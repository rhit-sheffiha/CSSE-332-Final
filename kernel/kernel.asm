
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	aa813103          	ld	sp,-1368(sp) # 80008aa8 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000066:	cde78793          	addi	a5,a5,-802 # 80005d40 <timervec>
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
    8000012e:	3ec080e7          	jalr	1004(ra) # 80002516 <either_copyin>
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
    800001cc:	198080e7          	jalr	408(ra) # 80002360 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	ee2080e7          	jalr	-286(ra) # 800020b8 <sleep>
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
    80000216:	2ae080e7          	jalr	686(ra) # 800024c0 <either_copyout>
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
    800002f6:	27a080e7          	jalr	634(ra) # 8000256c <procdump>
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
    8000044a:	cd6080e7          	jalr	-810(ra) # 8000211c <wakeup>
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
    80000898:	888080e7          	jalr	-1912(ra) # 8000211c <wakeup>
    
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
    80000922:	79a080e7          	jalr	1946(ra) # 800020b8 <sleep>
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
    80000ec2:	7f0080e7          	jalr	2032(ra) # 800026ae <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	eba080e7          	jalr	-326(ra) # 80005d80 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	00e080e7          	jalr	14(ra) # 80001edc <scheduler>
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
    80000f3a:	750080e7          	jalr	1872(ra) # 80002686 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00001097          	auipc	ra,0x1
    80000f42:	770080e7          	jalr	1904(ra) # 800026ae <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	e24080e7          	jalr	-476(ra) # 80005d6a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	e32080e7          	jalr	-462(ra) # 80005d80 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	fca080e7          	jalr	-54(ra) # 80002f20 <binit>
    iinit();         // inode table
    80000f5e:	00002097          	auipc	ra,0x2
    80000f62:	66a080e7          	jalr	1642(ra) # 800035c8 <iinit>
    fileinit();      // file table
    80000f66:	00003097          	auipc	ra,0x3
    80000f6a:	610080e7          	jalr	1552(ra) # 80004576 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	f1a080e7          	jalr	-230(ra) # 80005e88 <virtio_disk_init>
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
    80001a00:	fa47a783          	lw	a5,-92(a5) # 800089a0 <first.1>
    80001a04:	eb89                	bnez	a5,80001a16 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a06:	00001097          	auipc	ra,0x1
    80001a0a:	cc0080e7          	jalr	-832(ra) # 800026c6 <usertrapret>
}
    80001a0e:	60a2                	ld	ra,8(sp)
    80001a10:	6402                	ld	s0,0(sp)
    80001a12:	0141                	addi	sp,sp,16
    80001a14:	8082                	ret
    first = 0;
    80001a16:	00007797          	auipc	a5,0x7
    80001a1a:	f807a523          	sw	zero,-118(a5) # 800089a0 <first.1>
    fsinit(ROOTDEV);
    80001a1e:	4505                	li	a0,1
    80001a20:	00002097          	auipc	ra,0x2
    80001a24:	b28080e7          	jalr	-1240(ra) # 80003548 <fsinit>
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
    80001a4c:	f5c78793          	addi	a5,a5,-164 # 800089a4 <nextpid>
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
    80001ca8:	d0c58593          	addi	a1,a1,-756 # 800089b0 <initcode>
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
    80001ce6:	290080e7          	jalr	656(ra) # 80003f72 <namei>
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
    80001e16:	7f6080e7          	jalr	2038(ra) # 80004608 <filedup>
    80001e1a:	00a93023          	sd	a0,0(s2)
    80001e1e:	b7e5                	j	80001e06 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e20:	150ab503          	ld	a0,336(s5)
    80001e24:	00002097          	auipc	ra,0x2
    80001e28:	964080e7          	jalr	-1692(ra) # 80003788 <idup>
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
    80001ea2:	1101                	addi	sp,sp,-32
    80001ea4:	ec06                	sd	ra,24(sp)
    80001ea6:	e822                	sd	s0,16(sp)
    80001ea8:	e426                	sd	s1,8(sp)
    80001eaa:	1000                	addi	s0,sp,32
    80001eac:	84aa                	mv	s1,a0
  printf("In audit\n");
    80001eae:	00006517          	auipc	a0,0x6
    80001eb2:	36a50513          	addi	a0,a0,874 # 80008218 <digits+0x1d8>
    80001eb6:	ffffe097          	auipc	ra,0xffffe
    80001eba:	6d4080e7          	jalr	1748(ra) # 8000058a <printf>
  printf("%d\n", (uint64) arr);
    80001ebe:	85a6                	mv	a1,s1
    80001ec0:	00006517          	auipc	a0,0x6
    80001ec4:	60850513          	addi	a0,a0,1544 # 800084c8 <states.0+0x1f0>
    80001ec8:	ffffe097          	auipc	ra,0xffffe
    80001ecc:	6c2080e7          	jalr	1730(ra) # 8000058a <printf>
}
    80001ed0:	8526                	mv	a0,s1
    80001ed2:	60e2                	ld	ra,24(sp)
    80001ed4:	6442                	ld	s0,16(sp)
    80001ed6:	64a2                	ld	s1,8(sp)
    80001ed8:	6105                	addi	sp,sp,32
    80001eda:	8082                	ret

0000000080001edc <scheduler>:
{
    80001edc:	715d                	addi	sp,sp,-80
    80001ede:	e486                	sd	ra,72(sp)
    80001ee0:	e0a2                	sd	s0,64(sp)
    80001ee2:	fc26                	sd	s1,56(sp)
    80001ee4:	f84a                	sd	s2,48(sp)
    80001ee6:	f44e                	sd	s3,40(sp)
    80001ee8:	f052                	sd	s4,32(sp)
    80001eea:	ec56                	sd	s5,24(sp)
    80001eec:	e85a                	sd	s6,16(sp)
    80001eee:	e45e                	sd	s7,8(sp)
    80001ef0:	e062                	sd	s8,0(sp)
    80001ef2:	0880                	addi	s0,sp,80
    80001ef4:	8492                	mv	s1,tp
  int id = r_tp();
    80001ef6:	2481                	sext.w	s1,s1
  init_list_head(&runq);
    80001ef8:	0000f517          	auipc	a0,0xf
    80001efc:	29850513          	addi	a0,a0,664 # 80011190 <runq>
    80001f00:	00004097          	auipc	ra,0x4
    80001f04:	458080e7          	jalr	1112(ra) # 80006358 <init_list_head>
  c->proc = 0;
    80001f08:	00749b13          	slli	s6,s1,0x7
    80001f0c:	0000f797          	auipc	a5,0xf
    80001f10:	e5478793          	addi	a5,a5,-428 # 80010d60 <pid_lock>
    80001f14:	97da                	add	a5,a5,s6
    80001f16:	0207b823          	sd	zero,48(a5)
        swtch(&c->context, &p->context);
    80001f1a:	0000f797          	auipc	a5,0xf
    80001f1e:	e7e78793          	addi	a5,a5,-386 # 80010d98 <cpus+0x8>
    80001f22:	9b3e                	add	s6,s6,a5
    not_runnable_count = 0;
    80001f24:	4c01                	li	s8,0
        p->state = RUNNING;
    80001f26:	4b91                	li	s7,4
        c->proc = p;
    80001f28:	049e                	slli	s1,s1,0x7
    80001f2a:	0000fa97          	auipc	s5,0xf
    80001f2e:	e36a8a93          	addi	s5,s5,-458 # 80010d60 <pid_lock>
    80001f32:	9aa6                	add	s5,s5,s1
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f34:	00015a17          	auipc	s4,0x15
    80001f38:	e6ca0a13          	addi	s4,s4,-404 # 80016da0 <tickslock>
    80001f3c:	a0a9                	j	80001f86 <scheduler+0xaa>
        not_runnable_count++;
    80001f3e:	2905                	addiw	s2,s2,1
      release(&p->lock);
    80001f40:	8526                	mv	a0,s1
    80001f42:	fffff097          	auipc	ra,0xfffff
    80001f46:	d48080e7          	jalr	-696(ra) # 80000c8a <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f4a:	17048493          	addi	s1,s1,368
    80001f4e:	03448863          	beq	s1,s4,80001f7e <scheduler+0xa2>
      acquire(&p->lock);
    80001f52:	8526                	mv	a0,s1
    80001f54:	fffff097          	auipc	ra,0xfffff
    80001f58:	c82080e7          	jalr	-894(ra) # 80000bd6 <acquire>
      if(p->state == RUNNABLE) {
    80001f5c:	4c9c                	lw	a5,24(s1)
    80001f5e:	ff3790e3          	bne	a5,s3,80001f3e <scheduler+0x62>
        p->state = RUNNING;
    80001f62:	0174ac23          	sw	s7,24(s1)
        c->proc = p;
    80001f66:	029ab823          	sd	s1,48(s5)
        swtch(&c->context, &p->context);
    80001f6a:	06048593          	addi	a1,s1,96
    80001f6e:	855a                	mv	a0,s6
    80001f70:	00000097          	auipc	ra,0x0
    80001f74:	6ac080e7          	jalr	1708(ra) # 8000261c <swtch>
        c->proc = 0;
    80001f78:	020ab823          	sd	zero,48(s5)
    80001f7c:	b7d1                	j	80001f40 <scheduler+0x64>
    if (not_runnable_count == NPROC) {
    80001f7e:	04000793          	li	a5,64
    80001f82:	00f90f63          	beq	s2,a5,80001fa0 <scheduler+0xc4>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f86:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f8a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f8e:	10079073          	csrw	sstatus,a5
    not_runnable_count = 0;
    80001f92:	8962                	mv	s2,s8
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f94:	0000f497          	auipc	s1,0xf
    80001f98:	20c48493          	addi	s1,s1,524 # 800111a0 <proc>
      if(p->state == RUNNABLE) {
    80001f9c:	498d                	li	s3,3
    80001f9e:	bf55                	j	80001f52 <scheduler+0x76>
  asm volatile("wfi");
    80001fa0:	10500073          	wfi
}
    80001fa4:	b7cd                	j	80001f86 <scheduler+0xaa>

0000000080001fa6 <sched>:
{
    80001fa6:	7179                	addi	sp,sp,-48
    80001fa8:	f406                	sd	ra,40(sp)
    80001faa:	f022                	sd	s0,32(sp)
    80001fac:	ec26                	sd	s1,24(sp)
    80001fae:	e84a                	sd	s2,16(sp)
    80001fb0:	e44e                	sd	s3,8(sp)
    80001fb2:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fb4:	00000097          	auipc	ra,0x0
    80001fb8:	9f8080e7          	jalr	-1544(ra) # 800019ac <myproc>
    80001fbc:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001fbe:	fffff097          	auipc	ra,0xfffff
    80001fc2:	b9e080e7          	jalr	-1122(ra) # 80000b5c <holding>
    80001fc6:	c93d                	beqz	a0,8000203c <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fc8:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001fca:	2781                	sext.w	a5,a5
    80001fcc:	079e                	slli	a5,a5,0x7
    80001fce:	0000f717          	auipc	a4,0xf
    80001fd2:	d9270713          	addi	a4,a4,-622 # 80010d60 <pid_lock>
    80001fd6:	97ba                	add	a5,a5,a4
    80001fd8:	0a87a703          	lw	a4,168(a5)
    80001fdc:	4785                	li	a5,1
    80001fde:	06f71763          	bne	a4,a5,8000204c <sched+0xa6>
  if(p->state == RUNNING)
    80001fe2:	4c98                	lw	a4,24(s1)
    80001fe4:	4791                	li	a5,4
    80001fe6:	06f70b63          	beq	a4,a5,8000205c <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fea:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001fee:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001ff0:	efb5                	bnez	a5,8000206c <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ff2:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001ff4:	0000f917          	auipc	s2,0xf
    80001ff8:	d6c90913          	addi	s2,s2,-660 # 80010d60 <pid_lock>
    80001ffc:	2781                	sext.w	a5,a5
    80001ffe:	079e                	slli	a5,a5,0x7
    80002000:	97ca                	add	a5,a5,s2
    80002002:	0ac7a983          	lw	s3,172(a5)
    80002006:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002008:	2781                	sext.w	a5,a5
    8000200a:	079e                	slli	a5,a5,0x7
    8000200c:	0000f597          	auipc	a1,0xf
    80002010:	d8c58593          	addi	a1,a1,-628 # 80010d98 <cpus+0x8>
    80002014:	95be                	add	a1,a1,a5
    80002016:	06048513          	addi	a0,s1,96
    8000201a:	00000097          	auipc	ra,0x0
    8000201e:	602080e7          	jalr	1538(ra) # 8000261c <swtch>
    80002022:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002024:	2781                	sext.w	a5,a5
    80002026:	079e                	slli	a5,a5,0x7
    80002028:	993e                	add	s2,s2,a5
    8000202a:	0b392623          	sw	s3,172(s2)
}
    8000202e:	70a2                	ld	ra,40(sp)
    80002030:	7402                	ld	s0,32(sp)
    80002032:	64e2                	ld	s1,24(sp)
    80002034:	6942                	ld	s2,16(sp)
    80002036:	69a2                	ld	s3,8(sp)
    80002038:	6145                	addi	sp,sp,48
    8000203a:	8082                	ret
    panic("sched p->lock");
    8000203c:	00006517          	auipc	a0,0x6
    80002040:	1ec50513          	addi	a0,a0,492 # 80008228 <digits+0x1e8>
    80002044:	ffffe097          	auipc	ra,0xffffe
    80002048:	4fc080e7          	jalr	1276(ra) # 80000540 <panic>
    panic("sched locks");
    8000204c:	00006517          	auipc	a0,0x6
    80002050:	1ec50513          	addi	a0,a0,492 # 80008238 <digits+0x1f8>
    80002054:	ffffe097          	auipc	ra,0xffffe
    80002058:	4ec080e7          	jalr	1260(ra) # 80000540 <panic>
    panic("sched running");
    8000205c:	00006517          	auipc	a0,0x6
    80002060:	1ec50513          	addi	a0,a0,492 # 80008248 <digits+0x208>
    80002064:	ffffe097          	auipc	ra,0xffffe
    80002068:	4dc080e7          	jalr	1244(ra) # 80000540 <panic>
    panic("sched interruptible");
    8000206c:	00006517          	auipc	a0,0x6
    80002070:	1ec50513          	addi	a0,a0,492 # 80008258 <digits+0x218>
    80002074:	ffffe097          	auipc	ra,0xffffe
    80002078:	4cc080e7          	jalr	1228(ra) # 80000540 <panic>

000000008000207c <yield>:
{
    8000207c:	1101                	addi	sp,sp,-32
    8000207e:	ec06                	sd	ra,24(sp)
    80002080:	e822                	sd	s0,16(sp)
    80002082:	e426                	sd	s1,8(sp)
    80002084:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002086:	00000097          	auipc	ra,0x0
    8000208a:	926080e7          	jalr	-1754(ra) # 800019ac <myproc>
    8000208e:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002090:	fffff097          	auipc	ra,0xfffff
    80002094:	b46080e7          	jalr	-1210(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    80002098:	478d                	li	a5,3
    8000209a:	cc9c                	sw	a5,24(s1)
  sched();
    8000209c:	00000097          	auipc	ra,0x0
    800020a0:	f0a080e7          	jalr	-246(ra) # 80001fa6 <sched>
  release(&p->lock);
    800020a4:	8526                	mv	a0,s1
    800020a6:	fffff097          	auipc	ra,0xfffff
    800020aa:	be4080e7          	jalr	-1052(ra) # 80000c8a <release>
}
    800020ae:	60e2                	ld	ra,24(sp)
    800020b0:	6442                	ld	s0,16(sp)
    800020b2:	64a2                	ld	s1,8(sp)
    800020b4:	6105                	addi	sp,sp,32
    800020b6:	8082                	ret

00000000800020b8 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800020b8:	7179                	addi	sp,sp,-48
    800020ba:	f406                	sd	ra,40(sp)
    800020bc:	f022                	sd	s0,32(sp)
    800020be:	ec26                	sd	s1,24(sp)
    800020c0:	e84a                	sd	s2,16(sp)
    800020c2:	e44e                	sd	s3,8(sp)
    800020c4:	1800                	addi	s0,sp,48
    800020c6:	89aa                	mv	s3,a0
    800020c8:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800020ca:	00000097          	auipc	ra,0x0
    800020ce:	8e2080e7          	jalr	-1822(ra) # 800019ac <myproc>
    800020d2:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800020d4:	fffff097          	auipc	ra,0xfffff
    800020d8:	b02080e7          	jalr	-1278(ra) # 80000bd6 <acquire>
  release(lk);
    800020dc:	854a                	mv	a0,s2
    800020de:	fffff097          	auipc	ra,0xfffff
    800020e2:	bac080e7          	jalr	-1108(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    800020e6:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020ea:	4789                	li	a5,2
    800020ec:	cc9c                	sw	a5,24(s1)

  sched();
    800020ee:	00000097          	auipc	ra,0x0
    800020f2:	eb8080e7          	jalr	-328(ra) # 80001fa6 <sched>

  // Tidy up.
  p->chan = 0;
    800020f6:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020fa:	8526                	mv	a0,s1
    800020fc:	fffff097          	auipc	ra,0xfffff
    80002100:	b8e080e7          	jalr	-1138(ra) # 80000c8a <release>
  acquire(lk);
    80002104:	854a                	mv	a0,s2
    80002106:	fffff097          	auipc	ra,0xfffff
    8000210a:	ad0080e7          	jalr	-1328(ra) # 80000bd6 <acquire>
}
    8000210e:	70a2                	ld	ra,40(sp)
    80002110:	7402                	ld	s0,32(sp)
    80002112:	64e2                	ld	s1,24(sp)
    80002114:	6942                	ld	s2,16(sp)
    80002116:	69a2                	ld	s3,8(sp)
    80002118:	6145                	addi	sp,sp,48
    8000211a:	8082                	ret

000000008000211c <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000211c:	7139                	addi	sp,sp,-64
    8000211e:	fc06                	sd	ra,56(sp)
    80002120:	f822                	sd	s0,48(sp)
    80002122:	f426                	sd	s1,40(sp)
    80002124:	f04a                	sd	s2,32(sp)
    80002126:	ec4e                	sd	s3,24(sp)
    80002128:	e852                	sd	s4,16(sp)
    8000212a:	e456                	sd	s5,8(sp)
    8000212c:	0080                	addi	s0,sp,64
    8000212e:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002130:	0000f497          	auipc	s1,0xf
    80002134:	07048493          	addi	s1,s1,112 # 800111a0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002138:	4989                	li	s3,2
        p->state = RUNNABLE;
    8000213a:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000213c:	00015917          	auipc	s2,0x15
    80002140:	c6490913          	addi	s2,s2,-924 # 80016da0 <tickslock>
    80002144:	a811                	j	80002158 <wakeup+0x3c>
      }
      release(&p->lock);
    80002146:	8526                	mv	a0,s1
    80002148:	fffff097          	auipc	ra,0xfffff
    8000214c:	b42080e7          	jalr	-1214(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002150:	17048493          	addi	s1,s1,368
    80002154:	03248663          	beq	s1,s2,80002180 <wakeup+0x64>
    if(p != myproc()){
    80002158:	00000097          	auipc	ra,0x0
    8000215c:	854080e7          	jalr	-1964(ra) # 800019ac <myproc>
    80002160:	fea488e3          	beq	s1,a0,80002150 <wakeup+0x34>
      acquire(&p->lock);
    80002164:	8526                	mv	a0,s1
    80002166:	fffff097          	auipc	ra,0xfffff
    8000216a:	a70080e7          	jalr	-1424(ra) # 80000bd6 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    8000216e:	4c9c                	lw	a5,24(s1)
    80002170:	fd379be3          	bne	a5,s3,80002146 <wakeup+0x2a>
    80002174:	709c                	ld	a5,32(s1)
    80002176:	fd4798e3          	bne	a5,s4,80002146 <wakeup+0x2a>
        p->state = RUNNABLE;
    8000217a:	0154ac23          	sw	s5,24(s1)
    8000217e:	b7e1                	j	80002146 <wakeup+0x2a>
    }
  }
}
    80002180:	70e2                	ld	ra,56(sp)
    80002182:	7442                	ld	s0,48(sp)
    80002184:	74a2                	ld	s1,40(sp)
    80002186:	7902                	ld	s2,32(sp)
    80002188:	69e2                	ld	s3,24(sp)
    8000218a:	6a42                	ld	s4,16(sp)
    8000218c:	6aa2                	ld	s5,8(sp)
    8000218e:	6121                	addi	sp,sp,64
    80002190:	8082                	ret

0000000080002192 <reparent>:
{
    80002192:	7179                	addi	sp,sp,-48
    80002194:	f406                	sd	ra,40(sp)
    80002196:	f022                	sd	s0,32(sp)
    80002198:	ec26                	sd	s1,24(sp)
    8000219a:	e84a                	sd	s2,16(sp)
    8000219c:	e44e                	sd	s3,8(sp)
    8000219e:	e052                	sd	s4,0(sp)
    800021a0:	1800                	addi	s0,sp,48
    800021a2:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021a4:	0000f497          	auipc	s1,0xf
    800021a8:	ffc48493          	addi	s1,s1,-4 # 800111a0 <proc>
      pp->parent = initproc;
    800021ac:	00007a17          	auipc	s4,0x7
    800021b0:	93ca0a13          	addi	s4,s4,-1732 # 80008ae8 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021b4:	00015997          	auipc	s3,0x15
    800021b8:	bec98993          	addi	s3,s3,-1044 # 80016da0 <tickslock>
    800021bc:	a029                	j	800021c6 <reparent+0x34>
    800021be:	17048493          	addi	s1,s1,368
    800021c2:	01348d63          	beq	s1,s3,800021dc <reparent+0x4a>
    if(pp->parent == p){
    800021c6:	7c9c                	ld	a5,56(s1)
    800021c8:	ff279be3          	bne	a5,s2,800021be <reparent+0x2c>
      pp->parent = initproc;
    800021cc:	000a3503          	ld	a0,0(s4)
    800021d0:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800021d2:	00000097          	auipc	ra,0x0
    800021d6:	f4a080e7          	jalr	-182(ra) # 8000211c <wakeup>
    800021da:	b7d5                	j	800021be <reparent+0x2c>
}
    800021dc:	70a2                	ld	ra,40(sp)
    800021de:	7402                	ld	s0,32(sp)
    800021e0:	64e2                	ld	s1,24(sp)
    800021e2:	6942                	ld	s2,16(sp)
    800021e4:	69a2                	ld	s3,8(sp)
    800021e6:	6a02                	ld	s4,0(sp)
    800021e8:	6145                	addi	sp,sp,48
    800021ea:	8082                	ret

00000000800021ec <exit>:
{
    800021ec:	7179                	addi	sp,sp,-48
    800021ee:	f406                	sd	ra,40(sp)
    800021f0:	f022                	sd	s0,32(sp)
    800021f2:	ec26                	sd	s1,24(sp)
    800021f4:	e84a                	sd	s2,16(sp)
    800021f6:	e44e                	sd	s3,8(sp)
    800021f8:	e052                	sd	s4,0(sp)
    800021fa:	1800                	addi	s0,sp,48
    800021fc:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800021fe:	fffff097          	auipc	ra,0xfffff
    80002202:	7ae080e7          	jalr	1966(ra) # 800019ac <myproc>
    80002206:	89aa                	mv	s3,a0
  if(p == initproc)
    80002208:	00007797          	auipc	a5,0x7
    8000220c:	8e07b783          	ld	a5,-1824(a5) # 80008ae8 <initproc>
    80002210:	0d050493          	addi	s1,a0,208
    80002214:	15050913          	addi	s2,a0,336
    80002218:	02a79363          	bne	a5,a0,8000223e <exit+0x52>
    panic("init exiting");
    8000221c:	00006517          	auipc	a0,0x6
    80002220:	05450513          	addi	a0,a0,84 # 80008270 <digits+0x230>
    80002224:	ffffe097          	auipc	ra,0xffffe
    80002228:	31c080e7          	jalr	796(ra) # 80000540 <panic>
      fileclose(f);
    8000222c:	00002097          	auipc	ra,0x2
    80002230:	42e080e7          	jalr	1070(ra) # 8000465a <fileclose>
      p->ofile[fd] = 0;
    80002234:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002238:	04a1                	addi	s1,s1,8
    8000223a:	01248563          	beq	s1,s2,80002244 <exit+0x58>
    if(p->ofile[fd]){
    8000223e:	6088                	ld	a0,0(s1)
    80002240:	f575                	bnez	a0,8000222c <exit+0x40>
    80002242:	bfdd                	j	80002238 <exit+0x4c>
  begin_op();
    80002244:	00002097          	auipc	ra,0x2
    80002248:	f4e080e7          	jalr	-178(ra) # 80004192 <begin_op>
  iput(p->cwd);
    8000224c:	1509b503          	ld	a0,336(s3)
    80002250:	00001097          	auipc	ra,0x1
    80002254:	730080e7          	jalr	1840(ra) # 80003980 <iput>
  end_op();
    80002258:	00002097          	auipc	ra,0x2
    8000225c:	fb8080e7          	jalr	-72(ra) # 80004210 <end_op>
  p->cwd = 0;
    80002260:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002264:	0000f497          	auipc	s1,0xf
    80002268:	b1448493          	addi	s1,s1,-1260 # 80010d78 <wait_lock>
    8000226c:	8526                	mv	a0,s1
    8000226e:	fffff097          	auipc	ra,0xfffff
    80002272:	968080e7          	jalr	-1688(ra) # 80000bd6 <acquire>
  reparent(p);
    80002276:	854e                	mv	a0,s3
    80002278:	00000097          	auipc	ra,0x0
    8000227c:	f1a080e7          	jalr	-230(ra) # 80002192 <reparent>
  wakeup(p->parent);
    80002280:	0389b503          	ld	a0,56(s3)
    80002284:	00000097          	auipc	ra,0x0
    80002288:	e98080e7          	jalr	-360(ra) # 8000211c <wakeup>
  acquire(&p->lock);
    8000228c:	854e                	mv	a0,s3
    8000228e:	fffff097          	auipc	ra,0xfffff
    80002292:	948080e7          	jalr	-1720(ra) # 80000bd6 <acquire>
  p->xstate = status;
    80002296:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000229a:	4795                	li	a5,5
    8000229c:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800022a0:	8526                	mv	a0,s1
    800022a2:	fffff097          	auipc	ra,0xfffff
    800022a6:	9e8080e7          	jalr	-1560(ra) # 80000c8a <release>
  sched();
    800022aa:	00000097          	auipc	ra,0x0
    800022ae:	cfc080e7          	jalr	-772(ra) # 80001fa6 <sched>
  panic("zombie exit");
    800022b2:	00006517          	auipc	a0,0x6
    800022b6:	fce50513          	addi	a0,a0,-50 # 80008280 <digits+0x240>
    800022ba:	ffffe097          	auipc	ra,0xffffe
    800022be:	286080e7          	jalr	646(ra) # 80000540 <panic>

00000000800022c2 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800022c2:	7179                	addi	sp,sp,-48
    800022c4:	f406                	sd	ra,40(sp)
    800022c6:	f022                	sd	s0,32(sp)
    800022c8:	ec26                	sd	s1,24(sp)
    800022ca:	e84a                	sd	s2,16(sp)
    800022cc:	e44e                	sd	s3,8(sp)
    800022ce:	1800                	addi	s0,sp,48
    800022d0:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800022d2:	0000f497          	auipc	s1,0xf
    800022d6:	ece48493          	addi	s1,s1,-306 # 800111a0 <proc>
    800022da:	00015997          	auipc	s3,0x15
    800022de:	ac698993          	addi	s3,s3,-1338 # 80016da0 <tickslock>
    acquire(&p->lock);
    800022e2:	8526                	mv	a0,s1
    800022e4:	fffff097          	auipc	ra,0xfffff
    800022e8:	8f2080e7          	jalr	-1806(ra) # 80000bd6 <acquire>
    if(p->pid == pid){
    800022ec:	589c                	lw	a5,48(s1)
    800022ee:	01278d63          	beq	a5,s2,80002308 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800022f2:	8526                	mv	a0,s1
    800022f4:	fffff097          	auipc	ra,0xfffff
    800022f8:	996080e7          	jalr	-1642(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800022fc:	17048493          	addi	s1,s1,368
    80002300:	ff3491e3          	bne	s1,s3,800022e2 <kill+0x20>
  }
  return -1;
    80002304:	557d                	li	a0,-1
    80002306:	a829                	j	80002320 <kill+0x5e>
      p->killed = 1;
    80002308:	4785                	li	a5,1
    8000230a:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000230c:	4c98                	lw	a4,24(s1)
    8000230e:	4789                	li	a5,2
    80002310:	00f70f63          	beq	a4,a5,8000232e <kill+0x6c>
      release(&p->lock);
    80002314:	8526                	mv	a0,s1
    80002316:	fffff097          	auipc	ra,0xfffff
    8000231a:	974080e7          	jalr	-1676(ra) # 80000c8a <release>
      return 0;
    8000231e:	4501                	li	a0,0
}
    80002320:	70a2                	ld	ra,40(sp)
    80002322:	7402                	ld	s0,32(sp)
    80002324:	64e2                	ld	s1,24(sp)
    80002326:	6942                	ld	s2,16(sp)
    80002328:	69a2                	ld	s3,8(sp)
    8000232a:	6145                	addi	sp,sp,48
    8000232c:	8082                	ret
        p->state = RUNNABLE;
    8000232e:	478d                	li	a5,3
    80002330:	cc9c                	sw	a5,24(s1)
    80002332:	b7cd                	j	80002314 <kill+0x52>

0000000080002334 <setkilled>:

void
setkilled(struct proc *p)
{
    80002334:	1101                	addi	sp,sp,-32
    80002336:	ec06                	sd	ra,24(sp)
    80002338:	e822                	sd	s0,16(sp)
    8000233a:	e426                	sd	s1,8(sp)
    8000233c:	1000                	addi	s0,sp,32
    8000233e:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002340:	fffff097          	auipc	ra,0xfffff
    80002344:	896080e7          	jalr	-1898(ra) # 80000bd6 <acquire>
  p->killed = 1;
    80002348:	4785                	li	a5,1
    8000234a:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    8000234c:	8526                	mv	a0,s1
    8000234e:	fffff097          	auipc	ra,0xfffff
    80002352:	93c080e7          	jalr	-1732(ra) # 80000c8a <release>
}
    80002356:	60e2                	ld	ra,24(sp)
    80002358:	6442                	ld	s0,16(sp)
    8000235a:	64a2                	ld	s1,8(sp)
    8000235c:	6105                	addi	sp,sp,32
    8000235e:	8082                	ret

0000000080002360 <killed>:

int
killed(struct proc *p)
{
    80002360:	1101                	addi	sp,sp,-32
    80002362:	ec06                	sd	ra,24(sp)
    80002364:	e822                	sd	s0,16(sp)
    80002366:	e426                	sd	s1,8(sp)
    80002368:	e04a                	sd	s2,0(sp)
    8000236a:	1000                	addi	s0,sp,32
    8000236c:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    8000236e:	fffff097          	auipc	ra,0xfffff
    80002372:	868080e7          	jalr	-1944(ra) # 80000bd6 <acquire>
  k = p->killed;
    80002376:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    8000237a:	8526                	mv	a0,s1
    8000237c:	fffff097          	auipc	ra,0xfffff
    80002380:	90e080e7          	jalr	-1778(ra) # 80000c8a <release>
  return k;
}
    80002384:	854a                	mv	a0,s2
    80002386:	60e2                	ld	ra,24(sp)
    80002388:	6442                	ld	s0,16(sp)
    8000238a:	64a2                	ld	s1,8(sp)
    8000238c:	6902                	ld	s2,0(sp)
    8000238e:	6105                	addi	sp,sp,32
    80002390:	8082                	ret

0000000080002392 <wait>:
{
    80002392:	715d                	addi	sp,sp,-80
    80002394:	e486                	sd	ra,72(sp)
    80002396:	e0a2                	sd	s0,64(sp)
    80002398:	fc26                	sd	s1,56(sp)
    8000239a:	f84a                	sd	s2,48(sp)
    8000239c:	f44e                	sd	s3,40(sp)
    8000239e:	f052                	sd	s4,32(sp)
    800023a0:	ec56                	sd	s5,24(sp)
    800023a2:	e85a                	sd	s6,16(sp)
    800023a4:	e45e                	sd	s7,8(sp)
    800023a6:	e062                	sd	s8,0(sp)
    800023a8:	0880                	addi	s0,sp,80
    800023aa:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800023ac:	fffff097          	auipc	ra,0xfffff
    800023b0:	600080e7          	jalr	1536(ra) # 800019ac <myproc>
    800023b4:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800023b6:	0000f517          	auipc	a0,0xf
    800023ba:	9c250513          	addi	a0,a0,-1598 # 80010d78 <wait_lock>
    800023be:	fffff097          	auipc	ra,0xfffff
    800023c2:	818080e7          	jalr	-2024(ra) # 80000bd6 <acquire>
    havekids = 0;
    800023c6:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    800023c8:	4a15                	li	s4,5
        havekids = 1;
    800023ca:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800023cc:	00015997          	auipc	s3,0x15
    800023d0:	9d498993          	addi	s3,s3,-1580 # 80016da0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800023d4:	0000fc17          	auipc	s8,0xf
    800023d8:	9a4c0c13          	addi	s8,s8,-1628 # 80010d78 <wait_lock>
    havekids = 0;
    800023dc:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800023de:	0000f497          	auipc	s1,0xf
    800023e2:	dc248493          	addi	s1,s1,-574 # 800111a0 <proc>
    800023e6:	a0bd                	j	80002454 <wait+0xc2>
          pid = pp->pid;
    800023e8:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800023ec:	000b0e63          	beqz	s6,80002408 <wait+0x76>
    800023f0:	4691                	li	a3,4
    800023f2:	02c48613          	addi	a2,s1,44
    800023f6:	85da                	mv	a1,s6
    800023f8:	05093503          	ld	a0,80(s2)
    800023fc:	fffff097          	auipc	ra,0xfffff
    80002400:	270080e7          	jalr	624(ra) # 8000166c <copyout>
    80002404:	02054563          	bltz	a0,8000242e <wait+0x9c>
          freeproc(pp);
    80002408:	8526                	mv	a0,s1
    8000240a:	fffff097          	auipc	ra,0xfffff
    8000240e:	754080e7          	jalr	1876(ra) # 80001b5e <freeproc>
          release(&pp->lock);
    80002412:	8526                	mv	a0,s1
    80002414:	fffff097          	auipc	ra,0xfffff
    80002418:	876080e7          	jalr	-1930(ra) # 80000c8a <release>
          release(&wait_lock);
    8000241c:	0000f517          	auipc	a0,0xf
    80002420:	95c50513          	addi	a0,a0,-1700 # 80010d78 <wait_lock>
    80002424:	fffff097          	auipc	ra,0xfffff
    80002428:	866080e7          	jalr	-1946(ra) # 80000c8a <release>
          return pid;
    8000242c:	a0b5                	j	80002498 <wait+0x106>
            release(&pp->lock);
    8000242e:	8526                	mv	a0,s1
    80002430:	fffff097          	auipc	ra,0xfffff
    80002434:	85a080e7          	jalr	-1958(ra) # 80000c8a <release>
            release(&wait_lock);
    80002438:	0000f517          	auipc	a0,0xf
    8000243c:	94050513          	addi	a0,a0,-1728 # 80010d78 <wait_lock>
    80002440:	fffff097          	auipc	ra,0xfffff
    80002444:	84a080e7          	jalr	-1974(ra) # 80000c8a <release>
            return -1;
    80002448:	59fd                	li	s3,-1
    8000244a:	a0b9                	j	80002498 <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000244c:	17048493          	addi	s1,s1,368
    80002450:	03348463          	beq	s1,s3,80002478 <wait+0xe6>
      if(pp->parent == p){
    80002454:	7c9c                	ld	a5,56(s1)
    80002456:	ff279be3          	bne	a5,s2,8000244c <wait+0xba>
        acquire(&pp->lock);
    8000245a:	8526                	mv	a0,s1
    8000245c:	ffffe097          	auipc	ra,0xffffe
    80002460:	77a080e7          	jalr	1914(ra) # 80000bd6 <acquire>
        if(pp->state == ZOMBIE){
    80002464:	4c9c                	lw	a5,24(s1)
    80002466:	f94781e3          	beq	a5,s4,800023e8 <wait+0x56>
        release(&pp->lock);
    8000246a:	8526                	mv	a0,s1
    8000246c:	fffff097          	auipc	ra,0xfffff
    80002470:	81e080e7          	jalr	-2018(ra) # 80000c8a <release>
        havekids = 1;
    80002474:	8756                	mv	a4,s5
    80002476:	bfd9                	j	8000244c <wait+0xba>
    if(!havekids || killed(p)){
    80002478:	c719                	beqz	a4,80002486 <wait+0xf4>
    8000247a:	854a                	mv	a0,s2
    8000247c:	00000097          	auipc	ra,0x0
    80002480:	ee4080e7          	jalr	-284(ra) # 80002360 <killed>
    80002484:	c51d                	beqz	a0,800024b2 <wait+0x120>
      release(&wait_lock);
    80002486:	0000f517          	auipc	a0,0xf
    8000248a:	8f250513          	addi	a0,a0,-1806 # 80010d78 <wait_lock>
    8000248e:	ffffe097          	auipc	ra,0xffffe
    80002492:	7fc080e7          	jalr	2044(ra) # 80000c8a <release>
      return -1;
    80002496:	59fd                	li	s3,-1
}
    80002498:	854e                	mv	a0,s3
    8000249a:	60a6                	ld	ra,72(sp)
    8000249c:	6406                	ld	s0,64(sp)
    8000249e:	74e2                	ld	s1,56(sp)
    800024a0:	7942                	ld	s2,48(sp)
    800024a2:	79a2                	ld	s3,40(sp)
    800024a4:	7a02                	ld	s4,32(sp)
    800024a6:	6ae2                	ld	s5,24(sp)
    800024a8:	6b42                	ld	s6,16(sp)
    800024aa:	6ba2                	ld	s7,8(sp)
    800024ac:	6c02                	ld	s8,0(sp)
    800024ae:	6161                	addi	sp,sp,80
    800024b0:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800024b2:	85e2                	mv	a1,s8
    800024b4:	854a                	mv	a0,s2
    800024b6:	00000097          	auipc	ra,0x0
    800024ba:	c02080e7          	jalr	-1022(ra) # 800020b8 <sleep>
    havekids = 0;
    800024be:	bf39                	j	800023dc <wait+0x4a>

00000000800024c0 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024c0:	7179                	addi	sp,sp,-48
    800024c2:	f406                	sd	ra,40(sp)
    800024c4:	f022                	sd	s0,32(sp)
    800024c6:	ec26                	sd	s1,24(sp)
    800024c8:	e84a                	sd	s2,16(sp)
    800024ca:	e44e                	sd	s3,8(sp)
    800024cc:	e052                	sd	s4,0(sp)
    800024ce:	1800                	addi	s0,sp,48
    800024d0:	84aa                	mv	s1,a0
    800024d2:	892e                	mv	s2,a1
    800024d4:	89b2                	mv	s3,a2
    800024d6:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024d8:	fffff097          	auipc	ra,0xfffff
    800024dc:	4d4080e7          	jalr	1236(ra) # 800019ac <myproc>
  if(user_dst){
    800024e0:	c08d                	beqz	s1,80002502 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800024e2:	86d2                	mv	a3,s4
    800024e4:	864e                	mv	a2,s3
    800024e6:	85ca                	mv	a1,s2
    800024e8:	6928                	ld	a0,80(a0)
    800024ea:	fffff097          	auipc	ra,0xfffff
    800024ee:	182080e7          	jalr	386(ra) # 8000166c <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024f2:	70a2                	ld	ra,40(sp)
    800024f4:	7402                	ld	s0,32(sp)
    800024f6:	64e2                	ld	s1,24(sp)
    800024f8:	6942                	ld	s2,16(sp)
    800024fa:	69a2                	ld	s3,8(sp)
    800024fc:	6a02                	ld	s4,0(sp)
    800024fe:	6145                	addi	sp,sp,48
    80002500:	8082                	ret
    memmove((char *)dst, src, len);
    80002502:	000a061b          	sext.w	a2,s4
    80002506:	85ce                	mv	a1,s3
    80002508:	854a                	mv	a0,s2
    8000250a:	fffff097          	auipc	ra,0xfffff
    8000250e:	824080e7          	jalr	-2012(ra) # 80000d2e <memmove>
    return 0;
    80002512:	8526                	mv	a0,s1
    80002514:	bff9                	j	800024f2 <either_copyout+0x32>

0000000080002516 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002516:	7179                	addi	sp,sp,-48
    80002518:	f406                	sd	ra,40(sp)
    8000251a:	f022                	sd	s0,32(sp)
    8000251c:	ec26                	sd	s1,24(sp)
    8000251e:	e84a                	sd	s2,16(sp)
    80002520:	e44e                	sd	s3,8(sp)
    80002522:	e052                	sd	s4,0(sp)
    80002524:	1800                	addi	s0,sp,48
    80002526:	892a                	mv	s2,a0
    80002528:	84ae                	mv	s1,a1
    8000252a:	89b2                	mv	s3,a2
    8000252c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000252e:	fffff097          	auipc	ra,0xfffff
    80002532:	47e080e7          	jalr	1150(ra) # 800019ac <myproc>
  if(user_src){
    80002536:	c08d                	beqz	s1,80002558 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002538:	86d2                	mv	a3,s4
    8000253a:	864e                	mv	a2,s3
    8000253c:	85ca                	mv	a1,s2
    8000253e:	6928                	ld	a0,80(a0)
    80002540:	fffff097          	auipc	ra,0xfffff
    80002544:	1b8080e7          	jalr	440(ra) # 800016f8 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002548:	70a2                	ld	ra,40(sp)
    8000254a:	7402                	ld	s0,32(sp)
    8000254c:	64e2                	ld	s1,24(sp)
    8000254e:	6942                	ld	s2,16(sp)
    80002550:	69a2                	ld	s3,8(sp)
    80002552:	6a02                	ld	s4,0(sp)
    80002554:	6145                	addi	sp,sp,48
    80002556:	8082                	ret
    memmove(dst, (char*)src, len);
    80002558:	000a061b          	sext.w	a2,s4
    8000255c:	85ce                	mv	a1,s3
    8000255e:	854a                	mv	a0,s2
    80002560:	ffffe097          	auipc	ra,0xffffe
    80002564:	7ce080e7          	jalr	1998(ra) # 80000d2e <memmove>
    return 0;
    80002568:	8526                	mv	a0,s1
    8000256a:	bff9                	j	80002548 <either_copyin+0x32>

000000008000256c <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000256c:	715d                	addi	sp,sp,-80
    8000256e:	e486                	sd	ra,72(sp)
    80002570:	e0a2                	sd	s0,64(sp)
    80002572:	fc26                	sd	s1,56(sp)
    80002574:	f84a                	sd	s2,48(sp)
    80002576:	f44e                	sd	s3,40(sp)
    80002578:	f052                	sd	s4,32(sp)
    8000257a:	ec56                	sd	s5,24(sp)
    8000257c:	e85a                	sd	s6,16(sp)
    8000257e:	e45e                	sd	s7,8(sp)
    80002580:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002582:	00006517          	auipc	a0,0x6
    80002586:	b4650513          	addi	a0,a0,-1210 # 800080c8 <digits+0x88>
    8000258a:	ffffe097          	auipc	ra,0xffffe
    8000258e:	000080e7          	jalr	ra # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002592:	0000f497          	auipc	s1,0xf
    80002596:	d6648493          	addi	s1,s1,-666 # 800112f8 <proc+0x158>
    8000259a:	00015917          	auipc	s2,0x15
    8000259e:	95e90913          	addi	s2,s2,-1698 # 80016ef8 <bruh+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025a2:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800025a4:	00006997          	auipc	s3,0x6
    800025a8:	cec98993          	addi	s3,s3,-788 # 80008290 <digits+0x250>
    printf("%d %s %s", p->pid, state, p->name);
    800025ac:	00006a97          	auipc	s5,0x6
    800025b0:	ceca8a93          	addi	s5,s5,-788 # 80008298 <digits+0x258>
    printf("\n");
    800025b4:	00006a17          	auipc	s4,0x6
    800025b8:	b14a0a13          	addi	s4,s4,-1260 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025bc:	00006b97          	auipc	s7,0x6
    800025c0:	d1cb8b93          	addi	s7,s7,-740 # 800082d8 <states.0>
    800025c4:	a00d                	j	800025e6 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800025c6:	ed86a583          	lw	a1,-296(a3)
    800025ca:	8556                	mv	a0,s5
    800025cc:	ffffe097          	auipc	ra,0xffffe
    800025d0:	fbe080e7          	jalr	-66(ra) # 8000058a <printf>
    printf("\n");
    800025d4:	8552                	mv	a0,s4
    800025d6:	ffffe097          	auipc	ra,0xffffe
    800025da:	fb4080e7          	jalr	-76(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025de:	17048493          	addi	s1,s1,368
    800025e2:	03248263          	beq	s1,s2,80002606 <procdump+0x9a>
    if(p->state == UNUSED)
    800025e6:	86a6                	mv	a3,s1
    800025e8:	ec04a783          	lw	a5,-320(s1)
    800025ec:	dbed                	beqz	a5,800025de <procdump+0x72>
      state = "???";
    800025ee:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025f0:	fcfb6be3          	bltu	s6,a5,800025c6 <procdump+0x5a>
    800025f4:	02079713          	slli	a4,a5,0x20
    800025f8:	01d75793          	srli	a5,a4,0x1d
    800025fc:	97de                	add	a5,a5,s7
    800025fe:	6390                	ld	a2,0(a5)
    80002600:	f279                	bnez	a2,800025c6 <procdump+0x5a>
      state = "???";
    80002602:	864e                	mv	a2,s3
    80002604:	b7c9                	j	800025c6 <procdump+0x5a>
  }
}
    80002606:	60a6                	ld	ra,72(sp)
    80002608:	6406                	ld	s0,64(sp)
    8000260a:	74e2                	ld	s1,56(sp)
    8000260c:	7942                	ld	s2,48(sp)
    8000260e:	79a2                	ld	s3,40(sp)
    80002610:	7a02                	ld	s4,32(sp)
    80002612:	6ae2                	ld	s5,24(sp)
    80002614:	6b42                	ld	s6,16(sp)
    80002616:	6ba2                	ld	s7,8(sp)
    80002618:	6161                	addi	sp,sp,80
    8000261a:	8082                	ret

000000008000261c <swtch>:
    8000261c:	00153023          	sd	ra,0(a0)
    80002620:	00253423          	sd	sp,8(a0)
    80002624:	e900                	sd	s0,16(a0)
    80002626:	ed04                	sd	s1,24(a0)
    80002628:	03253023          	sd	s2,32(a0)
    8000262c:	03353423          	sd	s3,40(a0)
    80002630:	03453823          	sd	s4,48(a0)
    80002634:	03553c23          	sd	s5,56(a0)
    80002638:	05653023          	sd	s6,64(a0)
    8000263c:	05753423          	sd	s7,72(a0)
    80002640:	05853823          	sd	s8,80(a0)
    80002644:	05953c23          	sd	s9,88(a0)
    80002648:	07a53023          	sd	s10,96(a0)
    8000264c:	07b53423          	sd	s11,104(a0)
    80002650:	0005b083          	ld	ra,0(a1)
    80002654:	0085b103          	ld	sp,8(a1)
    80002658:	6980                	ld	s0,16(a1)
    8000265a:	6d84                	ld	s1,24(a1)
    8000265c:	0205b903          	ld	s2,32(a1)
    80002660:	0285b983          	ld	s3,40(a1)
    80002664:	0305ba03          	ld	s4,48(a1)
    80002668:	0385ba83          	ld	s5,56(a1)
    8000266c:	0405bb03          	ld	s6,64(a1)
    80002670:	0485bb83          	ld	s7,72(a1)
    80002674:	0505bc03          	ld	s8,80(a1)
    80002678:	0585bc83          	ld	s9,88(a1)
    8000267c:	0605bd03          	ld	s10,96(a1)
    80002680:	0685bd83          	ld	s11,104(a1)
    80002684:	8082                	ret

0000000080002686 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002686:	1141                	addi	sp,sp,-16
    80002688:	e406                	sd	ra,8(sp)
    8000268a:	e022                	sd	s0,0(sp)
    8000268c:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000268e:	00006597          	auipc	a1,0x6
    80002692:	c7a58593          	addi	a1,a1,-902 # 80008308 <states.0+0x30>
    80002696:	00014517          	auipc	a0,0x14
    8000269a:	70a50513          	addi	a0,a0,1802 # 80016da0 <tickslock>
    8000269e:	ffffe097          	auipc	ra,0xffffe
    800026a2:	4a8080e7          	jalr	1192(ra) # 80000b46 <initlock>
}
    800026a6:	60a2                	ld	ra,8(sp)
    800026a8:	6402                	ld	s0,0(sp)
    800026aa:	0141                	addi	sp,sp,16
    800026ac:	8082                	ret

00000000800026ae <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800026ae:	1141                	addi	sp,sp,-16
    800026b0:	e422                	sd	s0,8(sp)
    800026b2:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026b4:	00003797          	auipc	a5,0x3
    800026b8:	5fc78793          	addi	a5,a5,1532 # 80005cb0 <kernelvec>
    800026bc:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800026c0:	6422                	ld	s0,8(sp)
    800026c2:	0141                	addi	sp,sp,16
    800026c4:	8082                	ret

00000000800026c6 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800026c6:	1141                	addi	sp,sp,-16
    800026c8:	e406                	sd	ra,8(sp)
    800026ca:	e022                	sd	s0,0(sp)
    800026cc:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800026ce:	fffff097          	auipc	ra,0xfffff
    800026d2:	2de080e7          	jalr	734(ra) # 800019ac <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026d6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800026da:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026dc:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    800026e0:	00005697          	auipc	a3,0x5
    800026e4:	92068693          	addi	a3,a3,-1760 # 80007000 <_trampoline>
    800026e8:	00005717          	auipc	a4,0x5
    800026ec:	91870713          	addi	a4,a4,-1768 # 80007000 <_trampoline>
    800026f0:	8f15                	sub	a4,a4,a3
    800026f2:	040007b7          	lui	a5,0x4000
    800026f6:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    800026f8:	07b2                	slli	a5,a5,0xc
    800026fa:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026fc:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002700:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002702:	18002673          	csrr	a2,satp
    80002706:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002708:	6d30                	ld	a2,88(a0)
    8000270a:	6138                	ld	a4,64(a0)
    8000270c:	6585                	lui	a1,0x1
    8000270e:	972e                	add	a4,a4,a1
    80002710:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002712:	6d38                	ld	a4,88(a0)
    80002714:	00000617          	auipc	a2,0x0
    80002718:	13060613          	addi	a2,a2,304 # 80002844 <usertrap>
    8000271c:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000271e:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002720:	8612                	mv	a2,tp
    80002722:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002724:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002728:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000272c:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002730:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002734:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002736:	6f18                	ld	a4,24(a4)
    80002738:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000273c:	6928                	ld	a0,80(a0)
    8000273e:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002740:	00005717          	auipc	a4,0x5
    80002744:	95c70713          	addi	a4,a4,-1700 # 8000709c <userret>
    80002748:	8f15                	sub	a4,a4,a3
    8000274a:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    8000274c:	577d                	li	a4,-1
    8000274e:	177e                	slli	a4,a4,0x3f
    80002750:	8d59                	or	a0,a0,a4
    80002752:	9782                	jalr	a5
}
    80002754:	60a2                	ld	ra,8(sp)
    80002756:	6402                	ld	s0,0(sp)
    80002758:	0141                	addi	sp,sp,16
    8000275a:	8082                	ret

000000008000275c <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000275c:	1101                	addi	sp,sp,-32
    8000275e:	ec06                	sd	ra,24(sp)
    80002760:	e822                	sd	s0,16(sp)
    80002762:	e426                	sd	s1,8(sp)
    80002764:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002766:	00014497          	auipc	s1,0x14
    8000276a:	63a48493          	addi	s1,s1,1594 # 80016da0 <tickslock>
    8000276e:	8526                	mv	a0,s1
    80002770:	ffffe097          	auipc	ra,0xffffe
    80002774:	466080e7          	jalr	1126(ra) # 80000bd6 <acquire>
  ticks++;
    80002778:	00006517          	auipc	a0,0x6
    8000277c:	37850513          	addi	a0,a0,888 # 80008af0 <ticks>
    80002780:	411c                	lw	a5,0(a0)
    80002782:	2785                	addiw	a5,a5,1
    80002784:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002786:	00000097          	auipc	ra,0x0
    8000278a:	996080e7          	jalr	-1642(ra) # 8000211c <wakeup>
  release(&tickslock);
    8000278e:	8526                	mv	a0,s1
    80002790:	ffffe097          	auipc	ra,0xffffe
    80002794:	4fa080e7          	jalr	1274(ra) # 80000c8a <release>
}
    80002798:	60e2                	ld	ra,24(sp)
    8000279a:	6442                	ld	s0,16(sp)
    8000279c:	64a2                	ld	s1,8(sp)
    8000279e:	6105                	addi	sp,sp,32
    800027a0:	8082                	ret

00000000800027a2 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800027a2:	1101                	addi	sp,sp,-32
    800027a4:	ec06                	sd	ra,24(sp)
    800027a6:	e822                	sd	s0,16(sp)
    800027a8:	e426                	sd	s1,8(sp)
    800027aa:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027ac:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800027b0:	00074d63          	bltz	a4,800027ca <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800027b4:	57fd                	li	a5,-1
    800027b6:	17fe                	slli	a5,a5,0x3f
    800027b8:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800027ba:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800027bc:	06f70363          	beq	a4,a5,80002822 <devintr+0x80>
  }
}
    800027c0:	60e2                	ld	ra,24(sp)
    800027c2:	6442                	ld	s0,16(sp)
    800027c4:	64a2                	ld	s1,8(sp)
    800027c6:	6105                	addi	sp,sp,32
    800027c8:	8082                	ret
     (scause & 0xff) == 9){
    800027ca:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    800027ce:	46a5                	li	a3,9
    800027d0:	fed792e3          	bne	a5,a3,800027b4 <devintr+0x12>
    int irq = plic_claim();
    800027d4:	00003097          	auipc	ra,0x3
    800027d8:	5e4080e7          	jalr	1508(ra) # 80005db8 <plic_claim>
    800027dc:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800027de:	47a9                	li	a5,10
    800027e0:	02f50763          	beq	a0,a5,8000280e <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800027e4:	4785                	li	a5,1
    800027e6:	02f50963          	beq	a0,a5,80002818 <devintr+0x76>
    return 1;
    800027ea:	4505                	li	a0,1
    } else if(irq){
    800027ec:	d8f1                	beqz	s1,800027c0 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800027ee:	85a6                	mv	a1,s1
    800027f0:	00006517          	auipc	a0,0x6
    800027f4:	b2050513          	addi	a0,a0,-1248 # 80008310 <states.0+0x38>
    800027f8:	ffffe097          	auipc	ra,0xffffe
    800027fc:	d92080e7          	jalr	-622(ra) # 8000058a <printf>
      plic_complete(irq);
    80002800:	8526                	mv	a0,s1
    80002802:	00003097          	auipc	ra,0x3
    80002806:	5da080e7          	jalr	1498(ra) # 80005ddc <plic_complete>
    return 1;
    8000280a:	4505                	li	a0,1
    8000280c:	bf55                	j	800027c0 <devintr+0x1e>
      uartintr();
    8000280e:	ffffe097          	auipc	ra,0xffffe
    80002812:	18a080e7          	jalr	394(ra) # 80000998 <uartintr>
    80002816:	b7ed                	j	80002800 <devintr+0x5e>
      virtio_disk_intr();
    80002818:	00004097          	auipc	ra,0x4
    8000281c:	a8c080e7          	jalr	-1396(ra) # 800062a4 <virtio_disk_intr>
    80002820:	b7c5                	j	80002800 <devintr+0x5e>
    if(cpuid() == 0){
    80002822:	fffff097          	auipc	ra,0xfffff
    80002826:	15e080e7          	jalr	350(ra) # 80001980 <cpuid>
    8000282a:	c901                	beqz	a0,8000283a <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000282c:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002830:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002832:	14479073          	csrw	sip,a5
    return 2;
    80002836:	4509                	li	a0,2
    80002838:	b761                	j	800027c0 <devintr+0x1e>
      clockintr();
    8000283a:	00000097          	auipc	ra,0x0
    8000283e:	f22080e7          	jalr	-222(ra) # 8000275c <clockintr>
    80002842:	b7ed                	j	8000282c <devintr+0x8a>

0000000080002844 <usertrap>:
{
    80002844:	1101                	addi	sp,sp,-32
    80002846:	ec06                	sd	ra,24(sp)
    80002848:	e822                	sd	s0,16(sp)
    8000284a:	e426                	sd	s1,8(sp)
    8000284c:	e04a                	sd	s2,0(sp)
    8000284e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002850:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002854:	1007f793          	andi	a5,a5,256
    80002858:	e3b1                	bnez	a5,8000289c <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000285a:	00003797          	auipc	a5,0x3
    8000285e:	45678793          	addi	a5,a5,1110 # 80005cb0 <kernelvec>
    80002862:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002866:	fffff097          	auipc	ra,0xfffff
    8000286a:	146080e7          	jalr	326(ra) # 800019ac <myproc>
    8000286e:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002870:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002872:	14102773          	csrr	a4,sepc
    80002876:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002878:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000287c:	47a1                	li	a5,8
    8000287e:	02f70763          	beq	a4,a5,800028ac <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    80002882:	00000097          	auipc	ra,0x0
    80002886:	f20080e7          	jalr	-224(ra) # 800027a2 <devintr>
    8000288a:	892a                	mv	s2,a0
    8000288c:	c151                	beqz	a0,80002910 <usertrap+0xcc>
  if(killed(p))
    8000288e:	8526                	mv	a0,s1
    80002890:	00000097          	auipc	ra,0x0
    80002894:	ad0080e7          	jalr	-1328(ra) # 80002360 <killed>
    80002898:	c929                	beqz	a0,800028ea <usertrap+0xa6>
    8000289a:	a099                	j	800028e0 <usertrap+0x9c>
    panic("usertrap: not from user mode");
    8000289c:	00006517          	auipc	a0,0x6
    800028a0:	a9450513          	addi	a0,a0,-1388 # 80008330 <states.0+0x58>
    800028a4:	ffffe097          	auipc	ra,0xffffe
    800028a8:	c9c080e7          	jalr	-868(ra) # 80000540 <panic>
    if(killed(p))
    800028ac:	00000097          	auipc	ra,0x0
    800028b0:	ab4080e7          	jalr	-1356(ra) # 80002360 <killed>
    800028b4:	e921                	bnez	a0,80002904 <usertrap+0xc0>
    p->trapframe->epc += 4;
    800028b6:	6cb8                	ld	a4,88(s1)
    800028b8:	6f1c                	ld	a5,24(a4)
    800028ba:	0791                	addi	a5,a5,4
    800028bc:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028be:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800028c2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028c6:	10079073          	csrw	sstatus,a5
    syscall();
    800028ca:	00000097          	auipc	ra,0x0
    800028ce:	2d4080e7          	jalr	724(ra) # 80002b9e <syscall>
  if(killed(p))
    800028d2:	8526                	mv	a0,s1
    800028d4:	00000097          	auipc	ra,0x0
    800028d8:	a8c080e7          	jalr	-1396(ra) # 80002360 <killed>
    800028dc:	c911                	beqz	a0,800028f0 <usertrap+0xac>
    800028de:	4901                	li	s2,0
    exit(-1);
    800028e0:	557d                	li	a0,-1
    800028e2:	00000097          	auipc	ra,0x0
    800028e6:	90a080e7          	jalr	-1782(ra) # 800021ec <exit>
  if(which_dev == 2)
    800028ea:	4789                	li	a5,2
    800028ec:	04f90f63          	beq	s2,a5,8000294a <usertrap+0x106>
  usertrapret();
    800028f0:	00000097          	auipc	ra,0x0
    800028f4:	dd6080e7          	jalr	-554(ra) # 800026c6 <usertrapret>
}
    800028f8:	60e2                	ld	ra,24(sp)
    800028fa:	6442                	ld	s0,16(sp)
    800028fc:	64a2                	ld	s1,8(sp)
    800028fe:	6902                	ld	s2,0(sp)
    80002900:	6105                	addi	sp,sp,32
    80002902:	8082                	ret
      exit(-1);
    80002904:	557d                	li	a0,-1
    80002906:	00000097          	auipc	ra,0x0
    8000290a:	8e6080e7          	jalr	-1818(ra) # 800021ec <exit>
    8000290e:	b765                	j	800028b6 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002910:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002914:	5890                	lw	a2,48(s1)
    80002916:	00006517          	auipc	a0,0x6
    8000291a:	a3a50513          	addi	a0,a0,-1478 # 80008350 <states.0+0x78>
    8000291e:	ffffe097          	auipc	ra,0xffffe
    80002922:	c6c080e7          	jalr	-916(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002926:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000292a:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000292e:	00006517          	auipc	a0,0x6
    80002932:	a5250513          	addi	a0,a0,-1454 # 80008380 <states.0+0xa8>
    80002936:	ffffe097          	auipc	ra,0xffffe
    8000293a:	c54080e7          	jalr	-940(ra) # 8000058a <printf>
    setkilled(p);
    8000293e:	8526                	mv	a0,s1
    80002940:	00000097          	auipc	ra,0x0
    80002944:	9f4080e7          	jalr	-1548(ra) # 80002334 <setkilled>
    80002948:	b769                	j	800028d2 <usertrap+0x8e>
    yield();
    8000294a:	fffff097          	auipc	ra,0xfffff
    8000294e:	732080e7          	jalr	1842(ra) # 8000207c <yield>
    80002952:	bf79                	j	800028f0 <usertrap+0xac>

0000000080002954 <kerneltrap>:
{
    80002954:	7179                	addi	sp,sp,-48
    80002956:	f406                	sd	ra,40(sp)
    80002958:	f022                	sd	s0,32(sp)
    8000295a:	ec26                	sd	s1,24(sp)
    8000295c:	e84a                	sd	s2,16(sp)
    8000295e:	e44e                	sd	s3,8(sp)
    80002960:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002962:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002966:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000296a:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    8000296e:	1004f793          	andi	a5,s1,256
    80002972:	cb85                	beqz	a5,800029a2 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002974:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002978:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    8000297a:	ef85                	bnez	a5,800029b2 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    8000297c:	00000097          	auipc	ra,0x0
    80002980:	e26080e7          	jalr	-474(ra) # 800027a2 <devintr>
    80002984:	cd1d                	beqz	a0,800029c2 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002986:	4789                	li	a5,2
    80002988:	06f50a63          	beq	a0,a5,800029fc <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000298c:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002990:	10049073          	csrw	sstatus,s1
}
    80002994:	70a2                	ld	ra,40(sp)
    80002996:	7402                	ld	s0,32(sp)
    80002998:	64e2                	ld	s1,24(sp)
    8000299a:	6942                	ld	s2,16(sp)
    8000299c:	69a2                	ld	s3,8(sp)
    8000299e:	6145                	addi	sp,sp,48
    800029a0:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800029a2:	00006517          	auipc	a0,0x6
    800029a6:	9fe50513          	addi	a0,a0,-1538 # 800083a0 <states.0+0xc8>
    800029aa:	ffffe097          	auipc	ra,0xffffe
    800029ae:	b96080e7          	jalr	-1130(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    800029b2:	00006517          	auipc	a0,0x6
    800029b6:	a1650513          	addi	a0,a0,-1514 # 800083c8 <states.0+0xf0>
    800029ba:	ffffe097          	auipc	ra,0xffffe
    800029be:	b86080e7          	jalr	-1146(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    800029c2:	85ce                	mv	a1,s3
    800029c4:	00006517          	auipc	a0,0x6
    800029c8:	a2450513          	addi	a0,a0,-1500 # 800083e8 <states.0+0x110>
    800029cc:	ffffe097          	auipc	ra,0xffffe
    800029d0:	bbe080e7          	jalr	-1090(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029d4:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029d8:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029dc:	00006517          	auipc	a0,0x6
    800029e0:	a1c50513          	addi	a0,a0,-1508 # 800083f8 <states.0+0x120>
    800029e4:	ffffe097          	auipc	ra,0xffffe
    800029e8:	ba6080e7          	jalr	-1114(ra) # 8000058a <printf>
    panic("kerneltrap");
    800029ec:	00006517          	auipc	a0,0x6
    800029f0:	a2450513          	addi	a0,a0,-1500 # 80008410 <states.0+0x138>
    800029f4:	ffffe097          	auipc	ra,0xffffe
    800029f8:	b4c080e7          	jalr	-1204(ra) # 80000540 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029fc:	fffff097          	auipc	ra,0xfffff
    80002a00:	fb0080e7          	jalr	-80(ra) # 800019ac <myproc>
    80002a04:	d541                	beqz	a0,8000298c <kerneltrap+0x38>
    80002a06:	fffff097          	auipc	ra,0xfffff
    80002a0a:	fa6080e7          	jalr	-90(ra) # 800019ac <myproc>
    80002a0e:	4d18                	lw	a4,24(a0)
    80002a10:	4791                	li	a5,4
    80002a12:	f6f71de3          	bne	a4,a5,8000298c <kerneltrap+0x38>
    yield();
    80002a16:	fffff097          	auipc	ra,0xfffff
    80002a1a:	666080e7          	jalr	1638(ra) # 8000207c <yield>
    80002a1e:	b7bd                	j	8000298c <kerneltrap+0x38>

0000000080002a20 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a20:	1101                	addi	sp,sp,-32
    80002a22:	ec06                	sd	ra,24(sp)
    80002a24:	e822                	sd	s0,16(sp)
    80002a26:	e426                	sd	s1,8(sp)
    80002a28:	1000                	addi	s0,sp,32
    80002a2a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a2c:	fffff097          	auipc	ra,0xfffff
    80002a30:	f80080e7          	jalr	-128(ra) # 800019ac <myproc>
  switch (n) {
    80002a34:	4795                	li	a5,5
    80002a36:	0497e163          	bltu	a5,s1,80002a78 <argraw+0x58>
    80002a3a:	048a                	slli	s1,s1,0x2
    80002a3c:	00006717          	auipc	a4,0x6
    80002a40:	b4470713          	addi	a4,a4,-1212 # 80008580 <states.0+0x2a8>
    80002a44:	94ba                	add	s1,s1,a4
    80002a46:	409c                	lw	a5,0(s1)
    80002a48:	97ba                	add	a5,a5,a4
    80002a4a:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a4c:	6d3c                	ld	a5,88(a0)
    80002a4e:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a50:	60e2                	ld	ra,24(sp)
    80002a52:	6442                	ld	s0,16(sp)
    80002a54:	64a2                	ld	s1,8(sp)
    80002a56:	6105                	addi	sp,sp,32
    80002a58:	8082                	ret
    return p->trapframe->a1;
    80002a5a:	6d3c                	ld	a5,88(a0)
    80002a5c:	7fa8                	ld	a0,120(a5)
    80002a5e:	bfcd                	j	80002a50 <argraw+0x30>
    return p->trapframe->a2;
    80002a60:	6d3c                	ld	a5,88(a0)
    80002a62:	63c8                	ld	a0,128(a5)
    80002a64:	b7f5                	j	80002a50 <argraw+0x30>
    return p->trapframe->a3;
    80002a66:	6d3c                	ld	a5,88(a0)
    80002a68:	67c8                	ld	a0,136(a5)
    80002a6a:	b7dd                	j	80002a50 <argraw+0x30>
    return p->trapframe->a4;
    80002a6c:	6d3c                	ld	a5,88(a0)
    80002a6e:	6bc8                	ld	a0,144(a5)
    80002a70:	b7c5                	j	80002a50 <argraw+0x30>
    return p->trapframe->a5;
    80002a72:	6d3c                	ld	a5,88(a0)
    80002a74:	6fc8                	ld	a0,152(a5)
    80002a76:	bfe9                	j	80002a50 <argraw+0x30>
  panic("argraw");
    80002a78:	00006517          	auipc	a0,0x6
    80002a7c:	9a850513          	addi	a0,a0,-1624 # 80008420 <states.0+0x148>
    80002a80:	ffffe097          	auipc	ra,0xffffe
    80002a84:	ac0080e7          	jalr	-1344(ra) # 80000540 <panic>

0000000080002a88 <fetchaddr>:
{
    80002a88:	1101                	addi	sp,sp,-32
    80002a8a:	ec06                	sd	ra,24(sp)
    80002a8c:	e822                	sd	s0,16(sp)
    80002a8e:	e426                	sd	s1,8(sp)
    80002a90:	e04a                	sd	s2,0(sp)
    80002a92:	1000                	addi	s0,sp,32
    80002a94:	84aa                	mv	s1,a0
    80002a96:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002a98:	fffff097          	auipc	ra,0xfffff
    80002a9c:	f14080e7          	jalr	-236(ra) # 800019ac <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002aa0:	653c                	ld	a5,72(a0)
    80002aa2:	02f4f863          	bgeu	s1,a5,80002ad2 <fetchaddr+0x4a>
    80002aa6:	00848713          	addi	a4,s1,8
    80002aaa:	02e7e663          	bltu	a5,a4,80002ad6 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002aae:	46a1                	li	a3,8
    80002ab0:	8626                	mv	a2,s1
    80002ab2:	85ca                	mv	a1,s2
    80002ab4:	6928                	ld	a0,80(a0)
    80002ab6:	fffff097          	auipc	ra,0xfffff
    80002aba:	c42080e7          	jalr	-958(ra) # 800016f8 <copyin>
    80002abe:	00a03533          	snez	a0,a0
    80002ac2:	40a00533          	neg	a0,a0
}
    80002ac6:	60e2                	ld	ra,24(sp)
    80002ac8:	6442                	ld	s0,16(sp)
    80002aca:	64a2                	ld	s1,8(sp)
    80002acc:	6902                	ld	s2,0(sp)
    80002ace:	6105                	addi	sp,sp,32
    80002ad0:	8082                	ret
    return -1;
    80002ad2:	557d                	li	a0,-1
    80002ad4:	bfcd                	j	80002ac6 <fetchaddr+0x3e>
    80002ad6:	557d                	li	a0,-1
    80002ad8:	b7fd                	j	80002ac6 <fetchaddr+0x3e>

0000000080002ada <fetchstr>:
{
    80002ada:	7179                	addi	sp,sp,-48
    80002adc:	f406                	sd	ra,40(sp)
    80002ade:	f022                	sd	s0,32(sp)
    80002ae0:	ec26                	sd	s1,24(sp)
    80002ae2:	e84a                	sd	s2,16(sp)
    80002ae4:	e44e                	sd	s3,8(sp)
    80002ae6:	1800                	addi	s0,sp,48
    80002ae8:	892a                	mv	s2,a0
    80002aea:	84ae                	mv	s1,a1
    80002aec:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002aee:	fffff097          	auipc	ra,0xfffff
    80002af2:	ebe080e7          	jalr	-322(ra) # 800019ac <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002af6:	86ce                	mv	a3,s3
    80002af8:	864a                	mv	a2,s2
    80002afa:	85a6                	mv	a1,s1
    80002afc:	6928                	ld	a0,80(a0)
    80002afe:	fffff097          	auipc	ra,0xfffff
    80002b02:	c88080e7          	jalr	-888(ra) # 80001786 <copyinstr>
    80002b06:	00054e63          	bltz	a0,80002b22 <fetchstr+0x48>
  return strlen(buf);
    80002b0a:	8526                	mv	a0,s1
    80002b0c:	ffffe097          	auipc	ra,0xffffe
    80002b10:	342080e7          	jalr	834(ra) # 80000e4e <strlen>
}
    80002b14:	70a2                	ld	ra,40(sp)
    80002b16:	7402                	ld	s0,32(sp)
    80002b18:	64e2                	ld	s1,24(sp)
    80002b1a:	6942                	ld	s2,16(sp)
    80002b1c:	69a2                	ld	s3,8(sp)
    80002b1e:	6145                	addi	sp,sp,48
    80002b20:	8082                	ret
    return -1;
    80002b22:	557d                	li	a0,-1
    80002b24:	bfc5                	j	80002b14 <fetchstr+0x3a>

0000000080002b26 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002b26:	1101                	addi	sp,sp,-32
    80002b28:	ec06                	sd	ra,24(sp)
    80002b2a:	e822                	sd	s0,16(sp)
    80002b2c:	e426                	sd	s1,8(sp)
    80002b2e:	1000                	addi	s0,sp,32
    80002b30:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b32:	00000097          	auipc	ra,0x0
    80002b36:	eee080e7          	jalr	-274(ra) # 80002a20 <argraw>
    80002b3a:	c088                	sw	a0,0(s1)
}
    80002b3c:	60e2                	ld	ra,24(sp)
    80002b3e:	6442                	ld	s0,16(sp)
    80002b40:	64a2                	ld	s1,8(sp)
    80002b42:	6105                	addi	sp,sp,32
    80002b44:	8082                	ret

0000000080002b46 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002b46:	1101                	addi	sp,sp,-32
    80002b48:	ec06                	sd	ra,24(sp)
    80002b4a:	e822                	sd	s0,16(sp)
    80002b4c:	e426                	sd	s1,8(sp)
    80002b4e:	1000                	addi	s0,sp,32
    80002b50:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b52:	00000097          	auipc	ra,0x0
    80002b56:	ece080e7          	jalr	-306(ra) # 80002a20 <argraw>
    80002b5a:	e088                	sd	a0,0(s1)
}
    80002b5c:	60e2                	ld	ra,24(sp)
    80002b5e:	6442                	ld	s0,16(sp)
    80002b60:	64a2                	ld	s1,8(sp)
    80002b62:	6105                	addi	sp,sp,32
    80002b64:	8082                	ret

0000000080002b66 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002b66:	7179                	addi	sp,sp,-48
    80002b68:	f406                	sd	ra,40(sp)
    80002b6a:	f022                	sd	s0,32(sp)
    80002b6c:	ec26                	sd	s1,24(sp)
    80002b6e:	e84a                	sd	s2,16(sp)
    80002b70:	1800                	addi	s0,sp,48
    80002b72:	84ae                	mv	s1,a1
    80002b74:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002b76:	fd840593          	addi	a1,s0,-40
    80002b7a:	00000097          	auipc	ra,0x0
    80002b7e:	fcc080e7          	jalr	-52(ra) # 80002b46 <argaddr>
  return fetchstr(addr, buf, max);
    80002b82:	864a                	mv	a2,s2
    80002b84:	85a6                	mv	a1,s1
    80002b86:	fd843503          	ld	a0,-40(s0)
    80002b8a:	00000097          	auipc	ra,0x0
    80002b8e:	f50080e7          	jalr	-176(ra) # 80002ada <fetchstr>
}
    80002b92:	70a2                	ld	ra,40(sp)
    80002b94:	7402                	ld	s0,32(sp)
    80002b96:	64e2                	ld	s1,24(sp)
    80002b98:	6942                	ld	s2,16(sp)
    80002b9a:	6145                	addi	sp,sp,48
    80002b9c:	8082                	ret

0000000080002b9e <syscall>:
[SYS_audit]   sys_audit,
};

void
syscall(void)
{
    80002b9e:	715d                	addi	sp,sp,-80
    80002ba0:	e486                	sd	ra,72(sp)
    80002ba2:	e0a2                	sd	s0,64(sp)
    80002ba4:	fc26                	sd	s1,56(sp)
    80002ba6:	f84a                	sd	s2,48(sp)
    80002ba8:	f44e                	sd	s3,40(sp)
    80002baa:	f052                	sd	s4,32(sp)
    80002bac:	ec56                	sd	s5,24(sp)
    80002bae:	e85a                	sd	s6,16(sp)
    80002bb0:	0880                	addi	s0,sp,80
  int num;
  struct proc *p = myproc();
    80002bb2:	fffff097          	auipc	ra,0xfffff
    80002bb6:	dfa080e7          	jalr	-518(ra) # 800019ac <myproc>
    80002bba:	84aa                	mv	s1,a0

  // any time we are here, we are about to make a system call.
  // we can intercept args, etc.
  num = p->trapframe->a7;
    80002bbc:	6d3c                	ld	a5,88(a0)
    80002bbe:	77dc                	ld	a5,168(a5)
    80002bc0:	0007891b          	sext.w	s2,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002bc4:	fff7869b          	addiw	a3,a5,-1
    80002bc8:	4755                	li	a4,21
    80002bca:	10d76563          	bltu	a4,a3,80002cd4 <syscall+0x136>
    80002bce:	00391693          	slli	a3,s2,0x3
    80002bd2:	00006717          	auipc	a4,0x6
    80002bd6:	9c670713          	addi	a4,a4,-1594 # 80008598 <syscalls>
    80002bda:	9736                	add	a4,a4,a3
    80002bdc:	00073a03          	ld	s4,0(a4)
    80002be0:	0e0a0a63          	beqz	s4,80002cd4 <syscall+0x136>
    // and we will lose the args after the syscall is made.
    int fd = -1;
    struct file *f;

    // if it's any of these file related operations
    if (num == SYS_read || num == SYS_fstat || num == SYS_dup 
    80002be4:	4715                	li	a4,5
    80002be6:	04e90a63          	beq	s2,a4,80002c3a <syscall+0x9c>
    80002bea:	4755                	li	a4,21
    80002bec:	01276a63          	bltu	a4,s2,80002c00 <syscall+0x62>
    80002bf0:	00218737          	lui	a4,0x218
    80002bf4:	50070713          	addi	a4,a4,1280 # 218500 <_entry-0x7fde7b00>
    80002bf8:	012757b3          	srl	a5,a4,s2
    80002bfc:	8b85                	andi	a5,a5,1
    80002bfe:	ef95                	bnez	a5,80002c3a <syscall+0x9c>
      // we are trying to do SOMETHING with this file.
      argfd(0, &fd, &f);
    }
    
    // let the system call go through.
    p->trapframe->a0 = syscalls[num]();
    80002c00:	0584b983          	ld	s3,88(s1)
    80002c04:	9a02                	jalr	s4
    80002c06:	06a9b823          	sd	a0,112(s3)

    // these things will be consistent across processes, no matter if it used a file
    struct audit_data cur;
    cur.process_pid = p->pid;
    80002c0a:	5890                	lw	a2,48(s1)
    cur.process_name = p->name;
    80002c0c:	15848593          	addi	a1,s1,344
    cur.time = ticks;
    80002c10:	00006717          	auipc	a4,0x6
    80002c14:	ee072703          	lw	a4,-288(a4) # 80008af0 <ticks>
    cur.process_name = name_from_num[num];
    80002c18:	090e                	slli	s2,s2,0x3
    80002c1a:	00006797          	auipc	a5,0x6
    80002c1e:	dce78793          	addi	a5,a5,-562 # 800089e8 <name_from_num>
    80002c22:	97ca                	add	a5,a5,s2
    80002c24:	6384                	ld	s1,0(a5)
    } else {
      // just say we didn't use one
      cur.fd_used = 0;


      printf("Process %s pid %d called syscall %s at time %d\n", 
    80002c26:	86a6                	mv	a3,s1
    80002c28:	00006517          	auipc	a0,0x6
    80002c2c:	85850513          	addi	a0,a0,-1960 # 80008480 <states.0+0x1a8>
    80002c30:	ffffe097          	auipc	ra,0xffffe
    80002c34:	95a080e7          	jalr	-1702(ra) # 8000058a <printf>
    80002c38:	a041                	j	80002cb8 <syscall+0x11a>
  argint(n, &fd);
    80002c3a:	fbc40593          	addi	a1,s0,-68
    80002c3e:	4501                	li	a0,0
    80002c40:	00000097          	auipc	ra,0x0
    80002c44:	ee6080e7          	jalr	-282(ra) # 80002b26 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80002c48:	fbc42a83          	lw	s5,-68(s0)
    80002c4c:	000a871b          	sext.w	a4,s5
    80002c50:	47bd                	li	a5,15
    80002c52:	06e7ef63          	bltu	a5,a4,80002cd0 <syscall+0x132>
    80002c56:	fffff097          	auipc	ra,0xfffff
    80002c5a:	d56080e7          	jalr	-682(ra) # 800019ac <myproc>
    80002c5e:	01aa8793          	addi	a5,s5,26
    80002c62:	078e                	slli	a5,a5,0x3
    80002c64:	953e                	add	a0,a0,a5
    80002c66:	00053983          	ld	s3,0(a0)
    80002c6a:	06098163          	beqz	s3,80002ccc <syscall+0x12e>
    p->trapframe->a0 = syscalls[num]();
    80002c6e:	0584bb03          	ld	s6,88(s1)
    80002c72:	9a02                	jalr	s4
    80002c74:	06ab3823          	sd	a0,112(s6)
    cur.process_pid = p->pid;
    80002c78:	5890                	lw	a2,48(s1)
    cur.process_name = p->name;
    80002c7a:	15848593          	addi	a1,s1,344
    cur.time = ticks;
    80002c7e:	00006717          	auipc	a4,0x6
    80002c82:	e7272703          	lw	a4,-398(a4) # 80008af0 <ticks>
    cur.process_name = name_from_num[num];
    80002c86:	090e                	slli	s2,s2,0x3
    80002c88:	00006797          	auipc	a5,0x6
    80002c8c:	d6078793          	addi	a5,a5,-672 # 800089e8 <name_from_num>
    80002c90:	993e                	add	s2,s2,a5
    80002c92:	00093483          	ld	s1,0(s2)
    if (fd != -1) {
    80002c96:	57fd                	li	a5,-1
    80002c98:	f8fa87e3          	beq	s5,a5,80002c26 <syscall+0x88>
      printf("Process %s pid %d called syscall %s at time %d and used FD %d (perms r: %d, w: %d)\n",
    80002c9c:	0099c883          	lbu	a7,9(s3)
    80002ca0:	0089c803          	lbu	a6,8(s3)
    80002ca4:	87d6                	mv	a5,s5
    80002ca6:	86a6                	mv	a3,s1
    80002ca8:	00005517          	auipc	a0,0x5
    80002cac:	78050513          	addi	a0,a0,1920 # 80008428 <states.0+0x150>
    80002cb0:	ffffe097          	auipc	ra,0xffffe
    80002cb4:	8da080e7          	jalr	-1830(ra) # 8000058a <printf>
            p->name, p->pid, name_from_num[num], ticks);
    }

    printf("%d\n", cur.process_name);
    80002cb8:	85a6                	mv	a1,s1
    80002cba:	00006517          	auipc	a0,0x6
    80002cbe:	80e50513          	addi	a0,a0,-2034 # 800084c8 <states.0+0x1f0>
    80002cc2:	ffffe097          	auipc	ra,0xffffe
    80002cc6:	8c8080e7          	jalr	-1848(ra) # 8000058a <printf>
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002cca:	a025                	j	80002cf2 <syscall+0x154>
    int fd = -1;
    80002ccc:	5afd                	li	s5,-1
    80002cce:	b745                	j	80002c6e <syscall+0xd0>
    80002cd0:	5afd                	li	s5,-1
    80002cd2:	bf71                	j	80002c6e <syscall+0xd0>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002cd4:	86ca                	mv	a3,s2
    80002cd6:	15848613          	addi	a2,s1,344
    80002cda:	588c                	lw	a1,48(s1)
    80002cdc:	00005517          	auipc	a0,0x5
    80002ce0:	7d450513          	addi	a0,a0,2004 # 800084b0 <states.0+0x1d8>
    80002ce4:	ffffe097          	auipc	ra,0xffffe
    80002ce8:	8a6080e7          	jalr	-1882(ra) # 8000058a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002cec:	6cbc                	ld	a5,88(s1)
    80002cee:	577d                	li	a4,-1
    80002cf0:	fbb8                	sd	a4,112(a5)
  }
}
    80002cf2:	60a6                	ld	ra,72(sp)
    80002cf4:	6406                	ld	s0,64(sp)
    80002cf6:	74e2                	ld	s1,56(sp)
    80002cf8:	7942                	ld	s2,48(sp)
    80002cfa:	79a2                	ld	s3,40(sp)
    80002cfc:	7a02                	ld	s4,32(sp)
    80002cfe:	6ae2                	ld	s5,24(sp)
    80002d00:	6b42                	ld	s6,16(sp)
    80002d02:	6161                	addi	sp,sp,80
    80002d04:	8082                	ret

0000000080002d06 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002d06:	1101                	addi	sp,sp,-32
    80002d08:	ec06                	sd	ra,24(sp)
    80002d0a:	e822                	sd	s0,16(sp)
    80002d0c:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002d0e:	fec40593          	addi	a1,s0,-20
    80002d12:	4501                	li	a0,0
    80002d14:	00000097          	auipc	ra,0x0
    80002d18:	e12080e7          	jalr	-494(ra) # 80002b26 <argint>
  exit(n);
    80002d1c:	fec42503          	lw	a0,-20(s0)
    80002d20:	fffff097          	auipc	ra,0xfffff
    80002d24:	4cc080e7          	jalr	1228(ra) # 800021ec <exit>
  return 0;  // not reached
}
    80002d28:	4501                	li	a0,0
    80002d2a:	60e2                	ld	ra,24(sp)
    80002d2c:	6442                	ld	s0,16(sp)
    80002d2e:	6105                	addi	sp,sp,32
    80002d30:	8082                	ret

0000000080002d32 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002d32:	1141                	addi	sp,sp,-16
    80002d34:	e406                	sd	ra,8(sp)
    80002d36:	e022                	sd	s0,0(sp)
    80002d38:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002d3a:	fffff097          	auipc	ra,0xfffff
    80002d3e:	c72080e7          	jalr	-910(ra) # 800019ac <myproc>
}
    80002d42:	5908                	lw	a0,48(a0)
    80002d44:	60a2                	ld	ra,8(sp)
    80002d46:	6402                	ld	s0,0(sp)
    80002d48:	0141                	addi	sp,sp,16
    80002d4a:	8082                	ret

0000000080002d4c <sys_fork>:

uint64
sys_fork(void)
{
    80002d4c:	1141                	addi	sp,sp,-16
    80002d4e:	e406                	sd	ra,8(sp)
    80002d50:	e022                	sd	s0,0(sp)
    80002d52:	0800                	addi	s0,sp,16
  return fork();
    80002d54:	fffff097          	auipc	ra,0xfffff
    80002d58:	00e080e7          	jalr	14(ra) # 80001d62 <fork>
}
    80002d5c:	60a2                	ld	ra,8(sp)
    80002d5e:	6402                	ld	s0,0(sp)
    80002d60:	0141                	addi	sp,sp,16
    80002d62:	8082                	ret

0000000080002d64 <sys_wait>:

uint64
sys_wait(void)
{
    80002d64:	1101                	addi	sp,sp,-32
    80002d66:	ec06                	sd	ra,24(sp)
    80002d68:	e822                	sd	s0,16(sp)
    80002d6a:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002d6c:	fe840593          	addi	a1,s0,-24
    80002d70:	4501                	li	a0,0
    80002d72:	00000097          	auipc	ra,0x0
    80002d76:	dd4080e7          	jalr	-556(ra) # 80002b46 <argaddr>
  return wait(p);
    80002d7a:	fe843503          	ld	a0,-24(s0)
    80002d7e:	fffff097          	auipc	ra,0xfffff
    80002d82:	614080e7          	jalr	1556(ra) # 80002392 <wait>
}
    80002d86:	60e2                	ld	ra,24(sp)
    80002d88:	6442                	ld	s0,16(sp)
    80002d8a:	6105                	addi	sp,sp,32
    80002d8c:	8082                	ret

0000000080002d8e <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d8e:	7179                	addi	sp,sp,-48
    80002d90:	f406                	sd	ra,40(sp)
    80002d92:	f022                	sd	s0,32(sp)
    80002d94:	ec26                	sd	s1,24(sp)
    80002d96:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002d98:	fdc40593          	addi	a1,s0,-36
    80002d9c:	4501                	li	a0,0
    80002d9e:	00000097          	auipc	ra,0x0
    80002da2:	d88080e7          	jalr	-632(ra) # 80002b26 <argint>
  addr = myproc()->sz;
    80002da6:	fffff097          	auipc	ra,0xfffff
    80002daa:	c06080e7          	jalr	-1018(ra) # 800019ac <myproc>
    80002dae:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002db0:	fdc42503          	lw	a0,-36(s0)
    80002db4:	fffff097          	auipc	ra,0xfffff
    80002db8:	f52080e7          	jalr	-174(ra) # 80001d06 <growproc>
    80002dbc:	00054863          	bltz	a0,80002dcc <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002dc0:	8526                	mv	a0,s1
    80002dc2:	70a2                	ld	ra,40(sp)
    80002dc4:	7402                	ld	s0,32(sp)
    80002dc6:	64e2                	ld	s1,24(sp)
    80002dc8:	6145                	addi	sp,sp,48
    80002dca:	8082                	ret
    return -1;
    80002dcc:	54fd                	li	s1,-1
    80002dce:	bfcd                	j	80002dc0 <sys_sbrk+0x32>

0000000080002dd0 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002dd0:	7139                	addi	sp,sp,-64
    80002dd2:	fc06                	sd	ra,56(sp)
    80002dd4:	f822                	sd	s0,48(sp)
    80002dd6:	f426                	sd	s1,40(sp)
    80002dd8:	f04a                	sd	s2,32(sp)
    80002dda:	ec4e                	sd	s3,24(sp)
    80002ddc:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002dde:	fcc40593          	addi	a1,s0,-52
    80002de2:	4501                	li	a0,0
    80002de4:	00000097          	auipc	ra,0x0
    80002de8:	d42080e7          	jalr	-702(ra) # 80002b26 <argint>
  acquire(&tickslock);
    80002dec:	00014517          	auipc	a0,0x14
    80002df0:	fb450513          	addi	a0,a0,-76 # 80016da0 <tickslock>
    80002df4:	ffffe097          	auipc	ra,0xffffe
    80002df8:	de2080e7          	jalr	-542(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80002dfc:	00006917          	auipc	s2,0x6
    80002e00:	cf492903          	lw	s2,-780(s2) # 80008af0 <ticks>
  while(ticks - ticks0 < n){
    80002e04:	fcc42783          	lw	a5,-52(s0)
    80002e08:	cf9d                	beqz	a5,80002e46 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002e0a:	00014997          	auipc	s3,0x14
    80002e0e:	f9698993          	addi	s3,s3,-106 # 80016da0 <tickslock>
    80002e12:	00006497          	auipc	s1,0x6
    80002e16:	cde48493          	addi	s1,s1,-802 # 80008af0 <ticks>
    if(killed(myproc())){
    80002e1a:	fffff097          	auipc	ra,0xfffff
    80002e1e:	b92080e7          	jalr	-1134(ra) # 800019ac <myproc>
    80002e22:	fffff097          	auipc	ra,0xfffff
    80002e26:	53e080e7          	jalr	1342(ra) # 80002360 <killed>
    80002e2a:	ed15                	bnez	a0,80002e66 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002e2c:	85ce                	mv	a1,s3
    80002e2e:	8526                	mv	a0,s1
    80002e30:	fffff097          	auipc	ra,0xfffff
    80002e34:	288080e7          	jalr	648(ra) # 800020b8 <sleep>
  while(ticks - ticks0 < n){
    80002e38:	409c                	lw	a5,0(s1)
    80002e3a:	412787bb          	subw	a5,a5,s2
    80002e3e:	fcc42703          	lw	a4,-52(s0)
    80002e42:	fce7ece3          	bltu	a5,a4,80002e1a <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002e46:	00014517          	auipc	a0,0x14
    80002e4a:	f5a50513          	addi	a0,a0,-166 # 80016da0 <tickslock>
    80002e4e:	ffffe097          	auipc	ra,0xffffe
    80002e52:	e3c080e7          	jalr	-452(ra) # 80000c8a <release>
  return 0;
    80002e56:	4501                	li	a0,0
}
    80002e58:	70e2                	ld	ra,56(sp)
    80002e5a:	7442                	ld	s0,48(sp)
    80002e5c:	74a2                	ld	s1,40(sp)
    80002e5e:	7902                	ld	s2,32(sp)
    80002e60:	69e2                	ld	s3,24(sp)
    80002e62:	6121                	addi	sp,sp,64
    80002e64:	8082                	ret
      release(&tickslock);
    80002e66:	00014517          	auipc	a0,0x14
    80002e6a:	f3a50513          	addi	a0,a0,-198 # 80016da0 <tickslock>
    80002e6e:	ffffe097          	auipc	ra,0xffffe
    80002e72:	e1c080e7          	jalr	-484(ra) # 80000c8a <release>
      return -1;
    80002e76:	557d                	li	a0,-1
    80002e78:	b7c5                	j	80002e58 <sys_sleep+0x88>

0000000080002e7a <sys_kill>:

uint64
sys_kill(void)
{
    80002e7a:	1101                	addi	sp,sp,-32
    80002e7c:	ec06                	sd	ra,24(sp)
    80002e7e:	e822                	sd	s0,16(sp)
    80002e80:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002e82:	fec40593          	addi	a1,s0,-20
    80002e86:	4501                	li	a0,0
    80002e88:	00000097          	auipc	ra,0x0
    80002e8c:	c9e080e7          	jalr	-866(ra) # 80002b26 <argint>
  return kill(pid);
    80002e90:	fec42503          	lw	a0,-20(s0)
    80002e94:	fffff097          	auipc	ra,0xfffff
    80002e98:	42e080e7          	jalr	1070(ra) # 800022c2 <kill>
}
    80002e9c:	60e2                	ld	ra,24(sp)
    80002e9e:	6442                	ld	s0,16(sp)
    80002ea0:	6105                	addi	sp,sp,32
    80002ea2:	8082                	ret

0000000080002ea4 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002ea4:	1101                	addi	sp,sp,-32
    80002ea6:	ec06                	sd	ra,24(sp)
    80002ea8:	e822                	sd	s0,16(sp)
    80002eaa:	e426                	sd	s1,8(sp)
    80002eac:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002eae:	00014517          	auipc	a0,0x14
    80002eb2:	ef250513          	addi	a0,a0,-270 # 80016da0 <tickslock>
    80002eb6:	ffffe097          	auipc	ra,0xffffe
    80002eba:	d20080e7          	jalr	-736(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80002ebe:	00006497          	auipc	s1,0x6
    80002ec2:	c324a483          	lw	s1,-974(s1) # 80008af0 <ticks>
  release(&tickslock);
    80002ec6:	00014517          	auipc	a0,0x14
    80002eca:	eda50513          	addi	a0,a0,-294 # 80016da0 <tickslock>
    80002ece:	ffffe097          	auipc	ra,0xffffe
    80002ed2:	dbc080e7          	jalr	-580(ra) # 80000c8a <release>
  return xticks;
}
    80002ed6:	02049513          	slli	a0,s1,0x20
    80002eda:	9101                	srli	a0,a0,0x20
    80002edc:	60e2                	ld	ra,24(sp)
    80002ede:	6442                	ld	s0,16(sp)
    80002ee0:	64a2                	ld	s1,8(sp)
    80002ee2:	6105                	addi	sp,sp,32
    80002ee4:	8082                	ret

0000000080002ee6 <sys_audit>:

uint64
sys_audit(void)
{
    80002ee6:	1101                	addi	sp,sp,-32
    80002ee8:	ec06                	sd	ra,24(sp)
    80002eea:	e822                	sd	s0,16(sp)
    80002eec:	1000                	addi	s0,sp,32
  printf("in sys audit\n");
    80002eee:	00005517          	auipc	a0,0x5
    80002ef2:	76250513          	addi	a0,a0,1890 # 80008650 <syscalls+0xb8>
    80002ef6:	ffffd097          	auipc	ra,0xffffd
    80002efa:	694080e7          	jalr	1684(ra) # 8000058a <printf>
  uint64 arr_addr;
  argaddr(0, &arr_addr);
    80002efe:	fe840593          	addi	a1,s0,-24
    80002f02:	4501                	li	a0,0
    80002f04:	00000097          	auipc	ra,0x0
    80002f08:	c42080e7          	jalr	-958(ra) # 80002b46 <argaddr>
  return audit((int*) arr_addr);
    80002f0c:	fe843503          	ld	a0,-24(s0)
    80002f10:	fffff097          	auipc	ra,0xfffff
    80002f14:	f92080e7          	jalr	-110(ra) # 80001ea2 <audit>
}
    80002f18:	60e2                	ld	ra,24(sp)
    80002f1a:	6442                	ld	s0,16(sp)
    80002f1c:	6105                	addi	sp,sp,32
    80002f1e:	8082                	ret

0000000080002f20 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f20:	7179                	addi	sp,sp,-48
    80002f22:	f406                	sd	ra,40(sp)
    80002f24:	f022                	sd	s0,32(sp)
    80002f26:	ec26                	sd	s1,24(sp)
    80002f28:	e84a                	sd	s2,16(sp)
    80002f2a:	e44e                	sd	s3,8(sp)
    80002f2c:	e052                	sd	s4,0(sp)
    80002f2e:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002f30:	00005597          	auipc	a1,0x5
    80002f34:	73058593          	addi	a1,a1,1840 # 80008660 <syscalls+0xc8>
    80002f38:	00020517          	auipc	a0,0x20
    80002f3c:	e8050513          	addi	a0,a0,-384 # 80022db8 <bcache>
    80002f40:	ffffe097          	auipc	ra,0xffffe
    80002f44:	c06080e7          	jalr	-1018(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f48:	00028797          	auipc	a5,0x28
    80002f4c:	e7078793          	addi	a5,a5,-400 # 8002adb8 <bcache+0x8000>
    80002f50:	00028717          	auipc	a4,0x28
    80002f54:	0d070713          	addi	a4,a4,208 # 8002b020 <bcache+0x8268>
    80002f58:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f5c:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f60:	00020497          	auipc	s1,0x20
    80002f64:	e7048493          	addi	s1,s1,-400 # 80022dd0 <bcache+0x18>
    b->next = bcache.head.next;
    80002f68:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f6a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f6c:	00005a17          	auipc	s4,0x5
    80002f70:	6fca0a13          	addi	s4,s4,1788 # 80008668 <syscalls+0xd0>
    b->next = bcache.head.next;
    80002f74:	2b893783          	ld	a5,696(s2)
    80002f78:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f7a:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f7e:	85d2                	mv	a1,s4
    80002f80:	01048513          	addi	a0,s1,16
    80002f84:	00001097          	auipc	ra,0x1
    80002f88:	4c8080e7          	jalr	1224(ra) # 8000444c <initsleeplock>
    bcache.head.next->prev = b;
    80002f8c:	2b893783          	ld	a5,696(s2)
    80002f90:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f92:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f96:	45848493          	addi	s1,s1,1112
    80002f9a:	fd349de3          	bne	s1,s3,80002f74 <binit+0x54>
  }
}
    80002f9e:	70a2                	ld	ra,40(sp)
    80002fa0:	7402                	ld	s0,32(sp)
    80002fa2:	64e2                	ld	s1,24(sp)
    80002fa4:	6942                	ld	s2,16(sp)
    80002fa6:	69a2                	ld	s3,8(sp)
    80002fa8:	6a02                	ld	s4,0(sp)
    80002faa:	6145                	addi	sp,sp,48
    80002fac:	8082                	ret

0000000080002fae <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002fae:	7179                	addi	sp,sp,-48
    80002fb0:	f406                	sd	ra,40(sp)
    80002fb2:	f022                	sd	s0,32(sp)
    80002fb4:	ec26                	sd	s1,24(sp)
    80002fb6:	e84a                	sd	s2,16(sp)
    80002fb8:	e44e                	sd	s3,8(sp)
    80002fba:	1800                	addi	s0,sp,48
    80002fbc:	892a                	mv	s2,a0
    80002fbe:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002fc0:	00020517          	auipc	a0,0x20
    80002fc4:	df850513          	addi	a0,a0,-520 # 80022db8 <bcache>
    80002fc8:	ffffe097          	auipc	ra,0xffffe
    80002fcc:	c0e080e7          	jalr	-1010(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002fd0:	00028497          	auipc	s1,0x28
    80002fd4:	0a04b483          	ld	s1,160(s1) # 8002b070 <bcache+0x82b8>
    80002fd8:	00028797          	auipc	a5,0x28
    80002fdc:	04878793          	addi	a5,a5,72 # 8002b020 <bcache+0x8268>
    80002fe0:	02f48f63          	beq	s1,a5,8000301e <bread+0x70>
    80002fe4:	873e                	mv	a4,a5
    80002fe6:	a021                	j	80002fee <bread+0x40>
    80002fe8:	68a4                	ld	s1,80(s1)
    80002fea:	02e48a63          	beq	s1,a4,8000301e <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002fee:	449c                	lw	a5,8(s1)
    80002ff0:	ff279ce3          	bne	a5,s2,80002fe8 <bread+0x3a>
    80002ff4:	44dc                	lw	a5,12(s1)
    80002ff6:	ff3799e3          	bne	a5,s3,80002fe8 <bread+0x3a>
      b->refcnt++;
    80002ffa:	40bc                	lw	a5,64(s1)
    80002ffc:	2785                	addiw	a5,a5,1
    80002ffe:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003000:	00020517          	auipc	a0,0x20
    80003004:	db850513          	addi	a0,a0,-584 # 80022db8 <bcache>
    80003008:	ffffe097          	auipc	ra,0xffffe
    8000300c:	c82080e7          	jalr	-894(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003010:	01048513          	addi	a0,s1,16
    80003014:	00001097          	auipc	ra,0x1
    80003018:	472080e7          	jalr	1138(ra) # 80004486 <acquiresleep>
      return b;
    8000301c:	a8b9                	j	8000307a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000301e:	00028497          	auipc	s1,0x28
    80003022:	04a4b483          	ld	s1,74(s1) # 8002b068 <bcache+0x82b0>
    80003026:	00028797          	auipc	a5,0x28
    8000302a:	ffa78793          	addi	a5,a5,-6 # 8002b020 <bcache+0x8268>
    8000302e:	00f48863          	beq	s1,a5,8000303e <bread+0x90>
    80003032:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003034:	40bc                	lw	a5,64(s1)
    80003036:	cf81                	beqz	a5,8000304e <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003038:	64a4                	ld	s1,72(s1)
    8000303a:	fee49de3          	bne	s1,a4,80003034 <bread+0x86>
  panic("bget: no buffers");
    8000303e:	00005517          	auipc	a0,0x5
    80003042:	63250513          	addi	a0,a0,1586 # 80008670 <syscalls+0xd8>
    80003046:	ffffd097          	auipc	ra,0xffffd
    8000304a:	4fa080e7          	jalr	1274(ra) # 80000540 <panic>
      b->dev = dev;
    8000304e:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003052:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003056:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000305a:	4785                	li	a5,1
    8000305c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000305e:	00020517          	auipc	a0,0x20
    80003062:	d5a50513          	addi	a0,a0,-678 # 80022db8 <bcache>
    80003066:	ffffe097          	auipc	ra,0xffffe
    8000306a:	c24080e7          	jalr	-988(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    8000306e:	01048513          	addi	a0,s1,16
    80003072:	00001097          	auipc	ra,0x1
    80003076:	414080e7          	jalr	1044(ra) # 80004486 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000307a:	409c                	lw	a5,0(s1)
    8000307c:	cb89                	beqz	a5,8000308e <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000307e:	8526                	mv	a0,s1
    80003080:	70a2                	ld	ra,40(sp)
    80003082:	7402                	ld	s0,32(sp)
    80003084:	64e2                	ld	s1,24(sp)
    80003086:	6942                	ld	s2,16(sp)
    80003088:	69a2                	ld	s3,8(sp)
    8000308a:	6145                	addi	sp,sp,48
    8000308c:	8082                	ret
    virtio_disk_rw(b, 0);
    8000308e:	4581                	li	a1,0
    80003090:	8526                	mv	a0,s1
    80003092:	00003097          	auipc	ra,0x3
    80003096:	fe0080e7          	jalr	-32(ra) # 80006072 <virtio_disk_rw>
    b->valid = 1;
    8000309a:	4785                	li	a5,1
    8000309c:	c09c                	sw	a5,0(s1)
  return b;
    8000309e:	b7c5                	j	8000307e <bread+0xd0>

00000000800030a0 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800030a0:	1101                	addi	sp,sp,-32
    800030a2:	ec06                	sd	ra,24(sp)
    800030a4:	e822                	sd	s0,16(sp)
    800030a6:	e426                	sd	s1,8(sp)
    800030a8:	1000                	addi	s0,sp,32
    800030aa:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030ac:	0541                	addi	a0,a0,16
    800030ae:	00001097          	auipc	ra,0x1
    800030b2:	472080e7          	jalr	1138(ra) # 80004520 <holdingsleep>
    800030b6:	cd01                	beqz	a0,800030ce <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800030b8:	4585                	li	a1,1
    800030ba:	8526                	mv	a0,s1
    800030bc:	00003097          	auipc	ra,0x3
    800030c0:	fb6080e7          	jalr	-74(ra) # 80006072 <virtio_disk_rw>
}
    800030c4:	60e2                	ld	ra,24(sp)
    800030c6:	6442                	ld	s0,16(sp)
    800030c8:	64a2                	ld	s1,8(sp)
    800030ca:	6105                	addi	sp,sp,32
    800030cc:	8082                	ret
    panic("bwrite");
    800030ce:	00005517          	auipc	a0,0x5
    800030d2:	5ba50513          	addi	a0,a0,1466 # 80008688 <syscalls+0xf0>
    800030d6:	ffffd097          	auipc	ra,0xffffd
    800030da:	46a080e7          	jalr	1130(ra) # 80000540 <panic>

00000000800030de <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800030de:	1101                	addi	sp,sp,-32
    800030e0:	ec06                	sd	ra,24(sp)
    800030e2:	e822                	sd	s0,16(sp)
    800030e4:	e426                	sd	s1,8(sp)
    800030e6:	e04a                	sd	s2,0(sp)
    800030e8:	1000                	addi	s0,sp,32
    800030ea:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030ec:	01050913          	addi	s2,a0,16
    800030f0:	854a                	mv	a0,s2
    800030f2:	00001097          	auipc	ra,0x1
    800030f6:	42e080e7          	jalr	1070(ra) # 80004520 <holdingsleep>
    800030fa:	c92d                	beqz	a0,8000316c <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800030fc:	854a                	mv	a0,s2
    800030fe:	00001097          	auipc	ra,0x1
    80003102:	3de080e7          	jalr	990(ra) # 800044dc <releasesleep>

  acquire(&bcache.lock);
    80003106:	00020517          	auipc	a0,0x20
    8000310a:	cb250513          	addi	a0,a0,-846 # 80022db8 <bcache>
    8000310e:	ffffe097          	auipc	ra,0xffffe
    80003112:	ac8080e7          	jalr	-1336(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003116:	40bc                	lw	a5,64(s1)
    80003118:	37fd                	addiw	a5,a5,-1
    8000311a:	0007871b          	sext.w	a4,a5
    8000311e:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003120:	eb05                	bnez	a4,80003150 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003122:	68bc                	ld	a5,80(s1)
    80003124:	64b8                	ld	a4,72(s1)
    80003126:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003128:	64bc                	ld	a5,72(s1)
    8000312a:	68b8                	ld	a4,80(s1)
    8000312c:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000312e:	00028797          	auipc	a5,0x28
    80003132:	c8a78793          	addi	a5,a5,-886 # 8002adb8 <bcache+0x8000>
    80003136:	2b87b703          	ld	a4,696(a5)
    8000313a:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000313c:	00028717          	auipc	a4,0x28
    80003140:	ee470713          	addi	a4,a4,-284 # 8002b020 <bcache+0x8268>
    80003144:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003146:	2b87b703          	ld	a4,696(a5)
    8000314a:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000314c:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003150:	00020517          	auipc	a0,0x20
    80003154:	c6850513          	addi	a0,a0,-920 # 80022db8 <bcache>
    80003158:	ffffe097          	auipc	ra,0xffffe
    8000315c:	b32080e7          	jalr	-1230(ra) # 80000c8a <release>
}
    80003160:	60e2                	ld	ra,24(sp)
    80003162:	6442                	ld	s0,16(sp)
    80003164:	64a2                	ld	s1,8(sp)
    80003166:	6902                	ld	s2,0(sp)
    80003168:	6105                	addi	sp,sp,32
    8000316a:	8082                	ret
    panic("brelse");
    8000316c:	00005517          	auipc	a0,0x5
    80003170:	52450513          	addi	a0,a0,1316 # 80008690 <syscalls+0xf8>
    80003174:	ffffd097          	auipc	ra,0xffffd
    80003178:	3cc080e7          	jalr	972(ra) # 80000540 <panic>

000000008000317c <bpin>:

void
bpin(struct buf *b) {
    8000317c:	1101                	addi	sp,sp,-32
    8000317e:	ec06                	sd	ra,24(sp)
    80003180:	e822                	sd	s0,16(sp)
    80003182:	e426                	sd	s1,8(sp)
    80003184:	1000                	addi	s0,sp,32
    80003186:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003188:	00020517          	auipc	a0,0x20
    8000318c:	c3050513          	addi	a0,a0,-976 # 80022db8 <bcache>
    80003190:	ffffe097          	auipc	ra,0xffffe
    80003194:	a46080e7          	jalr	-1466(ra) # 80000bd6 <acquire>
  b->refcnt++;
    80003198:	40bc                	lw	a5,64(s1)
    8000319a:	2785                	addiw	a5,a5,1
    8000319c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000319e:	00020517          	auipc	a0,0x20
    800031a2:	c1a50513          	addi	a0,a0,-998 # 80022db8 <bcache>
    800031a6:	ffffe097          	auipc	ra,0xffffe
    800031aa:	ae4080e7          	jalr	-1308(ra) # 80000c8a <release>
}
    800031ae:	60e2                	ld	ra,24(sp)
    800031b0:	6442                	ld	s0,16(sp)
    800031b2:	64a2                	ld	s1,8(sp)
    800031b4:	6105                	addi	sp,sp,32
    800031b6:	8082                	ret

00000000800031b8 <bunpin>:

void
bunpin(struct buf *b) {
    800031b8:	1101                	addi	sp,sp,-32
    800031ba:	ec06                	sd	ra,24(sp)
    800031bc:	e822                	sd	s0,16(sp)
    800031be:	e426                	sd	s1,8(sp)
    800031c0:	1000                	addi	s0,sp,32
    800031c2:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031c4:	00020517          	auipc	a0,0x20
    800031c8:	bf450513          	addi	a0,a0,-1036 # 80022db8 <bcache>
    800031cc:	ffffe097          	auipc	ra,0xffffe
    800031d0:	a0a080e7          	jalr	-1526(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800031d4:	40bc                	lw	a5,64(s1)
    800031d6:	37fd                	addiw	a5,a5,-1
    800031d8:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031da:	00020517          	auipc	a0,0x20
    800031de:	bde50513          	addi	a0,a0,-1058 # 80022db8 <bcache>
    800031e2:	ffffe097          	auipc	ra,0xffffe
    800031e6:	aa8080e7          	jalr	-1368(ra) # 80000c8a <release>
}
    800031ea:	60e2                	ld	ra,24(sp)
    800031ec:	6442                	ld	s0,16(sp)
    800031ee:	64a2                	ld	s1,8(sp)
    800031f0:	6105                	addi	sp,sp,32
    800031f2:	8082                	ret

00000000800031f4 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800031f4:	1101                	addi	sp,sp,-32
    800031f6:	ec06                	sd	ra,24(sp)
    800031f8:	e822                	sd	s0,16(sp)
    800031fa:	e426                	sd	s1,8(sp)
    800031fc:	e04a                	sd	s2,0(sp)
    800031fe:	1000                	addi	s0,sp,32
    80003200:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003202:	00d5d59b          	srliw	a1,a1,0xd
    80003206:	00028797          	auipc	a5,0x28
    8000320a:	28e7a783          	lw	a5,654(a5) # 8002b494 <sb+0x1c>
    8000320e:	9dbd                	addw	a1,a1,a5
    80003210:	00000097          	auipc	ra,0x0
    80003214:	d9e080e7          	jalr	-610(ra) # 80002fae <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003218:	0074f713          	andi	a4,s1,7
    8000321c:	4785                	li	a5,1
    8000321e:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003222:	14ce                	slli	s1,s1,0x33
    80003224:	90d9                	srli	s1,s1,0x36
    80003226:	00950733          	add	a4,a0,s1
    8000322a:	05874703          	lbu	a4,88(a4)
    8000322e:	00e7f6b3          	and	a3,a5,a4
    80003232:	c69d                	beqz	a3,80003260 <bfree+0x6c>
    80003234:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003236:	94aa                	add	s1,s1,a0
    80003238:	fff7c793          	not	a5,a5
    8000323c:	8f7d                	and	a4,a4,a5
    8000323e:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003242:	00001097          	auipc	ra,0x1
    80003246:	126080e7          	jalr	294(ra) # 80004368 <log_write>
  brelse(bp);
    8000324a:	854a                	mv	a0,s2
    8000324c:	00000097          	auipc	ra,0x0
    80003250:	e92080e7          	jalr	-366(ra) # 800030de <brelse>
}
    80003254:	60e2                	ld	ra,24(sp)
    80003256:	6442                	ld	s0,16(sp)
    80003258:	64a2                	ld	s1,8(sp)
    8000325a:	6902                	ld	s2,0(sp)
    8000325c:	6105                	addi	sp,sp,32
    8000325e:	8082                	ret
    panic("freeing free block");
    80003260:	00005517          	auipc	a0,0x5
    80003264:	43850513          	addi	a0,a0,1080 # 80008698 <syscalls+0x100>
    80003268:	ffffd097          	auipc	ra,0xffffd
    8000326c:	2d8080e7          	jalr	728(ra) # 80000540 <panic>

0000000080003270 <balloc>:
{
    80003270:	711d                	addi	sp,sp,-96
    80003272:	ec86                	sd	ra,88(sp)
    80003274:	e8a2                	sd	s0,80(sp)
    80003276:	e4a6                	sd	s1,72(sp)
    80003278:	e0ca                	sd	s2,64(sp)
    8000327a:	fc4e                	sd	s3,56(sp)
    8000327c:	f852                	sd	s4,48(sp)
    8000327e:	f456                	sd	s5,40(sp)
    80003280:	f05a                	sd	s6,32(sp)
    80003282:	ec5e                	sd	s7,24(sp)
    80003284:	e862                	sd	s8,16(sp)
    80003286:	e466                	sd	s9,8(sp)
    80003288:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000328a:	00028797          	auipc	a5,0x28
    8000328e:	1f27a783          	lw	a5,498(a5) # 8002b47c <sb+0x4>
    80003292:	cff5                	beqz	a5,8000338e <balloc+0x11e>
    80003294:	8baa                	mv	s7,a0
    80003296:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003298:	00028b17          	auipc	s6,0x28
    8000329c:	1e0b0b13          	addi	s6,s6,480 # 8002b478 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032a0:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800032a2:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032a4:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800032a6:	6c89                	lui	s9,0x2
    800032a8:	a061                	j	80003330 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    800032aa:	97ca                	add	a5,a5,s2
    800032ac:	8e55                	or	a2,a2,a3
    800032ae:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    800032b2:	854a                	mv	a0,s2
    800032b4:	00001097          	auipc	ra,0x1
    800032b8:	0b4080e7          	jalr	180(ra) # 80004368 <log_write>
        brelse(bp);
    800032bc:	854a                	mv	a0,s2
    800032be:	00000097          	auipc	ra,0x0
    800032c2:	e20080e7          	jalr	-480(ra) # 800030de <brelse>
  bp = bread(dev, bno);
    800032c6:	85a6                	mv	a1,s1
    800032c8:	855e                	mv	a0,s7
    800032ca:	00000097          	auipc	ra,0x0
    800032ce:	ce4080e7          	jalr	-796(ra) # 80002fae <bread>
    800032d2:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800032d4:	40000613          	li	a2,1024
    800032d8:	4581                	li	a1,0
    800032da:	05850513          	addi	a0,a0,88
    800032de:	ffffe097          	auipc	ra,0xffffe
    800032e2:	9f4080e7          	jalr	-1548(ra) # 80000cd2 <memset>
  log_write(bp);
    800032e6:	854a                	mv	a0,s2
    800032e8:	00001097          	auipc	ra,0x1
    800032ec:	080080e7          	jalr	128(ra) # 80004368 <log_write>
  brelse(bp);
    800032f0:	854a                	mv	a0,s2
    800032f2:	00000097          	auipc	ra,0x0
    800032f6:	dec080e7          	jalr	-532(ra) # 800030de <brelse>
}
    800032fa:	8526                	mv	a0,s1
    800032fc:	60e6                	ld	ra,88(sp)
    800032fe:	6446                	ld	s0,80(sp)
    80003300:	64a6                	ld	s1,72(sp)
    80003302:	6906                	ld	s2,64(sp)
    80003304:	79e2                	ld	s3,56(sp)
    80003306:	7a42                	ld	s4,48(sp)
    80003308:	7aa2                	ld	s5,40(sp)
    8000330a:	7b02                	ld	s6,32(sp)
    8000330c:	6be2                	ld	s7,24(sp)
    8000330e:	6c42                	ld	s8,16(sp)
    80003310:	6ca2                	ld	s9,8(sp)
    80003312:	6125                	addi	sp,sp,96
    80003314:	8082                	ret
    brelse(bp);
    80003316:	854a                	mv	a0,s2
    80003318:	00000097          	auipc	ra,0x0
    8000331c:	dc6080e7          	jalr	-570(ra) # 800030de <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003320:	015c87bb          	addw	a5,s9,s5
    80003324:	00078a9b          	sext.w	s5,a5
    80003328:	004b2703          	lw	a4,4(s6)
    8000332c:	06eaf163          	bgeu	s5,a4,8000338e <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    80003330:	41fad79b          	sraiw	a5,s5,0x1f
    80003334:	0137d79b          	srliw	a5,a5,0x13
    80003338:	015787bb          	addw	a5,a5,s5
    8000333c:	40d7d79b          	sraiw	a5,a5,0xd
    80003340:	01cb2583          	lw	a1,28(s6)
    80003344:	9dbd                	addw	a1,a1,a5
    80003346:	855e                	mv	a0,s7
    80003348:	00000097          	auipc	ra,0x0
    8000334c:	c66080e7          	jalr	-922(ra) # 80002fae <bread>
    80003350:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003352:	004b2503          	lw	a0,4(s6)
    80003356:	000a849b          	sext.w	s1,s5
    8000335a:	8762                	mv	a4,s8
    8000335c:	faa4fde3          	bgeu	s1,a0,80003316 <balloc+0xa6>
      m = 1 << (bi % 8);
    80003360:	00777693          	andi	a3,a4,7
    80003364:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003368:	41f7579b          	sraiw	a5,a4,0x1f
    8000336c:	01d7d79b          	srliw	a5,a5,0x1d
    80003370:	9fb9                	addw	a5,a5,a4
    80003372:	4037d79b          	sraiw	a5,a5,0x3
    80003376:	00f90633          	add	a2,s2,a5
    8000337a:	05864603          	lbu	a2,88(a2)
    8000337e:	00c6f5b3          	and	a1,a3,a2
    80003382:	d585                	beqz	a1,800032aa <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003384:	2705                	addiw	a4,a4,1
    80003386:	2485                	addiw	s1,s1,1
    80003388:	fd471ae3          	bne	a4,s4,8000335c <balloc+0xec>
    8000338c:	b769                	j	80003316 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    8000338e:	00005517          	auipc	a0,0x5
    80003392:	32250513          	addi	a0,a0,802 # 800086b0 <syscalls+0x118>
    80003396:	ffffd097          	auipc	ra,0xffffd
    8000339a:	1f4080e7          	jalr	500(ra) # 8000058a <printf>
  return 0;
    8000339e:	4481                	li	s1,0
    800033a0:	bfa9                	j	800032fa <balloc+0x8a>

00000000800033a2 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800033a2:	7179                	addi	sp,sp,-48
    800033a4:	f406                	sd	ra,40(sp)
    800033a6:	f022                	sd	s0,32(sp)
    800033a8:	ec26                	sd	s1,24(sp)
    800033aa:	e84a                	sd	s2,16(sp)
    800033ac:	e44e                	sd	s3,8(sp)
    800033ae:	e052                	sd	s4,0(sp)
    800033b0:	1800                	addi	s0,sp,48
    800033b2:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800033b4:	47ad                	li	a5,11
    800033b6:	02b7e863          	bltu	a5,a1,800033e6 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    800033ba:	02059793          	slli	a5,a1,0x20
    800033be:	01e7d593          	srli	a1,a5,0x1e
    800033c2:	00b504b3          	add	s1,a0,a1
    800033c6:	0504a903          	lw	s2,80(s1)
    800033ca:	06091e63          	bnez	s2,80003446 <bmap+0xa4>
      addr = balloc(ip->dev);
    800033ce:	4108                	lw	a0,0(a0)
    800033d0:	00000097          	auipc	ra,0x0
    800033d4:	ea0080e7          	jalr	-352(ra) # 80003270 <balloc>
    800033d8:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800033dc:	06090563          	beqz	s2,80003446 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    800033e0:	0524a823          	sw	s2,80(s1)
    800033e4:	a08d                	j	80003446 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    800033e6:	ff45849b          	addiw	s1,a1,-12
    800033ea:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800033ee:	0ff00793          	li	a5,255
    800033f2:	08e7e563          	bltu	a5,a4,8000347c <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800033f6:	08052903          	lw	s2,128(a0)
    800033fa:	00091d63          	bnez	s2,80003414 <bmap+0x72>
      addr = balloc(ip->dev);
    800033fe:	4108                	lw	a0,0(a0)
    80003400:	00000097          	auipc	ra,0x0
    80003404:	e70080e7          	jalr	-400(ra) # 80003270 <balloc>
    80003408:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000340c:	02090d63          	beqz	s2,80003446 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003410:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003414:	85ca                	mv	a1,s2
    80003416:	0009a503          	lw	a0,0(s3)
    8000341a:	00000097          	auipc	ra,0x0
    8000341e:	b94080e7          	jalr	-1132(ra) # 80002fae <bread>
    80003422:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003424:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003428:	02049713          	slli	a4,s1,0x20
    8000342c:	01e75593          	srli	a1,a4,0x1e
    80003430:	00b784b3          	add	s1,a5,a1
    80003434:	0004a903          	lw	s2,0(s1)
    80003438:	02090063          	beqz	s2,80003458 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    8000343c:	8552                	mv	a0,s4
    8000343e:	00000097          	auipc	ra,0x0
    80003442:	ca0080e7          	jalr	-864(ra) # 800030de <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003446:	854a                	mv	a0,s2
    80003448:	70a2                	ld	ra,40(sp)
    8000344a:	7402                	ld	s0,32(sp)
    8000344c:	64e2                	ld	s1,24(sp)
    8000344e:	6942                	ld	s2,16(sp)
    80003450:	69a2                	ld	s3,8(sp)
    80003452:	6a02                	ld	s4,0(sp)
    80003454:	6145                	addi	sp,sp,48
    80003456:	8082                	ret
      addr = balloc(ip->dev);
    80003458:	0009a503          	lw	a0,0(s3)
    8000345c:	00000097          	auipc	ra,0x0
    80003460:	e14080e7          	jalr	-492(ra) # 80003270 <balloc>
    80003464:	0005091b          	sext.w	s2,a0
      if(addr){
    80003468:	fc090ae3          	beqz	s2,8000343c <bmap+0x9a>
        a[bn] = addr;
    8000346c:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003470:	8552                	mv	a0,s4
    80003472:	00001097          	auipc	ra,0x1
    80003476:	ef6080e7          	jalr	-266(ra) # 80004368 <log_write>
    8000347a:	b7c9                	j	8000343c <bmap+0x9a>
  panic("bmap: out of range");
    8000347c:	00005517          	auipc	a0,0x5
    80003480:	24c50513          	addi	a0,a0,588 # 800086c8 <syscalls+0x130>
    80003484:	ffffd097          	auipc	ra,0xffffd
    80003488:	0bc080e7          	jalr	188(ra) # 80000540 <panic>

000000008000348c <iget>:
{
    8000348c:	7179                	addi	sp,sp,-48
    8000348e:	f406                	sd	ra,40(sp)
    80003490:	f022                	sd	s0,32(sp)
    80003492:	ec26                	sd	s1,24(sp)
    80003494:	e84a                	sd	s2,16(sp)
    80003496:	e44e                	sd	s3,8(sp)
    80003498:	e052                	sd	s4,0(sp)
    8000349a:	1800                	addi	s0,sp,48
    8000349c:	89aa                	mv	s3,a0
    8000349e:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800034a0:	00028517          	auipc	a0,0x28
    800034a4:	ff850513          	addi	a0,a0,-8 # 8002b498 <itable>
    800034a8:	ffffd097          	auipc	ra,0xffffd
    800034ac:	72e080e7          	jalr	1838(ra) # 80000bd6 <acquire>
  empty = 0;
    800034b0:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800034b2:	00028497          	auipc	s1,0x28
    800034b6:	ffe48493          	addi	s1,s1,-2 # 8002b4b0 <itable+0x18>
    800034ba:	0002a697          	auipc	a3,0x2a
    800034be:	a8668693          	addi	a3,a3,-1402 # 8002cf40 <log>
    800034c2:	a039                	j	800034d0 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034c4:	02090b63          	beqz	s2,800034fa <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800034c8:	08848493          	addi	s1,s1,136
    800034cc:	02d48a63          	beq	s1,a3,80003500 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800034d0:	449c                	lw	a5,8(s1)
    800034d2:	fef059e3          	blez	a5,800034c4 <iget+0x38>
    800034d6:	4098                	lw	a4,0(s1)
    800034d8:	ff3716e3          	bne	a4,s3,800034c4 <iget+0x38>
    800034dc:	40d8                	lw	a4,4(s1)
    800034de:	ff4713e3          	bne	a4,s4,800034c4 <iget+0x38>
      ip->ref++;
    800034e2:	2785                	addiw	a5,a5,1
    800034e4:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800034e6:	00028517          	auipc	a0,0x28
    800034ea:	fb250513          	addi	a0,a0,-78 # 8002b498 <itable>
    800034ee:	ffffd097          	auipc	ra,0xffffd
    800034f2:	79c080e7          	jalr	1948(ra) # 80000c8a <release>
      return ip;
    800034f6:	8926                	mv	s2,s1
    800034f8:	a03d                	j	80003526 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034fa:	f7f9                	bnez	a5,800034c8 <iget+0x3c>
    800034fc:	8926                	mv	s2,s1
    800034fe:	b7e9                	j	800034c8 <iget+0x3c>
  if(empty == 0)
    80003500:	02090c63          	beqz	s2,80003538 <iget+0xac>
  ip->dev = dev;
    80003504:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003508:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000350c:	4785                	li	a5,1
    8000350e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003512:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003516:	00028517          	auipc	a0,0x28
    8000351a:	f8250513          	addi	a0,a0,-126 # 8002b498 <itable>
    8000351e:	ffffd097          	auipc	ra,0xffffd
    80003522:	76c080e7          	jalr	1900(ra) # 80000c8a <release>
}
    80003526:	854a                	mv	a0,s2
    80003528:	70a2                	ld	ra,40(sp)
    8000352a:	7402                	ld	s0,32(sp)
    8000352c:	64e2                	ld	s1,24(sp)
    8000352e:	6942                	ld	s2,16(sp)
    80003530:	69a2                	ld	s3,8(sp)
    80003532:	6a02                	ld	s4,0(sp)
    80003534:	6145                	addi	sp,sp,48
    80003536:	8082                	ret
    panic("iget: no inodes");
    80003538:	00005517          	auipc	a0,0x5
    8000353c:	1a850513          	addi	a0,a0,424 # 800086e0 <syscalls+0x148>
    80003540:	ffffd097          	auipc	ra,0xffffd
    80003544:	000080e7          	jalr	ra # 80000540 <panic>

0000000080003548 <fsinit>:
fsinit(int dev) {
    80003548:	7179                	addi	sp,sp,-48
    8000354a:	f406                	sd	ra,40(sp)
    8000354c:	f022                	sd	s0,32(sp)
    8000354e:	ec26                	sd	s1,24(sp)
    80003550:	e84a                	sd	s2,16(sp)
    80003552:	e44e                	sd	s3,8(sp)
    80003554:	1800                	addi	s0,sp,48
    80003556:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003558:	4585                	li	a1,1
    8000355a:	00000097          	auipc	ra,0x0
    8000355e:	a54080e7          	jalr	-1452(ra) # 80002fae <bread>
    80003562:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003564:	00028997          	auipc	s3,0x28
    80003568:	f1498993          	addi	s3,s3,-236 # 8002b478 <sb>
    8000356c:	02000613          	li	a2,32
    80003570:	05850593          	addi	a1,a0,88
    80003574:	854e                	mv	a0,s3
    80003576:	ffffd097          	auipc	ra,0xffffd
    8000357a:	7b8080e7          	jalr	1976(ra) # 80000d2e <memmove>
  brelse(bp);
    8000357e:	8526                	mv	a0,s1
    80003580:	00000097          	auipc	ra,0x0
    80003584:	b5e080e7          	jalr	-1186(ra) # 800030de <brelse>
  if(sb.magic != FSMAGIC)
    80003588:	0009a703          	lw	a4,0(s3)
    8000358c:	102037b7          	lui	a5,0x10203
    80003590:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003594:	02f71263          	bne	a4,a5,800035b8 <fsinit+0x70>
  initlog(dev, &sb);
    80003598:	00028597          	auipc	a1,0x28
    8000359c:	ee058593          	addi	a1,a1,-288 # 8002b478 <sb>
    800035a0:	854a                	mv	a0,s2
    800035a2:	00001097          	auipc	ra,0x1
    800035a6:	b4a080e7          	jalr	-1206(ra) # 800040ec <initlog>
}
    800035aa:	70a2                	ld	ra,40(sp)
    800035ac:	7402                	ld	s0,32(sp)
    800035ae:	64e2                	ld	s1,24(sp)
    800035b0:	6942                	ld	s2,16(sp)
    800035b2:	69a2                	ld	s3,8(sp)
    800035b4:	6145                	addi	sp,sp,48
    800035b6:	8082                	ret
    panic("invalid file system");
    800035b8:	00005517          	auipc	a0,0x5
    800035bc:	13850513          	addi	a0,a0,312 # 800086f0 <syscalls+0x158>
    800035c0:	ffffd097          	auipc	ra,0xffffd
    800035c4:	f80080e7          	jalr	-128(ra) # 80000540 <panic>

00000000800035c8 <iinit>:
{
    800035c8:	7179                	addi	sp,sp,-48
    800035ca:	f406                	sd	ra,40(sp)
    800035cc:	f022                	sd	s0,32(sp)
    800035ce:	ec26                	sd	s1,24(sp)
    800035d0:	e84a                	sd	s2,16(sp)
    800035d2:	e44e                	sd	s3,8(sp)
    800035d4:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800035d6:	00005597          	auipc	a1,0x5
    800035da:	13258593          	addi	a1,a1,306 # 80008708 <syscalls+0x170>
    800035de:	00028517          	auipc	a0,0x28
    800035e2:	eba50513          	addi	a0,a0,-326 # 8002b498 <itable>
    800035e6:	ffffd097          	auipc	ra,0xffffd
    800035ea:	560080e7          	jalr	1376(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    800035ee:	00028497          	auipc	s1,0x28
    800035f2:	ed248493          	addi	s1,s1,-302 # 8002b4c0 <itable+0x28>
    800035f6:	0002a997          	auipc	s3,0x2a
    800035fa:	95a98993          	addi	s3,s3,-1702 # 8002cf50 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800035fe:	00005917          	auipc	s2,0x5
    80003602:	11290913          	addi	s2,s2,274 # 80008710 <syscalls+0x178>
    80003606:	85ca                	mv	a1,s2
    80003608:	8526                	mv	a0,s1
    8000360a:	00001097          	auipc	ra,0x1
    8000360e:	e42080e7          	jalr	-446(ra) # 8000444c <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003612:	08848493          	addi	s1,s1,136
    80003616:	ff3498e3          	bne	s1,s3,80003606 <iinit+0x3e>
}
    8000361a:	70a2                	ld	ra,40(sp)
    8000361c:	7402                	ld	s0,32(sp)
    8000361e:	64e2                	ld	s1,24(sp)
    80003620:	6942                	ld	s2,16(sp)
    80003622:	69a2                	ld	s3,8(sp)
    80003624:	6145                	addi	sp,sp,48
    80003626:	8082                	ret

0000000080003628 <ialloc>:
{
    80003628:	715d                	addi	sp,sp,-80
    8000362a:	e486                	sd	ra,72(sp)
    8000362c:	e0a2                	sd	s0,64(sp)
    8000362e:	fc26                	sd	s1,56(sp)
    80003630:	f84a                	sd	s2,48(sp)
    80003632:	f44e                	sd	s3,40(sp)
    80003634:	f052                	sd	s4,32(sp)
    80003636:	ec56                	sd	s5,24(sp)
    80003638:	e85a                	sd	s6,16(sp)
    8000363a:	e45e                	sd	s7,8(sp)
    8000363c:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000363e:	00028717          	auipc	a4,0x28
    80003642:	e4672703          	lw	a4,-442(a4) # 8002b484 <sb+0xc>
    80003646:	4785                	li	a5,1
    80003648:	04e7fa63          	bgeu	a5,a4,8000369c <ialloc+0x74>
    8000364c:	8aaa                	mv	s5,a0
    8000364e:	8bae                	mv	s7,a1
    80003650:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003652:	00028a17          	auipc	s4,0x28
    80003656:	e26a0a13          	addi	s4,s4,-474 # 8002b478 <sb>
    8000365a:	00048b1b          	sext.w	s6,s1
    8000365e:	0044d593          	srli	a1,s1,0x4
    80003662:	018a2783          	lw	a5,24(s4)
    80003666:	9dbd                	addw	a1,a1,a5
    80003668:	8556                	mv	a0,s5
    8000366a:	00000097          	auipc	ra,0x0
    8000366e:	944080e7          	jalr	-1724(ra) # 80002fae <bread>
    80003672:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003674:	05850993          	addi	s3,a0,88
    80003678:	00f4f793          	andi	a5,s1,15
    8000367c:	079a                	slli	a5,a5,0x6
    8000367e:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003680:	00099783          	lh	a5,0(s3)
    80003684:	c3a1                	beqz	a5,800036c4 <ialloc+0x9c>
    brelse(bp);
    80003686:	00000097          	auipc	ra,0x0
    8000368a:	a58080e7          	jalr	-1448(ra) # 800030de <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000368e:	0485                	addi	s1,s1,1
    80003690:	00ca2703          	lw	a4,12(s4)
    80003694:	0004879b          	sext.w	a5,s1
    80003698:	fce7e1e3          	bltu	a5,a4,8000365a <ialloc+0x32>
  printf("ialloc: no inodes\n");
    8000369c:	00005517          	auipc	a0,0x5
    800036a0:	07c50513          	addi	a0,a0,124 # 80008718 <syscalls+0x180>
    800036a4:	ffffd097          	auipc	ra,0xffffd
    800036a8:	ee6080e7          	jalr	-282(ra) # 8000058a <printf>
  return 0;
    800036ac:	4501                	li	a0,0
}
    800036ae:	60a6                	ld	ra,72(sp)
    800036b0:	6406                	ld	s0,64(sp)
    800036b2:	74e2                	ld	s1,56(sp)
    800036b4:	7942                	ld	s2,48(sp)
    800036b6:	79a2                	ld	s3,40(sp)
    800036b8:	7a02                	ld	s4,32(sp)
    800036ba:	6ae2                	ld	s5,24(sp)
    800036bc:	6b42                	ld	s6,16(sp)
    800036be:	6ba2                	ld	s7,8(sp)
    800036c0:	6161                	addi	sp,sp,80
    800036c2:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800036c4:	04000613          	li	a2,64
    800036c8:	4581                	li	a1,0
    800036ca:	854e                	mv	a0,s3
    800036cc:	ffffd097          	auipc	ra,0xffffd
    800036d0:	606080e7          	jalr	1542(ra) # 80000cd2 <memset>
      dip->type = type;
    800036d4:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800036d8:	854a                	mv	a0,s2
    800036da:	00001097          	auipc	ra,0x1
    800036de:	c8e080e7          	jalr	-882(ra) # 80004368 <log_write>
      brelse(bp);
    800036e2:	854a                	mv	a0,s2
    800036e4:	00000097          	auipc	ra,0x0
    800036e8:	9fa080e7          	jalr	-1542(ra) # 800030de <brelse>
      return iget(dev, inum);
    800036ec:	85da                	mv	a1,s6
    800036ee:	8556                	mv	a0,s5
    800036f0:	00000097          	auipc	ra,0x0
    800036f4:	d9c080e7          	jalr	-612(ra) # 8000348c <iget>
    800036f8:	bf5d                	j	800036ae <ialloc+0x86>

00000000800036fa <iupdate>:
{
    800036fa:	1101                	addi	sp,sp,-32
    800036fc:	ec06                	sd	ra,24(sp)
    800036fe:	e822                	sd	s0,16(sp)
    80003700:	e426                	sd	s1,8(sp)
    80003702:	e04a                	sd	s2,0(sp)
    80003704:	1000                	addi	s0,sp,32
    80003706:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003708:	415c                	lw	a5,4(a0)
    8000370a:	0047d79b          	srliw	a5,a5,0x4
    8000370e:	00028597          	auipc	a1,0x28
    80003712:	d825a583          	lw	a1,-638(a1) # 8002b490 <sb+0x18>
    80003716:	9dbd                	addw	a1,a1,a5
    80003718:	4108                	lw	a0,0(a0)
    8000371a:	00000097          	auipc	ra,0x0
    8000371e:	894080e7          	jalr	-1900(ra) # 80002fae <bread>
    80003722:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003724:	05850793          	addi	a5,a0,88
    80003728:	40d8                	lw	a4,4(s1)
    8000372a:	8b3d                	andi	a4,a4,15
    8000372c:	071a                	slli	a4,a4,0x6
    8000372e:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003730:	04449703          	lh	a4,68(s1)
    80003734:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003738:	04649703          	lh	a4,70(s1)
    8000373c:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003740:	04849703          	lh	a4,72(s1)
    80003744:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003748:	04a49703          	lh	a4,74(s1)
    8000374c:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003750:	44f8                	lw	a4,76(s1)
    80003752:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003754:	03400613          	li	a2,52
    80003758:	05048593          	addi	a1,s1,80
    8000375c:	00c78513          	addi	a0,a5,12
    80003760:	ffffd097          	auipc	ra,0xffffd
    80003764:	5ce080e7          	jalr	1486(ra) # 80000d2e <memmove>
  log_write(bp);
    80003768:	854a                	mv	a0,s2
    8000376a:	00001097          	auipc	ra,0x1
    8000376e:	bfe080e7          	jalr	-1026(ra) # 80004368 <log_write>
  brelse(bp);
    80003772:	854a                	mv	a0,s2
    80003774:	00000097          	auipc	ra,0x0
    80003778:	96a080e7          	jalr	-1686(ra) # 800030de <brelse>
}
    8000377c:	60e2                	ld	ra,24(sp)
    8000377e:	6442                	ld	s0,16(sp)
    80003780:	64a2                	ld	s1,8(sp)
    80003782:	6902                	ld	s2,0(sp)
    80003784:	6105                	addi	sp,sp,32
    80003786:	8082                	ret

0000000080003788 <idup>:
{
    80003788:	1101                	addi	sp,sp,-32
    8000378a:	ec06                	sd	ra,24(sp)
    8000378c:	e822                	sd	s0,16(sp)
    8000378e:	e426                	sd	s1,8(sp)
    80003790:	1000                	addi	s0,sp,32
    80003792:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003794:	00028517          	auipc	a0,0x28
    80003798:	d0450513          	addi	a0,a0,-764 # 8002b498 <itable>
    8000379c:	ffffd097          	auipc	ra,0xffffd
    800037a0:	43a080e7          	jalr	1082(ra) # 80000bd6 <acquire>
  ip->ref++;
    800037a4:	449c                	lw	a5,8(s1)
    800037a6:	2785                	addiw	a5,a5,1
    800037a8:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800037aa:	00028517          	auipc	a0,0x28
    800037ae:	cee50513          	addi	a0,a0,-786 # 8002b498 <itable>
    800037b2:	ffffd097          	auipc	ra,0xffffd
    800037b6:	4d8080e7          	jalr	1240(ra) # 80000c8a <release>
}
    800037ba:	8526                	mv	a0,s1
    800037bc:	60e2                	ld	ra,24(sp)
    800037be:	6442                	ld	s0,16(sp)
    800037c0:	64a2                	ld	s1,8(sp)
    800037c2:	6105                	addi	sp,sp,32
    800037c4:	8082                	ret

00000000800037c6 <ilock>:
{
    800037c6:	1101                	addi	sp,sp,-32
    800037c8:	ec06                	sd	ra,24(sp)
    800037ca:	e822                	sd	s0,16(sp)
    800037cc:	e426                	sd	s1,8(sp)
    800037ce:	e04a                	sd	s2,0(sp)
    800037d0:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800037d2:	c115                	beqz	a0,800037f6 <ilock+0x30>
    800037d4:	84aa                	mv	s1,a0
    800037d6:	451c                	lw	a5,8(a0)
    800037d8:	00f05f63          	blez	a5,800037f6 <ilock+0x30>
  acquiresleep(&ip->lock);
    800037dc:	0541                	addi	a0,a0,16
    800037de:	00001097          	auipc	ra,0x1
    800037e2:	ca8080e7          	jalr	-856(ra) # 80004486 <acquiresleep>
  if(ip->valid == 0){
    800037e6:	40bc                	lw	a5,64(s1)
    800037e8:	cf99                	beqz	a5,80003806 <ilock+0x40>
}
    800037ea:	60e2                	ld	ra,24(sp)
    800037ec:	6442                	ld	s0,16(sp)
    800037ee:	64a2                	ld	s1,8(sp)
    800037f0:	6902                	ld	s2,0(sp)
    800037f2:	6105                	addi	sp,sp,32
    800037f4:	8082                	ret
    panic("ilock");
    800037f6:	00005517          	auipc	a0,0x5
    800037fa:	f3a50513          	addi	a0,a0,-198 # 80008730 <syscalls+0x198>
    800037fe:	ffffd097          	auipc	ra,0xffffd
    80003802:	d42080e7          	jalr	-702(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003806:	40dc                	lw	a5,4(s1)
    80003808:	0047d79b          	srliw	a5,a5,0x4
    8000380c:	00028597          	auipc	a1,0x28
    80003810:	c845a583          	lw	a1,-892(a1) # 8002b490 <sb+0x18>
    80003814:	9dbd                	addw	a1,a1,a5
    80003816:	4088                	lw	a0,0(s1)
    80003818:	fffff097          	auipc	ra,0xfffff
    8000381c:	796080e7          	jalr	1942(ra) # 80002fae <bread>
    80003820:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003822:	05850593          	addi	a1,a0,88
    80003826:	40dc                	lw	a5,4(s1)
    80003828:	8bbd                	andi	a5,a5,15
    8000382a:	079a                	slli	a5,a5,0x6
    8000382c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000382e:	00059783          	lh	a5,0(a1)
    80003832:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003836:	00259783          	lh	a5,2(a1)
    8000383a:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000383e:	00459783          	lh	a5,4(a1)
    80003842:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003846:	00659783          	lh	a5,6(a1)
    8000384a:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000384e:	459c                	lw	a5,8(a1)
    80003850:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003852:	03400613          	li	a2,52
    80003856:	05b1                	addi	a1,a1,12
    80003858:	05048513          	addi	a0,s1,80
    8000385c:	ffffd097          	auipc	ra,0xffffd
    80003860:	4d2080e7          	jalr	1234(ra) # 80000d2e <memmove>
    brelse(bp);
    80003864:	854a                	mv	a0,s2
    80003866:	00000097          	auipc	ra,0x0
    8000386a:	878080e7          	jalr	-1928(ra) # 800030de <brelse>
    ip->valid = 1;
    8000386e:	4785                	li	a5,1
    80003870:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003872:	04449783          	lh	a5,68(s1)
    80003876:	fbb5                	bnez	a5,800037ea <ilock+0x24>
      panic("ilock: no type");
    80003878:	00005517          	auipc	a0,0x5
    8000387c:	ec050513          	addi	a0,a0,-320 # 80008738 <syscalls+0x1a0>
    80003880:	ffffd097          	auipc	ra,0xffffd
    80003884:	cc0080e7          	jalr	-832(ra) # 80000540 <panic>

0000000080003888 <iunlock>:
{
    80003888:	1101                	addi	sp,sp,-32
    8000388a:	ec06                	sd	ra,24(sp)
    8000388c:	e822                	sd	s0,16(sp)
    8000388e:	e426                	sd	s1,8(sp)
    80003890:	e04a                	sd	s2,0(sp)
    80003892:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003894:	c905                	beqz	a0,800038c4 <iunlock+0x3c>
    80003896:	84aa                	mv	s1,a0
    80003898:	01050913          	addi	s2,a0,16
    8000389c:	854a                	mv	a0,s2
    8000389e:	00001097          	auipc	ra,0x1
    800038a2:	c82080e7          	jalr	-894(ra) # 80004520 <holdingsleep>
    800038a6:	cd19                	beqz	a0,800038c4 <iunlock+0x3c>
    800038a8:	449c                	lw	a5,8(s1)
    800038aa:	00f05d63          	blez	a5,800038c4 <iunlock+0x3c>
  releasesleep(&ip->lock);
    800038ae:	854a                	mv	a0,s2
    800038b0:	00001097          	auipc	ra,0x1
    800038b4:	c2c080e7          	jalr	-980(ra) # 800044dc <releasesleep>
}
    800038b8:	60e2                	ld	ra,24(sp)
    800038ba:	6442                	ld	s0,16(sp)
    800038bc:	64a2                	ld	s1,8(sp)
    800038be:	6902                	ld	s2,0(sp)
    800038c0:	6105                	addi	sp,sp,32
    800038c2:	8082                	ret
    panic("iunlock");
    800038c4:	00005517          	auipc	a0,0x5
    800038c8:	e8450513          	addi	a0,a0,-380 # 80008748 <syscalls+0x1b0>
    800038cc:	ffffd097          	auipc	ra,0xffffd
    800038d0:	c74080e7          	jalr	-908(ra) # 80000540 <panic>

00000000800038d4 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800038d4:	7179                	addi	sp,sp,-48
    800038d6:	f406                	sd	ra,40(sp)
    800038d8:	f022                	sd	s0,32(sp)
    800038da:	ec26                	sd	s1,24(sp)
    800038dc:	e84a                	sd	s2,16(sp)
    800038de:	e44e                	sd	s3,8(sp)
    800038e0:	e052                	sd	s4,0(sp)
    800038e2:	1800                	addi	s0,sp,48
    800038e4:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800038e6:	05050493          	addi	s1,a0,80
    800038ea:	08050913          	addi	s2,a0,128
    800038ee:	a021                	j	800038f6 <itrunc+0x22>
    800038f0:	0491                	addi	s1,s1,4
    800038f2:	01248d63          	beq	s1,s2,8000390c <itrunc+0x38>
    if(ip->addrs[i]){
    800038f6:	408c                	lw	a1,0(s1)
    800038f8:	dde5                	beqz	a1,800038f0 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800038fa:	0009a503          	lw	a0,0(s3)
    800038fe:	00000097          	auipc	ra,0x0
    80003902:	8f6080e7          	jalr	-1802(ra) # 800031f4 <bfree>
      ip->addrs[i] = 0;
    80003906:	0004a023          	sw	zero,0(s1)
    8000390a:	b7dd                	j	800038f0 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000390c:	0809a583          	lw	a1,128(s3)
    80003910:	e185                	bnez	a1,80003930 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003912:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003916:	854e                	mv	a0,s3
    80003918:	00000097          	auipc	ra,0x0
    8000391c:	de2080e7          	jalr	-542(ra) # 800036fa <iupdate>
}
    80003920:	70a2                	ld	ra,40(sp)
    80003922:	7402                	ld	s0,32(sp)
    80003924:	64e2                	ld	s1,24(sp)
    80003926:	6942                	ld	s2,16(sp)
    80003928:	69a2                	ld	s3,8(sp)
    8000392a:	6a02                	ld	s4,0(sp)
    8000392c:	6145                	addi	sp,sp,48
    8000392e:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003930:	0009a503          	lw	a0,0(s3)
    80003934:	fffff097          	auipc	ra,0xfffff
    80003938:	67a080e7          	jalr	1658(ra) # 80002fae <bread>
    8000393c:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000393e:	05850493          	addi	s1,a0,88
    80003942:	45850913          	addi	s2,a0,1112
    80003946:	a021                	j	8000394e <itrunc+0x7a>
    80003948:	0491                	addi	s1,s1,4
    8000394a:	01248b63          	beq	s1,s2,80003960 <itrunc+0x8c>
      if(a[j])
    8000394e:	408c                	lw	a1,0(s1)
    80003950:	dde5                	beqz	a1,80003948 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003952:	0009a503          	lw	a0,0(s3)
    80003956:	00000097          	auipc	ra,0x0
    8000395a:	89e080e7          	jalr	-1890(ra) # 800031f4 <bfree>
    8000395e:	b7ed                	j	80003948 <itrunc+0x74>
    brelse(bp);
    80003960:	8552                	mv	a0,s4
    80003962:	fffff097          	auipc	ra,0xfffff
    80003966:	77c080e7          	jalr	1916(ra) # 800030de <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000396a:	0809a583          	lw	a1,128(s3)
    8000396e:	0009a503          	lw	a0,0(s3)
    80003972:	00000097          	auipc	ra,0x0
    80003976:	882080e7          	jalr	-1918(ra) # 800031f4 <bfree>
    ip->addrs[NDIRECT] = 0;
    8000397a:	0809a023          	sw	zero,128(s3)
    8000397e:	bf51                	j	80003912 <itrunc+0x3e>

0000000080003980 <iput>:
{
    80003980:	1101                	addi	sp,sp,-32
    80003982:	ec06                	sd	ra,24(sp)
    80003984:	e822                	sd	s0,16(sp)
    80003986:	e426                	sd	s1,8(sp)
    80003988:	e04a                	sd	s2,0(sp)
    8000398a:	1000                	addi	s0,sp,32
    8000398c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000398e:	00028517          	auipc	a0,0x28
    80003992:	b0a50513          	addi	a0,a0,-1270 # 8002b498 <itable>
    80003996:	ffffd097          	auipc	ra,0xffffd
    8000399a:	240080e7          	jalr	576(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000399e:	4498                	lw	a4,8(s1)
    800039a0:	4785                	li	a5,1
    800039a2:	02f70363          	beq	a4,a5,800039c8 <iput+0x48>
  ip->ref--;
    800039a6:	449c                	lw	a5,8(s1)
    800039a8:	37fd                	addiw	a5,a5,-1
    800039aa:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800039ac:	00028517          	auipc	a0,0x28
    800039b0:	aec50513          	addi	a0,a0,-1300 # 8002b498 <itable>
    800039b4:	ffffd097          	auipc	ra,0xffffd
    800039b8:	2d6080e7          	jalr	726(ra) # 80000c8a <release>
}
    800039bc:	60e2                	ld	ra,24(sp)
    800039be:	6442                	ld	s0,16(sp)
    800039c0:	64a2                	ld	s1,8(sp)
    800039c2:	6902                	ld	s2,0(sp)
    800039c4:	6105                	addi	sp,sp,32
    800039c6:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039c8:	40bc                	lw	a5,64(s1)
    800039ca:	dff1                	beqz	a5,800039a6 <iput+0x26>
    800039cc:	04a49783          	lh	a5,74(s1)
    800039d0:	fbf9                	bnez	a5,800039a6 <iput+0x26>
    acquiresleep(&ip->lock);
    800039d2:	01048913          	addi	s2,s1,16
    800039d6:	854a                	mv	a0,s2
    800039d8:	00001097          	auipc	ra,0x1
    800039dc:	aae080e7          	jalr	-1362(ra) # 80004486 <acquiresleep>
    release(&itable.lock);
    800039e0:	00028517          	auipc	a0,0x28
    800039e4:	ab850513          	addi	a0,a0,-1352 # 8002b498 <itable>
    800039e8:	ffffd097          	auipc	ra,0xffffd
    800039ec:	2a2080e7          	jalr	674(ra) # 80000c8a <release>
    itrunc(ip);
    800039f0:	8526                	mv	a0,s1
    800039f2:	00000097          	auipc	ra,0x0
    800039f6:	ee2080e7          	jalr	-286(ra) # 800038d4 <itrunc>
    ip->type = 0;
    800039fa:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800039fe:	8526                	mv	a0,s1
    80003a00:	00000097          	auipc	ra,0x0
    80003a04:	cfa080e7          	jalr	-774(ra) # 800036fa <iupdate>
    ip->valid = 0;
    80003a08:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003a0c:	854a                	mv	a0,s2
    80003a0e:	00001097          	auipc	ra,0x1
    80003a12:	ace080e7          	jalr	-1330(ra) # 800044dc <releasesleep>
    acquire(&itable.lock);
    80003a16:	00028517          	auipc	a0,0x28
    80003a1a:	a8250513          	addi	a0,a0,-1406 # 8002b498 <itable>
    80003a1e:	ffffd097          	auipc	ra,0xffffd
    80003a22:	1b8080e7          	jalr	440(ra) # 80000bd6 <acquire>
    80003a26:	b741                	j	800039a6 <iput+0x26>

0000000080003a28 <iunlockput>:
{
    80003a28:	1101                	addi	sp,sp,-32
    80003a2a:	ec06                	sd	ra,24(sp)
    80003a2c:	e822                	sd	s0,16(sp)
    80003a2e:	e426                	sd	s1,8(sp)
    80003a30:	1000                	addi	s0,sp,32
    80003a32:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a34:	00000097          	auipc	ra,0x0
    80003a38:	e54080e7          	jalr	-428(ra) # 80003888 <iunlock>
  iput(ip);
    80003a3c:	8526                	mv	a0,s1
    80003a3e:	00000097          	auipc	ra,0x0
    80003a42:	f42080e7          	jalr	-190(ra) # 80003980 <iput>
}
    80003a46:	60e2                	ld	ra,24(sp)
    80003a48:	6442                	ld	s0,16(sp)
    80003a4a:	64a2                	ld	s1,8(sp)
    80003a4c:	6105                	addi	sp,sp,32
    80003a4e:	8082                	ret

0000000080003a50 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a50:	1141                	addi	sp,sp,-16
    80003a52:	e422                	sd	s0,8(sp)
    80003a54:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a56:	411c                	lw	a5,0(a0)
    80003a58:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a5a:	415c                	lw	a5,4(a0)
    80003a5c:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a5e:	04451783          	lh	a5,68(a0)
    80003a62:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a66:	04a51783          	lh	a5,74(a0)
    80003a6a:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a6e:	04c56783          	lwu	a5,76(a0)
    80003a72:	e99c                	sd	a5,16(a1)
}
    80003a74:	6422                	ld	s0,8(sp)
    80003a76:	0141                	addi	sp,sp,16
    80003a78:	8082                	ret

0000000080003a7a <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a7a:	457c                	lw	a5,76(a0)
    80003a7c:	0ed7e963          	bltu	a5,a3,80003b6e <readi+0xf4>
{
    80003a80:	7159                	addi	sp,sp,-112
    80003a82:	f486                	sd	ra,104(sp)
    80003a84:	f0a2                	sd	s0,96(sp)
    80003a86:	eca6                	sd	s1,88(sp)
    80003a88:	e8ca                	sd	s2,80(sp)
    80003a8a:	e4ce                	sd	s3,72(sp)
    80003a8c:	e0d2                	sd	s4,64(sp)
    80003a8e:	fc56                	sd	s5,56(sp)
    80003a90:	f85a                	sd	s6,48(sp)
    80003a92:	f45e                	sd	s7,40(sp)
    80003a94:	f062                	sd	s8,32(sp)
    80003a96:	ec66                	sd	s9,24(sp)
    80003a98:	e86a                	sd	s10,16(sp)
    80003a9a:	e46e                	sd	s11,8(sp)
    80003a9c:	1880                	addi	s0,sp,112
    80003a9e:	8b2a                	mv	s6,a0
    80003aa0:	8bae                	mv	s7,a1
    80003aa2:	8a32                	mv	s4,a2
    80003aa4:	84b6                	mv	s1,a3
    80003aa6:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003aa8:	9f35                	addw	a4,a4,a3
    return 0;
    80003aaa:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003aac:	0ad76063          	bltu	a4,a3,80003b4c <readi+0xd2>
  if(off + n > ip->size)
    80003ab0:	00e7f463          	bgeu	a5,a4,80003ab8 <readi+0x3e>
    n = ip->size - off;
    80003ab4:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ab8:	0a0a8963          	beqz	s5,80003b6a <readi+0xf0>
    80003abc:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003abe:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003ac2:	5c7d                	li	s8,-1
    80003ac4:	a82d                	j	80003afe <readi+0x84>
    80003ac6:	020d1d93          	slli	s11,s10,0x20
    80003aca:	020ddd93          	srli	s11,s11,0x20
    80003ace:	05890613          	addi	a2,s2,88
    80003ad2:	86ee                	mv	a3,s11
    80003ad4:	963a                	add	a2,a2,a4
    80003ad6:	85d2                	mv	a1,s4
    80003ad8:	855e                	mv	a0,s7
    80003ada:	fffff097          	auipc	ra,0xfffff
    80003ade:	9e6080e7          	jalr	-1562(ra) # 800024c0 <either_copyout>
    80003ae2:	05850d63          	beq	a0,s8,80003b3c <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003ae6:	854a                	mv	a0,s2
    80003ae8:	fffff097          	auipc	ra,0xfffff
    80003aec:	5f6080e7          	jalr	1526(ra) # 800030de <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003af0:	013d09bb          	addw	s3,s10,s3
    80003af4:	009d04bb          	addw	s1,s10,s1
    80003af8:	9a6e                	add	s4,s4,s11
    80003afa:	0559f763          	bgeu	s3,s5,80003b48 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003afe:	00a4d59b          	srliw	a1,s1,0xa
    80003b02:	855a                	mv	a0,s6
    80003b04:	00000097          	auipc	ra,0x0
    80003b08:	89e080e7          	jalr	-1890(ra) # 800033a2 <bmap>
    80003b0c:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003b10:	cd85                	beqz	a1,80003b48 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003b12:	000b2503          	lw	a0,0(s6)
    80003b16:	fffff097          	auipc	ra,0xfffff
    80003b1a:	498080e7          	jalr	1176(ra) # 80002fae <bread>
    80003b1e:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b20:	3ff4f713          	andi	a4,s1,1023
    80003b24:	40ec87bb          	subw	a5,s9,a4
    80003b28:	413a86bb          	subw	a3,s5,s3
    80003b2c:	8d3e                	mv	s10,a5
    80003b2e:	2781                	sext.w	a5,a5
    80003b30:	0006861b          	sext.w	a2,a3
    80003b34:	f8f679e3          	bgeu	a2,a5,80003ac6 <readi+0x4c>
    80003b38:	8d36                	mv	s10,a3
    80003b3a:	b771                	j	80003ac6 <readi+0x4c>
      brelse(bp);
    80003b3c:	854a                	mv	a0,s2
    80003b3e:	fffff097          	auipc	ra,0xfffff
    80003b42:	5a0080e7          	jalr	1440(ra) # 800030de <brelse>
      tot = -1;
    80003b46:	59fd                	li	s3,-1
  }
  return tot;
    80003b48:	0009851b          	sext.w	a0,s3
}
    80003b4c:	70a6                	ld	ra,104(sp)
    80003b4e:	7406                	ld	s0,96(sp)
    80003b50:	64e6                	ld	s1,88(sp)
    80003b52:	6946                	ld	s2,80(sp)
    80003b54:	69a6                	ld	s3,72(sp)
    80003b56:	6a06                	ld	s4,64(sp)
    80003b58:	7ae2                	ld	s5,56(sp)
    80003b5a:	7b42                	ld	s6,48(sp)
    80003b5c:	7ba2                	ld	s7,40(sp)
    80003b5e:	7c02                	ld	s8,32(sp)
    80003b60:	6ce2                	ld	s9,24(sp)
    80003b62:	6d42                	ld	s10,16(sp)
    80003b64:	6da2                	ld	s11,8(sp)
    80003b66:	6165                	addi	sp,sp,112
    80003b68:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b6a:	89d6                	mv	s3,s5
    80003b6c:	bff1                	j	80003b48 <readi+0xce>
    return 0;
    80003b6e:	4501                	li	a0,0
}
    80003b70:	8082                	ret

0000000080003b72 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b72:	457c                	lw	a5,76(a0)
    80003b74:	10d7e863          	bltu	a5,a3,80003c84 <writei+0x112>
{
    80003b78:	7159                	addi	sp,sp,-112
    80003b7a:	f486                	sd	ra,104(sp)
    80003b7c:	f0a2                	sd	s0,96(sp)
    80003b7e:	eca6                	sd	s1,88(sp)
    80003b80:	e8ca                	sd	s2,80(sp)
    80003b82:	e4ce                	sd	s3,72(sp)
    80003b84:	e0d2                	sd	s4,64(sp)
    80003b86:	fc56                	sd	s5,56(sp)
    80003b88:	f85a                	sd	s6,48(sp)
    80003b8a:	f45e                	sd	s7,40(sp)
    80003b8c:	f062                	sd	s8,32(sp)
    80003b8e:	ec66                	sd	s9,24(sp)
    80003b90:	e86a                	sd	s10,16(sp)
    80003b92:	e46e                	sd	s11,8(sp)
    80003b94:	1880                	addi	s0,sp,112
    80003b96:	8aaa                	mv	s5,a0
    80003b98:	8bae                	mv	s7,a1
    80003b9a:	8a32                	mv	s4,a2
    80003b9c:	8936                	mv	s2,a3
    80003b9e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003ba0:	00e687bb          	addw	a5,a3,a4
    80003ba4:	0ed7e263          	bltu	a5,a3,80003c88 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003ba8:	00043737          	lui	a4,0x43
    80003bac:	0ef76063          	bltu	a4,a5,80003c8c <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bb0:	0c0b0863          	beqz	s6,80003c80 <writei+0x10e>
    80003bb4:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bb6:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003bba:	5c7d                	li	s8,-1
    80003bbc:	a091                	j	80003c00 <writei+0x8e>
    80003bbe:	020d1d93          	slli	s11,s10,0x20
    80003bc2:	020ddd93          	srli	s11,s11,0x20
    80003bc6:	05848513          	addi	a0,s1,88
    80003bca:	86ee                	mv	a3,s11
    80003bcc:	8652                	mv	a2,s4
    80003bce:	85de                	mv	a1,s7
    80003bd0:	953a                	add	a0,a0,a4
    80003bd2:	fffff097          	auipc	ra,0xfffff
    80003bd6:	944080e7          	jalr	-1724(ra) # 80002516 <either_copyin>
    80003bda:	07850263          	beq	a0,s8,80003c3e <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003bde:	8526                	mv	a0,s1
    80003be0:	00000097          	auipc	ra,0x0
    80003be4:	788080e7          	jalr	1928(ra) # 80004368 <log_write>
    brelse(bp);
    80003be8:	8526                	mv	a0,s1
    80003bea:	fffff097          	auipc	ra,0xfffff
    80003bee:	4f4080e7          	jalr	1268(ra) # 800030de <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bf2:	013d09bb          	addw	s3,s10,s3
    80003bf6:	012d093b          	addw	s2,s10,s2
    80003bfa:	9a6e                	add	s4,s4,s11
    80003bfc:	0569f663          	bgeu	s3,s6,80003c48 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003c00:	00a9559b          	srliw	a1,s2,0xa
    80003c04:	8556                	mv	a0,s5
    80003c06:	fffff097          	auipc	ra,0xfffff
    80003c0a:	79c080e7          	jalr	1948(ra) # 800033a2 <bmap>
    80003c0e:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003c12:	c99d                	beqz	a1,80003c48 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003c14:	000aa503          	lw	a0,0(s5)
    80003c18:	fffff097          	auipc	ra,0xfffff
    80003c1c:	396080e7          	jalr	918(ra) # 80002fae <bread>
    80003c20:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c22:	3ff97713          	andi	a4,s2,1023
    80003c26:	40ec87bb          	subw	a5,s9,a4
    80003c2a:	413b06bb          	subw	a3,s6,s3
    80003c2e:	8d3e                	mv	s10,a5
    80003c30:	2781                	sext.w	a5,a5
    80003c32:	0006861b          	sext.w	a2,a3
    80003c36:	f8f674e3          	bgeu	a2,a5,80003bbe <writei+0x4c>
    80003c3a:	8d36                	mv	s10,a3
    80003c3c:	b749                	j	80003bbe <writei+0x4c>
      brelse(bp);
    80003c3e:	8526                	mv	a0,s1
    80003c40:	fffff097          	auipc	ra,0xfffff
    80003c44:	49e080e7          	jalr	1182(ra) # 800030de <brelse>
  }

  if(off > ip->size)
    80003c48:	04caa783          	lw	a5,76(s5)
    80003c4c:	0127f463          	bgeu	a5,s2,80003c54 <writei+0xe2>
    ip->size = off;
    80003c50:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003c54:	8556                	mv	a0,s5
    80003c56:	00000097          	auipc	ra,0x0
    80003c5a:	aa4080e7          	jalr	-1372(ra) # 800036fa <iupdate>

  return tot;
    80003c5e:	0009851b          	sext.w	a0,s3
}
    80003c62:	70a6                	ld	ra,104(sp)
    80003c64:	7406                	ld	s0,96(sp)
    80003c66:	64e6                	ld	s1,88(sp)
    80003c68:	6946                	ld	s2,80(sp)
    80003c6a:	69a6                	ld	s3,72(sp)
    80003c6c:	6a06                	ld	s4,64(sp)
    80003c6e:	7ae2                	ld	s5,56(sp)
    80003c70:	7b42                	ld	s6,48(sp)
    80003c72:	7ba2                	ld	s7,40(sp)
    80003c74:	7c02                	ld	s8,32(sp)
    80003c76:	6ce2                	ld	s9,24(sp)
    80003c78:	6d42                	ld	s10,16(sp)
    80003c7a:	6da2                	ld	s11,8(sp)
    80003c7c:	6165                	addi	sp,sp,112
    80003c7e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c80:	89da                	mv	s3,s6
    80003c82:	bfc9                	j	80003c54 <writei+0xe2>
    return -1;
    80003c84:	557d                	li	a0,-1
}
    80003c86:	8082                	ret
    return -1;
    80003c88:	557d                	li	a0,-1
    80003c8a:	bfe1                	j	80003c62 <writei+0xf0>
    return -1;
    80003c8c:	557d                	li	a0,-1
    80003c8e:	bfd1                	j	80003c62 <writei+0xf0>

0000000080003c90 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c90:	1141                	addi	sp,sp,-16
    80003c92:	e406                	sd	ra,8(sp)
    80003c94:	e022                	sd	s0,0(sp)
    80003c96:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c98:	4639                	li	a2,14
    80003c9a:	ffffd097          	auipc	ra,0xffffd
    80003c9e:	108080e7          	jalr	264(ra) # 80000da2 <strncmp>
}
    80003ca2:	60a2                	ld	ra,8(sp)
    80003ca4:	6402                	ld	s0,0(sp)
    80003ca6:	0141                	addi	sp,sp,16
    80003ca8:	8082                	ret

0000000080003caa <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003caa:	7139                	addi	sp,sp,-64
    80003cac:	fc06                	sd	ra,56(sp)
    80003cae:	f822                	sd	s0,48(sp)
    80003cb0:	f426                	sd	s1,40(sp)
    80003cb2:	f04a                	sd	s2,32(sp)
    80003cb4:	ec4e                	sd	s3,24(sp)
    80003cb6:	e852                	sd	s4,16(sp)
    80003cb8:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003cba:	04451703          	lh	a4,68(a0)
    80003cbe:	4785                	li	a5,1
    80003cc0:	00f71a63          	bne	a4,a5,80003cd4 <dirlookup+0x2a>
    80003cc4:	892a                	mv	s2,a0
    80003cc6:	89ae                	mv	s3,a1
    80003cc8:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cca:	457c                	lw	a5,76(a0)
    80003ccc:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003cce:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cd0:	e79d                	bnez	a5,80003cfe <dirlookup+0x54>
    80003cd2:	a8a5                	j	80003d4a <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003cd4:	00005517          	auipc	a0,0x5
    80003cd8:	a7c50513          	addi	a0,a0,-1412 # 80008750 <syscalls+0x1b8>
    80003cdc:	ffffd097          	auipc	ra,0xffffd
    80003ce0:	864080e7          	jalr	-1948(ra) # 80000540 <panic>
      panic("dirlookup read");
    80003ce4:	00005517          	auipc	a0,0x5
    80003ce8:	a8450513          	addi	a0,a0,-1404 # 80008768 <syscalls+0x1d0>
    80003cec:	ffffd097          	auipc	ra,0xffffd
    80003cf0:	854080e7          	jalr	-1964(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cf4:	24c1                	addiw	s1,s1,16
    80003cf6:	04c92783          	lw	a5,76(s2)
    80003cfa:	04f4f763          	bgeu	s1,a5,80003d48 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003cfe:	4741                	li	a4,16
    80003d00:	86a6                	mv	a3,s1
    80003d02:	fc040613          	addi	a2,s0,-64
    80003d06:	4581                	li	a1,0
    80003d08:	854a                	mv	a0,s2
    80003d0a:	00000097          	auipc	ra,0x0
    80003d0e:	d70080e7          	jalr	-656(ra) # 80003a7a <readi>
    80003d12:	47c1                	li	a5,16
    80003d14:	fcf518e3          	bne	a0,a5,80003ce4 <dirlookup+0x3a>
    if(de.inum == 0)
    80003d18:	fc045783          	lhu	a5,-64(s0)
    80003d1c:	dfe1                	beqz	a5,80003cf4 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d1e:	fc240593          	addi	a1,s0,-62
    80003d22:	854e                	mv	a0,s3
    80003d24:	00000097          	auipc	ra,0x0
    80003d28:	f6c080e7          	jalr	-148(ra) # 80003c90 <namecmp>
    80003d2c:	f561                	bnez	a0,80003cf4 <dirlookup+0x4a>
      if(poff)
    80003d2e:	000a0463          	beqz	s4,80003d36 <dirlookup+0x8c>
        *poff = off;
    80003d32:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003d36:	fc045583          	lhu	a1,-64(s0)
    80003d3a:	00092503          	lw	a0,0(s2)
    80003d3e:	fffff097          	auipc	ra,0xfffff
    80003d42:	74e080e7          	jalr	1870(ra) # 8000348c <iget>
    80003d46:	a011                	j	80003d4a <dirlookup+0xa0>
  return 0;
    80003d48:	4501                	li	a0,0
}
    80003d4a:	70e2                	ld	ra,56(sp)
    80003d4c:	7442                	ld	s0,48(sp)
    80003d4e:	74a2                	ld	s1,40(sp)
    80003d50:	7902                	ld	s2,32(sp)
    80003d52:	69e2                	ld	s3,24(sp)
    80003d54:	6a42                	ld	s4,16(sp)
    80003d56:	6121                	addi	sp,sp,64
    80003d58:	8082                	ret

0000000080003d5a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d5a:	711d                	addi	sp,sp,-96
    80003d5c:	ec86                	sd	ra,88(sp)
    80003d5e:	e8a2                	sd	s0,80(sp)
    80003d60:	e4a6                	sd	s1,72(sp)
    80003d62:	e0ca                	sd	s2,64(sp)
    80003d64:	fc4e                	sd	s3,56(sp)
    80003d66:	f852                	sd	s4,48(sp)
    80003d68:	f456                	sd	s5,40(sp)
    80003d6a:	f05a                	sd	s6,32(sp)
    80003d6c:	ec5e                	sd	s7,24(sp)
    80003d6e:	e862                	sd	s8,16(sp)
    80003d70:	e466                	sd	s9,8(sp)
    80003d72:	e06a                	sd	s10,0(sp)
    80003d74:	1080                	addi	s0,sp,96
    80003d76:	84aa                	mv	s1,a0
    80003d78:	8b2e                	mv	s6,a1
    80003d7a:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d7c:	00054703          	lbu	a4,0(a0)
    80003d80:	02f00793          	li	a5,47
    80003d84:	02f70363          	beq	a4,a5,80003daa <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d88:	ffffe097          	auipc	ra,0xffffe
    80003d8c:	c24080e7          	jalr	-988(ra) # 800019ac <myproc>
    80003d90:	15053503          	ld	a0,336(a0)
    80003d94:	00000097          	auipc	ra,0x0
    80003d98:	9f4080e7          	jalr	-1548(ra) # 80003788 <idup>
    80003d9c:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003d9e:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003da2:	4cb5                	li	s9,13
  len = path - s;
    80003da4:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003da6:	4c05                	li	s8,1
    80003da8:	a87d                	j	80003e66 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80003daa:	4585                	li	a1,1
    80003dac:	4505                	li	a0,1
    80003dae:	fffff097          	auipc	ra,0xfffff
    80003db2:	6de080e7          	jalr	1758(ra) # 8000348c <iget>
    80003db6:	8a2a                	mv	s4,a0
    80003db8:	b7dd                	j	80003d9e <namex+0x44>
      iunlockput(ip);
    80003dba:	8552                	mv	a0,s4
    80003dbc:	00000097          	auipc	ra,0x0
    80003dc0:	c6c080e7          	jalr	-916(ra) # 80003a28 <iunlockput>
      return 0;
    80003dc4:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003dc6:	8552                	mv	a0,s4
    80003dc8:	60e6                	ld	ra,88(sp)
    80003dca:	6446                	ld	s0,80(sp)
    80003dcc:	64a6                	ld	s1,72(sp)
    80003dce:	6906                	ld	s2,64(sp)
    80003dd0:	79e2                	ld	s3,56(sp)
    80003dd2:	7a42                	ld	s4,48(sp)
    80003dd4:	7aa2                	ld	s5,40(sp)
    80003dd6:	7b02                	ld	s6,32(sp)
    80003dd8:	6be2                	ld	s7,24(sp)
    80003dda:	6c42                	ld	s8,16(sp)
    80003ddc:	6ca2                	ld	s9,8(sp)
    80003dde:	6d02                	ld	s10,0(sp)
    80003de0:	6125                	addi	sp,sp,96
    80003de2:	8082                	ret
      iunlock(ip);
    80003de4:	8552                	mv	a0,s4
    80003de6:	00000097          	auipc	ra,0x0
    80003dea:	aa2080e7          	jalr	-1374(ra) # 80003888 <iunlock>
      return ip;
    80003dee:	bfe1                	j	80003dc6 <namex+0x6c>
      iunlockput(ip);
    80003df0:	8552                	mv	a0,s4
    80003df2:	00000097          	auipc	ra,0x0
    80003df6:	c36080e7          	jalr	-970(ra) # 80003a28 <iunlockput>
      return 0;
    80003dfa:	8a4e                	mv	s4,s3
    80003dfc:	b7e9                	j	80003dc6 <namex+0x6c>
  len = path - s;
    80003dfe:	40998633          	sub	a2,s3,s1
    80003e02:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80003e06:	09acd863          	bge	s9,s10,80003e96 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80003e0a:	4639                	li	a2,14
    80003e0c:	85a6                	mv	a1,s1
    80003e0e:	8556                	mv	a0,s5
    80003e10:	ffffd097          	auipc	ra,0xffffd
    80003e14:	f1e080e7          	jalr	-226(ra) # 80000d2e <memmove>
    80003e18:	84ce                	mv	s1,s3
  while(*path == '/')
    80003e1a:	0004c783          	lbu	a5,0(s1)
    80003e1e:	01279763          	bne	a5,s2,80003e2c <namex+0xd2>
    path++;
    80003e22:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e24:	0004c783          	lbu	a5,0(s1)
    80003e28:	ff278de3          	beq	a5,s2,80003e22 <namex+0xc8>
    ilock(ip);
    80003e2c:	8552                	mv	a0,s4
    80003e2e:	00000097          	auipc	ra,0x0
    80003e32:	998080e7          	jalr	-1640(ra) # 800037c6 <ilock>
    if(ip->type != T_DIR){
    80003e36:	044a1783          	lh	a5,68(s4)
    80003e3a:	f98790e3          	bne	a5,s8,80003dba <namex+0x60>
    if(nameiparent && *path == '\0'){
    80003e3e:	000b0563          	beqz	s6,80003e48 <namex+0xee>
    80003e42:	0004c783          	lbu	a5,0(s1)
    80003e46:	dfd9                	beqz	a5,80003de4 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e48:	865e                	mv	a2,s7
    80003e4a:	85d6                	mv	a1,s5
    80003e4c:	8552                	mv	a0,s4
    80003e4e:	00000097          	auipc	ra,0x0
    80003e52:	e5c080e7          	jalr	-420(ra) # 80003caa <dirlookup>
    80003e56:	89aa                	mv	s3,a0
    80003e58:	dd41                	beqz	a0,80003df0 <namex+0x96>
    iunlockput(ip);
    80003e5a:	8552                	mv	a0,s4
    80003e5c:	00000097          	auipc	ra,0x0
    80003e60:	bcc080e7          	jalr	-1076(ra) # 80003a28 <iunlockput>
    ip = next;
    80003e64:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003e66:	0004c783          	lbu	a5,0(s1)
    80003e6a:	01279763          	bne	a5,s2,80003e78 <namex+0x11e>
    path++;
    80003e6e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e70:	0004c783          	lbu	a5,0(s1)
    80003e74:	ff278de3          	beq	a5,s2,80003e6e <namex+0x114>
  if(*path == 0)
    80003e78:	cb9d                	beqz	a5,80003eae <namex+0x154>
  while(*path != '/' && *path != 0)
    80003e7a:	0004c783          	lbu	a5,0(s1)
    80003e7e:	89a6                	mv	s3,s1
  len = path - s;
    80003e80:	8d5e                	mv	s10,s7
    80003e82:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003e84:	01278963          	beq	a5,s2,80003e96 <namex+0x13c>
    80003e88:	dbbd                	beqz	a5,80003dfe <namex+0xa4>
    path++;
    80003e8a:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003e8c:	0009c783          	lbu	a5,0(s3)
    80003e90:	ff279ce3          	bne	a5,s2,80003e88 <namex+0x12e>
    80003e94:	b7ad                	j	80003dfe <namex+0xa4>
    memmove(name, s, len);
    80003e96:	2601                	sext.w	a2,a2
    80003e98:	85a6                	mv	a1,s1
    80003e9a:	8556                	mv	a0,s5
    80003e9c:	ffffd097          	auipc	ra,0xffffd
    80003ea0:	e92080e7          	jalr	-366(ra) # 80000d2e <memmove>
    name[len] = 0;
    80003ea4:	9d56                	add	s10,s10,s5
    80003ea6:	000d0023          	sb	zero,0(s10)
    80003eaa:	84ce                	mv	s1,s3
    80003eac:	b7bd                	j	80003e1a <namex+0xc0>
  if(nameiparent){
    80003eae:	f00b0ce3          	beqz	s6,80003dc6 <namex+0x6c>
    iput(ip);
    80003eb2:	8552                	mv	a0,s4
    80003eb4:	00000097          	auipc	ra,0x0
    80003eb8:	acc080e7          	jalr	-1332(ra) # 80003980 <iput>
    return 0;
    80003ebc:	4a01                	li	s4,0
    80003ebe:	b721                	j	80003dc6 <namex+0x6c>

0000000080003ec0 <dirlink>:
{
    80003ec0:	7139                	addi	sp,sp,-64
    80003ec2:	fc06                	sd	ra,56(sp)
    80003ec4:	f822                	sd	s0,48(sp)
    80003ec6:	f426                	sd	s1,40(sp)
    80003ec8:	f04a                	sd	s2,32(sp)
    80003eca:	ec4e                	sd	s3,24(sp)
    80003ecc:	e852                	sd	s4,16(sp)
    80003ece:	0080                	addi	s0,sp,64
    80003ed0:	892a                	mv	s2,a0
    80003ed2:	8a2e                	mv	s4,a1
    80003ed4:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003ed6:	4601                	li	a2,0
    80003ed8:	00000097          	auipc	ra,0x0
    80003edc:	dd2080e7          	jalr	-558(ra) # 80003caa <dirlookup>
    80003ee0:	e93d                	bnez	a0,80003f56 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ee2:	04c92483          	lw	s1,76(s2)
    80003ee6:	c49d                	beqz	s1,80003f14 <dirlink+0x54>
    80003ee8:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003eea:	4741                	li	a4,16
    80003eec:	86a6                	mv	a3,s1
    80003eee:	fc040613          	addi	a2,s0,-64
    80003ef2:	4581                	li	a1,0
    80003ef4:	854a                	mv	a0,s2
    80003ef6:	00000097          	auipc	ra,0x0
    80003efa:	b84080e7          	jalr	-1148(ra) # 80003a7a <readi>
    80003efe:	47c1                	li	a5,16
    80003f00:	06f51163          	bne	a0,a5,80003f62 <dirlink+0xa2>
    if(de.inum == 0)
    80003f04:	fc045783          	lhu	a5,-64(s0)
    80003f08:	c791                	beqz	a5,80003f14 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f0a:	24c1                	addiw	s1,s1,16
    80003f0c:	04c92783          	lw	a5,76(s2)
    80003f10:	fcf4ede3          	bltu	s1,a5,80003eea <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003f14:	4639                	li	a2,14
    80003f16:	85d2                	mv	a1,s4
    80003f18:	fc240513          	addi	a0,s0,-62
    80003f1c:	ffffd097          	auipc	ra,0xffffd
    80003f20:	ec2080e7          	jalr	-318(ra) # 80000dde <strncpy>
  de.inum = inum;
    80003f24:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f28:	4741                	li	a4,16
    80003f2a:	86a6                	mv	a3,s1
    80003f2c:	fc040613          	addi	a2,s0,-64
    80003f30:	4581                	li	a1,0
    80003f32:	854a                	mv	a0,s2
    80003f34:	00000097          	auipc	ra,0x0
    80003f38:	c3e080e7          	jalr	-962(ra) # 80003b72 <writei>
    80003f3c:	1541                	addi	a0,a0,-16
    80003f3e:	00a03533          	snez	a0,a0
    80003f42:	40a00533          	neg	a0,a0
}
    80003f46:	70e2                	ld	ra,56(sp)
    80003f48:	7442                	ld	s0,48(sp)
    80003f4a:	74a2                	ld	s1,40(sp)
    80003f4c:	7902                	ld	s2,32(sp)
    80003f4e:	69e2                	ld	s3,24(sp)
    80003f50:	6a42                	ld	s4,16(sp)
    80003f52:	6121                	addi	sp,sp,64
    80003f54:	8082                	ret
    iput(ip);
    80003f56:	00000097          	auipc	ra,0x0
    80003f5a:	a2a080e7          	jalr	-1494(ra) # 80003980 <iput>
    return -1;
    80003f5e:	557d                	li	a0,-1
    80003f60:	b7dd                	j	80003f46 <dirlink+0x86>
      panic("dirlink read");
    80003f62:	00005517          	auipc	a0,0x5
    80003f66:	81650513          	addi	a0,a0,-2026 # 80008778 <syscalls+0x1e0>
    80003f6a:	ffffc097          	auipc	ra,0xffffc
    80003f6e:	5d6080e7          	jalr	1494(ra) # 80000540 <panic>

0000000080003f72 <namei>:

struct inode*
namei(char *path)
{
    80003f72:	1101                	addi	sp,sp,-32
    80003f74:	ec06                	sd	ra,24(sp)
    80003f76:	e822                	sd	s0,16(sp)
    80003f78:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f7a:	fe040613          	addi	a2,s0,-32
    80003f7e:	4581                	li	a1,0
    80003f80:	00000097          	auipc	ra,0x0
    80003f84:	dda080e7          	jalr	-550(ra) # 80003d5a <namex>
}
    80003f88:	60e2                	ld	ra,24(sp)
    80003f8a:	6442                	ld	s0,16(sp)
    80003f8c:	6105                	addi	sp,sp,32
    80003f8e:	8082                	ret

0000000080003f90 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f90:	1141                	addi	sp,sp,-16
    80003f92:	e406                	sd	ra,8(sp)
    80003f94:	e022                	sd	s0,0(sp)
    80003f96:	0800                	addi	s0,sp,16
    80003f98:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f9a:	4585                	li	a1,1
    80003f9c:	00000097          	auipc	ra,0x0
    80003fa0:	dbe080e7          	jalr	-578(ra) # 80003d5a <namex>
}
    80003fa4:	60a2                	ld	ra,8(sp)
    80003fa6:	6402                	ld	s0,0(sp)
    80003fa8:	0141                	addi	sp,sp,16
    80003faa:	8082                	ret

0000000080003fac <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003fac:	1101                	addi	sp,sp,-32
    80003fae:	ec06                	sd	ra,24(sp)
    80003fb0:	e822                	sd	s0,16(sp)
    80003fb2:	e426                	sd	s1,8(sp)
    80003fb4:	e04a                	sd	s2,0(sp)
    80003fb6:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003fb8:	00029917          	auipc	s2,0x29
    80003fbc:	f8890913          	addi	s2,s2,-120 # 8002cf40 <log>
    80003fc0:	01892583          	lw	a1,24(s2)
    80003fc4:	02892503          	lw	a0,40(s2)
    80003fc8:	fffff097          	auipc	ra,0xfffff
    80003fcc:	fe6080e7          	jalr	-26(ra) # 80002fae <bread>
    80003fd0:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003fd2:	02c92683          	lw	a3,44(s2)
    80003fd6:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003fd8:	02d05863          	blez	a3,80004008 <write_head+0x5c>
    80003fdc:	00029797          	auipc	a5,0x29
    80003fe0:	f9478793          	addi	a5,a5,-108 # 8002cf70 <log+0x30>
    80003fe4:	05c50713          	addi	a4,a0,92
    80003fe8:	36fd                	addiw	a3,a3,-1
    80003fea:	02069613          	slli	a2,a3,0x20
    80003fee:	01e65693          	srli	a3,a2,0x1e
    80003ff2:	00029617          	auipc	a2,0x29
    80003ff6:	f8260613          	addi	a2,a2,-126 # 8002cf74 <log+0x34>
    80003ffa:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003ffc:	4390                	lw	a2,0(a5)
    80003ffe:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004000:	0791                	addi	a5,a5,4
    80004002:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80004004:	fed79ce3          	bne	a5,a3,80003ffc <write_head+0x50>
  }
  bwrite(buf);
    80004008:	8526                	mv	a0,s1
    8000400a:	fffff097          	auipc	ra,0xfffff
    8000400e:	096080e7          	jalr	150(ra) # 800030a0 <bwrite>
  brelse(buf);
    80004012:	8526                	mv	a0,s1
    80004014:	fffff097          	auipc	ra,0xfffff
    80004018:	0ca080e7          	jalr	202(ra) # 800030de <brelse>
}
    8000401c:	60e2                	ld	ra,24(sp)
    8000401e:	6442                	ld	s0,16(sp)
    80004020:	64a2                	ld	s1,8(sp)
    80004022:	6902                	ld	s2,0(sp)
    80004024:	6105                	addi	sp,sp,32
    80004026:	8082                	ret

0000000080004028 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004028:	00029797          	auipc	a5,0x29
    8000402c:	f447a783          	lw	a5,-188(a5) # 8002cf6c <log+0x2c>
    80004030:	0af05d63          	blez	a5,800040ea <install_trans+0xc2>
{
    80004034:	7139                	addi	sp,sp,-64
    80004036:	fc06                	sd	ra,56(sp)
    80004038:	f822                	sd	s0,48(sp)
    8000403a:	f426                	sd	s1,40(sp)
    8000403c:	f04a                	sd	s2,32(sp)
    8000403e:	ec4e                	sd	s3,24(sp)
    80004040:	e852                	sd	s4,16(sp)
    80004042:	e456                	sd	s5,8(sp)
    80004044:	e05a                	sd	s6,0(sp)
    80004046:	0080                	addi	s0,sp,64
    80004048:	8b2a                	mv	s6,a0
    8000404a:	00029a97          	auipc	s5,0x29
    8000404e:	f26a8a93          	addi	s5,s5,-218 # 8002cf70 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004052:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004054:	00029997          	auipc	s3,0x29
    80004058:	eec98993          	addi	s3,s3,-276 # 8002cf40 <log>
    8000405c:	a00d                	j	8000407e <install_trans+0x56>
    brelse(lbuf);
    8000405e:	854a                	mv	a0,s2
    80004060:	fffff097          	auipc	ra,0xfffff
    80004064:	07e080e7          	jalr	126(ra) # 800030de <brelse>
    brelse(dbuf);
    80004068:	8526                	mv	a0,s1
    8000406a:	fffff097          	auipc	ra,0xfffff
    8000406e:	074080e7          	jalr	116(ra) # 800030de <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004072:	2a05                	addiw	s4,s4,1
    80004074:	0a91                	addi	s5,s5,4
    80004076:	02c9a783          	lw	a5,44(s3)
    8000407a:	04fa5e63          	bge	s4,a5,800040d6 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000407e:	0189a583          	lw	a1,24(s3)
    80004082:	014585bb          	addw	a1,a1,s4
    80004086:	2585                	addiw	a1,a1,1
    80004088:	0289a503          	lw	a0,40(s3)
    8000408c:	fffff097          	auipc	ra,0xfffff
    80004090:	f22080e7          	jalr	-222(ra) # 80002fae <bread>
    80004094:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004096:	000aa583          	lw	a1,0(s5)
    8000409a:	0289a503          	lw	a0,40(s3)
    8000409e:	fffff097          	auipc	ra,0xfffff
    800040a2:	f10080e7          	jalr	-240(ra) # 80002fae <bread>
    800040a6:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800040a8:	40000613          	li	a2,1024
    800040ac:	05890593          	addi	a1,s2,88
    800040b0:	05850513          	addi	a0,a0,88
    800040b4:	ffffd097          	auipc	ra,0xffffd
    800040b8:	c7a080e7          	jalr	-902(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    800040bc:	8526                	mv	a0,s1
    800040be:	fffff097          	auipc	ra,0xfffff
    800040c2:	fe2080e7          	jalr	-30(ra) # 800030a0 <bwrite>
    if(recovering == 0)
    800040c6:	f80b1ce3          	bnez	s6,8000405e <install_trans+0x36>
      bunpin(dbuf);
    800040ca:	8526                	mv	a0,s1
    800040cc:	fffff097          	auipc	ra,0xfffff
    800040d0:	0ec080e7          	jalr	236(ra) # 800031b8 <bunpin>
    800040d4:	b769                	j	8000405e <install_trans+0x36>
}
    800040d6:	70e2                	ld	ra,56(sp)
    800040d8:	7442                	ld	s0,48(sp)
    800040da:	74a2                	ld	s1,40(sp)
    800040dc:	7902                	ld	s2,32(sp)
    800040de:	69e2                	ld	s3,24(sp)
    800040e0:	6a42                	ld	s4,16(sp)
    800040e2:	6aa2                	ld	s5,8(sp)
    800040e4:	6b02                	ld	s6,0(sp)
    800040e6:	6121                	addi	sp,sp,64
    800040e8:	8082                	ret
    800040ea:	8082                	ret

00000000800040ec <initlog>:
{
    800040ec:	7179                	addi	sp,sp,-48
    800040ee:	f406                	sd	ra,40(sp)
    800040f0:	f022                	sd	s0,32(sp)
    800040f2:	ec26                	sd	s1,24(sp)
    800040f4:	e84a                	sd	s2,16(sp)
    800040f6:	e44e                	sd	s3,8(sp)
    800040f8:	1800                	addi	s0,sp,48
    800040fa:	892a                	mv	s2,a0
    800040fc:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800040fe:	00029497          	auipc	s1,0x29
    80004102:	e4248493          	addi	s1,s1,-446 # 8002cf40 <log>
    80004106:	00004597          	auipc	a1,0x4
    8000410a:	68258593          	addi	a1,a1,1666 # 80008788 <syscalls+0x1f0>
    8000410e:	8526                	mv	a0,s1
    80004110:	ffffd097          	auipc	ra,0xffffd
    80004114:	a36080e7          	jalr	-1482(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    80004118:	0149a583          	lw	a1,20(s3)
    8000411c:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000411e:	0109a783          	lw	a5,16(s3)
    80004122:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004124:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004128:	854a                	mv	a0,s2
    8000412a:	fffff097          	auipc	ra,0xfffff
    8000412e:	e84080e7          	jalr	-380(ra) # 80002fae <bread>
  log.lh.n = lh->n;
    80004132:	4d34                	lw	a3,88(a0)
    80004134:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004136:	02d05663          	blez	a3,80004162 <initlog+0x76>
    8000413a:	05c50793          	addi	a5,a0,92
    8000413e:	00029717          	auipc	a4,0x29
    80004142:	e3270713          	addi	a4,a4,-462 # 8002cf70 <log+0x30>
    80004146:	36fd                	addiw	a3,a3,-1
    80004148:	02069613          	slli	a2,a3,0x20
    8000414c:	01e65693          	srli	a3,a2,0x1e
    80004150:	06050613          	addi	a2,a0,96
    80004154:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004156:	4390                	lw	a2,0(a5)
    80004158:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000415a:	0791                	addi	a5,a5,4
    8000415c:	0711                	addi	a4,a4,4
    8000415e:	fed79ce3          	bne	a5,a3,80004156 <initlog+0x6a>
  brelse(buf);
    80004162:	fffff097          	auipc	ra,0xfffff
    80004166:	f7c080e7          	jalr	-132(ra) # 800030de <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000416a:	4505                	li	a0,1
    8000416c:	00000097          	auipc	ra,0x0
    80004170:	ebc080e7          	jalr	-324(ra) # 80004028 <install_trans>
  log.lh.n = 0;
    80004174:	00029797          	auipc	a5,0x29
    80004178:	de07ac23          	sw	zero,-520(a5) # 8002cf6c <log+0x2c>
  write_head(); // clear the log
    8000417c:	00000097          	auipc	ra,0x0
    80004180:	e30080e7          	jalr	-464(ra) # 80003fac <write_head>
}
    80004184:	70a2                	ld	ra,40(sp)
    80004186:	7402                	ld	s0,32(sp)
    80004188:	64e2                	ld	s1,24(sp)
    8000418a:	6942                	ld	s2,16(sp)
    8000418c:	69a2                	ld	s3,8(sp)
    8000418e:	6145                	addi	sp,sp,48
    80004190:	8082                	ret

0000000080004192 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004192:	1101                	addi	sp,sp,-32
    80004194:	ec06                	sd	ra,24(sp)
    80004196:	e822                	sd	s0,16(sp)
    80004198:	e426                	sd	s1,8(sp)
    8000419a:	e04a                	sd	s2,0(sp)
    8000419c:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000419e:	00029517          	auipc	a0,0x29
    800041a2:	da250513          	addi	a0,a0,-606 # 8002cf40 <log>
    800041a6:	ffffd097          	auipc	ra,0xffffd
    800041aa:	a30080e7          	jalr	-1488(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    800041ae:	00029497          	auipc	s1,0x29
    800041b2:	d9248493          	addi	s1,s1,-622 # 8002cf40 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041b6:	4979                	li	s2,30
    800041b8:	a039                	j	800041c6 <begin_op+0x34>
      sleep(&log, &log.lock);
    800041ba:	85a6                	mv	a1,s1
    800041bc:	8526                	mv	a0,s1
    800041be:	ffffe097          	auipc	ra,0xffffe
    800041c2:	efa080e7          	jalr	-262(ra) # 800020b8 <sleep>
    if(log.committing){
    800041c6:	50dc                	lw	a5,36(s1)
    800041c8:	fbed                	bnez	a5,800041ba <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041ca:	5098                	lw	a4,32(s1)
    800041cc:	2705                	addiw	a4,a4,1
    800041ce:	0007069b          	sext.w	a3,a4
    800041d2:	0027179b          	slliw	a5,a4,0x2
    800041d6:	9fb9                	addw	a5,a5,a4
    800041d8:	0017979b          	slliw	a5,a5,0x1
    800041dc:	54d8                	lw	a4,44(s1)
    800041de:	9fb9                	addw	a5,a5,a4
    800041e0:	00f95963          	bge	s2,a5,800041f2 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800041e4:	85a6                	mv	a1,s1
    800041e6:	8526                	mv	a0,s1
    800041e8:	ffffe097          	auipc	ra,0xffffe
    800041ec:	ed0080e7          	jalr	-304(ra) # 800020b8 <sleep>
    800041f0:	bfd9                	j	800041c6 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800041f2:	00029517          	auipc	a0,0x29
    800041f6:	d4e50513          	addi	a0,a0,-690 # 8002cf40 <log>
    800041fa:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800041fc:	ffffd097          	auipc	ra,0xffffd
    80004200:	a8e080e7          	jalr	-1394(ra) # 80000c8a <release>
      break;
    }
  }
}
    80004204:	60e2                	ld	ra,24(sp)
    80004206:	6442                	ld	s0,16(sp)
    80004208:	64a2                	ld	s1,8(sp)
    8000420a:	6902                	ld	s2,0(sp)
    8000420c:	6105                	addi	sp,sp,32
    8000420e:	8082                	ret

0000000080004210 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004210:	7139                	addi	sp,sp,-64
    80004212:	fc06                	sd	ra,56(sp)
    80004214:	f822                	sd	s0,48(sp)
    80004216:	f426                	sd	s1,40(sp)
    80004218:	f04a                	sd	s2,32(sp)
    8000421a:	ec4e                	sd	s3,24(sp)
    8000421c:	e852                	sd	s4,16(sp)
    8000421e:	e456                	sd	s5,8(sp)
    80004220:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004222:	00029497          	auipc	s1,0x29
    80004226:	d1e48493          	addi	s1,s1,-738 # 8002cf40 <log>
    8000422a:	8526                	mv	a0,s1
    8000422c:	ffffd097          	auipc	ra,0xffffd
    80004230:	9aa080e7          	jalr	-1622(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    80004234:	509c                	lw	a5,32(s1)
    80004236:	37fd                	addiw	a5,a5,-1
    80004238:	0007891b          	sext.w	s2,a5
    8000423c:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000423e:	50dc                	lw	a5,36(s1)
    80004240:	e7b9                	bnez	a5,8000428e <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004242:	04091e63          	bnez	s2,8000429e <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004246:	00029497          	auipc	s1,0x29
    8000424a:	cfa48493          	addi	s1,s1,-774 # 8002cf40 <log>
    8000424e:	4785                	li	a5,1
    80004250:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004252:	8526                	mv	a0,s1
    80004254:	ffffd097          	auipc	ra,0xffffd
    80004258:	a36080e7          	jalr	-1482(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000425c:	54dc                	lw	a5,44(s1)
    8000425e:	06f04763          	bgtz	a5,800042cc <end_op+0xbc>
    acquire(&log.lock);
    80004262:	00029497          	auipc	s1,0x29
    80004266:	cde48493          	addi	s1,s1,-802 # 8002cf40 <log>
    8000426a:	8526                	mv	a0,s1
    8000426c:	ffffd097          	auipc	ra,0xffffd
    80004270:	96a080e7          	jalr	-1686(ra) # 80000bd6 <acquire>
    log.committing = 0;
    80004274:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004278:	8526                	mv	a0,s1
    8000427a:	ffffe097          	auipc	ra,0xffffe
    8000427e:	ea2080e7          	jalr	-350(ra) # 8000211c <wakeup>
    release(&log.lock);
    80004282:	8526                	mv	a0,s1
    80004284:	ffffd097          	auipc	ra,0xffffd
    80004288:	a06080e7          	jalr	-1530(ra) # 80000c8a <release>
}
    8000428c:	a03d                	j	800042ba <end_op+0xaa>
    panic("log.committing");
    8000428e:	00004517          	auipc	a0,0x4
    80004292:	50250513          	addi	a0,a0,1282 # 80008790 <syscalls+0x1f8>
    80004296:	ffffc097          	auipc	ra,0xffffc
    8000429a:	2aa080e7          	jalr	682(ra) # 80000540 <panic>
    wakeup(&log);
    8000429e:	00029497          	auipc	s1,0x29
    800042a2:	ca248493          	addi	s1,s1,-862 # 8002cf40 <log>
    800042a6:	8526                	mv	a0,s1
    800042a8:	ffffe097          	auipc	ra,0xffffe
    800042ac:	e74080e7          	jalr	-396(ra) # 8000211c <wakeup>
  release(&log.lock);
    800042b0:	8526                	mv	a0,s1
    800042b2:	ffffd097          	auipc	ra,0xffffd
    800042b6:	9d8080e7          	jalr	-1576(ra) # 80000c8a <release>
}
    800042ba:	70e2                	ld	ra,56(sp)
    800042bc:	7442                	ld	s0,48(sp)
    800042be:	74a2                	ld	s1,40(sp)
    800042c0:	7902                	ld	s2,32(sp)
    800042c2:	69e2                	ld	s3,24(sp)
    800042c4:	6a42                	ld	s4,16(sp)
    800042c6:	6aa2                	ld	s5,8(sp)
    800042c8:	6121                	addi	sp,sp,64
    800042ca:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800042cc:	00029a97          	auipc	s5,0x29
    800042d0:	ca4a8a93          	addi	s5,s5,-860 # 8002cf70 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800042d4:	00029a17          	auipc	s4,0x29
    800042d8:	c6ca0a13          	addi	s4,s4,-916 # 8002cf40 <log>
    800042dc:	018a2583          	lw	a1,24(s4)
    800042e0:	012585bb          	addw	a1,a1,s2
    800042e4:	2585                	addiw	a1,a1,1
    800042e6:	028a2503          	lw	a0,40(s4)
    800042ea:	fffff097          	auipc	ra,0xfffff
    800042ee:	cc4080e7          	jalr	-828(ra) # 80002fae <bread>
    800042f2:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800042f4:	000aa583          	lw	a1,0(s5)
    800042f8:	028a2503          	lw	a0,40(s4)
    800042fc:	fffff097          	auipc	ra,0xfffff
    80004300:	cb2080e7          	jalr	-846(ra) # 80002fae <bread>
    80004304:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004306:	40000613          	li	a2,1024
    8000430a:	05850593          	addi	a1,a0,88
    8000430e:	05848513          	addi	a0,s1,88
    80004312:	ffffd097          	auipc	ra,0xffffd
    80004316:	a1c080e7          	jalr	-1508(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    8000431a:	8526                	mv	a0,s1
    8000431c:	fffff097          	auipc	ra,0xfffff
    80004320:	d84080e7          	jalr	-636(ra) # 800030a0 <bwrite>
    brelse(from);
    80004324:	854e                	mv	a0,s3
    80004326:	fffff097          	auipc	ra,0xfffff
    8000432a:	db8080e7          	jalr	-584(ra) # 800030de <brelse>
    brelse(to);
    8000432e:	8526                	mv	a0,s1
    80004330:	fffff097          	auipc	ra,0xfffff
    80004334:	dae080e7          	jalr	-594(ra) # 800030de <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004338:	2905                	addiw	s2,s2,1
    8000433a:	0a91                	addi	s5,s5,4
    8000433c:	02ca2783          	lw	a5,44(s4)
    80004340:	f8f94ee3          	blt	s2,a5,800042dc <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004344:	00000097          	auipc	ra,0x0
    80004348:	c68080e7          	jalr	-920(ra) # 80003fac <write_head>
    install_trans(0); // Now install writes to home locations
    8000434c:	4501                	li	a0,0
    8000434e:	00000097          	auipc	ra,0x0
    80004352:	cda080e7          	jalr	-806(ra) # 80004028 <install_trans>
    log.lh.n = 0;
    80004356:	00029797          	auipc	a5,0x29
    8000435a:	c007ab23          	sw	zero,-1002(a5) # 8002cf6c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000435e:	00000097          	auipc	ra,0x0
    80004362:	c4e080e7          	jalr	-946(ra) # 80003fac <write_head>
    80004366:	bdf5                	j	80004262 <end_op+0x52>

0000000080004368 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004368:	1101                	addi	sp,sp,-32
    8000436a:	ec06                	sd	ra,24(sp)
    8000436c:	e822                	sd	s0,16(sp)
    8000436e:	e426                	sd	s1,8(sp)
    80004370:	e04a                	sd	s2,0(sp)
    80004372:	1000                	addi	s0,sp,32
    80004374:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004376:	00029917          	auipc	s2,0x29
    8000437a:	bca90913          	addi	s2,s2,-1078 # 8002cf40 <log>
    8000437e:	854a                	mv	a0,s2
    80004380:	ffffd097          	auipc	ra,0xffffd
    80004384:	856080e7          	jalr	-1962(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004388:	02c92603          	lw	a2,44(s2)
    8000438c:	47f5                	li	a5,29
    8000438e:	06c7c563          	blt	a5,a2,800043f8 <log_write+0x90>
    80004392:	00029797          	auipc	a5,0x29
    80004396:	bca7a783          	lw	a5,-1078(a5) # 8002cf5c <log+0x1c>
    8000439a:	37fd                	addiw	a5,a5,-1
    8000439c:	04f65e63          	bge	a2,a5,800043f8 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800043a0:	00029797          	auipc	a5,0x29
    800043a4:	bc07a783          	lw	a5,-1088(a5) # 8002cf60 <log+0x20>
    800043a8:	06f05063          	blez	a5,80004408 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800043ac:	4781                	li	a5,0
    800043ae:	06c05563          	blez	a2,80004418 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800043b2:	44cc                	lw	a1,12(s1)
    800043b4:	00029717          	auipc	a4,0x29
    800043b8:	bbc70713          	addi	a4,a4,-1092 # 8002cf70 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800043bc:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800043be:	4314                	lw	a3,0(a4)
    800043c0:	04b68c63          	beq	a3,a1,80004418 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800043c4:	2785                	addiw	a5,a5,1
    800043c6:	0711                	addi	a4,a4,4
    800043c8:	fef61be3          	bne	a2,a5,800043be <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800043cc:	0621                	addi	a2,a2,8
    800043ce:	060a                	slli	a2,a2,0x2
    800043d0:	00029797          	auipc	a5,0x29
    800043d4:	b7078793          	addi	a5,a5,-1168 # 8002cf40 <log>
    800043d8:	97b2                	add	a5,a5,a2
    800043da:	44d8                	lw	a4,12(s1)
    800043dc:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800043de:	8526                	mv	a0,s1
    800043e0:	fffff097          	auipc	ra,0xfffff
    800043e4:	d9c080e7          	jalr	-612(ra) # 8000317c <bpin>
    log.lh.n++;
    800043e8:	00029717          	auipc	a4,0x29
    800043ec:	b5870713          	addi	a4,a4,-1192 # 8002cf40 <log>
    800043f0:	575c                	lw	a5,44(a4)
    800043f2:	2785                	addiw	a5,a5,1
    800043f4:	d75c                	sw	a5,44(a4)
    800043f6:	a82d                	j	80004430 <log_write+0xc8>
    panic("too big a transaction");
    800043f8:	00004517          	auipc	a0,0x4
    800043fc:	3a850513          	addi	a0,a0,936 # 800087a0 <syscalls+0x208>
    80004400:	ffffc097          	auipc	ra,0xffffc
    80004404:	140080e7          	jalr	320(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    80004408:	00004517          	auipc	a0,0x4
    8000440c:	3b050513          	addi	a0,a0,944 # 800087b8 <syscalls+0x220>
    80004410:	ffffc097          	auipc	ra,0xffffc
    80004414:	130080e7          	jalr	304(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    80004418:	00878693          	addi	a3,a5,8
    8000441c:	068a                	slli	a3,a3,0x2
    8000441e:	00029717          	auipc	a4,0x29
    80004422:	b2270713          	addi	a4,a4,-1246 # 8002cf40 <log>
    80004426:	9736                	add	a4,a4,a3
    80004428:	44d4                	lw	a3,12(s1)
    8000442a:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000442c:	faf609e3          	beq	a2,a5,800043de <log_write+0x76>
  }
  release(&log.lock);
    80004430:	00029517          	auipc	a0,0x29
    80004434:	b1050513          	addi	a0,a0,-1264 # 8002cf40 <log>
    80004438:	ffffd097          	auipc	ra,0xffffd
    8000443c:	852080e7          	jalr	-1966(ra) # 80000c8a <release>
}
    80004440:	60e2                	ld	ra,24(sp)
    80004442:	6442                	ld	s0,16(sp)
    80004444:	64a2                	ld	s1,8(sp)
    80004446:	6902                	ld	s2,0(sp)
    80004448:	6105                	addi	sp,sp,32
    8000444a:	8082                	ret

000000008000444c <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000444c:	1101                	addi	sp,sp,-32
    8000444e:	ec06                	sd	ra,24(sp)
    80004450:	e822                	sd	s0,16(sp)
    80004452:	e426                	sd	s1,8(sp)
    80004454:	e04a                	sd	s2,0(sp)
    80004456:	1000                	addi	s0,sp,32
    80004458:	84aa                	mv	s1,a0
    8000445a:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000445c:	00004597          	auipc	a1,0x4
    80004460:	37c58593          	addi	a1,a1,892 # 800087d8 <syscalls+0x240>
    80004464:	0521                	addi	a0,a0,8
    80004466:	ffffc097          	auipc	ra,0xffffc
    8000446a:	6e0080e7          	jalr	1760(ra) # 80000b46 <initlock>
  lk->name = name;
    8000446e:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004472:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004476:	0204a423          	sw	zero,40(s1)
}
    8000447a:	60e2                	ld	ra,24(sp)
    8000447c:	6442                	ld	s0,16(sp)
    8000447e:	64a2                	ld	s1,8(sp)
    80004480:	6902                	ld	s2,0(sp)
    80004482:	6105                	addi	sp,sp,32
    80004484:	8082                	ret

0000000080004486 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004486:	1101                	addi	sp,sp,-32
    80004488:	ec06                	sd	ra,24(sp)
    8000448a:	e822                	sd	s0,16(sp)
    8000448c:	e426                	sd	s1,8(sp)
    8000448e:	e04a                	sd	s2,0(sp)
    80004490:	1000                	addi	s0,sp,32
    80004492:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004494:	00850913          	addi	s2,a0,8
    80004498:	854a                	mv	a0,s2
    8000449a:	ffffc097          	auipc	ra,0xffffc
    8000449e:	73c080e7          	jalr	1852(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    800044a2:	409c                	lw	a5,0(s1)
    800044a4:	cb89                	beqz	a5,800044b6 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800044a6:	85ca                	mv	a1,s2
    800044a8:	8526                	mv	a0,s1
    800044aa:	ffffe097          	auipc	ra,0xffffe
    800044ae:	c0e080e7          	jalr	-1010(ra) # 800020b8 <sleep>
  while (lk->locked) {
    800044b2:	409c                	lw	a5,0(s1)
    800044b4:	fbed                	bnez	a5,800044a6 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800044b6:	4785                	li	a5,1
    800044b8:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800044ba:	ffffd097          	auipc	ra,0xffffd
    800044be:	4f2080e7          	jalr	1266(ra) # 800019ac <myproc>
    800044c2:	591c                	lw	a5,48(a0)
    800044c4:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800044c6:	854a                	mv	a0,s2
    800044c8:	ffffc097          	auipc	ra,0xffffc
    800044cc:	7c2080e7          	jalr	1986(ra) # 80000c8a <release>
}
    800044d0:	60e2                	ld	ra,24(sp)
    800044d2:	6442                	ld	s0,16(sp)
    800044d4:	64a2                	ld	s1,8(sp)
    800044d6:	6902                	ld	s2,0(sp)
    800044d8:	6105                	addi	sp,sp,32
    800044da:	8082                	ret

00000000800044dc <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800044dc:	1101                	addi	sp,sp,-32
    800044de:	ec06                	sd	ra,24(sp)
    800044e0:	e822                	sd	s0,16(sp)
    800044e2:	e426                	sd	s1,8(sp)
    800044e4:	e04a                	sd	s2,0(sp)
    800044e6:	1000                	addi	s0,sp,32
    800044e8:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044ea:	00850913          	addi	s2,a0,8
    800044ee:	854a                	mv	a0,s2
    800044f0:	ffffc097          	auipc	ra,0xffffc
    800044f4:	6e6080e7          	jalr	1766(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    800044f8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044fc:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004500:	8526                	mv	a0,s1
    80004502:	ffffe097          	auipc	ra,0xffffe
    80004506:	c1a080e7          	jalr	-998(ra) # 8000211c <wakeup>
  release(&lk->lk);
    8000450a:	854a                	mv	a0,s2
    8000450c:	ffffc097          	auipc	ra,0xffffc
    80004510:	77e080e7          	jalr	1918(ra) # 80000c8a <release>
}
    80004514:	60e2                	ld	ra,24(sp)
    80004516:	6442                	ld	s0,16(sp)
    80004518:	64a2                	ld	s1,8(sp)
    8000451a:	6902                	ld	s2,0(sp)
    8000451c:	6105                	addi	sp,sp,32
    8000451e:	8082                	ret

0000000080004520 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004520:	7179                	addi	sp,sp,-48
    80004522:	f406                	sd	ra,40(sp)
    80004524:	f022                	sd	s0,32(sp)
    80004526:	ec26                	sd	s1,24(sp)
    80004528:	e84a                	sd	s2,16(sp)
    8000452a:	e44e                	sd	s3,8(sp)
    8000452c:	1800                	addi	s0,sp,48
    8000452e:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004530:	00850913          	addi	s2,a0,8
    80004534:	854a                	mv	a0,s2
    80004536:	ffffc097          	auipc	ra,0xffffc
    8000453a:	6a0080e7          	jalr	1696(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000453e:	409c                	lw	a5,0(s1)
    80004540:	ef99                	bnez	a5,8000455e <holdingsleep+0x3e>
    80004542:	4481                	li	s1,0
  release(&lk->lk);
    80004544:	854a                	mv	a0,s2
    80004546:	ffffc097          	auipc	ra,0xffffc
    8000454a:	744080e7          	jalr	1860(ra) # 80000c8a <release>
  return r;
}
    8000454e:	8526                	mv	a0,s1
    80004550:	70a2                	ld	ra,40(sp)
    80004552:	7402                	ld	s0,32(sp)
    80004554:	64e2                	ld	s1,24(sp)
    80004556:	6942                	ld	s2,16(sp)
    80004558:	69a2                	ld	s3,8(sp)
    8000455a:	6145                	addi	sp,sp,48
    8000455c:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000455e:	0284a983          	lw	s3,40(s1)
    80004562:	ffffd097          	auipc	ra,0xffffd
    80004566:	44a080e7          	jalr	1098(ra) # 800019ac <myproc>
    8000456a:	5904                	lw	s1,48(a0)
    8000456c:	413484b3          	sub	s1,s1,s3
    80004570:	0014b493          	seqz	s1,s1
    80004574:	bfc1                	j	80004544 <holdingsleep+0x24>

0000000080004576 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004576:	1141                	addi	sp,sp,-16
    80004578:	e406                	sd	ra,8(sp)
    8000457a:	e022                	sd	s0,0(sp)
    8000457c:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000457e:	00004597          	auipc	a1,0x4
    80004582:	26a58593          	addi	a1,a1,618 # 800087e8 <syscalls+0x250>
    80004586:	00029517          	auipc	a0,0x29
    8000458a:	b0250513          	addi	a0,a0,-1278 # 8002d088 <ftable>
    8000458e:	ffffc097          	auipc	ra,0xffffc
    80004592:	5b8080e7          	jalr	1464(ra) # 80000b46 <initlock>
}
    80004596:	60a2                	ld	ra,8(sp)
    80004598:	6402                	ld	s0,0(sp)
    8000459a:	0141                	addi	sp,sp,16
    8000459c:	8082                	ret

000000008000459e <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000459e:	1101                	addi	sp,sp,-32
    800045a0:	ec06                	sd	ra,24(sp)
    800045a2:	e822                	sd	s0,16(sp)
    800045a4:	e426                	sd	s1,8(sp)
    800045a6:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800045a8:	00029517          	auipc	a0,0x29
    800045ac:	ae050513          	addi	a0,a0,-1312 # 8002d088 <ftable>
    800045b0:	ffffc097          	auipc	ra,0xffffc
    800045b4:	626080e7          	jalr	1574(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045b8:	00029497          	auipc	s1,0x29
    800045bc:	ae848493          	addi	s1,s1,-1304 # 8002d0a0 <ftable+0x18>
    800045c0:	0002a717          	auipc	a4,0x2a
    800045c4:	a8070713          	addi	a4,a4,-1408 # 8002e040 <disk>
    if(f->ref == 0){
    800045c8:	40dc                	lw	a5,4(s1)
    800045ca:	cf99                	beqz	a5,800045e8 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045cc:	02848493          	addi	s1,s1,40
    800045d0:	fee49ce3          	bne	s1,a4,800045c8 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800045d4:	00029517          	auipc	a0,0x29
    800045d8:	ab450513          	addi	a0,a0,-1356 # 8002d088 <ftable>
    800045dc:	ffffc097          	auipc	ra,0xffffc
    800045e0:	6ae080e7          	jalr	1710(ra) # 80000c8a <release>
  return 0;
    800045e4:	4481                	li	s1,0
    800045e6:	a819                	j	800045fc <filealloc+0x5e>
      f->ref = 1;
    800045e8:	4785                	li	a5,1
    800045ea:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800045ec:	00029517          	auipc	a0,0x29
    800045f0:	a9c50513          	addi	a0,a0,-1380 # 8002d088 <ftable>
    800045f4:	ffffc097          	auipc	ra,0xffffc
    800045f8:	696080e7          	jalr	1686(ra) # 80000c8a <release>
}
    800045fc:	8526                	mv	a0,s1
    800045fe:	60e2                	ld	ra,24(sp)
    80004600:	6442                	ld	s0,16(sp)
    80004602:	64a2                	ld	s1,8(sp)
    80004604:	6105                	addi	sp,sp,32
    80004606:	8082                	ret

0000000080004608 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004608:	1101                	addi	sp,sp,-32
    8000460a:	ec06                	sd	ra,24(sp)
    8000460c:	e822                	sd	s0,16(sp)
    8000460e:	e426                	sd	s1,8(sp)
    80004610:	1000                	addi	s0,sp,32
    80004612:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004614:	00029517          	auipc	a0,0x29
    80004618:	a7450513          	addi	a0,a0,-1420 # 8002d088 <ftable>
    8000461c:	ffffc097          	auipc	ra,0xffffc
    80004620:	5ba080e7          	jalr	1466(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004624:	40dc                	lw	a5,4(s1)
    80004626:	02f05263          	blez	a5,8000464a <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000462a:	2785                	addiw	a5,a5,1
    8000462c:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000462e:	00029517          	auipc	a0,0x29
    80004632:	a5a50513          	addi	a0,a0,-1446 # 8002d088 <ftable>
    80004636:	ffffc097          	auipc	ra,0xffffc
    8000463a:	654080e7          	jalr	1620(ra) # 80000c8a <release>
  return f;
}
    8000463e:	8526                	mv	a0,s1
    80004640:	60e2                	ld	ra,24(sp)
    80004642:	6442                	ld	s0,16(sp)
    80004644:	64a2                	ld	s1,8(sp)
    80004646:	6105                	addi	sp,sp,32
    80004648:	8082                	ret
    panic("filedup");
    8000464a:	00004517          	auipc	a0,0x4
    8000464e:	1a650513          	addi	a0,a0,422 # 800087f0 <syscalls+0x258>
    80004652:	ffffc097          	auipc	ra,0xffffc
    80004656:	eee080e7          	jalr	-274(ra) # 80000540 <panic>

000000008000465a <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000465a:	7139                	addi	sp,sp,-64
    8000465c:	fc06                	sd	ra,56(sp)
    8000465e:	f822                	sd	s0,48(sp)
    80004660:	f426                	sd	s1,40(sp)
    80004662:	f04a                	sd	s2,32(sp)
    80004664:	ec4e                	sd	s3,24(sp)
    80004666:	e852                	sd	s4,16(sp)
    80004668:	e456                	sd	s5,8(sp)
    8000466a:	0080                	addi	s0,sp,64
    8000466c:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000466e:	00029517          	auipc	a0,0x29
    80004672:	a1a50513          	addi	a0,a0,-1510 # 8002d088 <ftable>
    80004676:	ffffc097          	auipc	ra,0xffffc
    8000467a:	560080e7          	jalr	1376(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    8000467e:	40dc                	lw	a5,4(s1)
    80004680:	06f05163          	blez	a5,800046e2 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004684:	37fd                	addiw	a5,a5,-1
    80004686:	0007871b          	sext.w	a4,a5
    8000468a:	c0dc                	sw	a5,4(s1)
    8000468c:	06e04363          	bgtz	a4,800046f2 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004690:	0004a903          	lw	s2,0(s1)
    80004694:	0094ca83          	lbu	s5,9(s1)
    80004698:	0104ba03          	ld	s4,16(s1)
    8000469c:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800046a0:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800046a4:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800046a8:	00029517          	auipc	a0,0x29
    800046ac:	9e050513          	addi	a0,a0,-1568 # 8002d088 <ftable>
    800046b0:	ffffc097          	auipc	ra,0xffffc
    800046b4:	5da080e7          	jalr	1498(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    800046b8:	4785                	li	a5,1
    800046ba:	04f90d63          	beq	s2,a5,80004714 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800046be:	3979                	addiw	s2,s2,-2
    800046c0:	4785                	li	a5,1
    800046c2:	0527e063          	bltu	a5,s2,80004702 <fileclose+0xa8>
    begin_op();
    800046c6:	00000097          	auipc	ra,0x0
    800046ca:	acc080e7          	jalr	-1332(ra) # 80004192 <begin_op>
    iput(ff.ip);
    800046ce:	854e                	mv	a0,s3
    800046d0:	fffff097          	auipc	ra,0xfffff
    800046d4:	2b0080e7          	jalr	688(ra) # 80003980 <iput>
    end_op();
    800046d8:	00000097          	auipc	ra,0x0
    800046dc:	b38080e7          	jalr	-1224(ra) # 80004210 <end_op>
    800046e0:	a00d                	j	80004702 <fileclose+0xa8>
    panic("fileclose");
    800046e2:	00004517          	auipc	a0,0x4
    800046e6:	11650513          	addi	a0,a0,278 # 800087f8 <syscalls+0x260>
    800046ea:	ffffc097          	auipc	ra,0xffffc
    800046ee:	e56080e7          	jalr	-426(ra) # 80000540 <panic>
    release(&ftable.lock);
    800046f2:	00029517          	auipc	a0,0x29
    800046f6:	99650513          	addi	a0,a0,-1642 # 8002d088 <ftable>
    800046fa:	ffffc097          	auipc	ra,0xffffc
    800046fe:	590080e7          	jalr	1424(ra) # 80000c8a <release>
  }
}
    80004702:	70e2                	ld	ra,56(sp)
    80004704:	7442                	ld	s0,48(sp)
    80004706:	74a2                	ld	s1,40(sp)
    80004708:	7902                	ld	s2,32(sp)
    8000470a:	69e2                	ld	s3,24(sp)
    8000470c:	6a42                	ld	s4,16(sp)
    8000470e:	6aa2                	ld	s5,8(sp)
    80004710:	6121                	addi	sp,sp,64
    80004712:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004714:	85d6                	mv	a1,s5
    80004716:	8552                	mv	a0,s4
    80004718:	00000097          	auipc	ra,0x0
    8000471c:	34c080e7          	jalr	844(ra) # 80004a64 <pipeclose>
    80004720:	b7cd                	j	80004702 <fileclose+0xa8>

0000000080004722 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004722:	715d                	addi	sp,sp,-80
    80004724:	e486                	sd	ra,72(sp)
    80004726:	e0a2                	sd	s0,64(sp)
    80004728:	fc26                	sd	s1,56(sp)
    8000472a:	f84a                	sd	s2,48(sp)
    8000472c:	f44e                	sd	s3,40(sp)
    8000472e:	0880                	addi	s0,sp,80
    80004730:	84aa                	mv	s1,a0
    80004732:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004734:	ffffd097          	auipc	ra,0xffffd
    80004738:	278080e7          	jalr	632(ra) # 800019ac <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000473c:	409c                	lw	a5,0(s1)
    8000473e:	37f9                	addiw	a5,a5,-2
    80004740:	4705                	li	a4,1
    80004742:	04f76763          	bltu	a4,a5,80004790 <filestat+0x6e>
    80004746:	892a                	mv	s2,a0
    ilock(f->ip);
    80004748:	6c88                	ld	a0,24(s1)
    8000474a:	fffff097          	auipc	ra,0xfffff
    8000474e:	07c080e7          	jalr	124(ra) # 800037c6 <ilock>
    stati(f->ip, &st);
    80004752:	fb840593          	addi	a1,s0,-72
    80004756:	6c88                	ld	a0,24(s1)
    80004758:	fffff097          	auipc	ra,0xfffff
    8000475c:	2f8080e7          	jalr	760(ra) # 80003a50 <stati>
    iunlock(f->ip);
    80004760:	6c88                	ld	a0,24(s1)
    80004762:	fffff097          	auipc	ra,0xfffff
    80004766:	126080e7          	jalr	294(ra) # 80003888 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000476a:	46e1                	li	a3,24
    8000476c:	fb840613          	addi	a2,s0,-72
    80004770:	85ce                	mv	a1,s3
    80004772:	05093503          	ld	a0,80(s2)
    80004776:	ffffd097          	auipc	ra,0xffffd
    8000477a:	ef6080e7          	jalr	-266(ra) # 8000166c <copyout>
    8000477e:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004782:	60a6                	ld	ra,72(sp)
    80004784:	6406                	ld	s0,64(sp)
    80004786:	74e2                	ld	s1,56(sp)
    80004788:	7942                	ld	s2,48(sp)
    8000478a:	79a2                	ld	s3,40(sp)
    8000478c:	6161                	addi	sp,sp,80
    8000478e:	8082                	ret
  return -1;
    80004790:	557d                	li	a0,-1
    80004792:	bfc5                	j	80004782 <filestat+0x60>

0000000080004794 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004794:	7179                	addi	sp,sp,-48
    80004796:	f406                	sd	ra,40(sp)
    80004798:	f022                	sd	s0,32(sp)
    8000479a:	ec26                	sd	s1,24(sp)
    8000479c:	e84a                	sd	s2,16(sp)
    8000479e:	e44e                	sd	s3,8(sp)
    800047a0:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800047a2:	00854783          	lbu	a5,8(a0)
    800047a6:	c3d5                	beqz	a5,8000484a <fileread+0xb6>
    800047a8:	84aa                	mv	s1,a0
    800047aa:	89ae                	mv	s3,a1
    800047ac:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800047ae:	411c                	lw	a5,0(a0)
    800047b0:	4705                	li	a4,1
    800047b2:	04e78963          	beq	a5,a4,80004804 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047b6:	470d                	li	a4,3
    800047b8:	04e78d63          	beq	a5,a4,80004812 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800047bc:	4709                	li	a4,2
    800047be:	06e79e63          	bne	a5,a4,8000483a <fileread+0xa6>
    ilock(f->ip);
    800047c2:	6d08                	ld	a0,24(a0)
    800047c4:	fffff097          	auipc	ra,0xfffff
    800047c8:	002080e7          	jalr	2(ra) # 800037c6 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800047cc:	874a                	mv	a4,s2
    800047ce:	5094                	lw	a3,32(s1)
    800047d0:	864e                	mv	a2,s3
    800047d2:	4585                	li	a1,1
    800047d4:	6c88                	ld	a0,24(s1)
    800047d6:	fffff097          	auipc	ra,0xfffff
    800047da:	2a4080e7          	jalr	676(ra) # 80003a7a <readi>
    800047de:	892a                	mv	s2,a0
    800047e0:	00a05563          	blez	a0,800047ea <fileread+0x56>
      f->off += r;
    800047e4:	509c                	lw	a5,32(s1)
    800047e6:	9fa9                	addw	a5,a5,a0
    800047e8:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800047ea:	6c88                	ld	a0,24(s1)
    800047ec:	fffff097          	auipc	ra,0xfffff
    800047f0:	09c080e7          	jalr	156(ra) # 80003888 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800047f4:	854a                	mv	a0,s2
    800047f6:	70a2                	ld	ra,40(sp)
    800047f8:	7402                	ld	s0,32(sp)
    800047fa:	64e2                	ld	s1,24(sp)
    800047fc:	6942                	ld	s2,16(sp)
    800047fe:	69a2                	ld	s3,8(sp)
    80004800:	6145                	addi	sp,sp,48
    80004802:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004804:	6908                	ld	a0,16(a0)
    80004806:	00000097          	auipc	ra,0x0
    8000480a:	3c6080e7          	jalr	966(ra) # 80004bcc <piperead>
    8000480e:	892a                	mv	s2,a0
    80004810:	b7d5                	j	800047f4 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004812:	02451783          	lh	a5,36(a0)
    80004816:	03079693          	slli	a3,a5,0x30
    8000481a:	92c1                	srli	a3,a3,0x30
    8000481c:	4725                	li	a4,9
    8000481e:	02d76863          	bltu	a4,a3,8000484e <fileread+0xba>
    80004822:	0792                	slli	a5,a5,0x4
    80004824:	00028717          	auipc	a4,0x28
    80004828:	7c470713          	addi	a4,a4,1988 # 8002cfe8 <devsw>
    8000482c:	97ba                	add	a5,a5,a4
    8000482e:	639c                	ld	a5,0(a5)
    80004830:	c38d                	beqz	a5,80004852 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004832:	4505                	li	a0,1
    80004834:	9782                	jalr	a5
    80004836:	892a                	mv	s2,a0
    80004838:	bf75                	j	800047f4 <fileread+0x60>
    panic("fileread");
    8000483a:	00004517          	auipc	a0,0x4
    8000483e:	fce50513          	addi	a0,a0,-50 # 80008808 <syscalls+0x270>
    80004842:	ffffc097          	auipc	ra,0xffffc
    80004846:	cfe080e7          	jalr	-770(ra) # 80000540 <panic>
    return -1;
    8000484a:	597d                	li	s2,-1
    8000484c:	b765                	j	800047f4 <fileread+0x60>
      return -1;
    8000484e:	597d                	li	s2,-1
    80004850:	b755                	j	800047f4 <fileread+0x60>
    80004852:	597d                	li	s2,-1
    80004854:	b745                	j	800047f4 <fileread+0x60>

0000000080004856 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004856:	715d                	addi	sp,sp,-80
    80004858:	e486                	sd	ra,72(sp)
    8000485a:	e0a2                	sd	s0,64(sp)
    8000485c:	fc26                	sd	s1,56(sp)
    8000485e:	f84a                	sd	s2,48(sp)
    80004860:	f44e                	sd	s3,40(sp)
    80004862:	f052                	sd	s4,32(sp)
    80004864:	ec56                	sd	s5,24(sp)
    80004866:	e85a                	sd	s6,16(sp)
    80004868:	e45e                	sd	s7,8(sp)
    8000486a:	e062                	sd	s8,0(sp)
    8000486c:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000486e:	00954783          	lbu	a5,9(a0)
    80004872:	10078663          	beqz	a5,8000497e <filewrite+0x128>
    80004876:	892a                	mv	s2,a0
    80004878:	8b2e                	mv	s6,a1
    8000487a:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000487c:	411c                	lw	a5,0(a0)
    8000487e:	4705                	li	a4,1
    80004880:	02e78263          	beq	a5,a4,800048a4 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004884:	470d                	li	a4,3
    80004886:	02e78663          	beq	a5,a4,800048b2 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000488a:	4709                	li	a4,2
    8000488c:	0ee79163          	bne	a5,a4,8000496e <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004890:	0ac05d63          	blez	a2,8000494a <filewrite+0xf4>
    int i = 0;
    80004894:	4981                	li	s3,0
    80004896:	6b85                	lui	s7,0x1
    80004898:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    8000489c:	6c05                	lui	s8,0x1
    8000489e:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    800048a2:	a861                	j	8000493a <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800048a4:	6908                	ld	a0,16(a0)
    800048a6:	00000097          	auipc	ra,0x0
    800048aa:	22e080e7          	jalr	558(ra) # 80004ad4 <pipewrite>
    800048ae:	8a2a                	mv	s4,a0
    800048b0:	a045                	j	80004950 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800048b2:	02451783          	lh	a5,36(a0)
    800048b6:	03079693          	slli	a3,a5,0x30
    800048ba:	92c1                	srli	a3,a3,0x30
    800048bc:	4725                	li	a4,9
    800048be:	0cd76263          	bltu	a4,a3,80004982 <filewrite+0x12c>
    800048c2:	0792                	slli	a5,a5,0x4
    800048c4:	00028717          	auipc	a4,0x28
    800048c8:	72470713          	addi	a4,a4,1828 # 8002cfe8 <devsw>
    800048cc:	97ba                	add	a5,a5,a4
    800048ce:	679c                	ld	a5,8(a5)
    800048d0:	cbdd                	beqz	a5,80004986 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800048d2:	4505                	li	a0,1
    800048d4:	9782                	jalr	a5
    800048d6:	8a2a                	mv	s4,a0
    800048d8:	a8a5                	j	80004950 <filewrite+0xfa>
    800048da:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800048de:	00000097          	auipc	ra,0x0
    800048e2:	8b4080e7          	jalr	-1868(ra) # 80004192 <begin_op>
      ilock(f->ip);
    800048e6:	01893503          	ld	a0,24(s2)
    800048ea:	fffff097          	auipc	ra,0xfffff
    800048ee:	edc080e7          	jalr	-292(ra) # 800037c6 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800048f2:	8756                	mv	a4,s5
    800048f4:	02092683          	lw	a3,32(s2)
    800048f8:	01698633          	add	a2,s3,s6
    800048fc:	4585                	li	a1,1
    800048fe:	01893503          	ld	a0,24(s2)
    80004902:	fffff097          	auipc	ra,0xfffff
    80004906:	270080e7          	jalr	624(ra) # 80003b72 <writei>
    8000490a:	84aa                	mv	s1,a0
    8000490c:	00a05763          	blez	a0,8000491a <filewrite+0xc4>
        f->off += r;
    80004910:	02092783          	lw	a5,32(s2)
    80004914:	9fa9                	addw	a5,a5,a0
    80004916:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000491a:	01893503          	ld	a0,24(s2)
    8000491e:	fffff097          	auipc	ra,0xfffff
    80004922:	f6a080e7          	jalr	-150(ra) # 80003888 <iunlock>
      end_op();
    80004926:	00000097          	auipc	ra,0x0
    8000492a:	8ea080e7          	jalr	-1814(ra) # 80004210 <end_op>

      if(r != n1){
    8000492e:	009a9f63          	bne	s5,s1,8000494c <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004932:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004936:	0149db63          	bge	s3,s4,8000494c <filewrite+0xf6>
      int n1 = n - i;
    8000493a:	413a04bb          	subw	s1,s4,s3
    8000493e:	0004879b          	sext.w	a5,s1
    80004942:	f8fbdce3          	bge	s7,a5,800048da <filewrite+0x84>
    80004946:	84e2                	mv	s1,s8
    80004948:	bf49                	j	800048da <filewrite+0x84>
    int i = 0;
    8000494a:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000494c:	013a1f63          	bne	s4,s3,8000496a <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004950:	8552                	mv	a0,s4
    80004952:	60a6                	ld	ra,72(sp)
    80004954:	6406                	ld	s0,64(sp)
    80004956:	74e2                	ld	s1,56(sp)
    80004958:	7942                	ld	s2,48(sp)
    8000495a:	79a2                	ld	s3,40(sp)
    8000495c:	7a02                	ld	s4,32(sp)
    8000495e:	6ae2                	ld	s5,24(sp)
    80004960:	6b42                	ld	s6,16(sp)
    80004962:	6ba2                	ld	s7,8(sp)
    80004964:	6c02                	ld	s8,0(sp)
    80004966:	6161                	addi	sp,sp,80
    80004968:	8082                	ret
    ret = (i == n ? n : -1);
    8000496a:	5a7d                	li	s4,-1
    8000496c:	b7d5                	j	80004950 <filewrite+0xfa>
    panic("filewrite");
    8000496e:	00004517          	auipc	a0,0x4
    80004972:	eaa50513          	addi	a0,a0,-342 # 80008818 <syscalls+0x280>
    80004976:	ffffc097          	auipc	ra,0xffffc
    8000497a:	bca080e7          	jalr	-1078(ra) # 80000540 <panic>
    return -1;
    8000497e:	5a7d                	li	s4,-1
    80004980:	bfc1                	j	80004950 <filewrite+0xfa>
      return -1;
    80004982:	5a7d                	li	s4,-1
    80004984:	b7f1                	j	80004950 <filewrite+0xfa>
    80004986:	5a7d                	li	s4,-1
    80004988:	b7e1                	j	80004950 <filewrite+0xfa>

000000008000498a <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000498a:	7179                	addi	sp,sp,-48
    8000498c:	f406                	sd	ra,40(sp)
    8000498e:	f022                	sd	s0,32(sp)
    80004990:	ec26                	sd	s1,24(sp)
    80004992:	e84a                	sd	s2,16(sp)
    80004994:	e44e                	sd	s3,8(sp)
    80004996:	e052                	sd	s4,0(sp)
    80004998:	1800                	addi	s0,sp,48
    8000499a:	84aa                	mv	s1,a0
    8000499c:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000499e:	0005b023          	sd	zero,0(a1)
    800049a2:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800049a6:	00000097          	auipc	ra,0x0
    800049aa:	bf8080e7          	jalr	-1032(ra) # 8000459e <filealloc>
    800049ae:	e088                	sd	a0,0(s1)
    800049b0:	c551                	beqz	a0,80004a3c <pipealloc+0xb2>
    800049b2:	00000097          	auipc	ra,0x0
    800049b6:	bec080e7          	jalr	-1044(ra) # 8000459e <filealloc>
    800049ba:	00aa3023          	sd	a0,0(s4)
    800049be:	c92d                	beqz	a0,80004a30 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800049c0:	ffffc097          	auipc	ra,0xffffc
    800049c4:	126080e7          	jalr	294(ra) # 80000ae6 <kalloc>
    800049c8:	892a                	mv	s2,a0
    800049ca:	c125                	beqz	a0,80004a2a <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800049cc:	4985                	li	s3,1
    800049ce:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800049d2:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800049d6:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800049da:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800049de:	00004597          	auipc	a1,0x4
    800049e2:	b1258593          	addi	a1,a1,-1262 # 800084f0 <states.0+0x218>
    800049e6:	ffffc097          	auipc	ra,0xffffc
    800049ea:	160080e7          	jalr	352(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    800049ee:	609c                	ld	a5,0(s1)
    800049f0:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800049f4:	609c                	ld	a5,0(s1)
    800049f6:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800049fa:	609c                	ld	a5,0(s1)
    800049fc:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a00:	609c                	ld	a5,0(s1)
    80004a02:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004a06:	000a3783          	ld	a5,0(s4)
    80004a0a:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004a0e:	000a3783          	ld	a5,0(s4)
    80004a12:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a16:	000a3783          	ld	a5,0(s4)
    80004a1a:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a1e:	000a3783          	ld	a5,0(s4)
    80004a22:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a26:	4501                	li	a0,0
    80004a28:	a025                	j	80004a50 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a2a:	6088                	ld	a0,0(s1)
    80004a2c:	e501                	bnez	a0,80004a34 <pipealloc+0xaa>
    80004a2e:	a039                	j	80004a3c <pipealloc+0xb2>
    80004a30:	6088                	ld	a0,0(s1)
    80004a32:	c51d                	beqz	a0,80004a60 <pipealloc+0xd6>
    fileclose(*f0);
    80004a34:	00000097          	auipc	ra,0x0
    80004a38:	c26080e7          	jalr	-986(ra) # 8000465a <fileclose>
  if(*f1)
    80004a3c:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a40:	557d                	li	a0,-1
  if(*f1)
    80004a42:	c799                	beqz	a5,80004a50 <pipealloc+0xc6>
    fileclose(*f1);
    80004a44:	853e                	mv	a0,a5
    80004a46:	00000097          	auipc	ra,0x0
    80004a4a:	c14080e7          	jalr	-1004(ra) # 8000465a <fileclose>
  return -1;
    80004a4e:	557d                	li	a0,-1
}
    80004a50:	70a2                	ld	ra,40(sp)
    80004a52:	7402                	ld	s0,32(sp)
    80004a54:	64e2                	ld	s1,24(sp)
    80004a56:	6942                	ld	s2,16(sp)
    80004a58:	69a2                	ld	s3,8(sp)
    80004a5a:	6a02                	ld	s4,0(sp)
    80004a5c:	6145                	addi	sp,sp,48
    80004a5e:	8082                	ret
  return -1;
    80004a60:	557d                	li	a0,-1
    80004a62:	b7fd                	j	80004a50 <pipealloc+0xc6>

0000000080004a64 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a64:	1101                	addi	sp,sp,-32
    80004a66:	ec06                	sd	ra,24(sp)
    80004a68:	e822                	sd	s0,16(sp)
    80004a6a:	e426                	sd	s1,8(sp)
    80004a6c:	e04a                	sd	s2,0(sp)
    80004a6e:	1000                	addi	s0,sp,32
    80004a70:	84aa                	mv	s1,a0
    80004a72:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a74:	ffffc097          	auipc	ra,0xffffc
    80004a78:	162080e7          	jalr	354(ra) # 80000bd6 <acquire>
  if(writable){
    80004a7c:	02090d63          	beqz	s2,80004ab6 <pipeclose+0x52>
    pi->writeopen = 0;
    80004a80:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a84:	21848513          	addi	a0,s1,536
    80004a88:	ffffd097          	auipc	ra,0xffffd
    80004a8c:	694080e7          	jalr	1684(ra) # 8000211c <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a90:	2204b783          	ld	a5,544(s1)
    80004a94:	eb95                	bnez	a5,80004ac8 <pipeclose+0x64>
    release(&pi->lock);
    80004a96:	8526                	mv	a0,s1
    80004a98:	ffffc097          	auipc	ra,0xffffc
    80004a9c:	1f2080e7          	jalr	498(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004aa0:	8526                	mv	a0,s1
    80004aa2:	ffffc097          	auipc	ra,0xffffc
    80004aa6:	f46080e7          	jalr	-186(ra) # 800009e8 <kfree>
  } else
    release(&pi->lock);
}
    80004aaa:	60e2                	ld	ra,24(sp)
    80004aac:	6442                	ld	s0,16(sp)
    80004aae:	64a2                	ld	s1,8(sp)
    80004ab0:	6902                	ld	s2,0(sp)
    80004ab2:	6105                	addi	sp,sp,32
    80004ab4:	8082                	ret
    pi->readopen = 0;
    80004ab6:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004aba:	21c48513          	addi	a0,s1,540
    80004abe:	ffffd097          	auipc	ra,0xffffd
    80004ac2:	65e080e7          	jalr	1630(ra) # 8000211c <wakeup>
    80004ac6:	b7e9                	j	80004a90 <pipeclose+0x2c>
    release(&pi->lock);
    80004ac8:	8526                	mv	a0,s1
    80004aca:	ffffc097          	auipc	ra,0xffffc
    80004ace:	1c0080e7          	jalr	448(ra) # 80000c8a <release>
}
    80004ad2:	bfe1                	j	80004aaa <pipeclose+0x46>

0000000080004ad4 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004ad4:	711d                	addi	sp,sp,-96
    80004ad6:	ec86                	sd	ra,88(sp)
    80004ad8:	e8a2                	sd	s0,80(sp)
    80004ada:	e4a6                	sd	s1,72(sp)
    80004adc:	e0ca                	sd	s2,64(sp)
    80004ade:	fc4e                	sd	s3,56(sp)
    80004ae0:	f852                	sd	s4,48(sp)
    80004ae2:	f456                	sd	s5,40(sp)
    80004ae4:	f05a                	sd	s6,32(sp)
    80004ae6:	ec5e                	sd	s7,24(sp)
    80004ae8:	e862                	sd	s8,16(sp)
    80004aea:	1080                	addi	s0,sp,96
    80004aec:	84aa                	mv	s1,a0
    80004aee:	8aae                	mv	s5,a1
    80004af0:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004af2:	ffffd097          	auipc	ra,0xffffd
    80004af6:	eba080e7          	jalr	-326(ra) # 800019ac <myproc>
    80004afa:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004afc:	8526                	mv	a0,s1
    80004afe:	ffffc097          	auipc	ra,0xffffc
    80004b02:	0d8080e7          	jalr	216(ra) # 80000bd6 <acquire>
  while(i < n){
    80004b06:	0b405663          	blez	s4,80004bb2 <pipewrite+0xde>
  int i = 0;
    80004b0a:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b0c:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004b0e:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b12:	21c48b93          	addi	s7,s1,540
    80004b16:	a089                	j	80004b58 <pipewrite+0x84>
      release(&pi->lock);
    80004b18:	8526                	mv	a0,s1
    80004b1a:	ffffc097          	auipc	ra,0xffffc
    80004b1e:	170080e7          	jalr	368(ra) # 80000c8a <release>
      return -1;
    80004b22:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004b24:	854a                	mv	a0,s2
    80004b26:	60e6                	ld	ra,88(sp)
    80004b28:	6446                	ld	s0,80(sp)
    80004b2a:	64a6                	ld	s1,72(sp)
    80004b2c:	6906                	ld	s2,64(sp)
    80004b2e:	79e2                	ld	s3,56(sp)
    80004b30:	7a42                	ld	s4,48(sp)
    80004b32:	7aa2                	ld	s5,40(sp)
    80004b34:	7b02                	ld	s6,32(sp)
    80004b36:	6be2                	ld	s7,24(sp)
    80004b38:	6c42                	ld	s8,16(sp)
    80004b3a:	6125                	addi	sp,sp,96
    80004b3c:	8082                	ret
      wakeup(&pi->nread);
    80004b3e:	8562                	mv	a0,s8
    80004b40:	ffffd097          	auipc	ra,0xffffd
    80004b44:	5dc080e7          	jalr	1500(ra) # 8000211c <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b48:	85a6                	mv	a1,s1
    80004b4a:	855e                	mv	a0,s7
    80004b4c:	ffffd097          	auipc	ra,0xffffd
    80004b50:	56c080e7          	jalr	1388(ra) # 800020b8 <sleep>
  while(i < n){
    80004b54:	07495063          	bge	s2,s4,80004bb4 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004b58:	2204a783          	lw	a5,544(s1)
    80004b5c:	dfd5                	beqz	a5,80004b18 <pipewrite+0x44>
    80004b5e:	854e                	mv	a0,s3
    80004b60:	ffffe097          	auipc	ra,0xffffe
    80004b64:	800080e7          	jalr	-2048(ra) # 80002360 <killed>
    80004b68:	f945                	bnez	a0,80004b18 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004b6a:	2184a783          	lw	a5,536(s1)
    80004b6e:	21c4a703          	lw	a4,540(s1)
    80004b72:	2007879b          	addiw	a5,a5,512
    80004b76:	fcf704e3          	beq	a4,a5,80004b3e <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b7a:	4685                	li	a3,1
    80004b7c:	01590633          	add	a2,s2,s5
    80004b80:	faf40593          	addi	a1,s0,-81
    80004b84:	0509b503          	ld	a0,80(s3)
    80004b88:	ffffd097          	auipc	ra,0xffffd
    80004b8c:	b70080e7          	jalr	-1168(ra) # 800016f8 <copyin>
    80004b90:	03650263          	beq	a0,s6,80004bb4 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b94:	21c4a783          	lw	a5,540(s1)
    80004b98:	0017871b          	addiw	a4,a5,1
    80004b9c:	20e4ae23          	sw	a4,540(s1)
    80004ba0:	1ff7f793          	andi	a5,a5,511
    80004ba4:	97a6                	add	a5,a5,s1
    80004ba6:	faf44703          	lbu	a4,-81(s0)
    80004baa:	00e78c23          	sb	a4,24(a5)
      i++;
    80004bae:	2905                	addiw	s2,s2,1
    80004bb0:	b755                	j	80004b54 <pipewrite+0x80>
  int i = 0;
    80004bb2:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004bb4:	21848513          	addi	a0,s1,536
    80004bb8:	ffffd097          	auipc	ra,0xffffd
    80004bbc:	564080e7          	jalr	1380(ra) # 8000211c <wakeup>
  release(&pi->lock);
    80004bc0:	8526                	mv	a0,s1
    80004bc2:	ffffc097          	auipc	ra,0xffffc
    80004bc6:	0c8080e7          	jalr	200(ra) # 80000c8a <release>
  return i;
    80004bca:	bfa9                	j	80004b24 <pipewrite+0x50>

0000000080004bcc <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004bcc:	715d                	addi	sp,sp,-80
    80004bce:	e486                	sd	ra,72(sp)
    80004bd0:	e0a2                	sd	s0,64(sp)
    80004bd2:	fc26                	sd	s1,56(sp)
    80004bd4:	f84a                	sd	s2,48(sp)
    80004bd6:	f44e                	sd	s3,40(sp)
    80004bd8:	f052                	sd	s4,32(sp)
    80004bda:	ec56                	sd	s5,24(sp)
    80004bdc:	e85a                	sd	s6,16(sp)
    80004bde:	0880                	addi	s0,sp,80
    80004be0:	84aa                	mv	s1,a0
    80004be2:	892e                	mv	s2,a1
    80004be4:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004be6:	ffffd097          	auipc	ra,0xffffd
    80004bea:	dc6080e7          	jalr	-570(ra) # 800019ac <myproc>
    80004bee:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004bf0:	8526                	mv	a0,s1
    80004bf2:	ffffc097          	auipc	ra,0xffffc
    80004bf6:	fe4080e7          	jalr	-28(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bfa:	2184a703          	lw	a4,536(s1)
    80004bfe:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c02:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c06:	02f71763          	bne	a4,a5,80004c34 <piperead+0x68>
    80004c0a:	2244a783          	lw	a5,548(s1)
    80004c0e:	c39d                	beqz	a5,80004c34 <piperead+0x68>
    if(killed(pr)){
    80004c10:	8552                	mv	a0,s4
    80004c12:	ffffd097          	auipc	ra,0xffffd
    80004c16:	74e080e7          	jalr	1870(ra) # 80002360 <killed>
    80004c1a:	e949                	bnez	a0,80004cac <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c1c:	85a6                	mv	a1,s1
    80004c1e:	854e                	mv	a0,s3
    80004c20:	ffffd097          	auipc	ra,0xffffd
    80004c24:	498080e7          	jalr	1176(ra) # 800020b8 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c28:	2184a703          	lw	a4,536(s1)
    80004c2c:	21c4a783          	lw	a5,540(s1)
    80004c30:	fcf70de3          	beq	a4,a5,80004c0a <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c34:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c36:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c38:	05505463          	blez	s5,80004c80 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004c3c:	2184a783          	lw	a5,536(s1)
    80004c40:	21c4a703          	lw	a4,540(s1)
    80004c44:	02f70e63          	beq	a4,a5,80004c80 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c48:	0017871b          	addiw	a4,a5,1
    80004c4c:	20e4ac23          	sw	a4,536(s1)
    80004c50:	1ff7f793          	andi	a5,a5,511
    80004c54:	97a6                	add	a5,a5,s1
    80004c56:	0187c783          	lbu	a5,24(a5)
    80004c5a:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c5e:	4685                	li	a3,1
    80004c60:	fbf40613          	addi	a2,s0,-65
    80004c64:	85ca                	mv	a1,s2
    80004c66:	050a3503          	ld	a0,80(s4)
    80004c6a:	ffffd097          	auipc	ra,0xffffd
    80004c6e:	a02080e7          	jalr	-1534(ra) # 8000166c <copyout>
    80004c72:	01650763          	beq	a0,s6,80004c80 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c76:	2985                	addiw	s3,s3,1
    80004c78:	0905                	addi	s2,s2,1
    80004c7a:	fd3a91e3          	bne	s5,s3,80004c3c <piperead+0x70>
    80004c7e:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c80:	21c48513          	addi	a0,s1,540
    80004c84:	ffffd097          	auipc	ra,0xffffd
    80004c88:	498080e7          	jalr	1176(ra) # 8000211c <wakeup>
  release(&pi->lock);
    80004c8c:	8526                	mv	a0,s1
    80004c8e:	ffffc097          	auipc	ra,0xffffc
    80004c92:	ffc080e7          	jalr	-4(ra) # 80000c8a <release>
  return i;
}
    80004c96:	854e                	mv	a0,s3
    80004c98:	60a6                	ld	ra,72(sp)
    80004c9a:	6406                	ld	s0,64(sp)
    80004c9c:	74e2                	ld	s1,56(sp)
    80004c9e:	7942                	ld	s2,48(sp)
    80004ca0:	79a2                	ld	s3,40(sp)
    80004ca2:	7a02                	ld	s4,32(sp)
    80004ca4:	6ae2                	ld	s5,24(sp)
    80004ca6:	6b42                	ld	s6,16(sp)
    80004ca8:	6161                	addi	sp,sp,80
    80004caa:	8082                	ret
      release(&pi->lock);
    80004cac:	8526                	mv	a0,s1
    80004cae:	ffffc097          	auipc	ra,0xffffc
    80004cb2:	fdc080e7          	jalr	-36(ra) # 80000c8a <release>
      return -1;
    80004cb6:	59fd                	li	s3,-1
    80004cb8:	bff9                	j	80004c96 <piperead+0xca>

0000000080004cba <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004cba:	1141                	addi	sp,sp,-16
    80004cbc:	e422                	sd	s0,8(sp)
    80004cbe:	0800                	addi	s0,sp,16
    80004cc0:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004cc2:	8905                	andi	a0,a0,1
    80004cc4:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004cc6:	8b89                	andi	a5,a5,2
    80004cc8:	c399                	beqz	a5,80004cce <flags2perm+0x14>
      perm |= PTE_W;
    80004cca:	00456513          	ori	a0,a0,4
    return perm;
}
    80004cce:	6422                	ld	s0,8(sp)
    80004cd0:	0141                	addi	sp,sp,16
    80004cd2:	8082                	ret

0000000080004cd4 <exec>:

int
exec(char *path, char **argv)
{
    80004cd4:	de010113          	addi	sp,sp,-544
    80004cd8:	20113c23          	sd	ra,536(sp)
    80004cdc:	20813823          	sd	s0,528(sp)
    80004ce0:	20913423          	sd	s1,520(sp)
    80004ce4:	21213023          	sd	s2,512(sp)
    80004ce8:	ffce                	sd	s3,504(sp)
    80004cea:	fbd2                	sd	s4,496(sp)
    80004cec:	f7d6                	sd	s5,488(sp)
    80004cee:	f3da                	sd	s6,480(sp)
    80004cf0:	efde                	sd	s7,472(sp)
    80004cf2:	ebe2                	sd	s8,464(sp)
    80004cf4:	e7e6                	sd	s9,456(sp)
    80004cf6:	e3ea                	sd	s10,448(sp)
    80004cf8:	ff6e                	sd	s11,440(sp)
    80004cfa:	1400                	addi	s0,sp,544
    80004cfc:	892a                	mv	s2,a0
    80004cfe:	dea43423          	sd	a0,-536(s0)
    80004d02:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004d06:	ffffd097          	auipc	ra,0xffffd
    80004d0a:	ca6080e7          	jalr	-858(ra) # 800019ac <myproc>
    80004d0e:	84aa                	mv	s1,a0

  begin_op();
    80004d10:	fffff097          	auipc	ra,0xfffff
    80004d14:	482080e7          	jalr	1154(ra) # 80004192 <begin_op>

  if((ip = namei(path)) == 0){
    80004d18:	854a                	mv	a0,s2
    80004d1a:	fffff097          	auipc	ra,0xfffff
    80004d1e:	258080e7          	jalr	600(ra) # 80003f72 <namei>
    80004d22:	c93d                	beqz	a0,80004d98 <exec+0xc4>
    80004d24:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d26:	fffff097          	auipc	ra,0xfffff
    80004d2a:	aa0080e7          	jalr	-1376(ra) # 800037c6 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d2e:	04000713          	li	a4,64
    80004d32:	4681                	li	a3,0
    80004d34:	e5040613          	addi	a2,s0,-432
    80004d38:	4581                	li	a1,0
    80004d3a:	8556                	mv	a0,s5
    80004d3c:	fffff097          	auipc	ra,0xfffff
    80004d40:	d3e080e7          	jalr	-706(ra) # 80003a7a <readi>
    80004d44:	04000793          	li	a5,64
    80004d48:	00f51a63          	bne	a0,a5,80004d5c <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004d4c:	e5042703          	lw	a4,-432(s0)
    80004d50:	464c47b7          	lui	a5,0x464c4
    80004d54:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d58:	04f70663          	beq	a4,a5,80004da4 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d5c:	8556                	mv	a0,s5
    80004d5e:	fffff097          	auipc	ra,0xfffff
    80004d62:	cca080e7          	jalr	-822(ra) # 80003a28 <iunlockput>
    end_op();
    80004d66:	fffff097          	auipc	ra,0xfffff
    80004d6a:	4aa080e7          	jalr	1194(ra) # 80004210 <end_op>
  }
  return -1;
    80004d6e:	557d                	li	a0,-1
}
    80004d70:	21813083          	ld	ra,536(sp)
    80004d74:	21013403          	ld	s0,528(sp)
    80004d78:	20813483          	ld	s1,520(sp)
    80004d7c:	20013903          	ld	s2,512(sp)
    80004d80:	79fe                	ld	s3,504(sp)
    80004d82:	7a5e                	ld	s4,496(sp)
    80004d84:	7abe                	ld	s5,488(sp)
    80004d86:	7b1e                	ld	s6,480(sp)
    80004d88:	6bfe                	ld	s7,472(sp)
    80004d8a:	6c5e                	ld	s8,464(sp)
    80004d8c:	6cbe                	ld	s9,456(sp)
    80004d8e:	6d1e                	ld	s10,448(sp)
    80004d90:	7dfa                	ld	s11,440(sp)
    80004d92:	22010113          	addi	sp,sp,544
    80004d96:	8082                	ret
    end_op();
    80004d98:	fffff097          	auipc	ra,0xfffff
    80004d9c:	478080e7          	jalr	1144(ra) # 80004210 <end_op>
    return -1;
    80004da0:	557d                	li	a0,-1
    80004da2:	b7f9                	j	80004d70 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004da4:	8526                	mv	a0,s1
    80004da6:	ffffd097          	auipc	ra,0xffffd
    80004daa:	cca080e7          	jalr	-822(ra) # 80001a70 <proc_pagetable>
    80004dae:	8b2a                	mv	s6,a0
    80004db0:	d555                	beqz	a0,80004d5c <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004db2:	e7042783          	lw	a5,-400(s0)
    80004db6:	e8845703          	lhu	a4,-376(s0)
    80004dba:	c735                	beqz	a4,80004e26 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004dbc:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004dbe:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004dc2:	6a05                	lui	s4,0x1
    80004dc4:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004dc8:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004dcc:	6d85                	lui	s11,0x1
    80004dce:	7d7d                	lui	s10,0xfffff
    80004dd0:	ac3d                	j	8000500e <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004dd2:	00004517          	auipc	a0,0x4
    80004dd6:	a5650513          	addi	a0,a0,-1450 # 80008828 <syscalls+0x290>
    80004dda:	ffffb097          	auipc	ra,0xffffb
    80004dde:	766080e7          	jalr	1894(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004de2:	874a                	mv	a4,s2
    80004de4:	009c86bb          	addw	a3,s9,s1
    80004de8:	4581                	li	a1,0
    80004dea:	8556                	mv	a0,s5
    80004dec:	fffff097          	auipc	ra,0xfffff
    80004df0:	c8e080e7          	jalr	-882(ra) # 80003a7a <readi>
    80004df4:	2501                	sext.w	a0,a0
    80004df6:	1aa91963          	bne	s2,a0,80004fa8 <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    80004dfa:	009d84bb          	addw	s1,s11,s1
    80004dfe:	013d09bb          	addw	s3,s10,s3
    80004e02:	1f74f663          	bgeu	s1,s7,80004fee <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    80004e06:	02049593          	slli	a1,s1,0x20
    80004e0a:	9181                	srli	a1,a1,0x20
    80004e0c:	95e2                	add	a1,a1,s8
    80004e0e:	855a                	mv	a0,s6
    80004e10:	ffffc097          	auipc	ra,0xffffc
    80004e14:	24c080e7          	jalr	588(ra) # 8000105c <walkaddr>
    80004e18:	862a                	mv	a2,a0
    if(pa == 0)
    80004e1a:	dd45                	beqz	a0,80004dd2 <exec+0xfe>
      n = PGSIZE;
    80004e1c:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004e1e:	fd49f2e3          	bgeu	s3,s4,80004de2 <exec+0x10e>
      n = sz - i;
    80004e22:	894e                	mv	s2,s3
    80004e24:	bf7d                	j	80004de2 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e26:	4901                	li	s2,0
  iunlockput(ip);
    80004e28:	8556                	mv	a0,s5
    80004e2a:	fffff097          	auipc	ra,0xfffff
    80004e2e:	bfe080e7          	jalr	-1026(ra) # 80003a28 <iunlockput>
  end_op();
    80004e32:	fffff097          	auipc	ra,0xfffff
    80004e36:	3de080e7          	jalr	990(ra) # 80004210 <end_op>
  p = myproc();
    80004e3a:	ffffd097          	auipc	ra,0xffffd
    80004e3e:	b72080e7          	jalr	-1166(ra) # 800019ac <myproc>
    80004e42:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004e44:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e48:	6785                	lui	a5,0x1
    80004e4a:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80004e4c:	97ca                	add	a5,a5,s2
    80004e4e:	777d                	lui	a4,0xfffff
    80004e50:	8ff9                	and	a5,a5,a4
    80004e52:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004e56:	4691                	li	a3,4
    80004e58:	6609                	lui	a2,0x2
    80004e5a:	963e                	add	a2,a2,a5
    80004e5c:	85be                	mv	a1,a5
    80004e5e:	855a                	mv	a0,s6
    80004e60:	ffffc097          	auipc	ra,0xffffc
    80004e64:	5b0080e7          	jalr	1456(ra) # 80001410 <uvmalloc>
    80004e68:	8c2a                	mv	s8,a0
  ip = 0;
    80004e6a:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004e6c:	12050e63          	beqz	a0,80004fa8 <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e70:	75f9                	lui	a1,0xffffe
    80004e72:	95aa                	add	a1,a1,a0
    80004e74:	855a                	mv	a0,s6
    80004e76:	ffffc097          	auipc	ra,0xffffc
    80004e7a:	7c4080e7          	jalr	1988(ra) # 8000163a <uvmclear>
  stackbase = sp - PGSIZE;
    80004e7e:	7afd                	lui	s5,0xfffff
    80004e80:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e82:	df043783          	ld	a5,-528(s0)
    80004e86:	6388                	ld	a0,0(a5)
    80004e88:	c925                	beqz	a0,80004ef8 <exec+0x224>
    80004e8a:	e9040993          	addi	s3,s0,-368
    80004e8e:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004e92:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e94:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004e96:	ffffc097          	auipc	ra,0xffffc
    80004e9a:	fb8080e7          	jalr	-72(ra) # 80000e4e <strlen>
    80004e9e:	0015079b          	addiw	a5,a0,1
    80004ea2:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004ea6:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004eaa:	13596663          	bltu	s2,s5,80004fd6 <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004eae:	df043d83          	ld	s11,-528(s0)
    80004eb2:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004eb6:	8552                	mv	a0,s4
    80004eb8:	ffffc097          	auipc	ra,0xffffc
    80004ebc:	f96080e7          	jalr	-106(ra) # 80000e4e <strlen>
    80004ec0:	0015069b          	addiw	a3,a0,1
    80004ec4:	8652                	mv	a2,s4
    80004ec6:	85ca                	mv	a1,s2
    80004ec8:	855a                	mv	a0,s6
    80004eca:	ffffc097          	auipc	ra,0xffffc
    80004ece:	7a2080e7          	jalr	1954(ra) # 8000166c <copyout>
    80004ed2:	10054663          	bltz	a0,80004fde <exec+0x30a>
    ustack[argc] = sp;
    80004ed6:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004eda:	0485                	addi	s1,s1,1
    80004edc:	008d8793          	addi	a5,s11,8
    80004ee0:	def43823          	sd	a5,-528(s0)
    80004ee4:	008db503          	ld	a0,8(s11)
    80004ee8:	c911                	beqz	a0,80004efc <exec+0x228>
    if(argc >= MAXARG)
    80004eea:	09a1                	addi	s3,s3,8
    80004eec:	fb3c95e3          	bne	s9,s3,80004e96 <exec+0x1c2>
  sz = sz1;
    80004ef0:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004ef4:	4a81                	li	s5,0
    80004ef6:	a84d                	j	80004fa8 <exec+0x2d4>
  sp = sz;
    80004ef8:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004efa:	4481                	li	s1,0
  ustack[argc] = 0;
    80004efc:	00349793          	slli	a5,s1,0x3
    80004f00:	f9078793          	addi	a5,a5,-112
    80004f04:	97a2                	add	a5,a5,s0
    80004f06:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004f0a:	00148693          	addi	a3,s1,1
    80004f0e:	068e                	slli	a3,a3,0x3
    80004f10:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004f14:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004f18:	01597663          	bgeu	s2,s5,80004f24 <exec+0x250>
  sz = sz1;
    80004f1c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f20:	4a81                	li	s5,0
    80004f22:	a059                	j	80004fa8 <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f24:	e9040613          	addi	a2,s0,-368
    80004f28:	85ca                	mv	a1,s2
    80004f2a:	855a                	mv	a0,s6
    80004f2c:	ffffc097          	auipc	ra,0xffffc
    80004f30:	740080e7          	jalr	1856(ra) # 8000166c <copyout>
    80004f34:	0a054963          	bltz	a0,80004fe6 <exec+0x312>
  p->trapframe->a1 = sp;
    80004f38:	058bb783          	ld	a5,88(s7)
    80004f3c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f40:	de843783          	ld	a5,-536(s0)
    80004f44:	0007c703          	lbu	a4,0(a5)
    80004f48:	cf11                	beqz	a4,80004f64 <exec+0x290>
    80004f4a:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f4c:	02f00693          	li	a3,47
    80004f50:	a039                	j	80004f5e <exec+0x28a>
      last = s+1;
    80004f52:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004f56:	0785                	addi	a5,a5,1
    80004f58:	fff7c703          	lbu	a4,-1(a5)
    80004f5c:	c701                	beqz	a4,80004f64 <exec+0x290>
    if(*s == '/')
    80004f5e:	fed71ce3          	bne	a4,a3,80004f56 <exec+0x282>
    80004f62:	bfc5                	j	80004f52 <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f64:	4641                	li	a2,16
    80004f66:	de843583          	ld	a1,-536(s0)
    80004f6a:	158b8513          	addi	a0,s7,344
    80004f6e:	ffffc097          	auipc	ra,0xffffc
    80004f72:	eae080e7          	jalr	-338(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    80004f76:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004f7a:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004f7e:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f82:	058bb783          	ld	a5,88(s7)
    80004f86:	e6843703          	ld	a4,-408(s0)
    80004f8a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f8c:	058bb783          	ld	a5,88(s7)
    80004f90:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f94:	85ea                	mv	a1,s10
    80004f96:	ffffd097          	auipc	ra,0xffffd
    80004f9a:	b76080e7          	jalr	-1162(ra) # 80001b0c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f9e:	0004851b          	sext.w	a0,s1
    80004fa2:	b3f9                	j	80004d70 <exec+0x9c>
    80004fa4:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004fa8:	df843583          	ld	a1,-520(s0)
    80004fac:	855a                	mv	a0,s6
    80004fae:	ffffd097          	auipc	ra,0xffffd
    80004fb2:	b5e080e7          	jalr	-1186(ra) # 80001b0c <proc_freepagetable>
  if(ip){
    80004fb6:	da0a93e3          	bnez	s5,80004d5c <exec+0x88>
  return -1;
    80004fba:	557d                	li	a0,-1
    80004fbc:	bb55                	j	80004d70 <exec+0x9c>
    80004fbe:	df243c23          	sd	s2,-520(s0)
    80004fc2:	b7dd                	j	80004fa8 <exec+0x2d4>
    80004fc4:	df243c23          	sd	s2,-520(s0)
    80004fc8:	b7c5                	j	80004fa8 <exec+0x2d4>
    80004fca:	df243c23          	sd	s2,-520(s0)
    80004fce:	bfe9                	j	80004fa8 <exec+0x2d4>
    80004fd0:	df243c23          	sd	s2,-520(s0)
    80004fd4:	bfd1                	j	80004fa8 <exec+0x2d4>
  sz = sz1;
    80004fd6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004fda:	4a81                	li	s5,0
    80004fdc:	b7f1                	j	80004fa8 <exec+0x2d4>
  sz = sz1;
    80004fde:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004fe2:	4a81                	li	s5,0
    80004fe4:	b7d1                	j	80004fa8 <exec+0x2d4>
  sz = sz1;
    80004fe6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004fea:	4a81                	li	s5,0
    80004fec:	bf75                	j	80004fa8 <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004fee:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ff2:	e0843783          	ld	a5,-504(s0)
    80004ff6:	0017869b          	addiw	a3,a5,1
    80004ffa:	e0d43423          	sd	a3,-504(s0)
    80004ffe:	e0043783          	ld	a5,-512(s0)
    80005002:	0387879b          	addiw	a5,a5,56
    80005006:	e8845703          	lhu	a4,-376(s0)
    8000500a:	e0e6dfe3          	bge	a3,a4,80004e28 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000500e:	2781                	sext.w	a5,a5
    80005010:	e0f43023          	sd	a5,-512(s0)
    80005014:	03800713          	li	a4,56
    80005018:	86be                	mv	a3,a5
    8000501a:	e1840613          	addi	a2,s0,-488
    8000501e:	4581                	li	a1,0
    80005020:	8556                	mv	a0,s5
    80005022:	fffff097          	auipc	ra,0xfffff
    80005026:	a58080e7          	jalr	-1448(ra) # 80003a7a <readi>
    8000502a:	03800793          	li	a5,56
    8000502e:	f6f51be3          	bne	a0,a5,80004fa4 <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    80005032:	e1842783          	lw	a5,-488(s0)
    80005036:	4705                	li	a4,1
    80005038:	fae79de3          	bne	a5,a4,80004ff2 <exec+0x31e>
    if(ph.memsz < ph.filesz)
    8000503c:	e4043483          	ld	s1,-448(s0)
    80005040:	e3843783          	ld	a5,-456(s0)
    80005044:	f6f4ede3          	bltu	s1,a5,80004fbe <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005048:	e2843783          	ld	a5,-472(s0)
    8000504c:	94be                	add	s1,s1,a5
    8000504e:	f6f4ebe3          	bltu	s1,a5,80004fc4 <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    80005052:	de043703          	ld	a4,-544(s0)
    80005056:	8ff9                	and	a5,a5,a4
    80005058:	fbad                	bnez	a5,80004fca <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000505a:	e1c42503          	lw	a0,-484(s0)
    8000505e:	00000097          	auipc	ra,0x0
    80005062:	c5c080e7          	jalr	-932(ra) # 80004cba <flags2perm>
    80005066:	86aa                	mv	a3,a0
    80005068:	8626                	mv	a2,s1
    8000506a:	85ca                	mv	a1,s2
    8000506c:	855a                	mv	a0,s6
    8000506e:	ffffc097          	auipc	ra,0xffffc
    80005072:	3a2080e7          	jalr	930(ra) # 80001410 <uvmalloc>
    80005076:	dea43c23          	sd	a0,-520(s0)
    8000507a:	d939                	beqz	a0,80004fd0 <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000507c:	e2843c03          	ld	s8,-472(s0)
    80005080:	e2042c83          	lw	s9,-480(s0)
    80005084:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005088:	f60b83e3          	beqz	s7,80004fee <exec+0x31a>
    8000508c:	89de                	mv	s3,s7
    8000508e:	4481                	li	s1,0
    80005090:	bb9d                	j	80004e06 <exec+0x132>

0000000080005092 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005092:	7179                	addi	sp,sp,-48
    80005094:	f406                	sd	ra,40(sp)
    80005096:	f022                	sd	s0,32(sp)
    80005098:	ec26                	sd	s1,24(sp)
    8000509a:	e84a                	sd	s2,16(sp)
    8000509c:	1800                	addi	s0,sp,48
    8000509e:	892e                	mv	s2,a1
    800050a0:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800050a2:	fdc40593          	addi	a1,s0,-36
    800050a6:	ffffe097          	auipc	ra,0xffffe
    800050aa:	a80080e7          	jalr	-1408(ra) # 80002b26 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800050ae:	fdc42703          	lw	a4,-36(s0)
    800050b2:	47bd                	li	a5,15
    800050b4:	02e7eb63          	bltu	a5,a4,800050ea <argfd+0x58>
    800050b8:	ffffd097          	auipc	ra,0xffffd
    800050bc:	8f4080e7          	jalr	-1804(ra) # 800019ac <myproc>
    800050c0:	fdc42703          	lw	a4,-36(s0)
    800050c4:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffd0e9a>
    800050c8:	078e                	slli	a5,a5,0x3
    800050ca:	953e                	add	a0,a0,a5
    800050cc:	611c                	ld	a5,0(a0)
    800050ce:	c385                	beqz	a5,800050ee <argfd+0x5c>
    return -1;
  if(pfd)
    800050d0:	00090463          	beqz	s2,800050d8 <argfd+0x46>
    *pfd = fd;
    800050d4:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800050d8:	4501                	li	a0,0
  if(pf)
    800050da:	c091                	beqz	s1,800050de <argfd+0x4c>
    *pf = f;
    800050dc:	e09c                	sd	a5,0(s1)
}
    800050de:	70a2                	ld	ra,40(sp)
    800050e0:	7402                	ld	s0,32(sp)
    800050e2:	64e2                	ld	s1,24(sp)
    800050e4:	6942                	ld	s2,16(sp)
    800050e6:	6145                	addi	sp,sp,48
    800050e8:	8082                	ret
    return -1;
    800050ea:	557d                	li	a0,-1
    800050ec:	bfcd                	j	800050de <argfd+0x4c>
    800050ee:	557d                	li	a0,-1
    800050f0:	b7fd                	j	800050de <argfd+0x4c>

00000000800050f2 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800050f2:	1101                	addi	sp,sp,-32
    800050f4:	ec06                	sd	ra,24(sp)
    800050f6:	e822                	sd	s0,16(sp)
    800050f8:	e426                	sd	s1,8(sp)
    800050fa:	1000                	addi	s0,sp,32
    800050fc:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800050fe:	ffffd097          	auipc	ra,0xffffd
    80005102:	8ae080e7          	jalr	-1874(ra) # 800019ac <myproc>
    80005106:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005108:	0d050793          	addi	a5,a0,208
    8000510c:	4501                	li	a0,0
    8000510e:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005110:	6398                	ld	a4,0(a5)
    80005112:	cb19                	beqz	a4,80005128 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005114:	2505                	addiw	a0,a0,1
    80005116:	07a1                	addi	a5,a5,8
    80005118:	fed51ce3          	bne	a0,a3,80005110 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000511c:	557d                	li	a0,-1
}
    8000511e:	60e2                	ld	ra,24(sp)
    80005120:	6442                	ld	s0,16(sp)
    80005122:	64a2                	ld	s1,8(sp)
    80005124:	6105                	addi	sp,sp,32
    80005126:	8082                	ret
      p->ofile[fd] = f;
    80005128:	01a50793          	addi	a5,a0,26
    8000512c:	078e                	slli	a5,a5,0x3
    8000512e:	963e                	add	a2,a2,a5
    80005130:	e204                	sd	s1,0(a2)
      return fd;
    80005132:	b7f5                	j	8000511e <fdalloc+0x2c>

0000000080005134 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005134:	715d                	addi	sp,sp,-80
    80005136:	e486                	sd	ra,72(sp)
    80005138:	e0a2                	sd	s0,64(sp)
    8000513a:	fc26                	sd	s1,56(sp)
    8000513c:	f84a                	sd	s2,48(sp)
    8000513e:	f44e                	sd	s3,40(sp)
    80005140:	f052                	sd	s4,32(sp)
    80005142:	ec56                	sd	s5,24(sp)
    80005144:	e85a                	sd	s6,16(sp)
    80005146:	0880                	addi	s0,sp,80
    80005148:	8b2e                	mv	s6,a1
    8000514a:	89b2                	mv	s3,a2
    8000514c:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000514e:	fb040593          	addi	a1,s0,-80
    80005152:	fffff097          	auipc	ra,0xfffff
    80005156:	e3e080e7          	jalr	-450(ra) # 80003f90 <nameiparent>
    8000515a:	84aa                	mv	s1,a0
    8000515c:	14050f63          	beqz	a0,800052ba <create+0x186>
    return 0;

  ilock(dp);
    80005160:	ffffe097          	auipc	ra,0xffffe
    80005164:	666080e7          	jalr	1638(ra) # 800037c6 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005168:	4601                	li	a2,0
    8000516a:	fb040593          	addi	a1,s0,-80
    8000516e:	8526                	mv	a0,s1
    80005170:	fffff097          	auipc	ra,0xfffff
    80005174:	b3a080e7          	jalr	-1222(ra) # 80003caa <dirlookup>
    80005178:	8aaa                	mv	s5,a0
    8000517a:	c931                	beqz	a0,800051ce <create+0x9a>
    iunlockput(dp);
    8000517c:	8526                	mv	a0,s1
    8000517e:	fffff097          	auipc	ra,0xfffff
    80005182:	8aa080e7          	jalr	-1878(ra) # 80003a28 <iunlockput>
    ilock(ip);
    80005186:	8556                	mv	a0,s5
    80005188:	ffffe097          	auipc	ra,0xffffe
    8000518c:	63e080e7          	jalr	1598(ra) # 800037c6 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005190:	000b059b          	sext.w	a1,s6
    80005194:	4789                	li	a5,2
    80005196:	02f59563          	bne	a1,a5,800051c0 <create+0x8c>
    8000519a:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffd0ec4>
    8000519e:	37f9                	addiw	a5,a5,-2
    800051a0:	17c2                	slli	a5,a5,0x30
    800051a2:	93c1                	srli	a5,a5,0x30
    800051a4:	4705                	li	a4,1
    800051a6:	00f76d63          	bltu	a4,a5,800051c0 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800051aa:	8556                	mv	a0,s5
    800051ac:	60a6                	ld	ra,72(sp)
    800051ae:	6406                	ld	s0,64(sp)
    800051b0:	74e2                	ld	s1,56(sp)
    800051b2:	7942                	ld	s2,48(sp)
    800051b4:	79a2                	ld	s3,40(sp)
    800051b6:	7a02                	ld	s4,32(sp)
    800051b8:	6ae2                	ld	s5,24(sp)
    800051ba:	6b42                	ld	s6,16(sp)
    800051bc:	6161                	addi	sp,sp,80
    800051be:	8082                	ret
    iunlockput(ip);
    800051c0:	8556                	mv	a0,s5
    800051c2:	fffff097          	auipc	ra,0xfffff
    800051c6:	866080e7          	jalr	-1946(ra) # 80003a28 <iunlockput>
    return 0;
    800051ca:	4a81                	li	s5,0
    800051cc:	bff9                	j	800051aa <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800051ce:	85da                	mv	a1,s6
    800051d0:	4088                	lw	a0,0(s1)
    800051d2:	ffffe097          	auipc	ra,0xffffe
    800051d6:	456080e7          	jalr	1110(ra) # 80003628 <ialloc>
    800051da:	8a2a                	mv	s4,a0
    800051dc:	c539                	beqz	a0,8000522a <create+0xf6>
  ilock(ip);
    800051de:	ffffe097          	auipc	ra,0xffffe
    800051e2:	5e8080e7          	jalr	1512(ra) # 800037c6 <ilock>
  ip->major = major;
    800051e6:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800051ea:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800051ee:	4905                	li	s2,1
    800051f0:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    800051f4:	8552                	mv	a0,s4
    800051f6:	ffffe097          	auipc	ra,0xffffe
    800051fa:	504080e7          	jalr	1284(ra) # 800036fa <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800051fe:	000b059b          	sext.w	a1,s6
    80005202:	03258b63          	beq	a1,s2,80005238 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    80005206:	004a2603          	lw	a2,4(s4)
    8000520a:	fb040593          	addi	a1,s0,-80
    8000520e:	8526                	mv	a0,s1
    80005210:	fffff097          	auipc	ra,0xfffff
    80005214:	cb0080e7          	jalr	-848(ra) # 80003ec0 <dirlink>
    80005218:	06054f63          	bltz	a0,80005296 <create+0x162>
  iunlockput(dp);
    8000521c:	8526                	mv	a0,s1
    8000521e:	fffff097          	auipc	ra,0xfffff
    80005222:	80a080e7          	jalr	-2038(ra) # 80003a28 <iunlockput>
  return ip;
    80005226:	8ad2                	mv	s5,s4
    80005228:	b749                	j	800051aa <create+0x76>
    iunlockput(dp);
    8000522a:	8526                	mv	a0,s1
    8000522c:	ffffe097          	auipc	ra,0xffffe
    80005230:	7fc080e7          	jalr	2044(ra) # 80003a28 <iunlockput>
    return 0;
    80005234:	8ad2                	mv	s5,s4
    80005236:	bf95                	j	800051aa <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005238:	004a2603          	lw	a2,4(s4)
    8000523c:	00003597          	auipc	a1,0x3
    80005240:	60c58593          	addi	a1,a1,1548 # 80008848 <syscalls+0x2b0>
    80005244:	8552                	mv	a0,s4
    80005246:	fffff097          	auipc	ra,0xfffff
    8000524a:	c7a080e7          	jalr	-902(ra) # 80003ec0 <dirlink>
    8000524e:	04054463          	bltz	a0,80005296 <create+0x162>
    80005252:	40d0                	lw	a2,4(s1)
    80005254:	00003597          	auipc	a1,0x3
    80005258:	5fc58593          	addi	a1,a1,1532 # 80008850 <syscalls+0x2b8>
    8000525c:	8552                	mv	a0,s4
    8000525e:	fffff097          	auipc	ra,0xfffff
    80005262:	c62080e7          	jalr	-926(ra) # 80003ec0 <dirlink>
    80005266:	02054863          	bltz	a0,80005296 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    8000526a:	004a2603          	lw	a2,4(s4)
    8000526e:	fb040593          	addi	a1,s0,-80
    80005272:	8526                	mv	a0,s1
    80005274:	fffff097          	auipc	ra,0xfffff
    80005278:	c4c080e7          	jalr	-948(ra) # 80003ec0 <dirlink>
    8000527c:	00054d63          	bltz	a0,80005296 <create+0x162>
    dp->nlink++;  // for ".."
    80005280:	04a4d783          	lhu	a5,74(s1)
    80005284:	2785                	addiw	a5,a5,1
    80005286:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000528a:	8526                	mv	a0,s1
    8000528c:	ffffe097          	auipc	ra,0xffffe
    80005290:	46e080e7          	jalr	1134(ra) # 800036fa <iupdate>
    80005294:	b761                	j	8000521c <create+0xe8>
  ip->nlink = 0;
    80005296:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    8000529a:	8552                	mv	a0,s4
    8000529c:	ffffe097          	auipc	ra,0xffffe
    800052a0:	45e080e7          	jalr	1118(ra) # 800036fa <iupdate>
  iunlockput(ip);
    800052a4:	8552                	mv	a0,s4
    800052a6:	ffffe097          	auipc	ra,0xffffe
    800052aa:	782080e7          	jalr	1922(ra) # 80003a28 <iunlockput>
  iunlockput(dp);
    800052ae:	8526                	mv	a0,s1
    800052b0:	ffffe097          	auipc	ra,0xffffe
    800052b4:	778080e7          	jalr	1912(ra) # 80003a28 <iunlockput>
  return 0;
    800052b8:	bdcd                	j	800051aa <create+0x76>
    return 0;
    800052ba:	8aaa                	mv	s5,a0
    800052bc:	b5fd                	j	800051aa <create+0x76>

00000000800052be <sys_dup>:
{
    800052be:	7179                	addi	sp,sp,-48
    800052c0:	f406                	sd	ra,40(sp)
    800052c2:	f022                	sd	s0,32(sp)
    800052c4:	ec26                	sd	s1,24(sp)
    800052c6:	e84a                	sd	s2,16(sp)
    800052c8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800052ca:	fd840613          	addi	a2,s0,-40
    800052ce:	4581                	li	a1,0
    800052d0:	4501                	li	a0,0
    800052d2:	00000097          	auipc	ra,0x0
    800052d6:	dc0080e7          	jalr	-576(ra) # 80005092 <argfd>
    return -1;
    800052da:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800052dc:	02054363          	bltz	a0,80005302 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    800052e0:	fd843903          	ld	s2,-40(s0)
    800052e4:	854a                	mv	a0,s2
    800052e6:	00000097          	auipc	ra,0x0
    800052ea:	e0c080e7          	jalr	-500(ra) # 800050f2 <fdalloc>
    800052ee:	84aa                	mv	s1,a0
    return -1;
    800052f0:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800052f2:	00054863          	bltz	a0,80005302 <sys_dup+0x44>
  filedup(f);
    800052f6:	854a                	mv	a0,s2
    800052f8:	fffff097          	auipc	ra,0xfffff
    800052fc:	310080e7          	jalr	784(ra) # 80004608 <filedup>
  return fd;
    80005300:	87a6                	mv	a5,s1
}
    80005302:	853e                	mv	a0,a5
    80005304:	70a2                	ld	ra,40(sp)
    80005306:	7402                	ld	s0,32(sp)
    80005308:	64e2                	ld	s1,24(sp)
    8000530a:	6942                	ld	s2,16(sp)
    8000530c:	6145                	addi	sp,sp,48
    8000530e:	8082                	ret

0000000080005310 <sys_read>:
{
    80005310:	7179                	addi	sp,sp,-48
    80005312:	f406                	sd	ra,40(sp)
    80005314:	f022                	sd	s0,32(sp)
    80005316:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005318:	fd840593          	addi	a1,s0,-40
    8000531c:	4505                	li	a0,1
    8000531e:	ffffe097          	auipc	ra,0xffffe
    80005322:	828080e7          	jalr	-2008(ra) # 80002b46 <argaddr>
  argint(2, &n);
    80005326:	fe440593          	addi	a1,s0,-28
    8000532a:	4509                	li	a0,2
    8000532c:	ffffd097          	auipc	ra,0xffffd
    80005330:	7fa080e7          	jalr	2042(ra) # 80002b26 <argint>
  if(argfd(0, 0, &f) < 0)
    80005334:	fe840613          	addi	a2,s0,-24
    80005338:	4581                	li	a1,0
    8000533a:	4501                	li	a0,0
    8000533c:	00000097          	auipc	ra,0x0
    80005340:	d56080e7          	jalr	-682(ra) # 80005092 <argfd>
    80005344:	87aa                	mv	a5,a0
    return -1;
    80005346:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005348:	0007cc63          	bltz	a5,80005360 <sys_read+0x50>
  return fileread(f, p, n);
    8000534c:	fe442603          	lw	a2,-28(s0)
    80005350:	fd843583          	ld	a1,-40(s0)
    80005354:	fe843503          	ld	a0,-24(s0)
    80005358:	fffff097          	auipc	ra,0xfffff
    8000535c:	43c080e7          	jalr	1084(ra) # 80004794 <fileread>
}
    80005360:	70a2                	ld	ra,40(sp)
    80005362:	7402                	ld	s0,32(sp)
    80005364:	6145                	addi	sp,sp,48
    80005366:	8082                	ret

0000000080005368 <sys_write>:
{
    80005368:	7179                	addi	sp,sp,-48
    8000536a:	f406                	sd	ra,40(sp)
    8000536c:	f022                	sd	s0,32(sp)
    8000536e:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005370:	fd840593          	addi	a1,s0,-40
    80005374:	4505                	li	a0,1
    80005376:	ffffd097          	auipc	ra,0xffffd
    8000537a:	7d0080e7          	jalr	2000(ra) # 80002b46 <argaddr>
  argint(2, &n);
    8000537e:	fe440593          	addi	a1,s0,-28
    80005382:	4509                	li	a0,2
    80005384:	ffffd097          	auipc	ra,0xffffd
    80005388:	7a2080e7          	jalr	1954(ra) # 80002b26 <argint>
  if(argfd(0, 0, &f) < 0)
    8000538c:	fe840613          	addi	a2,s0,-24
    80005390:	4581                	li	a1,0
    80005392:	4501                	li	a0,0
    80005394:	00000097          	auipc	ra,0x0
    80005398:	cfe080e7          	jalr	-770(ra) # 80005092 <argfd>
    8000539c:	87aa                	mv	a5,a0
    return -1;
    8000539e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800053a0:	0007cc63          	bltz	a5,800053b8 <sys_write+0x50>
  return filewrite(f, p, n);
    800053a4:	fe442603          	lw	a2,-28(s0)
    800053a8:	fd843583          	ld	a1,-40(s0)
    800053ac:	fe843503          	ld	a0,-24(s0)
    800053b0:	fffff097          	auipc	ra,0xfffff
    800053b4:	4a6080e7          	jalr	1190(ra) # 80004856 <filewrite>
}
    800053b8:	70a2                	ld	ra,40(sp)
    800053ba:	7402                	ld	s0,32(sp)
    800053bc:	6145                	addi	sp,sp,48
    800053be:	8082                	ret

00000000800053c0 <sys_close>:
{
    800053c0:	1101                	addi	sp,sp,-32
    800053c2:	ec06                	sd	ra,24(sp)
    800053c4:	e822                	sd	s0,16(sp)
    800053c6:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800053c8:	fe040613          	addi	a2,s0,-32
    800053cc:	fec40593          	addi	a1,s0,-20
    800053d0:	4501                	li	a0,0
    800053d2:	00000097          	auipc	ra,0x0
    800053d6:	cc0080e7          	jalr	-832(ra) # 80005092 <argfd>
    return -1;
    800053da:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800053dc:	02054463          	bltz	a0,80005404 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800053e0:	ffffc097          	auipc	ra,0xffffc
    800053e4:	5cc080e7          	jalr	1484(ra) # 800019ac <myproc>
    800053e8:	fec42783          	lw	a5,-20(s0)
    800053ec:	07e9                	addi	a5,a5,26
    800053ee:	078e                	slli	a5,a5,0x3
    800053f0:	953e                	add	a0,a0,a5
    800053f2:	00053023          	sd	zero,0(a0)
  fileclose(f);
    800053f6:	fe043503          	ld	a0,-32(s0)
    800053fa:	fffff097          	auipc	ra,0xfffff
    800053fe:	260080e7          	jalr	608(ra) # 8000465a <fileclose>
  return 0;
    80005402:	4781                	li	a5,0
}
    80005404:	853e                	mv	a0,a5
    80005406:	60e2                	ld	ra,24(sp)
    80005408:	6442                	ld	s0,16(sp)
    8000540a:	6105                	addi	sp,sp,32
    8000540c:	8082                	ret

000000008000540e <sys_fstat>:
{
    8000540e:	1101                	addi	sp,sp,-32
    80005410:	ec06                	sd	ra,24(sp)
    80005412:	e822                	sd	s0,16(sp)
    80005414:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005416:	fe040593          	addi	a1,s0,-32
    8000541a:	4505                	li	a0,1
    8000541c:	ffffd097          	auipc	ra,0xffffd
    80005420:	72a080e7          	jalr	1834(ra) # 80002b46 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005424:	fe840613          	addi	a2,s0,-24
    80005428:	4581                	li	a1,0
    8000542a:	4501                	li	a0,0
    8000542c:	00000097          	auipc	ra,0x0
    80005430:	c66080e7          	jalr	-922(ra) # 80005092 <argfd>
    80005434:	87aa                	mv	a5,a0
    return -1;
    80005436:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005438:	0007ca63          	bltz	a5,8000544c <sys_fstat+0x3e>
  return filestat(f, st);
    8000543c:	fe043583          	ld	a1,-32(s0)
    80005440:	fe843503          	ld	a0,-24(s0)
    80005444:	fffff097          	auipc	ra,0xfffff
    80005448:	2de080e7          	jalr	734(ra) # 80004722 <filestat>
}
    8000544c:	60e2                	ld	ra,24(sp)
    8000544e:	6442                	ld	s0,16(sp)
    80005450:	6105                	addi	sp,sp,32
    80005452:	8082                	ret

0000000080005454 <sys_link>:
{
    80005454:	7169                	addi	sp,sp,-304
    80005456:	f606                	sd	ra,296(sp)
    80005458:	f222                	sd	s0,288(sp)
    8000545a:	ee26                	sd	s1,280(sp)
    8000545c:	ea4a                	sd	s2,272(sp)
    8000545e:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005460:	08000613          	li	a2,128
    80005464:	ed040593          	addi	a1,s0,-304
    80005468:	4501                	li	a0,0
    8000546a:	ffffd097          	auipc	ra,0xffffd
    8000546e:	6fc080e7          	jalr	1788(ra) # 80002b66 <argstr>
    return -1;
    80005472:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005474:	10054e63          	bltz	a0,80005590 <sys_link+0x13c>
    80005478:	08000613          	li	a2,128
    8000547c:	f5040593          	addi	a1,s0,-176
    80005480:	4505                	li	a0,1
    80005482:	ffffd097          	auipc	ra,0xffffd
    80005486:	6e4080e7          	jalr	1764(ra) # 80002b66 <argstr>
    return -1;
    8000548a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000548c:	10054263          	bltz	a0,80005590 <sys_link+0x13c>
  begin_op();
    80005490:	fffff097          	auipc	ra,0xfffff
    80005494:	d02080e7          	jalr	-766(ra) # 80004192 <begin_op>
  if((ip = namei(old)) == 0){
    80005498:	ed040513          	addi	a0,s0,-304
    8000549c:	fffff097          	auipc	ra,0xfffff
    800054a0:	ad6080e7          	jalr	-1322(ra) # 80003f72 <namei>
    800054a4:	84aa                	mv	s1,a0
    800054a6:	c551                	beqz	a0,80005532 <sys_link+0xde>
  ilock(ip);
    800054a8:	ffffe097          	auipc	ra,0xffffe
    800054ac:	31e080e7          	jalr	798(ra) # 800037c6 <ilock>
  if(ip->type == T_DIR){
    800054b0:	04449703          	lh	a4,68(s1)
    800054b4:	4785                	li	a5,1
    800054b6:	08f70463          	beq	a4,a5,8000553e <sys_link+0xea>
  ip->nlink++;
    800054ba:	04a4d783          	lhu	a5,74(s1)
    800054be:	2785                	addiw	a5,a5,1
    800054c0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054c4:	8526                	mv	a0,s1
    800054c6:	ffffe097          	auipc	ra,0xffffe
    800054ca:	234080e7          	jalr	564(ra) # 800036fa <iupdate>
  iunlock(ip);
    800054ce:	8526                	mv	a0,s1
    800054d0:	ffffe097          	auipc	ra,0xffffe
    800054d4:	3b8080e7          	jalr	952(ra) # 80003888 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800054d8:	fd040593          	addi	a1,s0,-48
    800054dc:	f5040513          	addi	a0,s0,-176
    800054e0:	fffff097          	auipc	ra,0xfffff
    800054e4:	ab0080e7          	jalr	-1360(ra) # 80003f90 <nameiparent>
    800054e8:	892a                	mv	s2,a0
    800054ea:	c935                	beqz	a0,8000555e <sys_link+0x10a>
  ilock(dp);
    800054ec:	ffffe097          	auipc	ra,0xffffe
    800054f0:	2da080e7          	jalr	730(ra) # 800037c6 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800054f4:	00092703          	lw	a4,0(s2)
    800054f8:	409c                	lw	a5,0(s1)
    800054fa:	04f71d63          	bne	a4,a5,80005554 <sys_link+0x100>
    800054fe:	40d0                	lw	a2,4(s1)
    80005500:	fd040593          	addi	a1,s0,-48
    80005504:	854a                	mv	a0,s2
    80005506:	fffff097          	auipc	ra,0xfffff
    8000550a:	9ba080e7          	jalr	-1606(ra) # 80003ec0 <dirlink>
    8000550e:	04054363          	bltz	a0,80005554 <sys_link+0x100>
  iunlockput(dp);
    80005512:	854a                	mv	a0,s2
    80005514:	ffffe097          	auipc	ra,0xffffe
    80005518:	514080e7          	jalr	1300(ra) # 80003a28 <iunlockput>
  iput(ip);
    8000551c:	8526                	mv	a0,s1
    8000551e:	ffffe097          	auipc	ra,0xffffe
    80005522:	462080e7          	jalr	1122(ra) # 80003980 <iput>
  end_op();
    80005526:	fffff097          	auipc	ra,0xfffff
    8000552a:	cea080e7          	jalr	-790(ra) # 80004210 <end_op>
  return 0;
    8000552e:	4781                	li	a5,0
    80005530:	a085                	j	80005590 <sys_link+0x13c>
    end_op();
    80005532:	fffff097          	auipc	ra,0xfffff
    80005536:	cde080e7          	jalr	-802(ra) # 80004210 <end_op>
    return -1;
    8000553a:	57fd                	li	a5,-1
    8000553c:	a891                	j	80005590 <sys_link+0x13c>
    iunlockput(ip);
    8000553e:	8526                	mv	a0,s1
    80005540:	ffffe097          	auipc	ra,0xffffe
    80005544:	4e8080e7          	jalr	1256(ra) # 80003a28 <iunlockput>
    end_op();
    80005548:	fffff097          	auipc	ra,0xfffff
    8000554c:	cc8080e7          	jalr	-824(ra) # 80004210 <end_op>
    return -1;
    80005550:	57fd                	li	a5,-1
    80005552:	a83d                	j	80005590 <sys_link+0x13c>
    iunlockput(dp);
    80005554:	854a                	mv	a0,s2
    80005556:	ffffe097          	auipc	ra,0xffffe
    8000555a:	4d2080e7          	jalr	1234(ra) # 80003a28 <iunlockput>
  ilock(ip);
    8000555e:	8526                	mv	a0,s1
    80005560:	ffffe097          	auipc	ra,0xffffe
    80005564:	266080e7          	jalr	614(ra) # 800037c6 <ilock>
  ip->nlink--;
    80005568:	04a4d783          	lhu	a5,74(s1)
    8000556c:	37fd                	addiw	a5,a5,-1
    8000556e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005572:	8526                	mv	a0,s1
    80005574:	ffffe097          	auipc	ra,0xffffe
    80005578:	186080e7          	jalr	390(ra) # 800036fa <iupdate>
  iunlockput(ip);
    8000557c:	8526                	mv	a0,s1
    8000557e:	ffffe097          	auipc	ra,0xffffe
    80005582:	4aa080e7          	jalr	1194(ra) # 80003a28 <iunlockput>
  end_op();
    80005586:	fffff097          	auipc	ra,0xfffff
    8000558a:	c8a080e7          	jalr	-886(ra) # 80004210 <end_op>
  return -1;
    8000558e:	57fd                	li	a5,-1
}
    80005590:	853e                	mv	a0,a5
    80005592:	70b2                	ld	ra,296(sp)
    80005594:	7412                	ld	s0,288(sp)
    80005596:	64f2                	ld	s1,280(sp)
    80005598:	6952                	ld	s2,272(sp)
    8000559a:	6155                	addi	sp,sp,304
    8000559c:	8082                	ret

000000008000559e <sys_unlink>:
{
    8000559e:	7151                	addi	sp,sp,-240
    800055a0:	f586                	sd	ra,232(sp)
    800055a2:	f1a2                	sd	s0,224(sp)
    800055a4:	eda6                	sd	s1,216(sp)
    800055a6:	e9ca                	sd	s2,208(sp)
    800055a8:	e5ce                	sd	s3,200(sp)
    800055aa:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800055ac:	08000613          	li	a2,128
    800055b0:	f3040593          	addi	a1,s0,-208
    800055b4:	4501                	li	a0,0
    800055b6:	ffffd097          	auipc	ra,0xffffd
    800055ba:	5b0080e7          	jalr	1456(ra) # 80002b66 <argstr>
    800055be:	18054163          	bltz	a0,80005740 <sys_unlink+0x1a2>
  begin_op();
    800055c2:	fffff097          	auipc	ra,0xfffff
    800055c6:	bd0080e7          	jalr	-1072(ra) # 80004192 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800055ca:	fb040593          	addi	a1,s0,-80
    800055ce:	f3040513          	addi	a0,s0,-208
    800055d2:	fffff097          	auipc	ra,0xfffff
    800055d6:	9be080e7          	jalr	-1602(ra) # 80003f90 <nameiparent>
    800055da:	84aa                	mv	s1,a0
    800055dc:	c979                	beqz	a0,800056b2 <sys_unlink+0x114>
  ilock(dp);
    800055de:	ffffe097          	auipc	ra,0xffffe
    800055e2:	1e8080e7          	jalr	488(ra) # 800037c6 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800055e6:	00003597          	auipc	a1,0x3
    800055ea:	26258593          	addi	a1,a1,610 # 80008848 <syscalls+0x2b0>
    800055ee:	fb040513          	addi	a0,s0,-80
    800055f2:	ffffe097          	auipc	ra,0xffffe
    800055f6:	69e080e7          	jalr	1694(ra) # 80003c90 <namecmp>
    800055fa:	14050a63          	beqz	a0,8000574e <sys_unlink+0x1b0>
    800055fe:	00003597          	auipc	a1,0x3
    80005602:	25258593          	addi	a1,a1,594 # 80008850 <syscalls+0x2b8>
    80005606:	fb040513          	addi	a0,s0,-80
    8000560a:	ffffe097          	auipc	ra,0xffffe
    8000560e:	686080e7          	jalr	1670(ra) # 80003c90 <namecmp>
    80005612:	12050e63          	beqz	a0,8000574e <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005616:	f2c40613          	addi	a2,s0,-212
    8000561a:	fb040593          	addi	a1,s0,-80
    8000561e:	8526                	mv	a0,s1
    80005620:	ffffe097          	auipc	ra,0xffffe
    80005624:	68a080e7          	jalr	1674(ra) # 80003caa <dirlookup>
    80005628:	892a                	mv	s2,a0
    8000562a:	12050263          	beqz	a0,8000574e <sys_unlink+0x1b0>
  ilock(ip);
    8000562e:	ffffe097          	auipc	ra,0xffffe
    80005632:	198080e7          	jalr	408(ra) # 800037c6 <ilock>
  if(ip->nlink < 1)
    80005636:	04a91783          	lh	a5,74(s2)
    8000563a:	08f05263          	blez	a5,800056be <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000563e:	04491703          	lh	a4,68(s2)
    80005642:	4785                	li	a5,1
    80005644:	08f70563          	beq	a4,a5,800056ce <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005648:	4641                	li	a2,16
    8000564a:	4581                	li	a1,0
    8000564c:	fc040513          	addi	a0,s0,-64
    80005650:	ffffb097          	auipc	ra,0xffffb
    80005654:	682080e7          	jalr	1666(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005658:	4741                	li	a4,16
    8000565a:	f2c42683          	lw	a3,-212(s0)
    8000565e:	fc040613          	addi	a2,s0,-64
    80005662:	4581                	li	a1,0
    80005664:	8526                	mv	a0,s1
    80005666:	ffffe097          	auipc	ra,0xffffe
    8000566a:	50c080e7          	jalr	1292(ra) # 80003b72 <writei>
    8000566e:	47c1                	li	a5,16
    80005670:	0af51563          	bne	a0,a5,8000571a <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005674:	04491703          	lh	a4,68(s2)
    80005678:	4785                	li	a5,1
    8000567a:	0af70863          	beq	a4,a5,8000572a <sys_unlink+0x18c>
  iunlockput(dp);
    8000567e:	8526                	mv	a0,s1
    80005680:	ffffe097          	auipc	ra,0xffffe
    80005684:	3a8080e7          	jalr	936(ra) # 80003a28 <iunlockput>
  ip->nlink--;
    80005688:	04a95783          	lhu	a5,74(s2)
    8000568c:	37fd                	addiw	a5,a5,-1
    8000568e:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005692:	854a                	mv	a0,s2
    80005694:	ffffe097          	auipc	ra,0xffffe
    80005698:	066080e7          	jalr	102(ra) # 800036fa <iupdate>
  iunlockput(ip);
    8000569c:	854a                	mv	a0,s2
    8000569e:	ffffe097          	auipc	ra,0xffffe
    800056a2:	38a080e7          	jalr	906(ra) # 80003a28 <iunlockput>
  end_op();
    800056a6:	fffff097          	auipc	ra,0xfffff
    800056aa:	b6a080e7          	jalr	-1174(ra) # 80004210 <end_op>
  return 0;
    800056ae:	4501                	li	a0,0
    800056b0:	a84d                	j	80005762 <sys_unlink+0x1c4>
    end_op();
    800056b2:	fffff097          	auipc	ra,0xfffff
    800056b6:	b5e080e7          	jalr	-1186(ra) # 80004210 <end_op>
    return -1;
    800056ba:	557d                	li	a0,-1
    800056bc:	a05d                	j	80005762 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800056be:	00003517          	auipc	a0,0x3
    800056c2:	19a50513          	addi	a0,a0,410 # 80008858 <syscalls+0x2c0>
    800056c6:	ffffb097          	auipc	ra,0xffffb
    800056ca:	e7a080e7          	jalr	-390(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056ce:	04c92703          	lw	a4,76(s2)
    800056d2:	02000793          	li	a5,32
    800056d6:	f6e7f9e3          	bgeu	a5,a4,80005648 <sys_unlink+0xaa>
    800056da:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056de:	4741                	li	a4,16
    800056e0:	86ce                	mv	a3,s3
    800056e2:	f1840613          	addi	a2,s0,-232
    800056e6:	4581                	li	a1,0
    800056e8:	854a                	mv	a0,s2
    800056ea:	ffffe097          	auipc	ra,0xffffe
    800056ee:	390080e7          	jalr	912(ra) # 80003a7a <readi>
    800056f2:	47c1                	li	a5,16
    800056f4:	00f51b63          	bne	a0,a5,8000570a <sys_unlink+0x16c>
    if(de.inum != 0)
    800056f8:	f1845783          	lhu	a5,-232(s0)
    800056fc:	e7a1                	bnez	a5,80005744 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056fe:	29c1                	addiw	s3,s3,16
    80005700:	04c92783          	lw	a5,76(s2)
    80005704:	fcf9ede3          	bltu	s3,a5,800056de <sys_unlink+0x140>
    80005708:	b781                	j	80005648 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000570a:	00003517          	auipc	a0,0x3
    8000570e:	16650513          	addi	a0,a0,358 # 80008870 <syscalls+0x2d8>
    80005712:	ffffb097          	auipc	ra,0xffffb
    80005716:	e2e080e7          	jalr	-466(ra) # 80000540 <panic>
    panic("unlink: writei");
    8000571a:	00003517          	auipc	a0,0x3
    8000571e:	16e50513          	addi	a0,a0,366 # 80008888 <syscalls+0x2f0>
    80005722:	ffffb097          	auipc	ra,0xffffb
    80005726:	e1e080e7          	jalr	-482(ra) # 80000540 <panic>
    dp->nlink--;
    8000572a:	04a4d783          	lhu	a5,74(s1)
    8000572e:	37fd                	addiw	a5,a5,-1
    80005730:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005734:	8526                	mv	a0,s1
    80005736:	ffffe097          	auipc	ra,0xffffe
    8000573a:	fc4080e7          	jalr	-60(ra) # 800036fa <iupdate>
    8000573e:	b781                	j	8000567e <sys_unlink+0xe0>
    return -1;
    80005740:	557d                	li	a0,-1
    80005742:	a005                	j	80005762 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005744:	854a                	mv	a0,s2
    80005746:	ffffe097          	auipc	ra,0xffffe
    8000574a:	2e2080e7          	jalr	738(ra) # 80003a28 <iunlockput>
  iunlockput(dp);
    8000574e:	8526                	mv	a0,s1
    80005750:	ffffe097          	auipc	ra,0xffffe
    80005754:	2d8080e7          	jalr	728(ra) # 80003a28 <iunlockput>
  end_op();
    80005758:	fffff097          	auipc	ra,0xfffff
    8000575c:	ab8080e7          	jalr	-1352(ra) # 80004210 <end_op>
  return -1;
    80005760:	557d                	li	a0,-1
}
    80005762:	70ae                	ld	ra,232(sp)
    80005764:	740e                	ld	s0,224(sp)
    80005766:	64ee                	ld	s1,216(sp)
    80005768:	694e                	ld	s2,208(sp)
    8000576a:	69ae                	ld	s3,200(sp)
    8000576c:	616d                	addi	sp,sp,240
    8000576e:	8082                	ret

0000000080005770 <sys_open>:

uint64
sys_open(void)
{
    80005770:	7131                	addi	sp,sp,-192
    80005772:	fd06                	sd	ra,184(sp)
    80005774:	f922                	sd	s0,176(sp)
    80005776:	f526                	sd	s1,168(sp)
    80005778:	f14a                	sd	s2,160(sp)
    8000577a:	ed4e                	sd	s3,152(sp)
    8000577c:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    8000577e:	f4c40593          	addi	a1,s0,-180
    80005782:	4505                	li	a0,1
    80005784:	ffffd097          	auipc	ra,0xffffd
    80005788:	3a2080e7          	jalr	930(ra) # 80002b26 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000578c:	08000613          	li	a2,128
    80005790:	f5040593          	addi	a1,s0,-176
    80005794:	4501                	li	a0,0
    80005796:	ffffd097          	auipc	ra,0xffffd
    8000579a:	3d0080e7          	jalr	976(ra) # 80002b66 <argstr>
    8000579e:	87aa                	mv	a5,a0
    return -1;
    800057a0:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    800057a2:	0a07c963          	bltz	a5,80005854 <sys_open+0xe4>

  begin_op();
    800057a6:	fffff097          	auipc	ra,0xfffff
    800057aa:	9ec080e7          	jalr	-1556(ra) # 80004192 <begin_op>

  if(omode & O_CREATE){
    800057ae:	f4c42783          	lw	a5,-180(s0)
    800057b2:	2007f793          	andi	a5,a5,512
    800057b6:	cfc5                	beqz	a5,8000586e <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800057b8:	4681                	li	a3,0
    800057ba:	4601                	li	a2,0
    800057bc:	4589                	li	a1,2
    800057be:	f5040513          	addi	a0,s0,-176
    800057c2:	00000097          	auipc	ra,0x0
    800057c6:	972080e7          	jalr	-1678(ra) # 80005134 <create>
    800057ca:	84aa                	mv	s1,a0
    if(ip == 0){
    800057cc:	c959                	beqz	a0,80005862 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800057ce:	04449703          	lh	a4,68(s1)
    800057d2:	478d                	li	a5,3
    800057d4:	00f71763          	bne	a4,a5,800057e2 <sys_open+0x72>
    800057d8:	0464d703          	lhu	a4,70(s1)
    800057dc:	47a5                	li	a5,9
    800057de:	0ce7ed63          	bltu	a5,a4,800058b8 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800057e2:	fffff097          	auipc	ra,0xfffff
    800057e6:	dbc080e7          	jalr	-580(ra) # 8000459e <filealloc>
    800057ea:	89aa                	mv	s3,a0
    800057ec:	10050363          	beqz	a0,800058f2 <sys_open+0x182>
    800057f0:	00000097          	auipc	ra,0x0
    800057f4:	902080e7          	jalr	-1790(ra) # 800050f2 <fdalloc>
    800057f8:	892a                	mv	s2,a0
    800057fa:	0e054763          	bltz	a0,800058e8 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800057fe:	04449703          	lh	a4,68(s1)
    80005802:	478d                	li	a5,3
    80005804:	0cf70563          	beq	a4,a5,800058ce <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005808:	4789                	li	a5,2
    8000580a:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000580e:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005812:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005816:	f4c42783          	lw	a5,-180(s0)
    8000581a:	0017c713          	xori	a4,a5,1
    8000581e:	8b05                	andi	a4,a4,1
    80005820:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005824:	0037f713          	andi	a4,a5,3
    80005828:	00e03733          	snez	a4,a4
    8000582c:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005830:	4007f793          	andi	a5,a5,1024
    80005834:	c791                	beqz	a5,80005840 <sys_open+0xd0>
    80005836:	04449703          	lh	a4,68(s1)
    8000583a:	4789                	li	a5,2
    8000583c:	0af70063          	beq	a4,a5,800058dc <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005840:	8526                	mv	a0,s1
    80005842:	ffffe097          	auipc	ra,0xffffe
    80005846:	046080e7          	jalr	70(ra) # 80003888 <iunlock>
  end_op();
    8000584a:	fffff097          	auipc	ra,0xfffff
    8000584e:	9c6080e7          	jalr	-1594(ra) # 80004210 <end_op>

  return fd;
    80005852:	854a                	mv	a0,s2
}
    80005854:	70ea                	ld	ra,184(sp)
    80005856:	744a                	ld	s0,176(sp)
    80005858:	74aa                	ld	s1,168(sp)
    8000585a:	790a                	ld	s2,160(sp)
    8000585c:	69ea                	ld	s3,152(sp)
    8000585e:	6129                	addi	sp,sp,192
    80005860:	8082                	ret
      end_op();
    80005862:	fffff097          	auipc	ra,0xfffff
    80005866:	9ae080e7          	jalr	-1618(ra) # 80004210 <end_op>
      return -1;
    8000586a:	557d                	li	a0,-1
    8000586c:	b7e5                	j	80005854 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000586e:	f5040513          	addi	a0,s0,-176
    80005872:	ffffe097          	auipc	ra,0xffffe
    80005876:	700080e7          	jalr	1792(ra) # 80003f72 <namei>
    8000587a:	84aa                	mv	s1,a0
    8000587c:	c905                	beqz	a0,800058ac <sys_open+0x13c>
    ilock(ip);
    8000587e:	ffffe097          	auipc	ra,0xffffe
    80005882:	f48080e7          	jalr	-184(ra) # 800037c6 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005886:	04449703          	lh	a4,68(s1)
    8000588a:	4785                	li	a5,1
    8000588c:	f4f711e3          	bne	a4,a5,800057ce <sys_open+0x5e>
    80005890:	f4c42783          	lw	a5,-180(s0)
    80005894:	d7b9                	beqz	a5,800057e2 <sys_open+0x72>
      iunlockput(ip);
    80005896:	8526                	mv	a0,s1
    80005898:	ffffe097          	auipc	ra,0xffffe
    8000589c:	190080e7          	jalr	400(ra) # 80003a28 <iunlockput>
      end_op();
    800058a0:	fffff097          	auipc	ra,0xfffff
    800058a4:	970080e7          	jalr	-1680(ra) # 80004210 <end_op>
      return -1;
    800058a8:	557d                	li	a0,-1
    800058aa:	b76d                	j	80005854 <sys_open+0xe4>
      end_op();
    800058ac:	fffff097          	auipc	ra,0xfffff
    800058b0:	964080e7          	jalr	-1692(ra) # 80004210 <end_op>
      return -1;
    800058b4:	557d                	li	a0,-1
    800058b6:	bf79                	j	80005854 <sys_open+0xe4>
    iunlockput(ip);
    800058b8:	8526                	mv	a0,s1
    800058ba:	ffffe097          	auipc	ra,0xffffe
    800058be:	16e080e7          	jalr	366(ra) # 80003a28 <iunlockput>
    end_op();
    800058c2:	fffff097          	auipc	ra,0xfffff
    800058c6:	94e080e7          	jalr	-1714(ra) # 80004210 <end_op>
    return -1;
    800058ca:	557d                	li	a0,-1
    800058cc:	b761                	j	80005854 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800058ce:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800058d2:	04649783          	lh	a5,70(s1)
    800058d6:	02f99223          	sh	a5,36(s3)
    800058da:	bf25                	j	80005812 <sys_open+0xa2>
    itrunc(ip);
    800058dc:	8526                	mv	a0,s1
    800058de:	ffffe097          	auipc	ra,0xffffe
    800058e2:	ff6080e7          	jalr	-10(ra) # 800038d4 <itrunc>
    800058e6:	bfa9                	j	80005840 <sys_open+0xd0>
      fileclose(f);
    800058e8:	854e                	mv	a0,s3
    800058ea:	fffff097          	auipc	ra,0xfffff
    800058ee:	d70080e7          	jalr	-656(ra) # 8000465a <fileclose>
    iunlockput(ip);
    800058f2:	8526                	mv	a0,s1
    800058f4:	ffffe097          	auipc	ra,0xffffe
    800058f8:	134080e7          	jalr	308(ra) # 80003a28 <iunlockput>
    end_op();
    800058fc:	fffff097          	auipc	ra,0xfffff
    80005900:	914080e7          	jalr	-1772(ra) # 80004210 <end_op>
    return -1;
    80005904:	557d                	li	a0,-1
    80005906:	b7b9                	j	80005854 <sys_open+0xe4>

0000000080005908 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005908:	7175                	addi	sp,sp,-144
    8000590a:	e506                	sd	ra,136(sp)
    8000590c:	e122                	sd	s0,128(sp)
    8000590e:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005910:	fffff097          	auipc	ra,0xfffff
    80005914:	882080e7          	jalr	-1918(ra) # 80004192 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005918:	08000613          	li	a2,128
    8000591c:	f7040593          	addi	a1,s0,-144
    80005920:	4501                	li	a0,0
    80005922:	ffffd097          	auipc	ra,0xffffd
    80005926:	244080e7          	jalr	580(ra) # 80002b66 <argstr>
    8000592a:	02054963          	bltz	a0,8000595c <sys_mkdir+0x54>
    8000592e:	4681                	li	a3,0
    80005930:	4601                	li	a2,0
    80005932:	4585                	li	a1,1
    80005934:	f7040513          	addi	a0,s0,-144
    80005938:	fffff097          	auipc	ra,0xfffff
    8000593c:	7fc080e7          	jalr	2044(ra) # 80005134 <create>
    80005940:	cd11                	beqz	a0,8000595c <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005942:	ffffe097          	auipc	ra,0xffffe
    80005946:	0e6080e7          	jalr	230(ra) # 80003a28 <iunlockput>
  end_op();
    8000594a:	fffff097          	auipc	ra,0xfffff
    8000594e:	8c6080e7          	jalr	-1850(ra) # 80004210 <end_op>
  return 0;
    80005952:	4501                	li	a0,0
}
    80005954:	60aa                	ld	ra,136(sp)
    80005956:	640a                	ld	s0,128(sp)
    80005958:	6149                	addi	sp,sp,144
    8000595a:	8082                	ret
    end_op();
    8000595c:	fffff097          	auipc	ra,0xfffff
    80005960:	8b4080e7          	jalr	-1868(ra) # 80004210 <end_op>
    return -1;
    80005964:	557d                	li	a0,-1
    80005966:	b7fd                	j	80005954 <sys_mkdir+0x4c>

0000000080005968 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005968:	7135                	addi	sp,sp,-160
    8000596a:	ed06                	sd	ra,152(sp)
    8000596c:	e922                	sd	s0,144(sp)
    8000596e:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005970:	fffff097          	auipc	ra,0xfffff
    80005974:	822080e7          	jalr	-2014(ra) # 80004192 <begin_op>
  argint(1, &major);
    80005978:	f6c40593          	addi	a1,s0,-148
    8000597c:	4505                	li	a0,1
    8000597e:	ffffd097          	auipc	ra,0xffffd
    80005982:	1a8080e7          	jalr	424(ra) # 80002b26 <argint>
  argint(2, &minor);
    80005986:	f6840593          	addi	a1,s0,-152
    8000598a:	4509                	li	a0,2
    8000598c:	ffffd097          	auipc	ra,0xffffd
    80005990:	19a080e7          	jalr	410(ra) # 80002b26 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005994:	08000613          	li	a2,128
    80005998:	f7040593          	addi	a1,s0,-144
    8000599c:	4501                	li	a0,0
    8000599e:	ffffd097          	auipc	ra,0xffffd
    800059a2:	1c8080e7          	jalr	456(ra) # 80002b66 <argstr>
    800059a6:	02054b63          	bltz	a0,800059dc <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800059aa:	f6841683          	lh	a3,-152(s0)
    800059ae:	f6c41603          	lh	a2,-148(s0)
    800059b2:	458d                	li	a1,3
    800059b4:	f7040513          	addi	a0,s0,-144
    800059b8:	fffff097          	auipc	ra,0xfffff
    800059bc:	77c080e7          	jalr	1916(ra) # 80005134 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059c0:	cd11                	beqz	a0,800059dc <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800059c2:	ffffe097          	auipc	ra,0xffffe
    800059c6:	066080e7          	jalr	102(ra) # 80003a28 <iunlockput>
  end_op();
    800059ca:	fffff097          	auipc	ra,0xfffff
    800059ce:	846080e7          	jalr	-1978(ra) # 80004210 <end_op>
  return 0;
    800059d2:	4501                	li	a0,0
}
    800059d4:	60ea                	ld	ra,152(sp)
    800059d6:	644a                	ld	s0,144(sp)
    800059d8:	610d                	addi	sp,sp,160
    800059da:	8082                	ret
    end_op();
    800059dc:	fffff097          	auipc	ra,0xfffff
    800059e0:	834080e7          	jalr	-1996(ra) # 80004210 <end_op>
    return -1;
    800059e4:	557d                	li	a0,-1
    800059e6:	b7fd                	j	800059d4 <sys_mknod+0x6c>

00000000800059e8 <sys_chdir>:

uint64
sys_chdir(void)
{
    800059e8:	7135                	addi	sp,sp,-160
    800059ea:	ed06                	sd	ra,152(sp)
    800059ec:	e922                	sd	s0,144(sp)
    800059ee:	e526                	sd	s1,136(sp)
    800059f0:	e14a                	sd	s2,128(sp)
    800059f2:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800059f4:	ffffc097          	auipc	ra,0xffffc
    800059f8:	fb8080e7          	jalr	-72(ra) # 800019ac <myproc>
    800059fc:	892a                	mv	s2,a0
  
  begin_op();
    800059fe:	ffffe097          	auipc	ra,0xffffe
    80005a02:	794080e7          	jalr	1940(ra) # 80004192 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005a06:	08000613          	li	a2,128
    80005a0a:	f6040593          	addi	a1,s0,-160
    80005a0e:	4501                	li	a0,0
    80005a10:	ffffd097          	auipc	ra,0xffffd
    80005a14:	156080e7          	jalr	342(ra) # 80002b66 <argstr>
    80005a18:	04054b63          	bltz	a0,80005a6e <sys_chdir+0x86>
    80005a1c:	f6040513          	addi	a0,s0,-160
    80005a20:	ffffe097          	auipc	ra,0xffffe
    80005a24:	552080e7          	jalr	1362(ra) # 80003f72 <namei>
    80005a28:	84aa                	mv	s1,a0
    80005a2a:	c131                	beqz	a0,80005a6e <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a2c:	ffffe097          	auipc	ra,0xffffe
    80005a30:	d9a080e7          	jalr	-614(ra) # 800037c6 <ilock>
  if(ip->type != T_DIR){
    80005a34:	04449703          	lh	a4,68(s1)
    80005a38:	4785                	li	a5,1
    80005a3a:	04f71063          	bne	a4,a5,80005a7a <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a3e:	8526                	mv	a0,s1
    80005a40:	ffffe097          	auipc	ra,0xffffe
    80005a44:	e48080e7          	jalr	-440(ra) # 80003888 <iunlock>
  iput(p->cwd);
    80005a48:	15093503          	ld	a0,336(s2)
    80005a4c:	ffffe097          	auipc	ra,0xffffe
    80005a50:	f34080e7          	jalr	-204(ra) # 80003980 <iput>
  end_op();
    80005a54:	ffffe097          	auipc	ra,0xffffe
    80005a58:	7bc080e7          	jalr	1980(ra) # 80004210 <end_op>
  p->cwd = ip;
    80005a5c:	14993823          	sd	s1,336(s2)
  return 0;
    80005a60:	4501                	li	a0,0
}
    80005a62:	60ea                	ld	ra,152(sp)
    80005a64:	644a                	ld	s0,144(sp)
    80005a66:	64aa                	ld	s1,136(sp)
    80005a68:	690a                	ld	s2,128(sp)
    80005a6a:	610d                	addi	sp,sp,160
    80005a6c:	8082                	ret
    end_op();
    80005a6e:	ffffe097          	auipc	ra,0xffffe
    80005a72:	7a2080e7          	jalr	1954(ra) # 80004210 <end_op>
    return -1;
    80005a76:	557d                	li	a0,-1
    80005a78:	b7ed                	j	80005a62 <sys_chdir+0x7a>
    iunlockput(ip);
    80005a7a:	8526                	mv	a0,s1
    80005a7c:	ffffe097          	auipc	ra,0xffffe
    80005a80:	fac080e7          	jalr	-84(ra) # 80003a28 <iunlockput>
    end_op();
    80005a84:	ffffe097          	auipc	ra,0xffffe
    80005a88:	78c080e7          	jalr	1932(ra) # 80004210 <end_op>
    return -1;
    80005a8c:	557d                	li	a0,-1
    80005a8e:	bfd1                	j	80005a62 <sys_chdir+0x7a>

0000000080005a90 <sys_exec>:

uint64
sys_exec(void)
{
    80005a90:	7145                	addi	sp,sp,-464
    80005a92:	e786                	sd	ra,456(sp)
    80005a94:	e3a2                	sd	s0,448(sp)
    80005a96:	ff26                	sd	s1,440(sp)
    80005a98:	fb4a                	sd	s2,432(sp)
    80005a9a:	f74e                	sd	s3,424(sp)
    80005a9c:	f352                	sd	s4,416(sp)
    80005a9e:	ef56                	sd	s5,408(sp)
    80005aa0:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005aa2:	e3840593          	addi	a1,s0,-456
    80005aa6:	4505                	li	a0,1
    80005aa8:	ffffd097          	auipc	ra,0xffffd
    80005aac:	09e080e7          	jalr	158(ra) # 80002b46 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005ab0:	08000613          	li	a2,128
    80005ab4:	f4040593          	addi	a1,s0,-192
    80005ab8:	4501                	li	a0,0
    80005aba:	ffffd097          	auipc	ra,0xffffd
    80005abe:	0ac080e7          	jalr	172(ra) # 80002b66 <argstr>
    80005ac2:	87aa                	mv	a5,a0
    return -1;
    80005ac4:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005ac6:	0c07c363          	bltz	a5,80005b8c <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005aca:	10000613          	li	a2,256
    80005ace:	4581                	li	a1,0
    80005ad0:	e4040513          	addi	a0,s0,-448
    80005ad4:	ffffb097          	auipc	ra,0xffffb
    80005ad8:	1fe080e7          	jalr	510(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005adc:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005ae0:	89a6                	mv	s3,s1
    80005ae2:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005ae4:	02000a13          	li	s4,32
    80005ae8:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005aec:	00391513          	slli	a0,s2,0x3
    80005af0:	e3040593          	addi	a1,s0,-464
    80005af4:	e3843783          	ld	a5,-456(s0)
    80005af8:	953e                	add	a0,a0,a5
    80005afa:	ffffd097          	auipc	ra,0xffffd
    80005afe:	f8e080e7          	jalr	-114(ra) # 80002a88 <fetchaddr>
    80005b02:	02054a63          	bltz	a0,80005b36 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005b06:	e3043783          	ld	a5,-464(s0)
    80005b0a:	c3b9                	beqz	a5,80005b50 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005b0c:	ffffb097          	auipc	ra,0xffffb
    80005b10:	fda080e7          	jalr	-38(ra) # 80000ae6 <kalloc>
    80005b14:	85aa                	mv	a1,a0
    80005b16:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005b1a:	cd11                	beqz	a0,80005b36 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005b1c:	6605                	lui	a2,0x1
    80005b1e:	e3043503          	ld	a0,-464(s0)
    80005b22:	ffffd097          	auipc	ra,0xffffd
    80005b26:	fb8080e7          	jalr	-72(ra) # 80002ada <fetchstr>
    80005b2a:	00054663          	bltz	a0,80005b36 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005b2e:	0905                	addi	s2,s2,1
    80005b30:	09a1                	addi	s3,s3,8
    80005b32:	fb491be3          	bne	s2,s4,80005ae8 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b36:	f4040913          	addi	s2,s0,-192
    80005b3a:	6088                	ld	a0,0(s1)
    80005b3c:	c539                	beqz	a0,80005b8a <sys_exec+0xfa>
    kfree(argv[i]);
    80005b3e:	ffffb097          	auipc	ra,0xffffb
    80005b42:	eaa080e7          	jalr	-342(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b46:	04a1                	addi	s1,s1,8
    80005b48:	ff2499e3          	bne	s1,s2,80005b3a <sys_exec+0xaa>
  return -1;
    80005b4c:	557d                	li	a0,-1
    80005b4e:	a83d                	j	80005b8c <sys_exec+0xfc>
      argv[i] = 0;
    80005b50:	0a8e                	slli	s5,s5,0x3
    80005b52:	fc0a8793          	addi	a5,s5,-64
    80005b56:	00878ab3          	add	s5,a5,s0
    80005b5a:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005b5e:	e4040593          	addi	a1,s0,-448
    80005b62:	f4040513          	addi	a0,s0,-192
    80005b66:	fffff097          	auipc	ra,0xfffff
    80005b6a:	16e080e7          	jalr	366(ra) # 80004cd4 <exec>
    80005b6e:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b70:	f4040993          	addi	s3,s0,-192
    80005b74:	6088                	ld	a0,0(s1)
    80005b76:	c901                	beqz	a0,80005b86 <sys_exec+0xf6>
    kfree(argv[i]);
    80005b78:	ffffb097          	auipc	ra,0xffffb
    80005b7c:	e70080e7          	jalr	-400(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b80:	04a1                	addi	s1,s1,8
    80005b82:	ff3499e3          	bne	s1,s3,80005b74 <sys_exec+0xe4>
  return ret;
    80005b86:	854a                	mv	a0,s2
    80005b88:	a011                	j	80005b8c <sys_exec+0xfc>
  return -1;
    80005b8a:	557d                	li	a0,-1
}
    80005b8c:	60be                	ld	ra,456(sp)
    80005b8e:	641e                	ld	s0,448(sp)
    80005b90:	74fa                	ld	s1,440(sp)
    80005b92:	795a                	ld	s2,432(sp)
    80005b94:	79ba                	ld	s3,424(sp)
    80005b96:	7a1a                	ld	s4,416(sp)
    80005b98:	6afa                	ld	s5,408(sp)
    80005b9a:	6179                	addi	sp,sp,464
    80005b9c:	8082                	ret

0000000080005b9e <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b9e:	7139                	addi	sp,sp,-64
    80005ba0:	fc06                	sd	ra,56(sp)
    80005ba2:	f822                	sd	s0,48(sp)
    80005ba4:	f426                	sd	s1,40(sp)
    80005ba6:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005ba8:	ffffc097          	auipc	ra,0xffffc
    80005bac:	e04080e7          	jalr	-508(ra) # 800019ac <myproc>
    80005bb0:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005bb2:	fd840593          	addi	a1,s0,-40
    80005bb6:	4501                	li	a0,0
    80005bb8:	ffffd097          	auipc	ra,0xffffd
    80005bbc:	f8e080e7          	jalr	-114(ra) # 80002b46 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005bc0:	fc840593          	addi	a1,s0,-56
    80005bc4:	fd040513          	addi	a0,s0,-48
    80005bc8:	fffff097          	auipc	ra,0xfffff
    80005bcc:	dc2080e7          	jalr	-574(ra) # 8000498a <pipealloc>
    return -1;
    80005bd0:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005bd2:	0c054463          	bltz	a0,80005c9a <sys_pipe+0xfc>
  fd0 = -1;
    80005bd6:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005bda:	fd043503          	ld	a0,-48(s0)
    80005bde:	fffff097          	auipc	ra,0xfffff
    80005be2:	514080e7          	jalr	1300(ra) # 800050f2 <fdalloc>
    80005be6:	fca42223          	sw	a0,-60(s0)
    80005bea:	08054b63          	bltz	a0,80005c80 <sys_pipe+0xe2>
    80005bee:	fc843503          	ld	a0,-56(s0)
    80005bf2:	fffff097          	auipc	ra,0xfffff
    80005bf6:	500080e7          	jalr	1280(ra) # 800050f2 <fdalloc>
    80005bfa:	fca42023          	sw	a0,-64(s0)
    80005bfe:	06054863          	bltz	a0,80005c6e <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c02:	4691                	li	a3,4
    80005c04:	fc440613          	addi	a2,s0,-60
    80005c08:	fd843583          	ld	a1,-40(s0)
    80005c0c:	68a8                	ld	a0,80(s1)
    80005c0e:	ffffc097          	auipc	ra,0xffffc
    80005c12:	a5e080e7          	jalr	-1442(ra) # 8000166c <copyout>
    80005c16:	02054063          	bltz	a0,80005c36 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005c1a:	4691                	li	a3,4
    80005c1c:	fc040613          	addi	a2,s0,-64
    80005c20:	fd843583          	ld	a1,-40(s0)
    80005c24:	0591                	addi	a1,a1,4
    80005c26:	68a8                	ld	a0,80(s1)
    80005c28:	ffffc097          	auipc	ra,0xffffc
    80005c2c:	a44080e7          	jalr	-1468(ra) # 8000166c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005c30:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c32:	06055463          	bgez	a0,80005c9a <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005c36:	fc442783          	lw	a5,-60(s0)
    80005c3a:	07e9                	addi	a5,a5,26
    80005c3c:	078e                	slli	a5,a5,0x3
    80005c3e:	97a6                	add	a5,a5,s1
    80005c40:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c44:	fc042783          	lw	a5,-64(s0)
    80005c48:	07e9                	addi	a5,a5,26
    80005c4a:	078e                	slli	a5,a5,0x3
    80005c4c:	94be                	add	s1,s1,a5
    80005c4e:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005c52:	fd043503          	ld	a0,-48(s0)
    80005c56:	fffff097          	auipc	ra,0xfffff
    80005c5a:	a04080e7          	jalr	-1532(ra) # 8000465a <fileclose>
    fileclose(wf);
    80005c5e:	fc843503          	ld	a0,-56(s0)
    80005c62:	fffff097          	auipc	ra,0xfffff
    80005c66:	9f8080e7          	jalr	-1544(ra) # 8000465a <fileclose>
    return -1;
    80005c6a:	57fd                	li	a5,-1
    80005c6c:	a03d                	j	80005c9a <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005c6e:	fc442783          	lw	a5,-60(s0)
    80005c72:	0007c763          	bltz	a5,80005c80 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005c76:	07e9                	addi	a5,a5,26
    80005c78:	078e                	slli	a5,a5,0x3
    80005c7a:	97a6                	add	a5,a5,s1
    80005c7c:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005c80:	fd043503          	ld	a0,-48(s0)
    80005c84:	fffff097          	auipc	ra,0xfffff
    80005c88:	9d6080e7          	jalr	-1578(ra) # 8000465a <fileclose>
    fileclose(wf);
    80005c8c:	fc843503          	ld	a0,-56(s0)
    80005c90:	fffff097          	auipc	ra,0xfffff
    80005c94:	9ca080e7          	jalr	-1590(ra) # 8000465a <fileclose>
    return -1;
    80005c98:	57fd                	li	a5,-1
}
    80005c9a:	853e                	mv	a0,a5
    80005c9c:	70e2                	ld	ra,56(sp)
    80005c9e:	7442                	ld	s0,48(sp)
    80005ca0:	74a2                	ld	s1,40(sp)
    80005ca2:	6121                	addi	sp,sp,64
    80005ca4:	8082                	ret
	...

0000000080005cb0 <kernelvec>:
    80005cb0:	7111                	addi	sp,sp,-256
    80005cb2:	e006                	sd	ra,0(sp)
    80005cb4:	e40a                	sd	sp,8(sp)
    80005cb6:	e80e                	sd	gp,16(sp)
    80005cb8:	ec12                	sd	tp,24(sp)
    80005cba:	f016                	sd	t0,32(sp)
    80005cbc:	f41a                	sd	t1,40(sp)
    80005cbe:	f81e                	sd	t2,48(sp)
    80005cc0:	fc22                	sd	s0,56(sp)
    80005cc2:	e0a6                	sd	s1,64(sp)
    80005cc4:	e4aa                	sd	a0,72(sp)
    80005cc6:	e8ae                	sd	a1,80(sp)
    80005cc8:	ecb2                	sd	a2,88(sp)
    80005cca:	f0b6                	sd	a3,96(sp)
    80005ccc:	f4ba                	sd	a4,104(sp)
    80005cce:	f8be                	sd	a5,112(sp)
    80005cd0:	fcc2                	sd	a6,120(sp)
    80005cd2:	e146                	sd	a7,128(sp)
    80005cd4:	e54a                	sd	s2,136(sp)
    80005cd6:	e94e                	sd	s3,144(sp)
    80005cd8:	ed52                	sd	s4,152(sp)
    80005cda:	f156                	sd	s5,160(sp)
    80005cdc:	f55a                	sd	s6,168(sp)
    80005cde:	f95e                	sd	s7,176(sp)
    80005ce0:	fd62                	sd	s8,184(sp)
    80005ce2:	e1e6                	sd	s9,192(sp)
    80005ce4:	e5ea                	sd	s10,200(sp)
    80005ce6:	e9ee                	sd	s11,208(sp)
    80005ce8:	edf2                	sd	t3,216(sp)
    80005cea:	f1f6                	sd	t4,224(sp)
    80005cec:	f5fa                	sd	t5,232(sp)
    80005cee:	f9fe                	sd	t6,240(sp)
    80005cf0:	c65fc0ef          	jal	ra,80002954 <kerneltrap>
    80005cf4:	6082                	ld	ra,0(sp)
    80005cf6:	6122                	ld	sp,8(sp)
    80005cf8:	61c2                	ld	gp,16(sp)
    80005cfa:	7282                	ld	t0,32(sp)
    80005cfc:	7322                	ld	t1,40(sp)
    80005cfe:	73c2                	ld	t2,48(sp)
    80005d00:	7462                	ld	s0,56(sp)
    80005d02:	6486                	ld	s1,64(sp)
    80005d04:	6526                	ld	a0,72(sp)
    80005d06:	65c6                	ld	a1,80(sp)
    80005d08:	6666                	ld	a2,88(sp)
    80005d0a:	7686                	ld	a3,96(sp)
    80005d0c:	7726                	ld	a4,104(sp)
    80005d0e:	77c6                	ld	a5,112(sp)
    80005d10:	7866                	ld	a6,120(sp)
    80005d12:	688a                	ld	a7,128(sp)
    80005d14:	692a                	ld	s2,136(sp)
    80005d16:	69ca                	ld	s3,144(sp)
    80005d18:	6a6a                	ld	s4,152(sp)
    80005d1a:	7a8a                	ld	s5,160(sp)
    80005d1c:	7b2a                	ld	s6,168(sp)
    80005d1e:	7bca                	ld	s7,176(sp)
    80005d20:	7c6a                	ld	s8,184(sp)
    80005d22:	6c8e                	ld	s9,192(sp)
    80005d24:	6d2e                	ld	s10,200(sp)
    80005d26:	6dce                	ld	s11,208(sp)
    80005d28:	6e6e                	ld	t3,216(sp)
    80005d2a:	7e8e                	ld	t4,224(sp)
    80005d2c:	7f2e                	ld	t5,232(sp)
    80005d2e:	7fce                	ld	t6,240(sp)
    80005d30:	6111                	addi	sp,sp,256
    80005d32:	10200073          	sret
    80005d36:	00000013          	nop
    80005d3a:	00000013          	nop
    80005d3e:	0001                	nop

0000000080005d40 <timervec>:
    80005d40:	34051573          	csrrw	a0,mscratch,a0
    80005d44:	e10c                	sd	a1,0(a0)
    80005d46:	e510                	sd	a2,8(a0)
    80005d48:	e914                	sd	a3,16(a0)
    80005d4a:	6d0c                	ld	a1,24(a0)
    80005d4c:	7110                	ld	a2,32(a0)
    80005d4e:	6194                	ld	a3,0(a1)
    80005d50:	96b2                	add	a3,a3,a2
    80005d52:	e194                	sd	a3,0(a1)
    80005d54:	4589                	li	a1,2
    80005d56:	14459073          	csrw	sip,a1
    80005d5a:	6914                	ld	a3,16(a0)
    80005d5c:	6510                	ld	a2,8(a0)
    80005d5e:	610c                	ld	a1,0(a0)
    80005d60:	34051573          	csrrw	a0,mscratch,a0
    80005d64:	30200073          	mret
	...

0000000080005d6a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d6a:	1141                	addi	sp,sp,-16
    80005d6c:	e422                	sd	s0,8(sp)
    80005d6e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d70:	0c0007b7          	lui	a5,0xc000
    80005d74:	4705                	li	a4,1
    80005d76:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d78:	c3d8                	sw	a4,4(a5)
}
    80005d7a:	6422                	ld	s0,8(sp)
    80005d7c:	0141                	addi	sp,sp,16
    80005d7e:	8082                	ret

0000000080005d80 <plicinithart>:

void
plicinithart(void)
{
    80005d80:	1141                	addi	sp,sp,-16
    80005d82:	e406                	sd	ra,8(sp)
    80005d84:	e022                	sd	s0,0(sp)
    80005d86:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d88:	ffffc097          	auipc	ra,0xffffc
    80005d8c:	bf8080e7          	jalr	-1032(ra) # 80001980 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d90:	0085171b          	slliw	a4,a0,0x8
    80005d94:	0c0027b7          	lui	a5,0xc002
    80005d98:	97ba                	add	a5,a5,a4
    80005d9a:	40200713          	li	a4,1026
    80005d9e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005da2:	00d5151b          	slliw	a0,a0,0xd
    80005da6:	0c2017b7          	lui	a5,0xc201
    80005daa:	97aa                	add	a5,a5,a0
    80005dac:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005db0:	60a2                	ld	ra,8(sp)
    80005db2:	6402                	ld	s0,0(sp)
    80005db4:	0141                	addi	sp,sp,16
    80005db6:	8082                	ret

0000000080005db8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005db8:	1141                	addi	sp,sp,-16
    80005dba:	e406                	sd	ra,8(sp)
    80005dbc:	e022                	sd	s0,0(sp)
    80005dbe:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005dc0:	ffffc097          	auipc	ra,0xffffc
    80005dc4:	bc0080e7          	jalr	-1088(ra) # 80001980 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005dc8:	00d5151b          	slliw	a0,a0,0xd
    80005dcc:	0c2017b7          	lui	a5,0xc201
    80005dd0:	97aa                	add	a5,a5,a0
  return irq;
}
    80005dd2:	43c8                	lw	a0,4(a5)
    80005dd4:	60a2                	ld	ra,8(sp)
    80005dd6:	6402                	ld	s0,0(sp)
    80005dd8:	0141                	addi	sp,sp,16
    80005dda:	8082                	ret

0000000080005ddc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005ddc:	1101                	addi	sp,sp,-32
    80005dde:	ec06                	sd	ra,24(sp)
    80005de0:	e822                	sd	s0,16(sp)
    80005de2:	e426                	sd	s1,8(sp)
    80005de4:	1000                	addi	s0,sp,32
    80005de6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005de8:	ffffc097          	auipc	ra,0xffffc
    80005dec:	b98080e7          	jalr	-1128(ra) # 80001980 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005df0:	00d5151b          	slliw	a0,a0,0xd
    80005df4:	0c2017b7          	lui	a5,0xc201
    80005df8:	97aa                	add	a5,a5,a0
    80005dfa:	c3c4                	sw	s1,4(a5)
}
    80005dfc:	60e2                	ld	ra,24(sp)
    80005dfe:	6442                	ld	s0,16(sp)
    80005e00:	64a2                	ld	s1,8(sp)
    80005e02:	6105                	addi	sp,sp,32
    80005e04:	8082                	ret

0000000080005e06 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005e06:	1141                	addi	sp,sp,-16
    80005e08:	e406                	sd	ra,8(sp)
    80005e0a:	e022                	sd	s0,0(sp)
    80005e0c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005e0e:	479d                	li	a5,7
    80005e10:	04a7cc63          	blt	a5,a0,80005e68 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005e14:	00028797          	auipc	a5,0x28
    80005e18:	22c78793          	addi	a5,a5,556 # 8002e040 <disk>
    80005e1c:	97aa                	add	a5,a5,a0
    80005e1e:	0187c783          	lbu	a5,24(a5)
    80005e22:	ebb9                	bnez	a5,80005e78 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005e24:	00451693          	slli	a3,a0,0x4
    80005e28:	00028797          	auipc	a5,0x28
    80005e2c:	21878793          	addi	a5,a5,536 # 8002e040 <disk>
    80005e30:	6398                	ld	a4,0(a5)
    80005e32:	9736                	add	a4,a4,a3
    80005e34:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80005e38:	6398                	ld	a4,0(a5)
    80005e3a:	9736                	add	a4,a4,a3
    80005e3c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005e40:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005e44:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005e48:	97aa                	add	a5,a5,a0
    80005e4a:	4705                	li	a4,1
    80005e4c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80005e50:	00028517          	auipc	a0,0x28
    80005e54:	20850513          	addi	a0,a0,520 # 8002e058 <disk+0x18>
    80005e58:	ffffc097          	auipc	ra,0xffffc
    80005e5c:	2c4080e7          	jalr	708(ra) # 8000211c <wakeup>
}
    80005e60:	60a2                	ld	ra,8(sp)
    80005e62:	6402                	ld	s0,0(sp)
    80005e64:	0141                	addi	sp,sp,16
    80005e66:	8082                	ret
    panic("free_desc 1");
    80005e68:	00003517          	auipc	a0,0x3
    80005e6c:	a3050513          	addi	a0,a0,-1488 # 80008898 <syscalls+0x300>
    80005e70:	ffffa097          	auipc	ra,0xffffa
    80005e74:	6d0080e7          	jalr	1744(ra) # 80000540 <panic>
    panic("free_desc 2");
    80005e78:	00003517          	auipc	a0,0x3
    80005e7c:	a3050513          	addi	a0,a0,-1488 # 800088a8 <syscalls+0x310>
    80005e80:	ffffa097          	auipc	ra,0xffffa
    80005e84:	6c0080e7          	jalr	1728(ra) # 80000540 <panic>

0000000080005e88 <virtio_disk_init>:
{
    80005e88:	1101                	addi	sp,sp,-32
    80005e8a:	ec06                	sd	ra,24(sp)
    80005e8c:	e822                	sd	s0,16(sp)
    80005e8e:	e426                	sd	s1,8(sp)
    80005e90:	e04a                	sd	s2,0(sp)
    80005e92:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e94:	00003597          	auipc	a1,0x3
    80005e98:	a2458593          	addi	a1,a1,-1500 # 800088b8 <syscalls+0x320>
    80005e9c:	00028517          	auipc	a0,0x28
    80005ea0:	2cc50513          	addi	a0,a0,716 # 8002e168 <disk+0x128>
    80005ea4:	ffffb097          	auipc	ra,0xffffb
    80005ea8:	ca2080e7          	jalr	-862(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005eac:	100017b7          	lui	a5,0x10001
    80005eb0:	4398                	lw	a4,0(a5)
    80005eb2:	2701                	sext.w	a4,a4
    80005eb4:	747277b7          	lui	a5,0x74727
    80005eb8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005ebc:	14f71b63          	bne	a4,a5,80006012 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005ec0:	100017b7          	lui	a5,0x10001
    80005ec4:	43dc                	lw	a5,4(a5)
    80005ec6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005ec8:	4709                	li	a4,2
    80005eca:	14e79463          	bne	a5,a4,80006012 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ece:	100017b7          	lui	a5,0x10001
    80005ed2:	479c                	lw	a5,8(a5)
    80005ed4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005ed6:	12e79e63          	bne	a5,a4,80006012 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005eda:	100017b7          	lui	a5,0x10001
    80005ede:	47d8                	lw	a4,12(a5)
    80005ee0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ee2:	554d47b7          	lui	a5,0x554d4
    80005ee6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005eea:	12f71463          	bne	a4,a5,80006012 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eee:	100017b7          	lui	a5,0x10001
    80005ef2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ef6:	4705                	li	a4,1
    80005ef8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005efa:	470d                	li	a4,3
    80005efc:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005efe:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005f00:	c7ffe6b7          	lui	a3,0xc7ffe
    80005f04:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fd05df>
    80005f08:	8f75                	and	a4,a4,a3
    80005f0a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f0c:	472d                	li	a4,11
    80005f0e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005f10:	5bbc                	lw	a5,112(a5)
    80005f12:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005f16:	8ba1                	andi	a5,a5,8
    80005f18:	10078563          	beqz	a5,80006022 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005f1c:	100017b7          	lui	a5,0x10001
    80005f20:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005f24:	43fc                	lw	a5,68(a5)
    80005f26:	2781                	sext.w	a5,a5
    80005f28:	10079563          	bnez	a5,80006032 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005f2c:	100017b7          	lui	a5,0x10001
    80005f30:	5bdc                	lw	a5,52(a5)
    80005f32:	2781                	sext.w	a5,a5
  if(max == 0)
    80005f34:	10078763          	beqz	a5,80006042 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80005f38:	471d                	li	a4,7
    80005f3a:	10f77c63          	bgeu	a4,a5,80006052 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    80005f3e:	ffffb097          	auipc	ra,0xffffb
    80005f42:	ba8080e7          	jalr	-1112(ra) # 80000ae6 <kalloc>
    80005f46:	00028497          	auipc	s1,0x28
    80005f4a:	0fa48493          	addi	s1,s1,250 # 8002e040 <disk>
    80005f4e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005f50:	ffffb097          	auipc	ra,0xffffb
    80005f54:	b96080e7          	jalr	-1130(ra) # 80000ae6 <kalloc>
    80005f58:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005f5a:	ffffb097          	auipc	ra,0xffffb
    80005f5e:	b8c080e7          	jalr	-1140(ra) # 80000ae6 <kalloc>
    80005f62:	87aa                	mv	a5,a0
    80005f64:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005f66:	6088                	ld	a0,0(s1)
    80005f68:	cd6d                	beqz	a0,80006062 <virtio_disk_init+0x1da>
    80005f6a:	00028717          	auipc	a4,0x28
    80005f6e:	0de73703          	ld	a4,222(a4) # 8002e048 <disk+0x8>
    80005f72:	cb65                	beqz	a4,80006062 <virtio_disk_init+0x1da>
    80005f74:	c7fd                	beqz	a5,80006062 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80005f76:	6605                	lui	a2,0x1
    80005f78:	4581                	li	a1,0
    80005f7a:	ffffb097          	auipc	ra,0xffffb
    80005f7e:	d58080e7          	jalr	-680(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80005f82:	00028497          	auipc	s1,0x28
    80005f86:	0be48493          	addi	s1,s1,190 # 8002e040 <disk>
    80005f8a:	6605                	lui	a2,0x1
    80005f8c:	4581                	li	a1,0
    80005f8e:	6488                	ld	a0,8(s1)
    80005f90:	ffffb097          	auipc	ra,0xffffb
    80005f94:	d42080e7          	jalr	-702(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    80005f98:	6605                	lui	a2,0x1
    80005f9a:	4581                	li	a1,0
    80005f9c:	6888                	ld	a0,16(s1)
    80005f9e:	ffffb097          	auipc	ra,0xffffb
    80005fa2:	d34080e7          	jalr	-716(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005fa6:	100017b7          	lui	a5,0x10001
    80005faa:	4721                	li	a4,8
    80005fac:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005fae:	4098                	lw	a4,0(s1)
    80005fb0:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005fb4:	40d8                	lw	a4,4(s1)
    80005fb6:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005fba:	6498                	ld	a4,8(s1)
    80005fbc:	0007069b          	sext.w	a3,a4
    80005fc0:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005fc4:	9701                	srai	a4,a4,0x20
    80005fc6:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005fca:	6898                	ld	a4,16(s1)
    80005fcc:	0007069b          	sext.w	a3,a4
    80005fd0:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005fd4:	9701                	srai	a4,a4,0x20
    80005fd6:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80005fda:	4705                	li	a4,1
    80005fdc:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80005fde:	00e48c23          	sb	a4,24(s1)
    80005fe2:	00e48ca3          	sb	a4,25(s1)
    80005fe6:	00e48d23          	sb	a4,26(s1)
    80005fea:	00e48da3          	sb	a4,27(s1)
    80005fee:	00e48e23          	sb	a4,28(s1)
    80005ff2:	00e48ea3          	sb	a4,29(s1)
    80005ff6:	00e48f23          	sb	a4,30(s1)
    80005ffa:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005ffe:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006002:	0727a823          	sw	s2,112(a5)
}
    80006006:	60e2                	ld	ra,24(sp)
    80006008:	6442                	ld	s0,16(sp)
    8000600a:	64a2                	ld	s1,8(sp)
    8000600c:	6902                	ld	s2,0(sp)
    8000600e:	6105                	addi	sp,sp,32
    80006010:	8082                	ret
    panic("could not find virtio disk");
    80006012:	00003517          	auipc	a0,0x3
    80006016:	8b650513          	addi	a0,a0,-1866 # 800088c8 <syscalls+0x330>
    8000601a:	ffffa097          	auipc	ra,0xffffa
    8000601e:	526080e7          	jalr	1318(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006022:	00003517          	auipc	a0,0x3
    80006026:	8c650513          	addi	a0,a0,-1850 # 800088e8 <syscalls+0x350>
    8000602a:	ffffa097          	auipc	ra,0xffffa
    8000602e:	516080e7          	jalr	1302(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80006032:	00003517          	auipc	a0,0x3
    80006036:	8d650513          	addi	a0,a0,-1834 # 80008908 <syscalls+0x370>
    8000603a:	ffffa097          	auipc	ra,0xffffa
    8000603e:	506080e7          	jalr	1286(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80006042:	00003517          	auipc	a0,0x3
    80006046:	8e650513          	addi	a0,a0,-1818 # 80008928 <syscalls+0x390>
    8000604a:	ffffa097          	auipc	ra,0xffffa
    8000604e:	4f6080e7          	jalr	1270(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80006052:	00003517          	auipc	a0,0x3
    80006056:	8f650513          	addi	a0,a0,-1802 # 80008948 <syscalls+0x3b0>
    8000605a:	ffffa097          	auipc	ra,0xffffa
    8000605e:	4e6080e7          	jalr	1254(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    80006062:	00003517          	auipc	a0,0x3
    80006066:	90650513          	addi	a0,a0,-1786 # 80008968 <syscalls+0x3d0>
    8000606a:	ffffa097          	auipc	ra,0xffffa
    8000606e:	4d6080e7          	jalr	1238(ra) # 80000540 <panic>

0000000080006072 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006072:	7119                	addi	sp,sp,-128
    80006074:	fc86                	sd	ra,120(sp)
    80006076:	f8a2                	sd	s0,112(sp)
    80006078:	f4a6                	sd	s1,104(sp)
    8000607a:	f0ca                	sd	s2,96(sp)
    8000607c:	ecce                	sd	s3,88(sp)
    8000607e:	e8d2                	sd	s4,80(sp)
    80006080:	e4d6                	sd	s5,72(sp)
    80006082:	e0da                	sd	s6,64(sp)
    80006084:	fc5e                	sd	s7,56(sp)
    80006086:	f862                	sd	s8,48(sp)
    80006088:	f466                	sd	s9,40(sp)
    8000608a:	f06a                	sd	s10,32(sp)
    8000608c:	ec6e                	sd	s11,24(sp)
    8000608e:	0100                	addi	s0,sp,128
    80006090:	8aaa                	mv	s5,a0
    80006092:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006094:	00c52d03          	lw	s10,12(a0)
    80006098:	001d1d1b          	slliw	s10,s10,0x1
    8000609c:	1d02                	slli	s10,s10,0x20
    8000609e:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    800060a2:	00028517          	auipc	a0,0x28
    800060a6:	0c650513          	addi	a0,a0,198 # 8002e168 <disk+0x128>
    800060aa:	ffffb097          	auipc	ra,0xffffb
    800060ae:	b2c080e7          	jalr	-1236(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    800060b2:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800060b4:	44a1                	li	s1,8
      disk.free[i] = 0;
    800060b6:	00028b97          	auipc	s7,0x28
    800060ba:	f8ab8b93          	addi	s7,s7,-118 # 8002e040 <disk>
  for(int i = 0; i < 3; i++){
    800060be:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800060c0:	00028c97          	auipc	s9,0x28
    800060c4:	0a8c8c93          	addi	s9,s9,168 # 8002e168 <disk+0x128>
    800060c8:	a08d                	j	8000612a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800060ca:	00fb8733          	add	a4,s7,a5
    800060ce:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800060d2:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800060d4:	0207c563          	bltz	a5,800060fe <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    800060d8:	2905                	addiw	s2,s2,1
    800060da:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    800060dc:	05690c63          	beq	s2,s6,80006134 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    800060e0:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800060e2:	00028717          	auipc	a4,0x28
    800060e6:	f5e70713          	addi	a4,a4,-162 # 8002e040 <disk>
    800060ea:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800060ec:	01874683          	lbu	a3,24(a4)
    800060f0:	fee9                	bnez	a3,800060ca <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    800060f2:	2785                	addiw	a5,a5,1
    800060f4:	0705                	addi	a4,a4,1
    800060f6:	fe979be3          	bne	a5,s1,800060ec <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    800060fa:	57fd                	li	a5,-1
    800060fc:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800060fe:	01205d63          	blez	s2,80006118 <virtio_disk_rw+0xa6>
    80006102:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006104:	000a2503          	lw	a0,0(s4)
    80006108:	00000097          	auipc	ra,0x0
    8000610c:	cfe080e7          	jalr	-770(ra) # 80005e06 <free_desc>
      for(int j = 0; j < i; j++)
    80006110:	2d85                	addiw	s11,s11,1
    80006112:	0a11                	addi	s4,s4,4
    80006114:	ff2d98e3          	bne	s11,s2,80006104 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006118:	85e6                	mv	a1,s9
    8000611a:	00028517          	auipc	a0,0x28
    8000611e:	f3e50513          	addi	a0,a0,-194 # 8002e058 <disk+0x18>
    80006122:	ffffc097          	auipc	ra,0xffffc
    80006126:	f96080e7          	jalr	-106(ra) # 800020b8 <sleep>
  for(int i = 0; i < 3; i++){
    8000612a:	f8040a13          	addi	s4,s0,-128
{
    8000612e:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006130:	894e                	mv	s2,s3
    80006132:	b77d                	j	800060e0 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006134:	f8042503          	lw	a0,-128(s0)
    80006138:	00a50713          	addi	a4,a0,10
    8000613c:	0712                	slli	a4,a4,0x4

  if(write)
    8000613e:	00028797          	auipc	a5,0x28
    80006142:	f0278793          	addi	a5,a5,-254 # 8002e040 <disk>
    80006146:	00e786b3          	add	a3,a5,a4
    8000614a:	01803633          	snez	a2,s8
    8000614e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006150:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006154:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006158:	f6070613          	addi	a2,a4,-160
    8000615c:	6394                	ld	a3,0(a5)
    8000615e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006160:	00870593          	addi	a1,a4,8
    80006164:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006166:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006168:	0007b803          	ld	a6,0(a5)
    8000616c:	9642                	add	a2,a2,a6
    8000616e:	46c1                	li	a3,16
    80006170:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006172:	4585                	li	a1,1
    80006174:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006178:	f8442683          	lw	a3,-124(s0)
    8000617c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006180:	0692                	slli	a3,a3,0x4
    80006182:	9836                	add	a6,a6,a3
    80006184:	058a8613          	addi	a2,s5,88
    80006188:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    8000618c:	0007b803          	ld	a6,0(a5)
    80006190:	96c2                	add	a3,a3,a6
    80006192:	40000613          	li	a2,1024
    80006196:	c690                	sw	a2,8(a3)
  if(write)
    80006198:	001c3613          	seqz	a2,s8
    8000619c:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800061a0:	00166613          	ori	a2,a2,1
    800061a4:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800061a8:	f8842603          	lw	a2,-120(s0)
    800061ac:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800061b0:	00250693          	addi	a3,a0,2
    800061b4:	0692                	slli	a3,a3,0x4
    800061b6:	96be                	add	a3,a3,a5
    800061b8:	58fd                	li	a7,-1
    800061ba:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800061be:	0612                	slli	a2,a2,0x4
    800061c0:	9832                	add	a6,a6,a2
    800061c2:	f9070713          	addi	a4,a4,-112
    800061c6:	973e                	add	a4,a4,a5
    800061c8:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    800061cc:	6398                	ld	a4,0(a5)
    800061ce:	9732                	add	a4,a4,a2
    800061d0:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800061d2:	4609                	li	a2,2
    800061d4:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    800061d8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800061dc:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    800061e0:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800061e4:	6794                	ld	a3,8(a5)
    800061e6:	0026d703          	lhu	a4,2(a3)
    800061ea:	8b1d                	andi	a4,a4,7
    800061ec:	0706                	slli	a4,a4,0x1
    800061ee:	96ba                	add	a3,a3,a4
    800061f0:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    800061f4:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800061f8:	6798                	ld	a4,8(a5)
    800061fa:	00275783          	lhu	a5,2(a4)
    800061fe:	2785                	addiw	a5,a5,1
    80006200:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006204:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006208:	100017b7          	lui	a5,0x10001
    8000620c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006210:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    80006214:	00028917          	auipc	s2,0x28
    80006218:	f5490913          	addi	s2,s2,-172 # 8002e168 <disk+0x128>
  while(b->disk == 1) {
    8000621c:	4485                	li	s1,1
    8000621e:	00b79c63          	bne	a5,a1,80006236 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006222:	85ca                	mv	a1,s2
    80006224:	8556                	mv	a0,s5
    80006226:	ffffc097          	auipc	ra,0xffffc
    8000622a:	e92080e7          	jalr	-366(ra) # 800020b8 <sleep>
  while(b->disk == 1) {
    8000622e:	004aa783          	lw	a5,4(s5)
    80006232:	fe9788e3          	beq	a5,s1,80006222 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006236:	f8042903          	lw	s2,-128(s0)
    8000623a:	00290713          	addi	a4,s2,2
    8000623e:	0712                	slli	a4,a4,0x4
    80006240:	00028797          	auipc	a5,0x28
    80006244:	e0078793          	addi	a5,a5,-512 # 8002e040 <disk>
    80006248:	97ba                	add	a5,a5,a4
    8000624a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000624e:	00028997          	auipc	s3,0x28
    80006252:	df298993          	addi	s3,s3,-526 # 8002e040 <disk>
    80006256:	00491713          	slli	a4,s2,0x4
    8000625a:	0009b783          	ld	a5,0(s3)
    8000625e:	97ba                	add	a5,a5,a4
    80006260:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006264:	854a                	mv	a0,s2
    80006266:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000626a:	00000097          	auipc	ra,0x0
    8000626e:	b9c080e7          	jalr	-1124(ra) # 80005e06 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006272:	8885                	andi	s1,s1,1
    80006274:	f0ed                	bnez	s1,80006256 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006276:	00028517          	auipc	a0,0x28
    8000627a:	ef250513          	addi	a0,a0,-270 # 8002e168 <disk+0x128>
    8000627e:	ffffb097          	auipc	ra,0xffffb
    80006282:	a0c080e7          	jalr	-1524(ra) # 80000c8a <release>
}
    80006286:	70e6                	ld	ra,120(sp)
    80006288:	7446                	ld	s0,112(sp)
    8000628a:	74a6                	ld	s1,104(sp)
    8000628c:	7906                	ld	s2,96(sp)
    8000628e:	69e6                	ld	s3,88(sp)
    80006290:	6a46                	ld	s4,80(sp)
    80006292:	6aa6                	ld	s5,72(sp)
    80006294:	6b06                	ld	s6,64(sp)
    80006296:	7be2                	ld	s7,56(sp)
    80006298:	7c42                	ld	s8,48(sp)
    8000629a:	7ca2                	ld	s9,40(sp)
    8000629c:	7d02                	ld	s10,32(sp)
    8000629e:	6de2                	ld	s11,24(sp)
    800062a0:	6109                	addi	sp,sp,128
    800062a2:	8082                	ret

00000000800062a4 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800062a4:	1101                	addi	sp,sp,-32
    800062a6:	ec06                	sd	ra,24(sp)
    800062a8:	e822                	sd	s0,16(sp)
    800062aa:	e426                	sd	s1,8(sp)
    800062ac:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800062ae:	00028497          	auipc	s1,0x28
    800062b2:	d9248493          	addi	s1,s1,-622 # 8002e040 <disk>
    800062b6:	00028517          	auipc	a0,0x28
    800062ba:	eb250513          	addi	a0,a0,-334 # 8002e168 <disk+0x128>
    800062be:	ffffb097          	auipc	ra,0xffffb
    800062c2:	918080e7          	jalr	-1768(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800062c6:	10001737          	lui	a4,0x10001
    800062ca:	533c                	lw	a5,96(a4)
    800062cc:	8b8d                	andi	a5,a5,3
    800062ce:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800062d0:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800062d4:	689c                	ld	a5,16(s1)
    800062d6:	0204d703          	lhu	a4,32(s1)
    800062da:	0027d783          	lhu	a5,2(a5)
    800062de:	04f70863          	beq	a4,a5,8000632e <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800062e2:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800062e6:	6898                	ld	a4,16(s1)
    800062e8:	0204d783          	lhu	a5,32(s1)
    800062ec:	8b9d                	andi	a5,a5,7
    800062ee:	078e                	slli	a5,a5,0x3
    800062f0:	97ba                	add	a5,a5,a4
    800062f2:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800062f4:	00278713          	addi	a4,a5,2
    800062f8:	0712                	slli	a4,a4,0x4
    800062fa:	9726                	add	a4,a4,s1
    800062fc:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006300:	e721                	bnez	a4,80006348 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006302:	0789                	addi	a5,a5,2
    80006304:	0792                	slli	a5,a5,0x4
    80006306:	97a6                	add	a5,a5,s1
    80006308:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000630a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000630e:	ffffc097          	auipc	ra,0xffffc
    80006312:	e0e080e7          	jalr	-498(ra) # 8000211c <wakeup>

    disk.used_idx += 1;
    80006316:	0204d783          	lhu	a5,32(s1)
    8000631a:	2785                	addiw	a5,a5,1
    8000631c:	17c2                	slli	a5,a5,0x30
    8000631e:	93c1                	srli	a5,a5,0x30
    80006320:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006324:	6898                	ld	a4,16(s1)
    80006326:	00275703          	lhu	a4,2(a4)
    8000632a:	faf71ce3          	bne	a4,a5,800062e2 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000632e:	00028517          	auipc	a0,0x28
    80006332:	e3a50513          	addi	a0,a0,-454 # 8002e168 <disk+0x128>
    80006336:	ffffb097          	auipc	ra,0xffffb
    8000633a:	954080e7          	jalr	-1708(ra) # 80000c8a <release>
}
    8000633e:	60e2                	ld	ra,24(sp)
    80006340:	6442                	ld	s0,16(sp)
    80006342:	64a2                	ld	s1,8(sp)
    80006344:	6105                	addi	sp,sp,32
    80006346:	8082                	ret
      panic("virtio_disk_intr status");
    80006348:	00002517          	auipc	a0,0x2
    8000634c:	63850513          	addi	a0,a0,1592 # 80008980 <syscalls+0x3e8>
    80006350:	ffffa097          	auipc	ra,0xffffa
    80006354:	1f0080e7          	jalr	496(ra) # 80000540 <panic>

0000000080006358 <init_list_head>:
#include "defs.h"
#include "spinlock.h"
#include "proc.h"

void init_list_head(struct list_head *list)
{
    80006358:	1141                	addi	sp,sp,-16
    8000635a:	e422                	sd	s0,8(sp)
    8000635c:	0800                	addi	s0,sp,16
  list->next = list;
    8000635e:	e108                	sd	a0,0(a0)
  list->prev = list;
    80006360:	e508                	sd	a0,8(a0)
}
    80006362:	6422                	ld	s0,8(sp)
    80006364:	0141                	addi	sp,sp,16
    80006366:	8082                	ret

0000000080006368 <list_add>:
  next->prev = prev;
  prev->next = next;
}

void list_add(struct list_head *head, struct list_head *new)
{
    80006368:	1141                	addi	sp,sp,-16
    8000636a:	e422                	sd	s0,8(sp)
    8000636c:	0800                	addi	s0,sp,16
  __list_add(new, head, head->next);
    8000636e:	611c                	ld	a5,0(a0)
  next->prev = new;
    80006370:	e78c                	sd	a1,8(a5)
  new->next = next;
    80006372:	e19c                	sd	a5,0(a1)
  new->prev = prev;
    80006374:	e588                	sd	a0,8(a1)
  prev->next = new;
    80006376:	e10c                	sd	a1,0(a0)
}
    80006378:	6422                	ld	s0,8(sp)
    8000637a:	0141                	addi	sp,sp,16
    8000637c:	8082                	ret

000000008000637e <list_add_tail>:

void list_add_tail(struct list_head *head, struct list_head *new)
{
    8000637e:	1141                	addi	sp,sp,-16
    80006380:	e422                	sd	s0,8(sp)
    80006382:	0800                	addi	s0,sp,16
  __list_add(new, head->prev, head);
    80006384:	651c                	ld	a5,8(a0)
  next->prev = new;
    80006386:	e50c                	sd	a1,8(a0)
  new->next = next;
    80006388:	e188                	sd	a0,0(a1)
  new->prev = prev;
    8000638a:	e59c                	sd	a5,8(a1)
  prev->next = new;
    8000638c:	e38c                	sd	a1,0(a5)
}
    8000638e:	6422                	ld	s0,8(sp)
    80006390:	0141                	addi	sp,sp,16
    80006392:	8082                	ret

0000000080006394 <list_del>:

void list_del(struct list_head *entry)
{
    80006394:	1141                	addi	sp,sp,-16
    80006396:	e422                	sd	s0,8(sp)
    80006398:	0800                	addi	s0,sp,16
  __list_del(entry->prev, entry->next);
    8000639a:	651c                	ld	a5,8(a0)
    8000639c:	6118                	ld	a4,0(a0)
  next->prev = prev;
    8000639e:	e71c                	sd	a5,8(a4)
  prev->next = next;
    800063a0:	e398                	sd	a4,0(a5)
  entry->prev = entry->next = entry;
    800063a2:	e108                	sd	a0,0(a0)
    800063a4:	e508                	sd	a0,8(a0)
}
    800063a6:	6422                	ld	s0,8(sp)
    800063a8:	0141                	addi	sp,sp,16
    800063aa:	8082                	ret

00000000800063ac <list_del_init>:

void list_del_init(struct list_head *entry)
{
    800063ac:	1141                	addi	sp,sp,-16
    800063ae:	e422                	sd	s0,8(sp)
    800063b0:	0800                	addi	s0,sp,16
  __list_del(entry->prev, entry->next);
    800063b2:	651c                	ld	a5,8(a0)
    800063b4:	6118                	ld	a4,0(a0)
  next->prev = prev;
    800063b6:	e71c                	sd	a5,8(a4)
  prev->next = next;
    800063b8:	e398                	sd	a4,0(a5)
  list->next = list;
    800063ba:	e108                	sd	a0,0(a0)
  list->prev = list;
    800063bc:	e508                	sd	a0,8(a0)
  init_list_head(entry);
}
    800063be:	6422                	ld	s0,8(sp)
    800063c0:	0141                	addi	sp,sp,16
    800063c2:	8082                	ret
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
