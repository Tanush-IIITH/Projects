#define _POSIX_C_SOURCE 199309L
#include "data_transfer.h"
#include "connection.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/time.h>
#include <sys/select.h>
#include <arpa/inet.h>
#include <time.h>
#include "logger.h"
#include "data_transfer.h"
#include "connection.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <errno.h>
#include <sys/time.h>
#include <sys/select.h>
#include <arpa/inet.h>
#include <time.h>

// Initialize sliding window
void init_sliding_window(sliding_window_t *window, uint32_t initial_seq) {
    memset(window, 0, sizeof(sliding_window_t));
    window->base_seq_num = initial_seq;
    window->next_seq = 0;
    window->base = 0;
    window->window_used = 0;
    
    for (int i = 0; i < SHAM_WINDOW_SIZE; i++) {
        window->packets[i].state = PACKET_EMPTY;
    }
}

// Initialize receiver state
void init_receiver_state(receiver_state_t *receiver, uint32_t initial_seq) {
    memset(receiver, 0, sizeof(receiver_state_t));
    receiver->expected_seq = initial_seq;
    receiver->buffer_base = initial_seq;  // Set buffer base to match expected seq
    
    for (int i = 0; i < SHAM_WINDOW_SIZE * 2; i++) {
        receiver->buffer[i].received = false;
    }
}

// Check if packet has timed out
bool is_timeout(const struct timespec *send_time, int timeout_ms) {
    struct timespec current_time;
    clock_gettime(CLOCK_MONOTONIC, &current_time);
    
    long diff_ms = (current_time.tv_sec - send_time->tv_sec) * 1000 +
                   (current_time.tv_nsec - send_time->tv_nsec) / 1000000;
    
    return diff_ms >= timeout_ms;
}

// Send a data packet
int send_data_packet(sham_connection_t *conn, uint32_t seq_num, const char *data, size_t data_len) {
    // Create packet with header + data
    size_t packet_size = sizeof(struct sham_header) + data_len;
    char *packet = malloc(packet_size);
    if (!packet) {
        return -1;
    }
    
    // Fill header
    struct sham_header *header = (struct sham_header*)packet;
    header->seq_num = htonl(seq_num);
    header->ack_num = htonl(conn->ack_num);
    header->flags = htons(0);  // No special flags for data packets
    header->window_size = htons((uint16_t)conn->available_buffer);  // Advertise available buffer space
    
    // Copy data
    if (data && data_len > 0) {
        memcpy(packet + sizeof(struct sham_header), data, data_len);
    }
    
    // Simulate packet loss for testing
    // NOTE: Packet loss is simulated at the receiver side to match testing
    // specification. Sender should always attempt to send packets.
    
    // Send packet
    ssize_t sent = sendto(conn->sockfd, packet, packet_size, 0,
                         (struct sockaddr*)&conn->remote_addr, conn->remote_addr_len);
    
    free(packet);
    
    if (sent < 0) {
        perror("sendto");
        return -1;
    }
    
    printf("Sent data packet: seq=%u, len=%zu\n", seq_num, data_len);
    log_packet_sent(conn, 0, seq_num, conn->ack_num, conn->available_buffer, data_len);
    return 0;
}

// Send an ACK packet
int send_ack_packet(sham_connection_t *conn, uint32_t ack_num) {
    // Simulate packet loss for testing
    // NOTE: ACK loss is simulated at the receiver side if desired.
    
    struct sham_header header;
    header.seq_num = htonl(conn->seq_num);
    header.ack_num = htonl(ack_num);
    header.flags = htons(SHAM_ACK);
    header.window_size = htons((uint16_t)conn->available_buffer);  // Advertise available buffer space
    
    ssize_t sent = sendto(conn->sockfd, &header, sizeof(header), 0,
                         (struct sockaddr*)&conn->remote_addr, conn->remote_addr_len);
    
    if (sent < 0) {
        perror("sendto ACK");
        return -1;
    }
    
    printf("Sent ACK: ack_num=%u, window=%u\n", ack_num, conn->available_buffer);
    log_packet_sent(conn, SHAM_ACK, conn->seq_num, ack_num, conn->available_buffer, 0);
    return 0;
}

// Check if we can send a new packet (window not full)
bool can_send_packet(const sliding_window_t *window) {
    return window->window_used < SHAM_WINDOW_SIZE;
}

