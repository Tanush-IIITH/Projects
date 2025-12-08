#include <pcap.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <time.h>
#include <sys/types.h>
#include <unistd.h>
#include <net/ethernet.h>
#include <netinet/ip.h>
#include <netinet/ip6.h>
#include <netinet/ip_icmp.h>
#include <net/if_arp.h>
#include <arpa/inet.h>

// TCP Header structure
struct tcp_header {
    uint16_t source_port;
    uint16_t dest_port;
    uint32_t seq_num;
    uint32_t ack_num;
    uint8_t data_offset;
    uint8_t flags;
    uint16_t window;
    uint16_t checksum;
    uint16_t urgent_ptr;
} __attribute__((packed));

// UDP Header structure
struct udp_header {
    uint16_t source_port;
    uint16_t dest_port;
    uint16_t length;
    uint16_t checksum;
} __attribute__((packed));

// TCP flags
#define TCP_FIN 0x01
#define TCP_SYN 0x02
#define TCP_RST 0x04
#define TCP_PSH 0x08
#define TCP_ACK 0x10
#define TCP_URG 0x20

// Maximum number of packets to store - currently the first 10000 packets are stored not the latest 10000
#define MAX_PACKETS 10000

/*
The 4 byte discrepancy is due to libcap adding a pseudo header to the beginning of every packet - which contains the metadata
c shark reports the total length including this header, while the actual packet data starts after this header.
wireshark is smart - it reads that header and hides it - showing the actual packet length

The ACK and SEQ numbers differ as cshark shows the absolute numbers, while wireshark shows the relative numbers
*/

// Structure to store a captured packet
struct stored_packet {
    struct pcap_pkthdr header;  // Packet header with timestamp and length
    unsigned char *data;         // Copy of the packet data
    int id;                      // Packet ID in the session
};

// Global variables
pcap_t *handle = NULL;
int packet_count = 0;
volatile sig_atomic_t sniffing_active = 0;

// Session storage
struct stored_packet *session_packets[MAX_PACKETS];
int session_packet_count = 0;

// Helper function to identify common ports
const char* get_port_name(uint16_t port) {
    switch (port) {
        case 20: return "FTP-DATA";
        case 21: return "FTP";
        case 22: return "SSH";
        case 23: return "Telnet";
        case 25: return "SMTP";
        case 53: return "DNS";
        case 80: return "HTTP";
        case 110: return "POP3";
        case 143: return "IMAP";
        case 443: return "HTTPS";
        case 465: return "SMTPS";
        case 587: return "SMTP";
        case 993: return "IMAPS";
        case 995: return "POP3S";
        case 3306: return "MySQL";
        case 5432: return "PostgreSQL";
        case 8080: return "HTTP-Alt";
        default: return NULL;
    }
}

// Helper function to identify application protocol
const char* identify_app_protocol(uint16_t src_port, uint16_t dst_port) {
    if (src_port == 80 || dst_port == 80) return "HTTP";
    if (src_port == 443 || dst_port == 443) return "HTTPS/TLS";
    if (src_port == 53 || dst_port == 53) return "DNS";
    if (src_port == 22 || dst_port == 22) return "SSH";
    if (src_port == 21 || dst_port == 21) return "FTP";
    if (src_port == 25 || dst_port == 25) return "SMTP";
    return "Unknown";
}

// Helper function to print hex dump
void print_hex_dump(const unsigned char *data, int length) {
    int bytes_to_print = (length < 64) ? length : 64;
    
    for (int i = 0; i < bytes_to_print; i += 16) {
        // Print hex values
        for (int j = 0; j < 16 && (i + j) < bytes_to_print; j++) {
            printf("%02X ", data[i + j]);
        }
        
        // Pad if less than 16 bytes on this line
        for (int j = bytes_to_print - i; j < 16; j++) {
            printf("   ");
        }
        
        // Print ASCII representation
        for (int j = 0; j < 16 && (i + j) < bytes_to_print; j++) {
            unsigned char c = data[i + j];
            if (c >= 32 && c <= 126) {
                printf("%c", c);
            } else {
                printf(".");
            }
        }
        printf("\n");
    }
}

/*
Function to free all stored packets from previous session
*/
void free_session_packets() {
    for (int i = 0; i < session_packet_count; i++) {
        if (session_packets[i] != NULL) {
            if (session_packets[i]->data != NULL) {
                free(session_packets[i]->data);
            }
            free(session_packets[i]);
            session_packets[i] = NULL;
        }
    }
    session_packet_count = 0;
}

/*
Function to store a packet in the session
*/
void store_packet(const struct pcap_pkthdr *pkthdr, const unsigned char *packet) {
    if (session_packet_count >= MAX_PACKETS) {
        // Session storage is full, skip storing
        return;
    }
    
    // Allocate memory for the stored packet
    struct stored_packet *stored = (struct stored_packet *)malloc(sizeof(struct stored_packet));
    if (stored == NULL) {
        fprintf(stderr, "Error: Failed to allocate memory for packet storage\n");
        return;
    }
    
    // Copy packet header
    stored->header = *pkthdr;
    stored->id = session_packet_count + 1;
    
    // Allocate and copy packet data
    stored->data = (unsigned char *)malloc(pkthdr->caplen);
    if (stored->data == NULL) {
        fprintf(stderr, "Error: Failed to allocate memory for packet data\n");
        free(stored);
        return;
    }
    memcpy(stored->data, packet, pkthdr->caplen);
    
    // Store in session array
    session_packets[session_packet_count] = stored;
    session_packet_count++;
}

