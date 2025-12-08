#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fcntl.h"

int
main(int argc, char *argv[])
{
  uint64 count1, count2;
  int fd;
  char buf[200]; // Buffer is larger than our read size
  int n;
  char *test_string = "This is a test string. 1234567890. "; // 35 bytes
  int i;

  printf("Initial read count: %ld\n", getreadcount());
  
  // Create a file to read from
  fd = open("tempfile", O_CREATE | O_RDWR);
  if (fd < 0) {
    fprintf(2, "readcount: cannot open tempfile\n");
    exit(1);
  }
  
  // Write 140 bytes (35 bytes * 4 times) to the file to ensure it's > 100 bytes.
  printf("Writing 140 bytes to tempfile...\n");
  for(i = 0; i < 4; i++){
    if(write(fd, test_string, 35) != 35){
      fprintf(2, "readcount: failed to write to tempfile\n");
      exit(1);
    }
  }
  close(fd);

  // Re-open for reading
  fd = open("tempfile", O_RDONLY);
  if (fd < 0) {
    fprintf(2, "readcount: cannot open tempfile\n");
    exit(1);
  }

  // Get the read count before the read call
  count1 = getreadcount();
  
  // Read exactly 100 bytes from the file
  printf("Attempting to read 100 bytes...\n");
  n = read(fd, buf, 100);
  if (n < 0) {
    fprintf(2, "readcount: read failed\n");
    close(fd);
    exit(1);
  }

  // Get the read count after the read call
  count2 = getreadcount();

  printf("Bytes actually read: %d\n", n);
  printf("Read count before read: %ld\n", count1);
  printf("Read count after read: %ld\n", count2);
  
  // We expect n to be 100 now.
  if ((count2 - count1) == n && n == 100) {
    printf("Verification successful: count increased by exactly 100 bytes.\n");
  } else {
    printf("Verification failed: expected an increase of 100, but got %d.\n", (int)(count2 - count1));
  }

  close(fd);
  unlink("tempfile");

  exit(0);
}
