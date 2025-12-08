#pragma once

#ifndef _POSIX_C_SOURCE
#define _POSIX_C_SOURCE 199309L
#endif

#include "sham.h"
#include "connection.h"
#include <stdint.h>
#include <stdbool.h>
#include <time.h>

// Data transfer constants
#define SHAM_DATA_SIZE 1024        // Fixed chunk size (1024 bytes)
#define SHAM_WINDOW_SIZE 10        // Sliding window size (10 packets)
#define SHAM_RTO_MS 500           // Retransmission timeout (500ms)
#define SHAM_MAX_RETRIES 20       // Maximum retransmission attempts

// Packet state for sliding window
typedef enum {
    PACKET_EMPTY,      // Slot is empty
    PACKET_SENT,       // Packet sent, waiting for ACK
    PACKET_ACKED       // Packet acknowledged
} packet_state_t;

// Sliding window entry
typedef struct {
    packet_state_t state;          // Current state of this packet
    uint32_t seq_num;              // Sequence number of this packet
    char data[SHAM_DATA_SIZE];     // Data payload
    size_t data_len;               // Actual data length (may be < SHAM_DATA_SIZE)
    struct timespec send_time;     // When packet was sent (for RTO)
    int retry_count;               // Number of retransmission attempts
} window_entry_t;

// Sliding window for sender
typedef struct {
    window_entry_t packets[SHAM_WINDOW_SIZE];  // Window entries
    int base;                      // First unacknowledged packet index
    int next_seq;                  // Next sequence number to send
    int window_used;               // Number of packets currently in window
    uint32_t base_seq_num;         // Sequence number of base packet
} sliding_window_t;

// Receiver buffer for out-of-order packets
typedef struct {
    bool received;                 // Has this packet been received?
    char data[SHAM_DATA_SIZE];     // Data payload
    size_t data_len;               // Data length
} receive_buffer_entry_t;

// Receiver state
typedef struct {
    uint32_t expected_seq;         // Next expected sequence number
    receive_buffer_entry_t buffer[SHAM_WINDOW_SIZE * 2];  // Buffer for out-of-order packets
    int buffer_base;               // Base index in circular buffer
} receiver_state_t;

// Data transfer functions
int sham_send_file(sham_connection_t *conn, const char *filename);
int sham_receive_file(sham_connection_t *conn, const char *filename);
int sham_send_data(sham_connection_t *conn, const char *data, size_t total_len);
int sham_receive_data(sham_connection_t *conn, char *buffer, size_t buffer_size);

// Helper functions
void init_sliding_window(sliding_window_t *window, uint32_t initial_seq);
void init_receiver_state(receiver_state_t *receiver, uint32_t initial_seq);
bool is_timeout(const struct timespec *send_time, int timeout_ms);
int send_data_packet(sham_connection_t *conn, uint32_t seq_num, const char *data, size_t data_len);
int send_ack_packet(sham_connection_t *conn, uint32_t ack_num);
void process_ack(sliding_window_t *window, sham_connection_t *conn, uint32_t ack_num, uint16_t peer_window);
int process_data_packet(receiver_state_t *receiver, sham_connection_t *conn, 
                       const struct sham_header *header, const char *data, size_t data_len,
                       char *output_buffer, size_t buffer_size, size_t *bytes_received);
bool can_send_packet(const sliding_window_t *window);
bool can_send_flow_control(sham_connection_t *conn, const sliding_window_t *window, size_t next_packet_size);
int get_next_timeout_packet(const sliding_window_t *window);
void retransmit_packet(sham_connection_t *conn, sliding_window_t *window, int index);
