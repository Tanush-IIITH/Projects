
user/_readcount:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "user/user.h"
#include "kernel/fcntl.h"

int
main(int argc, char *argv[])
{
   0:	7111                	addi	sp,sp,-256
   2:	fd86                	sd	ra,248(sp)
   4:	f9a2                	sd	s0,240(sp)
   6:	0200                	addi	s0,sp,256
  char buf[200]; // Buffer is larger than our read size
  int n;
  char *test_string = "This is a test string. 1234567890. "; // 35 bytes
  int i;

  printf("Initial read count: %ld\n", getreadcount());
   8:	4a8000ef          	jal	4b0 <getreadcount>
   c:	85aa                	mv	a1,a0
   e:	00001517          	auipc	a0,0x1
  12:	9f250513          	addi	a0,a0,-1550 # a00 <malloc+0x104>
  16:	033000ef          	jal	848 <printf>
  
  // Create a file to read from
  fd = open("tempfile", O_CREATE | O_RDWR);
  1a:	20200593          	li	a1,514
  1e:	00001517          	auipc	a0,0x1
  22:	a0250513          	addi	a0,a0,-1534 # a20 <malloc+0x124>
  26:	42a000ef          	jal	450 <open>
  if (fd < 0) {
  2a:	0e054363          	bltz	a0,110 <main+0x110>
  2e:	f5a6                	sd	s1,232(sp)
  30:	f1ca                	sd	s2,224(sp)
  32:	edce                	sd	s3,216(sp)
  34:	e9d2                	sd	s4,208(sp)
  36:	84aa                	mv	s1,a0
    fprintf(2, "readcount: cannot open tempfile\n");
    exit(1);
  }
  
  // Write 140 bytes (35 bytes * 4 times) to the file to ensure it's > 100 bytes.
  printf("Writing 140 bytes to tempfile...\n");
  38:	00001517          	auipc	a0,0x1
  3c:	a2050513          	addi	a0,a0,-1504 # a58 <malloc+0x15c>
  40:	009000ef          	jal	848 <printf>
  44:	4911                	li	s2,4
  for(i = 0; i < 4; i++){
    if(write(fd, test_string, 35) != 35){
  46:	00001997          	auipc	s3,0x1
  4a:	a3a98993          	addi	s3,s3,-1478 # a80 <malloc+0x184>
  4e:	02300613          	li	a2,35
  52:	85ce                	mv	a1,s3
  54:	8526                	mv	a0,s1
  56:	3da000ef          	jal	430 <write>
  5a:	02300793          	li	a5,35
  5e:	0cf51763          	bne	a0,a5,12c <main+0x12c>
  for(i = 0; i < 4; i++){
  62:	397d                	addiw	s2,s2,-1
  64:	fe0915e3          	bnez	s2,4e <main+0x4e>
      fprintf(2, "readcount: failed to write to tempfile\n");
      exit(1);
    }
  }
  close(fd);
  68:	8526                	mv	a0,s1
  6a:	3ce000ef          	jal	438 <close>

  // Re-open for reading
  fd = open("tempfile", O_RDONLY);
  6e:	4581                	li	a1,0
  70:	00001517          	auipc	a0,0x1
  74:	9b050513          	addi	a0,a0,-1616 # a20 <malloc+0x124>
  78:	3d8000ef          	jal	450 <open>
  7c:	84aa                	mv	s1,a0
  if (fd < 0) {
  7e:	0c054163          	bltz	a0,140 <main+0x140>
    fprintf(2, "readcount: cannot open tempfile\n");
    exit(1);
  }

  // Get the read count before the read call
  count1 = getreadcount();
  82:	42e000ef          	jal	4b0 <getreadcount>
  86:	89aa                	mv	s3,a0
  
  // Read exactly 100 bytes from the file
  printf("Attempting to read 100 bytes...\n");
  88:	00001517          	auipc	a0,0x1
  8c:	a4850513          	addi	a0,a0,-1464 # ad0 <malloc+0x1d4>
  90:	7b8000ef          	jal	848 <printf>
  n = read(fd, buf, 100);
  94:	06400613          	li	a2,100
  98:	f0840593          	addi	a1,s0,-248
  9c:	8526                	mv	a0,s1
  9e:	38a000ef          	jal	428 <read>
  a2:	892a                	mv	s2,a0
  if (n < 0) {
  a4:	0a054863          	bltz	a0,154 <main+0x154>
    close(fd);
    exit(1);
  }

  // Get the read count after the read call
  count2 = getreadcount();
  a8:	408000ef          	jal	4b0 <getreadcount>
  ac:	8a2a                	mv	s4,a0

  printf("Bytes actually read: %d\n", n);
  ae:	85ca                	mv	a1,s2
  b0:	00001517          	auipc	a0,0x1
  b4:	a6050513          	addi	a0,a0,-1440 # b10 <malloc+0x214>
  b8:	790000ef          	jal	848 <printf>
  printf("Read count before read: %ld\n", count1);
  bc:	85ce                	mv	a1,s3
  be:	00001517          	auipc	a0,0x1
  c2:	a7250513          	addi	a0,a0,-1422 # b30 <malloc+0x234>
  c6:	782000ef          	jal	848 <printf>
  printf("Read count after read: %ld\n", count2);
  ca:	85d2                	mv	a1,s4
  cc:	00001517          	auipc	a0,0x1
  d0:	a8450513          	addi	a0,a0,-1404 # b50 <malloc+0x254>
  d4:	774000ef          	jal	848 <printf>
  
  // We expect n to be 100 now.
  if ((count2 - count1) == n && n == 100) {
  d8:	413a07b3          	sub	a5,s4,s3
  dc:	01279663          	bne	a5,s2,e8 <main+0xe8>
  e0:	06400793          	li	a5,100
  e4:	08f90563          	beq	s2,a5,16e <main+0x16e>
    printf("Verification successful: count increased by exactly 100 bytes.\n");
  } else {
    printf("Verification failed: expected an increase of 100, but got %d.\n", (int)(count2 - count1));
  e8:	413a05bb          	subw	a1,s4,s3
  ec:	00001517          	auipc	a0,0x1
  f0:	ac450513          	addi	a0,a0,-1340 # bb0 <malloc+0x2b4>
  f4:	754000ef          	jal	848 <printf>
  }

  close(fd);
  f8:	8526                	mv	a0,s1
  fa:	33e000ef          	jal	438 <close>
  unlink("tempfile");
  fe:	00001517          	auipc	a0,0x1
 102:	92250513          	addi	a0,a0,-1758 # a20 <malloc+0x124>
 106:	35a000ef          	jal	460 <unlink>

  exit(0);
 10a:	4501                	li	a0,0
 10c:	304000ef          	jal	410 <exit>
 110:	f5a6                	sd	s1,232(sp)
 112:	f1ca                	sd	s2,224(sp)
 114:	edce                	sd	s3,216(sp)
 116:	e9d2                	sd	s4,208(sp)
    fprintf(2, "readcount: cannot open tempfile\n");
 118:	00001597          	auipc	a1,0x1
 11c:	91858593          	addi	a1,a1,-1768 # a30 <malloc+0x134>
 120:	4509                	li	a0,2
 122:	6fc000ef          	jal	81e <fprintf>
    exit(1);
 126:	4505                	li	a0,1
 128:	2e8000ef          	jal	410 <exit>
      fprintf(2, "readcount: failed to write to tempfile\n");
 12c:	00001597          	auipc	a1,0x1
 130:	97c58593          	addi	a1,a1,-1668 # aa8 <malloc+0x1ac>
 134:	4509                	li	a0,2
 136:	6e8000ef          	jal	81e <fprintf>
      exit(1);
 13a:	4505                	li	a0,1
 13c:	2d4000ef          	jal	410 <exit>
    fprintf(2, "readcount: cannot open tempfile\n");
 140:	00001597          	auipc	a1,0x1
 144:	8f058593          	addi	a1,a1,-1808 # a30 <malloc+0x134>
 148:	4509                	li	a0,2
 14a:	6d4000ef          	jal	81e <fprintf>
    exit(1);
 14e:	4505                	li	a0,1
 150:	2c0000ef          	jal	410 <exit>
    fprintf(2, "readcount: read failed\n");
 154:	00001597          	auipc	a1,0x1
 158:	9a458593          	addi	a1,a1,-1628 # af8 <malloc+0x1fc>
 15c:	4509                	li	a0,2
 15e:	6c0000ef          	jal	81e <fprintf>
    close(fd);
 162:	8526                	mv	a0,s1
 164:	2d4000ef          	jal	438 <close>
    exit(1);
 168:	4505                	li	a0,1
 16a:	2a6000ef          	jal	410 <exit>
    printf("Verification successful: count increased by exactly 100 bytes.\n");
 16e:	00001517          	auipc	a0,0x1
 172:	a0250513          	addi	a0,a0,-1534 # b70 <malloc+0x274>
 176:	6d2000ef          	jal	848 <printf>
 17a:	bfbd                	j	f8 <main+0xf8>

000000000000017c <start>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
start(int argc, char **argv)
{
 17c:	1141                	addi	sp,sp,-16
 17e:	e406                	sd	ra,8(sp)
 180:	e022                	sd	s0,0(sp)
 182:	0800                	addi	s0,sp,16
  int r;
  extern int main(int argc, char **argv);
  r = main(argc, argv);
 184:	e7dff0ef          	jal	0 <main>
  exit(r);
 188:	288000ef          	jal	410 <exit>

000000000000018c <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
 18c:	1141                	addi	sp,sp,-16
 18e:	e422                	sd	s0,8(sp)
 190:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 192:	87aa                	mv	a5,a0
 194:	0585                	addi	a1,a1,1
 196:	0785                	addi	a5,a5,1
 198:	fff5c703          	lbu	a4,-1(a1)
 19c:	fee78fa3          	sb	a4,-1(a5)
 1a0:	fb75                	bnez	a4,194 <strcpy+0x8>
    ;
  return os;
}
 1a2:	6422                	ld	s0,8(sp)
 1a4:	0141                	addi	sp,sp,16
 1a6:	8082                	ret

00000000000001a8 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 1a8:	1141                	addi	sp,sp,-16
 1aa:	e422                	sd	s0,8(sp)
 1ac:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 1ae:	00054783          	lbu	a5,0(a0)
 1b2:	cb91                	beqz	a5,1c6 <strcmp+0x1e>
 1b4:	0005c703          	lbu	a4,0(a1)
 1b8:	00f71763          	bne	a4,a5,1c6 <strcmp+0x1e>
    p++, q++;
 1bc:	0505                	addi	a0,a0,1
 1be:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 1c0:	00054783          	lbu	a5,0(a0)
 1c4:	fbe5                	bnez	a5,1b4 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 1c6:	0005c503          	lbu	a0,0(a1)
}
 1ca:	40a7853b          	subw	a0,a5,a0
 1ce:	6422                	ld	s0,8(sp)
 1d0:	0141                	addi	sp,sp,16
 1d2:	8082                	ret

00000000000001d4 <strlen>:

uint
strlen(const char *s)
{
 1d4:	1141                	addi	sp,sp,-16
 1d6:	e422                	sd	s0,8(sp)
 1d8:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 1da:	00054783          	lbu	a5,0(a0)
 1de:	cf91                	beqz	a5,1fa <strlen+0x26>
 1e0:	0505                	addi	a0,a0,1
 1e2:	87aa                	mv	a5,a0
 1e4:	86be                	mv	a3,a5
 1e6:	0785                	addi	a5,a5,1
 1e8:	fff7c703          	lbu	a4,-1(a5)
 1ec:	ff65                	bnez	a4,1e4 <strlen+0x10>
 1ee:	40a6853b          	subw	a0,a3,a0
 1f2:	2505                	addiw	a0,a0,1
    ;
  return n;
}
 1f4:	6422                	ld	s0,8(sp)
 1f6:	0141                	addi	sp,sp,16
 1f8:	8082                	ret
  for(n = 0; s[n]; n++)
 1fa:	4501                	li	a0,0
 1fc:	bfe5                	j	1f4 <strlen+0x20>

00000000000001fe <memset>:

void*
memset(void *dst, int c, uint n)
{
 1fe:	1141                	addi	sp,sp,-16
 200:	e422                	sd	s0,8(sp)
 202:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 204:	ca19                	beqz	a2,21a <memset+0x1c>
 206:	87aa                	mv	a5,a0
 208:	1602                	slli	a2,a2,0x20
 20a:	9201                	srli	a2,a2,0x20
 20c:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 210:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 214:	0785                	addi	a5,a5,1
 216:	fee79de3          	bne	a5,a4,210 <memset+0x12>
  }
  return dst;
}
 21a:	6422                	ld	s0,8(sp)
 21c:	0141                	addi	sp,sp,16
 21e:	8082                	ret

