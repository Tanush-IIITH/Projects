
user/_init:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:

char *argv[] = { "sh", 0 };

int
main(void)
{
   0:	7179                	addi	sp,sp,-48
   2:	f406                	sd	ra,40(sp)
   4:	f022                	sd	s0,32(sp)
   6:	ec26                	sd	s1,24(sp)
   8:	e84a                	sd	s2,16(sp)
   a:	1800                	addi	s0,sp,48
  int pid, wpid;

  if(open("console", O_RDWR) < 0){
   c:	4589                	li	a1,2
   e:	00001517          	auipc	a0,0x1
  12:	95250513          	addi	a0,a0,-1710 # 960 <malloc+0x100>
  16:	39e000ef          	jal	3b4 <open>
  1a:	04054863          	bltz	a0,6a <main+0x6a>
    mknod("console", CONSOLE, 0);
    open("console", O_RDWR);
  }
  dup(0);  // stdout
  1e:	4501                	li	a0,0
  20:	3cc000ef          	jal	3ec <dup>
  dup(0);  // stderr
  24:	4501                	li	a0,0
  26:	3c6000ef          	jal	3ec <dup>

  if(fork() == 0){
  2a:	342000ef          	jal	36c <fork>
    // If exec fails, exit child
    exit(0);
  }

  for(;;){
    printf("init: starting sh\n");
  2e:	00001917          	auipc	s2,0x1
  32:	95290913          	addi	s2,s2,-1710 # 980 <malloc+0x120>
  if(fork() == 0){
  36:	c931                	beqz	a0,8a <main+0x8a>
    printf("init: starting sh\n");
  38:	854a                	mv	a0,s2
  3a:	772000ef          	jal	7ac <printf>
    pid = fork();
  3e:	32e000ef          	jal	36c <fork>
  42:	84aa                	mv	s1,a0
    if(pid < 0){
  44:	06054263          	bltz	a0,a8 <main+0xa8>
      printf("init: fork failed\n");
      exit(1);
    }
    if(pid == 0){
  48:	c92d                	beqz	a0,ba <main+0xba>
    }

    for(;;){
      // this call to wait() returns if the shell exits,
      // or if a parentless process exits.
      wpid = wait((int *) 0);
  4a:	4501                	li	a0,0
  4c:	330000ef          	jal	37c <wait>
      if(wpid == pid){
  50:	fea484e3          	beq	s1,a0,38 <main+0x38>
        // the shell exited; restart it.
        break;
      } else if(wpid < 0){
  54:	fe055be3          	bgez	a0,4a <main+0x4a>
        printf("init: wait returned an error\n");
  58:	00001517          	auipc	a0,0x1
  5c:	97850513          	addi	a0,a0,-1672 # 9d0 <malloc+0x170>
  60:	74c000ef          	jal	7ac <printf>
        exit(1);
  64:	4505                	li	a0,1
  66:	30e000ef          	jal	374 <exit>
    mknod("console", CONSOLE, 0);
  6a:	4601                	li	a2,0
  6c:	4585                	li	a1,1
  6e:	00001517          	auipc	a0,0x1
  72:	8f250513          	addi	a0,a0,-1806 # 960 <malloc+0x100>
  76:	346000ef          	jal	3bc <mknod>
    open("console", O_RDWR);
  7a:	4589                	li	a1,2
  7c:	00001517          	auipc	a0,0x1
  80:	8e450513          	addi	a0,a0,-1820 # 960 <malloc+0x100>
  84:	330000ef          	jal	3b4 <open>
  88:	bf59                	j	1e <main+0x1e>
    exec("schedulertest", (char*[]){"schedulertest", 0});
  8a:	00001517          	auipc	a0,0x1
  8e:	8de50513          	addi	a0,a0,-1826 # 968 <malloc+0x108>
  92:	fca43823          	sd	a0,-48(s0)
  96:	fc043c23          	sd	zero,-40(s0)
  9a:	fd040593          	addi	a1,s0,-48
  9e:	30e000ef          	jal	3ac <exec>
    exit(0);
  a2:	4501                	li	a0,0
  a4:	2d0000ef          	jal	374 <exit>
      printf("init: fork failed\n");
  a8:	00001517          	auipc	a0,0x1
  ac:	8f050513          	addi	a0,a0,-1808 # 998 <malloc+0x138>
  b0:	6fc000ef          	jal	7ac <printf>
      exit(1);
  b4:	4505                	li	a0,1
  b6:	2be000ef          	jal	374 <exit>
      exec("sh", argv);
  ba:	00001597          	auipc	a1,0x1
  be:	f4658593          	addi	a1,a1,-186 # 1000 <argv>
  c2:	00001517          	auipc	a0,0x1
  c6:	8ee50513          	addi	a0,a0,-1810 # 9b0 <malloc+0x150>
  ca:	2e2000ef          	jal	3ac <exec>
      printf("init: exec sh failed\n");
  ce:	00001517          	auipc	a0,0x1
  d2:	8ea50513          	addi	a0,a0,-1814 # 9b8 <malloc+0x158>
  d6:	6d6000ef          	jal	7ac <printf>
      exit(1);
  da:	4505                	li	a0,1
  dc:	298000ef          	jal	374 <exit>

00000000000000e0 <start>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
start(int argc, char **argv)
{
  e0:	1141                	addi	sp,sp,-16
  e2:	e406                	sd	ra,8(sp)
  e4:	e022                	sd	s0,0(sp)
  e6:	0800                	addi	s0,sp,16
  int r;
  extern int main(int argc, char **argv);
  r = main(argc, argv);
  e8:	f19ff0ef          	jal	0 <main>
  exit(r);
  ec:	288000ef          	jal	374 <exit>

00000000000000f0 <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
  f0:	1141                	addi	sp,sp,-16
  f2:	e422                	sd	s0,8(sp)
  f4:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  f6:	87aa                	mv	a5,a0
  f8:	0585                	addi	a1,a1,1
  fa:	0785                	addi	a5,a5,1
  fc:	fff5c703          	lbu	a4,-1(a1)
 100:	fee78fa3          	sb	a4,-1(a5)
 104:	fb75                	bnez	a4,f8 <strcpy+0x8>
    ;
  return os;
}
 106:	6422                	ld	s0,8(sp)
 108:	0141                	addi	sp,sp,16
 10a:	8082                	ret

000000000000010c <strcmp>:

int
strcmp(const char *p, const char *q)
{
 10c:	1141                	addi	sp,sp,-16
 10e:	e422                	sd	s0,8(sp)
 110:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 112:	00054783          	lbu	a5,0(a0)
 116:	cb91                	beqz	a5,12a <strcmp+0x1e>
 118:	0005c703          	lbu	a4,0(a1)
 11c:	00f71763          	bne	a4,a5,12a <strcmp+0x1e>
    p++, q++;
 120:	0505                	addi	a0,a0,1
 122:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 124:	00054783          	lbu	a5,0(a0)
 128:	fbe5                	bnez	a5,118 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 12a:	0005c503          	lbu	a0,0(a1)
}
 12e:	40a7853b          	subw	a0,a5,a0
 132:	6422                	ld	s0,8(sp)
 134:	0141                	addi	sp,sp,16
 136:	8082                	ret

0000000000000138 <strlen>:

uint
strlen(const char *s)
{
 138:	1141                	addi	sp,sp,-16
 13a:	e422                	sd	s0,8(sp)
 13c:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 13e:	00054783          	lbu	a5,0(a0)
 142:	cf91                	beqz	a5,15e <strlen+0x26>
 144:	0505                	addi	a0,a0,1
 146:	87aa                	mv	a5,a0
 148:	86be                	mv	a3,a5
 14a:	0785                	addi	a5,a5,1
 14c:	fff7c703          	lbu	a4,-1(a5)
 150:	ff65                	bnez	a4,148 <strlen+0x10>
 152:	40a6853b          	subw	a0,a3,a0
 156:	2505                	addiw	a0,a0,1
    ;
  return n;
}
 158:	6422                	ld	s0,8(sp)
 15a:	0141                	addi	sp,sp,16
 15c:	8082                	ret
  for(n = 0; s[n]; n++)
 15e:	4501                	li	a0,0
 160:	bfe5                	j	158 <strlen+0x20>

0000000000000162 <memset>:

void*
memset(void *dst, int c, uint n)
{
 162:	1141                	addi	sp,sp,-16
 164:	e422                	sd	s0,8(sp)
 166:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 168:	ca19                	beqz	a2,17e <memset+0x1c>
 16a:	87aa                	mv	a5,a0
 16c:	1602                	slli	a2,a2,0x20
 16e:	9201                	srli	a2,a2,0x20
 170:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 174:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 178:	0785                	addi	a5,a5,1
 17a:	fee79de3          	bne	a5,a4,174 <memset+0x12>
  }
  return dst;
}
 17e:	6422                	ld	s0,8(sp)
 180:	0141                	addi	sp,sp,16
 182:	8082                	ret

0000000000000184 <strchr>:

char*
strchr(const char *s, char c)
{
 184:	1141                	addi	sp,sp,-16
 186:	e422                	sd	s0,8(sp)
 188:	0800                	addi	s0,sp,16
  for(; *s; s++)
 18a:	00054783          	lbu	a5,0(a0)
 18e:	cb99                	beqz	a5,1a4 <strchr+0x20>
    if(*s == c)
 190:	00f58763          	beq	a1,a5,19e <strchr+0x1a>
  for(; *s; s++)
 194:	0505                	addi	a0,a0,1
 196:	00054783          	lbu	a5,0(a0)
 19a:	fbfd                	bnez	a5,190 <strchr+0xc>
      return (char*)s;
  return 0;
 19c:	4501                	li	a0,0
}
 19e:	6422                	ld	s0,8(sp)
 1a0:	0141                	addi	sp,sp,16
 1a2:	8082                	ret
  return 0;
 1a4:	4501                	li	a0,0
 1a6:	bfe5                	j	19e <strchr+0x1a>

00000000000001a8 <gets>:

char*
gets(char *buf, int max)
{
 1a8:	711d                	addi	sp,sp,-96
 1aa:	ec86                	sd	ra,88(sp)
 1ac:	e8a2                	sd	s0,80(sp)
 1ae:	e4a6                	sd	s1,72(sp)
 1b0:	e0ca                	sd	s2,64(sp)
 1b2:	fc4e                	sd	s3,56(sp)
 1b4:	f852                	sd	s4,48(sp)
 1b6:	f456                	sd	s5,40(sp)
 1b8:	f05a                	sd	s6,32(sp)
 1ba:	ec5e                	sd	s7,24(sp)
 1bc:	1080                	addi	s0,sp,96
 1be:	8baa                	mv	s7,a0
 1c0:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 1c2:	892a                	mv	s2,a0
 1c4:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 1c6:	4aa9                	li	s5,10
 1c8:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 1ca:	89a6                	mv	s3,s1
 1cc:	2485                	addiw	s1,s1,1
 1ce:	0344d663          	bge	s1,s4,1fa <gets+0x52>
    cc = read(0, &c, 1);
 1d2:	4605                	li	a2,1
 1d4:	faf40593          	addi	a1,s0,-81
 1d8:	4501                	li	a0,0
 1da:	1b2000ef          	jal	38c <read>
    if(cc < 1)
 1de:	00a05e63          	blez	a0,1fa <gets+0x52>
    buf[i++] = c;
 1e2:	faf44783          	lbu	a5,-81(s0)
 1e6:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 1ea:	01578763          	beq	a5,s5,1f8 <gets+0x50>
 1ee:	0905                	addi	s2,s2,1
 1f0:	fd679de3          	bne	a5,s6,1ca <gets+0x22>
    buf[i++] = c;
 1f4:	89a6                	mv	s3,s1
 1f6:	a011                	j	1fa <gets+0x52>
 1f8:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 1fa:	99de                	add	s3,s3,s7
 1fc:	00098023          	sb	zero,0(s3)
  return buf;
}
 200:	855e                	mv	a0,s7
 202:	60e6                	ld	ra,88(sp)
 204:	6446                	ld	s0,80(sp)
 206:	64a6                	ld	s1,72(sp)
 208:	6906                	ld	s2,64(sp)
 20a:	79e2                	ld	s3,56(sp)
 20c:	7a42                	ld	s4,48(sp)
 20e:	7aa2                	ld	s5,40(sp)
 210:	7b02                	ld	s6,32(sp)
 212:	6be2                	ld	s7,24(sp)
 214:	6125                	addi	sp,sp,96
 216:	8082                	ret

0000000000000218 <stat>:

int
stat(const char *n, struct stat *st)
{
 218:	1101                	addi	sp,sp,-32
 21a:	ec06                	sd	ra,24(sp)
 21c:	e822                	sd	s0,16(sp)
 21e:	e04a                	sd	s2,0(sp)
 220:	1000                	addi	s0,sp,32
 222:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 224:	4581                	li	a1,0
 226:	18e000ef          	jal	3b4 <open>
  if(fd < 0)
 22a:	02054263          	bltz	a0,24e <stat+0x36>
 22e:	e426                	sd	s1,8(sp)
 230:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 232:	85ca                	mv	a1,s2
 234:	198000ef          	jal	3cc <fstat>
 238:	892a                	mv	s2,a0
  close(fd);
 23a:	8526                	mv	a0,s1
 23c:	160000ef          	jal	39c <close>
  return r;
 240:	64a2                	ld	s1,8(sp)
}
 242:	854a                	mv	a0,s2
 244:	60e2                	ld	ra,24(sp)
 246:	6442                	ld	s0,16(sp)
 248:	6902                	ld	s2,0(sp)
 24a:	6105                	addi	sp,sp,32
 24c:	8082                	ret
    return -1;
 24e:	597d                	li	s2,-1
 250:	bfcd                	j	242 <stat+0x2a>

0000000000000252 <atoi>:

int
atoi(const char *s)
{
 252:	1141                	addi	sp,sp,-16
 254:	e422                	sd	s0,8(sp)
 256:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 258:	00054683          	lbu	a3,0(a0)
 25c:	fd06879b          	addiw	a5,a3,-48
 260:	0ff7f793          	zext.b	a5,a5
 264:	4625                	li	a2,9
 266:	02f66863          	bltu	a2,a5,296 <atoi+0x44>
 26a:	872a                	mv	a4,a0
  n = 0;
 26c:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 26e:	0705                	addi	a4,a4,1
 270:	0025179b          	slliw	a5,a0,0x2
 274:	9fa9                	addw	a5,a5,a0
 276:	0017979b          	slliw	a5,a5,0x1
 27a:	9fb5                	addw	a5,a5,a3
 27c:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 280:	00074683          	lbu	a3,0(a4)
 284:	fd06879b          	addiw	a5,a3,-48
 288:	0ff7f793          	zext.b	a5,a5
 28c:	fef671e3          	bgeu	a2,a5,26e <atoi+0x1c>
  return n;
}
 290:	6422                	ld	s0,8(sp)
 292:	0141                	addi	sp,sp,16
 294:	8082                	ret
  n = 0;
 296:	4501                	li	a0,0
 298:	bfe5                	j	290 <atoi+0x3e>

000000000000029a <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 29a:	1141                	addi	sp,sp,-16
 29c:	e422                	sd	s0,8(sp)
 29e:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 2a0:	02b57463          	bgeu	a0,a1,2c8 <memmove+0x2e>
    while(n-- > 0)
 2a4:	00c05f63          	blez	a2,2c2 <memmove+0x28>
 2a8:	1602                	slli	a2,a2,0x20
 2aa:	9201                	srli	a2,a2,0x20
 2ac:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 2b0:	872a                	mv	a4,a0
      *dst++ = *src++;
 2b2:	0585                	addi	a1,a1,1
 2b4:	0705                	addi	a4,a4,1
 2b6:	fff5c683          	lbu	a3,-1(a1)
 2ba:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 2be:	fef71ae3          	bne	a4,a5,2b2 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 2c2:	6422                	ld	s0,8(sp)
 2c4:	0141                	addi	sp,sp,16
 2c6:	8082                	ret
    dst += n;
 2c8:	00c50733          	add	a4,a0,a2
    src += n;
 2cc:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 2ce:	fec05ae3          	blez	a2,2c2 <memmove+0x28>
 2d2:	fff6079b          	addiw	a5,a2,-1
 2d6:	1782                	slli	a5,a5,0x20
 2d8:	9381                	srli	a5,a5,0x20
 2da:	fff7c793          	not	a5,a5
 2de:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 2e0:	15fd                	addi	a1,a1,-1
 2e2:	177d                	addi	a4,a4,-1
 2e4:	0005c683          	lbu	a3,0(a1)
 2e8:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 2ec:	fee79ae3          	bne	a5,a4,2e0 <memmove+0x46>
 2f0:	bfc9                	j	2c2 <memmove+0x28>

00000000000002f2 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 2f2:	1141                	addi	sp,sp,-16
 2f4:	e422                	sd	s0,8(sp)
 2f6:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 2f8:	ca05                	beqz	a2,328 <memcmp+0x36>
 2fa:	fff6069b          	addiw	a3,a2,-1
 2fe:	1682                	slli	a3,a3,0x20
 300:	9281                	srli	a3,a3,0x20
 302:	0685                	addi	a3,a3,1
 304:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 306:	00054783          	lbu	a5,0(a0)
 30a:	0005c703          	lbu	a4,0(a1)
 30e:	00e79863          	bne	a5,a4,31e <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 312:	0505                	addi	a0,a0,1
    p2++;
 314:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 316:	fed518e3          	bne	a0,a3,306 <memcmp+0x14>
  }
  return 0;
 31a:	4501                	li	a0,0
 31c:	a019                	j	322 <memcmp+0x30>
      return *p1 - *p2;
 31e:	40e7853b          	subw	a0,a5,a4
}
 322:	6422                	ld	s0,8(sp)
 324:	0141                	addi	sp,sp,16
 326:	8082                	ret
  return 0;
 328:	4501                	li	a0,0
 32a:	bfe5                	j	322 <memcmp+0x30>

000000000000032c <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 32c:	1141                	addi	sp,sp,-16
 32e:	e406                	sd	ra,8(sp)
 330:	e022                	sd	s0,0(sp)
 332:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 334:	f67ff0ef          	jal	29a <memmove>
}
 338:	60a2                	ld	ra,8(sp)
 33a:	6402                	ld	s0,0(sp)
 33c:	0141                	addi	sp,sp,16
 33e:	8082                	ret

0000000000000340 <sbrk>:

char *
sbrk(int n) {
 340:	1141                	addi	sp,sp,-16
 342:	e406                	sd	ra,8(sp)
 344:	e022                	sd	s0,0(sp)
 346:	0800                	addi	s0,sp,16
  return sys_sbrk(n, SBRK_EAGER);
 348:	4585                	li	a1,1
 34a:	0b2000ef          	jal	3fc <sys_sbrk>
}
 34e:	60a2                	ld	ra,8(sp)
 350:	6402                	ld	s0,0(sp)
 352:	0141                	addi	sp,sp,16
 354:	8082                	ret

0000000000000356 <sbrklazy>:

char *
sbrklazy(int n) {
 356:	1141                	addi	sp,sp,-16
 358:	e406                	sd	ra,8(sp)
 35a:	e022                	sd	s0,0(sp)
 35c:	0800                	addi	s0,sp,16
  return sys_sbrk(n, SBRK_LAZY);
 35e:	4589                	li	a1,2
 360:	09c000ef          	jal	3fc <sys_sbrk>
}
 364:	60a2                	ld	ra,8(sp)
 366:	6402                	ld	s0,0(sp)
 368:	0141                	addi	sp,sp,16
 36a:	8082                	ret

000000000000036c <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 36c:	4885                	li	a7,1
 ecall
 36e:	00000073          	ecall
 ret
 372:	8082                	ret

0000000000000374 <exit>:
.global exit
exit:
 li a7, SYS_exit
 374:	4889                	li	a7,2
 ecall
 376:	00000073          	ecall
 ret
 37a:	8082                	ret

000000000000037c <wait>:
.global wait
wait:
 li a7, SYS_wait
 37c:	488d                	li	a7,3
 ecall
 37e:	00000073          	ecall
 ret
 382:	8082                	ret

0000000000000384 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 384:	4891                	li	a7,4
 ecall
 386:	00000073          	ecall
 ret
 38a:	8082                	ret

000000000000038c <read>:
.global read
read:
 li a7, SYS_read
 38c:	4895                	li	a7,5
 ecall
 38e:	00000073          	ecall
 ret
 392:	8082                	ret

0000000000000394 <write>:
.global write
write:
 li a7, SYS_write
 394:	48c1                	li	a7,16
 ecall
 396:	00000073          	ecall
 ret
 39a:	8082                	ret

000000000000039c <close>:
.global close
close:
 li a7, SYS_close
 39c:	48d5                	li	a7,21
 ecall
 39e:	00000073          	ecall
 ret
 3a2:	8082                	ret

00000000000003a4 <kill>:
.global kill
kill:
 li a7, SYS_kill
 3a4:	4899                	li	a7,6
 ecall
 3a6:	00000073          	ecall
 ret
 3aa:	8082                	ret

00000000000003ac <exec>:
.global exec
exec:
 li a7, SYS_exec
 3ac:	489d                	li	a7,7
 ecall
 3ae:	00000073          	ecall
 ret
 3b2:	8082                	ret

00000000000003b4 <open>:
.global open
open:
 li a7, SYS_open
 3b4:	48bd                	li	a7,15
 ecall
 3b6:	00000073          	ecall
 ret
 3ba:	8082                	ret

00000000000003bc <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 3bc:	48c5                	li	a7,17
 ecall
 3be:	00000073          	ecall
 ret
 3c2:	8082                	ret

00000000000003c4 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 3c4:	48c9                	li	a7,18
 ecall
 3c6:	00000073          	ecall
 ret
 3ca:	8082                	ret

00000000000003cc <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 3cc:	48a1                	li	a7,8
 ecall
 3ce:	00000073          	ecall
 ret
 3d2:	8082                	ret

00000000000003d4 <link>:
.global link
link:
 li a7, SYS_link
 3d4:	48cd                	li	a7,19
 ecall
 3d6:	00000073          	ecall
 ret
 3da:	8082                	ret

00000000000003dc <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 3dc:	48d1                	li	a7,20
 ecall
 3de:	00000073          	ecall
 ret
 3e2:	8082                	ret

00000000000003e4 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 3e4:	48a5                	li	a7,9
 ecall
 3e6:	00000073          	ecall
 ret
 3ea:	8082                	ret

00000000000003ec <dup>:
.global dup
dup:
 li a7, SYS_dup
 3ec:	48a9                	li	a7,10
 ecall
 3ee:	00000073          	ecall
 ret
 3f2:	8082                	ret

00000000000003f4 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 3f4:	48ad                	li	a7,11
 ecall
 3f6:	00000073          	ecall
 ret
 3fa:	8082                	ret

00000000000003fc <sys_sbrk>:
.global sys_sbrk
sys_sbrk:
 li a7, SYS_sbrk
 3fc:	48b1                	li	a7,12
 ecall
 3fe:	00000073          	ecall
 ret
 402:	8082                	ret

0000000000000404 <pause>:
.global pause
pause:
 li a7, SYS_pause
 404:	48b5                	li	a7,13
 ecall
 406:	00000073          	ecall
 ret
 40a:	8082                	ret

000000000000040c <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 40c:	48b9                	li	a7,14
 ecall
 40e:	00000073          	ecall
 ret
 412:	8082                	ret

0000000000000414 <getreadcount>:
.global getreadcount
getreadcount:
 li a7, SYS_getreadcount
 414:	48d9                	li	a7,22
 ecall
 416:	00000073          	ecall
 ret
 41a:	8082                	ret

000000000000041c <set_nice>:
.global set_nice
set_nice:
 li a7, SYS_set_nice
 41c:	48dd                	li	a7,23
 ecall
 41e:	00000073          	ecall
 ret
 422:	8082                	ret

0000000000000424 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 424:	1101                	addi	sp,sp,-32
 426:	ec06                	sd	ra,24(sp)
 428:	e822                	sd	s0,16(sp)
 42a:	1000                	addi	s0,sp,32
 42c:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 430:	4605                	li	a2,1
 432:	fef40593          	addi	a1,s0,-17
 436:	f5fff0ef          	jal	394 <write>
}
 43a:	60e2                	ld	ra,24(sp)
 43c:	6442                	ld	s0,16(sp)
 43e:	6105                	addi	sp,sp,32
 440:	8082                	ret

