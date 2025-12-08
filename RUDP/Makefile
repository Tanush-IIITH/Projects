CC = gcc
CFLAGS = -Wall -Wextra -std=c99 -g -D_POSIX_C_SOURCE=199309L
TARGETS = server client
OBJS = connection.o data_transfer.o logger.o
SERVER_OBJS = server.o
CLIENT_OBJS = client.o

all: $(TARGETS)

server: $(OBJS) $(SERVER_OBJS)
	$(CC) $(CFLAGS) -o server $(OBJS) $(SERVER_OBJS) -lcrypto

client: $(OBJS) $(CLIENT_OBJS)
	$(CC) $(CFLAGS) -o client $(OBJS) $(CLIENT_OBJS)

connection.o: connection.c connection.h sham.h
	$(CC) $(CFLAGS) -c connection.c

data_transfer.o: data_transfer.c data_transfer.h sham.h connection.h
	$(CC) $(CFLAGS) -c data_transfer.c

logger.o: logger.c logger.h
	$(CC) $(CFLAGS) -c logger.c

server.o: server.c connection.h data_transfer.h sham.h
	$(CC) $(CFLAGS) -c server.c

client.o: client.c connection.h data_transfer.h sham.h
	$(CC) $(CFLAGS) -c client.c

clean:
	rm -f $(OBJS) $(SERVER_OBJS) $(CLIENT_OBJS) $(TARGETS)

.PHONY: all clean