/*
Packet handler function for processing captured packets.
pkthdr: Pointer to the packet header containing metadata like timestamp and length.
packet: Pointer to the actual packet data.
*/
void packet_handler(unsigned char *user, const struct pcap_pkthdr *pkthdr, const unsigned char *packet) {
    (void)user;
    packet_count++;
    
    // Store the packet in the session
    store_packet(pkthdr, packet);
    
    printf("-----------------------------------------\n");
    printf("Packet #%d | Timestamp: %ld.%06ld | Length: %d bytes\n",
           packet_count, pkthdr->ts.tv_sec, pkthdr->ts.tv_usec, pkthdr->len);
    
    // Decode Ethernet header (Layer 2)
    struct ether_header *eth_header = (struct ether_header *)packet;
    
    printf("L2 (Ethernet): Dst MAC: %02X:%02X:%02X:%02X:%02X:%02X | Src MAC: %02X:%02X:%02X:%02X:%02X:%02X | ",
           eth_header->ether_dhost[0], eth_header->ether_dhost[1], eth_header->ether_dhost[2],
           eth_header->ether_dhost[3], eth_header->ether_dhost[4], eth_header->ether_dhost[5],
           eth_header->ether_shost[0], eth_header->ether_shost[1], eth_header->ether_shost[2],
           eth_header->ether_shost[3], eth_header->ether_shost[4], eth_header->ether_shost[5]);
    
    // Get EtherType
    uint16_t ether_type = ntohs(eth_header->ether_type);
    
    printf("EtherType: ");
    switch (ether_type) {
        case ETHERTYPE_IP:
            printf("IPv4 (0x%04X)\n", ether_type);
            break;
        case ETHERTYPE_IPV6:
            printf("IPv6 (0x%04X)\n", ether_type);
            break;
        case ETHERTYPE_ARP:
            printf("ARP (0x%04X)\n", ether_type);
            break;
        default:
            printf("Unknown (0x%04X)\n", ether_type);
            break;
    }
    
    // Decode Layer 3 based on EtherType
    const unsigned char *layer3_packet = packet + sizeof(struct ether_header); //location of the layer 3 header
    
    if (ether_type == ETHERTYPE_IP) {
        // IPv4 packet
        struct iphdr *ip_header = (struct iphdr *)layer3_packet; //typecast to easily access IP header fields
        
        //store string representations of IPs
        char src_ip[INET_ADDRSTRLEN]; 
        char dst_ip[INET_ADDRSTRLEN];

        //hold binary representations of IPs
        struct in_addr src_addr, dst_addr;
        src_addr.s_addr = ip_header->saddr;
        dst_addr.s_addr = ip_header->daddr;
        
        // Convert binary IPs to string format
        inet_ntop(AF_INET, &src_addr, src_ip, INET_ADDRSTRLEN);
        inet_ntop(AF_INET, &dst_addr, dst_ip, INET_ADDRSTRLEN);
        
        printf("L3 (IPv4): Src IP: %s | Dst IP: %s | Protocol: ", src_ip, dst_ip);
        
        // Decode protocol
        switch (ip_header->protocol) {
            case IPPROTO_TCP:
                printf("TCP (%d)", ip_header->protocol);
                break;
            case IPPROTO_UDP:
                printf("UDP (%d)", ip_header->protocol);
                break;
            case IPPROTO_ICMP:
                printf("ICMP (%d)", ip_header->protocol);
                break;
            default:
                printf("Unknown (%d)", ip_header->protocol);
                break;
        }
        
        printf(" | TTL: %d\n", ip_header->ttl);
        printf("       ID: 0x%04X | Total Length: %d | Header Length: %d bytes",
               ntohs(ip_header->id), ntohs(ip_header->tot_len), ip_header->ihl * 4);
        
        // Decode flags
        uint16_t flags_offset = ntohs(ip_header->frag_off); //contains fragmentation flags and offset
        int flag_df = (flags_offset & 0x4000) != 0;  // Don't Fragment - do not break the packet into more fragments
        int flag_mf = (flags_offset & 0x2000) != 0;  // More Fragments - this is a part of the larger packet, if not set either the last packet of the larger part or it's a complete, unfragmented packet
        
        if (flag_df || flag_mf) {
            printf(" | Flags: [");
            if (flag_df) printf("DF");
            if (flag_df && flag_mf) printf(",");
            if (flag_mf) printf("MF");
            printf("]");
        }
        printf("\n");
        
        // Decode Layer 4 for IPv4
        const unsigned char *layer4_packet = layer3_packet + (ip_header->ihl * 4);
        
        if (ip_header->protocol == IPPROTO_TCP) {
            struct tcp_header *tcp_hdr = (struct tcp_header *)layer4_packet; //provides easy access to TCP fields
            uint16_t src_port = ntohs(tcp_hdr->source_port);
            uint16_t dst_port = ntohs(tcp_hdr->dest_port);
            
            printf("L4 (TCP): Src Port: %d", src_port);
            const char *src_name = get_port_name(src_port);
            if (src_name) printf(" (%s)", src_name);
            
            printf(" | Dst Port: %d", dst_port);
            const char *dst_name = get_port_name(dst_port);
            if (dst_name) printf(" (%s)", dst_name);
            
            printf(" | Seq: %u | Ack: %u | Flags: [",
                   ntohl(tcp_hdr->seq_num), ntohl(tcp_hdr->ack_num));
            
            // Decode TCP flags
            int flag_printed = 0;
            if (tcp_hdr->flags & TCP_FIN) { if (flag_printed++) printf(","); printf("FIN"); }
            if (tcp_hdr->flags & TCP_SYN) { if (flag_printed++) printf(","); printf("SYN"); }
            if (tcp_hdr->flags & TCP_RST) { if (flag_printed++) printf(","); printf("RST"); }
            if (tcp_hdr->flags & TCP_PSH) { if (flag_printed++) printf(","); printf("PSH"); }
            if (tcp_hdr->flags & TCP_ACK) { if (flag_printed++) printf(","); printf("ACK"); }
            if (tcp_hdr->flags & TCP_URG) { if (flag_printed++) printf(","); printf("URG"); }
            
            printf("]\n");
            printf("       Window: %d | Checksum: 0x%04X | Header Length: %d bytes\n",
                   ntohs(tcp_hdr->window), ntohs(tcp_hdr->checksum), (tcp_hdr->data_offset >> 4) * 4);
            
            // Layer 7 - Payload
            int tcp_header_len = (tcp_hdr->data_offset >> 4) * 4;
            const unsigned char *payload = layer4_packet + tcp_header_len;
            int payload_len = ntohs(ip_header->tot_len) - (ip_header->ihl * 4) - tcp_header_len;
            
            if (payload_len > 0) {
                const char *app_proto = identify_app_protocol(src_port, dst_port);
                printf("L7 (Payload): Identified as %s on port %d - %d bytes\n",
                       app_proto, (dst_port == 80 || dst_port == 443 || dst_port == 53) ? dst_port : src_port, payload_len);
                printf("Data (first %d bytes):\n", (payload_len < 64) ? payload_len : 64);
                print_hex_dump(payload, payload_len);
            }
                   
        } else if (ip_header->protocol == IPPROTO_UDP) {
            struct udp_header *udp_hdr = (struct udp_header *)layer4_packet;
            uint16_t src_port = ntohs(udp_hdr->source_port);
            uint16_t dst_port = ntohs(udp_hdr->dest_port);
            
            printf("L4 (UDP): Src Port: %d", src_port);
            const char *src_name = get_port_name(src_port);
            if (src_name) printf(" (%s)", src_name);
            
            printf(" | Dst Port: %d", dst_port);
            const char *dst_name = get_port_name(dst_port);
            if (dst_name) printf(" (%s)", dst_name);
            
            printf(" | Length: %d | Checksum: 0x%04X\n",
                   ntohs(udp_hdr->length), ntohs(udp_hdr->checksum));
            
            // Layer 7 - Payload
            const unsigned char *payload = layer4_packet + sizeof(struct udp_header);
            int payload_len = ntohs(udp_hdr->length) - sizeof(struct udp_header);
            
            if (payload_len > 0) {
                const char *app_proto = identify_app_protocol(src_port, dst_port);
                printf("L7 (Payload): Identified as %s on port %d - %d bytes\n",
                       app_proto, (dst_port == 80 || dst_port == 443 || dst_port == 53) ? dst_port : src_port, payload_len);
                printf("Data (first %d bytes):\n", (payload_len < 64) ? payload_len : 64);
                print_hex_dump(payload, payload_len);
            }
        }
        
    } else if (ether_type == ETHERTYPE_IPV6) {
        // IPv6 packet
        struct ip6_hdr *ipv6_header = (struct ip6_hdr *)layer3_packet; //get the IPv6 header
        
        char src_ip[INET6_ADDRSTRLEN];
        char dst_ip[INET6_ADDRSTRLEN];
        inet_ntop(AF_INET6, &(ipv6_header->ip6_src), src_ip, INET6_ADDRSTRLEN); //get the string representation of the source IP
        inet_ntop(AF_INET6, &(ipv6_header->ip6_dst), dst_ip, INET6_ADDRSTRLEN); //get the string representation of the destination IP
        
        printf("L3 (IPv6): Src IP: %s | Dst IP: %s\n", src_ip, dst_ip);
        
        uint8_t next_header = ipv6_header->ip6_nxt;
        printf("       Next Header: ");
        switch (next_header) {
            case IPPROTO_TCP:
                printf("TCP (%d)", next_header);
                break;
            case IPPROTO_UDP:
                printf("UDP (%d)", next_header);
                break;
            case IPPROTO_ICMPV6:
                printf("ICMPv6 (%d)", next_header);
                break;
            default:
                printf("Unknown (%d)", next_header);
                break;
        }
        
        // Extract traffic class and flow label
        uint32_t vtc_flow = ntohl(ipv6_header->ip6_flow);
        uint8_t traffic_class = (vtc_flow >> 20) & 0xFF; //specifies the priority of the packet
        uint32_t flow_label = vtc_flow & 0xFFFFF; //identify specific flow of packets b/w src and dst
        
        printf(" | Hop Limit: %d | Traffic Class: %d | Flow Label: 0x%05X | Payload Length: %d\n",
               ipv6_header->ip6_hlim, traffic_class, flow_label, ntohs(ipv6_header->ip6_plen));
        
        // Decode Layer 4 for IPv6
        const unsigned char *layer4_packet = layer3_packet + sizeof(struct ip6_hdr);
        
        if (next_header == IPPROTO_TCP) {
            struct tcp_header *tcp_hdr = (struct tcp_header *)layer4_packet;
            uint16_t src_port = ntohs(tcp_hdr->source_port);
            uint16_t dst_port = ntohs(tcp_hdr->dest_port);
            
            printf("L4 (TCP): Src Port: %d", src_port);
            const char *src_name = get_port_name(src_port);
            if (src_name) printf(" (%s)", src_name);
            
            printf(" | Dst Port: %d", dst_port);
            const char *dst_name = get_port_name(dst_port);
            if (dst_name) printf(" (%s)", dst_name);
            
            printf(" | Seq: %u | Ack: %u | Flags: [",
                   ntohl(tcp_hdr->seq_num), ntohl(tcp_hdr->ack_num));
            
            // Decode TCP flags
            int flag_printed = 0;
            if (tcp_hdr->flags & TCP_FIN) { if (flag_printed++) printf(","); printf("FIN"); }
            if (tcp_hdr->flags & TCP_SYN) { if (flag_printed++) printf(","); printf("SYN"); }
            if (tcp_hdr->flags & TCP_RST) { if (flag_printed++) printf(","); printf("RST"); }
            if (tcp_hdr->flags & TCP_PSH) { if (flag_printed++) printf(","); printf("PSH"); }
            if (tcp_hdr->flags & TCP_ACK) { if (flag_printed++) printf(","); printf("ACK"); }
            if (tcp_hdr->flags & TCP_URG) { if (flag_printed++) printf(","); printf("URG"); }
            
            printf("]\n");
            printf("       Window: %d | Checksum: 0x%04X | Header Length: %d bytes\n",
                   ntohs(tcp_hdr->window), ntohs(tcp_hdr->checksum), (tcp_hdr->data_offset >> 4) * 4);
            
            // Layer 7 - Payload
            int tcp_header_len = (tcp_hdr->data_offset >> 4) * 4;
            const unsigned char *payload = layer4_packet + tcp_header_len;
            int payload_len = ntohs(ipv6_header->ip6_plen) - tcp_header_len;
            
            if (payload_len > 0) {
                const char *app_proto = identify_app_protocol(src_port, dst_port);
                printf("L7 (Payload): Identified as %s on port %d - %d bytes\n",
                       app_proto, (dst_port == 80 || dst_port == 443 || dst_port == 53) ? dst_port : src_port, payload_len);
                printf("Data (first %d bytes):\n", (payload_len < 64) ? payload_len : 64);
                print_hex_dump(payload, payload_len);
            }
                   
        } else if (next_header == IPPROTO_UDP) {
            struct udp_header *udp_hdr = (struct udp_header *)layer4_packet;
            uint16_t src_port = ntohs(udp_hdr->source_port);
            uint16_t dst_port = ntohs(udp_hdr->dest_port);
            
            printf("L4 (UDP): Src Port: %d", src_port);
            const char *src_name = get_port_name(src_port);
            if (src_name) printf(" (%s)", src_name);
            
            printf(" | Dst Port: %d", dst_port);
            const char *dst_name = get_port_name(dst_port);
            if (dst_name) printf(" (%s)", dst_name);
            
            printf(" | Length: %d | Checksum: 0x%04X\n",
                   ntohs(udp_hdr->length), ntohs(udp_hdr->checksum));
            
            // Layer 7 - Payload
            const unsigned char *payload = layer4_packet + sizeof(struct udp_header);
            int payload_len = ntohs(udp_hdr->length) - sizeof(struct udp_header);
            
            if (payload_len > 0) {
                const char *app_proto = identify_app_protocol(src_port, dst_port);
                printf("L7 (Payload): Identified as %s on port %d - %d bytes\n",
                       app_proto, (dst_port == 80 || dst_port == 443 || dst_port == 53) ? dst_port : src_port, payload_len);
                printf("Data (first %d bytes):\n", (payload_len < 64) ? payload_len : 64);
                print_hex_dump(payload, payload_len);
            }
        }
        
    } else if (ether_type == ETHERTYPE_ARP) {
        // ARP packet
        struct arphdr *arp_header = (struct arphdr *)layer3_packet; //get the arp header
        
        printf("\nL3 (ARP): Operation: ");
        uint16_t arp_op = ntohs(arp_header->ar_op); //read the operation code (request or reply)
        switch (arp_op) {
            case ARPOP_REQUEST:
                printf("Request (%d)", arp_op);
                break;
            case ARPOP_REPLY:
                printf("Reply (%d)", arp_op);
                break;
            default:
                printf("Unknown (%d)", arp_op);
                break;
        }
        
        // Extract sender and target MAC/IP addresses
        unsigned char *arp_data = (unsigned char *)(layer3_packet + sizeof(struct arphdr));
        unsigned char *sender_mac = arp_data;
        unsigned char *sender_ip = arp_data + 6;
        unsigned char *target_mac = arp_data + 10;
        unsigned char *target_ip = arp_data + 16;
        
        printf(" | Sender IP: %d.%d.%d.%d | Target IP: %d.%d.%d.%d\n",
               sender_ip[0], sender_ip[1], sender_ip[2], sender_ip[3],
               target_ip[0], target_ip[1], target_ip[2], target_ip[3]);
        
        printf("       Sender MAC: %02X:%02X:%02X:%02X:%02X:%02X | Target MAC: %02X:%02X:%02X:%02X:%02X:%02X\n",
               sender_mac[0], sender_mac[1], sender_mac[2], sender_mac[3], sender_mac[4], sender_mac[5],
               target_mac[0], target_mac[1], target_mac[2], target_mac[3], target_mac[4], target_mac[5]);
        
        printf("       HW Type: %d | Proto Type: 0x%04X | HW Len: %d | Proto Len: %d\n",
               ntohs(arp_header->ar_hrd), ntohs(arp_header->ar_pro),
               arp_header->ar_hln, arp_header->ar_pln);
    }
}

