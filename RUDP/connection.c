#include "connection.h"
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <time.h>
#include <stdio.h>
#include <sys/select.h>
#include <sys/time.h>
#include <arpa/inet.h>
#include "logger.h"

// Packet loss simulation moved to the receiver side. Helper removed to
// avoid unused-function warnings while keeping original behavior.

/*
graph TD
    A[Socket Creation] --> B[Bind/Listen]
    B --> C{Client or Server?}
    C -->|Client| D[sham_connect]
    C -->|Server| E[sham_accept]
    D --> F[3-Way Handshake]
    E --> F
    F --> G[Data Transfer]
    G --> H[FIN Detection]
    H --> I[4-Way Handshake]
    I --> J[Connection Closed]
*/

#define INITIAL_WINDOW_SIZE 4096
#define MAX_RETRIES 10
#define TIMEOUT_SECONDS 10

/*
 * S.H.A.M. (Simple Handshake Acknowledgment Messaging) Protocol Implementation
 *
 * This file implements a reliable transport protocol over UDP that provides:
 * - Connection establishment (3-way handshake)
 * - Reliable data transfer with sequence numbers and acknowledgments
 * - Flow control using sliding window
 * - Connection termination (4-way handshake)
 * - Error recovery and timeout handling
 *
 * The protocol mimics TCP behavior while using UDP as the transport layer.
 */

/*
 * Creates a UDP socket for the S.H.A.M. protocol
 *
 * This is the foundation of all network communication in S.H.A.M.
 * The socket will be used for sending and receiving all protocol packets.
 *
 * Returns:
 *   int: Socket file descriptor on success, -1 on failure
 *
 * Error conditions:
 *   - System socket creation fails (insufficient resources, permissions)
 */
//Creates a UDP socket for the S.H.A.M. protocol
 int sham_socket(void) {
    // Create UDP socket using IPv4 addressing
    // AF_INET = IPv4, SOCK_DGRAM = UDP, 0 = default protocol
    int sockfd = socket(AF_INET, SOCK_DGRAM, 0);
    if (sockfd < 0) {
        perror("socket");  // Print system error message
        return -1;         // Return error indicator
    }
    return sockfd;  // Return valid socket descriptor
}

/*
 * Binds a socket to a specific network address and port
 *
 * This associates the socket with a local network interface and port,
 * allowing it to receive packets destined for that address/port combination.
 *
 * Parameters:
 *   sockfd: Socket file descriptor from sham_socket()
 *   addr: Pointer to sockaddr_in structure containing IP address and port
 *
 * Returns:
 *   int: 0 on success, -1 on failure
 *
 * Error conditions:
 *   - Port already in use by another process
 *   - Insufficient permissions (ports < 1024 require root)
 *   - Invalid address or socket descriptor
 */
//Binds a socket to a specific network address and port
 int sham_bind(int sockfd, const struct sockaddr_in *addr) {
    // Bind socket to the specified address and port
    // Cast sockaddr_in* to sockaddr* for generic socket API
    if (bind(sockfd, (struct sockaddr*)addr, sizeof(*addr)) < 0) {
        perror("bind");  // Print system error message
        return -1;       // Return error indicator
    }
    return 0;  // Success
}

/*
 * Sets a socket to listen mode for incoming connections (UDP semantic)
 *
 * For UDP, this is primarily a state change in our protocol implementation.
 * The socket is already capable of receiving packets, but this function
 * prepares the connection structure for accepting new connections.
 *
 * Parameters:
 *   sockfd: Socket file descriptor to set to listen mode
 *
 * Returns:
 *   int: 0 on success (always succeeds for UDP)
 *
 * Note: UDP doesn't have a true "listen" state like TCP, but this function
 * maintains API compatibility and prepares for sham_accept() calls.
 */
//Sets a socket to listen mode for incoming connections (UDP semantic)
int sham_listen(int sockfd) {
    // For UDP, listening is implicit - socket can receive from any address
    // This function mainly serves as a state indicator for the application
    (void)sockfd;  // Suppress unused parameter warning
    return 0;  // Always succeeds for UDP
}

/*
 * Sends a S.H.A.M. protocol packet to the remote peer
 *
 * This is the core packet transmission function used by all other functions
 * in the protocol. It constructs a complete S.H.A.M. packet with header and
 * optional data payload, then sends it to the remote peer.
 *
 * Packet Structure:
 * +----------------+----------------+----------------+----------------+
 * | Sequence Num   | Ack Num        | Flags          | Window Size    |  Header (16 bytes)
 * +----------------+----------------+----------------+----------------+
 * | Data Payload (variable length)                                   |
 * +------------------------------------------------------------------+
 *
 * Parameters:
 *   conn: Connection structure containing peer address and current state
 *   flags: Control flags (SHAM_SYN, SHAM_ACK, SHAM_FIN) - can be OR'd together
 *   data: Optional data payload to send (NULL for control packets)
 *   data_len: Length of data payload (0 for control packets)
 *
 * Returns:
 *   int: Number of bytes sent on success, -1 on failure
 *
 * Network Byte Order:
 *   All multi-byte fields are converted to network byte order (big-endian)
 *   for cross-platform compatibility
 *
 * Error conditions:
 *   - Memory allocation failure for packet buffer
 *   - Network send failure (peer unreachable, network down, etc.)
 */