// Check if we can send considering flow control (peer window)
bool can_send_flow_control(sham_connection_t *conn, const sliding_window_t *window, size_t next_packet_size) {
    if (window->window_used == 0) {
        // No unacknowledged data, can always send at least one packet
        return true;
    }
    
    // Calculate unacknowledged data in flight
    // LastByteSent - LastByteAcked
    uint32_t last_byte_sent = window->base_seq_num + window->next_seq - 1;
    
    // The first unacknowledged packet is at window->base index
    // Its sequence number represents the first unacknowledged byte
    // So the last acknowledged byte is one less than that
    uint32_t last_byte_acked = window->packets[window->base].seq_num - 1;
    
    uint32_t unacked_bytes = last_byte_sent - last_byte_acked;
    
    // Check if adding this packet would exceed peer's window
    return (unacked_bytes + next_packet_size) <= conn->peer_window_size;
}

// Process received ACK
void process_ack(sliding_window_t *window, sham_connection_t *conn, uint32_t ack_num, uint16_t peer_window) {
    printf("Processing ACK: ack_num=%u, peer_window=%u\n", ack_num, peer_window);
    
    // Update peer's advertised window size and log if changed
    if (conn->peer_window_size != peer_window) {
        conn->peer_window_size = peer_window;
        log_flow_win_update(peer_window);
    }
    
    // Cumulative ACK - acknowledge all packets up to ack_num-1
    uint32_t acked_seq = ack_num - 1;
    
    while (window->window_used > 0) {
        // Get the sequence number of the packet at the current base
        uint32_t base_seq = window->packets[window->base].seq_num;
        
        if (base_seq <= acked_seq) {
            // This packet is acknowledged
            window->packets[window->base].state = PACKET_ACKED;
            printf("Packet seq=%u acknowledged\n", base_seq);
            
            // Move window base forward
            window->base = (window->base + 1) % SHAM_WINDOW_SIZE;
            window->window_used--;
        } else {
            break;  // No more packets to acknowledge
        }
    }
}

// Get index of next packet that needs retransmission (timeout)
int get_next_timeout_packet(const sliding_window_t *window) {
    for (int i = 0; i < SHAM_WINDOW_SIZE; i++) {
        int idx = (window->base + i) % SHAM_WINDOW_SIZE;
        
        if (window->packets[idx].state == PACKET_SENT &&
            is_timeout(&window->packets[idx].send_time, SHAM_RTO_MS)) {
            return idx;
        }
    }
    return -1;  // No timeouts
}

// Retransmit a packet
void retransmit_packet(sham_connection_t *conn, sliding_window_t *window, int index) {
    window_entry_t *entry = &window->packets[index];
    
    if (entry->retry_count >= SHAM_MAX_RETRIES) {
        printf("Max retries reached for packet seq=%u\n", entry->seq_num);
        // Mark packet as acknowledged/failed so the sliding window can advance
        entry->state = PACKET_ACKED;
        // Advance the window base past any acknowledged packets
        while (window->window_used > 0 && window->packets[window->base].state == PACKET_ACKED) {
            window->base = (window->base + 1) % SHAM_WINDOW_SIZE;
            window->window_used--;
        }
        return;
    }
    
    printf("Retransmitting packet seq=%u (attempt %d)\n", 
           entry->seq_num, entry->retry_count + 1);
    
    log_retransmission(conn, entry->seq_num, entry->retry_count + 1);
    // Also log the data-oriented retransmission with length for automated checks
    log_retx_data(entry->seq_num, entry->data_len);
    
    // Resend the packet
    send_data_packet(conn, entry->seq_num, entry->data, entry->data_len);
    
    // Update timing and retry count
    clock_gettime(CLOCK_MONOTONIC, &entry->send_time);
    entry->retry_count++;
}

