#pragma once

#include <stdint.h>

// S.H.A.M. Protocol Constants
#define INITIAL_WINDOW_SIZE 4096  // Initial window size for flow control (4KB)

// S.H.A.M. Protocol Flags
// These values are powers of 2 (0x1=2^0, 0x2=2^1, 0x4=2^2) to enable bitwise operations.
// Each flag occupies a unique bit position, allowing multiple flags to be combined
// using bitwise OR (|) and tested using bitwise AND (&).
// Example: SYN-ACK packet = SHAM_SYN | SHAM_ACK = 0x1 | 0x2 = 0x3
// This follows TCP flag design and enables efficient flag manipulation.
#define SHAM_SYN 0x1  // Synchronise - Used to initiate a connection
#define SHAM_ACK 0x2  // Acknowledge - Indicates the ack_num field is significant  
#define SHAM_FIN 0x4  // Finish - Used to terminate a connection

// S.H.A.M. Header Structure
struct sham_header {
    uint32_t seq_num;     // Sequence Number - byte-stream number of first byte in data segment
    uint32_t ack_num;     // Acknowledgment Number - next sequence number expected (cumulative ACK)
    uint16_t flags;       // Control flags (SYN, ACK, FIN)
    uint16_t window_size; // Flow control window size - bytes sender is willing to accept
};