void handle_sigint(int sig) {
    (void)sig;
    if (sniffing_active && handle != NULL) {
        // Only break the pcap loop if we're actively sniffing
        pcap_breakloop(handle);
    } else {
        // If not sniffing, just ignore (don't exit)
        printf("\n[C-Shark] Press Ctrl+D to exit, or select option 4.\n");  
    }
}

/*
Function to get BPF filter string based on user's protocol choice
*/
const char* get_filter_for_protocol(int filter_choice) {
    switch (filter_choice) {
        case 1: // HTTP
            return "tcp port 80";
        case 2: // HTTPS
            return "tcp port 443";
        case 3: // DNS
            return "udp port 53 or tcp port 53";
        case 4: // ARP
            return "arp";
        case 5: // TCP
            return "tcp";
        case 6: // UDP
            return "udp";
        default:
            return NULL;
    }
}

/*
Function to display filter menu and get user's choice
*/
int show_filter_menu() {
    printf("\n[C-Shark] Select a protocol filter:\n\n");
    printf("1. HTTP (TCP port 80)\n");
    printf("2. HTTPS (TCP port 443)\n");
    printf("3. DNS (UDP/TCP port 53)\n");
    printf("4. ARP\n");
    printf("5. TCP (all TCP traffic)\n");
    printf("6. UDP (all UDP traffic)\n");
    printf("7. Cancel and return to main menu\n");
    printf("\nEnter your choice (1-7): ");
    fflush(stdout);
    
    int choice;
    if (scanf("%d", &choice) != 1) {
        // Handle EOF (Ctrl+D) or input error
        if (feof(stdin)) {
            printf("\n[C-Shark] Exiting...\n");
            exit(0);
        }
        // Clear input buffer on error
        int c;
        while ((c = getchar()) != '\n' && c != EOF);
        return 0; // Signal invalid input
    }
    
    return choice;
}