0000000000000442 <printint>:

static void
printint(int fd, long long xx, int base, int sgn)
{
 442:	715d                	addi	sp,sp,-80
 444:	e486                	sd	ra,72(sp)
 446:	e0a2                	sd	s0,64(sp)
 448:	f84a                	sd	s2,48(sp)
 44a:	0880                	addi	s0,sp,80
 44c:	892a                	mv	s2,a0
  char buf[20];
  int i, neg;
  unsigned long long x;

  neg = 0;
  if(sgn && xx < 0){
 44e:	c299                	beqz	a3,454 <printint+0x12>
 450:	0805c363          	bltz	a1,4d6 <printint+0x94>
  neg = 0;
 454:	4881                	li	a7,0
 456:	fb840693          	addi	a3,s0,-72
    x = -xx;
  } else {
    x = xx;
  }

  i = 0;
 45a:	4781                	li	a5,0
  do{
    buf[i++] = digits[x % base];
 45c:	00000517          	auipc	a0,0x0
 460:	59c50513          	addi	a0,a0,1436 # 9f8 <digits>
 464:	883e                	mv	a6,a5
 466:	2785                	addiw	a5,a5,1
 468:	02c5f733          	remu	a4,a1,a2
 46c:	972a                	add	a4,a4,a0
 46e:	00074703          	lbu	a4,0(a4)
 472:	00e68023          	sb	a4,0(a3)
  }while((x /= base) != 0);
 476:	872e                	mv	a4,a1
 478:	02c5d5b3          	divu	a1,a1,a2
 47c:	0685                	addi	a3,a3,1
 47e:	fec773e3          	bgeu	a4,a2,464 <printint+0x22>
  if(neg)
 482:	00088b63          	beqz	a7,498 <printint+0x56>
    buf[i++] = '-';
 486:	fd078793          	addi	a5,a5,-48
 48a:	97a2                	add	a5,a5,s0
 48c:	02d00713          	li	a4,45
 490:	fee78423          	sb	a4,-24(a5)
 494:	0028079b          	addiw	a5,a6,2

  while(--i >= 0)
 498:	02f05a63          	blez	a5,4cc <printint+0x8a>
 49c:	fc26                	sd	s1,56(sp)
 49e:	f44e                	sd	s3,40(sp)
 4a0:	fb840713          	addi	a4,s0,-72
 4a4:	00f704b3          	add	s1,a4,a5
 4a8:	fff70993          	addi	s3,a4,-1
 4ac:	99be                	add	s3,s3,a5
 4ae:	37fd                	addiw	a5,a5,-1
 4b0:	1782                	slli	a5,a5,0x20
 4b2:	9381                	srli	a5,a5,0x20
 4b4:	40f989b3          	sub	s3,s3,a5
    putc(fd, buf[i]);
 4b8:	fff4c583          	lbu	a1,-1(s1)
 4bc:	854a                	mv	a0,s2
 4be:	f67ff0ef          	jal	424 <putc>
  while(--i >= 0)
 4c2:	14fd                	addi	s1,s1,-1
 4c4:	ff349ae3          	bne	s1,s3,4b8 <printint+0x76>
 4c8:	74e2                	ld	s1,56(sp)
 4ca:	79a2                	ld	s3,40(sp)
}
 4cc:	60a6                	ld	ra,72(sp)
 4ce:	6406                	ld	s0,64(sp)
 4d0:	7942                	ld	s2,48(sp)
 4d2:	6161                	addi	sp,sp,80
 4d4:	8082                	ret
    x = -xx;
 4d6:	40b005b3          	neg	a1,a1
    neg = 1;
 4da:	4885                	li	a7,1
    x = -xx;
 4dc:	bfad                	j	456 <printint+0x14>