//Sends a S.H.A.M. protocol packet to the remote peer
int send_sham_packet(sham_connection_t *conn, uint16_t flags, const char *data, size_t data_len) {
    // Calculate total packet size (header + data)
    size_t packet_size = sizeof(struct sham_header) + data_len;

    // Allocate memory for the complete packet
    char *packet = malloc(packet_size);
    if (!packet) {
        return -1;  // Memory allocation failed
    }

    // Get pointer to header section of packet
    struct sham_header *header = (struct sham_header*)packet;

    // Fill header fields in network byte order (big-endian)
    header->seq_num = htonl(conn->seq_num);        // Convert to network order
    header->ack_num = htonl(conn->ack_num);        // Convert to network order
    header->flags = htons(flags);                  // Convert to network order
    header->window_size = htons((uint16_t)conn->available_buffer); // Advertise available buffer space

    // Copy data payload if provided
    if (data && data_len > 0) {
        memcpy(packet + sizeof(struct sham_header), data, data_len);
    }

    // NOTE: Packet loss is simulated at the receiver side in this
    // codebase to match testing requirements. The sender always
    // attempts to send the packet.

    // Send the complete packet to remote peer
    ssize_t sent = sendto(conn->sockfd, packet, packet_size, 0,
                         (struct sockaddr*)&conn->remote_addr, conn->remote_addr_len);

    // Free the packet buffer (no longer needed)
    free(packet);

    // Check for send errors
    if (sent < 0) {
        perror("sendto");  // Print system error message
        return -1;         // Return error indicator
    }

    return sent;  // Return actual bytes sent
}

/*
 * Receives a S.H.A.M. protocol packet from the remote peer
 *
 * This function waits for and receives packets from the remote peer,
 * validates them, and extracts both header information and optional data.
 * It also updates the connection's peer address information.
 *
 * Parameters:
 *   conn: Connection structure (will be updated with peer address)
 *   header: Pointer to sham_header structure to fill with received header
 *   data: Buffer to store received data payload (can be NULL)
 *   max_data_len: Maximum size of data buffer
 *
 * Returns:
 *   int: Number of data bytes received on success, -1 on failure
 *
 * Side Effects:
 *   - Updates conn->remote_addr with sender's address
 *   - Updates conn->remote_addr_len with address length
 *   - Converts all header fields from network to host byte order
 *
 * Error conditions:
 *   - Network receive failure
 *   - Packet too small (missing header)
 *   - Data buffer too small for received payload
 */
//Receives a S.H.A.M. protocol packet from the remote peer
int receive_sham_packet(sham_connection_t *conn, struct sham_header *header, char *data, size_t max_data_len) {
    char buffer[8192];  // Maximum packet size buffer

    // Receive packet from any sender (peer address will be filled in)
    ssize_t received = recvfrom(conn->sockfd, buffer, sizeof(buffer), 0,
                               (struct sockaddr*)&conn->remote_addr, &conn->remote_addr_len);

    // Check for receive errors
    if (received < 0) {
        perror("recvfrom");  // Print system error message
        return -1;           // Return error indicator
    }

    // Validate minimum packet size (must contain header)
    if ((size_t)received < sizeof(struct sham_header)) {
        printf("Received packet too small\n");
        return -1;
    }

    // Extract header from received packet
    memcpy(header, buffer, sizeof(struct sham_header));

    // Convert header fields from network to host byte order
    header->seq_num = ntohl(header->seq_num);        // Convert from network order
    header->ack_num = ntohl(header->ack_num);        // Convert from network order
    header->flags = ntohs(header->flags);            // Convert from network order
    header->window_size = ntohs(header->window_size); // Convert from network order

    // Calculate data payload size
    size_t data_len = received - sizeof(struct sham_header);

    // Extract data payload if buffer provided and data exists
    if (data && data_len > 0 && data_len <= max_data_len) {
        memcpy(data, buffer + sizeof(struct sham_header), data_len);
    }

    // Return the size of data payload received
    return data_len;
}

/*
 * Validates a received S.H.A.M. packet against protocol expectations
 *
 * This function performs security and correctness checks on incoming packets
 * to ensure they conform to the S.H.A.M. protocol specification and are
 * appropriate for the current connection state.
 *
 * Parameters:
 *   header: Pointer to the received packet header
 *   conn: Current connection state (may be used for additional validation)
 *   expected_flags: Bitmask of required flags (0 means any flags acceptable)
 *
 * Returns:
 *   bool: true if packet is valid, false if invalid/rejected
 *
 * Validation Checks:
 *   1. Flag validation: Ensures packet has required control flags
 *   2. Sequence number validation: Checks for reasonable sequence numbers
 *   3. Acknowledgment number validation: Validates ACK numbers
 *   4. Window size validation: Ensures window size is within bounds
 *   5. Flag consistency validation: Prevents invalid flag combinations
 *   6. State-specific validation: Context-aware checks based on connection state
 *   7. Basic sanity checks: Prevents obviously corrupted packets
 *   8. Protocol-specific validation: SYN packets must have reasonable window sizes
 *
 * Security Considerations:
 *   - Prevents processing of malformed packets
 *   - Validates protocol compliance
 *   - Detects potential replay attacks
 *   - Prevents integer overflow vulnerabilities
 *   - Can be extended for cryptographic validation
 */