/*
Function to print a complete hex dump of packet data
*/
void print_full_hex_dump(const unsigned char *data, int length) {
    for (int i = 0; i < length; i += 16) {
        // Print offset
        printf("%04X: ", i);
        
        // Print hex values
        for (int j = 0; j < 16; j++) {
            if (i + j < length) {
                printf("%02X ", data[i + j]);
            } else {
                printf("   ");
            }
        }
        
        printf(" | ");
        
        // Print ASCII representation
        for (int j = 0; j < 16 && (i + j) < length; j++) {
            unsigned char c = data[i + j];
            if (c >= 32 && c <= 126) {
                printf("%c", c);
            } else {
                printf(".");
            }
        }
        printf("\n");
    }
}

/*
Function to get basic L3/L4 info from a stored packet for summary display
*/
void get_packet_summary_info(struct stored_packet *pkt, char *summary, size_t summary_len) {
    const unsigned char *packet = pkt->data;
    struct ether_header *eth_header = (struct ether_header *)packet;
    uint16_t ether_type = ntohs(eth_header->ether_type);
    
    if (ether_type == ETHERTYPE_IP) {
        const unsigned char *layer3_packet = packet + sizeof(struct ether_header);
        struct iphdr *ip_header = (struct iphdr *)layer3_packet;
        
        char src_ip[INET_ADDRSTRLEN], dst_ip[INET_ADDRSTRLEN];
        struct in_addr src_addr, dst_addr;
        src_addr.s_addr = ip_header->saddr;
        dst_addr.s_addr = ip_header->daddr;
        inet_ntop(AF_INET, &src_addr, src_ip, INET_ADDRSTRLEN);
        inet_ntop(AF_INET, &dst_addr, dst_ip, INET_ADDRSTRLEN);
        
        if (ip_header->protocol == IPPROTO_TCP) {
            const unsigned char *layer4_packet = layer3_packet + (ip_header->ihl * 4);
            struct tcp_header *tcp_hdr = (struct tcp_header *)layer4_packet;
            snprintf(summary, summary_len, "IPv4 TCP | %s:%d -> %s:%d",
                     src_ip, ntohs(tcp_hdr->source_port),
                     dst_ip, ntohs(tcp_hdr->dest_port));
        } else if (ip_header->protocol == IPPROTO_UDP) {
            const unsigned char *layer4_packet = layer3_packet + (ip_header->ihl * 4);
            struct udp_header *udp_hdr = (struct udp_header *)layer4_packet;
            snprintf(summary, summary_len, "IPv4 UDP | %s:%d -> %s:%d",
                     src_ip, ntohs(udp_hdr->source_port),
                     dst_ip, ntohs(udp_hdr->dest_port));
        } else {
            snprintf(summary, summary_len, "IPv4 | %s -> %s | Protocol: %d",
                     src_ip, dst_ip, ip_header->protocol);
        }
    } else if (ether_type == ETHERTYPE_IPV6) {
        const unsigned char *layer3_packet = packet + sizeof(struct ether_header);
        struct ip6_hdr *ipv6_header = (struct ip6_hdr *)layer3_packet;
        
        char src_ip[INET6_ADDRSTRLEN], dst_ip[INET6_ADDRSTRLEN];
        inet_ntop(AF_INET6, &(ipv6_header->ip6_src), src_ip, INET6_ADDRSTRLEN);
        inet_ntop(AF_INET6, &(ipv6_header->ip6_dst), dst_ip, INET6_ADDRSTRLEN);
        
        uint8_t next_header = ipv6_header->ip6_nxt;
        if (next_header == IPPROTO_TCP) {
            const unsigned char *layer4_packet = layer3_packet + sizeof(struct ip6_hdr);
            struct tcp_header *tcp_hdr = (struct tcp_header *)layer4_packet;
            snprintf(summary, summary_len, "IPv6 TCP | %s:%d -> %s:%d",
                     src_ip, ntohs(tcp_hdr->source_port),
                     dst_ip, ntohs(tcp_hdr->dest_port));
        } else if (next_header == IPPROTO_UDP) {
            const unsigned char *layer4_packet = layer3_packet + sizeof(struct ip6_hdr);
            struct udp_header *udp_hdr = (struct udp_header *)layer4_packet;
            snprintf(summary, summary_len, "IPv6 UDP | %s:%d -> %s:%d",
                     src_ip, ntohs(udp_hdr->source_port),
                     dst_ip, ntohs(udp_hdr->dest_port));
        } else {
            snprintf(summary, summary_len, "IPv6 | %s -> %s | Next Header: %d",
                     src_ip, dst_ip, next_header);
        }
    } else if (ether_type == ETHERTYPE_ARP) {
        snprintf(summary, summary_len, "ARP");
    } else {
        snprintf(summary, summary_len, "EtherType: 0x%04X", ether_type);
    }
}

