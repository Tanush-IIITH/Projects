# Reliable UDP Protocol (RUDP)

**TCP-like Features Over UDP**

A custom transport-layer protocol built from scratch using C & UDP sockets.

## Overview

This project implements a reliable data transfer protocol on top of UDP, recreating core TCP functionalities while retaining the simplicity of UDP. All communication occurs using a custom packet format called the **S.H.A.M. packet**, sent inside UDP datagrams.

The protocol supports:

- Connection establishment & termination
- Reliable file transfer
- Real-time chat mode
- Sliding-window retransmission
- Cumulative acknowledgments
- Flow control
- Packet loss simulation
- High-precision verbose logging

## S.H.A.M. Packet Structure

Every message contains a header followed by application data.

```c
struct sham_header {
    uint32_t seq_num;      // Sequence Number
    uint32_t ack_num;      // Acknowledgment Number
    uint16_t flags;        // SYN, ACK, FIN
    uint16_t window_size;  // Receiver buffer availability
};
```

### Field Descriptions

- **seq_num**: Byte offset of the first byte in this packet.
- **ack_num**: Cumulative ACK; next expected byte.
- **flags**:
  - `0x1` → SYN
  - `0x2` → ACK
  - `0x4` → FIN
- **window_size**: Receiver-advertised buffer space (bytes).

## Connection Management

### Three-Way Handshake (Connect)

```
Client → Server : SYN, SEQ = X  
Server → Client : SYN+ACK, SEQ = Y, ACK = X+1  
Client → Server : ACK, ACK = Y+1
```

### Four-Way Handshake (Disconnect)

```
FIN → ACK → FIN → ACK
```

Both sides close the connection gracefully, mimicking TCP behavior.

## Data Transfer Features

### 1. Fixed-size Segmentation

Files and user input are split into 1024-byte segments, each wrapped inside a S.H.A.M. packet.

### 2. Sliding Window Protocol

- Sender maintains a fixed window (e.g., 10 packets).
- Can send multiple packets before waiting for ACKs.
- Prevents pipeline stalls.

### 3. Cumulative ACKs

The receiver sends an ACK for the highest contiguous sequence received.

**Example:**

```
Received: Packets 1, 2, 4
ACK sent: 3 (expects packet 3 next)
Packet 4 is buffered until missing packets arrive.
```

### 4. Retransmission Timeout (RTO)

Each packet maintains a timer (default: 500ms). On timeout, only the missing packet is retransmitted.

**Example: If packet 2 is lost**

```
TIMEOUT SEQ=1025  
RETX DATA SEQ=1025
```

Receiver eventually sends:

```
ACK=4097
```

(Sender knows packets 1–4 are all received).

## Flow Control

The Receiver advertises its available buffer in `window_size`. The Sender ensures:

$$\text{LastByteSent} - \text{LastByteAcked} \leq \text{receiver\_window}$$

This prevents buffer overflow and mimics TCP flow control.

## Program Execution

### Compilation (Linux)

```bash
gcc program.c -o program -lcrypto
```

### Server

```bash
./server <port> [--chat] [loss_rate]
```

### Client (File Transfer — default)

```bash
./client <server_ip> <server_port> <input_file> <output_file_name> [loss_rate]
```

### Client (Chat Mode)

```bash
./client <server_ip> <server_port> --chat [loss_rate]
```

### Options & Commands

| Option / Command | Description |
|------------------|-------------|
| `--chat` | Enables bi-directional real-time messaging. |
| `loss_rate` | Simulates packet drops (Float 0.0 to 1.0). |
| `/quit` | (Chat Mode) Initiates 4-way connection teardown. |

## Packet Loss Simulation

Receiver probabilistically drops packets based on `loss_rate`. Useful for testing retransmission logic.

**Log Entry Example:**

```
[LOG] DROP DATA SEQ=1025
```

## MD5 Verification (File Transfer Mode)

After complete file reception, the Server computes the MD5 checksum and prints it to stdout:

```
MD5: <32_char_md5_hash>
```

## Verbose Logging

Enable logging by setting the environment variable:

```bash
export RUDP_LOG=1
```

### Log Files:

- **Client**: `client_log.txt`
- **Server**: `server_log.txt`

### Format:

```
[YYYY-MM-DD HH:MM:SS.microseconds] [LOG] <message>
```

### Logged Events:

- SYN, SYN-ACK, ACK
- Data send/receive
- Cumulative ACKs
- Window updates
- Timeouts & Retransmissions
- Packet drops

### Example:

```
[2025-08-03 17:38:15.123589] [LOG] SND SYN-ACK SEQ=5000 ACK=101
```
