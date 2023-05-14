
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	b6013103          	ld	sp,-1184(sp) # 80008b60 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000054:	b7070713          	addi	a4,a4,-1168 # 80008bc0 <timer_scratch>
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
    80000066:	d8e78793          	addi	a5,a5,-626 # 80005df0 <timervec>
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
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd4567>
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
    8000012e:	438080e7          	jalr	1080(ra) # 80002562 <either_copyin>
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
    8000018e:	b7650513          	addi	a0,a0,-1162 # 80010d00 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	b6648493          	addi	s1,s1,-1178 # 80010d00 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	bf690913          	addi	s2,s2,-1034 # 80010d98 <cons+0x98>
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
    800001cc:	1e4080e7          	jalr	484(ra) # 800023ac <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	f2e080e7          	jalr	-210(ra) # 80002104 <sleep>
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
    80000216:	2fa080e7          	jalr	762(ra) # 8000250c <either_copyout>
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
    8000022a:	ada50513          	addi	a0,a0,-1318 # 80010d00 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	ac450513          	addi	a0,a0,-1340 # 80010d00 <cons>
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
    80000276:	b2f72323          	sw	a5,-1242(a4) # 80010d98 <cons+0x98>
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
    800002d0:	a3450513          	addi	a0,a0,-1484 # 80010d00 <cons>
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
    800002f6:	2c6080e7          	jalr	710(ra) # 800025b8 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	a0650513          	addi	a0,a0,-1530 # 80010d00 <cons>
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
    80000322:	9e270713          	addi	a4,a4,-1566 # 80010d00 <cons>
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
    8000034c:	9b878793          	addi	a5,a5,-1608 # 80010d00 <cons>
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
    8000037a:	a227a783          	lw	a5,-1502(a5) # 80010d98 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	97670713          	addi	a4,a4,-1674 # 80010d00 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	96648493          	addi	s1,s1,-1690 # 80010d00 <cons>
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
    800003da:	92a70713          	addi	a4,a4,-1750 # 80010d00 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	9af72a23          	sw	a5,-1612(a4) # 80010da0 <cons+0xa0>
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
    80000416:	8ee78793          	addi	a5,a5,-1810 # 80010d00 <cons>
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
    8000043a:	96c7a323          	sw	a2,-1690(a5) # 80010d9c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	95a50513          	addi	a0,a0,-1702 # 80010d98 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	d22080e7          	jalr	-734(ra) # 80002168 <wakeup>
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
    80000460:	00011517          	auipc	a0,0x11
    80000464:	8a050513          	addi	a0,a0,-1888 # 80010d00 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32c080e7          	jalr	812(ra) # 8000079c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00029797          	auipc	a5,0x29
    8000047c:	c8878793          	addi	a5,a5,-888 # 80029100 <devsw>
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
    8000054c:	00011797          	auipc	a5,0x11
    80000550:	8607aa23          	sw	zero,-1932(a5) # 80010dc0 <pr+0x18>
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
    80000584:	60f72023          	sw	a5,1536(a4) # 80008b80 <panicked>
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
    800005bc:	00011d97          	auipc	s11,0x11
    800005c0:	804dad83          	lw	s11,-2044(s11) # 80010dc0 <pr+0x18>
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
    800005fe:	7ae50513          	addi	a0,a0,1966 # 80010da8 <pr>
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
    8000075c:	65050513          	addi	a0,a0,1616 # 80010da8 <pr>
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
    80000778:	63448493          	addi	s1,s1,1588 # 80010da8 <pr>
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
    800007d8:	5f450513          	addi	a0,a0,1524 # 80010dc8 <uart_tx_lock>
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
    80000804:	3807a783          	lw	a5,896(a5) # 80008b80 <panicked>
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
    8000083c:	3507b783          	ld	a5,848(a5) # 80008b88 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	35073703          	ld	a4,848(a4) # 80008b90 <uart_tx_w>
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
    80000866:	566a0a13          	addi	s4,s4,1382 # 80010dc8 <uart_tx_lock>
    uart_tx_r += 1;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	31e48493          	addi	s1,s1,798 # 80008b88 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008997          	auipc	s3,0x8
    80000876:	31e98993          	addi	s3,s3,798 # 80008b90 <uart_tx_w>
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
    80000898:	8d4080e7          	jalr	-1836(ra) # 80002168 <wakeup>
    
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
    800008d4:	4f850513          	addi	a0,a0,1272 # 80010dc8 <uart_tx_lock>
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	2fe080e7          	jalr	766(ra) # 80000bd6 <acquire>
  if(panicked){
    800008e0:	00008797          	auipc	a5,0x8
    800008e4:	2a07a783          	lw	a5,672(a5) # 80008b80 <panicked>
    800008e8:	e7c9                	bnez	a5,80000972 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008717          	auipc	a4,0x8
    800008ee:	2a673703          	ld	a4,678(a4) # 80008b90 <uart_tx_w>
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	2967b783          	ld	a5,662(a5) # 80008b88 <uart_tx_r>
    800008fa:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00010997          	auipc	s3,0x10
    80000902:	4ca98993          	addi	s3,s3,1226 # 80010dc8 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	28248493          	addi	s1,s1,642 # 80008b88 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	28290913          	addi	s2,s2,642 # 80008b90 <uart_tx_w>
    80000916:	00e79f63          	bne	a5,a4,80000934 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85ce                	mv	a1,s3
    8000091c:	8526                	mv	a0,s1
    8000091e:	00001097          	auipc	ra,0x1
    80000922:	7e6080e7          	jalr	2022(ra) # 80002104 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093703          	ld	a4,0(s2)
    8000092a:	609c                	ld	a5,0(s1)
    8000092c:	02078793          	addi	a5,a5,32
    80000930:	fee785e3          	beq	a5,a4,8000091a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00010497          	auipc	s1,0x10
    80000938:	49448493          	addi	s1,s1,1172 # 80010dc8 <uart_tx_lock>
    8000093c:	01f77793          	andi	a5,a4,31
    80000940:	97a6                	add	a5,a5,s1
    80000942:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000946:	0705                	addi	a4,a4,1
    80000948:	00008797          	auipc	a5,0x8
    8000094c:	24e7b423          	sd	a4,584(a5) # 80008b90 <uart_tx_w>
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
    800009be:	40e48493          	addi	s1,s1,1038 # 80010dc8 <uart_tx_lock>
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
    800009fc:	0002a797          	auipc	a5,0x2a
    80000a00:	89c78793          	addi	a5,a5,-1892 # 8002a298 <end>
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
    80000a20:	3e490913          	addi	s2,s2,996 # 80010e00 <kmem>
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
    80000abe:	34650513          	addi	a0,a0,838 # 80010e00 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00029517          	auipc	a0,0x29
    80000ad2:	7ca50513          	addi	a0,a0,1994 # 8002a298 <end>
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
    80000af4:	31048493          	addi	s1,s1,784 # 80010e00 <kmem>
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
    80000b0c:	2f850513          	addi	a0,a0,760 # 80010e00 <kmem>
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
    80000b38:	2cc50513          	addi	a0,a0,716 # 80010e00 <kmem>
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
    80000d46:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffd4d69>
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
    80000e8c:	d1070713          	addi	a4,a4,-752 # 80008b98 <started>
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
    80000ebe:	00002097          	auipc	ra,0x2
    80000ec2:	83c080e7          	jalr	-1988(ra) # 800026fa <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	f6a080e7          	jalr	-150(ra) # 80005e30 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	05a080e7          	jalr	90(ra) # 80001f28 <scheduler>
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
    80000f3a:	79c080e7          	jalr	1948(ra) # 800026d2 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00001097          	auipc	ra,0x1
    80000f42:	7bc080e7          	jalr	1980(ra) # 800026fa <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	ed4080e7          	jalr	-300(ra) # 80005e1a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	ee2080e7          	jalr	-286(ra) # 80005e30 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	084080e7          	jalr	132(ra) # 80002fda <binit>
    iinit();         // inode table
    80000f5e:	00002097          	auipc	ra,0x2
    80000f62:	724080e7          	jalr	1828(ra) # 80003682 <iinit>
    fileinit();      // file table
    80000f66:	00003097          	auipc	ra,0x3
    80000f6a:	6ca080e7          	jalr	1738(ra) # 80004630 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	fca080e7          	jalr	-54(ra) # 80005f38 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	d0e080e7          	jalr	-754(ra) # 80001c84 <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	c0f72a23          	sw	a5,-1004(a4) # 80008b98 <started>
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
    80000f9c:	c087b783          	ld	a5,-1016(a5) # 80008ba0 <kernel_pagetable>
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
    80001016:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffd4d5f>
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
    80001258:	94a7b623          	sd	a0,-1716(a5) # 80008ba0 <kernel_pagetable>
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
    8000180c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd4d68>
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
    80001850:	a1448493          	addi	s1,s1,-1516 # 80011260 <proc>
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
    8000186a:	5faa0a13          	addi	s4,s4,1530 # 80016e60 <tickslock>
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
    800018ec:	53850513          	addi	a0,a0,1336 # 80010e20 <pid_lock>
    800018f0:	fffff097          	auipc	ra,0xfffff
    800018f4:	256080e7          	jalr	598(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018f8:	00007597          	auipc	a1,0x7
    800018fc:	8f058593          	addi	a1,a1,-1808 # 800081e8 <digits+0x1a8>
    80001900:	0000f517          	auipc	a0,0xf
    80001904:	53850513          	addi	a0,a0,1336 # 80010e38 <wait_lock>
    80001908:	fffff097          	auipc	ra,0xfffff
    8000190c:	23e080e7          	jalr	574(ra) # 80000b46 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001910:	00010497          	auipc	s1,0x10
    80001914:	95048493          	addi	s1,s1,-1712 # 80011260 <proc>
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
    80001936:	52e98993          	addi	s3,s3,1326 # 80016e60 <tickslock>
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
    800019a0:	4b450513          	addi	a0,a0,1204 # 80010e50 <cpus>
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
    800019c8:	45c70713          	addi	a4,a4,1116 # 80010e20 <pid_lock>
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
    80001a00:	0447a783          	lw	a5,68(a5) # 80008a40 <first.1>
    80001a04:	eb89                	bnez	a5,80001a16 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a06:	00001097          	auipc	ra,0x1
    80001a0a:	d0c080e7          	jalr	-756(ra) # 80002712 <usertrapret>
}
    80001a0e:	60a2                	ld	ra,8(sp)
    80001a10:	6402                	ld	s0,0(sp)
    80001a12:	0141                	addi	sp,sp,16
    80001a14:	8082                	ret
    first = 0;
    80001a16:	00007797          	auipc	a5,0x7
    80001a1a:	0207a523          	sw	zero,42(a5) # 80008a40 <first.1>
    fsinit(ROOTDEV);
    80001a1e:	4505                	li	a0,1
    80001a20:	00002097          	auipc	ra,0x2
    80001a24:	be2080e7          	jalr	-1054(ra) # 80003602 <fsinit>
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
    80001a3a:	3ea90913          	addi	s2,s2,1002 # 80010e20 <pid_lock>
    80001a3e:	854a                	mv	a0,s2
    80001a40:	fffff097          	auipc	ra,0xfffff
    80001a44:	196080e7          	jalr	406(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a48:	00007797          	auipc	a5,0x7
    80001a4c:	ffc78793          	addi	a5,a5,-4 # 80008a44 <nextpid>
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
    80001bc6:	69e48493          	addi	s1,s1,1694 # 80011260 <proc>
    80001bca:	00015917          	auipc	s2,0x15
    80001bce:	29690913          	addi	s2,s2,662 # 80016e60 <tickslock>
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
    80001c9c:	f0a7b823          	sd	a0,-240(a5) # 80008ba8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001ca0:	03400613          	li	a2,52
    80001ca4:	00007597          	auipc	a1,0x7
    80001ca8:	dac58593          	addi	a1,a1,-596 # 80008a50 <initcode>
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
    80001ce6:	34a080e7          	jalr	842(ra) # 8000402c <namei>
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
    80001e12:	00003097          	auipc	ra,0x3
    80001e16:	8b0080e7          	jalr	-1872(ra) # 800046c2 <filedup>
    80001e1a:	00a93023          	sd	a0,0(s2)
    80001e1e:	b7e5                	j	80001e06 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e20:	150ab503          	ld	a0,336(s5)
    80001e24:	00002097          	auipc	ra,0x2
    80001e28:	a1e080e7          	jalr	-1506(ra) # 80003842 <idup>
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
    80001e54:	fe848493          	addi	s1,s1,-24 # 80010e38 <wait_lock>
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
    80001ea2:	7179                	addi	sp,sp,-48
    80001ea4:	f406                	sd	ra,40(sp)
    80001ea6:	f022                	sd	s0,32(sp)
    80001ea8:	ec26                	sd	s1,24(sp)
    80001eaa:	e84a                	sd	s2,16(sp)
    80001eac:	1800                	addi	s0,sp,48
    80001eae:	892a                	mv	s2,a0
    80001eb0:	84ae                	mv	s1,a1
  printf("arr address in audit on proc side: %p\n", arr);
    80001eb2:	85aa                	mv	a1,a0
    80001eb4:	00006517          	auipc	a0,0x6
    80001eb8:	36450513          	addi	a0,a0,868 # 80008218 <digits+0x1d8>
    80001ebc:	ffffe097          	auipc	ra,0xffffe
    80001ec0:	6ce080e7          	jalr	1742(ra) # 8000058a <printf>
  printf("length address passed through: %p\n", length);
    80001ec4:	85a6                	mv	a1,s1
    80001ec6:	00006517          	auipc	a0,0x6
    80001eca:	37a50513          	addi	a0,a0,890 # 80008240 <digits+0x200>
    80001ece:	ffffe097          	auipc	ra,0xffffe
    80001ed2:	6bc080e7          	jalr	1724(ra) # 8000058a <printf>
  bruh.arr = arr;
    80001ed6:	fd243823          	sd	s2,-48(s0)
  bruh.length = length;
    80001eda:	fc943c23          	sd	s1,-40(s0)
  printf("length: %d\n", *length);
    80001ede:	408c                	lw	a1,0(s1)
    80001ee0:	00006517          	auipc	a0,0x6
    80001ee4:	38850513          	addi	a0,a0,904 # 80008268 <digits+0x228>
    80001ee8:	ffffe097          	auipc	ra,0xffffe
    80001eec:	6a2080e7          	jalr	1698(ra) # 8000058a <printf>
  printf("bruh length address: %p\n", bruh.length);
    80001ef0:	fd843583          	ld	a1,-40(s0)
    80001ef4:	00006517          	auipc	a0,0x6
    80001ef8:	38450513          	addi	a0,a0,900 # 80008278 <digits+0x238>
    80001efc:	ffffe097          	auipc	ra,0xffffe
    80001f00:	68e080e7          	jalr	1678(ra) # 8000058a <printf>
  printf("address of bruh: %p\n", &bruh);
    80001f04:	fd040593          	addi	a1,s0,-48
    80001f08:	00006517          	auipc	a0,0x6
    80001f0c:	39050513          	addi	a0,a0,912 # 80008298 <digits+0x258>
    80001f10:	ffffe097          	auipc	ra,0xffffe
    80001f14:	67a080e7          	jalr	1658(ra) # 8000058a <printf>
}
    80001f18:	fd040513          	addi	a0,s0,-48
    80001f1c:	70a2                	ld	ra,40(sp)
    80001f1e:	7402                	ld	s0,32(sp)
    80001f20:	64e2                	ld	s1,24(sp)
    80001f22:	6942                	ld	s2,16(sp)
    80001f24:	6145                	addi	sp,sp,48
    80001f26:	8082                	ret

0000000080001f28 <scheduler>:
{
    80001f28:	715d                	addi	sp,sp,-80
    80001f2a:	e486                	sd	ra,72(sp)
    80001f2c:	e0a2                	sd	s0,64(sp)
    80001f2e:	fc26                	sd	s1,56(sp)
    80001f30:	f84a                	sd	s2,48(sp)
    80001f32:	f44e                	sd	s3,40(sp)
    80001f34:	f052                	sd	s4,32(sp)
    80001f36:	ec56                	sd	s5,24(sp)
    80001f38:	e85a                	sd	s6,16(sp)
    80001f3a:	e45e                	sd	s7,8(sp)
    80001f3c:	e062                	sd	s8,0(sp)
    80001f3e:	0880                	addi	s0,sp,80
    80001f40:	8492                	mv	s1,tp
  int id = r_tp();
    80001f42:	2481                	sext.w	s1,s1
  init_list_head(&runq);
    80001f44:	0000f517          	auipc	a0,0xf
    80001f48:	30c50513          	addi	a0,a0,780 # 80011250 <runq>
    80001f4c:	00004097          	auipc	ra,0x4
    80001f50:	4bc080e7          	jalr	1212(ra) # 80006408 <init_list_head>
  c->proc = 0;
    80001f54:	00749b13          	slli	s6,s1,0x7
    80001f58:	0000f797          	auipc	a5,0xf
    80001f5c:	ec878793          	addi	a5,a5,-312 # 80010e20 <pid_lock>
    80001f60:	97da                	add	a5,a5,s6
    80001f62:	0207b823          	sd	zero,48(a5)
        swtch(&c->context, &p->context);
    80001f66:	0000f797          	auipc	a5,0xf
    80001f6a:	ef278793          	addi	a5,a5,-270 # 80010e58 <cpus+0x8>
    80001f6e:	9b3e                	add	s6,s6,a5
    not_runnable_count = 0;
    80001f70:	4c01                	li	s8,0
        p->state = RUNNING;
    80001f72:	4b91                	li	s7,4
        c->proc = p;
    80001f74:	049e                	slli	s1,s1,0x7
    80001f76:	0000fa97          	auipc	s5,0xf
    80001f7a:	eaaa8a93          	addi	s5,s5,-342 # 80010e20 <pid_lock>
    80001f7e:	9aa6                	add	s5,s5,s1
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f80:	00015a17          	auipc	s4,0x15
    80001f84:	ee0a0a13          	addi	s4,s4,-288 # 80016e60 <tickslock>
    80001f88:	a0a9                	j	80001fd2 <scheduler+0xaa>
        not_runnable_count++;
    80001f8a:	2905                	addiw	s2,s2,1
      release(&p->lock);
    80001f8c:	8526                	mv	a0,s1
    80001f8e:	fffff097          	auipc	ra,0xfffff
    80001f92:	cfc080e7          	jalr	-772(ra) # 80000c8a <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f96:	17048493          	addi	s1,s1,368
    80001f9a:	03448863          	beq	s1,s4,80001fca <scheduler+0xa2>
      acquire(&p->lock);
    80001f9e:	8526                	mv	a0,s1
    80001fa0:	fffff097          	auipc	ra,0xfffff
    80001fa4:	c36080e7          	jalr	-970(ra) # 80000bd6 <acquire>
      if(p->state == RUNNABLE) {
    80001fa8:	4c9c                	lw	a5,24(s1)
    80001faa:	ff3790e3          	bne	a5,s3,80001f8a <scheduler+0x62>
        p->state = RUNNING;
    80001fae:	0174ac23          	sw	s7,24(s1)
        c->proc = p;
    80001fb2:	029ab823          	sd	s1,48(s5)
        swtch(&c->context, &p->context);
    80001fb6:	06048593          	addi	a1,s1,96
    80001fba:	855a                	mv	a0,s6
    80001fbc:	00000097          	auipc	ra,0x0
    80001fc0:	6ac080e7          	jalr	1708(ra) # 80002668 <swtch>
        c->proc = 0;
    80001fc4:	020ab823          	sd	zero,48(s5)
    80001fc8:	b7d1                	j	80001f8c <scheduler+0x64>
    if (not_runnable_count == NPROC) {
    80001fca:	04000793          	li	a5,64
    80001fce:	00f90f63          	beq	s2,a5,80001fec <scheduler+0xc4>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fd2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001fd6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001fda:	10079073          	csrw	sstatus,a5
    not_runnable_count = 0;
    80001fde:	8962                	mv	s2,s8
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fe0:	0000f497          	auipc	s1,0xf
    80001fe4:	28048493          	addi	s1,s1,640 # 80011260 <proc>
      if(p->state == RUNNABLE) {
    80001fe8:	498d                	li	s3,3
    80001fea:	bf55                	j	80001f9e <scheduler+0x76>
  asm volatile("wfi");
    80001fec:	10500073          	wfi
}
    80001ff0:	b7cd                	j	80001fd2 <scheduler+0xaa>

0000000080001ff2 <sched>:
{
    80001ff2:	7179                	addi	sp,sp,-48
    80001ff4:	f406                	sd	ra,40(sp)
    80001ff6:	f022                	sd	s0,32(sp)
    80001ff8:	ec26                	sd	s1,24(sp)
    80001ffa:	e84a                	sd	s2,16(sp)
    80001ffc:	e44e                	sd	s3,8(sp)
    80001ffe:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002000:	00000097          	auipc	ra,0x0
    80002004:	9ac080e7          	jalr	-1620(ra) # 800019ac <myproc>
    80002008:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000200a:	fffff097          	auipc	ra,0xfffff
    8000200e:	b52080e7          	jalr	-1198(ra) # 80000b5c <holding>
    80002012:	c93d                	beqz	a0,80002088 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002014:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002016:	2781                	sext.w	a5,a5
    80002018:	079e                	slli	a5,a5,0x7
    8000201a:	0000f717          	auipc	a4,0xf
    8000201e:	e0670713          	addi	a4,a4,-506 # 80010e20 <pid_lock>
    80002022:	97ba                	add	a5,a5,a4
    80002024:	0a87a703          	lw	a4,168(a5)
    80002028:	4785                	li	a5,1
    8000202a:	06f71763          	bne	a4,a5,80002098 <sched+0xa6>
  if(p->state == RUNNING)
    8000202e:	4c98                	lw	a4,24(s1)
    80002030:	4791                	li	a5,4
    80002032:	06f70b63          	beq	a4,a5,800020a8 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002036:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000203a:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000203c:	efb5                	bnez	a5,800020b8 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000203e:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002040:	0000f917          	auipc	s2,0xf
    80002044:	de090913          	addi	s2,s2,-544 # 80010e20 <pid_lock>
    80002048:	2781                	sext.w	a5,a5
    8000204a:	079e                	slli	a5,a5,0x7
    8000204c:	97ca                	add	a5,a5,s2
    8000204e:	0ac7a983          	lw	s3,172(a5)
    80002052:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002054:	2781                	sext.w	a5,a5
    80002056:	079e                	slli	a5,a5,0x7
    80002058:	0000f597          	auipc	a1,0xf
    8000205c:	e0058593          	addi	a1,a1,-512 # 80010e58 <cpus+0x8>
    80002060:	95be                	add	a1,a1,a5
    80002062:	06048513          	addi	a0,s1,96
    80002066:	00000097          	auipc	ra,0x0
    8000206a:	602080e7          	jalr	1538(ra) # 80002668 <swtch>
    8000206e:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002070:	2781                	sext.w	a5,a5
    80002072:	079e                	slli	a5,a5,0x7
    80002074:	993e                	add	s2,s2,a5
    80002076:	0b392623          	sw	s3,172(s2)
}
    8000207a:	70a2                	ld	ra,40(sp)
    8000207c:	7402                	ld	s0,32(sp)
    8000207e:	64e2                	ld	s1,24(sp)
    80002080:	6942                	ld	s2,16(sp)
    80002082:	69a2                	ld	s3,8(sp)
    80002084:	6145                	addi	sp,sp,48
    80002086:	8082                	ret
    panic("sched p->lock");
    80002088:	00006517          	auipc	a0,0x6
    8000208c:	22850513          	addi	a0,a0,552 # 800082b0 <digits+0x270>
    80002090:	ffffe097          	auipc	ra,0xffffe
    80002094:	4b0080e7          	jalr	1200(ra) # 80000540 <panic>
    panic("sched locks");
    80002098:	00006517          	auipc	a0,0x6
    8000209c:	22850513          	addi	a0,a0,552 # 800082c0 <digits+0x280>
    800020a0:	ffffe097          	auipc	ra,0xffffe
    800020a4:	4a0080e7          	jalr	1184(ra) # 80000540 <panic>
    panic("sched running");
    800020a8:	00006517          	auipc	a0,0x6
    800020ac:	22850513          	addi	a0,a0,552 # 800082d0 <digits+0x290>
    800020b0:	ffffe097          	auipc	ra,0xffffe
    800020b4:	490080e7          	jalr	1168(ra) # 80000540 <panic>
    panic("sched interruptible");
    800020b8:	00006517          	auipc	a0,0x6
    800020bc:	22850513          	addi	a0,a0,552 # 800082e0 <digits+0x2a0>
    800020c0:	ffffe097          	auipc	ra,0xffffe
    800020c4:	480080e7          	jalr	1152(ra) # 80000540 <panic>

00000000800020c8 <yield>:
{
    800020c8:	1101                	addi	sp,sp,-32
    800020ca:	ec06                	sd	ra,24(sp)
    800020cc:	e822                	sd	s0,16(sp)
    800020ce:	e426                	sd	s1,8(sp)
    800020d0:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800020d2:	00000097          	auipc	ra,0x0
    800020d6:	8da080e7          	jalr	-1830(ra) # 800019ac <myproc>
    800020da:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020dc:	fffff097          	auipc	ra,0xfffff
    800020e0:	afa080e7          	jalr	-1286(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    800020e4:	478d                	li	a5,3
    800020e6:	cc9c                	sw	a5,24(s1)
  sched();
    800020e8:	00000097          	auipc	ra,0x0
    800020ec:	f0a080e7          	jalr	-246(ra) # 80001ff2 <sched>
  release(&p->lock);
    800020f0:	8526                	mv	a0,s1
    800020f2:	fffff097          	auipc	ra,0xfffff
    800020f6:	b98080e7          	jalr	-1128(ra) # 80000c8a <release>
}
    800020fa:	60e2                	ld	ra,24(sp)
    800020fc:	6442                	ld	s0,16(sp)
    800020fe:	64a2                	ld	s1,8(sp)
    80002100:	6105                	addi	sp,sp,32
    80002102:	8082                	ret

0000000080002104 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
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
    80002116:	00000097          	auipc	ra,0x0
    8000211a:	896080e7          	jalr	-1898(ra) # 800019ac <myproc>
    8000211e:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002120:	fffff097          	auipc	ra,0xfffff
    80002124:	ab6080e7          	jalr	-1354(ra) # 80000bd6 <acquire>
  release(lk);
    80002128:	854a                	mv	a0,s2
    8000212a:	fffff097          	auipc	ra,0xfffff
    8000212e:	b60080e7          	jalr	-1184(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    80002132:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002136:	4789                	li	a5,2
    80002138:	cc9c                	sw	a5,24(s1)

  sched();
    8000213a:	00000097          	auipc	ra,0x0
    8000213e:	eb8080e7          	jalr	-328(ra) # 80001ff2 <sched>

  // Tidy up.
  p->chan = 0;
    80002142:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002146:	8526                	mv	a0,s1
    80002148:	fffff097          	auipc	ra,0xfffff
    8000214c:	b42080e7          	jalr	-1214(ra) # 80000c8a <release>
  acquire(lk);
    80002150:	854a                	mv	a0,s2
    80002152:	fffff097          	auipc	ra,0xfffff
    80002156:	a84080e7          	jalr	-1404(ra) # 80000bd6 <acquire>
}
    8000215a:	70a2                	ld	ra,40(sp)
    8000215c:	7402                	ld	s0,32(sp)
    8000215e:	64e2                	ld	s1,24(sp)
    80002160:	6942                	ld	s2,16(sp)
    80002162:	69a2                	ld	s3,8(sp)
    80002164:	6145                	addi	sp,sp,48
    80002166:	8082                	ret

0000000080002168 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002168:	7139                	addi	sp,sp,-64
    8000216a:	fc06                	sd	ra,56(sp)
    8000216c:	f822                	sd	s0,48(sp)
    8000216e:	f426                	sd	s1,40(sp)
    80002170:	f04a                	sd	s2,32(sp)
    80002172:	ec4e                	sd	s3,24(sp)
    80002174:	e852                	sd	s4,16(sp)
    80002176:	e456                	sd	s5,8(sp)
    80002178:	0080                	addi	s0,sp,64
    8000217a:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    8000217c:	0000f497          	auipc	s1,0xf
    80002180:	0e448493          	addi	s1,s1,228 # 80011260 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002184:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002186:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002188:	00015917          	auipc	s2,0x15
    8000218c:	cd890913          	addi	s2,s2,-808 # 80016e60 <tickslock>
    80002190:	a811                	j	800021a4 <wakeup+0x3c>
      }
      release(&p->lock);
    80002192:	8526                	mv	a0,s1
    80002194:	fffff097          	auipc	ra,0xfffff
    80002198:	af6080e7          	jalr	-1290(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000219c:	17048493          	addi	s1,s1,368
    800021a0:	03248663          	beq	s1,s2,800021cc <wakeup+0x64>
    if(p != myproc()){
    800021a4:	00000097          	auipc	ra,0x0
    800021a8:	808080e7          	jalr	-2040(ra) # 800019ac <myproc>
    800021ac:	fea488e3          	beq	s1,a0,8000219c <wakeup+0x34>
      acquire(&p->lock);
    800021b0:	8526                	mv	a0,s1
    800021b2:	fffff097          	auipc	ra,0xfffff
    800021b6:	a24080e7          	jalr	-1500(ra) # 80000bd6 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800021ba:	4c9c                	lw	a5,24(s1)
    800021bc:	fd379be3          	bne	a5,s3,80002192 <wakeup+0x2a>
    800021c0:	709c                	ld	a5,32(s1)
    800021c2:	fd4798e3          	bne	a5,s4,80002192 <wakeup+0x2a>
        p->state = RUNNABLE;
    800021c6:	0154ac23          	sw	s5,24(s1)
    800021ca:	b7e1                	j	80002192 <wakeup+0x2a>
    }
  }
}
    800021cc:	70e2                	ld	ra,56(sp)
    800021ce:	7442                	ld	s0,48(sp)
    800021d0:	74a2                	ld	s1,40(sp)
    800021d2:	7902                	ld	s2,32(sp)
    800021d4:	69e2                	ld	s3,24(sp)
    800021d6:	6a42                	ld	s4,16(sp)
    800021d8:	6aa2                	ld	s5,8(sp)
    800021da:	6121                	addi	sp,sp,64
    800021dc:	8082                	ret

00000000800021de <reparent>:
{
    800021de:	7179                	addi	sp,sp,-48
    800021e0:	f406                	sd	ra,40(sp)
    800021e2:	f022                	sd	s0,32(sp)
    800021e4:	ec26                	sd	s1,24(sp)
    800021e6:	e84a                	sd	s2,16(sp)
    800021e8:	e44e                	sd	s3,8(sp)
    800021ea:	e052                	sd	s4,0(sp)
    800021ec:	1800                	addi	s0,sp,48
    800021ee:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021f0:	0000f497          	auipc	s1,0xf
    800021f4:	07048493          	addi	s1,s1,112 # 80011260 <proc>
      pp->parent = initproc;
    800021f8:	00007a17          	auipc	s4,0x7
    800021fc:	9b0a0a13          	addi	s4,s4,-1616 # 80008ba8 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002200:	00015997          	auipc	s3,0x15
    80002204:	c6098993          	addi	s3,s3,-928 # 80016e60 <tickslock>
    80002208:	a029                	j	80002212 <reparent+0x34>
    8000220a:	17048493          	addi	s1,s1,368
    8000220e:	01348d63          	beq	s1,s3,80002228 <reparent+0x4a>
    if(pp->parent == p){
    80002212:	7c9c                	ld	a5,56(s1)
    80002214:	ff279be3          	bne	a5,s2,8000220a <reparent+0x2c>
      pp->parent = initproc;
    80002218:	000a3503          	ld	a0,0(s4)
    8000221c:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    8000221e:	00000097          	auipc	ra,0x0
    80002222:	f4a080e7          	jalr	-182(ra) # 80002168 <wakeup>
    80002226:	b7d5                	j	8000220a <reparent+0x2c>
}
    80002228:	70a2                	ld	ra,40(sp)
    8000222a:	7402                	ld	s0,32(sp)
    8000222c:	64e2                	ld	s1,24(sp)
    8000222e:	6942                	ld	s2,16(sp)
    80002230:	69a2                	ld	s3,8(sp)
    80002232:	6a02                	ld	s4,0(sp)
    80002234:	6145                	addi	sp,sp,48
    80002236:	8082                	ret

0000000080002238 <exit>:
{
    80002238:	7179                	addi	sp,sp,-48
    8000223a:	f406                	sd	ra,40(sp)
    8000223c:	f022                	sd	s0,32(sp)
    8000223e:	ec26                	sd	s1,24(sp)
    80002240:	e84a                	sd	s2,16(sp)
    80002242:	e44e                	sd	s3,8(sp)
    80002244:	e052                	sd	s4,0(sp)
    80002246:	1800                	addi	s0,sp,48
    80002248:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000224a:	fffff097          	auipc	ra,0xfffff
    8000224e:	762080e7          	jalr	1890(ra) # 800019ac <myproc>
    80002252:	89aa                	mv	s3,a0
  if(p == initproc)
    80002254:	00007797          	auipc	a5,0x7
    80002258:	9547b783          	ld	a5,-1708(a5) # 80008ba8 <initproc>
    8000225c:	0d050493          	addi	s1,a0,208
    80002260:	15050913          	addi	s2,a0,336
    80002264:	02a79363          	bne	a5,a0,8000228a <exit+0x52>
    panic("init exiting");
    80002268:	00006517          	auipc	a0,0x6
    8000226c:	09050513          	addi	a0,a0,144 # 800082f8 <digits+0x2b8>
    80002270:	ffffe097          	auipc	ra,0xffffe
    80002274:	2d0080e7          	jalr	720(ra) # 80000540 <panic>
      fileclose(f);
    80002278:	00002097          	auipc	ra,0x2
    8000227c:	49c080e7          	jalr	1180(ra) # 80004714 <fileclose>
      p->ofile[fd] = 0;
    80002280:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002284:	04a1                	addi	s1,s1,8
    80002286:	01248563          	beq	s1,s2,80002290 <exit+0x58>
    if(p->ofile[fd]){
    8000228a:	6088                	ld	a0,0(s1)
    8000228c:	f575                	bnez	a0,80002278 <exit+0x40>
    8000228e:	bfdd                	j	80002284 <exit+0x4c>
  begin_op();
    80002290:	00002097          	auipc	ra,0x2
    80002294:	fbc080e7          	jalr	-68(ra) # 8000424c <begin_op>
  iput(p->cwd);
    80002298:	1509b503          	ld	a0,336(s3)
    8000229c:	00001097          	auipc	ra,0x1
    800022a0:	79e080e7          	jalr	1950(ra) # 80003a3a <iput>
  end_op();
    800022a4:	00002097          	auipc	ra,0x2
    800022a8:	026080e7          	jalr	38(ra) # 800042ca <end_op>
  p->cwd = 0;
    800022ac:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800022b0:	0000f497          	auipc	s1,0xf
    800022b4:	b8848493          	addi	s1,s1,-1144 # 80010e38 <wait_lock>
    800022b8:	8526                	mv	a0,s1
    800022ba:	fffff097          	auipc	ra,0xfffff
    800022be:	91c080e7          	jalr	-1764(ra) # 80000bd6 <acquire>
  reparent(p);
    800022c2:	854e                	mv	a0,s3
    800022c4:	00000097          	auipc	ra,0x0
    800022c8:	f1a080e7          	jalr	-230(ra) # 800021de <reparent>
  wakeup(p->parent);
    800022cc:	0389b503          	ld	a0,56(s3)
    800022d0:	00000097          	auipc	ra,0x0
    800022d4:	e98080e7          	jalr	-360(ra) # 80002168 <wakeup>
  acquire(&p->lock);
    800022d8:	854e                	mv	a0,s3
    800022da:	fffff097          	auipc	ra,0xfffff
    800022de:	8fc080e7          	jalr	-1796(ra) # 80000bd6 <acquire>
  p->xstate = status;
    800022e2:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800022e6:	4795                	li	a5,5
    800022e8:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800022ec:	8526                	mv	a0,s1
    800022ee:	fffff097          	auipc	ra,0xfffff
    800022f2:	99c080e7          	jalr	-1636(ra) # 80000c8a <release>
  sched();
    800022f6:	00000097          	auipc	ra,0x0
    800022fa:	cfc080e7          	jalr	-772(ra) # 80001ff2 <sched>
  panic("zombie exit");
    800022fe:	00006517          	auipc	a0,0x6
    80002302:	00a50513          	addi	a0,a0,10 # 80008308 <digits+0x2c8>
    80002306:	ffffe097          	auipc	ra,0xffffe
    8000230a:	23a080e7          	jalr	570(ra) # 80000540 <panic>

000000008000230e <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000230e:	7179                	addi	sp,sp,-48
    80002310:	f406                	sd	ra,40(sp)
    80002312:	f022                	sd	s0,32(sp)
    80002314:	ec26                	sd	s1,24(sp)
    80002316:	e84a                	sd	s2,16(sp)
    80002318:	e44e                	sd	s3,8(sp)
    8000231a:	1800                	addi	s0,sp,48
    8000231c:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000231e:	0000f497          	auipc	s1,0xf
    80002322:	f4248493          	addi	s1,s1,-190 # 80011260 <proc>
    80002326:	00015997          	auipc	s3,0x15
    8000232a:	b3a98993          	addi	s3,s3,-1222 # 80016e60 <tickslock>
    acquire(&p->lock);
    8000232e:	8526                	mv	a0,s1
    80002330:	fffff097          	auipc	ra,0xfffff
    80002334:	8a6080e7          	jalr	-1882(ra) # 80000bd6 <acquire>
    if(p->pid == pid){
    80002338:	589c                	lw	a5,48(s1)
    8000233a:	01278d63          	beq	a5,s2,80002354 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000233e:	8526                	mv	a0,s1
    80002340:	fffff097          	auipc	ra,0xfffff
    80002344:	94a080e7          	jalr	-1718(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002348:	17048493          	addi	s1,s1,368
    8000234c:	ff3491e3          	bne	s1,s3,8000232e <kill+0x20>
  }
  return -1;
    80002350:	557d                	li	a0,-1
    80002352:	a829                	j	8000236c <kill+0x5e>
      p->killed = 1;
    80002354:	4785                	li	a5,1
    80002356:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002358:	4c98                	lw	a4,24(s1)
    8000235a:	4789                	li	a5,2
    8000235c:	00f70f63          	beq	a4,a5,8000237a <kill+0x6c>
      release(&p->lock);
    80002360:	8526                	mv	a0,s1
    80002362:	fffff097          	auipc	ra,0xfffff
    80002366:	928080e7          	jalr	-1752(ra) # 80000c8a <release>
      return 0;
    8000236a:	4501                	li	a0,0
}
    8000236c:	70a2                	ld	ra,40(sp)
    8000236e:	7402                	ld	s0,32(sp)
    80002370:	64e2                	ld	s1,24(sp)
    80002372:	6942                	ld	s2,16(sp)
    80002374:	69a2                	ld	s3,8(sp)
    80002376:	6145                	addi	sp,sp,48
    80002378:	8082                	ret
        p->state = RUNNABLE;
    8000237a:	478d                	li	a5,3
    8000237c:	cc9c                	sw	a5,24(s1)
    8000237e:	b7cd                	j	80002360 <kill+0x52>

0000000080002380 <setkilled>:

void
setkilled(struct proc *p)
{
    80002380:	1101                	addi	sp,sp,-32
    80002382:	ec06                	sd	ra,24(sp)
    80002384:	e822                	sd	s0,16(sp)
    80002386:	e426                	sd	s1,8(sp)
    80002388:	1000                	addi	s0,sp,32
    8000238a:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000238c:	fffff097          	auipc	ra,0xfffff
    80002390:	84a080e7          	jalr	-1974(ra) # 80000bd6 <acquire>
  p->killed = 1;
    80002394:	4785                	li	a5,1
    80002396:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002398:	8526                	mv	a0,s1
    8000239a:	fffff097          	auipc	ra,0xfffff
    8000239e:	8f0080e7          	jalr	-1808(ra) # 80000c8a <release>
}
    800023a2:	60e2                	ld	ra,24(sp)
    800023a4:	6442                	ld	s0,16(sp)
    800023a6:	64a2                	ld	s1,8(sp)
    800023a8:	6105                	addi	sp,sp,32
    800023aa:	8082                	ret

00000000800023ac <killed>:

int
killed(struct proc *p)
{
    800023ac:	1101                	addi	sp,sp,-32
    800023ae:	ec06                	sd	ra,24(sp)
    800023b0:	e822                	sd	s0,16(sp)
    800023b2:	e426                	sd	s1,8(sp)
    800023b4:	e04a                	sd	s2,0(sp)
    800023b6:	1000                	addi	s0,sp,32
    800023b8:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    800023ba:	fffff097          	auipc	ra,0xfffff
    800023be:	81c080e7          	jalr	-2020(ra) # 80000bd6 <acquire>
  k = p->killed;
    800023c2:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800023c6:	8526                	mv	a0,s1
    800023c8:	fffff097          	auipc	ra,0xfffff
    800023cc:	8c2080e7          	jalr	-1854(ra) # 80000c8a <release>
  return k;
}
    800023d0:	854a                	mv	a0,s2
    800023d2:	60e2                	ld	ra,24(sp)
    800023d4:	6442                	ld	s0,16(sp)
    800023d6:	64a2                	ld	s1,8(sp)
    800023d8:	6902                	ld	s2,0(sp)
    800023da:	6105                	addi	sp,sp,32
    800023dc:	8082                	ret

00000000800023de <wait>:
{
    800023de:	715d                	addi	sp,sp,-80
    800023e0:	e486                	sd	ra,72(sp)
    800023e2:	e0a2                	sd	s0,64(sp)
    800023e4:	fc26                	sd	s1,56(sp)
    800023e6:	f84a                	sd	s2,48(sp)
    800023e8:	f44e                	sd	s3,40(sp)
    800023ea:	f052                	sd	s4,32(sp)
    800023ec:	ec56                	sd	s5,24(sp)
    800023ee:	e85a                	sd	s6,16(sp)
    800023f0:	e45e                	sd	s7,8(sp)
    800023f2:	e062                	sd	s8,0(sp)
    800023f4:	0880                	addi	s0,sp,80
    800023f6:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800023f8:	fffff097          	auipc	ra,0xfffff
    800023fc:	5b4080e7          	jalr	1460(ra) # 800019ac <myproc>
    80002400:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002402:	0000f517          	auipc	a0,0xf
    80002406:	a3650513          	addi	a0,a0,-1482 # 80010e38 <wait_lock>
    8000240a:	ffffe097          	auipc	ra,0xffffe
    8000240e:	7cc080e7          	jalr	1996(ra) # 80000bd6 <acquire>
    havekids = 0;
    80002412:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    80002414:	4a15                	li	s4,5
        havekids = 1;
    80002416:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002418:	00015997          	auipc	s3,0x15
    8000241c:	a4898993          	addi	s3,s3,-1464 # 80016e60 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002420:	0000fc17          	auipc	s8,0xf
    80002424:	a18c0c13          	addi	s8,s8,-1512 # 80010e38 <wait_lock>
    havekids = 0;
    80002428:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000242a:	0000f497          	auipc	s1,0xf
    8000242e:	e3648493          	addi	s1,s1,-458 # 80011260 <proc>
    80002432:	a0bd                	j	800024a0 <wait+0xc2>
          pid = pp->pid;
    80002434:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002438:	000b0e63          	beqz	s6,80002454 <wait+0x76>
    8000243c:	4691                	li	a3,4
    8000243e:	02c48613          	addi	a2,s1,44
    80002442:	85da                	mv	a1,s6
    80002444:	05093503          	ld	a0,80(s2)
    80002448:	fffff097          	auipc	ra,0xfffff
    8000244c:	224080e7          	jalr	548(ra) # 8000166c <copyout>
    80002450:	02054563          	bltz	a0,8000247a <wait+0x9c>
          freeproc(pp);
    80002454:	8526                	mv	a0,s1
    80002456:	fffff097          	auipc	ra,0xfffff
    8000245a:	708080e7          	jalr	1800(ra) # 80001b5e <freeproc>
          release(&pp->lock);
    8000245e:	8526                	mv	a0,s1
    80002460:	fffff097          	auipc	ra,0xfffff
    80002464:	82a080e7          	jalr	-2006(ra) # 80000c8a <release>
          release(&wait_lock);
    80002468:	0000f517          	auipc	a0,0xf
    8000246c:	9d050513          	addi	a0,a0,-1584 # 80010e38 <wait_lock>
    80002470:	fffff097          	auipc	ra,0xfffff
    80002474:	81a080e7          	jalr	-2022(ra) # 80000c8a <release>
          return pid;
    80002478:	a0b5                	j	800024e4 <wait+0x106>
            release(&pp->lock);
    8000247a:	8526                	mv	a0,s1
    8000247c:	fffff097          	auipc	ra,0xfffff
    80002480:	80e080e7          	jalr	-2034(ra) # 80000c8a <release>
            release(&wait_lock);
    80002484:	0000f517          	auipc	a0,0xf
    80002488:	9b450513          	addi	a0,a0,-1612 # 80010e38 <wait_lock>
    8000248c:	ffffe097          	auipc	ra,0xffffe
    80002490:	7fe080e7          	jalr	2046(ra) # 80000c8a <release>
            return -1;
    80002494:	59fd                	li	s3,-1
    80002496:	a0b9                	j	800024e4 <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002498:	17048493          	addi	s1,s1,368
    8000249c:	03348463          	beq	s1,s3,800024c4 <wait+0xe6>
      if(pp->parent == p){
    800024a0:	7c9c                	ld	a5,56(s1)
    800024a2:	ff279be3          	bne	a5,s2,80002498 <wait+0xba>
        acquire(&pp->lock);
    800024a6:	8526                	mv	a0,s1
    800024a8:	ffffe097          	auipc	ra,0xffffe
    800024ac:	72e080e7          	jalr	1838(ra) # 80000bd6 <acquire>
        if(pp->state == ZOMBIE){
    800024b0:	4c9c                	lw	a5,24(s1)
    800024b2:	f94781e3          	beq	a5,s4,80002434 <wait+0x56>
        release(&pp->lock);
    800024b6:	8526                	mv	a0,s1
    800024b8:	ffffe097          	auipc	ra,0xffffe
    800024bc:	7d2080e7          	jalr	2002(ra) # 80000c8a <release>
        havekids = 1;
    800024c0:	8756                	mv	a4,s5
    800024c2:	bfd9                	j	80002498 <wait+0xba>
    if(!havekids || killed(p)){
    800024c4:	c719                	beqz	a4,800024d2 <wait+0xf4>
    800024c6:	854a                	mv	a0,s2
    800024c8:	00000097          	auipc	ra,0x0
    800024cc:	ee4080e7          	jalr	-284(ra) # 800023ac <killed>
    800024d0:	c51d                	beqz	a0,800024fe <wait+0x120>
      release(&wait_lock);
    800024d2:	0000f517          	auipc	a0,0xf
    800024d6:	96650513          	addi	a0,a0,-1690 # 80010e38 <wait_lock>
    800024da:	ffffe097          	auipc	ra,0xffffe
    800024de:	7b0080e7          	jalr	1968(ra) # 80000c8a <release>
      return -1;
    800024e2:	59fd                	li	s3,-1
}
    800024e4:	854e                	mv	a0,s3
    800024e6:	60a6                	ld	ra,72(sp)
    800024e8:	6406                	ld	s0,64(sp)
    800024ea:	74e2                	ld	s1,56(sp)
    800024ec:	7942                	ld	s2,48(sp)
    800024ee:	79a2                	ld	s3,40(sp)
    800024f0:	7a02                	ld	s4,32(sp)
    800024f2:	6ae2                	ld	s5,24(sp)
    800024f4:	6b42                	ld	s6,16(sp)
    800024f6:	6ba2                	ld	s7,8(sp)
    800024f8:	6c02                	ld	s8,0(sp)
    800024fa:	6161                	addi	sp,sp,80
    800024fc:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800024fe:	85e2                	mv	a1,s8
    80002500:	854a                	mv	a0,s2
    80002502:	00000097          	auipc	ra,0x0
    80002506:	c02080e7          	jalr	-1022(ra) # 80002104 <sleep>
    havekids = 0;
    8000250a:	bf39                	j	80002428 <wait+0x4a>

000000008000250c <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000250c:	7179                	addi	sp,sp,-48
    8000250e:	f406                	sd	ra,40(sp)
    80002510:	f022                	sd	s0,32(sp)
    80002512:	ec26                	sd	s1,24(sp)
    80002514:	e84a                	sd	s2,16(sp)
    80002516:	e44e                	sd	s3,8(sp)
    80002518:	e052                	sd	s4,0(sp)
    8000251a:	1800                	addi	s0,sp,48
    8000251c:	84aa                	mv	s1,a0
    8000251e:	892e                	mv	s2,a1
    80002520:	89b2                	mv	s3,a2
    80002522:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002524:	fffff097          	auipc	ra,0xfffff
    80002528:	488080e7          	jalr	1160(ra) # 800019ac <myproc>
  if(user_dst){
    8000252c:	c08d                	beqz	s1,8000254e <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000252e:	86d2                	mv	a3,s4
    80002530:	864e                	mv	a2,s3
    80002532:	85ca                	mv	a1,s2
    80002534:	6928                	ld	a0,80(a0)
    80002536:	fffff097          	auipc	ra,0xfffff
    8000253a:	136080e7          	jalr	310(ra) # 8000166c <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000253e:	70a2                	ld	ra,40(sp)
    80002540:	7402                	ld	s0,32(sp)
    80002542:	64e2                	ld	s1,24(sp)
    80002544:	6942                	ld	s2,16(sp)
    80002546:	69a2                	ld	s3,8(sp)
    80002548:	6a02                	ld	s4,0(sp)
    8000254a:	6145                	addi	sp,sp,48
    8000254c:	8082                	ret
    memmove((char *)dst, src, len);
    8000254e:	000a061b          	sext.w	a2,s4
    80002552:	85ce                	mv	a1,s3
    80002554:	854a                	mv	a0,s2
    80002556:	ffffe097          	auipc	ra,0xffffe
    8000255a:	7d8080e7          	jalr	2008(ra) # 80000d2e <memmove>
    return 0;
    8000255e:	8526                	mv	a0,s1
    80002560:	bff9                	j	8000253e <either_copyout+0x32>

0000000080002562 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002562:	7179                	addi	sp,sp,-48
    80002564:	f406                	sd	ra,40(sp)
    80002566:	f022                	sd	s0,32(sp)
    80002568:	ec26                	sd	s1,24(sp)
    8000256a:	e84a                	sd	s2,16(sp)
    8000256c:	e44e                	sd	s3,8(sp)
    8000256e:	e052                	sd	s4,0(sp)
    80002570:	1800                	addi	s0,sp,48
    80002572:	892a                	mv	s2,a0
    80002574:	84ae                	mv	s1,a1
    80002576:	89b2                	mv	s3,a2
    80002578:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000257a:	fffff097          	auipc	ra,0xfffff
    8000257e:	432080e7          	jalr	1074(ra) # 800019ac <myproc>
  if(user_src){
    80002582:	c08d                	beqz	s1,800025a4 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002584:	86d2                	mv	a3,s4
    80002586:	864e                	mv	a2,s3
    80002588:	85ca                	mv	a1,s2
    8000258a:	6928                	ld	a0,80(a0)
    8000258c:	fffff097          	auipc	ra,0xfffff
    80002590:	16c080e7          	jalr	364(ra) # 800016f8 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002594:	70a2                	ld	ra,40(sp)
    80002596:	7402                	ld	s0,32(sp)
    80002598:	64e2                	ld	s1,24(sp)
    8000259a:	6942                	ld	s2,16(sp)
    8000259c:	69a2                	ld	s3,8(sp)
    8000259e:	6a02                	ld	s4,0(sp)
    800025a0:	6145                	addi	sp,sp,48
    800025a2:	8082                	ret
    memmove(dst, (char*)src, len);
    800025a4:	000a061b          	sext.w	a2,s4
    800025a8:	85ce                	mv	a1,s3
    800025aa:	854a                	mv	a0,s2
    800025ac:	ffffe097          	auipc	ra,0xffffe
    800025b0:	782080e7          	jalr	1922(ra) # 80000d2e <memmove>
    return 0;
    800025b4:	8526                	mv	a0,s1
    800025b6:	bff9                	j	80002594 <either_copyin+0x32>

00000000800025b8 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800025b8:	715d                	addi	sp,sp,-80
    800025ba:	e486                	sd	ra,72(sp)
    800025bc:	e0a2                	sd	s0,64(sp)
    800025be:	fc26                	sd	s1,56(sp)
    800025c0:	f84a                	sd	s2,48(sp)
    800025c2:	f44e                	sd	s3,40(sp)
    800025c4:	f052                	sd	s4,32(sp)
    800025c6:	ec56                	sd	s5,24(sp)
    800025c8:	e85a                	sd	s6,16(sp)
    800025ca:	e45e                	sd	s7,8(sp)
    800025cc:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800025ce:	00006517          	auipc	a0,0x6
    800025d2:	afa50513          	addi	a0,a0,-1286 # 800080c8 <digits+0x88>
    800025d6:	ffffe097          	auipc	ra,0xffffe
    800025da:	fb4080e7          	jalr	-76(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025de:	0000f497          	auipc	s1,0xf
    800025e2:	dda48493          	addi	s1,s1,-550 # 800113b8 <proc+0x158>
    800025e6:	00015917          	auipc	s2,0x15
    800025ea:	9d290913          	addi	s2,s2,-1582 # 80016fb8 <bruh+0xe8>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025ee:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800025f0:	00006997          	auipc	s3,0x6
    800025f4:	d2898993          	addi	s3,s3,-728 # 80008318 <digits+0x2d8>
    printf("%d %s %s", p->pid, state, p->name);
    800025f8:	00006a97          	auipc	s5,0x6
    800025fc:	d28a8a93          	addi	s5,s5,-728 # 80008320 <digits+0x2e0>
    printf("\n");
    80002600:	00006a17          	auipc	s4,0x6
    80002604:	ac8a0a13          	addi	s4,s4,-1336 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002608:	00006b97          	auipc	s7,0x6
    8000260c:	d58b8b93          	addi	s7,s7,-680 # 80008360 <states.0>
    80002610:	a00d                	j	80002632 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002612:	ed86a583          	lw	a1,-296(a3)
    80002616:	8556                	mv	a0,s5
    80002618:	ffffe097          	auipc	ra,0xffffe
    8000261c:	f72080e7          	jalr	-142(ra) # 8000058a <printf>
    printf("\n");
    80002620:	8552                	mv	a0,s4
    80002622:	ffffe097          	auipc	ra,0xffffe
    80002626:	f68080e7          	jalr	-152(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000262a:	17048493          	addi	s1,s1,368
    8000262e:	03248263          	beq	s1,s2,80002652 <procdump+0x9a>
    if(p->state == UNUSED)
    80002632:	86a6                	mv	a3,s1
    80002634:	ec04a783          	lw	a5,-320(s1)
    80002638:	dbed                	beqz	a5,8000262a <procdump+0x72>
      state = "???";
    8000263a:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000263c:	fcfb6be3          	bltu	s6,a5,80002612 <procdump+0x5a>
    80002640:	02079713          	slli	a4,a5,0x20
    80002644:	01d75793          	srli	a5,a4,0x1d
    80002648:	97de                	add	a5,a5,s7
    8000264a:	6390                	ld	a2,0(a5)
    8000264c:	f279                	bnez	a2,80002612 <procdump+0x5a>
      state = "???";
    8000264e:	864e                	mv	a2,s3
    80002650:	b7c9                	j	80002612 <procdump+0x5a>
  }
}
    80002652:	60a6                	ld	ra,72(sp)
    80002654:	6406                	ld	s0,64(sp)
    80002656:	74e2                	ld	s1,56(sp)
    80002658:	7942                	ld	s2,48(sp)
    8000265a:	79a2                	ld	s3,40(sp)
    8000265c:	7a02                	ld	s4,32(sp)
    8000265e:	6ae2                	ld	s5,24(sp)
    80002660:	6b42                	ld	s6,16(sp)
    80002662:	6ba2                	ld	s7,8(sp)
    80002664:	6161                	addi	sp,sp,80
    80002666:	8082                	ret

0000000080002668 <swtch>:
    80002668:	00153023          	sd	ra,0(a0)
    8000266c:	00253423          	sd	sp,8(a0)
    80002670:	e900                	sd	s0,16(a0)
    80002672:	ed04                	sd	s1,24(a0)
    80002674:	03253023          	sd	s2,32(a0)
    80002678:	03353423          	sd	s3,40(a0)
    8000267c:	03453823          	sd	s4,48(a0)
    80002680:	03553c23          	sd	s5,56(a0)
    80002684:	05653023          	sd	s6,64(a0)
    80002688:	05753423          	sd	s7,72(a0)
    8000268c:	05853823          	sd	s8,80(a0)
    80002690:	05953c23          	sd	s9,88(a0)
    80002694:	07a53023          	sd	s10,96(a0)
    80002698:	07b53423          	sd	s11,104(a0)
    8000269c:	0005b083          	ld	ra,0(a1)
    800026a0:	0085b103          	ld	sp,8(a1)
    800026a4:	6980                	ld	s0,16(a1)
    800026a6:	6d84                	ld	s1,24(a1)
    800026a8:	0205b903          	ld	s2,32(a1)
    800026ac:	0285b983          	ld	s3,40(a1)
    800026b0:	0305ba03          	ld	s4,48(a1)
    800026b4:	0385ba83          	ld	s5,56(a1)
    800026b8:	0405bb03          	ld	s6,64(a1)
    800026bc:	0485bb83          	ld	s7,72(a1)
    800026c0:	0505bc03          	ld	s8,80(a1)
    800026c4:	0585bc83          	ld	s9,88(a1)
    800026c8:	0605bd03          	ld	s10,96(a1)
    800026cc:	0685bd83          	ld	s11,104(a1)
    800026d0:	8082                	ret

00000000800026d2 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026d2:	1141                	addi	sp,sp,-16
    800026d4:	e406                	sd	ra,8(sp)
    800026d6:	e022                	sd	s0,0(sp)
    800026d8:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026da:	00006597          	auipc	a1,0x6
    800026de:	cb658593          	addi	a1,a1,-842 # 80008390 <states.0+0x30>
    800026e2:	00014517          	auipc	a0,0x14
    800026e6:	77e50513          	addi	a0,a0,1918 # 80016e60 <tickslock>
    800026ea:	ffffe097          	auipc	ra,0xffffe
    800026ee:	45c080e7          	jalr	1116(ra) # 80000b46 <initlock>
}
    800026f2:	60a2                	ld	ra,8(sp)
    800026f4:	6402                	ld	s0,0(sp)
    800026f6:	0141                	addi	sp,sp,16
    800026f8:	8082                	ret

00000000800026fa <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800026fa:	1141                	addi	sp,sp,-16
    800026fc:	e422                	sd	s0,8(sp)
    800026fe:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002700:	00003797          	auipc	a5,0x3
    80002704:	66078793          	addi	a5,a5,1632 # 80005d60 <kernelvec>
    80002708:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000270c:	6422                	ld	s0,8(sp)
    8000270e:	0141                	addi	sp,sp,16
    80002710:	8082                	ret

0000000080002712 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002712:	1141                	addi	sp,sp,-16
    80002714:	e406                	sd	ra,8(sp)
    80002716:	e022                	sd	s0,0(sp)
    80002718:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000271a:	fffff097          	auipc	ra,0xfffff
    8000271e:	292080e7          	jalr	658(ra) # 800019ac <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002722:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002726:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002728:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    8000272c:	00005697          	auipc	a3,0x5
    80002730:	8d468693          	addi	a3,a3,-1836 # 80007000 <_trampoline>
    80002734:	00005717          	auipc	a4,0x5
    80002738:	8cc70713          	addi	a4,a4,-1844 # 80007000 <_trampoline>
    8000273c:	8f15                	sub	a4,a4,a3
    8000273e:	040007b7          	lui	a5,0x4000
    80002742:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002744:	07b2                	slli	a5,a5,0xc
    80002746:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002748:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000274c:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000274e:	18002673          	csrr	a2,satp
    80002752:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002754:	6d30                	ld	a2,88(a0)
    80002756:	6138                	ld	a4,64(a0)
    80002758:	6585                	lui	a1,0x1
    8000275a:	972e                	add	a4,a4,a1
    8000275c:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000275e:	6d38                	ld	a4,88(a0)
    80002760:	00000617          	auipc	a2,0x0
    80002764:	13060613          	addi	a2,a2,304 # 80002890 <usertrap>
    80002768:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000276a:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000276c:	8612                	mv	a2,tp
    8000276e:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002770:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002774:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002778:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000277c:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002780:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002782:	6f18                	ld	a4,24(a4)
    80002784:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002788:	6928                	ld	a0,80(a0)
    8000278a:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    8000278c:	00005717          	auipc	a4,0x5
    80002790:	91070713          	addi	a4,a4,-1776 # 8000709c <userret>
    80002794:	8f15                	sub	a4,a4,a3
    80002796:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002798:	577d                	li	a4,-1
    8000279a:	177e                	slli	a4,a4,0x3f
    8000279c:	8d59                	or	a0,a0,a4
    8000279e:	9782                	jalr	a5
}
    800027a0:	60a2                	ld	ra,8(sp)
    800027a2:	6402                	ld	s0,0(sp)
    800027a4:	0141                	addi	sp,sp,16
    800027a6:	8082                	ret

00000000800027a8 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800027a8:	1101                	addi	sp,sp,-32
    800027aa:	ec06                	sd	ra,24(sp)
    800027ac:	e822                	sd	s0,16(sp)
    800027ae:	e426                	sd	s1,8(sp)
    800027b0:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800027b2:	00014497          	auipc	s1,0x14
    800027b6:	6ae48493          	addi	s1,s1,1710 # 80016e60 <tickslock>
    800027ba:	8526                	mv	a0,s1
    800027bc:	ffffe097          	auipc	ra,0xffffe
    800027c0:	41a080e7          	jalr	1050(ra) # 80000bd6 <acquire>
  ticks++;
    800027c4:	00006517          	auipc	a0,0x6
    800027c8:	3ec50513          	addi	a0,a0,1004 # 80008bb0 <ticks>
    800027cc:	411c                	lw	a5,0(a0)
    800027ce:	2785                	addiw	a5,a5,1
    800027d0:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800027d2:	00000097          	auipc	ra,0x0
    800027d6:	996080e7          	jalr	-1642(ra) # 80002168 <wakeup>
  release(&tickslock);
    800027da:	8526                	mv	a0,s1
    800027dc:	ffffe097          	auipc	ra,0xffffe
    800027e0:	4ae080e7          	jalr	1198(ra) # 80000c8a <release>
}
    800027e4:	60e2                	ld	ra,24(sp)
    800027e6:	6442                	ld	s0,16(sp)
    800027e8:	64a2                	ld	s1,8(sp)
    800027ea:	6105                	addi	sp,sp,32
    800027ec:	8082                	ret

00000000800027ee <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800027ee:	1101                	addi	sp,sp,-32
    800027f0:	ec06                	sd	ra,24(sp)
    800027f2:	e822                	sd	s0,16(sp)
    800027f4:	e426                	sd	s1,8(sp)
    800027f6:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027f8:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800027fc:	00074d63          	bltz	a4,80002816 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002800:	57fd                	li	a5,-1
    80002802:	17fe                	slli	a5,a5,0x3f
    80002804:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002806:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002808:	06f70363          	beq	a4,a5,8000286e <devintr+0x80>
  }
}
    8000280c:	60e2                	ld	ra,24(sp)
    8000280e:	6442                	ld	s0,16(sp)
    80002810:	64a2                	ld	s1,8(sp)
    80002812:	6105                	addi	sp,sp,32
    80002814:	8082                	ret
     (scause & 0xff) == 9){
    80002816:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    8000281a:	46a5                	li	a3,9
    8000281c:	fed792e3          	bne	a5,a3,80002800 <devintr+0x12>
    int irq = plic_claim();
    80002820:	00003097          	auipc	ra,0x3
    80002824:	648080e7          	jalr	1608(ra) # 80005e68 <plic_claim>
    80002828:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000282a:	47a9                	li	a5,10
    8000282c:	02f50763          	beq	a0,a5,8000285a <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002830:	4785                	li	a5,1
    80002832:	02f50963          	beq	a0,a5,80002864 <devintr+0x76>
    return 1;
    80002836:	4505                	li	a0,1
    } else if(irq){
    80002838:	d8f1                	beqz	s1,8000280c <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000283a:	85a6                	mv	a1,s1
    8000283c:	00006517          	auipc	a0,0x6
    80002840:	b5c50513          	addi	a0,a0,-1188 # 80008398 <states.0+0x38>
    80002844:	ffffe097          	auipc	ra,0xffffe
    80002848:	d46080e7          	jalr	-698(ra) # 8000058a <printf>
      plic_complete(irq);
    8000284c:	8526                	mv	a0,s1
    8000284e:	00003097          	auipc	ra,0x3
    80002852:	63e080e7          	jalr	1598(ra) # 80005e8c <plic_complete>
    return 1;
    80002856:	4505                	li	a0,1
    80002858:	bf55                	j	8000280c <devintr+0x1e>
      uartintr();
    8000285a:	ffffe097          	auipc	ra,0xffffe
    8000285e:	13e080e7          	jalr	318(ra) # 80000998 <uartintr>
    80002862:	b7ed                	j	8000284c <devintr+0x5e>
      virtio_disk_intr();
    80002864:	00004097          	auipc	ra,0x4
    80002868:	af0080e7          	jalr	-1296(ra) # 80006354 <virtio_disk_intr>
    8000286c:	b7c5                	j	8000284c <devintr+0x5e>
    if(cpuid() == 0){
    8000286e:	fffff097          	auipc	ra,0xfffff
    80002872:	112080e7          	jalr	274(ra) # 80001980 <cpuid>
    80002876:	c901                	beqz	a0,80002886 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002878:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000287c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000287e:	14479073          	csrw	sip,a5
    return 2;
    80002882:	4509                	li	a0,2
    80002884:	b761                	j	8000280c <devintr+0x1e>
      clockintr();
    80002886:	00000097          	auipc	ra,0x0
    8000288a:	f22080e7          	jalr	-222(ra) # 800027a8 <clockintr>
    8000288e:	b7ed                	j	80002878 <devintr+0x8a>

0000000080002890 <usertrap>:
{
    80002890:	1101                	addi	sp,sp,-32
    80002892:	ec06                	sd	ra,24(sp)
    80002894:	e822                	sd	s0,16(sp)
    80002896:	e426                	sd	s1,8(sp)
    80002898:	e04a                	sd	s2,0(sp)
    8000289a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000289c:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800028a0:	1007f793          	andi	a5,a5,256
    800028a4:	e3b1                	bnez	a5,800028e8 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028a6:	00003797          	auipc	a5,0x3
    800028aa:	4ba78793          	addi	a5,a5,1210 # 80005d60 <kernelvec>
    800028ae:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800028b2:	fffff097          	auipc	ra,0xfffff
    800028b6:	0fa080e7          	jalr	250(ra) # 800019ac <myproc>
    800028ba:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800028bc:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028be:	14102773          	csrr	a4,sepc
    800028c2:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028c4:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800028c8:	47a1                	li	a5,8
    800028ca:	02f70763          	beq	a4,a5,800028f8 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    800028ce:	00000097          	auipc	ra,0x0
    800028d2:	f20080e7          	jalr	-224(ra) # 800027ee <devintr>
    800028d6:	892a                	mv	s2,a0
    800028d8:	c151                	beqz	a0,8000295c <usertrap+0xcc>
  if(killed(p))
    800028da:	8526                	mv	a0,s1
    800028dc:	00000097          	auipc	ra,0x0
    800028e0:	ad0080e7          	jalr	-1328(ra) # 800023ac <killed>
    800028e4:	c929                	beqz	a0,80002936 <usertrap+0xa6>
    800028e6:	a099                	j	8000292c <usertrap+0x9c>
    panic("usertrap: not from user mode");
    800028e8:	00006517          	auipc	a0,0x6
    800028ec:	ad050513          	addi	a0,a0,-1328 # 800083b8 <states.0+0x58>
    800028f0:	ffffe097          	auipc	ra,0xffffe
    800028f4:	c50080e7          	jalr	-944(ra) # 80000540 <panic>
    if(killed(p))
    800028f8:	00000097          	auipc	ra,0x0
    800028fc:	ab4080e7          	jalr	-1356(ra) # 800023ac <killed>
    80002900:	e921                	bnez	a0,80002950 <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002902:	6cb8                	ld	a4,88(s1)
    80002904:	6f1c                	ld	a5,24(a4)
    80002906:	0791                	addi	a5,a5,4
    80002908:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000290a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000290e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002912:	10079073          	csrw	sstatus,a5
    syscall();
    80002916:	00000097          	auipc	ra,0x0
    8000291a:	2d4080e7          	jalr	724(ra) # 80002bea <syscall>
  if(killed(p))
    8000291e:	8526                	mv	a0,s1
    80002920:	00000097          	auipc	ra,0x0
    80002924:	a8c080e7          	jalr	-1396(ra) # 800023ac <killed>
    80002928:	c911                	beqz	a0,8000293c <usertrap+0xac>
    8000292a:	4901                	li	s2,0
    exit(-1);
    8000292c:	557d                	li	a0,-1
    8000292e:	00000097          	auipc	ra,0x0
    80002932:	90a080e7          	jalr	-1782(ra) # 80002238 <exit>
  if(which_dev == 2)
    80002936:	4789                	li	a5,2
    80002938:	04f90f63          	beq	s2,a5,80002996 <usertrap+0x106>
  usertrapret();
    8000293c:	00000097          	auipc	ra,0x0
    80002940:	dd6080e7          	jalr	-554(ra) # 80002712 <usertrapret>
}
    80002944:	60e2                	ld	ra,24(sp)
    80002946:	6442                	ld	s0,16(sp)
    80002948:	64a2                	ld	s1,8(sp)
    8000294a:	6902                	ld	s2,0(sp)
    8000294c:	6105                	addi	sp,sp,32
    8000294e:	8082                	ret
      exit(-1);
    80002950:	557d                	li	a0,-1
    80002952:	00000097          	auipc	ra,0x0
    80002956:	8e6080e7          	jalr	-1818(ra) # 80002238 <exit>
    8000295a:	b765                	j	80002902 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000295c:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002960:	5890                	lw	a2,48(s1)
    80002962:	00006517          	auipc	a0,0x6
    80002966:	a7650513          	addi	a0,a0,-1418 # 800083d8 <states.0+0x78>
    8000296a:	ffffe097          	auipc	ra,0xffffe
    8000296e:	c20080e7          	jalr	-992(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002972:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002976:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000297a:	00006517          	auipc	a0,0x6
    8000297e:	a8e50513          	addi	a0,a0,-1394 # 80008408 <states.0+0xa8>
    80002982:	ffffe097          	auipc	ra,0xffffe
    80002986:	c08080e7          	jalr	-1016(ra) # 8000058a <printf>
    setkilled(p);
    8000298a:	8526                	mv	a0,s1
    8000298c:	00000097          	auipc	ra,0x0
    80002990:	9f4080e7          	jalr	-1548(ra) # 80002380 <setkilled>
    80002994:	b769                	j	8000291e <usertrap+0x8e>
    yield();
    80002996:	fffff097          	auipc	ra,0xfffff
    8000299a:	732080e7          	jalr	1842(ra) # 800020c8 <yield>
    8000299e:	bf79                	j	8000293c <usertrap+0xac>

00000000800029a0 <kerneltrap>:
{
    800029a0:	7179                	addi	sp,sp,-48
    800029a2:	f406                	sd	ra,40(sp)
    800029a4:	f022                	sd	s0,32(sp)
    800029a6:	ec26                	sd	s1,24(sp)
    800029a8:	e84a                	sd	s2,16(sp)
    800029aa:	e44e                	sd	s3,8(sp)
    800029ac:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029ae:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029b2:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029b6:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800029ba:	1004f793          	andi	a5,s1,256
    800029be:	cb85                	beqz	a5,800029ee <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029c0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800029c4:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800029c6:	ef85                	bnez	a5,800029fe <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800029c8:	00000097          	auipc	ra,0x0
    800029cc:	e26080e7          	jalr	-474(ra) # 800027ee <devintr>
    800029d0:	cd1d                	beqz	a0,80002a0e <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029d2:	4789                	li	a5,2
    800029d4:	06f50a63          	beq	a0,a5,80002a48 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029d8:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029dc:	10049073          	csrw	sstatus,s1
}
    800029e0:	70a2                	ld	ra,40(sp)
    800029e2:	7402                	ld	s0,32(sp)
    800029e4:	64e2                	ld	s1,24(sp)
    800029e6:	6942                	ld	s2,16(sp)
    800029e8:	69a2                	ld	s3,8(sp)
    800029ea:	6145                	addi	sp,sp,48
    800029ec:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800029ee:	00006517          	auipc	a0,0x6
    800029f2:	a3a50513          	addi	a0,a0,-1478 # 80008428 <states.0+0xc8>
    800029f6:	ffffe097          	auipc	ra,0xffffe
    800029fa:	b4a080e7          	jalr	-1206(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    800029fe:	00006517          	auipc	a0,0x6
    80002a02:	a5250513          	addi	a0,a0,-1454 # 80008450 <states.0+0xf0>
    80002a06:	ffffe097          	auipc	ra,0xffffe
    80002a0a:	b3a080e7          	jalr	-1222(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80002a0e:	85ce                	mv	a1,s3
    80002a10:	00006517          	auipc	a0,0x6
    80002a14:	a6050513          	addi	a0,a0,-1440 # 80008470 <states.0+0x110>
    80002a18:	ffffe097          	auipc	ra,0xffffe
    80002a1c:	b72080e7          	jalr	-1166(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a20:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a24:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a28:	00006517          	auipc	a0,0x6
    80002a2c:	a5850513          	addi	a0,a0,-1448 # 80008480 <states.0+0x120>
    80002a30:	ffffe097          	auipc	ra,0xffffe
    80002a34:	b5a080e7          	jalr	-1190(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002a38:	00006517          	auipc	a0,0x6
    80002a3c:	a6050513          	addi	a0,a0,-1440 # 80008498 <states.0+0x138>
    80002a40:	ffffe097          	auipc	ra,0xffffe
    80002a44:	b00080e7          	jalr	-1280(ra) # 80000540 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a48:	fffff097          	auipc	ra,0xfffff
    80002a4c:	f64080e7          	jalr	-156(ra) # 800019ac <myproc>
    80002a50:	d541                	beqz	a0,800029d8 <kerneltrap+0x38>
    80002a52:	fffff097          	auipc	ra,0xfffff
    80002a56:	f5a080e7          	jalr	-166(ra) # 800019ac <myproc>
    80002a5a:	4d18                	lw	a4,24(a0)
    80002a5c:	4791                	li	a5,4
    80002a5e:	f6f71de3          	bne	a4,a5,800029d8 <kerneltrap+0x38>
    yield();
    80002a62:	fffff097          	auipc	ra,0xfffff
    80002a66:	666080e7          	jalr	1638(ra) # 800020c8 <yield>
    80002a6a:	b7bd                	j	800029d8 <kerneltrap+0x38>

0000000080002a6c <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a6c:	1101                	addi	sp,sp,-32
    80002a6e:	ec06                	sd	ra,24(sp)
    80002a70:	e822                	sd	s0,16(sp)
    80002a72:	e426                	sd	s1,8(sp)
    80002a74:	1000                	addi	s0,sp,32
    80002a76:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a78:	fffff097          	auipc	ra,0xfffff
    80002a7c:	f34080e7          	jalr	-204(ra) # 800019ac <myproc>
  switch (n) {
    80002a80:	4795                	li	a5,5
    80002a82:	0497e163          	bltu	a5,s1,80002ac4 <argraw+0x58>
    80002a86:	048a                	slli	s1,s1,0x2
    80002a88:	00006717          	auipc	a4,0x6
    80002a8c:	b8070713          	addi	a4,a4,-1152 # 80008608 <states.0+0x2a8>
    80002a90:	94ba                	add	s1,s1,a4
    80002a92:	409c                	lw	a5,0(s1)
    80002a94:	97ba                	add	a5,a5,a4
    80002a96:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a98:	6d3c                	ld	a5,88(a0)
    80002a9a:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a9c:	60e2                	ld	ra,24(sp)
    80002a9e:	6442                	ld	s0,16(sp)
    80002aa0:	64a2                	ld	s1,8(sp)
    80002aa2:	6105                	addi	sp,sp,32
    80002aa4:	8082                	ret
    return p->trapframe->a1;
    80002aa6:	6d3c                	ld	a5,88(a0)
    80002aa8:	7fa8                	ld	a0,120(a5)
    80002aaa:	bfcd                	j	80002a9c <argraw+0x30>
    return p->trapframe->a2;
    80002aac:	6d3c                	ld	a5,88(a0)
    80002aae:	63c8                	ld	a0,128(a5)
    80002ab0:	b7f5                	j	80002a9c <argraw+0x30>
    return p->trapframe->a3;
    80002ab2:	6d3c                	ld	a5,88(a0)
    80002ab4:	67c8                	ld	a0,136(a5)
    80002ab6:	b7dd                	j	80002a9c <argraw+0x30>
    return p->trapframe->a4;
    80002ab8:	6d3c                	ld	a5,88(a0)
    80002aba:	6bc8                	ld	a0,144(a5)
    80002abc:	b7c5                	j	80002a9c <argraw+0x30>
    return p->trapframe->a5;
    80002abe:	6d3c                	ld	a5,88(a0)
    80002ac0:	6fc8                	ld	a0,152(a5)
    80002ac2:	bfe9                	j	80002a9c <argraw+0x30>
  panic("argraw");
    80002ac4:	00006517          	auipc	a0,0x6
    80002ac8:	9e450513          	addi	a0,a0,-1564 # 800084a8 <states.0+0x148>
    80002acc:	ffffe097          	auipc	ra,0xffffe
    80002ad0:	a74080e7          	jalr	-1420(ra) # 80000540 <panic>

0000000080002ad4 <fetchaddr>:
{
    80002ad4:	1101                	addi	sp,sp,-32
    80002ad6:	ec06                	sd	ra,24(sp)
    80002ad8:	e822                	sd	s0,16(sp)
    80002ada:	e426                	sd	s1,8(sp)
    80002adc:	e04a                	sd	s2,0(sp)
    80002ade:	1000                	addi	s0,sp,32
    80002ae0:	84aa                	mv	s1,a0
    80002ae2:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002ae4:	fffff097          	auipc	ra,0xfffff
    80002ae8:	ec8080e7          	jalr	-312(ra) # 800019ac <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002aec:	653c                	ld	a5,72(a0)
    80002aee:	02f4f863          	bgeu	s1,a5,80002b1e <fetchaddr+0x4a>
    80002af2:	00848713          	addi	a4,s1,8
    80002af6:	02e7e663          	bltu	a5,a4,80002b22 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002afa:	46a1                	li	a3,8
    80002afc:	8626                	mv	a2,s1
    80002afe:	85ca                	mv	a1,s2
    80002b00:	6928                	ld	a0,80(a0)
    80002b02:	fffff097          	auipc	ra,0xfffff
    80002b06:	bf6080e7          	jalr	-1034(ra) # 800016f8 <copyin>
    80002b0a:	00a03533          	snez	a0,a0
    80002b0e:	40a00533          	neg	a0,a0
}
    80002b12:	60e2                	ld	ra,24(sp)
    80002b14:	6442                	ld	s0,16(sp)
    80002b16:	64a2                	ld	s1,8(sp)
    80002b18:	6902                	ld	s2,0(sp)
    80002b1a:	6105                	addi	sp,sp,32
    80002b1c:	8082                	ret
    return -1;
    80002b1e:	557d                	li	a0,-1
    80002b20:	bfcd                	j	80002b12 <fetchaddr+0x3e>
    80002b22:	557d                	li	a0,-1
    80002b24:	b7fd                	j	80002b12 <fetchaddr+0x3e>

0000000080002b26 <fetchstr>:
{
    80002b26:	7179                	addi	sp,sp,-48
    80002b28:	f406                	sd	ra,40(sp)
    80002b2a:	f022                	sd	s0,32(sp)
    80002b2c:	ec26                	sd	s1,24(sp)
    80002b2e:	e84a                	sd	s2,16(sp)
    80002b30:	e44e                	sd	s3,8(sp)
    80002b32:	1800                	addi	s0,sp,48
    80002b34:	892a                	mv	s2,a0
    80002b36:	84ae                	mv	s1,a1
    80002b38:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b3a:	fffff097          	auipc	ra,0xfffff
    80002b3e:	e72080e7          	jalr	-398(ra) # 800019ac <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002b42:	86ce                	mv	a3,s3
    80002b44:	864a                	mv	a2,s2
    80002b46:	85a6                	mv	a1,s1
    80002b48:	6928                	ld	a0,80(a0)
    80002b4a:	fffff097          	auipc	ra,0xfffff
    80002b4e:	c3c080e7          	jalr	-964(ra) # 80001786 <copyinstr>
    80002b52:	00054e63          	bltz	a0,80002b6e <fetchstr+0x48>
  return strlen(buf);
    80002b56:	8526                	mv	a0,s1
    80002b58:	ffffe097          	auipc	ra,0xffffe
    80002b5c:	2f6080e7          	jalr	758(ra) # 80000e4e <strlen>
}
    80002b60:	70a2                	ld	ra,40(sp)
    80002b62:	7402                	ld	s0,32(sp)
    80002b64:	64e2                	ld	s1,24(sp)
    80002b66:	6942                	ld	s2,16(sp)
    80002b68:	69a2                	ld	s3,8(sp)
    80002b6a:	6145                	addi	sp,sp,48
    80002b6c:	8082                	ret
    return -1;
    80002b6e:	557d                	li	a0,-1
    80002b70:	bfc5                	j	80002b60 <fetchstr+0x3a>

0000000080002b72 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002b72:	1101                	addi	sp,sp,-32
    80002b74:	ec06                	sd	ra,24(sp)
    80002b76:	e822                	sd	s0,16(sp)
    80002b78:	e426                	sd	s1,8(sp)
    80002b7a:	1000                	addi	s0,sp,32
    80002b7c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b7e:	00000097          	auipc	ra,0x0
    80002b82:	eee080e7          	jalr	-274(ra) # 80002a6c <argraw>
    80002b86:	c088                	sw	a0,0(s1)
}
    80002b88:	60e2                	ld	ra,24(sp)
    80002b8a:	6442                	ld	s0,16(sp)
    80002b8c:	64a2                	ld	s1,8(sp)
    80002b8e:	6105                	addi	sp,sp,32
    80002b90:	8082                	ret

0000000080002b92 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002b92:	1101                	addi	sp,sp,-32
    80002b94:	ec06                	sd	ra,24(sp)
    80002b96:	e822                	sd	s0,16(sp)
    80002b98:	e426                	sd	s1,8(sp)
    80002b9a:	1000                	addi	s0,sp,32
    80002b9c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b9e:	00000097          	auipc	ra,0x0
    80002ba2:	ece080e7          	jalr	-306(ra) # 80002a6c <argraw>
    80002ba6:	e088                	sd	a0,0(s1)
}
    80002ba8:	60e2                	ld	ra,24(sp)
    80002baa:	6442                	ld	s0,16(sp)
    80002bac:	64a2                	ld	s1,8(sp)
    80002bae:	6105                	addi	sp,sp,32
    80002bb0:	8082                	ret

0000000080002bb2 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002bb2:	7179                	addi	sp,sp,-48
    80002bb4:	f406                	sd	ra,40(sp)
    80002bb6:	f022                	sd	s0,32(sp)
    80002bb8:	ec26                	sd	s1,24(sp)
    80002bba:	e84a                	sd	s2,16(sp)
    80002bbc:	1800                	addi	s0,sp,48
    80002bbe:	84ae                	mv	s1,a1
    80002bc0:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002bc2:	fd840593          	addi	a1,s0,-40
    80002bc6:	00000097          	auipc	ra,0x0
    80002bca:	fcc080e7          	jalr	-52(ra) # 80002b92 <argaddr>
  return fetchstr(addr, buf, max);
    80002bce:	864a                	mv	a2,s2
    80002bd0:	85a6                	mv	a1,s1
    80002bd2:	fd843503          	ld	a0,-40(s0)
    80002bd6:	00000097          	auipc	ra,0x0
    80002bda:	f50080e7          	jalr	-176(ra) # 80002b26 <fetchstr>
}
    80002bde:	70a2                	ld	ra,40(sp)
    80002be0:	7402                	ld	s0,32(sp)
    80002be2:	64e2                	ld	s1,24(sp)
    80002be4:	6942                	ld	s2,16(sp)
    80002be6:	6145                	addi	sp,sp,48
    80002be8:	8082                	ret

0000000080002bea <syscall>:
};


void
syscall(void)
{
    80002bea:	711d                	addi	sp,sp,-96
    80002bec:	ec86                	sd	ra,88(sp)
    80002bee:	e8a2                	sd	s0,80(sp)
    80002bf0:	e4a6                	sd	s1,72(sp)
    80002bf2:	e0ca                	sd	s2,64(sp)
    80002bf4:	fc4e                	sd	s3,56(sp)
    80002bf6:	f852                	sd	s4,48(sp)
    80002bf8:	f456                	sd	s5,40(sp)
    80002bfa:	f05a                	sd	s6,32(sp)
    80002bfc:	ec5e                	sd	s7,24(sp)
    80002bfe:	e862                	sd	s8,16(sp)
    80002c00:	e466                	sd	s9,8(sp)
    80002c02:	1080                	addi	s0,sp,96
  int num;
  struct proc *p = myproc();
    80002c04:	fffff097          	auipc	ra,0xfffff
    80002c08:	da8080e7          	jalr	-600(ra) # 800019ac <myproc>
    80002c0c:	89aa                	mv	s3,a0

  num = p->trapframe->a7;
    80002c0e:	6d24                	ld	s1,88(a0)
    80002c10:	74dc                	ld	a5,168(s1)
    80002c12:	00078a1b          	sext.w	s4,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c16:	37fd                	addiw	a5,a5,-1
    80002c18:	4755                	li	a4,21
    80002c1a:	14f76263          	bltu	a4,a5,80002d5e <syscall+0x174>
    80002c1e:	003a1713          	slli	a4,s4,0x3
    80002c22:	00006797          	auipc	a5,0x6
    80002c26:	9fe78793          	addi	a5,a5,-1538 # 80008620 <syscalls>
    80002c2a:	97ba                	add	a5,a5,a4
    80002c2c:	639c                	ld	a5,0(a5)
    80002c2e:	12078863          	beqz	a5,80002d5e <syscall+0x174>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0

    p->trapframe->a0 = syscalls[num]();
    80002c32:	9782                	jalr	a5
    80002c34:	f8a8                	sd	a0,112(s1)
    // if our system call was AUDIT, we specifically need to take what's in a0
    // out right here. this contains the whitelist array for what calls to audit
    if (num == 22) {
    80002c36:	47d9                	li	a5,22
    80002c38:	04fa0463          	beq	s4,a5,80002c80 <syscall+0x96>
      }
      declared_length = *(bruh->length);
      printf("process %s with id %d called audit at time %d\n", p->name, p->pid, ticks);
      printf("declared length: %d\n", declared_length);
    }
    if (!declared_length) {
    80002c3c:	00006797          	auipc	a5,0x6
    80002c40:	f787a783          	lw	a5,-136(a5) # 80008bb4 <declared_length>
    80002c44:	cfdd                	beqz	a5,80002d02 <syscall+0x118>
      // nothing is whitelisted.
      printf("process %s with id %d called %s at time %d\n", p->name, p->pid, name_from_num[num], ticks);
    } else {
      // something is whitelisted.
      for (int i = 0; i < declared_length; i++) {
    80002c46:	00014497          	auipc	s1,0x14
    80002c4a:	23248493          	addi	s1,s1,562 # 80016e78 <whitelisted>
    80002c4e:	4901                	li	s2,0
    80002c50:	12f05863          	blez	a5,80002d80 <syscall+0x196>
        // if it's whitelisted, we care. otherwise, just let it time out.
        if (num == whitelisted[i]) {
          printf("process %s with id %d called %s at time %d\n", p->name, p->pid, name_from_num[num], ticks);
    80002c54:	00006b97          	auipc	s7,0x6
    80002c58:	f5cb8b93          	addi	s7,s7,-164 # 80008bb0 <ticks>
    80002c5c:	003a1793          	slli	a5,s4,0x3
    80002c60:	00006b17          	auipc	s6,0x6
    80002c64:	e28b0b13          	addi	s6,s6,-472 # 80008a88 <name_from_num>
    80002c68:	9b3e                	add	s6,s6,a5
    80002c6a:	15898c93          	addi	s9,s3,344
    80002c6e:	00006c17          	auipc	s8,0x6
    80002c72:	89ac0c13          	addi	s8,s8,-1894 # 80008508 <states.0+0x1a8>
      for (int i = 0; i < declared_length; i++) {
    80002c76:	00006a97          	auipc	s5,0x6
    80002c7a:	f3ea8a93          	addi	s5,s5,-194 # 80008bb4 <declared_length>
    80002c7e:	a0c1                	j	80002d3e <syscall+0x154>
      struct aud* bruh = (struct aud*)p->trapframe->a0;
    80002c80:	0589b783          	ld	a5,88(s3)
    80002c84:	7ba4                	ld	s1,112(a5)
      printf("edit in kernel\n");
    80002c86:	00006517          	auipc	a0,0x6
    80002c8a:	82a50513          	addi	a0,a0,-2006 # 800084b0 <states.0+0x150>
    80002c8e:	ffffe097          	auipc	ra,0xffffe
    80002c92:	8fc080e7          	jalr	-1796(ra) # 8000058a <printf>
      for (int i = 0; i < *(bruh->length); i++) {
    80002c96:	649c                	ld	a5,8(s1)
    80002c98:	4398                	lw	a4,0(a5)
    80002c9a:	02e05563          	blez	a4,80002cc4 <syscall+0xda>
    80002c9e:	00014697          	auipc	a3,0x14
    80002ca2:	1da68693          	addi	a3,a3,474 # 80016e78 <whitelisted>
    80002ca6:	4781                	li	a5,0
        whitelisted[i] = *(bruh->arr + i);
    80002ca8:	6098                	ld	a4,0(s1)
    80002caa:	00279613          	slli	a2,a5,0x2
    80002cae:	9732                	add	a4,a4,a2
    80002cb0:	4318                	lw	a4,0(a4)
    80002cb2:	c298                	sw	a4,0(a3)
      for (int i = 0; i < *(bruh->length); i++) {
    80002cb4:	6498                	ld	a4,8(s1)
    80002cb6:	4318                	lw	a4,0(a4)
    80002cb8:	0785                	addi	a5,a5,1
    80002cba:	0691                	addi	a3,a3,4
    80002cbc:	0007861b          	sext.w	a2,a5
    80002cc0:	fee644e3          	blt	a2,a4,80002ca8 <syscall+0xbe>
      declared_length = *(bruh->length);
    80002cc4:	00006497          	auipc	s1,0x6
    80002cc8:	ef048493          	addi	s1,s1,-272 # 80008bb4 <declared_length>
    80002ccc:	c098                	sw	a4,0(s1)
      printf("process %s with id %d called audit at time %d\n", p->name, p->pid, ticks);
    80002cce:	00006697          	auipc	a3,0x6
    80002cd2:	ee26a683          	lw	a3,-286(a3) # 80008bb0 <ticks>
    80002cd6:	0309a603          	lw	a2,48(s3)
    80002cda:	15898593          	addi	a1,s3,344
    80002cde:	00005517          	auipc	a0,0x5
    80002ce2:	7e250513          	addi	a0,a0,2018 # 800084c0 <states.0+0x160>
    80002ce6:	ffffe097          	auipc	ra,0xffffe
    80002cea:	8a4080e7          	jalr	-1884(ra) # 8000058a <printf>
      printf("declared length: %d\n", declared_length);
    80002cee:	408c                	lw	a1,0(s1)
    80002cf0:	00006517          	auipc	a0,0x6
    80002cf4:	80050513          	addi	a0,a0,-2048 # 800084f0 <states.0+0x190>
    80002cf8:	ffffe097          	auipc	ra,0xffffe
    80002cfc:	892080e7          	jalr	-1902(ra) # 8000058a <printf>
    80002d00:	bf35                	j	80002c3c <syscall+0x52>
      printf("process %s with id %d called %s at time %d\n", p->name, p->pid, name_from_num[num], ticks);
    80002d02:	0a0e                	slli	s4,s4,0x3
    80002d04:	00006797          	auipc	a5,0x6
    80002d08:	d8478793          	addi	a5,a5,-636 # 80008a88 <name_from_num>
    80002d0c:	97d2                	add	a5,a5,s4
    80002d0e:	00006717          	auipc	a4,0x6
    80002d12:	ea272703          	lw	a4,-350(a4) # 80008bb0 <ticks>
    80002d16:	6394                	ld	a3,0(a5)
    80002d18:	0309a603          	lw	a2,48(s3)
    80002d1c:	15898593          	addi	a1,s3,344
    80002d20:	00005517          	auipc	a0,0x5
    80002d24:	7e850513          	addi	a0,a0,2024 # 80008508 <states.0+0x1a8>
    80002d28:	ffffe097          	auipc	ra,0xffffe
    80002d2c:	862080e7          	jalr	-1950(ra) # 8000058a <printf>
    80002d30:	a881                	j	80002d80 <syscall+0x196>
      for (int i = 0; i < declared_length; i++) {
    80002d32:	2905                	addiw	s2,s2,1
    80002d34:	0491                	addi	s1,s1,4
    80002d36:	000aa783          	lw	a5,0(s5)
    80002d3a:	04f95363          	bge	s2,a5,80002d80 <syscall+0x196>
        if (num == whitelisted[i]) {
    80002d3e:	409c                	lw	a5,0(s1)
    80002d40:	ff4799e3          	bne	a5,s4,80002d32 <syscall+0x148>
          printf("process %s with id %d called %s at time %d\n", p->name, p->pid, name_from_num[num], ticks);
    80002d44:	000ba703          	lw	a4,0(s7)
    80002d48:	000b3683          	ld	a3,0(s6)
    80002d4c:	0309a603          	lw	a2,48(s3)
    80002d50:	85e6                	mv	a1,s9
    80002d52:	8562                	mv	a0,s8
    80002d54:	ffffe097          	auipc	ra,0xffffe
    80002d58:	836080e7          	jalr	-1994(ra) # 8000058a <printf>
    80002d5c:	bfd9                	j	80002d32 <syscall+0x148>
        }
      }
    }

  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d5e:	86d2                	mv	a3,s4
    80002d60:	15898613          	addi	a2,s3,344
    80002d64:	0309a583          	lw	a1,48(s3)
    80002d68:	00005517          	auipc	a0,0x5
    80002d6c:	7d050513          	addi	a0,a0,2000 # 80008538 <states.0+0x1d8>
    80002d70:	ffffe097          	auipc	ra,0xffffe
    80002d74:	81a080e7          	jalr	-2022(ra) # 8000058a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d78:	0589b783          	ld	a5,88(s3)
    80002d7c:	577d                	li	a4,-1
    80002d7e:	fbb8                	sd	a4,112(a5)
  }
}
    80002d80:	60e6                	ld	ra,88(sp)
    80002d82:	6446                	ld	s0,80(sp)
    80002d84:	64a6                	ld	s1,72(sp)
    80002d86:	6906                	ld	s2,64(sp)
    80002d88:	79e2                	ld	s3,56(sp)
    80002d8a:	7a42                	ld	s4,48(sp)
    80002d8c:	7aa2                	ld	s5,40(sp)
    80002d8e:	7b02                	ld	s6,32(sp)
    80002d90:	6be2                	ld	s7,24(sp)
    80002d92:	6c42                	ld	s8,16(sp)
    80002d94:	6ca2                	ld	s9,8(sp)
    80002d96:	6125                	addi	sp,sp,96
    80002d98:	8082                	ret

0000000080002d9a <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002d9a:	1101                	addi	sp,sp,-32
    80002d9c:	ec06                	sd	ra,24(sp)
    80002d9e:	e822                	sd	s0,16(sp)
    80002da0:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002da2:	fec40593          	addi	a1,s0,-20
    80002da6:	4501                	li	a0,0
    80002da8:	00000097          	auipc	ra,0x0
    80002dac:	dca080e7          	jalr	-566(ra) # 80002b72 <argint>
  exit(n);
    80002db0:	fec42503          	lw	a0,-20(s0)
    80002db4:	fffff097          	auipc	ra,0xfffff
    80002db8:	484080e7          	jalr	1156(ra) # 80002238 <exit>
  return 0;  // not reached
}
    80002dbc:	4501                	li	a0,0
    80002dbe:	60e2                	ld	ra,24(sp)
    80002dc0:	6442                	ld	s0,16(sp)
    80002dc2:	6105                	addi	sp,sp,32
    80002dc4:	8082                	ret

0000000080002dc6 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002dc6:	1141                	addi	sp,sp,-16
    80002dc8:	e406                	sd	ra,8(sp)
    80002dca:	e022                	sd	s0,0(sp)
    80002dcc:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002dce:	fffff097          	auipc	ra,0xfffff
    80002dd2:	bde080e7          	jalr	-1058(ra) # 800019ac <myproc>
}
    80002dd6:	5908                	lw	a0,48(a0)
    80002dd8:	60a2                	ld	ra,8(sp)
    80002dda:	6402                	ld	s0,0(sp)
    80002ddc:	0141                	addi	sp,sp,16
    80002dde:	8082                	ret

0000000080002de0 <sys_fork>:

uint64
sys_fork(void)
{
    80002de0:	1141                	addi	sp,sp,-16
    80002de2:	e406                	sd	ra,8(sp)
    80002de4:	e022                	sd	s0,0(sp)
    80002de6:	0800                	addi	s0,sp,16
  return fork();
    80002de8:	fffff097          	auipc	ra,0xfffff
    80002dec:	f7a080e7          	jalr	-134(ra) # 80001d62 <fork>
}
    80002df0:	60a2                	ld	ra,8(sp)
    80002df2:	6402                	ld	s0,0(sp)
    80002df4:	0141                	addi	sp,sp,16
    80002df6:	8082                	ret

0000000080002df8 <sys_wait>:

uint64
sys_wait(void)
{
    80002df8:	1101                	addi	sp,sp,-32
    80002dfa:	ec06                	sd	ra,24(sp)
    80002dfc:	e822                	sd	s0,16(sp)
    80002dfe:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002e00:	fe840593          	addi	a1,s0,-24
    80002e04:	4501                	li	a0,0
    80002e06:	00000097          	auipc	ra,0x0
    80002e0a:	d8c080e7          	jalr	-628(ra) # 80002b92 <argaddr>
  return wait(p);
    80002e0e:	fe843503          	ld	a0,-24(s0)
    80002e12:	fffff097          	auipc	ra,0xfffff
    80002e16:	5cc080e7          	jalr	1484(ra) # 800023de <wait>
}
    80002e1a:	60e2                	ld	ra,24(sp)
    80002e1c:	6442                	ld	s0,16(sp)
    80002e1e:	6105                	addi	sp,sp,32
    80002e20:	8082                	ret

0000000080002e22 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e22:	7179                	addi	sp,sp,-48
    80002e24:	f406                	sd	ra,40(sp)
    80002e26:	f022                	sd	s0,32(sp)
    80002e28:	ec26                	sd	s1,24(sp)
    80002e2a:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002e2c:	fdc40593          	addi	a1,s0,-36
    80002e30:	4501                	li	a0,0
    80002e32:	00000097          	auipc	ra,0x0
    80002e36:	d40080e7          	jalr	-704(ra) # 80002b72 <argint>
  addr = myproc()->sz;
    80002e3a:	fffff097          	auipc	ra,0xfffff
    80002e3e:	b72080e7          	jalr	-1166(ra) # 800019ac <myproc>
    80002e42:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002e44:	fdc42503          	lw	a0,-36(s0)
    80002e48:	fffff097          	auipc	ra,0xfffff
    80002e4c:	ebe080e7          	jalr	-322(ra) # 80001d06 <growproc>
    80002e50:	00054863          	bltz	a0,80002e60 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002e54:	8526                	mv	a0,s1
    80002e56:	70a2                	ld	ra,40(sp)
    80002e58:	7402                	ld	s0,32(sp)
    80002e5a:	64e2                	ld	s1,24(sp)
    80002e5c:	6145                	addi	sp,sp,48
    80002e5e:	8082                	ret
    return -1;
    80002e60:	54fd                	li	s1,-1
    80002e62:	bfcd                	j	80002e54 <sys_sbrk+0x32>

0000000080002e64 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002e64:	7139                	addi	sp,sp,-64
    80002e66:	fc06                	sd	ra,56(sp)
    80002e68:	f822                	sd	s0,48(sp)
    80002e6a:	f426                	sd	s1,40(sp)
    80002e6c:	f04a                	sd	s2,32(sp)
    80002e6e:	ec4e                	sd	s3,24(sp)
    80002e70:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002e72:	fcc40593          	addi	a1,s0,-52
    80002e76:	4501                	li	a0,0
    80002e78:	00000097          	auipc	ra,0x0
    80002e7c:	cfa080e7          	jalr	-774(ra) # 80002b72 <argint>
  acquire(&tickslock);
    80002e80:	00014517          	auipc	a0,0x14
    80002e84:	fe050513          	addi	a0,a0,-32 # 80016e60 <tickslock>
    80002e88:	ffffe097          	auipc	ra,0xffffe
    80002e8c:	d4e080e7          	jalr	-690(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80002e90:	00006917          	auipc	s2,0x6
    80002e94:	d2092903          	lw	s2,-736(s2) # 80008bb0 <ticks>
  while(ticks - ticks0 < n){
    80002e98:	fcc42783          	lw	a5,-52(s0)
    80002e9c:	cf9d                	beqz	a5,80002eda <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002e9e:	00014997          	auipc	s3,0x14
    80002ea2:	fc298993          	addi	s3,s3,-62 # 80016e60 <tickslock>
    80002ea6:	00006497          	auipc	s1,0x6
    80002eaa:	d0a48493          	addi	s1,s1,-758 # 80008bb0 <ticks>
    if(killed(myproc())){
    80002eae:	fffff097          	auipc	ra,0xfffff
    80002eb2:	afe080e7          	jalr	-1282(ra) # 800019ac <myproc>
    80002eb6:	fffff097          	auipc	ra,0xfffff
    80002eba:	4f6080e7          	jalr	1270(ra) # 800023ac <killed>
    80002ebe:	ed15                	bnez	a0,80002efa <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002ec0:	85ce                	mv	a1,s3
    80002ec2:	8526                	mv	a0,s1
    80002ec4:	fffff097          	auipc	ra,0xfffff
    80002ec8:	240080e7          	jalr	576(ra) # 80002104 <sleep>
  while(ticks - ticks0 < n){
    80002ecc:	409c                	lw	a5,0(s1)
    80002ece:	412787bb          	subw	a5,a5,s2
    80002ed2:	fcc42703          	lw	a4,-52(s0)
    80002ed6:	fce7ece3          	bltu	a5,a4,80002eae <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002eda:	00014517          	auipc	a0,0x14
    80002ede:	f8650513          	addi	a0,a0,-122 # 80016e60 <tickslock>
    80002ee2:	ffffe097          	auipc	ra,0xffffe
    80002ee6:	da8080e7          	jalr	-600(ra) # 80000c8a <release>
  return 0;
    80002eea:	4501                	li	a0,0
}
    80002eec:	70e2                	ld	ra,56(sp)
    80002eee:	7442                	ld	s0,48(sp)
    80002ef0:	74a2                	ld	s1,40(sp)
    80002ef2:	7902                	ld	s2,32(sp)
    80002ef4:	69e2                	ld	s3,24(sp)
    80002ef6:	6121                	addi	sp,sp,64
    80002ef8:	8082                	ret
      release(&tickslock);
    80002efa:	00014517          	auipc	a0,0x14
    80002efe:	f6650513          	addi	a0,a0,-154 # 80016e60 <tickslock>
    80002f02:	ffffe097          	auipc	ra,0xffffe
    80002f06:	d88080e7          	jalr	-632(ra) # 80000c8a <release>
      return -1;
    80002f0a:	557d                	li	a0,-1
    80002f0c:	b7c5                	j	80002eec <sys_sleep+0x88>

0000000080002f0e <sys_kill>:

uint64
sys_kill(void)
{
    80002f0e:	1101                	addi	sp,sp,-32
    80002f10:	ec06                	sd	ra,24(sp)
    80002f12:	e822                	sd	s0,16(sp)
    80002f14:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002f16:	fec40593          	addi	a1,s0,-20
    80002f1a:	4501                	li	a0,0
    80002f1c:	00000097          	auipc	ra,0x0
    80002f20:	c56080e7          	jalr	-938(ra) # 80002b72 <argint>
  return kill(pid);
    80002f24:	fec42503          	lw	a0,-20(s0)
    80002f28:	fffff097          	auipc	ra,0xfffff
    80002f2c:	3e6080e7          	jalr	998(ra) # 8000230e <kill>
}
    80002f30:	60e2                	ld	ra,24(sp)
    80002f32:	6442                	ld	s0,16(sp)
    80002f34:	6105                	addi	sp,sp,32
    80002f36:	8082                	ret

0000000080002f38 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002f38:	1101                	addi	sp,sp,-32
    80002f3a:	ec06                	sd	ra,24(sp)
    80002f3c:	e822                	sd	s0,16(sp)
    80002f3e:	e426                	sd	s1,8(sp)
    80002f40:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002f42:	00014517          	auipc	a0,0x14
    80002f46:	f1e50513          	addi	a0,a0,-226 # 80016e60 <tickslock>
    80002f4a:	ffffe097          	auipc	ra,0xffffe
    80002f4e:	c8c080e7          	jalr	-884(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80002f52:	00006497          	auipc	s1,0x6
    80002f56:	c5e4a483          	lw	s1,-930(s1) # 80008bb0 <ticks>
  release(&tickslock);
    80002f5a:	00014517          	auipc	a0,0x14
    80002f5e:	f0650513          	addi	a0,a0,-250 # 80016e60 <tickslock>
    80002f62:	ffffe097          	auipc	ra,0xffffe
    80002f66:	d28080e7          	jalr	-728(ra) # 80000c8a <release>
  return xticks;
}
    80002f6a:	02049513          	slli	a0,s1,0x20
    80002f6e:	9101                	srli	a0,a0,0x20
    80002f70:	60e2                	ld	ra,24(sp)
    80002f72:	6442                	ld	s0,16(sp)
    80002f74:	64a2                	ld	s1,8(sp)
    80002f76:	6105                	addi	sp,sp,32
    80002f78:	8082                	ret

0000000080002f7a <sys_audit>:

uint64
sys_audit(void)
{
    80002f7a:	1101                	addi	sp,sp,-32
    80002f7c:	ec06                	sd	ra,24(sp)
    80002f7e:	e822                	sd	s0,16(sp)
    80002f80:	1000                	addi	s0,sp,32
  printf("in sys audit\n");
    80002f82:	00005517          	auipc	a0,0x5
    80002f86:	75650513          	addi	a0,a0,1878 # 800086d8 <syscalls+0xb8>
    80002f8a:	ffffd097          	auipc	ra,0xffffd
    80002f8e:	600080e7          	jalr	1536(ra) # 8000058a <printf>
  uint64 arr_addr;
  uint64 length;
  argaddr(0, &arr_addr);
    80002f92:	fe840593          	addi	a1,s0,-24
    80002f96:	4501                	li	a0,0
    80002f98:	00000097          	auipc	ra,0x0
    80002f9c:	bfa080e7          	jalr	-1030(ra) # 80002b92 <argaddr>
  argaddr(1, &length);
    80002fa0:	fe040593          	addi	a1,s0,-32
    80002fa4:	4505                	li	a0,1
    80002fa6:	00000097          	auipc	ra,0x0
    80002faa:	bec080e7          	jalr	-1044(ra) # 80002b92 <argaddr>
  printf("address of length: %p\n", (int*) length);
    80002fae:	fe043583          	ld	a1,-32(s0)
    80002fb2:	00005517          	auipc	a0,0x5
    80002fb6:	73650513          	addi	a0,a0,1846 # 800086e8 <syscalls+0xc8>
    80002fba:	ffffd097          	auipc	ra,0xffffd
    80002fbe:	5d0080e7          	jalr	1488(ra) # 8000058a <printf>
  return audit((int*) arr_addr, (int*) length);
    80002fc2:	fe043583          	ld	a1,-32(s0)
    80002fc6:	fe843503          	ld	a0,-24(s0)
    80002fca:	fffff097          	auipc	ra,0xfffff
    80002fce:	ed8080e7          	jalr	-296(ra) # 80001ea2 <audit>
}
    80002fd2:	60e2                	ld	ra,24(sp)
    80002fd4:	6442                	ld	s0,16(sp)
    80002fd6:	6105                	addi	sp,sp,32
    80002fd8:	8082                	ret

0000000080002fda <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002fda:	7179                	addi	sp,sp,-48
    80002fdc:	f406                	sd	ra,40(sp)
    80002fde:	f022                	sd	s0,32(sp)
    80002fe0:	ec26                	sd	s1,24(sp)
    80002fe2:	e84a                	sd	s2,16(sp)
    80002fe4:	e44e                	sd	s3,8(sp)
    80002fe6:	e052                	sd	s4,0(sp)
    80002fe8:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002fea:	00005597          	auipc	a1,0x5
    80002fee:	71658593          	addi	a1,a1,1814 # 80008700 <syscalls+0xe0>
    80002ff2:	0001c517          	auipc	a0,0x1c
    80002ff6:	ede50513          	addi	a0,a0,-290 # 8001eed0 <bcache>
    80002ffa:	ffffe097          	auipc	ra,0xffffe
    80002ffe:	b4c080e7          	jalr	-1204(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003002:	00024797          	auipc	a5,0x24
    80003006:	ece78793          	addi	a5,a5,-306 # 80026ed0 <bcache+0x8000>
    8000300a:	00024717          	auipc	a4,0x24
    8000300e:	12e70713          	addi	a4,a4,302 # 80027138 <bcache+0x8268>
    80003012:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003016:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000301a:	0001c497          	auipc	s1,0x1c
    8000301e:	ece48493          	addi	s1,s1,-306 # 8001eee8 <bcache+0x18>
    b->next = bcache.head.next;
    80003022:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003024:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003026:	00005a17          	auipc	s4,0x5
    8000302a:	6e2a0a13          	addi	s4,s4,1762 # 80008708 <syscalls+0xe8>
    b->next = bcache.head.next;
    8000302e:	2b893783          	ld	a5,696(s2)
    80003032:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003034:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003038:	85d2                	mv	a1,s4
    8000303a:	01048513          	addi	a0,s1,16
    8000303e:	00001097          	auipc	ra,0x1
    80003042:	4c8080e7          	jalr	1224(ra) # 80004506 <initsleeplock>
    bcache.head.next->prev = b;
    80003046:	2b893783          	ld	a5,696(s2)
    8000304a:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000304c:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003050:	45848493          	addi	s1,s1,1112
    80003054:	fd349de3          	bne	s1,s3,8000302e <binit+0x54>
  }
}
    80003058:	70a2                	ld	ra,40(sp)
    8000305a:	7402                	ld	s0,32(sp)
    8000305c:	64e2                	ld	s1,24(sp)
    8000305e:	6942                	ld	s2,16(sp)
    80003060:	69a2                	ld	s3,8(sp)
    80003062:	6a02                	ld	s4,0(sp)
    80003064:	6145                	addi	sp,sp,48
    80003066:	8082                	ret

0000000080003068 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003068:	7179                	addi	sp,sp,-48
    8000306a:	f406                	sd	ra,40(sp)
    8000306c:	f022                	sd	s0,32(sp)
    8000306e:	ec26                	sd	s1,24(sp)
    80003070:	e84a                	sd	s2,16(sp)
    80003072:	e44e                	sd	s3,8(sp)
    80003074:	1800                	addi	s0,sp,48
    80003076:	892a                	mv	s2,a0
    80003078:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000307a:	0001c517          	auipc	a0,0x1c
    8000307e:	e5650513          	addi	a0,a0,-426 # 8001eed0 <bcache>
    80003082:	ffffe097          	auipc	ra,0xffffe
    80003086:	b54080e7          	jalr	-1196(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    8000308a:	00024497          	auipc	s1,0x24
    8000308e:	0fe4b483          	ld	s1,254(s1) # 80027188 <bcache+0x82b8>
    80003092:	00024797          	auipc	a5,0x24
    80003096:	0a678793          	addi	a5,a5,166 # 80027138 <bcache+0x8268>
    8000309a:	02f48f63          	beq	s1,a5,800030d8 <bread+0x70>
    8000309e:	873e                	mv	a4,a5
    800030a0:	a021                	j	800030a8 <bread+0x40>
    800030a2:	68a4                	ld	s1,80(s1)
    800030a4:	02e48a63          	beq	s1,a4,800030d8 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800030a8:	449c                	lw	a5,8(s1)
    800030aa:	ff279ce3          	bne	a5,s2,800030a2 <bread+0x3a>
    800030ae:	44dc                	lw	a5,12(s1)
    800030b0:	ff3799e3          	bne	a5,s3,800030a2 <bread+0x3a>
      b->refcnt++;
    800030b4:	40bc                	lw	a5,64(s1)
    800030b6:	2785                	addiw	a5,a5,1
    800030b8:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800030ba:	0001c517          	auipc	a0,0x1c
    800030be:	e1650513          	addi	a0,a0,-490 # 8001eed0 <bcache>
    800030c2:	ffffe097          	auipc	ra,0xffffe
    800030c6:	bc8080e7          	jalr	-1080(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    800030ca:	01048513          	addi	a0,s1,16
    800030ce:	00001097          	auipc	ra,0x1
    800030d2:	472080e7          	jalr	1138(ra) # 80004540 <acquiresleep>
      return b;
    800030d6:	a8b9                	j	80003134 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030d8:	00024497          	auipc	s1,0x24
    800030dc:	0a84b483          	ld	s1,168(s1) # 80027180 <bcache+0x82b0>
    800030e0:	00024797          	auipc	a5,0x24
    800030e4:	05878793          	addi	a5,a5,88 # 80027138 <bcache+0x8268>
    800030e8:	00f48863          	beq	s1,a5,800030f8 <bread+0x90>
    800030ec:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800030ee:	40bc                	lw	a5,64(s1)
    800030f0:	cf81                	beqz	a5,80003108 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030f2:	64a4                	ld	s1,72(s1)
    800030f4:	fee49de3          	bne	s1,a4,800030ee <bread+0x86>
  panic("bget: no buffers");
    800030f8:	00005517          	auipc	a0,0x5
    800030fc:	61850513          	addi	a0,a0,1560 # 80008710 <syscalls+0xf0>
    80003100:	ffffd097          	auipc	ra,0xffffd
    80003104:	440080e7          	jalr	1088(ra) # 80000540 <panic>
      b->dev = dev;
    80003108:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000310c:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003110:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003114:	4785                	li	a5,1
    80003116:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003118:	0001c517          	auipc	a0,0x1c
    8000311c:	db850513          	addi	a0,a0,-584 # 8001eed0 <bcache>
    80003120:	ffffe097          	auipc	ra,0xffffe
    80003124:	b6a080e7          	jalr	-1174(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003128:	01048513          	addi	a0,s1,16
    8000312c:	00001097          	auipc	ra,0x1
    80003130:	414080e7          	jalr	1044(ra) # 80004540 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003134:	409c                	lw	a5,0(s1)
    80003136:	cb89                	beqz	a5,80003148 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003138:	8526                	mv	a0,s1
    8000313a:	70a2                	ld	ra,40(sp)
    8000313c:	7402                	ld	s0,32(sp)
    8000313e:	64e2                	ld	s1,24(sp)
    80003140:	6942                	ld	s2,16(sp)
    80003142:	69a2                	ld	s3,8(sp)
    80003144:	6145                	addi	sp,sp,48
    80003146:	8082                	ret
    virtio_disk_rw(b, 0);
    80003148:	4581                	li	a1,0
    8000314a:	8526                	mv	a0,s1
    8000314c:	00003097          	auipc	ra,0x3
    80003150:	fd6080e7          	jalr	-42(ra) # 80006122 <virtio_disk_rw>
    b->valid = 1;
    80003154:	4785                	li	a5,1
    80003156:	c09c                	sw	a5,0(s1)
  return b;
    80003158:	b7c5                	j	80003138 <bread+0xd0>

000000008000315a <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000315a:	1101                	addi	sp,sp,-32
    8000315c:	ec06                	sd	ra,24(sp)
    8000315e:	e822                	sd	s0,16(sp)
    80003160:	e426                	sd	s1,8(sp)
    80003162:	1000                	addi	s0,sp,32
    80003164:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003166:	0541                	addi	a0,a0,16
    80003168:	00001097          	auipc	ra,0x1
    8000316c:	472080e7          	jalr	1138(ra) # 800045da <holdingsleep>
    80003170:	cd01                	beqz	a0,80003188 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003172:	4585                	li	a1,1
    80003174:	8526                	mv	a0,s1
    80003176:	00003097          	auipc	ra,0x3
    8000317a:	fac080e7          	jalr	-84(ra) # 80006122 <virtio_disk_rw>
}
    8000317e:	60e2                	ld	ra,24(sp)
    80003180:	6442                	ld	s0,16(sp)
    80003182:	64a2                	ld	s1,8(sp)
    80003184:	6105                	addi	sp,sp,32
    80003186:	8082                	ret
    panic("bwrite");
    80003188:	00005517          	auipc	a0,0x5
    8000318c:	5a050513          	addi	a0,a0,1440 # 80008728 <syscalls+0x108>
    80003190:	ffffd097          	auipc	ra,0xffffd
    80003194:	3b0080e7          	jalr	944(ra) # 80000540 <panic>

0000000080003198 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003198:	1101                	addi	sp,sp,-32
    8000319a:	ec06                	sd	ra,24(sp)
    8000319c:	e822                	sd	s0,16(sp)
    8000319e:	e426                	sd	s1,8(sp)
    800031a0:	e04a                	sd	s2,0(sp)
    800031a2:	1000                	addi	s0,sp,32
    800031a4:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031a6:	01050913          	addi	s2,a0,16
    800031aa:	854a                	mv	a0,s2
    800031ac:	00001097          	auipc	ra,0x1
    800031b0:	42e080e7          	jalr	1070(ra) # 800045da <holdingsleep>
    800031b4:	c92d                	beqz	a0,80003226 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800031b6:	854a                	mv	a0,s2
    800031b8:	00001097          	auipc	ra,0x1
    800031bc:	3de080e7          	jalr	990(ra) # 80004596 <releasesleep>

  acquire(&bcache.lock);
    800031c0:	0001c517          	auipc	a0,0x1c
    800031c4:	d1050513          	addi	a0,a0,-752 # 8001eed0 <bcache>
    800031c8:	ffffe097          	auipc	ra,0xffffe
    800031cc:	a0e080e7          	jalr	-1522(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800031d0:	40bc                	lw	a5,64(s1)
    800031d2:	37fd                	addiw	a5,a5,-1
    800031d4:	0007871b          	sext.w	a4,a5
    800031d8:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800031da:	eb05                	bnez	a4,8000320a <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800031dc:	68bc                	ld	a5,80(s1)
    800031de:	64b8                	ld	a4,72(s1)
    800031e0:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800031e2:	64bc                	ld	a5,72(s1)
    800031e4:	68b8                	ld	a4,80(s1)
    800031e6:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800031e8:	00024797          	auipc	a5,0x24
    800031ec:	ce878793          	addi	a5,a5,-792 # 80026ed0 <bcache+0x8000>
    800031f0:	2b87b703          	ld	a4,696(a5)
    800031f4:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800031f6:	00024717          	auipc	a4,0x24
    800031fa:	f4270713          	addi	a4,a4,-190 # 80027138 <bcache+0x8268>
    800031fe:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003200:	2b87b703          	ld	a4,696(a5)
    80003204:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003206:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000320a:	0001c517          	auipc	a0,0x1c
    8000320e:	cc650513          	addi	a0,a0,-826 # 8001eed0 <bcache>
    80003212:	ffffe097          	auipc	ra,0xffffe
    80003216:	a78080e7          	jalr	-1416(ra) # 80000c8a <release>
}
    8000321a:	60e2                	ld	ra,24(sp)
    8000321c:	6442                	ld	s0,16(sp)
    8000321e:	64a2                	ld	s1,8(sp)
    80003220:	6902                	ld	s2,0(sp)
    80003222:	6105                	addi	sp,sp,32
    80003224:	8082                	ret
    panic("brelse");
    80003226:	00005517          	auipc	a0,0x5
    8000322a:	50a50513          	addi	a0,a0,1290 # 80008730 <syscalls+0x110>
    8000322e:	ffffd097          	auipc	ra,0xffffd
    80003232:	312080e7          	jalr	786(ra) # 80000540 <panic>

0000000080003236 <bpin>:

void
bpin(struct buf *b) {
    80003236:	1101                	addi	sp,sp,-32
    80003238:	ec06                	sd	ra,24(sp)
    8000323a:	e822                	sd	s0,16(sp)
    8000323c:	e426                	sd	s1,8(sp)
    8000323e:	1000                	addi	s0,sp,32
    80003240:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003242:	0001c517          	auipc	a0,0x1c
    80003246:	c8e50513          	addi	a0,a0,-882 # 8001eed0 <bcache>
    8000324a:	ffffe097          	auipc	ra,0xffffe
    8000324e:	98c080e7          	jalr	-1652(ra) # 80000bd6 <acquire>
  b->refcnt++;
    80003252:	40bc                	lw	a5,64(s1)
    80003254:	2785                	addiw	a5,a5,1
    80003256:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003258:	0001c517          	auipc	a0,0x1c
    8000325c:	c7850513          	addi	a0,a0,-904 # 8001eed0 <bcache>
    80003260:	ffffe097          	auipc	ra,0xffffe
    80003264:	a2a080e7          	jalr	-1494(ra) # 80000c8a <release>
}
    80003268:	60e2                	ld	ra,24(sp)
    8000326a:	6442                	ld	s0,16(sp)
    8000326c:	64a2                	ld	s1,8(sp)
    8000326e:	6105                	addi	sp,sp,32
    80003270:	8082                	ret

0000000080003272 <bunpin>:

void
bunpin(struct buf *b) {
    80003272:	1101                	addi	sp,sp,-32
    80003274:	ec06                	sd	ra,24(sp)
    80003276:	e822                	sd	s0,16(sp)
    80003278:	e426                	sd	s1,8(sp)
    8000327a:	1000                	addi	s0,sp,32
    8000327c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000327e:	0001c517          	auipc	a0,0x1c
    80003282:	c5250513          	addi	a0,a0,-942 # 8001eed0 <bcache>
    80003286:	ffffe097          	auipc	ra,0xffffe
    8000328a:	950080e7          	jalr	-1712(ra) # 80000bd6 <acquire>
  b->refcnt--;
    8000328e:	40bc                	lw	a5,64(s1)
    80003290:	37fd                	addiw	a5,a5,-1
    80003292:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003294:	0001c517          	auipc	a0,0x1c
    80003298:	c3c50513          	addi	a0,a0,-964 # 8001eed0 <bcache>
    8000329c:	ffffe097          	auipc	ra,0xffffe
    800032a0:	9ee080e7          	jalr	-1554(ra) # 80000c8a <release>
}
    800032a4:	60e2                	ld	ra,24(sp)
    800032a6:	6442                	ld	s0,16(sp)
    800032a8:	64a2                	ld	s1,8(sp)
    800032aa:	6105                	addi	sp,sp,32
    800032ac:	8082                	ret

00000000800032ae <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800032ae:	1101                	addi	sp,sp,-32
    800032b0:	ec06                	sd	ra,24(sp)
    800032b2:	e822                	sd	s0,16(sp)
    800032b4:	e426                	sd	s1,8(sp)
    800032b6:	e04a                	sd	s2,0(sp)
    800032b8:	1000                	addi	s0,sp,32
    800032ba:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800032bc:	00d5d59b          	srliw	a1,a1,0xd
    800032c0:	00024797          	auipc	a5,0x24
    800032c4:	2ec7a783          	lw	a5,748(a5) # 800275ac <sb+0x1c>
    800032c8:	9dbd                	addw	a1,a1,a5
    800032ca:	00000097          	auipc	ra,0x0
    800032ce:	d9e080e7          	jalr	-610(ra) # 80003068 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800032d2:	0074f713          	andi	a4,s1,7
    800032d6:	4785                	li	a5,1
    800032d8:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800032dc:	14ce                	slli	s1,s1,0x33
    800032de:	90d9                	srli	s1,s1,0x36
    800032e0:	00950733          	add	a4,a0,s1
    800032e4:	05874703          	lbu	a4,88(a4)
    800032e8:	00e7f6b3          	and	a3,a5,a4
    800032ec:	c69d                	beqz	a3,8000331a <bfree+0x6c>
    800032ee:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800032f0:	94aa                	add	s1,s1,a0
    800032f2:	fff7c793          	not	a5,a5
    800032f6:	8f7d                	and	a4,a4,a5
    800032f8:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800032fc:	00001097          	auipc	ra,0x1
    80003300:	126080e7          	jalr	294(ra) # 80004422 <log_write>
  brelse(bp);
    80003304:	854a                	mv	a0,s2
    80003306:	00000097          	auipc	ra,0x0
    8000330a:	e92080e7          	jalr	-366(ra) # 80003198 <brelse>
}
    8000330e:	60e2                	ld	ra,24(sp)
    80003310:	6442                	ld	s0,16(sp)
    80003312:	64a2                	ld	s1,8(sp)
    80003314:	6902                	ld	s2,0(sp)
    80003316:	6105                	addi	sp,sp,32
    80003318:	8082                	ret
    panic("freeing free block");
    8000331a:	00005517          	auipc	a0,0x5
    8000331e:	41e50513          	addi	a0,a0,1054 # 80008738 <syscalls+0x118>
    80003322:	ffffd097          	auipc	ra,0xffffd
    80003326:	21e080e7          	jalr	542(ra) # 80000540 <panic>

000000008000332a <balloc>:
{
    8000332a:	711d                	addi	sp,sp,-96
    8000332c:	ec86                	sd	ra,88(sp)
    8000332e:	e8a2                	sd	s0,80(sp)
    80003330:	e4a6                	sd	s1,72(sp)
    80003332:	e0ca                	sd	s2,64(sp)
    80003334:	fc4e                	sd	s3,56(sp)
    80003336:	f852                	sd	s4,48(sp)
    80003338:	f456                	sd	s5,40(sp)
    8000333a:	f05a                	sd	s6,32(sp)
    8000333c:	ec5e                	sd	s7,24(sp)
    8000333e:	e862                	sd	s8,16(sp)
    80003340:	e466                	sd	s9,8(sp)
    80003342:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003344:	00024797          	auipc	a5,0x24
    80003348:	2507a783          	lw	a5,592(a5) # 80027594 <sb+0x4>
    8000334c:	cff5                	beqz	a5,80003448 <balloc+0x11e>
    8000334e:	8baa                	mv	s7,a0
    80003350:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003352:	00024b17          	auipc	s6,0x24
    80003356:	23eb0b13          	addi	s6,s6,574 # 80027590 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000335a:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000335c:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000335e:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003360:	6c89                	lui	s9,0x2
    80003362:	a061                	j	800033ea <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003364:	97ca                	add	a5,a5,s2
    80003366:	8e55                	or	a2,a2,a3
    80003368:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    8000336c:	854a                	mv	a0,s2
    8000336e:	00001097          	auipc	ra,0x1
    80003372:	0b4080e7          	jalr	180(ra) # 80004422 <log_write>
        brelse(bp);
    80003376:	854a                	mv	a0,s2
    80003378:	00000097          	auipc	ra,0x0
    8000337c:	e20080e7          	jalr	-480(ra) # 80003198 <brelse>
  bp = bread(dev, bno);
    80003380:	85a6                	mv	a1,s1
    80003382:	855e                	mv	a0,s7
    80003384:	00000097          	auipc	ra,0x0
    80003388:	ce4080e7          	jalr	-796(ra) # 80003068 <bread>
    8000338c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000338e:	40000613          	li	a2,1024
    80003392:	4581                	li	a1,0
    80003394:	05850513          	addi	a0,a0,88
    80003398:	ffffe097          	auipc	ra,0xffffe
    8000339c:	93a080e7          	jalr	-1734(ra) # 80000cd2 <memset>
  log_write(bp);
    800033a0:	854a                	mv	a0,s2
    800033a2:	00001097          	auipc	ra,0x1
    800033a6:	080080e7          	jalr	128(ra) # 80004422 <log_write>
  brelse(bp);
    800033aa:	854a                	mv	a0,s2
    800033ac:	00000097          	auipc	ra,0x0
    800033b0:	dec080e7          	jalr	-532(ra) # 80003198 <brelse>
}
    800033b4:	8526                	mv	a0,s1
    800033b6:	60e6                	ld	ra,88(sp)
    800033b8:	6446                	ld	s0,80(sp)
    800033ba:	64a6                	ld	s1,72(sp)
    800033bc:	6906                	ld	s2,64(sp)
    800033be:	79e2                	ld	s3,56(sp)
    800033c0:	7a42                	ld	s4,48(sp)
    800033c2:	7aa2                	ld	s5,40(sp)
    800033c4:	7b02                	ld	s6,32(sp)
    800033c6:	6be2                	ld	s7,24(sp)
    800033c8:	6c42                	ld	s8,16(sp)
    800033ca:	6ca2                	ld	s9,8(sp)
    800033cc:	6125                	addi	sp,sp,96
    800033ce:	8082                	ret
    brelse(bp);
    800033d0:	854a                	mv	a0,s2
    800033d2:	00000097          	auipc	ra,0x0
    800033d6:	dc6080e7          	jalr	-570(ra) # 80003198 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800033da:	015c87bb          	addw	a5,s9,s5
    800033de:	00078a9b          	sext.w	s5,a5
    800033e2:	004b2703          	lw	a4,4(s6)
    800033e6:	06eaf163          	bgeu	s5,a4,80003448 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    800033ea:	41fad79b          	sraiw	a5,s5,0x1f
    800033ee:	0137d79b          	srliw	a5,a5,0x13
    800033f2:	015787bb          	addw	a5,a5,s5
    800033f6:	40d7d79b          	sraiw	a5,a5,0xd
    800033fa:	01cb2583          	lw	a1,28(s6)
    800033fe:	9dbd                	addw	a1,a1,a5
    80003400:	855e                	mv	a0,s7
    80003402:	00000097          	auipc	ra,0x0
    80003406:	c66080e7          	jalr	-922(ra) # 80003068 <bread>
    8000340a:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000340c:	004b2503          	lw	a0,4(s6)
    80003410:	000a849b          	sext.w	s1,s5
    80003414:	8762                	mv	a4,s8
    80003416:	faa4fde3          	bgeu	s1,a0,800033d0 <balloc+0xa6>
      m = 1 << (bi % 8);
    8000341a:	00777693          	andi	a3,a4,7
    8000341e:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003422:	41f7579b          	sraiw	a5,a4,0x1f
    80003426:	01d7d79b          	srliw	a5,a5,0x1d
    8000342a:	9fb9                	addw	a5,a5,a4
    8000342c:	4037d79b          	sraiw	a5,a5,0x3
    80003430:	00f90633          	add	a2,s2,a5
    80003434:	05864603          	lbu	a2,88(a2)
    80003438:	00c6f5b3          	and	a1,a3,a2
    8000343c:	d585                	beqz	a1,80003364 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000343e:	2705                	addiw	a4,a4,1
    80003440:	2485                	addiw	s1,s1,1
    80003442:	fd471ae3          	bne	a4,s4,80003416 <balloc+0xec>
    80003446:	b769                	j	800033d0 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    80003448:	00005517          	auipc	a0,0x5
    8000344c:	30850513          	addi	a0,a0,776 # 80008750 <syscalls+0x130>
    80003450:	ffffd097          	auipc	ra,0xffffd
    80003454:	13a080e7          	jalr	314(ra) # 8000058a <printf>
  return 0;
    80003458:	4481                	li	s1,0
    8000345a:	bfa9                	j	800033b4 <balloc+0x8a>

000000008000345c <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    8000345c:	7179                	addi	sp,sp,-48
    8000345e:	f406                	sd	ra,40(sp)
    80003460:	f022                	sd	s0,32(sp)
    80003462:	ec26                	sd	s1,24(sp)
    80003464:	e84a                	sd	s2,16(sp)
    80003466:	e44e                	sd	s3,8(sp)
    80003468:	e052                	sd	s4,0(sp)
    8000346a:	1800                	addi	s0,sp,48
    8000346c:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000346e:	47ad                	li	a5,11
    80003470:	02b7e863          	bltu	a5,a1,800034a0 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    80003474:	02059793          	slli	a5,a1,0x20
    80003478:	01e7d593          	srli	a1,a5,0x1e
    8000347c:	00b504b3          	add	s1,a0,a1
    80003480:	0504a903          	lw	s2,80(s1)
    80003484:	06091e63          	bnez	s2,80003500 <bmap+0xa4>
      addr = balloc(ip->dev);
    80003488:	4108                	lw	a0,0(a0)
    8000348a:	00000097          	auipc	ra,0x0
    8000348e:	ea0080e7          	jalr	-352(ra) # 8000332a <balloc>
    80003492:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003496:	06090563          	beqz	s2,80003500 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    8000349a:	0524a823          	sw	s2,80(s1)
    8000349e:	a08d                	j	80003500 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    800034a0:	ff45849b          	addiw	s1,a1,-12
    800034a4:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800034a8:	0ff00793          	li	a5,255
    800034ac:	08e7e563          	bltu	a5,a4,80003536 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800034b0:	08052903          	lw	s2,128(a0)
    800034b4:	00091d63          	bnez	s2,800034ce <bmap+0x72>
      addr = balloc(ip->dev);
    800034b8:	4108                	lw	a0,0(a0)
    800034ba:	00000097          	auipc	ra,0x0
    800034be:	e70080e7          	jalr	-400(ra) # 8000332a <balloc>
    800034c2:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800034c6:	02090d63          	beqz	s2,80003500 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800034ca:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800034ce:	85ca                	mv	a1,s2
    800034d0:	0009a503          	lw	a0,0(s3)
    800034d4:	00000097          	auipc	ra,0x0
    800034d8:	b94080e7          	jalr	-1132(ra) # 80003068 <bread>
    800034dc:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800034de:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800034e2:	02049713          	slli	a4,s1,0x20
    800034e6:	01e75593          	srli	a1,a4,0x1e
    800034ea:	00b784b3          	add	s1,a5,a1
    800034ee:	0004a903          	lw	s2,0(s1)
    800034f2:	02090063          	beqz	s2,80003512 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800034f6:	8552                	mv	a0,s4
    800034f8:	00000097          	auipc	ra,0x0
    800034fc:	ca0080e7          	jalr	-864(ra) # 80003198 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003500:	854a                	mv	a0,s2
    80003502:	70a2                	ld	ra,40(sp)
    80003504:	7402                	ld	s0,32(sp)
    80003506:	64e2                	ld	s1,24(sp)
    80003508:	6942                	ld	s2,16(sp)
    8000350a:	69a2                	ld	s3,8(sp)
    8000350c:	6a02                	ld	s4,0(sp)
    8000350e:	6145                	addi	sp,sp,48
    80003510:	8082                	ret
      addr = balloc(ip->dev);
    80003512:	0009a503          	lw	a0,0(s3)
    80003516:	00000097          	auipc	ra,0x0
    8000351a:	e14080e7          	jalr	-492(ra) # 8000332a <balloc>
    8000351e:	0005091b          	sext.w	s2,a0
      if(addr){
    80003522:	fc090ae3          	beqz	s2,800034f6 <bmap+0x9a>
        a[bn] = addr;
    80003526:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    8000352a:	8552                	mv	a0,s4
    8000352c:	00001097          	auipc	ra,0x1
    80003530:	ef6080e7          	jalr	-266(ra) # 80004422 <log_write>
    80003534:	b7c9                	j	800034f6 <bmap+0x9a>
  panic("bmap: out of range");
    80003536:	00005517          	auipc	a0,0x5
    8000353a:	23250513          	addi	a0,a0,562 # 80008768 <syscalls+0x148>
    8000353e:	ffffd097          	auipc	ra,0xffffd
    80003542:	002080e7          	jalr	2(ra) # 80000540 <panic>

0000000080003546 <iget>:
{
    80003546:	7179                	addi	sp,sp,-48
    80003548:	f406                	sd	ra,40(sp)
    8000354a:	f022                	sd	s0,32(sp)
    8000354c:	ec26                	sd	s1,24(sp)
    8000354e:	e84a                	sd	s2,16(sp)
    80003550:	e44e                	sd	s3,8(sp)
    80003552:	e052                	sd	s4,0(sp)
    80003554:	1800                	addi	s0,sp,48
    80003556:	89aa                	mv	s3,a0
    80003558:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000355a:	00024517          	auipc	a0,0x24
    8000355e:	05650513          	addi	a0,a0,86 # 800275b0 <itable>
    80003562:	ffffd097          	auipc	ra,0xffffd
    80003566:	674080e7          	jalr	1652(ra) # 80000bd6 <acquire>
  empty = 0;
    8000356a:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000356c:	00024497          	auipc	s1,0x24
    80003570:	05c48493          	addi	s1,s1,92 # 800275c8 <itable+0x18>
    80003574:	00026697          	auipc	a3,0x26
    80003578:	ae468693          	addi	a3,a3,-1308 # 80029058 <log>
    8000357c:	a039                	j	8000358a <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000357e:	02090b63          	beqz	s2,800035b4 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003582:	08848493          	addi	s1,s1,136
    80003586:	02d48a63          	beq	s1,a3,800035ba <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000358a:	449c                	lw	a5,8(s1)
    8000358c:	fef059e3          	blez	a5,8000357e <iget+0x38>
    80003590:	4098                	lw	a4,0(s1)
    80003592:	ff3716e3          	bne	a4,s3,8000357e <iget+0x38>
    80003596:	40d8                	lw	a4,4(s1)
    80003598:	ff4713e3          	bne	a4,s4,8000357e <iget+0x38>
      ip->ref++;
    8000359c:	2785                	addiw	a5,a5,1
    8000359e:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800035a0:	00024517          	auipc	a0,0x24
    800035a4:	01050513          	addi	a0,a0,16 # 800275b0 <itable>
    800035a8:	ffffd097          	auipc	ra,0xffffd
    800035ac:	6e2080e7          	jalr	1762(ra) # 80000c8a <release>
      return ip;
    800035b0:	8926                	mv	s2,s1
    800035b2:	a03d                	j	800035e0 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035b4:	f7f9                	bnez	a5,80003582 <iget+0x3c>
    800035b6:	8926                	mv	s2,s1
    800035b8:	b7e9                	j	80003582 <iget+0x3c>
  if(empty == 0)
    800035ba:	02090c63          	beqz	s2,800035f2 <iget+0xac>
  ip->dev = dev;
    800035be:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800035c2:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800035c6:	4785                	li	a5,1
    800035c8:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800035cc:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800035d0:	00024517          	auipc	a0,0x24
    800035d4:	fe050513          	addi	a0,a0,-32 # 800275b0 <itable>
    800035d8:	ffffd097          	auipc	ra,0xffffd
    800035dc:	6b2080e7          	jalr	1714(ra) # 80000c8a <release>
}
    800035e0:	854a                	mv	a0,s2
    800035e2:	70a2                	ld	ra,40(sp)
    800035e4:	7402                	ld	s0,32(sp)
    800035e6:	64e2                	ld	s1,24(sp)
    800035e8:	6942                	ld	s2,16(sp)
    800035ea:	69a2                	ld	s3,8(sp)
    800035ec:	6a02                	ld	s4,0(sp)
    800035ee:	6145                	addi	sp,sp,48
    800035f0:	8082                	ret
    panic("iget: no inodes");
    800035f2:	00005517          	auipc	a0,0x5
    800035f6:	18e50513          	addi	a0,a0,398 # 80008780 <syscalls+0x160>
    800035fa:	ffffd097          	auipc	ra,0xffffd
    800035fe:	f46080e7          	jalr	-186(ra) # 80000540 <panic>

0000000080003602 <fsinit>:
fsinit(int dev) {
    80003602:	7179                	addi	sp,sp,-48
    80003604:	f406                	sd	ra,40(sp)
    80003606:	f022                	sd	s0,32(sp)
    80003608:	ec26                	sd	s1,24(sp)
    8000360a:	e84a                	sd	s2,16(sp)
    8000360c:	e44e                	sd	s3,8(sp)
    8000360e:	1800                	addi	s0,sp,48
    80003610:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003612:	4585                	li	a1,1
    80003614:	00000097          	auipc	ra,0x0
    80003618:	a54080e7          	jalr	-1452(ra) # 80003068 <bread>
    8000361c:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000361e:	00024997          	auipc	s3,0x24
    80003622:	f7298993          	addi	s3,s3,-142 # 80027590 <sb>
    80003626:	02000613          	li	a2,32
    8000362a:	05850593          	addi	a1,a0,88
    8000362e:	854e                	mv	a0,s3
    80003630:	ffffd097          	auipc	ra,0xffffd
    80003634:	6fe080e7          	jalr	1790(ra) # 80000d2e <memmove>
  brelse(bp);
    80003638:	8526                	mv	a0,s1
    8000363a:	00000097          	auipc	ra,0x0
    8000363e:	b5e080e7          	jalr	-1186(ra) # 80003198 <brelse>
  if(sb.magic != FSMAGIC)
    80003642:	0009a703          	lw	a4,0(s3)
    80003646:	102037b7          	lui	a5,0x10203
    8000364a:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000364e:	02f71263          	bne	a4,a5,80003672 <fsinit+0x70>
  initlog(dev, &sb);
    80003652:	00024597          	auipc	a1,0x24
    80003656:	f3e58593          	addi	a1,a1,-194 # 80027590 <sb>
    8000365a:	854a                	mv	a0,s2
    8000365c:	00001097          	auipc	ra,0x1
    80003660:	b4a080e7          	jalr	-1206(ra) # 800041a6 <initlog>
}
    80003664:	70a2                	ld	ra,40(sp)
    80003666:	7402                	ld	s0,32(sp)
    80003668:	64e2                	ld	s1,24(sp)
    8000366a:	6942                	ld	s2,16(sp)
    8000366c:	69a2                	ld	s3,8(sp)
    8000366e:	6145                	addi	sp,sp,48
    80003670:	8082                	ret
    panic("invalid file system");
    80003672:	00005517          	auipc	a0,0x5
    80003676:	11e50513          	addi	a0,a0,286 # 80008790 <syscalls+0x170>
    8000367a:	ffffd097          	auipc	ra,0xffffd
    8000367e:	ec6080e7          	jalr	-314(ra) # 80000540 <panic>

0000000080003682 <iinit>:
{
    80003682:	7179                	addi	sp,sp,-48
    80003684:	f406                	sd	ra,40(sp)
    80003686:	f022                	sd	s0,32(sp)
    80003688:	ec26                	sd	s1,24(sp)
    8000368a:	e84a                	sd	s2,16(sp)
    8000368c:	e44e                	sd	s3,8(sp)
    8000368e:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003690:	00005597          	auipc	a1,0x5
    80003694:	11858593          	addi	a1,a1,280 # 800087a8 <syscalls+0x188>
    80003698:	00024517          	auipc	a0,0x24
    8000369c:	f1850513          	addi	a0,a0,-232 # 800275b0 <itable>
    800036a0:	ffffd097          	auipc	ra,0xffffd
    800036a4:	4a6080e7          	jalr	1190(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    800036a8:	00024497          	auipc	s1,0x24
    800036ac:	f3048493          	addi	s1,s1,-208 # 800275d8 <itable+0x28>
    800036b0:	00026997          	auipc	s3,0x26
    800036b4:	9b898993          	addi	s3,s3,-1608 # 80029068 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800036b8:	00005917          	auipc	s2,0x5
    800036bc:	0f890913          	addi	s2,s2,248 # 800087b0 <syscalls+0x190>
    800036c0:	85ca                	mv	a1,s2
    800036c2:	8526                	mv	a0,s1
    800036c4:	00001097          	auipc	ra,0x1
    800036c8:	e42080e7          	jalr	-446(ra) # 80004506 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800036cc:	08848493          	addi	s1,s1,136
    800036d0:	ff3498e3          	bne	s1,s3,800036c0 <iinit+0x3e>
}
    800036d4:	70a2                	ld	ra,40(sp)
    800036d6:	7402                	ld	s0,32(sp)
    800036d8:	64e2                	ld	s1,24(sp)
    800036da:	6942                	ld	s2,16(sp)
    800036dc:	69a2                	ld	s3,8(sp)
    800036de:	6145                	addi	sp,sp,48
    800036e0:	8082                	ret

00000000800036e2 <ialloc>:
{
    800036e2:	715d                	addi	sp,sp,-80
    800036e4:	e486                	sd	ra,72(sp)
    800036e6:	e0a2                	sd	s0,64(sp)
    800036e8:	fc26                	sd	s1,56(sp)
    800036ea:	f84a                	sd	s2,48(sp)
    800036ec:	f44e                	sd	s3,40(sp)
    800036ee:	f052                	sd	s4,32(sp)
    800036f0:	ec56                	sd	s5,24(sp)
    800036f2:	e85a                	sd	s6,16(sp)
    800036f4:	e45e                	sd	s7,8(sp)
    800036f6:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800036f8:	00024717          	auipc	a4,0x24
    800036fc:	ea472703          	lw	a4,-348(a4) # 8002759c <sb+0xc>
    80003700:	4785                	li	a5,1
    80003702:	04e7fa63          	bgeu	a5,a4,80003756 <ialloc+0x74>
    80003706:	8aaa                	mv	s5,a0
    80003708:	8bae                	mv	s7,a1
    8000370a:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000370c:	00024a17          	auipc	s4,0x24
    80003710:	e84a0a13          	addi	s4,s4,-380 # 80027590 <sb>
    80003714:	00048b1b          	sext.w	s6,s1
    80003718:	0044d593          	srli	a1,s1,0x4
    8000371c:	018a2783          	lw	a5,24(s4)
    80003720:	9dbd                	addw	a1,a1,a5
    80003722:	8556                	mv	a0,s5
    80003724:	00000097          	auipc	ra,0x0
    80003728:	944080e7          	jalr	-1724(ra) # 80003068 <bread>
    8000372c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000372e:	05850993          	addi	s3,a0,88
    80003732:	00f4f793          	andi	a5,s1,15
    80003736:	079a                	slli	a5,a5,0x6
    80003738:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000373a:	00099783          	lh	a5,0(s3)
    8000373e:	c3a1                	beqz	a5,8000377e <ialloc+0x9c>
    brelse(bp);
    80003740:	00000097          	auipc	ra,0x0
    80003744:	a58080e7          	jalr	-1448(ra) # 80003198 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003748:	0485                	addi	s1,s1,1
    8000374a:	00ca2703          	lw	a4,12(s4)
    8000374e:	0004879b          	sext.w	a5,s1
    80003752:	fce7e1e3          	bltu	a5,a4,80003714 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003756:	00005517          	auipc	a0,0x5
    8000375a:	06250513          	addi	a0,a0,98 # 800087b8 <syscalls+0x198>
    8000375e:	ffffd097          	auipc	ra,0xffffd
    80003762:	e2c080e7          	jalr	-468(ra) # 8000058a <printf>
  return 0;
    80003766:	4501                	li	a0,0
}
    80003768:	60a6                	ld	ra,72(sp)
    8000376a:	6406                	ld	s0,64(sp)
    8000376c:	74e2                	ld	s1,56(sp)
    8000376e:	7942                	ld	s2,48(sp)
    80003770:	79a2                	ld	s3,40(sp)
    80003772:	7a02                	ld	s4,32(sp)
    80003774:	6ae2                	ld	s5,24(sp)
    80003776:	6b42                	ld	s6,16(sp)
    80003778:	6ba2                	ld	s7,8(sp)
    8000377a:	6161                	addi	sp,sp,80
    8000377c:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    8000377e:	04000613          	li	a2,64
    80003782:	4581                	li	a1,0
    80003784:	854e                	mv	a0,s3
    80003786:	ffffd097          	auipc	ra,0xffffd
    8000378a:	54c080e7          	jalr	1356(ra) # 80000cd2 <memset>
      dip->type = type;
    8000378e:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003792:	854a                	mv	a0,s2
    80003794:	00001097          	auipc	ra,0x1
    80003798:	c8e080e7          	jalr	-882(ra) # 80004422 <log_write>
      brelse(bp);
    8000379c:	854a                	mv	a0,s2
    8000379e:	00000097          	auipc	ra,0x0
    800037a2:	9fa080e7          	jalr	-1542(ra) # 80003198 <brelse>
      return iget(dev, inum);
    800037a6:	85da                	mv	a1,s6
    800037a8:	8556                	mv	a0,s5
    800037aa:	00000097          	auipc	ra,0x0
    800037ae:	d9c080e7          	jalr	-612(ra) # 80003546 <iget>
    800037b2:	bf5d                	j	80003768 <ialloc+0x86>

00000000800037b4 <iupdate>:
{
    800037b4:	1101                	addi	sp,sp,-32
    800037b6:	ec06                	sd	ra,24(sp)
    800037b8:	e822                	sd	s0,16(sp)
    800037ba:	e426                	sd	s1,8(sp)
    800037bc:	e04a                	sd	s2,0(sp)
    800037be:	1000                	addi	s0,sp,32
    800037c0:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037c2:	415c                	lw	a5,4(a0)
    800037c4:	0047d79b          	srliw	a5,a5,0x4
    800037c8:	00024597          	auipc	a1,0x24
    800037cc:	de05a583          	lw	a1,-544(a1) # 800275a8 <sb+0x18>
    800037d0:	9dbd                	addw	a1,a1,a5
    800037d2:	4108                	lw	a0,0(a0)
    800037d4:	00000097          	auipc	ra,0x0
    800037d8:	894080e7          	jalr	-1900(ra) # 80003068 <bread>
    800037dc:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037de:	05850793          	addi	a5,a0,88
    800037e2:	40d8                	lw	a4,4(s1)
    800037e4:	8b3d                	andi	a4,a4,15
    800037e6:	071a                	slli	a4,a4,0x6
    800037e8:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    800037ea:	04449703          	lh	a4,68(s1)
    800037ee:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    800037f2:	04649703          	lh	a4,70(s1)
    800037f6:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    800037fa:	04849703          	lh	a4,72(s1)
    800037fe:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003802:	04a49703          	lh	a4,74(s1)
    80003806:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    8000380a:	44f8                	lw	a4,76(s1)
    8000380c:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000380e:	03400613          	li	a2,52
    80003812:	05048593          	addi	a1,s1,80
    80003816:	00c78513          	addi	a0,a5,12
    8000381a:	ffffd097          	auipc	ra,0xffffd
    8000381e:	514080e7          	jalr	1300(ra) # 80000d2e <memmove>
  log_write(bp);
    80003822:	854a                	mv	a0,s2
    80003824:	00001097          	auipc	ra,0x1
    80003828:	bfe080e7          	jalr	-1026(ra) # 80004422 <log_write>
  brelse(bp);
    8000382c:	854a                	mv	a0,s2
    8000382e:	00000097          	auipc	ra,0x0
    80003832:	96a080e7          	jalr	-1686(ra) # 80003198 <brelse>
}
    80003836:	60e2                	ld	ra,24(sp)
    80003838:	6442                	ld	s0,16(sp)
    8000383a:	64a2                	ld	s1,8(sp)
    8000383c:	6902                	ld	s2,0(sp)
    8000383e:	6105                	addi	sp,sp,32
    80003840:	8082                	ret

0000000080003842 <idup>:
{
    80003842:	1101                	addi	sp,sp,-32
    80003844:	ec06                	sd	ra,24(sp)
    80003846:	e822                	sd	s0,16(sp)
    80003848:	e426                	sd	s1,8(sp)
    8000384a:	1000                	addi	s0,sp,32
    8000384c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000384e:	00024517          	auipc	a0,0x24
    80003852:	d6250513          	addi	a0,a0,-670 # 800275b0 <itable>
    80003856:	ffffd097          	auipc	ra,0xffffd
    8000385a:	380080e7          	jalr	896(ra) # 80000bd6 <acquire>
  ip->ref++;
    8000385e:	449c                	lw	a5,8(s1)
    80003860:	2785                	addiw	a5,a5,1
    80003862:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003864:	00024517          	auipc	a0,0x24
    80003868:	d4c50513          	addi	a0,a0,-692 # 800275b0 <itable>
    8000386c:	ffffd097          	auipc	ra,0xffffd
    80003870:	41e080e7          	jalr	1054(ra) # 80000c8a <release>
}
    80003874:	8526                	mv	a0,s1
    80003876:	60e2                	ld	ra,24(sp)
    80003878:	6442                	ld	s0,16(sp)
    8000387a:	64a2                	ld	s1,8(sp)
    8000387c:	6105                	addi	sp,sp,32
    8000387e:	8082                	ret

0000000080003880 <ilock>:
{
    80003880:	1101                	addi	sp,sp,-32
    80003882:	ec06                	sd	ra,24(sp)
    80003884:	e822                	sd	s0,16(sp)
    80003886:	e426                	sd	s1,8(sp)
    80003888:	e04a                	sd	s2,0(sp)
    8000388a:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000388c:	c115                	beqz	a0,800038b0 <ilock+0x30>
    8000388e:	84aa                	mv	s1,a0
    80003890:	451c                	lw	a5,8(a0)
    80003892:	00f05f63          	blez	a5,800038b0 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003896:	0541                	addi	a0,a0,16
    80003898:	00001097          	auipc	ra,0x1
    8000389c:	ca8080e7          	jalr	-856(ra) # 80004540 <acquiresleep>
  if(ip->valid == 0){
    800038a0:	40bc                	lw	a5,64(s1)
    800038a2:	cf99                	beqz	a5,800038c0 <ilock+0x40>
}
    800038a4:	60e2                	ld	ra,24(sp)
    800038a6:	6442                	ld	s0,16(sp)
    800038a8:	64a2                	ld	s1,8(sp)
    800038aa:	6902                	ld	s2,0(sp)
    800038ac:	6105                	addi	sp,sp,32
    800038ae:	8082                	ret
    panic("ilock");
    800038b0:	00005517          	auipc	a0,0x5
    800038b4:	f2050513          	addi	a0,a0,-224 # 800087d0 <syscalls+0x1b0>
    800038b8:	ffffd097          	auipc	ra,0xffffd
    800038bc:	c88080e7          	jalr	-888(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038c0:	40dc                	lw	a5,4(s1)
    800038c2:	0047d79b          	srliw	a5,a5,0x4
    800038c6:	00024597          	auipc	a1,0x24
    800038ca:	ce25a583          	lw	a1,-798(a1) # 800275a8 <sb+0x18>
    800038ce:	9dbd                	addw	a1,a1,a5
    800038d0:	4088                	lw	a0,0(s1)
    800038d2:	fffff097          	auipc	ra,0xfffff
    800038d6:	796080e7          	jalr	1942(ra) # 80003068 <bread>
    800038da:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038dc:	05850593          	addi	a1,a0,88
    800038e0:	40dc                	lw	a5,4(s1)
    800038e2:	8bbd                	andi	a5,a5,15
    800038e4:	079a                	slli	a5,a5,0x6
    800038e6:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800038e8:	00059783          	lh	a5,0(a1)
    800038ec:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800038f0:	00259783          	lh	a5,2(a1)
    800038f4:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800038f8:	00459783          	lh	a5,4(a1)
    800038fc:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003900:	00659783          	lh	a5,6(a1)
    80003904:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003908:	459c                	lw	a5,8(a1)
    8000390a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000390c:	03400613          	li	a2,52
    80003910:	05b1                	addi	a1,a1,12
    80003912:	05048513          	addi	a0,s1,80
    80003916:	ffffd097          	auipc	ra,0xffffd
    8000391a:	418080e7          	jalr	1048(ra) # 80000d2e <memmove>
    brelse(bp);
    8000391e:	854a                	mv	a0,s2
    80003920:	00000097          	auipc	ra,0x0
    80003924:	878080e7          	jalr	-1928(ra) # 80003198 <brelse>
    ip->valid = 1;
    80003928:	4785                	li	a5,1
    8000392a:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000392c:	04449783          	lh	a5,68(s1)
    80003930:	fbb5                	bnez	a5,800038a4 <ilock+0x24>
      panic("ilock: no type");
    80003932:	00005517          	auipc	a0,0x5
    80003936:	ea650513          	addi	a0,a0,-346 # 800087d8 <syscalls+0x1b8>
    8000393a:	ffffd097          	auipc	ra,0xffffd
    8000393e:	c06080e7          	jalr	-1018(ra) # 80000540 <panic>

0000000080003942 <iunlock>:
{
    80003942:	1101                	addi	sp,sp,-32
    80003944:	ec06                	sd	ra,24(sp)
    80003946:	e822                	sd	s0,16(sp)
    80003948:	e426                	sd	s1,8(sp)
    8000394a:	e04a                	sd	s2,0(sp)
    8000394c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000394e:	c905                	beqz	a0,8000397e <iunlock+0x3c>
    80003950:	84aa                	mv	s1,a0
    80003952:	01050913          	addi	s2,a0,16
    80003956:	854a                	mv	a0,s2
    80003958:	00001097          	auipc	ra,0x1
    8000395c:	c82080e7          	jalr	-894(ra) # 800045da <holdingsleep>
    80003960:	cd19                	beqz	a0,8000397e <iunlock+0x3c>
    80003962:	449c                	lw	a5,8(s1)
    80003964:	00f05d63          	blez	a5,8000397e <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003968:	854a                	mv	a0,s2
    8000396a:	00001097          	auipc	ra,0x1
    8000396e:	c2c080e7          	jalr	-980(ra) # 80004596 <releasesleep>
}
    80003972:	60e2                	ld	ra,24(sp)
    80003974:	6442                	ld	s0,16(sp)
    80003976:	64a2                	ld	s1,8(sp)
    80003978:	6902                	ld	s2,0(sp)
    8000397a:	6105                	addi	sp,sp,32
    8000397c:	8082                	ret
    panic("iunlock");
    8000397e:	00005517          	auipc	a0,0x5
    80003982:	e6a50513          	addi	a0,a0,-406 # 800087e8 <syscalls+0x1c8>
    80003986:	ffffd097          	auipc	ra,0xffffd
    8000398a:	bba080e7          	jalr	-1094(ra) # 80000540 <panic>

000000008000398e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000398e:	7179                	addi	sp,sp,-48
    80003990:	f406                	sd	ra,40(sp)
    80003992:	f022                	sd	s0,32(sp)
    80003994:	ec26                	sd	s1,24(sp)
    80003996:	e84a                	sd	s2,16(sp)
    80003998:	e44e                	sd	s3,8(sp)
    8000399a:	e052                	sd	s4,0(sp)
    8000399c:	1800                	addi	s0,sp,48
    8000399e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800039a0:	05050493          	addi	s1,a0,80
    800039a4:	08050913          	addi	s2,a0,128
    800039a8:	a021                	j	800039b0 <itrunc+0x22>
    800039aa:	0491                	addi	s1,s1,4
    800039ac:	01248d63          	beq	s1,s2,800039c6 <itrunc+0x38>
    if(ip->addrs[i]){
    800039b0:	408c                	lw	a1,0(s1)
    800039b2:	dde5                	beqz	a1,800039aa <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800039b4:	0009a503          	lw	a0,0(s3)
    800039b8:	00000097          	auipc	ra,0x0
    800039bc:	8f6080e7          	jalr	-1802(ra) # 800032ae <bfree>
      ip->addrs[i] = 0;
    800039c0:	0004a023          	sw	zero,0(s1)
    800039c4:	b7dd                	j	800039aa <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800039c6:	0809a583          	lw	a1,128(s3)
    800039ca:	e185                	bnez	a1,800039ea <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800039cc:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800039d0:	854e                	mv	a0,s3
    800039d2:	00000097          	auipc	ra,0x0
    800039d6:	de2080e7          	jalr	-542(ra) # 800037b4 <iupdate>
}
    800039da:	70a2                	ld	ra,40(sp)
    800039dc:	7402                	ld	s0,32(sp)
    800039de:	64e2                	ld	s1,24(sp)
    800039e0:	6942                	ld	s2,16(sp)
    800039e2:	69a2                	ld	s3,8(sp)
    800039e4:	6a02                	ld	s4,0(sp)
    800039e6:	6145                	addi	sp,sp,48
    800039e8:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800039ea:	0009a503          	lw	a0,0(s3)
    800039ee:	fffff097          	auipc	ra,0xfffff
    800039f2:	67a080e7          	jalr	1658(ra) # 80003068 <bread>
    800039f6:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800039f8:	05850493          	addi	s1,a0,88
    800039fc:	45850913          	addi	s2,a0,1112
    80003a00:	a021                	j	80003a08 <itrunc+0x7a>
    80003a02:	0491                	addi	s1,s1,4
    80003a04:	01248b63          	beq	s1,s2,80003a1a <itrunc+0x8c>
      if(a[j])
    80003a08:	408c                	lw	a1,0(s1)
    80003a0a:	dde5                	beqz	a1,80003a02 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003a0c:	0009a503          	lw	a0,0(s3)
    80003a10:	00000097          	auipc	ra,0x0
    80003a14:	89e080e7          	jalr	-1890(ra) # 800032ae <bfree>
    80003a18:	b7ed                	j	80003a02 <itrunc+0x74>
    brelse(bp);
    80003a1a:	8552                	mv	a0,s4
    80003a1c:	fffff097          	auipc	ra,0xfffff
    80003a20:	77c080e7          	jalr	1916(ra) # 80003198 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003a24:	0809a583          	lw	a1,128(s3)
    80003a28:	0009a503          	lw	a0,0(s3)
    80003a2c:	00000097          	auipc	ra,0x0
    80003a30:	882080e7          	jalr	-1918(ra) # 800032ae <bfree>
    ip->addrs[NDIRECT] = 0;
    80003a34:	0809a023          	sw	zero,128(s3)
    80003a38:	bf51                	j	800039cc <itrunc+0x3e>

0000000080003a3a <iput>:
{
    80003a3a:	1101                	addi	sp,sp,-32
    80003a3c:	ec06                	sd	ra,24(sp)
    80003a3e:	e822                	sd	s0,16(sp)
    80003a40:	e426                	sd	s1,8(sp)
    80003a42:	e04a                	sd	s2,0(sp)
    80003a44:	1000                	addi	s0,sp,32
    80003a46:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a48:	00024517          	auipc	a0,0x24
    80003a4c:	b6850513          	addi	a0,a0,-1176 # 800275b0 <itable>
    80003a50:	ffffd097          	auipc	ra,0xffffd
    80003a54:	186080e7          	jalr	390(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a58:	4498                	lw	a4,8(s1)
    80003a5a:	4785                	li	a5,1
    80003a5c:	02f70363          	beq	a4,a5,80003a82 <iput+0x48>
  ip->ref--;
    80003a60:	449c                	lw	a5,8(s1)
    80003a62:	37fd                	addiw	a5,a5,-1
    80003a64:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003a66:	00024517          	auipc	a0,0x24
    80003a6a:	b4a50513          	addi	a0,a0,-1206 # 800275b0 <itable>
    80003a6e:	ffffd097          	auipc	ra,0xffffd
    80003a72:	21c080e7          	jalr	540(ra) # 80000c8a <release>
}
    80003a76:	60e2                	ld	ra,24(sp)
    80003a78:	6442                	ld	s0,16(sp)
    80003a7a:	64a2                	ld	s1,8(sp)
    80003a7c:	6902                	ld	s2,0(sp)
    80003a7e:	6105                	addi	sp,sp,32
    80003a80:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a82:	40bc                	lw	a5,64(s1)
    80003a84:	dff1                	beqz	a5,80003a60 <iput+0x26>
    80003a86:	04a49783          	lh	a5,74(s1)
    80003a8a:	fbf9                	bnez	a5,80003a60 <iput+0x26>
    acquiresleep(&ip->lock);
    80003a8c:	01048913          	addi	s2,s1,16
    80003a90:	854a                	mv	a0,s2
    80003a92:	00001097          	auipc	ra,0x1
    80003a96:	aae080e7          	jalr	-1362(ra) # 80004540 <acquiresleep>
    release(&itable.lock);
    80003a9a:	00024517          	auipc	a0,0x24
    80003a9e:	b1650513          	addi	a0,a0,-1258 # 800275b0 <itable>
    80003aa2:	ffffd097          	auipc	ra,0xffffd
    80003aa6:	1e8080e7          	jalr	488(ra) # 80000c8a <release>
    itrunc(ip);
    80003aaa:	8526                	mv	a0,s1
    80003aac:	00000097          	auipc	ra,0x0
    80003ab0:	ee2080e7          	jalr	-286(ra) # 8000398e <itrunc>
    ip->type = 0;
    80003ab4:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003ab8:	8526                	mv	a0,s1
    80003aba:	00000097          	auipc	ra,0x0
    80003abe:	cfa080e7          	jalr	-774(ra) # 800037b4 <iupdate>
    ip->valid = 0;
    80003ac2:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003ac6:	854a                	mv	a0,s2
    80003ac8:	00001097          	auipc	ra,0x1
    80003acc:	ace080e7          	jalr	-1330(ra) # 80004596 <releasesleep>
    acquire(&itable.lock);
    80003ad0:	00024517          	auipc	a0,0x24
    80003ad4:	ae050513          	addi	a0,a0,-1312 # 800275b0 <itable>
    80003ad8:	ffffd097          	auipc	ra,0xffffd
    80003adc:	0fe080e7          	jalr	254(ra) # 80000bd6 <acquire>
    80003ae0:	b741                	j	80003a60 <iput+0x26>

0000000080003ae2 <iunlockput>:
{
    80003ae2:	1101                	addi	sp,sp,-32
    80003ae4:	ec06                	sd	ra,24(sp)
    80003ae6:	e822                	sd	s0,16(sp)
    80003ae8:	e426                	sd	s1,8(sp)
    80003aea:	1000                	addi	s0,sp,32
    80003aec:	84aa                	mv	s1,a0
  iunlock(ip);
    80003aee:	00000097          	auipc	ra,0x0
    80003af2:	e54080e7          	jalr	-428(ra) # 80003942 <iunlock>
  iput(ip);
    80003af6:	8526                	mv	a0,s1
    80003af8:	00000097          	auipc	ra,0x0
    80003afc:	f42080e7          	jalr	-190(ra) # 80003a3a <iput>
}
    80003b00:	60e2                	ld	ra,24(sp)
    80003b02:	6442                	ld	s0,16(sp)
    80003b04:	64a2                	ld	s1,8(sp)
    80003b06:	6105                	addi	sp,sp,32
    80003b08:	8082                	ret

0000000080003b0a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003b0a:	1141                	addi	sp,sp,-16
    80003b0c:	e422                	sd	s0,8(sp)
    80003b0e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003b10:	411c                	lw	a5,0(a0)
    80003b12:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003b14:	415c                	lw	a5,4(a0)
    80003b16:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003b18:	04451783          	lh	a5,68(a0)
    80003b1c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003b20:	04a51783          	lh	a5,74(a0)
    80003b24:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003b28:	04c56783          	lwu	a5,76(a0)
    80003b2c:	e99c                	sd	a5,16(a1)
}
    80003b2e:	6422                	ld	s0,8(sp)
    80003b30:	0141                	addi	sp,sp,16
    80003b32:	8082                	ret

0000000080003b34 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b34:	457c                	lw	a5,76(a0)
    80003b36:	0ed7e963          	bltu	a5,a3,80003c28 <readi+0xf4>
{
    80003b3a:	7159                	addi	sp,sp,-112
    80003b3c:	f486                	sd	ra,104(sp)
    80003b3e:	f0a2                	sd	s0,96(sp)
    80003b40:	eca6                	sd	s1,88(sp)
    80003b42:	e8ca                	sd	s2,80(sp)
    80003b44:	e4ce                	sd	s3,72(sp)
    80003b46:	e0d2                	sd	s4,64(sp)
    80003b48:	fc56                	sd	s5,56(sp)
    80003b4a:	f85a                	sd	s6,48(sp)
    80003b4c:	f45e                	sd	s7,40(sp)
    80003b4e:	f062                	sd	s8,32(sp)
    80003b50:	ec66                	sd	s9,24(sp)
    80003b52:	e86a                	sd	s10,16(sp)
    80003b54:	e46e                	sd	s11,8(sp)
    80003b56:	1880                	addi	s0,sp,112
    80003b58:	8b2a                	mv	s6,a0
    80003b5a:	8bae                	mv	s7,a1
    80003b5c:	8a32                	mv	s4,a2
    80003b5e:	84b6                	mv	s1,a3
    80003b60:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003b62:	9f35                	addw	a4,a4,a3
    return 0;
    80003b64:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003b66:	0ad76063          	bltu	a4,a3,80003c06 <readi+0xd2>
  if(off + n > ip->size)
    80003b6a:	00e7f463          	bgeu	a5,a4,80003b72 <readi+0x3e>
    n = ip->size - off;
    80003b6e:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b72:	0a0a8963          	beqz	s5,80003c24 <readi+0xf0>
    80003b76:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b78:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003b7c:	5c7d                	li	s8,-1
    80003b7e:	a82d                	j	80003bb8 <readi+0x84>
    80003b80:	020d1d93          	slli	s11,s10,0x20
    80003b84:	020ddd93          	srli	s11,s11,0x20
    80003b88:	05890613          	addi	a2,s2,88
    80003b8c:	86ee                	mv	a3,s11
    80003b8e:	963a                	add	a2,a2,a4
    80003b90:	85d2                	mv	a1,s4
    80003b92:	855e                	mv	a0,s7
    80003b94:	fffff097          	auipc	ra,0xfffff
    80003b98:	978080e7          	jalr	-1672(ra) # 8000250c <either_copyout>
    80003b9c:	05850d63          	beq	a0,s8,80003bf6 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003ba0:	854a                	mv	a0,s2
    80003ba2:	fffff097          	auipc	ra,0xfffff
    80003ba6:	5f6080e7          	jalr	1526(ra) # 80003198 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003baa:	013d09bb          	addw	s3,s10,s3
    80003bae:	009d04bb          	addw	s1,s10,s1
    80003bb2:	9a6e                	add	s4,s4,s11
    80003bb4:	0559f763          	bgeu	s3,s5,80003c02 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003bb8:	00a4d59b          	srliw	a1,s1,0xa
    80003bbc:	855a                	mv	a0,s6
    80003bbe:	00000097          	auipc	ra,0x0
    80003bc2:	89e080e7          	jalr	-1890(ra) # 8000345c <bmap>
    80003bc6:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003bca:	cd85                	beqz	a1,80003c02 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003bcc:	000b2503          	lw	a0,0(s6)
    80003bd0:	fffff097          	auipc	ra,0xfffff
    80003bd4:	498080e7          	jalr	1176(ra) # 80003068 <bread>
    80003bd8:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bda:	3ff4f713          	andi	a4,s1,1023
    80003bde:	40ec87bb          	subw	a5,s9,a4
    80003be2:	413a86bb          	subw	a3,s5,s3
    80003be6:	8d3e                	mv	s10,a5
    80003be8:	2781                	sext.w	a5,a5
    80003bea:	0006861b          	sext.w	a2,a3
    80003bee:	f8f679e3          	bgeu	a2,a5,80003b80 <readi+0x4c>
    80003bf2:	8d36                	mv	s10,a3
    80003bf4:	b771                	j	80003b80 <readi+0x4c>
      brelse(bp);
    80003bf6:	854a                	mv	a0,s2
    80003bf8:	fffff097          	auipc	ra,0xfffff
    80003bfc:	5a0080e7          	jalr	1440(ra) # 80003198 <brelse>
      tot = -1;
    80003c00:	59fd                	li	s3,-1
  }
  return tot;
    80003c02:	0009851b          	sext.w	a0,s3
}
    80003c06:	70a6                	ld	ra,104(sp)
    80003c08:	7406                	ld	s0,96(sp)
    80003c0a:	64e6                	ld	s1,88(sp)
    80003c0c:	6946                	ld	s2,80(sp)
    80003c0e:	69a6                	ld	s3,72(sp)
    80003c10:	6a06                	ld	s4,64(sp)
    80003c12:	7ae2                	ld	s5,56(sp)
    80003c14:	7b42                	ld	s6,48(sp)
    80003c16:	7ba2                	ld	s7,40(sp)
    80003c18:	7c02                	ld	s8,32(sp)
    80003c1a:	6ce2                	ld	s9,24(sp)
    80003c1c:	6d42                	ld	s10,16(sp)
    80003c1e:	6da2                	ld	s11,8(sp)
    80003c20:	6165                	addi	sp,sp,112
    80003c22:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c24:	89d6                	mv	s3,s5
    80003c26:	bff1                	j	80003c02 <readi+0xce>
    return 0;
    80003c28:	4501                	li	a0,0
}
    80003c2a:	8082                	ret

0000000080003c2c <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c2c:	457c                	lw	a5,76(a0)
    80003c2e:	10d7e863          	bltu	a5,a3,80003d3e <writei+0x112>
{
    80003c32:	7159                	addi	sp,sp,-112
    80003c34:	f486                	sd	ra,104(sp)
    80003c36:	f0a2                	sd	s0,96(sp)
    80003c38:	eca6                	sd	s1,88(sp)
    80003c3a:	e8ca                	sd	s2,80(sp)
    80003c3c:	e4ce                	sd	s3,72(sp)
    80003c3e:	e0d2                	sd	s4,64(sp)
    80003c40:	fc56                	sd	s5,56(sp)
    80003c42:	f85a                	sd	s6,48(sp)
    80003c44:	f45e                	sd	s7,40(sp)
    80003c46:	f062                	sd	s8,32(sp)
    80003c48:	ec66                	sd	s9,24(sp)
    80003c4a:	e86a                	sd	s10,16(sp)
    80003c4c:	e46e                	sd	s11,8(sp)
    80003c4e:	1880                	addi	s0,sp,112
    80003c50:	8aaa                	mv	s5,a0
    80003c52:	8bae                	mv	s7,a1
    80003c54:	8a32                	mv	s4,a2
    80003c56:	8936                	mv	s2,a3
    80003c58:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c5a:	00e687bb          	addw	a5,a3,a4
    80003c5e:	0ed7e263          	bltu	a5,a3,80003d42 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003c62:	00043737          	lui	a4,0x43
    80003c66:	0ef76063          	bltu	a4,a5,80003d46 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c6a:	0c0b0863          	beqz	s6,80003d3a <writei+0x10e>
    80003c6e:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c70:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003c74:	5c7d                	li	s8,-1
    80003c76:	a091                	j	80003cba <writei+0x8e>
    80003c78:	020d1d93          	slli	s11,s10,0x20
    80003c7c:	020ddd93          	srli	s11,s11,0x20
    80003c80:	05848513          	addi	a0,s1,88
    80003c84:	86ee                	mv	a3,s11
    80003c86:	8652                	mv	a2,s4
    80003c88:	85de                	mv	a1,s7
    80003c8a:	953a                	add	a0,a0,a4
    80003c8c:	fffff097          	auipc	ra,0xfffff
    80003c90:	8d6080e7          	jalr	-1834(ra) # 80002562 <either_copyin>
    80003c94:	07850263          	beq	a0,s8,80003cf8 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003c98:	8526                	mv	a0,s1
    80003c9a:	00000097          	auipc	ra,0x0
    80003c9e:	788080e7          	jalr	1928(ra) # 80004422 <log_write>
    brelse(bp);
    80003ca2:	8526                	mv	a0,s1
    80003ca4:	fffff097          	auipc	ra,0xfffff
    80003ca8:	4f4080e7          	jalr	1268(ra) # 80003198 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cac:	013d09bb          	addw	s3,s10,s3
    80003cb0:	012d093b          	addw	s2,s10,s2
    80003cb4:	9a6e                	add	s4,s4,s11
    80003cb6:	0569f663          	bgeu	s3,s6,80003d02 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003cba:	00a9559b          	srliw	a1,s2,0xa
    80003cbe:	8556                	mv	a0,s5
    80003cc0:	fffff097          	auipc	ra,0xfffff
    80003cc4:	79c080e7          	jalr	1948(ra) # 8000345c <bmap>
    80003cc8:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003ccc:	c99d                	beqz	a1,80003d02 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003cce:	000aa503          	lw	a0,0(s5)
    80003cd2:	fffff097          	auipc	ra,0xfffff
    80003cd6:	396080e7          	jalr	918(ra) # 80003068 <bread>
    80003cda:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cdc:	3ff97713          	andi	a4,s2,1023
    80003ce0:	40ec87bb          	subw	a5,s9,a4
    80003ce4:	413b06bb          	subw	a3,s6,s3
    80003ce8:	8d3e                	mv	s10,a5
    80003cea:	2781                	sext.w	a5,a5
    80003cec:	0006861b          	sext.w	a2,a3
    80003cf0:	f8f674e3          	bgeu	a2,a5,80003c78 <writei+0x4c>
    80003cf4:	8d36                	mv	s10,a3
    80003cf6:	b749                	j	80003c78 <writei+0x4c>
      brelse(bp);
    80003cf8:	8526                	mv	a0,s1
    80003cfa:	fffff097          	auipc	ra,0xfffff
    80003cfe:	49e080e7          	jalr	1182(ra) # 80003198 <brelse>
  }

  if(off > ip->size)
    80003d02:	04caa783          	lw	a5,76(s5)
    80003d06:	0127f463          	bgeu	a5,s2,80003d0e <writei+0xe2>
    ip->size = off;
    80003d0a:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003d0e:	8556                	mv	a0,s5
    80003d10:	00000097          	auipc	ra,0x0
    80003d14:	aa4080e7          	jalr	-1372(ra) # 800037b4 <iupdate>

  return tot;
    80003d18:	0009851b          	sext.w	a0,s3
}
    80003d1c:	70a6                	ld	ra,104(sp)
    80003d1e:	7406                	ld	s0,96(sp)
    80003d20:	64e6                	ld	s1,88(sp)
    80003d22:	6946                	ld	s2,80(sp)
    80003d24:	69a6                	ld	s3,72(sp)
    80003d26:	6a06                	ld	s4,64(sp)
    80003d28:	7ae2                	ld	s5,56(sp)
    80003d2a:	7b42                	ld	s6,48(sp)
    80003d2c:	7ba2                	ld	s7,40(sp)
    80003d2e:	7c02                	ld	s8,32(sp)
    80003d30:	6ce2                	ld	s9,24(sp)
    80003d32:	6d42                	ld	s10,16(sp)
    80003d34:	6da2                	ld	s11,8(sp)
    80003d36:	6165                	addi	sp,sp,112
    80003d38:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d3a:	89da                	mv	s3,s6
    80003d3c:	bfc9                	j	80003d0e <writei+0xe2>
    return -1;
    80003d3e:	557d                	li	a0,-1
}
    80003d40:	8082                	ret
    return -1;
    80003d42:	557d                	li	a0,-1
    80003d44:	bfe1                	j	80003d1c <writei+0xf0>
    return -1;
    80003d46:	557d                	li	a0,-1
    80003d48:	bfd1                	j	80003d1c <writei+0xf0>

0000000080003d4a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003d4a:	1141                	addi	sp,sp,-16
    80003d4c:	e406                	sd	ra,8(sp)
    80003d4e:	e022                	sd	s0,0(sp)
    80003d50:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003d52:	4639                	li	a2,14
    80003d54:	ffffd097          	auipc	ra,0xffffd
    80003d58:	04e080e7          	jalr	78(ra) # 80000da2 <strncmp>
}
    80003d5c:	60a2                	ld	ra,8(sp)
    80003d5e:	6402                	ld	s0,0(sp)
    80003d60:	0141                	addi	sp,sp,16
    80003d62:	8082                	ret

0000000080003d64 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003d64:	7139                	addi	sp,sp,-64
    80003d66:	fc06                	sd	ra,56(sp)
    80003d68:	f822                	sd	s0,48(sp)
    80003d6a:	f426                	sd	s1,40(sp)
    80003d6c:	f04a                	sd	s2,32(sp)
    80003d6e:	ec4e                	sd	s3,24(sp)
    80003d70:	e852                	sd	s4,16(sp)
    80003d72:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003d74:	04451703          	lh	a4,68(a0)
    80003d78:	4785                	li	a5,1
    80003d7a:	00f71a63          	bne	a4,a5,80003d8e <dirlookup+0x2a>
    80003d7e:	892a                	mv	s2,a0
    80003d80:	89ae                	mv	s3,a1
    80003d82:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d84:	457c                	lw	a5,76(a0)
    80003d86:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003d88:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d8a:	e79d                	bnez	a5,80003db8 <dirlookup+0x54>
    80003d8c:	a8a5                	j	80003e04 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003d8e:	00005517          	auipc	a0,0x5
    80003d92:	a6250513          	addi	a0,a0,-1438 # 800087f0 <syscalls+0x1d0>
    80003d96:	ffffc097          	auipc	ra,0xffffc
    80003d9a:	7aa080e7          	jalr	1962(ra) # 80000540 <panic>
      panic("dirlookup read");
    80003d9e:	00005517          	auipc	a0,0x5
    80003da2:	a6a50513          	addi	a0,a0,-1430 # 80008808 <syscalls+0x1e8>
    80003da6:	ffffc097          	auipc	ra,0xffffc
    80003daa:	79a080e7          	jalr	1946(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dae:	24c1                	addiw	s1,s1,16
    80003db0:	04c92783          	lw	a5,76(s2)
    80003db4:	04f4f763          	bgeu	s1,a5,80003e02 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003db8:	4741                	li	a4,16
    80003dba:	86a6                	mv	a3,s1
    80003dbc:	fc040613          	addi	a2,s0,-64
    80003dc0:	4581                	li	a1,0
    80003dc2:	854a                	mv	a0,s2
    80003dc4:	00000097          	auipc	ra,0x0
    80003dc8:	d70080e7          	jalr	-656(ra) # 80003b34 <readi>
    80003dcc:	47c1                	li	a5,16
    80003dce:	fcf518e3          	bne	a0,a5,80003d9e <dirlookup+0x3a>
    if(de.inum == 0)
    80003dd2:	fc045783          	lhu	a5,-64(s0)
    80003dd6:	dfe1                	beqz	a5,80003dae <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003dd8:	fc240593          	addi	a1,s0,-62
    80003ddc:	854e                	mv	a0,s3
    80003dde:	00000097          	auipc	ra,0x0
    80003de2:	f6c080e7          	jalr	-148(ra) # 80003d4a <namecmp>
    80003de6:	f561                	bnez	a0,80003dae <dirlookup+0x4a>
      if(poff)
    80003de8:	000a0463          	beqz	s4,80003df0 <dirlookup+0x8c>
        *poff = off;
    80003dec:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003df0:	fc045583          	lhu	a1,-64(s0)
    80003df4:	00092503          	lw	a0,0(s2)
    80003df8:	fffff097          	auipc	ra,0xfffff
    80003dfc:	74e080e7          	jalr	1870(ra) # 80003546 <iget>
    80003e00:	a011                	j	80003e04 <dirlookup+0xa0>
  return 0;
    80003e02:	4501                	li	a0,0
}
    80003e04:	70e2                	ld	ra,56(sp)
    80003e06:	7442                	ld	s0,48(sp)
    80003e08:	74a2                	ld	s1,40(sp)
    80003e0a:	7902                	ld	s2,32(sp)
    80003e0c:	69e2                	ld	s3,24(sp)
    80003e0e:	6a42                	ld	s4,16(sp)
    80003e10:	6121                	addi	sp,sp,64
    80003e12:	8082                	ret

0000000080003e14 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003e14:	711d                	addi	sp,sp,-96
    80003e16:	ec86                	sd	ra,88(sp)
    80003e18:	e8a2                	sd	s0,80(sp)
    80003e1a:	e4a6                	sd	s1,72(sp)
    80003e1c:	e0ca                	sd	s2,64(sp)
    80003e1e:	fc4e                	sd	s3,56(sp)
    80003e20:	f852                	sd	s4,48(sp)
    80003e22:	f456                	sd	s5,40(sp)
    80003e24:	f05a                	sd	s6,32(sp)
    80003e26:	ec5e                	sd	s7,24(sp)
    80003e28:	e862                	sd	s8,16(sp)
    80003e2a:	e466                	sd	s9,8(sp)
    80003e2c:	e06a                	sd	s10,0(sp)
    80003e2e:	1080                	addi	s0,sp,96
    80003e30:	84aa                	mv	s1,a0
    80003e32:	8b2e                	mv	s6,a1
    80003e34:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003e36:	00054703          	lbu	a4,0(a0)
    80003e3a:	02f00793          	li	a5,47
    80003e3e:	02f70363          	beq	a4,a5,80003e64 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003e42:	ffffe097          	auipc	ra,0xffffe
    80003e46:	b6a080e7          	jalr	-1174(ra) # 800019ac <myproc>
    80003e4a:	15053503          	ld	a0,336(a0)
    80003e4e:	00000097          	auipc	ra,0x0
    80003e52:	9f4080e7          	jalr	-1548(ra) # 80003842 <idup>
    80003e56:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003e58:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003e5c:	4cb5                	li	s9,13
  len = path - s;
    80003e5e:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003e60:	4c05                	li	s8,1
    80003e62:	a87d                	j	80003f20 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80003e64:	4585                	li	a1,1
    80003e66:	4505                	li	a0,1
    80003e68:	fffff097          	auipc	ra,0xfffff
    80003e6c:	6de080e7          	jalr	1758(ra) # 80003546 <iget>
    80003e70:	8a2a                	mv	s4,a0
    80003e72:	b7dd                	j	80003e58 <namex+0x44>
      iunlockput(ip);
    80003e74:	8552                	mv	a0,s4
    80003e76:	00000097          	auipc	ra,0x0
    80003e7a:	c6c080e7          	jalr	-916(ra) # 80003ae2 <iunlockput>
      return 0;
    80003e7e:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003e80:	8552                	mv	a0,s4
    80003e82:	60e6                	ld	ra,88(sp)
    80003e84:	6446                	ld	s0,80(sp)
    80003e86:	64a6                	ld	s1,72(sp)
    80003e88:	6906                	ld	s2,64(sp)
    80003e8a:	79e2                	ld	s3,56(sp)
    80003e8c:	7a42                	ld	s4,48(sp)
    80003e8e:	7aa2                	ld	s5,40(sp)
    80003e90:	7b02                	ld	s6,32(sp)
    80003e92:	6be2                	ld	s7,24(sp)
    80003e94:	6c42                	ld	s8,16(sp)
    80003e96:	6ca2                	ld	s9,8(sp)
    80003e98:	6d02                	ld	s10,0(sp)
    80003e9a:	6125                	addi	sp,sp,96
    80003e9c:	8082                	ret
      iunlock(ip);
    80003e9e:	8552                	mv	a0,s4
    80003ea0:	00000097          	auipc	ra,0x0
    80003ea4:	aa2080e7          	jalr	-1374(ra) # 80003942 <iunlock>
      return ip;
    80003ea8:	bfe1                	j	80003e80 <namex+0x6c>
      iunlockput(ip);
    80003eaa:	8552                	mv	a0,s4
    80003eac:	00000097          	auipc	ra,0x0
    80003eb0:	c36080e7          	jalr	-970(ra) # 80003ae2 <iunlockput>
      return 0;
    80003eb4:	8a4e                	mv	s4,s3
    80003eb6:	b7e9                	j	80003e80 <namex+0x6c>
  len = path - s;
    80003eb8:	40998633          	sub	a2,s3,s1
    80003ebc:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80003ec0:	09acd863          	bge	s9,s10,80003f50 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80003ec4:	4639                	li	a2,14
    80003ec6:	85a6                	mv	a1,s1
    80003ec8:	8556                	mv	a0,s5
    80003eca:	ffffd097          	auipc	ra,0xffffd
    80003ece:	e64080e7          	jalr	-412(ra) # 80000d2e <memmove>
    80003ed2:	84ce                	mv	s1,s3
  while(*path == '/')
    80003ed4:	0004c783          	lbu	a5,0(s1)
    80003ed8:	01279763          	bne	a5,s2,80003ee6 <namex+0xd2>
    path++;
    80003edc:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003ede:	0004c783          	lbu	a5,0(s1)
    80003ee2:	ff278de3          	beq	a5,s2,80003edc <namex+0xc8>
    ilock(ip);
    80003ee6:	8552                	mv	a0,s4
    80003ee8:	00000097          	auipc	ra,0x0
    80003eec:	998080e7          	jalr	-1640(ra) # 80003880 <ilock>
    if(ip->type != T_DIR){
    80003ef0:	044a1783          	lh	a5,68(s4)
    80003ef4:	f98790e3          	bne	a5,s8,80003e74 <namex+0x60>
    if(nameiparent && *path == '\0'){
    80003ef8:	000b0563          	beqz	s6,80003f02 <namex+0xee>
    80003efc:	0004c783          	lbu	a5,0(s1)
    80003f00:	dfd9                	beqz	a5,80003e9e <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003f02:	865e                	mv	a2,s7
    80003f04:	85d6                	mv	a1,s5
    80003f06:	8552                	mv	a0,s4
    80003f08:	00000097          	auipc	ra,0x0
    80003f0c:	e5c080e7          	jalr	-420(ra) # 80003d64 <dirlookup>
    80003f10:	89aa                	mv	s3,a0
    80003f12:	dd41                	beqz	a0,80003eaa <namex+0x96>
    iunlockput(ip);
    80003f14:	8552                	mv	a0,s4
    80003f16:	00000097          	auipc	ra,0x0
    80003f1a:	bcc080e7          	jalr	-1076(ra) # 80003ae2 <iunlockput>
    ip = next;
    80003f1e:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003f20:	0004c783          	lbu	a5,0(s1)
    80003f24:	01279763          	bne	a5,s2,80003f32 <namex+0x11e>
    path++;
    80003f28:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f2a:	0004c783          	lbu	a5,0(s1)
    80003f2e:	ff278de3          	beq	a5,s2,80003f28 <namex+0x114>
  if(*path == 0)
    80003f32:	cb9d                	beqz	a5,80003f68 <namex+0x154>
  while(*path != '/' && *path != 0)
    80003f34:	0004c783          	lbu	a5,0(s1)
    80003f38:	89a6                	mv	s3,s1
  len = path - s;
    80003f3a:	8d5e                	mv	s10,s7
    80003f3c:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003f3e:	01278963          	beq	a5,s2,80003f50 <namex+0x13c>
    80003f42:	dbbd                	beqz	a5,80003eb8 <namex+0xa4>
    path++;
    80003f44:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003f46:	0009c783          	lbu	a5,0(s3)
    80003f4a:	ff279ce3          	bne	a5,s2,80003f42 <namex+0x12e>
    80003f4e:	b7ad                	j	80003eb8 <namex+0xa4>
    memmove(name, s, len);
    80003f50:	2601                	sext.w	a2,a2
    80003f52:	85a6                	mv	a1,s1
    80003f54:	8556                	mv	a0,s5
    80003f56:	ffffd097          	auipc	ra,0xffffd
    80003f5a:	dd8080e7          	jalr	-552(ra) # 80000d2e <memmove>
    name[len] = 0;
    80003f5e:	9d56                	add	s10,s10,s5
    80003f60:	000d0023          	sb	zero,0(s10)
    80003f64:	84ce                	mv	s1,s3
    80003f66:	b7bd                	j	80003ed4 <namex+0xc0>
  if(nameiparent){
    80003f68:	f00b0ce3          	beqz	s6,80003e80 <namex+0x6c>
    iput(ip);
    80003f6c:	8552                	mv	a0,s4
    80003f6e:	00000097          	auipc	ra,0x0
    80003f72:	acc080e7          	jalr	-1332(ra) # 80003a3a <iput>
    return 0;
    80003f76:	4a01                	li	s4,0
    80003f78:	b721                	j	80003e80 <namex+0x6c>

0000000080003f7a <dirlink>:
{
    80003f7a:	7139                	addi	sp,sp,-64
    80003f7c:	fc06                	sd	ra,56(sp)
    80003f7e:	f822                	sd	s0,48(sp)
    80003f80:	f426                	sd	s1,40(sp)
    80003f82:	f04a                	sd	s2,32(sp)
    80003f84:	ec4e                	sd	s3,24(sp)
    80003f86:	e852                	sd	s4,16(sp)
    80003f88:	0080                	addi	s0,sp,64
    80003f8a:	892a                	mv	s2,a0
    80003f8c:	8a2e                	mv	s4,a1
    80003f8e:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003f90:	4601                	li	a2,0
    80003f92:	00000097          	auipc	ra,0x0
    80003f96:	dd2080e7          	jalr	-558(ra) # 80003d64 <dirlookup>
    80003f9a:	e93d                	bnez	a0,80004010 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f9c:	04c92483          	lw	s1,76(s2)
    80003fa0:	c49d                	beqz	s1,80003fce <dirlink+0x54>
    80003fa2:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fa4:	4741                	li	a4,16
    80003fa6:	86a6                	mv	a3,s1
    80003fa8:	fc040613          	addi	a2,s0,-64
    80003fac:	4581                	li	a1,0
    80003fae:	854a                	mv	a0,s2
    80003fb0:	00000097          	auipc	ra,0x0
    80003fb4:	b84080e7          	jalr	-1148(ra) # 80003b34 <readi>
    80003fb8:	47c1                	li	a5,16
    80003fba:	06f51163          	bne	a0,a5,8000401c <dirlink+0xa2>
    if(de.inum == 0)
    80003fbe:	fc045783          	lhu	a5,-64(s0)
    80003fc2:	c791                	beqz	a5,80003fce <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fc4:	24c1                	addiw	s1,s1,16
    80003fc6:	04c92783          	lw	a5,76(s2)
    80003fca:	fcf4ede3          	bltu	s1,a5,80003fa4 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003fce:	4639                	li	a2,14
    80003fd0:	85d2                	mv	a1,s4
    80003fd2:	fc240513          	addi	a0,s0,-62
    80003fd6:	ffffd097          	auipc	ra,0xffffd
    80003fda:	e08080e7          	jalr	-504(ra) # 80000dde <strncpy>
  de.inum = inum;
    80003fde:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fe2:	4741                	li	a4,16
    80003fe4:	86a6                	mv	a3,s1
    80003fe6:	fc040613          	addi	a2,s0,-64
    80003fea:	4581                	li	a1,0
    80003fec:	854a                	mv	a0,s2
    80003fee:	00000097          	auipc	ra,0x0
    80003ff2:	c3e080e7          	jalr	-962(ra) # 80003c2c <writei>
    80003ff6:	1541                	addi	a0,a0,-16
    80003ff8:	00a03533          	snez	a0,a0
    80003ffc:	40a00533          	neg	a0,a0
}
    80004000:	70e2                	ld	ra,56(sp)
    80004002:	7442                	ld	s0,48(sp)
    80004004:	74a2                	ld	s1,40(sp)
    80004006:	7902                	ld	s2,32(sp)
    80004008:	69e2                	ld	s3,24(sp)
    8000400a:	6a42                	ld	s4,16(sp)
    8000400c:	6121                	addi	sp,sp,64
    8000400e:	8082                	ret
    iput(ip);
    80004010:	00000097          	auipc	ra,0x0
    80004014:	a2a080e7          	jalr	-1494(ra) # 80003a3a <iput>
    return -1;
    80004018:	557d                	li	a0,-1
    8000401a:	b7dd                	j	80004000 <dirlink+0x86>
      panic("dirlink read");
    8000401c:	00004517          	auipc	a0,0x4
    80004020:	7fc50513          	addi	a0,a0,2044 # 80008818 <syscalls+0x1f8>
    80004024:	ffffc097          	auipc	ra,0xffffc
    80004028:	51c080e7          	jalr	1308(ra) # 80000540 <panic>

000000008000402c <namei>:

struct inode*
namei(char *path)
{
    8000402c:	1101                	addi	sp,sp,-32
    8000402e:	ec06                	sd	ra,24(sp)
    80004030:	e822                	sd	s0,16(sp)
    80004032:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004034:	fe040613          	addi	a2,s0,-32
    80004038:	4581                	li	a1,0
    8000403a:	00000097          	auipc	ra,0x0
    8000403e:	dda080e7          	jalr	-550(ra) # 80003e14 <namex>
}
    80004042:	60e2                	ld	ra,24(sp)
    80004044:	6442                	ld	s0,16(sp)
    80004046:	6105                	addi	sp,sp,32
    80004048:	8082                	ret

000000008000404a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000404a:	1141                	addi	sp,sp,-16
    8000404c:	e406                	sd	ra,8(sp)
    8000404e:	e022                	sd	s0,0(sp)
    80004050:	0800                	addi	s0,sp,16
    80004052:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004054:	4585                	li	a1,1
    80004056:	00000097          	auipc	ra,0x0
    8000405a:	dbe080e7          	jalr	-578(ra) # 80003e14 <namex>
}
    8000405e:	60a2                	ld	ra,8(sp)
    80004060:	6402                	ld	s0,0(sp)
    80004062:	0141                	addi	sp,sp,16
    80004064:	8082                	ret

0000000080004066 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004066:	1101                	addi	sp,sp,-32
    80004068:	ec06                	sd	ra,24(sp)
    8000406a:	e822                	sd	s0,16(sp)
    8000406c:	e426                	sd	s1,8(sp)
    8000406e:	e04a                	sd	s2,0(sp)
    80004070:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004072:	00025917          	auipc	s2,0x25
    80004076:	fe690913          	addi	s2,s2,-26 # 80029058 <log>
    8000407a:	01892583          	lw	a1,24(s2)
    8000407e:	02892503          	lw	a0,40(s2)
    80004082:	fffff097          	auipc	ra,0xfffff
    80004086:	fe6080e7          	jalr	-26(ra) # 80003068 <bread>
    8000408a:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000408c:	02c92683          	lw	a3,44(s2)
    80004090:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004092:	02d05863          	blez	a3,800040c2 <write_head+0x5c>
    80004096:	00025797          	auipc	a5,0x25
    8000409a:	ff278793          	addi	a5,a5,-14 # 80029088 <log+0x30>
    8000409e:	05c50713          	addi	a4,a0,92
    800040a2:	36fd                	addiw	a3,a3,-1
    800040a4:	02069613          	slli	a2,a3,0x20
    800040a8:	01e65693          	srli	a3,a2,0x1e
    800040ac:	00025617          	auipc	a2,0x25
    800040b0:	fe060613          	addi	a2,a2,-32 # 8002908c <log+0x34>
    800040b4:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800040b6:	4390                	lw	a2,0(a5)
    800040b8:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800040ba:	0791                	addi	a5,a5,4
    800040bc:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    800040be:	fed79ce3          	bne	a5,a3,800040b6 <write_head+0x50>
  }
  bwrite(buf);
    800040c2:	8526                	mv	a0,s1
    800040c4:	fffff097          	auipc	ra,0xfffff
    800040c8:	096080e7          	jalr	150(ra) # 8000315a <bwrite>
  brelse(buf);
    800040cc:	8526                	mv	a0,s1
    800040ce:	fffff097          	auipc	ra,0xfffff
    800040d2:	0ca080e7          	jalr	202(ra) # 80003198 <brelse>
}
    800040d6:	60e2                	ld	ra,24(sp)
    800040d8:	6442                	ld	s0,16(sp)
    800040da:	64a2                	ld	s1,8(sp)
    800040dc:	6902                	ld	s2,0(sp)
    800040de:	6105                	addi	sp,sp,32
    800040e0:	8082                	ret

00000000800040e2 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800040e2:	00025797          	auipc	a5,0x25
    800040e6:	fa27a783          	lw	a5,-94(a5) # 80029084 <log+0x2c>
    800040ea:	0af05d63          	blez	a5,800041a4 <install_trans+0xc2>
{
    800040ee:	7139                	addi	sp,sp,-64
    800040f0:	fc06                	sd	ra,56(sp)
    800040f2:	f822                	sd	s0,48(sp)
    800040f4:	f426                	sd	s1,40(sp)
    800040f6:	f04a                	sd	s2,32(sp)
    800040f8:	ec4e                	sd	s3,24(sp)
    800040fa:	e852                	sd	s4,16(sp)
    800040fc:	e456                	sd	s5,8(sp)
    800040fe:	e05a                	sd	s6,0(sp)
    80004100:	0080                	addi	s0,sp,64
    80004102:	8b2a                	mv	s6,a0
    80004104:	00025a97          	auipc	s5,0x25
    80004108:	f84a8a93          	addi	s5,s5,-124 # 80029088 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000410c:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000410e:	00025997          	auipc	s3,0x25
    80004112:	f4a98993          	addi	s3,s3,-182 # 80029058 <log>
    80004116:	a00d                	j	80004138 <install_trans+0x56>
    brelse(lbuf);
    80004118:	854a                	mv	a0,s2
    8000411a:	fffff097          	auipc	ra,0xfffff
    8000411e:	07e080e7          	jalr	126(ra) # 80003198 <brelse>
    brelse(dbuf);
    80004122:	8526                	mv	a0,s1
    80004124:	fffff097          	auipc	ra,0xfffff
    80004128:	074080e7          	jalr	116(ra) # 80003198 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000412c:	2a05                	addiw	s4,s4,1
    8000412e:	0a91                	addi	s5,s5,4
    80004130:	02c9a783          	lw	a5,44(s3)
    80004134:	04fa5e63          	bge	s4,a5,80004190 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004138:	0189a583          	lw	a1,24(s3)
    8000413c:	014585bb          	addw	a1,a1,s4
    80004140:	2585                	addiw	a1,a1,1
    80004142:	0289a503          	lw	a0,40(s3)
    80004146:	fffff097          	auipc	ra,0xfffff
    8000414a:	f22080e7          	jalr	-222(ra) # 80003068 <bread>
    8000414e:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004150:	000aa583          	lw	a1,0(s5)
    80004154:	0289a503          	lw	a0,40(s3)
    80004158:	fffff097          	auipc	ra,0xfffff
    8000415c:	f10080e7          	jalr	-240(ra) # 80003068 <bread>
    80004160:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004162:	40000613          	li	a2,1024
    80004166:	05890593          	addi	a1,s2,88
    8000416a:	05850513          	addi	a0,a0,88
    8000416e:	ffffd097          	auipc	ra,0xffffd
    80004172:	bc0080e7          	jalr	-1088(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    80004176:	8526                	mv	a0,s1
    80004178:	fffff097          	auipc	ra,0xfffff
    8000417c:	fe2080e7          	jalr	-30(ra) # 8000315a <bwrite>
    if(recovering == 0)
    80004180:	f80b1ce3          	bnez	s6,80004118 <install_trans+0x36>
      bunpin(dbuf);
    80004184:	8526                	mv	a0,s1
    80004186:	fffff097          	auipc	ra,0xfffff
    8000418a:	0ec080e7          	jalr	236(ra) # 80003272 <bunpin>
    8000418e:	b769                	j	80004118 <install_trans+0x36>
}
    80004190:	70e2                	ld	ra,56(sp)
    80004192:	7442                	ld	s0,48(sp)
    80004194:	74a2                	ld	s1,40(sp)
    80004196:	7902                	ld	s2,32(sp)
    80004198:	69e2                	ld	s3,24(sp)
    8000419a:	6a42                	ld	s4,16(sp)
    8000419c:	6aa2                	ld	s5,8(sp)
    8000419e:	6b02                	ld	s6,0(sp)
    800041a0:	6121                	addi	sp,sp,64
    800041a2:	8082                	ret
    800041a4:	8082                	ret

00000000800041a6 <initlog>:
{
    800041a6:	7179                	addi	sp,sp,-48
    800041a8:	f406                	sd	ra,40(sp)
    800041aa:	f022                	sd	s0,32(sp)
    800041ac:	ec26                	sd	s1,24(sp)
    800041ae:	e84a                	sd	s2,16(sp)
    800041b0:	e44e                	sd	s3,8(sp)
    800041b2:	1800                	addi	s0,sp,48
    800041b4:	892a                	mv	s2,a0
    800041b6:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800041b8:	00025497          	auipc	s1,0x25
    800041bc:	ea048493          	addi	s1,s1,-352 # 80029058 <log>
    800041c0:	00004597          	auipc	a1,0x4
    800041c4:	66858593          	addi	a1,a1,1640 # 80008828 <syscalls+0x208>
    800041c8:	8526                	mv	a0,s1
    800041ca:	ffffd097          	auipc	ra,0xffffd
    800041ce:	97c080e7          	jalr	-1668(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    800041d2:	0149a583          	lw	a1,20(s3)
    800041d6:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800041d8:	0109a783          	lw	a5,16(s3)
    800041dc:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800041de:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800041e2:	854a                	mv	a0,s2
    800041e4:	fffff097          	auipc	ra,0xfffff
    800041e8:	e84080e7          	jalr	-380(ra) # 80003068 <bread>
  log.lh.n = lh->n;
    800041ec:	4d34                	lw	a3,88(a0)
    800041ee:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800041f0:	02d05663          	blez	a3,8000421c <initlog+0x76>
    800041f4:	05c50793          	addi	a5,a0,92
    800041f8:	00025717          	auipc	a4,0x25
    800041fc:	e9070713          	addi	a4,a4,-368 # 80029088 <log+0x30>
    80004200:	36fd                	addiw	a3,a3,-1
    80004202:	02069613          	slli	a2,a3,0x20
    80004206:	01e65693          	srli	a3,a2,0x1e
    8000420a:	06050613          	addi	a2,a0,96
    8000420e:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004210:	4390                	lw	a2,0(a5)
    80004212:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004214:	0791                	addi	a5,a5,4
    80004216:	0711                	addi	a4,a4,4
    80004218:	fed79ce3          	bne	a5,a3,80004210 <initlog+0x6a>
  brelse(buf);
    8000421c:	fffff097          	auipc	ra,0xfffff
    80004220:	f7c080e7          	jalr	-132(ra) # 80003198 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004224:	4505                	li	a0,1
    80004226:	00000097          	auipc	ra,0x0
    8000422a:	ebc080e7          	jalr	-324(ra) # 800040e2 <install_trans>
  log.lh.n = 0;
    8000422e:	00025797          	auipc	a5,0x25
    80004232:	e407ab23          	sw	zero,-426(a5) # 80029084 <log+0x2c>
  write_head(); // clear the log
    80004236:	00000097          	auipc	ra,0x0
    8000423a:	e30080e7          	jalr	-464(ra) # 80004066 <write_head>
}
    8000423e:	70a2                	ld	ra,40(sp)
    80004240:	7402                	ld	s0,32(sp)
    80004242:	64e2                	ld	s1,24(sp)
    80004244:	6942                	ld	s2,16(sp)
    80004246:	69a2                	ld	s3,8(sp)
    80004248:	6145                	addi	sp,sp,48
    8000424a:	8082                	ret

000000008000424c <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000424c:	1101                	addi	sp,sp,-32
    8000424e:	ec06                	sd	ra,24(sp)
    80004250:	e822                	sd	s0,16(sp)
    80004252:	e426                	sd	s1,8(sp)
    80004254:	e04a                	sd	s2,0(sp)
    80004256:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004258:	00025517          	auipc	a0,0x25
    8000425c:	e0050513          	addi	a0,a0,-512 # 80029058 <log>
    80004260:	ffffd097          	auipc	ra,0xffffd
    80004264:	976080e7          	jalr	-1674(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    80004268:	00025497          	auipc	s1,0x25
    8000426c:	df048493          	addi	s1,s1,-528 # 80029058 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004270:	4979                	li	s2,30
    80004272:	a039                	j	80004280 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004274:	85a6                	mv	a1,s1
    80004276:	8526                	mv	a0,s1
    80004278:	ffffe097          	auipc	ra,0xffffe
    8000427c:	e8c080e7          	jalr	-372(ra) # 80002104 <sleep>
    if(log.committing){
    80004280:	50dc                	lw	a5,36(s1)
    80004282:	fbed                	bnez	a5,80004274 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004284:	5098                	lw	a4,32(s1)
    80004286:	2705                	addiw	a4,a4,1
    80004288:	0007069b          	sext.w	a3,a4
    8000428c:	0027179b          	slliw	a5,a4,0x2
    80004290:	9fb9                	addw	a5,a5,a4
    80004292:	0017979b          	slliw	a5,a5,0x1
    80004296:	54d8                	lw	a4,44(s1)
    80004298:	9fb9                	addw	a5,a5,a4
    8000429a:	00f95963          	bge	s2,a5,800042ac <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000429e:	85a6                	mv	a1,s1
    800042a0:	8526                	mv	a0,s1
    800042a2:	ffffe097          	auipc	ra,0xffffe
    800042a6:	e62080e7          	jalr	-414(ra) # 80002104 <sleep>
    800042aa:	bfd9                	j	80004280 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800042ac:	00025517          	auipc	a0,0x25
    800042b0:	dac50513          	addi	a0,a0,-596 # 80029058 <log>
    800042b4:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800042b6:	ffffd097          	auipc	ra,0xffffd
    800042ba:	9d4080e7          	jalr	-1580(ra) # 80000c8a <release>
      break;
    }
  }
}
    800042be:	60e2                	ld	ra,24(sp)
    800042c0:	6442                	ld	s0,16(sp)
    800042c2:	64a2                	ld	s1,8(sp)
    800042c4:	6902                	ld	s2,0(sp)
    800042c6:	6105                	addi	sp,sp,32
    800042c8:	8082                	ret

00000000800042ca <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800042ca:	7139                	addi	sp,sp,-64
    800042cc:	fc06                	sd	ra,56(sp)
    800042ce:	f822                	sd	s0,48(sp)
    800042d0:	f426                	sd	s1,40(sp)
    800042d2:	f04a                	sd	s2,32(sp)
    800042d4:	ec4e                	sd	s3,24(sp)
    800042d6:	e852                	sd	s4,16(sp)
    800042d8:	e456                	sd	s5,8(sp)
    800042da:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800042dc:	00025497          	auipc	s1,0x25
    800042e0:	d7c48493          	addi	s1,s1,-644 # 80029058 <log>
    800042e4:	8526                	mv	a0,s1
    800042e6:	ffffd097          	auipc	ra,0xffffd
    800042ea:	8f0080e7          	jalr	-1808(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    800042ee:	509c                	lw	a5,32(s1)
    800042f0:	37fd                	addiw	a5,a5,-1
    800042f2:	0007891b          	sext.w	s2,a5
    800042f6:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800042f8:	50dc                	lw	a5,36(s1)
    800042fa:	e7b9                	bnez	a5,80004348 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800042fc:	04091e63          	bnez	s2,80004358 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004300:	00025497          	auipc	s1,0x25
    80004304:	d5848493          	addi	s1,s1,-680 # 80029058 <log>
    80004308:	4785                	li	a5,1
    8000430a:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000430c:	8526                	mv	a0,s1
    8000430e:	ffffd097          	auipc	ra,0xffffd
    80004312:	97c080e7          	jalr	-1668(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004316:	54dc                	lw	a5,44(s1)
    80004318:	06f04763          	bgtz	a5,80004386 <end_op+0xbc>
    acquire(&log.lock);
    8000431c:	00025497          	auipc	s1,0x25
    80004320:	d3c48493          	addi	s1,s1,-708 # 80029058 <log>
    80004324:	8526                	mv	a0,s1
    80004326:	ffffd097          	auipc	ra,0xffffd
    8000432a:	8b0080e7          	jalr	-1872(ra) # 80000bd6 <acquire>
    log.committing = 0;
    8000432e:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004332:	8526                	mv	a0,s1
    80004334:	ffffe097          	auipc	ra,0xffffe
    80004338:	e34080e7          	jalr	-460(ra) # 80002168 <wakeup>
    release(&log.lock);
    8000433c:	8526                	mv	a0,s1
    8000433e:	ffffd097          	auipc	ra,0xffffd
    80004342:	94c080e7          	jalr	-1716(ra) # 80000c8a <release>
}
    80004346:	a03d                	j	80004374 <end_op+0xaa>
    panic("log.committing");
    80004348:	00004517          	auipc	a0,0x4
    8000434c:	4e850513          	addi	a0,a0,1256 # 80008830 <syscalls+0x210>
    80004350:	ffffc097          	auipc	ra,0xffffc
    80004354:	1f0080e7          	jalr	496(ra) # 80000540 <panic>
    wakeup(&log);
    80004358:	00025497          	auipc	s1,0x25
    8000435c:	d0048493          	addi	s1,s1,-768 # 80029058 <log>
    80004360:	8526                	mv	a0,s1
    80004362:	ffffe097          	auipc	ra,0xffffe
    80004366:	e06080e7          	jalr	-506(ra) # 80002168 <wakeup>
  release(&log.lock);
    8000436a:	8526                	mv	a0,s1
    8000436c:	ffffd097          	auipc	ra,0xffffd
    80004370:	91e080e7          	jalr	-1762(ra) # 80000c8a <release>
}
    80004374:	70e2                	ld	ra,56(sp)
    80004376:	7442                	ld	s0,48(sp)
    80004378:	74a2                	ld	s1,40(sp)
    8000437a:	7902                	ld	s2,32(sp)
    8000437c:	69e2                	ld	s3,24(sp)
    8000437e:	6a42                	ld	s4,16(sp)
    80004380:	6aa2                	ld	s5,8(sp)
    80004382:	6121                	addi	sp,sp,64
    80004384:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004386:	00025a97          	auipc	s5,0x25
    8000438a:	d02a8a93          	addi	s5,s5,-766 # 80029088 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000438e:	00025a17          	auipc	s4,0x25
    80004392:	ccaa0a13          	addi	s4,s4,-822 # 80029058 <log>
    80004396:	018a2583          	lw	a1,24(s4)
    8000439a:	012585bb          	addw	a1,a1,s2
    8000439e:	2585                	addiw	a1,a1,1
    800043a0:	028a2503          	lw	a0,40(s4)
    800043a4:	fffff097          	auipc	ra,0xfffff
    800043a8:	cc4080e7          	jalr	-828(ra) # 80003068 <bread>
    800043ac:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800043ae:	000aa583          	lw	a1,0(s5)
    800043b2:	028a2503          	lw	a0,40(s4)
    800043b6:	fffff097          	auipc	ra,0xfffff
    800043ba:	cb2080e7          	jalr	-846(ra) # 80003068 <bread>
    800043be:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800043c0:	40000613          	li	a2,1024
    800043c4:	05850593          	addi	a1,a0,88
    800043c8:	05848513          	addi	a0,s1,88
    800043cc:	ffffd097          	auipc	ra,0xffffd
    800043d0:	962080e7          	jalr	-1694(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    800043d4:	8526                	mv	a0,s1
    800043d6:	fffff097          	auipc	ra,0xfffff
    800043da:	d84080e7          	jalr	-636(ra) # 8000315a <bwrite>
    brelse(from);
    800043de:	854e                	mv	a0,s3
    800043e0:	fffff097          	auipc	ra,0xfffff
    800043e4:	db8080e7          	jalr	-584(ra) # 80003198 <brelse>
    brelse(to);
    800043e8:	8526                	mv	a0,s1
    800043ea:	fffff097          	auipc	ra,0xfffff
    800043ee:	dae080e7          	jalr	-594(ra) # 80003198 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043f2:	2905                	addiw	s2,s2,1
    800043f4:	0a91                	addi	s5,s5,4
    800043f6:	02ca2783          	lw	a5,44(s4)
    800043fa:	f8f94ee3          	blt	s2,a5,80004396 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800043fe:	00000097          	auipc	ra,0x0
    80004402:	c68080e7          	jalr	-920(ra) # 80004066 <write_head>
    install_trans(0); // Now install writes to home locations
    80004406:	4501                	li	a0,0
    80004408:	00000097          	auipc	ra,0x0
    8000440c:	cda080e7          	jalr	-806(ra) # 800040e2 <install_trans>
    log.lh.n = 0;
    80004410:	00025797          	auipc	a5,0x25
    80004414:	c607aa23          	sw	zero,-908(a5) # 80029084 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004418:	00000097          	auipc	ra,0x0
    8000441c:	c4e080e7          	jalr	-946(ra) # 80004066 <write_head>
    80004420:	bdf5                	j	8000431c <end_op+0x52>

0000000080004422 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004422:	1101                	addi	sp,sp,-32
    80004424:	ec06                	sd	ra,24(sp)
    80004426:	e822                	sd	s0,16(sp)
    80004428:	e426                	sd	s1,8(sp)
    8000442a:	e04a                	sd	s2,0(sp)
    8000442c:	1000                	addi	s0,sp,32
    8000442e:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004430:	00025917          	auipc	s2,0x25
    80004434:	c2890913          	addi	s2,s2,-984 # 80029058 <log>
    80004438:	854a                	mv	a0,s2
    8000443a:	ffffc097          	auipc	ra,0xffffc
    8000443e:	79c080e7          	jalr	1948(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004442:	02c92603          	lw	a2,44(s2)
    80004446:	47f5                	li	a5,29
    80004448:	06c7c563          	blt	a5,a2,800044b2 <log_write+0x90>
    8000444c:	00025797          	auipc	a5,0x25
    80004450:	c287a783          	lw	a5,-984(a5) # 80029074 <log+0x1c>
    80004454:	37fd                	addiw	a5,a5,-1
    80004456:	04f65e63          	bge	a2,a5,800044b2 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000445a:	00025797          	auipc	a5,0x25
    8000445e:	c1e7a783          	lw	a5,-994(a5) # 80029078 <log+0x20>
    80004462:	06f05063          	blez	a5,800044c2 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004466:	4781                	li	a5,0
    80004468:	06c05563          	blez	a2,800044d2 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000446c:	44cc                	lw	a1,12(s1)
    8000446e:	00025717          	auipc	a4,0x25
    80004472:	c1a70713          	addi	a4,a4,-998 # 80029088 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004476:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004478:	4314                	lw	a3,0(a4)
    8000447a:	04b68c63          	beq	a3,a1,800044d2 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000447e:	2785                	addiw	a5,a5,1
    80004480:	0711                	addi	a4,a4,4
    80004482:	fef61be3          	bne	a2,a5,80004478 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004486:	0621                	addi	a2,a2,8
    80004488:	060a                	slli	a2,a2,0x2
    8000448a:	00025797          	auipc	a5,0x25
    8000448e:	bce78793          	addi	a5,a5,-1074 # 80029058 <log>
    80004492:	97b2                	add	a5,a5,a2
    80004494:	44d8                	lw	a4,12(s1)
    80004496:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004498:	8526                	mv	a0,s1
    8000449a:	fffff097          	auipc	ra,0xfffff
    8000449e:	d9c080e7          	jalr	-612(ra) # 80003236 <bpin>
    log.lh.n++;
    800044a2:	00025717          	auipc	a4,0x25
    800044a6:	bb670713          	addi	a4,a4,-1098 # 80029058 <log>
    800044aa:	575c                	lw	a5,44(a4)
    800044ac:	2785                	addiw	a5,a5,1
    800044ae:	d75c                	sw	a5,44(a4)
    800044b0:	a82d                	j	800044ea <log_write+0xc8>
    panic("too big a transaction");
    800044b2:	00004517          	auipc	a0,0x4
    800044b6:	38e50513          	addi	a0,a0,910 # 80008840 <syscalls+0x220>
    800044ba:	ffffc097          	auipc	ra,0xffffc
    800044be:	086080e7          	jalr	134(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    800044c2:	00004517          	auipc	a0,0x4
    800044c6:	39650513          	addi	a0,a0,918 # 80008858 <syscalls+0x238>
    800044ca:	ffffc097          	auipc	ra,0xffffc
    800044ce:	076080e7          	jalr	118(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    800044d2:	00878693          	addi	a3,a5,8
    800044d6:	068a                	slli	a3,a3,0x2
    800044d8:	00025717          	auipc	a4,0x25
    800044dc:	b8070713          	addi	a4,a4,-1152 # 80029058 <log>
    800044e0:	9736                	add	a4,a4,a3
    800044e2:	44d4                	lw	a3,12(s1)
    800044e4:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800044e6:	faf609e3          	beq	a2,a5,80004498 <log_write+0x76>
  }
  release(&log.lock);
    800044ea:	00025517          	auipc	a0,0x25
    800044ee:	b6e50513          	addi	a0,a0,-1170 # 80029058 <log>
    800044f2:	ffffc097          	auipc	ra,0xffffc
    800044f6:	798080e7          	jalr	1944(ra) # 80000c8a <release>
}
    800044fa:	60e2                	ld	ra,24(sp)
    800044fc:	6442                	ld	s0,16(sp)
    800044fe:	64a2                	ld	s1,8(sp)
    80004500:	6902                	ld	s2,0(sp)
    80004502:	6105                	addi	sp,sp,32
    80004504:	8082                	ret

0000000080004506 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004506:	1101                	addi	sp,sp,-32
    80004508:	ec06                	sd	ra,24(sp)
    8000450a:	e822                	sd	s0,16(sp)
    8000450c:	e426                	sd	s1,8(sp)
    8000450e:	e04a                	sd	s2,0(sp)
    80004510:	1000                	addi	s0,sp,32
    80004512:	84aa                	mv	s1,a0
    80004514:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004516:	00004597          	auipc	a1,0x4
    8000451a:	36258593          	addi	a1,a1,866 # 80008878 <syscalls+0x258>
    8000451e:	0521                	addi	a0,a0,8
    80004520:	ffffc097          	auipc	ra,0xffffc
    80004524:	626080e7          	jalr	1574(ra) # 80000b46 <initlock>
  lk->name = name;
    80004528:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000452c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004530:	0204a423          	sw	zero,40(s1)
}
    80004534:	60e2                	ld	ra,24(sp)
    80004536:	6442                	ld	s0,16(sp)
    80004538:	64a2                	ld	s1,8(sp)
    8000453a:	6902                	ld	s2,0(sp)
    8000453c:	6105                	addi	sp,sp,32
    8000453e:	8082                	ret

0000000080004540 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004540:	1101                	addi	sp,sp,-32
    80004542:	ec06                	sd	ra,24(sp)
    80004544:	e822                	sd	s0,16(sp)
    80004546:	e426                	sd	s1,8(sp)
    80004548:	e04a                	sd	s2,0(sp)
    8000454a:	1000                	addi	s0,sp,32
    8000454c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000454e:	00850913          	addi	s2,a0,8
    80004552:	854a                	mv	a0,s2
    80004554:	ffffc097          	auipc	ra,0xffffc
    80004558:	682080e7          	jalr	1666(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    8000455c:	409c                	lw	a5,0(s1)
    8000455e:	cb89                	beqz	a5,80004570 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004560:	85ca                	mv	a1,s2
    80004562:	8526                	mv	a0,s1
    80004564:	ffffe097          	auipc	ra,0xffffe
    80004568:	ba0080e7          	jalr	-1120(ra) # 80002104 <sleep>
  while (lk->locked) {
    8000456c:	409c                	lw	a5,0(s1)
    8000456e:	fbed                	bnez	a5,80004560 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004570:	4785                	li	a5,1
    80004572:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004574:	ffffd097          	auipc	ra,0xffffd
    80004578:	438080e7          	jalr	1080(ra) # 800019ac <myproc>
    8000457c:	591c                	lw	a5,48(a0)
    8000457e:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004580:	854a                	mv	a0,s2
    80004582:	ffffc097          	auipc	ra,0xffffc
    80004586:	708080e7          	jalr	1800(ra) # 80000c8a <release>
}
    8000458a:	60e2                	ld	ra,24(sp)
    8000458c:	6442                	ld	s0,16(sp)
    8000458e:	64a2                	ld	s1,8(sp)
    80004590:	6902                	ld	s2,0(sp)
    80004592:	6105                	addi	sp,sp,32
    80004594:	8082                	ret

0000000080004596 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004596:	1101                	addi	sp,sp,-32
    80004598:	ec06                	sd	ra,24(sp)
    8000459a:	e822                	sd	s0,16(sp)
    8000459c:	e426                	sd	s1,8(sp)
    8000459e:	e04a                	sd	s2,0(sp)
    800045a0:	1000                	addi	s0,sp,32
    800045a2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045a4:	00850913          	addi	s2,a0,8
    800045a8:	854a                	mv	a0,s2
    800045aa:	ffffc097          	auipc	ra,0xffffc
    800045ae:	62c080e7          	jalr	1580(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    800045b2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800045b6:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800045ba:	8526                	mv	a0,s1
    800045bc:	ffffe097          	auipc	ra,0xffffe
    800045c0:	bac080e7          	jalr	-1108(ra) # 80002168 <wakeup>
  release(&lk->lk);
    800045c4:	854a                	mv	a0,s2
    800045c6:	ffffc097          	auipc	ra,0xffffc
    800045ca:	6c4080e7          	jalr	1732(ra) # 80000c8a <release>
}
    800045ce:	60e2                	ld	ra,24(sp)
    800045d0:	6442                	ld	s0,16(sp)
    800045d2:	64a2                	ld	s1,8(sp)
    800045d4:	6902                	ld	s2,0(sp)
    800045d6:	6105                	addi	sp,sp,32
    800045d8:	8082                	ret

00000000800045da <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800045da:	7179                	addi	sp,sp,-48
    800045dc:	f406                	sd	ra,40(sp)
    800045de:	f022                	sd	s0,32(sp)
    800045e0:	ec26                	sd	s1,24(sp)
    800045e2:	e84a                	sd	s2,16(sp)
    800045e4:	e44e                	sd	s3,8(sp)
    800045e6:	1800                	addi	s0,sp,48
    800045e8:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800045ea:	00850913          	addi	s2,a0,8
    800045ee:	854a                	mv	a0,s2
    800045f0:	ffffc097          	auipc	ra,0xffffc
    800045f4:	5e6080e7          	jalr	1510(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800045f8:	409c                	lw	a5,0(s1)
    800045fa:	ef99                	bnez	a5,80004618 <holdingsleep+0x3e>
    800045fc:	4481                	li	s1,0
  release(&lk->lk);
    800045fe:	854a                	mv	a0,s2
    80004600:	ffffc097          	auipc	ra,0xffffc
    80004604:	68a080e7          	jalr	1674(ra) # 80000c8a <release>
  return r;
}
    80004608:	8526                	mv	a0,s1
    8000460a:	70a2                	ld	ra,40(sp)
    8000460c:	7402                	ld	s0,32(sp)
    8000460e:	64e2                	ld	s1,24(sp)
    80004610:	6942                	ld	s2,16(sp)
    80004612:	69a2                	ld	s3,8(sp)
    80004614:	6145                	addi	sp,sp,48
    80004616:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004618:	0284a983          	lw	s3,40(s1)
    8000461c:	ffffd097          	auipc	ra,0xffffd
    80004620:	390080e7          	jalr	912(ra) # 800019ac <myproc>
    80004624:	5904                	lw	s1,48(a0)
    80004626:	413484b3          	sub	s1,s1,s3
    8000462a:	0014b493          	seqz	s1,s1
    8000462e:	bfc1                	j	800045fe <holdingsleep+0x24>

0000000080004630 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004630:	1141                	addi	sp,sp,-16
    80004632:	e406                	sd	ra,8(sp)
    80004634:	e022                	sd	s0,0(sp)
    80004636:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004638:	00004597          	auipc	a1,0x4
    8000463c:	25058593          	addi	a1,a1,592 # 80008888 <syscalls+0x268>
    80004640:	00025517          	auipc	a0,0x25
    80004644:	b6050513          	addi	a0,a0,-1184 # 800291a0 <ftable>
    80004648:	ffffc097          	auipc	ra,0xffffc
    8000464c:	4fe080e7          	jalr	1278(ra) # 80000b46 <initlock>
}
    80004650:	60a2                	ld	ra,8(sp)
    80004652:	6402                	ld	s0,0(sp)
    80004654:	0141                	addi	sp,sp,16
    80004656:	8082                	ret

0000000080004658 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004658:	1101                	addi	sp,sp,-32
    8000465a:	ec06                	sd	ra,24(sp)
    8000465c:	e822                	sd	s0,16(sp)
    8000465e:	e426                	sd	s1,8(sp)
    80004660:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004662:	00025517          	auipc	a0,0x25
    80004666:	b3e50513          	addi	a0,a0,-1218 # 800291a0 <ftable>
    8000466a:	ffffc097          	auipc	ra,0xffffc
    8000466e:	56c080e7          	jalr	1388(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004672:	00025497          	auipc	s1,0x25
    80004676:	b4648493          	addi	s1,s1,-1210 # 800291b8 <ftable+0x18>
    8000467a:	00026717          	auipc	a4,0x26
    8000467e:	ade70713          	addi	a4,a4,-1314 # 8002a158 <disk>
    if(f->ref == 0){
    80004682:	40dc                	lw	a5,4(s1)
    80004684:	cf99                	beqz	a5,800046a2 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004686:	02848493          	addi	s1,s1,40
    8000468a:	fee49ce3          	bne	s1,a4,80004682 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000468e:	00025517          	auipc	a0,0x25
    80004692:	b1250513          	addi	a0,a0,-1262 # 800291a0 <ftable>
    80004696:	ffffc097          	auipc	ra,0xffffc
    8000469a:	5f4080e7          	jalr	1524(ra) # 80000c8a <release>
  return 0;
    8000469e:	4481                	li	s1,0
    800046a0:	a819                	j	800046b6 <filealloc+0x5e>
      f->ref = 1;
    800046a2:	4785                	li	a5,1
    800046a4:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800046a6:	00025517          	auipc	a0,0x25
    800046aa:	afa50513          	addi	a0,a0,-1286 # 800291a0 <ftable>
    800046ae:	ffffc097          	auipc	ra,0xffffc
    800046b2:	5dc080e7          	jalr	1500(ra) # 80000c8a <release>
}
    800046b6:	8526                	mv	a0,s1
    800046b8:	60e2                	ld	ra,24(sp)
    800046ba:	6442                	ld	s0,16(sp)
    800046bc:	64a2                	ld	s1,8(sp)
    800046be:	6105                	addi	sp,sp,32
    800046c0:	8082                	ret

00000000800046c2 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800046c2:	1101                	addi	sp,sp,-32
    800046c4:	ec06                	sd	ra,24(sp)
    800046c6:	e822                	sd	s0,16(sp)
    800046c8:	e426                	sd	s1,8(sp)
    800046ca:	1000                	addi	s0,sp,32
    800046cc:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800046ce:	00025517          	auipc	a0,0x25
    800046d2:	ad250513          	addi	a0,a0,-1326 # 800291a0 <ftable>
    800046d6:	ffffc097          	auipc	ra,0xffffc
    800046da:	500080e7          	jalr	1280(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    800046de:	40dc                	lw	a5,4(s1)
    800046e0:	02f05263          	blez	a5,80004704 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800046e4:	2785                	addiw	a5,a5,1
    800046e6:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800046e8:	00025517          	auipc	a0,0x25
    800046ec:	ab850513          	addi	a0,a0,-1352 # 800291a0 <ftable>
    800046f0:	ffffc097          	auipc	ra,0xffffc
    800046f4:	59a080e7          	jalr	1434(ra) # 80000c8a <release>
  return f;
}
    800046f8:	8526                	mv	a0,s1
    800046fa:	60e2                	ld	ra,24(sp)
    800046fc:	6442                	ld	s0,16(sp)
    800046fe:	64a2                	ld	s1,8(sp)
    80004700:	6105                	addi	sp,sp,32
    80004702:	8082                	ret
    panic("filedup");
    80004704:	00004517          	auipc	a0,0x4
    80004708:	18c50513          	addi	a0,a0,396 # 80008890 <syscalls+0x270>
    8000470c:	ffffc097          	auipc	ra,0xffffc
    80004710:	e34080e7          	jalr	-460(ra) # 80000540 <panic>

0000000080004714 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004714:	7139                	addi	sp,sp,-64
    80004716:	fc06                	sd	ra,56(sp)
    80004718:	f822                	sd	s0,48(sp)
    8000471a:	f426                	sd	s1,40(sp)
    8000471c:	f04a                	sd	s2,32(sp)
    8000471e:	ec4e                	sd	s3,24(sp)
    80004720:	e852                	sd	s4,16(sp)
    80004722:	e456                	sd	s5,8(sp)
    80004724:	0080                	addi	s0,sp,64
    80004726:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004728:	00025517          	auipc	a0,0x25
    8000472c:	a7850513          	addi	a0,a0,-1416 # 800291a0 <ftable>
    80004730:	ffffc097          	auipc	ra,0xffffc
    80004734:	4a6080e7          	jalr	1190(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004738:	40dc                	lw	a5,4(s1)
    8000473a:	06f05163          	blez	a5,8000479c <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000473e:	37fd                	addiw	a5,a5,-1
    80004740:	0007871b          	sext.w	a4,a5
    80004744:	c0dc                	sw	a5,4(s1)
    80004746:	06e04363          	bgtz	a4,800047ac <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000474a:	0004a903          	lw	s2,0(s1)
    8000474e:	0094ca83          	lbu	s5,9(s1)
    80004752:	0104ba03          	ld	s4,16(s1)
    80004756:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000475a:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000475e:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004762:	00025517          	auipc	a0,0x25
    80004766:	a3e50513          	addi	a0,a0,-1474 # 800291a0 <ftable>
    8000476a:	ffffc097          	auipc	ra,0xffffc
    8000476e:	520080e7          	jalr	1312(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    80004772:	4785                	li	a5,1
    80004774:	04f90d63          	beq	s2,a5,800047ce <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004778:	3979                	addiw	s2,s2,-2
    8000477a:	4785                	li	a5,1
    8000477c:	0527e063          	bltu	a5,s2,800047bc <fileclose+0xa8>
    begin_op();
    80004780:	00000097          	auipc	ra,0x0
    80004784:	acc080e7          	jalr	-1332(ra) # 8000424c <begin_op>
    iput(ff.ip);
    80004788:	854e                	mv	a0,s3
    8000478a:	fffff097          	auipc	ra,0xfffff
    8000478e:	2b0080e7          	jalr	688(ra) # 80003a3a <iput>
    end_op();
    80004792:	00000097          	auipc	ra,0x0
    80004796:	b38080e7          	jalr	-1224(ra) # 800042ca <end_op>
    8000479a:	a00d                	j	800047bc <fileclose+0xa8>
    panic("fileclose");
    8000479c:	00004517          	auipc	a0,0x4
    800047a0:	0fc50513          	addi	a0,a0,252 # 80008898 <syscalls+0x278>
    800047a4:	ffffc097          	auipc	ra,0xffffc
    800047a8:	d9c080e7          	jalr	-612(ra) # 80000540 <panic>
    release(&ftable.lock);
    800047ac:	00025517          	auipc	a0,0x25
    800047b0:	9f450513          	addi	a0,a0,-1548 # 800291a0 <ftable>
    800047b4:	ffffc097          	auipc	ra,0xffffc
    800047b8:	4d6080e7          	jalr	1238(ra) # 80000c8a <release>
  }
}
    800047bc:	70e2                	ld	ra,56(sp)
    800047be:	7442                	ld	s0,48(sp)
    800047c0:	74a2                	ld	s1,40(sp)
    800047c2:	7902                	ld	s2,32(sp)
    800047c4:	69e2                	ld	s3,24(sp)
    800047c6:	6a42                	ld	s4,16(sp)
    800047c8:	6aa2                	ld	s5,8(sp)
    800047ca:	6121                	addi	sp,sp,64
    800047cc:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800047ce:	85d6                	mv	a1,s5
    800047d0:	8552                	mv	a0,s4
    800047d2:	00000097          	auipc	ra,0x0
    800047d6:	34c080e7          	jalr	844(ra) # 80004b1e <pipeclose>
    800047da:	b7cd                	j	800047bc <fileclose+0xa8>

00000000800047dc <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800047dc:	715d                	addi	sp,sp,-80
    800047de:	e486                	sd	ra,72(sp)
    800047e0:	e0a2                	sd	s0,64(sp)
    800047e2:	fc26                	sd	s1,56(sp)
    800047e4:	f84a                	sd	s2,48(sp)
    800047e6:	f44e                	sd	s3,40(sp)
    800047e8:	0880                	addi	s0,sp,80
    800047ea:	84aa                	mv	s1,a0
    800047ec:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800047ee:	ffffd097          	auipc	ra,0xffffd
    800047f2:	1be080e7          	jalr	446(ra) # 800019ac <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800047f6:	409c                	lw	a5,0(s1)
    800047f8:	37f9                	addiw	a5,a5,-2
    800047fa:	4705                	li	a4,1
    800047fc:	04f76763          	bltu	a4,a5,8000484a <filestat+0x6e>
    80004800:	892a                	mv	s2,a0
    ilock(f->ip);
    80004802:	6c88                	ld	a0,24(s1)
    80004804:	fffff097          	auipc	ra,0xfffff
    80004808:	07c080e7          	jalr	124(ra) # 80003880 <ilock>
    stati(f->ip, &st);
    8000480c:	fb840593          	addi	a1,s0,-72
    80004810:	6c88                	ld	a0,24(s1)
    80004812:	fffff097          	auipc	ra,0xfffff
    80004816:	2f8080e7          	jalr	760(ra) # 80003b0a <stati>
    iunlock(f->ip);
    8000481a:	6c88                	ld	a0,24(s1)
    8000481c:	fffff097          	auipc	ra,0xfffff
    80004820:	126080e7          	jalr	294(ra) # 80003942 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004824:	46e1                	li	a3,24
    80004826:	fb840613          	addi	a2,s0,-72
    8000482a:	85ce                	mv	a1,s3
    8000482c:	05093503          	ld	a0,80(s2)
    80004830:	ffffd097          	auipc	ra,0xffffd
    80004834:	e3c080e7          	jalr	-452(ra) # 8000166c <copyout>
    80004838:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000483c:	60a6                	ld	ra,72(sp)
    8000483e:	6406                	ld	s0,64(sp)
    80004840:	74e2                	ld	s1,56(sp)
    80004842:	7942                	ld	s2,48(sp)
    80004844:	79a2                	ld	s3,40(sp)
    80004846:	6161                	addi	sp,sp,80
    80004848:	8082                	ret
  return -1;
    8000484a:	557d                	li	a0,-1
    8000484c:	bfc5                	j	8000483c <filestat+0x60>

000000008000484e <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000484e:	7179                	addi	sp,sp,-48
    80004850:	f406                	sd	ra,40(sp)
    80004852:	f022                	sd	s0,32(sp)
    80004854:	ec26                	sd	s1,24(sp)
    80004856:	e84a                	sd	s2,16(sp)
    80004858:	e44e                	sd	s3,8(sp)
    8000485a:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000485c:	00854783          	lbu	a5,8(a0)
    80004860:	c3d5                	beqz	a5,80004904 <fileread+0xb6>
    80004862:	84aa                	mv	s1,a0
    80004864:	89ae                	mv	s3,a1
    80004866:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004868:	411c                	lw	a5,0(a0)
    8000486a:	4705                	li	a4,1
    8000486c:	04e78963          	beq	a5,a4,800048be <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004870:	470d                	li	a4,3
    80004872:	04e78d63          	beq	a5,a4,800048cc <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004876:	4709                	li	a4,2
    80004878:	06e79e63          	bne	a5,a4,800048f4 <fileread+0xa6>
    ilock(f->ip);
    8000487c:	6d08                	ld	a0,24(a0)
    8000487e:	fffff097          	auipc	ra,0xfffff
    80004882:	002080e7          	jalr	2(ra) # 80003880 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004886:	874a                	mv	a4,s2
    80004888:	5094                	lw	a3,32(s1)
    8000488a:	864e                	mv	a2,s3
    8000488c:	4585                	li	a1,1
    8000488e:	6c88                	ld	a0,24(s1)
    80004890:	fffff097          	auipc	ra,0xfffff
    80004894:	2a4080e7          	jalr	676(ra) # 80003b34 <readi>
    80004898:	892a                	mv	s2,a0
    8000489a:	00a05563          	blez	a0,800048a4 <fileread+0x56>
      f->off += r;
    8000489e:	509c                	lw	a5,32(s1)
    800048a0:	9fa9                	addw	a5,a5,a0
    800048a2:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800048a4:	6c88                	ld	a0,24(s1)
    800048a6:	fffff097          	auipc	ra,0xfffff
    800048aa:	09c080e7          	jalr	156(ra) # 80003942 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800048ae:	854a                	mv	a0,s2
    800048b0:	70a2                	ld	ra,40(sp)
    800048b2:	7402                	ld	s0,32(sp)
    800048b4:	64e2                	ld	s1,24(sp)
    800048b6:	6942                	ld	s2,16(sp)
    800048b8:	69a2                	ld	s3,8(sp)
    800048ba:	6145                	addi	sp,sp,48
    800048bc:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800048be:	6908                	ld	a0,16(a0)
    800048c0:	00000097          	auipc	ra,0x0
    800048c4:	3c6080e7          	jalr	966(ra) # 80004c86 <piperead>
    800048c8:	892a                	mv	s2,a0
    800048ca:	b7d5                	j	800048ae <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800048cc:	02451783          	lh	a5,36(a0)
    800048d0:	03079693          	slli	a3,a5,0x30
    800048d4:	92c1                	srli	a3,a3,0x30
    800048d6:	4725                	li	a4,9
    800048d8:	02d76863          	bltu	a4,a3,80004908 <fileread+0xba>
    800048dc:	0792                	slli	a5,a5,0x4
    800048de:	00025717          	auipc	a4,0x25
    800048e2:	82270713          	addi	a4,a4,-2014 # 80029100 <devsw>
    800048e6:	97ba                	add	a5,a5,a4
    800048e8:	639c                	ld	a5,0(a5)
    800048ea:	c38d                	beqz	a5,8000490c <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800048ec:	4505                	li	a0,1
    800048ee:	9782                	jalr	a5
    800048f0:	892a                	mv	s2,a0
    800048f2:	bf75                	j	800048ae <fileread+0x60>
    panic("fileread");
    800048f4:	00004517          	auipc	a0,0x4
    800048f8:	fb450513          	addi	a0,a0,-76 # 800088a8 <syscalls+0x288>
    800048fc:	ffffc097          	auipc	ra,0xffffc
    80004900:	c44080e7          	jalr	-956(ra) # 80000540 <panic>
    return -1;
    80004904:	597d                	li	s2,-1
    80004906:	b765                	j	800048ae <fileread+0x60>
      return -1;
    80004908:	597d                	li	s2,-1
    8000490a:	b755                	j	800048ae <fileread+0x60>
    8000490c:	597d                	li	s2,-1
    8000490e:	b745                	j	800048ae <fileread+0x60>

0000000080004910 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004910:	715d                	addi	sp,sp,-80
    80004912:	e486                	sd	ra,72(sp)
    80004914:	e0a2                	sd	s0,64(sp)
    80004916:	fc26                	sd	s1,56(sp)
    80004918:	f84a                	sd	s2,48(sp)
    8000491a:	f44e                	sd	s3,40(sp)
    8000491c:	f052                	sd	s4,32(sp)
    8000491e:	ec56                	sd	s5,24(sp)
    80004920:	e85a                	sd	s6,16(sp)
    80004922:	e45e                	sd	s7,8(sp)
    80004924:	e062                	sd	s8,0(sp)
    80004926:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004928:	00954783          	lbu	a5,9(a0)
    8000492c:	10078663          	beqz	a5,80004a38 <filewrite+0x128>
    80004930:	892a                	mv	s2,a0
    80004932:	8b2e                	mv	s6,a1
    80004934:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004936:	411c                	lw	a5,0(a0)
    80004938:	4705                	li	a4,1
    8000493a:	02e78263          	beq	a5,a4,8000495e <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000493e:	470d                	li	a4,3
    80004940:	02e78663          	beq	a5,a4,8000496c <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004944:	4709                	li	a4,2
    80004946:	0ee79163          	bne	a5,a4,80004a28 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000494a:	0ac05d63          	blez	a2,80004a04 <filewrite+0xf4>
    int i = 0;
    8000494e:	4981                	li	s3,0
    80004950:	6b85                	lui	s7,0x1
    80004952:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004956:	6c05                	lui	s8,0x1
    80004958:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    8000495c:	a861                	j	800049f4 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000495e:	6908                	ld	a0,16(a0)
    80004960:	00000097          	auipc	ra,0x0
    80004964:	22e080e7          	jalr	558(ra) # 80004b8e <pipewrite>
    80004968:	8a2a                	mv	s4,a0
    8000496a:	a045                	j	80004a0a <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000496c:	02451783          	lh	a5,36(a0)
    80004970:	03079693          	slli	a3,a5,0x30
    80004974:	92c1                	srli	a3,a3,0x30
    80004976:	4725                	li	a4,9
    80004978:	0cd76263          	bltu	a4,a3,80004a3c <filewrite+0x12c>
    8000497c:	0792                	slli	a5,a5,0x4
    8000497e:	00024717          	auipc	a4,0x24
    80004982:	78270713          	addi	a4,a4,1922 # 80029100 <devsw>
    80004986:	97ba                	add	a5,a5,a4
    80004988:	679c                	ld	a5,8(a5)
    8000498a:	cbdd                	beqz	a5,80004a40 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    8000498c:	4505                	li	a0,1
    8000498e:	9782                	jalr	a5
    80004990:	8a2a                	mv	s4,a0
    80004992:	a8a5                	j	80004a0a <filewrite+0xfa>
    80004994:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004998:	00000097          	auipc	ra,0x0
    8000499c:	8b4080e7          	jalr	-1868(ra) # 8000424c <begin_op>
      ilock(f->ip);
    800049a0:	01893503          	ld	a0,24(s2)
    800049a4:	fffff097          	auipc	ra,0xfffff
    800049a8:	edc080e7          	jalr	-292(ra) # 80003880 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800049ac:	8756                	mv	a4,s5
    800049ae:	02092683          	lw	a3,32(s2)
    800049b2:	01698633          	add	a2,s3,s6
    800049b6:	4585                	li	a1,1
    800049b8:	01893503          	ld	a0,24(s2)
    800049bc:	fffff097          	auipc	ra,0xfffff
    800049c0:	270080e7          	jalr	624(ra) # 80003c2c <writei>
    800049c4:	84aa                	mv	s1,a0
    800049c6:	00a05763          	blez	a0,800049d4 <filewrite+0xc4>
        f->off += r;
    800049ca:	02092783          	lw	a5,32(s2)
    800049ce:	9fa9                	addw	a5,a5,a0
    800049d0:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800049d4:	01893503          	ld	a0,24(s2)
    800049d8:	fffff097          	auipc	ra,0xfffff
    800049dc:	f6a080e7          	jalr	-150(ra) # 80003942 <iunlock>
      end_op();
    800049e0:	00000097          	auipc	ra,0x0
    800049e4:	8ea080e7          	jalr	-1814(ra) # 800042ca <end_op>

      if(r != n1){
    800049e8:	009a9f63          	bne	s5,s1,80004a06 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800049ec:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800049f0:	0149db63          	bge	s3,s4,80004a06 <filewrite+0xf6>
      int n1 = n - i;
    800049f4:	413a04bb          	subw	s1,s4,s3
    800049f8:	0004879b          	sext.w	a5,s1
    800049fc:	f8fbdce3          	bge	s7,a5,80004994 <filewrite+0x84>
    80004a00:	84e2                	mv	s1,s8
    80004a02:	bf49                	j	80004994 <filewrite+0x84>
    int i = 0;
    80004a04:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004a06:	013a1f63          	bne	s4,s3,80004a24 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004a0a:	8552                	mv	a0,s4
    80004a0c:	60a6                	ld	ra,72(sp)
    80004a0e:	6406                	ld	s0,64(sp)
    80004a10:	74e2                	ld	s1,56(sp)
    80004a12:	7942                	ld	s2,48(sp)
    80004a14:	79a2                	ld	s3,40(sp)
    80004a16:	7a02                	ld	s4,32(sp)
    80004a18:	6ae2                	ld	s5,24(sp)
    80004a1a:	6b42                	ld	s6,16(sp)
    80004a1c:	6ba2                	ld	s7,8(sp)
    80004a1e:	6c02                	ld	s8,0(sp)
    80004a20:	6161                	addi	sp,sp,80
    80004a22:	8082                	ret
    ret = (i == n ? n : -1);
    80004a24:	5a7d                	li	s4,-1
    80004a26:	b7d5                	j	80004a0a <filewrite+0xfa>
    panic("filewrite");
    80004a28:	00004517          	auipc	a0,0x4
    80004a2c:	e9050513          	addi	a0,a0,-368 # 800088b8 <syscalls+0x298>
    80004a30:	ffffc097          	auipc	ra,0xffffc
    80004a34:	b10080e7          	jalr	-1264(ra) # 80000540 <panic>
    return -1;
    80004a38:	5a7d                	li	s4,-1
    80004a3a:	bfc1                	j	80004a0a <filewrite+0xfa>
      return -1;
    80004a3c:	5a7d                	li	s4,-1
    80004a3e:	b7f1                	j	80004a0a <filewrite+0xfa>
    80004a40:	5a7d                	li	s4,-1
    80004a42:	b7e1                	j	80004a0a <filewrite+0xfa>

0000000080004a44 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004a44:	7179                	addi	sp,sp,-48
    80004a46:	f406                	sd	ra,40(sp)
    80004a48:	f022                	sd	s0,32(sp)
    80004a4a:	ec26                	sd	s1,24(sp)
    80004a4c:	e84a                	sd	s2,16(sp)
    80004a4e:	e44e                	sd	s3,8(sp)
    80004a50:	e052                	sd	s4,0(sp)
    80004a52:	1800                	addi	s0,sp,48
    80004a54:	84aa                	mv	s1,a0
    80004a56:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004a58:	0005b023          	sd	zero,0(a1)
    80004a5c:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004a60:	00000097          	auipc	ra,0x0
    80004a64:	bf8080e7          	jalr	-1032(ra) # 80004658 <filealloc>
    80004a68:	e088                	sd	a0,0(s1)
    80004a6a:	c551                	beqz	a0,80004af6 <pipealloc+0xb2>
    80004a6c:	00000097          	auipc	ra,0x0
    80004a70:	bec080e7          	jalr	-1044(ra) # 80004658 <filealloc>
    80004a74:	00aa3023          	sd	a0,0(s4)
    80004a78:	c92d                	beqz	a0,80004aea <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004a7a:	ffffc097          	auipc	ra,0xffffc
    80004a7e:	06c080e7          	jalr	108(ra) # 80000ae6 <kalloc>
    80004a82:	892a                	mv	s2,a0
    80004a84:	c125                	beqz	a0,80004ae4 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004a86:	4985                	li	s3,1
    80004a88:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004a8c:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004a90:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004a94:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004a98:	00004597          	auipc	a1,0x4
    80004a9c:	ae058593          	addi	a1,a1,-1312 # 80008578 <states.0+0x218>
    80004aa0:	ffffc097          	auipc	ra,0xffffc
    80004aa4:	0a6080e7          	jalr	166(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004aa8:	609c                	ld	a5,0(s1)
    80004aaa:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004aae:	609c                	ld	a5,0(s1)
    80004ab0:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004ab4:	609c                	ld	a5,0(s1)
    80004ab6:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004aba:	609c                	ld	a5,0(s1)
    80004abc:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004ac0:	000a3783          	ld	a5,0(s4)
    80004ac4:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004ac8:	000a3783          	ld	a5,0(s4)
    80004acc:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004ad0:	000a3783          	ld	a5,0(s4)
    80004ad4:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004ad8:	000a3783          	ld	a5,0(s4)
    80004adc:	0127b823          	sd	s2,16(a5)
  return 0;
    80004ae0:	4501                	li	a0,0
    80004ae2:	a025                	j	80004b0a <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004ae4:	6088                	ld	a0,0(s1)
    80004ae6:	e501                	bnez	a0,80004aee <pipealloc+0xaa>
    80004ae8:	a039                	j	80004af6 <pipealloc+0xb2>
    80004aea:	6088                	ld	a0,0(s1)
    80004aec:	c51d                	beqz	a0,80004b1a <pipealloc+0xd6>
    fileclose(*f0);
    80004aee:	00000097          	auipc	ra,0x0
    80004af2:	c26080e7          	jalr	-986(ra) # 80004714 <fileclose>
  if(*f1)
    80004af6:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004afa:	557d                	li	a0,-1
  if(*f1)
    80004afc:	c799                	beqz	a5,80004b0a <pipealloc+0xc6>
    fileclose(*f1);
    80004afe:	853e                	mv	a0,a5
    80004b00:	00000097          	auipc	ra,0x0
    80004b04:	c14080e7          	jalr	-1004(ra) # 80004714 <fileclose>
  return -1;
    80004b08:	557d                	li	a0,-1
}
    80004b0a:	70a2                	ld	ra,40(sp)
    80004b0c:	7402                	ld	s0,32(sp)
    80004b0e:	64e2                	ld	s1,24(sp)
    80004b10:	6942                	ld	s2,16(sp)
    80004b12:	69a2                	ld	s3,8(sp)
    80004b14:	6a02                	ld	s4,0(sp)
    80004b16:	6145                	addi	sp,sp,48
    80004b18:	8082                	ret
  return -1;
    80004b1a:	557d                	li	a0,-1
    80004b1c:	b7fd                	j	80004b0a <pipealloc+0xc6>

0000000080004b1e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004b1e:	1101                	addi	sp,sp,-32
    80004b20:	ec06                	sd	ra,24(sp)
    80004b22:	e822                	sd	s0,16(sp)
    80004b24:	e426                	sd	s1,8(sp)
    80004b26:	e04a                	sd	s2,0(sp)
    80004b28:	1000                	addi	s0,sp,32
    80004b2a:	84aa                	mv	s1,a0
    80004b2c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004b2e:	ffffc097          	auipc	ra,0xffffc
    80004b32:	0a8080e7          	jalr	168(ra) # 80000bd6 <acquire>
  if(writable){
    80004b36:	02090d63          	beqz	s2,80004b70 <pipeclose+0x52>
    pi->writeopen = 0;
    80004b3a:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004b3e:	21848513          	addi	a0,s1,536
    80004b42:	ffffd097          	auipc	ra,0xffffd
    80004b46:	626080e7          	jalr	1574(ra) # 80002168 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004b4a:	2204b783          	ld	a5,544(s1)
    80004b4e:	eb95                	bnez	a5,80004b82 <pipeclose+0x64>
    release(&pi->lock);
    80004b50:	8526                	mv	a0,s1
    80004b52:	ffffc097          	auipc	ra,0xffffc
    80004b56:	138080e7          	jalr	312(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004b5a:	8526                	mv	a0,s1
    80004b5c:	ffffc097          	auipc	ra,0xffffc
    80004b60:	e8c080e7          	jalr	-372(ra) # 800009e8 <kfree>
  } else
    release(&pi->lock);
}
    80004b64:	60e2                	ld	ra,24(sp)
    80004b66:	6442                	ld	s0,16(sp)
    80004b68:	64a2                	ld	s1,8(sp)
    80004b6a:	6902                	ld	s2,0(sp)
    80004b6c:	6105                	addi	sp,sp,32
    80004b6e:	8082                	ret
    pi->readopen = 0;
    80004b70:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004b74:	21c48513          	addi	a0,s1,540
    80004b78:	ffffd097          	auipc	ra,0xffffd
    80004b7c:	5f0080e7          	jalr	1520(ra) # 80002168 <wakeup>
    80004b80:	b7e9                	j	80004b4a <pipeclose+0x2c>
    release(&pi->lock);
    80004b82:	8526                	mv	a0,s1
    80004b84:	ffffc097          	auipc	ra,0xffffc
    80004b88:	106080e7          	jalr	262(ra) # 80000c8a <release>
}
    80004b8c:	bfe1                	j	80004b64 <pipeclose+0x46>

0000000080004b8e <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004b8e:	711d                	addi	sp,sp,-96
    80004b90:	ec86                	sd	ra,88(sp)
    80004b92:	e8a2                	sd	s0,80(sp)
    80004b94:	e4a6                	sd	s1,72(sp)
    80004b96:	e0ca                	sd	s2,64(sp)
    80004b98:	fc4e                	sd	s3,56(sp)
    80004b9a:	f852                	sd	s4,48(sp)
    80004b9c:	f456                	sd	s5,40(sp)
    80004b9e:	f05a                	sd	s6,32(sp)
    80004ba0:	ec5e                	sd	s7,24(sp)
    80004ba2:	e862                	sd	s8,16(sp)
    80004ba4:	1080                	addi	s0,sp,96
    80004ba6:	84aa                	mv	s1,a0
    80004ba8:	8aae                	mv	s5,a1
    80004baa:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004bac:	ffffd097          	auipc	ra,0xffffd
    80004bb0:	e00080e7          	jalr	-512(ra) # 800019ac <myproc>
    80004bb4:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004bb6:	8526                	mv	a0,s1
    80004bb8:	ffffc097          	auipc	ra,0xffffc
    80004bbc:	01e080e7          	jalr	30(ra) # 80000bd6 <acquire>
  while(i < n){
    80004bc0:	0b405663          	blez	s4,80004c6c <pipewrite+0xde>
  int i = 0;
    80004bc4:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004bc6:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004bc8:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004bcc:	21c48b93          	addi	s7,s1,540
    80004bd0:	a089                	j	80004c12 <pipewrite+0x84>
      release(&pi->lock);
    80004bd2:	8526                	mv	a0,s1
    80004bd4:	ffffc097          	auipc	ra,0xffffc
    80004bd8:	0b6080e7          	jalr	182(ra) # 80000c8a <release>
      return -1;
    80004bdc:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004bde:	854a                	mv	a0,s2
    80004be0:	60e6                	ld	ra,88(sp)
    80004be2:	6446                	ld	s0,80(sp)
    80004be4:	64a6                	ld	s1,72(sp)
    80004be6:	6906                	ld	s2,64(sp)
    80004be8:	79e2                	ld	s3,56(sp)
    80004bea:	7a42                	ld	s4,48(sp)
    80004bec:	7aa2                	ld	s5,40(sp)
    80004bee:	7b02                	ld	s6,32(sp)
    80004bf0:	6be2                	ld	s7,24(sp)
    80004bf2:	6c42                	ld	s8,16(sp)
    80004bf4:	6125                	addi	sp,sp,96
    80004bf6:	8082                	ret
      wakeup(&pi->nread);
    80004bf8:	8562                	mv	a0,s8
    80004bfa:	ffffd097          	auipc	ra,0xffffd
    80004bfe:	56e080e7          	jalr	1390(ra) # 80002168 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004c02:	85a6                	mv	a1,s1
    80004c04:	855e                	mv	a0,s7
    80004c06:	ffffd097          	auipc	ra,0xffffd
    80004c0a:	4fe080e7          	jalr	1278(ra) # 80002104 <sleep>
  while(i < n){
    80004c0e:	07495063          	bge	s2,s4,80004c6e <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004c12:	2204a783          	lw	a5,544(s1)
    80004c16:	dfd5                	beqz	a5,80004bd2 <pipewrite+0x44>
    80004c18:	854e                	mv	a0,s3
    80004c1a:	ffffd097          	auipc	ra,0xffffd
    80004c1e:	792080e7          	jalr	1938(ra) # 800023ac <killed>
    80004c22:	f945                	bnez	a0,80004bd2 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004c24:	2184a783          	lw	a5,536(s1)
    80004c28:	21c4a703          	lw	a4,540(s1)
    80004c2c:	2007879b          	addiw	a5,a5,512
    80004c30:	fcf704e3          	beq	a4,a5,80004bf8 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c34:	4685                	li	a3,1
    80004c36:	01590633          	add	a2,s2,s5
    80004c3a:	faf40593          	addi	a1,s0,-81
    80004c3e:	0509b503          	ld	a0,80(s3)
    80004c42:	ffffd097          	auipc	ra,0xffffd
    80004c46:	ab6080e7          	jalr	-1354(ra) # 800016f8 <copyin>
    80004c4a:	03650263          	beq	a0,s6,80004c6e <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004c4e:	21c4a783          	lw	a5,540(s1)
    80004c52:	0017871b          	addiw	a4,a5,1
    80004c56:	20e4ae23          	sw	a4,540(s1)
    80004c5a:	1ff7f793          	andi	a5,a5,511
    80004c5e:	97a6                	add	a5,a5,s1
    80004c60:	faf44703          	lbu	a4,-81(s0)
    80004c64:	00e78c23          	sb	a4,24(a5)
      i++;
    80004c68:	2905                	addiw	s2,s2,1
    80004c6a:	b755                	j	80004c0e <pipewrite+0x80>
  int i = 0;
    80004c6c:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004c6e:	21848513          	addi	a0,s1,536
    80004c72:	ffffd097          	auipc	ra,0xffffd
    80004c76:	4f6080e7          	jalr	1270(ra) # 80002168 <wakeup>
  release(&pi->lock);
    80004c7a:	8526                	mv	a0,s1
    80004c7c:	ffffc097          	auipc	ra,0xffffc
    80004c80:	00e080e7          	jalr	14(ra) # 80000c8a <release>
  return i;
    80004c84:	bfa9                	j	80004bde <pipewrite+0x50>

0000000080004c86 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004c86:	715d                	addi	sp,sp,-80
    80004c88:	e486                	sd	ra,72(sp)
    80004c8a:	e0a2                	sd	s0,64(sp)
    80004c8c:	fc26                	sd	s1,56(sp)
    80004c8e:	f84a                	sd	s2,48(sp)
    80004c90:	f44e                	sd	s3,40(sp)
    80004c92:	f052                	sd	s4,32(sp)
    80004c94:	ec56                	sd	s5,24(sp)
    80004c96:	e85a                	sd	s6,16(sp)
    80004c98:	0880                	addi	s0,sp,80
    80004c9a:	84aa                	mv	s1,a0
    80004c9c:	892e                	mv	s2,a1
    80004c9e:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004ca0:	ffffd097          	auipc	ra,0xffffd
    80004ca4:	d0c080e7          	jalr	-756(ra) # 800019ac <myproc>
    80004ca8:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004caa:	8526                	mv	a0,s1
    80004cac:	ffffc097          	auipc	ra,0xffffc
    80004cb0:	f2a080e7          	jalr	-214(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cb4:	2184a703          	lw	a4,536(s1)
    80004cb8:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004cbc:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cc0:	02f71763          	bne	a4,a5,80004cee <piperead+0x68>
    80004cc4:	2244a783          	lw	a5,548(s1)
    80004cc8:	c39d                	beqz	a5,80004cee <piperead+0x68>
    if(killed(pr)){
    80004cca:	8552                	mv	a0,s4
    80004ccc:	ffffd097          	auipc	ra,0xffffd
    80004cd0:	6e0080e7          	jalr	1760(ra) # 800023ac <killed>
    80004cd4:	e949                	bnez	a0,80004d66 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004cd6:	85a6                	mv	a1,s1
    80004cd8:	854e                	mv	a0,s3
    80004cda:	ffffd097          	auipc	ra,0xffffd
    80004cde:	42a080e7          	jalr	1066(ra) # 80002104 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ce2:	2184a703          	lw	a4,536(s1)
    80004ce6:	21c4a783          	lw	a5,540(s1)
    80004cea:	fcf70de3          	beq	a4,a5,80004cc4 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cee:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004cf0:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cf2:	05505463          	blez	s5,80004d3a <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004cf6:	2184a783          	lw	a5,536(s1)
    80004cfa:	21c4a703          	lw	a4,540(s1)
    80004cfe:	02f70e63          	beq	a4,a5,80004d3a <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004d02:	0017871b          	addiw	a4,a5,1
    80004d06:	20e4ac23          	sw	a4,536(s1)
    80004d0a:	1ff7f793          	andi	a5,a5,511
    80004d0e:	97a6                	add	a5,a5,s1
    80004d10:	0187c783          	lbu	a5,24(a5)
    80004d14:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d18:	4685                	li	a3,1
    80004d1a:	fbf40613          	addi	a2,s0,-65
    80004d1e:	85ca                	mv	a1,s2
    80004d20:	050a3503          	ld	a0,80(s4)
    80004d24:	ffffd097          	auipc	ra,0xffffd
    80004d28:	948080e7          	jalr	-1720(ra) # 8000166c <copyout>
    80004d2c:	01650763          	beq	a0,s6,80004d3a <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d30:	2985                	addiw	s3,s3,1
    80004d32:	0905                	addi	s2,s2,1
    80004d34:	fd3a91e3          	bne	s5,s3,80004cf6 <piperead+0x70>
    80004d38:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004d3a:	21c48513          	addi	a0,s1,540
    80004d3e:	ffffd097          	auipc	ra,0xffffd
    80004d42:	42a080e7          	jalr	1066(ra) # 80002168 <wakeup>
  release(&pi->lock);
    80004d46:	8526                	mv	a0,s1
    80004d48:	ffffc097          	auipc	ra,0xffffc
    80004d4c:	f42080e7          	jalr	-190(ra) # 80000c8a <release>
  return i;
}
    80004d50:	854e                	mv	a0,s3
    80004d52:	60a6                	ld	ra,72(sp)
    80004d54:	6406                	ld	s0,64(sp)
    80004d56:	74e2                	ld	s1,56(sp)
    80004d58:	7942                	ld	s2,48(sp)
    80004d5a:	79a2                	ld	s3,40(sp)
    80004d5c:	7a02                	ld	s4,32(sp)
    80004d5e:	6ae2                	ld	s5,24(sp)
    80004d60:	6b42                	ld	s6,16(sp)
    80004d62:	6161                	addi	sp,sp,80
    80004d64:	8082                	ret
      release(&pi->lock);
    80004d66:	8526                	mv	a0,s1
    80004d68:	ffffc097          	auipc	ra,0xffffc
    80004d6c:	f22080e7          	jalr	-222(ra) # 80000c8a <release>
      return -1;
    80004d70:	59fd                	li	s3,-1
    80004d72:	bff9                	j	80004d50 <piperead+0xca>

0000000080004d74 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004d74:	1141                	addi	sp,sp,-16
    80004d76:	e422                	sd	s0,8(sp)
    80004d78:	0800                	addi	s0,sp,16
    80004d7a:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004d7c:	8905                	andi	a0,a0,1
    80004d7e:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004d80:	8b89                	andi	a5,a5,2
    80004d82:	c399                	beqz	a5,80004d88 <flags2perm+0x14>
      perm |= PTE_W;
    80004d84:	00456513          	ori	a0,a0,4
    return perm;
}
    80004d88:	6422                	ld	s0,8(sp)
    80004d8a:	0141                	addi	sp,sp,16
    80004d8c:	8082                	ret

0000000080004d8e <exec>:

int
exec(char *path, char **argv)
{
    80004d8e:	de010113          	addi	sp,sp,-544
    80004d92:	20113c23          	sd	ra,536(sp)
    80004d96:	20813823          	sd	s0,528(sp)
    80004d9a:	20913423          	sd	s1,520(sp)
    80004d9e:	21213023          	sd	s2,512(sp)
    80004da2:	ffce                	sd	s3,504(sp)
    80004da4:	fbd2                	sd	s4,496(sp)
    80004da6:	f7d6                	sd	s5,488(sp)
    80004da8:	f3da                	sd	s6,480(sp)
    80004daa:	efde                	sd	s7,472(sp)
    80004dac:	ebe2                	sd	s8,464(sp)
    80004dae:	e7e6                	sd	s9,456(sp)
    80004db0:	e3ea                	sd	s10,448(sp)
    80004db2:	ff6e                	sd	s11,440(sp)
    80004db4:	1400                	addi	s0,sp,544
    80004db6:	892a                	mv	s2,a0
    80004db8:	dea43423          	sd	a0,-536(s0)
    80004dbc:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004dc0:	ffffd097          	auipc	ra,0xffffd
    80004dc4:	bec080e7          	jalr	-1044(ra) # 800019ac <myproc>
    80004dc8:	84aa                	mv	s1,a0

  begin_op();
    80004dca:	fffff097          	auipc	ra,0xfffff
    80004dce:	482080e7          	jalr	1154(ra) # 8000424c <begin_op>

  if((ip = namei(path)) == 0){
    80004dd2:	854a                	mv	a0,s2
    80004dd4:	fffff097          	auipc	ra,0xfffff
    80004dd8:	258080e7          	jalr	600(ra) # 8000402c <namei>
    80004ddc:	c93d                	beqz	a0,80004e52 <exec+0xc4>
    80004dde:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004de0:	fffff097          	auipc	ra,0xfffff
    80004de4:	aa0080e7          	jalr	-1376(ra) # 80003880 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004de8:	04000713          	li	a4,64
    80004dec:	4681                	li	a3,0
    80004dee:	e5040613          	addi	a2,s0,-432
    80004df2:	4581                	li	a1,0
    80004df4:	8556                	mv	a0,s5
    80004df6:	fffff097          	auipc	ra,0xfffff
    80004dfa:	d3e080e7          	jalr	-706(ra) # 80003b34 <readi>
    80004dfe:	04000793          	li	a5,64
    80004e02:	00f51a63          	bne	a0,a5,80004e16 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004e06:	e5042703          	lw	a4,-432(s0)
    80004e0a:	464c47b7          	lui	a5,0x464c4
    80004e0e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004e12:	04f70663          	beq	a4,a5,80004e5e <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004e16:	8556                	mv	a0,s5
    80004e18:	fffff097          	auipc	ra,0xfffff
    80004e1c:	cca080e7          	jalr	-822(ra) # 80003ae2 <iunlockput>
    end_op();
    80004e20:	fffff097          	auipc	ra,0xfffff
    80004e24:	4aa080e7          	jalr	1194(ra) # 800042ca <end_op>
  }
  return -1;
    80004e28:	557d                	li	a0,-1
}
    80004e2a:	21813083          	ld	ra,536(sp)
    80004e2e:	21013403          	ld	s0,528(sp)
    80004e32:	20813483          	ld	s1,520(sp)
    80004e36:	20013903          	ld	s2,512(sp)
    80004e3a:	79fe                	ld	s3,504(sp)
    80004e3c:	7a5e                	ld	s4,496(sp)
    80004e3e:	7abe                	ld	s5,488(sp)
    80004e40:	7b1e                	ld	s6,480(sp)
    80004e42:	6bfe                	ld	s7,472(sp)
    80004e44:	6c5e                	ld	s8,464(sp)
    80004e46:	6cbe                	ld	s9,456(sp)
    80004e48:	6d1e                	ld	s10,448(sp)
    80004e4a:	7dfa                	ld	s11,440(sp)
    80004e4c:	22010113          	addi	sp,sp,544
    80004e50:	8082                	ret
    end_op();
    80004e52:	fffff097          	auipc	ra,0xfffff
    80004e56:	478080e7          	jalr	1144(ra) # 800042ca <end_op>
    return -1;
    80004e5a:	557d                	li	a0,-1
    80004e5c:	b7f9                	j	80004e2a <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004e5e:	8526                	mv	a0,s1
    80004e60:	ffffd097          	auipc	ra,0xffffd
    80004e64:	c10080e7          	jalr	-1008(ra) # 80001a70 <proc_pagetable>
    80004e68:	8b2a                	mv	s6,a0
    80004e6a:	d555                	beqz	a0,80004e16 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e6c:	e7042783          	lw	a5,-400(s0)
    80004e70:	e8845703          	lhu	a4,-376(s0)
    80004e74:	c735                	beqz	a4,80004ee0 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e76:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e78:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004e7c:	6a05                	lui	s4,0x1
    80004e7e:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004e82:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004e86:	6d85                	lui	s11,0x1
    80004e88:	7d7d                	lui	s10,0xfffff
    80004e8a:	ac3d                	j	800050c8 <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004e8c:	00004517          	auipc	a0,0x4
    80004e90:	a3c50513          	addi	a0,a0,-1476 # 800088c8 <syscalls+0x2a8>
    80004e94:	ffffb097          	auipc	ra,0xffffb
    80004e98:	6ac080e7          	jalr	1708(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004e9c:	874a                	mv	a4,s2
    80004e9e:	009c86bb          	addw	a3,s9,s1
    80004ea2:	4581                	li	a1,0
    80004ea4:	8556                	mv	a0,s5
    80004ea6:	fffff097          	auipc	ra,0xfffff
    80004eaa:	c8e080e7          	jalr	-882(ra) # 80003b34 <readi>
    80004eae:	2501                	sext.w	a0,a0
    80004eb0:	1aa91963          	bne	s2,a0,80005062 <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    80004eb4:	009d84bb          	addw	s1,s11,s1
    80004eb8:	013d09bb          	addw	s3,s10,s3
    80004ebc:	1f74f663          	bgeu	s1,s7,800050a8 <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    80004ec0:	02049593          	slli	a1,s1,0x20
    80004ec4:	9181                	srli	a1,a1,0x20
    80004ec6:	95e2                	add	a1,a1,s8
    80004ec8:	855a                	mv	a0,s6
    80004eca:	ffffc097          	auipc	ra,0xffffc
    80004ece:	192080e7          	jalr	402(ra) # 8000105c <walkaddr>
    80004ed2:	862a                	mv	a2,a0
    if(pa == 0)
    80004ed4:	dd45                	beqz	a0,80004e8c <exec+0xfe>
      n = PGSIZE;
    80004ed6:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004ed8:	fd49f2e3          	bgeu	s3,s4,80004e9c <exec+0x10e>
      n = sz - i;
    80004edc:	894e                	mv	s2,s3
    80004ede:	bf7d                	j	80004e9c <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004ee0:	4901                	li	s2,0
  iunlockput(ip);
    80004ee2:	8556                	mv	a0,s5
    80004ee4:	fffff097          	auipc	ra,0xfffff
    80004ee8:	bfe080e7          	jalr	-1026(ra) # 80003ae2 <iunlockput>
  end_op();
    80004eec:	fffff097          	auipc	ra,0xfffff
    80004ef0:	3de080e7          	jalr	990(ra) # 800042ca <end_op>
  p = myproc();
    80004ef4:	ffffd097          	auipc	ra,0xffffd
    80004ef8:	ab8080e7          	jalr	-1352(ra) # 800019ac <myproc>
    80004efc:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004efe:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004f02:	6785                	lui	a5,0x1
    80004f04:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80004f06:	97ca                	add	a5,a5,s2
    80004f08:	777d                	lui	a4,0xfffff
    80004f0a:	8ff9                	and	a5,a5,a4
    80004f0c:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004f10:	4691                	li	a3,4
    80004f12:	6609                	lui	a2,0x2
    80004f14:	963e                	add	a2,a2,a5
    80004f16:	85be                	mv	a1,a5
    80004f18:	855a                	mv	a0,s6
    80004f1a:	ffffc097          	auipc	ra,0xffffc
    80004f1e:	4f6080e7          	jalr	1270(ra) # 80001410 <uvmalloc>
    80004f22:	8c2a                	mv	s8,a0
  ip = 0;
    80004f24:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004f26:	12050e63          	beqz	a0,80005062 <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004f2a:	75f9                	lui	a1,0xffffe
    80004f2c:	95aa                	add	a1,a1,a0
    80004f2e:	855a                	mv	a0,s6
    80004f30:	ffffc097          	auipc	ra,0xffffc
    80004f34:	70a080e7          	jalr	1802(ra) # 8000163a <uvmclear>
  stackbase = sp - PGSIZE;
    80004f38:	7afd                	lui	s5,0xfffff
    80004f3a:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004f3c:	df043783          	ld	a5,-528(s0)
    80004f40:	6388                	ld	a0,0(a5)
    80004f42:	c925                	beqz	a0,80004fb2 <exec+0x224>
    80004f44:	e9040993          	addi	s3,s0,-368
    80004f48:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004f4c:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004f4e:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004f50:	ffffc097          	auipc	ra,0xffffc
    80004f54:	efe080e7          	jalr	-258(ra) # 80000e4e <strlen>
    80004f58:	0015079b          	addiw	a5,a0,1
    80004f5c:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004f60:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004f64:	13596663          	bltu	s2,s5,80005090 <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004f68:	df043d83          	ld	s11,-528(s0)
    80004f6c:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004f70:	8552                	mv	a0,s4
    80004f72:	ffffc097          	auipc	ra,0xffffc
    80004f76:	edc080e7          	jalr	-292(ra) # 80000e4e <strlen>
    80004f7a:	0015069b          	addiw	a3,a0,1
    80004f7e:	8652                	mv	a2,s4
    80004f80:	85ca                	mv	a1,s2
    80004f82:	855a                	mv	a0,s6
    80004f84:	ffffc097          	auipc	ra,0xffffc
    80004f88:	6e8080e7          	jalr	1768(ra) # 8000166c <copyout>
    80004f8c:	10054663          	bltz	a0,80005098 <exec+0x30a>
    ustack[argc] = sp;
    80004f90:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004f94:	0485                	addi	s1,s1,1
    80004f96:	008d8793          	addi	a5,s11,8
    80004f9a:	def43823          	sd	a5,-528(s0)
    80004f9e:	008db503          	ld	a0,8(s11)
    80004fa2:	c911                	beqz	a0,80004fb6 <exec+0x228>
    if(argc >= MAXARG)
    80004fa4:	09a1                	addi	s3,s3,8
    80004fa6:	fb3c95e3          	bne	s9,s3,80004f50 <exec+0x1c2>
  sz = sz1;
    80004faa:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004fae:	4a81                	li	s5,0
    80004fb0:	a84d                	j	80005062 <exec+0x2d4>
  sp = sz;
    80004fb2:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004fb4:	4481                	li	s1,0
  ustack[argc] = 0;
    80004fb6:	00349793          	slli	a5,s1,0x3
    80004fba:	f9078793          	addi	a5,a5,-112
    80004fbe:	97a2                	add	a5,a5,s0
    80004fc0:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004fc4:	00148693          	addi	a3,s1,1
    80004fc8:	068e                	slli	a3,a3,0x3
    80004fca:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004fce:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004fd2:	01597663          	bgeu	s2,s5,80004fde <exec+0x250>
  sz = sz1;
    80004fd6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004fda:	4a81                	li	s5,0
    80004fdc:	a059                	j	80005062 <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004fde:	e9040613          	addi	a2,s0,-368
    80004fe2:	85ca                	mv	a1,s2
    80004fe4:	855a                	mv	a0,s6
    80004fe6:	ffffc097          	auipc	ra,0xffffc
    80004fea:	686080e7          	jalr	1670(ra) # 8000166c <copyout>
    80004fee:	0a054963          	bltz	a0,800050a0 <exec+0x312>
  p->trapframe->a1 = sp;
    80004ff2:	058bb783          	ld	a5,88(s7)
    80004ff6:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004ffa:	de843783          	ld	a5,-536(s0)
    80004ffe:	0007c703          	lbu	a4,0(a5)
    80005002:	cf11                	beqz	a4,8000501e <exec+0x290>
    80005004:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005006:	02f00693          	li	a3,47
    8000500a:	a039                	j	80005018 <exec+0x28a>
      last = s+1;
    8000500c:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005010:	0785                	addi	a5,a5,1
    80005012:	fff7c703          	lbu	a4,-1(a5)
    80005016:	c701                	beqz	a4,8000501e <exec+0x290>
    if(*s == '/')
    80005018:	fed71ce3          	bne	a4,a3,80005010 <exec+0x282>
    8000501c:	bfc5                	j	8000500c <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    8000501e:	4641                	li	a2,16
    80005020:	de843583          	ld	a1,-536(s0)
    80005024:	158b8513          	addi	a0,s7,344
    80005028:	ffffc097          	auipc	ra,0xffffc
    8000502c:	df4080e7          	jalr	-524(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    80005030:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80005034:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80005038:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000503c:	058bb783          	ld	a5,88(s7)
    80005040:	e6843703          	ld	a4,-408(s0)
    80005044:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005046:	058bb783          	ld	a5,88(s7)
    8000504a:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000504e:	85ea                	mv	a1,s10
    80005050:	ffffd097          	auipc	ra,0xffffd
    80005054:	abc080e7          	jalr	-1348(ra) # 80001b0c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005058:	0004851b          	sext.w	a0,s1
    8000505c:	b3f9                	j	80004e2a <exec+0x9c>
    8000505e:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005062:	df843583          	ld	a1,-520(s0)
    80005066:	855a                	mv	a0,s6
    80005068:	ffffd097          	auipc	ra,0xffffd
    8000506c:	aa4080e7          	jalr	-1372(ra) # 80001b0c <proc_freepagetable>
  if(ip){
    80005070:	da0a93e3          	bnez	s5,80004e16 <exec+0x88>
  return -1;
    80005074:	557d                	li	a0,-1
    80005076:	bb55                	j	80004e2a <exec+0x9c>
    80005078:	df243c23          	sd	s2,-520(s0)
    8000507c:	b7dd                	j	80005062 <exec+0x2d4>
    8000507e:	df243c23          	sd	s2,-520(s0)
    80005082:	b7c5                	j	80005062 <exec+0x2d4>
    80005084:	df243c23          	sd	s2,-520(s0)
    80005088:	bfe9                	j	80005062 <exec+0x2d4>
    8000508a:	df243c23          	sd	s2,-520(s0)
    8000508e:	bfd1                	j	80005062 <exec+0x2d4>
  sz = sz1;
    80005090:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005094:	4a81                	li	s5,0
    80005096:	b7f1                	j	80005062 <exec+0x2d4>
  sz = sz1;
    80005098:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000509c:	4a81                	li	s5,0
    8000509e:	b7d1                	j	80005062 <exec+0x2d4>
  sz = sz1;
    800050a0:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050a4:	4a81                	li	s5,0
    800050a6:	bf75                	j	80005062 <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800050a8:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050ac:	e0843783          	ld	a5,-504(s0)
    800050b0:	0017869b          	addiw	a3,a5,1
    800050b4:	e0d43423          	sd	a3,-504(s0)
    800050b8:	e0043783          	ld	a5,-512(s0)
    800050bc:	0387879b          	addiw	a5,a5,56
    800050c0:	e8845703          	lhu	a4,-376(s0)
    800050c4:	e0e6dfe3          	bge	a3,a4,80004ee2 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800050c8:	2781                	sext.w	a5,a5
    800050ca:	e0f43023          	sd	a5,-512(s0)
    800050ce:	03800713          	li	a4,56
    800050d2:	86be                	mv	a3,a5
    800050d4:	e1840613          	addi	a2,s0,-488
    800050d8:	4581                	li	a1,0
    800050da:	8556                	mv	a0,s5
    800050dc:	fffff097          	auipc	ra,0xfffff
    800050e0:	a58080e7          	jalr	-1448(ra) # 80003b34 <readi>
    800050e4:	03800793          	li	a5,56
    800050e8:	f6f51be3          	bne	a0,a5,8000505e <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    800050ec:	e1842783          	lw	a5,-488(s0)
    800050f0:	4705                	li	a4,1
    800050f2:	fae79de3          	bne	a5,a4,800050ac <exec+0x31e>
    if(ph.memsz < ph.filesz)
    800050f6:	e4043483          	ld	s1,-448(s0)
    800050fa:	e3843783          	ld	a5,-456(s0)
    800050fe:	f6f4ede3          	bltu	s1,a5,80005078 <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005102:	e2843783          	ld	a5,-472(s0)
    80005106:	94be                	add	s1,s1,a5
    80005108:	f6f4ebe3          	bltu	s1,a5,8000507e <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    8000510c:	de043703          	ld	a4,-544(s0)
    80005110:	8ff9                	and	a5,a5,a4
    80005112:	fbad                	bnez	a5,80005084 <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005114:	e1c42503          	lw	a0,-484(s0)
    80005118:	00000097          	auipc	ra,0x0
    8000511c:	c5c080e7          	jalr	-932(ra) # 80004d74 <flags2perm>
    80005120:	86aa                	mv	a3,a0
    80005122:	8626                	mv	a2,s1
    80005124:	85ca                	mv	a1,s2
    80005126:	855a                	mv	a0,s6
    80005128:	ffffc097          	auipc	ra,0xffffc
    8000512c:	2e8080e7          	jalr	744(ra) # 80001410 <uvmalloc>
    80005130:	dea43c23          	sd	a0,-520(s0)
    80005134:	d939                	beqz	a0,8000508a <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005136:	e2843c03          	ld	s8,-472(s0)
    8000513a:	e2042c83          	lw	s9,-480(s0)
    8000513e:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005142:	f60b83e3          	beqz	s7,800050a8 <exec+0x31a>
    80005146:	89de                	mv	s3,s7
    80005148:	4481                	li	s1,0
    8000514a:	bb9d                	j	80004ec0 <exec+0x132>

000000008000514c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000514c:	7179                	addi	sp,sp,-48
    8000514e:	f406                	sd	ra,40(sp)
    80005150:	f022                	sd	s0,32(sp)
    80005152:	ec26                	sd	s1,24(sp)
    80005154:	e84a                	sd	s2,16(sp)
    80005156:	1800                	addi	s0,sp,48
    80005158:	892e                	mv	s2,a1
    8000515a:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    8000515c:	fdc40593          	addi	a1,s0,-36
    80005160:	ffffe097          	auipc	ra,0xffffe
    80005164:	a12080e7          	jalr	-1518(ra) # 80002b72 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005168:	fdc42703          	lw	a4,-36(s0)
    8000516c:	47bd                	li	a5,15
    8000516e:	02e7eb63          	bltu	a5,a4,800051a4 <argfd+0x58>
    80005172:	ffffd097          	auipc	ra,0xffffd
    80005176:	83a080e7          	jalr	-1990(ra) # 800019ac <myproc>
    8000517a:	fdc42703          	lw	a4,-36(s0)
    8000517e:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffd4d82>
    80005182:	078e                	slli	a5,a5,0x3
    80005184:	953e                	add	a0,a0,a5
    80005186:	611c                	ld	a5,0(a0)
    80005188:	c385                	beqz	a5,800051a8 <argfd+0x5c>
    return -1;
  if(pfd)
    8000518a:	00090463          	beqz	s2,80005192 <argfd+0x46>
    *pfd = fd;
    8000518e:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005192:	4501                	li	a0,0
  if(pf)
    80005194:	c091                	beqz	s1,80005198 <argfd+0x4c>
    *pf = f;
    80005196:	e09c                	sd	a5,0(s1)
}
    80005198:	70a2                	ld	ra,40(sp)
    8000519a:	7402                	ld	s0,32(sp)
    8000519c:	64e2                	ld	s1,24(sp)
    8000519e:	6942                	ld	s2,16(sp)
    800051a0:	6145                	addi	sp,sp,48
    800051a2:	8082                	ret
    return -1;
    800051a4:	557d                	li	a0,-1
    800051a6:	bfcd                	j	80005198 <argfd+0x4c>
    800051a8:	557d                	li	a0,-1
    800051aa:	b7fd                	j	80005198 <argfd+0x4c>

00000000800051ac <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800051ac:	1101                	addi	sp,sp,-32
    800051ae:	ec06                	sd	ra,24(sp)
    800051b0:	e822                	sd	s0,16(sp)
    800051b2:	e426                	sd	s1,8(sp)
    800051b4:	1000                	addi	s0,sp,32
    800051b6:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800051b8:	ffffc097          	auipc	ra,0xffffc
    800051bc:	7f4080e7          	jalr	2036(ra) # 800019ac <myproc>
    800051c0:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800051c2:	0d050793          	addi	a5,a0,208
    800051c6:	4501                	li	a0,0
    800051c8:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800051ca:	6398                	ld	a4,0(a5)
    800051cc:	cb19                	beqz	a4,800051e2 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800051ce:	2505                	addiw	a0,a0,1
    800051d0:	07a1                	addi	a5,a5,8
    800051d2:	fed51ce3          	bne	a0,a3,800051ca <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800051d6:	557d                	li	a0,-1
}
    800051d8:	60e2                	ld	ra,24(sp)
    800051da:	6442                	ld	s0,16(sp)
    800051dc:	64a2                	ld	s1,8(sp)
    800051de:	6105                	addi	sp,sp,32
    800051e0:	8082                	ret
      p->ofile[fd] = f;
    800051e2:	01a50793          	addi	a5,a0,26
    800051e6:	078e                	slli	a5,a5,0x3
    800051e8:	963e                	add	a2,a2,a5
    800051ea:	e204                	sd	s1,0(a2)
      return fd;
    800051ec:	b7f5                	j	800051d8 <fdalloc+0x2c>

00000000800051ee <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800051ee:	715d                	addi	sp,sp,-80
    800051f0:	e486                	sd	ra,72(sp)
    800051f2:	e0a2                	sd	s0,64(sp)
    800051f4:	fc26                	sd	s1,56(sp)
    800051f6:	f84a                	sd	s2,48(sp)
    800051f8:	f44e                	sd	s3,40(sp)
    800051fa:	f052                	sd	s4,32(sp)
    800051fc:	ec56                	sd	s5,24(sp)
    800051fe:	e85a                	sd	s6,16(sp)
    80005200:	0880                	addi	s0,sp,80
    80005202:	8b2e                	mv	s6,a1
    80005204:	89b2                	mv	s3,a2
    80005206:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005208:	fb040593          	addi	a1,s0,-80
    8000520c:	fffff097          	auipc	ra,0xfffff
    80005210:	e3e080e7          	jalr	-450(ra) # 8000404a <nameiparent>
    80005214:	84aa                	mv	s1,a0
    80005216:	14050f63          	beqz	a0,80005374 <create+0x186>
    return 0;

  ilock(dp);
    8000521a:	ffffe097          	auipc	ra,0xffffe
    8000521e:	666080e7          	jalr	1638(ra) # 80003880 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005222:	4601                	li	a2,0
    80005224:	fb040593          	addi	a1,s0,-80
    80005228:	8526                	mv	a0,s1
    8000522a:	fffff097          	auipc	ra,0xfffff
    8000522e:	b3a080e7          	jalr	-1222(ra) # 80003d64 <dirlookup>
    80005232:	8aaa                	mv	s5,a0
    80005234:	c931                	beqz	a0,80005288 <create+0x9a>
    iunlockput(dp);
    80005236:	8526                	mv	a0,s1
    80005238:	fffff097          	auipc	ra,0xfffff
    8000523c:	8aa080e7          	jalr	-1878(ra) # 80003ae2 <iunlockput>
    ilock(ip);
    80005240:	8556                	mv	a0,s5
    80005242:	ffffe097          	auipc	ra,0xffffe
    80005246:	63e080e7          	jalr	1598(ra) # 80003880 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000524a:	000b059b          	sext.w	a1,s6
    8000524e:	4789                	li	a5,2
    80005250:	02f59563          	bne	a1,a5,8000527a <create+0x8c>
    80005254:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffd4dac>
    80005258:	37f9                	addiw	a5,a5,-2
    8000525a:	17c2                	slli	a5,a5,0x30
    8000525c:	93c1                	srli	a5,a5,0x30
    8000525e:	4705                	li	a4,1
    80005260:	00f76d63          	bltu	a4,a5,8000527a <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005264:	8556                	mv	a0,s5
    80005266:	60a6                	ld	ra,72(sp)
    80005268:	6406                	ld	s0,64(sp)
    8000526a:	74e2                	ld	s1,56(sp)
    8000526c:	7942                	ld	s2,48(sp)
    8000526e:	79a2                	ld	s3,40(sp)
    80005270:	7a02                	ld	s4,32(sp)
    80005272:	6ae2                	ld	s5,24(sp)
    80005274:	6b42                	ld	s6,16(sp)
    80005276:	6161                	addi	sp,sp,80
    80005278:	8082                	ret
    iunlockput(ip);
    8000527a:	8556                	mv	a0,s5
    8000527c:	fffff097          	auipc	ra,0xfffff
    80005280:	866080e7          	jalr	-1946(ra) # 80003ae2 <iunlockput>
    return 0;
    80005284:	4a81                	li	s5,0
    80005286:	bff9                	j	80005264 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005288:	85da                	mv	a1,s6
    8000528a:	4088                	lw	a0,0(s1)
    8000528c:	ffffe097          	auipc	ra,0xffffe
    80005290:	456080e7          	jalr	1110(ra) # 800036e2 <ialloc>
    80005294:	8a2a                	mv	s4,a0
    80005296:	c539                	beqz	a0,800052e4 <create+0xf6>
  ilock(ip);
    80005298:	ffffe097          	auipc	ra,0xffffe
    8000529c:	5e8080e7          	jalr	1512(ra) # 80003880 <ilock>
  ip->major = major;
    800052a0:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800052a4:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800052a8:	4905                	li	s2,1
    800052aa:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    800052ae:	8552                	mv	a0,s4
    800052b0:	ffffe097          	auipc	ra,0xffffe
    800052b4:	504080e7          	jalr	1284(ra) # 800037b4 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800052b8:	000b059b          	sext.w	a1,s6
    800052bc:	03258b63          	beq	a1,s2,800052f2 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    800052c0:	004a2603          	lw	a2,4(s4)
    800052c4:	fb040593          	addi	a1,s0,-80
    800052c8:	8526                	mv	a0,s1
    800052ca:	fffff097          	auipc	ra,0xfffff
    800052ce:	cb0080e7          	jalr	-848(ra) # 80003f7a <dirlink>
    800052d2:	06054f63          	bltz	a0,80005350 <create+0x162>
  iunlockput(dp);
    800052d6:	8526                	mv	a0,s1
    800052d8:	fffff097          	auipc	ra,0xfffff
    800052dc:	80a080e7          	jalr	-2038(ra) # 80003ae2 <iunlockput>
  return ip;
    800052e0:	8ad2                	mv	s5,s4
    800052e2:	b749                	j	80005264 <create+0x76>
    iunlockput(dp);
    800052e4:	8526                	mv	a0,s1
    800052e6:	ffffe097          	auipc	ra,0xffffe
    800052ea:	7fc080e7          	jalr	2044(ra) # 80003ae2 <iunlockput>
    return 0;
    800052ee:	8ad2                	mv	s5,s4
    800052f0:	bf95                	j	80005264 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800052f2:	004a2603          	lw	a2,4(s4)
    800052f6:	00003597          	auipc	a1,0x3
    800052fa:	5f258593          	addi	a1,a1,1522 # 800088e8 <syscalls+0x2c8>
    800052fe:	8552                	mv	a0,s4
    80005300:	fffff097          	auipc	ra,0xfffff
    80005304:	c7a080e7          	jalr	-902(ra) # 80003f7a <dirlink>
    80005308:	04054463          	bltz	a0,80005350 <create+0x162>
    8000530c:	40d0                	lw	a2,4(s1)
    8000530e:	00003597          	auipc	a1,0x3
    80005312:	5e258593          	addi	a1,a1,1506 # 800088f0 <syscalls+0x2d0>
    80005316:	8552                	mv	a0,s4
    80005318:	fffff097          	auipc	ra,0xfffff
    8000531c:	c62080e7          	jalr	-926(ra) # 80003f7a <dirlink>
    80005320:	02054863          	bltz	a0,80005350 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    80005324:	004a2603          	lw	a2,4(s4)
    80005328:	fb040593          	addi	a1,s0,-80
    8000532c:	8526                	mv	a0,s1
    8000532e:	fffff097          	auipc	ra,0xfffff
    80005332:	c4c080e7          	jalr	-948(ra) # 80003f7a <dirlink>
    80005336:	00054d63          	bltz	a0,80005350 <create+0x162>
    dp->nlink++;  // for ".."
    8000533a:	04a4d783          	lhu	a5,74(s1)
    8000533e:	2785                	addiw	a5,a5,1
    80005340:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005344:	8526                	mv	a0,s1
    80005346:	ffffe097          	auipc	ra,0xffffe
    8000534a:	46e080e7          	jalr	1134(ra) # 800037b4 <iupdate>
    8000534e:	b761                	j	800052d6 <create+0xe8>
  ip->nlink = 0;
    80005350:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005354:	8552                	mv	a0,s4
    80005356:	ffffe097          	auipc	ra,0xffffe
    8000535a:	45e080e7          	jalr	1118(ra) # 800037b4 <iupdate>
  iunlockput(ip);
    8000535e:	8552                	mv	a0,s4
    80005360:	ffffe097          	auipc	ra,0xffffe
    80005364:	782080e7          	jalr	1922(ra) # 80003ae2 <iunlockput>
  iunlockput(dp);
    80005368:	8526                	mv	a0,s1
    8000536a:	ffffe097          	auipc	ra,0xffffe
    8000536e:	778080e7          	jalr	1912(ra) # 80003ae2 <iunlockput>
  return 0;
    80005372:	bdcd                	j	80005264 <create+0x76>
    return 0;
    80005374:	8aaa                	mv	s5,a0
    80005376:	b5fd                	j	80005264 <create+0x76>

0000000080005378 <sys_dup>:
{
    80005378:	7179                	addi	sp,sp,-48
    8000537a:	f406                	sd	ra,40(sp)
    8000537c:	f022                	sd	s0,32(sp)
    8000537e:	ec26                	sd	s1,24(sp)
    80005380:	e84a                	sd	s2,16(sp)
    80005382:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005384:	fd840613          	addi	a2,s0,-40
    80005388:	4581                	li	a1,0
    8000538a:	4501                	li	a0,0
    8000538c:	00000097          	auipc	ra,0x0
    80005390:	dc0080e7          	jalr	-576(ra) # 8000514c <argfd>
    return -1;
    80005394:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005396:	02054363          	bltz	a0,800053bc <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    8000539a:	fd843903          	ld	s2,-40(s0)
    8000539e:	854a                	mv	a0,s2
    800053a0:	00000097          	auipc	ra,0x0
    800053a4:	e0c080e7          	jalr	-500(ra) # 800051ac <fdalloc>
    800053a8:	84aa                	mv	s1,a0
    return -1;
    800053aa:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800053ac:	00054863          	bltz	a0,800053bc <sys_dup+0x44>
  filedup(f);
    800053b0:	854a                	mv	a0,s2
    800053b2:	fffff097          	auipc	ra,0xfffff
    800053b6:	310080e7          	jalr	784(ra) # 800046c2 <filedup>
  return fd;
    800053ba:	87a6                	mv	a5,s1
}
    800053bc:	853e                	mv	a0,a5
    800053be:	70a2                	ld	ra,40(sp)
    800053c0:	7402                	ld	s0,32(sp)
    800053c2:	64e2                	ld	s1,24(sp)
    800053c4:	6942                	ld	s2,16(sp)
    800053c6:	6145                	addi	sp,sp,48
    800053c8:	8082                	ret

00000000800053ca <sys_read>:
{
    800053ca:	7179                	addi	sp,sp,-48
    800053cc:	f406                	sd	ra,40(sp)
    800053ce:	f022                	sd	s0,32(sp)
    800053d0:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800053d2:	fd840593          	addi	a1,s0,-40
    800053d6:	4505                	li	a0,1
    800053d8:	ffffd097          	auipc	ra,0xffffd
    800053dc:	7ba080e7          	jalr	1978(ra) # 80002b92 <argaddr>
  argint(2, &n);
    800053e0:	fe440593          	addi	a1,s0,-28
    800053e4:	4509                	li	a0,2
    800053e6:	ffffd097          	auipc	ra,0xffffd
    800053ea:	78c080e7          	jalr	1932(ra) # 80002b72 <argint>
  if(argfd(0, 0, &f) < 0)
    800053ee:	fe840613          	addi	a2,s0,-24
    800053f2:	4581                	li	a1,0
    800053f4:	4501                	li	a0,0
    800053f6:	00000097          	auipc	ra,0x0
    800053fa:	d56080e7          	jalr	-682(ra) # 8000514c <argfd>
    800053fe:	87aa                	mv	a5,a0
    return -1;
    80005400:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005402:	0007cc63          	bltz	a5,8000541a <sys_read+0x50>
  return fileread(f, p, n);
    80005406:	fe442603          	lw	a2,-28(s0)
    8000540a:	fd843583          	ld	a1,-40(s0)
    8000540e:	fe843503          	ld	a0,-24(s0)
    80005412:	fffff097          	auipc	ra,0xfffff
    80005416:	43c080e7          	jalr	1084(ra) # 8000484e <fileread>
}
    8000541a:	70a2                	ld	ra,40(sp)
    8000541c:	7402                	ld	s0,32(sp)
    8000541e:	6145                	addi	sp,sp,48
    80005420:	8082                	ret

0000000080005422 <sys_write>:
{
    80005422:	7179                	addi	sp,sp,-48
    80005424:	f406                	sd	ra,40(sp)
    80005426:	f022                	sd	s0,32(sp)
    80005428:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000542a:	fd840593          	addi	a1,s0,-40
    8000542e:	4505                	li	a0,1
    80005430:	ffffd097          	auipc	ra,0xffffd
    80005434:	762080e7          	jalr	1890(ra) # 80002b92 <argaddr>
  argint(2, &n);
    80005438:	fe440593          	addi	a1,s0,-28
    8000543c:	4509                	li	a0,2
    8000543e:	ffffd097          	auipc	ra,0xffffd
    80005442:	734080e7          	jalr	1844(ra) # 80002b72 <argint>
  if(argfd(0, 0, &f) < 0)
    80005446:	fe840613          	addi	a2,s0,-24
    8000544a:	4581                	li	a1,0
    8000544c:	4501                	li	a0,0
    8000544e:	00000097          	auipc	ra,0x0
    80005452:	cfe080e7          	jalr	-770(ra) # 8000514c <argfd>
    80005456:	87aa                	mv	a5,a0
    return -1;
    80005458:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000545a:	0007cc63          	bltz	a5,80005472 <sys_write+0x50>
  return filewrite(f, p, n);
    8000545e:	fe442603          	lw	a2,-28(s0)
    80005462:	fd843583          	ld	a1,-40(s0)
    80005466:	fe843503          	ld	a0,-24(s0)
    8000546a:	fffff097          	auipc	ra,0xfffff
    8000546e:	4a6080e7          	jalr	1190(ra) # 80004910 <filewrite>
}
    80005472:	70a2                	ld	ra,40(sp)
    80005474:	7402                	ld	s0,32(sp)
    80005476:	6145                	addi	sp,sp,48
    80005478:	8082                	ret

000000008000547a <sys_close>:
{
    8000547a:	1101                	addi	sp,sp,-32
    8000547c:	ec06                	sd	ra,24(sp)
    8000547e:	e822                	sd	s0,16(sp)
    80005480:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005482:	fe040613          	addi	a2,s0,-32
    80005486:	fec40593          	addi	a1,s0,-20
    8000548a:	4501                	li	a0,0
    8000548c:	00000097          	auipc	ra,0x0
    80005490:	cc0080e7          	jalr	-832(ra) # 8000514c <argfd>
    return -1;
    80005494:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005496:	02054463          	bltz	a0,800054be <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000549a:	ffffc097          	auipc	ra,0xffffc
    8000549e:	512080e7          	jalr	1298(ra) # 800019ac <myproc>
    800054a2:	fec42783          	lw	a5,-20(s0)
    800054a6:	07e9                	addi	a5,a5,26
    800054a8:	078e                	slli	a5,a5,0x3
    800054aa:	953e                	add	a0,a0,a5
    800054ac:	00053023          	sd	zero,0(a0)
  fileclose(f);
    800054b0:	fe043503          	ld	a0,-32(s0)
    800054b4:	fffff097          	auipc	ra,0xfffff
    800054b8:	260080e7          	jalr	608(ra) # 80004714 <fileclose>
  return 0;
    800054bc:	4781                	li	a5,0
}
    800054be:	853e                	mv	a0,a5
    800054c0:	60e2                	ld	ra,24(sp)
    800054c2:	6442                	ld	s0,16(sp)
    800054c4:	6105                	addi	sp,sp,32
    800054c6:	8082                	ret

00000000800054c8 <sys_fstat>:
{
    800054c8:	1101                	addi	sp,sp,-32
    800054ca:	ec06                	sd	ra,24(sp)
    800054cc:	e822                	sd	s0,16(sp)
    800054ce:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800054d0:	fe040593          	addi	a1,s0,-32
    800054d4:	4505                	li	a0,1
    800054d6:	ffffd097          	auipc	ra,0xffffd
    800054da:	6bc080e7          	jalr	1724(ra) # 80002b92 <argaddr>
  if(argfd(0, 0, &f) < 0)
    800054de:	fe840613          	addi	a2,s0,-24
    800054e2:	4581                	li	a1,0
    800054e4:	4501                	li	a0,0
    800054e6:	00000097          	auipc	ra,0x0
    800054ea:	c66080e7          	jalr	-922(ra) # 8000514c <argfd>
    800054ee:	87aa                	mv	a5,a0
    return -1;
    800054f0:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800054f2:	0007ca63          	bltz	a5,80005506 <sys_fstat+0x3e>
  return filestat(f, st);
    800054f6:	fe043583          	ld	a1,-32(s0)
    800054fa:	fe843503          	ld	a0,-24(s0)
    800054fe:	fffff097          	auipc	ra,0xfffff
    80005502:	2de080e7          	jalr	734(ra) # 800047dc <filestat>
}
    80005506:	60e2                	ld	ra,24(sp)
    80005508:	6442                	ld	s0,16(sp)
    8000550a:	6105                	addi	sp,sp,32
    8000550c:	8082                	ret

000000008000550e <sys_link>:
{
    8000550e:	7169                	addi	sp,sp,-304
    80005510:	f606                	sd	ra,296(sp)
    80005512:	f222                	sd	s0,288(sp)
    80005514:	ee26                	sd	s1,280(sp)
    80005516:	ea4a                	sd	s2,272(sp)
    80005518:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000551a:	08000613          	li	a2,128
    8000551e:	ed040593          	addi	a1,s0,-304
    80005522:	4501                	li	a0,0
    80005524:	ffffd097          	auipc	ra,0xffffd
    80005528:	68e080e7          	jalr	1678(ra) # 80002bb2 <argstr>
    return -1;
    8000552c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000552e:	10054e63          	bltz	a0,8000564a <sys_link+0x13c>
    80005532:	08000613          	li	a2,128
    80005536:	f5040593          	addi	a1,s0,-176
    8000553a:	4505                	li	a0,1
    8000553c:	ffffd097          	auipc	ra,0xffffd
    80005540:	676080e7          	jalr	1654(ra) # 80002bb2 <argstr>
    return -1;
    80005544:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005546:	10054263          	bltz	a0,8000564a <sys_link+0x13c>
  begin_op();
    8000554a:	fffff097          	auipc	ra,0xfffff
    8000554e:	d02080e7          	jalr	-766(ra) # 8000424c <begin_op>
  if((ip = namei(old)) == 0){
    80005552:	ed040513          	addi	a0,s0,-304
    80005556:	fffff097          	auipc	ra,0xfffff
    8000555a:	ad6080e7          	jalr	-1322(ra) # 8000402c <namei>
    8000555e:	84aa                	mv	s1,a0
    80005560:	c551                	beqz	a0,800055ec <sys_link+0xde>
  ilock(ip);
    80005562:	ffffe097          	auipc	ra,0xffffe
    80005566:	31e080e7          	jalr	798(ra) # 80003880 <ilock>
  if(ip->type == T_DIR){
    8000556a:	04449703          	lh	a4,68(s1)
    8000556e:	4785                	li	a5,1
    80005570:	08f70463          	beq	a4,a5,800055f8 <sys_link+0xea>
  ip->nlink++;
    80005574:	04a4d783          	lhu	a5,74(s1)
    80005578:	2785                	addiw	a5,a5,1
    8000557a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000557e:	8526                	mv	a0,s1
    80005580:	ffffe097          	auipc	ra,0xffffe
    80005584:	234080e7          	jalr	564(ra) # 800037b4 <iupdate>
  iunlock(ip);
    80005588:	8526                	mv	a0,s1
    8000558a:	ffffe097          	auipc	ra,0xffffe
    8000558e:	3b8080e7          	jalr	952(ra) # 80003942 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005592:	fd040593          	addi	a1,s0,-48
    80005596:	f5040513          	addi	a0,s0,-176
    8000559a:	fffff097          	auipc	ra,0xfffff
    8000559e:	ab0080e7          	jalr	-1360(ra) # 8000404a <nameiparent>
    800055a2:	892a                	mv	s2,a0
    800055a4:	c935                	beqz	a0,80005618 <sys_link+0x10a>
  ilock(dp);
    800055a6:	ffffe097          	auipc	ra,0xffffe
    800055aa:	2da080e7          	jalr	730(ra) # 80003880 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800055ae:	00092703          	lw	a4,0(s2)
    800055b2:	409c                	lw	a5,0(s1)
    800055b4:	04f71d63          	bne	a4,a5,8000560e <sys_link+0x100>
    800055b8:	40d0                	lw	a2,4(s1)
    800055ba:	fd040593          	addi	a1,s0,-48
    800055be:	854a                	mv	a0,s2
    800055c0:	fffff097          	auipc	ra,0xfffff
    800055c4:	9ba080e7          	jalr	-1606(ra) # 80003f7a <dirlink>
    800055c8:	04054363          	bltz	a0,8000560e <sys_link+0x100>
  iunlockput(dp);
    800055cc:	854a                	mv	a0,s2
    800055ce:	ffffe097          	auipc	ra,0xffffe
    800055d2:	514080e7          	jalr	1300(ra) # 80003ae2 <iunlockput>
  iput(ip);
    800055d6:	8526                	mv	a0,s1
    800055d8:	ffffe097          	auipc	ra,0xffffe
    800055dc:	462080e7          	jalr	1122(ra) # 80003a3a <iput>
  end_op();
    800055e0:	fffff097          	auipc	ra,0xfffff
    800055e4:	cea080e7          	jalr	-790(ra) # 800042ca <end_op>
  return 0;
    800055e8:	4781                	li	a5,0
    800055ea:	a085                	j	8000564a <sys_link+0x13c>
    end_op();
    800055ec:	fffff097          	auipc	ra,0xfffff
    800055f0:	cde080e7          	jalr	-802(ra) # 800042ca <end_op>
    return -1;
    800055f4:	57fd                	li	a5,-1
    800055f6:	a891                	j	8000564a <sys_link+0x13c>
    iunlockput(ip);
    800055f8:	8526                	mv	a0,s1
    800055fa:	ffffe097          	auipc	ra,0xffffe
    800055fe:	4e8080e7          	jalr	1256(ra) # 80003ae2 <iunlockput>
    end_op();
    80005602:	fffff097          	auipc	ra,0xfffff
    80005606:	cc8080e7          	jalr	-824(ra) # 800042ca <end_op>
    return -1;
    8000560a:	57fd                	li	a5,-1
    8000560c:	a83d                	j	8000564a <sys_link+0x13c>
    iunlockput(dp);
    8000560e:	854a                	mv	a0,s2
    80005610:	ffffe097          	auipc	ra,0xffffe
    80005614:	4d2080e7          	jalr	1234(ra) # 80003ae2 <iunlockput>
  ilock(ip);
    80005618:	8526                	mv	a0,s1
    8000561a:	ffffe097          	auipc	ra,0xffffe
    8000561e:	266080e7          	jalr	614(ra) # 80003880 <ilock>
  ip->nlink--;
    80005622:	04a4d783          	lhu	a5,74(s1)
    80005626:	37fd                	addiw	a5,a5,-1
    80005628:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000562c:	8526                	mv	a0,s1
    8000562e:	ffffe097          	auipc	ra,0xffffe
    80005632:	186080e7          	jalr	390(ra) # 800037b4 <iupdate>
  iunlockput(ip);
    80005636:	8526                	mv	a0,s1
    80005638:	ffffe097          	auipc	ra,0xffffe
    8000563c:	4aa080e7          	jalr	1194(ra) # 80003ae2 <iunlockput>
  end_op();
    80005640:	fffff097          	auipc	ra,0xfffff
    80005644:	c8a080e7          	jalr	-886(ra) # 800042ca <end_op>
  return -1;
    80005648:	57fd                	li	a5,-1
}
    8000564a:	853e                	mv	a0,a5
    8000564c:	70b2                	ld	ra,296(sp)
    8000564e:	7412                	ld	s0,288(sp)
    80005650:	64f2                	ld	s1,280(sp)
    80005652:	6952                	ld	s2,272(sp)
    80005654:	6155                	addi	sp,sp,304
    80005656:	8082                	ret

0000000080005658 <sys_unlink>:
{
    80005658:	7151                	addi	sp,sp,-240
    8000565a:	f586                	sd	ra,232(sp)
    8000565c:	f1a2                	sd	s0,224(sp)
    8000565e:	eda6                	sd	s1,216(sp)
    80005660:	e9ca                	sd	s2,208(sp)
    80005662:	e5ce                	sd	s3,200(sp)
    80005664:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005666:	08000613          	li	a2,128
    8000566a:	f3040593          	addi	a1,s0,-208
    8000566e:	4501                	li	a0,0
    80005670:	ffffd097          	auipc	ra,0xffffd
    80005674:	542080e7          	jalr	1346(ra) # 80002bb2 <argstr>
    80005678:	18054163          	bltz	a0,800057fa <sys_unlink+0x1a2>
  begin_op();
    8000567c:	fffff097          	auipc	ra,0xfffff
    80005680:	bd0080e7          	jalr	-1072(ra) # 8000424c <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005684:	fb040593          	addi	a1,s0,-80
    80005688:	f3040513          	addi	a0,s0,-208
    8000568c:	fffff097          	auipc	ra,0xfffff
    80005690:	9be080e7          	jalr	-1602(ra) # 8000404a <nameiparent>
    80005694:	84aa                	mv	s1,a0
    80005696:	c979                	beqz	a0,8000576c <sys_unlink+0x114>
  ilock(dp);
    80005698:	ffffe097          	auipc	ra,0xffffe
    8000569c:	1e8080e7          	jalr	488(ra) # 80003880 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800056a0:	00003597          	auipc	a1,0x3
    800056a4:	24858593          	addi	a1,a1,584 # 800088e8 <syscalls+0x2c8>
    800056a8:	fb040513          	addi	a0,s0,-80
    800056ac:	ffffe097          	auipc	ra,0xffffe
    800056b0:	69e080e7          	jalr	1694(ra) # 80003d4a <namecmp>
    800056b4:	14050a63          	beqz	a0,80005808 <sys_unlink+0x1b0>
    800056b8:	00003597          	auipc	a1,0x3
    800056bc:	23858593          	addi	a1,a1,568 # 800088f0 <syscalls+0x2d0>
    800056c0:	fb040513          	addi	a0,s0,-80
    800056c4:	ffffe097          	auipc	ra,0xffffe
    800056c8:	686080e7          	jalr	1670(ra) # 80003d4a <namecmp>
    800056cc:	12050e63          	beqz	a0,80005808 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800056d0:	f2c40613          	addi	a2,s0,-212
    800056d4:	fb040593          	addi	a1,s0,-80
    800056d8:	8526                	mv	a0,s1
    800056da:	ffffe097          	auipc	ra,0xffffe
    800056de:	68a080e7          	jalr	1674(ra) # 80003d64 <dirlookup>
    800056e2:	892a                	mv	s2,a0
    800056e4:	12050263          	beqz	a0,80005808 <sys_unlink+0x1b0>
  ilock(ip);
    800056e8:	ffffe097          	auipc	ra,0xffffe
    800056ec:	198080e7          	jalr	408(ra) # 80003880 <ilock>
  if(ip->nlink < 1)
    800056f0:	04a91783          	lh	a5,74(s2)
    800056f4:	08f05263          	blez	a5,80005778 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800056f8:	04491703          	lh	a4,68(s2)
    800056fc:	4785                	li	a5,1
    800056fe:	08f70563          	beq	a4,a5,80005788 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005702:	4641                	li	a2,16
    80005704:	4581                	li	a1,0
    80005706:	fc040513          	addi	a0,s0,-64
    8000570a:	ffffb097          	auipc	ra,0xffffb
    8000570e:	5c8080e7          	jalr	1480(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005712:	4741                	li	a4,16
    80005714:	f2c42683          	lw	a3,-212(s0)
    80005718:	fc040613          	addi	a2,s0,-64
    8000571c:	4581                	li	a1,0
    8000571e:	8526                	mv	a0,s1
    80005720:	ffffe097          	auipc	ra,0xffffe
    80005724:	50c080e7          	jalr	1292(ra) # 80003c2c <writei>
    80005728:	47c1                	li	a5,16
    8000572a:	0af51563          	bne	a0,a5,800057d4 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000572e:	04491703          	lh	a4,68(s2)
    80005732:	4785                	li	a5,1
    80005734:	0af70863          	beq	a4,a5,800057e4 <sys_unlink+0x18c>
  iunlockput(dp);
    80005738:	8526                	mv	a0,s1
    8000573a:	ffffe097          	auipc	ra,0xffffe
    8000573e:	3a8080e7          	jalr	936(ra) # 80003ae2 <iunlockput>
  ip->nlink--;
    80005742:	04a95783          	lhu	a5,74(s2)
    80005746:	37fd                	addiw	a5,a5,-1
    80005748:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000574c:	854a                	mv	a0,s2
    8000574e:	ffffe097          	auipc	ra,0xffffe
    80005752:	066080e7          	jalr	102(ra) # 800037b4 <iupdate>
  iunlockput(ip);
    80005756:	854a                	mv	a0,s2
    80005758:	ffffe097          	auipc	ra,0xffffe
    8000575c:	38a080e7          	jalr	906(ra) # 80003ae2 <iunlockput>
  end_op();
    80005760:	fffff097          	auipc	ra,0xfffff
    80005764:	b6a080e7          	jalr	-1174(ra) # 800042ca <end_op>
  return 0;
    80005768:	4501                	li	a0,0
    8000576a:	a84d                	j	8000581c <sys_unlink+0x1c4>
    end_op();
    8000576c:	fffff097          	auipc	ra,0xfffff
    80005770:	b5e080e7          	jalr	-1186(ra) # 800042ca <end_op>
    return -1;
    80005774:	557d                	li	a0,-1
    80005776:	a05d                	j	8000581c <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005778:	00003517          	auipc	a0,0x3
    8000577c:	18050513          	addi	a0,a0,384 # 800088f8 <syscalls+0x2d8>
    80005780:	ffffb097          	auipc	ra,0xffffb
    80005784:	dc0080e7          	jalr	-576(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005788:	04c92703          	lw	a4,76(s2)
    8000578c:	02000793          	li	a5,32
    80005790:	f6e7f9e3          	bgeu	a5,a4,80005702 <sys_unlink+0xaa>
    80005794:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005798:	4741                	li	a4,16
    8000579a:	86ce                	mv	a3,s3
    8000579c:	f1840613          	addi	a2,s0,-232
    800057a0:	4581                	li	a1,0
    800057a2:	854a                	mv	a0,s2
    800057a4:	ffffe097          	auipc	ra,0xffffe
    800057a8:	390080e7          	jalr	912(ra) # 80003b34 <readi>
    800057ac:	47c1                	li	a5,16
    800057ae:	00f51b63          	bne	a0,a5,800057c4 <sys_unlink+0x16c>
    if(de.inum != 0)
    800057b2:	f1845783          	lhu	a5,-232(s0)
    800057b6:	e7a1                	bnez	a5,800057fe <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057b8:	29c1                	addiw	s3,s3,16
    800057ba:	04c92783          	lw	a5,76(s2)
    800057be:	fcf9ede3          	bltu	s3,a5,80005798 <sys_unlink+0x140>
    800057c2:	b781                	j	80005702 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800057c4:	00003517          	auipc	a0,0x3
    800057c8:	14c50513          	addi	a0,a0,332 # 80008910 <syscalls+0x2f0>
    800057cc:	ffffb097          	auipc	ra,0xffffb
    800057d0:	d74080e7          	jalr	-652(ra) # 80000540 <panic>
    panic("unlink: writei");
    800057d4:	00003517          	auipc	a0,0x3
    800057d8:	15450513          	addi	a0,a0,340 # 80008928 <syscalls+0x308>
    800057dc:	ffffb097          	auipc	ra,0xffffb
    800057e0:	d64080e7          	jalr	-668(ra) # 80000540 <panic>
    dp->nlink--;
    800057e4:	04a4d783          	lhu	a5,74(s1)
    800057e8:	37fd                	addiw	a5,a5,-1
    800057ea:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800057ee:	8526                	mv	a0,s1
    800057f0:	ffffe097          	auipc	ra,0xffffe
    800057f4:	fc4080e7          	jalr	-60(ra) # 800037b4 <iupdate>
    800057f8:	b781                	j	80005738 <sys_unlink+0xe0>
    return -1;
    800057fa:	557d                	li	a0,-1
    800057fc:	a005                	j	8000581c <sys_unlink+0x1c4>
    iunlockput(ip);
    800057fe:	854a                	mv	a0,s2
    80005800:	ffffe097          	auipc	ra,0xffffe
    80005804:	2e2080e7          	jalr	738(ra) # 80003ae2 <iunlockput>
  iunlockput(dp);
    80005808:	8526                	mv	a0,s1
    8000580a:	ffffe097          	auipc	ra,0xffffe
    8000580e:	2d8080e7          	jalr	728(ra) # 80003ae2 <iunlockput>
  end_op();
    80005812:	fffff097          	auipc	ra,0xfffff
    80005816:	ab8080e7          	jalr	-1352(ra) # 800042ca <end_op>
  return -1;
    8000581a:	557d                	li	a0,-1
}
    8000581c:	70ae                	ld	ra,232(sp)
    8000581e:	740e                	ld	s0,224(sp)
    80005820:	64ee                	ld	s1,216(sp)
    80005822:	694e                	ld	s2,208(sp)
    80005824:	69ae                	ld	s3,200(sp)
    80005826:	616d                	addi	sp,sp,240
    80005828:	8082                	ret

000000008000582a <sys_open>:

uint64
sys_open(void)
{
    8000582a:	7131                	addi	sp,sp,-192
    8000582c:	fd06                	sd	ra,184(sp)
    8000582e:	f922                	sd	s0,176(sp)
    80005830:	f526                	sd	s1,168(sp)
    80005832:	f14a                	sd	s2,160(sp)
    80005834:	ed4e                	sd	s3,152(sp)
    80005836:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005838:	f4c40593          	addi	a1,s0,-180
    8000583c:	4505                	li	a0,1
    8000583e:	ffffd097          	auipc	ra,0xffffd
    80005842:	334080e7          	jalr	820(ra) # 80002b72 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005846:	08000613          	li	a2,128
    8000584a:	f5040593          	addi	a1,s0,-176
    8000584e:	4501                	li	a0,0
    80005850:	ffffd097          	auipc	ra,0xffffd
    80005854:	362080e7          	jalr	866(ra) # 80002bb2 <argstr>
    80005858:	87aa                	mv	a5,a0
    return -1;
    8000585a:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000585c:	0a07c963          	bltz	a5,8000590e <sys_open+0xe4>

  begin_op();
    80005860:	fffff097          	auipc	ra,0xfffff
    80005864:	9ec080e7          	jalr	-1556(ra) # 8000424c <begin_op>

  if(omode & O_CREATE){
    80005868:	f4c42783          	lw	a5,-180(s0)
    8000586c:	2007f793          	andi	a5,a5,512
    80005870:	cfc5                	beqz	a5,80005928 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005872:	4681                	li	a3,0
    80005874:	4601                	li	a2,0
    80005876:	4589                	li	a1,2
    80005878:	f5040513          	addi	a0,s0,-176
    8000587c:	00000097          	auipc	ra,0x0
    80005880:	972080e7          	jalr	-1678(ra) # 800051ee <create>
    80005884:	84aa                	mv	s1,a0
    if(ip == 0){
    80005886:	c959                	beqz	a0,8000591c <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005888:	04449703          	lh	a4,68(s1)
    8000588c:	478d                	li	a5,3
    8000588e:	00f71763          	bne	a4,a5,8000589c <sys_open+0x72>
    80005892:	0464d703          	lhu	a4,70(s1)
    80005896:	47a5                	li	a5,9
    80005898:	0ce7ed63          	bltu	a5,a4,80005972 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000589c:	fffff097          	auipc	ra,0xfffff
    800058a0:	dbc080e7          	jalr	-580(ra) # 80004658 <filealloc>
    800058a4:	89aa                	mv	s3,a0
    800058a6:	10050363          	beqz	a0,800059ac <sys_open+0x182>
    800058aa:	00000097          	auipc	ra,0x0
    800058ae:	902080e7          	jalr	-1790(ra) # 800051ac <fdalloc>
    800058b2:	892a                	mv	s2,a0
    800058b4:	0e054763          	bltz	a0,800059a2 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800058b8:	04449703          	lh	a4,68(s1)
    800058bc:	478d                	li	a5,3
    800058be:	0cf70563          	beq	a4,a5,80005988 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800058c2:	4789                	li	a5,2
    800058c4:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800058c8:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800058cc:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    800058d0:	f4c42783          	lw	a5,-180(s0)
    800058d4:	0017c713          	xori	a4,a5,1
    800058d8:	8b05                	andi	a4,a4,1
    800058da:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800058de:	0037f713          	andi	a4,a5,3
    800058e2:	00e03733          	snez	a4,a4
    800058e6:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800058ea:	4007f793          	andi	a5,a5,1024
    800058ee:	c791                	beqz	a5,800058fa <sys_open+0xd0>
    800058f0:	04449703          	lh	a4,68(s1)
    800058f4:	4789                	li	a5,2
    800058f6:	0af70063          	beq	a4,a5,80005996 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800058fa:	8526                	mv	a0,s1
    800058fc:	ffffe097          	auipc	ra,0xffffe
    80005900:	046080e7          	jalr	70(ra) # 80003942 <iunlock>
  end_op();
    80005904:	fffff097          	auipc	ra,0xfffff
    80005908:	9c6080e7          	jalr	-1594(ra) # 800042ca <end_op>

  return fd;
    8000590c:	854a                	mv	a0,s2
}
    8000590e:	70ea                	ld	ra,184(sp)
    80005910:	744a                	ld	s0,176(sp)
    80005912:	74aa                	ld	s1,168(sp)
    80005914:	790a                	ld	s2,160(sp)
    80005916:	69ea                	ld	s3,152(sp)
    80005918:	6129                	addi	sp,sp,192
    8000591a:	8082                	ret
      end_op();
    8000591c:	fffff097          	auipc	ra,0xfffff
    80005920:	9ae080e7          	jalr	-1618(ra) # 800042ca <end_op>
      return -1;
    80005924:	557d                	li	a0,-1
    80005926:	b7e5                	j	8000590e <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005928:	f5040513          	addi	a0,s0,-176
    8000592c:	ffffe097          	auipc	ra,0xffffe
    80005930:	700080e7          	jalr	1792(ra) # 8000402c <namei>
    80005934:	84aa                	mv	s1,a0
    80005936:	c905                	beqz	a0,80005966 <sys_open+0x13c>
    ilock(ip);
    80005938:	ffffe097          	auipc	ra,0xffffe
    8000593c:	f48080e7          	jalr	-184(ra) # 80003880 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005940:	04449703          	lh	a4,68(s1)
    80005944:	4785                	li	a5,1
    80005946:	f4f711e3          	bne	a4,a5,80005888 <sys_open+0x5e>
    8000594a:	f4c42783          	lw	a5,-180(s0)
    8000594e:	d7b9                	beqz	a5,8000589c <sys_open+0x72>
      iunlockput(ip);
    80005950:	8526                	mv	a0,s1
    80005952:	ffffe097          	auipc	ra,0xffffe
    80005956:	190080e7          	jalr	400(ra) # 80003ae2 <iunlockput>
      end_op();
    8000595a:	fffff097          	auipc	ra,0xfffff
    8000595e:	970080e7          	jalr	-1680(ra) # 800042ca <end_op>
      return -1;
    80005962:	557d                	li	a0,-1
    80005964:	b76d                	j	8000590e <sys_open+0xe4>
      end_op();
    80005966:	fffff097          	auipc	ra,0xfffff
    8000596a:	964080e7          	jalr	-1692(ra) # 800042ca <end_op>
      return -1;
    8000596e:	557d                	li	a0,-1
    80005970:	bf79                	j	8000590e <sys_open+0xe4>
    iunlockput(ip);
    80005972:	8526                	mv	a0,s1
    80005974:	ffffe097          	auipc	ra,0xffffe
    80005978:	16e080e7          	jalr	366(ra) # 80003ae2 <iunlockput>
    end_op();
    8000597c:	fffff097          	auipc	ra,0xfffff
    80005980:	94e080e7          	jalr	-1714(ra) # 800042ca <end_op>
    return -1;
    80005984:	557d                	li	a0,-1
    80005986:	b761                	j	8000590e <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005988:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000598c:	04649783          	lh	a5,70(s1)
    80005990:	02f99223          	sh	a5,36(s3)
    80005994:	bf25                	j	800058cc <sys_open+0xa2>
    itrunc(ip);
    80005996:	8526                	mv	a0,s1
    80005998:	ffffe097          	auipc	ra,0xffffe
    8000599c:	ff6080e7          	jalr	-10(ra) # 8000398e <itrunc>
    800059a0:	bfa9                	j	800058fa <sys_open+0xd0>
      fileclose(f);
    800059a2:	854e                	mv	a0,s3
    800059a4:	fffff097          	auipc	ra,0xfffff
    800059a8:	d70080e7          	jalr	-656(ra) # 80004714 <fileclose>
    iunlockput(ip);
    800059ac:	8526                	mv	a0,s1
    800059ae:	ffffe097          	auipc	ra,0xffffe
    800059b2:	134080e7          	jalr	308(ra) # 80003ae2 <iunlockput>
    end_op();
    800059b6:	fffff097          	auipc	ra,0xfffff
    800059ba:	914080e7          	jalr	-1772(ra) # 800042ca <end_op>
    return -1;
    800059be:	557d                	li	a0,-1
    800059c0:	b7b9                	j	8000590e <sys_open+0xe4>

00000000800059c2 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800059c2:	7175                	addi	sp,sp,-144
    800059c4:	e506                	sd	ra,136(sp)
    800059c6:	e122                	sd	s0,128(sp)
    800059c8:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800059ca:	fffff097          	auipc	ra,0xfffff
    800059ce:	882080e7          	jalr	-1918(ra) # 8000424c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800059d2:	08000613          	li	a2,128
    800059d6:	f7040593          	addi	a1,s0,-144
    800059da:	4501                	li	a0,0
    800059dc:	ffffd097          	auipc	ra,0xffffd
    800059e0:	1d6080e7          	jalr	470(ra) # 80002bb2 <argstr>
    800059e4:	02054963          	bltz	a0,80005a16 <sys_mkdir+0x54>
    800059e8:	4681                	li	a3,0
    800059ea:	4601                	li	a2,0
    800059ec:	4585                	li	a1,1
    800059ee:	f7040513          	addi	a0,s0,-144
    800059f2:	fffff097          	auipc	ra,0xfffff
    800059f6:	7fc080e7          	jalr	2044(ra) # 800051ee <create>
    800059fa:	cd11                	beqz	a0,80005a16 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800059fc:	ffffe097          	auipc	ra,0xffffe
    80005a00:	0e6080e7          	jalr	230(ra) # 80003ae2 <iunlockput>
  end_op();
    80005a04:	fffff097          	auipc	ra,0xfffff
    80005a08:	8c6080e7          	jalr	-1850(ra) # 800042ca <end_op>
  return 0;
    80005a0c:	4501                	li	a0,0
}
    80005a0e:	60aa                	ld	ra,136(sp)
    80005a10:	640a                	ld	s0,128(sp)
    80005a12:	6149                	addi	sp,sp,144
    80005a14:	8082                	ret
    end_op();
    80005a16:	fffff097          	auipc	ra,0xfffff
    80005a1a:	8b4080e7          	jalr	-1868(ra) # 800042ca <end_op>
    return -1;
    80005a1e:	557d                	li	a0,-1
    80005a20:	b7fd                	j	80005a0e <sys_mkdir+0x4c>

0000000080005a22 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005a22:	7135                	addi	sp,sp,-160
    80005a24:	ed06                	sd	ra,152(sp)
    80005a26:	e922                	sd	s0,144(sp)
    80005a28:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005a2a:	fffff097          	auipc	ra,0xfffff
    80005a2e:	822080e7          	jalr	-2014(ra) # 8000424c <begin_op>
  argint(1, &major);
    80005a32:	f6c40593          	addi	a1,s0,-148
    80005a36:	4505                	li	a0,1
    80005a38:	ffffd097          	auipc	ra,0xffffd
    80005a3c:	13a080e7          	jalr	314(ra) # 80002b72 <argint>
  argint(2, &minor);
    80005a40:	f6840593          	addi	a1,s0,-152
    80005a44:	4509                	li	a0,2
    80005a46:	ffffd097          	auipc	ra,0xffffd
    80005a4a:	12c080e7          	jalr	300(ra) # 80002b72 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a4e:	08000613          	li	a2,128
    80005a52:	f7040593          	addi	a1,s0,-144
    80005a56:	4501                	li	a0,0
    80005a58:	ffffd097          	auipc	ra,0xffffd
    80005a5c:	15a080e7          	jalr	346(ra) # 80002bb2 <argstr>
    80005a60:	02054b63          	bltz	a0,80005a96 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005a64:	f6841683          	lh	a3,-152(s0)
    80005a68:	f6c41603          	lh	a2,-148(s0)
    80005a6c:	458d                	li	a1,3
    80005a6e:	f7040513          	addi	a0,s0,-144
    80005a72:	fffff097          	auipc	ra,0xfffff
    80005a76:	77c080e7          	jalr	1916(ra) # 800051ee <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a7a:	cd11                	beqz	a0,80005a96 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a7c:	ffffe097          	auipc	ra,0xffffe
    80005a80:	066080e7          	jalr	102(ra) # 80003ae2 <iunlockput>
  end_op();
    80005a84:	fffff097          	auipc	ra,0xfffff
    80005a88:	846080e7          	jalr	-1978(ra) # 800042ca <end_op>
  return 0;
    80005a8c:	4501                	li	a0,0
}
    80005a8e:	60ea                	ld	ra,152(sp)
    80005a90:	644a                	ld	s0,144(sp)
    80005a92:	610d                	addi	sp,sp,160
    80005a94:	8082                	ret
    end_op();
    80005a96:	fffff097          	auipc	ra,0xfffff
    80005a9a:	834080e7          	jalr	-1996(ra) # 800042ca <end_op>
    return -1;
    80005a9e:	557d                	li	a0,-1
    80005aa0:	b7fd                	j	80005a8e <sys_mknod+0x6c>

0000000080005aa2 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005aa2:	7135                	addi	sp,sp,-160
    80005aa4:	ed06                	sd	ra,152(sp)
    80005aa6:	e922                	sd	s0,144(sp)
    80005aa8:	e526                	sd	s1,136(sp)
    80005aaa:	e14a                	sd	s2,128(sp)
    80005aac:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005aae:	ffffc097          	auipc	ra,0xffffc
    80005ab2:	efe080e7          	jalr	-258(ra) # 800019ac <myproc>
    80005ab6:	892a                	mv	s2,a0
  
  begin_op();
    80005ab8:	ffffe097          	auipc	ra,0xffffe
    80005abc:	794080e7          	jalr	1940(ra) # 8000424c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005ac0:	08000613          	li	a2,128
    80005ac4:	f6040593          	addi	a1,s0,-160
    80005ac8:	4501                	li	a0,0
    80005aca:	ffffd097          	auipc	ra,0xffffd
    80005ace:	0e8080e7          	jalr	232(ra) # 80002bb2 <argstr>
    80005ad2:	04054b63          	bltz	a0,80005b28 <sys_chdir+0x86>
    80005ad6:	f6040513          	addi	a0,s0,-160
    80005ada:	ffffe097          	auipc	ra,0xffffe
    80005ade:	552080e7          	jalr	1362(ra) # 8000402c <namei>
    80005ae2:	84aa                	mv	s1,a0
    80005ae4:	c131                	beqz	a0,80005b28 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005ae6:	ffffe097          	auipc	ra,0xffffe
    80005aea:	d9a080e7          	jalr	-614(ra) # 80003880 <ilock>
  if(ip->type != T_DIR){
    80005aee:	04449703          	lh	a4,68(s1)
    80005af2:	4785                	li	a5,1
    80005af4:	04f71063          	bne	a4,a5,80005b34 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005af8:	8526                	mv	a0,s1
    80005afa:	ffffe097          	auipc	ra,0xffffe
    80005afe:	e48080e7          	jalr	-440(ra) # 80003942 <iunlock>
  iput(p->cwd);
    80005b02:	15093503          	ld	a0,336(s2)
    80005b06:	ffffe097          	auipc	ra,0xffffe
    80005b0a:	f34080e7          	jalr	-204(ra) # 80003a3a <iput>
  end_op();
    80005b0e:	ffffe097          	auipc	ra,0xffffe
    80005b12:	7bc080e7          	jalr	1980(ra) # 800042ca <end_op>
  p->cwd = ip;
    80005b16:	14993823          	sd	s1,336(s2)
  return 0;
    80005b1a:	4501                	li	a0,0
}
    80005b1c:	60ea                	ld	ra,152(sp)
    80005b1e:	644a                	ld	s0,144(sp)
    80005b20:	64aa                	ld	s1,136(sp)
    80005b22:	690a                	ld	s2,128(sp)
    80005b24:	610d                	addi	sp,sp,160
    80005b26:	8082                	ret
    end_op();
    80005b28:	ffffe097          	auipc	ra,0xffffe
    80005b2c:	7a2080e7          	jalr	1954(ra) # 800042ca <end_op>
    return -1;
    80005b30:	557d                	li	a0,-1
    80005b32:	b7ed                	j	80005b1c <sys_chdir+0x7a>
    iunlockput(ip);
    80005b34:	8526                	mv	a0,s1
    80005b36:	ffffe097          	auipc	ra,0xffffe
    80005b3a:	fac080e7          	jalr	-84(ra) # 80003ae2 <iunlockput>
    end_op();
    80005b3e:	ffffe097          	auipc	ra,0xffffe
    80005b42:	78c080e7          	jalr	1932(ra) # 800042ca <end_op>
    return -1;
    80005b46:	557d                	li	a0,-1
    80005b48:	bfd1                	j	80005b1c <sys_chdir+0x7a>

0000000080005b4a <sys_exec>:

uint64
sys_exec(void)
{
    80005b4a:	7145                	addi	sp,sp,-464
    80005b4c:	e786                	sd	ra,456(sp)
    80005b4e:	e3a2                	sd	s0,448(sp)
    80005b50:	ff26                	sd	s1,440(sp)
    80005b52:	fb4a                	sd	s2,432(sp)
    80005b54:	f74e                	sd	s3,424(sp)
    80005b56:	f352                	sd	s4,416(sp)
    80005b58:	ef56                	sd	s5,408(sp)
    80005b5a:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005b5c:	e3840593          	addi	a1,s0,-456
    80005b60:	4505                	li	a0,1
    80005b62:	ffffd097          	auipc	ra,0xffffd
    80005b66:	030080e7          	jalr	48(ra) # 80002b92 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005b6a:	08000613          	li	a2,128
    80005b6e:	f4040593          	addi	a1,s0,-192
    80005b72:	4501                	li	a0,0
    80005b74:	ffffd097          	auipc	ra,0xffffd
    80005b78:	03e080e7          	jalr	62(ra) # 80002bb2 <argstr>
    80005b7c:	87aa                	mv	a5,a0
    return -1;
    80005b7e:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005b80:	0c07c363          	bltz	a5,80005c46 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005b84:	10000613          	li	a2,256
    80005b88:	4581                	li	a1,0
    80005b8a:	e4040513          	addi	a0,s0,-448
    80005b8e:	ffffb097          	auipc	ra,0xffffb
    80005b92:	144080e7          	jalr	324(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005b96:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005b9a:	89a6                	mv	s3,s1
    80005b9c:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005b9e:	02000a13          	li	s4,32
    80005ba2:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005ba6:	00391513          	slli	a0,s2,0x3
    80005baa:	e3040593          	addi	a1,s0,-464
    80005bae:	e3843783          	ld	a5,-456(s0)
    80005bb2:	953e                	add	a0,a0,a5
    80005bb4:	ffffd097          	auipc	ra,0xffffd
    80005bb8:	f20080e7          	jalr	-224(ra) # 80002ad4 <fetchaddr>
    80005bbc:	02054a63          	bltz	a0,80005bf0 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005bc0:	e3043783          	ld	a5,-464(s0)
    80005bc4:	c3b9                	beqz	a5,80005c0a <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005bc6:	ffffb097          	auipc	ra,0xffffb
    80005bca:	f20080e7          	jalr	-224(ra) # 80000ae6 <kalloc>
    80005bce:	85aa                	mv	a1,a0
    80005bd0:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005bd4:	cd11                	beqz	a0,80005bf0 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005bd6:	6605                	lui	a2,0x1
    80005bd8:	e3043503          	ld	a0,-464(s0)
    80005bdc:	ffffd097          	auipc	ra,0xffffd
    80005be0:	f4a080e7          	jalr	-182(ra) # 80002b26 <fetchstr>
    80005be4:	00054663          	bltz	a0,80005bf0 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005be8:	0905                	addi	s2,s2,1
    80005bea:	09a1                	addi	s3,s3,8
    80005bec:	fb491be3          	bne	s2,s4,80005ba2 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bf0:	f4040913          	addi	s2,s0,-192
    80005bf4:	6088                	ld	a0,0(s1)
    80005bf6:	c539                	beqz	a0,80005c44 <sys_exec+0xfa>
    kfree(argv[i]);
    80005bf8:	ffffb097          	auipc	ra,0xffffb
    80005bfc:	df0080e7          	jalr	-528(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c00:	04a1                	addi	s1,s1,8
    80005c02:	ff2499e3          	bne	s1,s2,80005bf4 <sys_exec+0xaa>
  return -1;
    80005c06:	557d                	li	a0,-1
    80005c08:	a83d                	j	80005c46 <sys_exec+0xfc>
      argv[i] = 0;
    80005c0a:	0a8e                	slli	s5,s5,0x3
    80005c0c:	fc0a8793          	addi	a5,s5,-64
    80005c10:	00878ab3          	add	s5,a5,s0
    80005c14:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005c18:	e4040593          	addi	a1,s0,-448
    80005c1c:	f4040513          	addi	a0,s0,-192
    80005c20:	fffff097          	auipc	ra,0xfffff
    80005c24:	16e080e7          	jalr	366(ra) # 80004d8e <exec>
    80005c28:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c2a:	f4040993          	addi	s3,s0,-192
    80005c2e:	6088                	ld	a0,0(s1)
    80005c30:	c901                	beqz	a0,80005c40 <sys_exec+0xf6>
    kfree(argv[i]);
    80005c32:	ffffb097          	auipc	ra,0xffffb
    80005c36:	db6080e7          	jalr	-586(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c3a:	04a1                	addi	s1,s1,8
    80005c3c:	ff3499e3          	bne	s1,s3,80005c2e <sys_exec+0xe4>
  return ret;
    80005c40:	854a                	mv	a0,s2
    80005c42:	a011                	j	80005c46 <sys_exec+0xfc>
  return -1;
    80005c44:	557d                	li	a0,-1
}
    80005c46:	60be                	ld	ra,456(sp)
    80005c48:	641e                	ld	s0,448(sp)
    80005c4a:	74fa                	ld	s1,440(sp)
    80005c4c:	795a                	ld	s2,432(sp)
    80005c4e:	79ba                	ld	s3,424(sp)
    80005c50:	7a1a                	ld	s4,416(sp)
    80005c52:	6afa                	ld	s5,408(sp)
    80005c54:	6179                	addi	sp,sp,464
    80005c56:	8082                	ret

0000000080005c58 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005c58:	7139                	addi	sp,sp,-64
    80005c5a:	fc06                	sd	ra,56(sp)
    80005c5c:	f822                	sd	s0,48(sp)
    80005c5e:	f426                	sd	s1,40(sp)
    80005c60:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005c62:	ffffc097          	auipc	ra,0xffffc
    80005c66:	d4a080e7          	jalr	-694(ra) # 800019ac <myproc>
    80005c6a:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005c6c:	fd840593          	addi	a1,s0,-40
    80005c70:	4501                	li	a0,0
    80005c72:	ffffd097          	auipc	ra,0xffffd
    80005c76:	f20080e7          	jalr	-224(ra) # 80002b92 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005c7a:	fc840593          	addi	a1,s0,-56
    80005c7e:	fd040513          	addi	a0,s0,-48
    80005c82:	fffff097          	auipc	ra,0xfffff
    80005c86:	dc2080e7          	jalr	-574(ra) # 80004a44 <pipealloc>
    return -1;
    80005c8a:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005c8c:	0c054463          	bltz	a0,80005d54 <sys_pipe+0xfc>
  fd0 = -1;
    80005c90:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005c94:	fd043503          	ld	a0,-48(s0)
    80005c98:	fffff097          	auipc	ra,0xfffff
    80005c9c:	514080e7          	jalr	1300(ra) # 800051ac <fdalloc>
    80005ca0:	fca42223          	sw	a0,-60(s0)
    80005ca4:	08054b63          	bltz	a0,80005d3a <sys_pipe+0xe2>
    80005ca8:	fc843503          	ld	a0,-56(s0)
    80005cac:	fffff097          	auipc	ra,0xfffff
    80005cb0:	500080e7          	jalr	1280(ra) # 800051ac <fdalloc>
    80005cb4:	fca42023          	sw	a0,-64(s0)
    80005cb8:	06054863          	bltz	a0,80005d28 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005cbc:	4691                	li	a3,4
    80005cbe:	fc440613          	addi	a2,s0,-60
    80005cc2:	fd843583          	ld	a1,-40(s0)
    80005cc6:	68a8                	ld	a0,80(s1)
    80005cc8:	ffffc097          	auipc	ra,0xffffc
    80005ccc:	9a4080e7          	jalr	-1628(ra) # 8000166c <copyout>
    80005cd0:	02054063          	bltz	a0,80005cf0 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005cd4:	4691                	li	a3,4
    80005cd6:	fc040613          	addi	a2,s0,-64
    80005cda:	fd843583          	ld	a1,-40(s0)
    80005cde:	0591                	addi	a1,a1,4
    80005ce0:	68a8                	ld	a0,80(s1)
    80005ce2:	ffffc097          	auipc	ra,0xffffc
    80005ce6:	98a080e7          	jalr	-1654(ra) # 8000166c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005cea:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005cec:	06055463          	bgez	a0,80005d54 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005cf0:	fc442783          	lw	a5,-60(s0)
    80005cf4:	07e9                	addi	a5,a5,26
    80005cf6:	078e                	slli	a5,a5,0x3
    80005cf8:	97a6                	add	a5,a5,s1
    80005cfa:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005cfe:	fc042783          	lw	a5,-64(s0)
    80005d02:	07e9                	addi	a5,a5,26
    80005d04:	078e                	slli	a5,a5,0x3
    80005d06:	94be                	add	s1,s1,a5
    80005d08:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005d0c:	fd043503          	ld	a0,-48(s0)
    80005d10:	fffff097          	auipc	ra,0xfffff
    80005d14:	a04080e7          	jalr	-1532(ra) # 80004714 <fileclose>
    fileclose(wf);
    80005d18:	fc843503          	ld	a0,-56(s0)
    80005d1c:	fffff097          	auipc	ra,0xfffff
    80005d20:	9f8080e7          	jalr	-1544(ra) # 80004714 <fileclose>
    return -1;
    80005d24:	57fd                	li	a5,-1
    80005d26:	a03d                	j	80005d54 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005d28:	fc442783          	lw	a5,-60(s0)
    80005d2c:	0007c763          	bltz	a5,80005d3a <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005d30:	07e9                	addi	a5,a5,26
    80005d32:	078e                	slli	a5,a5,0x3
    80005d34:	97a6                	add	a5,a5,s1
    80005d36:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005d3a:	fd043503          	ld	a0,-48(s0)
    80005d3e:	fffff097          	auipc	ra,0xfffff
    80005d42:	9d6080e7          	jalr	-1578(ra) # 80004714 <fileclose>
    fileclose(wf);
    80005d46:	fc843503          	ld	a0,-56(s0)
    80005d4a:	fffff097          	auipc	ra,0xfffff
    80005d4e:	9ca080e7          	jalr	-1590(ra) # 80004714 <fileclose>
    return -1;
    80005d52:	57fd                	li	a5,-1
}
    80005d54:	853e                	mv	a0,a5
    80005d56:	70e2                	ld	ra,56(sp)
    80005d58:	7442                	ld	s0,48(sp)
    80005d5a:	74a2                	ld	s1,40(sp)
    80005d5c:	6121                	addi	sp,sp,64
    80005d5e:	8082                	ret

0000000080005d60 <kernelvec>:
    80005d60:	7111                	addi	sp,sp,-256
    80005d62:	e006                	sd	ra,0(sp)
    80005d64:	e40a                	sd	sp,8(sp)
    80005d66:	e80e                	sd	gp,16(sp)
    80005d68:	ec12                	sd	tp,24(sp)
    80005d6a:	f016                	sd	t0,32(sp)
    80005d6c:	f41a                	sd	t1,40(sp)
    80005d6e:	f81e                	sd	t2,48(sp)
    80005d70:	fc22                	sd	s0,56(sp)
    80005d72:	e0a6                	sd	s1,64(sp)
    80005d74:	e4aa                	sd	a0,72(sp)
    80005d76:	e8ae                	sd	a1,80(sp)
    80005d78:	ecb2                	sd	a2,88(sp)
    80005d7a:	f0b6                	sd	a3,96(sp)
    80005d7c:	f4ba                	sd	a4,104(sp)
    80005d7e:	f8be                	sd	a5,112(sp)
    80005d80:	fcc2                	sd	a6,120(sp)
    80005d82:	e146                	sd	a7,128(sp)
    80005d84:	e54a                	sd	s2,136(sp)
    80005d86:	e94e                	sd	s3,144(sp)
    80005d88:	ed52                	sd	s4,152(sp)
    80005d8a:	f156                	sd	s5,160(sp)
    80005d8c:	f55a                	sd	s6,168(sp)
    80005d8e:	f95e                	sd	s7,176(sp)
    80005d90:	fd62                	sd	s8,184(sp)
    80005d92:	e1e6                	sd	s9,192(sp)
    80005d94:	e5ea                	sd	s10,200(sp)
    80005d96:	e9ee                	sd	s11,208(sp)
    80005d98:	edf2                	sd	t3,216(sp)
    80005d9a:	f1f6                	sd	t4,224(sp)
    80005d9c:	f5fa                	sd	t5,232(sp)
    80005d9e:	f9fe                	sd	t6,240(sp)
    80005da0:	c01fc0ef          	jal	ra,800029a0 <kerneltrap>
    80005da4:	6082                	ld	ra,0(sp)
    80005da6:	6122                	ld	sp,8(sp)
    80005da8:	61c2                	ld	gp,16(sp)
    80005daa:	7282                	ld	t0,32(sp)
    80005dac:	7322                	ld	t1,40(sp)
    80005dae:	73c2                	ld	t2,48(sp)
    80005db0:	7462                	ld	s0,56(sp)
    80005db2:	6486                	ld	s1,64(sp)
    80005db4:	6526                	ld	a0,72(sp)
    80005db6:	65c6                	ld	a1,80(sp)
    80005db8:	6666                	ld	a2,88(sp)
    80005dba:	7686                	ld	a3,96(sp)
    80005dbc:	7726                	ld	a4,104(sp)
    80005dbe:	77c6                	ld	a5,112(sp)
    80005dc0:	7866                	ld	a6,120(sp)
    80005dc2:	688a                	ld	a7,128(sp)
    80005dc4:	692a                	ld	s2,136(sp)
    80005dc6:	69ca                	ld	s3,144(sp)
    80005dc8:	6a6a                	ld	s4,152(sp)
    80005dca:	7a8a                	ld	s5,160(sp)
    80005dcc:	7b2a                	ld	s6,168(sp)
    80005dce:	7bca                	ld	s7,176(sp)
    80005dd0:	7c6a                	ld	s8,184(sp)
    80005dd2:	6c8e                	ld	s9,192(sp)
    80005dd4:	6d2e                	ld	s10,200(sp)
    80005dd6:	6dce                	ld	s11,208(sp)
    80005dd8:	6e6e                	ld	t3,216(sp)
    80005dda:	7e8e                	ld	t4,224(sp)
    80005ddc:	7f2e                	ld	t5,232(sp)
    80005dde:	7fce                	ld	t6,240(sp)
    80005de0:	6111                	addi	sp,sp,256
    80005de2:	10200073          	sret
    80005de6:	00000013          	nop
    80005dea:	00000013          	nop
    80005dee:	0001                	nop

0000000080005df0 <timervec>:
    80005df0:	34051573          	csrrw	a0,mscratch,a0
    80005df4:	e10c                	sd	a1,0(a0)
    80005df6:	e510                	sd	a2,8(a0)
    80005df8:	e914                	sd	a3,16(a0)
    80005dfa:	6d0c                	ld	a1,24(a0)
    80005dfc:	7110                	ld	a2,32(a0)
    80005dfe:	6194                	ld	a3,0(a1)
    80005e00:	96b2                	add	a3,a3,a2
    80005e02:	e194                	sd	a3,0(a1)
    80005e04:	4589                	li	a1,2
    80005e06:	14459073          	csrw	sip,a1
    80005e0a:	6914                	ld	a3,16(a0)
    80005e0c:	6510                	ld	a2,8(a0)
    80005e0e:	610c                	ld	a1,0(a0)
    80005e10:	34051573          	csrrw	a0,mscratch,a0
    80005e14:	30200073          	mret
	...

0000000080005e1a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005e1a:	1141                	addi	sp,sp,-16
    80005e1c:	e422                	sd	s0,8(sp)
    80005e1e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005e20:	0c0007b7          	lui	a5,0xc000
    80005e24:	4705                	li	a4,1
    80005e26:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005e28:	c3d8                	sw	a4,4(a5)
}
    80005e2a:	6422                	ld	s0,8(sp)
    80005e2c:	0141                	addi	sp,sp,16
    80005e2e:	8082                	ret

0000000080005e30 <plicinithart>:

void
plicinithart(void)
{
    80005e30:	1141                	addi	sp,sp,-16
    80005e32:	e406                	sd	ra,8(sp)
    80005e34:	e022                	sd	s0,0(sp)
    80005e36:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e38:	ffffc097          	auipc	ra,0xffffc
    80005e3c:	b48080e7          	jalr	-1208(ra) # 80001980 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005e40:	0085171b          	slliw	a4,a0,0x8
    80005e44:	0c0027b7          	lui	a5,0xc002
    80005e48:	97ba                	add	a5,a5,a4
    80005e4a:	40200713          	li	a4,1026
    80005e4e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005e52:	00d5151b          	slliw	a0,a0,0xd
    80005e56:	0c2017b7          	lui	a5,0xc201
    80005e5a:	97aa                	add	a5,a5,a0
    80005e5c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005e60:	60a2                	ld	ra,8(sp)
    80005e62:	6402                	ld	s0,0(sp)
    80005e64:	0141                	addi	sp,sp,16
    80005e66:	8082                	ret

0000000080005e68 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005e68:	1141                	addi	sp,sp,-16
    80005e6a:	e406                	sd	ra,8(sp)
    80005e6c:	e022                	sd	s0,0(sp)
    80005e6e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e70:	ffffc097          	auipc	ra,0xffffc
    80005e74:	b10080e7          	jalr	-1264(ra) # 80001980 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005e78:	00d5151b          	slliw	a0,a0,0xd
    80005e7c:	0c2017b7          	lui	a5,0xc201
    80005e80:	97aa                	add	a5,a5,a0
  return irq;
}
    80005e82:	43c8                	lw	a0,4(a5)
    80005e84:	60a2                	ld	ra,8(sp)
    80005e86:	6402                	ld	s0,0(sp)
    80005e88:	0141                	addi	sp,sp,16
    80005e8a:	8082                	ret

0000000080005e8c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005e8c:	1101                	addi	sp,sp,-32
    80005e8e:	ec06                	sd	ra,24(sp)
    80005e90:	e822                	sd	s0,16(sp)
    80005e92:	e426                	sd	s1,8(sp)
    80005e94:	1000                	addi	s0,sp,32
    80005e96:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005e98:	ffffc097          	auipc	ra,0xffffc
    80005e9c:	ae8080e7          	jalr	-1304(ra) # 80001980 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005ea0:	00d5151b          	slliw	a0,a0,0xd
    80005ea4:	0c2017b7          	lui	a5,0xc201
    80005ea8:	97aa                	add	a5,a5,a0
    80005eaa:	c3c4                	sw	s1,4(a5)
}
    80005eac:	60e2                	ld	ra,24(sp)
    80005eae:	6442                	ld	s0,16(sp)
    80005eb0:	64a2                	ld	s1,8(sp)
    80005eb2:	6105                	addi	sp,sp,32
    80005eb4:	8082                	ret

0000000080005eb6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005eb6:	1141                	addi	sp,sp,-16
    80005eb8:	e406                	sd	ra,8(sp)
    80005eba:	e022                	sd	s0,0(sp)
    80005ebc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005ebe:	479d                	li	a5,7
    80005ec0:	04a7cc63          	blt	a5,a0,80005f18 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005ec4:	00024797          	auipc	a5,0x24
    80005ec8:	29478793          	addi	a5,a5,660 # 8002a158 <disk>
    80005ecc:	97aa                	add	a5,a5,a0
    80005ece:	0187c783          	lbu	a5,24(a5)
    80005ed2:	ebb9                	bnez	a5,80005f28 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005ed4:	00451693          	slli	a3,a0,0x4
    80005ed8:	00024797          	auipc	a5,0x24
    80005edc:	28078793          	addi	a5,a5,640 # 8002a158 <disk>
    80005ee0:	6398                	ld	a4,0(a5)
    80005ee2:	9736                	add	a4,a4,a3
    80005ee4:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80005ee8:	6398                	ld	a4,0(a5)
    80005eea:	9736                	add	a4,a4,a3
    80005eec:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005ef0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005ef4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005ef8:	97aa                	add	a5,a5,a0
    80005efa:	4705                	li	a4,1
    80005efc:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80005f00:	00024517          	auipc	a0,0x24
    80005f04:	27050513          	addi	a0,a0,624 # 8002a170 <disk+0x18>
    80005f08:	ffffc097          	auipc	ra,0xffffc
    80005f0c:	260080e7          	jalr	608(ra) # 80002168 <wakeup>
}
    80005f10:	60a2                	ld	ra,8(sp)
    80005f12:	6402                	ld	s0,0(sp)
    80005f14:	0141                	addi	sp,sp,16
    80005f16:	8082                	ret
    panic("free_desc 1");
    80005f18:	00003517          	auipc	a0,0x3
    80005f1c:	a2050513          	addi	a0,a0,-1504 # 80008938 <syscalls+0x318>
    80005f20:	ffffa097          	auipc	ra,0xffffa
    80005f24:	620080e7          	jalr	1568(ra) # 80000540 <panic>
    panic("free_desc 2");
    80005f28:	00003517          	auipc	a0,0x3
    80005f2c:	a2050513          	addi	a0,a0,-1504 # 80008948 <syscalls+0x328>
    80005f30:	ffffa097          	auipc	ra,0xffffa
    80005f34:	610080e7          	jalr	1552(ra) # 80000540 <panic>

0000000080005f38 <virtio_disk_init>:
{
    80005f38:	1101                	addi	sp,sp,-32
    80005f3a:	ec06                	sd	ra,24(sp)
    80005f3c:	e822                	sd	s0,16(sp)
    80005f3e:	e426                	sd	s1,8(sp)
    80005f40:	e04a                	sd	s2,0(sp)
    80005f42:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005f44:	00003597          	auipc	a1,0x3
    80005f48:	a1458593          	addi	a1,a1,-1516 # 80008958 <syscalls+0x338>
    80005f4c:	00024517          	auipc	a0,0x24
    80005f50:	33450513          	addi	a0,a0,820 # 8002a280 <disk+0x128>
    80005f54:	ffffb097          	auipc	ra,0xffffb
    80005f58:	bf2080e7          	jalr	-1038(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f5c:	100017b7          	lui	a5,0x10001
    80005f60:	4398                	lw	a4,0(a5)
    80005f62:	2701                	sext.w	a4,a4
    80005f64:	747277b7          	lui	a5,0x74727
    80005f68:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005f6c:	14f71b63          	bne	a4,a5,800060c2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005f70:	100017b7          	lui	a5,0x10001
    80005f74:	43dc                	lw	a5,4(a5)
    80005f76:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f78:	4709                	li	a4,2
    80005f7a:	14e79463          	bne	a5,a4,800060c2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f7e:	100017b7          	lui	a5,0x10001
    80005f82:	479c                	lw	a5,8(a5)
    80005f84:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005f86:	12e79e63          	bne	a5,a4,800060c2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005f8a:	100017b7          	lui	a5,0x10001
    80005f8e:	47d8                	lw	a4,12(a5)
    80005f90:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f92:	554d47b7          	lui	a5,0x554d4
    80005f96:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005f9a:	12f71463          	bne	a4,a5,800060c2 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f9e:	100017b7          	lui	a5,0x10001
    80005fa2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fa6:	4705                	li	a4,1
    80005fa8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005faa:	470d                	li	a4,3
    80005fac:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005fae:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005fb0:	c7ffe6b7          	lui	a3,0xc7ffe
    80005fb4:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fd44c7>
    80005fb8:	8f75                	and	a4,a4,a3
    80005fba:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fbc:	472d                	li	a4,11
    80005fbe:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005fc0:	5bbc                	lw	a5,112(a5)
    80005fc2:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005fc6:	8ba1                	andi	a5,a5,8
    80005fc8:	10078563          	beqz	a5,800060d2 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005fcc:	100017b7          	lui	a5,0x10001
    80005fd0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005fd4:	43fc                	lw	a5,68(a5)
    80005fd6:	2781                	sext.w	a5,a5
    80005fd8:	10079563          	bnez	a5,800060e2 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005fdc:	100017b7          	lui	a5,0x10001
    80005fe0:	5bdc                	lw	a5,52(a5)
    80005fe2:	2781                	sext.w	a5,a5
  if(max == 0)
    80005fe4:	10078763          	beqz	a5,800060f2 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80005fe8:	471d                	li	a4,7
    80005fea:	10f77c63          	bgeu	a4,a5,80006102 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    80005fee:	ffffb097          	auipc	ra,0xffffb
    80005ff2:	af8080e7          	jalr	-1288(ra) # 80000ae6 <kalloc>
    80005ff6:	00024497          	auipc	s1,0x24
    80005ffa:	16248493          	addi	s1,s1,354 # 8002a158 <disk>
    80005ffe:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006000:	ffffb097          	auipc	ra,0xffffb
    80006004:	ae6080e7          	jalr	-1306(ra) # 80000ae6 <kalloc>
    80006008:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000600a:	ffffb097          	auipc	ra,0xffffb
    8000600e:	adc080e7          	jalr	-1316(ra) # 80000ae6 <kalloc>
    80006012:	87aa                	mv	a5,a0
    80006014:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006016:	6088                	ld	a0,0(s1)
    80006018:	cd6d                	beqz	a0,80006112 <virtio_disk_init+0x1da>
    8000601a:	00024717          	auipc	a4,0x24
    8000601e:	14673703          	ld	a4,326(a4) # 8002a160 <disk+0x8>
    80006022:	cb65                	beqz	a4,80006112 <virtio_disk_init+0x1da>
    80006024:	c7fd                	beqz	a5,80006112 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80006026:	6605                	lui	a2,0x1
    80006028:	4581                	li	a1,0
    8000602a:	ffffb097          	auipc	ra,0xffffb
    8000602e:	ca8080e7          	jalr	-856(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006032:	00024497          	auipc	s1,0x24
    80006036:	12648493          	addi	s1,s1,294 # 8002a158 <disk>
    8000603a:	6605                	lui	a2,0x1
    8000603c:	4581                	li	a1,0
    8000603e:	6488                	ld	a0,8(s1)
    80006040:	ffffb097          	auipc	ra,0xffffb
    80006044:	c92080e7          	jalr	-878(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    80006048:	6605                	lui	a2,0x1
    8000604a:	4581                	li	a1,0
    8000604c:	6888                	ld	a0,16(s1)
    8000604e:	ffffb097          	auipc	ra,0xffffb
    80006052:	c84080e7          	jalr	-892(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006056:	100017b7          	lui	a5,0x10001
    8000605a:	4721                	li	a4,8
    8000605c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    8000605e:	4098                	lw	a4,0(s1)
    80006060:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006064:	40d8                	lw	a4,4(s1)
    80006066:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000606a:	6498                	ld	a4,8(s1)
    8000606c:	0007069b          	sext.w	a3,a4
    80006070:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006074:	9701                	srai	a4,a4,0x20
    80006076:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000607a:	6898                	ld	a4,16(s1)
    8000607c:	0007069b          	sext.w	a3,a4
    80006080:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006084:	9701                	srai	a4,a4,0x20
    80006086:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000608a:	4705                	li	a4,1
    8000608c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    8000608e:	00e48c23          	sb	a4,24(s1)
    80006092:	00e48ca3          	sb	a4,25(s1)
    80006096:	00e48d23          	sb	a4,26(s1)
    8000609a:	00e48da3          	sb	a4,27(s1)
    8000609e:	00e48e23          	sb	a4,28(s1)
    800060a2:	00e48ea3          	sb	a4,29(s1)
    800060a6:	00e48f23          	sb	a4,30(s1)
    800060aa:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    800060ae:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    800060b2:	0727a823          	sw	s2,112(a5)
}
    800060b6:	60e2                	ld	ra,24(sp)
    800060b8:	6442                	ld	s0,16(sp)
    800060ba:	64a2                	ld	s1,8(sp)
    800060bc:	6902                	ld	s2,0(sp)
    800060be:	6105                	addi	sp,sp,32
    800060c0:	8082                	ret
    panic("could not find virtio disk");
    800060c2:	00003517          	auipc	a0,0x3
    800060c6:	8a650513          	addi	a0,a0,-1882 # 80008968 <syscalls+0x348>
    800060ca:	ffffa097          	auipc	ra,0xffffa
    800060ce:	476080e7          	jalr	1142(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    800060d2:	00003517          	auipc	a0,0x3
    800060d6:	8b650513          	addi	a0,a0,-1866 # 80008988 <syscalls+0x368>
    800060da:	ffffa097          	auipc	ra,0xffffa
    800060de:	466080e7          	jalr	1126(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    800060e2:	00003517          	auipc	a0,0x3
    800060e6:	8c650513          	addi	a0,a0,-1850 # 800089a8 <syscalls+0x388>
    800060ea:	ffffa097          	auipc	ra,0xffffa
    800060ee:	456080e7          	jalr	1110(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    800060f2:	00003517          	auipc	a0,0x3
    800060f6:	8d650513          	addi	a0,a0,-1834 # 800089c8 <syscalls+0x3a8>
    800060fa:	ffffa097          	auipc	ra,0xffffa
    800060fe:	446080e7          	jalr	1094(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80006102:	00003517          	auipc	a0,0x3
    80006106:	8e650513          	addi	a0,a0,-1818 # 800089e8 <syscalls+0x3c8>
    8000610a:	ffffa097          	auipc	ra,0xffffa
    8000610e:	436080e7          	jalr	1078(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    80006112:	00003517          	auipc	a0,0x3
    80006116:	8f650513          	addi	a0,a0,-1802 # 80008a08 <syscalls+0x3e8>
    8000611a:	ffffa097          	auipc	ra,0xffffa
    8000611e:	426080e7          	jalr	1062(ra) # 80000540 <panic>

0000000080006122 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006122:	7119                	addi	sp,sp,-128
    80006124:	fc86                	sd	ra,120(sp)
    80006126:	f8a2                	sd	s0,112(sp)
    80006128:	f4a6                	sd	s1,104(sp)
    8000612a:	f0ca                	sd	s2,96(sp)
    8000612c:	ecce                	sd	s3,88(sp)
    8000612e:	e8d2                	sd	s4,80(sp)
    80006130:	e4d6                	sd	s5,72(sp)
    80006132:	e0da                	sd	s6,64(sp)
    80006134:	fc5e                	sd	s7,56(sp)
    80006136:	f862                	sd	s8,48(sp)
    80006138:	f466                	sd	s9,40(sp)
    8000613a:	f06a                	sd	s10,32(sp)
    8000613c:	ec6e                	sd	s11,24(sp)
    8000613e:	0100                	addi	s0,sp,128
    80006140:	8aaa                	mv	s5,a0
    80006142:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006144:	00c52d03          	lw	s10,12(a0)
    80006148:	001d1d1b          	slliw	s10,s10,0x1
    8000614c:	1d02                	slli	s10,s10,0x20
    8000614e:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006152:	00024517          	auipc	a0,0x24
    80006156:	12e50513          	addi	a0,a0,302 # 8002a280 <disk+0x128>
    8000615a:	ffffb097          	auipc	ra,0xffffb
    8000615e:	a7c080e7          	jalr	-1412(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80006162:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006164:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006166:	00024b97          	auipc	s7,0x24
    8000616a:	ff2b8b93          	addi	s7,s7,-14 # 8002a158 <disk>
  for(int i = 0; i < 3; i++){
    8000616e:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006170:	00024c97          	auipc	s9,0x24
    80006174:	110c8c93          	addi	s9,s9,272 # 8002a280 <disk+0x128>
    80006178:	a08d                	j	800061da <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000617a:	00fb8733          	add	a4,s7,a5
    8000617e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006182:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006184:	0207c563          	bltz	a5,800061ae <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    80006188:	2905                	addiw	s2,s2,1
    8000618a:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    8000618c:	05690c63          	beq	s2,s6,800061e4 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006190:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006192:	00024717          	auipc	a4,0x24
    80006196:	fc670713          	addi	a4,a4,-58 # 8002a158 <disk>
    8000619a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000619c:	01874683          	lbu	a3,24(a4)
    800061a0:	fee9                	bnez	a3,8000617a <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    800061a2:	2785                	addiw	a5,a5,1
    800061a4:	0705                	addi	a4,a4,1
    800061a6:	fe979be3          	bne	a5,s1,8000619c <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    800061aa:	57fd                	li	a5,-1
    800061ac:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800061ae:	01205d63          	blez	s2,800061c8 <virtio_disk_rw+0xa6>
    800061b2:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800061b4:	000a2503          	lw	a0,0(s4)
    800061b8:	00000097          	auipc	ra,0x0
    800061bc:	cfe080e7          	jalr	-770(ra) # 80005eb6 <free_desc>
      for(int j = 0; j < i; j++)
    800061c0:	2d85                	addiw	s11,s11,1
    800061c2:	0a11                	addi	s4,s4,4
    800061c4:	ff2d98e3          	bne	s11,s2,800061b4 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800061c8:	85e6                	mv	a1,s9
    800061ca:	00024517          	auipc	a0,0x24
    800061ce:	fa650513          	addi	a0,a0,-90 # 8002a170 <disk+0x18>
    800061d2:	ffffc097          	auipc	ra,0xffffc
    800061d6:	f32080e7          	jalr	-206(ra) # 80002104 <sleep>
  for(int i = 0; i < 3; i++){
    800061da:	f8040a13          	addi	s4,s0,-128
{
    800061de:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800061e0:	894e                	mv	s2,s3
    800061e2:	b77d                	j	80006190 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800061e4:	f8042503          	lw	a0,-128(s0)
    800061e8:	00a50713          	addi	a4,a0,10
    800061ec:	0712                	slli	a4,a4,0x4

  if(write)
    800061ee:	00024797          	auipc	a5,0x24
    800061f2:	f6a78793          	addi	a5,a5,-150 # 8002a158 <disk>
    800061f6:	00e786b3          	add	a3,a5,a4
    800061fa:	01803633          	snez	a2,s8
    800061fe:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006200:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006204:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006208:	f6070613          	addi	a2,a4,-160
    8000620c:	6394                	ld	a3,0(a5)
    8000620e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006210:	00870593          	addi	a1,a4,8
    80006214:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006216:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006218:	0007b803          	ld	a6,0(a5)
    8000621c:	9642                	add	a2,a2,a6
    8000621e:	46c1                	li	a3,16
    80006220:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006222:	4585                	li	a1,1
    80006224:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006228:	f8442683          	lw	a3,-124(s0)
    8000622c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006230:	0692                	slli	a3,a3,0x4
    80006232:	9836                	add	a6,a6,a3
    80006234:	058a8613          	addi	a2,s5,88
    80006238:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    8000623c:	0007b803          	ld	a6,0(a5)
    80006240:	96c2                	add	a3,a3,a6
    80006242:	40000613          	li	a2,1024
    80006246:	c690                	sw	a2,8(a3)
  if(write)
    80006248:	001c3613          	seqz	a2,s8
    8000624c:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006250:	00166613          	ori	a2,a2,1
    80006254:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006258:	f8842603          	lw	a2,-120(s0)
    8000625c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006260:	00250693          	addi	a3,a0,2
    80006264:	0692                	slli	a3,a3,0x4
    80006266:	96be                	add	a3,a3,a5
    80006268:	58fd                	li	a7,-1
    8000626a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000626e:	0612                	slli	a2,a2,0x4
    80006270:	9832                	add	a6,a6,a2
    80006272:	f9070713          	addi	a4,a4,-112
    80006276:	973e                	add	a4,a4,a5
    80006278:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000627c:	6398                	ld	a4,0(a5)
    8000627e:	9732                	add	a4,a4,a2
    80006280:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006282:	4609                	li	a2,2
    80006284:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006288:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000628c:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80006290:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006294:	6794                	ld	a3,8(a5)
    80006296:	0026d703          	lhu	a4,2(a3)
    8000629a:	8b1d                	andi	a4,a4,7
    8000629c:	0706                	slli	a4,a4,0x1
    8000629e:	96ba                	add	a3,a3,a4
    800062a0:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    800062a4:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800062a8:	6798                	ld	a4,8(a5)
    800062aa:	00275783          	lhu	a5,2(a4)
    800062ae:	2785                	addiw	a5,a5,1
    800062b0:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800062b4:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800062b8:	100017b7          	lui	a5,0x10001
    800062bc:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800062c0:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    800062c4:	00024917          	auipc	s2,0x24
    800062c8:	fbc90913          	addi	s2,s2,-68 # 8002a280 <disk+0x128>
  while(b->disk == 1) {
    800062cc:	4485                	li	s1,1
    800062ce:	00b79c63          	bne	a5,a1,800062e6 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    800062d2:	85ca                	mv	a1,s2
    800062d4:	8556                	mv	a0,s5
    800062d6:	ffffc097          	auipc	ra,0xffffc
    800062da:	e2e080e7          	jalr	-466(ra) # 80002104 <sleep>
  while(b->disk == 1) {
    800062de:	004aa783          	lw	a5,4(s5)
    800062e2:	fe9788e3          	beq	a5,s1,800062d2 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    800062e6:	f8042903          	lw	s2,-128(s0)
    800062ea:	00290713          	addi	a4,s2,2
    800062ee:	0712                	slli	a4,a4,0x4
    800062f0:	00024797          	auipc	a5,0x24
    800062f4:	e6878793          	addi	a5,a5,-408 # 8002a158 <disk>
    800062f8:	97ba                	add	a5,a5,a4
    800062fa:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800062fe:	00024997          	auipc	s3,0x24
    80006302:	e5a98993          	addi	s3,s3,-422 # 8002a158 <disk>
    80006306:	00491713          	slli	a4,s2,0x4
    8000630a:	0009b783          	ld	a5,0(s3)
    8000630e:	97ba                	add	a5,a5,a4
    80006310:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006314:	854a                	mv	a0,s2
    80006316:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000631a:	00000097          	auipc	ra,0x0
    8000631e:	b9c080e7          	jalr	-1124(ra) # 80005eb6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006322:	8885                	andi	s1,s1,1
    80006324:	f0ed                	bnez	s1,80006306 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006326:	00024517          	auipc	a0,0x24
    8000632a:	f5a50513          	addi	a0,a0,-166 # 8002a280 <disk+0x128>
    8000632e:	ffffb097          	auipc	ra,0xffffb
    80006332:	95c080e7          	jalr	-1700(ra) # 80000c8a <release>
}
    80006336:	70e6                	ld	ra,120(sp)
    80006338:	7446                	ld	s0,112(sp)
    8000633a:	74a6                	ld	s1,104(sp)
    8000633c:	7906                	ld	s2,96(sp)
    8000633e:	69e6                	ld	s3,88(sp)
    80006340:	6a46                	ld	s4,80(sp)
    80006342:	6aa6                	ld	s5,72(sp)
    80006344:	6b06                	ld	s6,64(sp)
    80006346:	7be2                	ld	s7,56(sp)
    80006348:	7c42                	ld	s8,48(sp)
    8000634a:	7ca2                	ld	s9,40(sp)
    8000634c:	7d02                	ld	s10,32(sp)
    8000634e:	6de2                	ld	s11,24(sp)
    80006350:	6109                	addi	sp,sp,128
    80006352:	8082                	ret

0000000080006354 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006354:	1101                	addi	sp,sp,-32
    80006356:	ec06                	sd	ra,24(sp)
    80006358:	e822                	sd	s0,16(sp)
    8000635a:	e426                	sd	s1,8(sp)
    8000635c:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000635e:	00024497          	auipc	s1,0x24
    80006362:	dfa48493          	addi	s1,s1,-518 # 8002a158 <disk>
    80006366:	00024517          	auipc	a0,0x24
    8000636a:	f1a50513          	addi	a0,a0,-230 # 8002a280 <disk+0x128>
    8000636e:	ffffb097          	auipc	ra,0xffffb
    80006372:	868080e7          	jalr	-1944(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006376:	10001737          	lui	a4,0x10001
    8000637a:	533c                	lw	a5,96(a4)
    8000637c:	8b8d                	andi	a5,a5,3
    8000637e:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006380:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006384:	689c                	ld	a5,16(s1)
    80006386:	0204d703          	lhu	a4,32(s1)
    8000638a:	0027d783          	lhu	a5,2(a5)
    8000638e:	04f70863          	beq	a4,a5,800063de <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006392:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006396:	6898                	ld	a4,16(s1)
    80006398:	0204d783          	lhu	a5,32(s1)
    8000639c:	8b9d                	andi	a5,a5,7
    8000639e:	078e                	slli	a5,a5,0x3
    800063a0:	97ba                	add	a5,a5,a4
    800063a2:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800063a4:	00278713          	addi	a4,a5,2
    800063a8:	0712                	slli	a4,a4,0x4
    800063aa:	9726                	add	a4,a4,s1
    800063ac:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800063b0:	e721                	bnez	a4,800063f8 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800063b2:	0789                	addi	a5,a5,2
    800063b4:	0792                	slli	a5,a5,0x4
    800063b6:	97a6                	add	a5,a5,s1
    800063b8:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800063ba:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800063be:	ffffc097          	auipc	ra,0xffffc
    800063c2:	daa080e7          	jalr	-598(ra) # 80002168 <wakeup>

    disk.used_idx += 1;
    800063c6:	0204d783          	lhu	a5,32(s1)
    800063ca:	2785                	addiw	a5,a5,1
    800063cc:	17c2                	slli	a5,a5,0x30
    800063ce:	93c1                	srli	a5,a5,0x30
    800063d0:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800063d4:	6898                	ld	a4,16(s1)
    800063d6:	00275703          	lhu	a4,2(a4)
    800063da:	faf71ce3          	bne	a4,a5,80006392 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800063de:	00024517          	auipc	a0,0x24
    800063e2:	ea250513          	addi	a0,a0,-350 # 8002a280 <disk+0x128>
    800063e6:	ffffb097          	auipc	ra,0xffffb
    800063ea:	8a4080e7          	jalr	-1884(ra) # 80000c8a <release>
}
    800063ee:	60e2                	ld	ra,24(sp)
    800063f0:	6442                	ld	s0,16(sp)
    800063f2:	64a2                	ld	s1,8(sp)
    800063f4:	6105                	addi	sp,sp,32
    800063f6:	8082                	ret
      panic("virtio_disk_intr status");
    800063f8:	00002517          	auipc	a0,0x2
    800063fc:	62850513          	addi	a0,a0,1576 # 80008a20 <syscalls+0x400>
    80006400:	ffffa097          	auipc	ra,0xffffa
    80006404:	140080e7          	jalr	320(ra) # 80000540 <panic>

0000000080006408 <init_list_head>:
#include "defs.h"
#include "spinlock.h"
#include "proc.h"

void init_list_head(struct list_head *list)
{
    80006408:	1141                	addi	sp,sp,-16
    8000640a:	e422                	sd	s0,8(sp)
    8000640c:	0800                	addi	s0,sp,16
  list->next = list;
    8000640e:	e108                	sd	a0,0(a0)
  list->prev = list;
    80006410:	e508                	sd	a0,8(a0)
}
    80006412:	6422                	ld	s0,8(sp)
    80006414:	0141                	addi	sp,sp,16
    80006416:	8082                	ret

0000000080006418 <list_add>:
  next->prev = prev;
  prev->next = next;
}

void list_add(struct list_head *head, struct list_head *new)
{
    80006418:	1141                	addi	sp,sp,-16
    8000641a:	e422                	sd	s0,8(sp)
    8000641c:	0800                	addi	s0,sp,16
  __list_add(new, head, head->next);
    8000641e:	611c                	ld	a5,0(a0)
  next->prev = new;
    80006420:	e78c                	sd	a1,8(a5)
  new->next = next;
    80006422:	e19c                	sd	a5,0(a1)
  new->prev = prev;
    80006424:	e588                	sd	a0,8(a1)
  prev->next = new;
    80006426:	e10c                	sd	a1,0(a0)
}
    80006428:	6422                	ld	s0,8(sp)
    8000642a:	0141                	addi	sp,sp,16
    8000642c:	8082                	ret

000000008000642e <list_add_tail>:

void list_add_tail(struct list_head *head, struct list_head *new)
{
    8000642e:	1141                	addi	sp,sp,-16
    80006430:	e422                	sd	s0,8(sp)
    80006432:	0800                	addi	s0,sp,16
  __list_add(new, head->prev, head);
    80006434:	651c                	ld	a5,8(a0)
  next->prev = new;
    80006436:	e50c                	sd	a1,8(a0)
  new->next = next;
    80006438:	e188                	sd	a0,0(a1)
  new->prev = prev;
    8000643a:	e59c                	sd	a5,8(a1)
  prev->next = new;
    8000643c:	e38c                	sd	a1,0(a5)
}
    8000643e:	6422                	ld	s0,8(sp)
    80006440:	0141                	addi	sp,sp,16
    80006442:	8082                	ret

0000000080006444 <list_del>:

void list_del(struct list_head *entry)
{
    80006444:	1141                	addi	sp,sp,-16
    80006446:	e422                	sd	s0,8(sp)
    80006448:	0800                	addi	s0,sp,16
  __list_del(entry->prev, entry->next);
    8000644a:	651c                	ld	a5,8(a0)
    8000644c:	6118                	ld	a4,0(a0)
  next->prev = prev;
    8000644e:	e71c                	sd	a5,8(a4)
  prev->next = next;
    80006450:	e398                	sd	a4,0(a5)
  entry->prev = entry->next = entry;
    80006452:	e108                	sd	a0,0(a0)
    80006454:	e508                	sd	a0,8(a0)
}
    80006456:	6422                	ld	s0,8(sp)
    80006458:	0141                	addi	sp,sp,16
    8000645a:	8082                	ret

000000008000645c <list_del_init>:

void list_del_init(struct list_head *entry)
{
    8000645c:	1141                	addi	sp,sp,-16
    8000645e:	e422                	sd	s0,8(sp)
    80006460:	0800                	addi	s0,sp,16
  __list_del(entry->prev, entry->next);
    80006462:	651c                	ld	a5,8(a0)
    80006464:	6118                	ld	a4,0(a0)
  next->prev = prev;
    80006466:	e71c                	sd	a5,8(a4)
  prev->next = next;
    80006468:	e398                	sd	a4,0(a5)
  list->next = list;
    8000646a:	e108                	sd	a0,0(a0)
  list->prev = list;
    8000646c:	e508                	sd	a0,8(a0)
  init_list_head(entry);
}
    8000646e:	6422                	ld	s0,8(sp)
    80006470:	0141                	addi	sp,sp,16
    80006472:	8082                	ret
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