00000000000004de <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %c, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 4de:	711d                	addi	sp,sp,-96
 4e0:	ec86                	sd	ra,88(sp)
 4e2:	e8a2                	sd	s0,80(sp)
 4e4:	e0ca                	sd	s2,64(sp)
 4e6:	1080                	addi	s0,sp,96
  char *s;
  int c0, c1, c2, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 4e8:	0005c903          	lbu	s2,0(a1)
 4ec:	28090663          	beqz	s2,778 <vprintf+0x29a>
 4f0:	e4a6                	sd	s1,72(sp)
 4f2:	fc4e                	sd	s3,56(sp)
 4f4:	f852                	sd	s4,48(sp)
 4f6:	f456                	sd	s5,40(sp)
 4f8:	f05a                	sd	s6,32(sp)
 4fa:	ec5e                	sd	s7,24(sp)
 4fc:	e862                	sd	s8,16(sp)
 4fe:	e466                	sd	s9,8(sp)
 500:	8b2a                	mv	s6,a0
 502:	8a2e                	mv	s4,a1
 504:	8bb2                	mv	s7,a2
  state = 0;
 506:	4981                	li	s3,0
  for(i = 0; fmt[i]; i++){
 508:	4481                	li	s1,0
 50a:	4701                	li	a4,0
      if(c0 == '%'){
        state = '%';
      } else {
        putc(fd, c0);
      }
    } else if(state == '%'){
 50c:	02500a93          	li	s5,37
      c1 = c2 = 0;
      if(c0) c1 = fmt[i+1] & 0xff;
      if(c1) c2 = fmt[i+2] & 0xff;
      if(c0 == 'd'){
 510:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c0 == 'l' && c1 == 'd'){
 514:	06c00c93          	li	s9,108
 518:	a005                	j	538 <vprintf+0x5a>
        putc(fd, c0);
 51a:	85ca                	mv	a1,s2
 51c:	855a                	mv	a0,s6
 51e:	f07ff0ef          	jal	424 <putc>
 522:	a019                	j	528 <vprintf+0x4a>
    } else if(state == '%'){
 524:	03598263          	beq	s3,s5,548 <vprintf+0x6a>
  for(i = 0; fmt[i]; i++){
 528:	2485                	addiw	s1,s1,1
 52a:	8726                	mv	a4,s1
 52c:	009a07b3          	add	a5,s4,s1
 530:	0007c903          	lbu	s2,0(a5)
 534:	22090a63          	beqz	s2,768 <vprintf+0x28a>
    c0 = fmt[i] & 0xff;
 538:	0009079b          	sext.w	a5,s2
    if(state == 0){
 53c:	fe0994e3          	bnez	s3,524 <vprintf+0x46>
      if(c0 == '%'){
 540:	fd579de3          	bne	a5,s5,51a <vprintf+0x3c>
        state = '%';
 544:	89be                	mv	s3,a5
 546:	b7cd                	j	528 <vprintf+0x4a>
      if(c0) c1 = fmt[i+1] & 0xff;
 548:	00ea06b3          	add	a3,s4,a4
 54c:	0016c683          	lbu	a3,1(a3)
      c1 = c2 = 0;
 550:	8636                	mv	a2,a3
      if(c1) c2 = fmt[i+2] & 0xff;
 552:	c681                	beqz	a3,55a <vprintf+0x7c>
 554:	9752                	add	a4,a4,s4
 556:	00274603          	lbu	a2,2(a4)
      if(c0 == 'd'){
 55a:	05878363          	beq	a5,s8,5a0 <vprintf+0xc2>
      } else if(c0 == 'l' && c1 == 'd'){
 55e:	05978d63          	beq	a5,s9,5b8 <vprintf+0xda>
        printint(fd, va_arg(ap, uint64), 10, 1);
        i += 1;
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
        printint(fd, va_arg(ap, uint64), 10, 1);
        i += 2;
      } else if(c0 == 'u'){
 562:	07500713          	li	a4,117
 566:	0ee78763          	beq	a5,a4,654 <vprintf+0x176>
        printint(fd, va_arg(ap, uint64), 10, 0);
        i += 1;
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
        printint(fd, va_arg(ap, uint64), 10, 0);
        i += 2;
      } else if(c0 == 'x'){
 56a:	07800713          	li	a4,120
 56e:	12e78963          	beq	a5,a4,6a0 <vprintf+0x1c2>
        printint(fd, va_arg(ap, uint64), 16, 0);
        i += 1;
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
        printint(fd, va_arg(ap, uint64), 16, 0);
        i += 2;
      } else if(c0 == 'p'){
 572:	07000713          	li	a4,112
 576:	14e78e63          	beq	a5,a4,6d2 <vprintf+0x1f4>
        printptr(fd, va_arg(ap, uint64));
      } else if(c0 == 'c'){
 57a:	06300713          	li	a4,99
 57e:	18e78e63          	beq	a5,a4,71a <vprintf+0x23c>
        putc(fd, va_arg(ap, uint32));
      } else if(c0 == 's'){
 582:	07300713          	li	a4,115
 586:	1ae78463          	beq	a5,a4,72e <vprintf+0x250>
        if((s = va_arg(ap, char*)) == 0)
          s = "(null)";
        for(; *s; s++)
          putc(fd, *s);
      } else if(c0 == '%'){
 58a:	02500713          	li	a4,37
 58e:	04e79563          	bne	a5,a4,5d8 <vprintf+0xfa>
        putc(fd, '%');
 592:	02500593          	li	a1,37
 596:	855a                	mv	a0,s6
 598:	e8dff0ef          	jal	424 <putc>
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c0);
      }

      state = 0;
 59c:	4981                	li	s3,0
 59e:	b769                	j	528 <vprintf+0x4a>
        printint(fd, va_arg(ap, int), 10, 1);
 5a0:	008b8913          	addi	s2,s7,8
 5a4:	4685                	li	a3,1
 5a6:	4629                	li	a2,10
 5a8:	000ba583          	lw	a1,0(s7)
 5ac:	855a                	mv	a0,s6
 5ae:	e95ff0ef          	jal	442 <printint>
 5b2:	8bca                	mv	s7,s2
      state = 0;
 5b4:	4981                	li	s3,0
 5b6:	bf8d                	j	528 <vprintf+0x4a>
      } else if(c0 == 'l' && c1 == 'd'){
 5b8:	06400793          	li	a5,100
 5bc:	02f68963          	beq	a3,a5,5ee <vprintf+0x110>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
 5c0:	06c00793          	li	a5,108
 5c4:	04f68263          	beq	a3,a5,608 <vprintf+0x12a>
      } else if(c0 == 'l' && c1 == 'u'){
 5c8:	07500793          	li	a5,117
 5cc:	0af68063          	beq	a3,a5,66c <vprintf+0x18e>
      } else if(c0 == 'l' && c1 == 'x'){
 5d0:	07800793          	li	a5,120
 5d4:	0ef68263          	beq	a3,a5,6b8 <vprintf+0x1da>
        putc(fd, '%');
 5d8:	02500593          	li	a1,37
 5dc:	855a                	mv	a0,s6
 5de:	e47ff0ef          	jal	424 <putc>
        putc(fd, c0);
 5e2:	85ca                	mv	a1,s2
 5e4:	855a                	mv	a0,s6
 5e6:	e3fff0ef          	jal	424 <putc>
      state = 0;
 5ea:	4981                	li	s3,0
 5ec:	bf35                	j	528 <vprintf+0x4a>
        printint(fd, va_arg(ap, uint64), 10, 1);
 5ee:	008b8913          	addi	s2,s7,8
 5f2:	4685                	li	a3,1
 5f4:	4629                	li	a2,10
 5f6:	000bb583          	ld	a1,0(s7)
 5fa:	855a                	mv	a0,s6
 5fc:	e47ff0ef          	jal	442 <printint>
        i += 1;
 600:	2485                	addiw	s1,s1,1
        printint(fd, va_arg(ap, uint64), 10, 1);
 602:	8bca                	mv	s7,s2
      state = 0;
 604:	4981                	li	s3,0
        i += 1;
 606:	b70d                	j	528 <vprintf+0x4a>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
 608:	06400793          	li	a5,100
 60c:	02f60763          	beq	a2,a5,63a <vprintf+0x15c>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
 610:	07500793          	li	a5,117
 614:	06f60963          	beq	a2,a5,686 <vprintf+0x1a8>
      } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
 618:	07800793          	li	a5,120
 61c:	faf61ee3          	bne	a2,a5,5d8 <vprintf+0xfa>
        printint(fd, va_arg(ap, uint64), 16, 0);
 620:	008b8913          	addi	s2,s7,8
 624:	4681                	li	a3,0
 626:	4641                	li	a2,16
 628:	000bb583          	ld	a1,0(s7)
 62c:	855a                	mv	a0,s6
 62e:	e15ff0ef          	jal	442 <printint>
        i += 2;
 632:	2489                	addiw	s1,s1,2
        printint(fd, va_arg(ap, uint64), 16, 0);
 634:	8bca                	mv	s7,s2
      state = 0;
 636:	4981                	li	s3,0
        i += 2;
 638:	bdc5                	j	528 <vprintf+0x4a>
        printint(fd, va_arg(ap, uint64), 10, 1);
 63a:	008b8913          	addi	s2,s7,8
 63e:	4685                	li	a3,1
 640:	4629                	li	a2,10
 642:	000bb583          	ld	a1,0(s7)
 646:	855a                	mv	a0,s6
 648:	dfbff0ef          	jal	442 <printint>
        i += 2;
 64c:	2489                	addiw	s1,s1,2
        printint(fd, va_arg(ap, uint64), 10, 1);
 64e:	8bca                	mv	s7,s2
      state = 0;
 650:	4981                	li	s3,0
        i += 2;
 652:	bdd9                	j	528 <vprintf+0x4a>
        printint(fd, va_arg(ap, uint32), 10, 0);
 654:	008b8913          	addi	s2,s7,8
 658:	4681                	li	a3,0
 65a:	4629                	li	a2,10
 65c:	000be583          	lwu	a1,0(s7)
 660:	855a                	mv	a0,s6
 662:	de1ff0ef          	jal	442 <printint>
 666:	8bca                	mv	s7,s2
      state = 0;
 668:	4981                	li	s3,0
 66a:	bd7d                	j	528 <vprintf+0x4a>
        printint(fd, va_arg(ap, uint64), 10, 0);
 66c:	008b8913          	addi	s2,s7,8
 670:	4681                	li	a3,0
 672:	4629                	li	a2,10
 674:	000bb583          	ld	a1,0(s7)
 678:	855a                	mv	a0,s6
 67a:	dc9ff0ef          	jal	442 <printint>
        i += 1;
 67e:	2485                	addiw	s1,s1,1
        printint(fd, va_arg(ap, uint64), 10, 0);
 680:	8bca                	mv	s7,s2
      state = 0;
 682:	4981                	li	s3,0
        i += 1;
 684:	b555                	j	528 <vprintf+0x4a>
        printint(fd, va_arg(ap, uint64), 10, 0);
 686:	008b8913          	addi	s2,s7,8
 68a:	4681                	li	a3,0
 68c:	4629                	li	a2,10
 68e:	000bb583          	ld	a1,0(s7)
 692:	855a                	mv	a0,s6
 694:	dafff0ef          	jal	442 <printint>
        i += 2;
 698:	2489                	addiw	s1,s1,2
        printint(fd, va_arg(ap, uint64), 10, 0);
 69a:	8bca                	mv	s7,s2
      state = 0;
 69c:	4981                	li	s3,0
        i += 2;
 69e:	b569                	j	528 <vprintf+0x4a>
        printint(fd, va_arg(ap, uint32), 16, 0);
 6a0:	008b8913          	addi	s2,s7,8
 6a4:	4681                	li	a3,0
 6a6:	4641                	li	a2,16
 6a8:	000be583          	lwu	a1,0(s7)
 6ac:	855a                	mv	a0,s6
 6ae:	d95ff0ef          	jal	442 <printint>
 6b2:	8bca                	mv	s7,s2
      state = 0;
 6b4:	4981                	li	s3,0
 6b6:	bd8d                	j	528 <vprintf+0x4a>
        printint(fd, va_arg(ap, uint64), 16, 0);
 6b8:	008b8913          	addi	s2,s7,8
 6bc:	4681                	li	a3,0
 6be:	4641                	li	a2,16
 6c0:	000bb583          	ld	a1,0(s7)
 6c4:	855a                	mv	a0,s6
 6c6:	d7dff0ef          	jal	442 <printint>
        i += 1;
 6ca:	2485                	addiw	s1,s1,1
        printint(fd, va_arg(ap, uint64), 16, 0);
 6cc:	8bca                	mv	s7,s2
      state = 0;
 6ce:	4981                	li	s3,0
        i += 1;
 6d0:	bda1                	j	528 <vprintf+0x4a>
 6d2:	e06a                	sd	s10,0(sp)
        printptr(fd, va_arg(ap, uint64));
 6d4:	008b8d13          	addi	s10,s7,8
 6d8:	000bb983          	ld	s3,0(s7)
  putc(fd, '0');
 6dc:	03000593          	li	a1,48
 6e0:	855a                	mv	a0,s6
 6e2:	d43ff0ef          	jal	424 <putc>
  putc(fd, 'x');
 6e6:	07800593          	li	a1,120
 6ea:	855a                	mv	a0,s6
 6ec:	d39ff0ef          	jal	424 <putc>
 6f0:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 6f2:	00000b97          	auipc	s7,0x0
 6f6:	306b8b93          	addi	s7,s7,774 # 9f8 <digits>
 6fa:	03c9d793          	srli	a5,s3,0x3c
 6fe:	97de                	add	a5,a5,s7
 700:	0007c583          	lbu	a1,0(a5)
 704:	855a                	mv	a0,s6
 706:	d1fff0ef          	jal	424 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 70a:	0992                	slli	s3,s3,0x4
 70c:	397d                	addiw	s2,s2,-1
 70e:	fe0916e3          	bnez	s2,6fa <vprintf+0x21c>
        printptr(fd, va_arg(ap, uint64));
 712:	8bea                	mv	s7,s10
      state = 0;
 714:	4981                	li	s3,0
 716:	6d02                	ld	s10,0(sp)
 718:	bd01                	j	528 <vprintf+0x4a>
        putc(fd, va_arg(ap, uint32));
 71a:	008b8913          	addi	s2,s7,8
 71e:	000bc583          	lbu	a1,0(s7)
 722:	855a                	mv	a0,s6
 724:	d01ff0ef          	jal	424 <putc>
 728:	8bca                	mv	s7,s2
      state = 0;
 72a:	4981                	li	s3,0
 72c:	bbf5                	j	528 <vprintf+0x4a>
        if((s = va_arg(ap, char*)) == 0)
 72e:	008b8993          	addi	s3,s7,8
 732:	000bb903          	ld	s2,0(s7)
 736:	00090f63          	beqz	s2,754 <vprintf+0x276>
        for(; *s; s++)
 73a:	00094583          	lbu	a1,0(s2)
 73e:	c195                	beqz	a1,762 <vprintf+0x284>
          putc(fd, *s);
 740:	855a                	mv	a0,s6
 742:	ce3ff0ef          	jal	424 <putc>
        for(; *s; s++)
 746:	0905                	addi	s2,s2,1
 748:	00094583          	lbu	a1,0(s2)
 74c:	f9f5                	bnez	a1,740 <vprintf+0x262>
        if((s = va_arg(ap, char*)) == 0)
 74e:	8bce                	mv	s7,s3
      state = 0;
 750:	4981                	li	s3,0
 752:	bbd9                	j	528 <vprintf+0x4a>
          s = "(null)";
 754:	00000917          	auipc	s2,0x0
 758:	29c90913          	addi	s2,s2,668 # 9f0 <malloc+0x190>
        for(; *s; s++)
 75c:	02800593          	li	a1,40
 760:	b7c5                	j	740 <vprintf+0x262>
        if((s = va_arg(ap, char*)) == 0)
 762:	8bce                	mv	s7,s3
      state = 0;
 764:	4981                	li	s3,0
 766:	b3c9                	j	528 <vprintf+0x4a>
 768:	64a6                	ld	s1,72(sp)
 76a:	79e2                	ld	s3,56(sp)
 76c:	7a42                	ld	s4,48(sp)
 76e:	7aa2                	ld	s5,40(sp)
 770:	7b02                	ld	s6,32(sp)
 772:	6be2                	ld	s7,24(sp)
 774:	6c42                	ld	s8,16(sp)
 776:	6ca2                	ld	s9,8(sp)
    }
  }
}
 778:	60e6                	ld	ra,88(sp)
 77a:	6446                	ld	s0,80(sp)
 77c:	6906                	ld	s2,64(sp)
 77e:	6125                	addi	sp,sp,96
 780:	8082                	ret