0000000000000220 <strchr>:

char*
strchr(const char *s, char c)
{
 220:	1141                	addi	sp,sp,-16
 222:	e422                	sd	s0,8(sp)
 224:	0800                	addi	s0,sp,16
  for(; *s; s++)
 226:	00054783          	lbu	a5,0(a0)
 22a:	cb99                	beqz	a5,240 <strchr+0x20>
    if(*s == c)
 22c:	00f58763          	beq	a1,a5,23a <strchr+0x1a>
  for(; *s; s++)
 230:	0505                	addi	a0,a0,1
 232:	00054783          	lbu	a5,0(a0)
 236:	fbfd                	bnez	a5,22c <strchr+0xc>
      return (char*)s;
  return 0;
 238:	4501                	li	a0,0
}
 23a:	6422                	ld	s0,8(sp)
 23c:	0141                	addi	sp,sp,16
 23e:	8082                	ret
  return 0;
 240:	4501                	li	a0,0
 242:	bfe5                	j	23a <strchr+0x1a>

0000000000000244 <gets>:

char*
gets(char *buf, int max)
{
 244:	711d                	addi	sp,sp,-96
 246:	ec86                	sd	ra,88(sp)
 248:	e8a2                	sd	s0,80(sp)
 24a:	e4a6                	sd	s1,72(sp)
 24c:	e0ca                	sd	s2,64(sp)
 24e:	fc4e                	sd	s3,56(sp)
 250:	f852                	sd	s4,48(sp)
 252:	f456                	sd	s5,40(sp)
 254:	f05a                	sd	s6,32(sp)
 256:	ec5e                	sd	s7,24(sp)
 258:	1080                	addi	s0,sp,96
 25a:	8baa                	mv	s7,a0
 25c:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 25e:	892a                	mv	s2,a0
 260:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 262:	4aa9                	li	s5,10
 264:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 266:	89a6                	mv	s3,s1
 268:	2485                	addiw	s1,s1,1
 26a:	0344d663          	bge	s1,s4,296 <gets+0x52>
    cc = read(0, &c, 1);
 26e:	4605                	li	a2,1
 270:	faf40593          	addi	a1,s0,-81
 274:	4501                	li	a0,0
 276:	1b2000ef          	jal	428 <read>
    if(cc < 1)
 27a:	00a05e63          	blez	a0,296 <gets+0x52>
    buf[i++] = c;
 27e:	faf44783          	lbu	a5,-81(s0)
 282:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 286:	01578763          	beq	a5,s5,294 <gets+0x50>
 28a:	0905                	addi	s2,s2,1
 28c:	fd679de3          	bne	a5,s6,266 <gets+0x22>
    buf[i++] = c;
 290:	89a6                	mv	s3,s1
 292:	a011                	j	296 <gets+0x52>
 294:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 296:	99de                	add	s3,s3,s7
 298:	00098023          	sb	zero,0(s3)
  return buf;
}
 29c:	855e                	mv	a0,s7
 29e:	60e6                	ld	ra,88(sp)
 2a0:	6446                	ld	s0,80(sp)
 2a2:	64a6                	ld	s1,72(sp)
 2a4:	6906                	ld	s2,64(sp)
 2a6:	79e2                	ld	s3,56(sp)
 2a8:	7a42                	ld	s4,48(sp)
 2aa:	7aa2                	ld	s5,40(sp)
 2ac:	7b02                	ld	s6,32(sp)
 2ae:	6be2                	ld	s7,24(sp)
 2b0:	6125                	addi	sp,sp,96
 2b2:	8082                	ret