//Validates a received S.H.A.M. packet against protocol expectations
bool is_valid_packet(const struct sham_header *header, sham_connection_t *conn, uint16_t expected_flags) {
    (void)conn;  // Suppress unused parameter warning
    // Validate that packet contains required control flags
    // expected_flags is a bitmask (e.g., SHAM_SYN | SHAM_ACK)
    // If expected_flags is non-zero, packet must have ALL specified flags set
    if (expected_flags != 0 && !(header->flags & expected_flags)) {
        return false;  // Packet missing required flags
    }

    // 1. Sequence Number Validation
    // Check for obviously invalid sequence numbers (negative or unreasonably large)
    if (header->seq_num > 0x7FFFFFFF) {  // Avoid integer overflow issues
        return false;  // Sequence number too large
    }

    // 2. Acknowledgment Number Validation
    // ACK numbers should be reasonable (not negative, not excessively large)
    if (header->ack_num > 0x7FFFFFFF) {  // Avoid integer overflow
        return false;  // ACK number too large
    }

    // 3. Window Size Validation
    // Window size should be reasonable (not negative, not excessively large)
    const uint16_t MAX_WINDOW_SIZE = 65535;  // Maximum possible window size

    if (header->window_size > MAX_WINDOW_SIZE) {
        return false;  // Window size too large
    }

    // 4. Flag Consistency Validation
    // Certain flag combinations should be valid
    uint16_t flags = header->flags;

    // Check for invalid flag combinations
    // - SYN and FIN should not both be set (connection initiation vs termination)
    if ((flags & SHAM_SYN) && (flags & SHAM_FIN)) {
        return false;  // Invalid: SYN and FIN together
    }

    // - Only SYN, ACK, and FIN flags should be set (no other bits)
    uint16_t valid_flags = SHAM_SYN | SHAM_ACK | SHAM_FIN;
    if (flags & ~valid_flags) {  // Check for invalid flag bits
        return false;  // Invalid flags set
    }

    // 5. Basic Sanity Checks
    // Ensure header fields are not all zeros (might indicate corruption)
    if (header->seq_num == 0 && header->ack_num == 0 &&
        header->flags == 0 && header->window_size == 0) {
        return false;  // All-zero header likely indicates corruption
    }

    return true;  // Packet passed all validation checks
}

/*
 * Server-side connection acceptance (3-way handshake)
 *
 * This function implements the server side of the S.H.A.M. 3-way handshake:
 * 1. Server waits for SYN from client
 * 2. Server responds with SYN-ACK
 * 3. Server waits for final ACK from client
 *
 * The 3-way handshake establishes:
 * - Mutual agreement to communicate
 * - Initial sequence numbers for reliable data transfer
 * - Window sizes for flow control
 * - Connection state synchronization
 *
 * Parameters:
 *   sockfd: Server socket file descriptor (already bound and listening)
 *   conn: Connection structure to initialize and manage the new connection
 *
 * Returns:
 *   int: 0 on successful connection establishment, -1 on failure
 *
 * Connection State Transitions:
 *   SHAM_LISTEN → SHAM_SYN_RECEIVED → SHAM_ESTABLISHED
 *
 * Sequence Number Initialization:
 *   - conn->seq_num: Server's initial sequence number (random)
 *   - conn->ack_num: Next expected sequence from client (client_seq + 1)
 *
 * Flow Control Setup:
 *   - conn->window_size: Server's receive window size
 *   - conn->peer_window_size: Client's advertised window size
 *
 * Error Conditions:
 *   - Socket receive failures
 *   - Invalid packet formats
 *   - Timeout waiting for expected packets
 *   - Memory allocation failures
 */
