
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	ba013103          	ld	sp,-1120(sp) # 80008ba0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	bae70713          	addi	a4,a4,-1106 # 80008c00 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	ddc78793          	addi	a5,a5,-548 # 80005e40 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd4517>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de678793          	addi	a5,a5,-538 # 80000e94 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	43c080e7          	jalr	1084(ra) # 80002568 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	794080e7          	jalr	1940(ra) # 800008d0 <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	bb450513          	addi	a0,a0,-1100 # 80010d40 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a56080e7          	jalr	-1450(ra) # 80000bea <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	ba448493          	addi	s1,s1,-1116 # 80010d40 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	c3290913          	addi	s2,s2,-974 # 80010dd8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405b63          	blez	s4,8000022a <consoleread+0xc6>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71763          	bne	a4,a5,800001ee <consoleread+0x8a>
      if(killed(myproc())){
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	802080e7          	jalr	-2046(ra) # 800019c6 <myproc>
    800001cc:	00002097          	auipc	ra,0x2
    800001d0:	1e6080e7          	jalr	486(ra) # 800023b2 <killed>
    800001d4:	e535                	bnez	a0,80000240 <consoleread+0xdc>
      sleep(&cons.r, &cons.lock);
    800001d6:	85ce                	mv	a1,s3
    800001d8:	854a                	mv	a0,s2
    800001da:	00002097          	auipc	ra,0x2
    800001de:	f30080e7          	jalr	-208(ra) # 8000210a <sleep>
    while(cons.r == cons.w){
    800001e2:	0984a783          	lw	a5,152(s1)
    800001e6:	09c4a703          	lw	a4,156(s1)
    800001ea:	fcf70de3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ee:	0017871b          	addiw	a4,a5,1
    800001f2:	08e4ac23          	sw	a4,152(s1)
    800001f6:	07f7f713          	andi	a4,a5,127
    800001fa:	9726                	add	a4,a4,s1
    800001fc:	01874703          	lbu	a4,24(a4)
    80000200:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    80000204:	079c0663          	beq	s8,s9,80000270 <consoleread+0x10c>
    cbuf = c;
    80000208:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000020c:	4685                	li	a3,1
    8000020e:	f8f40613          	addi	a2,s0,-113
    80000212:	85d6                	mv	a1,s5
    80000214:	855a                	mv	a0,s6
    80000216:	00002097          	auipc	ra,0x2
    8000021a:	2fc080e7          	jalr	764(ra) # 80002512 <either_copyout>
    8000021e:	01a50663          	beq	a0,s10,8000022a <consoleread+0xc6>
    dst++;
    80000222:	0a85                	addi	s5,s5,1
    --n;
    80000224:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000226:	f9bc17e3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022a:	00011517          	auipc	a0,0x11
    8000022e:	b1650513          	addi	a0,a0,-1258 # 80010d40 <cons>
    80000232:	00001097          	auipc	ra,0x1
    80000236:	a6c080e7          	jalr	-1428(ra) # 80000c9e <release>

  return target - n;
    8000023a:	414b853b          	subw	a0,s7,s4
    8000023e:	a811                	j	80000252 <consoleread+0xee>
        release(&cons.lock);
    80000240:	00011517          	auipc	a0,0x11
    80000244:	b0050513          	addi	a0,a0,-1280 # 80010d40 <cons>
    80000248:	00001097          	auipc	ra,0x1
    8000024c:	a56080e7          	jalr	-1450(ra) # 80000c9e <release>
        return -1;
    80000250:	557d                	li	a0,-1
}
    80000252:	70e6                	ld	ra,120(sp)
    80000254:	7446                	ld	s0,112(sp)
    80000256:	74a6                	ld	s1,104(sp)
    80000258:	7906                	ld	s2,96(sp)
    8000025a:	69e6                	ld	s3,88(sp)
    8000025c:	6a46                	ld	s4,80(sp)
    8000025e:	6aa6                	ld	s5,72(sp)
    80000260:	6b06                	ld	s6,64(sp)
    80000262:	7be2                	ld	s7,56(sp)
    80000264:	7c42                	ld	s8,48(sp)
    80000266:	7ca2                	ld	s9,40(sp)
    80000268:	7d02                	ld	s10,32(sp)
    8000026a:	6de2                	ld	s11,24(sp)
    8000026c:	6109                	addi	sp,sp,128
    8000026e:	8082                	ret
      if(n < target){
    80000270:	000a071b          	sext.w	a4,s4
    80000274:	fb777be3          	bgeu	a4,s7,8000022a <consoleread+0xc6>
        cons.r--;
    80000278:	00011717          	auipc	a4,0x11
    8000027c:	b6f72023          	sw	a5,-1184(a4) # 80010dd8 <cons+0x98>
    80000280:	b76d                	j	8000022a <consoleread+0xc6>

0000000080000282 <consputc>:
{
    80000282:	1141                	addi	sp,sp,-16
    80000284:	e406                	sd	ra,8(sp)
    80000286:	e022                	sd	s0,0(sp)
    80000288:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000028a:	10000793          	li	a5,256
    8000028e:	00f50a63          	beq	a0,a5,800002a2 <consputc+0x20>
    uartputc_sync(c);
    80000292:	00000097          	auipc	ra,0x0
    80000296:	564080e7          	jalr	1380(ra) # 800007f6 <uartputc_sync>
}
    8000029a:	60a2                	ld	ra,8(sp)
    8000029c:	6402                	ld	s0,0(sp)
    8000029e:	0141                	addi	sp,sp,16
    800002a0:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a2:	4521                	li	a0,8
    800002a4:	00000097          	auipc	ra,0x0
    800002a8:	552080e7          	jalr	1362(ra) # 800007f6 <uartputc_sync>
    800002ac:	02000513          	li	a0,32
    800002b0:	00000097          	auipc	ra,0x0
    800002b4:	546080e7          	jalr	1350(ra) # 800007f6 <uartputc_sync>
    800002b8:	4521                	li	a0,8
    800002ba:	00000097          	auipc	ra,0x0
    800002be:	53c080e7          	jalr	1340(ra) # 800007f6 <uartputc_sync>
    800002c2:	bfe1                	j	8000029a <consputc+0x18>

00000000800002c4 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c4:	1101                	addi	sp,sp,-32
    800002c6:	ec06                	sd	ra,24(sp)
    800002c8:	e822                	sd	s0,16(sp)
    800002ca:	e426                	sd	s1,8(sp)
    800002cc:	e04a                	sd	s2,0(sp)
    800002ce:	1000                	addi	s0,sp,32
    800002d0:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d2:	00011517          	auipc	a0,0x11
    800002d6:	a6e50513          	addi	a0,a0,-1426 # 80010d40 <cons>
    800002da:	00001097          	auipc	ra,0x1
    800002de:	910080e7          	jalr	-1776(ra) # 80000bea <acquire>

  switch(c){
    800002e2:	47d5                	li	a5,21
    800002e4:	0af48663          	beq	s1,a5,80000390 <consoleintr+0xcc>
    800002e8:	0297ca63          	blt	a5,s1,8000031c <consoleintr+0x58>
    800002ec:	47a1                	li	a5,8
    800002ee:	0ef48763          	beq	s1,a5,800003dc <consoleintr+0x118>
    800002f2:	47c1                	li	a5,16
    800002f4:	10f49a63          	bne	s1,a5,80000408 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f8:	00002097          	auipc	ra,0x2
    800002fc:	2c6080e7          	jalr	710(ra) # 800025be <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000300:	00011517          	auipc	a0,0x11
    80000304:	a4050513          	addi	a0,a0,-1472 # 80010d40 <cons>
    80000308:	00001097          	auipc	ra,0x1
    8000030c:	996080e7          	jalr	-1642(ra) # 80000c9e <release>
}
    80000310:	60e2                	ld	ra,24(sp)
    80000312:	6442                	ld	s0,16(sp)
    80000314:	64a2                	ld	s1,8(sp)
    80000316:	6902                	ld	s2,0(sp)
    80000318:	6105                	addi	sp,sp,32
    8000031a:	8082                	ret
  switch(c){
    8000031c:	07f00793          	li	a5,127
    80000320:	0af48e63          	beq	s1,a5,800003dc <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000324:	00011717          	auipc	a4,0x11
    80000328:	a1c70713          	addi	a4,a4,-1508 # 80010d40 <cons>
    8000032c:	0a072783          	lw	a5,160(a4)
    80000330:	09872703          	lw	a4,152(a4)
    80000334:	9f99                	subw	a5,a5,a4
    80000336:	07f00713          	li	a4,127
    8000033a:	fcf763e3          	bltu	a4,a5,80000300 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000033e:	47b5                	li	a5,13
    80000340:	0cf48763          	beq	s1,a5,8000040e <consoleintr+0x14a>
      consputc(c);
    80000344:	8526                	mv	a0,s1
    80000346:	00000097          	auipc	ra,0x0
    8000034a:	f3c080e7          	jalr	-196(ra) # 80000282 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    8000034e:	00011797          	auipc	a5,0x11
    80000352:	9f278793          	addi	a5,a5,-1550 # 80010d40 <cons>
    80000356:	0a07a683          	lw	a3,160(a5)
    8000035a:	0016871b          	addiw	a4,a3,1
    8000035e:	0007061b          	sext.w	a2,a4
    80000362:	0ae7a023          	sw	a4,160(a5)
    80000366:	07f6f693          	andi	a3,a3,127
    8000036a:	97b6                	add	a5,a5,a3
    8000036c:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    80000370:	47a9                	li	a5,10
    80000372:	0cf48563          	beq	s1,a5,8000043c <consoleintr+0x178>
    80000376:	4791                	li	a5,4
    80000378:	0cf48263          	beq	s1,a5,8000043c <consoleintr+0x178>
    8000037c:	00011797          	auipc	a5,0x11
    80000380:	a5c7a783          	lw	a5,-1444(a5) # 80010dd8 <cons+0x98>
    80000384:	9f1d                	subw	a4,a4,a5
    80000386:	08000793          	li	a5,128
    8000038a:	f6f71be3          	bne	a4,a5,80000300 <consoleintr+0x3c>
    8000038e:	a07d                	j	8000043c <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000390:	00011717          	auipc	a4,0x11
    80000394:	9b070713          	addi	a4,a4,-1616 # 80010d40 <cons>
    80000398:	0a072783          	lw	a5,160(a4)
    8000039c:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a0:	00011497          	auipc	s1,0x11
    800003a4:	9a048493          	addi	s1,s1,-1632 # 80010d40 <cons>
    while(cons.e != cons.w &&
    800003a8:	4929                	li	s2,10
    800003aa:	f4f70be3          	beq	a4,a5,80000300 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003ae:	37fd                	addiw	a5,a5,-1
    800003b0:	07f7f713          	andi	a4,a5,127
    800003b4:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b6:	01874703          	lbu	a4,24(a4)
    800003ba:	f52703e3          	beq	a4,s2,80000300 <consoleintr+0x3c>
      cons.e--;
    800003be:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c2:	10000513          	li	a0,256
    800003c6:	00000097          	auipc	ra,0x0
    800003ca:	ebc080e7          	jalr	-324(ra) # 80000282 <consputc>
    while(cons.e != cons.w &&
    800003ce:	0a04a783          	lw	a5,160(s1)
    800003d2:	09c4a703          	lw	a4,156(s1)
    800003d6:	fcf71ce3          	bne	a4,a5,800003ae <consoleintr+0xea>
    800003da:	b71d                	j	80000300 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003dc:	00011717          	auipc	a4,0x11
    800003e0:	96470713          	addi	a4,a4,-1692 # 80010d40 <cons>
    800003e4:	0a072783          	lw	a5,160(a4)
    800003e8:	09c72703          	lw	a4,156(a4)
    800003ec:	f0f70ae3          	beq	a4,a5,80000300 <consoleintr+0x3c>
      cons.e--;
    800003f0:	37fd                	addiw	a5,a5,-1
    800003f2:	00011717          	auipc	a4,0x11
    800003f6:	9ef72723          	sw	a5,-1554(a4) # 80010de0 <cons+0xa0>
      consputc(BACKSPACE);
    800003fa:	10000513          	li	a0,256
    800003fe:	00000097          	auipc	ra,0x0
    80000402:	e84080e7          	jalr	-380(ra) # 80000282 <consputc>
    80000406:	bded                	j	80000300 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000408:	ee048ce3          	beqz	s1,80000300 <consoleintr+0x3c>
    8000040c:	bf21                	j	80000324 <consoleintr+0x60>
      consputc(c);
    8000040e:	4529                	li	a0,10
    80000410:	00000097          	auipc	ra,0x0
    80000414:	e72080e7          	jalr	-398(ra) # 80000282 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000418:	00011797          	auipc	a5,0x11
    8000041c:	92878793          	addi	a5,a5,-1752 # 80010d40 <cons>
    80000420:	0a07a703          	lw	a4,160(a5)
    80000424:	0017069b          	addiw	a3,a4,1
    80000428:	0006861b          	sext.w	a2,a3
    8000042c:	0ad7a023          	sw	a3,160(a5)
    80000430:	07f77713          	andi	a4,a4,127
    80000434:	97ba                	add	a5,a5,a4
    80000436:	4729                	li	a4,10
    80000438:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    8000043c:	00011797          	auipc	a5,0x11
    80000440:	9ac7a023          	sw	a2,-1632(a5) # 80010ddc <cons+0x9c>
        wakeup(&cons.r);
    80000444:	00011517          	auipc	a0,0x11
    80000448:	99450513          	addi	a0,a0,-1644 # 80010dd8 <cons+0x98>
    8000044c:	00002097          	auipc	ra,0x2
    80000450:	d22080e7          	jalr	-734(ra) # 8000216e <wakeup>
    80000454:	b575                	j	80000300 <consoleintr+0x3c>

0000000080000456 <consoleinit>:

void
consoleinit(void)
{
    80000456:	1141                	addi	sp,sp,-16
    80000458:	e406                	sd	ra,8(sp)
    8000045a:	e022                	sd	s0,0(sp)
    8000045c:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000045e:	00008597          	auipc	a1,0x8
    80000462:	bb258593          	addi	a1,a1,-1102 # 80008010 <etext+0x10>
    80000466:	00011517          	auipc	a0,0x11
    8000046a:	8da50513          	addi	a0,a0,-1830 # 80010d40 <cons>
    8000046e:	00000097          	auipc	ra,0x0
    80000472:	6ec080e7          	jalr	1772(ra) # 80000b5a <initlock>

  uartinit();
    80000476:	00000097          	auipc	ra,0x0
    8000047a:	330080e7          	jalr	816(ra) # 800007a6 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047e:	00029797          	auipc	a5,0x29
    80000482:	cd278793          	addi	a5,a5,-814 # 80029150 <devsw>
    80000486:	00000717          	auipc	a4,0x0
    8000048a:	cde70713          	addi	a4,a4,-802 # 80000164 <consoleread>
    8000048e:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000490:	00000717          	auipc	a4,0x0
    80000494:	c7270713          	addi	a4,a4,-910 # 80000102 <consolewrite>
    80000498:	ef98                	sd	a4,24(a5)
}
    8000049a:	60a2                	ld	ra,8(sp)
    8000049c:	6402                	ld	s0,0(sp)
    8000049e:	0141                	addi	sp,sp,16
    800004a0:	8082                	ret

00000000800004a2 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a2:	7179                	addi	sp,sp,-48
    800004a4:	f406                	sd	ra,40(sp)
    800004a6:	f022                	sd	s0,32(sp)
    800004a8:	ec26                	sd	s1,24(sp)
    800004aa:	e84a                	sd	s2,16(sp)
    800004ac:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004ae:	c219                	beqz	a2,800004b4 <printint+0x12>
    800004b0:	08054663          	bltz	a0,8000053c <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b4:	2501                	sext.w	a0,a0
    800004b6:	4881                	li	a7,0
    800004b8:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004bc:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004be:	2581                	sext.w	a1,a1
    800004c0:	00008617          	auipc	a2,0x8
    800004c4:	b8060613          	addi	a2,a2,-1152 # 80008040 <digits>
    800004c8:	883a                	mv	a6,a4
    800004ca:	2705                	addiw	a4,a4,1
    800004cc:	02b577bb          	remuw	a5,a0,a1
    800004d0:	1782                	slli	a5,a5,0x20
    800004d2:	9381                	srli	a5,a5,0x20
    800004d4:	97b2                	add	a5,a5,a2
    800004d6:	0007c783          	lbu	a5,0(a5)
    800004da:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004de:	0005079b          	sext.w	a5,a0
    800004e2:	02b5553b          	divuw	a0,a0,a1
    800004e6:	0685                	addi	a3,a3,1
    800004e8:	feb7f0e3          	bgeu	a5,a1,800004c8 <printint+0x26>

  if(sign)
    800004ec:	00088b63          	beqz	a7,80000502 <printint+0x60>
    buf[i++] = '-';
    800004f0:	fe040793          	addi	a5,s0,-32
    800004f4:	973e                	add	a4,a4,a5
    800004f6:	02d00793          	li	a5,45
    800004fa:	fef70823          	sb	a5,-16(a4)
    800004fe:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000502:	02e05763          	blez	a4,80000530 <printint+0x8e>
    80000506:	fd040793          	addi	a5,s0,-48
    8000050a:	00e784b3          	add	s1,a5,a4
    8000050e:	fff78913          	addi	s2,a5,-1
    80000512:	993a                	add	s2,s2,a4
    80000514:	377d                	addiw	a4,a4,-1
    80000516:	1702                	slli	a4,a4,0x20
    80000518:	9301                	srli	a4,a4,0x20
    8000051a:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051e:	fff4c503          	lbu	a0,-1(s1)
    80000522:	00000097          	auipc	ra,0x0
    80000526:	d60080e7          	jalr	-672(ra) # 80000282 <consputc>
  while(--i >= 0)
    8000052a:	14fd                	addi	s1,s1,-1
    8000052c:	ff2499e3          	bne	s1,s2,8000051e <printint+0x7c>
}
    80000530:	70a2                	ld	ra,40(sp)
    80000532:	7402                	ld	s0,32(sp)
    80000534:	64e2                	ld	s1,24(sp)
    80000536:	6942                	ld	s2,16(sp)
    80000538:	6145                	addi	sp,sp,48
    8000053a:	8082                	ret
    x = -xx;
    8000053c:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000540:	4885                	li	a7,1
    x = -xx;
    80000542:	bf9d                	j	800004b8 <printint+0x16>

0000000080000544 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000544:	1101                	addi	sp,sp,-32
    80000546:	ec06                	sd	ra,24(sp)
    80000548:	e822                	sd	s0,16(sp)
    8000054a:	e426                	sd	s1,8(sp)
    8000054c:	1000                	addi	s0,sp,32
    8000054e:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000550:	00011797          	auipc	a5,0x11
    80000554:	8a07a823          	sw	zero,-1872(a5) # 80010e00 <pr+0x18>
  printf("panic: ");
    80000558:	00008517          	auipc	a0,0x8
    8000055c:	ac050513          	addi	a0,a0,-1344 # 80008018 <etext+0x18>
    80000560:	00000097          	auipc	ra,0x0
    80000564:	02e080e7          	jalr	46(ra) # 8000058e <printf>
  printf(s);
    80000568:	8526                	mv	a0,s1
    8000056a:	00000097          	auipc	ra,0x0
    8000056e:	024080e7          	jalr	36(ra) # 8000058e <printf>
  printf("\n");
    80000572:	00008517          	auipc	a0,0x8
    80000576:	b5650513          	addi	a0,a0,-1194 # 800080c8 <digits+0x88>
    8000057a:	00000097          	auipc	ra,0x0
    8000057e:	014080e7          	jalr	20(ra) # 8000058e <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000582:	4785                	li	a5,1
    80000584:	00008717          	auipc	a4,0x8
    80000588:	62f72e23          	sw	a5,1596(a4) # 80008bc0 <panicked>
  for(;;)
    8000058c:	a001                	j	8000058c <panic+0x48>

000000008000058e <printf>:
{
    8000058e:	7131                	addi	sp,sp,-192
    80000590:	fc86                	sd	ra,120(sp)
    80000592:	f8a2                	sd	s0,112(sp)
    80000594:	f4a6                	sd	s1,104(sp)
    80000596:	f0ca                	sd	s2,96(sp)
    80000598:	ecce                	sd	s3,88(sp)
    8000059a:	e8d2                	sd	s4,80(sp)
    8000059c:	e4d6                	sd	s5,72(sp)
    8000059e:	e0da                	sd	s6,64(sp)
    800005a0:	fc5e                	sd	s7,56(sp)
    800005a2:	f862                	sd	s8,48(sp)
    800005a4:	f466                	sd	s9,40(sp)
    800005a6:	f06a                	sd	s10,32(sp)
    800005a8:	ec6e                	sd	s11,24(sp)
    800005aa:	0100                	addi	s0,sp,128
    800005ac:	8a2a                	mv	s4,a0
    800005ae:	e40c                	sd	a1,8(s0)
    800005b0:	e810                	sd	a2,16(s0)
    800005b2:	ec14                	sd	a3,24(s0)
    800005b4:	f018                	sd	a4,32(s0)
    800005b6:	f41c                	sd	a5,40(s0)
    800005b8:	03043823          	sd	a6,48(s0)
    800005bc:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005c0:	00011d97          	auipc	s11,0x11
    800005c4:	840dad83          	lw	s11,-1984(s11) # 80010e00 <pr+0x18>
  if(locking)
    800005c8:	020d9b63          	bnez	s11,800005fe <printf+0x70>
  if (fmt == 0)
    800005cc:	040a0263          	beqz	s4,80000610 <printf+0x82>
  va_start(ap, fmt);
    800005d0:	00840793          	addi	a5,s0,8
    800005d4:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d8:	000a4503          	lbu	a0,0(s4)
    800005dc:	16050263          	beqz	a0,80000740 <printf+0x1b2>
    800005e0:	4481                	li	s1,0
    if(c != '%'){
    800005e2:	02500a93          	li	s5,37
    switch(c){
    800005e6:	07000b13          	li	s6,112
  consputc('x');
    800005ea:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005ec:	00008b97          	auipc	s7,0x8
    800005f0:	a54b8b93          	addi	s7,s7,-1452 # 80008040 <digits>
    switch(c){
    800005f4:	07300c93          	li	s9,115
    800005f8:	06400c13          	li	s8,100
    800005fc:	a82d                	j	80000636 <printf+0xa8>
    acquire(&pr.lock);
    800005fe:	00010517          	auipc	a0,0x10
    80000602:	7ea50513          	addi	a0,a0,2026 # 80010de8 <pr>
    80000606:	00000097          	auipc	ra,0x0
    8000060a:	5e4080e7          	jalr	1508(ra) # 80000bea <acquire>
    8000060e:	bf7d                	j	800005cc <printf+0x3e>
    panic("null fmt");
    80000610:	00008517          	auipc	a0,0x8
    80000614:	a1850513          	addi	a0,a0,-1512 # 80008028 <etext+0x28>
    80000618:	00000097          	auipc	ra,0x0
    8000061c:	f2c080e7          	jalr	-212(ra) # 80000544 <panic>
      consputc(c);
    80000620:	00000097          	auipc	ra,0x0
    80000624:	c62080e7          	jalr	-926(ra) # 80000282 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000628:	2485                	addiw	s1,s1,1
    8000062a:	009a07b3          	add	a5,s4,s1
    8000062e:	0007c503          	lbu	a0,0(a5)
    80000632:	10050763          	beqz	a0,80000740 <printf+0x1b2>
    if(c != '%'){
    80000636:	ff5515e3          	bne	a0,s5,80000620 <printf+0x92>
    c = fmt[++i] & 0xff;
    8000063a:	2485                	addiw	s1,s1,1
    8000063c:	009a07b3          	add	a5,s4,s1
    80000640:	0007c783          	lbu	a5,0(a5)
    80000644:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000648:	cfe5                	beqz	a5,80000740 <printf+0x1b2>
    switch(c){
    8000064a:	05678a63          	beq	a5,s6,8000069e <printf+0x110>
    8000064e:	02fb7663          	bgeu	s6,a5,8000067a <printf+0xec>
    80000652:	09978963          	beq	a5,s9,800006e4 <printf+0x156>
    80000656:	07800713          	li	a4,120
    8000065a:	0ce79863          	bne	a5,a4,8000072a <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    8000065e:	f8843783          	ld	a5,-120(s0)
    80000662:	00878713          	addi	a4,a5,8
    80000666:	f8e43423          	sd	a4,-120(s0)
    8000066a:	4605                	li	a2,1
    8000066c:	85ea                	mv	a1,s10
    8000066e:	4388                	lw	a0,0(a5)
    80000670:	00000097          	auipc	ra,0x0
    80000674:	e32080e7          	jalr	-462(ra) # 800004a2 <printint>
      break;
    80000678:	bf45                	j	80000628 <printf+0x9a>
    switch(c){
    8000067a:	0b578263          	beq	a5,s5,8000071e <printf+0x190>
    8000067e:	0b879663          	bne	a5,s8,8000072a <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    80000682:	f8843783          	ld	a5,-120(s0)
    80000686:	00878713          	addi	a4,a5,8
    8000068a:	f8e43423          	sd	a4,-120(s0)
    8000068e:	4605                	li	a2,1
    80000690:	45a9                	li	a1,10
    80000692:	4388                	lw	a0,0(a5)
    80000694:	00000097          	auipc	ra,0x0
    80000698:	e0e080e7          	jalr	-498(ra) # 800004a2 <printint>
      break;
    8000069c:	b771                	j	80000628 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069e:	f8843783          	ld	a5,-120(s0)
    800006a2:	00878713          	addi	a4,a5,8
    800006a6:	f8e43423          	sd	a4,-120(s0)
    800006aa:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006ae:	03000513          	li	a0,48
    800006b2:	00000097          	auipc	ra,0x0
    800006b6:	bd0080e7          	jalr	-1072(ra) # 80000282 <consputc>
  consputc('x');
    800006ba:	07800513          	li	a0,120
    800006be:	00000097          	auipc	ra,0x0
    800006c2:	bc4080e7          	jalr	-1084(ra) # 80000282 <consputc>
    800006c6:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c8:	03c9d793          	srli	a5,s3,0x3c
    800006cc:	97de                	add	a5,a5,s7
    800006ce:	0007c503          	lbu	a0,0(a5)
    800006d2:	00000097          	auipc	ra,0x0
    800006d6:	bb0080e7          	jalr	-1104(ra) # 80000282 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006da:	0992                	slli	s3,s3,0x4
    800006dc:	397d                	addiw	s2,s2,-1
    800006de:	fe0915e3          	bnez	s2,800006c8 <printf+0x13a>
    800006e2:	b799                	j	80000628 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e4:	f8843783          	ld	a5,-120(s0)
    800006e8:	00878713          	addi	a4,a5,8
    800006ec:	f8e43423          	sd	a4,-120(s0)
    800006f0:	0007b903          	ld	s2,0(a5)
    800006f4:	00090e63          	beqz	s2,80000710 <printf+0x182>
      for(; *s; s++)
    800006f8:	00094503          	lbu	a0,0(s2)
    800006fc:	d515                	beqz	a0,80000628 <printf+0x9a>
        consputc(*s);
    800006fe:	00000097          	auipc	ra,0x0
    80000702:	b84080e7          	jalr	-1148(ra) # 80000282 <consputc>
      for(; *s; s++)
    80000706:	0905                	addi	s2,s2,1
    80000708:	00094503          	lbu	a0,0(s2)
    8000070c:	f96d                	bnez	a0,800006fe <printf+0x170>
    8000070e:	bf29                	j	80000628 <printf+0x9a>
        s = "(null)";
    80000710:	00008917          	auipc	s2,0x8
    80000714:	91090913          	addi	s2,s2,-1776 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000718:	02800513          	li	a0,40
    8000071c:	b7cd                	j	800006fe <printf+0x170>
      consputc('%');
    8000071e:	8556                	mv	a0,s5
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b62080e7          	jalr	-1182(ra) # 80000282 <consputc>
      break;
    80000728:	b701                	j	80000628 <printf+0x9a>
      consputc('%');
    8000072a:	8556                	mv	a0,s5
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b56080e7          	jalr	-1194(ra) # 80000282 <consputc>
      consputc(c);
    80000734:	854a                	mv	a0,s2
    80000736:	00000097          	auipc	ra,0x0
    8000073a:	b4c080e7          	jalr	-1204(ra) # 80000282 <consputc>
      break;
    8000073e:	b5ed                	j	80000628 <printf+0x9a>
  if(locking)
    80000740:	020d9163          	bnez	s11,80000762 <printf+0x1d4>
}
    80000744:	70e6                	ld	ra,120(sp)
    80000746:	7446                	ld	s0,112(sp)
    80000748:	74a6                	ld	s1,104(sp)
    8000074a:	7906                	ld	s2,96(sp)
    8000074c:	69e6                	ld	s3,88(sp)
    8000074e:	6a46                	ld	s4,80(sp)
    80000750:	6aa6                	ld	s5,72(sp)
    80000752:	6b06                	ld	s6,64(sp)
    80000754:	7be2                	ld	s7,56(sp)
    80000756:	7c42                	ld	s8,48(sp)
    80000758:	7ca2                	ld	s9,40(sp)
    8000075a:	7d02                	ld	s10,32(sp)
    8000075c:	6de2                	ld	s11,24(sp)
    8000075e:	6129                	addi	sp,sp,192
    80000760:	8082                	ret
    release(&pr.lock);
    80000762:	00010517          	auipc	a0,0x10
    80000766:	68650513          	addi	a0,a0,1670 # 80010de8 <pr>
    8000076a:	00000097          	auipc	ra,0x0
    8000076e:	534080e7          	jalr	1332(ra) # 80000c9e <release>
}
    80000772:	bfc9                	j	80000744 <printf+0x1b6>

0000000080000774 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000774:	1101                	addi	sp,sp,-32
    80000776:	ec06                	sd	ra,24(sp)
    80000778:	e822                	sd	s0,16(sp)
    8000077a:	e426                	sd	s1,8(sp)
    8000077c:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000077e:	00010497          	auipc	s1,0x10
    80000782:	66a48493          	addi	s1,s1,1642 # 80010de8 <pr>
    80000786:	00008597          	auipc	a1,0x8
    8000078a:	8b258593          	addi	a1,a1,-1870 # 80008038 <etext+0x38>
    8000078e:	8526                	mv	a0,s1
    80000790:	00000097          	auipc	ra,0x0
    80000794:	3ca080e7          	jalr	970(ra) # 80000b5a <initlock>
  pr.locking = 1;
    80000798:	4785                	li	a5,1
    8000079a:	cc9c                	sw	a5,24(s1)
}
    8000079c:	60e2                	ld	ra,24(sp)
    8000079e:	6442                	ld	s0,16(sp)
    800007a0:	64a2                	ld	s1,8(sp)
    800007a2:	6105                	addi	sp,sp,32
    800007a4:	8082                	ret

00000000800007a6 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a6:	1141                	addi	sp,sp,-16
    800007a8:	e406                	sd	ra,8(sp)
    800007aa:	e022                	sd	s0,0(sp)
    800007ac:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007ae:	100007b7          	lui	a5,0x10000
    800007b2:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b6:	f8000713          	li	a4,-128
    800007ba:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007be:	470d                	li	a4,3
    800007c0:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007c4:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c8:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007cc:	469d                	li	a3,7
    800007ce:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007d2:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d6:	00008597          	auipc	a1,0x8
    800007da:	88258593          	addi	a1,a1,-1918 # 80008058 <digits+0x18>
    800007de:	00010517          	auipc	a0,0x10
    800007e2:	62a50513          	addi	a0,a0,1578 # 80010e08 <uart_tx_lock>
    800007e6:	00000097          	auipc	ra,0x0
    800007ea:	374080e7          	jalr	884(ra) # 80000b5a <initlock>
}
    800007ee:	60a2                	ld	ra,8(sp)
    800007f0:	6402                	ld	s0,0(sp)
    800007f2:	0141                	addi	sp,sp,16
    800007f4:	8082                	ret

00000000800007f6 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f6:	1101                	addi	sp,sp,-32
    800007f8:	ec06                	sd	ra,24(sp)
    800007fa:	e822                	sd	s0,16(sp)
    800007fc:	e426                	sd	s1,8(sp)
    800007fe:	1000                	addi	s0,sp,32
    80000800:	84aa                	mv	s1,a0
  push_off();
    80000802:	00000097          	auipc	ra,0x0
    80000806:	39c080e7          	jalr	924(ra) # 80000b9e <push_off>

  if(panicked){
    8000080a:	00008797          	auipc	a5,0x8
    8000080e:	3b67a783          	lw	a5,950(a5) # 80008bc0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000812:	10000737          	lui	a4,0x10000
  if(panicked){
    80000816:	c391                	beqz	a5,8000081a <uartputc_sync+0x24>
    for(;;)
    80000818:	a001                	j	80000818 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081a:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000081e:	0ff7f793          	andi	a5,a5,255
    80000822:	0207f793          	andi	a5,a5,32
    80000826:	dbf5                	beqz	a5,8000081a <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000828:	0ff4f793          	andi	a5,s1,255
    8000082c:	10000737          	lui	a4,0x10000
    80000830:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000834:	00000097          	auipc	ra,0x0
    80000838:	40a080e7          	jalr	1034(ra) # 80000c3e <pop_off>
}
    8000083c:	60e2                	ld	ra,24(sp)
    8000083e:	6442                	ld	s0,16(sp)
    80000840:	64a2                	ld	s1,8(sp)
    80000842:	6105                	addi	sp,sp,32
    80000844:	8082                	ret

0000000080000846 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000846:	00008717          	auipc	a4,0x8
    8000084a:	38273703          	ld	a4,898(a4) # 80008bc8 <uart_tx_r>
    8000084e:	00008797          	auipc	a5,0x8
    80000852:	3827b783          	ld	a5,898(a5) # 80008bd0 <uart_tx_w>
    80000856:	06e78c63          	beq	a5,a4,800008ce <uartstart+0x88>
{
    8000085a:	7139                	addi	sp,sp,-64
    8000085c:	fc06                	sd	ra,56(sp)
    8000085e:	f822                	sd	s0,48(sp)
    80000860:	f426                	sd	s1,40(sp)
    80000862:	f04a                	sd	s2,32(sp)
    80000864:	ec4e                	sd	s3,24(sp)
    80000866:	e852                	sd	s4,16(sp)
    80000868:	e456                	sd	s5,8(sp)
    8000086a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000086c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000870:	00010a17          	auipc	s4,0x10
    80000874:	598a0a13          	addi	s4,s4,1432 # 80010e08 <uart_tx_lock>
    uart_tx_r += 1;
    80000878:	00008497          	auipc	s1,0x8
    8000087c:	35048493          	addi	s1,s1,848 # 80008bc8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000880:	00008997          	auipc	s3,0x8
    80000884:	35098993          	addi	s3,s3,848 # 80008bd0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000888:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000088c:	0ff7f793          	andi	a5,a5,255
    80000890:	0207f793          	andi	a5,a5,32
    80000894:	c785                	beqz	a5,800008bc <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000896:	01f77793          	andi	a5,a4,31
    8000089a:	97d2                	add	a5,a5,s4
    8000089c:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    800008a0:	0705                	addi	a4,a4,1
    800008a2:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008a4:	8526                	mv	a0,s1
    800008a6:	00002097          	auipc	ra,0x2
    800008aa:	8c8080e7          	jalr	-1848(ra) # 8000216e <wakeup>
    
    WriteReg(THR, c);
    800008ae:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008b2:	6098                	ld	a4,0(s1)
    800008b4:	0009b783          	ld	a5,0(s3)
    800008b8:	fce798e3          	bne	a5,a4,80000888 <uartstart+0x42>
  }
}
    800008bc:	70e2                	ld	ra,56(sp)
    800008be:	7442                	ld	s0,48(sp)
    800008c0:	74a2                	ld	s1,40(sp)
    800008c2:	7902                	ld	s2,32(sp)
    800008c4:	69e2                	ld	s3,24(sp)
    800008c6:	6a42                	ld	s4,16(sp)
    800008c8:	6aa2                	ld	s5,8(sp)
    800008ca:	6121                	addi	sp,sp,64
    800008cc:	8082                	ret
    800008ce:	8082                	ret

00000000800008d0 <uartputc>:
{
    800008d0:	7179                	addi	sp,sp,-48
    800008d2:	f406                	sd	ra,40(sp)
    800008d4:	f022                	sd	s0,32(sp)
    800008d6:	ec26                	sd	s1,24(sp)
    800008d8:	e84a                	sd	s2,16(sp)
    800008da:	e44e                	sd	s3,8(sp)
    800008dc:	e052                	sd	s4,0(sp)
    800008de:	1800                	addi	s0,sp,48
    800008e0:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008e2:	00010517          	auipc	a0,0x10
    800008e6:	52650513          	addi	a0,a0,1318 # 80010e08 <uart_tx_lock>
    800008ea:	00000097          	auipc	ra,0x0
    800008ee:	300080e7          	jalr	768(ra) # 80000bea <acquire>
  if(panicked){
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	2ce7a783          	lw	a5,718(a5) # 80008bc0 <panicked>
    800008fa:	e7c9                	bnez	a5,80000984 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fc:	00008797          	auipc	a5,0x8
    80000900:	2d47b783          	ld	a5,724(a5) # 80008bd0 <uart_tx_w>
    80000904:	00008717          	auipc	a4,0x8
    80000908:	2c473703          	ld	a4,708(a4) # 80008bc8 <uart_tx_r>
    8000090c:	02070713          	addi	a4,a4,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00010a17          	auipc	s4,0x10
    80000914:	4f8a0a13          	addi	s4,s4,1272 # 80010e08 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	2b048493          	addi	s1,s1,688 # 80008bc8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	2b090913          	addi	s2,s2,688 # 80008bd0 <uart_tx_w>
    80000928:	00f71f63          	bne	a4,a5,80000946 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000092c:	85d2                	mv	a1,s4
    8000092e:	8526                	mv	a0,s1
    80000930:	00001097          	auipc	ra,0x1
    80000934:	7da080e7          	jalr	2010(ra) # 8000210a <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000938:	00093783          	ld	a5,0(s2)
    8000093c:	6098                	ld	a4,0(s1)
    8000093e:	02070713          	addi	a4,a4,32
    80000942:	fef705e3          	beq	a4,a5,8000092c <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000946:	00010497          	auipc	s1,0x10
    8000094a:	4c248493          	addi	s1,s1,1218 # 80010e08 <uart_tx_lock>
    8000094e:	01f7f713          	andi	a4,a5,31
    80000952:	9726                	add	a4,a4,s1
    80000954:	01370c23          	sb	s3,24(a4)
  uart_tx_w += 1;
    80000958:	0785                	addi	a5,a5,1
    8000095a:	00008717          	auipc	a4,0x8
    8000095e:	26f73b23          	sd	a5,630(a4) # 80008bd0 <uart_tx_w>
  uartstart();
    80000962:	00000097          	auipc	ra,0x0
    80000966:	ee4080e7          	jalr	-284(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    8000096a:	8526                	mv	a0,s1
    8000096c:	00000097          	auipc	ra,0x0
    80000970:	332080e7          	jalr	818(ra) # 80000c9e <release>
}
    80000974:	70a2                	ld	ra,40(sp)
    80000976:	7402                	ld	s0,32(sp)
    80000978:	64e2                	ld	s1,24(sp)
    8000097a:	6942                	ld	s2,16(sp)
    8000097c:	69a2                	ld	s3,8(sp)
    8000097e:	6a02                	ld	s4,0(sp)
    80000980:	6145                	addi	sp,sp,48
    80000982:	8082                	ret
    for(;;)
    80000984:	a001                	j	80000984 <uartputc+0xb4>

0000000080000986 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000986:	1141                	addi	sp,sp,-16
    80000988:	e422                	sd	s0,8(sp)
    8000098a:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000098c:	100007b7          	lui	a5,0x10000
    80000990:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000994:	8b85                	andi	a5,a5,1
    80000996:	cb91                	beqz	a5,800009aa <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000998:	100007b7          	lui	a5,0x10000
    8000099c:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009a0:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009a4:	6422                	ld	s0,8(sp)
    800009a6:	0141                	addi	sp,sp,16
    800009a8:	8082                	ret
    return -1;
    800009aa:	557d                	li	a0,-1
    800009ac:	bfe5                	j	800009a4 <uartgetc+0x1e>

00000000800009ae <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    800009ae:	1101                	addi	sp,sp,-32
    800009b0:	ec06                	sd	ra,24(sp)
    800009b2:	e822                	sd	s0,16(sp)
    800009b4:	e426                	sd	s1,8(sp)
    800009b6:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b8:	54fd                	li	s1,-1
    int c = uartgetc();
    800009ba:	00000097          	auipc	ra,0x0
    800009be:	fcc080e7          	jalr	-52(ra) # 80000986 <uartgetc>
    if(c == -1)
    800009c2:	00950763          	beq	a0,s1,800009d0 <uartintr+0x22>
      break;
    consoleintr(c);
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	8fe080e7          	jalr	-1794(ra) # 800002c4 <consoleintr>
  while(1){
    800009ce:	b7f5                	j	800009ba <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009d0:	00010497          	auipc	s1,0x10
    800009d4:	43848493          	addi	s1,s1,1080 # 80010e08 <uart_tx_lock>
    800009d8:	8526                	mv	a0,s1
    800009da:	00000097          	auipc	ra,0x0
    800009de:	210080e7          	jalr	528(ra) # 80000bea <acquire>
  uartstart();
    800009e2:	00000097          	auipc	ra,0x0
    800009e6:	e64080e7          	jalr	-412(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    800009ea:	8526                	mv	a0,s1
    800009ec:	00000097          	auipc	ra,0x0
    800009f0:	2b2080e7          	jalr	690(ra) # 80000c9e <release>
}
    800009f4:	60e2                	ld	ra,24(sp)
    800009f6:	6442                	ld	s0,16(sp)
    800009f8:	64a2                	ld	s1,8(sp)
    800009fa:	6105                	addi	sp,sp,32
    800009fc:	8082                	ret

00000000800009fe <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009fe:	1101                	addi	sp,sp,-32
    80000a00:	ec06                	sd	ra,24(sp)
    80000a02:	e822                	sd	s0,16(sp)
    80000a04:	e426                	sd	s1,8(sp)
    80000a06:	e04a                	sd	s2,0(sp)
    80000a08:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a0a:	03451793          	slli	a5,a0,0x34
    80000a0e:	ebb9                	bnez	a5,80000a64 <kfree+0x66>
    80000a10:	84aa                	mv	s1,a0
    80000a12:	0002a797          	auipc	a5,0x2a
    80000a16:	8d678793          	addi	a5,a5,-1834 # 8002a2e8 <end>
    80000a1a:	04f56563          	bltu	a0,a5,80000a64 <kfree+0x66>
    80000a1e:	47c5                	li	a5,17
    80000a20:	07ee                	slli	a5,a5,0x1b
    80000a22:	04f57163          	bgeu	a0,a5,80000a64 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a26:	6605                	lui	a2,0x1
    80000a28:	4585                	li	a1,1
    80000a2a:	00000097          	auipc	ra,0x0
    80000a2e:	2bc080e7          	jalr	700(ra) # 80000ce6 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a32:	00010917          	auipc	s2,0x10
    80000a36:	40e90913          	addi	s2,s2,1038 # 80010e40 <kmem>
    80000a3a:	854a                	mv	a0,s2
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	1ae080e7          	jalr	430(ra) # 80000bea <acquire>
  r->next = kmem.freelist;
    80000a44:	01893783          	ld	a5,24(s2)
    80000a48:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a4a:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a4e:	854a                	mv	a0,s2
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	24e080e7          	jalr	590(ra) # 80000c9e <release>
}
    80000a58:	60e2                	ld	ra,24(sp)
    80000a5a:	6442                	ld	s0,16(sp)
    80000a5c:	64a2                	ld	s1,8(sp)
    80000a5e:	6902                	ld	s2,0(sp)
    80000a60:	6105                	addi	sp,sp,32
    80000a62:	8082                	ret
    panic("kfree");
    80000a64:	00007517          	auipc	a0,0x7
    80000a68:	5fc50513          	addi	a0,a0,1532 # 80008060 <digits+0x20>
    80000a6c:	00000097          	auipc	ra,0x0
    80000a70:	ad8080e7          	jalr	-1320(ra) # 80000544 <panic>

0000000080000a74 <freerange>:
{
    80000a74:	7179                	addi	sp,sp,-48
    80000a76:	f406                	sd	ra,40(sp)
    80000a78:	f022                	sd	s0,32(sp)
    80000a7a:	ec26                	sd	s1,24(sp)
    80000a7c:	e84a                	sd	s2,16(sp)
    80000a7e:	e44e                	sd	s3,8(sp)
    80000a80:	e052                	sd	s4,0(sp)
    80000a82:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a84:	6785                	lui	a5,0x1
    80000a86:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a8a:	94aa                	add	s1,s1,a0
    80000a8c:	757d                	lui	a0,0xfffff
    80000a8e:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a90:	94be                	add	s1,s1,a5
    80000a92:	0095ee63          	bltu	a1,s1,80000aae <freerange+0x3a>
    80000a96:	892e                	mv	s2,a1
    kfree(p);
    80000a98:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a9a:	6985                	lui	s3,0x1
    kfree(p);
    80000a9c:	01448533          	add	a0,s1,s4
    80000aa0:	00000097          	auipc	ra,0x0
    80000aa4:	f5e080e7          	jalr	-162(ra) # 800009fe <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa8:	94ce                	add	s1,s1,s3
    80000aaa:	fe9979e3          	bgeu	s2,s1,80000a9c <freerange+0x28>
}
    80000aae:	70a2                	ld	ra,40(sp)
    80000ab0:	7402                	ld	s0,32(sp)
    80000ab2:	64e2                	ld	s1,24(sp)
    80000ab4:	6942                	ld	s2,16(sp)
    80000ab6:	69a2                	ld	s3,8(sp)
    80000ab8:	6a02                	ld	s4,0(sp)
    80000aba:	6145                	addi	sp,sp,48
    80000abc:	8082                	ret

0000000080000abe <kinit>:
{
    80000abe:	1141                	addi	sp,sp,-16
    80000ac0:	e406                	sd	ra,8(sp)
    80000ac2:	e022                	sd	s0,0(sp)
    80000ac4:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac6:	00007597          	auipc	a1,0x7
    80000aca:	5a258593          	addi	a1,a1,1442 # 80008068 <digits+0x28>
    80000ace:	00010517          	auipc	a0,0x10
    80000ad2:	37250513          	addi	a0,a0,882 # 80010e40 <kmem>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	084080e7          	jalr	132(ra) # 80000b5a <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ade:	45c5                	li	a1,17
    80000ae0:	05ee                	slli	a1,a1,0x1b
    80000ae2:	0002a517          	auipc	a0,0x2a
    80000ae6:	80650513          	addi	a0,a0,-2042 # 8002a2e8 <end>
    80000aea:	00000097          	auipc	ra,0x0
    80000aee:	f8a080e7          	jalr	-118(ra) # 80000a74 <freerange>
}
    80000af2:	60a2                	ld	ra,8(sp)
    80000af4:	6402                	ld	s0,0(sp)
    80000af6:	0141                	addi	sp,sp,16
    80000af8:	8082                	ret

0000000080000afa <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000afa:	1101                	addi	sp,sp,-32
    80000afc:	ec06                	sd	ra,24(sp)
    80000afe:	e822                	sd	s0,16(sp)
    80000b00:	e426                	sd	s1,8(sp)
    80000b02:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b04:	00010497          	auipc	s1,0x10
    80000b08:	33c48493          	addi	s1,s1,828 # 80010e40 <kmem>
    80000b0c:	8526                	mv	a0,s1
    80000b0e:	00000097          	auipc	ra,0x0
    80000b12:	0dc080e7          	jalr	220(ra) # 80000bea <acquire>
  r = kmem.freelist;
    80000b16:	6c84                	ld	s1,24(s1)
  if(r)
    80000b18:	c885                	beqz	s1,80000b48 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b1a:	609c                	ld	a5,0(s1)
    80000b1c:	00010517          	auipc	a0,0x10
    80000b20:	32450513          	addi	a0,a0,804 # 80010e40 <kmem>
    80000b24:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b26:	00000097          	auipc	ra,0x0
    80000b2a:	178080e7          	jalr	376(ra) # 80000c9e <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b2e:	6605                	lui	a2,0x1
    80000b30:	4595                	li	a1,5
    80000b32:	8526                	mv	a0,s1
    80000b34:	00000097          	auipc	ra,0x0
    80000b38:	1b2080e7          	jalr	434(ra) # 80000ce6 <memset>
  return (void*)r;
}
    80000b3c:	8526                	mv	a0,s1
    80000b3e:	60e2                	ld	ra,24(sp)
    80000b40:	6442                	ld	s0,16(sp)
    80000b42:	64a2                	ld	s1,8(sp)
    80000b44:	6105                	addi	sp,sp,32
    80000b46:	8082                	ret
  release(&kmem.lock);
    80000b48:	00010517          	auipc	a0,0x10
    80000b4c:	2f850513          	addi	a0,a0,760 # 80010e40 <kmem>
    80000b50:	00000097          	auipc	ra,0x0
    80000b54:	14e080e7          	jalr	334(ra) # 80000c9e <release>
  if(r)
    80000b58:	b7d5                	j	80000b3c <kalloc+0x42>

0000000080000b5a <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b5a:	1141                	addi	sp,sp,-16
    80000b5c:	e422                	sd	s0,8(sp)
    80000b5e:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b60:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b62:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b66:	00053823          	sd	zero,16(a0)
}
    80000b6a:	6422                	ld	s0,8(sp)
    80000b6c:	0141                	addi	sp,sp,16
    80000b6e:	8082                	ret

0000000080000b70 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b70:	411c                	lw	a5,0(a0)
    80000b72:	e399                	bnez	a5,80000b78 <holding+0x8>
    80000b74:	4501                	li	a0,0
  return r;
}
    80000b76:	8082                	ret
{
    80000b78:	1101                	addi	sp,sp,-32
    80000b7a:	ec06                	sd	ra,24(sp)
    80000b7c:	e822                	sd	s0,16(sp)
    80000b7e:	e426                	sd	s1,8(sp)
    80000b80:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b82:	6904                	ld	s1,16(a0)
    80000b84:	00001097          	auipc	ra,0x1
    80000b88:	e26080e7          	jalr	-474(ra) # 800019aa <mycpu>
    80000b8c:	40a48533          	sub	a0,s1,a0
    80000b90:	00153513          	seqz	a0,a0
}
    80000b94:	60e2                	ld	ra,24(sp)
    80000b96:	6442                	ld	s0,16(sp)
    80000b98:	64a2                	ld	s1,8(sp)
    80000b9a:	6105                	addi	sp,sp,32
    80000b9c:	8082                	ret

0000000080000b9e <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b9e:	1101                	addi	sp,sp,-32
    80000ba0:	ec06                	sd	ra,24(sp)
    80000ba2:	e822                	sd	s0,16(sp)
    80000ba4:	e426                	sd	s1,8(sp)
    80000ba6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba8:	100024f3          	csrr	s1,sstatus
    80000bac:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bb0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bb2:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb6:	00001097          	auipc	ra,0x1
    80000bba:	df4080e7          	jalr	-524(ra) # 800019aa <mycpu>
    80000bbe:	5d3c                	lw	a5,120(a0)
    80000bc0:	cf89                	beqz	a5,80000bda <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bc2:	00001097          	auipc	ra,0x1
    80000bc6:	de8080e7          	jalr	-536(ra) # 800019aa <mycpu>
    80000bca:	5d3c                	lw	a5,120(a0)
    80000bcc:	2785                	addiw	a5,a5,1
    80000bce:	dd3c                	sw	a5,120(a0)
}
    80000bd0:	60e2                	ld	ra,24(sp)
    80000bd2:	6442                	ld	s0,16(sp)
    80000bd4:	64a2                	ld	s1,8(sp)
    80000bd6:	6105                	addi	sp,sp,32
    80000bd8:	8082                	ret
    mycpu()->intena = old;
    80000bda:	00001097          	auipc	ra,0x1
    80000bde:	dd0080e7          	jalr	-560(ra) # 800019aa <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000be2:	8085                	srli	s1,s1,0x1
    80000be4:	8885                	andi	s1,s1,1
    80000be6:	dd64                	sw	s1,124(a0)
    80000be8:	bfe9                	j	80000bc2 <push_off+0x24>

0000000080000bea <acquire>:
{
    80000bea:	1101                	addi	sp,sp,-32
    80000bec:	ec06                	sd	ra,24(sp)
    80000bee:	e822                	sd	s0,16(sp)
    80000bf0:	e426                	sd	s1,8(sp)
    80000bf2:	1000                	addi	s0,sp,32
    80000bf4:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf6:	00000097          	auipc	ra,0x0
    80000bfa:	fa8080e7          	jalr	-88(ra) # 80000b9e <push_off>
  if(holding(lk))
    80000bfe:	8526                	mv	a0,s1
    80000c00:	00000097          	auipc	ra,0x0
    80000c04:	f70080e7          	jalr	-144(ra) # 80000b70 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c08:	4705                	li	a4,1
  if(holding(lk))
    80000c0a:	e115                	bnez	a0,80000c2e <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c0c:	87ba                	mv	a5,a4
    80000c0e:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c12:	2781                	sext.w	a5,a5
    80000c14:	ffe5                	bnez	a5,80000c0c <acquire+0x22>
  __sync_synchronize();
    80000c16:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c1a:	00001097          	auipc	ra,0x1
    80000c1e:	d90080e7          	jalr	-624(ra) # 800019aa <mycpu>
    80000c22:	e888                	sd	a0,16(s1)
}
    80000c24:	60e2                	ld	ra,24(sp)
    80000c26:	6442                	ld	s0,16(sp)
    80000c28:	64a2                	ld	s1,8(sp)
    80000c2a:	6105                	addi	sp,sp,32
    80000c2c:	8082                	ret
    panic("acquire");
    80000c2e:	00007517          	auipc	a0,0x7
    80000c32:	44250513          	addi	a0,a0,1090 # 80008070 <digits+0x30>
    80000c36:	00000097          	auipc	ra,0x0
    80000c3a:	90e080e7          	jalr	-1778(ra) # 80000544 <panic>

0000000080000c3e <pop_off>:

void
pop_off(void)
{
    80000c3e:	1141                	addi	sp,sp,-16
    80000c40:	e406                	sd	ra,8(sp)
    80000c42:	e022                	sd	s0,0(sp)
    80000c44:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c46:	00001097          	auipc	ra,0x1
    80000c4a:	d64080e7          	jalr	-668(ra) # 800019aa <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c4e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c52:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c54:	e78d                	bnez	a5,80000c7e <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c56:	5d3c                	lw	a5,120(a0)
    80000c58:	02f05b63          	blez	a5,80000c8e <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c5c:	37fd                	addiw	a5,a5,-1
    80000c5e:	0007871b          	sext.w	a4,a5
    80000c62:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c64:	eb09                	bnez	a4,80000c76 <pop_off+0x38>
    80000c66:	5d7c                	lw	a5,124(a0)
    80000c68:	c799                	beqz	a5,80000c76 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c6a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c6e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c72:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c76:	60a2                	ld	ra,8(sp)
    80000c78:	6402                	ld	s0,0(sp)
    80000c7a:	0141                	addi	sp,sp,16
    80000c7c:	8082                	ret
    panic("pop_off - interruptible");
    80000c7e:	00007517          	auipc	a0,0x7
    80000c82:	3fa50513          	addi	a0,a0,1018 # 80008078 <digits+0x38>
    80000c86:	00000097          	auipc	ra,0x0
    80000c8a:	8be080e7          	jalr	-1858(ra) # 80000544 <panic>
    panic("pop_off");
    80000c8e:	00007517          	auipc	a0,0x7
    80000c92:	40250513          	addi	a0,a0,1026 # 80008090 <digits+0x50>
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	8ae080e7          	jalr	-1874(ra) # 80000544 <panic>

0000000080000c9e <release>:
{
    80000c9e:	1101                	addi	sp,sp,-32
    80000ca0:	ec06                	sd	ra,24(sp)
    80000ca2:	e822                	sd	s0,16(sp)
    80000ca4:	e426                	sd	s1,8(sp)
    80000ca6:	1000                	addi	s0,sp,32
    80000ca8:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000caa:	00000097          	auipc	ra,0x0
    80000cae:	ec6080e7          	jalr	-314(ra) # 80000b70 <holding>
    80000cb2:	c115                	beqz	a0,80000cd6 <release+0x38>
  lk->cpu = 0;
    80000cb4:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb8:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cbc:	0f50000f          	fence	iorw,ow
    80000cc0:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cc4:	00000097          	auipc	ra,0x0
    80000cc8:	f7a080e7          	jalr	-134(ra) # 80000c3e <pop_off>
}
    80000ccc:	60e2                	ld	ra,24(sp)
    80000cce:	6442                	ld	s0,16(sp)
    80000cd0:	64a2                	ld	s1,8(sp)
    80000cd2:	6105                	addi	sp,sp,32
    80000cd4:	8082                	ret
    panic("release");
    80000cd6:	00007517          	auipc	a0,0x7
    80000cda:	3c250513          	addi	a0,a0,962 # 80008098 <digits+0x58>
    80000cde:	00000097          	auipc	ra,0x0
    80000ce2:	866080e7          	jalr	-1946(ra) # 80000544 <panic>

0000000080000ce6 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce6:	1141                	addi	sp,sp,-16
    80000ce8:	e422                	sd	s0,8(sp)
    80000cea:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cec:	ce09                	beqz	a2,80000d06 <memset+0x20>
    80000cee:	87aa                	mv	a5,a0
    80000cf0:	fff6071b          	addiw	a4,a2,-1
    80000cf4:	1702                	slli	a4,a4,0x20
    80000cf6:	9301                	srli	a4,a4,0x20
    80000cf8:	0705                	addi	a4,a4,1
    80000cfa:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cfc:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d00:	0785                	addi	a5,a5,1
    80000d02:	fee79de3          	bne	a5,a4,80000cfc <memset+0x16>
  }
  return dst;
}
    80000d06:	6422                	ld	s0,8(sp)
    80000d08:	0141                	addi	sp,sp,16
    80000d0a:	8082                	ret

0000000080000d0c <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d0c:	1141                	addi	sp,sp,-16
    80000d0e:	e422                	sd	s0,8(sp)
    80000d10:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d12:	ca05                	beqz	a2,80000d42 <memcmp+0x36>
    80000d14:	fff6069b          	addiw	a3,a2,-1
    80000d18:	1682                	slli	a3,a3,0x20
    80000d1a:	9281                	srli	a3,a3,0x20
    80000d1c:	0685                	addi	a3,a3,1
    80000d1e:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d20:	00054783          	lbu	a5,0(a0)
    80000d24:	0005c703          	lbu	a4,0(a1)
    80000d28:	00e79863          	bne	a5,a4,80000d38 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d2c:	0505                	addi	a0,a0,1
    80000d2e:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d30:	fed518e3          	bne	a0,a3,80000d20 <memcmp+0x14>
  }

  return 0;
    80000d34:	4501                	li	a0,0
    80000d36:	a019                	j	80000d3c <memcmp+0x30>
      return *s1 - *s2;
    80000d38:	40e7853b          	subw	a0,a5,a4
}
    80000d3c:	6422                	ld	s0,8(sp)
    80000d3e:	0141                	addi	sp,sp,16
    80000d40:	8082                	ret
  return 0;
    80000d42:	4501                	li	a0,0
    80000d44:	bfe5                	j	80000d3c <memcmp+0x30>

0000000080000d46 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d46:	1141                	addi	sp,sp,-16
    80000d48:	e422                	sd	s0,8(sp)
    80000d4a:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d4c:	ca0d                	beqz	a2,80000d7e <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d4e:	00a5f963          	bgeu	a1,a0,80000d60 <memmove+0x1a>
    80000d52:	02061693          	slli	a3,a2,0x20
    80000d56:	9281                	srli	a3,a3,0x20
    80000d58:	00d58733          	add	a4,a1,a3
    80000d5c:	02e56463          	bltu	a0,a4,80000d84 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d60:	fff6079b          	addiw	a5,a2,-1
    80000d64:	1782                	slli	a5,a5,0x20
    80000d66:	9381                	srli	a5,a5,0x20
    80000d68:	0785                	addi	a5,a5,1
    80000d6a:	97ae                	add	a5,a5,a1
    80000d6c:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d6e:	0585                	addi	a1,a1,1
    80000d70:	0705                	addi	a4,a4,1
    80000d72:	fff5c683          	lbu	a3,-1(a1)
    80000d76:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d7a:	fef59ae3          	bne	a1,a5,80000d6e <memmove+0x28>

  return dst;
}
    80000d7e:	6422                	ld	s0,8(sp)
    80000d80:	0141                	addi	sp,sp,16
    80000d82:	8082                	ret
    d += n;
    80000d84:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d86:	fff6079b          	addiw	a5,a2,-1
    80000d8a:	1782                	slli	a5,a5,0x20
    80000d8c:	9381                	srli	a5,a5,0x20
    80000d8e:	fff7c793          	not	a5,a5
    80000d92:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d94:	177d                	addi	a4,a4,-1
    80000d96:	16fd                	addi	a3,a3,-1
    80000d98:	00074603          	lbu	a2,0(a4)
    80000d9c:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000da0:	fef71ae3          	bne	a4,a5,80000d94 <memmove+0x4e>
    80000da4:	bfe9                	j	80000d7e <memmove+0x38>

0000000080000da6 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da6:	1141                	addi	sp,sp,-16
    80000da8:	e406                	sd	ra,8(sp)
    80000daa:	e022                	sd	s0,0(sp)
    80000dac:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dae:	00000097          	auipc	ra,0x0
    80000db2:	f98080e7          	jalr	-104(ra) # 80000d46 <memmove>
}
    80000db6:	60a2                	ld	ra,8(sp)
    80000db8:	6402                	ld	s0,0(sp)
    80000dba:	0141                	addi	sp,sp,16
    80000dbc:	8082                	ret

0000000080000dbe <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000dbe:	1141                	addi	sp,sp,-16
    80000dc0:	e422                	sd	s0,8(sp)
    80000dc2:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dc4:	ce11                	beqz	a2,80000de0 <strncmp+0x22>
    80000dc6:	00054783          	lbu	a5,0(a0)
    80000dca:	cf89                	beqz	a5,80000de4 <strncmp+0x26>
    80000dcc:	0005c703          	lbu	a4,0(a1)
    80000dd0:	00f71a63          	bne	a4,a5,80000de4 <strncmp+0x26>
    n--, p++, q++;
    80000dd4:	367d                	addiw	a2,a2,-1
    80000dd6:	0505                	addi	a0,a0,1
    80000dd8:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dda:	f675                	bnez	a2,80000dc6 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000ddc:	4501                	li	a0,0
    80000dde:	a809                	j	80000df0 <strncmp+0x32>
    80000de0:	4501                	li	a0,0
    80000de2:	a039                	j	80000df0 <strncmp+0x32>
  if(n == 0)
    80000de4:	ca09                	beqz	a2,80000df6 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de6:	00054503          	lbu	a0,0(a0)
    80000dea:	0005c783          	lbu	a5,0(a1)
    80000dee:	9d1d                	subw	a0,a0,a5
}
    80000df0:	6422                	ld	s0,8(sp)
    80000df2:	0141                	addi	sp,sp,16
    80000df4:	8082                	ret
    return 0;
    80000df6:	4501                	li	a0,0
    80000df8:	bfe5                	j	80000df0 <strncmp+0x32>

0000000080000dfa <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dfa:	1141                	addi	sp,sp,-16
    80000dfc:	e422                	sd	s0,8(sp)
    80000dfe:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e00:	872a                	mv	a4,a0
    80000e02:	8832                	mv	a6,a2
    80000e04:	367d                	addiw	a2,a2,-1
    80000e06:	01005963          	blez	a6,80000e18 <strncpy+0x1e>
    80000e0a:	0705                	addi	a4,a4,1
    80000e0c:	0005c783          	lbu	a5,0(a1)
    80000e10:	fef70fa3          	sb	a5,-1(a4)
    80000e14:	0585                	addi	a1,a1,1
    80000e16:	f7f5                	bnez	a5,80000e02 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e18:	00c05d63          	blez	a2,80000e32 <strncpy+0x38>
    80000e1c:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e1e:	0685                	addi	a3,a3,1
    80000e20:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e24:	fff6c793          	not	a5,a3
    80000e28:	9fb9                	addw	a5,a5,a4
    80000e2a:	010787bb          	addw	a5,a5,a6
    80000e2e:	fef048e3          	bgtz	a5,80000e1e <strncpy+0x24>
  return os;
}
    80000e32:	6422                	ld	s0,8(sp)
    80000e34:	0141                	addi	sp,sp,16
    80000e36:	8082                	ret

0000000080000e38 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e38:	1141                	addi	sp,sp,-16
    80000e3a:	e422                	sd	s0,8(sp)
    80000e3c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e3e:	02c05363          	blez	a2,80000e64 <safestrcpy+0x2c>
    80000e42:	fff6069b          	addiw	a3,a2,-1
    80000e46:	1682                	slli	a3,a3,0x20
    80000e48:	9281                	srli	a3,a3,0x20
    80000e4a:	96ae                	add	a3,a3,a1
    80000e4c:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e4e:	00d58963          	beq	a1,a3,80000e60 <safestrcpy+0x28>
    80000e52:	0585                	addi	a1,a1,1
    80000e54:	0785                	addi	a5,a5,1
    80000e56:	fff5c703          	lbu	a4,-1(a1)
    80000e5a:	fee78fa3          	sb	a4,-1(a5)
    80000e5e:	fb65                	bnez	a4,80000e4e <safestrcpy+0x16>
    ;
  *s = 0;
    80000e60:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e64:	6422                	ld	s0,8(sp)
    80000e66:	0141                	addi	sp,sp,16
    80000e68:	8082                	ret

0000000080000e6a <strlen>:

int
strlen(const char *s)
{
    80000e6a:	1141                	addi	sp,sp,-16
    80000e6c:	e422                	sd	s0,8(sp)
    80000e6e:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e70:	00054783          	lbu	a5,0(a0)
    80000e74:	cf91                	beqz	a5,80000e90 <strlen+0x26>
    80000e76:	0505                	addi	a0,a0,1
    80000e78:	87aa                	mv	a5,a0
    80000e7a:	4685                	li	a3,1
    80000e7c:	9e89                	subw	a3,a3,a0
    80000e7e:	00f6853b          	addw	a0,a3,a5
    80000e82:	0785                	addi	a5,a5,1
    80000e84:	fff7c703          	lbu	a4,-1(a5)
    80000e88:	fb7d                	bnez	a4,80000e7e <strlen+0x14>
    ;
  return n;
}
    80000e8a:	6422                	ld	s0,8(sp)
    80000e8c:	0141                	addi	sp,sp,16
    80000e8e:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e90:	4501                	li	a0,0
    80000e92:	bfe5                	j	80000e8a <strlen+0x20>

0000000080000e94 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e94:	1141                	addi	sp,sp,-16
    80000e96:	e406                	sd	ra,8(sp)
    80000e98:	e022                	sd	s0,0(sp)
    80000e9a:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	afe080e7          	jalr	-1282(ra) # 8000199a <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ea4:	00008717          	auipc	a4,0x8
    80000ea8:	d3470713          	addi	a4,a4,-716 # 80008bd8 <started>
  if(cpuid() == 0){
    80000eac:	c139                	beqz	a0,80000ef2 <main+0x5e>
    while(started == 0)
    80000eae:	431c                	lw	a5,0(a4)
    80000eb0:	2781                	sext.w	a5,a5
    80000eb2:	dff5                	beqz	a5,80000eae <main+0x1a>
      ;
    __sync_synchronize();
    80000eb4:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb8:	00001097          	auipc	ra,0x1
    80000ebc:	ae2080e7          	jalr	-1310(ra) # 8000199a <cpuid>
    80000ec0:	85aa                	mv	a1,a0
    80000ec2:	00007517          	auipc	a0,0x7
    80000ec6:	1f650513          	addi	a0,a0,502 # 800080b8 <digits+0x78>
    80000eca:	fffff097          	auipc	ra,0xfffff
    80000ece:	6c4080e7          	jalr	1732(ra) # 8000058e <printf>
    kvminithart();    // turn on paging
    80000ed2:	00000097          	auipc	ra,0x0
    80000ed6:	0d8080e7          	jalr	216(ra) # 80000faa <kvminithart>
    trapinithart();   // install kernel trap vector
    80000eda:	00002097          	auipc	ra,0x2
    80000ede:	86c080e7          	jalr	-1940(ra) # 80002746 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ee2:	00005097          	auipc	ra,0x5
    80000ee6:	f9e080e7          	jalr	-98(ra) # 80005e80 <plicinithart>
  }

  scheduler();        
    80000eea:	00001097          	auipc	ra,0x1
    80000eee:	054080e7          	jalr	84(ra) # 80001f3e <scheduler>
    consoleinit();
    80000ef2:	fffff097          	auipc	ra,0xfffff
    80000ef6:	564080e7          	jalr	1380(ra) # 80000456 <consoleinit>
    printfinit();
    80000efa:	00000097          	auipc	ra,0x0
    80000efe:	87a080e7          	jalr	-1926(ra) # 80000774 <printfinit>
    printf("\n");
    80000f02:	00007517          	auipc	a0,0x7
    80000f06:	1c650513          	addi	a0,a0,454 # 800080c8 <digits+0x88>
    80000f0a:	fffff097          	auipc	ra,0xfffff
    80000f0e:	684080e7          	jalr	1668(ra) # 8000058e <printf>
    printf("xv6 kernel is booting\n");
    80000f12:	00007517          	auipc	a0,0x7
    80000f16:	18e50513          	addi	a0,a0,398 # 800080a0 <digits+0x60>
    80000f1a:	fffff097          	auipc	ra,0xfffff
    80000f1e:	674080e7          	jalr	1652(ra) # 8000058e <printf>
    printf("\n");
    80000f22:	00007517          	auipc	a0,0x7
    80000f26:	1a650513          	addi	a0,a0,422 # 800080c8 <digits+0x88>
    80000f2a:	fffff097          	auipc	ra,0xfffff
    80000f2e:	664080e7          	jalr	1636(ra) # 8000058e <printf>
    kinit();         // physical page allocator
    80000f32:	00000097          	auipc	ra,0x0
    80000f36:	b8c080e7          	jalr	-1140(ra) # 80000abe <kinit>
    kvminit();       // create kernel page table
    80000f3a:	00000097          	auipc	ra,0x0
    80000f3e:	326080e7          	jalr	806(ra) # 80001260 <kvminit>
    kvminithart();   // turn on paging
    80000f42:	00000097          	auipc	ra,0x0
    80000f46:	068080e7          	jalr	104(ra) # 80000faa <kvminithart>
    procinit();      // process table
    80000f4a:	00001097          	auipc	ra,0x1
    80000f4e:	99c080e7          	jalr	-1636(ra) # 800018e6 <procinit>
    trapinit();      // trap vectors
    80000f52:	00001097          	auipc	ra,0x1
    80000f56:	7cc080e7          	jalr	1996(ra) # 8000271e <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5a:	00001097          	auipc	ra,0x1
    80000f5e:	7ec080e7          	jalr	2028(ra) # 80002746 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	f08080e7          	jalr	-248(ra) # 80005e6a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6a:	00005097          	auipc	ra,0x5
    80000f6e:	f16080e7          	jalr	-234(ra) # 80005e80 <plicinithart>
    binit();         // buffer cache
    80000f72:	00002097          	auipc	ra,0x2
    80000f76:	0cc080e7          	jalr	204(ra) # 8000303e <binit>
    iinit();         // inode table
    80000f7a:	00002097          	auipc	ra,0x2
    80000f7e:	770080e7          	jalr	1904(ra) # 800036ea <iinit>
    fileinit();      // file table
    80000f82:	00003097          	auipc	ra,0x3
    80000f86:	70e080e7          	jalr	1806(ra) # 80004690 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8a:	00005097          	auipc	ra,0x5
    80000f8e:	ffe080e7          	jalr	-2(ra) # 80005f88 <virtio_disk_init>
    userinit();      // first user process
    80000f92:	00001097          	auipc	ra,0x1
    80000f96:	d0c080e7          	jalr	-756(ra) # 80001c9e <userinit>
    __sync_synchronize();
    80000f9a:	0ff0000f          	fence
    started = 1;
    80000f9e:	4785                	li	a5,1
    80000fa0:	00008717          	auipc	a4,0x8
    80000fa4:	c2f72c23          	sw	a5,-968(a4) # 80008bd8 <started>
    80000fa8:	b789                	j	80000eea <main+0x56>

0000000080000faa <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000faa:	1141                	addi	sp,sp,-16
    80000fac:	e422                	sd	s0,8(sp)
    80000fae:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fb0:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000fb4:	00008797          	auipc	a5,0x8
    80000fb8:	c2c7b783          	ld	a5,-980(a5) # 80008be0 <kernel_pagetable>
    80000fbc:	83b1                	srli	a5,a5,0xc
    80000fbe:	577d                	li	a4,-1
    80000fc0:	177e                	slli	a4,a4,0x3f
    80000fc2:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fc4:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fc8:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fcc:	6422                	ld	s0,8(sp)
    80000fce:	0141                	addi	sp,sp,16
    80000fd0:	8082                	ret

0000000080000fd2 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fd2:	7139                	addi	sp,sp,-64
    80000fd4:	fc06                	sd	ra,56(sp)
    80000fd6:	f822                	sd	s0,48(sp)
    80000fd8:	f426                	sd	s1,40(sp)
    80000fda:	f04a                	sd	s2,32(sp)
    80000fdc:	ec4e                	sd	s3,24(sp)
    80000fde:	e852                	sd	s4,16(sp)
    80000fe0:	e456                	sd	s5,8(sp)
    80000fe2:	e05a                	sd	s6,0(sp)
    80000fe4:	0080                	addi	s0,sp,64
    80000fe6:	84aa                	mv	s1,a0
    80000fe8:	89ae                	mv	s3,a1
    80000fea:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fec:	57fd                	li	a5,-1
    80000fee:	83e9                	srli	a5,a5,0x1a
    80000ff0:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000ff2:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000ff4:	04b7f263          	bgeu	a5,a1,80001038 <walk+0x66>
    panic("walk");
    80000ff8:	00007517          	auipc	a0,0x7
    80000ffc:	0d850513          	addi	a0,a0,216 # 800080d0 <digits+0x90>
    80001000:	fffff097          	auipc	ra,0xfffff
    80001004:	544080e7          	jalr	1348(ra) # 80000544 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001008:	060a8663          	beqz	s5,80001074 <walk+0xa2>
    8000100c:	00000097          	auipc	ra,0x0
    80001010:	aee080e7          	jalr	-1298(ra) # 80000afa <kalloc>
    80001014:	84aa                	mv	s1,a0
    80001016:	c529                	beqz	a0,80001060 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001018:	6605                	lui	a2,0x1
    8000101a:	4581                	li	a1,0
    8000101c:	00000097          	auipc	ra,0x0
    80001020:	cca080e7          	jalr	-822(ra) # 80000ce6 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001024:	00c4d793          	srli	a5,s1,0xc
    80001028:	07aa                	slli	a5,a5,0xa
    8000102a:	0017e793          	ori	a5,a5,1
    8000102e:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001032:	3a5d                	addiw	s4,s4,-9
    80001034:	036a0063          	beq	s4,s6,80001054 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001038:	0149d933          	srl	s2,s3,s4
    8000103c:	1ff97913          	andi	s2,s2,511
    80001040:	090e                	slli	s2,s2,0x3
    80001042:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001044:	00093483          	ld	s1,0(s2)
    80001048:	0014f793          	andi	a5,s1,1
    8000104c:	dfd5                	beqz	a5,80001008 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000104e:	80a9                	srli	s1,s1,0xa
    80001050:	04b2                	slli	s1,s1,0xc
    80001052:	b7c5                	j	80001032 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001054:	00c9d513          	srli	a0,s3,0xc
    80001058:	1ff57513          	andi	a0,a0,511
    8000105c:	050e                	slli	a0,a0,0x3
    8000105e:	9526                	add	a0,a0,s1
}
    80001060:	70e2                	ld	ra,56(sp)
    80001062:	7442                	ld	s0,48(sp)
    80001064:	74a2                	ld	s1,40(sp)
    80001066:	7902                	ld	s2,32(sp)
    80001068:	69e2                	ld	s3,24(sp)
    8000106a:	6a42                	ld	s4,16(sp)
    8000106c:	6aa2                	ld	s5,8(sp)
    8000106e:	6b02                	ld	s6,0(sp)
    80001070:	6121                	addi	sp,sp,64
    80001072:	8082                	ret
        return 0;
    80001074:	4501                	li	a0,0
    80001076:	b7ed                	j	80001060 <walk+0x8e>

0000000080001078 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001078:	57fd                	li	a5,-1
    8000107a:	83e9                	srli	a5,a5,0x1a
    8000107c:	00b7f463          	bgeu	a5,a1,80001084 <walkaddr+0xc>
    return 0;
    80001080:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001082:	8082                	ret
{
    80001084:	1141                	addi	sp,sp,-16
    80001086:	e406                	sd	ra,8(sp)
    80001088:	e022                	sd	s0,0(sp)
    8000108a:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000108c:	4601                	li	a2,0
    8000108e:	00000097          	auipc	ra,0x0
    80001092:	f44080e7          	jalr	-188(ra) # 80000fd2 <walk>
  if(pte == 0)
    80001096:	c105                	beqz	a0,800010b6 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001098:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000109a:	0117f693          	andi	a3,a5,17
    8000109e:	4745                	li	a4,17
    return 0;
    800010a0:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010a2:	00e68663          	beq	a3,a4,800010ae <walkaddr+0x36>
}
    800010a6:	60a2                	ld	ra,8(sp)
    800010a8:	6402                	ld	s0,0(sp)
    800010aa:	0141                	addi	sp,sp,16
    800010ac:	8082                	ret
  pa = PTE2PA(*pte);
    800010ae:	00a7d513          	srli	a0,a5,0xa
    800010b2:	0532                	slli	a0,a0,0xc
  return pa;
    800010b4:	bfcd                	j	800010a6 <walkaddr+0x2e>
    return 0;
    800010b6:	4501                	li	a0,0
    800010b8:	b7fd                	j	800010a6 <walkaddr+0x2e>

00000000800010ba <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010ba:	715d                	addi	sp,sp,-80
    800010bc:	e486                	sd	ra,72(sp)
    800010be:	e0a2                	sd	s0,64(sp)
    800010c0:	fc26                	sd	s1,56(sp)
    800010c2:	f84a                	sd	s2,48(sp)
    800010c4:	f44e                	sd	s3,40(sp)
    800010c6:	f052                	sd	s4,32(sp)
    800010c8:	ec56                	sd	s5,24(sp)
    800010ca:	e85a                	sd	s6,16(sp)
    800010cc:	e45e                	sd	s7,8(sp)
    800010ce:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010d0:	c205                	beqz	a2,800010f0 <mappages+0x36>
    800010d2:	8aaa                	mv	s5,a0
    800010d4:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010d6:	77fd                	lui	a5,0xfffff
    800010d8:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010dc:	15fd                	addi	a1,a1,-1
    800010de:	00c589b3          	add	s3,a1,a2
    800010e2:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010e6:	8952                	mv	s2,s4
    800010e8:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010ec:	6b85                	lui	s7,0x1
    800010ee:	a015                	j	80001112 <mappages+0x58>
    panic("mappages: size");
    800010f0:	00007517          	auipc	a0,0x7
    800010f4:	fe850513          	addi	a0,a0,-24 # 800080d8 <digits+0x98>
    800010f8:	fffff097          	auipc	ra,0xfffff
    800010fc:	44c080e7          	jalr	1100(ra) # 80000544 <panic>
      panic("mappages: remap");
    80001100:	00007517          	auipc	a0,0x7
    80001104:	fe850513          	addi	a0,a0,-24 # 800080e8 <digits+0xa8>
    80001108:	fffff097          	auipc	ra,0xfffff
    8000110c:	43c080e7          	jalr	1084(ra) # 80000544 <panic>
    a += PGSIZE;
    80001110:	995e                	add	s2,s2,s7
  for(;;){
    80001112:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001116:	4605                	li	a2,1
    80001118:	85ca                	mv	a1,s2
    8000111a:	8556                	mv	a0,s5
    8000111c:	00000097          	auipc	ra,0x0
    80001120:	eb6080e7          	jalr	-330(ra) # 80000fd2 <walk>
    80001124:	cd19                	beqz	a0,80001142 <mappages+0x88>
    if(*pte & PTE_V)
    80001126:	611c                	ld	a5,0(a0)
    80001128:	8b85                	andi	a5,a5,1
    8000112a:	fbf9                	bnez	a5,80001100 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000112c:	80b1                	srli	s1,s1,0xc
    8000112e:	04aa                	slli	s1,s1,0xa
    80001130:	0164e4b3          	or	s1,s1,s6
    80001134:	0014e493          	ori	s1,s1,1
    80001138:	e104                	sd	s1,0(a0)
    if(a == last)
    8000113a:	fd391be3          	bne	s2,s3,80001110 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    8000113e:	4501                	li	a0,0
    80001140:	a011                	j	80001144 <mappages+0x8a>
      return -1;
    80001142:	557d                	li	a0,-1
}
    80001144:	60a6                	ld	ra,72(sp)
    80001146:	6406                	ld	s0,64(sp)
    80001148:	74e2                	ld	s1,56(sp)
    8000114a:	7942                	ld	s2,48(sp)
    8000114c:	79a2                	ld	s3,40(sp)
    8000114e:	7a02                	ld	s4,32(sp)
    80001150:	6ae2                	ld	s5,24(sp)
    80001152:	6b42                	ld	s6,16(sp)
    80001154:	6ba2                	ld	s7,8(sp)
    80001156:	6161                	addi	sp,sp,80
    80001158:	8082                	ret

000000008000115a <kvmmap>:
{
    8000115a:	1141                	addi	sp,sp,-16
    8000115c:	e406                	sd	ra,8(sp)
    8000115e:	e022                	sd	s0,0(sp)
    80001160:	0800                	addi	s0,sp,16
    80001162:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001164:	86b2                	mv	a3,a2
    80001166:	863e                	mv	a2,a5
    80001168:	00000097          	auipc	ra,0x0
    8000116c:	f52080e7          	jalr	-174(ra) # 800010ba <mappages>
    80001170:	e509                	bnez	a0,8000117a <kvmmap+0x20>
}
    80001172:	60a2                	ld	ra,8(sp)
    80001174:	6402                	ld	s0,0(sp)
    80001176:	0141                	addi	sp,sp,16
    80001178:	8082                	ret
    panic("kvmmap");
    8000117a:	00007517          	auipc	a0,0x7
    8000117e:	f7e50513          	addi	a0,a0,-130 # 800080f8 <digits+0xb8>
    80001182:	fffff097          	auipc	ra,0xfffff
    80001186:	3c2080e7          	jalr	962(ra) # 80000544 <panic>

000000008000118a <kvmmake>:
{
    8000118a:	1101                	addi	sp,sp,-32
    8000118c:	ec06                	sd	ra,24(sp)
    8000118e:	e822                	sd	s0,16(sp)
    80001190:	e426                	sd	s1,8(sp)
    80001192:	e04a                	sd	s2,0(sp)
    80001194:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001196:	00000097          	auipc	ra,0x0
    8000119a:	964080e7          	jalr	-1692(ra) # 80000afa <kalloc>
    8000119e:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011a0:	6605                	lui	a2,0x1
    800011a2:	4581                	li	a1,0
    800011a4:	00000097          	auipc	ra,0x0
    800011a8:	b42080e7          	jalr	-1214(ra) # 80000ce6 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011ac:	4719                	li	a4,6
    800011ae:	6685                	lui	a3,0x1
    800011b0:	10000637          	lui	a2,0x10000
    800011b4:	100005b7          	lui	a1,0x10000
    800011b8:	8526                	mv	a0,s1
    800011ba:	00000097          	auipc	ra,0x0
    800011be:	fa0080e7          	jalr	-96(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011c2:	4719                	li	a4,6
    800011c4:	6685                	lui	a3,0x1
    800011c6:	10001637          	lui	a2,0x10001
    800011ca:	100015b7          	lui	a1,0x10001
    800011ce:	8526                	mv	a0,s1
    800011d0:	00000097          	auipc	ra,0x0
    800011d4:	f8a080e7          	jalr	-118(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011d8:	4719                	li	a4,6
    800011da:	004006b7          	lui	a3,0x400
    800011de:	0c000637          	lui	a2,0xc000
    800011e2:	0c0005b7          	lui	a1,0xc000
    800011e6:	8526                	mv	a0,s1
    800011e8:	00000097          	auipc	ra,0x0
    800011ec:	f72080e7          	jalr	-142(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011f0:	00007917          	auipc	s2,0x7
    800011f4:	e1090913          	addi	s2,s2,-496 # 80008000 <etext>
    800011f8:	4729                	li	a4,10
    800011fa:	80007697          	auipc	a3,0x80007
    800011fe:	e0668693          	addi	a3,a3,-506 # 8000 <_entry-0x7fff8000>
    80001202:	4605                	li	a2,1
    80001204:	067e                	slli	a2,a2,0x1f
    80001206:	85b2                	mv	a1,a2
    80001208:	8526                	mv	a0,s1
    8000120a:	00000097          	auipc	ra,0x0
    8000120e:	f50080e7          	jalr	-176(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001212:	4719                	li	a4,6
    80001214:	46c5                	li	a3,17
    80001216:	06ee                	slli	a3,a3,0x1b
    80001218:	412686b3          	sub	a3,a3,s2
    8000121c:	864a                	mv	a2,s2
    8000121e:	85ca                	mv	a1,s2
    80001220:	8526                	mv	a0,s1
    80001222:	00000097          	auipc	ra,0x0
    80001226:	f38080e7          	jalr	-200(ra) # 8000115a <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000122a:	4729                	li	a4,10
    8000122c:	6685                	lui	a3,0x1
    8000122e:	00006617          	auipc	a2,0x6
    80001232:	dd260613          	addi	a2,a2,-558 # 80007000 <_trampoline>
    80001236:	040005b7          	lui	a1,0x4000
    8000123a:	15fd                	addi	a1,a1,-1
    8000123c:	05b2                	slli	a1,a1,0xc
    8000123e:	8526                	mv	a0,s1
    80001240:	00000097          	auipc	ra,0x0
    80001244:	f1a080e7          	jalr	-230(ra) # 8000115a <kvmmap>
  proc_mapstacks(kpgtbl);
    80001248:	8526                	mv	a0,s1
    8000124a:	00000097          	auipc	ra,0x0
    8000124e:	606080e7          	jalr	1542(ra) # 80001850 <proc_mapstacks>
}
    80001252:	8526                	mv	a0,s1
    80001254:	60e2                	ld	ra,24(sp)
    80001256:	6442                	ld	s0,16(sp)
    80001258:	64a2                	ld	s1,8(sp)
    8000125a:	6902                	ld	s2,0(sp)
    8000125c:	6105                	addi	sp,sp,32
    8000125e:	8082                	ret

0000000080001260 <kvminit>:
{
    80001260:	1141                	addi	sp,sp,-16
    80001262:	e406                	sd	ra,8(sp)
    80001264:	e022                	sd	s0,0(sp)
    80001266:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001268:	00000097          	auipc	ra,0x0
    8000126c:	f22080e7          	jalr	-222(ra) # 8000118a <kvmmake>
    80001270:	00008797          	auipc	a5,0x8
    80001274:	96a7b823          	sd	a0,-1680(a5) # 80008be0 <kernel_pagetable>
}
    80001278:	60a2                	ld	ra,8(sp)
    8000127a:	6402                	ld	s0,0(sp)
    8000127c:	0141                	addi	sp,sp,16
    8000127e:	8082                	ret

0000000080001280 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001280:	715d                	addi	sp,sp,-80
    80001282:	e486                	sd	ra,72(sp)
    80001284:	e0a2                	sd	s0,64(sp)
    80001286:	fc26                	sd	s1,56(sp)
    80001288:	f84a                	sd	s2,48(sp)
    8000128a:	f44e                	sd	s3,40(sp)
    8000128c:	f052                	sd	s4,32(sp)
    8000128e:	ec56                	sd	s5,24(sp)
    80001290:	e85a                	sd	s6,16(sp)
    80001292:	e45e                	sd	s7,8(sp)
    80001294:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001296:	03459793          	slli	a5,a1,0x34
    8000129a:	e795                	bnez	a5,800012c6 <uvmunmap+0x46>
    8000129c:	8a2a                	mv	s4,a0
    8000129e:	892e                	mv	s2,a1
    800012a0:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a2:	0632                	slli	a2,a2,0xc
    800012a4:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012a8:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012aa:	6b05                	lui	s6,0x1
    800012ac:	0735e863          	bltu	a1,s3,8000131c <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012b0:	60a6                	ld	ra,72(sp)
    800012b2:	6406                	ld	s0,64(sp)
    800012b4:	74e2                	ld	s1,56(sp)
    800012b6:	7942                	ld	s2,48(sp)
    800012b8:	79a2                	ld	s3,40(sp)
    800012ba:	7a02                	ld	s4,32(sp)
    800012bc:	6ae2                	ld	s5,24(sp)
    800012be:	6b42                	ld	s6,16(sp)
    800012c0:	6ba2                	ld	s7,8(sp)
    800012c2:	6161                	addi	sp,sp,80
    800012c4:	8082                	ret
    panic("uvmunmap: not aligned");
    800012c6:	00007517          	auipc	a0,0x7
    800012ca:	e3a50513          	addi	a0,a0,-454 # 80008100 <digits+0xc0>
    800012ce:	fffff097          	auipc	ra,0xfffff
    800012d2:	276080e7          	jalr	630(ra) # 80000544 <panic>
      panic("uvmunmap: walk");
    800012d6:	00007517          	auipc	a0,0x7
    800012da:	e4250513          	addi	a0,a0,-446 # 80008118 <digits+0xd8>
    800012de:	fffff097          	auipc	ra,0xfffff
    800012e2:	266080e7          	jalr	614(ra) # 80000544 <panic>
      panic("uvmunmap: not mapped");
    800012e6:	00007517          	auipc	a0,0x7
    800012ea:	e4250513          	addi	a0,a0,-446 # 80008128 <digits+0xe8>
    800012ee:	fffff097          	auipc	ra,0xfffff
    800012f2:	256080e7          	jalr	598(ra) # 80000544 <panic>
      panic("uvmunmap: not a leaf");
    800012f6:	00007517          	auipc	a0,0x7
    800012fa:	e4a50513          	addi	a0,a0,-438 # 80008140 <digits+0x100>
    800012fe:	fffff097          	auipc	ra,0xfffff
    80001302:	246080e7          	jalr	582(ra) # 80000544 <panic>
      uint64 pa = PTE2PA(*pte);
    80001306:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001308:	0532                	slli	a0,a0,0xc
    8000130a:	fffff097          	auipc	ra,0xfffff
    8000130e:	6f4080e7          	jalr	1780(ra) # 800009fe <kfree>
    *pte = 0;
    80001312:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001316:	995a                	add	s2,s2,s6
    80001318:	f9397ce3          	bgeu	s2,s3,800012b0 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000131c:	4601                	li	a2,0
    8000131e:	85ca                	mv	a1,s2
    80001320:	8552                	mv	a0,s4
    80001322:	00000097          	auipc	ra,0x0
    80001326:	cb0080e7          	jalr	-848(ra) # 80000fd2 <walk>
    8000132a:	84aa                	mv	s1,a0
    8000132c:	d54d                	beqz	a0,800012d6 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000132e:	6108                	ld	a0,0(a0)
    80001330:	00157793          	andi	a5,a0,1
    80001334:	dbcd                	beqz	a5,800012e6 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001336:	3ff57793          	andi	a5,a0,1023
    8000133a:	fb778ee3          	beq	a5,s7,800012f6 <uvmunmap+0x76>
    if(do_free){
    8000133e:	fc0a8ae3          	beqz	s5,80001312 <uvmunmap+0x92>
    80001342:	b7d1                	j	80001306 <uvmunmap+0x86>

0000000080001344 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001344:	1101                	addi	sp,sp,-32
    80001346:	ec06                	sd	ra,24(sp)
    80001348:	e822                	sd	s0,16(sp)
    8000134a:	e426                	sd	s1,8(sp)
    8000134c:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000134e:	fffff097          	auipc	ra,0xfffff
    80001352:	7ac080e7          	jalr	1964(ra) # 80000afa <kalloc>
    80001356:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001358:	c519                	beqz	a0,80001366 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000135a:	6605                	lui	a2,0x1
    8000135c:	4581                	li	a1,0
    8000135e:	00000097          	auipc	ra,0x0
    80001362:	988080e7          	jalr	-1656(ra) # 80000ce6 <memset>
  return pagetable;
}
    80001366:	8526                	mv	a0,s1
    80001368:	60e2                	ld	ra,24(sp)
    8000136a:	6442                	ld	s0,16(sp)
    8000136c:	64a2                	ld	s1,8(sp)
    8000136e:	6105                	addi	sp,sp,32
    80001370:	8082                	ret

0000000080001372 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001372:	7179                	addi	sp,sp,-48
    80001374:	f406                	sd	ra,40(sp)
    80001376:	f022                	sd	s0,32(sp)
    80001378:	ec26                	sd	s1,24(sp)
    8000137a:	e84a                	sd	s2,16(sp)
    8000137c:	e44e                	sd	s3,8(sp)
    8000137e:	e052                	sd	s4,0(sp)
    80001380:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001382:	6785                	lui	a5,0x1
    80001384:	04f67863          	bgeu	a2,a5,800013d4 <uvmfirst+0x62>
    80001388:	8a2a                	mv	s4,a0
    8000138a:	89ae                	mv	s3,a1
    8000138c:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    8000138e:	fffff097          	auipc	ra,0xfffff
    80001392:	76c080e7          	jalr	1900(ra) # 80000afa <kalloc>
    80001396:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001398:	6605                	lui	a2,0x1
    8000139a:	4581                	li	a1,0
    8000139c:	00000097          	auipc	ra,0x0
    800013a0:	94a080e7          	jalr	-1718(ra) # 80000ce6 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013a4:	4779                	li	a4,30
    800013a6:	86ca                	mv	a3,s2
    800013a8:	6605                	lui	a2,0x1
    800013aa:	4581                	li	a1,0
    800013ac:	8552                	mv	a0,s4
    800013ae:	00000097          	auipc	ra,0x0
    800013b2:	d0c080e7          	jalr	-756(ra) # 800010ba <mappages>
  memmove(mem, src, sz);
    800013b6:	8626                	mv	a2,s1
    800013b8:	85ce                	mv	a1,s3
    800013ba:	854a                	mv	a0,s2
    800013bc:	00000097          	auipc	ra,0x0
    800013c0:	98a080e7          	jalr	-1654(ra) # 80000d46 <memmove>
}
    800013c4:	70a2                	ld	ra,40(sp)
    800013c6:	7402                	ld	s0,32(sp)
    800013c8:	64e2                	ld	s1,24(sp)
    800013ca:	6942                	ld	s2,16(sp)
    800013cc:	69a2                	ld	s3,8(sp)
    800013ce:	6a02                	ld	s4,0(sp)
    800013d0:	6145                	addi	sp,sp,48
    800013d2:	8082                	ret
    panic("uvmfirst: more than a page");
    800013d4:	00007517          	auipc	a0,0x7
    800013d8:	d8450513          	addi	a0,a0,-636 # 80008158 <digits+0x118>
    800013dc:	fffff097          	auipc	ra,0xfffff
    800013e0:	168080e7          	jalr	360(ra) # 80000544 <panic>

00000000800013e4 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013e4:	1101                	addi	sp,sp,-32
    800013e6:	ec06                	sd	ra,24(sp)
    800013e8:	e822                	sd	s0,16(sp)
    800013ea:	e426                	sd	s1,8(sp)
    800013ec:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013ee:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013f0:	00b67d63          	bgeu	a2,a1,8000140a <uvmdealloc+0x26>
    800013f4:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013f6:	6785                	lui	a5,0x1
    800013f8:	17fd                	addi	a5,a5,-1
    800013fa:	00f60733          	add	a4,a2,a5
    800013fe:	767d                	lui	a2,0xfffff
    80001400:	8f71                	and	a4,a4,a2
    80001402:	97ae                	add	a5,a5,a1
    80001404:	8ff1                	and	a5,a5,a2
    80001406:	00f76863          	bltu	a4,a5,80001416 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000140a:	8526                	mv	a0,s1
    8000140c:	60e2                	ld	ra,24(sp)
    8000140e:	6442                	ld	s0,16(sp)
    80001410:	64a2                	ld	s1,8(sp)
    80001412:	6105                	addi	sp,sp,32
    80001414:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001416:	8f99                	sub	a5,a5,a4
    80001418:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000141a:	4685                	li	a3,1
    8000141c:	0007861b          	sext.w	a2,a5
    80001420:	85ba                	mv	a1,a4
    80001422:	00000097          	auipc	ra,0x0
    80001426:	e5e080e7          	jalr	-418(ra) # 80001280 <uvmunmap>
    8000142a:	b7c5                	j	8000140a <uvmdealloc+0x26>

000000008000142c <uvmalloc>:
  if(newsz < oldsz)
    8000142c:	0ab66563          	bltu	a2,a1,800014d6 <uvmalloc+0xaa>
{
    80001430:	7139                	addi	sp,sp,-64
    80001432:	fc06                	sd	ra,56(sp)
    80001434:	f822                	sd	s0,48(sp)
    80001436:	f426                	sd	s1,40(sp)
    80001438:	f04a                	sd	s2,32(sp)
    8000143a:	ec4e                	sd	s3,24(sp)
    8000143c:	e852                	sd	s4,16(sp)
    8000143e:	e456                	sd	s5,8(sp)
    80001440:	e05a                	sd	s6,0(sp)
    80001442:	0080                	addi	s0,sp,64
    80001444:	8aaa                	mv	s5,a0
    80001446:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001448:	6985                	lui	s3,0x1
    8000144a:	19fd                	addi	s3,s3,-1
    8000144c:	95ce                	add	a1,a1,s3
    8000144e:	79fd                	lui	s3,0xfffff
    80001450:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001454:	08c9f363          	bgeu	s3,a2,800014da <uvmalloc+0xae>
    80001458:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    8000145e:	fffff097          	auipc	ra,0xfffff
    80001462:	69c080e7          	jalr	1692(ra) # 80000afa <kalloc>
    80001466:	84aa                	mv	s1,a0
    if(mem == 0){
    80001468:	c51d                	beqz	a0,80001496 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000146a:	6605                	lui	a2,0x1
    8000146c:	4581                	li	a1,0
    8000146e:	00000097          	auipc	ra,0x0
    80001472:	878080e7          	jalr	-1928(ra) # 80000ce6 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001476:	875a                	mv	a4,s6
    80001478:	86a6                	mv	a3,s1
    8000147a:	6605                	lui	a2,0x1
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	c3a080e7          	jalr	-966(ra) # 800010ba <mappages>
    80001488:	e90d                	bnez	a0,800014ba <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000148a:	6785                	lui	a5,0x1
    8000148c:	993e                	add	s2,s2,a5
    8000148e:	fd4968e3          	bltu	s2,s4,8000145e <uvmalloc+0x32>
  return newsz;
    80001492:	8552                	mv	a0,s4
    80001494:	a809                	j	800014a6 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    80001496:	864e                	mv	a2,s3
    80001498:	85ca                	mv	a1,s2
    8000149a:	8556                	mv	a0,s5
    8000149c:	00000097          	auipc	ra,0x0
    800014a0:	f48080e7          	jalr	-184(ra) # 800013e4 <uvmdealloc>
      return 0;
    800014a4:	4501                	li	a0,0
}
    800014a6:	70e2                	ld	ra,56(sp)
    800014a8:	7442                	ld	s0,48(sp)
    800014aa:	74a2                	ld	s1,40(sp)
    800014ac:	7902                	ld	s2,32(sp)
    800014ae:	69e2                	ld	s3,24(sp)
    800014b0:	6a42                	ld	s4,16(sp)
    800014b2:	6aa2                	ld	s5,8(sp)
    800014b4:	6b02                	ld	s6,0(sp)
    800014b6:	6121                	addi	sp,sp,64
    800014b8:	8082                	ret
      kfree(mem);
    800014ba:	8526                	mv	a0,s1
    800014bc:	fffff097          	auipc	ra,0xfffff
    800014c0:	542080e7          	jalr	1346(ra) # 800009fe <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014c4:	864e                	mv	a2,s3
    800014c6:	85ca                	mv	a1,s2
    800014c8:	8556                	mv	a0,s5
    800014ca:	00000097          	auipc	ra,0x0
    800014ce:	f1a080e7          	jalr	-230(ra) # 800013e4 <uvmdealloc>
      return 0;
    800014d2:	4501                	li	a0,0
    800014d4:	bfc9                	j	800014a6 <uvmalloc+0x7a>
    return oldsz;
    800014d6:	852e                	mv	a0,a1
}
    800014d8:	8082                	ret
  return newsz;
    800014da:	8532                	mv	a0,a2
    800014dc:	b7e9                	j	800014a6 <uvmalloc+0x7a>

00000000800014de <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014de:	7179                	addi	sp,sp,-48
    800014e0:	f406                	sd	ra,40(sp)
    800014e2:	f022                	sd	s0,32(sp)
    800014e4:	ec26                	sd	s1,24(sp)
    800014e6:	e84a                	sd	s2,16(sp)
    800014e8:	e44e                	sd	s3,8(sp)
    800014ea:	e052                	sd	s4,0(sp)
    800014ec:	1800                	addi	s0,sp,48
    800014ee:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014f0:	84aa                	mv	s1,a0
    800014f2:	6905                	lui	s2,0x1
    800014f4:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f6:	4985                	li	s3,1
    800014f8:	a821                	j	80001510 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014fa:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014fc:	0532                	slli	a0,a0,0xc
    800014fe:	00000097          	auipc	ra,0x0
    80001502:	fe0080e7          	jalr	-32(ra) # 800014de <freewalk>
      pagetable[i] = 0;
    80001506:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000150a:	04a1                	addi	s1,s1,8
    8000150c:	03248163          	beq	s1,s2,8000152e <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001510:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001512:	00f57793          	andi	a5,a0,15
    80001516:	ff3782e3          	beq	a5,s3,800014fa <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000151a:	8905                	andi	a0,a0,1
    8000151c:	d57d                	beqz	a0,8000150a <freewalk+0x2c>
      panic("freewalk: leaf");
    8000151e:	00007517          	auipc	a0,0x7
    80001522:	c5a50513          	addi	a0,a0,-934 # 80008178 <digits+0x138>
    80001526:	fffff097          	auipc	ra,0xfffff
    8000152a:	01e080e7          	jalr	30(ra) # 80000544 <panic>
    }
  }
  kfree((void*)pagetable);
    8000152e:	8552                	mv	a0,s4
    80001530:	fffff097          	auipc	ra,0xfffff
    80001534:	4ce080e7          	jalr	1230(ra) # 800009fe <kfree>
}
    80001538:	70a2                	ld	ra,40(sp)
    8000153a:	7402                	ld	s0,32(sp)
    8000153c:	64e2                	ld	s1,24(sp)
    8000153e:	6942                	ld	s2,16(sp)
    80001540:	69a2                	ld	s3,8(sp)
    80001542:	6a02                	ld	s4,0(sp)
    80001544:	6145                	addi	sp,sp,48
    80001546:	8082                	ret

0000000080001548 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001548:	1101                	addi	sp,sp,-32
    8000154a:	ec06                	sd	ra,24(sp)
    8000154c:	e822                	sd	s0,16(sp)
    8000154e:	e426                	sd	s1,8(sp)
    80001550:	1000                	addi	s0,sp,32
    80001552:	84aa                	mv	s1,a0
  if(sz > 0)
    80001554:	e999                	bnez	a1,8000156a <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001556:	8526                	mv	a0,s1
    80001558:	00000097          	auipc	ra,0x0
    8000155c:	f86080e7          	jalr	-122(ra) # 800014de <freewalk>
}
    80001560:	60e2                	ld	ra,24(sp)
    80001562:	6442                	ld	s0,16(sp)
    80001564:	64a2                	ld	s1,8(sp)
    80001566:	6105                	addi	sp,sp,32
    80001568:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000156a:	6605                	lui	a2,0x1
    8000156c:	167d                	addi	a2,a2,-1
    8000156e:	962e                	add	a2,a2,a1
    80001570:	4685                	li	a3,1
    80001572:	8231                	srli	a2,a2,0xc
    80001574:	4581                	li	a1,0
    80001576:	00000097          	auipc	ra,0x0
    8000157a:	d0a080e7          	jalr	-758(ra) # 80001280 <uvmunmap>
    8000157e:	bfe1                	j	80001556 <uvmfree+0xe>

0000000080001580 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001580:	c679                	beqz	a2,8000164e <uvmcopy+0xce>
{
    80001582:	715d                	addi	sp,sp,-80
    80001584:	e486                	sd	ra,72(sp)
    80001586:	e0a2                	sd	s0,64(sp)
    80001588:	fc26                	sd	s1,56(sp)
    8000158a:	f84a                	sd	s2,48(sp)
    8000158c:	f44e                	sd	s3,40(sp)
    8000158e:	f052                	sd	s4,32(sp)
    80001590:	ec56                	sd	s5,24(sp)
    80001592:	e85a                	sd	s6,16(sp)
    80001594:	e45e                	sd	s7,8(sp)
    80001596:	0880                	addi	s0,sp,80
    80001598:	8b2a                	mv	s6,a0
    8000159a:	8aae                	mv	s5,a1
    8000159c:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000159e:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015a0:	4601                	li	a2,0
    800015a2:	85ce                	mv	a1,s3
    800015a4:	855a                	mv	a0,s6
    800015a6:	00000097          	auipc	ra,0x0
    800015aa:	a2c080e7          	jalr	-1492(ra) # 80000fd2 <walk>
    800015ae:	c531                	beqz	a0,800015fa <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015b0:	6118                	ld	a4,0(a0)
    800015b2:	00177793          	andi	a5,a4,1
    800015b6:	cbb1                	beqz	a5,8000160a <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015b8:	00a75593          	srli	a1,a4,0xa
    800015bc:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015c0:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015c4:	fffff097          	auipc	ra,0xfffff
    800015c8:	536080e7          	jalr	1334(ra) # 80000afa <kalloc>
    800015cc:	892a                	mv	s2,a0
    800015ce:	c939                	beqz	a0,80001624 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015d0:	6605                	lui	a2,0x1
    800015d2:	85de                	mv	a1,s7
    800015d4:	fffff097          	auipc	ra,0xfffff
    800015d8:	772080e7          	jalr	1906(ra) # 80000d46 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015dc:	8726                	mv	a4,s1
    800015de:	86ca                	mv	a3,s2
    800015e0:	6605                	lui	a2,0x1
    800015e2:	85ce                	mv	a1,s3
    800015e4:	8556                	mv	a0,s5
    800015e6:	00000097          	auipc	ra,0x0
    800015ea:	ad4080e7          	jalr	-1324(ra) # 800010ba <mappages>
    800015ee:	e515                	bnez	a0,8000161a <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015f0:	6785                	lui	a5,0x1
    800015f2:	99be                	add	s3,s3,a5
    800015f4:	fb49e6e3          	bltu	s3,s4,800015a0 <uvmcopy+0x20>
    800015f8:	a081                	j	80001638 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015fa:	00007517          	auipc	a0,0x7
    800015fe:	b8e50513          	addi	a0,a0,-1138 # 80008188 <digits+0x148>
    80001602:	fffff097          	auipc	ra,0xfffff
    80001606:	f42080e7          	jalr	-190(ra) # 80000544 <panic>
      panic("uvmcopy: page not present");
    8000160a:	00007517          	auipc	a0,0x7
    8000160e:	b9e50513          	addi	a0,a0,-1122 # 800081a8 <digits+0x168>
    80001612:	fffff097          	auipc	ra,0xfffff
    80001616:	f32080e7          	jalr	-206(ra) # 80000544 <panic>
      kfree(mem);
    8000161a:	854a                	mv	a0,s2
    8000161c:	fffff097          	auipc	ra,0xfffff
    80001620:	3e2080e7          	jalr	994(ra) # 800009fe <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001624:	4685                	li	a3,1
    80001626:	00c9d613          	srli	a2,s3,0xc
    8000162a:	4581                	li	a1,0
    8000162c:	8556                	mv	a0,s5
    8000162e:	00000097          	auipc	ra,0x0
    80001632:	c52080e7          	jalr	-942(ra) # 80001280 <uvmunmap>
  return -1;
    80001636:	557d                	li	a0,-1
}
    80001638:	60a6                	ld	ra,72(sp)
    8000163a:	6406                	ld	s0,64(sp)
    8000163c:	74e2                	ld	s1,56(sp)
    8000163e:	7942                	ld	s2,48(sp)
    80001640:	79a2                	ld	s3,40(sp)
    80001642:	7a02                	ld	s4,32(sp)
    80001644:	6ae2                	ld	s5,24(sp)
    80001646:	6b42                	ld	s6,16(sp)
    80001648:	6ba2                	ld	s7,8(sp)
    8000164a:	6161                	addi	sp,sp,80
    8000164c:	8082                	ret
  return 0;
    8000164e:	4501                	li	a0,0
}
    80001650:	8082                	ret

0000000080001652 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001652:	1141                	addi	sp,sp,-16
    80001654:	e406                	sd	ra,8(sp)
    80001656:	e022                	sd	s0,0(sp)
    80001658:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000165a:	4601                	li	a2,0
    8000165c:	00000097          	auipc	ra,0x0
    80001660:	976080e7          	jalr	-1674(ra) # 80000fd2 <walk>
  if(pte == 0)
    80001664:	c901                	beqz	a0,80001674 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001666:	611c                	ld	a5,0(a0)
    80001668:	9bbd                	andi	a5,a5,-17
    8000166a:	e11c                	sd	a5,0(a0)
}
    8000166c:	60a2                	ld	ra,8(sp)
    8000166e:	6402                	ld	s0,0(sp)
    80001670:	0141                	addi	sp,sp,16
    80001672:	8082                	ret
    panic("uvmclear");
    80001674:	00007517          	auipc	a0,0x7
    80001678:	b5450513          	addi	a0,a0,-1196 # 800081c8 <digits+0x188>
    8000167c:	fffff097          	auipc	ra,0xfffff
    80001680:	ec8080e7          	jalr	-312(ra) # 80000544 <panic>

0000000080001684 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001684:	c6bd                	beqz	a3,800016f2 <copyout+0x6e>
{
    80001686:	715d                	addi	sp,sp,-80
    80001688:	e486                	sd	ra,72(sp)
    8000168a:	e0a2                	sd	s0,64(sp)
    8000168c:	fc26                	sd	s1,56(sp)
    8000168e:	f84a                	sd	s2,48(sp)
    80001690:	f44e                	sd	s3,40(sp)
    80001692:	f052                	sd	s4,32(sp)
    80001694:	ec56                	sd	s5,24(sp)
    80001696:	e85a                	sd	s6,16(sp)
    80001698:	e45e                	sd	s7,8(sp)
    8000169a:	e062                	sd	s8,0(sp)
    8000169c:	0880                	addi	s0,sp,80
    8000169e:	8b2a                	mv	s6,a0
    800016a0:	8c2e                	mv	s8,a1
    800016a2:	8a32                	mv	s4,a2
    800016a4:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016a6:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016a8:	6a85                	lui	s5,0x1
    800016aa:	a015                	j	800016ce <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016ac:	9562                	add	a0,a0,s8
    800016ae:	0004861b          	sext.w	a2,s1
    800016b2:	85d2                	mv	a1,s4
    800016b4:	41250533          	sub	a0,a0,s2
    800016b8:	fffff097          	auipc	ra,0xfffff
    800016bc:	68e080e7          	jalr	1678(ra) # 80000d46 <memmove>

    len -= n;
    800016c0:	409989b3          	sub	s3,s3,s1
    src += n;
    800016c4:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016c6:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016ca:	02098263          	beqz	s3,800016ee <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016ce:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016d2:	85ca                	mv	a1,s2
    800016d4:	855a                	mv	a0,s6
    800016d6:	00000097          	auipc	ra,0x0
    800016da:	9a2080e7          	jalr	-1630(ra) # 80001078 <walkaddr>
    if(pa0 == 0)
    800016de:	cd01                	beqz	a0,800016f6 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016e0:	418904b3          	sub	s1,s2,s8
    800016e4:	94d6                	add	s1,s1,s5
    if(n > len)
    800016e6:	fc99f3e3          	bgeu	s3,s1,800016ac <copyout+0x28>
    800016ea:	84ce                	mv	s1,s3
    800016ec:	b7c1                	j	800016ac <copyout+0x28>
  }
  return 0;
    800016ee:	4501                	li	a0,0
    800016f0:	a021                	j	800016f8 <copyout+0x74>
    800016f2:	4501                	li	a0,0
}
    800016f4:	8082                	ret
      return -1;
    800016f6:	557d                	li	a0,-1
}
    800016f8:	60a6                	ld	ra,72(sp)
    800016fa:	6406                	ld	s0,64(sp)
    800016fc:	74e2                	ld	s1,56(sp)
    800016fe:	7942                	ld	s2,48(sp)
    80001700:	79a2                	ld	s3,40(sp)
    80001702:	7a02                	ld	s4,32(sp)
    80001704:	6ae2                	ld	s5,24(sp)
    80001706:	6b42                	ld	s6,16(sp)
    80001708:	6ba2                	ld	s7,8(sp)
    8000170a:	6c02                	ld	s8,0(sp)
    8000170c:	6161                	addi	sp,sp,80
    8000170e:	8082                	ret

0000000080001710 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001710:	c6bd                	beqz	a3,8000177e <copyin+0x6e>
{
    80001712:	715d                	addi	sp,sp,-80
    80001714:	e486                	sd	ra,72(sp)
    80001716:	e0a2                	sd	s0,64(sp)
    80001718:	fc26                	sd	s1,56(sp)
    8000171a:	f84a                	sd	s2,48(sp)
    8000171c:	f44e                	sd	s3,40(sp)
    8000171e:	f052                	sd	s4,32(sp)
    80001720:	ec56                	sd	s5,24(sp)
    80001722:	e85a                	sd	s6,16(sp)
    80001724:	e45e                	sd	s7,8(sp)
    80001726:	e062                	sd	s8,0(sp)
    80001728:	0880                	addi	s0,sp,80
    8000172a:	8b2a                	mv	s6,a0
    8000172c:	8a2e                	mv	s4,a1
    8000172e:	8c32                	mv	s8,a2
    80001730:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001732:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001734:	6a85                	lui	s5,0x1
    80001736:	a015                	j	8000175a <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001738:	9562                	add	a0,a0,s8
    8000173a:	0004861b          	sext.w	a2,s1
    8000173e:	412505b3          	sub	a1,a0,s2
    80001742:	8552                	mv	a0,s4
    80001744:	fffff097          	auipc	ra,0xfffff
    80001748:	602080e7          	jalr	1538(ra) # 80000d46 <memmove>

    len -= n;
    8000174c:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001750:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001752:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001756:	02098263          	beqz	s3,8000177a <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    8000175a:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000175e:	85ca                	mv	a1,s2
    80001760:	855a                	mv	a0,s6
    80001762:	00000097          	auipc	ra,0x0
    80001766:	916080e7          	jalr	-1770(ra) # 80001078 <walkaddr>
    if(pa0 == 0)
    8000176a:	cd01                	beqz	a0,80001782 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000176c:	418904b3          	sub	s1,s2,s8
    80001770:	94d6                	add	s1,s1,s5
    if(n > len)
    80001772:	fc99f3e3          	bgeu	s3,s1,80001738 <copyin+0x28>
    80001776:	84ce                	mv	s1,s3
    80001778:	b7c1                	j	80001738 <copyin+0x28>
  }
  return 0;
    8000177a:	4501                	li	a0,0
    8000177c:	a021                	j	80001784 <copyin+0x74>
    8000177e:	4501                	li	a0,0
}
    80001780:	8082                	ret
      return -1;
    80001782:	557d                	li	a0,-1
}
    80001784:	60a6                	ld	ra,72(sp)
    80001786:	6406                	ld	s0,64(sp)
    80001788:	74e2                	ld	s1,56(sp)
    8000178a:	7942                	ld	s2,48(sp)
    8000178c:	79a2                	ld	s3,40(sp)
    8000178e:	7a02                	ld	s4,32(sp)
    80001790:	6ae2                	ld	s5,24(sp)
    80001792:	6b42                	ld	s6,16(sp)
    80001794:	6ba2                	ld	s7,8(sp)
    80001796:	6c02                	ld	s8,0(sp)
    80001798:	6161                	addi	sp,sp,80
    8000179a:	8082                	ret

000000008000179c <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000179c:	c6c5                	beqz	a3,80001844 <copyinstr+0xa8>
{
    8000179e:	715d                	addi	sp,sp,-80
    800017a0:	e486                	sd	ra,72(sp)
    800017a2:	e0a2                	sd	s0,64(sp)
    800017a4:	fc26                	sd	s1,56(sp)
    800017a6:	f84a                	sd	s2,48(sp)
    800017a8:	f44e                	sd	s3,40(sp)
    800017aa:	f052                	sd	s4,32(sp)
    800017ac:	ec56                	sd	s5,24(sp)
    800017ae:	e85a                	sd	s6,16(sp)
    800017b0:	e45e                	sd	s7,8(sp)
    800017b2:	0880                	addi	s0,sp,80
    800017b4:	8a2a                	mv	s4,a0
    800017b6:	8b2e                	mv	s6,a1
    800017b8:	8bb2                	mv	s7,a2
    800017ba:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017bc:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017be:	6985                	lui	s3,0x1
    800017c0:	a035                	j	800017ec <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017c2:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017c6:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017c8:	0017b793          	seqz	a5,a5
    800017cc:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017d0:	60a6                	ld	ra,72(sp)
    800017d2:	6406                	ld	s0,64(sp)
    800017d4:	74e2                	ld	s1,56(sp)
    800017d6:	7942                	ld	s2,48(sp)
    800017d8:	79a2                	ld	s3,40(sp)
    800017da:	7a02                	ld	s4,32(sp)
    800017dc:	6ae2                	ld	s5,24(sp)
    800017de:	6b42                	ld	s6,16(sp)
    800017e0:	6ba2                	ld	s7,8(sp)
    800017e2:	6161                	addi	sp,sp,80
    800017e4:	8082                	ret
    srcva = va0 + PGSIZE;
    800017e6:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017ea:	c8a9                	beqz	s1,8000183c <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017ec:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017f0:	85ca                	mv	a1,s2
    800017f2:	8552                	mv	a0,s4
    800017f4:	00000097          	auipc	ra,0x0
    800017f8:	884080e7          	jalr	-1916(ra) # 80001078 <walkaddr>
    if(pa0 == 0)
    800017fc:	c131                	beqz	a0,80001840 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017fe:	41790833          	sub	a6,s2,s7
    80001802:	984e                	add	a6,a6,s3
    if(n > max)
    80001804:	0104f363          	bgeu	s1,a6,8000180a <copyinstr+0x6e>
    80001808:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000180a:	955e                	add	a0,a0,s7
    8000180c:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001810:	fc080be3          	beqz	a6,800017e6 <copyinstr+0x4a>
    80001814:	985a                	add	a6,a6,s6
    80001816:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001818:	41650633          	sub	a2,a0,s6
    8000181c:	14fd                	addi	s1,s1,-1
    8000181e:	9b26                	add	s6,s6,s1
    80001820:	00f60733          	add	a4,a2,a5
    80001824:	00074703          	lbu	a4,0(a4)
    80001828:	df49                	beqz	a4,800017c2 <copyinstr+0x26>
        *dst = *p;
    8000182a:	00e78023          	sb	a4,0(a5)
      --max;
    8000182e:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001832:	0785                	addi	a5,a5,1
    while(n > 0){
    80001834:	ff0796e3          	bne	a5,a6,80001820 <copyinstr+0x84>
      dst++;
    80001838:	8b42                	mv	s6,a6
    8000183a:	b775                	j	800017e6 <copyinstr+0x4a>
    8000183c:	4781                	li	a5,0
    8000183e:	b769                	j	800017c8 <copyinstr+0x2c>
      return -1;
    80001840:	557d                	li	a0,-1
    80001842:	b779                	j	800017d0 <copyinstr+0x34>
  int got_null = 0;
    80001844:	4781                	li	a5,0
  if(got_null){
    80001846:	0017b793          	seqz	a5,a5
    8000184a:	40f00533          	neg	a0,a5
}
    8000184e:	8082                	ret

0000000080001850 <proc_mapstacks>:
// Map it high in memory, followed by an invalid
// guard page.

void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001850:	7139                	addi	sp,sp,-64
    80001852:	fc06                	sd	ra,56(sp)
    80001854:	f822                	sd	s0,48(sp)
    80001856:	f426                	sd	s1,40(sp)
    80001858:	f04a                	sd	s2,32(sp)
    8000185a:	ec4e                	sd	s3,24(sp)
    8000185c:	e852                	sd	s4,16(sp)
    8000185e:	e456                	sd	s5,8(sp)
    80001860:	e05a                	sd	s6,0(sp)
    80001862:	0080                	addi	s0,sp,64
    80001864:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001866:	00010497          	auipc	s1,0x10
    8000186a:	a3a48493          	addi	s1,s1,-1478 # 800112a0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000186e:	8b26                	mv	s6,s1
    80001870:	00006a97          	auipc	s5,0x6
    80001874:	790a8a93          	addi	s5,s5,1936 # 80008000 <etext>
    80001878:	04000937          	lui	s2,0x4000
    8000187c:	197d                	addi	s2,s2,-1
    8000187e:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001880:	00015a17          	auipc	s4,0x15
    80001884:	620a0a13          	addi	s4,s4,1568 # 80016ea0 <tickslock>
    char *pa = kalloc();
    80001888:	fffff097          	auipc	ra,0xfffff
    8000188c:	272080e7          	jalr	626(ra) # 80000afa <kalloc>
    80001890:	862a                	mv	a2,a0
    if(pa == 0)
    80001892:	c131                	beqz	a0,800018d6 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001894:	416485b3          	sub	a1,s1,s6
    80001898:	8591                	srai	a1,a1,0x4
    8000189a:	000ab783          	ld	a5,0(s5)
    8000189e:	02f585b3          	mul	a1,a1,a5
    800018a2:	2585                	addiw	a1,a1,1
    800018a4:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018a8:	4719                	li	a4,6
    800018aa:	6685                	lui	a3,0x1
    800018ac:	40b905b3          	sub	a1,s2,a1
    800018b0:	854e                	mv	a0,s3
    800018b2:	00000097          	auipc	ra,0x0
    800018b6:	8a8080e7          	jalr	-1880(ra) # 8000115a <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018ba:	17048493          	addi	s1,s1,368
    800018be:	fd4495e3          	bne	s1,s4,80001888 <proc_mapstacks+0x38>
  }
}
    800018c2:	70e2                	ld	ra,56(sp)
    800018c4:	7442                	ld	s0,48(sp)
    800018c6:	74a2                	ld	s1,40(sp)
    800018c8:	7902                	ld	s2,32(sp)
    800018ca:	69e2                	ld	s3,24(sp)
    800018cc:	6a42                	ld	s4,16(sp)
    800018ce:	6aa2                	ld	s5,8(sp)
    800018d0:	6b02                	ld	s6,0(sp)
    800018d2:	6121                	addi	sp,sp,64
    800018d4:	8082                	ret
      panic("kalloc");
    800018d6:	00007517          	auipc	a0,0x7
    800018da:	90250513          	addi	a0,a0,-1790 # 800081d8 <digits+0x198>
    800018de:	fffff097          	auipc	ra,0xfffff
    800018e2:	c66080e7          	jalr	-922(ra) # 80000544 <panic>

00000000800018e6 <procinit>:

// initialize the proc table.
void
procinit(void)
{
    800018e6:	7139                	addi	sp,sp,-64
    800018e8:	fc06                	sd	ra,56(sp)
    800018ea:	f822                	sd	s0,48(sp)
    800018ec:	f426                	sd	s1,40(sp)
    800018ee:	f04a                	sd	s2,32(sp)
    800018f0:	ec4e                	sd	s3,24(sp)
    800018f2:	e852                	sd	s4,16(sp)
    800018f4:	e456                	sd	s5,8(sp)
    800018f6:	e05a                	sd	s6,0(sp)
    800018f8:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018fa:	00007597          	auipc	a1,0x7
    800018fe:	8e658593          	addi	a1,a1,-1818 # 800081e0 <digits+0x1a0>
    80001902:	0000f517          	auipc	a0,0xf
    80001906:	55e50513          	addi	a0,a0,1374 # 80010e60 <pid_lock>
    8000190a:	fffff097          	auipc	ra,0xfffff
    8000190e:	250080e7          	jalr	592(ra) # 80000b5a <initlock>
  initlock(&wait_lock, "wait_lock");
    80001912:	00007597          	auipc	a1,0x7
    80001916:	8d658593          	addi	a1,a1,-1834 # 800081e8 <digits+0x1a8>
    8000191a:	0000f517          	auipc	a0,0xf
    8000191e:	55e50513          	addi	a0,a0,1374 # 80010e78 <wait_lock>
    80001922:	fffff097          	auipc	ra,0xfffff
    80001926:	238080e7          	jalr	568(ra) # 80000b5a <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000192a:	00010497          	auipc	s1,0x10
    8000192e:	97648493          	addi	s1,s1,-1674 # 800112a0 <proc>
      initlock(&p->lock, "proc");
    80001932:	00007b17          	auipc	s6,0x7
    80001936:	8c6b0b13          	addi	s6,s6,-1850 # 800081f8 <digits+0x1b8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    8000193a:	8aa6                	mv	s5,s1
    8000193c:	00006a17          	auipc	s4,0x6
    80001940:	6c4a0a13          	addi	s4,s4,1732 # 80008000 <etext>
    80001944:	04000937          	lui	s2,0x4000
    80001948:	197d                	addi	s2,s2,-1
    8000194a:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000194c:	00015997          	auipc	s3,0x15
    80001950:	55498993          	addi	s3,s3,1364 # 80016ea0 <tickslock>
      initlock(&p->lock, "proc");
    80001954:	85da                	mv	a1,s6
    80001956:	8526                	mv	a0,s1
    80001958:	fffff097          	auipc	ra,0xfffff
    8000195c:	202080e7          	jalr	514(ra) # 80000b5a <initlock>
      p->state = UNUSED;
    80001960:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    80001964:	415487b3          	sub	a5,s1,s5
    80001968:	8791                	srai	a5,a5,0x4
    8000196a:	000a3703          	ld	a4,0(s4)
    8000196e:	02e787b3          	mul	a5,a5,a4
    80001972:	2785                	addiw	a5,a5,1
    80001974:	00d7979b          	slliw	a5,a5,0xd
    80001978:	40f907b3          	sub	a5,s2,a5
    8000197c:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    8000197e:	17048493          	addi	s1,s1,368
    80001982:	fd3499e3          	bne	s1,s3,80001954 <procinit+0x6e>
  }
}
    80001986:	70e2                	ld	ra,56(sp)
    80001988:	7442                	ld	s0,48(sp)
    8000198a:	74a2                	ld	s1,40(sp)
    8000198c:	7902                	ld	s2,32(sp)
    8000198e:	69e2                	ld	s3,24(sp)
    80001990:	6a42                	ld	s4,16(sp)
    80001992:	6aa2                	ld	s5,8(sp)
    80001994:	6b02                	ld	s6,0(sp)
    80001996:	6121                	addi	sp,sp,64
    80001998:	8082                	ret

000000008000199a <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    8000199a:	1141                	addi	sp,sp,-16
    8000199c:	e422                	sd	s0,8(sp)
    8000199e:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019a0:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019a2:	2501                	sext.w	a0,a0
    800019a4:	6422                	ld	s0,8(sp)
    800019a6:	0141                	addi	sp,sp,16
    800019a8:	8082                	ret

00000000800019aa <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    800019aa:	1141                	addi	sp,sp,-16
    800019ac:	e422                	sd	s0,8(sp)
    800019ae:	0800                	addi	s0,sp,16
    800019b0:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019b2:	2781                	sext.w	a5,a5
    800019b4:	079e                	slli	a5,a5,0x7
  return c;
}
    800019b6:	0000f517          	auipc	a0,0xf
    800019ba:	4da50513          	addi	a0,a0,1242 # 80010e90 <cpus>
    800019be:	953e                	add	a0,a0,a5
    800019c0:	6422                	ld	s0,8(sp)
    800019c2:	0141                	addi	sp,sp,16
    800019c4:	8082                	ret

00000000800019c6 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    800019c6:	1101                	addi	sp,sp,-32
    800019c8:	ec06                	sd	ra,24(sp)
    800019ca:	e822                	sd	s0,16(sp)
    800019cc:	e426                	sd	s1,8(sp)
    800019ce:	1000                	addi	s0,sp,32
  push_off();
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	1ce080e7          	jalr	462(ra) # 80000b9e <push_off>
    800019d8:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019da:	2781                	sext.w	a5,a5
    800019dc:	079e                	slli	a5,a5,0x7
    800019de:	0000f717          	auipc	a4,0xf
    800019e2:	48270713          	addi	a4,a4,1154 # 80010e60 <pid_lock>
    800019e6:	97ba                	add	a5,a5,a4
    800019e8:	7b84                	ld	s1,48(a5)
  pop_off();
    800019ea:	fffff097          	auipc	ra,0xfffff
    800019ee:	254080e7          	jalr	596(ra) # 80000c3e <pop_off>
  return p;
}
    800019f2:	8526                	mv	a0,s1
    800019f4:	60e2                	ld	ra,24(sp)
    800019f6:	6442                	ld	s0,16(sp)
    800019f8:	64a2                	ld	s1,8(sp)
    800019fa:	6105                	addi	sp,sp,32
    800019fc:	8082                	ret

00000000800019fe <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019fe:	1141                	addi	sp,sp,-16
    80001a00:	e406                	sd	ra,8(sp)
    80001a02:	e022                	sd	s0,0(sp)
    80001a04:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a06:	00000097          	auipc	ra,0x0
    80001a0a:	fc0080e7          	jalr	-64(ra) # 800019c6 <myproc>
    80001a0e:	fffff097          	auipc	ra,0xfffff
    80001a12:	290080e7          	jalr	656(ra) # 80000c9e <release>

  if (first) {
    80001a16:	00007797          	auipc	a5,0x7
    80001a1a:	06a7a783          	lw	a5,106(a5) # 80008a80 <first.1738>
    80001a1e:	eb89                	bnez	a5,80001a30 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a20:	00001097          	auipc	ra,0x1
    80001a24:	d3e080e7          	jalr	-706(ra) # 8000275e <usertrapret>
}
    80001a28:	60a2                	ld	ra,8(sp)
    80001a2a:	6402                	ld	s0,0(sp)
    80001a2c:	0141                	addi	sp,sp,16
    80001a2e:	8082                	ret
    first = 0;
    80001a30:	00007797          	auipc	a5,0x7
    80001a34:	0407a823          	sw	zero,80(a5) # 80008a80 <first.1738>
    fsinit(ROOTDEV);
    80001a38:	4505                	li	a0,1
    80001a3a:	00002097          	auipc	ra,0x2
    80001a3e:	c30080e7          	jalr	-976(ra) # 8000366a <fsinit>
    80001a42:	bff9                	j	80001a20 <forkret+0x22>

0000000080001a44 <allocpid>:
{
    80001a44:	1101                	addi	sp,sp,-32
    80001a46:	ec06                	sd	ra,24(sp)
    80001a48:	e822                	sd	s0,16(sp)
    80001a4a:	e426                	sd	s1,8(sp)
    80001a4c:	e04a                	sd	s2,0(sp)
    80001a4e:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a50:	0000f917          	auipc	s2,0xf
    80001a54:	41090913          	addi	s2,s2,1040 # 80010e60 <pid_lock>
    80001a58:	854a                	mv	a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	190080e7          	jalr	400(ra) # 80000bea <acquire>
  pid = nextpid;
    80001a62:	00007797          	auipc	a5,0x7
    80001a66:	02278793          	addi	a5,a5,34 # 80008a84 <nextpid>
    80001a6a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a6c:	0014871b          	addiw	a4,s1,1
    80001a70:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a72:	854a                	mv	a0,s2
    80001a74:	fffff097          	auipc	ra,0xfffff
    80001a78:	22a080e7          	jalr	554(ra) # 80000c9e <release>
}
    80001a7c:	8526                	mv	a0,s1
    80001a7e:	60e2                	ld	ra,24(sp)
    80001a80:	6442                	ld	s0,16(sp)
    80001a82:	64a2                	ld	s1,8(sp)
    80001a84:	6902                	ld	s2,0(sp)
    80001a86:	6105                	addi	sp,sp,32
    80001a88:	8082                	ret

0000000080001a8a <proc_pagetable>:
{
    80001a8a:	1101                	addi	sp,sp,-32
    80001a8c:	ec06                	sd	ra,24(sp)
    80001a8e:	e822                	sd	s0,16(sp)
    80001a90:	e426                	sd	s1,8(sp)
    80001a92:	e04a                	sd	s2,0(sp)
    80001a94:	1000                	addi	s0,sp,32
    80001a96:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a98:	00000097          	auipc	ra,0x0
    80001a9c:	8ac080e7          	jalr	-1876(ra) # 80001344 <uvmcreate>
    80001aa0:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001aa2:	c121                	beqz	a0,80001ae2 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001aa4:	4729                	li	a4,10
    80001aa6:	00005697          	auipc	a3,0x5
    80001aaa:	55a68693          	addi	a3,a3,1370 # 80007000 <_trampoline>
    80001aae:	6605                	lui	a2,0x1
    80001ab0:	040005b7          	lui	a1,0x4000
    80001ab4:	15fd                	addi	a1,a1,-1
    80001ab6:	05b2                	slli	a1,a1,0xc
    80001ab8:	fffff097          	auipc	ra,0xfffff
    80001abc:	602080e7          	jalr	1538(ra) # 800010ba <mappages>
    80001ac0:	02054863          	bltz	a0,80001af0 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ac4:	4719                	li	a4,6
    80001ac6:	05893683          	ld	a3,88(s2)
    80001aca:	6605                	lui	a2,0x1
    80001acc:	020005b7          	lui	a1,0x2000
    80001ad0:	15fd                	addi	a1,a1,-1
    80001ad2:	05b6                	slli	a1,a1,0xd
    80001ad4:	8526                	mv	a0,s1
    80001ad6:	fffff097          	auipc	ra,0xfffff
    80001ada:	5e4080e7          	jalr	1508(ra) # 800010ba <mappages>
    80001ade:	02054163          	bltz	a0,80001b00 <proc_pagetable+0x76>
}
    80001ae2:	8526                	mv	a0,s1
    80001ae4:	60e2                	ld	ra,24(sp)
    80001ae6:	6442                	ld	s0,16(sp)
    80001ae8:	64a2                	ld	s1,8(sp)
    80001aea:	6902                	ld	s2,0(sp)
    80001aec:	6105                	addi	sp,sp,32
    80001aee:	8082                	ret
    uvmfree(pagetable, 0);
    80001af0:	4581                	li	a1,0
    80001af2:	8526                	mv	a0,s1
    80001af4:	00000097          	auipc	ra,0x0
    80001af8:	a54080e7          	jalr	-1452(ra) # 80001548 <uvmfree>
    return 0;
    80001afc:	4481                	li	s1,0
    80001afe:	b7d5                	j	80001ae2 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b00:	4681                	li	a3,0
    80001b02:	4605                	li	a2,1
    80001b04:	040005b7          	lui	a1,0x4000
    80001b08:	15fd                	addi	a1,a1,-1
    80001b0a:	05b2                	slli	a1,a1,0xc
    80001b0c:	8526                	mv	a0,s1
    80001b0e:	fffff097          	auipc	ra,0xfffff
    80001b12:	772080e7          	jalr	1906(ra) # 80001280 <uvmunmap>
    uvmfree(pagetable, 0);
    80001b16:	4581                	li	a1,0
    80001b18:	8526                	mv	a0,s1
    80001b1a:	00000097          	auipc	ra,0x0
    80001b1e:	a2e080e7          	jalr	-1490(ra) # 80001548 <uvmfree>
    return 0;
    80001b22:	4481                	li	s1,0
    80001b24:	bf7d                	j	80001ae2 <proc_pagetable+0x58>

0000000080001b26 <proc_freepagetable>:
{
    80001b26:	1101                	addi	sp,sp,-32
    80001b28:	ec06                	sd	ra,24(sp)
    80001b2a:	e822                	sd	s0,16(sp)
    80001b2c:	e426                	sd	s1,8(sp)
    80001b2e:	e04a                	sd	s2,0(sp)
    80001b30:	1000                	addi	s0,sp,32
    80001b32:	84aa                	mv	s1,a0
    80001b34:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b36:	4681                	li	a3,0
    80001b38:	4605                	li	a2,1
    80001b3a:	040005b7          	lui	a1,0x4000
    80001b3e:	15fd                	addi	a1,a1,-1
    80001b40:	05b2                	slli	a1,a1,0xc
    80001b42:	fffff097          	auipc	ra,0xfffff
    80001b46:	73e080e7          	jalr	1854(ra) # 80001280 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b4a:	4681                	li	a3,0
    80001b4c:	4605                	li	a2,1
    80001b4e:	020005b7          	lui	a1,0x2000
    80001b52:	15fd                	addi	a1,a1,-1
    80001b54:	05b6                	slli	a1,a1,0xd
    80001b56:	8526                	mv	a0,s1
    80001b58:	fffff097          	auipc	ra,0xfffff
    80001b5c:	728080e7          	jalr	1832(ra) # 80001280 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b60:	85ca                	mv	a1,s2
    80001b62:	8526                	mv	a0,s1
    80001b64:	00000097          	auipc	ra,0x0
    80001b68:	9e4080e7          	jalr	-1564(ra) # 80001548 <uvmfree>
}
    80001b6c:	60e2                	ld	ra,24(sp)
    80001b6e:	6442                	ld	s0,16(sp)
    80001b70:	64a2                	ld	s1,8(sp)
    80001b72:	6902                	ld	s2,0(sp)
    80001b74:	6105                	addi	sp,sp,32
    80001b76:	8082                	ret

0000000080001b78 <freeproc>:
{
    80001b78:	1101                	addi	sp,sp,-32
    80001b7a:	ec06                	sd	ra,24(sp)
    80001b7c:	e822                	sd	s0,16(sp)
    80001b7e:	e426                	sd	s1,8(sp)
    80001b80:	1000                	addi	s0,sp,32
    80001b82:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b84:	6d28                	ld	a0,88(a0)
    80001b86:	c509                	beqz	a0,80001b90 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b88:	fffff097          	auipc	ra,0xfffff
    80001b8c:	e76080e7          	jalr	-394(ra) # 800009fe <kfree>
  p->trapframe = 0;
    80001b90:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b94:	68a8                	ld	a0,80(s1)
    80001b96:	c511                	beqz	a0,80001ba2 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b98:	64ac                	ld	a1,72(s1)
    80001b9a:	00000097          	auipc	ra,0x0
    80001b9e:	f8c080e7          	jalr	-116(ra) # 80001b26 <proc_freepagetable>
  p->pagetable = 0;
    80001ba2:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001ba6:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001baa:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001bae:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001bb2:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bb6:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bba:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bbe:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bc2:	0004ac23          	sw	zero,24(s1)
}
    80001bc6:	60e2                	ld	ra,24(sp)
    80001bc8:	6442                	ld	s0,16(sp)
    80001bca:	64a2                	ld	s1,8(sp)
    80001bcc:	6105                	addi	sp,sp,32
    80001bce:	8082                	ret

0000000080001bd0 <allocproc>:
{
    80001bd0:	1101                	addi	sp,sp,-32
    80001bd2:	ec06                	sd	ra,24(sp)
    80001bd4:	e822                	sd	s0,16(sp)
    80001bd6:	e426                	sd	s1,8(sp)
    80001bd8:	e04a                	sd	s2,0(sp)
    80001bda:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bdc:	0000f497          	auipc	s1,0xf
    80001be0:	6c448493          	addi	s1,s1,1732 # 800112a0 <proc>
    80001be4:	00015917          	auipc	s2,0x15
    80001be8:	2bc90913          	addi	s2,s2,700 # 80016ea0 <tickslock>
    acquire(&p->lock);
    80001bec:	8526                	mv	a0,s1
    80001bee:	fffff097          	auipc	ra,0xfffff
    80001bf2:	ffc080e7          	jalr	-4(ra) # 80000bea <acquire>
    if(p->state == UNUSED) {
    80001bf6:	4c9c                	lw	a5,24(s1)
    80001bf8:	cf81                	beqz	a5,80001c10 <allocproc+0x40>
      release(&p->lock);
    80001bfa:	8526                	mv	a0,s1
    80001bfc:	fffff097          	auipc	ra,0xfffff
    80001c00:	0a2080e7          	jalr	162(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c04:	17048493          	addi	s1,s1,368
    80001c08:	ff2492e3          	bne	s1,s2,80001bec <allocproc+0x1c>
  return 0;
    80001c0c:	4481                	li	s1,0
    80001c0e:	a889                	j	80001c60 <allocproc+0x90>
  p->pid = allocpid();
    80001c10:	00000097          	auipc	ra,0x0
    80001c14:	e34080e7          	jalr	-460(ra) # 80001a44 <allocpid>
    80001c18:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c1a:	4785                	li	a5,1
    80001c1c:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c1e:	fffff097          	auipc	ra,0xfffff
    80001c22:	edc080e7          	jalr	-292(ra) # 80000afa <kalloc>
    80001c26:	892a                	mv	s2,a0
    80001c28:	eca8                	sd	a0,88(s1)
    80001c2a:	c131                	beqz	a0,80001c6e <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c2c:	8526                	mv	a0,s1
    80001c2e:	00000097          	auipc	ra,0x0
    80001c32:	e5c080e7          	jalr	-420(ra) # 80001a8a <proc_pagetable>
    80001c36:	892a                	mv	s2,a0
    80001c38:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c3a:	c531                	beqz	a0,80001c86 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c3c:	07000613          	li	a2,112
    80001c40:	4581                	li	a1,0
    80001c42:	06048513          	addi	a0,s1,96
    80001c46:	fffff097          	auipc	ra,0xfffff
    80001c4a:	0a0080e7          	jalr	160(ra) # 80000ce6 <memset>
  p->context.ra = (uint64)forkret;
    80001c4e:	00000797          	auipc	a5,0x0
    80001c52:	db078793          	addi	a5,a5,-592 # 800019fe <forkret>
    80001c56:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c58:	60bc                	ld	a5,64(s1)
    80001c5a:	6705                	lui	a4,0x1
    80001c5c:	97ba                	add	a5,a5,a4
    80001c5e:	f4bc                	sd	a5,104(s1)
}
    80001c60:	8526                	mv	a0,s1
    80001c62:	60e2                	ld	ra,24(sp)
    80001c64:	6442                	ld	s0,16(sp)
    80001c66:	64a2                	ld	s1,8(sp)
    80001c68:	6902                	ld	s2,0(sp)
    80001c6a:	6105                	addi	sp,sp,32
    80001c6c:	8082                	ret
    freeproc(p);
    80001c6e:	8526                	mv	a0,s1
    80001c70:	00000097          	auipc	ra,0x0
    80001c74:	f08080e7          	jalr	-248(ra) # 80001b78 <freeproc>
    release(&p->lock);
    80001c78:	8526                	mv	a0,s1
    80001c7a:	fffff097          	auipc	ra,0xfffff
    80001c7e:	024080e7          	jalr	36(ra) # 80000c9e <release>
    return 0;
    80001c82:	84ca                	mv	s1,s2
    80001c84:	bff1                	j	80001c60 <allocproc+0x90>
    freeproc(p);
    80001c86:	8526                	mv	a0,s1
    80001c88:	00000097          	auipc	ra,0x0
    80001c8c:	ef0080e7          	jalr	-272(ra) # 80001b78 <freeproc>
    release(&p->lock);
    80001c90:	8526                	mv	a0,s1
    80001c92:	fffff097          	auipc	ra,0xfffff
    80001c96:	00c080e7          	jalr	12(ra) # 80000c9e <release>
    return 0;
    80001c9a:	84ca                	mv	s1,s2
    80001c9c:	b7d1                	j	80001c60 <allocproc+0x90>

0000000080001c9e <userinit>:
{
    80001c9e:	1101                	addi	sp,sp,-32
    80001ca0:	ec06                	sd	ra,24(sp)
    80001ca2:	e822                	sd	s0,16(sp)
    80001ca4:	e426                	sd	s1,8(sp)
    80001ca6:	1000                	addi	s0,sp,32
  p = allocproc();
    80001ca8:	00000097          	auipc	ra,0x0
    80001cac:	f28080e7          	jalr	-216(ra) # 80001bd0 <allocproc>
    80001cb0:	84aa                	mv	s1,a0
  initproc = p;
    80001cb2:	00007797          	auipc	a5,0x7
    80001cb6:	f2a7bb23          	sd	a0,-202(a5) # 80008be8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cba:	03400613          	li	a2,52
    80001cbe:	00007597          	auipc	a1,0x7
    80001cc2:	dd258593          	addi	a1,a1,-558 # 80008a90 <initcode>
    80001cc6:	6928                	ld	a0,80(a0)
    80001cc8:	fffff097          	auipc	ra,0xfffff
    80001ccc:	6aa080e7          	jalr	1706(ra) # 80001372 <uvmfirst>
  p->sz = PGSIZE;
    80001cd0:	6785                	lui	a5,0x1
    80001cd2:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cd4:	6cb8                	ld	a4,88(s1)
    80001cd6:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cda:	6cb8                	ld	a4,88(s1)
    80001cdc:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cde:	4641                	li	a2,16
    80001ce0:	00006597          	auipc	a1,0x6
    80001ce4:	52058593          	addi	a1,a1,1312 # 80008200 <digits+0x1c0>
    80001ce8:	15848513          	addi	a0,s1,344
    80001cec:	fffff097          	auipc	ra,0xfffff
    80001cf0:	14c080e7          	jalr	332(ra) # 80000e38 <safestrcpy>
  p->cwd = namei("/");
    80001cf4:	00006517          	auipc	a0,0x6
    80001cf8:	51c50513          	addi	a0,a0,1308 # 80008210 <digits+0x1d0>
    80001cfc:	00002097          	auipc	ra,0x2
    80001d00:	390080e7          	jalr	912(ra) # 8000408c <namei>
    80001d04:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d08:	478d                	li	a5,3
    80001d0a:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d0c:	8526                	mv	a0,s1
    80001d0e:	fffff097          	auipc	ra,0xfffff
    80001d12:	f90080e7          	jalr	-112(ra) # 80000c9e <release>
}
    80001d16:	60e2                	ld	ra,24(sp)
    80001d18:	6442                	ld	s0,16(sp)
    80001d1a:	64a2                	ld	s1,8(sp)
    80001d1c:	6105                	addi	sp,sp,32
    80001d1e:	8082                	ret

0000000080001d20 <growproc>:
{
    80001d20:	1101                	addi	sp,sp,-32
    80001d22:	ec06                	sd	ra,24(sp)
    80001d24:	e822                	sd	s0,16(sp)
    80001d26:	e426                	sd	s1,8(sp)
    80001d28:	e04a                	sd	s2,0(sp)
    80001d2a:	1000                	addi	s0,sp,32
    80001d2c:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d2e:	00000097          	auipc	ra,0x0
    80001d32:	c98080e7          	jalr	-872(ra) # 800019c6 <myproc>
    80001d36:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d38:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001d3a:	01204c63          	bgtz	s2,80001d52 <growproc+0x32>
  } else if(n < 0){
    80001d3e:	02094663          	bltz	s2,80001d6a <growproc+0x4a>
  p->sz = sz;
    80001d42:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d44:	4501                	li	a0,0
}
    80001d46:	60e2                	ld	ra,24(sp)
    80001d48:	6442                	ld	s0,16(sp)
    80001d4a:	64a2                	ld	s1,8(sp)
    80001d4c:	6902                	ld	s2,0(sp)
    80001d4e:	6105                	addi	sp,sp,32
    80001d50:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001d52:	4691                	li	a3,4
    80001d54:	00b90633          	add	a2,s2,a1
    80001d58:	6928                	ld	a0,80(a0)
    80001d5a:	fffff097          	auipc	ra,0xfffff
    80001d5e:	6d2080e7          	jalr	1746(ra) # 8000142c <uvmalloc>
    80001d62:	85aa                	mv	a1,a0
    80001d64:	fd79                	bnez	a0,80001d42 <growproc+0x22>
      return -1;
    80001d66:	557d                	li	a0,-1
    80001d68:	bff9                	j	80001d46 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d6a:	00b90633          	add	a2,s2,a1
    80001d6e:	6928                	ld	a0,80(a0)
    80001d70:	fffff097          	auipc	ra,0xfffff
    80001d74:	674080e7          	jalr	1652(ra) # 800013e4 <uvmdealloc>
    80001d78:	85aa                	mv	a1,a0
    80001d7a:	b7e1                	j	80001d42 <growproc+0x22>

0000000080001d7c <fork>:
{
    80001d7c:	7179                	addi	sp,sp,-48
    80001d7e:	f406                	sd	ra,40(sp)
    80001d80:	f022                	sd	s0,32(sp)
    80001d82:	ec26                	sd	s1,24(sp)
    80001d84:	e84a                	sd	s2,16(sp)
    80001d86:	e44e                	sd	s3,8(sp)
    80001d88:	e052                	sd	s4,0(sp)
    80001d8a:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001d8c:	00000097          	auipc	ra,0x0
    80001d90:	c3a080e7          	jalr	-966(ra) # 800019c6 <myproc>
    80001d94:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001d96:	00000097          	auipc	ra,0x0
    80001d9a:	e3a080e7          	jalr	-454(ra) # 80001bd0 <allocproc>
    80001d9e:	10050b63          	beqz	a0,80001eb4 <fork+0x138>
    80001da2:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001da4:	04893603          	ld	a2,72(s2)
    80001da8:	692c                	ld	a1,80(a0)
    80001daa:	05093503          	ld	a0,80(s2)
    80001dae:	fffff097          	auipc	ra,0xfffff
    80001db2:	7d2080e7          	jalr	2002(ra) # 80001580 <uvmcopy>
    80001db6:	04054663          	bltz	a0,80001e02 <fork+0x86>
  np->sz = p->sz;
    80001dba:	04893783          	ld	a5,72(s2)
    80001dbe:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001dc2:	05893683          	ld	a3,88(s2)
    80001dc6:	87b6                	mv	a5,a3
    80001dc8:	0589b703          	ld	a4,88(s3)
    80001dcc:	12068693          	addi	a3,a3,288
    80001dd0:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dd4:	6788                	ld	a0,8(a5)
    80001dd6:	6b8c                	ld	a1,16(a5)
    80001dd8:	6f90                	ld	a2,24(a5)
    80001dda:	01073023          	sd	a6,0(a4)
    80001dde:	e708                	sd	a0,8(a4)
    80001de0:	eb0c                	sd	a1,16(a4)
    80001de2:	ef10                	sd	a2,24(a4)
    80001de4:	02078793          	addi	a5,a5,32
    80001de8:	02070713          	addi	a4,a4,32
    80001dec:	fed792e3          	bne	a5,a3,80001dd0 <fork+0x54>
  np->trapframe->a0 = 0;
    80001df0:	0589b783          	ld	a5,88(s3)
    80001df4:	0607b823          	sd	zero,112(a5)
    80001df8:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001dfc:	15000a13          	li	s4,336
    80001e00:	a03d                	j	80001e2e <fork+0xb2>
    freeproc(np);
    80001e02:	854e                	mv	a0,s3
    80001e04:	00000097          	auipc	ra,0x0
    80001e08:	d74080e7          	jalr	-652(ra) # 80001b78 <freeproc>
    release(&np->lock);
    80001e0c:	854e                	mv	a0,s3
    80001e0e:	fffff097          	auipc	ra,0xfffff
    80001e12:	e90080e7          	jalr	-368(ra) # 80000c9e <release>
    return -1;
    80001e16:	5a7d                	li	s4,-1
    80001e18:	a069                	j	80001ea2 <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e1a:	00003097          	auipc	ra,0x3
    80001e1e:	908080e7          	jalr	-1784(ra) # 80004722 <filedup>
    80001e22:	009987b3          	add	a5,s3,s1
    80001e26:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e28:	04a1                	addi	s1,s1,8
    80001e2a:	01448763          	beq	s1,s4,80001e38 <fork+0xbc>
    if(p->ofile[i])
    80001e2e:	009907b3          	add	a5,s2,s1
    80001e32:	6388                	ld	a0,0(a5)
    80001e34:	f17d                	bnez	a0,80001e1a <fork+0x9e>
    80001e36:	bfcd                	j	80001e28 <fork+0xac>
  np->cwd = idup(p->cwd);
    80001e38:	15093503          	ld	a0,336(s2)
    80001e3c:	00002097          	auipc	ra,0x2
    80001e40:	a6c080e7          	jalr	-1428(ra) # 800038a8 <idup>
    80001e44:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e48:	4641                	li	a2,16
    80001e4a:	15890593          	addi	a1,s2,344
    80001e4e:	15898513          	addi	a0,s3,344
    80001e52:	fffff097          	auipc	ra,0xfffff
    80001e56:	fe6080e7          	jalr	-26(ra) # 80000e38 <safestrcpy>
  pid = np->pid;
    80001e5a:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001e5e:	854e                	mv	a0,s3
    80001e60:	fffff097          	auipc	ra,0xfffff
    80001e64:	e3e080e7          	jalr	-450(ra) # 80000c9e <release>
  acquire(&wait_lock);
    80001e68:	0000f497          	auipc	s1,0xf
    80001e6c:	01048493          	addi	s1,s1,16 # 80010e78 <wait_lock>
    80001e70:	8526                	mv	a0,s1
    80001e72:	fffff097          	auipc	ra,0xfffff
    80001e76:	d78080e7          	jalr	-648(ra) # 80000bea <acquire>
  np->parent = p;
    80001e7a:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001e7e:	8526                	mv	a0,s1
    80001e80:	fffff097          	auipc	ra,0xfffff
    80001e84:	e1e080e7          	jalr	-482(ra) # 80000c9e <release>
  acquire(&np->lock);
    80001e88:	854e                	mv	a0,s3
    80001e8a:	fffff097          	auipc	ra,0xfffff
    80001e8e:	d60080e7          	jalr	-672(ra) # 80000bea <acquire>
  np->state = RUNNABLE;
    80001e92:	478d                	li	a5,3
    80001e94:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001e98:	854e                	mv	a0,s3
    80001e9a:	fffff097          	auipc	ra,0xfffff
    80001e9e:	e04080e7          	jalr	-508(ra) # 80000c9e <release>
}
    80001ea2:	8552                	mv	a0,s4
    80001ea4:	70a2                	ld	ra,40(sp)
    80001ea6:	7402                	ld	s0,32(sp)
    80001ea8:	64e2                	ld	s1,24(sp)
    80001eaa:	6942                	ld	s2,16(sp)
    80001eac:	69a2                	ld	s3,8(sp)
    80001eae:	6a02                	ld	s4,0(sp)
    80001eb0:	6145                	addi	sp,sp,48
    80001eb2:	8082                	ret
    return -1;
    80001eb4:	5a7d                	li	s4,-1
    80001eb6:	b7f5                	j	80001ea2 <fork+0x126>

0000000080001eb8 <audit>:
{
    80001eb8:	7179                	addi	sp,sp,-48
    80001eba:	f406                	sd	ra,40(sp)
    80001ebc:	f022                	sd	s0,32(sp)
    80001ebe:	ec26                	sd	s1,24(sp)
    80001ec0:	e84a                	sd	s2,16(sp)
    80001ec2:	1800                	addi	s0,sp,48
    80001ec4:	892a                	mv	s2,a0
    80001ec6:	84ae                	mv	s1,a1
  printf("arr address in audit on proc side: %p\n", arr);
    80001ec8:	85aa                	mv	a1,a0
    80001eca:	00006517          	auipc	a0,0x6
    80001ece:	34e50513          	addi	a0,a0,846 # 80008218 <digits+0x1d8>
    80001ed2:	ffffe097          	auipc	ra,0xffffe
    80001ed6:	6bc080e7          	jalr	1724(ra) # 8000058e <printf>
  printf("length address passed through: %p\n", length);
    80001eda:	85a6                	mv	a1,s1
    80001edc:	00006517          	auipc	a0,0x6
    80001ee0:	36450513          	addi	a0,a0,868 # 80008240 <digits+0x200>
    80001ee4:	ffffe097          	auipc	ra,0xffffe
    80001ee8:	6aa080e7          	jalr	1706(ra) # 8000058e <printf>
  bruh.arr = arr;
    80001eec:	fd243823          	sd	s2,-48(s0)
  bruh.length = length;
    80001ef0:	fc943c23          	sd	s1,-40(s0)
  printf("length: %d\n", *length);
    80001ef4:	408c                	lw	a1,0(s1)
    80001ef6:	00006517          	auipc	a0,0x6
    80001efa:	37250513          	addi	a0,a0,882 # 80008268 <digits+0x228>
    80001efe:	ffffe097          	auipc	ra,0xffffe
    80001f02:	690080e7          	jalr	1680(ra) # 8000058e <printf>
  printf("bruh length address: %p\n", bruh.length);
    80001f06:	fd843583          	ld	a1,-40(s0)
    80001f0a:	00006517          	auipc	a0,0x6
    80001f0e:	36e50513          	addi	a0,a0,878 # 80008278 <digits+0x238>
    80001f12:	ffffe097          	auipc	ra,0xffffe
    80001f16:	67c080e7          	jalr	1660(ra) # 8000058e <printf>
  printf("address of bruh: %p\n", &bruh);
    80001f1a:	fd040593          	addi	a1,s0,-48
    80001f1e:	00006517          	auipc	a0,0x6
    80001f22:	37a50513          	addi	a0,a0,890 # 80008298 <digits+0x258>
    80001f26:	ffffe097          	auipc	ra,0xffffe
    80001f2a:	668080e7          	jalr	1640(ra) # 8000058e <printf>
}
    80001f2e:	fd040513          	addi	a0,s0,-48
    80001f32:	70a2                	ld	ra,40(sp)
    80001f34:	7402                	ld	s0,32(sp)
    80001f36:	64e2                	ld	s1,24(sp)
    80001f38:	6942                	ld	s2,16(sp)
    80001f3a:	6145                	addi	sp,sp,48
    80001f3c:	8082                	ret

0000000080001f3e <scheduler>:
{
    80001f3e:	715d                	addi	sp,sp,-80
    80001f40:	e486                	sd	ra,72(sp)
    80001f42:	e0a2                	sd	s0,64(sp)
    80001f44:	fc26                	sd	s1,56(sp)
    80001f46:	f84a                	sd	s2,48(sp)
    80001f48:	f44e                	sd	s3,40(sp)
    80001f4a:	f052                	sd	s4,32(sp)
    80001f4c:	ec56                	sd	s5,24(sp)
    80001f4e:	e85a                	sd	s6,16(sp)
    80001f50:	e45e                	sd	s7,8(sp)
    80001f52:	e062                	sd	s8,0(sp)
    80001f54:	0880                	addi	s0,sp,80
    80001f56:	8792                	mv	a5,tp
  int id = r_tp();
    80001f58:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f5a:	00779b13          	slli	s6,a5,0x7
    80001f5e:	0000f717          	auipc	a4,0xf
    80001f62:	f0270713          	addi	a4,a4,-254 # 80010e60 <pid_lock>
    80001f66:	975a                	add	a4,a4,s6
    80001f68:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f6c:	0000f717          	auipc	a4,0xf
    80001f70:	f2c70713          	addi	a4,a4,-212 # 80010e98 <cpus+0x8>
    80001f74:	9b3a                	add	s6,s6,a4
        p->state = RUNNING;
    80001f76:	4b91                	li	s7,4
        c->proc = p;
    80001f78:	079e                	slli	a5,a5,0x7
    80001f7a:	0000fa97          	auipc	s5,0xf
    80001f7e:	ee6a8a93          	addi	s5,s5,-282 # 80010e60 <pid_lock>
    80001f82:	9abe                	add	s5,s5,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f84:	00015a17          	auipc	s4,0x15
    80001f88:	f1ca0a13          	addi	s4,s4,-228 # 80016ea0 <tickslock>
    not_runnable_count = 0;
    80001f8c:	4c01                	li	s8,0
    80001f8e:	a0a9                	j	80001fd8 <scheduler+0x9a>
        p->state = RUNNING;
    80001f90:	0174ac23          	sw	s7,24(s1)
        c->proc = p;
    80001f94:	029ab823          	sd	s1,48(s5)
        swtch(&c->context, &p->context);
    80001f98:	06048593          	addi	a1,s1,96
    80001f9c:	855a                	mv	a0,s6
    80001f9e:	00000097          	auipc	ra,0x0
    80001fa2:	716080e7          	jalr	1814(ra) # 800026b4 <swtch>
        c->proc = 0;
    80001fa6:	020ab823          	sd	zero,48(s5)
      release(&p->lock);
    80001faa:	8526                	mv	a0,s1
    80001fac:	fffff097          	auipc	ra,0xfffff
    80001fb0:	cf2080e7          	jalr	-782(ra) # 80000c9e <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fb4:	17048493          	addi	s1,s1,368
    80001fb8:	01448c63          	beq	s1,s4,80001fd0 <scheduler+0x92>
      acquire(&p->lock);
    80001fbc:	8526                	mv	a0,s1
    80001fbe:	fffff097          	auipc	ra,0xfffff
    80001fc2:	c2c080e7          	jalr	-980(ra) # 80000bea <acquire>
      if(p->state == RUNNABLE) {
    80001fc6:	4c9c                	lw	a5,24(s1)
    80001fc8:	fd3784e3          	beq	a5,s3,80001f90 <scheduler+0x52>
        not_runnable_count++;
    80001fcc:	2905                	addiw	s2,s2,1
    80001fce:	bff1                	j	80001faa <scheduler+0x6c>
    if (not_runnable_count == NPROC) {
    80001fd0:	04000793          	li	a5,64
    80001fd4:	00f90f63          	beq	s2,a5,80001ff2 <scheduler+0xb4>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fd8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001fdc:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001fe0:	10079073          	csrw	sstatus,a5
    not_runnable_count = 0;
    80001fe4:	8962                	mv	s2,s8
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fe6:	0000f497          	auipc	s1,0xf
    80001fea:	2ba48493          	addi	s1,s1,698 # 800112a0 <proc>
      if(p->state == RUNNABLE) {
    80001fee:	498d                	li	s3,3
    80001ff0:	b7f1                	j	80001fbc <scheduler+0x7e>
  asm volatile("wfi");
    80001ff2:	10500073          	wfi
}
    80001ff6:	b7cd                	j	80001fd8 <scheduler+0x9a>

0000000080001ff8 <sched>:
{
    80001ff8:	7179                	addi	sp,sp,-48
    80001ffa:	f406                	sd	ra,40(sp)
    80001ffc:	f022                	sd	s0,32(sp)
    80001ffe:	ec26                	sd	s1,24(sp)
    80002000:	e84a                	sd	s2,16(sp)
    80002002:	e44e                	sd	s3,8(sp)
    80002004:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002006:	00000097          	auipc	ra,0x0
    8000200a:	9c0080e7          	jalr	-1600(ra) # 800019c6 <myproc>
    8000200e:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002010:	fffff097          	auipc	ra,0xfffff
    80002014:	b60080e7          	jalr	-1184(ra) # 80000b70 <holding>
    80002018:	c93d                	beqz	a0,8000208e <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000201a:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000201c:	2781                	sext.w	a5,a5
    8000201e:	079e                	slli	a5,a5,0x7
    80002020:	0000f717          	auipc	a4,0xf
    80002024:	e4070713          	addi	a4,a4,-448 # 80010e60 <pid_lock>
    80002028:	97ba                	add	a5,a5,a4
    8000202a:	0a87a703          	lw	a4,168(a5)
    8000202e:	4785                	li	a5,1
    80002030:	06f71763          	bne	a4,a5,8000209e <sched+0xa6>
  if(p->state == RUNNING)
    80002034:	4c98                	lw	a4,24(s1)
    80002036:	4791                	li	a5,4
    80002038:	06f70b63          	beq	a4,a5,800020ae <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000203c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002040:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002042:	efb5                	bnez	a5,800020be <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002044:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002046:	0000f917          	auipc	s2,0xf
    8000204a:	e1a90913          	addi	s2,s2,-486 # 80010e60 <pid_lock>
    8000204e:	2781                	sext.w	a5,a5
    80002050:	079e                	slli	a5,a5,0x7
    80002052:	97ca                	add	a5,a5,s2
    80002054:	0ac7a983          	lw	s3,172(a5)
    80002058:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000205a:	2781                	sext.w	a5,a5
    8000205c:	079e                	slli	a5,a5,0x7
    8000205e:	0000f597          	auipc	a1,0xf
    80002062:	e3a58593          	addi	a1,a1,-454 # 80010e98 <cpus+0x8>
    80002066:	95be                	add	a1,a1,a5
    80002068:	06048513          	addi	a0,s1,96
    8000206c:	00000097          	auipc	ra,0x0
    80002070:	648080e7          	jalr	1608(ra) # 800026b4 <swtch>
    80002074:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002076:	2781                	sext.w	a5,a5
    80002078:	079e                	slli	a5,a5,0x7
    8000207a:	97ca                	add	a5,a5,s2
    8000207c:	0b37a623          	sw	s3,172(a5)
}
    80002080:	70a2                	ld	ra,40(sp)
    80002082:	7402                	ld	s0,32(sp)
    80002084:	64e2                	ld	s1,24(sp)
    80002086:	6942                	ld	s2,16(sp)
    80002088:	69a2                	ld	s3,8(sp)
    8000208a:	6145                	addi	sp,sp,48
    8000208c:	8082                	ret
    panic("sched p->lock");
    8000208e:	00006517          	auipc	a0,0x6
    80002092:	22250513          	addi	a0,a0,546 # 800082b0 <digits+0x270>
    80002096:	ffffe097          	auipc	ra,0xffffe
    8000209a:	4ae080e7          	jalr	1198(ra) # 80000544 <panic>
    panic("sched locks");
    8000209e:	00006517          	auipc	a0,0x6
    800020a2:	22250513          	addi	a0,a0,546 # 800082c0 <digits+0x280>
    800020a6:	ffffe097          	auipc	ra,0xffffe
    800020aa:	49e080e7          	jalr	1182(ra) # 80000544 <panic>
    panic("sched running");
    800020ae:	00006517          	auipc	a0,0x6
    800020b2:	22250513          	addi	a0,a0,546 # 800082d0 <digits+0x290>
    800020b6:	ffffe097          	auipc	ra,0xffffe
    800020ba:	48e080e7          	jalr	1166(ra) # 80000544 <panic>
    panic("sched interruptible");
    800020be:	00006517          	auipc	a0,0x6
    800020c2:	22250513          	addi	a0,a0,546 # 800082e0 <digits+0x2a0>
    800020c6:	ffffe097          	auipc	ra,0xffffe
    800020ca:	47e080e7          	jalr	1150(ra) # 80000544 <panic>

00000000800020ce <yield>:
{
    800020ce:	1101                	addi	sp,sp,-32
    800020d0:	ec06                	sd	ra,24(sp)
    800020d2:	e822                	sd	s0,16(sp)
    800020d4:	e426                	sd	s1,8(sp)
    800020d6:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800020d8:	00000097          	auipc	ra,0x0
    800020dc:	8ee080e7          	jalr	-1810(ra) # 800019c6 <myproc>
    800020e0:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020e2:	fffff097          	auipc	ra,0xfffff
    800020e6:	b08080e7          	jalr	-1272(ra) # 80000bea <acquire>
  p->state = RUNNABLE;
    800020ea:	478d                	li	a5,3
    800020ec:	cc9c                	sw	a5,24(s1)
  sched();
    800020ee:	00000097          	auipc	ra,0x0
    800020f2:	f0a080e7          	jalr	-246(ra) # 80001ff8 <sched>
  release(&p->lock);
    800020f6:	8526                	mv	a0,s1
    800020f8:	fffff097          	auipc	ra,0xfffff
    800020fc:	ba6080e7          	jalr	-1114(ra) # 80000c9e <release>
}
    80002100:	60e2                	ld	ra,24(sp)
    80002102:	6442                	ld	s0,16(sp)
    80002104:	64a2                	ld	s1,8(sp)
    80002106:	6105                	addi	sp,sp,32
    80002108:	8082                	ret

000000008000210a <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000210a:	7179                	addi	sp,sp,-48
    8000210c:	f406                	sd	ra,40(sp)
    8000210e:	f022                	sd	s0,32(sp)
    80002110:	ec26                	sd	s1,24(sp)
    80002112:	e84a                	sd	s2,16(sp)
    80002114:	e44e                	sd	s3,8(sp)
    80002116:	1800                	addi	s0,sp,48
    80002118:	89aa                	mv	s3,a0
    8000211a:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000211c:	00000097          	auipc	ra,0x0
    80002120:	8aa080e7          	jalr	-1878(ra) # 800019c6 <myproc>
    80002124:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002126:	fffff097          	auipc	ra,0xfffff
    8000212a:	ac4080e7          	jalr	-1340(ra) # 80000bea <acquire>
  release(lk);
    8000212e:	854a                	mv	a0,s2
    80002130:	fffff097          	auipc	ra,0xfffff
    80002134:	b6e080e7          	jalr	-1170(ra) # 80000c9e <release>

  // Go to sleep.
  p->chan = chan;
    80002138:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000213c:	4789                	li	a5,2
    8000213e:	cc9c                	sw	a5,24(s1)

  sched();
    80002140:	00000097          	auipc	ra,0x0
    80002144:	eb8080e7          	jalr	-328(ra) # 80001ff8 <sched>

  // Tidy up.
  p->chan = 0;
    80002148:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000214c:	8526                	mv	a0,s1
    8000214e:	fffff097          	auipc	ra,0xfffff
    80002152:	b50080e7          	jalr	-1200(ra) # 80000c9e <release>
  acquire(lk);
    80002156:	854a                	mv	a0,s2
    80002158:	fffff097          	auipc	ra,0xfffff
    8000215c:	a92080e7          	jalr	-1390(ra) # 80000bea <acquire>
}
    80002160:	70a2                	ld	ra,40(sp)
    80002162:	7402                	ld	s0,32(sp)
    80002164:	64e2                	ld	s1,24(sp)
    80002166:	6942                	ld	s2,16(sp)
    80002168:	69a2                	ld	s3,8(sp)
    8000216a:	6145                	addi	sp,sp,48
    8000216c:	8082                	ret

000000008000216e <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000216e:	7139                	addi	sp,sp,-64
    80002170:	fc06                	sd	ra,56(sp)
    80002172:	f822                	sd	s0,48(sp)
    80002174:	f426                	sd	s1,40(sp)
    80002176:	f04a                	sd	s2,32(sp)
    80002178:	ec4e                	sd	s3,24(sp)
    8000217a:	e852                	sd	s4,16(sp)
    8000217c:	e456                	sd	s5,8(sp)
    8000217e:	0080                	addi	s0,sp,64
    80002180:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002182:	0000f497          	auipc	s1,0xf
    80002186:	11e48493          	addi	s1,s1,286 # 800112a0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000218a:	4989                	li	s3,2
        p->state = RUNNABLE;
    8000218c:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000218e:	00015917          	auipc	s2,0x15
    80002192:	d1290913          	addi	s2,s2,-750 # 80016ea0 <tickslock>
    80002196:	a821                	j	800021ae <wakeup+0x40>
        p->state = RUNNABLE;
    80002198:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    8000219c:	8526                	mv	a0,s1
    8000219e:	fffff097          	auipc	ra,0xfffff
    800021a2:	b00080e7          	jalr	-1280(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800021a6:	17048493          	addi	s1,s1,368
    800021aa:	03248463          	beq	s1,s2,800021d2 <wakeup+0x64>
    if(p != myproc()){
    800021ae:	00000097          	auipc	ra,0x0
    800021b2:	818080e7          	jalr	-2024(ra) # 800019c6 <myproc>
    800021b6:	fea488e3          	beq	s1,a0,800021a6 <wakeup+0x38>
      acquire(&p->lock);
    800021ba:	8526                	mv	a0,s1
    800021bc:	fffff097          	auipc	ra,0xfffff
    800021c0:	a2e080e7          	jalr	-1490(ra) # 80000bea <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800021c4:	4c9c                	lw	a5,24(s1)
    800021c6:	fd379be3          	bne	a5,s3,8000219c <wakeup+0x2e>
    800021ca:	709c                	ld	a5,32(s1)
    800021cc:	fd4798e3          	bne	a5,s4,8000219c <wakeup+0x2e>
    800021d0:	b7e1                	j	80002198 <wakeup+0x2a>
    }
  }
}
    800021d2:	70e2                	ld	ra,56(sp)
    800021d4:	7442                	ld	s0,48(sp)
    800021d6:	74a2                	ld	s1,40(sp)
    800021d8:	7902                	ld	s2,32(sp)
    800021da:	69e2                	ld	s3,24(sp)
    800021dc:	6a42                	ld	s4,16(sp)
    800021de:	6aa2                	ld	s5,8(sp)
    800021e0:	6121                	addi	sp,sp,64
    800021e2:	8082                	ret

00000000800021e4 <reparent>:
{
    800021e4:	7179                	addi	sp,sp,-48
    800021e6:	f406                	sd	ra,40(sp)
    800021e8:	f022                	sd	s0,32(sp)
    800021ea:	ec26                	sd	s1,24(sp)
    800021ec:	e84a                	sd	s2,16(sp)
    800021ee:	e44e                	sd	s3,8(sp)
    800021f0:	e052                	sd	s4,0(sp)
    800021f2:	1800                	addi	s0,sp,48
    800021f4:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021f6:	0000f497          	auipc	s1,0xf
    800021fa:	0aa48493          	addi	s1,s1,170 # 800112a0 <proc>
      pp->parent = initproc;
    800021fe:	00007a17          	auipc	s4,0x7
    80002202:	9eaa0a13          	addi	s4,s4,-1558 # 80008be8 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002206:	00015997          	auipc	s3,0x15
    8000220a:	c9a98993          	addi	s3,s3,-870 # 80016ea0 <tickslock>
    8000220e:	a029                	j	80002218 <reparent+0x34>
    80002210:	17048493          	addi	s1,s1,368
    80002214:	01348d63          	beq	s1,s3,8000222e <reparent+0x4a>
    if(pp->parent == p){
    80002218:	7c9c                	ld	a5,56(s1)
    8000221a:	ff279be3          	bne	a5,s2,80002210 <reparent+0x2c>
      pp->parent = initproc;
    8000221e:	000a3503          	ld	a0,0(s4)
    80002222:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002224:	00000097          	auipc	ra,0x0
    80002228:	f4a080e7          	jalr	-182(ra) # 8000216e <wakeup>
    8000222c:	b7d5                	j	80002210 <reparent+0x2c>
}
    8000222e:	70a2                	ld	ra,40(sp)
    80002230:	7402                	ld	s0,32(sp)
    80002232:	64e2                	ld	s1,24(sp)
    80002234:	6942                	ld	s2,16(sp)
    80002236:	69a2                	ld	s3,8(sp)
    80002238:	6a02                	ld	s4,0(sp)
    8000223a:	6145                	addi	sp,sp,48
    8000223c:	8082                	ret

000000008000223e <exit>:
{
    8000223e:	7179                	addi	sp,sp,-48
    80002240:	f406                	sd	ra,40(sp)
    80002242:	f022                	sd	s0,32(sp)
    80002244:	ec26                	sd	s1,24(sp)
    80002246:	e84a                	sd	s2,16(sp)
    80002248:	e44e                	sd	s3,8(sp)
    8000224a:	e052                	sd	s4,0(sp)
    8000224c:	1800                	addi	s0,sp,48
    8000224e:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002250:	fffff097          	auipc	ra,0xfffff
    80002254:	776080e7          	jalr	1910(ra) # 800019c6 <myproc>
    80002258:	89aa                	mv	s3,a0
  if(p == initproc)
    8000225a:	00007797          	auipc	a5,0x7
    8000225e:	98e7b783          	ld	a5,-1650(a5) # 80008be8 <initproc>
    80002262:	0d050493          	addi	s1,a0,208
    80002266:	15050913          	addi	s2,a0,336
    8000226a:	02a79363          	bne	a5,a0,80002290 <exit+0x52>
    panic("init exiting");
    8000226e:	00006517          	auipc	a0,0x6
    80002272:	08a50513          	addi	a0,a0,138 # 800082f8 <digits+0x2b8>
    80002276:	ffffe097          	auipc	ra,0xffffe
    8000227a:	2ce080e7          	jalr	718(ra) # 80000544 <panic>
      fileclose(f);
    8000227e:	00002097          	auipc	ra,0x2
    80002282:	4f6080e7          	jalr	1270(ra) # 80004774 <fileclose>
      p->ofile[fd] = 0;
    80002286:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000228a:	04a1                	addi	s1,s1,8
    8000228c:	01248563          	beq	s1,s2,80002296 <exit+0x58>
    if(p->ofile[fd]){
    80002290:	6088                	ld	a0,0(s1)
    80002292:	f575                	bnez	a0,8000227e <exit+0x40>
    80002294:	bfdd                	j	8000228a <exit+0x4c>
  begin_op();
    80002296:	00002097          	auipc	ra,0x2
    8000229a:	012080e7          	jalr	18(ra) # 800042a8 <begin_op>
  iput(p->cwd);
    8000229e:	1509b503          	ld	a0,336(s3)
    800022a2:	00001097          	auipc	ra,0x1
    800022a6:	7fe080e7          	jalr	2046(ra) # 80003aa0 <iput>
  end_op();
    800022aa:	00002097          	auipc	ra,0x2
    800022ae:	07e080e7          	jalr	126(ra) # 80004328 <end_op>
  p->cwd = 0;
    800022b2:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800022b6:	0000f497          	auipc	s1,0xf
    800022ba:	bc248493          	addi	s1,s1,-1086 # 80010e78 <wait_lock>
    800022be:	8526                	mv	a0,s1
    800022c0:	fffff097          	auipc	ra,0xfffff
    800022c4:	92a080e7          	jalr	-1750(ra) # 80000bea <acquire>
  reparent(p);
    800022c8:	854e                	mv	a0,s3
    800022ca:	00000097          	auipc	ra,0x0
    800022ce:	f1a080e7          	jalr	-230(ra) # 800021e4 <reparent>
  wakeup(p->parent);
    800022d2:	0389b503          	ld	a0,56(s3)
    800022d6:	00000097          	auipc	ra,0x0
    800022da:	e98080e7          	jalr	-360(ra) # 8000216e <wakeup>
  acquire(&p->lock);
    800022de:	854e                	mv	a0,s3
    800022e0:	fffff097          	auipc	ra,0xfffff
    800022e4:	90a080e7          	jalr	-1782(ra) # 80000bea <acquire>
  p->xstate = status;
    800022e8:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800022ec:	4795                	li	a5,5
    800022ee:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800022f2:	8526                	mv	a0,s1
    800022f4:	fffff097          	auipc	ra,0xfffff
    800022f8:	9aa080e7          	jalr	-1622(ra) # 80000c9e <release>
  sched();
    800022fc:	00000097          	auipc	ra,0x0
    80002300:	cfc080e7          	jalr	-772(ra) # 80001ff8 <sched>
  panic("zombie exit");
    80002304:	00006517          	auipc	a0,0x6
    80002308:	00450513          	addi	a0,a0,4 # 80008308 <digits+0x2c8>
    8000230c:	ffffe097          	auipc	ra,0xffffe
    80002310:	238080e7          	jalr	568(ra) # 80000544 <panic>

0000000080002314 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002314:	7179                	addi	sp,sp,-48
    80002316:	f406                	sd	ra,40(sp)
    80002318:	f022                	sd	s0,32(sp)
    8000231a:	ec26                	sd	s1,24(sp)
    8000231c:	e84a                	sd	s2,16(sp)
    8000231e:	e44e                	sd	s3,8(sp)
    80002320:	1800                	addi	s0,sp,48
    80002322:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002324:	0000f497          	auipc	s1,0xf
    80002328:	f7c48493          	addi	s1,s1,-132 # 800112a0 <proc>
    8000232c:	00015997          	auipc	s3,0x15
    80002330:	b7498993          	addi	s3,s3,-1164 # 80016ea0 <tickslock>
    acquire(&p->lock);
    80002334:	8526                	mv	a0,s1
    80002336:	fffff097          	auipc	ra,0xfffff
    8000233a:	8b4080e7          	jalr	-1868(ra) # 80000bea <acquire>
    if(p->pid == pid){
    8000233e:	589c                	lw	a5,48(s1)
    80002340:	01278d63          	beq	a5,s2,8000235a <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002344:	8526                	mv	a0,s1
    80002346:	fffff097          	auipc	ra,0xfffff
    8000234a:	958080e7          	jalr	-1704(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000234e:	17048493          	addi	s1,s1,368
    80002352:	ff3491e3          	bne	s1,s3,80002334 <kill+0x20>
  }
  return -1;
    80002356:	557d                	li	a0,-1
    80002358:	a829                	j	80002372 <kill+0x5e>
      p->killed = 1;
    8000235a:	4785                	li	a5,1
    8000235c:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000235e:	4c98                	lw	a4,24(s1)
    80002360:	4789                	li	a5,2
    80002362:	00f70f63          	beq	a4,a5,80002380 <kill+0x6c>
      release(&p->lock);
    80002366:	8526                	mv	a0,s1
    80002368:	fffff097          	auipc	ra,0xfffff
    8000236c:	936080e7          	jalr	-1738(ra) # 80000c9e <release>
      return 0;
    80002370:	4501                	li	a0,0
}
    80002372:	70a2                	ld	ra,40(sp)
    80002374:	7402                	ld	s0,32(sp)
    80002376:	64e2                	ld	s1,24(sp)
    80002378:	6942                	ld	s2,16(sp)
    8000237a:	69a2                	ld	s3,8(sp)
    8000237c:	6145                	addi	sp,sp,48
    8000237e:	8082                	ret
        p->state = RUNNABLE;
    80002380:	478d                	li	a5,3
    80002382:	cc9c                	sw	a5,24(s1)
    80002384:	b7cd                	j	80002366 <kill+0x52>

0000000080002386 <setkilled>:

void
setkilled(struct proc *p)
{
    80002386:	1101                	addi	sp,sp,-32
    80002388:	ec06                	sd	ra,24(sp)
    8000238a:	e822                	sd	s0,16(sp)
    8000238c:	e426                	sd	s1,8(sp)
    8000238e:	1000                	addi	s0,sp,32
    80002390:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002392:	fffff097          	auipc	ra,0xfffff
    80002396:	858080e7          	jalr	-1960(ra) # 80000bea <acquire>
  p->killed = 1;
    8000239a:	4785                	li	a5,1
    8000239c:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    8000239e:	8526                	mv	a0,s1
    800023a0:	fffff097          	auipc	ra,0xfffff
    800023a4:	8fe080e7          	jalr	-1794(ra) # 80000c9e <release>
}
    800023a8:	60e2                	ld	ra,24(sp)
    800023aa:	6442                	ld	s0,16(sp)
    800023ac:	64a2                	ld	s1,8(sp)
    800023ae:	6105                	addi	sp,sp,32
    800023b0:	8082                	ret

00000000800023b2 <killed>:

int
killed(struct proc *p)
{
    800023b2:	1101                	addi	sp,sp,-32
    800023b4:	ec06                	sd	ra,24(sp)
    800023b6:	e822                	sd	s0,16(sp)
    800023b8:	e426                	sd	s1,8(sp)
    800023ba:	e04a                	sd	s2,0(sp)
    800023bc:	1000                	addi	s0,sp,32
    800023be:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    800023c0:	fffff097          	auipc	ra,0xfffff
    800023c4:	82a080e7          	jalr	-2006(ra) # 80000bea <acquire>
  k = p->killed;
    800023c8:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800023cc:	8526                	mv	a0,s1
    800023ce:	fffff097          	auipc	ra,0xfffff
    800023d2:	8d0080e7          	jalr	-1840(ra) # 80000c9e <release>
  return k;
}
    800023d6:	854a                	mv	a0,s2
    800023d8:	60e2                	ld	ra,24(sp)
    800023da:	6442                	ld	s0,16(sp)
    800023dc:	64a2                	ld	s1,8(sp)
    800023de:	6902                	ld	s2,0(sp)
    800023e0:	6105                	addi	sp,sp,32
    800023e2:	8082                	ret

00000000800023e4 <wait>:
{
    800023e4:	715d                	addi	sp,sp,-80
    800023e6:	e486                	sd	ra,72(sp)
    800023e8:	e0a2                	sd	s0,64(sp)
    800023ea:	fc26                	sd	s1,56(sp)
    800023ec:	f84a                	sd	s2,48(sp)
    800023ee:	f44e                	sd	s3,40(sp)
    800023f0:	f052                	sd	s4,32(sp)
    800023f2:	ec56                	sd	s5,24(sp)
    800023f4:	e85a                	sd	s6,16(sp)
    800023f6:	e45e                	sd	s7,8(sp)
    800023f8:	e062                	sd	s8,0(sp)
    800023fa:	0880                	addi	s0,sp,80
    800023fc:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800023fe:	fffff097          	auipc	ra,0xfffff
    80002402:	5c8080e7          	jalr	1480(ra) # 800019c6 <myproc>
    80002406:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002408:	0000f517          	auipc	a0,0xf
    8000240c:	a7050513          	addi	a0,a0,-1424 # 80010e78 <wait_lock>
    80002410:	ffffe097          	auipc	ra,0xffffe
    80002414:	7da080e7          	jalr	2010(ra) # 80000bea <acquire>
    havekids = 0;
    80002418:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    8000241a:	4a15                	li	s4,5
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000241c:	00015997          	auipc	s3,0x15
    80002420:	a8498993          	addi	s3,s3,-1404 # 80016ea0 <tickslock>
        havekids = 1;
    80002424:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002426:	0000fc17          	auipc	s8,0xf
    8000242a:	a52c0c13          	addi	s8,s8,-1454 # 80010e78 <wait_lock>
    havekids = 0;
    8000242e:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002430:	0000f497          	auipc	s1,0xf
    80002434:	e7048493          	addi	s1,s1,-400 # 800112a0 <proc>
    80002438:	a0bd                	j	800024a6 <wait+0xc2>
          pid = pp->pid;
    8000243a:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    8000243e:	000b0e63          	beqz	s6,8000245a <wait+0x76>
    80002442:	4691                	li	a3,4
    80002444:	02c48613          	addi	a2,s1,44
    80002448:	85da                	mv	a1,s6
    8000244a:	05093503          	ld	a0,80(s2)
    8000244e:	fffff097          	auipc	ra,0xfffff
    80002452:	236080e7          	jalr	566(ra) # 80001684 <copyout>
    80002456:	02054563          	bltz	a0,80002480 <wait+0x9c>
          freeproc(pp);
    8000245a:	8526                	mv	a0,s1
    8000245c:	fffff097          	auipc	ra,0xfffff
    80002460:	71c080e7          	jalr	1820(ra) # 80001b78 <freeproc>
          release(&pp->lock);
    80002464:	8526                	mv	a0,s1
    80002466:	fffff097          	auipc	ra,0xfffff
    8000246a:	838080e7          	jalr	-1992(ra) # 80000c9e <release>
          release(&wait_lock);
    8000246e:	0000f517          	auipc	a0,0xf
    80002472:	a0a50513          	addi	a0,a0,-1526 # 80010e78 <wait_lock>
    80002476:	fffff097          	auipc	ra,0xfffff
    8000247a:	828080e7          	jalr	-2008(ra) # 80000c9e <release>
          return pid;
    8000247e:	a0b5                	j	800024ea <wait+0x106>
            release(&pp->lock);
    80002480:	8526                	mv	a0,s1
    80002482:	fffff097          	auipc	ra,0xfffff
    80002486:	81c080e7          	jalr	-2020(ra) # 80000c9e <release>
            release(&wait_lock);
    8000248a:	0000f517          	auipc	a0,0xf
    8000248e:	9ee50513          	addi	a0,a0,-1554 # 80010e78 <wait_lock>
    80002492:	fffff097          	auipc	ra,0xfffff
    80002496:	80c080e7          	jalr	-2036(ra) # 80000c9e <release>
            return -1;
    8000249a:	59fd                	li	s3,-1
    8000249c:	a0b9                	j	800024ea <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000249e:	17048493          	addi	s1,s1,368
    800024a2:	03348463          	beq	s1,s3,800024ca <wait+0xe6>
      if(pp->parent == p){
    800024a6:	7c9c                	ld	a5,56(s1)
    800024a8:	ff279be3          	bne	a5,s2,8000249e <wait+0xba>
        acquire(&pp->lock);
    800024ac:	8526                	mv	a0,s1
    800024ae:	ffffe097          	auipc	ra,0xffffe
    800024b2:	73c080e7          	jalr	1852(ra) # 80000bea <acquire>
        if(pp->state == ZOMBIE){
    800024b6:	4c9c                	lw	a5,24(s1)
    800024b8:	f94781e3          	beq	a5,s4,8000243a <wait+0x56>
        release(&pp->lock);
    800024bc:	8526                	mv	a0,s1
    800024be:	ffffe097          	auipc	ra,0xffffe
    800024c2:	7e0080e7          	jalr	2016(ra) # 80000c9e <release>
        havekids = 1;
    800024c6:	8756                	mv	a4,s5
    800024c8:	bfd9                	j	8000249e <wait+0xba>
    if(!havekids || killed(p)){
    800024ca:	c719                	beqz	a4,800024d8 <wait+0xf4>
    800024cc:	854a                	mv	a0,s2
    800024ce:	00000097          	auipc	ra,0x0
    800024d2:	ee4080e7          	jalr	-284(ra) # 800023b2 <killed>
    800024d6:	c51d                	beqz	a0,80002504 <wait+0x120>
      release(&wait_lock);
    800024d8:	0000f517          	auipc	a0,0xf
    800024dc:	9a050513          	addi	a0,a0,-1632 # 80010e78 <wait_lock>
    800024e0:	ffffe097          	auipc	ra,0xffffe
    800024e4:	7be080e7          	jalr	1982(ra) # 80000c9e <release>
      return -1;
    800024e8:	59fd                	li	s3,-1
}
    800024ea:	854e                	mv	a0,s3
    800024ec:	60a6                	ld	ra,72(sp)
    800024ee:	6406                	ld	s0,64(sp)
    800024f0:	74e2                	ld	s1,56(sp)
    800024f2:	7942                	ld	s2,48(sp)
    800024f4:	79a2                	ld	s3,40(sp)
    800024f6:	7a02                	ld	s4,32(sp)
    800024f8:	6ae2                	ld	s5,24(sp)
    800024fa:	6b42                	ld	s6,16(sp)
    800024fc:	6ba2                	ld	s7,8(sp)
    800024fe:	6c02                	ld	s8,0(sp)
    80002500:	6161                	addi	sp,sp,80
    80002502:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002504:	85e2                	mv	a1,s8
    80002506:	854a                	mv	a0,s2
    80002508:	00000097          	auipc	ra,0x0
    8000250c:	c02080e7          	jalr	-1022(ra) # 8000210a <sleep>
    havekids = 0;
    80002510:	bf39                	j	8000242e <wait+0x4a>

0000000080002512 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002512:	7179                	addi	sp,sp,-48
    80002514:	f406                	sd	ra,40(sp)
    80002516:	f022                	sd	s0,32(sp)
    80002518:	ec26                	sd	s1,24(sp)
    8000251a:	e84a                	sd	s2,16(sp)
    8000251c:	e44e                	sd	s3,8(sp)
    8000251e:	e052                	sd	s4,0(sp)
    80002520:	1800                	addi	s0,sp,48
    80002522:	84aa                	mv	s1,a0
    80002524:	892e                	mv	s2,a1
    80002526:	89b2                	mv	s3,a2
    80002528:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000252a:	fffff097          	auipc	ra,0xfffff
    8000252e:	49c080e7          	jalr	1180(ra) # 800019c6 <myproc>
  if(user_dst){
    80002532:	c08d                	beqz	s1,80002554 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002534:	86d2                	mv	a3,s4
    80002536:	864e                	mv	a2,s3
    80002538:	85ca                	mv	a1,s2
    8000253a:	6928                	ld	a0,80(a0)
    8000253c:	fffff097          	auipc	ra,0xfffff
    80002540:	148080e7          	jalr	328(ra) # 80001684 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002544:	70a2                	ld	ra,40(sp)
    80002546:	7402                	ld	s0,32(sp)
    80002548:	64e2                	ld	s1,24(sp)
    8000254a:	6942                	ld	s2,16(sp)
    8000254c:	69a2                	ld	s3,8(sp)
    8000254e:	6a02                	ld	s4,0(sp)
    80002550:	6145                	addi	sp,sp,48
    80002552:	8082                	ret
    memmove((char *)dst, src, len);
    80002554:	000a061b          	sext.w	a2,s4
    80002558:	85ce                	mv	a1,s3
    8000255a:	854a                	mv	a0,s2
    8000255c:	ffffe097          	auipc	ra,0xffffe
    80002560:	7ea080e7          	jalr	2026(ra) # 80000d46 <memmove>
    return 0;
    80002564:	8526                	mv	a0,s1
    80002566:	bff9                	j	80002544 <either_copyout+0x32>

0000000080002568 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002568:	7179                	addi	sp,sp,-48
    8000256a:	f406                	sd	ra,40(sp)
    8000256c:	f022                	sd	s0,32(sp)
    8000256e:	ec26                	sd	s1,24(sp)
    80002570:	e84a                	sd	s2,16(sp)
    80002572:	e44e                	sd	s3,8(sp)
    80002574:	e052                	sd	s4,0(sp)
    80002576:	1800                	addi	s0,sp,48
    80002578:	892a                	mv	s2,a0
    8000257a:	84ae                	mv	s1,a1
    8000257c:	89b2                	mv	s3,a2
    8000257e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002580:	fffff097          	auipc	ra,0xfffff
    80002584:	446080e7          	jalr	1094(ra) # 800019c6 <myproc>
  if(user_src){
    80002588:	c08d                	beqz	s1,800025aa <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000258a:	86d2                	mv	a3,s4
    8000258c:	864e                	mv	a2,s3
    8000258e:	85ca                	mv	a1,s2
    80002590:	6928                	ld	a0,80(a0)
    80002592:	fffff097          	auipc	ra,0xfffff
    80002596:	17e080e7          	jalr	382(ra) # 80001710 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000259a:	70a2                	ld	ra,40(sp)
    8000259c:	7402                	ld	s0,32(sp)
    8000259e:	64e2                	ld	s1,24(sp)
    800025a0:	6942                	ld	s2,16(sp)
    800025a2:	69a2                	ld	s3,8(sp)
    800025a4:	6a02                	ld	s4,0(sp)
    800025a6:	6145                	addi	sp,sp,48
    800025a8:	8082                	ret
    memmove(dst, (char*)src, len);
    800025aa:	000a061b          	sext.w	a2,s4
    800025ae:	85ce                	mv	a1,s3
    800025b0:	854a                	mv	a0,s2
    800025b2:	ffffe097          	auipc	ra,0xffffe
    800025b6:	794080e7          	jalr	1940(ra) # 80000d46 <memmove>
    return 0;
    800025ba:	8526                	mv	a0,s1
    800025bc:	bff9                	j	8000259a <either_copyin+0x32>

00000000800025be <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800025be:	715d                	addi	sp,sp,-80
    800025c0:	e486                	sd	ra,72(sp)
    800025c2:	e0a2                	sd	s0,64(sp)
    800025c4:	fc26                	sd	s1,56(sp)
    800025c6:	f84a                	sd	s2,48(sp)
    800025c8:	f44e                	sd	s3,40(sp)
    800025ca:	f052                	sd	s4,32(sp)
    800025cc:	ec56                	sd	s5,24(sp)
    800025ce:	e85a                	sd	s6,16(sp)
    800025d0:	e45e                	sd	s7,8(sp)
    800025d2:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;
  
  printf("\n");
    800025d4:	00006517          	auipc	a0,0x6
    800025d8:	af450513          	addi	a0,a0,-1292 # 800080c8 <digits+0x88>
    800025dc:	ffffe097          	auipc	ra,0xffffe
    800025e0:	fb2080e7          	jalr	-78(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025e4:	0000f497          	auipc	s1,0xf
    800025e8:	e1448493          	addi	s1,s1,-492 # 800113f8 <proc+0x158>
    800025ec:	00015917          	auipc	s2,0x15
    800025f0:	a0c90913          	addi	s2,s2,-1524 # 80016ff8 <bruh+0xd8>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025f4:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800025f6:	00006997          	auipc	s3,0x6
    800025fa:	d2298993          	addi	s3,s3,-734 # 80008318 <digits+0x2d8>
    printf("%d %s %s", p->pid, state, p->name);
    800025fe:	00006a97          	auipc	s5,0x6
    80002602:	d22a8a93          	addi	s5,s5,-734 # 80008320 <digits+0x2e0>
    printf("\n");
    80002606:	00006a17          	auipc	s4,0x6
    8000260a:	ac2a0a13          	addi	s4,s4,-1342 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000260e:	00006b97          	auipc	s7,0x6
    80002612:	d5ab8b93          	addi	s7,s7,-678 # 80008368 <states.1782>
    80002616:	a00d                	j	80002638 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002618:	ed86a583          	lw	a1,-296(a3)
    8000261c:	8556                	mv	a0,s5
    8000261e:	ffffe097          	auipc	ra,0xffffe
    80002622:	f70080e7          	jalr	-144(ra) # 8000058e <printf>
    printf("\n");
    80002626:	8552                	mv	a0,s4
    80002628:	ffffe097          	auipc	ra,0xffffe
    8000262c:	f66080e7          	jalr	-154(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002630:	17048493          	addi	s1,s1,368
    80002634:	03248163          	beq	s1,s2,80002656 <procdump+0x98>
    if(p->state == UNUSED)
    80002638:	86a6                	mv	a3,s1
    8000263a:	ec04a783          	lw	a5,-320(s1)
    8000263e:	dbed                	beqz	a5,80002630 <procdump+0x72>
      state = "???";
    80002640:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002642:	fcfb6be3          	bltu	s6,a5,80002618 <procdump+0x5a>
    80002646:	1782                	slli	a5,a5,0x20
    80002648:	9381                	srli	a5,a5,0x20
    8000264a:	078e                	slli	a5,a5,0x3
    8000264c:	97de                	add	a5,a5,s7
    8000264e:	6390                	ld	a2,0(a5)
    80002650:	f661                	bnez	a2,80002618 <procdump+0x5a>
      state = "???";
    80002652:	864e                	mv	a2,s3
    80002654:	b7d1                	j	80002618 <procdump+0x5a>
  }
}
    80002656:	60a6                	ld	ra,72(sp)
    80002658:	6406                	ld	s0,64(sp)
    8000265a:	74e2                	ld	s1,56(sp)
    8000265c:	7942                	ld	s2,48(sp)
    8000265e:	79a2                	ld	s3,40(sp)
    80002660:	7a02                	ld	s4,32(sp)
    80002662:	6ae2                	ld	s5,24(sp)
    80002664:	6b42                	ld	s6,16(sp)
    80002666:	6ba2                	ld	s7,8(sp)
    80002668:	6161                	addi	sp,sp,80
    8000266a:	8082                	ret

000000008000266c <logs>:

uint64 logs(void *arg)
{
    8000266c:	715d                	addi	sp,sp,-80
    8000266e:	e486                	sd	ra,72(sp)
    80002670:	e0a2                	sd	s0,64(sp)
    80002672:	0880                	addi	s0,sp,80
    
    struct audit_node node = {.process_name = "Proc1\n", .pid = 0};
    80002674:	fc043423          	sd	zero,-56(s0)
    80002678:	fc043823          	sd	zero,-48(s0)
    8000267c:	fc043c23          	sd	zero,-40(s0)
    80002680:	fe043423          	sd	zero,-24(s0)
    80002684:	00006797          	auipc	a5,0x6
    80002688:	cac78793          	addi	a5,a5,-852 # 80008330 <digits+0x2f0>
    8000268c:	fef43023          	sd	a5,-32(s0)
    node.next = &node1;
    node1.next = &node2;
    node2.next = &node3;
    */
    struct audit_list auditlist;
    auditlist.size = 4;
    80002690:	4791                	li	a5,4
    80002692:	faf42c23          	sw	a5,-72(s0)
    auditlist.head = &node;
    80002696:	fc840793          	addi	a5,s0,-56
    8000269a:	fcf43023          	sd	a5,-64(s0)

    write_to_logs((void *)&auditlist);
    8000269e:	fb840513          	addi	a0,s0,-72
    800026a2:	00004097          	auipc	ra,0x4
    800026a6:	046080e7          	jalr	70(ra) # 800066e8 <write_to_logs>
    return (uint64)1;
}
    800026aa:	4505                	li	a0,1
    800026ac:	60a6                	ld	ra,72(sp)
    800026ae:	6406                	ld	s0,64(sp)
    800026b0:	6161                	addi	sp,sp,80
    800026b2:	8082                	ret

00000000800026b4 <swtch>:
    800026b4:	00153023          	sd	ra,0(a0)
    800026b8:	00253423          	sd	sp,8(a0)
    800026bc:	e900                	sd	s0,16(a0)
    800026be:	ed04                	sd	s1,24(a0)
    800026c0:	03253023          	sd	s2,32(a0)
    800026c4:	03353423          	sd	s3,40(a0)
    800026c8:	03453823          	sd	s4,48(a0)
    800026cc:	03553c23          	sd	s5,56(a0)
    800026d0:	05653023          	sd	s6,64(a0)
    800026d4:	05753423          	sd	s7,72(a0)
    800026d8:	05853823          	sd	s8,80(a0)
    800026dc:	05953c23          	sd	s9,88(a0)
    800026e0:	07a53023          	sd	s10,96(a0)
    800026e4:	07b53423          	sd	s11,104(a0)
    800026e8:	0005b083          	ld	ra,0(a1)
    800026ec:	0085b103          	ld	sp,8(a1)
    800026f0:	6980                	ld	s0,16(a1)
    800026f2:	6d84                	ld	s1,24(a1)
    800026f4:	0205b903          	ld	s2,32(a1)
    800026f8:	0285b983          	ld	s3,40(a1)
    800026fc:	0305ba03          	ld	s4,48(a1)
    80002700:	0385ba83          	ld	s5,56(a1)
    80002704:	0405bb03          	ld	s6,64(a1)
    80002708:	0485bb83          	ld	s7,72(a1)
    8000270c:	0505bc03          	ld	s8,80(a1)
    80002710:	0585bc83          	ld	s9,88(a1)
    80002714:	0605bd03          	ld	s10,96(a1)
    80002718:	0685bd83          	ld	s11,104(a1)
    8000271c:	8082                	ret

000000008000271e <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000271e:	1141                	addi	sp,sp,-16
    80002720:	e406                	sd	ra,8(sp)
    80002722:	e022                	sd	s0,0(sp)
    80002724:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002726:	00006597          	auipc	a1,0x6
    8000272a:	c7258593          	addi	a1,a1,-910 # 80008398 <states.1782+0x30>
    8000272e:	00014517          	auipc	a0,0x14
    80002732:	77250513          	addi	a0,a0,1906 # 80016ea0 <tickslock>
    80002736:	ffffe097          	auipc	ra,0xffffe
    8000273a:	424080e7          	jalr	1060(ra) # 80000b5a <initlock>
}
    8000273e:	60a2                	ld	ra,8(sp)
    80002740:	6402                	ld	s0,0(sp)
    80002742:	0141                	addi	sp,sp,16
    80002744:	8082                	ret

0000000080002746 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002746:	1141                	addi	sp,sp,-16
    80002748:	e422                	sd	s0,8(sp)
    8000274a:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000274c:	00003797          	auipc	a5,0x3
    80002750:	66478793          	addi	a5,a5,1636 # 80005db0 <kernelvec>
    80002754:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002758:	6422                	ld	s0,8(sp)
    8000275a:	0141                	addi	sp,sp,16
    8000275c:	8082                	ret

000000008000275e <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000275e:	1141                	addi	sp,sp,-16
    80002760:	e406                	sd	ra,8(sp)
    80002762:	e022                	sd	s0,0(sp)
    80002764:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002766:	fffff097          	auipc	ra,0xfffff
    8000276a:	260080e7          	jalr	608(ra) # 800019c6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000276e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002772:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002774:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002778:	00005617          	auipc	a2,0x5
    8000277c:	88860613          	addi	a2,a2,-1912 # 80007000 <_trampoline>
    80002780:	00005697          	auipc	a3,0x5
    80002784:	88068693          	addi	a3,a3,-1920 # 80007000 <_trampoline>
    80002788:	8e91                	sub	a3,a3,a2
    8000278a:	040007b7          	lui	a5,0x4000
    8000278e:	17fd                	addi	a5,a5,-1
    80002790:	07b2                	slli	a5,a5,0xc
    80002792:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002794:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002798:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000279a:	180026f3          	csrr	a3,satp
    8000279e:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800027a0:	6d38                	ld	a4,88(a0)
    800027a2:	6134                	ld	a3,64(a0)
    800027a4:	6585                	lui	a1,0x1
    800027a6:	96ae                	add	a3,a3,a1
    800027a8:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800027aa:	6d38                	ld	a4,88(a0)
    800027ac:	00000697          	auipc	a3,0x0
    800027b0:	13068693          	addi	a3,a3,304 # 800028dc <usertrap>
    800027b4:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800027b6:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800027b8:	8692                	mv	a3,tp
    800027ba:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027bc:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800027c0:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800027c4:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027c8:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800027cc:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800027ce:	6f18                	ld	a4,24(a4)
    800027d0:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800027d4:	6928                	ld	a0,80(a0)
    800027d6:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800027d8:	00005717          	auipc	a4,0x5
    800027dc:	8c470713          	addi	a4,a4,-1852 # 8000709c <userret>
    800027e0:	8f11                	sub	a4,a4,a2
    800027e2:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800027e4:	577d                	li	a4,-1
    800027e6:	177e                	slli	a4,a4,0x3f
    800027e8:	8d59                	or	a0,a0,a4
    800027ea:	9782                	jalr	a5
}
    800027ec:	60a2                	ld	ra,8(sp)
    800027ee:	6402                	ld	s0,0(sp)
    800027f0:	0141                	addi	sp,sp,16
    800027f2:	8082                	ret

00000000800027f4 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800027f4:	1101                	addi	sp,sp,-32
    800027f6:	ec06                	sd	ra,24(sp)
    800027f8:	e822                	sd	s0,16(sp)
    800027fa:	e426                	sd	s1,8(sp)
    800027fc:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800027fe:	00014497          	auipc	s1,0x14
    80002802:	6a248493          	addi	s1,s1,1698 # 80016ea0 <tickslock>
    80002806:	8526                	mv	a0,s1
    80002808:	ffffe097          	auipc	ra,0xffffe
    8000280c:	3e2080e7          	jalr	994(ra) # 80000bea <acquire>
  ticks++;
    80002810:	00006517          	auipc	a0,0x6
    80002814:	3e050513          	addi	a0,a0,992 # 80008bf0 <ticks>
    80002818:	411c                	lw	a5,0(a0)
    8000281a:	2785                	addiw	a5,a5,1
    8000281c:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    8000281e:	00000097          	auipc	ra,0x0
    80002822:	950080e7          	jalr	-1712(ra) # 8000216e <wakeup>
  release(&tickslock);
    80002826:	8526                	mv	a0,s1
    80002828:	ffffe097          	auipc	ra,0xffffe
    8000282c:	476080e7          	jalr	1142(ra) # 80000c9e <release>
}
    80002830:	60e2                	ld	ra,24(sp)
    80002832:	6442                	ld	s0,16(sp)
    80002834:	64a2                	ld	s1,8(sp)
    80002836:	6105                	addi	sp,sp,32
    80002838:	8082                	ret

000000008000283a <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000283a:	1101                	addi	sp,sp,-32
    8000283c:	ec06                	sd	ra,24(sp)
    8000283e:	e822                	sd	s0,16(sp)
    80002840:	e426                	sd	s1,8(sp)
    80002842:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002844:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002848:	00074d63          	bltz	a4,80002862 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000284c:	57fd                	li	a5,-1
    8000284e:	17fe                	slli	a5,a5,0x3f
    80002850:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002852:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002854:	06f70363          	beq	a4,a5,800028ba <devintr+0x80>
  }
}
    80002858:	60e2                	ld	ra,24(sp)
    8000285a:	6442                	ld	s0,16(sp)
    8000285c:	64a2                	ld	s1,8(sp)
    8000285e:	6105                	addi	sp,sp,32
    80002860:	8082                	ret
     (scause & 0xff) == 9){
    80002862:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002866:	46a5                	li	a3,9
    80002868:	fed792e3          	bne	a5,a3,8000284c <devintr+0x12>
    int irq = plic_claim();
    8000286c:	00003097          	auipc	ra,0x3
    80002870:	64c080e7          	jalr	1612(ra) # 80005eb8 <plic_claim>
    80002874:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002876:	47a9                	li	a5,10
    80002878:	02f50763          	beq	a0,a5,800028a6 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000287c:	4785                	li	a5,1
    8000287e:	02f50963          	beq	a0,a5,800028b0 <devintr+0x76>
    return 1;
    80002882:	4505                	li	a0,1
    } else if(irq){
    80002884:	d8f1                	beqz	s1,80002858 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002886:	85a6                	mv	a1,s1
    80002888:	00006517          	auipc	a0,0x6
    8000288c:	b1850513          	addi	a0,a0,-1256 # 800083a0 <states.1782+0x38>
    80002890:	ffffe097          	auipc	ra,0xffffe
    80002894:	cfe080e7          	jalr	-770(ra) # 8000058e <printf>
      plic_complete(irq);
    80002898:	8526                	mv	a0,s1
    8000289a:	00003097          	auipc	ra,0x3
    8000289e:	642080e7          	jalr	1602(ra) # 80005edc <plic_complete>
    return 1;
    800028a2:	4505                	li	a0,1
    800028a4:	bf55                	j	80002858 <devintr+0x1e>
      uartintr();
    800028a6:	ffffe097          	auipc	ra,0xffffe
    800028aa:	108080e7          	jalr	264(ra) # 800009ae <uartintr>
    800028ae:	b7ed                	j	80002898 <devintr+0x5e>
      virtio_disk_intr();
    800028b0:	00004097          	auipc	ra,0x4
    800028b4:	b56080e7          	jalr	-1194(ra) # 80006406 <virtio_disk_intr>
    800028b8:	b7c5                	j	80002898 <devintr+0x5e>
    if(cpuid() == 0){
    800028ba:	fffff097          	auipc	ra,0xfffff
    800028be:	0e0080e7          	jalr	224(ra) # 8000199a <cpuid>
    800028c2:	c901                	beqz	a0,800028d2 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800028c4:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800028c8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800028ca:	14479073          	csrw	sip,a5
    return 2;
    800028ce:	4509                	li	a0,2
    800028d0:	b761                	j	80002858 <devintr+0x1e>
      clockintr();
    800028d2:	00000097          	auipc	ra,0x0
    800028d6:	f22080e7          	jalr	-222(ra) # 800027f4 <clockintr>
    800028da:	b7ed                	j	800028c4 <devintr+0x8a>

00000000800028dc <usertrap>:
{
    800028dc:	1101                	addi	sp,sp,-32
    800028de:	ec06                	sd	ra,24(sp)
    800028e0:	e822                	sd	s0,16(sp)
    800028e2:	e426                	sd	s1,8(sp)
    800028e4:	e04a                	sd	s2,0(sp)
    800028e6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028e8:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800028ec:	1007f793          	andi	a5,a5,256
    800028f0:	e3b1                	bnez	a5,80002934 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028f2:	00003797          	auipc	a5,0x3
    800028f6:	4be78793          	addi	a5,a5,1214 # 80005db0 <kernelvec>
    800028fa:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800028fe:	fffff097          	auipc	ra,0xfffff
    80002902:	0c8080e7          	jalr	200(ra) # 800019c6 <myproc>
    80002906:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002908:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000290a:	14102773          	csrr	a4,sepc
    8000290e:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002910:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002914:	47a1                	li	a5,8
    80002916:	02f70763          	beq	a4,a5,80002944 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    8000291a:	00000097          	auipc	ra,0x0
    8000291e:	f20080e7          	jalr	-224(ra) # 8000283a <devintr>
    80002922:	892a                	mv	s2,a0
    80002924:	c151                	beqz	a0,800029a8 <usertrap+0xcc>
  if(killed(p))
    80002926:	8526                	mv	a0,s1
    80002928:	00000097          	auipc	ra,0x0
    8000292c:	a8a080e7          	jalr	-1398(ra) # 800023b2 <killed>
    80002930:	c929                	beqz	a0,80002982 <usertrap+0xa6>
    80002932:	a099                	j	80002978 <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002934:	00006517          	auipc	a0,0x6
    80002938:	a8c50513          	addi	a0,a0,-1396 # 800083c0 <states.1782+0x58>
    8000293c:	ffffe097          	auipc	ra,0xffffe
    80002940:	c08080e7          	jalr	-1016(ra) # 80000544 <panic>
    if(killed(p))
    80002944:	00000097          	auipc	ra,0x0
    80002948:	a6e080e7          	jalr	-1426(ra) # 800023b2 <killed>
    8000294c:	e921                	bnez	a0,8000299c <usertrap+0xc0>
    p->trapframe->epc += 4;
    8000294e:	6cb8                	ld	a4,88(s1)
    80002950:	6f1c                	ld	a5,24(a4)
    80002952:	0791                	addi	a5,a5,4
    80002954:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002956:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000295a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000295e:	10079073          	csrw	sstatus,a5
    syscall();
    80002962:	00000097          	auipc	ra,0x0
    80002966:	2d4080e7          	jalr	724(ra) # 80002c36 <syscall>
  if(killed(p))
    8000296a:	8526                	mv	a0,s1
    8000296c:	00000097          	auipc	ra,0x0
    80002970:	a46080e7          	jalr	-1466(ra) # 800023b2 <killed>
    80002974:	c911                	beqz	a0,80002988 <usertrap+0xac>
    80002976:	4901                	li	s2,0
    exit(-1);
    80002978:	557d                	li	a0,-1
    8000297a:	00000097          	auipc	ra,0x0
    8000297e:	8c4080e7          	jalr	-1852(ra) # 8000223e <exit>
  if(which_dev == 2)
    80002982:	4789                	li	a5,2
    80002984:	04f90f63          	beq	s2,a5,800029e2 <usertrap+0x106>
  usertrapret();
    80002988:	00000097          	auipc	ra,0x0
    8000298c:	dd6080e7          	jalr	-554(ra) # 8000275e <usertrapret>
}
    80002990:	60e2                	ld	ra,24(sp)
    80002992:	6442                	ld	s0,16(sp)
    80002994:	64a2                	ld	s1,8(sp)
    80002996:	6902                	ld	s2,0(sp)
    80002998:	6105                	addi	sp,sp,32
    8000299a:	8082                	ret
      exit(-1);
    8000299c:	557d                	li	a0,-1
    8000299e:	00000097          	auipc	ra,0x0
    800029a2:	8a0080e7          	jalr	-1888(ra) # 8000223e <exit>
    800029a6:	b765                	j	8000294e <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029a8:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800029ac:	5890                	lw	a2,48(s1)
    800029ae:	00006517          	auipc	a0,0x6
    800029b2:	a3250513          	addi	a0,a0,-1486 # 800083e0 <states.1782+0x78>
    800029b6:	ffffe097          	auipc	ra,0xffffe
    800029ba:	bd8080e7          	jalr	-1064(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029be:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029c2:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029c6:	00006517          	auipc	a0,0x6
    800029ca:	a4a50513          	addi	a0,a0,-1462 # 80008410 <states.1782+0xa8>
    800029ce:	ffffe097          	auipc	ra,0xffffe
    800029d2:	bc0080e7          	jalr	-1088(ra) # 8000058e <printf>
    setkilled(p);
    800029d6:	8526                	mv	a0,s1
    800029d8:	00000097          	auipc	ra,0x0
    800029dc:	9ae080e7          	jalr	-1618(ra) # 80002386 <setkilled>
    800029e0:	b769                	j	8000296a <usertrap+0x8e>
    yield();
    800029e2:	fffff097          	auipc	ra,0xfffff
    800029e6:	6ec080e7          	jalr	1772(ra) # 800020ce <yield>
    800029ea:	bf79                	j	80002988 <usertrap+0xac>

00000000800029ec <kerneltrap>:
{
    800029ec:	7179                	addi	sp,sp,-48
    800029ee:	f406                	sd	ra,40(sp)
    800029f0:	f022                	sd	s0,32(sp)
    800029f2:	ec26                	sd	s1,24(sp)
    800029f4:	e84a                	sd	s2,16(sp)
    800029f6:	e44e                	sd	s3,8(sp)
    800029f8:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029fa:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029fe:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a02:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002a06:	1004f793          	andi	a5,s1,256
    80002a0a:	cb85                	beqz	a5,80002a3a <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a0c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a10:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002a12:	ef85                	bnez	a5,80002a4a <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002a14:	00000097          	auipc	ra,0x0
    80002a18:	e26080e7          	jalr	-474(ra) # 8000283a <devintr>
    80002a1c:	cd1d                	beqz	a0,80002a5a <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a1e:	4789                	li	a5,2
    80002a20:	06f50a63          	beq	a0,a5,80002a94 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a24:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a28:	10049073          	csrw	sstatus,s1
}
    80002a2c:	70a2                	ld	ra,40(sp)
    80002a2e:	7402                	ld	s0,32(sp)
    80002a30:	64e2                	ld	s1,24(sp)
    80002a32:	6942                	ld	s2,16(sp)
    80002a34:	69a2                	ld	s3,8(sp)
    80002a36:	6145                	addi	sp,sp,48
    80002a38:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a3a:	00006517          	auipc	a0,0x6
    80002a3e:	9f650513          	addi	a0,a0,-1546 # 80008430 <states.1782+0xc8>
    80002a42:	ffffe097          	auipc	ra,0xffffe
    80002a46:	b02080e7          	jalr	-1278(ra) # 80000544 <panic>
    panic("kerneltrap: interrupts enabled");
    80002a4a:	00006517          	auipc	a0,0x6
    80002a4e:	a0e50513          	addi	a0,a0,-1522 # 80008458 <states.1782+0xf0>
    80002a52:	ffffe097          	auipc	ra,0xffffe
    80002a56:	af2080e7          	jalr	-1294(ra) # 80000544 <panic>
    printf("scause %p\n", scause);
    80002a5a:	85ce                	mv	a1,s3
    80002a5c:	00006517          	auipc	a0,0x6
    80002a60:	a1c50513          	addi	a0,a0,-1508 # 80008478 <states.1782+0x110>
    80002a64:	ffffe097          	auipc	ra,0xffffe
    80002a68:	b2a080e7          	jalr	-1238(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a6c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a70:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a74:	00006517          	auipc	a0,0x6
    80002a78:	a1450513          	addi	a0,a0,-1516 # 80008488 <states.1782+0x120>
    80002a7c:	ffffe097          	auipc	ra,0xffffe
    80002a80:	b12080e7          	jalr	-1262(ra) # 8000058e <printf>
    panic("kerneltrap");
    80002a84:	00006517          	auipc	a0,0x6
    80002a88:	a1c50513          	addi	a0,a0,-1508 # 800084a0 <states.1782+0x138>
    80002a8c:	ffffe097          	auipc	ra,0xffffe
    80002a90:	ab8080e7          	jalr	-1352(ra) # 80000544 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a94:	fffff097          	auipc	ra,0xfffff
    80002a98:	f32080e7          	jalr	-206(ra) # 800019c6 <myproc>
    80002a9c:	d541                	beqz	a0,80002a24 <kerneltrap+0x38>
    80002a9e:	fffff097          	auipc	ra,0xfffff
    80002aa2:	f28080e7          	jalr	-216(ra) # 800019c6 <myproc>
    80002aa6:	4d18                	lw	a4,24(a0)
    80002aa8:	4791                	li	a5,4
    80002aaa:	f6f71de3          	bne	a4,a5,80002a24 <kerneltrap+0x38>
    yield();
    80002aae:	fffff097          	auipc	ra,0xfffff
    80002ab2:	620080e7          	jalr	1568(ra) # 800020ce <yield>
    80002ab6:	b7bd                	j	80002a24 <kerneltrap+0x38>

0000000080002ab8 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002ab8:	1101                	addi	sp,sp,-32
    80002aba:	ec06                	sd	ra,24(sp)
    80002abc:	e822                	sd	s0,16(sp)
    80002abe:	e426                	sd	s1,8(sp)
    80002ac0:	1000                	addi	s0,sp,32
    80002ac2:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002ac4:	fffff097          	auipc	ra,0xfffff
    80002ac8:	f02080e7          	jalr	-254(ra) # 800019c6 <myproc>
  switch (n) {
    80002acc:	4795                	li	a5,5
    80002ace:	0497e163          	bltu	a5,s1,80002b10 <argraw+0x58>
    80002ad2:	048a                	slli	s1,s1,0x2
    80002ad4:	00006717          	auipc	a4,0x6
    80002ad8:	b0c70713          	addi	a4,a4,-1268 # 800085e0 <states.1782+0x278>
    80002adc:	94ba                	add	s1,s1,a4
    80002ade:	409c                	lw	a5,0(s1)
    80002ae0:	97ba                	add	a5,a5,a4
    80002ae2:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002ae4:	6d3c                	ld	a5,88(a0)
    80002ae6:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002ae8:	60e2                	ld	ra,24(sp)
    80002aea:	6442                	ld	s0,16(sp)
    80002aec:	64a2                	ld	s1,8(sp)
    80002aee:	6105                	addi	sp,sp,32
    80002af0:	8082                	ret
    return p->trapframe->a1;
    80002af2:	6d3c                	ld	a5,88(a0)
    80002af4:	7fa8                	ld	a0,120(a5)
    80002af6:	bfcd                	j	80002ae8 <argraw+0x30>
    return p->trapframe->a2;
    80002af8:	6d3c                	ld	a5,88(a0)
    80002afa:	63c8                	ld	a0,128(a5)
    80002afc:	b7f5                	j	80002ae8 <argraw+0x30>
    return p->trapframe->a3;
    80002afe:	6d3c                	ld	a5,88(a0)
    80002b00:	67c8                	ld	a0,136(a5)
    80002b02:	b7dd                	j	80002ae8 <argraw+0x30>
    return p->trapframe->a4;
    80002b04:	6d3c                	ld	a5,88(a0)
    80002b06:	6bc8                	ld	a0,144(a5)
    80002b08:	b7c5                	j	80002ae8 <argraw+0x30>
    return p->trapframe->a5;
    80002b0a:	6d3c                	ld	a5,88(a0)
    80002b0c:	6fc8                	ld	a0,152(a5)
    80002b0e:	bfe9                	j	80002ae8 <argraw+0x30>
  panic("argraw");
    80002b10:	00006517          	auipc	a0,0x6
    80002b14:	9a050513          	addi	a0,a0,-1632 # 800084b0 <states.1782+0x148>
    80002b18:	ffffe097          	auipc	ra,0xffffe
    80002b1c:	a2c080e7          	jalr	-1492(ra) # 80000544 <panic>

0000000080002b20 <fetchaddr>:
{
    80002b20:	1101                	addi	sp,sp,-32
    80002b22:	ec06                	sd	ra,24(sp)
    80002b24:	e822                	sd	s0,16(sp)
    80002b26:	e426                	sd	s1,8(sp)
    80002b28:	e04a                	sd	s2,0(sp)
    80002b2a:	1000                	addi	s0,sp,32
    80002b2c:	84aa                	mv	s1,a0
    80002b2e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b30:	fffff097          	auipc	ra,0xfffff
    80002b34:	e96080e7          	jalr	-362(ra) # 800019c6 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002b38:	653c                	ld	a5,72(a0)
    80002b3a:	02f4f863          	bgeu	s1,a5,80002b6a <fetchaddr+0x4a>
    80002b3e:	00848713          	addi	a4,s1,8
    80002b42:	02e7e663          	bltu	a5,a4,80002b6e <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b46:	46a1                	li	a3,8
    80002b48:	8626                	mv	a2,s1
    80002b4a:	85ca                	mv	a1,s2
    80002b4c:	6928                	ld	a0,80(a0)
    80002b4e:	fffff097          	auipc	ra,0xfffff
    80002b52:	bc2080e7          	jalr	-1086(ra) # 80001710 <copyin>
    80002b56:	00a03533          	snez	a0,a0
    80002b5a:	40a00533          	neg	a0,a0
}
    80002b5e:	60e2                	ld	ra,24(sp)
    80002b60:	6442                	ld	s0,16(sp)
    80002b62:	64a2                	ld	s1,8(sp)
    80002b64:	6902                	ld	s2,0(sp)
    80002b66:	6105                	addi	sp,sp,32
    80002b68:	8082                	ret
    return -1;
    80002b6a:	557d                	li	a0,-1
    80002b6c:	bfcd                	j	80002b5e <fetchaddr+0x3e>
    80002b6e:	557d                	li	a0,-1
    80002b70:	b7fd                	j	80002b5e <fetchaddr+0x3e>

0000000080002b72 <fetchstr>:
{
    80002b72:	7179                	addi	sp,sp,-48
    80002b74:	f406                	sd	ra,40(sp)
    80002b76:	f022                	sd	s0,32(sp)
    80002b78:	ec26                	sd	s1,24(sp)
    80002b7a:	e84a                	sd	s2,16(sp)
    80002b7c:	e44e                	sd	s3,8(sp)
    80002b7e:	1800                	addi	s0,sp,48
    80002b80:	892a                	mv	s2,a0
    80002b82:	84ae                	mv	s1,a1
    80002b84:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b86:	fffff097          	auipc	ra,0xfffff
    80002b8a:	e40080e7          	jalr	-448(ra) # 800019c6 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002b8e:	86ce                	mv	a3,s3
    80002b90:	864a                	mv	a2,s2
    80002b92:	85a6                	mv	a1,s1
    80002b94:	6928                	ld	a0,80(a0)
    80002b96:	fffff097          	auipc	ra,0xfffff
    80002b9a:	c06080e7          	jalr	-1018(ra) # 8000179c <copyinstr>
    80002b9e:	00054e63          	bltz	a0,80002bba <fetchstr+0x48>
  return strlen(buf);
    80002ba2:	8526                	mv	a0,s1
    80002ba4:	ffffe097          	auipc	ra,0xffffe
    80002ba8:	2c6080e7          	jalr	710(ra) # 80000e6a <strlen>
}
    80002bac:	70a2                	ld	ra,40(sp)
    80002bae:	7402                	ld	s0,32(sp)
    80002bb0:	64e2                	ld	s1,24(sp)
    80002bb2:	6942                	ld	s2,16(sp)
    80002bb4:	69a2                	ld	s3,8(sp)
    80002bb6:	6145                	addi	sp,sp,48
    80002bb8:	8082                	ret
    return -1;
    80002bba:	557d                	li	a0,-1
    80002bbc:	bfc5                	j	80002bac <fetchstr+0x3a>

0000000080002bbe <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002bbe:	1101                	addi	sp,sp,-32
    80002bc0:	ec06                	sd	ra,24(sp)
    80002bc2:	e822                	sd	s0,16(sp)
    80002bc4:	e426                	sd	s1,8(sp)
    80002bc6:	1000                	addi	s0,sp,32
    80002bc8:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bca:	00000097          	auipc	ra,0x0
    80002bce:	eee080e7          	jalr	-274(ra) # 80002ab8 <argraw>
    80002bd2:	c088                	sw	a0,0(s1)
}
    80002bd4:	60e2                	ld	ra,24(sp)
    80002bd6:	6442                	ld	s0,16(sp)
    80002bd8:	64a2                	ld	s1,8(sp)
    80002bda:	6105                	addi	sp,sp,32
    80002bdc:	8082                	ret

0000000080002bde <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002bde:	1101                	addi	sp,sp,-32
    80002be0:	ec06                	sd	ra,24(sp)
    80002be2:	e822                	sd	s0,16(sp)
    80002be4:	e426                	sd	s1,8(sp)
    80002be6:	1000                	addi	s0,sp,32
    80002be8:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bea:	00000097          	auipc	ra,0x0
    80002bee:	ece080e7          	jalr	-306(ra) # 80002ab8 <argraw>
    80002bf2:	e088                	sd	a0,0(s1)
}
    80002bf4:	60e2                	ld	ra,24(sp)
    80002bf6:	6442                	ld	s0,16(sp)
    80002bf8:	64a2                	ld	s1,8(sp)
    80002bfa:	6105                	addi	sp,sp,32
    80002bfc:	8082                	ret

0000000080002bfe <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002bfe:	7179                	addi	sp,sp,-48
    80002c00:	f406                	sd	ra,40(sp)
    80002c02:	f022                	sd	s0,32(sp)
    80002c04:	ec26                	sd	s1,24(sp)
    80002c06:	e84a                	sd	s2,16(sp)
    80002c08:	1800                	addi	s0,sp,48
    80002c0a:	84ae                	mv	s1,a1
    80002c0c:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002c0e:	fd840593          	addi	a1,s0,-40
    80002c12:	00000097          	auipc	ra,0x0
    80002c16:	fcc080e7          	jalr	-52(ra) # 80002bde <argaddr>
  return fetchstr(addr, buf, max);
    80002c1a:	864a                	mv	a2,s2
    80002c1c:	85a6                	mv	a1,s1
    80002c1e:	fd843503          	ld	a0,-40(s0)
    80002c22:	00000097          	auipc	ra,0x0
    80002c26:	f50080e7          	jalr	-176(ra) # 80002b72 <fetchstr>
}
    80002c2a:	70a2                	ld	ra,40(sp)
    80002c2c:	7402                	ld	s0,32(sp)
    80002c2e:	64e2                	ld	s1,24(sp)
    80002c30:	6942                	ld	s2,16(sp)
    80002c32:	6145                	addi	sp,sp,48
    80002c34:	8082                	ret

0000000080002c36 <syscall>:
};


void
syscall(void)
{
    80002c36:	711d                	addi	sp,sp,-96
    80002c38:	ec86                	sd	ra,88(sp)
    80002c3a:	e8a2                	sd	s0,80(sp)
    80002c3c:	e4a6                	sd	s1,72(sp)
    80002c3e:	e0ca                	sd	s2,64(sp)
    80002c40:	fc4e                	sd	s3,56(sp)
    80002c42:	f852                	sd	s4,48(sp)
    80002c44:	f456                	sd	s5,40(sp)
    80002c46:	f05a                	sd	s6,32(sp)
    80002c48:	ec5e                	sd	s7,24(sp)
    80002c4a:	e862                	sd	s8,16(sp)
    80002c4c:	e466                	sd	s9,8(sp)
    80002c4e:	1080                	addi	s0,sp,96
  int num;
  struct proc *p = myproc();
    80002c50:	fffff097          	auipc	ra,0xfffff
    80002c54:	d76080e7          	jalr	-650(ra) # 800019c6 <myproc>
    80002c58:	89aa                	mv	s3,a0

  num = p->trapframe->a7;
    80002c5a:	6d24                	ld	s1,88(a0)
    80002c5c:	74dc                	ld	a5,168(s1)
    80002c5e:	00078a1b          	sext.w	s4,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c62:	37fd                	addiw	a5,a5,-1
    80002c64:	4759                	li	a4,22
    80002c66:	12f76163          	bltu	a4,a5,80002d88 <syscall+0x152>
    80002c6a:	003a1713          	slli	a4,s4,0x3
    80002c6e:	00006797          	auipc	a5,0x6
    80002c72:	98a78793          	addi	a5,a5,-1654 # 800085f8 <syscalls>
    80002c76:	97ba                	add	a5,a5,a4
    80002c78:	639c                	ld	a5,0(a5)
    80002c7a:	10078763          	beqz	a5,80002d88 <syscall+0x152>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0

    p->trapframe->a0 = syscalls[num]();
    80002c7e:	9782                	jalr	a5
    80002c80:	f8a8                	sd	a0,112(s1)
    // if our system call was AUDIT, we specifically need to take what's in a0
    // out right here. this contains the whitelist array for what calls to audit
    if (num == 22) {
    80002c82:	47d9                	li	a5,22
    80002c84:	04fa0463          	beq	s4,a5,80002ccc <syscall+0x96>
      }
      declared_length = *(bruh->length);
      //printf("process %s with id %d called audit at time %d\n", p->name, p->pid, ticks);
      printf("declared length: %d\n", declared_length);
    }
    if (!declared_length) {
    80002c88:	00006797          	auipc	a5,0x6
    80002c8c:	f6c7a783          	lw	a5,-148(a5) # 80008bf4 <declared_length>
    80002c90:	cfc9                	beqz	a5,80002d2a <syscall+0xf4>
      // nothing is whitelisted.
      printf("process %s with id %d called %s at time %d\n", p->name, p->pid, name_from_num[num], ticks);
    } else {
      // something is whitelisted.
      for (int i = 0; i < declared_length; i++) {
    80002c92:	00014497          	auipc	s1,0x14
    80002c96:	22648493          	addi	s1,s1,550 # 80016eb8 <whitelisted>
    80002c9a:	4901                	li	s2,0
    80002c9c:	10f05763          	blez	a5,80002daa <syscall+0x174>
        // if it's whitelisted, we care. otherwise, just let it time out.
        if (num == whitelisted[i]) {
          printf("process %s with id %d called %s at time %d\n", p->name, p->pid, name_from_num[num], ticks);
    80002ca0:	00006b97          	auipc	s7,0x6
    80002ca4:	f50b8b93          	addi	s7,s7,-176 # 80008bf0 <ticks>
    80002ca8:	003a1b13          	slli	s6,s4,0x3
    80002cac:	00006797          	auipc	a5,0x6
    80002cb0:	e1c78793          	addi	a5,a5,-484 # 80008ac8 <name_from_num>
    80002cb4:	9b3e                	add	s6,s6,a5
    80002cb6:	15898c93          	addi	s9,s3,344
    80002cba:	00006c17          	auipc	s8,0x6
    80002cbe:	826c0c13          	addi	s8,s8,-2010 # 800084e0 <states.1782+0x178>
      for (int i = 0; i < declared_length; i++) {
    80002cc2:	00006a97          	auipc	s5,0x6
    80002cc6:	f32a8a93          	addi	s5,s5,-206 # 80008bf4 <declared_length>
    80002cca:	a85d                	j	80002d80 <syscall+0x14a>
      struct aud* bruh = (struct aud*)p->trapframe->a0;
    80002ccc:	0589b783          	ld	a5,88(s3)
    80002cd0:	7ba4                	ld	s1,112(a5)
      printf("edit in kernel\n");
    80002cd2:	00005517          	auipc	a0,0x5
    80002cd6:	7e650513          	addi	a0,a0,2022 # 800084b8 <states.1782+0x150>
    80002cda:	ffffe097          	auipc	ra,0xffffe
    80002cde:	8b4080e7          	jalr	-1868(ra) # 8000058e <printf>
      for (int i = 0; i < *(bruh->length); i++) {
    80002ce2:	649c                	ld	a5,8(s1)
    80002ce4:	438c                	lw	a1,0(a5)
    80002ce6:	02b05563          	blez	a1,80002d10 <syscall+0xda>
    80002cea:	00014697          	auipc	a3,0x14
    80002cee:	1ce68693          	addi	a3,a3,462 # 80016eb8 <whitelisted>
    80002cf2:	4781                	li	a5,0
        whitelisted[i] = *(bruh->arr + i);
    80002cf4:	6098                	ld	a4,0(s1)
    80002cf6:	00279613          	slli	a2,a5,0x2
    80002cfa:	9732                	add	a4,a4,a2
    80002cfc:	4318                	lw	a4,0(a4)
    80002cfe:	c298                	sw	a4,0(a3)
      for (int i = 0; i < *(bruh->length); i++) {
    80002d00:	6498                	ld	a4,8(s1)
    80002d02:	430c                	lw	a1,0(a4)
    80002d04:	0785                	addi	a5,a5,1
    80002d06:	0691                	addi	a3,a3,4
    80002d08:	0007871b          	sext.w	a4,a5
    80002d0c:	feb744e3          	blt	a4,a1,80002cf4 <syscall+0xbe>
      declared_length = *(bruh->length);
    80002d10:	00006797          	auipc	a5,0x6
    80002d14:	eeb7a223          	sw	a1,-284(a5) # 80008bf4 <declared_length>
      printf("declared length: %d\n", declared_length);
    80002d18:	00005517          	auipc	a0,0x5
    80002d1c:	7b050513          	addi	a0,a0,1968 # 800084c8 <states.1782+0x160>
    80002d20:	ffffe097          	auipc	ra,0xffffe
    80002d24:	86e080e7          	jalr	-1938(ra) # 8000058e <printf>
    80002d28:	b785                	j	80002c88 <syscall+0x52>
      printf("process %s with id %d called %s at time %d\n", p->name, p->pid, name_from_num[num], ticks);
    80002d2a:	0a0e                	slli	s4,s4,0x3
    80002d2c:	00006797          	auipc	a5,0x6
    80002d30:	d9c78793          	addi	a5,a5,-612 # 80008ac8 <name_from_num>
    80002d34:	9a3e                	add	s4,s4,a5
    80002d36:	00006717          	auipc	a4,0x6
    80002d3a:	eba72703          	lw	a4,-326(a4) # 80008bf0 <ticks>
    80002d3e:	000a3683          	ld	a3,0(s4)
    80002d42:	0309a603          	lw	a2,48(s3)
    80002d46:	15898593          	addi	a1,s3,344
    80002d4a:	00005517          	auipc	a0,0x5
    80002d4e:	79650513          	addi	a0,a0,1942 # 800084e0 <states.1782+0x178>
    80002d52:	ffffe097          	auipc	ra,0xffffe
    80002d56:	83c080e7          	jalr	-1988(ra) # 8000058e <printf>
    80002d5a:	a881                	j	80002daa <syscall+0x174>
          printf("process %s with id %d called %s at time %d\n", p->name, p->pid, name_from_num[num], ticks);
    80002d5c:	000ba703          	lw	a4,0(s7)
    80002d60:	000b3683          	ld	a3,0(s6)
    80002d64:	0309a603          	lw	a2,48(s3)
    80002d68:	85e6                	mv	a1,s9
    80002d6a:	8562                	mv	a0,s8
    80002d6c:	ffffe097          	auipc	ra,0xffffe
    80002d70:	822080e7          	jalr	-2014(ra) # 8000058e <printf>
      for (int i = 0; i < declared_length; i++) {
    80002d74:	2905                	addiw	s2,s2,1
    80002d76:	0491                	addi	s1,s1,4
    80002d78:	000aa783          	lw	a5,0(s5)
    80002d7c:	02f95763          	bge	s2,a5,80002daa <syscall+0x174>
        if (num == whitelisted[i]) {
    80002d80:	409c                	lw	a5,0(s1)
    80002d82:	ff4799e3          	bne	a5,s4,80002d74 <syscall+0x13e>
    80002d86:	bfd9                	j	80002d5c <syscall+0x126>
        }
      }
    }

  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d88:	86d2                	mv	a3,s4
    80002d8a:	15898613          	addi	a2,s3,344
    80002d8e:	0309a583          	lw	a1,48(s3)
    80002d92:	00005517          	auipc	a0,0x5
    80002d96:	77e50513          	addi	a0,a0,1918 # 80008510 <states.1782+0x1a8>
    80002d9a:	ffffd097          	auipc	ra,0xffffd
    80002d9e:	7f4080e7          	jalr	2036(ra) # 8000058e <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002da2:	0589b783          	ld	a5,88(s3)
    80002da6:	577d                	li	a4,-1
    80002da8:	fbb8                	sd	a4,112(a5)
  }

}
    80002daa:	60e6                	ld	ra,88(sp)
    80002dac:	6446                	ld	s0,80(sp)
    80002dae:	64a6                	ld	s1,72(sp)
    80002db0:	6906                	ld	s2,64(sp)
    80002db2:	79e2                	ld	s3,56(sp)
    80002db4:	7a42                	ld	s4,48(sp)
    80002db6:	7aa2                	ld	s5,40(sp)
    80002db8:	7b02                	ld	s6,32(sp)
    80002dba:	6be2                	ld	s7,24(sp)
    80002dbc:	6c42                	ld	s8,16(sp)
    80002dbe:	6ca2                	ld	s9,8(sp)
    80002dc0:	6125                	addi	sp,sp,96
    80002dc2:	8082                	ret

0000000080002dc4 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002dc4:	1101                	addi	sp,sp,-32
    80002dc6:	ec06                	sd	ra,24(sp)
    80002dc8:	e822                	sd	s0,16(sp)
    80002dca:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002dcc:	fec40593          	addi	a1,s0,-20
    80002dd0:	4501                	li	a0,0
    80002dd2:	00000097          	auipc	ra,0x0
    80002dd6:	dec080e7          	jalr	-532(ra) # 80002bbe <argint>
  exit(n);
    80002dda:	fec42503          	lw	a0,-20(s0)
    80002dde:	fffff097          	auipc	ra,0xfffff
    80002de2:	460080e7          	jalr	1120(ra) # 8000223e <exit>
  return 0;  // not reached
}
    80002de6:	4501                	li	a0,0
    80002de8:	60e2                	ld	ra,24(sp)
    80002dea:	6442                	ld	s0,16(sp)
    80002dec:	6105                	addi	sp,sp,32
    80002dee:	8082                	ret

0000000080002df0 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002df0:	1141                	addi	sp,sp,-16
    80002df2:	e406                	sd	ra,8(sp)
    80002df4:	e022                	sd	s0,0(sp)
    80002df6:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002df8:	fffff097          	auipc	ra,0xfffff
    80002dfc:	bce080e7          	jalr	-1074(ra) # 800019c6 <myproc>
}
    80002e00:	5908                	lw	a0,48(a0)
    80002e02:	60a2                	ld	ra,8(sp)
    80002e04:	6402                	ld	s0,0(sp)
    80002e06:	0141                	addi	sp,sp,16
    80002e08:	8082                	ret

0000000080002e0a <sys_fork>:

uint64
sys_fork(void)
{
    80002e0a:	1141                	addi	sp,sp,-16
    80002e0c:	e406                	sd	ra,8(sp)
    80002e0e:	e022                	sd	s0,0(sp)
    80002e10:	0800                	addi	s0,sp,16
  return fork();
    80002e12:	fffff097          	auipc	ra,0xfffff
    80002e16:	f6a080e7          	jalr	-150(ra) # 80001d7c <fork>
}
    80002e1a:	60a2                	ld	ra,8(sp)
    80002e1c:	6402                	ld	s0,0(sp)
    80002e1e:	0141                	addi	sp,sp,16
    80002e20:	8082                	ret

0000000080002e22 <sys_wait>:

uint64
sys_wait(void)
{
    80002e22:	1101                	addi	sp,sp,-32
    80002e24:	ec06                	sd	ra,24(sp)
    80002e26:	e822                	sd	s0,16(sp)
    80002e28:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002e2a:	fe840593          	addi	a1,s0,-24
    80002e2e:	4501                	li	a0,0
    80002e30:	00000097          	auipc	ra,0x0
    80002e34:	dae080e7          	jalr	-594(ra) # 80002bde <argaddr>
  return wait(p);
    80002e38:	fe843503          	ld	a0,-24(s0)
    80002e3c:	fffff097          	auipc	ra,0xfffff
    80002e40:	5a8080e7          	jalr	1448(ra) # 800023e4 <wait>
}
    80002e44:	60e2                	ld	ra,24(sp)
    80002e46:	6442                	ld	s0,16(sp)
    80002e48:	6105                	addi	sp,sp,32
    80002e4a:	8082                	ret

0000000080002e4c <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e4c:	7179                	addi	sp,sp,-48
    80002e4e:	f406                	sd	ra,40(sp)
    80002e50:	f022                	sd	s0,32(sp)
    80002e52:	ec26                	sd	s1,24(sp)
    80002e54:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002e56:	fdc40593          	addi	a1,s0,-36
    80002e5a:	4501                	li	a0,0
    80002e5c:	00000097          	auipc	ra,0x0
    80002e60:	d62080e7          	jalr	-670(ra) # 80002bbe <argint>
  addr = myproc()->sz;
    80002e64:	fffff097          	auipc	ra,0xfffff
    80002e68:	b62080e7          	jalr	-1182(ra) # 800019c6 <myproc>
    80002e6c:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002e6e:	fdc42503          	lw	a0,-36(s0)
    80002e72:	fffff097          	auipc	ra,0xfffff
    80002e76:	eae080e7          	jalr	-338(ra) # 80001d20 <growproc>
    80002e7a:	00054863          	bltz	a0,80002e8a <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002e7e:	8526                	mv	a0,s1
    80002e80:	70a2                	ld	ra,40(sp)
    80002e82:	7402                	ld	s0,32(sp)
    80002e84:	64e2                	ld	s1,24(sp)
    80002e86:	6145                	addi	sp,sp,48
    80002e88:	8082                	ret
    return -1;
    80002e8a:	54fd                	li	s1,-1
    80002e8c:	bfcd                	j	80002e7e <sys_sbrk+0x32>

0000000080002e8e <sys_sleep>:

uint64
sys_sleep(void)
{
    80002e8e:	7139                	addi	sp,sp,-64
    80002e90:	fc06                	sd	ra,56(sp)
    80002e92:	f822                	sd	s0,48(sp)
    80002e94:	f426                	sd	s1,40(sp)
    80002e96:	f04a                	sd	s2,32(sp)
    80002e98:	ec4e                	sd	s3,24(sp)
    80002e9a:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002e9c:	fcc40593          	addi	a1,s0,-52
    80002ea0:	4501                	li	a0,0
    80002ea2:	00000097          	auipc	ra,0x0
    80002ea6:	d1c080e7          	jalr	-740(ra) # 80002bbe <argint>
  acquire(&tickslock);
    80002eaa:	00014517          	auipc	a0,0x14
    80002eae:	ff650513          	addi	a0,a0,-10 # 80016ea0 <tickslock>
    80002eb2:	ffffe097          	auipc	ra,0xffffe
    80002eb6:	d38080e7          	jalr	-712(ra) # 80000bea <acquire>
  ticks0 = ticks;
    80002eba:	00006917          	auipc	s2,0x6
    80002ebe:	d3692903          	lw	s2,-714(s2) # 80008bf0 <ticks>
  while(ticks - ticks0 < n){
    80002ec2:	fcc42783          	lw	a5,-52(s0)
    80002ec6:	cf9d                	beqz	a5,80002f04 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002ec8:	00014997          	auipc	s3,0x14
    80002ecc:	fd898993          	addi	s3,s3,-40 # 80016ea0 <tickslock>
    80002ed0:	00006497          	auipc	s1,0x6
    80002ed4:	d2048493          	addi	s1,s1,-736 # 80008bf0 <ticks>
    if(killed(myproc())){
    80002ed8:	fffff097          	auipc	ra,0xfffff
    80002edc:	aee080e7          	jalr	-1298(ra) # 800019c6 <myproc>
    80002ee0:	fffff097          	auipc	ra,0xfffff
    80002ee4:	4d2080e7          	jalr	1234(ra) # 800023b2 <killed>
    80002ee8:	ed15                	bnez	a0,80002f24 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002eea:	85ce                	mv	a1,s3
    80002eec:	8526                	mv	a0,s1
    80002eee:	fffff097          	auipc	ra,0xfffff
    80002ef2:	21c080e7          	jalr	540(ra) # 8000210a <sleep>
  while(ticks - ticks0 < n){
    80002ef6:	409c                	lw	a5,0(s1)
    80002ef8:	412787bb          	subw	a5,a5,s2
    80002efc:	fcc42703          	lw	a4,-52(s0)
    80002f00:	fce7ece3          	bltu	a5,a4,80002ed8 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002f04:	00014517          	auipc	a0,0x14
    80002f08:	f9c50513          	addi	a0,a0,-100 # 80016ea0 <tickslock>
    80002f0c:	ffffe097          	auipc	ra,0xffffe
    80002f10:	d92080e7          	jalr	-622(ra) # 80000c9e <release>
  return 0;
    80002f14:	4501                	li	a0,0
}
    80002f16:	70e2                	ld	ra,56(sp)
    80002f18:	7442                	ld	s0,48(sp)
    80002f1a:	74a2                	ld	s1,40(sp)
    80002f1c:	7902                	ld	s2,32(sp)
    80002f1e:	69e2                	ld	s3,24(sp)
    80002f20:	6121                	addi	sp,sp,64
    80002f22:	8082                	ret
      release(&tickslock);
    80002f24:	00014517          	auipc	a0,0x14
    80002f28:	f7c50513          	addi	a0,a0,-132 # 80016ea0 <tickslock>
    80002f2c:	ffffe097          	auipc	ra,0xffffe
    80002f30:	d72080e7          	jalr	-654(ra) # 80000c9e <release>
      return -1;
    80002f34:	557d                	li	a0,-1
    80002f36:	b7c5                	j	80002f16 <sys_sleep+0x88>

0000000080002f38 <sys_kill>:

uint64
sys_kill(void)
{
    80002f38:	1101                	addi	sp,sp,-32
    80002f3a:	ec06                	sd	ra,24(sp)
    80002f3c:	e822                	sd	s0,16(sp)
    80002f3e:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002f40:	fec40593          	addi	a1,s0,-20
    80002f44:	4501                	li	a0,0
    80002f46:	00000097          	auipc	ra,0x0
    80002f4a:	c78080e7          	jalr	-904(ra) # 80002bbe <argint>
  return kill(pid);
    80002f4e:	fec42503          	lw	a0,-20(s0)
    80002f52:	fffff097          	auipc	ra,0xfffff
    80002f56:	3c2080e7          	jalr	962(ra) # 80002314 <kill>
}
    80002f5a:	60e2                	ld	ra,24(sp)
    80002f5c:	6442                	ld	s0,16(sp)
    80002f5e:	6105                	addi	sp,sp,32
    80002f60:	8082                	ret

0000000080002f62 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002f62:	1101                	addi	sp,sp,-32
    80002f64:	ec06                	sd	ra,24(sp)
    80002f66:	e822                	sd	s0,16(sp)
    80002f68:	e426                	sd	s1,8(sp)
    80002f6a:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002f6c:	00014517          	auipc	a0,0x14
    80002f70:	f3450513          	addi	a0,a0,-204 # 80016ea0 <tickslock>
    80002f74:	ffffe097          	auipc	ra,0xffffe
    80002f78:	c76080e7          	jalr	-906(ra) # 80000bea <acquire>
  xticks = ticks;
    80002f7c:	00006497          	auipc	s1,0x6
    80002f80:	c744a483          	lw	s1,-908(s1) # 80008bf0 <ticks>
  release(&tickslock);
    80002f84:	00014517          	auipc	a0,0x14
    80002f88:	f1c50513          	addi	a0,a0,-228 # 80016ea0 <tickslock>
    80002f8c:	ffffe097          	auipc	ra,0xffffe
    80002f90:	d12080e7          	jalr	-750(ra) # 80000c9e <release>
  return xticks;
}
    80002f94:	02049513          	slli	a0,s1,0x20
    80002f98:	9101                	srli	a0,a0,0x20
    80002f9a:	60e2                	ld	ra,24(sp)
    80002f9c:	6442                	ld	s0,16(sp)
    80002f9e:	64a2                	ld	s1,8(sp)
    80002fa0:	6105                	addi	sp,sp,32
    80002fa2:	8082                	ret

0000000080002fa4 <sys_audit>:

uint64
sys_audit(void)
{
    80002fa4:	1101                	addi	sp,sp,-32
    80002fa6:	ec06                	sd	ra,24(sp)
    80002fa8:	e822                	sd	s0,16(sp)
    80002faa:	1000                	addi	s0,sp,32
  printf("in sys audit\n");
    80002fac:	00005517          	auipc	a0,0x5
    80002fb0:	70c50513          	addi	a0,a0,1804 # 800086b8 <syscalls+0xc0>
    80002fb4:	ffffd097          	auipc	ra,0xffffd
    80002fb8:	5da080e7          	jalr	1498(ra) # 8000058e <printf>
  uint64 arr_addr;
  uint64 length;
  argaddr(0, &arr_addr);
    80002fbc:	fe840593          	addi	a1,s0,-24
    80002fc0:	4501                	li	a0,0
    80002fc2:	00000097          	auipc	ra,0x0
    80002fc6:	c1c080e7          	jalr	-996(ra) # 80002bde <argaddr>
  argaddr(1, &length);
    80002fca:	fe040593          	addi	a1,s0,-32
    80002fce:	4505                	li	a0,1
    80002fd0:	00000097          	auipc	ra,0x0
    80002fd4:	c0e080e7          	jalr	-1010(ra) # 80002bde <argaddr>
  printf("address of length: %p\n", (int*) length);
    80002fd8:	fe043583          	ld	a1,-32(s0)
    80002fdc:	00005517          	auipc	a0,0x5
    80002fe0:	6ec50513          	addi	a0,a0,1772 # 800086c8 <syscalls+0xd0>
    80002fe4:	ffffd097          	auipc	ra,0xffffd
    80002fe8:	5aa080e7          	jalr	1450(ra) # 8000058e <printf>
  return audit((int*) arr_addr, (int*) length);
    80002fec:	fe043583          	ld	a1,-32(s0)
    80002ff0:	fe843503          	ld	a0,-24(s0)
    80002ff4:	fffff097          	auipc	ra,0xfffff
    80002ff8:	ec4080e7          	jalr	-316(ra) # 80001eb8 <audit>
}
    80002ffc:	60e2                	ld	ra,24(sp)
    80002ffe:	6442                	ld	s0,16(sp)
    80003000:	6105                	addi	sp,sp,32
    80003002:	8082                	ret

0000000080003004 <sys_logs>:

uint64           
sys_logs(void)
{
    80003004:	1101                	addi	sp,sp,-32
    80003006:	ec06                	sd	ra,24(sp)
    80003008:	e822                	sd	s0,16(sp)
    8000300a:	1000                	addi	s0,sp,32
    printf("Working\n");
    8000300c:	00005517          	auipc	a0,0x5
    80003010:	6d450513          	addi	a0,a0,1748 # 800086e0 <syscalls+0xe8>
    80003014:	ffffd097          	auipc	ra,0xffffd
    80003018:	57a080e7          	jalr	1402(ra) # 8000058e <printf>
    uint64 addr;
    argaddr(0, &addr);
    8000301c:	fe840593          	addi	a1,s0,-24
    80003020:	4501                	li	a0,0
    80003022:	00000097          	auipc	ra,0x0
    80003026:	bbc080e7          	jalr	-1092(ra) # 80002bde <argaddr>
    return logs((void *) addr);
    8000302a:	fe843503          	ld	a0,-24(s0)
    8000302e:	fffff097          	auipc	ra,0xfffff
    80003032:	63e080e7          	jalr	1598(ra) # 8000266c <logs>
}
    80003036:	60e2                	ld	ra,24(sp)
    80003038:	6442                	ld	s0,16(sp)
    8000303a:	6105                	addi	sp,sp,32
    8000303c:	8082                	ret

000000008000303e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000303e:	7179                	addi	sp,sp,-48
    80003040:	f406                	sd	ra,40(sp)
    80003042:	f022                	sd	s0,32(sp)
    80003044:	ec26                	sd	s1,24(sp)
    80003046:	e84a                	sd	s2,16(sp)
    80003048:	e44e                	sd	s3,8(sp)
    8000304a:	e052                	sd	s4,0(sp)
    8000304c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000304e:	00005597          	auipc	a1,0x5
    80003052:	6a258593          	addi	a1,a1,1698 # 800086f0 <syscalls+0xf8>
    80003056:	0001c517          	auipc	a0,0x1c
    8000305a:	eca50513          	addi	a0,a0,-310 # 8001ef20 <bcache>
    8000305e:	ffffe097          	auipc	ra,0xffffe
    80003062:	afc080e7          	jalr	-1284(ra) # 80000b5a <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003066:	00024797          	auipc	a5,0x24
    8000306a:	eba78793          	addi	a5,a5,-326 # 80026f20 <bcache+0x8000>
    8000306e:	00024717          	auipc	a4,0x24
    80003072:	11a70713          	addi	a4,a4,282 # 80027188 <bcache+0x8268>
    80003076:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000307a:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000307e:	0001c497          	auipc	s1,0x1c
    80003082:	eba48493          	addi	s1,s1,-326 # 8001ef38 <bcache+0x18>
    b->next = bcache.head.next;
    80003086:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003088:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000308a:	00005a17          	auipc	s4,0x5
    8000308e:	66ea0a13          	addi	s4,s4,1646 # 800086f8 <syscalls+0x100>
    b->next = bcache.head.next;
    80003092:	2b893783          	ld	a5,696(s2)
    80003096:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003098:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000309c:	85d2                	mv	a1,s4
    8000309e:	01048513          	addi	a0,s1,16
    800030a2:	00001097          	auipc	ra,0x1
    800030a6:	4c4080e7          	jalr	1220(ra) # 80004566 <initsleeplock>
    bcache.head.next->prev = b;
    800030aa:	2b893783          	ld	a5,696(s2)
    800030ae:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800030b0:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800030b4:	45848493          	addi	s1,s1,1112
    800030b8:	fd349de3          	bne	s1,s3,80003092 <binit+0x54>
  }
}
    800030bc:	70a2                	ld	ra,40(sp)
    800030be:	7402                	ld	s0,32(sp)
    800030c0:	64e2                	ld	s1,24(sp)
    800030c2:	6942                	ld	s2,16(sp)
    800030c4:	69a2                	ld	s3,8(sp)
    800030c6:	6a02                	ld	s4,0(sp)
    800030c8:	6145                	addi	sp,sp,48
    800030ca:	8082                	ret

00000000800030cc <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800030cc:	7179                	addi	sp,sp,-48
    800030ce:	f406                	sd	ra,40(sp)
    800030d0:	f022                	sd	s0,32(sp)
    800030d2:	ec26                	sd	s1,24(sp)
    800030d4:	e84a                	sd	s2,16(sp)
    800030d6:	e44e                	sd	s3,8(sp)
    800030d8:	1800                	addi	s0,sp,48
    800030da:	89aa                	mv	s3,a0
    800030dc:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800030de:	0001c517          	auipc	a0,0x1c
    800030e2:	e4250513          	addi	a0,a0,-446 # 8001ef20 <bcache>
    800030e6:	ffffe097          	auipc	ra,0xffffe
    800030ea:	b04080e7          	jalr	-1276(ra) # 80000bea <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800030ee:	00024497          	auipc	s1,0x24
    800030f2:	0ea4b483          	ld	s1,234(s1) # 800271d8 <bcache+0x82b8>
    800030f6:	00024797          	auipc	a5,0x24
    800030fa:	09278793          	addi	a5,a5,146 # 80027188 <bcache+0x8268>
    800030fe:	02f48f63          	beq	s1,a5,8000313c <bread+0x70>
    80003102:	873e                	mv	a4,a5
    80003104:	a021                	j	8000310c <bread+0x40>
    80003106:	68a4                	ld	s1,80(s1)
    80003108:	02e48a63          	beq	s1,a4,8000313c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000310c:	449c                	lw	a5,8(s1)
    8000310e:	ff379ce3          	bne	a5,s3,80003106 <bread+0x3a>
    80003112:	44dc                	lw	a5,12(s1)
    80003114:	ff2799e3          	bne	a5,s2,80003106 <bread+0x3a>
      b->refcnt++;
    80003118:	40bc                	lw	a5,64(s1)
    8000311a:	2785                	addiw	a5,a5,1
    8000311c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000311e:	0001c517          	auipc	a0,0x1c
    80003122:	e0250513          	addi	a0,a0,-510 # 8001ef20 <bcache>
    80003126:	ffffe097          	auipc	ra,0xffffe
    8000312a:	b78080e7          	jalr	-1160(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    8000312e:	01048513          	addi	a0,s1,16
    80003132:	00001097          	auipc	ra,0x1
    80003136:	46e080e7          	jalr	1134(ra) # 800045a0 <acquiresleep>
      return b;
    8000313a:	a8b9                	j	80003198 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000313c:	00024497          	auipc	s1,0x24
    80003140:	0944b483          	ld	s1,148(s1) # 800271d0 <bcache+0x82b0>
    80003144:	00024797          	auipc	a5,0x24
    80003148:	04478793          	addi	a5,a5,68 # 80027188 <bcache+0x8268>
    8000314c:	00f48863          	beq	s1,a5,8000315c <bread+0x90>
    80003150:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003152:	40bc                	lw	a5,64(s1)
    80003154:	cf81                	beqz	a5,8000316c <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003156:	64a4                	ld	s1,72(s1)
    80003158:	fee49de3          	bne	s1,a4,80003152 <bread+0x86>
  panic("bget: no buffers");
    8000315c:	00005517          	auipc	a0,0x5
    80003160:	5a450513          	addi	a0,a0,1444 # 80008700 <syscalls+0x108>
    80003164:	ffffd097          	auipc	ra,0xffffd
    80003168:	3e0080e7          	jalr	992(ra) # 80000544 <panic>
      b->dev = dev;
    8000316c:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003170:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003174:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003178:	4785                	li	a5,1
    8000317a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000317c:	0001c517          	auipc	a0,0x1c
    80003180:	da450513          	addi	a0,a0,-604 # 8001ef20 <bcache>
    80003184:	ffffe097          	auipc	ra,0xffffe
    80003188:	b1a080e7          	jalr	-1254(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    8000318c:	01048513          	addi	a0,s1,16
    80003190:	00001097          	auipc	ra,0x1
    80003194:	410080e7          	jalr	1040(ra) # 800045a0 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003198:	409c                	lw	a5,0(s1)
    8000319a:	cb89                	beqz	a5,800031ac <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000319c:	8526                	mv	a0,s1
    8000319e:	70a2                	ld	ra,40(sp)
    800031a0:	7402                	ld	s0,32(sp)
    800031a2:	64e2                	ld	s1,24(sp)
    800031a4:	6942                	ld	s2,16(sp)
    800031a6:	69a2                	ld	s3,8(sp)
    800031a8:	6145                	addi	sp,sp,48
    800031aa:	8082                	ret
    virtio_disk_rw(b, 0);
    800031ac:	4581                	li	a1,0
    800031ae:	8526                	mv	a0,s1
    800031b0:	00003097          	auipc	ra,0x3
    800031b4:	fc8080e7          	jalr	-56(ra) # 80006178 <virtio_disk_rw>
    b->valid = 1;
    800031b8:	4785                	li	a5,1
    800031ba:	c09c                	sw	a5,0(s1)
  return b;
    800031bc:	b7c5                	j	8000319c <bread+0xd0>

00000000800031be <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800031be:	1101                	addi	sp,sp,-32
    800031c0:	ec06                	sd	ra,24(sp)
    800031c2:	e822                	sd	s0,16(sp)
    800031c4:	e426                	sd	s1,8(sp)
    800031c6:	1000                	addi	s0,sp,32
    800031c8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031ca:	0541                	addi	a0,a0,16
    800031cc:	00001097          	auipc	ra,0x1
    800031d0:	46e080e7          	jalr	1134(ra) # 8000463a <holdingsleep>
    800031d4:	cd01                	beqz	a0,800031ec <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800031d6:	4585                	li	a1,1
    800031d8:	8526                	mv	a0,s1
    800031da:	00003097          	auipc	ra,0x3
    800031de:	f9e080e7          	jalr	-98(ra) # 80006178 <virtio_disk_rw>
}
    800031e2:	60e2                	ld	ra,24(sp)
    800031e4:	6442                	ld	s0,16(sp)
    800031e6:	64a2                	ld	s1,8(sp)
    800031e8:	6105                	addi	sp,sp,32
    800031ea:	8082                	ret
    panic("bwrite");
    800031ec:	00005517          	auipc	a0,0x5
    800031f0:	52c50513          	addi	a0,a0,1324 # 80008718 <syscalls+0x120>
    800031f4:	ffffd097          	auipc	ra,0xffffd
    800031f8:	350080e7          	jalr	848(ra) # 80000544 <panic>

00000000800031fc <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800031fc:	1101                	addi	sp,sp,-32
    800031fe:	ec06                	sd	ra,24(sp)
    80003200:	e822                	sd	s0,16(sp)
    80003202:	e426                	sd	s1,8(sp)
    80003204:	e04a                	sd	s2,0(sp)
    80003206:	1000                	addi	s0,sp,32
    80003208:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000320a:	01050913          	addi	s2,a0,16
    8000320e:	854a                	mv	a0,s2
    80003210:	00001097          	auipc	ra,0x1
    80003214:	42a080e7          	jalr	1066(ra) # 8000463a <holdingsleep>
    80003218:	c92d                	beqz	a0,8000328a <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000321a:	854a                	mv	a0,s2
    8000321c:	00001097          	auipc	ra,0x1
    80003220:	3da080e7          	jalr	986(ra) # 800045f6 <releasesleep>

  acquire(&bcache.lock);
    80003224:	0001c517          	auipc	a0,0x1c
    80003228:	cfc50513          	addi	a0,a0,-772 # 8001ef20 <bcache>
    8000322c:	ffffe097          	auipc	ra,0xffffe
    80003230:	9be080e7          	jalr	-1602(ra) # 80000bea <acquire>
  b->refcnt--;
    80003234:	40bc                	lw	a5,64(s1)
    80003236:	37fd                	addiw	a5,a5,-1
    80003238:	0007871b          	sext.w	a4,a5
    8000323c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000323e:	eb05                	bnez	a4,8000326e <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003240:	68bc                	ld	a5,80(s1)
    80003242:	64b8                	ld	a4,72(s1)
    80003244:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003246:	64bc                	ld	a5,72(s1)
    80003248:	68b8                	ld	a4,80(s1)
    8000324a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000324c:	00024797          	auipc	a5,0x24
    80003250:	cd478793          	addi	a5,a5,-812 # 80026f20 <bcache+0x8000>
    80003254:	2b87b703          	ld	a4,696(a5)
    80003258:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000325a:	00024717          	auipc	a4,0x24
    8000325e:	f2e70713          	addi	a4,a4,-210 # 80027188 <bcache+0x8268>
    80003262:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003264:	2b87b703          	ld	a4,696(a5)
    80003268:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000326a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000326e:	0001c517          	auipc	a0,0x1c
    80003272:	cb250513          	addi	a0,a0,-846 # 8001ef20 <bcache>
    80003276:	ffffe097          	auipc	ra,0xffffe
    8000327a:	a28080e7          	jalr	-1496(ra) # 80000c9e <release>
}
    8000327e:	60e2                	ld	ra,24(sp)
    80003280:	6442                	ld	s0,16(sp)
    80003282:	64a2                	ld	s1,8(sp)
    80003284:	6902                	ld	s2,0(sp)
    80003286:	6105                	addi	sp,sp,32
    80003288:	8082                	ret
    panic("brelse");
    8000328a:	00005517          	auipc	a0,0x5
    8000328e:	49650513          	addi	a0,a0,1174 # 80008720 <syscalls+0x128>
    80003292:	ffffd097          	auipc	ra,0xffffd
    80003296:	2b2080e7          	jalr	690(ra) # 80000544 <panic>

000000008000329a <bpin>:

void
bpin(struct buf *b) {
    8000329a:	1101                	addi	sp,sp,-32
    8000329c:	ec06                	sd	ra,24(sp)
    8000329e:	e822                	sd	s0,16(sp)
    800032a0:	e426                	sd	s1,8(sp)
    800032a2:	1000                	addi	s0,sp,32
    800032a4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032a6:	0001c517          	auipc	a0,0x1c
    800032aa:	c7a50513          	addi	a0,a0,-902 # 8001ef20 <bcache>
    800032ae:	ffffe097          	auipc	ra,0xffffe
    800032b2:	93c080e7          	jalr	-1732(ra) # 80000bea <acquire>
  b->refcnt++;
    800032b6:	40bc                	lw	a5,64(s1)
    800032b8:	2785                	addiw	a5,a5,1
    800032ba:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032bc:	0001c517          	auipc	a0,0x1c
    800032c0:	c6450513          	addi	a0,a0,-924 # 8001ef20 <bcache>
    800032c4:	ffffe097          	auipc	ra,0xffffe
    800032c8:	9da080e7          	jalr	-1574(ra) # 80000c9e <release>
}
    800032cc:	60e2                	ld	ra,24(sp)
    800032ce:	6442                	ld	s0,16(sp)
    800032d0:	64a2                	ld	s1,8(sp)
    800032d2:	6105                	addi	sp,sp,32
    800032d4:	8082                	ret

00000000800032d6 <bunpin>:

void
bunpin(struct buf *b) {
    800032d6:	1101                	addi	sp,sp,-32
    800032d8:	ec06                	sd	ra,24(sp)
    800032da:	e822                	sd	s0,16(sp)
    800032dc:	e426                	sd	s1,8(sp)
    800032de:	1000                	addi	s0,sp,32
    800032e0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032e2:	0001c517          	auipc	a0,0x1c
    800032e6:	c3e50513          	addi	a0,a0,-962 # 8001ef20 <bcache>
    800032ea:	ffffe097          	auipc	ra,0xffffe
    800032ee:	900080e7          	jalr	-1792(ra) # 80000bea <acquire>
  b->refcnt--;
    800032f2:	40bc                	lw	a5,64(s1)
    800032f4:	37fd                	addiw	a5,a5,-1
    800032f6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032f8:	0001c517          	auipc	a0,0x1c
    800032fc:	c2850513          	addi	a0,a0,-984 # 8001ef20 <bcache>
    80003300:	ffffe097          	auipc	ra,0xffffe
    80003304:	99e080e7          	jalr	-1634(ra) # 80000c9e <release>
}
    80003308:	60e2                	ld	ra,24(sp)
    8000330a:	6442                	ld	s0,16(sp)
    8000330c:	64a2                	ld	s1,8(sp)
    8000330e:	6105                	addi	sp,sp,32
    80003310:	8082                	ret

0000000080003312 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003312:	1101                	addi	sp,sp,-32
    80003314:	ec06                	sd	ra,24(sp)
    80003316:	e822                	sd	s0,16(sp)
    80003318:	e426                	sd	s1,8(sp)
    8000331a:	e04a                	sd	s2,0(sp)
    8000331c:	1000                	addi	s0,sp,32
    8000331e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003320:	00d5d59b          	srliw	a1,a1,0xd
    80003324:	00024797          	auipc	a5,0x24
    80003328:	2d87a783          	lw	a5,728(a5) # 800275fc <sb+0x1c>
    8000332c:	9dbd                	addw	a1,a1,a5
    8000332e:	00000097          	auipc	ra,0x0
    80003332:	d9e080e7          	jalr	-610(ra) # 800030cc <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003336:	0074f713          	andi	a4,s1,7
    8000333a:	4785                	li	a5,1
    8000333c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003340:	14ce                	slli	s1,s1,0x33
    80003342:	90d9                	srli	s1,s1,0x36
    80003344:	00950733          	add	a4,a0,s1
    80003348:	05874703          	lbu	a4,88(a4)
    8000334c:	00e7f6b3          	and	a3,a5,a4
    80003350:	c69d                	beqz	a3,8000337e <bfree+0x6c>
    80003352:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003354:	94aa                	add	s1,s1,a0
    80003356:	fff7c793          	not	a5,a5
    8000335a:	8ff9                	and	a5,a5,a4
    8000335c:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003360:	00001097          	auipc	ra,0x1
    80003364:	120080e7          	jalr	288(ra) # 80004480 <log_write>
  brelse(bp);
    80003368:	854a                	mv	a0,s2
    8000336a:	00000097          	auipc	ra,0x0
    8000336e:	e92080e7          	jalr	-366(ra) # 800031fc <brelse>
}
    80003372:	60e2                	ld	ra,24(sp)
    80003374:	6442                	ld	s0,16(sp)
    80003376:	64a2                	ld	s1,8(sp)
    80003378:	6902                	ld	s2,0(sp)
    8000337a:	6105                	addi	sp,sp,32
    8000337c:	8082                	ret
    panic("freeing free block");
    8000337e:	00005517          	auipc	a0,0x5
    80003382:	3aa50513          	addi	a0,a0,938 # 80008728 <syscalls+0x130>
    80003386:	ffffd097          	auipc	ra,0xffffd
    8000338a:	1be080e7          	jalr	446(ra) # 80000544 <panic>

000000008000338e <balloc>:
{
    8000338e:	711d                	addi	sp,sp,-96
    80003390:	ec86                	sd	ra,88(sp)
    80003392:	e8a2                	sd	s0,80(sp)
    80003394:	e4a6                	sd	s1,72(sp)
    80003396:	e0ca                	sd	s2,64(sp)
    80003398:	fc4e                	sd	s3,56(sp)
    8000339a:	f852                	sd	s4,48(sp)
    8000339c:	f456                	sd	s5,40(sp)
    8000339e:	f05a                	sd	s6,32(sp)
    800033a0:	ec5e                	sd	s7,24(sp)
    800033a2:	e862                	sd	s8,16(sp)
    800033a4:	e466                	sd	s9,8(sp)
    800033a6:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800033a8:	00024797          	auipc	a5,0x24
    800033ac:	23c7a783          	lw	a5,572(a5) # 800275e4 <sb+0x4>
    800033b0:	10078163          	beqz	a5,800034b2 <balloc+0x124>
    800033b4:	8baa                	mv	s7,a0
    800033b6:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800033b8:	00024b17          	auipc	s6,0x24
    800033bc:	228b0b13          	addi	s6,s6,552 # 800275e0 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033c0:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800033c2:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033c4:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800033c6:	6c89                	lui	s9,0x2
    800033c8:	a061                	j	80003450 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    800033ca:	974a                	add	a4,a4,s2
    800033cc:	8fd5                	or	a5,a5,a3
    800033ce:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800033d2:	854a                	mv	a0,s2
    800033d4:	00001097          	auipc	ra,0x1
    800033d8:	0ac080e7          	jalr	172(ra) # 80004480 <log_write>
        brelse(bp);
    800033dc:	854a                	mv	a0,s2
    800033de:	00000097          	auipc	ra,0x0
    800033e2:	e1e080e7          	jalr	-482(ra) # 800031fc <brelse>
  bp = bread(dev, bno);
    800033e6:	85a6                	mv	a1,s1
    800033e8:	855e                	mv	a0,s7
    800033ea:	00000097          	auipc	ra,0x0
    800033ee:	ce2080e7          	jalr	-798(ra) # 800030cc <bread>
    800033f2:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800033f4:	40000613          	li	a2,1024
    800033f8:	4581                	li	a1,0
    800033fa:	05850513          	addi	a0,a0,88
    800033fe:	ffffe097          	auipc	ra,0xffffe
    80003402:	8e8080e7          	jalr	-1816(ra) # 80000ce6 <memset>
  log_write(bp);
    80003406:	854a                	mv	a0,s2
    80003408:	00001097          	auipc	ra,0x1
    8000340c:	078080e7          	jalr	120(ra) # 80004480 <log_write>
  brelse(bp);
    80003410:	854a                	mv	a0,s2
    80003412:	00000097          	auipc	ra,0x0
    80003416:	dea080e7          	jalr	-534(ra) # 800031fc <brelse>
}
    8000341a:	8526                	mv	a0,s1
    8000341c:	60e6                	ld	ra,88(sp)
    8000341e:	6446                	ld	s0,80(sp)
    80003420:	64a6                	ld	s1,72(sp)
    80003422:	6906                	ld	s2,64(sp)
    80003424:	79e2                	ld	s3,56(sp)
    80003426:	7a42                	ld	s4,48(sp)
    80003428:	7aa2                	ld	s5,40(sp)
    8000342a:	7b02                	ld	s6,32(sp)
    8000342c:	6be2                	ld	s7,24(sp)
    8000342e:	6c42                	ld	s8,16(sp)
    80003430:	6ca2                	ld	s9,8(sp)
    80003432:	6125                	addi	sp,sp,96
    80003434:	8082                	ret
    brelse(bp);
    80003436:	854a                	mv	a0,s2
    80003438:	00000097          	auipc	ra,0x0
    8000343c:	dc4080e7          	jalr	-572(ra) # 800031fc <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003440:	015c87bb          	addw	a5,s9,s5
    80003444:	00078a9b          	sext.w	s5,a5
    80003448:	004b2703          	lw	a4,4(s6)
    8000344c:	06eaf363          	bgeu	s5,a4,800034b2 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    80003450:	41fad79b          	sraiw	a5,s5,0x1f
    80003454:	0137d79b          	srliw	a5,a5,0x13
    80003458:	015787bb          	addw	a5,a5,s5
    8000345c:	40d7d79b          	sraiw	a5,a5,0xd
    80003460:	01cb2583          	lw	a1,28(s6)
    80003464:	9dbd                	addw	a1,a1,a5
    80003466:	855e                	mv	a0,s7
    80003468:	00000097          	auipc	ra,0x0
    8000346c:	c64080e7          	jalr	-924(ra) # 800030cc <bread>
    80003470:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003472:	004b2503          	lw	a0,4(s6)
    80003476:	000a849b          	sext.w	s1,s5
    8000347a:	8662                	mv	a2,s8
    8000347c:	faa4fde3          	bgeu	s1,a0,80003436 <balloc+0xa8>
      m = 1 << (bi % 8);
    80003480:	41f6579b          	sraiw	a5,a2,0x1f
    80003484:	01d7d69b          	srliw	a3,a5,0x1d
    80003488:	00c6873b          	addw	a4,a3,a2
    8000348c:	00777793          	andi	a5,a4,7
    80003490:	9f95                	subw	a5,a5,a3
    80003492:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003496:	4037571b          	sraiw	a4,a4,0x3
    8000349a:	00e906b3          	add	a3,s2,a4
    8000349e:	0586c683          	lbu	a3,88(a3)
    800034a2:	00d7f5b3          	and	a1,a5,a3
    800034a6:	d195                	beqz	a1,800033ca <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034a8:	2605                	addiw	a2,a2,1
    800034aa:	2485                	addiw	s1,s1,1
    800034ac:	fd4618e3          	bne	a2,s4,8000347c <balloc+0xee>
    800034b0:	b759                	j	80003436 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    800034b2:	00005517          	auipc	a0,0x5
    800034b6:	28e50513          	addi	a0,a0,654 # 80008740 <syscalls+0x148>
    800034ba:	ffffd097          	auipc	ra,0xffffd
    800034be:	0d4080e7          	jalr	212(ra) # 8000058e <printf>
  return 0;
    800034c2:	4481                	li	s1,0
    800034c4:	bf99                	j	8000341a <balloc+0x8c>

00000000800034c6 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800034c6:	7179                	addi	sp,sp,-48
    800034c8:	f406                	sd	ra,40(sp)
    800034ca:	f022                	sd	s0,32(sp)
    800034cc:	ec26                	sd	s1,24(sp)
    800034ce:	e84a                	sd	s2,16(sp)
    800034d0:	e44e                	sd	s3,8(sp)
    800034d2:	e052                	sd	s4,0(sp)
    800034d4:	1800                	addi	s0,sp,48
    800034d6:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800034d8:	47ad                	li	a5,11
    800034da:	02b7e763          	bltu	a5,a1,80003508 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    800034de:	02059493          	slli	s1,a1,0x20
    800034e2:	9081                	srli	s1,s1,0x20
    800034e4:	048a                	slli	s1,s1,0x2
    800034e6:	94aa                	add	s1,s1,a0
    800034e8:	0504a903          	lw	s2,80(s1)
    800034ec:	06091e63          	bnez	s2,80003568 <bmap+0xa2>
      addr = balloc(ip->dev);
    800034f0:	4108                	lw	a0,0(a0)
    800034f2:	00000097          	auipc	ra,0x0
    800034f6:	e9c080e7          	jalr	-356(ra) # 8000338e <balloc>
    800034fa:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800034fe:	06090563          	beqz	s2,80003568 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    80003502:	0524a823          	sw	s2,80(s1)
    80003506:	a08d                	j	80003568 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003508:	ff45849b          	addiw	s1,a1,-12
    8000350c:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003510:	0ff00793          	li	a5,255
    80003514:	08e7e563          	bltu	a5,a4,8000359e <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003518:	08052903          	lw	s2,128(a0)
    8000351c:	00091d63          	bnez	s2,80003536 <bmap+0x70>
      addr = balloc(ip->dev);
    80003520:	4108                	lw	a0,0(a0)
    80003522:	00000097          	auipc	ra,0x0
    80003526:	e6c080e7          	jalr	-404(ra) # 8000338e <balloc>
    8000352a:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000352e:	02090d63          	beqz	s2,80003568 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003532:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003536:	85ca                	mv	a1,s2
    80003538:	0009a503          	lw	a0,0(s3)
    8000353c:	00000097          	auipc	ra,0x0
    80003540:	b90080e7          	jalr	-1136(ra) # 800030cc <bread>
    80003544:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003546:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000354a:	02049593          	slli	a1,s1,0x20
    8000354e:	9181                	srli	a1,a1,0x20
    80003550:	058a                	slli	a1,a1,0x2
    80003552:	00b784b3          	add	s1,a5,a1
    80003556:	0004a903          	lw	s2,0(s1)
    8000355a:	02090063          	beqz	s2,8000357a <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    8000355e:	8552                	mv	a0,s4
    80003560:	00000097          	auipc	ra,0x0
    80003564:	c9c080e7          	jalr	-868(ra) # 800031fc <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003568:	854a                	mv	a0,s2
    8000356a:	70a2                	ld	ra,40(sp)
    8000356c:	7402                	ld	s0,32(sp)
    8000356e:	64e2                	ld	s1,24(sp)
    80003570:	6942                	ld	s2,16(sp)
    80003572:	69a2                	ld	s3,8(sp)
    80003574:	6a02                	ld	s4,0(sp)
    80003576:	6145                	addi	sp,sp,48
    80003578:	8082                	ret
      addr = balloc(ip->dev);
    8000357a:	0009a503          	lw	a0,0(s3)
    8000357e:	00000097          	auipc	ra,0x0
    80003582:	e10080e7          	jalr	-496(ra) # 8000338e <balloc>
    80003586:	0005091b          	sext.w	s2,a0
      if(addr){
    8000358a:	fc090ae3          	beqz	s2,8000355e <bmap+0x98>
        a[bn] = addr;
    8000358e:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003592:	8552                	mv	a0,s4
    80003594:	00001097          	auipc	ra,0x1
    80003598:	eec080e7          	jalr	-276(ra) # 80004480 <log_write>
    8000359c:	b7c9                	j	8000355e <bmap+0x98>
  panic("bmap: out of range");
    8000359e:	00005517          	auipc	a0,0x5
    800035a2:	1ba50513          	addi	a0,a0,442 # 80008758 <syscalls+0x160>
    800035a6:	ffffd097          	auipc	ra,0xffffd
    800035aa:	f9e080e7          	jalr	-98(ra) # 80000544 <panic>

00000000800035ae <iget>:
{
    800035ae:	7179                	addi	sp,sp,-48
    800035b0:	f406                	sd	ra,40(sp)
    800035b2:	f022                	sd	s0,32(sp)
    800035b4:	ec26                	sd	s1,24(sp)
    800035b6:	e84a                	sd	s2,16(sp)
    800035b8:	e44e                	sd	s3,8(sp)
    800035ba:	e052                	sd	s4,0(sp)
    800035bc:	1800                	addi	s0,sp,48
    800035be:	89aa                	mv	s3,a0
    800035c0:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800035c2:	00024517          	auipc	a0,0x24
    800035c6:	03e50513          	addi	a0,a0,62 # 80027600 <itable>
    800035ca:	ffffd097          	auipc	ra,0xffffd
    800035ce:	620080e7          	jalr	1568(ra) # 80000bea <acquire>
  empty = 0;
    800035d2:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800035d4:	00024497          	auipc	s1,0x24
    800035d8:	04448493          	addi	s1,s1,68 # 80027618 <itable+0x18>
    800035dc:	00026697          	auipc	a3,0x26
    800035e0:	acc68693          	addi	a3,a3,-1332 # 800290a8 <log>
    800035e4:	a039                	j	800035f2 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035e6:	02090b63          	beqz	s2,8000361c <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800035ea:	08848493          	addi	s1,s1,136
    800035ee:	02d48a63          	beq	s1,a3,80003622 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800035f2:	449c                	lw	a5,8(s1)
    800035f4:	fef059e3          	blez	a5,800035e6 <iget+0x38>
    800035f8:	4098                	lw	a4,0(s1)
    800035fa:	ff3716e3          	bne	a4,s3,800035e6 <iget+0x38>
    800035fe:	40d8                	lw	a4,4(s1)
    80003600:	ff4713e3          	bne	a4,s4,800035e6 <iget+0x38>
      ip->ref++;
    80003604:	2785                	addiw	a5,a5,1
    80003606:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003608:	00024517          	auipc	a0,0x24
    8000360c:	ff850513          	addi	a0,a0,-8 # 80027600 <itable>
    80003610:	ffffd097          	auipc	ra,0xffffd
    80003614:	68e080e7          	jalr	1678(ra) # 80000c9e <release>
      return ip;
    80003618:	8926                	mv	s2,s1
    8000361a:	a03d                	j	80003648 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000361c:	f7f9                	bnez	a5,800035ea <iget+0x3c>
    8000361e:	8926                	mv	s2,s1
    80003620:	b7e9                	j	800035ea <iget+0x3c>
  if(empty == 0)
    80003622:	02090c63          	beqz	s2,8000365a <iget+0xac>
  ip->dev = dev;
    80003626:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000362a:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000362e:	4785                	li	a5,1
    80003630:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003634:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003638:	00024517          	auipc	a0,0x24
    8000363c:	fc850513          	addi	a0,a0,-56 # 80027600 <itable>
    80003640:	ffffd097          	auipc	ra,0xffffd
    80003644:	65e080e7          	jalr	1630(ra) # 80000c9e <release>
}
    80003648:	854a                	mv	a0,s2
    8000364a:	70a2                	ld	ra,40(sp)
    8000364c:	7402                	ld	s0,32(sp)
    8000364e:	64e2                	ld	s1,24(sp)
    80003650:	6942                	ld	s2,16(sp)
    80003652:	69a2                	ld	s3,8(sp)
    80003654:	6a02                	ld	s4,0(sp)
    80003656:	6145                	addi	sp,sp,48
    80003658:	8082                	ret
    panic("iget: no inodes");
    8000365a:	00005517          	auipc	a0,0x5
    8000365e:	11650513          	addi	a0,a0,278 # 80008770 <syscalls+0x178>
    80003662:	ffffd097          	auipc	ra,0xffffd
    80003666:	ee2080e7          	jalr	-286(ra) # 80000544 <panic>

000000008000366a <fsinit>:
fsinit(int dev) {
    8000366a:	7179                	addi	sp,sp,-48
    8000366c:	f406                	sd	ra,40(sp)
    8000366e:	f022                	sd	s0,32(sp)
    80003670:	ec26                	sd	s1,24(sp)
    80003672:	e84a                	sd	s2,16(sp)
    80003674:	e44e                	sd	s3,8(sp)
    80003676:	1800                	addi	s0,sp,48
    80003678:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000367a:	4585                	li	a1,1
    8000367c:	00000097          	auipc	ra,0x0
    80003680:	a50080e7          	jalr	-1456(ra) # 800030cc <bread>
    80003684:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003686:	00024997          	auipc	s3,0x24
    8000368a:	f5a98993          	addi	s3,s3,-166 # 800275e0 <sb>
    8000368e:	02000613          	li	a2,32
    80003692:	05850593          	addi	a1,a0,88
    80003696:	854e                	mv	a0,s3
    80003698:	ffffd097          	auipc	ra,0xffffd
    8000369c:	6ae080e7          	jalr	1710(ra) # 80000d46 <memmove>
  brelse(bp);
    800036a0:	8526                	mv	a0,s1
    800036a2:	00000097          	auipc	ra,0x0
    800036a6:	b5a080e7          	jalr	-1190(ra) # 800031fc <brelse>
  if(sb.magic != FSMAGIC)
    800036aa:	0009a703          	lw	a4,0(s3)
    800036ae:	102037b7          	lui	a5,0x10203
    800036b2:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800036b6:	02f71263          	bne	a4,a5,800036da <fsinit+0x70>
  initlog(dev, &sb);
    800036ba:	00024597          	auipc	a1,0x24
    800036be:	f2658593          	addi	a1,a1,-218 # 800275e0 <sb>
    800036c2:	854a                	mv	a0,s2
    800036c4:	00001097          	auipc	ra,0x1
    800036c8:	b40080e7          	jalr	-1216(ra) # 80004204 <initlog>
}
    800036cc:	70a2                	ld	ra,40(sp)
    800036ce:	7402                	ld	s0,32(sp)
    800036d0:	64e2                	ld	s1,24(sp)
    800036d2:	6942                	ld	s2,16(sp)
    800036d4:	69a2                	ld	s3,8(sp)
    800036d6:	6145                	addi	sp,sp,48
    800036d8:	8082                	ret
    panic("invalid file system");
    800036da:	00005517          	auipc	a0,0x5
    800036de:	0a650513          	addi	a0,a0,166 # 80008780 <syscalls+0x188>
    800036e2:	ffffd097          	auipc	ra,0xffffd
    800036e6:	e62080e7          	jalr	-414(ra) # 80000544 <panic>

00000000800036ea <iinit>:
{
    800036ea:	7179                	addi	sp,sp,-48
    800036ec:	f406                	sd	ra,40(sp)
    800036ee:	f022                	sd	s0,32(sp)
    800036f0:	ec26                	sd	s1,24(sp)
    800036f2:	e84a                	sd	s2,16(sp)
    800036f4:	e44e                	sd	s3,8(sp)
    800036f6:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800036f8:	00005597          	auipc	a1,0x5
    800036fc:	0a058593          	addi	a1,a1,160 # 80008798 <syscalls+0x1a0>
    80003700:	00024517          	auipc	a0,0x24
    80003704:	f0050513          	addi	a0,a0,-256 # 80027600 <itable>
    80003708:	ffffd097          	auipc	ra,0xffffd
    8000370c:	452080e7          	jalr	1106(ra) # 80000b5a <initlock>
  for(i = 0; i < NINODE; i++) {
    80003710:	00024497          	auipc	s1,0x24
    80003714:	f1848493          	addi	s1,s1,-232 # 80027628 <itable+0x28>
    80003718:	00026997          	auipc	s3,0x26
    8000371c:	9a098993          	addi	s3,s3,-1632 # 800290b8 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003720:	00005917          	auipc	s2,0x5
    80003724:	08090913          	addi	s2,s2,128 # 800087a0 <syscalls+0x1a8>
    80003728:	85ca                	mv	a1,s2
    8000372a:	8526                	mv	a0,s1
    8000372c:	00001097          	auipc	ra,0x1
    80003730:	e3a080e7          	jalr	-454(ra) # 80004566 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003734:	08848493          	addi	s1,s1,136
    80003738:	ff3498e3          	bne	s1,s3,80003728 <iinit+0x3e>
}
    8000373c:	70a2                	ld	ra,40(sp)
    8000373e:	7402                	ld	s0,32(sp)
    80003740:	64e2                	ld	s1,24(sp)
    80003742:	6942                	ld	s2,16(sp)
    80003744:	69a2                	ld	s3,8(sp)
    80003746:	6145                	addi	sp,sp,48
    80003748:	8082                	ret

000000008000374a <ialloc>:
{
    8000374a:	715d                	addi	sp,sp,-80
    8000374c:	e486                	sd	ra,72(sp)
    8000374e:	e0a2                	sd	s0,64(sp)
    80003750:	fc26                	sd	s1,56(sp)
    80003752:	f84a                	sd	s2,48(sp)
    80003754:	f44e                	sd	s3,40(sp)
    80003756:	f052                	sd	s4,32(sp)
    80003758:	ec56                	sd	s5,24(sp)
    8000375a:	e85a                	sd	s6,16(sp)
    8000375c:	e45e                	sd	s7,8(sp)
    8000375e:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003760:	00024717          	auipc	a4,0x24
    80003764:	e8c72703          	lw	a4,-372(a4) # 800275ec <sb+0xc>
    80003768:	4785                	li	a5,1
    8000376a:	04e7fa63          	bgeu	a5,a4,800037be <ialloc+0x74>
    8000376e:	8aaa                	mv	s5,a0
    80003770:	8bae                	mv	s7,a1
    80003772:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003774:	00024a17          	auipc	s4,0x24
    80003778:	e6ca0a13          	addi	s4,s4,-404 # 800275e0 <sb>
    8000377c:	00048b1b          	sext.w	s6,s1
    80003780:	0044d593          	srli	a1,s1,0x4
    80003784:	018a2783          	lw	a5,24(s4)
    80003788:	9dbd                	addw	a1,a1,a5
    8000378a:	8556                	mv	a0,s5
    8000378c:	00000097          	auipc	ra,0x0
    80003790:	940080e7          	jalr	-1728(ra) # 800030cc <bread>
    80003794:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003796:	05850993          	addi	s3,a0,88
    8000379a:	00f4f793          	andi	a5,s1,15
    8000379e:	079a                	slli	a5,a5,0x6
    800037a0:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800037a2:	00099783          	lh	a5,0(s3)
    800037a6:	c3a1                	beqz	a5,800037e6 <ialloc+0x9c>
    brelse(bp);
    800037a8:	00000097          	auipc	ra,0x0
    800037ac:	a54080e7          	jalr	-1452(ra) # 800031fc <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800037b0:	0485                	addi	s1,s1,1
    800037b2:	00ca2703          	lw	a4,12(s4)
    800037b6:	0004879b          	sext.w	a5,s1
    800037ba:	fce7e1e3          	bltu	a5,a4,8000377c <ialloc+0x32>
  printf("ialloc: no inodes\n");
    800037be:	00005517          	auipc	a0,0x5
    800037c2:	fea50513          	addi	a0,a0,-22 # 800087a8 <syscalls+0x1b0>
    800037c6:	ffffd097          	auipc	ra,0xffffd
    800037ca:	dc8080e7          	jalr	-568(ra) # 8000058e <printf>
  return 0;
    800037ce:	4501                	li	a0,0
}
    800037d0:	60a6                	ld	ra,72(sp)
    800037d2:	6406                	ld	s0,64(sp)
    800037d4:	74e2                	ld	s1,56(sp)
    800037d6:	7942                	ld	s2,48(sp)
    800037d8:	79a2                	ld	s3,40(sp)
    800037da:	7a02                	ld	s4,32(sp)
    800037dc:	6ae2                	ld	s5,24(sp)
    800037de:	6b42                	ld	s6,16(sp)
    800037e0:	6ba2                	ld	s7,8(sp)
    800037e2:	6161                	addi	sp,sp,80
    800037e4:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800037e6:	04000613          	li	a2,64
    800037ea:	4581                	li	a1,0
    800037ec:	854e                	mv	a0,s3
    800037ee:	ffffd097          	auipc	ra,0xffffd
    800037f2:	4f8080e7          	jalr	1272(ra) # 80000ce6 <memset>
      dip->type = type;
    800037f6:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800037fa:	854a                	mv	a0,s2
    800037fc:	00001097          	auipc	ra,0x1
    80003800:	c84080e7          	jalr	-892(ra) # 80004480 <log_write>
      brelse(bp);
    80003804:	854a                	mv	a0,s2
    80003806:	00000097          	auipc	ra,0x0
    8000380a:	9f6080e7          	jalr	-1546(ra) # 800031fc <brelse>
      return iget(dev, inum);
    8000380e:	85da                	mv	a1,s6
    80003810:	8556                	mv	a0,s5
    80003812:	00000097          	auipc	ra,0x0
    80003816:	d9c080e7          	jalr	-612(ra) # 800035ae <iget>
    8000381a:	bf5d                	j	800037d0 <ialloc+0x86>

000000008000381c <iupdate>:
{
    8000381c:	1101                	addi	sp,sp,-32
    8000381e:	ec06                	sd	ra,24(sp)
    80003820:	e822                	sd	s0,16(sp)
    80003822:	e426                	sd	s1,8(sp)
    80003824:	e04a                	sd	s2,0(sp)
    80003826:	1000                	addi	s0,sp,32
    80003828:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000382a:	415c                	lw	a5,4(a0)
    8000382c:	0047d79b          	srliw	a5,a5,0x4
    80003830:	00024597          	auipc	a1,0x24
    80003834:	dc85a583          	lw	a1,-568(a1) # 800275f8 <sb+0x18>
    80003838:	9dbd                	addw	a1,a1,a5
    8000383a:	4108                	lw	a0,0(a0)
    8000383c:	00000097          	auipc	ra,0x0
    80003840:	890080e7          	jalr	-1904(ra) # 800030cc <bread>
    80003844:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003846:	05850793          	addi	a5,a0,88
    8000384a:	40c8                	lw	a0,4(s1)
    8000384c:	893d                	andi	a0,a0,15
    8000384e:	051a                	slli	a0,a0,0x6
    80003850:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003852:	04449703          	lh	a4,68(s1)
    80003856:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000385a:	04649703          	lh	a4,70(s1)
    8000385e:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003862:	04849703          	lh	a4,72(s1)
    80003866:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000386a:	04a49703          	lh	a4,74(s1)
    8000386e:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003872:	44f8                	lw	a4,76(s1)
    80003874:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003876:	03400613          	li	a2,52
    8000387a:	05048593          	addi	a1,s1,80
    8000387e:	0531                	addi	a0,a0,12
    80003880:	ffffd097          	auipc	ra,0xffffd
    80003884:	4c6080e7          	jalr	1222(ra) # 80000d46 <memmove>
  log_write(bp);
    80003888:	854a                	mv	a0,s2
    8000388a:	00001097          	auipc	ra,0x1
    8000388e:	bf6080e7          	jalr	-1034(ra) # 80004480 <log_write>
  brelse(bp);
    80003892:	854a                	mv	a0,s2
    80003894:	00000097          	auipc	ra,0x0
    80003898:	968080e7          	jalr	-1688(ra) # 800031fc <brelse>
}
    8000389c:	60e2                	ld	ra,24(sp)
    8000389e:	6442                	ld	s0,16(sp)
    800038a0:	64a2                	ld	s1,8(sp)
    800038a2:	6902                	ld	s2,0(sp)
    800038a4:	6105                	addi	sp,sp,32
    800038a6:	8082                	ret

00000000800038a8 <idup>:
{
    800038a8:	1101                	addi	sp,sp,-32
    800038aa:	ec06                	sd	ra,24(sp)
    800038ac:	e822                	sd	s0,16(sp)
    800038ae:	e426                	sd	s1,8(sp)
    800038b0:	1000                	addi	s0,sp,32
    800038b2:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800038b4:	00024517          	auipc	a0,0x24
    800038b8:	d4c50513          	addi	a0,a0,-692 # 80027600 <itable>
    800038bc:	ffffd097          	auipc	ra,0xffffd
    800038c0:	32e080e7          	jalr	814(ra) # 80000bea <acquire>
  ip->ref++;
    800038c4:	449c                	lw	a5,8(s1)
    800038c6:	2785                	addiw	a5,a5,1
    800038c8:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800038ca:	00024517          	auipc	a0,0x24
    800038ce:	d3650513          	addi	a0,a0,-714 # 80027600 <itable>
    800038d2:	ffffd097          	auipc	ra,0xffffd
    800038d6:	3cc080e7          	jalr	972(ra) # 80000c9e <release>
}
    800038da:	8526                	mv	a0,s1
    800038dc:	60e2                	ld	ra,24(sp)
    800038de:	6442                	ld	s0,16(sp)
    800038e0:	64a2                	ld	s1,8(sp)
    800038e2:	6105                	addi	sp,sp,32
    800038e4:	8082                	ret

00000000800038e6 <ilock>:
{
    800038e6:	1101                	addi	sp,sp,-32
    800038e8:	ec06                	sd	ra,24(sp)
    800038ea:	e822                	sd	s0,16(sp)
    800038ec:	e426                	sd	s1,8(sp)
    800038ee:	e04a                	sd	s2,0(sp)
    800038f0:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800038f2:	c115                	beqz	a0,80003916 <ilock+0x30>
    800038f4:	84aa                	mv	s1,a0
    800038f6:	451c                	lw	a5,8(a0)
    800038f8:	00f05f63          	blez	a5,80003916 <ilock+0x30>
  acquiresleep(&ip->lock);
    800038fc:	0541                	addi	a0,a0,16
    800038fe:	00001097          	auipc	ra,0x1
    80003902:	ca2080e7          	jalr	-862(ra) # 800045a0 <acquiresleep>
  if(ip->valid == 0){
    80003906:	40bc                	lw	a5,64(s1)
    80003908:	cf99                	beqz	a5,80003926 <ilock+0x40>
}
    8000390a:	60e2                	ld	ra,24(sp)
    8000390c:	6442                	ld	s0,16(sp)
    8000390e:	64a2                	ld	s1,8(sp)
    80003910:	6902                	ld	s2,0(sp)
    80003912:	6105                	addi	sp,sp,32
    80003914:	8082                	ret
    panic("ilock");
    80003916:	00005517          	auipc	a0,0x5
    8000391a:	eaa50513          	addi	a0,a0,-342 # 800087c0 <syscalls+0x1c8>
    8000391e:	ffffd097          	auipc	ra,0xffffd
    80003922:	c26080e7          	jalr	-986(ra) # 80000544 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003926:	40dc                	lw	a5,4(s1)
    80003928:	0047d79b          	srliw	a5,a5,0x4
    8000392c:	00024597          	auipc	a1,0x24
    80003930:	ccc5a583          	lw	a1,-820(a1) # 800275f8 <sb+0x18>
    80003934:	9dbd                	addw	a1,a1,a5
    80003936:	4088                	lw	a0,0(s1)
    80003938:	fffff097          	auipc	ra,0xfffff
    8000393c:	794080e7          	jalr	1940(ra) # 800030cc <bread>
    80003940:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003942:	05850593          	addi	a1,a0,88
    80003946:	40dc                	lw	a5,4(s1)
    80003948:	8bbd                	andi	a5,a5,15
    8000394a:	079a                	slli	a5,a5,0x6
    8000394c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000394e:	00059783          	lh	a5,0(a1)
    80003952:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003956:	00259783          	lh	a5,2(a1)
    8000395a:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000395e:	00459783          	lh	a5,4(a1)
    80003962:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003966:	00659783          	lh	a5,6(a1)
    8000396a:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000396e:	459c                	lw	a5,8(a1)
    80003970:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003972:	03400613          	li	a2,52
    80003976:	05b1                	addi	a1,a1,12
    80003978:	05048513          	addi	a0,s1,80
    8000397c:	ffffd097          	auipc	ra,0xffffd
    80003980:	3ca080e7          	jalr	970(ra) # 80000d46 <memmove>
    brelse(bp);
    80003984:	854a                	mv	a0,s2
    80003986:	00000097          	auipc	ra,0x0
    8000398a:	876080e7          	jalr	-1930(ra) # 800031fc <brelse>
    ip->valid = 1;
    8000398e:	4785                	li	a5,1
    80003990:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003992:	04449783          	lh	a5,68(s1)
    80003996:	fbb5                	bnez	a5,8000390a <ilock+0x24>
      panic("ilock: no type");
    80003998:	00005517          	auipc	a0,0x5
    8000399c:	e3050513          	addi	a0,a0,-464 # 800087c8 <syscalls+0x1d0>
    800039a0:	ffffd097          	auipc	ra,0xffffd
    800039a4:	ba4080e7          	jalr	-1116(ra) # 80000544 <panic>

00000000800039a8 <iunlock>:
{
    800039a8:	1101                	addi	sp,sp,-32
    800039aa:	ec06                	sd	ra,24(sp)
    800039ac:	e822                	sd	s0,16(sp)
    800039ae:	e426                	sd	s1,8(sp)
    800039b0:	e04a                	sd	s2,0(sp)
    800039b2:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800039b4:	c905                	beqz	a0,800039e4 <iunlock+0x3c>
    800039b6:	84aa                	mv	s1,a0
    800039b8:	01050913          	addi	s2,a0,16
    800039bc:	854a                	mv	a0,s2
    800039be:	00001097          	auipc	ra,0x1
    800039c2:	c7c080e7          	jalr	-900(ra) # 8000463a <holdingsleep>
    800039c6:	cd19                	beqz	a0,800039e4 <iunlock+0x3c>
    800039c8:	449c                	lw	a5,8(s1)
    800039ca:	00f05d63          	blez	a5,800039e4 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800039ce:	854a                	mv	a0,s2
    800039d0:	00001097          	auipc	ra,0x1
    800039d4:	c26080e7          	jalr	-986(ra) # 800045f6 <releasesleep>
}
    800039d8:	60e2                	ld	ra,24(sp)
    800039da:	6442                	ld	s0,16(sp)
    800039dc:	64a2                	ld	s1,8(sp)
    800039de:	6902                	ld	s2,0(sp)
    800039e0:	6105                	addi	sp,sp,32
    800039e2:	8082                	ret
    panic("iunlock");
    800039e4:	00005517          	auipc	a0,0x5
    800039e8:	df450513          	addi	a0,a0,-524 # 800087d8 <syscalls+0x1e0>
    800039ec:	ffffd097          	auipc	ra,0xffffd
    800039f0:	b58080e7          	jalr	-1192(ra) # 80000544 <panic>

00000000800039f4 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800039f4:	7179                	addi	sp,sp,-48
    800039f6:	f406                	sd	ra,40(sp)
    800039f8:	f022                	sd	s0,32(sp)
    800039fa:	ec26                	sd	s1,24(sp)
    800039fc:	e84a                	sd	s2,16(sp)
    800039fe:	e44e                	sd	s3,8(sp)
    80003a00:	e052                	sd	s4,0(sp)
    80003a02:	1800                	addi	s0,sp,48
    80003a04:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003a06:	05050493          	addi	s1,a0,80
    80003a0a:	08050913          	addi	s2,a0,128
    80003a0e:	a021                	j	80003a16 <itrunc+0x22>
    80003a10:	0491                	addi	s1,s1,4
    80003a12:	01248d63          	beq	s1,s2,80003a2c <itrunc+0x38>
    if(ip->addrs[i]){
    80003a16:	408c                	lw	a1,0(s1)
    80003a18:	dde5                	beqz	a1,80003a10 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003a1a:	0009a503          	lw	a0,0(s3)
    80003a1e:	00000097          	auipc	ra,0x0
    80003a22:	8f4080e7          	jalr	-1804(ra) # 80003312 <bfree>
      ip->addrs[i] = 0;
    80003a26:	0004a023          	sw	zero,0(s1)
    80003a2a:	b7dd                	j	80003a10 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003a2c:	0809a583          	lw	a1,128(s3)
    80003a30:	e185                	bnez	a1,80003a50 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003a32:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003a36:	854e                	mv	a0,s3
    80003a38:	00000097          	auipc	ra,0x0
    80003a3c:	de4080e7          	jalr	-540(ra) # 8000381c <iupdate>
}
    80003a40:	70a2                	ld	ra,40(sp)
    80003a42:	7402                	ld	s0,32(sp)
    80003a44:	64e2                	ld	s1,24(sp)
    80003a46:	6942                	ld	s2,16(sp)
    80003a48:	69a2                	ld	s3,8(sp)
    80003a4a:	6a02                	ld	s4,0(sp)
    80003a4c:	6145                	addi	sp,sp,48
    80003a4e:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003a50:	0009a503          	lw	a0,0(s3)
    80003a54:	fffff097          	auipc	ra,0xfffff
    80003a58:	678080e7          	jalr	1656(ra) # 800030cc <bread>
    80003a5c:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003a5e:	05850493          	addi	s1,a0,88
    80003a62:	45850913          	addi	s2,a0,1112
    80003a66:	a811                	j	80003a7a <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003a68:	0009a503          	lw	a0,0(s3)
    80003a6c:	00000097          	auipc	ra,0x0
    80003a70:	8a6080e7          	jalr	-1882(ra) # 80003312 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003a74:	0491                	addi	s1,s1,4
    80003a76:	01248563          	beq	s1,s2,80003a80 <itrunc+0x8c>
      if(a[j])
    80003a7a:	408c                	lw	a1,0(s1)
    80003a7c:	dde5                	beqz	a1,80003a74 <itrunc+0x80>
    80003a7e:	b7ed                	j	80003a68 <itrunc+0x74>
    brelse(bp);
    80003a80:	8552                	mv	a0,s4
    80003a82:	fffff097          	auipc	ra,0xfffff
    80003a86:	77a080e7          	jalr	1914(ra) # 800031fc <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003a8a:	0809a583          	lw	a1,128(s3)
    80003a8e:	0009a503          	lw	a0,0(s3)
    80003a92:	00000097          	auipc	ra,0x0
    80003a96:	880080e7          	jalr	-1920(ra) # 80003312 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003a9a:	0809a023          	sw	zero,128(s3)
    80003a9e:	bf51                	j	80003a32 <itrunc+0x3e>

0000000080003aa0 <iput>:
{
    80003aa0:	1101                	addi	sp,sp,-32
    80003aa2:	ec06                	sd	ra,24(sp)
    80003aa4:	e822                	sd	s0,16(sp)
    80003aa6:	e426                	sd	s1,8(sp)
    80003aa8:	e04a                	sd	s2,0(sp)
    80003aaa:	1000                	addi	s0,sp,32
    80003aac:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003aae:	00024517          	auipc	a0,0x24
    80003ab2:	b5250513          	addi	a0,a0,-1198 # 80027600 <itable>
    80003ab6:	ffffd097          	auipc	ra,0xffffd
    80003aba:	134080e7          	jalr	308(ra) # 80000bea <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003abe:	4498                	lw	a4,8(s1)
    80003ac0:	4785                	li	a5,1
    80003ac2:	02f70363          	beq	a4,a5,80003ae8 <iput+0x48>
  ip->ref--;
    80003ac6:	449c                	lw	a5,8(s1)
    80003ac8:	37fd                	addiw	a5,a5,-1
    80003aca:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003acc:	00024517          	auipc	a0,0x24
    80003ad0:	b3450513          	addi	a0,a0,-1228 # 80027600 <itable>
    80003ad4:	ffffd097          	auipc	ra,0xffffd
    80003ad8:	1ca080e7          	jalr	458(ra) # 80000c9e <release>
}
    80003adc:	60e2                	ld	ra,24(sp)
    80003ade:	6442                	ld	s0,16(sp)
    80003ae0:	64a2                	ld	s1,8(sp)
    80003ae2:	6902                	ld	s2,0(sp)
    80003ae4:	6105                	addi	sp,sp,32
    80003ae6:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ae8:	40bc                	lw	a5,64(s1)
    80003aea:	dff1                	beqz	a5,80003ac6 <iput+0x26>
    80003aec:	04a49783          	lh	a5,74(s1)
    80003af0:	fbf9                	bnez	a5,80003ac6 <iput+0x26>
    acquiresleep(&ip->lock);
    80003af2:	01048913          	addi	s2,s1,16
    80003af6:	854a                	mv	a0,s2
    80003af8:	00001097          	auipc	ra,0x1
    80003afc:	aa8080e7          	jalr	-1368(ra) # 800045a0 <acquiresleep>
    release(&itable.lock);
    80003b00:	00024517          	auipc	a0,0x24
    80003b04:	b0050513          	addi	a0,a0,-1280 # 80027600 <itable>
    80003b08:	ffffd097          	auipc	ra,0xffffd
    80003b0c:	196080e7          	jalr	406(ra) # 80000c9e <release>
    itrunc(ip);
    80003b10:	8526                	mv	a0,s1
    80003b12:	00000097          	auipc	ra,0x0
    80003b16:	ee2080e7          	jalr	-286(ra) # 800039f4 <itrunc>
    ip->type = 0;
    80003b1a:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003b1e:	8526                	mv	a0,s1
    80003b20:	00000097          	auipc	ra,0x0
    80003b24:	cfc080e7          	jalr	-772(ra) # 8000381c <iupdate>
    ip->valid = 0;
    80003b28:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003b2c:	854a                	mv	a0,s2
    80003b2e:	00001097          	auipc	ra,0x1
    80003b32:	ac8080e7          	jalr	-1336(ra) # 800045f6 <releasesleep>
    acquire(&itable.lock);
    80003b36:	00024517          	auipc	a0,0x24
    80003b3a:	aca50513          	addi	a0,a0,-1334 # 80027600 <itable>
    80003b3e:	ffffd097          	auipc	ra,0xffffd
    80003b42:	0ac080e7          	jalr	172(ra) # 80000bea <acquire>
    80003b46:	b741                	j	80003ac6 <iput+0x26>

0000000080003b48 <iunlockput>:
{
    80003b48:	1101                	addi	sp,sp,-32
    80003b4a:	ec06                	sd	ra,24(sp)
    80003b4c:	e822                	sd	s0,16(sp)
    80003b4e:	e426                	sd	s1,8(sp)
    80003b50:	1000                	addi	s0,sp,32
    80003b52:	84aa                	mv	s1,a0
  iunlock(ip);
    80003b54:	00000097          	auipc	ra,0x0
    80003b58:	e54080e7          	jalr	-428(ra) # 800039a8 <iunlock>
  iput(ip);
    80003b5c:	8526                	mv	a0,s1
    80003b5e:	00000097          	auipc	ra,0x0
    80003b62:	f42080e7          	jalr	-190(ra) # 80003aa0 <iput>
}
    80003b66:	60e2                	ld	ra,24(sp)
    80003b68:	6442                	ld	s0,16(sp)
    80003b6a:	64a2                	ld	s1,8(sp)
    80003b6c:	6105                	addi	sp,sp,32
    80003b6e:	8082                	ret

0000000080003b70 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003b70:	1141                	addi	sp,sp,-16
    80003b72:	e422                	sd	s0,8(sp)
    80003b74:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003b76:	411c                	lw	a5,0(a0)
    80003b78:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003b7a:	415c                	lw	a5,4(a0)
    80003b7c:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003b7e:	04451783          	lh	a5,68(a0)
    80003b82:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003b86:	04a51783          	lh	a5,74(a0)
    80003b8a:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003b8e:	04c56783          	lwu	a5,76(a0)
    80003b92:	e99c                	sd	a5,16(a1)
}
    80003b94:	6422                	ld	s0,8(sp)
    80003b96:	0141                	addi	sp,sp,16
    80003b98:	8082                	ret

0000000080003b9a <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b9a:	457c                	lw	a5,76(a0)
    80003b9c:	0ed7e963          	bltu	a5,a3,80003c8e <readi+0xf4>
{
    80003ba0:	7159                	addi	sp,sp,-112
    80003ba2:	f486                	sd	ra,104(sp)
    80003ba4:	f0a2                	sd	s0,96(sp)
    80003ba6:	eca6                	sd	s1,88(sp)
    80003ba8:	e8ca                	sd	s2,80(sp)
    80003baa:	e4ce                	sd	s3,72(sp)
    80003bac:	e0d2                	sd	s4,64(sp)
    80003bae:	fc56                	sd	s5,56(sp)
    80003bb0:	f85a                	sd	s6,48(sp)
    80003bb2:	f45e                	sd	s7,40(sp)
    80003bb4:	f062                	sd	s8,32(sp)
    80003bb6:	ec66                	sd	s9,24(sp)
    80003bb8:	e86a                	sd	s10,16(sp)
    80003bba:	e46e                	sd	s11,8(sp)
    80003bbc:	1880                	addi	s0,sp,112
    80003bbe:	8b2a                	mv	s6,a0
    80003bc0:	8bae                	mv	s7,a1
    80003bc2:	8a32                	mv	s4,a2
    80003bc4:	84b6                	mv	s1,a3
    80003bc6:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003bc8:	9f35                	addw	a4,a4,a3
    return 0;
    80003bca:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003bcc:	0ad76063          	bltu	a4,a3,80003c6c <readi+0xd2>
  if(off + n > ip->size)
    80003bd0:	00e7f463          	bgeu	a5,a4,80003bd8 <readi+0x3e>
    n = ip->size - off;
    80003bd4:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bd8:	0a0a8963          	beqz	s5,80003c8a <readi+0xf0>
    80003bdc:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bde:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003be2:	5c7d                	li	s8,-1
    80003be4:	a82d                	j	80003c1e <readi+0x84>
    80003be6:	020d1d93          	slli	s11,s10,0x20
    80003bea:	020ddd93          	srli	s11,s11,0x20
    80003bee:	05890613          	addi	a2,s2,88
    80003bf2:	86ee                	mv	a3,s11
    80003bf4:	963a                	add	a2,a2,a4
    80003bf6:	85d2                	mv	a1,s4
    80003bf8:	855e                	mv	a0,s7
    80003bfa:	fffff097          	auipc	ra,0xfffff
    80003bfe:	918080e7          	jalr	-1768(ra) # 80002512 <either_copyout>
    80003c02:	05850d63          	beq	a0,s8,80003c5c <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003c06:	854a                	mv	a0,s2
    80003c08:	fffff097          	auipc	ra,0xfffff
    80003c0c:	5f4080e7          	jalr	1524(ra) # 800031fc <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c10:	013d09bb          	addw	s3,s10,s3
    80003c14:	009d04bb          	addw	s1,s10,s1
    80003c18:	9a6e                	add	s4,s4,s11
    80003c1a:	0559f763          	bgeu	s3,s5,80003c68 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003c1e:	00a4d59b          	srliw	a1,s1,0xa
    80003c22:	855a                	mv	a0,s6
    80003c24:	00000097          	auipc	ra,0x0
    80003c28:	8a2080e7          	jalr	-1886(ra) # 800034c6 <bmap>
    80003c2c:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003c30:	cd85                	beqz	a1,80003c68 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003c32:	000b2503          	lw	a0,0(s6)
    80003c36:	fffff097          	auipc	ra,0xfffff
    80003c3a:	496080e7          	jalr	1174(ra) # 800030cc <bread>
    80003c3e:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c40:	3ff4f713          	andi	a4,s1,1023
    80003c44:	40ec87bb          	subw	a5,s9,a4
    80003c48:	413a86bb          	subw	a3,s5,s3
    80003c4c:	8d3e                	mv	s10,a5
    80003c4e:	2781                	sext.w	a5,a5
    80003c50:	0006861b          	sext.w	a2,a3
    80003c54:	f8f679e3          	bgeu	a2,a5,80003be6 <readi+0x4c>
    80003c58:	8d36                	mv	s10,a3
    80003c5a:	b771                	j	80003be6 <readi+0x4c>
      brelse(bp);
    80003c5c:	854a                	mv	a0,s2
    80003c5e:	fffff097          	auipc	ra,0xfffff
    80003c62:	59e080e7          	jalr	1438(ra) # 800031fc <brelse>
      tot = -1;
    80003c66:	59fd                	li	s3,-1
  }
  return tot;
    80003c68:	0009851b          	sext.w	a0,s3
}
    80003c6c:	70a6                	ld	ra,104(sp)
    80003c6e:	7406                	ld	s0,96(sp)
    80003c70:	64e6                	ld	s1,88(sp)
    80003c72:	6946                	ld	s2,80(sp)
    80003c74:	69a6                	ld	s3,72(sp)
    80003c76:	6a06                	ld	s4,64(sp)
    80003c78:	7ae2                	ld	s5,56(sp)
    80003c7a:	7b42                	ld	s6,48(sp)
    80003c7c:	7ba2                	ld	s7,40(sp)
    80003c7e:	7c02                	ld	s8,32(sp)
    80003c80:	6ce2                	ld	s9,24(sp)
    80003c82:	6d42                	ld	s10,16(sp)
    80003c84:	6da2                	ld	s11,8(sp)
    80003c86:	6165                	addi	sp,sp,112
    80003c88:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c8a:	89d6                	mv	s3,s5
    80003c8c:	bff1                	j	80003c68 <readi+0xce>
    return 0;
    80003c8e:	4501                	li	a0,0
}
    80003c90:	8082                	ret

0000000080003c92 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c92:	457c                	lw	a5,76(a0)
    80003c94:	10d7e863          	bltu	a5,a3,80003da4 <writei+0x112>
{
    80003c98:	7159                	addi	sp,sp,-112
    80003c9a:	f486                	sd	ra,104(sp)
    80003c9c:	f0a2                	sd	s0,96(sp)
    80003c9e:	eca6                	sd	s1,88(sp)
    80003ca0:	e8ca                	sd	s2,80(sp)
    80003ca2:	e4ce                	sd	s3,72(sp)
    80003ca4:	e0d2                	sd	s4,64(sp)
    80003ca6:	fc56                	sd	s5,56(sp)
    80003ca8:	f85a                	sd	s6,48(sp)
    80003caa:	f45e                	sd	s7,40(sp)
    80003cac:	f062                	sd	s8,32(sp)
    80003cae:	ec66                	sd	s9,24(sp)
    80003cb0:	e86a                	sd	s10,16(sp)
    80003cb2:	e46e                	sd	s11,8(sp)
    80003cb4:	1880                	addi	s0,sp,112
    80003cb6:	8aaa                	mv	s5,a0
    80003cb8:	8bae                	mv	s7,a1
    80003cba:	8a32                	mv	s4,a2
    80003cbc:	8936                	mv	s2,a3
    80003cbe:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003cc0:	00e687bb          	addw	a5,a3,a4
    80003cc4:	0ed7e263          	bltu	a5,a3,80003da8 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003cc8:	00043737          	lui	a4,0x43
    80003ccc:	0ef76063          	bltu	a4,a5,80003dac <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cd0:	0c0b0863          	beqz	s6,80003da0 <writei+0x10e>
    80003cd4:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cd6:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003cda:	5c7d                	li	s8,-1
    80003cdc:	a091                	j	80003d20 <writei+0x8e>
    80003cde:	020d1d93          	slli	s11,s10,0x20
    80003ce2:	020ddd93          	srli	s11,s11,0x20
    80003ce6:	05848513          	addi	a0,s1,88
    80003cea:	86ee                	mv	a3,s11
    80003cec:	8652                	mv	a2,s4
    80003cee:	85de                	mv	a1,s7
    80003cf0:	953a                	add	a0,a0,a4
    80003cf2:	fffff097          	auipc	ra,0xfffff
    80003cf6:	876080e7          	jalr	-1930(ra) # 80002568 <either_copyin>
    80003cfa:	07850263          	beq	a0,s8,80003d5e <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003cfe:	8526                	mv	a0,s1
    80003d00:	00000097          	auipc	ra,0x0
    80003d04:	780080e7          	jalr	1920(ra) # 80004480 <log_write>
    brelse(bp);
    80003d08:	8526                	mv	a0,s1
    80003d0a:	fffff097          	auipc	ra,0xfffff
    80003d0e:	4f2080e7          	jalr	1266(ra) # 800031fc <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d12:	013d09bb          	addw	s3,s10,s3
    80003d16:	012d093b          	addw	s2,s10,s2
    80003d1a:	9a6e                	add	s4,s4,s11
    80003d1c:	0569f663          	bgeu	s3,s6,80003d68 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003d20:	00a9559b          	srliw	a1,s2,0xa
    80003d24:	8556                	mv	a0,s5
    80003d26:	fffff097          	auipc	ra,0xfffff
    80003d2a:	7a0080e7          	jalr	1952(ra) # 800034c6 <bmap>
    80003d2e:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003d32:	c99d                	beqz	a1,80003d68 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003d34:	000aa503          	lw	a0,0(s5)
    80003d38:	fffff097          	auipc	ra,0xfffff
    80003d3c:	394080e7          	jalr	916(ra) # 800030cc <bread>
    80003d40:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d42:	3ff97713          	andi	a4,s2,1023
    80003d46:	40ec87bb          	subw	a5,s9,a4
    80003d4a:	413b06bb          	subw	a3,s6,s3
    80003d4e:	8d3e                	mv	s10,a5
    80003d50:	2781                	sext.w	a5,a5
    80003d52:	0006861b          	sext.w	a2,a3
    80003d56:	f8f674e3          	bgeu	a2,a5,80003cde <writei+0x4c>
    80003d5a:	8d36                	mv	s10,a3
    80003d5c:	b749                	j	80003cde <writei+0x4c>
      brelse(bp);
    80003d5e:	8526                	mv	a0,s1
    80003d60:	fffff097          	auipc	ra,0xfffff
    80003d64:	49c080e7          	jalr	1180(ra) # 800031fc <brelse>
  }

  if(off > ip->size)
    80003d68:	04caa783          	lw	a5,76(s5)
    80003d6c:	0127f463          	bgeu	a5,s2,80003d74 <writei+0xe2>
    ip->size = off;
    80003d70:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003d74:	8556                	mv	a0,s5
    80003d76:	00000097          	auipc	ra,0x0
    80003d7a:	aa6080e7          	jalr	-1370(ra) # 8000381c <iupdate>

  return tot;
    80003d7e:	0009851b          	sext.w	a0,s3
}
    80003d82:	70a6                	ld	ra,104(sp)
    80003d84:	7406                	ld	s0,96(sp)
    80003d86:	64e6                	ld	s1,88(sp)
    80003d88:	6946                	ld	s2,80(sp)
    80003d8a:	69a6                	ld	s3,72(sp)
    80003d8c:	6a06                	ld	s4,64(sp)
    80003d8e:	7ae2                	ld	s5,56(sp)
    80003d90:	7b42                	ld	s6,48(sp)
    80003d92:	7ba2                	ld	s7,40(sp)
    80003d94:	7c02                	ld	s8,32(sp)
    80003d96:	6ce2                	ld	s9,24(sp)
    80003d98:	6d42                	ld	s10,16(sp)
    80003d9a:	6da2                	ld	s11,8(sp)
    80003d9c:	6165                	addi	sp,sp,112
    80003d9e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003da0:	89da                	mv	s3,s6
    80003da2:	bfc9                	j	80003d74 <writei+0xe2>
    return -1;
    80003da4:	557d                	li	a0,-1
}
    80003da6:	8082                	ret
    return -1;
    80003da8:	557d                	li	a0,-1
    80003daa:	bfe1                	j	80003d82 <writei+0xf0>
    return -1;
    80003dac:	557d                	li	a0,-1
    80003dae:	bfd1                	j	80003d82 <writei+0xf0>

0000000080003db0 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003db0:	1141                	addi	sp,sp,-16
    80003db2:	e406                	sd	ra,8(sp)
    80003db4:	e022                	sd	s0,0(sp)
    80003db6:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003db8:	4639                	li	a2,14
    80003dba:	ffffd097          	auipc	ra,0xffffd
    80003dbe:	004080e7          	jalr	4(ra) # 80000dbe <strncmp>
}
    80003dc2:	60a2                	ld	ra,8(sp)
    80003dc4:	6402                	ld	s0,0(sp)
    80003dc6:	0141                	addi	sp,sp,16
    80003dc8:	8082                	ret

0000000080003dca <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003dca:	7139                	addi	sp,sp,-64
    80003dcc:	fc06                	sd	ra,56(sp)
    80003dce:	f822                	sd	s0,48(sp)
    80003dd0:	f426                	sd	s1,40(sp)
    80003dd2:	f04a                	sd	s2,32(sp)
    80003dd4:	ec4e                	sd	s3,24(sp)
    80003dd6:	e852                	sd	s4,16(sp)
    80003dd8:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003dda:	04451703          	lh	a4,68(a0)
    80003dde:	4785                	li	a5,1
    80003de0:	00f71a63          	bne	a4,a5,80003df4 <dirlookup+0x2a>
    80003de4:	892a                	mv	s2,a0
    80003de6:	89ae                	mv	s3,a1
    80003de8:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dea:	457c                	lw	a5,76(a0)
    80003dec:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003dee:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003df0:	e79d                	bnez	a5,80003e1e <dirlookup+0x54>
    80003df2:	a8a5                	j	80003e6a <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003df4:	00005517          	auipc	a0,0x5
    80003df8:	9ec50513          	addi	a0,a0,-1556 # 800087e0 <syscalls+0x1e8>
    80003dfc:	ffffc097          	auipc	ra,0xffffc
    80003e00:	748080e7          	jalr	1864(ra) # 80000544 <panic>
      panic("dirlookup read");
    80003e04:	00005517          	auipc	a0,0x5
    80003e08:	9f450513          	addi	a0,a0,-1548 # 800087f8 <syscalls+0x200>
    80003e0c:	ffffc097          	auipc	ra,0xffffc
    80003e10:	738080e7          	jalr	1848(ra) # 80000544 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e14:	24c1                	addiw	s1,s1,16
    80003e16:	04c92783          	lw	a5,76(s2)
    80003e1a:	04f4f763          	bgeu	s1,a5,80003e68 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e1e:	4741                	li	a4,16
    80003e20:	86a6                	mv	a3,s1
    80003e22:	fc040613          	addi	a2,s0,-64
    80003e26:	4581                	li	a1,0
    80003e28:	854a                	mv	a0,s2
    80003e2a:	00000097          	auipc	ra,0x0
    80003e2e:	d70080e7          	jalr	-656(ra) # 80003b9a <readi>
    80003e32:	47c1                	li	a5,16
    80003e34:	fcf518e3          	bne	a0,a5,80003e04 <dirlookup+0x3a>
    if(de.inum == 0)
    80003e38:	fc045783          	lhu	a5,-64(s0)
    80003e3c:	dfe1                	beqz	a5,80003e14 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003e3e:	fc240593          	addi	a1,s0,-62
    80003e42:	854e                	mv	a0,s3
    80003e44:	00000097          	auipc	ra,0x0
    80003e48:	f6c080e7          	jalr	-148(ra) # 80003db0 <namecmp>
    80003e4c:	f561                	bnez	a0,80003e14 <dirlookup+0x4a>
      if(poff)
    80003e4e:	000a0463          	beqz	s4,80003e56 <dirlookup+0x8c>
        *poff = off;
    80003e52:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003e56:	fc045583          	lhu	a1,-64(s0)
    80003e5a:	00092503          	lw	a0,0(s2)
    80003e5e:	fffff097          	auipc	ra,0xfffff
    80003e62:	750080e7          	jalr	1872(ra) # 800035ae <iget>
    80003e66:	a011                	j	80003e6a <dirlookup+0xa0>
  return 0;
    80003e68:	4501                	li	a0,0
}
    80003e6a:	70e2                	ld	ra,56(sp)
    80003e6c:	7442                	ld	s0,48(sp)
    80003e6e:	74a2                	ld	s1,40(sp)
    80003e70:	7902                	ld	s2,32(sp)
    80003e72:	69e2                	ld	s3,24(sp)
    80003e74:	6a42                	ld	s4,16(sp)
    80003e76:	6121                	addi	sp,sp,64
    80003e78:	8082                	ret

0000000080003e7a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003e7a:	711d                	addi	sp,sp,-96
    80003e7c:	ec86                	sd	ra,88(sp)
    80003e7e:	e8a2                	sd	s0,80(sp)
    80003e80:	e4a6                	sd	s1,72(sp)
    80003e82:	e0ca                	sd	s2,64(sp)
    80003e84:	fc4e                	sd	s3,56(sp)
    80003e86:	f852                	sd	s4,48(sp)
    80003e88:	f456                	sd	s5,40(sp)
    80003e8a:	f05a                	sd	s6,32(sp)
    80003e8c:	ec5e                	sd	s7,24(sp)
    80003e8e:	e862                	sd	s8,16(sp)
    80003e90:	e466                	sd	s9,8(sp)
    80003e92:	1080                	addi	s0,sp,96
    80003e94:	84aa                	mv	s1,a0
    80003e96:	8b2e                	mv	s6,a1
    80003e98:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003e9a:	00054703          	lbu	a4,0(a0)
    80003e9e:	02f00793          	li	a5,47
    80003ea2:	02f70363          	beq	a4,a5,80003ec8 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003ea6:	ffffe097          	auipc	ra,0xffffe
    80003eaa:	b20080e7          	jalr	-1248(ra) # 800019c6 <myproc>
    80003eae:	15053503          	ld	a0,336(a0)
    80003eb2:	00000097          	auipc	ra,0x0
    80003eb6:	9f6080e7          	jalr	-1546(ra) # 800038a8 <idup>
    80003eba:	89aa                	mv	s3,a0
  while(*path == '/')
    80003ebc:	02f00913          	li	s2,47
  len = path - s;
    80003ec0:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003ec2:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003ec4:	4c05                	li	s8,1
    80003ec6:	a865                	j	80003f7e <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003ec8:	4585                	li	a1,1
    80003eca:	4505                	li	a0,1
    80003ecc:	fffff097          	auipc	ra,0xfffff
    80003ed0:	6e2080e7          	jalr	1762(ra) # 800035ae <iget>
    80003ed4:	89aa                	mv	s3,a0
    80003ed6:	b7dd                	j	80003ebc <namex+0x42>
      iunlockput(ip);
    80003ed8:	854e                	mv	a0,s3
    80003eda:	00000097          	auipc	ra,0x0
    80003ede:	c6e080e7          	jalr	-914(ra) # 80003b48 <iunlockput>
      return 0;
    80003ee2:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003ee4:	854e                	mv	a0,s3
    80003ee6:	60e6                	ld	ra,88(sp)
    80003ee8:	6446                	ld	s0,80(sp)
    80003eea:	64a6                	ld	s1,72(sp)
    80003eec:	6906                	ld	s2,64(sp)
    80003eee:	79e2                	ld	s3,56(sp)
    80003ef0:	7a42                	ld	s4,48(sp)
    80003ef2:	7aa2                	ld	s5,40(sp)
    80003ef4:	7b02                	ld	s6,32(sp)
    80003ef6:	6be2                	ld	s7,24(sp)
    80003ef8:	6c42                	ld	s8,16(sp)
    80003efa:	6ca2                	ld	s9,8(sp)
    80003efc:	6125                	addi	sp,sp,96
    80003efe:	8082                	ret
      iunlock(ip);
    80003f00:	854e                	mv	a0,s3
    80003f02:	00000097          	auipc	ra,0x0
    80003f06:	aa6080e7          	jalr	-1370(ra) # 800039a8 <iunlock>
      return ip;
    80003f0a:	bfe9                	j	80003ee4 <namex+0x6a>
      iunlockput(ip);
    80003f0c:	854e                	mv	a0,s3
    80003f0e:	00000097          	auipc	ra,0x0
    80003f12:	c3a080e7          	jalr	-966(ra) # 80003b48 <iunlockput>
      return 0;
    80003f16:	89d2                	mv	s3,s4
    80003f18:	b7f1                	j	80003ee4 <namex+0x6a>
  len = path - s;
    80003f1a:	40b48633          	sub	a2,s1,a1
    80003f1e:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003f22:	094cd463          	bge	s9,s4,80003faa <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003f26:	4639                	li	a2,14
    80003f28:	8556                	mv	a0,s5
    80003f2a:	ffffd097          	auipc	ra,0xffffd
    80003f2e:	e1c080e7          	jalr	-484(ra) # 80000d46 <memmove>
  while(*path == '/')
    80003f32:	0004c783          	lbu	a5,0(s1)
    80003f36:	01279763          	bne	a5,s2,80003f44 <namex+0xca>
    path++;
    80003f3a:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f3c:	0004c783          	lbu	a5,0(s1)
    80003f40:	ff278de3          	beq	a5,s2,80003f3a <namex+0xc0>
    ilock(ip);
    80003f44:	854e                	mv	a0,s3
    80003f46:	00000097          	auipc	ra,0x0
    80003f4a:	9a0080e7          	jalr	-1632(ra) # 800038e6 <ilock>
    if(ip->type != T_DIR){
    80003f4e:	04499783          	lh	a5,68(s3)
    80003f52:	f98793e3          	bne	a5,s8,80003ed8 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003f56:	000b0563          	beqz	s6,80003f60 <namex+0xe6>
    80003f5a:	0004c783          	lbu	a5,0(s1)
    80003f5e:	d3cd                	beqz	a5,80003f00 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003f60:	865e                	mv	a2,s7
    80003f62:	85d6                	mv	a1,s5
    80003f64:	854e                	mv	a0,s3
    80003f66:	00000097          	auipc	ra,0x0
    80003f6a:	e64080e7          	jalr	-412(ra) # 80003dca <dirlookup>
    80003f6e:	8a2a                	mv	s4,a0
    80003f70:	dd51                	beqz	a0,80003f0c <namex+0x92>
    iunlockput(ip);
    80003f72:	854e                	mv	a0,s3
    80003f74:	00000097          	auipc	ra,0x0
    80003f78:	bd4080e7          	jalr	-1068(ra) # 80003b48 <iunlockput>
    ip = next;
    80003f7c:	89d2                	mv	s3,s4
  while(*path == '/')
    80003f7e:	0004c783          	lbu	a5,0(s1)
    80003f82:	05279763          	bne	a5,s2,80003fd0 <namex+0x156>
    path++;
    80003f86:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f88:	0004c783          	lbu	a5,0(s1)
    80003f8c:	ff278de3          	beq	a5,s2,80003f86 <namex+0x10c>
  if(*path == 0)
    80003f90:	c79d                	beqz	a5,80003fbe <namex+0x144>
    path++;
    80003f92:	85a6                	mv	a1,s1
  len = path - s;
    80003f94:	8a5e                	mv	s4,s7
    80003f96:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003f98:	01278963          	beq	a5,s2,80003faa <namex+0x130>
    80003f9c:	dfbd                	beqz	a5,80003f1a <namex+0xa0>
    path++;
    80003f9e:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003fa0:	0004c783          	lbu	a5,0(s1)
    80003fa4:	ff279ce3          	bne	a5,s2,80003f9c <namex+0x122>
    80003fa8:	bf8d                	j	80003f1a <namex+0xa0>
    memmove(name, s, len);
    80003faa:	2601                	sext.w	a2,a2
    80003fac:	8556                	mv	a0,s5
    80003fae:	ffffd097          	auipc	ra,0xffffd
    80003fb2:	d98080e7          	jalr	-616(ra) # 80000d46 <memmove>
    name[len] = 0;
    80003fb6:	9a56                	add	s4,s4,s5
    80003fb8:	000a0023          	sb	zero,0(s4)
    80003fbc:	bf9d                	j	80003f32 <namex+0xb8>
  if(nameiparent){
    80003fbe:	f20b03e3          	beqz	s6,80003ee4 <namex+0x6a>
    iput(ip);
    80003fc2:	854e                	mv	a0,s3
    80003fc4:	00000097          	auipc	ra,0x0
    80003fc8:	adc080e7          	jalr	-1316(ra) # 80003aa0 <iput>
    return 0;
    80003fcc:	4981                	li	s3,0
    80003fce:	bf19                	j	80003ee4 <namex+0x6a>
  if(*path == 0)
    80003fd0:	d7fd                	beqz	a5,80003fbe <namex+0x144>
  while(*path != '/' && *path != 0)
    80003fd2:	0004c783          	lbu	a5,0(s1)
    80003fd6:	85a6                	mv	a1,s1
    80003fd8:	b7d1                	j	80003f9c <namex+0x122>

0000000080003fda <dirlink>:
{
    80003fda:	7139                	addi	sp,sp,-64
    80003fdc:	fc06                	sd	ra,56(sp)
    80003fde:	f822                	sd	s0,48(sp)
    80003fe0:	f426                	sd	s1,40(sp)
    80003fe2:	f04a                	sd	s2,32(sp)
    80003fe4:	ec4e                	sd	s3,24(sp)
    80003fe6:	e852                	sd	s4,16(sp)
    80003fe8:	0080                	addi	s0,sp,64
    80003fea:	892a                	mv	s2,a0
    80003fec:	8a2e                	mv	s4,a1
    80003fee:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003ff0:	4601                	li	a2,0
    80003ff2:	00000097          	auipc	ra,0x0
    80003ff6:	dd8080e7          	jalr	-552(ra) # 80003dca <dirlookup>
    80003ffa:	e93d                	bnez	a0,80004070 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ffc:	04c92483          	lw	s1,76(s2)
    80004000:	c49d                	beqz	s1,8000402e <dirlink+0x54>
    80004002:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004004:	4741                	li	a4,16
    80004006:	86a6                	mv	a3,s1
    80004008:	fc040613          	addi	a2,s0,-64
    8000400c:	4581                	li	a1,0
    8000400e:	854a                	mv	a0,s2
    80004010:	00000097          	auipc	ra,0x0
    80004014:	b8a080e7          	jalr	-1142(ra) # 80003b9a <readi>
    80004018:	47c1                	li	a5,16
    8000401a:	06f51163          	bne	a0,a5,8000407c <dirlink+0xa2>
    if(de.inum == 0)
    8000401e:	fc045783          	lhu	a5,-64(s0)
    80004022:	c791                	beqz	a5,8000402e <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004024:	24c1                	addiw	s1,s1,16
    80004026:	04c92783          	lw	a5,76(s2)
    8000402a:	fcf4ede3          	bltu	s1,a5,80004004 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000402e:	4639                	li	a2,14
    80004030:	85d2                	mv	a1,s4
    80004032:	fc240513          	addi	a0,s0,-62
    80004036:	ffffd097          	auipc	ra,0xffffd
    8000403a:	dc4080e7          	jalr	-572(ra) # 80000dfa <strncpy>
  de.inum = inum;
    8000403e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004042:	4741                	li	a4,16
    80004044:	86a6                	mv	a3,s1
    80004046:	fc040613          	addi	a2,s0,-64
    8000404a:	4581                	li	a1,0
    8000404c:	854a                	mv	a0,s2
    8000404e:	00000097          	auipc	ra,0x0
    80004052:	c44080e7          	jalr	-956(ra) # 80003c92 <writei>
    80004056:	1541                	addi	a0,a0,-16
    80004058:	00a03533          	snez	a0,a0
    8000405c:	40a00533          	neg	a0,a0
}
    80004060:	70e2                	ld	ra,56(sp)
    80004062:	7442                	ld	s0,48(sp)
    80004064:	74a2                	ld	s1,40(sp)
    80004066:	7902                	ld	s2,32(sp)
    80004068:	69e2                	ld	s3,24(sp)
    8000406a:	6a42                	ld	s4,16(sp)
    8000406c:	6121                	addi	sp,sp,64
    8000406e:	8082                	ret
    iput(ip);
    80004070:	00000097          	auipc	ra,0x0
    80004074:	a30080e7          	jalr	-1488(ra) # 80003aa0 <iput>
    return -1;
    80004078:	557d                	li	a0,-1
    8000407a:	b7dd                	j	80004060 <dirlink+0x86>
      panic("dirlink read");
    8000407c:	00004517          	auipc	a0,0x4
    80004080:	78c50513          	addi	a0,a0,1932 # 80008808 <syscalls+0x210>
    80004084:	ffffc097          	auipc	ra,0xffffc
    80004088:	4c0080e7          	jalr	1216(ra) # 80000544 <panic>

000000008000408c <namei>:

struct inode*
namei(char *path)
{
    8000408c:	1101                	addi	sp,sp,-32
    8000408e:	ec06                	sd	ra,24(sp)
    80004090:	e822                	sd	s0,16(sp)
    80004092:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004094:	fe040613          	addi	a2,s0,-32
    80004098:	4581                	li	a1,0
    8000409a:	00000097          	auipc	ra,0x0
    8000409e:	de0080e7          	jalr	-544(ra) # 80003e7a <namex>
}
    800040a2:	60e2                	ld	ra,24(sp)
    800040a4:	6442                	ld	s0,16(sp)
    800040a6:	6105                	addi	sp,sp,32
    800040a8:	8082                	ret

00000000800040aa <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800040aa:	1141                	addi	sp,sp,-16
    800040ac:	e406                	sd	ra,8(sp)
    800040ae:	e022                	sd	s0,0(sp)
    800040b0:	0800                	addi	s0,sp,16
    800040b2:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800040b4:	4585                	li	a1,1
    800040b6:	00000097          	auipc	ra,0x0
    800040ba:	dc4080e7          	jalr	-572(ra) # 80003e7a <namex>
}
    800040be:	60a2                	ld	ra,8(sp)
    800040c0:	6402                	ld	s0,0(sp)
    800040c2:	0141                	addi	sp,sp,16
    800040c4:	8082                	ret

00000000800040c6 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800040c6:	1101                	addi	sp,sp,-32
    800040c8:	ec06                	sd	ra,24(sp)
    800040ca:	e822                	sd	s0,16(sp)
    800040cc:	e426                	sd	s1,8(sp)
    800040ce:	e04a                	sd	s2,0(sp)
    800040d0:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800040d2:	00025917          	auipc	s2,0x25
    800040d6:	fd690913          	addi	s2,s2,-42 # 800290a8 <log>
    800040da:	01892583          	lw	a1,24(s2)
    800040de:	02892503          	lw	a0,40(s2)
    800040e2:	fffff097          	auipc	ra,0xfffff
    800040e6:	fea080e7          	jalr	-22(ra) # 800030cc <bread>
    800040ea:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800040ec:	02c92683          	lw	a3,44(s2)
    800040f0:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800040f2:	02d05763          	blez	a3,80004120 <write_head+0x5a>
    800040f6:	00025797          	auipc	a5,0x25
    800040fa:	fe278793          	addi	a5,a5,-30 # 800290d8 <log+0x30>
    800040fe:	05c50713          	addi	a4,a0,92
    80004102:	36fd                	addiw	a3,a3,-1
    80004104:	1682                	slli	a3,a3,0x20
    80004106:	9281                	srli	a3,a3,0x20
    80004108:	068a                	slli	a3,a3,0x2
    8000410a:	00025617          	auipc	a2,0x25
    8000410e:	fd260613          	addi	a2,a2,-46 # 800290dc <log+0x34>
    80004112:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004114:	4390                	lw	a2,0(a5)
    80004116:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004118:	0791                	addi	a5,a5,4
    8000411a:	0711                	addi	a4,a4,4
    8000411c:	fed79ce3          	bne	a5,a3,80004114 <write_head+0x4e>
  }
  bwrite(buf);
    80004120:	8526                	mv	a0,s1
    80004122:	fffff097          	auipc	ra,0xfffff
    80004126:	09c080e7          	jalr	156(ra) # 800031be <bwrite>
  brelse(buf);
    8000412a:	8526                	mv	a0,s1
    8000412c:	fffff097          	auipc	ra,0xfffff
    80004130:	0d0080e7          	jalr	208(ra) # 800031fc <brelse>
}
    80004134:	60e2                	ld	ra,24(sp)
    80004136:	6442                	ld	s0,16(sp)
    80004138:	64a2                	ld	s1,8(sp)
    8000413a:	6902                	ld	s2,0(sp)
    8000413c:	6105                	addi	sp,sp,32
    8000413e:	8082                	ret

0000000080004140 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004140:	00025797          	auipc	a5,0x25
    80004144:	f947a783          	lw	a5,-108(a5) # 800290d4 <log+0x2c>
    80004148:	0af05d63          	blez	a5,80004202 <install_trans+0xc2>
{
    8000414c:	7139                	addi	sp,sp,-64
    8000414e:	fc06                	sd	ra,56(sp)
    80004150:	f822                	sd	s0,48(sp)
    80004152:	f426                	sd	s1,40(sp)
    80004154:	f04a                	sd	s2,32(sp)
    80004156:	ec4e                	sd	s3,24(sp)
    80004158:	e852                	sd	s4,16(sp)
    8000415a:	e456                	sd	s5,8(sp)
    8000415c:	e05a                	sd	s6,0(sp)
    8000415e:	0080                	addi	s0,sp,64
    80004160:	8b2a                	mv	s6,a0
    80004162:	00025a97          	auipc	s5,0x25
    80004166:	f76a8a93          	addi	s5,s5,-138 # 800290d8 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000416a:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000416c:	00025997          	auipc	s3,0x25
    80004170:	f3c98993          	addi	s3,s3,-196 # 800290a8 <log>
    80004174:	a035                	j	800041a0 <install_trans+0x60>
      bunpin(dbuf);
    80004176:	8526                	mv	a0,s1
    80004178:	fffff097          	auipc	ra,0xfffff
    8000417c:	15e080e7          	jalr	350(ra) # 800032d6 <bunpin>
    brelse(lbuf);
    80004180:	854a                	mv	a0,s2
    80004182:	fffff097          	auipc	ra,0xfffff
    80004186:	07a080e7          	jalr	122(ra) # 800031fc <brelse>
    brelse(dbuf);
    8000418a:	8526                	mv	a0,s1
    8000418c:	fffff097          	auipc	ra,0xfffff
    80004190:	070080e7          	jalr	112(ra) # 800031fc <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004194:	2a05                	addiw	s4,s4,1
    80004196:	0a91                	addi	s5,s5,4
    80004198:	02c9a783          	lw	a5,44(s3)
    8000419c:	04fa5963          	bge	s4,a5,800041ee <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800041a0:	0189a583          	lw	a1,24(s3)
    800041a4:	014585bb          	addw	a1,a1,s4
    800041a8:	2585                	addiw	a1,a1,1
    800041aa:	0289a503          	lw	a0,40(s3)
    800041ae:	fffff097          	auipc	ra,0xfffff
    800041b2:	f1e080e7          	jalr	-226(ra) # 800030cc <bread>
    800041b6:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800041b8:	000aa583          	lw	a1,0(s5)
    800041bc:	0289a503          	lw	a0,40(s3)
    800041c0:	fffff097          	auipc	ra,0xfffff
    800041c4:	f0c080e7          	jalr	-244(ra) # 800030cc <bread>
    800041c8:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800041ca:	40000613          	li	a2,1024
    800041ce:	05890593          	addi	a1,s2,88
    800041d2:	05850513          	addi	a0,a0,88
    800041d6:	ffffd097          	auipc	ra,0xffffd
    800041da:	b70080e7          	jalr	-1168(ra) # 80000d46 <memmove>
    bwrite(dbuf);  // write dst to disk
    800041de:	8526                	mv	a0,s1
    800041e0:	fffff097          	auipc	ra,0xfffff
    800041e4:	fde080e7          	jalr	-34(ra) # 800031be <bwrite>
    if(recovering == 0)
    800041e8:	f80b1ce3          	bnez	s6,80004180 <install_trans+0x40>
    800041ec:	b769                	j	80004176 <install_trans+0x36>
}
    800041ee:	70e2                	ld	ra,56(sp)
    800041f0:	7442                	ld	s0,48(sp)
    800041f2:	74a2                	ld	s1,40(sp)
    800041f4:	7902                	ld	s2,32(sp)
    800041f6:	69e2                	ld	s3,24(sp)
    800041f8:	6a42                	ld	s4,16(sp)
    800041fa:	6aa2                	ld	s5,8(sp)
    800041fc:	6b02                	ld	s6,0(sp)
    800041fe:	6121                	addi	sp,sp,64
    80004200:	8082                	ret
    80004202:	8082                	ret

0000000080004204 <initlog>:
{
    80004204:	7179                	addi	sp,sp,-48
    80004206:	f406                	sd	ra,40(sp)
    80004208:	f022                	sd	s0,32(sp)
    8000420a:	ec26                	sd	s1,24(sp)
    8000420c:	e84a                	sd	s2,16(sp)
    8000420e:	e44e                	sd	s3,8(sp)
    80004210:	1800                	addi	s0,sp,48
    80004212:	892a                	mv	s2,a0
    80004214:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004216:	00025497          	auipc	s1,0x25
    8000421a:	e9248493          	addi	s1,s1,-366 # 800290a8 <log>
    8000421e:	00004597          	auipc	a1,0x4
    80004222:	5fa58593          	addi	a1,a1,1530 # 80008818 <syscalls+0x220>
    80004226:	8526                	mv	a0,s1
    80004228:	ffffd097          	auipc	ra,0xffffd
    8000422c:	932080e7          	jalr	-1742(ra) # 80000b5a <initlock>
  log.start = sb->logstart;
    80004230:	0149a583          	lw	a1,20(s3)
    80004234:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004236:	0109a783          	lw	a5,16(s3)
    8000423a:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000423c:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004240:	854a                	mv	a0,s2
    80004242:	fffff097          	auipc	ra,0xfffff
    80004246:	e8a080e7          	jalr	-374(ra) # 800030cc <bread>
  log.lh.n = lh->n;
    8000424a:	4d3c                	lw	a5,88(a0)
    8000424c:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000424e:	02f05563          	blez	a5,80004278 <initlog+0x74>
    80004252:	05c50713          	addi	a4,a0,92
    80004256:	00025697          	auipc	a3,0x25
    8000425a:	e8268693          	addi	a3,a3,-382 # 800290d8 <log+0x30>
    8000425e:	37fd                	addiw	a5,a5,-1
    80004260:	1782                	slli	a5,a5,0x20
    80004262:	9381                	srli	a5,a5,0x20
    80004264:	078a                	slli	a5,a5,0x2
    80004266:	06050613          	addi	a2,a0,96
    8000426a:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000426c:	4310                	lw	a2,0(a4)
    8000426e:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004270:	0711                	addi	a4,a4,4
    80004272:	0691                	addi	a3,a3,4
    80004274:	fef71ce3          	bne	a4,a5,8000426c <initlog+0x68>
  brelse(buf);
    80004278:	fffff097          	auipc	ra,0xfffff
    8000427c:	f84080e7          	jalr	-124(ra) # 800031fc <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004280:	4505                	li	a0,1
    80004282:	00000097          	auipc	ra,0x0
    80004286:	ebe080e7          	jalr	-322(ra) # 80004140 <install_trans>
  log.lh.n = 0;
    8000428a:	00025797          	auipc	a5,0x25
    8000428e:	e407a523          	sw	zero,-438(a5) # 800290d4 <log+0x2c>
  write_head(); // clear the log
    80004292:	00000097          	auipc	ra,0x0
    80004296:	e34080e7          	jalr	-460(ra) # 800040c6 <write_head>
}
    8000429a:	70a2                	ld	ra,40(sp)
    8000429c:	7402                	ld	s0,32(sp)
    8000429e:	64e2                	ld	s1,24(sp)
    800042a0:	6942                	ld	s2,16(sp)
    800042a2:	69a2                	ld	s3,8(sp)
    800042a4:	6145                	addi	sp,sp,48
    800042a6:	8082                	ret

00000000800042a8 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800042a8:	1101                	addi	sp,sp,-32
    800042aa:	ec06                	sd	ra,24(sp)
    800042ac:	e822                	sd	s0,16(sp)
    800042ae:	e426                	sd	s1,8(sp)
    800042b0:	e04a                	sd	s2,0(sp)
    800042b2:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800042b4:	00025517          	auipc	a0,0x25
    800042b8:	df450513          	addi	a0,a0,-524 # 800290a8 <log>
    800042bc:	ffffd097          	auipc	ra,0xffffd
    800042c0:	92e080e7          	jalr	-1746(ra) # 80000bea <acquire>
  while(1){
    if(log.committing){
    800042c4:	00025497          	auipc	s1,0x25
    800042c8:	de448493          	addi	s1,s1,-540 # 800290a8 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042cc:	4979                	li	s2,30
    800042ce:	a039                	j	800042dc <begin_op+0x34>
      sleep(&log, &log.lock);
    800042d0:	85a6                	mv	a1,s1
    800042d2:	8526                	mv	a0,s1
    800042d4:	ffffe097          	auipc	ra,0xffffe
    800042d8:	e36080e7          	jalr	-458(ra) # 8000210a <sleep>
    if(log.committing){
    800042dc:	50dc                	lw	a5,36(s1)
    800042de:	fbed                	bnez	a5,800042d0 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042e0:	509c                	lw	a5,32(s1)
    800042e2:	0017871b          	addiw	a4,a5,1
    800042e6:	0007069b          	sext.w	a3,a4
    800042ea:	0027179b          	slliw	a5,a4,0x2
    800042ee:	9fb9                	addw	a5,a5,a4
    800042f0:	0017979b          	slliw	a5,a5,0x1
    800042f4:	54d8                	lw	a4,44(s1)
    800042f6:	9fb9                	addw	a5,a5,a4
    800042f8:	00f95963          	bge	s2,a5,8000430a <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800042fc:	85a6                	mv	a1,s1
    800042fe:	8526                	mv	a0,s1
    80004300:	ffffe097          	auipc	ra,0xffffe
    80004304:	e0a080e7          	jalr	-502(ra) # 8000210a <sleep>
    80004308:	bfd1                	j	800042dc <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000430a:	00025517          	auipc	a0,0x25
    8000430e:	d9e50513          	addi	a0,a0,-610 # 800290a8 <log>
    80004312:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004314:	ffffd097          	auipc	ra,0xffffd
    80004318:	98a080e7          	jalr	-1654(ra) # 80000c9e <release>
      break;
    }
  }
}
    8000431c:	60e2                	ld	ra,24(sp)
    8000431e:	6442                	ld	s0,16(sp)
    80004320:	64a2                	ld	s1,8(sp)
    80004322:	6902                	ld	s2,0(sp)
    80004324:	6105                	addi	sp,sp,32
    80004326:	8082                	ret

0000000080004328 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004328:	7139                	addi	sp,sp,-64
    8000432a:	fc06                	sd	ra,56(sp)
    8000432c:	f822                	sd	s0,48(sp)
    8000432e:	f426                	sd	s1,40(sp)
    80004330:	f04a                	sd	s2,32(sp)
    80004332:	ec4e                	sd	s3,24(sp)
    80004334:	e852                	sd	s4,16(sp)
    80004336:	e456                	sd	s5,8(sp)
    80004338:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000433a:	00025497          	auipc	s1,0x25
    8000433e:	d6e48493          	addi	s1,s1,-658 # 800290a8 <log>
    80004342:	8526                	mv	a0,s1
    80004344:	ffffd097          	auipc	ra,0xffffd
    80004348:	8a6080e7          	jalr	-1882(ra) # 80000bea <acquire>
  log.outstanding -= 1;
    8000434c:	509c                	lw	a5,32(s1)
    8000434e:	37fd                	addiw	a5,a5,-1
    80004350:	0007891b          	sext.w	s2,a5
    80004354:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004356:	50dc                	lw	a5,36(s1)
    80004358:	efb9                	bnez	a5,800043b6 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000435a:	06091663          	bnez	s2,800043c6 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    8000435e:	00025497          	auipc	s1,0x25
    80004362:	d4a48493          	addi	s1,s1,-694 # 800290a8 <log>
    80004366:	4785                	li	a5,1
    80004368:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000436a:	8526                	mv	a0,s1
    8000436c:	ffffd097          	auipc	ra,0xffffd
    80004370:	932080e7          	jalr	-1742(ra) # 80000c9e <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004374:	54dc                	lw	a5,44(s1)
    80004376:	06f04763          	bgtz	a5,800043e4 <end_op+0xbc>
    acquire(&log.lock);
    8000437a:	00025497          	auipc	s1,0x25
    8000437e:	d2e48493          	addi	s1,s1,-722 # 800290a8 <log>
    80004382:	8526                	mv	a0,s1
    80004384:	ffffd097          	auipc	ra,0xffffd
    80004388:	866080e7          	jalr	-1946(ra) # 80000bea <acquire>
    log.committing = 0;
    8000438c:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004390:	8526                	mv	a0,s1
    80004392:	ffffe097          	auipc	ra,0xffffe
    80004396:	ddc080e7          	jalr	-548(ra) # 8000216e <wakeup>
    release(&log.lock);
    8000439a:	8526                	mv	a0,s1
    8000439c:	ffffd097          	auipc	ra,0xffffd
    800043a0:	902080e7          	jalr	-1790(ra) # 80000c9e <release>
}
    800043a4:	70e2                	ld	ra,56(sp)
    800043a6:	7442                	ld	s0,48(sp)
    800043a8:	74a2                	ld	s1,40(sp)
    800043aa:	7902                	ld	s2,32(sp)
    800043ac:	69e2                	ld	s3,24(sp)
    800043ae:	6a42                	ld	s4,16(sp)
    800043b0:	6aa2                	ld	s5,8(sp)
    800043b2:	6121                	addi	sp,sp,64
    800043b4:	8082                	ret
    panic("log.committing");
    800043b6:	00004517          	auipc	a0,0x4
    800043ba:	46a50513          	addi	a0,a0,1130 # 80008820 <syscalls+0x228>
    800043be:	ffffc097          	auipc	ra,0xffffc
    800043c2:	186080e7          	jalr	390(ra) # 80000544 <panic>
    wakeup(&log);
    800043c6:	00025497          	auipc	s1,0x25
    800043ca:	ce248493          	addi	s1,s1,-798 # 800290a8 <log>
    800043ce:	8526                	mv	a0,s1
    800043d0:	ffffe097          	auipc	ra,0xffffe
    800043d4:	d9e080e7          	jalr	-610(ra) # 8000216e <wakeup>
  release(&log.lock);
    800043d8:	8526                	mv	a0,s1
    800043da:	ffffd097          	auipc	ra,0xffffd
    800043de:	8c4080e7          	jalr	-1852(ra) # 80000c9e <release>
  if(do_commit){
    800043e2:	b7c9                	j	800043a4 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043e4:	00025a97          	auipc	s5,0x25
    800043e8:	cf4a8a93          	addi	s5,s5,-780 # 800290d8 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800043ec:	00025a17          	auipc	s4,0x25
    800043f0:	cbca0a13          	addi	s4,s4,-836 # 800290a8 <log>
    800043f4:	018a2583          	lw	a1,24(s4)
    800043f8:	012585bb          	addw	a1,a1,s2
    800043fc:	2585                	addiw	a1,a1,1
    800043fe:	028a2503          	lw	a0,40(s4)
    80004402:	fffff097          	auipc	ra,0xfffff
    80004406:	cca080e7          	jalr	-822(ra) # 800030cc <bread>
    8000440a:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000440c:	000aa583          	lw	a1,0(s5)
    80004410:	028a2503          	lw	a0,40(s4)
    80004414:	fffff097          	auipc	ra,0xfffff
    80004418:	cb8080e7          	jalr	-840(ra) # 800030cc <bread>
    8000441c:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000441e:	40000613          	li	a2,1024
    80004422:	05850593          	addi	a1,a0,88
    80004426:	05848513          	addi	a0,s1,88
    8000442a:	ffffd097          	auipc	ra,0xffffd
    8000442e:	91c080e7          	jalr	-1764(ra) # 80000d46 <memmove>
    bwrite(to);  // write the log
    80004432:	8526                	mv	a0,s1
    80004434:	fffff097          	auipc	ra,0xfffff
    80004438:	d8a080e7          	jalr	-630(ra) # 800031be <bwrite>
    brelse(from);
    8000443c:	854e                	mv	a0,s3
    8000443e:	fffff097          	auipc	ra,0xfffff
    80004442:	dbe080e7          	jalr	-578(ra) # 800031fc <brelse>
    brelse(to);
    80004446:	8526                	mv	a0,s1
    80004448:	fffff097          	auipc	ra,0xfffff
    8000444c:	db4080e7          	jalr	-588(ra) # 800031fc <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004450:	2905                	addiw	s2,s2,1
    80004452:	0a91                	addi	s5,s5,4
    80004454:	02ca2783          	lw	a5,44(s4)
    80004458:	f8f94ee3          	blt	s2,a5,800043f4 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000445c:	00000097          	auipc	ra,0x0
    80004460:	c6a080e7          	jalr	-918(ra) # 800040c6 <write_head>
    install_trans(0); // Now install writes to home locations
    80004464:	4501                	li	a0,0
    80004466:	00000097          	auipc	ra,0x0
    8000446a:	cda080e7          	jalr	-806(ra) # 80004140 <install_trans>
    log.lh.n = 0;
    8000446e:	00025797          	auipc	a5,0x25
    80004472:	c607a323          	sw	zero,-922(a5) # 800290d4 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004476:	00000097          	auipc	ra,0x0
    8000447a:	c50080e7          	jalr	-944(ra) # 800040c6 <write_head>
    8000447e:	bdf5                	j	8000437a <end_op+0x52>

0000000080004480 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004480:	1101                	addi	sp,sp,-32
    80004482:	ec06                	sd	ra,24(sp)
    80004484:	e822                	sd	s0,16(sp)
    80004486:	e426                	sd	s1,8(sp)
    80004488:	e04a                	sd	s2,0(sp)
    8000448a:	1000                	addi	s0,sp,32
    8000448c:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000448e:	00025917          	auipc	s2,0x25
    80004492:	c1a90913          	addi	s2,s2,-998 # 800290a8 <log>
    80004496:	854a                	mv	a0,s2
    80004498:	ffffc097          	auipc	ra,0xffffc
    8000449c:	752080e7          	jalr	1874(ra) # 80000bea <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800044a0:	02c92603          	lw	a2,44(s2)
    800044a4:	47f5                	li	a5,29
    800044a6:	06c7c563          	blt	a5,a2,80004510 <log_write+0x90>
    800044aa:	00025797          	auipc	a5,0x25
    800044ae:	c1a7a783          	lw	a5,-998(a5) # 800290c4 <log+0x1c>
    800044b2:	37fd                	addiw	a5,a5,-1
    800044b4:	04f65e63          	bge	a2,a5,80004510 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800044b8:	00025797          	auipc	a5,0x25
    800044bc:	c107a783          	lw	a5,-1008(a5) # 800290c8 <log+0x20>
    800044c0:	06f05063          	blez	a5,80004520 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800044c4:	4781                	li	a5,0
    800044c6:	06c05563          	blez	a2,80004530 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800044ca:	44cc                	lw	a1,12(s1)
    800044cc:	00025717          	auipc	a4,0x25
    800044d0:	c0c70713          	addi	a4,a4,-1012 # 800290d8 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800044d4:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800044d6:	4314                	lw	a3,0(a4)
    800044d8:	04b68c63          	beq	a3,a1,80004530 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800044dc:	2785                	addiw	a5,a5,1
    800044de:	0711                	addi	a4,a4,4
    800044e0:	fef61be3          	bne	a2,a5,800044d6 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800044e4:	0621                	addi	a2,a2,8
    800044e6:	060a                	slli	a2,a2,0x2
    800044e8:	00025797          	auipc	a5,0x25
    800044ec:	bc078793          	addi	a5,a5,-1088 # 800290a8 <log>
    800044f0:	963e                	add	a2,a2,a5
    800044f2:	44dc                	lw	a5,12(s1)
    800044f4:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800044f6:	8526                	mv	a0,s1
    800044f8:	fffff097          	auipc	ra,0xfffff
    800044fc:	da2080e7          	jalr	-606(ra) # 8000329a <bpin>
    log.lh.n++;
    80004500:	00025717          	auipc	a4,0x25
    80004504:	ba870713          	addi	a4,a4,-1112 # 800290a8 <log>
    80004508:	575c                	lw	a5,44(a4)
    8000450a:	2785                	addiw	a5,a5,1
    8000450c:	d75c                	sw	a5,44(a4)
    8000450e:	a835                	j	8000454a <log_write+0xca>
    panic("too big a transaction");
    80004510:	00004517          	auipc	a0,0x4
    80004514:	32050513          	addi	a0,a0,800 # 80008830 <syscalls+0x238>
    80004518:	ffffc097          	auipc	ra,0xffffc
    8000451c:	02c080e7          	jalr	44(ra) # 80000544 <panic>
    panic("log_write outside of trans");
    80004520:	00004517          	auipc	a0,0x4
    80004524:	32850513          	addi	a0,a0,808 # 80008848 <syscalls+0x250>
    80004528:	ffffc097          	auipc	ra,0xffffc
    8000452c:	01c080e7          	jalr	28(ra) # 80000544 <panic>
  log.lh.block[i] = b->blockno;
    80004530:	00878713          	addi	a4,a5,8
    80004534:	00271693          	slli	a3,a4,0x2
    80004538:	00025717          	auipc	a4,0x25
    8000453c:	b7070713          	addi	a4,a4,-1168 # 800290a8 <log>
    80004540:	9736                	add	a4,a4,a3
    80004542:	44d4                	lw	a3,12(s1)
    80004544:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004546:	faf608e3          	beq	a2,a5,800044f6 <log_write+0x76>
  }
  release(&log.lock);
    8000454a:	00025517          	auipc	a0,0x25
    8000454e:	b5e50513          	addi	a0,a0,-1186 # 800290a8 <log>
    80004552:	ffffc097          	auipc	ra,0xffffc
    80004556:	74c080e7          	jalr	1868(ra) # 80000c9e <release>
}
    8000455a:	60e2                	ld	ra,24(sp)
    8000455c:	6442                	ld	s0,16(sp)
    8000455e:	64a2                	ld	s1,8(sp)
    80004560:	6902                	ld	s2,0(sp)
    80004562:	6105                	addi	sp,sp,32
    80004564:	8082                	ret

0000000080004566 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004566:	1101                	addi	sp,sp,-32
    80004568:	ec06                	sd	ra,24(sp)
    8000456a:	e822                	sd	s0,16(sp)
    8000456c:	e426                	sd	s1,8(sp)
    8000456e:	e04a                	sd	s2,0(sp)
    80004570:	1000                	addi	s0,sp,32
    80004572:	84aa                	mv	s1,a0
    80004574:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004576:	00004597          	auipc	a1,0x4
    8000457a:	2f258593          	addi	a1,a1,754 # 80008868 <syscalls+0x270>
    8000457e:	0521                	addi	a0,a0,8
    80004580:	ffffc097          	auipc	ra,0xffffc
    80004584:	5da080e7          	jalr	1498(ra) # 80000b5a <initlock>
  lk->name = name;
    80004588:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000458c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004590:	0204a423          	sw	zero,40(s1)
}
    80004594:	60e2                	ld	ra,24(sp)
    80004596:	6442                	ld	s0,16(sp)
    80004598:	64a2                	ld	s1,8(sp)
    8000459a:	6902                	ld	s2,0(sp)
    8000459c:	6105                	addi	sp,sp,32
    8000459e:	8082                	ret

00000000800045a0 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800045a0:	1101                	addi	sp,sp,-32
    800045a2:	ec06                	sd	ra,24(sp)
    800045a4:	e822                	sd	s0,16(sp)
    800045a6:	e426                	sd	s1,8(sp)
    800045a8:	e04a                	sd	s2,0(sp)
    800045aa:	1000                	addi	s0,sp,32
    800045ac:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045ae:	00850913          	addi	s2,a0,8
    800045b2:	854a                	mv	a0,s2
    800045b4:	ffffc097          	auipc	ra,0xffffc
    800045b8:	636080e7          	jalr	1590(ra) # 80000bea <acquire>
  while (lk->locked) {
    800045bc:	409c                	lw	a5,0(s1)
    800045be:	cb89                	beqz	a5,800045d0 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800045c0:	85ca                	mv	a1,s2
    800045c2:	8526                	mv	a0,s1
    800045c4:	ffffe097          	auipc	ra,0xffffe
    800045c8:	b46080e7          	jalr	-1210(ra) # 8000210a <sleep>
  while (lk->locked) {
    800045cc:	409c                	lw	a5,0(s1)
    800045ce:	fbed                	bnez	a5,800045c0 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800045d0:	4785                	li	a5,1
    800045d2:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800045d4:	ffffd097          	auipc	ra,0xffffd
    800045d8:	3f2080e7          	jalr	1010(ra) # 800019c6 <myproc>
    800045dc:	591c                	lw	a5,48(a0)
    800045de:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800045e0:	854a                	mv	a0,s2
    800045e2:	ffffc097          	auipc	ra,0xffffc
    800045e6:	6bc080e7          	jalr	1724(ra) # 80000c9e <release>
}
    800045ea:	60e2                	ld	ra,24(sp)
    800045ec:	6442                	ld	s0,16(sp)
    800045ee:	64a2                	ld	s1,8(sp)
    800045f0:	6902                	ld	s2,0(sp)
    800045f2:	6105                	addi	sp,sp,32
    800045f4:	8082                	ret

00000000800045f6 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800045f6:	1101                	addi	sp,sp,-32
    800045f8:	ec06                	sd	ra,24(sp)
    800045fa:	e822                	sd	s0,16(sp)
    800045fc:	e426                	sd	s1,8(sp)
    800045fe:	e04a                	sd	s2,0(sp)
    80004600:	1000                	addi	s0,sp,32
    80004602:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004604:	00850913          	addi	s2,a0,8
    80004608:	854a                	mv	a0,s2
    8000460a:	ffffc097          	auipc	ra,0xffffc
    8000460e:	5e0080e7          	jalr	1504(ra) # 80000bea <acquire>
  lk->locked = 0;
    80004612:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004616:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000461a:	8526                	mv	a0,s1
    8000461c:	ffffe097          	auipc	ra,0xffffe
    80004620:	b52080e7          	jalr	-1198(ra) # 8000216e <wakeup>
  release(&lk->lk);
    80004624:	854a                	mv	a0,s2
    80004626:	ffffc097          	auipc	ra,0xffffc
    8000462a:	678080e7          	jalr	1656(ra) # 80000c9e <release>
}
    8000462e:	60e2                	ld	ra,24(sp)
    80004630:	6442                	ld	s0,16(sp)
    80004632:	64a2                	ld	s1,8(sp)
    80004634:	6902                	ld	s2,0(sp)
    80004636:	6105                	addi	sp,sp,32
    80004638:	8082                	ret

000000008000463a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000463a:	7179                	addi	sp,sp,-48
    8000463c:	f406                	sd	ra,40(sp)
    8000463e:	f022                	sd	s0,32(sp)
    80004640:	ec26                	sd	s1,24(sp)
    80004642:	e84a                	sd	s2,16(sp)
    80004644:	e44e                	sd	s3,8(sp)
    80004646:	1800                	addi	s0,sp,48
    80004648:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000464a:	00850913          	addi	s2,a0,8
    8000464e:	854a                	mv	a0,s2
    80004650:	ffffc097          	auipc	ra,0xffffc
    80004654:	59a080e7          	jalr	1434(ra) # 80000bea <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004658:	409c                	lw	a5,0(s1)
    8000465a:	ef99                	bnez	a5,80004678 <holdingsleep+0x3e>
    8000465c:	4481                	li	s1,0
  release(&lk->lk);
    8000465e:	854a                	mv	a0,s2
    80004660:	ffffc097          	auipc	ra,0xffffc
    80004664:	63e080e7          	jalr	1598(ra) # 80000c9e <release>
  return r;
}
    80004668:	8526                	mv	a0,s1
    8000466a:	70a2                	ld	ra,40(sp)
    8000466c:	7402                	ld	s0,32(sp)
    8000466e:	64e2                	ld	s1,24(sp)
    80004670:	6942                	ld	s2,16(sp)
    80004672:	69a2                	ld	s3,8(sp)
    80004674:	6145                	addi	sp,sp,48
    80004676:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004678:	0284a983          	lw	s3,40(s1)
    8000467c:	ffffd097          	auipc	ra,0xffffd
    80004680:	34a080e7          	jalr	842(ra) # 800019c6 <myproc>
    80004684:	5904                	lw	s1,48(a0)
    80004686:	413484b3          	sub	s1,s1,s3
    8000468a:	0014b493          	seqz	s1,s1
    8000468e:	bfc1                	j	8000465e <holdingsleep+0x24>

0000000080004690 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004690:	1141                	addi	sp,sp,-16
    80004692:	e406                	sd	ra,8(sp)
    80004694:	e022                	sd	s0,0(sp)
    80004696:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004698:	00004597          	auipc	a1,0x4
    8000469c:	1e058593          	addi	a1,a1,480 # 80008878 <syscalls+0x280>
    800046a0:	00025517          	auipc	a0,0x25
    800046a4:	b5050513          	addi	a0,a0,-1200 # 800291f0 <ftable>
    800046a8:	ffffc097          	auipc	ra,0xffffc
    800046ac:	4b2080e7          	jalr	1202(ra) # 80000b5a <initlock>
}
    800046b0:	60a2                	ld	ra,8(sp)
    800046b2:	6402                	ld	s0,0(sp)
    800046b4:	0141                	addi	sp,sp,16
    800046b6:	8082                	ret

00000000800046b8 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800046b8:	1101                	addi	sp,sp,-32
    800046ba:	ec06                	sd	ra,24(sp)
    800046bc:	e822                	sd	s0,16(sp)
    800046be:	e426                	sd	s1,8(sp)
    800046c0:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800046c2:	00025517          	auipc	a0,0x25
    800046c6:	b2e50513          	addi	a0,a0,-1234 # 800291f0 <ftable>
    800046ca:	ffffc097          	auipc	ra,0xffffc
    800046ce:	520080e7          	jalr	1312(ra) # 80000bea <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046d2:	00025497          	auipc	s1,0x25
    800046d6:	b3648493          	addi	s1,s1,-1226 # 80029208 <ftable+0x18>
    800046da:	00026717          	auipc	a4,0x26
    800046de:	ace70713          	addi	a4,a4,-1330 # 8002a1a8 <disk>
    if(f->ref == 0){
    800046e2:	40dc                	lw	a5,4(s1)
    800046e4:	cf99                	beqz	a5,80004702 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046e6:	02848493          	addi	s1,s1,40
    800046ea:	fee49ce3          	bne	s1,a4,800046e2 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800046ee:	00025517          	auipc	a0,0x25
    800046f2:	b0250513          	addi	a0,a0,-1278 # 800291f0 <ftable>
    800046f6:	ffffc097          	auipc	ra,0xffffc
    800046fa:	5a8080e7          	jalr	1448(ra) # 80000c9e <release>
  return 0;
    800046fe:	4481                	li	s1,0
    80004700:	a819                	j	80004716 <filealloc+0x5e>
      f->ref = 1;
    80004702:	4785                	li	a5,1
    80004704:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004706:	00025517          	auipc	a0,0x25
    8000470a:	aea50513          	addi	a0,a0,-1302 # 800291f0 <ftable>
    8000470e:	ffffc097          	auipc	ra,0xffffc
    80004712:	590080e7          	jalr	1424(ra) # 80000c9e <release>
}
    80004716:	8526                	mv	a0,s1
    80004718:	60e2                	ld	ra,24(sp)
    8000471a:	6442                	ld	s0,16(sp)
    8000471c:	64a2                	ld	s1,8(sp)
    8000471e:	6105                	addi	sp,sp,32
    80004720:	8082                	ret

0000000080004722 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004722:	1101                	addi	sp,sp,-32
    80004724:	ec06                	sd	ra,24(sp)
    80004726:	e822                	sd	s0,16(sp)
    80004728:	e426                	sd	s1,8(sp)
    8000472a:	1000                	addi	s0,sp,32
    8000472c:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000472e:	00025517          	auipc	a0,0x25
    80004732:	ac250513          	addi	a0,a0,-1342 # 800291f0 <ftable>
    80004736:	ffffc097          	auipc	ra,0xffffc
    8000473a:	4b4080e7          	jalr	1204(ra) # 80000bea <acquire>
  if(f->ref < 1)
    8000473e:	40dc                	lw	a5,4(s1)
    80004740:	02f05263          	blez	a5,80004764 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004744:	2785                	addiw	a5,a5,1
    80004746:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004748:	00025517          	auipc	a0,0x25
    8000474c:	aa850513          	addi	a0,a0,-1368 # 800291f0 <ftable>
    80004750:	ffffc097          	auipc	ra,0xffffc
    80004754:	54e080e7          	jalr	1358(ra) # 80000c9e <release>
  return f;
}
    80004758:	8526                	mv	a0,s1
    8000475a:	60e2                	ld	ra,24(sp)
    8000475c:	6442                	ld	s0,16(sp)
    8000475e:	64a2                	ld	s1,8(sp)
    80004760:	6105                	addi	sp,sp,32
    80004762:	8082                	ret
    panic("filedup");
    80004764:	00004517          	auipc	a0,0x4
    80004768:	11c50513          	addi	a0,a0,284 # 80008880 <syscalls+0x288>
    8000476c:	ffffc097          	auipc	ra,0xffffc
    80004770:	dd8080e7          	jalr	-552(ra) # 80000544 <panic>

0000000080004774 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004774:	7139                	addi	sp,sp,-64
    80004776:	fc06                	sd	ra,56(sp)
    80004778:	f822                	sd	s0,48(sp)
    8000477a:	f426                	sd	s1,40(sp)
    8000477c:	f04a                	sd	s2,32(sp)
    8000477e:	ec4e                	sd	s3,24(sp)
    80004780:	e852                	sd	s4,16(sp)
    80004782:	e456                	sd	s5,8(sp)
    80004784:	0080                	addi	s0,sp,64
    80004786:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004788:	00025517          	auipc	a0,0x25
    8000478c:	a6850513          	addi	a0,a0,-1432 # 800291f0 <ftable>
    80004790:	ffffc097          	auipc	ra,0xffffc
    80004794:	45a080e7          	jalr	1114(ra) # 80000bea <acquire>
  if(f->ref < 1)
    80004798:	40dc                	lw	a5,4(s1)
    8000479a:	06f05163          	blez	a5,800047fc <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000479e:	37fd                	addiw	a5,a5,-1
    800047a0:	0007871b          	sext.w	a4,a5
    800047a4:	c0dc                	sw	a5,4(s1)
    800047a6:	06e04363          	bgtz	a4,8000480c <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800047aa:	0004a903          	lw	s2,0(s1)
    800047ae:	0094ca83          	lbu	s5,9(s1)
    800047b2:	0104ba03          	ld	s4,16(s1)
    800047b6:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800047ba:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800047be:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800047c2:	00025517          	auipc	a0,0x25
    800047c6:	a2e50513          	addi	a0,a0,-1490 # 800291f0 <ftable>
    800047ca:	ffffc097          	auipc	ra,0xffffc
    800047ce:	4d4080e7          	jalr	1236(ra) # 80000c9e <release>

  if(ff.type == FD_PIPE){
    800047d2:	4785                	li	a5,1
    800047d4:	04f90d63          	beq	s2,a5,8000482e <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800047d8:	3979                	addiw	s2,s2,-2
    800047da:	4785                	li	a5,1
    800047dc:	0527e063          	bltu	a5,s2,8000481c <fileclose+0xa8>
    begin_op();
    800047e0:	00000097          	auipc	ra,0x0
    800047e4:	ac8080e7          	jalr	-1336(ra) # 800042a8 <begin_op>
    iput(ff.ip);
    800047e8:	854e                	mv	a0,s3
    800047ea:	fffff097          	auipc	ra,0xfffff
    800047ee:	2b6080e7          	jalr	694(ra) # 80003aa0 <iput>
    end_op();
    800047f2:	00000097          	auipc	ra,0x0
    800047f6:	b36080e7          	jalr	-1226(ra) # 80004328 <end_op>
    800047fa:	a00d                	j	8000481c <fileclose+0xa8>
    panic("fileclose");
    800047fc:	00004517          	auipc	a0,0x4
    80004800:	08c50513          	addi	a0,a0,140 # 80008888 <syscalls+0x290>
    80004804:	ffffc097          	auipc	ra,0xffffc
    80004808:	d40080e7          	jalr	-704(ra) # 80000544 <panic>
    release(&ftable.lock);
    8000480c:	00025517          	auipc	a0,0x25
    80004810:	9e450513          	addi	a0,a0,-1564 # 800291f0 <ftable>
    80004814:	ffffc097          	auipc	ra,0xffffc
    80004818:	48a080e7          	jalr	1162(ra) # 80000c9e <release>
  }
}
    8000481c:	70e2                	ld	ra,56(sp)
    8000481e:	7442                	ld	s0,48(sp)
    80004820:	74a2                	ld	s1,40(sp)
    80004822:	7902                	ld	s2,32(sp)
    80004824:	69e2                	ld	s3,24(sp)
    80004826:	6a42                	ld	s4,16(sp)
    80004828:	6aa2                	ld	s5,8(sp)
    8000482a:	6121                	addi	sp,sp,64
    8000482c:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000482e:	85d6                	mv	a1,s5
    80004830:	8552                	mv	a0,s4
    80004832:	00000097          	auipc	ra,0x0
    80004836:	34c080e7          	jalr	844(ra) # 80004b7e <pipeclose>
    8000483a:	b7cd                	j	8000481c <fileclose+0xa8>

000000008000483c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000483c:	715d                	addi	sp,sp,-80
    8000483e:	e486                	sd	ra,72(sp)
    80004840:	e0a2                	sd	s0,64(sp)
    80004842:	fc26                	sd	s1,56(sp)
    80004844:	f84a                	sd	s2,48(sp)
    80004846:	f44e                	sd	s3,40(sp)
    80004848:	0880                	addi	s0,sp,80
    8000484a:	84aa                	mv	s1,a0
    8000484c:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000484e:	ffffd097          	auipc	ra,0xffffd
    80004852:	178080e7          	jalr	376(ra) # 800019c6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004856:	409c                	lw	a5,0(s1)
    80004858:	37f9                	addiw	a5,a5,-2
    8000485a:	4705                	li	a4,1
    8000485c:	04f76763          	bltu	a4,a5,800048aa <filestat+0x6e>
    80004860:	892a                	mv	s2,a0
    ilock(f->ip);
    80004862:	6c88                	ld	a0,24(s1)
    80004864:	fffff097          	auipc	ra,0xfffff
    80004868:	082080e7          	jalr	130(ra) # 800038e6 <ilock>
    stati(f->ip, &st);
    8000486c:	fb840593          	addi	a1,s0,-72
    80004870:	6c88                	ld	a0,24(s1)
    80004872:	fffff097          	auipc	ra,0xfffff
    80004876:	2fe080e7          	jalr	766(ra) # 80003b70 <stati>
    iunlock(f->ip);
    8000487a:	6c88                	ld	a0,24(s1)
    8000487c:	fffff097          	auipc	ra,0xfffff
    80004880:	12c080e7          	jalr	300(ra) # 800039a8 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004884:	46e1                	li	a3,24
    80004886:	fb840613          	addi	a2,s0,-72
    8000488a:	85ce                	mv	a1,s3
    8000488c:	05093503          	ld	a0,80(s2)
    80004890:	ffffd097          	auipc	ra,0xffffd
    80004894:	df4080e7          	jalr	-524(ra) # 80001684 <copyout>
    80004898:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000489c:	60a6                	ld	ra,72(sp)
    8000489e:	6406                	ld	s0,64(sp)
    800048a0:	74e2                	ld	s1,56(sp)
    800048a2:	7942                	ld	s2,48(sp)
    800048a4:	79a2                	ld	s3,40(sp)
    800048a6:	6161                	addi	sp,sp,80
    800048a8:	8082                	ret
  return -1;
    800048aa:	557d                	li	a0,-1
    800048ac:	bfc5                	j	8000489c <filestat+0x60>

00000000800048ae <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800048ae:	7179                	addi	sp,sp,-48
    800048b0:	f406                	sd	ra,40(sp)
    800048b2:	f022                	sd	s0,32(sp)
    800048b4:	ec26                	sd	s1,24(sp)
    800048b6:	e84a                	sd	s2,16(sp)
    800048b8:	e44e                	sd	s3,8(sp)
    800048ba:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800048bc:	00854783          	lbu	a5,8(a0)
    800048c0:	c3d5                	beqz	a5,80004964 <fileread+0xb6>
    800048c2:	84aa                	mv	s1,a0
    800048c4:	89ae                	mv	s3,a1
    800048c6:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800048c8:	411c                	lw	a5,0(a0)
    800048ca:	4705                	li	a4,1
    800048cc:	04e78963          	beq	a5,a4,8000491e <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048d0:	470d                	li	a4,3
    800048d2:	04e78d63          	beq	a5,a4,8000492c <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800048d6:	4709                	li	a4,2
    800048d8:	06e79e63          	bne	a5,a4,80004954 <fileread+0xa6>
    ilock(f->ip);
    800048dc:	6d08                	ld	a0,24(a0)
    800048de:	fffff097          	auipc	ra,0xfffff
    800048e2:	008080e7          	jalr	8(ra) # 800038e6 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800048e6:	874a                	mv	a4,s2
    800048e8:	5094                	lw	a3,32(s1)
    800048ea:	864e                	mv	a2,s3
    800048ec:	4585                	li	a1,1
    800048ee:	6c88                	ld	a0,24(s1)
    800048f0:	fffff097          	auipc	ra,0xfffff
    800048f4:	2aa080e7          	jalr	682(ra) # 80003b9a <readi>
    800048f8:	892a                	mv	s2,a0
    800048fa:	00a05563          	blez	a0,80004904 <fileread+0x56>
      f->off += r;
    800048fe:	509c                	lw	a5,32(s1)
    80004900:	9fa9                	addw	a5,a5,a0
    80004902:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004904:	6c88                	ld	a0,24(s1)
    80004906:	fffff097          	auipc	ra,0xfffff
    8000490a:	0a2080e7          	jalr	162(ra) # 800039a8 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000490e:	854a                	mv	a0,s2
    80004910:	70a2                	ld	ra,40(sp)
    80004912:	7402                	ld	s0,32(sp)
    80004914:	64e2                	ld	s1,24(sp)
    80004916:	6942                	ld	s2,16(sp)
    80004918:	69a2                	ld	s3,8(sp)
    8000491a:	6145                	addi	sp,sp,48
    8000491c:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000491e:	6908                	ld	a0,16(a0)
    80004920:	00000097          	auipc	ra,0x0
    80004924:	3ce080e7          	jalr	974(ra) # 80004cee <piperead>
    80004928:	892a                	mv	s2,a0
    8000492a:	b7d5                	j	8000490e <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000492c:	02451783          	lh	a5,36(a0)
    80004930:	03079693          	slli	a3,a5,0x30
    80004934:	92c1                	srli	a3,a3,0x30
    80004936:	4725                	li	a4,9
    80004938:	02d76863          	bltu	a4,a3,80004968 <fileread+0xba>
    8000493c:	0792                	slli	a5,a5,0x4
    8000493e:	00025717          	auipc	a4,0x25
    80004942:	81270713          	addi	a4,a4,-2030 # 80029150 <devsw>
    80004946:	97ba                	add	a5,a5,a4
    80004948:	639c                	ld	a5,0(a5)
    8000494a:	c38d                	beqz	a5,8000496c <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000494c:	4505                	li	a0,1
    8000494e:	9782                	jalr	a5
    80004950:	892a                	mv	s2,a0
    80004952:	bf75                	j	8000490e <fileread+0x60>
    panic("fileread");
    80004954:	00004517          	auipc	a0,0x4
    80004958:	f4450513          	addi	a0,a0,-188 # 80008898 <syscalls+0x2a0>
    8000495c:	ffffc097          	auipc	ra,0xffffc
    80004960:	be8080e7          	jalr	-1048(ra) # 80000544 <panic>
    return -1;
    80004964:	597d                	li	s2,-1
    80004966:	b765                	j	8000490e <fileread+0x60>
      return -1;
    80004968:	597d                	li	s2,-1
    8000496a:	b755                	j	8000490e <fileread+0x60>
    8000496c:	597d                	li	s2,-1
    8000496e:	b745                	j	8000490e <fileread+0x60>

0000000080004970 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004970:	715d                	addi	sp,sp,-80
    80004972:	e486                	sd	ra,72(sp)
    80004974:	e0a2                	sd	s0,64(sp)
    80004976:	fc26                	sd	s1,56(sp)
    80004978:	f84a                	sd	s2,48(sp)
    8000497a:	f44e                	sd	s3,40(sp)
    8000497c:	f052                	sd	s4,32(sp)
    8000497e:	ec56                	sd	s5,24(sp)
    80004980:	e85a                	sd	s6,16(sp)
    80004982:	e45e                	sd	s7,8(sp)
    80004984:	e062                	sd	s8,0(sp)
    80004986:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004988:	00954783          	lbu	a5,9(a0)
    8000498c:	10078663          	beqz	a5,80004a98 <filewrite+0x128>
    80004990:	892a                	mv	s2,a0
    80004992:	8aae                	mv	s5,a1
    80004994:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004996:	411c                	lw	a5,0(a0)
    80004998:	4705                	li	a4,1
    8000499a:	02e78263          	beq	a5,a4,800049be <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000499e:	470d                	li	a4,3
    800049a0:	02e78663          	beq	a5,a4,800049cc <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800049a4:	4709                	li	a4,2
    800049a6:	0ee79163          	bne	a5,a4,80004a88 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800049aa:	0ac05d63          	blez	a2,80004a64 <filewrite+0xf4>
    int i = 0;
    800049ae:	4981                	li	s3,0
    800049b0:	6b05                	lui	s6,0x1
    800049b2:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800049b6:	6b85                	lui	s7,0x1
    800049b8:	c00b8b9b          	addiw	s7,s7,-1024
    800049bc:	a861                	j	80004a54 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800049be:	6908                	ld	a0,16(a0)
    800049c0:	00000097          	auipc	ra,0x0
    800049c4:	22e080e7          	jalr	558(ra) # 80004bee <pipewrite>
    800049c8:	8a2a                	mv	s4,a0
    800049ca:	a045                	j	80004a6a <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800049cc:	02451783          	lh	a5,36(a0)
    800049d0:	03079693          	slli	a3,a5,0x30
    800049d4:	92c1                	srli	a3,a3,0x30
    800049d6:	4725                	li	a4,9
    800049d8:	0cd76263          	bltu	a4,a3,80004a9c <filewrite+0x12c>
    800049dc:	0792                	slli	a5,a5,0x4
    800049de:	00024717          	auipc	a4,0x24
    800049e2:	77270713          	addi	a4,a4,1906 # 80029150 <devsw>
    800049e6:	97ba                	add	a5,a5,a4
    800049e8:	679c                	ld	a5,8(a5)
    800049ea:	cbdd                	beqz	a5,80004aa0 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800049ec:	4505                	li	a0,1
    800049ee:	9782                	jalr	a5
    800049f0:	8a2a                	mv	s4,a0
    800049f2:	a8a5                	j	80004a6a <filewrite+0xfa>
    800049f4:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800049f8:	00000097          	auipc	ra,0x0
    800049fc:	8b0080e7          	jalr	-1872(ra) # 800042a8 <begin_op>
      ilock(f->ip);
    80004a00:	01893503          	ld	a0,24(s2)
    80004a04:	fffff097          	auipc	ra,0xfffff
    80004a08:	ee2080e7          	jalr	-286(ra) # 800038e6 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004a0c:	8762                	mv	a4,s8
    80004a0e:	02092683          	lw	a3,32(s2)
    80004a12:	01598633          	add	a2,s3,s5
    80004a16:	4585                	li	a1,1
    80004a18:	01893503          	ld	a0,24(s2)
    80004a1c:	fffff097          	auipc	ra,0xfffff
    80004a20:	276080e7          	jalr	630(ra) # 80003c92 <writei>
    80004a24:	84aa                	mv	s1,a0
    80004a26:	00a05763          	blez	a0,80004a34 <filewrite+0xc4>
        f->off += r;
    80004a2a:	02092783          	lw	a5,32(s2)
    80004a2e:	9fa9                	addw	a5,a5,a0
    80004a30:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004a34:	01893503          	ld	a0,24(s2)
    80004a38:	fffff097          	auipc	ra,0xfffff
    80004a3c:	f70080e7          	jalr	-144(ra) # 800039a8 <iunlock>
      end_op();
    80004a40:	00000097          	auipc	ra,0x0
    80004a44:	8e8080e7          	jalr	-1816(ra) # 80004328 <end_op>

      if(r != n1){
    80004a48:	009c1f63          	bne	s8,s1,80004a66 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004a4c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004a50:	0149db63          	bge	s3,s4,80004a66 <filewrite+0xf6>
      int n1 = n - i;
    80004a54:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004a58:	84be                	mv	s1,a5
    80004a5a:	2781                	sext.w	a5,a5
    80004a5c:	f8fb5ce3          	bge	s6,a5,800049f4 <filewrite+0x84>
    80004a60:	84de                	mv	s1,s7
    80004a62:	bf49                	j	800049f4 <filewrite+0x84>
    int i = 0;
    80004a64:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004a66:	013a1f63          	bne	s4,s3,80004a84 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004a6a:	8552                	mv	a0,s4
    80004a6c:	60a6                	ld	ra,72(sp)
    80004a6e:	6406                	ld	s0,64(sp)
    80004a70:	74e2                	ld	s1,56(sp)
    80004a72:	7942                	ld	s2,48(sp)
    80004a74:	79a2                	ld	s3,40(sp)
    80004a76:	7a02                	ld	s4,32(sp)
    80004a78:	6ae2                	ld	s5,24(sp)
    80004a7a:	6b42                	ld	s6,16(sp)
    80004a7c:	6ba2                	ld	s7,8(sp)
    80004a7e:	6c02                	ld	s8,0(sp)
    80004a80:	6161                	addi	sp,sp,80
    80004a82:	8082                	ret
    ret = (i == n ? n : -1);
    80004a84:	5a7d                	li	s4,-1
    80004a86:	b7d5                	j	80004a6a <filewrite+0xfa>
    panic("filewrite");
    80004a88:	00004517          	auipc	a0,0x4
    80004a8c:	e2050513          	addi	a0,a0,-480 # 800088a8 <syscalls+0x2b0>
    80004a90:	ffffc097          	auipc	ra,0xffffc
    80004a94:	ab4080e7          	jalr	-1356(ra) # 80000544 <panic>
    return -1;
    80004a98:	5a7d                	li	s4,-1
    80004a9a:	bfc1                	j	80004a6a <filewrite+0xfa>
      return -1;
    80004a9c:	5a7d                	li	s4,-1
    80004a9e:	b7f1                	j	80004a6a <filewrite+0xfa>
    80004aa0:	5a7d                	li	s4,-1
    80004aa2:	b7e1                	j	80004a6a <filewrite+0xfa>

0000000080004aa4 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004aa4:	7179                	addi	sp,sp,-48
    80004aa6:	f406                	sd	ra,40(sp)
    80004aa8:	f022                	sd	s0,32(sp)
    80004aaa:	ec26                	sd	s1,24(sp)
    80004aac:	e84a                	sd	s2,16(sp)
    80004aae:	e44e                	sd	s3,8(sp)
    80004ab0:	e052                	sd	s4,0(sp)
    80004ab2:	1800                	addi	s0,sp,48
    80004ab4:	84aa                	mv	s1,a0
    80004ab6:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004ab8:	0005b023          	sd	zero,0(a1)
    80004abc:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004ac0:	00000097          	auipc	ra,0x0
    80004ac4:	bf8080e7          	jalr	-1032(ra) # 800046b8 <filealloc>
    80004ac8:	e088                	sd	a0,0(s1)
    80004aca:	c551                	beqz	a0,80004b56 <pipealloc+0xb2>
    80004acc:	00000097          	auipc	ra,0x0
    80004ad0:	bec080e7          	jalr	-1044(ra) # 800046b8 <filealloc>
    80004ad4:	00aa3023          	sd	a0,0(s4)
    80004ad8:	c92d                	beqz	a0,80004b4a <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004ada:	ffffc097          	auipc	ra,0xffffc
    80004ade:	020080e7          	jalr	32(ra) # 80000afa <kalloc>
    80004ae2:	892a                	mv	s2,a0
    80004ae4:	c125                	beqz	a0,80004b44 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004ae6:	4985                	li	s3,1
    80004ae8:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004aec:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004af0:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004af4:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004af8:	00004597          	auipc	a1,0x4
    80004afc:	a5858593          	addi	a1,a1,-1448 # 80008550 <states.1782+0x1e8>
    80004b00:	ffffc097          	auipc	ra,0xffffc
    80004b04:	05a080e7          	jalr	90(ra) # 80000b5a <initlock>
  (*f0)->type = FD_PIPE;
    80004b08:	609c                	ld	a5,0(s1)
    80004b0a:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004b0e:	609c                	ld	a5,0(s1)
    80004b10:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004b14:	609c                	ld	a5,0(s1)
    80004b16:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004b1a:	609c                	ld	a5,0(s1)
    80004b1c:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004b20:	000a3783          	ld	a5,0(s4)
    80004b24:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004b28:	000a3783          	ld	a5,0(s4)
    80004b2c:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004b30:	000a3783          	ld	a5,0(s4)
    80004b34:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004b38:	000a3783          	ld	a5,0(s4)
    80004b3c:	0127b823          	sd	s2,16(a5)
  return 0;
    80004b40:	4501                	li	a0,0
    80004b42:	a025                	j	80004b6a <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004b44:	6088                	ld	a0,0(s1)
    80004b46:	e501                	bnez	a0,80004b4e <pipealloc+0xaa>
    80004b48:	a039                	j	80004b56 <pipealloc+0xb2>
    80004b4a:	6088                	ld	a0,0(s1)
    80004b4c:	c51d                	beqz	a0,80004b7a <pipealloc+0xd6>
    fileclose(*f0);
    80004b4e:	00000097          	auipc	ra,0x0
    80004b52:	c26080e7          	jalr	-986(ra) # 80004774 <fileclose>
  if(*f1)
    80004b56:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004b5a:	557d                	li	a0,-1
  if(*f1)
    80004b5c:	c799                	beqz	a5,80004b6a <pipealloc+0xc6>
    fileclose(*f1);
    80004b5e:	853e                	mv	a0,a5
    80004b60:	00000097          	auipc	ra,0x0
    80004b64:	c14080e7          	jalr	-1004(ra) # 80004774 <fileclose>
  return -1;
    80004b68:	557d                	li	a0,-1
}
    80004b6a:	70a2                	ld	ra,40(sp)
    80004b6c:	7402                	ld	s0,32(sp)
    80004b6e:	64e2                	ld	s1,24(sp)
    80004b70:	6942                	ld	s2,16(sp)
    80004b72:	69a2                	ld	s3,8(sp)
    80004b74:	6a02                	ld	s4,0(sp)
    80004b76:	6145                	addi	sp,sp,48
    80004b78:	8082                	ret
  return -1;
    80004b7a:	557d                	li	a0,-1
    80004b7c:	b7fd                	j	80004b6a <pipealloc+0xc6>

0000000080004b7e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004b7e:	1101                	addi	sp,sp,-32
    80004b80:	ec06                	sd	ra,24(sp)
    80004b82:	e822                	sd	s0,16(sp)
    80004b84:	e426                	sd	s1,8(sp)
    80004b86:	e04a                	sd	s2,0(sp)
    80004b88:	1000                	addi	s0,sp,32
    80004b8a:	84aa                	mv	s1,a0
    80004b8c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004b8e:	ffffc097          	auipc	ra,0xffffc
    80004b92:	05c080e7          	jalr	92(ra) # 80000bea <acquire>
  if(writable){
    80004b96:	02090d63          	beqz	s2,80004bd0 <pipeclose+0x52>
    pi->writeopen = 0;
    80004b9a:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004b9e:	21848513          	addi	a0,s1,536
    80004ba2:	ffffd097          	auipc	ra,0xffffd
    80004ba6:	5cc080e7          	jalr	1484(ra) # 8000216e <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004baa:	2204b783          	ld	a5,544(s1)
    80004bae:	eb95                	bnez	a5,80004be2 <pipeclose+0x64>
    release(&pi->lock);
    80004bb0:	8526                	mv	a0,s1
    80004bb2:	ffffc097          	auipc	ra,0xffffc
    80004bb6:	0ec080e7          	jalr	236(ra) # 80000c9e <release>
    kfree((char*)pi);
    80004bba:	8526                	mv	a0,s1
    80004bbc:	ffffc097          	auipc	ra,0xffffc
    80004bc0:	e42080e7          	jalr	-446(ra) # 800009fe <kfree>
  } else
    release(&pi->lock);
}
    80004bc4:	60e2                	ld	ra,24(sp)
    80004bc6:	6442                	ld	s0,16(sp)
    80004bc8:	64a2                	ld	s1,8(sp)
    80004bca:	6902                	ld	s2,0(sp)
    80004bcc:	6105                	addi	sp,sp,32
    80004bce:	8082                	ret
    pi->readopen = 0;
    80004bd0:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004bd4:	21c48513          	addi	a0,s1,540
    80004bd8:	ffffd097          	auipc	ra,0xffffd
    80004bdc:	596080e7          	jalr	1430(ra) # 8000216e <wakeup>
    80004be0:	b7e9                	j	80004baa <pipeclose+0x2c>
    release(&pi->lock);
    80004be2:	8526                	mv	a0,s1
    80004be4:	ffffc097          	auipc	ra,0xffffc
    80004be8:	0ba080e7          	jalr	186(ra) # 80000c9e <release>
}
    80004bec:	bfe1                	j	80004bc4 <pipeclose+0x46>

0000000080004bee <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004bee:	7159                	addi	sp,sp,-112
    80004bf0:	f486                	sd	ra,104(sp)
    80004bf2:	f0a2                	sd	s0,96(sp)
    80004bf4:	eca6                	sd	s1,88(sp)
    80004bf6:	e8ca                	sd	s2,80(sp)
    80004bf8:	e4ce                	sd	s3,72(sp)
    80004bfa:	e0d2                	sd	s4,64(sp)
    80004bfc:	fc56                	sd	s5,56(sp)
    80004bfe:	f85a                	sd	s6,48(sp)
    80004c00:	f45e                	sd	s7,40(sp)
    80004c02:	f062                	sd	s8,32(sp)
    80004c04:	ec66                	sd	s9,24(sp)
    80004c06:	1880                	addi	s0,sp,112
    80004c08:	84aa                	mv	s1,a0
    80004c0a:	8aae                	mv	s5,a1
    80004c0c:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004c0e:	ffffd097          	auipc	ra,0xffffd
    80004c12:	db8080e7          	jalr	-584(ra) # 800019c6 <myproc>
    80004c16:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004c18:	8526                	mv	a0,s1
    80004c1a:	ffffc097          	auipc	ra,0xffffc
    80004c1e:	fd0080e7          	jalr	-48(ra) # 80000bea <acquire>
  while(i < n){
    80004c22:	0d405463          	blez	s4,80004cea <pipewrite+0xfc>
    80004c26:	8ba6                	mv	s7,s1
  int i = 0;
    80004c28:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c2a:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004c2c:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004c30:	21c48c13          	addi	s8,s1,540
    80004c34:	a08d                	j	80004c96 <pipewrite+0xa8>
      release(&pi->lock);
    80004c36:	8526                	mv	a0,s1
    80004c38:	ffffc097          	auipc	ra,0xffffc
    80004c3c:	066080e7          	jalr	102(ra) # 80000c9e <release>
      return -1;
    80004c40:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004c42:	854a                	mv	a0,s2
    80004c44:	70a6                	ld	ra,104(sp)
    80004c46:	7406                	ld	s0,96(sp)
    80004c48:	64e6                	ld	s1,88(sp)
    80004c4a:	6946                	ld	s2,80(sp)
    80004c4c:	69a6                	ld	s3,72(sp)
    80004c4e:	6a06                	ld	s4,64(sp)
    80004c50:	7ae2                	ld	s5,56(sp)
    80004c52:	7b42                	ld	s6,48(sp)
    80004c54:	7ba2                	ld	s7,40(sp)
    80004c56:	7c02                	ld	s8,32(sp)
    80004c58:	6ce2                	ld	s9,24(sp)
    80004c5a:	6165                	addi	sp,sp,112
    80004c5c:	8082                	ret
      wakeup(&pi->nread);
    80004c5e:	8566                	mv	a0,s9
    80004c60:	ffffd097          	auipc	ra,0xffffd
    80004c64:	50e080e7          	jalr	1294(ra) # 8000216e <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004c68:	85de                	mv	a1,s7
    80004c6a:	8562                	mv	a0,s8
    80004c6c:	ffffd097          	auipc	ra,0xffffd
    80004c70:	49e080e7          	jalr	1182(ra) # 8000210a <sleep>
    80004c74:	a839                	j	80004c92 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004c76:	21c4a783          	lw	a5,540(s1)
    80004c7a:	0017871b          	addiw	a4,a5,1
    80004c7e:	20e4ae23          	sw	a4,540(s1)
    80004c82:	1ff7f793          	andi	a5,a5,511
    80004c86:	97a6                	add	a5,a5,s1
    80004c88:	f9f44703          	lbu	a4,-97(s0)
    80004c8c:	00e78c23          	sb	a4,24(a5)
      i++;
    80004c90:	2905                	addiw	s2,s2,1
  while(i < n){
    80004c92:	05495063          	bge	s2,s4,80004cd2 <pipewrite+0xe4>
    if(pi->readopen == 0 || killed(pr)){
    80004c96:	2204a783          	lw	a5,544(s1)
    80004c9a:	dfd1                	beqz	a5,80004c36 <pipewrite+0x48>
    80004c9c:	854e                	mv	a0,s3
    80004c9e:	ffffd097          	auipc	ra,0xffffd
    80004ca2:	714080e7          	jalr	1812(ra) # 800023b2 <killed>
    80004ca6:	f941                	bnez	a0,80004c36 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004ca8:	2184a783          	lw	a5,536(s1)
    80004cac:	21c4a703          	lw	a4,540(s1)
    80004cb0:	2007879b          	addiw	a5,a5,512
    80004cb4:	faf705e3          	beq	a4,a5,80004c5e <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004cb8:	4685                	li	a3,1
    80004cba:	01590633          	add	a2,s2,s5
    80004cbe:	f9f40593          	addi	a1,s0,-97
    80004cc2:	0509b503          	ld	a0,80(s3)
    80004cc6:	ffffd097          	auipc	ra,0xffffd
    80004cca:	a4a080e7          	jalr	-1462(ra) # 80001710 <copyin>
    80004cce:	fb6514e3          	bne	a0,s6,80004c76 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004cd2:	21848513          	addi	a0,s1,536
    80004cd6:	ffffd097          	auipc	ra,0xffffd
    80004cda:	498080e7          	jalr	1176(ra) # 8000216e <wakeup>
  release(&pi->lock);
    80004cde:	8526                	mv	a0,s1
    80004ce0:	ffffc097          	auipc	ra,0xffffc
    80004ce4:	fbe080e7          	jalr	-66(ra) # 80000c9e <release>
  return i;
    80004ce8:	bfa9                	j	80004c42 <pipewrite+0x54>
  int i = 0;
    80004cea:	4901                	li	s2,0
    80004cec:	b7dd                	j	80004cd2 <pipewrite+0xe4>

0000000080004cee <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004cee:	715d                	addi	sp,sp,-80
    80004cf0:	e486                	sd	ra,72(sp)
    80004cf2:	e0a2                	sd	s0,64(sp)
    80004cf4:	fc26                	sd	s1,56(sp)
    80004cf6:	f84a                	sd	s2,48(sp)
    80004cf8:	f44e                	sd	s3,40(sp)
    80004cfa:	f052                	sd	s4,32(sp)
    80004cfc:	ec56                	sd	s5,24(sp)
    80004cfe:	e85a                	sd	s6,16(sp)
    80004d00:	0880                	addi	s0,sp,80
    80004d02:	84aa                	mv	s1,a0
    80004d04:	892e                	mv	s2,a1
    80004d06:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004d08:	ffffd097          	auipc	ra,0xffffd
    80004d0c:	cbe080e7          	jalr	-834(ra) # 800019c6 <myproc>
    80004d10:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004d12:	8b26                	mv	s6,s1
    80004d14:	8526                	mv	a0,s1
    80004d16:	ffffc097          	auipc	ra,0xffffc
    80004d1a:	ed4080e7          	jalr	-300(ra) # 80000bea <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d1e:	2184a703          	lw	a4,536(s1)
    80004d22:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d26:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d2a:	02f71763          	bne	a4,a5,80004d58 <piperead+0x6a>
    80004d2e:	2244a783          	lw	a5,548(s1)
    80004d32:	c39d                	beqz	a5,80004d58 <piperead+0x6a>
    if(killed(pr)){
    80004d34:	8552                	mv	a0,s4
    80004d36:	ffffd097          	auipc	ra,0xffffd
    80004d3a:	67c080e7          	jalr	1660(ra) # 800023b2 <killed>
    80004d3e:	e941                	bnez	a0,80004dce <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d40:	85da                	mv	a1,s6
    80004d42:	854e                	mv	a0,s3
    80004d44:	ffffd097          	auipc	ra,0xffffd
    80004d48:	3c6080e7          	jalr	966(ra) # 8000210a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d4c:	2184a703          	lw	a4,536(s1)
    80004d50:	21c4a783          	lw	a5,540(s1)
    80004d54:	fcf70de3          	beq	a4,a5,80004d2e <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d58:	09505263          	blez	s5,80004ddc <piperead+0xee>
    80004d5c:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d5e:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004d60:	2184a783          	lw	a5,536(s1)
    80004d64:	21c4a703          	lw	a4,540(s1)
    80004d68:	02f70d63          	beq	a4,a5,80004da2 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004d6c:	0017871b          	addiw	a4,a5,1
    80004d70:	20e4ac23          	sw	a4,536(s1)
    80004d74:	1ff7f793          	andi	a5,a5,511
    80004d78:	97a6                	add	a5,a5,s1
    80004d7a:	0187c783          	lbu	a5,24(a5)
    80004d7e:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d82:	4685                	li	a3,1
    80004d84:	fbf40613          	addi	a2,s0,-65
    80004d88:	85ca                	mv	a1,s2
    80004d8a:	050a3503          	ld	a0,80(s4)
    80004d8e:	ffffd097          	auipc	ra,0xffffd
    80004d92:	8f6080e7          	jalr	-1802(ra) # 80001684 <copyout>
    80004d96:	01650663          	beq	a0,s6,80004da2 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d9a:	2985                	addiw	s3,s3,1
    80004d9c:	0905                	addi	s2,s2,1
    80004d9e:	fd3a91e3          	bne	s5,s3,80004d60 <piperead+0x72>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004da2:	21c48513          	addi	a0,s1,540
    80004da6:	ffffd097          	auipc	ra,0xffffd
    80004daa:	3c8080e7          	jalr	968(ra) # 8000216e <wakeup>
  release(&pi->lock);
    80004dae:	8526                	mv	a0,s1
    80004db0:	ffffc097          	auipc	ra,0xffffc
    80004db4:	eee080e7          	jalr	-274(ra) # 80000c9e <release>
  return i;
}
    80004db8:	854e                	mv	a0,s3
    80004dba:	60a6                	ld	ra,72(sp)
    80004dbc:	6406                	ld	s0,64(sp)
    80004dbe:	74e2                	ld	s1,56(sp)
    80004dc0:	7942                	ld	s2,48(sp)
    80004dc2:	79a2                	ld	s3,40(sp)
    80004dc4:	7a02                	ld	s4,32(sp)
    80004dc6:	6ae2                	ld	s5,24(sp)
    80004dc8:	6b42                	ld	s6,16(sp)
    80004dca:	6161                	addi	sp,sp,80
    80004dcc:	8082                	ret
      release(&pi->lock);
    80004dce:	8526                	mv	a0,s1
    80004dd0:	ffffc097          	auipc	ra,0xffffc
    80004dd4:	ece080e7          	jalr	-306(ra) # 80000c9e <release>
      return -1;
    80004dd8:	59fd                	li	s3,-1
    80004dda:	bff9                	j	80004db8 <piperead+0xca>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ddc:	4981                	li	s3,0
    80004dde:	b7d1                	j	80004da2 <piperead+0xb4>

0000000080004de0 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004de0:	1141                	addi	sp,sp,-16
    80004de2:	e422                	sd	s0,8(sp)
    80004de4:	0800                	addi	s0,sp,16
    80004de6:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004de8:	8905                	andi	a0,a0,1
    80004dea:	c111                	beqz	a0,80004dee <flags2perm+0xe>
      perm = PTE_X;
    80004dec:	4521                	li	a0,8
    if(flags & 0x2)
    80004dee:	8b89                	andi	a5,a5,2
    80004df0:	c399                	beqz	a5,80004df6 <flags2perm+0x16>
      perm |= PTE_W;
    80004df2:	00456513          	ori	a0,a0,4
    return perm;
}
    80004df6:	6422                	ld	s0,8(sp)
    80004df8:	0141                	addi	sp,sp,16
    80004dfa:	8082                	ret

0000000080004dfc <exec>:

int
exec(char *path, char **argv)
{
    80004dfc:	df010113          	addi	sp,sp,-528
    80004e00:	20113423          	sd	ra,520(sp)
    80004e04:	20813023          	sd	s0,512(sp)
    80004e08:	ffa6                	sd	s1,504(sp)
    80004e0a:	fbca                	sd	s2,496(sp)
    80004e0c:	f7ce                	sd	s3,488(sp)
    80004e0e:	f3d2                	sd	s4,480(sp)
    80004e10:	efd6                	sd	s5,472(sp)
    80004e12:	ebda                	sd	s6,464(sp)
    80004e14:	e7de                	sd	s7,456(sp)
    80004e16:	e3e2                	sd	s8,448(sp)
    80004e18:	ff66                	sd	s9,440(sp)
    80004e1a:	fb6a                	sd	s10,432(sp)
    80004e1c:	f76e                	sd	s11,424(sp)
    80004e1e:	0c00                	addi	s0,sp,528
    80004e20:	84aa                	mv	s1,a0
    80004e22:	dea43c23          	sd	a0,-520(s0)
    80004e26:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004e2a:	ffffd097          	auipc	ra,0xffffd
    80004e2e:	b9c080e7          	jalr	-1124(ra) # 800019c6 <myproc>
    80004e32:	892a                	mv	s2,a0

  begin_op();
    80004e34:	fffff097          	auipc	ra,0xfffff
    80004e38:	474080e7          	jalr	1140(ra) # 800042a8 <begin_op>

  if((ip = namei(path)) == 0){
    80004e3c:	8526                	mv	a0,s1
    80004e3e:	fffff097          	auipc	ra,0xfffff
    80004e42:	24e080e7          	jalr	590(ra) # 8000408c <namei>
    80004e46:	c92d                	beqz	a0,80004eb8 <exec+0xbc>
    80004e48:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004e4a:	fffff097          	auipc	ra,0xfffff
    80004e4e:	a9c080e7          	jalr	-1380(ra) # 800038e6 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004e52:	04000713          	li	a4,64
    80004e56:	4681                	li	a3,0
    80004e58:	e5040613          	addi	a2,s0,-432
    80004e5c:	4581                	li	a1,0
    80004e5e:	8526                	mv	a0,s1
    80004e60:	fffff097          	auipc	ra,0xfffff
    80004e64:	d3a080e7          	jalr	-710(ra) # 80003b9a <readi>
    80004e68:	04000793          	li	a5,64
    80004e6c:	00f51a63          	bne	a0,a5,80004e80 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004e70:	e5042703          	lw	a4,-432(s0)
    80004e74:	464c47b7          	lui	a5,0x464c4
    80004e78:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004e7c:	04f70463          	beq	a4,a5,80004ec4 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004e80:	8526                	mv	a0,s1
    80004e82:	fffff097          	auipc	ra,0xfffff
    80004e86:	cc6080e7          	jalr	-826(ra) # 80003b48 <iunlockput>
    end_op();
    80004e8a:	fffff097          	auipc	ra,0xfffff
    80004e8e:	49e080e7          	jalr	1182(ra) # 80004328 <end_op>
  }
  return -1;
    80004e92:	557d                	li	a0,-1
}
    80004e94:	20813083          	ld	ra,520(sp)
    80004e98:	20013403          	ld	s0,512(sp)
    80004e9c:	74fe                	ld	s1,504(sp)
    80004e9e:	795e                	ld	s2,496(sp)
    80004ea0:	79be                	ld	s3,488(sp)
    80004ea2:	7a1e                	ld	s4,480(sp)
    80004ea4:	6afe                	ld	s5,472(sp)
    80004ea6:	6b5e                	ld	s6,464(sp)
    80004ea8:	6bbe                	ld	s7,456(sp)
    80004eaa:	6c1e                	ld	s8,448(sp)
    80004eac:	7cfa                	ld	s9,440(sp)
    80004eae:	7d5a                	ld	s10,432(sp)
    80004eb0:	7dba                	ld	s11,424(sp)
    80004eb2:	21010113          	addi	sp,sp,528
    80004eb6:	8082                	ret
    end_op();
    80004eb8:	fffff097          	auipc	ra,0xfffff
    80004ebc:	470080e7          	jalr	1136(ra) # 80004328 <end_op>
    return -1;
    80004ec0:	557d                	li	a0,-1
    80004ec2:	bfc9                	j	80004e94 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004ec4:	854a                	mv	a0,s2
    80004ec6:	ffffd097          	auipc	ra,0xffffd
    80004eca:	bc4080e7          	jalr	-1084(ra) # 80001a8a <proc_pagetable>
    80004ece:	8baa                	mv	s7,a0
    80004ed0:	d945                	beqz	a0,80004e80 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ed2:	e7042983          	lw	s3,-400(s0)
    80004ed6:	e8845783          	lhu	a5,-376(s0)
    80004eda:	c7ad                	beqz	a5,80004f44 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004edc:	4a01                	li	s4,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ede:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004ee0:	6c85                	lui	s9,0x1
    80004ee2:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004ee6:	def43823          	sd	a5,-528(s0)
    80004eea:	ac0d                	j	8000511c <exec+0x320>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004eec:	00004517          	auipc	a0,0x4
    80004ef0:	9cc50513          	addi	a0,a0,-1588 # 800088b8 <syscalls+0x2c0>
    80004ef4:	ffffb097          	auipc	ra,0xffffb
    80004ef8:	650080e7          	jalr	1616(ra) # 80000544 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004efc:	8756                	mv	a4,s5
    80004efe:	012d86bb          	addw	a3,s11,s2
    80004f02:	4581                	li	a1,0
    80004f04:	8526                	mv	a0,s1
    80004f06:	fffff097          	auipc	ra,0xfffff
    80004f0a:	c94080e7          	jalr	-876(ra) # 80003b9a <readi>
    80004f0e:	2501                	sext.w	a0,a0
    80004f10:	1aaa9a63          	bne	s5,a0,800050c4 <exec+0x2c8>
  for(i = 0; i < sz; i += PGSIZE){
    80004f14:	6785                	lui	a5,0x1
    80004f16:	0127893b          	addw	s2,a5,s2
    80004f1a:	77fd                	lui	a5,0xfffff
    80004f1c:	01478a3b          	addw	s4,a5,s4
    80004f20:	1f897563          	bgeu	s2,s8,8000510a <exec+0x30e>
    pa = walkaddr(pagetable, va + i);
    80004f24:	02091593          	slli	a1,s2,0x20
    80004f28:	9181                	srli	a1,a1,0x20
    80004f2a:	95ea                	add	a1,a1,s10
    80004f2c:	855e                	mv	a0,s7
    80004f2e:	ffffc097          	auipc	ra,0xffffc
    80004f32:	14a080e7          	jalr	330(ra) # 80001078 <walkaddr>
    80004f36:	862a                	mv	a2,a0
    if(pa == 0)
    80004f38:	d955                	beqz	a0,80004eec <exec+0xf0>
      n = PGSIZE;
    80004f3a:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004f3c:	fd9a70e3          	bgeu	s4,s9,80004efc <exec+0x100>
      n = sz - i;
    80004f40:	8ad2                	mv	s5,s4
    80004f42:	bf6d                	j	80004efc <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004f44:	4a01                	li	s4,0
  iunlockput(ip);
    80004f46:	8526                	mv	a0,s1
    80004f48:	fffff097          	auipc	ra,0xfffff
    80004f4c:	c00080e7          	jalr	-1024(ra) # 80003b48 <iunlockput>
  end_op();
    80004f50:	fffff097          	auipc	ra,0xfffff
    80004f54:	3d8080e7          	jalr	984(ra) # 80004328 <end_op>
  p = myproc();
    80004f58:	ffffd097          	auipc	ra,0xffffd
    80004f5c:	a6e080e7          	jalr	-1426(ra) # 800019c6 <myproc>
    80004f60:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004f62:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004f66:	6785                	lui	a5,0x1
    80004f68:	17fd                	addi	a5,a5,-1
    80004f6a:	9a3e                	add	s4,s4,a5
    80004f6c:	757d                	lui	a0,0xfffff
    80004f6e:	00aa77b3          	and	a5,s4,a0
    80004f72:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004f76:	4691                	li	a3,4
    80004f78:	6609                	lui	a2,0x2
    80004f7a:	963e                	add	a2,a2,a5
    80004f7c:	85be                	mv	a1,a5
    80004f7e:	855e                	mv	a0,s7
    80004f80:	ffffc097          	auipc	ra,0xffffc
    80004f84:	4ac080e7          	jalr	1196(ra) # 8000142c <uvmalloc>
    80004f88:	8b2a                	mv	s6,a0
  ip = 0;
    80004f8a:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004f8c:	12050c63          	beqz	a0,800050c4 <exec+0x2c8>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004f90:	75f9                	lui	a1,0xffffe
    80004f92:	95aa                	add	a1,a1,a0
    80004f94:	855e                	mv	a0,s7
    80004f96:	ffffc097          	auipc	ra,0xffffc
    80004f9a:	6bc080e7          	jalr	1724(ra) # 80001652 <uvmclear>
  stackbase = sp - PGSIZE;
    80004f9e:	7c7d                	lui	s8,0xfffff
    80004fa0:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004fa2:	e0043783          	ld	a5,-512(s0)
    80004fa6:	6388                	ld	a0,0(a5)
    80004fa8:	c535                	beqz	a0,80005014 <exec+0x218>
    80004faa:	e9040993          	addi	s3,s0,-368
    80004fae:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004fb2:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004fb4:	ffffc097          	auipc	ra,0xffffc
    80004fb8:	eb6080e7          	jalr	-330(ra) # 80000e6a <strlen>
    80004fbc:	2505                	addiw	a0,a0,1
    80004fbe:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004fc2:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004fc6:	13896663          	bltu	s2,s8,800050f2 <exec+0x2f6>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004fca:	e0043d83          	ld	s11,-512(s0)
    80004fce:	000dba03          	ld	s4,0(s11)
    80004fd2:	8552                	mv	a0,s4
    80004fd4:	ffffc097          	auipc	ra,0xffffc
    80004fd8:	e96080e7          	jalr	-362(ra) # 80000e6a <strlen>
    80004fdc:	0015069b          	addiw	a3,a0,1
    80004fe0:	8652                	mv	a2,s4
    80004fe2:	85ca                	mv	a1,s2
    80004fe4:	855e                	mv	a0,s7
    80004fe6:	ffffc097          	auipc	ra,0xffffc
    80004fea:	69e080e7          	jalr	1694(ra) # 80001684 <copyout>
    80004fee:	10054663          	bltz	a0,800050fa <exec+0x2fe>
    ustack[argc] = sp;
    80004ff2:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004ff6:	0485                	addi	s1,s1,1
    80004ff8:	008d8793          	addi	a5,s11,8
    80004ffc:	e0f43023          	sd	a5,-512(s0)
    80005000:	008db503          	ld	a0,8(s11)
    80005004:	c911                	beqz	a0,80005018 <exec+0x21c>
    if(argc >= MAXARG)
    80005006:	09a1                	addi	s3,s3,8
    80005008:	fb3c96e3          	bne	s9,s3,80004fb4 <exec+0x1b8>
  sz = sz1;
    8000500c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005010:	4481                	li	s1,0
    80005012:	a84d                	j	800050c4 <exec+0x2c8>
  sp = sz;
    80005014:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005016:	4481                	li	s1,0
  ustack[argc] = 0;
    80005018:	00349793          	slli	a5,s1,0x3
    8000501c:	f9040713          	addi	a4,s0,-112
    80005020:	97ba                	add	a5,a5,a4
    80005022:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005026:	00148693          	addi	a3,s1,1
    8000502a:	068e                	slli	a3,a3,0x3
    8000502c:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005030:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005034:	01897663          	bgeu	s2,s8,80005040 <exec+0x244>
  sz = sz1;
    80005038:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000503c:	4481                	li	s1,0
    8000503e:	a059                	j	800050c4 <exec+0x2c8>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005040:	e9040613          	addi	a2,s0,-368
    80005044:	85ca                	mv	a1,s2
    80005046:	855e                	mv	a0,s7
    80005048:	ffffc097          	auipc	ra,0xffffc
    8000504c:	63c080e7          	jalr	1596(ra) # 80001684 <copyout>
    80005050:	0a054963          	bltz	a0,80005102 <exec+0x306>
  p->trapframe->a1 = sp;
    80005054:	058ab783          	ld	a5,88(s5)
    80005058:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000505c:	df843783          	ld	a5,-520(s0)
    80005060:	0007c703          	lbu	a4,0(a5)
    80005064:	cf11                	beqz	a4,80005080 <exec+0x284>
    80005066:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005068:	02f00693          	li	a3,47
    8000506c:	a039                	j	8000507a <exec+0x27e>
      last = s+1;
    8000506e:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005072:	0785                	addi	a5,a5,1
    80005074:	fff7c703          	lbu	a4,-1(a5)
    80005078:	c701                	beqz	a4,80005080 <exec+0x284>
    if(*s == '/')
    8000507a:	fed71ce3          	bne	a4,a3,80005072 <exec+0x276>
    8000507e:	bfc5                	j	8000506e <exec+0x272>
  safestrcpy(p->name, last, sizeof(p->name));
    80005080:	4641                	li	a2,16
    80005082:	df843583          	ld	a1,-520(s0)
    80005086:	158a8513          	addi	a0,s5,344
    8000508a:	ffffc097          	auipc	ra,0xffffc
    8000508e:	dae080e7          	jalr	-594(ra) # 80000e38 <safestrcpy>
  oldpagetable = p->pagetable;
    80005092:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005096:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    8000509a:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000509e:	058ab783          	ld	a5,88(s5)
    800050a2:	e6843703          	ld	a4,-408(s0)
    800050a6:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800050a8:	058ab783          	ld	a5,88(s5)
    800050ac:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800050b0:	85ea                	mv	a1,s10
    800050b2:	ffffd097          	auipc	ra,0xffffd
    800050b6:	a74080e7          	jalr	-1420(ra) # 80001b26 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800050ba:	0004851b          	sext.w	a0,s1
    800050be:	bbd9                	j	80004e94 <exec+0x98>
    800050c0:	e1443423          	sd	s4,-504(s0)
    proc_freepagetable(pagetable, sz);
    800050c4:	e0843583          	ld	a1,-504(s0)
    800050c8:	855e                	mv	a0,s7
    800050ca:	ffffd097          	auipc	ra,0xffffd
    800050ce:	a5c080e7          	jalr	-1444(ra) # 80001b26 <proc_freepagetable>
  if(ip){
    800050d2:	da0497e3          	bnez	s1,80004e80 <exec+0x84>
  return -1;
    800050d6:	557d                	li	a0,-1
    800050d8:	bb75                	j	80004e94 <exec+0x98>
    800050da:	e1443423          	sd	s4,-504(s0)
    800050de:	b7dd                	j	800050c4 <exec+0x2c8>
    800050e0:	e1443423          	sd	s4,-504(s0)
    800050e4:	b7c5                	j	800050c4 <exec+0x2c8>
    800050e6:	e1443423          	sd	s4,-504(s0)
    800050ea:	bfe9                	j	800050c4 <exec+0x2c8>
    800050ec:	e1443423          	sd	s4,-504(s0)
    800050f0:	bfd1                	j	800050c4 <exec+0x2c8>
  sz = sz1;
    800050f2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050f6:	4481                	li	s1,0
    800050f8:	b7f1                	j	800050c4 <exec+0x2c8>
  sz = sz1;
    800050fa:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050fe:	4481                	li	s1,0
    80005100:	b7d1                	j	800050c4 <exec+0x2c8>
  sz = sz1;
    80005102:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005106:	4481                	li	s1,0
    80005108:	bf75                	j	800050c4 <exec+0x2c8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000510a:	e0843a03          	ld	s4,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000510e:	2b05                	addiw	s6,s6,1
    80005110:	0389899b          	addiw	s3,s3,56
    80005114:	e8845783          	lhu	a5,-376(s0)
    80005118:	e2fb57e3          	bge	s6,a5,80004f46 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000511c:	2981                	sext.w	s3,s3
    8000511e:	03800713          	li	a4,56
    80005122:	86ce                	mv	a3,s3
    80005124:	e1840613          	addi	a2,s0,-488
    80005128:	4581                	li	a1,0
    8000512a:	8526                	mv	a0,s1
    8000512c:	fffff097          	auipc	ra,0xfffff
    80005130:	a6e080e7          	jalr	-1426(ra) # 80003b9a <readi>
    80005134:	03800793          	li	a5,56
    80005138:	f8f514e3          	bne	a0,a5,800050c0 <exec+0x2c4>
    if(ph.type != ELF_PROG_LOAD)
    8000513c:	e1842783          	lw	a5,-488(s0)
    80005140:	4705                	li	a4,1
    80005142:	fce796e3          	bne	a5,a4,8000510e <exec+0x312>
    if(ph.memsz < ph.filesz)
    80005146:	e4043903          	ld	s2,-448(s0)
    8000514a:	e3843783          	ld	a5,-456(s0)
    8000514e:	f8f966e3          	bltu	s2,a5,800050da <exec+0x2de>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005152:	e2843783          	ld	a5,-472(s0)
    80005156:	993e                	add	s2,s2,a5
    80005158:	f8f964e3          	bltu	s2,a5,800050e0 <exec+0x2e4>
    if(ph.vaddr % PGSIZE != 0)
    8000515c:	df043703          	ld	a4,-528(s0)
    80005160:	8ff9                	and	a5,a5,a4
    80005162:	f3d1                	bnez	a5,800050e6 <exec+0x2ea>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005164:	e1c42503          	lw	a0,-484(s0)
    80005168:	00000097          	auipc	ra,0x0
    8000516c:	c78080e7          	jalr	-904(ra) # 80004de0 <flags2perm>
    80005170:	86aa                	mv	a3,a0
    80005172:	864a                	mv	a2,s2
    80005174:	85d2                	mv	a1,s4
    80005176:	855e                	mv	a0,s7
    80005178:	ffffc097          	auipc	ra,0xffffc
    8000517c:	2b4080e7          	jalr	692(ra) # 8000142c <uvmalloc>
    80005180:	e0a43423          	sd	a0,-504(s0)
    80005184:	d525                	beqz	a0,800050ec <exec+0x2f0>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005186:	e2843d03          	ld	s10,-472(s0)
    8000518a:	e2042d83          	lw	s11,-480(s0)
    8000518e:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005192:	f60c0ce3          	beqz	s8,8000510a <exec+0x30e>
    80005196:	8a62                	mv	s4,s8
    80005198:	4901                	li	s2,0
    8000519a:	b369                	j	80004f24 <exec+0x128>

000000008000519c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000519c:	7179                	addi	sp,sp,-48
    8000519e:	f406                	sd	ra,40(sp)
    800051a0:	f022                	sd	s0,32(sp)
    800051a2:	ec26                	sd	s1,24(sp)
    800051a4:	e84a                	sd	s2,16(sp)
    800051a6:	1800                	addi	s0,sp,48
    800051a8:	892e                	mv	s2,a1
    800051aa:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800051ac:	fdc40593          	addi	a1,s0,-36
    800051b0:	ffffe097          	auipc	ra,0xffffe
    800051b4:	a0e080e7          	jalr	-1522(ra) # 80002bbe <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800051b8:	fdc42703          	lw	a4,-36(s0)
    800051bc:	47bd                	li	a5,15
    800051be:	02e7eb63          	bltu	a5,a4,800051f4 <argfd+0x58>
    800051c2:	ffffd097          	auipc	ra,0xffffd
    800051c6:	804080e7          	jalr	-2044(ra) # 800019c6 <myproc>
    800051ca:	fdc42703          	lw	a4,-36(s0)
    800051ce:	01a70793          	addi	a5,a4,26
    800051d2:	078e                	slli	a5,a5,0x3
    800051d4:	953e                	add	a0,a0,a5
    800051d6:	611c                	ld	a5,0(a0)
    800051d8:	c385                	beqz	a5,800051f8 <argfd+0x5c>
    return -1;
  if(pfd)
    800051da:	00090463          	beqz	s2,800051e2 <argfd+0x46>
    *pfd = fd;
    800051de:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800051e2:	4501                	li	a0,0
  if(pf)
    800051e4:	c091                	beqz	s1,800051e8 <argfd+0x4c>
    *pf = f;
    800051e6:	e09c                	sd	a5,0(s1)
}
    800051e8:	70a2                	ld	ra,40(sp)
    800051ea:	7402                	ld	s0,32(sp)
    800051ec:	64e2                	ld	s1,24(sp)
    800051ee:	6942                	ld	s2,16(sp)
    800051f0:	6145                	addi	sp,sp,48
    800051f2:	8082                	ret
    return -1;
    800051f4:	557d                	li	a0,-1
    800051f6:	bfcd                	j	800051e8 <argfd+0x4c>
    800051f8:	557d                	li	a0,-1
    800051fa:	b7fd                	j	800051e8 <argfd+0x4c>

00000000800051fc <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800051fc:	1101                	addi	sp,sp,-32
    800051fe:	ec06                	sd	ra,24(sp)
    80005200:	e822                	sd	s0,16(sp)
    80005202:	e426                	sd	s1,8(sp)
    80005204:	1000                	addi	s0,sp,32
    80005206:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005208:	ffffc097          	auipc	ra,0xffffc
    8000520c:	7be080e7          	jalr	1982(ra) # 800019c6 <myproc>
    80005210:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005212:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd4de8>
    80005216:	4501                	li	a0,0
    80005218:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000521a:	6398                	ld	a4,0(a5)
    8000521c:	cb19                	beqz	a4,80005232 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000521e:	2505                	addiw	a0,a0,1
    80005220:	07a1                	addi	a5,a5,8
    80005222:	fed51ce3          	bne	a0,a3,8000521a <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005226:	557d                	li	a0,-1
}
    80005228:	60e2                	ld	ra,24(sp)
    8000522a:	6442                	ld	s0,16(sp)
    8000522c:	64a2                	ld	s1,8(sp)
    8000522e:	6105                	addi	sp,sp,32
    80005230:	8082                	ret
      p->ofile[fd] = f;
    80005232:	01a50793          	addi	a5,a0,26
    80005236:	078e                	slli	a5,a5,0x3
    80005238:	963e                	add	a2,a2,a5
    8000523a:	e204                	sd	s1,0(a2)
      return fd;
    8000523c:	b7f5                	j	80005228 <fdalloc+0x2c>

000000008000523e <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000523e:	715d                	addi	sp,sp,-80
    80005240:	e486                	sd	ra,72(sp)
    80005242:	e0a2                	sd	s0,64(sp)
    80005244:	fc26                	sd	s1,56(sp)
    80005246:	f84a                	sd	s2,48(sp)
    80005248:	f44e                	sd	s3,40(sp)
    8000524a:	f052                	sd	s4,32(sp)
    8000524c:	ec56                	sd	s5,24(sp)
    8000524e:	e85a                	sd	s6,16(sp)
    80005250:	0880                	addi	s0,sp,80
    80005252:	8b2e                	mv	s6,a1
    80005254:	89b2                	mv	s3,a2
    80005256:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005258:	fb040593          	addi	a1,s0,-80
    8000525c:	fffff097          	auipc	ra,0xfffff
    80005260:	e4e080e7          	jalr	-434(ra) # 800040aa <nameiparent>
    80005264:	84aa                	mv	s1,a0
    80005266:	16050063          	beqz	a0,800053c6 <create+0x188>
    return 0;

  ilock(dp);
    8000526a:	ffffe097          	auipc	ra,0xffffe
    8000526e:	67c080e7          	jalr	1660(ra) # 800038e6 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005272:	4601                	li	a2,0
    80005274:	fb040593          	addi	a1,s0,-80
    80005278:	8526                	mv	a0,s1
    8000527a:	fffff097          	auipc	ra,0xfffff
    8000527e:	b50080e7          	jalr	-1200(ra) # 80003dca <dirlookup>
    80005282:	8aaa                	mv	s5,a0
    80005284:	c931                	beqz	a0,800052d8 <create+0x9a>
    iunlockput(dp);
    80005286:	8526                	mv	a0,s1
    80005288:	fffff097          	auipc	ra,0xfffff
    8000528c:	8c0080e7          	jalr	-1856(ra) # 80003b48 <iunlockput>
    ilock(ip);
    80005290:	8556                	mv	a0,s5
    80005292:	ffffe097          	auipc	ra,0xffffe
    80005296:	654080e7          	jalr	1620(ra) # 800038e6 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000529a:	000b059b          	sext.w	a1,s6
    8000529e:	4789                	li	a5,2
    800052a0:	02f59563          	bne	a1,a5,800052ca <create+0x8c>
    800052a4:	044ad783          	lhu	a5,68(s5)
    800052a8:	37f9                	addiw	a5,a5,-2
    800052aa:	17c2                	slli	a5,a5,0x30
    800052ac:	93c1                	srli	a5,a5,0x30
    800052ae:	4705                	li	a4,1
    800052b0:	00f76d63          	bltu	a4,a5,800052ca <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800052b4:	8556                	mv	a0,s5
    800052b6:	60a6                	ld	ra,72(sp)
    800052b8:	6406                	ld	s0,64(sp)
    800052ba:	74e2                	ld	s1,56(sp)
    800052bc:	7942                	ld	s2,48(sp)
    800052be:	79a2                	ld	s3,40(sp)
    800052c0:	7a02                	ld	s4,32(sp)
    800052c2:	6ae2                	ld	s5,24(sp)
    800052c4:	6b42                	ld	s6,16(sp)
    800052c6:	6161                	addi	sp,sp,80
    800052c8:	8082                	ret
    iunlockput(ip);
    800052ca:	8556                	mv	a0,s5
    800052cc:	fffff097          	auipc	ra,0xfffff
    800052d0:	87c080e7          	jalr	-1924(ra) # 80003b48 <iunlockput>
    return 0;
    800052d4:	4a81                	li	s5,0
    800052d6:	bff9                	j	800052b4 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800052d8:	85da                	mv	a1,s6
    800052da:	4088                	lw	a0,0(s1)
    800052dc:	ffffe097          	auipc	ra,0xffffe
    800052e0:	46e080e7          	jalr	1134(ra) # 8000374a <ialloc>
    800052e4:	8a2a                	mv	s4,a0
    800052e6:	c921                	beqz	a0,80005336 <create+0xf8>
  ilock(ip);
    800052e8:	ffffe097          	auipc	ra,0xffffe
    800052ec:	5fe080e7          	jalr	1534(ra) # 800038e6 <ilock>
  ip->major = major;
    800052f0:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800052f4:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800052f8:	4785                	li	a5,1
    800052fa:	04fa1523          	sh	a5,74(s4)
  iupdate(ip);
    800052fe:	8552                	mv	a0,s4
    80005300:	ffffe097          	auipc	ra,0xffffe
    80005304:	51c080e7          	jalr	1308(ra) # 8000381c <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005308:	000b059b          	sext.w	a1,s6
    8000530c:	4785                	li	a5,1
    8000530e:	02f58b63          	beq	a1,a5,80005344 <create+0x106>
  if(dirlink(dp, name, ip->inum) < 0)
    80005312:	004a2603          	lw	a2,4(s4)
    80005316:	fb040593          	addi	a1,s0,-80
    8000531a:	8526                	mv	a0,s1
    8000531c:	fffff097          	auipc	ra,0xfffff
    80005320:	cbe080e7          	jalr	-834(ra) # 80003fda <dirlink>
    80005324:	06054f63          	bltz	a0,800053a2 <create+0x164>
  iunlockput(dp);
    80005328:	8526                	mv	a0,s1
    8000532a:	fffff097          	auipc	ra,0xfffff
    8000532e:	81e080e7          	jalr	-2018(ra) # 80003b48 <iunlockput>
  return ip;
    80005332:	8ad2                	mv	s5,s4
    80005334:	b741                	j	800052b4 <create+0x76>
    iunlockput(dp);
    80005336:	8526                	mv	a0,s1
    80005338:	fffff097          	auipc	ra,0xfffff
    8000533c:	810080e7          	jalr	-2032(ra) # 80003b48 <iunlockput>
    return 0;
    80005340:	8ad2                	mv	s5,s4
    80005342:	bf8d                	j	800052b4 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005344:	004a2603          	lw	a2,4(s4)
    80005348:	00003597          	auipc	a1,0x3
    8000534c:	59058593          	addi	a1,a1,1424 # 800088d8 <syscalls+0x2e0>
    80005350:	8552                	mv	a0,s4
    80005352:	fffff097          	auipc	ra,0xfffff
    80005356:	c88080e7          	jalr	-888(ra) # 80003fda <dirlink>
    8000535a:	04054463          	bltz	a0,800053a2 <create+0x164>
    8000535e:	40d0                	lw	a2,4(s1)
    80005360:	00003597          	auipc	a1,0x3
    80005364:	58058593          	addi	a1,a1,1408 # 800088e0 <syscalls+0x2e8>
    80005368:	8552                	mv	a0,s4
    8000536a:	fffff097          	auipc	ra,0xfffff
    8000536e:	c70080e7          	jalr	-912(ra) # 80003fda <dirlink>
    80005372:	02054863          	bltz	a0,800053a2 <create+0x164>
  if(dirlink(dp, name, ip->inum) < 0)
    80005376:	004a2603          	lw	a2,4(s4)
    8000537a:	fb040593          	addi	a1,s0,-80
    8000537e:	8526                	mv	a0,s1
    80005380:	fffff097          	auipc	ra,0xfffff
    80005384:	c5a080e7          	jalr	-934(ra) # 80003fda <dirlink>
    80005388:	00054d63          	bltz	a0,800053a2 <create+0x164>
    dp->nlink++;  // for ".."
    8000538c:	04a4d783          	lhu	a5,74(s1)
    80005390:	2785                	addiw	a5,a5,1
    80005392:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005396:	8526                	mv	a0,s1
    80005398:	ffffe097          	auipc	ra,0xffffe
    8000539c:	484080e7          	jalr	1156(ra) # 8000381c <iupdate>
    800053a0:	b761                	j	80005328 <create+0xea>
  ip->nlink = 0;
    800053a2:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800053a6:	8552                	mv	a0,s4
    800053a8:	ffffe097          	auipc	ra,0xffffe
    800053ac:	474080e7          	jalr	1140(ra) # 8000381c <iupdate>
  iunlockput(ip);
    800053b0:	8552                	mv	a0,s4
    800053b2:	ffffe097          	auipc	ra,0xffffe
    800053b6:	796080e7          	jalr	1942(ra) # 80003b48 <iunlockput>
  iunlockput(dp);
    800053ba:	8526                	mv	a0,s1
    800053bc:	ffffe097          	auipc	ra,0xffffe
    800053c0:	78c080e7          	jalr	1932(ra) # 80003b48 <iunlockput>
  return 0;
    800053c4:	bdc5                	j	800052b4 <create+0x76>
    return 0;
    800053c6:	8aaa                	mv	s5,a0
    800053c8:	b5f5                	j	800052b4 <create+0x76>

00000000800053ca <sys_dup>:
{
    800053ca:	7179                	addi	sp,sp,-48
    800053cc:	f406                	sd	ra,40(sp)
    800053ce:	f022                	sd	s0,32(sp)
    800053d0:	ec26                	sd	s1,24(sp)
    800053d2:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800053d4:	fd840613          	addi	a2,s0,-40
    800053d8:	4581                	li	a1,0
    800053da:	4501                	li	a0,0
    800053dc:	00000097          	auipc	ra,0x0
    800053e0:	dc0080e7          	jalr	-576(ra) # 8000519c <argfd>
    return -1;
    800053e4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800053e6:	02054363          	bltz	a0,8000540c <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800053ea:	fd843503          	ld	a0,-40(s0)
    800053ee:	00000097          	auipc	ra,0x0
    800053f2:	e0e080e7          	jalr	-498(ra) # 800051fc <fdalloc>
    800053f6:	84aa                	mv	s1,a0
    return -1;
    800053f8:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800053fa:	00054963          	bltz	a0,8000540c <sys_dup+0x42>
  filedup(f);
    800053fe:	fd843503          	ld	a0,-40(s0)
    80005402:	fffff097          	auipc	ra,0xfffff
    80005406:	320080e7          	jalr	800(ra) # 80004722 <filedup>
  return fd;
    8000540a:	87a6                	mv	a5,s1
}
    8000540c:	853e                	mv	a0,a5
    8000540e:	70a2                	ld	ra,40(sp)
    80005410:	7402                	ld	s0,32(sp)
    80005412:	64e2                	ld	s1,24(sp)
    80005414:	6145                	addi	sp,sp,48
    80005416:	8082                	ret

0000000080005418 <sys_read>:
{
    80005418:	7179                	addi	sp,sp,-48
    8000541a:	f406                	sd	ra,40(sp)
    8000541c:	f022                	sd	s0,32(sp)
    8000541e:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005420:	fd840593          	addi	a1,s0,-40
    80005424:	4505                	li	a0,1
    80005426:	ffffd097          	auipc	ra,0xffffd
    8000542a:	7b8080e7          	jalr	1976(ra) # 80002bde <argaddr>
  argint(2, &n);
    8000542e:	fe440593          	addi	a1,s0,-28
    80005432:	4509                	li	a0,2
    80005434:	ffffd097          	auipc	ra,0xffffd
    80005438:	78a080e7          	jalr	1930(ra) # 80002bbe <argint>
  if(argfd(0, 0, &f) < 0)
    8000543c:	fe840613          	addi	a2,s0,-24
    80005440:	4581                	li	a1,0
    80005442:	4501                	li	a0,0
    80005444:	00000097          	auipc	ra,0x0
    80005448:	d58080e7          	jalr	-680(ra) # 8000519c <argfd>
    8000544c:	87aa                	mv	a5,a0
    return -1;
    8000544e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005450:	0007cc63          	bltz	a5,80005468 <sys_read+0x50>
  return fileread(f, p, n);
    80005454:	fe442603          	lw	a2,-28(s0)
    80005458:	fd843583          	ld	a1,-40(s0)
    8000545c:	fe843503          	ld	a0,-24(s0)
    80005460:	fffff097          	auipc	ra,0xfffff
    80005464:	44e080e7          	jalr	1102(ra) # 800048ae <fileread>
}
    80005468:	70a2                	ld	ra,40(sp)
    8000546a:	7402                	ld	s0,32(sp)
    8000546c:	6145                	addi	sp,sp,48
    8000546e:	8082                	ret

0000000080005470 <sys_write>:
{
    80005470:	7179                	addi	sp,sp,-48
    80005472:	f406                	sd	ra,40(sp)
    80005474:	f022                	sd	s0,32(sp)
    80005476:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005478:	fd840593          	addi	a1,s0,-40
    8000547c:	4505                	li	a0,1
    8000547e:	ffffd097          	auipc	ra,0xffffd
    80005482:	760080e7          	jalr	1888(ra) # 80002bde <argaddr>
  argint(2, &n);
    80005486:	fe440593          	addi	a1,s0,-28
    8000548a:	4509                	li	a0,2
    8000548c:	ffffd097          	auipc	ra,0xffffd
    80005490:	732080e7          	jalr	1842(ra) # 80002bbe <argint>
  if(argfd(0, 0, &f) < 0)
    80005494:	fe840613          	addi	a2,s0,-24
    80005498:	4581                	li	a1,0
    8000549a:	4501                	li	a0,0
    8000549c:	00000097          	auipc	ra,0x0
    800054a0:	d00080e7          	jalr	-768(ra) # 8000519c <argfd>
    800054a4:	87aa                	mv	a5,a0
    return -1;
    800054a6:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800054a8:	0007cc63          	bltz	a5,800054c0 <sys_write+0x50>
  return filewrite(f, p, n);
    800054ac:	fe442603          	lw	a2,-28(s0)
    800054b0:	fd843583          	ld	a1,-40(s0)
    800054b4:	fe843503          	ld	a0,-24(s0)
    800054b8:	fffff097          	auipc	ra,0xfffff
    800054bc:	4b8080e7          	jalr	1208(ra) # 80004970 <filewrite>
}
    800054c0:	70a2                	ld	ra,40(sp)
    800054c2:	7402                	ld	s0,32(sp)
    800054c4:	6145                	addi	sp,sp,48
    800054c6:	8082                	ret

00000000800054c8 <sys_close>:
{
    800054c8:	1101                	addi	sp,sp,-32
    800054ca:	ec06                	sd	ra,24(sp)
    800054cc:	e822                	sd	s0,16(sp)
    800054ce:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800054d0:	fe040613          	addi	a2,s0,-32
    800054d4:	fec40593          	addi	a1,s0,-20
    800054d8:	4501                	li	a0,0
    800054da:	00000097          	auipc	ra,0x0
    800054de:	cc2080e7          	jalr	-830(ra) # 8000519c <argfd>
    return -1;
    800054e2:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800054e4:	02054463          	bltz	a0,8000550c <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800054e8:	ffffc097          	auipc	ra,0xffffc
    800054ec:	4de080e7          	jalr	1246(ra) # 800019c6 <myproc>
    800054f0:	fec42783          	lw	a5,-20(s0)
    800054f4:	07e9                	addi	a5,a5,26
    800054f6:	078e                	slli	a5,a5,0x3
    800054f8:	97aa                	add	a5,a5,a0
    800054fa:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800054fe:	fe043503          	ld	a0,-32(s0)
    80005502:	fffff097          	auipc	ra,0xfffff
    80005506:	272080e7          	jalr	626(ra) # 80004774 <fileclose>
  return 0;
    8000550a:	4781                	li	a5,0
}
    8000550c:	853e                	mv	a0,a5
    8000550e:	60e2                	ld	ra,24(sp)
    80005510:	6442                	ld	s0,16(sp)
    80005512:	6105                	addi	sp,sp,32
    80005514:	8082                	ret

0000000080005516 <sys_fstat>:
{
    80005516:	1101                	addi	sp,sp,-32
    80005518:	ec06                	sd	ra,24(sp)
    8000551a:	e822                	sd	s0,16(sp)
    8000551c:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    8000551e:	fe040593          	addi	a1,s0,-32
    80005522:	4505                	li	a0,1
    80005524:	ffffd097          	auipc	ra,0xffffd
    80005528:	6ba080e7          	jalr	1722(ra) # 80002bde <argaddr>
  if(argfd(0, 0, &f) < 0)
    8000552c:	fe840613          	addi	a2,s0,-24
    80005530:	4581                	li	a1,0
    80005532:	4501                	li	a0,0
    80005534:	00000097          	auipc	ra,0x0
    80005538:	c68080e7          	jalr	-920(ra) # 8000519c <argfd>
    8000553c:	87aa                	mv	a5,a0
    return -1;
    8000553e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005540:	0007ca63          	bltz	a5,80005554 <sys_fstat+0x3e>
  return filestat(f, st);
    80005544:	fe043583          	ld	a1,-32(s0)
    80005548:	fe843503          	ld	a0,-24(s0)
    8000554c:	fffff097          	auipc	ra,0xfffff
    80005550:	2f0080e7          	jalr	752(ra) # 8000483c <filestat>
}
    80005554:	60e2                	ld	ra,24(sp)
    80005556:	6442                	ld	s0,16(sp)
    80005558:	6105                	addi	sp,sp,32
    8000555a:	8082                	ret

000000008000555c <sys_link>:
{
    8000555c:	7169                	addi	sp,sp,-304
    8000555e:	f606                	sd	ra,296(sp)
    80005560:	f222                	sd	s0,288(sp)
    80005562:	ee26                	sd	s1,280(sp)
    80005564:	ea4a                	sd	s2,272(sp)
    80005566:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005568:	08000613          	li	a2,128
    8000556c:	ed040593          	addi	a1,s0,-304
    80005570:	4501                	li	a0,0
    80005572:	ffffd097          	auipc	ra,0xffffd
    80005576:	68c080e7          	jalr	1676(ra) # 80002bfe <argstr>
    return -1;
    8000557a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000557c:	10054e63          	bltz	a0,80005698 <sys_link+0x13c>
    80005580:	08000613          	li	a2,128
    80005584:	f5040593          	addi	a1,s0,-176
    80005588:	4505                	li	a0,1
    8000558a:	ffffd097          	auipc	ra,0xffffd
    8000558e:	674080e7          	jalr	1652(ra) # 80002bfe <argstr>
    return -1;
    80005592:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005594:	10054263          	bltz	a0,80005698 <sys_link+0x13c>
  begin_op();
    80005598:	fffff097          	auipc	ra,0xfffff
    8000559c:	d10080e7          	jalr	-752(ra) # 800042a8 <begin_op>
  if((ip = namei(old)) == 0){
    800055a0:	ed040513          	addi	a0,s0,-304
    800055a4:	fffff097          	auipc	ra,0xfffff
    800055a8:	ae8080e7          	jalr	-1304(ra) # 8000408c <namei>
    800055ac:	84aa                	mv	s1,a0
    800055ae:	c551                	beqz	a0,8000563a <sys_link+0xde>
  ilock(ip);
    800055b0:	ffffe097          	auipc	ra,0xffffe
    800055b4:	336080e7          	jalr	822(ra) # 800038e6 <ilock>
  if(ip->type == T_DIR){
    800055b8:	04449703          	lh	a4,68(s1)
    800055bc:	4785                	li	a5,1
    800055be:	08f70463          	beq	a4,a5,80005646 <sys_link+0xea>
  ip->nlink++;
    800055c2:	04a4d783          	lhu	a5,74(s1)
    800055c6:	2785                	addiw	a5,a5,1
    800055c8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055cc:	8526                	mv	a0,s1
    800055ce:	ffffe097          	auipc	ra,0xffffe
    800055d2:	24e080e7          	jalr	590(ra) # 8000381c <iupdate>
  iunlock(ip);
    800055d6:	8526                	mv	a0,s1
    800055d8:	ffffe097          	auipc	ra,0xffffe
    800055dc:	3d0080e7          	jalr	976(ra) # 800039a8 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800055e0:	fd040593          	addi	a1,s0,-48
    800055e4:	f5040513          	addi	a0,s0,-176
    800055e8:	fffff097          	auipc	ra,0xfffff
    800055ec:	ac2080e7          	jalr	-1342(ra) # 800040aa <nameiparent>
    800055f0:	892a                	mv	s2,a0
    800055f2:	c935                	beqz	a0,80005666 <sys_link+0x10a>
  ilock(dp);
    800055f4:	ffffe097          	auipc	ra,0xffffe
    800055f8:	2f2080e7          	jalr	754(ra) # 800038e6 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800055fc:	00092703          	lw	a4,0(s2)
    80005600:	409c                	lw	a5,0(s1)
    80005602:	04f71d63          	bne	a4,a5,8000565c <sys_link+0x100>
    80005606:	40d0                	lw	a2,4(s1)
    80005608:	fd040593          	addi	a1,s0,-48
    8000560c:	854a                	mv	a0,s2
    8000560e:	fffff097          	auipc	ra,0xfffff
    80005612:	9cc080e7          	jalr	-1588(ra) # 80003fda <dirlink>
    80005616:	04054363          	bltz	a0,8000565c <sys_link+0x100>
  iunlockput(dp);
    8000561a:	854a                	mv	a0,s2
    8000561c:	ffffe097          	auipc	ra,0xffffe
    80005620:	52c080e7          	jalr	1324(ra) # 80003b48 <iunlockput>
  iput(ip);
    80005624:	8526                	mv	a0,s1
    80005626:	ffffe097          	auipc	ra,0xffffe
    8000562a:	47a080e7          	jalr	1146(ra) # 80003aa0 <iput>
  end_op();
    8000562e:	fffff097          	auipc	ra,0xfffff
    80005632:	cfa080e7          	jalr	-774(ra) # 80004328 <end_op>
  return 0;
    80005636:	4781                	li	a5,0
    80005638:	a085                	j	80005698 <sys_link+0x13c>
    end_op();
    8000563a:	fffff097          	auipc	ra,0xfffff
    8000563e:	cee080e7          	jalr	-786(ra) # 80004328 <end_op>
    return -1;
    80005642:	57fd                	li	a5,-1
    80005644:	a891                	j	80005698 <sys_link+0x13c>
    iunlockput(ip);
    80005646:	8526                	mv	a0,s1
    80005648:	ffffe097          	auipc	ra,0xffffe
    8000564c:	500080e7          	jalr	1280(ra) # 80003b48 <iunlockput>
    end_op();
    80005650:	fffff097          	auipc	ra,0xfffff
    80005654:	cd8080e7          	jalr	-808(ra) # 80004328 <end_op>
    return -1;
    80005658:	57fd                	li	a5,-1
    8000565a:	a83d                	j	80005698 <sys_link+0x13c>
    iunlockput(dp);
    8000565c:	854a                	mv	a0,s2
    8000565e:	ffffe097          	auipc	ra,0xffffe
    80005662:	4ea080e7          	jalr	1258(ra) # 80003b48 <iunlockput>
  ilock(ip);
    80005666:	8526                	mv	a0,s1
    80005668:	ffffe097          	auipc	ra,0xffffe
    8000566c:	27e080e7          	jalr	638(ra) # 800038e6 <ilock>
  ip->nlink--;
    80005670:	04a4d783          	lhu	a5,74(s1)
    80005674:	37fd                	addiw	a5,a5,-1
    80005676:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000567a:	8526                	mv	a0,s1
    8000567c:	ffffe097          	auipc	ra,0xffffe
    80005680:	1a0080e7          	jalr	416(ra) # 8000381c <iupdate>
  iunlockput(ip);
    80005684:	8526                	mv	a0,s1
    80005686:	ffffe097          	auipc	ra,0xffffe
    8000568a:	4c2080e7          	jalr	1218(ra) # 80003b48 <iunlockput>
  end_op();
    8000568e:	fffff097          	auipc	ra,0xfffff
    80005692:	c9a080e7          	jalr	-870(ra) # 80004328 <end_op>
  return -1;
    80005696:	57fd                	li	a5,-1
}
    80005698:	853e                	mv	a0,a5
    8000569a:	70b2                	ld	ra,296(sp)
    8000569c:	7412                	ld	s0,288(sp)
    8000569e:	64f2                	ld	s1,280(sp)
    800056a0:	6952                	ld	s2,272(sp)
    800056a2:	6155                	addi	sp,sp,304
    800056a4:	8082                	ret

00000000800056a6 <sys_unlink>:
{
    800056a6:	7151                	addi	sp,sp,-240
    800056a8:	f586                	sd	ra,232(sp)
    800056aa:	f1a2                	sd	s0,224(sp)
    800056ac:	eda6                	sd	s1,216(sp)
    800056ae:	e9ca                	sd	s2,208(sp)
    800056b0:	e5ce                	sd	s3,200(sp)
    800056b2:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800056b4:	08000613          	li	a2,128
    800056b8:	f3040593          	addi	a1,s0,-208
    800056bc:	4501                	li	a0,0
    800056be:	ffffd097          	auipc	ra,0xffffd
    800056c2:	540080e7          	jalr	1344(ra) # 80002bfe <argstr>
    800056c6:	18054163          	bltz	a0,80005848 <sys_unlink+0x1a2>
  begin_op();
    800056ca:	fffff097          	auipc	ra,0xfffff
    800056ce:	bde080e7          	jalr	-1058(ra) # 800042a8 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800056d2:	fb040593          	addi	a1,s0,-80
    800056d6:	f3040513          	addi	a0,s0,-208
    800056da:	fffff097          	auipc	ra,0xfffff
    800056de:	9d0080e7          	jalr	-1584(ra) # 800040aa <nameiparent>
    800056e2:	84aa                	mv	s1,a0
    800056e4:	c979                	beqz	a0,800057ba <sys_unlink+0x114>
  ilock(dp);
    800056e6:	ffffe097          	auipc	ra,0xffffe
    800056ea:	200080e7          	jalr	512(ra) # 800038e6 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800056ee:	00003597          	auipc	a1,0x3
    800056f2:	1ea58593          	addi	a1,a1,490 # 800088d8 <syscalls+0x2e0>
    800056f6:	fb040513          	addi	a0,s0,-80
    800056fa:	ffffe097          	auipc	ra,0xffffe
    800056fe:	6b6080e7          	jalr	1718(ra) # 80003db0 <namecmp>
    80005702:	14050a63          	beqz	a0,80005856 <sys_unlink+0x1b0>
    80005706:	00003597          	auipc	a1,0x3
    8000570a:	1da58593          	addi	a1,a1,474 # 800088e0 <syscalls+0x2e8>
    8000570e:	fb040513          	addi	a0,s0,-80
    80005712:	ffffe097          	auipc	ra,0xffffe
    80005716:	69e080e7          	jalr	1694(ra) # 80003db0 <namecmp>
    8000571a:	12050e63          	beqz	a0,80005856 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000571e:	f2c40613          	addi	a2,s0,-212
    80005722:	fb040593          	addi	a1,s0,-80
    80005726:	8526                	mv	a0,s1
    80005728:	ffffe097          	auipc	ra,0xffffe
    8000572c:	6a2080e7          	jalr	1698(ra) # 80003dca <dirlookup>
    80005730:	892a                	mv	s2,a0
    80005732:	12050263          	beqz	a0,80005856 <sys_unlink+0x1b0>
  ilock(ip);
    80005736:	ffffe097          	auipc	ra,0xffffe
    8000573a:	1b0080e7          	jalr	432(ra) # 800038e6 <ilock>
  if(ip->nlink < 1)
    8000573e:	04a91783          	lh	a5,74(s2)
    80005742:	08f05263          	blez	a5,800057c6 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005746:	04491703          	lh	a4,68(s2)
    8000574a:	4785                	li	a5,1
    8000574c:	08f70563          	beq	a4,a5,800057d6 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005750:	4641                	li	a2,16
    80005752:	4581                	li	a1,0
    80005754:	fc040513          	addi	a0,s0,-64
    80005758:	ffffb097          	auipc	ra,0xffffb
    8000575c:	58e080e7          	jalr	1422(ra) # 80000ce6 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005760:	4741                	li	a4,16
    80005762:	f2c42683          	lw	a3,-212(s0)
    80005766:	fc040613          	addi	a2,s0,-64
    8000576a:	4581                	li	a1,0
    8000576c:	8526                	mv	a0,s1
    8000576e:	ffffe097          	auipc	ra,0xffffe
    80005772:	524080e7          	jalr	1316(ra) # 80003c92 <writei>
    80005776:	47c1                	li	a5,16
    80005778:	0af51563          	bne	a0,a5,80005822 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000577c:	04491703          	lh	a4,68(s2)
    80005780:	4785                	li	a5,1
    80005782:	0af70863          	beq	a4,a5,80005832 <sys_unlink+0x18c>
  iunlockput(dp);
    80005786:	8526                	mv	a0,s1
    80005788:	ffffe097          	auipc	ra,0xffffe
    8000578c:	3c0080e7          	jalr	960(ra) # 80003b48 <iunlockput>
  ip->nlink--;
    80005790:	04a95783          	lhu	a5,74(s2)
    80005794:	37fd                	addiw	a5,a5,-1
    80005796:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000579a:	854a                	mv	a0,s2
    8000579c:	ffffe097          	auipc	ra,0xffffe
    800057a0:	080080e7          	jalr	128(ra) # 8000381c <iupdate>
  iunlockput(ip);
    800057a4:	854a                	mv	a0,s2
    800057a6:	ffffe097          	auipc	ra,0xffffe
    800057aa:	3a2080e7          	jalr	930(ra) # 80003b48 <iunlockput>
  end_op();
    800057ae:	fffff097          	auipc	ra,0xfffff
    800057b2:	b7a080e7          	jalr	-1158(ra) # 80004328 <end_op>
  return 0;
    800057b6:	4501                	li	a0,0
    800057b8:	a84d                	j	8000586a <sys_unlink+0x1c4>
    end_op();
    800057ba:	fffff097          	auipc	ra,0xfffff
    800057be:	b6e080e7          	jalr	-1170(ra) # 80004328 <end_op>
    return -1;
    800057c2:	557d                	li	a0,-1
    800057c4:	a05d                	j	8000586a <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800057c6:	00003517          	auipc	a0,0x3
    800057ca:	12250513          	addi	a0,a0,290 # 800088e8 <syscalls+0x2f0>
    800057ce:	ffffb097          	auipc	ra,0xffffb
    800057d2:	d76080e7          	jalr	-650(ra) # 80000544 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057d6:	04c92703          	lw	a4,76(s2)
    800057da:	02000793          	li	a5,32
    800057de:	f6e7f9e3          	bgeu	a5,a4,80005750 <sys_unlink+0xaa>
    800057e2:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057e6:	4741                	li	a4,16
    800057e8:	86ce                	mv	a3,s3
    800057ea:	f1840613          	addi	a2,s0,-232
    800057ee:	4581                	li	a1,0
    800057f0:	854a                	mv	a0,s2
    800057f2:	ffffe097          	auipc	ra,0xffffe
    800057f6:	3a8080e7          	jalr	936(ra) # 80003b9a <readi>
    800057fa:	47c1                	li	a5,16
    800057fc:	00f51b63          	bne	a0,a5,80005812 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005800:	f1845783          	lhu	a5,-232(s0)
    80005804:	e7a1                	bnez	a5,8000584c <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005806:	29c1                	addiw	s3,s3,16
    80005808:	04c92783          	lw	a5,76(s2)
    8000580c:	fcf9ede3          	bltu	s3,a5,800057e6 <sys_unlink+0x140>
    80005810:	b781                	j	80005750 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005812:	00003517          	auipc	a0,0x3
    80005816:	0ee50513          	addi	a0,a0,238 # 80008900 <syscalls+0x308>
    8000581a:	ffffb097          	auipc	ra,0xffffb
    8000581e:	d2a080e7          	jalr	-726(ra) # 80000544 <panic>
    panic("unlink: writei");
    80005822:	00003517          	auipc	a0,0x3
    80005826:	0f650513          	addi	a0,a0,246 # 80008918 <syscalls+0x320>
    8000582a:	ffffb097          	auipc	ra,0xffffb
    8000582e:	d1a080e7          	jalr	-742(ra) # 80000544 <panic>
    dp->nlink--;
    80005832:	04a4d783          	lhu	a5,74(s1)
    80005836:	37fd                	addiw	a5,a5,-1
    80005838:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000583c:	8526                	mv	a0,s1
    8000583e:	ffffe097          	auipc	ra,0xffffe
    80005842:	fde080e7          	jalr	-34(ra) # 8000381c <iupdate>
    80005846:	b781                	j	80005786 <sys_unlink+0xe0>
    return -1;
    80005848:	557d                	li	a0,-1
    8000584a:	a005                	j	8000586a <sys_unlink+0x1c4>
    iunlockput(ip);
    8000584c:	854a                	mv	a0,s2
    8000584e:	ffffe097          	auipc	ra,0xffffe
    80005852:	2fa080e7          	jalr	762(ra) # 80003b48 <iunlockput>
  iunlockput(dp);
    80005856:	8526                	mv	a0,s1
    80005858:	ffffe097          	auipc	ra,0xffffe
    8000585c:	2f0080e7          	jalr	752(ra) # 80003b48 <iunlockput>
  end_op();
    80005860:	fffff097          	auipc	ra,0xfffff
    80005864:	ac8080e7          	jalr	-1336(ra) # 80004328 <end_op>
  return -1;
    80005868:	557d                	li	a0,-1
}
    8000586a:	70ae                	ld	ra,232(sp)
    8000586c:	740e                	ld	s0,224(sp)
    8000586e:	64ee                	ld	s1,216(sp)
    80005870:	694e                	ld	s2,208(sp)
    80005872:	69ae                	ld	s3,200(sp)
    80005874:	616d                	addi	sp,sp,240
    80005876:	8082                	ret

0000000080005878 <sys_open>:

uint64
sys_open(void)
{
    80005878:	7131                	addi	sp,sp,-192
    8000587a:	fd06                	sd	ra,184(sp)
    8000587c:	f922                	sd	s0,176(sp)
    8000587e:	f526                	sd	s1,168(sp)
    80005880:	f14a                	sd	s2,160(sp)
    80005882:	ed4e                	sd	s3,152(sp)
    80005884:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005886:	f4c40593          	addi	a1,s0,-180
    8000588a:	4505                	li	a0,1
    8000588c:	ffffd097          	auipc	ra,0xffffd
    80005890:	332080e7          	jalr	818(ra) # 80002bbe <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005894:	08000613          	li	a2,128
    80005898:	f5040593          	addi	a1,s0,-176
    8000589c:	4501                	li	a0,0
    8000589e:	ffffd097          	auipc	ra,0xffffd
    800058a2:	360080e7          	jalr	864(ra) # 80002bfe <argstr>
    800058a6:	87aa                	mv	a5,a0
    return -1;
    800058a8:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    800058aa:	0a07c963          	bltz	a5,8000595c <sys_open+0xe4>

  begin_op();
    800058ae:	fffff097          	auipc	ra,0xfffff
    800058b2:	9fa080e7          	jalr	-1542(ra) # 800042a8 <begin_op>

  if(omode & O_CREATE){
    800058b6:	f4c42783          	lw	a5,-180(s0)
    800058ba:	2007f793          	andi	a5,a5,512
    800058be:	cfc5                	beqz	a5,80005976 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800058c0:	4681                	li	a3,0
    800058c2:	4601                	li	a2,0
    800058c4:	4589                	li	a1,2
    800058c6:	f5040513          	addi	a0,s0,-176
    800058ca:	00000097          	auipc	ra,0x0
    800058ce:	974080e7          	jalr	-1676(ra) # 8000523e <create>
    800058d2:	84aa                	mv	s1,a0
    if(ip == 0){
    800058d4:	c959                	beqz	a0,8000596a <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800058d6:	04449703          	lh	a4,68(s1)
    800058da:	478d                	li	a5,3
    800058dc:	00f71763          	bne	a4,a5,800058ea <sys_open+0x72>
    800058e0:	0464d703          	lhu	a4,70(s1)
    800058e4:	47a5                	li	a5,9
    800058e6:	0ce7ed63          	bltu	a5,a4,800059c0 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800058ea:	fffff097          	auipc	ra,0xfffff
    800058ee:	dce080e7          	jalr	-562(ra) # 800046b8 <filealloc>
    800058f2:	89aa                	mv	s3,a0
    800058f4:	10050363          	beqz	a0,800059fa <sys_open+0x182>
    800058f8:	00000097          	auipc	ra,0x0
    800058fc:	904080e7          	jalr	-1788(ra) # 800051fc <fdalloc>
    80005900:	892a                	mv	s2,a0
    80005902:	0e054763          	bltz	a0,800059f0 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005906:	04449703          	lh	a4,68(s1)
    8000590a:	478d                	li	a5,3
    8000590c:	0cf70563          	beq	a4,a5,800059d6 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005910:	4789                	li	a5,2
    80005912:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005916:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000591a:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000591e:	f4c42783          	lw	a5,-180(s0)
    80005922:	0017c713          	xori	a4,a5,1
    80005926:	8b05                	andi	a4,a4,1
    80005928:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000592c:	0037f713          	andi	a4,a5,3
    80005930:	00e03733          	snez	a4,a4
    80005934:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005938:	4007f793          	andi	a5,a5,1024
    8000593c:	c791                	beqz	a5,80005948 <sys_open+0xd0>
    8000593e:	04449703          	lh	a4,68(s1)
    80005942:	4789                	li	a5,2
    80005944:	0af70063          	beq	a4,a5,800059e4 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005948:	8526                	mv	a0,s1
    8000594a:	ffffe097          	auipc	ra,0xffffe
    8000594e:	05e080e7          	jalr	94(ra) # 800039a8 <iunlock>
  end_op();
    80005952:	fffff097          	auipc	ra,0xfffff
    80005956:	9d6080e7          	jalr	-1578(ra) # 80004328 <end_op>

  return fd;
    8000595a:	854a                	mv	a0,s2
}
    8000595c:	70ea                	ld	ra,184(sp)
    8000595e:	744a                	ld	s0,176(sp)
    80005960:	74aa                	ld	s1,168(sp)
    80005962:	790a                	ld	s2,160(sp)
    80005964:	69ea                	ld	s3,152(sp)
    80005966:	6129                	addi	sp,sp,192
    80005968:	8082                	ret
      end_op();
    8000596a:	fffff097          	auipc	ra,0xfffff
    8000596e:	9be080e7          	jalr	-1602(ra) # 80004328 <end_op>
      return -1;
    80005972:	557d                	li	a0,-1
    80005974:	b7e5                	j	8000595c <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005976:	f5040513          	addi	a0,s0,-176
    8000597a:	ffffe097          	auipc	ra,0xffffe
    8000597e:	712080e7          	jalr	1810(ra) # 8000408c <namei>
    80005982:	84aa                	mv	s1,a0
    80005984:	c905                	beqz	a0,800059b4 <sys_open+0x13c>
    ilock(ip);
    80005986:	ffffe097          	auipc	ra,0xffffe
    8000598a:	f60080e7          	jalr	-160(ra) # 800038e6 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000598e:	04449703          	lh	a4,68(s1)
    80005992:	4785                	li	a5,1
    80005994:	f4f711e3          	bne	a4,a5,800058d6 <sys_open+0x5e>
    80005998:	f4c42783          	lw	a5,-180(s0)
    8000599c:	d7b9                	beqz	a5,800058ea <sys_open+0x72>
      iunlockput(ip);
    8000599e:	8526                	mv	a0,s1
    800059a0:	ffffe097          	auipc	ra,0xffffe
    800059a4:	1a8080e7          	jalr	424(ra) # 80003b48 <iunlockput>
      end_op();
    800059a8:	fffff097          	auipc	ra,0xfffff
    800059ac:	980080e7          	jalr	-1664(ra) # 80004328 <end_op>
      return -1;
    800059b0:	557d                	li	a0,-1
    800059b2:	b76d                	j	8000595c <sys_open+0xe4>
      end_op();
    800059b4:	fffff097          	auipc	ra,0xfffff
    800059b8:	974080e7          	jalr	-1676(ra) # 80004328 <end_op>
      return -1;
    800059bc:	557d                	li	a0,-1
    800059be:	bf79                	j	8000595c <sys_open+0xe4>
    iunlockput(ip);
    800059c0:	8526                	mv	a0,s1
    800059c2:	ffffe097          	auipc	ra,0xffffe
    800059c6:	186080e7          	jalr	390(ra) # 80003b48 <iunlockput>
    end_op();
    800059ca:	fffff097          	auipc	ra,0xfffff
    800059ce:	95e080e7          	jalr	-1698(ra) # 80004328 <end_op>
    return -1;
    800059d2:	557d                	li	a0,-1
    800059d4:	b761                	j	8000595c <sys_open+0xe4>
    f->type = FD_DEVICE;
    800059d6:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800059da:	04649783          	lh	a5,70(s1)
    800059de:	02f99223          	sh	a5,36(s3)
    800059e2:	bf25                	j	8000591a <sys_open+0xa2>
    itrunc(ip);
    800059e4:	8526                	mv	a0,s1
    800059e6:	ffffe097          	auipc	ra,0xffffe
    800059ea:	00e080e7          	jalr	14(ra) # 800039f4 <itrunc>
    800059ee:	bfa9                	j	80005948 <sys_open+0xd0>
      fileclose(f);
    800059f0:	854e                	mv	a0,s3
    800059f2:	fffff097          	auipc	ra,0xfffff
    800059f6:	d82080e7          	jalr	-638(ra) # 80004774 <fileclose>
    iunlockput(ip);
    800059fa:	8526                	mv	a0,s1
    800059fc:	ffffe097          	auipc	ra,0xffffe
    80005a00:	14c080e7          	jalr	332(ra) # 80003b48 <iunlockput>
    end_op();
    80005a04:	fffff097          	auipc	ra,0xfffff
    80005a08:	924080e7          	jalr	-1756(ra) # 80004328 <end_op>
    return -1;
    80005a0c:	557d                	li	a0,-1
    80005a0e:	b7b9                	j	8000595c <sys_open+0xe4>

0000000080005a10 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005a10:	7175                	addi	sp,sp,-144
    80005a12:	e506                	sd	ra,136(sp)
    80005a14:	e122                	sd	s0,128(sp)
    80005a16:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005a18:	fffff097          	auipc	ra,0xfffff
    80005a1c:	890080e7          	jalr	-1904(ra) # 800042a8 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005a20:	08000613          	li	a2,128
    80005a24:	f7040593          	addi	a1,s0,-144
    80005a28:	4501                	li	a0,0
    80005a2a:	ffffd097          	auipc	ra,0xffffd
    80005a2e:	1d4080e7          	jalr	468(ra) # 80002bfe <argstr>
    80005a32:	02054963          	bltz	a0,80005a64 <sys_mkdir+0x54>
    80005a36:	4681                	li	a3,0
    80005a38:	4601                	li	a2,0
    80005a3a:	4585                	li	a1,1
    80005a3c:	f7040513          	addi	a0,s0,-144
    80005a40:	fffff097          	auipc	ra,0xfffff
    80005a44:	7fe080e7          	jalr	2046(ra) # 8000523e <create>
    80005a48:	cd11                	beqz	a0,80005a64 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a4a:	ffffe097          	auipc	ra,0xffffe
    80005a4e:	0fe080e7          	jalr	254(ra) # 80003b48 <iunlockput>
  end_op();
    80005a52:	fffff097          	auipc	ra,0xfffff
    80005a56:	8d6080e7          	jalr	-1834(ra) # 80004328 <end_op>
  return 0;
    80005a5a:	4501                	li	a0,0
}
    80005a5c:	60aa                	ld	ra,136(sp)
    80005a5e:	640a                	ld	s0,128(sp)
    80005a60:	6149                	addi	sp,sp,144
    80005a62:	8082                	ret
    end_op();
    80005a64:	fffff097          	auipc	ra,0xfffff
    80005a68:	8c4080e7          	jalr	-1852(ra) # 80004328 <end_op>
    return -1;
    80005a6c:	557d                	li	a0,-1
    80005a6e:	b7fd                	j	80005a5c <sys_mkdir+0x4c>

0000000080005a70 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005a70:	7135                	addi	sp,sp,-160
    80005a72:	ed06                	sd	ra,152(sp)
    80005a74:	e922                	sd	s0,144(sp)
    80005a76:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005a78:	fffff097          	auipc	ra,0xfffff
    80005a7c:	830080e7          	jalr	-2000(ra) # 800042a8 <begin_op>
  argint(1, &major);
    80005a80:	f6c40593          	addi	a1,s0,-148
    80005a84:	4505                	li	a0,1
    80005a86:	ffffd097          	auipc	ra,0xffffd
    80005a8a:	138080e7          	jalr	312(ra) # 80002bbe <argint>
  argint(2, &minor);
    80005a8e:	f6840593          	addi	a1,s0,-152
    80005a92:	4509                	li	a0,2
    80005a94:	ffffd097          	auipc	ra,0xffffd
    80005a98:	12a080e7          	jalr	298(ra) # 80002bbe <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a9c:	08000613          	li	a2,128
    80005aa0:	f7040593          	addi	a1,s0,-144
    80005aa4:	4501                	li	a0,0
    80005aa6:	ffffd097          	auipc	ra,0xffffd
    80005aaa:	158080e7          	jalr	344(ra) # 80002bfe <argstr>
    80005aae:	02054b63          	bltz	a0,80005ae4 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005ab2:	f6841683          	lh	a3,-152(s0)
    80005ab6:	f6c41603          	lh	a2,-148(s0)
    80005aba:	458d                	li	a1,3
    80005abc:	f7040513          	addi	a0,s0,-144
    80005ac0:	fffff097          	auipc	ra,0xfffff
    80005ac4:	77e080e7          	jalr	1918(ra) # 8000523e <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ac8:	cd11                	beqz	a0,80005ae4 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005aca:	ffffe097          	auipc	ra,0xffffe
    80005ace:	07e080e7          	jalr	126(ra) # 80003b48 <iunlockput>
  end_op();
    80005ad2:	fffff097          	auipc	ra,0xfffff
    80005ad6:	856080e7          	jalr	-1962(ra) # 80004328 <end_op>
  return 0;
    80005ada:	4501                	li	a0,0
}
    80005adc:	60ea                	ld	ra,152(sp)
    80005ade:	644a                	ld	s0,144(sp)
    80005ae0:	610d                	addi	sp,sp,160
    80005ae2:	8082                	ret
    end_op();
    80005ae4:	fffff097          	auipc	ra,0xfffff
    80005ae8:	844080e7          	jalr	-1980(ra) # 80004328 <end_op>
    return -1;
    80005aec:	557d                	li	a0,-1
    80005aee:	b7fd                	j	80005adc <sys_mknod+0x6c>

0000000080005af0 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005af0:	7135                	addi	sp,sp,-160
    80005af2:	ed06                	sd	ra,152(sp)
    80005af4:	e922                	sd	s0,144(sp)
    80005af6:	e526                	sd	s1,136(sp)
    80005af8:	e14a                	sd	s2,128(sp)
    80005afa:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005afc:	ffffc097          	auipc	ra,0xffffc
    80005b00:	eca080e7          	jalr	-310(ra) # 800019c6 <myproc>
    80005b04:	892a                	mv	s2,a0
  
  begin_op();
    80005b06:	ffffe097          	auipc	ra,0xffffe
    80005b0a:	7a2080e7          	jalr	1954(ra) # 800042a8 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005b0e:	08000613          	li	a2,128
    80005b12:	f6040593          	addi	a1,s0,-160
    80005b16:	4501                	li	a0,0
    80005b18:	ffffd097          	auipc	ra,0xffffd
    80005b1c:	0e6080e7          	jalr	230(ra) # 80002bfe <argstr>
    80005b20:	04054b63          	bltz	a0,80005b76 <sys_chdir+0x86>
    80005b24:	f6040513          	addi	a0,s0,-160
    80005b28:	ffffe097          	auipc	ra,0xffffe
    80005b2c:	564080e7          	jalr	1380(ra) # 8000408c <namei>
    80005b30:	84aa                	mv	s1,a0
    80005b32:	c131                	beqz	a0,80005b76 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005b34:	ffffe097          	auipc	ra,0xffffe
    80005b38:	db2080e7          	jalr	-590(ra) # 800038e6 <ilock>
  if(ip->type != T_DIR){
    80005b3c:	04449703          	lh	a4,68(s1)
    80005b40:	4785                	li	a5,1
    80005b42:	04f71063          	bne	a4,a5,80005b82 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005b46:	8526                	mv	a0,s1
    80005b48:	ffffe097          	auipc	ra,0xffffe
    80005b4c:	e60080e7          	jalr	-416(ra) # 800039a8 <iunlock>
  iput(p->cwd);
    80005b50:	15093503          	ld	a0,336(s2)
    80005b54:	ffffe097          	auipc	ra,0xffffe
    80005b58:	f4c080e7          	jalr	-180(ra) # 80003aa0 <iput>
  end_op();
    80005b5c:	ffffe097          	auipc	ra,0xffffe
    80005b60:	7cc080e7          	jalr	1996(ra) # 80004328 <end_op>
  p->cwd = ip;
    80005b64:	14993823          	sd	s1,336(s2)
  return 0;
    80005b68:	4501                	li	a0,0
}
    80005b6a:	60ea                	ld	ra,152(sp)
    80005b6c:	644a                	ld	s0,144(sp)
    80005b6e:	64aa                	ld	s1,136(sp)
    80005b70:	690a                	ld	s2,128(sp)
    80005b72:	610d                	addi	sp,sp,160
    80005b74:	8082                	ret
    end_op();
    80005b76:	ffffe097          	auipc	ra,0xffffe
    80005b7a:	7b2080e7          	jalr	1970(ra) # 80004328 <end_op>
    return -1;
    80005b7e:	557d                	li	a0,-1
    80005b80:	b7ed                	j	80005b6a <sys_chdir+0x7a>
    iunlockput(ip);
    80005b82:	8526                	mv	a0,s1
    80005b84:	ffffe097          	auipc	ra,0xffffe
    80005b88:	fc4080e7          	jalr	-60(ra) # 80003b48 <iunlockput>
    end_op();
    80005b8c:	ffffe097          	auipc	ra,0xffffe
    80005b90:	79c080e7          	jalr	1948(ra) # 80004328 <end_op>
    return -1;
    80005b94:	557d                	li	a0,-1
    80005b96:	bfd1                	j	80005b6a <sys_chdir+0x7a>

0000000080005b98 <sys_exec>:

uint64
sys_exec(void)
{
    80005b98:	7145                	addi	sp,sp,-464
    80005b9a:	e786                	sd	ra,456(sp)
    80005b9c:	e3a2                	sd	s0,448(sp)
    80005b9e:	ff26                	sd	s1,440(sp)
    80005ba0:	fb4a                	sd	s2,432(sp)
    80005ba2:	f74e                	sd	s3,424(sp)
    80005ba4:	f352                	sd	s4,416(sp)
    80005ba6:	ef56                	sd	s5,408(sp)
    80005ba8:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005baa:	e3840593          	addi	a1,s0,-456
    80005bae:	4505                	li	a0,1
    80005bb0:	ffffd097          	auipc	ra,0xffffd
    80005bb4:	02e080e7          	jalr	46(ra) # 80002bde <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005bb8:	08000613          	li	a2,128
    80005bbc:	f4040593          	addi	a1,s0,-192
    80005bc0:	4501                	li	a0,0
    80005bc2:	ffffd097          	auipc	ra,0xffffd
    80005bc6:	03c080e7          	jalr	60(ra) # 80002bfe <argstr>
    80005bca:	87aa                	mv	a5,a0
    return -1;
    80005bcc:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005bce:	0c07c263          	bltz	a5,80005c92 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005bd2:	10000613          	li	a2,256
    80005bd6:	4581                	li	a1,0
    80005bd8:	e4040513          	addi	a0,s0,-448
    80005bdc:	ffffb097          	auipc	ra,0xffffb
    80005be0:	10a080e7          	jalr	266(ra) # 80000ce6 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005be4:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005be8:	89a6                	mv	s3,s1
    80005bea:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005bec:	02000a13          	li	s4,32
    80005bf0:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005bf4:	00391513          	slli	a0,s2,0x3
    80005bf8:	e3040593          	addi	a1,s0,-464
    80005bfc:	e3843783          	ld	a5,-456(s0)
    80005c00:	953e                	add	a0,a0,a5
    80005c02:	ffffd097          	auipc	ra,0xffffd
    80005c06:	f1e080e7          	jalr	-226(ra) # 80002b20 <fetchaddr>
    80005c0a:	02054a63          	bltz	a0,80005c3e <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005c0e:	e3043783          	ld	a5,-464(s0)
    80005c12:	c3b9                	beqz	a5,80005c58 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005c14:	ffffb097          	auipc	ra,0xffffb
    80005c18:	ee6080e7          	jalr	-282(ra) # 80000afa <kalloc>
    80005c1c:	85aa                	mv	a1,a0
    80005c1e:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005c22:	cd11                	beqz	a0,80005c3e <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005c24:	6605                	lui	a2,0x1
    80005c26:	e3043503          	ld	a0,-464(s0)
    80005c2a:	ffffd097          	auipc	ra,0xffffd
    80005c2e:	f48080e7          	jalr	-184(ra) # 80002b72 <fetchstr>
    80005c32:	00054663          	bltz	a0,80005c3e <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005c36:	0905                	addi	s2,s2,1
    80005c38:	09a1                	addi	s3,s3,8
    80005c3a:	fb491be3          	bne	s2,s4,80005bf0 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c3e:	10048913          	addi	s2,s1,256
    80005c42:	6088                	ld	a0,0(s1)
    80005c44:	c531                	beqz	a0,80005c90 <sys_exec+0xf8>
    kfree(argv[i]);
    80005c46:	ffffb097          	auipc	ra,0xffffb
    80005c4a:	db8080e7          	jalr	-584(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c4e:	04a1                	addi	s1,s1,8
    80005c50:	ff2499e3          	bne	s1,s2,80005c42 <sys_exec+0xaa>
  return -1;
    80005c54:	557d                	li	a0,-1
    80005c56:	a835                	j	80005c92 <sys_exec+0xfa>
      argv[i] = 0;
    80005c58:	0a8e                	slli	s5,s5,0x3
    80005c5a:	fc040793          	addi	a5,s0,-64
    80005c5e:	9abe                	add	s5,s5,a5
    80005c60:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005c64:	e4040593          	addi	a1,s0,-448
    80005c68:	f4040513          	addi	a0,s0,-192
    80005c6c:	fffff097          	auipc	ra,0xfffff
    80005c70:	190080e7          	jalr	400(ra) # 80004dfc <exec>
    80005c74:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c76:	10048993          	addi	s3,s1,256
    80005c7a:	6088                	ld	a0,0(s1)
    80005c7c:	c901                	beqz	a0,80005c8c <sys_exec+0xf4>
    kfree(argv[i]);
    80005c7e:	ffffb097          	auipc	ra,0xffffb
    80005c82:	d80080e7          	jalr	-640(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c86:	04a1                	addi	s1,s1,8
    80005c88:	ff3499e3          	bne	s1,s3,80005c7a <sys_exec+0xe2>
  return ret;
    80005c8c:	854a                	mv	a0,s2
    80005c8e:	a011                	j	80005c92 <sys_exec+0xfa>
  return -1;
    80005c90:	557d                	li	a0,-1
}
    80005c92:	60be                	ld	ra,456(sp)
    80005c94:	641e                	ld	s0,448(sp)
    80005c96:	74fa                	ld	s1,440(sp)
    80005c98:	795a                	ld	s2,432(sp)
    80005c9a:	79ba                	ld	s3,424(sp)
    80005c9c:	7a1a                	ld	s4,416(sp)
    80005c9e:	6afa                	ld	s5,408(sp)
    80005ca0:	6179                	addi	sp,sp,464
    80005ca2:	8082                	ret

0000000080005ca4 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005ca4:	7139                	addi	sp,sp,-64
    80005ca6:	fc06                	sd	ra,56(sp)
    80005ca8:	f822                	sd	s0,48(sp)
    80005caa:	f426                	sd	s1,40(sp)
    80005cac:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005cae:	ffffc097          	auipc	ra,0xffffc
    80005cb2:	d18080e7          	jalr	-744(ra) # 800019c6 <myproc>
    80005cb6:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005cb8:	fd840593          	addi	a1,s0,-40
    80005cbc:	4501                	li	a0,0
    80005cbe:	ffffd097          	auipc	ra,0xffffd
    80005cc2:	f20080e7          	jalr	-224(ra) # 80002bde <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005cc6:	fc840593          	addi	a1,s0,-56
    80005cca:	fd040513          	addi	a0,s0,-48
    80005cce:	fffff097          	auipc	ra,0xfffff
    80005cd2:	dd6080e7          	jalr	-554(ra) # 80004aa4 <pipealloc>
    return -1;
    80005cd6:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005cd8:	0c054463          	bltz	a0,80005da0 <sys_pipe+0xfc>
  fd0 = -1;
    80005cdc:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005ce0:	fd043503          	ld	a0,-48(s0)
    80005ce4:	fffff097          	auipc	ra,0xfffff
    80005ce8:	518080e7          	jalr	1304(ra) # 800051fc <fdalloc>
    80005cec:	fca42223          	sw	a0,-60(s0)
    80005cf0:	08054b63          	bltz	a0,80005d86 <sys_pipe+0xe2>
    80005cf4:	fc843503          	ld	a0,-56(s0)
    80005cf8:	fffff097          	auipc	ra,0xfffff
    80005cfc:	504080e7          	jalr	1284(ra) # 800051fc <fdalloc>
    80005d00:	fca42023          	sw	a0,-64(s0)
    80005d04:	06054863          	bltz	a0,80005d74 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d08:	4691                	li	a3,4
    80005d0a:	fc440613          	addi	a2,s0,-60
    80005d0e:	fd843583          	ld	a1,-40(s0)
    80005d12:	68a8                	ld	a0,80(s1)
    80005d14:	ffffc097          	auipc	ra,0xffffc
    80005d18:	970080e7          	jalr	-1680(ra) # 80001684 <copyout>
    80005d1c:	02054063          	bltz	a0,80005d3c <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005d20:	4691                	li	a3,4
    80005d22:	fc040613          	addi	a2,s0,-64
    80005d26:	fd843583          	ld	a1,-40(s0)
    80005d2a:	0591                	addi	a1,a1,4
    80005d2c:	68a8                	ld	a0,80(s1)
    80005d2e:	ffffc097          	auipc	ra,0xffffc
    80005d32:	956080e7          	jalr	-1706(ra) # 80001684 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005d36:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d38:	06055463          	bgez	a0,80005da0 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005d3c:	fc442783          	lw	a5,-60(s0)
    80005d40:	07e9                	addi	a5,a5,26
    80005d42:	078e                	slli	a5,a5,0x3
    80005d44:	97a6                	add	a5,a5,s1
    80005d46:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005d4a:	fc042503          	lw	a0,-64(s0)
    80005d4e:	0569                	addi	a0,a0,26
    80005d50:	050e                	slli	a0,a0,0x3
    80005d52:	94aa                	add	s1,s1,a0
    80005d54:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005d58:	fd043503          	ld	a0,-48(s0)
    80005d5c:	fffff097          	auipc	ra,0xfffff
    80005d60:	a18080e7          	jalr	-1512(ra) # 80004774 <fileclose>
    fileclose(wf);
    80005d64:	fc843503          	ld	a0,-56(s0)
    80005d68:	fffff097          	auipc	ra,0xfffff
    80005d6c:	a0c080e7          	jalr	-1524(ra) # 80004774 <fileclose>
    return -1;
    80005d70:	57fd                	li	a5,-1
    80005d72:	a03d                	j	80005da0 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005d74:	fc442783          	lw	a5,-60(s0)
    80005d78:	0007c763          	bltz	a5,80005d86 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005d7c:	07e9                	addi	a5,a5,26
    80005d7e:	078e                	slli	a5,a5,0x3
    80005d80:	94be                	add	s1,s1,a5
    80005d82:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005d86:	fd043503          	ld	a0,-48(s0)
    80005d8a:	fffff097          	auipc	ra,0xfffff
    80005d8e:	9ea080e7          	jalr	-1558(ra) # 80004774 <fileclose>
    fileclose(wf);
    80005d92:	fc843503          	ld	a0,-56(s0)
    80005d96:	fffff097          	auipc	ra,0xfffff
    80005d9a:	9de080e7          	jalr	-1570(ra) # 80004774 <fileclose>
    return -1;
    80005d9e:	57fd                	li	a5,-1
}
    80005da0:	853e                	mv	a0,a5
    80005da2:	70e2                	ld	ra,56(sp)
    80005da4:	7442                	ld	s0,48(sp)
    80005da6:	74a2                	ld	s1,40(sp)
    80005da8:	6121                	addi	sp,sp,64
    80005daa:	8082                	ret
    80005dac:	0000                	unimp
	...

0000000080005db0 <kernelvec>:
    80005db0:	7111                	addi	sp,sp,-256
    80005db2:	e006                	sd	ra,0(sp)
    80005db4:	e40a                	sd	sp,8(sp)
    80005db6:	e80e                	sd	gp,16(sp)
    80005db8:	ec12                	sd	tp,24(sp)
    80005dba:	f016                	sd	t0,32(sp)
    80005dbc:	f41a                	sd	t1,40(sp)
    80005dbe:	f81e                	sd	t2,48(sp)
    80005dc0:	fc22                	sd	s0,56(sp)
    80005dc2:	e0a6                	sd	s1,64(sp)
    80005dc4:	e4aa                	sd	a0,72(sp)
    80005dc6:	e8ae                	sd	a1,80(sp)
    80005dc8:	ecb2                	sd	a2,88(sp)
    80005dca:	f0b6                	sd	a3,96(sp)
    80005dcc:	f4ba                	sd	a4,104(sp)
    80005dce:	f8be                	sd	a5,112(sp)
    80005dd0:	fcc2                	sd	a6,120(sp)
    80005dd2:	e146                	sd	a7,128(sp)
    80005dd4:	e54a                	sd	s2,136(sp)
    80005dd6:	e94e                	sd	s3,144(sp)
    80005dd8:	ed52                	sd	s4,152(sp)
    80005dda:	f156                	sd	s5,160(sp)
    80005ddc:	f55a                	sd	s6,168(sp)
    80005dde:	f95e                	sd	s7,176(sp)
    80005de0:	fd62                	sd	s8,184(sp)
    80005de2:	e1e6                	sd	s9,192(sp)
    80005de4:	e5ea                	sd	s10,200(sp)
    80005de6:	e9ee                	sd	s11,208(sp)
    80005de8:	edf2                	sd	t3,216(sp)
    80005dea:	f1f6                	sd	t4,224(sp)
    80005dec:	f5fa                	sd	t5,232(sp)
    80005dee:	f9fe                	sd	t6,240(sp)
    80005df0:	bfdfc0ef          	jal	ra,800029ec <kerneltrap>
    80005df4:	6082                	ld	ra,0(sp)
    80005df6:	6122                	ld	sp,8(sp)
    80005df8:	61c2                	ld	gp,16(sp)
    80005dfa:	7282                	ld	t0,32(sp)
    80005dfc:	7322                	ld	t1,40(sp)
    80005dfe:	73c2                	ld	t2,48(sp)
    80005e00:	7462                	ld	s0,56(sp)
    80005e02:	6486                	ld	s1,64(sp)
    80005e04:	6526                	ld	a0,72(sp)
    80005e06:	65c6                	ld	a1,80(sp)
    80005e08:	6666                	ld	a2,88(sp)
    80005e0a:	7686                	ld	a3,96(sp)
    80005e0c:	7726                	ld	a4,104(sp)
    80005e0e:	77c6                	ld	a5,112(sp)
    80005e10:	7866                	ld	a6,120(sp)
    80005e12:	688a                	ld	a7,128(sp)
    80005e14:	692a                	ld	s2,136(sp)
    80005e16:	69ca                	ld	s3,144(sp)
    80005e18:	6a6a                	ld	s4,152(sp)
    80005e1a:	7a8a                	ld	s5,160(sp)
    80005e1c:	7b2a                	ld	s6,168(sp)
    80005e1e:	7bca                	ld	s7,176(sp)
    80005e20:	7c6a                	ld	s8,184(sp)
    80005e22:	6c8e                	ld	s9,192(sp)
    80005e24:	6d2e                	ld	s10,200(sp)
    80005e26:	6dce                	ld	s11,208(sp)
    80005e28:	6e6e                	ld	t3,216(sp)
    80005e2a:	7e8e                	ld	t4,224(sp)
    80005e2c:	7f2e                	ld	t5,232(sp)
    80005e2e:	7fce                	ld	t6,240(sp)
    80005e30:	6111                	addi	sp,sp,256
    80005e32:	10200073          	sret
    80005e36:	00000013          	nop
    80005e3a:	00000013          	nop
    80005e3e:	0001                	nop

0000000080005e40 <timervec>:
    80005e40:	34051573          	csrrw	a0,mscratch,a0
    80005e44:	e10c                	sd	a1,0(a0)
    80005e46:	e510                	sd	a2,8(a0)
    80005e48:	e914                	sd	a3,16(a0)
    80005e4a:	6d0c                	ld	a1,24(a0)
    80005e4c:	7110                	ld	a2,32(a0)
    80005e4e:	6194                	ld	a3,0(a1)
    80005e50:	96b2                	add	a3,a3,a2
    80005e52:	e194                	sd	a3,0(a1)
    80005e54:	4589                	li	a1,2
    80005e56:	14459073          	csrw	sip,a1
    80005e5a:	6914                	ld	a3,16(a0)
    80005e5c:	6510                	ld	a2,8(a0)
    80005e5e:	610c                	ld	a1,0(a0)
    80005e60:	34051573          	csrrw	a0,mscratch,a0
    80005e64:	30200073          	mret
	...

0000000080005e6a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005e6a:	1141                	addi	sp,sp,-16
    80005e6c:	e422                	sd	s0,8(sp)
    80005e6e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005e70:	0c0007b7          	lui	a5,0xc000
    80005e74:	4705                	li	a4,1
    80005e76:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005e78:	c3d8                	sw	a4,4(a5)
}
    80005e7a:	6422                	ld	s0,8(sp)
    80005e7c:	0141                	addi	sp,sp,16
    80005e7e:	8082                	ret

0000000080005e80 <plicinithart>:

void
plicinithart(void)
{
    80005e80:	1141                	addi	sp,sp,-16
    80005e82:	e406                	sd	ra,8(sp)
    80005e84:	e022                	sd	s0,0(sp)
    80005e86:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e88:	ffffc097          	auipc	ra,0xffffc
    80005e8c:	b12080e7          	jalr	-1262(ra) # 8000199a <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005e90:	0085171b          	slliw	a4,a0,0x8
    80005e94:	0c0027b7          	lui	a5,0xc002
    80005e98:	97ba                	add	a5,a5,a4
    80005e9a:	40200713          	li	a4,1026
    80005e9e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005ea2:	00d5151b          	slliw	a0,a0,0xd
    80005ea6:	0c2017b7          	lui	a5,0xc201
    80005eaa:	953e                	add	a0,a0,a5
    80005eac:	00052023          	sw	zero,0(a0)
}
    80005eb0:	60a2                	ld	ra,8(sp)
    80005eb2:	6402                	ld	s0,0(sp)
    80005eb4:	0141                	addi	sp,sp,16
    80005eb6:	8082                	ret

0000000080005eb8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005eb8:	1141                	addi	sp,sp,-16
    80005eba:	e406                	sd	ra,8(sp)
    80005ebc:	e022                	sd	s0,0(sp)
    80005ebe:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ec0:	ffffc097          	auipc	ra,0xffffc
    80005ec4:	ada080e7          	jalr	-1318(ra) # 8000199a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005ec8:	00d5179b          	slliw	a5,a0,0xd
    80005ecc:	0c201537          	lui	a0,0xc201
    80005ed0:	953e                	add	a0,a0,a5
  return irq;
}
    80005ed2:	4148                	lw	a0,4(a0)
    80005ed4:	60a2                	ld	ra,8(sp)
    80005ed6:	6402                	ld	s0,0(sp)
    80005ed8:	0141                	addi	sp,sp,16
    80005eda:	8082                	ret

0000000080005edc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005edc:	1101                	addi	sp,sp,-32
    80005ede:	ec06                	sd	ra,24(sp)
    80005ee0:	e822                	sd	s0,16(sp)
    80005ee2:	e426                	sd	s1,8(sp)
    80005ee4:	1000                	addi	s0,sp,32
    80005ee6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005ee8:	ffffc097          	auipc	ra,0xffffc
    80005eec:	ab2080e7          	jalr	-1358(ra) # 8000199a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005ef0:	00d5151b          	slliw	a0,a0,0xd
    80005ef4:	0c2017b7          	lui	a5,0xc201
    80005ef8:	97aa                	add	a5,a5,a0
    80005efa:	c3c4                	sw	s1,4(a5)
}
    80005efc:	60e2                	ld	ra,24(sp)
    80005efe:	6442                	ld	s0,16(sp)
    80005f00:	64a2                	ld	s1,8(sp)
    80005f02:	6105                	addi	sp,sp,32
    80005f04:	8082                	ret

0000000080005f06 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005f06:	1141                	addi	sp,sp,-16
    80005f08:	e406                	sd	ra,8(sp)
    80005f0a:	e022                	sd	s0,0(sp)
    80005f0c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005f0e:	479d                	li	a5,7
    80005f10:	04a7cc63          	blt	a5,a0,80005f68 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005f14:	00024797          	auipc	a5,0x24
    80005f18:	29478793          	addi	a5,a5,660 # 8002a1a8 <disk>
    80005f1c:	97aa                	add	a5,a5,a0
    80005f1e:	0187c783          	lbu	a5,24(a5)
    80005f22:	ebb9                	bnez	a5,80005f78 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005f24:	00451613          	slli	a2,a0,0x4
    80005f28:	00024797          	auipc	a5,0x24
    80005f2c:	28078793          	addi	a5,a5,640 # 8002a1a8 <disk>
    80005f30:	6394                	ld	a3,0(a5)
    80005f32:	96b2                	add	a3,a3,a2
    80005f34:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005f38:	6398                	ld	a4,0(a5)
    80005f3a:	9732                	add	a4,a4,a2
    80005f3c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005f40:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005f44:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005f48:	953e                	add	a0,a0,a5
    80005f4a:	4785                	li	a5,1
    80005f4c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80005f50:	00024517          	auipc	a0,0x24
    80005f54:	27050513          	addi	a0,a0,624 # 8002a1c0 <disk+0x18>
    80005f58:	ffffc097          	auipc	ra,0xffffc
    80005f5c:	216080e7          	jalr	534(ra) # 8000216e <wakeup>
}
    80005f60:	60a2                	ld	ra,8(sp)
    80005f62:	6402                	ld	s0,0(sp)
    80005f64:	0141                	addi	sp,sp,16
    80005f66:	8082                	ret
    panic("free_desc 1");
    80005f68:	00003517          	auipc	a0,0x3
    80005f6c:	9c050513          	addi	a0,a0,-1600 # 80008928 <syscalls+0x330>
    80005f70:	ffffa097          	auipc	ra,0xffffa
    80005f74:	5d4080e7          	jalr	1492(ra) # 80000544 <panic>
    panic("free_desc 2");
    80005f78:	00003517          	auipc	a0,0x3
    80005f7c:	9c050513          	addi	a0,a0,-1600 # 80008938 <syscalls+0x340>
    80005f80:	ffffa097          	auipc	ra,0xffffa
    80005f84:	5c4080e7          	jalr	1476(ra) # 80000544 <panic>

0000000080005f88 <virtio_disk_init>:
{
    80005f88:	1101                	addi	sp,sp,-32
    80005f8a:	ec06                	sd	ra,24(sp)
    80005f8c:	e822                	sd	s0,16(sp)
    80005f8e:	e426                	sd	s1,8(sp)
    80005f90:	e04a                	sd	s2,0(sp)
    80005f92:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005f94:	00003597          	auipc	a1,0x3
    80005f98:	9b458593          	addi	a1,a1,-1612 # 80008948 <syscalls+0x350>
    80005f9c:	00024517          	auipc	a0,0x24
    80005fa0:	33450513          	addi	a0,a0,820 # 8002a2d0 <disk+0x128>
    80005fa4:	ffffb097          	auipc	ra,0xffffb
    80005fa8:	bb6080e7          	jalr	-1098(ra) # 80000b5a <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005fac:	100017b7          	lui	a5,0x10001
    80005fb0:	4398                	lw	a4,0(a5)
    80005fb2:	2701                	sext.w	a4,a4
    80005fb4:	747277b7          	lui	a5,0x74727
    80005fb8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005fbc:	14f71e63          	bne	a4,a5,80006118 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005fc0:	100017b7          	lui	a5,0x10001
    80005fc4:	43dc                	lw	a5,4(a5)
    80005fc6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005fc8:	4709                	li	a4,2
    80005fca:	14e79763          	bne	a5,a4,80006118 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005fce:	100017b7          	lui	a5,0x10001
    80005fd2:	479c                	lw	a5,8(a5)
    80005fd4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005fd6:	14e79163          	bne	a5,a4,80006118 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005fda:	100017b7          	lui	a5,0x10001
    80005fde:	47d8                	lw	a4,12(a5)
    80005fe0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005fe2:	554d47b7          	lui	a5,0x554d4
    80005fe6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005fea:	12f71763          	bne	a4,a5,80006118 <virtio_disk_init+0x190>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fee:	100017b7          	lui	a5,0x10001
    80005ff2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ff6:	4705                	li	a4,1
    80005ff8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ffa:	470d                	li	a4,3
    80005ffc:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005ffe:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006000:	c7ffe737          	lui	a4,0xc7ffe
    80006004:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd4477>
    80006008:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000600a:	2701                	sext.w	a4,a4
    8000600c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000600e:	472d                	li	a4,11
    80006010:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006012:	0707a903          	lw	s2,112(a5)
    80006016:	2901                	sext.w	s2,s2
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006018:	00897793          	andi	a5,s2,8
    8000601c:	10078663          	beqz	a5,80006128 <virtio_disk_init+0x1a0>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006020:	100017b7          	lui	a5,0x10001
    80006024:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006028:	43fc                	lw	a5,68(a5)
    8000602a:	2781                	sext.w	a5,a5
    8000602c:	10079663          	bnez	a5,80006138 <virtio_disk_init+0x1b0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006030:	100017b7          	lui	a5,0x10001
    80006034:	5bdc                	lw	a5,52(a5)
    80006036:	2781                	sext.w	a5,a5
  if(max == 0)
    80006038:	10078863          	beqz	a5,80006148 <virtio_disk_init+0x1c0>
  if(max < NUM)
    8000603c:	471d                	li	a4,7
    8000603e:	10f77d63          	bgeu	a4,a5,80006158 <virtio_disk_init+0x1d0>
  disk.desc = kalloc();
    80006042:	ffffb097          	auipc	ra,0xffffb
    80006046:	ab8080e7          	jalr	-1352(ra) # 80000afa <kalloc>
    8000604a:	00024497          	auipc	s1,0x24
    8000604e:	15e48493          	addi	s1,s1,350 # 8002a1a8 <disk>
    80006052:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006054:	ffffb097          	auipc	ra,0xffffb
    80006058:	aa6080e7          	jalr	-1370(ra) # 80000afa <kalloc>
    8000605c:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000605e:	ffffb097          	auipc	ra,0xffffb
    80006062:	a9c080e7          	jalr	-1380(ra) # 80000afa <kalloc>
    80006066:	87aa                	mv	a5,a0
    80006068:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    8000606a:	6088                	ld	a0,0(s1)
    8000606c:	cd75                	beqz	a0,80006168 <virtio_disk_init+0x1e0>
    8000606e:	00024717          	auipc	a4,0x24
    80006072:	14273703          	ld	a4,322(a4) # 8002a1b0 <disk+0x8>
    80006076:	cb6d                	beqz	a4,80006168 <virtio_disk_init+0x1e0>
    80006078:	cbe5                	beqz	a5,80006168 <virtio_disk_init+0x1e0>
  memset(disk.desc, 0, PGSIZE);
    8000607a:	6605                	lui	a2,0x1
    8000607c:	4581                	li	a1,0
    8000607e:	ffffb097          	auipc	ra,0xffffb
    80006082:	c68080e7          	jalr	-920(ra) # 80000ce6 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006086:	00024497          	auipc	s1,0x24
    8000608a:	12248493          	addi	s1,s1,290 # 8002a1a8 <disk>
    8000608e:	6605                	lui	a2,0x1
    80006090:	4581                	li	a1,0
    80006092:	6488                	ld	a0,8(s1)
    80006094:	ffffb097          	auipc	ra,0xffffb
    80006098:	c52080e7          	jalr	-942(ra) # 80000ce6 <memset>
  memset(disk.used, 0, PGSIZE);
    8000609c:	6605                	lui	a2,0x1
    8000609e:	4581                	li	a1,0
    800060a0:	6888                	ld	a0,16(s1)
    800060a2:	ffffb097          	auipc	ra,0xffffb
    800060a6:	c44080e7          	jalr	-956(ra) # 80000ce6 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800060aa:	100017b7          	lui	a5,0x10001
    800060ae:	4721                	li	a4,8
    800060b0:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800060b2:	4098                	lw	a4,0(s1)
    800060b4:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800060b8:	40d8                	lw	a4,4(s1)
    800060ba:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800060be:	6498                	ld	a4,8(s1)
    800060c0:	0007069b          	sext.w	a3,a4
    800060c4:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800060c8:	9701                	srai	a4,a4,0x20
    800060ca:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800060ce:	6898                	ld	a4,16(s1)
    800060d0:	0007069b          	sext.w	a3,a4
    800060d4:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800060d8:	9701                	srai	a4,a4,0x20
    800060da:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800060de:	4685                	li	a3,1
    800060e0:	c3f4                	sw	a3,68(a5)
    disk.free[i] = 1;
    800060e2:	4705                	li	a4,1
    800060e4:	00d48c23          	sb	a3,24(s1)
    800060e8:	00e48ca3          	sb	a4,25(s1)
    800060ec:	00e48d23          	sb	a4,26(s1)
    800060f0:	00e48da3          	sb	a4,27(s1)
    800060f4:	00e48e23          	sb	a4,28(s1)
    800060f8:	00e48ea3          	sb	a4,29(s1)
    800060fc:	00e48f23          	sb	a4,30(s1)
    80006100:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006104:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006108:	0727a823          	sw	s2,112(a5)
}
    8000610c:	60e2                	ld	ra,24(sp)
    8000610e:	6442                	ld	s0,16(sp)
    80006110:	64a2                	ld	s1,8(sp)
    80006112:	6902                	ld	s2,0(sp)
    80006114:	6105                	addi	sp,sp,32
    80006116:	8082                	ret
    panic("could not find virtio disk");
    80006118:	00003517          	auipc	a0,0x3
    8000611c:	84050513          	addi	a0,a0,-1984 # 80008958 <syscalls+0x360>
    80006120:	ffffa097          	auipc	ra,0xffffa
    80006124:	424080e7          	jalr	1060(ra) # 80000544 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006128:	00003517          	auipc	a0,0x3
    8000612c:	85050513          	addi	a0,a0,-1968 # 80008978 <syscalls+0x380>
    80006130:	ffffa097          	auipc	ra,0xffffa
    80006134:	414080e7          	jalr	1044(ra) # 80000544 <panic>
    panic("virtio disk should not be ready");
    80006138:	00003517          	auipc	a0,0x3
    8000613c:	86050513          	addi	a0,a0,-1952 # 80008998 <syscalls+0x3a0>
    80006140:	ffffa097          	auipc	ra,0xffffa
    80006144:	404080e7          	jalr	1028(ra) # 80000544 <panic>
    panic("virtio disk has no queue 0");
    80006148:	00003517          	auipc	a0,0x3
    8000614c:	87050513          	addi	a0,a0,-1936 # 800089b8 <syscalls+0x3c0>
    80006150:	ffffa097          	auipc	ra,0xffffa
    80006154:	3f4080e7          	jalr	1012(ra) # 80000544 <panic>
    panic("virtio disk max queue too short");
    80006158:	00003517          	auipc	a0,0x3
    8000615c:	88050513          	addi	a0,a0,-1920 # 800089d8 <syscalls+0x3e0>
    80006160:	ffffa097          	auipc	ra,0xffffa
    80006164:	3e4080e7          	jalr	996(ra) # 80000544 <panic>
    panic("virtio disk kalloc");
    80006168:	00003517          	auipc	a0,0x3
    8000616c:	89050513          	addi	a0,a0,-1904 # 800089f8 <syscalls+0x400>
    80006170:	ffffa097          	auipc	ra,0xffffa
    80006174:	3d4080e7          	jalr	980(ra) # 80000544 <panic>

0000000080006178 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006178:	7159                	addi	sp,sp,-112
    8000617a:	f486                	sd	ra,104(sp)
    8000617c:	f0a2                	sd	s0,96(sp)
    8000617e:	eca6                	sd	s1,88(sp)
    80006180:	e8ca                	sd	s2,80(sp)
    80006182:	e4ce                	sd	s3,72(sp)
    80006184:	e0d2                	sd	s4,64(sp)
    80006186:	fc56                	sd	s5,56(sp)
    80006188:	f85a                	sd	s6,48(sp)
    8000618a:	f45e                	sd	s7,40(sp)
    8000618c:	f062                	sd	s8,32(sp)
    8000618e:	ec66                	sd	s9,24(sp)
    80006190:	e86a                	sd	s10,16(sp)
    80006192:	1880                	addi	s0,sp,112
    80006194:	892a                	mv	s2,a0
    80006196:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006198:	00c52c83          	lw	s9,12(a0)
    8000619c:	001c9c9b          	slliw	s9,s9,0x1
    800061a0:	1c82                	slli	s9,s9,0x20
    800061a2:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800061a6:	00024517          	auipc	a0,0x24
    800061aa:	12a50513          	addi	a0,a0,298 # 8002a2d0 <disk+0x128>
    800061ae:	ffffb097          	auipc	ra,0xffffb
    800061b2:	a3c080e7          	jalr	-1476(ra) # 80000bea <acquire>
  for(int i = 0; i < 3; i++){
    800061b6:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800061b8:	4ba1                	li	s7,8
      disk.free[i] = 0;
    800061ba:	00024b17          	auipc	s6,0x24
    800061be:	feeb0b13          	addi	s6,s6,-18 # 8002a1a8 <disk>
  for(int i = 0; i < 3; i++){
    800061c2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800061c4:	8a4e                	mv	s4,s3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800061c6:	00024c17          	auipc	s8,0x24
    800061ca:	10ac0c13          	addi	s8,s8,266 # 8002a2d0 <disk+0x128>
    800061ce:	a8b5                	j	8000624a <virtio_disk_rw+0xd2>
      disk.free[i] = 0;
    800061d0:	00fb06b3          	add	a3,s6,a5
    800061d4:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800061d8:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800061da:	0207c563          	bltz	a5,80006204 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    800061de:	2485                	addiw	s1,s1,1
    800061e0:	0711                	addi	a4,a4,4
    800061e2:	1f548a63          	beq	s1,s5,800063d6 <virtio_disk_rw+0x25e>
    idx[i] = alloc_desc();
    800061e6:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800061e8:	00024697          	auipc	a3,0x24
    800061ec:	fc068693          	addi	a3,a3,-64 # 8002a1a8 <disk>
    800061f0:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800061f2:	0186c583          	lbu	a1,24(a3)
    800061f6:	fde9                	bnez	a1,800061d0 <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    800061f8:	2785                	addiw	a5,a5,1
    800061fa:	0685                	addi	a3,a3,1
    800061fc:	ff779be3          	bne	a5,s7,800061f2 <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    80006200:	57fd                	li	a5,-1
    80006202:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006204:	02905a63          	blez	s1,80006238 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    80006208:	f9042503          	lw	a0,-112(s0)
    8000620c:	00000097          	auipc	ra,0x0
    80006210:	cfa080e7          	jalr	-774(ra) # 80005f06 <free_desc>
      for(int j = 0; j < i; j++)
    80006214:	4785                	li	a5,1
    80006216:	0297d163          	bge	a5,s1,80006238 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    8000621a:	f9442503          	lw	a0,-108(s0)
    8000621e:	00000097          	auipc	ra,0x0
    80006222:	ce8080e7          	jalr	-792(ra) # 80005f06 <free_desc>
      for(int j = 0; j < i; j++)
    80006226:	4789                	li	a5,2
    80006228:	0097d863          	bge	a5,s1,80006238 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    8000622c:	f9842503          	lw	a0,-104(s0)
    80006230:	00000097          	auipc	ra,0x0
    80006234:	cd6080e7          	jalr	-810(ra) # 80005f06 <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006238:	85e2                	mv	a1,s8
    8000623a:	00024517          	auipc	a0,0x24
    8000623e:	f8650513          	addi	a0,a0,-122 # 8002a1c0 <disk+0x18>
    80006242:	ffffc097          	auipc	ra,0xffffc
    80006246:	ec8080e7          	jalr	-312(ra) # 8000210a <sleep>
  for(int i = 0; i < 3; i++){
    8000624a:	f9040713          	addi	a4,s0,-112
    8000624e:	84ce                	mv	s1,s3
    80006250:	bf59                	j	800061e6 <virtio_disk_rw+0x6e>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006252:	00a60793          	addi	a5,a2,10 # 100a <_entry-0x7fffeff6>
    80006256:	00479693          	slli	a3,a5,0x4
    8000625a:	00024797          	auipc	a5,0x24
    8000625e:	f4e78793          	addi	a5,a5,-178 # 8002a1a8 <disk>
    80006262:	97b6                	add	a5,a5,a3
    80006264:	4685                	li	a3,1
    80006266:	c794                	sw	a3,8(a5)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006268:	00024597          	auipc	a1,0x24
    8000626c:	f4058593          	addi	a1,a1,-192 # 8002a1a8 <disk>
    80006270:	00a60793          	addi	a5,a2,10
    80006274:	0792                	slli	a5,a5,0x4
    80006276:	97ae                	add	a5,a5,a1
    80006278:	0007a623          	sw	zero,12(a5)
  buf0->sector = sector;
    8000627c:	0197b823          	sd	s9,16(a5)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006280:	f6070693          	addi	a3,a4,-160
    80006284:	619c                	ld	a5,0(a1)
    80006286:	97b6                	add	a5,a5,a3
    80006288:	e388                	sd	a0,0(a5)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000628a:	6188                	ld	a0,0(a1)
    8000628c:	96aa                	add	a3,a3,a0
    8000628e:	47c1                	li	a5,16
    80006290:	c69c                	sw	a5,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006292:	4785                	li	a5,1
    80006294:	00f69623          	sh	a5,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006298:	f9442783          	lw	a5,-108(s0)
    8000629c:	00f69723          	sh	a5,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800062a0:	0792                	slli	a5,a5,0x4
    800062a2:	953e                	add	a0,a0,a5
    800062a4:	05890693          	addi	a3,s2,88
    800062a8:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    800062aa:	6188                	ld	a0,0(a1)
    800062ac:	97aa                	add	a5,a5,a0
    800062ae:	40000693          	li	a3,1024
    800062b2:	c794                	sw	a3,8(a5)
  if(write)
    800062b4:	100d0d63          	beqz	s10,800063ce <virtio_disk_rw+0x256>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800062b8:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800062bc:	00c7d683          	lhu	a3,12(a5)
    800062c0:	0016e693          	ori	a3,a3,1
    800062c4:	00d79623          	sh	a3,12(a5)
  disk.desc[idx[1]].next = idx[2];
    800062c8:	f9842583          	lw	a1,-104(s0)
    800062cc:	00b79723          	sh	a1,14(a5)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800062d0:	00024697          	auipc	a3,0x24
    800062d4:	ed868693          	addi	a3,a3,-296 # 8002a1a8 <disk>
    800062d8:	00260793          	addi	a5,a2,2
    800062dc:	0792                	slli	a5,a5,0x4
    800062de:	97b6                	add	a5,a5,a3
    800062e0:	587d                	li	a6,-1
    800062e2:	01078823          	sb	a6,16(a5)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800062e6:	0592                	slli	a1,a1,0x4
    800062e8:	952e                	add	a0,a0,a1
    800062ea:	f9070713          	addi	a4,a4,-112
    800062ee:	9736                	add	a4,a4,a3
    800062f0:	e118                	sd	a4,0(a0)
  disk.desc[idx[2]].len = 1;
    800062f2:	6298                	ld	a4,0(a3)
    800062f4:	972e                	add	a4,a4,a1
    800062f6:	4585                	li	a1,1
    800062f8:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800062fa:	4509                	li	a0,2
    800062fc:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[2]].next = 0;
    80006300:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006304:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006308:	0127b423          	sd	s2,8(a5)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    8000630c:	6698                	ld	a4,8(a3)
    8000630e:	00275783          	lhu	a5,2(a4)
    80006312:	8b9d                	andi	a5,a5,7
    80006314:	0786                	slli	a5,a5,0x1
    80006316:	97ba                	add	a5,a5,a4
    80006318:	00c79223          	sh	a2,4(a5)

  __sync_synchronize();
    8000631c:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006320:	6698                	ld	a4,8(a3)
    80006322:	00275783          	lhu	a5,2(a4)
    80006326:	2785                	addiw	a5,a5,1
    80006328:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    8000632c:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006330:	100017b7          	lui	a5,0x10001
    80006334:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006338:	00492703          	lw	a4,4(s2)
    8000633c:	4785                	li	a5,1
    8000633e:	02f71163          	bne	a4,a5,80006360 <virtio_disk_rw+0x1e8>
    sleep(b, &disk.vdisk_lock);
    80006342:	00024997          	auipc	s3,0x24
    80006346:	f8e98993          	addi	s3,s3,-114 # 8002a2d0 <disk+0x128>
  while(b->disk == 1) {
    8000634a:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    8000634c:	85ce                	mv	a1,s3
    8000634e:	854a                	mv	a0,s2
    80006350:	ffffc097          	auipc	ra,0xffffc
    80006354:	dba080e7          	jalr	-582(ra) # 8000210a <sleep>
  while(b->disk == 1) {
    80006358:	00492783          	lw	a5,4(s2)
    8000635c:	fe9788e3          	beq	a5,s1,8000634c <virtio_disk_rw+0x1d4>
  }

  disk.info[idx[0]].b = 0;
    80006360:	f9042903          	lw	s2,-112(s0)
    80006364:	00290793          	addi	a5,s2,2
    80006368:	00479713          	slli	a4,a5,0x4
    8000636c:	00024797          	auipc	a5,0x24
    80006370:	e3c78793          	addi	a5,a5,-452 # 8002a1a8 <disk>
    80006374:	97ba                	add	a5,a5,a4
    80006376:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000637a:	00024997          	auipc	s3,0x24
    8000637e:	e2e98993          	addi	s3,s3,-466 # 8002a1a8 <disk>
    80006382:	00491713          	slli	a4,s2,0x4
    80006386:	0009b783          	ld	a5,0(s3)
    8000638a:	97ba                	add	a5,a5,a4
    8000638c:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006390:	854a                	mv	a0,s2
    80006392:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006396:	00000097          	auipc	ra,0x0
    8000639a:	b70080e7          	jalr	-1168(ra) # 80005f06 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000639e:	8885                	andi	s1,s1,1
    800063a0:	f0ed                	bnez	s1,80006382 <virtio_disk_rw+0x20a>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800063a2:	00024517          	auipc	a0,0x24
    800063a6:	f2e50513          	addi	a0,a0,-210 # 8002a2d0 <disk+0x128>
    800063aa:	ffffb097          	auipc	ra,0xffffb
    800063ae:	8f4080e7          	jalr	-1804(ra) # 80000c9e <release>
}
    800063b2:	70a6                	ld	ra,104(sp)
    800063b4:	7406                	ld	s0,96(sp)
    800063b6:	64e6                	ld	s1,88(sp)
    800063b8:	6946                	ld	s2,80(sp)
    800063ba:	69a6                	ld	s3,72(sp)
    800063bc:	6a06                	ld	s4,64(sp)
    800063be:	7ae2                	ld	s5,56(sp)
    800063c0:	7b42                	ld	s6,48(sp)
    800063c2:	7ba2                	ld	s7,40(sp)
    800063c4:	7c02                	ld	s8,32(sp)
    800063c6:	6ce2                	ld	s9,24(sp)
    800063c8:	6d42                	ld	s10,16(sp)
    800063ca:	6165                	addi	sp,sp,112
    800063cc:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800063ce:	4689                	li	a3,2
    800063d0:	00d79623          	sh	a3,12(a5)
    800063d4:	b5e5                	j	800062bc <virtio_disk_rw+0x144>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800063d6:	f9042603          	lw	a2,-112(s0)
    800063da:	00a60713          	addi	a4,a2,10
    800063de:	0712                	slli	a4,a4,0x4
    800063e0:	00024517          	auipc	a0,0x24
    800063e4:	dd050513          	addi	a0,a0,-560 # 8002a1b0 <disk+0x8>
    800063e8:	953a                	add	a0,a0,a4
  if(write)
    800063ea:	e60d14e3          	bnez	s10,80006252 <virtio_disk_rw+0xda>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800063ee:	00a60793          	addi	a5,a2,10
    800063f2:	00479693          	slli	a3,a5,0x4
    800063f6:	00024797          	auipc	a5,0x24
    800063fa:	db278793          	addi	a5,a5,-590 # 8002a1a8 <disk>
    800063fe:	97b6                	add	a5,a5,a3
    80006400:	0007a423          	sw	zero,8(a5)
    80006404:	b595                	j	80006268 <virtio_disk_rw+0xf0>

0000000080006406 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006406:	1101                	addi	sp,sp,-32
    80006408:	ec06                	sd	ra,24(sp)
    8000640a:	e822                	sd	s0,16(sp)
    8000640c:	e426                	sd	s1,8(sp)
    8000640e:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006410:	00024497          	auipc	s1,0x24
    80006414:	d9848493          	addi	s1,s1,-616 # 8002a1a8 <disk>
    80006418:	00024517          	auipc	a0,0x24
    8000641c:	eb850513          	addi	a0,a0,-328 # 8002a2d0 <disk+0x128>
    80006420:	ffffa097          	auipc	ra,0xffffa
    80006424:	7ca080e7          	jalr	1994(ra) # 80000bea <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006428:	10001737          	lui	a4,0x10001
    8000642c:	533c                	lw	a5,96(a4)
    8000642e:	8b8d                	andi	a5,a5,3
    80006430:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006432:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006436:	689c                	ld	a5,16(s1)
    80006438:	0204d703          	lhu	a4,32(s1)
    8000643c:	0027d783          	lhu	a5,2(a5)
    80006440:	04f70863          	beq	a4,a5,80006490 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006444:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006448:	6898                	ld	a4,16(s1)
    8000644a:	0204d783          	lhu	a5,32(s1)
    8000644e:	8b9d                	andi	a5,a5,7
    80006450:	078e                	slli	a5,a5,0x3
    80006452:	97ba                	add	a5,a5,a4
    80006454:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006456:	00278713          	addi	a4,a5,2
    8000645a:	0712                	slli	a4,a4,0x4
    8000645c:	9726                	add	a4,a4,s1
    8000645e:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006462:	e721                	bnez	a4,800064aa <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006464:	0789                	addi	a5,a5,2
    80006466:	0792                	slli	a5,a5,0x4
    80006468:	97a6                	add	a5,a5,s1
    8000646a:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000646c:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006470:	ffffc097          	auipc	ra,0xffffc
    80006474:	cfe080e7          	jalr	-770(ra) # 8000216e <wakeup>

    disk.used_idx += 1;
    80006478:	0204d783          	lhu	a5,32(s1)
    8000647c:	2785                	addiw	a5,a5,1
    8000647e:	17c2                	slli	a5,a5,0x30
    80006480:	93c1                	srli	a5,a5,0x30
    80006482:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006486:	6898                	ld	a4,16(s1)
    80006488:	00275703          	lhu	a4,2(a4)
    8000648c:	faf71ce3          	bne	a4,a5,80006444 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006490:	00024517          	auipc	a0,0x24
    80006494:	e4050513          	addi	a0,a0,-448 # 8002a2d0 <disk+0x128>
    80006498:	ffffb097          	auipc	ra,0xffffb
    8000649c:	806080e7          	jalr	-2042(ra) # 80000c9e <release>
}
    800064a0:	60e2                	ld	ra,24(sp)
    800064a2:	6442                	ld	s0,16(sp)
    800064a4:	64a2                	ld	s1,8(sp)
    800064a6:	6105                	addi	sp,sp,32
    800064a8:	8082                	ret
      panic("virtio_disk_intr status");
    800064aa:	00002517          	auipc	a0,0x2
    800064ae:	56650513          	addi	a0,a0,1382 # 80008a10 <syscalls+0x418>
    800064b2:	ffffa097          	auipc	ra,0xffffa
    800064b6:	092080e7          	jalr	146(ra) # 80000544 <panic>

00000000800064ba <open>:
  iunlockput(dp);
  return 0;
}


struct file *open(char *filename){
    800064ba:	7179                	addi	sp,sp,-48
    800064bc:	f406                	sd	ra,40(sp)
    800064be:	f022                	sd	s0,32(sp)
    800064c0:	ec26                	sd	s1,24(sp)
    800064c2:	e84a                	sd	s2,16(sp)
    800064c4:	1800                	addi	s0,sp,48
    800064c6:	84aa                	mv	s1,a0
    int omode;
    struct file *f;
    struct inode *ip;

    omode = O_CREATE;
    if(strlen(filename) < 0)
    800064c8:	ffffb097          	auipc	ra,0xffffb
    800064cc:	9a2080e7          	jalr	-1630(ra) # 80000e6a <strlen>
	return (struct file *)-1;
    800064d0:	597d                	li	s2,-1
    if(strlen(filename) < 0)
    800064d2:	10054f63          	bltz	a0,800065f0 <open+0x136>

    begin_op();
    800064d6:	ffffe097          	auipc	ra,0xffffe
    800064da:	dd2080e7          	jalr	-558(ra) # 800042a8 <begin_op>
  if((dp = nameiparent(path, name)) == 0)
    800064de:	fd040593          	addi	a1,s0,-48
    800064e2:	8526                	mv	a0,s1
    800064e4:	ffffe097          	auipc	ra,0xffffe
    800064e8:	bc6080e7          	jalr	-1082(ra) # 800040aa <nameiparent>
    800064ec:	892a                	mv	s2,a0
    800064ee:	10050d63          	beqz	a0,80006608 <open+0x14e>
  ilock(dp);
    800064f2:	ffffd097          	auipc	ra,0xffffd
    800064f6:	3f4080e7          	jalr	1012(ra) # 800038e6 <ilock>
  if((ip = dirlookup(dp, name, 0)) != 0){
    800064fa:	4601                	li	a2,0
    800064fc:	fd040593          	addi	a1,s0,-48
    80006500:	854a                	mv	a0,s2
    80006502:	ffffe097          	auipc	ra,0xffffe
    80006506:	8c8080e7          	jalr	-1848(ra) # 80003dca <dirlookup>
    8000650a:	84aa                	mv	s1,a0
    8000650c:	10050463          	beqz	a0,80006614 <open+0x15a>
    iunlockput(dp);
    80006510:	854a                	mv	a0,s2
    80006512:	ffffd097          	auipc	ra,0xffffd
    80006516:	636080e7          	jalr	1590(ra) # 80003b48 <iunlockput>
    ilock(ip);
    8000651a:	8526                	mv	a0,s1
    8000651c:	ffffd097          	auipc	ra,0xffffd
    80006520:	3ca080e7          	jalr	970(ra) # 800038e6 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80006524:	0444d783          	lhu	a5,68(s1)
    80006528:	37f9                	addiw	a5,a5,-2
    8000652a:	17c2                	slli	a5,a5,0x30
    8000652c:	93c1                	srli	a5,a5,0x30
    8000652e:	4705                	li	a4,1
    80006530:	0cf76763          	bltu	a4,a5,800065fe <open+0x144>
	    printf("OOPs");
	    //this is where it breaks`
	    return (struct file *)-1;
	}
    }
    printf("Gone\n");
    80006534:	00002517          	auipc	a0,0x2
    80006538:	52450513          	addi	a0,a0,1316 # 80008a58 <syscalls+0x460>
    8000653c:	ffffa097          	auipc	ra,0xffffa
    80006540:	052080e7          	jalr	82(ra) # 8000058e <printf>
//    ilock(ip);

    printf("Gone\n");
    80006544:	00002517          	auipc	a0,0x2
    80006548:	51450513          	addi	a0,a0,1300 # 80008a58 <syscalls+0x460>
    8000654c:	ffffa097          	auipc	ra,0xffffa
    80006550:	042080e7          	jalr	66(ra) # 8000058e <printf>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80006554:	04449703          	lh	a4,68(s1)
    80006558:	4785                	li	a5,1
    8000655a:	14f70663          	beq	a4,a5,800066a6 <open+0x1ec>
	iunlockput(ip);
	end_op();
	return (struct file *)-1;
    }
    printf("1\n");
    8000655e:	00002517          	auipc	a0,0x2
    80006562:	4d250513          	addi	a0,a0,1234 # 80008a30 <syscalls+0x438>
    80006566:	ffffa097          	auipc	ra,0xffffa
    8000656a:	028080e7          	jalr	40(ra) # 8000058e <printf>
    

    if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000656e:	04449703          	lh	a4,68(s1)
    80006572:	478d                	li	a5,3
    80006574:	00f71763          	bne	a4,a5,80006582 <open+0xc8>
    80006578:	0464d703          	lhu	a4,70(s1)
    8000657c:	47a5                	li	a5,9
    8000657e:	12e7ef63          	bltu	a5,a4,800066bc <open+0x202>
	iunlockput(ip);
	end_op();
	return (struct file *)-1;
    }

	printf("2\n");
    80006582:	00002517          	auipc	a0,0x2
    80006586:	4b650513          	addi	a0,a0,1206 # 80008a38 <syscalls+0x440>
    8000658a:	ffffa097          	auipc	ra,0xffffa
    8000658e:	004080e7          	jalr	4(ra) # 8000058e <printf>
    if((f = filealloc()) == 0){
    80006592:	ffffe097          	auipc	ra,0xffffe
    80006596:	126080e7          	jalr	294(ra) # 800046b8 <filealloc>
    8000659a:	892a                	mv	s2,a0
    8000659c:	12050b63          	beqz	a0,800066d2 <open+0x218>
	iunlockput(ip);
	end_op();
	return (struct file *)-1;
    }

	printf("3\n");
    800065a0:	00002517          	auipc	a0,0x2
    800065a4:	4a050513          	addi	a0,a0,1184 # 80008a40 <syscalls+0x448>
    800065a8:	ffffa097          	auipc	ra,0xffffa
    800065ac:	fe6080e7          	jalr	-26(ra) # 8000058e <printf>
   f->type = FD_INODE;
    800065b0:	4789                	li	a5,2
    800065b2:	00f92023          	sw	a5,0(s2)
   f->off = 0;
    800065b6:	02092023          	sw	zero,32(s2)
   f->ip = ip;
    800065ba:	00993c23          	sd	s1,24(s2)
   f->readable = !(omode & O_WRONLY);
    800065be:	4785                	li	a5,1
    800065c0:	00f90423          	sb	a5,8(s2)
   f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800065c4:	000904a3          	sb	zero,9(s2)

   if((omode & O_TRUNC) && ip->type == T_FILE){
     itrunc(ip);
   }

	printf("4\n");
    800065c8:	00002517          	auipc	a0,0x2
    800065cc:	48050513          	addi	a0,a0,1152 # 80008a48 <syscalls+0x450>
    800065d0:	ffffa097          	auipc	ra,0xffffa
    800065d4:	fbe080e7          	jalr	-66(ra) # 8000058e <printf>
   //iunlock(ip);
   end_op();
    800065d8:	ffffe097          	auipc	ra,0xffffe
    800065dc:	d50080e7          	jalr	-688(ra) # 80004328 <end_op>

	printf("5\n");
    800065e0:	00002517          	auipc	a0,0x2
    800065e4:	47050513          	addi	a0,a0,1136 # 80008a50 <syscalls+0x458>
    800065e8:	ffffa097          	auipc	ra,0xffffa
    800065ec:	fa6080e7          	jalr	-90(ra) # 8000058e <printf>
   return f;
}
    800065f0:	854a                	mv	a0,s2
    800065f2:	70a2                	ld	ra,40(sp)
    800065f4:	7402                	ld	s0,32(sp)
    800065f6:	64e2                	ld	s1,24(sp)
    800065f8:	6942                	ld	s2,16(sp)
    800065fa:	6145                	addi	sp,sp,48
    800065fc:	8082                	ret
    iunlockput(ip);
    800065fe:	8526                	mv	a0,s1
    80006600:	ffffd097          	auipc	ra,0xffffd
    80006604:	548080e7          	jalr	1352(ra) # 80003b48 <iunlockput>
	    end_op();
    80006608:	ffffe097          	auipc	ra,0xffffe
    8000660c:	d20080e7          	jalr	-736(ra) # 80004328 <end_op>
	    return (struct file *)-1;
    80006610:	597d                	li	s2,-1
    80006612:	bff9                	j	800065f0 <open+0x136>
  if((ip = ialloc(dp->dev, type)) == 0){
    80006614:	4589                	li	a1,2
    80006616:	00092503          	lw	a0,0(s2)
    8000661a:	ffffd097          	auipc	ra,0xffffd
    8000661e:	130080e7          	jalr	304(ra) # 8000374a <ialloc>
    80006622:	84aa                	mv	s1,a0
    80006624:	c929                	beqz	a0,80006676 <open+0x1bc>
  ilock(ip);
    80006626:	ffffd097          	auipc	ra,0xffffd
    8000662a:	2c0080e7          	jalr	704(ra) # 800038e6 <ilock>
  ip->major = major;
    8000662e:	04049323          	sh	zero,70(s1)
  ip->minor = minor;
    80006632:	04049423          	sh	zero,72(s1)
  ip->nlink = 1;
    80006636:	4785                	li	a5,1
    80006638:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000663c:	8526                	mv	a0,s1
    8000663e:	ffffd097          	auipc	ra,0xffffd
    80006642:	1de080e7          	jalr	478(ra) # 8000381c <iupdate>
  if(dirlink(dp, name, ip->inum) < 0)
    80006646:	40d0                	lw	a2,4(s1)
    80006648:	fd040593          	addi	a1,s0,-48
    8000664c:	854a                	mv	a0,s2
    8000664e:	ffffe097          	auipc	ra,0xffffe
    80006652:	98c080e7          	jalr	-1652(ra) # 80003fda <dirlink>
    80006656:	02054663          	bltz	a0,80006682 <open+0x1c8>
  iunlockput(dp);
    8000665a:	854a                	mv	a0,s2
    8000665c:	ffffd097          	auipc	ra,0xffffd
    80006660:	4ec080e7          	jalr	1260(ra) # 80003b48 <iunlockput>
  printf("Happy\n");
    80006664:	00002517          	auipc	a0,0x2
    80006668:	3c450513          	addi	a0,a0,964 # 80008a28 <syscalls+0x430>
    8000666c:	ffffa097          	auipc	ra,0xffffa
    80006670:	f22080e7          	jalr	-222(ra) # 8000058e <printf>
  return ip;
    80006674:	b5c1                	j	80006534 <open+0x7a>
    iunlockput(dp);
    80006676:	854a                	mv	a0,s2
    80006678:	ffffd097          	auipc	ra,0xffffd
    8000667c:	4d0080e7          	jalr	1232(ra) # 80003b48 <iunlockput>
    return 0;
    80006680:	b761                	j	80006608 <open+0x14e>
  ip->nlink = 0;
    80006682:	04049523          	sh	zero,74(s1)
  iupdate(ip);
    80006686:	8526                	mv	a0,s1
    80006688:	ffffd097          	auipc	ra,0xffffd
    8000668c:	194080e7          	jalr	404(ra) # 8000381c <iupdate>
  iunlockput(ip);
    80006690:	8526                	mv	a0,s1
    80006692:	ffffd097          	auipc	ra,0xffffd
    80006696:	4b6080e7          	jalr	1206(ra) # 80003b48 <iunlockput>
  iunlockput(dp);
    8000669a:	854a                	mv	a0,s2
    8000669c:	ffffd097          	auipc	ra,0xffffd
    800066a0:	4ac080e7          	jalr	1196(ra) # 80003b48 <iunlockput>
  return 0;
    800066a4:	b795                	j	80006608 <open+0x14e>
	iunlockput(ip);
    800066a6:	8526                	mv	a0,s1
    800066a8:	ffffd097          	auipc	ra,0xffffd
    800066ac:	4a0080e7          	jalr	1184(ra) # 80003b48 <iunlockput>
	end_op();
    800066b0:	ffffe097          	auipc	ra,0xffffe
    800066b4:	c78080e7          	jalr	-904(ra) # 80004328 <end_op>
	return (struct file *)-1;
    800066b8:	597d                	li	s2,-1
    800066ba:	bf1d                	j	800065f0 <open+0x136>
	iunlockput(ip);
    800066bc:	8526                	mv	a0,s1
    800066be:	ffffd097          	auipc	ra,0xffffd
    800066c2:	48a080e7          	jalr	1162(ra) # 80003b48 <iunlockput>
	end_op();
    800066c6:	ffffe097          	auipc	ra,0xffffe
    800066ca:	c62080e7          	jalr	-926(ra) # 80004328 <end_op>
	return (struct file *)-1;
    800066ce:	597d                	li	s2,-1
    800066d0:	b705                	j	800065f0 <open+0x136>
	iunlockput(ip);
    800066d2:	8526                	mv	a0,s1
    800066d4:	ffffd097          	auipc	ra,0xffffd
    800066d8:	474080e7          	jalr	1140(ra) # 80003b48 <iunlockput>
	end_op();
    800066dc:	ffffe097          	auipc	ra,0xffffe
    800066e0:	c4c080e7          	jalr	-948(ra) # 80004328 <end_op>
	return (struct file *)-1;
    800066e4:	597d                	li	s2,-1
    800066e6:	b729                	j	800065f0 <open+0x136>

00000000800066e8 <write_to_logs>:

void write_to_logs(void *list){
    800066e8:	7179                	addi	sp,sp,-48
    800066ea:	f406                	sd	ra,40(sp)
    800066ec:	f022                	sd	s0,32(sp)
    800066ee:	ec26                	sd	s1,24(sp)
    800066f0:	1800                	addi	s0,sp,48
    f->writable = O_WRONLY;

    iunlock(ip);
*/

    f = open(filename);
    800066f2:	00002517          	auipc	a0,0x2
    800066f6:	36e50513          	addi	a0,a0,878 # 80008a60 <syscalls+0x468>
    800066fa:	00000097          	auipc	ra,0x0
    800066fe:	dc0080e7          	jalr	-576(ra) # 800064ba <open>
    80006702:	84aa                	mv	s1,a0

//    uint64 fd = open(filename);
    if(f == (struct file *)-1)
    80006704:	57fd                	li	a5,-1
    80006706:	04f50763          	beq	a0,a5,80006754 <write_to_logs+0x6c>
	exit(0);
    //write(fd, data, strlen(data)); 
    //struct audit_list *auditlist = (struct audit_list *)list;
    //struct audit_node *node = auditlist -> head;
    printf("6\n");
    8000670a:	00002517          	auipc	a0,0x2
    8000670e:	36650513          	addi	a0,a0,870 # 80008a70 <syscalls+0x478>
    80006712:	ffffa097          	auipc	ra,0xffffa
    80006716:	e7c080e7          	jalr	-388(ra) # 8000058e <printf>
    char temp[5] = "happ";
    8000671a:	707067b7          	lui	a5,0x70706
    8000671e:	1687879b          	addiw	a5,a5,360
    80006722:	fcf42c23          	sw	a5,-40(s0)
    80006726:	fc040e23          	sb	zero,-36(s0)
    filewrite(f, (uint64)(temp), 5);
    8000672a:	4615                	li	a2,5
    8000672c:	fd840593          	addi	a1,s0,-40
    80006730:	8526                	mv	a0,s1
    80006732:	ffffe097          	auipc	ra,0xffffe
    80006736:	23e080e7          	jalr	574(ra) # 80004970 <filewrite>
    while(node != 0){
	filewrite(f, (uint64)(node -> process_name), strlen(node -> process_name));
	node = node -> next;
    }
    */
    printf("What\n");
    8000673a:	00002517          	auipc	a0,0x2
    8000673e:	33e50513          	addi	a0,a0,830 # 80008a78 <syscalls+0x480>
    80006742:	ffffa097          	auipc	ra,0xffffa
    80006746:	e4c080e7          	jalr	-436(ra) # 8000058e <printf>


}
    8000674a:	70a2                	ld	ra,40(sp)
    8000674c:	7402                	ld	s0,32(sp)
    8000674e:	64e2                	ld	s1,24(sp)
    80006750:	6145                	addi	sp,sp,48
    80006752:	8082                	ret
	exit(0);
    80006754:	4501                	li	a0,0
    80006756:	ffffc097          	auipc	ra,0xffffc
    8000675a:	ae8080e7          	jalr	-1304(ra) # 8000223e <exit>
    8000675e:	b775                	j	8000670a <write_to_logs+0x22>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