// Process received data packet
int process_data_packet(receiver_state_t *receiver, sham_connection_t *conn,
                       const struct sham_header *header, const char *data, size_t data_len,
                       char *output_buffer, size_t buffer_size, size_t *bytes_received) {
    uint32_t seq_num = header->seq_num;
    
    printf("Received data packet: seq=%u, len=%zu\n", seq_num, data_len);
    log_packet_received(conn, header->flags, seq_num, header->ack_num, header->window_size, data_len);
    
    // Update peer's window size from the packet header and log if changed
    if (conn->peer_window_size != header->window_size) {
        conn->peer_window_size = header->window_size;
        log_flow_win_update(header->window_size);
    }
    
    // For in-order packets, we receive and deliver simultaneously, so no net change to available_buffer
    // For out-of-order packets, we consume buffer space for the received data
    if (seq_num != receiver->expected_seq) {
        // Out-of-order packet consumes buffer space
        if (conn->available_buffer >= data_len) {
            conn->available_buffer -= data_len;
        } else {
            printf("Buffer overflow - received packet exceeds available buffer\n");
            return -1;
        }
    }
    
    if (seq_num == receiver->expected_seq) {
        // In-order packet - can deliver immediately
        printf("In-order packet received: seq=%u\n", seq_num);
        
        // Calculate offset in output buffer
        size_t offset = *bytes_received;
        if (offset + data_len <= buffer_size) {
            memcpy(output_buffer + offset, data, data_len);
            *bytes_received += data_len;
            
            // Decrease available buffer space since data was delivered
            conn->available_buffer -= data_len;
        } else {
            printf("Buffer overflow - cannot deliver in-order packet\n");
            return -1;
        }
        
        receiver->expected_seq += data_len;  // Sequence numbers are byte-based
        
        // Check if we can deliver buffered packets
        while (true) {
            // Calculate packet index relative to current expected_seq
            uint32_t packet_offset = (receiver->expected_seq - receiver->buffer_base) / SHAM_DATA_SIZE;
            int buffer_idx = packet_offset % (SHAM_WINDOW_SIZE * 2);
            
            if (buffer_idx < SHAM_WINDOW_SIZE * 2 && 
                receiver->buffer[buffer_idx].received) {
                
                // Deliver buffered packet
                printf("Delivering buffered packet: seq=%u\n", receiver->expected_seq);
                
                size_t buffered_offset = *bytes_received;
                if (buffered_offset + receiver->buffer[buffer_idx].data_len <= buffer_size) {
                    memcpy(output_buffer + buffered_offset, 
                           receiver->buffer[buffer_idx].data, 
                           receiver->buffer[buffer_idx].data_len);
                    *bytes_received += receiver->buffer[buffer_idx].data_len;
                    
                    // Since we're delivering previously buffered data, 
                    // the buffer space becomes available again
                    conn->available_buffer += receiver->buffer[buffer_idx].data_len;
                } else {
                    printf("Buffer overflow - cannot deliver buffered packet\n");
                    return -1;
                }
                
                receiver->buffer[buffer_idx].received = false;
                receiver->expected_seq += receiver->buffer[buffer_idx].data_len;
            } else {
                break;
            }
        }
        
        // Send cumulative ACK
        send_ack_packet(conn, receiver->expected_seq);
        
    } else if (seq_num > receiver->expected_seq) {
        // Out-of-order packet - buffer it
        printf("Out-of-order packet: seq=%u, expected=%u\n", seq_num, receiver->expected_seq);
        
        // Calculate packet index relative to expected_seq
        uint32_t packet_offset = (seq_num - receiver->expected_seq) / SHAM_DATA_SIZE;
        int buffer_idx = packet_offset % (SHAM_WINDOW_SIZE * 2);
        
        if (buffer_idx < SHAM_WINDOW_SIZE * 2) {
            receiver->buffer[buffer_idx].received = true;
            receiver->buffer[buffer_idx].data_len = data_len;
            memcpy(receiver->buffer[buffer_idx].data, data, data_len);
        }
        
        // Send ACK for highest in-order sequence
        send_ack_packet(conn, receiver->expected_seq);
        
    } else {
        // Duplicate packet (seq < expected) - just ACK
        printf("Duplicate packet: seq=%u, expected=%u\n", seq_num, receiver->expected_seq);
        send_ack_packet(conn, receiver->expected_seq);
    }
    
    return 0;
}

