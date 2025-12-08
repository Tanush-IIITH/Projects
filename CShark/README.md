# C-Shark: Terminal-Based Packet Sniffer

A lightweight, terminal-native alternative to Wireshark, built in C using libpcap.

## Overview

C-Shark is a feature-rich, terminal-based packet sniffer built on top of the libpcap library. It provides real-time packet capture, multi-layer protocol decoding, protocol-level filtering, session storage, and deep forensic inspection—all within the terminal.

Designed as a minimal yet powerful network analysis tool, C-Shark dissects packets across:

- **Layer 2**: Ethernet
- **Layer 3**: IPv4, IPv6, ARP
- **Layer 4**: TCP, UDP
- **Layer 7**: DNS, HTTP, HTTPS, plus generic payload inspection

With features like interface discovery, packet filtering, structured decoding, and Wireshark-style hex dumps, C-Shark serves as a compact cybersecurity diagnostic tool.

## Features

### Interface Discovery

Automatically scans and lists all available network interfaces. The user selects one to begin sniffing.

### Live Packet Capture

Captures all packets using libpcap and displays:

- Packet ID
- Timestamp
- Packet length
- MAC addresses
- First 16 bytes (Phase 1) or full decoded details (Phase 2)

Graceful interrupt handling:

- `Ctrl+C` → stop capture and return to menu
- `Ctrl+D` → exit program

### Multi-Layer Packet Decoding

C-Shark breaks down packets layer-by-layer across the OSI stack:

#### Ethernet (Layer 2)

- Source and destination MAC addresses
- EtherType detection (IPv4, IPv6, ARP)

#### IPv4 (Layer 3)

- Source and destination IP addresses
- TTL (Time To Live)
- Protocol (TCP/UDP)
- Header length
- Packet ID
- Flags (DF, MF)

#### IPv6 (Layer 3)

- Source and destination IP addresses
- Traffic class
- Hop limit
- Flow label
- Next header (TCP/UDP)

#### ARP (Layer 3)

- Operation (Request/Reply)
- Sender and Target IP addresses
- Sender and Target MAC addresses

#### TCP (Layer 4)

- Source and destination ports with service identification (HTTP/HTTPS/DNS/etc.)
- Sequence and acknowledgement numbers
- Control flags (SYN, ACK, PSH, FIN)
- Window size
- Header length
- Checksum validation

#### UDP (Layer 4)

- Source and destination ports
- Packet length
- Checksum validation

### Deep Payload Inspection (Layer 7)

For recognizable protocols (DNS, HTTP, HTTPS), C-Shark identifies the application layer and displays:

- Payload size
- First 64 bytes in hexadecimal and ASCII format (Wireshark-style hex dump)

Example output:

```
16 03 03 00 25 10 00 00 21 20 A3 F9 BF D4 D4 6C   ....%...! .....l
CC 8F CC E8 61 9C 93 F0 09 1A DB A7 F0 41 BF 78   ....a.......A.x
```

### Packet Filtering

C-Shark supports protocol-level filtered sniffing using Berkeley Packet Filter (BPF):

- HTTP
- HTTPS
- DNS
- ARP
- TCP
- UDP

Filtering leverages libpcap's efficient BPF mechanism to match packets at the kernel level.

### Session Storage & Inspection

C-Shark stores captured packets from the most recent session in memory with the following capabilities:

- Customizable buffer size (MAX_PACKETS)
- Automatic cleanup before new captures to prevent memory leaks
- Inspect Last Session mode:
  - Displays a summarized list of all captured packets
  - User selects a packet ID for detailed analysis
  - Full breakdown with complete hex dump

## Example Workflow

1. Launch C-Shark:
   ```bash
   sudo ./cshark
   ```

2. Select a network interface

3. Choose operation mode:
   - Live packet sniffing
   - Sniffing with protocol filter
   - Inspect previous session

4. View structured packet breakdowns in real-time

5. Perform forensic inspection on specific packets

## Technologies Used

- **C Programming Language**
- **libpcap** for packet capture
- **Low-level networking headers**:
  - `<net/ethernet.h>`
  - `<netinet/ip.h>`
  - `<netinet/ip6.h>`
  - `<netinet/tcp.h>`
  - `<netinet/udp.h>`
  - `<netinet/ip_icmp.h>`
  - `<net/if_arp.h>`
  - `<arpa/inet.h>`
- Terminal UI design
- Hex dump formatting
- Dynamic memory management

## Build and Execution

### Compilation

```bash
make
```

### Running C-Shark

```bash
sudo ./cshark
```

Note: Packet sniffing requires root privileges.

## Safety and Legal Notes

- **Root privileges**: Packet sniffing requires elevated system privileges.
- **Read-only operation**: C-Shark is strictly a read-only sniffer and does not inject or modify packets.
- **Intended use**: Designed for educational, debugging, and authorized network analysis purposes only.

## Learning Outcomes

This project demonstrates:

- Deep understanding of packet structure across OSI layers
- Manual decoding of Ethernet, IP, ARP, TCP, and UDP headers
- Practical experience with libpcap and raw network analysis
- Terminal-based user interface design
- Memory management and modular system architecture
- Validation and debugging using Wireshark

## Summary

C-Shark brings together low-level networking, protocol dissection, and terminal-based UI design into a compact, extensible packet-sniffing tool. Whether for cybersecurity training, network debugging, teaching, or systems exploration, C-Shark offers a fast, dependency-light alternative to graphical sniffers—all accessible from your terminal.
