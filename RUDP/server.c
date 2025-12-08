#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <time.h>
#include <stdbool.h>
#include <sys/select.h>
#include <sys/time.h>
#include <openssl/md5.h>
#include "connection.h"
#include "data_transfer.h"
#include "logger.h"

#define DEFAULT_LOSS_RATE 0.0

// Global loss rate for packet loss simulation
float loss_rate = DEFAULT_LOSS_RATE;
bool chat_mode = false;

// (packet loss is simulated at receiver side via conn->loss_rate)

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wdeprecated-declarations"

// Function to calculate MD5 checksum of a file
char* calculate_md5(const char *filename) {
    static char md5_hash[33];  // 32 chars + null terminator
    FILE *file = fopen(filename, "rb");
    if (!file) {
        return NULL;
    }
    
    MD5_CTX md5_ctx;
    MD5_Init(&md5_ctx);
    
    unsigned char buffer[1024];
    size_t bytes_read;
    while ((bytes_read = fread(buffer, 1, sizeof(buffer), file)) > 0) {
        MD5_Update(&md5_ctx, buffer, bytes_read);
    }
    
    unsigned char hash[MD5_DIGEST_LENGTH];
    MD5_Final(hash, &md5_ctx);
    
    fclose(file);
    
    // Convert to lowercase hex string
    for (int i = 0; i < MD5_DIGEST_LENGTH; i++) {
        sprintf(md5_hash + (i * 2), "%02x", hash[i]);
    }
    md5_hash[32] = '\0';
    
    return md5_hash;
}

#pragma GCC diagnostic pop// Chat mode handler
void handle_chat_server(sham_connection_t *conn) {
    printf("=== SHAM Chat Server ===\n");
    printf("Chat mode activated. Type messages to send to client.\n");
    printf("Type '/quit' to exit.\n\n");

    char buffer[1024];
    char received_msg[1024];

    while (1) {
        // Check for incoming messages from client
        fd_set read_fds;
        FD_ZERO(&read_fds);
        FD_SET(conn->sockfd, &read_fds);
        FD_SET(STDIN_FILENO, &read_fds);

        struct timeval timeout = {0, 100000}; // 100ms timeout
        int ready = select(conn->sockfd + 1, &read_fds, NULL, NULL, &timeout);

        if (ready > 0) {
            // Check for client message
            if (FD_ISSET(conn->sockfd, &read_fds)) {
                int received = sham_receive_data(conn, received_msg, sizeof(received_msg) - 1);
                if (received > 0) {
                    received_msg[received] = '\0';
                    printf("\n[Client]: %s\n", received_msg);

                    if (strcmp(received_msg, "/quit") == 0) {
                        printf("Client requested disconnect.\n");
                        break;
                    }
                }
            }

            // Check for user input
            if (FD_ISSET(STDIN_FILENO, &read_fds)) {
                if (fgets(buffer, sizeof(buffer), stdin) != NULL) {
                    // Remove newline
                    buffer[strcspn(buffer, "\n")] = 0;

                    if (strcmp(buffer, "/quit") == 0) {
                        // Send quit notification to client before closing.
                        // sham_send_data() blocks until the data is acknowledged,
                        // so no additional pause is needed.
                        sham_send_data(conn, buffer, strlen(buffer));
                        printf("Initiating connection close...\n");
                        break;
                    }

                    // Send message to client
                    if (strlen(buffer) > 0) {
                        printf("[You]: %s\n", buffer);
                        sham_send_data(conn, buffer, strlen(buffer));
                    }
                }
            }
        }
    }
}

// File transfer mode handler
void handle_file_server(sham_connection_t *conn) {
    printf("=== SHAM File Server ===\n");
    printf("Waiting to receive file from client...\n");

    // Receive file
    int result = sham_receive_file(conn, "server_received.txt");
    if (result > 0) {
        printf("File received successfully: %d bytes\n", result);
        
        // Calculate and print MD5 checksum
        char *md5_hash = calculate_md5("server_received.txt");
        if (md5_hash != NULL) {
            printf("MD5: %s\n", md5_hash);
        } else {
            printf("MD5: <calculation_failed>\n");
        }
        
        // Send the received file back to client as response
        printf("Sending received file back to client...\n");
        result = sham_send_file(conn, "server_received.txt");
        if (result == 0) {
            printf("Response file sent successfully\n");
        } else {
            printf("Response file transmission failed\n");
        }
    } else {
        printf("File reception failed\n");
    }
}

int main(int argc, char *argv[]) {
    if (argc < 2 || strcmp(argv[1], "--help") == 0 || strcmp(argv[1], "-h") == 0) {
        printf("Usage: %s <port> [--chat] [loss_rate]\n", argv[0]);
        printf("\nArguments:\n");
        printf("  <port>: Port number to listen on\n");
        printf("  --chat: Enable chat mode (optional)\n");
        printf("  loss_rate: Packet loss probability (0.0-1.0, default: 0.0)\n");
        printf("\nExamples:\n");
        printf("  %s 8080                    # File transfer mode, no loss\n", argv[0]);
        printf("  %s 8080 --chat             # Chat mode, no loss\n", argv[0]);
        printf("  %s 8080 --chat 0.1         # Chat mode, 10%% loss rate\n", argv[0]);
        return argc < 2 ? 1 : 0;
    }

    // Parse arguments
    int port = atoi(argv[1]);
    int arg_idx = 2;

    // Check for --chat flag
    if (arg_idx < argc && strcmp(argv[arg_idx], "--chat") == 0) {
        chat_mode = true;
        arg_idx++;
    }

    // Check for loss rate
    if (arg_idx < argc) {
        loss_rate = atof(argv[arg_idx]);
        if (loss_rate < 0.0 || loss_rate > 1.0) {
            printf("Error: Loss rate must be between 0.0 and 1.0\n");
            return 1;
        }
    }

    // Seed random number generator for packet loss simulation
    srand(time(NULL));

    printf("Starting SHAM server on port %d\n", port);
    printf("Chat mode: %s\n", chat_mode ? "ON" : "OFF");
    printf("Loss rate: %.2f\n", loss_rate);

    // Initialize logger
    logger_init("server");

    // Create socket
    int sockfd = sham_socket();
    if (sockfd < 0) {
        return 1;
    }

    // Bind to port
    struct sockaddr_in server_addr;
    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_addr.s_addr = INADDR_ANY;
    server_addr.sin_port = htons(port);

    if (sham_bind(sockfd, &server_addr) < 0) {
        close(sockfd);
        return 1;
    }

    // Listen for connections
    if (sham_listen(sockfd) < 0) {
        close(sockfd);
        return 1;
    }

    printf("Server listening on port %d...\n", port);

    // Accept connection
    sham_connection_t conn;
    if (sham_accept(sockfd, &conn, loss_rate) == 0) {
        printf("Client connected successfully!\n");

        if (chat_mode) {
            handle_chat_server(&conn);
        } else {
            handle_file_server(&conn);
        }

        // Close connection
        sham_close(&conn);
    }

    close(sockfd);
    return 0;
}