// Process a data packet for file streaming (writes directly to file)
int process_file_packet(receiver_state_t *receiver, sham_connection_t *conn,
                       const struct sham_header *header, const char *data, size_t data_len,
                       FILE *file, size_t *bytes_received) {
    uint32_t seq_num = header->seq_num;

    printf("Received file packet: seq=%u, len=%zu\n", seq_num, data_len);

    // Update peer's window size from the packet header and log if changed
    if (conn->peer_window_size != header->window_size) {
        conn->peer_window_size = header->window_size;
        log_flow_win_update(header->window_size);
    }

    // For in-order packets, we write directly to file
    // For out-of-order packets, we buffer them
    if (seq_num != receiver->expected_seq) {
        // Out-of-order packet consumes buffer space
        if (conn->available_buffer >= data_len) {
            conn->available_buffer -= data_len;
        } else {
            printf("Buffer overflow - received packet exceeds available buffer\n");
            return -1;
        }
    }

    if (seq_num == receiver->expected_seq) {
        // In-order packet - write directly to file
        printf("In-order packet received: seq=%u\n", seq_num);

        size_t written = fwrite(data, 1, data_len, file);
        if (written != data_len) {
            perror("Failed to write to file");
            return -1;
        }

        *bytes_received += data_len;

        // For file streaming, we still need to manage available_buffer for flow control
        // Decrease available buffer space since we "consumed" it by processing the packet
        if (conn->available_buffer >= data_len) {
            conn->available_buffer -= data_len;
        } else {
            printf("Buffer underflow in file streaming\n");
            conn->available_buffer = 0;
        }

        receiver->expected_seq += data_len;  // Sequence numbers are byte-based

        // Check if we can deliver buffered packets
        while (true) {
            // Calculate packet index relative to current expected_seq
            uint32_t packet_offset = (receiver->expected_seq - receiver->buffer_base) / SHAM_DATA_SIZE;
            int buffer_idx = packet_offset % (SHAM_WINDOW_SIZE * 2);

            if (buffer_idx < SHAM_WINDOW_SIZE * 2 &&
                receiver->buffer[buffer_idx].received) {

                // Deliver buffered packet to file
                printf("Delivering buffered packet: seq=%u\n", receiver->expected_seq);

                size_t written = fwrite(receiver->buffer[buffer_idx].data, 1,
                                       receiver->buffer[buffer_idx].data_len, file);
                if (written != receiver->buffer[buffer_idx].data_len) {
                    perror("Failed to write buffered data to file");
                    return -1;
                }

                *bytes_received += receiver->buffer[buffer_idx].data_len;

                // Since we're delivering previously buffered data,
                // the buffer space becomes available again
                conn->available_buffer += receiver->buffer[buffer_idx].data_len;

                receiver->buffer[buffer_idx].received = false;
                receiver->expected_seq += receiver->buffer[buffer_idx].data_len;
            } else {
                break;
            }
        }

        // Send cumulative ACK
        send_ack_packet(conn, receiver->expected_seq);

    } else if (seq_num > receiver->expected_seq) {
        // Out-of-order packet - buffer it
        printf("Out-of-order packet: seq=%u, expected=%u\n", seq_num, receiver->expected_seq);

        // Calculate packet index relative to expected_seq
        uint32_t packet_offset = (seq_num - receiver->expected_seq) / SHAM_DATA_SIZE;
        int buffer_idx = packet_offset % (SHAM_WINDOW_SIZE * 2);

        if (buffer_idx < SHAM_WINDOW_SIZE * 2) {
            receiver->buffer[buffer_idx].received = true;
            receiver->buffer[buffer_idx].data_len = data_len;
            memcpy(receiver->buffer[buffer_idx].data, data, data_len);
        }

        // Send ACK for highest in-order sequence
        send_ack_packet(conn, receiver->expected_seq);

    } else {
        // Duplicate packet (seq < expected) - just ACK
        printf("Duplicate packet: seq=%u, expected=%u\n", seq_num, receiver->expected_seq);
        send_ack_packet(conn, receiver->expected_seq);
    }

    return 0;
}