0000000000000782 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 782:	715d                	addi	sp,sp,-80
 784:	ec06                	sd	ra,24(sp)
 786:	e822                	sd	s0,16(sp)
 788:	1000                	addi	s0,sp,32
 78a:	e010                	sd	a2,0(s0)
 78c:	e414                	sd	a3,8(s0)
 78e:	e818                	sd	a4,16(s0)
 790:	ec1c                	sd	a5,24(s0)
 792:	03043023          	sd	a6,32(s0)
 796:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 79a:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 79e:	8622                	mv	a2,s0
 7a0:	d3fff0ef          	jal	4de <vprintf>
}
 7a4:	60e2                	ld	ra,24(sp)
 7a6:	6442                	ld	s0,16(sp)
 7a8:	6161                	addi	sp,sp,80
 7aa:	8082                	ret

00000000000007ac <printf>:

void
printf(const char *fmt, ...)
{
 7ac:	711d                	addi	sp,sp,-96
 7ae:	ec06                	sd	ra,24(sp)
 7b0:	e822                	sd	s0,16(sp)
 7b2:	1000                	addi	s0,sp,32
 7b4:	e40c                	sd	a1,8(s0)
 7b6:	e810                	sd	a2,16(s0)
 7b8:	ec14                	sd	a3,24(s0)
 7ba:	f018                	sd	a4,32(s0)
 7bc:	f41c                	sd	a5,40(s0)
 7be:	03043823          	sd	a6,48(s0)
 7c2:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 7c6:	00840613          	addi	a2,s0,8
 7ca:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 7ce:	85aa                	mv	a1,a0
 7d0:	4505                	li	a0,1
 7d2:	d0dff0ef          	jal	4de <vprintf>
}
 7d6:	60e2                	ld	ra,24(sp)
 7d8:	6442                	ld	s0,16(sp)
 7da:	6125                	addi	sp,sp,96
 7dc:	8082                	ret