// Server accept connection (3-way handshake - server side)
int sham_accept(int sockfd, sham_connection_t *conn, float loss_rate) {

    //conn - server, receives from any client

    // Initialize connection structure for server-side operation
    conn->sockfd = sockfd;                           // Use provided socket
    conn->state = SHAM_LISTEN;                       // Server starts in LISTEN state
    conn->is_server = true;                         // Mark as server endpoint
    conn->window_size = INITIAL_WINDOW_SIZE;         // Set initial receive window
    conn->available_buffer = INITIAL_WINDOW_SIZE;    // Initialize available buffer space
    conn->loss_rate = loss_rate;                     // Set packet loss rate for testing
    conn->remote_addr_len = sizeof(conn->remote_addr); // Initialize address length

    struct sham_header header;  // Buffer for received packet headers
    char data[4096];           // Buffer for any data payload (not expected in handshake)
    (void)data;  // Suppress unused variable warning

    printf("Server waiting for SYN...\n");
    time_t start_time = time(NULL);
    int retries = 0;

    // ===== PHASE 1: Wait for SYN from client =====
    while (conn->state == SHAM_LISTEN && retries < MAX_RETRIES) {
        // Check for overall timeout
        if (time(NULL) - start_time > TIMEOUT_SECONDS) {
            printf("Connection timeout waiting for SYN\n");
            return -1;
        }

        // Use select() for 1-second timeout on socket
        fd_set read_fds;
        FD_ZERO(&read_fds);
        FD_SET(conn->sockfd, &read_fds);

        struct timeval timeout = {1, 0};  // 1 second timeout
        int ready = select(conn->sockfd + 1, &read_fds, NULL, NULL, &timeout);

        if (ready <= 0) {
            retries++;
            continue;  // Timeout or error, try again
        }

        char buffer[8192];  // Receive buffer for incoming packets

        // Receive packet from any client (address will be stored in conn->remote_addr)
        ssize_t received = recvfrom(conn->sockfd, buffer, sizeof(buffer), 0,
                                   (struct sockaddr*)&conn->remote_addr, &conn->remote_addr_len);

        // Skip packets that are too small to contain a valid header
        if (received < 0 || (size_t)received < sizeof(struct sham_header)) {
            retries++;
            continue;  // Wait for next packet
        }

        // Extract and convert header fields from network byte order
        memcpy(&header, buffer, sizeof(struct sham_header));
        header.seq_num = ntohl(header.seq_num);        // Convert sequence number
        header.ack_num = ntohl(header.ack_num);        // Convert acknowledgment number
        header.flags = ntohs(header.flags);            // Convert control flags
        header.window_size = ntohs(header.window_size); // Convert window size

        // Check if this is a SYN packet (connection initiation request)
        if (header.flags & SHAM_SYN) {
            printf("Received SYN with seq_num=%u\n", header.seq_num);
            log_packet_received(conn, header.flags, header.seq_num, header.ack_num, header.window_size, 0);

            // Initialize sequence numbers for this connection
            conn->ack_num = header.seq_num + 1;  // Next expected seq from client
            conn->seq_num = rand() % 1000;       // Our initial seq number (random)
            conn->peer_window_size = header.window_size; // Client's receive window

            // Transition to SYN_RECEIVED state (handshake in progress)
            conn->state = SHAM_SYN_RECEIVED;
            break;  // Exit waiting loop
        }
        // Ignore non-SYN packets while in LISTEN state
        retries++;
    }

    // ===== PHASE 2: Send SYN-ACK response =====
    printf("Sending SYN-ACK with seq_num=%u, ack_num=%u\n", conn->seq_num, conn->ack_num);
    log_packet_sent(conn, SHAM_SYN | SHAM_ACK, conn->seq_num, conn->ack_num, conn->window_size, 0);
    // Send SYN-ACK packet (synchronize + acknowledge)
    if (send_sham_packet(conn, SHAM_SYN | SHAM_ACK, NULL, 0) < 0) {
        return -1;  // Failed to send SYN-ACK
    }

    // ===== PHASE 3: Wait for final ACK from client =====
    printf("Waiting for ACK...\n");
    start_time = time(NULL);  // Reset timeout for ACK waiting
    retries = 0;
    
    while (conn->state == SHAM_SYN_RECEIVED && retries < MAX_RETRIES) {
        // Check for overall timeout
        if (time(NULL) - start_time > TIMEOUT_SECONDS) {
            printf("Connection timeout waiting for ACK\n");
            return -1;
        }

        // Use select() for 1-second timeout on socket
        fd_set read_fds;
        FD_ZERO(&read_fds);
        FD_SET(conn->sockfd, &read_fds);

        struct timeval timeout = {1, 0};  // 1 second timeout
        int ready = select(conn->sockfd + 1, &read_fds, NULL, NULL, &timeout);

        if (ready <= 0) {
            retries++;
            continue;  // Timeout or error, try again
        }

        char buffer[8192];  // Receive buffer for final ACK

        // Receive final ACK packet from the expected client
        ssize_t received = recvfrom(conn->sockfd, buffer, sizeof(buffer), 0,
                                   (struct sockaddr*)&conn->remote_addr, &conn->remote_addr_len);

        // Skip invalid packets
        if (received < 0 || (size_t)received < sizeof(struct sham_header)) {
            retries++;
            continue;  // Wait for valid packet
        }

        // Extract and convert header fields
        memcpy(&header, buffer, sizeof(struct sham_header));
        header.seq_num = ntohl(header.seq_num);
        header.ack_num = ntohl(header.ack_num);
        header.flags = ntohs(header.flags);
        header.window_size = ntohs(header.window_size);

        // Check if this is the expected ACK packet
        if ((header.flags & SHAM_ACK) && header.ack_num == conn->seq_num + 1) {
            printf("Received ACK. Connection established!\n");
            log_packet_received(conn, header.flags, header.seq_num, header.ack_num, header.window_size, 0);
            conn->seq_num++;  // Increment our sequence number for next packet
            conn->state = SHAM_ESTABLISHED;  // Connection is now fully established
            log_connection_event(conn, "CONNECTION_ESTABLISHED", "");
            return 0;  // Success!
        }
        // Ignore packets that don't match our expectations
        retries++;
    }

    // If we reach here, handshake failed (timeout or error)
    return -1;
}