00000000000002b4 <stat>:

int
stat(const char *n, struct stat *st)
{
 2b4:	1101                	addi	sp,sp,-32
 2b6:	ec06                	sd	ra,24(sp)
 2b8:	e822                	sd	s0,16(sp)
 2ba:	e04a                	sd	s2,0(sp)
 2bc:	1000                	addi	s0,sp,32
 2be:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 2c0:	4581                	li	a1,0
 2c2:	18e000ef          	jal	450 <open>
  if(fd < 0)
 2c6:	02054263          	bltz	a0,2ea <stat+0x36>
 2ca:	e426                	sd	s1,8(sp)
 2cc:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 2ce:	85ca                	mv	a1,s2
 2d0:	198000ef          	jal	468 <fstat>
 2d4:	892a                	mv	s2,a0
  close(fd);
 2d6:	8526                	mv	a0,s1
 2d8:	160000ef          	jal	438 <close>
  return r;
 2dc:	64a2                	ld	s1,8(sp)
}
 2de:	854a                	mv	a0,s2
 2e0:	60e2                	ld	ra,24(sp)
 2e2:	6442                	ld	s0,16(sp)
 2e4:	6902                	ld	s2,0(sp)
 2e6:	6105                	addi	sp,sp,32
 2e8:	8082                	ret
    return -1;
 2ea:	597d                	li	s2,-1
 2ec:	bfcd                	j	2de <stat+0x2a>

00000000000002ee <atoi>:

int
atoi(const char *s)
{
 2ee:	1141                	addi	sp,sp,-16
 2f0:	e422                	sd	s0,8(sp)
 2f2:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 2f4:	00054683          	lbu	a3,0(a0)
 2f8:	fd06879b          	addiw	a5,a3,-48
 2fc:	0ff7f793          	zext.b	a5,a5
 300:	4625                	li	a2,9
 302:	02f66863          	bltu	a2,a5,332 <atoi+0x44>
 306:	872a                	mv	a4,a0
  n = 0;
 308:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 30a:	0705                	addi	a4,a4,1
 30c:	0025179b          	slliw	a5,a0,0x2
 310:	9fa9                	addw	a5,a5,a0
 312:	0017979b          	slliw	a5,a5,0x1
 316:	9fb5                	addw	a5,a5,a3
 318:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 31c:	00074683          	lbu	a3,0(a4)
 320:	fd06879b          	addiw	a5,a3,-48
 324:	0ff7f793          	zext.b	a5,a5
 328:	fef671e3          	bgeu	a2,a5,30a <atoi+0x1c>
  return n;
}
 32c:	6422                	ld	s0,8(sp)
 32e:	0141                	addi	sp,sp,16
 330:	8082                	ret
  n = 0;
 332:	4501                	li	a0,0
 334:	bfe5                	j	32c <atoi+0x3e>

0000000000000336 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 336:	1141                	addi	sp,sp,-16
 338:	e422                	sd	s0,8(sp)
 33a:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 33c:	02b57463          	bgeu	a0,a1,364 <memmove+0x2e>
    while(n-- > 0)
 340:	00c05f63          	blez	a2,35e <memmove+0x28>
 344:	1602                	slli	a2,a2,0x20
 346:	9201                	srli	a2,a2,0x20
 348:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 34c:	872a                	mv	a4,a0
      *dst++ = *src++;
 34e:	0585                	addi	a1,a1,1
 350:	0705                	addi	a4,a4,1
 352:	fff5c683          	lbu	a3,-1(a1)
 356:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 35a:	fef71ae3          	bne	a4,a5,34e <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 35e:	6422                	ld	s0,8(sp)
 360:	0141                	addi	sp,sp,16
 362:	8082                	ret
    dst += n;
 364:	00c50733          	add	a4,a0,a2
    src += n;
 368:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 36a:	fec05ae3          	blez	a2,35e <memmove+0x28>
 36e:	fff6079b          	addiw	a5,a2,-1
 372:	1782                	slli	a5,a5,0x20
 374:	9381                	srli	a5,a5,0x20
 376:	fff7c793          	not	a5,a5
 37a:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 37c:	15fd                	addi	a1,a1,-1
 37e:	177d                	addi	a4,a4,-1
 380:	0005c683          	lbu	a3,0(a1)
 384:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 388:	fee79ae3          	bne	a5,a4,37c <memmove+0x46>
 38c:	bfc9                	j	35e <memmove+0x28>

000000000000038e <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 38e:	1141                	addi	sp,sp,-16
 390:	e422                	sd	s0,8(sp)
 392:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 394:	ca05                	beqz	a2,3c4 <memcmp+0x36>
 396:	fff6069b          	addiw	a3,a2,-1
 39a:	1682                	slli	a3,a3,0x20
 39c:	9281                	srli	a3,a3,0x20
 39e:	0685                	addi	a3,a3,1
 3a0:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 3a2:	00054783          	lbu	a5,0(a0)
 3a6:	0005c703          	lbu	a4,0(a1)
 3aa:	00e79863          	bne	a5,a4,3ba <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 3ae:	0505                	addi	a0,a0,1
    p2++;
 3b0:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 3b2:	fed518e3          	bne	a0,a3,3a2 <memcmp+0x14>
  }
  return 0;
 3b6:	4501                	li	a0,0
 3b8:	a019                	j	3be <memcmp+0x30>
      return *p1 - *p2;
 3ba:	40e7853b          	subw	a0,a5,a4
}
 3be:	6422                	ld	s0,8(sp)
 3c0:	0141                	addi	sp,sp,16
 3c2:	8082                	ret
  return 0;
 3c4:	4501                	li	a0,0
 3c6:	bfe5                	j	3be <memcmp+0x30>