00000000000007de <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 7de:	1141                	addi	sp,sp,-16
 7e0:	e422                	sd	s0,8(sp)
 7e2:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 7e4:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 7e8:	00001797          	auipc	a5,0x1
 7ec:	8287b783          	ld	a5,-2008(a5) # 1010 <freep>
 7f0:	a02d                	j	81a <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 7f2:	4618                	lw	a4,8(a2)
 7f4:	9f2d                	addw	a4,a4,a1
 7f6:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 7fa:	6398                	ld	a4,0(a5)
 7fc:	6310                	ld	a2,0(a4)
 7fe:	a83d                	j	83c <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 800:	ff852703          	lw	a4,-8(a0)
 804:	9f31                	addw	a4,a4,a2
 806:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 808:	ff053683          	ld	a3,-16(a0)
 80c:	a091                	j	850 <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 80e:	6398                	ld	a4,0(a5)
 810:	00e7e463          	bltu	a5,a4,818 <free+0x3a>
 814:	00e6ea63          	bltu	a3,a4,828 <free+0x4a>
{
 818:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 81a:	fed7fae3          	bgeu	a5,a3,80e <free+0x30>
 81e:	6398                	ld	a4,0(a5)
 820:	00e6e463          	bltu	a3,a4,828 <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 824:	fee7eae3          	bltu	a5,a4,818 <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 828:	ff852583          	lw	a1,-8(a0)
 82c:	6390                	ld	a2,0(a5)
 82e:	02059813          	slli	a6,a1,0x20
 832:	01c85713          	srli	a4,a6,0x1c
 836:	9736                	add	a4,a4,a3
 838:	fae60de3          	beq	a2,a4,7f2 <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 83c:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 840:	4790                	lw	a2,8(a5)
 842:	02061593          	slli	a1,a2,0x20
 846:	01c5d713          	srli	a4,a1,0x1c
 84a:	973e                	add	a4,a4,a5
 84c:	fae68ae3          	beq	a3,a4,800 <free+0x22>
    p->s.ptr = bp->s.ptr;
 850:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 852:	00000717          	auipc	a4,0x0
 856:	7af73f23          	sd	a5,1982(a4) # 1010 <freep>
}
 85a:	6422                	ld	s0,8(sp)
 85c:	0141                	addi	sp,sp,16
 85e:	8082                	ret