/*
Function to display detailed analysis of a single packet
*/
void inspect_packet_detailed(struct stored_packet *pkt) {
    printf("\n");
    printf("========================================\n");
    printf("DETAILED PACKET INSPECTION - Packet ID: %d\n", pkt->id);
    printf("========================================\n");
    printf("Timestamp: %ld.%06ld\n", pkt->header.ts.tv_sec, pkt->header.ts.tv_usec);
    printf("Capture Length: %d bytes\n", pkt->header.caplen);
    printf("Actual Length: %d bytes\n", pkt->header.len);
    printf("========================================\n\n");
    
    const unsigned char *packet = pkt->data;
    
    // Layer 2 - Ethernet
    printf("=== LAYER 2: ETHERNET HEADER ===\n");
    struct ether_header *eth_header = (struct ether_header *)packet;
    printf("Destination MAC: %02X:%02X:%02X:%02X:%02X:%02X\n",
           eth_header->ether_dhost[0], eth_header->ether_dhost[1], eth_header->ether_dhost[2],
           eth_header->ether_dhost[3], eth_header->ether_dhost[4], eth_header->ether_dhost[5]);
    printf("Source MAC:      %02X:%02X:%02X:%02X:%02X:%02X\n",
           eth_header->ether_shost[0], eth_header->ether_shost[1], eth_header->ether_shost[2],
           eth_header->ether_shost[3], eth_header->ether_shost[4], eth_header->ether_shost[5]);
    
    uint16_t ether_type = ntohs(eth_header->ether_type);
    printf("EtherType:       0x%04X (", ether_type);
    switch (ether_type) {
        case ETHERTYPE_IP: printf("IPv4"); break;
        case ETHERTYPE_IPV6: printf("IPv6"); break;
        case ETHERTYPE_ARP: printf("ARP"); break;
        default: printf("Unknown"); break;
    }
    printf(")\n");
    
    printf("\nRaw Ethernet Header (hex):\n");
    print_full_hex_dump(packet, sizeof(struct ether_header));
    printf("\n");
    
    // Layer 3 - IP/ARP
    const unsigned char *layer3_packet = packet + sizeof(struct ether_header);
    
    if (ether_type == ETHERTYPE_IP) {
        printf("=== LAYER 3: IPv4 HEADER ===\n");
        struct iphdr *ip_header = (struct iphdr *)layer3_packet;
        
        char src_ip[INET_ADDRSTRLEN], dst_ip[INET_ADDRSTRLEN];
        struct in_addr src_addr, dst_addr;
        src_addr.s_addr = ip_header->saddr;
        dst_addr.s_addr = ip_header->daddr;
        inet_ntop(AF_INET, &src_addr, src_ip, INET_ADDRSTRLEN);
        inet_ntop(AF_INET, &dst_addr, dst_ip, INET_ADDRSTRLEN);
        
        printf("Version:         %d\n", ip_header->version);
        printf("Header Length:   %d bytes (%d words)\n", ip_header->ihl * 4, ip_header->ihl);
        printf("Type of Service: 0x%02X\n", ip_header->tos);
        printf("Total Length:    %d bytes\n", ntohs(ip_header->tot_len));
        printf("Identification:  0x%04X\n", ntohs(ip_header->id));
        
        uint16_t flags_offset = ntohs(ip_header->frag_off);
        printf("Flags:           ");
        if (flags_offset & 0x4000) printf("DF (Don't Fragment) ");
        if (flags_offset & 0x2000) printf("MF (More Fragments)");
        printf("\n");
        printf("Fragment Offset: %d\n", flags_offset & 0x1FFF);
        
        printf("TTL:             %d\n", ip_header->ttl);
        printf("Protocol:        %d (", ip_header->protocol);
        switch (ip_header->protocol) {
            case IPPROTO_TCP: printf("TCP"); break;
            case IPPROTO_UDP: printf("UDP"); break;
            case IPPROTO_ICMP: printf("ICMP"); break;
            default: printf("Unknown"); break;
        }
        printf(")\n");
        printf("Checksum:        0x%04X\n", ntohs(ip_header->check));
        printf("Source IP:       %s\n", src_ip);
        printf("Destination IP:  %s\n", dst_ip);
        
        printf("\nRaw IPv4 Header (hex):\n");
        print_full_hex_dump(layer3_packet, ip_header->ihl * 4);
        printf("\n");
        
        // Layer 4 - TCP/UDP
        const unsigned char *layer4_packet = layer3_packet + (ip_header->ihl * 4);
        
        if (ip_header->protocol == IPPROTO_TCP) {
            printf("=== LAYER 4: TCP HEADER ===\n");
            struct tcp_header *tcp_hdr = (struct tcp_header *)layer4_packet;
            
            printf("Source Port:     %d", ntohs(tcp_hdr->source_port));
            const char *src_name = get_port_name(ntohs(tcp_hdr->source_port));
            if (src_name) printf(" (%s)", src_name);
            printf("\n");
            
            printf("Destination Port: %d", ntohs(tcp_hdr->dest_port));
            const char *dst_name = get_port_name(ntohs(tcp_hdr->dest_port));
            if (dst_name) printf(" (%s)", dst_name);
            printf("\n");
            
            printf("Sequence Number: %u\n", ntohl(tcp_hdr->seq_num));
            printf("Ack Number:      %u\n", ntohl(tcp_hdr->ack_num));
            printf("Data Offset:     %d bytes (%d words)\n", 
                   (tcp_hdr->data_offset >> 4) * 4, tcp_hdr->data_offset >> 4);
            printf("Flags:           0x%02X [", tcp_hdr->flags);
            int flag_printed = 0;
            if (tcp_hdr->flags & TCP_FIN) { if (flag_printed++) printf(","); printf("FIN"); }
            if (tcp_hdr->flags & TCP_SYN) { if (flag_printed++) printf(","); printf("SYN"); }
            if (tcp_hdr->flags & TCP_RST) { if (flag_printed++) printf(","); printf("RST"); }
            if (tcp_hdr->flags & TCP_PSH) { if (flag_printed++) printf(","); printf("PSH"); }
            if (tcp_hdr->flags & TCP_ACK) { if (flag_printed++) printf(","); printf("ACK"); }
            if (tcp_hdr->flags & TCP_URG) { if (flag_printed++) printf(","); printf("URG"); }
            printf("]\n");
            printf("Window Size:     %d\n", ntohs(tcp_hdr->window));
            printf("Checksum:        0x%04X\n", ntohs(tcp_hdr->checksum));
            printf("Urgent Pointer:  %d\n", ntohs(tcp_hdr->urgent_ptr));
            
            int tcp_header_len = (tcp_hdr->data_offset >> 4) * 4;
            printf("\nRaw TCP Header (hex):\n");
            print_full_hex_dump(layer4_packet, tcp_header_len);
            printf("\n");
            
            // Payload
            const unsigned char *payload = layer4_packet + tcp_header_len;
            int payload_len = ntohs(ip_header->tot_len) - (ip_header->ihl * 4) - tcp_header_len;
            
            if (payload_len > 0) {
                printf("=== LAYER 7: PAYLOAD ===\n");
                const char *app_proto = identify_app_protocol(ntohs(tcp_hdr->source_port), 
                                                               ntohs(tcp_hdr->dest_port));
                printf("Application Protocol: %s\n", app_proto);
                printf("Payload Length: %d bytes\n\n", payload_len);
                printf("Payload Data (hex):\n");
                print_full_hex_dump(payload, payload_len);
                printf("\n");
            }
            
        } else if (ip_header->protocol == IPPROTO_UDP) {
            printf("=== LAYER 4: UDP HEADER ===\n");
            struct udp_header *udp_hdr = (struct udp_header *)layer4_packet;
            
            printf("Source Port:     %d", ntohs(udp_hdr->source_port));
            const char *src_name = get_port_name(ntohs(udp_hdr->source_port));
            if (src_name) printf(" (%s)", src_name);
            printf("\n");
            
            printf("Destination Port: %d", ntohs(udp_hdr->dest_port));
            const char *dst_name = get_port_name(ntohs(udp_hdr->dest_port));
            if (dst_name) printf(" (%s)", dst_name);
            printf("\n");
            
            printf("Length:          %d bytes\n", ntohs(udp_hdr->length));
            printf("Checksum:        0x%04X\n", ntohs(udp_hdr->checksum));
            
            printf("\nRaw UDP Header (hex):\n");
            print_full_hex_dump(layer4_packet, sizeof(struct udp_header));
            printf("\n");
            
            // Payload
            const unsigned char *payload = layer4_packet + sizeof(struct udp_header);
            int payload_len = ntohs(udp_hdr->length) - sizeof(struct udp_header);
            
            if (payload_len > 0) {
                printf("=== LAYER 7: PAYLOAD ===\n");
                const char *app_proto = identify_app_protocol(ntohs(udp_hdr->source_port), 
                                                               ntohs(udp_hdr->dest_port));
                printf("Application Protocol: %s\n", app_proto);
                printf("Payload Length: %d bytes\n\n", payload_len);
                printf("Payload Data (hex):\n");
                print_full_hex_dump(payload, payload_len);
                printf("\n");
            }
        }
        
    } else if (ether_type == ETHERTYPE_IPV6) {
        printf("=== LAYER 3: IPv6 HEADER ===\n");
        struct ip6_hdr *ipv6_header = (struct ip6_hdr *)layer3_packet;
        
        char src_ip[INET6_ADDRSTRLEN], dst_ip[INET6_ADDRSTRLEN];
        inet_ntop(AF_INET6, &(ipv6_header->ip6_src), src_ip, INET6_ADDRSTRLEN);
        inet_ntop(AF_INET6, &(ipv6_header->ip6_dst), dst_ip, INET6_ADDRSTRLEN);
        
        uint32_t vtc_flow = ntohl(ipv6_header->ip6_flow);
        uint8_t traffic_class = (vtc_flow >> 20) & 0xFF;
        uint32_t flow_label = vtc_flow & 0xFFFFF;
        
        printf("Version:         6\n");
        printf("Traffic Class:   %d\n", traffic_class);
        printf("Flow Label:      0x%05X\n", flow_label);
        printf("Payload Length:  %d bytes\n", ntohs(ipv6_header->ip6_plen));
        printf("Next Header:     %d (", ipv6_header->ip6_nxt);
        switch (ipv6_header->ip6_nxt) {
            case IPPROTO_TCP: printf("TCP"); break;
            case IPPROTO_UDP: printf("UDP"); break;
            case IPPROTO_ICMPV6: printf("ICMPv6"); break;
            default: printf("Unknown"); break;
        }
        printf(")\n");
        printf("Hop Limit:       %d\n", ipv6_header->ip6_hlim);
        printf("Source IP:       %s\n", src_ip);
        printf("Destination IP:  %s\n", dst_ip);
        
        printf("\nRaw IPv6 Header (hex):\n");
        print_full_hex_dump(layer3_packet, sizeof(struct ip6_hdr));
        printf("\n");
        
        // Layer 4 for IPv6 (similar to IPv4, but simpler for brevity)
        const unsigned char *layer4_packet = layer3_packet + sizeof(struct ip6_hdr);
        uint8_t next_header = ipv6_header->ip6_nxt;
        
        if (next_header == IPPROTO_TCP || next_header == IPPROTO_UDP) {
            printf("=== LAYER 4: %s HEADER ===\n", next_header == IPPROTO_TCP ? "TCP" : "UDP");
            printf("(See hex dump below for details)\n");
            int l4_header_len = (next_header == IPPROTO_TCP) ? 20 : 8; // Minimum sizes
            print_full_hex_dump(layer4_packet, l4_header_len);
            printf("\n");
        }
        
    } else if (ether_type == ETHERTYPE_ARP) {
        printf("=== LAYER 3: ARP HEADER ===\n");
        struct arphdr *arp_header = (struct arphdr *)layer3_packet;
        
        printf("Hardware Type:   %d\n", ntohs(arp_header->ar_hrd));
        printf("Protocol Type:   0x%04X\n", ntohs(arp_header->ar_pro));
        printf("Hardware Length: %d\n", arp_header->ar_hln);
        printf("Protocol Length: %d\n", arp_header->ar_pln);
        printf("Operation:       %d (", ntohs(arp_header->ar_op));
        switch (ntohs(arp_header->ar_op)) {
            case ARPOP_REQUEST: printf("Request"); break;
            case ARPOP_REPLY: printf("Reply"); break;
            default: printf("Unknown"); break;
        }
        printf(")\n");
        
        unsigned char *arp_data = (unsigned char *)(layer3_packet + sizeof(struct arphdr));
        unsigned char *sender_mac = arp_data;
        unsigned char *sender_ip = arp_data + 6;
        unsigned char *target_mac = arp_data + 10;
        unsigned char *target_ip = arp_data + 16;
        
        printf("Sender MAC:      %02X:%02X:%02X:%02X:%02X:%02X\n",
               sender_mac[0], sender_mac[1], sender_mac[2], 
               sender_mac[3], sender_mac[4], sender_mac[5]);
        printf("Sender IP:       %d.%d.%d.%d\n",
               sender_ip[0], sender_ip[1], sender_ip[2], sender_ip[3]);
        printf("Target MAC:      %02X:%02X:%02X:%02X:%02X:%02X\n",
               target_mac[0], target_mac[1], target_mac[2], 
               target_mac[3], target_mac[4], target_mac[5]);
        printf("Target IP:       %d.%d.%d.%d\n",
               target_ip[0], target_ip[1], target_ip[2], target_ip[3]);
        
        printf("\nRaw ARP Packet (hex):\n");
        print_full_hex_dump(layer3_packet, 28);
        printf("\n");
    }
    
    // Complete packet hex dump
    printf("=== COMPLETE PACKET HEX DUMP ===\n");
    printf("Total packet size: %d bytes\n\n", pkt->header.caplen);
    print_full_hex_dump(pkt->data, pkt->header.caplen);
    printf("\n========================================\n");
}

