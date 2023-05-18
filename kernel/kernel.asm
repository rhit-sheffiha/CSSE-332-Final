
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	bc013103          	ld	sp,-1088(sp) # 80008bc0 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000056:	bce70713          	addi	a4,a4,-1074 # 80008c20 <timer_scratch>
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
    80000068:	e1c78793          	addi	a5,a5,-484 # 80005e80 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd44f7>
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
    80000190:	bd450513          	addi	a0,a0,-1068 # 80010d60 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a56080e7          	jalr	-1450(ra) # 80000bea <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	bc448493          	addi	s1,s1,-1084 # 80010d60 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	c5290913          	addi	s2,s2,-942 # 80010df8 <cons+0x98>
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
    8000022e:	b3650513          	addi	a0,a0,-1226 # 80010d60 <cons>
    80000232:	00001097          	auipc	ra,0x1
    80000236:	a6c080e7          	jalr	-1428(ra) # 80000c9e <release>

  return target - n;
    8000023a:	414b853b          	subw	a0,s7,s4
    8000023e:	a811                	j	80000252 <consoleread+0xee>
        release(&cons.lock);
    80000240:	00011517          	auipc	a0,0x11
    80000244:	b2050513          	addi	a0,a0,-1248 # 80010d60 <cons>
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
    8000027c:	b8f72023          	sw	a5,-1152(a4) # 80010df8 <cons+0x98>
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
    800002d6:	a8e50513          	addi	a0,a0,-1394 # 80010d60 <cons>
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
    80000304:	a6050513          	addi	a0,a0,-1440 # 80010d60 <cons>
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
    80000328:	a3c70713          	addi	a4,a4,-1476 # 80010d60 <cons>
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
    80000352:	a1278793          	addi	a5,a5,-1518 # 80010d60 <cons>
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
    80000380:	a7c7a783          	lw	a5,-1412(a5) # 80010df8 <cons+0x98>
    80000384:	9f1d                	subw	a4,a4,a5
    80000386:	08000793          	li	a5,128
    8000038a:	f6f71be3          	bne	a4,a5,80000300 <consoleintr+0x3c>
    8000038e:	a07d                	j	8000043c <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000390:	00011717          	auipc	a4,0x11
    80000394:	9d070713          	addi	a4,a4,-1584 # 80010d60 <cons>
    80000398:	0a072783          	lw	a5,160(a4)
    8000039c:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a0:	00011497          	auipc	s1,0x11
    800003a4:	9c048493          	addi	s1,s1,-1600 # 80010d60 <cons>
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
    800003e0:	98470713          	addi	a4,a4,-1660 # 80010d60 <cons>
    800003e4:	0a072783          	lw	a5,160(a4)
    800003e8:	09c72703          	lw	a4,156(a4)
    800003ec:	f0f70ae3          	beq	a4,a5,80000300 <consoleintr+0x3c>
      cons.e--;
    800003f0:	37fd                	addiw	a5,a5,-1
    800003f2:	00011717          	auipc	a4,0x11
    800003f6:	a0f72723          	sw	a5,-1522(a4) # 80010e00 <cons+0xa0>
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
    8000041c:	94878793          	addi	a5,a5,-1720 # 80010d60 <cons>
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
    80000440:	9cc7a023          	sw	a2,-1600(a5) # 80010dfc <cons+0x9c>
        wakeup(&cons.r);
    80000444:	00011517          	auipc	a0,0x11
    80000448:	9b450513          	addi	a0,a0,-1612 # 80010df8 <cons+0x98>
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
    8000046a:	8fa50513          	addi	a0,a0,-1798 # 80010d60 <cons>
    8000046e:	00000097          	auipc	ra,0x0
    80000472:	6ec080e7          	jalr	1772(ra) # 80000b5a <initlock>

  uartinit();
    80000476:	00000097          	auipc	ra,0x0
    8000047a:	330080e7          	jalr	816(ra) # 800007a6 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047e:	00029797          	auipc	a5,0x29
    80000482:	cf278793          	addi	a5,a5,-782 # 80029170 <devsw>
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
    80000554:	8c07a823          	sw	zero,-1840(a5) # 80010e20 <pr+0x18>
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
    80000588:	64f72e23          	sw	a5,1628(a4) # 80008be0 <panicked>
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
    800005c4:	860dad83          	lw	s11,-1952(s11) # 80010e20 <pr+0x18>
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
    800005fe:	00011517          	auipc	a0,0x11
    80000602:	80a50513          	addi	a0,a0,-2038 # 80010e08 <pr>
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
    80000766:	6a650513          	addi	a0,a0,1702 # 80010e08 <pr>
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
    80000782:	68a48493          	addi	s1,s1,1674 # 80010e08 <pr>
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
    800007e2:	64a50513          	addi	a0,a0,1610 # 80010e28 <uart_tx_lock>
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
    8000080e:	3d67a783          	lw	a5,982(a5) # 80008be0 <panicked>
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
    8000084a:	3a273703          	ld	a4,930(a4) # 80008be8 <uart_tx_r>
    8000084e:	00008797          	auipc	a5,0x8
    80000852:	3a27b783          	ld	a5,930(a5) # 80008bf0 <uart_tx_w>
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
    80000874:	5b8a0a13          	addi	s4,s4,1464 # 80010e28 <uart_tx_lock>
    uart_tx_r += 1;
    80000878:	00008497          	auipc	s1,0x8
    8000087c:	37048493          	addi	s1,s1,880 # 80008be8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000880:	00008997          	auipc	s3,0x8
    80000884:	37098993          	addi	s3,s3,880 # 80008bf0 <uart_tx_w>
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
    800008e6:	54650513          	addi	a0,a0,1350 # 80010e28 <uart_tx_lock>
    800008ea:	00000097          	auipc	ra,0x0
    800008ee:	300080e7          	jalr	768(ra) # 80000bea <acquire>
  if(panicked){
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	2ee7a783          	lw	a5,750(a5) # 80008be0 <panicked>
    800008fa:	e7c9                	bnez	a5,80000984 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fc:	00008797          	auipc	a5,0x8
    80000900:	2f47b783          	ld	a5,756(a5) # 80008bf0 <uart_tx_w>
    80000904:	00008717          	auipc	a4,0x8
    80000908:	2e473703          	ld	a4,740(a4) # 80008be8 <uart_tx_r>
    8000090c:	02070713          	addi	a4,a4,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00010a17          	auipc	s4,0x10
    80000914:	518a0a13          	addi	s4,s4,1304 # 80010e28 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	2d048493          	addi	s1,s1,720 # 80008be8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	2d090913          	addi	s2,s2,720 # 80008bf0 <uart_tx_w>
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
    8000094a:	4e248493          	addi	s1,s1,1250 # 80010e28 <uart_tx_lock>
    8000094e:	01f7f713          	andi	a4,a5,31
    80000952:	9726                	add	a4,a4,s1
    80000954:	01370c23          	sb	s3,24(a4)
  uart_tx_w += 1;
    80000958:	0785                	addi	a5,a5,1
    8000095a:	00008717          	auipc	a4,0x8
    8000095e:	28f73b23          	sd	a5,662(a4) # 80008bf0 <uart_tx_w>
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
    800009d4:	45848493          	addi	s1,s1,1112 # 80010e28 <uart_tx_lock>
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
    80000a16:	8f678793          	addi	a5,a5,-1802 # 8002a308 <end>
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
    80000a36:	42e90913          	addi	s2,s2,1070 # 80010e60 <kmem>
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
    80000ad2:	39250513          	addi	a0,a0,914 # 80010e60 <kmem>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	084080e7          	jalr	132(ra) # 80000b5a <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ade:	45c5                	li	a1,17
    80000ae0:	05ee                	slli	a1,a1,0x1b
    80000ae2:	0002a517          	auipc	a0,0x2a
    80000ae6:	82650513          	addi	a0,a0,-2010 # 8002a308 <end>
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
    80000b08:	35c48493          	addi	s1,s1,860 # 80010e60 <kmem>
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
    80000b20:	34450513          	addi	a0,a0,836 # 80010e60 <kmem>
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
    80000b4c:	31850513          	addi	a0,a0,792 # 80010e60 <kmem>
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
    80000ea8:	d5470713          	addi	a4,a4,-684 # 80008bf8 <started>
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
    80000ede:	890080e7          	jalr	-1904(ra) # 8000276a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ee2:	00005097          	auipc	ra,0x5
    80000ee6:	fde080e7          	jalr	-34(ra) # 80005ec0 <plicinithart>
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
    80000f56:	7f0080e7          	jalr	2032(ra) # 80002742 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5a:	00002097          	auipc	ra,0x2
    80000f5e:	810080e7          	jalr	-2032(ra) # 8000276a <trapinithart>
    plicinit();      // set up interrupt controller
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	f48080e7          	jalr	-184(ra) # 80005eaa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6a:	00005097          	auipc	ra,0x5
    80000f6e:	f56080e7          	jalr	-170(ra) # 80005ec0 <plicinithart>
    binit();         // buffer cache
    80000f72:	00002097          	auipc	ra,0x2
    80000f76:	10a080e7          	jalr	266(ra) # 8000307c <binit>
    iinit();         // inode table
    80000f7a:	00002097          	auipc	ra,0x2
    80000f7e:	7ae080e7          	jalr	1966(ra) # 80003728 <iinit>
    fileinit();      // file table
    80000f82:	00003097          	auipc	ra,0x3
    80000f86:	74c080e7          	jalr	1868(ra) # 800046ce <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8a:	00005097          	auipc	ra,0x5
    80000f8e:	03e080e7          	jalr	62(ra) # 80005fc8 <virtio_disk_init>
    userinit();      // first user process
    80000f92:	00001097          	auipc	ra,0x1
    80000f96:	d0c080e7          	jalr	-756(ra) # 80001c9e <userinit>
    __sync_synchronize();
    80000f9a:	0ff0000f          	fence
    started = 1;
    80000f9e:	4785                	li	a5,1
    80000fa0:	00008717          	auipc	a4,0x8
    80000fa4:	c4f72c23          	sw	a5,-936(a4) # 80008bf8 <started>
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
    80000fb8:	c4c7b783          	ld	a5,-948(a5) # 80008c00 <kernel_pagetable>
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
    80001274:	98a7b823          	sd	a0,-1648(a5) # 80008c00 <kernel_pagetable>
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
    8000186a:	a5a48493          	addi	s1,s1,-1446 # 800112c0 <proc>
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
    80001884:	640a0a13          	addi	s4,s4,1600 # 80016ec0 <tickslock>
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
    80001906:	57e50513          	addi	a0,a0,1406 # 80010e80 <pid_lock>
    8000190a:	fffff097          	auipc	ra,0xfffff
    8000190e:	250080e7          	jalr	592(ra) # 80000b5a <initlock>
  initlock(&wait_lock, "wait_lock");
    80001912:	00007597          	auipc	a1,0x7
    80001916:	8d658593          	addi	a1,a1,-1834 # 800081e8 <digits+0x1a8>
    8000191a:	0000f517          	auipc	a0,0xf
    8000191e:	57e50513          	addi	a0,a0,1406 # 80010e98 <wait_lock>
    80001922:	fffff097          	auipc	ra,0xfffff
    80001926:	238080e7          	jalr	568(ra) # 80000b5a <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000192a:	00010497          	auipc	s1,0x10
    8000192e:	99648493          	addi	s1,s1,-1642 # 800112c0 <proc>
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
    80001950:	57498993          	addi	s3,s3,1396 # 80016ec0 <tickslock>
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
    800019ba:	4fa50513          	addi	a0,a0,1274 # 80010eb0 <cpus>
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
    800019e2:	4a270713          	addi	a4,a4,1186 # 80010e80 <pid_lock>
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
    80001a1a:	08a7a783          	lw	a5,138(a5) # 80008aa0 <first.1740>
    80001a1e:	eb89                	bnez	a5,80001a30 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a20:	00001097          	auipc	ra,0x1
    80001a24:	d62080e7          	jalr	-670(ra) # 80002782 <usertrapret>
}
    80001a28:	60a2                	ld	ra,8(sp)
    80001a2a:	6402                	ld	s0,0(sp)
    80001a2c:	0141                	addi	sp,sp,16
    80001a2e:	8082                	ret
    first = 0;
    80001a30:	00007797          	auipc	a5,0x7
    80001a34:	0607a823          	sw	zero,112(a5) # 80008aa0 <first.1740>
    fsinit(ROOTDEV);
    80001a38:	4505                	li	a0,1
    80001a3a:	00002097          	auipc	ra,0x2
    80001a3e:	c6e080e7          	jalr	-914(ra) # 800036a8 <fsinit>
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
    80001a54:	43090913          	addi	s2,s2,1072 # 80010e80 <pid_lock>
    80001a58:	854a                	mv	a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	190080e7          	jalr	400(ra) # 80000bea <acquire>
  pid = nextpid;
    80001a62:	00007797          	auipc	a5,0x7
    80001a66:	04278793          	addi	a5,a5,66 # 80008aa4 <nextpid>
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
    80001be0:	6e448493          	addi	s1,s1,1764 # 800112c0 <proc>
    80001be4:	00015917          	auipc	s2,0x15
    80001be8:	2dc90913          	addi	s2,s2,732 # 80016ec0 <tickslock>
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
    80001cb6:	f4a7bb23          	sd	a0,-170(a5) # 80008c08 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cba:	03400613          	li	a2,52
    80001cbe:	00007597          	auipc	a1,0x7
    80001cc2:	df258593          	addi	a1,a1,-526 # 80008ab0 <initcode>
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
    80001d00:	3ce080e7          	jalr	974(ra) # 800040ca <namei>
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
    80001e1e:	946080e7          	jalr	-1722(ra) # 80004760 <filedup>
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
    80001e40:	aaa080e7          	jalr	-1366(ra) # 800038e6 <idup>
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
    80001e6c:	03048493          	addi	s1,s1,48 # 80010e98 <wait_lock>
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
    80001f62:	f2270713          	addi	a4,a4,-222 # 80010e80 <pid_lock>
    80001f66:	975a                	add	a4,a4,s6
    80001f68:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f6c:	0000f717          	auipc	a4,0xf
    80001f70:	f4c70713          	addi	a4,a4,-180 # 80010eb8 <cpus+0x8>
    80001f74:	9b3a                	add	s6,s6,a4
        p->state = RUNNING;
    80001f76:	4b91                	li	s7,4
        c->proc = p;
    80001f78:	079e                	slli	a5,a5,0x7
    80001f7a:	0000fa97          	auipc	s5,0xf
    80001f7e:	f06a8a93          	addi	s5,s5,-250 # 80010e80 <pid_lock>
    80001f82:	9abe                	add	s5,s5,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f84:	00015a17          	auipc	s4,0x15
    80001f88:	f3ca0a13          	addi	s4,s4,-196 # 80016ec0 <tickslock>
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
    80001fa2:	73a080e7          	jalr	1850(ra) # 800026d8 <swtch>
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
    80001fea:	2da48493          	addi	s1,s1,730 # 800112c0 <proc>
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
    80002024:	e6070713          	addi	a4,a4,-416 # 80010e80 <pid_lock>
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
    8000204a:	e3a90913          	addi	s2,s2,-454 # 80010e80 <pid_lock>
    8000204e:	2781                	sext.w	a5,a5
    80002050:	079e                	slli	a5,a5,0x7
    80002052:	97ca                	add	a5,a5,s2
    80002054:	0ac7a983          	lw	s3,172(a5)
    80002058:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000205a:	2781                	sext.w	a5,a5
    8000205c:	079e                	slli	a5,a5,0x7
    8000205e:	0000f597          	auipc	a1,0xf
    80002062:	e5a58593          	addi	a1,a1,-422 # 80010eb8 <cpus+0x8>
    80002066:	95be                	add	a1,a1,a5
    80002068:	06048513          	addi	a0,s1,96
    8000206c:	00000097          	auipc	ra,0x0
    80002070:	66c080e7          	jalr	1644(ra) # 800026d8 <swtch>
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
    80002186:	13e48493          	addi	s1,s1,318 # 800112c0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000218a:	4989                	li	s3,2
        p->state = RUNNABLE;
    8000218c:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000218e:	00015917          	auipc	s2,0x15
    80002192:	d3290913          	addi	s2,s2,-718 # 80016ec0 <tickslock>
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
    800021fa:	0ca48493          	addi	s1,s1,202 # 800112c0 <proc>
      pp->parent = initproc;
    800021fe:	00007a17          	auipc	s4,0x7
    80002202:	a0aa0a13          	addi	s4,s4,-1526 # 80008c08 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002206:	00015997          	auipc	s3,0x15
    8000220a:	cba98993          	addi	s3,s3,-838 # 80016ec0 <tickslock>
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
    8000225e:	9ae7b783          	ld	a5,-1618(a5) # 80008c08 <initproc>
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
    80002282:	534080e7          	jalr	1332(ra) # 800047b2 <fileclose>
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
    8000229a:	050080e7          	jalr	80(ra) # 800042e6 <begin_op>
  iput(p->cwd);
    8000229e:	1509b503          	ld	a0,336(s3)
    800022a2:	00002097          	auipc	ra,0x2
    800022a6:	83c080e7          	jalr	-1988(ra) # 80003ade <iput>
  end_op();
    800022aa:	00002097          	auipc	ra,0x2
    800022ae:	0bc080e7          	jalr	188(ra) # 80004366 <end_op>
  p->cwd = 0;
    800022b2:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800022b6:	0000f497          	auipc	s1,0xf
    800022ba:	be248493          	addi	s1,s1,-1054 # 80010e98 <wait_lock>
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
    80002328:	f9c48493          	addi	s1,s1,-100 # 800112c0 <proc>
    8000232c:	00015997          	auipc	s3,0x15
    80002330:	b9498993          	addi	s3,s3,-1132 # 80016ec0 <tickslock>
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
    8000240c:	a9050513          	addi	a0,a0,-1392 # 80010e98 <wait_lock>
    80002410:	ffffe097          	auipc	ra,0xffffe
    80002414:	7da080e7          	jalr	2010(ra) # 80000bea <acquire>
    havekids = 0;
    80002418:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    8000241a:	4a15                	li	s4,5
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000241c:	00015997          	auipc	s3,0x15
    80002420:	aa498993          	addi	s3,s3,-1372 # 80016ec0 <tickslock>
        havekids = 1;
    80002424:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002426:	0000fc17          	auipc	s8,0xf
    8000242a:	a72c0c13          	addi	s8,s8,-1422 # 80010e98 <wait_lock>
    havekids = 0;
    8000242e:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002430:	0000f497          	auipc	s1,0xf
    80002434:	e9048493          	addi	s1,s1,-368 # 800112c0 <proc>
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
    80002472:	a2a50513          	addi	a0,a0,-1494 # 80010e98 <wait_lock>
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
    8000248e:	a0e50513          	addi	a0,a0,-1522 # 80010e98 <wait_lock>
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
    800024dc:	9c050513          	addi	a0,a0,-1600 # 80010e98 <wait_lock>
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
    800025e8:	e3448493          	addi	s1,s1,-460 # 80011418 <proc+0x158>
    800025ec:	00015917          	auipc	s2,0x15
    800025f0:	a2c90913          	addi	s2,s2,-1492 # 80017018 <bruh+0xd8>
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
    80002612:	d82b8b93          	addi	s7,s7,-638 # 80008390 <states.1784>
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
    800026a6:	086080e7          	jalr	134(ra) # 80006728 <write_to_logs>
    return (uint64)1;
}
    800026aa:	4505                	li	a0,1
    800026ac:	60a6                	ld	ra,72(sp)
    800026ae:	6406                	ld	s0,64(sp)
    800026b0:	6161                	addi	sp,sp,80
    800026b2:	8082                	ret

00000000800026b4 <try2>:

uint64 try2(void *arg)
{
    800026b4:	1141                	addi	sp,sp,-16
    800026b6:	e406                	sd	ra,8(sp)
    800026b8:	e022                	sd	s0,0(sp)
    800026ba:	0800                	addi	s0,sp,16
    800026bc:	85aa                	mv	a1,a0

printf("In try two sys call with arg %p\n", arg);
    800026be:	00006517          	auipc	a0,0x6
    800026c2:	c7a50513          	addi	a0,a0,-902 # 80008338 <digits+0x2f8>
    800026c6:	ffffe097          	auipc	ra,0xffffe
    800026ca:	ec8080e7          	jalr	-312(ra) # 8000058e <printf>
return 0;
}
    800026ce:	4501                	li	a0,0
    800026d0:	60a2                	ld	ra,8(sp)
    800026d2:	6402                	ld	s0,0(sp)
    800026d4:	0141                	addi	sp,sp,16
    800026d6:	8082                	ret

00000000800026d8 <swtch>:
    800026d8:	00153023          	sd	ra,0(a0)
    800026dc:	00253423          	sd	sp,8(a0)
    800026e0:	e900                	sd	s0,16(a0)
    800026e2:	ed04                	sd	s1,24(a0)
    800026e4:	03253023          	sd	s2,32(a0)
    800026e8:	03353423          	sd	s3,40(a0)
    800026ec:	03453823          	sd	s4,48(a0)
    800026f0:	03553c23          	sd	s5,56(a0)
    800026f4:	05653023          	sd	s6,64(a0)
    800026f8:	05753423          	sd	s7,72(a0)
    800026fc:	05853823          	sd	s8,80(a0)
    80002700:	05953c23          	sd	s9,88(a0)
    80002704:	07a53023          	sd	s10,96(a0)
    80002708:	07b53423          	sd	s11,104(a0)
    8000270c:	0005b083          	ld	ra,0(a1)
    80002710:	0085b103          	ld	sp,8(a1)
    80002714:	6980                	ld	s0,16(a1)
    80002716:	6d84                	ld	s1,24(a1)
    80002718:	0205b903          	ld	s2,32(a1)
    8000271c:	0285b983          	ld	s3,40(a1)
    80002720:	0305ba03          	ld	s4,48(a1)
    80002724:	0385ba83          	ld	s5,56(a1)
    80002728:	0405bb03          	ld	s6,64(a1)
    8000272c:	0485bb83          	ld	s7,72(a1)
    80002730:	0505bc03          	ld	s8,80(a1)
    80002734:	0585bc83          	ld	s9,88(a1)
    80002738:	0605bd03          	ld	s10,96(a1)
    8000273c:	0685bd83          	ld	s11,104(a1)
    80002740:	8082                	ret

0000000080002742 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002742:	1141                	addi	sp,sp,-16
    80002744:	e406                	sd	ra,8(sp)
    80002746:	e022                	sd	s0,0(sp)
    80002748:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000274a:	00006597          	auipc	a1,0x6
    8000274e:	c7658593          	addi	a1,a1,-906 # 800083c0 <states.1784+0x30>
    80002752:	00014517          	auipc	a0,0x14
    80002756:	76e50513          	addi	a0,a0,1902 # 80016ec0 <tickslock>
    8000275a:	ffffe097          	auipc	ra,0xffffe
    8000275e:	400080e7          	jalr	1024(ra) # 80000b5a <initlock>
}
    80002762:	60a2                	ld	ra,8(sp)
    80002764:	6402                	ld	s0,0(sp)
    80002766:	0141                	addi	sp,sp,16
    80002768:	8082                	ret

000000008000276a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000276a:	1141                	addi	sp,sp,-16
    8000276c:	e422                	sd	s0,8(sp)
    8000276e:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002770:	00003797          	auipc	a5,0x3
    80002774:	68078793          	addi	a5,a5,1664 # 80005df0 <kernelvec>
    80002778:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000277c:	6422                	ld	s0,8(sp)
    8000277e:	0141                	addi	sp,sp,16
    80002780:	8082                	ret

0000000080002782 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002782:	1141                	addi	sp,sp,-16
    80002784:	e406                	sd	ra,8(sp)
    80002786:	e022                	sd	s0,0(sp)
    80002788:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000278a:	fffff097          	auipc	ra,0xfffff
    8000278e:	23c080e7          	jalr	572(ra) # 800019c6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002792:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002796:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002798:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    8000279c:	00005617          	auipc	a2,0x5
    800027a0:	86460613          	addi	a2,a2,-1948 # 80007000 <_trampoline>
    800027a4:	00005697          	auipc	a3,0x5
    800027a8:	85c68693          	addi	a3,a3,-1956 # 80007000 <_trampoline>
    800027ac:	8e91                	sub	a3,a3,a2
    800027ae:	040007b7          	lui	a5,0x4000
    800027b2:	17fd                	addi	a5,a5,-1
    800027b4:	07b2                	slli	a5,a5,0xc
    800027b6:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027b8:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800027bc:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800027be:	180026f3          	csrr	a3,satp
    800027c2:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800027c4:	6d38                	ld	a4,88(a0)
    800027c6:	6134                	ld	a3,64(a0)
    800027c8:	6585                	lui	a1,0x1
    800027ca:	96ae                	add	a3,a3,a1
    800027cc:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800027ce:	6d38                	ld	a4,88(a0)
    800027d0:	00000697          	auipc	a3,0x0
    800027d4:	13068693          	addi	a3,a3,304 # 80002900 <usertrap>
    800027d8:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800027da:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800027dc:	8692                	mv	a3,tp
    800027de:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027e0:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800027e4:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800027e8:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027ec:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800027f0:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800027f2:	6f18                	ld	a4,24(a4)
    800027f4:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800027f8:	6928                	ld	a0,80(a0)
    800027fa:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800027fc:	00005717          	auipc	a4,0x5
    80002800:	8a070713          	addi	a4,a4,-1888 # 8000709c <userret>
    80002804:	8f11                	sub	a4,a4,a2
    80002806:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002808:	577d                	li	a4,-1
    8000280a:	177e                	slli	a4,a4,0x3f
    8000280c:	8d59                	or	a0,a0,a4
    8000280e:	9782                	jalr	a5
}
    80002810:	60a2                	ld	ra,8(sp)
    80002812:	6402                	ld	s0,0(sp)
    80002814:	0141                	addi	sp,sp,16
    80002816:	8082                	ret

0000000080002818 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002818:	1101                	addi	sp,sp,-32
    8000281a:	ec06                	sd	ra,24(sp)
    8000281c:	e822                	sd	s0,16(sp)
    8000281e:	e426                	sd	s1,8(sp)
    80002820:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002822:	00014497          	auipc	s1,0x14
    80002826:	69e48493          	addi	s1,s1,1694 # 80016ec0 <tickslock>
    8000282a:	8526                	mv	a0,s1
    8000282c:	ffffe097          	auipc	ra,0xffffe
    80002830:	3be080e7          	jalr	958(ra) # 80000bea <acquire>
  ticks++;
    80002834:	00006517          	auipc	a0,0x6
    80002838:	3dc50513          	addi	a0,a0,988 # 80008c10 <ticks>
    8000283c:	411c                	lw	a5,0(a0)
    8000283e:	2785                	addiw	a5,a5,1
    80002840:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002842:	00000097          	auipc	ra,0x0
    80002846:	92c080e7          	jalr	-1748(ra) # 8000216e <wakeup>
  release(&tickslock);
    8000284a:	8526                	mv	a0,s1
    8000284c:	ffffe097          	auipc	ra,0xffffe
    80002850:	452080e7          	jalr	1106(ra) # 80000c9e <release>
}
    80002854:	60e2                	ld	ra,24(sp)
    80002856:	6442                	ld	s0,16(sp)
    80002858:	64a2                	ld	s1,8(sp)
    8000285a:	6105                	addi	sp,sp,32
    8000285c:	8082                	ret

000000008000285e <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000285e:	1101                	addi	sp,sp,-32
    80002860:	ec06                	sd	ra,24(sp)
    80002862:	e822                	sd	s0,16(sp)
    80002864:	e426                	sd	s1,8(sp)
    80002866:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002868:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000286c:	00074d63          	bltz	a4,80002886 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002870:	57fd                	li	a5,-1
    80002872:	17fe                	slli	a5,a5,0x3f
    80002874:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002876:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002878:	06f70363          	beq	a4,a5,800028de <devintr+0x80>
  }
}
    8000287c:	60e2                	ld	ra,24(sp)
    8000287e:	6442                	ld	s0,16(sp)
    80002880:	64a2                	ld	s1,8(sp)
    80002882:	6105                	addi	sp,sp,32
    80002884:	8082                	ret
     (scause & 0xff) == 9){
    80002886:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000288a:	46a5                	li	a3,9
    8000288c:	fed792e3          	bne	a5,a3,80002870 <devintr+0x12>
    int irq = plic_claim();
    80002890:	00003097          	auipc	ra,0x3
    80002894:	668080e7          	jalr	1640(ra) # 80005ef8 <plic_claim>
    80002898:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000289a:	47a9                	li	a5,10
    8000289c:	02f50763          	beq	a0,a5,800028ca <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800028a0:	4785                	li	a5,1
    800028a2:	02f50963          	beq	a0,a5,800028d4 <devintr+0x76>
    return 1;
    800028a6:	4505                	li	a0,1
    } else if(irq){
    800028a8:	d8f1                	beqz	s1,8000287c <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800028aa:	85a6                	mv	a1,s1
    800028ac:	00006517          	auipc	a0,0x6
    800028b0:	b1c50513          	addi	a0,a0,-1252 # 800083c8 <states.1784+0x38>
    800028b4:	ffffe097          	auipc	ra,0xffffe
    800028b8:	cda080e7          	jalr	-806(ra) # 8000058e <printf>
      plic_complete(irq);
    800028bc:	8526                	mv	a0,s1
    800028be:	00003097          	auipc	ra,0x3
    800028c2:	65e080e7          	jalr	1630(ra) # 80005f1c <plic_complete>
    return 1;
    800028c6:	4505                	li	a0,1
    800028c8:	bf55                	j	8000287c <devintr+0x1e>
      uartintr();
    800028ca:	ffffe097          	auipc	ra,0xffffe
    800028ce:	0e4080e7          	jalr	228(ra) # 800009ae <uartintr>
    800028d2:	b7ed                	j	800028bc <devintr+0x5e>
      virtio_disk_intr();
    800028d4:	00004097          	auipc	ra,0x4
    800028d8:	b72080e7          	jalr	-1166(ra) # 80006446 <virtio_disk_intr>
    800028dc:	b7c5                	j	800028bc <devintr+0x5e>
    if(cpuid() == 0){
    800028de:	fffff097          	auipc	ra,0xfffff
    800028e2:	0bc080e7          	jalr	188(ra) # 8000199a <cpuid>
    800028e6:	c901                	beqz	a0,800028f6 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800028e8:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800028ec:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800028ee:	14479073          	csrw	sip,a5
    return 2;
    800028f2:	4509                	li	a0,2
    800028f4:	b761                	j	8000287c <devintr+0x1e>
      clockintr();
    800028f6:	00000097          	auipc	ra,0x0
    800028fa:	f22080e7          	jalr	-222(ra) # 80002818 <clockintr>
    800028fe:	b7ed                	j	800028e8 <devintr+0x8a>

0000000080002900 <usertrap>:
{
    80002900:	1101                	addi	sp,sp,-32
    80002902:	ec06                	sd	ra,24(sp)
    80002904:	e822                	sd	s0,16(sp)
    80002906:	e426                	sd	s1,8(sp)
    80002908:	e04a                	sd	s2,0(sp)
    8000290a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000290c:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002910:	1007f793          	andi	a5,a5,256
    80002914:	e3b1                	bnez	a5,80002958 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002916:	00003797          	auipc	a5,0x3
    8000291a:	4da78793          	addi	a5,a5,1242 # 80005df0 <kernelvec>
    8000291e:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002922:	fffff097          	auipc	ra,0xfffff
    80002926:	0a4080e7          	jalr	164(ra) # 800019c6 <myproc>
    8000292a:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000292c:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000292e:	14102773          	csrr	a4,sepc
    80002932:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002934:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002938:	47a1                	li	a5,8
    8000293a:	02f70763          	beq	a4,a5,80002968 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    8000293e:	00000097          	auipc	ra,0x0
    80002942:	f20080e7          	jalr	-224(ra) # 8000285e <devintr>
    80002946:	892a                	mv	s2,a0
    80002948:	c151                	beqz	a0,800029cc <usertrap+0xcc>
  if(killed(p))
    8000294a:	8526                	mv	a0,s1
    8000294c:	00000097          	auipc	ra,0x0
    80002950:	a66080e7          	jalr	-1434(ra) # 800023b2 <killed>
    80002954:	c929                	beqz	a0,800029a6 <usertrap+0xa6>
    80002956:	a099                	j	8000299c <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002958:	00006517          	auipc	a0,0x6
    8000295c:	a9050513          	addi	a0,a0,-1392 # 800083e8 <states.1784+0x58>
    80002960:	ffffe097          	auipc	ra,0xffffe
    80002964:	be4080e7          	jalr	-1052(ra) # 80000544 <panic>
    if(killed(p))
    80002968:	00000097          	auipc	ra,0x0
    8000296c:	a4a080e7          	jalr	-1462(ra) # 800023b2 <killed>
    80002970:	e921                	bnez	a0,800029c0 <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002972:	6cb8                	ld	a4,88(s1)
    80002974:	6f1c                	ld	a5,24(a4)
    80002976:	0791                	addi	a5,a5,4
    80002978:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000297a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000297e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002982:	10079073          	csrw	sstatus,a5
    syscall();
    80002986:	00000097          	auipc	ra,0x0
    8000298a:	2d4080e7          	jalr	724(ra) # 80002c5a <syscall>
  if(killed(p))
    8000298e:	8526                	mv	a0,s1
    80002990:	00000097          	auipc	ra,0x0
    80002994:	a22080e7          	jalr	-1502(ra) # 800023b2 <killed>
    80002998:	c911                	beqz	a0,800029ac <usertrap+0xac>
    8000299a:	4901                	li	s2,0
    exit(-1);
    8000299c:	557d                	li	a0,-1
    8000299e:	00000097          	auipc	ra,0x0
    800029a2:	8a0080e7          	jalr	-1888(ra) # 8000223e <exit>
  if(which_dev == 2)
    800029a6:	4789                	li	a5,2
    800029a8:	04f90f63          	beq	s2,a5,80002a06 <usertrap+0x106>
  usertrapret();
    800029ac:	00000097          	auipc	ra,0x0
    800029b0:	dd6080e7          	jalr	-554(ra) # 80002782 <usertrapret>
}
    800029b4:	60e2                	ld	ra,24(sp)
    800029b6:	6442                	ld	s0,16(sp)
    800029b8:	64a2                	ld	s1,8(sp)
    800029ba:	6902                	ld	s2,0(sp)
    800029bc:	6105                	addi	sp,sp,32
    800029be:	8082                	ret
      exit(-1);
    800029c0:	557d                	li	a0,-1
    800029c2:	00000097          	auipc	ra,0x0
    800029c6:	87c080e7          	jalr	-1924(ra) # 8000223e <exit>
    800029ca:	b765                	j	80002972 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029cc:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800029d0:	5890                	lw	a2,48(s1)
    800029d2:	00006517          	auipc	a0,0x6
    800029d6:	a3650513          	addi	a0,a0,-1482 # 80008408 <states.1784+0x78>
    800029da:	ffffe097          	auipc	ra,0xffffe
    800029de:	bb4080e7          	jalr	-1100(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029e2:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029e6:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029ea:	00006517          	auipc	a0,0x6
    800029ee:	a4e50513          	addi	a0,a0,-1458 # 80008438 <states.1784+0xa8>
    800029f2:	ffffe097          	auipc	ra,0xffffe
    800029f6:	b9c080e7          	jalr	-1124(ra) # 8000058e <printf>
    setkilled(p);
    800029fa:	8526                	mv	a0,s1
    800029fc:	00000097          	auipc	ra,0x0
    80002a00:	98a080e7          	jalr	-1654(ra) # 80002386 <setkilled>
    80002a04:	b769                	j	8000298e <usertrap+0x8e>
    yield();
    80002a06:	fffff097          	auipc	ra,0xfffff
    80002a0a:	6c8080e7          	jalr	1736(ra) # 800020ce <yield>
    80002a0e:	bf79                	j	800029ac <usertrap+0xac>

0000000080002a10 <kerneltrap>:
{
    80002a10:	7179                	addi	sp,sp,-48
    80002a12:	f406                	sd	ra,40(sp)
    80002a14:	f022                	sd	s0,32(sp)
    80002a16:	ec26                	sd	s1,24(sp)
    80002a18:	e84a                	sd	s2,16(sp)
    80002a1a:	e44e                	sd	s3,8(sp)
    80002a1c:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a1e:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a22:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a26:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002a2a:	1004f793          	andi	a5,s1,256
    80002a2e:	cb85                	beqz	a5,80002a5e <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a30:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002a34:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002a36:	ef85                	bnez	a5,80002a6e <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002a38:	00000097          	auipc	ra,0x0
    80002a3c:	e26080e7          	jalr	-474(ra) # 8000285e <devintr>
    80002a40:	cd1d                	beqz	a0,80002a7e <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a42:	4789                	li	a5,2
    80002a44:	06f50a63          	beq	a0,a5,80002ab8 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a48:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a4c:	10049073          	csrw	sstatus,s1
}
    80002a50:	70a2                	ld	ra,40(sp)
    80002a52:	7402                	ld	s0,32(sp)
    80002a54:	64e2                	ld	s1,24(sp)
    80002a56:	6942                	ld	s2,16(sp)
    80002a58:	69a2                	ld	s3,8(sp)
    80002a5a:	6145                	addi	sp,sp,48
    80002a5c:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002a5e:	00006517          	auipc	a0,0x6
    80002a62:	9fa50513          	addi	a0,a0,-1542 # 80008458 <states.1784+0xc8>
    80002a66:	ffffe097          	auipc	ra,0xffffe
    80002a6a:	ade080e7          	jalr	-1314(ra) # 80000544 <panic>
    panic("kerneltrap: interrupts enabled");
    80002a6e:	00006517          	auipc	a0,0x6
    80002a72:	a1250513          	addi	a0,a0,-1518 # 80008480 <states.1784+0xf0>
    80002a76:	ffffe097          	auipc	ra,0xffffe
    80002a7a:	ace080e7          	jalr	-1330(ra) # 80000544 <panic>
    printf("scause %p\n", scause);
    80002a7e:	85ce                	mv	a1,s3
    80002a80:	00006517          	auipc	a0,0x6
    80002a84:	a2050513          	addi	a0,a0,-1504 # 800084a0 <states.1784+0x110>
    80002a88:	ffffe097          	auipc	ra,0xffffe
    80002a8c:	b06080e7          	jalr	-1274(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a90:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a94:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a98:	00006517          	auipc	a0,0x6
    80002a9c:	a1850513          	addi	a0,a0,-1512 # 800084b0 <states.1784+0x120>
    80002aa0:	ffffe097          	auipc	ra,0xffffe
    80002aa4:	aee080e7          	jalr	-1298(ra) # 8000058e <printf>
    panic("kerneltrap");
    80002aa8:	00006517          	auipc	a0,0x6
    80002aac:	a2050513          	addi	a0,a0,-1504 # 800084c8 <states.1784+0x138>
    80002ab0:	ffffe097          	auipc	ra,0xffffe
    80002ab4:	a94080e7          	jalr	-1388(ra) # 80000544 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ab8:	fffff097          	auipc	ra,0xfffff
    80002abc:	f0e080e7          	jalr	-242(ra) # 800019c6 <myproc>
    80002ac0:	d541                	beqz	a0,80002a48 <kerneltrap+0x38>
    80002ac2:	fffff097          	auipc	ra,0xfffff
    80002ac6:	f04080e7          	jalr	-252(ra) # 800019c6 <myproc>
    80002aca:	4d18                	lw	a4,24(a0)
    80002acc:	4791                	li	a5,4
    80002ace:	f6f71de3          	bne	a4,a5,80002a48 <kerneltrap+0x38>
    yield();
    80002ad2:	fffff097          	auipc	ra,0xfffff
    80002ad6:	5fc080e7          	jalr	1532(ra) # 800020ce <yield>
    80002ada:	b7bd                	j	80002a48 <kerneltrap+0x38>

0000000080002adc <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002adc:	1101                	addi	sp,sp,-32
    80002ade:	ec06                	sd	ra,24(sp)
    80002ae0:	e822                	sd	s0,16(sp)
    80002ae2:	e426                	sd	s1,8(sp)
    80002ae4:	1000                	addi	s0,sp,32
    80002ae6:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002ae8:	fffff097          	auipc	ra,0xfffff
    80002aec:	ede080e7          	jalr	-290(ra) # 800019c6 <myproc>
  switch (n) {
    80002af0:	4795                	li	a5,5
    80002af2:	0497e163          	bltu	a5,s1,80002b34 <argraw+0x58>
    80002af6:	048a                	slli	s1,s1,0x2
    80002af8:	00006717          	auipc	a4,0x6
    80002afc:	b1070713          	addi	a4,a4,-1264 # 80008608 <states.1784+0x278>
    80002b00:	94ba                	add	s1,s1,a4
    80002b02:	409c                	lw	a5,0(s1)
    80002b04:	97ba                	add	a5,a5,a4
    80002b06:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002b08:	6d3c                	ld	a5,88(a0)
    80002b0a:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002b0c:	60e2                	ld	ra,24(sp)
    80002b0e:	6442                	ld	s0,16(sp)
    80002b10:	64a2                	ld	s1,8(sp)
    80002b12:	6105                	addi	sp,sp,32
    80002b14:	8082                	ret
    return p->trapframe->a1;
    80002b16:	6d3c                	ld	a5,88(a0)
    80002b18:	7fa8                	ld	a0,120(a5)
    80002b1a:	bfcd                	j	80002b0c <argraw+0x30>
    return p->trapframe->a2;
    80002b1c:	6d3c                	ld	a5,88(a0)
    80002b1e:	63c8                	ld	a0,128(a5)
    80002b20:	b7f5                	j	80002b0c <argraw+0x30>
    return p->trapframe->a3;
    80002b22:	6d3c                	ld	a5,88(a0)
    80002b24:	67c8                	ld	a0,136(a5)
    80002b26:	b7dd                	j	80002b0c <argraw+0x30>
    return p->trapframe->a4;
    80002b28:	6d3c                	ld	a5,88(a0)
    80002b2a:	6bc8                	ld	a0,144(a5)
    80002b2c:	b7c5                	j	80002b0c <argraw+0x30>
    return p->trapframe->a5;
    80002b2e:	6d3c                	ld	a5,88(a0)
    80002b30:	6fc8                	ld	a0,152(a5)
    80002b32:	bfe9                	j	80002b0c <argraw+0x30>
  panic("argraw");
    80002b34:	00006517          	auipc	a0,0x6
    80002b38:	9a450513          	addi	a0,a0,-1628 # 800084d8 <states.1784+0x148>
    80002b3c:	ffffe097          	auipc	ra,0xffffe
    80002b40:	a08080e7          	jalr	-1528(ra) # 80000544 <panic>

0000000080002b44 <fetchaddr>:
{
    80002b44:	1101                	addi	sp,sp,-32
    80002b46:	ec06                	sd	ra,24(sp)
    80002b48:	e822                	sd	s0,16(sp)
    80002b4a:	e426                	sd	s1,8(sp)
    80002b4c:	e04a                	sd	s2,0(sp)
    80002b4e:	1000                	addi	s0,sp,32
    80002b50:	84aa                	mv	s1,a0
    80002b52:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b54:	fffff097          	auipc	ra,0xfffff
    80002b58:	e72080e7          	jalr	-398(ra) # 800019c6 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002b5c:	653c                	ld	a5,72(a0)
    80002b5e:	02f4f863          	bgeu	s1,a5,80002b8e <fetchaddr+0x4a>
    80002b62:	00848713          	addi	a4,s1,8
    80002b66:	02e7e663          	bltu	a5,a4,80002b92 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002b6a:	46a1                	li	a3,8
    80002b6c:	8626                	mv	a2,s1
    80002b6e:	85ca                	mv	a1,s2
    80002b70:	6928                	ld	a0,80(a0)
    80002b72:	fffff097          	auipc	ra,0xfffff
    80002b76:	b9e080e7          	jalr	-1122(ra) # 80001710 <copyin>
    80002b7a:	00a03533          	snez	a0,a0
    80002b7e:	40a00533          	neg	a0,a0
}
    80002b82:	60e2                	ld	ra,24(sp)
    80002b84:	6442                	ld	s0,16(sp)
    80002b86:	64a2                	ld	s1,8(sp)
    80002b88:	6902                	ld	s2,0(sp)
    80002b8a:	6105                	addi	sp,sp,32
    80002b8c:	8082                	ret
    return -1;
    80002b8e:	557d                	li	a0,-1
    80002b90:	bfcd                	j	80002b82 <fetchaddr+0x3e>
    80002b92:	557d                	li	a0,-1
    80002b94:	b7fd                	j	80002b82 <fetchaddr+0x3e>

0000000080002b96 <fetchstr>:
{
    80002b96:	7179                	addi	sp,sp,-48
    80002b98:	f406                	sd	ra,40(sp)
    80002b9a:	f022                	sd	s0,32(sp)
    80002b9c:	ec26                	sd	s1,24(sp)
    80002b9e:	e84a                	sd	s2,16(sp)
    80002ba0:	e44e                	sd	s3,8(sp)
    80002ba2:	1800                	addi	s0,sp,48
    80002ba4:	892a                	mv	s2,a0
    80002ba6:	84ae                	mv	s1,a1
    80002ba8:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002baa:	fffff097          	auipc	ra,0xfffff
    80002bae:	e1c080e7          	jalr	-484(ra) # 800019c6 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002bb2:	86ce                	mv	a3,s3
    80002bb4:	864a                	mv	a2,s2
    80002bb6:	85a6                	mv	a1,s1
    80002bb8:	6928                	ld	a0,80(a0)
    80002bba:	fffff097          	auipc	ra,0xfffff
    80002bbe:	be2080e7          	jalr	-1054(ra) # 8000179c <copyinstr>
    80002bc2:	00054e63          	bltz	a0,80002bde <fetchstr+0x48>
  return strlen(buf);
    80002bc6:	8526                	mv	a0,s1
    80002bc8:	ffffe097          	auipc	ra,0xffffe
    80002bcc:	2a2080e7          	jalr	674(ra) # 80000e6a <strlen>
}
    80002bd0:	70a2                	ld	ra,40(sp)
    80002bd2:	7402                	ld	s0,32(sp)
    80002bd4:	64e2                	ld	s1,24(sp)
    80002bd6:	6942                	ld	s2,16(sp)
    80002bd8:	69a2                	ld	s3,8(sp)
    80002bda:	6145                	addi	sp,sp,48
    80002bdc:	8082                	ret
    return -1;
    80002bde:	557d                	li	a0,-1
    80002be0:	bfc5                	j	80002bd0 <fetchstr+0x3a>

0000000080002be2 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002be2:	1101                	addi	sp,sp,-32
    80002be4:	ec06                	sd	ra,24(sp)
    80002be6:	e822                	sd	s0,16(sp)
    80002be8:	e426                	sd	s1,8(sp)
    80002bea:	1000                	addi	s0,sp,32
    80002bec:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002bee:	00000097          	auipc	ra,0x0
    80002bf2:	eee080e7          	jalr	-274(ra) # 80002adc <argraw>
    80002bf6:	c088                	sw	a0,0(s1)
}
    80002bf8:	60e2                	ld	ra,24(sp)
    80002bfa:	6442                	ld	s0,16(sp)
    80002bfc:	64a2                	ld	s1,8(sp)
    80002bfe:	6105                	addi	sp,sp,32
    80002c00:	8082                	ret

0000000080002c02 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002c02:	1101                	addi	sp,sp,-32
    80002c04:	ec06                	sd	ra,24(sp)
    80002c06:	e822                	sd	s0,16(sp)
    80002c08:	e426                	sd	s1,8(sp)
    80002c0a:	1000                	addi	s0,sp,32
    80002c0c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c0e:	00000097          	auipc	ra,0x0
    80002c12:	ece080e7          	jalr	-306(ra) # 80002adc <argraw>
    80002c16:	e088                	sd	a0,0(s1)
}
    80002c18:	60e2                	ld	ra,24(sp)
    80002c1a:	6442                	ld	s0,16(sp)
    80002c1c:	64a2                	ld	s1,8(sp)
    80002c1e:	6105                	addi	sp,sp,32
    80002c20:	8082                	ret

0000000080002c22 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002c22:	7179                	addi	sp,sp,-48
    80002c24:	f406                	sd	ra,40(sp)
    80002c26:	f022                	sd	s0,32(sp)
    80002c28:	ec26                	sd	s1,24(sp)
    80002c2a:	e84a                	sd	s2,16(sp)
    80002c2c:	1800                	addi	s0,sp,48
    80002c2e:	84ae                	mv	s1,a1
    80002c30:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002c32:	fd840593          	addi	a1,s0,-40
    80002c36:	00000097          	auipc	ra,0x0
    80002c3a:	fcc080e7          	jalr	-52(ra) # 80002c02 <argaddr>
  return fetchstr(addr, buf, max);
    80002c3e:	864a                	mv	a2,s2
    80002c40:	85a6                	mv	a1,s1
    80002c42:	fd843503          	ld	a0,-40(s0)
    80002c46:	00000097          	auipc	ra,0x0
    80002c4a:	f50080e7          	jalr	-176(ra) # 80002b96 <fetchstr>
}
    80002c4e:	70a2                	ld	ra,40(sp)
    80002c50:	7402                	ld	s0,32(sp)
    80002c52:	64e2                	ld	s1,24(sp)
    80002c54:	6942                	ld	s2,16(sp)
    80002c56:	6145                	addi	sp,sp,48
    80002c58:	8082                	ret

0000000080002c5a <syscall>:
};


void
syscall(void)
{
    80002c5a:	711d                	addi	sp,sp,-96
    80002c5c:	ec86                	sd	ra,88(sp)
    80002c5e:	e8a2                	sd	s0,80(sp)
    80002c60:	e4a6                	sd	s1,72(sp)
    80002c62:	e0ca                	sd	s2,64(sp)
    80002c64:	fc4e                	sd	s3,56(sp)
    80002c66:	f852                	sd	s4,48(sp)
    80002c68:	f456                	sd	s5,40(sp)
    80002c6a:	f05a                	sd	s6,32(sp)
    80002c6c:	ec5e                	sd	s7,24(sp)
    80002c6e:	e862                	sd	s8,16(sp)
    80002c70:	e466                	sd	s9,8(sp)
    80002c72:	1080                	addi	s0,sp,96
  int num;
  struct proc *p = myproc();
    80002c74:	fffff097          	auipc	ra,0xfffff
    80002c78:	d52080e7          	jalr	-686(ra) # 800019c6 <myproc>
    80002c7c:	89aa                	mv	s3,a0

  num = p->trapframe->a7;
    80002c7e:	6d24                	ld	s1,88(a0)
    80002c80:	74dc                	ld	a5,168(s1)
    80002c82:	00078a1b          	sext.w	s4,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c86:	37fd                	addiw	a5,a5,-1
    80002c88:	475d                	li	a4,23
    80002c8a:	12f76163          	bltu	a4,a5,80002dac <syscall+0x152>
    80002c8e:	003a1713          	slli	a4,s4,0x3
    80002c92:	00006797          	auipc	a5,0x6
    80002c96:	98e78793          	addi	a5,a5,-1650 # 80008620 <syscalls>
    80002c9a:	97ba                	add	a5,a5,a4
    80002c9c:	639c                	ld	a5,0(a5)
    80002c9e:	10078763          	beqz	a5,80002dac <syscall+0x152>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0

    p->trapframe->a0 = syscalls[num]();
    80002ca2:	9782                	jalr	a5
    80002ca4:	f8a8                	sd	a0,112(s1)
    // if our system call was AUDIT, we specifically need to take what's in a0
    // out right here. this contains the whitelist array for what calls to audit
    if (num == 22) {
    80002ca6:	47d9                	li	a5,22
    80002ca8:	04fa0463          	beq	s4,a5,80002cf0 <syscall+0x96>
      }
      declared_length = *(bruh->length);
      //printf("process %s with id %d called audit at time %d\n", p->name, p->pid, ticks);
      printf("declared length: %d\n", declared_length);
    }
    if (!declared_length) {
    80002cac:	00006797          	auipc	a5,0x6
    80002cb0:	f687a783          	lw	a5,-152(a5) # 80008c14 <declared_length>
    80002cb4:	cfc9                	beqz	a5,80002d4e <syscall+0xf4>
      // nothing is whitelisted.
      printf("process %s with id %d called %s at time %d\n", p->name, p->pid, name_from_num[num], ticks);
    } else {
      // something is whitelisted.
      for (int i = 0; i < declared_length; i++) {
    80002cb6:	00014497          	auipc	s1,0x14
    80002cba:	22248493          	addi	s1,s1,546 # 80016ed8 <whitelisted>
    80002cbe:	4901                	li	s2,0
    80002cc0:	10f05763          	blez	a5,80002dce <syscall+0x174>
        // if it's whitelisted, we care. otherwise, just let it time out.
        if (num == whitelisted[i]) {
          printf("process %s with id %d called %s at time %d\n", p->name, p->pid, name_from_num[num], ticks);
    80002cc4:	00006b97          	auipc	s7,0x6
    80002cc8:	f4cb8b93          	addi	s7,s7,-180 # 80008c10 <ticks>
    80002ccc:	003a1b13          	slli	s6,s4,0x3
    80002cd0:	00006797          	auipc	a5,0x6
    80002cd4:	e1878793          	addi	a5,a5,-488 # 80008ae8 <name_from_num>
    80002cd8:	9b3e                	add	s6,s6,a5
    80002cda:	15898c93          	addi	s9,s3,344
    80002cde:	00006c17          	auipc	s8,0x6
    80002ce2:	82ac0c13          	addi	s8,s8,-2006 # 80008508 <states.1784+0x178>
      for (int i = 0; i < declared_length; i++) {
    80002ce6:	00006a97          	auipc	s5,0x6
    80002cea:	f2ea8a93          	addi	s5,s5,-210 # 80008c14 <declared_length>
    80002cee:	a85d                	j	80002da4 <syscall+0x14a>
      struct aud* bruh = (struct aud*)p->trapframe->a0;
    80002cf0:	0589b783          	ld	a5,88(s3)
    80002cf4:	7ba4                	ld	s1,112(a5)
      printf("edit in kernel\n");
    80002cf6:	00005517          	auipc	a0,0x5
    80002cfa:	7ea50513          	addi	a0,a0,2026 # 800084e0 <states.1784+0x150>
    80002cfe:	ffffe097          	auipc	ra,0xffffe
    80002d02:	890080e7          	jalr	-1904(ra) # 8000058e <printf>
      for (int i = 0; i < *(bruh->length); i++) {
    80002d06:	649c                	ld	a5,8(s1)
    80002d08:	438c                	lw	a1,0(a5)
    80002d0a:	02b05563          	blez	a1,80002d34 <syscall+0xda>
    80002d0e:	00014697          	auipc	a3,0x14
    80002d12:	1ca68693          	addi	a3,a3,458 # 80016ed8 <whitelisted>
    80002d16:	4781                	li	a5,0
        whitelisted[i] = *(bruh->arr + i);
    80002d18:	6098                	ld	a4,0(s1)
    80002d1a:	00279613          	slli	a2,a5,0x2
    80002d1e:	9732                	add	a4,a4,a2
    80002d20:	4318                	lw	a4,0(a4)
    80002d22:	c298                	sw	a4,0(a3)
      for (int i = 0; i < *(bruh->length); i++) {
    80002d24:	6498                	ld	a4,8(s1)
    80002d26:	430c                	lw	a1,0(a4)
    80002d28:	0785                	addi	a5,a5,1
    80002d2a:	0691                	addi	a3,a3,4
    80002d2c:	0007871b          	sext.w	a4,a5
    80002d30:	feb744e3          	blt	a4,a1,80002d18 <syscall+0xbe>
      declared_length = *(bruh->length);
    80002d34:	00006797          	auipc	a5,0x6
    80002d38:	eeb7a023          	sw	a1,-288(a5) # 80008c14 <declared_length>
      printf("declared length: %d\n", declared_length);
    80002d3c:	00005517          	auipc	a0,0x5
    80002d40:	7b450513          	addi	a0,a0,1972 # 800084f0 <states.1784+0x160>
    80002d44:	ffffe097          	auipc	ra,0xffffe
    80002d48:	84a080e7          	jalr	-1974(ra) # 8000058e <printf>
    80002d4c:	b785                	j	80002cac <syscall+0x52>
      printf("process %s with id %d called %s at time %d\n", p->name, p->pid, name_from_num[num], ticks);
    80002d4e:	0a0e                	slli	s4,s4,0x3
    80002d50:	00006797          	auipc	a5,0x6
    80002d54:	d9878793          	addi	a5,a5,-616 # 80008ae8 <name_from_num>
    80002d58:	9a3e                	add	s4,s4,a5
    80002d5a:	00006717          	auipc	a4,0x6
    80002d5e:	eb672703          	lw	a4,-330(a4) # 80008c10 <ticks>
    80002d62:	000a3683          	ld	a3,0(s4)
    80002d66:	0309a603          	lw	a2,48(s3)
    80002d6a:	15898593          	addi	a1,s3,344
    80002d6e:	00005517          	auipc	a0,0x5
    80002d72:	79a50513          	addi	a0,a0,1946 # 80008508 <states.1784+0x178>
    80002d76:	ffffe097          	auipc	ra,0xffffe
    80002d7a:	818080e7          	jalr	-2024(ra) # 8000058e <printf>
    80002d7e:	a881                	j	80002dce <syscall+0x174>
          printf("process %s with id %d called %s at time %d\n", p->name, p->pid, name_from_num[num], ticks);
    80002d80:	000ba703          	lw	a4,0(s7)
    80002d84:	000b3683          	ld	a3,0(s6)
    80002d88:	0309a603          	lw	a2,48(s3)
    80002d8c:	85e6                	mv	a1,s9
    80002d8e:	8562                	mv	a0,s8
    80002d90:	ffffd097          	auipc	ra,0xffffd
    80002d94:	7fe080e7          	jalr	2046(ra) # 8000058e <printf>
      for (int i = 0; i < declared_length; i++) {
    80002d98:	2905                	addiw	s2,s2,1
    80002d9a:	0491                	addi	s1,s1,4
    80002d9c:	000aa783          	lw	a5,0(s5)
    80002da0:	02f95763          	bge	s2,a5,80002dce <syscall+0x174>
        if (num == whitelisted[i]) {
    80002da4:	409c                	lw	a5,0(s1)
    80002da6:	ff4799e3          	bne	a5,s4,80002d98 <syscall+0x13e>
    80002daa:	bfd9                	j	80002d80 <syscall+0x126>
        }
      }
    }

  } else {
    printf("%d %s: unknown sys call %d\n",
    80002dac:	86d2                	mv	a3,s4
    80002dae:	15898613          	addi	a2,s3,344
    80002db2:	0309a583          	lw	a1,48(s3)
    80002db6:	00005517          	auipc	a0,0x5
    80002dba:	78250513          	addi	a0,a0,1922 # 80008538 <states.1784+0x1a8>
    80002dbe:	ffffd097          	auipc	ra,0xffffd
    80002dc2:	7d0080e7          	jalr	2000(ra) # 8000058e <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002dc6:	0589b783          	ld	a5,88(s3)
    80002dca:	577d                	li	a4,-1
    80002dcc:	fbb8                	sd	a4,112(a5)
  }

}
    80002dce:	60e6                	ld	ra,88(sp)
    80002dd0:	6446                	ld	s0,80(sp)
    80002dd2:	64a6                	ld	s1,72(sp)
    80002dd4:	6906                	ld	s2,64(sp)
    80002dd6:	79e2                	ld	s3,56(sp)
    80002dd8:	7a42                	ld	s4,48(sp)
    80002dda:	7aa2                	ld	s5,40(sp)
    80002ddc:	7b02                	ld	s6,32(sp)
    80002dde:	6be2                	ld	s7,24(sp)
    80002de0:	6c42                	ld	s8,16(sp)
    80002de2:	6ca2                	ld	s9,8(sp)
    80002de4:	6125                	addi	sp,sp,96
    80002de6:	8082                	ret

0000000080002de8 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002de8:	1101                	addi	sp,sp,-32
    80002dea:	ec06                	sd	ra,24(sp)
    80002dec:	e822                	sd	s0,16(sp)
    80002dee:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002df0:	fec40593          	addi	a1,s0,-20
    80002df4:	4501                	li	a0,0
    80002df6:	00000097          	auipc	ra,0x0
    80002dfa:	dec080e7          	jalr	-532(ra) # 80002be2 <argint>
  exit(n);
    80002dfe:	fec42503          	lw	a0,-20(s0)
    80002e02:	fffff097          	auipc	ra,0xfffff
    80002e06:	43c080e7          	jalr	1084(ra) # 8000223e <exit>
  return 0;  // not reached
}
    80002e0a:	4501                	li	a0,0
    80002e0c:	60e2                	ld	ra,24(sp)
    80002e0e:	6442                	ld	s0,16(sp)
    80002e10:	6105                	addi	sp,sp,32
    80002e12:	8082                	ret

0000000080002e14 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002e14:	1141                	addi	sp,sp,-16
    80002e16:	e406                	sd	ra,8(sp)
    80002e18:	e022                	sd	s0,0(sp)
    80002e1a:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002e1c:	fffff097          	auipc	ra,0xfffff
    80002e20:	baa080e7          	jalr	-1110(ra) # 800019c6 <myproc>
}
    80002e24:	5908                	lw	a0,48(a0)
    80002e26:	60a2                	ld	ra,8(sp)
    80002e28:	6402                	ld	s0,0(sp)
    80002e2a:	0141                	addi	sp,sp,16
    80002e2c:	8082                	ret

0000000080002e2e <sys_fork>:

uint64
sys_fork(void)
{
    80002e2e:	1141                	addi	sp,sp,-16
    80002e30:	e406                	sd	ra,8(sp)
    80002e32:	e022                	sd	s0,0(sp)
    80002e34:	0800                	addi	s0,sp,16
  return fork();
    80002e36:	fffff097          	auipc	ra,0xfffff
    80002e3a:	f46080e7          	jalr	-186(ra) # 80001d7c <fork>
}
    80002e3e:	60a2                	ld	ra,8(sp)
    80002e40:	6402                	ld	s0,0(sp)
    80002e42:	0141                	addi	sp,sp,16
    80002e44:	8082                	ret

0000000080002e46 <sys_wait>:

uint64
sys_wait(void)
{
    80002e46:	1101                	addi	sp,sp,-32
    80002e48:	ec06                	sd	ra,24(sp)
    80002e4a:	e822                	sd	s0,16(sp)
    80002e4c:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002e4e:	fe840593          	addi	a1,s0,-24
    80002e52:	4501                	li	a0,0
    80002e54:	00000097          	auipc	ra,0x0
    80002e58:	dae080e7          	jalr	-594(ra) # 80002c02 <argaddr>
  return wait(p);
    80002e5c:	fe843503          	ld	a0,-24(s0)
    80002e60:	fffff097          	auipc	ra,0xfffff
    80002e64:	584080e7          	jalr	1412(ra) # 800023e4 <wait>
}
    80002e68:	60e2                	ld	ra,24(sp)
    80002e6a:	6442                	ld	s0,16(sp)
    80002e6c:	6105                	addi	sp,sp,32
    80002e6e:	8082                	ret

0000000080002e70 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e70:	7179                	addi	sp,sp,-48
    80002e72:	f406                	sd	ra,40(sp)
    80002e74:	f022                	sd	s0,32(sp)
    80002e76:	ec26                	sd	s1,24(sp)
    80002e78:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002e7a:	fdc40593          	addi	a1,s0,-36
    80002e7e:	4501                	li	a0,0
    80002e80:	00000097          	auipc	ra,0x0
    80002e84:	d62080e7          	jalr	-670(ra) # 80002be2 <argint>
  addr = myproc()->sz;
    80002e88:	fffff097          	auipc	ra,0xfffff
    80002e8c:	b3e080e7          	jalr	-1218(ra) # 800019c6 <myproc>
    80002e90:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002e92:	fdc42503          	lw	a0,-36(s0)
    80002e96:	fffff097          	auipc	ra,0xfffff
    80002e9a:	e8a080e7          	jalr	-374(ra) # 80001d20 <growproc>
    80002e9e:	00054863          	bltz	a0,80002eae <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002ea2:	8526                	mv	a0,s1
    80002ea4:	70a2                	ld	ra,40(sp)
    80002ea6:	7402                	ld	s0,32(sp)
    80002ea8:	64e2                	ld	s1,24(sp)
    80002eaa:	6145                	addi	sp,sp,48
    80002eac:	8082                	ret
    return -1;
    80002eae:	54fd                	li	s1,-1
    80002eb0:	bfcd                	j	80002ea2 <sys_sbrk+0x32>

0000000080002eb2 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002eb2:	7139                	addi	sp,sp,-64
    80002eb4:	fc06                	sd	ra,56(sp)
    80002eb6:	f822                	sd	s0,48(sp)
    80002eb8:	f426                	sd	s1,40(sp)
    80002eba:	f04a                	sd	s2,32(sp)
    80002ebc:	ec4e                	sd	s3,24(sp)
    80002ebe:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002ec0:	fcc40593          	addi	a1,s0,-52
    80002ec4:	4501                	li	a0,0
    80002ec6:	00000097          	auipc	ra,0x0
    80002eca:	d1c080e7          	jalr	-740(ra) # 80002be2 <argint>
  acquire(&tickslock);
    80002ece:	00014517          	auipc	a0,0x14
    80002ed2:	ff250513          	addi	a0,a0,-14 # 80016ec0 <tickslock>
    80002ed6:	ffffe097          	auipc	ra,0xffffe
    80002eda:	d14080e7          	jalr	-748(ra) # 80000bea <acquire>
  ticks0 = ticks;
    80002ede:	00006917          	auipc	s2,0x6
    80002ee2:	d3292903          	lw	s2,-718(s2) # 80008c10 <ticks>
  while(ticks - ticks0 < n){
    80002ee6:	fcc42783          	lw	a5,-52(s0)
    80002eea:	cf9d                	beqz	a5,80002f28 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002eec:	00014997          	auipc	s3,0x14
    80002ef0:	fd498993          	addi	s3,s3,-44 # 80016ec0 <tickslock>
    80002ef4:	00006497          	auipc	s1,0x6
    80002ef8:	d1c48493          	addi	s1,s1,-740 # 80008c10 <ticks>
    if(killed(myproc())){
    80002efc:	fffff097          	auipc	ra,0xfffff
    80002f00:	aca080e7          	jalr	-1334(ra) # 800019c6 <myproc>
    80002f04:	fffff097          	auipc	ra,0xfffff
    80002f08:	4ae080e7          	jalr	1198(ra) # 800023b2 <killed>
    80002f0c:	ed15                	bnez	a0,80002f48 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002f0e:	85ce                	mv	a1,s3
    80002f10:	8526                	mv	a0,s1
    80002f12:	fffff097          	auipc	ra,0xfffff
    80002f16:	1f8080e7          	jalr	504(ra) # 8000210a <sleep>
  while(ticks - ticks0 < n){
    80002f1a:	409c                	lw	a5,0(s1)
    80002f1c:	412787bb          	subw	a5,a5,s2
    80002f20:	fcc42703          	lw	a4,-52(s0)
    80002f24:	fce7ece3          	bltu	a5,a4,80002efc <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002f28:	00014517          	auipc	a0,0x14
    80002f2c:	f9850513          	addi	a0,a0,-104 # 80016ec0 <tickslock>
    80002f30:	ffffe097          	auipc	ra,0xffffe
    80002f34:	d6e080e7          	jalr	-658(ra) # 80000c9e <release>
  return 0;
    80002f38:	4501                	li	a0,0
}
    80002f3a:	70e2                	ld	ra,56(sp)
    80002f3c:	7442                	ld	s0,48(sp)
    80002f3e:	74a2                	ld	s1,40(sp)
    80002f40:	7902                	ld	s2,32(sp)
    80002f42:	69e2                	ld	s3,24(sp)
    80002f44:	6121                	addi	sp,sp,64
    80002f46:	8082                	ret
      release(&tickslock);
    80002f48:	00014517          	auipc	a0,0x14
    80002f4c:	f7850513          	addi	a0,a0,-136 # 80016ec0 <tickslock>
    80002f50:	ffffe097          	auipc	ra,0xffffe
    80002f54:	d4e080e7          	jalr	-690(ra) # 80000c9e <release>
      return -1;
    80002f58:	557d                	li	a0,-1
    80002f5a:	b7c5                	j	80002f3a <sys_sleep+0x88>

0000000080002f5c <sys_kill>:

uint64
sys_kill(void)
{
    80002f5c:	1101                	addi	sp,sp,-32
    80002f5e:	ec06                	sd	ra,24(sp)
    80002f60:	e822                	sd	s0,16(sp)
    80002f62:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002f64:	fec40593          	addi	a1,s0,-20
    80002f68:	4501                	li	a0,0
    80002f6a:	00000097          	auipc	ra,0x0
    80002f6e:	c78080e7          	jalr	-904(ra) # 80002be2 <argint>
  return kill(pid);
    80002f72:	fec42503          	lw	a0,-20(s0)
    80002f76:	fffff097          	auipc	ra,0xfffff
    80002f7a:	39e080e7          	jalr	926(ra) # 80002314 <kill>
}
    80002f7e:	60e2                	ld	ra,24(sp)
    80002f80:	6442                	ld	s0,16(sp)
    80002f82:	6105                	addi	sp,sp,32
    80002f84:	8082                	ret

0000000080002f86 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002f86:	1101                	addi	sp,sp,-32
    80002f88:	ec06                	sd	ra,24(sp)
    80002f8a:	e822                	sd	s0,16(sp)
    80002f8c:	e426                	sd	s1,8(sp)
    80002f8e:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002f90:	00014517          	auipc	a0,0x14
    80002f94:	f3050513          	addi	a0,a0,-208 # 80016ec0 <tickslock>
    80002f98:	ffffe097          	auipc	ra,0xffffe
    80002f9c:	c52080e7          	jalr	-942(ra) # 80000bea <acquire>
  xticks = ticks;
    80002fa0:	00006497          	auipc	s1,0x6
    80002fa4:	c704a483          	lw	s1,-912(s1) # 80008c10 <ticks>
  release(&tickslock);
    80002fa8:	00014517          	auipc	a0,0x14
    80002fac:	f1850513          	addi	a0,a0,-232 # 80016ec0 <tickslock>
    80002fb0:	ffffe097          	auipc	ra,0xffffe
    80002fb4:	cee080e7          	jalr	-786(ra) # 80000c9e <release>
  return xticks;
}
    80002fb8:	02049513          	slli	a0,s1,0x20
    80002fbc:	9101                	srli	a0,a0,0x20
    80002fbe:	60e2                	ld	ra,24(sp)
    80002fc0:	6442                	ld	s0,16(sp)
    80002fc2:	64a2                	ld	s1,8(sp)
    80002fc4:	6105                	addi	sp,sp,32
    80002fc6:	8082                	ret

0000000080002fc8 <sys_audit>:

uint64
sys_audit(void)
{
    80002fc8:	1101                	addi	sp,sp,-32
    80002fca:	ec06                	sd	ra,24(sp)
    80002fcc:	e822                	sd	s0,16(sp)
    80002fce:	1000                	addi	s0,sp,32
  printf("in sys audit\n");
    80002fd0:	00005517          	auipc	a0,0x5
    80002fd4:	71850513          	addi	a0,a0,1816 # 800086e8 <syscalls+0xc8>
    80002fd8:	ffffd097          	auipc	ra,0xffffd
    80002fdc:	5b6080e7          	jalr	1462(ra) # 8000058e <printf>
  uint64 arr_addr;
  uint64 length;
  argaddr(0, &arr_addr);
    80002fe0:	fe840593          	addi	a1,s0,-24
    80002fe4:	4501                	li	a0,0
    80002fe6:	00000097          	auipc	ra,0x0
    80002fea:	c1c080e7          	jalr	-996(ra) # 80002c02 <argaddr>
  argaddr(1, &length);
    80002fee:	fe040593          	addi	a1,s0,-32
    80002ff2:	4505                	li	a0,1
    80002ff4:	00000097          	auipc	ra,0x0
    80002ff8:	c0e080e7          	jalr	-1010(ra) # 80002c02 <argaddr>
  printf("address of length: %p\n", (int*) length);
    80002ffc:	fe043583          	ld	a1,-32(s0)
    80003000:	00005517          	auipc	a0,0x5
    80003004:	6f850513          	addi	a0,a0,1784 # 800086f8 <syscalls+0xd8>
    80003008:	ffffd097          	auipc	ra,0xffffd
    8000300c:	586080e7          	jalr	1414(ra) # 8000058e <printf>
  return audit((int*) arr_addr, (int*) length);
    80003010:	fe043583          	ld	a1,-32(s0)
    80003014:	fe843503          	ld	a0,-24(s0)
    80003018:	fffff097          	auipc	ra,0xfffff
    8000301c:	ea0080e7          	jalr	-352(ra) # 80001eb8 <audit>
}
    80003020:	60e2                	ld	ra,24(sp)
    80003022:	6442                	ld	s0,16(sp)
    80003024:	6105                	addi	sp,sp,32
    80003026:	8082                	ret

0000000080003028 <sys_logs>:

uint64           
sys_logs(void)
{
    80003028:	1101                	addi	sp,sp,-32
    8000302a:	ec06                	sd	ra,24(sp)
    8000302c:	e822                	sd	s0,16(sp)
    8000302e:	1000                	addi	s0,sp,32
    uint64 addr;
    argaddr(0, &addr);
    80003030:	fe840593          	addi	a1,s0,-24
    80003034:	4501                	li	a0,0
    80003036:	00000097          	auipc	ra,0x0
    8000303a:	bcc080e7          	jalr	-1076(ra) # 80002c02 <argaddr>
    return logs((void *) addr);
    8000303e:	fe843503          	ld	a0,-24(s0)
    80003042:	fffff097          	auipc	ra,0xfffff
    80003046:	62a080e7          	jalr	1578(ra) # 8000266c <logs>
}
    8000304a:	60e2                	ld	ra,24(sp)
    8000304c:	6442                	ld	s0,16(sp)
    8000304e:	6105                	addi	sp,sp,32
    80003050:	8082                	ret

0000000080003052 <sys_try2>:

uint64 sys_try2(void){
    80003052:	1101                	addi	sp,sp,-32
    80003054:	ec06                	sd	ra,24(sp)
    80003056:	e822                	sd	s0,16(sp)
    80003058:	1000                	addi	s0,sp,32
    uint64 addr;
    argaddr(0, &addr);
    8000305a:	fe840593          	addi	a1,s0,-24
    8000305e:	4501                	li	a0,0
    80003060:	00000097          	auipc	ra,0x0
    80003064:	ba2080e7          	jalr	-1118(ra) # 80002c02 <argaddr>
    return try2((void *) addr);
    80003068:	fe843503          	ld	a0,-24(s0)
    8000306c:	fffff097          	auipc	ra,0xfffff
    80003070:	648080e7          	jalr	1608(ra) # 800026b4 <try2>
}
    80003074:	60e2                	ld	ra,24(sp)
    80003076:	6442                	ld	s0,16(sp)
    80003078:	6105                	addi	sp,sp,32
    8000307a:	8082                	ret

000000008000307c <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000307c:	7179                	addi	sp,sp,-48
    8000307e:	f406                	sd	ra,40(sp)
    80003080:	f022                	sd	s0,32(sp)
    80003082:	ec26                	sd	s1,24(sp)
    80003084:	e84a                	sd	s2,16(sp)
    80003086:	e44e                	sd	s3,8(sp)
    80003088:	e052                	sd	s4,0(sp)
    8000308a:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000308c:	00005597          	auipc	a1,0x5
    80003090:	68458593          	addi	a1,a1,1668 # 80008710 <syscalls+0xf0>
    80003094:	0001c517          	auipc	a0,0x1c
    80003098:	eac50513          	addi	a0,a0,-340 # 8001ef40 <bcache>
    8000309c:	ffffe097          	auipc	ra,0xffffe
    800030a0:	abe080e7          	jalr	-1346(ra) # 80000b5a <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    800030a4:	00024797          	auipc	a5,0x24
    800030a8:	e9c78793          	addi	a5,a5,-356 # 80026f40 <bcache+0x8000>
    800030ac:	00024717          	auipc	a4,0x24
    800030b0:	0fc70713          	addi	a4,a4,252 # 800271a8 <bcache+0x8268>
    800030b4:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800030b8:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800030bc:	0001c497          	auipc	s1,0x1c
    800030c0:	e9c48493          	addi	s1,s1,-356 # 8001ef58 <bcache+0x18>
    b->next = bcache.head.next;
    800030c4:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800030c6:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800030c8:	00005a17          	auipc	s4,0x5
    800030cc:	650a0a13          	addi	s4,s4,1616 # 80008718 <syscalls+0xf8>
    b->next = bcache.head.next;
    800030d0:	2b893783          	ld	a5,696(s2)
    800030d4:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800030d6:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800030da:	85d2                	mv	a1,s4
    800030dc:	01048513          	addi	a0,s1,16
    800030e0:	00001097          	auipc	ra,0x1
    800030e4:	4c4080e7          	jalr	1220(ra) # 800045a4 <initsleeplock>
    bcache.head.next->prev = b;
    800030e8:	2b893783          	ld	a5,696(s2)
    800030ec:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800030ee:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800030f2:	45848493          	addi	s1,s1,1112
    800030f6:	fd349de3          	bne	s1,s3,800030d0 <binit+0x54>
  }
}
    800030fa:	70a2                	ld	ra,40(sp)
    800030fc:	7402                	ld	s0,32(sp)
    800030fe:	64e2                	ld	s1,24(sp)
    80003100:	6942                	ld	s2,16(sp)
    80003102:	69a2                	ld	s3,8(sp)
    80003104:	6a02                	ld	s4,0(sp)
    80003106:	6145                	addi	sp,sp,48
    80003108:	8082                	ret

000000008000310a <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000310a:	7179                	addi	sp,sp,-48
    8000310c:	f406                	sd	ra,40(sp)
    8000310e:	f022                	sd	s0,32(sp)
    80003110:	ec26                	sd	s1,24(sp)
    80003112:	e84a                	sd	s2,16(sp)
    80003114:	e44e                	sd	s3,8(sp)
    80003116:	1800                	addi	s0,sp,48
    80003118:	89aa                	mv	s3,a0
    8000311a:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    8000311c:	0001c517          	auipc	a0,0x1c
    80003120:	e2450513          	addi	a0,a0,-476 # 8001ef40 <bcache>
    80003124:	ffffe097          	auipc	ra,0xffffe
    80003128:	ac6080e7          	jalr	-1338(ra) # 80000bea <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000312c:	00024497          	auipc	s1,0x24
    80003130:	0cc4b483          	ld	s1,204(s1) # 800271f8 <bcache+0x82b8>
    80003134:	00024797          	auipc	a5,0x24
    80003138:	07478793          	addi	a5,a5,116 # 800271a8 <bcache+0x8268>
    8000313c:	02f48f63          	beq	s1,a5,8000317a <bread+0x70>
    80003140:	873e                	mv	a4,a5
    80003142:	a021                	j	8000314a <bread+0x40>
    80003144:	68a4                	ld	s1,80(s1)
    80003146:	02e48a63          	beq	s1,a4,8000317a <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000314a:	449c                	lw	a5,8(s1)
    8000314c:	ff379ce3          	bne	a5,s3,80003144 <bread+0x3a>
    80003150:	44dc                	lw	a5,12(s1)
    80003152:	ff2799e3          	bne	a5,s2,80003144 <bread+0x3a>
      b->refcnt++;
    80003156:	40bc                	lw	a5,64(s1)
    80003158:	2785                	addiw	a5,a5,1
    8000315a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000315c:	0001c517          	auipc	a0,0x1c
    80003160:	de450513          	addi	a0,a0,-540 # 8001ef40 <bcache>
    80003164:	ffffe097          	auipc	ra,0xffffe
    80003168:	b3a080e7          	jalr	-1222(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    8000316c:	01048513          	addi	a0,s1,16
    80003170:	00001097          	auipc	ra,0x1
    80003174:	46e080e7          	jalr	1134(ra) # 800045de <acquiresleep>
      return b;
    80003178:	a8b9                	j	800031d6 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000317a:	00024497          	auipc	s1,0x24
    8000317e:	0764b483          	ld	s1,118(s1) # 800271f0 <bcache+0x82b0>
    80003182:	00024797          	auipc	a5,0x24
    80003186:	02678793          	addi	a5,a5,38 # 800271a8 <bcache+0x8268>
    8000318a:	00f48863          	beq	s1,a5,8000319a <bread+0x90>
    8000318e:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003190:	40bc                	lw	a5,64(s1)
    80003192:	cf81                	beqz	a5,800031aa <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003194:	64a4                	ld	s1,72(s1)
    80003196:	fee49de3          	bne	s1,a4,80003190 <bread+0x86>
  panic("bget: no buffers");
    8000319a:	00005517          	auipc	a0,0x5
    8000319e:	58650513          	addi	a0,a0,1414 # 80008720 <syscalls+0x100>
    800031a2:	ffffd097          	auipc	ra,0xffffd
    800031a6:	3a2080e7          	jalr	930(ra) # 80000544 <panic>
      b->dev = dev;
    800031aa:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800031ae:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800031b2:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800031b6:	4785                	li	a5,1
    800031b8:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800031ba:	0001c517          	auipc	a0,0x1c
    800031be:	d8650513          	addi	a0,a0,-634 # 8001ef40 <bcache>
    800031c2:	ffffe097          	auipc	ra,0xffffe
    800031c6:	adc080e7          	jalr	-1316(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    800031ca:	01048513          	addi	a0,s1,16
    800031ce:	00001097          	auipc	ra,0x1
    800031d2:	410080e7          	jalr	1040(ra) # 800045de <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800031d6:	409c                	lw	a5,0(s1)
    800031d8:	cb89                	beqz	a5,800031ea <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800031da:	8526                	mv	a0,s1
    800031dc:	70a2                	ld	ra,40(sp)
    800031de:	7402                	ld	s0,32(sp)
    800031e0:	64e2                	ld	s1,24(sp)
    800031e2:	6942                	ld	s2,16(sp)
    800031e4:	69a2                	ld	s3,8(sp)
    800031e6:	6145                	addi	sp,sp,48
    800031e8:	8082                	ret
    virtio_disk_rw(b, 0);
    800031ea:	4581                	li	a1,0
    800031ec:	8526                	mv	a0,s1
    800031ee:	00003097          	auipc	ra,0x3
    800031f2:	fca080e7          	jalr	-54(ra) # 800061b8 <virtio_disk_rw>
    b->valid = 1;
    800031f6:	4785                	li	a5,1
    800031f8:	c09c                	sw	a5,0(s1)
  return b;
    800031fa:	b7c5                	j	800031da <bread+0xd0>

00000000800031fc <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800031fc:	1101                	addi	sp,sp,-32
    800031fe:	ec06                	sd	ra,24(sp)
    80003200:	e822                	sd	s0,16(sp)
    80003202:	e426                	sd	s1,8(sp)
    80003204:	1000                	addi	s0,sp,32
    80003206:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003208:	0541                	addi	a0,a0,16
    8000320a:	00001097          	auipc	ra,0x1
    8000320e:	46e080e7          	jalr	1134(ra) # 80004678 <holdingsleep>
    80003212:	cd01                	beqz	a0,8000322a <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003214:	4585                	li	a1,1
    80003216:	8526                	mv	a0,s1
    80003218:	00003097          	auipc	ra,0x3
    8000321c:	fa0080e7          	jalr	-96(ra) # 800061b8 <virtio_disk_rw>
}
    80003220:	60e2                	ld	ra,24(sp)
    80003222:	6442                	ld	s0,16(sp)
    80003224:	64a2                	ld	s1,8(sp)
    80003226:	6105                	addi	sp,sp,32
    80003228:	8082                	ret
    panic("bwrite");
    8000322a:	00005517          	auipc	a0,0x5
    8000322e:	50e50513          	addi	a0,a0,1294 # 80008738 <syscalls+0x118>
    80003232:	ffffd097          	auipc	ra,0xffffd
    80003236:	312080e7          	jalr	786(ra) # 80000544 <panic>

000000008000323a <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000323a:	1101                	addi	sp,sp,-32
    8000323c:	ec06                	sd	ra,24(sp)
    8000323e:	e822                	sd	s0,16(sp)
    80003240:	e426                	sd	s1,8(sp)
    80003242:	e04a                	sd	s2,0(sp)
    80003244:	1000                	addi	s0,sp,32
    80003246:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003248:	01050913          	addi	s2,a0,16
    8000324c:	854a                	mv	a0,s2
    8000324e:	00001097          	auipc	ra,0x1
    80003252:	42a080e7          	jalr	1066(ra) # 80004678 <holdingsleep>
    80003256:	c92d                	beqz	a0,800032c8 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003258:	854a                	mv	a0,s2
    8000325a:	00001097          	auipc	ra,0x1
    8000325e:	3da080e7          	jalr	986(ra) # 80004634 <releasesleep>

  acquire(&bcache.lock);
    80003262:	0001c517          	auipc	a0,0x1c
    80003266:	cde50513          	addi	a0,a0,-802 # 8001ef40 <bcache>
    8000326a:	ffffe097          	auipc	ra,0xffffe
    8000326e:	980080e7          	jalr	-1664(ra) # 80000bea <acquire>
  b->refcnt--;
    80003272:	40bc                	lw	a5,64(s1)
    80003274:	37fd                	addiw	a5,a5,-1
    80003276:	0007871b          	sext.w	a4,a5
    8000327a:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000327c:	eb05                	bnez	a4,800032ac <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000327e:	68bc                	ld	a5,80(s1)
    80003280:	64b8                	ld	a4,72(s1)
    80003282:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003284:	64bc                	ld	a5,72(s1)
    80003286:	68b8                	ld	a4,80(s1)
    80003288:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000328a:	00024797          	auipc	a5,0x24
    8000328e:	cb678793          	addi	a5,a5,-842 # 80026f40 <bcache+0x8000>
    80003292:	2b87b703          	ld	a4,696(a5)
    80003296:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003298:	00024717          	auipc	a4,0x24
    8000329c:	f1070713          	addi	a4,a4,-240 # 800271a8 <bcache+0x8268>
    800032a0:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800032a2:	2b87b703          	ld	a4,696(a5)
    800032a6:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800032a8:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800032ac:	0001c517          	auipc	a0,0x1c
    800032b0:	c9450513          	addi	a0,a0,-876 # 8001ef40 <bcache>
    800032b4:	ffffe097          	auipc	ra,0xffffe
    800032b8:	9ea080e7          	jalr	-1558(ra) # 80000c9e <release>
}
    800032bc:	60e2                	ld	ra,24(sp)
    800032be:	6442                	ld	s0,16(sp)
    800032c0:	64a2                	ld	s1,8(sp)
    800032c2:	6902                	ld	s2,0(sp)
    800032c4:	6105                	addi	sp,sp,32
    800032c6:	8082                	ret
    panic("brelse");
    800032c8:	00005517          	auipc	a0,0x5
    800032cc:	47850513          	addi	a0,a0,1144 # 80008740 <syscalls+0x120>
    800032d0:	ffffd097          	auipc	ra,0xffffd
    800032d4:	274080e7          	jalr	628(ra) # 80000544 <panic>

00000000800032d8 <bpin>:

void
bpin(struct buf *b) {
    800032d8:	1101                	addi	sp,sp,-32
    800032da:	ec06                	sd	ra,24(sp)
    800032dc:	e822                	sd	s0,16(sp)
    800032de:	e426                	sd	s1,8(sp)
    800032e0:	1000                	addi	s0,sp,32
    800032e2:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032e4:	0001c517          	auipc	a0,0x1c
    800032e8:	c5c50513          	addi	a0,a0,-932 # 8001ef40 <bcache>
    800032ec:	ffffe097          	auipc	ra,0xffffe
    800032f0:	8fe080e7          	jalr	-1794(ra) # 80000bea <acquire>
  b->refcnt++;
    800032f4:	40bc                	lw	a5,64(s1)
    800032f6:	2785                	addiw	a5,a5,1
    800032f8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032fa:	0001c517          	auipc	a0,0x1c
    800032fe:	c4650513          	addi	a0,a0,-954 # 8001ef40 <bcache>
    80003302:	ffffe097          	auipc	ra,0xffffe
    80003306:	99c080e7          	jalr	-1636(ra) # 80000c9e <release>
}
    8000330a:	60e2                	ld	ra,24(sp)
    8000330c:	6442                	ld	s0,16(sp)
    8000330e:	64a2                	ld	s1,8(sp)
    80003310:	6105                	addi	sp,sp,32
    80003312:	8082                	ret

0000000080003314 <bunpin>:

void
bunpin(struct buf *b) {
    80003314:	1101                	addi	sp,sp,-32
    80003316:	ec06                	sd	ra,24(sp)
    80003318:	e822                	sd	s0,16(sp)
    8000331a:	e426                	sd	s1,8(sp)
    8000331c:	1000                	addi	s0,sp,32
    8000331e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003320:	0001c517          	auipc	a0,0x1c
    80003324:	c2050513          	addi	a0,a0,-992 # 8001ef40 <bcache>
    80003328:	ffffe097          	auipc	ra,0xffffe
    8000332c:	8c2080e7          	jalr	-1854(ra) # 80000bea <acquire>
  b->refcnt--;
    80003330:	40bc                	lw	a5,64(s1)
    80003332:	37fd                	addiw	a5,a5,-1
    80003334:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003336:	0001c517          	auipc	a0,0x1c
    8000333a:	c0a50513          	addi	a0,a0,-1014 # 8001ef40 <bcache>
    8000333e:	ffffe097          	auipc	ra,0xffffe
    80003342:	960080e7          	jalr	-1696(ra) # 80000c9e <release>
}
    80003346:	60e2                	ld	ra,24(sp)
    80003348:	6442                	ld	s0,16(sp)
    8000334a:	64a2                	ld	s1,8(sp)
    8000334c:	6105                	addi	sp,sp,32
    8000334e:	8082                	ret

0000000080003350 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003350:	1101                	addi	sp,sp,-32
    80003352:	ec06                	sd	ra,24(sp)
    80003354:	e822                	sd	s0,16(sp)
    80003356:	e426                	sd	s1,8(sp)
    80003358:	e04a                	sd	s2,0(sp)
    8000335a:	1000                	addi	s0,sp,32
    8000335c:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000335e:	00d5d59b          	srliw	a1,a1,0xd
    80003362:	00024797          	auipc	a5,0x24
    80003366:	2ba7a783          	lw	a5,698(a5) # 8002761c <sb+0x1c>
    8000336a:	9dbd                	addw	a1,a1,a5
    8000336c:	00000097          	auipc	ra,0x0
    80003370:	d9e080e7          	jalr	-610(ra) # 8000310a <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003374:	0074f713          	andi	a4,s1,7
    80003378:	4785                	li	a5,1
    8000337a:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000337e:	14ce                	slli	s1,s1,0x33
    80003380:	90d9                	srli	s1,s1,0x36
    80003382:	00950733          	add	a4,a0,s1
    80003386:	05874703          	lbu	a4,88(a4)
    8000338a:	00e7f6b3          	and	a3,a5,a4
    8000338e:	c69d                	beqz	a3,800033bc <bfree+0x6c>
    80003390:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003392:	94aa                	add	s1,s1,a0
    80003394:	fff7c793          	not	a5,a5
    80003398:	8ff9                	and	a5,a5,a4
    8000339a:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000339e:	00001097          	auipc	ra,0x1
    800033a2:	120080e7          	jalr	288(ra) # 800044be <log_write>
  brelse(bp);
    800033a6:	854a                	mv	a0,s2
    800033a8:	00000097          	auipc	ra,0x0
    800033ac:	e92080e7          	jalr	-366(ra) # 8000323a <brelse>
}
    800033b0:	60e2                	ld	ra,24(sp)
    800033b2:	6442                	ld	s0,16(sp)
    800033b4:	64a2                	ld	s1,8(sp)
    800033b6:	6902                	ld	s2,0(sp)
    800033b8:	6105                	addi	sp,sp,32
    800033ba:	8082                	ret
    panic("freeing free block");
    800033bc:	00005517          	auipc	a0,0x5
    800033c0:	38c50513          	addi	a0,a0,908 # 80008748 <syscalls+0x128>
    800033c4:	ffffd097          	auipc	ra,0xffffd
    800033c8:	180080e7          	jalr	384(ra) # 80000544 <panic>

00000000800033cc <balloc>:
{
    800033cc:	711d                	addi	sp,sp,-96
    800033ce:	ec86                	sd	ra,88(sp)
    800033d0:	e8a2                	sd	s0,80(sp)
    800033d2:	e4a6                	sd	s1,72(sp)
    800033d4:	e0ca                	sd	s2,64(sp)
    800033d6:	fc4e                	sd	s3,56(sp)
    800033d8:	f852                	sd	s4,48(sp)
    800033da:	f456                	sd	s5,40(sp)
    800033dc:	f05a                	sd	s6,32(sp)
    800033de:	ec5e                	sd	s7,24(sp)
    800033e0:	e862                	sd	s8,16(sp)
    800033e2:	e466                	sd	s9,8(sp)
    800033e4:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800033e6:	00024797          	auipc	a5,0x24
    800033ea:	21e7a783          	lw	a5,542(a5) # 80027604 <sb+0x4>
    800033ee:	10078163          	beqz	a5,800034f0 <balloc+0x124>
    800033f2:	8baa                	mv	s7,a0
    800033f4:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800033f6:	00024b17          	auipc	s6,0x24
    800033fa:	20ab0b13          	addi	s6,s6,522 # 80027600 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033fe:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003400:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003402:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003404:	6c89                	lui	s9,0x2
    80003406:	a061                	j	8000348e <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003408:	974a                	add	a4,a4,s2
    8000340a:	8fd5                	or	a5,a5,a3
    8000340c:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003410:	854a                	mv	a0,s2
    80003412:	00001097          	auipc	ra,0x1
    80003416:	0ac080e7          	jalr	172(ra) # 800044be <log_write>
        brelse(bp);
    8000341a:	854a                	mv	a0,s2
    8000341c:	00000097          	auipc	ra,0x0
    80003420:	e1e080e7          	jalr	-482(ra) # 8000323a <brelse>
  bp = bread(dev, bno);
    80003424:	85a6                	mv	a1,s1
    80003426:	855e                	mv	a0,s7
    80003428:	00000097          	auipc	ra,0x0
    8000342c:	ce2080e7          	jalr	-798(ra) # 8000310a <bread>
    80003430:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003432:	40000613          	li	a2,1024
    80003436:	4581                	li	a1,0
    80003438:	05850513          	addi	a0,a0,88
    8000343c:	ffffe097          	auipc	ra,0xffffe
    80003440:	8aa080e7          	jalr	-1878(ra) # 80000ce6 <memset>
  log_write(bp);
    80003444:	854a                	mv	a0,s2
    80003446:	00001097          	auipc	ra,0x1
    8000344a:	078080e7          	jalr	120(ra) # 800044be <log_write>
  brelse(bp);
    8000344e:	854a                	mv	a0,s2
    80003450:	00000097          	auipc	ra,0x0
    80003454:	dea080e7          	jalr	-534(ra) # 8000323a <brelse>
}
    80003458:	8526                	mv	a0,s1
    8000345a:	60e6                	ld	ra,88(sp)
    8000345c:	6446                	ld	s0,80(sp)
    8000345e:	64a6                	ld	s1,72(sp)
    80003460:	6906                	ld	s2,64(sp)
    80003462:	79e2                	ld	s3,56(sp)
    80003464:	7a42                	ld	s4,48(sp)
    80003466:	7aa2                	ld	s5,40(sp)
    80003468:	7b02                	ld	s6,32(sp)
    8000346a:	6be2                	ld	s7,24(sp)
    8000346c:	6c42                	ld	s8,16(sp)
    8000346e:	6ca2                	ld	s9,8(sp)
    80003470:	6125                	addi	sp,sp,96
    80003472:	8082                	ret
    brelse(bp);
    80003474:	854a                	mv	a0,s2
    80003476:	00000097          	auipc	ra,0x0
    8000347a:	dc4080e7          	jalr	-572(ra) # 8000323a <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000347e:	015c87bb          	addw	a5,s9,s5
    80003482:	00078a9b          	sext.w	s5,a5
    80003486:	004b2703          	lw	a4,4(s6)
    8000348a:	06eaf363          	bgeu	s5,a4,800034f0 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    8000348e:	41fad79b          	sraiw	a5,s5,0x1f
    80003492:	0137d79b          	srliw	a5,a5,0x13
    80003496:	015787bb          	addw	a5,a5,s5
    8000349a:	40d7d79b          	sraiw	a5,a5,0xd
    8000349e:	01cb2583          	lw	a1,28(s6)
    800034a2:	9dbd                	addw	a1,a1,a5
    800034a4:	855e                	mv	a0,s7
    800034a6:	00000097          	auipc	ra,0x0
    800034aa:	c64080e7          	jalr	-924(ra) # 8000310a <bread>
    800034ae:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034b0:	004b2503          	lw	a0,4(s6)
    800034b4:	000a849b          	sext.w	s1,s5
    800034b8:	8662                	mv	a2,s8
    800034ba:	faa4fde3          	bgeu	s1,a0,80003474 <balloc+0xa8>
      m = 1 << (bi % 8);
    800034be:	41f6579b          	sraiw	a5,a2,0x1f
    800034c2:	01d7d69b          	srliw	a3,a5,0x1d
    800034c6:	00c6873b          	addw	a4,a3,a2
    800034ca:	00777793          	andi	a5,a4,7
    800034ce:	9f95                	subw	a5,a5,a3
    800034d0:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800034d4:	4037571b          	sraiw	a4,a4,0x3
    800034d8:	00e906b3          	add	a3,s2,a4
    800034dc:	0586c683          	lbu	a3,88(a3)
    800034e0:	00d7f5b3          	and	a1,a5,a3
    800034e4:	d195                	beqz	a1,80003408 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034e6:	2605                	addiw	a2,a2,1
    800034e8:	2485                	addiw	s1,s1,1
    800034ea:	fd4618e3          	bne	a2,s4,800034ba <balloc+0xee>
    800034ee:	b759                	j	80003474 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    800034f0:	00005517          	auipc	a0,0x5
    800034f4:	27050513          	addi	a0,a0,624 # 80008760 <syscalls+0x140>
    800034f8:	ffffd097          	auipc	ra,0xffffd
    800034fc:	096080e7          	jalr	150(ra) # 8000058e <printf>
  return 0;
    80003500:	4481                	li	s1,0
    80003502:	bf99                	j	80003458 <balloc+0x8c>

0000000080003504 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003504:	7179                	addi	sp,sp,-48
    80003506:	f406                	sd	ra,40(sp)
    80003508:	f022                	sd	s0,32(sp)
    8000350a:	ec26                	sd	s1,24(sp)
    8000350c:	e84a                	sd	s2,16(sp)
    8000350e:	e44e                	sd	s3,8(sp)
    80003510:	e052                	sd	s4,0(sp)
    80003512:	1800                	addi	s0,sp,48
    80003514:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003516:	47ad                	li	a5,11
    80003518:	02b7e763          	bltu	a5,a1,80003546 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    8000351c:	02059493          	slli	s1,a1,0x20
    80003520:	9081                	srli	s1,s1,0x20
    80003522:	048a                	slli	s1,s1,0x2
    80003524:	94aa                	add	s1,s1,a0
    80003526:	0504a903          	lw	s2,80(s1)
    8000352a:	06091e63          	bnez	s2,800035a6 <bmap+0xa2>
      addr = balloc(ip->dev);
    8000352e:	4108                	lw	a0,0(a0)
    80003530:	00000097          	auipc	ra,0x0
    80003534:	e9c080e7          	jalr	-356(ra) # 800033cc <balloc>
    80003538:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000353c:	06090563          	beqz	s2,800035a6 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    80003540:	0524a823          	sw	s2,80(s1)
    80003544:	a08d                	j	800035a6 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003546:	ff45849b          	addiw	s1,a1,-12
    8000354a:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000354e:	0ff00793          	li	a5,255
    80003552:	08e7e563          	bltu	a5,a4,800035dc <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003556:	08052903          	lw	s2,128(a0)
    8000355a:	00091d63          	bnez	s2,80003574 <bmap+0x70>
      addr = balloc(ip->dev);
    8000355e:	4108                	lw	a0,0(a0)
    80003560:	00000097          	auipc	ra,0x0
    80003564:	e6c080e7          	jalr	-404(ra) # 800033cc <balloc>
    80003568:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000356c:	02090d63          	beqz	s2,800035a6 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003570:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003574:	85ca                	mv	a1,s2
    80003576:	0009a503          	lw	a0,0(s3)
    8000357a:	00000097          	auipc	ra,0x0
    8000357e:	b90080e7          	jalr	-1136(ra) # 8000310a <bread>
    80003582:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003584:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003588:	02049593          	slli	a1,s1,0x20
    8000358c:	9181                	srli	a1,a1,0x20
    8000358e:	058a                	slli	a1,a1,0x2
    80003590:	00b784b3          	add	s1,a5,a1
    80003594:	0004a903          	lw	s2,0(s1)
    80003598:	02090063          	beqz	s2,800035b8 <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    8000359c:	8552                	mv	a0,s4
    8000359e:	00000097          	auipc	ra,0x0
    800035a2:	c9c080e7          	jalr	-868(ra) # 8000323a <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800035a6:	854a                	mv	a0,s2
    800035a8:	70a2                	ld	ra,40(sp)
    800035aa:	7402                	ld	s0,32(sp)
    800035ac:	64e2                	ld	s1,24(sp)
    800035ae:	6942                	ld	s2,16(sp)
    800035b0:	69a2                	ld	s3,8(sp)
    800035b2:	6a02                	ld	s4,0(sp)
    800035b4:	6145                	addi	sp,sp,48
    800035b6:	8082                	ret
      addr = balloc(ip->dev);
    800035b8:	0009a503          	lw	a0,0(s3)
    800035bc:	00000097          	auipc	ra,0x0
    800035c0:	e10080e7          	jalr	-496(ra) # 800033cc <balloc>
    800035c4:	0005091b          	sext.w	s2,a0
      if(addr){
    800035c8:	fc090ae3          	beqz	s2,8000359c <bmap+0x98>
        a[bn] = addr;
    800035cc:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800035d0:	8552                	mv	a0,s4
    800035d2:	00001097          	auipc	ra,0x1
    800035d6:	eec080e7          	jalr	-276(ra) # 800044be <log_write>
    800035da:	b7c9                	j	8000359c <bmap+0x98>
  panic("bmap: out of range");
    800035dc:	00005517          	auipc	a0,0x5
    800035e0:	19c50513          	addi	a0,a0,412 # 80008778 <syscalls+0x158>
    800035e4:	ffffd097          	auipc	ra,0xffffd
    800035e8:	f60080e7          	jalr	-160(ra) # 80000544 <panic>

00000000800035ec <iget>:
{
    800035ec:	7179                	addi	sp,sp,-48
    800035ee:	f406                	sd	ra,40(sp)
    800035f0:	f022                	sd	s0,32(sp)
    800035f2:	ec26                	sd	s1,24(sp)
    800035f4:	e84a                	sd	s2,16(sp)
    800035f6:	e44e                	sd	s3,8(sp)
    800035f8:	e052                	sd	s4,0(sp)
    800035fa:	1800                	addi	s0,sp,48
    800035fc:	89aa                	mv	s3,a0
    800035fe:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003600:	00024517          	auipc	a0,0x24
    80003604:	02050513          	addi	a0,a0,32 # 80027620 <itable>
    80003608:	ffffd097          	auipc	ra,0xffffd
    8000360c:	5e2080e7          	jalr	1506(ra) # 80000bea <acquire>
  empty = 0;
    80003610:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003612:	00024497          	auipc	s1,0x24
    80003616:	02648493          	addi	s1,s1,38 # 80027638 <itable+0x18>
    8000361a:	00026697          	auipc	a3,0x26
    8000361e:	aae68693          	addi	a3,a3,-1362 # 800290c8 <log>
    80003622:	a039                	j	80003630 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003624:	02090b63          	beqz	s2,8000365a <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003628:	08848493          	addi	s1,s1,136
    8000362c:	02d48a63          	beq	s1,a3,80003660 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003630:	449c                	lw	a5,8(s1)
    80003632:	fef059e3          	blez	a5,80003624 <iget+0x38>
    80003636:	4098                	lw	a4,0(s1)
    80003638:	ff3716e3          	bne	a4,s3,80003624 <iget+0x38>
    8000363c:	40d8                	lw	a4,4(s1)
    8000363e:	ff4713e3          	bne	a4,s4,80003624 <iget+0x38>
      ip->ref++;
    80003642:	2785                	addiw	a5,a5,1
    80003644:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003646:	00024517          	auipc	a0,0x24
    8000364a:	fda50513          	addi	a0,a0,-38 # 80027620 <itable>
    8000364e:	ffffd097          	auipc	ra,0xffffd
    80003652:	650080e7          	jalr	1616(ra) # 80000c9e <release>
      return ip;
    80003656:	8926                	mv	s2,s1
    80003658:	a03d                	j	80003686 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000365a:	f7f9                	bnez	a5,80003628 <iget+0x3c>
    8000365c:	8926                	mv	s2,s1
    8000365e:	b7e9                	j	80003628 <iget+0x3c>
  if(empty == 0)
    80003660:	02090c63          	beqz	s2,80003698 <iget+0xac>
  ip->dev = dev;
    80003664:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003668:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000366c:	4785                	li	a5,1
    8000366e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003672:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003676:	00024517          	auipc	a0,0x24
    8000367a:	faa50513          	addi	a0,a0,-86 # 80027620 <itable>
    8000367e:	ffffd097          	auipc	ra,0xffffd
    80003682:	620080e7          	jalr	1568(ra) # 80000c9e <release>
}
    80003686:	854a                	mv	a0,s2
    80003688:	70a2                	ld	ra,40(sp)
    8000368a:	7402                	ld	s0,32(sp)
    8000368c:	64e2                	ld	s1,24(sp)
    8000368e:	6942                	ld	s2,16(sp)
    80003690:	69a2                	ld	s3,8(sp)
    80003692:	6a02                	ld	s4,0(sp)
    80003694:	6145                	addi	sp,sp,48
    80003696:	8082                	ret
    panic("iget: no inodes");
    80003698:	00005517          	auipc	a0,0x5
    8000369c:	0f850513          	addi	a0,a0,248 # 80008790 <syscalls+0x170>
    800036a0:	ffffd097          	auipc	ra,0xffffd
    800036a4:	ea4080e7          	jalr	-348(ra) # 80000544 <panic>

00000000800036a8 <fsinit>:
fsinit(int dev) {
    800036a8:	7179                	addi	sp,sp,-48
    800036aa:	f406                	sd	ra,40(sp)
    800036ac:	f022                	sd	s0,32(sp)
    800036ae:	ec26                	sd	s1,24(sp)
    800036b0:	e84a                	sd	s2,16(sp)
    800036b2:	e44e                	sd	s3,8(sp)
    800036b4:	1800                	addi	s0,sp,48
    800036b6:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800036b8:	4585                	li	a1,1
    800036ba:	00000097          	auipc	ra,0x0
    800036be:	a50080e7          	jalr	-1456(ra) # 8000310a <bread>
    800036c2:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800036c4:	00024997          	auipc	s3,0x24
    800036c8:	f3c98993          	addi	s3,s3,-196 # 80027600 <sb>
    800036cc:	02000613          	li	a2,32
    800036d0:	05850593          	addi	a1,a0,88
    800036d4:	854e                	mv	a0,s3
    800036d6:	ffffd097          	auipc	ra,0xffffd
    800036da:	670080e7          	jalr	1648(ra) # 80000d46 <memmove>
  brelse(bp);
    800036de:	8526                	mv	a0,s1
    800036e0:	00000097          	auipc	ra,0x0
    800036e4:	b5a080e7          	jalr	-1190(ra) # 8000323a <brelse>
  if(sb.magic != FSMAGIC)
    800036e8:	0009a703          	lw	a4,0(s3)
    800036ec:	102037b7          	lui	a5,0x10203
    800036f0:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800036f4:	02f71263          	bne	a4,a5,80003718 <fsinit+0x70>
  initlog(dev, &sb);
    800036f8:	00024597          	auipc	a1,0x24
    800036fc:	f0858593          	addi	a1,a1,-248 # 80027600 <sb>
    80003700:	854a                	mv	a0,s2
    80003702:	00001097          	auipc	ra,0x1
    80003706:	b40080e7          	jalr	-1216(ra) # 80004242 <initlog>
}
    8000370a:	70a2                	ld	ra,40(sp)
    8000370c:	7402                	ld	s0,32(sp)
    8000370e:	64e2                	ld	s1,24(sp)
    80003710:	6942                	ld	s2,16(sp)
    80003712:	69a2                	ld	s3,8(sp)
    80003714:	6145                	addi	sp,sp,48
    80003716:	8082                	ret
    panic("invalid file system");
    80003718:	00005517          	auipc	a0,0x5
    8000371c:	08850513          	addi	a0,a0,136 # 800087a0 <syscalls+0x180>
    80003720:	ffffd097          	auipc	ra,0xffffd
    80003724:	e24080e7          	jalr	-476(ra) # 80000544 <panic>

0000000080003728 <iinit>:
{
    80003728:	7179                	addi	sp,sp,-48
    8000372a:	f406                	sd	ra,40(sp)
    8000372c:	f022                	sd	s0,32(sp)
    8000372e:	ec26                	sd	s1,24(sp)
    80003730:	e84a                	sd	s2,16(sp)
    80003732:	e44e                	sd	s3,8(sp)
    80003734:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003736:	00005597          	auipc	a1,0x5
    8000373a:	08258593          	addi	a1,a1,130 # 800087b8 <syscalls+0x198>
    8000373e:	00024517          	auipc	a0,0x24
    80003742:	ee250513          	addi	a0,a0,-286 # 80027620 <itable>
    80003746:	ffffd097          	auipc	ra,0xffffd
    8000374a:	414080e7          	jalr	1044(ra) # 80000b5a <initlock>
  for(i = 0; i < NINODE; i++) {
    8000374e:	00024497          	auipc	s1,0x24
    80003752:	efa48493          	addi	s1,s1,-262 # 80027648 <itable+0x28>
    80003756:	00026997          	auipc	s3,0x26
    8000375a:	98298993          	addi	s3,s3,-1662 # 800290d8 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000375e:	00005917          	auipc	s2,0x5
    80003762:	06290913          	addi	s2,s2,98 # 800087c0 <syscalls+0x1a0>
    80003766:	85ca                	mv	a1,s2
    80003768:	8526                	mv	a0,s1
    8000376a:	00001097          	auipc	ra,0x1
    8000376e:	e3a080e7          	jalr	-454(ra) # 800045a4 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003772:	08848493          	addi	s1,s1,136
    80003776:	ff3498e3          	bne	s1,s3,80003766 <iinit+0x3e>
}
    8000377a:	70a2                	ld	ra,40(sp)
    8000377c:	7402                	ld	s0,32(sp)
    8000377e:	64e2                	ld	s1,24(sp)
    80003780:	6942                	ld	s2,16(sp)
    80003782:	69a2                	ld	s3,8(sp)
    80003784:	6145                	addi	sp,sp,48
    80003786:	8082                	ret

0000000080003788 <ialloc>:
{
    80003788:	715d                	addi	sp,sp,-80
    8000378a:	e486                	sd	ra,72(sp)
    8000378c:	e0a2                	sd	s0,64(sp)
    8000378e:	fc26                	sd	s1,56(sp)
    80003790:	f84a                	sd	s2,48(sp)
    80003792:	f44e                	sd	s3,40(sp)
    80003794:	f052                	sd	s4,32(sp)
    80003796:	ec56                	sd	s5,24(sp)
    80003798:	e85a                	sd	s6,16(sp)
    8000379a:	e45e                	sd	s7,8(sp)
    8000379c:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000379e:	00024717          	auipc	a4,0x24
    800037a2:	e6e72703          	lw	a4,-402(a4) # 8002760c <sb+0xc>
    800037a6:	4785                	li	a5,1
    800037a8:	04e7fa63          	bgeu	a5,a4,800037fc <ialloc+0x74>
    800037ac:	8aaa                	mv	s5,a0
    800037ae:	8bae                	mv	s7,a1
    800037b0:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800037b2:	00024a17          	auipc	s4,0x24
    800037b6:	e4ea0a13          	addi	s4,s4,-434 # 80027600 <sb>
    800037ba:	00048b1b          	sext.w	s6,s1
    800037be:	0044d593          	srli	a1,s1,0x4
    800037c2:	018a2783          	lw	a5,24(s4)
    800037c6:	9dbd                	addw	a1,a1,a5
    800037c8:	8556                	mv	a0,s5
    800037ca:	00000097          	auipc	ra,0x0
    800037ce:	940080e7          	jalr	-1728(ra) # 8000310a <bread>
    800037d2:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800037d4:	05850993          	addi	s3,a0,88
    800037d8:	00f4f793          	andi	a5,s1,15
    800037dc:	079a                	slli	a5,a5,0x6
    800037de:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800037e0:	00099783          	lh	a5,0(s3)
    800037e4:	c3a1                	beqz	a5,80003824 <ialloc+0x9c>
    brelse(bp);
    800037e6:	00000097          	auipc	ra,0x0
    800037ea:	a54080e7          	jalr	-1452(ra) # 8000323a <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800037ee:	0485                	addi	s1,s1,1
    800037f0:	00ca2703          	lw	a4,12(s4)
    800037f4:	0004879b          	sext.w	a5,s1
    800037f8:	fce7e1e3          	bltu	a5,a4,800037ba <ialloc+0x32>
  printf("ialloc: no inodes\n");
    800037fc:	00005517          	auipc	a0,0x5
    80003800:	fcc50513          	addi	a0,a0,-52 # 800087c8 <syscalls+0x1a8>
    80003804:	ffffd097          	auipc	ra,0xffffd
    80003808:	d8a080e7          	jalr	-630(ra) # 8000058e <printf>
  return 0;
    8000380c:	4501                	li	a0,0
}
    8000380e:	60a6                	ld	ra,72(sp)
    80003810:	6406                	ld	s0,64(sp)
    80003812:	74e2                	ld	s1,56(sp)
    80003814:	7942                	ld	s2,48(sp)
    80003816:	79a2                	ld	s3,40(sp)
    80003818:	7a02                	ld	s4,32(sp)
    8000381a:	6ae2                	ld	s5,24(sp)
    8000381c:	6b42                	ld	s6,16(sp)
    8000381e:	6ba2                	ld	s7,8(sp)
    80003820:	6161                	addi	sp,sp,80
    80003822:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003824:	04000613          	li	a2,64
    80003828:	4581                	li	a1,0
    8000382a:	854e                	mv	a0,s3
    8000382c:	ffffd097          	auipc	ra,0xffffd
    80003830:	4ba080e7          	jalr	1210(ra) # 80000ce6 <memset>
      dip->type = type;
    80003834:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003838:	854a                	mv	a0,s2
    8000383a:	00001097          	auipc	ra,0x1
    8000383e:	c84080e7          	jalr	-892(ra) # 800044be <log_write>
      brelse(bp);
    80003842:	854a                	mv	a0,s2
    80003844:	00000097          	auipc	ra,0x0
    80003848:	9f6080e7          	jalr	-1546(ra) # 8000323a <brelse>
      return iget(dev, inum);
    8000384c:	85da                	mv	a1,s6
    8000384e:	8556                	mv	a0,s5
    80003850:	00000097          	auipc	ra,0x0
    80003854:	d9c080e7          	jalr	-612(ra) # 800035ec <iget>
    80003858:	bf5d                	j	8000380e <ialloc+0x86>

000000008000385a <iupdate>:
{
    8000385a:	1101                	addi	sp,sp,-32
    8000385c:	ec06                	sd	ra,24(sp)
    8000385e:	e822                	sd	s0,16(sp)
    80003860:	e426                	sd	s1,8(sp)
    80003862:	e04a                	sd	s2,0(sp)
    80003864:	1000                	addi	s0,sp,32
    80003866:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003868:	415c                	lw	a5,4(a0)
    8000386a:	0047d79b          	srliw	a5,a5,0x4
    8000386e:	00024597          	auipc	a1,0x24
    80003872:	daa5a583          	lw	a1,-598(a1) # 80027618 <sb+0x18>
    80003876:	9dbd                	addw	a1,a1,a5
    80003878:	4108                	lw	a0,0(a0)
    8000387a:	00000097          	auipc	ra,0x0
    8000387e:	890080e7          	jalr	-1904(ra) # 8000310a <bread>
    80003882:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003884:	05850793          	addi	a5,a0,88
    80003888:	40c8                	lw	a0,4(s1)
    8000388a:	893d                	andi	a0,a0,15
    8000388c:	051a                	slli	a0,a0,0x6
    8000388e:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003890:	04449703          	lh	a4,68(s1)
    80003894:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003898:	04649703          	lh	a4,70(s1)
    8000389c:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800038a0:	04849703          	lh	a4,72(s1)
    800038a4:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800038a8:	04a49703          	lh	a4,74(s1)
    800038ac:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800038b0:	44f8                	lw	a4,76(s1)
    800038b2:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800038b4:	03400613          	li	a2,52
    800038b8:	05048593          	addi	a1,s1,80
    800038bc:	0531                	addi	a0,a0,12
    800038be:	ffffd097          	auipc	ra,0xffffd
    800038c2:	488080e7          	jalr	1160(ra) # 80000d46 <memmove>
  log_write(bp);
    800038c6:	854a                	mv	a0,s2
    800038c8:	00001097          	auipc	ra,0x1
    800038cc:	bf6080e7          	jalr	-1034(ra) # 800044be <log_write>
  brelse(bp);
    800038d0:	854a                	mv	a0,s2
    800038d2:	00000097          	auipc	ra,0x0
    800038d6:	968080e7          	jalr	-1688(ra) # 8000323a <brelse>
}
    800038da:	60e2                	ld	ra,24(sp)
    800038dc:	6442                	ld	s0,16(sp)
    800038de:	64a2                	ld	s1,8(sp)
    800038e0:	6902                	ld	s2,0(sp)
    800038e2:	6105                	addi	sp,sp,32
    800038e4:	8082                	ret

00000000800038e6 <idup>:
{
    800038e6:	1101                	addi	sp,sp,-32
    800038e8:	ec06                	sd	ra,24(sp)
    800038ea:	e822                	sd	s0,16(sp)
    800038ec:	e426                	sd	s1,8(sp)
    800038ee:	1000                	addi	s0,sp,32
    800038f0:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800038f2:	00024517          	auipc	a0,0x24
    800038f6:	d2e50513          	addi	a0,a0,-722 # 80027620 <itable>
    800038fa:	ffffd097          	auipc	ra,0xffffd
    800038fe:	2f0080e7          	jalr	752(ra) # 80000bea <acquire>
  ip->ref++;
    80003902:	449c                	lw	a5,8(s1)
    80003904:	2785                	addiw	a5,a5,1
    80003906:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003908:	00024517          	auipc	a0,0x24
    8000390c:	d1850513          	addi	a0,a0,-744 # 80027620 <itable>
    80003910:	ffffd097          	auipc	ra,0xffffd
    80003914:	38e080e7          	jalr	910(ra) # 80000c9e <release>
}
    80003918:	8526                	mv	a0,s1
    8000391a:	60e2                	ld	ra,24(sp)
    8000391c:	6442                	ld	s0,16(sp)
    8000391e:	64a2                	ld	s1,8(sp)
    80003920:	6105                	addi	sp,sp,32
    80003922:	8082                	ret

0000000080003924 <ilock>:
{
    80003924:	1101                	addi	sp,sp,-32
    80003926:	ec06                	sd	ra,24(sp)
    80003928:	e822                	sd	s0,16(sp)
    8000392a:	e426                	sd	s1,8(sp)
    8000392c:	e04a                	sd	s2,0(sp)
    8000392e:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003930:	c115                	beqz	a0,80003954 <ilock+0x30>
    80003932:	84aa                	mv	s1,a0
    80003934:	451c                	lw	a5,8(a0)
    80003936:	00f05f63          	blez	a5,80003954 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000393a:	0541                	addi	a0,a0,16
    8000393c:	00001097          	auipc	ra,0x1
    80003940:	ca2080e7          	jalr	-862(ra) # 800045de <acquiresleep>
  if(ip->valid == 0){
    80003944:	40bc                	lw	a5,64(s1)
    80003946:	cf99                	beqz	a5,80003964 <ilock+0x40>
}
    80003948:	60e2                	ld	ra,24(sp)
    8000394a:	6442                	ld	s0,16(sp)
    8000394c:	64a2                	ld	s1,8(sp)
    8000394e:	6902                	ld	s2,0(sp)
    80003950:	6105                	addi	sp,sp,32
    80003952:	8082                	ret
    panic("ilock");
    80003954:	00005517          	auipc	a0,0x5
    80003958:	e8c50513          	addi	a0,a0,-372 # 800087e0 <syscalls+0x1c0>
    8000395c:	ffffd097          	auipc	ra,0xffffd
    80003960:	be8080e7          	jalr	-1048(ra) # 80000544 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003964:	40dc                	lw	a5,4(s1)
    80003966:	0047d79b          	srliw	a5,a5,0x4
    8000396a:	00024597          	auipc	a1,0x24
    8000396e:	cae5a583          	lw	a1,-850(a1) # 80027618 <sb+0x18>
    80003972:	9dbd                	addw	a1,a1,a5
    80003974:	4088                	lw	a0,0(s1)
    80003976:	fffff097          	auipc	ra,0xfffff
    8000397a:	794080e7          	jalr	1940(ra) # 8000310a <bread>
    8000397e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003980:	05850593          	addi	a1,a0,88
    80003984:	40dc                	lw	a5,4(s1)
    80003986:	8bbd                	andi	a5,a5,15
    80003988:	079a                	slli	a5,a5,0x6
    8000398a:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000398c:	00059783          	lh	a5,0(a1)
    80003990:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003994:	00259783          	lh	a5,2(a1)
    80003998:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000399c:	00459783          	lh	a5,4(a1)
    800039a0:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800039a4:	00659783          	lh	a5,6(a1)
    800039a8:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800039ac:	459c                	lw	a5,8(a1)
    800039ae:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800039b0:	03400613          	li	a2,52
    800039b4:	05b1                	addi	a1,a1,12
    800039b6:	05048513          	addi	a0,s1,80
    800039ba:	ffffd097          	auipc	ra,0xffffd
    800039be:	38c080e7          	jalr	908(ra) # 80000d46 <memmove>
    brelse(bp);
    800039c2:	854a                	mv	a0,s2
    800039c4:	00000097          	auipc	ra,0x0
    800039c8:	876080e7          	jalr	-1930(ra) # 8000323a <brelse>
    ip->valid = 1;
    800039cc:	4785                	li	a5,1
    800039ce:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800039d0:	04449783          	lh	a5,68(s1)
    800039d4:	fbb5                	bnez	a5,80003948 <ilock+0x24>
      panic("ilock: no type");
    800039d6:	00005517          	auipc	a0,0x5
    800039da:	e1250513          	addi	a0,a0,-494 # 800087e8 <syscalls+0x1c8>
    800039de:	ffffd097          	auipc	ra,0xffffd
    800039e2:	b66080e7          	jalr	-1178(ra) # 80000544 <panic>

00000000800039e6 <iunlock>:
{
    800039e6:	1101                	addi	sp,sp,-32
    800039e8:	ec06                	sd	ra,24(sp)
    800039ea:	e822                	sd	s0,16(sp)
    800039ec:	e426                	sd	s1,8(sp)
    800039ee:	e04a                	sd	s2,0(sp)
    800039f0:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800039f2:	c905                	beqz	a0,80003a22 <iunlock+0x3c>
    800039f4:	84aa                	mv	s1,a0
    800039f6:	01050913          	addi	s2,a0,16
    800039fa:	854a                	mv	a0,s2
    800039fc:	00001097          	auipc	ra,0x1
    80003a00:	c7c080e7          	jalr	-900(ra) # 80004678 <holdingsleep>
    80003a04:	cd19                	beqz	a0,80003a22 <iunlock+0x3c>
    80003a06:	449c                	lw	a5,8(s1)
    80003a08:	00f05d63          	blez	a5,80003a22 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003a0c:	854a                	mv	a0,s2
    80003a0e:	00001097          	auipc	ra,0x1
    80003a12:	c26080e7          	jalr	-986(ra) # 80004634 <releasesleep>
}
    80003a16:	60e2                	ld	ra,24(sp)
    80003a18:	6442                	ld	s0,16(sp)
    80003a1a:	64a2                	ld	s1,8(sp)
    80003a1c:	6902                	ld	s2,0(sp)
    80003a1e:	6105                	addi	sp,sp,32
    80003a20:	8082                	ret
    panic("iunlock");
    80003a22:	00005517          	auipc	a0,0x5
    80003a26:	dd650513          	addi	a0,a0,-554 # 800087f8 <syscalls+0x1d8>
    80003a2a:	ffffd097          	auipc	ra,0xffffd
    80003a2e:	b1a080e7          	jalr	-1254(ra) # 80000544 <panic>

0000000080003a32 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003a32:	7179                	addi	sp,sp,-48
    80003a34:	f406                	sd	ra,40(sp)
    80003a36:	f022                	sd	s0,32(sp)
    80003a38:	ec26                	sd	s1,24(sp)
    80003a3a:	e84a                	sd	s2,16(sp)
    80003a3c:	e44e                	sd	s3,8(sp)
    80003a3e:	e052                	sd	s4,0(sp)
    80003a40:	1800                	addi	s0,sp,48
    80003a42:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003a44:	05050493          	addi	s1,a0,80
    80003a48:	08050913          	addi	s2,a0,128
    80003a4c:	a021                	j	80003a54 <itrunc+0x22>
    80003a4e:	0491                	addi	s1,s1,4
    80003a50:	01248d63          	beq	s1,s2,80003a6a <itrunc+0x38>
    if(ip->addrs[i]){
    80003a54:	408c                	lw	a1,0(s1)
    80003a56:	dde5                	beqz	a1,80003a4e <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003a58:	0009a503          	lw	a0,0(s3)
    80003a5c:	00000097          	auipc	ra,0x0
    80003a60:	8f4080e7          	jalr	-1804(ra) # 80003350 <bfree>
      ip->addrs[i] = 0;
    80003a64:	0004a023          	sw	zero,0(s1)
    80003a68:	b7dd                	j	80003a4e <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003a6a:	0809a583          	lw	a1,128(s3)
    80003a6e:	e185                	bnez	a1,80003a8e <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003a70:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003a74:	854e                	mv	a0,s3
    80003a76:	00000097          	auipc	ra,0x0
    80003a7a:	de4080e7          	jalr	-540(ra) # 8000385a <iupdate>
}
    80003a7e:	70a2                	ld	ra,40(sp)
    80003a80:	7402                	ld	s0,32(sp)
    80003a82:	64e2                	ld	s1,24(sp)
    80003a84:	6942                	ld	s2,16(sp)
    80003a86:	69a2                	ld	s3,8(sp)
    80003a88:	6a02                	ld	s4,0(sp)
    80003a8a:	6145                	addi	sp,sp,48
    80003a8c:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003a8e:	0009a503          	lw	a0,0(s3)
    80003a92:	fffff097          	auipc	ra,0xfffff
    80003a96:	678080e7          	jalr	1656(ra) # 8000310a <bread>
    80003a9a:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003a9c:	05850493          	addi	s1,a0,88
    80003aa0:	45850913          	addi	s2,a0,1112
    80003aa4:	a811                	j	80003ab8 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003aa6:	0009a503          	lw	a0,0(s3)
    80003aaa:	00000097          	auipc	ra,0x0
    80003aae:	8a6080e7          	jalr	-1882(ra) # 80003350 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003ab2:	0491                	addi	s1,s1,4
    80003ab4:	01248563          	beq	s1,s2,80003abe <itrunc+0x8c>
      if(a[j])
    80003ab8:	408c                	lw	a1,0(s1)
    80003aba:	dde5                	beqz	a1,80003ab2 <itrunc+0x80>
    80003abc:	b7ed                	j	80003aa6 <itrunc+0x74>
    brelse(bp);
    80003abe:	8552                	mv	a0,s4
    80003ac0:	fffff097          	auipc	ra,0xfffff
    80003ac4:	77a080e7          	jalr	1914(ra) # 8000323a <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003ac8:	0809a583          	lw	a1,128(s3)
    80003acc:	0009a503          	lw	a0,0(s3)
    80003ad0:	00000097          	auipc	ra,0x0
    80003ad4:	880080e7          	jalr	-1920(ra) # 80003350 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003ad8:	0809a023          	sw	zero,128(s3)
    80003adc:	bf51                	j	80003a70 <itrunc+0x3e>

0000000080003ade <iput>:
{
    80003ade:	1101                	addi	sp,sp,-32
    80003ae0:	ec06                	sd	ra,24(sp)
    80003ae2:	e822                	sd	s0,16(sp)
    80003ae4:	e426                	sd	s1,8(sp)
    80003ae6:	e04a                	sd	s2,0(sp)
    80003ae8:	1000                	addi	s0,sp,32
    80003aea:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003aec:	00024517          	auipc	a0,0x24
    80003af0:	b3450513          	addi	a0,a0,-1228 # 80027620 <itable>
    80003af4:	ffffd097          	auipc	ra,0xffffd
    80003af8:	0f6080e7          	jalr	246(ra) # 80000bea <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003afc:	4498                	lw	a4,8(s1)
    80003afe:	4785                	li	a5,1
    80003b00:	02f70363          	beq	a4,a5,80003b26 <iput+0x48>
  ip->ref--;
    80003b04:	449c                	lw	a5,8(s1)
    80003b06:	37fd                	addiw	a5,a5,-1
    80003b08:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003b0a:	00024517          	auipc	a0,0x24
    80003b0e:	b1650513          	addi	a0,a0,-1258 # 80027620 <itable>
    80003b12:	ffffd097          	auipc	ra,0xffffd
    80003b16:	18c080e7          	jalr	396(ra) # 80000c9e <release>
}
    80003b1a:	60e2                	ld	ra,24(sp)
    80003b1c:	6442                	ld	s0,16(sp)
    80003b1e:	64a2                	ld	s1,8(sp)
    80003b20:	6902                	ld	s2,0(sp)
    80003b22:	6105                	addi	sp,sp,32
    80003b24:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b26:	40bc                	lw	a5,64(s1)
    80003b28:	dff1                	beqz	a5,80003b04 <iput+0x26>
    80003b2a:	04a49783          	lh	a5,74(s1)
    80003b2e:	fbf9                	bnez	a5,80003b04 <iput+0x26>
    acquiresleep(&ip->lock);
    80003b30:	01048913          	addi	s2,s1,16
    80003b34:	854a                	mv	a0,s2
    80003b36:	00001097          	auipc	ra,0x1
    80003b3a:	aa8080e7          	jalr	-1368(ra) # 800045de <acquiresleep>
    release(&itable.lock);
    80003b3e:	00024517          	auipc	a0,0x24
    80003b42:	ae250513          	addi	a0,a0,-1310 # 80027620 <itable>
    80003b46:	ffffd097          	auipc	ra,0xffffd
    80003b4a:	158080e7          	jalr	344(ra) # 80000c9e <release>
    itrunc(ip);
    80003b4e:	8526                	mv	a0,s1
    80003b50:	00000097          	auipc	ra,0x0
    80003b54:	ee2080e7          	jalr	-286(ra) # 80003a32 <itrunc>
    ip->type = 0;
    80003b58:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003b5c:	8526                	mv	a0,s1
    80003b5e:	00000097          	auipc	ra,0x0
    80003b62:	cfc080e7          	jalr	-772(ra) # 8000385a <iupdate>
    ip->valid = 0;
    80003b66:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003b6a:	854a                	mv	a0,s2
    80003b6c:	00001097          	auipc	ra,0x1
    80003b70:	ac8080e7          	jalr	-1336(ra) # 80004634 <releasesleep>
    acquire(&itable.lock);
    80003b74:	00024517          	auipc	a0,0x24
    80003b78:	aac50513          	addi	a0,a0,-1364 # 80027620 <itable>
    80003b7c:	ffffd097          	auipc	ra,0xffffd
    80003b80:	06e080e7          	jalr	110(ra) # 80000bea <acquire>
    80003b84:	b741                	j	80003b04 <iput+0x26>

0000000080003b86 <iunlockput>:
{
    80003b86:	1101                	addi	sp,sp,-32
    80003b88:	ec06                	sd	ra,24(sp)
    80003b8a:	e822                	sd	s0,16(sp)
    80003b8c:	e426                	sd	s1,8(sp)
    80003b8e:	1000                	addi	s0,sp,32
    80003b90:	84aa                	mv	s1,a0
  iunlock(ip);
    80003b92:	00000097          	auipc	ra,0x0
    80003b96:	e54080e7          	jalr	-428(ra) # 800039e6 <iunlock>
  iput(ip);
    80003b9a:	8526                	mv	a0,s1
    80003b9c:	00000097          	auipc	ra,0x0
    80003ba0:	f42080e7          	jalr	-190(ra) # 80003ade <iput>
}
    80003ba4:	60e2                	ld	ra,24(sp)
    80003ba6:	6442                	ld	s0,16(sp)
    80003ba8:	64a2                	ld	s1,8(sp)
    80003baa:	6105                	addi	sp,sp,32
    80003bac:	8082                	ret

0000000080003bae <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003bae:	1141                	addi	sp,sp,-16
    80003bb0:	e422                	sd	s0,8(sp)
    80003bb2:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003bb4:	411c                	lw	a5,0(a0)
    80003bb6:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003bb8:	415c                	lw	a5,4(a0)
    80003bba:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003bbc:	04451783          	lh	a5,68(a0)
    80003bc0:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003bc4:	04a51783          	lh	a5,74(a0)
    80003bc8:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003bcc:	04c56783          	lwu	a5,76(a0)
    80003bd0:	e99c                	sd	a5,16(a1)
}
    80003bd2:	6422                	ld	s0,8(sp)
    80003bd4:	0141                	addi	sp,sp,16
    80003bd6:	8082                	ret

0000000080003bd8 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003bd8:	457c                	lw	a5,76(a0)
    80003bda:	0ed7e963          	bltu	a5,a3,80003ccc <readi+0xf4>
{
    80003bde:	7159                	addi	sp,sp,-112
    80003be0:	f486                	sd	ra,104(sp)
    80003be2:	f0a2                	sd	s0,96(sp)
    80003be4:	eca6                	sd	s1,88(sp)
    80003be6:	e8ca                	sd	s2,80(sp)
    80003be8:	e4ce                	sd	s3,72(sp)
    80003bea:	e0d2                	sd	s4,64(sp)
    80003bec:	fc56                	sd	s5,56(sp)
    80003bee:	f85a                	sd	s6,48(sp)
    80003bf0:	f45e                	sd	s7,40(sp)
    80003bf2:	f062                	sd	s8,32(sp)
    80003bf4:	ec66                	sd	s9,24(sp)
    80003bf6:	e86a                	sd	s10,16(sp)
    80003bf8:	e46e                	sd	s11,8(sp)
    80003bfa:	1880                	addi	s0,sp,112
    80003bfc:	8b2a                	mv	s6,a0
    80003bfe:	8bae                	mv	s7,a1
    80003c00:	8a32                	mv	s4,a2
    80003c02:	84b6                	mv	s1,a3
    80003c04:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003c06:	9f35                	addw	a4,a4,a3
    return 0;
    80003c08:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003c0a:	0ad76063          	bltu	a4,a3,80003caa <readi+0xd2>
  if(off + n > ip->size)
    80003c0e:	00e7f463          	bgeu	a5,a4,80003c16 <readi+0x3e>
    n = ip->size - off;
    80003c12:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c16:	0a0a8963          	beqz	s5,80003cc8 <readi+0xf0>
    80003c1a:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c1c:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003c20:	5c7d                	li	s8,-1
    80003c22:	a82d                	j	80003c5c <readi+0x84>
    80003c24:	020d1d93          	slli	s11,s10,0x20
    80003c28:	020ddd93          	srli	s11,s11,0x20
    80003c2c:	05890613          	addi	a2,s2,88
    80003c30:	86ee                	mv	a3,s11
    80003c32:	963a                	add	a2,a2,a4
    80003c34:	85d2                	mv	a1,s4
    80003c36:	855e                	mv	a0,s7
    80003c38:	fffff097          	auipc	ra,0xfffff
    80003c3c:	8da080e7          	jalr	-1830(ra) # 80002512 <either_copyout>
    80003c40:	05850d63          	beq	a0,s8,80003c9a <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003c44:	854a                	mv	a0,s2
    80003c46:	fffff097          	auipc	ra,0xfffff
    80003c4a:	5f4080e7          	jalr	1524(ra) # 8000323a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c4e:	013d09bb          	addw	s3,s10,s3
    80003c52:	009d04bb          	addw	s1,s10,s1
    80003c56:	9a6e                	add	s4,s4,s11
    80003c58:	0559f763          	bgeu	s3,s5,80003ca6 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003c5c:	00a4d59b          	srliw	a1,s1,0xa
    80003c60:	855a                	mv	a0,s6
    80003c62:	00000097          	auipc	ra,0x0
    80003c66:	8a2080e7          	jalr	-1886(ra) # 80003504 <bmap>
    80003c6a:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003c6e:	cd85                	beqz	a1,80003ca6 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003c70:	000b2503          	lw	a0,0(s6)
    80003c74:	fffff097          	auipc	ra,0xfffff
    80003c78:	496080e7          	jalr	1174(ra) # 8000310a <bread>
    80003c7c:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c7e:	3ff4f713          	andi	a4,s1,1023
    80003c82:	40ec87bb          	subw	a5,s9,a4
    80003c86:	413a86bb          	subw	a3,s5,s3
    80003c8a:	8d3e                	mv	s10,a5
    80003c8c:	2781                	sext.w	a5,a5
    80003c8e:	0006861b          	sext.w	a2,a3
    80003c92:	f8f679e3          	bgeu	a2,a5,80003c24 <readi+0x4c>
    80003c96:	8d36                	mv	s10,a3
    80003c98:	b771                	j	80003c24 <readi+0x4c>
      brelse(bp);
    80003c9a:	854a                	mv	a0,s2
    80003c9c:	fffff097          	auipc	ra,0xfffff
    80003ca0:	59e080e7          	jalr	1438(ra) # 8000323a <brelse>
      tot = -1;
    80003ca4:	59fd                	li	s3,-1
  }
  return tot;
    80003ca6:	0009851b          	sext.w	a0,s3
}
    80003caa:	70a6                	ld	ra,104(sp)
    80003cac:	7406                	ld	s0,96(sp)
    80003cae:	64e6                	ld	s1,88(sp)
    80003cb0:	6946                	ld	s2,80(sp)
    80003cb2:	69a6                	ld	s3,72(sp)
    80003cb4:	6a06                	ld	s4,64(sp)
    80003cb6:	7ae2                	ld	s5,56(sp)
    80003cb8:	7b42                	ld	s6,48(sp)
    80003cba:	7ba2                	ld	s7,40(sp)
    80003cbc:	7c02                	ld	s8,32(sp)
    80003cbe:	6ce2                	ld	s9,24(sp)
    80003cc0:	6d42                	ld	s10,16(sp)
    80003cc2:	6da2                	ld	s11,8(sp)
    80003cc4:	6165                	addi	sp,sp,112
    80003cc6:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003cc8:	89d6                	mv	s3,s5
    80003cca:	bff1                	j	80003ca6 <readi+0xce>
    return 0;
    80003ccc:	4501                	li	a0,0
}
    80003cce:	8082                	ret

0000000080003cd0 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003cd0:	457c                	lw	a5,76(a0)
    80003cd2:	10d7e863          	bltu	a5,a3,80003de2 <writei+0x112>
{
    80003cd6:	7159                	addi	sp,sp,-112
    80003cd8:	f486                	sd	ra,104(sp)
    80003cda:	f0a2                	sd	s0,96(sp)
    80003cdc:	eca6                	sd	s1,88(sp)
    80003cde:	e8ca                	sd	s2,80(sp)
    80003ce0:	e4ce                	sd	s3,72(sp)
    80003ce2:	e0d2                	sd	s4,64(sp)
    80003ce4:	fc56                	sd	s5,56(sp)
    80003ce6:	f85a                	sd	s6,48(sp)
    80003ce8:	f45e                	sd	s7,40(sp)
    80003cea:	f062                	sd	s8,32(sp)
    80003cec:	ec66                	sd	s9,24(sp)
    80003cee:	e86a                	sd	s10,16(sp)
    80003cf0:	e46e                	sd	s11,8(sp)
    80003cf2:	1880                	addi	s0,sp,112
    80003cf4:	8aaa                	mv	s5,a0
    80003cf6:	8bae                	mv	s7,a1
    80003cf8:	8a32                	mv	s4,a2
    80003cfa:	8936                	mv	s2,a3
    80003cfc:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003cfe:	00e687bb          	addw	a5,a3,a4
    80003d02:	0ed7e263          	bltu	a5,a3,80003de6 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003d06:	00043737          	lui	a4,0x43
    80003d0a:	0ef76063          	bltu	a4,a5,80003dea <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d0e:	0c0b0863          	beqz	s6,80003dde <writei+0x10e>
    80003d12:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d14:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003d18:	5c7d                	li	s8,-1
    80003d1a:	a091                	j	80003d5e <writei+0x8e>
    80003d1c:	020d1d93          	slli	s11,s10,0x20
    80003d20:	020ddd93          	srli	s11,s11,0x20
    80003d24:	05848513          	addi	a0,s1,88
    80003d28:	86ee                	mv	a3,s11
    80003d2a:	8652                	mv	a2,s4
    80003d2c:	85de                	mv	a1,s7
    80003d2e:	953a                	add	a0,a0,a4
    80003d30:	fffff097          	auipc	ra,0xfffff
    80003d34:	838080e7          	jalr	-1992(ra) # 80002568 <either_copyin>
    80003d38:	07850263          	beq	a0,s8,80003d9c <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003d3c:	8526                	mv	a0,s1
    80003d3e:	00000097          	auipc	ra,0x0
    80003d42:	780080e7          	jalr	1920(ra) # 800044be <log_write>
    brelse(bp);
    80003d46:	8526                	mv	a0,s1
    80003d48:	fffff097          	auipc	ra,0xfffff
    80003d4c:	4f2080e7          	jalr	1266(ra) # 8000323a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d50:	013d09bb          	addw	s3,s10,s3
    80003d54:	012d093b          	addw	s2,s10,s2
    80003d58:	9a6e                	add	s4,s4,s11
    80003d5a:	0569f663          	bgeu	s3,s6,80003da6 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003d5e:	00a9559b          	srliw	a1,s2,0xa
    80003d62:	8556                	mv	a0,s5
    80003d64:	fffff097          	auipc	ra,0xfffff
    80003d68:	7a0080e7          	jalr	1952(ra) # 80003504 <bmap>
    80003d6c:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003d70:	c99d                	beqz	a1,80003da6 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003d72:	000aa503          	lw	a0,0(s5)
    80003d76:	fffff097          	auipc	ra,0xfffff
    80003d7a:	394080e7          	jalr	916(ra) # 8000310a <bread>
    80003d7e:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d80:	3ff97713          	andi	a4,s2,1023
    80003d84:	40ec87bb          	subw	a5,s9,a4
    80003d88:	413b06bb          	subw	a3,s6,s3
    80003d8c:	8d3e                	mv	s10,a5
    80003d8e:	2781                	sext.w	a5,a5
    80003d90:	0006861b          	sext.w	a2,a3
    80003d94:	f8f674e3          	bgeu	a2,a5,80003d1c <writei+0x4c>
    80003d98:	8d36                	mv	s10,a3
    80003d9a:	b749                	j	80003d1c <writei+0x4c>
      brelse(bp);
    80003d9c:	8526                	mv	a0,s1
    80003d9e:	fffff097          	auipc	ra,0xfffff
    80003da2:	49c080e7          	jalr	1180(ra) # 8000323a <brelse>
  }

  if(off > ip->size)
    80003da6:	04caa783          	lw	a5,76(s5)
    80003daa:	0127f463          	bgeu	a5,s2,80003db2 <writei+0xe2>
    ip->size = off;
    80003dae:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003db2:	8556                	mv	a0,s5
    80003db4:	00000097          	auipc	ra,0x0
    80003db8:	aa6080e7          	jalr	-1370(ra) # 8000385a <iupdate>

  return tot;
    80003dbc:	0009851b          	sext.w	a0,s3
}
    80003dc0:	70a6                	ld	ra,104(sp)
    80003dc2:	7406                	ld	s0,96(sp)
    80003dc4:	64e6                	ld	s1,88(sp)
    80003dc6:	6946                	ld	s2,80(sp)
    80003dc8:	69a6                	ld	s3,72(sp)
    80003dca:	6a06                	ld	s4,64(sp)
    80003dcc:	7ae2                	ld	s5,56(sp)
    80003dce:	7b42                	ld	s6,48(sp)
    80003dd0:	7ba2                	ld	s7,40(sp)
    80003dd2:	7c02                	ld	s8,32(sp)
    80003dd4:	6ce2                	ld	s9,24(sp)
    80003dd6:	6d42                	ld	s10,16(sp)
    80003dd8:	6da2                	ld	s11,8(sp)
    80003dda:	6165                	addi	sp,sp,112
    80003ddc:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003dde:	89da                	mv	s3,s6
    80003de0:	bfc9                	j	80003db2 <writei+0xe2>
    return -1;
    80003de2:	557d                	li	a0,-1
}
    80003de4:	8082                	ret
    return -1;
    80003de6:	557d                	li	a0,-1
    80003de8:	bfe1                	j	80003dc0 <writei+0xf0>
    return -1;
    80003dea:	557d                	li	a0,-1
    80003dec:	bfd1                	j	80003dc0 <writei+0xf0>

0000000080003dee <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003dee:	1141                	addi	sp,sp,-16
    80003df0:	e406                	sd	ra,8(sp)
    80003df2:	e022                	sd	s0,0(sp)
    80003df4:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003df6:	4639                	li	a2,14
    80003df8:	ffffd097          	auipc	ra,0xffffd
    80003dfc:	fc6080e7          	jalr	-58(ra) # 80000dbe <strncmp>
}
    80003e00:	60a2                	ld	ra,8(sp)
    80003e02:	6402                	ld	s0,0(sp)
    80003e04:	0141                	addi	sp,sp,16
    80003e06:	8082                	ret

0000000080003e08 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003e08:	7139                	addi	sp,sp,-64
    80003e0a:	fc06                	sd	ra,56(sp)
    80003e0c:	f822                	sd	s0,48(sp)
    80003e0e:	f426                	sd	s1,40(sp)
    80003e10:	f04a                	sd	s2,32(sp)
    80003e12:	ec4e                	sd	s3,24(sp)
    80003e14:	e852                	sd	s4,16(sp)
    80003e16:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003e18:	04451703          	lh	a4,68(a0)
    80003e1c:	4785                	li	a5,1
    80003e1e:	00f71a63          	bne	a4,a5,80003e32 <dirlookup+0x2a>
    80003e22:	892a                	mv	s2,a0
    80003e24:	89ae                	mv	s3,a1
    80003e26:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e28:	457c                	lw	a5,76(a0)
    80003e2a:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003e2c:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e2e:	e79d                	bnez	a5,80003e5c <dirlookup+0x54>
    80003e30:	a8a5                	j	80003ea8 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003e32:	00005517          	auipc	a0,0x5
    80003e36:	9ce50513          	addi	a0,a0,-1586 # 80008800 <syscalls+0x1e0>
    80003e3a:	ffffc097          	auipc	ra,0xffffc
    80003e3e:	70a080e7          	jalr	1802(ra) # 80000544 <panic>
      panic("dirlookup read");
    80003e42:	00005517          	auipc	a0,0x5
    80003e46:	9d650513          	addi	a0,a0,-1578 # 80008818 <syscalls+0x1f8>
    80003e4a:	ffffc097          	auipc	ra,0xffffc
    80003e4e:	6fa080e7          	jalr	1786(ra) # 80000544 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e52:	24c1                	addiw	s1,s1,16
    80003e54:	04c92783          	lw	a5,76(s2)
    80003e58:	04f4f763          	bgeu	s1,a5,80003ea6 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e5c:	4741                	li	a4,16
    80003e5e:	86a6                	mv	a3,s1
    80003e60:	fc040613          	addi	a2,s0,-64
    80003e64:	4581                	li	a1,0
    80003e66:	854a                	mv	a0,s2
    80003e68:	00000097          	auipc	ra,0x0
    80003e6c:	d70080e7          	jalr	-656(ra) # 80003bd8 <readi>
    80003e70:	47c1                	li	a5,16
    80003e72:	fcf518e3          	bne	a0,a5,80003e42 <dirlookup+0x3a>
    if(de.inum == 0)
    80003e76:	fc045783          	lhu	a5,-64(s0)
    80003e7a:	dfe1                	beqz	a5,80003e52 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003e7c:	fc240593          	addi	a1,s0,-62
    80003e80:	854e                	mv	a0,s3
    80003e82:	00000097          	auipc	ra,0x0
    80003e86:	f6c080e7          	jalr	-148(ra) # 80003dee <namecmp>
    80003e8a:	f561                	bnez	a0,80003e52 <dirlookup+0x4a>
      if(poff)
    80003e8c:	000a0463          	beqz	s4,80003e94 <dirlookup+0x8c>
        *poff = off;
    80003e90:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003e94:	fc045583          	lhu	a1,-64(s0)
    80003e98:	00092503          	lw	a0,0(s2)
    80003e9c:	fffff097          	auipc	ra,0xfffff
    80003ea0:	750080e7          	jalr	1872(ra) # 800035ec <iget>
    80003ea4:	a011                	j	80003ea8 <dirlookup+0xa0>
  return 0;
    80003ea6:	4501                	li	a0,0
}
    80003ea8:	70e2                	ld	ra,56(sp)
    80003eaa:	7442                	ld	s0,48(sp)
    80003eac:	74a2                	ld	s1,40(sp)
    80003eae:	7902                	ld	s2,32(sp)
    80003eb0:	69e2                	ld	s3,24(sp)
    80003eb2:	6a42                	ld	s4,16(sp)
    80003eb4:	6121                	addi	sp,sp,64
    80003eb6:	8082                	ret

0000000080003eb8 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003eb8:	711d                	addi	sp,sp,-96
    80003eba:	ec86                	sd	ra,88(sp)
    80003ebc:	e8a2                	sd	s0,80(sp)
    80003ebe:	e4a6                	sd	s1,72(sp)
    80003ec0:	e0ca                	sd	s2,64(sp)
    80003ec2:	fc4e                	sd	s3,56(sp)
    80003ec4:	f852                	sd	s4,48(sp)
    80003ec6:	f456                	sd	s5,40(sp)
    80003ec8:	f05a                	sd	s6,32(sp)
    80003eca:	ec5e                	sd	s7,24(sp)
    80003ecc:	e862                	sd	s8,16(sp)
    80003ece:	e466                	sd	s9,8(sp)
    80003ed0:	1080                	addi	s0,sp,96
    80003ed2:	84aa                	mv	s1,a0
    80003ed4:	8b2e                	mv	s6,a1
    80003ed6:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003ed8:	00054703          	lbu	a4,0(a0)
    80003edc:	02f00793          	li	a5,47
    80003ee0:	02f70363          	beq	a4,a5,80003f06 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003ee4:	ffffe097          	auipc	ra,0xffffe
    80003ee8:	ae2080e7          	jalr	-1310(ra) # 800019c6 <myproc>
    80003eec:	15053503          	ld	a0,336(a0)
    80003ef0:	00000097          	auipc	ra,0x0
    80003ef4:	9f6080e7          	jalr	-1546(ra) # 800038e6 <idup>
    80003ef8:	89aa                	mv	s3,a0
  while(*path == '/')
    80003efa:	02f00913          	li	s2,47
  len = path - s;
    80003efe:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003f00:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003f02:	4c05                	li	s8,1
    80003f04:	a865                	j	80003fbc <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003f06:	4585                	li	a1,1
    80003f08:	4505                	li	a0,1
    80003f0a:	fffff097          	auipc	ra,0xfffff
    80003f0e:	6e2080e7          	jalr	1762(ra) # 800035ec <iget>
    80003f12:	89aa                	mv	s3,a0
    80003f14:	b7dd                	j	80003efa <namex+0x42>
      iunlockput(ip);
    80003f16:	854e                	mv	a0,s3
    80003f18:	00000097          	auipc	ra,0x0
    80003f1c:	c6e080e7          	jalr	-914(ra) # 80003b86 <iunlockput>
      return 0;
    80003f20:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003f22:	854e                	mv	a0,s3
    80003f24:	60e6                	ld	ra,88(sp)
    80003f26:	6446                	ld	s0,80(sp)
    80003f28:	64a6                	ld	s1,72(sp)
    80003f2a:	6906                	ld	s2,64(sp)
    80003f2c:	79e2                	ld	s3,56(sp)
    80003f2e:	7a42                	ld	s4,48(sp)
    80003f30:	7aa2                	ld	s5,40(sp)
    80003f32:	7b02                	ld	s6,32(sp)
    80003f34:	6be2                	ld	s7,24(sp)
    80003f36:	6c42                	ld	s8,16(sp)
    80003f38:	6ca2                	ld	s9,8(sp)
    80003f3a:	6125                	addi	sp,sp,96
    80003f3c:	8082                	ret
      iunlock(ip);
    80003f3e:	854e                	mv	a0,s3
    80003f40:	00000097          	auipc	ra,0x0
    80003f44:	aa6080e7          	jalr	-1370(ra) # 800039e6 <iunlock>
      return ip;
    80003f48:	bfe9                	j	80003f22 <namex+0x6a>
      iunlockput(ip);
    80003f4a:	854e                	mv	a0,s3
    80003f4c:	00000097          	auipc	ra,0x0
    80003f50:	c3a080e7          	jalr	-966(ra) # 80003b86 <iunlockput>
      return 0;
    80003f54:	89d2                	mv	s3,s4
    80003f56:	b7f1                	j	80003f22 <namex+0x6a>
  len = path - s;
    80003f58:	40b48633          	sub	a2,s1,a1
    80003f5c:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003f60:	094cd463          	bge	s9,s4,80003fe8 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003f64:	4639                	li	a2,14
    80003f66:	8556                	mv	a0,s5
    80003f68:	ffffd097          	auipc	ra,0xffffd
    80003f6c:	dde080e7          	jalr	-546(ra) # 80000d46 <memmove>
  while(*path == '/')
    80003f70:	0004c783          	lbu	a5,0(s1)
    80003f74:	01279763          	bne	a5,s2,80003f82 <namex+0xca>
    path++;
    80003f78:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f7a:	0004c783          	lbu	a5,0(s1)
    80003f7e:	ff278de3          	beq	a5,s2,80003f78 <namex+0xc0>
    ilock(ip);
    80003f82:	854e                	mv	a0,s3
    80003f84:	00000097          	auipc	ra,0x0
    80003f88:	9a0080e7          	jalr	-1632(ra) # 80003924 <ilock>
    if(ip->type != T_DIR){
    80003f8c:	04499783          	lh	a5,68(s3)
    80003f90:	f98793e3          	bne	a5,s8,80003f16 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003f94:	000b0563          	beqz	s6,80003f9e <namex+0xe6>
    80003f98:	0004c783          	lbu	a5,0(s1)
    80003f9c:	d3cd                	beqz	a5,80003f3e <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003f9e:	865e                	mv	a2,s7
    80003fa0:	85d6                	mv	a1,s5
    80003fa2:	854e                	mv	a0,s3
    80003fa4:	00000097          	auipc	ra,0x0
    80003fa8:	e64080e7          	jalr	-412(ra) # 80003e08 <dirlookup>
    80003fac:	8a2a                	mv	s4,a0
    80003fae:	dd51                	beqz	a0,80003f4a <namex+0x92>
    iunlockput(ip);
    80003fb0:	854e                	mv	a0,s3
    80003fb2:	00000097          	auipc	ra,0x0
    80003fb6:	bd4080e7          	jalr	-1068(ra) # 80003b86 <iunlockput>
    ip = next;
    80003fba:	89d2                	mv	s3,s4
  while(*path == '/')
    80003fbc:	0004c783          	lbu	a5,0(s1)
    80003fc0:	05279763          	bne	a5,s2,8000400e <namex+0x156>
    path++;
    80003fc4:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003fc6:	0004c783          	lbu	a5,0(s1)
    80003fca:	ff278de3          	beq	a5,s2,80003fc4 <namex+0x10c>
  if(*path == 0)
    80003fce:	c79d                	beqz	a5,80003ffc <namex+0x144>
    path++;
    80003fd0:	85a6                	mv	a1,s1
  len = path - s;
    80003fd2:	8a5e                	mv	s4,s7
    80003fd4:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003fd6:	01278963          	beq	a5,s2,80003fe8 <namex+0x130>
    80003fda:	dfbd                	beqz	a5,80003f58 <namex+0xa0>
    path++;
    80003fdc:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003fde:	0004c783          	lbu	a5,0(s1)
    80003fe2:	ff279ce3          	bne	a5,s2,80003fda <namex+0x122>
    80003fe6:	bf8d                	j	80003f58 <namex+0xa0>
    memmove(name, s, len);
    80003fe8:	2601                	sext.w	a2,a2
    80003fea:	8556                	mv	a0,s5
    80003fec:	ffffd097          	auipc	ra,0xffffd
    80003ff0:	d5a080e7          	jalr	-678(ra) # 80000d46 <memmove>
    name[len] = 0;
    80003ff4:	9a56                	add	s4,s4,s5
    80003ff6:	000a0023          	sb	zero,0(s4)
    80003ffa:	bf9d                	j	80003f70 <namex+0xb8>
  if(nameiparent){
    80003ffc:	f20b03e3          	beqz	s6,80003f22 <namex+0x6a>
    iput(ip);
    80004000:	854e                	mv	a0,s3
    80004002:	00000097          	auipc	ra,0x0
    80004006:	adc080e7          	jalr	-1316(ra) # 80003ade <iput>
    return 0;
    8000400a:	4981                	li	s3,0
    8000400c:	bf19                	j	80003f22 <namex+0x6a>
  if(*path == 0)
    8000400e:	d7fd                	beqz	a5,80003ffc <namex+0x144>
  while(*path != '/' && *path != 0)
    80004010:	0004c783          	lbu	a5,0(s1)
    80004014:	85a6                	mv	a1,s1
    80004016:	b7d1                	j	80003fda <namex+0x122>

0000000080004018 <dirlink>:
{
    80004018:	7139                	addi	sp,sp,-64
    8000401a:	fc06                	sd	ra,56(sp)
    8000401c:	f822                	sd	s0,48(sp)
    8000401e:	f426                	sd	s1,40(sp)
    80004020:	f04a                	sd	s2,32(sp)
    80004022:	ec4e                	sd	s3,24(sp)
    80004024:	e852                	sd	s4,16(sp)
    80004026:	0080                	addi	s0,sp,64
    80004028:	892a                	mv	s2,a0
    8000402a:	8a2e                	mv	s4,a1
    8000402c:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000402e:	4601                	li	a2,0
    80004030:	00000097          	auipc	ra,0x0
    80004034:	dd8080e7          	jalr	-552(ra) # 80003e08 <dirlookup>
    80004038:	e93d                	bnez	a0,800040ae <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000403a:	04c92483          	lw	s1,76(s2)
    8000403e:	c49d                	beqz	s1,8000406c <dirlink+0x54>
    80004040:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004042:	4741                	li	a4,16
    80004044:	86a6                	mv	a3,s1
    80004046:	fc040613          	addi	a2,s0,-64
    8000404a:	4581                	li	a1,0
    8000404c:	854a                	mv	a0,s2
    8000404e:	00000097          	auipc	ra,0x0
    80004052:	b8a080e7          	jalr	-1142(ra) # 80003bd8 <readi>
    80004056:	47c1                	li	a5,16
    80004058:	06f51163          	bne	a0,a5,800040ba <dirlink+0xa2>
    if(de.inum == 0)
    8000405c:	fc045783          	lhu	a5,-64(s0)
    80004060:	c791                	beqz	a5,8000406c <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004062:	24c1                	addiw	s1,s1,16
    80004064:	04c92783          	lw	a5,76(s2)
    80004068:	fcf4ede3          	bltu	s1,a5,80004042 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000406c:	4639                	li	a2,14
    8000406e:	85d2                	mv	a1,s4
    80004070:	fc240513          	addi	a0,s0,-62
    80004074:	ffffd097          	auipc	ra,0xffffd
    80004078:	d86080e7          	jalr	-634(ra) # 80000dfa <strncpy>
  de.inum = inum;
    8000407c:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004080:	4741                	li	a4,16
    80004082:	86a6                	mv	a3,s1
    80004084:	fc040613          	addi	a2,s0,-64
    80004088:	4581                	li	a1,0
    8000408a:	854a                	mv	a0,s2
    8000408c:	00000097          	auipc	ra,0x0
    80004090:	c44080e7          	jalr	-956(ra) # 80003cd0 <writei>
    80004094:	1541                	addi	a0,a0,-16
    80004096:	00a03533          	snez	a0,a0
    8000409a:	40a00533          	neg	a0,a0
}
    8000409e:	70e2                	ld	ra,56(sp)
    800040a0:	7442                	ld	s0,48(sp)
    800040a2:	74a2                	ld	s1,40(sp)
    800040a4:	7902                	ld	s2,32(sp)
    800040a6:	69e2                	ld	s3,24(sp)
    800040a8:	6a42                	ld	s4,16(sp)
    800040aa:	6121                	addi	sp,sp,64
    800040ac:	8082                	ret
    iput(ip);
    800040ae:	00000097          	auipc	ra,0x0
    800040b2:	a30080e7          	jalr	-1488(ra) # 80003ade <iput>
    return -1;
    800040b6:	557d                	li	a0,-1
    800040b8:	b7dd                	j	8000409e <dirlink+0x86>
      panic("dirlink read");
    800040ba:	00004517          	auipc	a0,0x4
    800040be:	76e50513          	addi	a0,a0,1902 # 80008828 <syscalls+0x208>
    800040c2:	ffffc097          	auipc	ra,0xffffc
    800040c6:	482080e7          	jalr	1154(ra) # 80000544 <panic>

00000000800040ca <namei>:

struct inode*
namei(char *path)
{
    800040ca:	1101                	addi	sp,sp,-32
    800040cc:	ec06                	sd	ra,24(sp)
    800040ce:	e822                	sd	s0,16(sp)
    800040d0:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800040d2:	fe040613          	addi	a2,s0,-32
    800040d6:	4581                	li	a1,0
    800040d8:	00000097          	auipc	ra,0x0
    800040dc:	de0080e7          	jalr	-544(ra) # 80003eb8 <namex>
}
    800040e0:	60e2                	ld	ra,24(sp)
    800040e2:	6442                	ld	s0,16(sp)
    800040e4:	6105                	addi	sp,sp,32
    800040e6:	8082                	ret

00000000800040e8 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800040e8:	1141                	addi	sp,sp,-16
    800040ea:	e406                	sd	ra,8(sp)
    800040ec:	e022                	sd	s0,0(sp)
    800040ee:	0800                	addi	s0,sp,16
    800040f0:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800040f2:	4585                	li	a1,1
    800040f4:	00000097          	auipc	ra,0x0
    800040f8:	dc4080e7          	jalr	-572(ra) # 80003eb8 <namex>
}
    800040fc:	60a2                	ld	ra,8(sp)
    800040fe:	6402                	ld	s0,0(sp)
    80004100:	0141                	addi	sp,sp,16
    80004102:	8082                	ret

0000000080004104 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004104:	1101                	addi	sp,sp,-32
    80004106:	ec06                	sd	ra,24(sp)
    80004108:	e822                	sd	s0,16(sp)
    8000410a:	e426                	sd	s1,8(sp)
    8000410c:	e04a                	sd	s2,0(sp)
    8000410e:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004110:	00025917          	auipc	s2,0x25
    80004114:	fb890913          	addi	s2,s2,-72 # 800290c8 <log>
    80004118:	01892583          	lw	a1,24(s2)
    8000411c:	02892503          	lw	a0,40(s2)
    80004120:	fffff097          	auipc	ra,0xfffff
    80004124:	fea080e7          	jalr	-22(ra) # 8000310a <bread>
    80004128:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000412a:	02c92683          	lw	a3,44(s2)
    8000412e:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004130:	02d05763          	blez	a3,8000415e <write_head+0x5a>
    80004134:	00025797          	auipc	a5,0x25
    80004138:	fc478793          	addi	a5,a5,-60 # 800290f8 <log+0x30>
    8000413c:	05c50713          	addi	a4,a0,92
    80004140:	36fd                	addiw	a3,a3,-1
    80004142:	1682                	slli	a3,a3,0x20
    80004144:	9281                	srli	a3,a3,0x20
    80004146:	068a                	slli	a3,a3,0x2
    80004148:	00025617          	auipc	a2,0x25
    8000414c:	fb460613          	addi	a2,a2,-76 # 800290fc <log+0x34>
    80004150:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004152:	4390                	lw	a2,0(a5)
    80004154:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004156:	0791                	addi	a5,a5,4
    80004158:	0711                	addi	a4,a4,4
    8000415a:	fed79ce3          	bne	a5,a3,80004152 <write_head+0x4e>
  }
  bwrite(buf);
    8000415e:	8526                	mv	a0,s1
    80004160:	fffff097          	auipc	ra,0xfffff
    80004164:	09c080e7          	jalr	156(ra) # 800031fc <bwrite>
  brelse(buf);
    80004168:	8526                	mv	a0,s1
    8000416a:	fffff097          	auipc	ra,0xfffff
    8000416e:	0d0080e7          	jalr	208(ra) # 8000323a <brelse>
}
    80004172:	60e2                	ld	ra,24(sp)
    80004174:	6442                	ld	s0,16(sp)
    80004176:	64a2                	ld	s1,8(sp)
    80004178:	6902                	ld	s2,0(sp)
    8000417a:	6105                	addi	sp,sp,32
    8000417c:	8082                	ret

000000008000417e <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000417e:	00025797          	auipc	a5,0x25
    80004182:	f767a783          	lw	a5,-138(a5) # 800290f4 <log+0x2c>
    80004186:	0af05d63          	blez	a5,80004240 <install_trans+0xc2>
{
    8000418a:	7139                	addi	sp,sp,-64
    8000418c:	fc06                	sd	ra,56(sp)
    8000418e:	f822                	sd	s0,48(sp)
    80004190:	f426                	sd	s1,40(sp)
    80004192:	f04a                	sd	s2,32(sp)
    80004194:	ec4e                	sd	s3,24(sp)
    80004196:	e852                	sd	s4,16(sp)
    80004198:	e456                	sd	s5,8(sp)
    8000419a:	e05a                	sd	s6,0(sp)
    8000419c:	0080                	addi	s0,sp,64
    8000419e:	8b2a                	mv	s6,a0
    800041a0:	00025a97          	auipc	s5,0x25
    800041a4:	f58a8a93          	addi	s5,s5,-168 # 800290f8 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041a8:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800041aa:	00025997          	auipc	s3,0x25
    800041ae:	f1e98993          	addi	s3,s3,-226 # 800290c8 <log>
    800041b2:	a035                	j	800041de <install_trans+0x60>
      bunpin(dbuf);
    800041b4:	8526                	mv	a0,s1
    800041b6:	fffff097          	auipc	ra,0xfffff
    800041ba:	15e080e7          	jalr	350(ra) # 80003314 <bunpin>
    brelse(lbuf);
    800041be:	854a                	mv	a0,s2
    800041c0:	fffff097          	auipc	ra,0xfffff
    800041c4:	07a080e7          	jalr	122(ra) # 8000323a <brelse>
    brelse(dbuf);
    800041c8:	8526                	mv	a0,s1
    800041ca:	fffff097          	auipc	ra,0xfffff
    800041ce:	070080e7          	jalr	112(ra) # 8000323a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800041d2:	2a05                	addiw	s4,s4,1
    800041d4:	0a91                	addi	s5,s5,4
    800041d6:	02c9a783          	lw	a5,44(s3)
    800041da:	04fa5963          	bge	s4,a5,8000422c <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800041de:	0189a583          	lw	a1,24(s3)
    800041e2:	014585bb          	addw	a1,a1,s4
    800041e6:	2585                	addiw	a1,a1,1
    800041e8:	0289a503          	lw	a0,40(s3)
    800041ec:	fffff097          	auipc	ra,0xfffff
    800041f0:	f1e080e7          	jalr	-226(ra) # 8000310a <bread>
    800041f4:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800041f6:	000aa583          	lw	a1,0(s5)
    800041fa:	0289a503          	lw	a0,40(s3)
    800041fe:	fffff097          	auipc	ra,0xfffff
    80004202:	f0c080e7          	jalr	-244(ra) # 8000310a <bread>
    80004206:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004208:	40000613          	li	a2,1024
    8000420c:	05890593          	addi	a1,s2,88
    80004210:	05850513          	addi	a0,a0,88
    80004214:	ffffd097          	auipc	ra,0xffffd
    80004218:	b32080e7          	jalr	-1230(ra) # 80000d46 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000421c:	8526                	mv	a0,s1
    8000421e:	fffff097          	auipc	ra,0xfffff
    80004222:	fde080e7          	jalr	-34(ra) # 800031fc <bwrite>
    if(recovering == 0)
    80004226:	f80b1ce3          	bnez	s6,800041be <install_trans+0x40>
    8000422a:	b769                	j	800041b4 <install_trans+0x36>
}
    8000422c:	70e2                	ld	ra,56(sp)
    8000422e:	7442                	ld	s0,48(sp)
    80004230:	74a2                	ld	s1,40(sp)
    80004232:	7902                	ld	s2,32(sp)
    80004234:	69e2                	ld	s3,24(sp)
    80004236:	6a42                	ld	s4,16(sp)
    80004238:	6aa2                	ld	s5,8(sp)
    8000423a:	6b02                	ld	s6,0(sp)
    8000423c:	6121                	addi	sp,sp,64
    8000423e:	8082                	ret
    80004240:	8082                	ret

0000000080004242 <initlog>:
{
    80004242:	7179                	addi	sp,sp,-48
    80004244:	f406                	sd	ra,40(sp)
    80004246:	f022                	sd	s0,32(sp)
    80004248:	ec26                	sd	s1,24(sp)
    8000424a:	e84a                	sd	s2,16(sp)
    8000424c:	e44e                	sd	s3,8(sp)
    8000424e:	1800                	addi	s0,sp,48
    80004250:	892a                	mv	s2,a0
    80004252:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004254:	00025497          	auipc	s1,0x25
    80004258:	e7448493          	addi	s1,s1,-396 # 800290c8 <log>
    8000425c:	00004597          	auipc	a1,0x4
    80004260:	5dc58593          	addi	a1,a1,1500 # 80008838 <syscalls+0x218>
    80004264:	8526                	mv	a0,s1
    80004266:	ffffd097          	auipc	ra,0xffffd
    8000426a:	8f4080e7          	jalr	-1804(ra) # 80000b5a <initlock>
  log.start = sb->logstart;
    8000426e:	0149a583          	lw	a1,20(s3)
    80004272:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004274:	0109a783          	lw	a5,16(s3)
    80004278:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000427a:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000427e:	854a                	mv	a0,s2
    80004280:	fffff097          	auipc	ra,0xfffff
    80004284:	e8a080e7          	jalr	-374(ra) # 8000310a <bread>
  log.lh.n = lh->n;
    80004288:	4d3c                	lw	a5,88(a0)
    8000428a:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000428c:	02f05563          	blez	a5,800042b6 <initlog+0x74>
    80004290:	05c50713          	addi	a4,a0,92
    80004294:	00025697          	auipc	a3,0x25
    80004298:	e6468693          	addi	a3,a3,-412 # 800290f8 <log+0x30>
    8000429c:	37fd                	addiw	a5,a5,-1
    8000429e:	1782                	slli	a5,a5,0x20
    800042a0:	9381                	srli	a5,a5,0x20
    800042a2:	078a                	slli	a5,a5,0x2
    800042a4:	06050613          	addi	a2,a0,96
    800042a8:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800042aa:	4310                	lw	a2,0(a4)
    800042ac:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800042ae:	0711                	addi	a4,a4,4
    800042b0:	0691                	addi	a3,a3,4
    800042b2:	fef71ce3          	bne	a4,a5,800042aa <initlog+0x68>
  brelse(buf);
    800042b6:	fffff097          	auipc	ra,0xfffff
    800042ba:	f84080e7          	jalr	-124(ra) # 8000323a <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800042be:	4505                	li	a0,1
    800042c0:	00000097          	auipc	ra,0x0
    800042c4:	ebe080e7          	jalr	-322(ra) # 8000417e <install_trans>
  log.lh.n = 0;
    800042c8:	00025797          	auipc	a5,0x25
    800042cc:	e207a623          	sw	zero,-468(a5) # 800290f4 <log+0x2c>
  write_head(); // clear the log
    800042d0:	00000097          	auipc	ra,0x0
    800042d4:	e34080e7          	jalr	-460(ra) # 80004104 <write_head>
}
    800042d8:	70a2                	ld	ra,40(sp)
    800042da:	7402                	ld	s0,32(sp)
    800042dc:	64e2                	ld	s1,24(sp)
    800042de:	6942                	ld	s2,16(sp)
    800042e0:	69a2                	ld	s3,8(sp)
    800042e2:	6145                	addi	sp,sp,48
    800042e4:	8082                	ret

00000000800042e6 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800042e6:	1101                	addi	sp,sp,-32
    800042e8:	ec06                	sd	ra,24(sp)
    800042ea:	e822                	sd	s0,16(sp)
    800042ec:	e426                	sd	s1,8(sp)
    800042ee:	e04a                	sd	s2,0(sp)
    800042f0:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800042f2:	00025517          	auipc	a0,0x25
    800042f6:	dd650513          	addi	a0,a0,-554 # 800290c8 <log>
    800042fa:	ffffd097          	auipc	ra,0xffffd
    800042fe:	8f0080e7          	jalr	-1808(ra) # 80000bea <acquire>
  while(1){
    if(log.committing){
    80004302:	00025497          	auipc	s1,0x25
    80004306:	dc648493          	addi	s1,s1,-570 # 800290c8 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000430a:	4979                	li	s2,30
    8000430c:	a039                	j	8000431a <begin_op+0x34>
      sleep(&log, &log.lock);
    8000430e:	85a6                	mv	a1,s1
    80004310:	8526                	mv	a0,s1
    80004312:	ffffe097          	auipc	ra,0xffffe
    80004316:	df8080e7          	jalr	-520(ra) # 8000210a <sleep>
    if(log.committing){
    8000431a:	50dc                	lw	a5,36(s1)
    8000431c:	fbed                	bnez	a5,8000430e <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000431e:	509c                	lw	a5,32(s1)
    80004320:	0017871b          	addiw	a4,a5,1
    80004324:	0007069b          	sext.w	a3,a4
    80004328:	0027179b          	slliw	a5,a4,0x2
    8000432c:	9fb9                	addw	a5,a5,a4
    8000432e:	0017979b          	slliw	a5,a5,0x1
    80004332:	54d8                	lw	a4,44(s1)
    80004334:	9fb9                	addw	a5,a5,a4
    80004336:	00f95963          	bge	s2,a5,80004348 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000433a:	85a6                	mv	a1,s1
    8000433c:	8526                	mv	a0,s1
    8000433e:	ffffe097          	auipc	ra,0xffffe
    80004342:	dcc080e7          	jalr	-564(ra) # 8000210a <sleep>
    80004346:	bfd1                	j	8000431a <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004348:	00025517          	auipc	a0,0x25
    8000434c:	d8050513          	addi	a0,a0,-640 # 800290c8 <log>
    80004350:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004352:	ffffd097          	auipc	ra,0xffffd
    80004356:	94c080e7          	jalr	-1716(ra) # 80000c9e <release>
      break;
    }
  }
}
    8000435a:	60e2                	ld	ra,24(sp)
    8000435c:	6442                	ld	s0,16(sp)
    8000435e:	64a2                	ld	s1,8(sp)
    80004360:	6902                	ld	s2,0(sp)
    80004362:	6105                	addi	sp,sp,32
    80004364:	8082                	ret

0000000080004366 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004366:	7139                	addi	sp,sp,-64
    80004368:	fc06                	sd	ra,56(sp)
    8000436a:	f822                	sd	s0,48(sp)
    8000436c:	f426                	sd	s1,40(sp)
    8000436e:	f04a                	sd	s2,32(sp)
    80004370:	ec4e                	sd	s3,24(sp)
    80004372:	e852                	sd	s4,16(sp)
    80004374:	e456                	sd	s5,8(sp)
    80004376:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004378:	00025497          	auipc	s1,0x25
    8000437c:	d5048493          	addi	s1,s1,-688 # 800290c8 <log>
    80004380:	8526                	mv	a0,s1
    80004382:	ffffd097          	auipc	ra,0xffffd
    80004386:	868080e7          	jalr	-1944(ra) # 80000bea <acquire>
  log.outstanding -= 1;
    8000438a:	509c                	lw	a5,32(s1)
    8000438c:	37fd                	addiw	a5,a5,-1
    8000438e:	0007891b          	sext.w	s2,a5
    80004392:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004394:	50dc                	lw	a5,36(s1)
    80004396:	efb9                	bnez	a5,800043f4 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004398:	06091663          	bnez	s2,80004404 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    8000439c:	00025497          	auipc	s1,0x25
    800043a0:	d2c48493          	addi	s1,s1,-724 # 800290c8 <log>
    800043a4:	4785                	li	a5,1
    800043a6:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800043a8:	8526                	mv	a0,s1
    800043aa:	ffffd097          	auipc	ra,0xffffd
    800043ae:	8f4080e7          	jalr	-1804(ra) # 80000c9e <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800043b2:	54dc                	lw	a5,44(s1)
    800043b4:	06f04763          	bgtz	a5,80004422 <end_op+0xbc>
    acquire(&log.lock);
    800043b8:	00025497          	auipc	s1,0x25
    800043bc:	d1048493          	addi	s1,s1,-752 # 800290c8 <log>
    800043c0:	8526                	mv	a0,s1
    800043c2:	ffffd097          	auipc	ra,0xffffd
    800043c6:	828080e7          	jalr	-2008(ra) # 80000bea <acquire>
    log.committing = 0;
    800043ca:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800043ce:	8526                	mv	a0,s1
    800043d0:	ffffe097          	auipc	ra,0xffffe
    800043d4:	d9e080e7          	jalr	-610(ra) # 8000216e <wakeup>
    release(&log.lock);
    800043d8:	8526                	mv	a0,s1
    800043da:	ffffd097          	auipc	ra,0xffffd
    800043de:	8c4080e7          	jalr	-1852(ra) # 80000c9e <release>
}
    800043e2:	70e2                	ld	ra,56(sp)
    800043e4:	7442                	ld	s0,48(sp)
    800043e6:	74a2                	ld	s1,40(sp)
    800043e8:	7902                	ld	s2,32(sp)
    800043ea:	69e2                	ld	s3,24(sp)
    800043ec:	6a42                	ld	s4,16(sp)
    800043ee:	6aa2                	ld	s5,8(sp)
    800043f0:	6121                	addi	sp,sp,64
    800043f2:	8082                	ret
    panic("log.committing");
    800043f4:	00004517          	auipc	a0,0x4
    800043f8:	44c50513          	addi	a0,a0,1100 # 80008840 <syscalls+0x220>
    800043fc:	ffffc097          	auipc	ra,0xffffc
    80004400:	148080e7          	jalr	328(ra) # 80000544 <panic>
    wakeup(&log);
    80004404:	00025497          	auipc	s1,0x25
    80004408:	cc448493          	addi	s1,s1,-828 # 800290c8 <log>
    8000440c:	8526                	mv	a0,s1
    8000440e:	ffffe097          	auipc	ra,0xffffe
    80004412:	d60080e7          	jalr	-672(ra) # 8000216e <wakeup>
  release(&log.lock);
    80004416:	8526                	mv	a0,s1
    80004418:	ffffd097          	auipc	ra,0xffffd
    8000441c:	886080e7          	jalr	-1914(ra) # 80000c9e <release>
  if(do_commit){
    80004420:	b7c9                	j	800043e2 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004422:	00025a97          	auipc	s5,0x25
    80004426:	cd6a8a93          	addi	s5,s5,-810 # 800290f8 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000442a:	00025a17          	auipc	s4,0x25
    8000442e:	c9ea0a13          	addi	s4,s4,-866 # 800290c8 <log>
    80004432:	018a2583          	lw	a1,24(s4)
    80004436:	012585bb          	addw	a1,a1,s2
    8000443a:	2585                	addiw	a1,a1,1
    8000443c:	028a2503          	lw	a0,40(s4)
    80004440:	fffff097          	auipc	ra,0xfffff
    80004444:	cca080e7          	jalr	-822(ra) # 8000310a <bread>
    80004448:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000444a:	000aa583          	lw	a1,0(s5)
    8000444e:	028a2503          	lw	a0,40(s4)
    80004452:	fffff097          	auipc	ra,0xfffff
    80004456:	cb8080e7          	jalr	-840(ra) # 8000310a <bread>
    8000445a:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000445c:	40000613          	li	a2,1024
    80004460:	05850593          	addi	a1,a0,88
    80004464:	05848513          	addi	a0,s1,88
    80004468:	ffffd097          	auipc	ra,0xffffd
    8000446c:	8de080e7          	jalr	-1826(ra) # 80000d46 <memmove>
    bwrite(to);  // write the log
    80004470:	8526                	mv	a0,s1
    80004472:	fffff097          	auipc	ra,0xfffff
    80004476:	d8a080e7          	jalr	-630(ra) # 800031fc <bwrite>
    brelse(from);
    8000447a:	854e                	mv	a0,s3
    8000447c:	fffff097          	auipc	ra,0xfffff
    80004480:	dbe080e7          	jalr	-578(ra) # 8000323a <brelse>
    brelse(to);
    80004484:	8526                	mv	a0,s1
    80004486:	fffff097          	auipc	ra,0xfffff
    8000448a:	db4080e7          	jalr	-588(ra) # 8000323a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000448e:	2905                	addiw	s2,s2,1
    80004490:	0a91                	addi	s5,s5,4
    80004492:	02ca2783          	lw	a5,44(s4)
    80004496:	f8f94ee3          	blt	s2,a5,80004432 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000449a:	00000097          	auipc	ra,0x0
    8000449e:	c6a080e7          	jalr	-918(ra) # 80004104 <write_head>
    install_trans(0); // Now install writes to home locations
    800044a2:	4501                	li	a0,0
    800044a4:	00000097          	auipc	ra,0x0
    800044a8:	cda080e7          	jalr	-806(ra) # 8000417e <install_trans>
    log.lh.n = 0;
    800044ac:	00025797          	auipc	a5,0x25
    800044b0:	c407a423          	sw	zero,-952(a5) # 800290f4 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800044b4:	00000097          	auipc	ra,0x0
    800044b8:	c50080e7          	jalr	-944(ra) # 80004104 <write_head>
    800044bc:	bdf5                	j	800043b8 <end_op+0x52>

00000000800044be <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800044be:	1101                	addi	sp,sp,-32
    800044c0:	ec06                	sd	ra,24(sp)
    800044c2:	e822                	sd	s0,16(sp)
    800044c4:	e426                	sd	s1,8(sp)
    800044c6:	e04a                	sd	s2,0(sp)
    800044c8:	1000                	addi	s0,sp,32
    800044ca:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800044cc:	00025917          	auipc	s2,0x25
    800044d0:	bfc90913          	addi	s2,s2,-1028 # 800290c8 <log>
    800044d4:	854a                	mv	a0,s2
    800044d6:	ffffc097          	auipc	ra,0xffffc
    800044da:	714080e7          	jalr	1812(ra) # 80000bea <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800044de:	02c92603          	lw	a2,44(s2)
    800044e2:	47f5                	li	a5,29
    800044e4:	06c7c563          	blt	a5,a2,8000454e <log_write+0x90>
    800044e8:	00025797          	auipc	a5,0x25
    800044ec:	bfc7a783          	lw	a5,-1028(a5) # 800290e4 <log+0x1c>
    800044f0:	37fd                	addiw	a5,a5,-1
    800044f2:	04f65e63          	bge	a2,a5,8000454e <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800044f6:	00025797          	auipc	a5,0x25
    800044fa:	bf27a783          	lw	a5,-1038(a5) # 800290e8 <log+0x20>
    800044fe:	06f05063          	blez	a5,8000455e <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004502:	4781                	li	a5,0
    80004504:	06c05563          	blez	a2,8000456e <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004508:	44cc                	lw	a1,12(s1)
    8000450a:	00025717          	auipc	a4,0x25
    8000450e:	bee70713          	addi	a4,a4,-1042 # 800290f8 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004512:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004514:	4314                	lw	a3,0(a4)
    80004516:	04b68c63          	beq	a3,a1,8000456e <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000451a:	2785                	addiw	a5,a5,1
    8000451c:	0711                	addi	a4,a4,4
    8000451e:	fef61be3          	bne	a2,a5,80004514 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004522:	0621                	addi	a2,a2,8
    80004524:	060a                	slli	a2,a2,0x2
    80004526:	00025797          	auipc	a5,0x25
    8000452a:	ba278793          	addi	a5,a5,-1118 # 800290c8 <log>
    8000452e:	963e                	add	a2,a2,a5
    80004530:	44dc                	lw	a5,12(s1)
    80004532:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004534:	8526                	mv	a0,s1
    80004536:	fffff097          	auipc	ra,0xfffff
    8000453a:	da2080e7          	jalr	-606(ra) # 800032d8 <bpin>
    log.lh.n++;
    8000453e:	00025717          	auipc	a4,0x25
    80004542:	b8a70713          	addi	a4,a4,-1142 # 800290c8 <log>
    80004546:	575c                	lw	a5,44(a4)
    80004548:	2785                	addiw	a5,a5,1
    8000454a:	d75c                	sw	a5,44(a4)
    8000454c:	a835                	j	80004588 <log_write+0xca>
    panic("too big a transaction");
    8000454e:	00004517          	auipc	a0,0x4
    80004552:	30250513          	addi	a0,a0,770 # 80008850 <syscalls+0x230>
    80004556:	ffffc097          	auipc	ra,0xffffc
    8000455a:	fee080e7          	jalr	-18(ra) # 80000544 <panic>
    panic("log_write outside of trans");
    8000455e:	00004517          	auipc	a0,0x4
    80004562:	30a50513          	addi	a0,a0,778 # 80008868 <syscalls+0x248>
    80004566:	ffffc097          	auipc	ra,0xffffc
    8000456a:	fde080e7          	jalr	-34(ra) # 80000544 <panic>
  log.lh.block[i] = b->blockno;
    8000456e:	00878713          	addi	a4,a5,8
    80004572:	00271693          	slli	a3,a4,0x2
    80004576:	00025717          	auipc	a4,0x25
    8000457a:	b5270713          	addi	a4,a4,-1198 # 800290c8 <log>
    8000457e:	9736                	add	a4,a4,a3
    80004580:	44d4                	lw	a3,12(s1)
    80004582:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004584:	faf608e3          	beq	a2,a5,80004534 <log_write+0x76>
  }
  release(&log.lock);
    80004588:	00025517          	auipc	a0,0x25
    8000458c:	b4050513          	addi	a0,a0,-1216 # 800290c8 <log>
    80004590:	ffffc097          	auipc	ra,0xffffc
    80004594:	70e080e7          	jalr	1806(ra) # 80000c9e <release>
}
    80004598:	60e2                	ld	ra,24(sp)
    8000459a:	6442                	ld	s0,16(sp)
    8000459c:	64a2                	ld	s1,8(sp)
    8000459e:	6902                	ld	s2,0(sp)
    800045a0:	6105                	addi	sp,sp,32
    800045a2:	8082                	ret

00000000800045a4 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800045a4:	1101                	addi	sp,sp,-32
    800045a6:	ec06                	sd	ra,24(sp)
    800045a8:	e822                	sd	s0,16(sp)
    800045aa:	e426                	sd	s1,8(sp)
    800045ac:	e04a                	sd	s2,0(sp)
    800045ae:	1000                	addi	s0,sp,32
    800045b0:	84aa                	mv	s1,a0
    800045b2:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800045b4:	00004597          	auipc	a1,0x4
    800045b8:	2d458593          	addi	a1,a1,724 # 80008888 <syscalls+0x268>
    800045bc:	0521                	addi	a0,a0,8
    800045be:	ffffc097          	auipc	ra,0xffffc
    800045c2:	59c080e7          	jalr	1436(ra) # 80000b5a <initlock>
  lk->name = name;
    800045c6:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800045ca:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800045ce:	0204a423          	sw	zero,40(s1)
}
    800045d2:	60e2                	ld	ra,24(sp)
    800045d4:	6442                	ld	s0,16(sp)
    800045d6:	64a2                	ld	s1,8(sp)
    800045d8:	6902                	ld	s2,0(sp)
    800045da:	6105                	addi	sp,sp,32
    800045dc:	8082                	ret

00000000800045de <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800045de:	1101                	addi	sp,sp,-32
    800045e0:	ec06                	sd	ra,24(sp)
    800045e2:	e822                	sd	s0,16(sp)
    800045e4:	e426                	sd	s1,8(sp)
    800045e6:	e04a                	sd	s2,0(sp)
    800045e8:	1000                	addi	s0,sp,32
    800045ea:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045ec:	00850913          	addi	s2,a0,8
    800045f0:	854a                	mv	a0,s2
    800045f2:	ffffc097          	auipc	ra,0xffffc
    800045f6:	5f8080e7          	jalr	1528(ra) # 80000bea <acquire>
  while (lk->locked) {
    800045fa:	409c                	lw	a5,0(s1)
    800045fc:	cb89                	beqz	a5,8000460e <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800045fe:	85ca                	mv	a1,s2
    80004600:	8526                	mv	a0,s1
    80004602:	ffffe097          	auipc	ra,0xffffe
    80004606:	b08080e7          	jalr	-1272(ra) # 8000210a <sleep>
  while (lk->locked) {
    8000460a:	409c                	lw	a5,0(s1)
    8000460c:	fbed                	bnez	a5,800045fe <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000460e:	4785                	li	a5,1
    80004610:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004612:	ffffd097          	auipc	ra,0xffffd
    80004616:	3b4080e7          	jalr	948(ra) # 800019c6 <myproc>
    8000461a:	591c                	lw	a5,48(a0)
    8000461c:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000461e:	854a                	mv	a0,s2
    80004620:	ffffc097          	auipc	ra,0xffffc
    80004624:	67e080e7          	jalr	1662(ra) # 80000c9e <release>
}
    80004628:	60e2                	ld	ra,24(sp)
    8000462a:	6442                	ld	s0,16(sp)
    8000462c:	64a2                	ld	s1,8(sp)
    8000462e:	6902                	ld	s2,0(sp)
    80004630:	6105                	addi	sp,sp,32
    80004632:	8082                	ret

0000000080004634 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004634:	1101                	addi	sp,sp,-32
    80004636:	ec06                	sd	ra,24(sp)
    80004638:	e822                	sd	s0,16(sp)
    8000463a:	e426                	sd	s1,8(sp)
    8000463c:	e04a                	sd	s2,0(sp)
    8000463e:	1000                	addi	s0,sp,32
    80004640:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004642:	00850913          	addi	s2,a0,8
    80004646:	854a                	mv	a0,s2
    80004648:	ffffc097          	auipc	ra,0xffffc
    8000464c:	5a2080e7          	jalr	1442(ra) # 80000bea <acquire>
  lk->locked = 0;
    80004650:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004654:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004658:	8526                	mv	a0,s1
    8000465a:	ffffe097          	auipc	ra,0xffffe
    8000465e:	b14080e7          	jalr	-1260(ra) # 8000216e <wakeup>
  release(&lk->lk);
    80004662:	854a                	mv	a0,s2
    80004664:	ffffc097          	auipc	ra,0xffffc
    80004668:	63a080e7          	jalr	1594(ra) # 80000c9e <release>
}
    8000466c:	60e2                	ld	ra,24(sp)
    8000466e:	6442                	ld	s0,16(sp)
    80004670:	64a2                	ld	s1,8(sp)
    80004672:	6902                	ld	s2,0(sp)
    80004674:	6105                	addi	sp,sp,32
    80004676:	8082                	ret

0000000080004678 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004678:	7179                	addi	sp,sp,-48
    8000467a:	f406                	sd	ra,40(sp)
    8000467c:	f022                	sd	s0,32(sp)
    8000467e:	ec26                	sd	s1,24(sp)
    80004680:	e84a                	sd	s2,16(sp)
    80004682:	e44e                	sd	s3,8(sp)
    80004684:	1800                	addi	s0,sp,48
    80004686:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004688:	00850913          	addi	s2,a0,8
    8000468c:	854a                	mv	a0,s2
    8000468e:	ffffc097          	auipc	ra,0xffffc
    80004692:	55c080e7          	jalr	1372(ra) # 80000bea <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004696:	409c                	lw	a5,0(s1)
    80004698:	ef99                	bnez	a5,800046b6 <holdingsleep+0x3e>
    8000469a:	4481                	li	s1,0
  release(&lk->lk);
    8000469c:	854a                	mv	a0,s2
    8000469e:	ffffc097          	auipc	ra,0xffffc
    800046a2:	600080e7          	jalr	1536(ra) # 80000c9e <release>
  return r;
}
    800046a6:	8526                	mv	a0,s1
    800046a8:	70a2                	ld	ra,40(sp)
    800046aa:	7402                	ld	s0,32(sp)
    800046ac:	64e2                	ld	s1,24(sp)
    800046ae:	6942                	ld	s2,16(sp)
    800046b0:	69a2                	ld	s3,8(sp)
    800046b2:	6145                	addi	sp,sp,48
    800046b4:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800046b6:	0284a983          	lw	s3,40(s1)
    800046ba:	ffffd097          	auipc	ra,0xffffd
    800046be:	30c080e7          	jalr	780(ra) # 800019c6 <myproc>
    800046c2:	5904                	lw	s1,48(a0)
    800046c4:	413484b3          	sub	s1,s1,s3
    800046c8:	0014b493          	seqz	s1,s1
    800046cc:	bfc1                	j	8000469c <holdingsleep+0x24>

00000000800046ce <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800046ce:	1141                	addi	sp,sp,-16
    800046d0:	e406                	sd	ra,8(sp)
    800046d2:	e022                	sd	s0,0(sp)
    800046d4:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800046d6:	00004597          	auipc	a1,0x4
    800046da:	1c258593          	addi	a1,a1,450 # 80008898 <syscalls+0x278>
    800046de:	00025517          	auipc	a0,0x25
    800046e2:	b3250513          	addi	a0,a0,-1230 # 80029210 <ftable>
    800046e6:	ffffc097          	auipc	ra,0xffffc
    800046ea:	474080e7          	jalr	1140(ra) # 80000b5a <initlock>
}
    800046ee:	60a2                	ld	ra,8(sp)
    800046f0:	6402                	ld	s0,0(sp)
    800046f2:	0141                	addi	sp,sp,16
    800046f4:	8082                	ret

00000000800046f6 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800046f6:	1101                	addi	sp,sp,-32
    800046f8:	ec06                	sd	ra,24(sp)
    800046fa:	e822                	sd	s0,16(sp)
    800046fc:	e426                	sd	s1,8(sp)
    800046fe:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004700:	00025517          	auipc	a0,0x25
    80004704:	b1050513          	addi	a0,a0,-1264 # 80029210 <ftable>
    80004708:	ffffc097          	auipc	ra,0xffffc
    8000470c:	4e2080e7          	jalr	1250(ra) # 80000bea <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004710:	00025497          	auipc	s1,0x25
    80004714:	b1848493          	addi	s1,s1,-1256 # 80029228 <ftable+0x18>
    80004718:	00026717          	auipc	a4,0x26
    8000471c:	ab070713          	addi	a4,a4,-1360 # 8002a1c8 <disk>
    if(f->ref == 0){
    80004720:	40dc                	lw	a5,4(s1)
    80004722:	cf99                	beqz	a5,80004740 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004724:	02848493          	addi	s1,s1,40
    80004728:	fee49ce3          	bne	s1,a4,80004720 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000472c:	00025517          	auipc	a0,0x25
    80004730:	ae450513          	addi	a0,a0,-1308 # 80029210 <ftable>
    80004734:	ffffc097          	auipc	ra,0xffffc
    80004738:	56a080e7          	jalr	1386(ra) # 80000c9e <release>
  return 0;
    8000473c:	4481                	li	s1,0
    8000473e:	a819                	j	80004754 <filealloc+0x5e>
      f->ref = 1;
    80004740:	4785                	li	a5,1
    80004742:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004744:	00025517          	auipc	a0,0x25
    80004748:	acc50513          	addi	a0,a0,-1332 # 80029210 <ftable>
    8000474c:	ffffc097          	auipc	ra,0xffffc
    80004750:	552080e7          	jalr	1362(ra) # 80000c9e <release>
}
    80004754:	8526                	mv	a0,s1
    80004756:	60e2                	ld	ra,24(sp)
    80004758:	6442                	ld	s0,16(sp)
    8000475a:	64a2                	ld	s1,8(sp)
    8000475c:	6105                	addi	sp,sp,32
    8000475e:	8082                	ret

0000000080004760 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004760:	1101                	addi	sp,sp,-32
    80004762:	ec06                	sd	ra,24(sp)
    80004764:	e822                	sd	s0,16(sp)
    80004766:	e426                	sd	s1,8(sp)
    80004768:	1000                	addi	s0,sp,32
    8000476a:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000476c:	00025517          	auipc	a0,0x25
    80004770:	aa450513          	addi	a0,a0,-1372 # 80029210 <ftable>
    80004774:	ffffc097          	auipc	ra,0xffffc
    80004778:	476080e7          	jalr	1142(ra) # 80000bea <acquire>
  if(f->ref < 1)
    8000477c:	40dc                	lw	a5,4(s1)
    8000477e:	02f05263          	blez	a5,800047a2 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004782:	2785                	addiw	a5,a5,1
    80004784:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004786:	00025517          	auipc	a0,0x25
    8000478a:	a8a50513          	addi	a0,a0,-1398 # 80029210 <ftable>
    8000478e:	ffffc097          	auipc	ra,0xffffc
    80004792:	510080e7          	jalr	1296(ra) # 80000c9e <release>
  return f;
}
    80004796:	8526                	mv	a0,s1
    80004798:	60e2                	ld	ra,24(sp)
    8000479a:	6442                	ld	s0,16(sp)
    8000479c:	64a2                	ld	s1,8(sp)
    8000479e:	6105                	addi	sp,sp,32
    800047a0:	8082                	ret
    panic("filedup");
    800047a2:	00004517          	auipc	a0,0x4
    800047a6:	0fe50513          	addi	a0,a0,254 # 800088a0 <syscalls+0x280>
    800047aa:	ffffc097          	auipc	ra,0xffffc
    800047ae:	d9a080e7          	jalr	-614(ra) # 80000544 <panic>

00000000800047b2 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800047b2:	7139                	addi	sp,sp,-64
    800047b4:	fc06                	sd	ra,56(sp)
    800047b6:	f822                	sd	s0,48(sp)
    800047b8:	f426                	sd	s1,40(sp)
    800047ba:	f04a                	sd	s2,32(sp)
    800047bc:	ec4e                	sd	s3,24(sp)
    800047be:	e852                	sd	s4,16(sp)
    800047c0:	e456                	sd	s5,8(sp)
    800047c2:	0080                	addi	s0,sp,64
    800047c4:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800047c6:	00025517          	auipc	a0,0x25
    800047ca:	a4a50513          	addi	a0,a0,-1462 # 80029210 <ftable>
    800047ce:	ffffc097          	auipc	ra,0xffffc
    800047d2:	41c080e7          	jalr	1052(ra) # 80000bea <acquire>
  if(f->ref < 1)
    800047d6:	40dc                	lw	a5,4(s1)
    800047d8:	06f05163          	blez	a5,8000483a <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800047dc:	37fd                	addiw	a5,a5,-1
    800047de:	0007871b          	sext.w	a4,a5
    800047e2:	c0dc                	sw	a5,4(s1)
    800047e4:	06e04363          	bgtz	a4,8000484a <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800047e8:	0004a903          	lw	s2,0(s1)
    800047ec:	0094ca83          	lbu	s5,9(s1)
    800047f0:	0104ba03          	ld	s4,16(s1)
    800047f4:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800047f8:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800047fc:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004800:	00025517          	auipc	a0,0x25
    80004804:	a1050513          	addi	a0,a0,-1520 # 80029210 <ftable>
    80004808:	ffffc097          	auipc	ra,0xffffc
    8000480c:	496080e7          	jalr	1174(ra) # 80000c9e <release>

  if(ff.type == FD_PIPE){
    80004810:	4785                	li	a5,1
    80004812:	04f90d63          	beq	s2,a5,8000486c <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004816:	3979                	addiw	s2,s2,-2
    80004818:	4785                	li	a5,1
    8000481a:	0527e063          	bltu	a5,s2,8000485a <fileclose+0xa8>
    begin_op();
    8000481e:	00000097          	auipc	ra,0x0
    80004822:	ac8080e7          	jalr	-1336(ra) # 800042e6 <begin_op>
    iput(ff.ip);
    80004826:	854e                	mv	a0,s3
    80004828:	fffff097          	auipc	ra,0xfffff
    8000482c:	2b6080e7          	jalr	694(ra) # 80003ade <iput>
    end_op();
    80004830:	00000097          	auipc	ra,0x0
    80004834:	b36080e7          	jalr	-1226(ra) # 80004366 <end_op>
    80004838:	a00d                	j	8000485a <fileclose+0xa8>
    panic("fileclose");
    8000483a:	00004517          	auipc	a0,0x4
    8000483e:	06e50513          	addi	a0,a0,110 # 800088a8 <syscalls+0x288>
    80004842:	ffffc097          	auipc	ra,0xffffc
    80004846:	d02080e7          	jalr	-766(ra) # 80000544 <panic>
    release(&ftable.lock);
    8000484a:	00025517          	auipc	a0,0x25
    8000484e:	9c650513          	addi	a0,a0,-1594 # 80029210 <ftable>
    80004852:	ffffc097          	auipc	ra,0xffffc
    80004856:	44c080e7          	jalr	1100(ra) # 80000c9e <release>
  }
}
    8000485a:	70e2                	ld	ra,56(sp)
    8000485c:	7442                	ld	s0,48(sp)
    8000485e:	74a2                	ld	s1,40(sp)
    80004860:	7902                	ld	s2,32(sp)
    80004862:	69e2                	ld	s3,24(sp)
    80004864:	6a42                	ld	s4,16(sp)
    80004866:	6aa2                	ld	s5,8(sp)
    80004868:	6121                	addi	sp,sp,64
    8000486a:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000486c:	85d6                	mv	a1,s5
    8000486e:	8552                	mv	a0,s4
    80004870:	00000097          	auipc	ra,0x0
    80004874:	34c080e7          	jalr	844(ra) # 80004bbc <pipeclose>
    80004878:	b7cd                	j	8000485a <fileclose+0xa8>

000000008000487a <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000487a:	715d                	addi	sp,sp,-80
    8000487c:	e486                	sd	ra,72(sp)
    8000487e:	e0a2                	sd	s0,64(sp)
    80004880:	fc26                	sd	s1,56(sp)
    80004882:	f84a                	sd	s2,48(sp)
    80004884:	f44e                	sd	s3,40(sp)
    80004886:	0880                	addi	s0,sp,80
    80004888:	84aa                	mv	s1,a0
    8000488a:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000488c:	ffffd097          	auipc	ra,0xffffd
    80004890:	13a080e7          	jalr	314(ra) # 800019c6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004894:	409c                	lw	a5,0(s1)
    80004896:	37f9                	addiw	a5,a5,-2
    80004898:	4705                	li	a4,1
    8000489a:	04f76763          	bltu	a4,a5,800048e8 <filestat+0x6e>
    8000489e:	892a                	mv	s2,a0
    ilock(f->ip);
    800048a0:	6c88                	ld	a0,24(s1)
    800048a2:	fffff097          	auipc	ra,0xfffff
    800048a6:	082080e7          	jalr	130(ra) # 80003924 <ilock>
    stati(f->ip, &st);
    800048aa:	fb840593          	addi	a1,s0,-72
    800048ae:	6c88                	ld	a0,24(s1)
    800048b0:	fffff097          	auipc	ra,0xfffff
    800048b4:	2fe080e7          	jalr	766(ra) # 80003bae <stati>
    iunlock(f->ip);
    800048b8:	6c88                	ld	a0,24(s1)
    800048ba:	fffff097          	auipc	ra,0xfffff
    800048be:	12c080e7          	jalr	300(ra) # 800039e6 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800048c2:	46e1                	li	a3,24
    800048c4:	fb840613          	addi	a2,s0,-72
    800048c8:	85ce                	mv	a1,s3
    800048ca:	05093503          	ld	a0,80(s2)
    800048ce:	ffffd097          	auipc	ra,0xffffd
    800048d2:	db6080e7          	jalr	-586(ra) # 80001684 <copyout>
    800048d6:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800048da:	60a6                	ld	ra,72(sp)
    800048dc:	6406                	ld	s0,64(sp)
    800048de:	74e2                	ld	s1,56(sp)
    800048e0:	7942                	ld	s2,48(sp)
    800048e2:	79a2                	ld	s3,40(sp)
    800048e4:	6161                	addi	sp,sp,80
    800048e6:	8082                	ret
  return -1;
    800048e8:	557d                	li	a0,-1
    800048ea:	bfc5                	j	800048da <filestat+0x60>

00000000800048ec <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800048ec:	7179                	addi	sp,sp,-48
    800048ee:	f406                	sd	ra,40(sp)
    800048f0:	f022                	sd	s0,32(sp)
    800048f2:	ec26                	sd	s1,24(sp)
    800048f4:	e84a                	sd	s2,16(sp)
    800048f6:	e44e                	sd	s3,8(sp)
    800048f8:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800048fa:	00854783          	lbu	a5,8(a0)
    800048fe:	c3d5                	beqz	a5,800049a2 <fileread+0xb6>
    80004900:	84aa                	mv	s1,a0
    80004902:	89ae                	mv	s3,a1
    80004904:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004906:	411c                	lw	a5,0(a0)
    80004908:	4705                	li	a4,1
    8000490a:	04e78963          	beq	a5,a4,8000495c <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000490e:	470d                	li	a4,3
    80004910:	04e78d63          	beq	a5,a4,8000496a <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004914:	4709                	li	a4,2
    80004916:	06e79e63          	bne	a5,a4,80004992 <fileread+0xa6>
    ilock(f->ip);
    8000491a:	6d08                	ld	a0,24(a0)
    8000491c:	fffff097          	auipc	ra,0xfffff
    80004920:	008080e7          	jalr	8(ra) # 80003924 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004924:	874a                	mv	a4,s2
    80004926:	5094                	lw	a3,32(s1)
    80004928:	864e                	mv	a2,s3
    8000492a:	4585                	li	a1,1
    8000492c:	6c88                	ld	a0,24(s1)
    8000492e:	fffff097          	auipc	ra,0xfffff
    80004932:	2aa080e7          	jalr	682(ra) # 80003bd8 <readi>
    80004936:	892a                	mv	s2,a0
    80004938:	00a05563          	blez	a0,80004942 <fileread+0x56>
      f->off += r;
    8000493c:	509c                	lw	a5,32(s1)
    8000493e:	9fa9                	addw	a5,a5,a0
    80004940:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004942:	6c88                	ld	a0,24(s1)
    80004944:	fffff097          	auipc	ra,0xfffff
    80004948:	0a2080e7          	jalr	162(ra) # 800039e6 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000494c:	854a                	mv	a0,s2
    8000494e:	70a2                	ld	ra,40(sp)
    80004950:	7402                	ld	s0,32(sp)
    80004952:	64e2                	ld	s1,24(sp)
    80004954:	6942                	ld	s2,16(sp)
    80004956:	69a2                	ld	s3,8(sp)
    80004958:	6145                	addi	sp,sp,48
    8000495a:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000495c:	6908                	ld	a0,16(a0)
    8000495e:	00000097          	auipc	ra,0x0
    80004962:	3ce080e7          	jalr	974(ra) # 80004d2c <piperead>
    80004966:	892a                	mv	s2,a0
    80004968:	b7d5                	j	8000494c <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000496a:	02451783          	lh	a5,36(a0)
    8000496e:	03079693          	slli	a3,a5,0x30
    80004972:	92c1                	srli	a3,a3,0x30
    80004974:	4725                	li	a4,9
    80004976:	02d76863          	bltu	a4,a3,800049a6 <fileread+0xba>
    8000497a:	0792                	slli	a5,a5,0x4
    8000497c:	00024717          	auipc	a4,0x24
    80004980:	7f470713          	addi	a4,a4,2036 # 80029170 <devsw>
    80004984:	97ba                	add	a5,a5,a4
    80004986:	639c                	ld	a5,0(a5)
    80004988:	c38d                	beqz	a5,800049aa <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000498a:	4505                	li	a0,1
    8000498c:	9782                	jalr	a5
    8000498e:	892a                	mv	s2,a0
    80004990:	bf75                	j	8000494c <fileread+0x60>
    panic("fileread");
    80004992:	00004517          	auipc	a0,0x4
    80004996:	f2650513          	addi	a0,a0,-218 # 800088b8 <syscalls+0x298>
    8000499a:	ffffc097          	auipc	ra,0xffffc
    8000499e:	baa080e7          	jalr	-1110(ra) # 80000544 <panic>
    return -1;
    800049a2:	597d                	li	s2,-1
    800049a4:	b765                	j	8000494c <fileread+0x60>
      return -1;
    800049a6:	597d                	li	s2,-1
    800049a8:	b755                	j	8000494c <fileread+0x60>
    800049aa:	597d                	li	s2,-1
    800049ac:	b745                	j	8000494c <fileread+0x60>

00000000800049ae <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800049ae:	715d                	addi	sp,sp,-80
    800049b0:	e486                	sd	ra,72(sp)
    800049b2:	e0a2                	sd	s0,64(sp)
    800049b4:	fc26                	sd	s1,56(sp)
    800049b6:	f84a                	sd	s2,48(sp)
    800049b8:	f44e                	sd	s3,40(sp)
    800049ba:	f052                	sd	s4,32(sp)
    800049bc:	ec56                	sd	s5,24(sp)
    800049be:	e85a                	sd	s6,16(sp)
    800049c0:	e45e                	sd	s7,8(sp)
    800049c2:	e062                	sd	s8,0(sp)
    800049c4:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800049c6:	00954783          	lbu	a5,9(a0)
    800049ca:	10078663          	beqz	a5,80004ad6 <filewrite+0x128>
    800049ce:	892a                	mv	s2,a0
    800049d0:	8aae                	mv	s5,a1
    800049d2:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800049d4:	411c                	lw	a5,0(a0)
    800049d6:	4705                	li	a4,1
    800049d8:	02e78263          	beq	a5,a4,800049fc <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800049dc:	470d                	li	a4,3
    800049de:	02e78663          	beq	a5,a4,80004a0a <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800049e2:	4709                	li	a4,2
    800049e4:	0ee79163          	bne	a5,a4,80004ac6 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800049e8:	0ac05d63          	blez	a2,80004aa2 <filewrite+0xf4>
    int i = 0;
    800049ec:	4981                	li	s3,0
    800049ee:	6b05                	lui	s6,0x1
    800049f0:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800049f4:	6b85                	lui	s7,0x1
    800049f6:	c00b8b9b          	addiw	s7,s7,-1024
    800049fa:	a861                	j	80004a92 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800049fc:	6908                	ld	a0,16(a0)
    800049fe:	00000097          	auipc	ra,0x0
    80004a02:	22e080e7          	jalr	558(ra) # 80004c2c <pipewrite>
    80004a06:	8a2a                	mv	s4,a0
    80004a08:	a045                	j	80004aa8 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004a0a:	02451783          	lh	a5,36(a0)
    80004a0e:	03079693          	slli	a3,a5,0x30
    80004a12:	92c1                	srli	a3,a3,0x30
    80004a14:	4725                	li	a4,9
    80004a16:	0cd76263          	bltu	a4,a3,80004ada <filewrite+0x12c>
    80004a1a:	0792                	slli	a5,a5,0x4
    80004a1c:	00024717          	auipc	a4,0x24
    80004a20:	75470713          	addi	a4,a4,1876 # 80029170 <devsw>
    80004a24:	97ba                	add	a5,a5,a4
    80004a26:	679c                	ld	a5,8(a5)
    80004a28:	cbdd                	beqz	a5,80004ade <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004a2a:	4505                	li	a0,1
    80004a2c:	9782                	jalr	a5
    80004a2e:	8a2a                	mv	s4,a0
    80004a30:	a8a5                	j	80004aa8 <filewrite+0xfa>
    80004a32:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004a36:	00000097          	auipc	ra,0x0
    80004a3a:	8b0080e7          	jalr	-1872(ra) # 800042e6 <begin_op>
      ilock(f->ip);
    80004a3e:	01893503          	ld	a0,24(s2)
    80004a42:	fffff097          	auipc	ra,0xfffff
    80004a46:	ee2080e7          	jalr	-286(ra) # 80003924 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004a4a:	8762                	mv	a4,s8
    80004a4c:	02092683          	lw	a3,32(s2)
    80004a50:	01598633          	add	a2,s3,s5
    80004a54:	4585                	li	a1,1
    80004a56:	01893503          	ld	a0,24(s2)
    80004a5a:	fffff097          	auipc	ra,0xfffff
    80004a5e:	276080e7          	jalr	630(ra) # 80003cd0 <writei>
    80004a62:	84aa                	mv	s1,a0
    80004a64:	00a05763          	blez	a0,80004a72 <filewrite+0xc4>
        f->off += r;
    80004a68:	02092783          	lw	a5,32(s2)
    80004a6c:	9fa9                	addw	a5,a5,a0
    80004a6e:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004a72:	01893503          	ld	a0,24(s2)
    80004a76:	fffff097          	auipc	ra,0xfffff
    80004a7a:	f70080e7          	jalr	-144(ra) # 800039e6 <iunlock>
      end_op();
    80004a7e:	00000097          	auipc	ra,0x0
    80004a82:	8e8080e7          	jalr	-1816(ra) # 80004366 <end_op>

      if(r != n1){
    80004a86:	009c1f63          	bne	s8,s1,80004aa4 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004a8a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004a8e:	0149db63          	bge	s3,s4,80004aa4 <filewrite+0xf6>
      int n1 = n - i;
    80004a92:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004a96:	84be                	mv	s1,a5
    80004a98:	2781                	sext.w	a5,a5
    80004a9a:	f8fb5ce3          	bge	s6,a5,80004a32 <filewrite+0x84>
    80004a9e:	84de                	mv	s1,s7
    80004aa0:	bf49                	j	80004a32 <filewrite+0x84>
    int i = 0;
    80004aa2:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004aa4:	013a1f63          	bne	s4,s3,80004ac2 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004aa8:	8552                	mv	a0,s4
    80004aaa:	60a6                	ld	ra,72(sp)
    80004aac:	6406                	ld	s0,64(sp)
    80004aae:	74e2                	ld	s1,56(sp)
    80004ab0:	7942                	ld	s2,48(sp)
    80004ab2:	79a2                	ld	s3,40(sp)
    80004ab4:	7a02                	ld	s4,32(sp)
    80004ab6:	6ae2                	ld	s5,24(sp)
    80004ab8:	6b42                	ld	s6,16(sp)
    80004aba:	6ba2                	ld	s7,8(sp)
    80004abc:	6c02                	ld	s8,0(sp)
    80004abe:	6161                	addi	sp,sp,80
    80004ac0:	8082                	ret
    ret = (i == n ? n : -1);
    80004ac2:	5a7d                	li	s4,-1
    80004ac4:	b7d5                	j	80004aa8 <filewrite+0xfa>
    panic("filewrite");
    80004ac6:	00004517          	auipc	a0,0x4
    80004aca:	e0250513          	addi	a0,a0,-510 # 800088c8 <syscalls+0x2a8>
    80004ace:	ffffc097          	auipc	ra,0xffffc
    80004ad2:	a76080e7          	jalr	-1418(ra) # 80000544 <panic>
    return -1;
    80004ad6:	5a7d                	li	s4,-1
    80004ad8:	bfc1                	j	80004aa8 <filewrite+0xfa>
      return -1;
    80004ada:	5a7d                	li	s4,-1
    80004adc:	b7f1                	j	80004aa8 <filewrite+0xfa>
    80004ade:	5a7d                	li	s4,-1
    80004ae0:	b7e1                	j	80004aa8 <filewrite+0xfa>

0000000080004ae2 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004ae2:	7179                	addi	sp,sp,-48
    80004ae4:	f406                	sd	ra,40(sp)
    80004ae6:	f022                	sd	s0,32(sp)
    80004ae8:	ec26                	sd	s1,24(sp)
    80004aea:	e84a                	sd	s2,16(sp)
    80004aec:	e44e                	sd	s3,8(sp)
    80004aee:	e052                	sd	s4,0(sp)
    80004af0:	1800                	addi	s0,sp,48
    80004af2:	84aa                	mv	s1,a0
    80004af4:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004af6:	0005b023          	sd	zero,0(a1)
    80004afa:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004afe:	00000097          	auipc	ra,0x0
    80004b02:	bf8080e7          	jalr	-1032(ra) # 800046f6 <filealloc>
    80004b06:	e088                	sd	a0,0(s1)
    80004b08:	c551                	beqz	a0,80004b94 <pipealloc+0xb2>
    80004b0a:	00000097          	auipc	ra,0x0
    80004b0e:	bec080e7          	jalr	-1044(ra) # 800046f6 <filealloc>
    80004b12:	00aa3023          	sd	a0,0(s4)
    80004b16:	c92d                	beqz	a0,80004b88 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004b18:	ffffc097          	auipc	ra,0xffffc
    80004b1c:	fe2080e7          	jalr	-30(ra) # 80000afa <kalloc>
    80004b20:	892a                	mv	s2,a0
    80004b22:	c125                	beqz	a0,80004b82 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004b24:	4985                	li	s3,1
    80004b26:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004b2a:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004b2e:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004b32:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004b36:	00004597          	auipc	a1,0x4
    80004b3a:	a4258593          	addi	a1,a1,-1470 # 80008578 <states.1784+0x1e8>
    80004b3e:	ffffc097          	auipc	ra,0xffffc
    80004b42:	01c080e7          	jalr	28(ra) # 80000b5a <initlock>
  (*f0)->type = FD_PIPE;
    80004b46:	609c                	ld	a5,0(s1)
    80004b48:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004b4c:	609c                	ld	a5,0(s1)
    80004b4e:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004b52:	609c                	ld	a5,0(s1)
    80004b54:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004b58:	609c                	ld	a5,0(s1)
    80004b5a:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004b5e:	000a3783          	ld	a5,0(s4)
    80004b62:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004b66:	000a3783          	ld	a5,0(s4)
    80004b6a:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004b6e:	000a3783          	ld	a5,0(s4)
    80004b72:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004b76:	000a3783          	ld	a5,0(s4)
    80004b7a:	0127b823          	sd	s2,16(a5)
  return 0;
    80004b7e:	4501                	li	a0,0
    80004b80:	a025                	j	80004ba8 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004b82:	6088                	ld	a0,0(s1)
    80004b84:	e501                	bnez	a0,80004b8c <pipealloc+0xaa>
    80004b86:	a039                	j	80004b94 <pipealloc+0xb2>
    80004b88:	6088                	ld	a0,0(s1)
    80004b8a:	c51d                	beqz	a0,80004bb8 <pipealloc+0xd6>
    fileclose(*f0);
    80004b8c:	00000097          	auipc	ra,0x0
    80004b90:	c26080e7          	jalr	-986(ra) # 800047b2 <fileclose>
  if(*f1)
    80004b94:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004b98:	557d                	li	a0,-1
  if(*f1)
    80004b9a:	c799                	beqz	a5,80004ba8 <pipealloc+0xc6>
    fileclose(*f1);
    80004b9c:	853e                	mv	a0,a5
    80004b9e:	00000097          	auipc	ra,0x0
    80004ba2:	c14080e7          	jalr	-1004(ra) # 800047b2 <fileclose>
  return -1;
    80004ba6:	557d                	li	a0,-1
}
    80004ba8:	70a2                	ld	ra,40(sp)
    80004baa:	7402                	ld	s0,32(sp)
    80004bac:	64e2                	ld	s1,24(sp)
    80004bae:	6942                	ld	s2,16(sp)
    80004bb0:	69a2                	ld	s3,8(sp)
    80004bb2:	6a02                	ld	s4,0(sp)
    80004bb4:	6145                	addi	sp,sp,48
    80004bb6:	8082                	ret
  return -1;
    80004bb8:	557d                	li	a0,-1
    80004bba:	b7fd                	j	80004ba8 <pipealloc+0xc6>

0000000080004bbc <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004bbc:	1101                	addi	sp,sp,-32
    80004bbe:	ec06                	sd	ra,24(sp)
    80004bc0:	e822                	sd	s0,16(sp)
    80004bc2:	e426                	sd	s1,8(sp)
    80004bc4:	e04a                	sd	s2,0(sp)
    80004bc6:	1000                	addi	s0,sp,32
    80004bc8:	84aa                	mv	s1,a0
    80004bca:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004bcc:	ffffc097          	auipc	ra,0xffffc
    80004bd0:	01e080e7          	jalr	30(ra) # 80000bea <acquire>
  if(writable){
    80004bd4:	02090d63          	beqz	s2,80004c0e <pipeclose+0x52>
    pi->writeopen = 0;
    80004bd8:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004bdc:	21848513          	addi	a0,s1,536
    80004be0:	ffffd097          	auipc	ra,0xffffd
    80004be4:	58e080e7          	jalr	1422(ra) # 8000216e <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004be8:	2204b783          	ld	a5,544(s1)
    80004bec:	eb95                	bnez	a5,80004c20 <pipeclose+0x64>
    release(&pi->lock);
    80004bee:	8526                	mv	a0,s1
    80004bf0:	ffffc097          	auipc	ra,0xffffc
    80004bf4:	0ae080e7          	jalr	174(ra) # 80000c9e <release>
    kfree((char*)pi);
    80004bf8:	8526                	mv	a0,s1
    80004bfa:	ffffc097          	auipc	ra,0xffffc
    80004bfe:	e04080e7          	jalr	-508(ra) # 800009fe <kfree>
  } else
    release(&pi->lock);
}
    80004c02:	60e2                	ld	ra,24(sp)
    80004c04:	6442                	ld	s0,16(sp)
    80004c06:	64a2                	ld	s1,8(sp)
    80004c08:	6902                	ld	s2,0(sp)
    80004c0a:	6105                	addi	sp,sp,32
    80004c0c:	8082                	ret
    pi->readopen = 0;
    80004c0e:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004c12:	21c48513          	addi	a0,s1,540
    80004c16:	ffffd097          	auipc	ra,0xffffd
    80004c1a:	558080e7          	jalr	1368(ra) # 8000216e <wakeup>
    80004c1e:	b7e9                	j	80004be8 <pipeclose+0x2c>
    release(&pi->lock);
    80004c20:	8526                	mv	a0,s1
    80004c22:	ffffc097          	auipc	ra,0xffffc
    80004c26:	07c080e7          	jalr	124(ra) # 80000c9e <release>
}
    80004c2a:	bfe1                	j	80004c02 <pipeclose+0x46>

0000000080004c2c <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004c2c:	7159                	addi	sp,sp,-112
    80004c2e:	f486                	sd	ra,104(sp)
    80004c30:	f0a2                	sd	s0,96(sp)
    80004c32:	eca6                	sd	s1,88(sp)
    80004c34:	e8ca                	sd	s2,80(sp)
    80004c36:	e4ce                	sd	s3,72(sp)
    80004c38:	e0d2                	sd	s4,64(sp)
    80004c3a:	fc56                	sd	s5,56(sp)
    80004c3c:	f85a                	sd	s6,48(sp)
    80004c3e:	f45e                	sd	s7,40(sp)
    80004c40:	f062                	sd	s8,32(sp)
    80004c42:	ec66                	sd	s9,24(sp)
    80004c44:	1880                	addi	s0,sp,112
    80004c46:	84aa                	mv	s1,a0
    80004c48:	8aae                	mv	s5,a1
    80004c4a:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004c4c:	ffffd097          	auipc	ra,0xffffd
    80004c50:	d7a080e7          	jalr	-646(ra) # 800019c6 <myproc>
    80004c54:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004c56:	8526                	mv	a0,s1
    80004c58:	ffffc097          	auipc	ra,0xffffc
    80004c5c:	f92080e7          	jalr	-110(ra) # 80000bea <acquire>
  while(i < n){
    80004c60:	0d405463          	blez	s4,80004d28 <pipewrite+0xfc>
    80004c64:	8ba6                	mv	s7,s1
  int i = 0;
    80004c66:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c68:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004c6a:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004c6e:	21c48c13          	addi	s8,s1,540
    80004c72:	a08d                	j	80004cd4 <pipewrite+0xa8>
      release(&pi->lock);
    80004c74:	8526                	mv	a0,s1
    80004c76:	ffffc097          	auipc	ra,0xffffc
    80004c7a:	028080e7          	jalr	40(ra) # 80000c9e <release>
      return -1;
    80004c7e:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004c80:	854a                	mv	a0,s2
    80004c82:	70a6                	ld	ra,104(sp)
    80004c84:	7406                	ld	s0,96(sp)
    80004c86:	64e6                	ld	s1,88(sp)
    80004c88:	6946                	ld	s2,80(sp)
    80004c8a:	69a6                	ld	s3,72(sp)
    80004c8c:	6a06                	ld	s4,64(sp)
    80004c8e:	7ae2                	ld	s5,56(sp)
    80004c90:	7b42                	ld	s6,48(sp)
    80004c92:	7ba2                	ld	s7,40(sp)
    80004c94:	7c02                	ld	s8,32(sp)
    80004c96:	6ce2                	ld	s9,24(sp)
    80004c98:	6165                	addi	sp,sp,112
    80004c9a:	8082                	ret
      wakeup(&pi->nread);
    80004c9c:	8566                	mv	a0,s9
    80004c9e:	ffffd097          	auipc	ra,0xffffd
    80004ca2:	4d0080e7          	jalr	1232(ra) # 8000216e <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004ca6:	85de                	mv	a1,s7
    80004ca8:	8562                	mv	a0,s8
    80004caa:	ffffd097          	auipc	ra,0xffffd
    80004cae:	460080e7          	jalr	1120(ra) # 8000210a <sleep>
    80004cb2:	a839                	j	80004cd0 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004cb4:	21c4a783          	lw	a5,540(s1)
    80004cb8:	0017871b          	addiw	a4,a5,1
    80004cbc:	20e4ae23          	sw	a4,540(s1)
    80004cc0:	1ff7f793          	andi	a5,a5,511
    80004cc4:	97a6                	add	a5,a5,s1
    80004cc6:	f9f44703          	lbu	a4,-97(s0)
    80004cca:	00e78c23          	sb	a4,24(a5)
      i++;
    80004cce:	2905                	addiw	s2,s2,1
  while(i < n){
    80004cd0:	05495063          	bge	s2,s4,80004d10 <pipewrite+0xe4>
    if(pi->readopen == 0 || killed(pr)){
    80004cd4:	2204a783          	lw	a5,544(s1)
    80004cd8:	dfd1                	beqz	a5,80004c74 <pipewrite+0x48>
    80004cda:	854e                	mv	a0,s3
    80004cdc:	ffffd097          	auipc	ra,0xffffd
    80004ce0:	6d6080e7          	jalr	1750(ra) # 800023b2 <killed>
    80004ce4:	f941                	bnez	a0,80004c74 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004ce6:	2184a783          	lw	a5,536(s1)
    80004cea:	21c4a703          	lw	a4,540(s1)
    80004cee:	2007879b          	addiw	a5,a5,512
    80004cf2:	faf705e3          	beq	a4,a5,80004c9c <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004cf6:	4685                	li	a3,1
    80004cf8:	01590633          	add	a2,s2,s5
    80004cfc:	f9f40593          	addi	a1,s0,-97
    80004d00:	0509b503          	ld	a0,80(s3)
    80004d04:	ffffd097          	auipc	ra,0xffffd
    80004d08:	a0c080e7          	jalr	-1524(ra) # 80001710 <copyin>
    80004d0c:	fb6514e3          	bne	a0,s6,80004cb4 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004d10:	21848513          	addi	a0,s1,536
    80004d14:	ffffd097          	auipc	ra,0xffffd
    80004d18:	45a080e7          	jalr	1114(ra) # 8000216e <wakeup>
  release(&pi->lock);
    80004d1c:	8526                	mv	a0,s1
    80004d1e:	ffffc097          	auipc	ra,0xffffc
    80004d22:	f80080e7          	jalr	-128(ra) # 80000c9e <release>
  return i;
    80004d26:	bfa9                	j	80004c80 <pipewrite+0x54>
  int i = 0;
    80004d28:	4901                	li	s2,0
    80004d2a:	b7dd                	j	80004d10 <pipewrite+0xe4>

0000000080004d2c <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004d2c:	715d                	addi	sp,sp,-80
    80004d2e:	e486                	sd	ra,72(sp)
    80004d30:	e0a2                	sd	s0,64(sp)
    80004d32:	fc26                	sd	s1,56(sp)
    80004d34:	f84a                	sd	s2,48(sp)
    80004d36:	f44e                	sd	s3,40(sp)
    80004d38:	f052                	sd	s4,32(sp)
    80004d3a:	ec56                	sd	s5,24(sp)
    80004d3c:	e85a                	sd	s6,16(sp)
    80004d3e:	0880                	addi	s0,sp,80
    80004d40:	84aa                	mv	s1,a0
    80004d42:	892e                	mv	s2,a1
    80004d44:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004d46:	ffffd097          	auipc	ra,0xffffd
    80004d4a:	c80080e7          	jalr	-896(ra) # 800019c6 <myproc>
    80004d4e:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004d50:	8b26                	mv	s6,s1
    80004d52:	8526                	mv	a0,s1
    80004d54:	ffffc097          	auipc	ra,0xffffc
    80004d58:	e96080e7          	jalr	-362(ra) # 80000bea <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d5c:	2184a703          	lw	a4,536(s1)
    80004d60:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d64:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d68:	02f71763          	bne	a4,a5,80004d96 <piperead+0x6a>
    80004d6c:	2244a783          	lw	a5,548(s1)
    80004d70:	c39d                	beqz	a5,80004d96 <piperead+0x6a>
    if(killed(pr)){
    80004d72:	8552                	mv	a0,s4
    80004d74:	ffffd097          	auipc	ra,0xffffd
    80004d78:	63e080e7          	jalr	1598(ra) # 800023b2 <killed>
    80004d7c:	e941                	bnez	a0,80004e0c <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d7e:	85da                	mv	a1,s6
    80004d80:	854e                	mv	a0,s3
    80004d82:	ffffd097          	auipc	ra,0xffffd
    80004d86:	388080e7          	jalr	904(ra) # 8000210a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d8a:	2184a703          	lw	a4,536(s1)
    80004d8e:	21c4a783          	lw	a5,540(s1)
    80004d92:	fcf70de3          	beq	a4,a5,80004d6c <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d96:	09505263          	blez	s5,80004e1a <piperead+0xee>
    80004d9a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d9c:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004d9e:	2184a783          	lw	a5,536(s1)
    80004da2:	21c4a703          	lw	a4,540(s1)
    80004da6:	02f70d63          	beq	a4,a5,80004de0 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004daa:	0017871b          	addiw	a4,a5,1
    80004dae:	20e4ac23          	sw	a4,536(s1)
    80004db2:	1ff7f793          	andi	a5,a5,511
    80004db6:	97a6                	add	a5,a5,s1
    80004db8:	0187c783          	lbu	a5,24(a5)
    80004dbc:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004dc0:	4685                	li	a3,1
    80004dc2:	fbf40613          	addi	a2,s0,-65
    80004dc6:	85ca                	mv	a1,s2
    80004dc8:	050a3503          	ld	a0,80(s4)
    80004dcc:	ffffd097          	auipc	ra,0xffffd
    80004dd0:	8b8080e7          	jalr	-1864(ra) # 80001684 <copyout>
    80004dd4:	01650663          	beq	a0,s6,80004de0 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004dd8:	2985                	addiw	s3,s3,1
    80004dda:	0905                	addi	s2,s2,1
    80004ddc:	fd3a91e3          	bne	s5,s3,80004d9e <piperead+0x72>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004de0:	21c48513          	addi	a0,s1,540
    80004de4:	ffffd097          	auipc	ra,0xffffd
    80004de8:	38a080e7          	jalr	906(ra) # 8000216e <wakeup>
  release(&pi->lock);
    80004dec:	8526                	mv	a0,s1
    80004dee:	ffffc097          	auipc	ra,0xffffc
    80004df2:	eb0080e7          	jalr	-336(ra) # 80000c9e <release>
  return i;
}
    80004df6:	854e                	mv	a0,s3
    80004df8:	60a6                	ld	ra,72(sp)
    80004dfa:	6406                	ld	s0,64(sp)
    80004dfc:	74e2                	ld	s1,56(sp)
    80004dfe:	7942                	ld	s2,48(sp)
    80004e00:	79a2                	ld	s3,40(sp)
    80004e02:	7a02                	ld	s4,32(sp)
    80004e04:	6ae2                	ld	s5,24(sp)
    80004e06:	6b42                	ld	s6,16(sp)
    80004e08:	6161                	addi	sp,sp,80
    80004e0a:	8082                	ret
      release(&pi->lock);
    80004e0c:	8526                	mv	a0,s1
    80004e0e:	ffffc097          	auipc	ra,0xffffc
    80004e12:	e90080e7          	jalr	-368(ra) # 80000c9e <release>
      return -1;
    80004e16:	59fd                	li	s3,-1
    80004e18:	bff9                	j	80004df6 <piperead+0xca>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e1a:	4981                	li	s3,0
    80004e1c:	b7d1                	j	80004de0 <piperead+0xb4>

0000000080004e1e <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004e1e:	1141                	addi	sp,sp,-16
    80004e20:	e422                	sd	s0,8(sp)
    80004e22:	0800                	addi	s0,sp,16
    80004e24:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004e26:	8905                	andi	a0,a0,1
    80004e28:	c111                	beqz	a0,80004e2c <flags2perm+0xe>
      perm = PTE_X;
    80004e2a:	4521                	li	a0,8
    if(flags & 0x2)
    80004e2c:	8b89                	andi	a5,a5,2
    80004e2e:	c399                	beqz	a5,80004e34 <flags2perm+0x16>
      perm |= PTE_W;
    80004e30:	00456513          	ori	a0,a0,4
    return perm;
}
    80004e34:	6422                	ld	s0,8(sp)
    80004e36:	0141                	addi	sp,sp,16
    80004e38:	8082                	ret

0000000080004e3a <exec>:

int
exec(char *path, char **argv)
{
    80004e3a:	df010113          	addi	sp,sp,-528
    80004e3e:	20113423          	sd	ra,520(sp)
    80004e42:	20813023          	sd	s0,512(sp)
    80004e46:	ffa6                	sd	s1,504(sp)
    80004e48:	fbca                	sd	s2,496(sp)
    80004e4a:	f7ce                	sd	s3,488(sp)
    80004e4c:	f3d2                	sd	s4,480(sp)
    80004e4e:	efd6                	sd	s5,472(sp)
    80004e50:	ebda                	sd	s6,464(sp)
    80004e52:	e7de                	sd	s7,456(sp)
    80004e54:	e3e2                	sd	s8,448(sp)
    80004e56:	ff66                	sd	s9,440(sp)
    80004e58:	fb6a                	sd	s10,432(sp)
    80004e5a:	f76e                	sd	s11,424(sp)
    80004e5c:	0c00                	addi	s0,sp,528
    80004e5e:	84aa                	mv	s1,a0
    80004e60:	dea43c23          	sd	a0,-520(s0)
    80004e64:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004e68:	ffffd097          	auipc	ra,0xffffd
    80004e6c:	b5e080e7          	jalr	-1186(ra) # 800019c6 <myproc>
    80004e70:	892a                	mv	s2,a0

  begin_op();
    80004e72:	fffff097          	auipc	ra,0xfffff
    80004e76:	474080e7          	jalr	1140(ra) # 800042e6 <begin_op>

  if((ip = namei(path)) == 0){
    80004e7a:	8526                	mv	a0,s1
    80004e7c:	fffff097          	auipc	ra,0xfffff
    80004e80:	24e080e7          	jalr	590(ra) # 800040ca <namei>
    80004e84:	c92d                	beqz	a0,80004ef6 <exec+0xbc>
    80004e86:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004e88:	fffff097          	auipc	ra,0xfffff
    80004e8c:	a9c080e7          	jalr	-1380(ra) # 80003924 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004e90:	04000713          	li	a4,64
    80004e94:	4681                	li	a3,0
    80004e96:	e5040613          	addi	a2,s0,-432
    80004e9a:	4581                	li	a1,0
    80004e9c:	8526                	mv	a0,s1
    80004e9e:	fffff097          	auipc	ra,0xfffff
    80004ea2:	d3a080e7          	jalr	-710(ra) # 80003bd8 <readi>
    80004ea6:	04000793          	li	a5,64
    80004eaa:	00f51a63          	bne	a0,a5,80004ebe <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004eae:	e5042703          	lw	a4,-432(s0)
    80004eb2:	464c47b7          	lui	a5,0x464c4
    80004eb6:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004eba:	04f70463          	beq	a4,a5,80004f02 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004ebe:	8526                	mv	a0,s1
    80004ec0:	fffff097          	auipc	ra,0xfffff
    80004ec4:	cc6080e7          	jalr	-826(ra) # 80003b86 <iunlockput>
    end_op();
    80004ec8:	fffff097          	auipc	ra,0xfffff
    80004ecc:	49e080e7          	jalr	1182(ra) # 80004366 <end_op>
  }
  return -1;
    80004ed0:	557d                	li	a0,-1
}
    80004ed2:	20813083          	ld	ra,520(sp)
    80004ed6:	20013403          	ld	s0,512(sp)
    80004eda:	74fe                	ld	s1,504(sp)
    80004edc:	795e                	ld	s2,496(sp)
    80004ede:	79be                	ld	s3,488(sp)
    80004ee0:	7a1e                	ld	s4,480(sp)
    80004ee2:	6afe                	ld	s5,472(sp)
    80004ee4:	6b5e                	ld	s6,464(sp)
    80004ee6:	6bbe                	ld	s7,456(sp)
    80004ee8:	6c1e                	ld	s8,448(sp)
    80004eea:	7cfa                	ld	s9,440(sp)
    80004eec:	7d5a                	ld	s10,432(sp)
    80004eee:	7dba                	ld	s11,424(sp)
    80004ef0:	21010113          	addi	sp,sp,528
    80004ef4:	8082                	ret
    end_op();
    80004ef6:	fffff097          	auipc	ra,0xfffff
    80004efa:	470080e7          	jalr	1136(ra) # 80004366 <end_op>
    return -1;
    80004efe:	557d                	li	a0,-1
    80004f00:	bfc9                	j	80004ed2 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004f02:	854a                	mv	a0,s2
    80004f04:	ffffd097          	auipc	ra,0xffffd
    80004f08:	b86080e7          	jalr	-1146(ra) # 80001a8a <proc_pagetable>
    80004f0c:	8baa                	mv	s7,a0
    80004f0e:	d945                	beqz	a0,80004ebe <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f10:	e7042983          	lw	s3,-400(s0)
    80004f14:	e8845783          	lhu	a5,-376(s0)
    80004f18:	c7ad                	beqz	a5,80004f82 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004f1a:	4a01                	li	s4,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f1c:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004f1e:	6c85                	lui	s9,0x1
    80004f20:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004f24:	def43823          	sd	a5,-528(s0)
    80004f28:	ac0d                	j	8000515a <exec+0x320>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004f2a:	00004517          	auipc	a0,0x4
    80004f2e:	9ae50513          	addi	a0,a0,-1618 # 800088d8 <syscalls+0x2b8>
    80004f32:	ffffb097          	auipc	ra,0xffffb
    80004f36:	612080e7          	jalr	1554(ra) # 80000544 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004f3a:	8756                	mv	a4,s5
    80004f3c:	012d86bb          	addw	a3,s11,s2
    80004f40:	4581                	li	a1,0
    80004f42:	8526                	mv	a0,s1
    80004f44:	fffff097          	auipc	ra,0xfffff
    80004f48:	c94080e7          	jalr	-876(ra) # 80003bd8 <readi>
    80004f4c:	2501                	sext.w	a0,a0
    80004f4e:	1aaa9a63          	bne	s5,a0,80005102 <exec+0x2c8>
  for(i = 0; i < sz; i += PGSIZE){
    80004f52:	6785                	lui	a5,0x1
    80004f54:	0127893b          	addw	s2,a5,s2
    80004f58:	77fd                	lui	a5,0xfffff
    80004f5a:	01478a3b          	addw	s4,a5,s4
    80004f5e:	1f897563          	bgeu	s2,s8,80005148 <exec+0x30e>
    pa = walkaddr(pagetable, va + i);
    80004f62:	02091593          	slli	a1,s2,0x20
    80004f66:	9181                	srli	a1,a1,0x20
    80004f68:	95ea                	add	a1,a1,s10
    80004f6a:	855e                	mv	a0,s7
    80004f6c:	ffffc097          	auipc	ra,0xffffc
    80004f70:	10c080e7          	jalr	268(ra) # 80001078 <walkaddr>
    80004f74:	862a                	mv	a2,a0
    if(pa == 0)
    80004f76:	d955                	beqz	a0,80004f2a <exec+0xf0>
      n = PGSIZE;
    80004f78:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004f7a:	fd9a70e3          	bgeu	s4,s9,80004f3a <exec+0x100>
      n = sz - i;
    80004f7e:	8ad2                	mv	s5,s4
    80004f80:	bf6d                	j	80004f3a <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004f82:	4a01                	li	s4,0
  iunlockput(ip);
    80004f84:	8526                	mv	a0,s1
    80004f86:	fffff097          	auipc	ra,0xfffff
    80004f8a:	c00080e7          	jalr	-1024(ra) # 80003b86 <iunlockput>
  end_op();
    80004f8e:	fffff097          	auipc	ra,0xfffff
    80004f92:	3d8080e7          	jalr	984(ra) # 80004366 <end_op>
  p = myproc();
    80004f96:	ffffd097          	auipc	ra,0xffffd
    80004f9a:	a30080e7          	jalr	-1488(ra) # 800019c6 <myproc>
    80004f9e:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004fa0:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004fa4:	6785                	lui	a5,0x1
    80004fa6:	17fd                	addi	a5,a5,-1
    80004fa8:	9a3e                	add	s4,s4,a5
    80004faa:	757d                	lui	a0,0xfffff
    80004fac:	00aa77b3          	and	a5,s4,a0
    80004fb0:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004fb4:	4691                	li	a3,4
    80004fb6:	6609                	lui	a2,0x2
    80004fb8:	963e                	add	a2,a2,a5
    80004fba:	85be                	mv	a1,a5
    80004fbc:	855e                	mv	a0,s7
    80004fbe:	ffffc097          	auipc	ra,0xffffc
    80004fc2:	46e080e7          	jalr	1134(ra) # 8000142c <uvmalloc>
    80004fc6:	8b2a                	mv	s6,a0
  ip = 0;
    80004fc8:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004fca:	12050c63          	beqz	a0,80005102 <exec+0x2c8>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004fce:	75f9                	lui	a1,0xffffe
    80004fd0:	95aa                	add	a1,a1,a0
    80004fd2:	855e                	mv	a0,s7
    80004fd4:	ffffc097          	auipc	ra,0xffffc
    80004fd8:	67e080e7          	jalr	1662(ra) # 80001652 <uvmclear>
  stackbase = sp - PGSIZE;
    80004fdc:	7c7d                	lui	s8,0xfffff
    80004fde:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004fe0:	e0043783          	ld	a5,-512(s0)
    80004fe4:	6388                	ld	a0,0(a5)
    80004fe6:	c535                	beqz	a0,80005052 <exec+0x218>
    80004fe8:	e9040993          	addi	s3,s0,-368
    80004fec:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004ff0:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004ff2:	ffffc097          	auipc	ra,0xffffc
    80004ff6:	e78080e7          	jalr	-392(ra) # 80000e6a <strlen>
    80004ffa:	2505                	addiw	a0,a0,1
    80004ffc:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005000:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005004:	13896663          	bltu	s2,s8,80005130 <exec+0x2f6>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005008:	e0043d83          	ld	s11,-512(s0)
    8000500c:	000dba03          	ld	s4,0(s11)
    80005010:	8552                	mv	a0,s4
    80005012:	ffffc097          	auipc	ra,0xffffc
    80005016:	e58080e7          	jalr	-424(ra) # 80000e6a <strlen>
    8000501a:	0015069b          	addiw	a3,a0,1
    8000501e:	8652                	mv	a2,s4
    80005020:	85ca                	mv	a1,s2
    80005022:	855e                	mv	a0,s7
    80005024:	ffffc097          	auipc	ra,0xffffc
    80005028:	660080e7          	jalr	1632(ra) # 80001684 <copyout>
    8000502c:	10054663          	bltz	a0,80005138 <exec+0x2fe>
    ustack[argc] = sp;
    80005030:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005034:	0485                	addi	s1,s1,1
    80005036:	008d8793          	addi	a5,s11,8
    8000503a:	e0f43023          	sd	a5,-512(s0)
    8000503e:	008db503          	ld	a0,8(s11)
    80005042:	c911                	beqz	a0,80005056 <exec+0x21c>
    if(argc >= MAXARG)
    80005044:	09a1                	addi	s3,s3,8
    80005046:	fb3c96e3          	bne	s9,s3,80004ff2 <exec+0x1b8>
  sz = sz1;
    8000504a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000504e:	4481                	li	s1,0
    80005050:	a84d                	j	80005102 <exec+0x2c8>
  sp = sz;
    80005052:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005054:	4481                	li	s1,0
  ustack[argc] = 0;
    80005056:	00349793          	slli	a5,s1,0x3
    8000505a:	f9040713          	addi	a4,s0,-112
    8000505e:	97ba                	add	a5,a5,a4
    80005060:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005064:	00148693          	addi	a3,s1,1
    80005068:	068e                	slli	a3,a3,0x3
    8000506a:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000506e:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005072:	01897663          	bgeu	s2,s8,8000507e <exec+0x244>
  sz = sz1;
    80005076:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000507a:	4481                	li	s1,0
    8000507c:	a059                	j	80005102 <exec+0x2c8>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000507e:	e9040613          	addi	a2,s0,-368
    80005082:	85ca                	mv	a1,s2
    80005084:	855e                	mv	a0,s7
    80005086:	ffffc097          	auipc	ra,0xffffc
    8000508a:	5fe080e7          	jalr	1534(ra) # 80001684 <copyout>
    8000508e:	0a054963          	bltz	a0,80005140 <exec+0x306>
  p->trapframe->a1 = sp;
    80005092:	058ab783          	ld	a5,88(s5)
    80005096:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000509a:	df843783          	ld	a5,-520(s0)
    8000509e:	0007c703          	lbu	a4,0(a5)
    800050a2:	cf11                	beqz	a4,800050be <exec+0x284>
    800050a4:	0785                	addi	a5,a5,1
    if(*s == '/')
    800050a6:	02f00693          	li	a3,47
    800050aa:	a039                	j	800050b8 <exec+0x27e>
      last = s+1;
    800050ac:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800050b0:	0785                	addi	a5,a5,1
    800050b2:	fff7c703          	lbu	a4,-1(a5)
    800050b6:	c701                	beqz	a4,800050be <exec+0x284>
    if(*s == '/')
    800050b8:	fed71ce3          	bne	a4,a3,800050b0 <exec+0x276>
    800050bc:	bfc5                	j	800050ac <exec+0x272>
  safestrcpy(p->name, last, sizeof(p->name));
    800050be:	4641                	li	a2,16
    800050c0:	df843583          	ld	a1,-520(s0)
    800050c4:	158a8513          	addi	a0,s5,344
    800050c8:	ffffc097          	auipc	ra,0xffffc
    800050cc:	d70080e7          	jalr	-656(ra) # 80000e38 <safestrcpy>
  oldpagetable = p->pagetable;
    800050d0:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    800050d4:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    800050d8:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800050dc:	058ab783          	ld	a5,88(s5)
    800050e0:	e6843703          	ld	a4,-408(s0)
    800050e4:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800050e6:	058ab783          	ld	a5,88(s5)
    800050ea:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800050ee:	85ea                	mv	a1,s10
    800050f0:	ffffd097          	auipc	ra,0xffffd
    800050f4:	a36080e7          	jalr	-1482(ra) # 80001b26 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800050f8:	0004851b          	sext.w	a0,s1
    800050fc:	bbd9                	j	80004ed2 <exec+0x98>
    800050fe:	e1443423          	sd	s4,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005102:	e0843583          	ld	a1,-504(s0)
    80005106:	855e                	mv	a0,s7
    80005108:	ffffd097          	auipc	ra,0xffffd
    8000510c:	a1e080e7          	jalr	-1506(ra) # 80001b26 <proc_freepagetable>
  if(ip){
    80005110:	da0497e3          	bnez	s1,80004ebe <exec+0x84>
  return -1;
    80005114:	557d                	li	a0,-1
    80005116:	bb75                	j	80004ed2 <exec+0x98>
    80005118:	e1443423          	sd	s4,-504(s0)
    8000511c:	b7dd                	j	80005102 <exec+0x2c8>
    8000511e:	e1443423          	sd	s4,-504(s0)
    80005122:	b7c5                	j	80005102 <exec+0x2c8>
    80005124:	e1443423          	sd	s4,-504(s0)
    80005128:	bfe9                	j	80005102 <exec+0x2c8>
    8000512a:	e1443423          	sd	s4,-504(s0)
    8000512e:	bfd1                	j	80005102 <exec+0x2c8>
  sz = sz1;
    80005130:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005134:	4481                	li	s1,0
    80005136:	b7f1                	j	80005102 <exec+0x2c8>
  sz = sz1;
    80005138:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000513c:	4481                	li	s1,0
    8000513e:	b7d1                	j	80005102 <exec+0x2c8>
  sz = sz1;
    80005140:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005144:	4481                	li	s1,0
    80005146:	bf75                	j	80005102 <exec+0x2c8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005148:	e0843a03          	ld	s4,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000514c:	2b05                	addiw	s6,s6,1
    8000514e:	0389899b          	addiw	s3,s3,56
    80005152:	e8845783          	lhu	a5,-376(s0)
    80005156:	e2fb57e3          	bge	s6,a5,80004f84 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000515a:	2981                	sext.w	s3,s3
    8000515c:	03800713          	li	a4,56
    80005160:	86ce                	mv	a3,s3
    80005162:	e1840613          	addi	a2,s0,-488
    80005166:	4581                	li	a1,0
    80005168:	8526                	mv	a0,s1
    8000516a:	fffff097          	auipc	ra,0xfffff
    8000516e:	a6e080e7          	jalr	-1426(ra) # 80003bd8 <readi>
    80005172:	03800793          	li	a5,56
    80005176:	f8f514e3          	bne	a0,a5,800050fe <exec+0x2c4>
    if(ph.type != ELF_PROG_LOAD)
    8000517a:	e1842783          	lw	a5,-488(s0)
    8000517e:	4705                	li	a4,1
    80005180:	fce796e3          	bne	a5,a4,8000514c <exec+0x312>
    if(ph.memsz < ph.filesz)
    80005184:	e4043903          	ld	s2,-448(s0)
    80005188:	e3843783          	ld	a5,-456(s0)
    8000518c:	f8f966e3          	bltu	s2,a5,80005118 <exec+0x2de>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005190:	e2843783          	ld	a5,-472(s0)
    80005194:	993e                	add	s2,s2,a5
    80005196:	f8f964e3          	bltu	s2,a5,8000511e <exec+0x2e4>
    if(ph.vaddr % PGSIZE != 0)
    8000519a:	df043703          	ld	a4,-528(s0)
    8000519e:	8ff9                	and	a5,a5,a4
    800051a0:	f3d1                	bnez	a5,80005124 <exec+0x2ea>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800051a2:	e1c42503          	lw	a0,-484(s0)
    800051a6:	00000097          	auipc	ra,0x0
    800051aa:	c78080e7          	jalr	-904(ra) # 80004e1e <flags2perm>
    800051ae:	86aa                	mv	a3,a0
    800051b0:	864a                	mv	a2,s2
    800051b2:	85d2                	mv	a1,s4
    800051b4:	855e                	mv	a0,s7
    800051b6:	ffffc097          	auipc	ra,0xffffc
    800051ba:	276080e7          	jalr	630(ra) # 8000142c <uvmalloc>
    800051be:	e0a43423          	sd	a0,-504(s0)
    800051c2:	d525                	beqz	a0,8000512a <exec+0x2f0>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800051c4:	e2843d03          	ld	s10,-472(s0)
    800051c8:	e2042d83          	lw	s11,-480(s0)
    800051cc:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800051d0:	f60c0ce3          	beqz	s8,80005148 <exec+0x30e>
    800051d4:	8a62                	mv	s4,s8
    800051d6:	4901                	li	s2,0
    800051d8:	b369                	j	80004f62 <exec+0x128>

00000000800051da <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800051da:	7179                	addi	sp,sp,-48
    800051dc:	f406                	sd	ra,40(sp)
    800051de:	f022                	sd	s0,32(sp)
    800051e0:	ec26                	sd	s1,24(sp)
    800051e2:	e84a                	sd	s2,16(sp)
    800051e4:	1800                	addi	s0,sp,48
    800051e6:	892e                	mv	s2,a1
    800051e8:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800051ea:	fdc40593          	addi	a1,s0,-36
    800051ee:	ffffe097          	auipc	ra,0xffffe
    800051f2:	9f4080e7          	jalr	-1548(ra) # 80002be2 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800051f6:	fdc42703          	lw	a4,-36(s0)
    800051fa:	47bd                	li	a5,15
    800051fc:	02e7eb63          	bltu	a5,a4,80005232 <argfd+0x58>
    80005200:	ffffc097          	auipc	ra,0xffffc
    80005204:	7c6080e7          	jalr	1990(ra) # 800019c6 <myproc>
    80005208:	fdc42703          	lw	a4,-36(s0)
    8000520c:	01a70793          	addi	a5,a4,26
    80005210:	078e                	slli	a5,a5,0x3
    80005212:	953e                	add	a0,a0,a5
    80005214:	611c                	ld	a5,0(a0)
    80005216:	c385                	beqz	a5,80005236 <argfd+0x5c>
    return -1;
  if(pfd)
    80005218:	00090463          	beqz	s2,80005220 <argfd+0x46>
    *pfd = fd;
    8000521c:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005220:	4501                	li	a0,0
  if(pf)
    80005222:	c091                	beqz	s1,80005226 <argfd+0x4c>
    *pf = f;
    80005224:	e09c                	sd	a5,0(s1)
}
    80005226:	70a2                	ld	ra,40(sp)
    80005228:	7402                	ld	s0,32(sp)
    8000522a:	64e2                	ld	s1,24(sp)
    8000522c:	6942                	ld	s2,16(sp)
    8000522e:	6145                	addi	sp,sp,48
    80005230:	8082                	ret
    return -1;
    80005232:	557d                	li	a0,-1
    80005234:	bfcd                	j	80005226 <argfd+0x4c>
    80005236:	557d                	li	a0,-1
    80005238:	b7fd                	j	80005226 <argfd+0x4c>

000000008000523a <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000523a:	1101                	addi	sp,sp,-32
    8000523c:	ec06                	sd	ra,24(sp)
    8000523e:	e822                	sd	s0,16(sp)
    80005240:	e426                	sd	s1,8(sp)
    80005242:	1000                	addi	s0,sp,32
    80005244:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005246:	ffffc097          	auipc	ra,0xffffc
    8000524a:	780080e7          	jalr	1920(ra) # 800019c6 <myproc>
    8000524e:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005250:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd4dc8>
    80005254:	4501                	li	a0,0
    80005256:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005258:	6398                	ld	a4,0(a5)
    8000525a:	cb19                	beqz	a4,80005270 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    8000525c:	2505                	addiw	a0,a0,1
    8000525e:	07a1                	addi	a5,a5,8
    80005260:	fed51ce3          	bne	a0,a3,80005258 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005264:	557d                	li	a0,-1
}
    80005266:	60e2                	ld	ra,24(sp)
    80005268:	6442                	ld	s0,16(sp)
    8000526a:	64a2                	ld	s1,8(sp)
    8000526c:	6105                	addi	sp,sp,32
    8000526e:	8082                	ret
      p->ofile[fd] = f;
    80005270:	01a50793          	addi	a5,a0,26
    80005274:	078e                	slli	a5,a5,0x3
    80005276:	963e                	add	a2,a2,a5
    80005278:	e204                	sd	s1,0(a2)
      return fd;
    8000527a:	b7f5                	j	80005266 <fdalloc+0x2c>

000000008000527c <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000527c:	715d                	addi	sp,sp,-80
    8000527e:	e486                	sd	ra,72(sp)
    80005280:	e0a2                	sd	s0,64(sp)
    80005282:	fc26                	sd	s1,56(sp)
    80005284:	f84a                	sd	s2,48(sp)
    80005286:	f44e                	sd	s3,40(sp)
    80005288:	f052                	sd	s4,32(sp)
    8000528a:	ec56                	sd	s5,24(sp)
    8000528c:	e85a                	sd	s6,16(sp)
    8000528e:	0880                	addi	s0,sp,80
    80005290:	8b2e                	mv	s6,a1
    80005292:	89b2                	mv	s3,a2
    80005294:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005296:	fb040593          	addi	a1,s0,-80
    8000529a:	fffff097          	auipc	ra,0xfffff
    8000529e:	e4e080e7          	jalr	-434(ra) # 800040e8 <nameiparent>
    800052a2:	84aa                	mv	s1,a0
    800052a4:	16050063          	beqz	a0,80005404 <create+0x188>
    return 0;

  ilock(dp);
    800052a8:	ffffe097          	auipc	ra,0xffffe
    800052ac:	67c080e7          	jalr	1660(ra) # 80003924 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800052b0:	4601                	li	a2,0
    800052b2:	fb040593          	addi	a1,s0,-80
    800052b6:	8526                	mv	a0,s1
    800052b8:	fffff097          	auipc	ra,0xfffff
    800052bc:	b50080e7          	jalr	-1200(ra) # 80003e08 <dirlookup>
    800052c0:	8aaa                	mv	s5,a0
    800052c2:	c931                	beqz	a0,80005316 <create+0x9a>
    iunlockput(dp);
    800052c4:	8526                	mv	a0,s1
    800052c6:	fffff097          	auipc	ra,0xfffff
    800052ca:	8c0080e7          	jalr	-1856(ra) # 80003b86 <iunlockput>
    ilock(ip);
    800052ce:	8556                	mv	a0,s5
    800052d0:	ffffe097          	auipc	ra,0xffffe
    800052d4:	654080e7          	jalr	1620(ra) # 80003924 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800052d8:	000b059b          	sext.w	a1,s6
    800052dc:	4789                	li	a5,2
    800052de:	02f59563          	bne	a1,a5,80005308 <create+0x8c>
    800052e2:	044ad783          	lhu	a5,68(s5)
    800052e6:	37f9                	addiw	a5,a5,-2
    800052e8:	17c2                	slli	a5,a5,0x30
    800052ea:	93c1                	srli	a5,a5,0x30
    800052ec:	4705                	li	a4,1
    800052ee:	00f76d63          	bltu	a4,a5,80005308 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800052f2:	8556                	mv	a0,s5
    800052f4:	60a6                	ld	ra,72(sp)
    800052f6:	6406                	ld	s0,64(sp)
    800052f8:	74e2                	ld	s1,56(sp)
    800052fa:	7942                	ld	s2,48(sp)
    800052fc:	79a2                	ld	s3,40(sp)
    800052fe:	7a02                	ld	s4,32(sp)
    80005300:	6ae2                	ld	s5,24(sp)
    80005302:	6b42                	ld	s6,16(sp)
    80005304:	6161                	addi	sp,sp,80
    80005306:	8082                	ret
    iunlockput(ip);
    80005308:	8556                	mv	a0,s5
    8000530a:	fffff097          	auipc	ra,0xfffff
    8000530e:	87c080e7          	jalr	-1924(ra) # 80003b86 <iunlockput>
    return 0;
    80005312:	4a81                	li	s5,0
    80005314:	bff9                	j	800052f2 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005316:	85da                	mv	a1,s6
    80005318:	4088                	lw	a0,0(s1)
    8000531a:	ffffe097          	auipc	ra,0xffffe
    8000531e:	46e080e7          	jalr	1134(ra) # 80003788 <ialloc>
    80005322:	8a2a                	mv	s4,a0
    80005324:	c921                	beqz	a0,80005374 <create+0xf8>
  ilock(ip);
    80005326:	ffffe097          	auipc	ra,0xffffe
    8000532a:	5fe080e7          	jalr	1534(ra) # 80003924 <ilock>
  ip->major = major;
    8000532e:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005332:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005336:	4785                	li	a5,1
    80005338:	04fa1523          	sh	a5,74(s4)
  iupdate(ip);
    8000533c:	8552                	mv	a0,s4
    8000533e:	ffffe097          	auipc	ra,0xffffe
    80005342:	51c080e7          	jalr	1308(ra) # 8000385a <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005346:	000b059b          	sext.w	a1,s6
    8000534a:	4785                	li	a5,1
    8000534c:	02f58b63          	beq	a1,a5,80005382 <create+0x106>
  if(dirlink(dp, name, ip->inum) < 0)
    80005350:	004a2603          	lw	a2,4(s4)
    80005354:	fb040593          	addi	a1,s0,-80
    80005358:	8526                	mv	a0,s1
    8000535a:	fffff097          	auipc	ra,0xfffff
    8000535e:	cbe080e7          	jalr	-834(ra) # 80004018 <dirlink>
    80005362:	06054f63          	bltz	a0,800053e0 <create+0x164>
  iunlockput(dp);
    80005366:	8526                	mv	a0,s1
    80005368:	fffff097          	auipc	ra,0xfffff
    8000536c:	81e080e7          	jalr	-2018(ra) # 80003b86 <iunlockput>
  return ip;
    80005370:	8ad2                	mv	s5,s4
    80005372:	b741                	j	800052f2 <create+0x76>
    iunlockput(dp);
    80005374:	8526                	mv	a0,s1
    80005376:	fffff097          	auipc	ra,0xfffff
    8000537a:	810080e7          	jalr	-2032(ra) # 80003b86 <iunlockput>
    return 0;
    8000537e:	8ad2                	mv	s5,s4
    80005380:	bf8d                	j	800052f2 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005382:	004a2603          	lw	a2,4(s4)
    80005386:	00003597          	auipc	a1,0x3
    8000538a:	57258593          	addi	a1,a1,1394 # 800088f8 <syscalls+0x2d8>
    8000538e:	8552                	mv	a0,s4
    80005390:	fffff097          	auipc	ra,0xfffff
    80005394:	c88080e7          	jalr	-888(ra) # 80004018 <dirlink>
    80005398:	04054463          	bltz	a0,800053e0 <create+0x164>
    8000539c:	40d0                	lw	a2,4(s1)
    8000539e:	00003597          	auipc	a1,0x3
    800053a2:	56258593          	addi	a1,a1,1378 # 80008900 <syscalls+0x2e0>
    800053a6:	8552                	mv	a0,s4
    800053a8:	fffff097          	auipc	ra,0xfffff
    800053ac:	c70080e7          	jalr	-912(ra) # 80004018 <dirlink>
    800053b0:	02054863          	bltz	a0,800053e0 <create+0x164>
  if(dirlink(dp, name, ip->inum) < 0)
    800053b4:	004a2603          	lw	a2,4(s4)
    800053b8:	fb040593          	addi	a1,s0,-80
    800053bc:	8526                	mv	a0,s1
    800053be:	fffff097          	auipc	ra,0xfffff
    800053c2:	c5a080e7          	jalr	-934(ra) # 80004018 <dirlink>
    800053c6:	00054d63          	bltz	a0,800053e0 <create+0x164>
    dp->nlink++;  // for ".."
    800053ca:	04a4d783          	lhu	a5,74(s1)
    800053ce:	2785                	addiw	a5,a5,1
    800053d0:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800053d4:	8526                	mv	a0,s1
    800053d6:	ffffe097          	auipc	ra,0xffffe
    800053da:	484080e7          	jalr	1156(ra) # 8000385a <iupdate>
    800053de:	b761                	j	80005366 <create+0xea>
  ip->nlink = 0;
    800053e0:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800053e4:	8552                	mv	a0,s4
    800053e6:	ffffe097          	auipc	ra,0xffffe
    800053ea:	474080e7          	jalr	1140(ra) # 8000385a <iupdate>
  iunlockput(ip);
    800053ee:	8552                	mv	a0,s4
    800053f0:	ffffe097          	auipc	ra,0xffffe
    800053f4:	796080e7          	jalr	1942(ra) # 80003b86 <iunlockput>
  iunlockput(dp);
    800053f8:	8526                	mv	a0,s1
    800053fa:	ffffe097          	auipc	ra,0xffffe
    800053fe:	78c080e7          	jalr	1932(ra) # 80003b86 <iunlockput>
  return 0;
    80005402:	bdc5                	j	800052f2 <create+0x76>
    return 0;
    80005404:	8aaa                	mv	s5,a0
    80005406:	b5f5                	j	800052f2 <create+0x76>

0000000080005408 <sys_dup>:
{
    80005408:	7179                	addi	sp,sp,-48
    8000540a:	f406                	sd	ra,40(sp)
    8000540c:	f022                	sd	s0,32(sp)
    8000540e:	ec26                	sd	s1,24(sp)
    80005410:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005412:	fd840613          	addi	a2,s0,-40
    80005416:	4581                	li	a1,0
    80005418:	4501                	li	a0,0
    8000541a:	00000097          	auipc	ra,0x0
    8000541e:	dc0080e7          	jalr	-576(ra) # 800051da <argfd>
    return -1;
    80005422:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005424:	02054363          	bltz	a0,8000544a <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005428:	fd843503          	ld	a0,-40(s0)
    8000542c:	00000097          	auipc	ra,0x0
    80005430:	e0e080e7          	jalr	-498(ra) # 8000523a <fdalloc>
    80005434:	84aa                	mv	s1,a0
    return -1;
    80005436:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005438:	00054963          	bltz	a0,8000544a <sys_dup+0x42>
  filedup(f);
    8000543c:	fd843503          	ld	a0,-40(s0)
    80005440:	fffff097          	auipc	ra,0xfffff
    80005444:	320080e7          	jalr	800(ra) # 80004760 <filedup>
  return fd;
    80005448:	87a6                	mv	a5,s1
}
    8000544a:	853e                	mv	a0,a5
    8000544c:	70a2                	ld	ra,40(sp)
    8000544e:	7402                	ld	s0,32(sp)
    80005450:	64e2                	ld	s1,24(sp)
    80005452:	6145                	addi	sp,sp,48
    80005454:	8082                	ret

0000000080005456 <sys_read>:
{
    80005456:	7179                	addi	sp,sp,-48
    80005458:	f406                	sd	ra,40(sp)
    8000545a:	f022                	sd	s0,32(sp)
    8000545c:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000545e:	fd840593          	addi	a1,s0,-40
    80005462:	4505                	li	a0,1
    80005464:	ffffd097          	auipc	ra,0xffffd
    80005468:	79e080e7          	jalr	1950(ra) # 80002c02 <argaddr>
  argint(2, &n);
    8000546c:	fe440593          	addi	a1,s0,-28
    80005470:	4509                	li	a0,2
    80005472:	ffffd097          	auipc	ra,0xffffd
    80005476:	770080e7          	jalr	1904(ra) # 80002be2 <argint>
  if(argfd(0, 0, &f) < 0)
    8000547a:	fe840613          	addi	a2,s0,-24
    8000547e:	4581                	li	a1,0
    80005480:	4501                	li	a0,0
    80005482:	00000097          	auipc	ra,0x0
    80005486:	d58080e7          	jalr	-680(ra) # 800051da <argfd>
    8000548a:	87aa                	mv	a5,a0
    return -1;
    8000548c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000548e:	0007cc63          	bltz	a5,800054a6 <sys_read+0x50>
  return fileread(f, p, n);
    80005492:	fe442603          	lw	a2,-28(s0)
    80005496:	fd843583          	ld	a1,-40(s0)
    8000549a:	fe843503          	ld	a0,-24(s0)
    8000549e:	fffff097          	auipc	ra,0xfffff
    800054a2:	44e080e7          	jalr	1102(ra) # 800048ec <fileread>
}
    800054a6:	70a2                	ld	ra,40(sp)
    800054a8:	7402                	ld	s0,32(sp)
    800054aa:	6145                	addi	sp,sp,48
    800054ac:	8082                	ret

00000000800054ae <sys_write>:
{
    800054ae:	7179                	addi	sp,sp,-48
    800054b0:	f406                	sd	ra,40(sp)
    800054b2:	f022                	sd	s0,32(sp)
    800054b4:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800054b6:	fd840593          	addi	a1,s0,-40
    800054ba:	4505                	li	a0,1
    800054bc:	ffffd097          	auipc	ra,0xffffd
    800054c0:	746080e7          	jalr	1862(ra) # 80002c02 <argaddr>
  argint(2, &n);
    800054c4:	fe440593          	addi	a1,s0,-28
    800054c8:	4509                	li	a0,2
    800054ca:	ffffd097          	auipc	ra,0xffffd
    800054ce:	718080e7          	jalr	1816(ra) # 80002be2 <argint>
  if(argfd(0, 0, &f) < 0)
    800054d2:	fe840613          	addi	a2,s0,-24
    800054d6:	4581                	li	a1,0
    800054d8:	4501                	li	a0,0
    800054da:	00000097          	auipc	ra,0x0
    800054de:	d00080e7          	jalr	-768(ra) # 800051da <argfd>
    800054e2:	87aa                	mv	a5,a0
    return -1;
    800054e4:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800054e6:	0007cc63          	bltz	a5,800054fe <sys_write+0x50>
  return filewrite(f, p, n);
    800054ea:	fe442603          	lw	a2,-28(s0)
    800054ee:	fd843583          	ld	a1,-40(s0)
    800054f2:	fe843503          	ld	a0,-24(s0)
    800054f6:	fffff097          	auipc	ra,0xfffff
    800054fa:	4b8080e7          	jalr	1208(ra) # 800049ae <filewrite>
}
    800054fe:	70a2                	ld	ra,40(sp)
    80005500:	7402                	ld	s0,32(sp)
    80005502:	6145                	addi	sp,sp,48
    80005504:	8082                	ret

0000000080005506 <sys_close>:
{
    80005506:	1101                	addi	sp,sp,-32
    80005508:	ec06                	sd	ra,24(sp)
    8000550a:	e822                	sd	s0,16(sp)
    8000550c:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000550e:	fe040613          	addi	a2,s0,-32
    80005512:	fec40593          	addi	a1,s0,-20
    80005516:	4501                	li	a0,0
    80005518:	00000097          	auipc	ra,0x0
    8000551c:	cc2080e7          	jalr	-830(ra) # 800051da <argfd>
    return -1;
    80005520:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005522:	02054463          	bltz	a0,8000554a <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005526:	ffffc097          	auipc	ra,0xffffc
    8000552a:	4a0080e7          	jalr	1184(ra) # 800019c6 <myproc>
    8000552e:	fec42783          	lw	a5,-20(s0)
    80005532:	07e9                	addi	a5,a5,26
    80005534:	078e                	slli	a5,a5,0x3
    80005536:	97aa                	add	a5,a5,a0
    80005538:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000553c:	fe043503          	ld	a0,-32(s0)
    80005540:	fffff097          	auipc	ra,0xfffff
    80005544:	272080e7          	jalr	626(ra) # 800047b2 <fileclose>
  return 0;
    80005548:	4781                	li	a5,0
}
    8000554a:	853e                	mv	a0,a5
    8000554c:	60e2                	ld	ra,24(sp)
    8000554e:	6442                	ld	s0,16(sp)
    80005550:	6105                	addi	sp,sp,32
    80005552:	8082                	ret

0000000080005554 <sys_fstat>:
{
    80005554:	1101                	addi	sp,sp,-32
    80005556:	ec06                	sd	ra,24(sp)
    80005558:	e822                	sd	s0,16(sp)
    8000555a:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    8000555c:	fe040593          	addi	a1,s0,-32
    80005560:	4505                	li	a0,1
    80005562:	ffffd097          	auipc	ra,0xffffd
    80005566:	6a0080e7          	jalr	1696(ra) # 80002c02 <argaddr>
  if(argfd(0, 0, &f) < 0)
    8000556a:	fe840613          	addi	a2,s0,-24
    8000556e:	4581                	li	a1,0
    80005570:	4501                	li	a0,0
    80005572:	00000097          	auipc	ra,0x0
    80005576:	c68080e7          	jalr	-920(ra) # 800051da <argfd>
    8000557a:	87aa                	mv	a5,a0
    return -1;
    8000557c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000557e:	0007ca63          	bltz	a5,80005592 <sys_fstat+0x3e>
  return filestat(f, st);
    80005582:	fe043583          	ld	a1,-32(s0)
    80005586:	fe843503          	ld	a0,-24(s0)
    8000558a:	fffff097          	auipc	ra,0xfffff
    8000558e:	2f0080e7          	jalr	752(ra) # 8000487a <filestat>
}
    80005592:	60e2                	ld	ra,24(sp)
    80005594:	6442                	ld	s0,16(sp)
    80005596:	6105                	addi	sp,sp,32
    80005598:	8082                	ret

000000008000559a <sys_link>:
{
    8000559a:	7169                	addi	sp,sp,-304
    8000559c:	f606                	sd	ra,296(sp)
    8000559e:	f222                	sd	s0,288(sp)
    800055a0:	ee26                	sd	s1,280(sp)
    800055a2:	ea4a                	sd	s2,272(sp)
    800055a4:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055a6:	08000613          	li	a2,128
    800055aa:	ed040593          	addi	a1,s0,-304
    800055ae:	4501                	li	a0,0
    800055b0:	ffffd097          	auipc	ra,0xffffd
    800055b4:	672080e7          	jalr	1650(ra) # 80002c22 <argstr>
    return -1;
    800055b8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055ba:	10054e63          	bltz	a0,800056d6 <sys_link+0x13c>
    800055be:	08000613          	li	a2,128
    800055c2:	f5040593          	addi	a1,s0,-176
    800055c6:	4505                	li	a0,1
    800055c8:	ffffd097          	auipc	ra,0xffffd
    800055cc:	65a080e7          	jalr	1626(ra) # 80002c22 <argstr>
    return -1;
    800055d0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800055d2:	10054263          	bltz	a0,800056d6 <sys_link+0x13c>
  begin_op();
    800055d6:	fffff097          	auipc	ra,0xfffff
    800055da:	d10080e7          	jalr	-752(ra) # 800042e6 <begin_op>
  if((ip = namei(old)) == 0){
    800055de:	ed040513          	addi	a0,s0,-304
    800055e2:	fffff097          	auipc	ra,0xfffff
    800055e6:	ae8080e7          	jalr	-1304(ra) # 800040ca <namei>
    800055ea:	84aa                	mv	s1,a0
    800055ec:	c551                	beqz	a0,80005678 <sys_link+0xde>
  ilock(ip);
    800055ee:	ffffe097          	auipc	ra,0xffffe
    800055f2:	336080e7          	jalr	822(ra) # 80003924 <ilock>
  if(ip->type == T_DIR){
    800055f6:	04449703          	lh	a4,68(s1)
    800055fa:	4785                	li	a5,1
    800055fc:	08f70463          	beq	a4,a5,80005684 <sys_link+0xea>
  ip->nlink++;
    80005600:	04a4d783          	lhu	a5,74(s1)
    80005604:	2785                	addiw	a5,a5,1
    80005606:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000560a:	8526                	mv	a0,s1
    8000560c:	ffffe097          	auipc	ra,0xffffe
    80005610:	24e080e7          	jalr	590(ra) # 8000385a <iupdate>
  iunlock(ip);
    80005614:	8526                	mv	a0,s1
    80005616:	ffffe097          	auipc	ra,0xffffe
    8000561a:	3d0080e7          	jalr	976(ra) # 800039e6 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000561e:	fd040593          	addi	a1,s0,-48
    80005622:	f5040513          	addi	a0,s0,-176
    80005626:	fffff097          	auipc	ra,0xfffff
    8000562a:	ac2080e7          	jalr	-1342(ra) # 800040e8 <nameiparent>
    8000562e:	892a                	mv	s2,a0
    80005630:	c935                	beqz	a0,800056a4 <sys_link+0x10a>
  ilock(dp);
    80005632:	ffffe097          	auipc	ra,0xffffe
    80005636:	2f2080e7          	jalr	754(ra) # 80003924 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000563a:	00092703          	lw	a4,0(s2)
    8000563e:	409c                	lw	a5,0(s1)
    80005640:	04f71d63          	bne	a4,a5,8000569a <sys_link+0x100>
    80005644:	40d0                	lw	a2,4(s1)
    80005646:	fd040593          	addi	a1,s0,-48
    8000564a:	854a                	mv	a0,s2
    8000564c:	fffff097          	auipc	ra,0xfffff
    80005650:	9cc080e7          	jalr	-1588(ra) # 80004018 <dirlink>
    80005654:	04054363          	bltz	a0,8000569a <sys_link+0x100>
  iunlockput(dp);
    80005658:	854a                	mv	a0,s2
    8000565a:	ffffe097          	auipc	ra,0xffffe
    8000565e:	52c080e7          	jalr	1324(ra) # 80003b86 <iunlockput>
  iput(ip);
    80005662:	8526                	mv	a0,s1
    80005664:	ffffe097          	auipc	ra,0xffffe
    80005668:	47a080e7          	jalr	1146(ra) # 80003ade <iput>
  end_op();
    8000566c:	fffff097          	auipc	ra,0xfffff
    80005670:	cfa080e7          	jalr	-774(ra) # 80004366 <end_op>
  return 0;
    80005674:	4781                	li	a5,0
    80005676:	a085                	j	800056d6 <sys_link+0x13c>
    end_op();
    80005678:	fffff097          	auipc	ra,0xfffff
    8000567c:	cee080e7          	jalr	-786(ra) # 80004366 <end_op>
    return -1;
    80005680:	57fd                	li	a5,-1
    80005682:	a891                	j	800056d6 <sys_link+0x13c>
    iunlockput(ip);
    80005684:	8526                	mv	a0,s1
    80005686:	ffffe097          	auipc	ra,0xffffe
    8000568a:	500080e7          	jalr	1280(ra) # 80003b86 <iunlockput>
    end_op();
    8000568e:	fffff097          	auipc	ra,0xfffff
    80005692:	cd8080e7          	jalr	-808(ra) # 80004366 <end_op>
    return -1;
    80005696:	57fd                	li	a5,-1
    80005698:	a83d                	j	800056d6 <sys_link+0x13c>
    iunlockput(dp);
    8000569a:	854a                	mv	a0,s2
    8000569c:	ffffe097          	auipc	ra,0xffffe
    800056a0:	4ea080e7          	jalr	1258(ra) # 80003b86 <iunlockput>
  ilock(ip);
    800056a4:	8526                	mv	a0,s1
    800056a6:	ffffe097          	auipc	ra,0xffffe
    800056aa:	27e080e7          	jalr	638(ra) # 80003924 <ilock>
  ip->nlink--;
    800056ae:	04a4d783          	lhu	a5,74(s1)
    800056b2:	37fd                	addiw	a5,a5,-1
    800056b4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056b8:	8526                	mv	a0,s1
    800056ba:	ffffe097          	auipc	ra,0xffffe
    800056be:	1a0080e7          	jalr	416(ra) # 8000385a <iupdate>
  iunlockput(ip);
    800056c2:	8526                	mv	a0,s1
    800056c4:	ffffe097          	auipc	ra,0xffffe
    800056c8:	4c2080e7          	jalr	1218(ra) # 80003b86 <iunlockput>
  end_op();
    800056cc:	fffff097          	auipc	ra,0xfffff
    800056d0:	c9a080e7          	jalr	-870(ra) # 80004366 <end_op>
  return -1;
    800056d4:	57fd                	li	a5,-1
}
    800056d6:	853e                	mv	a0,a5
    800056d8:	70b2                	ld	ra,296(sp)
    800056da:	7412                	ld	s0,288(sp)
    800056dc:	64f2                	ld	s1,280(sp)
    800056de:	6952                	ld	s2,272(sp)
    800056e0:	6155                	addi	sp,sp,304
    800056e2:	8082                	ret

00000000800056e4 <sys_unlink>:
{
    800056e4:	7151                	addi	sp,sp,-240
    800056e6:	f586                	sd	ra,232(sp)
    800056e8:	f1a2                	sd	s0,224(sp)
    800056ea:	eda6                	sd	s1,216(sp)
    800056ec:	e9ca                	sd	s2,208(sp)
    800056ee:	e5ce                	sd	s3,200(sp)
    800056f0:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800056f2:	08000613          	li	a2,128
    800056f6:	f3040593          	addi	a1,s0,-208
    800056fa:	4501                	li	a0,0
    800056fc:	ffffd097          	auipc	ra,0xffffd
    80005700:	526080e7          	jalr	1318(ra) # 80002c22 <argstr>
    80005704:	18054163          	bltz	a0,80005886 <sys_unlink+0x1a2>
  begin_op();
    80005708:	fffff097          	auipc	ra,0xfffff
    8000570c:	bde080e7          	jalr	-1058(ra) # 800042e6 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005710:	fb040593          	addi	a1,s0,-80
    80005714:	f3040513          	addi	a0,s0,-208
    80005718:	fffff097          	auipc	ra,0xfffff
    8000571c:	9d0080e7          	jalr	-1584(ra) # 800040e8 <nameiparent>
    80005720:	84aa                	mv	s1,a0
    80005722:	c979                	beqz	a0,800057f8 <sys_unlink+0x114>
  ilock(dp);
    80005724:	ffffe097          	auipc	ra,0xffffe
    80005728:	200080e7          	jalr	512(ra) # 80003924 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000572c:	00003597          	auipc	a1,0x3
    80005730:	1cc58593          	addi	a1,a1,460 # 800088f8 <syscalls+0x2d8>
    80005734:	fb040513          	addi	a0,s0,-80
    80005738:	ffffe097          	auipc	ra,0xffffe
    8000573c:	6b6080e7          	jalr	1718(ra) # 80003dee <namecmp>
    80005740:	14050a63          	beqz	a0,80005894 <sys_unlink+0x1b0>
    80005744:	00003597          	auipc	a1,0x3
    80005748:	1bc58593          	addi	a1,a1,444 # 80008900 <syscalls+0x2e0>
    8000574c:	fb040513          	addi	a0,s0,-80
    80005750:	ffffe097          	auipc	ra,0xffffe
    80005754:	69e080e7          	jalr	1694(ra) # 80003dee <namecmp>
    80005758:	12050e63          	beqz	a0,80005894 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    8000575c:	f2c40613          	addi	a2,s0,-212
    80005760:	fb040593          	addi	a1,s0,-80
    80005764:	8526                	mv	a0,s1
    80005766:	ffffe097          	auipc	ra,0xffffe
    8000576a:	6a2080e7          	jalr	1698(ra) # 80003e08 <dirlookup>
    8000576e:	892a                	mv	s2,a0
    80005770:	12050263          	beqz	a0,80005894 <sys_unlink+0x1b0>
  ilock(ip);
    80005774:	ffffe097          	auipc	ra,0xffffe
    80005778:	1b0080e7          	jalr	432(ra) # 80003924 <ilock>
  if(ip->nlink < 1)
    8000577c:	04a91783          	lh	a5,74(s2)
    80005780:	08f05263          	blez	a5,80005804 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005784:	04491703          	lh	a4,68(s2)
    80005788:	4785                	li	a5,1
    8000578a:	08f70563          	beq	a4,a5,80005814 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000578e:	4641                	li	a2,16
    80005790:	4581                	li	a1,0
    80005792:	fc040513          	addi	a0,s0,-64
    80005796:	ffffb097          	auipc	ra,0xffffb
    8000579a:	550080e7          	jalr	1360(ra) # 80000ce6 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000579e:	4741                	li	a4,16
    800057a0:	f2c42683          	lw	a3,-212(s0)
    800057a4:	fc040613          	addi	a2,s0,-64
    800057a8:	4581                	li	a1,0
    800057aa:	8526                	mv	a0,s1
    800057ac:	ffffe097          	auipc	ra,0xffffe
    800057b0:	524080e7          	jalr	1316(ra) # 80003cd0 <writei>
    800057b4:	47c1                	li	a5,16
    800057b6:	0af51563          	bne	a0,a5,80005860 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800057ba:	04491703          	lh	a4,68(s2)
    800057be:	4785                	li	a5,1
    800057c0:	0af70863          	beq	a4,a5,80005870 <sys_unlink+0x18c>
  iunlockput(dp);
    800057c4:	8526                	mv	a0,s1
    800057c6:	ffffe097          	auipc	ra,0xffffe
    800057ca:	3c0080e7          	jalr	960(ra) # 80003b86 <iunlockput>
  ip->nlink--;
    800057ce:	04a95783          	lhu	a5,74(s2)
    800057d2:	37fd                	addiw	a5,a5,-1
    800057d4:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800057d8:	854a                	mv	a0,s2
    800057da:	ffffe097          	auipc	ra,0xffffe
    800057de:	080080e7          	jalr	128(ra) # 8000385a <iupdate>
  iunlockput(ip);
    800057e2:	854a                	mv	a0,s2
    800057e4:	ffffe097          	auipc	ra,0xffffe
    800057e8:	3a2080e7          	jalr	930(ra) # 80003b86 <iunlockput>
  end_op();
    800057ec:	fffff097          	auipc	ra,0xfffff
    800057f0:	b7a080e7          	jalr	-1158(ra) # 80004366 <end_op>
  return 0;
    800057f4:	4501                	li	a0,0
    800057f6:	a84d                	j	800058a8 <sys_unlink+0x1c4>
    end_op();
    800057f8:	fffff097          	auipc	ra,0xfffff
    800057fc:	b6e080e7          	jalr	-1170(ra) # 80004366 <end_op>
    return -1;
    80005800:	557d                	li	a0,-1
    80005802:	a05d                	j	800058a8 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005804:	00003517          	auipc	a0,0x3
    80005808:	10450513          	addi	a0,a0,260 # 80008908 <syscalls+0x2e8>
    8000580c:	ffffb097          	auipc	ra,0xffffb
    80005810:	d38080e7          	jalr	-712(ra) # 80000544 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005814:	04c92703          	lw	a4,76(s2)
    80005818:	02000793          	li	a5,32
    8000581c:	f6e7f9e3          	bgeu	a5,a4,8000578e <sys_unlink+0xaa>
    80005820:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005824:	4741                	li	a4,16
    80005826:	86ce                	mv	a3,s3
    80005828:	f1840613          	addi	a2,s0,-232
    8000582c:	4581                	li	a1,0
    8000582e:	854a                	mv	a0,s2
    80005830:	ffffe097          	auipc	ra,0xffffe
    80005834:	3a8080e7          	jalr	936(ra) # 80003bd8 <readi>
    80005838:	47c1                	li	a5,16
    8000583a:	00f51b63          	bne	a0,a5,80005850 <sys_unlink+0x16c>
    if(de.inum != 0)
    8000583e:	f1845783          	lhu	a5,-232(s0)
    80005842:	e7a1                	bnez	a5,8000588a <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005844:	29c1                	addiw	s3,s3,16
    80005846:	04c92783          	lw	a5,76(s2)
    8000584a:	fcf9ede3          	bltu	s3,a5,80005824 <sys_unlink+0x140>
    8000584e:	b781                	j	8000578e <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005850:	00003517          	auipc	a0,0x3
    80005854:	0d050513          	addi	a0,a0,208 # 80008920 <syscalls+0x300>
    80005858:	ffffb097          	auipc	ra,0xffffb
    8000585c:	cec080e7          	jalr	-788(ra) # 80000544 <panic>
    panic("unlink: writei");
    80005860:	00003517          	auipc	a0,0x3
    80005864:	0d850513          	addi	a0,a0,216 # 80008938 <syscalls+0x318>
    80005868:	ffffb097          	auipc	ra,0xffffb
    8000586c:	cdc080e7          	jalr	-804(ra) # 80000544 <panic>
    dp->nlink--;
    80005870:	04a4d783          	lhu	a5,74(s1)
    80005874:	37fd                	addiw	a5,a5,-1
    80005876:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000587a:	8526                	mv	a0,s1
    8000587c:	ffffe097          	auipc	ra,0xffffe
    80005880:	fde080e7          	jalr	-34(ra) # 8000385a <iupdate>
    80005884:	b781                	j	800057c4 <sys_unlink+0xe0>
    return -1;
    80005886:	557d                	li	a0,-1
    80005888:	a005                	j	800058a8 <sys_unlink+0x1c4>
    iunlockput(ip);
    8000588a:	854a                	mv	a0,s2
    8000588c:	ffffe097          	auipc	ra,0xffffe
    80005890:	2fa080e7          	jalr	762(ra) # 80003b86 <iunlockput>
  iunlockput(dp);
    80005894:	8526                	mv	a0,s1
    80005896:	ffffe097          	auipc	ra,0xffffe
    8000589a:	2f0080e7          	jalr	752(ra) # 80003b86 <iunlockput>
  end_op();
    8000589e:	fffff097          	auipc	ra,0xfffff
    800058a2:	ac8080e7          	jalr	-1336(ra) # 80004366 <end_op>
  return -1;
    800058a6:	557d                	li	a0,-1
}
    800058a8:	70ae                	ld	ra,232(sp)
    800058aa:	740e                	ld	s0,224(sp)
    800058ac:	64ee                	ld	s1,216(sp)
    800058ae:	694e                	ld	s2,208(sp)
    800058b0:	69ae                	ld	s3,200(sp)
    800058b2:	616d                	addi	sp,sp,240
    800058b4:	8082                	ret

00000000800058b6 <sys_open>:

uint64
sys_open(void)
{
    800058b6:	7131                	addi	sp,sp,-192
    800058b8:	fd06                	sd	ra,184(sp)
    800058ba:	f922                	sd	s0,176(sp)
    800058bc:	f526                	sd	s1,168(sp)
    800058be:	f14a                	sd	s2,160(sp)
    800058c0:	ed4e                	sd	s3,152(sp)
    800058c2:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    800058c4:	f4c40593          	addi	a1,s0,-180
    800058c8:	4505                	li	a0,1
    800058ca:	ffffd097          	auipc	ra,0xffffd
    800058ce:	318080e7          	jalr	792(ra) # 80002be2 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    800058d2:	08000613          	li	a2,128
    800058d6:	f5040593          	addi	a1,s0,-176
    800058da:	4501                	li	a0,0
    800058dc:	ffffd097          	auipc	ra,0xffffd
    800058e0:	346080e7          	jalr	838(ra) # 80002c22 <argstr>
    800058e4:	87aa                	mv	a5,a0
    return -1;
    800058e6:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    800058e8:	0a07c963          	bltz	a5,8000599a <sys_open+0xe4>

  begin_op();
    800058ec:	fffff097          	auipc	ra,0xfffff
    800058f0:	9fa080e7          	jalr	-1542(ra) # 800042e6 <begin_op>

  if(omode & O_CREATE){
    800058f4:	f4c42783          	lw	a5,-180(s0)
    800058f8:	2007f793          	andi	a5,a5,512
    800058fc:	cfc5                	beqz	a5,800059b4 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800058fe:	4681                	li	a3,0
    80005900:	4601                	li	a2,0
    80005902:	4589                	li	a1,2
    80005904:	f5040513          	addi	a0,s0,-176
    80005908:	00000097          	auipc	ra,0x0
    8000590c:	974080e7          	jalr	-1676(ra) # 8000527c <create>
    80005910:	84aa                	mv	s1,a0
    if(ip == 0){
    80005912:	c959                	beqz	a0,800059a8 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005914:	04449703          	lh	a4,68(s1)
    80005918:	478d                	li	a5,3
    8000591a:	00f71763          	bne	a4,a5,80005928 <sys_open+0x72>
    8000591e:	0464d703          	lhu	a4,70(s1)
    80005922:	47a5                	li	a5,9
    80005924:	0ce7ed63          	bltu	a5,a4,800059fe <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005928:	fffff097          	auipc	ra,0xfffff
    8000592c:	dce080e7          	jalr	-562(ra) # 800046f6 <filealloc>
    80005930:	89aa                	mv	s3,a0
    80005932:	10050363          	beqz	a0,80005a38 <sys_open+0x182>
    80005936:	00000097          	auipc	ra,0x0
    8000593a:	904080e7          	jalr	-1788(ra) # 8000523a <fdalloc>
    8000593e:	892a                	mv	s2,a0
    80005940:	0e054763          	bltz	a0,80005a2e <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005944:	04449703          	lh	a4,68(s1)
    80005948:	478d                	li	a5,3
    8000594a:	0cf70563          	beq	a4,a5,80005a14 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000594e:	4789                	li	a5,2
    80005950:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005954:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005958:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000595c:	f4c42783          	lw	a5,-180(s0)
    80005960:	0017c713          	xori	a4,a5,1
    80005964:	8b05                	andi	a4,a4,1
    80005966:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000596a:	0037f713          	andi	a4,a5,3
    8000596e:	00e03733          	snez	a4,a4
    80005972:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005976:	4007f793          	andi	a5,a5,1024
    8000597a:	c791                	beqz	a5,80005986 <sys_open+0xd0>
    8000597c:	04449703          	lh	a4,68(s1)
    80005980:	4789                	li	a5,2
    80005982:	0af70063          	beq	a4,a5,80005a22 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005986:	8526                	mv	a0,s1
    80005988:	ffffe097          	auipc	ra,0xffffe
    8000598c:	05e080e7          	jalr	94(ra) # 800039e6 <iunlock>
  end_op();
    80005990:	fffff097          	auipc	ra,0xfffff
    80005994:	9d6080e7          	jalr	-1578(ra) # 80004366 <end_op>

  return fd;
    80005998:	854a                	mv	a0,s2
}
    8000599a:	70ea                	ld	ra,184(sp)
    8000599c:	744a                	ld	s0,176(sp)
    8000599e:	74aa                	ld	s1,168(sp)
    800059a0:	790a                	ld	s2,160(sp)
    800059a2:	69ea                	ld	s3,152(sp)
    800059a4:	6129                	addi	sp,sp,192
    800059a6:	8082                	ret
      end_op();
    800059a8:	fffff097          	auipc	ra,0xfffff
    800059ac:	9be080e7          	jalr	-1602(ra) # 80004366 <end_op>
      return -1;
    800059b0:	557d                	li	a0,-1
    800059b2:	b7e5                	j	8000599a <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800059b4:	f5040513          	addi	a0,s0,-176
    800059b8:	ffffe097          	auipc	ra,0xffffe
    800059bc:	712080e7          	jalr	1810(ra) # 800040ca <namei>
    800059c0:	84aa                	mv	s1,a0
    800059c2:	c905                	beqz	a0,800059f2 <sys_open+0x13c>
    ilock(ip);
    800059c4:	ffffe097          	auipc	ra,0xffffe
    800059c8:	f60080e7          	jalr	-160(ra) # 80003924 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800059cc:	04449703          	lh	a4,68(s1)
    800059d0:	4785                	li	a5,1
    800059d2:	f4f711e3          	bne	a4,a5,80005914 <sys_open+0x5e>
    800059d6:	f4c42783          	lw	a5,-180(s0)
    800059da:	d7b9                	beqz	a5,80005928 <sys_open+0x72>
      iunlockput(ip);
    800059dc:	8526                	mv	a0,s1
    800059de:	ffffe097          	auipc	ra,0xffffe
    800059e2:	1a8080e7          	jalr	424(ra) # 80003b86 <iunlockput>
      end_op();
    800059e6:	fffff097          	auipc	ra,0xfffff
    800059ea:	980080e7          	jalr	-1664(ra) # 80004366 <end_op>
      return -1;
    800059ee:	557d                	li	a0,-1
    800059f0:	b76d                	j	8000599a <sys_open+0xe4>
      end_op();
    800059f2:	fffff097          	auipc	ra,0xfffff
    800059f6:	974080e7          	jalr	-1676(ra) # 80004366 <end_op>
      return -1;
    800059fa:	557d                	li	a0,-1
    800059fc:	bf79                	j	8000599a <sys_open+0xe4>
    iunlockput(ip);
    800059fe:	8526                	mv	a0,s1
    80005a00:	ffffe097          	auipc	ra,0xffffe
    80005a04:	186080e7          	jalr	390(ra) # 80003b86 <iunlockput>
    end_op();
    80005a08:	fffff097          	auipc	ra,0xfffff
    80005a0c:	95e080e7          	jalr	-1698(ra) # 80004366 <end_op>
    return -1;
    80005a10:	557d                	li	a0,-1
    80005a12:	b761                	j	8000599a <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005a14:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005a18:	04649783          	lh	a5,70(s1)
    80005a1c:	02f99223          	sh	a5,36(s3)
    80005a20:	bf25                	j	80005958 <sys_open+0xa2>
    itrunc(ip);
    80005a22:	8526                	mv	a0,s1
    80005a24:	ffffe097          	auipc	ra,0xffffe
    80005a28:	00e080e7          	jalr	14(ra) # 80003a32 <itrunc>
    80005a2c:	bfa9                	j	80005986 <sys_open+0xd0>
      fileclose(f);
    80005a2e:	854e                	mv	a0,s3
    80005a30:	fffff097          	auipc	ra,0xfffff
    80005a34:	d82080e7          	jalr	-638(ra) # 800047b2 <fileclose>
    iunlockput(ip);
    80005a38:	8526                	mv	a0,s1
    80005a3a:	ffffe097          	auipc	ra,0xffffe
    80005a3e:	14c080e7          	jalr	332(ra) # 80003b86 <iunlockput>
    end_op();
    80005a42:	fffff097          	auipc	ra,0xfffff
    80005a46:	924080e7          	jalr	-1756(ra) # 80004366 <end_op>
    return -1;
    80005a4a:	557d                	li	a0,-1
    80005a4c:	b7b9                	j	8000599a <sys_open+0xe4>

0000000080005a4e <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005a4e:	7175                	addi	sp,sp,-144
    80005a50:	e506                	sd	ra,136(sp)
    80005a52:	e122                	sd	s0,128(sp)
    80005a54:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005a56:	fffff097          	auipc	ra,0xfffff
    80005a5a:	890080e7          	jalr	-1904(ra) # 800042e6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005a5e:	08000613          	li	a2,128
    80005a62:	f7040593          	addi	a1,s0,-144
    80005a66:	4501                	li	a0,0
    80005a68:	ffffd097          	auipc	ra,0xffffd
    80005a6c:	1ba080e7          	jalr	442(ra) # 80002c22 <argstr>
    80005a70:	02054963          	bltz	a0,80005aa2 <sys_mkdir+0x54>
    80005a74:	4681                	li	a3,0
    80005a76:	4601                	li	a2,0
    80005a78:	4585                	li	a1,1
    80005a7a:	f7040513          	addi	a0,s0,-144
    80005a7e:	fffff097          	auipc	ra,0xfffff
    80005a82:	7fe080e7          	jalr	2046(ra) # 8000527c <create>
    80005a86:	cd11                	beqz	a0,80005aa2 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a88:	ffffe097          	auipc	ra,0xffffe
    80005a8c:	0fe080e7          	jalr	254(ra) # 80003b86 <iunlockput>
  end_op();
    80005a90:	fffff097          	auipc	ra,0xfffff
    80005a94:	8d6080e7          	jalr	-1834(ra) # 80004366 <end_op>
  return 0;
    80005a98:	4501                	li	a0,0
}
    80005a9a:	60aa                	ld	ra,136(sp)
    80005a9c:	640a                	ld	s0,128(sp)
    80005a9e:	6149                	addi	sp,sp,144
    80005aa0:	8082                	ret
    end_op();
    80005aa2:	fffff097          	auipc	ra,0xfffff
    80005aa6:	8c4080e7          	jalr	-1852(ra) # 80004366 <end_op>
    return -1;
    80005aaa:	557d                	li	a0,-1
    80005aac:	b7fd                	j	80005a9a <sys_mkdir+0x4c>

0000000080005aae <sys_mknod>:

uint64
sys_mknod(void)
{
    80005aae:	7135                	addi	sp,sp,-160
    80005ab0:	ed06                	sd	ra,152(sp)
    80005ab2:	e922                	sd	s0,144(sp)
    80005ab4:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005ab6:	fffff097          	auipc	ra,0xfffff
    80005aba:	830080e7          	jalr	-2000(ra) # 800042e6 <begin_op>
  argint(1, &major);
    80005abe:	f6c40593          	addi	a1,s0,-148
    80005ac2:	4505                	li	a0,1
    80005ac4:	ffffd097          	auipc	ra,0xffffd
    80005ac8:	11e080e7          	jalr	286(ra) # 80002be2 <argint>
  argint(2, &minor);
    80005acc:	f6840593          	addi	a1,s0,-152
    80005ad0:	4509                	li	a0,2
    80005ad2:	ffffd097          	auipc	ra,0xffffd
    80005ad6:	110080e7          	jalr	272(ra) # 80002be2 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ada:	08000613          	li	a2,128
    80005ade:	f7040593          	addi	a1,s0,-144
    80005ae2:	4501                	li	a0,0
    80005ae4:	ffffd097          	auipc	ra,0xffffd
    80005ae8:	13e080e7          	jalr	318(ra) # 80002c22 <argstr>
    80005aec:	02054b63          	bltz	a0,80005b22 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005af0:	f6841683          	lh	a3,-152(s0)
    80005af4:	f6c41603          	lh	a2,-148(s0)
    80005af8:	458d                	li	a1,3
    80005afa:	f7040513          	addi	a0,s0,-144
    80005afe:	fffff097          	auipc	ra,0xfffff
    80005b02:	77e080e7          	jalr	1918(ra) # 8000527c <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b06:	cd11                	beqz	a0,80005b22 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b08:	ffffe097          	auipc	ra,0xffffe
    80005b0c:	07e080e7          	jalr	126(ra) # 80003b86 <iunlockput>
  end_op();
    80005b10:	fffff097          	auipc	ra,0xfffff
    80005b14:	856080e7          	jalr	-1962(ra) # 80004366 <end_op>
  return 0;
    80005b18:	4501                	li	a0,0
}
    80005b1a:	60ea                	ld	ra,152(sp)
    80005b1c:	644a                	ld	s0,144(sp)
    80005b1e:	610d                	addi	sp,sp,160
    80005b20:	8082                	ret
    end_op();
    80005b22:	fffff097          	auipc	ra,0xfffff
    80005b26:	844080e7          	jalr	-1980(ra) # 80004366 <end_op>
    return -1;
    80005b2a:	557d                	li	a0,-1
    80005b2c:	b7fd                	j	80005b1a <sys_mknod+0x6c>

0000000080005b2e <sys_chdir>:

uint64
sys_chdir(void)
{
    80005b2e:	7135                	addi	sp,sp,-160
    80005b30:	ed06                	sd	ra,152(sp)
    80005b32:	e922                	sd	s0,144(sp)
    80005b34:	e526                	sd	s1,136(sp)
    80005b36:	e14a                	sd	s2,128(sp)
    80005b38:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005b3a:	ffffc097          	auipc	ra,0xffffc
    80005b3e:	e8c080e7          	jalr	-372(ra) # 800019c6 <myproc>
    80005b42:	892a                	mv	s2,a0
  
  begin_op();
    80005b44:	ffffe097          	auipc	ra,0xffffe
    80005b48:	7a2080e7          	jalr	1954(ra) # 800042e6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005b4c:	08000613          	li	a2,128
    80005b50:	f6040593          	addi	a1,s0,-160
    80005b54:	4501                	li	a0,0
    80005b56:	ffffd097          	auipc	ra,0xffffd
    80005b5a:	0cc080e7          	jalr	204(ra) # 80002c22 <argstr>
    80005b5e:	04054b63          	bltz	a0,80005bb4 <sys_chdir+0x86>
    80005b62:	f6040513          	addi	a0,s0,-160
    80005b66:	ffffe097          	auipc	ra,0xffffe
    80005b6a:	564080e7          	jalr	1380(ra) # 800040ca <namei>
    80005b6e:	84aa                	mv	s1,a0
    80005b70:	c131                	beqz	a0,80005bb4 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005b72:	ffffe097          	auipc	ra,0xffffe
    80005b76:	db2080e7          	jalr	-590(ra) # 80003924 <ilock>
  if(ip->type != T_DIR){
    80005b7a:	04449703          	lh	a4,68(s1)
    80005b7e:	4785                	li	a5,1
    80005b80:	04f71063          	bne	a4,a5,80005bc0 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005b84:	8526                	mv	a0,s1
    80005b86:	ffffe097          	auipc	ra,0xffffe
    80005b8a:	e60080e7          	jalr	-416(ra) # 800039e6 <iunlock>
  iput(p->cwd);
    80005b8e:	15093503          	ld	a0,336(s2)
    80005b92:	ffffe097          	auipc	ra,0xffffe
    80005b96:	f4c080e7          	jalr	-180(ra) # 80003ade <iput>
  end_op();
    80005b9a:	ffffe097          	auipc	ra,0xffffe
    80005b9e:	7cc080e7          	jalr	1996(ra) # 80004366 <end_op>
  p->cwd = ip;
    80005ba2:	14993823          	sd	s1,336(s2)
  return 0;
    80005ba6:	4501                	li	a0,0
}
    80005ba8:	60ea                	ld	ra,152(sp)
    80005baa:	644a                	ld	s0,144(sp)
    80005bac:	64aa                	ld	s1,136(sp)
    80005bae:	690a                	ld	s2,128(sp)
    80005bb0:	610d                	addi	sp,sp,160
    80005bb2:	8082                	ret
    end_op();
    80005bb4:	ffffe097          	auipc	ra,0xffffe
    80005bb8:	7b2080e7          	jalr	1970(ra) # 80004366 <end_op>
    return -1;
    80005bbc:	557d                	li	a0,-1
    80005bbe:	b7ed                	j	80005ba8 <sys_chdir+0x7a>
    iunlockput(ip);
    80005bc0:	8526                	mv	a0,s1
    80005bc2:	ffffe097          	auipc	ra,0xffffe
    80005bc6:	fc4080e7          	jalr	-60(ra) # 80003b86 <iunlockput>
    end_op();
    80005bca:	ffffe097          	auipc	ra,0xffffe
    80005bce:	79c080e7          	jalr	1948(ra) # 80004366 <end_op>
    return -1;
    80005bd2:	557d                	li	a0,-1
    80005bd4:	bfd1                	j	80005ba8 <sys_chdir+0x7a>

0000000080005bd6 <sys_exec>:

uint64
sys_exec(void)
{
    80005bd6:	7145                	addi	sp,sp,-464
    80005bd8:	e786                	sd	ra,456(sp)
    80005bda:	e3a2                	sd	s0,448(sp)
    80005bdc:	ff26                	sd	s1,440(sp)
    80005bde:	fb4a                	sd	s2,432(sp)
    80005be0:	f74e                	sd	s3,424(sp)
    80005be2:	f352                	sd	s4,416(sp)
    80005be4:	ef56                	sd	s5,408(sp)
    80005be6:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005be8:	e3840593          	addi	a1,s0,-456
    80005bec:	4505                	li	a0,1
    80005bee:	ffffd097          	auipc	ra,0xffffd
    80005bf2:	014080e7          	jalr	20(ra) # 80002c02 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005bf6:	08000613          	li	a2,128
    80005bfa:	f4040593          	addi	a1,s0,-192
    80005bfe:	4501                	li	a0,0
    80005c00:	ffffd097          	auipc	ra,0xffffd
    80005c04:	022080e7          	jalr	34(ra) # 80002c22 <argstr>
    80005c08:	87aa                	mv	a5,a0
    return -1;
    80005c0a:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005c0c:	0c07c263          	bltz	a5,80005cd0 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005c10:	10000613          	li	a2,256
    80005c14:	4581                	li	a1,0
    80005c16:	e4040513          	addi	a0,s0,-448
    80005c1a:	ffffb097          	auipc	ra,0xffffb
    80005c1e:	0cc080e7          	jalr	204(ra) # 80000ce6 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005c22:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005c26:	89a6                	mv	s3,s1
    80005c28:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005c2a:	02000a13          	li	s4,32
    80005c2e:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005c32:	00391513          	slli	a0,s2,0x3
    80005c36:	e3040593          	addi	a1,s0,-464
    80005c3a:	e3843783          	ld	a5,-456(s0)
    80005c3e:	953e                	add	a0,a0,a5
    80005c40:	ffffd097          	auipc	ra,0xffffd
    80005c44:	f04080e7          	jalr	-252(ra) # 80002b44 <fetchaddr>
    80005c48:	02054a63          	bltz	a0,80005c7c <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005c4c:	e3043783          	ld	a5,-464(s0)
    80005c50:	c3b9                	beqz	a5,80005c96 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005c52:	ffffb097          	auipc	ra,0xffffb
    80005c56:	ea8080e7          	jalr	-344(ra) # 80000afa <kalloc>
    80005c5a:	85aa                	mv	a1,a0
    80005c5c:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005c60:	cd11                	beqz	a0,80005c7c <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005c62:	6605                	lui	a2,0x1
    80005c64:	e3043503          	ld	a0,-464(s0)
    80005c68:	ffffd097          	auipc	ra,0xffffd
    80005c6c:	f2e080e7          	jalr	-210(ra) # 80002b96 <fetchstr>
    80005c70:	00054663          	bltz	a0,80005c7c <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005c74:	0905                	addi	s2,s2,1
    80005c76:	09a1                	addi	s3,s3,8
    80005c78:	fb491be3          	bne	s2,s4,80005c2e <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c7c:	10048913          	addi	s2,s1,256
    80005c80:	6088                	ld	a0,0(s1)
    80005c82:	c531                	beqz	a0,80005cce <sys_exec+0xf8>
    kfree(argv[i]);
    80005c84:	ffffb097          	auipc	ra,0xffffb
    80005c88:	d7a080e7          	jalr	-646(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c8c:	04a1                	addi	s1,s1,8
    80005c8e:	ff2499e3          	bne	s1,s2,80005c80 <sys_exec+0xaa>
  return -1;
    80005c92:	557d                	li	a0,-1
    80005c94:	a835                	j	80005cd0 <sys_exec+0xfa>
      argv[i] = 0;
    80005c96:	0a8e                	slli	s5,s5,0x3
    80005c98:	fc040793          	addi	a5,s0,-64
    80005c9c:	9abe                	add	s5,s5,a5
    80005c9e:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005ca2:	e4040593          	addi	a1,s0,-448
    80005ca6:	f4040513          	addi	a0,s0,-192
    80005caa:	fffff097          	auipc	ra,0xfffff
    80005cae:	190080e7          	jalr	400(ra) # 80004e3a <exec>
    80005cb2:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cb4:	10048993          	addi	s3,s1,256
    80005cb8:	6088                	ld	a0,0(s1)
    80005cba:	c901                	beqz	a0,80005cca <sys_exec+0xf4>
    kfree(argv[i]);
    80005cbc:	ffffb097          	auipc	ra,0xffffb
    80005cc0:	d42080e7          	jalr	-702(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005cc4:	04a1                	addi	s1,s1,8
    80005cc6:	ff3499e3          	bne	s1,s3,80005cb8 <sys_exec+0xe2>
  return ret;
    80005cca:	854a                	mv	a0,s2
    80005ccc:	a011                	j	80005cd0 <sys_exec+0xfa>
  return -1;
    80005cce:	557d                	li	a0,-1
}
    80005cd0:	60be                	ld	ra,456(sp)
    80005cd2:	641e                	ld	s0,448(sp)
    80005cd4:	74fa                	ld	s1,440(sp)
    80005cd6:	795a                	ld	s2,432(sp)
    80005cd8:	79ba                	ld	s3,424(sp)
    80005cda:	7a1a                	ld	s4,416(sp)
    80005cdc:	6afa                	ld	s5,408(sp)
    80005cde:	6179                	addi	sp,sp,464
    80005ce0:	8082                	ret

0000000080005ce2 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005ce2:	7139                	addi	sp,sp,-64
    80005ce4:	fc06                	sd	ra,56(sp)
    80005ce6:	f822                	sd	s0,48(sp)
    80005ce8:	f426                	sd	s1,40(sp)
    80005cea:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005cec:	ffffc097          	auipc	ra,0xffffc
    80005cf0:	cda080e7          	jalr	-806(ra) # 800019c6 <myproc>
    80005cf4:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005cf6:	fd840593          	addi	a1,s0,-40
    80005cfa:	4501                	li	a0,0
    80005cfc:	ffffd097          	auipc	ra,0xffffd
    80005d00:	f06080e7          	jalr	-250(ra) # 80002c02 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005d04:	fc840593          	addi	a1,s0,-56
    80005d08:	fd040513          	addi	a0,s0,-48
    80005d0c:	fffff097          	auipc	ra,0xfffff
    80005d10:	dd6080e7          	jalr	-554(ra) # 80004ae2 <pipealloc>
    return -1;
    80005d14:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005d16:	0c054463          	bltz	a0,80005dde <sys_pipe+0xfc>
  fd0 = -1;
    80005d1a:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005d1e:	fd043503          	ld	a0,-48(s0)
    80005d22:	fffff097          	auipc	ra,0xfffff
    80005d26:	518080e7          	jalr	1304(ra) # 8000523a <fdalloc>
    80005d2a:	fca42223          	sw	a0,-60(s0)
    80005d2e:	08054b63          	bltz	a0,80005dc4 <sys_pipe+0xe2>
    80005d32:	fc843503          	ld	a0,-56(s0)
    80005d36:	fffff097          	auipc	ra,0xfffff
    80005d3a:	504080e7          	jalr	1284(ra) # 8000523a <fdalloc>
    80005d3e:	fca42023          	sw	a0,-64(s0)
    80005d42:	06054863          	bltz	a0,80005db2 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d46:	4691                	li	a3,4
    80005d48:	fc440613          	addi	a2,s0,-60
    80005d4c:	fd843583          	ld	a1,-40(s0)
    80005d50:	68a8                	ld	a0,80(s1)
    80005d52:	ffffc097          	auipc	ra,0xffffc
    80005d56:	932080e7          	jalr	-1742(ra) # 80001684 <copyout>
    80005d5a:	02054063          	bltz	a0,80005d7a <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005d5e:	4691                	li	a3,4
    80005d60:	fc040613          	addi	a2,s0,-64
    80005d64:	fd843583          	ld	a1,-40(s0)
    80005d68:	0591                	addi	a1,a1,4
    80005d6a:	68a8                	ld	a0,80(s1)
    80005d6c:	ffffc097          	auipc	ra,0xffffc
    80005d70:	918080e7          	jalr	-1768(ra) # 80001684 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005d74:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d76:	06055463          	bgez	a0,80005dde <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005d7a:	fc442783          	lw	a5,-60(s0)
    80005d7e:	07e9                	addi	a5,a5,26
    80005d80:	078e                	slli	a5,a5,0x3
    80005d82:	97a6                	add	a5,a5,s1
    80005d84:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005d88:	fc042503          	lw	a0,-64(s0)
    80005d8c:	0569                	addi	a0,a0,26
    80005d8e:	050e                	slli	a0,a0,0x3
    80005d90:	94aa                	add	s1,s1,a0
    80005d92:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005d96:	fd043503          	ld	a0,-48(s0)
    80005d9a:	fffff097          	auipc	ra,0xfffff
    80005d9e:	a18080e7          	jalr	-1512(ra) # 800047b2 <fileclose>
    fileclose(wf);
    80005da2:	fc843503          	ld	a0,-56(s0)
    80005da6:	fffff097          	auipc	ra,0xfffff
    80005daa:	a0c080e7          	jalr	-1524(ra) # 800047b2 <fileclose>
    return -1;
    80005dae:	57fd                	li	a5,-1
    80005db0:	a03d                	j	80005dde <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005db2:	fc442783          	lw	a5,-60(s0)
    80005db6:	0007c763          	bltz	a5,80005dc4 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005dba:	07e9                	addi	a5,a5,26
    80005dbc:	078e                	slli	a5,a5,0x3
    80005dbe:	94be                	add	s1,s1,a5
    80005dc0:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005dc4:	fd043503          	ld	a0,-48(s0)
    80005dc8:	fffff097          	auipc	ra,0xfffff
    80005dcc:	9ea080e7          	jalr	-1558(ra) # 800047b2 <fileclose>
    fileclose(wf);
    80005dd0:	fc843503          	ld	a0,-56(s0)
    80005dd4:	fffff097          	auipc	ra,0xfffff
    80005dd8:	9de080e7          	jalr	-1570(ra) # 800047b2 <fileclose>
    return -1;
    80005ddc:	57fd                	li	a5,-1
}
    80005dde:	853e                	mv	a0,a5
    80005de0:	70e2                	ld	ra,56(sp)
    80005de2:	7442                	ld	s0,48(sp)
    80005de4:	74a2                	ld	s1,40(sp)
    80005de6:	6121                	addi	sp,sp,64
    80005de8:	8082                	ret
    80005dea:	0000                	unimp
    80005dec:	0000                	unimp
	...

0000000080005df0 <kernelvec>:
    80005df0:	7111                	addi	sp,sp,-256
    80005df2:	e006                	sd	ra,0(sp)
    80005df4:	e40a                	sd	sp,8(sp)
    80005df6:	e80e                	sd	gp,16(sp)
    80005df8:	ec12                	sd	tp,24(sp)
    80005dfa:	f016                	sd	t0,32(sp)
    80005dfc:	f41a                	sd	t1,40(sp)
    80005dfe:	f81e                	sd	t2,48(sp)
    80005e00:	fc22                	sd	s0,56(sp)
    80005e02:	e0a6                	sd	s1,64(sp)
    80005e04:	e4aa                	sd	a0,72(sp)
    80005e06:	e8ae                	sd	a1,80(sp)
    80005e08:	ecb2                	sd	a2,88(sp)
    80005e0a:	f0b6                	sd	a3,96(sp)
    80005e0c:	f4ba                	sd	a4,104(sp)
    80005e0e:	f8be                	sd	a5,112(sp)
    80005e10:	fcc2                	sd	a6,120(sp)
    80005e12:	e146                	sd	a7,128(sp)
    80005e14:	e54a                	sd	s2,136(sp)
    80005e16:	e94e                	sd	s3,144(sp)
    80005e18:	ed52                	sd	s4,152(sp)
    80005e1a:	f156                	sd	s5,160(sp)
    80005e1c:	f55a                	sd	s6,168(sp)
    80005e1e:	f95e                	sd	s7,176(sp)
    80005e20:	fd62                	sd	s8,184(sp)
    80005e22:	e1e6                	sd	s9,192(sp)
    80005e24:	e5ea                	sd	s10,200(sp)
    80005e26:	e9ee                	sd	s11,208(sp)
    80005e28:	edf2                	sd	t3,216(sp)
    80005e2a:	f1f6                	sd	t4,224(sp)
    80005e2c:	f5fa                	sd	t5,232(sp)
    80005e2e:	f9fe                	sd	t6,240(sp)
    80005e30:	be1fc0ef          	jal	ra,80002a10 <kerneltrap>
    80005e34:	6082                	ld	ra,0(sp)
    80005e36:	6122                	ld	sp,8(sp)
    80005e38:	61c2                	ld	gp,16(sp)
    80005e3a:	7282                	ld	t0,32(sp)
    80005e3c:	7322                	ld	t1,40(sp)
    80005e3e:	73c2                	ld	t2,48(sp)
    80005e40:	7462                	ld	s0,56(sp)
    80005e42:	6486                	ld	s1,64(sp)
    80005e44:	6526                	ld	a0,72(sp)
    80005e46:	65c6                	ld	a1,80(sp)
    80005e48:	6666                	ld	a2,88(sp)
    80005e4a:	7686                	ld	a3,96(sp)
    80005e4c:	7726                	ld	a4,104(sp)
    80005e4e:	77c6                	ld	a5,112(sp)
    80005e50:	7866                	ld	a6,120(sp)
    80005e52:	688a                	ld	a7,128(sp)
    80005e54:	692a                	ld	s2,136(sp)
    80005e56:	69ca                	ld	s3,144(sp)
    80005e58:	6a6a                	ld	s4,152(sp)
    80005e5a:	7a8a                	ld	s5,160(sp)
    80005e5c:	7b2a                	ld	s6,168(sp)
    80005e5e:	7bca                	ld	s7,176(sp)
    80005e60:	7c6a                	ld	s8,184(sp)
    80005e62:	6c8e                	ld	s9,192(sp)
    80005e64:	6d2e                	ld	s10,200(sp)
    80005e66:	6dce                	ld	s11,208(sp)
    80005e68:	6e6e                	ld	t3,216(sp)
    80005e6a:	7e8e                	ld	t4,224(sp)
    80005e6c:	7f2e                	ld	t5,232(sp)
    80005e6e:	7fce                	ld	t6,240(sp)
    80005e70:	6111                	addi	sp,sp,256
    80005e72:	10200073          	sret
    80005e76:	00000013          	nop
    80005e7a:	00000013          	nop
    80005e7e:	0001                	nop

0000000080005e80 <timervec>:
    80005e80:	34051573          	csrrw	a0,mscratch,a0
    80005e84:	e10c                	sd	a1,0(a0)
    80005e86:	e510                	sd	a2,8(a0)
    80005e88:	e914                	sd	a3,16(a0)
    80005e8a:	6d0c                	ld	a1,24(a0)
    80005e8c:	7110                	ld	a2,32(a0)
    80005e8e:	6194                	ld	a3,0(a1)
    80005e90:	96b2                	add	a3,a3,a2
    80005e92:	e194                	sd	a3,0(a1)
    80005e94:	4589                	li	a1,2
    80005e96:	14459073          	csrw	sip,a1
    80005e9a:	6914                	ld	a3,16(a0)
    80005e9c:	6510                	ld	a2,8(a0)
    80005e9e:	610c                	ld	a1,0(a0)
    80005ea0:	34051573          	csrrw	a0,mscratch,a0
    80005ea4:	30200073          	mret
	...

0000000080005eaa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005eaa:	1141                	addi	sp,sp,-16
    80005eac:	e422                	sd	s0,8(sp)
    80005eae:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005eb0:	0c0007b7          	lui	a5,0xc000
    80005eb4:	4705                	li	a4,1
    80005eb6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005eb8:	c3d8                	sw	a4,4(a5)
}
    80005eba:	6422                	ld	s0,8(sp)
    80005ebc:	0141                	addi	sp,sp,16
    80005ebe:	8082                	ret

0000000080005ec0 <plicinithart>:

void
plicinithart(void)
{
    80005ec0:	1141                	addi	sp,sp,-16
    80005ec2:	e406                	sd	ra,8(sp)
    80005ec4:	e022                	sd	s0,0(sp)
    80005ec6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005ec8:	ffffc097          	auipc	ra,0xffffc
    80005ecc:	ad2080e7          	jalr	-1326(ra) # 8000199a <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005ed0:	0085171b          	slliw	a4,a0,0x8
    80005ed4:	0c0027b7          	lui	a5,0xc002
    80005ed8:	97ba                	add	a5,a5,a4
    80005eda:	40200713          	li	a4,1026
    80005ede:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005ee2:	00d5151b          	slliw	a0,a0,0xd
    80005ee6:	0c2017b7          	lui	a5,0xc201
    80005eea:	953e                	add	a0,a0,a5
    80005eec:	00052023          	sw	zero,0(a0)
}
    80005ef0:	60a2                	ld	ra,8(sp)
    80005ef2:	6402                	ld	s0,0(sp)
    80005ef4:	0141                	addi	sp,sp,16
    80005ef6:	8082                	ret

0000000080005ef8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005ef8:	1141                	addi	sp,sp,-16
    80005efa:	e406                	sd	ra,8(sp)
    80005efc:	e022                	sd	s0,0(sp)
    80005efe:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f00:	ffffc097          	auipc	ra,0xffffc
    80005f04:	a9a080e7          	jalr	-1382(ra) # 8000199a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005f08:	00d5179b          	slliw	a5,a0,0xd
    80005f0c:	0c201537          	lui	a0,0xc201
    80005f10:	953e                	add	a0,a0,a5
  return irq;
}
    80005f12:	4148                	lw	a0,4(a0)
    80005f14:	60a2                	ld	ra,8(sp)
    80005f16:	6402                	ld	s0,0(sp)
    80005f18:	0141                	addi	sp,sp,16
    80005f1a:	8082                	ret

0000000080005f1c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005f1c:	1101                	addi	sp,sp,-32
    80005f1e:	ec06                	sd	ra,24(sp)
    80005f20:	e822                	sd	s0,16(sp)
    80005f22:	e426                	sd	s1,8(sp)
    80005f24:	1000                	addi	s0,sp,32
    80005f26:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005f28:	ffffc097          	auipc	ra,0xffffc
    80005f2c:	a72080e7          	jalr	-1422(ra) # 8000199a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005f30:	00d5151b          	slliw	a0,a0,0xd
    80005f34:	0c2017b7          	lui	a5,0xc201
    80005f38:	97aa                	add	a5,a5,a0
    80005f3a:	c3c4                	sw	s1,4(a5)
}
    80005f3c:	60e2                	ld	ra,24(sp)
    80005f3e:	6442                	ld	s0,16(sp)
    80005f40:	64a2                	ld	s1,8(sp)
    80005f42:	6105                	addi	sp,sp,32
    80005f44:	8082                	ret

0000000080005f46 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005f46:	1141                	addi	sp,sp,-16
    80005f48:	e406                	sd	ra,8(sp)
    80005f4a:	e022                	sd	s0,0(sp)
    80005f4c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005f4e:	479d                	li	a5,7
    80005f50:	04a7cc63          	blt	a5,a0,80005fa8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005f54:	00024797          	auipc	a5,0x24
    80005f58:	27478793          	addi	a5,a5,628 # 8002a1c8 <disk>
    80005f5c:	97aa                	add	a5,a5,a0
    80005f5e:	0187c783          	lbu	a5,24(a5)
    80005f62:	ebb9                	bnez	a5,80005fb8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005f64:	00451613          	slli	a2,a0,0x4
    80005f68:	00024797          	auipc	a5,0x24
    80005f6c:	26078793          	addi	a5,a5,608 # 8002a1c8 <disk>
    80005f70:	6394                	ld	a3,0(a5)
    80005f72:	96b2                	add	a3,a3,a2
    80005f74:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005f78:	6398                	ld	a4,0(a5)
    80005f7a:	9732                	add	a4,a4,a2
    80005f7c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005f80:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005f84:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005f88:	953e                	add	a0,a0,a5
    80005f8a:	4785                	li	a5,1
    80005f8c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80005f90:	00024517          	auipc	a0,0x24
    80005f94:	25050513          	addi	a0,a0,592 # 8002a1e0 <disk+0x18>
    80005f98:	ffffc097          	auipc	ra,0xffffc
    80005f9c:	1d6080e7          	jalr	470(ra) # 8000216e <wakeup>
}
    80005fa0:	60a2                	ld	ra,8(sp)
    80005fa2:	6402                	ld	s0,0(sp)
    80005fa4:	0141                	addi	sp,sp,16
    80005fa6:	8082                	ret
    panic("free_desc 1");
    80005fa8:	00003517          	auipc	a0,0x3
    80005fac:	9a050513          	addi	a0,a0,-1632 # 80008948 <syscalls+0x328>
    80005fb0:	ffffa097          	auipc	ra,0xffffa
    80005fb4:	594080e7          	jalr	1428(ra) # 80000544 <panic>
    panic("free_desc 2");
    80005fb8:	00003517          	auipc	a0,0x3
    80005fbc:	9a050513          	addi	a0,a0,-1632 # 80008958 <syscalls+0x338>
    80005fc0:	ffffa097          	auipc	ra,0xffffa
    80005fc4:	584080e7          	jalr	1412(ra) # 80000544 <panic>

0000000080005fc8 <virtio_disk_init>:
{
    80005fc8:	1101                	addi	sp,sp,-32
    80005fca:	ec06                	sd	ra,24(sp)
    80005fcc:	e822                	sd	s0,16(sp)
    80005fce:	e426                	sd	s1,8(sp)
    80005fd0:	e04a                	sd	s2,0(sp)
    80005fd2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005fd4:	00003597          	auipc	a1,0x3
    80005fd8:	99458593          	addi	a1,a1,-1644 # 80008968 <syscalls+0x348>
    80005fdc:	00024517          	auipc	a0,0x24
    80005fe0:	31450513          	addi	a0,a0,788 # 8002a2f0 <disk+0x128>
    80005fe4:	ffffb097          	auipc	ra,0xffffb
    80005fe8:	b76080e7          	jalr	-1162(ra) # 80000b5a <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005fec:	100017b7          	lui	a5,0x10001
    80005ff0:	4398                	lw	a4,0(a5)
    80005ff2:	2701                	sext.w	a4,a4
    80005ff4:	747277b7          	lui	a5,0x74727
    80005ff8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005ffc:	14f71e63          	bne	a4,a5,80006158 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006000:	100017b7          	lui	a5,0x10001
    80006004:	43dc                	lw	a5,4(a5)
    80006006:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006008:	4709                	li	a4,2
    8000600a:	14e79763          	bne	a5,a4,80006158 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000600e:	100017b7          	lui	a5,0x10001
    80006012:	479c                	lw	a5,8(a5)
    80006014:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006016:	14e79163          	bne	a5,a4,80006158 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000601a:	100017b7          	lui	a5,0x10001
    8000601e:	47d8                	lw	a4,12(a5)
    80006020:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006022:	554d47b7          	lui	a5,0x554d4
    80006026:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000602a:	12f71763          	bne	a4,a5,80006158 <virtio_disk_init+0x190>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000602e:	100017b7          	lui	a5,0x10001
    80006032:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006036:	4705                	li	a4,1
    80006038:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000603a:	470d                	li	a4,3
    8000603c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000603e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006040:	c7ffe737          	lui	a4,0xc7ffe
    80006044:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd4457>
    80006048:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000604a:	2701                	sext.w	a4,a4
    8000604c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000604e:	472d                	li	a4,11
    80006050:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006052:	0707a903          	lw	s2,112(a5)
    80006056:	2901                	sext.w	s2,s2
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006058:	00897793          	andi	a5,s2,8
    8000605c:	10078663          	beqz	a5,80006168 <virtio_disk_init+0x1a0>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006060:	100017b7          	lui	a5,0x10001
    80006064:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006068:	43fc                	lw	a5,68(a5)
    8000606a:	2781                	sext.w	a5,a5
    8000606c:	10079663          	bnez	a5,80006178 <virtio_disk_init+0x1b0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006070:	100017b7          	lui	a5,0x10001
    80006074:	5bdc                	lw	a5,52(a5)
    80006076:	2781                	sext.w	a5,a5
  if(max == 0)
    80006078:	10078863          	beqz	a5,80006188 <virtio_disk_init+0x1c0>
  if(max < NUM)
    8000607c:	471d                	li	a4,7
    8000607e:	10f77d63          	bgeu	a4,a5,80006198 <virtio_disk_init+0x1d0>
  disk.desc = kalloc();
    80006082:	ffffb097          	auipc	ra,0xffffb
    80006086:	a78080e7          	jalr	-1416(ra) # 80000afa <kalloc>
    8000608a:	00024497          	auipc	s1,0x24
    8000608e:	13e48493          	addi	s1,s1,318 # 8002a1c8 <disk>
    80006092:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006094:	ffffb097          	auipc	ra,0xffffb
    80006098:	a66080e7          	jalr	-1434(ra) # 80000afa <kalloc>
    8000609c:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000609e:	ffffb097          	auipc	ra,0xffffb
    800060a2:	a5c080e7          	jalr	-1444(ra) # 80000afa <kalloc>
    800060a6:	87aa                	mv	a5,a0
    800060a8:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800060aa:	6088                	ld	a0,0(s1)
    800060ac:	cd75                	beqz	a0,800061a8 <virtio_disk_init+0x1e0>
    800060ae:	00024717          	auipc	a4,0x24
    800060b2:	12273703          	ld	a4,290(a4) # 8002a1d0 <disk+0x8>
    800060b6:	cb6d                	beqz	a4,800061a8 <virtio_disk_init+0x1e0>
    800060b8:	cbe5                	beqz	a5,800061a8 <virtio_disk_init+0x1e0>
  memset(disk.desc, 0, PGSIZE);
    800060ba:	6605                	lui	a2,0x1
    800060bc:	4581                	li	a1,0
    800060be:	ffffb097          	auipc	ra,0xffffb
    800060c2:	c28080e7          	jalr	-984(ra) # 80000ce6 <memset>
  memset(disk.avail, 0, PGSIZE);
    800060c6:	00024497          	auipc	s1,0x24
    800060ca:	10248493          	addi	s1,s1,258 # 8002a1c8 <disk>
    800060ce:	6605                	lui	a2,0x1
    800060d0:	4581                	li	a1,0
    800060d2:	6488                	ld	a0,8(s1)
    800060d4:	ffffb097          	auipc	ra,0xffffb
    800060d8:	c12080e7          	jalr	-1006(ra) # 80000ce6 <memset>
  memset(disk.used, 0, PGSIZE);
    800060dc:	6605                	lui	a2,0x1
    800060de:	4581                	li	a1,0
    800060e0:	6888                	ld	a0,16(s1)
    800060e2:	ffffb097          	auipc	ra,0xffffb
    800060e6:	c04080e7          	jalr	-1020(ra) # 80000ce6 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800060ea:	100017b7          	lui	a5,0x10001
    800060ee:	4721                	li	a4,8
    800060f0:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800060f2:	4098                	lw	a4,0(s1)
    800060f4:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800060f8:	40d8                	lw	a4,4(s1)
    800060fa:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800060fe:	6498                	ld	a4,8(s1)
    80006100:	0007069b          	sext.w	a3,a4
    80006104:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006108:	9701                	srai	a4,a4,0x20
    8000610a:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000610e:	6898                	ld	a4,16(s1)
    80006110:	0007069b          	sext.w	a3,a4
    80006114:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006118:	9701                	srai	a4,a4,0x20
    8000611a:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000611e:	4685                	li	a3,1
    80006120:	c3f4                	sw	a3,68(a5)
    disk.free[i] = 1;
    80006122:	4705                	li	a4,1
    80006124:	00d48c23          	sb	a3,24(s1)
    80006128:	00e48ca3          	sb	a4,25(s1)
    8000612c:	00e48d23          	sb	a4,26(s1)
    80006130:	00e48da3          	sb	a4,27(s1)
    80006134:	00e48e23          	sb	a4,28(s1)
    80006138:	00e48ea3          	sb	a4,29(s1)
    8000613c:	00e48f23          	sb	a4,30(s1)
    80006140:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006144:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006148:	0727a823          	sw	s2,112(a5)
}
    8000614c:	60e2                	ld	ra,24(sp)
    8000614e:	6442                	ld	s0,16(sp)
    80006150:	64a2                	ld	s1,8(sp)
    80006152:	6902                	ld	s2,0(sp)
    80006154:	6105                	addi	sp,sp,32
    80006156:	8082                	ret
    panic("could not find virtio disk");
    80006158:	00003517          	auipc	a0,0x3
    8000615c:	82050513          	addi	a0,a0,-2016 # 80008978 <syscalls+0x358>
    80006160:	ffffa097          	auipc	ra,0xffffa
    80006164:	3e4080e7          	jalr	996(ra) # 80000544 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006168:	00003517          	auipc	a0,0x3
    8000616c:	83050513          	addi	a0,a0,-2000 # 80008998 <syscalls+0x378>
    80006170:	ffffa097          	auipc	ra,0xffffa
    80006174:	3d4080e7          	jalr	980(ra) # 80000544 <panic>
    panic("virtio disk should not be ready");
    80006178:	00003517          	auipc	a0,0x3
    8000617c:	84050513          	addi	a0,a0,-1984 # 800089b8 <syscalls+0x398>
    80006180:	ffffa097          	auipc	ra,0xffffa
    80006184:	3c4080e7          	jalr	964(ra) # 80000544 <panic>
    panic("virtio disk has no queue 0");
    80006188:	00003517          	auipc	a0,0x3
    8000618c:	85050513          	addi	a0,a0,-1968 # 800089d8 <syscalls+0x3b8>
    80006190:	ffffa097          	auipc	ra,0xffffa
    80006194:	3b4080e7          	jalr	948(ra) # 80000544 <panic>
    panic("virtio disk max queue too short");
    80006198:	00003517          	auipc	a0,0x3
    8000619c:	86050513          	addi	a0,a0,-1952 # 800089f8 <syscalls+0x3d8>
    800061a0:	ffffa097          	auipc	ra,0xffffa
    800061a4:	3a4080e7          	jalr	932(ra) # 80000544 <panic>
    panic("virtio disk kalloc");
    800061a8:	00003517          	auipc	a0,0x3
    800061ac:	87050513          	addi	a0,a0,-1936 # 80008a18 <syscalls+0x3f8>
    800061b0:	ffffa097          	auipc	ra,0xffffa
    800061b4:	394080e7          	jalr	916(ra) # 80000544 <panic>

00000000800061b8 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800061b8:	7159                	addi	sp,sp,-112
    800061ba:	f486                	sd	ra,104(sp)
    800061bc:	f0a2                	sd	s0,96(sp)
    800061be:	eca6                	sd	s1,88(sp)
    800061c0:	e8ca                	sd	s2,80(sp)
    800061c2:	e4ce                	sd	s3,72(sp)
    800061c4:	e0d2                	sd	s4,64(sp)
    800061c6:	fc56                	sd	s5,56(sp)
    800061c8:	f85a                	sd	s6,48(sp)
    800061ca:	f45e                	sd	s7,40(sp)
    800061cc:	f062                	sd	s8,32(sp)
    800061ce:	ec66                	sd	s9,24(sp)
    800061d0:	e86a                	sd	s10,16(sp)
    800061d2:	1880                	addi	s0,sp,112
    800061d4:	892a                	mv	s2,a0
    800061d6:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800061d8:	00c52c83          	lw	s9,12(a0)
    800061dc:	001c9c9b          	slliw	s9,s9,0x1
    800061e0:	1c82                	slli	s9,s9,0x20
    800061e2:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800061e6:	00024517          	auipc	a0,0x24
    800061ea:	10a50513          	addi	a0,a0,266 # 8002a2f0 <disk+0x128>
    800061ee:	ffffb097          	auipc	ra,0xffffb
    800061f2:	9fc080e7          	jalr	-1540(ra) # 80000bea <acquire>
  for(int i = 0; i < 3; i++){
    800061f6:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800061f8:	4ba1                	li	s7,8
      disk.free[i] = 0;
    800061fa:	00024b17          	auipc	s6,0x24
    800061fe:	fceb0b13          	addi	s6,s6,-50 # 8002a1c8 <disk>
  for(int i = 0; i < 3; i++){
    80006202:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006204:	8a4e                	mv	s4,s3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006206:	00024c17          	auipc	s8,0x24
    8000620a:	0eac0c13          	addi	s8,s8,234 # 8002a2f0 <disk+0x128>
    8000620e:	a8b5                	j	8000628a <virtio_disk_rw+0xd2>
      disk.free[i] = 0;
    80006210:	00fb06b3          	add	a3,s6,a5
    80006214:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006218:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    8000621a:	0207c563          	bltz	a5,80006244 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    8000621e:	2485                	addiw	s1,s1,1
    80006220:	0711                	addi	a4,a4,4
    80006222:	1f548a63          	beq	s1,s5,80006416 <virtio_disk_rw+0x25e>
    idx[i] = alloc_desc();
    80006226:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006228:	00024697          	auipc	a3,0x24
    8000622c:	fa068693          	addi	a3,a3,-96 # 8002a1c8 <disk>
    80006230:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006232:	0186c583          	lbu	a1,24(a3)
    80006236:	fde9                	bnez	a1,80006210 <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006238:	2785                	addiw	a5,a5,1
    8000623a:	0685                	addi	a3,a3,1
    8000623c:	ff779be3          	bne	a5,s7,80006232 <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    80006240:	57fd                	li	a5,-1
    80006242:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006244:	02905a63          	blez	s1,80006278 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    80006248:	f9042503          	lw	a0,-112(s0)
    8000624c:	00000097          	auipc	ra,0x0
    80006250:	cfa080e7          	jalr	-774(ra) # 80005f46 <free_desc>
      for(int j = 0; j < i; j++)
    80006254:	4785                	li	a5,1
    80006256:	0297d163          	bge	a5,s1,80006278 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    8000625a:	f9442503          	lw	a0,-108(s0)
    8000625e:	00000097          	auipc	ra,0x0
    80006262:	ce8080e7          	jalr	-792(ra) # 80005f46 <free_desc>
      for(int j = 0; j < i; j++)
    80006266:	4789                	li	a5,2
    80006268:	0097d863          	bge	a5,s1,80006278 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    8000626c:	f9842503          	lw	a0,-104(s0)
    80006270:	00000097          	auipc	ra,0x0
    80006274:	cd6080e7          	jalr	-810(ra) # 80005f46 <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006278:	85e2                	mv	a1,s8
    8000627a:	00024517          	auipc	a0,0x24
    8000627e:	f6650513          	addi	a0,a0,-154 # 8002a1e0 <disk+0x18>
    80006282:	ffffc097          	auipc	ra,0xffffc
    80006286:	e88080e7          	jalr	-376(ra) # 8000210a <sleep>
  for(int i = 0; i < 3; i++){
    8000628a:	f9040713          	addi	a4,s0,-112
    8000628e:	84ce                	mv	s1,s3
    80006290:	bf59                	j	80006226 <virtio_disk_rw+0x6e>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006292:	00a60793          	addi	a5,a2,10 # 100a <_entry-0x7fffeff6>
    80006296:	00479693          	slli	a3,a5,0x4
    8000629a:	00024797          	auipc	a5,0x24
    8000629e:	f2e78793          	addi	a5,a5,-210 # 8002a1c8 <disk>
    800062a2:	97b6                	add	a5,a5,a3
    800062a4:	4685                	li	a3,1
    800062a6:	c794                	sw	a3,8(a5)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800062a8:	00024597          	auipc	a1,0x24
    800062ac:	f2058593          	addi	a1,a1,-224 # 8002a1c8 <disk>
    800062b0:	00a60793          	addi	a5,a2,10
    800062b4:	0792                	slli	a5,a5,0x4
    800062b6:	97ae                	add	a5,a5,a1
    800062b8:	0007a623          	sw	zero,12(a5)
  buf0->sector = sector;
    800062bc:	0197b823          	sd	s9,16(a5)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800062c0:	f6070693          	addi	a3,a4,-160
    800062c4:	619c                	ld	a5,0(a1)
    800062c6:	97b6                	add	a5,a5,a3
    800062c8:	e388                	sd	a0,0(a5)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800062ca:	6188                	ld	a0,0(a1)
    800062cc:	96aa                	add	a3,a3,a0
    800062ce:	47c1                	li	a5,16
    800062d0:	c69c                	sw	a5,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800062d2:	4785                	li	a5,1
    800062d4:	00f69623          	sh	a5,12(a3)
  disk.desc[idx[0]].next = idx[1];
    800062d8:	f9442783          	lw	a5,-108(s0)
    800062dc:	00f69723          	sh	a5,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800062e0:	0792                	slli	a5,a5,0x4
    800062e2:	953e                	add	a0,a0,a5
    800062e4:	05890693          	addi	a3,s2,88
    800062e8:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    800062ea:	6188                	ld	a0,0(a1)
    800062ec:	97aa                	add	a5,a5,a0
    800062ee:	40000693          	li	a3,1024
    800062f2:	c794                	sw	a3,8(a5)
  if(write)
    800062f4:	100d0d63          	beqz	s10,8000640e <virtio_disk_rw+0x256>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800062f8:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800062fc:	00c7d683          	lhu	a3,12(a5)
    80006300:	0016e693          	ori	a3,a3,1
    80006304:	00d79623          	sh	a3,12(a5)
  disk.desc[idx[1]].next = idx[2];
    80006308:	f9842583          	lw	a1,-104(s0)
    8000630c:	00b79723          	sh	a1,14(a5)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006310:	00024697          	auipc	a3,0x24
    80006314:	eb868693          	addi	a3,a3,-328 # 8002a1c8 <disk>
    80006318:	00260793          	addi	a5,a2,2
    8000631c:	0792                	slli	a5,a5,0x4
    8000631e:	97b6                	add	a5,a5,a3
    80006320:	587d                	li	a6,-1
    80006322:	01078823          	sb	a6,16(a5)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006326:	0592                	slli	a1,a1,0x4
    80006328:	952e                	add	a0,a0,a1
    8000632a:	f9070713          	addi	a4,a4,-112
    8000632e:	9736                	add	a4,a4,a3
    80006330:	e118                	sd	a4,0(a0)
  disk.desc[idx[2]].len = 1;
    80006332:	6298                	ld	a4,0(a3)
    80006334:	972e                	add	a4,a4,a1
    80006336:	4585                	li	a1,1
    80006338:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000633a:	4509                	li	a0,2
    8000633c:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[2]].next = 0;
    80006340:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006344:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006348:	0127b423          	sd	s2,8(a5)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    8000634c:	6698                	ld	a4,8(a3)
    8000634e:	00275783          	lhu	a5,2(a4)
    80006352:	8b9d                	andi	a5,a5,7
    80006354:	0786                	slli	a5,a5,0x1
    80006356:	97ba                	add	a5,a5,a4
    80006358:	00c79223          	sh	a2,4(a5)

  __sync_synchronize();
    8000635c:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006360:	6698                	ld	a4,8(a3)
    80006362:	00275783          	lhu	a5,2(a4)
    80006366:	2785                	addiw	a5,a5,1
    80006368:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    8000636c:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006370:	100017b7          	lui	a5,0x10001
    80006374:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006378:	00492703          	lw	a4,4(s2)
    8000637c:	4785                	li	a5,1
    8000637e:	02f71163          	bne	a4,a5,800063a0 <virtio_disk_rw+0x1e8>
    sleep(b, &disk.vdisk_lock);
    80006382:	00024997          	auipc	s3,0x24
    80006386:	f6e98993          	addi	s3,s3,-146 # 8002a2f0 <disk+0x128>
  while(b->disk == 1) {
    8000638a:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    8000638c:	85ce                	mv	a1,s3
    8000638e:	854a                	mv	a0,s2
    80006390:	ffffc097          	auipc	ra,0xffffc
    80006394:	d7a080e7          	jalr	-646(ra) # 8000210a <sleep>
  while(b->disk == 1) {
    80006398:	00492783          	lw	a5,4(s2)
    8000639c:	fe9788e3          	beq	a5,s1,8000638c <virtio_disk_rw+0x1d4>
  }

  disk.info[idx[0]].b = 0;
    800063a0:	f9042903          	lw	s2,-112(s0)
    800063a4:	00290793          	addi	a5,s2,2
    800063a8:	00479713          	slli	a4,a5,0x4
    800063ac:	00024797          	auipc	a5,0x24
    800063b0:	e1c78793          	addi	a5,a5,-484 # 8002a1c8 <disk>
    800063b4:	97ba                	add	a5,a5,a4
    800063b6:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800063ba:	00024997          	auipc	s3,0x24
    800063be:	e0e98993          	addi	s3,s3,-498 # 8002a1c8 <disk>
    800063c2:	00491713          	slli	a4,s2,0x4
    800063c6:	0009b783          	ld	a5,0(s3)
    800063ca:	97ba                	add	a5,a5,a4
    800063cc:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800063d0:	854a                	mv	a0,s2
    800063d2:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800063d6:	00000097          	auipc	ra,0x0
    800063da:	b70080e7          	jalr	-1168(ra) # 80005f46 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800063de:	8885                	andi	s1,s1,1
    800063e0:	f0ed                	bnez	s1,800063c2 <virtio_disk_rw+0x20a>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800063e2:	00024517          	auipc	a0,0x24
    800063e6:	f0e50513          	addi	a0,a0,-242 # 8002a2f0 <disk+0x128>
    800063ea:	ffffb097          	auipc	ra,0xffffb
    800063ee:	8b4080e7          	jalr	-1868(ra) # 80000c9e <release>
}
    800063f2:	70a6                	ld	ra,104(sp)
    800063f4:	7406                	ld	s0,96(sp)
    800063f6:	64e6                	ld	s1,88(sp)
    800063f8:	6946                	ld	s2,80(sp)
    800063fa:	69a6                	ld	s3,72(sp)
    800063fc:	6a06                	ld	s4,64(sp)
    800063fe:	7ae2                	ld	s5,56(sp)
    80006400:	7b42                	ld	s6,48(sp)
    80006402:	7ba2                	ld	s7,40(sp)
    80006404:	7c02                	ld	s8,32(sp)
    80006406:	6ce2                	ld	s9,24(sp)
    80006408:	6d42                	ld	s10,16(sp)
    8000640a:	6165                	addi	sp,sp,112
    8000640c:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000640e:	4689                	li	a3,2
    80006410:	00d79623          	sh	a3,12(a5)
    80006414:	b5e5                	j	800062fc <virtio_disk_rw+0x144>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006416:	f9042603          	lw	a2,-112(s0)
    8000641a:	00a60713          	addi	a4,a2,10
    8000641e:	0712                	slli	a4,a4,0x4
    80006420:	00024517          	auipc	a0,0x24
    80006424:	db050513          	addi	a0,a0,-592 # 8002a1d0 <disk+0x8>
    80006428:	953a                	add	a0,a0,a4
  if(write)
    8000642a:	e60d14e3          	bnez	s10,80006292 <virtio_disk_rw+0xda>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    8000642e:	00a60793          	addi	a5,a2,10
    80006432:	00479693          	slli	a3,a5,0x4
    80006436:	00024797          	auipc	a5,0x24
    8000643a:	d9278793          	addi	a5,a5,-622 # 8002a1c8 <disk>
    8000643e:	97b6                	add	a5,a5,a3
    80006440:	0007a423          	sw	zero,8(a5)
    80006444:	b595                	j	800062a8 <virtio_disk_rw+0xf0>

0000000080006446 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006446:	1101                	addi	sp,sp,-32
    80006448:	ec06                	sd	ra,24(sp)
    8000644a:	e822                	sd	s0,16(sp)
    8000644c:	e426                	sd	s1,8(sp)
    8000644e:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006450:	00024497          	auipc	s1,0x24
    80006454:	d7848493          	addi	s1,s1,-648 # 8002a1c8 <disk>
    80006458:	00024517          	auipc	a0,0x24
    8000645c:	e9850513          	addi	a0,a0,-360 # 8002a2f0 <disk+0x128>
    80006460:	ffffa097          	auipc	ra,0xffffa
    80006464:	78a080e7          	jalr	1930(ra) # 80000bea <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006468:	10001737          	lui	a4,0x10001
    8000646c:	533c                	lw	a5,96(a4)
    8000646e:	8b8d                	andi	a5,a5,3
    80006470:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006472:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006476:	689c                	ld	a5,16(s1)
    80006478:	0204d703          	lhu	a4,32(s1)
    8000647c:	0027d783          	lhu	a5,2(a5)
    80006480:	04f70863          	beq	a4,a5,800064d0 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006484:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006488:	6898                	ld	a4,16(s1)
    8000648a:	0204d783          	lhu	a5,32(s1)
    8000648e:	8b9d                	andi	a5,a5,7
    80006490:	078e                	slli	a5,a5,0x3
    80006492:	97ba                	add	a5,a5,a4
    80006494:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006496:	00278713          	addi	a4,a5,2
    8000649a:	0712                	slli	a4,a4,0x4
    8000649c:	9726                	add	a4,a4,s1
    8000649e:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800064a2:	e721                	bnez	a4,800064ea <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800064a4:	0789                	addi	a5,a5,2
    800064a6:	0792                	slli	a5,a5,0x4
    800064a8:	97a6                	add	a5,a5,s1
    800064aa:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800064ac:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800064b0:	ffffc097          	auipc	ra,0xffffc
    800064b4:	cbe080e7          	jalr	-834(ra) # 8000216e <wakeup>

    disk.used_idx += 1;
    800064b8:	0204d783          	lhu	a5,32(s1)
    800064bc:	2785                	addiw	a5,a5,1
    800064be:	17c2                	slli	a5,a5,0x30
    800064c0:	93c1                	srli	a5,a5,0x30
    800064c2:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800064c6:	6898                	ld	a4,16(s1)
    800064c8:	00275703          	lhu	a4,2(a4)
    800064cc:	faf71ce3          	bne	a4,a5,80006484 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800064d0:	00024517          	auipc	a0,0x24
    800064d4:	e2050513          	addi	a0,a0,-480 # 8002a2f0 <disk+0x128>
    800064d8:	ffffa097          	auipc	ra,0xffffa
    800064dc:	7c6080e7          	jalr	1990(ra) # 80000c9e <release>
}
    800064e0:	60e2                	ld	ra,24(sp)
    800064e2:	6442                	ld	s0,16(sp)
    800064e4:	64a2                	ld	s1,8(sp)
    800064e6:	6105                	addi	sp,sp,32
    800064e8:	8082                	ret
      panic("virtio_disk_intr status");
    800064ea:	00002517          	auipc	a0,0x2
    800064ee:	54650513          	addi	a0,a0,1350 # 80008a30 <syscalls+0x410>
    800064f2:	ffffa097          	auipc	ra,0xffffa
    800064f6:	052080e7          	jalr	82(ra) # 80000544 <panic>

00000000800064fa <open>:
  iunlockput(dp);
  return 0;
}


struct file *open(char *filename){
    800064fa:	7179                	addi	sp,sp,-48
    800064fc:	f406                	sd	ra,40(sp)
    800064fe:	f022                	sd	s0,32(sp)
    80006500:	ec26                	sd	s1,24(sp)
    80006502:	e84a                	sd	s2,16(sp)
    80006504:	1800                	addi	s0,sp,48
    80006506:	84aa                	mv	s1,a0
    int omode;
    struct file *f;
    struct inode *ip;

    omode = O_CREATE;
    if(strlen(filename) < 0)
    80006508:	ffffb097          	auipc	ra,0xffffb
    8000650c:	962080e7          	jalr	-1694(ra) # 80000e6a <strlen>
	return (struct file *)-1;
    80006510:	597d                	li	s2,-1
    if(strlen(filename) < 0)
    80006512:	10054f63          	bltz	a0,80006630 <open+0x136>

    begin_op();
    80006516:	ffffe097          	auipc	ra,0xffffe
    8000651a:	dd0080e7          	jalr	-560(ra) # 800042e6 <begin_op>
  if((dp = nameiparent(path, name)) == 0)
    8000651e:	fd040593          	addi	a1,s0,-48
    80006522:	8526                	mv	a0,s1
    80006524:	ffffe097          	auipc	ra,0xffffe
    80006528:	bc4080e7          	jalr	-1084(ra) # 800040e8 <nameiparent>
    8000652c:	892a                	mv	s2,a0
    8000652e:	10050d63          	beqz	a0,80006648 <open+0x14e>
  ilock(dp);
    80006532:	ffffd097          	auipc	ra,0xffffd
    80006536:	3f2080e7          	jalr	1010(ra) # 80003924 <ilock>
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000653a:	4601                	li	a2,0
    8000653c:	fd040593          	addi	a1,s0,-48
    80006540:	854a                	mv	a0,s2
    80006542:	ffffe097          	auipc	ra,0xffffe
    80006546:	8c6080e7          	jalr	-1850(ra) # 80003e08 <dirlookup>
    8000654a:	84aa                	mv	s1,a0
    8000654c:	10050463          	beqz	a0,80006654 <open+0x15a>
    iunlockput(dp);
    80006550:	854a                	mv	a0,s2
    80006552:	ffffd097          	auipc	ra,0xffffd
    80006556:	634080e7          	jalr	1588(ra) # 80003b86 <iunlockput>
    ilock(ip);
    8000655a:	8526                	mv	a0,s1
    8000655c:	ffffd097          	auipc	ra,0xffffd
    80006560:	3c8080e7          	jalr	968(ra) # 80003924 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80006564:	0444d783          	lhu	a5,68(s1)
    80006568:	37f9                	addiw	a5,a5,-2
    8000656a:	17c2                	slli	a5,a5,0x30
    8000656c:	93c1                	srli	a5,a5,0x30
    8000656e:	4705                	li	a4,1
    80006570:	0cf76763          	bltu	a4,a5,8000663e <open+0x144>
	    printf("OOPs");
	    //this is where it breaks`
	    return (struct file *)-1;
	}
    }
    printf("Gone\n");
    80006574:	00002517          	auipc	a0,0x2
    80006578:	50450513          	addi	a0,a0,1284 # 80008a78 <syscalls+0x458>
    8000657c:	ffffa097          	auipc	ra,0xffffa
    80006580:	012080e7          	jalr	18(ra) # 8000058e <printf>
//    ilock(ip);

    printf("Gone\n");
    80006584:	00002517          	auipc	a0,0x2
    80006588:	4f450513          	addi	a0,a0,1268 # 80008a78 <syscalls+0x458>
    8000658c:	ffffa097          	auipc	ra,0xffffa
    80006590:	002080e7          	jalr	2(ra) # 8000058e <printf>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80006594:	04449703          	lh	a4,68(s1)
    80006598:	4785                	li	a5,1
    8000659a:	14f70663          	beq	a4,a5,800066e6 <open+0x1ec>
	iunlockput(ip);
	end_op();
	return (struct file *)-1;
    }
    printf("1\n");
    8000659e:	00002517          	auipc	a0,0x2
    800065a2:	4b250513          	addi	a0,a0,1202 # 80008a50 <syscalls+0x430>
    800065a6:	ffffa097          	auipc	ra,0xffffa
    800065aa:	fe8080e7          	jalr	-24(ra) # 8000058e <printf>
    

    if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800065ae:	04449703          	lh	a4,68(s1)
    800065b2:	478d                	li	a5,3
    800065b4:	00f71763          	bne	a4,a5,800065c2 <open+0xc8>
    800065b8:	0464d703          	lhu	a4,70(s1)
    800065bc:	47a5                	li	a5,9
    800065be:	12e7ef63          	bltu	a5,a4,800066fc <open+0x202>
	iunlockput(ip);
	end_op();
	return (struct file *)-1;
    }

	printf("2\n");
    800065c2:	00002517          	auipc	a0,0x2
    800065c6:	49650513          	addi	a0,a0,1174 # 80008a58 <syscalls+0x438>
    800065ca:	ffffa097          	auipc	ra,0xffffa
    800065ce:	fc4080e7          	jalr	-60(ra) # 8000058e <printf>
    if((f = filealloc()) == 0){
    800065d2:	ffffe097          	auipc	ra,0xffffe
    800065d6:	124080e7          	jalr	292(ra) # 800046f6 <filealloc>
    800065da:	892a                	mv	s2,a0
    800065dc:	12050b63          	beqz	a0,80006712 <open+0x218>
	iunlockput(ip);
	end_op();
	return (struct file *)-1;
    }

	printf("3\n");
    800065e0:	00002517          	auipc	a0,0x2
    800065e4:	48050513          	addi	a0,a0,1152 # 80008a60 <syscalls+0x440>
    800065e8:	ffffa097          	auipc	ra,0xffffa
    800065ec:	fa6080e7          	jalr	-90(ra) # 8000058e <printf>
   f->type = FD_INODE;
    800065f0:	4789                	li	a5,2
    800065f2:	00f92023          	sw	a5,0(s2)
   f->off = 0;
    800065f6:	02092023          	sw	zero,32(s2)
   f->ip = ip;
    800065fa:	00993c23          	sd	s1,24(s2)
   f->readable = !(omode & O_WRONLY);
    800065fe:	4785                	li	a5,1
    80006600:	00f90423          	sb	a5,8(s2)
   f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80006604:	000904a3          	sb	zero,9(s2)

   if((omode & O_TRUNC) && ip->type == T_FILE){
     itrunc(ip);
   }

	printf("4\n");
    80006608:	00002517          	auipc	a0,0x2
    8000660c:	46050513          	addi	a0,a0,1120 # 80008a68 <syscalls+0x448>
    80006610:	ffffa097          	auipc	ra,0xffffa
    80006614:	f7e080e7          	jalr	-130(ra) # 8000058e <printf>
   //iunlock(ip);
   end_op();
    80006618:	ffffe097          	auipc	ra,0xffffe
    8000661c:	d4e080e7          	jalr	-690(ra) # 80004366 <end_op>

	printf("5\n");
    80006620:	00002517          	auipc	a0,0x2
    80006624:	45050513          	addi	a0,a0,1104 # 80008a70 <syscalls+0x450>
    80006628:	ffffa097          	auipc	ra,0xffffa
    8000662c:	f66080e7          	jalr	-154(ra) # 8000058e <printf>
   return f;
}
    80006630:	854a                	mv	a0,s2
    80006632:	70a2                	ld	ra,40(sp)
    80006634:	7402                	ld	s0,32(sp)
    80006636:	64e2                	ld	s1,24(sp)
    80006638:	6942                	ld	s2,16(sp)
    8000663a:	6145                	addi	sp,sp,48
    8000663c:	8082                	ret
    iunlockput(ip);
    8000663e:	8526                	mv	a0,s1
    80006640:	ffffd097          	auipc	ra,0xffffd
    80006644:	546080e7          	jalr	1350(ra) # 80003b86 <iunlockput>
	    end_op();
    80006648:	ffffe097          	auipc	ra,0xffffe
    8000664c:	d1e080e7          	jalr	-738(ra) # 80004366 <end_op>
	    return (struct file *)-1;
    80006650:	597d                	li	s2,-1
    80006652:	bff9                	j	80006630 <open+0x136>
  if((ip = ialloc(dp->dev, type)) == 0){
    80006654:	4589                	li	a1,2
    80006656:	00092503          	lw	a0,0(s2)
    8000665a:	ffffd097          	auipc	ra,0xffffd
    8000665e:	12e080e7          	jalr	302(ra) # 80003788 <ialloc>
    80006662:	84aa                	mv	s1,a0
    80006664:	c929                	beqz	a0,800066b6 <open+0x1bc>
  ilock(ip);
    80006666:	ffffd097          	auipc	ra,0xffffd
    8000666a:	2be080e7          	jalr	702(ra) # 80003924 <ilock>
  ip->major = major;
    8000666e:	04049323          	sh	zero,70(s1)
  ip->minor = minor;
    80006672:	04049423          	sh	zero,72(s1)
  ip->nlink = 1;
    80006676:	4785                	li	a5,1
    80006678:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000667c:	8526                	mv	a0,s1
    8000667e:	ffffd097          	auipc	ra,0xffffd
    80006682:	1dc080e7          	jalr	476(ra) # 8000385a <iupdate>
  if(dirlink(dp, name, ip->inum) < 0)
    80006686:	40d0                	lw	a2,4(s1)
    80006688:	fd040593          	addi	a1,s0,-48
    8000668c:	854a                	mv	a0,s2
    8000668e:	ffffe097          	auipc	ra,0xffffe
    80006692:	98a080e7          	jalr	-1654(ra) # 80004018 <dirlink>
    80006696:	02054663          	bltz	a0,800066c2 <open+0x1c8>
  iunlockput(dp);
    8000669a:	854a                	mv	a0,s2
    8000669c:	ffffd097          	auipc	ra,0xffffd
    800066a0:	4ea080e7          	jalr	1258(ra) # 80003b86 <iunlockput>
  printf("Happy\n");
    800066a4:	00002517          	auipc	a0,0x2
    800066a8:	3a450513          	addi	a0,a0,932 # 80008a48 <syscalls+0x428>
    800066ac:	ffffa097          	auipc	ra,0xffffa
    800066b0:	ee2080e7          	jalr	-286(ra) # 8000058e <printf>
  return ip;
    800066b4:	b5c1                	j	80006574 <open+0x7a>
    iunlockput(dp);
    800066b6:	854a                	mv	a0,s2
    800066b8:	ffffd097          	auipc	ra,0xffffd
    800066bc:	4ce080e7          	jalr	1230(ra) # 80003b86 <iunlockput>
    return 0;
    800066c0:	b761                	j	80006648 <open+0x14e>
  ip->nlink = 0;
    800066c2:	04049523          	sh	zero,74(s1)
  iupdate(ip);
    800066c6:	8526                	mv	a0,s1
    800066c8:	ffffd097          	auipc	ra,0xffffd
    800066cc:	192080e7          	jalr	402(ra) # 8000385a <iupdate>
  iunlockput(ip);
    800066d0:	8526                	mv	a0,s1
    800066d2:	ffffd097          	auipc	ra,0xffffd
    800066d6:	4b4080e7          	jalr	1204(ra) # 80003b86 <iunlockput>
  iunlockput(dp);
    800066da:	854a                	mv	a0,s2
    800066dc:	ffffd097          	auipc	ra,0xffffd
    800066e0:	4aa080e7          	jalr	1194(ra) # 80003b86 <iunlockput>
  return 0;
    800066e4:	b795                	j	80006648 <open+0x14e>
	iunlockput(ip);
    800066e6:	8526                	mv	a0,s1
    800066e8:	ffffd097          	auipc	ra,0xffffd
    800066ec:	49e080e7          	jalr	1182(ra) # 80003b86 <iunlockput>
	end_op();
    800066f0:	ffffe097          	auipc	ra,0xffffe
    800066f4:	c76080e7          	jalr	-906(ra) # 80004366 <end_op>
	return (struct file *)-1;
    800066f8:	597d                	li	s2,-1
    800066fa:	bf1d                	j	80006630 <open+0x136>
	iunlockput(ip);
    800066fc:	8526                	mv	a0,s1
    800066fe:	ffffd097          	auipc	ra,0xffffd
    80006702:	488080e7          	jalr	1160(ra) # 80003b86 <iunlockput>
	end_op();
    80006706:	ffffe097          	auipc	ra,0xffffe
    8000670a:	c60080e7          	jalr	-928(ra) # 80004366 <end_op>
	return (struct file *)-1;
    8000670e:	597d                	li	s2,-1
    80006710:	b705                	j	80006630 <open+0x136>
	iunlockput(ip);
    80006712:	8526                	mv	a0,s1
    80006714:	ffffd097          	auipc	ra,0xffffd
    80006718:	472080e7          	jalr	1138(ra) # 80003b86 <iunlockput>
	end_op();
    8000671c:	ffffe097          	auipc	ra,0xffffe
    80006720:	c4a080e7          	jalr	-950(ra) # 80004366 <end_op>
	return (struct file *)-1;
    80006724:	597d                	li	s2,-1
    80006726:	b729                	j	80006630 <open+0x136>

0000000080006728 <write_to_logs>:

void write_to_logs(void *list){
    80006728:	7179                	addi	sp,sp,-48
    8000672a:	f406                	sd	ra,40(sp)
    8000672c:	f022                	sd	s0,32(sp)
    8000672e:	ec26                	sd	s1,24(sp)
    80006730:	1800                	addi	s0,sp,48
    struct file *f;
    char *filename = "/AuditLogs.txt";
    
    f = open(filename);
    80006732:	00002517          	auipc	a0,0x2
    80006736:	34e50513          	addi	a0,a0,846 # 80008a80 <syscalls+0x460>
    8000673a:	00000097          	auipc	ra,0x0
    8000673e:	dc0080e7          	jalr	-576(ra) # 800064fa <open>
    80006742:	84aa                	mv	s1,a0

//    uint64 fd = open(filename);
    if(f == (struct file *)-1)
    80006744:	57fd                	li	a5,-1
    80006746:	04f50763          	beq	a0,a5,80006794 <write_to_logs+0x6c>
	exit(0);

    printf("6\n");
    8000674a:	00002517          	auipc	a0,0x2
    8000674e:	34650513          	addi	a0,a0,838 # 80008a90 <syscalls+0x470>
    80006752:	ffffa097          	auipc	ra,0xffffa
    80006756:	e3c080e7          	jalr	-452(ra) # 8000058e <printf>
    char temp[5] = "happ";
    8000675a:	707067b7          	lui	a5,0x70706
    8000675e:	1687879b          	addiw	a5,a5,360
    80006762:	fcf42c23          	sw	a5,-40(s0)
    80006766:	fc040e23          	sb	zero,-36(s0)
    filewrite(f, (uint64)(temp), 5);
    8000676a:	4615                	li	a2,5
    8000676c:	fd840593          	addi	a1,s0,-40
    80006770:	8526                	mv	a0,s1
    80006772:	ffffe097          	auipc	ra,0xffffe
    80006776:	23c080e7          	jalr	572(ra) # 800049ae <filewrite>

    printf("What\n");
    8000677a:	00002517          	auipc	a0,0x2
    8000677e:	31e50513          	addi	a0,a0,798 # 80008a98 <syscalls+0x478>
    80006782:	ffffa097          	auipc	ra,0xffffa
    80006786:	e0c080e7          	jalr	-500(ra) # 8000058e <printf>


}
    8000678a:	70a2                	ld	ra,40(sp)
    8000678c:	7402                	ld	s0,32(sp)
    8000678e:	64e2                	ld	s1,24(sp)
    80006790:	6145                	addi	sp,sp,48
    80006792:	8082                	ret
	exit(0);
    80006794:	4501                	li	a0,0
    80006796:	ffffc097          	auipc	ra,0xffffc
    8000679a:	aa8080e7          	jalr	-1368(ra) # 8000223e <exit>
    8000679e:	b775                	j	8000674a <write_to_logs+0x22>
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