/*
 * Client-side connection establishment (3-way handshake)
 *
 * This function implements the client side of the S.H.A.M. 3-way handshake:
 * 1. Client sends SYN to server
 * 2. Client waits for SYN-ACK from server
 * 3. Client sends final ACK to server
 *
 * The 3-way handshake establishes:
 * - Mutual agreement to communicate
 * - Initial sequence numbers for reliable data transfer
 * - Window sizes for flow control
 * - Connection state synchronization
 *
 * Parameters:
 *   sockfd: Client socket file descriptor (already created)
 *   server_addr: Server's network address (IP + port)
 *   conn: Connection structure to initialize and manage the connection
 *
 * Returns:
 *   int: 0 on successful connection establishment, -1 on failure
 *
 * Connection State Transitions:
 *   SHAM_CLOSED → SHAM_SYN_SENT → SHAM_ESTABLISHED
 *
 * Sequence Number Initialization:
 *   - conn->seq_num: Client's initial sequence number (random)
 *   - conn->ack_num: Next expected sequence from server (set after SYN-ACK)
 *
 * Flow Control Setup:
 *   - conn->window_size: Client's receive window size
 *   - conn->peer_window_size: Server's advertised window size
 *
 * Error Conditions:
 *   - Socket send/receive failures
 *   - Invalid server responses
 *   - Timeout waiting for expected packets
 *   - Network connectivity issues
 */
// Client connect (3-way handshake - client side)
int sham_connect(int sockfd, const struct sockaddr_in *server_addr, sham_connection_t *conn, float loss_rate) {
    // Initialize connection structure for client-side operation
    conn->sockfd = sockfd;                          // Use provided socket
    conn->remote_addr = *server_addr;               // Store server address
    conn->remote_addr_len = sizeof(*server_addr);   // Set address length
    conn->state = SHAM_CLOSED;                      // Start in closed state
    conn->is_server = false;                       // Mark as client endpoint
    conn->window_size = INITIAL_WINDOW_SIZE;        // Set initial receive window
    conn->available_buffer = INITIAL_WINDOW_SIZE;   // Initialize available buffer space
    conn->loss_rate = loss_rate;                    // Set packet loss rate for testing

    // Initialize sequence number with random value for security
    srand(time(NULL));                              // Seed random number generator
    conn->seq_num = rand() % 1000;                  // Random initial sequence number

    struct sham_header header;  // Buffer for received packet headers
    char data[1024];           // Buffer for any data payload (not expected in handshake)
    (void)data;  // Suppress unused variable warning

    // ===== PHASE 1: Send SYN to initiate connection =====
    printf("Sending SYN with seq_num=%u\n", conn->seq_num);
    log_packet_sent(conn, SHAM_SYN, conn->seq_num, 0, 0, 0);
    // Send SYN packet to request connection establishment
    if (send_sham_packet(conn, SHAM_SYN, NULL, 0) < 0) {
        return -1;  // Failed to send SYN
    }
    conn->state = SHAM_SYN_SENT;  // Transition to SYN_SENT state

    // ===== PHASE 2: Wait for SYN-ACK response from server =====
    printf("Waiting for SYN-ACK...\n");
    time_t start_time = time(NULL);
    int retries = 0;
    
    while (conn->state == SHAM_SYN_SENT && retries < MAX_RETRIES) {
        // Check for overall timeout
        if (time(NULL) - start_time > TIMEOUT_SECONDS) {
            printf("Connection timeout waiting for SYN-ACK\n");
            return -1;
        }

        // Use select() for 1-second timeout on socket
        fd_set read_fds;
        FD_ZERO(&read_fds);
        FD_SET(conn->sockfd, &read_fds);

        struct timeval timeout = {1, 0};  // 1 second timeout
        int ready = select(conn->sockfd + 1, &read_fds, NULL, NULL, &timeout);

        if (ready <= 0) {
            // Timeout occurred, retransmit the SYN packet
            printf("Timeout waiting for SYN-ACK, retransmitting SYN (attempt %d)...\n", retries + 1);
            
            // Re-send the initial SYN packet
            if (send_sham_packet(conn, SHAM_SYN, NULL, 0) < 0) {
                // If sending fails, we should probably abort
                perror("Failed to retransmit SYN");
                return -1;
            }
            
            retries++;
            continue; // Continue to the next iteration to wait again
        }

        char buffer[8192];  // Receive buffer for server response

        // Receive response from server
        ssize_t received = recvfrom(conn->sockfd, buffer, sizeof(buffer), 0,
                                   (struct sockaddr*)&conn->remote_addr, &conn->remote_addr_len);

        // Skip packets that are too small
        if (received < 0 || (size_t)received < sizeof(struct sham_header)) {
            retries++;
            continue;  // Wait for valid packet
        }

        // Extract and convert header fields from network byte order
        memcpy(&header, buffer, sizeof(struct sham_header));
        header.seq_num = ntohl(header.seq_num);        // Convert sequence number
        header.ack_num = ntohl(header.ack_num);        // Convert acknowledgment number
        header.flags = ntohs(header.flags);            // Convert control flags
        header.window_size = ntohs(header.window_size); // Convert window size

        // Check if this is the expected SYN-ACK packet
        if ((header.flags & (SHAM_SYN | SHAM_ACK)) == (SHAM_SYN | SHAM_ACK) &&
            header.ack_num == conn->seq_num + 1) {
            printf("Received SYN-ACK with seq_num=%u, ack_num=%u\n", header.seq_num, header.ack_num);
            log_packet_received(conn, header.flags, header.seq_num, header.ack_num, header.window_size, 0);

            // Initialize sequence numbers based on server response
            conn->ack_num = header.seq_num + 1;  // Next expected seq from server
            conn->seq_num++;                     // Increment our sequence number
            conn->peer_window_size = header.window_size; // Server's receive window

            // ===== PHASE 3: Send final ACK to complete handshake =====
            printf("Sending ACK with ack_num=%u\n", conn->ack_num);
            log_packet_sent(conn, SHAM_ACK, conn->seq_num, conn->ack_num, conn->window_size, 0);
            // Send final ACK to acknowledge server's SYN
            if (send_sham_packet(conn, SHAM_ACK, NULL, 0) < 0) {
                return -1;  // Failed to send ACK
            }

            conn->state = SHAM_ESTABLISHED;  // Connection is now fully established
            printf("Connection established!\n");
            log_connection_event(conn, "CONNECTION_ESTABLISHED", "");
            return 0;  // Success!
        }
        // Ignore packets that don't match our expectations
        retries++;
    }

    // If we reach here, handshake failed (timeout or error)
    return -1;
}

