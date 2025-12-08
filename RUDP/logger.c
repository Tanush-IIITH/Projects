#include "logger.h"
#include "sham.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/time.h>
#include <time.h>
#include <stdint.h>

static FILE *log_file = NULL;
static int logging_enabled = 0;

// Initialize logger based on role and environment variable
void logger_init(const char *role) {
    // Check if logging is enabled via environment variable
    const char *env_value = getenv("RUDP_LOG");
    if (!env_value || strcmp(env_value, "1") != 0) {
        logging_enabled = 0;
        return;
    }

    logging_enabled = 1;

    // Determine log file name based on role
    const char *filename;
    if (strcmp(role, "server") == 0) {
        filename = "server_log.txt";
    } else if (strcmp(role, "client") == 0) {
        filename = "client_log.txt";
    } else {
        fprintf(stderr, "Invalid role for logger: %s\n", role);
        logging_enabled = 0;
        return;
    }

    // Open log file for writing
    log_file = fopen(filename, "w");
    if (!log_file) {
        perror("Failed to open log file");
        logging_enabled = 0;
        return;
    }
}

// Close the log file
void logger_close(void) {
    if (log_file) {
        fclose(log_file);
        log_file = NULL;
    }
    logging_enabled = 0;
}

// Helper function to write timestamped log entry
static void write_log_entry(const char *message) {
    if (!logging_enabled || !log_file) {
        return;
    }

    char time_buffer[30];
    struct timeval tv;
    time_t curtime;

    gettimeofday(&tv, NULL);
    curtime = tv.tv_sec;

    // Format the time part
    strftime(time_buffer, 30, "%Y-%m-%d %H:%M:%S", localtime(&curtime));

    // Write timestamped log entry
    fprintf(log_file, "[%s.%06ld] [LOG] %s\n", time_buffer, tv.tv_usec, message);
    fflush(log_file); // Ensure immediate write
}

// Connection handshake logging
void log_snd_syn(uint32_t seq_num) {
    char message[100];
    sprintf(message, "SND SYN SEQ=%u", seq_num);
    write_log_entry(message);
}

void log_rcv_syn(uint32_t seq_num) {
    char message[100];
    sprintf(message, "RCV SYN SEQ=%u", seq_num);
    write_log_entry(message);
}

void log_snd_syn_ack(uint32_t seq_num, uint32_t ack_num) {
    char message[100];
    sprintf(message, "SND SYN-ACK SEQ=%u ACK=%u", seq_num, ack_num);
    write_log_entry(message);
}

void log_rcv_ack_for_syn(void) {
    write_log_entry("RCV ACK FOR SYN");
}

// Data transmission logging
void log_snd_data(uint32_t seq_num, size_t len) {
    char message[100];
    sprintf(message, "SND DATA SEQ=%u LEN=%zu", seq_num, len);
    write_log_entry(message);
}

void log_rcv_data(uint32_t seq_num, size_t len) {
    char message[100];
    sprintf(message, "RCV DATA SEQ=%u LEN=%zu", seq_num, len);
    write_log_entry(message);
}

// Acknowledgments logging
void log_snd_ack(uint32_t ack_num, uint16_t window_size) {
    char message[100];
    sprintf(message, "SND ACK=%u WIN=%u", ack_num, window_size);
    write_log_entry(message);
}

void log_rcv_ack(uint32_t ack_num) {
    char message[100];
    sprintf(message, "RCV ACK=%u", ack_num);
    write_log_entry(message);
}

// Retransmission logging
void log_timeout(uint32_t seq_num) {
    char message[100];
    sprintf(message, "TIMEOUT SEQ=%u", seq_num);
    write_log_entry(message);
}

void log_retx_data(uint32_t seq_num, size_t len) {
    char message[100];
    sprintf(message, "RETX DATA SEQ=%u LEN=%zu", seq_num, len);
    write_log_entry(message);
}

// Flow control logging
void log_flow_win_update(uint16_t new_window_size) {
    char message[100];
    sprintf(message, "FLOW WIN UPDATE=%u", new_window_size);
    write_log_entry(message);
}

// Simulated packet loss logging
void log_drop_data(uint32_t seq_num) {
    char message[100];
    sprintf(message, "DROP DATA SEQ=%u", seq_num);
    write_log_entry(message);
}

// Generic packet logging functions
void log_packet_sent(sham_connection_t *conn, uint16_t flags, uint32_t seq_num, uint32_t ack_num, uint16_t window_size, size_t len) {
    (void)conn; // conn not used in this implementation, silence unused-param warning
    if (!logging_enabled || !log_file) {
        return;
    }

    char message[200];
    if (flags == SHAM_SYN) {
        sprintf(message, "SND SYN SEQ=%u", seq_num);
    } else if (flags == (SHAM_SYN | SHAM_ACK)) {
        sprintf(message, "SND SYN-ACK SEQ=%u ACK=%u", seq_num, ack_num);
    } else if (flags == SHAM_ACK) {
        sprintf(message, "SND ACK=%u WIN=%u", ack_num, window_size);
    } else if (flags == SHAM_FIN) {
        sprintf(message, "SND FIN SEQ=%u", seq_num);
    } else if (flags == 0) {
        sprintf(message, "SND DATA SEQ=%u LEN=%zu", seq_num, len);
    } else {
        // Fallback for other combinations
        sprintf(message, "SND UNKNOWN FLAGS=%u SEQ=%u ACK=%u WIN=%u LEN=%zu", flags, seq_num, ack_num, window_size, len);
    }
    write_log_entry(message);
}

void log_packet_received(sham_connection_t *conn, uint16_t flags, uint32_t seq_num, uint32_t ack_num, uint16_t window_size, size_t len) {
    (void)conn; // silence unused-param
    if (!logging_enabled || !log_file) {
        return;
    }

    char message[200];
    if (flags == SHAM_SYN) {
        sprintf(message, "RCV SYN SEQ=%u", seq_num);
    } else if (flags == (SHAM_SYN | SHAM_ACK)) {
        sprintf(message, "RCV SYN-ACK SEQ=%u ACK=%u", seq_num, ack_num);
    } else if (flags == SHAM_ACK) {
        sprintf(message, "RCV ACK=%u", ack_num);
    } else if (flags == SHAM_FIN) {
        sprintf(message, "RCV FIN SEQ=%u", seq_num);
    } else if (flags == 0) {
        sprintf(message, "RCV DATA SEQ=%u LEN=%zu", seq_num, len);
    } else {
        // Fallback
        sprintf(message, "RCV UNKNOWN FLAGS=%u SEQ=%u ACK=%u WIN=%u LEN=%zu", flags, seq_num, ack_num, window_size, len);
    }
    write_log_entry(message);
}

// Retransmission logging
void log_retransmission(sham_connection_t *conn, uint32_t seq_num, int attempt) {
    (void)conn; // silence unused-param
    if (!logging_enabled || !log_file) {
        return;
    }

    char message[100];
    sprintf(message, "RETX DATA SEQ=%u ATTEMPT=%d", seq_num, attempt);
    write_log_entry(message);
}

// Connection event logging
void log_connection_event(sham_connection_t *conn, const char *event, const char *details) {
    (void)conn; // silence unused-param
    if (!logging_enabled || !log_file) {
        return;
    }

    char message[200];
    if (strlen(details) > 0) {
        sprintf(message, "EVENT %s: %s", event, details);
    } else {
        sprintf(message, "EVENT %s", event);
    }
    write_log_entry(message);
}