00000000000003c8 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 3c8:	1141                	addi	sp,sp,-16
 3ca:	e406                	sd	ra,8(sp)
 3cc:	e022                	sd	s0,0(sp)
 3ce:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 3d0:	f67ff0ef          	jal	336 <memmove>
}
 3d4:	60a2                	ld	ra,8(sp)
 3d6:	6402                	ld	s0,0(sp)
 3d8:	0141                	addi	sp,sp,16
 3da:	8082                	ret

00000000000003dc <sbrk>:

char *
sbrk(int n) {
 3dc:	1141                	addi	sp,sp,-16
 3de:	e406                	sd	ra,8(sp)
 3e0:	e022                	sd	s0,0(sp)
 3e2:	0800                	addi	s0,sp,16
  return sys_sbrk(n, SBRK_EAGER);
 3e4:	4585                	li	a1,1
 3e6:	0b2000ef          	jal	498 <sys_sbrk>
}
 3ea:	60a2                	ld	ra,8(sp)
 3ec:	6402                	ld	s0,0(sp)
 3ee:	0141                	addi	sp,sp,16
 3f0:	8082                	ret

00000000000003f2 <sbrklazy>:

char *
sbrklazy(int n) {
 3f2:	1141                	addi	sp,sp,-16
 3f4:	e406                	sd	ra,8(sp)
 3f6:	e022                	sd	s0,0(sp)
 3f8:	0800                	addi	s0,sp,16
  return sys_sbrk(n, SBRK_LAZY);
 3fa:	4589                	li	a1,2
 3fc:	09c000ef          	jal	498 <sys_sbrk>
}
 400:	60a2                	ld	ra,8(sp)
 402:	6402                	ld	s0,0(sp)
 404:	0141                	addi	sp,sp,16
 406:	8082                	ret

0000000000000408 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 408:	4885                	li	a7,1
 ecall
 40a:	00000073          	ecall
 ret
 40e:	8082                	ret

0000000000000410 <exit>:
.global exit
exit:
 li a7, SYS_exit
 410:	4889                	li	a7,2
 ecall
 412:	00000073          	ecall
 ret
 416:	8082                	ret

0000000000000418 <wait>:
.global wait
wait:
 li a7, SYS_wait
 418:	488d                	li	a7,3
 ecall
 41a:	00000073          	ecall
 ret
 41e:	8082                	ret

0000000000000420 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 420:	4891                	li	a7,4
 ecall
 422:	00000073          	ecall
 ret
 426:	8082                	ret

0000000000000428 <read>:
.global read
read:
 li a7, SYS_read
 428:	4895                	li	a7,5
 ecall
 42a:	00000073          	ecall
 ret
 42e:	8082                	ret

0000000000000430 <write>:
.global write
write:
 li a7, SYS_write
 430:	48c1                	li	a7,16
 ecall
 432:	00000073          	ecall
 ret
 436:	8082                	ret

0000000000000438 <close>:
.global close
close:
 li a7, SYS_close
 438:	48d5                	li	a7,21
 ecall
 43a:	00000073          	ecall
 ret
 43e:	8082                	ret

0000000000000440 <kill>:
.global kill
kill:
 li a7, SYS_kill
 440:	4899                	li	a7,6
 ecall
 442:	00000073          	ecall
 ret
 446:	8082                	ret

0000000000000448 <exec>:
.global exec
exec:
 li a7, SYS_exec
 448:	489d                	li	a7,7
 ecall
 44a:	00000073          	ecall
 ret
 44e:	8082                	ret

0000000000000450 <open>:
.global open
open:
 li a7, SYS_open
 450:	48bd                	li	a7,15
 ecall
 452:	00000073          	ecall
 ret
 456:	8082                	ret

0000000000000458 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 458:	48c5                	li	a7,17
 ecall
 45a:	00000073          	ecall
 ret
 45e:	8082                	ret

0000000000000460 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 460:	48c9                	li	a7,18
 ecall
 462:	00000073          	ecall
 ret
 466:	8082                	ret

0000000000000468 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 468:	48a1                	li	a7,8
 ecall
 46a:	00000073          	ecall
 ret
 46e:	8082                	ret

0000000000000470 <link>:
.global link
link:
 li a7, SYS_link
 470:	48cd                	li	a7,19
 ecall
 472:	00000073          	ecall
 ret
 476:	8082                	ret

0000000000000478 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 478:	48d1                	li	a7,20
 ecall
 47a:	00000073          	ecall
 ret
 47e:	8082                	ret

0000000000000480 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 480:	48a5                	li	a7,9
 ecall
 482:	00000073          	ecall
 ret
 486:	8082                	ret

0000000000000488 <dup>:
.global dup
dup:
 li a7, SYS_dup
 488:	48a9                	li	a7,10
 ecall
 48a:	00000073          	ecall
 ret
 48e:	8082                	ret

0000000000000490 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 490:	48ad                	li	a7,11
 ecall
 492:	00000073          	ecall
 ret
 496:	8082                	ret

0000000000000498 <sys_sbrk>:
.global sys_sbrk
sys_sbrk:
 li a7, SYS_sbrk
 498:	48b1                	li	a7,12
 ecall
 49a:	00000073          	ecall
 ret
 49e:	8082                	ret

00000000000004a0 <pause>:
.global pause
pause:
 li a7, SYS_pause
 4a0:	48b5                	li	a7,13
 ecall
 4a2:	00000073          	ecall
 ret
 4a6:	8082                	ret

00000000000004a8 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 4a8:	48b9                	li	a7,14
 ecall
 4aa:	00000073          	ecall
 ret
 4ae:	8082                	ret

00000000000004b0 <getreadcount>:
.global getreadcount
getreadcount:
 li a7, SYS_getreadcount
 4b0:	48d9                	li	a7,22
 ecall
 4b2:	00000073          	ecall
 ret
 4b6:	8082                	ret

00000000000004b8 <set_nice>:
.global set_nice
set_nice:
 li a7, SYS_set_nice
 4b8:	48dd                	li	a7,23
 ecall
 4ba:	00000073          	ecall
 ret
 4be:	8082                	ret

00000000000004c0 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 4c0:	1101                	addi	sp,sp,-32
 4c2:	ec06                	sd	ra,24(sp)
 4c4:	e822                	sd	s0,16(sp)
 4c6:	1000                	addi	s0,sp,32
 4c8:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 4cc:	4605                	li	a2,1
 4ce:	fef40593          	addi	a1,s0,-17
 4d2:	f5fff0ef          	jal	430 <write>
}
 4d6:	60e2                	ld	ra,24(sp)
 4d8:	6442                	ld	s0,16(sp)
 4da:	6105                	addi	sp,sp,32
 4dc:	8082                	ret

00000000000004de <printint>:

static void
printint(int fd, long long xx, int base, int sgn)
{
 4de:	715d                	addi	sp,sp,-80
 4e0:	e486                	sd	ra,72(sp)
 4e2:	e0a2                	sd	s0,64(sp)
 4e4:	f84a                	sd	s2,48(sp)
 4e6:	0880                	addi	s0,sp,80
 4e8:	892a                	mv	s2,a0
  char buf[20];
  int i, neg;
  unsigned long long x;

  neg = 0;
  if(sgn && xx < 0){
 4ea:	c299                	beqz	a3,4f0 <printint+0x12>
 4ec:	0805c363          	bltz	a1,572 <printint+0x94>
  neg = 0;
 4f0:	4881                	li	a7,0
 4f2:	fb840693          	addi	a3,s0,-72
    x = -xx;
  } else {
    x = xx;
  }

  i = 0;
 4f6:	4781                	li	a5,0
  do{
    buf[i++] = digits[x % base];
 4f8:	00000517          	auipc	a0,0x0
 4fc:	70050513          	addi	a0,a0,1792 # bf8 <digits>
 500:	883e                	mv	a6,a5
 502:	2785                	addiw	a5,a5,1
 504:	02c5f733          	remu	a4,a1,a2
 508:	972a                	add	a4,a4,a0
 50a:	00074703          	lbu	a4,0(a4)
 50e:	00e68023          	sb	a4,0(a3)
  }while((x /= base) != 0);
 512:	872e                	mv	a4,a1
 514:	02c5d5b3          	divu	a1,a1,a2
 518:	0685                	addi	a3,a3,1
 51a:	fec773e3          	bgeu	a4,a2,500 <printint+0x22>
  if(neg)
 51e:	00088b63          	beqz	a7,534 <printint+0x56>
    buf[i++] = '-';
 522:	fd078793          	addi	a5,a5,-48
 526:	97a2                	add	a5,a5,s0
 528:	02d00713          	li	a4,45
 52c:	fee78423          	sb	a4,-24(a5)
 530:	0028079b          	addiw	a5,a6,2

  while(--i >= 0)
 534:	02f05a63          	blez	a5,568 <printint+0x8a>
 538:	fc26                	sd	s1,56(sp)
 53a:	f44e                	sd	s3,40(sp)
 53c:	fb840713          	addi	a4,s0,-72
 540:	00f704b3          	add	s1,a4,a5
 544:	fff70993          	addi	s3,a4,-1
 548:	99be                	add	s3,s3,a5
 54a:	37fd                	addiw	a5,a5,-1
 54c:	1782                	slli	a5,a5,0x20
 54e:	9381                	srli	a5,a5,0x20
 550:	40f989b3          	sub	s3,s3,a5
    putc(fd, buf[i]);
 554:	fff4c583          	lbu	a1,-1(s1)
 558:	854a                	mv	a0,s2
 55a:	f67ff0ef          	jal	4c0 <putc>
  while(--i >= 0)
 55e:	14fd                	addi	s1,s1,-1
 560:	ff349ae3          	bne	s1,s3,554 <printint+0x76>
 564:	74e2                	ld	s1,56(sp)
 566:	79a2                	ld	s3,40(sp)
}
 568:	60a6                	ld	ra,72(sp)
 56a:	6406                	ld	s0,64(sp)
 56c:	7942                	ld	s2,48(sp)
 56e:	6161                	addi	sp,sp,80
 570:	8082                	ret
    x = -xx;
 572:	40b005b3          	neg	a1,a1
    neg = 1;
 576:	4885                	li	a7,1
    x = -xx;
 578:	bfad                	j	4f2 <printint+0x14>