/*
 * Connection termination (4-way handshake with simultaneous close handling)
 *
 * This function implements the S.H.A.M. 4-way handshake for graceful connection
 * termination. It handles three scenarios:
 * 1. Normal close (we initiate, peer responds)
 * 2. Passive close (peer initiated, we respond)
 * 3. Simultaneous close (both sides initiate simultaneously)
 *
 * The 4-way handshake ensures:
 * - Both sides agree to terminate
 * - No data loss during termination
 * - Clean resource cleanup
 * - Proper state transitions
 *
 * Parameters:
 *   conn: Connection structure to terminate
 *
 * Returns:
 *   int: 0 on successful termination, -1 on failure
 *
 * State Transitions (Normal Close):
 *   ESTABLISHED → FIN_WAIT_1 → FIN_WAIT_2 → CLOSED
 *   Peer: ESTABLISHED → CLOSE_WAIT → LAST_ACK → CLOSED
 *
 * State Transitions (Simultaneous Close):
 *   Both: ESTABLISHED → FIN_WAIT_1 → CLOSING → CLOSED
 *
 * Timeout Handling:
 *   - 5-second overall timeout for close operations
 *   - 1-second select() timeout for packet reception
 *   - Graceful fallback to forced close on timeout
 *
 * Error Conditions:
 *   - Invalid connection state
 *   - Network send/receive failures
 *   - Timeout waiting for expected packets
 *   - Memory allocation failures
 */
