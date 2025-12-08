#pragma once

#include "sham.h"
#include <sys/socket.h>
#include <netinet/in.h>
#include <stdint.h>
#include <stdbool.h>

// Connection States
typedef enum {
    SHAM_CLOSED,        // No connection
    SHAM_LISTEN,        // Server waiting for connection
    SHAM_SYN_SENT,      // Client sent SYN, waiting for SYN-ACK
    SHAM_SYN_RECEIVED,  // Server received SYN, sent SYN-ACK, waiting for ACK
    SHAM_ESTABLISHED,   // Connection established
    SHAM_FIN_WAIT_1,    // Sent FIN, waiting for ACK
    SHAM_FIN_WAIT_2,    // Received ACK for FIN, waiting for FIN from other side
    SHAM_CLOSE_WAIT,    // Received FIN, sent ACK, waiting to send FIN
    SHAM_CLOSING,       // Both sides sent FIN (simultaneous close)
    SHAM_LAST_ACK       // Sent FIN after receiving FIN, waiting for final ACK
} sham_state_t;

// Connection structure
typedef struct {
    int sockfd;                    // UDP socket file descriptor
    //for client, peer - server it is connecting to and vice versa
    struct sockaddr_in remote_addr; // Remote address - represents peer's identity on the network (IP + port)
    socklen_t remote_addr_len;     // Remote address length
    
    sham_state_t state;            // Current connection state
    
    uint32_t seq_num;              // Our sequence number
    uint32_t ack_num;              // Expected sequence number from peer
    //maximum data that we can accept
    uint16_t window_size;          // Our receive window size
    //maximum data that the peer can accept
    uint16_t peer_window_size;     // Peer's advertised window size
    uint32_t available_buffer;     // Our available buffer space (for flow control)
    
    float loss_rate;               // Packet loss probability for testing
    
    bool is_server;                // True if this is server side
} sham_connection_t;

// Function declarations
int sham_socket(void);
int sham_bind(int sockfd, const struct sockaddr_in *addr);
int sham_listen(int sockfd);
int sham_accept(int sockfd, sham_connection_t *conn, float loss_rate);
int sham_connect(int sockfd, const struct sockaddr_in *server_addr, sham_connection_t *conn, float loss_rate);
int sham_close(sham_connection_t *conn);
int sham_handle_incoming_fin(sham_connection_t *conn, struct sham_header *header);

// Helper functions
int send_sham_packet(sham_connection_t *conn, uint16_t flags, const char *data, size_t data_len);
int receive_sham_packet(sham_connection_t *conn, struct sham_header *header, char *data, size_t max_data_len);
bool is_valid_packet(const struct sham_header *header, sham_connection_t *conn, uint16_t expected_flags);