/*
Function to display session summary and allow packet selection
*/
void inspect_last_session() {
    if (session_packet_count == 0) {
        printf("\n[C-Shark] No packets in session. Capture some packets first!\n");
        return;
    }
    
    printf("\n========================================\n");
    printf("LAST SESSION SUMMARY\n");
    printf("========================================\n");
    printf("Total packets captured: %d\n", session_packet_count);
    printf("========================================\n\n");
    
    printf("%-5s | %-20s | %-10s | %s\n", "ID", "Timestamp", "Length", "Summary");
    printf("------+----------------------+------------+------------------------------------------\n");
    
    for (int i = 0; i < session_packet_count; i++) {
        struct stored_packet *pkt = session_packets[i];
        char summary[256];
        get_packet_summary_info(pkt, summary, sizeof(summary));
        
        printf("%-5d | %ld.%06ld | %-10d | %s\n",
               pkt->id, pkt->header.ts.tv_sec, pkt->header.ts.tv_usec,
               pkt->header.len, summary);
    }
    
    printf("\n");
    printf("Enter Packet ID to inspect (1-%d), or 0 to return to menu: ", session_packet_count);
    fflush(stdout);
    
    int choice;
    if (scanf("%d", &choice) != 1) {
        if (feof(stdin)) {
            printf("\n[C-Shark] Exiting...\n");
            exit(0);
        }
        int c;
        while ((c = getchar()) != '\n' && c != EOF);
        printf("[C-Shark] Invalid input.\n");
        return;
    }
    
    if (choice == 0) {
        printf("[C-Shark] Returning to main menu...\n");
        return;
    }
    
    if (choice < 1 || choice > session_packet_count) {
        printf("[C-Shark] Invalid packet ID.\n");
        return;
    }
    
    // Find and inspect the selected packet
    for (int i = 0; i < session_packet_count; i++) {
        if (session_packets[i]->id == choice) {
            inspect_packet_detailed(session_packets[i]);
            break;
        }
    }
}