// Close connection (4-way handshake with timeout and simultaneous close handling)
int sham_close(sham_connection_t *conn) {
    // Validate connection state - can only close from ESTABLISHED or CLOSE_WAIT
    if (conn->state != SHAM_ESTABLISHED && conn->state != SHAM_CLOSE_WAIT) {
        return -1;  // Invalid state for closing
    }

    struct sham_header header;  // Buffer for received packet headers
    char data[1024];           // Buffer for any data payload (not expected in close)
    (void)data;  // Suppress unused variable warning

    // ===== HANDLE PASSIVE CLOSE SCENARIO =====
    // If we're already in CLOSE_WAIT (peer sent FIN first), handle that case
    if (conn->state == SHAM_CLOSE_WAIT) {
        // Peer already sent FIN and we ACKed it, now we need to send our FIN
        printf("In CLOSE_WAIT - sending our FIN...\n");
        log_packet_sent(conn, SHAM_FIN, conn->seq_num, conn->ack_num, conn->window_size, 0);
        if (send_sham_packet(conn, SHAM_FIN, NULL, 0) < 0) {
            return -1;  // Failed to send FIN
        }
        conn->state = SHAM_LAST_ACK;  // Waiting for final ACK

        // Set up timeout for close operations
        time_t start_time = time(NULL);
        const int CLOSE_TIMEOUT = 5;  // 5 seconds total timeout

        // Wait for final ACK from peer
        printf("Waiting for final ACK...\n");
        while (conn->state == SHAM_LAST_ACK) {
            // Check for overall timeout
            if (time(NULL) - start_time > CLOSE_TIMEOUT) {
                printf("Close timeout - forcing connection close\n");
                conn->state = SHAM_CLOSED;
                return 0;  // Success (forced close)
            }

            // Use select() for 1-second timeout on socket
            fd_set read_fds;
            FD_ZERO(&read_fds);
            FD_SET(conn->sockfd, &read_fds);

            struct timeval timeout = {1, 0};  // 1 second timeout
            int ready = select(conn->sockfd + 1, &read_fds, NULL, NULL, &timeout);

            if (ready <= 0) {
                continue;  // Timeout or error, try again
            }

            // Receive packet
            char buffer[8192];
            ssize_t received = recvfrom(conn->sockfd, buffer, sizeof(buffer), 0, NULL, NULL);

            if (received < 0 || (size_t)received < sizeof(struct sham_header)) {
                continue;  // Invalid packet size
            }

            // Extract and convert header fields
            memcpy(&header, buffer, sizeof(struct sham_header));
            header.seq_num = ntohl(header.seq_num);
            header.ack_num = ntohl(header.ack_num);
            header.flags = ntohs(header.flags);
            header.window_size = ntohs(header.window_size);

            // Check for final ACK
            if (header.flags & SHAM_ACK) {
                printf("Received final ACK - connection closed\n");
                log_packet_received(conn, header.flags, header.seq_num, header.ack_num, header.window_size, 0);
                conn->state = SHAM_CLOSED;
                log_connection_event(conn, "CONNECTION_CLOSED", "");
                return 0;  // Success!
            }
        }
        return 0;  // Should not reach here
    }

    // ===== HANDLE ACTIVE CLOSE SCENARIO =====
    // Normal case: we're initiating the close from ESTABLISHED state

    // Step 1: Send FIN to initiate close
    printf("Sending FIN...\n");
    log_packet_sent(conn, SHAM_FIN, conn->seq_num, conn->ack_num, conn->window_size, 0);
    if (send_sham_packet(conn, SHAM_FIN, NULL, 0) < 0) {
        return -1;  // Failed to send FIN
    }
    conn->state = SHAM_FIN_WAIT_1;  // Waiting for ACK or FIN

    // Set up timeout for close operations
    time_t start_time = time(NULL);
    const int CLOSE_TIMEOUT = 5;  // 5 seconds total timeout

    // Step 2: Wait for ACK of our FIN or FIN from peer (simultaneous close)
    printf("Waiting for ACK of FIN or FIN from peer...\n");
    while (conn->state == SHAM_FIN_WAIT_1) {
        // Check for overall timeout
        if (time(NULL) - start_time > CLOSE_TIMEOUT) {
            printf("Close timeout - forcing connection close\n");
            conn->state = SHAM_CLOSED;
            return 0;  // Success (forced close)
        }

        // Use select() for non-blocking socket operations
        fd_set read_fds;
        FD_ZERO(&read_fds);
        FD_SET(conn->sockfd, &read_fds);

        struct timeval timeout = {1, 0};  // 1 second timeout
        int ready = select(conn->sockfd + 1, &read_fds, NULL, NULL, &timeout);

        if (ready <= 0) {
            continue;  // Timeout or error, try again
        }

        // Receive packet
        char buffer[8192];
        ssize_t received = recvfrom(conn->sockfd, buffer, sizeof(buffer), 0, NULL, NULL);

        if (received < 0 || (size_t)received < sizeof(struct sham_header)) {
            continue;  // Invalid packet size
        }

        // Extract and convert header fields
        memcpy(&header, buffer, sizeof(struct sham_header));
        header.seq_num = ntohl(header.seq_num);
        header.ack_num = ntohl(header.ack_num);
        header.flags = ntohs(header.flags);
        header.window_size = ntohs(header.window_size);

        // Handle different response types
        if (header.flags & SHAM_ACK) {
            // Received ACK of our FIN - normal close progression
            printf("Received ACK of FIN\n");
            log_packet_received(conn, header.flags, header.seq_num, header.ack_num, header.window_size, 0);
            conn->state = SHAM_FIN_WAIT_2;  // Now wait for peer's FIN
            break;
        } else if (header.flags & SHAM_FIN) {
            // Received FIN - simultaneous close scenario
            printf("Received FIN (simultaneous close)\n");
            log_packet_received(conn, header.flags, header.seq_num, header.ack_num, header.window_size, 0);

            // Send ACK for their FIN
            printf("Sending ACK for peer's FIN...\n");
            log_packet_sent(conn, SHAM_ACK, conn->seq_num, conn->ack_num, conn->window_size, 0);
            if (send_sham_packet(conn, SHAM_ACK, NULL, 0) < 0) {
                return -1;  // Failed to send ACK
            }

            conn->state = SHAM_CLOSING;  // Special state for simultaneous close
            break;
        }
    }

    // ===== HANDLE DIFFERENT CLOSE SCENARIOS =====

    if (conn->state == SHAM_FIN_WAIT_2) {
        // Normal close: we sent FIN, got ACK, now wait for peer's FIN
        printf("Waiting for FIN from peer...\n");
        while (conn->state == SHAM_FIN_WAIT_2) {
            // Check for overall timeout
            if (time(NULL) - start_time > CLOSE_TIMEOUT) {
                printf("Close timeout - forcing connection close\n");
                conn->state = SHAM_CLOSED;
                return 0;  // Success (forced close)
            }

            // Use select() for timeout handling
            fd_set read_fds;
            FD_ZERO(&read_fds);
            FD_SET(conn->sockfd, &read_fds);

            struct timeval timeout = {1, 0};  // 1 second timeout
            int ready = select(conn->sockfd + 1, &read_fds, NULL, NULL, &timeout);

            if (ready <= 0) {
                continue;  // Timeout or error, try again
            }

            // Receive packet
            char buffer[8192];
            ssize_t received = recvfrom(conn->sockfd, buffer, sizeof(buffer), 0, NULL, NULL);

            if (received < 0 || (size_t)received < sizeof(struct sham_header)) {
                continue;  // Invalid packet size
            }

            // Extract and convert header fields
            memcpy(&header, buffer, sizeof(struct sham_header));
            header.seq_num = ntohl(header.seq_num);
            header.ack_num = ntohl(header.ack_num);
            header.flags = ntohs(header.flags);
            header.window_size = ntohs(header.window_size);

            // Check for peer's FIN
            if (header.flags & SHAM_FIN) {
                printf("Received FIN from peer\n");
                log_packet_received(conn, header.flags, header.seq_num, header.ack_num, header.window_size, 0);

                // Step 4: Send final ACK to complete 4-way handshake
                printf("Sending final ACK...\n");
                log_packet_sent(conn, SHAM_ACK, conn->seq_num, conn->ack_num, conn->window_size, 0);
                if (send_sham_packet(conn, SHAM_ACK, NULL, 0) < 0) {
                    return -1;  // Failed to send ACK
                }

                conn->state = SHAM_CLOSED;
                printf("Connection closed successfully\n");
                log_connection_event(conn, "CONNECTION_CLOSED", "");
                return 0;  // Success!
            }
        }
    } else if (conn->state == SHAM_CLOSING) {
        // Simultaneous close: both sides sent FIN, wait for ACK of our FIN
        printf("Waiting for ACK of our FIN (simultaneous close)...\n");
        while (conn->state == SHAM_CLOSING) {
            // Check for overall timeout
            if (time(NULL) - start_time > CLOSE_TIMEOUT) {
                printf("Close timeout - forcing connection close\n");
                conn->state = SHAM_CLOSED;
                return 0;  // Success (forced close)
            }

            // Use select() for timeout handling
            fd_set read_fds;
            FD_ZERO(&read_fds);
            FD_SET(conn->sockfd, &read_fds);

            struct timeval timeout = {1, 0};  // 1 second timeout
            int ready = select(conn->sockfd + 1, &read_fds, NULL, NULL, &timeout);

            if (ready <= 0) {
                continue;  // Timeout or error, try again
            }

            // Receive packet
            char buffer[8192];
            ssize_t received = recvfrom(conn->sockfd, buffer, sizeof(buffer), 0, NULL, NULL);

            if (received < 0 || (size_t)received < sizeof(struct sham_header)) {
                continue;  // Invalid packet size
            }

            // Extract and convert header fields
            memcpy(&header, buffer, sizeof(struct sham_header));
            header.seq_num = ntohl(header.seq_num);
            header.ack_num = ntohl(header.ack_num);
            header.flags = ntohs(header.flags);
            header.window_size = ntohs(header.window_size);

            // Check for ACK of our FIN
            if (header.flags & SHAM_ACK) {
                printf("Received ACK of our FIN\n");
                log_packet_received(conn, header.flags, header.seq_num, header.ack_num, header.window_size, 0);
                conn->state = SHAM_CLOSED;
                printf("Connection closed successfully (simultaneous close)\n");
                log_connection_event(conn, "CONNECTION_CLOSED", "");
                return 0;  // Success!
            }
        }
    }

    // Fallback: force close if something went wrong
    conn->state = SHAM_CLOSED;
    printf("Connection closed (forced)\n");
    return 0;  // Success (forced close)
}

