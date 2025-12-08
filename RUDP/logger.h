#pragma once

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>
#include <time.h>
#include <stdint.h>

// Use the connection typedef so signatures match the rest of the code
#include "connection.h"

// Logger initialization and management
void logger_init(const char *role);
void logger_close(void);

// Generic packet logging functions
void log_packet_sent(sham_connection_t *conn, uint16_t flags, uint32_t seq_num, uint32_t ack_num, uint16_t window_size, size_t len);
void log_packet_received(sham_connection_t *conn, uint16_t flags, uint32_t seq_num, uint32_t ack_num, uint16_t window_size, size_t len);

// Retransmission logging
void log_retransmission(sham_connection_t *conn, uint32_t seq_num, int attempt);

// Connection event logging
void log_connection_event(sham_connection_t *conn, const char *event, const char *details);

// Legacy functions for backward compatibility
void log_snd_syn(uint32_t seq_num);
void log_rcv_syn(uint32_t seq_num);
void log_snd_syn_ack(uint32_t seq_num, uint32_t ack_num);
void log_rcv_ack_for_syn(void);

// Data transmission logging
void log_snd_data(uint32_t seq_num, size_t len);
void log_rcv_data(uint32_t seq_num, size_t len);

// Acknowledgments logging
void log_snd_ack(uint32_t ack_num, uint16_t window_size);
void log_rcv_ack(uint32_t ack_num);

// Retransmission logging
void log_timeout(uint32_t seq_num);
void log_retx_data(uint32_t seq_num, size_t len);

// Flow control logging
void log_flow_win_update(uint16_t new_window_size);

// Simulated packet loss logging
void log_drop_data(uint32_t seq_num);