// Send data using sliding window protocol
int sham_send_data(sham_connection_t *conn, const char *data, size_t total_len) {
    sliding_window_t window;
    init_sliding_window(&window, conn->seq_num);
    
    size_t bytes_sent = 0;
    bool done = false;
    
    printf("Starting data transmission: %zu bytes\n", total_len);
    
    while (!done) {
        // Send new packets if window has space, we have data, and flow control allows
        while (can_send_packet(&window) && can_send_flow_control(conn, &window, 
               (total_len - bytes_sent < SHAM_DATA_SIZE) ? (total_len - bytes_sent) : SHAM_DATA_SIZE) 
               && bytes_sent < total_len) {
            size_t chunk_size = (total_len - bytes_sent < SHAM_DATA_SIZE) ? 
                               (total_len - bytes_sent) : SHAM_DATA_SIZE;
            
            int window_idx = (window.base + window.window_used) % SHAM_WINDOW_SIZE;
            window_entry_t *entry = &window.packets[window_idx];
            
            // Prepare packet
            entry->state = PACKET_SENT;
            entry->seq_num = window.base_seq_num + bytes_sent;  // Byte-based sequence numbers
            entry->data_len = chunk_size;
            entry->retry_count = 0;
            memcpy(entry->data, data + bytes_sent, chunk_size);
            clock_gettime(CLOCK_MONOTONIC, &entry->send_time);
            
            // Send packet
            send_data_packet(conn, entry->seq_num, entry->data, entry->data_len);
            
            bytes_sent += chunk_size;
            window.next_seq += chunk_size;  // Increment by bytes sent
            window.window_used++;
        }
        
        // Check for timeouts and retransmit
        int timeout_idx = get_next_timeout_packet(&window);
        if (timeout_idx >= 0) {
                // Log timeout for the timed-out packet
                log_timeout(window.packets[timeout_idx].seq_num);
            retransmit_packet(conn, &window, timeout_idx);
        }
        
        // Receive ACKs (non-blocking)
        fd_set read_fds;
        FD_ZERO(&read_fds);
        FD_SET(conn->sockfd, &read_fds);
        
        struct timeval timeout = {0, 10000};  // 10ms timeout
        int ready = select(conn->sockfd + 1, &read_fds, NULL, NULL, &timeout);
        
        if (ready > 0 && FD_ISSET(conn->sockfd, &read_fds)) {
            char buffer[sizeof(struct sham_header)];
            ssize_t received = recvfrom(conn->sockfd, buffer, sizeof(buffer), 0, NULL, NULL);
            
            if (received == sizeof(struct sham_header)) {
                struct sham_header *header = (struct sham_header*)buffer;
                header->seq_num = ntohl(header->seq_num);
                header->ack_num = ntohl(header->ack_num);
                header->flags = ntohs(header->flags);
                header->window_size = ntohs(header->window_size);
                
                // Check for FIN packet - peer wants to close connection
                if (header->flags & SHAM_FIN) {
                    printf("Received FIN during data send\n");
                    // Handle the incoming FIN
                    if (sham_handle_incoming_fin(conn, header) > 0) {
                        // FIN was handled, connection is now in CLOSE_WAIT
                        // Stop sending and return what we've sent so far
                        printf("Connection closing, sent %zu bytes\n", bytes_sent);
                        return bytes_sent;
                    }
                }
                
                // Log received ACK packet
                if (header->flags & SHAM_ACK) {
                    log_packet_received(conn, header->flags, header->seq_num, header->ack_num, header->window_size, 0);
                    process_ack(&window, conn, header->ack_num, header->window_size);
                }
            }
        }
        
        // Check if we're done
        done = (bytes_sent >= total_len) && (window.window_used == 0);
    }
    
    printf("Data transmission completed: %zu bytes sent\n", total_len);
    return 0;
}

// Receive data using the protocol
int sham_receive_data(sham_connection_t *conn, char *buffer, size_t buffer_size) {
    receiver_state_t receiver;
    init_receiver_state(&receiver, conn->ack_num);
    
    size_t total_received = 0;
    
    // Set available buffer space based on actual buffer size.
    // `available_buffer` is a uint32_t. Guard against overflow
    // (e.g. buffer_size == 64*1024 == 65536 would wrap to 0).
    if (buffer_size > 0xFFFF) {
        conn->available_buffer = 0xFFFF; /* 65535 */
    } else {
        conn->available_buffer = buffer_size;
    }
    
    printf("Starting data reception...\n");
    
    while (total_received < buffer_size) {
        char packet_buffer[sizeof(struct sham_header) + SHAM_DATA_SIZE];
        
        ssize_t received = recvfrom(conn->sockfd, packet_buffer, sizeof(packet_buffer), 0, NULL, NULL);
        
        if (received < 0 || (size_t)received < sizeof(struct sham_header)) {
            continue;
        }
        
        struct sham_header *header = (struct sham_header*)packet_buffer;
        header->seq_num = ntohl(header->seq_num);
        header->ack_num = ntohl(header->ack_num);
        header->flags = ntohs(header->flags);
        header->window_size = ntohs(header->window_size);
        // Receiver-side packet loss simulation: drop packet probabilistically
        if (conn->loss_rate > 0.0 && ((float)rand() / RAND_MAX) < conn->loss_rate) {
            printf("Receiver dropped incoming packet (loss simulation): seq=%u\n", header->seq_num);
            log_drop_data(header->seq_num);
            continue;
        }
        
        // Check for FIN packet - peer wants to close connection
        if (header->flags & SHAM_FIN) {
            printf("Received FIN during data transfer\n");
            // Handle the incoming FIN
            if (sham_handle_incoming_fin(conn, header) > 0) {
                // FIN was handled, connection is now in CLOSE_WAIT
                // Return what we've received so far
                printf("Connection closing, returning %zu bytes received\n", total_received);
                return total_received;
            }
        }
        
        size_t data_len = received - sizeof(struct sham_header);
        char *data = packet_buffer + sizeof(struct sham_header);
        
        // Process the data packet (handles both in-order and out-of-order delivery)
        if (process_data_packet(&receiver, conn, header, data, data_len, 
                               buffer, buffer_size, &total_received) < 0) {
            // Error in processing
            break;
        }
        
        // Check if this was the last packet (partial data indicates end)
        if (data_len < SHAM_DATA_SIZE) {
            break;
        }
    }
    
    printf("Data reception completed: %zu bytes received\n", total_received);
    return total_received;
}

