#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

#define NFORK 10
#define IO 5

int main() {
  int n, pid;

  // Fork NFORK child processes
  for (n = 0; n < NFORK; n++) {
    pid = fork();
    if (pid < 0)
      break;
    if (pid == 0) { // Child process
      if (n < IO) {
        pause(200); // IO-bound process
      } else {
        // CPU-bound process
        for (volatile int i = 0; i < 1000000000; i++) {} 
      }
      printf("Process %d finished\n", getpid());
      exit(0);
    }
  }

  exit(0);
}