000000000000057a <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %c, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 57a:	711d                	addi	sp,sp,-96
 57c:	ec86                	sd	ra,88(sp)
 57e:	e8a2                	sd	s0,80(sp)
 580:	e0ca                	sd	s2,64(sp)
 582:	1080                	addi	s0,sp,96
  char *s;
  int c0, c1, c2, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 584:	0005c903          	lbu	s2,0(a1)
 588:	28090663          	beqz	s2,814 <vprintf+0x29a>
 58c:	e4a6                	sd	s1,72(sp)
 58e:	fc4e                	sd	s3,56(sp)
 590:	f852                	sd	s4,48(sp)
 592:	f456                	sd	s5,40(sp)
 594:	f05a                	sd	s6,32(sp)
 596:	ec5e                	sd	s7,24(sp)
 598:	e862                	sd	s8,16(sp)
 59a:	e466                	sd	s9,8(sp)
 59c:	8b2a                	mv	s6,a0
 59e:	8a2e                	mv	s4,a1
 5a0:	8bb2                	mv	s7,a2
  state = 0;
 5a2:	4981                	li	s3,0
  for(i = 0; fmt[i]; i++){
 5a4:	4481                	li	s1,0
 5a6:	4701                	li	a4,0
      if(c0 == '%'){
        state = '%';
      } else {
        putc(fd, c0);
      }
    } else if(state == '%'){
 5a8:	02500a93          	li	s5,37
      c1 = c2 = 0;
      if(c0) c1 = fmt[i+1] & 0xff;
      if(c1) c2 = fmt[i+2] & 0xff;
      if(c0 == 'd'){
 5ac:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c0 == 'l' && c1 == 'd'){
 5b0:	06c00c93          	li	s9,108
 5b4:	a005                	j	5d4 <vprintf+0x5a>
        putc(fd, c0);
 5b6:	85ca                	mv	a1,s2
 5b8:	855a                	mv	a0,s6
 5ba:	f07ff0ef          	jal	4c0 <putc>
 5be:	a019                	j	5c4 <vprintf+0x4a>
    } else if(state == '%'){
 5c0:	03598263          	beq	s3,s5,5e4 <vprintf+0x6a>
  for(i = 0; fmt[i]; i++){
 5c4:	2485                	addiw	s1,s1,1
 5c6:	8726                	mv	a4,s1
 5c8:	009a07b3          	add	a5,s4,s1
 5cc:	0007c903          	lbu	s2,0(a5)
 5d0:	22090a63          	beqz	s2,804 <vprintf+0x28a>
    c0 = fmt[i] & 0xff;
 5d4:	0009079b          	sext.w	a5,s2
    if(state == 0){
 5d8:	fe0994e3          	bnez	s3,5c0 <vprintf+0x46>
      if(c0 == '%'){
 5dc:	fd579de3          	bne	a5,s5,5b6 <vprintf+0x3c>
        state = '%';
 5e0:	89be                	mv	s3,a5
 5e2:	b7cd                	j	5c4 <vprintf+0x4a>
      if(c0) c1 = fmt[i+1] & 0xff;
 5e4:	00ea06b3          	add	a3,s4,a4
 5e8:	0016c683          	lbu	a3,1(a3)
      c1 = c2 = 0;
 5ec:	8636                	mv	a2,a3
      if(c1) c2 = fmt[i+2] & 0xff;
 5ee:	c681                	beqz	a3,5f6 <vprintf+0x7c>
 5f0:	9752                	add	a4,a4,s4
 5f2:	00274603          	lbu	a2,2(a4)
      if(c0 == 'd'){
 5f6:	05878363          	beq	a5,s8,63c <vprintf+0xc2>
      } else if(c0 == 'l' && c1 == 'd'){
 5fa:	05978d63          	beq	a5,s9,654 <vprintf+0xda>
        printint(fd, va_arg(ap, uint64), 10, 1);
        i += 1;
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
        printint(fd, va_arg(ap, uint64), 10, 1);
        i += 2;
      } else if(c0 == 'u'){
 5fe:	07500713          	li	a4,117
 602:	0ee78763          	beq	a5,a4,6f0 <vprintf+0x176>
        printint(fd, va_arg(ap, uint64), 10, 0);
        i += 1;
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
        printint(fd, va_arg(ap, uint64), 10, 0);
        i += 2;
      } else if(c0 == 'x'){
 606:	07800713          	li	a4,120
 60a:	12e78963          	beq	a5,a4,73c <vprintf+0x1c2>
        printint(fd, va_arg(ap, uint64), 16, 0);
        i += 1;
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
        printint(fd, va_arg(ap, uint64), 16, 0);
        i += 2;
      } else if(c0 == 'p'){
 60e:	07000713          	li	a4,112
 612:	14e78e63          	beq	a5,a4,76e <vprintf+0x1f4>
        printptr(fd, va_arg(ap, uint64));
      } else if(c0 == 'c'){
 616:	06300713          	li	a4,99
 61a:	18e78e63          	beq	a5,a4,7b6 <vprintf+0x23c>
        putc(fd, va_arg(ap, uint32));
      } else if(c0 == 's'){
 61e:	07300713          	li	a4,115
 622:	1ae78463          	beq	a5,a4,7ca <vprintf+0x250>
        if((s = va_arg(ap, char*)) == 0)
          s = "(null)";
        for(; *s; s++)
          putc(fd, *s);
      } else if(c0 == '%'){
 626:	02500713          	li	a4,37
 62a:	04e79563          	bne	a5,a4,674 <vprintf+0xfa>
        putc(fd, '%');
 62e:	02500593          	li	a1,37
 632:	855a                	mv	a0,s6
 634:	e8dff0ef          	jal	4c0 <putc>
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c0);
      }

      state = 0;
 638:	4981                	li	s3,0
 63a:	b769                	j	5c4 <vprintf+0x4a>
        printint(fd, va_arg(ap, int), 10, 1);
 63c:	008b8913          	addi	s2,s7,8
 640:	4685                	li	a3,1
 642:	4629                	li	a2,10
 644:	000ba583          	lw	a1,0(s7)
 648:	855a                	mv	a0,s6
 64a:	e95ff0ef          	jal	4de <printint>
 64e:	8bca                	mv	s7,s2
      state = 0;
 650:	4981                	li	s3,0
 652:	bf8d                	j	5c4 <vprintf+0x4a>
      } else if(c0 == 'l' && c1 == 'd'){
 654:	06400793          	li	a5,100
 658:	02f68963          	beq	a3,a5,68a <vprintf+0x110>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
 65c:	06c00793          	li	a5,108
 660:	04f68263          	beq	a3,a5,6a4 <vprintf+0x12a>
      } else if(c0 == 'l' && c1 == 'u'){
 664:	07500793          	li	a5,117
 668:	0af68063          	beq	a3,a5,708 <vprintf+0x18e>
      } else if(c0 == 'l' && c1 == 'x'){
 66c:	07800793          	li	a5,120
 670:	0ef68263          	beq	a3,a5,754 <vprintf+0x1da>
        putc(fd, '%');
 674:	02500593          	li	a1,37
 678:	855a                	mv	a0,s6
 67a:	e47ff0ef          	jal	4c0 <putc>
        putc(fd, c0);
 67e:	85ca                	mv	a1,s2
 680:	855a                	mv	a0,s6
 682:	e3fff0ef          	jal	4c0 <putc>
      state = 0;
 686:	4981                	li	s3,0
 688:	bf35                	j	5c4 <vprintf+0x4a>
        printint(fd, va_arg(ap, uint64), 10, 1);
 68a:	008b8913          	addi	s2,s7,8
 68e:	4685                	li	a3,1
 690:	4629                	li	a2,10
 692:	000bb583          	ld	a1,0(s7)
 696:	855a                	mv	a0,s6
 698:	e47ff0ef          	jal	4de <printint>
        i += 1;
 69c:	2485                	addiw	s1,s1,1
        printint(fd, va_arg(ap, uint64), 10, 1);
 69e:	8bca                	mv	s7,s2
      state = 0;
 6a0:	4981                	li	s3,0
        i += 1;
 6a2:	b70d                	j	5c4 <vprintf+0x4a>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
 6a4:	06400793          	li	a5,100
 6a8:	02f60763          	beq	a2,a5,6d6 <vprintf+0x15c>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
 6ac:	07500793          	li	a5,117
 6b0:	06f60963          	beq	a2,a5,722 <vprintf+0x1a8>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
 6b4:	07800793          	li	a5,120
 6b8:	faf61ee3          	bne	a2,a5,674 <vprintf+0xfa>
        printint(fd, va_arg(ap, uint64), 16, 0);
 6bc:	008b8913          	addi	s2,s7,8
 6c0:	4681                	li	a3,0
 6c2:	4641                	li	a2,16
 6c4:	000bb583          	ld	a1,0(s7)
 6c8:	855a                	mv	a0,s6
 6ca:	e15ff0ef          	jal	4de <printint>
        i += 2;
 6ce:	2489                	addiw	s1,s1,2
        printint(fd, va_arg(ap, uint64), 16, 0);
 6d0:	8bca                	mv	s7,s2
      state = 0;
 6d2:	4981                	li	s3,0
        i += 2;
 6d4:	bdc5                	j	5c4 <vprintf+0x4a>
        printint(fd, va_arg(ap, uint64), 10, 1);
 6d6:	008b8913          	addi	s2,s7,8
 6da:	4685                	li	a3,1
 6dc:	4629                	li	a2,10
 6de:	000bb583          	ld	a1,0(s7)
 6e2:	855a                	mv	a0,s6
 6e4:	dfbff0ef          	jal	4de <printint>
        i += 2;
 6e8:	2489                	addiw	s1,s1,2
        printint(fd, va_arg(ap, uint64), 10, 1);
 6ea:	8bca                	mv	s7,s2
      state = 0;
 6ec:	4981                	li	s3,0
        i += 2;
 6ee:	bdd9                	j	5c4 <vprintf+0x4a>
        printint(fd, va_arg(ap, uint32), 10, 0);
 6f0:	008b8913          	addi	s2,s7,8
 6f4:	4681                	li	a3,0
 6f6:	4629                	li	a2,10
 6f8:	000be583          	lwu	a1,0(s7)
 6fc:	855a                	mv	a0,s6
 6fe:	de1ff0ef          	jal	4de <printint>
 702:	8bca                	mv	s7,s2
      state = 0;
 704:	4981                	li	s3,0
 706:	bd7d                	j	5c4 <vprintf+0x4a>
        printint(fd, va_arg(ap, uint64), 10, 0);
 708:	008b8913          	addi	s2,s7,8
 70c:	4681                	li	a3,0
 70e:	4629                	li	a2,10
 710:	000bb583          	ld	a1,0(s7)
 714:	855a                	mv	a0,s6
 716:	dc9ff0ef          	jal	4de <printint>
        i += 1;
 71a:	2485                	addiw	s1,s1,1
        printint(fd, va_arg(ap, uint64), 10, 0);
 71c:	8bca                	mv	s7,s2
      state = 0;
 71e:	4981                	li	s3,0
        i += 1;
 720:	b555                	j	5c4 <vprintf+0x4a>
        printint(fd, va_arg(ap, uint64), 10, 0);
 722:	008b8913          	addi	s2,s7,8
 726:	4681                	li	a3,0
 728:	4629                	li	a2,10
 72a:	000bb583          	ld	a1,0(s7)
 72e:	855a                	mv	a0,s6
 730:	dafff0ef          	jal	4de <printint>
        i += 2;
 734:	2489                	addiw	s1,s1,2
        printint(fd, va_arg(ap, uint64), 10, 0);
 736:	8bca                	mv	s7,s2
      state = 0;
 738:	4981                	li	s3,0
        i += 2;
 73a:	b569                	j	5c4 <vprintf+0x4a>
        printint(fd, va_arg(ap, uint32), 16, 0);
 73c:	008b8913          	addi	s2,s7,8
 740:	4681                	li	a3,0
 742:	4641                	li	a2,16
 744:	000be583          	lwu	a1,0(s7)
 748:	855a                	mv	a0,s6
 74a:	d95ff0ef          	jal	4de <printint>
 74e:	8bca                	mv	s7,s2
      state = 0;
 750:	4981                	li	s3,0
 752:	bd8d                	j	5c4 <vprintf+0x4a>
        printint(fd, va_arg(ap, uint64), 16, 0);
 754:	008b8913          	addi	s2,s7,8
 758:	4681                	li	a3,0
 75a:	4641                	li	a2,16
 75c:	000bb583          	ld	a1,0(s7)
 760:	855a                	mv	a0,s6
 762:	d7dff0ef          	jal	4de <printint>
        i += 1;
 766:	2485                	addiw	s1,s1,1
        printint(fd, va_arg(ap, uint64), 16, 0);
 768:	8bca                	mv	s7,s2
      state = 0;
 76a:	4981                	li	s3,0
        i += 1;
 76c:	bda1                	j	5c4 <vprintf+0x4a>
 76e:	e06a                	sd	s10,0(sp)
        printptr(fd, va_arg(ap, uint64));
 770:	008b8d13          	addi	s10,s7,8
 774:	000bb983          	ld	s3,0(s7)
  putc(fd, '0');
 778:	03000593          	li	a1,48
 77c:	855a                	mv	a0,s6
 77e:	d43ff0ef          	jal	4c0 <putc>
  putc(fd, 'x');
 782:	07800593          	li	a1,120
 786:	855a                	mv	a0,s6
 788:	d39ff0ef          	jal	4c0 <putc>
 78c:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 78e:	00000b97          	auipc	s7,0x0
 792:	46ab8b93          	addi	s7,s7,1130 # bf8 <digits>
 796:	03c9d793          	srli	a5,s3,0x3c
 79a:	97de                	add	a5,a5,s7
 79c:	0007c583          	lbu	a1,0(a5)
 7a0:	855a                	mv	a0,s6
 7a2:	d1fff0ef          	jal	4c0 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 7a6:	0992                	slli	s3,s3,0x4
 7a8:	397d                	addiw	s2,s2,-1
 7aa:	fe0916e3          	bnez	s2,796 <vprintf+0x21c>
        printptr(fd, va_arg(ap, uint64));
 7ae:	8bea                	mv	s7,s10
      state = 0;
 7b0:	4981                	li	s3,0
 7b2:	6d02                	ld	s10,0(sp)
 7b4:	bd01                	j	5c4 <vprintf+0x4a>
        putc(fd, va_arg(ap, uint32));
 7b6:	008b8913          	addi	s2,s7,8
 7ba:	000bc583          	lbu	a1,0(s7)
 7be:	855a                	mv	a0,s6
 7c0:	d01ff0ef          	jal	4c0 <putc>
 7c4:	8bca                	mv	s7,s2
      state = 0;
 7c6:	4981                	li	s3,0
 7c8:	bbf5                	j	5c4 <vprintf+0x4a>
        if((s = va_arg(ap, char*)) == 0)
 7ca:	008b8993          	addi	s3,s7,8
 7ce:	000bb903          	ld	s2,0(s7)
 7d2:	00090f63          	beqz	s2,7f0 <vprintf+0x276>
        for(; *s; s++)
 7d6:	00094583          	lbu	a1,0(s2)
 7da:	c195                	beqz	a1,7fe <vprintf+0x284>
          putc(fd, *s);
 7dc:	855a                	mv	a0,s6
 7de:	ce3ff0ef          	jal	4c0 <putc>
        for(; *s; s++)
 7e2:	0905                	addi	s2,s2,1
 7e4:	00094583          	lbu	a1,0(s2)
 7e8:	f9f5                	bnez	a1,7dc <vprintf+0x262>
        if((s = va_arg(ap, char*)) == 0)
 7ea:	8bce                	mv	s7,s3
      state = 0;
 7ec:	4981                	li	s3,0
 7ee:	bbd9                	j	5c4 <vprintf+0x4a>
          s = "(null)";
 7f0:	00000917          	auipc	s2,0x0
 7f4:	40090913          	addi	s2,s2,1024 # bf0 <malloc+0x2f4>
        for(; *s; s++)
 7f8:	02800593          	li	a1,40
 7fc:	b7c5                	j	7dc <vprintf+0x262>
        if((s = va_arg(ap, char*)) == 0)
 7fe:	8bce                	mv	s7,s3
      state = 0;
 800:	4981                	li	s3,0
 802:	b3c9                	j	5c4 <vprintf+0x4a>
 804:	64a6                	ld	s1,72(sp)
 806:	79e2                	ld	s3,56(sp)
 808:	7a42                	ld	s4,48(sp)
 80a:	7aa2                	ld	s5,40(sp)
 80c:	7b02                	ld	s6,32(sp)
 80e:	6be2                	ld	s7,24(sp)
 810:	6c42                	ld	s8,16(sp)
 812:	6ca2                	ld	s9,8(sp)
    }
  }
}
 814:	60e6                	ld	ra,88(sp)
 816:	6446                	ld	s0,80(sp)
 818:	6906                	ld	s2,64(sp)
 81a:	6125                	addi	sp,sp,96
 81c:	8082                	ret

000000000000081e <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 81e:	715d                	addi	sp,sp,-80
 820:	ec06                	sd	ra,24(sp)
 822:	e822                	sd	s0,16(sp)
 824:	1000                	addi	s0,sp,32
 826:	e010                	sd	a2,0(s0)
 828:	e414                	sd	a3,8(s0)
 82a:	e818                	sd	a4,16(s0)
 82c:	ec1c                	sd	a5,24(s0)
 82e:	03043023          	sd	a6,32(s0)
 832:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 836:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 83a:	8622                	mv	a2,s0
 83c:	d3fff0ef          	jal	57a <vprintf>
}
 840:	60e2                	ld	ra,24(sp)
 842:	6442                	ld	s0,16(sp)
 844:	6161                	addi	sp,sp,80
 846:	8082                	ret

