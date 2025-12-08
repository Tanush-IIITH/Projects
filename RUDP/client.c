#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <time.h>
#include <stdbool.h>
#include <sys/select.h>
#include <sys/time.h>
#include "connection.h"
#include "data_transfer.h"
#include "logger.h"

#define DEFAULT_LOSS_RATE 0.0

// Global loss rate for packet loss simulation
float loss_rate = DEFAULT_LOSS_RATE;
bool chat_mode = false;

// (packet loss is simulated at receiver side via conn->loss_rate)

// Chat mode handler
void handle_chat_client(sham_connection_t *conn) {
    printf("=== SHAM Chat Client ===\n");
    printf("Chat mode activated. Type messages to send to server.\n");
    printf("Type '/quit' to exit.\n\n");

    char buffer[1024];
    char received_msg[1024];

    while (1) {
        // Check for incoming messages from server
        fd_set read_fds;
        FD_ZERO(&read_fds);
        FD_SET(conn->sockfd, &read_fds);
        FD_SET(STDIN_FILENO, &read_fds);

        struct timeval timeout = {0, 100000}; // 100ms timeout
        int ready = select(conn->sockfd + 1, &read_fds, NULL, NULL, &timeout);

        if (ready > 0) {
            // Check for server message
            if (FD_ISSET(conn->sockfd, &read_fds)) {
                int received = sham_receive_data(conn, received_msg, sizeof(received_msg) - 1);
                if (received > 0) {
                    received_msg[received] = '\0';
                    printf("\n[Server]: %s\n", received_msg);

                    if (strcmp(received_msg, "/quit") == 0) {
                        printf("Server requested disconnect.\n");
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
                        // Send quit notification to server before closing.
                        // sham_send_data() is blocking and will return only after
                        // the message has been acknowledged by the peer.
                        sham_send_data(conn, buffer, strlen(buffer));
                        printf("Initiating connection close...\n");
                        break;
                    }

                    // Send message to server
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
void handle_file_client(sham_connection_t *conn, const char *input_file, const char *output_file) {
    printf("=== SHAM File Client ===\n");
    printf("Sending file: %s\n", input_file);

    // Send file
    int result = sham_send_file(conn, input_file);
    if (result == 0) {
        printf("File sent successfully\n");
    } else {
        printf("File transmission failed\n");
    }

    // Optionally receive a response file
    if (output_file) {
        printf("Waiting to receive response file: %s\n", output_file);
        result = sham_receive_file(conn, output_file);
        if (result > 0) {
            printf("Response file received successfully: %d bytes\n", result);
        } else {
            printf("Response file reception failed\n");
        }
    }
}

int main(int argc, char *argv[]) {
    if (argc < 3 || strcmp(argv[1], "--help") == 0 || strcmp(argv[1], "-h") == 0) {
        printf("Usage:\n");
        printf("  File Transfer: %s <server_ip> <server_port> <input_file> <output_file> [loss_rate]\n", argv[0]);
        printf("  Chat Mode:     %s <server_ip> <server_port> --chat [loss_rate]\n", argv[0]);
        printf("\nArguments:\n");
        printf("  <server_ip>: Server IP address\n");
        printf("  <server_port>: Server port number\n");
        printf("  <input_file>: File to send (file transfer mode)\n");
        printf("  <output_file>: File to receive (file transfer mode)\n");
        printf("  --chat: Enable chat mode\n");
        printf("  loss_rate: Packet loss probability (0.0-1.0, default: 0.0)\n");
        printf("\nExamples:\n");
        printf("  %s 127.0.0.1 8080 test.txt response.txt     # File transfer, no loss\n", argv[0]);
        printf("  %s 127.0.0.1 8080 test.txt response.txt 0.1  # File transfer, 10%% loss\n", argv[0]);
        printf("  %s 127.0.0.1 8080 --chat                    # Chat mode, no loss\n", argv[0]);
        printf("  %s 127.0.0.1 8080 --chat 0.05               # Chat mode, 5%% loss\n", argv[0]);
        return argc < 3 ? 1 : 0;
    }

    // Parse arguments
    char *server_ip = argv[1];
    int server_port = atoi(argv[2]);
    char *input_file = NULL;
    char *output_file = NULL;
    int arg_idx = 3;

    // Check for --chat flag
    if (arg_idx < argc && strcmp(argv[arg_idx], "--chat") == 0) {
        chat_mode = true;
        arg_idx++;
    } else {
        // File transfer mode - parse file arguments
        if (arg_idx < argc) {
            input_file = argv[arg_idx++];
        }
        if (arg_idx < argc) {
            output_file = argv[arg_idx++];
        }
    }

    // Check for loss rate
    if (arg_idx < argc) {
        loss_rate = atof(argv[arg_idx]);
        if (loss_rate < 0.0 || loss_rate > 1.0) {
            printf("Error: Loss rate must be between 0.0 and 1.0\n");
            return 1;
        }
    }

    // Validate arguments: in file transfer mode, both input and output files are required
    if (!chat_mode) {
        if (!input_file || !output_file) {
            printf("Error: Input and output files required for file transfer mode\n");
            return 1;
        }
    }

    // Seed random number generator for packet loss simulation
    srand(time(NULL));

    printf("Connecting to SHAM server at %s:%d\n", server_ip, server_port);
    printf("Chat mode: %s\n", chat_mode ? "ON" : "OFF");
    printf("Loss rate: %.2f\n", loss_rate);

    // Initialize logger
    logger_init("client");

    // Create socket
    int sockfd = sham_socket();
    if (sockfd < 0) {
        return 1;
    }

    // Connect to server
    struct sockaddr_in server_addr;
    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_addr.s_addr = inet_addr(server_ip);
    server_addr.sin_port = htons(server_port);

    sham_connection_t conn;
    if (sham_connect(sockfd, &server_addr, &conn, loss_rate) == 0) {
        printf("Connected to server successfully!\n");

        if (chat_mode) {
            handle_chat_client(&conn);
        } else {
            handle_file_client(&conn, input_file, output_file);
        }

        // Close connection
        sham_close(&conn);
    } else {
        printf("Failed to connect to server\n");
    }

    close(sockfd);
    return 0;
}