0000000000000860 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 860:	7139                	addi	sp,sp,-64
 862:	fc06                	sd	ra,56(sp)
 864:	f822                	sd	s0,48(sp)
 866:	f426                	sd	s1,40(sp)
 868:	ec4e                	sd	s3,24(sp)
 86a:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 86c:	02051493          	slli	s1,a0,0x20
 870:	9081                	srli	s1,s1,0x20
 872:	04bd                	addi	s1,s1,15
 874:	8091                	srli	s1,s1,0x4
 876:	0014899b          	addiw	s3,s1,1
 87a:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 87c:	00000517          	auipc	a0,0x0
 880:	79453503          	ld	a0,1940(a0) # 1010 <freep>
 884:	c915                	beqz	a0,8b8 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 886:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 888:	4798                	lw	a4,8(a5)
 88a:	08977a63          	bgeu	a4,s1,91e <malloc+0xbe>
 88e:	f04a                	sd	s2,32(sp)
 890:	e852                	sd	s4,16(sp)
 892:	e456                	sd	s5,8(sp)
 894:	e05a                	sd	s6,0(sp)
  if(nu < 4096)
 896:	8a4e                	mv	s4,s3
 898:	0009871b          	sext.w	a4,s3
 89c:	6685                	lui	a3,0x1
 89e:	00d77363          	bgeu	a4,a3,8a4 <malloc+0x44>
 8a2:	6a05                	lui	s4,0x1
 8a4:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 8a8:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 8ac:	00000917          	auipc	s2,0x0
 8b0:	76490913          	addi	s2,s2,1892 # 1010 <freep>
  if(p == SBRK_ERROR)
 8b4:	5afd                	li	s5,-1
 8b6:	a081                	j	8f6 <malloc+0x96>
 8b8:	f04a                	sd	s2,32(sp)
 8ba:	e852                	sd	s4,16(sp)
 8bc:	e456                	sd	s5,8(sp)
 8be:	e05a                	sd	s6,0(sp)
    base.s.ptr = freep = prevp = &base;
 8c0:	00000797          	auipc	a5,0x0
 8c4:	76078793          	addi	a5,a5,1888 # 1020 <base>
 8c8:	00000717          	auipc	a4,0x0
 8cc:	74f73423          	sd	a5,1864(a4) # 1010 <freep>
 8d0:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 8d2:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 8d6:	b7c1                	j	896 <malloc+0x36>
        prevp->s.ptr = p->s.ptr;
 8d8:	6398                	ld	a4,0(a5)
 8da:	e118                	sd	a4,0(a0)
 8dc:	a8a9                	j	936 <malloc+0xd6>
  hp->s.size = nu;
 8de:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 8e2:	0541                	addi	a0,a0,16
 8e4:	efbff0ef          	jal	7de <free>
  return freep;
 8e8:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 8ec:	c12d                	beqz	a0,94e <malloc+0xee>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 8ee:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 8f0:	4798                	lw	a4,8(a5)
 8f2:	02977263          	bgeu	a4,s1,916 <malloc+0xb6>
    if(p == freep)
 8f6:	00093703          	ld	a4,0(s2)
 8fa:	853e                	mv	a0,a5
 8fc:	fef719e3          	bne	a4,a5,8ee <malloc+0x8e>
  p = sbrk(nu * sizeof(Header));
 900:	8552                	mv	a0,s4
 902:	a3fff0ef          	jal	340 <sbrk>
  if(p == SBRK_ERROR)
 906:	fd551ce3          	bne	a0,s5,8de <malloc+0x7e>
        return 0;
 90a:	4501                	li	a0,0
 90c:	7902                	ld	s2,32(sp)
 90e:	6a42                	ld	s4,16(sp)
 910:	6aa2                	ld	s5,8(sp)
 912:	6b02                	ld	s6,0(sp)
 914:	a03d                	j	942 <malloc+0xe2>
 916:	7902                	ld	s2,32(sp)
 918:	6a42                	ld	s4,16(sp)
 91a:	6aa2                	ld	s5,8(sp)
 91c:	6b02                	ld	s6,0(sp)
      if(p->s.size == nunits)
 91e:	fae48de3          	beq	s1,a4,8d8 <malloc+0x78>
        p->s.size -= nunits;
 922:	4137073b          	subw	a4,a4,s3
 926:	c798                	sw	a4,8(a5)
        p += p->s.size;
 928:	02071693          	slli	a3,a4,0x20
 92c:	01c6d713          	srli	a4,a3,0x1c
 930:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 932:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 936:	00000717          	auipc	a4,0x0
 93a:	6ca73d23          	sd	a0,1754(a4) # 1010 <freep>
      return (void*)(p + 1);
 93e:	01078513          	addi	a0,a5,16
  }
}
 942:	70e2                	ld	ra,56(sp)
 944:	7442                	ld	s0,48(sp)
 946:	74a2                	ld	s1,40(sp)
 948:	69e2                	ld	s3,24(sp)
 94a:	6121                	addi	sp,sp,64
 94c:	8082                	ret
 94e:	7902                	ld	s2,32(sp)
 950:	6a42                	ld	s4,16(sp)
 952:	6aa2                	ld	s5,8(sp)
 954:	6b02                	ld	s6,0(sp)
 956:	b7f5                	j	942 <malloc+0xe2>
