
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
_entry:
        # set up a stack for C.
        # stack0 is declared in start.c,
        # with a 4096-byte stack per CPU.
        # sp = stack0 + ((hartid + 1) * 4096)
        la sp, stack0
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	3b813103          	ld	sp,952(sp) # 8000a3b8 <_GLOBAL_OFFSET_TABLE_+0x8>
        li a0, 1024*4
    80000008:	6505                	lui	a0,0x1
        csrr a1, mhartid
    8000000a:	f14025f3          	csrr	a1,mhartid
        addi a1, a1, 1
    8000000e:	0585                	addi	a1,a1,1
        mul a0, a0, a1
    80000010:	02b50533          	mul	a0,a0,a1
        add sp, sp, a0
    80000014:	912a                	add	sp,sp,a0
        # jump to start() in start.c
        call start
    80000016:	04a000ef          	jal	80000060 <start>

000000008000001a <spin>:
spin:
        j spin
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
}

// ask each hart to generate timer interrupts.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
#define MIE_STIE (1L << 5)  // supervisor timer
static inline uint64
r_mie()
{
  uint64 x;
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000022:	304027f3          	csrr	a5,mie
  // enable supervisor-mode timer interrupts.
  w_mie(r_mie() | MIE_STIE);
    80000026:	0207e793          	ori	a5,a5,32
}

static inline void 
w_mie(uint64 x)
{
  asm volatile("csrw mie, %0" : : "r" (x));
    8000002a:	30479073          	csrw	mie,a5
static inline uint64
r_menvcfg()
{
  uint64 x;
  // asm volatile("csrr %0, menvcfg" : "=r" (x) );
  asm volatile("csrr %0, 0x30a" : "=r" (x) );
    8000002e:	30a027f3          	csrr	a5,0x30a
  
  // enable the sstc extension (i.e. stimecmp).
  w_menvcfg(r_menvcfg() | (1L << 63)); 
    80000032:	577d                	li	a4,-1
    80000034:	177e                	slli	a4,a4,0x3f
    80000036:	8fd9                	or	a5,a5,a4

static inline void 
w_menvcfg(uint64 x)
{
  // asm volatile("csrw menvcfg, %0" : : "r" (x));
  asm volatile("csrw 0x30a, %0" : : "r" (x));
    80000038:	30a79073          	csrw	0x30a,a5

static inline uint64
r_mcounteren()
{
  uint64 x;
  asm volatile("csrr %0, mcounteren" : "=r" (x) );
    8000003c:	306027f3          	csrr	a5,mcounteren
  
  // allow supervisor to use stimecmp and time.
  w_mcounteren(r_mcounteren() | 2);
    80000040:	0027e793          	ori	a5,a5,2
  asm volatile("csrw mcounteren, %0" : : "r" (x));
    80000044:	30679073          	csrw	mcounteren,a5
// machine-mode cycle counter
static inline uint64
r_time()
{
  uint64 x;
  asm volatile("csrr %0, time" : "=r" (x) );
    80000048:	c01027f3          	rdtime	a5
  
  // ask for the very first timer interrupt.
  w_stimecmp(r_time() + 1000000);
    8000004c:	000f4737          	lui	a4,0xf4
    80000050:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80000054:	97ba                	add	a5,a5,a4
  asm volatile("csrw 0x14d, %0" : : "r" (x));
    80000056:	14d79073          	csrw	stimecmp,a5
}
    8000005a:	6422                	ld	s0,8(sp)
    8000005c:	0141                	addi	sp,sp,16
    8000005e:	8082                	ret

0000000080000060 <start>:
{
    80000060:	1141                	addi	sp,sp,-16
    80000062:	e406                	sd	ra,8(sp)
    80000064:	e022                	sd	s0,0(sp)
    80000066:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000068:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000006c:	7779                	lui	a4,0xffffe
    8000006e:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffda2a7>
    80000072:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    80000074:	6705                	lui	a4,0x1
    80000076:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    8000007a:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    8000007c:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    80000080:	00001797          	auipc	a5,0x1
    80000084:	dbc78793          	addi	a5,a5,-580 # 80000e3c <main>
    80000088:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    8000008c:	4781                	li	a5,0
    8000008e:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    80000092:	67c1                	lui	a5,0x10
    80000094:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    80000096:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    8000009a:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    8000009e:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE);
    800000a2:	2207e793          	ori	a5,a5,544
  asm volatile("csrw sie, %0" : : "r" (x));
    800000a6:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000aa:	57fd                	li	a5,-1
    800000ac:	83a9                	srli	a5,a5,0xa
    800000ae:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000b2:	47bd                	li	a5,15
    800000b4:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000b8:	f65ff0ef          	jal	8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000bc:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000c0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000c2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000c4:	30200073          	mret
}
    800000c8:	60a2                	ld	ra,8(sp)
    800000ca:	6402                	ld	s0,0(sp)
    800000cc:	0141                	addi	sp,sp,16
    800000ce:	8082                	ret

00000000800000d0 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000d0:	7119                	addi	sp,sp,-128
    800000d2:	fc86                	sd	ra,120(sp)
    800000d4:	f8a2                	sd	s0,112(sp)
    800000d6:	f4a6                	sd	s1,104(sp)
    800000d8:	0100                	addi	s0,sp,128
  char buf[32];
  int i = 0;

  while(i < n){
    800000da:	06c05a63          	blez	a2,8000014e <consolewrite+0x7e>
    800000de:	f0ca                	sd	s2,96(sp)
    800000e0:	ecce                	sd	s3,88(sp)
    800000e2:	e8d2                	sd	s4,80(sp)
    800000e4:	e4d6                	sd	s5,72(sp)
    800000e6:	e0da                	sd	s6,64(sp)
    800000e8:	fc5e                	sd	s7,56(sp)
    800000ea:	f862                	sd	s8,48(sp)
    800000ec:	f466                	sd	s9,40(sp)
    800000ee:	8aaa                	mv	s5,a0
    800000f0:	8b2e                	mv	s6,a1
    800000f2:	8a32                	mv	s4,a2
  int i = 0;
    800000f4:	4481                	li	s1,0
    int nn = sizeof(buf);
    if(nn > n - i)
    800000f6:	02000c13          	li	s8,32
    800000fa:	02000c93          	li	s9,32
      nn = n - i;
    if(either_copyin(buf, user_src, src+i, nn) == -1)
    800000fe:	5bfd                	li	s7,-1
    80000100:	a035                	j	8000012c <consolewrite+0x5c>
    if(nn > n - i)
    80000102:	0009099b          	sext.w	s3,s2
    if(either_copyin(buf, user_src, src+i, nn) == -1)
    80000106:	86ce                	mv	a3,s3
    80000108:	01648633          	add	a2,s1,s6
    8000010c:	85d6                	mv	a1,s5
    8000010e:	f8040513          	addi	a0,s0,-128
    80000112:	422020ef          	jal	80002534 <either_copyin>
    80000116:	03750e63          	beq	a0,s7,80000152 <consolewrite+0x82>
      break;
    uartwrite(buf, nn);
    8000011a:	85ce                	mv	a1,s3
    8000011c:	f8040513          	addi	a0,s0,-128
    80000120:	778000ef          	jal	80000898 <uartwrite>
    i += nn;
    80000124:	009904bb          	addw	s1,s2,s1
  while(i < n){
    80000128:	0144da63          	bge	s1,s4,8000013c <consolewrite+0x6c>
    if(nn > n - i)
    8000012c:	409a093b          	subw	s2,s4,s1
    80000130:	0009079b          	sext.w	a5,s2
    80000134:	fcfc57e3          	bge	s8,a5,80000102 <consolewrite+0x32>
    80000138:	8966                	mv	s2,s9
    8000013a:	b7e1                	j	80000102 <consolewrite+0x32>
    8000013c:	7906                	ld	s2,96(sp)
    8000013e:	69e6                	ld	s3,88(sp)
    80000140:	6a46                	ld	s4,80(sp)
    80000142:	6aa6                	ld	s5,72(sp)
    80000144:	6b06                	ld	s6,64(sp)
    80000146:	7be2                	ld	s7,56(sp)
    80000148:	7c42                	ld	s8,48(sp)
    8000014a:	7ca2                	ld	s9,40(sp)
    8000014c:	a819                	j	80000162 <consolewrite+0x92>
  int i = 0;
    8000014e:	4481                	li	s1,0
    80000150:	a809                	j	80000162 <consolewrite+0x92>
    80000152:	7906                	ld	s2,96(sp)
    80000154:	69e6                	ld	s3,88(sp)
    80000156:	6a46                	ld	s4,80(sp)
    80000158:	6aa6                	ld	s5,72(sp)
    8000015a:	6b06                	ld	s6,64(sp)
    8000015c:	7be2                	ld	s7,56(sp)
    8000015e:	7c42                	ld	s8,48(sp)
    80000160:	7ca2                	ld	s9,40(sp)
  }

  return i;
}
    80000162:	8526                	mv	a0,s1
    80000164:	70e6                	ld	ra,120(sp)
    80000166:	7446                	ld	s0,112(sp)
    80000168:	74a6                	ld	s1,104(sp)
    8000016a:	6109                	addi	sp,sp,128
    8000016c:	8082                	ret

000000008000016e <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    8000016e:	711d                	addi	sp,sp,-96
    80000170:	ec86                	sd	ra,88(sp)
    80000172:	e8a2                	sd	s0,80(sp)
    80000174:	e4a6                	sd	s1,72(sp)
    80000176:	e0ca                	sd	s2,64(sp)
    80000178:	fc4e                	sd	s3,56(sp)
    8000017a:	f852                	sd	s4,48(sp)
    8000017c:	f456                	sd	s5,40(sp)
    8000017e:	f05a                	sd	s6,32(sp)
    80000180:	1080                	addi	s0,sp,96
    80000182:	8aaa                	mv	s5,a0
    80000184:	8a2e                	mv	s4,a1
    80000186:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018c:	00012517          	auipc	a0,0x12
    80000190:	29450513          	addi	a0,a0,660 # 80012420 <cons>
    80000194:	23b000ef          	jal	80000bce <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    80000198:	00012497          	auipc	s1,0x12
    8000019c:	28848493          	addi	s1,s1,648 # 80012420 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a0:	00012917          	auipc	s2,0x12
    800001a4:	31890913          	addi	s2,s2,792 # 800124b8 <cons+0x98>
  while(n > 0){
    800001a8:	0b305d63          	blez	s3,80000262 <consoleread+0xf4>
    while(cons.r == cons.w){
    800001ac:	0984a783          	lw	a5,152(s1)
    800001b0:	09c4a703          	lw	a4,156(s1)
    800001b4:	0af71263          	bne	a4,a5,80000258 <consoleread+0xea>
      if(killed(myproc())){
    800001b8:	756010ef          	jal	8000190e <myproc>
    800001bc:	20a020ef          	jal	800023c6 <killed>
    800001c0:	e12d                	bnez	a0,80000222 <consoleread+0xb4>
      sleep(&cons.r, &cons.lock);
    800001c2:	85a6                	mv	a1,s1
    800001c4:	854a                	mv	a0,s2
    800001c6:	73f010ef          	jal	80002104 <sleep>
    while(cons.r == cons.w){
    800001ca:	0984a783          	lw	a5,152(s1)
    800001ce:	09c4a703          	lw	a4,156(s1)
    800001d2:	fef703e3          	beq	a4,a5,800001b8 <consoleread+0x4a>
    800001d6:	ec5e                	sd	s7,24(sp)
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001d8:	00012717          	auipc	a4,0x12
    800001dc:	24870713          	addi	a4,a4,584 # 80012420 <cons>
    800001e0:	0017869b          	addiw	a3,a5,1
    800001e4:	08d72c23          	sw	a3,152(a4)
    800001e8:	07f7f693          	andi	a3,a5,127
    800001ec:	9736                	add	a4,a4,a3
    800001ee:	01874703          	lbu	a4,24(a4)
    800001f2:	00070b9b          	sext.w	s7,a4

    if(c == C('D')){  // end-of-file
    800001f6:	4691                	li	a3,4
    800001f8:	04db8663          	beq	s7,a3,80000244 <consoleread+0xd6>
      }
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    800001fc:	fae407a3          	sb	a4,-81(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000200:	4685                	li	a3,1
    80000202:	faf40613          	addi	a2,s0,-81
    80000206:	85d2                	mv	a1,s4
    80000208:	8556                	mv	a0,s5
    8000020a:	2e0020ef          	jal	800024ea <either_copyout>
    8000020e:	57fd                	li	a5,-1
    80000210:	04f50863          	beq	a0,a5,80000260 <consoleread+0xf2>
      break;

    dst++;
    80000214:	0a05                	addi	s4,s4,1
    --n;
    80000216:	39fd                	addiw	s3,s3,-1

    if(c == '\n'){
    80000218:	47a9                	li	a5,10
    8000021a:	04fb8d63          	beq	s7,a5,80000274 <consoleread+0x106>
    8000021e:	6be2                	ld	s7,24(sp)
    80000220:	b761                	j	800001a8 <consoleread+0x3a>
        release(&cons.lock);
    80000222:	00012517          	auipc	a0,0x12
    80000226:	1fe50513          	addi	a0,a0,510 # 80012420 <cons>
    8000022a:	23d000ef          	jal	80000c66 <release>
        return -1;
    8000022e:	557d                	li	a0,-1
    }
  }
  release(&cons.lock);

  return target - n;
}
    80000230:	60e6                	ld	ra,88(sp)
    80000232:	6446                	ld	s0,80(sp)
    80000234:	64a6                	ld	s1,72(sp)
    80000236:	6906                	ld	s2,64(sp)
    80000238:	79e2                	ld	s3,56(sp)
    8000023a:	7a42                	ld	s4,48(sp)
    8000023c:	7aa2                	ld	s5,40(sp)
    8000023e:	7b02                	ld	s6,32(sp)
    80000240:	6125                	addi	sp,sp,96
    80000242:	8082                	ret
      if(n < target){
    80000244:	0009871b          	sext.w	a4,s3
    80000248:	01677a63          	bgeu	a4,s6,8000025c <consoleread+0xee>
        cons.r--;
    8000024c:	00012717          	auipc	a4,0x12
    80000250:	26f72623          	sw	a5,620(a4) # 800124b8 <cons+0x98>
    80000254:	6be2                	ld	s7,24(sp)
    80000256:	a031                	j	80000262 <consoleread+0xf4>
    80000258:	ec5e                	sd	s7,24(sp)
    8000025a:	bfbd                	j	800001d8 <consoleread+0x6a>
    8000025c:	6be2                	ld	s7,24(sp)
    8000025e:	a011                	j	80000262 <consoleread+0xf4>
    80000260:	6be2                	ld	s7,24(sp)
  release(&cons.lock);
    80000262:	00012517          	auipc	a0,0x12
    80000266:	1be50513          	addi	a0,a0,446 # 80012420 <cons>
    8000026a:	1fd000ef          	jal	80000c66 <release>
  return target - n;
    8000026e:	413b053b          	subw	a0,s6,s3
    80000272:	bf7d                	j	80000230 <consoleread+0xc2>
    80000274:	6be2                	ld	s7,24(sp)
    80000276:	b7f5                	j	80000262 <consoleread+0xf4>

0000000080000278 <consputc>:
{
    80000278:	1141                	addi	sp,sp,-16
    8000027a:	e406                	sd	ra,8(sp)
    8000027c:	e022                	sd	s0,0(sp)
    8000027e:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000280:	10000793          	li	a5,256
    80000284:	00f50863          	beq	a0,a5,80000294 <consputc+0x1c>
    uartputc_sync(c);
    80000288:	6a4000ef          	jal	8000092c <uartputc_sync>
}
    8000028c:	60a2                	ld	ra,8(sp)
    8000028e:	6402                	ld	s0,0(sp)
    80000290:	0141                	addi	sp,sp,16
    80000292:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000294:	4521                	li	a0,8
    80000296:	696000ef          	jal	8000092c <uartputc_sync>
    8000029a:	02000513          	li	a0,32
    8000029e:	68e000ef          	jal	8000092c <uartputc_sync>
    800002a2:	4521                	li	a0,8
    800002a4:	688000ef          	jal	8000092c <uartputc_sync>
    800002a8:	b7d5                	j	8000028c <consputc+0x14>

00000000800002aa <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002aa:	1101                	addi	sp,sp,-32
    800002ac:	ec06                	sd	ra,24(sp)
    800002ae:	e822                	sd	s0,16(sp)
    800002b0:	e426                	sd	s1,8(sp)
    800002b2:	1000                	addi	s0,sp,32
    800002b4:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002b6:	00012517          	auipc	a0,0x12
    800002ba:	16a50513          	addi	a0,a0,362 # 80012420 <cons>
    800002be:	111000ef          	jal	80000bce <acquire>

  switch(c){
    800002c2:	47d5                	li	a5,21
    800002c4:	08f48f63          	beq	s1,a5,80000362 <consoleintr+0xb8>
    800002c8:	0297c563          	blt	a5,s1,800002f2 <consoleintr+0x48>
    800002cc:	47a1                	li	a5,8
    800002ce:	0ef48463          	beq	s1,a5,800003b6 <consoleintr+0x10c>
    800002d2:	47c1                	li	a5,16
    800002d4:	10f49563          	bne	s1,a5,800003de <consoleintr+0x134>
  case C('P'):  // Print process list.
    procdump();
    800002d8:	2a6020ef          	jal	8000257e <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002dc:	00012517          	auipc	a0,0x12
    800002e0:	14450513          	addi	a0,a0,324 # 80012420 <cons>
    800002e4:	183000ef          	jal	80000c66 <release>
}
    800002e8:	60e2                	ld	ra,24(sp)
    800002ea:	6442                	ld	s0,16(sp)
    800002ec:	64a2                	ld	s1,8(sp)
    800002ee:	6105                	addi	sp,sp,32
    800002f0:	8082                	ret
  switch(c){
    800002f2:	07f00793          	li	a5,127
    800002f6:	0cf48063          	beq	s1,a5,800003b6 <consoleintr+0x10c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    800002fa:	00012717          	auipc	a4,0x12
    800002fe:	12670713          	addi	a4,a4,294 # 80012420 <cons>
    80000302:	0a072783          	lw	a5,160(a4)
    80000306:	09872703          	lw	a4,152(a4)
    8000030a:	9f99                	subw	a5,a5,a4
    8000030c:	07f00713          	li	a4,127
    80000310:	fcf766e3          	bltu	a4,a5,800002dc <consoleintr+0x32>
      c = (c == '\r') ? '\n' : c;
    80000314:	47b5                	li	a5,13
    80000316:	0cf48763          	beq	s1,a5,800003e4 <consoleintr+0x13a>
      consputc(c);
    8000031a:	8526                	mv	a0,s1
    8000031c:	f5dff0ef          	jal	80000278 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000320:	00012797          	auipc	a5,0x12
    80000324:	10078793          	addi	a5,a5,256 # 80012420 <cons>
    80000328:	0a07a683          	lw	a3,160(a5)
    8000032c:	0016871b          	addiw	a4,a3,1
    80000330:	0007061b          	sext.w	a2,a4
    80000334:	0ae7a023          	sw	a4,160(a5)
    80000338:	07f6f693          	andi	a3,a3,127
    8000033c:	97b6                	add	a5,a5,a3
    8000033e:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    80000342:	47a9                	li	a5,10
    80000344:	0cf48563          	beq	s1,a5,8000040e <consoleintr+0x164>
    80000348:	4791                	li	a5,4
    8000034a:	0cf48263          	beq	s1,a5,8000040e <consoleintr+0x164>
    8000034e:	00012797          	auipc	a5,0x12
    80000352:	16a7a783          	lw	a5,362(a5) # 800124b8 <cons+0x98>
    80000356:	9f1d                	subw	a4,a4,a5
    80000358:	08000793          	li	a5,128
    8000035c:	f8f710e3          	bne	a4,a5,800002dc <consoleintr+0x32>
    80000360:	a07d                	j	8000040e <consoleintr+0x164>
    80000362:	e04a                	sd	s2,0(sp)
    while(cons.e != cons.w &&
    80000364:	00012717          	auipc	a4,0x12
    80000368:	0bc70713          	addi	a4,a4,188 # 80012420 <cons>
    8000036c:	0a072783          	lw	a5,160(a4)
    80000370:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000374:	00012497          	auipc	s1,0x12
    80000378:	0ac48493          	addi	s1,s1,172 # 80012420 <cons>
    while(cons.e != cons.w &&
    8000037c:	4929                	li	s2,10
    8000037e:	02f70863          	beq	a4,a5,800003ae <consoleintr+0x104>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000382:	37fd                	addiw	a5,a5,-1
    80000384:	07f7f713          	andi	a4,a5,127
    80000388:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    8000038a:	01874703          	lbu	a4,24(a4)
    8000038e:	03270263          	beq	a4,s2,800003b2 <consoleintr+0x108>
      cons.e--;
    80000392:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    80000396:	10000513          	li	a0,256
    8000039a:	edfff0ef          	jal	80000278 <consputc>
    while(cons.e != cons.w &&
    8000039e:	0a04a783          	lw	a5,160(s1)
    800003a2:	09c4a703          	lw	a4,156(s1)
    800003a6:	fcf71ee3          	bne	a4,a5,80000382 <consoleintr+0xd8>
    800003aa:	6902                	ld	s2,0(sp)
    800003ac:	bf05                	j	800002dc <consoleintr+0x32>
    800003ae:	6902                	ld	s2,0(sp)
    800003b0:	b735                	j	800002dc <consoleintr+0x32>
    800003b2:	6902                	ld	s2,0(sp)
    800003b4:	b725                	j	800002dc <consoleintr+0x32>
    if(cons.e != cons.w){
    800003b6:	00012717          	auipc	a4,0x12
    800003ba:	06a70713          	addi	a4,a4,106 # 80012420 <cons>
    800003be:	0a072783          	lw	a5,160(a4)
    800003c2:	09c72703          	lw	a4,156(a4)
    800003c6:	f0f70be3          	beq	a4,a5,800002dc <consoleintr+0x32>
      cons.e--;
    800003ca:	37fd                	addiw	a5,a5,-1
    800003cc:	00012717          	auipc	a4,0x12
    800003d0:	0ef72a23          	sw	a5,244(a4) # 800124c0 <cons+0xa0>
      consputc(BACKSPACE);
    800003d4:	10000513          	li	a0,256
    800003d8:	ea1ff0ef          	jal	80000278 <consputc>
    800003dc:	b701                	j	800002dc <consoleintr+0x32>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    800003de:	ee048fe3          	beqz	s1,800002dc <consoleintr+0x32>
    800003e2:	bf21                	j	800002fa <consoleintr+0x50>
      consputc(c);
    800003e4:	4529                	li	a0,10
    800003e6:	e93ff0ef          	jal	80000278 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    800003ea:	00012797          	auipc	a5,0x12
    800003ee:	03678793          	addi	a5,a5,54 # 80012420 <cons>
    800003f2:	0a07a703          	lw	a4,160(a5)
    800003f6:	0017069b          	addiw	a3,a4,1
    800003fa:	0006861b          	sext.w	a2,a3
    800003fe:	0ad7a023          	sw	a3,160(a5)
    80000402:	07f77713          	andi	a4,a4,127
    80000406:	97ba                	add	a5,a5,a4
    80000408:	4729                	li	a4,10
    8000040a:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    8000040e:	00012797          	auipc	a5,0x12
    80000412:	0ac7a723          	sw	a2,174(a5) # 800124bc <cons+0x9c>
        wakeup(&cons.r);
    80000416:	00012517          	auipc	a0,0x12
    8000041a:	0a250513          	addi	a0,a0,162 # 800124b8 <cons+0x98>
    8000041e:	563010ef          	jal	80002180 <wakeup>
    80000422:	bd6d                	j	800002dc <consoleintr+0x32>

0000000080000424 <consoleinit>:

void
consoleinit(void)
{
    80000424:	1141                	addi	sp,sp,-16
    80000426:	e406                	sd	ra,8(sp)
    80000428:	e022                	sd	s0,0(sp)
    8000042a:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000042c:	00007597          	auipc	a1,0x7
    80000430:	bd458593          	addi	a1,a1,-1068 # 80007000 <etext>
    80000434:	00012517          	auipc	a0,0x12
    80000438:	fec50513          	addi	a0,a0,-20 # 80012420 <cons>
    8000043c:	712000ef          	jal	80000b4e <initlock>

  uartinit();
    80000440:	400000ef          	jal	80000840 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000444:	00023797          	auipc	a5,0x23
    80000448:	f7c78793          	addi	a5,a5,-132 # 800233c0 <devsw>
    8000044c:	00000717          	auipc	a4,0x0
    80000450:	d2270713          	addi	a4,a4,-734 # 8000016e <consoleread>
    80000454:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000456:	00000717          	auipc	a4,0x0
    8000045a:	c7a70713          	addi	a4,a4,-902 # 800000d0 <consolewrite>
    8000045e:	ef98                	sd	a4,24(a5)
}
    80000460:	60a2                	ld	ra,8(sp)
    80000462:	6402                	ld	s0,0(sp)
    80000464:	0141                	addi	sp,sp,16
    80000466:	8082                	ret

0000000080000468 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(long long xx, int base, int sign)
{
    80000468:	7139                	addi	sp,sp,-64
    8000046a:	fc06                	sd	ra,56(sp)
    8000046c:	f822                	sd	s0,48(sp)
    8000046e:	0080                	addi	s0,sp,64
  char buf[20];
  int i;
  unsigned long long x;

  if(sign && (sign = (xx < 0)))
    80000470:	c219                	beqz	a2,80000476 <printint+0xe>
    80000472:	08054063          	bltz	a0,800004f2 <printint+0x8a>
    x = -xx;
  else
    x = xx;
    80000476:	4881                	li	a7,0
    80000478:	fc840693          	addi	a3,s0,-56

  i = 0;
    8000047c:	4781                	li	a5,0
  do {
    buf[i++] = digits[x % base];
    8000047e:	00007617          	auipc	a2,0x7
    80000482:	39260613          	addi	a2,a2,914 # 80007810 <digits>
    80000486:	883e                	mv	a6,a5
    80000488:	2785                	addiw	a5,a5,1
    8000048a:	02b57733          	remu	a4,a0,a1
    8000048e:	9732                	add	a4,a4,a2
    80000490:	00074703          	lbu	a4,0(a4)
    80000494:	00e68023          	sb	a4,0(a3)
  } while((x /= base) != 0);
    80000498:	872a                	mv	a4,a0
    8000049a:	02b55533          	divu	a0,a0,a1
    8000049e:	0685                	addi	a3,a3,1
    800004a0:	feb773e3          	bgeu	a4,a1,80000486 <printint+0x1e>

  if(sign)
    800004a4:	00088a63          	beqz	a7,800004b8 <printint+0x50>
    buf[i++] = '-';
    800004a8:	1781                	addi	a5,a5,-32
    800004aa:	97a2                	add	a5,a5,s0
    800004ac:	02d00713          	li	a4,45
    800004b0:	fee78423          	sb	a4,-24(a5)
    800004b4:	0028079b          	addiw	a5,a6,2

  while(--i >= 0)
    800004b8:	02f05963          	blez	a5,800004ea <printint+0x82>
    800004bc:	f426                	sd	s1,40(sp)
    800004be:	f04a                	sd	s2,32(sp)
    800004c0:	fc840713          	addi	a4,s0,-56
    800004c4:	00f704b3          	add	s1,a4,a5
    800004c8:	fff70913          	addi	s2,a4,-1
    800004cc:	993e                	add	s2,s2,a5
    800004ce:	37fd                	addiw	a5,a5,-1
    800004d0:	1782                	slli	a5,a5,0x20
    800004d2:	9381                	srli	a5,a5,0x20
    800004d4:	40f90933          	sub	s2,s2,a5
    consputc(buf[i]);
    800004d8:	fff4c503          	lbu	a0,-1(s1)
    800004dc:	d9dff0ef          	jal	80000278 <consputc>
  while(--i >= 0)
    800004e0:	14fd                	addi	s1,s1,-1
    800004e2:	ff249be3          	bne	s1,s2,800004d8 <printint+0x70>
    800004e6:	74a2                	ld	s1,40(sp)
    800004e8:	7902                	ld	s2,32(sp)
}
    800004ea:	70e2                	ld	ra,56(sp)
    800004ec:	7442                	ld	s0,48(sp)
    800004ee:	6121                	addi	sp,sp,64
    800004f0:	8082                	ret
    x = -xx;
    800004f2:	40a00533          	neg	a0,a0
  if(sign && (sign = (xx < 0)))
    800004f6:	4885                	li	a7,1
    x = -xx;
    800004f8:	b741                	j	80000478 <printint+0x10>

00000000800004fa <printf>:
}

// Print to the console.
int
printf(char *fmt, ...)
{
    800004fa:	7131                	addi	sp,sp,-192
    800004fc:	fc86                	sd	ra,120(sp)
    800004fe:	f8a2                	sd	s0,112(sp)
    80000500:	e8d2                	sd	s4,80(sp)
    80000502:	0100                	addi	s0,sp,128
    80000504:	8a2a                	mv	s4,a0
    80000506:	e40c                	sd	a1,8(s0)
    80000508:	e810                	sd	a2,16(s0)
    8000050a:	ec14                	sd	a3,24(s0)
    8000050c:	f018                	sd	a4,32(s0)
    8000050e:	f41c                	sd	a5,40(s0)
    80000510:	03043823          	sd	a6,48(s0)
    80000514:	03143c23          	sd	a7,56(s0)
  va_list ap;
  int i, cx, c0, c1, c2;
  char *s;

  if(panicking == 0)
    80000518:	0000a797          	auipc	a5,0xa
    8000051c:	ebc7a783          	lw	a5,-324(a5) # 8000a3d4 <panicking>
    80000520:	c3a1                	beqz	a5,80000560 <printf+0x66>
    acquire(&pr.lock);

  va_start(ap, fmt);
    80000522:	00840793          	addi	a5,s0,8
    80000526:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (cx = fmt[i] & 0xff) != 0; i++){
    8000052a:	000a4503          	lbu	a0,0(s4)
    8000052e:	28050763          	beqz	a0,800007bc <printf+0x2c2>
    80000532:	f4a6                	sd	s1,104(sp)
    80000534:	f0ca                	sd	s2,96(sp)
    80000536:	ecce                	sd	s3,88(sp)
    80000538:	e4d6                	sd	s5,72(sp)
    8000053a:	e0da                	sd	s6,64(sp)
    8000053c:	f862                	sd	s8,48(sp)
    8000053e:	f466                	sd	s9,40(sp)
    80000540:	f06a                	sd	s10,32(sp)
    80000542:	ec6e                	sd	s11,24(sp)
    80000544:	4981                	li	s3,0
    if(cx != '%'){
    80000546:	02500a93          	li	s5,37
    i++;
    c0 = fmt[i+0] & 0xff;
    c1 = c2 = 0;
    if(c0) c1 = fmt[i+1] & 0xff;
    if(c1) c2 = fmt[i+2] & 0xff;
    if(c0 == 'd'){
    8000054a:	06400b13          	li	s6,100
      printint(va_arg(ap, int), 10, 1);
    } else if(c0 == 'l' && c1 == 'd'){
    8000054e:	06c00c13          	li	s8,108
      printint(va_arg(ap, uint64), 10, 1);
      i += 1;
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
      printint(va_arg(ap, uint64), 10, 1);
      i += 2;
    } else if(c0 == 'u'){
    80000552:	07500c93          	li	s9,117
      printint(va_arg(ap, uint64), 10, 0);
      i += 1;
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
      printint(va_arg(ap, uint64), 10, 0);
      i += 2;
    } else if(c0 == 'x'){
    80000556:	07800d13          	li	s10,120
      printint(va_arg(ap, uint64), 16, 0);
      i += 1;
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
      printint(va_arg(ap, uint64), 16, 0);
      i += 2;
    } else if(c0 == 'p'){
    8000055a:	07000d93          	li	s11,112
    8000055e:	a01d                	j	80000584 <printf+0x8a>
    acquire(&pr.lock);
    80000560:	00012517          	auipc	a0,0x12
    80000564:	f6850513          	addi	a0,a0,-152 # 800124c8 <pr>
    80000568:	666000ef          	jal	80000bce <acquire>
    8000056c:	bf5d                	j	80000522 <printf+0x28>
      consputc(cx);
    8000056e:	d0bff0ef          	jal	80000278 <consputc>
      continue;
    80000572:	84ce                	mv	s1,s3
  for(i = 0; (cx = fmt[i] & 0xff) != 0; i++){
    80000574:	0014899b          	addiw	s3,s1,1
    80000578:	013a07b3          	add	a5,s4,s3
    8000057c:	0007c503          	lbu	a0,0(a5)
    80000580:	20050b63          	beqz	a0,80000796 <printf+0x29c>
    if(cx != '%'){
    80000584:	ff5515e3          	bne	a0,s5,8000056e <printf+0x74>
    i++;
    80000588:	0019849b          	addiw	s1,s3,1
    c0 = fmt[i+0] & 0xff;
    8000058c:	009a07b3          	add	a5,s4,s1
    80000590:	0007c903          	lbu	s2,0(a5)
    if(c0) c1 = fmt[i+1] & 0xff;
    80000594:	20090b63          	beqz	s2,800007aa <printf+0x2b0>
    80000598:	0017c783          	lbu	a5,1(a5)
    c1 = c2 = 0;
    8000059c:	86be                	mv	a3,a5
    if(c1) c2 = fmt[i+2] & 0xff;
    8000059e:	c789                	beqz	a5,800005a8 <printf+0xae>
    800005a0:	009a0733          	add	a4,s4,s1
    800005a4:	00274683          	lbu	a3,2(a4)
    if(c0 == 'd'){
    800005a8:	03690963          	beq	s2,s6,800005da <printf+0xe0>
    } else if(c0 == 'l' && c1 == 'd'){
    800005ac:	05890363          	beq	s2,s8,800005f2 <printf+0xf8>
    } else if(c0 == 'u'){
    800005b0:	0d990663          	beq	s2,s9,8000067c <printf+0x182>
    } else if(c0 == 'x'){
    800005b4:	11a90d63          	beq	s2,s10,800006ce <printf+0x1d4>
    } else if(c0 == 'p'){
    800005b8:	15b90663          	beq	s2,s11,80000704 <printf+0x20a>
      printptr(va_arg(ap, uint64));
    } else if(c0 == 'c'){
    800005bc:	06300793          	li	a5,99
    800005c0:	18f90563          	beq	s2,a5,8000074a <printf+0x250>
      consputc(va_arg(ap, uint));
    } else if(c0 == 's'){
    800005c4:	07300793          	li	a5,115
    800005c8:	18f90b63          	beq	s2,a5,8000075e <printf+0x264>
      if((s = va_arg(ap, char*)) == 0)
        s = "(null)";
      for(; *s; s++)
        consputc(*s);
    } else if(c0 == '%'){
    800005cc:	03591b63          	bne	s2,s5,80000602 <printf+0x108>
      consputc('%');
    800005d0:	02500513          	li	a0,37
    800005d4:	ca5ff0ef          	jal	80000278 <consputc>
    800005d8:	bf71                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, int), 10, 1);
    800005da:	f8843783          	ld	a5,-120(s0)
    800005de:	00878713          	addi	a4,a5,8
    800005e2:	f8e43423          	sd	a4,-120(s0)
    800005e6:	4605                	li	a2,1
    800005e8:	45a9                	li	a1,10
    800005ea:	4388                	lw	a0,0(a5)
    800005ec:	e7dff0ef          	jal	80000468 <printint>
    800005f0:	b751                	j	80000574 <printf+0x7a>
    } else if(c0 == 'l' && c1 == 'd'){
    800005f2:	01678f63          	beq	a5,s6,80000610 <printf+0x116>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
    800005f6:	03878b63          	beq	a5,s8,8000062c <printf+0x132>
    } else if(c0 == 'l' && c1 == 'u'){
    800005fa:	09978e63          	beq	a5,s9,80000696 <printf+0x19c>
    } else if(c0 == 'l' && c1 == 'x'){
    800005fe:	0fa78563          	beq	a5,s10,800006e8 <printf+0x1ee>
    } else if(c0 == 0){
      break;
    } else {
      // Print unknown % sequence to draw attention.
      consputc('%');
    80000602:	8556                	mv	a0,s5
    80000604:	c75ff0ef          	jal	80000278 <consputc>
      consputc(c0);
    80000608:	854a                	mv	a0,s2
    8000060a:	c6fff0ef          	jal	80000278 <consputc>
    8000060e:	b79d                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint64), 10, 1);
    80000610:	f8843783          	ld	a5,-120(s0)
    80000614:	00878713          	addi	a4,a5,8
    80000618:	f8e43423          	sd	a4,-120(s0)
    8000061c:	4605                	li	a2,1
    8000061e:	45a9                	li	a1,10
    80000620:	6388                	ld	a0,0(a5)
    80000622:	e47ff0ef          	jal	80000468 <printint>
      i += 1;
    80000626:	0029849b          	addiw	s1,s3,2
    8000062a:	b7a9                	j	80000574 <printf+0x7a>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
    8000062c:	06400793          	li	a5,100
    80000630:	02f68863          	beq	a3,a5,80000660 <printf+0x166>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
    80000634:	07500793          	li	a5,117
    80000638:	06f68d63          	beq	a3,a5,800006b2 <printf+0x1b8>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
    8000063c:	07800793          	li	a5,120
    80000640:	fcf691e3          	bne	a3,a5,80000602 <printf+0x108>
      printint(va_arg(ap, uint64), 16, 0);
    80000644:	f8843783          	ld	a5,-120(s0)
    80000648:	00878713          	addi	a4,a5,8
    8000064c:	f8e43423          	sd	a4,-120(s0)
    80000650:	4601                	li	a2,0
    80000652:	45c1                	li	a1,16
    80000654:	6388                	ld	a0,0(a5)
    80000656:	e13ff0ef          	jal	80000468 <printint>
      i += 2;
    8000065a:	0039849b          	addiw	s1,s3,3
    8000065e:	bf19                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint64), 10, 1);
    80000660:	f8843783          	ld	a5,-120(s0)
    80000664:	00878713          	addi	a4,a5,8
    80000668:	f8e43423          	sd	a4,-120(s0)
    8000066c:	4605                	li	a2,1
    8000066e:	45a9                	li	a1,10
    80000670:	6388                	ld	a0,0(a5)
    80000672:	df7ff0ef          	jal	80000468 <printint>
      i += 2;
    80000676:	0039849b          	addiw	s1,s3,3
    8000067a:	bded                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint32), 10, 0);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4601                	li	a2,0
    8000068a:	45a9                	li	a1,10
    8000068c:	0007e503          	lwu	a0,0(a5)
    80000690:	dd9ff0ef          	jal	80000468 <printint>
    80000694:	b5c5                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint64), 10, 0);
    80000696:	f8843783          	ld	a5,-120(s0)
    8000069a:	00878713          	addi	a4,a5,8
    8000069e:	f8e43423          	sd	a4,-120(s0)
    800006a2:	4601                	li	a2,0
    800006a4:	45a9                	li	a1,10
    800006a6:	6388                	ld	a0,0(a5)
    800006a8:	dc1ff0ef          	jal	80000468 <printint>
      i += 1;
    800006ac:	0029849b          	addiw	s1,s3,2
    800006b0:	b5d1                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint64), 10, 0);
    800006b2:	f8843783          	ld	a5,-120(s0)
    800006b6:	00878713          	addi	a4,a5,8
    800006ba:	f8e43423          	sd	a4,-120(s0)
    800006be:	4601                	li	a2,0
    800006c0:	45a9                	li	a1,10
    800006c2:	6388                	ld	a0,0(a5)
    800006c4:	da5ff0ef          	jal	80000468 <printint>
      i += 2;
    800006c8:	0039849b          	addiw	s1,s3,3
    800006cc:	b565                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint32), 16, 0);
    800006ce:	f8843783          	ld	a5,-120(s0)
    800006d2:	00878713          	addi	a4,a5,8
    800006d6:	f8e43423          	sd	a4,-120(s0)
    800006da:	4601                	li	a2,0
    800006dc:	45c1                	li	a1,16
    800006de:	0007e503          	lwu	a0,0(a5)
    800006e2:	d87ff0ef          	jal	80000468 <printint>
    800006e6:	b579                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint64), 16, 0);
    800006e8:	f8843783          	ld	a5,-120(s0)
    800006ec:	00878713          	addi	a4,a5,8
    800006f0:	f8e43423          	sd	a4,-120(s0)
    800006f4:	4601                	li	a2,0
    800006f6:	45c1                	li	a1,16
    800006f8:	6388                	ld	a0,0(a5)
    800006fa:	d6fff0ef          	jal	80000468 <printint>
      i += 1;
    800006fe:	0029849b          	addiw	s1,s3,2
    80000702:	bd8d                	j	80000574 <printf+0x7a>
    80000704:	fc5e                	sd	s7,56(sp)
      printptr(va_arg(ap, uint64));
    80000706:	f8843783          	ld	a5,-120(s0)
    8000070a:	00878713          	addi	a4,a5,8
    8000070e:	f8e43423          	sd	a4,-120(s0)
    80000712:	0007b983          	ld	s3,0(a5)
  consputc('0');
    80000716:	03000513          	li	a0,48
    8000071a:	b5fff0ef          	jal	80000278 <consputc>
  consputc('x');
    8000071e:	07800513          	li	a0,120
    80000722:	b57ff0ef          	jal	80000278 <consputc>
    80000726:	4941                	li	s2,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    80000728:	00007b97          	auipc	s7,0x7
    8000072c:	0e8b8b93          	addi	s7,s7,232 # 80007810 <digits>
    80000730:	03c9d793          	srli	a5,s3,0x3c
    80000734:	97de                	add	a5,a5,s7
    80000736:	0007c503          	lbu	a0,0(a5)
    8000073a:	b3fff0ef          	jal	80000278 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    8000073e:	0992                	slli	s3,s3,0x4
    80000740:	397d                	addiw	s2,s2,-1
    80000742:	fe0917e3          	bnez	s2,80000730 <printf+0x236>
    80000746:	7be2                	ld	s7,56(sp)
    80000748:	b535                	j	80000574 <printf+0x7a>
      consputc(va_arg(ap, uint));
    8000074a:	f8843783          	ld	a5,-120(s0)
    8000074e:	00878713          	addi	a4,a5,8
    80000752:	f8e43423          	sd	a4,-120(s0)
    80000756:	4388                	lw	a0,0(a5)
    80000758:	b21ff0ef          	jal	80000278 <consputc>
    8000075c:	bd21                	j	80000574 <printf+0x7a>
      if((s = va_arg(ap, char*)) == 0)
    8000075e:	f8843783          	ld	a5,-120(s0)
    80000762:	00878713          	addi	a4,a5,8
    80000766:	f8e43423          	sd	a4,-120(s0)
    8000076a:	0007b903          	ld	s2,0(a5)
    8000076e:	00090d63          	beqz	s2,80000788 <printf+0x28e>
      for(; *s; s++)
    80000772:	00094503          	lbu	a0,0(s2)
    80000776:	de050fe3          	beqz	a0,80000574 <printf+0x7a>
        consputc(*s);
    8000077a:	affff0ef          	jal	80000278 <consputc>
      for(; *s; s++)
    8000077e:	0905                	addi	s2,s2,1
    80000780:	00094503          	lbu	a0,0(s2)
    80000784:	f97d                	bnez	a0,8000077a <printf+0x280>
    80000786:	b3fd                	j	80000574 <printf+0x7a>
        s = "(null)";
    80000788:	00007917          	auipc	s2,0x7
    8000078c:	88090913          	addi	s2,s2,-1920 # 80007008 <etext+0x8>
      for(; *s; s++)
    80000790:	02800513          	li	a0,40
    80000794:	b7dd                	j	8000077a <printf+0x280>
    80000796:	74a6                	ld	s1,104(sp)
    80000798:	7906                	ld	s2,96(sp)
    8000079a:	69e6                	ld	s3,88(sp)
    8000079c:	6aa6                	ld	s5,72(sp)
    8000079e:	6b06                	ld	s6,64(sp)
    800007a0:	7c42                	ld	s8,48(sp)
    800007a2:	7ca2                	ld	s9,40(sp)
    800007a4:	7d02                	ld	s10,32(sp)
    800007a6:	6de2                	ld	s11,24(sp)
    800007a8:	a811                	j	800007bc <printf+0x2c2>
    800007aa:	74a6                	ld	s1,104(sp)
    800007ac:	7906                	ld	s2,96(sp)
    800007ae:	69e6                	ld	s3,88(sp)
    800007b0:	6aa6                	ld	s5,72(sp)
    800007b2:	6b06                	ld	s6,64(sp)
    800007b4:	7c42                	ld	s8,48(sp)
    800007b6:	7ca2                	ld	s9,40(sp)
    800007b8:	7d02                	ld	s10,32(sp)
    800007ba:	6de2                	ld	s11,24(sp)
    }

  }
  va_end(ap);

  if(panicking == 0)
    800007bc:	0000a797          	auipc	a5,0xa
    800007c0:	c187a783          	lw	a5,-1000(a5) # 8000a3d4 <panicking>
    800007c4:	c799                	beqz	a5,800007d2 <printf+0x2d8>
    release(&pr.lock);

  return 0;
}
    800007c6:	4501                	li	a0,0
    800007c8:	70e6                	ld	ra,120(sp)
    800007ca:	7446                	ld	s0,112(sp)
    800007cc:	6a46                	ld	s4,80(sp)
    800007ce:	6129                	addi	sp,sp,192
    800007d0:	8082                	ret
    release(&pr.lock);
    800007d2:	00012517          	auipc	a0,0x12
    800007d6:	cf650513          	addi	a0,a0,-778 # 800124c8 <pr>
    800007da:	48c000ef          	jal	80000c66 <release>
  return 0;
    800007de:	b7e5                	j	800007c6 <printf+0x2cc>

00000000800007e0 <panic>:

void
panic(char *s)
{
    800007e0:	1101                	addi	sp,sp,-32
    800007e2:	ec06                	sd	ra,24(sp)
    800007e4:	e822                	sd	s0,16(sp)
    800007e6:	e426                	sd	s1,8(sp)
    800007e8:	e04a                	sd	s2,0(sp)
    800007ea:	1000                	addi	s0,sp,32
    800007ec:	84aa                	mv	s1,a0
  panicking = 1;
    800007ee:	4905                	li	s2,1
    800007f0:	0000a797          	auipc	a5,0xa
    800007f4:	bf27a223          	sw	s2,-1052(a5) # 8000a3d4 <panicking>
  printf("panic: ");
    800007f8:	00007517          	auipc	a0,0x7
    800007fc:	82050513          	addi	a0,a0,-2016 # 80007018 <etext+0x18>
    80000800:	cfbff0ef          	jal	800004fa <printf>
  printf("%s\n", s);
    80000804:	85a6                	mv	a1,s1
    80000806:	00007517          	auipc	a0,0x7
    8000080a:	81a50513          	addi	a0,a0,-2022 # 80007020 <etext+0x20>
    8000080e:	cedff0ef          	jal	800004fa <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000812:	0000a797          	auipc	a5,0xa
    80000816:	bb27af23          	sw	s2,-1090(a5) # 8000a3d0 <panicked>
  for(;;)
    8000081a:	a001                	j	8000081a <panic+0x3a>

000000008000081c <printfinit>:
    ;
}

void
printfinit(void)
{
    8000081c:	1141                	addi	sp,sp,-16
    8000081e:	e406                	sd	ra,8(sp)
    80000820:	e022                	sd	s0,0(sp)
    80000822:	0800                	addi	s0,sp,16
  initlock(&pr.lock, "pr");
    80000824:	00007597          	auipc	a1,0x7
    80000828:	80458593          	addi	a1,a1,-2044 # 80007028 <etext+0x28>
    8000082c:	00012517          	auipc	a0,0x12
    80000830:	c9c50513          	addi	a0,a0,-868 # 800124c8 <pr>
    80000834:	31a000ef          	jal	80000b4e <initlock>
}
    80000838:	60a2                	ld	ra,8(sp)
    8000083a:	6402                	ld	s0,0(sp)
    8000083c:	0141                	addi	sp,sp,16
    8000083e:	8082                	ret

0000000080000840 <uartinit>:
extern volatile int panicking; // from printf.c
extern volatile int panicked; // from printf.c

void
uartinit(void)
{
    80000840:	1141                	addi	sp,sp,-16
    80000842:	e406                	sd	ra,8(sp)
    80000844:	e022                	sd	s0,0(sp)
    80000846:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    80000848:	100007b7          	lui	a5,0x10000
    8000084c:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    80000850:	10000737          	lui	a4,0x10000
    80000854:	f8000693          	li	a3,-128
    80000858:	00d701a3          	sb	a3,3(a4) # 10000003 <_entry-0x6ffffffd>

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    8000085c:	468d                	li	a3,3
    8000085e:	10000637          	lui	a2,0x10000
    80000862:	00d60023          	sb	a3,0(a2) # 10000000 <_entry-0x70000000>

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    80000866:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    8000086a:	00d701a3          	sb	a3,3(a4)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    8000086e:	10000737          	lui	a4,0x10000
    80000872:	461d                	li	a2,7
    80000874:	00c70123          	sb	a2,2(a4) # 10000002 <_entry-0x6ffffffe>

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    80000878:	00d780a3          	sb	a3,1(a5)

  initlock(&tx_lock, "uart");
    8000087c:	00006597          	auipc	a1,0x6
    80000880:	7b458593          	addi	a1,a1,1972 # 80007030 <etext+0x30>
    80000884:	00012517          	auipc	a0,0x12
    80000888:	c5c50513          	addi	a0,a0,-932 # 800124e0 <tx_lock>
    8000088c:	2c2000ef          	jal	80000b4e <initlock>
}
    80000890:	60a2                	ld	ra,8(sp)
    80000892:	6402                	ld	s0,0(sp)
    80000894:	0141                	addi	sp,sp,16
    80000896:	8082                	ret

0000000080000898 <uartwrite>:
// transmit buf[] to the uart. it blocks if the
// uart is busy, so it cannot be called from
// interrupts, only from write() system calls.
void
uartwrite(char buf[], int n)
{
    80000898:	715d                	addi	sp,sp,-80
    8000089a:	e486                	sd	ra,72(sp)
    8000089c:	e0a2                	sd	s0,64(sp)
    8000089e:	fc26                	sd	s1,56(sp)
    800008a0:	ec56                	sd	s5,24(sp)
    800008a2:	0880                	addi	s0,sp,80
    800008a4:	8aaa                	mv	s5,a0
    800008a6:	84ae                	mv	s1,a1
  acquire(&tx_lock);
    800008a8:	00012517          	auipc	a0,0x12
    800008ac:	c3850513          	addi	a0,a0,-968 # 800124e0 <tx_lock>
    800008b0:	31e000ef          	jal	80000bce <acquire>

  int i = 0;
  while(i < n){ 
    800008b4:	06905063          	blez	s1,80000914 <uartwrite+0x7c>
    800008b8:	f84a                	sd	s2,48(sp)
    800008ba:	f44e                	sd	s3,40(sp)
    800008bc:	f052                	sd	s4,32(sp)
    800008be:	e85a                	sd	s6,16(sp)
    800008c0:	e45e                	sd	s7,8(sp)
    800008c2:	8a56                	mv	s4,s5
    800008c4:	9aa6                	add	s5,s5,s1
    while(tx_busy != 0){
    800008c6:	0000a497          	auipc	s1,0xa
    800008ca:	b1648493          	addi	s1,s1,-1258 # 8000a3dc <tx_busy>
      // wait for a UART transmit-complete interrupt
      // to set tx_busy to 0.
      sleep(&tx_chan, &tx_lock);
    800008ce:	00012997          	auipc	s3,0x12
    800008d2:	c1298993          	addi	s3,s3,-1006 # 800124e0 <tx_lock>
    800008d6:	0000a917          	auipc	s2,0xa
    800008da:	b0290913          	addi	s2,s2,-1278 # 8000a3d8 <tx_chan>
    }   
      
    WriteReg(THR, buf[i]);
    800008de:	10000bb7          	lui	s7,0x10000
    i += 1;
    tx_busy = 1;
    800008e2:	4b05                	li	s6,1
    800008e4:	a005                	j	80000904 <uartwrite+0x6c>
      sleep(&tx_chan, &tx_lock);
    800008e6:	85ce                	mv	a1,s3
    800008e8:	854a                	mv	a0,s2
    800008ea:	01b010ef          	jal	80002104 <sleep>
    while(tx_busy != 0){
    800008ee:	409c                	lw	a5,0(s1)
    800008f0:	fbfd                	bnez	a5,800008e6 <uartwrite+0x4e>
    WriteReg(THR, buf[i]);
    800008f2:	000a4783          	lbu	a5,0(s4)
    800008f6:	00fb8023          	sb	a5,0(s7) # 10000000 <_entry-0x70000000>
    tx_busy = 1;
    800008fa:	0164a023          	sw	s6,0(s1)
  while(i < n){ 
    800008fe:	0a05                	addi	s4,s4,1
    80000900:	015a0563          	beq	s4,s5,8000090a <uartwrite+0x72>
    while(tx_busy != 0){
    80000904:	409c                	lw	a5,0(s1)
    80000906:	f3e5                	bnez	a5,800008e6 <uartwrite+0x4e>
    80000908:	b7ed                	j	800008f2 <uartwrite+0x5a>
    8000090a:	7942                	ld	s2,48(sp)
    8000090c:	79a2                	ld	s3,40(sp)
    8000090e:	7a02                	ld	s4,32(sp)
    80000910:	6b42                	ld	s6,16(sp)
    80000912:	6ba2                	ld	s7,8(sp)
  }

  release(&tx_lock);
    80000914:	00012517          	auipc	a0,0x12
    80000918:	bcc50513          	addi	a0,a0,-1076 # 800124e0 <tx_lock>
    8000091c:	34a000ef          	jal	80000c66 <release>
}
    80000920:	60a6                	ld	ra,72(sp)
    80000922:	6406                	ld	s0,64(sp)
    80000924:	74e2                	ld	s1,56(sp)
    80000926:	6ae2                	ld	s5,24(sp)
    80000928:	6161                	addi	sp,sp,80
    8000092a:	8082                	ret

000000008000092c <uartputc_sync>:
// interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    8000092c:	1101                	addi	sp,sp,-32
    8000092e:	ec06                	sd	ra,24(sp)
    80000930:	e822                	sd	s0,16(sp)
    80000932:	e426                	sd	s1,8(sp)
    80000934:	1000                	addi	s0,sp,32
    80000936:	84aa                	mv	s1,a0
  if(panicking == 0)
    80000938:	0000a797          	auipc	a5,0xa
    8000093c:	a9c7a783          	lw	a5,-1380(a5) # 8000a3d4 <panicking>
    80000940:	cf95                	beqz	a5,8000097c <uartputc_sync+0x50>
    push_off();

  if(panicked){
    80000942:	0000a797          	auipc	a5,0xa
    80000946:	a8e7a783          	lw	a5,-1394(a5) # 8000a3d0 <panicked>
    8000094a:	ef85                	bnez	a5,80000982 <uartputc_sync+0x56>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000094c:	10000737          	lui	a4,0x10000
    80000950:	0715                	addi	a4,a4,5 # 10000005 <_entry-0x6ffffffb>
    80000952:	00074783          	lbu	a5,0(a4)
    80000956:	0207f793          	andi	a5,a5,32
    8000095a:	dfe5                	beqz	a5,80000952 <uartputc_sync+0x26>
    ;
  WriteReg(THR, c);
    8000095c:	0ff4f513          	zext.b	a0,s1
    80000960:	100007b7          	lui	a5,0x10000
    80000964:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  if(panicking == 0)
    80000968:	0000a797          	auipc	a5,0xa
    8000096c:	a6c7a783          	lw	a5,-1428(a5) # 8000a3d4 <panicking>
    80000970:	cb91                	beqz	a5,80000984 <uartputc_sync+0x58>
    pop_off();
}
    80000972:	60e2                	ld	ra,24(sp)
    80000974:	6442                	ld	s0,16(sp)
    80000976:	64a2                	ld	s1,8(sp)
    80000978:	6105                	addi	sp,sp,32
    8000097a:	8082                	ret
    push_off();
    8000097c:	212000ef          	jal	80000b8e <push_off>
    80000980:	b7c9                	j	80000942 <uartputc_sync+0x16>
    for(;;)
    80000982:	a001                	j	80000982 <uartputc_sync+0x56>
    pop_off();
    80000984:	28e000ef          	jal	80000c12 <pop_off>
}
    80000988:	b7ed                	j	80000972 <uartputc_sync+0x46>

000000008000098a <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    8000098a:	1141                	addi	sp,sp,-16
    8000098c:	e422                	sd	s0,8(sp)
    8000098e:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & LSR_RX_READY){
    80000990:	100007b7          	lui	a5,0x10000
    80000994:	0795                	addi	a5,a5,5 # 10000005 <_entry-0x6ffffffb>
    80000996:	0007c783          	lbu	a5,0(a5)
    8000099a:	8b85                	andi	a5,a5,1
    8000099c:	cb81                	beqz	a5,800009ac <uartgetc+0x22>
    // input data is ready.
    return ReadReg(RHR);
    8000099e:	100007b7          	lui	a5,0x10000
    800009a2:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    800009a6:	6422                	ld	s0,8(sp)
    800009a8:	0141                	addi	sp,sp,16
    800009aa:	8082                	ret
    return -1;
    800009ac:	557d                	li	a0,-1
    800009ae:	bfe5                	j	800009a6 <uartgetc+0x1c>

00000000800009b0 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    800009b0:	1101                	addi	sp,sp,-32
    800009b2:	ec06                	sd	ra,24(sp)
    800009b4:	e822                	sd	s0,16(sp)
    800009b6:	e426                	sd	s1,8(sp)
    800009b8:	1000                	addi	s0,sp,32
  ReadReg(ISR); // acknowledge the interrupt
    800009ba:	100007b7          	lui	a5,0x10000
    800009be:	0789                	addi	a5,a5,2 # 10000002 <_entry-0x6ffffffe>
    800009c0:	0007c783          	lbu	a5,0(a5)

  acquire(&tx_lock);
    800009c4:	00012517          	auipc	a0,0x12
    800009c8:	b1c50513          	addi	a0,a0,-1252 # 800124e0 <tx_lock>
    800009cc:	202000ef          	jal	80000bce <acquire>
  if(ReadReg(LSR) & LSR_TX_IDLE){
    800009d0:	100007b7          	lui	a5,0x10000
    800009d4:	0795                	addi	a5,a5,5 # 10000005 <_entry-0x6ffffffb>
    800009d6:	0007c783          	lbu	a5,0(a5)
    800009da:	0207f793          	andi	a5,a5,32
    800009de:	eb89                	bnez	a5,800009f0 <uartintr+0x40>
    // UART finished transmitting; wake up sending thread.
    tx_busy = 0;
    wakeup(&tx_chan);
  }
  release(&tx_lock);
    800009e0:	00012517          	auipc	a0,0x12
    800009e4:	b0050513          	addi	a0,a0,-1280 # 800124e0 <tx_lock>
    800009e8:	27e000ef          	jal	80000c66 <release>

  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009ec:	54fd                	li	s1,-1
    800009ee:	a831                	j	80000a0a <uartintr+0x5a>
    tx_busy = 0;
    800009f0:	0000a797          	auipc	a5,0xa
    800009f4:	9e07a623          	sw	zero,-1556(a5) # 8000a3dc <tx_busy>
    wakeup(&tx_chan);
    800009f8:	0000a517          	auipc	a0,0xa
    800009fc:	9e050513          	addi	a0,a0,-1568 # 8000a3d8 <tx_chan>
    80000a00:	780010ef          	jal	80002180 <wakeup>
    80000a04:	bff1                	j	800009e0 <uartintr+0x30>
      break;
    consoleintr(c);
    80000a06:	8a5ff0ef          	jal	800002aa <consoleintr>
    int c = uartgetc();
    80000a0a:	f81ff0ef          	jal	8000098a <uartgetc>
    if(c == -1)
    80000a0e:	fe951ce3          	bne	a0,s1,80000a06 <uartintr+0x56>
  }
}
    80000a12:	60e2                	ld	ra,24(sp)
    80000a14:	6442                	ld	s0,16(sp)
    80000a16:	64a2                	ld	s1,8(sp)
    80000a18:	6105                	addi	sp,sp,32
    80000a1a:	8082                	ret

0000000080000a1c <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a1c:	1101                	addi	sp,sp,-32
    80000a1e:	ec06                	sd	ra,24(sp)
    80000a20:	e822                	sd	s0,16(sp)
    80000a22:	e426                	sd	s1,8(sp)
    80000a24:	e04a                	sd	s2,0(sp)
    80000a26:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a28:	03451793          	slli	a5,a0,0x34
    80000a2c:	e7a9                	bnez	a5,80000a76 <kfree+0x5a>
    80000a2e:	84aa                	mv	s1,a0
    80000a30:	00024797          	auipc	a5,0x24
    80000a34:	b2878793          	addi	a5,a5,-1240 # 80024558 <end>
    80000a38:	02f56f63          	bltu	a0,a5,80000a76 <kfree+0x5a>
    80000a3c:	47c5                	li	a5,17
    80000a3e:	07ee                	slli	a5,a5,0x1b
    80000a40:	02f57b63          	bgeu	a0,a5,80000a76 <kfree+0x5a>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a44:	6605                	lui	a2,0x1
    80000a46:	4585                	li	a1,1
    80000a48:	25a000ef          	jal	80000ca2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a4c:	00012917          	auipc	s2,0x12
    80000a50:	aac90913          	addi	s2,s2,-1364 # 800124f8 <kmem>
    80000a54:	854a                	mv	a0,s2
    80000a56:	178000ef          	jal	80000bce <acquire>
  r->next = kmem.freelist;
    80000a5a:	01893783          	ld	a5,24(s2)
    80000a5e:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a60:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a64:	854a                	mv	a0,s2
    80000a66:	200000ef          	jal	80000c66 <release>
}
    80000a6a:	60e2                	ld	ra,24(sp)
    80000a6c:	6442                	ld	s0,16(sp)
    80000a6e:	64a2                	ld	s1,8(sp)
    80000a70:	6902                	ld	s2,0(sp)
    80000a72:	6105                	addi	sp,sp,32
    80000a74:	8082                	ret
    panic("kfree");
    80000a76:	00006517          	auipc	a0,0x6
    80000a7a:	5c250513          	addi	a0,a0,1474 # 80007038 <etext+0x38>
    80000a7e:	d63ff0ef          	jal	800007e0 <panic>

0000000080000a82 <freerange>:
{
    80000a82:	7179                	addi	sp,sp,-48
    80000a84:	f406                	sd	ra,40(sp)
    80000a86:	f022                	sd	s0,32(sp)
    80000a88:	ec26                	sd	s1,24(sp)
    80000a8a:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a8c:	6785                	lui	a5,0x1
    80000a8e:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a92:	00e504b3          	add	s1,a0,a4
    80000a96:	777d                	lui	a4,0xfffff
    80000a98:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a9a:	94be                	add	s1,s1,a5
    80000a9c:	0295e263          	bltu	a1,s1,80000ac0 <freerange+0x3e>
    80000aa0:	e84a                	sd	s2,16(sp)
    80000aa2:	e44e                	sd	s3,8(sp)
    80000aa4:	e052                	sd	s4,0(sp)
    80000aa6:	892e                	mv	s2,a1
    kfree(p);
    80000aa8:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aaa:	6985                	lui	s3,0x1
    kfree(p);
    80000aac:	01448533          	add	a0,s1,s4
    80000ab0:	f6dff0ef          	jal	80000a1c <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ab4:	94ce                	add	s1,s1,s3
    80000ab6:	fe997be3          	bgeu	s2,s1,80000aac <freerange+0x2a>
    80000aba:	6942                	ld	s2,16(sp)
    80000abc:	69a2                	ld	s3,8(sp)
    80000abe:	6a02                	ld	s4,0(sp)
}
    80000ac0:	70a2                	ld	ra,40(sp)
    80000ac2:	7402                	ld	s0,32(sp)
    80000ac4:	64e2                	ld	s1,24(sp)
    80000ac6:	6145                	addi	sp,sp,48
    80000ac8:	8082                	ret

0000000080000aca <kinit>:
{
    80000aca:	1141                	addi	sp,sp,-16
    80000acc:	e406                	sd	ra,8(sp)
    80000ace:	e022                	sd	s0,0(sp)
    80000ad0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ad2:	00006597          	auipc	a1,0x6
    80000ad6:	56e58593          	addi	a1,a1,1390 # 80007040 <etext+0x40>
    80000ada:	00012517          	auipc	a0,0x12
    80000ade:	a1e50513          	addi	a0,a0,-1506 # 800124f8 <kmem>
    80000ae2:	06c000ef          	jal	80000b4e <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ae6:	45c5                	li	a1,17
    80000ae8:	05ee                	slli	a1,a1,0x1b
    80000aea:	00024517          	auipc	a0,0x24
    80000aee:	a6e50513          	addi	a0,a0,-1426 # 80024558 <end>
    80000af2:	f91ff0ef          	jal	80000a82 <freerange>
}
    80000af6:	60a2                	ld	ra,8(sp)
    80000af8:	6402                	ld	s0,0(sp)
    80000afa:	0141                	addi	sp,sp,16
    80000afc:	8082                	ret

0000000080000afe <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000afe:	1101                	addi	sp,sp,-32
    80000b00:	ec06                	sd	ra,24(sp)
    80000b02:	e822                	sd	s0,16(sp)
    80000b04:	e426                	sd	s1,8(sp)
    80000b06:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b08:	00012497          	auipc	s1,0x12
    80000b0c:	9f048493          	addi	s1,s1,-1552 # 800124f8 <kmem>
    80000b10:	8526                	mv	a0,s1
    80000b12:	0bc000ef          	jal	80000bce <acquire>
  r = kmem.freelist;
    80000b16:	6c84                	ld	s1,24(s1)
  if(r)
    80000b18:	c485                	beqz	s1,80000b40 <kalloc+0x42>
    kmem.freelist = r->next;
    80000b1a:	609c                	ld	a5,0(s1)
    80000b1c:	00012517          	auipc	a0,0x12
    80000b20:	9dc50513          	addi	a0,a0,-1572 # 800124f8 <kmem>
    80000b24:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b26:	140000ef          	jal	80000c66 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b2a:	6605                	lui	a2,0x1
    80000b2c:	4595                	li	a1,5
    80000b2e:	8526                	mv	a0,s1
    80000b30:	172000ef          	jal	80000ca2 <memset>
  return (void*)r;
}
    80000b34:	8526                	mv	a0,s1
    80000b36:	60e2                	ld	ra,24(sp)
    80000b38:	6442                	ld	s0,16(sp)
    80000b3a:	64a2                	ld	s1,8(sp)
    80000b3c:	6105                	addi	sp,sp,32
    80000b3e:	8082                	ret
  release(&kmem.lock);
    80000b40:	00012517          	auipc	a0,0x12
    80000b44:	9b850513          	addi	a0,a0,-1608 # 800124f8 <kmem>
    80000b48:	11e000ef          	jal	80000c66 <release>
  if(r)
    80000b4c:	b7e5                	j	80000b34 <kalloc+0x36>

0000000080000b4e <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b4e:	1141                	addi	sp,sp,-16
    80000b50:	e422                	sd	s0,8(sp)
    80000b52:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b54:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b56:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b5a:	00053823          	sd	zero,16(a0)
}
    80000b5e:	6422                	ld	s0,8(sp)
    80000b60:	0141                	addi	sp,sp,16
    80000b62:	8082                	ret

0000000080000b64 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b64:	411c                	lw	a5,0(a0)
    80000b66:	e399                	bnez	a5,80000b6c <holding+0x8>
    80000b68:	4501                	li	a0,0
  return r;
}
    80000b6a:	8082                	ret
{
    80000b6c:	1101                	addi	sp,sp,-32
    80000b6e:	ec06                	sd	ra,24(sp)
    80000b70:	e822                	sd	s0,16(sp)
    80000b72:	e426                	sd	s1,8(sp)
    80000b74:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b76:	6904                	ld	s1,16(a0)
    80000b78:	57b000ef          	jal	800018f2 <mycpu>
    80000b7c:	40a48533          	sub	a0,s1,a0
    80000b80:	00153513          	seqz	a0,a0
}
    80000b84:	60e2                	ld	ra,24(sp)
    80000b86:	6442                	ld	s0,16(sp)
    80000b88:	64a2                	ld	s1,8(sp)
    80000b8a:	6105                	addi	sp,sp,32
    80000b8c:	8082                	ret

0000000080000b8e <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8e:	1101                	addi	sp,sp,-32
    80000b90:	ec06                	sd	ra,24(sp)
    80000b92:	e822                	sd	s0,16(sp)
    80000b94:	e426                	sd	s1,8(sp)
    80000b96:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b98:	100024f3          	csrr	s1,sstatus
    80000b9c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000ba0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000ba2:	10079073          	csrw	sstatus,a5

  // disable interrupts to prevent an involuntary context
  // switch while using mycpu().
  intr_off();

  if(mycpu()->noff == 0)
    80000ba6:	54d000ef          	jal	800018f2 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cb99                	beqz	a5,80000bc2 <push_off+0x34>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	545000ef          	jal	800018f2 <mycpu>
    80000bb2:	5d3c                	lw	a5,120(a0)
    80000bb4:	2785                	addiw	a5,a5,1
    80000bb6:	dd3c                	sw	a5,120(a0)
}
    80000bb8:	60e2                	ld	ra,24(sp)
    80000bba:	6442                	ld	s0,16(sp)
    80000bbc:	64a2                	ld	s1,8(sp)
    80000bbe:	6105                	addi	sp,sp,32
    80000bc0:	8082                	ret
    mycpu()->intena = old;
    80000bc2:	531000ef          	jal	800018f2 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bc6:	8085                	srli	s1,s1,0x1
    80000bc8:	8885                	andi	s1,s1,1
    80000bca:	dd64                	sw	s1,124(a0)
    80000bcc:	b7cd                	j	80000bae <push_off+0x20>

0000000080000bce <acquire>:
{
    80000bce:	1101                	addi	sp,sp,-32
    80000bd0:	ec06                	sd	ra,24(sp)
    80000bd2:	e822                	sd	s0,16(sp)
    80000bd4:	e426                	sd	s1,8(sp)
    80000bd6:	1000                	addi	s0,sp,32
    80000bd8:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bda:	fb5ff0ef          	jal	80000b8e <push_off>
  if(holding(lk))
    80000bde:	8526                	mv	a0,s1
    80000be0:	f85ff0ef          	jal	80000b64 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000be4:	4705                	li	a4,1
  if(holding(lk))
    80000be6:	e105                	bnez	a0,80000c06 <acquire+0x38>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000be8:	87ba                	mv	a5,a4
    80000bea:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bee:	2781                	sext.w	a5,a5
    80000bf0:	ffe5                	bnez	a5,80000be8 <acquire+0x1a>
  __sync_synchronize();
    80000bf2:	0330000f          	fence	rw,rw
  lk->cpu = mycpu();
    80000bf6:	4fd000ef          	jal	800018f2 <mycpu>
    80000bfa:	e888                	sd	a0,16(s1)
}
    80000bfc:	60e2                	ld	ra,24(sp)
    80000bfe:	6442                	ld	s0,16(sp)
    80000c00:	64a2                	ld	s1,8(sp)
    80000c02:	6105                	addi	sp,sp,32
    80000c04:	8082                	ret
    panic("acquire");
    80000c06:	00006517          	auipc	a0,0x6
    80000c0a:	44250513          	addi	a0,a0,1090 # 80007048 <etext+0x48>
    80000c0e:	bd3ff0ef          	jal	800007e0 <panic>

0000000080000c12 <pop_off>:

void
pop_off(void)
{
    80000c12:	1141                	addi	sp,sp,-16
    80000c14:	e406                	sd	ra,8(sp)
    80000c16:	e022                	sd	s0,0(sp)
    80000c18:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c1a:	4d9000ef          	jal	800018f2 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c1e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c22:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c24:	e78d                	bnez	a5,80000c4e <pop_off+0x3c>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c26:	5d3c                	lw	a5,120(a0)
    80000c28:	02f05963          	blez	a5,80000c5a <pop_off+0x48>
    panic("pop_off");
  c->noff -= 1;
    80000c2c:	37fd                	addiw	a5,a5,-1
    80000c2e:	0007871b          	sext.w	a4,a5
    80000c32:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c34:	eb09                	bnez	a4,80000c46 <pop_off+0x34>
    80000c36:	5d7c                	lw	a5,124(a0)
    80000c38:	c799                	beqz	a5,80000c46 <pop_off+0x34>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c3e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c42:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c46:	60a2                	ld	ra,8(sp)
    80000c48:	6402                	ld	s0,0(sp)
    80000c4a:	0141                	addi	sp,sp,16
    80000c4c:	8082                	ret
    panic("pop_off - interruptible");
    80000c4e:	00006517          	auipc	a0,0x6
    80000c52:	40250513          	addi	a0,a0,1026 # 80007050 <etext+0x50>
    80000c56:	b8bff0ef          	jal	800007e0 <panic>
    panic("pop_off");
    80000c5a:	00006517          	auipc	a0,0x6
    80000c5e:	40e50513          	addi	a0,a0,1038 # 80007068 <etext+0x68>
    80000c62:	b7fff0ef          	jal	800007e0 <panic>

0000000080000c66 <release>:
{
    80000c66:	1101                	addi	sp,sp,-32
    80000c68:	ec06                	sd	ra,24(sp)
    80000c6a:	e822                	sd	s0,16(sp)
    80000c6c:	e426                	sd	s1,8(sp)
    80000c6e:	1000                	addi	s0,sp,32
    80000c70:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c72:	ef3ff0ef          	jal	80000b64 <holding>
    80000c76:	c105                	beqz	a0,80000c96 <release+0x30>
  lk->cpu = 0;
    80000c78:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000c7c:	0330000f          	fence	rw,rw
  __sync_lock_release(&lk->locked);
    80000c80:	0310000f          	fence	rw,w
    80000c84:	0004a023          	sw	zero,0(s1)
  pop_off();
    80000c88:	f8bff0ef          	jal	80000c12 <pop_off>
}
    80000c8c:	60e2                	ld	ra,24(sp)
    80000c8e:	6442                	ld	s0,16(sp)
    80000c90:	64a2                	ld	s1,8(sp)
    80000c92:	6105                	addi	sp,sp,32
    80000c94:	8082                	ret
    panic("release");
    80000c96:	00006517          	auipc	a0,0x6
    80000c9a:	3da50513          	addi	a0,a0,986 # 80007070 <etext+0x70>
    80000c9e:	b43ff0ef          	jal	800007e0 <panic>

0000000080000ca2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ca2:	1141                	addi	sp,sp,-16
    80000ca4:	e422                	sd	s0,8(sp)
    80000ca6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ca8:	ca19                	beqz	a2,80000cbe <memset+0x1c>
    80000caa:	87aa                	mv	a5,a0
    80000cac:	1602                	slli	a2,a2,0x20
    80000cae:	9201                	srli	a2,a2,0x20
    80000cb0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000cb4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cb8:	0785                	addi	a5,a5,1
    80000cba:	fee79de3          	bne	a5,a4,80000cb4 <memset+0x12>
  }
  return dst;
}
    80000cbe:	6422                	ld	s0,8(sp)
    80000cc0:	0141                	addi	sp,sp,16
    80000cc2:	8082                	ret

0000000080000cc4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cc4:	1141                	addi	sp,sp,-16
    80000cc6:	e422                	sd	s0,8(sp)
    80000cc8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cca:	ca05                	beqz	a2,80000cfa <memcmp+0x36>
    80000ccc:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000cd0:	1682                	slli	a3,a3,0x20
    80000cd2:	9281                	srli	a3,a3,0x20
    80000cd4:	0685                	addi	a3,a3,1
    80000cd6:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000cd8:	00054783          	lbu	a5,0(a0)
    80000cdc:	0005c703          	lbu	a4,0(a1)
    80000ce0:	00e79863          	bne	a5,a4,80000cf0 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000ce4:	0505                	addi	a0,a0,1
    80000ce6:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000ce8:	fed518e3          	bne	a0,a3,80000cd8 <memcmp+0x14>
  }

  return 0;
    80000cec:	4501                	li	a0,0
    80000cee:	a019                	j	80000cf4 <memcmp+0x30>
      return *s1 - *s2;
    80000cf0:	40e7853b          	subw	a0,a5,a4
}
    80000cf4:	6422                	ld	s0,8(sp)
    80000cf6:	0141                	addi	sp,sp,16
    80000cf8:	8082                	ret
  return 0;
    80000cfa:	4501                	li	a0,0
    80000cfc:	bfe5                	j	80000cf4 <memcmp+0x30>

0000000080000cfe <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000cfe:	1141                	addi	sp,sp,-16
    80000d00:	e422                	sd	s0,8(sp)
    80000d02:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d04:	c205                	beqz	a2,80000d24 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d06:	02a5e263          	bltu	a1,a0,80000d2a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d0a:	1602                	slli	a2,a2,0x20
    80000d0c:	9201                	srli	a2,a2,0x20
    80000d0e:	00c587b3          	add	a5,a1,a2
{
    80000d12:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d14:	0585                	addi	a1,a1,1
    80000d16:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdaaa9>
    80000d18:	fff5c683          	lbu	a3,-1(a1)
    80000d1c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d20:	feb79ae3          	bne	a5,a1,80000d14 <memmove+0x16>

  return dst;
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  if(s < d && s + n > d){
    80000d2a:	02061693          	slli	a3,a2,0x20
    80000d2e:	9281                	srli	a3,a3,0x20
    80000d30:	00d58733          	add	a4,a1,a3
    80000d34:	fce57be3          	bgeu	a0,a4,80000d0a <memmove+0xc>
    d += n;
    80000d38:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d3a:	fff6079b          	addiw	a5,a2,-1
    80000d3e:	1782                	slli	a5,a5,0x20
    80000d40:	9381                	srli	a5,a5,0x20
    80000d42:	fff7c793          	not	a5,a5
    80000d46:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d48:	177d                	addi	a4,a4,-1
    80000d4a:	16fd                	addi	a3,a3,-1
    80000d4c:	00074603          	lbu	a2,0(a4)
    80000d50:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d54:	fef71ae3          	bne	a4,a5,80000d48 <memmove+0x4a>
    80000d58:	b7f1                	j	80000d24 <memmove+0x26>

0000000080000d5a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d5a:	1141                	addi	sp,sp,-16
    80000d5c:	e406                	sd	ra,8(sp)
    80000d5e:	e022                	sd	s0,0(sp)
    80000d60:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d62:	f9dff0ef          	jal	80000cfe <memmove>
}
    80000d66:	60a2                	ld	ra,8(sp)
    80000d68:	6402                	ld	s0,0(sp)
    80000d6a:	0141                	addi	sp,sp,16
    80000d6c:	8082                	ret

0000000080000d6e <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000d6e:	1141                	addi	sp,sp,-16
    80000d70:	e422                	sd	s0,8(sp)
    80000d72:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000d74:	ce11                	beqz	a2,80000d90 <strncmp+0x22>
    80000d76:	00054783          	lbu	a5,0(a0)
    80000d7a:	cf89                	beqz	a5,80000d94 <strncmp+0x26>
    80000d7c:	0005c703          	lbu	a4,0(a1)
    80000d80:	00f71a63          	bne	a4,a5,80000d94 <strncmp+0x26>
    n--, p++, q++;
    80000d84:	367d                	addiw	a2,a2,-1
    80000d86:	0505                	addi	a0,a0,1
    80000d88:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000d8a:	f675                	bnez	a2,80000d76 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000d8c:	4501                	li	a0,0
    80000d8e:	a801                	j	80000d9e <strncmp+0x30>
    80000d90:	4501                	li	a0,0
    80000d92:	a031                	j	80000d9e <strncmp+0x30>
  return (uchar)*p - (uchar)*q;
    80000d94:	00054503          	lbu	a0,0(a0)
    80000d98:	0005c783          	lbu	a5,0(a1)
    80000d9c:	9d1d                	subw	a0,a0,a5
}
    80000d9e:	6422                	ld	s0,8(sp)
    80000da0:	0141                	addi	sp,sp,16
    80000da2:	8082                	ret

0000000080000da4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000da4:	1141                	addi	sp,sp,-16
    80000da6:	e422                	sd	s0,8(sp)
    80000da8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000daa:	87aa                	mv	a5,a0
    80000dac:	86b2                	mv	a3,a2
    80000dae:	367d                	addiw	a2,a2,-1
    80000db0:	02d05563          	blez	a3,80000dda <strncpy+0x36>
    80000db4:	0785                	addi	a5,a5,1
    80000db6:	0005c703          	lbu	a4,0(a1)
    80000dba:	fee78fa3          	sb	a4,-1(a5)
    80000dbe:	0585                	addi	a1,a1,1
    80000dc0:	f775                	bnez	a4,80000dac <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dc2:	873e                	mv	a4,a5
    80000dc4:	9fb5                	addw	a5,a5,a3
    80000dc6:	37fd                	addiw	a5,a5,-1
    80000dc8:	00c05963          	blez	a2,80000dda <strncpy+0x36>
    *s++ = 0;
    80000dcc:	0705                	addi	a4,a4,1
    80000dce:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    80000dd2:	40e786bb          	subw	a3,a5,a4
    80000dd6:	fed04be3          	bgtz	a3,80000dcc <strncpy+0x28>
  return os;
}
    80000dda:	6422                	ld	s0,8(sp)
    80000ddc:	0141                	addi	sp,sp,16
    80000dde:	8082                	ret

0000000080000de0 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000de0:	1141                	addi	sp,sp,-16
    80000de2:	e422                	sd	s0,8(sp)
    80000de4:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000de6:	02c05363          	blez	a2,80000e0c <safestrcpy+0x2c>
    80000dea:	fff6069b          	addiw	a3,a2,-1
    80000dee:	1682                	slli	a3,a3,0x20
    80000df0:	9281                	srli	a3,a3,0x20
    80000df2:	96ae                	add	a3,a3,a1
    80000df4:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000df6:	00d58963          	beq	a1,a3,80000e08 <safestrcpy+0x28>
    80000dfa:	0585                	addi	a1,a1,1
    80000dfc:	0785                	addi	a5,a5,1
    80000dfe:	fff5c703          	lbu	a4,-1(a1)
    80000e02:	fee78fa3          	sb	a4,-1(a5)
    80000e06:	fb65                	bnez	a4,80000df6 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e08:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e0c:	6422                	ld	s0,8(sp)
    80000e0e:	0141                	addi	sp,sp,16
    80000e10:	8082                	ret

0000000080000e12 <strlen>:

int
strlen(const char *s)
{
    80000e12:	1141                	addi	sp,sp,-16
    80000e14:	e422                	sd	s0,8(sp)
    80000e16:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e18:	00054783          	lbu	a5,0(a0)
    80000e1c:	cf91                	beqz	a5,80000e38 <strlen+0x26>
    80000e1e:	0505                	addi	a0,a0,1
    80000e20:	87aa                	mv	a5,a0
    80000e22:	86be                	mv	a3,a5
    80000e24:	0785                	addi	a5,a5,1
    80000e26:	fff7c703          	lbu	a4,-1(a5)
    80000e2a:	ff65                	bnez	a4,80000e22 <strlen+0x10>
    80000e2c:	40a6853b          	subw	a0,a3,a0
    80000e30:	2505                	addiw	a0,a0,1
    ;
  return n;
}
    80000e32:	6422                	ld	s0,8(sp)
    80000e34:	0141                	addi	sp,sp,16
    80000e36:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e38:	4501                	li	a0,0
    80000e3a:	bfe5                	j	80000e32 <strlen+0x20>

0000000080000e3c <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e3c:	1141                	addi	sp,sp,-16
    80000e3e:	e406                	sd	ra,8(sp)
    80000e40:	e022                	sd	s0,0(sp)
    80000e42:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e44:	29f000ef          	jal	800018e2 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e48:	00009717          	auipc	a4,0x9
    80000e4c:	59870713          	addi	a4,a4,1432 # 8000a3e0 <started>
  if(cpuid() == 0){
    80000e50:	c51d                	beqz	a0,80000e7e <main+0x42>
    while(started == 0)
    80000e52:	431c                	lw	a5,0(a4)
    80000e54:	2781                	sext.w	a5,a5
    80000e56:	dff5                	beqz	a5,80000e52 <main+0x16>
      ;
    __sync_synchronize();
    80000e58:	0330000f          	fence	rw,rw
    printf("hart %d starting\n", cpuid());
    80000e5c:	287000ef          	jal	800018e2 <cpuid>
    80000e60:	85aa                	mv	a1,a0
    80000e62:	00006517          	auipc	a0,0x6
    80000e66:	22e50513          	addi	a0,a0,558 # 80007090 <etext+0x90>
    80000e6a:	e90ff0ef          	jal	800004fa <printf>
    kvminithart();    // turn on paging
    80000e6e:	080000ef          	jal	80000eee <kvminithart>
    trapinithart();   // install kernel trap vector
    80000e72:	047010ef          	jal	800026b8 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000e76:	0e3040ef          	jal	80005758 <plicinithart>
  }

  scheduler();        
    80000e7a:	032010ef          	jal	80001eac <scheduler>
    consoleinit();
    80000e7e:	da6ff0ef          	jal	80000424 <consoleinit>
    printfinit();
    80000e82:	99bff0ef          	jal	8000081c <printfinit>
    printf("\n");
    80000e86:	00006517          	auipc	a0,0x6
    80000e8a:	38250513          	addi	a0,a0,898 # 80007208 <etext+0x208>
    80000e8e:	e6cff0ef          	jal	800004fa <printf>
    printf("xv6 kernel is booting\n");
    80000e92:	00006517          	auipc	a0,0x6
    80000e96:	1e650513          	addi	a0,a0,486 # 80007078 <etext+0x78>
    80000e9a:	e60ff0ef          	jal	800004fa <printf>
    printf("\n");
    80000e9e:	00006517          	auipc	a0,0x6
    80000ea2:	36a50513          	addi	a0,a0,874 # 80007208 <etext+0x208>
    80000ea6:	e54ff0ef          	jal	800004fa <printf>
    kinit();         // physical page allocator
    80000eaa:	c21ff0ef          	jal	80000aca <kinit>
    kvminit();       // create kernel page table
    80000eae:	2ca000ef          	jal	80001178 <kvminit>
    kvminithart();   // turn on paging
    80000eb2:	03c000ef          	jal	80000eee <kvminithart>
    procinit();      // process table
    80000eb6:	137000ef          	jal	800017ec <procinit>
    trapinit();      // trap vectors
    80000eba:	7da010ef          	jal	80002694 <trapinit>
    trapinithart();  // install kernel trap vector
    80000ebe:	7fa010ef          	jal	800026b8 <trapinithart>
    plicinit();      // set up interrupt controller
    80000ec2:	07d040ef          	jal	8000573e <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000ec6:	093040ef          	jal	80005758 <plicinithart>
    binit();         // buffer cache
    80000eca:	73f010ef          	jal	80002e08 <binit>
    iinit();         // inode table
    80000ece:	4c4020ef          	jal	80003392 <iinit>
    fileinit();      // file table
    80000ed2:	3b6030ef          	jal	80004288 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000ed6:	173040ef          	jal	80005848 <virtio_disk_init>
    userinit();      // first user process
    80000eda:	61d000ef          	jal	80001cf6 <userinit>
    __sync_synchronize();
    80000ede:	0330000f          	fence	rw,rw
    started = 1;
    80000ee2:	4785                	li	a5,1
    80000ee4:	00009717          	auipc	a4,0x9
    80000ee8:	4ef72e23          	sw	a5,1276(a4) # 8000a3e0 <started>
    80000eec:	b779                	j	80000e7a <main+0x3e>

0000000080000eee <kvminithart>:

// Switch the current CPU's h/w page table register to
// the kernel's page table, and enable paging.
void
kvminithart()
{
    80000eee:	1141                	addi	sp,sp,-16
    80000ef0:	e422                	sd	s0,8(sp)
    80000ef2:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000ef4:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000ef8:	00009797          	auipc	a5,0x9
    80000efc:	4f07b783          	ld	a5,1264(a5) # 8000a3e8 <kernel_pagetable>
    80000f00:	83b1                	srli	a5,a5,0xc
    80000f02:	577d                	li	a4,-1
    80000f04:	177e                	slli	a4,a4,0x3f
    80000f06:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000f08:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000f0c:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000f10:	6422                	ld	s0,8(sp)
    80000f12:	0141                	addi	sp,sp,16
    80000f14:	8082                	ret

0000000080000f16 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000f16:	7139                	addi	sp,sp,-64
    80000f18:	fc06                	sd	ra,56(sp)
    80000f1a:	f822                	sd	s0,48(sp)
    80000f1c:	f426                	sd	s1,40(sp)
    80000f1e:	f04a                	sd	s2,32(sp)
    80000f20:	ec4e                	sd	s3,24(sp)
    80000f22:	e852                	sd	s4,16(sp)
    80000f24:	e456                	sd	s5,8(sp)
    80000f26:	e05a                	sd	s6,0(sp)
    80000f28:	0080                	addi	s0,sp,64
    80000f2a:	84aa                	mv	s1,a0
    80000f2c:	89ae                	mv	s3,a1
    80000f2e:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000f30:	57fd                	li	a5,-1
    80000f32:	83e9                	srli	a5,a5,0x1a
    80000f34:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000f36:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000f38:	02b7fc63          	bgeu	a5,a1,80000f70 <walk+0x5a>
    panic("walk");
    80000f3c:	00006517          	auipc	a0,0x6
    80000f40:	16c50513          	addi	a0,a0,364 # 800070a8 <etext+0xa8>
    80000f44:	89dff0ef          	jal	800007e0 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000f48:	060a8263          	beqz	s5,80000fac <walk+0x96>
    80000f4c:	bb3ff0ef          	jal	80000afe <kalloc>
    80000f50:	84aa                	mv	s1,a0
    80000f52:	c139                	beqz	a0,80000f98 <walk+0x82>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000f54:	6605                	lui	a2,0x1
    80000f56:	4581                	li	a1,0
    80000f58:	d4bff0ef          	jal	80000ca2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80000f5c:	00c4d793          	srli	a5,s1,0xc
    80000f60:	07aa                	slli	a5,a5,0xa
    80000f62:	0017e793          	ori	a5,a5,1
    80000f66:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80000f6a:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdaa9f>
    80000f6c:	036a0063          	beq	s4,s6,80000f8c <walk+0x76>
    pte_t *pte = &pagetable[PX(level, va)];
    80000f70:	0149d933          	srl	s2,s3,s4
    80000f74:	1ff97913          	andi	s2,s2,511
    80000f78:	090e                	slli	s2,s2,0x3
    80000f7a:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80000f7c:	00093483          	ld	s1,0(s2)
    80000f80:	0014f793          	andi	a5,s1,1
    80000f84:	d3f1                	beqz	a5,80000f48 <walk+0x32>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80000f86:	80a9                	srli	s1,s1,0xa
    80000f88:	04b2                	slli	s1,s1,0xc
    80000f8a:	b7c5                	j	80000f6a <walk+0x54>
    }
  }
  return &pagetable[PX(0, va)];
    80000f8c:	00c9d513          	srli	a0,s3,0xc
    80000f90:	1ff57513          	andi	a0,a0,511
    80000f94:	050e                	slli	a0,a0,0x3
    80000f96:	9526                	add	a0,a0,s1
}
    80000f98:	70e2                	ld	ra,56(sp)
    80000f9a:	7442                	ld	s0,48(sp)
    80000f9c:	74a2                	ld	s1,40(sp)
    80000f9e:	7902                	ld	s2,32(sp)
    80000fa0:	69e2                	ld	s3,24(sp)
    80000fa2:	6a42                	ld	s4,16(sp)
    80000fa4:	6aa2                	ld	s5,8(sp)
    80000fa6:	6b02                	ld	s6,0(sp)
    80000fa8:	6121                	addi	sp,sp,64
    80000faa:	8082                	ret
        return 0;
    80000fac:	4501                	li	a0,0
    80000fae:	b7ed                	j	80000f98 <walk+0x82>

0000000080000fb0 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80000fb0:	57fd                	li	a5,-1
    80000fb2:	83e9                	srli	a5,a5,0x1a
    80000fb4:	00b7f463          	bgeu	a5,a1,80000fbc <walkaddr+0xc>
    return 0;
    80000fb8:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80000fba:	8082                	ret
{
    80000fbc:	1141                	addi	sp,sp,-16
    80000fbe:	e406                	sd	ra,8(sp)
    80000fc0:	e022                	sd	s0,0(sp)
    80000fc2:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80000fc4:	4601                	li	a2,0
    80000fc6:	f51ff0ef          	jal	80000f16 <walk>
  if(pte == 0)
    80000fca:	c105                	beqz	a0,80000fea <walkaddr+0x3a>
  if((*pte & PTE_V) == 0)
    80000fcc:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80000fce:	0117f693          	andi	a3,a5,17
    80000fd2:	4745                	li	a4,17
    return 0;
    80000fd4:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80000fd6:	00e68663          	beq	a3,a4,80000fe2 <walkaddr+0x32>
}
    80000fda:	60a2                	ld	ra,8(sp)
    80000fdc:	6402                	ld	s0,0(sp)
    80000fde:	0141                	addi	sp,sp,16
    80000fe0:	8082                	ret
  pa = PTE2PA(*pte);
    80000fe2:	83a9                	srli	a5,a5,0xa
    80000fe4:	00c79513          	slli	a0,a5,0xc
  return pa;
    80000fe8:	bfcd                	j	80000fda <walkaddr+0x2a>
    return 0;
    80000fea:	4501                	li	a0,0
    80000fec:	b7fd                	j	80000fda <walkaddr+0x2a>

0000000080000fee <mappages>:
// va and size MUST be page-aligned.
// Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80000fee:	715d                	addi	sp,sp,-80
    80000ff0:	e486                	sd	ra,72(sp)
    80000ff2:	e0a2                	sd	s0,64(sp)
    80000ff4:	fc26                	sd	s1,56(sp)
    80000ff6:	f84a                	sd	s2,48(sp)
    80000ff8:	f44e                	sd	s3,40(sp)
    80000ffa:	f052                	sd	s4,32(sp)
    80000ffc:	ec56                	sd	s5,24(sp)
    80000ffe:	e85a                	sd	s6,16(sp)
    80001000:	e45e                	sd	s7,8(sp)
    80001002:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001004:	03459793          	slli	a5,a1,0x34
    80001008:	e7a9                	bnez	a5,80001052 <mappages+0x64>
    8000100a:	8aaa                	mv	s5,a0
    8000100c:	8b3a                	mv	s6,a4
    panic("mappages: va not aligned");

  if((size % PGSIZE) != 0)
    8000100e:	03461793          	slli	a5,a2,0x34
    80001012:	e7b1                	bnez	a5,8000105e <mappages+0x70>
    panic("mappages: size not aligned");

  if(size == 0)
    80001014:	ca39                	beqz	a2,8000106a <mappages+0x7c>
    panic("mappages: size");
  
  a = va;
  last = va + size - PGSIZE;
    80001016:	77fd                	lui	a5,0xfffff
    80001018:	963e                	add	a2,a2,a5
    8000101a:	00b609b3          	add	s3,a2,a1
  a = va;
    8000101e:	892e                	mv	s2,a1
    80001020:	40b68a33          	sub	s4,a3,a1
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001024:	6b85                	lui	s7,0x1
    80001026:	014904b3          	add	s1,s2,s4
    if((pte = walk(pagetable, a, 1)) == 0)
    8000102a:	4605                	li	a2,1
    8000102c:	85ca                	mv	a1,s2
    8000102e:	8556                	mv	a0,s5
    80001030:	ee7ff0ef          	jal	80000f16 <walk>
    80001034:	c539                	beqz	a0,80001082 <mappages+0x94>
    if(*pte & PTE_V)
    80001036:	611c                	ld	a5,0(a0)
    80001038:	8b85                	andi	a5,a5,1
    8000103a:	ef95                	bnez	a5,80001076 <mappages+0x88>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000103c:	80b1                	srli	s1,s1,0xc
    8000103e:	04aa                	slli	s1,s1,0xa
    80001040:	0164e4b3          	or	s1,s1,s6
    80001044:	0014e493          	ori	s1,s1,1
    80001048:	e104                	sd	s1,0(a0)
    if(a == last)
    8000104a:	05390863          	beq	s2,s3,8000109a <mappages+0xac>
    a += PGSIZE;
    8000104e:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001050:	bfd9                	j	80001026 <mappages+0x38>
    panic("mappages: va not aligned");
    80001052:	00006517          	auipc	a0,0x6
    80001056:	05e50513          	addi	a0,a0,94 # 800070b0 <etext+0xb0>
    8000105a:	f86ff0ef          	jal	800007e0 <panic>
    panic("mappages: size not aligned");
    8000105e:	00006517          	auipc	a0,0x6
    80001062:	07250513          	addi	a0,a0,114 # 800070d0 <etext+0xd0>
    80001066:	f7aff0ef          	jal	800007e0 <panic>
    panic("mappages: size");
    8000106a:	00006517          	auipc	a0,0x6
    8000106e:	08650513          	addi	a0,a0,134 # 800070f0 <etext+0xf0>
    80001072:	f6eff0ef          	jal	800007e0 <panic>
      panic("mappages: remap");
    80001076:	00006517          	auipc	a0,0x6
    8000107a:	08a50513          	addi	a0,a0,138 # 80007100 <etext+0x100>
    8000107e:	f62ff0ef          	jal	800007e0 <panic>
      return -1;
    80001082:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001084:	60a6                	ld	ra,72(sp)
    80001086:	6406                	ld	s0,64(sp)
    80001088:	74e2                	ld	s1,56(sp)
    8000108a:	7942                	ld	s2,48(sp)
    8000108c:	79a2                	ld	s3,40(sp)
    8000108e:	7a02                	ld	s4,32(sp)
    80001090:	6ae2                	ld	s5,24(sp)
    80001092:	6b42                	ld	s6,16(sp)
    80001094:	6ba2                	ld	s7,8(sp)
    80001096:	6161                	addi	sp,sp,80
    80001098:	8082                	ret
  return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7e5                	j	80001084 <mappages+0x96>

000000008000109e <kvmmap>:
{
    8000109e:	1141                	addi	sp,sp,-16
    800010a0:	e406                	sd	ra,8(sp)
    800010a2:	e022                	sd	s0,0(sp)
    800010a4:	0800                	addi	s0,sp,16
    800010a6:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    800010a8:	86b2                	mv	a3,a2
    800010aa:	863e                	mv	a2,a5
    800010ac:	f43ff0ef          	jal	80000fee <mappages>
    800010b0:	e509                	bnez	a0,800010ba <kvmmap+0x1c>
}
    800010b2:	60a2                	ld	ra,8(sp)
    800010b4:	6402                	ld	s0,0(sp)
    800010b6:	0141                	addi	sp,sp,16
    800010b8:	8082                	ret
    panic("kvmmap");
    800010ba:	00006517          	auipc	a0,0x6
    800010be:	05650513          	addi	a0,a0,86 # 80007110 <etext+0x110>
    800010c2:	f1eff0ef          	jal	800007e0 <panic>

00000000800010c6 <kvmmake>:
{
    800010c6:	1101                	addi	sp,sp,-32
    800010c8:	ec06                	sd	ra,24(sp)
    800010ca:	e822                	sd	s0,16(sp)
    800010cc:	e426                	sd	s1,8(sp)
    800010ce:	e04a                	sd	s2,0(sp)
    800010d0:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800010d2:	a2dff0ef          	jal	80000afe <kalloc>
    800010d6:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800010d8:	6605                	lui	a2,0x1
    800010da:	4581                	li	a1,0
    800010dc:	bc7ff0ef          	jal	80000ca2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800010e0:	4719                	li	a4,6
    800010e2:	6685                	lui	a3,0x1
    800010e4:	10000637          	lui	a2,0x10000
    800010e8:	100005b7          	lui	a1,0x10000
    800010ec:	8526                	mv	a0,s1
    800010ee:	fb1ff0ef          	jal	8000109e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800010f2:	4719                	li	a4,6
    800010f4:	6685                	lui	a3,0x1
    800010f6:	10001637          	lui	a2,0x10001
    800010fa:	100015b7          	lui	a1,0x10001
    800010fe:	8526                	mv	a0,s1
    80001100:	f9fff0ef          	jal	8000109e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x4000000, PTE_R | PTE_W);
    80001104:	4719                	li	a4,6
    80001106:	040006b7          	lui	a3,0x4000
    8000110a:	0c000637          	lui	a2,0xc000
    8000110e:	0c0005b7          	lui	a1,0xc000
    80001112:	8526                	mv	a0,s1
    80001114:	f8bff0ef          	jal	8000109e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001118:	00006917          	auipc	s2,0x6
    8000111c:	ee890913          	addi	s2,s2,-280 # 80007000 <etext>
    80001120:	4729                	li	a4,10
    80001122:	80006697          	auipc	a3,0x80006
    80001126:	ede68693          	addi	a3,a3,-290 # 7000 <_entry-0x7fff9000>
    8000112a:	4605                	li	a2,1
    8000112c:	067e                	slli	a2,a2,0x1f
    8000112e:	85b2                	mv	a1,a2
    80001130:	8526                	mv	a0,s1
    80001132:	f6dff0ef          	jal	8000109e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001136:	46c5                	li	a3,17
    80001138:	06ee                	slli	a3,a3,0x1b
    8000113a:	4719                	li	a4,6
    8000113c:	412686b3          	sub	a3,a3,s2
    80001140:	864a                	mv	a2,s2
    80001142:	85ca                	mv	a1,s2
    80001144:	8526                	mv	a0,s1
    80001146:	f59ff0ef          	jal	8000109e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000114a:	4729                	li	a4,10
    8000114c:	6685                	lui	a3,0x1
    8000114e:	00005617          	auipc	a2,0x5
    80001152:	eb260613          	addi	a2,a2,-334 # 80006000 <_trampoline>
    80001156:	040005b7          	lui	a1,0x4000
    8000115a:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    8000115c:	05b2                	slli	a1,a1,0xc
    8000115e:	8526                	mv	a0,s1
    80001160:	f3fff0ef          	jal	8000109e <kvmmap>
  proc_mapstacks(kpgtbl);
    80001164:	8526                	mv	a0,s1
    80001166:	5ee000ef          	jal	80001754 <proc_mapstacks>
}
    8000116a:	8526                	mv	a0,s1
    8000116c:	60e2                	ld	ra,24(sp)
    8000116e:	6442                	ld	s0,16(sp)
    80001170:	64a2                	ld	s1,8(sp)
    80001172:	6902                	ld	s2,0(sp)
    80001174:	6105                	addi	sp,sp,32
    80001176:	8082                	ret

0000000080001178 <kvminit>:
{
    80001178:	1141                	addi	sp,sp,-16
    8000117a:	e406                	sd	ra,8(sp)
    8000117c:	e022                	sd	s0,0(sp)
    8000117e:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001180:	f47ff0ef          	jal	800010c6 <kvmmake>
    80001184:	00009797          	auipc	a5,0x9
    80001188:	26a7b223          	sd	a0,612(a5) # 8000a3e8 <kernel_pagetable>
}
    8000118c:	60a2                	ld	ra,8(sp)
    8000118e:	6402                	ld	s0,0(sp)
    80001190:	0141                	addi	sp,sp,16
    80001192:	8082                	ret

0000000080001194 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001194:	1101                	addi	sp,sp,-32
    80001196:	ec06                	sd	ra,24(sp)
    80001198:	e822                	sd	s0,16(sp)
    8000119a:	e426                	sd	s1,8(sp)
    8000119c:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000119e:	961ff0ef          	jal	80000afe <kalloc>
    800011a2:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800011a4:	c509                	beqz	a0,800011ae <uvmcreate+0x1a>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800011a6:	6605                	lui	a2,0x1
    800011a8:	4581                	li	a1,0
    800011aa:	af9ff0ef          	jal	80000ca2 <memset>
  return pagetable;
}
    800011ae:	8526                	mv	a0,s1
    800011b0:	60e2                	ld	ra,24(sp)
    800011b2:	6442                	ld	s0,16(sp)
    800011b4:	64a2                	ld	s1,8(sp)
    800011b6:	6105                	addi	sp,sp,32
    800011b8:	8082                	ret

00000000800011ba <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. It's OK if the mappings don't exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800011ba:	7139                	addi	sp,sp,-64
    800011bc:	fc06                	sd	ra,56(sp)
    800011be:	f822                	sd	s0,48(sp)
    800011c0:	0080                	addi	s0,sp,64
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800011c2:	03459793          	slli	a5,a1,0x34
    800011c6:	e38d                	bnez	a5,800011e8 <uvmunmap+0x2e>
    800011c8:	f04a                	sd	s2,32(sp)
    800011ca:	ec4e                	sd	s3,24(sp)
    800011cc:	e852                	sd	s4,16(sp)
    800011ce:	e456                	sd	s5,8(sp)
    800011d0:	e05a                	sd	s6,0(sp)
    800011d2:	8a2a                	mv	s4,a0
    800011d4:	892e                	mv	s2,a1
    800011d6:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800011d8:	0632                	slli	a2,a2,0xc
    800011da:	00b609b3          	add	s3,a2,a1
    800011de:	6b05                	lui	s6,0x1
    800011e0:	0535f963          	bgeu	a1,s3,80001232 <uvmunmap+0x78>
    800011e4:	f426                	sd	s1,40(sp)
    800011e6:	a015                	j	8000120a <uvmunmap+0x50>
    800011e8:	f426                	sd	s1,40(sp)
    800011ea:	f04a                	sd	s2,32(sp)
    800011ec:	ec4e                	sd	s3,24(sp)
    800011ee:	e852                	sd	s4,16(sp)
    800011f0:	e456                	sd	s5,8(sp)
    800011f2:	e05a                	sd	s6,0(sp)
    panic("uvmunmap: not aligned");
    800011f4:	00006517          	auipc	a0,0x6
    800011f8:	f2450513          	addi	a0,a0,-220 # 80007118 <etext+0x118>
    800011fc:	de4ff0ef          	jal	800007e0 <panic>
      continue;
    if(do_free){
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
    80001200:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001204:	995a                	add	s2,s2,s6
    80001206:	03397563          	bgeu	s2,s3,80001230 <uvmunmap+0x76>
    if((pte = walk(pagetable, a, 0)) == 0) // leaf page table entry allocated?
    8000120a:	4601                	li	a2,0
    8000120c:	85ca                	mv	a1,s2
    8000120e:	8552                	mv	a0,s4
    80001210:	d07ff0ef          	jal	80000f16 <walk>
    80001214:	84aa                	mv	s1,a0
    80001216:	d57d                	beqz	a0,80001204 <uvmunmap+0x4a>
    if((*pte & PTE_V) == 0)  // has physical page been allocated?
    80001218:	611c                	ld	a5,0(a0)
    8000121a:	0017f713          	andi	a4,a5,1
    8000121e:	d37d                	beqz	a4,80001204 <uvmunmap+0x4a>
    if(do_free){
    80001220:	fe0a80e3          	beqz	s5,80001200 <uvmunmap+0x46>
      uint64 pa = PTE2PA(*pte);
    80001224:	83a9                	srli	a5,a5,0xa
      kfree((void*)pa);
    80001226:	00c79513          	slli	a0,a5,0xc
    8000122a:	ff2ff0ef          	jal	80000a1c <kfree>
    8000122e:	bfc9                	j	80001200 <uvmunmap+0x46>
    80001230:	74a2                	ld	s1,40(sp)
    80001232:	7902                	ld	s2,32(sp)
    80001234:	69e2                	ld	s3,24(sp)
    80001236:	6a42                	ld	s4,16(sp)
    80001238:	6aa2                	ld	s5,8(sp)
    8000123a:	6b02                	ld	s6,0(sp)
  }
}
    8000123c:	70e2                	ld	ra,56(sp)
    8000123e:	7442                	ld	s0,48(sp)
    80001240:	6121                	addi	sp,sp,64
    80001242:	8082                	ret

0000000080001244 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001244:	1101                	addi	sp,sp,-32
    80001246:	ec06                	sd	ra,24(sp)
    80001248:	e822                	sd	s0,16(sp)
    8000124a:	e426                	sd	s1,8(sp)
    8000124c:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000124e:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001250:	00b67d63          	bgeu	a2,a1,8000126a <uvmdealloc+0x26>
    80001254:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001256:	6785                	lui	a5,0x1
    80001258:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000125a:	00f60733          	add	a4,a2,a5
    8000125e:	76fd                	lui	a3,0xfffff
    80001260:	8f75                	and	a4,a4,a3
    80001262:	97ae                	add	a5,a5,a1
    80001264:	8ff5                	and	a5,a5,a3
    80001266:	00f76863          	bltu	a4,a5,80001276 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000126a:	8526                	mv	a0,s1
    8000126c:	60e2                	ld	ra,24(sp)
    8000126e:	6442                	ld	s0,16(sp)
    80001270:	64a2                	ld	s1,8(sp)
    80001272:	6105                	addi	sp,sp,32
    80001274:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001276:	8f99                	sub	a5,a5,a4
    80001278:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000127a:	4685                	li	a3,1
    8000127c:	0007861b          	sext.w	a2,a5
    80001280:	85ba                	mv	a1,a4
    80001282:	f39ff0ef          	jal	800011ba <uvmunmap>
    80001286:	b7d5                	j	8000126a <uvmdealloc+0x26>

0000000080001288 <uvmalloc>:
  if(newsz < oldsz)
    80001288:	08b66f63          	bltu	a2,a1,80001326 <uvmalloc+0x9e>
{
    8000128c:	7139                	addi	sp,sp,-64
    8000128e:	fc06                	sd	ra,56(sp)
    80001290:	f822                	sd	s0,48(sp)
    80001292:	ec4e                	sd	s3,24(sp)
    80001294:	e852                	sd	s4,16(sp)
    80001296:	e456                	sd	s5,8(sp)
    80001298:	0080                	addi	s0,sp,64
    8000129a:	8aaa                	mv	s5,a0
    8000129c:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000129e:	6785                	lui	a5,0x1
    800012a0:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800012a2:	95be                	add	a1,a1,a5
    800012a4:	77fd                	lui	a5,0xfffff
    800012a6:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    800012aa:	08c9f063          	bgeu	s3,a2,8000132a <uvmalloc+0xa2>
    800012ae:	f426                	sd	s1,40(sp)
    800012b0:	f04a                	sd	s2,32(sp)
    800012b2:	e05a                	sd	s6,0(sp)
    800012b4:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800012b6:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    800012ba:	845ff0ef          	jal	80000afe <kalloc>
    800012be:	84aa                	mv	s1,a0
    if(mem == 0){
    800012c0:	c515                	beqz	a0,800012ec <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    800012c2:	6605                	lui	a2,0x1
    800012c4:	4581                	li	a1,0
    800012c6:	9ddff0ef          	jal	80000ca2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800012ca:	875a                	mv	a4,s6
    800012cc:	86a6                	mv	a3,s1
    800012ce:	6605                	lui	a2,0x1
    800012d0:	85ca                	mv	a1,s2
    800012d2:	8556                	mv	a0,s5
    800012d4:	d1bff0ef          	jal	80000fee <mappages>
    800012d8:	e915                	bnez	a0,8000130c <uvmalloc+0x84>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800012da:	6785                	lui	a5,0x1
    800012dc:	993e                	add	s2,s2,a5
    800012de:	fd496ee3          	bltu	s2,s4,800012ba <uvmalloc+0x32>
  return newsz;
    800012e2:	8552                	mv	a0,s4
    800012e4:	74a2                	ld	s1,40(sp)
    800012e6:	7902                	ld	s2,32(sp)
    800012e8:	6b02                	ld	s6,0(sp)
    800012ea:	a811                	j	800012fe <uvmalloc+0x76>
      uvmdealloc(pagetable, a, oldsz);
    800012ec:	864e                	mv	a2,s3
    800012ee:	85ca                	mv	a1,s2
    800012f0:	8556                	mv	a0,s5
    800012f2:	f53ff0ef          	jal	80001244 <uvmdealloc>
      return 0;
    800012f6:	4501                	li	a0,0
    800012f8:	74a2                	ld	s1,40(sp)
    800012fa:	7902                	ld	s2,32(sp)
    800012fc:	6b02                	ld	s6,0(sp)
}
    800012fe:	70e2                	ld	ra,56(sp)
    80001300:	7442                	ld	s0,48(sp)
    80001302:	69e2                	ld	s3,24(sp)
    80001304:	6a42                	ld	s4,16(sp)
    80001306:	6aa2                	ld	s5,8(sp)
    80001308:	6121                	addi	sp,sp,64
    8000130a:	8082                	ret
      kfree(mem);
    8000130c:	8526                	mv	a0,s1
    8000130e:	f0eff0ef          	jal	80000a1c <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001312:	864e                	mv	a2,s3
    80001314:	85ca                	mv	a1,s2
    80001316:	8556                	mv	a0,s5
    80001318:	f2dff0ef          	jal	80001244 <uvmdealloc>
      return 0;
    8000131c:	4501                	li	a0,0
    8000131e:	74a2                	ld	s1,40(sp)
    80001320:	7902                	ld	s2,32(sp)
    80001322:	6b02                	ld	s6,0(sp)
    80001324:	bfe9                	j	800012fe <uvmalloc+0x76>
    return oldsz;
    80001326:	852e                	mv	a0,a1
}
    80001328:	8082                	ret
  return newsz;
    8000132a:	8532                	mv	a0,a2
    8000132c:	bfc9                	j	800012fe <uvmalloc+0x76>

000000008000132e <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000132e:	7179                	addi	sp,sp,-48
    80001330:	f406                	sd	ra,40(sp)
    80001332:	f022                	sd	s0,32(sp)
    80001334:	ec26                	sd	s1,24(sp)
    80001336:	e84a                	sd	s2,16(sp)
    80001338:	e44e                	sd	s3,8(sp)
    8000133a:	e052                	sd	s4,0(sp)
    8000133c:	1800                	addi	s0,sp,48
    8000133e:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001340:	84aa                	mv	s1,a0
    80001342:	6905                	lui	s2,0x1
    80001344:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001346:	4985                	li	s3,1
    80001348:	a819                	j	8000135e <freewalk+0x30>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    8000134a:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    8000134c:	00c79513          	slli	a0,a5,0xc
    80001350:	fdfff0ef          	jal	8000132e <freewalk>
      pagetable[i] = 0;
    80001354:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001358:	04a1                	addi	s1,s1,8
    8000135a:	01248f63          	beq	s1,s2,80001378 <freewalk+0x4a>
    pte_t pte = pagetable[i];
    8000135e:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001360:	00f7f713          	andi	a4,a5,15
    80001364:	ff3703e3          	beq	a4,s3,8000134a <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001368:	8b85                	andi	a5,a5,1
    8000136a:	d7fd                	beqz	a5,80001358 <freewalk+0x2a>
      panic("freewalk: leaf");
    8000136c:	00006517          	auipc	a0,0x6
    80001370:	dc450513          	addi	a0,a0,-572 # 80007130 <etext+0x130>
    80001374:	c6cff0ef          	jal	800007e0 <panic>
    }
  }
  kfree((void*)pagetable);
    80001378:	8552                	mv	a0,s4
    8000137a:	ea2ff0ef          	jal	80000a1c <kfree>
}
    8000137e:	70a2                	ld	ra,40(sp)
    80001380:	7402                	ld	s0,32(sp)
    80001382:	64e2                	ld	s1,24(sp)
    80001384:	6942                	ld	s2,16(sp)
    80001386:	69a2                	ld	s3,8(sp)
    80001388:	6a02                	ld	s4,0(sp)
    8000138a:	6145                	addi	sp,sp,48
    8000138c:	8082                	ret

000000008000138e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000138e:	1101                	addi	sp,sp,-32
    80001390:	ec06                	sd	ra,24(sp)
    80001392:	e822                	sd	s0,16(sp)
    80001394:	e426                	sd	s1,8(sp)
    80001396:	1000                	addi	s0,sp,32
    80001398:	84aa                	mv	s1,a0
  if(sz > 0)
    8000139a:	e989                	bnez	a1,800013ac <uvmfree+0x1e>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000139c:	8526                	mv	a0,s1
    8000139e:	f91ff0ef          	jal	8000132e <freewalk>
}
    800013a2:	60e2                	ld	ra,24(sp)
    800013a4:	6442                	ld	s0,16(sp)
    800013a6:	64a2                	ld	s1,8(sp)
    800013a8:	6105                	addi	sp,sp,32
    800013aa:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800013ac:	6785                	lui	a5,0x1
    800013ae:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013b0:	95be                	add	a1,a1,a5
    800013b2:	4685                	li	a3,1
    800013b4:	00c5d613          	srli	a2,a1,0xc
    800013b8:	4581                	li	a1,0
    800013ba:	e01ff0ef          	jal	800011ba <uvmunmap>
    800013be:	bff9                	j	8000139c <uvmfree+0xe>

00000000800013c0 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800013c0:	ce49                	beqz	a2,8000145a <uvmcopy+0x9a>
{
    800013c2:	715d                	addi	sp,sp,-80
    800013c4:	e486                	sd	ra,72(sp)
    800013c6:	e0a2                	sd	s0,64(sp)
    800013c8:	fc26                	sd	s1,56(sp)
    800013ca:	f84a                	sd	s2,48(sp)
    800013cc:	f44e                	sd	s3,40(sp)
    800013ce:	f052                	sd	s4,32(sp)
    800013d0:	ec56                	sd	s5,24(sp)
    800013d2:	e85a                	sd	s6,16(sp)
    800013d4:	e45e                	sd	s7,8(sp)
    800013d6:	0880                	addi	s0,sp,80
    800013d8:	8aaa                	mv	s5,a0
    800013da:	8b2e                	mv	s6,a1
    800013dc:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800013de:	4481                	li	s1,0
    800013e0:	a029                	j	800013ea <uvmcopy+0x2a>
    800013e2:	6785                	lui	a5,0x1
    800013e4:	94be                	add	s1,s1,a5
    800013e6:	0544fe63          	bgeu	s1,s4,80001442 <uvmcopy+0x82>
    if((pte = walk(old, i, 0)) == 0)
    800013ea:	4601                	li	a2,0
    800013ec:	85a6                	mv	a1,s1
    800013ee:	8556                	mv	a0,s5
    800013f0:	b27ff0ef          	jal	80000f16 <walk>
    800013f4:	d57d                	beqz	a0,800013e2 <uvmcopy+0x22>
      continue;   // page table entry hasn't been allocated
    if((*pte & PTE_V) == 0)
    800013f6:	6118                	ld	a4,0(a0)
    800013f8:	00177793          	andi	a5,a4,1
    800013fc:	d3fd                	beqz	a5,800013e2 <uvmcopy+0x22>
      continue;   // physical page hasn't been allocated
    pa = PTE2PA(*pte);
    800013fe:	00a75593          	srli	a1,a4,0xa
    80001402:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001406:	3ff77913          	andi	s2,a4,1023
    if((mem = kalloc()) == 0)
    8000140a:	ef4ff0ef          	jal	80000afe <kalloc>
    8000140e:	89aa                	mv	s3,a0
    80001410:	c105                	beqz	a0,80001430 <uvmcopy+0x70>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001412:	6605                	lui	a2,0x1
    80001414:	85de                	mv	a1,s7
    80001416:	8e9ff0ef          	jal	80000cfe <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000141a:	874a                	mv	a4,s2
    8000141c:	86ce                	mv	a3,s3
    8000141e:	6605                	lui	a2,0x1
    80001420:	85a6                	mv	a1,s1
    80001422:	855a                	mv	a0,s6
    80001424:	bcbff0ef          	jal	80000fee <mappages>
    80001428:	dd4d                	beqz	a0,800013e2 <uvmcopy+0x22>
      kfree(mem);
    8000142a:	854e                	mv	a0,s3
    8000142c:	df0ff0ef          	jal	80000a1c <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001430:	4685                	li	a3,1
    80001432:	00c4d613          	srli	a2,s1,0xc
    80001436:	4581                	li	a1,0
    80001438:	855a                	mv	a0,s6
    8000143a:	d81ff0ef          	jal	800011ba <uvmunmap>
  return -1;
    8000143e:	557d                	li	a0,-1
    80001440:	a011                	j	80001444 <uvmcopy+0x84>
  return 0;
    80001442:	4501                	li	a0,0
}
    80001444:	60a6                	ld	ra,72(sp)
    80001446:	6406                	ld	s0,64(sp)
    80001448:	74e2                	ld	s1,56(sp)
    8000144a:	7942                	ld	s2,48(sp)
    8000144c:	79a2                	ld	s3,40(sp)
    8000144e:	7a02                	ld	s4,32(sp)
    80001450:	6ae2                	ld	s5,24(sp)
    80001452:	6b42                	ld	s6,16(sp)
    80001454:	6ba2                	ld	s7,8(sp)
    80001456:	6161                	addi	sp,sp,80
    80001458:	8082                	ret
  return 0;
    8000145a:	4501                	li	a0,0
}
    8000145c:	8082                	ret

000000008000145e <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000145e:	1141                	addi	sp,sp,-16
    80001460:	e406                	sd	ra,8(sp)
    80001462:	e022                	sd	s0,0(sp)
    80001464:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001466:	4601                	li	a2,0
    80001468:	aafff0ef          	jal	80000f16 <walk>
  if(pte == 0)
    8000146c:	c901                	beqz	a0,8000147c <uvmclear+0x1e>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000146e:	611c                	ld	a5,0(a0)
    80001470:	9bbd                	andi	a5,a5,-17
    80001472:	e11c                	sd	a5,0(a0)
}
    80001474:	60a2                	ld	ra,8(sp)
    80001476:	6402                	ld	s0,0(sp)
    80001478:	0141                	addi	sp,sp,16
    8000147a:	8082                	ret
    panic("uvmclear");
    8000147c:	00006517          	auipc	a0,0x6
    80001480:	cc450513          	addi	a0,a0,-828 # 80007140 <etext+0x140>
    80001484:	b5cff0ef          	jal	800007e0 <panic>

0000000080001488 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001488:	c6dd                	beqz	a3,80001536 <copyinstr+0xae>
{
    8000148a:	715d                	addi	sp,sp,-80
    8000148c:	e486                	sd	ra,72(sp)
    8000148e:	e0a2                	sd	s0,64(sp)
    80001490:	fc26                	sd	s1,56(sp)
    80001492:	f84a                	sd	s2,48(sp)
    80001494:	f44e                	sd	s3,40(sp)
    80001496:	f052                	sd	s4,32(sp)
    80001498:	ec56                	sd	s5,24(sp)
    8000149a:	e85a                	sd	s6,16(sp)
    8000149c:	e45e                	sd	s7,8(sp)
    8000149e:	0880                	addi	s0,sp,80
    800014a0:	8a2a                	mv	s4,a0
    800014a2:	8b2e                	mv	s6,a1
    800014a4:	8bb2                	mv	s7,a2
    800014a6:	8936                	mv	s2,a3
    va0 = PGROUNDDOWN(srcva);
    800014a8:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800014aa:	6985                	lui	s3,0x1
    800014ac:	a825                	j	800014e4 <copyinstr+0x5c>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800014ae:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800014b2:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800014b4:	37fd                	addiw	a5,a5,-1
    800014b6:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800014ba:	60a6                	ld	ra,72(sp)
    800014bc:	6406                	ld	s0,64(sp)
    800014be:	74e2                	ld	s1,56(sp)
    800014c0:	7942                	ld	s2,48(sp)
    800014c2:	79a2                	ld	s3,40(sp)
    800014c4:	7a02                	ld	s4,32(sp)
    800014c6:	6ae2                	ld	s5,24(sp)
    800014c8:	6b42                	ld	s6,16(sp)
    800014ca:	6ba2                	ld	s7,8(sp)
    800014cc:	6161                	addi	sp,sp,80
    800014ce:	8082                	ret
    800014d0:	fff90713          	addi	a4,s2,-1 # fff <_entry-0x7ffff001>
    800014d4:	9742                	add	a4,a4,a6
      --max;
    800014d6:	40b70933          	sub	s2,a4,a1
    srcva = va0 + PGSIZE;
    800014da:	01348bb3          	add	s7,s1,s3
  while(got_null == 0 && max > 0){
    800014de:	04e58463          	beq	a1,a4,80001526 <copyinstr+0x9e>
{
    800014e2:	8b3e                	mv	s6,a5
    va0 = PGROUNDDOWN(srcva);
    800014e4:	015bf4b3          	and	s1,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800014e8:	85a6                	mv	a1,s1
    800014ea:	8552                	mv	a0,s4
    800014ec:	ac5ff0ef          	jal	80000fb0 <walkaddr>
    if(pa0 == 0)
    800014f0:	cd0d                	beqz	a0,8000152a <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800014f2:	417486b3          	sub	a3,s1,s7
    800014f6:	96ce                	add	a3,a3,s3
    if(n > max)
    800014f8:	00d97363          	bgeu	s2,a3,800014fe <copyinstr+0x76>
    800014fc:	86ca                	mv	a3,s2
    char *p = (char *) (pa0 + (srcva - va0));
    800014fe:	955e                	add	a0,a0,s7
    80001500:	8d05                	sub	a0,a0,s1
    while(n > 0){
    80001502:	c695                	beqz	a3,8000152e <copyinstr+0xa6>
    80001504:	87da                	mv	a5,s6
    80001506:	885a                	mv	a6,s6
      if(*p == '\0'){
    80001508:	41650633          	sub	a2,a0,s6
    while(n > 0){
    8000150c:	96da                	add	a3,a3,s6
    8000150e:	85be                	mv	a1,a5
      if(*p == '\0'){
    80001510:	00f60733          	add	a4,a2,a5
    80001514:	00074703          	lbu	a4,0(a4)
    80001518:	db59                	beqz	a4,800014ae <copyinstr+0x26>
        *dst = *p;
    8000151a:	00e78023          	sb	a4,0(a5)
      dst++;
    8000151e:	0785                	addi	a5,a5,1
    while(n > 0){
    80001520:	fed797e3          	bne	a5,a3,8000150e <copyinstr+0x86>
    80001524:	b775                	j	800014d0 <copyinstr+0x48>
    80001526:	4781                	li	a5,0
    80001528:	b771                	j	800014b4 <copyinstr+0x2c>
      return -1;
    8000152a:	557d                	li	a0,-1
    8000152c:	b779                	j	800014ba <copyinstr+0x32>
    srcva = va0 + PGSIZE;
    8000152e:	6b85                	lui	s7,0x1
    80001530:	9ba6                	add	s7,s7,s1
    80001532:	87da                	mv	a5,s6
    80001534:	b77d                	j	800014e2 <copyinstr+0x5a>
  int got_null = 0;
    80001536:	4781                	li	a5,0
  if(got_null){
    80001538:	37fd                	addiw	a5,a5,-1
    8000153a:	0007851b          	sext.w	a0,a5
}
    8000153e:	8082                	ret

0000000080001540 <ismapped>:
  return mem;
}

int
ismapped(pagetable_t pagetable, uint64 va)
{
    80001540:	1141                	addi	sp,sp,-16
    80001542:	e406                	sd	ra,8(sp)
    80001544:	e022                	sd	s0,0(sp)
    80001546:	0800                	addi	s0,sp,16
  pte_t *pte = walk(pagetable, va, 0);
    80001548:	4601                	li	a2,0
    8000154a:	9cdff0ef          	jal	80000f16 <walk>
  if (pte == 0) {
    8000154e:	c519                	beqz	a0,8000155c <ismapped+0x1c>
    return 0;
  }
  if (*pte & PTE_V){
    80001550:	6108                	ld	a0,0(a0)
    80001552:	8905                	andi	a0,a0,1
    return 1;
  }
  return 0;
}
    80001554:	60a2                	ld	ra,8(sp)
    80001556:	6402                	ld	s0,0(sp)
    80001558:	0141                	addi	sp,sp,16
    8000155a:	8082                	ret
    return 0;
    8000155c:	4501                	li	a0,0
    8000155e:	bfdd                	j	80001554 <ismapped+0x14>

0000000080001560 <vmfault>:
{
    80001560:	7179                	addi	sp,sp,-48
    80001562:	f406                	sd	ra,40(sp)
    80001564:	f022                	sd	s0,32(sp)
    80001566:	ec26                	sd	s1,24(sp)
    80001568:	e44e                	sd	s3,8(sp)
    8000156a:	1800                	addi	s0,sp,48
    8000156c:	89aa                	mv	s3,a0
    8000156e:	84ae                	mv	s1,a1
  struct proc *p = myproc();
    80001570:	39e000ef          	jal	8000190e <myproc>
  if (va >= p->sz)
    80001574:	653c                	ld	a5,72(a0)
    80001576:	00f4ea63          	bltu	s1,a5,8000158a <vmfault+0x2a>
    return 0;
    8000157a:	4981                	li	s3,0
}
    8000157c:	854e                	mv	a0,s3
    8000157e:	70a2                	ld	ra,40(sp)
    80001580:	7402                	ld	s0,32(sp)
    80001582:	64e2                	ld	s1,24(sp)
    80001584:	69a2                	ld	s3,8(sp)
    80001586:	6145                	addi	sp,sp,48
    80001588:	8082                	ret
    8000158a:	e84a                	sd	s2,16(sp)
    8000158c:	892a                	mv	s2,a0
  va = PGROUNDDOWN(va);
    8000158e:	77fd                	lui	a5,0xfffff
    80001590:	8cfd                	and	s1,s1,a5
  if(ismapped(pagetable, va)) {
    80001592:	85a6                	mv	a1,s1
    80001594:	854e                	mv	a0,s3
    80001596:	fabff0ef          	jal	80001540 <ismapped>
    return 0;
    8000159a:	4981                	li	s3,0
  if(ismapped(pagetable, va)) {
    8000159c:	c119                	beqz	a0,800015a2 <vmfault+0x42>
    8000159e:	6942                	ld	s2,16(sp)
    800015a0:	bff1                	j	8000157c <vmfault+0x1c>
    800015a2:	e052                	sd	s4,0(sp)
  mem = (uint64) kalloc();
    800015a4:	d5aff0ef          	jal	80000afe <kalloc>
    800015a8:	8a2a                	mv	s4,a0
  if(mem == 0)
    800015aa:	c90d                	beqz	a0,800015dc <vmfault+0x7c>
  mem = (uint64) kalloc();
    800015ac:	89aa                	mv	s3,a0
  memset((void *) mem, 0, PGSIZE);
    800015ae:	6605                	lui	a2,0x1
    800015b0:	4581                	li	a1,0
    800015b2:	ef0ff0ef          	jal	80000ca2 <memset>
  if (mappages(p->pagetable, va, PGSIZE, mem, PTE_W|PTE_U|PTE_R) != 0) {
    800015b6:	4759                	li	a4,22
    800015b8:	86d2                	mv	a3,s4
    800015ba:	6605                	lui	a2,0x1
    800015bc:	85a6                	mv	a1,s1
    800015be:	05093503          	ld	a0,80(s2)
    800015c2:	a2dff0ef          	jal	80000fee <mappages>
    800015c6:	e501                	bnez	a0,800015ce <vmfault+0x6e>
    800015c8:	6942                	ld	s2,16(sp)
    800015ca:	6a02                	ld	s4,0(sp)
    800015cc:	bf45                	j	8000157c <vmfault+0x1c>
    kfree((void *)mem);
    800015ce:	8552                	mv	a0,s4
    800015d0:	c4cff0ef          	jal	80000a1c <kfree>
    return 0;
    800015d4:	4981                	li	s3,0
    800015d6:	6942                	ld	s2,16(sp)
    800015d8:	6a02                	ld	s4,0(sp)
    800015da:	b74d                	j	8000157c <vmfault+0x1c>
    800015dc:	6942                	ld	s2,16(sp)
    800015de:	6a02                	ld	s4,0(sp)
    800015e0:	bf71                	j	8000157c <vmfault+0x1c>

00000000800015e2 <copyout>:
  while(len > 0){
    800015e2:	c2cd                	beqz	a3,80001684 <copyout+0xa2>
{
    800015e4:	711d                	addi	sp,sp,-96
    800015e6:	ec86                	sd	ra,88(sp)
    800015e8:	e8a2                	sd	s0,80(sp)
    800015ea:	e4a6                	sd	s1,72(sp)
    800015ec:	f852                	sd	s4,48(sp)
    800015ee:	f05a                	sd	s6,32(sp)
    800015f0:	ec5e                	sd	s7,24(sp)
    800015f2:	e862                	sd	s8,16(sp)
    800015f4:	1080                	addi	s0,sp,96
    800015f6:	8c2a                	mv	s8,a0
    800015f8:	8b2e                	mv	s6,a1
    800015fa:	8bb2                	mv	s7,a2
    800015fc:	8a36                	mv	s4,a3
    va0 = PGROUNDDOWN(dstva);
    800015fe:	74fd                	lui	s1,0xfffff
    80001600:	8ced                	and	s1,s1,a1
    if(va0 >= MAXVA)
    80001602:	57fd                	li	a5,-1
    80001604:	83e9                	srli	a5,a5,0x1a
    80001606:	0897e163          	bltu	a5,s1,80001688 <copyout+0xa6>
    8000160a:	e0ca                	sd	s2,64(sp)
    8000160c:	fc4e                	sd	s3,56(sp)
    8000160e:	f456                	sd	s5,40(sp)
    80001610:	e466                	sd	s9,8(sp)
    80001612:	e06a                	sd	s10,0(sp)
    80001614:	6d05                	lui	s10,0x1
    80001616:	8cbe                	mv	s9,a5
    80001618:	a015                	j	8000163c <copyout+0x5a>
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000161a:	409b0533          	sub	a0,s6,s1
    8000161e:	0009861b          	sext.w	a2,s3
    80001622:	85de                	mv	a1,s7
    80001624:	954a                	add	a0,a0,s2
    80001626:	ed8ff0ef          	jal	80000cfe <memmove>
    len -= n;
    8000162a:	413a0a33          	sub	s4,s4,s3
    src += n;
    8000162e:	9bce                	add	s7,s7,s3
  while(len > 0){
    80001630:	040a0363          	beqz	s4,80001676 <copyout+0x94>
    if(va0 >= MAXVA)
    80001634:	055cec63          	bltu	s9,s5,8000168c <copyout+0xaa>
    80001638:	84d6                	mv	s1,s5
    8000163a:	8b56                	mv	s6,s5
    pa0 = walkaddr(pagetable, va0);
    8000163c:	85a6                	mv	a1,s1
    8000163e:	8562                	mv	a0,s8
    80001640:	971ff0ef          	jal	80000fb0 <walkaddr>
    80001644:	892a                	mv	s2,a0
    if(pa0 == 0) {
    80001646:	e901                	bnez	a0,80001656 <copyout+0x74>
      if((pa0 = vmfault(pagetable, va0, 0)) == 0) {
    80001648:	4601                	li	a2,0
    8000164a:	85a6                	mv	a1,s1
    8000164c:	8562                	mv	a0,s8
    8000164e:	f13ff0ef          	jal	80001560 <vmfault>
    80001652:	892a                	mv	s2,a0
    80001654:	c139                	beqz	a0,8000169a <copyout+0xb8>
    pte = walk(pagetable, va0, 0);
    80001656:	4601                	li	a2,0
    80001658:	85a6                	mv	a1,s1
    8000165a:	8562                	mv	a0,s8
    8000165c:	8bbff0ef          	jal	80000f16 <walk>
    if((*pte & PTE_W) == 0)
    80001660:	611c                	ld	a5,0(a0)
    80001662:	8b91                	andi	a5,a5,4
    80001664:	c3b1                	beqz	a5,800016a8 <copyout+0xc6>
    n = PGSIZE - (dstva - va0);
    80001666:	01a48ab3          	add	s5,s1,s10
    8000166a:	416a89b3          	sub	s3,s5,s6
    if(n > len)
    8000166e:	fb3a76e3          	bgeu	s4,s3,8000161a <copyout+0x38>
    80001672:	89d2                	mv	s3,s4
    80001674:	b75d                	j	8000161a <copyout+0x38>
  return 0;
    80001676:	4501                	li	a0,0
    80001678:	6906                	ld	s2,64(sp)
    8000167a:	79e2                	ld	s3,56(sp)
    8000167c:	7aa2                	ld	s5,40(sp)
    8000167e:	6ca2                	ld	s9,8(sp)
    80001680:	6d02                	ld	s10,0(sp)
    80001682:	a80d                	j	800016b4 <copyout+0xd2>
    80001684:	4501                	li	a0,0
}
    80001686:	8082                	ret
      return -1;
    80001688:	557d                	li	a0,-1
    8000168a:	a02d                	j	800016b4 <copyout+0xd2>
    8000168c:	557d                	li	a0,-1
    8000168e:	6906                	ld	s2,64(sp)
    80001690:	79e2                	ld	s3,56(sp)
    80001692:	7aa2                	ld	s5,40(sp)
    80001694:	6ca2                	ld	s9,8(sp)
    80001696:	6d02                	ld	s10,0(sp)
    80001698:	a831                	j	800016b4 <copyout+0xd2>
        return -1;
    8000169a:	557d                	li	a0,-1
    8000169c:	6906                	ld	s2,64(sp)
    8000169e:	79e2                	ld	s3,56(sp)
    800016a0:	7aa2                	ld	s5,40(sp)
    800016a2:	6ca2                	ld	s9,8(sp)
    800016a4:	6d02                	ld	s10,0(sp)
    800016a6:	a039                	j	800016b4 <copyout+0xd2>
      return -1;
    800016a8:	557d                	li	a0,-1
    800016aa:	6906                	ld	s2,64(sp)
    800016ac:	79e2                	ld	s3,56(sp)
    800016ae:	7aa2                	ld	s5,40(sp)
    800016b0:	6ca2                	ld	s9,8(sp)
    800016b2:	6d02                	ld	s10,0(sp)
}
    800016b4:	60e6                	ld	ra,88(sp)
    800016b6:	6446                	ld	s0,80(sp)
    800016b8:	64a6                	ld	s1,72(sp)
    800016ba:	7a42                	ld	s4,48(sp)
    800016bc:	7b02                	ld	s6,32(sp)
    800016be:	6be2                	ld	s7,24(sp)
    800016c0:	6c42                	ld	s8,16(sp)
    800016c2:	6125                	addi	sp,sp,96
    800016c4:	8082                	ret

00000000800016c6 <copyin>:
  while(len > 0){
    800016c6:	c6c9                	beqz	a3,80001750 <copyin+0x8a>
{
    800016c8:	715d                	addi	sp,sp,-80
    800016ca:	e486                	sd	ra,72(sp)
    800016cc:	e0a2                	sd	s0,64(sp)
    800016ce:	fc26                	sd	s1,56(sp)
    800016d0:	f84a                	sd	s2,48(sp)
    800016d2:	f44e                	sd	s3,40(sp)
    800016d4:	f052                	sd	s4,32(sp)
    800016d6:	ec56                	sd	s5,24(sp)
    800016d8:	e85a                	sd	s6,16(sp)
    800016da:	e45e                	sd	s7,8(sp)
    800016dc:	e062                	sd	s8,0(sp)
    800016de:	0880                	addi	s0,sp,80
    800016e0:	8baa                	mv	s7,a0
    800016e2:	8aae                	mv	s5,a1
    800016e4:	8932                	mv	s2,a2
    800016e6:	8a36                	mv	s4,a3
    va0 = PGROUNDDOWN(srcva);
    800016e8:	7c7d                	lui	s8,0xfffff
    n = PGSIZE - (srcva - va0);
    800016ea:	6b05                	lui	s6,0x1
    800016ec:	a035                	j	80001718 <copyin+0x52>
    800016ee:	412984b3          	sub	s1,s3,s2
    800016f2:	94da                	add	s1,s1,s6
    if(n > len)
    800016f4:	009a7363          	bgeu	s4,s1,800016fa <copyin+0x34>
    800016f8:	84d2                	mv	s1,s4
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800016fa:	413905b3          	sub	a1,s2,s3
    800016fe:	0004861b          	sext.w	a2,s1
    80001702:	95aa                	add	a1,a1,a0
    80001704:	8556                	mv	a0,s5
    80001706:	df8ff0ef          	jal	80000cfe <memmove>
    len -= n;
    8000170a:	409a0a33          	sub	s4,s4,s1
    dst += n;
    8000170e:	9aa6                	add	s5,s5,s1
    srcva = va0 + PGSIZE;
    80001710:	01698933          	add	s2,s3,s6
  while(len > 0){
    80001714:	020a0163          	beqz	s4,80001736 <copyin+0x70>
    va0 = PGROUNDDOWN(srcva);
    80001718:	018979b3          	and	s3,s2,s8
    pa0 = walkaddr(pagetable, va0);
    8000171c:	85ce                	mv	a1,s3
    8000171e:	855e                	mv	a0,s7
    80001720:	891ff0ef          	jal	80000fb0 <walkaddr>
    if(pa0 == 0) {
    80001724:	f569                	bnez	a0,800016ee <copyin+0x28>
      if((pa0 = vmfault(pagetable, va0, 0)) == 0) {
    80001726:	4601                	li	a2,0
    80001728:	85ce                	mv	a1,s3
    8000172a:	855e                	mv	a0,s7
    8000172c:	e35ff0ef          	jal	80001560 <vmfault>
    80001730:	fd5d                	bnez	a0,800016ee <copyin+0x28>
        return -1;
    80001732:	557d                	li	a0,-1
    80001734:	a011                	j	80001738 <copyin+0x72>
  return 0;
    80001736:	4501                	li	a0,0
}
    80001738:	60a6                	ld	ra,72(sp)
    8000173a:	6406                	ld	s0,64(sp)
    8000173c:	74e2                	ld	s1,56(sp)
    8000173e:	7942                	ld	s2,48(sp)
    80001740:	79a2                	ld	s3,40(sp)
    80001742:	7a02                	ld	s4,32(sp)
    80001744:	6ae2                	ld	s5,24(sp)
    80001746:	6b42                	ld	s6,16(sp)
    80001748:	6ba2                	ld	s7,8(sp)
    8000174a:	6c02                	ld	s8,0(sp)
    8000174c:	6161                	addi	sp,sp,80
    8000174e:	8082                	ret
  return 0;
    80001750:	4501                	li	a0,0
}
    80001752:	8082                	ret

0000000080001754 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001754:	7139                	addi	sp,sp,-64
    80001756:	fc06                	sd	ra,56(sp)
    80001758:	f822                	sd	s0,48(sp)
    8000175a:	f426                	sd	s1,40(sp)
    8000175c:	f04a                	sd	s2,32(sp)
    8000175e:	ec4e                	sd	s3,24(sp)
    80001760:	e852                	sd	s4,16(sp)
    80001762:	e456                	sd	s5,8(sp)
    80001764:	e05a                	sd	s6,0(sp)
    80001766:	0080                	addi	s0,sp,64
    80001768:	8a2a                	mv	s4,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    8000176a:	00011497          	auipc	s1,0x11
    8000176e:	20e48493          	addi	s1,s1,526 # 80012978 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001772:	8b26                	mv	s6,s1
    80001774:	04ec5937          	lui	s2,0x4ec5
    80001778:	ec590913          	addi	s2,s2,-315 # 4ec4ec5 <_entry-0x7b13b13b>
    8000177c:	0932                	slli	s2,s2,0xc
    8000177e:	ec590913          	addi	s2,s2,-315
    80001782:	0932                	slli	s2,s2,0xc
    80001784:	ec590913          	addi	s2,s2,-315
    80001788:	0932                	slli	s2,s2,0xc
    8000178a:	ec590913          	addi	s2,s2,-315
    8000178e:	040009b7          	lui	s3,0x4000
    80001792:	19fd                	addi	s3,s3,-1 # 3ffffff <_entry-0x7c000001>
    80001794:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001796:	00018a97          	auipc	s5,0x18
    8000179a:	9e2a8a93          	addi	s5,s5,-1566 # 80019178 <tickslock>
    char *pa = kalloc();
    8000179e:	b60ff0ef          	jal	80000afe <kalloc>
    800017a2:	862a                	mv	a2,a0
    if(pa == 0)
    800017a4:	cd15                	beqz	a0,800017e0 <proc_mapstacks+0x8c>
    uint64 va = KSTACK((int) (p - proc));
    800017a6:	416485b3          	sub	a1,s1,s6
    800017aa:	8595                	srai	a1,a1,0x5
    800017ac:	032585b3          	mul	a1,a1,s2
    800017b0:	2585                	addiw	a1,a1,1
    800017b2:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800017b6:	4719                	li	a4,6
    800017b8:	6685                	lui	a3,0x1
    800017ba:	40b985b3          	sub	a1,s3,a1
    800017be:	8552                	mv	a0,s4
    800017c0:	8dfff0ef          	jal	8000109e <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800017c4:	1a048493          	addi	s1,s1,416
    800017c8:	fd549be3          	bne	s1,s5,8000179e <proc_mapstacks+0x4a>
  }
}
    800017cc:	70e2                	ld	ra,56(sp)
    800017ce:	7442                	ld	s0,48(sp)
    800017d0:	74a2                	ld	s1,40(sp)
    800017d2:	7902                	ld	s2,32(sp)
    800017d4:	69e2                	ld	s3,24(sp)
    800017d6:	6a42                	ld	s4,16(sp)
    800017d8:	6aa2                	ld	s5,8(sp)
    800017da:	6b02                	ld	s6,0(sp)
    800017dc:	6121                	addi	sp,sp,64
    800017de:	8082                	ret
      panic("kalloc");
    800017e0:	00006517          	auipc	a0,0x6
    800017e4:	97050513          	addi	a0,a0,-1680 # 80007150 <etext+0x150>
    800017e8:	ff9fe0ef          	jal	800007e0 <panic>

00000000800017ec <procinit>:

// initialize the proc table.
void
procinit(void)
{
    800017ec:	7139                	addi	sp,sp,-64
    800017ee:	fc06                	sd	ra,56(sp)
    800017f0:	f822                	sd	s0,48(sp)
    800017f2:	f426                	sd	s1,40(sp)
    800017f4:	f04a                	sd	s2,32(sp)
    800017f6:	ec4e                	sd	s3,24(sp)
    800017f8:	e852                	sd	s4,16(sp)
    800017fa:	e456                	sd	s5,8(sp)
    800017fc:	e05a                	sd	s6,0(sp)
    800017fe:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001800:	00006597          	auipc	a1,0x6
    80001804:	95858593          	addi	a1,a1,-1704 # 80007158 <etext+0x158>
    80001808:	00011517          	auipc	a0,0x11
    8000180c:	d1050513          	addi	a0,a0,-752 # 80012518 <pid_lock>
    80001810:	b3eff0ef          	jal	80000b4e <initlock>
  initlock(&wait_lock, "wait_lock");
    80001814:	00006597          	auipc	a1,0x6
    80001818:	94c58593          	addi	a1,a1,-1716 # 80007160 <etext+0x160>
    8000181c:	00011517          	auipc	a0,0x11
    80001820:	d1450513          	addi	a0,a0,-748 # 80012530 <wait_lock>
    80001824:	b2aff0ef          	jal	80000b4e <initlock>
  initlock(&vruntime_lock, "vruntime"); 
    80001828:	00006597          	auipc	a1,0x6
    8000182c:	94858593          	addi	a1,a1,-1720 # 80007170 <etext+0x170>
    80001830:	00011517          	auipc	a0,0x11
    80001834:	d1850513          	addi	a0,a0,-744 # 80012548 <vruntime_lock>
    80001838:	b16ff0ef          	jal	80000b4e <initlock>
  initlock(&run_queue_lock, "run_queue"); // Add this line
    8000183c:	00006597          	auipc	a1,0x6
    80001840:	94458593          	addi	a1,a1,-1724 # 80007180 <etext+0x180>
    80001844:	00011517          	auipc	a0,0x11
    80001848:	d1c50513          	addi	a0,a0,-740 # 80012560 <run_queue_lock>
    8000184c:	b02ff0ef          	jal	80000b4e <initlock>
  run_queue = 0; // Initialize the run queue
    80001850:	00009797          	auipc	a5,0x9
    80001854:	ba07b023          	sd	zero,-1120(a5) # 8000a3f0 <run_queue>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001858:	00011497          	auipc	s1,0x11
    8000185c:	12048493          	addi	s1,s1,288 # 80012978 <proc>
      initlock(&p->lock, "proc");
    80001860:	00006b17          	auipc	s6,0x6
    80001864:	930b0b13          	addi	s6,s6,-1744 # 80007190 <etext+0x190>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001868:	8aa6                	mv	s5,s1
    8000186a:	04ec5937          	lui	s2,0x4ec5
    8000186e:	ec590913          	addi	s2,s2,-315 # 4ec4ec5 <_entry-0x7b13b13b>
    80001872:	0932                	slli	s2,s2,0xc
    80001874:	ec590913          	addi	s2,s2,-315
    80001878:	0932                	slli	s2,s2,0xc
    8000187a:	ec590913          	addi	s2,s2,-315
    8000187e:	0932                	slli	s2,s2,0xc
    80001880:	ec590913          	addi	s2,s2,-315
    80001884:	040009b7          	lui	s3,0x4000
    80001888:	19fd                	addi	s3,s3,-1 # 3ffffff <_entry-0x7c000001>
    8000188a:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000188c:	00018a17          	auipc	s4,0x18
    80001890:	8eca0a13          	addi	s4,s4,-1812 # 80019178 <tickslock>
      initlock(&p->lock, "proc");
    80001894:	85da                	mv	a1,s6
    80001896:	8526                	mv	a0,s1
    80001898:	ab6ff0ef          	jal	80000b4e <initlock>
      p->state = UNUSED;
    8000189c:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    800018a0:	415487b3          	sub	a5,s1,s5
    800018a4:	8795                	srai	a5,a5,0x5
    800018a6:	032787b3          	mul	a5,a5,s2
    800018aa:	2785                	addiw	a5,a5,1
    800018ac:	00d7979b          	slliw	a5,a5,0xd
    800018b0:	40f987b3          	sub	a5,s3,a5
    800018b4:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    800018b6:	1a048493          	addi	s1,s1,416
    800018ba:	fd449de3          	bne	s1,s4,80001894 <procinit+0xa8>
  }
  // Initialize last boost tick to current ticks to avoid immediate boost
  last_boost_tick = ticks;
    800018be:	00009797          	auipc	a5,0x9
    800018c2:	b4e7a783          	lw	a5,-1202(a5) # 8000a40c <ticks>
    800018c6:	00009717          	auipc	a4,0x9
    800018ca:	b4f72123          	sw	a5,-1214(a4) # 8000a408 <last_boost_tick>
}
    800018ce:	70e2                	ld	ra,56(sp)
    800018d0:	7442                	ld	s0,48(sp)
    800018d2:	74a2                	ld	s1,40(sp)
    800018d4:	7902                	ld	s2,32(sp)
    800018d6:	69e2                	ld	s3,24(sp)
    800018d8:	6a42                	ld	s4,16(sp)
    800018da:	6aa2                	ld	s5,8(sp)
    800018dc:	6b02                	ld	s6,0(sp)
    800018de:	6121                	addi	sp,sp,64
    800018e0:	8082                	ret

00000000800018e2 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800018e2:	1141                	addi	sp,sp,-16
    800018e4:	e422                	sd	s0,8(sp)
    800018e6:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800018e8:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800018ea:	2501                	sext.w	a0,a0
    800018ec:	6422                	ld	s0,8(sp)
    800018ee:	0141                	addi	sp,sp,16
    800018f0:	8082                	ret

00000000800018f2 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    800018f2:	1141                	addi	sp,sp,-16
    800018f4:	e422                	sd	s0,8(sp)
    800018f6:	0800                	addi	s0,sp,16
    800018f8:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800018fa:	2781                	sext.w	a5,a5
    800018fc:	079e                	slli	a5,a5,0x7
  return c;
}
    800018fe:	00011517          	auipc	a0,0x11
    80001902:	c7a50513          	addi	a0,a0,-902 # 80012578 <cpus>
    80001906:	953e                	add	a0,a0,a5
    80001908:	6422                	ld	s0,8(sp)
    8000190a:	0141                	addi	sp,sp,16
    8000190c:	8082                	ret

000000008000190e <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    8000190e:	1101                	addi	sp,sp,-32
    80001910:	ec06                	sd	ra,24(sp)
    80001912:	e822                	sd	s0,16(sp)
    80001914:	e426                	sd	s1,8(sp)
    80001916:	1000                	addi	s0,sp,32
  push_off();
    80001918:	a76ff0ef          	jal	80000b8e <push_off>
    8000191c:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    8000191e:	2781                	sext.w	a5,a5
    80001920:	079e                	slli	a5,a5,0x7
    80001922:	00011717          	auipc	a4,0x11
    80001926:	bf670713          	addi	a4,a4,-1034 # 80012518 <pid_lock>
    8000192a:	97ba                	add	a5,a5,a4
    8000192c:	73a4                	ld	s1,96(a5)
  pop_off();
    8000192e:	ae4ff0ef          	jal	80000c12 <pop_off>
  return p;
}
    80001932:	8526                	mv	a0,s1
    80001934:	60e2                	ld	ra,24(sp)
    80001936:	6442                	ld	s0,16(sp)
    80001938:	64a2                	ld	s1,8(sp)
    8000193a:	6105                	addi	sp,sp,32
    8000193c:	8082                	ret

000000008000193e <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    8000193e:	7179                	addi	sp,sp,-48
    80001940:	f406                	sd	ra,40(sp)
    80001942:	f022                	sd	s0,32(sp)
    80001944:	ec26                	sd	s1,24(sp)
    80001946:	1800                	addi	s0,sp,48
  extern char userret[];
  static int first = 1;
  struct proc *p = myproc();
    80001948:	fc7ff0ef          	jal	8000190e <myproc>
    8000194c:	84aa                	mv	s1,a0

  // Still holding p->lock from scheduler.
  release(&p->lock);
    8000194e:	b18ff0ef          	jal	80000c66 <release>

  if (first) {
    80001952:	00009797          	auipc	a5,0x9
    80001956:	a4e7a783          	lw	a5,-1458(a5) # 8000a3a0 <first.1>
    8000195a:	cf8d                	beqz	a5,80001994 <forkret+0x56>
    // File system initialization must be run in the context of a
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    fsinit(ROOTDEV);
    8000195c:	4505                	li	a0,1
    8000195e:	6f1010ef          	jal	8000384e <fsinit>

    first = 0;
    80001962:	00009797          	auipc	a5,0x9
    80001966:	a207af23          	sw	zero,-1474(a5) # 8000a3a0 <first.1>
    // ensure other cores see first=0.
    __sync_synchronize();
    8000196a:	0330000f          	fence	rw,rw

    // We can invoke kexec() now that file system is initialized.
    // Put the return value (argc) of kexec into a0.
    p->trapframe->a0 = kexec("/init", (char *[]){ "/init", 0 });
    8000196e:	00006517          	auipc	a0,0x6
    80001972:	82a50513          	addi	a0,a0,-2006 # 80007198 <etext+0x198>
    80001976:	fca43823          	sd	a0,-48(s0)
    8000197a:	fc043c23          	sd	zero,-40(s0)
    8000197e:	fd040593          	addi	a1,s0,-48
    80001982:	7cd020ef          	jal	8000494e <kexec>
    80001986:	6cbc                	ld	a5,88(s1)
    80001988:	fba8                	sd	a0,112(a5)
    if (p->trapframe->a0 == -1) {
    8000198a:	6cbc                	ld	a5,88(s1)
    8000198c:	7bb8                	ld	a4,112(a5)
    8000198e:	57fd                	li	a5,-1
    80001990:	02f70d63          	beq	a4,a5,800019ca <forkret+0x8c>
      panic("exec");
    }
  }

  // return to user space, mimicing usertrap()'s return.
  prepare_return();
    80001994:	53d000ef          	jal	800026d0 <prepare_return>
  uint64 satp = MAKE_SATP(p->pagetable);
    80001998:	68a8                	ld	a0,80(s1)
    8000199a:	8131                	srli	a0,a0,0xc
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    8000199c:	04000737          	lui	a4,0x4000
    800019a0:	177d                	addi	a4,a4,-1 # 3ffffff <_entry-0x7c000001>
    800019a2:	0732                	slli	a4,a4,0xc
    800019a4:	00004797          	auipc	a5,0x4
    800019a8:	6f878793          	addi	a5,a5,1784 # 8000609c <userret>
    800019ac:	00004697          	auipc	a3,0x4
    800019b0:	65468693          	addi	a3,a3,1620 # 80006000 <_trampoline>
    800019b4:	8f95                	sub	a5,a5,a3
    800019b6:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800019b8:	577d                	li	a4,-1
    800019ba:	177e                	slli	a4,a4,0x3f
    800019bc:	8d59                	or	a0,a0,a4
    800019be:	9782                	jalr	a5
}
    800019c0:	70a2                	ld	ra,40(sp)
    800019c2:	7402                	ld	s0,32(sp)
    800019c4:	64e2                	ld	s1,24(sp)
    800019c6:	6145                	addi	sp,sp,48
    800019c8:	8082                	ret
      panic("exec");
    800019ca:	00005517          	auipc	a0,0x5
    800019ce:	7d650513          	addi	a0,a0,2006 # 800071a0 <etext+0x1a0>
    800019d2:	e0ffe0ef          	jal	800007e0 <panic>

00000000800019d6 <allocpid>:
{
    800019d6:	1101                	addi	sp,sp,-32
    800019d8:	ec06                	sd	ra,24(sp)
    800019da:	e822                	sd	s0,16(sp)
    800019dc:	e426                	sd	s1,8(sp)
    800019de:	e04a                	sd	s2,0(sp)
    800019e0:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    800019e2:	00011917          	auipc	s2,0x11
    800019e6:	b3690913          	addi	s2,s2,-1226 # 80012518 <pid_lock>
    800019ea:	854a                	mv	a0,s2
    800019ec:	9e2ff0ef          	jal	80000bce <acquire>
  pid = nextpid;
    800019f0:	00009797          	auipc	a5,0x9
    800019f4:	9b478793          	addi	a5,a5,-1612 # 8000a3a4 <nextpid>
    800019f8:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    800019fa:	0014871b          	addiw	a4,s1,1
    800019fe:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a00:	854a                	mv	a0,s2
    80001a02:	a64ff0ef          	jal	80000c66 <release>
}
    80001a06:	8526                	mv	a0,s1
    80001a08:	60e2                	ld	ra,24(sp)
    80001a0a:	6442                	ld	s0,16(sp)
    80001a0c:	64a2                	ld	s1,8(sp)
    80001a0e:	6902                	ld	s2,0(sp)
    80001a10:	6105                	addi	sp,sp,32
    80001a12:	8082                	ret

0000000080001a14 <proc_pagetable>:
{
    80001a14:	1101                	addi	sp,sp,-32
    80001a16:	ec06                	sd	ra,24(sp)
    80001a18:	e822                	sd	s0,16(sp)
    80001a1a:	e426                	sd	s1,8(sp)
    80001a1c:	e04a                	sd	s2,0(sp)
    80001a1e:	1000                	addi	s0,sp,32
    80001a20:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a22:	f72ff0ef          	jal	80001194 <uvmcreate>
    80001a26:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a28:	cd05                	beqz	a0,80001a60 <proc_pagetable+0x4c>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a2a:	4729                	li	a4,10
    80001a2c:	00004697          	auipc	a3,0x4
    80001a30:	5d468693          	addi	a3,a3,1492 # 80006000 <_trampoline>
    80001a34:	6605                	lui	a2,0x1
    80001a36:	040005b7          	lui	a1,0x4000
    80001a3a:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a3c:	05b2                	slli	a1,a1,0xc
    80001a3e:	db0ff0ef          	jal	80000fee <mappages>
    80001a42:	02054663          	bltz	a0,80001a6e <proc_pagetable+0x5a>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001a46:	4719                	li	a4,6
    80001a48:	05893683          	ld	a3,88(s2)
    80001a4c:	6605                	lui	a2,0x1
    80001a4e:	020005b7          	lui	a1,0x2000
    80001a52:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001a54:	05b6                	slli	a1,a1,0xd
    80001a56:	8526                	mv	a0,s1
    80001a58:	d96ff0ef          	jal	80000fee <mappages>
    80001a5c:	00054f63          	bltz	a0,80001a7a <proc_pagetable+0x66>
}
    80001a60:	8526                	mv	a0,s1
    80001a62:	60e2                	ld	ra,24(sp)
    80001a64:	6442                	ld	s0,16(sp)
    80001a66:	64a2                	ld	s1,8(sp)
    80001a68:	6902                	ld	s2,0(sp)
    80001a6a:	6105                	addi	sp,sp,32
    80001a6c:	8082                	ret
    uvmfree(pagetable, 0);
    80001a6e:	4581                	li	a1,0
    80001a70:	8526                	mv	a0,s1
    80001a72:	91dff0ef          	jal	8000138e <uvmfree>
    return 0;
    80001a76:	4481                	li	s1,0
    80001a78:	b7e5                	j	80001a60 <proc_pagetable+0x4c>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001a7a:	4681                	li	a3,0
    80001a7c:	4605                	li	a2,1
    80001a7e:	040005b7          	lui	a1,0x4000
    80001a82:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a84:	05b2                	slli	a1,a1,0xc
    80001a86:	8526                	mv	a0,s1
    80001a88:	f32ff0ef          	jal	800011ba <uvmunmap>
    uvmfree(pagetable, 0);
    80001a8c:	4581                	li	a1,0
    80001a8e:	8526                	mv	a0,s1
    80001a90:	8ffff0ef          	jal	8000138e <uvmfree>
    return 0;
    80001a94:	4481                	li	s1,0
    80001a96:	b7e9                	j	80001a60 <proc_pagetable+0x4c>

0000000080001a98 <proc_freepagetable>:
{
    80001a98:	1101                	addi	sp,sp,-32
    80001a9a:	ec06                	sd	ra,24(sp)
    80001a9c:	e822                	sd	s0,16(sp)
    80001a9e:	e426                	sd	s1,8(sp)
    80001aa0:	e04a                	sd	s2,0(sp)
    80001aa2:	1000                	addi	s0,sp,32
    80001aa4:	84aa                	mv	s1,a0
    80001aa6:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001aa8:	4681                	li	a3,0
    80001aaa:	4605                	li	a2,1
    80001aac:	040005b7          	lui	a1,0x4000
    80001ab0:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001ab2:	05b2                	slli	a1,a1,0xc
    80001ab4:	f06ff0ef          	jal	800011ba <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001ab8:	4681                	li	a3,0
    80001aba:	4605                	li	a2,1
    80001abc:	020005b7          	lui	a1,0x2000
    80001ac0:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001ac2:	05b6                	slli	a1,a1,0xd
    80001ac4:	8526                	mv	a0,s1
    80001ac6:	ef4ff0ef          	jal	800011ba <uvmunmap>
  uvmfree(pagetable, sz);
    80001aca:	85ca                	mv	a1,s2
    80001acc:	8526                	mv	a0,s1
    80001ace:	8c1ff0ef          	jal	8000138e <uvmfree>
}
    80001ad2:	60e2                	ld	ra,24(sp)
    80001ad4:	6442                	ld	s0,16(sp)
    80001ad6:	64a2                	ld	s1,8(sp)
    80001ad8:	6902                	ld	s2,0(sp)
    80001ada:	6105                	addi	sp,sp,32
    80001adc:	8082                	ret

0000000080001ade <freeproc>:
{
    80001ade:	1101                	addi	sp,sp,-32
    80001ae0:	ec06                	sd	ra,24(sp)
    80001ae2:	e822                	sd	s0,16(sp)
    80001ae4:	e426                	sd	s1,8(sp)
    80001ae6:	1000                	addi	s0,sp,32
    80001ae8:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001aea:	6d28                	ld	a0,88(a0)
    80001aec:	c119                	beqz	a0,80001af2 <freeproc+0x14>
    kfree((void*)p->trapframe);
    80001aee:	f2ffe0ef          	jal	80000a1c <kfree>
  p->trapframe = 0;
    80001af2:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001af6:	68a8                	ld	a0,80(s1)
    80001af8:	c501                	beqz	a0,80001b00 <freeproc+0x22>
    proc_freepagetable(p->pagetable, p->sz);
    80001afa:	64ac                	ld	a1,72(s1)
    80001afc:	f9dff0ef          	jal	80001a98 <proc_freepagetable>
  p->pagetable = 0;
    80001b00:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b04:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b08:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b0c:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b10:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b14:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001b18:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001b1c:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001b20:	0004ac23          	sw	zero,24(s1)
}
    80001b24:	60e2                	ld	ra,24(sp)
    80001b26:	6442                	ld	s0,16(sp)
    80001b28:	64a2                	ld	s1,8(sp)
    80001b2a:	6105                	addi	sp,sp,32
    80001b2c:	8082                	ret

0000000080001b2e <allocproc>:
{
    80001b2e:	1101                	addi	sp,sp,-32
    80001b30:	ec06                	sd	ra,24(sp)
    80001b32:	e822                	sd	s0,16(sp)
    80001b34:	e426                	sd	s1,8(sp)
    80001b36:	e04a                	sd	s2,0(sp)
    80001b38:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b3a:	00011497          	auipc	s1,0x11
    80001b3e:	e3e48493          	addi	s1,s1,-450 # 80012978 <proc>
    80001b42:	00017917          	auipc	s2,0x17
    80001b46:	63690913          	addi	s2,s2,1590 # 80019178 <tickslock>
    acquire(&p->lock);
    80001b4a:	8526                	mv	a0,s1
    80001b4c:	882ff0ef          	jal	80000bce <acquire>
    if(p->state == UNUSED) {
    80001b50:	4c9c                	lw	a5,24(s1)
    80001b52:	cb91                	beqz	a5,80001b66 <allocproc+0x38>
      release(&p->lock);
    80001b54:	8526                	mv	a0,s1
    80001b56:	910ff0ef          	jal	80000c66 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b5a:	1a048493          	addi	s1,s1,416
    80001b5e:	ff2496e3          	bne	s1,s2,80001b4a <allocproc+0x1c>
  return 0;
    80001b62:	4481                	li	s1,0
    80001b64:	a049                	j	80001be6 <allocproc+0xb8>
  p->pid = allocpid();
    80001b66:	e71ff0ef          	jal	800019d6 <allocpid>
    80001b6a:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001b6c:	4785                	li	a5,1
    80001b6e:	cc9c                	sw	a5,24(s1)
  p->creation_time = ticks;
    80001b70:	00009797          	auipc	a5,0x9
    80001b74:	89c7a783          	lw	a5,-1892(a5) # 8000a40c <ticks>
    80001b78:	16f4a823          	sw	a5,368(s1)
  p->run_time = 0;
    80001b7c:	1804a423          	sw	zero,392(s1)
  p->end_time = 0;
    80001b80:	1804a623          	sw	zero,396(s1)
  p->nice = 0;
    80001b84:	1604a423          	sw	zero,360(s1)
  acquire(&vruntime_lock);
    80001b88:	00011917          	auipc	s2,0x11
    80001b8c:	9c090913          	addi	s2,s2,-1600 # 80012548 <vruntime_lock>
    80001b90:	854a                	mv	a0,s2
    80001b92:	83cff0ef          	jal	80000bce <acquire>
  p->vruntime = 0;
    80001b96:	1604a623          	sw	zero,364(s1)
  release(&vruntime_lock);
    80001b9a:	854a                	mv	a0,s2
    80001b9c:	8caff0ef          	jal	80000c66 <release>
  p->time_slice = 0;
    80001ba0:	1804a223          	sw	zero,388(s1)
  p->queue = 0;
    80001ba4:	1604ac23          	sw	zero,376(s1)
  p->ticks_in_queue = 0;
    80001ba8:	1604ae23          	sw	zero,380(s1)
  p->age = 0;
    80001bac:	1804a023          	sw	zero,384(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001bb0:	f4ffe0ef          	jal	80000afe <kalloc>
    80001bb4:	892a                	mv	s2,a0
    80001bb6:	eca8                	sd	a0,88(s1)
    80001bb8:	cd15                	beqz	a0,80001bf4 <allocproc+0xc6>
  p->pagetable = proc_pagetable(p);
    80001bba:	8526                	mv	a0,s1
    80001bbc:	e59ff0ef          	jal	80001a14 <proc_pagetable>
    80001bc0:	892a                	mv	s2,a0
    80001bc2:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001bc4:	c121                	beqz	a0,80001c04 <allocproc+0xd6>
  memset(&p->context, 0, sizeof(p->context));
    80001bc6:	07000613          	li	a2,112
    80001bca:	4581                	li	a1,0
    80001bcc:	06048513          	addi	a0,s1,96
    80001bd0:	8d2ff0ef          	jal	80000ca2 <memset>
  p->context.ra = (uint64)forkret;
    80001bd4:	00000797          	auipc	a5,0x0
    80001bd8:	d6a78793          	addi	a5,a5,-662 # 8000193e <forkret>
    80001bdc:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001bde:	60bc                	ld	a5,64(s1)
    80001be0:	6705                	lui	a4,0x1
    80001be2:	97ba                	add	a5,a5,a4
    80001be4:	f4bc                	sd	a5,104(s1)
}
    80001be6:	8526                	mv	a0,s1
    80001be8:	60e2                	ld	ra,24(sp)
    80001bea:	6442                	ld	s0,16(sp)
    80001bec:	64a2                	ld	s1,8(sp)
    80001bee:	6902                	ld	s2,0(sp)
    80001bf0:	6105                	addi	sp,sp,32
    80001bf2:	8082                	ret
    freeproc(p);
    80001bf4:	8526                	mv	a0,s1
    80001bf6:	ee9ff0ef          	jal	80001ade <freeproc>
    release(&p->lock);
    80001bfa:	8526                	mv	a0,s1
    80001bfc:	86aff0ef          	jal	80000c66 <release>
    return 0;
    80001c00:	84ca                	mv	s1,s2
    80001c02:	b7d5                	j	80001be6 <allocproc+0xb8>
    freeproc(p);
    80001c04:	8526                	mv	a0,s1
    80001c06:	ed9ff0ef          	jal	80001ade <freeproc>
    release(&p->lock);
    80001c0a:	8526                	mv	a0,s1
    80001c0c:	85aff0ef          	jal	80000c66 <release>
    return 0;
    80001c10:	84ca                	mv	s1,s2
    80001c12:	bfd1                	j	80001be6 <allocproc+0xb8>

0000000080001c14 <growproc>:
{
    80001c14:	1101                	addi	sp,sp,-32
    80001c16:	ec06                	sd	ra,24(sp)
    80001c18:	e822                	sd	s0,16(sp)
    80001c1a:	e426                	sd	s1,8(sp)
    80001c1c:	e04a                	sd	s2,0(sp)
    80001c1e:	1000                	addi	s0,sp,32
    80001c20:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001c22:	cedff0ef          	jal	8000190e <myproc>
    80001c26:	84aa                	mv	s1,a0
  sz = p->sz;
    80001c28:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001c2a:	01204c63          	bgtz	s2,80001c42 <growproc+0x2e>
  } else if(n < 0){
    80001c2e:	02094463          	bltz	s2,80001c56 <growproc+0x42>
  p->sz = sz;
    80001c32:	e4ac                	sd	a1,72(s1)
  return 0;
    80001c34:	4501                	li	a0,0
}
    80001c36:	60e2                	ld	ra,24(sp)
    80001c38:	6442                	ld	s0,16(sp)
    80001c3a:	64a2                	ld	s1,8(sp)
    80001c3c:	6902                	ld	s2,0(sp)
    80001c3e:	6105                	addi	sp,sp,32
    80001c40:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001c42:	4691                	li	a3,4
    80001c44:	00b90633          	add	a2,s2,a1
    80001c48:	6928                	ld	a0,80(a0)
    80001c4a:	e3eff0ef          	jal	80001288 <uvmalloc>
    80001c4e:	85aa                	mv	a1,a0
    80001c50:	f16d                	bnez	a0,80001c32 <growproc+0x1e>
      return -1;
    80001c52:	557d                	li	a0,-1
    80001c54:	b7cd                	j	80001c36 <growproc+0x22>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001c56:	00b90633          	add	a2,s2,a1
    80001c5a:	6928                	ld	a0,80(a0)
    80001c5c:	de8ff0ef          	jal	80001244 <uvmdealloc>
    80001c60:	85aa                	mv	a1,a0
    80001c62:	bfc1                	j	80001c32 <growproc+0x1e>

0000000080001c64 <add_to_run_queue>:
{
    80001c64:	1101                	addi	sp,sp,-32
    80001c66:	ec06                	sd	ra,24(sp)
    80001c68:	e822                	sd	s0,16(sp)
    80001c6a:	e426                	sd	s1,8(sp)
    80001c6c:	1000                	addi	s0,sp,32
    80001c6e:	84aa                	mv	s1,a0
  acquire(&run_queue_lock);
    80001c70:	00011517          	auipc	a0,0x11
    80001c74:	8f050513          	addi	a0,a0,-1808 # 80012560 <run_queue_lock>
    80001c78:	f57fe0ef          	jal	80000bce <acquire>
  if (run_queue == 0) { // Queue is empty
    80001c7c:	00008597          	auipc	a1,0x8
    80001c80:	7745b583          	ld	a1,1908(a1) # 8000a3f0 <run_queue>
    80001c84:	cd99                	beqz	a1,80001ca2 <add_to_run_queue+0x3e>
    while (curr && curr->vruntime < p->vruntime) {
    80001c86:	16c4a603          	lw	a2,364(s1)
    struct proc *curr = run_queue;
    80001c8a:	87ae                	mv	a5,a1
    struct proc *prev = 0;
    80001c8c:	4681                	li	a3,0
    while (curr && curr->vruntime < p->vruntime) {
    80001c8e:	16c7a703          	lw	a4,364(a5)
    80001c92:	02c77163          	bgeu	a4,a2,80001cb4 <add_to_run_queue+0x50>
      curr = curr->next_run;
    80001c96:	1907b703          	ld	a4,400(a5)
    while (curr && curr->vruntime < p->vruntime) {
    80001c9a:	86be                	mv	a3,a5
    80001c9c:	c71d                	beqz	a4,80001cca <add_to_run_queue+0x66>
    80001c9e:	87ba                	mv	a5,a4
    80001ca0:	b7fd                	j	80001c8e <add_to_run_queue+0x2a>
    run_queue = p;
    80001ca2:	00008797          	auipc	a5,0x8
    80001ca6:	7497b723          	sd	s1,1870(a5) # 8000a3f0 <run_queue>
    p->next_run = 0;
    80001caa:	1804b823          	sd	zero,400(s1)
    p->prev_run = 0;
    80001cae:	1804bc23          	sd	zero,408(s1)
    80001cb2:	a03d                	j	80001ce0 <add_to_run_queue+0x7c>
    if (prev == 0) { // Insert at the head
    80001cb4:	ea91                	bnez	a3,80001cc8 <add_to_run_queue+0x64>
      p->next_run = run_queue;
    80001cb6:	18b4b823          	sd	a1,400(s1)
      run_queue->prev_run = p;
    80001cba:	1895bc23          	sd	s1,408(a1)
      run_queue = p;
    80001cbe:	00008797          	auipc	a5,0x8
    80001cc2:	7297b923          	sd	s1,1842(a5) # 8000a3f0 <run_queue>
    80001cc6:	a829                	j	80001ce0 <add_to_run_queue+0x7c>
    80001cc8:	87b6                	mv	a5,a3
      p->next_run = prev->next_run;
    80001cca:	1907b703          	ld	a4,400(a5)
    80001cce:	18e4b823          	sd	a4,400(s1)
      if (prev->next_run)
    80001cd2:	c319                	beqz	a4,80001cd8 <add_to_run_queue+0x74>
        prev->next_run->prev_run = p;
    80001cd4:	18973c23          	sd	s1,408(a4) # 1198 <_entry-0x7fffee68>
      prev->next_run = p;
    80001cd8:	1897b823          	sd	s1,400(a5)
      p->prev_run = prev;
    80001cdc:	18f4bc23          	sd	a5,408(s1)
  release(&run_queue_lock);
    80001ce0:	00011517          	auipc	a0,0x11
    80001ce4:	88050513          	addi	a0,a0,-1920 # 80012560 <run_queue_lock>
    80001ce8:	f7ffe0ef          	jal	80000c66 <release>
}
    80001cec:	60e2                	ld	ra,24(sp)
    80001cee:	6442                	ld	s0,16(sp)
    80001cf0:	64a2                	ld	s1,8(sp)
    80001cf2:	6105                	addi	sp,sp,32
    80001cf4:	8082                	ret

0000000080001cf6 <userinit>:
{
    80001cf6:	1101                	addi	sp,sp,-32
    80001cf8:	ec06                	sd	ra,24(sp)
    80001cfa:	e822                	sd	s0,16(sp)
    80001cfc:	e426                	sd	s1,8(sp)
    80001cfe:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d00:	e2fff0ef          	jal	80001b2e <allocproc>
    80001d04:	84aa                	mv	s1,a0
  initproc = p;
    80001d06:	00008797          	auipc	a5,0x8
    80001d0a:	6ea7bd23          	sd	a0,1786(a5) # 8000a400 <initproc>
  p->cwd = namei("/");
    80001d0e:	00005517          	auipc	a0,0x5
    80001d12:	49a50513          	addi	a0,a0,1178 # 800071a8 <etext+0x1a8>
    80001d16:	05a020ef          	jal	80003d70 <namei>
    80001d1a:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d1e:	478d                	li	a5,3
    80001d20:	cc9c                	sw	a5,24(s1)
  add_to_run_queue(p);
    80001d22:	8526                	mv	a0,s1
    80001d24:	f41ff0ef          	jal	80001c64 <add_to_run_queue>
  release(&p->lock);
    80001d28:	8526                	mv	a0,s1
    80001d2a:	f3dfe0ef          	jal	80000c66 <release>
}
    80001d2e:	60e2                	ld	ra,24(sp)
    80001d30:	6442                	ld	s0,16(sp)
    80001d32:	64a2                	ld	s1,8(sp)
    80001d34:	6105                	addi	sp,sp,32
    80001d36:	8082                	ret

0000000080001d38 <kfork>:
{
    80001d38:	7139                	addi	sp,sp,-64
    80001d3a:	fc06                	sd	ra,56(sp)
    80001d3c:	f822                	sd	s0,48(sp)
    80001d3e:	f04a                	sd	s2,32(sp)
    80001d40:	e456                	sd	s5,8(sp)
    80001d42:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d44:	bcbff0ef          	jal	8000190e <myproc>
    80001d48:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001d4a:	de5ff0ef          	jal	80001b2e <allocproc>
    80001d4e:	0e050d63          	beqz	a0,80001e48 <kfork+0x110>
    80001d52:	ec4e                	sd	s3,24(sp)
    80001d54:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001d56:	048ab603          	ld	a2,72(s5)
    80001d5a:	692c                	ld	a1,80(a0)
    80001d5c:	050ab503          	ld	a0,80(s5)
    80001d60:	e60ff0ef          	jal	800013c0 <uvmcopy>
    80001d64:	04054a63          	bltz	a0,80001db8 <kfork+0x80>
    80001d68:	f426                	sd	s1,40(sp)
    80001d6a:	e852                	sd	s4,16(sp)
  np->sz = p->sz;
    80001d6c:	048ab783          	ld	a5,72(s5)
    80001d70:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001d74:	058ab683          	ld	a3,88(s5)
    80001d78:	87b6                	mv	a5,a3
    80001d7a:	0589b703          	ld	a4,88(s3)
    80001d7e:	12068693          	addi	a3,a3,288
    80001d82:	0007b803          	ld	a6,0(a5)
    80001d86:	6788                	ld	a0,8(a5)
    80001d88:	6b8c                	ld	a1,16(a5)
    80001d8a:	6f90                	ld	a2,24(a5)
    80001d8c:	01073023          	sd	a6,0(a4)
    80001d90:	e708                	sd	a0,8(a4)
    80001d92:	eb0c                	sd	a1,16(a4)
    80001d94:	ef10                	sd	a2,24(a4)
    80001d96:	02078793          	addi	a5,a5,32
    80001d9a:	02070713          	addi	a4,a4,32
    80001d9e:	fed792e3          	bne	a5,a3,80001d82 <kfork+0x4a>
  np->trapframe->a0 = 0;
    80001da2:	0589b783          	ld	a5,88(s3)
    80001da6:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001daa:	0d0a8493          	addi	s1,s5,208
    80001dae:	0d098913          	addi	s2,s3,208
    80001db2:	150a8a13          	addi	s4,s5,336
    80001db6:	a831                	j	80001dd2 <kfork+0x9a>
    freeproc(np);
    80001db8:	854e                	mv	a0,s3
    80001dba:	d25ff0ef          	jal	80001ade <freeproc>
    release(&np->lock);
    80001dbe:	854e                	mv	a0,s3
    80001dc0:	ea7fe0ef          	jal	80000c66 <release>
    return -1;
    80001dc4:	597d                	li	s2,-1
    80001dc6:	69e2                	ld	s3,24(sp)
    80001dc8:	a88d                	j	80001e3a <kfork+0x102>
  for(i = 0; i < NOFILE; i++)
    80001dca:	04a1                	addi	s1,s1,8
    80001dcc:	0921                	addi	s2,s2,8
    80001dce:	01448963          	beq	s1,s4,80001de0 <kfork+0xa8>
    if(p->ofile[i])
    80001dd2:	6088                	ld	a0,0(s1)
    80001dd4:	d97d                	beqz	a0,80001dca <kfork+0x92>
      np->ofile[i] = filedup(p->ofile[i]);
    80001dd6:	534020ef          	jal	8000430a <filedup>
    80001dda:	00a93023          	sd	a0,0(s2)
    80001dde:	b7f5                	j	80001dca <kfork+0x92>
  np->cwd = idup(p->cwd);
    80001de0:	150ab503          	ld	a0,336(s5)
    80001de4:	740010ef          	jal	80003524 <idup>
    80001de8:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001dec:	4641                	li	a2,16
    80001dee:	158a8593          	addi	a1,s5,344
    80001df2:	15898513          	addi	a0,s3,344
    80001df6:	febfe0ef          	jal	80000de0 <safestrcpy>
  pid = np->pid;
    80001dfa:	0309a903          	lw	s2,48(s3)
  release(&np->lock);
    80001dfe:	854e                	mv	a0,s3
    80001e00:	e67fe0ef          	jal	80000c66 <release>
  acquire(&wait_lock);
    80001e04:	00010497          	auipc	s1,0x10
    80001e08:	72c48493          	addi	s1,s1,1836 # 80012530 <wait_lock>
    80001e0c:	8526                	mv	a0,s1
    80001e0e:	dc1fe0ef          	jal	80000bce <acquire>
  np->parent = p;
    80001e12:	0359bc23          	sd	s5,56(s3)
  release(&wait_lock);
    80001e16:	8526                	mv	a0,s1
    80001e18:	e4ffe0ef          	jal	80000c66 <release>
  acquire(&np->lock);
    80001e1c:	854e                	mv	a0,s3
    80001e1e:	db1fe0ef          	jal	80000bce <acquire>
  np->state = RUNNABLE;
    80001e22:	478d                	li	a5,3
    80001e24:	00f9ac23          	sw	a5,24(s3)
  add_to_run_queue(np); 
    80001e28:	854e                	mv	a0,s3
    80001e2a:	e3bff0ef          	jal	80001c64 <add_to_run_queue>
  release(&np->lock);
    80001e2e:	854e                	mv	a0,s3
    80001e30:	e37fe0ef          	jal	80000c66 <release>
  return pid;
    80001e34:	74a2                	ld	s1,40(sp)
    80001e36:	69e2                	ld	s3,24(sp)
    80001e38:	6a42                	ld	s4,16(sp)
}
    80001e3a:	854a                	mv	a0,s2
    80001e3c:	70e2                	ld	ra,56(sp)
    80001e3e:	7442                	ld	s0,48(sp)
    80001e40:	7902                	ld	s2,32(sp)
    80001e42:	6aa2                	ld	s5,8(sp)
    80001e44:	6121                	addi	sp,sp,64
    80001e46:	8082                	ret
    return -1;
    80001e48:	597d                	li	s2,-1
    80001e4a:	bfc5                	j	80001e3a <kfork+0x102>

0000000080001e4c <remove_from_run_queue>:
{
    80001e4c:	1101                	addi	sp,sp,-32
    80001e4e:	ec06                	sd	ra,24(sp)
    80001e50:	e822                	sd	s0,16(sp)
    80001e52:	e426                	sd	s1,8(sp)
    80001e54:	1000                	addi	s0,sp,32
    80001e56:	84aa                	mv	s1,a0
  acquire(&run_queue_lock);
    80001e58:	00010517          	auipc	a0,0x10
    80001e5c:	70850513          	addi	a0,a0,1800 # 80012560 <run_queue_lock>
    80001e60:	d6ffe0ef          	jal	80000bce <acquire>
  if (p->prev_run)
    80001e64:	1984b783          	ld	a5,408(s1)
    80001e68:	cb9d                	beqz	a5,80001e9e <remove_from_run_queue+0x52>
    p->prev_run->next_run = p->next_run;
    80001e6a:	1904b703          	ld	a4,400(s1)
    80001e6e:	18e7b823          	sd	a4,400(a5)
  if (p->next_run)
    80001e72:	1904b783          	ld	a5,400(s1)
    80001e76:	c789                	beqz	a5,80001e80 <remove_from_run_queue+0x34>
    p->next_run->prev_run = p->prev_run;
    80001e78:	1984b703          	ld	a4,408(s1)
    80001e7c:	18e7bc23          	sd	a4,408(a5)
  p->next_run = 0;
    80001e80:	1804b823          	sd	zero,400(s1)
  p->prev_run = 0;
    80001e84:	1804bc23          	sd	zero,408(s1)
  release(&run_queue_lock);
    80001e88:	00010517          	auipc	a0,0x10
    80001e8c:	6d850513          	addi	a0,a0,1752 # 80012560 <run_queue_lock>
    80001e90:	dd7fe0ef          	jal	80000c66 <release>
}
    80001e94:	60e2                	ld	ra,24(sp)
    80001e96:	6442                	ld	s0,16(sp)
    80001e98:	64a2                	ld	s1,8(sp)
    80001e9a:	6105                	addi	sp,sp,32
    80001e9c:	8082                	ret
    run_queue = p->next_run;
    80001e9e:	1904b783          	ld	a5,400(s1)
    80001ea2:	00008717          	auipc	a4,0x8
    80001ea6:	54f73723          	sd	a5,1358(a4) # 8000a3f0 <run_queue>
    80001eaa:	b7e1                	j	80001e72 <remove_from_run_queue+0x26>

0000000080001eac <scheduler>:
{
    80001eac:	711d                	addi	sp,sp,-96
    80001eae:	ec86                	sd	ra,88(sp)
    80001eb0:	e8a2                	sd	s0,80(sp)
    80001eb2:	e4a6                	sd	s1,72(sp)
    80001eb4:	e0ca                	sd	s2,64(sp)
    80001eb6:	fc4e                	sd	s3,56(sp)
    80001eb8:	f852                	sd	s4,48(sp)
    80001eba:	f456                	sd	s5,40(sp)
    80001ebc:	f05a                	sd	s6,32(sp)
    80001ebe:	ec5e                	sd	s7,24(sp)
    80001ec0:	e862                	sd	s8,16(sp)
    80001ec2:	e466                	sd	s9,8(sp)
    80001ec4:	e06a                	sd	s10,0(sp)
    80001ec6:	1080                	addi	s0,sp,96
    80001ec8:	8792                	mv	a5,tp
  int id = r_tp();
    80001eca:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001ecc:	00779c93          	slli	s9,a5,0x7
    80001ed0:	00010717          	auipc	a4,0x10
    80001ed4:	64870713          	addi	a4,a4,1608 # 80012518 <pid_lock>
    80001ed8:	9766                	add	a4,a4,s9
    80001eda:	06073023          	sd	zero,96(a4)
        swtch(&c->context, &best_p->context);
    80001ede:	00010717          	auipc	a4,0x10
    80001ee2:	6a270713          	addi	a4,a4,1698 # 80012580 <cpus+0x8>
    80001ee6:	9cba                	add	s9,s9,a4
    acquire(&run_queue_lock);
    80001ee8:	00010a97          	auipc	s5,0x10
    80001eec:	678a8a93          	addi	s5,s5,1656 # 80012560 <run_queue_lock>
    struct proc *best_p = run_queue;
    80001ef0:	00008b17          	auipc	s6,0x8
    80001ef4:	500b0b13          	addi	s6,s6,1280 # 8000a3f0 <run_queue>
      printf("\n[Scheduler Tick]\n");
    80001ef8:	00005b97          	auipc	s7,0x5
    80001efc:	2b8b8b93          	addi	s7,s7,696 # 800071b0 <etext+0x1b0>
        printf("PID: %d | vRuntime: %d\n", p_log->pid, p_log->vruntime);
    80001f00:	00005a17          	auipc	s4,0x5
    80001f04:	2c8a0a13          	addi	s4,s4,712 # 800071c8 <etext+0x1c8>
            if (p_count->state == RUNNABLE) {
    80001f08:	448d                	li	s1,3
        for (p_count = proc; p_count < &proc[NPROC]; p_count++) {
    80001f0a:	00017917          	auipc	s2,0x17
    80001f0e:	26e90913          	addi	s2,s2,622 # 80019178 <tickslock>
        c->proc = best_p;
    80001f12:	079e                	slli	a5,a5,0x7
    80001f14:	00010c17          	auipc	s8,0x10
    80001f18:	604c0c13          	addi	s8,s8,1540 # 80012518 <pid_lock>
    80001f1c:	9c3e                	add	s8,s8,a5
    80001f1e:	a021                	j	80001f26 <scheduler+0x7a>
    release(&run_queue_lock);
    80001f20:	8556                	mv	a0,s5
    80001f22:	d45fe0ef          	jal	80000c66 <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f26:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f2a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f2e:	10079073          	csrw	sstatus,a5
    acquire(&run_queue_lock);
    80001f32:	8556                	mv	a0,s5
    80001f34:	c9bfe0ef          	jal	80000bce <acquire>
    struct proc *best_p = run_queue;
    80001f38:	000b3983          	ld	s3,0(s6)
    if(best_p){
    80001f3c:	fe0982e3          	beqz	s3,80001f20 <scheduler+0x74>
      printf("\n[Scheduler Tick]\n");
    80001f40:	855e                	mv	a0,s7
    80001f42:	db8fe0ef          	jal	800004fa <printf>
      struct proc *p_log = run_queue;
    80001f46:	000b3d03          	ld	s10,0(s6)
      while(p_log) {
    80001f4a:	000d0d63          	beqz	s10,80001f64 <scheduler+0xb8>
        printf("PID: %d | vRuntime: %d\n", p_log->pid, p_log->vruntime);
    80001f4e:	16cd2603          	lw	a2,364(s10) # 116c <_entry-0x7fffee94>
    80001f52:	030d2583          	lw	a1,48(s10)
    80001f56:	8552                	mv	a0,s4
    80001f58:	da2fe0ef          	jal	800004fa <printf>
        p_log = p_log->next_run;
    80001f5c:	190d3d03          	ld	s10,400(s10)
      while(p_log) {
    80001f60:	fe0d17e3          	bnez	s10,80001f4e <scheduler+0xa2>
      printf("--> Scheduling PID %d (lowest vRuntime)\n\n", best_p->pid);
    80001f64:	0309a583          	lw	a1,48(s3)
    80001f68:	00005517          	auipc	a0,0x5
    80001f6c:	27850513          	addi	a0,a0,632 # 800071e0 <etext+0x1e0>
    80001f70:	d8afe0ef          	jal	800004fa <printf>
      run_queue = best_p->next_run;
    80001f74:	1909b783          	ld	a5,400(s3)
    80001f78:	00fb3023          	sd	a5,0(s6)
      if (run_queue)
    80001f7c:	c399                	beqz	a5,80001f82 <scheduler+0xd6>
        run_queue->prev_run = 0;
    80001f7e:	1807bc23          	sd	zero,408(a5)
      best_p->next_run = 0;
    80001f82:	1809b823          	sd	zero,400(s3)
    release(&run_queue_lock);
    80001f86:	8556                	mv	a0,s5
    80001f88:	cdffe0ef          	jal	80000c66 <release>
        acquire(&best_p->lock);
    80001f8c:	854e                	mv	a0,s3
    80001f8e:	c41fe0ef          	jal	80000bce <acquire>
        for (p_count = proc; p_count < &proc[NPROC]; p_count++) {
    80001f92:	00011797          	auipc	a5,0x11
    80001f96:	9e678793          	addi	a5,a5,-1562 # 80012978 <proc>
        int num_runnable = 0;
    80001f9a:	4681                	li	a3,0
    80001f9c:	a029                	j	80001fa6 <scheduler+0xfa>
        for (p_count = proc; p_count < &proc[NPROC]; p_count++) {
    80001f9e:	1a078793          	addi	a5,a5,416
    80001fa2:	01278763          	beq	a5,s2,80001fb0 <scheduler+0x104>
            if (p_count->state == RUNNABLE) {
    80001fa6:	4f98                	lw	a4,24(a5)
    80001fa8:	fe971be3          	bne	a4,s1,80001f9e <scheduler+0xf2>
                num_runnable++;
    80001fac:	2685                	addiw	a3,a3,1
    80001fae:	bfc5                	j	80001f9e <scheduler+0xf2>
        num_runnable++; // Include the current process
    80001fb0:	2685                	addiw	a3,a3,1
        int time_slice = target_latency / slice_divisor;
    80001fb2:	03000793          	li	a5,48
    80001fb6:	02d7c7bb          	divw	a5,a5,a3
        if (time_slice < min_timeslice) {
    80001fba:	0007871b          	sext.w	a4,a5
    80001fbe:	00975363          	bge	a4,s1,80001fc4 <scheduler+0x118>
    80001fc2:	478d                	li	a5,3
        best_p->time_slice = time_slice;
    80001fc4:	18f9a223          	sw	a5,388(s3)
        best_p->state = RUNNING;
    80001fc8:	4791                	li	a5,4
    80001fca:	00f9ac23          	sw	a5,24(s3)
        c->proc = best_p;
    80001fce:	073c3023          	sd	s3,96(s8)
        swtch(&c->context, &best_p->context);
    80001fd2:	06098593          	addi	a1,s3,96
    80001fd6:	8566                	mv	a0,s9
    80001fd8:	652000ef          	jal	8000262a <swtch>
        c->proc = 0;
    80001fdc:	060c3023          	sd	zero,96(s8)
        release(&best_p->lock);
    80001fe0:	854e                	mv	a0,s3
    80001fe2:	c85fe0ef          	jal	80000c66 <release>
    80001fe6:	b781                	j	80001f26 <scheduler+0x7a>

0000000080001fe8 <sched>:
{
    80001fe8:	7179                	addi	sp,sp,-48
    80001fea:	f406                	sd	ra,40(sp)
    80001fec:	f022                	sd	s0,32(sp)
    80001fee:	ec26                	sd	s1,24(sp)
    80001ff0:	e84a                	sd	s2,16(sp)
    80001ff2:	e44e                	sd	s3,8(sp)
    80001ff4:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001ff6:	919ff0ef          	jal	8000190e <myproc>
    80001ffa:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001ffc:	b69fe0ef          	jal	80000b64 <holding>
    80002000:	c92d                	beqz	a0,80002072 <sched+0x8a>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002002:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002004:	2781                	sext.w	a5,a5
    80002006:	079e                	slli	a5,a5,0x7
    80002008:	00010717          	auipc	a4,0x10
    8000200c:	51070713          	addi	a4,a4,1296 # 80012518 <pid_lock>
    80002010:	97ba                	add	a5,a5,a4
    80002012:	0d87a703          	lw	a4,216(a5)
    80002016:	4785                	li	a5,1
    80002018:	06f71363          	bne	a4,a5,8000207e <sched+0x96>
  if(p->state == RUNNING)
    8000201c:	4c98                	lw	a4,24(s1)
    8000201e:	4791                	li	a5,4
    80002020:	06f70563          	beq	a4,a5,8000208a <sched+0xa2>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002024:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002028:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000202a:	e7b5                	bnez	a5,80002096 <sched+0xae>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000202c:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000202e:	00010917          	auipc	s2,0x10
    80002032:	4ea90913          	addi	s2,s2,1258 # 80012518 <pid_lock>
    80002036:	2781                	sext.w	a5,a5
    80002038:	079e                	slli	a5,a5,0x7
    8000203a:	97ca                	add	a5,a5,s2
    8000203c:	0dc7a983          	lw	s3,220(a5)
    80002040:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002042:	2781                	sext.w	a5,a5
    80002044:	079e                	slli	a5,a5,0x7
    80002046:	00010597          	auipc	a1,0x10
    8000204a:	53a58593          	addi	a1,a1,1338 # 80012580 <cpus+0x8>
    8000204e:	95be                	add	a1,a1,a5
    80002050:	06048513          	addi	a0,s1,96
    80002054:	5d6000ef          	jal	8000262a <swtch>
    80002058:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000205a:	2781                	sext.w	a5,a5
    8000205c:	079e                	slli	a5,a5,0x7
    8000205e:	993e                	add	s2,s2,a5
    80002060:	0d392e23          	sw	s3,220(s2)
}
    80002064:	70a2                	ld	ra,40(sp)
    80002066:	7402                	ld	s0,32(sp)
    80002068:	64e2                	ld	s1,24(sp)
    8000206a:	6942                	ld	s2,16(sp)
    8000206c:	69a2                	ld	s3,8(sp)
    8000206e:	6145                	addi	sp,sp,48
    80002070:	8082                	ret
    panic("sched p->lock");
    80002072:	00005517          	auipc	a0,0x5
    80002076:	19e50513          	addi	a0,a0,414 # 80007210 <etext+0x210>
    8000207a:	f66fe0ef          	jal	800007e0 <panic>
    panic("sched locks");
    8000207e:	00005517          	auipc	a0,0x5
    80002082:	1a250513          	addi	a0,a0,418 # 80007220 <etext+0x220>
    80002086:	f5afe0ef          	jal	800007e0 <panic>
    panic("sched RUNNING");
    8000208a:	00005517          	auipc	a0,0x5
    8000208e:	1a650513          	addi	a0,a0,422 # 80007230 <etext+0x230>
    80002092:	f4efe0ef          	jal	800007e0 <panic>
    panic("sched interruptible");
    80002096:	00005517          	auipc	a0,0x5
    8000209a:	1aa50513          	addi	a0,a0,426 # 80007240 <etext+0x240>
    8000209e:	f42fe0ef          	jal	800007e0 <panic>

00000000800020a2 <yield>:
{
    800020a2:	1101                	addi	sp,sp,-32
    800020a4:	ec06                	sd	ra,24(sp)
    800020a6:	e822                	sd	s0,16(sp)
    800020a8:	e426                	sd	s1,8(sp)
    800020aa:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800020ac:	863ff0ef          	jal	8000190e <myproc>
    800020b0:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020b2:	b1dfe0ef          	jal	80000bce <acquire>
  if(p->ticks > 0) {
    800020b6:	1744a783          	lw	a5,372(s1)
    800020ba:	c795                	beqz	a5,800020e6 <yield+0x44>
    p->vruntime += (p->ticks * 1024) / weight;
    800020bc:	00a7979b          	slliw	a5,a5,0xa
  int weight = NICE_TO_WEIGHT[p->nice + 20];
    800020c0:	1684a703          	lw	a4,360(s1)
    800020c4:	2751                	addiw	a4,a4,20
    800020c6:	070a                	slli	a4,a4,0x2
    800020c8:	00005697          	auipc	a3,0x5
    800020cc:	76068693          	addi	a3,a3,1888 # 80007828 <NICE_TO_WEIGHT>
    800020d0:	9736                	add	a4,a4,a3
    p->vruntime += (p->ticks * 1024) / weight;
    800020d2:	4318                	lw	a4,0(a4)
    800020d4:	02e7d7bb          	divuw	a5,a5,a4
    800020d8:	16c4a703          	lw	a4,364(s1)
    800020dc:	9fb9                	addw	a5,a5,a4
    800020de:	16f4a623          	sw	a5,364(s1)
    p->ticks = 0;
    800020e2:	1604aa23          	sw	zero,372(s1)
  p->state = RUNNABLE;
    800020e6:	478d                	li	a5,3
    800020e8:	cc9c                	sw	a5,24(s1)
  add_to_run_queue(p);
    800020ea:	8526                	mv	a0,s1
    800020ec:	b79ff0ef          	jal	80001c64 <add_to_run_queue>
  sched();
    800020f0:	ef9ff0ef          	jal	80001fe8 <sched>
  release(&p->lock);
    800020f4:	8526                	mv	a0,s1
    800020f6:	b71fe0ef          	jal	80000c66 <release>
}
    800020fa:	60e2                	ld	ra,24(sp)
    800020fc:	6442                	ld	s0,16(sp)
    800020fe:	64a2                	ld	s1,8(sp)
    80002100:	6105                	addi	sp,sp,32
    80002102:	8082                	ret

0000000080002104 <sleep>:

// Sleep on channel chan, releasing condition lock lk.
// Re-acquires lk when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002104:	7179                	addi	sp,sp,-48
    80002106:	f406                	sd	ra,40(sp)
    80002108:	f022                	sd	s0,32(sp)
    8000210a:	ec26                	sd	s1,24(sp)
    8000210c:	e84a                	sd	s2,16(sp)
    8000210e:	e44e                	sd	s3,8(sp)
    80002110:	1800                	addi	s0,sp,48
    80002112:	89aa                	mv	s3,a0
    80002114:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002116:	ff8ff0ef          	jal	8000190e <myproc>
    8000211a:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000211c:	ab3fe0ef          	jal	80000bce <acquire>
  release(lk);
    80002120:	854a                	mv	a0,s2
    80002122:	b45fe0ef          	jal	80000c66 <release>

  // Go to sleep.
  p->chan = chan;
    80002126:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000212a:	4789                	li	a5,2
    8000212c:	cc9c                	sw	a5,24(s1)

#if defined(CFS)
  // Update vruntime before calling the scheduler.
  int weight = NICE_TO_WEIGHT[p->nice + 20];
  if(p->ticks > 0) {
    8000212e:	1744a783          	lw	a5,372(s1)
    80002132:	c795                	beqz	a5,8000215e <sleep+0x5a>
    p->vruntime += (p->ticks * 1024) / weight;
    80002134:	00a7979b          	slliw	a5,a5,0xa
  int weight = NICE_TO_WEIGHT[p->nice + 20];
    80002138:	1684a703          	lw	a4,360(s1)
    8000213c:	2751                	addiw	a4,a4,20
    8000213e:	070a                	slli	a4,a4,0x2
    80002140:	00005697          	auipc	a3,0x5
    80002144:	6e868693          	addi	a3,a3,1768 # 80007828 <NICE_TO_WEIGHT>
    80002148:	9736                	add	a4,a4,a3
    p->vruntime += (p->ticks * 1024) / weight;
    8000214a:	4318                	lw	a4,0(a4)
    8000214c:	02e7d7bb          	divuw	a5,a5,a4
    80002150:	16c4a703          	lw	a4,364(s1)
    80002154:	9fb9                	addw	a5,a5,a4
    80002156:	16f4a623          	sw	a5,364(s1)
    p->ticks = 0;
    8000215a:	1604aa23          	sw	zero,372(s1)
  }
#endif

  sched();
    8000215e:	e8bff0ef          	jal	80001fe8 <sched>

  // Tidy up.
  p->chan = 0;
    80002162:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002166:	8526                	mv	a0,s1
    80002168:	afffe0ef          	jal	80000c66 <release>
  acquire(lk);
    8000216c:	854a                	mv	a0,s2
    8000216e:	a61fe0ef          	jal	80000bce <acquire>
}
    80002172:	70a2                	ld	ra,40(sp)
    80002174:	7402                	ld	s0,32(sp)
    80002176:	64e2                	ld	s1,24(sp)
    80002178:	6942                	ld	s2,16(sp)
    8000217a:	69a2                	ld	s3,8(sp)
    8000217c:	6145                	addi	sp,sp,48
    8000217e:	8082                	ret

0000000080002180 <wakeup>:

// Wake up all processes sleeping on channel chan.
// Caller should hold the condition lock.
void
wakeup(void *chan)
{
    80002180:	7139                	addi	sp,sp,-64
    80002182:	fc06                	sd	ra,56(sp)
    80002184:	f822                	sd	s0,48(sp)
    80002186:	f426                	sd	s1,40(sp)
    80002188:	f04a                	sd	s2,32(sp)
    8000218a:	ec4e                	sd	s3,24(sp)
    8000218c:	e852                	sd	s4,16(sp)
    8000218e:	e456                	sd	s5,8(sp)
    80002190:	0080                	addi	s0,sp,64
    80002192:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002194:	00010497          	auipc	s1,0x10
    80002198:	7e448493          	addi	s1,s1,2020 # 80012978 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000219c:	4989                	li	s3,2
        p->state = RUNNABLE;
    8000219e:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800021a0:	00017917          	auipc	s2,0x17
    800021a4:	fd890913          	addi	s2,s2,-40 # 80019178 <tickslock>
    800021a8:	a801                	j	800021b8 <wakeup+0x38>
        add_to_run_queue(p);
      }
      release(&p->lock);
    800021aa:	8526                	mv	a0,s1
    800021ac:	abbfe0ef          	jal	80000c66 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800021b0:	1a048493          	addi	s1,s1,416
    800021b4:	03248563          	beq	s1,s2,800021de <wakeup+0x5e>
    if(p != myproc()){
    800021b8:	f56ff0ef          	jal	8000190e <myproc>
    800021bc:	fea48ae3          	beq	s1,a0,800021b0 <wakeup+0x30>
      acquire(&p->lock);
    800021c0:	8526                	mv	a0,s1
    800021c2:	a0dfe0ef          	jal	80000bce <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800021c6:	4c9c                	lw	a5,24(s1)
    800021c8:	ff3791e3          	bne	a5,s3,800021aa <wakeup+0x2a>
    800021cc:	709c                	ld	a5,32(s1)
    800021ce:	fd479ee3          	bne	a5,s4,800021aa <wakeup+0x2a>
        p->state = RUNNABLE;
    800021d2:	0154ac23          	sw	s5,24(s1)
        add_to_run_queue(p);
    800021d6:	8526                	mv	a0,s1
    800021d8:	a8dff0ef          	jal	80001c64 <add_to_run_queue>
    800021dc:	b7f9                	j	800021aa <wakeup+0x2a>
    }
  }
}
    800021de:	70e2                	ld	ra,56(sp)
    800021e0:	7442                	ld	s0,48(sp)
    800021e2:	74a2                	ld	s1,40(sp)
    800021e4:	7902                	ld	s2,32(sp)
    800021e6:	69e2                	ld	s3,24(sp)
    800021e8:	6a42                	ld	s4,16(sp)
    800021ea:	6aa2                	ld	s5,8(sp)
    800021ec:	6121                	addi	sp,sp,64
    800021ee:	8082                	ret

00000000800021f0 <reparent>:
{
    800021f0:	7179                	addi	sp,sp,-48
    800021f2:	f406                	sd	ra,40(sp)
    800021f4:	f022                	sd	s0,32(sp)
    800021f6:	ec26                	sd	s1,24(sp)
    800021f8:	e84a                	sd	s2,16(sp)
    800021fa:	e44e                	sd	s3,8(sp)
    800021fc:	e052                	sd	s4,0(sp)
    800021fe:	1800                	addi	s0,sp,48
    80002200:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002202:	00010497          	auipc	s1,0x10
    80002206:	77648493          	addi	s1,s1,1910 # 80012978 <proc>
      pp->parent = initproc;
    8000220a:	00008a17          	auipc	s4,0x8
    8000220e:	1f6a0a13          	addi	s4,s4,502 # 8000a400 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002212:	00017997          	auipc	s3,0x17
    80002216:	f6698993          	addi	s3,s3,-154 # 80019178 <tickslock>
    8000221a:	a029                	j	80002224 <reparent+0x34>
    8000221c:	1a048493          	addi	s1,s1,416
    80002220:	01348b63          	beq	s1,s3,80002236 <reparent+0x46>
    if(pp->parent == p){
    80002224:	7c9c                	ld	a5,56(s1)
    80002226:	ff279be3          	bne	a5,s2,8000221c <reparent+0x2c>
      pp->parent = initproc;
    8000222a:	000a3503          	ld	a0,0(s4)
    8000222e:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002230:	f51ff0ef          	jal	80002180 <wakeup>
    80002234:	b7e5                	j	8000221c <reparent+0x2c>
}
    80002236:	70a2                	ld	ra,40(sp)
    80002238:	7402                	ld	s0,32(sp)
    8000223a:	64e2                	ld	s1,24(sp)
    8000223c:	6942                	ld	s2,16(sp)
    8000223e:	69a2                	ld	s3,8(sp)
    80002240:	6a02                	ld	s4,0(sp)
    80002242:	6145                	addi	sp,sp,48
    80002244:	8082                	ret

0000000080002246 <kexit>:
{
    80002246:	7179                	addi	sp,sp,-48
    80002248:	f406                	sd	ra,40(sp)
    8000224a:	f022                	sd	s0,32(sp)
    8000224c:	ec26                	sd	s1,24(sp)
    8000224e:	e84a                	sd	s2,16(sp)
    80002250:	e44e                	sd	s3,8(sp)
    80002252:	e052                	sd	s4,0(sp)
    80002254:	1800                	addi	s0,sp,48
    80002256:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002258:	eb6ff0ef          	jal	8000190e <myproc>
    8000225c:	892a                	mv	s2,a0
  if(p == initproc)
    8000225e:	00008797          	auipc	a5,0x8
    80002262:	1a27b783          	ld	a5,418(a5) # 8000a400 <initproc>
    80002266:	0d050493          	addi	s1,a0,208
    8000226a:	15050993          	addi	s3,a0,336
    8000226e:	00a79f63          	bne	a5,a0,8000228c <kexit+0x46>
    panic("init exiting");
    80002272:	00005517          	auipc	a0,0x5
    80002276:	00650513          	addi	a0,a0,6 # 80007278 <etext+0x278>
    8000227a:	d66fe0ef          	jal	800007e0 <panic>
      fileclose(f);
    8000227e:	0d2020ef          	jal	80004350 <fileclose>
      p->ofile[fd] = 0;
    80002282:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002286:	04a1                	addi	s1,s1,8
    80002288:	01348563          	beq	s1,s3,80002292 <kexit+0x4c>
    if(p->ofile[fd]){
    8000228c:	6088                	ld	a0,0(s1)
    8000228e:	f965                	bnez	a0,8000227e <kexit+0x38>
    80002290:	bfdd                	j	80002286 <kexit+0x40>
  begin_op();
    80002292:	4b3010ef          	jal	80003f44 <begin_op>
  iput(p->cwd);
    80002296:	15093503          	ld	a0,336(s2)
    8000229a:	442010ef          	jal	800036dc <iput>
  end_op();
    8000229e:	511010ef          	jal	80003fae <end_op>
  p->cwd = 0;
    800022a2:	14093823          	sd	zero,336(s2)
  acquire(&wait_lock);
    800022a6:	00010517          	auipc	a0,0x10
    800022aa:	28a50513          	addi	a0,a0,650 # 80012530 <wait_lock>
    800022ae:	921fe0ef          	jal	80000bce <acquire>
  reparent(p);
    800022b2:	854a                	mv	a0,s2
    800022b4:	f3dff0ef          	jal	800021f0 <reparent>
  wakeup(p->parent);
    800022b8:	03893503          	ld	a0,56(s2)
    800022bc:	ec5ff0ef          	jal	80002180 <wakeup>
  acquire(&p->lock);
    800022c0:	854a                	mv	a0,s2
    800022c2:	90dfe0ef          	jal	80000bce <acquire>
  p->end_time = ticks;
    800022c6:	00008797          	auipc	a5,0x8
    800022ca:	1467a783          	lw	a5,326(a5) # 8000a40c <ticks>
    800022ce:	18f92623          	sw	a5,396(s2)
  int wait_time = p->end_time - p->creation_time - p->run_time;
    800022d2:	17092703          	lw	a4,368(s2)
    800022d6:	9f99                	subw	a5,a5,a4
    800022d8:	18892683          	lw	a3,392(s2)
    800022dc:	40d7873b          	subw	a4,a5,a3
  if (wait_time < 0) wait_time = 0; // Ensure wait time is not negative
    800022e0:	0007061b          	sext.w	a2,a4
    800022e4:	fff64613          	not	a2,a2
    800022e8:	967d                	srai	a2,a2,0x3f
    800022ea:	8f71                	and	a4,a4,a2
    800022ec:	2701                	sext.w	a4,a4
  int turnaround_time = p->end_time - p->creation_time;
    800022ee:	2781                	sext.w	a5,a5
  printf("PID %d | Type: %s | Run Time: %d | Wait Time: %d | Turnaround Time: %d\n",
    800022f0:	03092583          	lw	a1,48(s2)
    800022f4:	4539                	li	a0,14
    800022f6:	00005617          	auipc	a2,0x5
    800022fa:	f7260613          	addi	a2,a2,-142 # 80007268 <etext+0x268>
    800022fe:	00b54663          	blt	a0,a1,8000230a <kexit+0xc4>
    80002302:	00005617          	auipc	a2,0x5
    80002306:	f5660613          	addi	a2,a2,-170 # 80007258 <etext+0x258>
    8000230a:	00005517          	auipc	a0,0x5
    8000230e:	f7e50513          	addi	a0,a0,-130 # 80007288 <etext+0x288>
    80002312:	9e8fe0ef          	jal	800004fa <printf>
  p->xstate = status;
    80002316:	03492623          	sw	s4,44(s2)
  p->state = ZOMBIE;
    8000231a:	4795                	li	a5,5
    8000231c:	00f92c23          	sw	a5,24(s2)
  release(&wait_lock);
    80002320:	00010517          	auipc	a0,0x10
    80002324:	21050513          	addi	a0,a0,528 # 80012530 <wait_lock>
    80002328:	93ffe0ef          	jal	80000c66 <release>
  sched();
    8000232c:	cbdff0ef          	jal	80001fe8 <sched>
  panic("zombie exit");
    80002330:	00005517          	auipc	a0,0x5
    80002334:	fa050513          	addi	a0,a0,-96 # 800072d0 <etext+0x2d0>
    80002338:	ca8fe0ef          	jal	800007e0 <panic>

000000008000233c <kkill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kkill(int pid)
{
    8000233c:	7179                	addi	sp,sp,-48
    8000233e:	f406                	sd	ra,40(sp)
    80002340:	f022                	sd	s0,32(sp)
    80002342:	ec26                	sd	s1,24(sp)
    80002344:	e84a                	sd	s2,16(sp)
    80002346:	e44e                	sd	s3,8(sp)
    80002348:	1800                	addi	s0,sp,48
    8000234a:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000234c:	00010497          	auipc	s1,0x10
    80002350:	62c48493          	addi	s1,s1,1580 # 80012978 <proc>
    80002354:	00017997          	auipc	s3,0x17
    80002358:	e2498993          	addi	s3,s3,-476 # 80019178 <tickslock>
    acquire(&p->lock);
    8000235c:	8526                	mv	a0,s1
    8000235e:	871fe0ef          	jal	80000bce <acquire>
    if(p->pid == pid){
    80002362:	589c                	lw	a5,48(s1)
    80002364:	01278b63          	beq	a5,s2,8000237a <kkill+0x3e>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002368:	8526                	mv	a0,s1
    8000236a:	8fdfe0ef          	jal	80000c66 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000236e:	1a048493          	addi	s1,s1,416
    80002372:	ff3495e3          	bne	s1,s3,8000235c <kkill+0x20>
  }
  return -1;
    80002376:	557d                	li	a0,-1
    80002378:	a819                	j	8000238e <kkill+0x52>
      p->killed = 1;
    8000237a:	4785                	li	a5,1
    8000237c:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000237e:	4c98                	lw	a4,24(s1)
    80002380:	4789                	li	a5,2
    80002382:	00f70d63          	beq	a4,a5,8000239c <kkill+0x60>
      release(&p->lock);
    80002386:	8526                	mv	a0,s1
    80002388:	8dffe0ef          	jal	80000c66 <release>
      return 0;
    8000238c:	4501                	li	a0,0
}
    8000238e:	70a2                	ld	ra,40(sp)
    80002390:	7402                	ld	s0,32(sp)
    80002392:	64e2                	ld	s1,24(sp)
    80002394:	6942                	ld	s2,16(sp)
    80002396:	69a2                	ld	s3,8(sp)
    80002398:	6145                	addi	sp,sp,48
    8000239a:	8082                	ret
        p->state = RUNNABLE;
    8000239c:	478d                	li	a5,3
    8000239e:	cc9c                	sw	a5,24(s1)
    800023a0:	b7dd                	j	80002386 <kkill+0x4a>

00000000800023a2 <setkilled>:

void
setkilled(struct proc *p)
{
    800023a2:	1101                	addi	sp,sp,-32
    800023a4:	ec06                	sd	ra,24(sp)
    800023a6:	e822                	sd	s0,16(sp)
    800023a8:	e426                	sd	s1,8(sp)
    800023aa:	1000                	addi	s0,sp,32
    800023ac:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800023ae:	821fe0ef          	jal	80000bce <acquire>
  p->killed = 1;
    800023b2:	4785                	li	a5,1
    800023b4:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800023b6:	8526                	mv	a0,s1
    800023b8:	8affe0ef          	jal	80000c66 <release>
}
    800023bc:	60e2                	ld	ra,24(sp)
    800023be:	6442                	ld	s0,16(sp)
    800023c0:	64a2                	ld	s1,8(sp)
    800023c2:	6105                	addi	sp,sp,32
    800023c4:	8082                	ret

00000000800023c6 <killed>:

int
killed(struct proc *p)
{
    800023c6:	1101                	addi	sp,sp,-32
    800023c8:	ec06                	sd	ra,24(sp)
    800023ca:	e822                	sd	s0,16(sp)
    800023cc:	e426                	sd	s1,8(sp)
    800023ce:	e04a                	sd	s2,0(sp)
    800023d0:	1000                	addi	s0,sp,32
    800023d2:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    800023d4:	ffafe0ef          	jal	80000bce <acquire>
  k = p->killed;
    800023d8:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800023dc:	8526                	mv	a0,s1
    800023de:	889fe0ef          	jal	80000c66 <release>
  return k;
}
    800023e2:	854a                	mv	a0,s2
    800023e4:	60e2                	ld	ra,24(sp)
    800023e6:	6442                	ld	s0,16(sp)
    800023e8:	64a2                	ld	s1,8(sp)
    800023ea:	6902                	ld	s2,0(sp)
    800023ec:	6105                	addi	sp,sp,32
    800023ee:	8082                	ret

00000000800023f0 <kwait>:
{
    800023f0:	715d                	addi	sp,sp,-80
    800023f2:	e486                	sd	ra,72(sp)
    800023f4:	e0a2                	sd	s0,64(sp)
    800023f6:	fc26                	sd	s1,56(sp)
    800023f8:	f84a                	sd	s2,48(sp)
    800023fa:	f44e                	sd	s3,40(sp)
    800023fc:	f052                	sd	s4,32(sp)
    800023fe:	ec56                	sd	s5,24(sp)
    80002400:	e85a                	sd	s6,16(sp)
    80002402:	e45e                	sd	s7,8(sp)
    80002404:	e062                	sd	s8,0(sp)
    80002406:	0880                	addi	s0,sp,80
    80002408:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000240a:	d04ff0ef          	jal	8000190e <myproc>
    8000240e:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002410:	00010517          	auipc	a0,0x10
    80002414:	12050513          	addi	a0,a0,288 # 80012530 <wait_lock>
    80002418:	fb6fe0ef          	jal	80000bce <acquire>
    havekids = 0;
    8000241c:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    8000241e:	4a15                	li	s4,5
        havekids = 1;
    80002420:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002422:	00017997          	auipc	s3,0x17
    80002426:	d5698993          	addi	s3,s3,-682 # 80019178 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000242a:	00010c17          	auipc	s8,0x10
    8000242e:	106c0c13          	addi	s8,s8,262 # 80012530 <wait_lock>
    80002432:	a871                	j	800024ce <kwait+0xde>
          pid = pp->pid;
    80002434:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002438:	000b0c63          	beqz	s6,80002450 <kwait+0x60>
    8000243c:	4691                	li	a3,4
    8000243e:	02c48613          	addi	a2,s1,44
    80002442:	85da                	mv	a1,s6
    80002444:	05093503          	ld	a0,80(s2)
    80002448:	99aff0ef          	jal	800015e2 <copyout>
    8000244c:	02054b63          	bltz	a0,80002482 <kwait+0x92>
          freeproc(pp);
    80002450:	8526                	mv	a0,s1
    80002452:	e8cff0ef          	jal	80001ade <freeproc>
          release(&pp->lock);
    80002456:	8526                	mv	a0,s1
    80002458:	80ffe0ef          	jal	80000c66 <release>
          release(&wait_lock);
    8000245c:	00010517          	auipc	a0,0x10
    80002460:	0d450513          	addi	a0,a0,212 # 80012530 <wait_lock>
    80002464:	803fe0ef          	jal	80000c66 <release>
}
    80002468:	854e                	mv	a0,s3
    8000246a:	60a6                	ld	ra,72(sp)
    8000246c:	6406                	ld	s0,64(sp)
    8000246e:	74e2                	ld	s1,56(sp)
    80002470:	7942                	ld	s2,48(sp)
    80002472:	79a2                	ld	s3,40(sp)
    80002474:	7a02                	ld	s4,32(sp)
    80002476:	6ae2                	ld	s5,24(sp)
    80002478:	6b42                	ld	s6,16(sp)
    8000247a:	6ba2                	ld	s7,8(sp)
    8000247c:	6c02                	ld	s8,0(sp)
    8000247e:	6161                	addi	sp,sp,80
    80002480:	8082                	ret
            release(&pp->lock);
    80002482:	8526                	mv	a0,s1
    80002484:	fe2fe0ef          	jal	80000c66 <release>
            release(&wait_lock);
    80002488:	00010517          	auipc	a0,0x10
    8000248c:	0a850513          	addi	a0,a0,168 # 80012530 <wait_lock>
    80002490:	fd6fe0ef          	jal	80000c66 <release>
            return -1;
    80002494:	59fd                	li	s3,-1
    80002496:	bfc9                	j	80002468 <kwait+0x78>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002498:	1a048493          	addi	s1,s1,416
    8000249c:	03348063          	beq	s1,s3,800024bc <kwait+0xcc>
      if(pp->parent == p){
    800024a0:	7c9c                	ld	a5,56(s1)
    800024a2:	ff279be3          	bne	a5,s2,80002498 <kwait+0xa8>
        acquire(&pp->lock);
    800024a6:	8526                	mv	a0,s1
    800024a8:	f26fe0ef          	jal	80000bce <acquire>
        if(pp->state == ZOMBIE){
    800024ac:	4c9c                	lw	a5,24(s1)
    800024ae:	f94783e3          	beq	a5,s4,80002434 <kwait+0x44>
        release(&pp->lock);
    800024b2:	8526                	mv	a0,s1
    800024b4:	fb2fe0ef          	jal	80000c66 <release>
        havekids = 1;
    800024b8:	8756                	mv	a4,s5
    800024ba:	bff9                	j	80002498 <kwait+0xa8>
    if(!havekids || killed(p)){
    800024bc:	cf19                	beqz	a4,800024da <kwait+0xea>
    800024be:	854a                	mv	a0,s2
    800024c0:	f07ff0ef          	jal	800023c6 <killed>
    800024c4:	e919                	bnez	a0,800024da <kwait+0xea>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800024c6:	85e2                	mv	a1,s8
    800024c8:	854a                	mv	a0,s2
    800024ca:	c3bff0ef          	jal	80002104 <sleep>
    havekids = 0;
    800024ce:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800024d0:	00010497          	auipc	s1,0x10
    800024d4:	4a848493          	addi	s1,s1,1192 # 80012978 <proc>
    800024d8:	b7e1                	j	800024a0 <kwait+0xb0>
      release(&wait_lock);
    800024da:	00010517          	auipc	a0,0x10
    800024de:	05650513          	addi	a0,a0,86 # 80012530 <wait_lock>
    800024e2:	f84fe0ef          	jal	80000c66 <release>
      return -1;
    800024e6:	59fd                	li	s3,-1
    800024e8:	b741                	j	80002468 <kwait+0x78>

00000000800024ea <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024ea:	7179                	addi	sp,sp,-48
    800024ec:	f406                	sd	ra,40(sp)
    800024ee:	f022                	sd	s0,32(sp)
    800024f0:	ec26                	sd	s1,24(sp)
    800024f2:	e84a                	sd	s2,16(sp)
    800024f4:	e44e                	sd	s3,8(sp)
    800024f6:	e052                	sd	s4,0(sp)
    800024f8:	1800                	addi	s0,sp,48
    800024fa:	84aa                	mv	s1,a0
    800024fc:	892e                	mv	s2,a1
    800024fe:	89b2                	mv	s3,a2
    80002500:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002502:	c0cff0ef          	jal	8000190e <myproc>
  if(user_dst){
    80002506:	cc99                	beqz	s1,80002524 <either_copyout+0x3a>
    return copyout(p->pagetable, dst, src, len);
    80002508:	86d2                	mv	a3,s4
    8000250a:	864e                	mv	a2,s3
    8000250c:	85ca                	mv	a1,s2
    8000250e:	6928                	ld	a0,80(a0)
    80002510:	8d2ff0ef          	jal	800015e2 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002514:	70a2                	ld	ra,40(sp)
    80002516:	7402                	ld	s0,32(sp)
    80002518:	64e2                	ld	s1,24(sp)
    8000251a:	6942                	ld	s2,16(sp)
    8000251c:	69a2                	ld	s3,8(sp)
    8000251e:	6a02                	ld	s4,0(sp)
    80002520:	6145                	addi	sp,sp,48
    80002522:	8082                	ret
    memmove((char *)dst, src, len);
    80002524:	000a061b          	sext.w	a2,s4
    80002528:	85ce                	mv	a1,s3
    8000252a:	854a                	mv	a0,s2
    8000252c:	fd2fe0ef          	jal	80000cfe <memmove>
    return 0;
    80002530:	8526                	mv	a0,s1
    80002532:	b7cd                	j	80002514 <either_copyout+0x2a>

0000000080002534 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002534:	7179                	addi	sp,sp,-48
    80002536:	f406                	sd	ra,40(sp)
    80002538:	f022                	sd	s0,32(sp)
    8000253a:	ec26                	sd	s1,24(sp)
    8000253c:	e84a                	sd	s2,16(sp)
    8000253e:	e44e                	sd	s3,8(sp)
    80002540:	e052                	sd	s4,0(sp)
    80002542:	1800                	addi	s0,sp,48
    80002544:	892a                	mv	s2,a0
    80002546:	84ae                	mv	s1,a1
    80002548:	89b2                	mv	s3,a2
    8000254a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000254c:	bc2ff0ef          	jal	8000190e <myproc>
  if(user_src){
    80002550:	cc99                	beqz	s1,8000256e <either_copyin+0x3a>
    return copyin(p->pagetable, dst, src, len);
    80002552:	86d2                	mv	a3,s4
    80002554:	864e                	mv	a2,s3
    80002556:	85ca                	mv	a1,s2
    80002558:	6928                	ld	a0,80(a0)
    8000255a:	96cff0ef          	jal	800016c6 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000255e:	70a2                	ld	ra,40(sp)
    80002560:	7402                	ld	s0,32(sp)
    80002562:	64e2                	ld	s1,24(sp)
    80002564:	6942                	ld	s2,16(sp)
    80002566:	69a2                	ld	s3,8(sp)
    80002568:	6a02                	ld	s4,0(sp)
    8000256a:	6145                	addi	sp,sp,48
    8000256c:	8082                	ret
    memmove(dst, (char*)src, len);
    8000256e:	000a061b          	sext.w	a2,s4
    80002572:	85ce                	mv	a1,s3
    80002574:	854a                	mv	a0,s2
    80002576:	f88fe0ef          	jal	80000cfe <memmove>
    return 0;
    8000257a:	8526                	mv	a0,s1
    8000257c:	b7cd                	j	8000255e <either_copyin+0x2a>

000000008000257e <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000257e:	715d                	addi	sp,sp,-80
    80002580:	e486                	sd	ra,72(sp)
    80002582:	e0a2                	sd	s0,64(sp)
    80002584:	fc26                	sd	s1,56(sp)
    80002586:	f84a                	sd	s2,48(sp)
    80002588:	f44e                	sd	s3,40(sp)
    8000258a:	f052                	sd	s4,32(sp)
    8000258c:	ec56                	sd	s5,24(sp)
    8000258e:	e85a                	sd	s6,16(sp)
    80002590:	e45e                	sd	s7,8(sp)
    80002592:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002594:	00005517          	auipc	a0,0x5
    80002598:	c7450513          	addi	a0,a0,-908 # 80007208 <etext+0x208>
    8000259c:	f5ffd0ef          	jal	800004fa <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025a0:	00010497          	auipc	s1,0x10
    800025a4:	53048493          	addi	s1,s1,1328 # 80012ad0 <proc+0x158>
    800025a8:	00017917          	auipc	s2,0x17
    800025ac:	d2890913          	addi	s2,s2,-728 # 800192d0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025b0:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800025b2:	00005997          	auipc	s3,0x5
    800025b6:	d2e98993          	addi	s3,s3,-722 # 800072e0 <etext+0x2e0>
    printf("%d %s %s nice:%d vruntime:%d creation_time:%d", p->pid, state, p->name, p->nice, p->vruntime, p->creation_time);
    800025ba:	00005a97          	auipc	s5,0x5
    800025be:	d2ea8a93          	addi	s5,s5,-722 # 800072e8 <etext+0x2e8>
    printf("\n");
    800025c2:	00005a17          	auipc	s4,0x5
    800025c6:	c46a0a13          	addi	s4,s4,-954 # 80007208 <etext+0x208>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025ca:	00005b97          	auipc	s7,0x5
    800025ce:	25eb8b93          	addi	s7,s7,606 # 80007828 <NICE_TO_WEIGHT>
    800025d2:	a00d                	j	800025f4 <procdump+0x76>
    printf("%d %s %s nice:%d vruntime:%d creation_time:%d", p->pid, state, p->name, p->nice, p->vruntime, p->creation_time);
    800025d4:	0186a803          	lw	a6,24(a3)
    800025d8:	4adc                	lw	a5,20(a3)
    800025da:	4a98                	lw	a4,16(a3)
    800025dc:	ed86a583          	lw	a1,-296(a3)
    800025e0:	8556                	mv	a0,s5
    800025e2:	f19fd0ef          	jal	800004fa <printf>
    printf("\n");
    800025e6:	8552                	mv	a0,s4
    800025e8:	f13fd0ef          	jal	800004fa <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025ec:	1a048493          	addi	s1,s1,416
    800025f0:	03248263          	beq	s1,s2,80002614 <procdump+0x96>
    if(p->state == UNUSED)
    800025f4:	86a6                	mv	a3,s1
    800025f6:	ec04a783          	lw	a5,-320(s1)
    800025fa:	dbed                	beqz	a5,800025ec <procdump+0x6e>
      state = "???";
    800025fc:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025fe:	fcfb6be3          	bltu	s6,a5,800025d4 <procdump+0x56>
    80002602:	02079713          	slli	a4,a5,0x20
    80002606:	01d75793          	srli	a5,a4,0x1d
    8000260a:	97de                	add	a5,a5,s7
    8000260c:	73d0                	ld	a2,160(a5)
    8000260e:	f279                	bnez	a2,800025d4 <procdump+0x56>
      state = "???";
    80002610:	864e                	mv	a2,s3
    80002612:	b7c9                	j	800025d4 <procdump+0x56>
  }
}
    80002614:	60a6                	ld	ra,72(sp)
    80002616:	6406                	ld	s0,64(sp)
    80002618:	74e2                	ld	s1,56(sp)
    8000261a:	7942                	ld	s2,48(sp)
    8000261c:	79a2                	ld	s3,40(sp)
    8000261e:	7a02                	ld	s4,32(sp)
    80002620:	6ae2                	ld	s5,24(sp)
    80002622:	6b42                	ld	s6,16(sp)
    80002624:	6ba2                	ld	s7,8(sp)
    80002626:	6161                	addi	sp,sp,80
    80002628:	8082                	ret

000000008000262a <swtch>:
# Save current registers in old. Load from new.	


.globl swtch
swtch:
        sd ra, 0(a0)
    8000262a:	00153023          	sd	ra,0(a0)
        sd sp, 8(a0)
    8000262e:	00253423          	sd	sp,8(a0)
        sd s0, 16(a0)
    80002632:	e900                	sd	s0,16(a0)
        sd s1, 24(a0)
    80002634:	ed04                	sd	s1,24(a0)
        sd s2, 32(a0)
    80002636:	03253023          	sd	s2,32(a0)
        sd s3, 40(a0)
    8000263a:	03353423          	sd	s3,40(a0)
        sd s4, 48(a0)
    8000263e:	03453823          	sd	s4,48(a0)
        sd s5, 56(a0)
    80002642:	03553c23          	sd	s5,56(a0)
        sd s6, 64(a0)
    80002646:	05653023          	sd	s6,64(a0)
        sd s7, 72(a0)
    8000264a:	05753423          	sd	s7,72(a0)
        sd s8, 80(a0)
    8000264e:	05853823          	sd	s8,80(a0)
        sd s9, 88(a0)
    80002652:	05953c23          	sd	s9,88(a0)
        sd s10, 96(a0)
    80002656:	07a53023          	sd	s10,96(a0)
        sd s11, 104(a0)
    8000265a:	07b53423          	sd	s11,104(a0)

        ld ra, 0(a1)
    8000265e:	0005b083          	ld	ra,0(a1)
        ld sp, 8(a1)
    80002662:	0085b103          	ld	sp,8(a1)
        ld s0, 16(a1)
    80002666:	6980                	ld	s0,16(a1)
        ld s1, 24(a1)
    80002668:	6d84                	ld	s1,24(a1)
        ld s2, 32(a1)
    8000266a:	0205b903          	ld	s2,32(a1)
        ld s3, 40(a1)
    8000266e:	0285b983          	ld	s3,40(a1)
        ld s4, 48(a1)
    80002672:	0305ba03          	ld	s4,48(a1)
        ld s5, 56(a1)
    80002676:	0385ba83          	ld	s5,56(a1)
        ld s6, 64(a1)
    8000267a:	0405bb03          	ld	s6,64(a1)
        ld s7, 72(a1)
    8000267e:	0485bb83          	ld	s7,72(a1)
        ld s8, 80(a1)
    80002682:	0505bc03          	ld	s8,80(a1)
        ld s9, 88(a1)
    80002686:	0585bc83          	ld	s9,88(a1)
        ld s10, 96(a1)
    8000268a:	0605bd03          	ld	s10,96(a1)
        ld s11, 104(a1)
    8000268e:	0685bd83          	ld	s11,104(a1)
        
        ret
    80002692:	8082                	ret

0000000080002694 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002694:	1141                	addi	sp,sp,-16
    80002696:	e406                	sd	ra,8(sp)
    80002698:	e022                	sd	s0,0(sp)
    8000269a:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000269c:	00005597          	auipc	a1,0x5
    800026a0:	cac58593          	addi	a1,a1,-852 # 80007348 <etext+0x348>
    800026a4:	00017517          	auipc	a0,0x17
    800026a8:	ad450513          	addi	a0,a0,-1324 # 80019178 <tickslock>
    800026ac:	ca2fe0ef          	jal	80000b4e <initlock>
}
    800026b0:	60a2                	ld	ra,8(sp)
    800026b2:	6402                	ld	s0,0(sp)
    800026b4:	0141                	addi	sp,sp,16
    800026b6:	8082                	ret

00000000800026b8 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800026b8:	1141                	addi	sp,sp,-16
    800026ba:	e422                	sd	s0,8(sp)
    800026bc:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026be:	00003797          	auipc	a5,0x3
    800026c2:	02278793          	addi	a5,a5,34 # 800056e0 <kernelvec>
    800026c6:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800026ca:	6422                	ld	s0,8(sp)
    800026cc:	0141                	addi	sp,sp,16
    800026ce:	8082                	ret

00000000800026d0 <prepare_return>:
//
// set up trapframe and control registers for a return to user space
//
void
prepare_return(void)
{
    800026d0:	1141                	addi	sp,sp,-16
    800026d2:	e406                	sd	ra,8(sp)
    800026d4:	e022                	sd	s0,0(sp)
    800026d6:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800026d8:	a36ff0ef          	jal	8000190e <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026dc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800026e0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026e2:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(). because a trap from kernel
  // code to usertrap would be a disaster, turn off interrupts.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    800026e6:	04000737          	lui	a4,0x4000
    800026ea:	177d                	addi	a4,a4,-1 # 3ffffff <_entry-0x7c000001>
    800026ec:	0732                	slli	a4,a4,0xc
    800026ee:	00004797          	auipc	a5,0x4
    800026f2:	91278793          	addi	a5,a5,-1774 # 80006000 <_trampoline>
    800026f6:	00004697          	auipc	a3,0x4
    800026fa:	90a68693          	addi	a3,a3,-1782 # 80006000 <_trampoline>
    800026fe:	8f95                	sub	a5,a5,a3
    80002700:	97ba                	add	a5,a5,a4
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002702:	10579073          	csrw	stvec,a5
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002706:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002708:	18002773          	csrr	a4,satp
    8000270c:	e398                	sd	a4,0(a5)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000270e:	6d38                	ld	a4,88(a0)
    80002710:	613c                	ld	a5,64(a0)
    80002712:	6685                	lui	a3,0x1
    80002714:	97b6                	add	a5,a5,a3
    80002716:	e71c                	sd	a5,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002718:	6d3c                	ld	a5,88(a0)
    8000271a:	00000717          	auipc	a4,0x0
    8000271e:	0f870713          	addi	a4,a4,248 # 80002812 <usertrap>
    80002722:	eb98                	sd	a4,16(a5)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002724:	6d3c                	ld	a5,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002726:	8712                	mv	a4,tp
    80002728:	f398                	sd	a4,32(a5)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000272a:	100027f3          	csrr	a5,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000272e:	eff7f793          	andi	a5,a5,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002732:	0207e793          	ori	a5,a5,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002736:	10079073          	csrw	sstatus,a5
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000273a:	6d3c                	ld	a5,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000273c:	6f9c                	ld	a5,24(a5)
    8000273e:	14179073          	csrw	sepc,a5
}
    80002742:	60a2                	ld	ra,8(sp)
    80002744:	6402                	ld	s0,0(sp)
    80002746:	0141                	addi	sp,sp,16
    80002748:	8082                	ret

000000008000274a <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000274a:	1101                	addi	sp,sp,-32
    8000274c:	ec06                	sd	ra,24(sp)
    8000274e:	e822                	sd	s0,16(sp)
    80002750:	1000                	addi	s0,sp,32
  if(cpuid() == 0){
    80002752:	990ff0ef          	jal	800018e2 <cpuid>
    80002756:	cd11                	beqz	a0,80002772 <clockintr+0x28>
  asm volatile("csrr %0, time" : "=r" (x) );
    80002758:	c01027f3          	rdtime	a5
  }

  // ask for the next timer interrupt. this also clears
  // the interrupt request. 1000000 is about a tenth
  // of a second.
  w_stimecmp(r_time() + 1000000);
    8000275c:	000f4737          	lui	a4,0xf4
    80002760:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80002764:	97ba                	add	a5,a5,a4
  asm volatile("csrw 0x14d, %0" : : "r" (x));
    80002766:	14d79073          	csrw	stimecmp,a5
}
    8000276a:	60e2                	ld	ra,24(sp)
    8000276c:	6442                	ld	s0,16(sp)
    8000276e:	6105                	addi	sp,sp,32
    80002770:	8082                	ret
    80002772:	e426                	sd	s1,8(sp)
    acquire(&tickslock);
    80002774:	00017497          	auipc	s1,0x17
    80002778:	a0448493          	addi	s1,s1,-1532 # 80019178 <tickslock>
    8000277c:	8526                	mv	a0,s1
    8000277e:	c50fe0ef          	jal	80000bce <acquire>
    ticks++;
    80002782:	00008517          	auipc	a0,0x8
    80002786:	c8a50513          	addi	a0,a0,-886 # 8000a40c <ticks>
    8000278a:	411c                	lw	a5,0(a0)
    8000278c:	2785                	addiw	a5,a5,1
    8000278e:	c11c                	sw	a5,0(a0)
    wakeup(&ticks);
    80002790:	9f1ff0ef          	jal	80002180 <wakeup>
    release(&tickslock);
    80002794:	8526                	mv	a0,s1
    80002796:	cd0fe0ef          	jal	80000c66 <release>
    8000279a:	64a2                	ld	s1,8(sp)
    8000279c:	bf75                	j	80002758 <clockintr+0xe>

000000008000279e <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000279e:	1101                	addi	sp,sp,-32
    800027a0:	ec06                	sd	ra,24(sp)
    800027a2:	e822                	sd	s0,16(sp)
    800027a4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027a6:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if(scause == 0x8000000000000009L){
    800027aa:	57fd                	li	a5,-1
    800027ac:	17fe                	slli	a5,a5,0x3f
    800027ae:	07a5                	addi	a5,a5,9
    800027b0:	00f70c63          	beq	a4,a5,800027c8 <devintr+0x2a>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000005L){
    800027b4:	57fd                	li	a5,-1
    800027b6:	17fe                	slli	a5,a5,0x3f
    800027b8:	0795                	addi	a5,a5,5
    // timer interrupt.
    clockintr();
    return 2;
  } else {
    return 0;
    800027ba:	4501                	li	a0,0
  } else if(scause == 0x8000000000000005L){
    800027bc:	04f70763          	beq	a4,a5,8000280a <devintr+0x6c>
  }
}
    800027c0:	60e2                	ld	ra,24(sp)
    800027c2:	6442                	ld	s0,16(sp)
    800027c4:	6105                	addi	sp,sp,32
    800027c6:	8082                	ret
    800027c8:	e426                	sd	s1,8(sp)
    int irq = plic_claim();
    800027ca:	7c3020ef          	jal	8000578c <plic_claim>
    800027ce:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800027d0:	47a9                	li	a5,10
    800027d2:	00f50963          	beq	a0,a5,800027e4 <devintr+0x46>
    } else if(irq == VIRTIO0_IRQ){
    800027d6:	4785                	li	a5,1
    800027d8:	00f50963          	beq	a0,a5,800027ea <devintr+0x4c>
    return 1;
    800027dc:	4505                	li	a0,1
    } else if(irq){
    800027de:	e889                	bnez	s1,800027f0 <devintr+0x52>
    800027e0:	64a2                	ld	s1,8(sp)
    800027e2:	bff9                	j	800027c0 <devintr+0x22>
      uartintr();
    800027e4:	9ccfe0ef          	jal	800009b0 <uartintr>
    if(irq)
    800027e8:	a819                	j	800027fe <devintr+0x60>
      virtio_disk_intr();
    800027ea:	468030ef          	jal	80005c52 <virtio_disk_intr>
    if(irq)
    800027ee:	a801                	j	800027fe <devintr+0x60>
      printf("unexpected interrupt irq=%d\n", irq);
    800027f0:	85a6                	mv	a1,s1
    800027f2:	00005517          	auipc	a0,0x5
    800027f6:	b5e50513          	addi	a0,a0,-1186 # 80007350 <etext+0x350>
    800027fa:	d01fd0ef          	jal	800004fa <printf>
      plic_complete(irq);
    800027fe:	8526                	mv	a0,s1
    80002800:	7ad020ef          	jal	800057ac <plic_complete>
    return 1;
    80002804:	4505                	li	a0,1
    80002806:	64a2                	ld	s1,8(sp)
    80002808:	bf65                	j	800027c0 <devintr+0x22>
    clockintr();
    8000280a:	f41ff0ef          	jal	8000274a <clockintr>
    return 2;
    8000280e:	4509                	li	a0,2
    80002810:	bf45                	j	800027c0 <devintr+0x22>

0000000080002812 <usertrap>:
{
    80002812:	1101                	addi	sp,sp,-32
    80002814:	ec06                	sd	ra,24(sp)
    80002816:	e822                	sd	s0,16(sp)
    80002818:	e426                	sd	s1,8(sp)
    8000281a:	e04a                	sd	s2,0(sp)
    8000281c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000281e:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002822:	1007f793          	andi	a5,a5,256
    80002826:	eba5                	bnez	a5,80002896 <usertrap+0x84>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002828:	00003797          	auipc	a5,0x3
    8000282c:	eb878793          	addi	a5,a5,-328 # 800056e0 <kernelvec>
    80002830:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002834:	8daff0ef          	jal	8000190e <myproc>
    80002838:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000283a:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000283c:	14102773          	csrr	a4,sepc
    80002840:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002842:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002846:	47a1                	li	a5,8
    80002848:	04f70d63          	beq	a4,a5,800028a2 <usertrap+0x90>
  } else if((which_dev = devintr()) != 0){
    8000284c:	f53ff0ef          	jal	8000279e <devintr>
    80002850:	892a                	mv	s2,a0
    80002852:	e945                	bnez	a0,80002902 <usertrap+0xf0>
    80002854:	14202773          	csrr	a4,scause
  } else if((r_scause() == 15 || r_scause() == 13) &&
    80002858:	47bd                	li	a5,15
    8000285a:	08f70863          	beq	a4,a5,800028ea <usertrap+0xd8>
    8000285e:	14202773          	csrr	a4,scause
    80002862:	47b5                	li	a5,13
    80002864:	08f70363          	beq	a4,a5,800028ea <usertrap+0xd8>
    80002868:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause 0x%lx pid=%d\n", r_scause(), p->pid);
    8000286c:	5890                	lw	a2,48(s1)
    8000286e:	00005517          	auipc	a0,0x5
    80002872:	b2250513          	addi	a0,a0,-1246 # 80007390 <etext+0x390>
    80002876:	c85fd0ef          	jal	800004fa <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000287a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000287e:	14302673          	csrr	a2,stval
    printf("            sepc=0x%lx stval=0x%lx\n", r_sepc(), r_stval());
    80002882:	00005517          	auipc	a0,0x5
    80002886:	b3e50513          	addi	a0,a0,-1218 # 800073c0 <etext+0x3c0>
    8000288a:	c71fd0ef          	jal	800004fa <printf>
    setkilled(p);
    8000288e:	8526                	mv	a0,s1
    80002890:	b13ff0ef          	jal	800023a2 <setkilled>
    80002894:	a035                	j	800028c0 <usertrap+0xae>
    panic("usertrap: not from user mode");
    80002896:	00005517          	auipc	a0,0x5
    8000289a:	ada50513          	addi	a0,a0,-1318 # 80007370 <etext+0x370>
    8000289e:	f43fd0ef          	jal	800007e0 <panic>
    if(killed(p))
    800028a2:	b25ff0ef          	jal	800023c6 <killed>
    800028a6:	ed15                	bnez	a0,800028e2 <usertrap+0xd0>
    p->trapframe->epc += 4;
    800028a8:	6cb8                	ld	a4,88(s1)
    800028aa:	6f1c                	ld	a5,24(a4)
    800028ac:	0791                	addi	a5,a5,4
    800028ae:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028b0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800028b4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028b8:	10079073          	csrw	sstatus,a5
    syscall();
    800028bc:	2ae000ef          	jal	80002b6a <syscall>
  if(killed(p))
    800028c0:	8526                	mv	a0,s1
    800028c2:	b05ff0ef          	jal	800023c6 <killed>
    800028c6:	e139                	bnez	a0,8000290c <usertrap+0xfa>
  prepare_return();
    800028c8:	e09ff0ef          	jal	800026d0 <prepare_return>
  uint64 satp = MAKE_SATP(p->pagetable);
    800028cc:	68a8                	ld	a0,80(s1)
    800028ce:	8131                	srli	a0,a0,0xc
    800028d0:	57fd                	li	a5,-1
    800028d2:	17fe                	slli	a5,a5,0x3f
    800028d4:	8d5d                	or	a0,a0,a5
}
    800028d6:	60e2                	ld	ra,24(sp)
    800028d8:	6442                	ld	s0,16(sp)
    800028da:	64a2                	ld	s1,8(sp)
    800028dc:	6902                	ld	s2,0(sp)
    800028de:	6105                	addi	sp,sp,32
    800028e0:	8082                	ret
      kexit(-1);
    800028e2:	557d                	li	a0,-1
    800028e4:	963ff0ef          	jal	80002246 <kexit>
    800028e8:	b7c1                	j	800028a8 <usertrap+0x96>
  asm volatile("csrr %0, stval" : "=r" (x) );
    800028ea:	143025f3          	csrr	a1,stval
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028ee:	14202673          	csrr	a2,scause
            vmfault(p->pagetable, r_stval(), (r_scause() == 13)? 1 : 0) != 0) {
    800028f2:	164d                	addi	a2,a2,-13
    800028f4:	00163613          	seqz	a2,a2
    800028f8:	68a8                	ld	a0,80(s1)
    800028fa:	c67fe0ef          	jal	80001560 <vmfault>
  } else if((r_scause() == 15 || r_scause() == 13) &&
    800028fe:	f169                	bnez	a0,800028c0 <usertrap+0xae>
    80002900:	b7a5                	j	80002868 <usertrap+0x56>
  if(killed(p))
    80002902:	8526                	mv	a0,s1
    80002904:	ac3ff0ef          	jal	800023c6 <killed>
    80002908:	c511                	beqz	a0,80002914 <usertrap+0x102>
    8000290a:	a011                	j	8000290e <usertrap+0xfc>
    8000290c:	4901                	li	s2,0
    kexit(-1);
    8000290e:	557d                	li	a0,-1
    80002910:	937ff0ef          	jal	80002246 <kexit>
  if(which_dev == 2){
    80002914:	4789                	li	a5,2
    80002916:	faf919e3          	bne	s2,a5,800028c8 <usertrap+0xb6>
    myproc()->run_time++;
    8000291a:	ff5fe0ef          	jal	8000190e <myproc>
    8000291e:	18852783          	lw	a5,392(a0)
    80002922:	2785                	addiw	a5,a5,1
    80002924:	18f52423          	sw	a5,392(a0)
    p->ticks++;
    80002928:	1744a783          	lw	a5,372(s1)
    8000292c:	2785                	addiw	a5,a5,1
    8000292e:	16f4aa23          	sw	a5,372(s1)
    if(--p->time_slice <= 0){
    80002932:	1844a783          	lw	a5,388(s1)
    80002936:	37fd                	addiw	a5,a5,-1
    80002938:	0007871b          	sext.w	a4,a5
    8000293c:	18f4a223          	sw	a5,388(s1)
    80002940:	f8e044e3          	bgtz	a4,800028c8 <usertrap+0xb6>
      yield();
    80002944:	f5eff0ef          	jal	800020a2 <yield>
    80002948:	b741                	j	800028c8 <usertrap+0xb6>

000000008000294a <kerneltrap>:
{
    8000294a:	7179                	addi	sp,sp,-48
    8000294c:	f406                	sd	ra,40(sp)
    8000294e:	f022                	sd	s0,32(sp)
    80002950:	ec26                	sd	s1,24(sp)
    80002952:	e84a                	sd	s2,16(sp)
    80002954:	e44e                	sd	s3,8(sp)
    80002956:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002958:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000295c:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002960:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002964:	1004f793          	andi	a5,s1,256
    80002968:	c795                	beqz	a5,80002994 <kerneltrap+0x4a>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000296a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000296e:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002970:	eb85                	bnez	a5,800029a0 <kerneltrap+0x56>
  if((which_dev = devintr()) == 0){
    80002972:	e2dff0ef          	jal	8000279e <devintr>
    80002976:	c91d                	beqz	a0,800029ac <kerneltrap+0x62>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING){
    80002978:	4789                	li	a5,2
    8000297a:	04f50a63          	beq	a0,a5,800029ce <kerneltrap+0x84>
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000297e:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002982:	10049073          	csrw	sstatus,s1
}
    80002986:	70a2                	ld	ra,40(sp)
    80002988:	7402                	ld	s0,32(sp)
    8000298a:	64e2                	ld	s1,24(sp)
    8000298c:	6942                	ld	s2,16(sp)
    8000298e:	69a2                	ld	s3,8(sp)
    80002990:	6145                	addi	sp,sp,48
    80002992:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002994:	00005517          	auipc	a0,0x5
    80002998:	a5450513          	addi	a0,a0,-1452 # 800073e8 <etext+0x3e8>
    8000299c:	e45fd0ef          	jal	800007e0 <panic>
    panic("kerneltrap: interrupts enabled");
    800029a0:	00005517          	auipc	a0,0x5
    800029a4:	a7050513          	addi	a0,a0,-1424 # 80007410 <etext+0x410>
    800029a8:	e39fd0ef          	jal	800007e0 <panic>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029ac:	14102673          	csrr	a2,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029b0:	143026f3          	csrr	a3,stval
    printf("scause=0x%lx sepc=0x%lx stval=0x%lx\n", scause, r_sepc(), r_stval());
    800029b4:	85ce                	mv	a1,s3
    800029b6:	00005517          	auipc	a0,0x5
    800029ba:	a7a50513          	addi	a0,a0,-1414 # 80007430 <etext+0x430>
    800029be:	b3dfd0ef          	jal	800004fa <printf>
    panic("kerneltrap");
    800029c2:	00005517          	auipc	a0,0x5
    800029c6:	a9650513          	addi	a0,a0,-1386 # 80007458 <etext+0x458>
    800029ca:	e17fd0ef          	jal	800007e0 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING){
    800029ce:	f41fe0ef          	jal	8000190e <myproc>
    800029d2:	d555                	beqz	a0,8000297e <kerneltrap+0x34>
    800029d4:	f3bfe0ef          	jal	8000190e <myproc>
    800029d8:	4d18                	lw	a4,24(a0)
    800029da:	4791                	li	a5,4
    800029dc:	faf711e3          	bne	a4,a5,8000297e <kerneltrap+0x34>
    myproc()->run_time++;
    800029e0:	f2ffe0ef          	jal	8000190e <myproc>
    800029e4:	18852783          	lw	a5,392(a0)
    800029e8:	2785                	addiw	a5,a5,1
    800029ea:	18f52423          	sw	a5,392(a0)
    myproc()->ticks++;
    800029ee:	f21fe0ef          	jal	8000190e <myproc>
    800029f2:	17452783          	lw	a5,372(a0)
    800029f6:	2785                	addiw	a5,a5,1
    800029f8:	16f52a23          	sw	a5,372(a0)
    if(--myproc()->time_slice <= 0){
    800029fc:	f13fe0ef          	jal	8000190e <myproc>
    80002a00:	18452783          	lw	a5,388(a0)
    80002a04:	37fd                	addiw	a5,a5,-1
    80002a06:	0007871b          	sext.w	a4,a5
    80002a0a:	18f52223          	sw	a5,388(a0)
    80002a0e:	f6e048e3          	bgtz	a4,8000297e <kerneltrap+0x34>
      yield();
    80002a12:	e90ff0ef          	jal	800020a2 <yield>
    80002a16:	b7a5                	j	8000297e <kerneltrap+0x34>

0000000080002a18 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a18:	1101                	addi	sp,sp,-32
    80002a1a:	ec06                	sd	ra,24(sp)
    80002a1c:	e822                	sd	s0,16(sp)
    80002a1e:	e426                	sd	s1,8(sp)
    80002a20:	1000                	addi	s0,sp,32
    80002a22:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a24:	eebfe0ef          	jal	8000190e <myproc>
  switch (n) {
    80002a28:	4795                	li	a5,5
    80002a2a:	0497e163          	bltu	a5,s1,80002a6c <argraw+0x54>
    80002a2e:	048a                	slli	s1,s1,0x2
    80002a30:	00005717          	auipc	a4,0x5
    80002a34:	ec870713          	addi	a4,a4,-312 # 800078f8 <states.0+0x30>
    80002a38:	94ba                	add	s1,s1,a4
    80002a3a:	409c                	lw	a5,0(s1)
    80002a3c:	97ba                	add	a5,a5,a4
    80002a3e:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a40:	6d3c                	ld	a5,88(a0)
    80002a42:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a44:	60e2                	ld	ra,24(sp)
    80002a46:	6442                	ld	s0,16(sp)
    80002a48:	64a2                	ld	s1,8(sp)
    80002a4a:	6105                	addi	sp,sp,32
    80002a4c:	8082                	ret
    return p->trapframe->a1;
    80002a4e:	6d3c                	ld	a5,88(a0)
    80002a50:	7fa8                	ld	a0,120(a5)
    80002a52:	bfcd                	j	80002a44 <argraw+0x2c>
    return p->trapframe->a2;
    80002a54:	6d3c                	ld	a5,88(a0)
    80002a56:	63c8                	ld	a0,128(a5)
    80002a58:	b7f5                	j	80002a44 <argraw+0x2c>
    return p->trapframe->a3;
    80002a5a:	6d3c                	ld	a5,88(a0)
    80002a5c:	67c8                	ld	a0,136(a5)
    80002a5e:	b7dd                	j	80002a44 <argraw+0x2c>
    return p->trapframe->a4;
    80002a60:	6d3c                	ld	a5,88(a0)
    80002a62:	6bc8                	ld	a0,144(a5)
    80002a64:	b7c5                	j	80002a44 <argraw+0x2c>
    return p->trapframe->a5;
    80002a66:	6d3c                	ld	a5,88(a0)
    80002a68:	6fc8                	ld	a0,152(a5)
    80002a6a:	bfe9                	j	80002a44 <argraw+0x2c>
  panic("argraw");
    80002a6c:	00005517          	auipc	a0,0x5
    80002a70:	9fc50513          	addi	a0,a0,-1540 # 80007468 <etext+0x468>
    80002a74:	d6dfd0ef          	jal	800007e0 <panic>

0000000080002a78 <fetchaddr>:
{
    80002a78:	1101                	addi	sp,sp,-32
    80002a7a:	ec06                	sd	ra,24(sp)
    80002a7c:	e822                	sd	s0,16(sp)
    80002a7e:	e426                	sd	s1,8(sp)
    80002a80:	e04a                	sd	s2,0(sp)
    80002a82:	1000                	addi	s0,sp,32
    80002a84:	84aa                	mv	s1,a0
    80002a86:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002a88:	e87fe0ef          	jal	8000190e <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002a8c:	653c                	ld	a5,72(a0)
    80002a8e:	02f4f663          	bgeu	s1,a5,80002aba <fetchaddr+0x42>
    80002a92:	00848713          	addi	a4,s1,8
    80002a96:	02e7e463          	bltu	a5,a4,80002abe <fetchaddr+0x46>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002a9a:	46a1                	li	a3,8
    80002a9c:	8626                	mv	a2,s1
    80002a9e:	85ca                	mv	a1,s2
    80002aa0:	6928                	ld	a0,80(a0)
    80002aa2:	c25fe0ef          	jal	800016c6 <copyin>
    80002aa6:	00a03533          	snez	a0,a0
    80002aaa:	40a00533          	neg	a0,a0
}
    80002aae:	60e2                	ld	ra,24(sp)
    80002ab0:	6442                	ld	s0,16(sp)
    80002ab2:	64a2                	ld	s1,8(sp)
    80002ab4:	6902                	ld	s2,0(sp)
    80002ab6:	6105                	addi	sp,sp,32
    80002ab8:	8082                	ret
    return -1;
    80002aba:	557d                	li	a0,-1
    80002abc:	bfcd                	j	80002aae <fetchaddr+0x36>
    80002abe:	557d                	li	a0,-1
    80002ac0:	b7fd                	j	80002aae <fetchaddr+0x36>

0000000080002ac2 <fetchstr>:
{
    80002ac2:	7179                	addi	sp,sp,-48
    80002ac4:	f406                	sd	ra,40(sp)
    80002ac6:	f022                	sd	s0,32(sp)
    80002ac8:	ec26                	sd	s1,24(sp)
    80002aca:	e84a                	sd	s2,16(sp)
    80002acc:	e44e                	sd	s3,8(sp)
    80002ace:	1800                	addi	s0,sp,48
    80002ad0:	892a                	mv	s2,a0
    80002ad2:	84ae                	mv	s1,a1
    80002ad4:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002ad6:	e39fe0ef          	jal	8000190e <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002ada:	86ce                	mv	a3,s3
    80002adc:	864a                	mv	a2,s2
    80002ade:	85a6                	mv	a1,s1
    80002ae0:	6928                	ld	a0,80(a0)
    80002ae2:	9a7fe0ef          	jal	80001488 <copyinstr>
    80002ae6:	00054c63          	bltz	a0,80002afe <fetchstr+0x3c>
  return strlen(buf);
    80002aea:	8526                	mv	a0,s1
    80002aec:	b26fe0ef          	jal	80000e12 <strlen>
}
    80002af0:	70a2                	ld	ra,40(sp)
    80002af2:	7402                	ld	s0,32(sp)
    80002af4:	64e2                	ld	s1,24(sp)
    80002af6:	6942                	ld	s2,16(sp)
    80002af8:	69a2                	ld	s3,8(sp)
    80002afa:	6145                	addi	sp,sp,48
    80002afc:	8082                	ret
    return -1;
    80002afe:	557d                	li	a0,-1
    80002b00:	bfc5                	j	80002af0 <fetchstr+0x2e>

0000000080002b02 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002b02:	1101                	addi	sp,sp,-32
    80002b04:	ec06                	sd	ra,24(sp)
    80002b06:	e822                	sd	s0,16(sp)
    80002b08:	e426                	sd	s1,8(sp)
    80002b0a:	1000                	addi	s0,sp,32
    80002b0c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b0e:	f0bff0ef          	jal	80002a18 <argraw>
    80002b12:	c088                	sw	a0,0(s1)
}
    80002b14:	60e2                	ld	ra,24(sp)
    80002b16:	6442                	ld	s0,16(sp)
    80002b18:	64a2                	ld	s1,8(sp)
    80002b1a:	6105                	addi	sp,sp,32
    80002b1c:	8082                	ret

0000000080002b1e <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002b1e:	1101                	addi	sp,sp,-32
    80002b20:	ec06                	sd	ra,24(sp)
    80002b22:	e822                	sd	s0,16(sp)
    80002b24:	e426                	sd	s1,8(sp)
    80002b26:	1000                	addi	s0,sp,32
    80002b28:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b2a:	eefff0ef          	jal	80002a18 <argraw>
    80002b2e:	e088                	sd	a0,0(s1)
}
    80002b30:	60e2                	ld	ra,24(sp)
    80002b32:	6442                	ld	s0,16(sp)
    80002b34:	64a2                	ld	s1,8(sp)
    80002b36:	6105                	addi	sp,sp,32
    80002b38:	8082                	ret

0000000080002b3a <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002b3a:	7179                	addi	sp,sp,-48
    80002b3c:	f406                	sd	ra,40(sp)
    80002b3e:	f022                	sd	s0,32(sp)
    80002b40:	ec26                	sd	s1,24(sp)
    80002b42:	e84a                	sd	s2,16(sp)
    80002b44:	1800                	addi	s0,sp,48
    80002b46:	84ae                	mv	s1,a1
    80002b48:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002b4a:	fd840593          	addi	a1,s0,-40
    80002b4e:	fd1ff0ef          	jal	80002b1e <argaddr>
  return fetchstr(addr, buf, max);
    80002b52:	864a                	mv	a2,s2
    80002b54:	85a6                	mv	a1,s1
    80002b56:	fd843503          	ld	a0,-40(s0)
    80002b5a:	f69ff0ef          	jal	80002ac2 <fetchstr>
}
    80002b5e:	70a2                	ld	ra,40(sp)
    80002b60:	7402                	ld	s0,32(sp)
    80002b62:	64e2                	ld	s1,24(sp)
    80002b64:	6942                	ld	s2,16(sp)
    80002b66:	6145                	addi	sp,sp,48
    80002b68:	8082                	ret

0000000080002b6a <syscall>:
[SYS_set_nice]   sys_set_nice,
};

void
syscall(void)
{
    80002b6a:	1101                	addi	sp,sp,-32
    80002b6c:	ec06                	sd	ra,24(sp)
    80002b6e:	e822                	sd	s0,16(sp)
    80002b70:	e426                	sd	s1,8(sp)
    80002b72:	e04a                	sd	s2,0(sp)
    80002b74:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002b76:	d99fe0ef          	jal	8000190e <myproc>
    80002b7a:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002b7c:	05853903          	ld	s2,88(a0)
    80002b80:	0a893783          	ld	a5,168(s2)
    80002b84:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002b88:	37fd                	addiw	a5,a5,-1
    80002b8a:	4759                	li	a4,22
    80002b8c:	00f76f63          	bltu	a4,a5,80002baa <syscall+0x40>
    80002b90:	00369713          	slli	a4,a3,0x3
    80002b94:	00005797          	auipc	a5,0x5
    80002b98:	d7c78793          	addi	a5,a5,-644 # 80007910 <syscalls>
    80002b9c:	97ba                	add	a5,a5,a4
    80002b9e:	639c                	ld	a5,0(a5)
    80002ba0:	c789                	beqz	a5,80002baa <syscall+0x40>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002ba2:	9782                	jalr	a5
    80002ba4:	06a93823          	sd	a0,112(s2)
    80002ba8:	a829                	j	80002bc2 <syscall+0x58>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002baa:	15848613          	addi	a2,s1,344
    80002bae:	588c                	lw	a1,48(s1)
    80002bb0:	00005517          	auipc	a0,0x5
    80002bb4:	8c050513          	addi	a0,a0,-1856 # 80007470 <etext+0x470>
    80002bb8:	943fd0ef          	jal	800004fa <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002bbc:	6cbc                	ld	a5,88(s1)
    80002bbe:	577d                	li	a4,-1
    80002bc0:	fbb8                	sd	a4,112(a5)
  }
}
    80002bc2:	60e2                	ld	ra,24(sp)
    80002bc4:	6442                	ld	s0,16(sp)
    80002bc6:	64a2                	ld	s1,8(sp)
    80002bc8:	6902                	ld	s2,0(sp)
    80002bca:	6105                	addi	sp,sp,32
    80002bcc:	8082                	ret

0000000080002bce <sys_exit>:
#include "proc.h"
#include "vm.h"

uint64
sys_exit(void)
{
    80002bce:	1101                	addi	sp,sp,-32
    80002bd0:	ec06                	sd	ra,24(sp)
    80002bd2:	e822                	sd	s0,16(sp)
    80002bd4:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002bd6:	fec40593          	addi	a1,s0,-20
    80002bda:	4501                	li	a0,0
    80002bdc:	f27ff0ef          	jal	80002b02 <argint>
  kexit(n);
    80002be0:	fec42503          	lw	a0,-20(s0)
    80002be4:	e62ff0ef          	jal	80002246 <kexit>
  return 0;  // not reached
}
    80002be8:	4501                	li	a0,0
    80002bea:	60e2                	ld	ra,24(sp)
    80002bec:	6442                	ld	s0,16(sp)
    80002bee:	6105                	addi	sp,sp,32
    80002bf0:	8082                	ret

0000000080002bf2 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002bf2:	1141                	addi	sp,sp,-16
    80002bf4:	e406                	sd	ra,8(sp)
    80002bf6:	e022                	sd	s0,0(sp)
    80002bf8:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002bfa:	d15fe0ef          	jal	8000190e <myproc>
}
    80002bfe:	5908                	lw	a0,48(a0)
    80002c00:	60a2                	ld	ra,8(sp)
    80002c02:	6402                	ld	s0,0(sp)
    80002c04:	0141                	addi	sp,sp,16
    80002c06:	8082                	ret

0000000080002c08 <sys_fork>:

uint64
sys_fork(void)
{
    80002c08:	1141                	addi	sp,sp,-16
    80002c0a:	e406                	sd	ra,8(sp)
    80002c0c:	e022                	sd	s0,0(sp)
    80002c0e:	0800                	addi	s0,sp,16
  return kfork();
    80002c10:	928ff0ef          	jal	80001d38 <kfork>
}
    80002c14:	60a2                	ld	ra,8(sp)
    80002c16:	6402                	ld	s0,0(sp)
    80002c18:	0141                	addi	sp,sp,16
    80002c1a:	8082                	ret

0000000080002c1c <sys_wait>:

uint64
sys_wait(void)
{
    80002c1c:	1101                	addi	sp,sp,-32
    80002c1e:	ec06                	sd	ra,24(sp)
    80002c20:	e822                	sd	s0,16(sp)
    80002c22:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002c24:	fe840593          	addi	a1,s0,-24
    80002c28:	4501                	li	a0,0
    80002c2a:	ef5ff0ef          	jal	80002b1e <argaddr>
  return kwait(p);
    80002c2e:	fe843503          	ld	a0,-24(s0)
    80002c32:	fbeff0ef          	jal	800023f0 <kwait>
}
    80002c36:	60e2                	ld	ra,24(sp)
    80002c38:	6442                	ld	s0,16(sp)
    80002c3a:	6105                	addi	sp,sp,32
    80002c3c:	8082                	ret

0000000080002c3e <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002c3e:	7179                	addi	sp,sp,-48
    80002c40:	f406                	sd	ra,40(sp)
    80002c42:	f022                	sd	s0,32(sp)
    80002c44:	ec26                	sd	s1,24(sp)
    80002c46:	1800                	addi	s0,sp,48
  uint64 addr;
  int t;
  int n;

  argint(0, &n);
    80002c48:	fd840593          	addi	a1,s0,-40
    80002c4c:	4501                	li	a0,0
    80002c4e:	eb5ff0ef          	jal	80002b02 <argint>
  argint(1, &t);
    80002c52:	fdc40593          	addi	a1,s0,-36
    80002c56:	4505                	li	a0,1
    80002c58:	eabff0ef          	jal	80002b02 <argint>
  addr = myproc()->sz;
    80002c5c:	cb3fe0ef          	jal	8000190e <myproc>
    80002c60:	6524                	ld	s1,72(a0)

  if(t == SBRK_EAGER || n < 0) {
    80002c62:	fdc42703          	lw	a4,-36(s0)
    80002c66:	4785                	li	a5,1
    80002c68:	02f70163          	beq	a4,a5,80002c8a <sys_sbrk+0x4c>
    80002c6c:	fd842783          	lw	a5,-40(s0)
    80002c70:	0007cd63          	bltz	a5,80002c8a <sys_sbrk+0x4c>
    }
  } else {
    // Lazily allocate memory for this process: increase its memory
    // size but don't allocate memory. If the processes uses the
    // memory, vmfault() will allocate it.
    if(addr + n < addr)
    80002c74:	97a6                	add	a5,a5,s1
    80002c76:	0297e863          	bltu	a5,s1,80002ca6 <sys_sbrk+0x68>
      return -1;
    myproc()->sz += n;
    80002c7a:	c95fe0ef          	jal	8000190e <myproc>
    80002c7e:	fd842703          	lw	a4,-40(s0)
    80002c82:	653c                	ld	a5,72(a0)
    80002c84:	97ba                	add	a5,a5,a4
    80002c86:	e53c                	sd	a5,72(a0)
    80002c88:	a039                	j	80002c96 <sys_sbrk+0x58>
    if(growproc(n) < 0) {
    80002c8a:	fd842503          	lw	a0,-40(s0)
    80002c8e:	f87fe0ef          	jal	80001c14 <growproc>
    80002c92:	00054863          	bltz	a0,80002ca2 <sys_sbrk+0x64>
  }
  return addr;
}
    80002c96:	8526                	mv	a0,s1
    80002c98:	70a2                	ld	ra,40(sp)
    80002c9a:	7402                	ld	s0,32(sp)
    80002c9c:	64e2                	ld	s1,24(sp)
    80002c9e:	6145                	addi	sp,sp,48
    80002ca0:	8082                	ret
      return -1;
    80002ca2:	54fd                	li	s1,-1
    80002ca4:	bfcd                	j	80002c96 <sys_sbrk+0x58>
      return -1;
    80002ca6:	54fd                	li	s1,-1
    80002ca8:	b7fd                	j	80002c96 <sys_sbrk+0x58>

0000000080002caa <sys_pause>:

uint64
sys_pause(void)
{
    80002caa:	7139                	addi	sp,sp,-64
    80002cac:	fc06                	sd	ra,56(sp)
    80002cae:	f822                	sd	s0,48(sp)
    80002cb0:	f04a                	sd	s2,32(sp)
    80002cb2:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002cb4:	fcc40593          	addi	a1,s0,-52
    80002cb8:	4501                	li	a0,0
    80002cba:	e49ff0ef          	jal	80002b02 <argint>
  if(n < 0)
    80002cbe:	fcc42783          	lw	a5,-52(s0)
    80002cc2:	0607c763          	bltz	a5,80002d30 <sys_pause+0x86>
    n = 0;
  acquire(&tickslock);
    80002cc6:	00016517          	auipc	a0,0x16
    80002cca:	4b250513          	addi	a0,a0,1202 # 80019178 <tickslock>
    80002cce:	f01fd0ef          	jal	80000bce <acquire>
  ticks0 = ticks;
    80002cd2:	00007917          	auipc	s2,0x7
    80002cd6:	73a92903          	lw	s2,1850(s2) # 8000a40c <ticks>
  while(ticks - ticks0 < n){
    80002cda:	fcc42783          	lw	a5,-52(s0)
    80002cde:	cf8d                	beqz	a5,80002d18 <sys_pause+0x6e>
    80002ce0:	f426                	sd	s1,40(sp)
    80002ce2:	ec4e                	sd	s3,24(sp)
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002ce4:	00016997          	auipc	s3,0x16
    80002ce8:	49498993          	addi	s3,s3,1172 # 80019178 <tickslock>
    80002cec:	00007497          	auipc	s1,0x7
    80002cf0:	72048493          	addi	s1,s1,1824 # 8000a40c <ticks>
    if(killed(myproc())){
    80002cf4:	c1bfe0ef          	jal	8000190e <myproc>
    80002cf8:	eceff0ef          	jal	800023c6 <killed>
    80002cfc:	ed0d                	bnez	a0,80002d36 <sys_pause+0x8c>
    sleep(&ticks, &tickslock);
    80002cfe:	85ce                	mv	a1,s3
    80002d00:	8526                	mv	a0,s1
    80002d02:	c02ff0ef          	jal	80002104 <sleep>
  while(ticks - ticks0 < n){
    80002d06:	409c                	lw	a5,0(s1)
    80002d08:	412787bb          	subw	a5,a5,s2
    80002d0c:	fcc42703          	lw	a4,-52(s0)
    80002d10:	fee7e2e3          	bltu	a5,a4,80002cf4 <sys_pause+0x4a>
    80002d14:	74a2                	ld	s1,40(sp)
    80002d16:	69e2                	ld	s3,24(sp)
  }
  release(&tickslock);
    80002d18:	00016517          	auipc	a0,0x16
    80002d1c:	46050513          	addi	a0,a0,1120 # 80019178 <tickslock>
    80002d20:	f47fd0ef          	jal	80000c66 <release>
  return 0;
    80002d24:	4501                	li	a0,0
}
    80002d26:	70e2                	ld	ra,56(sp)
    80002d28:	7442                	ld	s0,48(sp)
    80002d2a:	7902                	ld	s2,32(sp)
    80002d2c:	6121                	addi	sp,sp,64
    80002d2e:	8082                	ret
    n = 0;
    80002d30:	fc042623          	sw	zero,-52(s0)
    80002d34:	bf49                	j	80002cc6 <sys_pause+0x1c>
      release(&tickslock);
    80002d36:	00016517          	auipc	a0,0x16
    80002d3a:	44250513          	addi	a0,a0,1090 # 80019178 <tickslock>
    80002d3e:	f29fd0ef          	jal	80000c66 <release>
      return -1;
    80002d42:	557d                	li	a0,-1
    80002d44:	74a2                	ld	s1,40(sp)
    80002d46:	69e2                	ld	s3,24(sp)
    80002d48:	bff9                	j	80002d26 <sys_pause+0x7c>

0000000080002d4a <sys_kill>:

uint64
sys_kill(void)
{
    80002d4a:	1101                	addi	sp,sp,-32
    80002d4c:	ec06                	sd	ra,24(sp)
    80002d4e:	e822                	sd	s0,16(sp)
    80002d50:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002d52:	fec40593          	addi	a1,s0,-20
    80002d56:	4501                	li	a0,0
    80002d58:	dabff0ef          	jal	80002b02 <argint>
  return kkill(pid);
    80002d5c:	fec42503          	lw	a0,-20(s0)
    80002d60:	ddcff0ef          	jal	8000233c <kkill>
}
    80002d64:	60e2                	ld	ra,24(sp)
    80002d66:	6442                	ld	s0,16(sp)
    80002d68:	6105                	addi	sp,sp,32
    80002d6a:	8082                	ret

0000000080002d6c <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002d6c:	1101                	addi	sp,sp,-32
    80002d6e:	ec06                	sd	ra,24(sp)
    80002d70:	e822                	sd	s0,16(sp)
    80002d72:	e426                	sd	s1,8(sp)
    80002d74:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002d76:	00016517          	auipc	a0,0x16
    80002d7a:	40250513          	addi	a0,a0,1026 # 80019178 <tickslock>
    80002d7e:	e51fd0ef          	jal	80000bce <acquire>
  xticks = ticks;
    80002d82:	00007497          	auipc	s1,0x7
    80002d86:	68a4a483          	lw	s1,1674(s1) # 8000a40c <ticks>
  release(&tickslock);
    80002d8a:	00016517          	auipc	a0,0x16
    80002d8e:	3ee50513          	addi	a0,a0,1006 # 80019178 <tickslock>
    80002d92:	ed5fd0ef          	jal	80000c66 <release>
  return xticks;
}
    80002d96:	02049513          	slli	a0,s1,0x20
    80002d9a:	9101                	srli	a0,a0,0x20
    80002d9c:	60e2                	ld	ra,24(sp)
    80002d9e:	6442                	ld	s0,16(sp)
    80002da0:	64a2                	ld	s1,8(sp)
    80002da2:	6105                	addi	sp,sp,32
    80002da4:	8082                	ret

0000000080002da6 <sys_set_nice>:

uint64
sys_set_nice(void)
{
    80002da6:	1101                	addi	sp,sp,-32
    80002da8:	ec06                	sd	ra,24(sp)
    80002daa:	e822                	sd	s0,16(sp)
    80002dac:	1000                	addi	s0,sp,32
  int pid, nice;
  struct proc *p;

  argint(0, &pid);
    80002dae:	fec40593          	addi	a1,s0,-20
    80002db2:	4501                	li	a0,0
    80002db4:	d4fff0ef          	jal	80002b02 <argint>
  argint(1, &nice);
    80002db8:	fe840593          	addi	a1,s0,-24
    80002dbc:	4505                	li	a0,1
    80002dbe:	d45ff0ef          	jal	80002b02 <argint>

  if(nice < -20 || nice > 19)
    80002dc2:	fe842583          	lw	a1,-24(s0)
    80002dc6:	0145871b          	addiw	a4,a1,20
    80002dca:	02700793          	li	a5,39
    return -1;
    80002dce:	557d                	li	a0,-1
  if(nice < -20 || nice > 19)
    80002dd0:	02e7e863          	bltu	a5,a4,80002e00 <sys_set_nice+0x5a>

  for(p = proc; p < &proc[NPROC]; p++){
    if(p->pid == pid){
    80002dd4:	fec42683          	lw	a3,-20(s0)
  for(p = proc; p < &proc[NPROC]; p++){
    80002dd8:	00010797          	auipc	a5,0x10
    80002ddc:	ba078793          	addi	a5,a5,-1120 # 80012978 <proc>
    80002de0:	00016617          	auipc	a2,0x16
    80002de4:	39860613          	addi	a2,a2,920 # 80019178 <tickslock>
    if(p->pid == pid){
    80002de8:	5b98                	lw	a4,48(a5)
    80002dea:	00d70863          	beq	a4,a3,80002dfa <sys_set_nice+0x54>
  for(p = proc; p < &proc[NPROC]; p++){
    80002dee:	1a078793          	addi	a5,a5,416
    80002df2:	fec79be3          	bne	a5,a2,80002de8 <sys_set_nice+0x42>
      p->nice = nice;
      return 0;
    }
  }

  return -1;
    80002df6:	557d                	li	a0,-1
    80002df8:	a021                	j	80002e00 <sys_set_nice+0x5a>
      p->nice = nice;
    80002dfa:	16b7a423          	sw	a1,360(a5)
      return 0;
    80002dfe:	4501                	li	a0,0
}
    80002e00:	60e2                	ld	ra,24(sp)
    80002e02:	6442                	ld	s0,16(sp)
    80002e04:	6105                	addi	sp,sp,32
    80002e06:	8082                	ret

0000000080002e08 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002e08:	7179                	addi	sp,sp,-48
    80002e0a:	f406                	sd	ra,40(sp)
    80002e0c:	f022                	sd	s0,32(sp)
    80002e0e:	ec26                	sd	s1,24(sp)
    80002e10:	e84a                	sd	s2,16(sp)
    80002e12:	e44e                	sd	s3,8(sp)
    80002e14:	e052                	sd	s4,0(sp)
    80002e16:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002e18:	00004597          	auipc	a1,0x4
    80002e1c:	67858593          	addi	a1,a1,1656 # 80007490 <etext+0x490>
    80002e20:	00016517          	auipc	a0,0x16
    80002e24:	37050513          	addi	a0,a0,880 # 80019190 <bcache>
    80002e28:	d27fd0ef          	jal	80000b4e <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002e2c:	0001e797          	auipc	a5,0x1e
    80002e30:	36478793          	addi	a5,a5,868 # 80021190 <bcache+0x8000>
    80002e34:	0001e717          	auipc	a4,0x1e
    80002e38:	5c470713          	addi	a4,a4,1476 # 800213f8 <bcache+0x8268>
    80002e3c:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002e40:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e44:	00016497          	auipc	s1,0x16
    80002e48:	36448493          	addi	s1,s1,868 # 800191a8 <bcache+0x18>
    b->next = bcache.head.next;
    80002e4c:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002e4e:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002e50:	00004a17          	auipc	s4,0x4
    80002e54:	648a0a13          	addi	s4,s4,1608 # 80007498 <etext+0x498>
    b->next = bcache.head.next;
    80002e58:	2b893783          	ld	a5,696(s2)
    80002e5c:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002e5e:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002e62:	85d2                	mv	a1,s4
    80002e64:	01048513          	addi	a0,s1,16
    80002e68:	322010ef          	jal	8000418a <initsleeplock>
    bcache.head.next->prev = b;
    80002e6c:	2b893783          	ld	a5,696(s2)
    80002e70:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002e72:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002e76:	45848493          	addi	s1,s1,1112
    80002e7a:	fd349fe3          	bne	s1,s3,80002e58 <binit+0x50>
  }
}
    80002e7e:	70a2                	ld	ra,40(sp)
    80002e80:	7402                	ld	s0,32(sp)
    80002e82:	64e2                	ld	s1,24(sp)
    80002e84:	6942                	ld	s2,16(sp)
    80002e86:	69a2                	ld	s3,8(sp)
    80002e88:	6a02                	ld	s4,0(sp)
    80002e8a:	6145                	addi	sp,sp,48
    80002e8c:	8082                	ret

0000000080002e8e <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002e8e:	7179                	addi	sp,sp,-48
    80002e90:	f406                	sd	ra,40(sp)
    80002e92:	f022                	sd	s0,32(sp)
    80002e94:	ec26                	sd	s1,24(sp)
    80002e96:	e84a                	sd	s2,16(sp)
    80002e98:	e44e                	sd	s3,8(sp)
    80002e9a:	1800                	addi	s0,sp,48
    80002e9c:	892a                	mv	s2,a0
    80002e9e:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002ea0:	00016517          	auipc	a0,0x16
    80002ea4:	2f050513          	addi	a0,a0,752 # 80019190 <bcache>
    80002ea8:	d27fd0ef          	jal	80000bce <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002eac:	0001e497          	auipc	s1,0x1e
    80002eb0:	59c4b483          	ld	s1,1436(s1) # 80021448 <bcache+0x82b8>
    80002eb4:	0001e797          	auipc	a5,0x1e
    80002eb8:	54478793          	addi	a5,a5,1348 # 800213f8 <bcache+0x8268>
    80002ebc:	02f48b63          	beq	s1,a5,80002ef2 <bread+0x64>
    80002ec0:	873e                	mv	a4,a5
    80002ec2:	a021                	j	80002eca <bread+0x3c>
    80002ec4:	68a4                	ld	s1,80(s1)
    80002ec6:	02e48663          	beq	s1,a4,80002ef2 <bread+0x64>
    if(b->dev == dev && b->blockno == blockno){
    80002eca:	449c                	lw	a5,8(s1)
    80002ecc:	ff279ce3          	bne	a5,s2,80002ec4 <bread+0x36>
    80002ed0:	44dc                	lw	a5,12(s1)
    80002ed2:	ff3799e3          	bne	a5,s3,80002ec4 <bread+0x36>
      b->refcnt++;
    80002ed6:	40bc                	lw	a5,64(s1)
    80002ed8:	2785                	addiw	a5,a5,1
    80002eda:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002edc:	00016517          	auipc	a0,0x16
    80002ee0:	2b450513          	addi	a0,a0,692 # 80019190 <bcache>
    80002ee4:	d83fd0ef          	jal	80000c66 <release>
      acquiresleep(&b->lock);
    80002ee8:	01048513          	addi	a0,s1,16
    80002eec:	2d4010ef          	jal	800041c0 <acquiresleep>
      return b;
    80002ef0:	a889                	j	80002f42 <bread+0xb4>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002ef2:	0001e497          	auipc	s1,0x1e
    80002ef6:	54e4b483          	ld	s1,1358(s1) # 80021440 <bcache+0x82b0>
    80002efa:	0001e797          	auipc	a5,0x1e
    80002efe:	4fe78793          	addi	a5,a5,1278 # 800213f8 <bcache+0x8268>
    80002f02:	00f48863          	beq	s1,a5,80002f12 <bread+0x84>
    80002f06:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002f08:	40bc                	lw	a5,64(s1)
    80002f0a:	cb91                	beqz	a5,80002f1e <bread+0x90>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002f0c:	64a4                	ld	s1,72(s1)
    80002f0e:	fee49de3          	bne	s1,a4,80002f08 <bread+0x7a>
  panic("bget: no buffers");
    80002f12:	00004517          	auipc	a0,0x4
    80002f16:	58e50513          	addi	a0,a0,1422 # 800074a0 <etext+0x4a0>
    80002f1a:	8c7fd0ef          	jal	800007e0 <panic>
      b->dev = dev;
    80002f1e:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002f22:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002f26:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002f2a:	4785                	li	a5,1
    80002f2c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f2e:	00016517          	auipc	a0,0x16
    80002f32:	26250513          	addi	a0,a0,610 # 80019190 <bcache>
    80002f36:	d31fd0ef          	jal	80000c66 <release>
      acquiresleep(&b->lock);
    80002f3a:	01048513          	addi	a0,s1,16
    80002f3e:	282010ef          	jal	800041c0 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002f42:	409c                	lw	a5,0(s1)
    80002f44:	cb89                	beqz	a5,80002f56 <bread+0xc8>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002f46:	8526                	mv	a0,s1
    80002f48:	70a2                	ld	ra,40(sp)
    80002f4a:	7402                	ld	s0,32(sp)
    80002f4c:	64e2                	ld	s1,24(sp)
    80002f4e:	6942                	ld	s2,16(sp)
    80002f50:	69a2                	ld	s3,8(sp)
    80002f52:	6145                	addi	sp,sp,48
    80002f54:	8082                	ret
    virtio_disk_rw(b, 0);
    80002f56:	4581                	li	a1,0
    80002f58:	8526                	mv	a0,s1
    80002f5a:	2e7020ef          	jal	80005a40 <virtio_disk_rw>
    b->valid = 1;
    80002f5e:	4785                	li	a5,1
    80002f60:	c09c                	sw	a5,0(s1)
  return b;
    80002f62:	b7d5                	j	80002f46 <bread+0xb8>

0000000080002f64 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002f64:	1101                	addi	sp,sp,-32
    80002f66:	ec06                	sd	ra,24(sp)
    80002f68:	e822                	sd	s0,16(sp)
    80002f6a:	e426                	sd	s1,8(sp)
    80002f6c:	1000                	addi	s0,sp,32
    80002f6e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002f70:	0541                	addi	a0,a0,16
    80002f72:	2cc010ef          	jal	8000423e <holdingsleep>
    80002f76:	c911                	beqz	a0,80002f8a <bwrite+0x26>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002f78:	4585                	li	a1,1
    80002f7a:	8526                	mv	a0,s1
    80002f7c:	2c5020ef          	jal	80005a40 <virtio_disk_rw>
}
    80002f80:	60e2                	ld	ra,24(sp)
    80002f82:	6442                	ld	s0,16(sp)
    80002f84:	64a2                	ld	s1,8(sp)
    80002f86:	6105                	addi	sp,sp,32
    80002f88:	8082                	ret
    panic("bwrite");
    80002f8a:	00004517          	auipc	a0,0x4
    80002f8e:	52e50513          	addi	a0,a0,1326 # 800074b8 <etext+0x4b8>
    80002f92:	84ffd0ef          	jal	800007e0 <panic>

0000000080002f96 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002f96:	1101                	addi	sp,sp,-32
    80002f98:	ec06                	sd	ra,24(sp)
    80002f9a:	e822                	sd	s0,16(sp)
    80002f9c:	e426                	sd	s1,8(sp)
    80002f9e:	e04a                	sd	s2,0(sp)
    80002fa0:	1000                	addi	s0,sp,32
    80002fa2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002fa4:	01050913          	addi	s2,a0,16
    80002fa8:	854a                	mv	a0,s2
    80002faa:	294010ef          	jal	8000423e <holdingsleep>
    80002fae:	c135                	beqz	a0,80003012 <brelse+0x7c>
    panic("brelse");

  releasesleep(&b->lock);
    80002fb0:	854a                	mv	a0,s2
    80002fb2:	254010ef          	jal	80004206 <releasesleep>

  acquire(&bcache.lock);
    80002fb6:	00016517          	auipc	a0,0x16
    80002fba:	1da50513          	addi	a0,a0,474 # 80019190 <bcache>
    80002fbe:	c11fd0ef          	jal	80000bce <acquire>
  b->refcnt--;
    80002fc2:	40bc                	lw	a5,64(s1)
    80002fc4:	37fd                	addiw	a5,a5,-1
    80002fc6:	0007871b          	sext.w	a4,a5
    80002fca:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002fcc:	e71d                	bnez	a4,80002ffa <brelse+0x64>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80002fce:	68b8                	ld	a4,80(s1)
    80002fd0:	64bc                	ld	a5,72(s1)
    80002fd2:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    80002fd4:	68b8                	ld	a4,80(s1)
    80002fd6:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002fd8:	0001e797          	auipc	a5,0x1e
    80002fdc:	1b878793          	addi	a5,a5,440 # 80021190 <bcache+0x8000>
    80002fe0:	2b87b703          	ld	a4,696(a5)
    80002fe4:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80002fe6:	0001e717          	auipc	a4,0x1e
    80002fea:	41270713          	addi	a4,a4,1042 # 800213f8 <bcache+0x8268>
    80002fee:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80002ff0:	2b87b703          	ld	a4,696(a5)
    80002ff4:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80002ff6:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80002ffa:	00016517          	auipc	a0,0x16
    80002ffe:	19650513          	addi	a0,a0,406 # 80019190 <bcache>
    80003002:	c65fd0ef          	jal	80000c66 <release>
}
    80003006:	60e2                	ld	ra,24(sp)
    80003008:	6442                	ld	s0,16(sp)
    8000300a:	64a2                	ld	s1,8(sp)
    8000300c:	6902                	ld	s2,0(sp)
    8000300e:	6105                	addi	sp,sp,32
    80003010:	8082                	ret
    panic("brelse");
    80003012:	00004517          	auipc	a0,0x4
    80003016:	4ae50513          	addi	a0,a0,1198 # 800074c0 <etext+0x4c0>
    8000301a:	fc6fd0ef          	jal	800007e0 <panic>

000000008000301e <bpin>:

void
bpin(struct buf *b) {
    8000301e:	1101                	addi	sp,sp,-32
    80003020:	ec06                	sd	ra,24(sp)
    80003022:	e822                	sd	s0,16(sp)
    80003024:	e426                	sd	s1,8(sp)
    80003026:	1000                	addi	s0,sp,32
    80003028:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000302a:	00016517          	auipc	a0,0x16
    8000302e:	16650513          	addi	a0,a0,358 # 80019190 <bcache>
    80003032:	b9dfd0ef          	jal	80000bce <acquire>
  b->refcnt++;
    80003036:	40bc                	lw	a5,64(s1)
    80003038:	2785                	addiw	a5,a5,1
    8000303a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000303c:	00016517          	auipc	a0,0x16
    80003040:	15450513          	addi	a0,a0,340 # 80019190 <bcache>
    80003044:	c23fd0ef          	jal	80000c66 <release>
}
    80003048:	60e2                	ld	ra,24(sp)
    8000304a:	6442                	ld	s0,16(sp)
    8000304c:	64a2                	ld	s1,8(sp)
    8000304e:	6105                	addi	sp,sp,32
    80003050:	8082                	ret

0000000080003052 <bunpin>:

void
bunpin(struct buf *b) {
    80003052:	1101                	addi	sp,sp,-32
    80003054:	ec06                	sd	ra,24(sp)
    80003056:	e822                	sd	s0,16(sp)
    80003058:	e426                	sd	s1,8(sp)
    8000305a:	1000                	addi	s0,sp,32
    8000305c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000305e:	00016517          	auipc	a0,0x16
    80003062:	13250513          	addi	a0,a0,306 # 80019190 <bcache>
    80003066:	b69fd0ef          	jal	80000bce <acquire>
  b->refcnt--;
    8000306a:	40bc                	lw	a5,64(s1)
    8000306c:	37fd                	addiw	a5,a5,-1
    8000306e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003070:	00016517          	auipc	a0,0x16
    80003074:	12050513          	addi	a0,a0,288 # 80019190 <bcache>
    80003078:	beffd0ef          	jal	80000c66 <release>
}
    8000307c:	60e2                	ld	ra,24(sp)
    8000307e:	6442                	ld	s0,16(sp)
    80003080:	64a2                	ld	s1,8(sp)
    80003082:	6105                	addi	sp,sp,32
    80003084:	8082                	ret

0000000080003086 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003086:	1101                	addi	sp,sp,-32
    80003088:	ec06                	sd	ra,24(sp)
    8000308a:	e822                	sd	s0,16(sp)
    8000308c:	e426                	sd	s1,8(sp)
    8000308e:	e04a                	sd	s2,0(sp)
    80003090:	1000                	addi	s0,sp,32
    80003092:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003094:	00d5d59b          	srliw	a1,a1,0xd
    80003098:	0001e797          	auipc	a5,0x1e
    8000309c:	7d47a783          	lw	a5,2004(a5) # 8002186c <sb+0x1c>
    800030a0:	9dbd                	addw	a1,a1,a5
    800030a2:	dedff0ef          	jal	80002e8e <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800030a6:	0074f713          	andi	a4,s1,7
    800030aa:	4785                	li	a5,1
    800030ac:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800030b0:	14ce                	slli	s1,s1,0x33
    800030b2:	90d9                	srli	s1,s1,0x36
    800030b4:	00950733          	add	a4,a0,s1
    800030b8:	05874703          	lbu	a4,88(a4)
    800030bc:	00e7f6b3          	and	a3,a5,a4
    800030c0:	c29d                	beqz	a3,800030e6 <bfree+0x60>
    800030c2:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800030c4:	94aa                	add	s1,s1,a0
    800030c6:	fff7c793          	not	a5,a5
    800030ca:	8f7d                	and	a4,a4,a5
    800030cc:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800030d0:	7f9000ef          	jal	800040c8 <log_write>
  brelse(bp);
    800030d4:	854a                	mv	a0,s2
    800030d6:	ec1ff0ef          	jal	80002f96 <brelse>
}
    800030da:	60e2                	ld	ra,24(sp)
    800030dc:	6442                	ld	s0,16(sp)
    800030de:	64a2                	ld	s1,8(sp)
    800030e0:	6902                	ld	s2,0(sp)
    800030e2:	6105                	addi	sp,sp,32
    800030e4:	8082                	ret
    panic("freeing free block");
    800030e6:	00004517          	auipc	a0,0x4
    800030ea:	3e250513          	addi	a0,a0,994 # 800074c8 <etext+0x4c8>
    800030ee:	ef2fd0ef          	jal	800007e0 <panic>

00000000800030f2 <balloc>:
{
    800030f2:	711d                	addi	sp,sp,-96
    800030f4:	ec86                	sd	ra,88(sp)
    800030f6:	e8a2                	sd	s0,80(sp)
    800030f8:	e4a6                	sd	s1,72(sp)
    800030fa:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800030fc:	0001e797          	auipc	a5,0x1e
    80003100:	7587a783          	lw	a5,1880(a5) # 80021854 <sb+0x4>
    80003104:	0e078f63          	beqz	a5,80003202 <balloc+0x110>
    80003108:	e0ca                	sd	s2,64(sp)
    8000310a:	fc4e                	sd	s3,56(sp)
    8000310c:	f852                	sd	s4,48(sp)
    8000310e:	f456                	sd	s5,40(sp)
    80003110:	f05a                	sd	s6,32(sp)
    80003112:	ec5e                	sd	s7,24(sp)
    80003114:	e862                	sd	s8,16(sp)
    80003116:	e466                	sd	s9,8(sp)
    80003118:	8baa                	mv	s7,a0
    8000311a:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000311c:	0001eb17          	auipc	s6,0x1e
    80003120:	734b0b13          	addi	s6,s6,1844 # 80021850 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003124:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003126:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003128:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000312a:	6c89                	lui	s9,0x2
    8000312c:	a0b5                	j	80003198 <balloc+0xa6>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000312e:	97ca                	add	a5,a5,s2
    80003130:	8e55                	or	a2,a2,a3
    80003132:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003136:	854a                	mv	a0,s2
    80003138:	791000ef          	jal	800040c8 <log_write>
        brelse(bp);
    8000313c:	854a                	mv	a0,s2
    8000313e:	e59ff0ef          	jal	80002f96 <brelse>
  bp = bread(dev, bno);
    80003142:	85a6                	mv	a1,s1
    80003144:	855e                	mv	a0,s7
    80003146:	d49ff0ef          	jal	80002e8e <bread>
    8000314a:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000314c:	40000613          	li	a2,1024
    80003150:	4581                	li	a1,0
    80003152:	05850513          	addi	a0,a0,88
    80003156:	b4dfd0ef          	jal	80000ca2 <memset>
  log_write(bp);
    8000315a:	854a                	mv	a0,s2
    8000315c:	76d000ef          	jal	800040c8 <log_write>
  brelse(bp);
    80003160:	854a                	mv	a0,s2
    80003162:	e35ff0ef          	jal	80002f96 <brelse>
}
    80003166:	6906                	ld	s2,64(sp)
    80003168:	79e2                	ld	s3,56(sp)
    8000316a:	7a42                	ld	s4,48(sp)
    8000316c:	7aa2                	ld	s5,40(sp)
    8000316e:	7b02                	ld	s6,32(sp)
    80003170:	6be2                	ld	s7,24(sp)
    80003172:	6c42                	ld	s8,16(sp)
    80003174:	6ca2                	ld	s9,8(sp)
}
    80003176:	8526                	mv	a0,s1
    80003178:	60e6                	ld	ra,88(sp)
    8000317a:	6446                	ld	s0,80(sp)
    8000317c:	64a6                	ld	s1,72(sp)
    8000317e:	6125                	addi	sp,sp,96
    80003180:	8082                	ret
    brelse(bp);
    80003182:	854a                	mv	a0,s2
    80003184:	e13ff0ef          	jal	80002f96 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003188:	015c87bb          	addw	a5,s9,s5
    8000318c:	00078a9b          	sext.w	s5,a5
    80003190:	004b2703          	lw	a4,4(s6)
    80003194:	04eaff63          	bgeu	s5,a4,800031f2 <balloc+0x100>
    bp = bread(dev, BBLOCK(b, sb));
    80003198:	41fad79b          	sraiw	a5,s5,0x1f
    8000319c:	0137d79b          	srliw	a5,a5,0x13
    800031a0:	015787bb          	addw	a5,a5,s5
    800031a4:	40d7d79b          	sraiw	a5,a5,0xd
    800031a8:	01cb2583          	lw	a1,28(s6)
    800031ac:	9dbd                	addw	a1,a1,a5
    800031ae:	855e                	mv	a0,s7
    800031b0:	cdfff0ef          	jal	80002e8e <bread>
    800031b4:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031b6:	004b2503          	lw	a0,4(s6)
    800031ba:	000a849b          	sext.w	s1,s5
    800031be:	8762                	mv	a4,s8
    800031c0:	fca4f1e3          	bgeu	s1,a0,80003182 <balloc+0x90>
      m = 1 << (bi % 8);
    800031c4:	00777693          	andi	a3,a4,7
    800031c8:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800031cc:	41f7579b          	sraiw	a5,a4,0x1f
    800031d0:	01d7d79b          	srliw	a5,a5,0x1d
    800031d4:	9fb9                	addw	a5,a5,a4
    800031d6:	4037d79b          	sraiw	a5,a5,0x3
    800031da:	00f90633          	add	a2,s2,a5
    800031de:	05864603          	lbu	a2,88(a2)
    800031e2:	00c6f5b3          	and	a1,a3,a2
    800031e6:	d5a1                	beqz	a1,8000312e <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800031e8:	2705                	addiw	a4,a4,1
    800031ea:	2485                	addiw	s1,s1,1
    800031ec:	fd471ae3          	bne	a4,s4,800031c0 <balloc+0xce>
    800031f0:	bf49                	j	80003182 <balloc+0x90>
    800031f2:	6906                	ld	s2,64(sp)
    800031f4:	79e2                	ld	s3,56(sp)
    800031f6:	7a42                	ld	s4,48(sp)
    800031f8:	7aa2                	ld	s5,40(sp)
    800031fa:	7b02                	ld	s6,32(sp)
    800031fc:	6be2                	ld	s7,24(sp)
    800031fe:	6c42                	ld	s8,16(sp)
    80003200:	6ca2                	ld	s9,8(sp)
  printf("balloc: out of blocks\n");
    80003202:	00004517          	auipc	a0,0x4
    80003206:	2de50513          	addi	a0,a0,734 # 800074e0 <etext+0x4e0>
    8000320a:	af0fd0ef          	jal	800004fa <printf>
  return 0;
    8000320e:	4481                	li	s1,0
    80003210:	b79d                	j	80003176 <balloc+0x84>

0000000080003212 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003212:	7179                	addi	sp,sp,-48
    80003214:	f406                	sd	ra,40(sp)
    80003216:	f022                	sd	s0,32(sp)
    80003218:	ec26                	sd	s1,24(sp)
    8000321a:	e84a                	sd	s2,16(sp)
    8000321c:	e44e                	sd	s3,8(sp)
    8000321e:	1800                	addi	s0,sp,48
    80003220:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003222:	47ad                	li	a5,11
    80003224:	02b7e663          	bltu	a5,a1,80003250 <bmap+0x3e>
    if((addr = ip->addrs[bn]) == 0){
    80003228:	02059793          	slli	a5,a1,0x20
    8000322c:	01e7d593          	srli	a1,a5,0x1e
    80003230:	00b504b3          	add	s1,a0,a1
    80003234:	0504a903          	lw	s2,80(s1)
    80003238:	06091a63          	bnez	s2,800032ac <bmap+0x9a>
      addr = balloc(ip->dev);
    8000323c:	4108                	lw	a0,0(a0)
    8000323e:	eb5ff0ef          	jal	800030f2 <balloc>
    80003242:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003246:	06090363          	beqz	s2,800032ac <bmap+0x9a>
        return 0;
      ip->addrs[bn] = addr;
    8000324a:	0524a823          	sw	s2,80(s1)
    8000324e:	a8b9                	j	800032ac <bmap+0x9a>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003250:	ff45849b          	addiw	s1,a1,-12
    80003254:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003258:	0ff00793          	li	a5,255
    8000325c:	06e7ee63          	bltu	a5,a4,800032d8 <bmap+0xc6>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003260:	08052903          	lw	s2,128(a0)
    80003264:	00091d63          	bnez	s2,8000327e <bmap+0x6c>
      addr = balloc(ip->dev);
    80003268:	4108                	lw	a0,0(a0)
    8000326a:	e89ff0ef          	jal	800030f2 <balloc>
    8000326e:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003272:	02090d63          	beqz	s2,800032ac <bmap+0x9a>
    80003276:	e052                	sd	s4,0(sp)
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003278:	0929a023          	sw	s2,128(s3)
    8000327c:	a011                	j	80003280 <bmap+0x6e>
    8000327e:	e052                	sd	s4,0(sp)
    }
    bp = bread(ip->dev, addr);
    80003280:	85ca                	mv	a1,s2
    80003282:	0009a503          	lw	a0,0(s3)
    80003286:	c09ff0ef          	jal	80002e8e <bread>
    8000328a:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000328c:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003290:	02049713          	slli	a4,s1,0x20
    80003294:	01e75593          	srli	a1,a4,0x1e
    80003298:	00b784b3          	add	s1,a5,a1
    8000329c:	0004a903          	lw	s2,0(s1)
    800032a0:	00090e63          	beqz	s2,800032bc <bmap+0xaa>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800032a4:	8552                	mv	a0,s4
    800032a6:	cf1ff0ef          	jal	80002f96 <brelse>
    return addr;
    800032aa:	6a02                	ld	s4,0(sp)
  }

  panic("bmap: out of range");
}
    800032ac:	854a                	mv	a0,s2
    800032ae:	70a2                	ld	ra,40(sp)
    800032b0:	7402                	ld	s0,32(sp)
    800032b2:	64e2                	ld	s1,24(sp)
    800032b4:	6942                	ld	s2,16(sp)
    800032b6:	69a2                	ld	s3,8(sp)
    800032b8:	6145                	addi	sp,sp,48
    800032ba:	8082                	ret
      addr = balloc(ip->dev);
    800032bc:	0009a503          	lw	a0,0(s3)
    800032c0:	e33ff0ef          	jal	800030f2 <balloc>
    800032c4:	0005091b          	sext.w	s2,a0
      if(addr){
    800032c8:	fc090ee3          	beqz	s2,800032a4 <bmap+0x92>
        a[bn] = addr;
    800032cc:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800032d0:	8552                	mv	a0,s4
    800032d2:	5f7000ef          	jal	800040c8 <log_write>
    800032d6:	b7f9                	j	800032a4 <bmap+0x92>
    800032d8:	e052                	sd	s4,0(sp)
  panic("bmap: out of range");
    800032da:	00004517          	auipc	a0,0x4
    800032de:	21e50513          	addi	a0,a0,542 # 800074f8 <etext+0x4f8>
    800032e2:	cfefd0ef          	jal	800007e0 <panic>

00000000800032e6 <iget>:
{
    800032e6:	7179                	addi	sp,sp,-48
    800032e8:	f406                	sd	ra,40(sp)
    800032ea:	f022                	sd	s0,32(sp)
    800032ec:	ec26                	sd	s1,24(sp)
    800032ee:	e84a                	sd	s2,16(sp)
    800032f0:	e44e                	sd	s3,8(sp)
    800032f2:	e052                	sd	s4,0(sp)
    800032f4:	1800                	addi	s0,sp,48
    800032f6:	89aa                	mv	s3,a0
    800032f8:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800032fa:	0001e517          	auipc	a0,0x1e
    800032fe:	57650513          	addi	a0,a0,1398 # 80021870 <itable>
    80003302:	8cdfd0ef          	jal	80000bce <acquire>
  empty = 0;
    80003306:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003308:	0001e497          	auipc	s1,0x1e
    8000330c:	58048493          	addi	s1,s1,1408 # 80021888 <itable+0x18>
    80003310:	00020697          	auipc	a3,0x20
    80003314:	00868693          	addi	a3,a3,8 # 80023318 <log>
    80003318:	a039                	j	80003326 <iget+0x40>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000331a:	02090963          	beqz	s2,8000334c <iget+0x66>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000331e:	08848493          	addi	s1,s1,136
    80003322:	02d48863          	beq	s1,a3,80003352 <iget+0x6c>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003326:	449c                	lw	a5,8(s1)
    80003328:	fef059e3          	blez	a5,8000331a <iget+0x34>
    8000332c:	4098                	lw	a4,0(s1)
    8000332e:	ff3716e3          	bne	a4,s3,8000331a <iget+0x34>
    80003332:	40d8                	lw	a4,4(s1)
    80003334:	ff4713e3          	bne	a4,s4,8000331a <iget+0x34>
      ip->ref++;
    80003338:	2785                	addiw	a5,a5,1
    8000333a:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000333c:	0001e517          	auipc	a0,0x1e
    80003340:	53450513          	addi	a0,a0,1332 # 80021870 <itable>
    80003344:	923fd0ef          	jal	80000c66 <release>
      return ip;
    80003348:	8926                	mv	s2,s1
    8000334a:	a02d                	j	80003374 <iget+0x8e>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000334c:	fbe9                	bnez	a5,8000331e <iget+0x38>
      empty = ip;
    8000334e:	8926                	mv	s2,s1
    80003350:	b7f9                	j	8000331e <iget+0x38>
  if(empty == 0)
    80003352:	02090a63          	beqz	s2,80003386 <iget+0xa0>
  ip->dev = dev;
    80003356:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000335a:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000335e:	4785                	li	a5,1
    80003360:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003364:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003368:	0001e517          	auipc	a0,0x1e
    8000336c:	50850513          	addi	a0,a0,1288 # 80021870 <itable>
    80003370:	8f7fd0ef          	jal	80000c66 <release>
}
    80003374:	854a                	mv	a0,s2
    80003376:	70a2                	ld	ra,40(sp)
    80003378:	7402                	ld	s0,32(sp)
    8000337a:	64e2                	ld	s1,24(sp)
    8000337c:	6942                	ld	s2,16(sp)
    8000337e:	69a2                	ld	s3,8(sp)
    80003380:	6a02                	ld	s4,0(sp)
    80003382:	6145                	addi	sp,sp,48
    80003384:	8082                	ret
    panic("iget: no inodes");
    80003386:	00004517          	auipc	a0,0x4
    8000338a:	18a50513          	addi	a0,a0,394 # 80007510 <etext+0x510>
    8000338e:	c52fd0ef          	jal	800007e0 <panic>

0000000080003392 <iinit>:
{
    80003392:	7179                	addi	sp,sp,-48
    80003394:	f406                	sd	ra,40(sp)
    80003396:	f022                	sd	s0,32(sp)
    80003398:	ec26                	sd	s1,24(sp)
    8000339a:	e84a                	sd	s2,16(sp)
    8000339c:	e44e                	sd	s3,8(sp)
    8000339e:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800033a0:	00004597          	auipc	a1,0x4
    800033a4:	18058593          	addi	a1,a1,384 # 80007520 <etext+0x520>
    800033a8:	0001e517          	auipc	a0,0x1e
    800033ac:	4c850513          	addi	a0,a0,1224 # 80021870 <itable>
    800033b0:	f9efd0ef          	jal	80000b4e <initlock>
  for(i = 0; i < NINODE; i++) {
    800033b4:	0001e497          	auipc	s1,0x1e
    800033b8:	4e448493          	addi	s1,s1,1252 # 80021898 <itable+0x28>
    800033bc:	00020997          	auipc	s3,0x20
    800033c0:	f6c98993          	addi	s3,s3,-148 # 80023328 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800033c4:	00004917          	auipc	s2,0x4
    800033c8:	16490913          	addi	s2,s2,356 # 80007528 <etext+0x528>
    800033cc:	85ca                	mv	a1,s2
    800033ce:	8526                	mv	a0,s1
    800033d0:	5bb000ef          	jal	8000418a <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800033d4:	08848493          	addi	s1,s1,136
    800033d8:	ff349ae3          	bne	s1,s3,800033cc <iinit+0x3a>
}
    800033dc:	70a2                	ld	ra,40(sp)
    800033de:	7402                	ld	s0,32(sp)
    800033e0:	64e2                	ld	s1,24(sp)
    800033e2:	6942                	ld	s2,16(sp)
    800033e4:	69a2                	ld	s3,8(sp)
    800033e6:	6145                	addi	sp,sp,48
    800033e8:	8082                	ret

00000000800033ea <ialloc>:
{
    800033ea:	7139                	addi	sp,sp,-64
    800033ec:	fc06                	sd	ra,56(sp)
    800033ee:	f822                	sd	s0,48(sp)
    800033f0:	0080                	addi	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    800033f2:	0001e717          	auipc	a4,0x1e
    800033f6:	46a72703          	lw	a4,1130(a4) # 8002185c <sb+0xc>
    800033fa:	4785                	li	a5,1
    800033fc:	06e7f063          	bgeu	a5,a4,8000345c <ialloc+0x72>
    80003400:	f426                	sd	s1,40(sp)
    80003402:	f04a                	sd	s2,32(sp)
    80003404:	ec4e                	sd	s3,24(sp)
    80003406:	e852                	sd	s4,16(sp)
    80003408:	e456                	sd	s5,8(sp)
    8000340a:	e05a                	sd	s6,0(sp)
    8000340c:	8aaa                	mv	s5,a0
    8000340e:	8b2e                	mv	s6,a1
    80003410:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003412:	0001ea17          	auipc	s4,0x1e
    80003416:	43ea0a13          	addi	s4,s4,1086 # 80021850 <sb>
    8000341a:	00495593          	srli	a1,s2,0x4
    8000341e:	018a2783          	lw	a5,24(s4)
    80003422:	9dbd                	addw	a1,a1,a5
    80003424:	8556                	mv	a0,s5
    80003426:	a69ff0ef          	jal	80002e8e <bread>
    8000342a:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000342c:	05850993          	addi	s3,a0,88
    80003430:	00f97793          	andi	a5,s2,15
    80003434:	079a                	slli	a5,a5,0x6
    80003436:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003438:	00099783          	lh	a5,0(s3)
    8000343c:	cb9d                	beqz	a5,80003472 <ialloc+0x88>
    brelse(bp);
    8000343e:	b59ff0ef          	jal	80002f96 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003442:	0905                	addi	s2,s2,1
    80003444:	00ca2703          	lw	a4,12(s4)
    80003448:	0009079b          	sext.w	a5,s2
    8000344c:	fce7e7e3          	bltu	a5,a4,8000341a <ialloc+0x30>
    80003450:	74a2                	ld	s1,40(sp)
    80003452:	7902                	ld	s2,32(sp)
    80003454:	69e2                	ld	s3,24(sp)
    80003456:	6a42                	ld	s4,16(sp)
    80003458:	6aa2                	ld	s5,8(sp)
    8000345a:	6b02                	ld	s6,0(sp)
  printf("ialloc: no inodes\n");
    8000345c:	00004517          	auipc	a0,0x4
    80003460:	0d450513          	addi	a0,a0,212 # 80007530 <etext+0x530>
    80003464:	896fd0ef          	jal	800004fa <printf>
  return 0;
    80003468:	4501                	li	a0,0
}
    8000346a:	70e2                	ld	ra,56(sp)
    8000346c:	7442                	ld	s0,48(sp)
    8000346e:	6121                	addi	sp,sp,64
    80003470:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003472:	04000613          	li	a2,64
    80003476:	4581                	li	a1,0
    80003478:	854e                	mv	a0,s3
    8000347a:	829fd0ef          	jal	80000ca2 <memset>
      dip->type = type;
    8000347e:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003482:	8526                	mv	a0,s1
    80003484:	445000ef          	jal	800040c8 <log_write>
      brelse(bp);
    80003488:	8526                	mv	a0,s1
    8000348a:	b0dff0ef          	jal	80002f96 <brelse>
      return iget(dev, inum);
    8000348e:	0009059b          	sext.w	a1,s2
    80003492:	8556                	mv	a0,s5
    80003494:	e53ff0ef          	jal	800032e6 <iget>
    80003498:	74a2                	ld	s1,40(sp)
    8000349a:	7902                	ld	s2,32(sp)
    8000349c:	69e2                	ld	s3,24(sp)
    8000349e:	6a42                	ld	s4,16(sp)
    800034a0:	6aa2                	ld	s5,8(sp)
    800034a2:	6b02                	ld	s6,0(sp)
    800034a4:	b7d9                	j	8000346a <ialloc+0x80>

00000000800034a6 <iupdate>:
{
    800034a6:	1101                	addi	sp,sp,-32
    800034a8:	ec06                	sd	ra,24(sp)
    800034aa:	e822                	sd	s0,16(sp)
    800034ac:	e426                	sd	s1,8(sp)
    800034ae:	e04a                	sd	s2,0(sp)
    800034b0:	1000                	addi	s0,sp,32
    800034b2:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800034b4:	415c                	lw	a5,4(a0)
    800034b6:	0047d79b          	srliw	a5,a5,0x4
    800034ba:	0001e597          	auipc	a1,0x1e
    800034be:	3ae5a583          	lw	a1,942(a1) # 80021868 <sb+0x18>
    800034c2:	9dbd                	addw	a1,a1,a5
    800034c4:	4108                	lw	a0,0(a0)
    800034c6:	9c9ff0ef          	jal	80002e8e <bread>
    800034ca:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800034cc:	05850793          	addi	a5,a0,88
    800034d0:	40d8                	lw	a4,4(s1)
    800034d2:	8b3d                	andi	a4,a4,15
    800034d4:	071a                	slli	a4,a4,0x6
    800034d6:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    800034d8:	04449703          	lh	a4,68(s1)
    800034dc:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    800034e0:	04649703          	lh	a4,70(s1)
    800034e4:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    800034e8:	04849703          	lh	a4,72(s1)
    800034ec:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    800034f0:	04a49703          	lh	a4,74(s1)
    800034f4:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    800034f8:	44f8                	lw	a4,76(s1)
    800034fa:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800034fc:	03400613          	li	a2,52
    80003500:	05048593          	addi	a1,s1,80
    80003504:	00c78513          	addi	a0,a5,12
    80003508:	ff6fd0ef          	jal	80000cfe <memmove>
  log_write(bp);
    8000350c:	854a                	mv	a0,s2
    8000350e:	3bb000ef          	jal	800040c8 <log_write>
  brelse(bp);
    80003512:	854a                	mv	a0,s2
    80003514:	a83ff0ef          	jal	80002f96 <brelse>
}
    80003518:	60e2                	ld	ra,24(sp)
    8000351a:	6442                	ld	s0,16(sp)
    8000351c:	64a2                	ld	s1,8(sp)
    8000351e:	6902                	ld	s2,0(sp)
    80003520:	6105                	addi	sp,sp,32
    80003522:	8082                	ret

0000000080003524 <idup>:
{
    80003524:	1101                	addi	sp,sp,-32
    80003526:	ec06                	sd	ra,24(sp)
    80003528:	e822                	sd	s0,16(sp)
    8000352a:	e426                	sd	s1,8(sp)
    8000352c:	1000                	addi	s0,sp,32
    8000352e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003530:	0001e517          	auipc	a0,0x1e
    80003534:	34050513          	addi	a0,a0,832 # 80021870 <itable>
    80003538:	e96fd0ef          	jal	80000bce <acquire>
  ip->ref++;
    8000353c:	449c                	lw	a5,8(s1)
    8000353e:	2785                	addiw	a5,a5,1
    80003540:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003542:	0001e517          	auipc	a0,0x1e
    80003546:	32e50513          	addi	a0,a0,814 # 80021870 <itable>
    8000354a:	f1cfd0ef          	jal	80000c66 <release>
}
    8000354e:	8526                	mv	a0,s1
    80003550:	60e2                	ld	ra,24(sp)
    80003552:	6442                	ld	s0,16(sp)
    80003554:	64a2                	ld	s1,8(sp)
    80003556:	6105                	addi	sp,sp,32
    80003558:	8082                	ret

000000008000355a <ilock>:
{
    8000355a:	1101                	addi	sp,sp,-32
    8000355c:	ec06                	sd	ra,24(sp)
    8000355e:	e822                	sd	s0,16(sp)
    80003560:	e426                	sd	s1,8(sp)
    80003562:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003564:	cd19                	beqz	a0,80003582 <ilock+0x28>
    80003566:	84aa                	mv	s1,a0
    80003568:	451c                	lw	a5,8(a0)
    8000356a:	00f05c63          	blez	a5,80003582 <ilock+0x28>
  acquiresleep(&ip->lock);
    8000356e:	0541                	addi	a0,a0,16
    80003570:	451000ef          	jal	800041c0 <acquiresleep>
  if(ip->valid == 0){
    80003574:	40bc                	lw	a5,64(s1)
    80003576:	cf89                	beqz	a5,80003590 <ilock+0x36>
}
    80003578:	60e2                	ld	ra,24(sp)
    8000357a:	6442                	ld	s0,16(sp)
    8000357c:	64a2                	ld	s1,8(sp)
    8000357e:	6105                	addi	sp,sp,32
    80003580:	8082                	ret
    80003582:	e04a                	sd	s2,0(sp)
    panic("ilock");
    80003584:	00004517          	auipc	a0,0x4
    80003588:	fc450513          	addi	a0,a0,-60 # 80007548 <etext+0x548>
    8000358c:	a54fd0ef          	jal	800007e0 <panic>
    80003590:	e04a                	sd	s2,0(sp)
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003592:	40dc                	lw	a5,4(s1)
    80003594:	0047d79b          	srliw	a5,a5,0x4
    80003598:	0001e597          	auipc	a1,0x1e
    8000359c:	2d05a583          	lw	a1,720(a1) # 80021868 <sb+0x18>
    800035a0:	9dbd                	addw	a1,a1,a5
    800035a2:	4088                	lw	a0,0(s1)
    800035a4:	8ebff0ef          	jal	80002e8e <bread>
    800035a8:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800035aa:	05850593          	addi	a1,a0,88
    800035ae:	40dc                	lw	a5,4(s1)
    800035b0:	8bbd                	andi	a5,a5,15
    800035b2:	079a                	slli	a5,a5,0x6
    800035b4:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800035b6:	00059783          	lh	a5,0(a1)
    800035ba:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800035be:	00259783          	lh	a5,2(a1)
    800035c2:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800035c6:	00459783          	lh	a5,4(a1)
    800035ca:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800035ce:	00659783          	lh	a5,6(a1)
    800035d2:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800035d6:	459c                	lw	a5,8(a1)
    800035d8:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800035da:	03400613          	li	a2,52
    800035de:	05b1                	addi	a1,a1,12
    800035e0:	05048513          	addi	a0,s1,80
    800035e4:	f1afd0ef          	jal	80000cfe <memmove>
    brelse(bp);
    800035e8:	854a                	mv	a0,s2
    800035ea:	9adff0ef          	jal	80002f96 <brelse>
    ip->valid = 1;
    800035ee:	4785                	li	a5,1
    800035f0:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800035f2:	04449783          	lh	a5,68(s1)
    800035f6:	c399                	beqz	a5,800035fc <ilock+0xa2>
    800035f8:	6902                	ld	s2,0(sp)
    800035fa:	bfbd                	j	80003578 <ilock+0x1e>
      panic("ilock: no type");
    800035fc:	00004517          	auipc	a0,0x4
    80003600:	f5450513          	addi	a0,a0,-172 # 80007550 <etext+0x550>
    80003604:	9dcfd0ef          	jal	800007e0 <panic>

0000000080003608 <iunlock>:
{
    80003608:	1101                	addi	sp,sp,-32
    8000360a:	ec06                	sd	ra,24(sp)
    8000360c:	e822                	sd	s0,16(sp)
    8000360e:	e426                	sd	s1,8(sp)
    80003610:	e04a                	sd	s2,0(sp)
    80003612:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003614:	c505                	beqz	a0,8000363c <iunlock+0x34>
    80003616:	84aa                	mv	s1,a0
    80003618:	01050913          	addi	s2,a0,16
    8000361c:	854a                	mv	a0,s2
    8000361e:	421000ef          	jal	8000423e <holdingsleep>
    80003622:	cd09                	beqz	a0,8000363c <iunlock+0x34>
    80003624:	449c                	lw	a5,8(s1)
    80003626:	00f05b63          	blez	a5,8000363c <iunlock+0x34>
  releasesleep(&ip->lock);
    8000362a:	854a                	mv	a0,s2
    8000362c:	3db000ef          	jal	80004206 <releasesleep>
}
    80003630:	60e2                	ld	ra,24(sp)
    80003632:	6442                	ld	s0,16(sp)
    80003634:	64a2                	ld	s1,8(sp)
    80003636:	6902                	ld	s2,0(sp)
    80003638:	6105                	addi	sp,sp,32
    8000363a:	8082                	ret
    panic("iunlock");
    8000363c:	00004517          	auipc	a0,0x4
    80003640:	f2450513          	addi	a0,a0,-220 # 80007560 <etext+0x560>
    80003644:	99cfd0ef          	jal	800007e0 <panic>

0000000080003648 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003648:	7179                	addi	sp,sp,-48
    8000364a:	f406                	sd	ra,40(sp)
    8000364c:	f022                	sd	s0,32(sp)
    8000364e:	ec26                	sd	s1,24(sp)
    80003650:	e84a                	sd	s2,16(sp)
    80003652:	e44e                	sd	s3,8(sp)
    80003654:	1800                	addi	s0,sp,48
    80003656:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003658:	05050493          	addi	s1,a0,80
    8000365c:	08050913          	addi	s2,a0,128
    80003660:	a021                	j	80003668 <itrunc+0x20>
    80003662:	0491                	addi	s1,s1,4
    80003664:	01248b63          	beq	s1,s2,8000367a <itrunc+0x32>
    if(ip->addrs[i]){
    80003668:	408c                	lw	a1,0(s1)
    8000366a:	dde5                	beqz	a1,80003662 <itrunc+0x1a>
      bfree(ip->dev, ip->addrs[i]);
    8000366c:	0009a503          	lw	a0,0(s3)
    80003670:	a17ff0ef          	jal	80003086 <bfree>
      ip->addrs[i] = 0;
    80003674:	0004a023          	sw	zero,0(s1)
    80003678:	b7ed                	j	80003662 <itrunc+0x1a>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000367a:	0809a583          	lw	a1,128(s3)
    8000367e:	ed89                	bnez	a1,80003698 <itrunc+0x50>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003680:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003684:	854e                	mv	a0,s3
    80003686:	e21ff0ef          	jal	800034a6 <iupdate>
}
    8000368a:	70a2                	ld	ra,40(sp)
    8000368c:	7402                	ld	s0,32(sp)
    8000368e:	64e2                	ld	s1,24(sp)
    80003690:	6942                	ld	s2,16(sp)
    80003692:	69a2                	ld	s3,8(sp)
    80003694:	6145                	addi	sp,sp,48
    80003696:	8082                	ret
    80003698:	e052                	sd	s4,0(sp)
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000369a:	0009a503          	lw	a0,0(s3)
    8000369e:	ff0ff0ef          	jal	80002e8e <bread>
    800036a2:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800036a4:	05850493          	addi	s1,a0,88
    800036a8:	45850913          	addi	s2,a0,1112
    800036ac:	a021                	j	800036b4 <itrunc+0x6c>
    800036ae:	0491                	addi	s1,s1,4
    800036b0:	01248963          	beq	s1,s2,800036c2 <itrunc+0x7a>
      if(a[j])
    800036b4:	408c                	lw	a1,0(s1)
    800036b6:	dde5                	beqz	a1,800036ae <itrunc+0x66>
        bfree(ip->dev, a[j]);
    800036b8:	0009a503          	lw	a0,0(s3)
    800036bc:	9cbff0ef          	jal	80003086 <bfree>
    800036c0:	b7fd                	j	800036ae <itrunc+0x66>
    brelse(bp);
    800036c2:	8552                	mv	a0,s4
    800036c4:	8d3ff0ef          	jal	80002f96 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800036c8:	0809a583          	lw	a1,128(s3)
    800036cc:	0009a503          	lw	a0,0(s3)
    800036d0:	9b7ff0ef          	jal	80003086 <bfree>
    ip->addrs[NDIRECT] = 0;
    800036d4:	0809a023          	sw	zero,128(s3)
    800036d8:	6a02                	ld	s4,0(sp)
    800036da:	b75d                	j	80003680 <itrunc+0x38>

00000000800036dc <iput>:
{
    800036dc:	1101                	addi	sp,sp,-32
    800036de:	ec06                	sd	ra,24(sp)
    800036e0:	e822                	sd	s0,16(sp)
    800036e2:	e426                	sd	s1,8(sp)
    800036e4:	1000                	addi	s0,sp,32
    800036e6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800036e8:	0001e517          	auipc	a0,0x1e
    800036ec:	18850513          	addi	a0,a0,392 # 80021870 <itable>
    800036f0:	cdefd0ef          	jal	80000bce <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800036f4:	4498                	lw	a4,8(s1)
    800036f6:	4785                	li	a5,1
    800036f8:	02f70063          	beq	a4,a5,80003718 <iput+0x3c>
  ip->ref--;
    800036fc:	449c                	lw	a5,8(s1)
    800036fe:	37fd                	addiw	a5,a5,-1
    80003700:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003702:	0001e517          	auipc	a0,0x1e
    80003706:	16e50513          	addi	a0,a0,366 # 80021870 <itable>
    8000370a:	d5cfd0ef          	jal	80000c66 <release>
}
    8000370e:	60e2                	ld	ra,24(sp)
    80003710:	6442                	ld	s0,16(sp)
    80003712:	64a2                	ld	s1,8(sp)
    80003714:	6105                	addi	sp,sp,32
    80003716:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003718:	40bc                	lw	a5,64(s1)
    8000371a:	d3ed                	beqz	a5,800036fc <iput+0x20>
    8000371c:	04a49783          	lh	a5,74(s1)
    80003720:	fff1                	bnez	a5,800036fc <iput+0x20>
    80003722:	e04a                	sd	s2,0(sp)
    acquiresleep(&ip->lock);
    80003724:	01048913          	addi	s2,s1,16
    80003728:	854a                	mv	a0,s2
    8000372a:	297000ef          	jal	800041c0 <acquiresleep>
    release(&itable.lock);
    8000372e:	0001e517          	auipc	a0,0x1e
    80003732:	14250513          	addi	a0,a0,322 # 80021870 <itable>
    80003736:	d30fd0ef          	jal	80000c66 <release>
    itrunc(ip);
    8000373a:	8526                	mv	a0,s1
    8000373c:	f0dff0ef          	jal	80003648 <itrunc>
    ip->type = 0;
    80003740:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003744:	8526                	mv	a0,s1
    80003746:	d61ff0ef          	jal	800034a6 <iupdate>
    ip->valid = 0;
    8000374a:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000374e:	854a                	mv	a0,s2
    80003750:	2b7000ef          	jal	80004206 <releasesleep>
    acquire(&itable.lock);
    80003754:	0001e517          	auipc	a0,0x1e
    80003758:	11c50513          	addi	a0,a0,284 # 80021870 <itable>
    8000375c:	c72fd0ef          	jal	80000bce <acquire>
    80003760:	6902                	ld	s2,0(sp)
    80003762:	bf69                	j	800036fc <iput+0x20>

0000000080003764 <iunlockput>:
{
    80003764:	1101                	addi	sp,sp,-32
    80003766:	ec06                	sd	ra,24(sp)
    80003768:	e822                	sd	s0,16(sp)
    8000376a:	e426                	sd	s1,8(sp)
    8000376c:	1000                	addi	s0,sp,32
    8000376e:	84aa                	mv	s1,a0
  iunlock(ip);
    80003770:	e99ff0ef          	jal	80003608 <iunlock>
  iput(ip);
    80003774:	8526                	mv	a0,s1
    80003776:	f67ff0ef          	jal	800036dc <iput>
}
    8000377a:	60e2                	ld	ra,24(sp)
    8000377c:	6442                	ld	s0,16(sp)
    8000377e:	64a2                	ld	s1,8(sp)
    80003780:	6105                	addi	sp,sp,32
    80003782:	8082                	ret

0000000080003784 <ireclaim>:
  for (int inum = 1; inum < sb.ninodes; inum++) {
    80003784:	0001e717          	auipc	a4,0x1e
    80003788:	0d872703          	lw	a4,216(a4) # 8002185c <sb+0xc>
    8000378c:	4785                	li	a5,1
    8000378e:	0ae7ff63          	bgeu	a5,a4,8000384c <ireclaim+0xc8>
{
    80003792:	7139                	addi	sp,sp,-64
    80003794:	fc06                	sd	ra,56(sp)
    80003796:	f822                	sd	s0,48(sp)
    80003798:	f426                	sd	s1,40(sp)
    8000379a:	f04a                	sd	s2,32(sp)
    8000379c:	ec4e                	sd	s3,24(sp)
    8000379e:	e852                	sd	s4,16(sp)
    800037a0:	e456                	sd	s5,8(sp)
    800037a2:	e05a                	sd	s6,0(sp)
    800037a4:	0080                	addi	s0,sp,64
  for (int inum = 1; inum < sb.ninodes; inum++) {
    800037a6:	4485                	li	s1,1
    struct buf *bp = bread(dev, IBLOCK(inum, sb));
    800037a8:	00050a1b          	sext.w	s4,a0
    800037ac:	0001ea97          	auipc	s5,0x1e
    800037b0:	0a4a8a93          	addi	s5,s5,164 # 80021850 <sb>
      printf("ireclaim: orphaned inode %d\n", inum);
    800037b4:	00004b17          	auipc	s6,0x4
    800037b8:	db4b0b13          	addi	s6,s6,-588 # 80007568 <etext+0x568>
    800037bc:	a099                	j	80003802 <ireclaim+0x7e>
    800037be:	85ce                	mv	a1,s3
    800037c0:	855a                	mv	a0,s6
    800037c2:	d39fc0ef          	jal	800004fa <printf>
      ip = iget(dev, inum);
    800037c6:	85ce                	mv	a1,s3
    800037c8:	8552                	mv	a0,s4
    800037ca:	b1dff0ef          	jal	800032e6 <iget>
    800037ce:	89aa                	mv	s3,a0
    brelse(bp);
    800037d0:	854a                	mv	a0,s2
    800037d2:	fc4ff0ef          	jal	80002f96 <brelse>
    if (ip) {
    800037d6:	00098f63          	beqz	s3,800037f4 <ireclaim+0x70>
      begin_op();
    800037da:	76a000ef          	jal	80003f44 <begin_op>
      ilock(ip);
    800037de:	854e                	mv	a0,s3
    800037e0:	d7bff0ef          	jal	8000355a <ilock>
      iunlock(ip);
    800037e4:	854e                	mv	a0,s3
    800037e6:	e23ff0ef          	jal	80003608 <iunlock>
      iput(ip);
    800037ea:	854e                	mv	a0,s3
    800037ec:	ef1ff0ef          	jal	800036dc <iput>
      end_op();
    800037f0:	7be000ef          	jal	80003fae <end_op>
  for (int inum = 1; inum < sb.ninodes; inum++) {
    800037f4:	0485                	addi	s1,s1,1
    800037f6:	00caa703          	lw	a4,12(s5)
    800037fa:	0004879b          	sext.w	a5,s1
    800037fe:	02e7fd63          	bgeu	a5,a4,80003838 <ireclaim+0xb4>
    80003802:	0004899b          	sext.w	s3,s1
    struct buf *bp = bread(dev, IBLOCK(inum, sb));
    80003806:	0044d593          	srli	a1,s1,0x4
    8000380a:	018aa783          	lw	a5,24(s5)
    8000380e:	9dbd                	addw	a1,a1,a5
    80003810:	8552                	mv	a0,s4
    80003812:	e7cff0ef          	jal	80002e8e <bread>
    80003816:	892a                	mv	s2,a0
    struct dinode *dip = (struct dinode *)bp->data + inum % IPB;
    80003818:	05850793          	addi	a5,a0,88
    8000381c:	00f9f713          	andi	a4,s3,15
    80003820:	071a                	slli	a4,a4,0x6
    80003822:	97ba                	add	a5,a5,a4
    if (dip->type != 0 && dip->nlink == 0) {  // is an orphaned inode
    80003824:	00079703          	lh	a4,0(a5)
    80003828:	c701                	beqz	a4,80003830 <ireclaim+0xac>
    8000382a:	00679783          	lh	a5,6(a5)
    8000382e:	dbc1                	beqz	a5,800037be <ireclaim+0x3a>
    brelse(bp);
    80003830:	854a                	mv	a0,s2
    80003832:	f64ff0ef          	jal	80002f96 <brelse>
    if (ip) {
    80003836:	bf7d                	j	800037f4 <ireclaim+0x70>
}
    80003838:	70e2                	ld	ra,56(sp)
    8000383a:	7442                	ld	s0,48(sp)
    8000383c:	74a2                	ld	s1,40(sp)
    8000383e:	7902                	ld	s2,32(sp)
    80003840:	69e2                	ld	s3,24(sp)
    80003842:	6a42                	ld	s4,16(sp)
    80003844:	6aa2                	ld	s5,8(sp)
    80003846:	6b02                	ld	s6,0(sp)
    80003848:	6121                	addi	sp,sp,64
    8000384a:	8082                	ret
    8000384c:	8082                	ret

000000008000384e <fsinit>:
fsinit(int dev) {
    8000384e:	7179                	addi	sp,sp,-48
    80003850:	f406                	sd	ra,40(sp)
    80003852:	f022                	sd	s0,32(sp)
    80003854:	ec26                	sd	s1,24(sp)
    80003856:	e84a                	sd	s2,16(sp)
    80003858:	e44e                	sd	s3,8(sp)
    8000385a:	1800                	addi	s0,sp,48
    8000385c:	84aa                	mv	s1,a0
  bp = bread(dev, 1);
    8000385e:	4585                	li	a1,1
    80003860:	e2eff0ef          	jal	80002e8e <bread>
    80003864:	892a                	mv	s2,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003866:	0001e997          	auipc	s3,0x1e
    8000386a:	fea98993          	addi	s3,s3,-22 # 80021850 <sb>
    8000386e:	02000613          	li	a2,32
    80003872:	05850593          	addi	a1,a0,88
    80003876:	854e                	mv	a0,s3
    80003878:	c86fd0ef          	jal	80000cfe <memmove>
  brelse(bp);
    8000387c:	854a                	mv	a0,s2
    8000387e:	f18ff0ef          	jal	80002f96 <brelse>
  if(sb.magic != FSMAGIC)
    80003882:	0009a703          	lw	a4,0(s3)
    80003886:	102037b7          	lui	a5,0x10203
    8000388a:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000388e:	02f71363          	bne	a4,a5,800038b4 <fsinit+0x66>
  initlog(dev, &sb);
    80003892:	0001e597          	auipc	a1,0x1e
    80003896:	fbe58593          	addi	a1,a1,-66 # 80021850 <sb>
    8000389a:	8526                	mv	a0,s1
    8000389c:	62a000ef          	jal	80003ec6 <initlog>
  ireclaim(dev);
    800038a0:	8526                	mv	a0,s1
    800038a2:	ee3ff0ef          	jal	80003784 <ireclaim>
}
    800038a6:	70a2                	ld	ra,40(sp)
    800038a8:	7402                	ld	s0,32(sp)
    800038aa:	64e2                	ld	s1,24(sp)
    800038ac:	6942                	ld	s2,16(sp)
    800038ae:	69a2                	ld	s3,8(sp)
    800038b0:	6145                	addi	sp,sp,48
    800038b2:	8082                	ret
    panic("invalid file system");
    800038b4:	00004517          	auipc	a0,0x4
    800038b8:	cd450513          	addi	a0,a0,-812 # 80007588 <etext+0x588>
    800038bc:	f25fc0ef          	jal	800007e0 <panic>

00000000800038c0 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800038c0:	1141                	addi	sp,sp,-16
    800038c2:	e422                	sd	s0,8(sp)
    800038c4:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800038c6:	411c                	lw	a5,0(a0)
    800038c8:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800038ca:	415c                	lw	a5,4(a0)
    800038cc:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800038ce:	04451783          	lh	a5,68(a0)
    800038d2:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800038d6:	04a51783          	lh	a5,74(a0)
    800038da:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800038de:	04c56783          	lwu	a5,76(a0)
    800038e2:	e99c                	sd	a5,16(a1)
}
    800038e4:	6422                	ld	s0,8(sp)
    800038e6:	0141                	addi	sp,sp,16
    800038e8:	8082                	ret

00000000800038ea <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800038ea:	457c                	lw	a5,76(a0)
    800038ec:	0ed7eb63          	bltu	a5,a3,800039e2 <readi+0xf8>
{
    800038f0:	7159                	addi	sp,sp,-112
    800038f2:	f486                	sd	ra,104(sp)
    800038f4:	f0a2                	sd	s0,96(sp)
    800038f6:	eca6                	sd	s1,88(sp)
    800038f8:	e0d2                	sd	s4,64(sp)
    800038fa:	fc56                	sd	s5,56(sp)
    800038fc:	f85a                	sd	s6,48(sp)
    800038fe:	f45e                	sd	s7,40(sp)
    80003900:	1880                	addi	s0,sp,112
    80003902:	8b2a                	mv	s6,a0
    80003904:	8bae                	mv	s7,a1
    80003906:	8a32                	mv	s4,a2
    80003908:	84b6                	mv	s1,a3
    8000390a:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    8000390c:	9f35                	addw	a4,a4,a3
    return 0;
    8000390e:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003910:	0cd76063          	bltu	a4,a3,800039d0 <readi+0xe6>
    80003914:	e4ce                	sd	s3,72(sp)
  if(off + n > ip->size)
    80003916:	00e7f463          	bgeu	a5,a4,8000391e <readi+0x34>
    n = ip->size - off;
    8000391a:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000391e:	080a8f63          	beqz	s5,800039bc <readi+0xd2>
    80003922:	e8ca                	sd	s2,80(sp)
    80003924:	f062                	sd	s8,32(sp)
    80003926:	ec66                	sd	s9,24(sp)
    80003928:	e86a                	sd	s10,16(sp)
    8000392a:	e46e                	sd	s11,8(sp)
    8000392c:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    8000392e:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003932:	5c7d                	li	s8,-1
    80003934:	a80d                	j	80003966 <readi+0x7c>
    80003936:	020d1d93          	slli	s11,s10,0x20
    8000393a:	020ddd93          	srli	s11,s11,0x20
    8000393e:	05890613          	addi	a2,s2,88
    80003942:	86ee                	mv	a3,s11
    80003944:	963a                	add	a2,a2,a4
    80003946:	85d2                	mv	a1,s4
    80003948:	855e                	mv	a0,s7
    8000394a:	ba1fe0ef          	jal	800024ea <either_copyout>
    8000394e:	05850763          	beq	a0,s8,8000399c <readi+0xb2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003952:	854a                	mv	a0,s2
    80003954:	e42ff0ef          	jal	80002f96 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003958:	013d09bb          	addw	s3,s10,s3
    8000395c:	009d04bb          	addw	s1,s10,s1
    80003960:	9a6e                	add	s4,s4,s11
    80003962:	0559f763          	bgeu	s3,s5,800039b0 <readi+0xc6>
    uint addr = bmap(ip, off/BSIZE);
    80003966:	00a4d59b          	srliw	a1,s1,0xa
    8000396a:	855a                	mv	a0,s6
    8000396c:	8a7ff0ef          	jal	80003212 <bmap>
    80003970:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003974:	c5b1                	beqz	a1,800039c0 <readi+0xd6>
    bp = bread(ip->dev, addr);
    80003976:	000b2503          	lw	a0,0(s6)
    8000397a:	d14ff0ef          	jal	80002e8e <bread>
    8000397e:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003980:	3ff4f713          	andi	a4,s1,1023
    80003984:	40ec87bb          	subw	a5,s9,a4
    80003988:	413a86bb          	subw	a3,s5,s3
    8000398c:	8d3e                	mv	s10,a5
    8000398e:	2781                	sext.w	a5,a5
    80003990:	0006861b          	sext.w	a2,a3
    80003994:	faf671e3          	bgeu	a2,a5,80003936 <readi+0x4c>
    80003998:	8d36                	mv	s10,a3
    8000399a:	bf71                	j	80003936 <readi+0x4c>
      brelse(bp);
    8000399c:	854a                	mv	a0,s2
    8000399e:	df8ff0ef          	jal	80002f96 <brelse>
      tot = -1;
    800039a2:	59fd                	li	s3,-1
      break;
    800039a4:	6946                	ld	s2,80(sp)
    800039a6:	7c02                	ld	s8,32(sp)
    800039a8:	6ce2                	ld	s9,24(sp)
    800039aa:	6d42                	ld	s10,16(sp)
    800039ac:	6da2                	ld	s11,8(sp)
    800039ae:	a831                	j	800039ca <readi+0xe0>
    800039b0:	6946                	ld	s2,80(sp)
    800039b2:	7c02                	ld	s8,32(sp)
    800039b4:	6ce2                	ld	s9,24(sp)
    800039b6:	6d42                	ld	s10,16(sp)
    800039b8:	6da2                	ld	s11,8(sp)
    800039ba:	a801                	j	800039ca <readi+0xe0>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800039bc:	89d6                	mv	s3,s5
    800039be:	a031                	j	800039ca <readi+0xe0>
    800039c0:	6946                	ld	s2,80(sp)
    800039c2:	7c02                	ld	s8,32(sp)
    800039c4:	6ce2                	ld	s9,24(sp)
    800039c6:	6d42                	ld	s10,16(sp)
    800039c8:	6da2                	ld	s11,8(sp)
  }
  return tot;
    800039ca:	0009851b          	sext.w	a0,s3
    800039ce:	69a6                	ld	s3,72(sp)
}
    800039d0:	70a6                	ld	ra,104(sp)
    800039d2:	7406                	ld	s0,96(sp)
    800039d4:	64e6                	ld	s1,88(sp)
    800039d6:	6a06                	ld	s4,64(sp)
    800039d8:	7ae2                	ld	s5,56(sp)
    800039da:	7b42                	ld	s6,48(sp)
    800039dc:	7ba2                	ld	s7,40(sp)
    800039de:	6165                	addi	sp,sp,112
    800039e0:	8082                	ret
    return 0;
    800039e2:	4501                	li	a0,0
}
    800039e4:	8082                	ret

00000000800039e6 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800039e6:	457c                	lw	a5,76(a0)
    800039e8:	10d7e063          	bltu	a5,a3,80003ae8 <writei+0x102>
{
    800039ec:	7159                	addi	sp,sp,-112
    800039ee:	f486                	sd	ra,104(sp)
    800039f0:	f0a2                	sd	s0,96(sp)
    800039f2:	e8ca                	sd	s2,80(sp)
    800039f4:	e0d2                	sd	s4,64(sp)
    800039f6:	fc56                	sd	s5,56(sp)
    800039f8:	f85a                	sd	s6,48(sp)
    800039fa:	f45e                	sd	s7,40(sp)
    800039fc:	1880                	addi	s0,sp,112
    800039fe:	8aaa                	mv	s5,a0
    80003a00:	8bae                	mv	s7,a1
    80003a02:	8a32                	mv	s4,a2
    80003a04:	8936                	mv	s2,a3
    80003a06:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a08:	00e687bb          	addw	a5,a3,a4
    80003a0c:	0ed7e063          	bltu	a5,a3,80003aec <writei+0x106>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003a10:	00043737          	lui	a4,0x43
    80003a14:	0cf76e63          	bltu	a4,a5,80003af0 <writei+0x10a>
    80003a18:	e4ce                	sd	s3,72(sp)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a1a:	0a0b0f63          	beqz	s6,80003ad8 <writei+0xf2>
    80003a1e:	eca6                	sd	s1,88(sp)
    80003a20:	f062                	sd	s8,32(sp)
    80003a22:	ec66                	sd	s9,24(sp)
    80003a24:	e86a                	sd	s10,16(sp)
    80003a26:	e46e                	sd	s11,8(sp)
    80003a28:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a2a:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003a2e:	5c7d                	li	s8,-1
    80003a30:	a825                	j	80003a68 <writei+0x82>
    80003a32:	020d1d93          	slli	s11,s10,0x20
    80003a36:	020ddd93          	srli	s11,s11,0x20
    80003a3a:	05848513          	addi	a0,s1,88
    80003a3e:	86ee                	mv	a3,s11
    80003a40:	8652                	mv	a2,s4
    80003a42:	85de                	mv	a1,s7
    80003a44:	953a                	add	a0,a0,a4
    80003a46:	aeffe0ef          	jal	80002534 <either_copyin>
    80003a4a:	05850a63          	beq	a0,s8,80003a9e <writei+0xb8>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003a4e:	8526                	mv	a0,s1
    80003a50:	678000ef          	jal	800040c8 <log_write>
    brelse(bp);
    80003a54:	8526                	mv	a0,s1
    80003a56:	d40ff0ef          	jal	80002f96 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003a5a:	013d09bb          	addw	s3,s10,s3
    80003a5e:	012d093b          	addw	s2,s10,s2
    80003a62:	9a6e                	add	s4,s4,s11
    80003a64:	0569f063          	bgeu	s3,s6,80003aa4 <writei+0xbe>
    uint addr = bmap(ip, off/BSIZE);
    80003a68:	00a9559b          	srliw	a1,s2,0xa
    80003a6c:	8556                	mv	a0,s5
    80003a6e:	fa4ff0ef          	jal	80003212 <bmap>
    80003a72:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003a76:	c59d                	beqz	a1,80003aa4 <writei+0xbe>
    bp = bread(ip->dev, addr);
    80003a78:	000aa503          	lw	a0,0(s5)
    80003a7c:	c12ff0ef          	jal	80002e8e <bread>
    80003a80:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a82:	3ff97713          	andi	a4,s2,1023
    80003a86:	40ec87bb          	subw	a5,s9,a4
    80003a8a:	413b06bb          	subw	a3,s6,s3
    80003a8e:	8d3e                	mv	s10,a5
    80003a90:	2781                	sext.w	a5,a5
    80003a92:	0006861b          	sext.w	a2,a3
    80003a96:	f8f67ee3          	bgeu	a2,a5,80003a32 <writei+0x4c>
    80003a9a:	8d36                	mv	s10,a3
    80003a9c:	bf59                	j	80003a32 <writei+0x4c>
      brelse(bp);
    80003a9e:	8526                	mv	a0,s1
    80003aa0:	cf6ff0ef          	jal	80002f96 <brelse>
  }

  if(off > ip->size)
    80003aa4:	04caa783          	lw	a5,76(s5)
    80003aa8:	0327fa63          	bgeu	a5,s2,80003adc <writei+0xf6>
    ip->size = off;
    80003aac:	052aa623          	sw	s2,76(s5)
    80003ab0:	64e6                	ld	s1,88(sp)
    80003ab2:	7c02                	ld	s8,32(sp)
    80003ab4:	6ce2                	ld	s9,24(sp)
    80003ab6:	6d42                	ld	s10,16(sp)
    80003ab8:	6da2                	ld	s11,8(sp)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003aba:	8556                	mv	a0,s5
    80003abc:	9ebff0ef          	jal	800034a6 <iupdate>

  return tot;
    80003ac0:	0009851b          	sext.w	a0,s3
    80003ac4:	69a6                	ld	s3,72(sp)
}
    80003ac6:	70a6                	ld	ra,104(sp)
    80003ac8:	7406                	ld	s0,96(sp)
    80003aca:	6946                	ld	s2,80(sp)
    80003acc:	6a06                	ld	s4,64(sp)
    80003ace:	7ae2                	ld	s5,56(sp)
    80003ad0:	7b42                	ld	s6,48(sp)
    80003ad2:	7ba2                	ld	s7,40(sp)
    80003ad4:	6165                	addi	sp,sp,112
    80003ad6:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ad8:	89da                	mv	s3,s6
    80003ada:	b7c5                	j	80003aba <writei+0xd4>
    80003adc:	64e6                	ld	s1,88(sp)
    80003ade:	7c02                	ld	s8,32(sp)
    80003ae0:	6ce2                	ld	s9,24(sp)
    80003ae2:	6d42                	ld	s10,16(sp)
    80003ae4:	6da2                	ld	s11,8(sp)
    80003ae6:	bfd1                	j	80003aba <writei+0xd4>
    return -1;
    80003ae8:	557d                	li	a0,-1
}
    80003aea:	8082                	ret
    return -1;
    80003aec:	557d                	li	a0,-1
    80003aee:	bfe1                	j	80003ac6 <writei+0xe0>
    return -1;
    80003af0:	557d                	li	a0,-1
    80003af2:	bfd1                	j	80003ac6 <writei+0xe0>

0000000080003af4 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003af4:	1141                	addi	sp,sp,-16
    80003af6:	e406                	sd	ra,8(sp)
    80003af8:	e022                	sd	s0,0(sp)
    80003afa:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003afc:	4639                	li	a2,14
    80003afe:	a70fd0ef          	jal	80000d6e <strncmp>
}
    80003b02:	60a2                	ld	ra,8(sp)
    80003b04:	6402                	ld	s0,0(sp)
    80003b06:	0141                	addi	sp,sp,16
    80003b08:	8082                	ret

0000000080003b0a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003b0a:	7139                	addi	sp,sp,-64
    80003b0c:	fc06                	sd	ra,56(sp)
    80003b0e:	f822                	sd	s0,48(sp)
    80003b10:	f426                	sd	s1,40(sp)
    80003b12:	f04a                	sd	s2,32(sp)
    80003b14:	ec4e                	sd	s3,24(sp)
    80003b16:	e852                	sd	s4,16(sp)
    80003b18:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003b1a:	04451703          	lh	a4,68(a0)
    80003b1e:	4785                	li	a5,1
    80003b20:	00f71a63          	bne	a4,a5,80003b34 <dirlookup+0x2a>
    80003b24:	892a                	mv	s2,a0
    80003b26:	89ae                	mv	s3,a1
    80003b28:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b2a:	457c                	lw	a5,76(a0)
    80003b2c:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003b2e:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b30:	e39d                	bnez	a5,80003b56 <dirlookup+0x4c>
    80003b32:	a095                	j	80003b96 <dirlookup+0x8c>
    panic("dirlookup not DIR");
    80003b34:	00004517          	auipc	a0,0x4
    80003b38:	a6c50513          	addi	a0,a0,-1428 # 800075a0 <etext+0x5a0>
    80003b3c:	ca5fc0ef          	jal	800007e0 <panic>
      panic("dirlookup read");
    80003b40:	00004517          	auipc	a0,0x4
    80003b44:	a7850513          	addi	a0,a0,-1416 # 800075b8 <etext+0x5b8>
    80003b48:	c99fc0ef          	jal	800007e0 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003b4c:	24c1                	addiw	s1,s1,16
    80003b4e:	04c92783          	lw	a5,76(s2)
    80003b52:	04f4f163          	bgeu	s1,a5,80003b94 <dirlookup+0x8a>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003b56:	4741                	li	a4,16
    80003b58:	86a6                	mv	a3,s1
    80003b5a:	fc040613          	addi	a2,s0,-64
    80003b5e:	4581                	li	a1,0
    80003b60:	854a                	mv	a0,s2
    80003b62:	d89ff0ef          	jal	800038ea <readi>
    80003b66:	47c1                	li	a5,16
    80003b68:	fcf51ce3          	bne	a0,a5,80003b40 <dirlookup+0x36>
    if(de.inum == 0)
    80003b6c:	fc045783          	lhu	a5,-64(s0)
    80003b70:	dff1                	beqz	a5,80003b4c <dirlookup+0x42>
    if(namecmp(name, de.name) == 0){
    80003b72:	fc240593          	addi	a1,s0,-62
    80003b76:	854e                	mv	a0,s3
    80003b78:	f7dff0ef          	jal	80003af4 <namecmp>
    80003b7c:	f961                	bnez	a0,80003b4c <dirlookup+0x42>
      if(poff)
    80003b7e:	000a0463          	beqz	s4,80003b86 <dirlookup+0x7c>
        *poff = off;
    80003b82:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003b86:	fc045583          	lhu	a1,-64(s0)
    80003b8a:	00092503          	lw	a0,0(s2)
    80003b8e:	f58ff0ef          	jal	800032e6 <iget>
    80003b92:	a011                	j	80003b96 <dirlookup+0x8c>
  return 0;
    80003b94:	4501                	li	a0,0
}
    80003b96:	70e2                	ld	ra,56(sp)
    80003b98:	7442                	ld	s0,48(sp)
    80003b9a:	74a2                	ld	s1,40(sp)
    80003b9c:	7902                	ld	s2,32(sp)
    80003b9e:	69e2                	ld	s3,24(sp)
    80003ba0:	6a42                	ld	s4,16(sp)
    80003ba2:	6121                	addi	sp,sp,64
    80003ba4:	8082                	ret

0000000080003ba6 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003ba6:	711d                	addi	sp,sp,-96
    80003ba8:	ec86                	sd	ra,88(sp)
    80003baa:	e8a2                	sd	s0,80(sp)
    80003bac:	e4a6                	sd	s1,72(sp)
    80003bae:	e0ca                	sd	s2,64(sp)
    80003bb0:	fc4e                	sd	s3,56(sp)
    80003bb2:	f852                	sd	s4,48(sp)
    80003bb4:	f456                	sd	s5,40(sp)
    80003bb6:	f05a                	sd	s6,32(sp)
    80003bb8:	ec5e                	sd	s7,24(sp)
    80003bba:	e862                	sd	s8,16(sp)
    80003bbc:	e466                	sd	s9,8(sp)
    80003bbe:	1080                	addi	s0,sp,96
    80003bc0:	84aa                	mv	s1,a0
    80003bc2:	8b2e                	mv	s6,a1
    80003bc4:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003bc6:	00054703          	lbu	a4,0(a0)
    80003bca:	02f00793          	li	a5,47
    80003bce:	00f70e63          	beq	a4,a5,80003bea <namex+0x44>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003bd2:	d3dfd0ef          	jal	8000190e <myproc>
    80003bd6:	15053503          	ld	a0,336(a0)
    80003bda:	94bff0ef          	jal	80003524 <idup>
    80003bde:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003be0:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003be4:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003be6:	4b85                	li	s7,1
    80003be8:	a871                	j	80003c84 <namex+0xde>
    ip = iget(ROOTDEV, ROOTINO);
    80003bea:	4585                	li	a1,1
    80003bec:	4505                	li	a0,1
    80003bee:	ef8ff0ef          	jal	800032e6 <iget>
    80003bf2:	8a2a                	mv	s4,a0
    80003bf4:	b7f5                	j	80003be0 <namex+0x3a>
      iunlockput(ip);
    80003bf6:	8552                	mv	a0,s4
    80003bf8:	b6dff0ef          	jal	80003764 <iunlockput>
      return 0;
    80003bfc:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003bfe:	8552                	mv	a0,s4
    80003c00:	60e6                	ld	ra,88(sp)
    80003c02:	6446                	ld	s0,80(sp)
    80003c04:	64a6                	ld	s1,72(sp)
    80003c06:	6906                	ld	s2,64(sp)
    80003c08:	79e2                	ld	s3,56(sp)
    80003c0a:	7a42                	ld	s4,48(sp)
    80003c0c:	7aa2                	ld	s5,40(sp)
    80003c0e:	7b02                	ld	s6,32(sp)
    80003c10:	6be2                	ld	s7,24(sp)
    80003c12:	6c42                	ld	s8,16(sp)
    80003c14:	6ca2                	ld	s9,8(sp)
    80003c16:	6125                	addi	sp,sp,96
    80003c18:	8082                	ret
      iunlock(ip);
    80003c1a:	8552                	mv	a0,s4
    80003c1c:	9edff0ef          	jal	80003608 <iunlock>
      return ip;
    80003c20:	bff9                	j	80003bfe <namex+0x58>
      iunlockput(ip);
    80003c22:	8552                	mv	a0,s4
    80003c24:	b41ff0ef          	jal	80003764 <iunlockput>
      return 0;
    80003c28:	8a4e                	mv	s4,s3
    80003c2a:	bfd1                	j	80003bfe <namex+0x58>
  len = path - s;
    80003c2c:	40998633          	sub	a2,s3,s1
    80003c30:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80003c34:	099c5063          	bge	s8,s9,80003cb4 <namex+0x10e>
    memmove(name, s, DIRSIZ);
    80003c38:	4639                	li	a2,14
    80003c3a:	85a6                	mv	a1,s1
    80003c3c:	8556                	mv	a0,s5
    80003c3e:	8c0fd0ef          	jal	80000cfe <memmove>
    80003c42:	84ce                	mv	s1,s3
  while(*path == '/')
    80003c44:	0004c783          	lbu	a5,0(s1)
    80003c48:	01279763          	bne	a5,s2,80003c56 <namex+0xb0>
    path++;
    80003c4c:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003c4e:	0004c783          	lbu	a5,0(s1)
    80003c52:	ff278de3          	beq	a5,s2,80003c4c <namex+0xa6>
    ilock(ip);
    80003c56:	8552                	mv	a0,s4
    80003c58:	903ff0ef          	jal	8000355a <ilock>
    if(ip->type != T_DIR){
    80003c5c:	044a1783          	lh	a5,68(s4)
    80003c60:	f9779be3          	bne	a5,s7,80003bf6 <namex+0x50>
    if(nameiparent && *path == '\0'){
    80003c64:	000b0563          	beqz	s6,80003c6e <namex+0xc8>
    80003c68:	0004c783          	lbu	a5,0(s1)
    80003c6c:	d7dd                	beqz	a5,80003c1a <namex+0x74>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003c6e:	4601                	li	a2,0
    80003c70:	85d6                	mv	a1,s5
    80003c72:	8552                	mv	a0,s4
    80003c74:	e97ff0ef          	jal	80003b0a <dirlookup>
    80003c78:	89aa                	mv	s3,a0
    80003c7a:	d545                	beqz	a0,80003c22 <namex+0x7c>
    iunlockput(ip);
    80003c7c:	8552                	mv	a0,s4
    80003c7e:	ae7ff0ef          	jal	80003764 <iunlockput>
    ip = next;
    80003c82:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003c84:	0004c783          	lbu	a5,0(s1)
    80003c88:	01279763          	bne	a5,s2,80003c96 <namex+0xf0>
    path++;
    80003c8c:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003c8e:	0004c783          	lbu	a5,0(s1)
    80003c92:	ff278de3          	beq	a5,s2,80003c8c <namex+0xe6>
  if(*path == 0)
    80003c96:	cb8d                	beqz	a5,80003cc8 <namex+0x122>
  while(*path != '/' && *path != 0)
    80003c98:	0004c783          	lbu	a5,0(s1)
    80003c9c:	89a6                	mv	s3,s1
  len = path - s;
    80003c9e:	4c81                	li	s9,0
    80003ca0:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    80003ca2:	01278963          	beq	a5,s2,80003cb4 <namex+0x10e>
    80003ca6:	d3d9                	beqz	a5,80003c2c <namex+0x86>
    path++;
    80003ca8:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003caa:	0009c783          	lbu	a5,0(s3)
    80003cae:	ff279ce3          	bne	a5,s2,80003ca6 <namex+0x100>
    80003cb2:	bfad                	j	80003c2c <namex+0x86>
    memmove(name, s, len);
    80003cb4:	2601                	sext.w	a2,a2
    80003cb6:	85a6                	mv	a1,s1
    80003cb8:	8556                	mv	a0,s5
    80003cba:	844fd0ef          	jal	80000cfe <memmove>
    name[len] = 0;
    80003cbe:	9cd6                	add	s9,s9,s5
    80003cc0:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80003cc4:	84ce                	mv	s1,s3
    80003cc6:	bfbd                	j	80003c44 <namex+0x9e>
  if(nameiparent){
    80003cc8:	f20b0be3          	beqz	s6,80003bfe <namex+0x58>
    iput(ip);
    80003ccc:	8552                	mv	a0,s4
    80003cce:	a0fff0ef          	jal	800036dc <iput>
    return 0;
    80003cd2:	4a01                	li	s4,0
    80003cd4:	b72d                	j	80003bfe <namex+0x58>

0000000080003cd6 <dirlink>:
{
    80003cd6:	7139                	addi	sp,sp,-64
    80003cd8:	fc06                	sd	ra,56(sp)
    80003cda:	f822                	sd	s0,48(sp)
    80003cdc:	f04a                	sd	s2,32(sp)
    80003cde:	ec4e                	sd	s3,24(sp)
    80003ce0:	e852                	sd	s4,16(sp)
    80003ce2:	0080                	addi	s0,sp,64
    80003ce4:	892a                	mv	s2,a0
    80003ce6:	8a2e                	mv	s4,a1
    80003ce8:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003cea:	4601                	li	a2,0
    80003cec:	e1fff0ef          	jal	80003b0a <dirlookup>
    80003cf0:	e535                	bnez	a0,80003d5c <dirlink+0x86>
    80003cf2:	f426                	sd	s1,40(sp)
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cf4:	04c92483          	lw	s1,76(s2)
    80003cf8:	c48d                	beqz	s1,80003d22 <dirlink+0x4c>
    80003cfa:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003cfc:	4741                	li	a4,16
    80003cfe:	86a6                	mv	a3,s1
    80003d00:	fc040613          	addi	a2,s0,-64
    80003d04:	4581                	li	a1,0
    80003d06:	854a                	mv	a0,s2
    80003d08:	be3ff0ef          	jal	800038ea <readi>
    80003d0c:	47c1                	li	a5,16
    80003d0e:	04f51b63          	bne	a0,a5,80003d64 <dirlink+0x8e>
    if(de.inum == 0)
    80003d12:	fc045783          	lhu	a5,-64(s0)
    80003d16:	c791                	beqz	a5,80003d22 <dirlink+0x4c>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d18:	24c1                	addiw	s1,s1,16
    80003d1a:	04c92783          	lw	a5,76(s2)
    80003d1e:	fcf4efe3          	bltu	s1,a5,80003cfc <dirlink+0x26>
  strncpy(de.name, name, DIRSIZ);
    80003d22:	4639                	li	a2,14
    80003d24:	85d2                	mv	a1,s4
    80003d26:	fc240513          	addi	a0,s0,-62
    80003d2a:	87afd0ef          	jal	80000da4 <strncpy>
  de.inum = inum;
    80003d2e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d32:	4741                	li	a4,16
    80003d34:	86a6                	mv	a3,s1
    80003d36:	fc040613          	addi	a2,s0,-64
    80003d3a:	4581                	li	a1,0
    80003d3c:	854a                	mv	a0,s2
    80003d3e:	ca9ff0ef          	jal	800039e6 <writei>
    80003d42:	1541                	addi	a0,a0,-16
    80003d44:	00a03533          	snez	a0,a0
    80003d48:	40a00533          	neg	a0,a0
    80003d4c:	74a2                	ld	s1,40(sp)
}
    80003d4e:	70e2                	ld	ra,56(sp)
    80003d50:	7442                	ld	s0,48(sp)
    80003d52:	7902                	ld	s2,32(sp)
    80003d54:	69e2                	ld	s3,24(sp)
    80003d56:	6a42                	ld	s4,16(sp)
    80003d58:	6121                	addi	sp,sp,64
    80003d5a:	8082                	ret
    iput(ip);
    80003d5c:	981ff0ef          	jal	800036dc <iput>
    return -1;
    80003d60:	557d                	li	a0,-1
    80003d62:	b7f5                	j	80003d4e <dirlink+0x78>
      panic("dirlink read");
    80003d64:	00004517          	auipc	a0,0x4
    80003d68:	86450513          	addi	a0,a0,-1948 # 800075c8 <etext+0x5c8>
    80003d6c:	a75fc0ef          	jal	800007e0 <panic>

0000000080003d70 <namei>:

struct inode*
namei(char *path)
{
    80003d70:	1101                	addi	sp,sp,-32
    80003d72:	ec06                	sd	ra,24(sp)
    80003d74:	e822                	sd	s0,16(sp)
    80003d76:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003d78:	fe040613          	addi	a2,s0,-32
    80003d7c:	4581                	li	a1,0
    80003d7e:	e29ff0ef          	jal	80003ba6 <namex>
}
    80003d82:	60e2                	ld	ra,24(sp)
    80003d84:	6442                	ld	s0,16(sp)
    80003d86:	6105                	addi	sp,sp,32
    80003d88:	8082                	ret

0000000080003d8a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003d8a:	1141                	addi	sp,sp,-16
    80003d8c:	e406                	sd	ra,8(sp)
    80003d8e:	e022                	sd	s0,0(sp)
    80003d90:	0800                	addi	s0,sp,16
    80003d92:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003d94:	4585                	li	a1,1
    80003d96:	e11ff0ef          	jal	80003ba6 <namex>
}
    80003d9a:	60a2                	ld	ra,8(sp)
    80003d9c:	6402                	ld	s0,0(sp)
    80003d9e:	0141                	addi	sp,sp,16
    80003da0:	8082                	ret

0000000080003da2 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003da2:	1101                	addi	sp,sp,-32
    80003da4:	ec06                	sd	ra,24(sp)
    80003da6:	e822                	sd	s0,16(sp)
    80003da8:	e426                	sd	s1,8(sp)
    80003daa:	e04a                	sd	s2,0(sp)
    80003dac:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003dae:	0001f917          	auipc	s2,0x1f
    80003db2:	56a90913          	addi	s2,s2,1386 # 80023318 <log>
    80003db6:	01892583          	lw	a1,24(s2)
    80003dba:	02492503          	lw	a0,36(s2)
    80003dbe:	8d0ff0ef          	jal	80002e8e <bread>
    80003dc2:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003dc4:	02892603          	lw	a2,40(s2)
    80003dc8:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003dca:	00c05f63          	blez	a2,80003de8 <write_head+0x46>
    80003dce:	0001f717          	auipc	a4,0x1f
    80003dd2:	57670713          	addi	a4,a4,1398 # 80023344 <log+0x2c>
    80003dd6:	87aa                	mv	a5,a0
    80003dd8:	060a                	slli	a2,a2,0x2
    80003dda:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    80003ddc:	4314                	lw	a3,0(a4)
    80003dde:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    80003de0:	0711                	addi	a4,a4,4
    80003de2:	0791                	addi	a5,a5,4
    80003de4:	fec79ce3          	bne	a5,a2,80003ddc <write_head+0x3a>
  }
  bwrite(buf);
    80003de8:	8526                	mv	a0,s1
    80003dea:	97aff0ef          	jal	80002f64 <bwrite>
  brelse(buf);
    80003dee:	8526                	mv	a0,s1
    80003df0:	9a6ff0ef          	jal	80002f96 <brelse>
}
    80003df4:	60e2                	ld	ra,24(sp)
    80003df6:	6442                	ld	s0,16(sp)
    80003df8:	64a2                	ld	s1,8(sp)
    80003dfa:	6902                	ld	s2,0(sp)
    80003dfc:	6105                	addi	sp,sp,32
    80003dfe:	8082                	ret

0000000080003e00 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003e00:	0001f797          	auipc	a5,0x1f
    80003e04:	5407a783          	lw	a5,1344(a5) # 80023340 <log+0x28>
    80003e08:	0af05e63          	blez	a5,80003ec4 <install_trans+0xc4>
{
    80003e0c:	715d                	addi	sp,sp,-80
    80003e0e:	e486                	sd	ra,72(sp)
    80003e10:	e0a2                	sd	s0,64(sp)
    80003e12:	fc26                	sd	s1,56(sp)
    80003e14:	f84a                	sd	s2,48(sp)
    80003e16:	f44e                	sd	s3,40(sp)
    80003e18:	f052                	sd	s4,32(sp)
    80003e1a:	ec56                	sd	s5,24(sp)
    80003e1c:	e85a                	sd	s6,16(sp)
    80003e1e:	e45e                	sd	s7,8(sp)
    80003e20:	0880                	addi	s0,sp,80
    80003e22:	8b2a                	mv	s6,a0
    80003e24:	0001fa97          	auipc	s5,0x1f
    80003e28:	520a8a93          	addi	s5,s5,1312 # 80023344 <log+0x2c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003e2c:	4981                	li	s3,0
      printf("recovering tail %d dst %d\n", tail, log.lh.block[tail]);
    80003e2e:	00003b97          	auipc	s7,0x3
    80003e32:	7aab8b93          	addi	s7,s7,1962 # 800075d8 <etext+0x5d8>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003e36:	0001fa17          	auipc	s4,0x1f
    80003e3a:	4e2a0a13          	addi	s4,s4,1250 # 80023318 <log>
    80003e3e:	a025                	j	80003e66 <install_trans+0x66>
      printf("recovering tail %d dst %d\n", tail, log.lh.block[tail]);
    80003e40:	000aa603          	lw	a2,0(s5)
    80003e44:	85ce                	mv	a1,s3
    80003e46:	855e                	mv	a0,s7
    80003e48:	eb2fc0ef          	jal	800004fa <printf>
    80003e4c:	a839                	j	80003e6a <install_trans+0x6a>
    brelse(lbuf);
    80003e4e:	854a                	mv	a0,s2
    80003e50:	946ff0ef          	jal	80002f96 <brelse>
    brelse(dbuf);
    80003e54:	8526                	mv	a0,s1
    80003e56:	940ff0ef          	jal	80002f96 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003e5a:	2985                	addiw	s3,s3,1
    80003e5c:	0a91                	addi	s5,s5,4
    80003e5e:	028a2783          	lw	a5,40(s4)
    80003e62:	04f9d663          	bge	s3,a5,80003eae <install_trans+0xae>
    if(recovering) {
    80003e66:	fc0b1de3          	bnez	s6,80003e40 <install_trans+0x40>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003e6a:	018a2583          	lw	a1,24(s4)
    80003e6e:	013585bb          	addw	a1,a1,s3
    80003e72:	2585                	addiw	a1,a1,1
    80003e74:	024a2503          	lw	a0,36(s4)
    80003e78:	816ff0ef          	jal	80002e8e <bread>
    80003e7c:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003e7e:	000aa583          	lw	a1,0(s5)
    80003e82:	024a2503          	lw	a0,36(s4)
    80003e86:	808ff0ef          	jal	80002e8e <bread>
    80003e8a:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003e8c:	40000613          	li	a2,1024
    80003e90:	05890593          	addi	a1,s2,88
    80003e94:	05850513          	addi	a0,a0,88
    80003e98:	e67fc0ef          	jal	80000cfe <memmove>
    bwrite(dbuf);  // write dst to disk
    80003e9c:	8526                	mv	a0,s1
    80003e9e:	8c6ff0ef          	jal	80002f64 <bwrite>
    if(recovering == 0)
    80003ea2:	fa0b16e3          	bnez	s6,80003e4e <install_trans+0x4e>
      bunpin(dbuf);
    80003ea6:	8526                	mv	a0,s1
    80003ea8:	9aaff0ef          	jal	80003052 <bunpin>
    80003eac:	b74d                	j	80003e4e <install_trans+0x4e>
}
    80003eae:	60a6                	ld	ra,72(sp)
    80003eb0:	6406                	ld	s0,64(sp)
    80003eb2:	74e2                	ld	s1,56(sp)
    80003eb4:	7942                	ld	s2,48(sp)
    80003eb6:	79a2                	ld	s3,40(sp)
    80003eb8:	7a02                	ld	s4,32(sp)
    80003eba:	6ae2                	ld	s5,24(sp)
    80003ebc:	6b42                	ld	s6,16(sp)
    80003ebe:	6ba2                	ld	s7,8(sp)
    80003ec0:	6161                	addi	sp,sp,80
    80003ec2:	8082                	ret
    80003ec4:	8082                	ret

0000000080003ec6 <initlog>:
{
    80003ec6:	7179                	addi	sp,sp,-48
    80003ec8:	f406                	sd	ra,40(sp)
    80003eca:	f022                	sd	s0,32(sp)
    80003ecc:	ec26                	sd	s1,24(sp)
    80003ece:	e84a                	sd	s2,16(sp)
    80003ed0:	e44e                	sd	s3,8(sp)
    80003ed2:	1800                	addi	s0,sp,48
    80003ed4:	892a                	mv	s2,a0
    80003ed6:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003ed8:	0001f497          	auipc	s1,0x1f
    80003edc:	44048493          	addi	s1,s1,1088 # 80023318 <log>
    80003ee0:	00003597          	auipc	a1,0x3
    80003ee4:	71858593          	addi	a1,a1,1816 # 800075f8 <etext+0x5f8>
    80003ee8:	8526                	mv	a0,s1
    80003eea:	c65fc0ef          	jal	80000b4e <initlock>
  log.start = sb->logstart;
    80003eee:	0149a583          	lw	a1,20(s3)
    80003ef2:	cc8c                	sw	a1,24(s1)
  log.dev = dev;
    80003ef4:	0324a223          	sw	s2,36(s1)
  struct buf *buf = bread(log.dev, log.start);
    80003ef8:	854a                	mv	a0,s2
    80003efa:	f95fe0ef          	jal	80002e8e <bread>
  log.lh.n = lh->n;
    80003efe:	4d30                	lw	a2,88(a0)
    80003f00:	d490                	sw	a2,40(s1)
  for (i = 0; i < log.lh.n; i++) {
    80003f02:	00c05f63          	blez	a2,80003f20 <initlog+0x5a>
    80003f06:	87aa                	mv	a5,a0
    80003f08:	0001f717          	auipc	a4,0x1f
    80003f0c:	43c70713          	addi	a4,a4,1084 # 80023344 <log+0x2c>
    80003f10:	060a                	slli	a2,a2,0x2
    80003f12:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    80003f14:	4ff4                	lw	a3,92(a5)
    80003f16:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003f18:	0791                	addi	a5,a5,4
    80003f1a:	0711                	addi	a4,a4,4
    80003f1c:	fec79ce3          	bne	a5,a2,80003f14 <initlog+0x4e>
  brelse(buf);
    80003f20:	876ff0ef          	jal	80002f96 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80003f24:	4505                	li	a0,1
    80003f26:	edbff0ef          	jal	80003e00 <install_trans>
  log.lh.n = 0;
    80003f2a:	0001f797          	auipc	a5,0x1f
    80003f2e:	4007ab23          	sw	zero,1046(a5) # 80023340 <log+0x28>
  write_head(); // clear the log
    80003f32:	e71ff0ef          	jal	80003da2 <write_head>
}
    80003f36:	70a2                	ld	ra,40(sp)
    80003f38:	7402                	ld	s0,32(sp)
    80003f3a:	64e2                	ld	s1,24(sp)
    80003f3c:	6942                	ld	s2,16(sp)
    80003f3e:	69a2                	ld	s3,8(sp)
    80003f40:	6145                	addi	sp,sp,48
    80003f42:	8082                	ret

0000000080003f44 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80003f44:	1101                	addi	sp,sp,-32
    80003f46:	ec06                	sd	ra,24(sp)
    80003f48:	e822                	sd	s0,16(sp)
    80003f4a:	e426                	sd	s1,8(sp)
    80003f4c:	e04a                	sd	s2,0(sp)
    80003f4e:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80003f50:	0001f517          	auipc	a0,0x1f
    80003f54:	3c850513          	addi	a0,a0,968 # 80023318 <log>
    80003f58:	c77fc0ef          	jal	80000bce <acquire>
  while(1){
    if(log.committing){
    80003f5c:	0001f497          	auipc	s1,0x1f
    80003f60:	3bc48493          	addi	s1,s1,956 # 80023318 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGBLOCKS){
    80003f64:	4979                	li	s2,30
    80003f66:	a029                	j	80003f70 <begin_op+0x2c>
      sleep(&log, &log.lock);
    80003f68:	85a6                	mv	a1,s1
    80003f6a:	8526                	mv	a0,s1
    80003f6c:	998fe0ef          	jal	80002104 <sleep>
    if(log.committing){
    80003f70:	509c                	lw	a5,32(s1)
    80003f72:	fbfd                	bnez	a5,80003f68 <begin_op+0x24>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGBLOCKS){
    80003f74:	4cd8                	lw	a4,28(s1)
    80003f76:	2705                	addiw	a4,a4,1
    80003f78:	0027179b          	slliw	a5,a4,0x2
    80003f7c:	9fb9                	addw	a5,a5,a4
    80003f7e:	0017979b          	slliw	a5,a5,0x1
    80003f82:	5494                	lw	a3,40(s1)
    80003f84:	9fb5                	addw	a5,a5,a3
    80003f86:	00f95763          	bge	s2,a5,80003f94 <begin_op+0x50>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80003f8a:	85a6                	mv	a1,s1
    80003f8c:	8526                	mv	a0,s1
    80003f8e:	976fe0ef          	jal	80002104 <sleep>
    80003f92:	bff9                	j	80003f70 <begin_op+0x2c>
    } else {
      log.outstanding += 1;
    80003f94:	0001f517          	auipc	a0,0x1f
    80003f98:	38450513          	addi	a0,a0,900 # 80023318 <log>
    80003f9c:	cd58                	sw	a4,28(a0)
      release(&log.lock);
    80003f9e:	cc9fc0ef          	jal	80000c66 <release>
      break;
    }
  }
}
    80003fa2:	60e2                	ld	ra,24(sp)
    80003fa4:	6442                	ld	s0,16(sp)
    80003fa6:	64a2                	ld	s1,8(sp)
    80003fa8:	6902                	ld	s2,0(sp)
    80003faa:	6105                	addi	sp,sp,32
    80003fac:	8082                	ret

0000000080003fae <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80003fae:	7139                	addi	sp,sp,-64
    80003fb0:	fc06                	sd	ra,56(sp)
    80003fb2:	f822                	sd	s0,48(sp)
    80003fb4:	f426                	sd	s1,40(sp)
    80003fb6:	f04a                	sd	s2,32(sp)
    80003fb8:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80003fba:	0001f497          	auipc	s1,0x1f
    80003fbe:	35e48493          	addi	s1,s1,862 # 80023318 <log>
    80003fc2:	8526                	mv	a0,s1
    80003fc4:	c0bfc0ef          	jal	80000bce <acquire>
  log.outstanding -= 1;
    80003fc8:	4cdc                	lw	a5,28(s1)
    80003fca:	37fd                	addiw	a5,a5,-1
    80003fcc:	0007891b          	sext.w	s2,a5
    80003fd0:	ccdc                	sw	a5,28(s1)
  if(log.committing)
    80003fd2:	509c                	lw	a5,32(s1)
    80003fd4:	ef9d                	bnez	a5,80004012 <end_op+0x64>
    panic("log.committing");
  if(log.outstanding == 0){
    80003fd6:	04091763          	bnez	s2,80004024 <end_op+0x76>
    do_commit = 1;
    log.committing = 1;
    80003fda:	0001f497          	auipc	s1,0x1f
    80003fde:	33e48493          	addi	s1,s1,830 # 80023318 <log>
    80003fe2:	4785                	li	a5,1
    80003fe4:	d09c                	sw	a5,32(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80003fe6:	8526                	mv	a0,s1
    80003fe8:	c7ffc0ef          	jal	80000c66 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80003fec:	549c                	lw	a5,40(s1)
    80003fee:	04f04b63          	bgtz	a5,80004044 <end_op+0x96>
    acquire(&log.lock);
    80003ff2:	0001f497          	auipc	s1,0x1f
    80003ff6:	32648493          	addi	s1,s1,806 # 80023318 <log>
    80003ffa:	8526                	mv	a0,s1
    80003ffc:	bd3fc0ef          	jal	80000bce <acquire>
    log.committing = 0;
    80004000:	0204a023          	sw	zero,32(s1)
    wakeup(&log);
    80004004:	8526                	mv	a0,s1
    80004006:	97afe0ef          	jal	80002180 <wakeup>
    release(&log.lock);
    8000400a:	8526                	mv	a0,s1
    8000400c:	c5bfc0ef          	jal	80000c66 <release>
}
    80004010:	a025                	j	80004038 <end_op+0x8a>
    80004012:	ec4e                	sd	s3,24(sp)
    80004014:	e852                	sd	s4,16(sp)
    80004016:	e456                	sd	s5,8(sp)
    panic("log.committing");
    80004018:	00003517          	auipc	a0,0x3
    8000401c:	5e850513          	addi	a0,a0,1512 # 80007600 <etext+0x600>
    80004020:	fc0fc0ef          	jal	800007e0 <panic>
    wakeup(&log);
    80004024:	0001f497          	auipc	s1,0x1f
    80004028:	2f448493          	addi	s1,s1,756 # 80023318 <log>
    8000402c:	8526                	mv	a0,s1
    8000402e:	952fe0ef          	jal	80002180 <wakeup>
  release(&log.lock);
    80004032:	8526                	mv	a0,s1
    80004034:	c33fc0ef          	jal	80000c66 <release>
}
    80004038:	70e2                	ld	ra,56(sp)
    8000403a:	7442                	ld	s0,48(sp)
    8000403c:	74a2                	ld	s1,40(sp)
    8000403e:	7902                	ld	s2,32(sp)
    80004040:	6121                	addi	sp,sp,64
    80004042:	8082                	ret
    80004044:	ec4e                	sd	s3,24(sp)
    80004046:	e852                	sd	s4,16(sp)
    80004048:	e456                	sd	s5,8(sp)
  for (tail = 0; tail < log.lh.n; tail++) {
    8000404a:	0001fa97          	auipc	s5,0x1f
    8000404e:	2faa8a93          	addi	s5,s5,762 # 80023344 <log+0x2c>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004052:	0001fa17          	auipc	s4,0x1f
    80004056:	2c6a0a13          	addi	s4,s4,710 # 80023318 <log>
    8000405a:	018a2583          	lw	a1,24(s4)
    8000405e:	012585bb          	addw	a1,a1,s2
    80004062:	2585                	addiw	a1,a1,1
    80004064:	024a2503          	lw	a0,36(s4)
    80004068:	e27fe0ef          	jal	80002e8e <bread>
    8000406c:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000406e:	000aa583          	lw	a1,0(s5)
    80004072:	024a2503          	lw	a0,36(s4)
    80004076:	e19fe0ef          	jal	80002e8e <bread>
    8000407a:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000407c:	40000613          	li	a2,1024
    80004080:	05850593          	addi	a1,a0,88
    80004084:	05848513          	addi	a0,s1,88
    80004088:	c77fc0ef          	jal	80000cfe <memmove>
    bwrite(to);  // write the log
    8000408c:	8526                	mv	a0,s1
    8000408e:	ed7fe0ef          	jal	80002f64 <bwrite>
    brelse(from);
    80004092:	854e                	mv	a0,s3
    80004094:	f03fe0ef          	jal	80002f96 <brelse>
    brelse(to);
    80004098:	8526                	mv	a0,s1
    8000409a:	efdfe0ef          	jal	80002f96 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000409e:	2905                	addiw	s2,s2,1
    800040a0:	0a91                	addi	s5,s5,4
    800040a2:	028a2783          	lw	a5,40(s4)
    800040a6:	faf94ae3          	blt	s2,a5,8000405a <end_op+0xac>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800040aa:	cf9ff0ef          	jal	80003da2 <write_head>
    install_trans(0); // Now install writes to home locations
    800040ae:	4501                	li	a0,0
    800040b0:	d51ff0ef          	jal	80003e00 <install_trans>
    log.lh.n = 0;
    800040b4:	0001f797          	auipc	a5,0x1f
    800040b8:	2807a623          	sw	zero,652(a5) # 80023340 <log+0x28>
    write_head();    // Erase the transaction from the log
    800040bc:	ce7ff0ef          	jal	80003da2 <write_head>
    800040c0:	69e2                	ld	s3,24(sp)
    800040c2:	6a42                	ld	s4,16(sp)
    800040c4:	6aa2                	ld	s5,8(sp)
    800040c6:	b735                	j	80003ff2 <end_op+0x44>

00000000800040c8 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800040c8:	1101                	addi	sp,sp,-32
    800040ca:	ec06                	sd	ra,24(sp)
    800040cc:	e822                	sd	s0,16(sp)
    800040ce:	e426                	sd	s1,8(sp)
    800040d0:	e04a                	sd	s2,0(sp)
    800040d2:	1000                	addi	s0,sp,32
    800040d4:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800040d6:	0001f917          	auipc	s2,0x1f
    800040da:	24290913          	addi	s2,s2,578 # 80023318 <log>
    800040de:	854a                	mv	a0,s2
    800040e0:	aeffc0ef          	jal	80000bce <acquire>
  if (log.lh.n >= LOGBLOCKS)
    800040e4:	02892603          	lw	a2,40(s2)
    800040e8:	47f5                	li	a5,29
    800040ea:	04c7cc63          	blt	a5,a2,80004142 <log_write+0x7a>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800040ee:	0001f797          	auipc	a5,0x1f
    800040f2:	2467a783          	lw	a5,582(a5) # 80023334 <log+0x1c>
    800040f6:	04f05c63          	blez	a5,8000414e <log_write+0x86>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800040fa:	4781                	li	a5,0
    800040fc:	04c05f63          	blez	a2,8000415a <log_write+0x92>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004100:	44cc                	lw	a1,12(s1)
    80004102:	0001f717          	auipc	a4,0x1f
    80004106:	24270713          	addi	a4,a4,578 # 80023344 <log+0x2c>
  for (i = 0; i < log.lh.n; i++) {
    8000410a:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000410c:	4314                	lw	a3,0(a4)
    8000410e:	04b68663          	beq	a3,a1,8000415a <log_write+0x92>
  for (i = 0; i < log.lh.n; i++) {
    80004112:	2785                	addiw	a5,a5,1
    80004114:	0711                	addi	a4,a4,4
    80004116:	fef61be3          	bne	a2,a5,8000410c <log_write+0x44>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000411a:	0621                	addi	a2,a2,8
    8000411c:	060a                	slli	a2,a2,0x2
    8000411e:	0001f797          	auipc	a5,0x1f
    80004122:	1fa78793          	addi	a5,a5,506 # 80023318 <log>
    80004126:	97b2                	add	a5,a5,a2
    80004128:	44d8                	lw	a4,12(s1)
    8000412a:	c7d8                	sw	a4,12(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000412c:	8526                	mv	a0,s1
    8000412e:	ef1fe0ef          	jal	8000301e <bpin>
    log.lh.n++;
    80004132:	0001f717          	auipc	a4,0x1f
    80004136:	1e670713          	addi	a4,a4,486 # 80023318 <log>
    8000413a:	571c                	lw	a5,40(a4)
    8000413c:	2785                	addiw	a5,a5,1
    8000413e:	d71c                	sw	a5,40(a4)
    80004140:	a80d                	j	80004172 <log_write+0xaa>
    panic("too big a transaction");
    80004142:	00003517          	auipc	a0,0x3
    80004146:	4ce50513          	addi	a0,a0,1230 # 80007610 <etext+0x610>
    8000414a:	e96fc0ef          	jal	800007e0 <panic>
    panic("log_write outside of trans");
    8000414e:	00003517          	auipc	a0,0x3
    80004152:	4da50513          	addi	a0,a0,1242 # 80007628 <etext+0x628>
    80004156:	e8afc0ef          	jal	800007e0 <panic>
  log.lh.block[i] = b->blockno;
    8000415a:	00878693          	addi	a3,a5,8
    8000415e:	068a                	slli	a3,a3,0x2
    80004160:	0001f717          	auipc	a4,0x1f
    80004164:	1b870713          	addi	a4,a4,440 # 80023318 <log>
    80004168:	9736                	add	a4,a4,a3
    8000416a:	44d4                	lw	a3,12(s1)
    8000416c:	c754                	sw	a3,12(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000416e:	faf60fe3          	beq	a2,a5,8000412c <log_write+0x64>
  }
  release(&log.lock);
    80004172:	0001f517          	auipc	a0,0x1f
    80004176:	1a650513          	addi	a0,a0,422 # 80023318 <log>
    8000417a:	aedfc0ef          	jal	80000c66 <release>
}
    8000417e:	60e2                	ld	ra,24(sp)
    80004180:	6442                	ld	s0,16(sp)
    80004182:	64a2                	ld	s1,8(sp)
    80004184:	6902                	ld	s2,0(sp)
    80004186:	6105                	addi	sp,sp,32
    80004188:	8082                	ret

000000008000418a <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000418a:	1101                	addi	sp,sp,-32
    8000418c:	ec06                	sd	ra,24(sp)
    8000418e:	e822                	sd	s0,16(sp)
    80004190:	e426                	sd	s1,8(sp)
    80004192:	e04a                	sd	s2,0(sp)
    80004194:	1000                	addi	s0,sp,32
    80004196:	84aa                	mv	s1,a0
    80004198:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000419a:	00003597          	auipc	a1,0x3
    8000419e:	4ae58593          	addi	a1,a1,1198 # 80007648 <etext+0x648>
    800041a2:	0521                	addi	a0,a0,8
    800041a4:	9abfc0ef          	jal	80000b4e <initlock>
  lk->name = name;
    800041a8:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800041ac:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800041b0:	0204a423          	sw	zero,40(s1)
}
    800041b4:	60e2                	ld	ra,24(sp)
    800041b6:	6442                	ld	s0,16(sp)
    800041b8:	64a2                	ld	s1,8(sp)
    800041ba:	6902                	ld	s2,0(sp)
    800041bc:	6105                	addi	sp,sp,32
    800041be:	8082                	ret

00000000800041c0 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800041c0:	1101                	addi	sp,sp,-32
    800041c2:	ec06                	sd	ra,24(sp)
    800041c4:	e822                	sd	s0,16(sp)
    800041c6:	e426                	sd	s1,8(sp)
    800041c8:	e04a                	sd	s2,0(sp)
    800041ca:	1000                	addi	s0,sp,32
    800041cc:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800041ce:	00850913          	addi	s2,a0,8
    800041d2:	854a                	mv	a0,s2
    800041d4:	9fbfc0ef          	jal	80000bce <acquire>
  while (lk->locked) {
    800041d8:	409c                	lw	a5,0(s1)
    800041da:	c799                	beqz	a5,800041e8 <acquiresleep+0x28>
    sleep(lk, &lk->lk);
    800041dc:	85ca                	mv	a1,s2
    800041de:	8526                	mv	a0,s1
    800041e0:	f25fd0ef          	jal	80002104 <sleep>
  while (lk->locked) {
    800041e4:	409c                	lw	a5,0(s1)
    800041e6:	fbfd                	bnez	a5,800041dc <acquiresleep+0x1c>
  }
  lk->locked = 1;
    800041e8:	4785                	li	a5,1
    800041ea:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800041ec:	f22fd0ef          	jal	8000190e <myproc>
    800041f0:	591c                	lw	a5,48(a0)
    800041f2:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800041f4:	854a                	mv	a0,s2
    800041f6:	a71fc0ef          	jal	80000c66 <release>
}
    800041fa:	60e2                	ld	ra,24(sp)
    800041fc:	6442                	ld	s0,16(sp)
    800041fe:	64a2                	ld	s1,8(sp)
    80004200:	6902                	ld	s2,0(sp)
    80004202:	6105                	addi	sp,sp,32
    80004204:	8082                	ret

0000000080004206 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004206:	1101                	addi	sp,sp,-32
    80004208:	ec06                	sd	ra,24(sp)
    8000420a:	e822                	sd	s0,16(sp)
    8000420c:	e426                	sd	s1,8(sp)
    8000420e:	e04a                	sd	s2,0(sp)
    80004210:	1000                	addi	s0,sp,32
    80004212:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004214:	00850913          	addi	s2,a0,8
    80004218:	854a                	mv	a0,s2
    8000421a:	9b5fc0ef          	jal	80000bce <acquire>
  lk->locked = 0;
    8000421e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004222:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004226:	8526                	mv	a0,s1
    80004228:	f59fd0ef          	jal	80002180 <wakeup>
  release(&lk->lk);
    8000422c:	854a                	mv	a0,s2
    8000422e:	a39fc0ef          	jal	80000c66 <release>
}
    80004232:	60e2                	ld	ra,24(sp)
    80004234:	6442                	ld	s0,16(sp)
    80004236:	64a2                	ld	s1,8(sp)
    80004238:	6902                	ld	s2,0(sp)
    8000423a:	6105                	addi	sp,sp,32
    8000423c:	8082                	ret

000000008000423e <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000423e:	7179                	addi	sp,sp,-48
    80004240:	f406                	sd	ra,40(sp)
    80004242:	f022                	sd	s0,32(sp)
    80004244:	ec26                	sd	s1,24(sp)
    80004246:	e84a                	sd	s2,16(sp)
    80004248:	1800                	addi	s0,sp,48
    8000424a:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000424c:	00850913          	addi	s2,a0,8
    80004250:	854a                	mv	a0,s2
    80004252:	97dfc0ef          	jal	80000bce <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004256:	409c                	lw	a5,0(s1)
    80004258:	ef81                	bnez	a5,80004270 <holdingsleep+0x32>
    8000425a:	4481                	li	s1,0
  release(&lk->lk);
    8000425c:	854a                	mv	a0,s2
    8000425e:	a09fc0ef          	jal	80000c66 <release>
  return r;
}
    80004262:	8526                	mv	a0,s1
    80004264:	70a2                	ld	ra,40(sp)
    80004266:	7402                	ld	s0,32(sp)
    80004268:	64e2                	ld	s1,24(sp)
    8000426a:	6942                	ld	s2,16(sp)
    8000426c:	6145                	addi	sp,sp,48
    8000426e:	8082                	ret
    80004270:	e44e                	sd	s3,8(sp)
  r = lk->locked && (lk->pid == myproc()->pid);
    80004272:	0284a983          	lw	s3,40(s1)
    80004276:	e98fd0ef          	jal	8000190e <myproc>
    8000427a:	5904                	lw	s1,48(a0)
    8000427c:	413484b3          	sub	s1,s1,s3
    80004280:	0014b493          	seqz	s1,s1
    80004284:	69a2                	ld	s3,8(sp)
    80004286:	bfd9                	j	8000425c <holdingsleep+0x1e>

0000000080004288 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004288:	1141                	addi	sp,sp,-16
    8000428a:	e406                	sd	ra,8(sp)
    8000428c:	e022                	sd	s0,0(sp)
    8000428e:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004290:	00003597          	auipc	a1,0x3
    80004294:	3c858593          	addi	a1,a1,968 # 80007658 <etext+0x658>
    80004298:	0001f517          	auipc	a0,0x1f
    8000429c:	1c850513          	addi	a0,a0,456 # 80023460 <ftable>
    800042a0:	8affc0ef          	jal	80000b4e <initlock>
}
    800042a4:	60a2                	ld	ra,8(sp)
    800042a6:	6402                	ld	s0,0(sp)
    800042a8:	0141                	addi	sp,sp,16
    800042aa:	8082                	ret

00000000800042ac <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800042ac:	1101                	addi	sp,sp,-32
    800042ae:	ec06                	sd	ra,24(sp)
    800042b0:	e822                	sd	s0,16(sp)
    800042b2:	e426                	sd	s1,8(sp)
    800042b4:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800042b6:	0001f517          	auipc	a0,0x1f
    800042ba:	1aa50513          	addi	a0,a0,426 # 80023460 <ftable>
    800042be:	911fc0ef          	jal	80000bce <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800042c2:	0001f497          	auipc	s1,0x1f
    800042c6:	1b648493          	addi	s1,s1,438 # 80023478 <ftable+0x18>
    800042ca:	00020717          	auipc	a4,0x20
    800042ce:	14e70713          	addi	a4,a4,334 # 80024418 <disk>
    if(f->ref == 0){
    800042d2:	40dc                	lw	a5,4(s1)
    800042d4:	cf89                	beqz	a5,800042ee <filealloc+0x42>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800042d6:	02848493          	addi	s1,s1,40
    800042da:	fee49ce3          	bne	s1,a4,800042d2 <filealloc+0x26>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800042de:	0001f517          	auipc	a0,0x1f
    800042e2:	18250513          	addi	a0,a0,386 # 80023460 <ftable>
    800042e6:	981fc0ef          	jal	80000c66 <release>
  return 0;
    800042ea:	4481                	li	s1,0
    800042ec:	a809                	j	800042fe <filealloc+0x52>
      f->ref = 1;
    800042ee:	4785                	li	a5,1
    800042f0:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800042f2:	0001f517          	auipc	a0,0x1f
    800042f6:	16e50513          	addi	a0,a0,366 # 80023460 <ftable>
    800042fa:	96dfc0ef          	jal	80000c66 <release>
}
    800042fe:	8526                	mv	a0,s1
    80004300:	60e2                	ld	ra,24(sp)
    80004302:	6442                	ld	s0,16(sp)
    80004304:	64a2                	ld	s1,8(sp)
    80004306:	6105                	addi	sp,sp,32
    80004308:	8082                	ret

000000008000430a <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000430a:	1101                	addi	sp,sp,-32
    8000430c:	ec06                	sd	ra,24(sp)
    8000430e:	e822                	sd	s0,16(sp)
    80004310:	e426                	sd	s1,8(sp)
    80004312:	1000                	addi	s0,sp,32
    80004314:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004316:	0001f517          	auipc	a0,0x1f
    8000431a:	14a50513          	addi	a0,a0,330 # 80023460 <ftable>
    8000431e:	8b1fc0ef          	jal	80000bce <acquire>
  if(f->ref < 1)
    80004322:	40dc                	lw	a5,4(s1)
    80004324:	02f05063          	blez	a5,80004344 <filedup+0x3a>
    panic("filedup");
  f->ref++;
    80004328:	2785                	addiw	a5,a5,1
    8000432a:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000432c:	0001f517          	auipc	a0,0x1f
    80004330:	13450513          	addi	a0,a0,308 # 80023460 <ftable>
    80004334:	933fc0ef          	jal	80000c66 <release>
  return f;
}
    80004338:	8526                	mv	a0,s1
    8000433a:	60e2                	ld	ra,24(sp)
    8000433c:	6442                	ld	s0,16(sp)
    8000433e:	64a2                	ld	s1,8(sp)
    80004340:	6105                	addi	sp,sp,32
    80004342:	8082                	ret
    panic("filedup");
    80004344:	00003517          	auipc	a0,0x3
    80004348:	31c50513          	addi	a0,a0,796 # 80007660 <etext+0x660>
    8000434c:	c94fc0ef          	jal	800007e0 <panic>

0000000080004350 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004350:	7139                	addi	sp,sp,-64
    80004352:	fc06                	sd	ra,56(sp)
    80004354:	f822                	sd	s0,48(sp)
    80004356:	f426                	sd	s1,40(sp)
    80004358:	0080                	addi	s0,sp,64
    8000435a:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000435c:	0001f517          	auipc	a0,0x1f
    80004360:	10450513          	addi	a0,a0,260 # 80023460 <ftable>
    80004364:	86bfc0ef          	jal	80000bce <acquire>
  if(f->ref < 1)
    80004368:	40dc                	lw	a5,4(s1)
    8000436a:	04f05a63          	blez	a5,800043be <fileclose+0x6e>
    panic("fileclose");
  if(--f->ref > 0){
    8000436e:	37fd                	addiw	a5,a5,-1
    80004370:	0007871b          	sext.w	a4,a5
    80004374:	c0dc                	sw	a5,4(s1)
    80004376:	04e04e63          	bgtz	a4,800043d2 <fileclose+0x82>
    8000437a:	f04a                	sd	s2,32(sp)
    8000437c:	ec4e                	sd	s3,24(sp)
    8000437e:	e852                	sd	s4,16(sp)
    80004380:	e456                	sd	s5,8(sp)
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004382:	0004a903          	lw	s2,0(s1)
    80004386:	0094ca83          	lbu	s5,9(s1)
    8000438a:	0104ba03          	ld	s4,16(s1)
    8000438e:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004392:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004396:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000439a:	0001f517          	auipc	a0,0x1f
    8000439e:	0c650513          	addi	a0,a0,198 # 80023460 <ftable>
    800043a2:	8c5fc0ef          	jal	80000c66 <release>

  if(ff.type == FD_PIPE){
    800043a6:	4785                	li	a5,1
    800043a8:	04f90063          	beq	s2,a5,800043e8 <fileclose+0x98>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800043ac:	3979                	addiw	s2,s2,-2
    800043ae:	4785                	li	a5,1
    800043b0:	0527f563          	bgeu	a5,s2,800043fa <fileclose+0xaa>
    800043b4:	7902                	ld	s2,32(sp)
    800043b6:	69e2                	ld	s3,24(sp)
    800043b8:	6a42                	ld	s4,16(sp)
    800043ba:	6aa2                	ld	s5,8(sp)
    800043bc:	a00d                	j	800043de <fileclose+0x8e>
    800043be:	f04a                	sd	s2,32(sp)
    800043c0:	ec4e                	sd	s3,24(sp)
    800043c2:	e852                	sd	s4,16(sp)
    800043c4:	e456                	sd	s5,8(sp)
    panic("fileclose");
    800043c6:	00003517          	auipc	a0,0x3
    800043ca:	2a250513          	addi	a0,a0,674 # 80007668 <etext+0x668>
    800043ce:	c12fc0ef          	jal	800007e0 <panic>
    release(&ftable.lock);
    800043d2:	0001f517          	auipc	a0,0x1f
    800043d6:	08e50513          	addi	a0,a0,142 # 80023460 <ftable>
    800043da:	88dfc0ef          	jal	80000c66 <release>
    begin_op();
    iput(ff.ip);
    end_op();
  }
}
    800043de:	70e2                	ld	ra,56(sp)
    800043e0:	7442                	ld	s0,48(sp)
    800043e2:	74a2                	ld	s1,40(sp)
    800043e4:	6121                	addi	sp,sp,64
    800043e6:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800043e8:	85d6                	mv	a1,s5
    800043ea:	8552                	mv	a0,s4
    800043ec:	336000ef          	jal	80004722 <pipeclose>
    800043f0:	7902                	ld	s2,32(sp)
    800043f2:	69e2                	ld	s3,24(sp)
    800043f4:	6a42                	ld	s4,16(sp)
    800043f6:	6aa2                	ld	s5,8(sp)
    800043f8:	b7dd                	j	800043de <fileclose+0x8e>
    begin_op();
    800043fa:	b4bff0ef          	jal	80003f44 <begin_op>
    iput(ff.ip);
    800043fe:	854e                	mv	a0,s3
    80004400:	adcff0ef          	jal	800036dc <iput>
    end_op();
    80004404:	babff0ef          	jal	80003fae <end_op>
    80004408:	7902                	ld	s2,32(sp)
    8000440a:	69e2                	ld	s3,24(sp)
    8000440c:	6a42                	ld	s4,16(sp)
    8000440e:	6aa2                	ld	s5,8(sp)
    80004410:	b7f9                	j	800043de <fileclose+0x8e>

0000000080004412 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004412:	715d                	addi	sp,sp,-80
    80004414:	e486                	sd	ra,72(sp)
    80004416:	e0a2                	sd	s0,64(sp)
    80004418:	fc26                	sd	s1,56(sp)
    8000441a:	f44e                	sd	s3,40(sp)
    8000441c:	0880                	addi	s0,sp,80
    8000441e:	84aa                	mv	s1,a0
    80004420:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004422:	cecfd0ef          	jal	8000190e <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004426:	409c                	lw	a5,0(s1)
    80004428:	37f9                	addiw	a5,a5,-2
    8000442a:	4705                	li	a4,1
    8000442c:	04f76063          	bltu	a4,a5,8000446c <filestat+0x5a>
    80004430:	f84a                	sd	s2,48(sp)
    80004432:	892a                	mv	s2,a0
    ilock(f->ip);
    80004434:	6c88                	ld	a0,24(s1)
    80004436:	924ff0ef          	jal	8000355a <ilock>
    stati(f->ip, &st);
    8000443a:	fb840593          	addi	a1,s0,-72
    8000443e:	6c88                	ld	a0,24(s1)
    80004440:	c80ff0ef          	jal	800038c0 <stati>
    iunlock(f->ip);
    80004444:	6c88                	ld	a0,24(s1)
    80004446:	9c2ff0ef          	jal	80003608 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000444a:	46e1                	li	a3,24
    8000444c:	fb840613          	addi	a2,s0,-72
    80004450:	85ce                	mv	a1,s3
    80004452:	05093503          	ld	a0,80(s2)
    80004456:	98cfd0ef          	jal	800015e2 <copyout>
    8000445a:	41f5551b          	sraiw	a0,a0,0x1f
    8000445e:	7942                	ld	s2,48(sp)
      return -1;
    return 0;
  }
  return -1;
}
    80004460:	60a6                	ld	ra,72(sp)
    80004462:	6406                	ld	s0,64(sp)
    80004464:	74e2                	ld	s1,56(sp)
    80004466:	79a2                	ld	s3,40(sp)
    80004468:	6161                	addi	sp,sp,80
    8000446a:	8082                	ret
  return -1;
    8000446c:	557d                	li	a0,-1
    8000446e:	bfcd                	j	80004460 <filestat+0x4e>

0000000080004470 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004470:	7179                	addi	sp,sp,-48
    80004472:	f406                	sd	ra,40(sp)
    80004474:	f022                	sd	s0,32(sp)
    80004476:	e84a                	sd	s2,16(sp)
    80004478:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000447a:	00854783          	lbu	a5,8(a0)
    8000447e:	cfd1                	beqz	a5,8000451a <fileread+0xaa>
    80004480:	ec26                	sd	s1,24(sp)
    80004482:	e44e                	sd	s3,8(sp)
    80004484:	84aa                	mv	s1,a0
    80004486:	89ae                	mv	s3,a1
    80004488:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000448a:	411c                	lw	a5,0(a0)
    8000448c:	4705                	li	a4,1
    8000448e:	04e78363          	beq	a5,a4,800044d4 <fileread+0x64>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004492:	470d                	li	a4,3
    80004494:	04e78763          	beq	a5,a4,800044e2 <fileread+0x72>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004498:	4709                	li	a4,2
    8000449a:	06e79a63          	bne	a5,a4,8000450e <fileread+0x9e>
    ilock(f->ip);
    8000449e:	6d08                	ld	a0,24(a0)
    800044a0:	8baff0ef          	jal	8000355a <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800044a4:	874a                	mv	a4,s2
    800044a6:	5094                	lw	a3,32(s1)
    800044a8:	864e                	mv	a2,s3
    800044aa:	4585                	li	a1,1
    800044ac:	6c88                	ld	a0,24(s1)
    800044ae:	c3cff0ef          	jal	800038ea <readi>
    800044b2:	892a                	mv	s2,a0
    800044b4:	00a05563          	blez	a0,800044be <fileread+0x4e>
      f->off += r;
    800044b8:	509c                	lw	a5,32(s1)
    800044ba:	9fa9                	addw	a5,a5,a0
    800044bc:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800044be:	6c88                	ld	a0,24(s1)
    800044c0:	948ff0ef          	jal	80003608 <iunlock>
    800044c4:	64e2                	ld	s1,24(sp)
    800044c6:	69a2                	ld	s3,8(sp)
  } else {
    panic("fileread");
  }

  return r;
}
    800044c8:	854a                	mv	a0,s2
    800044ca:	70a2                	ld	ra,40(sp)
    800044cc:	7402                	ld	s0,32(sp)
    800044ce:	6942                	ld	s2,16(sp)
    800044d0:	6145                	addi	sp,sp,48
    800044d2:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800044d4:	6908                	ld	a0,16(a0)
    800044d6:	388000ef          	jal	8000485e <piperead>
    800044da:	892a                	mv	s2,a0
    800044dc:	64e2                	ld	s1,24(sp)
    800044de:	69a2                	ld	s3,8(sp)
    800044e0:	b7e5                	j	800044c8 <fileread+0x58>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800044e2:	02451783          	lh	a5,36(a0)
    800044e6:	03079693          	slli	a3,a5,0x30
    800044ea:	92c1                	srli	a3,a3,0x30
    800044ec:	4725                	li	a4,9
    800044ee:	02d76863          	bltu	a4,a3,8000451e <fileread+0xae>
    800044f2:	0792                	slli	a5,a5,0x4
    800044f4:	0001f717          	auipc	a4,0x1f
    800044f8:	ecc70713          	addi	a4,a4,-308 # 800233c0 <devsw>
    800044fc:	97ba                	add	a5,a5,a4
    800044fe:	639c                	ld	a5,0(a5)
    80004500:	c39d                	beqz	a5,80004526 <fileread+0xb6>
    r = devsw[f->major].read(1, addr, n);
    80004502:	4505                	li	a0,1
    80004504:	9782                	jalr	a5
    80004506:	892a                	mv	s2,a0
    80004508:	64e2                	ld	s1,24(sp)
    8000450a:	69a2                	ld	s3,8(sp)
    8000450c:	bf75                	j	800044c8 <fileread+0x58>
    panic("fileread");
    8000450e:	00003517          	auipc	a0,0x3
    80004512:	16a50513          	addi	a0,a0,362 # 80007678 <etext+0x678>
    80004516:	acafc0ef          	jal	800007e0 <panic>
    return -1;
    8000451a:	597d                	li	s2,-1
    8000451c:	b775                	j	800044c8 <fileread+0x58>
      return -1;
    8000451e:	597d                	li	s2,-1
    80004520:	64e2                	ld	s1,24(sp)
    80004522:	69a2                	ld	s3,8(sp)
    80004524:	b755                	j	800044c8 <fileread+0x58>
    80004526:	597d                	li	s2,-1
    80004528:	64e2                	ld	s1,24(sp)
    8000452a:	69a2                	ld	s3,8(sp)
    8000452c:	bf71                	j	800044c8 <fileread+0x58>

000000008000452e <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    8000452e:	00954783          	lbu	a5,9(a0)
    80004532:	10078b63          	beqz	a5,80004648 <filewrite+0x11a>
{
    80004536:	715d                	addi	sp,sp,-80
    80004538:	e486                	sd	ra,72(sp)
    8000453a:	e0a2                	sd	s0,64(sp)
    8000453c:	f84a                	sd	s2,48(sp)
    8000453e:	f052                	sd	s4,32(sp)
    80004540:	e85a                	sd	s6,16(sp)
    80004542:	0880                	addi	s0,sp,80
    80004544:	892a                	mv	s2,a0
    80004546:	8b2e                	mv	s6,a1
    80004548:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000454a:	411c                	lw	a5,0(a0)
    8000454c:	4705                	li	a4,1
    8000454e:	02e78763          	beq	a5,a4,8000457c <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004552:	470d                	li	a4,3
    80004554:	02e78863          	beq	a5,a4,80004584 <filewrite+0x56>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004558:	4709                	li	a4,2
    8000455a:	0ce79c63          	bne	a5,a4,80004632 <filewrite+0x104>
    8000455e:	f44e                	sd	s3,40(sp)
    // the maximum log transaction size, including
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004560:	0ac05863          	blez	a2,80004610 <filewrite+0xe2>
    80004564:	fc26                	sd	s1,56(sp)
    80004566:	ec56                	sd	s5,24(sp)
    80004568:	e45e                	sd	s7,8(sp)
    8000456a:	e062                	sd	s8,0(sp)
    int i = 0;
    8000456c:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    8000456e:	6b85                	lui	s7,0x1
    80004570:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004574:	6c05                	lui	s8,0x1
    80004576:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    8000457a:	a8b5                	j	800045f6 <filewrite+0xc8>
    ret = pipewrite(f->pipe, addr, n);
    8000457c:	6908                	ld	a0,16(a0)
    8000457e:	1fc000ef          	jal	8000477a <pipewrite>
    80004582:	a04d                	j	80004624 <filewrite+0xf6>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004584:	02451783          	lh	a5,36(a0)
    80004588:	03079693          	slli	a3,a5,0x30
    8000458c:	92c1                	srli	a3,a3,0x30
    8000458e:	4725                	li	a4,9
    80004590:	0ad76e63          	bltu	a4,a3,8000464c <filewrite+0x11e>
    80004594:	0792                	slli	a5,a5,0x4
    80004596:	0001f717          	auipc	a4,0x1f
    8000459a:	e2a70713          	addi	a4,a4,-470 # 800233c0 <devsw>
    8000459e:	97ba                	add	a5,a5,a4
    800045a0:	679c                	ld	a5,8(a5)
    800045a2:	c7dd                	beqz	a5,80004650 <filewrite+0x122>
    ret = devsw[f->major].write(1, addr, n);
    800045a4:	4505                	li	a0,1
    800045a6:	9782                	jalr	a5
    800045a8:	a8b5                	j	80004624 <filewrite+0xf6>
      if(n1 > max)
    800045aa:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    800045ae:	997ff0ef          	jal	80003f44 <begin_op>
      ilock(f->ip);
    800045b2:	01893503          	ld	a0,24(s2)
    800045b6:	fa5fe0ef          	jal	8000355a <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800045ba:	8756                	mv	a4,s5
    800045bc:	02092683          	lw	a3,32(s2)
    800045c0:	01698633          	add	a2,s3,s6
    800045c4:	4585                	li	a1,1
    800045c6:	01893503          	ld	a0,24(s2)
    800045ca:	c1cff0ef          	jal	800039e6 <writei>
    800045ce:	84aa                	mv	s1,a0
    800045d0:	00a05763          	blez	a0,800045de <filewrite+0xb0>
        f->off += r;
    800045d4:	02092783          	lw	a5,32(s2)
    800045d8:	9fa9                	addw	a5,a5,a0
    800045da:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800045de:	01893503          	ld	a0,24(s2)
    800045e2:	826ff0ef          	jal	80003608 <iunlock>
      end_op();
    800045e6:	9c9ff0ef          	jal	80003fae <end_op>

      if(r != n1){
    800045ea:	029a9563          	bne	s5,s1,80004614 <filewrite+0xe6>
        // error from writei
        break;
      }
      i += r;
    800045ee:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800045f2:	0149da63          	bge	s3,s4,80004606 <filewrite+0xd8>
      int n1 = n - i;
    800045f6:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    800045fa:	0004879b          	sext.w	a5,s1
    800045fe:	fafbd6e3          	bge	s7,a5,800045aa <filewrite+0x7c>
    80004602:	84e2                	mv	s1,s8
    80004604:	b75d                	j	800045aa <filewrite+0x7c>
    80004606:	74e2                	ld	s1,56(sp)
    80004608:	6ae2                	ld	s5,24(sp)
    8000460a:	6ba2                	ld	s7,8(sp)
    8000460c:	6c02                	ld	s8,0(sp)
    8000460e:	a039                	j	8000461c <filewrite+0xee>
    int i = 0;
    80004610:	4981                	li	s3,0
    80004612:	a029                	j	8000461c <filewrite+0xee>
    80004614:	74e2                	ld	s1,56(sp)
    80004616:	6ae2                	ld	s5,24(sp)
    80004618:	6ba2                	ld	s7,8(sp)
    8000461a:	6c02                	ld	s8,0(sp)
    }
    ret = (i == n ? n : -1);
    8000461c:	033a1c63          	bne	s4,s3,80004654 <filewrite+0x126>
    80004620:	8552                	mv	a0,s4
    80004622:	79a2                	ld	s3,40(sp)
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004624:	60a6                	ld	ra,72(sp)
    80004626:	6406                	ld	s0,64(sp)
    80004628:	7942                	ld	s2,48(sp)
    8000462a:	7a02                	ld	s4,32(sp)
    8000462c:	6b42                	ld	s6,16(sp)
    8000462e:	6161                	addi	sp,sp,80
    80004630:	8082                	ret
    80004632:	fc26                	sd	s1,56(sp)
    80004634:	f44e                	sd	s3,40(sp)
    80004636:	ec56                	sd	s5,24(sp)
    80004638:	e45e                	sd	s7,8(sp)
    8000463a:	e062                	sd	s8,0(sp)
    panic("filewrite");
    8000463c:	00003517          	auipc	a0,0x3
    80004640:	04c50513          	addi	a0,a0,76 # 80007688 <etext+0x688>
    80004644:	99cfc0ef          	jal	800007e0 <panic>
    return -1;
    80004648:	557d                	li	a0,-1
}
    8000464a:	8082                	ret
      return -1;
    8000464c:	557d                	li	a0,-1
    8000464e:	bfd9                	j	80004624 <filewrite+0xf6>
    80004650:	557d                	li	a0,-1
    80004652:	bfc9                	j	80004624 <filewrite+0xf6>
    ret = (i == n ? n : -1);
    80004654:	557d                	li	a0,-1
    80004656:	79a2                	ld	s3,40(sp)
    80004658:	b7f1                	j	80004624 <filewrite+0xf6>

000000008000465a <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000465a:	7179                	addi	sp,sp,-48
    8000465c:	f406                	sd	ra,40(sp)
    8000465e:	f022                	sd	s0,32(sp)
    80004660:	ec26                	sd	s1,24(sp)
    80004662:	e052                	sd	s4,0(sp)
    80004664:	1800                	addi	s0,sp,48
    80004666:	84aa                	mv	s1,a0
    80004668:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000466a:	0005b023          	sd	zero,0(a1)
    8000466e:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004672:	c3bff0ef          	jal	800042ac <filealloc>
    80004676:	e088                	sd	a0,0(s1)
    80004678:	c549                	beqz	a0,80004702 <pipealloc+0xa8>
    8000467a:	c33ff0ef          	jal	800042ac <filealloc>
    8000467e:	00aa3023          	sd	a0,0(s4)
    80004682:	cd25                	beqz	a0,800046fa <pipealloc+0xa0>
    80004684:	e84a                	sd	s2,16(sp)
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004686:	c78fc0ef          	jal	80000afe <kalloc>
    8000468a:	892a                	mv	s2,a0
    8000468c:	c12d                	beqz	a0,800046ee <pipealloc+0x94>
    8000468e:	e44e                	sd	s3,8(sp)
    goto bad;
  pi->readopen = 1;
    80004690:	4985                	li	s3,1
    80004692:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004696:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000469a:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000469e:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800046a2:	00003597          	auipc	a1,0x3
    800046a6:	ff658593          	addi	a1,a1,-10 # 80007698 <etext+0x698>
    800046aa:	ca4fc0ef          	jal	80000b4e <initlock>
  (*f0)->type = FD_PIPE;
    800046ae:	609c                	ld	a5,0(s1)
    800046b0:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800046b4:	609c                	ld	a5,0(s1)
    800046b6:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800046ba:	609c                	ld	a5,0(s1)
    800046bc:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800046c0:	609c                	ld	a5,0(s1)
    800046c2:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800046c6:	000a3783          	ld	a5,0(s4)
    800046ca:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800046ce:	000a3783          	ld	a5,0(s4)
    800046d2:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800046d6:	000a3783          	ld	a5,0(s4)
    800046da:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800046de:	000a3783          	ld	a5,0(s4)
    800046e2:	0127b823          	sd	s2,16(a5)
  return 0;
    800046e6:	4501                	li	a0,0
    800046e8:	6942                	ld	s2,16(sp)
    800046ea:	69a2                	ld	s3,8(sp)
    800046ec:	a01d                	j	80004712 <pipealloc+0xb8>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800046ee:	6088                	ld	a0,0(s1)
    800046f0:	c119                	beqz	a0,800046f6 <pipealloc+0x9c>
    800046f2:	6942                	ld	s2,16(sp)
    800046f4:	a029                	j	800046fe <pipealloc+0xa4>
    800046f6:	6942                	ld	s2,16(sp)
    800046f8:	a029                	j	80004702 <pipealloc+0xa8>
    800046fa:	6088                	ld	a0,0(s1)
    800046fc:	c10d                	beqz	a0,8000471e <pipealloc+0xc4>
    fileclose(*f0);
    800046fe:	c53ff0ef          	jal	80004350 <fileclose>
  if(*f1)
    80004702:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004706:	557d                	li	a0,-1
  if(*f1)
    80004708:	c789                	beqz	a5,80004712 <pipealloc+0xb8>
    fileclose(*f1);
    8000470a:	853e                	mv	a0,a5
    8000470c:	c45ff0ef          	jal	80004350 <fileclose>
  return -1;
    80004710:	557d                	li	a0,-1
}
    80004712:	70a2                	ld	ra,40(sp)
    80004714:	7402                	ld	s0,32(sp)
    80004716:	64e2                	ld	s1,24(sp)
    80004718:	6a02                	ld	s4,0(sp)
    8000471a:	6145                	addi	sp,sp,48
    8000471c:	8082                	ret
  return -1;
    8000471e:	557d                	li	a0,-1
    80004720:	bfcd                	j	80004712 <pipealloc+0xb8>

0000000080004722 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004722:	1101                	addi	sp,sp,-32
    80004724:	ec06                	sd	ra,24(sp)
    80004726:	e822                	sd	s0,16(sp)
    80004728:	e426                	sd	s1,8(sp)
    8000472a:	e04a                	sd	s2,0(sp)
    8000472c:	1000                	addi	s0,sp,32
    8000472e:	84aa                	mv	s1,a0
    80004730:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004732:	c9cfc0ef          	jal	80000bce <acquire>
  if(writable){
    80004736:	02090763          	beqz	s2,80004764 <pipeclose+0x42>
    pi->writeopen = 0;
    8000473a:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    8000473e:	21848513          	addi	a0,s1,536
    80004742:	a3ffd0ef          	jal	80002180 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004746:	2204b783          	ld	a5,544(s1)
    8000474a:	e785                	bnez	a5,80004772 <pipeclose+0x50>
    release(&pi->lock);
    8000474c:	8526                	mv	a0,s1
    8000474e:	d18fc0ef          	jal	80000c66 <release>
    kfree((char*)pi);
    80004752:	8526                	mv	a0,s1
    80004754:	ac8fc0ef          	jal	80000a1c <kfree>
  } else
    release(&pi->lock);
}
    80004758:	60e2                	ld	ra,24(sp)
    8000475a:	6442                	ld	s0,16(sp)
    8000475c:	64a2                	ld	s1,8(sp)
    8000475e:	6902                	ld	s2,0(sp)
    80004760:	6105                	addi	sp,sp,32
    80004762:	8082                	ret
    pi->readopen = 0;
    80004764:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004768:	21c48513          	addi	a0,s1,540
    8000476c:	a15fd0ef          	jal	80002180 <wakeup>
    80004770:	bfd9                	j	80004746 <pipeclose+0x24>
    release(&pi->lock);
    80004772:	8526                	mv	a0,s1
    80004774:	cf2fc0ef          	jal	80000c66 <release>
}
    80004778:	b7c5                	j	80004758 <pipeclose+0x36>

000000008000477a <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    8000477a:	711d                	addi	sp,sp,-96
    8000477c:	ec86                	sd	ra,88(sp)
    8000477e:	e8a2                	sd	s0,80(sp)
    80004780:	e4a6                	sd	s1,72(sp)
    80004782:	e0ca                	sd	s2,64(sp)
    80004784:	fc4e                	sd	s3,56(sp)
    80004786:	f852                	sd	s4,48(sp)
    80004788:	f456                	sd	s5,40(sp)
    8000478a:	1080                	addi	s0,sp,96
    8000478c:	84aa                	mv	s1,a0
    8000478e:	8aae                	mv	s5,a1
    80004790:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004792:	97cfd0ef          	jal	8000190e <myproc>
    80004796:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004798:	8526                	mv	a0,s1
    8000479a:	c34fc0ef          	jal	80000bce <acquire>
  while(i < n){
    8000479e:	0b405a63          	blez	s4,80004852 <pipewrite+0xd8>
    800047a2:	f05a                	sd	s6,32(sp)
    800047a4:	ec5e                	sd	s7,24(sp)
    800047a6:	e862                	sd	s8,16(sp)
  int i = 0;
    800047a8:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800047aa:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800047ac:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800047b0:	21c48b93          	addi	s7,s1,540
    800047b4:	a81d                	j	800047ea <pipewrite+0x70>
      release(&pi->lock);
    800047b6:	8526                	mv	a0,s1
    800047b8:	caefc0ef          	jal	80000c66 <release>
      return -1;
    800047bc:	597d                	li	s2,-1
    800047be:	7b02                	ld	s6,32(sp)
    800047c0:	6be2                	ld	s7,24(sp)
    800047c2:	6c42                	ld	s8,16(sp)
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800047c4:	854a                	mv	a0,s2
    800047c6:	60e6                	ld	ra,88(sp)
    800047c8:	6446                	ld	s0,80(sp)
    800047ca:	64a6                	ld	s1,72(sp)
    800047cc:	6906                	ld	s2,64(sp)
    800047ce:	79e2                	ld	s3,56(sp)
    800047d0:	7a42                	ld	s4,48(sp)
    800047d2:	7aa2                	ld	s5,40(sp)
    800047d4:	6125                	addi	sp,sp,96
    800047d6:	8082                	ret
      wakeup(&pi->nread);
    800047d8:	8562                	mv	a0,s8
    800047da:	9a7fd0ef          	jal	80002180 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800047de:	85a6                	mv	a1,s1
    800047e0:	855e                	mv	a0,s7
    800047e2:	923fd0ef          	jal	80002104 <sleep>
  while(i < n){
    800047e6:	05495b63          	bge	s2,s4,8000483c <pipewrite+0xc2>
    if(pi->readopen == 0 || killed(pr)){
    800047ea:	2204a783          	lw	a5,544(s1)
    800047ee:	d7e1                	beqz	a5,800047b6 <pipewrite+0x3c>
    800047f0:	854e                	mv	a0,s3
    800047f2:	bd5fd0ef          	jal	800023c6 <killed>
    800047f6:	f161                	bnez	a0,800047b6 <pipewrite+0x3c>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800047f8:	2184a783          	lw	a5,536(s1)
    800047fc:	21c4a703          	lw	a4,540(s1)
    80004800:	2007879b          	addiw	a5,a5,512
    80004804:	fcf70ae3          	beq	a4,a5,800047d8 <pipewrite+0x5e>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004808:	4685                	li	a3,1
    8000480a:	01590633          	add	a2,s2,s5
    8000480e:	faf40593          	addi	a1,s0,-81
    80004812:	0509b503          	ld	a0,80(s3)
    80004816:	eb1fc0ef          	jal	800016c6 <copyin>
    8000481a:	03650e63          	beq	a0,s6,80004856 <pipewrite+0xdc>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    8000481e:	21c4a783          	lw	a5,540(s1)
    80004822:	0017871b          	addiw	a4,a5,1
    80004826:	20e4ae23          	sw	a4,540(s1)
    8000482a:	1ff7f793          	andi	a5,a5,511
    8000482e:	97a6                	add	a5,a5,s1
    80004830:	faf44703          	lbu	a4,-81(s0)
    80004834:	00e78c23          	sb	a4,24(a5)
      i++;
    80004838:	2905                	addiw	s2,s2,1
    8000483a:	b775                	j	800047e6 <pipewrite+0x6c>
    8000483c:	7b02                	ld	s6,32(sp)
    8000483e:	6be2                	ld	s7,24(sp)
    80004840:	6c42                	ld	s8,16(sp)
  wakeup(&pi->nread);
    80004842:	21848513          	addi	a0,s1,536
    80004846:	93bfd0ef          	jal	80002180 <wakeup>
  release(&pi->lock);
    8000484a:	8526                	mv	a0,s1
    8000484c:	c1afc0ef          	jal	80000c66 <release>
  return i;
    80004850:	bf95                	j	800047c4 <pipewrite+0x4a>
  int i = 0;
    80004852:	4901                	li	s2,0
    80004854:	b7fd                	j	80004842 <pipewrite+0xc8>
    80004856:	7b02                	ld	s6,32(sp)
    80004858:	6be2                	ld	s7,24(sp)
    8000485a:	6c42                	ld	s8,16(sp)
    8000485c:	b7dd                	j	80004842 <pipewrite+0xc8>

000000008000485e <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    8000485e:	715d                	addi	sp,sp,-80
    80004860:	e486                	sd	ra,72(sp)
    80004862:	e0a2                	sd	s0,64(sp)
    80004864:	fc26                	sd	s1,56(sp)
    80004866:	f84a                	sd	s2,48(sp)
    80004868:	f44e                	sd	s3,40(sp)
    8000486a:	f052                	sd	s4,32(sp)
    8000486c:	ec56                	sd	s5,24(sp)
    8000486e:	0880                	addi	s0,sp,80
    80004870:	84aa                	mv	s1,a0
    80004872:	892e                	mv	s2,a1
    80004874:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004876:	898fd0ef          	jal	8000190e <myproc>
    8000487a:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000487c:	8526                	mv	a0,s1
    8000487e:	b50fc0ef          	jal	80000bce <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004882:	2184a703          	lw	a4,536(s1)
    80004886:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000488a:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000488e:	02f71563          	bne	a4,a5,800048b8 <piperead+0x5a>
    80004892:	2244a783          	lw	a5,548(s1)
    80004896:	cb85                	beqz	a5,800048c6 <piperead+0x68>
    if(killed(pr)){
    80004898:	8552                	mv	a0,s4
    8000489a:	b2dfd0ef          	jal	800023c6 <killed>
    8000489e:	ed19                	bnez	a0,800048bc <piperead+0x5e>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800048a0:	85a6                	mv	a1,s1
    800048a2:	854e                	mv	a0,s3
    800048a4:	861fd0ef          	jal	80002104 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800048a8:	2184a703          	lw	a4,536(s1)
    800048ac:	21c4a783          	lw	a5,540(s1)
    800048b0:	fef701e3          	beq	a4,a5,80004892 <piperead+0x34>
    800048b4:	e85a                	sd	s6,16(sp)
    800048b6:	a809                	j	800048c8 <piperead+0x6a>
    800048b8:	e85a                	sd	s6,16(sp)
    800048ba:	a039                	j	800048c8 <piperead+0x6a>
      release(&pi->lock);
    800048bc:	8526                	mv	a0,s1
    800048be:	ba8fc0ef          	jal	80000c66 <release>
      return -1;
    800048c2:	59fd                	li	s3,-1
    800048c4:	a8b1                	j	80004920 <piperead+0xc2>
    800048c6:	e85a                	sd	s6,16(sp)
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800048c8:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800048ca:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800048cc:	05505263          	blez	s5,80004910 <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    800048d0:	2184a783          	lw	a5,536(s1)
    800048d4:	21c4a703          	lw	a4,540(s1)
    800048d8:	02f70c63          	beq	a4,a5,80004910 <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800048dc:	0017871b          	addiw	a4,a5,1
    800048e0:	20e4ac23          	sw	a4,536(s1)
    800048e4:	1ff7f793          	andi	a5,a5,511
    800048e8:	97a6                	add	a5,a5,s1
    800048ea:	0187c783          	lbu	a5,24(a5)
    800048ee:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800048f2:	4685                	li	a3,1
    800048f4:	fbf40613          	addi	a2,s0,-65
    800048f8:	85ca                	mv	a1,s2
    800048fa:	050a3503          	ld	a0,80(s4)
    800048fe:	ce5fc0ef          	jal	800015e2 <copyout>
    80004902:	01650763          	beq	a0,s6,80004910 <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004906:	2985                	addiw	s3,s3,1
    80004908:	0905                	addi	s2,s2,1
    8000490a:	fd3a93e3          	bne	s5,s3,800048d0 <piperead+0x72>
    8000490e:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004910:	21c48513          	addi	a0,s1,540
    80004914:	86dfd0ef          	jal	80002180 <wakeup>
  release(&pi->lock);
    80004918:	8526                	mv	a0,s1
    8000491a:	b4cfc0ef          	jal	80000c66 <release>
    8000491e:	6b42                	ld	s6,16(sp)
  return i;
}
    80004920:	854e                	mv	a0,s3
    80004922:	60a6                	ld	ra,72(sp)
    80004924:	6406                	ld	s0,64(sp)
    80004926:	74e2                	ld	s1,56(sp)
    80004928:	7942                	ld	s2,48(sp)
    8000492a:	79a2                	ld	s3,40(sp)
    8000492c:	7a02                	ld	s4,32(sp)
    8000492e:	6ae2                	ld	s5,24(sp)
    80004930:	6161                	addi	sp,sp,80
    80004932:	8082                	ret

0000000080004934 <flags2perm>:

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

// map ELF permissions to PTE permission bits.
int flags2perm(int flags)
{
    80004934:	1141                	addi	sp,sp,-16
    80004936:	e422                	sd	s0,8(sp)
    80004938:	0800                	addi	s0,sp,16
    8000493a:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    8000493c:	8905                	andi	a0,a0,1
    8000493e:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004940:	8b89                	andi	a5,a5,2
    80004942:	c399                	beqz	a5,80004948 <flags2perm+0x14>
      perm |= PTE_W;
    80004944:	00456513          	ori	a0,a0,4
    return perm;
}
    80004948:	6422                	ld	s0,8(sp)
    8000494a:	0141                	addi	sp,sp,16
    8000494c:	8082                	ret

000000008000494e <kexec>:
//
// the implementation of the exec() system call
//
int
kexec(char *path, char **argv)
{
    8000494e:	df010113          	addi	sp,sp,-528
    80004952:	20113423          	sd	ra,520(sp)
    80004956:	20813023          	sd	s0,512(sp)
    8000495a:	ffa6                	sd	s1,504(sp)
    8000495c:	fbca                	sd	s2,496(sp)
    8000495e:	0c00                	addi	s0,sp,528
    80004960:	892a                	mv	s2,a0
    80004962:	dea43c23          	sd	a0,-520(s0)
    80004966:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    8000496a:	fa5fc0ef          	jal	8000190e <myproc>
    8000496e:	84aa                	mv	s1,a0

  begin_op();
    80004970:	dd4ff0ef          	jal	80003f44 <begin_op>

  // Open the executable file.
  if((ip = namei(path)) == 0){
    80004974:	854a                	mv	a0,s2
    80004976:	bfaff0ef          	jal	80003d70 <namei>
    8000497a:	c931                	beqz	a0,800049ce <kexec+0x80>
    8000497c:	f3d2                	sd	s4,480(sp)
    8000497e:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004980:	bdbfe0ef          	jal	8000355a <ilock>

  // Read the ELF header.
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004984:	04000713          	li	a4,64
    80004988:	4681                	li	a3,0
    8000498a:	e5040613          	addi	a2,s0,-432
    8000498e:	4581                	li	a1,0
    80004990:	8552                	mv	a0,s4
    80004992:	f59fe0ef          	jal	800038ea <readi>
    80004996:	04000793          	li	a5,64
    8000499a:	00f51a63          	bne	a0,a5,800049ae <kexec+0x60>
    goto bad;

  // Is this really an ELF file?
  if(elf.magic != ELF_MAGIC)
    8000499e:	e5042703          	lw	a4,-432(s0)
    800049a2:	464c47b7          	lui	a5,0x464c4
    800049a6:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800049aa:	02f70663          	beq	a4,a5,800049d6 <kexec+0x88>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800049ae:	8552                	mv	a0,s4
    800049b0:	db5fe0ef          	jal	80003764 <iunlockput>
    end_op();
    800049b4:	dfaff0ef          	jal	80003fae <end_op>
  }
  return -1;
    800049b8:	557d                	li	a0,-1
    800049ba:	7a1e                	ld	s4,480(sp)
}
    800049bc:	20813083          	ld	ra,520(sp)
    800049c0:	20013403          	ld	s0,512(sp)
    800049c4:	74fe                	ld	s1,504(sp)
    800049c6:	795e                	ld	s2,496(sp)
    800049c8:	21010113          	addi	sp,sp,528
    800049cc:	8082                	ret
    end_op();
    800049ce:	de0ff0ef          	jal	80003fae <end_op>
    return -1;
    800049d2:	557d                	li	a0,-1
    800049d4:	b7e5                	j	800049bc <kexec+0x6e>
    800049d6:	ebda                	sd	s6,464(sp)
  if((pagetable = proc_pagetable(p)) == 0)
    800049d8:	8526                	mv	a0,s1
    800049da:	83afd0ef          	jal	80001a14 <proc_pagetable>
    800049de:	8b2a                	mv	s6,a0
    800049e0:	2c050b63          	beqz	a0,80004cb6 <kexec+0x368>
    800049e4:	f7ce                	sd	s3,488(sp)
    800049e6:	efd6                	sd	s5,472(sp)
    800049e8:	e7de                	sd	s7,456(sp)
    800049ea:	e3e2                	sd	s8,448(sp)
    800049ec:	ff66                	sd	s9,440(sp)
    800049ee:	fb6a                	sd	s10,432(sp)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800049f0:	e7042d03          	lw	s10,-400(s0)
    800049f4:	e8845783          	lhu	a5,-376(s0)
    800049f8:	12078963          	beqz	a5,80004b2a <kexec+0x1dc>
    800049fc:	f76e                	sd	s11,424(sp)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800049fe:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004a00:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    80004a02:	6c85                	lui	s9,0x1
    80004a04:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004a08:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    80004a0c:	6a85                	lui	s5,0x1
    80004a0e:	a085                	j	80004a6e <kexec+0x120>
      panic("loadseg: address should exist");
    80004a10:	00003517          	auipc	a0,0x3
    80004a14:	c9050513          	addi	a0,a0,-880 # 800076a0 <etext+0x6a0>
    80004a18:	dc9fb0ef          	jal	800007e0 <panic>
    if(sz - i < PGSIZE)
    80004a1c:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004a1e:	8726                	mv	a4,s1
    80004a20:	012c06bb          	addw	a3,s8,s2
    80004a24:	4581                	li	a1,0
    80004a26:	8552                	mv	a0,s4
    80004a28:	ec3fe0ef          	jal	800038ea <readi>
    80004a2c:	2501                	sext.w	a0,a0
    80004a2e:	24a49a63          	bne	s1,a0,80004c82 <kexec+0x334>
  for(i = 0; i < sz; i += PGSIZE){
    80004a32:	012a893b          	addw	s2,s5,s2
    80004a36:	03397363          	bgeu	s2,s3,80004a5c <kexec+0x10e>
    pa = walkaddr(pagetable, va + i);
    80004a3a:	02091593          	slli	a1,s2,0x20
    80004a3e:	9181                	srli	a1,a1,0x20
    80004a40:	95de                	add	a1,a1,s7
    80004a42:	855a                	mv	a0,s6
    80004a44:	d6cfc0ef          	jal	80000fb0 <walkaddr>
    80004a48:	862a                	mv	a2,a0
    if(pa == 0)
    80004a4a:	d179                	beqz	a0,80004a10 <kexec+0xc2>
    if(sz - i < PGSIZE)
    80004a4c:	412984bb          	subw	s1,s3,s2
    80004a50:	0004879b          	sext.w	a5,s1
    80004a54:	fcfcf4e3          	bgeu	s9,a5,80004a1c <kexec+0xce>
    80004a58:	84d6                	mv	s1,s5
    80004a5a:	b7c9                	j	80004a1c <kexec+0xce>
    sz = sz1;
    80004a5c:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004a60:	2d85                	addiw	s11,s11,1
    80004a62:	038d0d1b          	addiw	s10,s10,56
    80004a66:	e8845783          	lhu	a5,-376(s0)
    80004a6a:	08fdd063          	bge	s11,a5,80004aea <kexec+0x19c>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004a6e:	2d01                	sext.w	s10,s10
    80004a70:	03800713          	li	a4,56
    80004a74:	86ea                	mv	a3,s10
    80004a76:	e1840613          	addi	a2,s0,-488
    80004a7a:	4581                	li	a1,0
    80004a7c:	8552                	mv	a0,s4
    80004a7e:	e6dfe0ef          	jal	800038ea <readi>
    80004a82:	03800793          	li	a5,56
    80004a86:	1cf51663          	bne	a0,a5,80004c52 <kexec+0x304>
    if(ph.type != ELF_PROG_LOAD)
    80004a8a:	e1842783          	lw	a5,-488(s0)
    80004a8e:	4705                	li	a4,1
    80004a90:	fce798e3          	bne	a5,a4,80004a60 <kexec+0x112>
    if(ph.memsz < ph.filesz)
    80004a94:	e4043483          	ld	s1,-448(s0)
    80004a98:	e3843783          	ld	a5,-456(s0)
    80004a9c:	1af4ef63          	bltu	s1,a5,80004c5a <kexec+0x30c>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004aa0:	e2843783          	ld	a5,-472(s0)
    80004aa4:	94be                	add	s1,s1,a5
    80004aa6:	1af4ee63          	bltu	s1,a5,80004c62 <kexec+0x314>
    if(ph.vaddr % PGSIZE != 0)
    80004aaa:	df043703          	ld	a4,-528(s0)
    80004aae:	8ff9                	and	a5,a5,a4
    80004ab0:	1a079d63          	bnez	a5,80004c6a <kexec+0x31c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004ab4:	e1c42503          	lw	a0,-484(s0)
    80004ab8:	e7dff0ef          	jal	80004934 <flags2perm>
    80004abc:	86aa                	mv	a3,a0
    80004abe:	8626                	mv	a2,s1
    80004ac0:	85ca                	mv	a1,s2
    80004ac2:	855a                	mv	a0,s6
    80004ac4:	fc4fc0ef          	jal	80001288 <uvmalloc>
    80004ac8:	e0a43423          	sd	a0,-504(s0)
    80004acc:	1a050363          	beqz	a0,80004c72 <kexec+0x324>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004ad0:	e2843b83          	ld	s7,-472(s0)
    80004ad4:	e2042c03          	lw	s8,-480(s0)
    80004ad8:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004adc:	00098463          	beqz	s3,80004ae4 <kexec+0x196>
    80004ae0:	4901                	li	s2,0
    80004ae2:	bfa1                	j	80004a3a <kexec+0xec>
    sz = sz1;
    80004ae4:	e0843903          	ld	s2,-504(s0)
    80004ae8:	bfa5                	j	80004a60 <kexec+0x112>
    80004aea:	7dba                	ld	s11,424(sp)
  iunlockput(ip);
    80004aec:	8552                	mv	a0,s4
    80004aee:	c77fe0ef          	jal	80003764 <iunlockput>
  end_op();
    80004af2:	cbcff0ef          	jal	80003fae <end_op>
  p = myproc();
    80004af6:	e19fc0ef          	jal	8000190e <myproc>
    80004afa:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004afc:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80004b00:	6985                	lui	s3,0x1
    80004b02:	19fd                	addi	s3,s3,-1 # fff <_entry-0x7ffff001>
    80004b04:	99ca                	add	s3,s3,s2
    80004b06:	77fd                	lui	a5,0xfffff
    80004b08:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + (USERSTACK+1)*PGSIZE, PTE_W)) == 0)
    80004b0c:	4691                	li	a3,4
    80004b0e:	6609                	lui	a2,0x2
    80004b10:	964e                	add	a2,a2,s3
    80004b12:	85ce                	mv	a1,s3
    80004b14:	855a                	mv	a0,s6
    80004b16:	f72fc0ef          	jal	80001288 <uvmalloc>
    80004b1a:	892a                	mv	s2,a0
    80004b1c:	e0a43423          	sd	a0,-504(s0)
    80004b20:	e519                	bnez	a0,80004b2e <kexec+0x1e0>
  if(pagetable)
    80004b22:	e1343423          	sd	s3,-504(s0)
    80004b26:	4a01                	li	s4,0
    80004b28:	aab1                	j	80004c84 <kexec+0x336>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004b2a:	4901                	li	s2,0
    80004b2c:	b7c1                	j	80004aec <kexec+0x19e>
  uvmclear(pagetable, sz-(USERSTACK+1)*PGSIZE);
    80004b2e:	75f9                	lui	a1,0xffffe
    80004b30:	95aa                	add	a1,a1,a0
    80004b32:	855a                	mv	a0,s6
    80004b34:	92bfc0ef          	jal	8000145e <uvmclear>
  stackbase = sp - USERSTACK*PGSIZE;
    80004b38:	7bfd                	lui	s7,0xfffff
    80004b3a:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    80004b3c:	e0043783          	ld	a5,-512(s0)
    80004b40:	6388                	ld	a0,0(a5)
    80004b42:	cd39                	beqz	a0,80004ba0 <kexec+0x252>
    80004b44:	e9040993          	addi	s3,s0,-368
    80004b48:	f9040c13          	addi	s8,s0,-112
    80004b4c:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004b4e:	ac4fc0ef          	jal	80000e12 <strlen>
    80004b52:	0015079b          	addiw	a5,a0,1
    80004b56:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004b5a:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004b5e:	11796e63          	bltu	s2,s7,80004c7a <kexec+0x32c>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004b62:	e0043d03          	ld	s10,-512(s0)
    80004b66:	000d3a03          	ld	s4,0(s10)
    80004b6a:	8552                	mv	a0,s4
    80004b6c:	aa6fc0ef          	jal	80000e12 <strlen>
    80004b70:	0015069b          	addiw	a3,a0,1
    80004b74:	8652                	mv	a2,s4
    80004b76:	85ca                	mv	a1,s2
    80004b78:	855a                	mv	a0,s6
    80004b7a:	a69fc0ef          	jal	800015e2 <copyout>
    80004b7e:	10054063          	bltz	a0,80004c7e <kexec+0x330>
    ustack[argc] = sp;
    80004b82:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004b86:	0485                	addi	s1,s1,1
    80004b88:	008d0793          	addi	a5,s10,8
    80004b8c:	e0f43023          	sd	a5,-512(s0)
    80004b90:	008d3503          	ld	a0,8(s10)
    80004b94:	c909                	beqz	a0,80004ba6 <kexec+0x258>
    if(argc >= MAXARG)
    80004b96:	09a1                	addi	s3,s3,8
    80004b98:	fb899be3          	bne	s3,s8,80004b4e <kexec+0x200>
  ip = 0;
    80004b9c:	4a01                	li	s4,0
    80004b9e:	a0dd                	j	80004c84 <kexec+0x336>
  sp = sz;
    80004ba0:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    80004ba4:	4481                	li	s1,0
  ustack[argc] = 0;
    80004ba6:	00349793          	slli	a5,s1,0x3
    80004baa:	f9078793          	addi	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7ffdaa38>
    80004bae:	97a2                	add	a5,a5,s0
    80004bb0:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004bb4:	00148693          	addi	a3,s1,1
    80004bb8:	068e                	slli	a3,a3,0x3
    80004bba:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004bbe:	ff097913          	andi	s2,s2,-16
  sz = sz1;
    80004bc2:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    80004bc6:	f5796ee3          	bltu	s2,s7,80004b22 <kexec+0x1d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004bca:	e9040613          	addi	a2,s0,-368
    80004bce:	85ca                	mv	a1,s2
    80004bd0:	855a                	mv	a0,s6
    80004bd2:	a11fc0ef          	jal	800015e2 <copyout>
    80004bd6:	0e054263          	bltz	a0,80004cba <kexec+0x36c>
  p->trapframe->a1 = sp;
    80004bda:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    80004bde:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004be2:	df843783          	ld	a5,-520(s0)
    80004be6:	0007c703          	lbu	a4,0(a5)
    80004bea:	cf11                	beqz	a4,80004c06 <kexec+0x2b8>
    80004bec:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004bee:	02f00693          	li	a3,47
    80004bf2:	a039                	j	80004c00 <kexec+0x2b2>
      last = s+1;
    80004bf4:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004bf8:	0785                	addi	a5,a5,1
    80004bfa:	fff7c703          	lbu	a4,-1(a5)
    80004bfe:	c701                	beqz	a4,80004c06 <kexec+0x2b8>
    if(*s == '/')
    80004c00:	fed71ce3          	bne	a4,a3,80004bf8 <kexec+0x2aa>
    80004c04:	bfc5                	j	80004bf4 <kexec+0x2a6>
  safestrcpy(p->name, last, sizeof(p->name));
    80004c06:	4641                	li	a2,16
    80004c08:	df843583          	ld	a1,-520(s0)
    80004c0c:	158a8513          	addi	a0,s5,344
    80004c10:	9d0fc0ef          	jal	80000de0 <safestrcpy>
  oldpagetable = p->pagetable;
    80004c14:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004c18:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    80004c1c:	e0843783          	ld	a5,-504(s0)
    80004c20:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004c24:	058ab783          	ld	a5,88(s5)
    80004c28:	e6843703          	ld	a4,-408(s0)
    80004c2c:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004c2e:	058ab783          	ld	a5,88(s5)
    80004c32:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004c36:	85e6                	mv	a1,s9
    80004c38:	e61fc0ef          	jal	80001a98 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004c3c:	0004851b          	sext.w	a0,s1
    80004c40:	79be                	ld	s3,488(sp)
    80004c42:	7a1e                	ld	s4,480(sp)
    80004c44:	6afe                	ld	s5,472(sp)
    80004c46:	6b5e                	ld	s6,464(sp)
    80004c48:	6bbe                	ld	s7,456(sp)
    80004c4a:	6c1e                	ld	s8,448(sp)
    80004c4c:	7cfa                	ld	s9,440(sp)
    80004c4e:	7d5a                	ld	s10,432(sp)
    80004c50:	b3b5                	j	800049bc <kexec+0x6e>
    80004c52:	e1243423          	sd	s2,-504(s0)
    80004c56:	7dba                	ld	s11,424(sp)
    80004c58:	a035                	j	80004c84 <kexec+0x336>
    80004c5a:	e1243423          	sd	s2,-504(s0)
    80004c5e:	7dba                	ld	s11,424(sp)
    80004c60:	a015                	j	80004c84 <kexec+0x336>
    80004c62:	e1243423          	sd	s2,-504(s0)
    80004c66:	7dba                	ld	s11,424(sp)
    80004c68:	a831                	j	80004c84 <kexec+0x336>
    80004c6a:	e1243423          	sd	s2,-504(s0)
    80004c6e:	7dba                	ld	s11,424(sp)
    80004c70:	a811                	j	80004c84 <kexec+0x336>
    80004c72:	e1243423          	sd	s2,-504(s0)
    80004c76:	7dba                	ld	s11,424(sp)
    80004c78:	a031                	j	80004c84 <kexec+0x336>
  ip = 0;
    80004c7a:	4a01                	li	s4,0
    80004c7c:	a021                	j	80004c84 <kexec+0x336>
    80004c7e:	4a01                	li	s4,0
  if(pagetable)
    80004c80:	a011                	j	80004c84 <kexec+0x336>
    80004c82:	7dba                	ld	s11,424(sp)
    proc_freepagetable(pagetable, sz);
    80004c84:	e0843583          	ld	a1,-504(s0)
    80004c88:	855a                	mv	a0,s6
    80004c8a:	e0ffc0ef          	jal	80001a98 <proc_freepagetable>
  return -1;
    80004c8e:	557d                	li	a0,-1
  if(ip){
    80004c90:	000a1b63          	bnez	s4,80004ca6 <kexec+0x358>
    80004c94:	79be                	ld	s3,488(sp)
    80004c96:	7a1e                	ld	s4,480(sp)
    80004c98:	6afe                	ld	s5,472(sp)
    80004c9a:	6b5e                	ld	s6,464(sp)
    80004c9c:	6bbe                	ld	s7,456(sp)
    80004c9e:	6c1e                	ld	s8,448(sp)
    80004ca0:	7cfa                	ld	s9,440(sp)
    80004ca2:	7d5a                	ld	s10,432(sp)
    80004ca4:	bb21                	j	800049bc <kexec+0x6e>
    80004ca6:	79be                	ld	s3,488(sp)
    80004ca8:	6afe                	ld	s5,472(sp)
    80004caa:	6b5e                	ld	s6,464(sp)
    80004cac:	6bbe                	ld	s7,456(sp)
    80004cae:	6c1e                	ld	s8,448(sp)
    80004cb0:	7cfa                	ld	s9,440(sp)
    80004cb2:	7d5a                	ld	s10,432(sp)
    80004cb4:	b9ed                	j	800049ae <kexec+0x60>
    80004cb6:	6b5e                	ld	s6,464(sp)
    80004cb8:	b9dd                	j	800049ae <kexec+0x60>
  sz = sz1;
    80004cba:	e0843983          	ld	s3,-504(s0)
    80004cbe:	b595                	j	80004b22 <kexec+0x1d4>

0000000080004cc0 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004cc0:	7179                	addi	sp,sp,-48
    80004cc2:	f406                	sd	ra,40(sp)
    80004cc4:	f022                	sd	s0,32(sp)
    80004cc6:	ec26                	sd	s1,24(sp)
    80004cc8:	e84a                	sd	s2,16(sp)
    80004cca:	1800                	addi	s0,sp,48
    80004ccc:	892e                	mv	s2,a1
    80004cce:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80004cd0:	fdc40593          	addi	a1,s0,-36
    80004cd4:	e2ffd0ef          	jal	80002b02 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004cd8:	fdc42703          	lw	a4,-36(s0)
    80004cdc:	47bd                	li	a5,15
    80004cde:	02e7e963          	bltu	a5,a4,80004d10 <argfd+0x50>
    80004ce2:	c2dfc0ef          	jal	8000190e <myproc>
    80004ce6:	fdc42703          	lw	a4,-36(s0)
    80004cea:	01a70793          	addi	a5,a4,26
    80004cee:	078e                	slli	a5,a5,0x3
    80004cf0:	953e                	add	a0,a0,a5
    80004cf2:	611c                	ld	a5,0(a0)
    80004cf4:	c385                	beqz	a5,80004d14 <argfd+0x54>
    return -1;
  if(pfd)
    80004cf6:	00090463          	beqz	s2,80004cfe <argfd+0x3e>
    *pfd = fd;
    80004cfa:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004cfe:	4501                	li	a0,0
  if(pf)
    80004d00:	c091                	beqz	s1,80004d04 <argfd+0x44>
    *pf = f;
    80004d02:	e09c                	sd	a5,0(s1)
}
    80004d04:	70a2                	ld	ra,40(sp)
    80004d06:	7402                	ld	s0,32(sp)
    80004d08:	64e2                	ld	s1,24(sp)
    80004d0a:	6942                	ld	s2,16(sp)
    80004d0c:	6145                	addi	sp,sp,48
    80004d0e:	8082                	ret
    return -1;
    80004d10:	557d                	li	a0,-1
    80004d12:	bfcd                	j	80004d04 <argfd+0x44>
    80004d14:	557d                	li	a0,-1
    80004d16:	b7fd                	j	80004d04 <argfd+0x44>

0000000080004d18 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004d18:	1101                	addi	sp,sp,-32
    80004d1a:	ec06                	sd	ra,24(sp)
    80004d1c:	e822                	sd	s0,16(sp)
    80004d1e:	e426                	sd	s1,8(sp)
    80004d20:	1000                	addi	s0,sp,32
    80004d22:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004d24:	bebfc0ef          	jal	8000190e <myproc>
    80004d28:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004d2a:	0d050793          	addi	a5,a0,208
    80004d2e:	4501                	li	a0,0
    80004d30:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004d32:	6398                	ld	a4,0(a5)
    80004d34:	cb19                	beqz	a4,80004d4a <fdalloc+0x32>
  for(fd = 0; fd < NOFILE; fd++){
    80004d36:	2505                	addiw	a0,a0,1
    80004d38:	07a1                	addi	a5,a5,8
    80004d3a:	fed51ce3          	bne	a0,a3,80004d32 <fdalloc+0x1a>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80004d3e:	557d                	li	a0,-1
}
    80004d40:	60e2                	ld	ra,24(sp)
    80004d42:	6442                	ld	s0,16(sp)
    80004d44:	64a2                	ld	s1,8(sp)
    80004d46:	6105                	addi	sp,sp,32
    80004d48:	8082                	ret
      p->ofile[fd] = f;
    80004d4a:	01a50793          	addi	a5,a0,26
    80004d4e:	078e                	slli	a5,a5,0x3
    80004d50:	963e                	add	a2,a2,a5
    80004d52:	e204                	sd	s1,0(a2)
      return fd;
    80004d54:	b7f5                	j	80004d40 <fdalloc+0x28>

0000000080004d56 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80004d56:	715d                	addi	sp,sp,-80
    80004d58:	e486                	sd	ra,72(sp)
    80004d5a:	e0a2                	sd	s0,64(sp)
    80004d5c:	fc26                	sd	s1,56(sp)
    80004d5e:	f84a                	sd	s2,48(sp)
    80004d60:	f44e                	sd	s3,40(sp)
    80004d62:	ec56                	sd	s5,24(sp)
    80004d64:	e85a                	sd	s6,16(sp)
    80004d66:	0880                	addi	s0,sp,80
    80004d68:	8b2e                	mv	s6,a1
    80004d6a:	89b2                	mv	s3,a2
    80004d6c:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80004d6e:	fb040593          	addi	a1,s0,-80
    80004d72:	818ff0ef          	jal	80003d8a <nameiparent>
    80004d76:	84aa                	mv	s1,a0
    80004d78:	10050a63          	beqz	a0,80004e8c <create+0x136>
    return 0;

  ilock(dp);
    80004d7c:	fdefe0ef          	jal	8000355a <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80004d80:	4601                	li	a2,0
    80004d82:	fb040593          	addi	a1,s0,-80
    80004d86:	8526                	mv	a0,s1
    80004d88:	d83fe0ef          	jal	80003b0a <dirlookup>
    80004d8c:	8aaa                	mv	s5,a0
    80004d8e:	c129                	beqz	a0,80004dd0 <create+0x7a>
    iunlockput(dp);
    80004d90:	8526                	mv	a0,s1
    80004d92:	9d3fe0ef          	jal	80003764 <iunlockput>
    ilock(ip);
    80004d96:	8556                	mv	a0,s5
    80004d98:	fc2fe0ef          	jal	8000355a <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80004d9c:	4789                	li	a5,2
    80004d9e:	02fb1463          	bne	s6,a5,80004dc6 <create+0x70>
    80004da2:	044ad783          	lhu	a5,68(s5)
    80004da6:	37f9                	addiw	a5,a5,-2
    80004da8:	17c2                	slli	a5,a5,0x30
    80004daa:	93c1                	srli	a5,a5,0x30
    80004dac:	4705                	li	a4,1
    80004dae:	00f76c63          	bltu	a4,a5,80004dc6 <create+0x70>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80004db2:	8556                	mv	a0,s5
    80004db4:	60a6                	ld	ra,72(sp)
    80004db6:	6406                	ld	s0,64(sp)
    80004db8:	74e2                	ld	s1,56(sp)
    80004dba:	7942                	ld	s2,48(sp)
    80004dbc:	79a2                	ld	s3,40(sp)
    80004dbe:	6ae2                	ld	s5,24(sp)
    80004dc0:	6b42                	ld	s6,16(sp)
    80004dc2:	6161                	addi	sp,sp,80
    80004dc4:	8082                	ret
    iunlockput(ip);
    80004dc6:	8556                	mv	a0,s5
    80004dc8:	99dfe0ef          	jal	80003764 <iunlockput>
    return 0;
    80004dcc:	4a81                	li	s5,0
    80004dce:	b7d5                	j	80004db2 <create+0x5c>
    80004dd0:	f052                	sd	s4,32(sp)
  if((ip = ialloc(dp->dev, type)) == 0){
    80004dd2:	85da                	mv	a1,s6
    80004dd4:	4088                	lw	a0,0(s1)
    80004dd6:	e14fe0ef          	jal	800033ea <ialloc>
    80004dda:	8a2a                	mv	s4,a0
    80004ddc:	cd15                	beqz	a0,80004e18 <create+0xc2>
  ilock(ip);
    80004dde:	f7cfe0ef          	jal	8000355a <ilock>
  ip->major = major;
    80004de2:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80004de6:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80004dea:	4905                	li	s2,1
    80004dec:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80004df0:	8552                	mv	a0,s4
    80004df2:	eb4fe0ef          	jal	800034a6 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80004df6:	032b0763          	beq	s6,s2,80004e24 <create+0xce>
  if(dirlink(dp, name, ip->inum) < 0)
    80004dfa:	004a2603          	lw	a2,4(s4)
    80004dfe:	fb040593          	addi	a1,s0,-80
    80004e02:	8526                	mv	a0,s1
    80004e04:	ed3fe0ef          	jal	80003cd6 <dirlink>
    80004e08:	06054563          	bltz	a0,80004e72 <create+0x11c>
  iunlockput(dp);
    80004e0c:	8526                	mv	a0,s1
    80004e0e:	957fe0ef          	jal	80003764 <iunlockput>
  return ip;
    80004e12:	8ad2                	mv	s5,s4
    80004e14:	7a02                	ld	s4,32(sp)
    80004e16:	bf71                	j	80004db2 <create+0x5c>
    iunlockput(dp);
    80004e18:	8526                	mv	a0,s1
    80004e1a:	94bfe0ef          	jal	80003764 <iunlockput>
    return 0;
    80004e1e:	8ad2                	mv	s5,s4
    80004e20:	7a02                	ld	s4,32(sp)
    80004e22:	bf41                	j	80004db2 <create+0x5c>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80004e24:	004a2603          	lw	a2,4(s4)
    80004e28:	00003597          	auipc	a1,0x3
    80004e2c:	89858593          	addi	a1,a1,-1896 # 800076c0 <etext+0x6c0>
    80004e30:	8552                	mv	a0,s4
    80004e32:	ea5fe0ef          	jal	80003cd6 <dirlink>
    80004e36:	02054e63          	bltz	a0,80004e72 <create+0x11c>
    80004e3a:	40d0                	lw	a2,4(s1)
    80004e3c:	00003597          	auipc	a1,0x3
    80004e40:	88c58593          	addi	a1,a1,-1908 # 800076c8 <etext+0x6c8>
    80004e44:	8552                	mv	a0,s4
    80004e46:	e91fe0ef          	jal	80003cd6 <dirlink>
    80004e4a:	02054463          	bltz	a0,80004e72 <create+0x11c>
  if(dirlink(dp, name, ip->inum) < 0)
    80004e4e:	004a2603          	lw	a2,4(s4)
    80004e52:	fb040593          	addi	a1,s0,-80
    80004e56:	8526                	mv	a0,s1
    80004e58:	e7ffe0ef          	jal	80003cd6 <dirlink>
    80004e5c:	00054b63          	bltz	a0,80004e72 <create+0x11c>
    dp->nlink++;  // for ".."
    80004e60:	04a4d783          	lhu	a5,74(s1)
    80004e64:	2785                	addiw	a5,a5,1
    80004e66:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80004e6a:	8526                	mv	a0,s1
    80004e6c:	e3afe0ef          	jal	800034a6 <iupdate>
    80004e70:	bf71                	j	80004e0c <create+0xb6>
  ip->nlink = 0;
    80004e72:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80004e76:	8552                	mv	a0,s4
    80004e78:	e2efe0ef          	jal	800034a6 <iupdate>
  iunlockput(ip);
    80004e7c:	8552                	mv	a0,s4
    80004e7e:	8e7fe0ef          	jal	80003764 <iunlockput>
  iunlockput(dp);
    80004e82:	8526                	mv	a0,s1
    80004e84:	8e1fe0ef          	jal	80003764 <iunlockput>
  return 0;
    80004e88:	7a02                	ld	s4,32(sp)
    80004e8a:	b725                	j	80004db2 <create+0x5c>
    return 0;
    80004e8c:	8aaa                	mv	s5,a0
    80004e8e:	b715                	j	80004db2 <create+0x5c>

0000000080004e90 <sys_dup>:
{
    80004e90:	7179                	addi	sp,sp,-48
    80004e92:	f406                	sd	ra,40(sp)
    80004e94:	f022                	sd	s0,32(sp)
    80004e96:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80004e98:	fd840613          	addi	a2,s0,-40
    80004e9c:	4581                	li	a1,0
    80004e9e:	4501                	li	a0,0
    80004ea0:	e21ff0ef          	jal	80004cc0 <argfd>
    return -1;
    80004ea4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80004ea6:	02054363          	bltz	a0,80004ecc <sys_dup+0x3c>
    80004eaa:	ec26                	sd	s1,24(sp)
    80004eac:	e84a                	sd	s2,16(sp)
  if((fd=fdalloc(f)) < 0)
    80004eae:	fd843903          	ld	s2,-40(s0)
    80004eb2:	854a                	mv	a0,s2
    80004eb4:	e65ff0ef          	jal	80004d18 <fdalloc>
    80004eb8:	84aa                	mv	s1,a0
    return -1;
    80004eba:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80004ebc:	00054d63          	bltz	a0,80004ed6 <sys_dup+0x46>
  filedup(f);
    80004ec0:	854a                	mv	a0,s2
    80004ec2:	c48ff0ef          	jal	8000430a <filedup>
  return fd;
    80004ec6:	87a6                	mv	a5,s1
    80004ec8:	64e2                	ld	s1,24(sp)
    80004eca:	6942                	ld	s2,16(sp)
}
    80004ecc:	853e                	mv	a0,a5
    80004ece:	70a2                	ld	ra,40(sp)
    80004ed0:	7402                	ld	s0,32(sp)
    80004ed2:	6145                	addi	sp,sp,48
    80004ed4:	8082                	ret
    80004ed6:	64e2                	ld	s1,24(sp)
    80004ed8:	6942                	ld	s2,16(sp)
    80004eda:	bfcd                	j	80004ecc <sys_dup+0x3c>

0000000080004edc <sys_read>:
{
    80004edc:	7179                	addi	sp,sp,-48
    80004ede:	f406                	sd	ra,40(sp)
    80004ee0:	f022                	sd	s0,32(sp)
    80004ee2:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80004ee4:	fd840593          	addi	a1,s0,-40
    80004ee8:	4505                	li	a0,1
    80004eea:	c35fd0ef          	jal	80002b1e <argaddr>
  argint(2, &n);
    80004eee:	fe440593          	addi	a1,s0,-28
    80004ef2:	4509                	li	a0,2
    80004ef4:	c0ffd0ef          	jal	80002b02 <argint>
  if(argfd(0, 0, &f) < 0)
    80004ef8:	fe840613          	addi	a2,s0,-24
    80004efc:	4581                	li	a1,0
    80004efe:	4501                	li	a0,0
    80004f00:	dc1ff0ef          	jal	80004cc0 <argfd>
    return -1;
    80004f04:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80004f06:	02054363          	bltz	a0,80004f2c <sys_read+0x50>
  uint64 ret = fileread(f, p, n);
    80004f0a:	fe442603          	lw	a2,-28(s0)
    80004f0e:	fd843583          	ld	a1,-40(s0)
    80004f12:	fe843503          	ld	a0,-24(s0)
    80004f16:	d5aff0ef          	jal	80004470 <fileread>
    80004f1a:	87aa                	mv	a5,a0
  if(ret > 0)
    80004f1c:	c901                	beqz	a0,80004f2c <sys_read+0x50>
    read_bytes += ret;  // uint64 naturally wraps around on overflow
    80004f1e:	00005697          	auipc	a3,0x5
    80004f22:	4f268693          	addi	a3,a3,1266 # 8000a410 <read_bytes>
    80004f26:	6298                	ld	a4,0(a3)
    80004f28:	972a                	add	a4,a4,a0
    80004f2a:	e298                	sd	a4,0(a3)
}
    80004f2c:	853e                	mv	a0,a5
    80004f2e:	70a2                	ld	ra,40(sp)
    80004f30:	7402                	ld	s0,32(sp)
    80004f32:	6145                	addi	sp,sp,48
    80004f34:	8082                	ret

0000000080004f36 <sys_getreadcount>:
{
    80004f36:	1141                	addi	sp,sp,-16
    80004f38:	e422                	sd	s0,8(sp)
    80004f3a:	0800                	addi	s0,sp,16
}
    80004f3c:	00005517          	auipc	a0,0x5
    80004f40:	4d453503          	ld	a0,1236(a0) # 8000a410 <read_bytes>
    80004f44:	6422                	ld	s0,8(sp)
    80004f46:	0141                	addi	sp,sp,16
    80004f48:	8082                	ret

0000000080004f4a <sys_write>:
{
    80004f4a:	7179                	addi	sp,sp,-48
    80004f4c:	f406                	sd	ra,40(sp)
    80004f4e:	f022                	sd	s0,32(sp)
    80004f50:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80004f52:	fd840593          	addi	a1,s0,-40
    80004f56:	4505                	li	a0,1
    80004f58:	bc7fd0ef          	jal	80002b1e <argaddr>
  argint(2, &n);
    80004f5c:	fe440593          	addi	a1,s0,-28
    80004f60:	4509                	li	a0,2
    80004f62:	ba1fd0ef          	jal	80002b02 <argint>
  if(argfd(0, 0, &f) < 0)
    80004f66:	fe840613          	addi	a2,s0,-24
    80004f6a:	4581                	li	a1,0
    80004f6c:	4501                	li	a0,0
    80004f6e:	d53ff0ef          	jal	80004cc0 <argfd>
    80004f72:	87aa                	mv	a5,a0
    return -1;
    80004f74:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80004f76:	0007ca63          	bltz	a5,80004f8a <sys_write+0x40>
  return filewrite(f, p, n);
    80004f7a:	fe442603          	lw	a2,-28(s0)
    80004f7e:	fd843583          	ld	a1,-40(s0)
    80004f82:	fe843503          	ld	a0,-24(s0)
    80004f86:	da8ff0ef          	jal	8000452e <filewrite>
}
    80004f8a:	70a2                	ld	ra,40(sp)
    80004f8c:	7402                	ld	s0,32(sp)
    80004f8e:	6145                	addi	sp,sp,48
    80004f90:	8082                	ret

0000000080004f92 <sys_close>:
{
    80004f92:	1101                	addi	sp,sp,-32
    80004f94:	ec06                	sd	ra,24(sp)
    80004f96:	e822                	sd	s0,16(sp)
    80004f98:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80004f9a:	fe040613          	addi	a2,s0,-32
    80004f9e:	fec40593          	addi	a1,s0,-20
    80004fa2:	4501                	li	a0,0
    80004fa4:	d1dff0ef          	jal	80004cc0 <argfd>
    return -1;
    80004fa8:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80004faa:	02054063          	bltz	a0,80004fca <sys_close+0x38>
  myproc()->ofile[fd] = 0;
    80004fae:	961fc0ef          	jal	8000190e <myproc>
    80004fb2:	fec42783          	lw	a5,-20(s0)
    80004fb6:	07e9                	addi	a5,a5,26
    80004fb8:	078e                	slli	a5,a5,0x3
    80004fba:	953e                	add	a0,a0,a5
    80004fbc:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80004fc0:	fe043503          	ld	a0,-32(s0)
    80004fc4:	b8cff0ef          	jal	80004350 <fileclose>
  return 0;
    80004fc8:	4781                	li	a5,0
}
    80004fca:	853e                	mv	a0,a5
    80004fcc:	60e2                	ld	ra,24(sp)
    80004fce:	6442                	ld	s0,16(sp)
    80004fd0:	6105                	addi	sp,sp,32
    80004fd2:	8082                	ret

0000000080004fd4 <sys_fstat>:
{
    80004fd4:	1101                	addi	sp,sp,-32
    80004fd6:	ec06                	sd	ra,24(sp)
    80004fd8:	e822                	sd	s0,16(sp)
    80004fda:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80004fdc:	fe040593          	addi	a1,s0,-32
    80004fe0:	4505                	li	a0,1
    80004fe2:	b3dfd0ef          	jal	80002b1e <argaddr>
  if(argfd(0, 0, &f) < 0)
    80004fe6:	fe840613          	addi	a2,s0,-24
    80004fea:	4581                	li	a1,0
    80004fec:	4501                	li	a0,0
    80004fee:	cd3ff0ef          	jal	80004cc0 <argfd>
    80004ff2:	87aa                	mv	a5,a0
    return -1;
    80004ff4:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80004ff6:	0007c863          	bltz	a5,80005006 <sys_fstat+0x32>
  return filestat(f, st);
    80004ffa:	fe043583          	ld	a1,-32(s0)
    80004ffe:	fe843503          	ld	a0,-24(s0)
    80005002:	c10ff0ef          	jal	80004412 <filestat>
}
    80005006:	60e2                	ld	ra,24(sp)
    80005008:	6442                	ld	s0,16(sp)
    8000500a:	6105                	addi	sp,sp,32
    8000500c:	8082                	ret

000000008000500e <sys_link>:
{
    8000500e:	7169                	addi	sp,sp,-304
    80005010:	f606                	sd	ra,296(sp)
    80005012:	f222                	sd	s0,288(sp)
    80005014:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005016:	08000613          	li	a2,128
    8000501a:	ed040593          	addi	a1,s0,-304
    8000501e:	4501                	li	a0,0
    80005020:	b1bfd0ef          	jal	80002b3a <argstr>
    return -1;
    80005024:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005026:	0c054e63          	bltz	a0,80005102 <sys_link+0xf4>
    8000502a:	08000613          	li	a2,128
    8000502e:	f5040593          	addi	a1,s0,-176
    80005032:	4505                	li	a0,1
    80005034:	b07fd0ef          	jal	80002b3a <argstr>
    return -1;
    80005038:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000503a:	0c054463          	bltz	a0,80005102 <sys_link+0xf4>
    8000503e:	ee26                	sd	s1,280(sp)
  begin_op();
    80005040:	f05fe0ef          	jal	80003f44 <begin_op>
  if((ip = namei(old)) == 0){
    80005044:	ed040513          	addi	a0,s0,-304
    80005048:	d29fe0ef          	jal	80003d70 <namei>
    8000504c:	84aa                	mv	s1,a0
    8000504e:	c53d                	beqz	a0,800050bc <sys_link+0xae>
  ilock(ip);
    80005050:	d0afe0ef          	jal	8000355a <ilock>
  if(ip->type == T_DIR){
    80005054:	04449703          	lh	a4,68(s1)
    80005058:	4785                	li	a5,1
    8000505a:	06f70663          	beq	a4,a5,800050c6 <sys_link+0xb8>
    8000505e:	ea4a                	sd	s2,272(sp)
  ip->nlink++;
    80005060:	04a4d783          	lhu	a5,74(s1)
    80005064:	2785                	addiw	a5,a5,1
    80005066:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000506a:	8526                	mv	a0,s1
    8000506c:	c3afe0ef          	jal	800034a6 <iupdate>
  iunlock(ip);
    80005070:	8526                	mv	a0,s1
    80005072:	d96fe0ef          	jal	80003608 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005076:	fd040593          	addi	a1,s0,-48
    8000507a:	f5040513          	addi	a0,s0,-176
    8000507e:	d0dfe0ef          	jal	80003d8a <nameiparent>
    80005082:	892a                	mv	s2,a0
    80005084:	cd21                	beqz	a0,800050dc <sys_link+0xce>
  ilock(dp);
    80005086:	cd4fe0ef          	jal	8000355a <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000508a:	00092703          	lw	a4,0(s2)
    8000508e:	409c                	lw	a5,0(s1)
    80005090:	04f71363          	bne	a4,a5,800050d6 <sys_link+0xc8>
    80005094:	40d0                	lw	a2,4(s1)
    80005096:	fd040593          	addi	a1,s0,-48
    8000509a:	854a                	mv	a0,s2
    8000509c:	c3bfe0ef          	jal	80003cd6 <dirlink>
    800050a0:	02054b63          	bltz	a0,800050d6 <sys_link+0xc8>
  iunlockput(dp);
    800050a4:	854a                	mv	a0,s2
    800050a6:	ebefe0ef          	jal	80003764 <iunlockput>
  iput(ip);
    800050aa:	8526                	mv	a0,s1
    800050ac:	e30fe0ef          	jal	800036dc <iput>
  end_op();
    800050b0:	efffe0ef          	jal	80003fae <end_op>
  return 0;
    800050b4:	4781                	li	a5,0
    800050b6:	64f2                	ld	s1,280(sp)
    800050b8:	6952                	ld	s2,272(sp)
    800050ba:	a0a1                	j	80005102 <sys_link+0xf4>
    end_op();
    800050bc:	ef3fe0ef          	jal	80003fae <end_op>
    return -1;
    800050c0:	57fd                	li	a5,-1
    800050c2:	64f2                	ld	s1,280(sp)
    800050c4:	a83d                	j	80005102 <sys_link+0xf4>
    iunlockput(ip);
    800050c6:	8526                	mv	a0,s1
    800050c8:	e9cfe0ef          	jal	80003764 <iunlockput>
    end_op();
    800050cc:	ee3fe0ef          	jal	80003fae <end_op>
    return -1;
    800050d0:	57fd                	li	a5,-1
    800050d2:	64f2                	ld	s1,280(sp)
    800050d4:	a03d                	j	80005102 <sys_link+0xf4>
    iunlockput(dp);
    800050d6:	854a                	mv	a0,s2
    800050d8:	e8cfe0ef          	jal	80003764 <iunlockput>
  ilock(ip);
    800050dc:	8526                	mv	a0,s1
    800050de:	c7cfe0ef          	jal	8000355a <ilock>
  ip->nlink--;
    800050e2:	04a4d783          	lhu	a5,74(s1)
    800050e6:	37fd                	addiw	a5,a5,-1
    800050e8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800050ec:	8526                	mv	a0,s1
    800050ee:	bb8fe0ef          	jal	800034a6 <iupdate>
  iunlockput(ip);
    800050f2:	8526                	mv	a0,s1
    800050f4:	e70fe0ef          	jal	80003764 <iunlockput>
  end_op();
    800050f8:	eb7fe0ef          	jal	80003fae <end_op>
  return -1;
    800050fc:	57fd                	li	a5,-1
    800050fe:	64f2                	ld	s1,280(sp)
    80005100:	6952                	ld	s2,272(sp)
}
    80005102:	853e                	mv	a0,a5
    80005104:	70b2                	ld	ra,296(sp)
    80005106:	7412                	ld	s0,288(sp)
    80005108:	6155                	addi	sp,sp,304
    8000510a:	8082                	ret

000000008000510c <sys_unlink>:
{
    8000510c:	7151                	addi	sp,sp,-240
    8000510e:	f586                	sd	ra,232(sp)
    80005110:	f1a2                	sd	s0,224(sp)
    80005112:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005114:	08000613          	li	a2,128
    80005118:	f3040593          	addi	a1,s0,-208
    8000511c:	4501                	li	a0,0
    8000511e:	a1dfd0ef          	jal	80002b3a <argstr>
    80005122:	16054063          	bltz	a0,80005282 <sys_unlink+0x176>
    80005126:	eda6                	sd	s1,216(sp)
  begin_op();
    80005128:	e1dfe0ef          	jal	80003f44 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000512c:	fb040593          	addi	a1,s0,-80
    80005130:	f3040513          	addi	a0,s0,-208
    80005134:	c57fe0ef          	jal	80003d8a <nameiparent>
    80005138:	84aa                	mv	s1,a0
    8000513a:	c945                	beqz	a0,800051ea <sys_unlink+0xde>
  ilock(dp);
    8000513c:	c1efe0ef          	jal	8000355a <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005140:	00002597          	auipc	a1,0x2
    80005144:	58058593          	addi	a1,a1,1408 # 800076c0 <etext+0x6c0>
    80005148:	fb040513          	addi	a0,s0,-80
    8000514c:	9a9fe0ef          	jal	80003af4 <namecmp>
    80005150:	10050e63          	beqz	a0,8000526c <sys_unlink+0x160>
    80005154:	00002597          	auipc	a1,0x2
    80005158:	57458593          	addi	a1,a1,1396 # 800076c8 <etext+0x6c8>
    8000515c:	fb040513          	addi	a0,s0,-80
    80005160:	995fe0ef          	jal	80003af4 <namecmp>
    80005164:	10050463          	beqz	a0,8000526c <sys_unlink+0x160>
    80005168:	e9ca                	sd	s2,208(sp)
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000516a:	f2c40613          	addi	a2,s0,-212
    8000516e:	fb040593          	addi	a1,s0,-80
    80005172:	8526                	mv	a0,s1
    80005174:	997fe0ef          	jal	80003b0a <dirlookup>
    80005178:	892a                	mv	s2,a0
    8000517a:	0e050863          	beqz	a0,8000526a <sys_unlink+0x15e>
  ilock(ip);
    8000517e:	bdcfe0ef          	jal	8000355a <ilock>
  if(ip->nlink < 1)
    80005182:	04a91783          	lh	a5,74(s2)
    80005186:	06f05763          	blez	a5,800051f4 <sys_unlink+0xe8>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000518a:	04491703          	lh	a4,68(s2)
    8000518e:	4785                	li	a5,1
    80005190:	06f70963          	beq	a4,a5,80005202 <sys_unlink+0xf6>
  memset(&de, 0, sizeof(de));
    80005194:	4641                	li	a2,16
    80005196:	4581                	li	a1,0
    80005198:	fc040513          	addi	a0,s0,-64
    8000519c:	b07fb0ef          	jal	80000ca2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800051a0:	4741                	li	a4,16
    800051a2:	f2c42683          	lw	a3,-212(s0)
    800051a6:	fc040613          	addi	a2,s0,-64
    800051aa:	4581                	li	a1,0
    800051ac:	8526                	mv	a0,s1
    800051ae:	839fe0ef          	jal	800039e6 <writei>
    800051b2:	47c1                	li	a5,16
    800051b4:	08f51b63          	bne	a0,a5,8000524a <sys_unlink+0x13e>
  if(ip->type == T_DIR){
    800051b8:	04491703          	lh	a4,68(s2)
    800051bc:	4785                	li	a5,1
    800051be:	08f70d63          	beq	a4,a5,80005258 <sys_unlink+0x14c>
  iunlockput(dp);
    800051c2:	8526                	mv	a0,s1
    800051c4:	da0fe0ef          	jal	80003764 <iunlockput>
  ip->nlink--;
    800051c8:	04a95783          	lhu	a5,74(s2)
    800051cc:	37fd                	addiw	a5,a5,-1
    800051ce:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800051d2:	854a                	mv	a0,s2
    800051d4:	ad2fe0ef          	jal	800034a6 <iupdate>
  iunlockput(ip);
    800051d8:	854a                	mv	a0,s2
    800051da:	d8afe0ef          	jal	80003764 <iunlockput>
  end_op();
    800051de:	dd1fe0ef          	jal	80003fae <end_op>
  return 0;
    800051e2:	4501                	li	a0,0
    800051e4:	64ee                	ld	s1,216(sp)
    800051e6:	694e                	ld	s2,208(sp)
    800051e8:	a849                	j	8000527a <sys_unlink+0x16e>
    end_op();
    800051ea:	dc5fe0ef          	jal	80003fae <end_op>
    return -1;
    800051ee:	557d                	li	a0,-1
    800051f0:	64ee                	ld	s1,216(sp)
    800051f2:	a061                	j	8000527a <sys_unlink+0x16e>
    800051f4:	e5ce                	sd	s3,200(sp)
    panic("unlink: nlink < 1");
    800051f6:	00002517          	auipc	a0,0x2
    800051fa:	4da50513          	addi	a0,a0,1242 # 800076d0 <etext+0x6d0>
    800051fe:	de2fb0ef          	jal	800007e0 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005202:	04c92703          	lw	a4,76(s2)
    80005206:	02000793          	li	a5,32
    8000520a:	f8e7f5e3          	bgeu	a5,a4,80005194 <sys_unlink+0x88>
    8000520e:	e5ce                	sd	s3,200(sp)
    80005210:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005214:	4741                	li	a4,16
    80005216:	86ce                	mv	a3,s3
    80005218:	f1840613          	addi	a2,s0,-232
    8000521c:	4581                	li	a1,0
    8000521e:	854a                	mv	a0,s2
    80005220:	ecafe0ef          	jal	800038ea <readi>
    80005224:	47c1                	li	a5,16
    80005226:	00f51c63          	bne	a0,a5,8000523e <sys_unlink+0x132>
    if(de.inum != 0)
    8000522a:	f1845783          	lhu	a5,-232(s0)
    8000522e:	efa1                	bnez	a5,80005286 <sys_unlink+0x17a>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005230:	29c1                	addiw	s3,s3,16
    80005232:	04c92783          	lw	a5,76(s2)
    80005236:	fcf9efe3          	bltu	s3,a5,80005214 <sys_unlink+0x108>
    8000523a:	69ae                	ld	s3,200(sp)
    8000523c:	bfa1                	j	80005194 <sys_unlink+0x88>
      panic("isdirempty: readi");
    8000523e:	00002517          	auipc	a0,0x2
    80005242:	4aa50513          	addi	a0,a0,1194 # 800076e8 <etext+0x6e8>
    80005246:	d9afb0ef          	jal	800007e0 <panic>
    8000524a:	e5ce                	sd	s3,200(sp)
    panic("unlink: writei");
    8000524c:	00002517          	auipc	a0,0x2
    80005250:	4b450513          	addi	a0,a0,1204 # 80007700 <etext+0x700>
    80005254:	d8cfb0ef          	jal	800007e0 <panic>
    dp->nlink--;
    80005258:	04a4d783          	lhu	a5,74(s1)
    8000525c:	37fd                	addiw	a5,a5,-1
    8000525e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005262:	8526                	mv	a0,s1
    80005264:	a42fe0ef          	jal	800034a6 <iupdate>
    80005268:	bfa9                	j	800051c2 <sys_unlink+0xb6>
    8000526a:	694e                	ld	s2,208(sp)
  iunlockput(dp);
    8000526c:	8526                	mv	a0,s1
    8000526e:	cf6fe0ef          	jal	80003764 <iunlockput>
  end_op();
    80005272:	d3dfe0ef          	jal	80003fae <end_op>
  return -1;
    80005276:	557d                	li	a0,-1
    80005278:	64ee                	ld	s1,216(sp)
}
    8000527a:	70ae                	ld	ra,232(sp)
    8000527c:	740e                	ld	s0,224(sp)
    8000527e:	616d                	addi	sp,sp,240
    80005280:	8082                	ret
    return -1;
    80005282:	557d                	li	a0,-1
    80005284:	bfdd                	j	8000527a <sys_unlink+0x16e>
    iunlockput(ip);
    80005286:	854a                	mv	a0,s2
    80005288:	cdcfe0ef          	jal	80003764 <iunlockput>
    goto bad;
    8000528c:	694e                	ld	s2,208(sp)
    8000528e:	69ae                	ld	s3,200(sp)
    80005290:	bff1                	j	8000526c <sys_unlink+0x160>

0000000080005292 <sys_open>:

uint64
sys_open(void)
{
    80005292:	7131                	addi	sp,sp,-192
    80005294:	fd06                	sd	ra,184(sp)
    80005296:	f922                	sd	s0,176(sp)
    80005298:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    8000529a:	f4c40593          	addi	a1,s0,-180
    8000529e:	4505                	li	a0,1
    800052a0:	863fd0ef          	jal	80002b02 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    800052a4:	08000613          	li	a2,128
    800052a8:	f5040593          	addi	a1,s0,-176
    800052ac:	4501                	li	a0,0
    800052ae:	88dfd0ef          	jal	80002b3a <argstr>
    800052b2:	87aa                	mv	a5,a0
    return -1;
    800052b4:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    800052b6:	0a07c263          	bltz	a5,8000535a <sys_open+0xc8>
    800052ba:	f526                	sd	s1,168(sp)

  begin_op();
    800052bc:	c89fe0ef          	jal	80003f44 <begin_op>

  if(omode & O_CREATE){
    800052c0:	f4c42783          	lw	a5,-180(s0)
    800052c4:	2007f793          	andi	a5,a5,512
    800052c8:	c3d5                	beqz	a5,8000536c <sys_open+0xda>
    ip = create(path, T_FILE, 0, 0);
    800052ca:	4681                	li	a3,0
    800052cc:	4601                	li	a2,0
    800052ce:	4589                	li	a1,2
    800052d0:	f5040513          	addi	a0,s0,-176
    800052d4:	a83ff0ef          	jal	80004d56 <create>
    800052d8:	84aa                	mv	s1,a0
    if(ip == 0){
    800052da:	c541                	beqz	a0,80005362 <sys_open+0xd0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800052dc:	04449703          	lh	a4,68(s1)
    800052e0:	478d                	li	a5,3
    800052e2:	00f71763          	bne	a4,a5,800052f0 <sys_open+0x5e>
    800052e6:	0464d703          	lhu	a4,70(s1)
    800052ea:	47a5                	li	a5,9
    800052ec:	0ae7ed63          	bltu	a5,a4,800053a6 <sys_open+0x114>
    800052f0:	f14a                	sd	s2,160(sp)
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800052f2:	fbbfe0ef          	jal	800042ac <filealloc>
    800052f6:	892a                	mv	s2,a0
    800052f8:	c179                	beqz	a0,800053be <sys_open+0x12c>
    800052fa:	ed4e                	sd	s3,152(sp)
    800052fc:	a1dff0ef          	jal	80004d18 <fdalloc>
    80005300:	89aa                	mv	s3,a0
    80005302:	0a054a63          	bltz	a0,800053b6 <sys_open+0x124>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005306:	04449703          	lh	a4,68(s1)
    8000530a:	478d                	li	a5,3
    8000530c:	0cf70263          	beq	a4,a5,800053d0 <sys_open+0x13e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005310:	4789                	li	a5,2
    80005312:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    80005316:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    8000531a:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    8000531e:	f4c42783          	lw	a5,-180(s0)
    80005322:	0017c713          	xori	a4,a5,1
    80005326:	8b05                	andi	a4,a4,1
    80005328:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000532c:	0037f713          	andi	a4,a5,3
    80005330:	00e03733          	snez	a4,a4
    80005334:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005338:	4007f793          	andi	a5,a5,1024
    8000533c:	c791                	beqz	a5,80005348 <sys_open+0xb6>
    8000533e:	04449703          	lh	a4,68(s1)
    80005342:	4789                	li	a5,2
    80005344:	08f70d63          	beq	a4,a5,800053de <sys_open+0x14c>
    itrunc(ip);
  }

  iunlock(ip);
    80005348:	8526                	mv	a0,s1
    8000534a:	abefe0ef          	jal	80003608 <iunlock>
  end_op();
    8000534e:	c61fe0ef          	jal	80003fae <end_op>

  return fd;
    80005352:	854e                	mv	a0,s3
    80005354:	74aa                	ld	s1,168(sp)
    80005356:	790a                	ld	s2,160(sp)
    80005358:	69ea                	ld	s3,152(sp)
}
    8000535a:	70ea                	ld	ra,184(sp)
    8000535c:	744a                	ld	s0,176(sp)
    8000535e:	6129                	addi	sp,sp,192
    80005360:	8082                	ret
      end_op();
    80005362:	c4dfe0ef          	jal	80003fae <end_op>
      return -1;
    80005366:	557d                	li	a0,-1
    80005368:	74aa                	ld	s1,168(sp)
    8000536a:	bfc5                	j	8000535a <sys_open+0xc8>
    if((ip = namei(path)) == 0){
    8000536c:	f5040513          	addi	a0,s0,-176
    80005370:	a01fe0ef          	jal	80003d70 <namei>
    80005374:	84aa                	mv	s1,a0
    80005376:	c11d                	beqz	a0,8000539c <sys_open+0x10a>
    ilock(ip);
    80005378:	9e2fe0ef          	jal	8000355a <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000537c:	04449703          	lh	a4,68(s1)
    80005380:	4785                	li	a5,1
    80005382:	f4f71de3          	bne	a4,a5,800052dc <sys_open+0x4a>
    80005386:	f4c42783          	lw	a5,-180(s0)
    8000538a:	d3bd                	beqz	a5,800052f0 <sys_open+0x5e>
      iunlockput(ip);
    8000538c:	8526                	mv	a0,s1
    8000538e:	bd6fe0ef          	jal	80003764 <iunlockput>
      end_op();
    80005392:	c1dfe0ef          	jal	80003fae <end_op>
      return -1;
    80005396:	557d                	li	a0,-1
    80005398:	74aa                	ld	s1,168(sp)
    8000539a:	b7c1                	j	8000535a <sys_open+0xc8>
      end_op();
    8000539c:	c13fe0ef          	jal	80003fae <end_op>
      return -1;
    800053a0:	557d                	li	a0,-1
    800053a2:	74aa                	ld	s1,168(sp)
    800053a4:	bf5d                	j	8000535a <sys_open+0xc8>
    iunlockput(ip);
    800053a6:	8526                	mv	a0,s1
    800053a8:	bbcfe0ef          	jal	80003764 <iunlockput>
    end_op();
    800053ac:	c03fe0ef          	jal	80003fae <end_op>
    return -1;
    800053b0:	557d                	li	a0,-1
    800053b2:	74aa                	ld	s1,168(sp)
    800053b4:	b75d                	j	8000535a <sys_open+0xc8>
      fileclose(f);
    800053b6:	854a                	mv	a0,s2
    800053b8:	f99fe0ef          	jal	80004350 <fileclose>
    800053bc:	69ea                	ld	s3,152(sp)
    iunlockput(ip);
    800053be:	8526                	mv	a0,s1
    800053c0:	ba4fe0ef          	jal	80003764 <iunlockput>
    end_op();
    800053c4:	bebfe0ef          	jal	80003fae <end_op>
    return -1;
    800053c8:	557d                	li	a0,-1
    800053ca:	74aa                	ld	s1,168(sp)
    800053cc:	790a                	ld	s2,160(sp)
    800053ce:	b771                	j	8000535a <sys_open+0xc8>
    f->type = FD_DEVICE;
    800053d0:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    800053d4:	04649783          	lh	a5,70(s1)
    800053d8:	02f91223          	sh	a5,36(s2)
    800053dc:	bf3d                	j	8000531a <sys_open+0x88>
    itrunc(ip);
    800053de:	8526                	mv	a0,s1
    800053e0:	a68fe0ef          	jal	80003648 <itrunc>
    800053e4:	b795                	j	80005348 <sys_open+0xb6>

00000000800053e6 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800053e6:	7175                	addi	sp,sp,-144
    800053e8:	e506                	sd	ra,136(sp)
    800053ea:	e122                	sd	s0,128(sp)
    800053ec:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800053ee:	b57fe0ef          	jal	80003f44 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800053f2:	08000613          	li	a2,128
    800053f6:	f7040593          	addi	a1,s0,-144
    800053fa:	4501                	li	a0,0
    800053fc:	f3efd0ef          	jal	80002b3a <argstr>
    80005400:	02054363          	bltz	a0,80005426 <sys_mkdir+0x40>
    80005404:	4681                	li	a3,0
    80005406:	4601                	li	a2,0
    80005408:	4585                	li	a1,1
    8000540a:	f7040513          	addi	a0,s0,-144
    8000540e:	949ff0ef          	jal	80004d56 <create>
    80005412:	c911                	beqz	a0,80005426 <sys_mkdir+0x40>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005414:	b50fe0ef          	jal	80003764 <iunlockput>
  end_op();
    80005418:	b97fe0ef          	jal	80003fae <end_op>
  return 0;
    8000541c:	4501                	li	a0,0
}
    8000541e:	60aa                	ld	ra,136(sp)
    80005420:	640a                	ld	s0,128(sp)
    80005422:	6149                	addi	sp,sp,144
    80005424:	8082                	ret
    end_op();
    80005426:	b89fe0ef          	jal	80003fae <end_op>
    return -1;
    8000542a:	557d                	li	a0,-1
    8000542c:	bfcd                	j	8000541e <sys_mkdir+0x38>

000000008000542e <sys_mknod>:

uint64
sys_mknod(void)
{
    8000542e:	7135                	addi	sp,sp,-160
    80005430:	ed06                	sd	ra,152(sp)
    80005432:	e922                	sd	s0,144(sp)
    80005434:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005436:	b0ffe0ef          	jal	80003f44 <begin_op>
  argint(1, &major);
    8000543a:	f6c40593          	addi	a1,s0,-148
    8000543e:	4505                	li	a0,1
    80005440:	ec2fd0ef          	jal	80002b02 <argint>
  argint(2, &minor);
    80005444:	f6840593          	addi	a1,s0,-152
    80005448:	4509                	li	a0,2
    8000544a:	eb8fd0ef          	jal	80002b02 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000544e:	08000613          	li	a2,128
    80005452:	f7040593          	addi	a1,s0,-144
    80005456:	4501                	li	a0,0
    80005458:	ee2fd0ef          	jal	80002b3a <argstr>
    8000545c:	02054563          	bltz	a0,80005486 <sys_mknod+0x58>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005460:	f6841683          	lh	a3,-152(s0)
    80005464:	f6c41603          	lh	a2,-148(s0)
    80005468:	458d                	li	a1,3
    8000546a:	f7040513          	addi	a0,s0,-144
    8000546e:	8e9ff0ef          	jal	80004d56 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005472:	c911                	beqz	a0,80005486 <sys_mknod+0x58>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005474:	af0fe0ef          	jal	80003764 <iunlockput>
  end_op();
    80005478:	b37fe0ef          	jal	80003fae <end_op>
  return 0;
    8000547c:	4501                	li	a0,0
}
    8000547e:	60ea                	ld	ra,152(sp)
    80005480:	644a                	ld	s0,144(sp)
    80005482:	610d                	addi	sp,sp,160
    80005484:	8082                	ret
    end_op();
    80005486:	b29fe0ef          	jal	80003fae <end_op>
    return -1;
    8000548a:	557d                	li	a0,-1
    8000548c:	bfcd                	j	8000547e <sys_mknod+0x50>

000000008000548e <sys_chdir>:

uint64
sys_chdir(void)
{
    8000548e:	7135                	addi	sp,sp,-160
    80005490:	ed06                	sd	ra,152(sp)
    80005492:	e922                	sd	s0,144(sp)
    80005494:	e14a                	sd	s2,128(sp)
    80005496:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005498:	c76fc0ef          	jal	8000190e <myproc>
    8000549c:	892a                	mv	s2,a0
  
  begin_op();
    8000549e:	aa7fe0ef          	jal	80003f44 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800054a2:	08000613          	li	a2,128
    800054a6:	f6040593          	addi	a1,s0,-160
    800054aa:	4501                	li	a0,0
    800054ac:	e8efd0ef          	jal	80002b3a <argstr>
    800054b0:	04054363          	bltz	a0,800054f6 <sys_chdir+0x68>
    800054b4:	e526                	sd	s1,136(sp)
    800054b6:	f6040513          	addi	a0,s0,-160
    800054ba:	8b7fe0ef          	jal	80003d70 <namei>
    800054be:	84aa                	mv	s1,a0
    800054c0:	c915                	beqz	a0,800054f4 <sys_chdir+0x66>
    end_op();
    return -1;
  }
  ilock(ip);
    800054c2:	898fe0ef          	jal	8000355a <ilock>
  if(ip->type != T_DIR){
    800054c6:	04449703          	lh	a4,68(s1)
    800054ca:	4785                	li	a5,1
    800054cc:	02f71963          	bne	a4,a5,800054fe <sys_chdir+0x70>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800054d0:	8526                	mv	a0,s1
    800054d2:	936fe0ef          	jal	80003608 <iunlock>
  iput(p->cwd);
    800054d6:	15093503          	ld	a0,336(s2)
    800054da:	a02fe0ef          	jal	800036dc <iput>
  end_op();
    800054de:	ad1fe0ef          	jal	80003fae <end_op>
  p->cwd = ip;
    800054e2:	14993823          	sd	s1,336(s2)
  return 0;
    800054e6:	4501                	li	a0,0
    800054e8:	64aa                	ld	s1,136(sp)
}
    800054ea:	60ea                	ld	ra,152(sp)
    800054ec:	644a                	ld	s0,144(sp)
    800054ee:	690a                	ld	s2,128(sp)
    800054f0:	610d                	addi	sp,sp,160
    800054f2:	8082                	ret
    800054f4:	64aa                	ld	s1,136(sp)
    end_op();
    800054f6:	ab9fe0ef          	jal	80003fae <end_op>
    return -1;
    800054fa:	557d                	li	a0,-1
    800054fc:	b7fd                	j	800054ea <sys_chdir+0x5c>
    iunlockput(ip);
    800054fe:	8526                	mv	a0,s1
    80005500:	a64fe0ef          	jal	80003764 <iunlockput>
    end_op();
    80005504:	aabfe0ef          	jal	80003fae <end_op>
    return -1;
    80005508:	557d                	li	a0,-1
    8000550a:	64aa                	ld	s1,136(sp)
    8000550c:	bff9                	j	800054ea <sys_chdir+0x5c>

000000008000550e <sys_exec>:

uint64
sys_exec(void)
{
    8000550e:	7121                	addi	sp,sp,-448
    80005510:	ff06                	sd	ra,440(sp)
    80005512:	fb22                	sd	s0,432(sp)
    80005514:	0380                	addi	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005516:	e4840593          	addi	a1,s0,-440
    8000551a:	4505                	li	a0,1
    8000551c:	e02fd0ef          	jal	80002b1e <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005520:	08000613          	li	a2,128
    80005524:	f5040593          	addi	a1,s0,-176
    80005528:	4501                	li	a0,0
    8000552a:	e10fd0ef          	jal	80002b3a <argstr>
    8000552e:	87aa                	mv	a5,a0
    return -1;
    80005530:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005532:	0c07c463          	bltz	a5,800055fa <sys_exec+0xec>
    80005536:	f726                	sd	s1,424(sp)
    80005538:	f34a                	sd	s2,416(sp)
    8000553a:	ef4e                	sd	s3,408(sp)
    8000553c:	eb52                	sd	s4,400(sp)
  }
  memset(argv, 0, sizeof(argv));
    8000553e:	10000613          	li	a2,256
    80005542:	4581                	li	a1,0
    80005544:	e5040513          	addi	a0,s0,-432
    80005548:	f5afb0ef          	jal	80000ca2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    8000554c:	e5040493          	addi	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    80005550:	89a6                	mv	s3,s1
    80005552:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005554:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005558:	00391513          	slli	a0,s2,0x3
    8000555c:	e4040593          	addi	a1,s0,-448
    80005560:	e4843783          	ld	a5,-440(s0)
    80005564:	953e                	add	a0,a0,a5
    80005566:	d12fd0ef          	jal	80002a78 <fetchaddr>
    8000556a:	02054663          	bltz	a0,80005596 <sys_exec+0x88>
      goto bad;
    }
    if(uarg == 0){
    8000556e:	e4043783          	ld	a5,-448(s0)
    80005572:	c3a9                	beqz	a5,800055b4 <sys_exec+0xa6>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005574:	d8afb0ef          	jal	80000afe <kalloc>
    80005578:	85aa                	mv	a1,a0
    8000557a:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    8000557e:	cd01                	beqz	a0,80005596 <sys_exec+0x88>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005580:	6605                	lui	a2,0x1
    80005582:	e4043503          	ld	a0,-448(s0)
    80005586:	d3cfd0ef          	jal	80002ac2 <fetchstr>
    8000558a:	00054663          	bltz	a0,80005596 <sys_exec+0x88>
    if(i >= NELEM(argv)){
    8000558e:	0905                	addi	s2,s2,1
    80005590:	09a1                	addi	s3,s3,8
    80005592:	fd4913e3          	bne	s2,s4,80005558 <sys_exec+0x4a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005596:	f5040913          	addi	s2,s0,-176
    8000559a:	6088                	ld	a0,0(s1)
    8000559c:	c931                	beqz	a0,800055f0 <sys_exec+0xe2>
    kfree(argv[i]);
    8000559e:	c7efb0ef          	jal	80000a1c <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800055a2:	04a1                	addi	s1,s1,8
    800055a4:	ff249be3          	bne	s1,s2,8000559a <sys_exec+0x8c>
  return -1;
    800055a8:	557d                	li	a0,-1
    800055aa:	74ba                	ld	s1,424(sp)
    800055ac:	791a                	ld	s2,416(sp)
    800055ae:	69fa                	ld	s3,408(sp)
    800055b0:	6a5a                	ld	s4,400(sp)
    800055b2:	a0a1                	j	800055fa <sys_exec+0xec>
      argv[i] = 0;
    800055b4:	0009079b          	sext.w	a5,s2
    800055b8:	078e                	slli	a5,a5,0x3
    800055ba:	fd078793          	addi	a5,a5,-48
    800055be:	97a2                	add	a5,a5,s0
    800055c0:	e807b023          	sd	zero,-384(a5)
  int ret = kexec(path, argv);
    800055c4:	e5040593          	addi	a1,s0,-432
    800055c8:	f5040513          	addi	a0,s0,-176
    800055cc:	b82ff0ef          	jal	8000494e <kexec>
    800055d0:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800055d2:	f5040993          	addi	s3,s0,-176
    800055d6:	6088                	ld	a0,0(s1)
    800055d8:	c511                	beqz	a0,800055e4 <sys_exec+0xd6>
    kfree(argv[i]);
    800055da:	c42fb0ef          	jal	80000a1c <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800055de:	04a1                	addi	s1,s1,8
    800055e0:	ff349be3          	bne	s1,s3,800055d6 <sys_exec+0xc8>
  return ret;
    800055e4:	854a                	mv	a0,s2
    800055e6:	74ba                	ld	s1,424(sp)
    800055e8:	791a                	ld	s2,416(sp)
    800055ea:	69fa                	ld	s3,408(sp)
    800055ec:	6a5a                	ld	s4,400(sp)
    800055ee:	a031                	j	800055fa <sys_exec+0xec>
  return -1;
    800055f0:	557d                	li	a0,-1
    800055f2:	74ba                	ld	s1,424(sp)
    800055f4:	791a                	ld	s2,416(sp)
    800055f6:	69fa                	ld	s3,408(sp)
    800055f8:	6a5a                	ld	s4,400(sp)
}
    800055fa:	70fa                	ld	ra,440(sp)
    800055fc:	745a                	ld	s0,432(sp)
    800055fe:	6139                	addi	sp,sp,448
    80005600:	8082                	ret

0000000080005602 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005602:	7139                	addi	sp,sp,-64
    80005604:	fc06                	sd	ra,56(sp)
    80005606:	f822                	sd	s0,48(sp)
    80005608:	f426                	sd	s1,40(sp)
    8000560a:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    8000560c:	b02fc0ef          	jal	8000190e <myproc>
    80005610:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005612:	fd840593          	addi	a1,s0,-40
    80005616:	4501                	li	a0,0
    80005618:	d06fd0ef          	jal	80002b1e <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    8000561c:	fc840593          	addi	a1,s0,-56
    80005620:	fd040513          	addi	a0,s0,-48
    80005624:	836ff0ef          	jal	8000465a <pipealloc>
    return -1;
    80005628:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    8000562a:	0a054463          	bltz	a0,800056d2 <sys_pipe+0xd0>
  fd0 = -1;
    8000562e:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005632:	fd043503          	ld	a0,-48(s0)
    80005636:	ee2ff0ef          	jal	80004d18 <fdalloc>
    8000563a:	fca42223          	sw	a0,-60(s0)
    8000563e:	08054163          	bltz	a0,800056c0 <sys_pipe+0xbe>
    80005642:	fc843503          	ld	a0,-56(s0)
    80005646:	ed2ff0ef          	jal	80004d18 <fdalloc>
    8000564a:	fca42023          	sw	a0,-64(s0)
    8000564e:	06054063          	bltz	a0,800056ae <sys_pipe+0xac>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005652:	4691                	li	a3,4
    80005654:	fc440613          	addi	a2,s0,-60
    80005658:	fd843583          	ld	a1,-40(s0)
    8000565c:	68a8                	ld	a0,80(s1)
    8000565e:	f85fb0ef          	jal	800015e2 <copyout>
    80005662:	00054e63          	bltz	a0,8000567e <sys_pipe+0x7c>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005666:	4691                	li	a3,4
    80005668:	fc040613          	addi	a2,s0,-64
    8000566c:	fd843583          	ld	a1,-40(s0)
    80005670:	0591                	addi	a1,a1,4
    80005672:	68a8                	ld	a0,80(s1)
    80005674:	f6ffb0ef          	jal	800015e2 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005678:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000567a:	04055c63          	bgez	a0,800056d2 <sys_pipe+0xd0>
    p->ofile[fd0] = 0;
    8000567e:	fc442783          	lw	a5,-60(s0)
    80005682:	07e9                	addi	a5,a5,26
    80005684:	078e                	slli	a5,a5,0x3
    80005686:	97a6                	add	a5,a5,s1
    80005688:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    8000568c:	fc042783          	lw	a5,-64(s0)
    80005690:	07e9                	addi	a5,a5,26
    80005692:	078e                	slli	a5,a5,0x3
    80005694:	94be                	add	s1,s1,a5
    80005696:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    8000569a:	fd043503          	ld	a0,-48(s0)
    8000569e:	cb3fe0ef          	jal	80004350 <fileclose>
    fileclose(wf);
    800056a2:	fc843503          	ld	a0,-56(s0)
    800056a6:	cabfe0ef          	jal	80004350 <fileclose>
    return -1;
    800056aa:	57fd                	li	a5,-1
    800056ac:	a01d                	j	800056d2 <sys_pipe+0xd0>
    if(fd0 >= 0)
    800056ae:	fc442783          	lw	a5,-60(s0)
    800056b2:	0007c763          	bltz	a5,800056c0 <sys_pipe+0xbe>
      p->ofile[fd0] = 0;
    800056b6:	07e9                	addi	a5,a5,26
    800056b8:	078e                	slli	a5,a5,0x3
    800056ba:	97a6                	add	a5,a5,s1
    800056bc:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    800056c0:	fd043503          	ld	a0,-48(s0)
    800056c4:	c8dfe0ef          	jal	80004350 <fileclose>
    fileclose(wf);
    800056c8:	fc843503          	ld	a0,-56(s0)
    800056cc:	c85fe0ef          	jal	80004350 <fileclose>
    return -1;
    800056d0:	57fd                	li	a5,-1
}
    800056d2:	853e                	mv	a0,a5
    800056d4:	70e2                	ld	ra,56(sp)
    800056d6:	7442                	ld	s0,48(sp)
    800056d8:	74a2                	ld	s1,40(sp)
    800056da:	6121                	addi	sp,sp,64
    800056dc:	8082                	ret
	...

00000000800056e0 <kernelvec>:
.globl kerneltrap
.globl kernelvec
.align 4
kernelvec:
        # make room to save registers.
        addi sp, sp, -256
    800056e0:	7111                	addi	sp,sp,-256

        # save caller-saved registers.
        sd ra, 0(sp)
    800056e2:	e006                	sd	ra,0(sp)
        # sd sp, 8(sp)
        sd gp, 16(sp)
    800056e4:	e80e                	sd	gp,16(sp)
        sd tp, 24(sp)
    800056e6:	ec12                	sd	tp,24(sp)
        sd t0, 32(sp)
    800056e8:	f016                	sd	t0,32(sp)
        sd t1, 40(sp)
    800056ea:	f41a                	sd	t1,40(sp)
        sd t2, 48(sp)
    800056ec:	f81e                	sd	t2,48(sp)
        sd a0, 72(sp)
    800056ee:	e4aa                	sd	a0,72(sp)
        sd a1, 80(sp)
    800056f0:	e8ae                	sd	a1,80(sp)
        sd a2, 88(sp)
    800056f2:	ecb2                	sd	a2,88(sp)
        sd a3, 96(sp)
    800056f4:	f0b6                	sd	a3,96(sp)
        sd a4, 104(sp)
    800056f6:	f4ba                	sd	a4,104(sp)
        sd a5, 112(sp)
    800056f8:	f8be                	sd	a5,112(sp)
        sd a6, 120(sp)
    800056fa:	fcc2                	sd	a6,120(sp)
        sd a7, 128(sp)
    800056fc:	e146                	sd	a7,128(sp)
        sd t3, 216(sp)
    800056fe:	edf2                	sd	t3,216(sp)
        sd t4, 224(sp)
    80005700:	f1f6                	sd	t4,224(sp)
        sd t5, 232(sp)
    80005702:	f5fa                	sd	t5,232(sp)
        sd t6, 240(sp)
    80005704:	f9fe                	sd	t6,240(sp)

        # call the C trap handler in trap.c
        call kerneltrap
    80005706:	a44fd0ef          	jal	8000294a <kerneltrap>

        # restore registers.
        ld ra, 0(sp)
    8000570a:	6082                	ld	ra,0(sp)
        # ld sp, 8(sp)
        ld gp, 16(sp)
    8000570c:	61c2                	ld	gp,16(sp)
        # not tp (contains hartid), in case we moved CPUs
        ld t0, 32(sp)
    8000570e:	7282                	ld	t0,32(sp)
        ld t1, 40(sp)
    80005710:	7322                	ld	t1,40(sp)
        ld t2, 48(sp)
    80005712:	73c2                	ld	t2,48(sp)
        ld a0, 72(sp)
    80005714:	6526                	ld	a0,72(sp)
        ld a1, 80(sp)
    80005716:	65c6                	ld	a1,80(sp)
        ld a2, 88(sp)
    80005718:	6666                	ld	a2,88(sp)
        ld a3, 96(sp)
    8000571a:	7686                	ld	a3,96(sp)
        ld a4, 104(sp)
    8000571c:	7726                	ld	a4,104(sp)
        ld a5, 112(sp)
    8000571e:	77c6                	ld	a5,112(sp)
        ld a6, 120(sp)
    80005720:	7866                	ld	a6,120(sp)
        ld a7, 128(sp)
    80005722:	688a                	ld	a7,128(sp)
        ld t3, 216(sp)
    80005724:	6e6e                	ld	t3,216(sp)
        ld t4, 224(sp)
    80005726:	7e8e                	ld	t4,224(sp)
        ld t5, 232(sp)
    80005728:	7f2e                	ld	t5,232(sp)
        ld t6, 240(sp)
    8000572a:	7fce                	ld	t6,240(sp)

        addi sp, sp, 256
    8000572c:	6111                	addi	sp,sp,256

        # return to whatever we were doing in the kernel.
        sret
    8000572e:	10200073          	sret
	...

000000008000573e <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000573e:	1141                	addi	sp,sp,-16
    80005740:	e422                	sd	s0,8(sp)
    80005742:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005744:	0c0007b7          	lui	a5,0xc000
    80005748:	4705                	li	a4,1
    8000574a:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    8000574c:	0c0007b7          	lui	a5,0xc000
    80005750:	c3d8                	sw	a4,4(a5)
}
    80005752:	6422                	ld	s0,8(sp)
    80005754:	0141                	addi	sp,sp,16
    80005756:	8082                	ret

0000000080005758 <plicinithart>:

void
plicinithart(void)
{
    80005758:	1141                	addi	sp,sp,-16
    8000575a:	e406                	sd	ra,8(sp)
    8000575c:	e022                	sd	s0,0(sp)
    8000575e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005760:	982fc0ef          	jal	800018e2 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005764:	0085171b          	slliw	a4,a0,0x8
    80005768:	0c0027b7          	lui	a5,0xc002
    8000576c:	97ba                	add	a5,a5,a4
    8000576e:	40200713          	li	a4,1026
    80005772:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005776:	00d5151b          	slliw	a0,a0,0xd
    8000577a:	0c2017b7          	lui	a5,0xc201
    8000577e:	97aa                	add	a5,a5,a0
    80005780:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005784:	60a2                	ld	ra,8(sp)
    80005786:	6402                	ld	s0,0(sp)
    80005788:	0141                	addi	sp,sp,16
    8000578a:	8082                	ret

000000008000578c <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    8000578c:	1141                	addi	sp,sp,-16
    8000578e:	e406                	sd	ra,8(sp)
    80005790:	e022                	sd	s0,0(sp)
    80005792:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005794:	94efc0ef          	jal	800018e2 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005798:	00d5151b          	slliw	a0,a0,0xd
    8000579c:	0c2017b7          	lui	a5,0xc201
    800057a0:	97aa                	add	a5,a5,a0
  return irq;
}
    800057a2:	43c8                	lw	a0,4(a5)
    800057a4:	60a2                	ld	ra,8(sp)
    800057a6:	6402                	ld	s0,0(sp)
    800057a8:	0141                	addi	sp,sp,16
    800057aa:	8082                	ret

00000000800057ac <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800057ac:	1101                	addi	sp,sp,-32
    800057ae:	ec06                	sd	ra,24(sp)
    800057b0:	e822                	sd	s0,16(sp)
    800057b2:	e426                	sd	s1,8(sp)
    800057b4:	1000                	addi	s0,sp,32
    800057b6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800057b8:	92afc0ef          	jal	800018e2 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800057bc:	00d5151b          	slliw	a0,a0,0xd
    800057c0:	0c2017b7          	lui	a5,0xc201
    800057c4:	97aa                	add	a5,a5,a0
    800057c6:	c3c4                	sw	s1,4(a5)
}
    800057c8:	60e2                	ld	ra,24(sp)
    800057ca:	6442                	ld	s0,16(sp)
    800057cc:	64a2                	ld	s1,8(sp)
    800057ce:	6105                	addi	sp,sp,32
    800057d0:	8082                	ret

00000000800057d2 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800057d2:	1141                	addi	sp,sp,-16
    800057d4:	e406                	sd	ra,8(sp)
    800057d6:	e022                	sd	s0,0(sp)
    800057d8:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800057da:	479d                	li	a5,7
    800057dc:	04a7ca63          	blt	a5,a0,80005830 <free_desc+0x5e>
    panic("free_desc 1");
  if(disk.free[i])
    800057e0:	0001f797          	auipc	a5,0x1f
    800057e4:	c3878793          	addi	a5,a5,-968 # 80024418 <disk>
    800057e8:	97aa                	add	a5,a5,a0
    800057ea:	0187c783          	lbu	a5,24(a5)
    800057ee:	e7b9                	bnez	a5,8000583c <free_desc+0x6a>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800057f0:	00451693          	slli	a3,a0,0x4
    800057f4:	0001f797          	auipc	a5,0x1f
    800057f8:	c2478793          	addi	a5,a5,-988 # 80024418 <disk>
    800057fc:	6398                	ld	a4,0(a5)
    800057fe:	9736                	add	a4,a4,a3
    80005800:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80005804:	6398                	ld	a4,0(a5)
    80005806:	9736                	add	a4,a4,a3
    80005808:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    8000580c:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005810:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005814:	97aa                	add	a5,a5,a0
    80005816:	4705                	li	a4,1
    80005818:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    8000581c:	0001f517          	auipc	a0,0x1f
    80005820:	c1450513          	addi	a0,a0,-1004 # 80024430 <disk+0x18>
    80005824:	95dfc0ef          	jal	80002180 <wakeup>
}
    80005828:	60a2                	ld	ra,8(sp)
    8000582a:	6402                	ld	s0,0(sp)
    8000582c:	0141                	addi	sp,sp,16
    8000582e:	8082                	ret
    panic("free_desc 1");
    80005830:	00002517          	auipc	a0,0x2
    80005834:	ee050513          	addi	a0,a0,-288 # 80007710 <etext+0x710>
    80005838:	fa9fa0ef          	jal	800007e0 <panic>
    panic("free_desc 2");
    8000583c:	00002517          	auipc	a0,0x2
    80005840:	ee450513          	addi	a0,a0,-284 # 80007720 <etext+0x720>
    80005844:	f9dfa0ef          	jal	800007e0 <panic>

0000000080005848 <virtio_disk_init>:
{
    80005848:	1101                	addi	sp,sp,-32
    8000584a:	ec06                	sd	ra,24(sp)
    8000584c:	e822                	sd	s0,16(sp)
    8000584e:	e426                	sd	s1,8(sp)
    80005850:	e04a                	sd	s2,0(sp)
    80005852:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005854:	00002597          	auipc	a1,0x2
    80005858:	edc58593          	addi	a1,a1,-292 # 80007730 <etext+0x730>
    8000585c:	0001f517          	auipc	a0,0x1f
    80005860:	ce450513          	addi	a0,a0,-796 # 80024540 <disk+0x128>
    80005864:	aeafb0ef          	jal	80000b4e <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005868:	100017b7          	lui	a5,0x10001
    8000586c:	4398                	lw	a4,0(a5)
    8000586e:	2701                	sext.w	a4,a4
    80005870:	747277b7          	lui	a5,0x74727
    80005874:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005878:	18f71063          	bne	a4,a5,800059f8 <virtio_disk_init+0x1b0>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    8000587c:	100017b7          	lui	a5,0x10001
    80005880:	0791                	addi	a5,a5,4 # 10001004 <_entry-0x6fffeffc>
    80005882:	439c                	lw	a5,0(a5)
    80005884:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005886:	4709                	li	a4,2
    80005888:	16e79863          	bne	a5,a4,800059f8 <virtio_disk_init+0x1b0>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000588c:	100017b7          	lui	a5,0x10001
    80005890:	07a1                	addi	a5,a5,8 # 10001008 <_entry-0x6fffeff8>
    80005892:	439c                	lw	a5,0(a5)
    80005894:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005896:	16e79163          	bne	a5,a4,800059f8 <virtio_disk_init+0x1b0>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000589a:	100017b7          	lui	a5,0x10001
    8000589e:	47d8                	lw	a4,12(a5)
    800058a0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800058a2:	554d47b7          	lui	a5,0x554d4
    800058a6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800058aa:	14f71763          	bne	a4,a5,800059f8 <virtio_disk_init+0x1b0>
  *R(VIRTIO_MMIO_STATUS) = status;
    800058ae:	100017b7          	lui	a5,0x10001
    800058b2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    800058b6:	4705                	li	a4,1
    800058b8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800058ba:	470d                	li	a4,3
    800058bc:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800058be:	10001737          	lui	a4,0x10001
    800058c2:	4b14                	lw	a3,16(a4)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800058c4:	c7ffe737          	lui	a4,0xc7ffe
    800058c8:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fda207>
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800058cc:	8ef9                	and	a3,a3,a4
    800058ce:	10001737          	lui	a4,0x10001
    800058d2:	d314                	sw	a3,32(a4)
  *R(VIRTIO_MMIO_STATUS) = status;
    800058d4:	472d                	li	a4,11
    800058d6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800058d8:	07078793          	addi	a5,a5,112
  status = *R(VIRTIO_MMIO_STATUS);
    800058dc:	439c                	lw	a5,0(a5)
    800058de:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    800058e2:	8ba1                	andi	a5,a5,8
    800058e4:	12078063          	beqz	a5,80005a04 <virtio_disk_init+0x1bc>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800058e8:	100017b7          	lui	a5,0x10001
    800058ec:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800058f0:	100017b7          	lui	a5,0x10001
    800058f4:	04478793          	addi	a5,a5,68 # 10001044 <_entry-0x6fffefbc>
    800058f8:	439c                	lw	a5,0(a5)
    800058fa:	2781                	sext.w	a5,a5
    800058fc:	10079a63          	bnez	a5,80005a10 <virtio_disk_init+0x1c8>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005900:	100017b7          	lui	a5,0x10001
    80005904:	03478793          	addi	a5,a5,52 # 10001034 <_entry-0x6fffefcc>
    80005908:	439c                	lw	a5,0(a5)
    8000590a:	2781                	sext.w	a5,a5
  if(max == 0)
    8000590c:	10078863          	beqz	a5,80005a1c <virtio_disk_init+0x1d4>
  if(max < NUM)
    80005910:	471d                	li	a4,7
    80005912:	10f77b63          	bgeu	a4,a5,80005a28 <virtio_disk_init+0x1e0>
  disk.desc = kalloc();
    80005916:	9e8fb0ef          	jal	80000afe <kalloc>
    8000591a:	0001f497          	auipc	s1,0x1f
    8000591e:	afe48493          	addi	s1,s1,-1282 # 80024418 <disk>
    80005922:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005924:	9dafb0ef          	jal	80000afe <kalloc>
    80005928:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000592a:	9d4fb0ef          	jal	80000afe <kalloc>
    8000592e:	87aa                	mv	a5,a0
    80005930:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005932:	6088                	ld	a0,0(s1)
    80005934:	10050063          	beqz	a0,80005a34 <virtio_disk_init+0x1ec>
    80005938:	0001f717          	auipc	a4,0x1f
    8000593c:	ae873703          	ld	a4,-1304(a4) # 80024420 <disk+0x8>
    80005940:	0e070a63          	beqz	a4,80005a34 <virtio_disk_init+0x1ec>
    80005944:	0e078863          	beqz	a5,80005a34 <virtio_disk_init+0x1ec>
  memset(disk.desc, 0, PGSIZE);
    80005948:	6605                	lui	a2,0x1
    8000594a:	4581                	li	a1,0
    8000594c:	b56fb0ef          	jal	80000ca2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80005950:	0001f497          	auipc	s1,0x1f
    80005954:	ac848493          	addi	s1,s1,-1336 # 80024418 <disk>
    80005958:	6605                	lui	a2,0x1
    8000595a:	4581                	li	a1,0
    8000595c:	6488                	ld	a0,8(s1)
    8000595e:	b44fb0ef          	jal	80000ca2 <memset>
  memset(disk.used, 0, PGSIZE);
    80005962:	6605                	lui	a2,0x1
    80005964:	4581                	li	a1,0
    80005966:	6888                	ld	a0,16(s1)
    80005968:	b3afb0ef          	jal	80000ca2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    8000596c:	100017b7          	lui	a5,0x10001
    80005970:	4721                	li	a4,8
    80005972:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005974:	4098                	lw	a4,0(s1)
    80005976:	100017b7          	lui	a5,0x10001
    8000597a:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    8000597e:	40d8                	lw	a4,4(s1)
    80005980:	100017b7          	lui	a5,0x10001
    80005984:	08e7a223          	sw	a4,132(a5) # 10001084 <_entry-0x6fffef7c>
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005988:	649c                	ld	a5,8(s1)
    8000598a:	0007869b          	sext.w	a3,a5
    8000598e:	10001737          	lui	a4,0x10001
    80005992:	08d72823          	sw	a3,144(a4) # 10001090 <_entry-0x6fffef70>
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005996:	9781                	srai	a5,a5,0x20
    80005998:	10001737          	lui	a4,0x10001
    8000599c:	08f72a23          	sw	a5,148(a4) # 10001094 <_entry-0x6fffef6c>
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800059a0:	689c                	ld	a5,16(s1)
    800059a2:	0007869b          	sext.w	a3,a5
    800059a6:	10001737          	lui	a4,0x10001
    800059aa:	0ad72023          	sw	a3,160(a4) # 100010a0 <_entry-0x6fffef60>
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800059ae:	9781                	srai	a5,a5,0x20
    800059b0:	10001737          	lui	a4,0x10001
    800059b4:	0af72223          	sw	a5,164(a4) # 100010a4 <_entry-0x6fffef5c>
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800059b8:	10001737          	lui	a4,0x10001
    800059bc:	4785                	li	a5,1
    800059be:	c37c                	sw	a5,68(a4)
    disk.free[i] = 1;
    800059c0:	00f48c23          	sb	a5,24(s1)
    800059c4:	00f48ca3          	sb	a5,25(s1)
    800059c8:	00f48d23          	sb	a5,26(s1)
    800059cc:	00f48da3          	sb	a5,27(s1)
    800059d0:	00f48e23          	sb	a5,28(s1)
    800059d4:	00f48ea3          	sb	a5,29(s1)
    800059d8:	00f48f23          	sb	a5,30(s1)
    800059dc:	00f48fa3          	sb	a5,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    800059e0:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    800059e4:	100017b7          	lui	a5,0x10001
    800059e8:	0727a823          	sw	s2,112(a5) # 10001070 <_entry-0x6fffef90>
}
    800059ec:	60e2                	ld	ra,24(sp)
    800059ee:	6442                	ld	s0,16(sp)
    800059f0:	64a2                	ld	s1,8(sp)
    800059f2:	6902                	ld	s2,0(sp)
    800059f4:	6105                	addi	sp,sp,32
    800059f6:	8082                	ret
    panic("could not find virtio disk");
    800059f8:	00002517          	auipc	a0,0x2
    800059fc:	d4850513          	addi	a0,a0,-696 # 80007740 <etext+0x740>
    80005a00:	de1fa0ef          	jal	800007e0 <panic>
    panic("virtio disk FEATURES_OK unset");
    80005a04:	00002517          	auipc	a0,0x2
    80005a08:	d5c50513          	addi	a0,a0,-676 # 80007760 <etext+0x760>
    80005a0c:	dd5fa0ef          	jal	800007e0 <panic>
    panic("virtio disk should not be ready");
    80005a10:	00002517          	auipc	a0,0x2
    80005a14:	d7050513          	addi	a0,a0,-656 # 80007780 <etext+0x780>
    80005a18:	dc9fa0ef          	jal	800007e0 <panic>
    panic("virtio disk has no queue 0");
    80005a1c:	00002517          	auipc	a0,0x2
    80005a20:	d8450513          	addi	a0,a0,-636 # 800077a0 <etext+0x7a0>
    80005a24:	dbdfa0ef          	jal	800007e0 <panic>
    panic("virtio disk max queue too short");
    80005a28:	00002517          	auipc	a0,0x2
    80005a2c:	d9850513          	addi	a0,a0,-616 # 800077c0 <etext+0x7c0>
    80005a30:	db1fa0ef          	jal	800007e0 <panic>
    panic("virtio disk kalloc");
    80005a34:	00002517          	auipc	a0,0x2
    80005a38:	dac50513          	addi	a0,a0,-596 # 800077e0 <etext+0x7e0>
    80005a3c:	da5fa0ef          	jal	800007e0 <panic>

0000000080005a40 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005a40:	7159                	addi	sp,sp,-112
    80005a42:	f486                	sd	ra,104(sp)
    80005a44:	f0a2                	sd	s0,96(sp)
    80005a46:	eca6                	sd	s1,88(sp)
    80005a48:	e8ca                	sd	s2,80(sp)
    80005a4a:	e4ce                	sd	s3,72(sp)
    80005a4c:	e0d2                	sd	s4,64(sp)
    80005a4e:	fc56                	sd	s5,56(sp)
    80005a50:	f85a                	sd	s6,48(sp)
    80005a52:	f45e                	sd	s7,40(sp)
    80005a54:	f062                	sd	s8,32(sp)
    80005a56:	ec66                	sd	s9,24(sp)
    80005a58:	1880                	addi	s0,sp,112
    80005a5a:	8a2a                	mv	s4,a0
    80005a5c:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005a5e:	00c52c83          	lw	s9,12(a0)
    80005a62:	001c9c9b          	slliw	s9,s9,0x1
    80005a66:	1c82                	slli	s9,s9,0x20
    80005a68:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005a6c:	0001f517          	auipc	a0,0x1f
    80005a70:	ad450513          	addi	a0,a0,-1324 # 80024540 <disk+0x128>
    80005a74:	95afb0ef          	jal	80000bce <acquire>
  for(int i = 0; i < 3; i++){
    80005a78:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005a7a:	44a1                	li	s1,8
      disk.free[i] = 0;
    80005a7c:	0001fb17          	auipc	s6,0x1f
    80005a80:	99cb0b13          	addi	s6,s6,-1636 # 80024418 <disk>
  for(int i = 0; i < 3; i++){
    80005a84:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005a86:	0001fc17          	auipc	s8,0x1f
    80005a8a:	abac0c13          	addi	s8,s8,-1350 # 80024540 <disk+0x128>
    80005a8e:	a8b9                	j	80005aec <virtio_disk_rw+0xac>
      disk.free[i] = 0;
    80005a90:	00fb0733          	add	a4,s6,a5
    80005a94:	00070c23          	sb	zero,24(a4) # 10001018 <_entry-0x6fffefe8>
    idx[i] = alloc_desc();
    80005a98:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80005a9a:	0207c563          	bltz	a5,80005ac4 <virtio_disk_rw+0x84>
  for(int i = 0; i < 3; i++){
    80005a9e:	2905                	addiw	s2,s2,1
    80005aa0:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    80005aa2:	05590963          	beq	s2,s5,80005af4 <virtio_disk_rw+0xb4>
    idx[i] = alloc_desc();
    80005aa6:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80005aa8:	0001f717          	auipc	a4,0x1f
    80005aac:	97070713          	addi	a4,a4,-1680 # 80024418 <disk>
    80005ab0:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80005ab2:	01874683          	lbu	a3,24(a4)
    80005ab6:	fee9                	bnez	a3,80005a90 <virtio_disk_rw+0x50>
  for(int i = 0; i < NUM; i++){
    80005ab8:	2785                	addiw	a5,a5,1
    80005aba:	0705                	addi	a4,a4,1
    80005abc:	fe979be3          	bne	a5,s1,80005ab2 <virtio_disk_rw+0x72>
    idx[i] = alloc_desc();
    80005ac0:	57fd                	li	a5,-1
    80005ac2:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80005ac4:	01205d63          	blez	s2,80005ade <virtio_disk_rw+0x9e>
        free_desc(idx[j]);
    80005ac8:	f9042503          	lw	a0,-112(s0)
    80005acc:	d07ff0ef          	jal	800057d2 <free_desc>
      for(int j = 0; j < i; j++)
    80005ad0:	4785                	li	a5,1
    80005ad2:	0127d663          	bge	a5,s2,80005ade <virtio_disk_rw+0x9e>
        free_desc(idx[j]);
    80005ad6:	f9442503          	lw	a0,-108(s0)
    80005ada:	cf9ff0ef          	jal	800057d2 <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80005ade:	85e2                	mv	a1,s8
    80005ae0:	0001f517          	auipc	a0,0x1f
    80005ae4:	95050513          	addi	a0,a0,-1712 # 80024430 <disk+0x18>
    80005ae8:	e1cfc0ef          	jal	80002104 <sleep>
  for(int i = 0; i < 3; i++){
    80005aec:	f9040613          	addi	a2,s0,-112
    80005af0:	894e                	mv	s2,s3
    80005af2:	bf55                	j	80005aa6 <virtio_disk_rw+0x66>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80005af4:	f9042503          	lw	a0,-112(s0)
    80005af8:	00451693          	slli	a3,a0,0x4

  if(write)
    80005afc:	0001f797          	auipc	a5,0x1f
    80005b00:	91c78793          	addi	a5,a5,-1764 # 80024418 <disk>
    80005b04:	00a50713          	addi	a4,a0,10
    80005b08:	0712                	slli	a4,a4,0x4
    80005b0a:	973e                	add	a4,a4,a5
    80005b0c:	01703633          	snez	a2,s7
    80005b10:	c710                	sw	a2,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80005b12:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    80005b16:	01973823          	sd	s9,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80005b1a:	6398                	ld	a4,0(a5)
    80005b1c:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80005b1e:	0a868613          	addi	a2,a3,168
    80005b22:	963e                	add	a2,a2,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80005b24:	e310                	sd	a2,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80005b26:	6390                	ld	a2,0(a5)
    80005b28:	00d605b3          	add	a1,a2,a3
    80005b2c:	4741                	li	a4,16
    80005b2e:	c598                	sw	a4,8(a1)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80005b30:	4805                	li	a6,1
    80005b32:	01059623          	sh	a6,12(a1)
  disk.desc[idx[0]].next = idx[1];
    80005b36:	f9442703          	lw	a4,-108(s0)
    80005b3a:	00e59723          	sh	a4,14(a1)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80005b3e:	0712                	slli	a4,a4,0x4
    80005b40:	963a                	add	a2,a2,a4
    80005b42:	058a0593          	addi	a1,s4,88
    80005b46:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80005b48:	0007b883          	ld	a7,0(a5)
    80005b4c:	9746                	add	a4,a4,a7
    80005b4e:	40000613          	li	a2,1024
    80005b52:	c710                	sw	a2,8(a4)
  if(write)
    80005b54:	001bb613          	seqz	a2,s7
    80005b58:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80005b5c:	00166613          	ori	a2,a2,1
    80005b60:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[1]].next = idx[2];
    80005b64:	f9842583          	lw	a1,-104(s0)
    80005b68:	00b71723          	sh	a1,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80005b6c:	00250613          	addi	a2,a0,2
    80005b70:	0612                	slli	a2,a2,0x4
    80005b72:	963e                	add	a2,a2,a5
    80005b74:	577d                	li	a4,-1
    80005b76:	00e60823          	sb	a4,16(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80005b7a:	0592                	slli	a1,a1,0x4
    80005b7c:	98ae                	add	a7,a7,a1
    80005b7e:	03068713          	addi	a4,a3,48
    80005b82:	973e                	add	a4,a4,a5
    80005b84:	00e8b023          	sd	a4,0(a7)
  disk.desc[idx[2]].len = 1;
    80005b88:	6398                	ld	a4,0(a5)
    80005b8a:	972e                	add	a4,a4,a1
    80005b8c:	01072423          	sw	a6,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80005b90:	4689                	li	a3,2
    80005b92:	00d71623          	sh	a3,12(a4)
  disk.desc[idx[2]].next = 0;
    80005b96:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80005b9a:	010a2223          	sw	a6,4(s4)
  disk.info[idx[0]].b = b;
    80005b9e:	01463423          	sd	s4,8(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80005ba2:	6794                	ld	a3,8(a5)
    80005ba4:	0026d703          	lhu	a4,2(a3)
    80005ba8:	8b1d                	andi	a4,a4,7
    80005baa:	0706                	slli	a4,a4,0x1
    80005bac:	96ba                	add	a3,a3,a4
    80005bae:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80005bb2:	0330000f          	fence	rw,rw

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80005bb6:	6798                	ld	a4,8(a5)
    80005bb8:	00275783          	lhu	a5,2(a4)
    80005bbc:	2785                	addiw	a5,a5,1
    80005bbe:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80005bc2:	0330000f          	fence	rw,rw

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80005bc6:	100017b7          	lui	a5,0x10001
    80005bca:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80005bce:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    80005bd2:	0001f917          	auipc	s2,0x1f
    80005bd6:	96e90913          	addi	s2,s2,-1682 # 80024540 <disk+0x128>
  while(b->disk == 1) {
    80005bda:	4485                	li	s1,1
    80005bdc:	01079a63          	bne	a5,a6,80005bf0 <virtio_disk_rw+0x1b0>
    sleep(b, &disk.vdisk_lock);
    80005be0:	85ca                	mv	a1,s2
    80005be2:	8552                	mv	a0,s4
    80005be4:	d20fc0ef          	jal	80002104 <sleep>
  while(b->disk == 1) {
    80005be8:	004a2783          	lw	a5,4(s4)
    80005bec:	fe978ae3          	beq	a5,s1,80005be0 <virtio_disk_rw+0x1a0>
  }

  disk.info[idx[0]].b = 0;
    80005bf0:	f9042903          	lw	s2,-112(s0)
    80005bf4:	00290713          	addi	a4,s2,2
    80005bf8:	0712                	slli	a4,a4,0x4
    80005bfa:	0001f797          	auipc	a5,0x1f
    80005bfe:	81e78793          	addi	a5,a5,-2018 # 80024418 <disk>
    80005c02:	97ba                	add	a5,a5,a4
    80005c04:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80005c08:	0001f997          	auipc	s3,0x1f
    80005c0c:	81098993          	addi	s3,s3,-2032 # 80024418 <disk>
    80005c10:	00491713          	slli	a4,s2,0x4
    80005c14:	0009b783          	ld	a5,0(s3)
    80005c18:	97ba                	add	a5,a5,a4
    80005c1a:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80005c1e:	854a                	mv	a0,s2
    80005c20:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80005c24:	bafff0ef          	jal	800057d2 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80005c28:	8885                	andi	s1,s1,1
    80005c2a:	f0fd                	bnez	s1,80005c10 <virtio_disk_rw+0x1d0>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80005c2c:	0001f517          	auipc	a0,0x1f
    80005c30:	91450513          	addi	a0,a0,-1772 # 80024540 <disk+0x128>
    80005c34:	832fb0ef          	jal	80000c66 <release>
}
    80005c38:	70a6                	ld	ra,104(sp)
    80005c3a:	7406                	ld	s0,96(sp)
    80005c3c:	64e6                	ld	s1,88(sp)
    80005c3e:	6946                	ld	s2,80(sp)
    80005c40:	69a6                	ld	s3,72(sp)
    80005c42:	6a06                	ld	s4,64(sp)
    80005c44:	7ae2                	ld	s5,56(sp)
    80005c46:	7b42                	ld	s6,48(sp)
    80005c48:	7ba2                	ld	s7,40(sp)
    80005c4a:	7c02                	ld	s8,32(sp)
    80005c4c:	6ce2                	ld	s9,24(sp)
    80005c4e:	6165                	addi	sp,sp,112
    80005c50:	8082                	ret

0000000080005c52 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80005c52:	1101                	addi	sp,sp,-32
    80005c54:	ec06                	sd	ra,24(sp)
    80005c56:	e822                	sd	s0,16(sp)
    80005c58:	e426                	sd	s1,8(sp)
    80005c5a:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80005c5c:	0001e497          	auipc	s1,0x1e
    80005c60:	7bc48493          	addi	s1,s1,1980 # 80024418 <disk>
    80005c64:	0001f517          	auipc	a0,0x1f
    80005c68:	8dc50513          	addi	a0,a0,-1828 # 80024540 <disk+0x128>
    80005c6c:	f63fa0ef          	jal	80000bce <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80005c70:	100017b7          	lui	a5,0x10001
    80005c74:	53b8                	lw	a4,96(a5)
    80005c76:	8b0d                	andi	a4,a4,3
    80005c78:	100017b7          	lui	a5,0x10001
    80005c7c:	d3f8                	sw	a4,100(a5)

  __sync_synchronize();
    80005c7e:	0330000f          	fence	rw,rw

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80005c82:	689c                	ld	a5,16(s1)
    80005c84:	0204d703          	lhu	a4,32(s1)
    80005c88:	0027d783          	lhu	a5,2(a5) # 10001002 <_entry-0x6fffeffe>
    80005c8c:	04f70663          	beq	a4,a5,80005cd8 <virtio_disk_intr+0x86>
    __sync_synchronize();
    80005c90:	0330000f          	fence	rw,rw
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80005c94:	6898                	ld	a4,16(s1)
    80005c96:	0204d783          	lhu	a5,32(s1)
    80005c9a:	8b9d                	andi	a5,a5,7
    80005c9c:	078e                	slli	a5,a5,0x3
    80005c9e:	97ba                	add	a5,a5,a4
    80005ca0:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80005ca2:	00278713          	addi	a4,a5,2
    80005ca6:	0712                	slli	a4,a4,0x4
    80005ca8:	9726                	add	a4,a4,s1
    80005caa:	01074703          	lbu	a4,16(a4)
    80005cae:	e321                	bnez	a4,80005cee <virtio_disk_intr+0x9c>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80005cb0:	0789                	addi	a5,a5,2
    80005cb2:	0792                	slli	a5,a5,0x4
    80005cb4:	97a6                	add	a5,a5,s1
    80005cb6:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80005cb8:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80005cbc:	cc4fc0ef          	jal	80002180 <wakeup>

    disk.used_idx += 1;
    80005cc0:	0204d783          	lhu	a5,32(s1)
    80005cc4:	2785                	addiw	a5,a5,1
    80005cc6:	17c2                	slli	a5,a5,0x30
    80005cc8:	93c1                	srli	a5,a5,0x30
    80005cca:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80005cce:	6898                	ld	a4,16(s1)
    80005cd0:	00275703          	lhu	a4,2(a4)
    80005cd4:	faf71ee3          	bne	a4,a5,80005c90 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80005cd8:	0001f517          	auipc	a0,0x1f
    80005cdc:	86850513          	addi	a0,a0,-1944 # 80024540 <disk+0x128>
    80005ce0:	f87fa0ef          	jal	80000c66 <release>
}
    80005ce4:	60e2                	ld	ra,24(sp)
    80005ce6:	6442                	ld	s0,16(sp)
    80005ce8:	64a2                	ld	s1,8(sp)
    80005cea:	6105                	addi	sp,sp,32
    80005cec:	8082                	ret
      panic("virtio_disk_intr status");
    80005cee:	00002517          	auipc	a0,0x2
    80005cf2:	b0a50513          	addi	a0,a0,-1270 # 800077f8 <etext+0x7f8>
    80005cf6:	aebfa0ef          	jal	800007e0 <panic>
	...

0000000080006000 <_trampoline>:
    80006000:	14051073          	csrw	sscratch,a0
    80006004:	02000537          	lui	a0,0x2000
    80006008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000600a:	0536                	slli	a0,a0,0xd
    8000600c:	02153423          	sd	ra,40(a0)
    80006010:	02253823          	sd	sp,48(a0)
    80006014:	02353c23          	sd	gp,56(a0)
    80006018:	04453023          	sd	tp,64(a0)
    8000601c:	04553423          	sd	t0,72(a0)
    80006020:	04653823          	sd	t1,80(a0)
    80006024:	04753c23          	sd	t2,88(a0)
    80006028:	f120                	sd	s0,96(a0)
    8000602a:	f524                	sd	s1,104(a0)
    8000602c:	fd2c                	sd	a1,120(a0)
    8000602e:	e150                	sd	a2,128(a0)
    80006030:	e554                	sd	a3,136(a0)
    80006032:	e958                	sd	a4,144(a0)
    80006034:	ed5c                	sd	a5,152(a0)
    80006036:	0b053023          	sd	a6,160(a0)
    8000603a:	0b153423          	sd	a7,168(a0)
    8000603e:	0b253823          	sd	s2,176(a0)
    80006042:	0b353c23          	sd	s3,184(a0)
    80006046:	0d453023          	sd	s4,192(a0)
    8000604a:	0d553423          	sd	s5,200(a0)
    8000604e:	0d653823          	sd	s6,208(a0)
    80006052:	0d753c23          	sd	s7,216(a0)
    80006056:	0f853023          	sd	s8,224(a0)
    8000605a:	0f953423          	sd	s9,232(a0)
    8000605e:	0fa53823          	sd	s10,240(a0)
    80006062:	0fb53c23          	sd	s11,248(a0)
    80006066:	11c53023          	sd	t3,256(a0)
    8000606a:	11d53423          	sd	t4,264(a0)
    8000606e:	11e53823          	sd	t5,272(a0)
    80006072:	11f53c23          	sd	t6,280(a0)
    80006076:	140022f3          	csrr	t0,sscratch
    8000607a:	06553823          	sd	t0,112(a0)
    8000607e:	00853103          	ld	sp,8(a0)
    80006082:	02053203          	ld	tp,32(a0)
    80006086:	01053283          	ld	t0,16(a0)
    8000608a:	00053303          	ld	t1,0(a0)
    8000608e:	12000073          	sfence.vma
    80006092:	18031073          	csrw	satp,t1
    80006096:	12000073          	sfence.vma
    8000609a:	9282                	jalr	t0

000000008000609c <userret>:
    8000609c:	12000073          	sfence.vma
    800060a0:	18051073          	csrw	satp,a0
    800060a4:	12000073          	sfence.vma
    800060a8:	02000537          	lui	a0,0x2000
    800060ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800060ae:	0536                	slli	a0,a0,0xd
    800060b0:	02853083          	ld	ra,40(a0)
    800060b4:	03053103          	ld	sp,48(a0)
    800060b8:	03853183          	ld	gp,56(a0)
    800060bc:	04053203          	ld	tp,64(a0)
    800060c0:	04853283          	ld	t0,72(a0)
    800060c4:	05053303          	ld	t1,80(a0)
    800060c8:	05853383          	ld	t2,88(a0)
    800060cc:	7120                	ld	s0,96(a0)
    800060ce:	7524                	ld	s1,104(a0)
    800060d0:	7d2c                	ld	a1,120(a0)
    800060d2:	6150                	ld	a2,128(a0)
    800060d4:	6554                	ld	a3,136(a0)
    800060d6:	6958                	ld	a4,144(a0)
    800060d8:	6d5c                	ld	a5,152(a0)
    800060da:	0a053803          	ld	a6,160(a0)
    800060de:	0a853883          	ld	a7,168(a0)
    800060e2:	0b053903          	ld	s2,176(a0)
    800060e6:	0b853983          	ld	s3,184(a0)
    800060ea:	0c053a03          	ld	s4,192(a0)
    800060ee:	0c853a83          	ld	s5,200(a0)
    800060f2:	0d053b03          	ld	s6,208(a0)
    800060f6:	0d853b83          	ld	s7,216(a0)
    800060fa:	0e053c03          	ld	s8,224(a0)
    800060fe:	0e853c83          	ld	s9,232(a0)
    80006102:	0f053d03          	ld	s10,240(a0)
    80006106:	0f853d83          	ld	s11,248(a0)
    8000610a:	10053e03          	ld	t3,256(a0)
    8000610e:	10853e83          	ld	t4,264(a0)
    80006112:	11053f03          	ld	t5,272(a0)
    80006116:	11853f83          	ld	t6,280(a0)
    8000611a:	7928                	ld	a0,112(a0)
    8000611c:	10200073          	sret
	...