0000000000000848 <printf>:

void
printf(const char *fmt, ...)
{
 848:	711d                	addi	sp,sp,-96
 84a:	ec06                	sd	ra,24(sp)
 84c:	e822                	sd	s0,16(sp)
 84e:	1000                	addi	s0,sp,32
 850:	e40c                	sd	a1,8(s0)
 852:	e810                	sd	a2,16(s0)
 854:	ec14                	sd	a3,24(s0)
 856:	f018                	sd	a4,32(s0)
 858:	f41c                	sd	a5,40(s0)
 85a:	03043823          	sd	a6,48(s0)
 85e:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 862:	00840613          	addi	a2,s0,8
 866:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 86a:	85aa                	mv	a1,a0
 86c:	4505                	li	a0,1
 86e:	d0dff0ef          	jal	57a <vprintf>
}
 872:	60e2                	ld	ra,24(sp)
 874:	6442                	ld	s0,16(sp)
 876:	6125                	addi	sp,sp,96
 878:	8082                	ret

000000000000087a <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 87a:	1141                	addi	sp,sp,-16
 87c:	e422                	sd	s0,8(sp)
 87e:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 880:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 884:	00001797          	auipc	a5,0x1
 888:	77c7b783          	ld	a5,1916(a5) # 2000 <freep>
 88c:	a02d                	j	8b6 <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 88e:	4618                	lw	a4,8(a2)
 890:	9f2d                	addw	a4,a4,a1
 892:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 896:	6398                	ld	a4,0(a5)
 898:	6310                	ld	a2,0(a4)
 89a:	a83d                	j	8d8 <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 89c:	ff852703          	lw	a4,-8(a0)
 8a0:	9f31                	addw	a4,a4,a2
 8a2:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 8a4:	ff053683          	ld	a3,-16(a0)
 8a8:	a091                	j	8ec <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 8aa:	6398                	ld	a4,0(a5)
 8ac:	00e7e463          	bltu	a5,a4,8b4 <free+0x3a>
 8b0:	00e6ea63          	bltu	a3,a4,8c4 <free+0x4a>
{
 8b4:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 8b6:	fed7fae3          	bgeu	a5,a3,8aa <free+0x30>
 8ba:	6398                	ld	a4,0(a5)
 8bc:	00e6e463          	bltu	a3,a4,8c4 <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 8c0:	fee7eae3          	bltu	a5,a4,8b4 <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 8c4:	ff852583          	lw	a1,-8(a0)
 8c8:	6390                	ld	a2,0(a5)
 8ca:	02059813          	slli	a6,a1,0x20
 8ce:	01c85713          	srli	a4,a6,0x1c
 8d2:	9736                	add	a4,a4,a3
 8d4:	fae60de3          	beq	a2,a4,88e <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 8d8:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 8dc:	4790                	lw	a2,8(a5)
 8de:	02061593          	slli	a1,a2,0x20
 8e2:	01c5d713          	srli	a4,a1,0x1c
 8e6:	973e                	add	a4,a4,a5
 8e8:	fae68ae3          	beq	a3,a4,89c <free+0x22>
    p->s.ptr = bp->s.ptr;
 8ec:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 8ee:	00001717          	auipc	a4,0x1
 8f2:	70f73923          	sd	a5,1810(a4) # 2000 <freep>
}
 8f6:	6422                	ld	s0,8(sp)
 8f8:	0141                	addi	sp,sp,16
 8fa:	8082                	ret