void start_sniffing(const char *dev_name) {
    char errbuf[PCAP_ERRBUF_SIZE]; //buffer to store error messages
    
    // Free previous session data
    free_session_packets();
    
    printf("\n[C-Shark] Starting packet capture on interface '%s'...\n", dev_name);
    printf("[C-Shark] Press Ctrl+C to stop capturing and return to menu.\n\n");
    
    // Set a shorter timeout (100ms) so Ctrl+C is more responsive
    handle = pcap_open_live(dev_name, BUFSIZ, 1, 100, errbuf); //returns session handle for live capture
    if (handle == NULL) {
        fprintf(stderr, "Error opening device %s: %s\n", dev_name, errbuf);
        return;
    }
    
    sniffing_active = 1; //set flag to indicate sniffing is active
    packet_count = 0; //reset packet count
    
    //Ctrl + C will trigger handle_sigint which calls pcap_breakloop
    pcap_loop(handle, 0, packet_handler, NULL); //start capturing packets, 0 means this will run until pcap_breakloop is called
    
    sniffing_active = 0; //reset flag after loop ends
    pcap_close(handle); //close the session
    handle = NULL;
    
    printf("\n[C-Shark] Capture stopped. Total packets captured: %d\n", packet_count);
    if (session_packet_count >= MAX_PACKETS) {
        printf("[C-Shark] %d packets stored in memory (max: %d)\n", session_packet_count, MAX_PACKETS);
    } else {
        printf("[C-Shark] %d packets stored in memory\n", session_packet_count);
    }
    printf("[C-Shark] Returning to main menu...\n\n");
}