// Send a file
int sham_send_file(sham_connection_t *conn, const char *filename) {
    FILE *file = fopen(filename, "rb");
    if (!file) {
        perror("fopen");
        return -1;
    }
    
    // Get file size
    fseek(file, 0, SEEK_END);
    long file_size = ftell(file);
    fseek(file, 0, SEEK_SET);
    
    // Read entire file into memory (for simplicity)
    char *file_data = malloc(file_size);
    if (!file_data) {
        fclose(file);
        return -1;
    }
    
    fread(file_data, 1, file_size, file);
    fclose(file);
    
    // Send using sliding window protocol
    int result = sham_send_data(conn, file_data, file_size);
    
    free(file_data);
    return result;
}

// Receive a file
int sham_receive_file(sham_connection_t *conn, const char *filename) {
    FILE *file = fopen(filename, "wb");
    if (!file) {
        perror("Failed to open file for writing");
        return -1;
    }
    
    receiver_state_t receiver;
    init_receiver_state(&receiver, conn->ack_num);
    
    // Use a smaller buffer for chunked reception
    const size_t CHUNK_SIZE = 64 * 1024; // 64KB chunks
    char *buffer = malloc(CHUNK_SIZE);
    if (!buffer) {
        perror("Failed to allocate buffer");
        fclose(file);
        return -1;
    }
    
    size_t total_received = 0;
    int result = 0;
    
    // Set available buffer space to chunk size
    conn->available_buffer = CHUNK_SIZE;
    
    printf("Starting file reception to %s...\n", filename);
    
    while (1) {
        char packet_buffer[sizeof(struct sham_header) + SHAM_DATA_SIZE];
        
        ssize_t received = recvfrom(conn->sockfd, packet_buffer, sizeof(packet_buffer), 0, NULL, NULL);
        
        if (received < 0 || (size_t)received < sizeof(struct sham_header)) {
            continue;
        }
        
        struct sham_header *header = (struct sham_header*)packet_buffer;
        header->seq_num = ntohl(header->seq_num);
        header->ack_num = ntohl(header->ack_num);
        header->flags = ntohs(header->flags);
        header->window_size = ntohs(header->window_size);
        // Receiver-side packet loss simulation: drop packet probabilistically
        if (conn->loss_rate > 0.0 && ((float)rand() / RAND_MAX) < conn->loss_rate) {
            printf("Receiver dropped incoming file packet (loss simulation): seq=%u\n", header->seq_num);
            log_drop_data(header->seq_num);
            continue;
        }
        
        // Check for FIN packet - peer wants to close connection
        if (header->flags & SHAM_FIN) {
            printf("Received FIN during file transfer\n");
            // Handle the incoming FIN
            if (sham_handle_incoming_fin(conn, header) > 0) {
                // FIN was handled, connection is now in CLOSE_WAIT
                printf("Connection closing, file transfer complete: %zu bytes received\n", total_received);
                break;
            }
        }
        
        size_t data_len = received - sizeof(struct sham_header);
        char *data = packet_buffer + sizeof(struct sham_header);
        
        // Process the data packet for protocol state (ACKs, etc.)
        // This will handle writing to file and updating total_received
        if (process_file_packet(&receiver, conn, header, data, data_len, 
                               file, &total_received) < 0) {
            // Error in processing
            result = -1;
            break;
        }
        
        // Check if this was the last packet (partial data indicates end)
        if (data_len < SHAM_DATA_SIZE) {
            printf("Received last packet with %zu bytes\n", data_len);
            break;
        }
    }
    
    free(buffer);
    fclose(file);
    
    if (result == 0) {
        printf("File reception completed: %zu bytes written to %s\n", total_received, filename);
        return (int)total_received;  // Return number of bytes received on success
    }
    
    return result;
}