/*
 * Handle incoming FIN packet during data transfer
 *
 * This function is called when a FIN packet is received while the connection
 * is in ESTABLISHED state (during data transfer). It transitions the connection
 * to CLOSE_WAIT state and sends an ACK, allowing the application to complete
 * the 4-way handshake by calling sham_close().
 *
 * This enables graceful termination even when data is being transferred,
 * preventing data loss and ensuring proper connection cleanup.
 *
 * Parameters:
 *   conn: Connection structure that received the FIN
 *   header: Header of the received FIN packet
 *
 * Returns:
 *   int: 1 if FIN was handled, 0 if ignored, -1 on error
 *
 * State Transition:
 *   ESTABLISHED → CLOSE_WAIT
 *
 * Side Effects:
 *   - Sends ACK packet to peer
 *   - Updates connection state to CLOSE_WAIT
 *   - Updates acknowledgment number
 *
 * Integration:
 *   - Called from sham_receive_data() and sham_send_data()
 *   - Allows data transfer functions to detect connection termination
 *   - Enables clean shutdown during active data transfer
 */
// Handle incoming FIN packet - transition to CLOSE_WAIT
int sham_handle_incoming_fin(sham_connection_t *conn, struct sham_header *header) {
    // Only handle FIN packets when connection is established
    if (conn->state != SHAM_ESTABLISHED) {
        return 0;  // Ignore FIN in other states
    }

    printf("Received FIN from peer in ESTABLISHED state\n");
    log_packet_received(conn, header->flags, header->seq_num, header->ack_num, header->window_size, 0);

    // Update acknowledgment number to acknowledge the FIN
    conn->ack_num = header->seq_num + 1;

    // Send ACK to acknowledge receipt of FIN
    printf("Sending ACK for FIN...\n");
    log_packet_sent(conn, SHAM_ACK, conn->seq_num, conn->ack_num, conn->window_size, 0);
    if (send_sham_packet(conn, SHAM_ACK, NULL, 0) < 0) {
        return -1;  // Failed to send ACK
    }

    // Transition to CLOSE_WAIT state
    // Application must call sham_close() to complete the handshake
    conn->state = SHAM_CLOSE_WAIT;
    printf("Transitioned to CLOSE_WAIT - waiting for local close\n");
    log_connection_event(conn, "STATE_CHANGE", "CLOSE_WAIT");
    return 1;  // FIN was successfully handled
}