/*
Function to start sniffing with a filter
*/
void start_sniffing_with_filter(const char *dev_name) {
    char errbuf[PCAP_ERRBUF_SIZE];
    struct bpf_program fp; // Compiled filter program
    
    // Free previous session data
    free_session_packets();
    
    // Get filter choice from user
    int filter_choice = show_filter_menu();
    
    if (filter_choice == 7) {
        // User wants to cancel
        printf("\n[C-Shark] Returning to main menu...\n");
        return;
    }
    
    if (filter_choice < 1 || filter_choice > 6) {
        printf("\n[C-Shark] Invalid choice. Returning to main menu.\n");
        return;
    }
    
    const char *filter_str = get_filter_for_protocol(filter_choice);
    const char *protocol_names[] = {"", "HTTP", "HTTPS", "DNS", "ARP", "TCP", "UDP"};
    
    printf("\n[C-Shark] Starting filtered packet capture on interface '%s'...\n", dev_name);
    printf("[C-Shark] Filter: %s (BPF: \"%s\")\n", protocol_names[filter_choice], filter_str);
    printf("[C-Shark] Press Ctrl+C to stop capturing and return to menu.\n\n");
    
    // Open device for packet capture
    handle = pcap_open_live(dev_name, BUFSIZ, 1, 100, errbuf);
    if (handle == NULL) {
        fprintf(stderr, "Error opening device %s: %s\n", dev_name, errbuf);
        return;
    }
    
    // Compile the filter
    if (pcap_compile(handle, &fp, filter_str, 0, PCAP_NETMASK_UNKNOWN) == -1) { //compiles the filter expression into BPF bytecode with no optimization (0)
        fprintf(stderr, "Error compiling filter: %s\n", pcap_geterr(handle));
        pcap_close(handle);
        handle = NULL;
        return;
    }
    
    // Apply the filter
    if (pcap_setfilter(handle, &fp) == -1) { //applies filter to handler
        fprintf(stderr, "Error setting filter: %s\n", pcap_geterr(handle));
        pcap_freecode(&fp);
        pcap_close(handle);
        handle = NULL;
        return;
    }
    
    // Free the compiled filter (it's already loaded into the kernel)
    pcap_freecode(&fp);
    
    sniffing_active = 1;
    packet_count = 0;
    
    // Start capturing packets
    pcap_loop(handle, 0, packet_handler, NULL);
    
    sniffing_active = 0;
    pcap_close(handle);
    handle = NULL;
    
    printf("\n[C-Shark] Filtered capture stopped. Total packets captured: %d\n", packet_count);
    if (session_packet_count >= MAX_PACKETS) {
        printf("[C-Shark] %d packets stored in memory (max: %d)\n", session_packet_count, MAX_PACKETS);
    } else {
        printf("[C-Shark] %d packets stored in memory\n", session_packet_count);
    }
    printf("[C-Shark] Returning to main menu...\n\n");
}

/*
This function discovers available network interfaces and allows the user to select one.
It returns the name of the selected interface as a dynamically allocated string.
*/
char* discover_interfaces() {
    char errbuf[PCAP_ERRBUF_SIZE]; //buffer to store error messages
    pcap_if_t *alldevs, *device; //pointers to hold the list of devices
    int i = 0; //counter for interfaces
    
    printf("\n[C-Shark] The Command-Line Packet Predator\n");
    printf("==============================================\n");
    printf("[C-Shark] Searching for available interfaces... ");
    fflush(stdout); //flush to ensure immediate output
    
    if (pcap_findalldevs(&alldevs, errbuf) == -1) { //scans the system for all network interfaces
        fprintf(stderr, "Error finding devices: %s\n", errbuf);
        exit(1);
    }
    
    printf("Found!\n\n");
    
    // print the list of interfaces
    for (device = alldevs; device != NULL; device = device->next) {
        i++;
        printf("%d. %s", i, device->name);
        if (device->description) {
            printf(" (%s)", device->description);
        }
        printf("\n");
    }
    
    if (i == 0) {
        printf("No interfaces found! Make sure you run this with sudo.\n");
        pcap_freealldevs(alldevs); //free the device list
        exit(1);
    }
    
    printf("\nSelect an interface to sniff (1-%d): ", i);
    fflush(stdout);
    
    int choice;
    if (scanf("%d", &choice) != 1) { // Check if input is valid
        // Handle EOF (Ctrl+D)
        printf("\n[C-Shark] Exiting...\n");
        pcap_freealldevs(alldevs);
        exit(0);
    }
    
    if (choice < 1 || choice > i) {
        printf("Invalid choice!\n");
        pcap_freealldevs(alldevs);
        exit(1);
    }
    
    device = alldevs;
    for (int j = 1; j < choice; j++) {
        device = device->next;
    }
    
    char *selected_dev = strdup(device->name);
    
    pcap_freealldevs(alldevs);
    
    return selected_dev;
}

/*
This function displays the main menu and prompts the user for their choice.
*/
void show_menu(const char *dev_name) {
    printf("\n[C-Shark] Interface '%s' selected. What's next?\n\n", dev_name);
    printf("1. Start Sniffing (All Packets)\n");
    printf("2. Start Sniffing (With Filters)\n");
    printf("3. Inspect Last Session\n");
    printf("4. Exit C-Shark\n");
    printf("\nEnter your choice: ");
    fflush(stdout);
}

int main(int argc, char *argv[]) {
    (void)argc;
    (void)argv;
    
    // Set up signal handler for Ctrl+C
    signal(SIGINT, handle_sigint); //use the custom handle_sigint function
    
    char *dev_name = discover_interfaces(); //discover and select interface
    if (dev_name == NULL) {
        return 1;
    }
    
    int running = 1;
    while (running) {
        show_menu(dev_name); //display menu
        
        int choice;
        if (scanf("%d", &choice) != 1) {
            // Handle EOF (Ctrl+D) or input error
            if (feof(stdin)) {
                printf("\n[C-Shark] Exiting...\n");
                running = 0;
                break;
            }
            // Clear input buffer on error
            int c;
            while ((c = getchar()) != '\n' && c != EOF) {
                if (c == EOF) {
                    printf("\n[C-Shark] Exiting...\n");
                    running = 0;
                    break;
                }
            }
            if (!running) break;
            printf("[C-Shark] Invalid input. Please enter a number.\n");
            continue;
        }
        
        switch (choice) {
            case 1:
                start_sniffing(dev_name);
                break;
            case 2:
                start_sniffing_with_filter(dev_name);
                break;
            case 3:
                inspect_last_session();
                break;
            case 4:
                printf("\n[C-Shark] Exiting...\n");
                running = 0;
                break;
            default:
                printf("\n[C-Shark] Invalid choice. Please try again.\n");
        }
    }
    
    free(dev_name);
    free_session_packets(); // Clean up session data before exit
    return 0;
}
