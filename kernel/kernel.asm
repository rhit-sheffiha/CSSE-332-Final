
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	aa013103          	ld	sp,-1376(sp) # 80008aa0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

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
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	ab070713          	addi	a4,a4,-1360 # 80008b00 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	cbe78793          	addi	a5,a5,-834 # 80005d20 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd067f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	dcc78793          	addi	a5,a5,-564 # 80000e78 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	3c2080e7          	jalr	962(ra) # 800024ec <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	784080e7          	jalr	1924(ra) # 800008be <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
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
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	ab650513          	addi	a0,a0,-1354 # 80010c40 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	aa648493          	addi	s1,s1,-1370 # 80010c40 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	b3690913          	addi	s2,s2,-1226 # 80010cd8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00001097          	auipc	ra,0x1
    800001c4:	7ec080e7          	jalr	2028(ra) # 800019ac <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	16e080e7          	jalr	366(ra) # 80002336 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	eb8080e7          	jalr	-328(ra) # 8000208e <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	284080e7          	jalr	644(ra) # 80002496 <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	a1a50513          	addi	a0,a0,-1510 # 80010c40 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	a0450513          	addi	a0,a0,-1532 # 80010c40 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a46080e7          	jalr	-1466(ra) # 80000c8a <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	a6f72323          	sw	a5,-1434(a4) # 80010cd8 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	560080e7          	jalr	1376(ra) # 800007ec <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54e080e7          	jalr	1358(ra) # 800007ec <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	542080e7          	jalr	1346(ra) # 800007ec <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	538080e7          	jalr	1336(ra) # 800007ec <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	97450513          	addi	a0,a0,-1676 # 80010c40 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	902080e7          	jalr	-1790(ra) # 80000bd6 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	250080e7          	jalr	592(ra) # 80002542 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	94650513          	addi	a0,a0,-1722 # 80010c40 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	988080e7          	jalr	-1656(ra) # 80000c8a <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	92270713          	addi	a4,a4,-1758 # 80010c40 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	8f878793          	addi	a5,a5,-1800 # 80010c40 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	9627a783          	lw	a5,-1694(a5) # 80010cd8 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	8b670713          	addi	a4,a4,-1866 # 80010c40 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	8a648493          	addi	s1,s1,-1882 # 80010c40 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	86a70713          	addi	a4,a4,-1942 # 80010c40 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	8ef72a23          	sw	a5,-1804(a4) # 80010ce0 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	82e78793          	addi	a5,a5,-2002 # 80010c40 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	8ac7a323          	sw	a2,-1882(a5) # 80010cdc <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	89a50513          	addi	a0,a0,-1894 # 80010cd8 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	cac080e7          	jalr	-852(ra) # 800020f2 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	7e050513          	addi	a0,a0,2016 # 80010c40 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32c080e7          	jalr	812(ra) # 8000079c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	0002d797          	auipc	a5,0x2d
    8000047c:	b7078793          	addi	a5,a5,-1168 # 8002cfe8 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7670713          	addi	a4,a4,-906 # 80000100 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054763          	bltz	a0,80000538 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088c63          	beqz	a7,800004fe <printint+0x62>
    buf[i++] = '-';
    800004ea:	fe070793          	addi	a5,a4,-32
    800004ee:	00878733          	add	a4,a5,s0
    800004f2:	02d00793          	li	a5,45
    800004f6:	fef70823          	sb	a5,-16(a4)
    800004fa:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fe:	02e05763          	blez	a4,8000052c <printint+0x90>
    80000502:	fd040793          	addi	a5,s0,-48
    80000506:	00e784b3          	add	s1,a5,a4
    8000050a:	fff78913          	addi	s2,a5,-1
    8000050e:	993a                	add	s2,s2,a4
    80000510:	377d                	addiw	a4,a4,-1
    80000512:	1702                	slli	a4,a4,0x20
    80000514:	9301                	srli	a4,a4,0x20
    80000516:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051a:	fff4c503          	lbu	a0,-1(s1)
    8000051e:	00000097          	auipc	ra,0x0
    80000522:	d5e080e7          	jalr	-674(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000526:	14fd                	addi	s1,s1,-1
    80000528:	ff2499e3          	bne	s1,s2,8000051a <printint+0x7e>
}
    8000052c:	70a2                	ld	ra,40(sp)
    8000052e:	7402                	ld	s0,32(sp)
    80000530:	64e2                	ld	s1,24(sp)
    80000532:	6942                	ld	s2,16(sp)
    80000534:	6145                	addi	sp,sp,48
    80000536:	8082                	ret
    x = -xx;
    80000538:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053c:	4885                	li	a7,1
    x = -xx;
    8000053e:	bf95                	j	800004b2 <printint+0x16>

0000000080000540 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000540:	1101                	addi	sp,sp,-32
    80000542:	ec06                	sd	ra,24(sp)
    80000544:	e822                	sd	s0,16(sp)
    80000546:	e426                	sd	s1,8(sp)
    80000548:	1000                	addi	s0,sp,32
    8000054a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054c:	00010797          	auipc	a5,0x10
    80000550:	7a07aa23          	sw	zero,1972(a5) # 80010d00 <pr+0x18>
  printf("panic: ");
    80000554:	00008517          	auipc	a0,0x8
    80000558:	ac450513          	addi	a0,a0,-1340 # 80008018 <etext+0x18>
    8000055c:	00000097          	auipc	ra,0x0
    80000560:	02e080e7          	jalr	46(ra) # 8000058a <printf>
  printf(s);
    80000564:	8526                	mv	a0,s1
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	024080e7          	jalr	36(ra) # 8000058a <printf>
  printf("\n");
    8000056e:	00008517          	auipc	a0,0x8
    80000572:	b5a50513          	addi	a0,a0,-1190 # 800080c8 <digits+0x88>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00008717          	auipc	a4,0x8
    80000584:	54f72023          	sw	a5,1344(a4) # 80008ac0 <panicked>
  for(;;)
    80000588:	a001                	j	80000588 <panic+0x48>

000000008000058a <printf>:
{
    8000058a:	7131                	addi	sp,sp,-192
    8000058c:	fc86                	sd	ra,120(sp)
    8000058e:	f8a2                	sd	s0,112(sp)
    80000590:	f4a6                	sd	s1,104(sp)
    80000592:	f0ca                	sd	s2,96(sp)
    80000594:	ecce                	sd	s3,88(sp)
    80000596:	e8d2                	sd	s4,80(sp)
    80000598:	e4d6                	sd	s5,72(sp)
    8000059a:	e0da                	sd	s6,64(sp)
    8000059c:	fc5e                	sd	s7,56(sp)
    8000059e:	f862                	sd	s8,48(sp)
    800005a0:	f466                	sd	s9,40(sp)
    800005a2:	f06a                	sd	s10,32(sp)
    800005a4:	ec6e                	sd	s11,24(sp)
    800005a6:	0100                	addi	s0,sp,128
    800005a8:	8a2a                	mv	s4,a0
    800005aa:	e40c                	sd	a1,8(s0)
    800005ac:	e810                	sd	a2,16(s0)
    800005ae:	ec14                	sd	a3,24(s0)
    800005b0:	f018                	sd	a4,32(s0)
    800005b2:	f41c                	sd	a5,40(s0)
    800005b4:	03043823          	sd	a6,48(s0)
    800005b8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005bc:	00010d97          	auipc	s11,0x10
    800005c0:	744dad83          	lw	s11,1860(s11) # 80010d00 <pr+0x18>
  if(locking)
    800005c4:	020d9b63          	bnez	s11,800005fa <printf+0x70>
  if (fmt == 0)
    800005c8:	040a0263          	beqz	s4,8000060c <printf+0x82>
  va_start(ap, fmt);
    800005cc:	00840793          	addi	a5,s0,8
    800005d0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d4:	000a4503          	lbu	a0,0(s4)
    800005d8:	14050f63          	beqz	a0,80000736 <printf+0x1ac>
    800005dc:	4981                	li	s3,0
    if(c != '%'){
    800005de:	02500a93          	li	s5,37
    switch(c){
    800005e2:	07000b93          	li	s7,112
  consputc('x');
    800005e6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e8:	00008b17          	auipc	s6,0x8
    800005ec:	a58b0b13          	addi	s6,s6,-1448 # 80008040 <digits>
    switch(c){
    800005f0:	07300c93          	li	s9,115
    800005f4:	06400c13          	li	s8,100
    800005f8:	a82d                	j	80000632 <printf+0xa8>
    acquire(&pr.lock);
    800005fa:	00010517          	auipc	a0,0x10
    800005fe:	6ee50513          	addi	a0,a0,1774 # 80010ce8 <pr>
    80000602:	00000097          	auipc	ra,0x0
    80000606:	5d4080e7          	jalr	1492(ra) # 80000bd6 <acquire>
    8000060a:	bf7d                	j	800005c8 <printf+0x3e>
    panic("null fmt");
    8000060c:	00008517          	auipc	a0,0x8
    80000610:	a1c50513          	addi	a0,a0,-1508 # 80008028 <etext+0x28>
    80000614:	00000097          	auipc	ra,0x0
    80000618:	f2c080e7          	jalr	-212(ra) # 80000540 <panic>
      consputc(c);
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	c60080e7          	jalr	-928(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000624:	2985                	addiw	s3,s3,1
    80000626:	013a07b3          	add	a5,s4,s3
    8000062a:	0007c503          	lbu	a0,0(a5)
    8000062e:	10050463          	beqz	a0,80000736 <printf+0x1ac>
    if(c != '%'){
    80000632:	ff5515e3          	bne	a0,s5,8000061c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000636:	2985                	addiw	s3,s3,1
    80000638:	013a07b3          	add	a5,s4,s3
    8000063c:	0007c783          	lbu	a5,0(a5)
    80000640:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000644:	cbed                	beqz	a5,80000736 <printf+0x1ac>
    switch(c){
    80000646:	05778a63          	beq	a5,s7,8000069a <printf+0x110>
    8000064a:	02fbf663          	bgeu	s7,a5,80000676 <printf+0xec>
    8000064e:	09978863          	beq	a5,s9,800006de <printf+0x154>
    80000652:	07800713          	li	a4,120
    80000656:	0ce79563          	bne	a5,a4,80000720 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000065a:	f8843783          	ld	a5,-120(s0)
    8000065e:	00878713          	addi	a4,a5,8
    80000662:	f8e43423          	sd	a4,-120(s0)
    80000666:	4605                	li	a2,1
    80000668:	85ea                	mv	a1,s10
    8000066a:	4388                	lw	a0,0(a5)
    8000066c:	00000097          	auipc	ra,0x0
    80000670:	e30080e7          	jalr	-464(ra) # 8000049c <printint>
      break;
    80000674:	bf45                	j	80000624 <printf+0x9a>
    switch(c){
    80000676:	09578f63          	beq	a5,s5,80000714 <printf+0x18a>
    8000067a:	0b879363          	bne	a5,s8,80000720 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067e:	f8843783          	ld	a5,-120(s0)
    80000682:	00878713          	addi	a4,a5,8
    80000686:	f8e43423          	sd	a4,-120(s0)
    8000068a:	4605                	li	a2,1
    8000068c:	45a9                	li	a1,10
    8000068e:	4388                	lw	a0,0(a5)
    80000690:	00000097          	auipc	ra,0x0
    80000694:	e0c080e7          	jalr	-500(ra) # 8000049c <printint>
      break;
    80000698:	b771                	j	80000624 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069a:	f8843783          	ld	a5,-120(s0)
    8000069e:	00878713          	addi	a4,a5,8
    800006a2:	f8e43423          	sd	a4,-120(s0)
    800006a6:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006aa:	03000513          	li	a0,48
    800006ae:	00000097          	auipc	ra,0x0
    800006b2:	bce080e7          	jalr	-1074(ra) # 8000027c <consputc>
  consputc('x');
    800006b6:	07800513          	li	a0,120
    800006ba:	00000097          	auipc	ra,0x0
    800006be:	bc2080e7          	jalr	-1086(ra) # 8000027c <consputc>
    800006c2:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c4:	03c95793          	srli	a5,s2,0x3c
    800006c8:	97da                	add	a5,a5,s6
    800006ca:	0007c503          	lbu	a0,0(a5)
    800006ce:	00000097          	auipc	ra,0x0
    800006d2:	bae080e7          	jalr	-1106(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d6:	0912                	slli	s2,s2,0x4
    800006d8:	34fd                	addiw	s1,s1,-1
    800006da:	f4ed                	bnez	s1,800006c4 <printf+0x13a>
    800006dc:	b7a1                	j	80000624 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	6384                	ld	s1,0(a5)
    800006ec:	cc89                	beqz	s1,80000706 <printf+0x17c>
      for(; *s; s++)
    800006ee:	0004c503          	lbu	a0,0(s1)
    800006f2:	d90d                	beqz	a0,80000624 <printf+0x9a>
        consputc(*s);
    800006f4:	00000097          	auipc	ra,0x0
    800006f8:	b88080e7          	jalr	-1144(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fc:	0485                	addi	s1,s1,1
    800006fe:	0004c503          	lbu	a0,0(s1)
    80000702:	f96d                	bnez	a0,800006f4 <printf+0x16a>
    80000704:	b705                	j	80000624 <printf+0x9a>
        s = "(null)";
    80000706:	00008497          	auipc	s1,0x8
    8000070a:	91a48493          	addi	s1,s1,-1766 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070e:	02800513          	li	a0,40
    80000712:	b7cd                	j	800006f4 <printf+0x16a>
      consputc('%');
    80000714:	8556                	mv	a0,s5
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b66080e7          	jalr	-1178(ra) # 8000027c <consputc>
      break;
    8000071e:	b719                	j	80000624 <printf+0x9a>
      consputc('%');
    80000720:	8556                	mv	a0,s5
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b5a080e7          	jalr	-1190(ra) # 8000027c <consputc>
      consputc(c);
    8000072a:	8526                	mv	a0,s1
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b50080e7          	jalr	-1200(ra) # 8000027c <consputc>
      break;
    80000734:	bdc5                	j	80000624 <printf+0x9a>
  if(locking)
    80000736:	020d9163          	bnez	s11,80000758 <printf+0x1ce>
}
    8000073a:	70e6                	ld	ra,120(sp)
    8000073c:	7446                	ld	s0,112(sp)
    8000073e:	74a6                	ld	s1,104(sp)
    80000740:	7906                	ld	s2,96(sp)
    80000742:	69e6                	ld	s3,88(sp)
    80000744:	6a46                	ld	s4,80(sp)
    80000746:	6aa6                	ld	s5,72(sp)
    80000748:	6b06                	ld	s6,64(sp)
    8000074a:	7be2                	ld	s7,56(sp)
    8000074c:	7c42                	ld	s8,48(sp)
    8000074e:	7ca2                	ld	s9,40(sp)
    80000750:	7d02                	ld	s10,32(sp)
    80000752:	6de2                	ld	s11,24(sp)
    80000754:	6129                	addi	sp,sp,192
    80000756:	8082                	ret
    release(&pr.lock);
    80000758:	00010517          	auipc	a0,0x10
    8000075c:	59050513          	addi	a0,a0,1424 # 80010ce8 <pr>
    80000760:	00000097          	auipc	ra,0x0
    80000764:	52a080e7          	jalr	1322(ra) # 80000c8a <release>
}
    80000768:	bfc9                	j	8000073a <printf+0x1b0>

000000008000076a <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076a:	1101                	addi	sp,sp,-32
    8000076c:	ec06                	sd	ra,24(sp)
    8000076e:	e822                	sd	s0,16(sp)
    80000770:	e426                	sd	s1,8(sp)
    80000772:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000774:	00010497          	auipc	s1,0x10
    80000778:	57448493          	addi	s1,s1,1396 # 80010ce8 <pr>
    8000077c:	00008597          	auipc	a1,0x8
    80000780:	8bc58593          	addi	a1,a1,-1860 # 80008038 <etext+0x38>
    80000784:	8526                	mv	a0,s1
    80000786:	00000097          	auipc	ra,0x0
    8000078a:	3c0080e7          	jalr	960(ra) # 80000b46 <initlock>
  pr.locking = 1;
    8000078e:	4785                	li	a5,1
    80000790:	cc9c                	sw	a5,24(s1)
}
    80000792:	60e2                	ld	ra,24(sp)
    80000794:	6442                	ld	s0,16(sp)
    80000796:	64a2                	ld	s1,8(sp)
    80000798:	6105                	addi	sp,sp,32
    8000079a:	8082                	ret

000000008000079c <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079c:	1141                	addi	sp,sp,-16
    8000079e:	e406                	sd	ra,8(sp)
    800007a0:	e022                	sd	s0,0(sp)
    800007a2:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a4:	100007b7          	lui	a5,0x10000
    800007a8:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ac:	f8000713          	li	a4,-128
    800007b0:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b4:	470d                	li	a4,3
    800007b6:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007ba:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007be:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c2:	469d                	li	a3,7
    800007c4:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c8:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007cc:	00008597          	auipc	a1,0x8
    800007d0:	88c58593          	addi	a1,a1,-1908 # 80008058 <digits+0x18>
    800007d4:	00010517          	auipc	a0,0x10
    800007d8:	53450513          	addi	a0,a0,1332 # 80010d08 <uart_tx_lock>
    800007dc:	00000097          	auipc	ra,0x0
    800007e0:	36a080e7          	jalr	874(ra) # 80000b46 <initlock>
}
    800007e4:	60a2                	ld	ra,8(sp)
    800007e6:	6402                	ld	s0,0(sp)
    800007e8:	0141                	addi	sp,sp,16
    800007ea:	8082                	ret

00000000800007ec <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ec:	1101                	addi	sp,sp,-32
    800007ee:	ec06                	sd	ra,24(sp)
    800007f0:	e822                	sd	s0,16(sp)
    800007f2:	e426                	sd	s1,8(sp)
    800007f4:	1000                	addi	s0,sp,32
    800007f6:	84aa                	mv	s1,a0
  push_off();
    800007f8:	00000097          	auipc	ra,0x0
    800007fc:	392080e7          	jalr	914(ra) # 80000b8a <push_off>

  if(panicked){
    80000800:	00008797          	auipc	a5,0x8
    80000804:	2c07a783          	lw	a5,704(a5) # 80008ac0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000808:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080c:	c391                	beqz	a5,80000810 <uartputc_sync+0x24>
    for(;;)
    8000080e:	a001                	j	8000080e <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000810:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000814:	0207f793          	andi	a5,a5,32
    80000818:	dfe5                	beqz	a5,80000810 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000081a:	0ff4f513          	zext.b	a0,s1
    8000081e:	100007b7          	lui	a5,0x10000
    80000822:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000826:	00000097          	auipc	ra,0x0
    8000082a:	404080e7          	jalr	1028(ra) # 80000c2a <pop_off>
}
    8000082e:	60e2                	ld	ra,24(sp)
    80000830:	6442                	ld	s0,16(sp)
    80000832:	64a2                	ld	s1,8(sp)
    80000834:	6105                	addi	sp,sp,32
    80000836:	8082                	ret

0000000080000838 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000838:	00008797          	auipc	a5,0x8
    8000083c:	2907b783          	ld	a5,656(a5) # 80008ac8 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	29073703          	ld	a4,656(a4) # 80008ad0 <uart_tx_w>
    80000848:	06f70a63          	beq	a4,a5,800008bc <uartstart+0x84>
{
    8000084c:	7139                	addi	sp,sp,-64
    8000084e:	fc06                	sd	ra,56(sp)
    80000850:	f822                	sd	s0,48(sp)
    80000852:	f426                	sd	s1,40(sp)
    80000854:	f04a                	sd	s2,32(sp)
    80000856:	ec4e                	sd	s3,24(sp)
    80000858:	e852                	sd	s4,16(sp)
    8000085a:	e456                	sd	s5,8(sp)
    8000085c:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085e:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000862:	00010a17          	auipc	s4,0x10
    80000866:	4a6a0a13          	addi	s4,s4,1190 # 80010d08 <uart_tx_lock>
    uart_tx_r += 1;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	25e48493          	addi	s1,s1,606 # 80008ac8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008997          	auipc	s3,0x8
    80000876:	25e98993          	addi	s3,s3,606 # 80008ad0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087a:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087e:	02077713          	andi	a4,a4,32
    80000882:	c705                	beqz	a4,800008aa <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000884:	01f7f713          	andi	a4,a5,31
    80000888:	9752                	add	a4,a4,s4
    8000088a:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088e:	0785                	addi	a5,a5,1
    80000890:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000892:	8526                	mv	a0,s1
    80000894:	00002097          	auipc	ra,0x2
    80000898:	85e080e7          	jalr	-1954(ra) # 800020f2 <wakeup>
    
    WriteReg(THR, c);
    8000089c:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008a0:	609c                	ld	a5,0(s1)
    800008a2:	0009b703          	ld	a4,0(s3)
    800008a6:	fcf71ae3          	bne	a4,a5,8000087a <uartstart+0x42>
  }
}
    800008aa:	70e2                	ld	ra,56(sp)
    800008ac:	7442                	ld	s0,48(sp)
    800008ae:	74a2                	ld	s1,40(sp)
    800008b0:	7902                	ld	s2,32(sp)
    800008b2:	69e2                	ld	s3,24(sp)
    800008b4:	6a42                	ld	s4,16(sp)
    800008b6:	6aa2                	ld	s5,8(sp)
    800008b8:	6121                	addi	sp,sp,64
    800008ba:	8082                	ret
    800008bc:	8082                	ret

00000000800008be <uartputc>:
{
    800008be:	7179                	addi	sp,sp,-48
    800008c0:	f406                	sd	ra,40(sp)
    800008c2:	f022                	sd	s0,32(sp)
    800008c4:	ec26                	sd	s1,24(sp)
    800008c6:	e84a                	sd	s2,16(sp)
    800008c8:	e44e                	sd	s3,8(sp)
    800008ca:	e052                	sd	s4,0(sp)
    800008cc:	1800                	addi	s0,sp,48
    800008ce:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008d0:	00010517          	auipc	a0,0x10
    800008d4:	43850513          	addi	a0,a0,1080 # 80010d08 <uart_tx_lock>
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	2fe080e7          	jalr	766(ra) # 80000bd6 <acquire>
  if(panicked){
    800008e0:	00008797          	auipc	a5,0x8
    800008e4:	1e07a783          	lw	a5,480(a5) # 80008ac0 <panicked>
    800008e8:	e7c9                	bnez	a5,80000972 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008717          	auipc	a4,0x8
    800008ee:	1e673703          	ld	a4,486(a4) # 80008ad0 <uart_tx_w>
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	1d67b783          	ld	a5,470(a5) # 80008ac8 <uart_tx_r>
    800008fa:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00010997          	auipc	s3,0x10
    80000902:	40a98993          	addi	s3,s3,1034 # 80010d08 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	1c248493          	addi	s1,s1,450 # 80008ac8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	1c290913          	addi	s2,s2,450 # 80008ad0 <uart_tx_w>
    80000916:	00e79f63          	bne	a5,a4,80000934 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85ce                	mv	a1,s3
    8000091c:	8526                	mv	a0,s1
    8000091e:	00001097          	auipc	ra,0x1
    80000922:	770080e7          	jalr	1904(ra) # 8000208e <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093703          	ld	a4,0(s2)
    8000092a:	609c                	ld	a5,0(s1)
    8000092c:	02078793          	addi	a5,a5,32
    80000930:	fee785e3          	beq	a5,a4,8000091a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00010497          	auipc	s1,0x10
    80000938:	3d448493          	addi	s1,s1,980 # 80010d08 <uart_tx_lock>
    8000093c:	01f77793          	andi	a5,a4,31
    80000940:	97a6                	add	a5,a5,s1
    80000942:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000946:	0705                	addi	a4,a4,1
    80000948:	00008797          	auipc	a5,0x8
    8000094c:	18e7b423          	sd	a4,392(a5) # 80008ad0 <uart_tx_w>
  uartstart();
    80000950:	00000097          	auipc	ra,0x0
    80000954:	ee8080e7          	jalr	-280(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    80000958:	8526                	mv	a0,s1
    8000095a:	00000097          	auipc	ra,0x0
    8000095e:	330080e7          	jalr	816(ra) # 80000c8a <release>
}
    80000962:	70a2                	ld	ra,40(sp)
    80000964:	7402                	ld	s0,32(sp)
    80000966:	64e2                	ld	s1,24(sp)
    80000968:	6942                	ld	s2,16(sp)
    8000096a:	69a2                	ld	s3,8(sp)
    8000096c:	6a02                	ld	s4,0(sp)
    8000096e:	6145                	addi	sp,sp,48
    80000970:	8082                	ret
    for(;;)
    80000972:	a001                	j	80000972 <uartputc+0xb4>

0000000080000974 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000974:	1141                	addi	sp,sp,-16
    80000976:	e422                	sd	s0,8(sp)
    80000978:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000097a:	100007b7          	lui	a5,0x10000
    8000097e:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000982:	8b85                	andi	a5,a5,1
    80000984:	cb81                	beqz	a5,80000994 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000098e:	6422                	ld	s0,8(sp)
    80000990:	0141                	addi	sp,sp,16
    80000992:	8082                	ret
    return -1;
    80000994:	557d                	li	a0,-1
    80000996:	bfe5                	j	8000098e <uartgetc+0x1a>

0000000080000998 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000998:	1101                	addi	sp,sp,-32
    8000099a:	ec06                	sd	ra,24(sp)
    8000099c:	e822                	sd	s0,16(sp)
    8000099e:	e426                	sd	s1,8(sp)
    800009a0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a2:	54fd                	li	s1,-1
    800009a4:	a029                	j	800009ae <uartintr+0x16>
      break;
    consoleintr(c);
    800009a6:	00000097          	auipc	ra,0x0
    800009aa:	918080e7          	jalr	-1768(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009ae:	00000097          	auipc	ra,0x0
    800009b2:	fc6080e7          	jalr	-58(ra) # 80000974 <uartgetc>
    if(c == -1)
    800009b6:	fe9518e3          	bne	a0,s1,800009a6 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ba:	00010497          	auipc	s1,0x10
    800009be:	34e48493          	addi	s1,s1,846 # 80010d08 <uart_tx_lock>
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	212080e7          	jalr	530(ra) # 80000bd6 <acquire>
  uartstart();
    800009cc:	00000097          	auipc	ra,0x0
    800009d0:	e6c080e7          	jalr	-404(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    800009d4:	8526                	mv	a0,s1
    800009d6:	00000097          	auipc	ra,0x0
    800009da:	2b4080e7          	jalr	692(ra) # 80000c8a <release>
}
    800009de:	60e2                	ld	ra,24(sp)
    800009e0:	6442                	ld	s0,16(sp)
    800009e2:	64a2                	ld	s1,8(sp)
    800009e4:	6105                	addi	sp,sp,32
    800009e6:	8082                	ret

00000000800009e8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e8:	1101                	addi	sp,sp,-32
    800009ea:	ec06                	sd	ra,24(sp)
    800009ec:	e822                	sd	s0,16(sp)
    800009ee:	e426                	sd	s1,8(sp)
    800009f0:	e04a                	sd	s2,0(sp)
    800009f2:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f4:	03451793          	slli	a5,a0,0x34
    800009f8:	ebb9                	bnez	a5,80000a4e <kfree+0x66>
    800009fa:	84aa                	mv	s1,a0
    800009fc:	0002d797          	auipc	a5,0x2d
    80000a00:	78478793          	addi	a5,a5,1924 # 8002e180 <end>
    80000a04:	04f56563          	bltu	a0,a5,80000a4e <kfree+0x66>
    80000a08:	47c5                	li	a5,17
    80000a0a:	07ee                	slli	a5,a5,0x1b
    80000a0c:	04f57163          	bgeu	a0,a5,80000a4e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a10:	6605                	lui	a2,0x1
    80000a12:	4585                	li	a1,1
    80000a14:	00000097          	auipc	ra,0x0
    80000a18:	2be080e7          	jalr	702(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1c:	00010917          	auipc	s2,0x10
    80000a20:	32490913          	addi	s2,s2,804 # 80010d40 <kmem>
    80000a24:	854a                	mv	a0,s2
    80000a26:	00000097          	auipc	ra,0x0
    80000a2a:	1b0080e7          	jalr	432(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a2e:	01893783          	ld	a5,24(s2)
    80000a32:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a34:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a38:	854a                	mv	a0,s2
    80000a3a:	00000097          	auipc	ra,0x0
    80000a3e:	250080e7          	jalr	592(ra) # 80000c8a <release>
}
    80000a42:	60e2                	ld	ra,24(sp)
    80000a44:	6442                	ld	s0,16(sp)
    80000a46:	64a2                	ld	s1,8(sp)
    80000a48:	6902                	ld	s2,0(sp)
    80000a4a:	6105                	addi	sp,sp,32
    80000a4c:	8082                	ret
    panic("kfree");
    80000a4e:	00007517          	auipc	a0,0x7
    80000a52:	61250513          	addi	a0,a0,1554 # 80008060 <digits+0x20>
    80000a56:	00000097          	auipc	ra,0x0
    80000a5a:	aea080e7          	jalr	-1302(ra) # 80000540 <panic>

0000000080000a5e <freerange>:
{
    80000a5e:	7179                	addi	sp,sp,-48
    80000a60:	f406                	sd	ra,40(sp)
    80000a62:	f022                	sd	s0,32(sp)
    80000a64:	ec26                	sd	s1,24(sp)
    80000a66:	e84a                	sd	s2,16(sp)
    80000a68:	e44e                	sd	s3,8(sp)
    80000a6a:	e052                	sd	s4,0(sp)
    80000a6c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a6e:	6785                	lui	a5,0x1
    80000a70:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a74:	00e504b3          	add	s1,a0,a4
    80000a78:	777d                	lui	a4,0xfffff
    80000a7a:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3c>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5c080e7          	jalr	-164(ra) # 800009e8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x2a>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	28650513          	addi	a0,a0,646 # 80010d40 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	0002d517          	auipc	a0,0x2d
    80000ad2:	6b250513          	addi	a0,a0,1714 # 8002e180 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f88080e7          	jalr	-120(ra) # 80000a5e <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	25048493          	addi	s1,s1,592 # 80010d40 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	23850513          	addi	a0,a0,568 # 80010d40 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	20c50513          	addi	a0,a0,524 # 80010d40 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	e20080e7          	jalr	-480(ra) # 80001990 <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	dee080e7          	jalr	-530(ra) # 80001990 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	de2080e7          	jalr	-542(ra) # 80001990 <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	dca080e7          	jalr	-566(ra) # 80001990 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	d8a080e7          	jalr	-630(ra) # 80001990 <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	91e080e7          	jalr	-1762(ra) # 80000540 <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	d5e080e7          	jalr	-674(ra) # 80001990 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8ce080e7          	jalr	-1842(ra) # 80000540 <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8be080e7          	jalr	-1858(ra) # 80000540 <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	876080e7          	jalr	-1930(ra) # 80000540 <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ca19                	beqz	a2,80000cee <memset+0x1c>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	1602                	slli	a2,a2,0x20
    80000cde:	9201                	srli	a2,a2,0x20
    80000ce0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce8:	0785                	addi	a5,a5,1
    80000cea:	fee79de3          	bne	a5,a4,80000ce4 <memset+0x12>
  }
  return dst;
}
    80000cee:	6422                	ld	s0,8(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret

0000000080000cf4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf4:	1141                	addi	sp,sp,-16
    80000cf6:	e422                	sd	s0,8(sp)
    80000cf8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfa:	ca05                	beqz	a2,80000d2a <memcmp+0x36>
    80000cfc:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d00:	1682                	slli	a3,a3,0x20
    80000d02:	9281                	srli	a3,a3,0x20
    80000d04:	0685                	addi	a3,a3,1
    80000d06:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d08:	00054783          	lbu	a5,0(a0)
    80000d0c:	0005c703          	lbu	a4,0(a1)
    80000d10:	00e79863          	bne	a5,a4,80000d20 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d14:	0505                	addi	a0,a0,1
    80000d16:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d18:	fed518e3          	bne	a0,a3,80000d08 <memcmp+0x14>
  }

  return 0;
    80000d1c:	4501                	li	a0,0
    80000d1e:	a019                	j	80000d24 <memcmp+0x30>
      return *s1 - *s2;
    80000d20:	40e7853b          	subw	a0,a5,a4
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  return 0;
    80000d2a:	4501                	li	a0,0
    80000d2c:	bfe5                	j	80000d24 <memcmp+0x30>

0000000080000d2e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d34:	c205                	beqz	a2,80000d54 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d36:	02a5e263          	bltu	a1,a0,80000d5a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d3a:	1602                	slli	a2,a2,0x20
    80000d3c:	9201                	srli	a2,a2,0x20
    80000d3e:	00c587b3          	add	a5,a1,a2
{
    80000d42:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d44:	0585                	addi	a1,a1,1
    80000d46:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffd0e81>
    80000d48:	fff5c683          	lbu	a3,-1(a1)
    80000d4c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d50:	fef59ae3          	bne	a1,a5,80000d44 <memmove+0x16>

  return dst;
}
    80000d54:	6422                	ld	s0,8(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret
  if(s < d && s + n > d){
    80000d5a:	02061693          	slli	a3,a2,0x20
    80000d5e:	9281                	srli	a3,a3,0x20
    80000d60:	00d58733          	add	a4,a1,a3
    80000d64:	fce57be3          	bgeu	a0,a4,80000d3a <memmove+0xc>
    d += n;
    80000d68:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d6a:	fff6079b          	addiw	a5,a2,-1
    80000d6e:	1782                	slli	a5,a5,0x20
    80000d70:	9381                	srli	a5,a5,0x20
    80000d72:	fff7c793          	not	a5,a5
    80000d76:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d78:	177d                	addi	a4,a4,-1
    80000d7a:	16fd                	addi	a3,a3,-1
    80000d7c:	00074603          	lbu	a2,0(a4)
    80000d80:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d84:	fee79ae3          	bne	a5,a4,80000d78 <memmove+0x4a>
    80000d88:	b7f1                	j	80000d54 <memmove+0x26>

0000000080000d8a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d8a:	1141                	addi	sp,sp,-16
    80000d8c:	e406                	sd	ra,8(sp)
    80000d8e:	e022                	sd	s0,0(sp)
    80000d90:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	f9c080e7          	jalr	-100(ra) # 80000d2e <memmove>
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret

0000000080000da2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000da2:	1141                	addi	sp,sp,-16
    80000da4:	e422                	sd	s0,8(sp)
    80000da6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da8:	ce11                	beqz	a2,80000dc4 <strncmp+0x22>
    80000daa:	00054783          	lbu	a5,0(a0)
    80000dae:	cf89                	beqz	a5,80000dc8 <strncmp+0x26>
    80000db0:	0005c703          	lbu	a4,0(a1)
    80000db4:	00f71a63          	bne	a4,a5,80000dc8 <strncmp+0x26>
    n--, p++, q++;
    80000db8:	367d                	addiw	a2,a2,-1
    80000dba:	0505                	addi	a0,a0,1
    80000dbc:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dbe:	f675                	bnez	a2,80000daa <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dc0:	4501                	li	a0,0
    80000dc2:	a809                	j	80000dd4 <strncmp+0x32>
    80000dc4:	4501                	li	a0,0
    80000dc6:	a039                	j	80000dd4 <strncmp+0x32>
  if(n == 0)
    80000dc8:	ca09                	beqz	a2,80000dda <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dca:	00054503          	lbu	a0,0(a0)
    80000dce:	0005c783          	lbu	a5,0(a1)
    80000dd2:	9d1d                	subw	a0,a0,a5
}
    80000dd4:	6422                	ld	s0,8(sp)
    80000dd6:	0141                	addi	sp,sp,16
    80000dd8:	8082                	ret
    return 0;
    80000dda:	4501                	li	a0,0
    80000ddc:	bfe5                	j	80000dd4 <strncmp+0x32>

0000000080000dde <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e422                	sd	s0,8(sp)
    80000de2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de4:	872a                	mv	a4,a0
    80000de6:	8832                	mv	a6,a2
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	01005963          	blez	a6,80000dfc <strncpy+0x1e>
    80000dee:	0705                	addi	a4,a4,1
    80000df0:	0005c783          	lbu	a5,0(a1)
    80000df4:	fef70fa3          	sb	a5,-1(a4)
    80000df8:	0585                	addi	a1,a1,1
    80000dfa:	f7f5                	bnez	a5,80000de6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dfc:	86ba                	mv	a3,a4
    80000dfe:	00c05c63          	blez	a2,80000e16 <strncpy+0x38>
    *s++ = 0;
    80000e02:	0685                	addi	a3,a3,1
    80000e04:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e08:	40d707bb          	subw	a5,a4,a3
    80000e0c:	37fd                	addiw	a5,a5,-1
    80000e0e:	010787bb          	addw	a5,a5,a6
    80000e12:	fef048e3          	bgtz	a5,80000e02 <strncpy+0x24>
  return os;
}
    80000e16:	6422                	ld	s0,8(sp)
    80000e18:	0141                	addi	sp,sp,16
    80000e1a:	8082                	ret

0000000080000e1c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e1c:	1141                	addi	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e22:	02c05363          	blez	a2,80000e48 <safestrcpy+0x2c>
    80000e26:	fff6069b          	addiw	a3,a2,-1
    80000e2a:	1682                	slli	a3,a3,0x20
    80000e2c:	9281                	srli	a3,a3,0x20
    80000e2e:	96ae                	add	a3,a3,a1
    80000e30:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e32:	00d58963          	beq	a1,a3,80000e44 <safestrcpy+0x28>
    80000e36:	0585                	addi	a1,a1,1
    80000e38:	0785                	addi	a5,a5,1
    80000e3a:	fff5c703          	lbu	a4,-1(a1)
    80000e3e:	fee78fa3          	sb	a4,-1(a5)
    80000e42:	fb65                	bnez	a4,80000e32 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e44:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret

0000000080000e4e <strlen>:

int
strlen(const char *s)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e422                	sd	s0,8(sp)
    80000e52:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e54:	00054783          	lbu	a5,0(a0)
    80000e58:	cf91                	beqz	a5,80000e74 <strlen+0x26>
    80000e5a:	0505                	addi	a0,a0,1
    80000e5c:	87aa                	mv	a5,a0
    80000e5e:	4685                	li	a3,1
    80000e60:	9e89                	subw	a3,a3,a0
    80000e62:	00f6853b          	addw	a0,a3,a5
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff7c703          	lbu	a4,-1(a5)
    80000e6c:	fb7d                	bnez	a4,80000e62 <strlen+0x14>
    ;
  return n;
}
    80000e6e:	6422                	ld	s0,8(sp)
    80000e70:	0141                	addi	sp,sp,16
    80000e72:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e74:	4501                	li	a0,0
    80000e76:	bfe5                	j	80000e6e <strlen+0x20>

0000000080000e78 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e78:	1141                	addi	sp,sp,-16
    80000e7a:	e406                	sd	ra,8(sp)
    80000e7c:	e022                	sd	s0,0(sp)
    80000e7e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e80:	00001097          	auipc	ra,0x1
    80000e84:	b00080e7          	jalr	-1280(ra) # 80001980 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	c5070713          	addi	a4,a4,-944 # 80008ad8 <started>
  if(cpuid() == 0){
    80000e90:	c139                	beqz	a0,80000ed6 <main+0x5e>
    while(started == 0)
    80000e92:	431c                	lw	a5,0(a4)
    80000e94:	2781                	sext.w	a5,a5
    80000e96:	dff5                	beqz	a5,80000e92 <main+0x1a>
      ;
    __sync_synchronize();
    80000e98:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	ae4080e7          	jalr	-1308(ra) # 80001980 <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	21250513          	addi	a0,a0,530 # 800080b8 <digits+0x78>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6dc080e7          	jalr	1756(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	0d8080e7          	jalr	216(ra) # 80000f8e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00001097          	auipc	ra,0x1
    80000ec2:	7c6080e7          	jalr	1990(ra) # 80002684 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	e9a080e7          	jalr	-358(ra) # 80005d60 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	fe4080e7          	jalr	-28(ra) # 80001eb2 <scheduler>
    consoleinit();
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	57a080e7          	jalr	1402(ra) # 80000450 <consoleinit>
    printfinit();
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	88c080e7          	jalr	-1908(ra) # 8000076a <printfinit>
    printf("\n");
    80000ee6:	00007517          	auipc	a0,0x7
    80000eea:	1e250513          	addi	a0,a0,482 # 800080c8 <digits+0x88>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69c080e7          	jalr	1692(ra) # 8000058a <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	1aa50513          	addi	a0,a0,426 # 800080a0 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68c080e7          	jalr	1676(ra) # 8000058a <printf>
    printf("\n");
    80000f06:	00007517          	auipc	a0,0x7
    80000f0a:	1c250513          	addi	a0,a0,450 # 800080c8 <digits+0x88>
    80000f0e:	fffff097          	auipc	ra,0xfffff
    80000f12:	67c080e7          	jalr	1660(ra) # 8000058a <printf>
    kinit();         // physical page allocator
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	b94080e7          	jalr	-1132(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f1e:	00000097          	auipc	ra,0x0
    80000f22:	326080e7          	jalr	806(ra) # 80001244 <kvminit>
    kvminithart();   // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	068080e7          	jalr	104(ra) # 80000f8e <kvminithart>
    procinit();      // process table
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	99e080e7          	jalr	-1634(ra) # 800018cc <procinit>
    trapinit();      // trap vectors
    80000f36:	00001097          	auipc	ra,0x1
    80000f3a:	726080e7          	jalr	1830(ra) # 8000265c <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00001097          	auipc	ra,0x1
    80000f42:	746080e7          	jalr	1862(ra) # 80002684 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	e04080e7          	jalr	-508(ra) # 80005d4a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	e12080e7          	jalr	-494(ra) # 80005d60 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	fb2080e7          	jalr	-78(ra) # 80002f08 <binit>
    iinit();         // inode table
    80000f5e:	00002097          	auipc	ra,0x2
    80000f62:	652080e7          	jalr	1618(ra) # 800035b0 <iinit>
    fileinit();      // file table
    80000f66:	00003097          	auipc	ra,0x3
    80000f6a:	5f8080e7          	jalr	1528(ra) # 8000455e <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	efa080e7          	jalr	-262(ra) # 80005e68 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	d0e080e7          	jalr	-754(ra) # 80001c84 <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	b4f72a23          	sw	a5,-1196(a4) # 80008ad8 <started>
    80000f8c:	b789                	j	80000ece <main+0x56>

0000000080000f8e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f8e:	1141                	addi	sp,sp,-16
    80000f90:	e422                	sd	s0,8(sp)
    80000f92:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f94:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f98:	00008797          	auipc	a5,0x8
    80000f9c:	b487b783          	ld	a5,-1208(a5) # 80008ae0 <kernel_pagetable>
    80000fa0:	83b1                	srli	a5,a5,0xc
    80000fa2:	577d                	li	a4,-1
    80000fa4:	177e                	slli	a4,a4,0x3f
    80000fa6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa8:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fac:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fb0:	6422                	ld	s0,8(sp)
    80000fb2:	0141                	addi	sp,sp,16
    80000fb4:	8082                	ret

0000000080000fb6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb6:	7139                	addi	sp,sp,-64
    80000fb8:	fc06                	sd	ra,56(sp)
    80000fba:	f822                	sd	s0,48(sp)
    80000fbc:	f426                	sd	s1,40(sp)
    80000fbe:	f04a                	sd	s2,32(sp)
    80000fc0:	ec4e                	sd	s3,24(sp)
    80000fc2:	e852                	sd	s4,16(sp)
    80000fc4:	e456                	sd	s5,8(sp)
    80000fc6:	e05a                	sd	s6,0(sp)
    80000fc8:	0080                	addi	s0,sp,64
    80000fca:	84aa                	mv	s1,a0
    80000fcc:	89ae                	mv	s3,a1
    80000fce:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd0:	57fd                	li	a5,-1
    80000fd2:	83e9                	srli	a5,a5,0x1a
    80000fd4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd8:	04b7f263          	bgeu	a5,a1,8000101c <walk+0x66>
    panic("walk");
    80000fdc:	00007517          	auipc	a0,0x7
    80000fe0:	0f450513          	addi	a0,a0,244 # 800080d0 <digits+0x90>
    80000fe4:	fffff097          	auipc	ra,0xfffff
    80000fe8:	55c080e7          	jalr	1372(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fec:	060a8663          	beqz	s5,80001058 <walk+0xa2>
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	af6080e7          	jalr	-1290(ra) # 80000ae6 <kalloc>
    80000ff8:	84aa                	mv	s1,a0
    80000ffa:	c529                	beqz	a0,80001044 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ffc:	6605                	lui	a2,0x1
    80000ffe:	4581                	li	a1,0
    80001000:	00000097          	auipc	ra,0x0
    80001004:	cd2080e7          	jalr	-814(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001008:	00c4d793          	srli	a5,s1,0xc
    8000100c:	07aa                	slli	a5,a5,0xa
    8000100e:	0017e793          	ori	a5,a5,1
    80001012:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001016:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffd0e77>
    80001018:	036a0063          	beq	s4,s6,80001038 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000101c:	0149d933          	srl	s2,s3,s4
    80001020:	1ff97913          	andi	s2,s2,511
    80001024:	090e                	slli	s2,s2,0x3
    80001026:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001028:	00093483          	ld	s1,0(s2)
    8000102c:	0014f793          	andi	a5,s1,1
    80001030:	dfd5                	beqz	a5,80000fec <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001032:	80a9                	srli	s1,s1,0xa
    80001034:	04b2                	slli	s1,s1,0xc
    80001036:	b7c5                	j	80001016 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001038:	00c9d513          	srli	a0,s3,0xc
    8000103c:	1ff57513          	andi	a0,a0,511
    80001040:	050e                	slli	a0,a0,0x3
    80001042:	9526                	add	a0,a0,s1
}
    80001044:	70e2                	ld	ra,56(sp)
    80001046:	7442                	ld	s0,48(sp)
    80001048:	74a2                	ld	s1,40(sp)
    8000104a:	7902                	ld	s2,32(sp)
    8000104c:	69e2                	ld	s3,24(sp)
    8000104e:	6a42                	ld	s4,16(sp)
    80001050:	6aa2                	ld	s5,8(sp)
    80001052:	6b02                	ld	s6,0(sp)
    80001054:	6121                	addi	sp,sp,64
    80001056:	8082                	ret
        return 0;
    80001058:	4501                	li	a0,0
    8000105a:	b7ed                	j	80001044 <walk+0x8e>

000000008000105c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000105c:	57fd                	li	a5,-1
    8000105e:	83e9                	srli	a5,a5,0x1a
    80001060:	00b7f463          	bgeu	a5,a1,80001068 <walkaddr+0xc>
    return 0;
    80001064:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001066:	8082                	ret
{
    80001068:	1141                	addi	sp,sp,-16
    8000106a:	e406                	sd	ra,8(sp)
    8000106c:	e022                	sd	s0,0(sp)
    8000106e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001070:	4601                	li	a2,0
    80001072:	00000097          	auipc	ra,0x0
    80001076:	f44080e7          	jalr	-188(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000107a:	c105                	beqz	a0,8000109a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000107c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000107e:	0117f693          	andi	a3,a5,17
    80001082:	4745                	li	a4,17
    return 0;
    80001084:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001086:	00e68663          	beq	a3,a4,80001092 <walkaddr+0x36>
}
    8000108a:	60a2                	ld	ra,8(sp)
    8000108c:	6402                	ld	s0,0(sp)
    8000108e:	0141                	addi	sp,sp,16
    80001090:	8082                	ret
  pa = PTE2PA(*pte);
    80001092:	83a9                	srli	a5,a5,0xa
    80001094:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001098:	bfcd                	j	8000108a <walkaddr+0x2e>
    return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7fd                	j	8000108a <walkaddr+0x2e>

000000008000109e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000109e:	715d                	addi	sp,sp,-80
    800010a0:	e486                	sd	ra,72(sp)
    800010a2:	e0a2                	sd	s0,64(sp)
    800010a4:	fc26                	sd	s1,56(sp)
    800010a6:	f84a                	sd	s2,48(sp)
    800010a8:	f44e                	sd	s3,40(sp)
    800010aa:	f052                	sd	s4,32(sp)
    800010ac:	ec56                	sd	s5,24(sp)
    800010ae:	e85a                	sd	s6,16(sp)
    800010b0:	e45e                	sd	s7,8(sp)
    800010b2:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010b4:	c639                	beqz	a2,80001102 <mappages+0x64>
    800010b6:	8aaa                	mv	s5,a0
    800010b8:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010ba:	777d                	lui	a4,0xfffff
    800010bc:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010c0:	fff58993          	addi	s3,a1,-1
    800010c4:	99b2                	add	s3,s3,a2
    800010c6:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010ca:	893e                	mv	s2,a5
    800010cc:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d0:	6b85                	lui	s7,0x1
    800010d2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010d6:	4605                	li	a2,1
    800010d8:	85ca                	mv	a1,s2
    800010da:	8556                	mv	a0,s5
    800010dc:	00000097          	auipc	ra,0x0
    800010e0:	eda080e7          	jalr	-294(ra) # 80000fb6 <walk>
    800010e4:	cd1d                	beqz	a0,80001122 <mappages+0x84>
    if(*pte & PTE_V)
    800010e6:	611c                	ld	a5,0(a0)
    800010e8:	8b85                	andi	a5,a5,1
    800010ea:	e785                	bnez	a5,80001112 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010ec:	80b1                	srli	s1,s1,0xc
    800010ee:	04aa                	slli	s1,s1,0xa
    800010f0:	0164e4b3          	or	s1,s1,s6
    800010f4:	0014e493          	ori	s1,s1,1
    800010f8:	e104                	sd	s1,0(a0)
    if(a == last)
    800010fa:	05390063          	beq	s2,s3,8000113a <mappages+0x9c>
    a += PGSIZE;
    800010fe:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001100:	bfc9                	j	800010d2 <mappages+0x34>
    panic("mappages: size");
    80001102:	00007517          	auipc	a0,0x7
    80001106:	fd650513          	addi	a0,a0,-42 # 800080d8 <digits+0x98>
    8000110a:	fffff097          	auipc	ra,0xfffff
    8000110e:	436080e7          	jalr	1078(ra) # 80000540 <panic>
      panic("mappages: remap");
    80001112:	00007517          	auipc	a0,0x7
    80001116:	fd650513          	addi	a0,a0,-42 # 800080e8 <digits+0xa8>
    8000111a:	fffff097          	auipc	ra,0xfffff
    8000111e:	426080e7          	jalr	1062(ra) # 80000540 <panic>
      return -1;
    80001122:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001124:	60a6                	ld	ra,72(sp)
    80001126:	6406                	ld	s0,64(sp)
    80001128:	74e2                	ld	s1,56(sp)
    8000112a:	7942                	ld	s2,48(sp)
    8000112c:	79a2                	ld	s3,40(sp)
    8000112e:	7a02                	ld	s4,32(sp)
    80001130:	6ae2                	ld	s5,24(sp)
    80001132:	6b42                	ld	s6,16(sp)
    80001134:	6ba2                	ld	s7,8(sp)
    80001136:	6161                	addi	sp,sp,80
    80001138:	8082                	ret
  return 0;
    8000113a:	4501                	li	a0,0
    8000113c:	b7e5                	j	80001124 <mappages+0x86>

000000008000113e <kvmmap>:
{
    8000113e:	1141                	addi	sp,sp,-16
    80001140:	e406                	sd	ra,8(sp)
    80001142:	e022                	sd	s0,0(sp)
    80001144:	0800                	addi	s0,sp,16
    80001146:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001148:	86b2                	mv	a3,a2
    8000114a:	863e                	mv	a2,a5
    8000114c:	00000097          	auipc	ra,0x0
    80001150:	f52080e7          	jalr	-174(ra) # 8000109e <mappages>
    80001154:	e509                	bnez	a0,8000115e <kvmmap+0x20>
}
    80001156:	60a2                	ld	ra,8(sp)
    80001158:	6402                	ld	s0,0(sp)
    8000115a:	0141                	addi	sp,sp,16
    8000115c:	8082                	ret
    panic("kvmmap");
    8000115e:	00007517          	auipc	a0,0x7
    80001162:	f9a50513          	addi	a0,a0,-102 # 800080f8 <digits+0xb8>
    80001166:	fffff097          	auipc	ra,0xfffff
    8000116a:	3da080e7          	jalr	986(ra) # 80000540 <panic>

000000008000116e <kvmmake>:
{
    8000116e:	1101                	addi	sp,sp,-32
    80001170:	ec06                	sd	ra,24(sp)
    80001172:	e822                	sd	s0,16(sp)
    80001174:	e426                	sd	s1,8(sp)
    80001176:	e04a                	sd	s2,0(sp)
    80001178:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	96c080e7          	jalr	-1684(ra) # 80000ae6 <kalloc>
    80001182:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001184:	6605                	lui	a2,0x1
    80001186:	4581                	li	a1,0
    80001188:	00000097          	auipc	ra,0x0
    8000118c:	b4a080e7          	jalr	-1206(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001190:	4719                	li	a4,6
    80001192:	6685                	lui	a3,0x1
    80001194:	10000637          	lui	a2,0x10000
    80001198:	100005b7          	lui	a1,0x10000
    8000119c:	8526                	mv	a0,s1
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	fa0080e7          	jalr	-96(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011a6:	4719                	li	a4,6
    800011a8:	6685                	lui	a3,0x1
    800011aa:	10001637          	lui	a2,0x10001
    800011ae:	100015b7          	lui	a1,0x10001
    800011b2:	8526                	mv	a0,s1
    800011b4:	00000097          	auipc	ra,0x0
    800011b8:	f8a080e7          	jalr	-118(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011bc:	4719                	li	a4,6
    800011be:	004006b7          	lui	a3,0x400
    800011c2:	0c000637          	lui	a2,0xc000
    800011c6:	0c0005b7          	lui	a1,0xc000
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f72080e7          	jalr	-142(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011d4:	00007917          	auipc	s2,0x7
    800011d8:	e2c90913          	addi	s2,s2,-468 # 80008000 <etext>
    800011dc:	4729                	li	a4,10
    800011de:	80007697          	auipc	a3,0x80007
    800011e2:	e2268693          	addi	a3,a3,-478 # 8000 <_entry-0x7fff8000>
    800011e6:	4605                	li	a2,1
    800011e8:	067e                	slli	a2,a2,0x1f
    800011ea:	85b2                	mv	a1,a2
    800011ec:	8526                	mv	a0,s1
    800011ee:	00000097          	auipc	ra,0x0
    800011f2:	f50080e7          	jalr	-176(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011f6:	4719                	li	a4,6
    800011f8:	46c5                	li	a3,17
    800011fa:	06ee                	slli	a3,a3,0x1b
    800011fc:	412686b3          	sub	a3,a3,s2
    80001200:	864a                	mv	a2,s2
    80001202:	85ca                	mv	a1,s2
    80001204:	8526                	mv	a0,s1
    80001206:	00000097          	auipc	ra,0x0
    8000120a:	f38080e7          	jalr	-200(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000120e:	4729                	li	a4,10
    80001210:	6685                	lui	a3,0x1
    80001212:	00006617          	auipc	a2,0x6
    80001216:	dee60613          	addi	a2,a2,-530 # 80007000 <_trampoline>
    8000121a:	040005b7          	lui	a1,0x4000
    8000121e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001220:	05b2                	slli	a1,a1,0xc
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	f1a080e7          	jalr	-230(ra) # 8000113e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000122c:	8526                	mv	a0,s1
    8000122e:	00000097          	auipc	ra,0x0
    80001232:	608080e7          	jalr	1544(ra) # 80001836 <proc_mapstacks>
}
    80001236:	8526                	mv	a0,s1
    80001238:	60e2                	ld	ra,24(sp)
    8000123a:	6442                	ld	s0,16(sp)
    8000123c:	64a2                	ld	s1,8(sp)
    8000123e:	6902                	ld	s2,0(sp)
    80001240:	6105                	addi	sp,sp,32
    80001242:	8082                	ret

0000000080001244 <kvminit>:
{
    80001244:	1141                	addi	sp,sp,-16
    80001246:	e406                	sd	ra,8(sp)
    80001248:	e022                	sd	s0,0(sp)
    8000124a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000124c:	00000097          	auipc	ra,0x0
    80001250:	f22080e7          	jalr	-222(ra) # 8000116e <kvmmake>
    80001254:	00008797          	auipc	a5,0x8
    80001258:	88a7b623          	sd	a0,-1908(a5) # 80008ae0 <kernel_pagetable>
}
    8000125c:	60a2                	ld	ra,8(sp)
    8000125e:	6402                	ld	s0,0(sp)
    80001260:	0141                	addi	sp,sp,16
    80001262:	8082                	ret

0000000080001264 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001264:	715d                	addi	sp,sp,-80
    80001266:	e486                	sd	ra,72(sp)
    80001268:	e0a2                	sd	s0,64(sp)
    8000126a:	fc26                	sd	s1,56(sp)
    8000126c:	f84a                	sd	s2,48(sp)
    8000126e:	f44e                	sd	s3,40(sp)
    80001270:	f052                	sd	s4,32(sp)
    80001272:	ec56                	sd	s5,24(sp)
    80001274:	e85a                	sd	s6,16(sp)
    80001276:	e45e                	sd	s7,8(sp)
    80001278:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000127a:	03459793          	slli	a5,a1,0x34
    8000127e:	e795                	bnez	a5,800012aa <uvmunmap+0x46>
    80001280:	8a2a                	mv	s4,a0
    80001282:	892e                	mv	s2,a1
    80001284:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001286:	0632                	slli	a2,a2,0xc
    80001288:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000128c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000128e:	6b05                	lui	s6,0x1
    80001290:	0735e263          	bltu	a1,s3,800012f4 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001294:	60a6                	ld	ra,72(sp)
    80001296:	6406                	ld	s0,64(sp)
    80001298:	74e2                	ld	s1,56(sp)
    8000129a:	7942                	ld	s2,48(sp)
    8000129c:	79a2                	ld	s3,40(sp)
    8000129e:	7a02                	ld	s4,32(sp)
    800012a0:	6ae2                	ld	s5,24(sp)
    800012a2:	6b42                	ld	s6,16(sp)
    800012a4:	6ba2                	ld	s7,8(sp)
    800012a6:	6161                	addi	sp,sp,80
    800012a8:	8082                	ret
    panic("uvmunmap: not aligned");
    800012aa:	00007517          	auipc	a0,0x7
    800012ae:	e5650513          	addi	a0,a0,-426 # 80008100 <digits+0xc0>
    800012b2:	fffff097          	auipc	ra,0xfffff
    800012b6:	28e080e7          	jalr	654(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    800012ba:	00007517          	auipc	a0,0x7
    800012be:	e5e50513          	addi	a0,a0,-418 # 80008118 <digits+0xd8>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	27e080e7          	jalr	638(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e5e50513          	addi	a0,a0,-418 # 80008128 <digits+0xe8>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	26e080e7          	jalr	622(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e6650513          	addi	a0,a0,-410 # 80008140 <digits+0x100>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	25e080e7          	jalr	606(ra) # 80000540 <panic>
    *pte = 0;
    800012ea:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ee:	995a                	add	s2,s2,s6
    800012f0:	fb3972e3          	bgeu	s2,s3,80001294 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012f4:	4601                	li	a2,0
    800012f6:	85ca                	mv	a1,s2
    800012f8:	8552                	mv	a0,s4
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	cbc080e7          	jalr	-836(ra) # 80000fb6 <walk>
    80001302:	84aa                	mv	s1,a0
    80001304:	d95d                	beqz	a0,800012ba <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001306:	6108                	ld	a0,0(a0)
    80001308:	00157793          	andi	a5,a0,1
    8000130c:	dfdd                	beqz	a5,800012ca <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000130e:	3ff57793          	andi	a5,a0,1023
    80001312:	fd7784e3          	beq	a5,s7,800012da <uvmunmap+0x76>
    if(do_free){
    80001316:	fc0a8ae3          	beqz	s5,800012ea <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000131a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000131c:	0532                	slli	a0,a0,0xc
    8000131e:	fffff097          	auipc	ra,0xfffff
    80001322:	6ca080e7          	jalr	1738(ra) # 800009e8 <kfree>
    80001326:	b7d1                	j	800012ea <uvmunmap+0x86>

0000000080001328 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001328:	1101                	addi	sp,sp,-32
    8000132a:	ec06                	sd	ra,24(sp)
    8000132c:	e822                	sd	s0,16(sp)
    8000132e:	e426                	sd	s1,8(sp)
    80001330:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001332:	fffff097          	auipc	ra,0xfffff
    80001336:	7b4080e7          	jalr	1972(ra) # 80000ae6 <kalloc>
    8000133a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000133c:	c519                	beqz	a0,8000134a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000133e:	6605                	lui	a2,0x1
    80001340:	4581                	li	a1,0
    80001342:	00000097          	auipc	ra,0x0
    80001346:	990080e7          	jalr	-1648(ra) # 80000cd2 <memset>
  return pagetable;
}
    8000134a:	8526                	mv	a0,s1
    8000134c:	60e2                	ld	ra,24(sp)
    8000134e:	6442                	ld	s0,16(sp)
    80001350:	64a2                	ld	s1,8(sp)
    80001352:	6105                	addi	sp,sp,32
    80001354:	8082                	ret

0000000080001356 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001356:	7179                	addi	sp,sp,-48
    80001358:	f406                	sd	ra,40(sp)
    8000135a:	f022                	sd	s0,32(sp)
    8000135c:	ec26                	sd	s1,24(sp)
    8000135e:	e84a                	sd	s2,16(sp)
    80001360:	e44e                	sd	s3,8(sp)
    80001362:	e052                	sd	s4,0(sp)
    80001364:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001366:	6785                	lui	a5,0x1
    80001368:	04f67863          	bgeu	a2,a5,800013b8 <uvmfirst+0x62>
    8000136c:	8a2a                	mv	s4,a0
    8000136e:	89ae                	mv	s3,a1
    80001370:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	774080e7          	jalr	1908(ra) # 80000ae6 <kalloc>
    8000137a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000137c:	6605                	lui	a2,0x1
    8000137e:	4581                	li	a1,0
    80001380:	00000097          	auipc	ra,0x0
    80001384:	952080e7          	jalr	-1710(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001388:	4779                	li	a4,30
    8000138a:	86ca                	mv	a3,s2
    8000138c:	6605                	lui	a2,0x1
    8000138e:	4581                	li	a1,0
    80001390:	8552                	mv	a0,s4
    80001392:	00000097          	auipc	ra,0x0
    80001396:	d0c080e7          	jalr	-756(ra) # 8000109e <mappages>
  memmove(mem, src, sz);
    8000139a:	8626                	mv	a2,s1
    8000139c:	85ce                	mv	a1,s3
    8000139e:	854a                	mv	a0,s2
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	98e080e7          	jalr	-1650(ra) # 80000d2e <memmove>
}
    800013a8:	70a2                	ld	ra,40(sp)
    800013aa:	7402                	ld	s0,32(sp)
    800013ac:	64e2                	ld	s1,24(sp)
    800013ae:	6942                	ld	s2,16(sp)
    800013b0:	69a2                	ld	s3,8(sp)
    800013b2:	6a02                	ld	s4,0(sp)
    800013b4:	6145                	addi	sp,sp,48
    800013b6:	8082                	ret
    panic("uvmfirst: more than a page");
    800013b8:	00007517          	auipc	a0,0x7
    800013bc:	da050513          	addi	a0,a0,-608 # 80008158 <digits+0x118>
    800013c0:	fffff097          	auipc	ra,0xfffff
    800013c4:	180080e7          	jalr	384(ra) # 80000540 <panic>

00000000800013c8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013c8:	1101                	addi	sp,sp,-32
    800013ca:	ec06                	sd	ra,24(sp)
    800013cc:	e822                	sd	s0,16(sp)
    800013ce:	e426                	sd	s1,8(sp)
    800013d0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013d2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013d4:	00b67d63          	bgeu	a2,a1,800013ee <uvmdealloc+0x26>
    800013d8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013da:	6785                	lui	a5,0x1
    800013dc:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013de:	00f60733          	add	a4,a2,a5
    800013e2:	76fd                	lui	a3,0xfffff
    800013e4:	8f75                	and	a4,a4,a3
    800013e6:	97ae                	add	a5,a5,a1
    800013e8:	8ff5                	and	a5,a5,a3
    800013ea:	00f76863          	bltu	a4,a5,800013fa <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013ee:	8526                	mv	a0,s1
    800013f0:	60e2                	ld	ra,24(sp)
    800013f2:	6442                	ld	s0,16(sp)
    800013f4:	64a2                	ld	s1,8(sp)
    800013f6:	6105                	addi	sp,sp,32
    800013f8:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013fa:	8f99                	sub	a5,a5,a4
    800013fc:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013fe:	4685                	li	a3,1
    80001400:	0007861b          	sext.w	a2,a5
    80001404:	85ba                	mv	a1,a4
    80001406:	00000097          	auipc	ra,0x0
    8000140a:	e5e080e7          	jalr	-418(ra) # 80001264 <uvmunmap>
    8000140e:	b7c5                	j	800013ee <uvmdealloc+0x26>

0000000080001410 <uvmalloc>:
  if(newsz < oldsz)
    80001410:	0ab66563          	bltu	a2,a1,800014ba <uvmalloc+0xaa>
{
    80001414:	7139                	addi	sp,sp,-64
    80001416:	fc06                	sd	ra,56(sp)
    80001418:	f822                	sd	s0,48(sp)
    8000141a:	f426                	sd	s1,40(sp)
    8000141c:	f04a                	sd	s2,32(sp)
    8000141e:	ec4e                	sd	s3,24(sp)
    80001420:	e852                	sd	s4,16(sp)
    80001422:	e456                	sd	s5,8(sp)
    80001424:	e05a                	sd	s6,0(sp)
    80001426:	0080                	addi	s0,sp,64
    80001428:	8aaa                	mv	s5,a0
    8000142a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000142c:	6785                	lui	a5,0x1
    8000142e:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001430:	95be                	add	a1,a1,a5
    80001432:	77fd                	lui	a5,0xfffff
    80001434:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001438:	08c9f363          	bgeu	s3,a2,800014be <uvmalloc+0xae>
    8000143c:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000143e:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001442:	fffff097          	auipc	ra,0xfffff
    80001446:	6a4080e7          	jalr	1700(ra) # 80000ae6 <kalloc>
    8000144a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000144c:	c51d                	beqz	a0,8000147a <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000144e:	6605                	lui	a2,0x1
    80001450:	4581                	li	a1,0
    80001452:	00000097          	auipc	ra,0x0
    80001456:	880080e7          	jalr	-1920(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	875a                	mv	a4,s6
    8000145c:	86a6                	mv	a3,s1
    8000145e:	6605                	lui	a2,0x1
    80001460:	85ca                	mv	a1,s2
    80001462:	8556                	mv	a0,s5
    80001464:	00000097          	auipc	ra,0x0
    80001468:	c3a080e7          	jalr	-966(ra) # 8000109e <mappages>
    8000146c:	e90d                	bnez	a0,8000149e <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000146e:	6785                	lui	a5,0x1
    80001470:	993e                	add	s2,s2,a5
    80001472:	fd4968e3          	bltu	s2,s4,80001442 <uvmalloc+0x32>
  return newsz;
    80001476:	8552                	mv	a0,s4
    80001478:	a809                	j	8000148a <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000147a:	864e                	mv	a2,s3
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	f48080e7          	jalr	-184(ra) # 800013c8 <uvmdealloc>
      return 0;
    80001488:	4501                	li	a0,0
}
    8000148a:	70e2                	ld	ra,56(sp)
    8000148c:	7442                	ld	s0,48(sp)
    8000148e:	74a2                	ld	s1,40(sp)
    80001490:	7902                	ld	s2,32(sp)
    80001492:	69e2                	ld	s3,24(sp)
    80001494:	6a42                	ld	s4,16(sp)
    80001496:	6aa2                	ld	s5,8(sp)
    80001498:	6b02                	ld	s6,0(sp)
    8000149a:	6121                	addi	sp,sp,64
    8000149c:	8082                	ret
      kfree(mem);
    8000149e:	8526                	mv	a0,s1
    800014a0:	fffff097          	auipc	ra,0xfffff
    800014a4:	548080e7          	jalr	1352(ra) # 800009e8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014a8:	864e                	mv	a2,s3
    800014aa:	85ca                	mv	a1,s2
    800014ac:	8556                	mv	a0,s5
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	f1a080e7          	jalr	-230(ra) # 800013c8 <uvmdealloc>
      return 0;
    800014b6:	4501                	li	a0,0
    800014b8:	bfc9                	j	8000148a <uvmalloc+0x7a>
    return oldsz;
    800014ba:	852e                	mv	a0,a1
}
    800014bc:	8082                	ret
  return newsz;
    800014be:	8532                	mv	a0,a2
    800014c0:	b7e9                	j	8000148a <uvmalloc+0x7a>

00000000800014c2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014c2:	7179                	addi	sp,sp,-48
    800014c4:	f406                	sd	ra,40(sp)
    800014c6:	f022                	sd	s0,32(sp)
    800014c8:	ec26                	sd	s1,24(sp)
    800014ca:	e84a                	sd	s2,16(sp)
    800014cc:	e44e                	sd	s3,8(sp)
    800014ce:	e052                	sd	s4,0(sp)
    800014d0:	1800                	addi	s0,sp,48
    800014d2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014d4:	84aa                	mv	s1,a0
    800014d6:	6905                	lui	s2,0x1
    800014d8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014da:	4985                	li	s3,1
    800014dc:	a829                	j	800014f6 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014de:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014e0:	00c79513          	slli	a0,a5,0xc
    800014e4:	00000097          	auipc	ra,0x0
    800014e8:	fde080e7          	jalr	-34(ra) # 800014c2 <freewalk>
      pagetable[i] = 0;
    800014ec:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f0:	04a1                	addi	s1,s1,8
    800014f2:	03248163          	beq	s1,s2,80001514 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800014f6:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f8:	00f7f713          	andi	a4,a5,15
    800014fc:	ff3701e3          	beq	a4,s3,800014de <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001500:	8b85                	andi	a5,a5,1
    80001502:	d7fd                	beqz	a5,800014f0 <freewalk+0x2e>
      panic("freewalk: leaf");
    80001504:	00007517          	auipc	a0,0x7
    80001508:	c7450513          	addi	a0,a0,-908 # 80008178 <digits+0x138>
    8000150c:	fffff097          	auipc	ra,0xfffff
    80001510:	034080e7          	jalr	52(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    80001514:	8552                	mv	a0,s4
    80001516:	fffff097          	auipc	ra,0xfffff
    8000151a:	4d2080e7          	jalr	1234(ra) # 800009e8 <kfree>
}
    8000151e:	70a2                	ld	ra,40(sp)
    80001520:	7402                	ld	s0,32(sp)
    80001522:	64e2                	ld	s1,24(sp)
    80001524:	6942                	ld	s2,16(sp)
    80001526:	69a2                	ld	s3,8(sp)
    80001528:	6a02                	ld	s4,0(sp)
    8000152a:	6145                	addi	sp,sp,48
    8000152c:	8082                	ret

000000008000152e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000152e:	1101                	addi	sp,sp,-32
    80001530:	ec06                	sd	ra,24(sp)
    80001532:	e822                	sd	s0,16(sp)
    80001534:	e426                	sd	s1,8(sp)
    80001536:	1000                	addi	s0,sp,32
    80001538:	84aa                	mv	s1,a0
  if(sz > 0)
    8000153a:	e999                	bnez	a1,80001550 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000153c:	8526                	mv	a0,s1
    8000153e:	00000097          	auipc	ra,0x0
    80001542:	f84080e7          	jalr	-124(ra) # 800014c2 <freewalk>
}
    80001546:	60e2                	ld	ra,24(sp)
    80001548:	6442                	ld	s0,16(sp)
    8000154a:	64a2                	ld	s1,8(sp)
    8000154c:	6105                	addi	sp,sp,32
    8000154e:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001550:	6785                	lui	a5,0x1
    80001552:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001554:	95be                	add	a1,a1,a5
    80001556:	4685                	li	a3,1
    80001558:	00c5d613          	srli	a2,a1,0xc
    8000155c:	4581                	li	a1,0
    8000155e:	00000097          	auipc	ra,0x0
    80001562:	d06080e7          	jalr	-762(ra) # 80001264 <uvmunmap>
    80001566:	bfd9                	j	8000153c <uvmfree+0xe>

0000000080001568 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001568:	c679                	beqz	a2,80001636 <uvmcopy+0xce>
{
    8000156a:	715d                	addi	sp,sp,-80
    8000156c:	e486                	sd	ra,72(sp)
    8000156e:	e0a2                	sd	s0,64(sp)
    80001570:	fc26                	sd	s1,56(sp)
    80001572:	f84a                	sd	s2,48(sp)
    80001574:	f44e                	sd	s3,40(sp)
    80001576:	f052                	sd	s4,32(sp)
    80001578:	ec56                	sd	s5,24(sp)
    8000157a:	e85a                	sd	s6,16(sp)
    8000157c:	e45e                	sd	s7,8(sp)
    8000157e:	0880                	addi	s0,sp,80
    80001580:	8b2a                	mv	s6,a0
    80001582:	8aae                	mv	s5,a1
    80001584:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001586:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001588:	4601                	li	a2,0
    8000158a:	85ce                	mv	a1,s3
    8000158c:	855a                	mv	a0,s6
    8000158e:	00000097          	auipc	ra,0x0
    80001592:	a28080e7          	jalr	-1496(ra) # 80000fb6 <walk>
    80001596:	c531                	beqz	a0,800015e2 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001598:	6118                	ld	a4,0(a0)
    8000159a:	00177793          	andi	a5,a4,1
    8000159e:	cbb1                	beqz	a5,800015f2 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a0:	00a75593          	srli	a1,a4,0xa
    800015a4:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015a8:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015ac:	fffff097          	auipc	ra,0xfffff
    800015b0:	53a080e7          	jalr	1338(ra) # 80000ae6 <kalloc>
    800015b4:	892a                	mv	s2,a0
    800015b6:	c939                	beqz	a0,8000160c <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015b8:	6605                	lui	a2,0x1
    800015ba:	85de                	mv	a1,s7
    800015bc:	fffff097          	auipc	ra,0xfffff
    800015c0:	772080e7          	jalr	1906(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015c4:	8726                	mv	a4,s1
    800015c6:	86ca                	mv	a3,s2
    800015c8:	6605                	lui	a2,0x1
    800015ca:	85ce                	mv	a1,s3
    800015cc:	8556                	mv	a0,s5
    800015ce:	00000097          	auipc	ra,0x0
    800015d2:	ad0080e7          	jalr	-1328(ra) # 8000109e <mappages>
    800015d6:	e515                	bnez	a0,80001602 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015d8:	6785                	lui	a5,0x1
    800015da:	99be                	add	s3,s3,a5
    800015dc:	fb49e6e3          	bltu	s3,s4,80001588 <uvmcopy+0x20>
    800015e0:	a081                	j	80001620 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e2:	00007517          	auipc	a0,0x7
    800015e6:	ba650513          	addi	a0,a0,-1114 # 80008188 <digits+0x148>
    800015ea:	fffff097          	auipc	ra,0xfffff
    800015ee:	f56080e7          	jalr	-170(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    800015f2:	00007517          	auipc	a0,0x7
    800015f6:	bb650513          	addi	a0,a0,-1098 # 800081a8 <digits+0x168>
    800015fa:	fffff097          	auipc	ra,0xfffff
    800015fe:	f46080e7          	jalr	-186(ra) # 80000540 <panic>
      kfree(mem);
    80001602:	854a                	mv	a0,s2
    80001604:	fffff097          	auipc	ra,0xfffff
    80001608:	3e4080e7          	jalr	996(ra) # 800009e8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000160c:	4685                	li	a3,1
    8000160e:	00c9d613          	srli	a2,s3,0xc
    80001612:	4581                	li	a1,0
    80001614:	8556                	mv	a0,s5
    80001616:	00000097          	auipc	ra,0x0
    8000161a:	c4e080e7          	jalr	-946(ra) # 80001264 <uvmunmap>
  return -1;
    8000161e:	557d                	li	a0,-1
}
    80001620:	60a6                	ld	ra,72(sp)
    80001622:	6406                	ld	s0,64(sp)
    80001624:	74e2                	ld	s1,56(sp)
    80001626:	7942                	ld	s2,48(sp)
    80001628:	79a2                	ld	s3,40(sp)
    8000162a:	7a02                	ld	s4,32(sp)
    8000162c:	6ae2                	ld	s5,24(sp)
    8000162e:	6b42                	ld	s6,16(sp)
    80001630:	6ba2                	ld	s7,8(sp)
    80001632:	6161                	addi	sp,sp,80
    80001634:	8082                	ret
  return 0;
    80001636:	4501                	li	a0,0
}
    80001638:	8082                	ret

000000008000163a <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000163a:	1141                	addi	sp,sp,-16
    8000163c:	e406                	sd	ra,8(sp)
    8000163e:	e022                	sd	s0,0(sp)
    80001640:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001642:	4601                	li	a2,0
    80001644:	00000097          	auipc	ra,0x0
    80001648:	972080e7          	jalr	-1678(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000164c:	c901                	beqz	a0,8000165c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000164e:	611c                	ld	a5,0(a0)
    80001650:	9bbd                	andi	a5,a5,-17
    80001652:	e11c                	sd	a5,0(a0)
}
    80001654:	60a2                	ld	ra,8(sp)
    80001656:	6402                	ld	s0,0(sp)
    80001658:	0141                	addi	sp,sp,16
    8000165a:	8082                	ret
    panic("uvmclear");
    8000165c:	00007517          	auipc	a0,0x7
    80001660:	b6c50513          	addi	a0,a0,-1172 # 800081c8 <digits+0x188>
    80001664:	fffff097          	auipc	ra,0xfffff
    80001668:	edc080e7          	jalr	-292(ra) # 80000540 <panic>

000000008000166c <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000166c:	c6bd                	beqz	a3,800016da <copyout+0x6e>
{
    8000166e:	715d                	addi	sp,sp,-80
    80001670:	e486                	sd	ra,72(sp)
    80001672:	e0a2                	sd	s0,64(sp)
    80001674:	fc26                	sd	s1,56(sp)
    80001676:	f84a                	sd	s2,48(sp)
    80001678:	f44e                	sd	s3,40(sp)
    8000167a:	f052                	sd	s4,32(sp)
    8000167c:	ec56                	sd	s5,24(sp)
    8000167e:	e85a                	sd	s6,16(sp)
    80001680:	e45e                	sd	s7,8(sp)
    80001682:	e062                	sd	s8,0(sp)
    80001684:	0880                	addi	s0,sp,80
    80001686:	8b2a                	mv	s6,a0
    80001688:	8c2e                	mv	s8,a1
    8000168a:	8a32                	mv	s4,a2
    8000168c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000168e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001690:	6a85                	lui	s5,0x1
    80001692:	a015                	j	800016b6 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001694:	9562                	add	a0,a0,s8
    80001696:	0004861b          	sext.w	a2,s1
    8000169a:	85d2                	mv	a1,s4
    8000169c:	41250533          	sub	a0,a0,s2
    800016a0:	fffff097          	auipc	ra,0xfffff
    800016a4:	68e080e7          	jalr	1678(ra) # 80000d2e <memmove>

    len -= n;
    800016a8:	409989b3          	sub	s3,s3,s1
    src += n;
    800016ac:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016ae:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b2:	02098263          	beqz	s3,800016d6 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016b6:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016ba:	85ca                	mv	a1,s2
    800016bc:	855a                	mv	a0,s6
    800016be:	00000097          	auipc	ra,0x0
    800016c2:	99e080e7          	jalr	-1634(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800016c6:	cd01                	beqz	a0,800016de <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016c8:	418904b3          	sub	s1,s2,s8
    800016cc:	94d6                	add	s1,s1,s5
    800016ce:	fc99f3e3          	bgeu	s3,s1,80001694 <copyout+0x28>
    800016d2:	84ce                	mv	s1,s3
    800016d4:	b7c1                	j	80001694 <copyout+0x28>
  }
  return 0;
    800016d6:	4501                	li	a0,0
    800016d8:	a021                	j	800016e0 <copyout+0x74>
    800016da:	4501                	li	a0,0
}
    800016dc:	8082                	ret
      return -1;
    800016de:	557d                	li	a0,-1
}
    800016e0:	60a6                	ld	ra,72(sp)
    800016e2:	6406                	ld	s0,64(sp)
    800016e4:	74e2                	ld	s1,56(sp)
    800016e6:	7942                	ld	s2,48(sp)
    800016e8:	79a2                	ld	s3,40(sp)
    800016ea:	7a02                	ld	s4,32(sp)
    800016ec:	6ae2                	ld	s5,24(sp)
    800016ee:	6b42                	ld	s6,16(sp)
    800016f0:	6ba2                	ld	s7,8(sp)
    800016f2:	6c02                	ld	s8,0(sp)
    800016f4:	6161                	addi	sp,sp,80
    800016f6:	8082                	ret

00000000800016f8 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016f8:	caa5                	beqz	a3,80001768 <copyin+0x70>
{
    800016fa:	715d                	addi	sp,sp,-80
    800016fc:	e486                	sd	ra,72(sp)
    800016fe:	e0a2                	sd	s0,64(sp)
    80001700:	fc26                	sd	s1,56(sp)
    80001702:	f84a                	sd	s2,48(sp)
    80001704:	f44e                	sd	s3,40(sp)
    80001706:	f052                	sd	s4,32(sp)
    80001708:	ec56                	sd	s5,24(sp)
    8000170a:	e85a                	sd	s6,16(sp)
    8000170c:	e45e                	sd	s7,8(sp)
    8000170e:	e062                	sd	s8,0(sp)
    80001710:	0880                	addi	s0,sp,80
    80001712:	8b2a                	mv	s6,a0
    80001714:	8a2e                	mv	s4,a1
    80001716:	8c32                	mv	s8,a2
    80001718:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000171a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000171c:	6a85                	lui	s5,0x1
    8000171e:	a01d                	j	80001744 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001720:	018505b3          	add	a1,a0,s8
    80001724:	0004861b          	sext.w	a2,s1
    80001728:	412585b3          	sub	a1,a1,s2
    8000172c:	8552                	mv	a0,s4
    8000172e:	fffff097          	auipc	ra,0xfffff
    80001732:	600080e7          	jalr	1536(ra) # 80000d2e <memmove>

    len -= n;
    80001736:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173a:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000173c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001740:	02098263          	beqz	s3,80001764 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001744:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001748:	85ca                	mv	a1,s2
    8000174a:	855a                	mv	a0,s6
    8000174c:	00000097          	auipc	ra,0x0
    80001750:	910080e7          	jalr	-1776(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    80001754:	cd01                	beqz	a0,8000176c <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001756:	418904b3          	sub	s1,s2,s8
    8000175a:	94d6                	add	s1,s1,s5
    8000175c:	fc99f2e3          	bgeu	s3,s1,80001720 <copyin+0x28>
    80001760:	84ce                	mv	s1,s3
    80001762:	bf7d                	j	80001720 <copyin+0x28>
  }
  return 0;
    80001764:	4501                	li	a0,0
    80001766:	a021                	j	8000176e <copyin+0x76>
    80001768:	4501                	li	a0,0
}
    8000176a:	8082                	ret
      return -1;
    8000176c:	557d                	li	a0,-1
}
    8000176e:	60a6                	ld	ra,72(sp)
    80001770:	6406                	ld	s0,64(sp)
    80001772:	74e2                	ld	s1,56(sp)
    80001774:	7942                	ld	s2,48(sp)
    80001776:	79a2                	ld	s3,40(sp)
    80001778:	7a02                	ld	s4,32(sp)
    8000177a:	6ae2                	ld	s5,24(sp)
    8000177c:	6b42                	ld	s6,16(sp)
    8000177e:	6ba2                	ld	s7,8(sp)
    80001780:	6c02                	ld	s8,0(sp)
    80001782:	6161                	addi	sp,sp,80
    80001784:	8082                	ret

0000000080001786 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001786:	c2dd                	beqz	a3,8000182c <copyinstr+0xa6>
{
    80001788:	715d                	addi	sp,sp,-80
    8000178a:	e486                	sd	ra,72(sp)
    8000178c:	e0a2                	sd	s0,64(sp)
    8000178e:	fc26                	sd	s1,56(sp)
    80001790:	f84a                	sd	s2,48(sp)
    80001792:	f44e                	sd	s3,40(sp)
    80001794:	f052                	sd	s4,32(sp)
    80001796:	ec56                	sd	s5,24(sp)
    80001798:	e85a                	sd	s6,16(sp)
    8000179a:	e45e                	sd	s7,8(sp)
    8000179c:	0880                	addi	s0,sp,80
    8000179e:	8a2a                	mv	s4,a0
    800017a0:	8b2e                	mv	s6,a1
    800017a2:	8bb2                	mv	s7,a2
    800017a4:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017a6:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017a8:	6985                	lui	s3,0x1
    800017aa:	a02d                	j	800017d4 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017ac:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b0:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b2:	37fd                	addiw	a5,a5,-1
    800017b4:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017b8:	60a6                	ld	ra,72(sp)
    800017ba:	6406                	ld	s0,64(sp)
    800017bc:	74e2                	ld	s1,56(sp)
    800017be:	7942                	ld	s2,48(sp)
    800017c0:	79a2                	ld	s3,40(sp)
    800017c2:	7a02                	ld	s4,32(sp)
    800017c4:	6ae2                	ld	s5,24(sp)
    800017c6:	6b42                	ld	s6,16(sp)
    800017c8:	6ba2                	ld	s7,8(sp)
    800017ca:	6161                	addi	sp,sp,80
    800017cc:	8082                	ret
    srcva = va0 + PGSIZE;
    800017ce:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d2:	c8a9                	beqz	s1,80001824 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017d4:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017d8:	85ca                	mv	a1,s2
    800017da:	8552                	mv	a0,s4
    800017dc:	00000097          	auipc	ra,0x0
    800017e0:	880080e7          	jalr	-1920(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800017e4:	c131                	beqz	a0,80001828 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800017e6:	417906b3          	sub	a3,s2,s7
    800017ea:	96ce                	add	a3,a3,s3
    800017ec:	00d4f363          	bgeu	s1,a3,800017f2 <copyinstr+0x6c>
    800017f0:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f2:	955e                	add	a0,a0,s7
    800017f4:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017f8:	daf9                	beqz	a3,800017ce <copyinstr+0x48>
    800017fa:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017fc:	41650633          	sub	a2,a0,s6
    80001800:	fff48593          	addi	a1,s1,-1
    80001804:	95da                	add	a1,a1,s6
    while(n > 0){
    80001806:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    80001808:	00f60733          	add	a4,a2,a5
    8000180c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd0e80>
    80001810:	df51                	beqz	a4,800017ac <copyinstr+0x26>
        *dst = *p;
    80001812:	00e78023          	sb	a4,0(a5)
      --max;
    80001816:	40f584b3          	sub	s1,a1,a5
      dst++;
    8000181a:	0785                	addi	a5,a5,1
    while(n > 0){
    8000181c:	fed796e3          	bne	a5,a3,80001808 <copyinstr+0x82>
      dst++;
    80001820:	8b3e                	mv	s6,a5
    80001822:	b775                	j	800017ce <copyinstr+0x48>
    80001824:	4781                	li	a5,0
    80001826:	b771                	j	800017b2 <copyinstr+0x2c>
      return -1;
    80001828:	557d                	li	a0,-1
    8000182a:	b779                	j	800017b8 <copyinstr+0x32>
  int got_null = 0;
    8000182c:	4781                	li	a5,0
  if(got_null){
    8000182e:	37fd                	addiw	a5,a5,-1
    80001830:	0007851b          	sext.w	a0,a5
}
    80001834:	8082                	ret

0000000080001836 <proc_mapstacks>:
// Map it high in memory, followed by an invalid
// guard page.

void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001836:	7139                	addi	sp,sp,-64
    80001838:	fc06                	sd	ra,56(sp)
    8000183a:	f822                	sd	s0,48(sp)
    8000183c:	f426                	sd	s1,40(sp)
    8000183e:	f04a                	sd	s2,32(sp)
    80001840:	ec4e                	sd	s3,24(sp)
    80001842:	e852                	sd	s4,16(sp)
    80001844:	e456                	sd	s5,8(sp)
    80001846:	e05a                	sd	s6,0(sp)
    80001848:	0080                	addi	s0,sp,64
    8000184a:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    8000184c:	00010497          	auipc	s1,0x10
    80001850:	95448493          	addi	s1,s1,-1708 # 800111a0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001854:	8b26                	mv	s6,s1
    80001856:	00006a97          	auipc	s5,0x6
    8000185a:	7aaa8a93          	addi	s5,s5,1962 # 80008000 <etext>
    8000185e:	04000937          	lui	s2,0x4000
    80001862:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001864:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001866:	00015a17          	auipc	s4,0x15
    8000186a:	53aa0a13          	addi	s4,s4,1338 # 80016da0 <tickslock>
    char *pa = kalloc();
    8000186e:	fffff097          	auipc	ra,0xfffff
    80001872:	278080e7          	jalr	632(ra) # 80000ae6 <kalloc>
    80001876:	862a                	mv	a2,a0
    if(pa == 0)
    80001878:	c131                	beqz	a0,800018bc <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    8000187a:	416485b3          	sub	a1,s1,s6
    8000187e:	8591                	srai	a1,a1,0x4
    80001880:	000ab783          	ld	a5,0(s5)
    80001884:	02f585b3          	mul	a1,a1,a5
    80001888:	2585                	addiw	a1,a1,1
    8000188a:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000188e:	4719                	li	a4,6
    80001890:	6685                	lui	a3,0x1
    80001892:	40b905b3          	sub	a1,s2,a1
    80001896:	854e                	mv	a0,s3
    80001898:	00000097          	auipc	ra,0x0
    8000189c:	8a6080e7          	jalr	-1882(ra) # 8000113e <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018a0:	17048493          	addi	s1,s1,368
    800018a4:	fd4495e3          	bne	s1,s4,8000186e <proc_mapstacks+0x38>
  }
}
    800018a8:	70e2                	ld	ra,56(sp)
    800018aa:	7442                	ld	s0,48(sp)
    800018ac:	74a2                	ld	s1,40(sp)
    800018ae:	7902                	ld	s2,32(sp)
    800018b0:	69e2                	ld	s3,24(sp)
    800018b2:	6a42                	ld	s4,16(sp)
    800018b4:	6aa2                	ld	s5,8(sp)
    800018b6:	6b02                	ld	s6,0(sp)
    800018b8:	6121                	addi	sp,sp,64
    800018ba:	8082                	ret
      panic("kalloc");
    800018bc:	00007517          	auipc	a0,0x7
    800018c0:	91c50513          	addi	a0,a0,-1764 # 800081d8 <digits+0x198>
    800018c4:	fffff097          	auipc	ra,0xfffff
    800018c8:	c7c080e7          	jalr	-900(ra) # 80000540 <panic>

00000000800018cc <procinit>:

// initialize the proc table.
void
procinit(void)
{
    800018cc:	7139                	addi	sp,sp,-64
    800018ce:	fc06                	sd	ra,56(sp)
    800018d0:	f822                	sd	s0,48(sp)
    800018d2:	f426                	sd	s1,40(sp)
    800018d4:	f04a                	sd	s2,32(sp)
    800018d6:	ec4e                	sd	s3,24(sp)
    800018d8:	e852                	sd	s4,16(sp)
    800018da:	e456                	sd	s5,8(sp)
    800018dc:	e05a                	sd	s6,0(sp)
    800018de:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018e0:	00007597          	auipc	a1,0x7
    800018e4:	90058593          	addi	a1,a1,-1792 # 800081e0 <digits+0x1a0>
    800018e8:	0000f517          	auipc	a0,0xf
    800018ec:	47850513          	addi	a0,a0,1144 # 80010d60 <pid_lock>
    800018f0:	fffff097          	auipc	ra,0xfffff
    800018f4:	256080e7          	jalr	598(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018f8:	00007597          	auipc	a1,0x7
    800018fc:	8f058593          	addi	a1,a1,-1808 # 800081e8 <digits+0x1a8>
    80001900:	0000f517          	auipc	a0,0xf
    80001904:	47850513          	addi	a0,a0,1144 # 80010d78 <wait_lock>
    80001908:	fffff097          	auipc	ra,0xfffff
    8000190c:	23e080e7          	jalr	574(ra) # 80000b46 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001910:	00010497          	auipc	s1,0x10
    80001914:	89048493          	addi	s1,s1,-1904 # 800111a0 <proc>
      initlock(&p->lock, "proc");
    80001918:	00007b17          	auipc	s6,0x7
    8000191c:	8e0b0b13          	addi	s6,s6,-1824 # 800081f8 <digits+0x1b8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001920:	8aa6                	mv	s5,s1
    80001922:	00006a17          	auipc	s4,0x6
    80001926:	6dea0a13          	addi	s4,s4,1758 # 80008000 <etext>
    8000192a:	04000937          	lui	s2,0x4000
    8000192e:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001930:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001932:	00015997          	auipc	s3,0x15
    80001936:	46e98993          	addi	s3,s3,1134 # 80016da0 <tickslock>
      initlock(&p->lock, "proc");
    8000193a:	85da                	mv	a1,s6
    8000193c:	8526                	mv	a0,s1
    8000193e:	fffff097          	auipc	ra,0xfffff
    80001942:	208080e7          	jalr	520(ra) # 80000b46 <initlock>
      p->state = UNUSED;
    80001946:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    8000194a:	415487b3          	sub	a5,s1,s5
    8000194e:	8791                	srai	a5,a5,0x4
    80001950:	000a3703          	ld	a4,0(s4)
    80001954:	02e787b3          	mul	a5,a5,a4
    80001958:	2785                	addiw	a5,a5,1
    8000195a:	00d7979b          	slliw	a5,a5,0xd
    8000195e:	40f907b3          	sub	a5,s2,a5
    80001962:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001964:	17048493          	addi	s1,s1,368
    80001968:	fd3499e3          	bne	s1,s3,8000193a <procinit+0x6e>
  }
}
    8000196c:	70e2                	ld	ra,56(sp)
    8000196e:	7442                	ld	s0,48(sp)
    80001970:	74a2                	ld	s1,40(sp)
    80001972:	7902                	ld	s2,32(sp)
    80001974:	69e2                	ld	s3,24(sp)
    80001976:	6a42                	ld	s4,16(sp)
    80001978:	6aa2                	ld	s5,8(sp)
    8000197a:	6b02                	ld	s6,0(sp)
    8000197c:	6121                	addi	sp,sp,64
    8000197e:	8082                	ret

0000000080001980 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001980:	1141                	addi	sp,sp,-16
    80001982:	e422                	sd	s0,8(sp)
    80001984:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001986:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001988:	2501                	sext.w	a0,a0
    8000198a:	6422                	ld	s0,8(sp)
    8000198c:	0141                	addi	sp,sp,16
    8000198e:	8082                	ret

0000000080001990 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80001990:	1141                	addi	sp,sp,-16
    80001992:	e422                	sd	s0,8(sp)
    80001994:	0800                	addi	s0,sp,16
    80001996:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001998:	2781                	sext.w	a5,a5
    8000199a:	079e                	slli	a5,a5,0x7
  return c;
}
    8000199c:	0000f517          	auipc	a0,0xf
    800019a0:	3f450513          	addi	a0,a0,1012 # 80010d90 <cpus>
    800019a4:	953e                	add	a0,a0,a5
    800019a6:	6422                	ld	s0,8(sp)
    800019a8:	0141                	addi	sp,sp,16
    800019aa:	8082                	ret

00000000800019ac <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    800019ac:	1101                	addi	sp,sp,-32
    800019ae:	ec06                	sd	ra,24(sp)
    800019b0:	e822                	sd	s0,16(sp)
    800019b2:	e426                	sd	s1,8(sp)
    800019b4:	1000                	addi	s0,sp,32
  push_off();
    800019b6:	fffff097          	auipc	ra,0xfffff
    800019ba:	1d4080e7          	jalr	468(ra) # 80000b8a <push_off>
    800019be:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c0:	2781                	sext.w	a5,a5
    800019c2:	079e                	slli	a5,a5,0x7
    800019c4:	0000f717          	auipc	a4,0xf
    800019c8:	39c70713          	addi	a4,a4,924 # 80010d60 <pid_lock>
    800019cc:	97ba                	add	a5,a5,a4
    800019ce:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	25a080e7          	jalr	602(ra) # 80000c2a <pop_off>
  return p;
}
    800019d8:	8526                	mv	a0,s1
    800019da:	60e2                	ld	ra,24(sp)
    800019dc:	6442                	ld	s0,16(sp)
    800019de:	64a2                	ld	s1,8(sp)
    800019e0:	6105                	addi	sp,sp,32
    800019e2:	8082                	ret

00000000800019e4 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019e4:	1141                	addi	sp,sp,-16
    800019e6:	e406                	sd	ra,8(sp)
    800019e8:	e022                	sd	s0,0(sp)
    800019ea:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019ec:	00000097          	auipc	ra,0x0
    800019f0:	fc0080e7          	jalr	-64(ra) # 800019ac <myproc>
    800019f4:	fffff097          	auipc	ra,0xfffff
    800019f8:	296080e7          	jalr	662(ra) # 80000c8a <release>

  if (first) {
    800019fc:	00007797          	auipc	a5,0x7
    80001a00:	f847a783          	lw	a5,-124(a5) # 80008980 <first.1>
    80001a04:	eb89                	bnez	a5,80001a16 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a06:	00001097          	auipc	ra,0x1
    80001a0a:	c96080e7          	jalr	-874(ra) # 8000269c <usertrapret>
}
    80001a0e:	60a2                	ld	ra,8(sp)
    80001a10:	6402                	ld	s0,0(sp)
    80001a12:	0141                	addi	sp,sp,16
    80001a14:	8082                	ret
    first = 0;
    80001a16:	00007797          	auipc	a5,0x7
    80001a1a:	f607a523          	sw	zero,-150(a5) # 80008980 <first.1>
    fsinit(ROOTDEV);
    80001a1e:	4505                	li	a0,1
    80001a20:	00002097          	auipc	ra,0x2
    80001a24:	b10080e7          	jalr	-1264(ra) # 80003530 <fsinit>
    80001a28:	bff9                	j	80001a06 <forkret+0x22>

0000000080001a2a <allocpid>:
{
    80001a2a:	1101                	addi	sp,sp,-32
    80001a2c:	ec06                	sd	ra,24(sp)
    80001a2e:	e822                	sd	s0,16(sp)
    80001a30:	e426                	sd	s1,8(sp)
    80001a32:	e04a                	sd	s2,0(sp)
    80001a34:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a36:	0000f917          	auipc	s2,0xf
    80001a3a:	32a90913          	addi	s2,s2,810 # 80010d60 <pid_lock>
    80001a3e:	854a                	mv	a0,s2
    80001a40:	fffff097          	auipc	ra,0xfffff
    80001a44:	196080e7          	jalr	406(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a48:	00007797          	auipc	a5,0x7
    80001a4c:	f3c78793          	addi	a5,a5,-196 # 80008984 <nextpid>
    80001a50:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a52:	0014871b          	addiw	a4,s1,1
    80001a56:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a58:	854a                	mv	a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	230080e7          	jalr	560(ra) # 80000c8a <release>
}
    80001a62:	8526                	mv	a0,s1
    80001a64:	60e2                	ld	ra,24(sp)
    80001a66:	6442                	ld	s0,16(sp)
    80001a68:	64a2                	ld	s1,8(sp)
    80001a6a:	6902                	ld	s2,0(sp)
    80001a6c:	6105                	addi	sp,sp,32
    80001a6e:	8082                	ret

0000000080001a70 <proc_pagetable>:
{
    80001a70:	1101                	addi	sp,sp,-32
    80001a72:	ec06                	sd	ra,24(sp)
    80001a74:	e822                	sd	s0,16(sp)
    80001a76:	e426                	sd	s1,8(sp)
    80001a78:	e04a                	sd	s2,0(sp)
    80001a7a:	1000                	addi	s0,sp,32
    80001a7c:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a7e:	00000097          	auipc	ra,0x0
    80001a82:	8aa080e7          	jalr	-1878(ra) # 80001328 <uvmcreate>
    80001a86:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a88:	c121                	beqz	a0,80001ac8 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a8a:	4729                	li	a4,10
    80001a8c:	00005697          	auipc	a3,0x5
    80001a90:	57468693          	addi	a3,a3,1396 # 80007000 <_trampoline>
    80001a94:	6605                	lui	a2,0x1
    80001a96:	040005b7          	lui	a1,0x4000
    80001a9a:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a9c:	05b2                	slli	a1,a1,0xc
    80001a9e:	fffff097          	auipc	ra,0xfffff
    80001aa2:	600080e7          	jalr	1536(ra) # 8000109e <mappages>
    80001aa6:	02054863          	bltz	a0,80001ad6 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aaa:	4719                	li	a4,6
    80001aac:	05893683          	ld	a3,88(s2)
    80001ab0:	6605                	lui	a2,0x1
    80001ab2:	020005b7          	lui	a1,0x2000
    80001ab6:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001ab8:	05b6                	slli	a1,a1,0xd
    80001aba:	8526                	mv	a0,s1
    80001abc:	fffff097          	auipc	ra,0xfffff
    80001ac0:	5e2080e7          	jalr	1506(ra) # 8000109e <mappages>
    80001ac4:	02054163          	bltz	a0,80001ae6 <proc_pagetable+0x76>
}
    80001ac8:	8526                	mv	a0,s1
    80001aca:	60e2                	ld	ra,24(sp)
    80001acc:	6442                	ld	s0,16(sp)
    80001ace:	64a2                	ld	s1,8(sp)
    80001ad0:	6902                	ld	s2,0(sp)
    80001ad2:	6105                	addi	sp,sp,32
    80001ad4:	8082                	ret
    uvmfree(pagetable, 0);
    80001ad6:	4581                	li	a1,0
    80001ad8:	8526                	mv	a0,s1
    80001ada:	00000097          	auipc	ra,0x0
    80001ade:	a54080e7          	jalr	-1452(ra) # 8000152e <uvmfree>
    return 0;
    80001ae2:	4481                	li	s1,0
    80001ae4:	b7d5                	j	80001ac8 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ae6:	4681                	li	a3,0
    80001ae8:	4605                	li	a2,1
    80001aea:	040005b7          	lui	a1,0x4000
    80001aee:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001af0:	05b2                	slli	a1,a1,0xc
    80001af2:	8526                	mv	a0,s1
    80001af4:	fffff097          	auipc	ra,0xfffff
    80001af8:	770080e7          	jalr	1904(ra) # 80001264 <uvmunmap>
    uvmfree(pagetable, 0);
    80001afc:	4581                	li	a1,0
    80001afe:	8526                	mv	a0,s1
    80001b00:	00000097          	auipc	ra,0x0
    80001b04:	a2e080e7          	jalr	-1490(ra) # 8000152e <uvmfree>
    return 0;
    80001b08:	4481                	li	s1,0
    80001b0a:	bf7d                	j	80001ac8 <proc_pagetable+0x58>

0000000080001b0c <proc_freepagetable>:
{
    80001b0c:	1101                	addi	sp,sp,-32
    80001b0e:	ec06                	sd	ra,24(sp)
    80001b10:	e822                	sd	s0,16(sp)
    80001b12:	e426                	sd	s1,8(sp)
    80001b14:	e04a                	sd	s2,0(sp)
    80001b16:	1000                	addi	s0,sp,32
    80001b18:	84aa                	mv	s1,a0
    80001b1a:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b1c:	4681                	li	a3,0
    80001b1e:	4605                	li	a2,1
    80001b20:	040005b7          	lui	a1,0x4000
    80001b24:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b26:	05b2                	slli	a1,a1,0xc
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	73c080e7          	jalr	1852(ra) # 80001264 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b30:	4681                	li	a3,0
    80001b32:	4605                	li	a2,1
    80001b34:	020005b7          	lui	a1,0x2000
    80001b38:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b3a:	05b6                	slli	a1,a1,0xd
    80001b3c:	8526                	mv	a0,s1
    80001b3e:	fffff097          	auipc	ra,0xfffff
    80001b42:	726080e7          	jalr	1830(ra) # 80001264 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b46:	85ca                	mv	a1,s2
    80001b48:	8526                	mv	a0,s1
    80001b4a:	00000097          	auipc	ra,0x0
    80001b4e:	9e4080e7          	jalr	-1564(ra) # 8000152e <uvmfree>
}
    80001b52:	60e2                	ld	ra,24(sp)
    80001b54:	6442                	ld	s0,16(sp)
    80001b56:	64a2                	ld	s1,8(sp)
    80001b58:	6902                	ld	s2,0(sp)
    80001b5a:	6105                	addi	sp,sp,32
    80001b5c:	8082                	ret

0000000080001b5e <freeproc>:
{
    80001b5e:	1101                	addi	sp,sp,-32
    80001b60:	ec06                	sd	ra,24(sp)
    80001b62:	e822                	sd	s0,16(sp)
    80001b64:	e426                	sd	s1,8(sp)
    80001b66:	1000                	addi	s0,sp,32
    80001b68:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b6a:	6d28                	ld	a0,88(a0)
    80001b6c:	c509                	beqz	a0,80001b76 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b6e:	fffff097          	auipc	ra,0xfffff
    80001b72:	e7a080e7          	jalr	-390(ra) # 800009e8 <kfree>
  p->trapframe = 0;
    80001b76:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001b7a:	68a8                	ld	a0,80(s1)
    80001b7c:	c511                	beqz	a0,80001b88 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b7e:	64ac                	ld	a1,72(s1)
    80001b80:	00000097          	auipc	ra,0x0
    80001b84:	f8c080e7          	jalr	-116(ra) # 80001b0c <proc_freepagetable>
  p->pagetable = 0;
    80001b88:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b8c:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b90:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b94:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b98:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b9c:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ba0:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ba4:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001ba8:	0004ac23          	sw	zero,24(s1)
}
    80001bac:	60e2                	ld	ra,24(sp)
    80001bae:	6442                	ld	s0,16(sp)
    80001bb0:	64a2                	ld	s1,8(sp)
    80001bb2:	6105                	addi	sp,sp,32
    80001bb4:	8082                	ret

0000000080001bb6 <allocproc>:
{
    80001bb6:	1101                	addi	sp,sp,-32
    80001bb8:	ec06                	sd	ra,24(sp)
    80001bba:	e822                	sd	s0,16(sp)
    80001bbc:	e426                	sd	s1,8(sp)
    80001bbe:	e04a                	sd	s2,0(sp)
    80001bc0:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bc2:	0000f497          	auipc	s1,0xf
    80001bc6:	5de48493          	addi	s1,s1,1502 # 800111a0 <proc>
    80001bca:	00015917          	auipc	s2,0x15
    80001bce:	1d690913          	addi	s2,s2,470 # 80016da0 <tickslock>
    acquire(&p->lock);
    80001bd2:	8526                	mv	a0,s1
    80001bd4:	fffff097          	auipc	ra,0xfffff
    80001bd8:	002080e7          	jalr	2(ra) # 80000bd6 <acquire>
    if(p->state == UNUSED) {
    80001bdc:	4c9c                	lw	a5,24(s1)
    80001bde:	cf81                	beqz	a5,80001bf6 <allocproc+0x40>
      release(&p->lock);
    80001be0:	8526                	mv	a0,s1
    80001be2:	fffff097          	auipc	ra,0xfffff
    80001be6:	0a8080e7          	jalr	168(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bea:	17048493          	addi	s1,s1,368
    80001bee:	ff2492e3          	bne	s1,s2,80001bd2 <allocproc+0x1c>
  return 0;
    80001bf2:	4481                	li	s1,0
    80001bf4:	a889                	j	80001c46 <allocproc+0x90>
  p->pid = allocpid();
    80001bf6:	00000097          	auipc	ra,0x0
    80001bfa:	e34080e7          	jalr	-460(ra) # 80001a2a <allocpid>
    80001bfe:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c00:	4785                	li	a5,1
    80001c02:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c04:	fffff097          	auipc	ra,0xfffff
    80001c08:	ee2080e7          	jalr	-286(ra) # 80000ae6 <kalloc>
    80001c0c:	892a                	mv	s2,a0
    80001c0e:	eca8                	sd	a0,88(s1)
    80001c10:	c131                	beqz	a0,80001c54 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c12:	8526                	mv	a0,s1
    80001c14:	00000097          	auipc	ra,0x0
    80001c18:	e5c080e7          	jalr	-420(ra) # 80001a70 <proc_pagetable>
    80001c1c:	892a                	mv	s2,a0
    80001c1e:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c20:	c531                	beqz	a0,80001c6c <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c22:	07000613          	li	a2,112
    80001c26:	4581                	li	a1,0
    80001c28:	06048513          	addi	a0,s1,96
    80001c2c:	fffff097          	auipc	ra,0xfffff
    80001c30:	0a6080e7          	jalr	166(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c34:	00000797          	auipc	a5,0x0
    80001c38:	db078793          	addi	a5,a5,-592 # 800019e4 <forkret>
    80001c3c:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c3e:	60bc                	ld	a5,64(s1)
    80001c40:	6705                	lui	a4,0x1
    80001c42:	97ba                	add	a5,a5,a4
    80001c44:	f4bc                	sd	a5,104(s1)
}
    80001c46:	8526                	mv	a0,s1
    80001c48:	60e2                	ld	ra,24(sp)
    80001c4a:	6442                	ld	s0,16(sp)
    80001c4c:	64a2                	ld	s1,8(sp)
    80001c4e:	6902                	ld	s2,0(sp)
    80001c50:	6105                	addi	sp,sp,32
    80001c52:	8082                	ret
    freeproc(p);
    80001c54:	8526                	mv	a0,s1
    80001c56:	00000097          	auipc	ra,0x0
    80001c5a:	f08080e7          	jalr	-248(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c5e:	8526                	mv	a0,s1
    80001c60:	fffff097          	auipc	ra,0xfffff
    80001c64:	02a080e7          	jalr	42(ra) # 80000c8a <release>
    return 0;
    80001c68:	84ca                	mv	s1,s2
    80001c6a:	bff1                	j	80001c46 <allocproc+0x90>
    freeproc(p);
    80001c6c:	8526                	mv	a0,s1
    80001c6e:	00000097          	auipc	ra,0x0
    80001c72:	ef0080e7          	jalr	-272(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c76:	8526                	mv	a0,s1
    80001c78:	fffff097          	auipc	ra,0xfffff
    80001c7c:	012080e7          	jalr	18(ra) # 80000c8a <release>
    return 0;
    80001c80:	84ca                	mv	s1,s2
    80001c82:	b7d1                	j	80001c46 <allocproc+0x90>

0000000080001c84 <userinit>:
{
    80001c84:	1101                	addi	sp,sp,-32
    80001c86:	ec06                	sd	ra,24(sp)
    80001c88:	e822                	sd	s0,16(sp)
    80001c8a:	e426                	sd	s1,8(sp)
    80001c8c:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c8e:	00000097          	auipc	ra,0x0
    80001c92:	f28080e7          	jalr	-216(ra) # 80001bb6 <allocproc>
    80001c96:	84aa                	mv	s1,a0
  initproc = p;
    80001c98:	00007797          	auipc	a5,0x7
    80001c9c:	e4a7b823          	sd	a0,-432(a5) # 80008ae8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001ca0:	03400613          	li	a2,52
    80001ca4:	00007597          	auipc	a1,0x7
    80001ca8:	cec58593          	addi	a1,a1,-788 # 80008990 <initcode>
    80001cac:	6928                	ld	a0,80(a0)
    80001cae:	fffff097          	auipc	ra,0xfffff
    80001cb2:	6a8080e7          	jalr	1704(ra) # 80001356 <uvmfirst>
  p->sz = PGSIZE;
    80001cb6:	6785                	lui	a5,0x1
    80001cb8:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cba:	6cb8                	ld	a4,88(s1)
    80001cbc:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cc0:	6cb8                	ld	a4,88(s1)
    80001cc2:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cc4:	4641                	li	a2,16
    80001cc6:	00006597          	auipc	a1,0x6
    80001cca:	53a58593          	addi	a1,a1,1338 # 80008200 <digits+0x1c0>
    80001cce:	15848513          	addi	a0,s1,344
    80001cd2:	fffff097          	auipc	ra,0xfffff
    80001cd6:	14a080e7          	jalr	330(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001cda:	00006517          	auipc	a0,0x6
    80001cde:	53650513          	addi	a0,a0,1334 # 80008210 <digits+0x1d0>
    80001ce2:	00002097          	auipc	ra,0x2
    80001ce6:	278080e7          	jalr	632(ra) # 80003f5a <namei>
    80001cea:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001cee:	478d                	li	a5,3
    80001cf0:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001cf2:	8526                	mv	a0,s1
    80001cf4:	fffff097          	auipc	ra,0xfffff
    80001cf8:	f96080e7          	jalr	-106(ra) # 80000c8a <release>
}
    80001cfc:	60e2                	ld	ra,24(sp)
    80001cfe:	6442                	ld	s0,16(sp)
    80001d00:	64a2                	ld	s1,8(sp)
    80001d02:	6105                	addi	sp,sp,32
    80001d04:	8082                	ret

0000000080001d06 <growproc>:
{
    80001d06:	1101                	addi	sp,sp,-32
    80001d08:	ec06                	sd	ra,24(sp)
    80001d0a:	e822                	sd	s0,16(sp)
    80001d0c:	e426                	sd	s1,8(sp)
    80001d0e:	e04a                	sd	s2,0(sp)
    80001d10:	1000                	addi	s0,sp,32
    80001d12:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d14:	00000097          	auipc	ra,0x0
    80001d18:	c98080e7          	jalr	-872(ra) # 800019ac <myproc>
    80001d1c:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d1e:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001d20:	01204c63          	bgtz	s2,80001d38 <growproc+0x32>
  } else if(n < 0){
    80001d24:	02094663          	bltz	s2,80001d50 <growproc+0x4a>
  p->sz = sz;
    80001d28:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d2a:	4501                	li	a0,0
}
    80001d2c:	60e2                	ld	ra,24(sp)
    80001d2e:	6442                	ld	s0,16(sp)
    80001d30:	64a2                	ld	s1,8(sp)
    80001d32:	6902                	ld	s2,0(sp)
    80001d34:	6105                	addi	sp,sp,32
    80001d36:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001d38:	4691                	li	a3,4
    80001d3a:	00b90633          	add	a2,s2,a1
    80001d3e:	6928                	ld	a0,80(a0)
    80001d40:	fffff097          	auipc	ra,0xfffff
    80001d44:	6d0080e7          	jalr	1744(ra) # 80001410 <uvmalloc>
    80001d48:	85aa                	mv	a1,a0
    80001d4a:	fd79                	bnez	a0,80001d28 <growproc+0x22>
      return -1;
    80001d4c:	557d                	li	a0,-1
    80001d4e:	bff9                	j	80001d2c <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d50:	00b90633          	add	a2,s2,a1
    80001d54:	6928                	ld	a0,80(a0)
    80001d56:	fffff097          	auipc	ra,0xfffff
    80001d5a:	672080e7          	jalr	1650(ra) # 800013c8 <uvmdealloc>
    80001d5e:	85aa                	mv	a1,a0
    80001d60:	b7e1                	j	80001d28 <growproc+0x22>

0000000080001d62 <fork>:
{
    80001d62:	7139                	addi	sp,sp,-64
    80001d64:	fc06                	sd	ra,56(sp)
    80001d66:	f822                	sd	s0,48(sp)
    80001d68:	f426                	sd	s1,40(sp)
    80001d6a:	f04a                	sd	s2,32(sp)
    80001d6c:	ec4e                	sd	s3,24(sp)
    80001d6e:	e852                	sd	s4,16(sp)
    80001d70:	e456                	sd	s5,8(sp)
    80001d72:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d74:	00000097          	auipc	ra,0x0
    80001d78:	c38080e7          	jalr	-968(ra) # 800019ac <myproc>
    80001d7c:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001d7e:	00000097          	auipc	ra,0x0
    80001d82:	e38080e7          	jalr	-456(ra) # 80001bb6 <allocproc>
    80001d86:	10050c63          	beqz	a0,80001e9e <fork+0x13c>
    80001d8a:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001d8c:	048ab603          	ld	a2,72(s5)
    80001d90:	692c                	ld	a1,80(a0)
    80001d92:	050ab503          	ld	a0,80(s5)
    80001d96:	fffff097          	auipc	ra,0xfffff
    80001d9a:	7d2080e7          	jalr	2002(ra) # 80001568 <uvmcopy>
    80001d9e:	04054863          	bltz	a0,80001dee <fork+0x8c>
  np->sz = p->sz;
    80001da2:	048ab783          	ld	a5,72(s5)
    80001da6:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001daa:	058ab683          	ld	a3,88(s5)
    80001dae:	87b6                	mv	a5,a3
    80001db0:	058a3703          	ld	a4,88(s4)
    80001db4:	12068693          	addi	a3,a3,288
    80001db8:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dbc:	6788                	ld	a0,8(a5)
    80001dbe:	6b8c                	ld	a1,16(a5)
    80001dc0:	6f90                	ld	a2,24(a5)
    80001dc2:	01073023          	sd	a6,0(a4)
    80001dc6:	e708                	sd	a0,8(a4)
    80001dc8:	eb0c                	sd	a1,16(a4)
    80001dca:	ef10                	sd	a2,24(a4)
    80001dcc:	02078793          	addi	a5,a5,32
    80001dd0:	02070713          	addi	a4,a4,32
    80001dd4:	fed792e3          	bne	a5,a3,80001db8 <fork+0x56>
  np->trapframe->a0 = 0;
    80001dd8:	058a3783          	ld	a5,88(s4)
    80001ddc:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001de0:	0d0a8493          	addi	s1,s5,208
    80001de4:	0d0a0913          	addi	s2,s4,208
    80001de8:	150a8993          	addi	s3,s5,336
    80001dec:	a00d                	j	80001e0e <fork+0xac>
    freeproc(np);
    80001dee:	8552                	mv	a0,s4
    80001df0:	00000097          	auipc	ra,0x0
    80001df4:	d6e080e7          	jalr	-658(ra) # 80001b5e <freeproc>
    release(&np->lock);
    80001df8:	8552                	mv	a0,s4
    80001dfa:	fffff097          	auipc	ra,0xfffff
    80001dfe:	e90080e7          	jalr	-368(ra) # 80000c8a <release>
    return -1;
    80001e02:	597d                	li	s2,-1
    80001e04:	a059                	j	80001e8a <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001e06:	04a1                	addi	s1,s1,8
    80001e08:	0921                	addi	s2,s2,8
    80001e0a:	01348b63          	beq	s1,s3,80001e20 <fork+0xbe>
    if(p->ofile[i])
    80001e0e:	6088                	ld	a0,0(s1)
    80001e10:	d97d                	beqz	a0,80001e06 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e12:	00002097          	auipc	ra,0x2
    80001e16:	7de080e7          	jalr	2014(ra) # 800045f0 <filedup>
    80001e1a:	00a93023          	sd	a0,0(s2)
    80001e1e:	b7e5                	j	80001e06 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e20:	150ab503          	ld	a0,336(s5)
    80001e24:	00002097          	auipc	ra,0x2
    80001e28:	94c080e7          	jalr	-1716(ra) # 80003770 <idup>
    80001e2c:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e30:	4641                	li	a2,16
    80001e32:	158a8593          	addi	a1,s5,344
    80001e36:	158a0513          	addi	a0,s4,344
    80001e3a:	fffff097          	auipc	ra,0xfffff
    80001e3e:	fe2080e7          	jalr	-30(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001e42:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e46:	8552                	mv	a0,s4
    80001e48:	fffff097          	auipc	ra,0xfffff
    80001e4c:	e42080e7          	jalr	-446(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001e50:	0000f497          	auipc	s1,0xf
    80001e54:	f2848493          	addi	s1,s1,-216 # 80010d78 <wait_lock>
    80001e58:	8526                	mv	a0,s1
    80001e5a:	fffff097          	auipc	ra,0xfffff
    80001e5e:	d7c080e7          	jalr	-644(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001e62:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001e66:	8526                	mv	a0,s1
    80001e68:	fffff097          	auipc	ra,0xfffff
    80001e6c:	e22080e7          	jalr	-478(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001e70:	8552                	mv	a0,s4
    80001e72:	fffff097          	auipc	ra,0xfffff
    80001e76:	d64080e7          	jalr	-668(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001e7a:	478d                	li	a5,3
    80001e7c:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001e80:	8552                	mv	a0,s4
    80001e82:	fffff097          	auipc	ra,0xfffff
    80001e86:	e08080e7          	jalr	-504(ra) # 80000c8a <release>
}
    80001e8a:	854a                	mv	a0,s2
    80001e8c:	70e2                	ld	ra,56(sp)
    80001e8e:	7442                	ld	s0,48(sp)
    80001e90:	74a2                	ld	s1,40(sp)
    80001e92:	7902                	ld	s2,32(sp)
    80001e94:	69e2                	ld	s3,24(sp)
    80001e96:	6a42                	ld	s4,16(sp)
    80001e98:	6aa2                	ld	s5,8(sp)
    80001e9a:	6121                	addi	sp,sp,64
    80001e9c:	8082                	ret
    return -1;
    80001e9e:	597d                	li	s2,-1
    80001ea0:	b7ed                	j	80001e8a <fork+0x128>

0000000080001ea2 <audit>:
{
    80001ea2:	1141                	addi	sp,sp,-16
    80001ea4:	e422                	sd	s0,8(sp)
    80001ea6:	0800                	addi	s0,sp,16
}
    80001ea8:	00a5551b          	srliw	a0,a0,0xa
    80001eac:	6422                	ld	s0,8(sp)
    80001eae:	0141                	addi	sp,sp,16
    80001eb0:	8082                	ret

0000000080001eb2 <scheduler>:
{
    80001eb2:	715d                	addi	sp,sp,-80
    80001eb4:	e486                	sd	ra,72(sp)
    80001eb6:	e0a2                	sd	s0,64(sp)
    80001eb8:	fc26                	sd	s1,56(sp)
    80001eba:	f84a                	sd	s2,48(sp)
    80001ebc:	f44e                	sd	s3,40(sp)
    80001ebe:	f052                	sd	s4,32(sp)
    80001ec0:	ec56                	sd	s5,24(sp)
    80001ec2:	e85a                	sd	s6,16(sp)
    80001ec4:	e45e                	sd	s7,8(sp)
    80001ec6:	e062                	sd	s8,0(sp)
    80001ec8:	0880                	addi	s0,sp,80
    80001eca:	8492                	mv	s1,tp
  int id = r_tp();
    80001ecc:	2481                	sext.w	s1,s1
  init_list_head(&runq);
    80001ece:	0000f517          	auipc	a0,0xf
    80001ed2:	2c250513          	addi	a0,a0,706 # 80011190 <runq>
    80001ed6:	00004097          	auipc	ra,0x4
    80001eda:	462080e7          	jalr	1122(ra) # 80006338 <init_list_head>
  c->proc = 0;
    80001ede:	00749b13          	slli	s6,s1,0x7
    80001ee2:	0000f797          	auipc	a5,0xf
    80001ee6:	e7e78793          	addi	a5,a5,-386 # 80010d60 <pid_lock>
    80001eea:	97da                	add	a5,a5,s6
    80001eec:	0207b823          	sd	zero,48(a5)
        swtch(&c->context, &p->context);
    80001ef0:	0000f797          	auipc	a5,0xf
    80001ef4:	ea878793          	addi	a5,a5,-344 # 80010d98 <cpus+0x8>
    80001ef8:	9b3e                	add	s6,s6,a5
    not_runnable_count = 0;
    80001efa:	4c01                	li	s8,0
        p->state = RUNNING;
    80001efc:	4b91                	li	s7,4
        c->proc = p;
    80001efe:	049e                	slli	s1,s1,0x7
    80001f00:	0000fa97          	auipc	s5,0xf
    80001f04:	e60a8a93          	addi	s5,s5,-416 # 80010d60 <pid_lock>
    80001f08:	9aa6                	add	s5,s5,s1
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f0a:	00015a17          	auipc	s4,0x15
    80001f0e:	e96a0a13          	addi	s4,s4,-362 # 80016da0 <tickslock>
    80001f12:	a0a9                	j	80001f5c <scheduler+0xaa>
        not_runnable_count++;
    80001f14:	2905                	addiw	s2,s2,1
      release(&p->lock);
    80001f16:	8526                	mv	a0,s1
    80001f18:	fffff097          	auipc	ra,0xfffff
    80001f1c:	d72080e7          	jalr	-654(ra) # 80000c8a <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f20:	17048493          	addi	s1,s1,368
    80001f24:	03448863          	beq	s1,s4,80001f54 <scheduler+0xa2>
      acquire(&p->lock);
    80001f28:	8526                	mv	a0,s1
    80001f2a:	fffff097          	auipc	ra,0xfffff
    80001f2e:	cac080e7          	jalr	-852(ra) # 80000bd6 <acquire>
      if(p->state == RUNNABLE) {
    80001f32:	4c9c                	lw	a5,24(s1)
    80001f34:	ff3790e3          	bne	a5,s3,80001f14 <scheduler+0x62>
        p->state = RUNNING;
    80001f38:	0174ac23          	sw	s7,24(s1)
        c->proc = p;
    80001f3c:	029ab823          	sd	s1,48(s5)
        swtch(&c->context, &p->context);
    80001f40:	06048593          	addi	a1,s1,96
    80001f44:	855a                	mv	a0,s6
    80001f46:	00000097          	auipc	ra,0x0
    80001f4a:	6ac080e7          	jalr	1708(ra) # 800025f2 <swtch>
        c->proc = 0;
    80001f4e:	020ab823          	sd	zero,48(s5)
    80001f52:	b7d1                	j	80001f16 <scheduler+0x64>
    if (not_runnable_count == NPROC) {
    80001f54:	04000793          	li	a5,64
    80001f58:	00f90f63          	beq	s2,a5,80001f76 <scheduler+0xc4>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f5c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f60:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f64:	10079073          	csrw	sstatus,a5
    not_runnable_count = 0;
    80001f68:	8962                	mv	s2,s8
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f6a:	0000f497          	auipc	s1,0xf
    80001f6e:	23648493          	addi	s1,s1,566 # 800111a0 <proc>
      if(p->state == RUNNABLE) {
    80001f72:	498d                	li	s3,3
    80001f74:	bf55                	j	80001f28 <scheduler+0x76>
  asm volatile("wfi");
    80001f76:	10500073          	wfi
}
    80001f7a:	b7cd                	j	80001f5c <scheduler+0xaa>

0000000080001f7c <sched>:
{
    80001f7c:	7179                	addi	sp,sp,-48
    80001f7e:	f406                	sd	ra,40(sp)
    80001f80:	f022                	sd	s0,32(sp)
    80001f82:	ec26                	sd	s1,24(sp)
    80001f84:	e84a                	sd	s2,16(sp)
    80001f86:	e44e                	sd	s3,8(sp)
    80001f88:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f8a:	00000097          	auipc	ra,0x0
    80001f8e:	a22080e7          	jalr	-1502(ra) # 800019ac <myproc>
    80001f92:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001f94:	fffff097          	auipc	ra,0xfffff
    80001f98:	bc8080e7          	jalr	-1080(ra) # 80000b5c <holding>
    80001f9c:	c93d                	beqz	a0,80002012 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001f9e:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001fa0:	2781                	sext.w	a5,a5
    80001fa2:	079e                	slli	a5,a5,0x7
    80001fa4:	0000f717          	auipc	a4,0xf
    80001fa8:	dbc70713          	addi	a4,a4,-580 # 80010d60 <pid_lock>
    80001fac:	97ba                	add	a5,a5,a4
    80001fae:	0a87a703          	lw	a4,168(a5)
    80001fb2:	4785                	li	a5,1
    80001fb4:	06f71763          	bne	a4,a5,80002022 <sched+0xa6>
  if(p->state == RUNNING)
    80001fb8:	4c98                	lw	a4,24(s1)
    80001fba:	4791                	li	a5,4
    80001fbc:	06f70b63          	beq	a4,a5,80002032 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fc0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001fc4:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001fc6:	efb5                	bnez	a5,80002042 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fc8:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001fca:	0000f917          	auipc	s2,0xf
    80001fce:	d9690913          	addi	s2,s2,-618 # 80010d60 <pid_lock>
    80001fd2:	2781                	sext.w	a5,a5
    80001fd4:	079e                	slli	a5,a5,0x7
    80001fd6:	97ca                	add	a5,a5,s2
    80001fd8:	0ac7a983          	lw	s3,172(a5)
    80001fdc:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001fde:	2781                	sext.w	a5,a5
    80001fe0:	079e                	slli	a5,a5,0x7
    80001fe2:	0000f597          	auipc	a1,0xf
    80001fe6:	db658593          	addi	a1,a1,-586 # 80010d98 <cpus+0x8>
    80001fea:	95be                	add	a1,a1,a5
    80001fec:	06048513          	addi	a0,s1,96
    80001ff0:	00000097          	auipc	ra,0x0
    80001ff4:	602080e7          	jalr	1538(ra) # 800025f2 <swtch>
    80001ff8:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001ffa:	2781                	sext.w	a5,a5
    80001ffc:	079e                	slli	a5,a5,0x7
    80001ffe:	993e                	add	s2,s2,a5
    80002000:	0b392623          	sw	s3,172(s2)
}
    80002004:	70a2                	ld	ra,40(sp)
    80002006:	7402                	ld	s0,32(sp)
    80002008:	64e2                	ld	s1,24(sp)
    8000200a:	6942                	ld	s2,16(sp)
    8000200c:	69a2                	ld	s3,8(sp)
    8000200e:	6145                	addi	sp,sp,48
    80002010:	8082                	ret
    panic("sched p->lock");
    80002012:	00006517          	auipc	a0,0x6
    80002016:	20650513          	addi	a0,a0,518 # 80008218 <digits+0x1d8>
    8000201a:	ffffe097          	auipc	ra,0xffffe
    8000201e:	526080e7          	jalr	1318(ra) # 80000540 <panic>
    panic("sched locks");
    80002022:	00006517          	auipc	a0,0x6
    80002026:	20650513          	addi	a0,a0,518 # 80008228 <digits+0x1e8>
    8000202a:	ffffe097          	auipc	ra,0xffffe
    8000202e:	516080e7          	jalr	1302(ra) # 80000540 <panic>
    panic("sched running");
    80002032:	00006517          	auipc	a0,0x6
    80002036:	20650513          	addi	a0,a0,518 # 80008238 <digits+0x1f8>
    8000203a:	ffffe097          	auipc	ra,0xffffe
    8000203e:	506080e7          	jalr	1286(ra) # 80000540 <panic>
    panic("sched interruptible");
    80002042:	00006517          	auipc	a0,0x6
    80002046:	20650513          	addi	a0,a0,518 # 80008248 <digits+0x208>
    8000204a:	ffffe097          	auipc	ra,0xffffe
    8000204e:	4f6080e7          	jalr	1270(ra) # 80000540 <panic>

0000000080002052 <yield>:
{
    80002052:	1101                	addi	sp,sp,-32
    80002054:	ec06                	sd	ra,24(sp)
    80002056:	e822                	sd	s0,16(sp)
    80002058:	e426                	sd	s1,8(sp)
    8000205a:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000205c:	00000097          	auipc	ra,0x0
    80002060:	950080e7          	jalr	-1712(ra) # 800019ac <myproc>
    80002064:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002066:	fffff097          	auipc	ra,0xfffff
    8000206a:	b70080e7          	jalr	-1168(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    8000206e:	478d                	li	a5,3
    80002070:	cc9c                	sw	a5,24(s1)
  sched();
    80002072:	00000097          	auipc	ra,0x0
    80002076:	f0a080e7          	jalr	-246(ra) # 80001f7c <sched>
  release(&p->lock);
    8000207a:	8526                	mv	a0,s1
    8000207c:	fffff097          	auipc	ra,0xfffff
    80002080:	c0e080e7          	jalr	-1010(ra) # 80000c8a <release>
}
    80002084:	60e2                	ld	ra,24(sp)
    80002086:	6442                	ld	s0,16(sp)
    80002088:	64a2                	ld	s1,8(sp)
    8000208a:	6105                	addi	sp,sp,32
    8000208c:	8082                	ret

000000008000208e <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    8000208e:	7179                	addi	sp,sp,-48
    80002090:	f406                	sd	ra,40(sp)
    80002092:	f022                	sd	s0,32(sp)
    80002094:	ec26                	sd	s1,24(sp)
    80002096:	e84a                	sd	s2,16(sp)
    80002098:	e44e                	sd	s3,8(sp)
    8000209a:	1800                	addi	s0,sp,48
    8000209c:	89aa                	mv	s3,a0
    8000209e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800020a0:	00000097          	auipc	ra,0x0
    800020a4:	90c080e7          	jalr	-1780(ra) # 800019ac <myproc>
    800020a8:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800020aa:	fffff097          	auipc	ra,0xfffff
    800020ae:	b2c080e7          	jalr	-1236(ra) # 80000bd6 <acquire>
  release(lk);
    800020b2:	854a                	mv	a0,s2
    800020b4:	fffff097          	auipc	ra,0xfffff
    800020b8:	bd6080e7          	jalr	-1066(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    800020bc:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020c0:	4789                	li	a5,2
    800020c2:	cc9c                	sw	a5,24(s1)

  sched();
    800020c4:	00000097          	auipc	ra,0x0
    800020c8:	eb8080e7          	jalr	-328(ra) # 80001f7c <sched>

  // Tidy up.
  p->chan = 0;
    800020cc:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020d0:	8526                	mv	a0,s1
    800020d2:	fffff097          	auipc	ra,0xfffff
    800020d6:	bb8080e7          	jalr	-1096(ra) # 80000c8a <release>
  acquire(lk);
    800020da:	854a                	mv	a0,s2
    800020dc:	fffff097          	auipc	ra,0xfffff
    800020e0:	afa080e7          	jalr	-1286(ra) # 80000bd6 <acquire>
}
    800020e4:	70a2                	ld	ra,40(sp)
    800020e6:	7402                	ld	s0,32(sp)
    800020e8:	64e2                	ld	s1,24(sp)
    800020ea:	6942                	ld	s2,16(sp)
    800020ec:	69a2                	ld	s3,8(sp)
    800020ee:	6145                	addi	sp,sp,48
    800020f0:	8082                	ret

00000000800020f2 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800020f2:	7139                	addi	sp,sp,-64
    800020f4:	fc06                	sd	ra,56(sp)
    800020f6:	f822                	sd	s0,48(sp)
    800020f8:	f426                	sd	s1,40(sp)
    800020fa:	f04a                	sd	s2,32(sp)
    800020fc:	ec4e                	sd	s3,24(sp)
    800020fe:	e852                	sd	s4,16(sp)
    80002100:	e456                	sd	s5,8(sp)
    80002102:	0080                	addi	s0,sp,64
    80002104:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002106:	0000f497          	auipc	s1,0xf
    8000210a:	09a48493          	addi	s1,s1,154 # 800111a0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000210e:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002110:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002112:	00015917          	auipc	s2,0x15
    80002116:	c8e90913          	addi	s2,s2,-882 # 80016da0 <tickslock>
    8000211a:	a811                	j	8000212e <wakeup+0x3c>
      }
      release(&p->lock);
    8000211c:	8526                	mv	a0,s1
    8000211e:	fffff097          	auipc	ra,0xfffff
    80002122:	b6c080e7          	jalr	-1172(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002126:	17048493          	addi	s1,s1,368
    8000212a:	03248663          	beq	s1,s2,80002156 <wakeup+0x64>
    if(p != myproc()){
    8000212e:	00000097          	auipc	ra,0x0
    80002132:	87e080e7          	jalr	-1922(ra) # 800019ac <myproc>
    80002136:	fea488e3          	beq	s1,a0,80002126 <wakeup+0x34>
      acquire(&p->lock);
    8000213a:	8526                	mv	a0,s1
    8000213c:	fffff097          	auipc	ra,0xfffff
    80002140:	a9a080e7          	jalr	-1382(ra) # 80000bd6 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002144:	4c9c                	lw	a5,24(s1)
    80002146:	fd379be3          	bne	a5,s3,8000211c <wakeup+0x2a>
    8000214a:	709c                	ld	a5,32(s1)
    8000214c:	fd4798e3          	bne	a5,s4,8000211c <wakeup+0x2a>
        p->state = RUNNABLE;
    80002150:	0154ac23          	sw	s5,24(s1)
    80002154:	b7e1                	j	8000211c <wakeup+0x2a>
    }
  }
}
    80002156:	70e2                	ld	ra,56(sp)
    80002158:	7442                	ld	s0,48(sp)
    8000215a:	74a2                	ld	s1,40(sp)
    8000215c:	7902                	ld	s2,32(sp)
    8000215e:	69e2                	ld	s3,24(sp)
    80002160:	6a42                	ld	s4,16(sp)
    80002162:	6aa2                	ld	s5,8(sp)
    80002164:	6121                	addi	sp,sp,64
    80002166:	8082                	ret

0000000080002168 <reparent>:
{
    80002168:	7179                	addi	sp,sp,-48
    8000216a:	f406                	sd	ra,40(sp)
    8000216c:	f022                	sd	s0,32(sp)
    8000216e:	ec26                	sd	s1,24(sp)
    80002170:	e84a                	sd	s2,16(sp)
    80002172:	e44e                	sd	s3,8(sp)
    80002174:	e052                	sd	s4,0(sp)
    80002176:	1800                	addi	s0,sp,48
    80002178:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000217a:	0000f497          	auipc	s1,0xf
    8000217e:	02648493          	addi	s1,s1,38 # 800111a0 <proc>
      pp->parent = initproc;
    80002182:	00007a17          	auipc	s4,0x7
    80002186:	966a0a13          	addi	s4,s4,-1690 # 80008ae8 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000218a:	00015997          	auipc	s3,0x15
    8000218e:	c1698993          	addi	s3,s3,-1002 # 80016da0 <tickslock>
    80002192:	a029                	j	8000219c <reparent+0x34>
    80002194:	17048493          	addi	s1,s1,368
    80002198:	01348d63          	beq	s1,s3,800021b2 <reparent+0x4a>
    if(pp->parent == p){
    8000219c:	7c9c                	ld	a5,56(s1)
    8000219e:	ff279be3          	bne	a5,s2,80002194 <reparent+0x2c>
      pp->parent = initproc;
    800021a2:	000a3503          	ld	a0,0(s4)
    800021a6:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800021a8:	00000097          	auipc	ra,0x0
    800021ac:	f4a080e7          	jalr	-182(ra) # 800020f2 <wakeup>
    800021b0:	b7d5                	j	80002194 <reparent+0x2c>
}
    800021b2:	70a2                	ld	ra,40(sp)
    800021b4:	7402                	ld	s0,32(sp)
    800021b6:	64e2                	ld	s1,24(sp)
    800021b8:	6942                	ld	s2,16(sp)
    800021ba:	69a2                	ld	s3,8(sp)
    800021bc:	6a02                	ld	s4,0(sp)
    800021be:	6145                	addi	sp,sp,48
    800021c0:	8082                	ret

00000000800021c2 <exit>:
{
    800021c2:	7179                	addi	sp,sp,-48
    800021c4:	f406                	sd	ra,40(sp)
    800021c6:	f022                	sd	s0,32(sp)
    800021c8:	ec26                	sd	s1,24(sp)
    800021ca:	e84a                	sd	s2,16(sp)
    800021cc:	e44e                	sd	s3,8(sp)
    800021ce:	e052                	sd	s4,0(sp)
    800021d0:	1800                	addi	s0,sp,48
    800021d2:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800021d4:	fffff097          	auipc	ra,0xfffff
    800021d8:	7d8080e7          	jalr	2008(ra) # 800019ac <myproc>
    800021dc:	89aa                	mv	s3,a0
  if(p == initproc)
    800021de:	00007797          	auipc	a5,0x7
    800021e2:	90a7b783          	ld	a5,-1782(a5) # 80008ae8 <initproc>
    800021e6:	0d050493          	addi	s1,a0,208
    800021ea:	15050913          	addi	s2,a0,336
    800021ee:	02a79363          	bne	a5,a0,80002214 <exit+0x52>
    panic("init exiting");
    800021f2:	00006517          	auipc	a0,0x6
    800021f6:	06e50513          	addi	a0,a0,110 # 80008260 <digits+0x220>
    800021fa:	ffffe097          	auipc	ra,0xffffe
    800021fe:	346080e7          	jalr	838(ra) # 80000540 <panic>
      fileclose(f);
    80002202:	00002097          	auipc	ra,0x2
    80002206:	440080e7          	jalr	1088(ra) # 80004642 <fileclose>
      p->ofile[fd] = 0;
    8000220a:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000220e:	04a1                	addi	s1,s1,8
    80002210:	01248563          	beq	s1,s2,8000221a <exit+0x58>
    if(p->ofile[fd]){
    80002214:	6088                	ld	a0,0(s1)
    80002216:	f575                	bnez	a0,80002202 <exit+0x40>
    80002218:	bfdd                	j	8000220e <exit+0x4c>
  begin_op();
    8000221a:	00002097          	auipc	ra,0x2
    8000221e:	f60080e7          	jalr	-160(ra) # 8000417a <begin_op>
  iput(p->cwd);
    80002222:	1509b503          	ld	a0,336(s3)
    80002226:	00001097          	auipc	ra,0x1
    8000222a:	742080e7          	jalr	1858(ra) # 80003968 <iput>
  end_op();
    8000222e:	00002097          	auipc	ra,0x2
    80002232:	fca080e7          	jalr	-54(ra) # 800041f8 <end_op>
  p->cwd = 0;
    80002236:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000223a:	0000f497          	auipc	s1,0xf
    8000223e:	b3e48493          	addi	s1,s1,-1218 # 80010d78 <wait_lock>
    80002242:	8526                	mv	a0,s1
    80002244:	fffff097          	auipc	ra,0xfffff
    80002248:	992080e7          	jalr	-1646(ra) # 80000bd6 <acquire>
  reparent(p);
    8000224c:	854e                	mv	a0,s3
    8000224e:	00000097          	auipc	ra,0x0
    80002252:	f1a080e7          	jalr	-230(ra) # 80002168 <reparent>
  wakeup(p->parent);
    80002256:	0389b503          	ld	a0,56(s3)
    8000225a:	00000097          	auipc	ra,0x0
    8000225e:	e98080e7          	jalr	-360(ra) # 800020f2 <wakeup>
  acquire(&p->lock);
    80002262:	854e                	mv	a0,s3
    80002264:	fffff097          	auipc	ra,0xfffff
    80002268:	972080e7          	jalr	-1678(ra) # 80000bd6 <acquire>
  p->xstate = status;
    8000226c:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002270:	4795                	li	a5,5
    80002272:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002276:	8526                	mv	a0,s1
    80002278:	fffff097          	auipc	ra,0xfffff
    8000227c:	a12080e7          	jalr	-1518(ra) # 80000c8a <release>
  sched();
    80002280:	00000097          	auipc	ra,0x0
    80002284:	cfc080e7          	jalr	-772(ra) # 80001f7c <sched>
  panic("zombie exit");
    80002288:	00006517          	auipc	a0,0x6
    8000228c:	fe850513          	addi	a0,a0,-24 # 80008270 <digits+0x230>
    80002290:	ffffe097          	auipc	ra,0xffffe
    80002294:	2b0080e7          	jalr	688(ra) # 80000540 <panic>

0000000080002298 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002298:	7179                	addi	sp,sp,-48
    8000229a:	f406                	sd	ra,40(sp)
    8000229c:	f022                	sd	s0,32(sp)
    8000229e:	ec26                	sd	s1,24(sp)
    800022a0:	e84a                	sd	s2,16(sp)
    800022a2:	e44e                	sd	s3,8(sp)
    800022a4:	1800                	addi	s0,sp,48
    800022a6:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800022a8:	0000f497          	auipc	s1,0xf
    800022ac:	ef848493          	addi	s1,s1,-264 # 800111a0 <proc>
    800022b0:	00015997          	auipc	s3,0x15
    800022b4:	af098993          	addi	s3,s3,-1296 # 80016da0 <tickslock>
    acquire(&p->lock);
    800022b8:	8526                	mv	a0,s1
    800022ba:	fffff097          	auipc	ra,0xfffff
    800022be:	91c080e7          	jalr	-1764(ra) # 80000bd6 <acquire>
    if(p->pid == pid){
    800022c2:	589c                	lw	a5,48(s1)
    800022c4:	01278d63          	beq	a5,s2,800022de <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800022c8:	8526                	mv	a0,s1
    800022ca:	fffff097          	auipc	ra,0xfffff
    800022ce:	9c0080e7          	jalr	-1600(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800022d2:	17048493          	addi	s1,s1,368
    800022d6:	ff3491e3          	bne	s1,s3,800022b8 <kill+0x20>
  }
  return -1;
    800022da:	557d                	li	a0,-1
    800022dc:	a829                	j	800022f6 <kill+0x5e>
      p->killed = 1;
    800022de:	4785                	li	a5,1
    800022e0:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800022e2:	4c98                	lw	a4,24(s1)
    800022e4:	4789                	li	a5,2
    800022e6:	00f70f63          	beq	a4,a5,80002304 <kill+0x6c>
      release(&p->lock);
    800022ea:	8526                	mv	a0,s1
    800022ec:	fffff097          	auipc	ra,0xfffff
    800022f0:	99e080e7          	jalr	-1634(ra) # 80000c8a <release>
      return 0;
    800022f4:	4501                	li	a0,0
}
    800022f6:	70a2                	ld	ra,40(sp)
    800022f8:	7402                	ld	s0,32(sp)
    800022fa:	64e2                	ld	s1,24(sp)
    800022fc:	6942                	ld	s2,16(sp)
    800022fe:	69a2                	ld	s3,8(sp)
    80002300:	6145                	addi	sp,sp,48
    80002302:	8082                	ret
        p->state = RUNNABLE;
    80002304:	478d                	li	a5,3
    80002306:	cc9c                	sw	a5,24(s1)
    80002308:	b7cd                	j	800022ea <kill+0x52>

000000008000230a <setkilled>:

void
setkilled(struct proc *p)
{
    8000230a:	1101                	addi	sp,sp,-32
    8000230c:	ec06                	sd	ra,24(sp)
    8000230e:	e822                	sd	s0,16(sp)
    80002310:	e426                	sd	s1,8(sp)
    80002312:	1000                	addi	s0,sp,32
    80002314:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002316:	fffff097          	auipc	ra,0xfffff
    8000231a:	8c0080e7          	jalr	-1856(ra) # 80000bd6 <acquire>
  p->killed = 1;
    8000231e:	4785                	li	a5,1
    80002320:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002322:	8526                	mv	a0,s1
    80002324:	fffff097          	auipc	ra,0xfffff
    80002328:	966080e7          	jalr	-1690(ra) # 80000c8a <release>
}
    8000232c:	60e2                	ld	ra,24(sp)
    8000232e:	6442                	ld	s0,16(sp)
    80002330:	64a2                	ld	s1,8(sp)
    80002332:	6105                	addi	sp,sp,32
    80002334:	8082                	ret

0000000080002336 <killed>:

int
killed(struct proc *p)
{
    80002336:	1101                	addi	sp,sp,-32
    80002338:	ec06                	sd	ra,24(sp)
    8000233a:	e822                	sd	s0,16(sp)
    8000233c:	e426                	sd	s1,8(sp)
    8000233e:	e04a                	sd	s2,0(sp)
    80002340:	1000                	addi	s0,sp,32
    80002342:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    80002344:	fffff097          	auipc	ra,0xfffff
    80002348:	892080e7          	jalr	-1902(ra) # 80000bd6 <acquire>
  k = p->killed;
    8000234c:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002350:	8526                	mv	a0,s1
    80002352:	fffff097          	auipc	ra,0xfffff
    80002356:	938080e7          	jalr	-1736(ra) # 80000c8a <release>
  return k;
}
    8000235a:	854a                	mv	a0,s2
    8000235c:	60e2                	ld	ra,24(sp)
    8000235e:	6442                	ld	s0,16(sp)
    80002360:	64a2                	ld	s1,8(sp)
    80002362:	6902                	ld	s2,0(sp)
    80002364:	6105                	addi	sp,sp,32
    80002366:	8082                	ret

0000000080002368 <wait>:
{
    80002368:	715d                	addi	sp,sp,-80
    8000236a:	e486                	sd	ra,72(sp)
    8000236c:	e0a2                	sd	s0,64(sp)
    8000236e:	fc26                	sd	s1,56(sp)
    80002370:	f84a                	sd	s2,48(sp)
    80002372:	f44e                	sd	s3,40(sp)
    80002374:	f052                	sd	s4,32(sp)
    80002376:	ec56                	sd	s5,24(sp)
    80002378:	e85a                	sd	s6,16(sp)
    8000237a:	e45e                	sd	s7,8(sp)
    8000237c:	e062                	sd	s8,0(sp)
    8000237e:	0880                	addi	s0,sp,80
    80002380:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002382:	fffff097          	auipc	ra,0xfffff
    80002386:	62a080e7          	jalr	1578(ra) # 800019ac <myproc>
    8000238a:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000238c:	0000f517          	auipc	a0,0xf
    80002390:	9ec50513          	addi	a0,a0,-1556 # 80010d78 <wait_lock>
    80002394:	fffff097          	auipc	ra,0xfffff
    80002398:	842080e7          	jalr	-1982(ra) # 80000bd6 <acquire>
    havekids = 0;
    8000239c:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    8000239e:	4a15                	li	s4,5
        havekids = 1;
    800023a0:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800023a2:	00015997          	auipc	s3,0x15
    800023a6:	9fe98993          	addi	s3,s3,-1538 # 80016da0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800023aa:	0000fc17          	auipc	s8,0xf
    800023ae:	9cec0c13          	addi	s8,s8,-1586 # 80010d78 <wait_lock>
    havekids = 0;
    800023b2:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800023b4:	0000f497          	auipc	s1,0xf
    800023b8:	dec48493          	addi	s1,s1,-532 # 800111a0 <proc>
    800023bc:	a0bd                	j	8000242a <wait+0xc2>
          pid = pp->pid;
    800023be:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800023c2:	000b0e63          	beqz	s6,800023de <wait+0x76>
    800023c6:	4691                	li	a3,4
    800023c8:	02c48613          	addi	a2,s1,44
    800023cc:	85da                	mv	a1,s6
    800023ce:	05093503          	ld	a0,80(s2)
    800023d2:	fffff097          	auipc	ra,0xfffff
    800023d6:	29a080e7          	jalr	666(ra) # 8000166c <copyout>
    800023da:	02054563          	bltz	a0,80002404 <wait+0x9c>
          freeproc(pp);
    800023de:	8526                	mv	a0,s1
    800023e0:	fffff097          	auipc	ra,0xfffff
    800023e4:	77e080e7          	jalr	1918(ra) # 80001b5e <freeproc>
          release(&pp->lock);
    800023e8:	8526                	mv	a0,s1
    800023ea:	fffff097          	auipc	ra,0xfffff
    800023ee:	8a0080e7          	jalr	-1888(ra) # 80000c8a <release>
          release(&wait_lock);
    800023f2:	0000f517          	auipc	a0,0xf
    800023f6:	98650513          	addi	a0,a0,-1658 # 80010d78 <wait_lock>
    800023fa:	fffff097          	auipc	ra,0xfffff
    800023fe:	890080e7          	jalr	-1904(ra) # 80000c8a <release>
          return pid;
    80002402:	a0b5                	j	8000246e <wait+0x106>
            release(&pp->lock);
    80002404:	8526                	mv	a0,s1
    80002406:	fffff097          	auipc	ra,0xfffff
    8000240a:	884080e7          	jalr	-1916(ra) # 80000c8a <release>
            release(&wait_lock);
    8000240e:	0000f517          	auipc	a0,0xf
    80002412:	96a50513          	addi	a0,a0,-1686 # 80010d78 <wait_lock>
    80002416:	fffff097          	auipc	ra,0xfffff
    8000241a:	874080e7          	jalr	-1932(ra) # 80000c8a <release>
            return -1;
    8000241e:	59fd                	li	s3,-1
    80002420:	a0b9                	j	8000246e <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002422:	17048493          	addi	s1,s1,368
    80002426:	03348463          	beq	s1,s3,8000244e <wait+0xe6>
      if(pp->parent == p){
    8000242a:	7c9c                	ld	a5,56(s1)
    8000242c:	ff279be3          	bne	a5,s2,80002422 <wait+0xba>
        acquire(&pp->lock);
    80002430:	8526                	mv	a0,s1
    80002432:	ffffe097          	auipc	ra,0xffffe
    80002436:	7a4080e7          	jalr	1956(ra) # 80000bd6 <acquire>
        if(pp->state == ZOMBIE){
    8000243a:	4c9c                	lw	a5,24(s1)
    8000243c:	f94781e3          	beq	a5,s4,800023be <wait+0x56>
        release(&pp->lock);
    80002440:	8526                	mv	a0,s1
    80002442:	fffff097          	auipc	ra,0xfffff
    80002446:	848080e7          	jalr	-1976(ra) # 80000c8a <release>
        havekids = 1;
    8000244a:	8756                	mv	a4,s5
    8000244c:	bfd9                	j	80002422 <wait+0xba>
    if(!havekids || killed(p)){
    8000244e:	c719                	beqz	a4,8000245c <wait+0xf4>
    80002450:	854a                	mv	a0,s2
    80002452:	00000097          	auipc	ra,0x0
    80002456:	ee4080e7          	jalr	-284(ra) # 80002336 <killed>
    8000245a:	c51d                	beqz	a0,80002488 <wait+0x120>
      release(&wait_lock);
    8000245c:	0000f517          	auipc	a0,0xf
    80002460:	91c50513          	addi	a0,a0,-1764 # 80010d78 <wait_lock>
    80002464:	fffff097          	auipc	ra,0xfffff
    80002468:	826080e7          	jalr	-2010(ra) # 80000c8a <release>
      return -1;
    8000246c:	59fd                	li	s3,-1
}
    8000246e:	854e                	mv	a0,s3
    80002470:	60a6                	ld	ra,72(sp)
    80002472:	6406                	ld	s0,64(sp)
    80002474:	74e2                	ld	s1,56(sp)
    80002476:	7942                	ld	s2,48(sp)
    80002478:	79a2                	ld	s3,40(sp)
    8000247a:	7a02                	ld	s4,32(sp)
    8000247c:	6ae2                	ld	s5,24(sp)
    8000247e:	6b42                	ld	s6,16(sp)
    80002480:	6ba2                	ld	s7,8(sp)
    80002482:	6c02                	ld	s8,0(sp)
    80002484:	6161                	addi	sp,sp,80
    80002486:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002488:	85e2                	mv	a1,s8
    8000248a:	854a                	mv	a0,s2
    8000248c:	00000097          	auipc	ra,0x0
    80002490:	c02080e7          	jalr	-1022(ra) # 8000208e <sleep>
    havekids = 0;
    80002494:	bf39                	j	800023b2 <wait+0x4a>

0000000080002496 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002496:	7179                	addi	sp,sp,-48
    80002498:	f406                	sd	ra,40(sp)
    8000249a:	f022                	sd	s0,32(sp)
    8000249c:	ec26                	sd	s1,24(sp)
    8000249e:	e84a                	sd	s2,16(sp)
    800024a0:	e44e                	sd	s3,8(sp)
    800024a2:	e052                	sd	s4,0(sp)
    800024a4:	1800                	addi	s0,sp,48
    800024a6:	84aa                	mv	s1,a0
    800024a8:	892e                	mv	s2,a1
    800024aa:	89b2                	mv	s3,a2
    800024ac:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024ae:	fffff097          	auipc	ra,0xfffff
    800024b2:	4fe080e7          	jalr	1278(ra) # 800019ac <myproc>
  if(user_dst){
    800024b6:	c08d                	beqz	s1,800024d8 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800024b8:	86d2                	mv	a3,s4
    800024ba:	864e                	mv	a2,s3
    800024bc:	85ca                	mv	a1,s2
    800024be:	6928                	ld	a0,80(a0)
    800024c0:	fffff097          	auipc	ra,0xfffff
    800024c4:	1ac080e7          	jalr	428(ra) # 8000166c <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024c8:	70a2                	ld	ra,40(sp)
    800024ca:	7402                	ld	s0,32(sp)
    800024cc:	64e2                	ld	s1,24(sp)
    800024ce:	6942                	ld	s2,16(sp)
    800024d0:	69a2                	ld	s3,8(sp)
    800024d2:	6a02                	ld	s4,0(sp)
    800024d4:	6145                	addi	sp,sp,48
    800024d6:	8082                	ret
    memmove((char *)dst, src, len);
    800024d8:	000a061b          	sext.w	a2,s4
    800024dc:	85ce                	mv	a1,s3
    800024de:	854a                	mv	a0,s2
    800024e0:	fffff097          	auipc	ra,0xfffff
    800024e4:	84e080e7          	jalr	-1970(ra) # 80000d2e <memmove>
    return 0;
    800024e8:	8526                	mv	a0,s1
    800024ea:	bff9                	j	800024c8 <either_copyout+0x32>

00000000800024ec <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024ec:	7179                	addi	sp,sp,-48
    800024ee:	f406                	sd	ra,40(sp)
    800024f0:	f022                	sd	s0,32(sp)
    800024f2:	ec26                	sd	s1,24(sp)
    800024f4:	e84a                	sd	s2,16(sp)
    800024f6:	e44e                	sd	s3,8(sp)
    800024f8:	e052                	sd	s4,0(sp)
    800024fa:	1800                	addi	s0,sp,48
    800024fc:	892a                	mv	s2,a0
    800024fe:	84ae                	mv	s1,a1
    80002500:	89b2                	mv	s3,a2
    80002502:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002504:	fffff097          	auipc	ra,0xfffff
    80002508:	4a8080e7          	jalr	1192(ra) # 800019ac <myproc>
  if(user_src){
    8000250c:	c08d                	beqz	s1,8000252e <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000250e:	86d2                	mv	a3,s4
    80002510:	864e                	mv	a2,s3
    80002512:	85ca                	mv	a1,s2
    80002514:	6928                	ld	a0,80(a0)
    80002516:	fffff097          	auipc	ra,0xfffff
    8000251a:	1e2080e7          	jalr	482(ra) # 800016f8 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000251e:	70a2                	ld	ra,40(sp)
    80002520:	7402                	ld	s0,32(sp)
    80002522:	64e2                	ld	s1,24(sp)
    80002524:	6942                	ld	s2,16(sp)
    80002526:	69a2                	ld	s3,8(sp)
    80002528:	6a02                	ld	s4,0(sp)
    8000252a:	6145                	addi	sp,sp,48
    8000252c:	8082                	ret
    memmove(dst, (char*)src, len);
    8000252e:	000a061b          	sext.w	a2,s4
    80002532:	85ce                	mv	a1,s3
    80002534:	854a                	mv	a0,s2
    80002536:	ffffe097          	auipc	ra,0xffffe
    8000253a:	7f8080e7          	jalr	2040(ra) # 80000d2e <memmove>
    return 0;
    8000253e:	8526                	mv	a0,s1
    80002540:	bff9                	j	8000251e <either_copyin+0x32>

0000000080002542 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002542:	715d                	addi	sp,sp,-80
    80002544:	e486                	sd	ra,72(sp)
    80002546:	e0a2                	sd	s0,64(sp)
    80002548:	fc26                	sd	s1,56(sp)
    8000254a:	f84a                	sd	s2,48(sp)
    8000254c:	f44e                	sd	s3,40(sp)
    8000254e:	f052                	sd	s4,32(sp)
    80002550:	ec56                	sd	s5,24(sp)
    80002552:	e85a                	sd	s6,16(sp)
    80002554:	e45e                	sd	s7,8(sp)
    80002556:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002558:	00006517          	auipc	a0,0x6
    8000255c:	b7050513          	addi	a0,a0,-1168 # 800080c8 <digits+0x88>
    80002560:	ffffe097          	auipc	ra,0xffffe
    80002564:	02a080e7          	jalr	42(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002568:	0000f497          	auipc	s1,0xf
    8000256c:	d9048493          	addi	s1,s1,-624 # 800112f8 <proc+0x158>
    80002570:	00015917          	auipc	s2,0x15
    80002574:	98890913          	addi	s2,s2,-1656 # 80016ef8 <bruh+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002578:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000257a:	00006997          	auipc	s3,0x6
    8000257e:	d0698993          	addi	s3,s3,-762 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002582:	00006a97          	auipc	s5,0x6
    80002586:	d06a8a93          	addi	s5,s5,-762 # 80008288 <digits+0x248>
    printf("\n");
    8000258a:	00006a17          	auipc	s4,0x6
    8000258e:	b3ea0a13          	addi	s4,s4,-1218 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002592:	00006b97          	auipc	s7,0x6
    80002596:	d36b8b93          	addi	s7,s7,-714 # 800082c8 <states.0>
    8000259a:	a00d                	j	800025bc <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000259c:	ed86a583          	lw	a1,-296(a3)
    800025a0:	8556                	mv	a0,s5
    800025a2:	ffffe097          	auipc	ra,0xffffe
    800025a6:	fe8080e7          	jalr	-24(ra) # 8000058a <printf>
    printf("\n");
    800025aa:	8552                	mv	a0,s4
    800025ac:	ffffe097          	auipc	ra,0xffffe
    800025b0:	fde080e7          	jalr	-34(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025b4:	17048493          	addi	s1,s1,368
    800025b8:	03248263          	beq	s1,s2,800025dc <procdump+0x9a>
    if(p->state == UNUSED)
    800025bc:	86a6                	mv	a3,s1
    800025be:	ec04a783          	lw	a5,-320(s1)
    800025c2:	dbed                	beqz	a5,800025b4 <procdump+0x72>
      state = "???";
    800025c4:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025c6:	fcfb6be3          	bltu	s6,a5,8000259c <procdump+0x5a>
    800025ca:	02079713          	slli	a4,a5,0x20
    800025ce:	01d75793          	srli	a5,a4,0x1d
    800025d2:	97de                	add	a5,a5,s7
    800025d4:	6390                	ld	a2,0(a5)
    800025d6:	f279                	bnez	a2,8000259c <procdump+0x5a>
      state = "???";
    800025d8:	864e                	mv	a2,s3
    800025da:	b7c9                	j	8000259c <procdump+0x5a>
  }
}
    800025dc:	60a6                	ld	ra,72(sp)
    800025de:	6406                	ld	s0,64(sp)
    800025e0:	74e2                	ld	s1,56(sp)
    800025e2:	7942                	ld	s2,48(sp)
    800025e4:	79a2                	ld	s3,40(sp)
    800025e6:	7a02                	ld	s4,32(sp)
    800025e8:	6ae2                	ld	s5,24(sp)
    800025ea:	6b42                	ld	s6,16(sp)
    800025ec:	6ba2                	ld	s7,8(sp)
    800025ee:	6161                	addi	sp,sp,80
    800025f0:	8082                	ret

00000000800025f2 <swtch>:
    800025f2:	00153023          	sd	ra,0(a0)
    800025f6:	00253423          	sd	sp,8(a0)
    800025fa:	e900                	sd	s0,16(a0)
    800025fc:	ed04                	sd	s1,24(a0)
    800025fe:	03253023          	sd	s2,32(a0)
    80002602:	03353423          	sd	s3,40(a0)
    80002606:	03453823          	sd	s4,48(a0)
    8000260a:	03553c23          	sd	s5,56(a0)
    8000260e:	05653023          	sd	s6,64(a0)
    80002612:	05753423          	sd	s7,72(a0)
    80002616:	05853823          	sd	s8,80(a0)
    8000261a:	05953c23          	sd	s9,88(a0)
    8000261e:	07a53023          	sd	s10,96(a0)
    80002622:	07b53423          	sd	s11,104(a0)
    80002626:	0005b083          	ld	ra,0(a1)
    8000262a:	0085b103          	ld	sp,8(a1)
    8000262e:	6980                	ld	s0,16(a1)
    80002630:	6d84                	ld	s1,24(a1)
    80002632:	0205b903          	ld	s2,32(a1)
    80002636:	0285b983          	ld	s3,40(a1)
    8000263a:	0305ba03          	ld	s4,48(a1)
    8000263e:	0385ba83          	ld	s5,56(a1)
    80002642:	0405bb03          	ld	s6,64(a1)
    80002646:	0485bb83          	ld	s7,72(a1)
    8000264a:	0505bc03          	ld	s8,80(a1)
    8000264e:	0585bc83          	ld	s9,88(a1)
    80002652:	0605bd03          	ld	s10,96(a1)
    80002656:	0685bd83          	ld	s11,104(a1)
    8000265a:	8082                	ret

000000008000265c <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000265c:	1141                	addi	sp,sp,-16
    8000265e:	e406                	sd	ra,8(sp)
    80002660:	e022                	sd	s0,0(sp)
    80002662:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002664:	00006597          	auipc	a1,0x6
    80002668:	c9458593          	addi	a1,a1,-876 # 800082f8 <states.0+0x30>
    8000266c:	00014517          	auipc	a0,0x14
    80002670:	73450513          	addi	a0,a0,1844 # 80016da0 <tickslock>
    80002674:	ffffe097          	auipc	ra,0xffffe
    80002678:	4d2080e7          	jalr	1234(ra) # 80000b46 <initlock>
}
    8000267c:	60a2                	ld	ra,8(sp)
    8000267e:	6402                	ld	s0,0(sp)
    80002680:	0141                	addi	sp,sp,16
    80002682:	8082                	ret

0000000080002684 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002684:	1141                	addi	sp,sp,-16
    80002686:	e422                	sd	s0,8(sp)
    80002688:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000268a:	00003797          	auipc	a5,0x3
    8000268e:	60678793          	addi	a5,a5,1542 # 80005c90 <kernelvec>
    80002692:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002696:	6422                	ld	s0,8(sp)
    80002698:	0141                	addi	sp,sp,16
    8000269a:	8082                	ret

000000008000269c <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000269c:	1141                	addi	sp,sp,-16
    8000269e:	e406                	sd	ra,8(sp)
    800026a0:	e022                	sd	s0,0(sp)
    800026a2:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800026a4:	fffff097          	auipc	ra,0xfffff
    800026a8:	308080e7          	jalr	776(ra) # 800019ac <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026ac:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800026b0:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026b2:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    800026b6:	00005697          	auipc	a3,0x5
    800026ba:	94a68693          	addi	a3,a3,-1718 # 80007000 <_trampoline>
    800026be:	00005717          	auipc	a4,0x5
    800026c2:	94270713          	addi	a4,a4,-1726 # 80007000 <_trampoline>
    800026c6:	8f15                	sub	a4,a4,a3
    800026c8:	040007b7          	lui	a5,0x4000
    800026cc:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    800026ce:	07b2                	slli	a5,a5,0xc
    800026d0:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026d2:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800026d6:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800026d8:	18002673          	csrr	a2,satp
    800026dc:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800026de:	6d30                	ld	a2,88(a0)
    800026e0:	6138                	ld	a4,64(a0)
    800026e2:	6585                	lui	a1,0x1
    800026e4:	972e                	add	a4,a4,a1
    800026e6:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800026e8:	6d38                	ld	a4,88(a0)
    800026ea:	00000617          	auipc	a2,0x0
    800026ee:	13060613          	addi	a2,a2,304 # 8000281a <usertrap>
    800026f2:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800026f4:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800026f6:	8612                	mv	a2,tp
    800026f8:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026fa:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800026fe:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002702:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002706:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000270a:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000270c:	6f18                	ld	a4,24(a4)
    8000270e:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002712:	6928                	ld	a0,80(a0)
    80002714:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002716:	00005717          	auipc	a4,0x5
    8000271a:	98670713          	addi	a4,a4,-1658 # 8000709c <userret>
    8000271e:	8f15                	sub	a4,a4,a3
    80002720:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002722:	577d                	li	a4,-1
    80002724:	177e                	slli	a4,a4,0x3f
    80002726:	8d59                	or	a0,a0,a4
    80002728:	9782                	jalr	a5
}
    8000272a:	60a2                	ld	ra,8(sp)
    8000272c:	6402                	ld	s0,0(sp)
    8000272e:	0141                	addi	sp,sp,16
    80002730:	8082                	ret

0000000080002732 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002732:	1101                	addi	sp,sp,-32
    80002734:	ec06                	sd	ra,24(sp)
    80002736:	e822                	sd	s0,16(sp)
    80002738:	e426                	sd	s1,8(sp)
    8000273a:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    8000273c:	00014497          	auipc	s1,0x14
    80002740:	66448493          	addi	s1,s1,1636 # 80016da0 <tickslock>
    80002744:	8526                	mv	a0,s1
    80002746:	ffffe097          	auipc	ra,0xffffe
    8000274a:	490080e7          	jalr	1168(ra) # 80000bd6 <acquire>
  ticks++;
    8000274e:	00006517          	auipc	a0,0x6
    80002752:	3a250513          	addi	a0,a0,930 # 80008af0 <ticks>
    80002756:	411c                	lw	a5,0(a0)
    80002758:	2785                	addiw	a5,a5,1
    8000275a:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    8000275c:	00000097          	auipc	ra,0x0
    80002760:	996080e7          	jalr	-1642(ra) # 800020f2 <wakeup>
  release(&tickslock);
    80002764:	8526                	mv	a0,s1
    80002766:	ffffe097          	auipc	ra,0xffffe
    8000276a:	524080e7          	jalr	1316(ra) # 80000c8a <release>
}
    8000276e:	60e2                	ld	ra,24(sp)
    80002770:	6442                	ld	s0,16(sp)
    80002772:	64a2                	ld	s1,8(sp)
    80002774:	6105                	addi	sp,sp,32
    80002776:	8082                	ret

0000000080002778 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002778:	1101                	addi	sp,sp,-32
    8000277a:	ec06                	sd	ra,24(sp)
    8000277c:	e822                	sd	s0,16(sp)
    8000277e:	e426                	sd	s1,8(sp)
    80002780:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002782:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002786:	00074d63          	bltz	a4,800027a0 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    8000278a:	57fd                	li	a5,-1
    8000278c:	17fe                	slli	a5,a5,0x3f
    8000278e:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002790:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002792:	06f70363          	beq	a4,a5,800027f8 <devintr+0x80>
  }
}
    80002796:	60e2                	ld	ra,24(sp)
    80002798:	6442                	ld	s0,16(sp)
    8000279a:	64a2                	ld	s1,8(sp)
    8000279c:	6105                	addi	sp,sp,32
    8000279e:	8082                	ret
     (scause & 0xff) == 9){
    800027a0:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    800027a4:	46a5                	li	a3,9
    800027a6:	fed792e3          	bne	a5,a3,8000278a <devintr+0x12>
    int irq = plic_claim();
    800027aa:	00003097          	auipc	ra,0x3
    800027ae:	5ee080e7          	jalr	1518(ra) # 80005d98 <plic_claim>
    800027b2:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800027b4:	47a9                	li	a5,10
    800027b6:	02f50763          	beq	a0,a5,800027e4 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800027ba:	4785                	li	a5,1
    800027bc:	02f50963          	beq	a0,a5,800027ee <devintr+0x76>
    return 1;
    800027c0:	4505                	li	a0,1
    } else if(irq){
    800027c2:	d8f1                	beqz	s1,80002796 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800027c4:	85a6                	mv	a1,s1
    800027c6:	00006517          	auipc	a0,0x6
    800027ca:	b3a50513          	addi	a0,a0,-1222 # 80008300 <states.0+0x38>
    800027ce:	ffffe097          	auipc	ra,0xffffe
    800027d2:	dbc080e7          	jalr	-580(ra) # 8000058a <printf>
      plic_complete(irq);
    800027d6:	8526                	mv	a0,s1
    800027d8:	00003097          	auipc	ra,0x3
    800027dc:	5e4080e7          	jalr	1508(ra) # 80005dbc <plic_complete>
    return 1;
    800027e0:	4505                	li	a0,1
    800027e2:	bf55                	j	80002796 <devintr+0x1e>
      uartintr();
    800027e4:	ffffe097          	auipc	ra,0xffffe
    800027e8:	1b4080e7          	jalr	436(ra) # 80000998 <uartintr>
    800027ec:	b7ed                	j	800027d6 <devintr+0x5e>
      virtio_disk_intr();
    800027ee:	00004097          	auipc	ra,0x4
    800027f2:	a96080e7          	jalr	-1386(ra) # 80006284 <virtio_disk_intr>
    800027f6:	b7c5                	j	800027d6 <devintr+0x5e>
    if(cpuid() == 0){
    800027f8:	fffff097          	auipc	ra,0xfffff
    800027fc:	188080e7          	jalr	392(ra) # 80001980 <cpuid>
    80002800:	c901                	beqz	a0,80002810 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002802:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002806:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002808:	14479073          	csrw	sip,a5
    return 2;
    8000280c:	4509                	li	a0,2
    8000280e:	b761                	j	80002796 <devintr+0x1e>
      clockintr();
    80002810:	00000097          	auipc	ra,0x0
    80002814:	f22080e7          	jalr	-222(ra) # 80002732 <clockintr>
    80002818:	b7ed                	j	80002802 <devintr+0x8a>

000000008000281a <usertrap>:
{
    8000281a:	1101                	addi	sp,sp,-32
    8000281c:	ec06                	sd	ra,24(sp)
    8000281e:	e822                	sd	s0,16(sp)
    80002820:	e426                	sd	s1,8(sp)
    80002822:	e04a                	sd	s2,0(sp)
    80002824:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002826:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000282a:	1007f793          	andi	a5,a5,256
    8000282e:	e3b1                	bnez	a5,80002872 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002830:	00003797          	auipc	a5,0x3
    80002834:	46078793          	addi	a5,a5,1120 # 80005c90 <kernelvec>
    80002838:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    8000283c:	fffff097          	auipc	ra,0xfffff
    80002840:	170080e7          	jalr	368(ra) # 800019ac <myproc>
    80002844:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002846:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002848:	14102773          	csrr	a4,sepc
    8000284c:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000284e:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002852:	47a1                	li	a5,8
    80002854:	02f70763          	beq	a4,a5,80002882 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    80002858:	00000097          	auipc	ra,0x0
    8000285c:	f20080e7          	jalr	-224(ra) # 80002778 <devintr>
    80002860:	892a                	mv	s2,a0
    80002862:	c151                	beqz	a0,800028e6 <usertrap+0xcc>
  if(killed(p))
    80002864:	8526                	mv	a0,s1
    80002866:	00000097          	auipc	ra,0x0
    8000286a:	ad0080e7          	jalr	-1328(ra) # 80002336 <killed>
    8000286e:	c929                	beqz	a0,800028c0 <usertrap+0xa6>
    80002870:	a099                	j	800028b6 <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002872:	00006517          	auipc	a0,0x6
    80002876:	aae50513          	addi	a0,a0,-1362 # 80008320 <states.0+0x58>
    8000287a:	ffffe097          	auipc	ra,0xffffe
    8000287e:	cc6080e7          	jalr	-826(ra) # 80000540 <panic>
    if(killed(p))
    80002882:	00000097          	auipc	ra,0x0
    80002886:	ab4080e7          	jalr	-1356(ra) # 80002336 <killed>
    8000288a:	e921                	bnez	a0,800028da <usertrap+0xc0>
    p->trapframe->epc += 4;
    8000288c:	6cb8                	ld	a4,88(s1)
    8000288e:	6f1c                	ld	a5,24(a4)
    80002890:	0791                	addi	a5,a5,4
    80002892:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002894:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002898:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000289c:	10079073          	csrw	sstatus,a5
    syscall();
    800028a0:	00000097          	auipc	ra,0x0
    800028a4:	2d4080e7          	jalr	724(ra) # 80002b74 <syscall>
  if(killed(p))
    800028a8:	8526                	mv	a0,s1
    800028aa:	00000097          	auipc	ra,0x0
    800028ae:	a8c080e7          	jalr	-1396(ra) # 80002336 <killed>
    800028b2:	c911                	beqz	a0,800028c6 <usertrap+0xac>
    800028b4:	4901                	li	s2,0
    exit(-1);
    800028b6:	557d                	li	a0,-1
    800028b8:	00000097          	auipc	ra,0x0
    800028bc:	90a080e7          	jalr	-1782(ra) # 800021c2 <exit>
  if(which_dev == 2)
    800028c0:	4789                	li	a5,2
    800028c2:	04f90f63          	beq	s2,a5,80002920 <usertrap+0x106>
  usertrapret();
    800028c6:	00000097          	auipc	ra,0x0
    800028ca:	dd6080e7          	jalr	-554(ra) # 8000269c <usertrapret>
}
    800028ce:	60e2                	ld	ra,24(sp)
    800028d0:	6442                	ld	s0,16(sp)
    800028d2:	64a2                	ld	s1,8(sp)
    800028d4:	6902                	ld	s2,0(sp)
    800028d6:	6105                	addi	sp,sp,32
    800028d8:	8082                	ret
      exit(-1);
    800028da:	557d                	li	a0,-1
    800028dc:	00000097          	auipc	ra,0x0
    800028e0:	8e6080e7          	jalr	-1818(ra) # 800021c2 <exit>
    800028e4:	b765                	j	8000288c <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028e6:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800028ea:	5890                	lw	a2,48(s1)
    800028ec:	00006517          	auipc	a0,0x6
    800028f0:	a5450513          	addi	a0,a0,-1452 # 80008340 <states.0+0x78>
    800028f4:	ffffe097          	auipc	ra,0xffffe
    800028f8:	c96080e7          	jalr	-874(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028fc:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002900:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002904:	00006517          	auipc	a0,0x6
    80002908:	a6c50513          	addi	a0,a0,-1428 # 80008370 <states.0+0xa8>
    8000290c:	ffffe097          	auipc	ra,0xffffe
    80002910:	c7e080e7          	jalr	-898(ra) # 8000058a <printf>
    setkilled(p);
    80002914:	8526                	mv	a0,s1
    80002916:	00000097          	auipc	ra,0x0
    8000291a:	9f4080e7          	jalr	-1548(ra) # 8000230a <setkilled>
    8000291e:	b769                	j	800028a8 <usertrap+0x8e>
    yield();
    80002920:	fffff097          	auipc	ra,0xfffff
    80002924:	732080e7          	jalr	1842(ra) # 80002052 <yield>
    80002928:	bf79                	j	800028c6 <usertrap+0xac>

000000008000292a <kerneltrap>:
{
    8000292a:	7179                	addi	sp,sp,-48
    8000292c:	f406                	sd	ra,40(sp)
    8000292e:	f022                	sd	s0,32(sp)
    80002930:	ec26                	sd	s1,24(sp)
    80002932:	e84a                	sd	s2,16(sp)
    80002934:	e44e                	sd	s3,8(sp)
    80002936:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002938:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000293c:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002940:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002944:	1004f793          	andi	a5,s1,256
    80002948:	cb85                	beqz	a5,80002978 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000294a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000294e:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002950:	ef85                	bnez	a5,80002988 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002952:	00000097          	auipc	ra,0x0
    80002956:	e26080e7          	jalr	-474(ra) # 80002778 <devintr>
    8000295a:	cd1d                	beqz	a0,80002998 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000295c:	4789                	li	a5,2
    8000295e:	06f50a63          	beq	a0,a5,800029d2 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002962:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002966:	10049073          	csrw	sstatus,s1
}
    8000296a:	70a2                	ld	ra,40(sp)
    8000296c:	7402                	ld	s0,32(sp)
    8000296e:	64e2                	ld	s1,24(sp)
    80002970:	6942                	ld	s2,16(sp)
    80002972:	69a2                	ld	s3,8(sp)
    80002974:	6145                	addi	sp,sp,48
    80002976:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002978:	00006517          	auipc	a0,0x6
    8000297c:	a1850513          	addi	a0,a0,-1512 # 80008390 <states.0+0xc8>
    80002980:	ffffe097          	auipc	ra,0xffffe
    80002984:	bc0080e7          	jalr	-1088(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002988:	00006517          	auipc	a0,0x6
    8000298c:	a3050513          	addi	a0,a0,-1488 # 800083b8 <states.0+0xf0>
    80002990:	ffffe097          	auipc	ra,0xffffe
    80002994:	bb0080e7          	jalr	-1104(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80002998:	85ce                	mv	a1,s3
    8000299a:	00006517          	auipc	a0,0x6
    8000299e:	a3e50513          	addi	a0,a0,-1474 # 800083d8 <states.0+0x110>
    800029a2:	ffffe097          	auipc	ra,0xffffe
    800029a6:	be8080e7          	jalr	-1048(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029aa:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029ae:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029b2:	00006517          	auipc	a0,0x6
    800029b6:	a3650513          	addi	a0,a0,-1482 # 800083e8 <states.0+0x120>
    800029ba:	ffffe097          	auipc	ra,0xffffe
    800029be:	bd0080e7          	jalr	-1072(ra) # 8000058a <printf>
    panic("kerneltrap");
    800029c2:	00006517          	auipc	a0,0x6
    800029c6:	a3e50513          	addi	a0,a0,-1474 # 80008400 <states.0+0x138>
    800029ca:	ffffe097          	auipc	ra,0xffffe
    800029ce:	b76080e7          	jalr	-1162(ra) # 80000540 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029d2:	fffff097          	auipc	ra,0xfffff
    800029d6:	fda080e7          	jalr	-38(ra) # 800019ac <myproc>
    800029da:	d541                	beqz	a0,80002962 <kerneltrap+0x38>
    800029dc:	fffff097          	auipc	ra,0xfffff
    800029e0:	fd0080e7          	jalr	-48(ra) # 800019ac <myproc>
    800029e4:	4d18                	lw	a4,24(a0)
    800029e6:	4791                	li	a5,4
    800029e8:	f6f71de3          	bne	a4,a5,80002962 <kerneltrap+0x38>
    yield();
    800029ec:	fffff097          	auipc	ra,0xfffff
    800029f0:	666080e7          	jalr	1638(ra) # 80002052 <yield>
    800029f4:	b7bd                	j	80002962 <kerneltrap+0x38>

00000000800029f6 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800029f6:	1101                	addi	sp,sp,-32
    800029f8:	ec06                	sd	ra,24(sp)
    800029fa:	e822                	sd	s0,16(sp)
    800029fc:	e426                	sd	s1,8(sp)
    800029fe:	1000                	addi	s0,sp,32
    80002a00:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a02:	fffff097          	auipc	ra,0xfffff
    80002a06:	faa080e7          	jalr	-86(ra) # 800019ac <myproc>
  switch (n) {
    80002a0a:	4795                	li	a5,5
    80002a0c:	0497e163          	bltu	a5,s1,80002a4e <argraw+0x58>
    80002a10:	048a                	slli	s1,s1,0x2
    80002a12:	00006717          	auipc	a4,0x6
    80002a16:	b5e70713          	addi	a4,a4,-1186 # 80008570 <states.0+0x2a8>
    80002a1a:	94ba                	add	s1,s1,a4
    80002a1c:	409c                	lw	a5,0(s1)
    80002a1e:	97ba                	add	a5,a5,a4
    80002a20:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a22:	6d3c                	ld	a5,88(a0)
    80002a24:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a26:	60e2                	ld	ra,24(sp)
    80002a28:	6442                	ld	s0,16(sp)
    80002a2a:	64a2                	ld	s1,8(sp)
    80002a2c:	6105                	addi	sp,sp,32
    80002a2e:	8082                	ret
    return p->trapframe->a1;
    80002a30:	6d3c                	ld	a5,88(a0)
    80002a32:	7fa8                	ld	a0,120(a5)
    80002a34:	bfcd                	j	80002a26 <argraw+0x30>
    return p->trapframe->a2;
    80002a36:	6d3c                	ld	a5,88(a0)
    80002a38:	63c8                	ld	a0,128(a5)
    80002a3a:	b7f5                	j	80002a26 <argraw+0x30>
    return p->trapframe->a3;
    80002a3c:	6d3c                	ld	a5,88(a0)
    80002a3e:	67c8                	ld	a0,136(a5)
    80002a40:	b7dd                	j	80002a26 <argraw+0x30>
    return p->trapframe->a4;
    80002a42:	6d3c                	ld	a5,88(a0)
    80002a44:	6bc8                	ld	a0,144(a5)
    80002a46:	b7c5                	j	80002a26 <argraw+0x30>
    return p->trapframe->a5;
    80002a48:	6d3c                	ld	a5,88(a0)
    80002a4a:	6fc8                	ld	a0,152(a5)
    80002a4c:	bfe9                	j	80002a26 <argraw+0x30>
  panic("argraw");
    80002a4e:	00006517          	auipc	a0,0x6
    80002a52:	9c250513          	addi	a0,a0,-1598 # 80008410 <states.0+0x148>
    80002a56:	ffffe097          	auipc	ra,0xffffe
    80002a5a:	aea080e7          	jalr	-1302(ra) # 80000540 <panic>

0000000080002a5e <fetchaddr>:
{
    80002a5e:	1101                	addi	sp,sp,-32
    80002a60:	ec06                	sd	ra,24(sp)
    80002a62:	e822                	sd	s0,16(sp)
    80002a64:	e426                	sd	s1,8(sp)
    80002a66:	e04a                	sd	s2,0(sp)
    80002a68:	1000                	addi	s0,sp,32
    80002a6a:	84aa                	mv	s1,a0
    80002a6c:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002a6e:	fffff097          	auipc	ra,0xfffff
    80002a72:	f3e080e7          	jalr	-194(ra) # 800019ac <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002a76:	653c                	ld	a5,72(a0)
    80002a78:	02f4f863          	bgeu	s1,a5,80002aa8 <fetchaddr+0x4a>
    80002a7c:	00848713          	addi	a4,s1,8
    80002a80:	02e7e663          	bltu	a5,a4,80002aac <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002a84:	46a1                	li	a3,8
    80002a86:	8626                	mv	a2,s1
    80002a88:	85ca                	mv	a1,s2
    80002a8a:	6928                	ld	a0,80(a0)
    80002a8c:	fffff097          	auipc	ra,0xfffff
    80002a90:	c6c080e7          	jalr	-916(ra) # 800016f8 <copyin>
    80002a94:	00a03533          	snez	a0,a0
    80002a98:	40a00533          	neg	a0,a0
}
    80002a9c:	60e2                	ld	ra,24(sp)
    80002a9e:	6442                	ld	s0,16(sp)
    80002aa0:	64a2                	ld	s1,8(sp)
    80002aa2:	6902                	ld	s2,0(sp)
    80002aa4:	6105                	addi	sp,sp,32
    80002aa6:	8082                	ret
    return -1;
    80002aa8:	557d                	li	a0,-1
    80002aaa:	bfcd                	j	80002a9c <fetchaddr+0x3e>
    80002aac:	557d                	li	a0,-1
    80002aae:	b7fd                	j	80002a9c <fetchaddr+0x3e>

0000000080002ab0 <fetchstr>:
{
    80002ab0:	7179                	addi	sp,sp,-48
    80002ab2:	f406                	sd	ra,40(sp)
    80002ab4:	f022                	sd	s0,32(sp)
    80002ab6:	ec26                	sd	s1,24(sp)
    80002ab8:	e84a                	sd	s2,16(sp)
    80002aba:	e44e                	sd	s3,8(sp)
    80002abc:	1800                	addi	s0,sp,48
    80002abe:	892a                	mv	s2,a0
    80002ac0:	84ae                	mv	s1,a1
    80002ac2:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002ac4:	fffff097          	auipc	ra,0xfffff
    80002ac8:	ee8080e7          	jalr	-280(ra) # 800019ac <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002acc:	86ce                	mv	a3,s3
    80002ace:	864a                	mv	a2,s2
    80002ad0:	85a6                	mv	a1,s1
    80002ad2:	6928                	ld	a0,80(a0)
    80002ad4:	fffff097          	auipc	ra,0xfffff
    80002ad8:	cb2080e7          	jalr	-846(ra) # 80001786 <copyinstr>
    80002adc:	00054e63          	bltz	a0,80002af8 <fetchstr+0x48>
  return strlen(buf);
    80002ae0:	8526                	mv	a0,s1
    80002ae2:	ffffe097          	auipc	ra,0xffffe
    80002ae6:	36c080e7          	jalr	876(ra) # 80000e4e <strlen>
}
    80002aea:	70a2                	ld	ra,40(sp)
    80002aec:	7402                	ld	s0,32(sp)
    80002aee:	64e2                	ld	s1,24(sp)
    80002af0:	6942                	ld	s2,16(sp)
    80002af2:	69a2                	ld	s3,8(sp)
    80002af4:	6145                	addi	sp,sp,48
    80002af6:	8082                	ret
    return -1;
    80002af8:	557d                	li	a0,-1
    80002afa:	bfc5                	j	80002aea <fetchstr+0x3a>

0000000080002afc <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002afc:	1101                	addi	sp,sp,-32
    80002afe:	ec06                	sd	ra,24(sp)
    80002b00:	e822                	sd	s0,16(sp)
    80002b02:	e426                	sd	s1,8(sp)
    80002b04:	1000                	addi	s0,sp,32
    80002b06:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b08:	00000097          	auipc	ra,0x0
    80002b0c:	eee080e7          	jalr	-274(ra) # 800029f6 <argraw>
    80002b10:	c088                	sw	a0,0(s1)
}
    80002b12:	60e2                	ld	ra,24(sp)
    80002b14:	6442                	ld	s0,16(sp)
    80002b16:	64a2                	ld	s1,8(sp)
    80002b18:	6105                	addi	sp,sp,32
    80002b1a:	8082                	ret

0000000080002b1c <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002b1c:	1101                	addi	sp,sp,-32
    80002b1e:	ec06                	sd	ra,24(sp)
    80002b20:	e822                	sd	s0,16(sp)
    80002b22:	e426                	sd	s1,8(sp)
    80002b24:	1000                	addi	s0,sp,32
    80002b26:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b28:	00000097          	auipc	ra,0x0
    80002b2c:	ece080e7          	jalr	-306(ra) # 800029f6 <argraw>
    80002b30:	e088                	sd	a0,0(s1)
}
    80002b32:	60e2                	ld	ra,24(sp)
    80002b34:	6442                	ld	s0,16(sp)
    80002b36:	64a2                	ld	s1,8(sp)
    80002b38:	6105                	addi	sp,sp,32
    80002b3a:	8082                	ret

0000000080002b3c <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002b3c:	7179                	addi	sp,sp,-48
    80002b3e:	f406                	sd	ra,40(sp)
    80002b40:	f022                	sd	s0,32(sp)
    80002b42:	ec26                	sd	s1,24(sp)
    80002b44:	e84a                	sd	s2,16(sp)
    80002b46:	1800                	addi	s0,sp,48
    80002b48:	84ae                	mv	s1,a1
    80002b4a:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002b4c:	fd840593          	addi	a1,s0,-40
    80002b50:	00000097          	auipc	ra,0x0
    80002b54:	fcc080e7          	jalr	-52(ra) # 80002b1c <argaddr>
  return fetchstr(addr, buf, max);
    80002b58:	864a                	mv	a2,s2
    80002b5a:	85a6                	mv	a1,s1
    80002b5c:	fd843503          	ld	a0,-40(s0)
    80002b60:	00000097          	auipc	ra,0x0
    80002b64:	f50080e7          	jalr	-176(ra) # 80002ab0 <fetchstr>
}
    80002b68:	70a2                	ld	ra,40(sp)
    80002b6a:	7402                	ld	s0,32(sp)
    80002b6c:	64e2                	ld	s1,24(sp)
    80002b6e:	6942                	ld	s2,16(sp)
    80002b70:	6145                	addi	sp,sp,48
    80002b72:	8082                	ret

0000000080002b74 <syscall>:
[SYS_audit]   sys_audit,
};

void
syscall(void)
{
    80002b74:	715d                	addi	sp,sp,-80
    80002b76:	e486                	sd	ra,72(sp)
    80002b78:	e0a2                	sd	s0,64(sp)
    80002b7a:	fc26                	sd	s1,56(sp)
    80002b7c:	f84a                	sd	s2,48(sp)
    80002b7e:	f44e                	sd	s3,40(sp)
    80002b80:	f052                	sd	s4,32(sp)
    80002b82:	ec56                	sd	s5,24(sp)
    80002b84:	e85a                	sd	s6,16(sp)
    80002b86:	0880                	addi	s0,sp,80
  int num;
  struct proc *p = myproc();
    80002b88:	fffff097          	auipc	ra,0xfffff
    80002b8c:	e24080e7          	jalr	-476(ra) # 800019ac <myproc>
    80002b90:	84aa                	mv	s1,a0

  // any time we are here, we are about to make a system call.
  // we can intercept args, etc.
  num = p->trapframe->a7;
    80002b92:	6d3c                	ld	a5,88(a0)
    80002b94:	77dc                	ld	a5,168(a5)
    80002b96:	0007891b          	sext.w	s2,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002b9a:	fff7869b          	addiw	a3,a5,-1
    80002b9e:	4755                	li	a4,21
    80002ba0:	12d76663          	bltu	a4,a3,80002ccc <syscall+0x158>
    80002ba4:	00391693          	slli	a3,s2,0x3
    80002ba8:	00006717          	auipc	a4,0x6
    80002bac:	9e070713          	addi	a4,a4,-1568 # 80008588 <syscalls>
    80002bb0:	9736                	add	a4,a4,a3
    80002bb2:	00073a03          	ld	s4,0(a4)
    80002bb6:	100a0b63          	beqz	s4,80002ccc <syscall+0x158>
    // steal the file away, if there is one, before we return a0.
    int fd = -1;
    struct file *f;

    // if it's any of these file related operations
    if (num == SYS_read || num == SYS_fstat || num == SYS_dup 
    80002bba:	4715                	li	a4,5
    80002bbc:	06e90c63          	beq	s2,a4,80002c34 <syscall+0xc0>
    80002bc0:	4755                	li	a4,21
    80002bc2:	0d276c63          	bltu	a4,s2,80002c9a <syscall+0x126>
    80002bc6:	00218737          	lui	a4,0x218
    80002bca:	50070713          	addi	a4,a4,1280 # 218500 <_entry-0x7fde7b00>
    80002bce:	012757b3          	srl	a5,a4,s2
    80002bd2:	8b85                	andi	a5,a5,1
    80002bd4:	e3a5                	bnez	a5,80002c34 <syscall+0xc0>
      // we are trying to do SOMETHING with this file.
      argfd(0, &fd, &f);
    }
    
    // let the system call go through.
    p->trapframe->a0 = syscalls[num]();
    80002bd6:	05853a83          	ld	s5,88(a0)
    80002bda:	9a02                	jalr	s4
    80002bdc:	06aab823          	sd	a0,112(s5)
    80002be0:	5afd                	li	s5,-1
        audit_num = audit_num >> 1;
      }
    }

    // it should always be apparent when audit is called.
    if (whitelisted[num - 1] || num == SYS_audit) {
    80002be2:	fff9071b          	addiw	a4,s2,-1
    80002be6:	00006797          	auipc	a5,0x6
    80002bea:	de278793          	addi	a5,a5,-542 # 800089c8 <whitelisted>
    80002bee:	97ba                	add	a5,a5,a4
    80002bf0:	0007c783          	lbu	a5,0(a5)
    80002bf4:	cbfd                	beqz	a5,80002cea <syscall+0x176>
      // these things will be consistent across processes, no matter if it used a file
      struct audit_data cur;
      cur.process_pid = p->pid;
    80002bf6:	5890                	lw	a2,48(s1)
      cur.process_name = p->name;
    80002bf8:	15848593          	addi	a1,s1,344
      cur.time = ticks;
    80002bfc:	00006717          	auipc	a4,0x6
    80002c00:	ef472703          	lw	a4,-268(a4) # 80008af0 <ticks>
      cur.process_name = name_from_num[num];
    80002c04:	090e                	slli	s2,s2,0x3
    80002c06:	00006797          	auipc	a5,0x6
    80002c0a:	dc278793          	addi	a5,a5,-574 # 800089c8 <whitelisted>
    80002c0e:	97ca                	add	a5,a5,s2
    80002c10:	6f94                	ld	a3,24(a5)
      if (fd != -1) {
    80002c12:	57fd                	li	a5,-1
    80002c14:	0afa8363          	beq	s5,a5,80002cba <syscall+0x146>
        // need to set fd info
        cur.fd_used = 1;
        cur.fd_read = f->readable;
        cur.fd_write = f->writable;
        printf("Process %s pid %d called syscall %s at time %d and used FD %d (perms r: %d, w: %d)\n",
    80002c18:	0099c883          	lbu	a7,9(s3)
    80002c1c:	0089c803          	lbu	a6,8(s3)
    80002c20:	87d6                	mv	a5,s5
    80002c22:	00005517          	auipc	a0,0x5
    80002c26:	7f650513          	addi	a0,a0,2038 # 80008418 <states.0+0x150>
    80002c2a:	ffffe097          	auipc	ra,0xffffe
    80002c2e:	960080e7          	jalr	-1696(ra) # 8000058a <printf>
    80002c32:	a865                	j	80002cea <syscall+0x176>
  argint(n, &fd);
    80002c34:	fbc40593          	addi	a1,s0,-68
    80002c38:	4501                	li	a0,0
    80002c3a:	00000097          	auipc	ra,0x0
    80002c3e:	ec2080e7          	jalr	-318(ra) # 80002afc <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80002c42:	fbc42a83          	lw	s5,-68(s0)
    80002c46:	000a871b          	sext.w	a4,s5
    80002c4a:	47bd                	li	a5,15
    80002c4c:	04e7e563          	bltu	a5,a4,80002c96 <syscall+0x122>
    80002c50:	fffff097          	auipc	ra,0xfffff
    80002c54:	d5c080e7          	jalr	-676(ra) # 800019ac <myproc>
    80002c58:	01aa8793          	addi	a5,s5,26
    80002c5c:	078e                	slli	a5,a5,0x3
    80002c5e:	953e                	add	a0,a0,a5
    80002c60:	00053983          	ld	s3,0(a0)
    80002c64:	02098763          	beqz	s3,80002c92 <syscall+0x11e>
    p->trapframe->a0 = syscalls[num]();
    80002c68:	0584bb03          	ld	s6,88(s1)
    80002c6c:	9a02                	jalr	s4
    80002c6e:	06ab3823          	sd	a0,112(s6)
    if (num == 22) {
    80002c72:	47d9                	li	a5,22
    80002c74:	f6f917e3          	bne	s2,a5,80002be2 <syscall+0x6e>
      uint audit_num = (uint) p->trapframe->a0;
    80002c78:	6cbc                	ld	a5,88(s1)
    80002c7a:	5bb8                	lw	a4,112(a5)
      for (int i = 0; i < NUM_SYS_CALLS; i++) {
    80002c7c:	00006797          	auipc	a5,0x6
    80002c80:	d4c78793          	addi	a5,a5,-692 # 800089c8 <whitelisted>
    80002c84:	00006697          	auipc	a3,0x6
    80002c88:	d5968693          	addi	a3,a3,-679 # 800089dd <whitelisted+0x15>
    80002c8c:	85b6                	mv	a1,a3
          whitelisted[NUM_SYS_CALLS - i] = 1;
    80002c8e:	4505                	li	a0,1
    80002c90:	a829                	j	80002caa <syscall+0x136>
    int fd = -1;
    80002c92:	5afd                	li	s5,-1
    80002c94:	bfd1                	j	80002c68 <syscall+0xf4>
    80002c96:	5afd                	li	s5,-1
    80002c98:	bfc1                	j	80002c68 <syscall+0xf4>
    if (num == SYS_read || num == SYS_fstat || num == SYS_dup 
    80002c9a:	5afd                	li	s5,-1
    80002c9c:	b7f1                	j	80002c68 <syscall+0xf4>
        audit_num = audit_num >> 1;
    80002c9e:	0017571b          	srliw	a4,a4,0x1
      for (int i = 0; i < NUM_SYS_CALLS; i++) {
    80002ca2:	0785                	addi	a5,a5,1
    80002ca4:	16fd                	addi	a3,a3,-1
    80002ca6:	f4f588e3          	beq	a1,a5,80002bf6 <syscall+0x82>
        whitelisted[i] = 0; // reset the array position first.
    80002caa:	00078023          	sb	zero,0(a5)
        if (audit_num & 0b00000000000000000000000000000001) { // bit was toggled, whitelist
    80002cae:	00177613          	andi	a2,a4,1
    80002cb2:	d675                	beqz	a2,80002c9e <syscall+0x12a>
          whitelisted[NUM_SYS_CALLS - i] = 1;
    80002cb4:	00a68023          	sb	a0,0(a3)
    80002cb8:	b7dd                	j	80002c9e <syscall+0x12a>
                p->name, p->pid, name_from_num[num], ticks, fd, f->readable, f->writable);
      } else {
        // just say we didn't use one
        cur.fd_used = 0;
        printf("Process %s pid %d called syscall %s at time %d\n", 
    80002cba:	00005517          	auipc	a0,0x5
    80002cbe:	7b650513          	addi	a0,a0,1974 # 80008470 <states.0+0x1a8>
    80002cc2:	ffffe097          	auipc	ra,0xffffe
    80002cc6:	8c8080e7          	jalr	-1848(ra) # 8000058a <printf>
    80002cca:	a005                	j	80002cea <syscall+0x176>
      // here just so we don't throw unused variable errors
      int bruh = cur.process_pid;
      bruh++;
    }
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002ccc:	86ca                	mv	a3,s2
    80002cce:	15848613          	addi	a2,s1,344
    80002cd2:	588c                	lw	a1,48(s1)
    80002cd4:	00005517          	auipc	a0,0x5
    80002cd8:	7cc50513          	addi	a0,a0,1996 # 800084a0 <states.0+0x1d8>
    80002cdc:	ffffe097          	auipc	ra,0xffffe
    80002ce0:	8ae080e7          	jalr	-1874(ra) # 8000058a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002ce4:	6cbc                	ld	a5,88(s1)
    80002ce6:	577d                	li	a4,-1
    80002ce8:	fbb8                	sd	a4,112(a5)
  }
}
    80002cea:	60a6                	ld	ra,72(sp)
    80002cec:	6406                	ld	s0,64(sp)
    80002cee:	74e2                	ld	s1,56(sp)
    80002cf0:	7942                	ld	s2,48(sp)
    80002cf2:	79a2                	ld	s3,40(sp)
    80002cf4:	7a02                	ld	s4,32(sp)
    80002cf6:	6ae2                	ld	s5,24(sp)
    80002cf8:	6b42                	ld	s6,16(sp)
    80002cfa:	6161                	addi	sp,sp,80
    80002cfc:	8082                	ret

0000000080002cfe <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002cfe:	1101                	addi	sp,sp,-32
    80002d00:	ec06                	sd	ra,24(sp)
    80002d02:	e822                	sd	s0,16(sp)
    80002d04:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002d06:	fec40593          	addi	a1,s0,-20
    80002d0a:	4501                	li	a0,0
    80002d0c:	00000097          	auipc	ra,0x0
    80002d10:	df0080e7          	jalr	-528(ra) # 80002afc <argint>
  exit(n);
    80002d14:	fec42503          	lw	a0,-20(s0)
    80002d18:	fffff097          	auipc	ra,0xfffff
    80002d1c:	4aa080e7          	jalr	1194(ra) # 800021c2 <exit>
  return 0;  // not reached
}
    80002d20:	4501                	li	a0,0
    80002d22:	60e2                	ld	ra,24(sp)
    80002d24:	6442                	ld	s0,16(sp)
    80002d26:	6105                	addi	sp,sp,32
    80002d28:	8082                	ret

0000000080002d2a <sys_getpid>:

uint64
sys_getpid(void)
{
    80002d2a:	1141                	addi	sp,sp,-16
    80002d2c:	e406                	sd	ra,8(sp)
    80002d2e:	e022                	sd	s0,0(sp)
    80002d30:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002d32:	fffff097          	auipc	ra,0xfffff
    80002d36:	c7a080e7          	jalr	-902(ra) # 800019ac <myproc>
}
    80002d3a:	5908                	lw	a0,48(a0)
    80002d3c:	60a2                	ld	ra,8(sp)
    80002d3e:	6402                	ld	s0,0(sp)
    80002d40:	0141                	addi	sp,sp,16
    80002d42:	8082                	ret

0000000080002d44 <sys_fork>:

uint64
sys_fork(void)
{
    80002d44:	1141                	addi	sp,sp,-16
    80002d46:	e406                	sd	ra,8(sp)
    80002d48:	e022                	sd	s0,0(sp)
    80002d4a:	0800                	addi	s0,sp,16
  return fork();
    80002d4c:	fffff097          	auipc	ra,0xfffff
    80002d50:	016080e7          	jalr	22(ra) # 80001d62 <fork>
}
    80002d54:	60a2                	ld	ra,8(sp)
    80002d56:	6402                	ld	s0,0(sp)
    80002d58:	0141                	addi	sp,sp,16
    80002d5a:	8082                	ret

0000000080002d5c <sys_wait>:

uint64
sys_wait(void)
{
    80002d5c:	1101                	addi	sp,sp,-32
    80002d5e:	ec06                	sd	ra,24(sp)
    80002d60:	e822                	sd	s0,16(sp)
    80002d62:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002d64:	fe840593          	addi	a1,s0,-24
    80002d68:	4501                	li	a0,0
    80002d6a:	00000097          	auipc	ra,0x0
    80002d6e:	db2080e7          	jalr	-590(ra) # 80002b1c <argaddr>
  return wait(p);
    80002d72:	fe843503          	ld	a0,-24(s0)
    80002d76:	fffff097          	auipc	ra,0xfffff
    80002d7a:	5f2080e7          	jalr	1522(ra) # 80002368 <wait>
}
    80002d7e:	60e2                	ld	ra,24(sp)
    80002d80:	6442                	ld	s0,16(sp)
    80002d82:	6105                	addi	sp,sp,32
    80002d84:	8082                	ret

0000000080002d86 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d86:	7179                	addi	sp,sp,-48
    80002d88:	f406                	sd	ra,40(sp)
    80002d8a:	f022                	sd	s0,32(sp)
    80002d8c:	ec26                	sd	s1,24(sp)
    80002d8e:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002d90:	fdc40593          	addi	a1,s0,-36
    80002d94:	4501                	li	a0,0
    80002d96:	00000097          	auipc	ra,0x0
    80002d9a:	d66080e7          	jalr	-666(ra) # 80002afc <argint>
  addr = myproc()->sz;
    80002d9e:	fffff097          	auipc	ra,0xfffff
    80002da2:	c0e080e7          	jalr	-1010(ra) # 800019ac <myproc>
    80002da6:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002da8:	fdc42503          	lw	a0,-36(s0)
    80002dac:	fffff097          	auipc	ra,0xfffff
    80002db0:	f5a080e7          	jalr	-166(ra) # 80001d06 <growproc>
    80002db4:	00054863          	bltz	a0,80002dc4 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002db8:	8526                	mv	a0,s1
    80002dba:	70a2                	ld	ra,40(sp)
    80002dbc:	7402                	ld	s0,32(sp)
    80002dbe:	64e2                	ld	s1,24(sp)
    80002dc0:	6145                	addi	sp,sp,48
    80002dc2:	8082                	ret
    return -1;
    80002dc4:	54fd                	li	s1,-1
    80002dc6:	bfcd                	j	80002db8 <sys_sbrk+0x32>

0000000080002dc8 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002dc8:	7139                	addi	sp,sp,-64
    80002dca:	fc06                	sd	ra,56(sp)
    80002dcc:	f822                	sd	s0,48(sp)
    80002dce:	f426                	sd	s1,40(sp)
    80002dd0:	f04a                	sd	s2,32(sp)
    80002dd2:	ec4e                	sd	s3,24(sp)
    80002dd4:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002dd6:	fcc40593          	addi	a1,s0,-52
    80002dda:	4501                	li	a0,0
    80002ddc:	00000097          	auipc	ra,0x0
    80002de0:	d20080e7          	jalr	-736(ra) # 80002afc <argint>
  acquire(&tickslock);
    80002de4:	00014517          	auipc	a0,0x14
    80002de8:	fbc50513          	addi	a0,a0,-68 # 80016da0 <tickslock>
    80002dec:	ffffe097          	auipc	ra,0xffffe
    80002df0:	dea080e7          	jalr	-534(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80002df4:	00006917          	auipc	s2,0x6
    80002df8:	cfc92903          	lw	s2,-772(s2) # 80008af0 <ticks>
  while(ticks - ticks0 < n){
    80002dfc:	fcc42783          	lw	a5,-52(s0)
    80002e00:	cf9d                	beqz	a5,80002e3e <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002e02:	00014997          	auipc	s3,0x14
    80002e06:	f9e98993          	addi	s3,s3,-98 # 80016da0 <tickslock>
    80002e0a:	00006497          	auipc	s1,0x6
    80002e0e:	ce648493          	addi	s1,s1,-794 # 80008af0 <ticks>
    if(killed(myproc())){
    80002e12:	fffff097          	auipc	ra,0xfffff
    80002e16:	b9a080e7          	jalr	-1126(ra) # 800019ac <myproc>
    80002e1a:	fffff097          	auipc	ra,0xfffff
    80002e1e:	51c080e7          	jalr	1308(ra) # 80002336 <killed>
    80002e22:	ed15                	bnez	a0,80002e5e <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002e24:	85ce                	mv	a1,s3
    80002e26:	8526                	mv	a0,s1
    80002e28:	fffff097          	auipc	ra,0xfffff
    80002e2c:	266080e7          	jalr	614(ra) # 8000208e <sleep>
  while(ticks - ticks0 < n){
    80002e30:	409c                	lw	a5,0(s1)
    80002e32:	412787bb          	subw	a5,a5,s2
    80002e36:	fcc42703          	lw	a4,-52(s0)
    80002e3a:	fce7ece3          	bltu	a5,a4,80002e12 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002e3e:	00014517          	auipc	a0,0x14
    80002e42:	f6250513          	addi	a0,a0,-158 # 80016da0 <tickslock>
    80002e46:	ffffe097          	auipc	ra,0xffffe
    80002e4a:	e44080e7          	jalr	-444(ra) # 80000c8a <release>
  return 0;
    80002e4e:	4501                	li	a0,0
}
    80002e50:	70e2                	ld	ra,56(sp)
    80002e52:	7442                	ld	s0,48(sp)
    80002e54:	74a2                	ld	s1,40(sp)
    80002e56:	7902                	ld	s2,32(sp)
    80002e58:	69e2                	ld	s3,24(sp)
    80002e5a:	6121                	addi	sp,sp,64
    80002e5c:	8082                	ret
      release(&tickslock);
    80002e5e:	00014517          	auipc	a0,0x14
    80002e62:	f4250513          	addi	a0,a0,-190 # 80016da0 <tickslock>
    80002e66:	ffffe097          	auipc	ra,0xffffe
    80002e6a:	e24080e7          	jalr	-476(ra) # 80000c8a <release>
      return -1;
    80002e6e:	557d                	li	a0,-1
    80002e70:	b7c5                	j	80002e50 <sys_sleep+0x88>

0000000080002e72 <sys_kill>:

uint64
sys_kill(void)
{
    80002e72:	1101                	addi	sp,sp,-32
    80002e74:	ec06                	sd	ra,24(sp)
    80002e76:	e822                	sd	s0,16(sp)
    80002e78:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002e7a:	fec40593          	addi	a1,s0,-20
    80002e7e:	4501                	li	a0,0
    80002e80:	00000097          	auipc	ra,0x0
    80002e84:	c7c080e7          	jalr	-900(ra) # 80002afc <argint>
  return kill(pid);
    80002e88:	fec42503          	lw	a0,-20(s0)
    80002e8c:	fffff097          	auipc	ra,0xfffff
    80002e90:	40c080e7          	jalr	1036(ra) # 80002298 <kill>
}
    80002e94:	60e2                	ld	ra,24(sp)
    80002e96:	6442                	ld	s0,16(sp)
    80002e98:	6105                	addi	sp,sp,32
    80002e9a:	8082                	ret

0000000080002e9c <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e9c:	1101                	addi	sp,sp,-32
    80002e9e:	ec06                	sd	ra,24(sp)
    80002ea0:	e822                	sd	s0,16(sp)
    80002ea2:	e426                	sd	s1,8(sp)
    80002ea4:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002ea6:	00014517          	auipc	a0,0x14
    80002eaa:	efa50513          	addi	a0,a0,-262 # 80016da0 <tickslock>
    80002eae:	ffffe097          	auipc	ra,0xffffe
    80002eb2:	d28080e7          	jalr	-728(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80002eb6:	00006497          	auipc	s1,0x6
    80002eba:	c3a4a483          	lw	s1,-966(s1) # 80008af0 <ticks>
  release(&tickslock);
    80002ebe:	00014517          	auipc	a0,0x14
    80002ec2:	ee250513          	addi	a0,a0,-286 # 80016da0 <tickslock>
    80002ec6:	ffffe097          	auipc	ra,0xffffe
    80002eca:	dc4080e7          	jalr	-572(ra) # 80000c8a <release>
  return xticks;
}
    80002ece:	02049513          	slli	a0,s1,0x20
    80002ed2:	9101                	srli	a0,a0,0x20
    80002ed4:	60e2                	ld	ra,24(sp)
    80002ed6:	6442                	ld	s0,16(sp)
    80002ed8:	64a2                	ld	s1,8(sp)
    80002eda:	6105                	addi	sp,sp,32
    80002edc:	8082                	ret

0000000080002ede <sys_audit>:

uint64
sys_audit(void)
{
    80002ede:	1101                	addi	sp,sp,-32
    80002ee0:	ec06                	sd	ra,24(sp)
    80002ee2:	e822                	sd	s0,16(sp)
    80002ee4:	1000                	addi	s0,sp,32
  // fetch the integer
  int n;
  argint(0, &n); 
    80002ee6:	fec40593          	addi	a1,s0,-20
    80002eea:	4501                	li	a0,0
    80002eec:	00000097          	auipc	ra,0x0
    80002ef0:	c10080e7          	jalr	-1008(ra) # 80002afc <argint>
  return audit(n);
    80002ef4:	fec42503          	lw	a0,-20(s0)
    80002ef8:	fffff097          	auipc	ra,0xfffff
    80002efc:	faa080e7          	jalr	-86(ra) # 80001ea2 <audit>
}
    80002f00:	60e2                	ld	ra,24(sp)
    80002f02:	6442                	ld	s0,16(sp)
    80002f04:	6105                	addi	sp,sp,32
    80002f06:	8082                	ret

0000000080002f08 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f08:	7179                	addi	sp,sp,-48
    80002f0a:	f406                	sd	ra,40(sp)
    80002f0c:	f022                	sd	s0,32(sp)
    80002f0e:	ec26                	sd	s1,24(sp)
    80002f10:	e84a                	sd	s2,16(sp)
    80002f12:	e44e                	sd	s3,8(sp)
    80002f14:	e052                	sd	s4,0(sp)
    80002f16:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002f18:	00005597          	auipc	a1,0x5
    80002f1c:	72858593          	addi	a1,a1,1832 # 80008640 <syscalls+0xb8>
    80002f20:	00020517          	auipc	a0,0x20
    80002f24:	e9850513          	addi	a0,a0,-360 # 80022db8 <bcache>
    80002f28:	ffffe097          	auipc	ra,0xffffe
    80002f2c:	c1e080e7          	jalr	-994(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f30:	00028797          	auipc	a5,0x28
    80002f34:	e8878793          	addi	a5,a5,-376 # 8002adb8 <bcache+0x8000>
    80002f38:	00028717          	auipc	a4,0x28
    80002f3c:	0e870713          	addi	a4,a4,232 # 8002b020 <bcache+0x8268>
    80002f40:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f44:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f48:	00020497          	auipc	s1,0x20
    80002f4c:	e8848493          	addi	s1,s1,-376 # 80022dd0 <bcache+0x18>
    b->next = bcache.head.next;
    80002f50:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f52:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f54:	00005a17          	auipc	s4,0x5
    80002f58:	6f4a0a13          	addi	s4,s4,1780 # 80008648 <syscalls+0xc0>
    b->next = bcache.head.next;
    80002f5c:	2b893783          	ld	a5,696(s2)
    80002f60:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f62:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f66:	85d2                	mv	a1,s4
    80002f68:	01048513          	addi	a0,s1,16
    80002f6c:	00001097          	auipc	ra,0x1
    80002f70:	4c8080e7          	jalr	1224(ra) # 80004434 <initsleeplock>
    bcache.head.next->prev = b;
    80002f74:	2b893783          	ld	a5,696(s2)
    80002f78:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f7a:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f7e:	45848493          	addi	s1,s1,1112
    80002f82:	fd349de3          	bne	s1,s3,80002f5c <binit+0x54>
  }
}
    80002f86:	70a2                	ld	ra,40(sp)
    80002f88:	7402                	ld	s0,32(sp)
    80002f8a:	64e2                	ld	s1,24(sp)
    80002f8c:	6942                	ld	s2,16(sp)
    80002f8e:	69a2                	ld	s3,8(sp)
    80002f90:	6a02                	ld	s4,0(sp)
    80002f92:	6145                	addi	sp,sp,48
    80002f94:	8082                	ret

0000000080002f96 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f96:	7179                	addi	sp,sp,-48
    80002f98:	f406                	sd	ra,40(sp)
    80002f9a:	f022                	sd	s0,32(sp)
    80002f9c:	ec26                	sd	s1,24(sp)
    80002f9e:	e84a                	sd	s2,16(sp)
    80002fa0:	e44e                	sd	s3,8(sp)
    80002fa2:	1800                	addi	s0,sp,48
    80002fa4:	892a                	mv	s2,a0
    80002fa6:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002fa8:	00020517          	auipc	a0,0x20
    80002fac:	e1050513          	addi	a0,a0,-496 # 80022db8 <bcache>
    80002fb0:	ffffe097          	auipc	ra,0xffffe
    80002fb4:	c26080e7          	jalr	-986(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002fb8:	00028497          	auipc	s1,0x28
    80002fbc:	0b84b483          	ld	s1,184(s1) # 8002b070 <bcache+0x82b8>
    80002fc0:	00028797          	auipc	a5,0x28
    80002fc4:	06078793          	addi	a5,a5,96 # 8002b020 <bcache+0x8268>
    80002fc8:	02f48f63          	beq	s1,a5,80003006 <bread+0x70>
    80002fcc:	873e                	mv	a4,a5
    80002fce:	a021                	j	80002fd6 <bread+0x40>
    80002fd0:	68a4                	ld	s1,80(s1)
    80002fd2:	02e48a63          	beq	s1,a4,80003006 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002fd6:	449c                	lw	a5,8(s1)
    80002fd8:	ff279ce3          	bne	a5,s2,80002fd0 <bread+0x3a>
    80002fdc:	44dc                	lw	a5,12(s1)
    80002fde:	ff3799e3          	bne	a5,s3,80002fd0 <bread+0x3a>
      b->refcnt++;
    80002fe2:	40bc                	lw	a5,64(s1)
    80002fe4:	2785                	addiw	a5,a5,1
    80002fe6:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fe8:	00020517          	auipc	a0,0x20
    80002fec:	dd050513          	addi	a0,a0,-560 # 80022db8 <bcache>
    80002ff0:	ffffe097          	auipc	ra,0xffffe
    80002ff4:	c9a080e7          	jalr	-870(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80002ff8:	01048513          	addi	a0,s1,16
    80002ffc:	00001097          	auipc	ra,0x1
    80003000:	472080e7          	jalr	1138(ra) # 8000446e <acquiresleep>
      return b;
    80003004:	a8b9                	j	80003062 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003006:	00028497          	auipc	s1,0x28
    8000300a:	0624b483          	ld	s1,98(s1) # 8002b068 <bcache+0x82b0>
    8000300e:	00028797          	auipc	a5,0x28
    80003012:	01278793          	addi	a5,a5,18 # 8002b020 <bcache+0x8268>
    80003016:	00f48863          	beq	s1,a5,80003026 <bread+0x90>
    8000301a:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000301c:	40bc                	lw	a5,64(s1)
    8000301e:	cf81                	beqz	a5,80003036 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003020:	64a4                	ld	s1,72(s1)
    80003022:	fee49de3          	bne	s1,a4,8000301c <bread+0x86>
  panic("bget: no buffers");
    80003026:	00005517          	auipc	a0,0x5
    8000302a:	62a50513          	addi	a0,a0,1578 # 80008650 <syscalls+0xc8>
    8000302e:	ffffd097          	auipc	ra,0xffffd
    80003032:	512080e7          	jalr	1298(ra) # 80000540 <panic>
      b->dev = dev;
    80003036:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000303a:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    8000303e:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003042:	4785                	li	a5,1
    80003044:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003046:	00020517          	auipc	a0,0x20
    8000304a:	d7250513          	addi	a0,a0,-654 # 80022db8 <bcache>
    8000304e:	ffffe097          	auipc	ra,0xffffe
    80003052:	c3c080e7          	jalr	-964(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003056:	01048513          	addi	a0,s1,16
    8000305a:	00001097          	auipc	ra,0x1
    8000305e:	414080e7          	jalr	1044(ra) # 8000446e <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003062:	409c                	lw	a5,0(s1)
    80003064:	cb89                	beqz	a5,80003076 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003066:	8526                	mv	a0,s1
    80003068:	70a2                	ld	ra,40(sp)
    8000306a:	7402                	ld	s0,32(sp)
    8000306c:	64e2                	ld	s1,24(sp)
    8000306e:	6942                	ld	s2,16(sp)
    80003070:	69a2                	ld	s3,8(sp)
    80003072:	6145                	addi	sp,sp,48
    80003074:	8082                	ret
    virtio_disk_rw(b, 0);
    80003076:	4581                	li	a1,0
    80003078:	8526                	mv	a0,s1
    8000307a:	00003097          	auipc	ra,0x3
    8000307e:	fd8080e7          	jalr	-40(ra) # 80006052 <virtio_disk_rw>
    b->valid = 1;
    80003082:	4785                	li	a5,1
    80003084:	c09c                	sw	a5,0(s1)
  return b;
    80003086:	b7c5                	j	80003066 <bread+0xd0>

0000000080003088 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003088:	1101                	addi	sp,sp,-32
    8000308a:	ec06                	sd	ra,24(sp)
    8000308c:	e822                	sd	s0,16(sp)
    8000308e:	e426                	sd	s1,8(sp)
    80003090:	1000                	addi	s0,sp,32
    80003092:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003094:	0541                	addi	a0,a0,16
    80003096:	00001097          	auipc	ra,0x1
    8000309a:	472080e7          	jalr	1138(ra) # 80004508 <holdingsleep>
    8000309e:	cd01                	beqz	a0,800030b6 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800030a0:	4585                	li	a1,1
    800030a2:	8526                	mv	a0,s1
    800030a4:	00003097          	auipc	ra,0x3
    800030a8:	fae080e7          	jalr	-82(ra) # 80006052 <virtio_disk_rw>
}
    800030ac:	60e2                	ld	ra,24(sp)
    800030ae:	6442                	ld	s0,16(sp)
    800030b0:	64a2                	ld	s1,8(sp)
    800030b2:	6105                	addi	sp,sp,32
    800030b4:	8082                	ret
    panic("bwrite");
    800030b6:	00005517          	auipc	a0,0x5
    800030ba:	5b250513          	addi	a0,a0,1458 # 80008668 <syscalls+0xe0>
    800030be:	ffffd097          	auipc	ra,0xffffd
    800030c2:	482080e7          	jalr	1154(ra) # 80000540 <panic>

00000000800030c6 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800030c6:	1101                	addi	sp,sp,-32
    800030c8:	ec06                	sd	ra,24(sp)
    800030ca:	e822                	sd	s0,16(sp)
    800030cc:	e426                	sd	s1,8(sp)
    800030ce:	e04a                	sd	s2,0(sp)
    800030d0:	1000                	addi	s0,sp,32
    800030d2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030d4:	01050913          	addi	s2,a0,16
    800030d8:	854a                	mv	a0,s2
    800030da:	00001097          	auipc	ra,0x1
    800030de:	42e080e7          	jalr	1070(ra) # 80004508 <holdingsleep>
    800030e2:	c92d                	beqz	a0,80003154 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800030e4:	854a                	mv	a0,s2
    800030e6:	00001097          	auipc	ra,0x1
    800030ea:	3de080e7          	jalr	990(ra) # 800044c4 <releasesleep>

  acquire(&bcache.lock);
    800030ee:	00020517          	auipc	a0,0x20
    800030f2:	cca50513          	addi	a0,a0,-822 # 80022db8 <bcache>
    800030f6:	ffffe097          	auipc	ra,0xffffe
    800030fa:	ae0080e7          	jalr	-1312(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800030fe:	40bc                	lw	a5,64(s1)
    80003100:	37fd                	addiw	a5,a5,-1
    80003102:	0007871b          	sext.w	a4,a5
    80003106:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003108:	eb05                	bnez	a4,80003138 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000310a:	68bc                	ld	a5,80(s1)
    8000310c:	64b8                	ld	a4,72(s1)
    8000310e:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003110:	64bc                	ld	a5,72(s1)
    80003112:	68b8                	ld	a4,80(s1)
    80003114:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003116:	00028797          	auipc	a5,0x28
    8000311a:	ca278793          	addi	a5,a5,-862 # 8002adb8 <bcache+0x8000>
    8000311e:	2b87b703          	ld	a4,696(a5)
    80003122:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003124:	00028717          	auipc	a4,0x28
    80003128:	efc70713          	addi	a4,a4,-260 # 8002b020 <bcache+0x8268>
    8000312c:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000312e:	2b87b703          	ld	a4,696(a5)
    80003132:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003134:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003138:	00020517          	auipc	a0,0x20
    8000313c:	c8050513          	addi	a0,a0,-896 # 80022db8 <bcache>
    80003140:	ffffe097          	auipc	ra,0xffffe
    80003144:	b4a080e7          	jalr	-1206(ra) # 80000c8a <release>
}
    80003148:	60e2                	ld	ra,24(sp)
    8000314a:	6442                	ld	s0,16(sp)
    8000314c:	64a2                	ld	s1,8(sp)
    8000314e:	6902                	ld	s2,0(sp)
    80003150:	6105                	addi	sp,sp,32
    80003152:	8082                	ret
    panic("brelse");
    80003154:	00005517          	auipc	a0,0x5
    80003158:	51c50513          	addi	a0,a0,1308 # 80008670 <syscalls+0xe8>
    8000315c:	ffffd097          	auipc	ra,0xffffd
    80003160:	3e4080e7          	jalr	996(ra) # 80000540 <panic>

0000000080003164 <bpin>:

void
bpin(struct buf *b) {
    80003164:	1101                	addi	sp,sp,-32
    80003166:	ec06                	sd	ra,24(sp)
    80003168:	e822                	sd	s0,16(sp)
    8000316a:	e426                	sd	s1,8(sp)
    8000316c:	1000                	addi	s0,sp,32
    8000316e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003170:	00020517          	auipc	a0,0x20
    80003174:	c4850513          	addi	a0,a0,-952 # 80022db8 <bcache>
    80003178:	ffffe097          	auipc	ra,0xffffe
    8000317c:	a5e080e7          	jalr	-1442(ra) # 80000bd6 <acquire>
  b->refcnt++;
    80003180:	40bc                	lw	a5,64(s1)
    80003182:	2785                	addiw	a5,a5,1
    80003184:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003186:	00020517          	auipc	a0,0x20
    8000318a:	c3250513          	addi	a0,a0,-974 # 80022db8 <bcache>
    8000318e:	ffffe097          	auipc	ra,0xffffe
    80003192:	afc080e7          	jalr	-1284(ra) # 80000c8a <release>
}
    80003196:	60e2                	ld	ra,24(sp)
    80003198:	6442                	ld	s0,16(sp)
    8000319a:	64a2                	ld	s1,8(sp)
    8000319c:	6105                	addi	sp,sp,32
    8000319e:	8082                	ret

00000000800031a0 <bunpin>:

void
bunpin(struct buf *b) {
    800031a0:	1101                	addi	sp,sp,-32
    800031a2:	ec06                	sd	ra,24(sp)
    800031a4:	e822                	sd	s0,16(sp)
    800031a6:	e426                	sd	s1,8(sp)
    800031a8:	1000                	addi	s0,sp,32
    800031aa:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031ac:	00020517          	auipc	a0,0x20
    800031b0:	c0c50513          	addi	a0,a0,-1012 # 80022db8 <bcache>
    800031b4:	ffffe097          	auipc	ra,0xffffe
    800031b8:	a22080e7          	jalr	-1502(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800031bc:	40bc                	lw	a5,64(s1)
    800031be:	37fd                	addiw	a5,a5,-1
    800031c0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031c2:	00020517          	auipc	a0,0x20
    800031c6:	bf650513          	addi	a0,a0,-1034 # 80022db8 <bcache>
    800031ca:	ffffe097          	auipc	ra,0xffffe
    800031ce:	ac0080e7          	jalr	-1344(ra) # 80000c8a <release>
}
    800031d2:	60e2                	ld	ra,24(sp)
    800031d4:	6442                	ld	s0,16(sp)
    800031d6:	64a2                	ld	s1,8(sp)
    800031d8:	6105                	addi	sp,sp,32
    800031da:	8082                	ret

00000000800031dc <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800031dc:	1101                	addi	sp,sp,-32
    800031de:	ec06                	sd	ra,24(sp)
    800031e0:	e822                	sd	s0,16(sp)
    800031e2:	e426                	sd	s1,8(sp)
    800031e4:	e04a                	sd	s2,0(sp)
    800031e6:	1000                	addi	s0,sp,32
    800031e8:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800031ea:	00d5d59b          	srliw	a1,a1,0xd
    800031ee:	00028797          	auipc	a5,0x28
    800031f2:	2a67a783          	lw	a5,678(a5) # 8002b494 <sb+0x1c>
    800031f6:	9dbd                	addw	a1,a1,a5
    800031f8:	00000097          	auipc	ra,0x0
    800031fc:	d9e080e7          	jalr	-610(ra) # 80002f96 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003200:	0074f713          	andi	a4,s1,7
    80003204:	4785                	li	a5,1
    80003206:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000320a:	14ce                	slli	s1,s1,0x33
    8000320c:	90d9                	srli	s1,s1,0x36
    8000320e:	00950733          	add	a4,a0,s1
    80003212:	05874703          	lbu	a4,88(a4)
    80003216:	00e7f6b3          	and	a3,a5,a4
    8000321a:	c69d                	beqz	a3,80003248 <bfree+0x6c>
    8000321c:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000321e:	94aa                	add	s1,s1,a0
    80003220:	fff7c793          	not	a5,a5
    80003224:	8f7d                	and	a4,a4,a5
    80003226:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    8000322a:	00001097          	auipc	ra,0x1
    8000322e:	126080e7          	jalr	294(ra) # 80004350 <log_write>
  brelse(bp);
    80003232:	854a                	mv	a0,s2
    80003234:	00000097          	auipc	ra,0x0
    80003238:	e92080e7          	jalr	-366(ra) # 800030c6 <brelse>
}
    8000323c:	60e2                	ld	ra,24(sp)
    8000323e:	6442                	ld	s0,16(sp)
    80003240:	64a2                	ld	s1,8(sp)
    80003242:	6902                	ld	s2,0(sp)
    80003244:	6105                	addi	sp,sp,32
    80003246:	8082                	ret
    panic("freeing free block");
    80003248:	00005517          	auipc	a0,0x5
    8000324c:	43050513          	addi	a0,a0,1072 # 80008678 <syscalls+0xf0>
    80003250:	ffffd097          	auipc	ra,0xffffd
    80003254:	2f0080e7          	jalr	752(ra) # 80000540 <panic>

0000000080003258 <balloc>:
{
    80003258:	711d                	addi	sp,sp,-96
    8000325a:	ec86                	sd	ra,88(sp)
    8000325c:	e8a2                	sd	s0,80(sp)
    8000325e:	e4a6                	sd	s1,72(sp)
    80003260:	e0ca                	sd	s2,64(sp)
    80003262:	fc4e                	sd	s3,56(sp)
    80003264:	f852                	sd	s4,48(sp)
    80003266:	f456                	sd	s5,40(sp)
    80003268:	f05a                	sd	s6,32(sp)
    8000326a:	ec5e                	sd	s7,24(sp)
    8000326c:	e862                	sd	s8,16(sp)
    8000326e:	e466                	sd	s9,8(sp)
    80003270:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003272:	00028797          	auipc	a5,0x28
    80003276:	20a7a783          	lw	a5,522(a5) # 8002b47c <sb+0x4>
    8000327a:	cff5                	beqz	a5,80003376 <balloc+0x11e>
    8000327c:	8baa                	mv	s7,a0
    8000327e:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003280:	00028b17          	auipc	s6,0x28
    80003284:	1f8b0b13          	addi	s6,s6,504 # 8002b478 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003288:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000328a:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000328c:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000328e:	6c89                	lui	s9,0x2
    80003290:	a061                	j	80003318 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003292:	97ca                	add	a5,a5,s2
    80003294:	8e55                	or	a2,a2,a3
    80003296:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    8000329a:	854a                	mv	a0,s2
    8000329c:	00001097          	auipc	ra,0x1
    800032a0:	0b4080e7          	jalr	180(ra) # 80004350 <log_write>
        brelse(bp);
    800032a4:	854a                	mv	a0,s2
    800032a6:	00000097          	auipc	ra,0x0
    800032aa:	e20080e7          	jalr	-480(ra) # 800030c6 <brelse>
  bp = bread(dev, bno);
    800032ae:	85a6                	mv	a1,s1
    800032b0:	855e                	mv	a0,s7
    800032b2:	00000097          	auipc	ra,0x0
    800032b6:	ce4080e7          	jalr	-796(ra) # 80002f96 <bread>
    800032ba:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800032bc:	40000613          	li	a2,1024
    800032c0:	4581                	li	a1,0
    800032c2:	05850513          	addi	a0,a0,88
    800032c6:	ffffe097          	auipc	ra,0xffffe
    800032ca:	a0c080e7          	jalr	-1524(ra) # 80000cd2 <memset>
  log_write(bp);
    800032ce:	854a                	mv	a0,s2
    800032d0:	00001097          	auipc	ra,0x1
    800032d4:	080080e7          	jalr	128(ra) # 80004350 <log_write>
  brelse(bp);
    800032d8:	854a                	mv	a0,s2
    800032da:	00000097          	auipc	ra,0x0
    800032de:	dec080e7          	jalr	-532(ra) # 800030c6 <brelse>
}
    800032e2:	8526                	mv	a0,s1
    800032e4:	60e6                	ld	ra,88(sp)
    800032e6:	6446                	ld	s0,80(sp)
    800032e8:	64a6                	ld	s1,72(sp)
    800032ea:	6906                	ld	s2,64(sp)
    800032ec:	79e2                	ld	s3,56(sp)
    800032ee:	7a42                	ld	s4,48(sp)
    800032f0:	7aa2                	ld	s5,40(sp)
    800032f2:	7b02                	ld	s6,32(sp)
    800032f4:	6be2                	ld	s7,24(sp)
    800032f6:	6c42                	ld	s8,16(sp)
    800032f8:	6ca2                	ld	s9,8(sp)
    800032fa:	6125                	addi	sp,sp,96
    800032fc:	8082                	ret
    brelse(bp);
    800032fe:	854a                	mv	a0,s2
    80003300:	00000097          	auipc	ra,0x0
    80003304:	dc6080e7          	jalr	-570(ra) # 800030c6 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003308:	015c87bb          	addw	a5,s9,s5
    8000330c:	00078a9b          	sext.w	s5,a5
    80003310:	004b2703          	lw	a4,4(s6)
    80003314:	06eaf163          	bgeu	s5,a4,80003376 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    80003318:	41fad79b          	sraiw	a5,s5,0x1f
    8000331c:	0137d79b          	srliw	a5,a5,0x13
    80003320:	015787bb          	addw	a5,a5,s5
    80003324:	40d7d79b          	sraiw	a5,a5,0xd
    80003328:	01cb2583          	lw	a1,28(s6)
    8000332c:	9dbd                	addw	a1,a1,a5
    8000332e:	855e                	mv	a0,s7
    80003330:	00000097          	auipc	ra,0x0
    80003334:	c66080e7          	jalr	-922(ra) # 80002f96 <bread>
    80003338:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000333a:	004b2503          	lw	a0,4(s6)
    8000333e:	000a849b          	sext.w	s1,s5
    80003342:	8762                	mv	a4,s8
    80003344:	faa4fde3          	bgeu	s1,a0,800032fe <balloc+0xa6>
      m = 1 << (bi % 8);
    80003348:	00777693          	andi	a3,a4,7
    8000334c:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003350:	41f7579b          	sraiw	a5,a4,0x1f
    80003354:	01d7d79b          	srliw	a5,a5,0x1d
    80003358:	9fb9                	addw	a5,a5,a4
    8000335a:	4037d79b          	sraiw	a5,a5,0x3
    8000335e:	00f90633          	add	a2,s2,a5
    80003362:	05864603          	lbu	a2,88(a2)
    80003366:	00c6f5b3          	and	a1,a3,a2
    8000336a:	d585                	beqz	a1,80003292 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000336c:	2705                	addiw	a4,a4,1
    8000336e:	2485                	addiw	s1,s1,1
    80003370:	fd471ae3          	bne	a4,s4,80003344 <balloc+0xec>
    80003374:	b769                	j	800032fe <balloc+0xa6>
  printf("balloc: out of blocks\n");
    80003376:	00005517          	auipc	a0,0x5
    8000337a:	31a50513          	addi	a0,a0,794 # 80008690 <syscalls+0x108>
    8000337e:	ffffd097          	auipc	ra,0xffffd
    80003382:	20c080e7          	jalr	524(ra) # 8000058a <printf>
  return 0;
    80003386:	4481                	li	s1,0
    80003388:	bfa9                	j	800032e2 <balloc+0x8a>

000000008000338a <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    8000338a:	7179                	addi	sp,sp,-48
    8000338c:	f406                	sd	ra,40(sp)
    8000338e:	f022                	sd	s0,32(sp)
    80003390:	ec26                	sd	s1,24(sp)
    80003392:	e84a                	sd	s2,16(sp)
    80003394:	e44e                	sd	s3,8(sp)
    80003396:	e052                	sd	s4,0(sp)
    80003398:	1800                	addi	s0,sp,48
    8000339a:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000339c:	47ad                	li	a5,11
    8000339e:	02b7e863          	bltu	a5,a1,800033ce <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    800033a2:	02059793          	slli	a5,a1,0x20
    800033a6:	01e7d593          	srli	a1,a5,0x1e
    800033aa:	00b504b3          	add	s1,a0,a1
    800033ae:	0504a903          	lw	s2,80(s1)
    800033b2:	06091e63          	bnez	s2,8000342e <bmap+0xa4>
      addr = balloc(ip->dev);
    800033b6:	4108                	lw	a0,0(a0)
    800033b8:	00000097          	auipc	ra,0x0
    800033bc:	ea0080e7          	jalr	-352(ra) # 80003258 <balloc>
    800033c0:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800033c4:	06090563          	beqz	s2,8000342e <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    800033c8:	0524a823          	sw	s2,80(s1)
    800033cc:	a08d                	j	8000342e <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    800033ce:	ff45849b          	addiw	s1,a1,-12
    800033d2:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800033d6:	0ff00793          	li	a5,255
    800033da:	08e7e563          	bltu	a5,a4,80003464 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800033de:	08052903          	lw	s2,128(a0)
    800033e2:	00091d63          	bnez	s2,800033fc <bmap+0x72>
      addr = balloc(ip->dev);
    800033e6:	4108                	lw	a0,0(a0)
    800033e8:	00000097          	auipc	ra,0x0
    800033ec:	e70080e7          	jalr	-400(ra) # 80003258 <balloc>
    800033f0:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800033f4:	02090d63          	beqz	s2,8000342e <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800033f8:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800033fc:	85ca                	mv	a1,s2
    800033fe:	0009a503          	lw	a0,0(s3)
    80003402:	00000097          	auipc	ra,0x0
    80003406:	b94080e7          	jalr	-1132(ra) # 80002f96 <bread>
    8000340a:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000340c:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003410:	02049713          	slli	a4,s1,0x20
    80003414:	01e75593          	srli	a1,a4,0x1e
    80003418:	00b784b3          	add	s1,a5,a1
    8000341c:	0004a903          	lw	s2,0(s1)
    80003420:	02090063          	beqz	s2,80003440 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003424:	8552                	mv	a0,s4
    80003426:	00000097          	auipc	ra,0x0
    8000342a:	ca0080e7          	jalr	-864(ra) # 800030c6 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000342e:	854a                	mv	a0,s2
    80003430:	70a2                	ld	ra,40(sp)
    80003432:	7402                	ld	s0,32(sp)
    80003434:	64e2                	ld	s1,24(sp)
    80003436:	6942                	ld	s2,16(sp)
    80003438:	69a2                	ld	s3,8(sp)
    8000343a:	6a02                	ld	s4,0(sp)
    8000343c:	6145                	addi	sp,sp,48
    8000343e:	8082                	ret
      addr = balloc(ip->dev);
    80003440:	0009a503          	lw	a0,0(s3)
    80003444:	00000097          	auipc	ra,0x0
    80003448:	e14080e7          	jalr	-492(ra) # 80003258 <balloc>
    8000344c:	0005091b          	sext.w	s2,a0
      if(addr){
    80003450:	fc090ae3          	beqz	s2,80003424 <bmap+0x9a>
        a[bn] = addr;
    80003454:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003458:	8552                	mv	a0,s4
    8000345a:	00001097          	auipc	ra,0x1
    8000345e:	ef6080e7          	jalr	-266(ra) # 80004350 <log_write>
    80003462:	b7c9                	j	80003424 <bmap+0x9a>
  panic("bmap: out of range");
    80003464:	00005517          	auipc	a0,0x5
    80003468:	24450513          	addi	a0,a0,580 # 800086a8 <syscalls+0x120>
    8000346c:	ffffd097          	auipc	ra,0xffffd
    80003470:	0d4080e7          	jalr	212(ra) # 80000540 <panic>

0000000080003474 <iget>:
{
    80003474:	7179                	addi	sp,sp,-48
    80003476:	f406                	sd	ra,40(sp)
    80003478:	f022                	sd	s0,32(sp)
    8000347a:	ec26                	sd	s1,24(sp)
    8000347c:	e84a                	sd	s2,16(sp)
    8000347e:	e44e                	sd	s3,8(sp)
    80003480:	e052                	sd	s4,0(sp)
    80003482:	1800                	addi	s0,sp,48
    80003484:	89aa                	mv	s3,a0
    80003486:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003488:	00028517          	auipc	a0,0x28
    8000348c:	01050513          	addi	a0,a0,16 # 8002b498 <itable>
    80003490:	ffffd097          	auipc	ra,0xffffd
    80003494:	746080e7          	jalr	1862(ra) # 80000bd6 <acquire>
  empty = 0;
    80003498:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000349a:	00028497          	auipc	s1,0x28
    8000349e:	01648493          	addi	s1,s1,22 # 8002b4b0 <itable+0x18>
    800034a2:	0002a697          	auipc	a3,0x2a
    800034a6:	a9e68693          	addi	a3,a3,-1378 # 8002cf40 <log>
    800034aa:	a039                	j	800034b8 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034ac:	02090b63          	beqz	s2,800034e2 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800034b0:	08848493          	addi	s1,s1,136
    800034b4:	02d48a63          	beq	s1,a3,800034e8 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800034b8:	449c                	lw	a5,8(s1)
    800034ba:	fef059e3          	blez	a5,800034ac <iget+0x38>
    800034be:	4098                	lw	a4,0(s1)
    800034c0:	ff3716e3          	bne	a4,s3,800034ac <iget+0x38>
    800034c4:	40d8                	lw	a4,4(s1)
    800034c6:	ff4713e3          	bne	a4,s4,800034ac <iget+0x38>
      ip->ref++;
    800034ca:	2785                	addiw	a5,a5,1
    800034cc:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800034ce:	00028517          	auipc	a0,0x28
    800034d2:	fca50513          	addi	a0,a0,-54 # 8002b498 <itable>
    800034d6:	ffffd097          	auipc	ra,0xffffd
    800034da:	7b4080e7          	jalr	1972(ra) # 80000c8a <release>
      return ip;
    800034de:	8926                	mv	s2,s1
    800034e0:	a03d                	j	8000350e <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034e2:	f7f9                	bnez	a5,800034b0 <iget+0x3c>
    800034e4:	8926                	mv	s2,s1
    800034e6:	b7e9                	j	800034b0 <iget+0x3c>
  if(empty == 0)
    800034e8:	02090c63          	beqz	s2,80003520 <iget+0xac>
  ip->dev = dev;
    800034ec:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800034f0:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800034f4:	4785                	li	a5,1
    800034f6:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800034fa:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800034fe:	00028517          	auipc	a0,0x28
    80003502:	f9a50513          	addi	a0,a0,-102 # 8002b498 <itable>
    80003506:	ffffd097          	auipc	ra,0xffffd
    8000350a:	784080e7          	jalr	1924(ra) # 80000c8a <release>
}
    8000350e:	854a                	mv	a0,s2
    80003510:	70a2                	ld	ra,40(sp)
    80003512:	7402                	ld	s0,32(sp)
    80003514:	64e2                	ld	s1,24(sp)
    80003516:	6942                	ld	s2,16(sp)
    80003518:	69a2                	ld	s3,8(sp)
    8000351a:	6a02                	ld	s4,0(sp)
    8000351c:	6145                	addi	sp,sp,48
    8000351e:	8082                	ret
    panic("iget: no inodes");
    80003520:	00005517          	auipc	a0,0x5
    80003524:	1a050513          	addi	a0,a0,416 # 800086c0 <syscalls+0x138>
    80003528:	ffffd097          	auipc	ra,0xffffd
    8000352c:	018080e7          	jalr	24(ra) # 80000540 <panic>

0000000080003530 <fsinit>:
fsinit(int dev) {
    80003530:	7179                	addi	sp,sp,-48
    80003532:	f406                	sd	ra,40(sp)
    80003534:	f022                	sd	s0,32(sp)
    80003536:	ec26                	sd	s1,24(sp)
    80003538:	e84a                	sd	s2,16(sp)
    8000353a:	e44e                	sd	s3,8(sp)
    8000353c:	1800                	addi	s0,sp,48
    8000353e:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003540:	4585                	li	a1,1
    80003542:	00000097          	auipc	ra,0x0
    80003546:	a54080e7          	jalr	-1452(ra) # 80002f96 <bread>
    8000354a:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000354c:	00028997          	auipc	s3,0x28
    80003550:	f2c98993          	addi	s3,s3,-212 # 8002b478 <sb>
    80003554:	02000613          	li	a2,32
    80003558:	05850593          	addi	a1,a0,88
    8000355c:	854e                	mv	a0,s3
    8000355e:	ffffd097          	auipc	ra,0xffffd
    80003562:	7d0080e7          	jalr	2000(ra) # 80000d2e <memmove>
  brelse(bp);
    80003566:	8526                	mv	a0,s1
    80003568:	00000097          	auipc	ra,0x0
    8000356c:	b5e080e7          	jalr	-1186(ra) # 800030c6 <brelse>
  if(sb.magic != FSMAGIC)
    80003570:	0009a703          	lw	a4,0(s3)
    80003574:	102037b7          	lui	a5,0x10203
    80003578:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000357c:	02f71263          	bne	a4,a5,800035a0 <fsinit+0x70>
  initlog(dev, &sb);
    80003580:	00028597          	auipc	a1,0x28
    80003584:	ef858593          	addi	a1,a1,-264 # 8002b478 <sb>
    80003588:	854a                	mv	a0,s2
    8000358a:	00001097          	auipc	ra,0x1
    8000358e:	b4a080e7          	jalr	-1206(ra) # 800040d4 <initlog>
}
    80003592:	70a2                	ld	ra,40(sp)
    80003594:	7402                	ld	s0,32(sp)
    80003596:	64e2                	ld	s1,24(sp)
    80003598:	6942                	ld	s2,16(sp)
    8000359a:	69a2                	ld	s3,8(sp)
    8000359c:	6145                	addi	sp,sp,48
    8000359e:	8082                	ret
    panic("invalid file system");
    800035a0:	00005517          	auipc	a0,0x5
    800035a4:	13050513          	addi	a0,a0,304 # 800086d0 <syscalls+0x148>
    800035a8:	ffffd097          	auipc	ra,0xffffd
    800035ac:	f98080e7          	jalr	-104(ra) # 80000540 <panic>

00000000800035b0 <iinit>:
{
    800035b0:	7179                	addi	sp,sp,-48
    800035b2:	f406                	sd	ra,40(sp)
    800035b4:	f022                	sd	s0,32(sp)
    800035b6:	ec26                	sd	s1,24(sp)
    800035b8:	e84a                	sd	s2,16(sp)
    800035ba:	e44e                	sd	s3,8(sp)
    800035bc:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800035be:	00005597          	auipc	a1,0x5
    800035c2:	12a58593          	addi	a1,a1,298 # 800086e8 <syscalls+0x160>
    800035c6:	00028517          	auipc	a0,0x28
    800035ca:	ed250513          	addi	a0,a0,-302 # 8002b498 <itable>
    800035ce:	ffffd097          	auipc	ra,0xffffd
    800035d2:	578080e7          	jalr	1400(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    800035d6:	00028497          	auipc	s1,0x28
    800035da:	eea48493          	addi	s1,s1,-278 # 8002b4c0 <itable+0x28>
    800035de:	0002a997          	auipc	s3,0x2a
    800035e2:	97298993          	addi	s3,s3,-1678 # 8002cf50 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800035e6:	00005917          	auipc	s2,0x5
    800035ea:	10a90913          	addi	s2,s2,266 # 800086f0 <syscalls+0x168>
    800035ee:	85ca                	mv	a1,s2
    800035f0:	8526                	mv	a0,s1
    800035f2:	00001097          	auipc	ra,0x1
    800035f6:	e42080e7          	jalr	-446(ra) # 80004434 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800035fa:	08848493          	addi	s1,s1,136
    800035fe:	ff3498e3          	bne	s1,s3,800035ee <iinit+0x3e>
}
    80003602:	70a2                	ld	ra,40(sp)
    80003604:	7402                	ld	s0,32(sp)
    80003606:	64e2                	ld	s1,24(sp)
    80003608:	6942                	ld	s2,16(sp)
    8000360a:	69a2                	ld	s3,8(sp)
    8000360c:	6145                	addi	sp,sp,48
    8000360e:	8082                	ret

0000000080003610 <ialloc>:
{
    80003610:	715d                	addi	sp,sp,-80
    80003612:	e486                	sd	ra,72(sp)
    80003614:	e0a2                	sd	s0,64(sp)
    80003616:	fc26                	sd	s1,56(sp)
    80003618:	f84a                	sd	s2,48(sp)
    8000361a:	f44e                	sd	s3,40(sp)
    8000361c:	f052                	sd	s4,32(sp)
    8000361e:	ec56                	sd	s5,24(sp)
    80003620:	e85a                	sd	s6,16(sp)
    80003622:	e45e                	sd	s7,8(sp)
    80003624:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003626:	00028717          	auipc	a4,0x28
    8000362a:	e5e72703          	lw	a4,-418(a4) # 8002b484 <sb+0xc>
    8000362e:	4785                	li	a5,1
    80003630:	04e7fa63          	bgeu	a5,a4,80003684 <ialloc+0x74>
    80003634:	8aaa                	mv	s5,a0
    80003636:	8bae                	mv	s7,a1
    80003638:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000363a:	00028a17          	auipc	s4,0x28
    8000363e:	e3ea0a13          	addi	s4,s4,-450 # 8002b478 <sb>
    80003642:	00048b1b          	sext.w	s6,s1
    80003646:	0044d593          	srli	a1,s1,0x4
    8000364a:	018a2783          	lw	a5,24(s4)
    8000364e:	9dbd                	addw	a1,a1,a5
    80003650:	8556                	mv	a0,s5
    80003652:	00000097          	auipc	ra,0x0
    80003656:	944080e7          	jalr	-1724(ra) # 80002f96 <bread>
    8000365a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000365c:	05850993          	addi	s3,a0,88
    80003660:	00f4f793          	andi	a5,s1,15
    80003664:	079a                	slli	a5,a5,0x6
    80003666:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003668:	00099783          	lh	a5,0(s3)
    8000366c:	c3a1                	beqz	a5,800036ac <ialloc+0x9c>
    brelse(bp);
    8000366e:	00000097          	auipc	ra,0x0
    80003672:	a58080e7          	jalr	-1448(ra) # 800030c6 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003676:	0485                	addi	s1,s1,1
    80003678:	00ca2703          	lw	a4,12(s4)
    8000367c:	0004879b          	sext.w	a5,s1
    80003680:	fce7e1e3          	bltu	a5,a4,80003642 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003684:	00005517          	auipc	a0,0x5
    80003688:	07450513          	addi	a0,a0,116 # 800086f8 <syscalls+0x170>
    8000368c:	ffffd097          	auipc	ra,0xffffd
    80003690:	efe080e7          	jalr	-258(ra) # 8000058a <printf>
  return 0;
    80003694:	4501                	li	a0,0
}
    80003696:	60a6                	ld	ra,72(sp)
    80003698:	6406                	ld	s0,64(sp)
    8000369a:	74e2                	ld	s1,56(sp)
    8000369c:	7942                	ld	s2,48(sp)
    8000369e:	79a2                	ld	s3,40(sp)
    800036a0:	7a02                	ld	s4,32(sp)
    800036a2:	6ae2                	ld	s5,24(sp)
    800036a4:	6b42                	ld	s6,16(sp)
    800036a6:	6ba2                	ld	s7,8(sp)
    800036a8:	6161                	addi	sp,sp,80
    800036aa:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800036ac:	04000613          	li	a2,64
    800036b0:	4581                	li	a1,0
    800036b2:	854e                	mv	a0,s3
    800036b4:	ffffd097          	auipc	ra,0xffffd
    800036b8:	61e080e7          	jalr	1566(ra) # 80000cd2 <memset>
      dip->type = type;
    800036bc:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800036c0:	854a                	mv	a0,s2
    800036c2:	00001097          	auipc	ra,0x1
    800036c6:	c8e080e7          	jalr	-882(ra) # 80004350 <log_write>
      brelse(bp);
    800036ca:	854a                	mv	a0,s2
    800036cc:	00000097          	auipc	ra,0x0
    800036d0:	9fa080e7          	jalr	-1542(ra) # 800030c6 <brelse>
      return iget(dev, inum);
    800036d4:	85da                	mv	a1,s6
    800036d6:	8556                	mv	a0,s5
    800036d8:	00000097          	auipc	ra,0x0
    800036dc:	d9c080e7          	jalr	-612(ra) # 80003474 <iget>
    800036e0:	bf5d                	j	80003696 <ialloc+0x86>

00000000800036e2 <iupdate>:
{
    800036e2:	1101                	addi	sp,sp,-32
    800036e4:	ec06                	sd	ra,24(sp)
    800036e6:	e822                	sd	s0,16(sp)
    800036e8:	e426                	sd	s1,8(sp)
    800036ea:	e04a                	sd	s2,0(sp)
    800036ec:	1000                	addi	s0,sp,32
    800036ee:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036f0:	415c                	lw	a5,4(a0)
    800036f2:	0047d79b          	srliw	a5,a5,0x4
    800036f6:	00028597          	auipc	a1,0x28
    800036fa:	d9a5a583          	lw	a1,-614(a1) # 8002b490 <sb+0x18>
    800036fe:	9dbd                	addw	a1,a1,a5
    80003700:	4108                	lw	a0,0(a0)
    80003702:	00000097          	auipc	ra,0x0
    80003706:	894080e7          	jalr	-1900(ra) # 80002f96 <bread>
    8000370a:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000370c:	05850793          	addi	a5,a0,88
    80003710:	40d8                	lw	a4,4(s1)
    80003712:	8b3d                	andi	a4,a4,15
    80003714:	071a                	slli	a4,a4,0x6
    80003716:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003718:	04449703          	lh	a4,68(s1)
    8000371c:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003720:	04649703          	lh	a4,70(s1)
    80003724:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003728:	04849703          	lh	a4,72(s1)
    8000372c:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003730:	04a49703          	lh	a4,74(s1)
    80003734:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003738:	44f8                	lw	a4,76(s1)
    8000373a:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000373c:	03400613          	li	a2,52
    80003740:	05048593          	addi	a1,s1,80
    80003744:	00c78513          	addi	a0,a5,12
    80003748:	ffffd097          	auipc	ra,0xffffd
    8000374c:	5e6080e7          	jalr	1510(ra) # 80000d2e <memmove>
  log_write(bp);
    80003750:	854a                	mv	a0,s2
    80003752:	00001097          	auipc	ra,0x1
    80003756:	bfe080e7          	jalr	-1026(ra) # 80004350 <log_write>
  brelse(bp);
    8000375a:	854a                	mv	a0,s2
    8000375c:	00000097          	auipc	ra,0x0
    80003760:	96a080e7          	jalr	-1686(ra) # 800030c6 <brelse>
}
    80003764:	60e2                	ld	ra,24(sp)
    80003766:	6442                	ld	s0,16(sp)
    80003768:	64a2                	ld	s1,8(sp)
    8000376a:	6902                	ld	s2,0(sp)
    8000376c:	6105                	addi	sp,sp,32
    8000376e:	8082                	ret

0000000080003770 <idup>:
{
    80003770:	1101                	addi	sp,sp,-32
    80003772:	ec06                	sd	ra,24(sp)
    80003774:	e822                	sd	s0,16(sp)
    80003776:	e426                	sd	s1,8(sp)
    80003778:	1000                	addi	s0,sp,32
    8000377a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000377c:	00028517          	auipc	a0,0x28
    80003780:	d1c50513          	addi	a0,a0,-740 # 8002b498 <itable>
    80003784:	ffffd097          	auipc	ra,0xffffd
    80003788:	452080e7          	jalr	1106(ra) # 80000bd6 <acquire>
  ip->ref++;
    8000378c:	449c                	lw	a5,8(s1)
    8000378e:	2785                	addiw	a5,a5,1
    80003790:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003792:	00028517          	auipc	a0,0x28
    80003796:	d0650513          	addi	a0,a0,-762 # 8002b498 <itable>
    8000379a:	ffffd097          	auipc	ra,0xffffd
    8000379e:	4f0080e7          	jalr	1264(ra) # 80000c8a <release>
}
    800037a2:	8526                	mv	a0,s1
    800037a4:	60e2                	ld	ra,24(sp)
    800037a6:	6442                	ld	s0,16(sp)
    800037a8:	64a2                	ld	s1,8(sp)
    800037aa:	6105                	addi	sp,sp,32
    800037ac:	8082                	ret

00000000800037ae <ilock>:
{
    800037ae:	1101                	addi	sp,sp,-32
    800037b0:	ec06                	sd	ra,24(sp)
    800037b2:	e822                	sd	s0,16(sp)
    800037b4:	e426                	sd	s1,8(sp)
    800037b6:	e04a                	sd	s2,0(sp)
    800037b8:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800037ba:	c115                	beqz	a0,800037de <ilock+0x30>
    800037bc:	84aa                	mv	s1,a0
    800037be:	451c                	lw	a5,8(a0)
    800037c0:	00f05f63          	blez	a5,800037de <ilock+0x30>
  acquiresleep(&ip->lock);
    800037c4:	0541                	addi	a0,a0,16
    800037c6:	00001097          	auipc	ra,0x1
    800037ca:	ca8080e7          	jalr	-856(ra) # 8000446e <acquiresleep>
  if(ip->valid == 0){
    800037ce:	40bc                	lw	a5,64(s1)
    800037d0:	cf99                	beqz	a5,800037ee <ilock+0x40>
}
    800037d2:	60e2                	ld	ra,24(sp)
    800037d4:	6442                	ld	s0,16(sp)
    800037d6:	64a2                	ld	s1,8(sp)
    800037d8:	6902                	ld	s2,0(sp)
    800037da:	6105                	addi	sp,sp,32
    800037dc:	8082                	ret
    panic("ilock");
    800037de:	00005517          	auipc	a0,0x5
    800037e2:	f3250513          	addi	a0,a0,-206 # 80008710 <syscalls+0x188>
    800037e6:	ffffd097          	auipc	ra,0xffffd
    800037ea:	d5a080e7          	jalr	-678(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037ee:	40dc                	lw	a5,4(s1)
    800037f0:	0047d79b          	srliw	a5,a5,0x4
    800037f4:	00028597          	auipc	a1,0x28
    800037f8:	c9c5a583          	lw	a1,-868(a1) # 8002b490 <sb+0x18>
    800037fc:	9dbd                	addw	a1,a1,a5
    800037fe:	4088                	lw	a0,0(s1)
    80003800:	fffff097          	auipc	ra,0xfffff
    80003804:	796080e7          	jalr	1942(ra) # 80002f96 <bread>
    80003808:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000380a:	05850593          	addi	a1,a0,88
    8000380e:	40dc                	lw	a5,4(s1)
    80003810:	8bbd                	andi	a5,a5,15
    80003812:	079a                	slli	a5,a5,0x6
    80003814:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003816:	00059783          	lh	a5,0(a1)
    8000381a:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000381e:	00259783          	lh	a5,2(a1)
    80003822:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003826:	00459783          	lh	a5,4(a1)
    8000382a:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000382e:	00659783          	lh	a5,6(a1)
    80003832:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003836:	459c                	lw	a5,8(a1)
    80003838:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000383a:	03400613          	li	a2,52
    8000383e:	05b1                	addi	a1,a1,12
    80003840:	05048513          	addi	a0,s1,80
    80003844:	ffffd097          	auipc	ra,0xffffd
    80003848:	4ea080e7          	jalr	1258(ra) # 80000d2e <memmove>
    brelse(bp);
    8000384c:	854a                	mv	a0,s2
    8000384e:	00000097          	auipc	ra,0x0
    80003852:	878080e7          	jalr	-1928(ra) # 800030c6 <brelse>
    ip->valid = 1;
    80003856:	4785                	li	a5,1
    80003858:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000385a:	04449783          	lh	a5,68(s1)
    8000385e:	fbb5                	bnez	a5,800037d2 <ilock+0x24>
      panic("ilock: no type");
    80003860:	00005517          	auipc	a0,0x5
    80003864:	eb850513          	addi	a0,a0,-328 # 80008718 <syscalls+0x190>
    80003868:	ffffd097          	auipc	ra,0xffffd
    8000386c:	cd8080e7          	jalr	-808(ra) # 80000540 <panic>

0000000080003870 <iunlock>:
{
    80003870:	1101                	addi	sp,sp,-32
    80003872:	ec06                	sd	ra,24(sp)
    80003874:	e822                	sd	s0,16(sp)
    80003876:	e426                	sd	s1,8(sp)
    80003878:	e04a                	sd	s2,0(sp)
    8000387a:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000387c:	c905                	beqz	a0,800038ac <iunlock+0x3c>
    8000387e:	84aa                	mv	s1,a0
    80003880:	01050913          	addi	s2,a0,16
    80003884:	854a                	mv	a0,s2
    80003886:	00001097          	auipc	ra,0x1
    8000388a:	c82080e7          	jalr	-894(ra) # 80004508 <holdingsleep>
    8000388e:	cd19                	beqz	a0,800038ac <iunlock+0x3c>
    80003890:	449c                	lw	a5,8(s1)
    80003892:	00f05d63          	blez	a5,800038ac <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003896:	854a                	mv	a0,s2
    80003898:	00001097          	auipc	ra,0x1
    8000389c:	c2c080e7          	jalr	-980(ra) # 800044c4 <releasesleep>
}
    800038a0:	60e2                	ld	ra,24(sp)
    800038a2:	6442                	ld	s0,16(sp)
    800038a4:	64a2                	ld	s1,8(sp)
    800038a6:	6902                	ld	s2,0(sp)
    800038a8:	6105                	addi	sp,sp,32
    800038aa:	8082                	ret
    panic("iunlock");
    800038ac:	00005517          	auipc	a0,0x5
    800038b0:	e7c50513          	addi	a0,a0,-388 # 80008728 <syscalls+0x1a0>
    800038b4:	ffffd097          	auipc	ra,0xffffd
    800038b8:	c8c080e7          	jalr	-884(ra) # 80000540 <panic>

00000000800038bc <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800038bc:	7179                	addi	sp,sp,-48
    800038be:	f406                	sd	ra,40(sp)
    800038c0:	f022                	sd	s0,32(sp)
    800038c2:	ec26                	sd	s1,24(sp)
    800038c4:	e84a                	sd	s2,16(sp)
    800038c6:	e44e                	sd	s3,8(sp)
    800038c8:	e052                	sd	s4,0(sp)
    800038ca:	1800                	addi	s0,sp,48
    800038cc:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800038ce:	05050493          	addi	s1,a0,80
    800038d2:	08050913          	addi	s2,a0,128
    800038d6:	a021                	j	800038de <itrunc+0x22>
    800038d8:	0491                	addi	s1,s1,4
    800038da:	01248d63          	beq	s1,s2,800038f4 <itrunc+0x38>
    if(ip->addrs[i]){
    800038de:	408c                	lw	a1,0(s1)
    800038e0:	dde5                	beqz	a1,800038d8 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800038e2:	0009a503          	lw	a0,0(s3)
    800038e6:	00000097          	auipc	ra,0x0
    800038ea:	8f6080e7          	jalr	-1802(ra) # 800031dc <bfree>
      ip->addrs[i] = 0;
    800038ee:	0004a023          	sw	zero,0(s1)
    800038f2:	b7dd                	j	800038d8 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800038f4:	0809a583          	lw	a1,128(s3)
    800038f8:	e185                	bnez	a1,80003918 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800038fa:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800038fe:	854e                	mv	a0,s3
    80003900:	00000097          	auipc	ra,0x0
    80003904:	de2080e7          	jalr	-542(ra) # 800036e2 <iupdate>
}
    80003908:	70a2                	ld	ra,40(sp)
    8000390a:	7402                	ld	s0,32(sp)
    8000390c:	64e2                	ld	s1,24(sp)
    8000390e:	6942                	ld	s2,16(sp)
    80003910:	69a2                	ld	s3,8(sp)
    80003912:	6a02                	ld	s4,0(sp)
    80003914:	6145                	addi	sp,sp,48
    80003916:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003918:	0009a503          	lw	a0,0(s3)
    8000391c:	fffff097          	auipc	ra,0xfffff
    80003920:	67a080e7          	jalr	1658(ra) # 80002f96 <bread>
    80003924:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003926:	05850493          	addi	s1,a0,88
    8000392a:	45850913          	addi	s2,a0,1112
    8000392e:	a021                	j	80003936 <itrunc+0x7a>
    80003930:	0491                	addi	s1,s1,4
    80003932:	01248b63          	beq	s1,s2,80003948 <itrunc+0x8c>
      if(a[j])
    80003936:	408c                	lw	a1,0(s1)
    80003938:	dde5                	beqz	a1,80003930 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    8000393a:	0009a503          	lw	a0,0(s3)
    8000393e:	00000097          	auipc	ra,0x0
    80003942:	89e080e7          	jalr	-1890(ra) # 800031dc <bfree>
    80003946:	b7ed                	j	80003930 <itrunc+0x74>
    brelse(bp);
    80003948:	8552                	mv	a0,s4
    8000394a:	fffff097          	auipc	ra,0xfffff
    8000394e:	77c080e7          	jalr	1916(ra) # 800030c6 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003952:	0809a583          	lw	a1,128(s3)
    80003956:	0009a503          	lw	a0,0(s3)
    8000395a:	00000097          	auipc	ra,0x0
    8000395e:	882080e7          	jalr	-1918(ra) # 800031dc <bfree>
    ip->addrs[NDIRECT] = 0;
    80003962:	0809a023          	sw	zero,128(s3)
    80003966:	bf51                	j	800038fa <itrunc+0x3e>

0000000080003968 <iput>:
{
    80003968:	1101                	addi	sp,sp,-32
    8000396a:	ec06                	sd	ra,24(sp)
    8000396c:	e822                	sd	s0,16(sp)
    8000396e:	e426                	sd	s1,8(sp)
    80003970:	e04a                	sd	s2,0(sp)
    80003972:	1000                	addi	s0,sp,32
    80003974:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003976:	00028517          	auipc	a0,0x28
    8000397a:	b2250513          	addi	a0,a0,-1246 # 8002b498 <itable>
    8000397e:	ffffd097          	auipc	ra,0xffffd
    80003982:	258080e7          	jalr	600(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003986:	4498                	lw	a4,8(s1)
    80003988:	4785                	li	a5,1
    8000398a:	02f70363          	beq	a4,a5,800039b0 <iput+0x48>
  ip->ref--;
    8000398e:	449c                	lw	a5,8(s1)
    80003990:	37fd                	addiw	a5,a5,-1
    80003992:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003994:	00028517          	auipc	a0,0x28
    80003998:	b0450513          	addi	a0,a0,-1276 # 8002b498 <itable>
    8000399c:	ffffd097          	auipc	ra,0xffffd
    800039a0:	2ee080e7          	jalr	750(ra) # 80000c8a <release>
}
    800039a4:	60e2                	ld	ra,24(sp)
    800039a6:	6442                	ld	s0,16(sp)
    800039a8:	64a2                	ld	s1,8(sp)
    800039aa:	6902                	ld	s2,0(sp)
    800039ac:	6105                	addi	sp,sp,32
    800039ae:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039b0:	40bc                	lw	a5,64(s1)
    800039b2:	dff1                	beqz	a5,8000398e <iput+0x26>
    800039b4:	04a49783          	lh	a5,74(s1)
    800039b8:	fbf9                	bnez	a5,8000398e <iput+0x26>
    acquiresleep(&ip->lock);
    800039ba:	01048913          	addi	s2,s1,16
    800039be:	854a                	mv	a0,s2
    800039c0:	00001097          	auipc	ra,0x1
    800039c4:	aae080e7          	jalr	-1362(ra) # 8000446e <acquiresleep>
    release(&itable.lock);
    800039c8:	00028517          	auipc	a0,0x28
    800039cc:	ad050513          	addi	a0,a0,-1328 # 8002b498 <itable>
    800039d0:	ffffd097          	auipc	ra,0xffffd
    800039d4:	2ba080e7          	jalr	698(ra) # 80000c8a <release>
    itrunc(ip);
    800039d8:	8526                	mv	a0,s1
    800039da:	00000097          	auipc	ra,0x0
    800039de:	ee2080e7          	jalr	-286(ra) # 800038bc <itrunc>
    ip->type = 0;
    800039e2:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800039e6:	8526                	mv	a0,s1
    800039e8:	00000097          	auipc	ra,0x0
    800039ec:	cfa080e7          	jalr	-774(ra) # 800036e2 <iupdate>
    ip->valid = 0;
    800039f0:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800039f4:	854a                	mv	a0,s2
    800039f6:	00001097          	auipc	ra,0x1
    800039fa:	ace080e7          	jalr	-1330(ra) # 800044c4 <releasesleep>
    acquire(&itable.lock);
    800039fe:	00028517          	auipc	a0,0x28
    80003a02:	a9a50513          	addi	a0,a0,-1382 # 8002b498 <itable>
    80003a06:	ffffd097          	auipc	ra,0xffffd
    80003a0a:	1d0080e7          	jalr	464(ra) # 80000bd6 <acquire>
    80003a0e:	b741                	j	8000398e <iput+0x26>

0000000080003a10 <iunlockput>:
{
    80003a10:	1101                	addi	sp,sp,-32
    80003a12:	ec06                	sd	ra,24(sp)
    80003a14:	e822                	sd	s0,16(sp)
    80003a16:	e426                	sd	s1,8(sp)
    80003a18:	1000                	addi	s0,sp,32
    80003a1a:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a1c:	00000097          	auipc	ra,0x0
    80003a20:	e54080e7          	jalr	-428(ra) # 80003870 <iunlock>
  iput(ip);
    80003a24:	8526                	mv	a0,s1
    80003a26:	00000097          	auipc	ra,0x0
    80003a2a:	f42080e7          	jalr	-190(ra) # 80003968 <iput>
}
    80003a2e:	60e2                	ld	ra,24(sp)
    80003a30:	6442                	ld	s0,16(sp)
    80003a32:	64a2                	ld	s1,8(sp)
    80003a34:	6105                	addi	sp,sp,32
    80003a36:	8082                	ret

0000000080003a38 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a38:	1141                	addi	sp,sp,-16
    80003a3a:	e422                	sd	s0,8(sp)
    80003a3c:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a3e:	411c                	lw	a5,0(a0)
    80003a40:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a42:	415c                	lw	a5,4(a0)
    80003a44:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a46:	04451783          	lh	a5,68(a0)
    80003a4a:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a4e:	04a51783          	lh	a5,74(a0)
    80003a52:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a56:	04c56783          	lwu	a5,76(a0)
    80003a5a:	e99c                	sd	a5,16(a1)
}
    80003a5c:	6422                	ld	s0,8(sp)
    80003a5e:	0141                	addi	sp,sp,16
    80003a60:	8082                	ret

0000000080003a62 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a62:	457c                	lw	a5,76(a0)
    80003a64:	0ed7e963          	bltu	a5,a3,80003b56 <readi+0xf4>
{
    80003a68:	7159                	addi	sp,sp,-112
    80003a6a:	f486                	sd	ra,104(sp)
    80003a6c:	f0a2                	sd	s0,96(sp)
    80003a6e:	eca6                	sd	s1,88(sp)
    80003a70:	e8ca                	sd	s2,80(sp)
    80003a72:	e4ce                	sd	s3,72(sp)
    80003a74:	e0d2                	sd	s4,64(sp)
    80003a76:	fc56                	sd	s5,56(sp)
    80003a78:	f85a                	sd	s6,48(sp)
    80003a7a:	f45e                	sd	s7,40(sp)
    80003a7c:	f062                	sd	s8,32(sp)
    80003a7e:	ec66                	sd	s9,24(sp)
    80003a80:	e86a                	sd	s10,16(sp)
    80003a82:	e46e                	sd	s11,8(sp)
    80003a84:	1880                	addi	s0,sp,112
    80003a86:	8b2a                	mv	s6,a0
    80003a88:	8bae                	mv	s7,a1
    80003a8a:	8a32                	mv	s4,a2
    80003a8c:	84b6                	mv	s1,a3
    80003a8e:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003a90:	9f35                	addw	a4,a4,a3
    return 0;
    80003a92:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a94:	0ad76063          	bltu	a4,a3,80003b34 <readi+0xd2>
  if(off + n > ip->size)
    80003a98:	00e7f463          	bgeu	a5,a4,80003aa0 <readi+0x3e>
    n = ip->size - off;
    80003a9c:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003aa0:	0a0a8963          	beqz	s5,80003b52 <readi+0xf0>
    80003aa4:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003aa6:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003aaa:	5c7d                	li	s8,-1
    80003aac:	a82d                	j	80003ae6 <readi+0x84>
    80003aae:	020d1d93          	slli	s11,s10,0x20
    80003ab2:	020ddd93          	srli	s11,s11,0x20
    80003ab6:	05890613          	addi	a2,s2,88
    80003aba:	86ee                	mv	a3,s11
    80003abc:	963a                	add	a2,a2,a4
    80003abe:	85d2                	mv	a1,s4
    80003ac0:	855e                	mv	a0,s7
    80003ac2:	fffff097          	auipc	ra,0xfffff
    80003ac6:	9d4080e7          	jalr	-1580(ra) # 80002496 <either_copyout>
    80003aca:	05850d63          	beq	a0,s8,80003b24 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003ace:	854a                	mv	a0,s2
    80003ad0:	fffff097          	auipc	ra,0xfffff
    80003ad4:	5f6080e7          	jalr	1526(ra) # 800030c6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ad8:	013d09bb          	addw	s3,s10,s3
    80003adc:	009d04bb          	addw	s1,s10,s1
    80003ae0:	9a6e                	add	s4,s4,s11
    80003ae2:	0559f763          	bgeu	s3,s5,80003b30 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003ae6:	00a4d59b          	srliw	a1,s1,0xa
    80003aea:	855a                	mv	a0,s6
    80003aec:	00000097          	auipc	ra,0x0
    80003af0:	89e080e7          	jalr	-1890(ra) # 8000338a <bmap>
    80003af4:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003af8:	cd85                	beqz	a1,80003b30 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003afa:	000b2503          	lw	a0,0(s6)
    80003afe:	fffff097          	auipc	ra,0xfffff
    80003b02:	498080e7          	jalr	1176(ra) # 80002f96 <bread>
    80003b06:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b08:	3ff4f713          	andi	a4,s1,1023
    80003b0c:	40ec87bb          	subw	a5,s9,a4
    80003b10:	413a86bb          	subw	a3,s5,s3
    80003b14:	8d3e                	mv	s10,a5
    80003b16:	2781                	sext.w	a5,a5
    80003b18:	0006861b          	sext.w	a2,a3
    80003b1c:	f8f679e3          	bgeu	a2,a5,80003aae <readi+0x4c>
    80003b20:	8d36                	mv	s10,a3
    80003b22:	b771                	j	80003aae <readi+0x4c>
      brelse(bp);
    80003b24:	854a                	mv	a0,s2
    80003b26:	fffff097          	auipc	ra,0xfffff
    80003b2a:	5a0080e7          	jalr	1440(ra) # 800030c6 <brelse>
      tot = -1;
    80003b2e:	59fd                	li	s3,-1
  }
  return tot;
    80003b30:	0009851b          	sext.w	a0,s3
}
    80003b34:	70a6                	ld	ra,104(sp)
    80003b36:	7406                	ld	s0,96(sp)
    80003b38:	64e6                	ld	s1,88(sp)
    80003b3a:	6946                	ld	s2,80(sp)
    80003b3c:	69a6                	ld	s3,72(sp)
    80003b3e:	6a06                	ld	s4,64(sp)
    80003b40:	7ae2                	ld	s5,56(sp)
    80003b42:	7b42                	ld	s6,48(sp)
    80003b44:	7ba2                	ld	s7,40(sp)
    80003b46:	7c02                	ld	s8,32(sp)
    80003b48:	6ce2                	ld	s9,24(sp)
    80003b4a:	6d42                	ld	s10,16(sp)
    80003b4c:	6da2                	ld	s11,8(sp)
    80003b4e:	6165                	addi	sp,sp,112
    80003b50:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b52:	89d6                	mv	s3,s5
    80003b54:	bff1                	j	80003b30 <readi+0xce>
    return 0;
    80003b56:	4501                	li	a0,0
}
    80003b58:	8082                	ret

0000000080003b5a <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b5a:	457c                	lw	a5,76(a0)
    80003b5c:	10d7e863          	bltu	a5,a3,80003c6c <writei+0x112>
{
    80003b60:	7159                	addi	sp,sp,-112
    80003b62:	f486                	sd	ra,104(sp)
    80003b64:	f0a2                	sd	s0,96(sp)
    80003b66:	eca6                	sd	s1,88(sp)
    80003b68:	e8ca                	sd	s2,80(sp)
    80003b6a:	e4ce                	sd	s3,72(sp)
    80003b6c:	e0d2                	sd	s4,64(sp)
    80003b6e:	fc56                	sd	s5,56(sp)
    80003b70:	f85a                	sd	s6,48(sp)
    80003b72:	f45e                	sd	s7,40(sp)
    80003b74:	f062                	sd	s8,32(sp)
    80003b76:	ec66                	sd	s9,24(sp)
    80003b78:	e86a                	sd	s10,16(sp)
    80003b7a:	e46e                	sd	s11,8(sp)
    80003b7c:	1880                	addi	s0,sp,112
    80003b7e:	8aaa                	mv	s5,a0
    80003b80:	8bae                	mv	s7,a1
    80003b82:	8a32                	mv	s4,a2
    80003b84:	8936                	mv	s2,a3
    80003b86:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b88:	00e687bb          	addw	a5,a3,a4
    80003b8c:	0ed7e263          	bltu	a5,a3,80003c70 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b90:	00043737          	lui	a4,0x43
    80003b94:	0ef76063          	bltu	a4,a5,80003c74 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b98:	0c0b0863          	beqz	s6,80003c68 <writei+0x10e>
    80003b9c:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b9e:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003ba2:	5c7d                	li	s8,-1
    80003ba4:	a091                	j	80003be8 <writei+0x8e>
    80003ba6:	020d1d93          	slli	s11,s10,0x20
    80003baa:	020ddd93          	srli	s11,s11,0x20
    80003bae:	05848513          	addi	a0,s1,88
    80003bb2:	86ee                	mv	a3,s11
    80003bb4:	8652                	mv	a2,s4
    80003bb6:	85de                	mv	a1,s7
    80003bb8:	953a                	add	a0,a0,a4
    80003bba:	fffff097          	auipc	ra,0xfffff
    80003bbe:	932080e7          	jalr	-1742(ra) # 800024ec <either_copyin>
    80003bc2:	07850263          	beq	a0,s8,80003c26 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003bc6:	8526                	mv	a0,s1
    80003bc8:	00000097          	auipc	ra,0x0
    80003bcc:	788080e7          	jalr	1928(ra) # 80004350 <log_write>
    brelse(bp);
    80003bd0:	8526                	mv	a0,s1
    80003bd2:	fffff097          	auipc	ra,0xfffff
    80003bd6:	4f4080e7          	jalr	1268(ra) # 800030c6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bda:	013d09bb          	addw	s3,s10,s3
    80003bde:	012d093b          	addw	s2,s10,s2
    80003be2:	9a6e                	add	s4,s4,s11
    80003be4:	0569f663          	bgeu	s3,s6,80003c30 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003be8:	00a9559b          	srliw	a1,s2,0xa
    80003bec:	8556                	mv	a0,s5
    80003bee:	fffff097          	auipc	ra,0xfffff
    80003bf2:	79c080e7          	jalr	1948(ra) # 8000338a <bmap>
    80003bf6:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003bfa:	c99d                	beqz	a1,80003c30 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003bfc:	000aa503          	lw	a0,0(s5)
    80003c00:	fffff097          	auipc	ra,0xfffff
    80003c04:	396080e7          	jalr	918(ra) # 80002f96 <bread>
    80003c08:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c0a:	3ff97713          	andi	a4,s2,1023
    80003c0e:	40ec87bb          	subw	a5,s9,a4
    80003c12:	413b06bb          	subw	a3,s6,s3
    80003c16:	8d3e                	mv	s10,a5
    80003c18:	2781                	sext.w	a5,a5
    80003c1a:	0006861b          	sext.w	a2,a3
    80003c1e:	f8f674e3          	bgeu	a2,a5,80003ba6 <writei+0x4c>
    80003c22:	8d36                	mv	s10,a3
    80003c24:	b749                	j	80003ba6 <writei+0x4c>
      brelse(bp);
    80003c26:	8526                	mv	a0,s1
    80003c28:	fffff097          	auipc	ra,0xfffff
    80003c2c:	49e080e7          	jalr	1182(ra) # 800030c6 <brelse>
  }

  if(off > ip->size)
    80003c30:	04caa783          	lw	a5,76(s5)
    80003c34:	0127f463          	bgeu	a5,s2,80003c3c <writei+0xe2>
    ip->size = off;
    80003c38:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003c3c:	8556                	mv	a0,s5
    80003c3e:	00000097          	auipc	ra,0x0
    80003c42:	aa4080e7          	jalr	-1372(ra) # 800036e2 <iupdate>

  return tot;
    80003c46:	0009851b          	sext.w	a0,s3
}
    80003c4a:	70a6                	ld	ra,104(sp)
    80003c4c:	7406                	ld	s0,96(sp)
    80003c4e:	64e6                	ld	s1,88(sp)
    80003c50:	6946                	ld	s2,80(sp)
    80003c52:	69a6                	ld	s3,72(sp)
    80003c54:	6a06                	ld	s4,64(sp)
    80003c56:	7ae2                	ld	s5,56(sp)
    80003c58:	7b42                	ld	s6,48(sp)
    80003c5a:	7ba2                	ld	s7,40(sp)
    80003c5c:	7c02                	ld	s8,32(sp)
    80003c5e:	6ce2                	ld	s9,24(sp)
    80003c60:	6d42                	ld	s10,16(sp)
    80003c62:	6da2                	ld	s11,8(sp)
    80003c64:	6165                	addi	sp,sp,112
    80003c66:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c68:	89da                	mv	s3,s6
    80003c6a:	bfc9                	j	80003c3c <writei+0xe2>
    return -1;
    80003c6c:	557d                	li	a0,-1
}
    80003c6e:	8082                	ret
    return -1;
    80003c70:	557d                	li	a0,-1
    80003c72:	bfe1                	j	80003c4a <writei+0xf0>
    return -1;
    80003c74:	557d                	li	a0,-1
    80003c76:	bfd1                	j	80003c4a <writei+0xf0>

0000000080003c78 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c78:	1141                	addi	sp,sp,-16
    80003c7a:	e406                	sd	ra,8(sp)
    80003c7c:	e022                	sd	s0,0(sp)
    80003c7e:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c80:	4639                	li	a2,14
    80003c82:	ffffd097          	auipc	ra,0xffffd
    80003c86:	120080e7          	jalr	288(ra) # 80000da2 <strncmp>
}
    80003c8a:	60a2                	ld	ra,8(sp)
    80003c8c:	6402                	ld	s0,0(sp)
    80003c8e:	0141                	addi	sp,sp,16
    80003c90:	8082                	ret

0000000080003c92 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c92:	7139                	addi	sp,sp,-64
    80003c94:	fc06                	sd	ra,56(sp)
    80003c96:	f822                	sd	s0,48(sp)
    80003c98:	f426                	sd	s1,40(sp)
    80003c9a:	f04a                	sd	s2,32(sp)
    80003c9c:	ec4e                	sd	s3,24(sp)
    80003c9e:	e852                	sd	s4,16(sp)
    80003ca0:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003ca2:	04451703          	lh	a4,68(a0)
    80003ca6:	4785                	li	a5,1
    80003ca8:	00f71a63          	bne	a4,a5,80003cbc <dirlookup+0x2a>
    80003cac:	892a                	mv	s2,a0
    80003cae:	89ae                	mv	s3,a1
    80003cb0:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cb2:	457c                	lw	a5,76(a0)
    80003cb4:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003cb6:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cb8:	e79d                	bnez	a5,80003ce6 <dirlookup+0x54>
    80003cba:	a8a5                	j	80003d32 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003cbc:	00005517          	auipc	a0,0x5
    80003cc0:	a7450513          	addi	a0,a0,-1420 # 80008730 <syscalls+0x1a8>
    80003cc4:	ffffd097          	auipc	ra,0xffffd
    80003cc8:	87c080e7          	jalr	-1924(ra) # 80000540 <panic>
      panic("dirlookup read");
    80003ccc:	00005517          	auipc	a0,0x5
    80003cd0:	a7c50513          	addi	a0,a0,-1412 # 80008748 <syscalls+0x1c0>
    80003cd4:	ffffd097          	auipc	ra,0xffffd
    80003cd8:	86c080e7          	jalr	-1940(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cdc:	24c1                	addiw	s1,s1,16
    80003cde:	04c92783          	lw	a5,76(s2)
    80003ce2:	04f4f763          	bgeu	s1,a5,80003d30 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ce6:	4741                	li	a4,16
    80003ce8:	86a6                	mv	a3,s1
    80003cea:	fc040613          	addi	a2,s0,-64
    80003cee:	4581                	li	a1,0
    80003cf0:	854a                	mv	a0,s2
    80003cf2:	00000097          	auipc	ra,0x0
    80003cf6:	d70080e7          	jalr	-656(ra) # 80003a62 <readi>
    80003cfa:	47c1                	li	a5,16
    80003cfc:	fcf518e3          	bne	a0,a5,80003ccc <dirlookup+0x3a>
    if(de.inum == 0)
    80003d00:	fc045783          	lhu	a5,-64(s0)
    80003d04:	dfe1                	beqz	a5,80003cdc <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d06:	fc240593          	addi	a1,s0,-62
    80003d0a:	854e                	mv	a0,s3
    80003d0c:	00000097          	auipc	ra,0x0
    80003d10:	f6c080e7          	jalr	-148(ra) # 80003c78 <namecmp>
    80003d14:	f561                	bnez	a0,80003cdc <dirlookup+0x4a>
      if(poff)
    80003d16:	000a0463          	beqz	s4,80003d1e <dirlookup+0x8c>
        *poff = off;
    80003d1a:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003d1e:	fc045583          	lhu	a1,-64(s0)
    80003d22:	00092503          	lw	a0,0(s2)
    80003d26:	fffff097          	auipc	ra,0xfffff
    80003d2a:	74e080e7          	jalr	1870(ra) # 80003474 <iget>
    80003d2e:	a011                	j	80003d32 <dirlookup+0xa0>
  return 0;
    80003d30:	4501                	li	a0,0
}
    80003d32:	70e2                	ld	ra,56(sp)
    80003d34:	7442                	ld	s0,48(sp)
    80003d36:	74a2                	ld	s1,40(sp)
    80003d38:	7902                	ld	s2,32(sp)
    80003d3a:	69e2                	ld	s3,24(sp)
    80003d3c:	6a42                	ld	s4,16(sp)
    80003d3e:	6121                	addi	sp,sp,64
    80003d40:	8082                	ret

0000000080003d42 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d42:	711d                	addi	sp,sp,-96
    80003d44:	ec86                	sd	ra,88(sp)
    80003d46:	e8a2                	sd	s0,80(sp)
    80003d48:	e4a6                	sd	s1,72(sp)
    80003d4a:	e0ca                	sd	s2,64(sp)
    80003d4c:	fc4e                	sd	s3,56(sp)
    80003d4e:	f852                	sd	s4,48(sp)
    80003d50:	f456                	sd	s5,40(sp)
    80003d52:	f05a                	sd	s6,32(sp)
    80003d54:	ec5e                	sd	s7,24(sp)
    80003d56:	e862                	sd	s8,16(sp)
    80003d58:	e466                	sd	s9,8(sp)
    80003d5a:	e06a                	sd	s10,0(sp)
    80003d5c:	1080                	addi	s0,sp,96
    80003d5e:	84aa                	mv	s1,a0
    80003d60:	8b2e                	mv	s6,a1
    80003d62:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d64:	00054703          	lbu	a4,0(a0)
    80003d68:	02f00793          	li	a5,47
    80003d6c:	02f70363          	beq	a4,a5,80003d92 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d70:	ffffe097          	auipc	ra,0xffffe
    80003d74:	c3c080e7          	jalr	-964(ra) # 800019ac <myproc>
    80003d78:	15053503          	ld	a0,336(a0)
    80003d7c:	00000097          	auipc	ra,0x0
    80003d80:	9f4080e7          	jalr	-1548(ra) # 80003770 <idup>
    80003d84:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003d86:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003d8a:	4cb5                	li	s9,13
  len = path - s;
    80003d8c:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d8e:	4c05                	li	s8,1
    80003d90:	a87d                	j	80003e4e <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80003d92:	4585                	li	a1,1
    80003d94:	4505                	li	a0,1
    80003d96:	fffff097          	auipc	ra,0xfffff
    80003d9a:	6de080e7          	jalr	1758(ra) # 80003474 <iget>
    80003d9e:	8a2a                	mv	s4,a0
    80003da0:	b7dd                	j	80003d86 <namex+0x44>
      iunlockput(ip);
    80003da2:	8552                	mv	a0,s4
    80003da4:	00000097          	auipc	ra,0x0
    80003da8:	c6c080e7          	jalr	-916(ra) # 80003a10 <iunlockput>
      return 0;
    80003dac:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003dae:	8552                	mv	a0,s4
    80003db0:	60e6                	ld	ra,88(sp)
    80003db2:	6446                	ld	s0,80(sp)
    80003db4:	64a6                	ld	s1,72(sp)
    80003db6:	6906                	ld	s2,64(sp)
    80003db8:	79e2                	ld	s3,56(sp)
    80003dba:	7a42                	ld	s4,48(sp)
    80003dbc:	7aa2                	ld	s5,40(sp)
    80003dbe:	7b02                	ld	s6,32(sp)
    80003dc0:	6be2                	ld	s7,24(sp)
    80003dc2:	6c42                	ld	s8,16(sp)
    80003dc4:	6ca2                	ld	s9,8(sp)
    80003dc6:	6d02                	ld	s10,0(sp)
    80003dc8:	6125                	addi	sp,sp,96
    80003dca:	8082                	ret
      iunlock(ip);
    80003dcc:	8552                	mv	a0,s4
    80003dce:	00000097          	auipc	ra,0x0
    80003dd2:	aa2080e7          	jalr	-1374(ra) # 80003870 <iunlock>
      return ip;
    80003dd6:	bfe1                	j	80003dae <namex+0x6c>
      iunlockput(ip);
    80003dd8:	8552                	mv	a0,s4
    80003dda:	00000097          	auipc	ra,0x0
    80003dde:	c36080e7          	jalr	-970(ra) # 80003a10 <iunlockput>
      return 0;
    80003de2:	8a4e                	mv	s4,s3
    80003de4:	b7e9                	j	80003dae <namex+0x6c>
  len = path - s;
    80003de6:	40998633          	sub	a2,s3,s1
    80003dea:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80003dee:	09acd863          	bge	s9,s10,80003e7e <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80003df2:	4639                	li	a2,14
    80003df4:	85a6                	mv	a1,s1
    80003df6:	8556                	mv	a0,s5
    80003df8:	ffffd097          	auipc	ra,0xffffd
    80003dfc:	f36080e7          	jalr	-202(ra) # 80000d2e <memmove>
    80003e00:	84ce                	mv	s1,s3
  while(*path == '/')
    80003e02:	0004c783          	lbu	a5,0(s1)
    80003e06:	01279763          	bne	a5,s2,80003e14 <namex+0xd2>
    path++;
    80003e0a:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e0c:	0004c783          	lbu	a5,0(s1)
    80003e10:	ff278de3          	beq	a5,s2,80003e0a <namex+0xc8>
    ilock(ip);
    80003e14:	8552                	mv	a0,s4
    80003e16:	00000097          	auipc	ra,0x0
    80003e1a:	998080e7          	jalr	-1640(ra) # 800037ae <ilock>
    if(ip->type != T_DIR){
    80003e1e:	044a1783          	lh	a5,68(s4)
    80003e22:	f98790e3          	bne	a5,s8,80003da2 <namex+0x60>
    if(nameiparent && *path == '\0'){
    80003e26:	000b0563          	beqz	s6,80003e30 <namex+0xee>
    80003e2a:	0004c783          	lbu	a5,0(s1)
    80003e2e:	dfd9                	beqz	a5,80003dcc <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e30:	865e                	mv	a2,s7
    80003e32:	85d6                	mv	a1,s5
    80003e34:	8552                	mv	a0,s4
    80003e36:	00000097          	auipc	ra,0x0
    80003e3a:	e5c080e7          	jalr	-420(ra) # 80003c92 <dirlookup>
    80003e3e:	89aa                	mv	s3,a0
    80003e40:	dd41                	beqz	a0,80003dd8 <namex+0x96>
    iunlockput(ip);
    80003e42:	8552                	mv	a0,s4
    80003e44:	00000097          	auipc	ra,0x0
    80003e48:	bcc080e7          	jalr	-1076(ra) # 80003a10 <iunlockput>
    ip = next;
    80003e4c:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003e4e:	0004c783          	lbu	a5,0(s1)
    80003e52:	01279763          	bne	a5,s2,80003e60 <namex+0x11e>
    path++;
    80003e56:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e58:	0004c783          	lbu	a5,0(s1)
    80003e5c:	ff278de3          	beq	a5,s2,80003e56 <namex+0x114>
  if(*path == 0)
    80003e60:	cb9d                	beqz	a5,80003e96 <namex+0x154>
  while(*path != '/' && *path != 0)
    80003e62:	0004c783          	lbu	a5,0(s1)
    80003e66:	89a6                	mv	s3,s1
  len = path - s;
    80003e68:	8d5e                	mv	s10,s7
    80003e6a:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003e6c:	01278963          	beq	a5,s2,80003e7e <namex+0x13c>
    80003e70:	dbbd                	beqz	a5,80003de6 <namex+0xa4>
    path++;
    80003e72:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003e74:	0009c783          	lbu	a5,0(s3)
    80003e78:	ff279ce3          	bne	a5,s2,80003e70 <namex+0x12e>
    80003e7c:	b7ad                	j	80003de6 <namex+0xa4>
    memmove(name, s, len);
    80003e7e:	2601                	sext.w	a2,a2
    80003e80:	85a6                	mv	a1,s1
    80003e82:	8556                	mv	a0,s5
    80003e84:	ffffd097          	auipc	ra,0xffffd
    80003e88:	eaa080e7          	jalr	-342(ra) # 80000d2e <memmove>
    name[len] = 0;
    80003e8c:	9d56                	add	s10,s10,s5
    80003e8e:	000d0023          	sb	zero,0(s10)
    80003e92:	84ce                	mv	s1,s3
    80003e94:	b7bd                	j	80003e02 <namex+0xc0>
  if(nameiparent){
    80003e96:	f00b0ce3          	beqz	s6,80003dae <namex+0x6c>
    iput(ip);
    80003e9a:	8552                	mv	a0,s4
    80003e9c:	00000097          	auipc	ra,0x0
    80003ea0:	acc080e7          	jalr	-1332(ra) # 80003968 <iput>
    return 0;
    80003ea4:	4a01                	li	s4,0
    80003ea6:	b721                	j	80003dae <namex+0x6c>

0000000080003ea8 <dirlink>:
{
    80003ea8:	7139                	addi	sp,sp,-64
    80003eaa:	fc06                	sd	ra,56(sp)
    80003eac:	f822                	sd	s0,48(sp)
    80003eae:	f426                	sd	s1,40(sp)
    80003eb0:	f04a                	sd	s2,32(sp)
    80003eb2:	ec4e                	sd	s3,24(sp)
    80003eb4:	e852                	sd	s4,16(sp)
    80003eb6:	0080                	addi	s0,sp,64
    80003eb8:	892a                	mv	s2,a0
    80003eba:	8a2e                	mv	s4,a1
    80003ebc:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003ebe:	4601                	li	a2,0
    80003ec0:	00000097          	auipc	ra,0x0
    80003ec4:	dd2080e7          	jalr	-558(ra) # 80003c92 <dirlookup>
    80003ec8:	e93d                	bnez	a0,80003f3e <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003eca:	04c92483          	lw	s1,76(s2)
    80003ece:	c49d                	beqz	s1,80003efc <dirlink+0x54>
    80003ed0:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ed2:	4741                	li	a4,16
    80003ed4:	86a6                	mv	a3,s1
    80003ed6:	fc040613          	addi	a2,s0,-64
    80003eda:	4581                	li	a1,0
    80003edc:	854a                	mv	a0,s2
    80003ede:	00000097          	auipc	ra,0x0
    80003ee2:	b84080e7          	jalr	-1148(ra) # 80003a62 <readi>
    80003ee6:	47c1                	li	a5,16
    80003ee8:	06f51163          	bne	a0,a5,80003f4a <dirlink+0xa2>
    if(de.inum == 0)
    80003eec:	fc045783          	lhu	a5,-64(s0)
    80003ef0:	c791                	beqz	a5,80003efc <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ef2:	24c1                	addiw	s1,s1,16
    80003ef4:	04c92783          	lw	a5,76(s2)
    80003ef8:	fcf4ede3          	bltu	s1,a5,80003ed2 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003efc:	4639                	li	a2,14
    80003efe:	85d2                	mv	a1,s4
    80003f00:	fc240513          	addi	a0,s0,-62
    80003f04:	ffffd097          	auipc	ra,0xffffd
    80003f08:	eda080e7          	jalr	-294(ra) # 80000dde <strncpy>
  de.inum = inum;
    80003f0c:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f10:	4741                	li	a4,16
    80003f12:	86a6                	mv	a3,s1
    80003f14:	fc040613          	addi	a2,s0,-64
    80003f18:	4581                	li	a1,0
    80003f1a:	854a                	mv	a0,s2
    80003f1c:	00000097          	auipc	ra,0x0
    80003f20:	c3e080e7          	jalr	-962(ra) # 80003b5a <writei>
    80003f24:	1541                	addi	a0,a0,-16
    80003f26:	00a03533          	snez	a0,a0
    80003f2a:	40a00533          	neg	a0,a0
}
    80003f2e:	70e2                	ld	ra,56(sp)
    80003f30:	7442                	ld	s0,48(sp)
    80003f32:	74a2                	ld	s1,40(sp)
    80003f34:	7902                	ld	s2,32(sp)
    80003f36:	69e2                	ld	s3,24(sp)
    80003f38:	6a42                	ld	s4,16(sp)
    80003f3a:	6121                	addi	sp,sp,64
    80003f3c:	8082                	ret
    iput(ip);
    80003f3e:	00000097          	auipc	ra,0x0
    80003f42:	a2a080e7          	jalr	-1494(ra) # 80003968 <iput>
    return -1;
    80003f46:	557d                	li	a0,-1
    80003f48:	b7dd                	j	80003f2e <dirlink+0x86>
      panic("dirlink read");
    80003f4a:	00005517          	auipc	a0,0x5
    80003f4e:	80e50513          	addi	a0,a0,-2034 # 80008758 <syscalls+0x1d0>
    80003f52:	ffffc097          	auipc	ra,0xffffc
    80003f56:	5ee080e7          	jalr	1518(ra) # 80000540 <panic>

0000000080003f5a <namei>:

struct inode*
namei(char *path)
{
    80003f5a:	1101                	addi	sp,sp,-32
    80003f5c:	ec06                	sd	ra,24(sp)
    80003f5e:	e822                	sd	s0,16(sp)
    80003f60:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f62:	fe040613          	addi	a2,s0,-32
    80003f66:	4581                	li	a1,0
    80003f68:	00000097          	auipc	ra,0x0
    80003f6c:	dda080e7          	jalr	-550(ra) # 80003d42 <namex>
}
    80003f70:	60e2                	ld	ra,24(sp)
    80003f72:	6442                	ld	s0,16(sp)
    80003f74:	6105                	addi	sp,sp,32
    80003f76:	8082                	ret

0000000080003f78 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f78:	1141                	addi	sp,sp,-16
    80003f7a:	e406                	sd	ra,8(sp)
    80003f7c:	e022                	sd	s0,0(sp)
    80003f7e:	0800                	addi	s0,sp,16
    80003f80:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f82:	4585                	li	a1,1
    80003f84:	00000097          	auipc	ra,0x0
    80003f88:	dbe080e7          	jalr	-578(ra) # 80003d42 <namex>
}
    80003f8c:	60a2                	ld	ra,8(sp)
    80003f8e:	6402                	ld	s0,0(sp)
    80003f90:	0141                	addi	sp,sp,16
    80003f92:	8082                	ret

0000000080003f94 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f94:	1101                	addi	sp,sp,-32
    80003f96:	ec06                	sd	ra,24(sp)
    80003f98:	e822                	sd	s0,16(sp)
    80003f9a:	e426                	sd	s1,8(sp)
    80003f9c:	e04a                	sd	s2,0(sp)
    80003f9e:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003fa0:	00029917          	auipc	s2,0x29
    80003fa4:	fa090913          	addi	s2,s2,-96 # 8002cf40 <log>
    80003fa8:	01892583          	lw	a1,24(s2)
    80003fac:	02892503          	lw	a0,40(s2)
    80003fb0:	fffff097          	auipc	ra,0xfffff
    80003fb4:	fe6080e7          	jalr	-26(ra) # 80002f96 <bread>
    80003fb8:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003fba:	02c92683          	lw	a3,44(s2)
    80003fbe:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003fc0:	02d05863          	blez	a3,80003ff0 <write_head+0x5c>
    80003fc4:	00029797          	auipc	a5,0x29
    80003fc8:	fac78793          	addi	a5,a5,-84 # 8002cf70 <log+0x30>
    80003fcc:	05c50713          	addi	a4,a0,92
    80003fd0:	36fd                	addiw	a3,a3,-1
    80003fd2:	02069613          	slli	a2,a3,0x20
    80003fd6:	01e65693          	srli	a3,a2,0x1e
    80003fda:	00029617          	auipc	a2,0x29
    80003fde:	f9a60613          	addi	a2,a2,-102 # 8002cf74 <log+0x34>
    80003fe2:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003fe4:	4390                	lw	a2,0(a5)
    80003fe6:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003fe8:	0791                	addi	a5,a5,4
    80003fea:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80003fec:	fed79ce3          	bne	a5,a3,80003fe4 <write_head+0x50>
  }
  bwrite(buf);
    80003ff0:	8526                	mv	a0,s1
    80003ff2:	fffff097          	auipc	ra,0xfffff
    80003ff6:	096080e7          	jalr	150(ra) # 80003088 <bwrite>
  brelse(buf);
    80003ffa:	8526                	mv	a0,s1
    80003ffc:	fffff097          	auipc	ra,0xfffff
    80004000:	0ca080e7          	jalr	202(ra) # 800030c6 <brelse>
}
    80004004:	60e2                	ld	ra,24(sp)
    80004006:	6442                	ld	s0,16(sp)
    80004008:	64a2                	ld	s1,8(sp)
    8000400a:	6902                	ld	s2,0(sp)
    8000400c:	6105                	addi	sp,sp,32
    8000400e:	8082                	ret

0000000080004010 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004010:	00029797          	auipc	a5,0x29
    80004014:	f5c7a783          	lw	a5,-164(a5) # 8002cf6c <log+0x2c>
    80004018:	0af05d63          	blez	a5,800040d2 <install_trans+0xc2>
{
    8000401c:	7139                	addi	sp,sp,-64
    8000401e:	fc06                	sd	ra,56(sp)
    80004020:	f822                	sd	s0,48(sp)
    80004022:	f426                	sd	s1,40(sp)
    80004024:	f04a                	sd	s2,32(sp)
    80004026:	ec4e                	sd	s3,24(sp)
    80004028:	e852                	sd	s4,16(sp)
    8000402a:	e456                	sd	s5,8(sp)
    8000402c:	e05a                	sd	s6,0(sp)
    8000402e:	0080                	addi	s0,sp,64
    80004030:	8b2a                	mv	s6,a0
    80004032:	00029a97          	auipc	s5,0x29
    80004036:	f3ea8a93          	addi	s5,s5,-194 # 8002cf70 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000403a:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000403c:	00029997          	auipc	s3,0x29
    80004040:	f0498993          	addi	s3,s3,-252 # 8002cf40 <log>
    80004044:	a00d                	j	80004066 <install_trans+0x56>
    brelse(lbuf);
    80004046:	854a                	mv	a0,s2
    80004048:	fffff097          	auipc	ra,0xfffff
    8000404c:	07e080e7          	jalr	126(ra) # 800030c6 <brelse>
    brelse(dbuf);
    80004050:	8526                	mv	a0,s1
    80004052:	fffff097          	auipc	ra,0xfffff
    80004056:	074080e7          	jalr	116(ra) # 800030c6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000405a:	2a05                	addiw	s4,s4,1
    8000405c:	0a91                	addi	s5,s5,4
    8000405e:	02c9a783          	lw	a5,44(s3)
    80004062:	04fa5e63          	bge	s4,a5,800040be <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004066:	0189a583          	lw	a1,24(s3)
    8000406a:	014585bb          	addw	a1,a1,s4
    8000406e:	2585                	addiw	a1,a1,1
    80004070:	0289a503          	lw	a0,40(s3)
    80004074:	fffff097          	auipc	ra,0xfffff
    80004078:	f22080e7          	jalr	-222(ra) # 80002f96 <bread>
    8000407c:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000407e:	000aa583          	lw	a1,0(s5)
    80004082:	0289a503          	lw	a0,40(s3)
    80004086:	fffff097          	auipc	ra,0xfffff
    8000408a:	f10080e7          	jalr	-240(ra) # 80002f96 <bread>
    8000408e:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004090:	40000613          	li	a2,1024
    80004094:	05890593          	addi	a1,s2,88
    80004098:	05850513          	addi	a0,a0,88
    8000409c:	ffffd097          	auipc	ra,0xffffd
    800040a0:	c92080e7          	jalr	-878(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    800040a4:	8526                	mv	a0,s1
    800040a6:	fffff097          	auipc	ra,0xfffff
    800040aa:	fe2080e7          	jalr	-30(ra) # 80003088 <bwrite>
    if(recovering == 0)
    800040ae:	f80b1ce3          	bnez	s6,80004046 <install_trans+0x36>
      bunpin(dbuf);
    800040b2:	8526                	mv	a0,s1
    800040b4:	fffff097          	auipc	ra,0xfffff
    800040b8:	0ec080e7          	jalr	236(ra) # 800031a0 <bunpin>
    800040bc:	b769                	j	80004046 <install_trans+0x36>
}
    800040be:	70e2                	ld	ra,56(sp)
    800040c0:	7442                	ld	s0,48(sp)
    800040c2:	74a2                	ld	s1,40(sp)
    800040c4:	7902                	ld	s2,32(sp)
    800040c6:	69e2                	ld	s3,24(sp)
    800040c8:	6a42                	ld	s4,16(sp)
    800040ca:	6aa2                	ld	s5,8(sp)
    800040cc:	6b02                	ld	s6,0(sp)
    800040ce:	6121                	addi	sp,sp,64
    800040d0:	8082                	ret
    800040d2:	8082                	ret

00000000800040d4 <initlog>:
{
    800040d4:	7179                	addi	sp,sp,-48
    800040d6:	f406                	sd	ra,40(sp)
    800040d8:	f022                	sd	s0,32(sp)
    800040da:	ec26                	sd	s1,24(sp)
    800040dc:	e84a                	sd	s2,16(sp)
    800040de:	e44e                	sd	s3,8(sp)
    800040e0:	1800                	addi	s0,sp,48
    800040e2:	892a                	mv	s2,a0
    800040e4:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800040e6:	00029497          	auipc	s1,0x29
    800040ea:	e5a48493          	addi	s1,s1,-422 # 8002cf40 <log>
    800040ee:	00004597          	auipc	a1,0x4
    800040f2:	67a58593          	addi	a1,a1,1658 # 80008768 <syscalls+0x1e0>
    800040f6:	8526                	mv	a0,s1
    800040f8:	ffffd097          	auipc	ra,0xffffd
    800040fc:	a4e080e7          	jalr	-1458(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    80004100:	0149a583          	lw	a1,20(s3)
    80004104:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004106:	0109a783          	lw	a5,16(s3)
    8000410a:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000410c:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004110:	854a                	mv	a0,s2
    80004112:	fffff097          	auipc	ra,0xfffff
    80004116:	e84080e7          	jalr	-380(ra) # 80002f96 <bread>
  log.lh.n = lh->n;
    8000411a:	4d34                	lw	a3,88(a0)
    8000411c:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000411e:	02d05663          	blez	a3,8000414a <initlog+0x76>
    80004122:	05c50793          	addi	a5,a0,92
    80004126:	00029717          	auipc	a4,0x29
    8000412a:	e4a70713          	addi	a4,a4,-438 # 8002cf70 <log+0x30>
    8000412e:	36fd                	addiw	a3,a3,-1
    80004130:	02069613          	slli	a2,a3,0x20
    80004134:	01e65693          	srli	a3,a2,0x1e
    80004138:	06050613          	addi	a2,a0,96
    8000413c:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    8000413e:	4390                	lw	a2,0(a5)
    80004140:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004142:	0791                	addi	a5,a5,4
    80004144:	0711                	addi	a4,a4,4
    80004146:	fed79ce3          	bne	a5,a3,8000413e <initlog+0x6a>
  brelse(buf);
    8000414a:	fffff097          	auipc	ra,0xfffff
    8000414e:	f7c080e7          	jalr	-132(ra) # 800030c6 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004152:	4505                	li	a0,1
    80004154:	00000097          	auipc	ra,0x0
    80004158:	ebc080e7          	jalr	-324(ra) # 80004010 <install_trans>
  log.lh.n = 0;
    8000415c:	00029797          	auipc	a5,0x29
    80004160:	e007a823          	sw	zero,-496(a5) # 8002cf6c <log+0x2c>
  write_head(); // clear the log
    80004164:	00000097          	auipc	ra,0x0
    80004168:	e30080e7          	jalr	-464(ra) # 80003f94 <write_head>
}
    8000416c:	70a2                	ld	ra,40(sp)
    8000416e:	7402                	ld	s0,32(sp)
    80004170:	64e2                	ld	s1,24(sp)
    80004172:	6942                	ld	s2,16(sp)
    80004174:	69a2                	ld	s3,8(sp)
    80004176:	6145                	addi	sp,sp,48
    80004178:	8082                	ret

000000008000417a <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000417a:	1101                	addi	sp,sp,-32
    8000417c:	ec06                	sd	ra,24(sp)
    8000417e:	e822                	sd	s0,16(sp)
    80004180:	e426                	sd	s1,8(sp)
    80004182:	e04a                	sd	s2,0(sp)
    80004184:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004186:	00029517          	auipc	a0,0x29
    8000418a:	dba50513          	addi	a0,a0,-582 # 8002cf40 <log>
    8000418e:	ffffd097          	auipc	ra,0xffffd
    80004192:	a48080e7          	jalr	-1464(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    80004196:	00029497          	auipc	s1,0x29
    8000419a:	daa48493          	addi	s1,s1,-598 # 8002cf40 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000419e:	4979                	li	s2,30
    800041a0:	a039                	j	800041ae <begin_op+0x34>
      sleep(&log, &log.lock);
    800041a2:	85a6                	mv	a1,s1
    800041a4:	8526                	mv	a0,s1
    800041a6:	ffffe097          	auipc	ra,0xffffe
    800041aa:	ee8080e7          	jalr	-280(ra) # 8000208e <sleep>
    if(log.committing){
    800041ae:	50dc                	lw	a5,36(s1)
    800041b0:	fbed                	bnez	a5,800041a2 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041b2:	5098                	lw	a4,32(s1)
    800041b4:	2705                	addiw	a4,a4,1
    800041b6:	0007069b          	sext.w	a3,a4
    800041ba:	0027179b          	slliw	a5,a4,0x2
    800041be:	9fb9                	addw	a5,a5,a4
    800041c0:	0017979b          	slliw	a5,a5,0x1
    800041c4:	54d8                	lw	a4,44(s1)
    800041c6:	9fb9                	addw	a5,a5,a4
    800041c8:	00f95963          	bge	s2,a5,800041da <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800041cc:	85a6                	mv	a1,s1
    800041ce:	8526                	mv	a0,s1
    800041d0:	ffffe097          	auipc	ra,0xffffe
    800041d4:	ebe080e7          	jalr	-322(ra) # 8000208e <sleep>
    800041d8:	bfd9                	j	800041ae <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800041da:	00029517          	auipc	a0,0x29
    800041de:	d6650513          	addi	a0,a0,-666 # 8002cf40 <log>
    800041e2:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800041e4:	ffffd097          	auipc	ra,0xffffd
    800041e8:	aa6080e7          	jalr	-1370(ra) # 80000c8a <release>
      break;
    }
  }
}
    800041ec:	60e2                	ld	ra,24(sp)
    800041ee:	6442                	ld	s0,16(sp)
    800041f0:	64a2                	ld	s1,8(sp)
    800041f2:	6902                	ld	s2,0(sp)
    800041f4:	6105                	addi	sp,sp,32
    800041f6:	8082                	ret

00000000800041f8 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800041f8:	7139                	addi	sp,sp,-64
    800041fa:	fc06                	sd	ra,56(sp)
    800041fc:	f822                	sd	s0,48(sp)
    800041fe:	f426                	sd	s1,40(sp)
    80004200:	f04a                	sd	s2,32(sp)
    80004202:	ec4e                	sd	s3,24(sp)
    80004204:	e852                	sd	s4,16(sp)
    80004206:	e456                	sd	s5,8(sp)
    80004208:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000420a:	00029497          	auipc	s1,0x29
    8000420e:	d3648493          	addi	s1,s1,-714 # 8002cf40 <log>
    80004212:	8526                	mv	a0,s1
    80004214:	ffffd097          	auipc	ra,0xffffd
    80004218:	9c2080e7          	jalr	-1598(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    8000421c:	509c                	lw	a5,32(s1)
    8000421e:	37fd                	addiw	a5,a5,-1
    80004220:	0007891b          	sext.w	s2,a5
    80004224:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004226:	50dc                	lw	a5,36(s1)
    80004228:	e7b9                	bnez	a5,80004276 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000422a:	04091e63          	bnez	s2,80004286 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000422e:	00029497          	auipc	s1,0x29
    80004232:	d1248493          	addi	s1,s1,-750 # 8002cf40 <log>
    80004236:	4785                	li	a5,1
    80004238:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000423a:	8526                	mv	a0,s1
    8000423c:	ffffd097          	auipc	ra,0xffffd
    80004240:	a4e080e7          	jalr	-1458(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004244:	54dc                	lw	a5,44(s1)
    80004246:	06f04763          	bgtz	a5,800042b4 <end_op+0xbc>
    acquire(&log.lock);
    8000424a:	00029497          	auipc	s1,0x29
    8000424e:	cf648493          	addi	s1,s1,-778 # 8002cf40 <log>
    80004252:	8526                	mv	a0,s1
    80004254:	ffffd097          	auipc	ra,0xffffd
    80004258:	982080e7          	jalr	-1662(ra) # 80000bd6 <acquire>
    log.committing = 0;
    8000425c:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004260:	8526                	mv	a0,s1
    80004262:	ffffe097          	auipc	ra,0xffffe
    80004266:	e90080e7          	jalr	-368(ra) # 800020f2 <wakeup>
    release(&log.lock);
    8000426a:	8526                	mv	a0,s1
    8000426c:	ffffd097          	auipc	ra,0xffffd
    80004270:	a1e080e7          	jalr	-1506(ra) # 80000c8a <release>
}
    80004274:	a03d                	j	800042a2 <end_op+0xaa>
    panic("log.committing");
    80004276:	00004517          	auipc	a0,0x4
    8000427a:	4fa50513          	addi	a0,a0,1274 # 80008770 <syscalls+0x1e8>
    8000427e:	ffffc097          	auipc	ra,0xffffc
    80004282:	2c2080e7          	jalr	706(ra) # 80000540 <panic>
    wakeup(&log);
    80004286:	00029497          	auipc	s1,0x29
    8000428a:	cba48493          	addi	s1,s1,-838 # 8002cf40 <log>
    8000428e:	8526                	mv	a0,s1
    80004290:	ffffe097          	auipc	ra,0xffffe
    80004294:	e62080e7          	jalr	-414(ra) # 800020f2 <wakeup>
  release(&log.lock);
    80004298:	8526                	mv	a0,s1
    8000429a:	ffffd097          	auipc	ra,0xffffd
    8000429e:	9f0080e7          	jalr	-1552(ra) # 80000c8a <release>
}
    800042a2:	70e2                	ld	ra,56(sp)
    800042a4:	7442                	ld	s0,48(sp)
    800042a6:	74a2                	ld	s1,40(sp)
    800042a8:	7902                	ld	s2,32(sp)
    800042aa:	69e2                	ld	s3,24(sp)
    800042ac:	6a42                	ld	s4,16(sp)
    800042ae:	6aa2                	ld	s5,8(sp)
    800042b0:	6121                	addi	sp,sp,64
    800042b2:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800042b4:	00029a97          	auipc	s5,0x29
    800042b8:	cbca8a93          	addi	s5,s5,-836 # 8002cf70 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800042bc:	00029a17          	auipc	s4,0x29
    800042c0:	c84a0a13          	addi	s4,s4,-892 # 8002cf40 <log>
    800042c4:	018a2583          	lw	a1,24(s4)
    800042c8:	012585bb          	addw	a1,a1,s2
    800042cc:	2585                	addiw	a1,a1,1
    800042ce:	028a2503          	lw	a0,40(s4)
    800042d2:	fffff097          	auipc	ra,0xfffff
    800042d6:	cc4080e7          	jalr	-828(ra) # 80002f96 <bread>
    800042da:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800042dc:	000aa583          	lw	a1,0(s5)
    800042e0:	028a2503          	lw	a0,40(s4)
    800042e4:	fffff097          	auipc	ra,0xfffff
    800042e8:	cb2080e7          	jalr	-846(ra) # 80002f96 <bread>
    800042ec:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800042ee:	40000613          	li	a2,1024
    800042f2:	05850593          	addi	a1,a0,88
    800042f6:	05848513          	addi	a0,s1,88
    800042fa:	ffffd097          	auipc	ra,0xffffd
    800042fe:	a34080e7          	jalr	-1484(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    80004302:	8526                	mv	a0,s1
    80004304:	fffff097          	auipc	ra,0xfffff
    80004308:	d84080e7          	jalr	-636(ra) # 80003088 <bwrite>
    brelse(from);
    8000430c:	854e                	mv	a0,s3
    8000430e:	fffff097          	auipc	ra,0xfffff
    80004312:	db8080e7          	jalr	-584(ra) # 800030c6 <brelse>
    brelse(to);
    80004316:	8526                	mv	a0,s1
    80004318:	fffff097          	auipc	ra,0xfffff
    8000431c:	dae080e7          	jalr	-594(ra) # 800030c6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004320:	2905                	addiw	s2,s2,1
    80004322:	0a91                	addi	s5,s5,4
    80004324:	02ca2783          	lw	a5,44(s4)
    80004328:	f8f94ee3          	blt	s2,a5,800042c4 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000432c:	00000097          	auipc	ra,0x0
    80004330:	c68080e7          	jalr	-920(ra) # 80003f94 <write_head>
    install_trans(0); // Now install writes to home locations
    80004334:	4501                	li	a0,0
    80004336:	00000097          	auipc	ra,0x0
    8000433a:	cda080e7          	jalr	-806(ra) # 80004010 <install_trans>
    log.lh.n = 0;
    8000433e:	00029797          	auipc	a5,0x29
    80004342:	c207a723          	sw	zero,-978(a5) # 8002cf6c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004346:	00000097          	auipc	ra,0x0
    8000434a:	c4e080e7          	jalr	-946(ra) # 80003f94 <write_head>
    8000434e:	bdf5                	j	8000424a <end_op+0x52>

0000000080004350 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004350:	1101                	addi	sp,sp,-32
    80004352:	ec06                	sd	ra,24(sp)
    80004354:	e822                	sd	s0,16(sp)
    80004356:	e426                	sd	s1,8(sp)
    80004358:	e04a                	sd	s2,0(sp)
    8000435a:	1000                	addi	s0,sp,32
    8000435c:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000435e:	00029917          	auipc	s2,0x29
    80004362:	be290913          	addi	s2,s2,-1054 # 8002cf40 <log>
    80004366:	854a                	mv	a0,s2
    80004368:	ffffd097          	auipc	ra,0xffffd
    8000436c:	86e080e7          	jalr	-1938(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004370:	02c92603          	lw	a2,44(s2)
    80004374:	47f5                	li	a5,29
    80004376:	06c7c563          	blt	a5,a2,800043e0 <log_write+0x90>
    8000437a:	00029797          	auipc	a5,0x29
    8000437e:	be27a783          	lw	a5,-1054(a5) # 8002cf5c <log+0x1c>
    80004382:	37fd                	addiw	a5,a5,-1
    80004384:	04f65e63          	bge	a2,a5,800043e0 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004388:	00029797          	auipc	a5,0x29
    8000438c:	bd87a783          	lw	a5,-1064(a5) # 8002cf60 <log+0x20>
    80004390:	06f05063          	blez	a5,800043f0 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004394:	4781                	li	a5,0
    80004396:	06c05563          	blez	a2,80004400 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000439a:	44cc                	lw	a1,12(s1)
    8000439c:	00029717          	auipc	a4,0x29
    800043a0:	bd470713          	addi	a4,a4,-1068 # 8002cf70 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800043a4:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800043a6:	4314                	lw	a3,0(a4)
    800043a8:	04b68c63          	beq	a3,a1,80004400 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800043ac:	2785                	addiw	a5,a5,1
    800043ae:	0711                	addi	a4,a4,4
    800043b0:	fef61be3          	bne	a2,a5,800043a6 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800043b4:	0621                	addi	a2,a2,8
    800043b6:	060a                	slli	a2,a2,0x2
    800043b8:	00029797          	auipc	a5,0x29
    800043bc:	b8878793          	addi	a5,a5,-1144 # 8002cf40 <log>
    800043c0:	97b2                	add	a5,a5,a2
    800043c2:	44d8                	lw	a4,12(s1)
    800043c4:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800043c6:	8526                	mv	a0,s1
    800043c8:	fffff097          	auipc	ra,0xfffff
    800043cc:	d9c080e7          	jalr	-612(ra) # 80003164 <bpin>
    log.lh.n++;
    800043d0:	00029717          	auipc	a4,0x29
    800043d4:	b7070713          	addi	a4,a4,-1168 # 8002cf40 <log>
    800043d8:	575c                	lw	a5,44(a4)
    800043da:	2785                	addiw	a5,a5,1
    800043dc:	d75c                	sw	a5,44(a4)
    800043de:	a82d                	j	80004418 <log_write+0xc8>
    panic("too big a transaction");
    800043e0:	00004517          	auipc	a0,0x4
    800043e4:	3a050513          	addi	a0,a0,928 # 80008780 <syscalls+0x1f8>
    800043e8:	ffffc097          	auipc	ra,0xffffc
    800043ec:	158080e7          	jalr	344(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    800043f0:	00004517          	auipc	a0,0x4
    800043f4:	3a850513          	addi	a0,a0,936 # 80008798 <syscalls+0x210>
    800043f8:	ffffc097          	auipc	ra,0xffffc
    800043fc:	148080e7          	jalr	328(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    80004400:	00878693          	addi	a3,a5,8
    80004404:	068a                	slli	a3,a3,0x2
    80004406:	00029717          	auipc	a4,0x29
    8000440a:	b3a70713          	addi	a4,a4,-1222 # 8002cf40 <log>
    8000440e:	9736                	add	a4,a4,a3
    80004410:	44d4                	lw	a3,12(s1)
    80004412:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004414:	faf609e3          	beq	a2,a5,800043c6 <log_write+0x76>
  }
  release(&log.lock);
    80004418:	00029517          	auipc	a0,0x29
    8000441c:	b2850513          	addi	a0,a0,-1240 # 8002cf40 <log>
    80004420:	ffffd097          	auipc	ra,0xffffd
    80004424:	86a080e7          	jalr	-1942(ra) # 80000c8a <release>
}
    80004428:	60e2                	ld	ra,24(sp)
    8000442a:	6442                	ld	s0,16(sp)
    8000442c:	64a2                	ld	s1,8(sp)
    8000442e:	6902                	ld	s2,0(sp)
    80004430:	6105                	addi	sp,sp,32
    80004432:	8082                	ret

0000000080004434 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004434:	1101                	addi	sp,sp,-32
    80004436:	ec06                	sd	ra,24(sp)
    80004438:	e822                	sd	s0,16(sp)
    8000443a:	e426                	sd	s1,8(sp)
    8000443c:	e04a                	sd	s2,0(sp)
    8000443e:	1000                	addi	s0,sp,32
    80004440:	84aa                	mv	s1,a0
    80004442:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004444:	00004597          	auipc	a1,0x4
    80004448:	37458593          	addi	a1,a1,884 # 800087b8 <syscalls+0x230>
    8000444c:	0521                	addi	a0,a0,8
    8000444e:	ffffc097          	auipc	ra,0xffffc
    80004452:	6f8080e7          	jalr	1784(ra) # 80000b46 <initlock>
  lk->name = name;
    80004456:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000445a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000445e:	0204a423          	sw	zero,40(s1)
}
    80004462:	60e2                	ld	ra,24(sp)
    80004464:	6442                	ld	s0,16(sp)
    80004466:	64a2                	ld	s1,8(sp)
    80004468:	6902                	ld	s2,0(sp)
    8000446a:	6105                	addi	sp,sp,32
    8000446c:	8082                	ret

000000008000446e <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000446e:	1101                	addi	sp,sp,-32
    80004470:	ec06                	sd	ra,24(sp)
    80004472:	e822                	sd	s0,16(sp)
    80004474:	e426                	sd	s1,8(sp)
    80004476:	e04a                	sd	s2,0(sp)
    80004478:	1000                	addi	s0,sp,32
    8000447a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000447c:	00850913          	addi	s2,a0,8
    80004480:	854a                	mv	a0,s2
    80004482:	ffffc097          	auipc	ra,0xffffc
    80004486:	754080e7          	jalr	1876(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    8000448a:	409c                	lw	a5,0(s1)
    8000448c:	cb89                	beqz	a5,8000449e <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000448e:	85ca                	mv	a1,s2
    80004490:	8526                	mv	a0,s1
    80004492:	ffffe097          	auipc	ra,0xffffe
    80004496:	bfc080e7          	jalr	-1028(ra) # 8000208e <sleep>
  while (lk->locked) {
    8000449a:	409c                	lw	a5,0(s1)
    8000449c:	fbed                	bnez	a5,8000448e <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000449e:	4785                	li	a5,1
    800044a0:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800044a2:	ffffd097          	auipc	ra,0xffffd
    800044a6:	50a080e7          	jalr	1290(ra) # 800019ac <myproc>
    800044aa:	591c                	lw	a5,48(a0)
    800044ac:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800044ae:	854a                	mv	a0,s2
    800044b0:	ffffc097          	auipc	ra,0xffffc
    800044b4:	7da080e7          	jalr	2010(ra) # 80000c8a <release>
}
    800044b8:	60e2                	ld	ra,24(sp)
    800044ba:	6442                	ld	s0,16(sp)
    800044bc:	64a2                	ld	s1,8(sp)
    800044be:	6902                	ld	s2,0(sp)
    800044c0:	6105                	addi	sp,sp,32
    800044c2:	8082                	ret

00000000800044c4 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800044c4:	1101                	addi	sp,sp,-32
    800044c6:	ec06                	sd	ra,24(sp)
    800044c8:	e822                	sd	s0,16(sp)
    800044ca:	e426                	sd	s1,8(sp)
    800044cc:	e04a                	sd	s2,0(sp)
    800044ce:	1000                	addi	s0,sp,32
    800044d0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044d2:	00850913          	addi	s2,a0,8
    800044d6:	854a                	mv	a0,s2
    800044d8:	ffffc097          	auipc	ra,0xffffc
    800044dc:	6fe080e7          	jalr	1790(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    800044e0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044e4:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800044e8:	8526                	mv	a0,s1
    800044ea:	ffffe097          	auipc	ra,0xffffe
    800044ee:	c08080e7          	jalr	-1016(ra) # 800020f2 <wakeup>
  release(&lk->lk);
    800044f2:	854a                	mv	a0,s2
    800044f4:	ffffc097          	auipc	ra,0xffffc
    800044f8:	796080e7          	jalr	1942(ra) # 80000c8a <release>
}
    800044fc:	60e2                	ld	ra,24(sp)
    800044fe:	6442                	ld	s0,16(sp)
    80004500:	64a2                	ld	s1,8(sp)
    80004502:	6902                	ld	s2,0(sp)
    80004504:	6105                	addi	sp,sp,32
    80004506:	8082                	ret

0000000080004508 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004508:	7179                	addi	sp,sp,-48
    8000450a:	f406                	sd	ra,40(sp)
    8000450c:	f022                	sd	s0,32(sp)
    8000450e:	ec26                	sd	s1,24(sp)
    80004510:	e84a                	sd	s2,16(sp)
    80004512:	e44e                	sd	s3,8(sp)
    80004514:	1800                	addi	s0,sp,48
    80004516:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004518:	00850913          	addi	s2,a0,8
    8000451c:	854a                	mv	a0,s2
    8000451e:	ffffc097          	auipc	ra,0xffffc
    80004522:	6b8080e7          	jalr	1720(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004526:	409c                	lw	a5,0(s1)
    80004528:	ef99                	bnez	a5,80004546 <holdingsleep+0x3e>
    8000452a:	4481                	li	s1,0
  release(&lk->lk);
    8000452c:	854a                	mv	a0,s2
    8000452e:	ffffc097          	auipc	ra,0xffffc
    80004532:	75c080e7          	jalr	1884(ra) # 80000c8a <release>
  return r;
}
    80004536:	8526                	mv	a0,s1
    80004538:	70a2                	ld	ra,40(sp)
    8000453a:	7402                	ld	s0,32(sp)
    8000453c:	64e2                	ld	s1,24(sp)
    8000453e:	6942                	ld	s2,16(sp)
    80004540:	69a2                	ld	s3,8(sp)
    80004542:	6145                	addi	sp,sp,48
    80004544:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004546:	0284a983          	lw	s3,40(s1)
    8000454a:	ffffd097          	auipc	ra,0xffffd
    8000454e:	462080e7          	jalr	1122(ra) # 800019ac <myproc>
    80004552:	5904                	lw	s1,48(a0)
    80004554:	413484b3          	sub	s1,s1,s3
    80004558:	0014b493          	seqz	s1,s1
    8000455c:	bfc1                	j	8000452c <holdingsleep+0x24>

000000008000455e <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000455e:	1141                	addi	sp,sp,-16
    80004560:	e406                	sd	ra,8(sp)
    80004562:	e022                	sd	s0,0(sp)
    80004564:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004566:	00004597          	auipc	a1,0x4
    8000456a:	26258593          	addi	a1,a1,610 # 800087c8 <syscalls+0x240>
    8000456e:	00029517          	auipc	a0,0x29
    80004572:	b1a50513          	addi	a0,a0,-1254 # 8002d088 <ftable>
    80004576:	ffffc097          	auipc	ra,0xffffc
    8000457a:	5d0080e7          	jalr	1488(ra) # 80000b46 <initlock>
}
    8000457e:	60a2                	ld	ra,8(sp)
    80004580:	6402                	ld	s0,0(sp)
    80004582:	0141                	addi	sp,sp,16
    80004584:	8082                	ret

0000000080004586 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004586:	1101                	addi	sp,sp,-32
    80004588:	ec06                	sd	ra,24(sp)
    8000458a:	e822                	sd	s0,16(sp)
    8000458c:	e426                	sd	s1,8(sp)
    8000458e:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004590:	00029517          	auipc	a0,0x29
    80004594:	af850513          	addi	a0,a0,-1288 # 8002d088 <ftable>
    80004598:	ffffc097          	auipc	ra,0xffffc
    8000459c:	63e080e7          	jalr	1598(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045a0:	00029497          	auipc	s1,0x29
    800045a4:	b0048493          	addi	s1,s1,-1280 # 8002d0a0 <ftable+0x18>
    800045a8:	0002a717          	auipc	a4,0x2a
    800045ac:	a9870713          	addi	a4,a4,-1384 # 8002e040 <disk>
    if(f->ref == 0){
    800045b0:	40dc                	lw	a5,4(s1)
    800045b2:	cf99                	beqz	a5,800045d0 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045b4:	02848493          	addi	s1,s1,40
    800045b8:	fee49ce3          	bne	s1,a4,800045b0 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800045bc:	00029517          	auipc	a0,0x29
    800045c0:	acc50513          	addi	a0,a0,-1332 # 8002d088 <ftable>
    800045c4:	ffffc097          	auipc	ra,0xffffc
    800045c8:	6c6080e7          	jalr	1734(ra) # 80000c8a <release>
  return 0;
    800045cc:	4481                	li	s1,0
    800045ce:	a819                	j	800045e4 <filealloc+0x5e>
      f->ref = 1;
    800045d0:	4785                	li	a5,1
    800045d2:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800045d4:	00029517          	auipc	a0,0x29
    800045d8:	ab450513          	addi	a0,a0,-1356 # 8002d088 <ftable>
    800045dc:	ffffc097          	auipc	ra,0xffffc
    800045e0:	6ae080e7          	jalr	1710(ra) # 80000c8a <release>
}
    800045e4:	8526                	mv	a0,s1
    800045e6:	60e2                	ld	ra,24(sp)
    800045e8:	6442                	ld	s0,16(sp)
    800045ea:	64a2                	ld	s1,8(sp)
    800045ec:	6105                	addi	sp,sp,32
    800045ee:	8082                	ret

00000000800045f0 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800045f0:	1101                	addi	sp,sp,-32
    800045f2:	ec06                	sd	ra,24(sp)
    800045f4:	e822                	sd	s0,16(sp)
    800045f6:	e426                	sd	s1,8(sp)
    800045f8:	1000                	addi	s0,sp,32
    800045fa:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800045fc:	00029517          	auipc	a0,0x29
    80004600:	a8c50513          	addi	a0,a0,-1396 # 8002d088 <ftable>
    80004604:	ffffc097          	auipc	ra,0xffffc
    80004608:	5d2080e7          	jalr	1490(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    8000460c:	40dc                	lw	a5,4(s1)
    8000460e:	02f05263          	blez	a5,80004632 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004612:	2785                	addiw	a5,a5,1
    80004614:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004616:	00029517          	auipc	a0,0x29
    8000461a:	a7250513          	addi	a0,a0,-1422 # 8002d088 <ftable>
    8000461e:	ffffc097          	auipc	ra,0xffffc
    80004622:	66c080e7          	jalr	1644(ra) # 80000c8a <release>
  return f;
}
    80004626:	8526                	mv	a0,s1
    80004628:	60e2                	ld	ra,24(sp)
    8000462a:	6442                	ld	s0,16(sp)
    8000462c:	64a2                	ld	s1,8(sp)
    8000462e:	6105                	addi	sp,sp,32
    80004630:	8082                	ret
    panic("filedup");
    80004632:	00004517          	auipc	a0,0x4
    80004636:	19e50513          	addi	a0,a0,414 # 800087d0 <syscalls+0x248>
    8000463a:	ffffc097          	auipc	ra,0xffffc
    8000463e:	f06080e7          	jalr	-250(ra) # 80000540 <panic>

0000000080004642 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004642:	7139                	addi	sp,sp,-64
    80004644:	fc06                	sd	ra,56(sp)
    80004646:	f822                	sd	s0,48(sp)
    80004648:	f426                	sd	s1,40(sp)
    8000464a:	f04a                	sd	s2,32(sp)
    8000464c:	ec4e                	sd	s3,24(sp)
    8000464e:	e852                	sd	s4,16(sp)
    80004650:	e456                	sd	s5,8(sp)
    80004652:	0080                	addi	s0,sp,64
    80004654:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004656:	00029517          	auipc	a0,0x29
    8000465a:	a3250513          	addi	a0,a0,-1486 # 8002d088 <ftable>
    8000465e:	ffffc097          	auipc	ra,0xffffc
    80004662:	578080e7          	jalr	1400(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004666:	40dc                	lw	a5,4(s1)
    80004668:	06f05163          	blez	a5,800046ca <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000466c:	37fd                	addiw	a5,a5,-1
    8000466e:	0007871b          	sext.w	a4,a5
    80004672:	c0dc                	sw	a5,4(s1)
    80004674:	06e04363          	bgtz	a4,800046da <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004678:	0004a903          	lw	s2,0(s1)
    8000467c:	0094ca83          	lbu	s5,9(s1)
    80004680:	0104ba03          	ld	s4,16(s1)
    80004684:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004688:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000468c:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004690:	00029517          	auipc	a0,0x29
    80004694:	9f850513          	addi	a0,a0,-1544 # 8002d088 <ftable>
    80004698:	ffffc097          	auipc	ra,0xffffc
    8000469c:	5f2080e7          	jalr	1522(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    800046a0:	4785                	li	a5,1
    800046a2:	04f90d63          	beq	s2,a5,800046fc <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800046a6:	3979                	addiw	s2,s2,-2
    800046a8:	4785                	li	a5,1
    800046aa:	0527e063          	bltu	a5,s2,800046ea <fileclose+0xa8>
    begin_op();
    800046ae:	00000097          	auipc	ra,0x0
    800046b2:	acc080e7          	jalr	-1332(ra) # 8000417a <begin_op>
    iput(ff.ip);
    800046b6:	854e                	mv	a0,s3
    800046b8:	fffff097          	auipc	ra,0xfffff
    800046bc:	2b0080e7          	jalr	688(ra) # 80003968 <iput>
    end_op();
    800046c0:	00000097          	auipc	ra,0x0
    800046c4:	b38080e7          	jalr	-1224(ra) # 800041f8 <end_op>
    800046c8:	a00d                	j	800046ea <fileclose+0xa8>
    panic("fileclose");
    800046ca:	00004517          	auipc	a0,0x4
    800046ce:	10e50513          	addi	a0,a0,270 # 800087d8 <syscalls+0x250>
    800046d2:	ffffc097          	auipc	ra,0xffffc
    800046d6:	e6e080e7          	jalr	-402(ra) # 80000540 <panic>
    release(&ftable.lock);
    800046da:	00029517          	auipc	a0,0x29
    800046de:	9ae50513          	addi	a0,a0,-1618 # 8002d088 <ftable>
    800046e2:	ffffc097          	auipc	ra,0xffffc
    800046e6:	5a8080e7          	jalr	1448(ra) # 80000c8a <release>
  }
}
    800046ea:	70e2                	ld	ra,56(sp)
    800046ec:	7442                	ld	s0,48(sp)
    800046ee:	74a2                	ld	s1,40(sp)
    800046f0:	7902                	ld	s2,32(sp)
    800046f2:	69e2                	ld	s3,24(sp)
    800046f4:	6a42                	ld	s4,16(sp)
    800046f6:	6aa2                	ld	s5,8(sp)
    800046f8:	6121                	addi	sp,sp,64
    800046fa:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800046fc:	85d6                	mv	a1,s5
    800046fe:	8552                	mv	a0,s4
    80004700:	00000097          	auipc	ra,0x0
    80004704:	34c080e7          	jalr	844(ra) # 80004a4c <pipeclose>
    80004708:	b7cd                	j	800046ea <fileclose+0xa8>

000000008000470a <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000470a:	715d                	addi	sp,sp,-80
    8000470c:	e486                	sd	ra,72(sp)
    8000470e:	e0a2                	sd	s0,64(sp)
    80004710:	fc26                	sd	s1,56(sp)
    80004712:	f84a                	sd	s2,48(sp)
    80004714:	f44e                	sd	s3,40(sp)
    80004716:	0880                	addi	s0,sp,80
    80004718:	84aa                	mv	s1,a0
    8000471a:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000471c:	ffffd097          	auipc	ra,0xffffd
    80004720:	290080e7          	jalr	656(ra) # 800019ac <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004724:	409c                	lw	a5,0(s1)
    80004726:	37f9                	addiw	a5,a5,-2
    80004728:	4705                	li	a4,1
    8000472a:	04f76763          	bltu	a4,a5,80004778 <filestat+0x6e>
    8000472e:	892a                	mv	s2,a0
    ilock(f->ip);
    80004730:	6c88                	ld	a0,24(s1)
    80004732:	fffff097          	auipc	ra,0xfffff
    80004736:	07c080e7          	jalr	124(ra) # 800037ae <ilock>
    stati(f->ip, &st);
    8000473a:	fb840593          	addi	a1,s0,-72
    8000473e:	6c88                	ld	a0,24(s1)
    80004740:	fffff097          	auipc	ra,0xfffff
    80004744:	2f8080e7          	jalr	760(ra) # 80003a38 <stati>
    iunlock(f->ip);
    80004748:	6c88                	ld	a0,24(s1)
    8000474a:	fffff097          	auipc	ra,0xfffff
    8000474e:	126080e7          	jalr	294(ra) # 80003870 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004752:	46e1                	li	a3,24
    80004754:	fb840613          	addi	a2,s0,-72
    80004758:	85ce                	mv	a1,s3
    8000475a:	05093503          	ld	a0,80(s2)
    8000475e:	ffffd097          	auipc	ra,0xffffd
    80004762:	f0e080e7          	jalr	-242(ra) # 8000166c <copyout>
    80004766:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000476a:	60a6                	ld	ra,72(sp)
    8000476c:	6406                	ld	s0,64(sp)
    8000476e:	74e2                	ld	s1,56(sp)
    80004770:	7942                	ld	s2,48(sp)
    80004772:	79a2                	ld	s3,40(sp)
    80004774:	6161                	addi	sp,sp,80
    80004776:	8082                	ret
  return -1;
    80004778:	557d                	li	a0,-1
    8000477a:	bfc5                	j	8000476a <filestat+0x60>

000000008000477c <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000477c:	7179                	addi	sp,sp,-48
    8000477e:	f406                	sd	ra,40(sp)
    80004780:	f022                	sd	s0,32(sp)
    80004782:	ec26                	sd	s1,24(sp)
    80004784:	e84a                	sd	s2,16(sp)
    80004786:	e44e                	sd	s3,8(sp)
    80004788:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000478a:	00854783          	lbu	a5,8(a0)
    8000478e:	c3d5                	beqz	a5,80004832 <fileread+0xb6>
    80004790:	84aa                	mv	s1,a0
    80004792:	89ae                	mv	s3,a1
    80004794:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004796:	411c                	lw	a5,0(a0)
    80004798:	4705                	li	a4,1
    8000479a:	04e78963          	beq	a5,a4,800047ec <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000479e:	470d                	li	a4,3
    800047a0:	04e78d63          	beq	a5,a4,800047fa <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800047a4:	4709                	li	a4,2
    800047a6:	06e79e63          	bne	a5,a4,80004822 <fileread+0xa6>
    ilock(f->ip);
    800047aa:	6d08                	ld	a0,24(a0)
    800047ac:	fffff097          	auipc	ra,0xfffff
    800047b0:	002080e7          	jalr	2(ra) # 800037ae <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800047b4:	874a                	mv	a4,s2
    800047b6:	5094                	lw	a3,32(s1)
    800047b8:	864e                	mv	a2,s3
    800047ba:	4585                	li	a1,1
    800047bc:	6c88                	ld	a0,24(s1)
    800047be:	fffff097          	auipc	ra,0xfffff
    800047c2:	2a4080e7          	jalr	676(ra) # 80003a62 <readi>
    800047c6:	892a                	mv	s2,a0
    800047c8:	00a05563          	blez	a0,800047d2 <fileread+0x56>
      f->off += r;
    800047cc:	509c                	lw	a5,32(s1)
    800047ce:	9fa9                	addw	a5,a5,a0
    800047d0:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800047d2:	6c88                	ld	a0,24(s1)
    800047d4:	fffff097          	auipc	ra,0xfffff
    800047d8:	09c080e7          	jalr	156(ra) # 80003870 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800047dc:	854a                	mv	a0,s2
    800047de:	70a2                	ld	ra,40(sp)
    800047e0:	7402                	ld	s0,32(sp)
    800047e2:	64e2                	ld	s1,24(sp)
    800047e4:	6942                	ld	s2,16(sp)
    800047e6:	69a2                	ld	s3,8(sp)
    800047e8:	6145                	addi	sp,sp,48
    800047ea:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800047ec:	6908                	ld	a0,16(a0)
    800047ee:	00000097          	auipc	ra,0x0
    800047f2:	3c6080e7          	jalr	966(ra) # 80004bb4 <piperead>
    800047f6:	892a                	mv	s2,a0
    800047f8:	b7d5                	j	800047dc <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800047fa:	02451783          	lh	a5,36(a0)
    800047fe:	03079693          	slli	a3,a5,0x30
    80004802:	92c1                	srli	a3,a3,0x30
    80004804:	4725                	li	a4,9
    80004806:	02d76863          	bltu	a4,a3,80004836 <fileread+0xba>
    8000480a:	0792                	slli	a5,a5,0x4
    8000480c:	00028717          	auipc	a4,0x28
    80004810:	7dc70713          	addi	a4,a4,2012 # 8002cfe8 <devsw>
    80004814:	97ba                	add	a5,a5,a4
    80004816:	639c                	ld	a5,0(a5)
    80004818:	c38d                	beqz	a5,8000483a <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000481a:	4505                	li	a0,1
    8000481c:	9782                	jalr	a5
    8000481e:	892a                	mv	s2,a0
    80004820:	bf75                	j	800047dc <fileread+0x60>
    panic("fileread");
    80004822:	00004517          	auipc	a0,0x4
    80004826:	fc650513          	addi	a0,a0,-58 # 800087e8 <syscalls+0x260>
    8000482a:	ffffc097          	auipc	ra,0xffffc
    8000482e:	d16080e7          	jalr	-746(ra) # 80000540 <panic>
    return -1;
    80004832:	597d                	li	s2,-1
    80004834:	b765                	j	800047dc <fileread+0x60>
      return -1;
    80004836:	597d                	li	s2,-1
    80004838:	b755                	j	800047dc <fileread+0x60>
    8000483a:	597d                	li	s2,-1
    8000483c:	b745                	j	800047dc <fileread+0x60>

000000008000483e <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    8000483e:	715d                	addi	sp,sp,-80
    80004840:	e486                	sd	ra,72(sp)
    80004842:	e0a2                	sd	s0,64(sp)
    80004844:	fc26                	sd	s1,56(sp)
    80004846:	f84a                	sd	s2,48(sp)
    80004848:	f44e                	sd	s3,40(sp)
    8000484a:	f052                	sd	s4,32(sp)
    8000484c:	ec56                	sd	s5,24(sp)
    8000484e:	e85a                	sd	s6,16(sp)
    80004850:	e45e                	sd	s7,8(sp)
    80004852:	e062                	sd	s8,0(sp)
    80004854:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004856:	00954783          	lbu	a5,9(a0)
    8000485a:	10078663          	beqz	a5,80004966 <filewrite+0x128>
    8000485e:	892a                	mv	s2,a0
    80004860:	8b2e                	mv	s6,a1
    80004862:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004864:	411c                	lw	a5,0(a0)
    80004866:	4705                	li	a4,1
    80004868:	02e78263          	beq	a5,a4,8000488c <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000486c:	470d                	li	a4,3
    8000486e:	02e78663          	beq	a5,a4,8000489a <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004872:	4709                	li	a4,2
    80004874:	0ee79163          	bne	a5,a4,80004956 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004878:	0ac05d63          	blez	a2,80004932 <filewrite+0xf4>
    int i = 0;
    8000487c:	4981                	li	s3,0
    8000487e:	6b85                	lui	s7,0x1
    80004880:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004884:	6c05                	lui	s8,0x1
    80004886:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    8000488a:	a861                	j	80004922 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000488c:	6908                	ld	a0,16(a0)
    8000488e:	00000097          	auipc	ra,0x0
    80004892:	22e080e7          	jalr	558(ra) # 80004abc <pipewrite>
    80004896:	8a2a                	mv	s4,a0
    80004898:	a045                	j	80004938 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000489a:	02451783          	lh	a5,36(a0)
    8000489e:	03079693          	slli	a3,a5,0x30
    800048a2:	92c1                	srli	a3,a3,0x30
    800048a4:	4725                	li	a4,9
    800048a6:	0cd76263          	bltu	a4,a3,8000496a <filewrite+0x12c>
    800048aa:	0792                	slli	a5,a5,0x4
    800048ac:	00028717          	auipc	a4,0x28
    800048b0:	73c70713          	addi	a4,a4,1852 # 8002cfe8 <devsw>
    800048b4:	97ba                	add	a5,a5,a4
    800048b6:	679c                	ld	a5,8(a5)
    800048b8:	cbdd                	beqz	a5,8000496e <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800048ba:	4505                	li	a0,1
    800048bc:	9782                	jalr	a5
    800048be:	8a2a                	mv	s4,a0
    800048c0:	a8a5                	j	80004938 <filewrite+0xfa>
    800048c2:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800048c6:	00000097          	auipc	ra,0x0
    800048ca:	8b4080e7          	jalr	-1868(ra) # 8000417a <begin_op>
      ilock(f->ip);
    800048ce:	01893503          	ld	a0,24(s2)
    800048d2:	fffff097          	auipc	ra,0xfffff
    800048d6:	edc080e7          	jalr	-292(ra) # 800037ae <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800048da:	8756                	mv	a4,s5
    800048dc:	02092683          	lw	a3,32(s2)
    800048e0:	01698633          	add	a2,s3,s6
    800048e4:	4585                	li	a1,1
    800048e6:	01893503          	ld	a0,24(s2)
    800048ea:	fffff097          	auipc	ra,0xfffff
    800048ee:	270080e7          	jalr	624(ra) # 80003b5a <writei>
    800048f2:	84aa                	mv	s1,a0
    800048f4:	00a05763          	blez	a0,80004902 <filewrite+0xc4>
        f->off += r;
    800048f8:	02092783          	lw	a5,32(s2)
    800048fc:	9fa9                	addw	a5,a5,a0
    800048fe:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004902:	01893503          	ld	a0,24(s2)
    80004906:	fffff097          	auipc	ra,0xfffff
    8000490a:	f6a080e7          	jalr	-150(ra) # 80003870 <iunlock>
      end_op();
    8000490e:	00000097          	auipc	ra,0x0
    80004912:	8ea080e7          	jalr	-1814(ra) # 800041f8 <end_op>

      if(r != n1){
    80004916:	009a9f63          	bne	s5,s1,80004934 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    8000491a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000491e:	0149db63          	bge	s3,s4,80004934 <filewrite+0xf6>
      int n1 = n - i;
    80004922:	413a04bb          	subw	s1,s4,s3
    80004926:	0004879b          	sext.w	a5,s1
    8000492a:	f8fbdce3          	bge	s7,a5,800048c2 <filewrite+0x84>
    8000492e:	84e2                	mv	s1,s8
    80004930:	bf49                	j	800048c2 <filewrite+0x84>
    int i = 0;
    80004932:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004934:	013a1f63          	bne	s4,s3,80004952 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004938:	8552                	mv	a0,s4
    8000493a:	60a6                	ld	ra,72(sp)
    8000493c:	6406                	ld	s0,64(sp)
    8000493e:	74e2                	ld	s1,56(sp)
    80004940:	7942                	ld	s2,48(sp)
    80004942:	79a2                	ld	s3,40(sp)
    80004944:	7a02                	ld	s4,32(sp)
    80004946:	6ae2                	ld	s5,24(sp)
    80004948:	6b42                	ld	s6,16(sp)
    8000494a:	6ba2                	ld	s7,8(sp)
    8000494c:	6c02                	ld	s8,0(sp)
    8000494e:	6161                	addi	sp,sp,80
    80004950:	8082                	ret
    ret = (i == n ? n : -1);
    80004952:	5a7d                	li	s4,-1
    80004954:	b7d5                	j	80004938 <filewrite+0xfa>
    panic("filewrite");
    80004956:	00004517          	auipc	a0,0x4
    8000495a:	ea250513          	addi	a0,a0,-350 # 800087f8 <syscalls+0x270>
    8000495e:	ffffc097          	auipc	ra,0xffffc
    80004962:	be2080e7          	jalr	-1054(ra) # 80000540 <panic>
    return -1;
    80004966:	5a7d                	li	s4,-1
    80004968:	bfc1                	j	80004938 <filewrite+0xfa>
      return -1;
    8000496a:	5a7d                	li	s4,-1
    8000496c:	b7f1                	j	80004938 <filewrite+0xfa>
    8000496e:	5a7d                	li	s4,-1
    80004970:	b7e1                	j	80004938 <filewrite+0xfa>

0000000080004972 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004972:	7179                	addi	sp,sp,-48
    80004974:	f406                	sd	ra,40(sp)
    80004976:	f022                	sd	s0,32(sp)
    80004978:	ec26                	sd	s1,24(sp)
    8000497a:	e84a                	sd	s2,16(sp)
    8000497c:	e44e                	sd	s3,8(sp)
    8000497e:	e052                	sd	s4,0(sp)
    80004980:	1800                	addi	s0,sp,48
    80004982:	84aa                	mv	s1,a0
    80004984:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004986:	0005b023          	sd	zero,0(a1)
    8000498a:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000498e:	00000097          	auipc	ra,0x0
    80004992:	bf8080e7          	jalr	-1032(ra) # 80004586 <filealloc>
    80004996:	e088                	sd	a0,0(s1)
    80004998:	c551                	beqz	a0,80004a24 <pipealloc+0xb2>
    8000499a:	00000097          	auipc	ra,0x0
    8000499e:	bec080e7          	jalr	-1044(ra) # 80004586 <filealloc>
    800049a2:	00aa3023          	sd	a0,0(s4)
    800049a6:	c92d                	beqz	a0,80004a18 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800049a8:	ffffc097          	auipc	ra,0xffffc
    800049ac:	13e080e7          	jalr	318(ra) # 80000ae6 <kalloc>
    800049b0:	892a                	mv	s2,a0
    800049b2:	c125                	beqz	a0,80004a12 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800049b4:	4985                	li	s3,1
    800049b6:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800049ba:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800049be:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800049c2:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800049c6:	00004597          	auipc	a1,0x4
    800049ca:	b1a58593          	addi	a1,a1,-1254 # 800084e0 <states.0+0x218>
    800049ce:	ffffc097          	auipc	ra,0xffffc
    800049d2:	178080e7          	jalr	376(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    800049d6:	609c                	ld	a5,0(s1)
    800049d8:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800049dc:	609c                	ld	a5,0(s1)
    800049de:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800049e2:	609c                	ld	a5,0(s1)
    800049e4:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800049e8:	609c                	ld	a5,0(s1)
    800049ea:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800049ee:	000a3783          	ld	a5,0(s4)
    800049f2:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800049f6:	000a3783          	ld	a5,0(s4)
    800049fa:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800049fe:	000a3783          	ld	a5,0(s4)
    80004a02:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a06:	000a3783          	ld	a5,0(s4)
    80004a0a:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a0e:	4501                	li	a0,0
    80004a10:	a025                	j	80004a38 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a12:	6088                	ld	a0,0(s1)
    80004a14:	e501                	bnez	a0,80004a1c <pipealloc+0xaa>
    80004a16:	a039                	j	80004a24 <pipealloc+0xb2>
    80004a18:	6088                	ld	a0,0(s1)
    80004a1a:	c51d                	beqz	a0,80004a48 <pipealloc+0xd6>
    fileclose(*f0);
    80004a1c:	00000097          	auipc	ra,0x0
    80004a20:	c26080e7          	jalr	-986(ra) # 80004642 <fileclose>
  if(*f1)
    80004a24:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a28:	557d                	li	a0,-1
  if(*f1)
    80004a2a:	c799                	beqz	a5,80004a38 <pipealloc+0xc6>
    fileclose(*f1);
    80004a2c:	853e                	mv	a0,a5
    80004a2e:	00000097          	auipc	ra,0x0
    80004a32:	c14080e7          	jalr	-1004(ra) # 80004642 <fileclose>
  return -1;
    80004a36:	557d                	li	a0,-1
}
    80004a38:	70a2                	ld	ra,40(sp)
    80004a3a:	7402                	ld	s0,32(sp)
    80004a3c:	64e2                	ld	s1,24(sp)
    80004a3e:	6942                	ld	s2,16(sp)
    80004a40:	69a2                	ld	s3,8(sp)
    80004a42:	6a02                	ld	s4,0(sp)
    80004a44:	6145                	addi	sp,sp,48
    80004a46:	8082                	ret
  return -1;
    80004a48:	557d                	li	a0,-1
    80004a4a:	b7fd                	j	80004a38 <pipealloc+0xc6>

0000000080004a4c <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a4c:	1101                	addi	sp,sp,-32
    80004a4e:	ec06                	sd	ra,24(sp)
    80004a50:	e822                	sd	s0,16(sp)
    80004a52:	e426                	sd	s1,8(sp)
    80004a54:	e04a                	sd	s2,0(sp)
    80004a56:	1000                	addi	s0,sp,32
    80004a58:	84aa                	mv	s1,a0
    80004a5a:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a5c:	ffffc097          	auipc	ra,0xffffc
    80004a60:	17a080e7          	jalr	378(ra) # 80000bd6 <acquire>
  if(writable){
    80004a64:	02090d63          	beqz	s2,80004a9e <pipeclose+0x52>
    pi->writeopen = 0;
    80004a68:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a6c:	21848513          	addi	a0,s1,536
    80004a70:	ffffd097          	auipc	ra,0xffffd
    80004a74:	682080e7          	jalr	1666(ra) # 800020f2 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a78:	2204b783          	ld	a5,544(s1)
    80004a7c:	eb95                	bnez	a5,80004ab0 <pipeclose+0x64>
    release(&pi->lock);
    80004a7e:	8526                	mv	a0,s1
    80004a80:	ffffc097          	auipc	ra,0xffffc
    80004a84:	20a080e7          	jalr	522(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004a88:	8526                	mv	a0,s1
    80004a8a:	ffffc097          	auipc	ra,0xffffc
    80004a8e:	f5e080e7          	jalr	-162(ra) # 800009e8 <kfree>
  } else
    release(&pi->lock);
}
    80004a92:	60e2                	ld	ra,24(sp)
    80004a94:	6442                	ld	s0,16(sp)
    80004a96:	64a2                	ld	s1,8(sp)
    80004a98:	6902                	ld	s2,0(sp)
    80004a9a:	6105                	addi	sp,sp,32
    80004a9c:	8082                	ret
    pi->readopen = 0;
    80004a9e:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004aa2:	21c48513          	addi	a0,s1,540
    80004aa6:	ffffd097          	auipc	ra,0xffffd
    80004aaa:	64c080e7          	jalr	1612(ra) # 800020f2 <wakeup>
    80004aae:	b7e9                	j	80004a78 <pipeclose+0x2c>
    release(&pi->lock);
    80004ab0:	8526                	mv	a0,s1
    80004ab2:	ffffc097          	auipc	ra,0xffffc
    80004ab6:	1d8080e7          	jalr	472(ra) # 80000c8a <release>
}
    80004aba:	bfe1                	j	80004a92 <pipeclose+0x46>

0000000080004abc <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004abc:	711d                	addi	sp,sp,-96
    80004abe:	ec86                	sd	ra,88(sp)
    80004ac0:	e8a2                	sd	s0,80(sp)
    80004ac2:	e4a6                	sd	s1,72(sp)
    80004ac4:	e0ca                	sd	s2,64(sp)
    80004ac6:	fc4e                	sd	s3,56(sp)
    80004ac8:	f852                	sd	s4,48(sp)
    80004aca:	f456                	sd	s5,40(sp)
    80004acc:	f05a                	sd	s6,32(sp)
    80004ace:	ec5e                	sd	s7,24(sp)
    80004ad0:	e862                	sd	s8,16(sp)
    80004ad2:	1080                	addi	s0,sp,96
    80004ad4:	84aa                	mv	s1,a0
    80004ad6:	8aae                	mv	s5,a1
    80004ad8:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004ada:	ffffd097          	auipc	ra,0xffffd
    80004ade:	ed2080e7          	jalr	-302(ra) # 800019ac <myproc>
    80004ae2:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004ae4:	8526                	mv	a0,s1
    80004ae6:	ffffc097          	auipc	ra,0xffffc
    80004aea:	0f0080e7          	jalr	240(ra) # 80000bd6 <acquire>
  while(i < n){
    80004aee:	0b405663          	blez	s4,80004b9a <pipewrite+0xde>
  int i = 0;
    80004af2:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004af4:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004af6:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004afa:	21c48b93          	addi	s7,s1,540
    80004afe:	a089                	j	80004b40 <pipewrite+0x84>
      release(&pi->lock);
    80004b00:	8526                	mv	a0,s1
    80004b02:	ffffc097          	auipc	ra,0xffffc
    80004b06:	188080e7          	jalr	392(ra) # 80000c8a <release>
      return -1;
    80004b0a:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004b0c:	854a                	mv	a0,s2
    80004b0e:	60e6                	ld	ra,88(sp)
    80004b10:	6446                	ld	s0,80(sp)
    80004b12:	64a6                	ld	s1,72(sp)
    80004b14:	6906                	ld	s2,64(sp)
    80004b16:	79e2                	ld	s3,56(sp)
    80004b18:	7a42                	ld	s4,48(sp)
    80004b1a:	7aa2                	ld	s5,40(sp)
    80004b1c:	7b02                	ld	s6,32(sp)
    80004b1e:	6be2                	ld	s7,24(sp)
    80004b20:	6c42                	ld	s8,16(sp)
    80004b22:	6125                	addi	sp,sp,96
    80004b24:	8082                	ret
      wakeup(&pi->nread);
    80004b26:	8562                	mv	a0,s8
    80004b28:	ffffd097          	auipc	ra,0xffffd
    80004b2c:	5ca080e7          	jalr	1482(ra) # 800020f2 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b30:	85a6                	mv	a1,s1
    80004b32:	855e                	mv	a0,s7
    80004b34:	ffffd097          	auipc	ra,0xffffd
    80004b38:	55a080e7          	jalr	1370(ra) # 8000208e <sleep>
  while(i < n){
    80004b3c:	07495063          	bge	s2,s4,80004b9c <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004b40:	2204a783          	lw	a5,544(s1)
    80004b44:	dfd5                	beqz	a5,80004b00 <pipewrite+0x44>
    80004b46:	854e                	mv	a0,s3
    80004b48:	ffffd097          	auipc	ra,0xffffd
    80004b4c:	7ee080e7          	jalr	2030(ra) # 80002336 <killed>
    80004b50:	f945                	bnez	a0,80004b00 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004b52:	2184a783          	lw	a5,536(s1)
    80004b56:	21c4a703          	lw	a4,540(s1)
    80004b5a:	2007879b          	addiw	a5,a5,512
    80004b5e:	fcf704e3          	beq	a4,a5,80004b26 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b62:	4685                	li	a3,1
    80004b64:	01590633          	add	a2,s2,s5
    80004b68:	faf40593          	addi	a1,s0,-81
    80004b6c:	0509b503          	ld	a0,80(s3)
    80004b70:	ffffd097          	auipc	ra,0xffffd
    80004b74:	b88080e7          	jalr	-1144(ra) # 800016f8 <copyin>
    80004b78:	03650263          	beq	a0,s6,80004b9c <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b7c:	21c4a783          	lw	a5,540(s1)
    80004b80:	0017871b          	addiw	a4,a5,1
    80004b84:	20e4ae23          	sw	a4,540(s1)
    80004b88:	1ff7f793          	andi	a5,a5,511
    80004b8c:	97a6                	add	a5,a5,s1
    80004b8e:	faf44703          	lbu	a4,-81(s0)
    80004b92:	00e78c23          	sb	a4,24(a5)
      i++;
    80004b96:	2905                	addiw	s2,s2,1
    80004b98:	b755                	j	80004b3c <pipewrite+0x80>
  int i = 0;
    80004b9a:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004b9c:	21848513          	addi	a0,s1,536
    80004ba0:	ffffd097          	auipc	ra,0xffffd
    80004ba4:	552080e7          	jalr	1362(ra) # 800020f2 <wakeup>
  release(&pi->lock);
    80004ba8:	8526                	mv	a0,s1
    80004baa:	ffffc097          	auipc	ra,0xffffc
    80004bae:	0e0080e7          	jalr	224(ra) # 80000c8a <release>
  return i;
    80004bb2:	bfa9                	j	80004b0c <pipewrite+0x50>

0000000080004bb4 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004bb4:	715d                	addi	sp,sp,-80
    80004bb6:	e486                	sd	ra,72(sp)
    80004bb8:	e0a2                	sd	s0,64(sp)
    80004bba:	fc26                	sd	s1,56(sp)
    80004bbc:	f84a                	sd	s2,48(sp)
    80004bbe:	f44e                	sd	s3,40(sp)
    80004bc0:	f052                	sd	s4,32(sp)
    80004bc2:	ec56                	sd	s5,24(sp)
    80004bc4:	e85a                	sd	s6,16(sp)
    80004bc6:	0880                	addi	s0,sp,80
    80004bc8:	84aa                	mv	s1,a0
    80004bca:	892e                	mv	s2,a1
    80004bcc:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004bce:	ffffd097          	auipc	ra,0xffffd
    80004bd2:	dde080e7          	jalr	-546(ra) # 800019ac <myproc>
    80004bd6:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004bd8:	8526                	mv	a0,s1
    80004bda:	ffffc097          	auipc	ra,0xffffc
    80004bde:	ffc080e7          	jalr	-4(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004be2:	2184a703          	lw	a4,536(s1)
    80004be6:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bea:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bee:	02f71763          	bne	a4,a5,80004c1c <piperead+0x68>
    80004bf2:	2244a783          	lw	a5,548(s1)
    80004bf6:	c39d                	beqz	a5,80004c1c <piperead+0x68>
    if(killed(pr)){
    80004bf8:	8552                	mv	a0,s4
    80004bfa:	ffffd097          	auipc	ra,0xffffd
    80004bfe:	73c080e7          	jalr	1852(ra) # 80002336 <killed>
    80004c02:	e949                	bnez	a0,80004c94 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c04:	85a6                	mv	a1,s1
    80004c06:	854e                	mv	a0,s3
    80004c08:	ffffd097          	auipc	ra,0xffffd
    80004c0c:	486080e7          	jalr	1158(ra) # 8000208e <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c10:	2184a703          	lw	a4,536(s1)
    80004c14:	21c4a783          	lw	a5,540(s1)
    80004c18:	fcf70de3          	beq	a4,a5,80004bf2 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c1c:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c1e:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c20:	05505463          	blez	s5,80004c68 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004c24:	2184a783          	lw	a5,536(s1)
    80004c28:	21c4a703          	lw	a4,540(s1)
    80004c2c:	02f70e63          	beq	a4,a5,80004c68 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c30:	0017871b          	addiw	a4,a5,1
    80004c34:	20e4ac23          	sw	a4,536(s1)
    80004c38:	1ff7f793          	andi	a5,a5,511
    80004c3c:	97a6                	add	a5,a5,s1
    80004c3e:	0187c783          	lbu	a5,24(a5)
    80004c42:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c46:	4685                	li	a3,1
    80004c48:	fbf40613          	addi	a2,s0,-65
    80004c4c:	85ca                	mv	a1,s2
    80004c4e:	050a3503          	ld	a0,80(s4)
    80004c52:	ffffd097          	auipc	ra,0xffffd
    80004c56:	a1a080e7          	jalr	-1510(ra) # 8000166c <copyout>
    80004c5a:	01650763          	beq	a0,s6,80004c68 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c5e:	2985                	addiw	s3,s3,1
    80004c60:	0905                	addi	s2,s2,1
    80004c62:	fd3a91e3          	bne	s5,s3,80004c24 <piperead+0x70>
    80004c66:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c68:	21c48513          	addi	a0,s1,540
    80004c6c:	ffffd097          	auipc	ra,0xffffd
    80004c70:	486080e7          	jalr	1158(ra) # 800020f2 <wakeup>
  release(&pi->lock);
    80004c74:	8526                	mv	a0,s1
    80004c76:	ffffc097          	auipc	ra,0xffffc
    80004c7a:	014080e7          	jalr	20(ra) # 80000c8a <release>
  return i;
}
    80004c7e:	854e                	mv	a0,s3
    80004c80:	60a6                	ld	ra,72(sp)
    80004c82:	6406                	ld	s0,64(sp)
    80004c84:	74e2                	ld	s1,56(sp)
    80004c86:	7942                	ld	s2,48(sp)
    80004c88:	79a2                	ld	s3,40(sp)
    80004c8a:	7a02                	ld	s4,32(sp)
    80004c8c:	6ae2                	ld	s5,24(sp)
    80004c8e:	6b42                	ld	s6,16(sp)
    80004c90:	6161                	addi	sp,sp,80
    80004c92:	8082                	ret
      release(&pi->lock);
    80004c94:	8526                	mv	a0,s1
    80004c96:	ffffc097          	auipc	ra,0xffffc
    80004c9a:	ff4080e7          	jalr	-12(ra) # 80000c8a <release>
      return -1;
    80004c9e:	59fd                	li	s3,-1
    80004ca0:	bff9                	j	80004c7e <piperead+0xca>

0000000080004ca2 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004ca2:	1141                	addi	sp,sp,-16
    80004ca4:	e422                	sd	s0,8(sp)
    80004ca6:	0800                	addi	s0,sp,16
    80004ca8:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004caa:	8905                	andi	a0,a0,1
    80004cac:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004cae:	8b89                	andi	a5,a5,2
    80004cb0:	c399                	beqz	a5,80004cb6 <flags2perm+0x14>
      perm |= PTE_W;
    80004cb2:	00456513          	ori	a0,a0,4
    return perm;
}
    80004cb6:	6422                	ld	s0,8(sp)
    80004cb8:	0141                	addi	sp,sp,16
    80004cba:	8082                	ret

0000000080004cbc <exec>:

int
exec(char *path, char **argv)
{
    80004cbc:	de010113          	addi	sp,sp,-544
    80004cc0:	20113c23          	sd	ra,536(sp)
    80004cc4:	20813823          	sd	s0,528(sp)
    80004cc8:	20913423          	sd	s1,520(sp)
    80004ccc:	21213023          	sd	s2,512(sp)
    80004cd0:	ffce                	sd	s3,504(sp)
    80004cd2:	fbd2                	sd	s4,496(sp)
    80004cd4:	f7d6                	sd	s5,488(sp)
    80004cd6:	f3da                	sd	s6,480(sp)
    80004cd8:	efde                	sd	s7,472(sp)
    80004cda:	ebe2                	sd	s8,464(sp)
    80004cdc:	e7e6                	sd	s9,456(sp)
    80004cde:	e3ea                	sd	s10,448(sp)
    80004ce0:	ff6e                	sd	s11,440(sp)
    80004ce2:	1400                	addi	s0,sp,544
    80004ce4:	892a                	mv	s2,a0
    80004ce6:	dea43423          	sd	a0,-536(s0)
    80004cea:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004cee:	ffffd097          	auipc	ra,0xffffd
    80004cf2:	cbe080e7          	jalr	-834(ra) # 800019ac <myproc>
    80004cf6:	84aa                	mv	s1,a0

  begin_op();
    80004cf8:	fffff097          	auipc	ra,0xfffff
    80004cfc:	482080e7          	jalr	1154(ra) # 8000417a <begin_op>

  if((ip = namei(path)) == 0){
    80004d00:	854a                	mv	a0,s2
    80004d02:	fffff097          	auipc	ra,0xfffff
    80004d06:	258080e7          	jalr	600(ra) # 80003f5a <namei>
    80004d0a:	c93d                	beqz	a0,80004d80 <exec+0xc4>
    80004d0c:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d0e:	fffff097          	auipc	ra,0xfffff
    80004d12:	aa0080e7          	jalr	-1376(ra) # 800037ae <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d16:	04000713          	li	a4,64
    80004d1a:	4681                	li	a3,0
    80004d1c:	e5040613          	addi	a2,s0,-432
    80004d20:	4581                	li	a1,0
    80004d22:	8556                	mv	a0,s5
    80004d24:	fffff097          	auipc	ra,0xfffff
    80004d28:	d3e080e7          	jalr	-706(ra) # 80003a62 <readi>
    80004d2c:	04000793          	li	a5,64
    80004d30:	00f51a63          	bne	a0,a5,80004d44 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004d34:	e5042703          	lw	a4,-432(s0)
    80004d38:	464c47b7          	lui	a5,0x464c4
    80004d3c:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d40:	04f70663          	beq	a4,a5,80004d8c <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d44:	8556                	mv	a0,s5
    80004d46:	fffff097          	auipc	ra,0xfffff
    80004d4a:	cca080e7          	jalr	-822(ra) # 80003a10 <iunlockput>
    end_op();
    80004d4e:	fffff097          	auipc	ra,0xfffff
    80004d52:	4aa080e7          	jalr	1194(ra) # 800041f8 <end_op>
  }
  return -1;
    80004d56:	557d                	li	a0,-1
}
    80004d58:	21813083          	ld	ra,536(sp)
    80004d5c:	21013403          	ld	s0,528(sp)
    80004d60:	20813483          	ld	s1,520(sp)
    80004d64:	20013903          	ld	s2,512(sp)
    80004d68:	79fe                	ld	s3,504(sp)
    80004d6a:	7a5e                	ld	s4,496(sp)
    80004d6c:	7abe                	ld	s5,488(sp)
    80004d6e:	7b1e                	ld	s6,480(sp)
    80004d70:	6bfe                	ld	s7,472(sp)
    80004d72:	6c5e                	ld	s8,464(sp)
    80004d74:	6cbe                	ld	s9,456(sp)
    80004d76:	6d1e                	ld	s10,448(sp)
    80004d78:	7dfa                	ld	s11,440(sp)
    80004d7a:	22010113          	addi	sp,sp,544
    80004d7e:	8082                	ret
    end_op();
    80004d80:	fffff097          	auipc	ra,0xfffff
    80004d84:	478080e7          	jalr	1144(ra) # 800041f8 <end_op>
    return -1;
    80004d88:	557d                	li	a0,-1
    80004d8a:	b7f9                	j	80004d58 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d8c:	8526                	mv	a0,s1
    80004d8e:	ffffd097          	auipc	ra,0xffffd
    80004d92:	ce2080e7          	jalr	-798(ra) # 80001a70 <proc_pagetable>
    80004d96:	8b2a                	mv	s6,a0
    80004d98:	d555                	beqz	a0,80004d44 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d9a:	e7042783          	lw	a5,-400(s0)
    80004d9e:	e8845703          	lhu	a4,-376(s0)
    80004da2:	c735                	beqz	a4,80004e0e <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004da4:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004da6:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004daa:	6a05                	lui	s4,0x1
    80004dac:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004db0:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004db4:	6d85                	lui	s11,0x1
    80004db6:	7d7d                	lui	s10,0xfffff
    80004db8:	ac3d                	j	80004ff6 <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004dba:	00004517          	auipc	a0,0x4
    80004dbe:	a4e50513          	addi	a0,a0,-1458 # 80008808 <syscalls+0x280>
    80004dc2:	ffffb097          	auipc	ra,0xffffb
    80004dc6:	77e080e7          	jalr	1918(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004dca:	874a                	mv	a4,s2
    80004dcc:	009c86bb          	addw	a3,s9,s1
    80004dd0:	4581                	li	a1,0
    80004dd2:	8556                	mv	a0,s5
    80004dd4:	fffff097          	auipc	ra,0xfffff
    80004dd8:	c8e080e7          	jalr	-882(ra) # 80003a62 <readi>
    80004ddc:	2501                	sext.w	a0,a0
    80004dde:	1aa91963          	bne	s2,a0,80004f90 <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    80004de2:	009d84bb          	addw	s1,s11,s1
    80004de6:	013d09bb          	addw	s3,s10,s3
    80004dea:	1f74f663          	bgeu	s1,s7,80004fd6 <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    80004dee:	02049593          	slli	a1,s1,0x20
    80004df2:	9181                	srli	a1,a1,0x20
    80004df4:	95e2                	add	a1,a1,s8
    80004df6:	855a                	mv	a0,s6
    80004df8:	ffffc097          	auipc	ra,0xffffc
    80004dfc:	264080e7          	jalr	612(ra) # 8000105c <walkaddr>
    80004e00:	862a                	mv	a2,a0
    if(pa == 0)
    80004e02:	dd45                	beqz	a0,80004dba <exec+0xfe>
      n = PGSIZE;
    80004e04:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004e06:	fd49f2e3          	bgeu	s3,s4,80004dca <exec+0x10e>
      n = sz - i;
    80004e0a:	894e                	mv	s2,s3
    80004e0c:	bf7d                	j	80004dca <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e0e:	4901                	li	s2,0
  iunlockput(ip);
    80004e10:	8556                	mv	a0,s5
    80004e12:	fffff097          	auipc	ra,0xfffff
    80004e16:	bfe080e7          	jalr	-1026(ra) # 80003a10 <iunlockput>
  end_op();
    80004e1a:	fffff097          	auipc	ra,0xfffff
    80004e1e:	3de080e7          	jalr	990(ra) # 800041f8 <end_op>
  p = myproc();
    80004e22:	ffffd097          	auipc	ra,0xffffd
    80004e26:	b8a080e7          	jalr	-1142(ra) # 800019ac <myproc>
    80004e2a:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004e2c:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e30:	6785                	lui	a5,0x1
    80004e32:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80004e34:	97ca                	add	a5,a5,s2
    80004e36:	777d                	lui	a4,0xfffff
    80004e38:	8ff9                	and	a5,a5,a4
    80004e3a:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004e3e:	4691                	li	a3,4
    80004e40:	6609                	lui	a2,0x2
    80004e42:	963e                	add	a2,a2,a5
    80004e44:	85be                	mv	a1,a5
    80004e46:	855a                	mv	a0,s6
    80004e48:	ffffc097          	auipc	ra,0xffffc
    80004e4c:	5c8080e7          	jalr	1480(ra) # 80001410 <uvmalloc>
    80004e50:	8c2a                	mv	s8,a0
  ip = 0;
    80004e52:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004e54:	12050e63          	beqz	a0,80004f90 <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e58:	75f9                	lui	a1,0xffffe
    80004e5a:	95aa                	add	a1,a1,a0
    80004e5c:	855a                	mv	a0,s6
    80004e5e:	ffffc097          	auipc	ra,0xffffc
    80004e62:	7dc080e7          	jalr	2012(ra) # 8000163a <uvmclear>
  stackbase = sp - PGSIZE;
    80004e66:	7afd                	lui	s5,0xfffff
    80004e68:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e6a:	df043783          	ld	a5,-528(s0)
    80004e6e:	6388                	ld	a0,0(a5)
    80004e70:	c925                	beqz	a0,80004ee0 <exec+0x224>
    80004e72:	e9040993          	addi	s3,s0,-368
    80004e76:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004e7a:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e7c:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004e7e:	ffffc097          	auipc	ra,0xffffc
    80004e82:	fd0080e7          	jalr	-48(ra) # 80000e4e <strlen>
    80004e86:	0015079b          	addiw	a5,a0,1
    80004e8a:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e8e:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004e92:	13596663          	bltu	s2,s5,80004fbe <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e96:	df043d83          	ld	s11,-528(s0)
    80004e9a:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004e9e:	8552                	mv	a0,s4
    80004ea0:	ffffc097          	auipc	ra,0xffffc
    80004ea4:	fae080e7          	jalr	-82(ra) # 80000e4e <strlen>
    80004ea8:	0015069b          	addiw	a3,a0,1
    80004eac:	8652                	mv	a2,s4
    80004eae:	85ca                	mv	a1,s2
    80004eb0:	855a                	mv	a0,s6
    80004eb2:	ffffc097          	auipc	ra,0xffffc
    80004eb6:	7ba080e7          	jalr	1978(ra) # 8000166c <copyout>
    80004eba:	10054663          	bltz	a0,80004fc6 <exec+0x30a>
    ustack[argc] = sp;
    80004ebe:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004ec2:	0485                	addi	s1,s1,1
    80004ec4:	008d8793          	addi	a5,s11,8
    80004ec8:	def43823          	sd	a5,-528(s0)
    80004ecc:	008db503          	ld	a0,8(s11)
    80004ed0:	c911                	beqz	a0,80004ee4 <exec+0x228>
    if(argc >= MAXARG)
    80004ed2:	09a1                	addi	s3,s3,8
    80004ed4:	fb3c95e3          	bne	s9,s3,80004e7e <exec+0x1c2>
  sz = sz1;
    80004ed8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004edc:	4a81                	li	s5,0
    80004ede:	a84d                	j	80004f90 <exec+0x2d4>
  sp = sz;
    80004ee0:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004ee2:	4481                	li	s1,0
  ustack[argc] = 0;
    80004ee4:	00349793          	slli	a5,s1,0x3
    80004ee8:	f9078793          	addi	a5,a5,-112
    80004eec:	97a2                	add	a5,a5,s0
    80004eee:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004ef2:	00148693          	addi	a3,s1,1
    80004ef6:	068e                	slli	a3,a3,0x3
    80004ef8:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004efc:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004f00:	01597663          	bgeu	s2,s5,80004f0c <exec+0x250>
  sz = sz1;
    80004f04:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f08:	4a81                	li	s5,0
    80004f0a:	a059                	j	80004f90 <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f0c:	e9040613          	addi	a2,s0,-368
    80004f10:	85ca                	mv	a1,s2
    80004f12:	855a                	mv	a0,s6
    80004f14:	ffffc097          	auipc	ra,0xffffc
    80004f18:	758080e7          	jalr	1880(ra) # 8000166c <copyout>
    80004f1c:	0a054963          	bltz	a0,80004fce <exec+0x312>
  p->trapframe->a1 = sp;
    80004f20:	058bb783          	ld	a5,88(s7)
    80004f24:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f28:	de843783          	ld	a5,-536(s0)
    80004f2c:	0007c703          	lbu	a4,0(a5)
    80004f30:	cf11                	beqz	a4,80004f4c <exec+0x290>
    80004f32:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f34:	02f00693          	li	a3,47
    80004f38:	a039                	j	80004f46 <exec+0x28a>
      last = s+1;
    80004f3a:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004f3e:	0785                	addi	a5,a5,1
    80004f40:	fff7c703          	lbu	a4,-1(a5)
    80004f44:	c701                	beqz	a4,80004f4c <exec+0x290>
    if(*s == '/')
    80004f46:	fed71ce3          	bne	a4,a3,80004f3e <exec+0x282>
    80004f4a:	bfc5                	j	80004f3a <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f4c:	4641                	li	a2,16
    80004f4e:	de843583          	ld	a1,-536(s0)
    80004f52:	158b8513          	addi	a0,s7,344
    80004f56:	ffffc097          	auipc	ra,0xffffc
    80004f5a:	ec6080e7          	jalr	-314(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    80004f5e:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004f62:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004f66:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f6a:	058bb783          	ld	a5,88(s7)
    80004f6e:	e6843703          	ld	a4,-408(s0)
    80004f72:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f74:	058bb783          	ld	a5,88(s7)
    80004f78:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f7c:	85ea                	mv	a1,s10
    80004f7e:	ffffd097          	auipc	ra,0xffffd
    80004f82:	b8e080e7          	jalr	-1138(ra) # 80001b0c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f86:	0004851b          	sext.w	a0,s1
    80004f8a:	b3f9                	j	80004d58 <exec+0x9c>
    80004f8c:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004f90:	df843583          	ld	a1,-520(s0)
    80004f94:	855a                	mv	a0,s6
    80004f96:	ffffd097          	auipc	ra,0xffffd
    80004f9a:	b76080e7          	jalr	-1162(ra) # 80001b0c <proc_freepagetable>
  if(ip){
    80004f9e:	da0a93e3          	bnez	s5,80004d44 <exec+0x88>
  return -1;
    80004fa2:	557d                	li	a0,-1
    80004fa4:	bb55                	j	80004d58 <exec+0x9c>
    80004fa6:	df243c23          	sd	s2,-520(s0)
    80004faa:	b7dd                	j	80004f90 <exec+0x2d4>
    80004fac:	df243c23          	sd	s2,-520(s0)
    80004fb0:	b7c5                	j	80004f90 <exec+0x2d4>
    80004fb2:	df243c23          	sd	s2,-520(s0)
    80004fb6:	bfe9                	j	80004f90 <exec+0x2d4>
    80004fb8:	df243c23          	sd	s2,-520(s0)
    80004fbc:	bfd1                	j	80004f90 <exec+0x2d4>
  sz = sz1;
    80004fbe:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004fc2:	4a81                	li	s5,0
    80004fc4:	b7f1                	j	80004f90 <exec+0x2d4>
  sz = sz1;
    80004fc6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004fca:	4a81                	li	s5,0
    80004fcc:	b7d1                	j	80004f90 <exec+0x2d4>
  sz = sz1;
    80004fce:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004fd2:	4a81                	li	s5,0
    80004fd4:	bf75                	j	80004f90 <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004fd6:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fda:	e0843783          	ld	a5,-504(s0)
    80004fde:	0017869b          	addiw	a3,a5,1
    80004fe2:	e0d43423          	sd	a3,-504(s0)
    80004fe6:	e0043783          	ld	a5,-512(s0)
    80004fea:	0387879b          	addiw	a5,a5,56
    80004fee:	e8845703          	lhu	a4,-376(s0)
    80004ff2:	e0e6dfe3          	bge	a3,a4,80004e10 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004ff6:	2781                	sext.w	a5,a5
    80004ff8:	e0f43023          	sd	a5,-512(s0)
    80004ffc:	03800713          	li	a4,56
    80005000:	86be                	mv	a3,a5
    80005002:	e1840613          	addi	a2,s0,-488
    80005006:	4581                	li	a1,0
    80005008:	8556                	mv	a0,s5
    8000500a:	fffff097          	auipc	ra,0xfffff
    8000500e:	a58080e7          	jalr	-1448(ra) # 80003a62 <readi>
    80005012:	03800793          	li	a5,56
    80005016:	f6f51be3          	bne	a0,a5,80004f8c <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    8000501a:	e1842783          	lw	a5,-488(s0)
    8000501e:	4705                	li	a4,1
    80005020:	fae79de3          	bne	a5,a4,80004fda <exec+0x31e>
    if(ph.memsz < ph.filesz)
    80005024:	e4043483          	ld	s1,-448(s0)
    80005028:	e3843783          	ld	a5,-456(s0)
    8000502c:	f6f4ede3          	bltu	s1,a5,80004fa6 <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005030:	e2843783          	ld	a5,-472(s0)
    80005034:	94be                	add	s1,s1,a5
    80005036:	f6f4ebe3          	bltu	s1,a5,80004fac <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    8000503a:	de043703          	ld	a4,-544(s0)
    8000503e:	8ff9                	and	a5,a5,a4
    80005040:	fbad                	bnez	a5,80004fb2 <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005042:	e1c42503          	lw	a0,-484(s0)
    80005046:	00000097          	auipc	ra,0x0
    8000504a:	c5c080e7          	jalr	-932(ra) # 80004ca2 <flags2perm>
    8000504e:	86aa                	mv	a3,a0
    80005050:	8626                	mv	a2,s1
    80005052:	85ca                	mv	a1,s2
    80005054:	855a                	mv	a0,s6
    80005056:	ffffc097          	auipc	ra,0xffffc
    8000505a:	3ba080e7          	jalr	954(ra) # 80001410 <uvmalloc>
    8000505e:	dea43c23          	sd	a0,-520(s0)
    80005062:	d939                	beqz	a0,80004fb8 <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005064:	e2843c03          	ld	s8,-472(s0)
    80005068:	e2042c83          	lw	s9,-480(s0)
    8000506c:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005070:	f60b83e3          	beqz	s7,80004fd6 <exec+0x31a>
    80005074:	89de                	mv	s3,s7
    80005076:	4481                	li	s1,0
    80005078:	bb9d                	j	80004dee <exec+0x132>

000000008000507a <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000507a:	7179                	addi	sp,sp,-48
    8000507c:	f406                	sd	ra,40(sp)
    8000507e:	f022                	sd	s0,32(sp)
    80005080:	ec26                	sd	s1,24(sp)
    80005082:	e84a                	sd	s2,16(sp)
    80005084:	1800                	addi	s0,sp,48
    80005086:	892e                	mv	s2,a1
    80005088:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    8000508a:	fdc40593          	addi	a1,s0,-36
    8000508e:	ffffe097          	auipc	ra,0xffffe
    80005092:	a6e080e7          	jalr	-1426(ra) # 80002afc <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005096:	fdc42703          	lw	a4,-36(s0)
    8000509a:	47bd                	li	a5,15
    8000509c:	02e7eb63          	bltu	a5,a4,800050d2 <argfd+0x58>
    800050a0:	ffffd097          	auipc	ra,0xffffd
    800050a4:	90c080e7          	jalr	-1780(ra) # 800019ac <myproc>
    800050a8:	fdc42703          	lw	a4,-36(s0)
    800050ac:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffd0e9a>
    800050b0:	078e                	slli	a5,a5,0x3
    800050b2:	953e                	add	a0,a0,a5
    800050b4:	611c                	ld	a5,0(a0)
    800050b6:	c385                	beqz	a5,800050d6 <argfd+0x5c>
    return -1;
  if(pfd)
    800050b8:	00090463          	beqz	s2,800050c0 <argfd+0x46>
    *pfd = fd;
    800050bc:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800050c0:	4501                	li	a0,0
  if(pf)
    800050c2:	c091                	beqz	s1,800050c6 <argfd+0x4c>
    *pf = f;
    800050c4:	e09c                	sd	a5,0(s1)
}
    800050c6:	70a2                	ld	ra,40(sp)
    800050c8:	7402                	ld	s0,32(sp)
    800050ca:	64e2                	ld	s1,24(sp)
    800050cc:	6942                	ld	s2,16(sp)
    800050ce:	6145                	addi	sp,sp,48
    800050d0:	8082                	ret
    return -1;
    800050d2:	557d                	li	a0,-1
    800050d4:	bfcd                	j	800050c6 <argfd+0x4c>
    800050d6:	557d                	li	a0,-1
    800050d8:	b7fd                	j	800050c6 <argfd+0x4c>

00000000800050da <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800050da:	1101                	addi	sp,sp,-32
    800050dc:	ec06                	sd	ra,24(sp)
    800050de:	e822                	sd	s0,16(sp)
    800050e0:	e426                	sd	s1,8(sp)
    800050e2:	1000                	addi	s0,sp,32
    800050e4:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800050e6:	ffffd097          	auipc	ra,0xffffd
    800050ea:	8c6080e7          	jalr	-1850(ra) # 800019ac <myproc>
    800050ee:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800050f0:	0d050793          	addi	a5,a0,208
    800050f4:	4501                	li	a0,0
    800050f6:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800050f8:	6398                	ld	a4,0(a5)
    800050fa:	cb19                	beqz	a4,80005110 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800050fc:	2505                	addiw	a0,a0,1
    800050fe:	07a1                	addi	a5,a5,8
    80005100:	fed51ce3          	bne	a0,a3,800050f8 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005104:	557d                	li	a0,-1
}
    80005106:	60e2                	ld	ra,24(sp)
    80005108:	6442                	ld	s0,16(sp)
    8000510a:	64a2                	ld	s1,8(sp)
    8000510c:	6105                	addi	sp,sp,32
    8000510e:	8082                	ret
      p->ofile[fd] = f;
    80005110:	01a50793          	addi	a5,a0,26
    80005114:	078e                	slli	a5,a5,0x3
    80005116:	963e                	add	a2,a2,a5
    80005118:	e204                	sd	s1,0(a2)
      return fd;
    8000511a:	b7f5                	j	80005106 <fdalloc+0x2c>

000000008000511c <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000511c:	715d                	addi	sp,sp,-80
    8000511e:	e486                	sd	ra,72(sp)
    80005120:	e0a2                	sd	s0,64(sp)
    80005122:	fc26                	sd	s1,56(sp)
    80005124:	f84a                	sd	s2,48(sp)
    80005126:	f44e                	sd	s3,40(sp)
    80005128:	f052                	sd	s4,32(sp)
    8000512a:	ec56                	sd	s5,24(sp)
    8000512c:	e85a                	sd	s6,16(sp)
    8000512e:	0880                	addi	s0,sp,80
    80005130:	8b2e                	mv	s6,a1
    80005132:	89b2                	mv	s3,a2
    80005134:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005136:	fb040593          	addi	a1,s0,-80
    8000513a:	fffff097          	auipc	ra,0xfffff
    8000513e:	e3e080e7          	jalr	-450(ra) # 80003f78 <nameiparent>
    80005142:	84aa                	mv	s1,a0
    80005144:	14050f63          	beqz	a0,800052a2 <create+0x186>
    return 0;

  ilock(dp);
    80005148:	ffffe097          	auipc	ra,0xffffe
    8000514c:	666080e7          	jalr	1638(ra) # 800037ae <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005150:	4601                	li	a2,0
    80005152:	fb040593          	addi	a1,s0,-80
    80005156:	8526                	mv	a0,s1
    80005158:	fffff097          	auipc	ra,0xfffff
    8000515c:	b3a080e7          	jalr	-1222(ra) # 80003c92 <dirlookup>
    80005160:	8aaa                	mv	s5,a0
    80005162:	c931                	beqz	a0,800051b6 <create+0x9a>
    iunlockput(dp);
    80005164:	8526                	mv	a0,s1
    80005166:	fffff097          	auipc	ra,0xfffff
    8000516a:	8aa080e7          	jalr	-1878(ra) # 80003a10 <iunlockput>
    ilock(ip);
    8000516e:	8556                	mv	a0,s5
    80005170:	ffffe097          	auipc	ra,0xffffe
    80005174:	63e080e7          	jalr	1598(ra) # 800037ae <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005178:	000b059b          	sext.w	a1,s6
    8000517c:	4789                	li	a5,2
    8000517e:	02f59563          	bne	a1,a5,800051a8 <create+0x8c>
    80005182:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffd0ec4>
    80005186:	37f9                	addiw	a5,a5,-2
    80005188:	17c2                	slli	a5,a5,0x30
    8000518a:	93c1                	srli	a5,a5,0x30
    8000518c:	4705                	li	a4,1
    8000518e:	00f76d63          	bltu	a4,a5,800051a8 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005192:	8556                	mv	a0,s5
    80005194:	60a6                	ld	ra,72(sp)
    80005196:	6406                	ld	s0,64(sp)
    80005198:	74e2                	ld	s1,56(sp)
    8000519a:	7942                	ld	s2,48(sp)
    8000519c:	79a2                	ld	s3,40(sp)
    8000519e:	7a02                	ld	s4,32(sp)
    800051a0:	6ae2                	ld	s5,24(sp)
    800051a2:	6b42                	ld	s6,16(sp)
    800051a4:	6161                	addi	sp,sp,80
    800051a6:	8082                	ret
    iunlockput(ip);
    800051a8:	8556                	mv	a0,s5
    800051aa:	fffff097          	auipc	ra,0xfffff
    800051ae:	866080e7          	jalr	-1946(ra) # 80003a10 <iunlockput>
    return 0;
    800051b2:	4a81                	li	s5,0
    800051b4:	bff9                	j	80005192 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800051b6:	85da                	mv	a1,s6
    800051b8:	4088                	lw	a0,0(s1)
    800051ba:	ffffe097          	auipc	ra,0xffffe
    800051be:	456080e7          	jalr	1110(ra) # 80003610 <ialloc>
    800051c2:	8a2a                	mv	s4,a0
    800051c4:	c539                	beqz	a0,80005212 <create+0xf6>
  ilock(ip);
    800051c6:	ffffe097          	auipc	ra,0xffffe
    800051ca:	5e8080e7          	jalr	1512(ra) # 800037ae <ilock>
  ip->major = major;
    800051ce:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800051d2:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800051d6:	4905                	li	s2,1
    800051d8:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    800051dc:	8552                	mv	a0,s4
    800051de:	ffffe097          	auipc	ra,0xffffe
    800051e2:	504080e7          	jalr	1284(ra) # 800036e2 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800051e6:	000b059b          	sext.w	a1,s6
    800051ea:	03258b63          	beq	a1,s2,80005220 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    800051ee:	004a2603          	lw	a2,4(s4)
    800051f2:	fb040593          	addi	a1,s0,-80
    800051f6:	8526                	mv	a0,s1
    800051f8:	fffff097          	auipc	ra,0xfffff
    800051fc:	cb0080e7          	jalr	-848(ra) # 80003ea8 <dirlink>
    80005200:	06054f63          	bltz	a0,8000527e <create+0x162>
  iunlockput(dp);
    80005204:	8526                	mv	a0,s1
    80005206:	fffff097          	auipc	ra,0xfffff
    8000520a:	80a080e7          	jalr	-2038(ra) # 80003a10 <iunlockput>
  return ip;
    8000520e:	8ad2                	mv	s5,s4
    80005210:	b749                	j	80005192 <create+0x76>
    iunlockput(dp);
    80005212:	8526                	mv	a0,s1
    80005214:	ffffe097          	auipc	ra,0xffffe
    80005218:	7fc080e7          	jalr	2044(ra) # 80003a10 <iunlockput>
    return 0;
    8000521c:	8ad2                	mv	s5,s4
    8000521e:	bf95                	j	80005192 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005220:	004a2603          	lw	a2,4(s4)
    80005224:	00003597          	auipc	a1,0x3
    80005228:	60458593          	addi	a1,a1,1540 # 80008828 <syscalls+0x2a0>
    8000522c:	8552                	mv	a0,s4
    8000522e:	fffff097          	auipc	ra,0xfffff
    80005232:	c7a080e7          	jalr	-902(ra) # 80003ea8 <dirlink>
    80005236:	04054463          	bltz	a0,8000527e <create+0x162>
    8000523a:	40d0                	lw	a2,4(s1)
    8000523c:	00003597          	auipc	a1,0x3
    80005240:	5f458593          	addi	a1,a1,1524 # 80008830 <syscalls+0x2a8>
    80005244:	8552                	mv	a0,s4
    80005246:	fffff097          	auipc	ra,0xfffff
    8000524a:	c62080e7          	jalr	-926(ra) # 80003ea8 <dirlink>
    8000524e:	02054863          	bltz	a0,8000527e <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    80005252:	004a2603          	lw	a2,4(s4)
    80005256:	fb040593          	addi	a1,s0,-80
    8000525a:	8526                	mv	a0,s1
    8000525c:	fffff097          	auipc	ra,0xfffff
    80005260:	c4c080e7          	jalr	-948(ra) # 80003ea8 <dirlink>
    80005264:	00054d63          	bltz	a0,8000527e <create+0x162>
    dp->nlink++;  // for ".."
    80005268:	04a4d783          	lhu	a5,74(s1)
    8000526c:	2785                	addiw	a5,a5,1
    8000526e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005272:	8526                	mv	a0,s1
    80005274:	ffffe097          	auipc	ra,0xffffe
    80005278:	46e080e7          	jalr	1134(ra) # 800036e2 <iupdate>
    8000527c:	b761                	j	80005204 <create+0xe8>
  ip->nlink = 0;
    8000527e:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005282:	8552                	mv	a0,s4
    80005284:	ffffe097          	auipc	ra,0xffffe
    80005288:	45e080e7          	jalr	1118(ra) # 800036e2 <iupdate>
  iunlockput(ip);
    8000528c:	8552                	mv	a0,s4
    8000528e:	ffffe097          	auipc	ra,0xffffe
    80005292:	782080e7          	jalr	1922(ra) # 80003a10 <iunlockput>
  iunlockput(dp);
    80005296:	8526                	mv	a0,s1
    80005298:	ffffe097          	auipc	ra,0xffffe
    8000529c:	778080e7          	jalr	1912(ra) # 80003a10 <iunlockput>
  return 0;
    800052a0:	bdcd                	j	80005192 <create+0x76>
    return 0;
    800052a2:	8aaa                	mv	s5,a0
    800052a4:	b5fd                	j	80005192 <create+0x76>

00000000800052a6 <sys_dup>:
{
    800052a6:	7179                	addi	sp,sp,-48
    800052a8:	f406                	sd	ra,40(sp)
    800052aa:	f022                	sd	s0,32(sp)
    800052ac:	ec26                	sd	s1,24(sp)
    800052ae:	e84a                	sd	s2,16(sp)
    800052b0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800052b2:	fd840613          	addi	a2,s0,-40
    800052b6:	4581                	li	a1,0
    800052b8:	4501                	li	a0,0
    800052ba:	00000097          	auipc	ra,0x0
    800052be:	dc0080e7          	jalr	-576(ra) # 8000507a <argfd>
    return -1;
    800052c2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800052c4:	02054363          	bltz	a0,800052ea <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    800052c8:	fd843903          	ld	s2,-40(s0)
    800052cc:	854a                	mv	a0,s2
    800052ce:	00000097          	auipc	ra,0x0
    800052d2:	e0c080e7          	jalr	-500(ra) # 800050da <fdalloc>
    800052d6:	84aa                	mv	s1,a0
    return -1;
    800052d8:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800052da:	00054863          	bltz	a0,800052ea <sys_dup+0x44>
  filedup(f);
    800052de:	854a                	mv	a0,s2
    800052e0:	fffff097          	auipc	ra,0xfffff
    800052e4:	310080e7          	jalr	784(ra) # 800045f0 <filedup>
  return fd;
    800052e8:	87a6                	mv	a5,s1
}
    800052ea:	853e                	mv	a0,a5
    800052ec:	70a2                	ld	ra,40(sp)
    800052ee:	7402                	ld	s0,32(sp)
    800052f0:	64e2                	ld	s1,24(sp)
    800052f2:	6942                	ld	s2,16(sp)
    800052f4:	6145                	addi	sp,sp,48
    800052f6:	8082                	ret

00000000800052f8 <sys_read>:
{
    800052f8:	7179                	addi	sp,sp,-48
    800052fa:	f406                	sd	ra,40(sp)
    800052fc:	f022                	sd	s0,32(sp)
    800052fe:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005300:	fd840593          	addi	a1,s0,-40
    80005304:	4505                	li	a0,1
    80005306:	ffffe097          	auipc	ra,0xffffe
    8000530a:	816080e7          	jalr	-2026(ra) # 80002b1c <argaddr>
  argint(2, &n);
    8000530e:	fe440593          	addi	a1,s0,-28
    80005312:	4509                	li	a0,2
    80005314:	ffffd097          	auipc	ra,0xffffd
    80005318:	7e8080e7          	jalr	2024(ra) # 80002afc <argint>
  if(argfd(0, 0, &f) < 0)
    8000531c:	fe840613          	addi	a2,s0,-24
    80005320:	4581                	li	a1,0
    80005322:	4501                	li	a0,0
    80005324:	00000097          	auipc	ra,0x0
    80005328:	d56080e7          	jalr	-682(ra) # 8000507a <argfd>
    8000532c:	87aa                	mv	a5,a0
    return -1;
    8000532e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005330:	0007cc63          	bltz	a5,80005348 <sys_read+0x50>
  return fileread(f, p, n);
    80005334:	fe442603          	lw	a2,-28(s0)
    80005338:	fd843583          	ld	a1,-40(s0)
    8000533c:	fe843503          	ld	a0,-24(s0)
    80005340:	fffff097          	auipc	ra,0xfffff
    80005344:	43c080e7          	jalr	1084(ra) # 8000477c <fileread>
}
    80005348:	70a2                	ld	ra,40(sp)
    8000534a:	7402                	ld	s0,32(sp)
    8000534c:	6145                	addi	sp,sp,48
    8000534e:	8082                	ret

0000000080005350 <sys_write>:
{
    80005350:	7179                	addi	sp,sp,-48
    80005352:	f406                	sd	ra,40(sp)
    80005354:	f022                	sd	s0,32(sp)
    80005356:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005358:	fd840593          	addi	a1,s0,-40
    8000535c:	4505                	li	a0,1
    8000535e:	ffffd097          	auipc	ra,0xffffd
    80005362:	7be080e7          	jalr	1982(ra) # 80002b1c <argaddr>
  argint(2, &n);
    80005366:	fe440593          	addi	a1,s0,-28
    8000536a:	4509                	li	a0,2
    8000536c:	ffffd097          	auipc	ra,0xffffd
    80005370:	790080e7          	jalr	1936(ra) # 80002afc <argint>
  if(argfd(0, 0, &f) < 0)
    80005374:	fe840613          	addi	a2,s0,-24
    80005378:	4581                	li	a1,0
    8000537a:	4501                	li	a0,0
    8000537c:	00000097          	auipc	ra,0x0
    80005380:	cfe080e7          	jalr	-770(ra) # 8000507a <argfd>
    80005384:	87aa                	mv	a5,a0
    return -1;
    80005386:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005388:	0007cc63          	bltz	a5,800053a0 <sys_write+0x50>
  return filewrite(f, p, n);
    8000538c:	fe442603          	lw	a2,-28(s0)
    80005390:	fd843583          	ld	a1,-40(s0)
    80005394:	fe843503          	ld	a0,-24(s0)
    80005398:	fffff097          	auipc	ra,0xfffff
    8000539c:	4a6080e7          	jalr	1190(ra) # 8000483e <filewrite>
}
    800053a0:	70a2                	ld	ra,40(sp)
    800053a2:	7402                	ld	s0,32(sp)
    800053a4:	6145                	addi	sp,sp,48
    800053a6:	8082                	ret

00000000800053a8 <sys_close>:
{
    800053a8:	1101                	addi	sp,sp,-32
    800053aa:	ec06                	sd	ra,24(sp)
    800053ac:	e822                	sd	s0,16(sp)
    800053ae:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800053b0:	fe040613          	addi	a2,s0,-32
    800053b4:	fec40593          	addi	a1,s0,-20
    800053b8:	4501                	li	a0,0
    800053ba:	00000097          	auipc	ra,0x0
    800053be:	cc0080e7          	jalr	-832(ra) # 8000507a <argfd>
    return -1;
    800053c2:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800053c4:	02054463          	bltz	a0,800053ec <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800053c8:	ffffc097          	auipc	ra,0xffffc
    800053cc:	5e4080e7          	jalr	1508(ra) # 800019ac <myproc>
    800053d0:	fec42783          	lw	a5,-20(s0)
    800053d4:	07e9                	addi	a5,a5,26
    800053d6:	078e                	slli	a5,a5,0x3
    800053d8:	953e                	add	a0,a0,a5
    800053da:	00053023          	sd	zero,0(a0)
  fileclose(f);
    800053de:	fe043503          	ld	a0,-32(s0)
    800053e2:	fffff097          	auipc	ra,0xfffff
    800053e6:	260080e7          	jalr	608(ra) # 80004642 <fileclose>
  return 0;
    800053ea:	4781                	li	a5,0
}
    800053ec:	853e                	mv	a0,a5
    800053ee:	60e2                	ld	ra,24(sp)
    800053f0:	6442                	ld	s0,16(sp)
    800053f2:	6105                	addi	sp,sp,32
    800053f4:	8082                	ret

00000000800053f6 <sys_fstat>:
{
    800053f6:	1101                	addi	sp,sp,-32
    800053f8:	ec06                	sd	ra,24(sp)
    800053fa:	e822                	sd	s0,16(sp)
    800053fc:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800053fe:	fe040593          	addi	a1,s0,-32
    80005402:	4505                	li	a0,1
    80005404:	ffffd097          	auipc	ra,0xffffd
    80005408:	718080e7          	jalr	1816(ra) # 80002b1c <argaddr>
  if(argfd(0, 0, &f) < 0)
    8000540c:	fe840613          	addi	a2,s0,-24
    80005410:	4581                	li	a1,0
    80005412:	4501                	li	a0,0
    80005414:	00000097          	auipc	ra,0x0
    80005418:	c66080e7          	jalr	-922(ra) # 8000507a <argfd>
    8000541c:	87aa                	mv	a5,a0
    return -1;
    8000541e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005420:	0007ca63          	bltz	a5,80005434 <sys_fstat+0x3e>
  return filestat(f, st);
    80005424:	fe043583          	ld	a1,-32(s0)
    80005428:	fe843503          	ld	a0,-24(s0)
    8000542c:	fffff097          	auipc	ra,0xfffff
    80005430:	2de080e7          	jalr	734(ra) # 8000470a <filestat>
}
    80005434:	60e2                	ld	ra,24(sp)
    80005436:	6442                	ld	s0,16(sp)
    80005438:	6105                	addi	sp,sp,32
    8000543a:	8082                	ret

000000008000543c <sys_link>:
{
    8000543c:	7169                	addi	sp,sp,-304
    8000543e:	f606                	sd	ra,296(sp)
    80005440:	f222                	sd	s0,288(sp)
    80005442:	ee26                	sd	s1,280(sp)
    80005444:	ea4a                	sd	s2,272(sp)
    80005446:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005448:	08000613          	li	a2,128
    8000544c:	ed040593          	addi	a1,s0,-304
    80005450:	4501                	li	a0,0
    80005452:	ffffd097          	auipc	ra,0xffffd
    80005456:	6ea080e7          	jalr	1770(ra) # 80002b3c <argstr>
    return -1;
    8000545a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000545c:	10054e63          	bltz	a0,80005578 <sys_link+0x13c>
    80005460:	08000613          	li	a2,128
    80005464:	f5040593          	addi	a1,s0,-176
    80005468:	4505                	li	a0,1
    8000546a:	ffffd097          	auipc	ra,0xffffd
    8000546e:	6d2080e7          	jalr	1746(ra) # 80002b3c <argstr>
    return -1;
    80005472:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005474:	10054263          	bltz	a0,80005578 <sys_link+0x13c>
  begin_op();
    80005478:	fffff097          	auipc	ra,0xfffff
    8000547c:	d02080e7          	jalr	-766(ra) # 8000417a <begin_op>
  if((ip = namei(old)) == 0){
    80005480:	ed040513          	addi	a0,s0,-304
    80005484:	fffff097          	auipc	ra,0xfffff
    80005488:	ad6080e7          	jalr	-1322(ra) # 80003f5a <namei>
    8000548c:	84aa                	mv	s1,a0
    8000548e:	c551                	beqz	a0,8000551a <sys_link+0xde>
  ilock(ip);
    80005490:	ffffe097          	auipc	ra,0xffffe
    80005494:	31e080e7          	jalr	798(ra) # 800037ae <ilock>
  if(ip->type == T_DIR){
    80005498:	04449703          	lh	a4,68(s1)
    8000549c:	4785                	li	a5,1
    8000549e:	08f70463          	beq	a4,a5,80005526 <sys_link+0xea>
  ip->nlink++;
    800054a2:	04a4d783          	lhu	a5,74(s1)
    800054a6:	2785                	addiw	a5,a5,1
    800054a8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054ac:	8526                	mv	a0,s1
    800054ae:	ffffe097          	auipc	ra,0xffffe
    800054b2:	234080e7          	jalr	564(ra) # 800036e2 <iupdate>
  iunlock(ip);
    800054b6:	8526                	mv	a0,s1
    800054b8:	ffffe097          	auipc	ra,0xffffe
    800054bc:	3b8080e7          	jalr	952(ra) # 80003870 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800054c0:	fd040593          	addi	a1,s0,-48
    800054c4:	f5040513          	addi	a0,s0,-176
    800054c8:	fffff097          	auipc	ra,0xfffff
    800054cc:	ab0080e7          	jalr	-1360(ra) # 80003f78 <nameiparent>
    800054d0:	892a                	mv	s2,a0
    800054d2:	c935                	beqz	a0,80005546 <sys_link+0x10a>
  ilock(dp);
    800054d4:	ffffe097          	auipc	ra,0xffffe
    800054d8:	2da080e7          	jalr	730(ra) # 800037ae <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800054dc:	00092703          	lw	a4,0(s2)
    800054e0:	409c                	lw	a5,0(s1)
    800054e2:	04f71d63          	bne	a4,a5,8000553c <sys_link+0x100>
    800054e6:	40d0                	lw	a2,4(s1)
    800054e8:	fd040593          	addi	a1,s0,-48
    800054ec:	854a                	mv	a0,s2
    800054ee:	fffff097          	auipc	ra,0xfffff
    800054f2:	9ba080e7          	jalr	-1606(ra) # 80003ea8 <dirlink>
    800054f6:	04054363          	bltz	a0,8000553c <sys_link+0x100>
  iunlockput(dp);
    800054fa:	854a                	mv	a0,s2
    800054fc:	ffffe097          	auipc	ra,0xffffe
    80005500:	514080e7          	jalr	1300(ra) # 80003a10 <iunlockput>
  iput(ip);
    80005504:	8526                	mv	a0,s1
    80005506:	ffffe097          	auipc	ra,0xffffe
    8000550a:	462080e7          	jalr	1122(ra) # 80003968 <iput>
  end_op();
    8000550e:	fffff097          	auipc	ra,0xfffff
    80005512:	cea080e7          	jalr	-790(ra) # 800041f8 <end_op>
  return 0;
    80005516:	4781                	li	a5,0
    80005518:	a085                	j	80005578 <sys_link+0x13c>
    end_op();
    8000551a:	fffff097          	auipc	ra,0xfffff
    8000551e:	cde080e7          	jalr	-802(ra) # 800041f8 <end_op>
    return -1;
    80005522:	57fd                	li	a5,-1
    80005524:	a891                	j	80005578 <sys_link+0x13c>
    iunlockput(ip);
    80005526:	8526                	mv	a0,s1
    80005528:	ffffe097          	auipc	ra,0xffffe
    8000552c:	4e8080e7          	jalr	1256(ra) # 80003a10 <iunlockput>
    end_op();
    80005530:	fffff097          	auipc	ra,0xfffff
    80005534:	cc8080e7          	jalr	-824(ra) # 800041f8 <end_op>
    return -1;
    80005538:	57fd                	li	a5,-1
    8000553a:	a83d                	j	80005578 <sys_link+0x13c>
    iunlockput(dp);
    8000553c:	854a                	mv	a0,s2
    8000553e:	ffffe097          	auipc	ra,0xffffe
    80005542:	4d2080e7          	jalr	1234(ra) # 80003a10 <iunlockput>
  ilock(ip);
    80005546:	8526                	mv	a0,s1
    80005548:	ffffe097          	auipc	ra,0xffffe
    8000554c:	266080e7          	jalr	614(ra) # 800037ae <ilock>
  ip->nlink--;
    80005550:	04a4d783          	lhu	a5,74(s1)
    80005554:	37fd                	addiw	a5,a5,-1
    80005556:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000555a:	8526                	mv	a0,s1
    8000555c:	ffffe097          	auipc	ra,0xffffe
    80005560:	186080e7          	jalr	390(ra) # 800036e2 <iupdate>
  iunlockput(ip);
    80005564:	8526                	mv	a0,s1
    80005566:	ffffe097          	auipc	ra,0xffffe
    8000556a:	4aa080e7          	jalr	1194(ra) # 80003a10 <iunlockput>
  end_op();
    8000556e:	fffff097          	auipc	ra,0xfffff
    80005572:	c8a080e7          	jalr	-886(ra) # 800041f8 <end_op>
  return -1;
    80005576:	57fd                	li	a5,-1
}
    80005578:	853e                	mv	a0,a5
    8000557a:	70b2                	ld	ra,296(sp)
    8000557c:	7412                	ld	s0,288(sp)
    8000557e:	64f2                	ld	s1,280(sp)
    80005580:	6952                	ld	s2,272(sp)
    80005582:	6155                	addi	sp,sp,304
    80005584:	8082                	ret

0000000080005586 <sys_unlink>:
{
    80005586:	7151                	addi	sp,sp,-240
    80005588:	f586                	sd	ra,232(sp)
    8000558a:	f1a2                	sd	s0,224(sp)
    8000558c:	eda6                	sd	s1,216(sp)
    8000558e:	e9ca                	sd	s2,208(sp)
    80005590:	e5ce                	sd	s3,200(sp)
    80005592:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005594:	08000613          	li	a2,128
    80005598:	f3040593          	addi	a1,s0,-208
    8000559c:	4501                	li	a0,0
    8000559e:	ffffd097          	auipc	ra,0xffffd
    800055a2:	59e080e7          	jalr	1438(ra) # 80002b3c <argstr>
    800055a6:	18054163          	bltz	a0,80005728 <sys_unlink+0x1a2>
  begin_op();
    800055aa:	fffff097          	auipc	ra,0xfffff
    800055ae:	bd0080e7          	jalr	-1072(ra) # 8000417a <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800055b2:	fb040593          	addi	a1,s0,-80
    800055b6:	f3040513          	addi	a0,s0,-208
    800055ba:	fffff097          	auipc	ra,0xfffff
    800055be:	9be080e7          	jalr	-1602(ra) # 80003f78 <nameiparent>
    800055c2:	84aa                	mv	s1,a0
    800055c4:	c979                	beqz	a0,8000569a <sys_unlink+0x114>
  ilock(dp);
    800055c6:	ffffe097          	auipc	ra,0xffffe
    800055ca:	1e8080e7          	jalr	488(ra) # 800037ae <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800055ce:	00003597          	auipc	a1,0x3
    800055d2:	25a58593          	addi	a1,a1,602 # 80008828 <syscalls+0x2a0>
    800055d6:	fb040513          	addi	a0,s0,-80
    800055da:	ffffe097          	auipc	ra,0xffffe
    800055de:	69e080e7          	jalr	1694(ra) # 80003c78 <namecmp>
    800055e2:	14050a63          	beqz	a0,80005736 <sys_unlink+0x1b0>
    800055e6:	00003597          	auipc	a1,0x3
    800055ea:	24a58593          	addi	a1,a1,586 # 80008830 <syscalls+0x2a8>
    800055ee:	fb040513          	addi	a0,s0,-80
    800055f2:	ffffe097          	auipc	ra,0xffffe
    800055f6:	686080e7          	jalr	1670(ra) # 80003c78 <namecmp>
    800055fa:	12050e63          	beqz	a0,80005736 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800055fe:	f2c40613          	addi	a2,s0,-212
    80005602:	fb040593          	addi	a1,s0,-80
    80005606:	8526                	mv	a0,s1
    80005608:	ffffe097          	auipc	ra,0xffffe
    8000560c:	68a080e7          	jalr	1674(ra) # 80003c92 <dirlookup>
    80005610:	892a                	mv	s2,a0
    80005612:	12050263          	beqz	a0,80005736 <sys_unlink+0x1b0>
  ilock(ip);
    80005616:	ffffe097          	auipc	ra,0xffffe
    8000561a:	198080e7          	jalr	408(ra) # 800037ae <ilock>
  if(ip->nlink < 1)
    8000561e:	04a91783          	lh	a5,74(s2)
    80005622:	08f05263          	blez	a5,800056a6 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005626:	04491703          	lh	a4,68(s2)
    8000562a:	4785                	li	a5,1
    8000562c:	08f70563          	beq	a4,a5,800056b6 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005630:	4641                	li	a2,16
    80005632:	4581                	li	a1,0
    80005634:	fc040513          	addi	a0,s0,-64
    80005638:	ffffb097          	auipc	ra,0xffffb
    8000563c:	69a080e7          	jalr	1690(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005640:	4741                	li	a4,16
    80005642:	f2c42683          	lw	a3,-212(s0)
    80005646:	fc040613          	addi	a2,s0,-64
    8000564a:	4581                	li	a1,0
    8000564c:	8526                	mv	a0,s1
    8000564e:	ffffe097          	auipc	ra,0xffffe
    80005652:	50c080e7          	jalr	1292(ra) # 80003b5a <writei>
    80005656:	47c1                	li	a5,16
    80005658:	0af51563          	bne	a0,a5,80005702 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000565c:	04491703          	lh	a4,68(s2)
    80005660:	4785                	li	a5,1
    80005662:	0af70863          	beq	a4,a5,80005712 <sys_unlink+0x18c>
  iunlockput(dp);
    80005666:	8526                	mv	a0,s1
    80005668:	ffffe097          	auipc	ra,0xffffe
    8000566c:	3a8080e7          	jalr	936(ra) # 80003a10 <iunlockput>
  ip->nlink--;
    80005670:	04a95783          	lhu	a5,74(s2)
    80005674:	37fd                	addiw	a5,a5,-1
    80005676:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000567a:	854a                	mv	a0,s2
    8000567c:	ffffe097          	auipc	ra,0xffffe
    80005680:	066080e7          	jalr	102(ra) # 800036e2 <iupdate>
  iunlockput(ip);
    80005684:	854a                	mv	a0,s2
    80005686:	ffffe097          	auipc	ra,0xffffe
    8000568a:	38a080e7          	jalr	906(ra) # 80003a10 <iunlockput>
  end_op();
    8000568e:	fffff097          	auipc	ra,0xfffff
    80005692:	b6a080e7          	jalr	-1174(ra) # 800041f8 <end_op>
  return 0;
    80005696:	4501                	li	a0,0
    80005698:	a84d                	j	8000574a <sys_unlink+0x1c4>
    end_op();
    8000569a:	fffff097          	auipc	ra,0xfffff
    8000569e:	b5e080e7          	jalr	-1186(ra) # 800041f8 <end_op>
    return -1;
    800056a2:	557d                	li	a0,-1
    800056a4:	a05d                	j	8000574a <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800056a6:	00003517          	auipc	a0,0x3
    800056aa:	19250513          	addi	a0,a0,402 # 80008838 <syscalls+0x2b0>
    800056ae:	ffffb097          	auipc	ra,0xffffb
    800056b2:	e92080e7          	jalr	-366(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056b6:	04c92703          	lw	a4,76(s2)
    800056ba:	02000793          	li	a5,32
    800056be:	f6e7f9e3          	bgeu	a5,a4,80005630 <sys_unlink+0xaa>
    800056c2:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056c6:	4741                	li	a4,16
    800056c8:	86ce                	mv	a3,s3
    800056ca:	f1840613          	addi	a2,s0,-232
    800056ce:	4581                	li	a1,0
    800056d0:	854a                	mv	a0,s2
    800056d2:	ffffe097          	auipc	ra,0xffffe
    800056d6:	390080e7          	jalr	912(ra) # 80003a62 <readi>
    800056da:	47c1                	li	a5,16
    800056dc:	00f51b63          	bne	a0,a5,800056f2 <sys_unlink+0x16c>
    if(de.inum != 0)
    800056e0:	f1845783          	lhu	a5,-232(s0)
    800056e4:	e7a1                	bnez	a5,8000572c <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056e6:	29c1                	addiw	s3,s3,16
    800056e8:	04c92783          	lw	a5,76(s2)
    800056ec:	fcf9ede3          	bltu	s3,a5,800056c6 <sys_unlink+0x140>
    800056f0:	b781                	j	80005630 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800056f2:	00003517          	auipc	a0,0x3
    800056f6:	15e50513          	addi	a0,a0,350 # 80008850 <syscalls+0x2c8>
    800056fa:	ffffb097          	auipc	ra,0xffffb
    800056fe:	e46080e7          	jalr	-442(ra) # 80000540 <panic>
    panic("unlink: writei");
    80005702:	00003517          	auipc	a0,0x3
    80005706:	16650513          	addi	a0,a0,358 # 80008868 <syscalls+0x2e0>
    8000570a:	ffffb097          	auipc	ra,0xffffb
    8000570e:	e36080e7          	jalr	-458(ra) # 80000540 <panic>
    dp->nlink--;
    80005712:	04a4d783          	lhu	a5,74(s1)
    80005716:	37fd                	addiw	a5,a5,-1
    80005718:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000571c:	8526                	mv	a0,s1
    8000571e:	ffffe097          	auipc	ra,0xffffe
    80005722:	fc4080e7          	jalr	-60(ra) # 800036e2 <iupdate>
    80005726:	b781                	j	80005666 <sys_unlink+0xe0>
    return -1;
    80005728:	557d                	li	a0,-1
    8000572a:	a005                	j	8000574a <sys_unlink+0x1c4>
    iunlockput(ip);
    8000572c:	854a                	mv	a0,s2
    8000572e:	ffffe097          	auipc	ra,0xffffe
    80005732:	2e2080e7          	jalr	738(ra) # 80003a10 <iunlockput>
  iunlockput(dp);
    80005736:	8526                	mv	a0,s1
    80005738:	ffffe097          	auipc	ra,0xffffe
    8000573c:	2d8080e7          	jalr	728(ra) # 80003a10 <iunlockput>
  end_op();
    80005740:	fffff097          	auipc	ra,0xfffff
    80005744:	ab8080e7          	jalr	-1352(ra) # 800041f8 <end_op>
  return -1;
    80005748:	557d                	li	a0,-1
}
    8000574a:	70ae                	ld	ra,232(sp)
    8000574c:	740e                	ld	s0,224(sp)
    8000574e:	64ee                	ld	s1,216(sp)
    80005750:	694e                	ld	s2,208(sp)
    80005752:	69ae                	ld	s3,200(sp)
    80005754:	616d                	addi	sp,sp,240
    80005756:	8082                	ret

0000000080005758 <sys_open>:

uint64
sys_open(void)
{
    80005758:	7131                	addi	sp,sp,-192
    8000575a:	fd06                	sd	ra,184(sp)
    8000575c:	f922                	sd	s0,176(sp)
    8000575e:	f526                	sd	s1,168(sp)
    80005760:	f14a                	sd	s2,160(sp)
    80005762:	ed4e                	sd	s3,152(sp)
    80005764:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005766:	f4c40593          	addi	a1,s0,-180
    8000576a:	4505                	li	a0,1
    8000576c:	ffffd097          	auipc	ra,0xffffd
    80005770:	390080e7          	jalr	912(ra) # 80002afc <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005774:	08000613          	li	a2,128
    80005778:	f5040593          	addi	a1,s0,-176
    8000577c:	4501                	li	a0,0
    8000577e:	ffffd097          	auipc	ra,0xffffd
    80005782:	3be080e7          	jalr	958(ra) # 80002b3c <argstr>
    80005786:	87aa                	mv	a5,a0
    return -1;
    80005788:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000578a:	0a07c963          	bltz	a5,8000583c <sys_open+0xe4>

  begin_op();
    8000578e:	fffff097          	auipc	ra,0xfffff
    80005792:	9ec080e7          	jalr	-1556(ra) # 8000417a <begin_op>

  if(omode & O_CREATE){
    80005796:	f4c42783          	lw	a5,-180(s0)
    8000579a:	2007f793          	andi	a5,a5,512
    8000579e:	cfc5                	beqz	a5,80005856 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800057a0:	4681                	li	a3,0
    800057a2:	4601                	li	a2,0
    800057a4:	4589                	li	a1,2
    800057a6:	f5040513          	addi	a0,s0,-176
    800057aa:	00000097          	auipc	ra,0x0
    800057ae:	972080e7          	jalr	-1678(ra) # 8000511c <create>
    800057b2:	84aa                	mv	s1,a0
    if(ip == 0){
    800057b4:	c959                	beqz	a0,8000584a <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800057b6:	04449703          	lh	a4,68(s1)
    800057ba:	478d                	li	a5,3
    800057bc:	00f71763          	bne	a4,a5,800057ca <sys_open+0x72>
    800057c0:	0464d703          	lhu	a4,70(s1)
    800057c4:	47a5                	li	a5,9
    800057c6:	0ce7ed63          	bltu	a5,a4,800058a0 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800057ca:	fffff097          	auipc	ra,0xfffff
    800057ce:	dbc080e7          	jalr	-580(ra) # 80004586 <filealloc>
    800057d2:	89aa                	mv	s3,a0
    800057d4:	10050363          	beqz	a0,800058da <sys_open+0x182>
    800057d8:	00000097          	auipc	ra,0x0
    800057dc:	902080e7          	jalr	-1790(ra) # 800050da <fdalloc>
    800057e0:	892a                	mv	s2,a0
    800057e2:	0e054763          	bltz	a0,800058d0 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800057e6:	04449703          	lh	a4,68(s1)
    800057ea:	478d                	li	a5,3
    800057ec:	0cf70563          	beq	a4,a5,800058b6 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800057f0:	4789                	li	a5,2
    800057f2:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800057f6:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800057fa:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    800057fe:	f4c42783          	lw	a5,-180(s0)
    80005802:	0017c713          	xori	a4,a5,1
    80005806:	8b05                	andi	a4,a4,1
    80005808:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000580c:	0037f713          	andi	a4,a5,3
    80005810:	00e03733          	snez	a4,a4
    80005814:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005818:	4007f793          	andi	a5,a5,1024
    8000581c:	c791                	beqz	a5,80005828 <sys_open+0xd0>
    8000581e:	04449703          	lh	a4,68(s1)
    80005822:	4789                	li	a5,2
    80005824:	0af70063          	beq	a4,a5,800058c4 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005828:	8526                	mv	a0,s1
    8000582a:	ffffe097          	auipc	ra,0xffffe
    8000582e:	046080e7          	jalr	70(ra) # 80003870 <iunlock>
  end_op();
    80005832:	fffff097          	auipc	ra,0xfffff
    80005836:	9c6080e7          	jalr	-1594(ra) # 800041f8 <end_op>

  return fd;
    8000583a:	854a                	mv	a0,s2
}
    8000583c:	70ea                	ld	ra,184(sp)
    8000583e:	744a                	ld	s0,176(sp)
    80005840:	74aa                	ld	s1,168(sp)
    80005842:	790a                	ld	s2,160(sp)
    80005844:	69ea                	ld	s3,152(sp)
    80005846:	6129                	addi	sp,sp,192
    80005848:	8082                	ret
      end_op();
    8000584a:	fffff097          	auipc	ra,0xfffff
    8000584e:	9ae080e7          	jalr	-1618(ra) # 800041f8 <end_op>
      return -1;
    80005852:	557d                	li	a0,-1
    80005854:	b7e5                	j	8000583c <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005856:	f5040513          	addi	a0,s0,-176
    8000585a:	ffffe097          	auipc	ra,0xffffe
    8000585e:	700080e7          	jalr	1792(ra) # 80003f5a <namei>
    80005862:	84aa                	mv	s1,a0
    80005864:	c905                	beqz	a0,80005894 <sys_open+0x13c>
    ilock(ip);
    80005866:	ffffe097          	auipc	ra,0xffffe
    8000586a:	f48080e7          	jalr	-184(ra) # 800037ae <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000586e:	04449703          	lh	a4,68(s1)
    80005872:	4785                	li	a5,1
    80005874:	f4f711e3          	bne	a4,a5,800057b6 <sys_open+0x5e>
    80005878:	f4c42783          	lw	a5,-180(s0)
    8000587c:	d7b9                	beqz	a5,800057ca <sys_open+0x72>
      iunlockput(ip);
    8000587e:	8526                	mv	a0,s1
    80005880:	ffffe097          	auipc	ra,0xffffe
    80005884:	190080e7          	jalr	400(ra) # 80003a10 <iunlockput>
      end_op();
    80005888:	fffff097          	auipc	ra,0xfffff
    8000588c:	970080e7          	jalr	-1680(ra) # 800041f8 <end_op>
      return -1;
    80005890:	557d                	li	a0,-1
    80005892:	b76d                	j	8000583c <sys_open+0xe4>
      end_op();
    80005894:	fffff097          	auipc	ra,0xfffff
    80005898:	964080e7          	jalr	-1692(ra) # 800041f8 <end_op>
      return -1;
    8000589c:	557d                	li	a0,-1
    8000589e:	bf79                	j	8000583c <sys_open+0xe4>
    iunlockput(ip);
    800058a0:	8526                	mv	a0,s1
    800058a2:	ffffe097          	auipc	ra,0xffffe
    800058a6:	16e080e7          	jalr	366(ra) # 80003a10 <iunlockput>
    end_op();
    800058aa:	fffff097          	auipc	ra,0xfffff
    800058ae:	94e080e7          	jalr	-1714(ra) # 800041f8 <end_op>
    return -1;
    800058b2:	557d                	li	a0,-1
    800058b4:	b761                	j	8000583c <sys_open+0xe4>
    f->type = FD_DEVICE;
    800058b6:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800058ba:	04649783          	lh	a5,70(s1)
    800058be:	02f99223          	sh	a5,36(s3)
    800058c2:	bf25                	j	800057fa <sys_open+0xa2>
    itrunc(ip);
    800058c4:	8526                	mv	a0,s1
    800058c6:	ffffe097          	auipc	ra,0xffffe
    800058ca:	ff6080e7          	jalr	-10(ra) # 800038bc <itrunc>
    800058ce:	bfa9                	j	80005828 <sys_open+0xd0>
      fileclose(f);
    800058d0:	854e                	mv	a0,s3
    800058d2:	fffff097          	auipc	ra,0xfffff
    800058d6:	d70080e7          	jalr	-656(ra) # 80004642 <fileclose>
    iunlockput(ip);
    800058da:	8526                	mv	a0,s1
    800058dc:	ffffe097          	auipc	ra,0xffffe
    800058e0:	134080e7          	jalr	308(ra) # 80003a10 <iunlockput>
    end_op();
    800058e4:	fffff097          	auipc	ra,0xfffff
    800058e8:	914080e7          	jalr	-1772(ra) # 800041f8 <end_op>
    return -1;
    800058ec:	557d                	li	a0,-1
    800058ee:	b7b9                	j	8000583c <sys_open+0xe4>

00000000800058f0 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800058f0:	7175                	addi	sp,sp,-144
    800058f2:	e506                	sd	ra,136(sp)
    800058f4:	e122                	sd	s0,128(sp)
    800058f6:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800058f8:	fffff097          	auipc	ra,0xfffff
    800058fc:	882080e7          	jalr	-1918(ra) # 8000417a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005900:	08000613          	li	a2,128
    80005904:	f7040593          	addi	a1,s0,-144
    80005908:	4501                	li	a0,0
    8000590a:	ffffd097          	auipc	ra,0xffffd
    8000590e:	232080e7          	jalr	562(ra) # 80002b3c <argstr>
    80005912:	02054963          	bltz	a0,80005944 <sys_mkdir+0x54>
    80005916:	4681                	li	a3,0
    80005918:	4601                	li	a2,0
    8000591a:	4585                	li	a1,1
    8000591c:	f7040513          	addi	a0,s0,-144
    80005920:	fffff097          	auipc	ra,0xfffff
    80005924:	7fc080e7          	jalr	2044(ra) # 8000511c <create>
    80005928:	cd11                	beqz	a0,80005944 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000592a:	ffffe097          	auipc	ra,0xffffe
    8000592e:	0e6080e7          	jalr	230(ra) # 80003a10 <iunlockput>
  end_op();
    80005932:	fffff097          	auipc	ra,0xfffff
    80005936:	8c6080e7          	jalr	-1850(ra) # 800041f8 <end_op>
  return 0;
    8000593a:	4501                	li	a0,0
}
    8000593c:	60aa                	ld	ra,136(sp)
    8000593e:	640a                	ld	s0,128(sp)
    80005940:	6149                	addi	sp,sp,144
    80005942:	8082                	ret
    end_op();
    80005944:	fffff097          	auipc	ra,0xfffff
    80005948:	8b4080e7          	jalr	-1868(ra) # 800041f8 <end_op>
    return -1;
    8000594c:	557d                	li	a0,-1
    8000594e:	b7fd                	j	8000593c <sys_mkdir+0x4c>

0000000080005950 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005950:	7135                	addi	sp,sp,-160
    80005952:	ed06                	sd	ra,152(sp)
    80005954:	e922                	sd	s0,144(sp)
    80005956:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005958:	fffff097          	auipc	ra,0xfffff
    8000595c:	822080e7          	jalr	-2014(ra) # 8000417a <begin_op>
  argint(1, &major);
    80005960:	f6c40593          	addi	a1,s0,-148
    80005964:	4505                	li	a0,1
    80005966:	ffffd097          	auipc	ra,0xffffd
    8000596a:	196080e7          	jalr	406(ra) # 80002afc <argint>
  argint(2, &minor);
    8000596e:	f6840593          	addi	a1,s0,-152
    80005972:	4509                	li	a0,2
    80005974:	ffffd097          	auipc	ra,0xffffd
    80005978:	188080e7          	jalr	392(ra) # 80002afc <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000597c:	08000613          	li	a2,128
    80005980:	f7040593          	addi	a1,s0,-144
    80005984:	4501                	li	a0,0
    80005986:	ffffd097          	auipc	ra,0xffffd
    8000598a:	1b6080e7          	jalr	438(ra) # 80002b3c <argstr>
    8000598e:	02054b63          	bltz	a0,800059c4 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005992:	f6841683          	lh	a3,-152(s0)
    80005996:	f6c41603          	lh	a2,-148(s0)
    8000599a:	458d                	li	a1,3
    8000599c:	f7040513          	addi	a0,s0,-144
    800059a0:	fffff097          	auipc	ra,0xfffff
    800059a4:	77c080e7          	jalr	1916(ra) # 8000511c <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059a8:	cd11                	beqz	a0,800059c4 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800059aa:	ffffe097          	auipc	ra,0xffffe
    800059ae:	066080e7          	jalr	102(ra) # 80003a10 <iunlockput>
  end_op();
    800059b2:	fffff097          	auipc	ra,0xfffff
    800059b6:	846080e7          	jalr	-1978(ra) # 800041f8 <end_op>
  return 0;
    800059ba:	4501                	li	a0,0
}
    800059bc:	60ea                	ld	ra,152(sp)
    800059be:	644a                	ld	s0,144(sp)
    800059c0:	610d                	addi	sp,sp,160
    800059c2:	8082                	ret
    end_op();
    800059c4:	fffff097          	auipc	ra,0xfffff
    800059c8:	834080e7          	jalr	-1996(ra) # 800041f8 <end_op>
    return -1;
    800059cc:	557d                	li	a0,-1
    800059ce:	b7fd                	j	800059bc <sys_mknod+0x6c>

00000000800059d0 <sys_chdir>:

uint64
sys_chdir(void)
{
    800059d0:	7135                	addi	sp,sp,-160
    800059d2:	ed06                	sd	ra,152(sp)
    800059d4:	e922                	sd	s0,144(sp)
    800059d6:	e526                	sd	s1,136(sp)
    800059d8:	e14a                	sd	s2,128(sp)
    800059da:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800059dc:	ffffc097          	auipc	ra,0xffffc
    800059e0:	fd0080e7          	jalr	-48(ra) # 800019ac <myproc>
    800059e4:	892a                	mv	s2,a0
  
  begin_op();
    800059e6:	ffffe097          	auipc	ra,0xffffe
    800059ea:	794080e7          	jalr	1940(ra) # 8000417a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800059ee:	08000613          	li	a2,128
    800059f2:	f6040593          	addi	a1,s0,-160
    800059f6:	4501                	li	a0,0
    800059f8:	ffffd097          	auipc	ra,0xffffd
    800059fc:	144080e7          	jalr	324(ra) # 80002b3c <argstr>
    80005a00:	04054b63          	bltz	a0,80005a56 <sys_chdir+0x86>
    80005a04:	f6040513          	addi	a0,s0,-160
    80005a08:	ffffe097          	auipc	ra,0xffffe
    80005a0c:	552080e7          	jalr	1362(ra) # 80003f5a <namei>
    80005a10:	84aa                	mv	s1,a0
    80005a12:	c131                	beqz	a0,80005a56 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a14:	ffffe097          	auipc	ra,0xffffe
    80005a18:	d9a080e7          	jalr	-614(ra) # 800037ae <ilock>
  if(ip->type != T_DIR){
    80005a1c:	04449703          	lh	a4,68(s1)
    80005a20:	4785                	li	a5,1
    80005a22:	04f71063          	bne	a4,a5,80005a62 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a26:	8526                	mv	a0,s1
    80005a28:	ffffe097          	auipc	ra,0xffffe
    80005a2c:	e48080e7          	jalr	-440(ra) # 80003870 <iunlock>
  iput(p->cwd);
    80005a30:	15093503          	ld	a0,336(s2)
    80005a34:	ffffe097          	auipc	ra,0xffffe
    80005a38:	f34080e7          	jalr	-204(ra) # 80003968 <iput>
  end_op();
    80005a3c:	ffffe097          	auipc	ra,0xffffe
    80005a40:	7bc080e7          	jalr	1980(ra) # 800041f8 <end_op>
  p->cwd = ip;
    80005a44:	14993823          	sd	s1,336(s2)
  return 0;
    80005a48:	4501                	li	a0,0
}
    80005a4a:	60ea                	ld	ra,152(sp)
    80005a4c:	644a                	ld	s0,144(sp)
    80005a4e:	64aa                	ld	s1,136(sp)
    80005a50:	690a                	ld	s2,128(sp)
    80005a52:	610d                	addi	sp,sp,160
    80005a54:	8082                	ret
    end_op();
    80005a56:	ffffe097          	auipc	ra,0xffffe
    80005a5a:	7a2080e7          	jalr	1954(ra) # 800041f8 <end_op>
    return -1;
    80005a5e:	557d                	li	a0,-1
    80005a60:	b7ed                	j	80005a4a <sys_chdir+0x7a>
    iunlockput(ip);
    80005a62:	8526                	mv	a0,s1
    80005a64:	ffffe097          	auipc	ra,0xffffe
    80005a68:	fac080e7          	jalr	-84(ra) # 80003a10 <iunlockput>
    end_op();
    80005a6c:	ffffe097          	auipc	ra,0xffffe
    80005a70:	78c080e7          	jalr	1932(ra) # 800041f8 <end_op>
    return -1;
    80005a74:	557d                	li	a0,-1
    80005a76:	bfd1                	j	80005a4a <sys_chdir+0x7a>

0000000080005a78 <sys_exec>:

uint64
sys_exec(void)
{
    80005a78:	7145                	addi	sp,sp,-464
    80005a7a:	e786                	sd	ra,456(sp)
    80005a7c:	e3a2                	sd	s0,448(sp)
    80005a7e:	ff26                	sd	s1,440(sp)
    80005a80:	fb4a                	sd	s2,432(sp)
    80005a82:	f74e                	sd	s3,424(sp)
    80005a84:	f352                	sd	s4,416(sp)
    80005a86:	ef56                	sd	s5,408(sp)
    80005a88:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005a8a:	e3840593          	addi	a1,s0,-456
    80005a8e:	4505                	li	a0,1
    80005a90:	ffffd097          	auipc	ra,0xffffd
    80005a94:	08c080e7          	jalr	140(ra) # 80002b1c <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005a98:	08000613          	li	a2,128
    80005a9c:	f4040593          	addi	a1,s0,-192
    80005aa0:	4501                	li	a0,0
    80005aa2:	ffffd097          	auipc	ra,0xffffd
    80005aa6:	09a080e7          	jalr	154(ra) # 80002b3c <argstr>
    80005aaa:	87aa                	mv	a5,a0
    return -1;
    80005aac:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005aae:	0c07c363          	bltz	a5,80005b74 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005ab2:	10000613          	li	a2,256
    80005ab6:	4581                	li	a1,0
    80005ab8:	e4040513          	addi	a0,s0,-448
    80005abc:	ffffb097          	auipc	ra,0xffffb
    80005ac0:	216080e7          	jalr	534(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005ac4:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005ac8:	89a6                	mv	s3,s1
    80005aca:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005acc:	02000a13          	li	s4,32
    80005ad0:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005ad4:	00391513          	slli	a0,s2,0x3
    80005ad8:	e3040593          	addi	a1,s0,-464
    80005adc:	e3843783          	ld	a5,-456(s0)
    80005ae0:	953e                	add	a0,a0,a5
    80005ae2:	ffffd097          	auipc	ra,0xffffd
    80005ae6:	f7c080e7          	jalr	-132(ra) # 80002a5e <fetchaddr>
    80005aea:	02054a63          	bltz	a0,80005b1e <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005aee:	e3043783          	ld	a5,-464(s0)
    80005af2:	c3b9                	beqz	a5,80005b38 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005af4:	ffffb097          	auipc	ra,0xffffb
    80005af8:	ff2080e7          	jalr	-14(ra) # 80000ae6 <kalloc>
    80005afc:	85aa                	mv	a1,a0
    80005afe:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005b02:	cd11                	beqz	a0,80005b1e <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005b04:	6605                	lui	a2,0x1
    80005b06:	e3043503          	ld	a0,-464(s0)
    80005b0a:	ffffd097          	auipc	ra,0xffffd
    80005b0e:	fa6080e7          	jalr	-90(ra) # 80002ab0 <fetchstr>
    80005b12:	00054663          	bltz	a0,80005b1e <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005b16:	0905                	addi	s2,s2,1
    80005b18:	09a1                	addi	s3,s3,8
    80005b1a:	fb491be3          	bne	s2,s4,80005ad0 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b1e:	f4040913          	addi	s2,s0,-192
    80005b22:	6088                	ld	a0,0(s1)
    80005b24:	c539                	beqz	a0,80005b72 <sys_exec+0xfa>
    kfree(argv[i]);
    80005b26:	ffffb097          	auipc	ra,0xffffb
    80005b2a:	ec2080e7          	jalr	-318(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b2e:	04a1                	addi	s1,s1,8
    80005b30:	ff2499e3          	bne	s1,s2,80005b22 <sys_exec+0xaa>
  return -1;
    80005b34:	557d                	li	a0,-1
    80005b36:	a83d                	j	80005b74 <sys_exec+0xfc>
      argv[i] = 0;
    80005b38:	0a8e                	slli	s5,s5,0x3
    80005b3a:	fc0a8793          	addi	a5,s5,-64
    80005b3e:	00878ab3          	add	s5,a5,s0
    80005b42:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005b46:	e4040593          	addi	a1,s0,-448
    80005b4a:	f4040513          	addi	a0,s0,-192
    80005b4e:	fffff097          	auipc	ra,0xfffff
    80005b52:	16e080e7          	jalr	366(ra) # 80004cbc <exec>
    80005b56:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b58:	f4040993          	addi	s3,s0,-192
    80005b5c:	6088                	ld	a0,0(s1)
    80005b5e:	c901                	beqz	a0,80005b6e <sys_exec+0xf6>
    kfree(argv[i]);
    80005b60:	ffffb097          	auipc	ra,0xffffb
    80005b64:	e88080e7          	jalr	-376(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b68:	04a1                	addi	s1,s1,8
    80005b6a:	ff3499e3          	bne	s1,s3,80005b5c <sys_exec+0xe4>
  return ret;
    80005b6e:	854a                	mv	a0,s2
    80005b70:	a011                	j	80005b74 <sys_exec+0xfc>
  return -1;
    80005b72:	557d                	li	a0,-1
}
    80005b74:	60be                	ld	ra,456(sp)
    80005b76:	641e                	ld	s0,448(sp)
    80005b78:	74fa                	ld	s1,440(sp)
    80005b7a:	795a                	ld	s2,432(sp)
    80005b7c:	79ba                	ld	s3,424(sp)
    80005b7e:	7a1a                	ld	s4,416(sp)
    80005b80:	6afa                	ld	s5,408(sp)
    80005b82:	6179                	addi	sp,sp,464
    80005b84:	8082                	ret

0000000080005b86 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b86:	7139                	addi	sp,sp,-64
    80005b88:	fc06                	sd	ra,56(sp)
    80005b8a:	f822                	sd	s0,48(sp)
    80005b8c:	f426                	sd	s1,40(sp)
    80005b8e:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b90:	ffffc097          	auipc	ra,0xffffc
    80005b94:	e1c080e7          	jalr	-484(ra) # 800019ac <myproc>
    80005b98:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005b9a:	fd840593          	addi	a1,s0,-40
    80005b9e:	4501                	li	a0,0
    80005ba0:	ffffd097          	auipc	ra,0xffffd
    80005ba4:	f7c080e7          	jalr	-132(ra) # 80002b1c <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005ba8:	fc840593          	addi	a1,s0,-56
    80005bac:	fd040513          	addi	a0,s0,-48
    80005bb0:	fffff097          	auipc	ra,0xfffff
    80005bb4:	dc2080e7          	jalr	-574(ra) # 80004972 <pipealloc>
    return -1;
    80005bb8:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005bba:	0c054463          	bltz	a0,80005c82 <sys_pipe+0xfc>
  fd0 = -1;
    80005bbe:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005bc2:	fd043503          	ld	a0,-48(s0)
    80005bc6:	fffff097          	auipc	ra,0xfffff
    80005bca:	514080e7          	jalr	1300(ra) # 800050da <fdalloc>
    80005bce:	fca42223          	sw	a0,-60(s0)
    80005bd2:	08054b63          	bltz	a0,80005c68 <sys_pipe+0xe2>
    80005bd6:	fc843503          	ld	a0,-56(s0)
    80005bda:	fffff097          	auipc	ra,0xfffff
    80005bde:	500080e7          	jalr	1280(ra) # 800050da <fdalloc>
    80005be2:	fca42023          	sw	a0,-64(s0)
    80005be6:	06054863          	bltz	a0,80005c56 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bea:	4691                	li	a3,4
    80005bec:	fc440613          	addi	a2,s0,-60
    80005bf0:	fd843583          	ld	a1,-40(s0)
    80005bf4:	68a8                	ld	a0,80(s1)
    80005bf6:	ffffc097          	auipc	ra,0xffffc
    80005bfa:	a76080e7          	jalr	-1418(ra) # 8000166c <copyout>
    80005bfe:	02054063          	bltz	a0,80005c1e <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005c02:	4691                	li	a3,4
    80005c04:	fc040613          	addi	a2,s0,-64
    80005c08:	fd843583          	ld	a1,-40(s0)
    80005c0c:	0591                	addi	a1,a1,4
    80005c0e:	68a8                	ld	a0,80(s1)
    80005c10:	ffffc097          	auipc	ra,0xffffc
    80005c14:	a5c080e7          	jalr	-1444(ra) # 8000166c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005c18:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c1a:	06055463          	bgez	a0,80005c82 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005c1e:	fc442783          	lw	a5,-60(s0)
    80005c22:	07e9                	addi	a5,a5,26
    80005c24:	078e                	slli	a5,a5,0x3
    80005c26:	97a6                	add	a5,a5,s1
    80005c28:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c2c:	fc042783          	lw	a5,-64(s0)
    80005c30:	07e9                	addi	a5,a5,26
    80005c32:	078e                	slli	a5,a5,0x3
    80005c34:	94be                	add	s1,s1,a5
    80005c36:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005c3a:	fd043503          	ld	a0,-48(s0)
    80005c3e:	fffff097          	auipc	ra,0xfffff
    80005c42:	a04080e7          	jalr	-1532(ra) # 80004642 <fileclose>
    fileclose(wf);
    80005c46:	fc843503          	ld	a0,-56(s0)
    80005c4a:	fffff097          	auipc	ra,0xfffff
    80005c4e:	9f8080e7          	jalr	-1544(ra) # 80004642 <fileclose>
    return -1;
    80005c52:	57fd                	li	a5,-1
    80005c54:	a03d                	j	80005c82 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005c56:	fc442783          	lw	a5,-60(s0)
    80005c5a:	0007c763          	bltz	a5,80005c68 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005c5e:	07e9                	addi	a5,a5,26
    80005c60:	078e                	slli	a5,a5,0x3
    80005c62:	97a6                	add	a5,a5,s1
    80005c64:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005c68:	fd043503          	ld	a0,-48(s0)
    80005c6c:	fffff097          	auipc	ra,0xfffff
    80005c70:	9d6080e7          	jalr	-1578(ra) # 80004642 <fileclose>
    fileclose(wf);
    80005c74:	fc843503          	ld	a0,-56(s0)
    80005c78:	fffff097          	auipc	ra,0xfffff
    80005c7c:	9ca080e7          	jalr	-1590(ra) # 80004642 <fileclose>
    return -1;
    80005c80:	57fd                	li	a5,-1
}
    80005c82:	853e                	mv	a0,a5
    80005c84:	70e2                	ld	ra,56(sp)
    80005c86:	7442                	ld	s0,48(sp)
    80005c88:	74a2                	ld	s1,40(sp)
    80005c8a:	6121                	addi	sp,sp,64
    80005c8c:	8082                	ret
	...

0000000080005c90 <kernelvec>:
    80005c90:	7111                	addi	sp,sp,-256
    80005c92:	e006                	sd	ra,0(sp)
    80005c94:	e40a                	sd	sp,8(sp)
    80005c96:	e80e                	sd	gp,16(sp)
    80005c98:	ec12                	sd	tp,24(sp)
    80005c9a:	f016                	sd	t0,32(sp)
    80005c9c:	f41a                	sd	t1,40(sp)
    80005c9e:	f81e                	sd	t2,48(sp)
    80005ca0:	fc22                	sd	s0,56(sp)
    80005ca2:	e0a6                	sd	s1,64(sp)
    80005ca4:	e4aa                	sd	a0,72(sp)
    80005ca6:	e8ae                	sd	a1,80(sp)
    80005ca8:	ecb2                	sd	a2,88(sp)
    80005caa:	f0b6                	sd	a3,96(sp)
    80005cac:	f4ba                	sd	a4,104(sp)
    80005cae:	f8be                	sd	a5,112(sp)
    80005cb0:	fcc2                	sd	a6,120(sp)
    80005cb2:	e146                	sd	a7,128(sp)
    80005cb4:	e54a                	sd	s2,136(sp)
    80005cb6:	e94e                	sd	s3,144(sp)
    80005cb8:	ed52                	sd	s4,152(sp)
    80005cba:	f156                	sd	s5,160(sp)
    80005cbc:	f55a                	sd	s6,168(sp)
    80005cbe:	f95e                	sd	s7,176(sp)
    80005cc0:	fd62                	sd	s8,184(sp)
    80005cc2:	e1e6                	sd	s9,192(sp)
    80005cc4:	e5ea                	sd	s10,200(sp)
    80005cc6:	e9ee                	sd	s11,208(sp)
    80005cc8:	edf2                	sd	t3,216(sp)
    80005cca:	f1f6                	sd	t4,224(sp)
    80005ccc:	f5fa                	sd	t5,232(sp)
    80005cce:	f9fe                	sd	t6,240(sp)
    80005cd0:	c5bfc0ef          	jal	ra,8000292a <kerneltrap>
    80005cd4:	6082                	ld	ra,0(sp)
    80005cd6:	6122                	ld	sp,8(sp)
    80005cd8:	61c2                	ld	gp,16(sp)
    80005cda:	7282                	ld	t0,32(sp)
    80005cdc:	7322                	ld	t1,40(sp)
    80005cde:	73c2                	ld	t2,48(sp)
    80005ce0:	7462                	ld	s0,56(sp)
    80005ce2:	6486                	ld	s1,64(sp)
    80005ce4:	6526                	ld	a0,72(sp)
    80005ce6:	65c6                	ld	a1,80(sp)
    80005ce8:	6666                	ld	a2,88(sp)
    80005cea:	7686                	ld	a3,96(sp)
    80005cec:	7726                	ld	a4,104(sp)
    80005cee:	77c6                	ld	a5,112(sp)
    80005cf0:	7866                	ld	a6,120(sp)
    80005cf2:	688a                	ld	a7,128(sp)
    80005cf4:	692a                	ld	s2,136(sp)
    80005cf6:	69ca                	ld	s3,144(sp)
    80005cf8:	6a6a                	ld	s4,152(sp)
    80005cfa:	7a8a                	ld	s5,160(sp)
    80005cfc:	7b2a                	ld	s6,168(sp)
    80005cfe:	7bca                	ld	s7,176(sp)
    80005d00:	7c6a                	ld	s8,184(sp)
    80005d02:	6c8e                	ld	s9,192(sp)
    80005d04:	6d2e                	ld	s10,200(sp)
    80005d06:	6dce                	ld	s11,208(sp)
    80005d08:	6e6e                	ld	t3,216(sp)
    80005d0a:	7e8e                	ld	t4,224(sp)
    80005d0c:	7f2e                	ld	t5,232(sp)
    80005d0e:	7fce                	ld	t6,240(sp)
    80005d10:	6111                	addi	sp,sp,256
    80005d12:	10200073          	sret
    80005d16:	00000013          	nop
    80005d1a:	00000013          	nop
    80005d1e:	0001                	nop

0000000080005d20 <timervec>:
    80005d20:	34051573          	csrrw	a0,mscratch,a0
    80005d24:	e10c                	sd	a1,0(a0)
    80005d26:	e510                	sd	a2,8(a0)
    80005d28:	e914                	sd	a3,16(a0)
    80005d2a:	6d0c                	ld	a1,24(a0)
    80005d2c:	7110                	ld	a2,32(a0)
    80005d2e:	6194                	ld	a3,0(a1)
    80005d30:	96b2                	add	a3,a3,a2
    80005d32:	e194                	sd	a3,0(a1)
    80005d34:	4589                	li	a1,2
    80005d36:	14459073          	csrw	sip,a1
    80005d3a:	6914                	ld	a3,16(a0)
    80005d3c:	6510                	ld	a2,8(a0)
    80005d3e:	610c                	ld	a1,0(a0)
    80005d40:	34051573          	csrrw	a0,mscratch,a0
    80005d44:	30200073          	mret
	...

0000000080005d4a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d4a:	1141                	addi	sp,sp,-16
    80005d4c:	e422                	sd	s0,8(sp)
    80005d4e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d50:	0c0007b7          	lui	a5,0xc000
    80005d54:	4705                	li	a4,1
    80005d56:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d58:	c3d8                	sw	a4,4(a5)
}
    80005d5a:	6422                	ld	s0,8(sp)
    80005d5c:	0141                	addi	sp,sp,16
    80005d5e:	8082                	ret

0000000080005d60 <plicinithart>:

void
plicinithart(void)
{
    80005d60:	1141                	addi	sp,sp,-16
    80005d62:	e406                	sd	ra,8(sp)
    80005d64:	e022                	sd	s0,0(sp)
    80005d66:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d68:	ffffc097          	auipc	ra,0xffffc
    80005d6c:	c18080e7          	jalr	-1000(ra) # 80001980 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d70:	0085171b          	slliw	a4,a0,0x8
    80005d74:	0c0027b7          	lui	a5,0xc002
    80005d78:	97ba                	add	a5,a5,a4
    80005d7a:	40200713          	li	a4,1026
    80005d7e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d82:	00d5151b          	slliw	a0,a0,0xd
    80005d86:	0c2017b7          	lui	a5,0xc201
    80005d8a:	97aa                	add	a5,a5,a0
    80005d8c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005d90:	60a2                	ld	ra,8(sp)
    80005d92:	6402                	ld	s0,0(sp)
    80005d94:	0141                	addi	sp,sp,16
    80005d96:	8082                	ret

0000000080005d98 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d98:	1141                	addi	sp,sp,-16
    80005d9a:	e406                	sd	ra,8(sp)
    80005d9c:	e022                	sd	s0,0(sp)
    80005d9e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005da0:	ffffc097          	auipc	ra,0xffffc
    80005da4:	be0080e7          	jalr	-1056(ra) # 80001980 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005da8:	00d5151b          	slliw	a0,a0,0xd
    80005dac:	0c2017b7          	lui	a5,0xc201
    80005db0:	97aa                	add	a5,a5,a0
  return irq;
}
    80005db2:	43c8                	lw	a0,4(a5)
    80005db4:	60a2                	ld	ra,8(sp)
    80005db6:	6402                	ld	s0,0(sp)
    80005db8:	0141                	addi	sp,sp,16
    80005dba:	8082                	ret

0000000080005dbc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005dbc:	1101                	addi	sp,sp,-32
    80005dbe:	ec06                	sd	ra,24(sp)
    80005dc0:	e822                	sd	s0,16(sp)
    80005dc2:	e426                	sd	s1,8(sp)
    80005dc4:	1000                	addi	s0,sp,32
    80005dc6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005dc8:	ffffc097          	auipc	ra,0xffffc
    80005dcc:	bb8080e7          	jalr	-1096(ra) # 80001980 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005dd0:	00d5151b          	slliw	a0,a0,0xd
    80005dd4:	0c2017b7          	lui	a5,0xc201
    80005dd8:	97aa                	add	a5,a5,a0
    80005dda:	c3c4                	sw	s1,4(a5)
}
    80005ddc:	60e2                	ld	ra,24(sp)
    80005dde:	6442                	ld	s0,16(sp)
    80005de0:	64a2                	ld	s1,8(sp)
    80005de2:	6105                	addi	sp,sp,32
    80005de4:	8082                	ret

0000000080005de6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005de6:	1141                	addi	sp,sp,-16
    80005de8:	e406                	sd	ra,8(sp)
    80005dea:	e022                	sd	s0,0(sp)
    80005dec:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005dee:	479d                	li	a5,7
    80005df0:	04a7cc63          	blt	a5,a0,80005e48 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005df4:	00028797          	auipc	a5,0x28
    80005df8:	24c78793          	addi	a5,a5,588 # 8002e040 <disk>
    80005dfc:	97aa                	add	a5,a5,a0
    80005dfe:	0187c783          	lbu	a5,24(a5)
    80005e02:	ebb9                	bnez	a5,80005e58 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005e04:	00451693          	slli	a3,a0,0x4
    80005e08:	00028797          	auipc	a5,0x28
    80005e0c:	23878793          	addi	a5,a5,568 # 8002e040 <disk>
    80005e10:	6398                	ld	a4,0(a5)
    80005e12:	9736                	add	a4,a4,a3
    80005e14:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80005e18:	6398                	ld	a4,0(a5)
    80005e1a:	9736                	add	a4,a4,a3
    80005e1c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005e20:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005e24:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005e28:	97aa                	add	a5,a5,a0
    80005e2a:	4705                	li	a4,1
    80005e2c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80005e30:	00028517          	auipc	a0,0x28
    80005e34:	22850513          	addi	a0,a0,552 # 8002e058 <disk+0x18>
    80005e38:	ffffc097          	auipc	ra,0xffffc
    80005e3c:	2ba080e7          	jalr	698(ra) # 800020f2 <wakeup>
}
    80005e40:	60a2                	ld	ra,8(sp)
    80005e42:	6402                	ld	s0,0(sp)
    80005e44:	0141                	addi	sp,sp,16
    80005e46:	8082                	ret
    panic("free_desc 1");
    80005e48:	00003517          	auipc	a0,0x3
    80005e4c:	a3050513          	addi	a0,a0,-1488 # 80008878 <syscalls+0x2f0>
    80005e50:	ffffa097          	auipc	ra,0xffffa
    80005e54:	6f0080e7          	jalr	1776(ra) # 80000540 <panic>
    panic("free_desc 2");
    80005e58:	00003517          	auipc	a0,0x3
    80005e5c:	a3050513          	addi	a0,a0,-1488 # 80008888 <syscalls+0x300>
    80005e60:	ffffa097          	auipc	ra,0xffffa
    80005e64:	6e0080e7          	jalr	1760(ra) # 80000540 <panic>

0000000080005e68 <virtio_disk_init>:
{
    80005e68:	1101                	addi	sp,sp,-32
    80005e6a:	ec06                	sd	ra,24(sp)
    80005e6c:	e822                	sd	s0,16(sp)
    80005e6e:	e426                	sd	s1,8(sp)
    80005e70:	e04a                	sd	s2,0(sp)
    80005e72:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e74:	00003597          	auipc	a1,0x3
    80005e78:	a2458593          	addi	a1,a1,-1500 # 80008898 <syscalls+0x310>
    80005e7c:	00028517          	auipc	a0,0x28
    80005e80:	2ec50513          	addi	a0,a0,748 # 8002e168 <disk+0x128>
    80005e84:	ffffb097          	auipc	ra,0xffffb
    80005e88:	cc2080e7          	jalr	-830(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e8c:	100017b7          	lui	a5,0x10001
    80005e90:	4398                	lw	a4,0(a5)
    80005e92:	2701                	sext.w	a4,a4
    80005e94:	747277b7          	lui	a5,0x74727
    80005e98:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e9c:	14f71b63          	bne	a4,a5,80005ff2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005ea0:	100017b7          	lui	a5,0x10001
    80005ea4:	43dc                	lw	a5,4(a5)
    80005ea6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005ea8:	4709                	li	a4,2
    80005eaa:	14e79463          	bne	a5,a4,80005ff2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005eae:	100017b7          	lui	a5,0x10001
    80005eb2:	479c                	lw	a5,8(a5)
    80005eb4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005eb6:	12e79e63          	bne	a5,a4,80005ff2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005eba:	100017b7          	lui	a5,0x10001
    80005ebe:	47d8                	lw	a4,12(a5)
    80005ec0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ec2:	554d47b7          	lui	a5,0x554d4
    80005ec6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005eca:	12f71463          	bne	a4,a5,80005ff2 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ece:	100017b7          	lui	a5,0x10001
    80005ed2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ed6:	4705                	li	a4,1
    80005ed8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eda:	470d                	li	a4,3
    80005edc:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005ede:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005ee0:	c7ffe6b7          	lui	a3,0xc7ffe
    80005ee4:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fd05df>
    80005ee8:	8f75                	and	a4,a4,a3
    80005eea:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eec:	472d                	li	a4,11
    80005eee:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005ef0:	5bbc                	lw	a5,112(a5)
    80005ef2:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005ef6:	8ba1                	andi	a5,a5,8
    80005ef8:	10078563          	beqz	a5,80006002 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005efc:	100017b7          	lui	a5,0x10001
    80005f00:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005f04:	43fc                	lw	a5,68(a5)
    80005f06:	2781                	sext.w	a5,a5
    80005f08:	10079563          	bnez	a5,80006012 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005f0c:	100017b7          	lui	a5,0x10001
    80005f10:	5bdc                	lw	a5,52(a5)
    80005f12:	2781                	sext.w	a5,a5
  if(max == 0)
    80005f14:	10078763          	beqz	a5,80006022 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80005f18:	471d                	li	a4,7
    80005f1a:	10f77c63          	bgeu	a4,a5,80006032 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    80005f1e:	ffffb097          	auipc	ra,0xffffb
    80005f22:	bc8080e7          	jalr	-1080(ra) # 80000ae6 <kalloc>
    80005f26:	00028497          	auipc	s1,0x28
    80005f2a:	11a48493          	addi	s1,s1,282 # 8002e040 <disk>
    80005f2e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005f30:	ffffb097          	auipc	ra,0xffffb
    80005f34:	bb6080e7          	jalr	-1098(ra) # 80000ae6 <kalloc>
    80005f38:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005f3a:	ffffb097          	auipc	ra,0xffffb
    80005f3e:	bac080e7          	jalr	-1108(ra) # 80000ae6 <kalloc>
    80005f42:	87aa                	mv	a5,a0
    80005f44:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005f46:	6088                	ld	a0,0(s1)
    80005f48:	cd6d                	beqz	a0,80006042 <virtio_disk_init+0x1da>
    80005f4a:	00028717          	auipc	a4,0x28
    80005f4e:	0fe73703          	ld	a4,254(a4) # 8002e048 <disk+0x8>
    80005f52:	cb65                	beqz	a4,80006042 <virtio_disk_init+0x1da>
    80005f54:	c7fd                	beqz	a5,80006042 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80005f56:	6605                	lui	a2,0x1
    80005f58:	4581                	li	a1,0
    80005f5a:	ffffb097          	auipc	ra,0xffffb
    80005f5e:	d78080e7          	jalr	-648(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80005f62:	00028497          	auipc	s1,0x28
    80005f66:	0de48493          	addi	s1,s1,222 # 8002e040 <disk>
    80005f6a:	6605                	lui	a2,0x1
    80005f6c:	4581                	li	a1,0
    80005f6e:	6488                	ld	a0,8(s1)
    80005f70:	ffffb097          	auipc	ra,0xffffb
    80005f74:	d62080e7          	jalr	-670(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    80005f78:	6605                	lui	a2,0x1
    80005f7a:	4581                	li	a1,0
    80005f7c:	6888                	ld	a0,16(s1)
    80005f7e:	ffffb097          	auipc	ra,0xffffb
    80005f82:	d54080e7          	jalr	-684(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f86:	100017b7          	lui	a5,0x10001
    80005f8a:	4721                	li	a4,8
    80005f8c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005f8e:	4098                	lw	a4,0(s1)
    80005f90:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005f94:	40d8                	lw	a4,4(s1)
    80005f96:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005f9a:	6498                	ld	a4,8(s1)
    80005f9c:	0007069b          	sext.w	a3,a4
    80005fa0:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005fa4:	9701                	srai	a4,a4,0x20
    80005fa6:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005faa:	6898                	ld	a4,16(s1)
    80005fac:	0007069b          	sext.w	a3,a4
    80005fb0:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005fb4:	9701                	srai	a4,a4,0x20
    80005fb6:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80005fba:	4705                	li	a4,1
    80005fbc:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80005fbe:	00e48c23          	sb	a4,24(s1)
    80005fc2:	00e48ca3          	sb	a4,25(s1)
    80005fc6:	00e48d23          	sb	a4,26(s1)
    80005fca:	00e48da3          	sb	a4,27(s1)
    80005fce:	00e48e23          	sb	a4,28(s1)
    80005fd2:	00e48ea3          	sb	a4,29(s1)
    80005fd6:	00e48f23          	sb	a4,30(s1)
    80005fda:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005fde:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fe2:	0727a823          	sw	s2,112(a5)
}
    80005fe6:	60e2                	ld	ra,24(sp)
    80005fe8:	6442                	ld	s0,16(sp)
    80005fea:	64a2                	ld	s1,8(sp)
    80005fec:	6902                	ld	s2,0(sp)
    80005fee:	6105                	addi	sp,sp,32
    80005ff0:	8082                	ret
    panic("could not find virtio disk");
    80005ff2:	00003517          	auipc	a0,0x3
    80005ff6:	8b650513          	addi	a0,a0,-1866 # 800088a8 <syscalls+0x320>
    80005ffa:	ffffa097          	auipc	ra,0xffffa
    80005ffe:	546080e7          	jalr	1350(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006002:	00003517          	auipc	a0,0x3
    80006006:	8c650513          	addi	a0,a0,-1850 # 800088c8 <syscalls+0x340>
    8000600a:	ffffa097          	auipc	ra,0xffffa
    8000600e:	536080e7          	jalr	1334(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80006012:	00003517          	auipc	a0,0x3
    80006016:	8d650513          	addi	a0,a0,-1834 # 800088e8 <syscalls+0x360>
    8000601a:	ffffa097          	auipc	ra,0xffffa
    8000601e:	526080e7          	jalr	1318(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80006022:	00003517          	auipc	a0,0x3
    80006026:	8e650513          	addi	a0,a0,-1818 # 80008908 <syscalls+0x380>
    8000602a:	ffffa097          	auipc	ra,0xffffa
    8000602e:	516080e7          	jalr	1302(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80006032:	00003517          	auipc	a0,0x3
    80006036:	8f650513          	addi	a0,a0,-1802 # 80008928 <syscalls+0x3a0>
    8000603a:	ffffa097          	auipc	ra,0xffffa
    8000603e:	506080e7          	jalr	1286(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    80006042:	00003517          	auipc	a0,0x3
    80006046:	90650513          	addi	a0,a0,-1786 # 80008948 <syscalls+0x3c0>
    8000604a:	ffffa097          	auipc	ra,0xffffa
    8000604e:	4f6080e7          	jalr	1270(ra) # 80000540 <panic>

0000000080006052 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006052:	7119                	addi	sp,sp,-128
    80006054:	fc86                	sd	ra,120(sp)
    80006056:	f8a2                	sd	s0,112(sp)
    80006058:	f4a6                	sd	s1,104(sp)
    8000605a:	f0ca                	sd	s2,96(sp)
    8000605c:	ecce                	sd	s3,88(sp)
    8000605e:	e8d2                	sd	s4,80(sp)
    80006060:	e4d6                	sd	s5,72(sp)
    80006062:	e0da                	sd	s6,64(sp)
    80006064:	fc5e                	sd	s7,56(sp)
    80006066:	f862                	sd	s8,48(sp)
    80006068:	f466                	sd	s9,40(sp)
    8000606a:	f06a                	sd	s10,32(sp)
    8000606c:	ec6e                	sd	s11,24(sp)
    8000606e:	0100                	addi	s0,sp,128
    80006070:	8aaa                	mv	s5,a0
    80006072:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006074:	00c52d03          	lw	s10,12(a0)
    80006078:	001d1d1b          	slliw	s10,s10,0x1
    8000607c:	1d02                	slli	s10,s10,0x20
    8000607e:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006082:	00028517          	auipc	a0,0x28
    80006086:	0e650513          	addi	a0,a0,230 # 8002e168 <disk+0x128>
    8000608a:	ffffb097          	auipc	ra,0xffffb
    8000608e:	b4c080e7          	jalr	-1204(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80006092:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006094:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006096:	00028b97          	auipc	s7,0x28
    8000609a:	faab8b93          	addi	s7,s7,-86 # 8002e040 <disk>
  for(int i = 0; i < 3; i++){
    8000609e:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800060a0:	00028c97          	auipc	s9,0x28
    800060a4:	0c8c8c93          	addi	s9,s9,200 # 8002e168 <disk+0x128>
    800060a8:	a08d                	j	8000610a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800060aa:	00fb8733          	add	a4,s7,a5
    800060ae:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800060b2:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800060b4:	0207c563          	bltz	a5,800060de <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    800060b8:	2905                	addiw	s2,s2,1
    800060ba:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    800060bc:	05690c63          	beq	s2,s6,80006114 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    800060c0:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800060c2:	00028717          	auipc	a4,0x28
    800060c6:	f7e70713          	addi	a4,a4,-130 # 8002e040 <disk>
    800060ca:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800060cc:	01874683          	lbu	a3,24(a4)
    800060d0:	fee9                	bnez	a3,800060aa <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    800060d2:	2785                	addiw	a5,a5,1
    800060d4:	0705                	addi	a4,a4,1
    800060d6:	fe979be3          	bne	a5,s1,800060cc <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    800060da:	57fd                	li	a5,-1
    800060dc:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800060de:	01205d63          	blez	s2,800060f8 <virtio_disk_rw+0xa6>
    800060e2:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800060e4:	000a2503          	lw	a0,0(s4)
    800060e8:	00000097          	auipc	ra,0x0
    800060ec:	cfe080e7          	jalr	-770(ra) # 80005de6 <free_desc>
      for(int j = 0; j < i; j++)
    800060f0:	2d85                	addiw	s11,s11,1
    800060f2:	0a11                	addi	s4,s4,4
    800060f4:	ff2d98e3          	bne	s11,s2,800060e4 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800060f8:	85e6                	mv	a1,s9
    800060fa:	00028517          	auipc	a0,0x28
    800060fe:	f5e50513          	addi	a0,a0,-162 # 8002e058 <disk+0x18>
    80006102:	ffffc097          	auipc	ra,0xffffc
    80006106:	f8c080e7          	jalr	-116(ra) # 8000208e <sleep>
  for(int i = 0; i < 3; i++){
    8000610a:	f8040a13          	addi	s4,s0,-128
{
    8000610e:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006110:	894e                	mv	s2,s3
    80006112:	b77d                	j	800060c0 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006114:	f8042503          	lw	a0,-128(s0)
    80006118:	00a50713          	addi	a4,a0,10
    8000611c:	0712                	slli	a4,a4,0x4

  if(write)
    8000611e:	00028797          	auipc	a5,0x28
    80006122:	f2278793          	addi	a5,a5,-222 # 8002e040 <disk>
    80006126:	00e786b3          	add	a3,a5,a4
    8000612a:	01803633          	snez	a2,s8
    8000612e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006130:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006134:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006138:	f6070613          	addi	a2,a4,-160
    8000613c:	6394                	ld	a3,0(a5)
    8000613e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006140:	00870593          	addi	a1,a4,8
    80006144:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006146:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006148:	0007b803          	ld	a6,0(a5)
    8000614c:	9642                	add	a2,a2,a6
    8000614e:	46c1                	li	a3,16
    80006150:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006152:	4585                	li	a1,1
    80006154:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006158:	f8442683          	lw	a3,-124(s0)
    8000615c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006160:	0692                	slli	a3,a3,0x4
    80006162:	9836                	add	a6,a6,a3
    80006164:	058a8613          	addi	a2,s5,88
    80006168:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    8000616c:	0007b803          	ld	a6,0(a5)
    80006170:	96c2                	add	a3,a3,a6
    80006172:	40000613          	li	a2,1024
    80006176:	c690                	sw	a2,8(a3)
  if(write)
    80006178:	001c3613          	seqz	a2,s8
    8000617c:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006180:	00166613          	ori	a2,a2,1
    80006184:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006188:	f8842603          	lw	a2,-120(s0)
    8000618c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006190:	00250693          	addi	a3,a0,2
    80006194:	0692                	slli	a3,a3,0x4
    80006196:	96be                	add	a3,a3,a5
    80006198:	58fd                	li	a7,-1
    8000619a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000619e:	0612                	slli	a2,a2,0x4
    800061a0:	9832                	add	a6,a6,a2
    800061a2:	f9070713          	addi	a4,a4,-112
    800061a6:	973e                	add	a4,a4,a5
    800061a8:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    800061ac:	6398                	ld	a4,0(a5)
    800061ae:	9732                	add	a4,a4,a2
    800061b0:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800061b2:	4609                	li	a2,2
    800061b4:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    800061b8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800061bc:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    800061c0:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800061c4:	6794                	ld	a3,8(a5)
    800061c6:	0026d703          	lhu	a4,2(a3)
    800061ca:	8b1d                	andi	a4,a4,7
    800061cc:	0706                	slli	a4,a4,0x1
    800061ce:	96ba                	add	a3,a3,a4
    800061d0:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    800061d4:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800061d8:	6798                	ld	a4,8(a5)
    800061da:	00275783          	lhu	a5,2(a4)
    800061de:	2785                	addiw	a5,a5,1
    800061e0:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800061e4:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800061e8:	100017b7          	lui	a5,0x10001
    800061ec:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800061f0:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    800061f4:	00028917          	auipc	s2,0x28
    800061f8:	f7490913          	addi	s2,s2,-140 # 8002e168 <disk+0x128>
  while(b->disk == 1) {
    800061fc:	4485                	li	s1,1
    800061fe:	00b79c63          	bne	a5,a1,80006216 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006202:	85ca                	mv	a1,s2
    80006204:	8556                	mv	a0,s5
    80006206:	ffffc097          	auipc	ra,0xffffc
    8000620a:	e88080e7          	jalr	-376(ra) # 8000208e <sleep>
  while(b->disk == 1) {
    8000620e:	004aa783          	lw	a5,4(s5)
    80006212:	fe9788e3          	beq	a5,s1,80006202 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006216:	f8042903          	lw	s2,-128(s0)
    8000621a:	00290713          	addi	a4,s2,2
    8000621e:	0712                	slli	a4,a4,0x4
    80006220:	00028797          	auipc	a5,0x28
    80006224:	e2078793          	addi	a5,a5,-480 # 8002e040 <disk>
    80006228:	97ba                	add	a5,a5,a4
    8000622a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000622e:	00028997          	auipc	s3,0x28
    80006232:	e1298993          	addi	s3,s3,-494 # 8002e040 <disk>
    80006236:	00491713          	slli	a4,s2,0x4
    8000623a:	0009b783          	ld	a5,0(s3)
    8000623e:	97ba                	add	a5,a5,a4
    80006240:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006244:	854a                	mv	a0,s2
    80006246:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000624a:	00000097          	auipc	ra,0x0
    8000624e:	b9c080e7          	jalr	-1124(ra) # 80005de6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006252:	8885                	andi	s1,s1,1
    80006254:	f0ed                	bnez	s1,80006236 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006256:	00028517          	auipc	a0,0x28
    8000625a:	f1250513          	addi	a0,a0,-238 # 8002e168 <disk+0x128>
    8000625e:	ffffb097          	auipc	ra,0xffffb
    80006262:	a2c080e7          	jalr	-1492(ra) # 80000c8a <release>
}
    80006266:	70e6                	ld	ra,120(sp)
    80006268:	7446                	ld	s0,112(sp)
    8000626a:	74a6                	ld	s1,104(sp)
    8000626c:	7906                	ld	s2,96(sp)
    8000626e:	69e6                	ld	s3,88(sp)
    80006270:	6a46                	ld	s4,80(sp)
    80006272:	6aa6                	ld	s5,72(sp)
    80006274:	6b06                	ld	s6,64(sp)
    80006276:	7be2                	ld	s7,56(sp)
    80006278:	7c42                	ld	s8,48(sp)
    8000627a:	7ca2                	ld	s9,40(sp)
    8000627c:	7d02                	ld	s10,32(sp)
    8000627e:	6de2                	ld	s11,24(sp)
    80006280:	6109                	addi	sp,sp,128
    80006282:	8082                	ret

0000000080006284 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006284:	1101                	addi	sp,sp,-32
    80006286:	ec06                	sd	ra,24(sp)
    80006288:	e822                	sd	s0,16(sp)
    8000628a:	e426                	sd	s1,8(sp)
    8000628c:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000628e:	00028497          	auipc	s1,0x28
    80006292:	db248493          	addi	s1,s1,-590 # 8002e040 <disk>
    80006296:	00028517          	auipc	a0,0x28
    8000629a:	ed250513          	addi	a0,a0,-302 # 8002e168 <disk+0x128>
    8000629e:	ffffb097          	auipc	ra,0xffffb
    800062a2:	938080e7          	jalr	-1736(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800062a6:	10001737          	lui	a4,0x10001
    800062aa:	533c                	lw	a5,96(a4)
    800062ac:	8b8d                	andi	a5,a5,3
    800062ae:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800062b0:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800062b4:	689c                	ld	a5,16(s1)
    800062b6:	0204d703          	lhu	a4,32(s1)
    800062ba:	0027d783          	lhu	a5,2(a5)
    800062be:	04f70863          	beq	a4,a5,8000630e <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800062c2:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800062c6:	6898                	ld	a4,16(s1)
    800062c8:	0204d783          	lhu	a5,32(s1)
    800062cc:	8b9d                	andi	a5,a5,7
    800062ce:	078e                	slli	a5,a5,0x3
    800062d0:	97ba                	add	a5,a5,a4
    800062d2:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800062d4:	00278713          	addi	a4,a5,2
    800062d8:	0712                	slli	a4,a4,0x4
    800062da:	9726                	add	a4,a4,s1
    800062dc:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800062e0:	e721                	bnez	a4,80006328 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800062e2:	0789                	addi	a5,a5,2
    800062e4:	0792                	slli	a5,a5,0x4
    800062e6:	97a6                	add	a5,a5,s1
    800062e8:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800062ea:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800062ee:	ffffc097          	auipc	ra,0xffffc
    800062f2:	e04080e7          	jalr	-508(ra) # 800020f2 <wakeup>

    disk.used_idx += 1;
    800062f6:	0204d783          	lhu	a5,32(s1)
    800062fa:	2785                	addiw	a5,a5,1
    800062fc:	17c2                	slli	a5,a5,0x30
    800062fe:	93c1                	srli	a5,a5,0x30
    80006300:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006304:	6898                	ld	a4,16(s1)
    80006306:	00275703          	lhu	a4,2(a4)
    8000630a:	faf71ce3          	bne	a4,a5,800062c2 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000630e:	00028517          	auipc	a0,0x28
    80006312:	e5a50513          	addi	a0,a0,-422 # 8002e168 <disk+0x128>
    80006316:	ffffb097          	auipc	ra,0xffffb
    8000631a:	974080e7          	jalr	-1676(ra) # 80000c8a <release>
}
    8000631e:	60e2                	ld	ra,24(sp)
    80006320:	6442                	ld	s0,16(sp)
    80006322:	64a2                	ld	s1,8(sp)
    80006324:	6105                	addi	sp,sp,32
    80006326:	8082                	ret
      panic("virtio_disk_intr status");
    80006328:	00002517          	auipc	a0,0x2
    8000632c:	63850513          	addi	a0,a0,1592 # 80008960 <syscalls+0x3d8>
    80006330:	ffffa097          	auipc	ra,0xffffa
    80006334:	210080e7          	jalr	528(ra) # 80000540 <panic>

0000000080006338 <init_list_head>:
#include "defs.h"
#include "spinlock.h"
#include "proc.h"

void init_list_head(struct list_head *list)
{
    80006338:	1141                	addi	sp,sp,-16
    8000633a:	e422                	sd	s0,8(sp)
    8000633c:	0800                	addi	s0,sp,16
  list->next = list;
    8000633e:	e108                	sd	a0,0(a0)
  list->prev = list;
    80006340:	e508                	sd	a0,8(a0)
}
    80006342:	6422                	ld	s0,8(sp)
    80006344:	0141                	addi	sp,sp,16
    80006346:	8082                	ret

0000000080006348 <list_add>:
  next->prev = prev;
  prev->next = next;
}

void list_add(struct list_head *head, struct list_head *new)
{
    80006348:	1141                	addi	sp,sp,-16
    8000634a:	e422                	sd	s0,8(sp)
    8000634c:	0800                	addi	s0,sp,16
  __list_add(new, head, head->next);
    8000634e:	611c                	ld	a5,0(a0)
  next->prev = new;
    80006350:	e78c                	sd	a1,8(a5)
  new->next = next;
    80006352:	e19c                	sd	a5,0(a1)
  new->prev = prev;
    80006354:	e588                	sd	a0,8(a1)
  prev->next = new;
    80006356:	e10c                	sd	a1,0(a0)
}
    80006358:	6422                	ld	s0,8(sp)
    8000635a:	0141                	addi	sp,sp,16
    8000635c:	8082                	ret

000000008000635e <list_add_tail>:

void list_add_tail(struct list_head *head, struct list_head *new)
{
    8000635e:	1141                	addi	sp,sp,-16
    80006360:	e422                	sd	s0,8(sp)
    80006362:	0800                	addi	s0,sp,16
  __list_add(new, head->prev, head);
    80006364:	651c                	ld	a5,8(a0)
  next->prev = new;
    80006366:	e50c                	sd	a1,8(a0)
  new->next = next;
    80006368:	e188                	sd	a0,0(a1)
  new->prev = prev;
    8000636a:	e59c                	sd	a5,8(a1)
  prev->next = new;
    8000636c:	e38c                	sd	a1,0(a5)
}
    8000636e:	6422                	ld	s0,8(sp)
    80006370:	0141                	addi	sp,sp,16
    80006372:	8082                	ret

0000000080006374 <list_del>:

void list_del(struct list_head *entry)
{
    80006374:	1141                	addi	sp,sp,-16
    80006376:	e422                	sd	s0,8(sp)
    80006378:	0800                	addi	s0,sp,16
  __list_del(entry->prev, entry->next);
    8000637a:	651c                	ld	a5,8(a0)
    8000637c:	6118                	ld	a4,0(a0)
  next->prev = prev;
    8000637e:	e71c                	sd	a5,8(a4)
  prev->next = next;
    80006380:	e398                	sd	a4,0(a5)
  entry->prev = entry->next = entry;
    80006382:	e108                	sd	a0,0(a0)
    80006384:	e508                	sd	a0,8(a0)
}
    80006386:	6422                	ld	s0,8(sp)
    80006388:	0141                	addi	sp,sp,16
    8000638a:	8082                	ret

000000008000638c <list_del_init>:

void list_del_init(struct list_head *entry)
{
    8000638c:	1141                	addi	sp,sp,-16
    8000638e:	e422                	sd	s0,8(sp)
    80006390:	0800                	addi	s0,sp,16
  __list_del(entry->prev, entry->next);
    80006392:	651c                	ld	a5,8(a0)
    80006394:	6118                	ld	a4,0(a0)
  next->prev = prev;
    80006396:	e71c                	sd	a5,8(a4)
  prev->next = next;
    80006398:	e398                	sd	a4,0(a5)
  list->next = list;
    8000639a:	e108                	sd	a0,0(a0)
  list->prev = list;
    8000639c:	e508                	sd	a0,8(a0)
  init_list_head(entry);
}
    8000639e:	6422                	ld	s0,8(sp)
    800063a0:	0141                	addi	sp,sp,16
    800063a2:	8082                	ret
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
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
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
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