00000000000008fc <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 8fc:	7139                	addi	sp,sp,-64
 8fe:	fc06                	sd	ra,56(sp)
 900:	f822                	sd	s0,48(sp)
 902:	f426                	sd	s1,40(sp)
 904:	ec4e                	sd	s3,24(sp)
 906:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 908:	02051493          	slli	s1,a0,0x20
 90c:	9081                	srli	s1,s1,0x20
 90e:	04bd                	addi	s1,s1,15
 910:	8091                	srli	s1,s1,0x4
 912:	0014899b          	addiw	s3,s1,1
 916:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 918:	00001517          	auipc	a0,0x1
 91c:	6e853503          	ld	a0,1768(a0) # 2000 <freep>
 920:	c915                	beqz	a0,954 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 922:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 924:	4798                	lw	a4,8(a5)
 926:	08977a63          	bgeu	a4,s1,9ba <malloc+0xbe>
 92a:	f04a                	sd	s2,32(sp)
 92c:	e852                	sd	s4,16(sp)
 92e:	e456                	sd	s5,8(sp)
 930:	e05a                	sd	s6,0(sp)
  if(nu < 4096)
 932:	8a4e                	mv	s4,s3
 934:	0009871b          	sext.w	a4,s3
 938:	6685                	lui	a3,0x1
 93a:	00d77363          	bgeu	a4,a3,940 <malloc+0x44>
 93e:	6a05                	lui	s4,0x1
 940:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 944:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 948:	00001917          	auipc	s2,0x1
 94c:	6b890913          	addi	s2,s2,1720 # 2000 <freep>
  if(p == SBRK_ERROR)
 950:	5afd                	li	s5,-1
 952:	a081                	j	992 <malloc+0x96>
 954:	f04a                	sd	s2,32(sp)
 956:	e852                	sd	s4,16(sp)
 958:	e456                	sd	s5,8(sp)
 95a:	e05a                	sd	s6,0(sp)
    base.s.ptr = freep = prevp = &base;
 95c:	00001797          	auipc	a5,0x1
 960:	6b478793          	addi	a5,a5,1716 # 2010 <base>
 964:	00001717          	auipc	a4,0x1
 968:	68f73e23          	sd	a5,1692(a4) # 2000 <freep>
 96c:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 96e:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 972:	b7c1                	j	932 <malloc+0x36>
        prevp->s.ptr = p->s.ptr;
 974:	6398                	ld	a4,0(a5)
 976:	e118                	sd	a4,0(a0)
 978:	a8a9                	j	9d2 <malloc+0xd6>
  hp->s.size = nu;
 97a:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 97e:	0541                	addi	a0,a0,16
 980:	efbff0ef          	jal	87a <free>
  return freep;
 984:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 988:	c12d                	beqz	a0,9ea <malloc+0xee>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 98a:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 98c:	4798                	lw	a4,8(a5)
 98e:	02977263          	bgeu	a4,s1,9b2 <malloc+0xb6>
    if(p == freep)
 992:	00093703          	ld	a4,0(s2)
 996:	853e                	mv	a0,a5
 998:	fef719e3          	bne	a4,a5,98a <malloc+0x8e>
  p = sbrk(nu * sizeof(Header));
 99c:	8552                	mv	a0,s4
 99e:	a3fff0ef          	jal	3dc <sbrk>
  if(p == SBRK_ERROR)
 9a2:	fd551ce3          	bne	a0,s5,97a <malloc+0x7e>
        return 0;
 9a6:	4501                	li	a0,0
 9a8:	7902                	ld	s2,32(sp)
 9aa:	6a42                	ld	s4,16(sp)
 9ac:	6aa2                	ld	s5,8(sp)
 9ae:	6b02                	ld	s6,0(sp)
 9b0:	a03d                	j	9de <malloc+0xe2>
 9b2:	7902                	ld	s2,32(sp)
 9b4:	6a42                	ld	s4,16(sp)
 9b6:	6aa2                	ld	s5,8(sp)
 9b8:	6b02                	ld	s6,0(sp)
      if(p->s.size == nunits)
 9ba:	fae48de3          	beq	s1,a4,974 <malloc+0x78>
        p->s.size -= nunits;
 9be:	4137073b          	subw	a4,a4,s3
 9c2:	c798                	sw	a4,8(a5)
        p += p->s.size;
 9c4:	02071693          	slli	a3,a4,0x20
 9c8:	01c6d713          	srli	a4,a3,0x1c
 9cc:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 9ce:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 9d2:	00001717          	auipc	a4,0x1
 9d6:	62a73723          	sd	a0,1582(a4) # 2000 <freep>
      return (void*)(p + 1);
 9da:	01078513          	addi	a0,a5,16
  }
}
 9de:	70e2                	ld	ra,56(sp)
 9e0:	7442                	ld	s0,48(sp)
 9e2:	74a2                	ld	s1,40(sp)
 9e4:	69e2                	ld	s3,24(sp)
 9e6:	6121                	addi	sp,sp,64
 9e8:	8082                	ret
 9ea:	7902                	ld	s2,32(sp)
 9ec:	6a42                	ld	s4,16(sp)
 9ee:	6aa2                	ld	s5,8(sp)
 9f0:	6b02                	ld	s6,0(sp)
 9f2:	b7f5                	j	9de <malloc+0xe2>
