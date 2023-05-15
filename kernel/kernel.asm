
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
    80000056:	b6e70713          	addi	a4,a4,-1170 # 80008bc0 <timer_scratch>
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
    80000068:	d7c78793          	addi	a5,a5,-644 # 80005de0 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd4567>
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
    80000190:	b7450513          	addi	a0,a0,-1164 # 80010d00 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a56080e7          	jalr	-1450(ra) # 80000bea <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	b6448493          	addi	s1,s1,-1180 # 80010d00 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	bf290913          	addi	s2,s2,-1038 # 80010d98 <cons+0x98>
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
    8000022e:	ad650513          	addi	a0,a0,-1322 # 80010d00 <cons>
    80000232:	00001097          	auipc	ra,0x1
    80000236:	a6c080e7          	jalr	-1428(ra) # 80000c9e <release>

  return target - n;
    8000023a:	414b853b          	subw	a0,s7,s4
    8000023e:	a811                	j	80000252 <consoleread+0xee>
        release(&cons.lock);
    80000240:	00011517          	auipc	a0,0x11
    80000244:	ac050513          	addi	a0,a0,-1344 # 80010d00 <cons>
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
    8000027c:	b2f72023          	sw	a5,-1248(a4) # 80010d98 <cons+0x98>
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
    800002d6:	a2e50513          	addi	a0,a0,-1490 # 80010d00 <cons>
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
    80000304:	a0050513          	addi	a0,a0,-1536 # 80010d00 <cons>
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
    80000328:	9dc70713          	addi	a4,a4,-1572 # 80010d00 <cons>
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
    80000352:	9b278793          	addi	a5,a5,-1614 # 80010d00 <cons>
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
    80000380:	a1c7a783          	lw	a5,-1508(a5) # 80010d98 <cons+0x98>
    80000384:	9f1d                	subw	a4,a4,a5
    80000386:	08000793          	li	a5,128
    8000038a:	f6f71be3          	bne	a4,a5,80000300 <consoleintr+0x3c>
    8000038e:	a07d                	j	8000043c <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000390:	00011717          	auipc	a4,0x11
    80000394:	97070713          	addi	a4,a4,-1680 # 80010d00 <cons>
    80000398:	0a072783          	lw	a5,160(a4)
    8000039c:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a0:	00011497          	auipc	s1,0x11
    800003a4:	96048493          	addi	s1,s1,-1696 # 80010d00 <cons>
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
    800003e0:	92470713          	addi	a4,a4,-1756 # 80010d00 <cons>
    800003e4:	0a072783          	lw	a5,160(a4)
    800003e8:	09c72703          	lw	a4,156(a4)
    800003ec:	f0f70ae3          	beq	a4,a5,80000300 <consoleintr+0x3c>
      cons.e--;
    800003f0:	37fd                	addiw	a5,a5,-1
    800003f2:	00011717          	auipc	a4,0x11
    800003f6:	9af72723          	sw	a5,-1618(a4) # 80010da0 <cons+0xa0>
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
    8000041c:	8e878793          	addi	a5,a5,-1816 # 80010d00 <cons>
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
    80000440:	96c7a023          	sw	a2,-1696(a5) # 80010d9c <cons+0x9c>
        wakeup(&cons.r);
    80000444:	00011517          	auipc	a0,0x11
    80000448:	95450513          	addi	a0,a0,-1708 # 80010d98 <cons+0x98>
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
    8000046a:	89a50513          	addi	a0,a0,-1894 # 80010d00 <cons>
    8000046e:	00000097          	auipc	ra,0x0
    80000472:	6ec080e7          	jalr	1772(ra) # 80000b5a <initlock>

  uartinit();
    80000476:	00000097          	auipc	ra,0x0
    8000047a:	330080e7          	jalr	816(ra) # 800007a6 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047e:	00029797          	auipc	a5,0x29
    80000482:	c8278793          	addi	a5,a5,-894 # 80029100 <devsw>
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
    80000554:	8607a823          	sw	zero,-1936(a5) # 80010dc0 <pr+0x18>
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
    80000588:	5ef72e23          	sw	a5,1532(a4) # 80008b80 <panicked>
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
    800005c4:	800dad83          	lw	s11,-2048(s11) # 80010dc0 <pr+0x18>
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
    80000602:	7aa50513          	addi	a0,a0,1962 # 80010da8 <pr>
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
    80000766:	64650513          	addi	a0,a0,1606 # 80010da8 <pr>
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
    80000782:	62a48493          	addi	s1,s1,1578 # 80010da8 <pr>
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
    800007e2:	5ea50513          	addi	a0,a0,1514 # 80010dc8 <uart_tx_lock>
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
    8000080e:	3767a783          	lw	a5,886(a5) # 80008b80 <panicked>
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
    8000084a:	34273703          	ld	a4,834(a4) # 80008b88 <uart_tx_r>
    8000084e:	00008797          	auipc	a5,0x8
    80000852:	3427b783          	ld	a5,834(a5) # 80008b90 <uart_tx_w>
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
    80000874:	558a0a13          	addi	s4,s4,1368 # 80010dc8 <uart_tx_lock>
    uart_tx_r += 1;
    80000878:	00008497          	auipc	s1,0x8
    8000087c:	31048493          	addi	s1,s1,784 # 80008b88 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000880:	00008997          	auipc	s3,0x8
    80000884:	31098993          	addi	s3,s3,784 # 80008b90 <uart_tx_w>
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
    800008e6:	4e650513          	addi	a0,a0,1254 # 80010dc8 <uart_tx_lock>
    800008ea:	00000097          	auipc	ra,0x0
    800008ee:	300080e7          	jalr	768(ra) # 80000bea <acquire>
  if(panicked){
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	28e7a783          	lw	a5,654(a5) # 80008b80 <panicked>
    800008fa:	e7c9                	bnez	a5,80000984 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fc:	00008797          	auipc	a5,0x8
    80000900:	2947b783          	ld	a5,660(a5) # 80008b90 <uart_tx_w>
    80000904:	00008717          	auipc	a4,0x8
    80000908:	28473703          	ld	a4,644(a4) # 80008b88 <uart_tx_r>
    8000090c:	02070713          	addi	a4,a4,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00010a17          	auipc	s4,0x10
    80000914:	4b8a0a13          	addi	s4,s4,1208 # 80010dc8 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	27048493          	addi	s1,s1,624 # 80008b88 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	27090913          	addi	s2,s2,624 # 80008b90 <uart_tx_w>
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
    8000094a:	48248493          	addi	s1,s1,1154 # 80010dc8 <uart_tx_lock>
    8000094e:	01f7f713          	andi	a4,a5,31
    80000952:	9726                	add	a4,a4,s1
    80000954:	01370c23          	sb	s3,24(a4)
  uart_tx_w += 1;
    80000958:	0785                	addi	a5,a5,1
    8000095a:	00008717          	auipc	a4,0x8
    8000095e:	22f73b23          	sd	a5,566(a4) # 80008b90 <uart_tx_w>
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
    800009d4:	3f848493          	addi	s1,s1,1016 # 80010dc8 <uart_tx_lock>
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
    80000a16:	88678793          	addi	a5,a5,-1914 # 8002a298 <end>
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
    80000a36:	3ce90913          	addi	s2,s2,974 # 80010e00 <kmem>
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
    80000ad2:	33250513          	addi	a0,a0,818 # 80010e00 <kmem>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	084080e7          	jalr	132(ra) # 80000b5a <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ade:	45c5                	li	a1,17
    80000ae0:	05ee                	slli	a1,a1,0x1b
    80000ae2:	00029517          	auipc	a0,0x29
    80000ae6:	7b650513          	addi	a0,a0,1974 # 8002a298 <end>
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
    80000b08:	2fc48493          	addi	s1,s1,764 # 80010e00 <kmem>
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
    80000b20:	2e450513          	addi	a0,a0,740 # 80010e00 <kmem>
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
    80000b4c:	2b850513          	addi	a0,a0,696 # 80010e00 <kmem>
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
    80000ea8:	cf470713          	addi	a4,a4,-780 # 80008b98 <started>
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
    80000ede:	824080e7          	jalr	-2012(ra) # 800026fe <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ee2:	00005097          	auipc	ra,0x5
    80000ee6:	f3e080e7          	jalr	-194(ra) # 80005e20 <plicinithart>
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
    80000f56:	784080e7          	jalr	1924(ra) # 800026d6 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5a:	00001097          	auipc	ra,0x1
    80000f5e:	7a4080e7          	jalr	1956(ra) # 800026fe <trapinithart>
    plicinit();      // set up interrupt controller
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	ea8080e7          	jalr	-344(ra) # 80005e0a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6a:	00005097          	auipc	ra,0x5
    80000f6e:	eb6080e7          	jalr	-330(ra) # 80005e20 <plicinithart>
    binit();         // buffer cache
    80000f72:	00002097          	auipc	ra,0x2
    80000f76:	06e080e7          	jalr	110(ra) # 80002fe0 <binit>
    iinit();         // inode table
    80000f7a:	00002097          	auipc	ra,0x2
    80000f7e:	712080e7          	jalr	1810(ra) # 8000368c <iinit>
    fileinit();      // file table
    80000f82:	00003097          	auipc	ra,0x3
    80000f86:	6b0080e7          	jalr	1712(ra) # 80004632 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8a:	00005097          	auipc	ra,0x5
    80000f8e:	f9e080e7          	jalr	-98(ra) # 80005f28 <virtio_disk_init>
    userinit();      // first user process
    80000f92:	00001097          	auipc	ra,0x1
    80000f96:	d0c080e7          	jalr	-756(ra) # 80001c9e <userinit>
    __sync_synchronize();
    80000f9a:	0ff0000f          	fence
    started = 1;
    80000f9e:	4785                	li	a5,1
    80000fa0:	00008717          	auipc	a4,0x8
    80000fa4:	bef72c23          	sw	a5,-1032(a4) # 80008b98 <started>
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
    80000fb8:	bec7b783          	ld	a5,-1044(a5) # 80008ba0 <kernel_pagetable>
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
    80001274:	92a7b823          	sd	a0,-1744(a5) # 80008ba0 <kernel_pagetable>
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
    8000186a:	9fa48493          	addi	s1,s1,-1542 # 80011260 <proc>
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
    80001884:	5e0a0a13          	addi	s4,s4,1504 # 80016e60 <tickslock>
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
    80001906:	51e50513          	addi	a0,a0,1310 # 80010e20 <pid_lock>
    8000190a:	fffff097          	auipc	ra,0xfffff
    8000190e:	250080e7          	jalr	592(ra) # 80000b5a <initlock>
  initlock(&wait_lock, "wait_lock");
    80001912:	00007597          	auipc	a1,0x7
    80001916:	8d658593          	addi	a1,a1,-1834 # 800081e8 <digits+0x1a8>
    8000191a:	0000f517          	auipc	a0,0xf
    8000191e:	51e50513          	addi	a0,a0,1310 # 80010e38 <wait_lock>
    80001922:	fffff097          	auipc	ra,0xfffff
    80001926:	238080e7          	jalr	568(ra) # 80000b5a <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000192a:	00010497          	auipc	s1,0x10
    8000192e:	93648493          	addi	s1,s1,-1738 # 80011260 <proc>
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
    80001950:	51498993          	addi	s3,s3,1300 # 80016e60 <tickslock>
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
    800019ba:	49a50513          	addi	a0,a0,1178 # 80010e50 <cpus>
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
    800019e2:	44270713          	addi	a4,a4,1090 # 80010e20 <pid_lock>
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
    80001a1a:	02a7a783          	lw	a5,42(a5) # 80008a40 <first.1719>
    80001a1e:	eb89                	bnez	a5,80001a30 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a20:	00001097          	auipc	ra,0x1
    80001a24:	cf6080e7          	jalr	-778(ra) # 80002716 <usertrapret>
}
    80001a28:	60a2                	ld	ra,8(sp)
    80001a2a:	6402                	ld	s0,0(sp)
    80001a2c:	0141                	addi	sp,sp,16
    80001a2e:	8082                	ret
    first = 0;
    80001a30:	00007797          	auipc	a5,0x7
    80001a34:	0007a823          	sw	zero,16(a5) # 80008a40 <first.1719>
    fsinit(ROOTDEV);
    80001a38:	4505                	li	a0,1
    80001a3a:	00002097          	auipc	ra,0x2
    80001a3e:	bd2080e7          	jalr	-1070(ra) # 8000360c <fsinit>
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
    80001a54:	3d090913          	addi	s2,s2,976 # 80010e20 <pid_lock>
    80001a58:	854a                	mv	a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	190080e7          	jalr	400(ra) # 80000bea <acquire>
  pid = nextpid;
    80001a62:	00007797          	auipc	a5,0x7
    80001a66:	fe278793          	addi	a5,a5,-30 # 80008a44 <nextpid>
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
    80001be0:	68448493          	addi	s1,s1,1668 # 80011260 <proc>
    80001be4:	00015917          	auipc	s2,0x15
    80001be8:	27c90913          	addi	s2,s2,636 # 80016e60 <tickslock>
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
    80001cb6:	eea7bb23          	sd	a0,-266(a5) # 80008ba8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cba:	03400613          	li	a2,52
    80001cbe:	00007597          	auipc	a1,0x7
    80001cc2:	d9258593          	addi	a1,a1,-622 # 80008a50 <initcode>
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
    80001d00:	332080e7          	jalr	818(ra) # 8000402e <namei>
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
    80001e1e:	8aa080e7          	jalr	-1878(ra) # 800046c4 <filedup>
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
    80001e40:	a0e080e7          	jalr	-1522(ra) # 8000384a <idup>
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
    80001e6c:	fd048493          	addi	s1,s1,-48 # 80010e38 <wait_lock>
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
    80001f62:	ec270713          	addi	a4,a4,-318 # 80010e20 <pid_lock>
    80001f66:	975a                	add	a4,a4,s6
    80001f68:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f6c:	0000f717          	auipc	a4,0xf
    80001f70:	eec70713          	addi	a4,a4,-276 # 80010e58 <cpus+0x8>
    80001f74:	9b3a                	add	s6,s6,a4
        p->state = RUNNING;
    80001f76:	4b91                	li	s7,4
        c->proc = p;
    80001f78:	079e                	slli	a5,a5,0x7
    80001f7a:	0000fa97          	auipc	s5,0xf
    80001f7e:	ea6a8a93          	addi	s5,s5,-346 # 80010e20 <pid_lock>
    80001f82:	9abe                	add	s5,s5,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f84:	00015a17          	auipc	s4,0x15
    80001f88:	edca0a13          	addi	s4,s4,-292 # 80016e60 <tickslock>
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
    80001fa2:	6ce080e7          	jalr	1742(ra) # 8000266c <swtch>
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
    80001fea:	27a48493          	addi	s1,s1,634 # 80011260 <proc>
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
    80002024:	e0070713          	addi	a4,a4,-512 # 80010e20 <pid_lock>
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
    8000204a:	dda90913          	addi	s2,s2,-550 # 80010e20 <pid_lock>
    8000204e:	2781                	sext.w	a5,a5
    80002050:	079e                	slli	a5,a5,0x7
    80002052:	97ca                	add	a5,a5,s2
    80002054:	0ac7a983          	lw	s3,172(a5)
    80002058:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000205a:	2781                	sext.w	a5,a5
    8000205c:	079e                	slli	a5,a5,0x7
    8000205e:	0000f597          	auipc	a1,0xf
    80002062:	dfa58593          	addi	a1,a1,-518 # 80010e58 <cpus+0x8>
    80002066:	95be                	add	a1,a1,a5
    80002068:	06048513          	addi	a0,s1,96
    8000206c:	00000097          	auipc	ra,0x0
    80002070:	600080e7          	jalr	1536(ra) # 8000266c <swtch>
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
    80002186:	0de48493          	addi	s1,s1,222 # 80011260 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000218a:	4989                	li	s3,2
        p->state = RUNNABLE;
    8000218c:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000218e:	00015917          	auipc	s2,0x15
    80002192:	cd290913          	addi	s2,s2,-814 # 80016e60 <tickslock>
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
    800021fa:	06a48493          	addi	s1,s1,106 # 80011260 <proc>
      pp->parent = initproc;
    800021fe:	00007a17          	auipc	s4,0x7
    80002202:	9aaa0a13          	addi	s4,s4,-1622 # 80008ba8 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002206:	00015997          	auipc	s3,0x15
    8000220a:	c5a98993          	addi	s3,s3,-934 # 80016e60 <tickslock>
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
    8000225e:	94e7b783          	ld	a5,-1714(a5) # 80008ba8 <initproc>
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
    80002282:	498080e7          	jalr	1176(ra) # 80004716 <fileclose>
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
    8000229a:	fb4080e7          	jalr	-76(ra) # 8000424a <begin_op>
  iput(p->cwd);
    8000229e:	1509b503          	ld	a0,336(s3)
    800022a2:	00001097          	auipc	ra,0x1
    800022a6:	7a0080e7          	jalr	1952(ra) # 80003a42 <iput>
  end_op();
    800022aa:	00002097          	auipc	ra,0x2
    800022ae:	020080e7          	jalr	32(ra) # 800042ca <end_op>
  p->cwd = 0;
    800022b2:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800022b6:	0000f497          	auipc	s1,0xf
    800022ba:	b8248493          	addi	s1,s1,-1150 # 80010e38 <wait_lock>
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
    80002328:	f3c48493          	addi	s1,s1,-196 # 80011260 <proc>
    8000232c:	00015997          	auipc	s3,0x15
    80002330:	b3498993          	addi	s3,s3,-1228 # 80016e60 <tickslock>
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
    8000240c:	a3050513          	addi	a0,a0,-1488 # 80010e38 <wait_lock>
    80002410:	ffffe097          	auipc	ra,0xffffe
    80002414:	7da080e7          	jalr	2010(ra) # 80000bea <acquire>
    havekids = 0;
    80002418:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    8000241a:	4a15                	li	s4,5
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000241c:	00015997          	auipc	s3,0x15
    80002420:	a4498993          	addi	s3,s3,-1468 # 80016e60 <tickslock>
        havekids = 1;
    80002424:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002426:	0000fc17          	auipc	s8,0xf
    8000242a:	a12c0c13          	addi	s8,s8,-1518 # 80010e38 <wait_lock>
    havekids = 0;
    8000242e:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002430:	0000f497          	auipc	s1,0xf
    80002434:	e3048493          	addi	s1,s1,-464 # 80011260 <proc>
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
    80002472:	9ca50513          	addi	a0,a0,-1590 # 80010e38 <wait_lock>
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
    8000248e:	9ae50513          	addi	a0,a0,-1618 # 80010e38 <wait_lock>
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
    800024dc:	96050513          	addi	a0,a0,-1696 # 80010e38 <wait_lock>
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
    800025e8:	dd448493          	addi	s1,s1,-556 # 800113b8 <proc+0x158>
    800025ec:	00015917          	auipc	s2,0x15
    800025f0:	9cc90913          	addi	s2,s2,-1588 # 80016fb8 <bruh+0xe8>
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
    80002612:	d52b8b93          	addi	s7,s7,-686 # 80008360 <states.1763>
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

000000008000266c <swtch>:
    8000266c:	00153023          	sd	ra,0(a0)
    80002670:	00253423          	sd	sp,8(a0)
    80002674:	e900                	sd	s0,16(a0)
    80002676:	ed04                	sd	s1,24(a0)
    80002678:	03253023          	sd	s2,32(a0)
    8000267c:	03353423          	sd	s3,40(a0)
    80002680:	03453823          	sd	s4,48(a0)
    80002684:	03553c23          	sd	s5,56(a0)
    80002688:	05653023          	sd	s6,64(a0)
    8000268c:	05753423          	sd	s7,72(a0)
    80002690:	05853823          	sd	s8,80(a0)
    80002694:	05953c23          	sd	s9,88(a0)
    80002698:	07a53023          	sd	s10,96(a0)
    8000269c:	07b53423          	sd	s11,104(a0)
    800026a0:	0005b083          	ld	ra,0(a1)
    800026a4:	0085b103          	ld	sp,8(a1)
    800026a8:	6980                	ld	s0,16(a1)
    800026aa:	6d84                	ld	s1,24(a1)
    800026ac:	0205b903          	ld	s2,32(a1)
    800026b0:	0285b983          	ld	s3,40(a1)
    800026b4:	0305ba03          	ld	s4,48(a1)
    800026b8:	0385ba83          	ld	s5,56(a1)
    800026bc:	0405bb03          	ld	s6,64(a1)
    800026c0:	0485bb83          	ld	s7,72(a1)
    800026c4:	0505bc03          	ld	s8,80(a1)
    800026c8:	0585bc83          	ld	s9,88(a1)
    800026cc:	0605bd03          	ld	s10,96(a1)
    800026d0:	0685bd83          	ld	s11,104(a1)
    800026d4:	8082                	ret

00000000800026d6 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026d6:	1141                	addi	sp,sp,-16
    800026d8:	e406                	sd	ra,8(sp)
    800026da:	e022                	sd	s0,0(sp)
    800026dc:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026de:	00006597          	auipc	a1,0x6
    800026e2:	cb258593          	addi	a1,a1,-846 # 80008390 <states.1763+0x30>
    800026e6:	00014517          	auipc	a0,0x14
    800026ea:	77a50513          	addi	a0,a0,1914 # 80016e60 <tickslock>
    800026ee:	ffffe097          	auipc	ra,0xffffe
    800026f2:	46c080e7          	jalr	1132(ra) # 80000b5a <initlock>
}
    800026f6:	60a2                	ld	ra,8(sp)
    800026f8:	6402                	ld	s0,0(sp)
    800026fa:	0141                	addi	sp,sp,16
    800026fc:	8082                	ret

00000000800026fe <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800026fe:	1141                	addi	sp,sp,-16
    80002700:	e422                	sd	s0,8(sp)
    80002702:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002704:	00003797          	auipc	a5,0x3
    80002708:	64c78793          	addi	a5,a5,1612 # 80005d50 <kernelvec>
    8000270c:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002710:	6422                	ld	s0,8(sp)
    80002712:	0141                	addi	sp,sp,16
    80002714:	8082                	ret

0000000080002716 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002716:	1141                	addi	sp,sp,-16
    80002718:	e406                	sd	ra,8(sp)
    8000271a:	e022                	sd	s0,0(sp)
    8000271c:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000271e:	fffff097          	auipc	ra,0xfffff
    80002722:	2a8080e7          	jalr	680(ra) # 800019c6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002726:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000272a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000272c:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002730:	00005617          	auipc	a2,0x5
    80002734:	8d060613          	addi	a2,a2,-1840 # 80007000 <_trampoline>
    80002738:	00005697          	auipc	a3,0x5
    8000273c:	8c868693          	addi	a3,a3,-1848 # 80007000 <_trampoline>
    80002740:	8e91                	sub	a3,a3,a2
    80002742:	040007b7          	lui	a5,0x4000
    80002746:	17fd                	addi	a5,a5,-1
    80002748:	07b2                	slli	a5,a5,0xc
    8000274a:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000274c:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002750:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002752:	180026f3          	csrr	a3,satp
    80002756:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002758:	6d38                	ld	a4,88(a0)
    8000275a:	6134                	ld	a3,64(a0)
    8000275c:	6585                	lui	a1,0x1
    8000275e:	96ae                	add	a3,a3,a1
    80002760:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002762:	6d38                	ld	a4,88(a0)
    80002764:	00000697          	auipc	a3,0x0
    80002768:	13068693          	addi	a3,a3,304 # 80002894 <usertrap>
    8000276c:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000276e:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002770:	8692                	mv	a3,tp
    80002772:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002774:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002778:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000277c:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002780:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002784:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002786:	6f18                	ld	a4,24(a4)
    80002788:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000278c:	6928                	ld	a0,80(a0)
    8000278e:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002790:	00005717          	auipc	a4,0x5
    80002794:	90c70713          	addi	a4,a4,-1780 # 8000709c <userret>
    80002798:	8f11                	sub	a4,a4,a2
    8000279a:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    8000279c:	577d                	li	a4,-1
    8000279e:	177e                	slli	a4,a4,0x3f
    800027a0:	8d59                	or	a0,a0,a4
    800027a2:	9782                	jalr	a5
}
    800027a4:	60a2                	ld	ra,8(sp)
    800027a6:	6402                	ld	s0,0(sp)
    800027a8:	0141                	addi	sp,sp,16
    800027aa:	8082                	ret

00000000800027ac <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800027ac:	1101                	addi	sp,sp,-32
    800027ae:	ec06                	sd	ra,24(sp)
    800027b0:	e822                	sd	s0,16(sp)
    800027b2:	e426                	sd	s1,8(sp)
    800027b4:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800027b6:	00014497          	auipc	s1,0x14
    800027ba:	6aa48493          	addi	s1,s1,1706 # 80016e60 <tickslock>
    800027be:	8526                	mv	a0,s1
    800027c0:	ffffe097          	auipc	ra,0xffffe
    800027c4:	42a080e7          	jalr	1066(ra) # 80000bea <acquire>
  ticks++;
    800027c8:	00006517          	auipc	a0,0x6
    800027cc:	3e850513          	addi	a0,a0,1000 # 80008bb0 <ticks>
    800027d0:	411c                	lw	a5,0(a0)
    800027d2:	2785                	addiw	a5,a5,1
    800027d4:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800027d6:	00000097          	auipc	ra,0x0
    800027da:	998080e7          	jalr	-1640(ra) # 8000216e <wakeup>
  release(&tickslock);
    800027de:	8526                	mv	a0,s1
    800027e0:	ffffe097          	auipc	ra,0xffffe
    800027e4:	4be080e7          	jalr	1214(ra) # 80000c9e <release>
}
    800027e8:	60e2                	ld	ra,24(sp)
    800027ea:	6442                	ld	s0,16(sp)
    800027ec:	64a2                	ld	s1,8(sp)
    800027ee:	6105                	addi	sp,sp,32
    800027f0:	8082                	ret

00000000800027f2 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800027f2:	1101                	addi	sp,sp,-32
    800027f4:	ec06                	sd	ra,24(sp)
    800027f6:	e822                	sd	s0,16(sp)
    800027f8:	e426                	sd	s1,8(sp)
    800027fa:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027fc:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002800:	00074d63          	bltz	a4,8000281a <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002804:	57fd                	li	a5,-1
    80002806:	17fe                	slli	a5,a5,0x3f
    80002808:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000280a:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000280c:	06f70363          	beq	a4,a5,80002872 <devintr+0x80>
  }
}
    80002810:	60e2                	ld	ra,24(sp)
    80002812:	6442                	ld	s0,16(sp)
    80002814:	64a2                	ld	s1,8(sp)
    80002816:	6105                	addi	sp,sp,32
    80002818:	8082                	ret
     (scause & 0xff) == 9){
    8000281a:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000281e:	46a5                	li	a3,9
    80002820:	fed792e3          	bne	a5,a3,80002804 <devintr+0x12>
    int irq = plic_claim();
    80002824:	00003097          	auipc	ra,0x3
    80002828:	634080e7          	jalr	1588(ra) # 80005e58 <plic_claim>
    8000282c:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000282e:	47a9                	li	a5,10
    80002830:	02f50763          	beq	a0,a5,8000285e <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002834:	4785                	li	a5,1
    80002836:	02f50963          	beq	a0,a5,80002868 <devintr+0x76>
    return 1;
    8000283a:	4505                	li	a0,1
    } else if(irq){
    8000283c:	d8f1                	beqz	s1,80002810 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000283e:	85a6                	mv	a1,s1
    80002840:	00006517          	auipc	a0,0x6
    80002844:	b5850513          	addi	a0,a0,-1192 # 80008398 <states.1763+0x38>
    80002848:	ffffe097          	auipc	ra,0xffffe
    8000284c:	d46080e7          	jalr	-698(ra) # 8000058e <printf>
      plic_complete(irq);
    80002850:	8526                	mv	a0,s1
    80002852:	00003097          	auipc	ra,0x3
    80002856:	62a080e7          	jalr	1578(ra) # 80005e7c <plic_complete>
    return 1;
    8000285a:	4505                	li	a0,1
    8000285c:	bf55                	j	80002810 <devintr+0x1e>
      uartintr();
    8000285e:	ffffe097          	auipc	ra,0xffffe
    80002862:	150080e7          	jalr	336(ra) # 800009ae <uartintr>
    80002866:	b7ed                	j	80002850 <devintr+0x5e>
      virtio_disk_intr();
    80002868:	00004097          	auipc	ra,0x4
    8000286c:	b3e080e7          	jalr	-1218(ra) # 800063a6 <virtio_disk_intr>
    80002870:	b7c5                	j	80002850 <devintr+0x5e>
    if(cpuid() == 0){
    80002872:	fffff097          	auipc	ra,0xfffff
    80002876:	128080e7          	jalr	296(ra) # 8000199a <cpuid>
    8000287a:	c901                	beqz	a0,8000288a <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000287c:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002880:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002882:	14479073          	csrw	sip,a5
    return 2;
    80002886:	4509                	li	a0,2
    80002888:	b761                	j	80002810 <devintr+0x1e>
      clockintr();
    8000288a:	00000097          	auipc	ra,0x0
    8000288e:	f22080e7          	jalr	-222(ra) # 800027ac <clockintr>
    80002892:	b7ed                	j	8000287c <devintr+0x8a>

0000000080002894 <usertrap>:
{
    80002894:	1101                	addi	sp,sp,-32
    80002896:	ec06                	sd	ra,24(sp)
    80002898:	e822                	sd	s0,16(sp)
    8000289a:	e426                	sd	s1,8(sp)
    8000289c:	e04a                	sd	s2,0(sp)
    8000289e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028a0:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800028a4:	1007f793          	andi	a5,a5,256
    800028a8:	e3b1                	bnez	a5,800028ec <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028aa:	00003797          	auipc	a5,0x3
    800028ae:	4a678793          	addi	a5,a5,1190 # 80005d50 <kernelvec>
    800028b2:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800028b6:	fffff097          	auipc	ra,0xfffff
    800028ba:	110080e7          	jalr	272(ra) # 800019c6 <myproc>
    800028be:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800028c0:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028c2:	14102773          	csrr	a4,sepc
    800028c6:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028c8:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800028cc:	47a1                	li	a5,8
    800028ce:	02f70763          	beq	a4,a5,800028fc <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    800028d2:	00000097          	auipc	ra,0x0
    800028d6:	f20080e7          	jalr	-224(ra) # 800027f2 <devintr>
    800028da:	892a                	mv	s2,a0
    800028dc:	c151                	beqz	a0,80002960 <usertrap+0xcc>
  if(killed(p))
    800028de:	8526                	mv	a0,s1
    800028e0:	00000097          	auipc	ra,0x0
    800028e4:	ad2080e7          	jalr	-1326(ra) # 800023b2 <killed>
    800028e8:	c929                	beqz	a0,8000293a <usertrap+0xa6>
    800028ea:	a099                	j	80002930 <usertrap+0x9c>
    panic("usertrap: not from user mode");
    800028ec:	00006517          	auipc	a0,0x6
    800028f0:	acc50513          	addi	a0,a0,-1332 # 800083b8 <states.1763+0x58>
    800028f4:	ffffe097          	auipc	ra,0xffffe
    800028f8:	c50080e7          	jalr	-944(ra) # 80000544 <panic>
    if(killed(p))
    800028fc:	00000097          	auipc	ra,0x0
    80002900:	ab6080e7          	jalr	-1354(ra) # 800023b2 <killed>
    80002904:	e921                	bnez	a0,80002954 <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002906:	6cb8                	ld	a4,88(s1)
    80002908:	6f1c                	ld	a5,24(a4)
    8000290a:	0791                	addi	a5,a5,4
    8000290c:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000290e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002912:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002916:	10079073          	csrw	sstatus,a5
    syscall();
    8000291a:	00000097          	auipc	ra,0x0
    8000291e:	2d4080e7          	jalr	724(ra) # 80002bee <syscall>
  if(killed(p))
    80002922:	8526                	mv	a0,s1
    80002924:	00000097          	auipc	ra,0x0
    80002928:	a8e080e7          	jalr	-1394(ra) # 800023b2 <killed>
    8000292c:	c911                	beqz	a0,80002940 <usertrap+0xac>
    8000292e:	4901                	li	s2,0
    exit(-1);
    80002930:	557d                	li	a0,-1
    80002932:	00000097          	auipc	ra,0x0
    80002936:	90c080e7          	jalr	-1780(ra) # 8000223e <exit>
  if(which_dev == 2)
    8000293a:	4789                	li	a5,2
    8000293c:	04f90f63          	beq	s2,a5,8000299a <usertrap+0x106>
  usertrapret();
    80002940:	00000097          	auipc	ra,0x0
    80002944:	dd6080e7          	jalr	-554(ra) # 80002716 <usertrapret>
}
    80002948:	60e2                	ld	ra,24(sp)
    8000294a:	6442                	ld	s0,16(sp)
    8000294c:	64a2                	ld	s1,8(sp)
    8000294e:	6902                	ld	s2,0(sp)
    80002950:	6105                	addi	sp,sp,32
    80002952:	8082                	ret
      exit(-1);
    80002954:	557d                	li	a0,-1
    80002956:	00000097          	auipc	ra,0x0
    8000295a:	8e8080e7          	jalr	-1816(ra) # 8000223e <exit>
    8000295e:	b765                	j	80002906 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002960:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002964:	5890                	lw	a2,48(s1)
    80002966:	00006517          	auipc	a0,0x6
    8000296a:	a7250513          	addi	a0,a0,-1422 # 800083d8 <states.1763+0x78>
    8000296e:	ffffe097          	auipc	ra,0xffffe
    80002972:	c20080e7          	jalr	-992(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002976:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000297a:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000297e:	00006517          	auipc	a0,0x6
    80002982:	a8a50513          	addi	a0,a0,-1398 # 80008408 <states.1763+0xa8>
    80002986:	ffffe097          	auipc	ra,0xffffe
    8000298a:	c08080e7          	jalr	-1016(ra) # 8000058e <printf>
    setkilled(p);
    8000298e:	8526                	mv	a0,s1
    80002990:	00000097          	auipc	ra,0x0
    80002994:	9f6080e7          	jalr	-1546(ra) # 80002386 <setkilled>
    80002998:	b769                	j	80002922 <usertrap+0x8e>
    yield();
    8000299a:	fffff097          	auipc	ra,0xfffff
    8000299e:	734080e7          	jalr	1844(ra) # 800020ce <yield>
    800029a2:	bf79                	j	80002940 <usertrap+0xac>

00000000800029a4 <kerneltrap>:
{
    800029a4:	7179                	addi	sp,sp,-48
    800029a6:	f406                	sd	ra,40(sp)
    800029a8:	f022                	sd	s0,32(sp)
    800029aa:	ec26                	sd	s1,24(sp)
    800029ac:	e84a                	sd	s2,16(sp)
    800029ae:	e44e                	sd	s3,8(sp)
    800029b0:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029b2:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029b6:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029ba:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800029be:	1004f793          	andi	a5,s1,256
    800029c2:	cb85                	beqz	a5,800029f2 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029c4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800029c8:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800029ca:	ef85                	bnez	a5,80002a02 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800029cc:	00000097          	auipc	ra,0x0
    800029d0:	e26080e7          	jalr	-474(ra) # 800027f2 <devintr>
    800029d4:	cd1d                	beqz	a0,80002a12 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029d6:	4789                	li	a5,2
    800029d8:	06f50a63          	beq	a0,a5,80002a4c <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029dc:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029e0:	10049073          	csrw	sstatus,s1
}
    800029e4:	70a2                	ld	ra,40(sp)
    800029e6:	7402                	ld	s0,32(sp)
    800029e8:	64e2                	ld	s1,24(sp)
    800029ea:	6942                	ld	s2,16(sp)
    800029ec:	69a2                	ld	s3,8(sp)
    800029ee:	6145                	addi	sp,sp,48
    800029f0:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800029f2:	00006517          	auipc	a0,0x6
    800029f6:	a3650513          	addi	a0,a0,-1482 # 80008428 <states.1763+0xc8>
    800029fa:	ffffe097          	auipc	ra,0xffffe
    800029fe:	b4a080e7          	jalr	-1206(ra) # 80000544 <panic>
    panic("kerneltrap: interrupts enabled");
    80002a02:	00006517          	auipc	a0,0x6
    80002a06:	a4e50513          	addi	a0,a0,-1458 # 80008450 <states.1763+0xf0>
    80002a0a:	ffffe097          	auipc	ra,0xffffe
    80002a0e:	b3a080e7          	jalr	-1222(ra) # 80000544 <panic>
    printf("scause %p\n", scause);
    80002a12:	85ce                	mv	a1,s3
    80002a14:	00006517          	auipc	a0,0x6
    80002a18:	a5c50513          	addi	a0,a0,-1444 # 80008470 <states.1763+0x110>
    80002a1c:	ffffe097          	auipc	ra,0xffffe
    80002a20:	b72080e7          	jalr	-1166(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a24:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a28:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a2c:	00006517          	auipc	a0,0x6
    80002a30:	a5450513          	addi	a0,a0,-1452 # 80008480 <states.1763+0x120>
    80002a34:	ffffe097          	auipc	ra,0xffffe
    80002a38:	b5a080e7          	jalr	-1190(ra) # 8000058e <printf>
    panic("kerneltrap");
    80002a3c:	00006517          	auipc	a0,0x6
    80002a40:	a5c50513          	addi	a0,a0,-1444 # 80008498 <states.1763+0x138>
    80002a44:	ffffe097          	auipc	ra,0xffffe
    80002a48:	b00080e7          	jalr	-1280(ra) # 80000544 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a4c:	fffff097          	auipc	ra,0xfffff
    80002a50:	f7a080e7          	jalr	-134(ra) # 800019c6 <myproc>
    80002a54:	d541                	beqz	a0,800029dc <kerneltrap+0x38>
    80002a56:	fffff097          	auipc	ra,0xfffff
    80002a5a:	f70080e7          	jalr	-144(ra) # 800019c6 <myproc>
    80002a5e:	4d18                	lw	a4,24(a0)
    80002a60:	4791                	li	a5,4
    80002a62:	f6f71de3          	bne	a4,a5,800029dc <kerneltrap+0x38>
    yield();
    80002a66:	fffff097          	auipc	ra,0xfffff
    80002a6a:	668080e7          	jalr	1640(ra) # 800020ce <yield>
    80002a6e:	b7bd                	j	800029dc <kerneltrap+0x38>

0000000080002a70 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a70:	1101                	addi	sp,sp,-32
    80002a72:	ec06                	sd	ra,24(sp)
    80002a74:	e822                	sd	s0,16(sp)
    80002a76:	e426                	sd	s1,8(sp)
    80002a78:	1000                	addi	s0,sp,32
    80002a7a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a7c:	fffff097          	auipc	ra,0xfffff
    80002a80:	f4a080e7          	jalr	-182(ra) # 800019c6 <myproc>
  switch (n) {
    80002a84:	4795                	li	a5,5
    80002a86:	0497e163          	bltu	a5,s1,80002ac8 <argraw+0x58>
    80002a8a:	048a                	slli	s1,s1,0x2
    80002a8c:	00006717          	auipc	a4,0x6
    80002a90:	b7c70713          	addi	a4,a4,-1156 # 80008608 <states.1763+0x2a8>
    80002a94:	94ba                	add	s1,s1,a4
    80002a96:	409c                	lw	a5,0(s1)
    80002a98:	97ba                	add	a5,a5,a4
    80002a9a:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a9c:	6d3c                	ld	a5,88(a0)
    80002a9e:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002aa0:	60e2                	ld	ra,24(sp)
    80002aa2:	6442                	ld	s0,16(sp)
    80002aa4:	64a2                	ld	s1,8(sp)
    80002aa6:	6105                	addi	sp,sp,32
    80002aa8:	8082                	ret
    return p->trapframe->a1;
    80002aaa:	6d3c                	ld	a5,88(a0)
    80002aac:	7fa8                	ld	a0,120(a5)
    80002aae:	bfcd                	j	80002aa0 <argraw+0x30>
    return p->trapframe->a2;
    80002ab0:	6d3c                	ld	a5,88(a0)
    80002ab2:	63c8                	ld	a0,128(a5)
    80002ab4:	b7f5                	j	80002aa0 <argraw+0x30>
    return p->trapframe->a3;
    80002ab6:	6d3c                	ld	a5,88(a0)
    80002ab8:	67c8                	ld	a0,136(a5)
    80002aba:	b7dd                	j	80002aa0 <argraw+0x30>
    return p->trapframe->a4;
    80002abc:	6d3c                	ld	a5,88(a0)
    80002abe:	6bc8                	ld	a0,144(a5)
    80002ac0:	b7c5                	j	80002aa0 <argraw+0x30>
    return p->trapframe->a5;
    80002ac2:	6d3c                	ld	a5,88(a0)
    80002ac4:	6fc8                	ld	a0,152(a5)
    80002ac6:	bfe9                	j	80002aa0 <argraw+0x30>
  panic("argraw");
    80002ac8:	00006517          	auipc	a0,0x6
    80002acc:	9e050513          	addi	a0,a0,-1568 # 800084a8 <states.1763+0x148>
    80002ad0:	ffffe097          	auipc	ra,0xffffe
    80002ad4:	a74080e7          	jalr	-1420(ra) # 80000544 <panic>

0000000080002ad8 <fetchaddr>:
{
    80002ad8:	1101                	addi	sp,sp,-32
    80002ada:	ec06                	sd	ra,24(sp)
    80002adc:	e822                	sd	s0,16(sp)
    80002ade:	e426                	sd	s1,8(sp)
    80002ae0:	e04a                	sd	s2,0(sp)
    80002ae2:	1000                	addi	s0,sp,32
    80002ae4:	84aa                	mv	s1,a0
    80002ae6:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002ae8:	fffff097          	auipc	ra,0xfffff
    80002aec:	ede080e7          	jalr	-290(ra) # 800019c6 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002af0:	653c                	ld	a5,72(a0)
    80002af2:	02f4f863          	bgeu	s1,a5,80002b22 <fetchaddr+0x4a>
    80002af6:	00848713          	addi	a4,s1,8
    80002afa:	02e7e663          	bltu	a5,a4,80002b26 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002afe:	46a1                	li	a3,8
    80002b00:	8626                	mv	a2,s1
    80002b02:	85ca                	mv	a1,s2
    80002b04:	6928                	ld	a0,80(a0)
    80002b06:	fffff097          	auipc	ra,0xfffff
    80002b0a:	c0a080e7          	jalr	-1014(ra) # 80001710 <copyin>
    80002b0e:	00a03533          	snez	a0,a0
    80002b12:	40a00533          	neg	a0,a0
}
    80002b16:	60e2                	ld	ra,24(sp)
    80002b18:	6442                	ld	s0,16(sp)
    80002b1a:	64a2                	ld	s1,8(sp)
    80002b1c:	6902                	ld	s2,0(sp)
    80002b1e:	6105                	addi	sp,sp,32
    80002b20:	8082                	ret
    return -1;
    80002b22:	557d                	li	a0,-1
    80002b24:	bfcd                	j	80002b16 <fetchaddr+0x3e>
    80002b26:	557d                	li	a0,-1
    80002b28:	b7fd                	j	80002b16 <fetchaddr+0x3e>

0000000080002b2a <fetchstr>:
{
    80002b2a:	7179                	addi	sp,sp,-48
    80002b2c:	f406                	sd	ra,40(sp)
    80002b2e:	f022                	sd	s0,32(sp)
    80002b30:	ec26                	sd	s1,24(sp)
    80002b32:	e84a                	sd	s2,16(sp)
    80002b34:	e44e                	sd	s3,8(sp)
    80002b36:	1800                	addi	s0,sp,48
    80002b38:	892a                	mv	s2,a0
    80002b3a:	84ae                	mv	s1,a1
    80002b3c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b3e:	fffff097          	auipc	ra,0xfffff
    80002b42:	e88080e7          	jalr	-376(ra) # 800019c6 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002b46:	86ce                	mv	a3,s3
    80002b48:	864a                	mv	a2,s2
    80002b4a:	85a6                	mv	a1,s1
    80002b4c:	6928                	ld	a0,80(a0)
    80002b4e:	fffff097          	auipc	ra,0xfffff
    80002b52:	c4e080e7          	jalr	-946(ra) # 8000179c <copyinstr>
    80002b56:	00054e63          	bltz	a0,80002b72 <fetchstr+0x48>
  return strlen(buf);
    80002b5a:	8526                	mv	a0,s1
    80002b5c:	ffffe097          	auipc	ra,0xffffe
    80002b60:	30e080e7          	jalr	782(ra) # 80000e6a <strlen>
}
    80002b64:	70a2                	ld	ra,40(sp)
    80002b66:	7402                	ld	s0,32(sp)
    80002b68:	64e2                	ld	s1,24(sp)
    80002b6a:	6942                	ld	s2,16(sp)
    80002b6c:	69a2                	ld	s3,8(sp)
    80002b6e:	6145                	addi	sp,sp,48
    80002b70:	8082                	ret
    return -1;
    80002b72:	557d                	li	a0,-1
    80002b74:	bfc5                	j	80002b64 <fetchstr+0x3a>

0000000080002b76 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002b76:	1101                	addi	sp,sp,-32
    80002b78:	ec06                	sd	ra,24(sp)
    80002b7a:	e822                	sd	s0,16(sp)
    80002b7c:	e426                	sd	s1,8(sp)
    80002b7e:	1000                	addi	s0,sp,32
    80002b80:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b82:	00000097          	auipc	ra,0x0
    80002b86:	eee080e7          	jalr	-274(ra) # 80002a70 <argraw>
    80002b8a:	c088                	sw	a0,0(s1)
}
    80002b8c:	60e2                	ld	ra,24(sp)
    80002b8e:	6442                	ld	s0,16(sp)
    80002b90:	64a2                	ld	s1,8(sp)
    80002b92:	6105                	addi	sp,sp,32
    80002b94:	8082                	ret

0000000080002b96 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002b96:	1101                	addi	sp,sp,-32
    80002b98:	ec06                	sd	ra,24(sp)
    80002b9a:	e822                	sd	s0,16(sp)
    80002b9c:	e426                	sd	s1,8(sp)
    80002b9e:	1000                	addi	s0,sp,32
    80002ba0:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ba2:	00000097          	auipc	ra,0x0
    80002ba6:	ece080e7          	jalr	-306(ra) # 80002a70 <argraw>
    80002baa:	e088                	sd	a0,0(s1)
}
    80002bac:	60e2                	ld	ra,24(sp)
    80002bae:	6442                	ld	s0,16(sp)
    80002bb0:	64a2                	ld	s1,8(sp)
    80002bb2:	6105                	addi	sp,sp,32
    80002bb4:	8082                	ret

0000000080002bb6 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002bb6:	7179                	addi	sp,sp,-48
    80002bb8:	f406                	sd	ra,40(sp)
    80002bba:	f022                	sd	s0,32(sp)
    80002bbc:	ec26                	sd	s1,24(sp)
    80002bbe:	e84a                	sd	s2,16(sp)
    80002bc0:	1800                	addi	s0,sp,48
    80002bc2:	84ae                	mv	s1,a1
    80002bc4:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002bc6:	fd840593          	addi	a1,s0,-40
    80002bca:	00000097          	auipc	ra,0x0
    80002bce:	fcc080e7          	jalr	-52(ra) # 80002b96 <argaddr>
  return fetchstr(addr, buf, max);
    80002bd2:	864a                	mv	a2,s2
    80002bd4:	85a6                	mv	a1,s1
    80002bd6:	fd843503          	ld	a0,-40(s0)
    80002bda:	00000097          	auipc	ra,0x0
    80002bde:	f50080e7          	jalr	-176(ra) # 80002b2a <fetchstr>
}
    80002be2:	70a2                	ld	ra,40(sp)
    80002be4:	7402                	ld	s0,32(sp)
    80002be6:	64e2                	ld	s1,24(sp)
    80002be8:	6942                	ld	s2,16(sp)
    80002bea:	6145                	addi	sp,sp,48
    80002bec:	8082                	ret

0000000080002bee <syscall>:
};


void
syscall(void)
{
    80002bee:	711d                	addi	sp,sp,-96
    80002bf0:	ec86                	sd	ra,88(sp)
    80002bf2:	e8a2                	sd	s0,80(sp)
    80002bf4:	e4a6                	sd	s1,72(sp)
    80002bf6:	e0ca                	sd	s2,64(sp)
    80002bf8:	fc4e                	sd	s3,56(sp)
    80002bfa:	f852                	sd	s4,48(sp)
    80002bfc:	f456                	sd	s5,40(sp)
    80002bfe:	f05a                	sd	s6,32(sp)
    80002c00:	ec5e                	sd	s7,24(sp)
    80002c02:	e862                	sd	s8,16(sp)
    80002c04:	e466                	sd	s9,8(sp)
    80002c06:	1080                	addi	s0,sp,96
  int num;
  struct proc *p = myproc();
    80002c08:	fffff097          	auipc	ra,0xfffff
    80002c0c:	dbe080e7          	jalr	-578(ra) # 800019c6 <myproc>
    80002c10:	89aa                	mv	s3,a0

  num = p->trapframe->a7;
    80002c12:	6d24                	ld	s1,88(a0)
    80002c14:	74dc                	ld	a5,168(s1)
    80002c16:	00078a1b          	sext.w	s4,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c1a:	37fd                	addiw	a5,a5,-1
    80002c1c:	4755                	li	a4,21
    80002c1e:	14f76363          	bltu	a4,a5,80002d64 <syscall+0x176>
    80002c22:	003a1713          	slli	a4,s4,0x3
    80002c26:	00006797          	auipc	a5,0x6
    80002c2a:	9fa78793          	addi	a5,a5,-1542 # 80008620 <syscalls>
    80002c2e:	97ba                	add	a5,a5,a4
    80002c30:	639c                	ld	a5,0(a5)
    80002c32:	12078963          	beqz	a5,80002d64 <syscall+0x176>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0

    p->trapframe->a0 = syscalls[num]();
    80002c36:	9782                	jalr	a5
    80002c38:	f8a8                	sd	a0,112(s1)
    // if our system call was AUDIT, we specifically need to take what's in a0
    // out right here. this contains the whitelist array for what calls to audit
    if (num == 22) {
    80002c3a:	47d9                	li	a5,22
    80002c3c:	04fa0463          	beq	s4,a5,80002c84 <syscall+0x96>
      }
      declared_length = *(bruh->length);
      printf("process %s with id %d called audit at time %d\n", p->name, p->pid, ticks);
      printf("declared length: %d\n", declared_length);
    }
    if (!declared_length) {
    80002c40:	00006797          	auipc	a5,0x6
    80002c44:	f747a783          	lw	a5,-140(a5) # 80008bb4 <declared_length>
    80002c48:	cfdd                	beqz	a5,80002d06 <syscall+0x118>
      // nothing is whitelisted.
      printf("process %s with id %d called %s at time %d\n", p->name, p->pid, name_from_num[num], ticks);
    } else {
      // something is whitelisted.
      for (int i = 0; i < declared_length; i++) {
    80002c4a:	00014497          	auipc	s1,0x14
    80002c4e:	22e48493          	addi	s1,s1,558 # 80016e78 <whitelisted>
    80002c52:	4901                	li	s2,0
    80002c54:	12f05963          	blez	a5,80002d86 <syscall+0x198>
        // if it's whitelisted, we care. otherwise, just let it time out.
        if (num == whitelisted[i]) {
          printf("process %s with id %d called %s at time %d\n", p->name, p->pid, name_from_num[num], ticks);
    80002c58:	00006b97          	auipc	s7,0x6
    80002c5c:	f58b8b93          	addi	s7,s7,-168 # 80008bb0 <ticks>
    80002c60:	003a1b13          	slli	s6,s4,0x3
    80002c64:	00006797          	auipc	a5,0x6
    80002c68:	e2478793          	addi	a5,a5,-476 # 80008a88 <name_from_num>
    80002c6c:	9b3e                	add	s6,s6,a5
    80002c6e:	15898c93          	addi	s9,s3,344
    80002c72:	00006c17          	auipc	s8,0x6
    80002c76:	896c0c13          	addi	s8,s8,-1898 # 80008508 <states.1763+0x1a8>
      for (int i = 0; i < declared_length; i++) {
    80002c7a:	00006a97          	auipc	s5,0x6
    80002c7e:	f3aa8a93          	addi	s5,s5,-198 # 80008bb4 <declared_length>
    80002c82:	a8e9                	j	80002d5c <syscall+0x16e>
      struct aud* bruh = (struct aud*)p->trapframe->a0;
    80002c84:	0589b783          	ld	a5,88(s3)
    80002c88:	7ba4                	ld	s1,112(a5)
      printf("edit in kernel\n");
    80002c8a:	00006517          	auipc	a0,0x6
    80002c8e:	82650513          	addi	a0,a0,-2010 # 800084b0 <states.1763+0x150>
    80002c92:	ffffe097          	auipc	ra,0xffffe
    80002c96:	8fc080e7          	jalr	-1796(ra) # 8000058e <printf>
      for (int i = 0; i < *(bruh->length); i++) {
    80002c9a:	649c                	ld	a5,8(s1)
    80002c9c:	4398                	lw	a4,0(a5)
    80002c9e:	02e05563          	blez	a4,80002cc8 <syscall+0xda>
    80002ca2:	00014697          	auipc	a3,0x14
    80002ca6:	1d668693          	addi	a3,a3,470 # 80016e78 <whitelisted>
    80002caa:	4781                	li	a5,0
        whitelisted[i] = *(bruh->arr + i);
    80002cac:	6098                	ld	a4,0(s1)
    80002cae:	00279613          	slli	a2,a5,0x2
    80002cb2:	9732                	add	a4,a4,a2
    80002cb4:	4318                	lw	a4,0(a4)
    80002cb6:	c298                	sw	a4,0(a3)
      for (int i = 0; i < *(bruh->length); i++) {
    80002cb8:	6498                	ld	a4,8(s1)
    80002cba:	4318                	lw	a4,0(a4)
    80002cbc:	0785                	addi	a5,a5,1
    80002cbe:	0691                	addi	a3,a3,4
    80002cc0:	0007861b          	sext.w	a2,a5
    80002cc4:	fee644e3          	blt	a2,a4,80002cac <syscall+0xbe>
      declared_length = *(bruh->length);
    80002cc8:	00006497          	auipc	s1,0x6
    80002ccc:	eec48493          	addi	s1,s1,-276 # 80008bb4 <declared_length>
    80002cd0:	c098                	sw	a4,0(s1)
      printf("process %s with id %d called audit at time %d\n", p->name, p->pid, ticks);
    80002cd2:	00006697          	auipc	a3,0x6
    80002cd6:	ede6a683          	lw	a3,-290(a3) # 80008bb0 <ticks>
    80002cda:	0309a603          	lw	a2,48(s3)
    80002cde:	15898593          	addi	a1,s3,344
    80002ce2:	00005517          	auipc	a0,0x5
    80002ce6:	7de50513          	addi	a0,a0,2014 # 800084c0 <states.1763+0x160>
    80002cea:	ffffe097          	auipc	ra,0xffffe
    80002cee:	8a4080e7          	jalr	-1884(ra) # 8000058e <printf>
      printf("declared length: %d\n", declared_length);
    80002cf2:	408c                	lw	a1,0(s1)
    80002cf4:	00005517          	auipc	a0,0x5
    80002cf8:	7fc50513          	addi	a0,a0,2044 # 800084f0 <states.1763+0x190>
    80002cfc:	ffffe097          	auipc	ra,0xffffe
    80002d00:	892080e7          	jalr	-1902(ra) # 8000058e <printf>
    80002d04:	bf35                	j	80002c40 <syscall+0x52>
      printf("process %s with id %d called %s at time %d\n", p->name, p->pid, name_from_num[num], ticks);
    80002d06:	0a0e                	slli	s4,s4,0x3
    80002d08:	00006797          	auipc	a5,0x6
    80002d0c:	d8078793          	addi	a5,a5,-640 # 80008a88 <name_from_num>
    80002d10:	9a3e                	add	s4,s4,a5
    80002d12:	00006717          	auipc	a4,0x6
    80002d16:	e9e72703          	lw	a4,-354(a4) # 80008bb0 <ticks>
    80002d1a:	000a3683          	ld	a3,0(s4)
    80002d1e:	0309a603          	lw	a2,48(s3)
    80002d22:	15898593          	addi	a1,s3,344
    80002d26:	00005517          	auipc	a0,0x5
    80002d2a:	7e250513          	addi	a0,a0,2018 # 80008508 <states.1763+0x1a8>
    80002d2e:	ffffe097          	auipc	ra,0xffffe
    80002d32:	860080e7          	jalr	-1952(ra) # 8000058e <printf>
    80002d36:	a881                	j	80002d86 <syscall+0x198>
          printf("process %s with id %d called %s at time %d\n", p->name, p->pid, name_from_num[num], ticks);
    80002d38:	000ba703          	lw	a4,0(s7)
    80002d3c:	000b3683          	ld	a3,0(s6)
    80002d40:	0309a603          	lw	a2,48(s3)
    80002d44:	85e6                	mv	a1,s9
    80002d46:	8562                	mv	a0,s8
    80002d48:	ffffe097          	auipc	ra,0xffffe
    80002d4c:	846080e7          	jalr	-1978(ra) # 8000058e <printf>
      for (int i = 0; i < declared_length; i++) {
    80002d50:	2905                	addiw	s2,s2,1
    80002d52:	0491                	addi	s1,s1,4
    80002d54:	000aa783          	lw	a5,0(s5)
    80002d58:	02f95763          	bge	s2,a5,80002d86 <syscall+0x198>
        if (num == whitelisted[i]) {
    80002d5c:	409c                	lw	a5,0(s1)
    80002d5e:	ff4799e3          	bne	a5,s4,80002d50 <syscall+0x162>
    80002d62:	bfd9                	j	80002d38 <syscall+0x14a>
        }
      }
    }

  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d64:	86d2                	mv	a3,s4
    80002d66:	15898613          	addi	a2,s3,344
    80002d6a:	0309a583          	lw	a1,48(s3)
    80002d6e:	00005517          	auipc	a0,0x5
    80002d72:	7ca50513          	addi	a0,a0,1994 # 80008538 <states.1763+0x1d8>
    80002d76:	ffffe097          	auipc	ra,0xffffe
    80002d7a:	818080e7          	jalr	-2024(ra) # 8000058e <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d7e:	0589b783          	ld	a5,88(s3)
    80002d82:	577d                	li	a4,-1
    80002d84:	fbb8                	sd	a4,112(a5)
  }
}
    80002d86:	60e6                	ld	ra,88(sp)
    80002d88:	6446                	ld	s0,80(sp)
    80002d8a:	64a6                	ld	s1,72(sp)
    80002d8c:	6906                	ld	s2,64(sp)
    80002d8e:	79e2                	ld	s3,56(sp)
    80002d90:	7a42                	ld	s4,48(sp)
    80002d92:	7aa2                	ld	s5,40(sp)
    80002d94:	7b02                	ld	s6,32(sp)
    80002d96:	6be2                	ld	s7,24(sp)
    80002d98:	6c42                	ld	s8,16(sp)
    80002d9a:	6ca2                	ld	s9,8(sp)
    80002d9c:	6125                	addi	sp,sp,96
    80002d9e:	8082                	ret

0000000080002da0 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002da0:	1101                	addi	sp,sp,-32
    80002da2:	ec06                	sd	ra,24(sp)
    80002da4:	e822                	sd	s0,16(sp)
    80002da6:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002da8:	fec40593          	addi	a1,s0,-20
    80002dac:	4501                	li	a0,0
    80002dae:	00000097          	auipc	ra,0x0
    80002db2:	dc8080e7          	jalr	-568(ra) # 80002b76 <argint>
  exit(n);
    80002db6:	fec42503          	lw	a0,-20(s0)
    80002dba:	fffff097          	auipc	ra,0xfffff
    80002dbe:	484080e7          	jalr	1156(ra) # 8000223e <exit>
  return 0;  // not reached
}
    80002dc2:	4501                	li	a0,0
    80002dc4:	60e2                	ld	ra,24(sp)
    80002dc6:	6442                	ld	s0,16(sp)
    80002dc8:	6105                	addi	sp,sp,32
    80002dca:	8082                	ret

0000000080002dcc <sys_getpid>:

uint64
sys_getpid(void)
{
    80002dcc:	1141                	addi	sp,sp,-16
    80002dce:	e406                	sd	ra,8(sp)
    80002dd0:	e022                	sd	s0,0(sp)
    80002dd2:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002dd4:	fffff097          	auipc	ra,0xfffff
    80002dd8:	bf2080e7          	jalr	-1038(ra) # 800019c6 <myproc>
}
    80002ddc:	5908                	lw	a0,48(a0)
    80002dde:	60a2                	ld	ra,8(sp)
    80002de0:	6402                	ld	s0,0(sp)
    80002de2:	0141                	addi	sp,sp,16
    80002de4:	8082                	ret

0000000080002de6 <sys_fork>:

uint64
sys_fork(void)
{
    80002de6:	1141                	addi	sp,sp,-16
    80002de8:	e406                	sd	ra,8(sp)
    80002dea:	e022                	sd	s0,0(sp)
    80002dec:	0800                	addi	s0,sp,16
  return fork();
    80002dee:	fffff097          	auipc	ra,0xfffff
    80002df2:	f8e080e7          	jalr	-114(ra) # 80001d7c <fork>
}
    80002df6:	60a2                	ld	ra,8(sp)
    80002df8:	6402                	ld	s0,0(sp)
    80002dfa:	0141                	addi	sp,sp,16
    80002dfc:	8082                	ret

0000000080002dfe <sys_wait>:

uint64
sys_wait(void)
{
    80002dfe:	1101                	addi	sp,sp,-32
    80002e00:	ec06                	sd	ra,24(sp)
    80002e02:	e822                	sd	s0,16(sp)
    80002e04:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002e06:	fe840593          	addi	a1,s0,-24
    80002e0a:	4501                	li	a0,0
    80002e0c:	00000097          	auipc	ra,0x0
    80002e10:	d8a080e7          	jalr	-630(ra) # 80002b96 <argaddr>
  return wait(p);
    80002e14:	fe843503          	ld	a0,-24(s0)
    80002e18:	fffff097          	auipc	ra,0xfffff
    80002e1c:	5cc080e7          	jalr	1484(ra) # 800023e4 <wait>
}
    80002e20:	60e2                	ld	ra,24(sp)
    80002e22:	6442                	ld	s0,16(sp)
    80002e24:	6105                	addi	sp,sp,32
    80002e26:	8082                	ret

0000000080002e28 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e28:	7179                	addi	sp,sp,-48
    80002e2a:	f406                	sd	ra,40(sp)
    80002e2c:	f022                	sd	s0,32(sp)
    80002e2e:	ec26                	sd	s1,24(sp)
    80002e30:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002e32:	fdc40593          	addi	a1,s0,-36
    80002e36:	4501                	li	a0,0
    80002e38:	00000097          	auipc	ra,0x0
    80002e3c:	d3e080e7          	jalr	-706(ra) # 80002b76 <argint>
  addr = myproc()->sz;
    80002e40:	fffff097          	auipc	ra,0xfffff
    80002e44:	b86080e7          	jalr	-1146(ra) # 800019c6 <myproc>
    80002e48:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002e4a:	fdc42503          	lw	a0,-36(s0)
    80002e4e:	fffff097          	auipc	ra,0xfffff
    80002e52:	ed2080e7          	jalr	-302(ra) # 80001d20 <growproc>
    80002e56:	00054863          	bltz	a0,80002e66 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002e5a:	8526                	mv	a0,s1
    80002e5c:	70a2                	ld	ra,40(sp)
    80002e5e:	7402                	ld	s0,32(sp)
    80002e60:	64e2                	ld	s1,24(sp)
    80002e62:	6145                	addi	sp,sp,48
    80002e64:	8082                	ret
    return -1;
    80002e66:	54fd                	li	s1,-1
    80002e68:	bfcd                	j	80002e5a <sys_sbrk+0x32>

0000000080002e6a <sys_sleep>:

uint64
sys_sleep(void)
{
    80002e6a:	7139                	addi	sp,sp,-64
    80002e6c:	fc06                	sd	ra,56(sp)
    80002e6e:	f822                	sd	s0,48(sp)
    80002e70:	f426                	sd	s1,40(sp)
    80002e72:	f04a                	sd	s2,32(sp)
    80002e74:	ec4e                	sd	s3,24(sp)
    80002e76:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002e78:	fcc40593          	addi	a1,s0,-52
    80002e7c:	4501                	li	a0,0
    80002e7e:	00000097          	auipc	ra,0x0
    80002e82:	cf8080e7          	jalr	-776(ra) # 80002b76 <argint>
  acquire(&tickslock);
    80002e86:	00014517          	auipc	a0,0x14
    80002e8a:	fda50513          	addi	a0,a0,-38 # 80016e60 <tickslock>
    80002e8e:	ffffe097          	auipc	ra,0xffffe
    80002e92:	d5c080e7          	jalr	-676(ra) # 80000bea <acquire>
  ticks0 = ticks;
    80002e96:	00006917          	auipc	s2,0x6
    80002e9a:	d1a92903          	lw	s2,-742(s2) # 80008bb0 <ticks>
  while(ticks - ticks0 < n){
    80002e9e:	fcc42783          	lw	a5,-52(s0)
    80002ea2:	cf9d                	beqz	a5,80002ee0 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002ea4:	00014997          	auipc	s3,0x14
    80002ea8:	fbc98993          	addi	s3,s3,-68 # 80016e60 <tickslock>
    80002eac:	00006497          	auipc	s1,0x6
    80002eb0:	d0448493          	addi	s1,s1,-764 # 80008bb0 <ticks>
    if(killed(myproc())){
    80002eb4:	fffff097          	auipc	ra,0xfffff
    80002eb8:	b12080e7          	jalr	-1262(ra) # 800019c6 <myproc>
    80002ebc:	fffff097          	auipc	ra,0xfffff
    80002ec0:	4f6080e7          	jalr	1270(ra) # 800023b2 <killed>
    80002ec4:	ed15                	bnez	a0,80002f00 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002ec6:	85ce                	mv	a1,s3
    80002ec8:	8526                	mv	a0,s1
    80002eca:	fffff097          	auipc	ra,0xfffff
    80002ece:	240080e7          	jalr	576(ra) # 8000210a <sleep>
  while(ticks - ticks0 < n){
    80002ed2:	409c                	lw	a5,0(s1)
    80002ed4:	412787bb          	subw	a5,a5,s2
    80002ed8:	fcc42703          	lw	a4,-52(s0)
    80002edc:	fce7ece3          	bltu	a5,a4,80002eb4 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002ee0:	00014517          	auipc	a0,0x14
    80002ee4:	f8050513          	addi	a0,a0,-128 # 80016e60 <tickslock>
    80002ee8:	ffffe097          	auipc	ra,0xffffe
    80002eec:	db6080e7          	jalr	-586(ra) # 80000c9e <release>
  return 0;
    80002ef0:	4501                	li	a0,0
}
    80002ef2:	70e2                	ld	ra,56(sp)
    80002ef4:	7442                	ld	s0,48(sp)
    80002ef6:	74a2                	ld	s1,40(sp)
    80002ef8:	7902                	ld	s2,32(sp)
    80002efa:	69e2                	ld	s3,24(sp)
    80002efc:	6121                	addi	sp,sp,64
    80002efe:	8082                	ret
      release(&tickslock);
    80002f00:	00014517          	auipc	a0,0x14
    80002f04:	f6050513          	addi	a0,a0,-160 # 80016e60 <tickslock>
    80002f08:	ffffe097          	auipc	ra,0xffffe
    80002f0c:	d96080e7          	jalr	-618(ra) # 80000c9e <release>
      return -1;
    80002f10:	557d                	li	a0,-1
    80002f12:	b7c5                	j	80002ef2 <sys_sleep+0x88>

0000000080002f14 <sys_kill>:

uint64
sys_kill(void)
{
    80002f14:	1101                	addi	sp,sp,-32
    80002f16:	ec06                	sd	ra,24(sp)
    80002f18:	e822                	sd	s0,16(sp)
    80002f1a:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002f1c:	fec40593          	addi	a1,s0,-20
    80002f20:	4501                	li	a0,0
    80002f22:	00000097          	auipc	ra,0x0
    80002f26:	c54080e7          	jalr	-940(ra) # 80002b76 <argint>
  return kill(pid);
    80002f2a:	fec42503          	lw	a0,-20(s0)
    80002f2e:	fffff097          	auipc	ra,0xfffff
    80002f32:	3e6080e7          	jalr	998(ra) # 80002314 <kill>
}
    80002f36:	60e2                	ld	ra,24(sp)
    80002f38:	6442                	ld	s0,16(sp)
    80002f3a:	6105                	addi	sp,sp,32
    80002f3c:	8082                	ret

0000000080002f3e <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002f3e:	1101                	addi	sp,sp,-32
    80002f40:	ec06                	sd	ra,24(sp)
    80002f42:	e822                	sd	s0,16(sp)
    80002f44:	e426                	sd	s1,8(sp)
    80002f46:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002f48:	00014517          	auipc	a0,0x14
    80002f4c:	f1850513          	addi	a0,a0,-232 # 80016e60 <tickslock>
    80002f50:	ffffe097          	auipc	ra,0xffffe
    80002f54:	c9a080e7          	jalr	-870(ra) # 80000bea <acquire>
  xticks = ticks;
    80002f58:	00006497          	auipc	s1,0x6
    80002f5c:	c584a483          	lw	s1,-936(s1) # 80008bb0 <ticks>
  release(&tickslock);
    80002f60:	00014517          	auipc	a0,0x14
    80002f64:	f0050513          	addi	a0,a0,-256 # 80016e60 <tickslock>
    80002f68:	ffffe097          	auipc	ra,0xffffe
    80002f6c:	d36080e7          	jalr	-714(ra) # 80000c9e <release>
  return xticks;
}
    80002f70:	02049513          	slli	a0,s1,0x20
    80002f74:	9101                	srli	a0,a0,0x20
    80002f76:	60e2                	ld	ra,24(sp)
    80002f78:	6442                	ld	s0,16(sp)
    80002f7a:	64a2                	ld	s1,8(sp)
    80002f7c:	6105                	addi	sp,sp,32
    80002f7e:	8082                	ret

0000000080002f80 <sys_audit>:

uint64
sys_audit(void)
{
    80002f80:	1101                	addi	sp,sp,-32
    80002f82:	ec06                	sd	ra,24(sp)
    80002f84:	e822                	sd	s0,16(sp)
    80002f86:	1000                	addi	s0,sp,32
  printf("in sys audit\n");
    80002f88:	00005517          	auipc	a0,0x5
    80002f8c:	75050513          	addi	a0,a0,1872 # 800086d8 <syscalls+0xb8>
    80002f90:	ffffd097          	auipc	ra,0xffffd
    80002f94:	5fe080e7          	jalr	1534(ra) # 8000058e <printf>
  uint64 arr_addr;
  uint64 length;
  argaddr(0, &arr_addr);
    80002f98:	fe840593          	addi	a1,s0,-24
    80002f9c:	4501                	li	a0,0
    80002f9e:	00000097          	auipc	ra,0x0
    80002fa2:	bf8080e7          	jalr	-1032(ra) # 80002b96 <argaddr>
  argaddr(1, &length);
    80002fa6:	fe040593          	addi	a1,s0,-32
    80002faa:	4505                	li	a0,1
    80002fac:	00000097          	auipc	ra,0x0
    80002fb0:	bea080e7          	jalr	-1046(ra) # 80002b96 <argaddr>
  printf("address of length: %p\n", (int*) length);
    80002fb4:	fe043583          	ld	a1,-32(s0)
    80002fb8:	00005517          	auipc	a0,0x5
    80002fbc:	73050513          	addi	a0,a0,1840 # 800086e8 <syscalls+0xc8>
    80002fc0:	ffffd097          	auipc	ra,0xffffd
    80002fc4:	5ce080e7          	jalr	1486(ra) # 8000058e <printf>
  return audit((int*) arr_addr, (int*) length);
    80002fc8:	fe043583          	ld	a1,-32(s0)
    80002fcc:	fe843503          	ld	a0,-24(s0)
    80002fd0:	fffff097          	auipc	ra,0xfffff
    80002fd4:	ee8080e7          	jalr	-280(ra) # 80001eb8 <audit>
}
    80002fd8:	60e2                	ld	ra,24(sp)
    80002fda:	6442                	ld	s0,16(sp)
    80002fdc:	6105                	addi	sp,sp,32
    80002fde:	8082                	ret

0000000080002fe0 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002fe0:	7179                	addi	sp,sp,-48
    80002fe2:	f406                	sd	ra,40(sp)
    80002fe4:	f022                	sd	s0,32(sp)
    80002fe6:	ec26                	sd	s1,24(sp)
    80002fe8:	e84a                	sd	s2,16(sp)
    80002fea:	e44e                	sd	s3,8(sp)
    80002fec:	e052                	sd	s4,0(sp)
    80002fee:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002ff0:	00005597          	auipc	a1,0x5
    80002ff4:	71058593          	addi	a1,a1,1808 # 80008700 <syscalls+0xe0>
    80002ff8:	0001c517          	auipc	a0,0x1c
    80002ffc:	ed850513          	addi	a0,a0,-296 # 8001eed0 <bcache>
    80003000:	ffffe097          	auipc	ra,0xffffe
    80003004:	b5a080e7          	jalr	-1190(ra) # 80000b5a <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003008:	00024797          	auipc	a5,0x24
    8000300c:	ec878793          	addi	a5,a5,-312 # 80026ed0 <bcache+0x8000>
    80003010:	00024717          	auipc	a4,0x24
    80003014:	12870713          	addi	a4,a4,296 # 80027138 <bcache+0x8268>
    80003018:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000301c:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003020:	0001c497          	auipc	s1,0x1c
    80003024:	ec848493          	addi	s1,s1,-312 # 8001eee8 <bcache+0x18>
    b->next = bcache.head.next;
    80003028:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000302a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000302c:	00005a17          	auipc	s4,0x5
    80003030:	6dca0a13          	addi	s4,s4,1756 # 80008708 <syscalls+0xe8>
    b->next = bcache.head.next;
    80003034:	2b893783          	ld	a5,696(s2)
    80003038:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000303a:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000303e:	85d2                	mv	a1,s4
    80003040:	01048513          	addi	a0,s1,16
    80003044:	00001097          	auipc	ra,0x1
    80003048:	4c4080e7          	jalr	1220(ra) # 80004508 <initsleeplock>
    bcache.head.next->prev = b;
    8000304c:	2b893783          	ld	a5,696(s2)
    80003050:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003052:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003056:	45848493          	addi	s1,s1,1112
    8000305a:	fd349de3          	bne	s1,s3,80003034 <binit+0x54>
  }
}
    8000305e:	70a2                	ld	ra,40(sp)
    80003060:	7402                	ld	s0,32(sp)
    80003062:	64e2                	ld	s1,24(sp)
    80003064:	6942                	ld	s2,16(sp)
    80003066:	69a2                	ld	s3,8(sp)
    80003068:	6a02                	ld	s4,0(sp)
    8000306a:	6145                	addi	sp,sp,48
    8000306c:	8082                	ret

000000008000306e <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000306e:	7179                	addi	sp,sp,-48
    80003070:	f406                	sd	ra,40(sp)
    80003072:	f022                	sd	s0,32(sp)
    80003074:	ec26                	sd	s1,24(sp)
    80003076:	e84a                	sd	s2,16(sp)
    80003078:	e44e                	sd	s3,8(sp)
    8000307a:	1800                	addi	s0,sp,48
    8000307c:	89aa                	mv	s3,a0
    8000307e:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003080:	0001c517          	auipc	a0,0x1c
    80003084:	e5050513          	addi	a0,a0,-432 # 8001eed0 <bcache>
    80003088:	ffffe097          	auipc	ra,0xffffe
    8000308c:	b62080e7          	jalr	-1182(ra) # 80000bea <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003090:	00024497          	auipc	s1,0x24
    80003094:	0f84b483          	ld	s1,248(s1) # 80027188 <bcache+0x82b8>
    80003098:	00024797          	auipc	a5,0x24
    8000309c:	0a078793          	addi	a5,a5,160 # 80027138 <bcache+0x8268>
    800030a0:	02f48f63          	beq	s1,a5,800030de <bread+0x70>
    800030a4:	873e                	mv	a4,a5
    800030a6:	a021                	j	800030ae <bread+0x40>
    800030a8:	68a4                	ld	s1,80(s1)
    800030aa:	02e48a63          	beq	s1,a4,800030de <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800030ae:	449c                	lw	a5,8(s1)
    800030b0:	ff379ce3          	bne	a5,s3,800030a8 <bread+0x3a>
    800030b4:	44dc                	lw	a5,12(s1)
    800030b6:	ff2799e3          	bne	a5,s2,800030a8 <bread+0x3a>
      b->refcnt++;
    800030ba:	40bc                	lw	a5,64(s1)
    800030bc:	2785                	addiw	a5,a5,1
    800030be:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800030c0:	0001c517          	auipc	a0,0x1c
    800030c4:	e1050513          	addi	a0,a0,-496 # 8001eed0 <bcache>
    800030c8:	ffffe097          	auipc	ra,0xffffe
    800030cc:	bd6080e7          	jalr	-1066(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    800030d0:	01048513          	addi	a0,s1,16
    800030d4:	00001097          	auipc	ra,0x1
    800030d8:	46e080e7          	jalr	1134(ra) # 80004542 <acquiresleep>
      return b;
    800030dc:	a8b9                	j	8000313a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030de:	00024497          	auipc	s1,0x24
    800030e2:	0a24b483          	ld	s1,162(s1) # 80027180 <bcache+0x82b0>
    800030e6:	00024797          	auipc	a5,0x24
    800030ea:	05278793          	addi	a5,a5,82 # 80027138 <bcache+0x8268>
    800030ee:	00f48863          	beq	s1,a5,800030fe <bread+0x90>
    800030f2:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800030f4:	40bc                	lw	a5,64(s1)
    800030f6:	cf81                	beqz	a5,8000310e <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030f8:	64a4                	ld	s1,72(s1)
    800030fa:	fee49de3          	bne	s1,a4,800030f4 <bread+0x86>
  panic("bget: no buffers");
    800030fe:	00005517          	auipc	a0,0x5
    80003102:	61250513          	addi	a0,a0,1554 # 80008710 <syscalls+0xf0>
    80003106:	ffffd097          	auipc	ra,0xffffd
    8000310a:	43e080e7          	jalr	1086(ra) # 80000544 <panic>
      b->dev = dev;
    8000310e:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003112:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003116:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000311a:	4785                	li	a5,1
    8000311c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000311e:	0001c517          	auipc	a0,0x1c
    80003122:	db250513          	addi	a0,a0,-590 # 8001eed0 <bcache>
    80003126:	ffffe097          	auipc	ra,0xffffe
    8000312a:	b78080e7          	jalr	-1160(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    8000312e:	01048513          	addi	a0,s1,16
    80003132:	00001097          	auipc	ra,0x1
    80003136:	410080e7          	jalr	1040(ra) # 80004542 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000313a:	409c                	lw	a5,0(s1)
    8000313c:	cb89                	beqz	a5,8000314e <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000313e:	8526                	mv	a0,s1
    80003140:	70a2                	ld	ra,40(sp)
    80003142:	7402                	ld	s0,32(sp)
    80003144:	64e2                	ld	s1,24(sp)
    80003146:	6942                	ld	s2,16(sp)
    80003148:	69a2                	ld	s3,8(sp)
    8000314a:	6145                	addi	sp,sp,48
    8000314c:	8082                	ret
    virtio_disk_rw(b, 0);
    8000314e:	4581                	li	a1,0
    80003150:	8526                	mv	a0,s1
    80003152:	00003097          	auipc	ra,0x3
    80003156:	fc6080e7          	jalr	-58(ra) # 80006118 <virtio_disk_rw>
    b->valid = 1;
    8000315a:	4785                	li	a5,1
    8000315c:	c09c                	sw	a5,0(s1)
  return b;
    8000315e:	b7c5                	j	8000313e <bread+0xd0>

0000000080003160 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003160:	1101                	addi	sp,sp,-32
    80003162:	ec06                	sd	ra,24(sp)
    80003164:	e822                	sd	s0,16(sp)
    80003166:	e426                	sd	s1,8(sp)
    80003168:	1000                	addi	s0,sp,32
    8000316a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000316c:	0541                	addi	a0,a0,16
    8000316e:	00001097          	auipc	ra,0x1
    80003172:	46e080e7          	jalr	1134(ra) # 800045dc <holdingsleep>
    80003176:	cd01                	beqz	a0,8000318e <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003178:	4585                	li	a1,1
    8000317a:	8526                	mv	a0,s1
    8000317c:	00003097          	auipc	ra,0x3
    80003180:	f9c080e7          	jalr	-100(ra) # 80006118 <virtio_disk_rw>
}
    80003184:	60e2                	ld	ra,24(sp)
    80003186:	6442                	ld	s0,16(sp)
    80003188:	64a2                	ld	s1,8(sp)
    8000318a:	6105                	addi	sp,sp,32
    8000318c:	8082                	ret
    panic("bwrite");
    8000318e:	00005517          	auipc	a0,0x5
    80003192:	59a50513          	addi	a0,a0,1434 # 80008728 <syscalls+0x108>
    80003196:	ffffd097          	auipc	ra,0xffffd
    8000319a:	3ae080e7          	jalr	942(ra) # 80000544 <panic>

000000008000319e <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000319e:	1101                	addi	sp,sp,-32
    800031a0:	ec06                	sd	ra,24(sp)
    800031a2:	e822                	sd	s0,16(sp)
    800031a4:	e426                	sd	s1,8(sp)
    800031a6:	e04a                	sd	s2,0(sp)
    800031a8:	1000                	addi	s0,sp,32
    800031aa:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031ac:	01050913          	addi	s2,a0,16
    800031b0:	854a                	mv	a0,s2
    800031b2:	00001097          	auipc	ra,0x1
    800031b6:	42a080e7          	jalr	1066(ra) # 800045dc <holdingsleep>
    800031ba:	c92d                	beqz	a0,8000322c <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800031bc:	854a                	mv	a0,s2
    800031be:	00001097          	auipc	ra,0x1
    800031c2:	3da080e7          	jalr	986(ra) # 80004598 <releasesleep>

  acquire(&bcache.lock);
    800031c6:	0001c517          	auipc	a0,0x1c
    800031ca:	d0a50513          	addi	a0,a0,-758 # 8001eed0 <bcache>
    800031ce:	ffffe097          	auipc	ra,0xffffe
    800031d2:	a1c080e7          	jalr	-1508(ra) # 80000bea <acquire>
  b->refcnt--;
    800031d6:	40bc                	lw	a5,64(s1)
    800031d8:	37fd                	addiw	a5,a5,-1
    800031da:	0007871b          	sext.w	a4,a5
    800031de:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800031e0:	eb05                	bnez	a4,80003210 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800031e2:	68bc                	ld	a5,80(s1)
    800031e4:	64b8                	ld	a4,72(s1)
    800031e6:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800031e8:	64bc                	ld	a5,72(s1)
    800031ea:	68b8                	ld	a4,80(s1)
    800031ec:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800031ee:	00024797          	auipc	a5,0x24
    800031f2:	ce278793          	addi	a5,a5,-798 # 80026ed0 <bcache+0x8000>
    800031f6:	2b87b703          	ld	a4,696(a5)
    800031fa:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800031fc:	00024717          	auipc	a4,0x24
    80003200:	f3c70713          	addi	a4,a4,-196 # 80027138 <bcache+0x8268>
    80003204:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003206:	2b87b703          	ld	a4,696(a5)
    8000320a:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000320c:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003210:	0001c517          	auipc	a0,0x1c
    80003214:	cc050513          	addi	a0,a0,-832 # 8001eed0 <bcache>
    80003218:	ffffe097          	auipc	ra,0xffffe
    8000321c:	a86080e7          	jalr	-1402(ra) # 80000c9e <release>
}
    80003220:	60e2                	ld	ra,24(sp)
    80003222:	6442                	ld	s0,16(sp)
    80003224:	64a2                	ld	s1,8(sp)
    80003226:	6902                	ld	s2,0(sp)
    80003228:	6105                	addi	sp,sp,32
    8000322a:	8082                	ret
    panic("brelse");
    8000322c:	00005517          	auipc	a0,0x5
    80003230:	50450513          	addi	a0,a0,1284 # 80008730 <syscalls+0x110>
    80003234:	ffffd097          	auipc	ra,0xffffd
    80003238:	310080e7          	jalr	784(ra) # 80000544 <panic>

000000008000323c <bpin>:

void
bpin(struct buf *b) {
    8000323c:	1101                	addi	sp,sp,-32
    8000323e:	ec06                	sd	ra,24(sp)
    80003240:	e822                	sd	s0,16(sp)
    80003242:	e426                	sd	s1,8(sp)
    80003244:	1000                	addi	s0,sp,32
    80003246:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003248:	0001c517          	auipc	a0,0x1c
    8000324c:	c8850513          	addi	a0,a0,-888 # 8001eed0 <bcache>
    80003250:	ffffe097          	auipc	ra,0xffffe
    80003254:	99a080e7          	jalr	-1638(ra) # 80000bea <acquire>
  b->refcnt++;
    80003258:	40bc                	lw	a5,64(s1)
    8000325a:	2785                	addiw	a5,a5,1
    8000325c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000325e:	0001c517          	auipc	a0,0x1c
    80003262:	c7250513          	addi	a0,a0,-910 # 8001eed0 <bcache>
    80003266:	ffffe097          	auipc	ra,0xffffe
    8000326a:	a38080e7          	jalr	-1480(ra) # 80000c9e <release>
}
    8000326e:	60e2                	ld	ra,24(sp)
    80003270:	6442                	ld	s0,16(sp)
    80003272:	64a2                	ld	s1,8(sp)
    80003274:	6105                	addi	sp,sp,32
    80003276:	8082                	ret

0000000080003278 <bunpin>:

void
bunpin(struct buf *b) {
    80003278:	1101                	addi	sp,sp,-32
    8000327a:	ec06                	sd	ra,24(sp)
    8000327c:	e822                	sd	s0,16(sp)
    8000327e:	e426                	sd	s1,8(sp)
    80003280:	1000                	addi	s0,sp,32
    80003282:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003284:	0001c517          	auipc	a0,0x1c
    80003288:	c4c50513          	addi	a0,a0,-948 # 8001eed0 <bcache>
    8000328c:	ffffe097          	auipc	ra,0xffffe
    80003290:	95e080e7          	jalr	-1698(ra) # 80000bea <acquire>
  b->refcnt--;
    80003294:	40bc                	lw	a5,64(s1)
    80003296:	37fd                	addiw	a5,a5,-1
    80003298:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000329a:	0001c517          	auipc	a0,0x1c
    8000329e:	c3650513          	addi	a0,a0,-970 # 8001eed0 <bcache>
    800032a2:	ffffe097          	auipc	ra,0xffffe
    800032a6:	9fc080e7          	jalr	-1540(ra) # 80000c9e <release>
}
    800032aa:	60e2                	ld	ra,24(sp)
    800032ac:	6442                	ld	s0,16(sp)
    800032ae:	64a2                	ld	s1,8(sp)
    800032b0:	6105                	addi	sp,sp,32
    800032b2:	8082                	ret

00000000800032b4 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800032b4:	1101                	addi	sp,sp,-32
    800032b6:	ec06                	sd	ra,24(sp)
    800032b8:	e822                	sd	s0,16(sp)
    800032ba:	e426                	sd	s1,8(sp)
    800032bc:	e04a                	sd	s2,0(sp)
    800032be:	1000                	addi	s0,sp,32
    800032c0:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800032c2:	00d5d59b          	srliw	a1,a1,0xd
    800032c6:	00024797          	auipc	a5,0x24
    800032ca:	2e67a783          	lw	a5,742(a5) # 800275ac <sb+0x1c>
    800032ce:	9dbd                	addw	a1,a1,a5
    800032d0:	00000097          	auipc	ra,0x0
    800032d4:	d9e080e7          	jalr	-610(ra) # 8000306e <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800032d8:	0074f713          	andi	a4,s1,7
    800032dc:	4785                	li	a5,1
    800032de:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800032e2:	14ce                	slli	s1,s1,0x33
    800032e4:	90d9                	srli	s1,s1,0x36
    800032e6:	00950733          	add	a4,a0,s1
    800032ea:	05874703          	lbu	a4,88(a4)
    800032ee:	00e7f6b3          	and	a3,a5,a4
    800032f2:	c69d                	beqz	a3,80003320 <bfree+0x6c>
    800032f4:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800032f6:	94aa                	add	s1,s1,a0
    800032f8:	fff7c793          	not	a5,a5
    800032fc:	8ff9                	and	a5,a5,a4
    800032fe:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003302:	00001097          	auipc	ra,0x1
    80003306:	120080e7          	jalr	288(ra) # 80004422 <log_write>
  brelse(bp);
    8000330a:	854a                	mv	a0,s2
    8000330c:	00000097          	auipc	ra,0x0
    80003310:	e92080e7          	jalr	-366(ra) # 8000319e <brelse>
}
    80003314:	60e2                	ld	ra,24(sp)
    80003316:	6442                	ld	s0,16(sp)
    80003318:	64a2                	ld	s1,8(sp)
    8000331a:	6902                	ld	s2,0(sp)
    8000331c:	6105                	addi	sp,sp,32
    8000331e:	8082                	ret
    panic("freeing free block");
    80003320:	00005517          	auipc	a0,0x5
    80003324:	41850513          	addi	a0,a0,1048 # 80008738 <syscalls+0x118>
    80003328:	ffffd097          	auipc	ra,0xffffd
    8000332c:	21c080e7          	jalr	540(ra) # 80000544 <panic>

0000000080003330 <balloc>:
{
    80003330:	711d                	addi	sp,sp,-96
    80003332:	ec86                	sd	ra,88(sp)
    80003334:	e8a2                	sd	s0,80(sp)
    80003336:	e4a6                	sd	s1,72(sp)
    80003338:	e0ca                	sd	s2,64(sp)
    8000333a:	fc4e                	sd	s3,56(sp)
    8000333c:	f852                	sd	s4,48(sp)
    8000333e:	f456                	sd	s5,40(sp)
    80003340:	f05a                	sd	s6,32(sp)
    80003342:	ec5e                	sd	s7,24(sp)
    80003344:	e862                	sd	s8,16(sp)
    80003346:	e466                	sd	s9,8(sp)
    80003348:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000334a:	00024797          	auipc	a5,0x24
    8000334e:	24a7a783          	lw	a5,586(a5) # 80027594 <sb+0x4>
    80003352:	10078163          	beqz	a5,80003454 <balloc+0x124>
    80003356:	8baa                	mv	s7,a0
    80003358:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000335a:	00024b17          	auipc	s6,0x24
    8000335e:	236b0b13          	addi	s6,s6,566 # 80027590 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003362:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003364:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003366:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003368:	6c89                	lui	s9,0x2
    8000336a:	a061                	j	800033f2 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000336c:	974a                	add	a4,a4,s2
    8000336e:	8fd5                	or	a5,a5,a3
    80003370:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003374:	854a                	mv	a0,s2
    80003376:	00001097          	auipc	ra,0x1
    8000337a:	0ac080e7          	jalr	172(ra) # 80004422 <log_write>
        brelse(bp);
    8000337e:	854a                	mv	a0,s2
    80003380:	00000097          	auipc	ra,0x0
    80003384:	e1e080e7          	jalr	-482(ra) # 8000319e <brelse>
  bp = bread(dev, bno);
    80003388:	85a6                	mv	a1,s1
    8000338a:	855e                	mv	a0,s7
    8000338c:	00000097          	auipc	ra,0x0
    80003390:	ce2080e7          	jalr	-798(ra) # 8000306e <bread>
    80003394:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003396:	40000613          	li	a2,1024
    8000339a:	4581                	li	a1,0
    8000339c:	05850513          	addi	a0,a0,88
    800033a0:	ffffe097          	auipc	ra,0xffffe
    800033a4:	946080e7          	jalr	-1722(ra) # 80000ce6 <memset>
  log_write(bp);
    800033a8:	854a                	mv	a0,s2
    800033aa:	00001097          	auipc	ra,0x1
    800033ae:	078080e7          	jalr	120(ra) # 80004422 <log_write>
  brelse(bp);
    800033b2:	854a                	mv	a0,s2
    800033b4:	00000097          	auipc	ra,0x0
    800033b8:	dea080e7          	jalr	-534(ra) # 8000319e <brelse>
}
    800033bc:	8526                	mv	a0,s1
    800033be:	60e6                	ld	ra,88(sp)
    800033c0:	6446                	ld	s0,80(sp)
    800033c2:	64a6                	ld	s1,72(sp)
    800033c4:	6906                	ld	s2,64(sp)
    800033c6:	79e2                	ld	s3,56(sp)
    800033c8:	7a42                	ld	s4,48(sp)
    800033ca:	7aa2                	ld	s5,40(sp)
    800033cc:	7b02                	ld	s6,32(sp)
    800033ce:	6be2                	ld	s7,24(sp)
    800033d0:	6c42                	ld	s8,16(sp)
    800033d2:	6ca2                	ld	s9,8(sp)
    800033d4:	6125                	addi	sp,sp,96
    800033d6:	8082                	ret
    brelse(bp);
    800033d8:	854a                	mv	a0,s2
    800033da:	00000097          	auipc	ra,0x0
    800033de:	dc4080e7          	jalr	-572(ra) # 8000319e <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800033e2:	015c87bb          	addw	a5,s9,s5
    800033e6:	00078a9b          	sext.w	s5,a5
    800033ea:	004b2703          	lw	a4,4(s6)
    800033ee:	06eaf363          	bgeu	s5,a4,80003454 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    800033f2:	41fad79b          	sraiw	a5,s5,0x1f
    800033f6:	0137d79b          	srliw	a5,a5,0x13
    800033fa:	015787bb          	addw	a5,a5,s5
    800033fe:	40d7d79b          	sraiw	a5,a5,0xd
    80003402:	01cb2583          	lw	a1,28(s6)
    80003406:	9dbd                	addw	a1,a1,a5
    80003408:	855e                	mv	a0,s7
    8000340a:	00000097          	auipc	ra,0x0
    8000340e:	c64080e7          	jalr	-924(ra) # 8000306e <bread>
    80003412:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003414:	004b2503          	lw	a0,4(s6)
    80003418:	000a849b          	sext.w	s1,s5
    8000341c:	8662                	mv	a2,s8
    8000341e:	faa4fde3          	bgeu	s1,a0,800033d8 <balloc+0xa8>
      m = 1 << (bi % 8);
    80003422:	41f6579b          	sraiw	a5,a2,0x1f
    80003426:	01d7d69b          	srliw	a3,a5,0x1d
    8000342a:	00c6873b          	addw	a4,a3,a2
    8000342e:	00777793          	andi	a5,a4,7
    80003432:	9f95                	subw	a5,a5,a3
    80003434:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003438:	4037571b          	sraiw	a4,a4,0x3
    8000343c:	00e906b3          	add	a3,s2,a4
    80003440:	0586c683          	lbu	a3,88(a3)
    80003444:	00d7f5b3          	and	a1,a5,a3
    80003448:	d195                	beqz	a1,8000336c <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000344a:	2605                	addiw	a2,a2,1
    8000344c:	2485                	addiw	s1,s1,1
    8000344e:	fd4618e3          	bne	a2,s4,8000341e <balloc+0xee>
    80003452:	b759                	j	800033d8 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    80003454:	00005517          	auipc	a0,0x5
    80003458:	2fc50513          	addi	a0,a0,764 # 80008750 <syscalls+0x130>
    8000345c:	ffffd097          	auipc	ra,0xffffd
    80003460:	132080e7          	jalr	306(ra) # 8000058e <printf>
  return 0;
    80003464:	4481                	li	s1,0
    80003466:	bf99                	j	800033bc <balloc+0x8c>

0000000080003468 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003468:	7179                	addi	sp,sp,-48
    8000346a:	f406                	sd	ra,40(sp)
    8000346c:	f022                	sd	s0,32(sp)
    8000346e:	ec26                	sd	s1,24(sp)
    80003470:	e84a                	sd	s2,16(sp)
    80003472:	e44e                	sd	s3,8(sp)
    80003474:	e052                	sd	s4,0(sp)
    80003476:	1800                	addi	s0,sp,48
    80003478:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000347a:	47ad                	li	a5,11
    8000347c:	02b7e763          	bltu	a5,a1,800034aa <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    80003480:	02059493          	slli	s1,a1,0x20
    80003484:	9081                	srli	s1,s1,0x20
    80003486:	048a                	slli	s1,s1,0x2
    80003488:	94aa                	add	s1,s1,a0
    8000348a:	0504a903          	lw	s2,80(s1)
    8000348e:	06091e63          	bnez	s2,8000350a <bmap+0xa2>
      addr = balloc(ip->dev);
    80003492:	4108                	lw	a0,0(a0)
    80003494:	00000097          	auipc	ra,0x0
    80003498:	e9c080e7          	jalr	-356(ra) # 80003330 <balloc>
    8000349c:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800034a0:	06090563          	beqz	s2,8000350a <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    800034a4:	0524a823          	sw	s2,80(s1)
    800034a8:	a08d                	j	8000350a <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    800034aa:	ff45849b          	addiw	s1,a1,-12
    800034ae:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800034b2:	0ff00793          	li	a5,255
    800034b6:	08e7e563          	bltu	a5,a4,80003540 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800034ba:	08052903          	lw	s2,128(a0)
    800034be:	00091d63          	bnez	s2,800034d8 <bmap+0x70>
      addr = balloc(ip->dev);
    800034c2:	4108                	lw	a0,0(a0)
    800034c4:	00000097          	auipc	ra,0x0
    800034c8:	e6c080e7          	jalr	-404(ra) # 80003330 <balloc>
    800034cc:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800034d0:	02090d63          	beqz	s2,8000350a <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800034d4:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800034d8:	85ca                	mv	a1,s2
    800034da:	0009a503          	lw	a0,0(s3)
    800034de:	00000097          	auipc	ra,0x0
    800034e2:	b90080e7          	jalr	-1136(ra) # 8000306e <bread>
    800034e6:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800034e8:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800034ec:	02049593          	slli	a1,s1,0x20
    800034f0:	9181                	srli	a1,a1,0x20
    800034f2:	058a                	slli	a1,a1,0x2
    800034f4:	00b784b3          	add	s1,a5,a1
    800034f8:	0004a903          	lw	s2,0(s1)
    800034fc:	02090063          	beqz	s2,8000351c <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003500:	8552                	mv	a0,s4
    80003502:	00000097          	auipc	ra,0x0
    80003506:	c9c080e7          	jalr	-868(ra) # 8000319e <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000350a:	854a                	mv	a0,s2
    8000350c:	70a2                	ld	ra,40(sp)
    8000350e:	7402                	ld	s0,32(sp)
    80003510:	64e2                	ld	s1,24(sp)
    80003512:	6942                	ld	s2,16(sp)
    80003514:	69a2                	ld	s3,8(sp)
    80003516:	6a02                	ld	s4,0(sp)
    80003518:	6145                	addi	sp,sp,48
    8000351a:	8082                	ret
      addr = balloc(ip->dev);
    8000351c:	0009a503          	lw	a0,0(s3)
    80003520:	00000097          	auipc	ra,0x0
    80003524:	e10080e7          	jalr	-496(ra) # 80003330 <balloc>
    80003528:	0005091b          	sext.w	s2,a0
      if(addr){
    8000352c:	fc090ae3          	beqz	s2,80003500 <bmap+0x98>
        a[bn] = addr;
    80003530:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003534:	8552                	mv	a0,s4
    80003536:	00001097          	auipc	ra,0x1
    8000353a:	eec080e7          	jalr	-276(ra) # 80004422 <log_write>
    8000353e:	b7c9                	j	80003500 <bmap+0x98>
  panic("bmap: out of range");
    80003540:	00005517          	auipc	a0,0x5
    80003544:	22850513          	addi	a0,a0,552 # 80008768 <syscalls+0x148>
    80003548:	ffffd097          	auipc	ra,0xffffd
    8000354c:	ffc080e7          	jalr	-4(ra) # 80000544 <panic>

0000000080003550 <iget>:
{
    80003550:	7179                	addi	sp,sp,-48
    80003552:	f406                	sd	ra,40(sp)
    80003554:	f022                	sd	s0,32(sp)
    80003556:	ec26                	sd	s1,24(sp)
    80003558:	e84a                	sd	s2,16(sp)
    8000355a:	e44e                	sd	s3,8(sp)
    8000355c:	e052                	sd	s4,0(sp)
    8000355e:	1800                	addi	s0,sp,48
    80003560:	89aa                	mv	s3,a0
    80003562:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003564:	00024517          	auipc	a0,0x24
    80003568:	04c50513          	addi	a0,a0,76 # 800275b0 <itable>
    8000356c:	ffffd097          	auipc	ra,0xffffd
    80003570:	67e080e7          	jalr	1662(ra) # 80000bea <acquire>
  empty = 0;
    80003574:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003576:	00024497          	auipc	s1,0x24
    8000357a:	05248493          	addi	s1,s1,82 # 800275c8 <itable+0x18>
    8000357e:	00026697          	auipc	a3,0x26
    80003582:	ada68693          	addi	a3,a3,-1318 # 80029058 <log>
    80003586:	a039                	j	80003594 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003588:	02090b63          	beqz	s2,800035be <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000358c:	08848493          	addi	s1,s1,136
    80003590:	02d48a63          	beq	s1,a3,800035c4 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003594:	449c                	lw	a5,8(s1)
    80003596:	fef059e3          	blez	a5,80003588 <iget+0x38>
    8000359a:	4098                	lw	a4,0(s1)
    8000359c:	ff3716e3          	bne	a4,s3,80003588 <iget+0x38>
    800035a0:	40d8                	lw	a4,4(s1)
    800035a2:	ff4713e3          	bne	a4,s4,80003588 <iget+0x38>
      ip->ref++;
    800035a6:	2785                	addiw	a5,a5,1
    800035a8:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800035aa:	00024517          	auipc	a0,0x24
    800035ae:	00650513          	addi	a0,a0,6 # 800275b0 <itable>
    800035b2:	ffffd097          	auipc	ra,0xffffd
    800035b6:	6ec080e7          	jalr	1772(ra) # 80000c9e <release>
      return ip;
    800035ba:	8926                	mv	s2,s1
    800035bc:	a03d                	j	800035ea <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035be:	f7f9                	bnez	a5,8000358c <iget+0x3c>
    800035c0:	8926                	mv	s2,s1
    800035c2:	b7e9                	j	8000358c <iget+0x3c>
  if(empty == 0)
    800035c4:	02090c63          	beqz	s2,800035fc <iget+0xac>
  ip->dev = dev;
    800035c8:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800035cc:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800035d0:	4785                	li	a5,1
    800035d2:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800035d6:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800035da:	00024517          	auipc	a0,0x24
    800035de:	fd650513          	addi	a0,a0,-42 # 800275b0 <itable>
    800035e2:	ffffd097          	auipc	ra,0xffffd
    800035e6:	6bc080e7          	jalr	1724(ra) # 80000c9e <release>
}
    800035ea:	854a                	mv	a0,s2
    800035ec:	70a2                	ld	ra,40(sp)
    800035ee:	7402                	ld	s0,32(sp)
    800035f0:	64e2                	ld	s1,24(sp)
    800035f2:	6942                	ld	s2,16(sp)
    800035f4:	69a2                	ld	s3,8(sp)
    800035f6:	6a02                	ld	s4,0(sp)
    800035f8:	6145                	addi	sp,sp,48
    800035fa:	8082                	ret
    panic("iget: no inodes");
    800035fc:	00005517          	auipc	a0,0x5
    80003600:	18450513          	addi	a0,a0,388 # 80008780 <syscalls+0x160>
    80003604:	ffffd097          	auipc	ra,0xffffd
    80003608:	f40080e7          	jalr	-192(ra) # 80000544 <panic>

000000008000360c <fsinit>:
fsinit(int dev) {
    8000360c:	7179                	addi	sp,sp,-48
    8000360e:	f406                	sd	ra,40(sp)
    80003610:	f022                	sd	s0,32(sp)
    80003612:	ec26                	sd	s1,24(sp)
    80003614:	e84a                	sd	s2,16(sp)
    80003616:	e44e                	sd	s3,8(sp)
    80003618:	1800                	addi	s0,sp,48
    8000361a:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000361c:	4585                	li	a1,1
    8000361e:	00000097          	auipc	ra,0x0
    80003622:	a50080e7          	jalr	-1456(ra) # 8000306e <bread>
    80003626:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003628:	00024997          	auipc	s3,0x24
    8000362c:	f6898993          	addi	s3,s3,-152 # 80027590 <sb>
    80003630:	02000613          	li	a2,32
    80003634:	05850593          	addi	a1,a0,88
    80003638:	854e                	mv	a0,s3
    8000363a:	ffffd097          	auipc	ra,0xffffd
    8000363e:	70c080e7          	jalr	1804(ra) # 80000d46 <memmove>
  brelse(bp);
    80003642:	8526                	mv	a0,s1
    80003644:	00000097          	auipc	ra,0x0
    80003648:	b5a080e7          	jalr	-1190(ra) # 8000319e <brelse>
  if(sb.magic != FSMAGIC)
    8000364c:	0009a703          	lw	a4,0(s3)
    80003650:	102037b7          	lui	a5,0x10203
    80003654:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003658:	02f71263          	bne	a4,a5,8000367c <fsinit+0x70>
  initlog(dev, &sb);
    8000365c:	00024597          	auipc	a1,0x24
    80003660:	f3458593          	addi	a1,a1,-204 # 80027590 <sb>
    80003664:	854a                	mv	a0,s2
    80003666:	00001097          	auipc	ra,0x1
    8000366a:	b40080e7          	jalr	-1216(ra) # 800041a6 <initlog>
}
    8000366e:	70a2                	ld	ra,40(sp)
    80003670:	7402                	ld	s0,32(sp)
    80003672:	64e2                	ld	s1,24(sp)
    80003674:	6942                	ld	s2,16(sp)
    80003676:	69a2                	ld	s3,8(sp)
    80003678:	6145                	addi	sp,sp,48
    8000367a:	8082                	ret
    panic("invalid file system");
    8000367c:	00005517          	auipc	a0,0x5
    80003680:	11450513          	addi	a0,a0,276 # 80008790 <syscalls+0x170>
    80003684:	ffffd097          	auipc	ra,0xffffd
    80003688:	ec0080e7          	jalr	-320(ra) # 80000544 <panic>

000000008000368c <iinit>:
{
    8000368c:	7179                	addi	sp,sp,-48
    8000368e:	f406                	sd	ra,40(sp)
    80003690:	f022                	sd	s0,32(sp)
    80003692:	ec26                	sd	s1,24(sp)
    80003694:	e84a                	sd	s2,16(sp)
    80003696:	e44e                	sd	s3,8(sp)
    80003698:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000369a:	00005597          	auipc	a1,0x5
    8000369e:	10e58593          	addi	a1,a1,270 # 800087a8 <syscalls+0x188>
    800036a2:	00024517          	auipc	a0,0x24
    800036a6:	f0e50513          	addi	a0,a0,-242 # 800275b0 <itable>
    800036aa:	ffffd097          	auipc	ra,0xffffd
    800036ae:	4b0080e7          	jalr	1200(ra) # 80000b5a <initlock>
  for(i = 0; i < NINODE; i++) {
    800036b2:	00024497          	auipc	s1,0x24
    800036b6:	f2648493          	addi	s1,s1,-218 # 800275d8 <itable+0x28>
    800036ba:	00026997          	auipc	s3,0x26
    800036be:	9ae98993          	addi	s3,s3,-1618 # 80029068 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800036c2:	00005917          	auipc	s2,0x5
    800036c6:	0ee90913          	addi	s2,s2,238 # 800087b0 <syscalls+0x190>
    800036ca:	85ca                	mv	a1,s2
    800036cc:	8526                	mv	a0,s1
    800036ce:	00001097          	auipc	ra,0x1
    800036d2:	e3a080e7          	jalr	-454(ra) # 80004508 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800036d6:	08848493          	addi	s1,s1,136
    800036da:	ff3498e3          	bne	s1,s3,800036ca <iinit+0x3e>
}
    800036de:	70a2                	ld	ra,40(sp)
    800036e0:	7402                	ld	s0,32(sp)
    800036e2:	64e2                	ld	s1,24(sp)
    800036e4:	6942                	ld	s2,16(sp)
    800036e6:	69a2                	ld	s3,8(sp)
    800036e8:	6145                	addi	sp,sp,48
    800036ea:	8082                	ret

00000000800036ec <ialloc>:
{
    800036ec:	715d                	addi	sp,sp,-80
    800036ee:	e486                	sd	ra,72(sp)
    800036f0:	e0a2                	sd	s0,64(sp)
    800036f2:	fc26                	sd	s1,56(sp)
    800036f4:	f84a                	sd	s2,48(sp)
    800036f6:	f44e                	sd	s3,40(sp)
    800036f8:	f052                	sd	s4,32(sp)
    800036fa:	ec56                	sd	s5,24(sp)
    800036fc:	e85a                	sd	s6,16(sp)
    800036fe:	e45e                	sd	s7,8(sp)
    80003700:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003702:	00024717          	auipc	a4,0x24
    80003706:	e9a72703          	lw	a4,-358(a4) # 8002759c <sb+0xc>
    8000370a:	4785                	li	a5,1
    8000370c:	04e7fa63          	bgeu	a5,a4,80003760 <ialloc+0x74>
    80003710:	8aaa                	mv	s5,a0
    80003712:	8bae                	mv	s7,a1
    80003714:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003716:	00024a17          	auipc	s4,0x24
    8000371a:	e7aa0a13          	addi	s4,s4,-390 # 80027590 <sb>
    8000371e:	00048b1b          	sext.w	s6,s1
    80003722:	0044d593          	srli	a1,s1,0x4
    80003726:	018a2783          	lw	a5,24(s4)
    8000372a:	9dbd                	addw	a1,a1,a5
    8000372c:	8556                	mv	a0,s5
    8000372e:	00000097          	auipc	ra,0x0
    80003732:	940080e7          	jalr	-1728(ra) # 8000306e <bread>
    80003736:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003738:	05850993          	addi	s3,a0,88
    8000373c:	00f4f793          	andi	a5,s1,15
    80003740:	079a                	slli	a5,a5,0x6
    80003742:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003744:	00099783          	lh	a5,0(s3)
    80003748:	c3a1                	beqz	a5,80003788 <ialloc+0x9c>
    brelse(bp);
    8000374a:	00000097          	auipc	ra,0x0
    8000374e:	a54080e7          	jalr	-1452(ra) # 8000319e <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003752:	0485                	addi	s1,s1,1
    80003754:	00ca2703          	lw	a4,12(s4)
    80003758:	0004879b          	sext.w	a5,s1
    8000375c:	fce7e1e3          	bltu	a5,a4,8000371e <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003760:	00005517          	auipc	a0,0x5
    80003764:	05850513          	addi	a0,a0,88 # 800087b8 <syscalls+0x198>
    80003768:	ffffd097          	auipc	ra,0xffffd
    8000376c:	e26080e7          	jalr	-474(ra) # 8000058e <printf>
  return 0;
    80003770:	4501                	li	a0,0
}
    80003772:	60a6                	ld	ra,72(sp)
    80003774:	6406                	ld	s0,64(sp)
    80003776:	74e2                	ld	s1,56(sp)
    80003778:	7942                	ld	s2,48(sp)
    8000377a:	79a2                	ld	s3,40(sp)
    8000377c:	7a02                	ld	s4,32(sp)
    8000377e:	6ae2                	ld	s5,24(sp)
    80003780:	6b42                	ld	s6,16(sp)
    80003782:	6ba2                	ld	s7,8(sp)
    80003784:	6161                	addi	sp,sp,80
    80003786:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003788:	04000613          	li	a2,64
    8000378c:	4581                	li	a1,0
    8000378e:	854e                	mv	a0,s3
    80003790:	ffffd097          	auipc	ra,0xffffd
    80003794:	556080e7          	jalr	1366(ra) # 80000ce6 <memset>
      dip->type = type;
    80003798:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000379c:	854a                	mv	a0,s2
    8000379e:	00001097          	auipc	ra,0x1
    800037a2:	c84080e7          	jalr	-892(ra) # 80004422 <log_write>
      brelse(bp);
    800037a6:	854a                	mv	a0,s2
    800037a8:	00000097          	auipc	ra,0x0
    800037ac:	9f6080e7          	jalr	-1546(ra) # 8000319e <brelse>
      return iget(dev, inum);
    800037b0:	85da                	mv	a1,s6
    800037b2:	8556                	mv	a0,s5
    800037b4:	00000097          	auipc	ra,0x0
    800037b8:	d9c080e7          	jalr	-612(ra) # 80003550 <iget>
    800037bc:	bf5d                	j	80003772 <ialloc+0x86>

00000000800037be <iupdate>:
{
    800037be:	1101                	addi	sp,sp,-32
    800037c0:	ec06                	sd	ra,24(sp)
    800037c2:	e822                	sd	s0,16(sp)
    800037c4:	e426                	sd	s1,8(sp)
    800037c6:	e04a                	sd	s2,0(sp)
    800037c8:	1000                	addi	s0,sp,32
    800037ca:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037cc:	415c                	lw	a5,4(a0)
    800037ce:	0047d79b          	srliw	a5,a5,0x4
    800037d2:	00024597          	auipc	a1,0x24
    800037d6:	dd65a583          	lw	a1,-554(a1) # 800275a8 <sb+0x18>
    800037da:	9dbd                	addw	a1,a1,a5
    800037dc:	4108                	lw	a0,0(a0)
    800037de:	00000097          	auipc	ra,0x0
    800037e2:	890080e7          	jalr	-1904(ra) # 8000306e <bread>
    800037e6:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037e8:	05850793          	addi	a5,a0,88
    800037ec:	40c8                	lw	a0,4(s1)
    800037ee:	893d                	andi	a0,a0,15
    800037f0:	051a                	slli	a0,a0,0x6
    800037f2:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800037f4:	04449703          	lh	a4,68(s1)
    800037f8:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800037fc:	04649703          	lh	a4,70(s1)
    80003800:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003804:	04849703          	lh	a4,72(s1)
    80003808:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000380c:	04a49703          	lh	a4,74(s1)
    80003810:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003814:	44f8                	lw	a4,76(s1)
    80003816:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003818:	03400613          	li	a2,52
    8000381c:	05048593          	addi	a1,s1,80
    80003820:	0531                	addi	a0,a0,12
    80003822:	ffffd097          	auipc	ra,0xffffd
    80003826:	524080e7          	jalr	1316(ra) # 80000d46 <memmove>
  log_write(bp);
    8000382a:	854a                	mv	a0,s2
    8000382c:	00001097          	auipc	ra,0x1
    80003830:	bf6080e7          	jalr	-1034(ra) # 80004422 <log_write>
  brelse(bp);
    80003834:	854a                	mv	a0,s2
    80003836:	00000097          	auipc	ra,0x0
    8000383a:	968080e7          	jalr	-1688(ra) # 8000319e <brelse>
}
    8000383e:	60e2                	ld	ra,24(sp)
    80003840:	6442                	ld	s0,16(sp)
    80003842:	64a2                	ld	s1,8(sp)
    80003844:	6902                	ld	s2,0(sp)
    80003846:	6105                	addi	sp,sp,32
    80003848:	8082                	ret

000000008000384a <idup>:
{
    8000384a:	1101                	addi	sp,sp,-32
    8000384c:	ec06                	sd	ra,24(sp)
    8000384e:	e822                	sd	s0,16(sp)
    80003850:	e426                	sd	s1,8(sp)
    80003852:	1000                	addi	s0,sp,32
    80003854:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003856:	00024517          	auipc	a0,0x24
    8000385a:	d5a50513          	addi	a0,a0,-678 # 800275b0 <itable>
    8000385e:	ffffd097          	auipc	ra,0xffffd
    80003862:	38c080e7          	jalr	908(ra) # 80000bea <acquire>
  ip->ref++;
    80003866:	449c                	lw	a5,8(s1)
    80003868:	2785                	addiw	a5,a5,1
    8000386a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000386c:	00024517          	auipc	a0,0x24
    80003870:	d4450513          	addi	a0,a0,-700 # 800275b0 <itable>
    80003874:	ffffd097          	auipc	ra,0xffffd
    80003878:	42a080e7          	jalr	1066(ra) # 80000c9e <release>
}
    8000387c:	8526                	mv	a0,s1
    8000387e:	60e2                	ld	ra,24(sp)
    80003880:	6442                	ld	s0,16(sp)
    80003882:	64a2                	ld	s1,8(sp)
    80003884:	6105                	addi	sp,sp,32
    80003886:	8082                	ret

0000000080003888 <ilock>:
{
    80003888:	1101                	addi	sp,sp,-32
    8000388a:	ec06                	sd	ra,24(sp)
    8000388c:	e822                	sd	s0,16(sp)
    8000388e:	e426                	sd	s1,8(sp)
    80003890:	e04a                	sd	s2,0(sp)
    80003892:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003894:	c115                	beqz	a0,800038b8 <ilock+0x30>
    80003896:	84aa                	mv	s1,a0
    80003898:	451c                	lw	a5,8(a0)
    8000389a:	00f05f63          	blez	a5,800038b8 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000389e:	0541                	addi	a0,a0,16
    800038a0:	00001097          	auipc	ra,0x1
    800038a4:	ca2080e7          	jalr	-862(ra) # 80004542 <acquiresleep>
  if(ip->valid == 0){
    800038a8:	40bc                	lw	a5,64(s1)
    800038aa:	cf99                	beqz	a5,800038c8 <ilock+0x40>
}
    800038ac:	60e2                	ld	ra,24(sp)
    800038ae:	6442                	ld	s0,16(sp)
    800038b0:	64a2                	ld	s1,8(sp)
    800038b2:	6902                	ld	s2,0(sp)
    800038b4:	6105                	addi	sp,sp,32
    800038b6:	8082                	ret
    panic("ilock");
    800038b8:	00005517          	auipc	a0,0x5
    800038bc:	f1850513          	addi	a0,a0,-232 # 800087d0 <syscalls+0x1b0>
    800038c0:	ffffd097          	auipc	ra,0xffffd
    800038c4:	c84080e7          	jalr	-892(ra) # 80000544 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038c8:	40dc                	lw	a5,4(s1)
    800038ca:	0047d79b          	srliw	a5,a5,0x4
    800038ce:	00024597          	auipc	a1,0x24
    800038d2:	cda5a583          	lw	a1,-806(a1) # 800275a8 <sb+0x18>
    800038d6:	9dbd                	addw	a1,a1,a5
    800038d8:	4088                	lw	a0,0(s1)
    800038da:	fffff097          	auipc	ra,0xfffff
    800038de:	794080e7          	jalr	1940(ra) # 8000306e <bread>
    800038e2:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038e4:	05850593          	addi	a1,a0,88
    800038e8:	40dc                	lw	a5,4(s1)
    800038ea:	8bbd                	andi	a5,a5,15
    800038ec:	079a                	slli	a5,a5,0x6
    800038ee:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800038f0:	00059783          	lh	a5,0(a1)
    800038f4:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800038f8:	00259783          	lh	a5,2(a1)
    800038fc:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003900:	00459783          	lh	a5,4(a1)
    80003904:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003908:	00659783          	lh	a5,6(a1)
    8000390c:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003910:	459c                	lw	a5,8(a1)
    80003912:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003914:	03400613          	li	a2,52
    80003918:	05b1                	addi	a1,a1,12
    8000391a:	05048513          	addi	a0,s1,80
    8000391e:	ffffd097          	auipc	ra,0xffffd
    80003922:	428080e7          	jalr	1064(ra) # 80000d46 <memmove>
    brelse(bp);
    80003926:	854a                	mv	a0,s2
    80003928:	00000097          	auipc	ra,0x0
    8000392c:	876080e7          	jalr	-1930(ra) # 8000319e <brelse>
    ip->valid = 1;
    80003930:	4785                	li	a5,1
    80003932:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003934:	04449783          	lh	a5,68(s1)
    80003938:	fbb5                	bnez	a5,800038ac <ilock+0x24>
      panic("ilock: no type");
    8000393a:	00005517          	auipc	a0,0x5
    8000393e:	e9e50513          	addi	a0,a0,-354 # 800087d8 <syscalls+0x1b8>
    80003942:	ffffd097          	auipc	ra,0xffffd
    80003946:	c02080e7          	jalr	-1022(ra) # 80000544 <panic>

000000008000394a <iunlock>:
{
    8000394a:	1101                	addi	sp,sp,-32
    8000394c:	ec06                	sd	ra,24(sp)
    8000394e:	e822                	sd	s0,16(sp)
    80003950:	e426                	sd	s1,8(sp)
    80003952:	e04a                	sd	s2,0(sp)
    80003954:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003956:	c905                	beqz	a0,80003986 <iunlock+0x3c>
    80003958:	84aa                	mv	s1,a0
    8000395a:	01050913          	addi	s2,a0,16
    8000395e:	854a                	mv	a0,s2
    80003960:	00001097          	auipc	ra,0x1
    80003964:	c7c080e7          	jalr	-900(ra) # 800045dc <holdingsleep>
    80003968:	cd19                	beqz	a0,80003986 <iunlock+0x3c>
    8000396a:	449c                	lw	a5,8(s1)
    8000396c:	00f05d63          	blez	a5,80003986 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003970:	854a                	mv	a0,s2
    80003972:	00001097          	auipc	ra,0x1
    80003976:	c26080e7          	jalr	-986(ra) # 80004598 <releasesleep>
}
    8000397a:	60e2                	ld	ra,24(sp)
    8000397c:	6442                	ld	s0,16(sp)
    8000397e:	64a2                	ld	s1,8(sp)
    80003980:	6902                	ld	s2,0(sp)
    80003982:	6105                	addi	sp,sp,32
    80003984:	8082                	ret
    panic("iunlock");
    80003986:	00005517          	auipc	a0,0x5
    8000398a:	e6250513          	addi	a0,a0,-414 # 800087e8 <syscalls+0x1c8>
    8000398e:	ffffd097          	auipc	ra,0xffffd
    80003992:	bb6080e7          	jalr	-1098(ra) # 80000544 <panic>

0000000080003996 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003996:	7179                	addi	sp,sp,-48
    80003998:	f406                	sd	ra,40(sp)
    8000399a:	f022                	sd	s0,32(sp)
    8000399c:	ec26                	sd	s1,24(sp)
    8000399e:	e84a                	sd	s2,16(sp)
    800039a0:	e44e                	sd	s3,8(sp)
    800039a2:	e052                	sd	s4,0(sp)
    800039a4:	1800                	addi	s0,sp,48
    800039a6:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800039a8:	05050493          	addi	s1,a0,80
    800039ac:	08050913          	addi	s2,a0,128
    800039b0:	a021                	j	800039b8 <itrunc+0x22>
    800039b2:	0491                	addi	s1,s1,4
    800039b4:	01248d63          	beq	s1,s2,800039ce <itrunc+0x38>
    if(ip->addrs[i]){
    800039b8:	408c                	lw	a1,0(s1)
    800039ba:	dde5                	beqz	a1,800039b2 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800039bc:	0009a503          	lw	a0,0(s3)
    800039c0:	00000097          	auipc	ra,0x0
    800039c4:	8f4080e7          	jalr	-1804(ra) # 800032b4 <bfree>
      ip->addrs[i] = 0;
    800039c8:	0004a023          	sw	zero,0(s1)
    800039cc:	b7dd                	j	800039b2 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800039ce:	0809a583          	lw	a1,128(s3)
    800039d2:	e185                	bnez	a1,800039f2 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800039d4:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800039d8:	854e                	mv	a0,s3
    800039da:	00000097          	auipc	ra,0x0
    800039de:	de4080e7          	jalr	-540(ra) # 800037be <iupdate>
}
    800039e2:	70a2                	ld	ra,40(sp)
    800039e4:	7402                	ld	s0,32(sp)
    800039e6:	64e2                	ld	s1,24(sp)
    800039e8:	6942                	ld	s2,16(sp)
    800039ea:	69a2                	ld	s3,8(sp)
    800039ec:	6a02                	ld	s4,0(sp)
    800039ee:	6145                	addi	sp,sp,48
    800039f0:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800039f2:	0009a503          	lw	a0,0(s3)
    800039f6:	fffff097          	auipc	ra,0xfffff
    800039fa:	678080e7          	jalr	1656(ra) # 8000306e <bread>
    800039fe:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003a00:	05850493          	addi	s1,a0,88
    80003a04:	45850913          	addi	s2,a0,1112
    80003a08:	a811                	j	80003a1c <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003a0a:	0009a503          	lw	a0,0(s3)
    80003a0e:	00000097          	auipc	ra,0x0
    80003a12:	8a6080e7          	jalr	-1882(ra) # 800032b4 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003a16:	0491                	addi	s1,s1,4
    80003a18:	01248563          	beq	s1,s2,80003a22 <itrunc+0x8c>
      if(a[j])
    80003a1c:	408c                	lw	a1,0(s1)
    80003a1e:	dde5                	beqz	a1,80003a16 <itrunc+0x80>
    80003a20:	b7ed                	j	80003a0a <itrunc+0x74>
    brelse(bp);
    80003a22:	8552                	mv	a0,s4
    80003a24:	fffff097          	auipc	ra,0xfffff
    80003a28:	77a080e7          	jalr	1914(ra) # 8000319e <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003a2c:	0809a583          	lw	a1,128(s3)
    80003a30:	0009a503          	lw	a0,0(s3)
    80003a34:	00000097          	auipc	ra,0x0
    80003a38:	880080e7          	jalr	-1920(ra) # 800032b4 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003a3c:	0809a023          	sw	zero,128(s3)
    80003a40:	bf51                	j	800039d4 <itrunc+0x3e>

0000000080003a42 <iput>:
{
    80003a42:	1101                	addi	sp,sp,-32
    80003a44:	ec06                	sd	ra,24(sp)
    80003a46:	e822                	sd	s0,16(sp)
    80003a48:	e426                	sd	s1,8(sp)
    80003a4a:	e04a                	sd	s2,0(sp)
    80003a4c:	1000                	addi	s0,sp,32
    80003a4e:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a50:	00024517          	auipc	a0,0x24
    80003a54:	b6050513          	addi	a0,a0,-1184 # 800275b0 <itable>
    80003a58:	ffffd097          	auipc	ra,0xffffd
    80003a5c:	192080e7          	jalr	402(ra) # 80000bea <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a60:	4498                	lw	a4,8(s1)
    80003a62:	4785                	li	a5,1
    80003a64:	02f70363          	beq	a4,a5,80003a8a <iput+0x48>
  ip->ref--;
    80003a68:	449c                	lw	a5,8(s1)
    80003a6a:	37fd                	addiw	a5,a5,-1
    80003a6c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003a6e:	00024517          	auipc	a0,0x24
    80003a72:	b4250513          	addi	a0,a0,-1214 # 800275b0 <itable>
    80003a76:	ffffd097          	auipc	ra,0xffffd
    80003a7a:	228080e7          	jalr	552(ra) # 80000c9e <release>
}
    80003a7e:	60e2                	ld	ra,24(sp)
    80003a80:	6442                	ld	s0,16(sp)
    80003a82:	64a2                	ld	s1,8(sp)
    80003a84:	6902                	ld	s2,0(sp)
    80003a86:	6105                	addi	sp,sp,32
    80003a88:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a8a:	40bc                	lw	a5,64(s1)
    80003a8c:	dff1                	beqz	a5,80003a68 <iput+0x26>
    80003a8e:	04a49783          	lh	a5,74(s1)
    80003a92:	fbf9                	bnez	a5,80003a68 <iput+0x26>
    acquiresleep(&ip->lock);
    80003a94:	01048913          	addi	s2,s1,16
    80003a98:	854a                	mv	a0,s2
    80003a9a:	00001097          	auipc	ra,0x1
    80003a9e:	aa8080e7          	jalr	-1368(ra) # 80004542 <acquiresleep>
    release(&itable.lock);
    80003aa2:	00024517          	auipc	a0,0x24
    80003aa6:	b0e50513          	addi	a0,a0,-1266 # 800275b0 <itable>
    80003aaa:	ffffd097          	auipc	ra,0xffffd
    80003aae:	1f4080e7          	jalr	500(ra) # 80000c9e <release>
    itrunc(ip);
    80003ab2:	8526                	mv	a0,s1
    80003ab4:	00000097          	auipc	ra,0x0
    80003ab8:	ee2080e7          	jalr	-286(ra) # 80003996 <itrunc>
    ip->type = 0;
    80003abc:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003ac0:	8526                	mv	a0,s1
    80003ac2:	00000097          	auipc	ra,0x0
    80003ac6:	cfc080e7          	jalr	-772(ra) # 800037be <iupdate>
    ip->valid = 0;
    80003aca:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003ace:	854a                	mv	a0,s2
    80003ad0:	00001097          	auipc	ra,0x1
    80003ad4:	ac8080e7          	jalr	-1336(ra) # 80004598 <releasesleep>
    acquire(&itable.lock);
    80003ad8:	00024517          	auipc	a0,0x24
    80003adc:	ad850513          	addi	a0,a0,-1320 # 800275b0 <itable>
    80003ae0:	ffffd097          	auipc	ra,0xffffd
    80003ae4:	10a080e7          	jalr	266(ra) # 80000bea <acquire>
    80003ae8:	b741                	j	80003a68 <iput+0x26>

0000000080003aea <iunlockput>:
{
    80003aea:	1101                	addi	sp,sp,-32
    80003aec:	ec06                	sd	ra,24(sp)
    80003aee:	e822                	sd	s0,16(sp)
    80003af0:	e426                	sd	s1,8(sp)
    80003af2:	1000                	addi	s0,sp,32
    80003af4:	84aa                	mv	s1,a0
  iunlock(ip);
    80003af6:	00000097          	auipc	ra,0x0
    80003afa:	e54080e7          	jalr	-428(ra) # 8000394a <iunlock>
  iput(ip);
    80003afe:	8526                	mv	a0,s1
    80003b00:	00000097          	auipc	ra,0x0
    80003b04:	f42080e7          	jalr	-190(ra) # 80003a42 <iput>
}
    80003b08:	60e2                	ld	ra,24(sp)
    80003b0a:	6442                	ld	s0,16(sp)
    80003b0c:	64a2                	ld	s1,8(sp)
    80003b0e:	6105                	addi	sp,sp,32
    80003b10:	8082                	ret

0000000080003b12 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003b12:	1141                	addi	sp,sp,-16
    80003b14:	e422                	sd	s0,8(sp)
    80003b16:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003b18:	411c                	lw	a5,0(a0)
    80003b1a:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003b1c:	415c                	lw	a5,4(a0)
    80003b1e:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003b20:	04451783          	lh	a5,68(a0)
    80003b24:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003b28:	04a51783          	lh	a5,74(a0)
    80003b2c:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003b30:	04c56783          	lwu	a5,76(a0)
    80003b34:	e99c                	sd	a5,16(a1)
}
    80003b36:	6422                	ld	s0,8(sp)
    80003b38:	0141                	addi	sp,sp,16
    80003b3a:	8082                	ret

0000000080003b3c <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b3c:	457c                	lw	a5,76(a0)
    80003b3e:	0ed7e963          	bltu	a5,a3,80003c30 <readi+0xf4>
{
    80003b42:	7159                	addi	sp,sp,-112
    80003b44:	f486                	sd	ra,104(sp)
    80003b46:	f0a2                	sd	s0,96(sp)
    80003b48:	eca6                	sd	s1,88(sp)
    80003b4a:	e8ca                	sd	s2,80(sp)
    80003b4c:	e4ce                	sd	s3,72(sp)
    80003b4e:	e0d2                	sd	s4,64(sp)
    80003b50:	fc56                	sd	s5,56(sp)
    80003b52:	f85a                	sd	s6,48(sp)
    80003b54:	f45e                	sd	s7,40(sp)
    80003b56:	f062                	sd	s8,32(sp)
    80003b58:	ec66                	sd	s9,24(sp)
    80003b5a:	e86a                	sd	s10,16(sp)
    80003b5c:	e46e                	sd	s11,8(sp)
    80003b5e:	1880                	addi	s0,sp,112
    80003b60:	8b2a                	mv	s6,a0
    80003b62:	8bae                	mv	s7,a1
    80003b64:	8a32                	mv	s4,a2
    80003b66:	84b6                	mv	s1,a3
    80003b68:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003b6a:	9f35                	addw	a4,a4,a3
    return 0;
    80003b6c:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003b6e:	0ad76063          	bltu	a4,a3,80003c0e <readi+0xd2>
  if(off + n > ip->size)
    80003b72:	00e7f463          	bgeu	a5,a4,80003b7a <readi+0x3e>
    n = ip->size - off;
    80003b76:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b7a:	0a0a8963          	beqz	s5,80003c2c <readi+0xf0>
    80003b7e:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b80:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003b84:	5c7d                	li	s8,-1
    80003b86:	a82d                	j	80003bc0 <readi+0x84>
    80003b88:	020d1d93          	slli	s11,s10,0x20
    80003b8c:	020ddd93          	srli	s11,s11,0x20
    80003b90:	05890613          	addi	a2,s2,88
    80003b94:	86ee                	mv	a3,s11
    80003b96:	963a                	add	a2,a2,a4
    80003b98:	85d2                	mv	a1,s4
    80003b9a:	855e                	mv	a0,s7
    80003b9c:	fffff097          	auipc	ra,0xfffff
    80003ba0:	976080e7          	jalr	-1674(ra) # 80002512 <either_copyout>
    80003ba4:	05850d63          	beq	a0,s8,80003bfe <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003ba8:	854a                	mv	a0,s2
    80003baa:	fffff097          	auipc	ra,0xfffff
    80003bae:	5f4080e7          	jalr	1524(ra) # 8000319e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bb2:	013d09bb          	addw	s3,s10,s3
    80003bb6:	009d04bb          	addw	s1,s10,s1
    80003bba:	9a6e                	add	s4,s4,s11
    80003bbc:	0559f763          	bgeu	s3,s5,80003c0a <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003bc0:	00a4d59b          	srliw	a1,s1,0xa
    80003bc4:	855a                	mv	a0,s6
    80003bc6:	00000097          	auipc	ra,0x0
    80003bca:	8a2080e7          	jalr	-1886(ra) # 80003468 <bmap>
    80003bce:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003bd2:	cd85                	beqz	a1,80003c0a <readi+0xce>
    bp = bread(ip->dev, addr);
    80003bd4:	000b2503          	lw	a0,0(s6)
    80003bd8:	fffff097          	auipc	ra,0xfffff
    80003bdc:	496080e7          	jalr	1174(ra) # 8000306e <bread>
    80003be0:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003be2:	3ff4f713          	andi	a4,s1,1023
    80003be6:	40ec87bb          	subw	a5,s9,a4
    80003bea:	413a86bb          	subw	a3,s5,s3
    80003bee:	8d3e                	mv	s10,a5
    80003bf0:	2781                	sext.w	a5,a5
    80003bf2:	0006861b          	sext.w	a2,a3
    80003bf6:	f8f679e3          	bgeu	a2,a5,80003b88 <readi+0x4c>
    80003bfa:	8d36                	mv	s10,a3
    80003bfc:	b771                	j	80003b88 <readi+0x4c>
      brelse(bp);
    80003bfe:	854a                	mv	a0,s2
    80003c00:	fffff097          	auipc	ra,0xfffff
    80003c04:	59e080e7          	jalr	1438(ra) # 8000319e <brelse>
      tot = -1;
    80003c08:	59fd                	li	s3,-1
  }
  return tot;
    80003c0a:	0009851b          	sext.w	a0,s3
}
    80003c0e:	70a6                	ld	ra,104(sp)
    80003c10:	7406                	ld	s0,96(sp)
    80003c12:	64e6                	ld	s1,88(sp)
    80003c14:	6946                	ld	s2,80(sp)
    80003c16:	69a6                	ld	s3,72(sp)
    80003c18:	6a06                	ld	s4,64(sp)
    80003c1a:	7ae2                	ld	s5,56(sp)
    80003c1c:	7b42                	ld	s6,48(sp)
    80003c1e:	7ba2                	ld	s7,40(sp)
    80003c20:	7c02                	ld	s8,32(sp)
    80003c22:	6ce2                	ld	s9,24(sp)
    80003c24:	6d42                	ld	s10,16(sp)
    80003c26:	6da2                	ld	s11,8(sp)
    80003c28:	6165                	addi	sp,sp,112
    80003c2a:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c2c:	89d6                	mv	s3,s5
    80003c2e:	bff1                	j	80003c0a <readi+0xce>
    return 0;
    80003c30:	4501                	li	a0,0
}
    80003c32:	8082                	ret

0000000080003c34 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c34:	457c                	lw	a5,76(a0)
    80003c36:	10d7e863          	bltu	a5,a3,80003d46 <writei+0x112>
{
    80003c3a:	7159                	addi	sp,sp,-112
    80003c3c:	f486                	sd	ra,104(sp)
    80003c3e:	f0a2                	sd	s0,96(sp)
    80003c40:	eca6                	sd	s1,88(sp)
    80003c42:	e8ca                	sd	s2,80(sp)
    80003c44:	e4ce                	sd	s3,72(sp)
    80003c46:	e0d2                	sd	s4,64(sp)
    80003c48:	fc56                	sd	s5,56(sp)
    80003c4a:	f85a                	sd	s6,48(sp)
    80003c4c:	f45e                	sd	s7,40(sp)
    80003c4e:	f062                	sd	s8,32(sp)
    80003c50:	ec66                	sd	s9,24(sp)
    80003c52:	e86a                	sd	s10,16(sp)
    80003c54:	e46e                	sd	s11,8(sp)
    80003c56:	1880                	addi	s0,sp,112
    80003c58:	8aaa                	mv	s5,a0
    80003c5a:	8bae                	mv	s7,a1
    80003c5c:	8a32                	mv	s4,a2
    80003c5e:	8936                	mv	s2,a3
    80003c60:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c62:	00e687bb          	addw	a5,a3,a4
    80003c66:	0ed7e263          	bltu	a5,a3,80003d4a <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003c6a:	00043737          	lui	a4,0x43
    80003c6e:	0ef76063          	bltu	a4,a5,80003d4e <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c72:	0c0b0863          	beqz	s6,80003d42 <writei+0x10e>
    80003c76:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c78:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003c7c:	5c7d                	li	s8,-1
    80003c7e:	a091                	j	80003cc2 <writei+0x8e>
    80003c80:	020d1d93          	slli	s11,s10,0x20
    80003c84:	020ddd93          	srli	s11,s11,0x20
    80003c88:	05848513          	addi	a0,s1,88
    80003c8c:	86ee                	mv	a3,s11
    80003c8e:	8652                	mv	a2,s4
    80003c90:	85de                	mv	a1,s7
    80003c92:	953a                	add	a0,a0,a4
    80003c94:	fffff097          	auipc	ra,0xfffff
    80003c98:	8d4080e7          	jalr	-1836(ra) # 80002568 <either_copyin>
    80003c9c:	07850263          	beq	a0,s8,80003d00 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003ca0:	8526                	mv	a0,s1
    80003ca2:	00000097          	auipc	ra,0x0
    80003ca6:	780080e7          	jalr	1920(ra) # 80004422 <log_write>
    brelse(bp);
    80003caa:	8526                	mv	a0,s1
    80003cac:	fffff097          	auipc	ra,0xfffff
    80003cb0:	4f2080e7          	jalr	1266(ra) # 8000319e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cb4:	013d09bb          	addw	s3,s10,s3
    80003cb8:	012d093b          	addw	s2,s10,s2
    80003cbc:	9a6e                	add	s4,s4,s11
    80003cbe:	0569f663          	bgeu	s3,s6,80003d0a <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003cc2:	00a9559b          	srliw	a1,s2,0xa
    80003cc6:	8556                	mv	a0,s5
    80003cc8:	fffff097          	auipc	ra,0xfffff
    80003ccc:	7a0080e7          	jalr	1952(ra) # 80003468 <bmap>
    80003cd0:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003cd4:	c99d                	beqz	a1,80003d0a <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003cd6:	000aa503          	lw	a0,0(s5)
    80003cda:	fffff097          	auipc	ra,0xfffff
    80003cde:	394080e7          	jalr	916(ra) # 8000306e <bread>
    80003ce2:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ce4:	3ff97713          	andi	a4,s2,1023
    80003ce8:	40ec87bb          	subw	a5,s9,a4
    80003cec:	413b06bb          	subw	a3,s6,s3
    80003cf0:	8d3e                	mv	s10,a5
    80003cf2:	2781                	sext.w	a5,a5
    80003cf4:	0006861b          	sext.w	a2,a3
    80003cf8:	f8f674e3          	bgeu	a2,a5,80003c80 <writei+0x4c>
    80003cfc:	8d36                	mv	s10,a3
    80003cfe:	b749                	j	80003c80 <writei+0x4c>
      brelse(bp);
    80003d00:	8526                	mv	a0,s1
    80003d02:	fffff097          	auipc	ra,0xfffff
    80003d06:	49c080e7          	jalr	1180(ra) # 8000319e <brelse>
  }

  if(off > ip->size)
    80003d0a:	04caa783          	lw	a5,76(s5)
    80003d0e:	0127f463          	bgeu	a5,s2,80003d16 <writei+0xe2>
    ip->size = off;
    80003d12:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003d16:	8556                	mv	a0,s5
    80003d18:	00000097          	auipc	ra,0x0
    80003d1c:	aa6080e7          	jalr	-1370(ra) # 800037be <iupdate>

  return tot;
    80003d20:	0009851b          	sext.w	a0,s3
}
    80003d24:	70a6                	ld	ra,104(sp)
    80003d26:	7406                	ld	s0,96(sp)
    80003d28:	64e6                	ld	s1,88(sp)
    80003d2a:	6946                	ld	s2,80(sp)
    80003d2c:	69a6                	ld	s3,72(sp)
    80003d2e:	6a06                	ld	s4,64(sp)
    80003d30:	7ae2                	ld	s5,56(sp)
    80003d32:	7b42                	ld	s6,48(sp)
    80003d34:	7ba2                	ld	s7,40(sp)
    80003d36:	7c02                	ld	s8,32(sp)
    80003d38:	6ce2                	ld	s9,24(sp)
    80003d3a:	6d42                	ld	s10,16(sp)
    80003d3c:	6da2                	ld	s11,8(sp)
    80003d3e:	6165                	addi	sp,sp,112
    80003d40:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d42:	89da                	mv	s3,s6
    80003d44:	bfc9                	j	80003d16 <writei+0xe2>
    return -1;
    80003d46:	557d                	li	a0,-1
}
    80003d48:	8082                	ret
    return -1;
    80003d4a:	557d                	li	a0,-1
    80003d4c:	bfe1                	j	80003d24 <writei+0xf0>
    return -1;
    80003d4e:	557d                	li	a0,-1
    80003d50:	bfd1                	j	80003d24 <writei+0xf0>

0000000080003d52 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003d52:	1141                	addi	sp,sp,-16
    80003d54:	e406                	sd	ra,8(sp)
    80003d56:	e022                	sd	s0,0(sp)
    80003d58:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003d5a:	4639                	li	a2,14
    80003d5c:	ffffd097          	auipc	ra,0xffffd
    80003d60:	062080e7          	jalr	98(ra) # 80000dbe <strncmp>
}
    80003d64:	60a2                	ld	ra,8(sp)
    80003d66:	6402                	ld	s0,0(sp)
    80003d68:	0141                	addi	sp,sp,16
    80003d6a:	8082                	ret

0000000080003d6c <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003d6c:	7139                	addi	sp,sp,-64
    80003d6e:	fc06                	sd	ra,56(sp)
    80003d70:	f822                	sd	s0,48(sp)
    80003d72:	f426                	sd	s1,40(sp)
    80003d74:	f04a                	sd	s2,32(sp)
    80003d76:	ec4e                	sd	s3,24(sp)
    80003d78:	e852                	sd	s4,16(sp)
    80003d7a:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003d7c:	04451703          	lh	a4,68(a0)
    80003d80:	4785                	li	a5,1
    80003d82:	00f71a63          	bne	a4,a5,80003d96 <dirlookup+0x2a>
    80003d86:	892a                	mv	s2,a0
    80003d88:	89ae                	mv	s3,a1
    80003d8a:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d8c:	457c                	lw	a5,76(a0)
    80003d8e:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003d90:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d92:	e79d                	bnez	a5,80003dc0 <dirlookup+0x54>
    80003d94:	a8a5                	j	80003e0c <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003d96:	00005517          	auipc	a0,0x5
    80003d9a:	a5a50513          	addi	a0,a0,-1446 # 800087f0 <syscalls+0x1d0>
    80003d9e:	ffffc097          	auipc	ra,0xffffc
    80003da2:	7a6080e7          	jalr	1958(ra) # 80000544 <panic>
      panic("dirlookup read");
    80003da6:	00005517          	auipc	a0,0x5
    80003daa:	a6250513          	addi	a0,a0,-1438 # 80008808 <syscalls+0x1e8>
    80003dae:	ffffc097          	auipc	ra,0xffffc
    80003db2:	796080e7          	jalr	1942(ra) # 80000544 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003db6:	24c1                	addiw	s1,s1,16
    80003db8:	04c92783          	lw	a5,76(s2)
    80003dbc:	04f4f763          	bgeu	s1,a5,80003e0a <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003dc0:	4741                	li	a4,16
    80003dc2:	86a6                	mv	a3,s1
    80003dc4:	fc040613          	addi	a2,s0,-64
    80003dc8:	4581                	li	a1,0
    80003dca:	854a                	mv	a0,s2
    80003dcc:	00000097          	auipc	ra,0x0
    80003dd0:	d70080e7          	jalr	-656(ra) # 80003b3c <readi>
    80003dd4:	47c1                	li	a5,16
    80003dd6:	fcf518e3          	bne	a0,a5,80003da6 <dirlookup+0x3a>
    if(de.inum == 0)
    80003dda:	fc045783          	lhu	a5,-64(s0)
    80003dde:	dfe1                	beqz	a5,80003db6 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003de0:	fc240593          	addi	a1,s0,-62
    80003de4:	854e                	mv	a0,s3
    80003de6:	00000097          	auipc	ra,0x0
    80003dea:	f6c080e7          	jalr	-148(ra) # 80003d52 <namecmp>
    80003dee:	f561                	bnez	a0,80003db6 <dirlookup+0x4a>
      if(poff)
    80003df0:	000a0463          	beqz	s4,80003df8 <dirlookup+0x8c>
        *poff = off;
    80003df4:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003df8:	fc045583          	lhu	a1,-64(s0)
    80003dfc:	00092503          	lw	a0,0(s2)
    80003e00:	fffff097          	auipc	ra,0xfffff
    80003e04:	750080e7          	jalr	1872(ra) # 80003550 <iget>
    80003e08:	a011                	j	80003e0c <dirlookup+0xa0>
  return 0;
    80003e0a:	4501                	li	a0,0
}
    80003e0c:	70e2                	ld	ra,56(sp)
    80003e0e:	7442                	ld	s0,48(sp)
    80003e10:	74a2                	ld	s1,40(sp)
    80003e12:	7902                	ld	s2,32(sp)
    80003e14:	69e2                	ld	s3,24(sp)
    80003e16:	6a42                	ld	s4,16(sp)
    80003e18:	6121                	addi	sp,sp,64
    80003e1a:	8082                	ret

0000000080003e1c <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003e1c:	711d                	addi	sp,sp,-96
    80003e1e:	ec86                	sd	ra,88(sp)
    80003e20:	e8a2                	sd	s0,80(sp)
    80003e22:	e4a6                	sd	s1,72(sp)
    80003e24:	e0ca                	sd	s2,64(sp)
    80003e26:	fc4e                	sd	s3,56(sp)
    80003e28:	f852                	sd	s4,48(sp)
    80003e2a:	f456                	sd	s5,40(sp)
    80003e2c:	f05a                	sd	s6,32(sp)
    80003e2e:	ec5e                	sd	s7,24(sp)
    80003e30:	e862                	sd	s8,16(sp)
    80003e32:	e466                	sd	s9,8(sp)
    80003e34:	1080                	addi	s0,sp,96
    80003e36:	84aa                	mv	s1,a0
    80003e38:	8b2e                	mv	s6,a1
    80003e3a:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003e3c:	00054703          	lbu	a4,0(a0)
    80003e40:	02f00793          	li	a5,47
    80003e44:	02f70363          	beq	a4,a5,80003e6a <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003e48:	ffffe097          	auipc	ra,0xffffe
    80003e4c:	b7e080e7          	jalr	-1154(ra) # 800019c6 <myproc>
    80003e50:	15053503          	ld	a0,336(a0)
    80003e54:	00000097          	auipc	ra,0x0
    80003e58:	9f6080e7          	jalr	-1546(ra) # 8000384a <idup>
    80003e5c:	89aa                	mv	s3,a0
  while(*path == '/')
    80003e5e:	02f00913          	li	s2,47
  len = path - s;
    80003e62:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003e64:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003e66:	4c05                	li	s8,1
    80003e68:	a865                	j	80003f20 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003e6a:	4585                	li	a1,1
    80003e6c:	4505                	li	a0,1
    80003e6e:	fffff097          	auipc	ra,0xfffff
    80003e72:	6e2080e7          	jalr	1762(ra) # 80003550 <iget>
    80003e76:	89aa                	mv	s3,a0
    80003e78:	b7dd                	j	80003e5e <namex+0x42>
      iunlockput(ip);
    80003e7a:	854e                	mv	a0,s3
    80003e7c:	00000097          	auipc	ra,0x0
    80003e80:	c6e080e7          	jalr	-914(ra) # 80003aea <iunlockput>
      return 0;
    80003e84:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003e86:	854e                	mv	a0,s3
    80003e88:	60e6                	ld	ra,88(sp)
    80003e8a:	6446                	ld	s0,80(sp)
    80003e8c:	64a6                	ld	s1,72(sp)
    80003e8e:	6906                	ld	s2,64(sp)
    80003e90:	79e2                	ld	s3,56(sp)
    80003e92:	7a42                	ld	s4,48(sp)
    80003e94:	7aa2                	ld	s5,40(sp)
    80003e96:	7b02                	ld	s6,32(sp)
    80003e98:	6be2                	ld	s7,24(sp)
    80003e9a:	6c42                	ld	s8,16(sp)
    80003e9c:	6ca2                	ld	s9,8(sp)
    80003e9e:	6125                	addi	sp,sp,96
    80003ea0:	8082                	ret
      iunlock(ip);
    80003ea2:	854e                	mv	a0,s3
    80003ea4:	00000097          	auipc	ra,0x0
    80003ea8:	aa6080e7          	jalr	-1370(ra) # 8000394a <iunlock>
      return ip;
    80003eac:	bfe9                	j	80003e86 <namex+0x6a>
      iunlockput(ip);
    80003eae:	854e                	mv	a0,s3
    80003eb0:	00000097          	auipc	ra,0x0
    80003eb4:	c3a080e7          	jalr	-966(ra) # 80003aea <iunlockput>
      return 0;
    80003eb8:	89d2                	mv	s3,s4
    80003eba:	b7f1                	j	80003e86 <namex+0x6a>
  len = path - s;
    80003ebc:	40b48633          	sub	a2,s1,a1
    80003ec0:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003ec4:	094cd463          	bge	s9,s4,80003f4c <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003ec8:	4639                	li	a2,14
    80003eca:	8556                	mv	a0,s5
    80003ecc:	ffffd097          	auipc	ra,0xffffd
    80003ed0:	e7a080e7          	jalr	-390(ra) # 80000d46 <memmove>
  while(*path == '/')
    80003ed4:	0004c783          	lbu	a5,0(s1)
    80003ed8:	01279763          	bne	a5,s2,80003ee6 <namex+0xca>
    path++;
    80003edc:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003ede:	0004c783          	lbu	a5,0(s1)
    80003ee2:	ff278de3          	beq	a5,s2,80003edc <namex+0xc0>
    ilock(ip);
    80003ee6:	854e                	mv	a0,s3
    80003ee8:	00000097          	auipc	ra,0x0
    80003eec:	9a0080e7          	jalr	-1632(ra) # 80003888 <ilock>
    if(ip->type != T_DIR){
    80003ef0:	04499783          	lh	a5,68(s3)
    80003ef4:	f98793e3          	bne	a5,s8,80003e7a <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003ef8:	000b0563          	beqz	s6,80003f02 <namex+0xe6>
    80003efc:	0004c783          	lbu	a5,0(s1)
    80003f00:	d3cd                	beqz	a5,80003ea2 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003f02:	865e                	mv	a2,s7
    80003f04:	85d6                	mv	a1,s5
    80003f06:	854e                	mv	a0,s3
    80003f08:	00000097          	auipc	ra,0x0
    80003f0c:	e64080e7          	jalr	-412(ra) # 80003d6c <dirlookup>
    80003f10:	8a2a                	mv	s4,a0
    80003f12:	dd51                	beqz	a0,80003eae <namex+0x92>
    iunlockput(ip);
    80003f14:	854e                	mv	a0,s3
    80003f16:	00000097          	auipc	ra,0x0
    80003f1a:	bd4080e7          	jalr	-1068(ra) # 80003aea <iunlockput>
    ip = next;
    80003f1e:	89d2                	mv	s3,s4
  while(*path == '/')
    80003f20:	0004c783          	lbu	a5,0(s1)
    80003f24:	05279763          	bne	a5,s2,80003f72 <namex+0x156>
    path++;
    80003f28:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f2a:	0004c783          	lbu	a5,0(s1)
    80003f2e:	ff278de3          	beq	a5,s2,80003f28 <namex+0x10c>
  if(*path == 0)
    80003f32:	c79d                	beqz	a5,80003f60 <namex+0x144>
    path++;
    80003f34:	85a6                	mv	a1,s1
  len = path - s;
    80003f36:	8a5e                	mv	s4,s7
    80003f38:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003f3a:	01278963          	beq	a5,s2,80003f4c <namex+0x130>
    80003f3e:	dfbd                	beqz	a5,80003ebc <namex+0xa0>
    path++;
    80003f40:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003f42:	0004c783          	lbu	a5,0(s1)
    80003f46:	ff279ce3          	bne	a5,s2,80003f3e <namex+0x122>
    80003f4a:	bf8d                	j	80003ebc <namex+0xa0>
    memmove(name, s, len);
    80003f4c:	2601                	sext.w	a2,a2
    80003f4e:	8556                	mv	a0,s5
    80003f50:	ffffd097          	auipc	ra,0xffffd
    80003f54:	df6080e7          	jalr	-522(ra) # 80000d46 <memmove>
    name[len] = 0;
    80003f58:	9a56                	add	s4,s4,s5
    80003f5a:	000a0023          	sb	zero,0(s4)
    80003f5e:	bf9d                	j	80003ed4 <namex+0xb8>
  if(nameiparent){
    80003f60:	f20b03e3          	beqz	s6,80003e86 <namex+0x6a>
    iput(ip);
    80003f64:	854e                	mv	a0,s3
    80003f66:	00000097          	auipc	ra,0x0
    80003f6a:	adc080e7          	jalr	-1316(ra) # 80003a42 <iput>
    return 0;
    80003f6e:	4981                	li	s3,0
    80003f70:	bf19                	j	80003e86 <namex+0x6a>
  if(*path == 0)
    80003f72:	d7fd                	beqz	a5,80003f60 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003f74:	0004c783          	lbu	a5,0(s1)
    80003f78:	85a6                	mv	a1,s1
    80003f7a:	b7d1                	j	80003f3e <namex+0x122>

0000000080003f7c <dirlink>:
{
    80003f7c:	7139                	addi	sp,sp,-64
    80003f7e:	fc06                	sd	ra,56(sp)
    80003f80:	f822                	sd	s0,48(sp)
    80003f82:	f426                	sd	s1,40(sp)
    80003f84:	f04a                	sd	s2,32(sp)
    80003f86:	ec4e                	sd	s3,24(sp)
    80003f88:	e852                	sd	s4,16(sp)
    80003f8a:	0080                	addi	s0,sp,64
    80003f8c:	892a                	mv	s2,a0
    80003f8e:	8a2e                	mv	s4,a1
    80003f90:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003f92:	4601                	li	a2,0
    80003f94:	00000097          	auipc	ra,0x0
    80003f98:	dd8080e7          	jalr	-552(ra) # 80003d6c <dirlookup>
    80003f9c:	e93d                	bnez	a0,80004012 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f9e:	04c92483          	lw	s1,76(s2)
    80003fa2:	c49d                	beqz	s1,80003fd0 <dirlink+0x54>
    80003fa4:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fa6:	4741                	li	a4,16
    80003fa8:	86a6                	mv	a3,s1
    80003faa:	fc040613          	addi	a2,s0,-64
    80003fae:	4581                	li	a1,0
    80003fb0:	854a                	mv	a0,s2
    80003fb2:	00000097          	auipc	ra,0x0
    80003fb6:	b8a080e7          	jalr	-1142(ra) # 80003b3c <readi>
    80003fba:	47c1                	li	a5,16
    80003fbc:	06f51163          	bne	a0,a5,8000401e <dirlink+0xa2>
    if(de.inum == 0)
    80003fc0:	fc045783          	lhu	a5,-64(s0)
    80003fc4:	c791                	beqz	a5,80003fd0 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fc6:	24c1                	addiw	s1,s1,16
    80003fc8:	04c92783          	lw	a5,76(s2)
    80003fcc:	fcf4ede3          	bltu	s1,a5,80003fa6 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003fd0:	4639                	li	a2,14
    80003fd2:	85d2                	mv	a1,s4
    80003fd4:	fc240513          	addi	a0,s0,-62
    80003fd8:	ffffd097          	auipc	ra,0xffffd
    80003fdc:	e22080e7          	jalr	-478(ra) # 80000dfa <strncpy>
  de.inum = inum;
    80003fe0:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fe4:	4741                	li	a4,16
    80003fe6:	86a6                	mv	a3,s1
    80003fe8:	fc040613          	addi	a2,s0,-64
    80003fec:	4581                	li	a1,0
    80003fee:	854a                	mv	a0,s2
    80003ff0:	00000097          	auipc	ra,0x0
    80003ff4:	c44080e7          	jalr	-956(ra) # 80003c34 <writei>
    80003ff8:	1541                	addi	a0,a0,-16
    80003ffa:	00a03533          	snez	a0,a0
    80003ffe:	40a00533          	neg	a0,a0
}
    80004002:	70e2                	ld	ra,56(sp)
    80004004:	7442                	ld	s0,48(sp)
    80004006:	74a2                	ld	s1,40(sp)
    80004008:	7902                	ld	s2,32(sp)
    8000400a:	69e2                	ld	s3,24(sp)
    8000400c:	6a42                	ld	s4,16(sp)
    8000400e:	6121                	addi	sp,sp,64
    80004010:	8082                	ret
    iput(ip);
    80004012:	00000097          	auipc	ra,0x0
    80004016:	a30080e7          	jalr	-1488(ra) # 80003a42 <iput>
    return -1;
    8000401a:	557d                	li	a0,-1
    8000401c:	b7dd                	j	80004002 <dirlink+0x86>
      panic("dirlink read");
    8000401e:	00004517          	auipc	a0,0x4
    80004022:	7fa50513          	addi	a0,a0,2042 # 80008818 <syscalls+0x1f8>
    80004026:	ffffc097          	auipc	ra,0xffffc
    8000402a:	51e080e7          	jalr	1310(ra) # 80000544 <panic>

000000008000402e <namei>:

struct inode*
namei(char *path)
{
    8000402e:	1101                	addi	sp,sp,-32
    80004030:	ec06                	sd	ra,24(sp)
    80004032:	e822                	sd	s0,16(sp)
    80004034:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004036:	fe040613          	addi	a2,s0,-32
    8000403a:	4581                	li	a1,0
    8000403c:	00000097          	auipc	ra,0x0
    80004040:	de0080e7          	jalr	-544(ra) # 80003e1c <namex>
}
    80004044:	60e2                	ld	ra,24(sp)
    80004046:	6442                	ld	s0,16(sp)
    80004048:	6105                	addi	sp,sp,32
    8000404a:	8082                	ret

000000008000404c <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000404c:	1141                	addi	sp,sp,-16
    8000404e:	e406                	sd	ra,8(sp)
    80004050:	e022                	sd	s0,0(sp)
    80004052:	0800                	addi	s0,sp,16
    80004054:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004056:	4585                	li	a1,1
    80004058:	00000097          	auipc	ra,0x0
    8000405c:	dc4080e7          	jalr	-572(ra) # 80003e1c <namex>
}
    80004060:	60a2                	ld	ra,8(sp)
    80004062:	6402                	ld	s0,0(sp)
    80004064:	0141                	addi	sp,sp,16
    80004066:	8082                	ret

0000000080004068 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004068:	1101                	addi	sp,sp,-32
    8000406a:	ec06                	sd	ra,24(sp)
    8000406c:	e822                	sd	s0,16(sp)
    8000406e:	e426                	sd	s1,8(sp)
    80004070:	e04a                	sd	s2,0(sp)
    80004072:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004074:	00025917          	auipc	s2,0x25
    80004078:	fe490913          	addi	s2,s2,-28 # 80029058 <log>
    8000407c:	01892583          	lw	a1,24(s2)
    80004080:	02892503          	lw	a0,40(s2)
    80004084:	fffff097          	auipc	ra,0xfffff
    80004088:	fea080e7          	jalr	-22(ra) # 8000306e <bread>
    8000408c:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    8000408e:	02c92683          	lw	a3,44(s2)
    80004092:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004094:	02d05763          	blez	a3,800040c2 <write_head+0x5a>
    80004098:	00025797          	auipc	a5,0x25
    8000409c:	ff078793          	addi	a5,a5,-16 # 80029088 <log+0x30>
    800040a0:	05c50713          	addi	a4,a0,92
    800040a4:	36fd                	addiw	a3,a3,-1
    800040a6:	1682                	slli	a3,a3,0x20
    800040a8:	9281                	srli	a3,a3,0x20
    800040aa:	068a                	slli	a3,a3,0x2
    800040ac:	00025617          	auipc	a2,0x25
    800040b0:	fe060613          	addi	a2,a2,-32 # 8002908c <log+0x34>
    800040b4:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800040b6:	4390                	lw	a2,0(a5)
    800040b8:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800040ba:	0791                	addi	a5,a5,4
    800040bc:	0711                	addi	a4,a4,4
    800040be:	fed79ce3          	bne	a5,a3,800040b6 <write_head+0x4e>
  }
  bwrite(buf);
    800040c2:	8526                	mv	a0,s1
    800040c4:	fffff097          	auipc	ra,0xfffff
    800040c8:	09c080e7          	jalr	156(ra) # 80003160 <bwrite>
  brelse(buf);
    800040cc:	8526                	mv	a0,s1
    800040ce:	fffff097          	auipc	ra,0xfffff
    800040d2:	0d0080e7          	jalr	208(ra) # 8000319e <brelse>
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
    80004116:	a035                	j	80004142 <install_trans+0x60>
      bunpin(dbuf);
    80004118:	8526                	mv	a0,s1
    8000411a:	fffff097          	auipc	ra,0xfffff
    8000411e:	15e080e7          	jalr	350(ra) # 80003278 <bunpin>
    brelse(lbuf);
    80004122:	854a                	mv	a0,s2
    80004124:	fffff097          	auipc	ra,0xfffff
    80004128:	07a080e7          	jalr	122(ra) # 8000319e <brelse>
    brelse(dbuf);
    8000412c:	8526                	mv	a0,s1
    8000412e:	fffff097          	auipc	ra,0xfffff
    80004132:	070080e7          	jalr	112(ra) # 8000319e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004136:	2a05                	addiw	s4,s4,1
    80004138:	0a91                	addi	s5,s5,4
    8000413a:	02c9a783          	lw	a5,44(s3)
    8000413e:	04fa5963          	bge	s4,a5,80004190 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004142:	0189a583          	lw	a1,24(s3)
    80004146:	014585bb          	addw	a1,a1,s4
    8000414a:	2585                	addiw	a1,a1,1
    8000414c:	0289a503          	lw	a0,40(s3)
    80004150:	fffff097          	auipc	ra,0xfffff
    80004154:	f1e080e7          	jalr	-226(ra) # 8000306e <bread>
    80004158:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000415a:	000aa583          	lw	a1,0(s5)
    8000415e:	0289a503          	lw	a0,40(s3)
    80004162:	fffff097          	auipc	ra,0xfffff
    80004166:	f0c080e7          	jalr	-244(ra) # 8000306e <bread>
    8000416a:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000416c:	40000613          	li	a2,1024
    80004170:	05890593          	addi	a1,s2,88
    80004174:	05850513          	addi	a0,a0,88
    80004178:	ffffd097          	auipc	ra,0xffffd
    8000417c:	bce080e7          	jalr	-1074(ra) # 80000d46 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004180:	8526                	mv	a0,s1
    80004182:	fffff097          	auipc	ra,0xfffff
    80004186:	fde080e7          	jalr	-34(ra) # 80003160 <bwrite>
    if(recovering == 0)
    8000418a:	f80b1ce3          	bnez	s6,80004122 <install_trans+0x40>
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
    800041ce:	990080e7          	jalr	-1648(ra) # 80000b5a <initlock>
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
    800041e8:	e8a080e7          	jalr	-374(ra) # 8000306e <bread>
  log.lh.n = lh->n;
    800041ec:	4d3c                	lw	a5,88(a0)
    800041ee:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800041f0:	02f05563          	blez	a5,8000421a <initlog+0x74>
    800041f4:	05c50713          	addi	a4,a0,92
    800041f8:	00025697          	auipc	a3,0x25
    800041fc:	e9068693          	addi	a3,a3,-368 # 80029088 <log+0x30>
    80004200:	37fd                	addiw	a5,a5,-1
    80004202:	1782                	slli	a5,a5,0x20
    80004204:	9381                	srli	a5,a5,0x20
    80004206:	078a                	slli	a5,a5,0x2
    80004208:	06050613          	addi	a2,a0,96
    8000420c:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000420e:	4310                	lw	a2,0(a4)
    80004210:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004212:	0711                	addi	a4,a4,4
    80004214:	0691                	addi	a3,a3,4
    80004216:	fef71ce3          	bne	a4,a5,8000420e <initlog+0x68>
  brelse(buf);
    8000421a:	fffff097          	auipc	ra,0xfffff
    8000421e:	f84080e7          	jalr	-124(ra) # 8000319e <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004222:	4505                	li	a0,1
    80004224:	00000097          	auipc	ra,0x0
    80004228:	ebe080e7          	jalr	-322(ra) # 800040e2 <install_trans>
  log.lh.n = 0;
    8000422c:	00025797          	auipc	a5,0x25
    80004230:	e407ac23          	sw	zero,-424(a5) # 80029084 <log+0x2c>
  write_head(); // clear the log
    80004234:	00000097          	auipc	ra,0x0
    80004238:	e34080e7          	jalr	-460(ra) # 80004068 <write_head>
}
    8000423c:	70a2                	ld	ra,40(sp)
    8000423e:	7402                	ld	s0,32(sp)
    80004240:	64e2                	ld	s1,24(sp)
    80004242:	6942                	ld	s2,16(sp)
    80004244:	69a2                	ld	s3,8(sp)
    80004246:	6145                	addi	sp,sp,48
    80004248:	8082                	ret

000000008000424a <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000424a:	1101                	addi	sp,sp,-32
    8000424c:	ec06                	sd	ra,24(sp)
    8000424e:	e822                	sd	s0,16(sp)
    80004250:	e426                	sd	s1,8(sp)
    80004252:	e04a                	sd	s2,0(sp)
    80004254:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004256:	00025517          	auipc	a0,0x25
    8000425a:	e0250513          	addi	a0,a0,-510 # 80029058 <log>
    8000425e:	ffffd097          	auipc	ra,0xffffd
    80004262:	98c080e7          	jalr	-1652(ra) # 80000bea <acquire>
  while(1){
    if(log.committing){
    80004266:	00025497          	auipc	s1,0x25
    8000426a:	df248493          	addi	s1,s1,-526 # 80029058 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000426e:	4979                	li	s2,30
    80004270:	a039                	j	8000427e <begin_op+0x34>
      sleep(&log, &log.lock);
    80004272:	85a6                	mv	a1,s1
    80004274:	8526                	mv	a0,s1
    80004276:	ffffe097          	auipc	ra,0xffffe
    8000427a:	e94080e7          	jalr	-364(ra) # 8000210a <sleep>
    if(log.committing){
    8000427e:	50dc                	lw	a5,36(s1)
    80004280:	fbed                	bnez	a5,80004272 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004282:	509c                	lw	a5,32(s1)
    80004284:	0017871b          	addiw	a4,a5,1
    80004288:	0007069b          	sext.w	a3,a4
    8000428c:	0027179b          	slliw	a5,a4,0x2
    80004290:	9fb9                	addw	a5,a5,a4
    80004292:	0017979b          	slliw	a5,a5,0x1
    80004296:	54d8                	lw	a4,44(s1)
    80004298:	9fb9                	addw	a5,a5,a4
    8000429a:	00f95963          	bge	s2,a5,800042ac <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000429e:	85a6                	mv	a1,s1
    800042a0:	8526                	mv	a0,s1
    800042a2:	ffffe097          	auipc	ra,0xffffe
    800042a6:	e68080e7          	jalr	-408(ra) # 8000210a <sleep>
    800042aa:	bfd1                	j	8000427e <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800042ac:	00025517          	auipc	a0,0x25
    800042b0:	dac50513          	addi	a0,a0,-596 # 80029058 <log>
    800042b4:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800042b6:	ffffd097          	auipc	ra,0xffffd
    800042ba:	9e8080e7          	jalr	-1560(ra) # 80000c9e <release>
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
    800042ea:	904080e7          	jalr	-1788(ra) # 80000bea <acquire>
  log.outstanding -= 1;
    800042ee:	509c                	lw	a5,32(s1)
    800042f0:	37fd                	addiw	a5,a5,-1
    800042f2:	0007891b          	sext.w	s2,a5
    800042f6:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800042f8:	50dc                	lw	a5,36(s1)
    800042fa:	efb9                	bnez	a5,80004358 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800042fc:	06091663          	bnez	s2,80004368 <end_op+0x9e>
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
    80004312:	990080e7          	jalr	-1648(ra) # 80000c9e <release>
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
    8000432a:	8c4080e7          	jalr	-1852(ra) # 80000bea <acquire>
    log.committing = 0;
    8000432e:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004332:	8526                	mv	a0,s1
    80004334:	ffffe097          	auipc	ra,0xffffe
    80004338:	e3a080e7          	jalr	-454(ra) # 8000216e <wakeup>
    release(&log.lock);
    8000433c:	8526                	mv	a0,s1
    8000433e:	ffffd097          	auipc	ra,0xffffd
    80004342:	960080e7          	jalr	-1696(ra) # 80000c9e <release>
}
    80004346:	70e2                	ld	ra,56(sp)
    80004348:	7442                	ld	s0,48(sp)
    8000434a:	74a2                	ld	s1,40(sp)
    8000434c:	7902                	ld	s2,32(sp)
    8000434e:	69e2                	ld	s3,24(sp)
    80004350:	6a42                	ld	s4,16(sp)
    80004352:	6aa2                	ld	s5,8(sp)
    80004354:	6121                	addi	sp,sp,64
    80004356:	8082                	ret
    panic("log.committing");
    80004358:	00004517          	auipc	a0,0x4
    8000435c:	4d850513          	addi	a0,a0,1240 # 80008830 <syscalls+0x210>
    80004360:	ffffc097          	auipc	ra,0xffffc
    80004364:	1e4080e7          	jalr	484(ra) # 80000544 <panic>
    wakeup(&log);
    80004368:	00025497          	auipc	s1,0x25
    8000436c:	cf048493          	addi	s1,s1,-784 # 80029058 <log>
    80004370:	8526                	mv	a0,s1
    80004372:	ffffe097          	auipc	ra,0xffffe
    80004376:	dfc080e7          	jalr	-516(ra) # 8000216e <wakeup>
  release(&log.lock);
    8000437a:	8526                	mv	a0,s1
    8000437c:	ffffd097          	auipc	ra,0xffffd
    80004380:	922080e7          	jalr	-1758(ra) # 80000c9e <release>
  if(do_commit){
    80004384:	b7c9                	j	80004346 <end_op+0x7c>
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
    800043a8:	cca080e7          	jalr	-822(ra) # 8000306e <bread>
    800043ac:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800043ae:	000aa583          	lw	a1,0(s5)
    800043b2:	028a2503          	lw	a0,40(s4)
    800043b6:	fffff097          	auipc	ra,0xfffff
    800043ba:	cb8080e7          	jalr	-840(ra) # 8000306e <bread>
    800043be:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800043c0:	40000613          	li	a2,1024
    800043c4:	05850593          	addi	a1,a0,88
    800043c8:	05848513          	addi	a0,s1,88
    800043cc:	ffffd097          	auipc	ra,0xffffd
    800043d0:	97a080e7          	jalr	-1670(ra) # 80000d46 <memmove>
    bwrite(to);  // write the log
    800043d4:	8526                	mv	a0,s1
    800043d6:	fffff097          	auipc	ra,0xfffff
    800043da:	d8a080e7          	jalr	-630(ra) # 80003160 <bwrite>
    brelse(from);
    800043de:	854e                	mv	a0,s3
    800043e0:	fffff097          	auipc	ra,0xfffff
    800043e4:	dbe080e7          	jalr	-578(ra) # 8000319e <brelse>
    brelse(to);
    800043e8:	8526                	mv	a0,s1
    800043ea:	fffff097          	auipc	ra,0xfffff
    800043ee:	db4080e7          	jalr	-588(ra) # 8000319e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043f2:	2905                	addiw	s2,s2,1
    800043f4:	0a91                	addi	s5,s5,4
    800043f6:	02ca2783          	lw	a5,44(s4)
    800043fa:	f8f94ee3          	blt	s2,a5,80004396 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800043fe:	00000097          	auipc	ra,0x0
    80004402:	c6a080e7          	jalr	-918(ra) # 80004068 <write_head>
    install_trans(0); // Now install writes to home locations
    80004406:	4501                	li	a0,0
    80004408:	00000097          	auipc	ra,0x0
    8000440c:	cda080e7          	jalr	-806(ra) # 800040e2 <install_trans>
    log.lh.n = 0;
    80004410:	00025797          	auipc	a5,0x25
    80004414:	c607aa23          	sw	zero,-908(a5) # 80029084 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004418:	00000097          	auipc	ra,0x0
    8000441c:	c50080e7          	jalr	-944(ra) # 80004068 <write_head>
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
    8000443e:	7b0080e7          	jalr	1968(ra) # 80000bea <acquire>
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
    80004492:	963e                	add	a2,a2,a5
    80004494:	44dc                	lw	a5,12(s1)
    80004496:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004498:	8526                	mv	a0,s1
    8000449a:	fffff097          	auipc	ra,0xfffff
    8000449e:	da2080e7          	jalr	-606(ra) # 8000323c <bpin>
    log.lh.n++;
    800044a2:	00025717          	auipc	a4,0x25
    800044a6:	bb670713          	addi	a4,a4,-1098 # 80029058 <log>
    800044aa:	575c                	lw	a5,44(a4)
    800044ac:	2785                	addiw	a5,a5,1
    800044ae:	d75c                	sw	a5,44(a4)
    800044b0:	a835                	j	800044ec <log_write+0xca>
    panic("too big a transaction");
    800044b2:	00004517          	auipc	a0,0x4
    800044b6:	38e50513          	addi	a0,a0,910 # 80008840 <syscalls+0x220>
    800044ba:	ffffc097          	auipc	ra,0xffffc
    800044be:	08a080e7          	jalr	138(ra) # 80000544 <panic>
    panic("log_write outside of trans");
    800044c2:	00004517          	auipc	a0,0x4
    800044c6:	39650513          	addi	a0,a0,918 # 80008858 <syscalls+0x238>
    800044ca:	ffffc097          	auipc	ra,0xffffc
    800044ce:	07a080e7          	jalr	122(ra) # 80000544 <panic>
  log.lh.block[i] = b->blockno;
    800044d2:	00878713          	addi	a4,a5,8
    800044d6:	00271693          	slli	a3,a4,0x2
    800044da:	00025717          	auipc	a4,0x25
    800044de:	b7e70713          	addi	a4,a4,-1154 # 80029058 <log>
    800044e2:	9736                	add	a4,a4,a3
    800044e4:	44d4                	lw	a3,12(s1)
    800044e6:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800044e8:	faf608e3          	beq	a2,a5,80004498 <log_write+0x76>
  }
  release(&log.lock);
    800044ec:	00025517          	auipc	a0,0x25
    800044f0:	b6c50513          	addi	a0,a0,-1172 # 80029058 <log>
    800044f4:	ffffc097          	auipc	ra,0xffffc
    800044f8:	7aa080e7          	jalr	1962(ra) # 80000c9e <release>
}
    800044fc:	60e2                	ld	ra,24(sp)
    800044fe:	6442                	ld	s0,16(sp)
    80004500:	64a2                	ld	s1,8(sp)
    80004502:	6902                	ld	s2,0(sp)
    80004504:	6105                	addi	sp,sp,32
    80004506:	8082                	ret

0000000080004508 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004508:	1101                	addi	sp,sp,-32
    8000450a:	ec06                	sd	ra,24(sp)
    8000450c:	e822                	sd	s0,16(sp)
    8000450e:	e426                	sd	s1,8(sp)
    80004510:	e04a                	sd	s2,0(sp)
    80004512:	1000                	addi	s0,sp,32
    80004514:	84aa                	mv	s1,a0
    80004516:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004518:	00004597          	auipc	a1,0x4
    8000451c:	36058593          	addi	a1,a1,864 # 80008878 <syscalls+0x258>
    80004520:	0521                	addi	a0,a0,8
    80004522:	ffffc097          	auipc	ra,0xffffc
    80004526:	638080e7          	jalr	1592(ra) # 80000b5a <initlock>
  lk->name = name;
    8000452a:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000452e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004532:	0204a423          	sw	zero,40(s1)
}
    80004536:	60e2                	ld	ra,24(sp)
    80004538:	6442                	ld	s0,16(sp)
    8000453a:	64a2                	ld	s1,8(sp)
    8000453c:	6902                	ld	s2,0(sp)
    8000453e:	6105                	addi	sp,sp,32
    80004540:	8082                	ret

0000000080004542 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004542:	1101                	addi	sp,sp,-32
    80004544:	ec06                	sd	ra,24(sp)
    80004546:	e822                	sd	s0,16(sp)
    80004548:	e426                	sd	s1,8(sp)
    8000454a:	e04a                	sd	s2,0(sp)
    8000454c:	1000                	addi	s0,sp,32
    8000454e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004550:	00850913          	addi	s2,a0,8
    80004554:	854a                	mv	a0,s2
    80004556:	ffffc097          	auipc	ra,0xffffc
    8000455a:	694080e7          	jalr	1684(ra) # 80000bea <acquire>
  while (lk->locked) {
    8000455e:	409c                	lw	a5,0(s1)
    80004560:	cb89                	beqz	a5,80004572 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004562:	85ca                	mv	a1,s2
    80004564:	8526                	mv	a0,s1
    80004566:	ffffe097          	auipc	ra,0xffffe
    8000456a:	ba4080e7          	jalr	-1116(ra) # 8000210a <sleep>
  while (lk->locked) {
    8000456e:	409c                	lw	a5,0(s1)
    80004570:	fbed                	bnez	a5,80004562 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004572:	4785                	li	a5,1
    80004574:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004576:	ffffd097          	auipc	ra,0xffffd
    8000457a:	450080e7          	jalr	1104(ra) # 800019c6 <myproc>
    8000457e:	591c                	lw	a5,48(a0)
    80004580:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004582:	854a                	mv	a0,s2
    80004584:	ffffc097          	auipc	ra,0xffffc
    80004588:	71a080e7          	jalr	1818(ra) # 80000c9e <release>
}
    8000458c:	60e2                	ld	ra,24(sp)
    8000458e:	6442                	ld	s0,16(sp)
    80004590:	64a2                	ld	s1,8(sp)
    80004592:	6902                	ld	s2,0(sp)
    80004594:	6105                	addi	sp,sp,32
    80004596:	8082                	ret

0000000080004598 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004598:	1101                	addi	sp,sp,-32
    8000459a:	ec06                	sd	ra,24(sp)
    8000459c:	e822                	sd	s0,16(sp)
    8000459e:	e426                	sd	s1,8(sp)
    800045a0:	e04a                	sd	s2,0(sp)
    800045a2:	1000                	addi	s0,sp,32
    800045a4:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045a6:	00850913          	addi	s2,a0,8
    800045aa:	854a                	mv	a0,s2
    800045ac:	ffffc097          	auipc	ra,0xffffc
    800045b0:	63e080e7          	jalr	1598(ra) # 80000bea <acquire>
  lk->locked = 0;
    800045b4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800045b8:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800045bc:	8526                	mv	a0,s1
    800045be:	ffffe097          	auipc	ra,0xffffe
    800045c2:	bb0080e7          	jalr	-1104(ra) # 8000216e <wakeup>
  release(&lk->lk);
    800045c6:	854a                	mv	a0,s2
    800045c8:	ffffc097          	auipc	ra,0xffffc
    800045cc:	6d6080e7          	jalr	1750(ra) # 80000c9e <release>
}
    800045d0:	60e2                	ld	ra,24(sp)
    800045d2:	6442                	ld	s0,16(sp)
    800045d4:	64a2                	ld	s1,8(sp)
    800045d6:	6902                	ld	s2,0(sp)
    800045d8:	6105                	addi	sp,sp,32
    800045da:	8082                	ret

00000000800045dc <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800045dc:	7179                	addi	sp,sp,-48
    800045de:	f406                	sd	ra,40(sp)
    800045e0:	f022                	sd	s0,32(sp)
    800045e2:	ec26                	sd	s1,24(sp)
    800045e4:	e84a                	sd	s2,16(sp)
    800045e6:	e44e                	sd	s3,8(sp)
    800045e8:	1800                	addi	s0,sp,48
    800045ea:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800045ec:	00850913          	addi	s2,a0,8
    800045f0:	854a                	mv	a0,s2
    800045f2:	ffffc097          	auipc	ra,0xffffc
    800045f6:	5f8080e7          	jalr	1528(ra) # 80000bea <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800045fa:	409c                	lw	a5,0(s1)
    800045fc:	ef99                	bnez	a5,8000461a <holdingsleep+0x3e>
    800045fe:	4481                	li	s1,0
  release(&lk->lk);
    80004600:	854a                	mv	a0,s2
    80004602:	ffffc097          	auipc	ra,0xffffc
    80004606:	69c080e7          	jalr	1692(ra) # 80000c9e <release>
  return r;
}
    8000460a:	8526                	mv	a0,s1
    8000460c:	70a2                	ld	ra,40(sp)
    8000460e:	7402                	ld	s0,32(sp)
    80004610:	64e2                	ld	s1,24(sp)
    80004612:	6942                	ld	s2,16(sp)
    80004614:	69a2                	ld	s3,8(sp)
    80004616:	6145                	addi	sp,sp,48
    80004618:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000461a:	0284a983          	lw	s3,40(s1)
    8000461e:	ffffd097          	auipc	ra,0xffffd
    80004622:	3a8080e7          	jalr	936(ra) # 800019c6 <myproc>
    80004626:	5904                	lw	s1,48(a0)
    80004628:	413484b3          	sub	s1,s1,s3
    8000462c:	0014b493          	seqz	s1,s1
    80004630:	bfc1                	j	80004600 <holdingsleep+0x24>

0000000080004632 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004632:	1141                	addi	sp,sp,-16
    80004634:	e406                	sd	ra,8(sp)
    80004636:	e022                	sd	s0,0(sp)
    80004638:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000463a:	00004597          	auipc	a1,0x4
    8000463e:	24e58593          	addi	a1,a1,590 # 80008888 <syscalls+0x268>
    80004642:	00025517          	auipc	a0,0x25
    80004646:	b5e50513          	addi	a0,a0,-1186 # 800291a0 <ftable>
    8000464a:	ffffc097          	auipc	ra,0xffffc
    8000464e:	510080e7          	jalr	1296(ra) # 80000b5a <initlock>
}
    80004652:	60a2                	ld	ra,8(sp)
    80004654:	6402                	ld	s0,0(sp)
    80004656:	0141                	addi	sp,sp,16
    80004658:	8082                	ret

000000008000465a <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000465a:	1101                	addi	sp,sp,-32
    8000465c:	ec06                	sd	ra,24(sp)
    8000465e:	e822                	sd	s0,16(sp)
    80004660:	e426                	sd	s1,8(sp)
    80004662:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004664:	00025517          	auipc	a0,0x25
    80004668:	b3c50513          	addi	a0,a0,-1220 # 800291a0 <ftable>
    8000466c:	ffffc097          	auipc	ra,0xffffc
    80004670:	57e080e7          	jalr	1406(ra) # 80000bea <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004674:	00025497          	auipc	s1,0x25
    80004678:	b4448493          	addi	s1,s1,-1212 # 800291b8 <ftable+0x18>
    8000467c:	00026717          	auipc	a4,0x26
    80004680:	adc70713          	addi	a4,a4,-1316 # 8002a158 <disk>
    if(f->ref == 0){
    80004684:	40dc                	lw	a5,4(s1)
    80004686:	cf99                	beqz	a5,800046a4 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004688:	02848493          	addi	s1,s1,40
    8000468c:	fee49ce3          	bne	s1,a4,80004684 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004690:	00025517          	auipc	a0,0x25
    80004694:	b1050513          	addi	a0,a0,-1264 # 800291a0 <ftable>
    80004698:	ffffc097          	auipc	ra,0xffffc
    8000469c:	606080e7          	jalr	1542(ra) # 80000c9e <release>
  return 0;
    800046a0:	4481                	li	s1,0
    800046a2:	a819                	j	800046b8 <filealloc+0x5e>
      f->ref = 1;
    800046a4:	4785                	li	a5,1
    800046a6:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800046a8:	00025517          	auipc	a0,0x25
    800046ac:	af850513          	addi	a0,a0,-1288 # 800291a0 <ftable>
    800046b0:	ffffc097          	auipc	ra,0xffffc
    800046b4:	5ee080e7          	jalr	1518(ra) # 80000c9e <release>
}
    800046b8:	8526                	mv	a0,s1
    800046ba:	60e2                	ld	ra,24(sp)
    800046bc:	6442                	ld	s0,16(sp)
    800046be:	64a2                	ld	s1,8(sp)
    800046c0:	6105                	addi	sp,sp,32
    800046c2:	8082                	ret

00000000800046c4 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800046c4:	1101                	addi	sp,sp,-32
    800046c6:	ec06                	sd	ra,24(sp)
    800046c8:	e822                	sd	s0,16(sp)
    800046ca:	e426                	sd	s1,8(sp)
    800046cc:	1000                	addi	s0,sp,32
    800046ce:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800046d0:	00025517          	auipc	a0,0x25
    800046d4:	ad050513          	addi	a0,a0,-1328 # 800291a0 <ftable>
    800046d8:	ffffc097          	auipc	ra,0xffffc
    800046dc:	512080e7          	jalr	1298(ra) # 80000bea <acquire>
  if(f->ref < 1)
    800046e0:	40dc                	lw	a5,4(s1)
    800046e2:	02f05263          	blez	a5,80004706 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800046e6:	2785                	addiw	a5,a5,1
    800046e8:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800046ea:	00025517          	auipc	a0,0x25
    800046ee:	ab650513          	addi	a0,a0,-1354 # 800291a0 <ftable>
    800046f2:	ffffc097          	auipc	ra,0xffffc
    800046f6:	5ac080e7          	jalr	1452(ra) # 80000c9e <release>
  return f;
}
    800046fa:	8526                	mv	a0,s1
    800046fc:	60e2                	ld	ra,24(sp)
    800046fe:	6442                	ld	s0,16(sp)
    80004700:	64a2                	ld	s1,8(sp)
    80004702:	6105                	addi	sp,sp,32
    80004704:	8082                	ret
    panic("filedup");
    80004706:	00004517          	auipc	a0,0x4
    8000470a:	18a50513          	addi	a0,a0,394 # 80008890 <syscalls+0x270>
    8000470e:	ffffc097          	auipc	ra,0xffffc
    80004712:	e36080e7          	jalr	-458(ra) # 80000544 <panic>

0000000080004716 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004716:	7139                	addi	sp,sp,-64
    80004718:	fc06                	sd	ra,56(sp)
    8000471a:	f822                	sd	s0,48(sp)
    8000471c:	f426                	sd	s1,40(sp)
    8000471e:	f04a                	sd	s2,32(sp)
    80004720:	ec4e                	sd	s3,24(sp)
    80004722:	e852                	sd	s4,16(sp)
    80004724:	e456                	sd	s5,8(sp)
    80004726:	0080                	addi	s0,sp,64
    80004728:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000472a:	00025517          	auipc	a0,0x25
    8000472e:	a7650513          	addi	a0,a0,-1418 # 800291a0 <ftable>
    80004732:	ffffc097          	auipc	ra,0xffffc
    80004736:	4b8080e7          	jalr	1208(ra) # 80000bea <acquire>
  if(f->ref < 1)
    8000473a:	40dc                	lw	a5,4(s1)
    8000473c:	06f05163          	blez	a5,8000479e <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004740:	37fd                	addiw	a5,a5,-1
    80004742:	0007871b          	sext.w	a4,a5
    80004746:	c0dc                	sw	a5,4(s1)
    80004748:	06e04363          	bgtz	a4,800047ae <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000474c:	0004a903          	lw	s2,0(s1)
    80004750:	0094ca83          	lbu	s5,9(s1)
    80004754:	0104ba03          	ld	s4,16(s1)
    80004758:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000475c:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004760:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004764:	00025517          	auipc	a0,0x25
    80004768:	a3c50513          	addi	a0,a0,-1476 # 800291a0 <ftable>
    8000476c:	ffffc097          	auipc	ra,0xffffc
    80004770:	532080e7          	jalr	1330(ra) # 80000c9e <release>

  if(ff.type == FD_PIPE){
    80004774:	4785                	li	a5,1
    80004776:	04f90d63          	beq	s2,a5,800047d0 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000477a:	3979                	addiw	s2,s2,-2
    8000477c:	4785                	li	a5,1
    8000477e:	0527e063          	bltu	a5,s2,800047be <fileclose+0xa8>
    begin_op();
    80004782:	00000097          	auipc	ra,0x0
    80004786:	ac8080e7          	jalr	-1336(ra) # 8000424a <begin_op>
    iput(ff.ip);
    8000478a:	854e                	mv	a0,s3
    8000478c:	fffff097          	auipc	ra,0xfffff
    80004790:	2b6080e7          	jalr	694(ra) # 80003a42 <iput>
    end_op();
    80004794:	00000097          	auipc	ra,0x0
    80004798:	b36080e7          	jalr	-1226(ra) # 800042ca <end_op>
    8000479c:	a00d                	j	800047be <fileclose+0xa8>
    panic("fileclose");
    8000479e:	00004517          	auipc	a0,0x4
    800047a2:	0fa50513          	addi	a0,a0,250 # 80008898 <syscalls+0x278>
    800047a6:	ffffc097          	auipc	ra,0xffffc
    800047aa:	d9e080e7          	jalr	-610(ra) # 80000544 <panic>
    release(&ftable.lock);
    800047ae:	00025517          	auipc	a0,0x25
    800047b2:	9f250513          	addi	a0,a0,-1550 # 800291a0 <ftable>
    800047b6:	ffffc097          	auipc	ra,0xffffc
    800047ba:	4e8080e7          	jalr	1256(ra) # 80000c9e <release>
  }
}
    800047be:	70e2                	ld	ra,56(sp)
    800047c0:	7442                	ld	s0,48(sp)
    800047c2:	74a2                	ld	s1,40(sp)
    800047c4:	7902                	ld	s2,32(sp)
    800047c6:	69e2                	ld	s3,24(sp)
    800047c8:	6a42                	ld	s4,16(sp)
    800047ca:	6aa2                	ld	s5,8(sp)
    800047cc:	6121                	addi	sp,sp,64
    800047ce:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800047d0:	85d6                	mv	a1,s5
    800047d2:	8552                	mv	a0,s4
    800047d4:	00000097          	auipc	ra,0x0
    800047d8:	34c080e7          	jalr	844(ra) # 80004b20 <pipeclose>
    800047dc:	b7cd                	j	800047be <fileclose+0xa8>

00000000800047de <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800047de:	715d                	addi	sp,sp,-80
    800047e0:	e486                	sd	ra,72(sp)
    800047e2:	e0a2                	sd	s0,64(sp)
    800047e4:	fc26                	sd	s1,56(sp)
    800047e6:	f84a                	sd	s2,48(sp)
    800047e8:	f44e                	sd	s3,40(sp)
    800047ea:	0880                	addi	s0,sp,80
    800047ec:	84aa                	mv	s1,a0
    800047ee:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800047f0:	ffffd097          	auipc	ra,0xffffd
    800047f4:	1d6080e7          	jalr	470(ra) # 800019c6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800047f8:	409c                	lw	a5,0(s1)
    800047fa:	37f9                	addiw	a5,a5,-2
    800047fc:	4705                	li	a4,1
    800047fe:	04f76763          	bltu	a4,a5,8000484c <filestat+0x6e>
    80004802:	892a                	mv	s2,a0
    ilock(f->ip);
    80004804:	6c88                	ld	a0,24(s1)
    80004806:	fffff097          	auipc	ra,0xfffff
    8000480a:	082080e7          	jalr	130(ra) # 80003888 <ilock>
    stati(f->ip, &st);
    8000480e:	fb840593          	addi	a1,s0,-72
    80004812:	6c88                	ld	a0,24(s1)
    80004814:	fffff097          	auipc	ra,0xfffff
    80004818:	2fe080e7          	jalr	766(ra) # 80003b12 <stati>
    iunlock(f->ip);
    8000481c:	6c88                	ld	a0,24(s1)
    8000481e:	fffff097          	auipc	ra,0xfffff
    80004822:	12c080e7          	jalr	300(ra) # 8000394a <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004826:	46e1                	li	a3,24
    80004828:	fb840613          	addi	a2,s0,-72
    8000482c:	85ce                	mv	a1,s3
    8000482e:	05093503          	ld	a0,80(s2)
    80004832:	ffffd097          	auipc	ra,0xffffd
    80004836:	e52080e7          	jalr	-430(ra) # 80001684 <copyout>
    8000483a:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000483e:	60a6                	ld	ra,72(sp)
    80004840:	6406                	ld	s0,64(sp)
    80004842:	74e2                	ld	s1,56(sp)
    80004844:	7942                	ld	s2,48(sp)
    80004846:	79a2                	ld	s3,40(sp)
    80004848:	6161                	addi	sp,sp,80
    8000484a:	8082                	ret
  return -1;
    8000484c:	557d                	li	a0,-1
    8000484e:	bfc5                	j	8000483e <filestat+0x60>

0000000080004850 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004850:	7179                	addi	sp,sp,-48
    80004852:	f406                	sd	ra,40(sp)
    80004854:	f022                	sd	s0,32(sp)
    80004856:	ec26                	sd	s1,24(sp)
    80004858:	e84a                	sd	s2,16(sp)
    8000485a:	e44e                	sd	s3,8(sp)
    8000485c:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000485e:	00854783          	lbu	a5,8(a0)
    80004862:	c3d5                	beqz	a5,80004906 <fileread+0xb6>
    80004864:	84aa                	mv	s1,a0
    80004866:	89ae                	mv	s3,a1
    80004868:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000486a:	411c                	lw	a5,0(a0)
    8000486c:	4705                	li	a4,1
    8000486e:	04e78963          	beq	a5,a4,800048c0 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004872:	470d                	li	a4,3
    80004874:	04e78d63          	beq	a5,a4,800048ce <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004878:	4709                	li	a4,2
    8000487a:	06e79e63          	bne	a5,a4,800048f6 <fileread+0xa6>
    ilock(f->ip);
    8000487e:	6d08                	ld	a0,24(a0)
    80004880:	fffff097          	auipc	ra,0xfffff
    80004884:	008080e7          	jalr	8(ra) # 80003888 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004888:	874a                	mv	a4,s2
    8000488a:	5094                	lw	a3,32(s1)
    8000488c:	864e                	mv	a2,s3
    8000488e:	4585                	li	a1,1
    80004890:	6c88                	ld	a0,24(s1)
    80004892:	fffff097          	auipc	ra,0xfffff
    80004896:	2aa080e7          	jalr	682(ra) # 80003b3c <readi>
    8000489a:	892a                	mv	s2,a0
    8000489c:	00a05563          	blez	a0,800048a6 <fileread+0x56>
      f->off += r;
    800048a0:	509c                	lw	a5,32(s1)
    800048a2:	9fa9                	addw	a5,a5,a0
    800048a4:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800048a6:	6c88                	ld	a0,24(s1)
    800048a8:	fffff097          	auipc	ra,0xfffff
    800048ac:	0a2080e7          	jalr	162(ra) # 8000394a <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800048b0:	854a                	mv	a0,s2
    800048b2:	70a2                	ld	ra,40(sp)
    800048b4:	7402                	ld	s0,32(sp)
    800048b6:	64e2                	ld	s1,24(sp)
    800048b8:	6942                	ld	s2,16(sp)
    800048ba:	69a2                	ld	s3,8(sp)
    800048bc:	6145                	addi	sp,sp,48
    800048be:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800048c0:	6908                	ld	a0,16(a0)
    800048c2:	00000097          	auipc	ra,0x0
    800048c6:	3ce080e7          	jalr	974(ra) # 80004c90 <piperead>
    800048ca:	892a                	mv	s2,a0
    800048cc:	b7d5                	j	800048b0 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800048ce:	02451783          	lh	a5,36(a0)
    800048d2:	03079693          	slli	a3,a5,0x30
    800048d6:	92c1                	srli	a3,a3,0x30
    800048d8:	4725                	li	a4,9
    800048da:	02d76863          	bltu	a4,a3,8000490a <fileread+0xba>
    800048de:	0792                	slli	a5,a5,0x4
    800048e0:	00025717          	auipc	a4,0x25
    800048e4:	82070713          	addi	a4,a4,-2016 # 80029100 <devsw>
    800048e8:	97ba                	add	a5,a5,a4
    800048ea:	639c                	ld	a5,0(a5)
    800048ec:	c38d                	beqz	a5,8000490e <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800048ee:	4505                	li	a0,1
    800048f0:	9782                	jalr	a5
    800048f2:	892a                	mv	s2,a0
    800048f4:	bf75                	j	800048b0 <fileread+0x60>
    panic("fileread");
    800048f6:	00004517          	auipc	a0,0x4
    800048fa:	fb250513          	addi	a0,a0,-78 # 800088a8 <syscalls+0x288>
    800048fe:	ffffc097          	auipc	ra,0xffffc
    80004902:	c46080e7          	jalr	-954(ra) # 80000544 <panic>
    return -1;
    80004906:	597d                	li	s2,-1
    80004908:	b765                	j	800048b0 <fileread+0x60>
      return -1;
    8000490a:	597d                	li	s2,-1
    8000490c:	b755                	j	800048b0 <fileread+0x60>
    8000490e:	597d                	li	s2,-1
    80004910:	b745                	j	800048b0 <fileread+0x60>

0000000080004912 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004912:	715d                	addi	sp,sp,-80
    80004914:	e486                	sd	ra,72(sp)
    80004916:	e0a2                	sd	s0,64(sp)
    80004918:	fc26                	sd	s1,56(sp)
    8000491a:	f84a                	sd	s2,48(sp)
    8000491c:	f44e                	sd	s3,40(sp)
    8000491e:	f052                	sd	s4,32(sp)
    80004920:	ec56                	sd	s5,24(sp)
    80004922:	e85a                	sd	s6,16(sp)
    80004924:	e45e                	sd	s7,8(sp)
    80004926:	e062                	sd	s8,0(sp)
    80004928:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000492a:	00954783          	lbu	a5,9(a0)
    8000492e:	10078663          	beqz	a5,80004a3a <filewrite+0x128>
    80004932:	892a                	mv	s2,a0
    80004934:	8aae                	mv	s5,a1
    80004936:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004938:	411c                	lw	a5,0(a0)
    8000493a:	4705                	li	a4,1
    8000493c:	02e78263          	beq	a5,a4,80004960 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004940:	470d                	li	a4,3
    80004942:	02e78663          	beq	a5,a4,8000496e <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004946:	4709                	li	a4,2
    80004948:	0ee79163          	bne	a5,a4,80004a2a <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000494c:	0ac05d63          	blez	a2,80004a06 <filewrite+0xf4>
    int i = 0;
    80004950:	4981                	li	s3,0
    80004952:	6b05                	lui	s6,0x1
    80004954:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004958:	6b85                	lui	s7,0x1
    8000495a:	c00b8b9b          	addiw	s7,s7,-1024
    8000495e:	a861                	j	800049f6 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004960:	6908                	ld	a0,16(a0)
    80004962:	00000097          	auipc	ra,0x0
    80004966:	22e080e7          	jalr	558(ra) # 80004b90 <pipewrite>
    8000496a:	8a2a                	mv	s4,a0
    8000496c:	a045                	j	80004a0c <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000496e:	02451783          	lh	a5,36(a0)
    80004972:	03079693          	slli	a3,a5,0x30
    80004976:	92c1                	srli	a3,a3,0x30
    80004978:	4725                	li	a4,9
    8000497a:	0cd76263          	bltu	a4,a3,80004a3e <filewrite+0x12c>
    8000497e:	0792                	slli	a5,a5,0x4
    80004980:	00024717          	auipc	a4,0x24
    80004984:	78070713          	addi	a4,a4,1920 # 80029100 <devsw>
    80004988:	97ba                	add	a5,a5,a4
    8000498a:	679c                	ld	a5,8(a5)
    8000498c:	cbdd                	beqz	a5,80004a42 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    8000498e:	4505                	li	a0,1
    80004990:	9782                	jalr	a5
    80004992:	8a2a                	mv	s4,a0
    80004994:	a8a5                	j	80004a0c <filewrite+0xfa>
    80004996:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000499a:	00000097          	auipc	ra,0x0
    8000499e:	8b0080e7          	jalr	-1872(ra) # 8000424a <begin_op>
      ilock(f->ip);
    800049a2:	01893503          	ld	a0,24(s2)
    800049a6:	fffff097          	auipc	ra,0xfffff
    800049aa:	ee2080e7          	jalr	-286(ra) # 80003888 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800049ae:	8762                	mv	a4,s8
    800049b0:	02092683          	lw	a3,32(s2)
    800049b4:	01598633          	add	a2,s3,s5
    800049b8:	4585                	li	a1,1
    800049ba:	01893503          	ld	a0,24(s2)
    800049be:	fffff097          	auipc	ra,0xfffff
    800049c2:	276080e7          	jalr	630(ra) # 80003c34 <writei>
    800049c6:	84aa                	mv	s1,a0
    800049c8:	00a05763          	blez	a0,800049d6 <filewrite+0xc4>
        f->off += r;
    800049cc:	02092783          	lw	a5,32(s2)
    800049d0:	9fa9                	addw	a5,a5,a0
    800049d2:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800049d6:	01893503          	ld	a0,24(s2)
    800049da:	fffff097          	auipc	ra,0xfffff
    800049de:	f70080e7          	jalr	-144(ra) # 8000394a <iunlock>
      end_op();
    800049e2:	00000097          	auipc	ra,0x0
    800049e6:	8e8080e7          	jalr	-1816(ra) # 800042ca <end_op>

      if(r != n1){
    800049ea:	009c1f63          	bne	s8,s1,80004a08 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800049ee:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800049f2:	0149db63          	bge	s3,s4,80004a08 <filewrite+0xf6>
      int n1 = n - i;
    800049f6:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800049fa:	84be                	mv	s1,a5
    800049fc:	2781                	sext.w	a5,a5
    800049fe:	f8fb5ce3          	bge	s6,a5,80004996 <filewrite+0x84>
    80004a02:	84de                	mv	s1,s7
    80004a04:	bf49                	j	80004996 <filewrite+0x84>
    int i = 0;
    80004a06:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004a08:	013a1f63          	bne	s4,s3,80004a26 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004a0c:	8552                	mv	a0,s4
    80004a0e:	60a6                	ld	ra,72(sp)
    80004a10:	6406                	ld	s0,64(sp)
    80004a12:	74e2                	ld	s1,56(sp)
    80004a14:	7942                	ld	s2,48(sp)
    80004a16:	79a2                	ld	s3,40(sp)
    80004a18:	7a02                	ld	s4,32(sp)
    80004a1a:	6ae2                	ld	s5,24(sp)
    80004a1c:	6b42                	ld	s6,16(sp)
    80004a1e:	6ba2                	ld	s7,8(sp)
    80004a20:	6c02                	ld	s8,0(sp)
    80004a22:	6161                	addi	sp,sp,80
    80004a24:	8082                	ret
    ret = (i == n ? n : -1);
    80004a26:	5a7d                	li	s4,-1
    80004a28:	b7d5                	j	80004a0c <filewrite+0xfa>
    panic("filewrite");
    80004a2a:	00004517          	auipc	a0,0x4
    80004a2e:	e8e50513          	addi	a0,a0,-370 # 800088b8 <syscalls+0x298>
    80004a32:	ffffc097          	auipc	ra,0xffffc
    80004a36:	b12080e7          	jalr	-1262(ra) # 80000544 <panic>
    return -1;
    80004a3a:	5a7d                	li	s4,-1
    80004a3c:	bfc1                	j	80004a0c <filewrite+0xfa>
      return -1;
    80004a3e:	5a7d                	li	s4,-1
    80004a40:	b7f1                	j	80004a0c <filewrite+0xfa>
    80004a42:	5a7d                	li	s4,-1
    80004a44:	b7e1                	j	80004a0c <filewrite+0xfa>

0000000080004a46 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004a46:	7179                	addi	sp,sp,-48
    80004a48:	f406                	sd	ra,40(sp)
    80004a4a:	f022                	sd	s0,32(sp)
    80004a4c:	ec26                	sd	s1,24(sp)
    80004a4e:	e84a                	sd	s2,16(sp)
    80004a50:	e44e                	sd	s3,8(sp)
    80004a52:	e052                	sd	s4,0(sp)
    80004a54:	1800                	addi	s0,sp,48
    80004a56:	84aa                	mv	s1,a0
    80004a58:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004a5a:	0005b023          	sd	zero,0(a1)
    80004a5e:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004a62:	00000097          	auipc	ra,0x0
    80004a66:	bf8080e7          	jalr	-1032(ra) # 8000465a <filealloc>
    80004a6a:	e088                	sd	a0,0(s1)
    80004a6c:	c551                	beqz	a0,80004af8 <pipealloc+0xb2>
    80004a6e:	00000097          	auipc	ra,0x0
    80004a72:	bec080e7          	jalr	-1044(ra) # 8000465a <filealloc>
    80004a76:	00aa3023          	sd	a0,0(s4)
    80004a7a:	c92d                	beqz	a0,80004aec <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004a7c:	ffffc097          	auipc	ra,0xffffc
    80004a80:	07e080e7          	jalr	126(ra) # 80000afa <kalloc>
    80004a84:	892a                	mv	s2,a0
    80004a86:	c125                	beqz	a0,80004ae6 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004a88:	4985                	li	s3,1
    80004a8a:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004a8e:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004a92:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004a96:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004a9a:	00004597          	auipc	a1,0x4
    80004a9e:	ade58593          	addi	a1,a1,-1314 # 80008578 <states.1763+0x218>
    80004aa2:	ffffc097          	auipc	ra,0xffffc
    80004aa6:	0b8080e7          	jalr	184(ra) # 80000b5a <initlock>
  (*f0)->type = FD_PIPE;
    80004aaa:	609c                	ld	a5,0(s1)
    80004aac:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004ab0:	609c                	ld	a5,0(s1)
    80004ab2:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004ab6:	609c                	ld	a5,0(s1)
    80004ab8:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004abc:	609c                	ld	a5,0(s1)
    80004abe:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004ac2:	000a3783          	ld	a5,0(s4)
    80004ac6:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004aca:	000a3783          	ld	a5,0(s4)
    80004ace:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004ad2:	000a3783          	ld	a5,0(s4)
    80004ad6:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004ada:	000a3783          	ld	a5,0(s4)
    80004ade:	0127b823          	sd	s2,16(a5)
  return 0;
    80004ae2:	4501                	li	a0,0
    80004ae4:	a025                	j	80004b0c <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004ae6:	6088                	ld	a0,0(s1)
    80004ae8:	e501                	bnez	a0,80004af0 <pipealloc+0xaa>
    80004aea:	a039                	j	80004af8 <pipealloc+0xb2>
    80004aec:	6088                	ld	a0,0(s1)
    80004aee:	c51d                	beqz	a0,80004b1c <pipealloc+0xd6>
    fileclose(*f0);
    80004af0:	00000097          	auipc	ra,0x0
    80004af4:	c26080e7          	jalr	-986(ra) # 80004716 <fileclose>
  if(*f1)
    80004af8:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004afc:	557d                	li	a0,-1
  if(*f1)
    80004afe:	c799                	beqz	a5,80004b0c <pipealloc+0xc6>
    fileclose(*f1);
    80004b00:	853e                	mv	a0,a5
    80004b02:	00000097          	auipc	ra,0x0
    80004b06:	c14080e7          	jalr	-1004(ra) # 80004716 <fileclose>
  return -1;
    80004b0a:	557d                	li	a0,-1
}
    80004b0c:	70a2                	ld	ra,40(sp)
    80004b0e:	7402                	ld	s0,32(sp)
    80004b10:	64e2                	ld	s1,24(sp)
    80004b12:	6942                	ld	s2,16(sp)
    80004b14:	69a2                	ld	s3,8(sp)
    80004b16:	6a02                	ld	s4,0(sp)
    80004b18:	6145                	addi	sp,sp,48
    80004b1a:	8082                	ret
  return -1;
    80004b1c:	557d                	li	a0,-1
    80004b1e:	b7fd                	j	80004b0c <pipealloc+0xc6>

0000000080004b20 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004b20:	1101                	addi	sp,sp,-32
    80004b22:	ec06                	sd	ra,24(sp)
    80004b24:	e822                	sd	s0,16(sp)
    80004b26:	e426                	sd	s1,8(sp)
    80004b28:	e04a                	sd	s2,0(sp)
    80004b2a:	1000                	addi	s0,sp,32
    80004b2c:	84aa                	mv	s1,a0
    80004b2e:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004b30:	ffffc097          	auipc	ra,0xffffc
    80004b34:	0ba080e7          	jalr	186(ra) # 80000bea <acquire>
  if(writable){
    80004b38:	02090d63          	beqz	s2,80004b72 <pipeclose+0x52>
    pi->writeopen = 0;
    80004b3c:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004b40:	21848513          	addi	a0,s1,536
    80004b44:	ffffd097          	auipc	ra,0xffffd
    80004b48:	62a080e7          	jalr	1578(ra) # 8000216e <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004b4c:	2204b783          	ld	a5,544(s1)
    80004b50:	eb95                	bnez	a5,80004b84 <pipeclose+0x64>
    release(&pi->lock);
    80004b52:	8526                	mv	a0,s1
    80004b54:	ffffc097          	auipc	ra,0xffffc
    80004b58:	14a080e7          	jalr	330(ra) # 80000c9e <release>
    kfree((char*)pi);
    80004b5c:	8526                	mv	a0,s1
    80004b5e:	ffffc097          	auipc	ra,0xffffc
    80004b62:	ea0080e7          	jalr	-352(ra) # 800009fe <kfree>
  } else
    release(&pi->lock);
}
    80004b66:	60e2                	ld	ra,24(sp)
    80004b68:	6442                	ld	s0,16(sp)
    80004b6a:	64a2                	ld	s1,8(sp)
    80004b6c:	6902                	ld	s2,0(sp)
    80004b6e:	6105                	addi	sp,sp,32
    80004b70:	8082                	ret
    pi->readopen = 0;
    80004b72:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004b76:	21c48513          	addi	a0,s1,540
    80004b7a:	ffffd097          	auipc	ra,0xffffd
    80004b7e:	5f4080e7          	jalr	1524(ra) # 8000216e <wakeup>
    80004b82:	b7e9                	j	80004b4c <pipeclose+0x2c>
    release(&pi->lock);
    80004b84:	8526                	mv	a0,s1
    80004b86:	ffffc097          	auipc	ra,0xffffc
    80004b8a:	118080e7          	jalr	280(ra) # 80000c9e <release>
}
    80004b8e:	bfe1                	j	80004b66 <pipeclose+0x46>

0000000080004b90 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004b90:	7159                	addi	sp,sp,-112
    80004b92:	f486                	sd	ra,104(sp)
    80004b94:	f0a2                	sd	s0,96(sp)
    80004b96:	eca6                	sd	s1,88(sp)
    80004b98:	e8ca                	sd	s2,80(sp)
    80004b9a:	e4ce                	sd	s3,72(sp)
    80004b9c:	e0d2                	sd	s4,64(sp)
    80004b9e:	fc56                	sd	s5,56(sp)
    80004ba0:	f85a                	sd	s6,48(sp)
    80004ba2:	f45e                	sd	s7,40(sp)
    80004ba4:	f062                	sd	s8,32(sp)
    80004ba6:	ec66                	sd	s9,24(sp)
    80004ba8:	1880                	addi	s0,sp,112
    80004baa:	84aa                	mv	s1,a0
    80004bac:	8aae                	mv	s5,a1
    80004bae:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004bb0:	ffffd097          	auipc	ra,0xffffd
    80004bb4:	e16080e7          	jalr	-490(ra) # 800019c6 <myproc>
    80004bb8:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004bba:	8526                	mv	a0,s1
    80004bbc:	ffffc097          	auipc	ra,0xffffc
    80004bc0:	02e080e7          	jalr	46(ra) # 80000bea <acquire>
  while(i < n){
    80004bc4:	0d405463          	blez	s4,80004c8c <pipewrite+0xfc>
    80004bc8:	8ba6                	mv	s7,s1
  int i = 0;
    80004bca:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004bcc:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004bce:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004bd2:	21c48c13          	addi	s8,s1,540
    80004bd6:	a08d                	j	80004c38 <pipewrite+0xa8>
      release(&pi->lock);
    80004bd8:	8526                	mv	a0,s1
    80004bda:	ffffc097          	auipc	ra,0xffffc
    80004bde:	0c4080e7          	jalr	196(ra) # 80000c9e <release>
      return -1;
    80004be2:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004be4:	854a                	mv	a0,s2
    80004be6:	70a6                	ld	ra,104(sp)
    80004be8:	7406                	ld	s0,96(sp)
    80004bea:	64e6                	ld	s1,88(sp)
    80004bec:	6946                	ld	s2,80(sp)
    80004bee:	69a6                	ld	s3,72(sp)
    80004bf0:	6a06                	ld	s4,64(sp)
    80004bf2:	7ae2                	ld	s5,56(sp)
    80004bf4:	7b42                	ld	s6,48(sp)
    80004bf6:	7ba2                	ld	s7,40(sp)
    80004bf8:	7c02                	ld	s8,32(sp)
    80004bfa:	6ce2                	ld	s9,24(sp)
    80004bfc:	6165                	addi	sp,sp,112
    80004bfe:	8082                	ret
      wakeup(&pi->nread);
    80004c00:	8566                	mv	a0,s9
    80004c02:	ffffd097          	auipc	ra,0xffffd
    80004c06:	56c080e7          	jalr	1388(ra) # 8000216e <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004c0a:	85de                	mv	a1,s7
    80004c0c:	8562                	mv	a0,s8
    80004c0e:	ffffd097          	auipc	ra,0xffffd
    80004c12:	4fc080e7          	jalr	1276(ra) # 8000210a <sleep>
    80004c16:	a839                	j	80004c34 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004c18:	21c4a783          	lw	a5,540(s1)
    80004c1c:	0017871b          	addiw	a4,a5,1
    80004c20:	20e4ae23          	sw	a4,540(s1)
    80004c24:	1ff7f793          	andi	a5,a5,511
    80004c28:	97a6                	add	a5,a5,s1
    80004c2a:	f9f44703          	lbu	a4,-97(s0)
    80004c2e:	00e78c23          	sb	a4,24(a5)
      i++;
    80004c32:	2905                	addiw	s2,s2,1
  while(i < n){
    80004c34:	05495063          	bge	s2,s4,80004c74 <pipewrite+0xe4>
    if(pi->readopen == 0 || killed(pr)){
    80004c38:	2204a783          	lw	a5,544(s1)
    80004c3c:	dfd1                	beqz	a5,80004bd8 <pipewrite+0x48>
    80004c3e:	854e                	mv	a0,s3
    80004c40:	ffffd097          	auipc	ra,0xffffd
    80004c44:	772080e7          	jalr	1906(ra) # 800023b2 <killed>
    80004c48:	f941                	bnez	a0,80004bd8 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004c4a:	2184a783          	lw	a5,536(s1)
    80004c4e:	21c4a703          	lw	a4,540(s1)
    80004c52:	2007879b          	addiw	a5,a5,512
    80004c56:	faf705e3          	beq	a4,a5,80004c00 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c5a:	4685                	li	a3,1
    80004c5c:	01590633          	add	a2,s2,s5
    80004c60:	f9f40593          	addi	a1,s0,-97
    80004c64:	0509b503          	ld	a0,80(s3)
    80004c68:	ffffd097          	auipc	ra,0xffffd
    80004c6c:	aa8080e7          	jalr	-1368(ra) # 80001710 <copyin>
    80004c70:	fb6514e3          	bne	a0,s6,80004c18 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004c74:	21848513          	addi	a0,s1,536
    80004c78:	ffffd097          	auipc	ra,0xffffd
    80004c7c:	4f6080e7          	jalr	1270(ra) # 8000216e <wakeup>
  release(&pi->lock);
    80004c80:	8526                	mv	a0,s1
    80004c82:	ffffc097          	auipc	ra,0xffffc
    80004c86:	01c080e7          	jalr	28(ra) # 80000c9e <release>
  return i;
    80004c8a:	bfa9                	j	80004be4 <pipewrite+0x54>
  int i = 0;
    80004c8c:	4901                	li	s2,0
    80004c8e:	b7dd                	j	80004c74 <pipewrite+0xe4>

0000000080004c90 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004c90:	715d                	addi	sp,sp,-80
    80004c92:	e486                	sd	ra,72(sp)
    80004c94:	e0a2                	sd	s0,64(sp)
    80004c96:	fc26                	sd	s1,56(sp)
    80004c98:	f84a                	sd	s2,48(sp)
    80004c9a:	f44e                	sd	s3,40(sp)
    80004c9c:	f052                	sd	s4,32(sp)
    80004c9e:	ec56                	sd	s5,24(sp)
    80004ca0:	e85a                	sd	s6,16(sp)
    80004ca2:	0880                	addi	s0,sp,80
    80004ca4:	84aa                	mv	s1,a0
    80004ca6:	892e                	mv	s2,a1
    80004ca8:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004caa:	ffffd097          	auipc	ra,0xffffd
    80004cae:	d1c080e7          	jalr	-740(ra) # 800019c6 <myproc>
    80004cb2:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004cb4:	8b26                	mv	s6,s1
    80004cb6:	8526                	mv	a0,s1
    80004cb8:	ffffc097          	auipc	ra,0xffffc
    80004cbc:	f32080e7          	jalr	-206(ra) # 80000bea <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cc0:	2184a703          	lw	a4,536(s1)
    80004cc4:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004cc8:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ccc:	02f71763          	bne	a4,a5,80004cfa <piperead+0x6a>
    80004cd0:	2244a783          	lw	a5,548(s1)
    80004cd4:	c39d                	beqz	a5,80004cfa <piperead+0x6a>
    if(killed(pr)){
    80004cd6:	8552                	mv	a0,s4
    80004cd8:	ffffd097          	auipc	ra,0xffffd
    80004cdc:	6da080e7          	jalr	1754(ra) # 800023b2 <killed>
    80004ce0:	e941                	bnez	a0,80004d70 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004ce2:	85da                	mv	a1,s6
    80004ce4:	854e                	mv	a0,s3
    80004ce6:	ffffd097          	auipc	ra,0xffffd
    80004cea:	424080e7          	jalr	1060(ra) # 8000210a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cee:	2184a703          	lw	a4,536(s1)
    80004cf2:	21c4a783          	lw	a5,540(s1)
    80004cf6:	fcf70de3          	beq	a4,a5,80004cd0 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cfa:	09505263          	blez	s5,80004d7e <piperead+0xee>
    80004cfe:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d00:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004d02:	2184a783          	lw	a5,536(s1)
    80004d06:	21c4a703          	lw	a4,540(s1)
    80004d0a:	02f70d63          	beq	a4,a5,80004d44 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004d0e:	0017871b          	addiw	a4,a5,1
    80004d12:	20e4ac23          	sw	a4,536(s1)
    80004d16:	1ff7f793          	andi	a5,a5,511
    80004d1a:	97a6                	add	a5,a5,s1
    80004d1c:	0187c783          	lbu	a5,24(a5)
    80004d20:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d24:	4685                	li	a3,1
    80004d26:	fbf40613          	addi	a2,s0,-65
    80004d2a:	85ca                	mv	a1,s2
    80004d2c:	050a3503          	ld	a0,80(s4)
    80004d30:	ffffd097          	auipc	ra,0xffffd
    80004d34:	954080e7          	jalr	-1708(ra) # 80001684 <copyout>
    80004d38:	01650663          	beq	a0,s6,80004d44 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d3c:	2985                	addiw	s3,s3,1
    80004d3e:	0905                	addi	s2,s2,1
    80004d40:	fd3a91e3          	bne	s5,s3,80004d02 <piperead+0x72>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004d44:	21c48513          	addi	a0,s1,540
    80004d48:	ffffd097          	auipc	ra,0xffffd
    80004d4c:	426080e7          	jalr	1062(ra) # 8000216e <wakeup>
  release(&pi->lock);
    80004d50:	8526                	mv	a0,s1
    80004d52:	ffffc097          	auipc	ra,0xffffc
    80004d56:	f4c080e7          	jalr	-180(ra) # 80000c9e <release>
  return i;
}
    80004d5a:	854e                	mv	a0,s3
    80004d5c:	60a6                	ld	ra,72(sp)
    80004d5e:	6406                	ld	s0,64(sp)
    80004d60:	74e2                	ld	s1,56(sp)
    80004d62:	7942                	ld	s2,48(sp)
    80004d64:	79a2                	ld	s3,40(sp)
    80004d66:	7a02                	ld	s4,32(sp)
    80004d68:	6ae2                	ld	s5,24(sp)
    80004d6a:	6b42                	ld	s6,16(sp)
    80004d6c:	6161                	addi	sp,sp,80
    80004d6e:	8082                	ret
      release(&pi->lock);
    80004d70:	8526                	mv	a0,s1
    80004d72:	ffffc097          	auipc	ra,0xffffc
    80004d76:	f2c080e7          	jalr	-212(ra) # 80000c9e <release>
      return -1;
    80004d7a:	59fd                	li	s3,-1
    80004d7c:	bff9                	j	80004d5a <piperead+0xca>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d7e:	4981                	li	s3,0
    80004d80:	b7d1                	j	80004d44 <piperead+0xb4>

0000000080004d82 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004d82:	1141                	addi	sp,sp,-16
    80004d84:	e422                	sd	s0,8(sp)
    80004d86:	0800                	addi	s0,sp,16
    80004d88:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004d8a:	8905                	andi	a0,a0,1
    80004d8c:	c111                	beqz	a0,80004d90 <flags2perm+0xe>
      perm = PTE_X;
    80004d8e:	4521                	li	a0,8
    if(flags & 0x2)
    80004d90:	8b89                	andi	a5,a5,2
    80004d92:	c399                	beqz	a5,80004d98 <flags2perm+0x16>
      perm |= PTE_W;
    80004d94:	00456513          	ori	a0,a0,4
    return perm;
}
    80004d98:	6422                	ld	s0,8(sp)
    80004d9a:	0141                	addi	sp,sp,16
    80004d9c:	8082                	ret

0000000080004d9e <exec>:

int
exec(char *path, char **argv)
{
    80004d9e:	df010113          	addi	sp,sp,-528
    80004da2:	20113423          	sd	ra,520(sp)
    80004da6:	20813023          	sd	s0,512(sp)
    80004daa:	ffa6                	sd	s1,504(sp)
    80004dac:	fbca                	sd	s2,496(sp)
    80004dae:	f7ce                	sd	s3,488(sp)
    80004db0:	f3d2                	sd	s4,480(sp)
    80004db2:	efd6                	sd	s5,472(sp)
    80004db4:	ebda                	sd	s6,464(sp)
    80004db6:	e7de                	sd	s7,456(sp)
    80004db8:	e3e2                	sd	s8,448(sp)
    80004dba:	ff66                	sd	s9,440(sp)
    80004dbc:	fb6a                	sd	s10,432(sp)
    80004dbe:	f76e                	sd	s11,424(sp)
    80004dc0:	0c00                	addi	s0,sp,528
    80004dc2:	84aa                	mv	s1,a0
    80004dc4:	dea43c23          	sd	a0,-520(s0)
    80004dc8:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004dcc:	ffffd097          	auipc	ra,0xffffd
    80004dd0:	bfa080e7          	jalr	-1030(ra) # 800019c6 <myproc>
    80004dd4:	892a                	mv	s2,a0

  begin_op();
    80004dd6:	fffff097          	auipc	ra,0xfffff
    80004dda:	474080e7          	jalr	1140(ra) # 8000424a <begin_op>

  if((ip = namei(path)) == 0){
    80004dde:	8526                	mv	a0,s1
    80004de0:	fffff097          	auipc	ra,0xfffff
    80004de4:	24e080e7          	jalr	590(ra) # 8000402e <namei>
    80004de8:	c92d                	beqz	a0,80004e5a <exec+0xbc>
    80004dea:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004dec:	fffff097          	auipc	ra,0xfffff
    80004df0:	a9c080e7          	jalr	-1380(ra) # 80003888 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004df4:	04000713          	li	a4,64
    80004df8:	4681                	li	a3,0
    80004dfa:	e5040613          	addi	a2,s0,-432
    80004dfe:	4581                	li	a1,0
    80004e00:	8526                	mv	a0,s1
    80004e02:	fffff097          	auipc	ra,0xfffff
    80004e06:	d3a080e7          	jalr	-710(ra) # 80003b3c <readi>
    80004e0a:	04000793          	li	a5,64
    80004e0e:	00f51a63          	bne	a0,a5,80004e22 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004e12:	e5042703          	lw	a4,-432(s0)
    80004e16:	464c47b7          	lui	a5,0x464c4
    80004e1a:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004e1e:	04f70463          	beq	a4,a5,80004e66 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004e22:	8526                	mv	a0,s1
    80004e24:	fffff097          	auipc	ra,0xfffff
    80004e28:	cc6080e7          	jalr	-826(ra) # 80003aea <iunlockput>
    end_op();
    80004e2c:	fffff097          	auipc	ra,0xfffff
    80004e30:	49e080e7          	jalr	1182(ra) # 800042ca <end_op>
  }
  return -1;
    80004e34:	557d                	li	a0,-1
}
    80004e36:	20813083          	ld	ra,520(sp)
    80004e3a:	20013403          	ld	s0,512(sp)
    80004e3e:	74fe                	ld	s1,504(sp)
    80004e40:	795e                	ld	s2,496(sp)
    80004e42:	79be                	ld	s3,488(sp)
    80004e44:	7a1e                	ld	s4,480(sp)
    80004e46:	6afe                	ld	s5,472(sp)
    80004e48:	6b5e                	ld	s6,464(sp)
    80004e4a:	6bbe                	ld	s7,456(sp)
    80004e4c:	6c1e                	ld	s8,448(sp)
    80004e4e:	7cfa                	ld	s9,440(sp)
    80004e50:	7d5a                	ld	s10,432(sp)
    80004e52:	7dba                	ld	s11,424(sp)
    80004e54:	21010113          	addi	sp,sp,528
    80004e58:	8082                	ret
    end_op();
    80004e5a:	fffff097          	auipc	ra,0xfffff
    80004e5e:	470080e7          	jalr	1136(ra) # 800042ca <end_op>
    return -1;
    80004e62:	557d                	li	a0,-1
    80004e64:	bfc9                	j	80004e36 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004e66:	854a                	mv	a0,s2
    80004e68:	ffffd097          	auipc	ra,0xffffd
    80004e6c:	c22080e7          	jalr	-990(ra) # 80001a8a <proc_pagetable>
    80004e70:	8baa                	mv	s7,a0
    80004e72:	d945                	beqz	a0,80004e22 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e74:	e7042983          	lw	s3,-400(s0)
    80004e78:	e8845783          	lhu	a5,-376(s0)
    80004e7c:	c7ad                	beqz	a5,80004ee6 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004e7e:	4a01                	li	s4,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e80:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004e82:	6c85                	lui	s9,0x1
    80004e84:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004e88:	def43823          	sd	a5,-528(s0)
    80004e8c:	ac0d                	j	800050be <exec+0x320>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004e8e:	00004517          	auipc	a0,0x4
    80004e92:	a3a50513          	addi	a0,a0,-1478 # 800088c8 <syscalls+0x2a8>
    80004e96:	ffffb097          	auipc	ra,0xffffb
    80004e9a:	6ae080e7          	jalr	1710(ra) # 80000544 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004e9e:	8756                	mv	a4,s5
    80004ea0:	012d86bb          	addw	a3,s11,s2
    80004ea4:	4581                	li	a1,0
    80004ea6:	8526                	mv	a0,s1
    80004ea8:	fffff097          	auipc	ra,0xfffff
    80004eac:	c94080e7          	jalr	-876(ra) # 80003b3c <readi>
    80004eb0:	2501                	sext.w	a0,a0
    80004eb2:	1aaa9a63          	bne	s5,a0,80005066 <exec+0x2c8>
  for(i = 0; i < sz; i += PGSIZE){
    80004eb6:	6785                	lui	a5,0x1
    80004eb8:	0127893b          	addw	s2,a5,s2
    80004ebc:	77fd                	lui	a5,0xfffff
    80004ebe:	01478a3b          	addw	s4,a5,s4
    80004ec2:	1f897563          	bgeu	s2,s8,800050ac <exec+0x30e>
    pa = walkaddr(pagetable, va + i);
    80004ec6:	02091593          	slli	a1,s2,0x20
    80004eca:	9181                	srli	a1,a1,0x20
    80004ecc:	95ea                	add	a1,a1,s10
    80004ece:	855e                	mv	a0,s7
    80004ed0:	ffffc097          	auipc	ra,0xffffc
    80004ed4:	1a8080e7          	jalr	424(ra) # 80001078 <walkaddr>
    80004ed8:	862a                	mv	a2,a0
    if(pa == 0)
    80004eda:	d955                	beqz	a0,80004e8e <exec+0xf0>
      n = PGSIZE;
    80004edc:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004ede:	fd9a70e3          	bgeu	s4,s9,80004e9e <exec+0x100>
      n = sz - i;
    80004ee2:	8ad2                	mv	s5,s4
    80004ee4:	bf6d                	j	80004e9e <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004ee6:	4a01                	li	s4,0
  iunlockput(ip);
    80004ee8:	8526                	mv	a0,s1
    80004eea:	fffff097          	auipc	ra,0xfffff
    80004eee:	c00080e7          	jalr	-1024(ra) # 80003aea <iunlockput>
  end_op();
    80004ef2:	fffff097          	auipc	ra,0xfffff
    80004ef6:	3d8080e7          	jalr	984(ra) # 800042ca <end_op>
  p = myproc();
    80004efa:	ffffd097          	auipc	ra,0xffffd
    80004efe:	acc080e7          	jalr	-1332(ra) # 800019c6 <myproc>
    80004f02:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004f04:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004f08:	6785                	lui	a5,0x1
    80004f0a:	17fd                	addi	a5,a5,-1
    80004f0c:	9a3e                	add	s4,s4,a5
    80004f0e:	757d                	lui	a0,0xfffff
    80004f10:	00aa77b3          	and	a5,s4,a0
    80004f14:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004f18:	4691                	li	a3,4
    80004f1a:	6609                	lui	a2,0x2
    80004f1c:	963e                	add	a2,a2,a5
    80004f1e:	85be                	mv	a1,a5
    80004f20:	855e                	mv	a0,s7
    80004f22:	ffffc097          	auipc	ra,0xffffc
    80004f26:	50a080e7          	jalr	1290(ra) # 8000142c <uvmalloc>
    80004f2a:	8b2a                	mv	s6,a0
  ip = 0;
    80004f2c:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004f2e:	12050c63          	beqz	a0,80005066 <exec+0x2c8>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004f32:	75f9                	lui	a1,0xffffe
    80004f34:	95aa                	add	a1,a1,a0
    80004f36:	855e                	mv	a0,s7
    80004f38:	ffffc097          	auipc	ra,0xffffc
    80004f3c:	71a080e7          	jalr	1818(ra) # 80001652 <uvmclear>
  stackbase = sp - PGSIZE;
    80004f40:	7c7d                	lui	s8,0xfffff
    80004f42:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004f44:	e0043783          	ld	a5,-512(s0)
    80004f48:	6388                	ld	a0,0(a5)
    80004f4a:	c535                	beqz	a0,80004fb6 <exec+0x218>
    80004f4c:	e9040993          	addi	s3,s0,-368
    80004f50:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004f54:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004f56:	ffffc097          	auipc	ra,0xffffc
    80004f5a:	f14080e7          	jalr	-236(ra) # 80000e6a <strlen>
    80004f5e:	2505                	addiw	a0,a0,1
    80004f60:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004f64:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004f68:	13896663          	bltu	s2,s8,80005094 <exec+0x2f6>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004f6c:	e0043d83          	ld	s11,-512(s0)
    80004f70:	000dba03          	ld	s4,0(s11)
    80004f74:	8552                	mv	a0,s4
    80004f76:	ffffc097          	auipc	ra,0xffffc
    80004f7a:	ef4080e7          	jalr	-268(ra) # 80000e6a <strlen>
    80004f7e:	0015069b          	addiw	a3,a0,1
    80004f82:	8652                	mv	a2,s4
    80004f84:	85ca                	mv	a1,s2
    80004f86:	855e                	mv	a0,s7
    80004f88:	ffffc097          	auipc	ra,0xffffc
    80004f8c:	6fc080e7          	jalr	1788(ra) # 80001684 <copyout>
    80004f90:	10054663          	bltz	a0,8000509c <exec+0x2fe>
    ustack[argc] = sp;
    80004f94:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004f98:	0485                	addi	s1,s1,1
    80004f9a:	008d8793          	addi	a5,s11,8
    80004f9e:	e0f43023          	sd	a5,-512(s0)
    80004fa2:	008db503          	ld	a0,8(s11)
    80004fa6:	c911                	beqz	a0,80004fba <exec+0x21c>
    if(argc >= MAXARG)
    80004fa8:	09a1                	addi	s3,s3,8
    80004faa:	fb3c96e3          	bne	s9,s3,80004f56 <exec+0x1b8>
  sz = sz1;
    80004fae:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fb2:	4481                	li	s1,0
    80004fb4:	a84d                	j	80005066 <exec+0x2c8>
  sp = sz;
    80004fb6:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004fb8:	4481                	li	s1,0
  ustack[argc] = 0;
    80004fba:	00349793          	slli	a5,s1,0x3
    80004fbe:	f9040713          	addi	a4,s0,-112
    80004fc2:	97ba                	add	a5,a5,a4
    80004fc4:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004fc8:	00148693          	addi	a3,s1,1
    80004fcc:	068e                	slli	a3,a3,0x3
    80004fce:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004fd2:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004fd6:	01897663          	bgeu	s2,s8,80004fe2 <exec+0x244>
  sz = sz1;
    80004fda:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fde:	4481                	li	s1,0
    80004fe0:	a059                	j	80005066 <exec+0x2c8>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004fe2:	e9040613          	addi	a2,s0,-368
    80004fe6:	85ca                	mv	a1,s2
    80004fe8:	855e                	mv	a0,s7
    80004fea:	ffffc097          	auipc	ra,0xffffc
    80004fee:	69a080e7          	jalr	1690(ra) # 80001684 <copyout>
    80004ff2:	0a054963          	bltz	a0,800050a4 <exec+0x306>
  p->trapframe->a1 = sp;
    80004ff6:	058ab783          	ld	a5,88(s5)
    80004ffa:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004ffe:	df843783          	ld	a5,-520(s0)
    80005002:	0007c703          	lbu	a4,0(a5)
    80005006:	cf11                	beqz	a4,80005022 <exec+0x284>
    80005008:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000500a:	02f00693          	li	a3,47
    8000500e:	a039                	j	8000501c <exec+0x27e>
      last = s+1;
    80005010:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005014:	0785                	addi	a5,a5,1
    80005016:	fff7c703          	lbu	a4,-1(a5)
    8000501a:	c701                	beqz	a4,80005022 <exec+0x284>
    if(*s == '/')
    8000501c:	fed71ce3          	bne	a4,a3,80005014 <exec+0x276>
    80005020:	bfc5                	j	80005010 <exec+0x272>
  safestrcpy(p->name, last, sizeof(p->name));
    80005022:	4641                	li	a2,16
    80005024:	df843583          	ld	a1,-520(s0)
    80005028:	158a8513          	addi	a0,s5,344
    8000502c:	ffffc097          	auipc	ra,0xffffc
    80005030:	e0c080e7          	jalr	-500(ra) # 80000e38 <safestrcpy>
  oldpagetable = p->pagetable;
    80005034:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005038:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    8000503c:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005040:	058ab783          	ld	a5,88(s5)
    80005044:	e6843703          	ld	a4,-408(s0)
    80005048:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000504a:	058ab783          	ld	a5,88(s5)
    8000504e:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005052:	85ea                	mv	a1,s10
    80005054:	ffffd097          	auipc	ra,0xffffd
    80005058:	ad2080e7          	jalr	-1326(ra) # 80001b26 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000505c:	0004851b          	sext.w	a0,s1
    80005060:	bbd9                	j	80004e36 <exec+0x98>
    80005062:	e1443423          	sd	s4,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005066:	e0843583          	ld	a1,-504(s0)
    8000506a:	855e                	mv	a0,s7
    8000506c:	ffffd097          	auipc	ra,0xffffd
    80005070:	aba080e7          	jalr	-1350(ra) # 80001b26 <proc_freepagetable>
  if(ip){
    80005074:	da0497e3          	bnez	s1,80004e22 <exec+0x84>
  return -1;
    80005078:	557d                	li	a0,-1
    8000507a:	bb75                	j	80004e36 <exec+0x98>
    8000507c:	e1443423          	sd	s4,-504(s0)
    80005080:	b7dd                	j	80005066 <exec+0x2c8>
    80005082:	e1443423          	sd	s4,-504(s0)
    80005086:	b7c5                	j	80005066 <exec+0x2c8>
    80005088:	e1443423          	sd	s4,-504(s0)
    8000508c:	bfe9                	j	80005066 <exec+0x2c8>
    8000508e:	e1443423          	sd	s4,-504(s0)
    80005092:	bfd1                	j	80005066 <exec+0x2c8>
  sz = sz1;
    80005094:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005098:	4481                	li	s1,0
    8000509a:	b7f1                	j	80005066 <exec+0x2c8>
  sz = sz1;
    8000509c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050a0:	4481                	li	s1,0
    800050a2:	b7d1                	j	80005066 <exec+0x2c8>
  sz = sz1;
    800050a4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050a8:	4481                	li	s1,0
    800050aa:	bf75                	j	80005066 <exec+0x2c8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800050ac:	e0843a03          	ld	s4,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050b0:	2b05                	addiw	s6,s6,1
    800050b2:	0389899b          	addiw	s3,s3,56
    800050b6:	e8845783          	lhu	a5,-376(s0)
    800050ba:	e2fb57e3          	bge	s6,a5,80004ee8 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800050be:	2981                	sext.w	s3,s3
    800050c0:	03800713          	li	a4,56
    800050c4:	86ce                	mv	a3,s3
    800050c6:	e1840613          	addi	a2,s0,-488
    800050ca:	4581                	li	a1,0
    800050cc:	8526                	mv	a0,s1
    800050ce:	fffff097          	auipc	ra,0xfffff
    800050d2:	a6e080e7          	jalr	-1426(ra) # 80003b3c <readi>
    800050d6:	03800793          	li	a5,56
    800050da:	f8f514e3          	bne	a0,a5,80005062 <exec+0x2c4>
    if(ph.type != ELF_PROG_LOAD)
    800050de:	e1842783          	lw	a5,-488(s0)
    800050e2:	4705                	li	a4,1
    800050e4:	fce796e3          	bne	a5,a4,800050b0 <exec+0x312>
    if(ph.memsz < ph.filesz)
    800050e8:	e4043903          	ld	s2,-448(s0)
    800050ec:	e3843783          	ld	a5,-456(s0)
    800050f0:	f8f966e3          	bltu	s2,a5,8000507c <exec+0x2de>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800050f4:	e2843783          	ld	a5,-472(s0)
    800050f8:	993e                	add	s2,s2,a5
    800050fa:	f8f964e3          	bltu	s2,a5,80005082 <exec+0x2e4>
    if(ph.vaddr % PGSIZE != 0)
    800050fe:	df043703          	ld	a4,-528(s0)
    80005102:	8ff9                	and	a5,a5,a4
    80005104:	f3d1                	bnez	a5,80005088 <exec+0x2ea>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005106:	e1c42503          	lw	a0,-484(s0)
    8000510a:	00000097          	auipc	ra,0x0
    8000510e:	c78080e7          	jalr	-904(ra) # 80004d82 <flags2perm>
    80005112:	86aa                	mv	a3,a0
    80005114:	864a                	mv	a2,s2
    80005116:	85d2                	mv	a1,s4
    80005118:	855e                	mv	a0,s7
    8000511a:	ffffc097          	auipc	ra,0xffffc
    8000511e:	312080e7          	jalr	786(ra) # 8000142c <uvmalloc>
    80005122:	e0a43423          	sd	a0,-504(s0)
    80005126:	d525                	beqz	a0,8000508e <exec+0x2f0>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005128:	e2843d03          	ld	s10,-472(s0)
    8000512c:	e2042d83          	lw	s11,-480(s0)
    80005130:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005134:	f60c0ce3          	beqz	s8,800050ac <exec+0x30e>
    80005138:	8a62                	mv	s4,s8
    8000513a:	4901                	li	s2,0
    8000513c:	b369                	j	80004ec6 <exec+0x128>

000000008000513e <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000513e:	7179                	addi	sp,sp,-48
    80005140:	f406                	sd	ra,40(sp)
    80005142:	f022                	sd	s0,32(sp)
    80005144:	ec26                	sd	s1,24(sp)
    80005146:	e84a                	sd	s2,16(sp)
    80005148:	1800                	addi	s0,sp,48
    8000514a:	892e                	mv	s2,a1
    8000514c:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    8000514e:	fdc40593          	addi	a1,s0,-36
    80005152:	ffffe097          	auipc	ra,0xffffe
    80005156:	a24080e7          	jalr	-1500(ra) # 80002b76 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000515a:	fdc42703          	lw	a4,-36(s0)
    8000515e:	47bd                	li	a5,15
    80005160:	02e7eb63          	bltu	a5,a4,80005196 <argfd+0x58>
    80005164:	ffffd097          	auipc	ra,0xffffd
    80005168:	862080e7          	jalr	-1950(ra) # 800019c6 <myproc>
    8000516c:	fdc42703          	lw	a4,-36(s0)
    80005170:	01a70793          	addi	a5,a4,26
    80005174:	078e                	slli	a5,a5,0x3
    80005176:	953e                	add	a0,a0,a5
    80005178:	611c                	ld	a5,0(a0)
    8000517a:	c385                	beqz	a5,8000519a <argfd+0x5c>
    return -1;
  if(pfd)
    8000517c:	00090463          	beqz	s2,80005184 <argfd+0x46>
    *pfd = fd;
    80005180:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005184:	4501                	li	a0,0
  if(pf)
    80005186:	c091                	beqz	s1,8000518a <argfd+0x4c>
    *pf = f;
    80005188:	e09c                	sd	a5,0(s1)
}
    8000518a:	70a2                	ld	ra,40(sp)
    8000518c:	7402                	ld	s0,32(sp)
    8000518e:	64e2                	ld	s1,24(sp)
    80005190:	6942                	ld	s2,16(sp)
    80005192:	6145                	addi	sp,sp,48
    80005194:	8082                	ret
    return -1;
    80005196:	557d                	li	a0,-1
    80005198:	bfcd                	j	8000518a <argfd+0x4c>
    8000519a:	557d                	li	a0,-1
    8000519c:	b7fd                	j	8000518a <argfd+0x4c>

000000008000519e <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000519e:	1101                	addi	sp,sp,-32
    800051a0:	ec06                	sd	ra,24(sp)
    800051a2:	e822                	sd	s0,16(sp)
    800051a4:	e426                	sd	s1,8(sp)
    800051a6:	1000                	addi	s0,sp,32
    800051a8:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800051aa:	ffffd097          	auipc	ra,0xffffd
    800051ae:	81c080e7          	jalr	-2020(ra) # 800019c6 <myproc>
    800051b2:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800051b4:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd4e38>
    800051b8:	4501                	li	a0,0
    800051ba:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800051bc:	6398                	ld	a4,0(a5)
    800051be:	cb19                	beqz	a4,800051d4 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800051c0:	2505                	addiw	a0,a0,1
    800051c2:	07a1                	addi	a5,a5,8
    800051c4:	fed51ce3          	bne	a0,a3,800051bc <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800051c8:	557d                	li	a0,-1
}
    800051ca:	60e2                	ld	ra,24(sp)
    800051cc:	6442                	ld	s0,16(sp)
    800051ce:	64a2                	ld	s1,8(sp)
    800051d0:	6105                	addi	sp,sp,32
    800051d2:	8082                	ret
      p->ofile[fd] = f;
    800051d4:	01a50793          	addi	a5,a0,26
    800051d8:	078e                	slli	a5,a5,0x3
    800051da:	963e                	add	a2,a2,a5
    800051dc:	e204                	sd	s1,0(a2)
      return fd;
    800051de:	b7f5                	j	800051ca <fdalloc+0x2c>

00000000800051e0 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800051e0:	715d                	addi	sp,sp,-80
    800051e2:	e486                	sd	ra,72(sp)
    800051e4:	e0a2                	sd	s0,64(sp)
    800051e6:	fc26                	sd	s1,56(sp)
    800051e8:	f84a                	sd	s2,48(sp)
    800051ea:	f44e                	sd	s3,40(sp)
    800051ec:	f052                	sd	s4,32(sp)
    800051ee:	ec56                	sd	s5,24(sp)
    800051f0:	e85a                	sd	s6,16(sp)
    800051f2:	0880                	addi	s0,sp,80
    800051f4:	8b2e                	mv	s6,a1
    800051f6:	89b2                	mv	s3,a2
    800051f8:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800051fa:	fb040593          	addi	a1,s0,-80
    800051fe:	fffff097          	auipc	ra,0xfffff
    80005202:	e4e080e7          	jalr	-434(ra) # 8000404c <nameiparent>
    80005206:	84aa                	mv	s1,a0
    80005208:	16050063          	beqz	a0,80005368 <create+0x188>
    return 0;

  ilock(dp);
    8000520c:	ffffe097          	auipc	ra,0xffffe
    80005210:	67c080e7          	jalr	1660(ra) # 80003888 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005214:	4601                	li	a2,0
    80005216:	fb040593          	addi	a1,s0,-80
    8000521a:	8526                	mv	a0,s1
    8000521c:	fffff097          	auipc	ra,0xfffff
    80005220:	b50080e7          	jalr	-1200(ra) # 80003d6c <dirlookup>
    80005224:	8aaa                	mv	s5,a0
    80005226:	c931                	beqz	a0,8000527a <create+0x9a>
    iunlockput(dp);
    80005228:	8526                	mv	a0,s1
    8000522a:	fffff097          	auipc	ra,0xfffff
    8000522e:	8c0080e7          	jalr	-1856(ra) # 80003aea <iunlockput>
    ilock(ip);
    80005232:	8556                	mv	a0,s5
    80005234:	ffffe097          	auipc	ra,0xffffe
    80005238:	654080e7          	jalr	1620(ra) # 80003888 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000523c:	000b059b          	sext.w	a1,s6
    80005240:	4789                	li	a5,2
    80005242:	02f59563          	bne	a1,a5,8000526c <create+0x8c>
    80005246:	044ad783          	lhu	a5,68(s5)
    8000524a:	37f9                	addiw	a5,a5,-2
    8000524c:	17c2                	slli	a5,a5,0x30
    8000524e:	93c1                	srli	a5,a5,0x30
    80005250:	4705                	li	a4,1
    80005252:	00f76d63          	bltu	a4,a5,8000526c <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005256:	8556                	mv	a0,s5
    80005258:	60a6                	ld	ra,72(sp)
    8000525a:	6406                	ld	s0,64(sp)
    8000525c:	74e2                	ld	s1,56(sp)
    8000525e:	7942                	ld	s2,48(sp)
    80005260:	79a2                	ld	s3,40(sp)
    80005262:	7a02                	ld	s4,32(sp)
    80005264:	6ae2                	ld	s5,24(sp)
    80005266:	6b42                	ld	s6,16(sp)
    80005268:	6161                	addi	sp,sp,80
    8000526a:	8082                	ret
    iunlockput(ip);
    8000526c:	8556                	mv	a0,s5
    8000526e:	fffff097          	auipc	ra,0xfffff
    80005272:	87c080e7          	jalr	-1924(ra) # 80003aea <iunlockput>
    return 0;
    80005276:	4a81                	li	s5,0
    80005278:	bff9                	j	80005256 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    8000527a:	85da                	mv	a1,s6
    8000527c:	4088                	lw	a0,0(s1)
    8000527e:	ffffe097          	auipc	ra,0xffffe
    80005282:	46e080e7          	jalr	1134(ra) # 800036ec <ialloc>
    80005286:	8a2a                	mv	s4,a0
    80005288:	c921                	beqz	a0,800052d8 <create+0xf8>
  ilock(ip);
    8000528a:	ffffe097          	auipc	ra,0xffffe
    8000528e:	5fe080e7          	jalr	1534(ra) # 80003888 <ilock>
  ip->major = major;
    80005292:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005296:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    8000529a:	4785                	li	a5,1
    8000529c:	04fa1523          	sh	a5,74(s4)
  iupdate(ip);
    800052a0:	8552                	mv	a0,s4
    800052a2:	ffffe097          	auipc	ra,0xffffe
    800052a6:	51c080e7          	jalr	1308(ra) # 800037be <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800052aa:	000b059b          	sext.w	a1,s6
    800052ae:	4785                	li	a5,1
    800052b0:	02f58b63          	beq	a1,a5,800052e6 <create+0x106>
  if(dirlink(dp, name, ip->inum) < 0)
    800052b4:	004a2603          	lw	a2,4(s4)
    800052b8:	fb040593          	addi	a1,s0,-80
    800052bc:	8526                	mv	a0,s1
    800052be:	fffff097          	auipc	ra,0xfffff
    800052c2:	cbe080e7          	jalr	-834(ra) # 80003f7c <dirlink>
    800052c6:	06054f63          	bltz	a0,80005344 <create+0x164>
  iunlockput(dp);
    800052ca:	8526                	mv	a0,s1
    800052cc:	fffff097          	auipc	ra,0xfffff
    800052d0:	81e080e7          	jalr	-2018(ra) # 80003aea <iunlockput>
  return ip;
    800052d4:	8ad2                	mv	s5,s4
    800052d6:	b741                	j	80005256 <create+0x76>
    iunlockput(dp);
    800052d8:	8526                	mv	a0,s1
    800052da:	fffff097          	auipc	ra,0xfffff
    800052de:	810080e7          	jalr	-2032(ra) # 80003aea <iunlockput>
    return 0;
    800052e2:	8ad2                	mv	s5,s4
    800052e4:	bf8d                	j	80005256 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800052e6:	004a2603          	lw	a2,4(s4)
    800052ea:	00003597          	auipc	a1,0x3
    800052ee:	5fe58593          	addi	a1,a1,1534 # 800088e8 <syscalls+0x2c8>
    800052f2:	8552                	mv	a0,s4
    800052f4:	fffff097          	auipc	ra,0xfffff
    800052f8:	c88080e7          	jalr	-888(ra) # 80003f7c <dirlink>
    800052fc:	04054463          	bltz	a0,80005344 <create+0x164>
    80005300:	40d0                	lw	a2,4(s1)
    80005302:	00003597          	auipc	a1,0x3
    80005306:	5ee58593          	addi	a1,a1,1518 # 800088f0 <syscalls+0x2d0>
    8000530a:	8552                	mv	a0,s4
    8000530c:	fffff097          	auipc	ra,0xfffff
    80005310:	c70080e7          	jalr	-912(ra) # 80003f7c <dirlink>
    80005314:	02054863          	bltz	a0,80005344 <create+0x164>
  if(dirlink(dp, name, ip->inum) < 0)
    80005318:	004a2603          	lw	a2,4(s4)
    8000531c:	fb040593          	addi	a1,s0,-80
    80005320:	8526                	mv	a0,s1
    80005322:	fffff097          	auipc	ra,0xfffff
    80005326:	c5a080e7          	jalr	-934(ra) # 80003f7c <dirlink>
    8000532a:	00054d63          	bltz	a0,80005344 <create+0x164>
    dp->nlink++;  // for ".."
    8000532e:	04a4d783          	lhu	a5,74(s1)
    80005332:	2785                	addiw	a5,a5,1
    80005334:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005338:	8526                	mv	a0,s1
    8000533a:	ffffe097          	auipc	ra,0xffffe
    8000533e:	484080e7          	jalr	1156(ra) # 800037be <iupdate>
    80005342:	b761                	j	800052ca <create+0xea>
  ip->nlink = 0;
    80005344:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005348:	8552                	mv	a0,s4
    8000534a:	ffffe097          	auipc	ra,0xffffe
    8000534e:	474080e7          	jalr	1140(ra) # 800037be <iupdate>
  iunlockput(ip);
    80005352:	8552                	mv	a0,s4
    80005354:	ffffe097          	auipc	ra,0xffffe
    80005358:	796080e7          	jalr	1942(ra) # 80003aea <iunlockput>
  iunlockput(dp);
    8000535c:	8526                	mv	a0,s1
    8000535e:	ffffe097          	auipc	ra,0xffffe
    80005362:	78c080e7          	jalr	1932(ra) # 80003aea <iunlockput>
  return 0;
    80005366:	bdc5                	j	80005256 <create+0x76>
    return 0;
    80005368:	8aaa                	mv	s5,a0
    8000536a:	b5f5                	j	80005256 <create+0x76>

000000008000536c <sys_dup>:
{
    8000536c:	7179                	addi	sp,sp,-48
    8000536e:	f406                	sd	ra,40(sp)
    80005370:	f022                	sd	s0,32(sp)
    80005372:	ec26                	sd	s1,24(sp)
    80005374:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005376:	fd840613          	addi	a2,s0,-40
    8000537a:	4581                	li	a1,0
    8000537c:	4501                	li	a0,0
    8000537e:	00000097          	auipc	ra,0x0
    80005382:	dc0080e7          	jalr	-576(ra) # 8000513e <argfd>
    return -1;
    80005386:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005388:	02054363          	bltz	a0,800053ae <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000538c:	fd843503          	ld	a0,-40(s0)
    80005390:	00000097          	auipc	ra,0x0
    80005394:	e0e080e7          	jalr	-498(ra) # 8000519e <fdalloc>
    80005398:	84aa                	mv	s1,a0
    return -1;
    8000539a:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000539c:	00054963          	bltz	a0,800053ae <sys_dup+0x42>
  filedup(f);
    800053a0:	fd843503          	ld	a0,-40(s0)
    800053a4:	fffff097          	auipc	ra,0xfffff
    800053a8:	320080e7          	jalr	800(ra) # 800046c4 <filedup>
  return fd;
    800053ac:	87a6                	mv	a5,s1
}
    800053ae:	853e                	mv	a0,a5
    800053b0:	70a2                	ld	ra,40(sp)
    800053b2:	7402                	ld	s0,32(sp)
    800053b4:	64e2                	ld	s1,24(sp)
    800053b6:	6145                	addi	sp,sp,48
    800053b8:	8082                	ret

00000000800053ba <sys_read>:
{
    800053ba:	7179                	addi	sp,sp,-48
    800053bc:	f406                	sd	ra,40(sp)
    800053be:	f022                	sd	s0,32(sp)
    800053c0:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800053c2:	fd840593          	addi	a1,s0,-40
    800053c6:	4505                	li	a0,1
    800053c8:	ffffd097          	auipc	ra,0xffffd
    800053cc:	7ce080e7          	jalr	1998(ra) # 80002b96 <argaddr>
  argint(2, &n);
    800053d0:	fe440593          	addi	a1,s0,-28
    800053d4:	4509                	li	a0,2
    800053d6:	ffffd097          	auipc	ra,0xffffd
    800053da:	7a0080e7          	jalr	1952(ra) # 80002b76 <argint>
  if(argfd(0, 0, &f) < 0)
    800053de:	fe840613          	addi	a2,s0,-24
    800053e2:	4581                	li	a1,0
    800053e4:	4501                	li	a0,0
    800053e6:	00000097          	auipc	ra,0x0
    800053ea:	d58080e7          	jalr	-680(ra) # 8000513e <argfd>
    800053ee:	87aa                	mv	a5,a0
    return -1;
    800053f0:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800053f2:	0007cc63          	bltz	a5,8000540a <sys_read+0x50>
  return fileread(f, p, n);
    800053f6:	fe442603          	lw	a2,-28(s0)
    800053fa:	fd843583          	ld	a1,-40(s0)
    800053fe:	fe843503          	ld	a0,-24(s0)
    80005402:	fffff097          	auipc	ra,0xfffff
    80005406:	44e080e7          	jalr	1102(ra) # 80004850 <fileread>
}
    8000540a:	70a2                	ld	ra,40(sp)
    8000540c:	7402                	ld	s0,32(sp)
    8000540e:	6145                	addi	sp,sp,48
    80005410:	8082                	ret

0000000080005412 <sys_write>:
{
    80005412:	7179                	addi	sp,sp,-48
    80005414:	f406                	sd	ra,40(sp)
    80005416:	f022                	sd	s0,32(sp)
    80005418:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000541a:	fd840593          	addi	a1,s0,-40
    8000541e:	4505                	li	a0,1
    80005420:	ffffd097          	auipc	ra,0xffffd
    80005424:	776080e7          	jalr	1910(ra) # 80002b96 <argaddr>
  argint(2, &n);
    80005428:	fe440593          	addi	a1,s0,-28
    8000542c:	4509                	li	a0,2
    8000542e:	ffffd097          	auipc	ra,0xffffd
    80005432:	748080e7          	jalr	1864(ra) # 80002b76 <argint>
  if(argfd(0, 0, &f) < 0)
    80005436:	fe840613          	addi	a2,s0,-24
    8000543a:	4581                	li	a1,0
    8000543c:	4501                	li	a0,0
    8000543e:	00000097          	auipc	ra,0x0
    80005442:	d00080e7          	jalr	-768(ra) # 8000513e <argfd>
    80005446:	87aa                	mv	a5,a0
    return -1;
    80005448:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000544a:	0007cc63          	bltz	a5,80005462 <sys_write+0x50>
  return filewrite(f, p, n);
    8000544e:	fe442603          	lw	a2,-28(s0)
    80005452:	fd843583          	ld	a1,-40(s0)
    80005456:	fe843503          	ld	a0,-24(s0)
    8000545a:	fffff097          	auipc	ra,0xfffff
    8000545e:	4b8080e7          	jalr	1208(ra) # 80004912 <filewrite>
}
    80005462:	70a2                	ld	ra,40(sp)
    80005464:	7402                	ld	s0,32(sp)
    80005466:	6145                	addi	sp,sp,48
    80005468:	8082                	ret

000000008000546a <sys_close>:
{
    8000546a:	1101                	addi	sp,sp,-32
    8000546c:	ec06                	sd	ra,24(sp)
    8000546e:	e822                	sd	s0,16(sp)
    80005470:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005472:	fe040613          	addi	a2,s0,-32
    80005476:	fec40593          	addi	a1,s0,-20
    8000547a:	4501                	li	a0,0
    8000547c:	00000097          	auipc	ra,0x0
    80005480:	cc2080e7          	jalr	-830(ra) # 8000513e <argfd>
    return -1;
    80005484:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005486:	02054463          	bltz	a0,800054ae <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000548a:	ffffc097          	auipc	ra,0xffffc
    8000548e:	53c080e7          	jalr	1340(ra) # 800019c6 <myproc>
    80005492:	fec42783          	lw	a5,-20(s0)
    80005496:	07e9                	addi	a5,a5,26
    80005498:	078e                	slli	a5,a5,0x3
    8000549a:	97aa                	add	a5,a5,a0
    8000549c:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800054a0:	fe043503          	ld	a0,-32(s0)
    800054a4:	fffff097          	auipc	ra,0xfffff
    800054a8:	272080e7          	jalr	626(ra) # 80004716 <fileclose>
  return 0;
    800054ac:	4781                	li	a5,0
}
    800054ae:	853e                	mv	a0,a5
    800054b0:	60e2                	ld	ra,24(sp)
    800054b2:	6442                	ld	s0,16(sp)
    800054b4:	6105                	addi	sp,sp,32
    800054b6:	8082                	ret

00000000800054b8 <sys_fstat>:
{
    800054b8:	1101                	addi	sp,sp,-32
    800054ba:	ec06                	sd	ra,24(sp)
    800054bc:	e822                	sd	s0,16(sp)
    800054be:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800054c0:	fe040593          	addi	a1,s0,-32
    800054c4:	4505                	li	a0,1
    800054c6:	ffffd097          	auipc	ra,0xffffd
    800054ca:	6d0080e7          	jalr	1744(ra) # 80002b96 <argaddr>
  if(argfd(0, 0, &f) < 0)
    800054ce:	fe840613          	addi	a2,s0,-24
    800054d2:	4581                	li	a1,0
    800054d4:	4501                	li	a0,0
    800054d6:	00000097          	auipc	ra,0x0
    800054da:	c68080e7          	jalr	-920(ra) # 8000513e <argfd>
    800054de:	87aa                	mv	a5,a0
    return -1;
    800054e0:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800054e2:	0007ca63          	bltz	a5,800054f6 <sys_fstat+0x3e>
  return filestat(f, st);
    800054e6:	fe043583          	ld	a1,-32(s0)
    800054ea:	fe843503          	ld	a0,-24(s0)
    800054ee:	fffff097          	auipc	ra,0xfffff
    800054f2:	2f0080e7          	jalr	752(ra) # 800047de <filestat>
}
    800054f6:	60e2                	ld	ra,24(sp)
    800054f8:	6442                	ld	s0,16(sp)
    800054fa:	6105                	addi	sp,sp,32
    800054fc:	8082                	ret

00000000800054fe <sys_link>:
{
    800054fe:	7169                	addi	sp,sp,-304
    80005500:	f606                	sd	ra,296(sp)
    80005502:	f222                	sd	s0,288(sp)
    80005504:	ee26                	sd	s1,280(sp)
    80005506:	ea4a                	sd	s2,272(sp)
    80005508:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000550a:	08000613          	li	a2,128
    8000550e:	ed040593          	addi	a1,s0,-304
    80005512:	4501                	li	a0,0
    80005514:	ffffd097          	auipc	ra,0xffffd
    80005518:	6a2080e7          	jalr	1698(ra) # 80002bb6 <argstr>
    return -1;
    8000551c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000551e:	10054e63          	bltz	a0,8000563a <sys_link+0x13c>
    80005522:	08000613          	li	a2,128
    80005526:	f5040593          	addi	a1,s0,-176
    8000552a:	4505                	li	a0,1
    8000552c:	ffffd097          	auipc	ra,0xffffd
    80005530:	68a080e7          	jalr	1674(ra) # 80002bb6 <argstr>
    return -1;
    80005534:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005536:	10054263          	bltz	a0,8000563a <sys_link+0x13c>
  begin_op();
    8000553a:	fffff097          	auipc	ra,0xfffff
    8000553e:	d10080e7          	jalr	-752(ra) # 8000424a <begin_op>
  if((ip = namei(old)) == 0){
    80005542:	ed040513          	addi	a0,s0,-304
    80005546:	fffff097          	auipc	ra,0xfffff
    8000554a:	ae8080e7          	jalr	-1304(ra) # 8000402e <namei>
    8000554e:	84aa                	mv	s1,a0
    80005550:	c551                	beqz	a0,800055dc <sys_link+0xde>
  ilock(ip);
    80005552:	ffffe097          	auipc	ra,0xffffe
    80005556:	336080e7          	jalr	822(ra) # 80003888 <ilock>
  if(ip->type == T_DIR){
    8000555a:	04449703          	lh	a4,68(s1)
    8000555e:	4785                	li	a5,1
    80005560:	08f70463          	beq	a4,a5,800055e8 <sys_link+0xea>
  ip->nlink++;
    80005564:	04a4d783          	lhu	a5,74(s1)
    80005568:	2785                	addiw	a5,a5,1
    8000556a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000556e:	8526                	mv	a0,s1
    80005570:	ffffe097          	auipc	ra,0xffffe
    80005574:	24e080e7          	jalr	590(ra) # 800037be <iupdate>
  iunlock(ip);
    80005578:	8526                	mv	a0,s1
    8000557a:	ffffe097          	auipc	ra,0xffffe
    8000557e:	3d0080e7          	jalr	976(ra) # 8000394a <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005582:	fd040593          	addi	a1,s0,-48
    80005586:	f5040513          	addi	a0,s0,-176
    8000558a:	fffff097          	auipc	ra,0xfffff
    8000558e:	ac2080e7          	jalr	-1342(ra) # 8000404c <nameiparent>
    80005592:	892a                	mv	s2,a0
    80005594:	c935                	beqz	a0,80005608 <sys_link+0x10a>
  ilock(dp);
    80005596:	ffffe097          	auipc	ra,0xffffe
    8000559a:	2f2080e7          	jalr	754(ra) # 80003888 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000559e:	00092703          	lw	a4,0(s2)
    800055a2:	409c                	lw	a5,0(s1)
    800055a4:	04f71d63          	bne	a4,a5,800055fe <sys_link+0x100>
    800055a8:	40d0                	lw	a2,4(s1)
    800055aa:	fd040593          	addi	a1,s0,-48
    800055ae:	854a                	mv	a0,s2
    800055b0:	fffff097          	auipc	ra,0xfffff
    800055b4:	9cc080e7          	jalr	-1588(ra) # 80003f7c <dirlink>
    800055b8:	04054363          	bltz	a0,800055fe <sys_link+0x100>
  iunlockput(dp);
    800055bc:	854a                	mv	a0,s2
    800055be:	ffffe097          	auipc	ra,0xffffe
    800055c2:	52c080e7          	jalr	1324(ra) # 80003aea <iunlockput>
  iput(ip);
    800055c6:	8526                	mv	a0,s1
    800055c8:	ffffe097          	auipc	ra,0xffffe
    800055cc:	47a080e7          	jalr	1146(ra) # 80003a42 <iput>
  end_op();
    800055d0:	fffff097          	auipc	ra,0xfffff
    800055d4:	cfa080e7          	jalr	-774(ra) # 800042ca <end_op>
  return 0;
    800055d8:	4781                	li	a5,0
    800055da:	a085                	j	8000563a <sys_link+0x13c>
    end_op();
    800055dc:	fffff097          	auipc	ra,0xfffff
    800055e0:	cee080e7          	jalr	-786(ra) # 800042ca <end_op>
    return -1;
    800055e4:	57fd                	li	a5,-1
    800055e6:	a891                	j	8000563a <sys_link+0x13c>
    iunlockput(ip);
    800055e8:	8526                	mv	a0,s1
    800055ea:	ffffe097          	auipc	ra,0xffffe
    800055ee:	500080e7          	jalr	1280(ra) # 80003aea <iunlockput>
    end_op();
    800055f2:	fffff097          	auipc	ra,0xfffff
    800055f6:	cd8080e7          	jalr	-808(ra) # 800042ca <end_op>
    return -1;
    800055fa:	57fd                	li	a5,-1
    800055fc:	a83d                	j	8000563a <sys_link+0x13c>
    iunlockput(dp);
    800055fe:	854a                	mv	a0,s2
    80005600:	ffffe097          	auipc	ra,0xffffe
    80005604:	4ea080e7          	jalr	1258(ra) # 80003aea <iunlockput>
  ilock(ip);
    80005608:	8526                	mv	a0,s1
    8000560a:	ffffe097          	auipc	ra,0xffffe
    8000560e:	27e080e7          	jalr	638(ra) # 80003888 <ilock>
  ip->nlink--;
    80005612:	04a4d783          	lhu	a5,74(s1)
    80005616:	37fd                	addiw	a5,a5,-1
    80005618:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000561c:	8526                	mv	a0,s1
    8000561e:	ffffe097          	auipc	ra,0xffffe
    80005622:	1a0080e7          	jalr	416(ra) # 800037be <iupdate>
  iunlockput(ip);
    80005626:	8526                	mv	a0,s1
    80005628:	ffffe097          	auipc	ra,0xffffe
    8000562c:	4c2080e7          	jalr	1218(ra) # 80003aea <iunlockput>
  end_op();
    80005630:	fffff097          	auipc	ra,0xfffff
    80005634:	c9a080e7          	jalr	-870(ra) # 800042ca <end_op>
  return -1;
    80005638:	57fd                	li	a5,-1
}
    8000563a:	853e                	mv	a0,a5
    8000563c:	70b2                	ld	ra,296(sp)
    8000563e:	7412                	ld	s0,288(sp)
    80005640:	64f2                	ld	s1,280(sp)
    80005642:	6952                	ld	s2,272(sp)
    80005644:	6155                	addi	sp,sp,304
    80005646:	8082                	ret

0000000080005648 <sys_unlink>:
{
    80005648:	7151                	addi	sp,sp,-240
    8000564a:	f586                	sd	ra,232(sp)
    8000564c:	f1a2                	sd	s0,224(sp)
    8000564e:	eda6                	sd	s1,216(sp)
    80005650:	e9ca                	sd	s2,208(sp)
    80005652:	e5ce                	sd	s3,200(sp)
    80005654:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005656:	08000613          	li	a2,128
    8000565a:	f3040593          	addi	a1,s0,-208
    8000565e:	4501                	li	a0,0
    80005660:	ffffd097          	auipc	ra,0xffffd
    80005664:	556080e7          	jalr	1366(ra) # 80002bb6 <argstr>
    80005668:	18054163          	bltz	a0,800057ea <sys_unlink+0x1a2>
  begin_op();
    8000566c:	fffff097          	auipc	ra,0xfffff
    80005670:	bde080e7          	jalr	-1058(ra) # 8000424a <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005674:	fb040593          	addi	a1,s0,-80
    80005678:	f3040513          	addi	a0,s0,-208
    8000567c:	fffff097          	auipc	ra,0xfffff
    80005680:	9d0080e7          	jalr	-1584(ra) # 8000404c <nameiparent>
    80005684:	84aa                	mv	s1,a0
    80005686:	c979                	beqz	a0,8000575c <sys_unlink+0x114>
  ilock(dp);
    80005688:	ffffe097          	auipc	ra,0xffffe
    8000568c:	200080e7          	jalr	512(ra) # 80003888 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005690:	00003597          	auipc	a1,0x3
    80005694:	25858593          	addi	a1,a1,600 # 800088e8 <syscalls+0x2c8>
    80005698:	fb040513          	addi	a0,s0,-80
    8000569c:	ffffe097          	auipc	ra,0xffffe
    800056a0:	6b6080e7          	jalr	1718(ra) # 80003d52 <namecmp>
    800056a4:	14050a63          	beqz	a0,800057f8 <sys_unlink+0x1b0>
    800056a8:	00003597          	auipc	a1,0x3
    800056ac:	24858593          	addi	a1,a1,584 # 800088f0 <syscalls+0x2d0>
    800056b0:	fb040513          	addi	a0,s0,-80
    800056b4:	ffffe097          	auipc	ra,0xffffe
    800056b8:	69e080e7          	jalr	1694(ra) # 80003d52 <namecmp>
    800056bc:	12050e63          	beqz	a0,800057f8 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800056c0:	f2c40613          	addi	a2,s0,-212
    800056c4:	fb040593          	addi	a1,s0,-80
    800056c8:	8526                	mv	a0,s1
    800056ca:	ffffe097          	auipc	ra,0xffffe
    800056ce:	6a2080e7          	jalr	1698(ra) # 80003d6c <dirlookup>
    800056d2:	892a                	mv	s2,a0
    800056d4:	12050263          	beqz	a0,800057f8 <sys_unlink+0x1b0>
  ilock(ip);
    800056d8:	ffffe097          	auipc	ra,0xffffe
    800056dc:	1b0080e7          	jalr	432(ra) # 80003888 <ilock>
  if(ip->nlink < 1)
    800056e0:	04a91783          	lh	a5,74(s2)
    800056e4:	08f05263          	blez	a5,80005768 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800056e8:	04491703          	lh	a4,68(s2)
    800056ec:	4785                	li	a5,1
    800056ee:	08f70563          	beq	a4,a5,80005778 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800056f2:	4641                	li	a2,16
    800056f4:	4581                	li	a1,0
    800056f6:	fc040513          	addi	a0,s0,-64
    800056fa:	ffffb097          	auipc	ra,0xffffb
    800056fe:	5ec080e7          	jalr	1516(ra) # 80000ce6 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005702:	4741                	li	a4,16
    80005704:	f2c42683          	lw	a3,-212(s0)
    80005708:	fc040613          	addi	a2,s0,-64
    8000570c:	4581                	li	a1,0
    8000570e:	8526                	mv	a0,s1
    80005710:	ffffe097          	auipc	ra,0xffffe
    80005714:	524080e7          	jalr	1316(ra) # 80003c34 <writei>
    80005718:	47c1                	li	a5,16
    8000571a:	0af51563          	bne	a0,a5,800057c4 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000571e:	04491703          	lh	a4,68(s2)
    80005722:	4785                	li	a5,1
    80005724:	0af70863          	beq	a4,a5,800057d4 <sys_unlink+0x18c>
  iunlockput(dp);
    80005728:	8526                	mv	a0,s1
    8000572a:	ffffe097          	auipc	ra,0xffffe
    8000572e:	3c0080e7          	jalr	960(ra) # 80003aea <iunlockput>
  ip->nlink--;
    80005732:	04a95783          	lhu	a5,74(s2)
    80005736:	37fd                	addiw	a5,a5,-1
    80005738:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000573c:	854a                	mv	a0,s2
    8000573e:	ffffe097          	auipc	ra,0xffffe
    80005742:	080080e7          	jalr	128(ra) # 800037be <iupdate>
  iunlockput(ip);
    80005746:	854a                	mv	a0,s2
    80005748:	ffffe097          	auipc	ra,0xffffe
    8000574c:	3a2080e7          	jalr	930(ra) # 80003aea <iunlockput>
  end_op();
    80005750:	fffff097          	auipc	ra,0xfffff
    80005754:	b7a080e7          	jalr	-1158(ra) # 800042ca <end_op>
  return 0;
    80005758:	4501                	li	a0,0
    8000575a:	a84d                	j	8000580c <sys_unlink+0x1c4>
    end_op();
    8000575c:	fffff097          	auipc	ra,0xfffff
    80005760:	b6e080e7          	jalr	-1170(ra) # 800042ca <end_op>
    return -1;
    80005764:	557d                	li	a0,-1
    80005766:	a05d                	j	8000580c <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005768:	00003517          	auipc	a0,0x3
    8000576c:	19050513          	addi	a0,a0,400 # 800088f8 <syscalls+0x2d8>
    80005770:	ffffb097          	auipc	ra,0xffffb
    80005774:	dd4080e7          	jalr	-556(ra) # 80000544 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005778:	04c92703          	lw	a4,76(s2)
    8000577c:	02000793          	li	a5,32
    80005780:	f6e7f9e3          	bgeu	a5,a4,800056f2 <sys_unlink+0xaa>
    80005784:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005788:	4741                	li	a4,16
    8000578a:	86ce                	mv	a3,s3
    8000578c:	f1840613          	addi	a2,s0,-232
    80005790:	4581                	li	a1,0
    80005792:	854a                	mv	a0,s2
    80005794:	ffffe097          	auipc	ra,0xffffe
    80005798:	3a8080e7          	jalr	936(ra) # 80003b3c <readi>
    8000579c:	47c1                	li	a5,16
    8000579e:	00f51b63          	bne	a0,a5,800057b4 <sys_unlink+0x16c>
    if(de.inum != 0)
    800057a2:	f1845783          	lhu	a5,-232(s0)
    800057a6:	e7a1                	bnez	a5,800057ee <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057a8:	29c1                	addiw	s3,s3,16
    800057aa:	04c92783          	lw	a5,76(s2)
    800057ae:	fcf9ede3          	bltu	s3,a5,80005788 <sys_unlink+0x140>
    800057b2:	b781                	j	800056f2 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800057b4:	00003517          	auipc	a0,0x3
    800057b8:	15c50513          	addi	a0,a0,348 # 80008910 <syscalls+0x2f0>
    800057bc:	ffffb097          	auipc	ra,0xffffb
    800057c0:	d88080e7          	jalr	-632(ra) # 80000544 <panic>
    panic("unlink: writei");
    800057c4:	00003517          	auipc	a0,0x3
    800057c8:	16450513          	addi	a0,a0,356 # 80008928 <syscalls+0x308>
    800057cc:	ffffb097          	auipc	ra,0xffffb
    800057d0:	d78080e7          	jalr	-648(ra) # 80000544 <panic>
    dp->nlink--;
    800057d4:	04a4d783          	lhu	a5,74(s1)
    800057d8:	37fd                	addiw	a5,a5,-1
    800057da:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800057de:	8526                	mv	a0,s1
    800057e0:	ffffe097          	auipc	ra,0xffffe
    800057e4:	fde080e7          	jalr	-34(ra) # 800037be <iupdate>
    800057e8:	b781                	j	80005728 <sys_unlink+0xe0>
    return -1;
    800057ea:	557d                	li	a0,-1
    800057ec:	a005                	j	8000580c <sys_unlink+0x1c4>
    iunlockput(ip);
    800057ee:	854a                	mv	a0,s2
    800057f0:	ffffe097          	auipc	ra,0xffffe
    800057f4:	2fa080e7          	jalr	762(ra) # 80003aea <iunlockput>
  iunlockput(dp);
    800057f8:	8526                	mv	a0,s1
    800057fa:	ffffe097          	auipc	ra,0xffffe
    800057fe:	2f0080e7          	jalr	752(ra) # 80003aea <iunlockput>
  end_op();
    80005802:	fffff097          	auipc	ra,0xfffff
    80005806:	ac8080e7          	jalr	-1336(ra) # 800042ca <end_op>
  return -1;
    8000580a:	557d                	li	a0,-1
}
    8000580c:	70ae                	ld	ra,232(sp)
    8000580e:	740e                	ld	s0,224(sp)
    80005810:	64ee                	ld	s1,216(sp)
    80005812:	694e                	ld	s2,208(sp)
    80005814:	69ae                	ld	s3,200(sp)
    80005816:	616d                	addi	sp,sp,240
    80005818:	8082                	ret

000000008000581a <sys_open>:

uint64
sys_open(void)
{
    8000581a:	7131                	addi	sp,sp,-192
    8000581c:	fd06                	sd	ra,184(sp)
    8000581e:	f922                	sd	s0,176(sp)
    80005820:	f526                	sd	s1,168(sp)
    80005822:	f14a                	sd	s2,160(sp)
    80005824:	ed4e                	sd	s3,152(sp)
    80005826:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005828:	f4c40593          	addi	a1,s0,-180
    8000582c:	4505                	li	a0,1
    8000582e:	ffffd097          	auipc	ra,0xffffd
    80005832:	348080e7          	jalr	840(ra) # 80002b76 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005836:	08000613          	li	a2,128
    8000583a:	f5040593          	addi	a1,s0,-176
    8000583e:	4501                	li	a0,0
    80005840:	ffffd097          	auipc	ra,0xffffd
    80005844:	376080e7          	jalr	886(ra) # 80002bb6 <argstr>
    80005848:	87aa                	mv	a5,a0
    return -1;
    8000584a:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000584c:	0a07c963          	bltz	a5,800058fe <sys_open+0xe4>

  begin_op();
    80005850:	fffff097          	auipc	ra,0xfffff
    80005854:	9fa080e7          	jalr	-1542(ra) # 8000424a <begin_op>

  if(omode & O_CREATE){
    80005858:	f4c42783          	lw	a5,-180(s0)
    8000585c:	2007f793          	andi	a5,a5,512
    80005860:	cfc5                	beqz	a5,80005918 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005862:	4681                	li	a3,0
    80005864:	4601                	li	a2,0
    80005866:	4589                	li	a1,2
    80005868:	f5040513          	addi	a0,s0,-176
    8000586c:	00000097          	auipc	ra,0x0
    80005870:	974080e7          	jalr	-1676(ra) # 800051e0 <create>
    80005874:	84aa                	mv	s1,a0
    if(ip == 0){
    80005876:	c959                	beqz	a0,8000590c <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005878:	04449703          	lh	a4,68(s1)
    8000587c:	478d                	li	a5,3
    8000587e:	00f71763          	bne	a4,a5,8000588c <sys_open+0x72>
    80005882:	0464d703          	lhu	a4,70(s1)
    80005886:	47a5                	li	a5,9
    80005888:	0ce7ed63          	bltu	a5,a4,80005962 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000588c:	fffff097          	auipc	ra,0xfffff
    80005890:	dce080e7          	jalr	-562(ra) # 8000465a <filealloc>
    80005894:	89aa                	mv	s3,a0
    80005896:	10050363          	beqz	a0,8000599c <sys_open+0x182>
    8000589a:	00000097          	auipc	ra,0x0
    8000589e:	904080e7          	jalr	-1788(ra) # 8000519e <fdalloc>
    800058a2:	892a                	mv	s2,a0
    800058a4:	0e054763          	bltz	a0,80005992 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800058a8:	04449703          	lh	a4,68(s1)
    800058ac:	478d                	li	a5,3
    800058ae:	0cf70563          	beq	a4,a5,80005978 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800058b2:	4789                	li	a5,2
    800058b4:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800058b8:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800058bc:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    800058c0:	f4c42783          	lw	a5,-180(s0)
    800058c4:	0017c713          	xori	a4,a5,1
    800058c8:	8b05                	andi	a4,a4,1
    800058ca:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800058ce:	0037f713          	andi	a4,a5,3
    800058d2:	00e03733          	snez	a4,a4
    800058d6:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800058da:	4007f793          	andi	a5,a5,1024
    800058de:	c791                	beqz	a5,800058ea <sys_open+0xd0>
    800058e0:	04449703          	lh	a4,68(s1)
    800058e4:	4789                	li	a5,2
    800058e6:	0af70063          	beq	a4,a5,80005986 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800058ea:	8526                	mv	a0,s1
    800058ec:	ffffe097          	auipc	ra,0xffffe
    800058f0:	05e080e7          	jalr	94(ra) # 8000394a <iunlock>
  end_op();
    800058f4:	fffff097          	auipc	ra,0xfffff
    800058f8:	9d6080e7          	jalr	-1578(ra) # 800042ca <end_op>

  return fd;
    800058fc:	854a                	mv	a0,s2
}
    800058fe:	70ea                	ld	ra,184(sp)
    80005900:	744a                	ld	s0,176(sp)
    80005902:	74aa                	ld	s1,168(sp)
    80005904:	790a                	ld	s2,160(sp)
    80005906:	69ea                	ld	s3,152(sp)
    80005908:	6129                	addi	sp,sp,192
    8000590a:	8082                	ret
      end_op();
    8000590c:	fffff097          	auipc	ra,0xfffff
    80005910:	9be080e7          	jalr	-1602(ra) # 800042ca <end_op>
      return -1;
    80005914:	557d                	li	a0,-1
    80005916:	b7e5                	j	800058fe <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005918:	f5040513          	addi	a0,s0,-176
    8000591c:	ffffe097          	auipc	ra,0xffffe
    80005920:	712080e7          	jalr	1810(ra) # 8000402e <namei>
    80005924:	84aa                	mv	s1,a0
    80005926:	c905                	beqz	a0,80005956 <sys_open+0x13c>
    ilock(ip);
    80005928:	ffffe097          	auipc	ra,0xffffe
    8000592c:	f60080e7          	jalr	-160(ra) # 80003888 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005930:	04449703          	lh	a4,68(s1)
    80005934:	4785                	li	a5,1
    80005936:	f4f711e3          	bne	a4,a5,80005878 <sys_open+0x5e>
    8000593a:	f4c42783          	lw	a5,-180(s0)
    8000593e:	d7b9                	beqz	a5,8000588c <sys_open+0x72>
      iunlockput(ip);
    80005940:	8526                	mv	a0,s1
    80005942:	ffffe097          	auipc	ra,0xffffe
    80005946:	1a8080e7          	jalr	424(ra) # 80003aea <iunlockput>
      end_op();
    8000594a:	fffff097          	auipc	ra,0xfffff
    8000594e:	980080e7          	jalr	-1664(ra) # 800042ca <end_op>
      return -1;
    80005952:	557d                	li	a0,-1
    80005954:	b76d                	j	800058fe <sys_open+0xe4>
      end_op();
    80005956:	fffff097          	auipc	ra,0xfffff
    8000595a:	974080e7          	jalr	-1676(ra) # 800042ca <end_op>
      return -1;
    8000595e:	557d                	li	a0,-1
    80005960:	bf79                	j	800058fe <sys_open+0xe4>
    iunlockput(ip);
    80005962:	8526                	mv	a0,s1
    80005964:	ffffe097          	auipc	ra,0xffffe
    80005968:	186080e7          	jalr	390(ra) # 80003aea <iunlockput>
    end_op();
    8000596c:	fffff097          	auipc	ra,0xfffff
    80005970:	95e080e7          	jalr	-1698(ra) # 800042ca <end_op>
    return -1;
    80005974:	557d                	li	a0,-1
    80005976:	b761                	j	800058fe <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005978:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000597c:	04649783          	lh	a5,70(s1)
    80005980:	02f99223          	sh	a5,36(s3)
    80005984:	bf25                	j	800058bc <sys_open+0xa2>
    itrunc(ip);
    80005986:	8526                	mv	a0,s1
    80005988:	ffffe097          	auipc	ra,0xffffe
    8000598c:	00e080e7          	jalr	14(ra) # 80003996 <itrunc>
    80005990:	bfa9                	j	800058ea <sys_open+0xd0>
      fileclose(f);
    80005992:	854e                	mv	a0,s3
    80005994:	fffff097          	auipc	ra,0xfffff
    80005998:	d82080e7          	jalr	-638(ra) # 80004716 <fileclose>
    iunlockput(ip);
    8000599c:	8526                	mv	a0,s1
    8000599e:	ffffe097          	auipc	ra,0xffffe
    800059a2:	14c080e7          	jalr	332(ra) # 80003aea <iunlockput>
    end_op();
    800059a6:	fffff097          	auipc	ra,0xfffff
    800059aa:	924080e7          	jalr	-1756(ra) # 800042ca <end_op>
    return -1;
    800059ae:	557d                	li	a0,-1
    800059b0:	b7b9                	j	800058fe <sys_open+0xe4>

00000000800059b2 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800059b2:	7175                	addi	sp,sp,-144
    800059b4:	e506                	sd	ra,136(sp)
    800059b6:	e122                	sd	s0,128(sp)
    800059b8:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800059ba:	fffff097          	auipc	ra,0xfffff
    800059be:	890080e7          	jalr	-1904(ra) # 8000424a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800059c2:	08000613          	li	a2,128
    800059c6:	f7040593          	addi	a1,s0,-144
    800059ca:	4501                	li	a0,0
    800059cc:	ffffd097          	auipc	ra,0xffffd
    800059d0:	1ea080e7          	jalr	490(ra) # 80002bb6 <argstr>
    800059d4:	02054963          	bltz	a0,80005a06 <sys_mkdir+0x54>
    800059d8:	4681                	li	a3,0
    800059da:	4601                	li	a2,0
    800059dc:	4585                	li	a1,1
    800059de:	f7040513          	addi	a0,s0,-144
    800059e2:	fffff097          	auipc	ra,0xfffff
    800059e6:	7fe080e7          	jalr	2046(ra) # 800051e0 <create>
    800059ea:	cd11                	beqz	a0,80005a06 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800059ec:	ffffe097          	auipc	ra,0xffffe
    800059f0:	0fe080e7          	jalr	254(ra) # 80003aea <iunlockput>
  end_op();
    800059f4:	fffff097          	auipc	ra,0xfffff
    800059f8:	8d6080e7          	jalr	-1834(ra) # 800042ca <end_op>
  return 0;
    800059fc:	4501                	li	a0,0
}
    800059fe:	60aa                	ld	ra,136(sp)
    80005a00:	640a                	ld	s0,128(sp)
    80005a02:	6149                	addi	sp,sp,144
    80005a04:	8082                	ret
    end_op();
    80005a06:	fffff097          	auipc	ra,0xfffff
    80005a0a:	8c4080e7          	jalr	-1852(ra) # 800042ca <end_op>
    return -1;
    80005a0e:	557d                	li	a0,-1
    80005a10:	b7fd                	j	800059fe <sys_mkdir+0x4c>

0000000080005a12 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005a12:	7135                	addi	sp,sp,-160
    80005a14:	ed06                	sd	ra,152(sp)
    80005a16:	e922                	sd	s0,144(sp)
    80005a18:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005a1a:	fffff097          	auipc	ra,0xfffff
    80005a1e:	830080e7          	jalr	-2000(ra) # 8000424a <begin_op>
  argint(1, &major);
    80005a22:	f6c40593          	addi	a1,s0,-148
    80005a26:	4505                	li	a0,1
    80005a28:	ffffd097          	auipc	ra,0xffffd
    80005a2c:	14e080e7          	jalr	334(ra) # 80002b76 <argint>
  argint(2, &minor);
    80005a30:	f6840593          	addi	a1,s0,-152
    80005a34:	4509                	li	a0,2
    80005a36:	ffffd097          	auipc	ra,0xffffd
    80005a3a:	140080e7          	jalr	320(ra) # 80002b76 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a3e:	08000613          	li	a2,128
    80005a42:	f7040593          	addi	a1,s0,-144
    80005a46:	4501                	li	a0,0
    80005a48:	ffffd097          	auipc	ra,0xffffd
    80005a4c:	16e080e7          	jalr	366(ra) # 80002bb6 <argstr>
    80005a50:	02054b63          	bltz	a0,80005a86 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005a54:	f6841683          	lh	a3,-152(s0)
    80005a58:	f6c41603          	lh	a2,-148(s0)
    80005a5c:	458d                	li	a1,3
    80005a5e:	f7040513          	addi	a0,s0,-144
    80005a62:	fffff097          	auipc	ra,0xfffff
    80005a66:	77e080e7          	jalr	1918(ra) # 800051e0 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a6a:	cd11                	beqz	a0,80005a86 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a6c:	ffffe097          	auipc	ra,0xffffe
    80005a70:	07e080e7          	jalr	126(ra) # 80003aea <iunlockput>
  end_op();
    80005a74:	fffff097          	auipc	ra,0xfffff
    80005a78:	856080e7          	jalr	-1962(ra) # 800042ca <end_op>
  return 0;
    80005a7c:	4501                	li	a0,0
}
    80005a7e:	60ea                	ld	ra,152(sp)
    80005a80:	644a                	ld	s0,144(sp)
    80005a82:	610d                	addi	sp,sp,160
    80005a84:	8082                	ret
    end_op();
    80005a86:	fffff097          	auipc	ra,0xfffff
    80005a8a:	844080e7          	jalr	-1980(ra) # 800042ca <end_op>
    return -1;
    80005a8e:	557d                	li	a0,-1
    80005a90:	b7fd                	j	80005a7e <sys_mknod+0x6c>

0000000080005a92 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005a92:	7135                	addi	sp,sp,-160
    80005a94:	ed06                	sd	ra,152(sp)
    80005a96:	e922                	sd	s0,144(sp)
    80005a98:	e526                	sd	s1,136(sp)
    80005a9a:	e14a                	sd	s2,128(sp)
    80005a9c:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005a9e:	ffffc097          	auipc	ra,0xffffc
    80005aa2:	f28080e7          	jalr	-216(ra) # 800019c6 <myproc>
    80005aa6:	892a                	mv	s2,a0
  
  begin_op();
    80005aa8:	ffffe097          	auipc	ra,0xffffe
    80005aac:	7a2080e7          	jalr	1954(ra) # 8000424a <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005ab0:	08000613          	li	a2,128
    80005ab4:	f6040593          	addi	a1,s0,-160
    80005ab8:	4501                	li	a0,0
    80005aba:	ffffd097          	auipc	ra,0xffffd
    80005abe:	0fc080e7          	jalr	252(ra) # 80002bb6 <argstr>
    80005ac2:	04054b63          	bltz	a0,80005b18 <sys_chdir+0x86>
    80005ac6:	f6040513          	addi	a0,s0,-160
    80005aca:	ffffe097          	auipc	ra,0xffffe
    80005ace:	564080e7          	jalr	1380(ra) # 8000402e <namei>
    80005ad2:	84aa                	mv	s1,a0
    80005ad4:	c131                	beqz	a0,80005b18 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005ad6:	ffffe097          	auipc	ra,0xffffe
    80005ada:	db2080e7          	jalr	-590(ra) # 80003888 <ilock>
  if(ip->type != T_DIR){
    80005ade:	04449703          	lh	a4,68(s1)
    80005ae2:	4785                	li	a5,1
    80005ae4:	04f71063          	bne	a4,a5,80005b24 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005ae8:	8526                	mv	a0,s1
    80005aea:	ffffe097          	auipc	ra,0xffffe
    80005aee:	e60080e7          	jalr	-416(ra) # 8000394a <iunlock>
  iput(p->cwd);
    80005af2:	15093503          	ld	a0,336(s2)
    80005af6:	ffffe097          	auipc	ra,0xffffe
    80005afa:	f4c080e7          	jalr	-180(ra) # 80003a42 <iput>
  end_op();
    80005afe:	ffffe097          	auipc	ra,0xffffe
    80005b02:	7cc080e7          	jalr	1996(ra) # 800042ca <end_op>
  p->cwd = ip;
    80005b06:	14993823          	sd	s1,336(s2)
  return 0;
    80005b0a:	4501                	li	a0,0
}
    80005b0c:	60ea                	ld	ra,152(sp)
    80005b0e:	644a                	ld	s0,144(sp)
    80005b10:	64aa                	ld	s1,136(sp)
    80005b12:	690a                	ld	s2,128(sp)
    80005b14:	610d                	addi	sp,sp,160
    80005b16:	8082                	ret
    end_op();
    80005b18:	ffffe097          	auipc	ra,0xffffe
    80005b1c:	7b2080e7          	jalr	1970(ra) # 800042ca <end_op>
    return -1;
    80005b20:	557d                	li	a0,-1
    80005b22:	b7ed                	j	80005b0c <sys_chdir+0x7a>
    iunlockput(ip);
    80005b24:	8526                	mv	a0,s1
    80005b26:	ffffe097          	auipc	ra,0xffffe
    80005b2a:	fc4080e7          	jalr	-60(ra) # 80003aea <iunlockput>
    end_op();
    80005b2e:	ffffe097          	auipc	ra,0xffffe
    80005b32:	79c080e7          	jalr	1948(ra) # 800042ca <end_op>
    return -1;
    80005b36:	557d                	li	a0,-1
    80005b38:	bfd1                	j	80005b0c <sys_chdir+0x7a>

0000000080005b3a <sys_exec>:

uint64
sys_exec(void)
{
    80005b3a:	7145                	addi	sp,sp,-464
    80005b3c:	e786                	sd	ra,456(sp)
    80005b3e:	e3a2                	sd	s0,448(sp)
    80005b40:	ff26                	sd	s1,440(sp)
    80005b42:	fb4a                	sd	s2,432(sp)
    80005b44:	f74e                	sd	s3,424(sp)
    80005b46:	f352                	sd	s4,416(sp)
    80005b48:	ef56                	sd	s5,408(sp)
    80005b4a:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005b4c:	e3840593          	addi	a1,s0,-456
    80005b50:	4505                	li	a0,1
    80005b52:	ffffd097          	auipc	ra,0xffffd
    80005b56:	044080e7          	jalr	68(ra) # 80002b96 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005b5a:	08000613          	li	a2,128
    80005b5e:	f4040593          	addi	a1,s0,-192
    80005b62:	4501                	li	a0,0
    80005b64:	ffffd097          	auipc	ra,0xffffd
    80005b68:	052080e7          	jalr	82(ra) # 80002bb6 <argstr>
    80005b6c:	87aa                	mv	a5,a0
    return -1;
    80005b6e:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005b70:	0c07c263          	bltz	a5,80005c34 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005b74:	10000613          	li	a2,256
    80005b78:	4581                	li	a1,0
    80005b7a:	e4040513          	addi	a0,s0,-448
    80005b7e:	ffffb097          	auipc	ra,0xffffb
    80005b82:	168080e7          	jalr	360(ra) # 80000ce6 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005b86:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005b8a:	89a6                	mv	s3,s1
    80005b8c:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005b8e:	02000a13          	li	s4,32
    80005b92:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005b96:	00391513          	slli	a0,s2,0x3
    80005b9a:	e3040593          	addi	a1,s0,-464
    80005b9e:	e3843783          	ld	a5,-456(s0)
    80005ba2:	953e                	add	a0,a0,a5
    80005ba4:	ffffd097          	auipc	ra,0xffffd
    80005ba8:	f34080e7          	jalr	-204(ra) # 80002ad8 <fetchaddr>
    80005bac:	02054a63          	bltz	a0,80005be0 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005bb0:	e3043783          	ld	a5,-464(s0)
    80005bb4:	c3b9                	beqz	a5,80005bfa <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005bb6:	ffffb097          	auipc	ra,0xffffb
    80005bba:	f44080e7          	jalr	-188(ra) # 80000afa <kalloc>
    80005bbe:	85aa                	mv	a1,a0
    80005bc0:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005bc4:	cd11                	beqz	a0,80005be0 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005bc6:	6605                	lui	a2,0x1
    80005bc8:	e3043503          	ld	a0,-464(s0)
    80005bcc:	ffffd097          	auipc	ra,0xffffd
    80005bd0:	f5e080e7          	jalr	-162(ra) # 80002b2a <fetchstr>
    80005bd4:	00054663          	bltz	a0,80005be0 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005bd8:	0905                	addi	s2,s2,1
    80005bda:	09a1                	addi	s3,s3,8
    80005bdc:	fb491be3          	bne	s2,s4,80005b92 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005be0:	10048913          	addi	s2,s1,256
    80005be4:	6088                	ld	a0,0(s1)
    80005be6:	c531                	beqz	a0,80005c32 <sys_exec+0xf8>
    kfree(argv[i]);
    80005be8:	ffffb097          	auipc	ra,0xffffb
    80005bec:	e16080e7          	jalr	-490(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bf0:	04a1                	addi	s1,s1,8
    80005bf2:	ff2499e3          	bne	s1,s2,80005be4 <sys_exec+0xaa>
  return -1;
    80005bf6:	557d                	li	a0,-1
    80005bf8:	a835                	j	80005c34 <sys_exec+0xfa>
      argv[i] = 0;
    80005bfa:	0a8e                	slli	s5,s5,0x3
    80005bfc:	fc040793          	addi	a5,s0,-64
    80005c00:	9abe                	add	s5,s5,a5
    80005c02:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005c06:	e4040593          	addi	a1,s0,-448
    80005c0a:	f4040513          	addi	a0,s0,-192
    80005c0e:	fffff097          	auipc	ra,0xfffff
    80005c12:	190080e7          	jalr	400(ra) # 80004d9e <exec>
    80005c16:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c18:	10048993          	addi	s3,s1,256
    80005c1c:	6088                	ld	a0,0(s1)
    80005c1e:	c901                	beqz	a0,80005c2e <sys_exec+0xf4>
    kfree(argv[i]);
    80005c20:	ffffb097          	auipc	ra,0xffffb
    80005c24:	dde080e7          	jalr	-546(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c28:	04a1                	addi	s1,s1,8
    80005c2a:	ff3499e3          	bne	s1,s3,80005c1c <sys_exec+0xe2>
  return ret;
    80005c2e:	854a                	mv	a0,s2
    80005c30:	a011                	j	80005c34 <sys_exec+0xfa>
  return -1;
    80005c32:	557d                	li	a0,-1
}
    80005c34:	60be                	ld	ra,456(sp)
    80005c36:	641e                	ld	s0,448(sp)
    80005c38:	74fa                	ld	s1,440(sp)
    80005c3a:	795a                	ld	s2,432(sp)
    80005c3c:	79ba                	ld	s3,424(sp)
    80005c3e:	7a1a                	ld	s4,416(sp)
    80005c40:	6afa                	ld	s5,408(sp)
    80005c42:	6179                	addi	sp,sp,464
    80005c44:	8082                	ret

0000000080005c46 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005c46:	7139                	addi	sp,sp,-64
    80005c48:	fc06                	sd	ra,56(sp)
    80005c4a:	f822                	sd	s0,48(sp)
    80005c4c:	f426                	sd	s1,40(sp)
    80005c4e:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005c50:	ffffc097          	auipc	ra,0xffffc
    80005c54:	d76080e7          	jalr	-650(ra) # 800019c6 <myproc>
    80005c58:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005c5a:	fd840593          	addi	a1,s0,-40
    80005c5e:	4501                	li	a0,0
    80005c60:	ffffd097          	auipc	ra,0xffffd
    80005c64:	f36080e7          	jalr	-202(ra) # 80002b96 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005c68:	fc840593          	addi	a1,s0,-56
    80005c6c:	fd040513          	addi	a0,s0,-48
    80005c70:	fffff097          	auipc	ra,0xfffff
    80005c74:	dd6080e7          	jalr	-554(ra) # 80004a46 <pipealloc>
    return -1;
    80005c78:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005c7a:	0c054463          	bltz	a0,80005d42 <sys_pipe+0xfc>
  fd0 = -1;
    80005c7e:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005c82:	fd043503          	ld	a0,-48(s0)
    80005c86:	fffff097          	auipc	ra,0xfffff
    80005c8a:	518080e7          	jalr	1304(ra) # 8000519e <fdalloc>
    80005c8e:	fca42223          	sw	a0,-60(s0)
    80005c92:	08054b63          	bltz	a0,80005d28 <sys_pipe+0xe2>
    80005c96:	fc843503          	ld	a0,-56(s0)
    80005c9a:	fffff097          	auipc	ra,0xfffff
    80005c9e:	504080e7          	jalr	1284(ra) # 8000519e <fdalloc>
    80005ca2:	fca42023          	sw	a0,-64(s0)
    80005ca6:	06054863          	bltz	a0,80005d16 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005caa:	4691                	li	a3,4
    80005cac:	fc440613          	addi	a2,s0,-60
    80005cb0:	fd843583          	ld	a1,-40(s0)
    80005cb4:	68a8                	ld	a0,80(s1)
    80005cb6:	ffffc097          	auipc	ra,0xffffc
    80005cba:	9ce080e7          	jalr	-1586(ra) # 80001684 <copyout>
    80005cbe:	02054063          	bltz	a0,80005cde <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005cc2:	4691                	li	a3,4
    80005cc4:	fc040613          	addi	a2,s0,-64
    80005cc8:	fd843583          	ld	a1,-40(s0)
    80005ccc:	0591                	addi	a1,a1,4
    80005cce:	68a8                	ld	a0,80(s1)
    80005cd0:	ffffc097          	auipc	ra,0xffffc
    80005cd4:	9b4080e7          	jalr	-1612(ra) # 80001684 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005cd8:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005cda:	06055463          	bgez	a0,80005d42 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005cde:	fc442783          	lw	a5,-60(s0)
    80005ce2:	07e9                	addi	a5,a5,26
    80005ce4:	078e                	slli	a5,a5,0x3
    80005ce6:	97a6                	add	a5,a5,s1
    80005ce8:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005cec:	fc042503          	lw	a0,-64(s0)
    80005cf0:	0569                	addi	a0,a0,26
    80005cf2:	050e                	slli	a0,a0,0x3
    80005cf4:	94aa                	add	s1,s1,a0
    80005cf6:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005cfa:	fd043503          	ld	a0,-48(s0)
    80005cfe:	fffff097          	auipc	ra,0xfffff
    80005d02:	a18080e7          	jalr	-1512(ra) # 80004716 <fileclose>
    fileclose(wf);
    80005d06:	fc843503          	ld	a0,-56(s0)
    80005d0a:	fffff097          	auipc	ra,0xfffff
    80005d0e:	a0c080e7          	jalr	-1524(ra) # 80004716 <fileclose>
    return -1;
    80005d12:	57fd                	li	a5,-1
    80005d14:	a03d                	j	80005d42 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005d16:	fc442783          	lw	a5,-60(s0)
    80005d1a:	0007c763          	bltz	a5,80005d28 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005d1e:	07e9                	addi	a5,a5,26
    80005d20:	078e                	slli	a5,a5,0x3
    80005d22:	94be                	add	s1,s1,a5
    80005d24:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005d28:	fd043503          	ld	a0,-48(s0)
    80005d2c:	fffff097          	auipc	ra,0xfffff
    80005d30:	9ea080e7          	jalr	-1558(ra) # 80004716 <fileclose>
    fileclose(wf);
    80005d34:	fc843503          	ld	a0,-56(s0)
    80005d38:	fffff097          	auipc	ra,0xfffff
    80005d3c:	9de080e7          	jalr	-1570(ra) # 80004716 <fileclose>
    return -1;
    80005d40:	57fd                	li	a5,-1
}
    80005d42:	853e                	mv	a0,a5
    80005d44:	70e2                	ld	ra,56(sp)
    80005d46:	7442                	ld	s0,48(sp)
    80005d48:	74a2                	ld	s1,40(sp)
    80005d4a:	6121                	addi	sp,sp,64
    80005d4c:	8082                	ret
	...

0000000080005d50 <kernelvec>:
    80005d50:	7111                	addi	sp,sp,-256
    80005d52:	e006                	sd	ra,0(sp)
    80005d54:	e40a                	sd	sp,8(sp)
    80005d56:	e80e                	sd	gp,16(sp)
    80005d58:	ec12                	sd	tp,24(sp)
    80005d5a:	f016                	sd	t0,32(sp)
    80005d5c:	f41a                	sd	t1,40(sp)
    80005d5e:	f81e                	sd	t2,48(sp)
    80005d60:	fc22                	sd	s0,56(sp)
    80005d62:	e0a6                	sd	s1,64(sp)
    80005d64:	e4aa                	sd	a0,72(sp)
    80005d66:	e8ae                	sd	a1,80(sp)
    80005d68:	ecb2                	sd	a2,88(sp)
    80005d6a:	f0b6                	sd	a3,96(sp)
    80005d6c:	f4ba                	sd	a4,104(sp)
    80005d6e:	f8be                	sd	a5,112(sp)
    80005d70:	fcc2                	sd	a6,120(sp)
    80005d72:	e146                	sd	a7,128(sp)
    80005d74:	e54a                	sd	s2,136(sp)
    80005d76:	e94e                	sd	s3,144(sp)
    80005d78:	ed52                	sd	s4,152(sp)
    80005d7a:	f156                	sd	s5,160(sp)
    80005d7c:	f55a                	sd	s6,168(sp)
    80005d7e:	f95e                	sd	s7,176(sp)
    80005d80:	fd62                	sd	s8,184(sp)
    80005d82:	e1e6                	sd	s9,192(sp)
    80005d84:	e5ea                	sd	s10,200(sp)
    80005d86:	e9ee                	sd	s11,208(sp)
    80005d88:	edf2                	sd	t3,216(sp)
    80005d8a:	f1f6                	sd	t4,224(sp)
    80005d8c:	f5fa                	sd	t5,232(sp)
    80005d8e:	f9fe                	sd	t6,240(sp)
    80005d90:	c15fc0ef          	jal	ra,800029a4 <kerneltrap>
    80005d94:	6082                	ld	ra,0(sp)
    80005d96:	6122                	ld	sp,8(sp)
    80005d98:	61c2                	ld	gp,16(sp)
    80005d9a:	7282                	ld	t0,32(sp)
    80005d9c:	7322                	ld	t1,40(sp)
    80005d9e:	73c2                	ld	t2,48(sp)
    80005da0:	7462                	ld	s0,56(sp)
    80005da2:	6486                	ld	s1,64(sp)
    80005da4:	6526                	ld	a0,72(sp)
    80005da6:	65c6                	ld	a1,80(sp)
    80005da8:	6666                	ld	a2,88(sp)
    80005daa:	7686                	ld	a3,96(sp)
    80005dac:	7726                	ld	a4,104(sp)
    80005dae:	77c6                	ld	a5,112(sp)
    80005db0:	7866                	ld	a6,120(sp)
    80005db2:	688a                	ld	a7,128(sp)
    80005db4:	692a                	ld	s2,136(sp)
    80005db6:	69ca                	ld	s3,144(sp)
    80005db8:	6a6a                	ld	s4,152(sp)
    80005dba:	7a8a                	ld	s5,160(sp)
    80005dbc:	7b2a                	ld	s6,168(sp)
    80005dbe:	7bca                	ld	s7,176(sp)
    80005dc0:	7c6a                	ld	s8,184(sp)
    80005dc2:	6c8e                	ld	s9,192(sp)
    80005dc4:	6d2e                	ld	s10,200(sp)
    80005dc6:	6dce                	ld	s11,208(sp)
    80005dc8:	6e6e                	ld	t3,216(sp)
    80005dca:	7e8e                	ld	t4,224(sp)
    80005dcc:	7f2e                	ld	t5,232(sp)
    80005dce:	7fce                	ld	t6,240(sp)
    80005dd0:	6111                	addi	sp,sp,256
    80005dd2:	10200073          	sret
    80005dd6:	00000013          	nop
    80005dda:	00000013          	nop
    80005dde:	0001                	nop

0000000080005de0 <timervec>:
    80005de0:	34051573          	csrrw	a0,mscratch,a0
    80005de4:	e10c                	sd	a1,0(a0)
    80005de6:	e510                	sd	a2,8(a0)
    80005de8:	e914                	sd	a3,16(a0)
    80005dea:	6d0c                	ld	a1,24(a0)
    80005dec:	7110                	ld	a2,32(a0)
    80005dee:	6194                	ld	a3,0(a1)
    80005df0:	96b2                	add	a3,a3,a2
    80005df2:	e194                	sd	a3,0(a1)
    80005df4:	4589                	li	a1,2
    80005df6:	14459073          	csrw	sip,a1
    80005dfa:	6914                	ld	a3,16(a0)
    80005dfc:	6510                	ld	a2,8(a0)
    80005dfe:	610c                	ld	a1,0(a0)
    80005e00:	34051573          	csrrw	a0,mscratch,a0
    80005e04:	30200073          	mret
	...

0000000080005e0a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005e0a:	1141                	addi	sp,sp,-16
    80005e0c:	e422                	sd	s0,8(sp)
    80005e0e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005e10:	0c0007b7          	lui	a5,0xc000
    80005e14:	4705                	li	a4,1
    80005e16:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005e18:	c3d8                	sw	a4,4(a5)
}
    80005e1a:	6422                	ld	s0,8(sp)
    80005e1c:	0141                	addi	sp,sp,16
    80005e1e:	8082                	ret

0000000080005e20 <plicinithart>:

void
plicinithart(void)
{
    80005e20:	1141                	addi	sp,sp,-16
    80005e22:	e406                	sd	ra,8(sp)
    80005e24:	e022                	sd	s0,0(sp)
    80005e26:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e28:	ffffc097          	auipc	ra,0xffffc
    80005e2c:	b72080e7          	jalr	-1166(ra) # 8000199a <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005e30:	0085171b          	slliw	a4,a0,0x8
    80005e34:	0c0027b7          	lui	a5,0xc002
    80005e38:	97ba                	add	a5,a5,a4
    80005e3a:	40200713          	li	a4,1026
    80005e3e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005e42:	00d5151b          	slliw	a0,a0,0xd
    80005e46:	0c2017b7          	lui	a5,0xc201
    80005e4a:	953e                	add	a0,a0,a5
    80005e4c:	00052023          	sw	zero,0(a0)
}
    80005e50:	60a2                	ld	ra,8(sp)
    80005e52:	6402                	ld	s0,0(sp)
    80005e54:	0141                	addi	sp,sp,16
    80005e56:	8082                	ret

0000000080005e58 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005e58:	1141                	addi	sp,sp,-16
    80005e5a:	e406                	sd	ra,8(sp)
    80005e5c:	e022                	sd	s0,0(sp)
    80005e5e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e60:	ffffc097          	auipc	ra,0xffffc
    80005e64:	b3a080e7          	jalr	-1222(ra) # 8000199a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005e68:	00d5179b          	slliw	a5,a0,0xd
    80005e6c:	0c201537          	lui	a0,0xc201
    80005e70:	953e                	add	a0,a0,a5
  return irq;
}
    80005e72:	4148                	lw	a0,4(a0)
    80005e74:	60a2                	ld	ra,8(sp)
    80005e76:	6402                	ld	s0,0(sp)
    80005e78:	0141                	addi	sp,sp,16
    80005e7a:	8082                	ret

0000000080005e7c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005e7c:	1101                	addi	sp,sp,-32
    80005e7e:	ec06                	sd	ra,24(sp)
    80005e80:	e822                	sd	s0,16(sp)
    80005e82:	e426                	sd	s1,8(sp)
    80005e84:	1000                	addi	s0,sp,32
    80005e86:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005e88:	ffffc097          	auipc	ra,0xffffc
    80005e8c:	b12080e7          	jalr	-1262(ra) # 8000199a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005e90:	00d5151b          	slliw	a0,a0,0xd
    80005e94:	0c2017b7          	lui	a5,0xc201
    80005e98:	97aa                	add	a5,a5,a0
    80005e9a:	c3c4                	sw	s1,4(a5)
}
    80005e9c:	60e2                	ld	ra,24(sp)
    80005e9e:	6442                	ld	s0,16(sp)
    80005ea0:	64a2                	ld	s1,8(sp)
    80005ea2:	6105                	addi	sp,sp,32
    80005ea4:	8082                	ret

0000000080005ea6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005ea6:	1141                	addi	sp,sp,-16
    80005ea8:	e406                	sd	ra,8(sp)
    80005eaa:	e022                	sd	s0,0(sp)
    80005eac:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005eae:	479d                	li	a5,7
    80005eb0:	04a7cc63          	blt	a5,a0,80005f08 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005eb4:	00024797          	auipc	a5,0x24
    80005eb8:	2a478793          	addi	a5,a5,676 # 8002a158 <disk>
    80005ebc:	97aa                	add	a5,a5,a0
    80005ebe:	0187c783          	lbu	a5,24(a5)
    80005ec2:	ebb9                	bnez	a5,80005f18 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005ec4:	00451613          	slli	a2,a0,0x4
    80005ec8:	00024797          	auipc	a5,0x24
    80005ecc:	29078793          	addi	a5,a5,656 # 8002a158 <disk>
    80005ed0:	6394                	ld	a3,0(a5)
    80005ed2:	96b2                	add	a3,a3,a2
    80005ed4:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005ed8:	6398                	ld	a4,0(a5)
    80005eda:	9732                	add	a4,a4,a2
    80005edc:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005ee0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005ee4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005ee8:	953e                	add	a0,a0,a5
    80005eea:	4785                	li	a5,1
    80005eec:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80005ef0:	00024517          	auipc	a0,0x24
    80005ef4:	28050513          	addi	a0,a0,640 # 8002a170 <disk+0x18>
    80005ef8:	ffffc097          	auipc	ra,0xffffc
    80005efc:	276080e7          	jalr	630(ra) # 8000216e <wakeup>
}
    80005f00:	60a2                	ld	ra,8(sp)
    80005f02:	6402                	ld	s0,0(sp)
    80005f04:	0141                	addi	sp,sp,16
    80005f06:	8082                	ret
    panic("free_desc 1");
    80005f08:	00003517          	auipc	a0,0x3
    80005f0c:	a3050513          	addi	a0,a0,-1488 # 80008938 <syscalls+0x318>
    80005f10:	ffffa097          	auipc	ra,0xffffa
    80005f14:	634080e7          	jalr	1588(ra) # 80000544 <panic>
    panic("free_desc 2");
    80005f18:	00003517          	auipc	a0,0x3
    80005f1c:	a3050513          	addi	a0,a0,-1488 # 80008948 <syscalls+0x328>
    80005f20:	ffffa097          	auipc	ra,0xffffa
    80005f24:	624080e7          	jalr	1572(ra) # 80000544 <panic>

0000000080005f28 <virtio_disk_init>:
{
    80005f28:	1101                	addi	sp,sp,-32
    80005f2a:	ec06                	sd	ra,24(sp)
    80005f2c:	e822                	sd	s0,16(sp)
    80005f2e:	e426                	sd	s1,8(sp)
    80005f30:	e04a                	sd	s2,0(sp)
    80005f32:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005f34:	00003597          	auipc	a1,0x3
    80005f38:	a2458593          	addi	a1,a1,-1500 # 80008958 <syscalls+0x338>
    80005f3c:	00024517          	auipc	a0,0x24
    80005f40:	34450513          	addi	a0,a0,836 # 8002a280 <disk+0x128>
    80005f44:	ffffb097          	auipc	ra,0xffffb
    80005f48:	c16080e7          	jalr	-1002(ra) # 80000b5a <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f4c:	100017b7          	lui	a5,0x10001
    80005f50:	4398                	lw	a4,0(a5)
    80005f52:	2701                	sext.w	a4,a4
    80005f54:	747277b7          	lui	a5,0x74727
    80005f58:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005f5c:	14f71e63          	bne	a4,a5,800060b8 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005f60:	100017b7          	lui	a5,0x10001
    80005f64:	43dc                	lw	a5,4(a5)
    80005f66:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f68:	4709                	li	a4,2
    80005f6a:	14e79763          	bne	a5,a4,800060b8 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f6e:	100017b7          	lui	a5,0x10001
    80005f72:	479c                	lw	a5,8(a5)
    80005f74:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005f76:	14e79163          	bne	a5,a4,800060b8 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005f7a:	100017b7          	lui	a5,0x10001
    80005f7e:	47d8                	lw	a4,12(a5)
    80005f80:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f82:	554d47b7          	lui	a5,0x554d4
    80005f86:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005f8a:	12f71763          	bne	a4,a5,800060b8 <virtio_disk_init+0x190>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f8e:	100017b7          	lui	a5,0x10001
    80005f92:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f96:	4705                	li	a4,1
    80005f98:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f9a:	470d                	li	a4,3
    80005f9c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005f9e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005fa0:	c7ffe737          	lui	a4,0xc7ffe
    80005fa4:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd44c7>
    80005fa8:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005faa:	2701                	sext.w	a4,a4
    80005fac:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fae:	472d                	li	a4,11
    80005fb0:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005fb2:	0707a903          	lw	s2,112(a5)
    80005fb6:	2901                	sext.w	s2,s2
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005fb8:	00897793          	andi	a5,s2,8
    80005fbc:	10078663          	beqz	a5,800060c8 <virtio_disk_init+0x1a0>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005fc0:	100017b7          	lui	a5,0x10001
    80005fc4:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005fc8:	43fc                	lw	a5,68(a5)
    80005fca:	2781                	sext.w	a5,a5
    80005fcc:	10079663          	bnez	a5,800060d8 <virtio_disk_init+0x1b0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005fd0:	100017b7          	lui	a5,0x10001
    80005fd4:	5bdc                	lw	a5,52(a5)
    80005fd6:	2781                	sext.w	a5,a5
  if(max == 0)
    80005fd8:	10078863          	beqz	a5,800060e8 <virtio_disk_init+0x1c0>
  if(max < NUM)
    80005fdc:	471d                	li	a4,7
    80005fde:	10f77d63          	bgeu	a4,a5,800060f8 <virtio_disk_init+0x1d0>
  disk.desc = kalloc();
    80005fe2:	ffffb097          	auipc	ra,0xffffb
    80005fe6:	b18080e7          	jalr	-1256(ra) # 80000afa <kalloc>
    80005fea:	00024497          	auipc	s1,0x24
    80005fee:	16e48493          	addi	s1,s1,366 # 8002a158 <disk>
    80005ff2:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005ff4:	ffffb097          	auipc	ra,0xffffb
    80005ff8:	b06080e7          	jalr	-1274(ra) # 80000afa <kalloc>
    80005ffc:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005ffe:	ffffb097          	auipc	ra,0xffffb
    80006002:	afc080e7          	jalr	-1284(ra) # 80000afa <kalloc>
    80006006:	87aa                	mv	a5,a0
    80006008:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    8000600a:	6088                	ld	a0,0(s1)
    8000600c:	cd75                	beqz	a0,80006108 <virtio_disk_init+0x1e0>
    8000600e:	00024717          	auipc	a4,0x24
    80006012:	15273703          	ld	a4,338(a4) # 8002a160 <disk+0x8>
    80006016:	cb6d                	beqz	a4,80006108 <virtio_disk_init+0x1e0>
    80006018:	cbe5                	beqz	a5,80006108 <virtio_disk_init+0x1e0>
  memset(disk.desc, 0, PGSIZE);
    8000601a:	6605                	lui	a2,0x1
    8000601c:	4581                	li	a1,0
    8000601e:	ffffb097          	auipc	ra,0xffffb
    80006022:	cc8080e7          	jalr	-824(ra) # 80000ce6 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006026:	00024497          	auipc	s1,0x24
    8000602a:	13248493          	addi	s1,s1,306 # 8002a158 <disk>
    8000602e:	6605                	lui	a2,0x1
    80006030:	4581                	li	a1,0
    80006032:	6488                	ld	a0,8(s1)
    80006034:	ffffb097          	auipc	ra,0xffffb
    80006038:	cb2080e7          	jalr	-846(ra) # 80000ce6 <memset>
  memset(disk.used, 0, PGSIZE);
    8000603c:	6605                	lui	a2,0x1
    8000603e:	4581                	li	a1,0
    80006040:	6888                	ld	a0,16(s1)
    80006042:	ffffb097          	auipc	ra,0xffffb
    80006046:	ca4080e7          	jalr	-860(ra) # 80000ce6 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    8000604a:	100017b7          	lui	a5,0x10001
    8000604e:	4721                	li	a4,8
    80006050:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006052:	4098                	lw	a4,0(s1)
    80006054:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006058:	40d8                	lw	a4,4(s1)
    8000605a:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000605e:	6498                	ld	a4,8(s1)
    80006060:	0007069b          	sext.w	a3,a4
    80006064:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006068:	9701                	srai	a4,a4,0x20
    8000606a:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000606e:	6898                	ld	a4,16(s1)
    80006070:	0007069b          	sext.w	a3,a4
    80006074:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006078:	9701                	srai	a4,a4,0x20
    8000607a:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000607e:	4685                	li	a3,1
    80006080:	c3f4                	sw	a3,68(a5)
    disk.free[i] = 1;
    80006082:	4705                	li	a4,1
    80006084:	00d48c23          	sb	a3,24(s1)
    80006088:	00e48ca3          	sb	a4,25(s1)
    8000608c:	00e48d23          	sb	a4,26(s1)
    80006090:	00e48da3          	sb	a4,27(s1)
    80006094:	00e48e23          	sb	a4,28(s1)
    80006098:	00e48ea3          	sb	a4,29(s1)
    8000609c:	00e48f23          	sb	a4,30(s1)
    800060a0:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    800060a4:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    800060a8:	0727a823          	sw	s2,112(a5)
}
    800060ac:	60e2                	ld	ra,24(sp)
    800060ae:	6442                	ld	s0,16(sp)
    800060b0:	64a2                	ld	s1,8(sp)
    800060b2:	6902                	ld	s2,0(sp)
    800060b4:	6105                	addi	sp,sp,32
    800060b6:	8082                	ret
    panic("could not find virtio disk");
    800060b8:	00003517          	auipc	a0,0x3
    800060bc:	8b050513          	addi	a0,a0,-1872 # 80008968 <syscalls+0x348>
    800060c0:	ffffa097          	auipc	ra,0xffffa
    800060c4:	484080e7          	jalr	1156(ra) # 80000544 <panic>
    panic("virtio disk FEATURES_OK unset");
    800060c8:	00003517          	auipc	a0,0x3
    800060cc:	8c050513          	addi	a0,a0,-1856 # 80008988 <syscalls+0x368>
    800060d0:	ffffa097          	auipc	ra,0xffffa
    800060d4:	474080e7          	jalr	1140(ra) # 80000544 <panic>
    panic("virtio disk should not be ready");
    800060d8:	00003517          	auipc	a0,0x3
    800060dc:	8d050513          	addi	a0,a0,-1840 # 800089a8 <syscalls+0x388>
    800060e0:	ffffa097          	auipc	ra,0xffffa
    800060e4:	464080e7          	jalr	1124(ra) # 80000544 <panic>
    panic("virtio disk has no queue 0");
    800060e8:	00003517          	auipc	a0,0x3
    800060ec:	8e050513          	addi	a0,a0,-1824 # 800089c8 <syscalls+0x3a8>
    800060f0:	ffffa097          	auipc	ra,0xffffa
    800060f4:	454080e7          	jalr	1108(ra) # 80000544 <panic>
    panic("virtio disk max queue too short");
    800060f8:	00003517          	auipc	a0,0x3
    800060fc:	8f050513          	addi	a0,a0,-1808 # 800089e8 <syscalls+0x3c8>
    80006100:	ffffa097          	auipc	ra,0xffffa
    80006104:	444080e7          	jalr	1092(ra) # 80000544 <panic>
    panic("virtio disk kalloc");
    80006108:	00003517          	auipc	a0,0x3
    8000610c:	90050513          	addi	a0,a0,-1792 # 80008a08 <syscalls+0x3e8>
    80006110:	ffffa097          	auipc	ra,0xffffa
    80006114:	434080e7          	jalr	1076(ra) # 80000544 <panic>

0000000080006118 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006118:	7159                	addi	sp,sp,-112
    8000611a:	f486                	sd	ra,104(sp)
    8000611c:	f0a2                	sd	s0,96(sp)
    8000611e:	eca6                	sd	s1,88(sp)
    80006120:	e8ca                	sd	s2,80(sp)
    80006122:	e4ce                	sd	s3,72(sp)
    80006124:	e0d2                	sd	s4,64(sp)
    80006126:	fc56                	sd	s5,56(sp)
    80006128:	f85a                	sd	s6,48(sp)
    8000612a:	f45e                	sd	s7,40(sp)
    8000612c:	f062                	sd	s8,32(sp)
    8000612e:	ec66                	sd	s9,24(sp)
    80006130:	e86a                	sd	s10,16(sp)
    80006132:	1880                	addi	s0,sp,112
    80006134:	892a                	mv	s2,a0
    80006136:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006138:	00c52c83          	lw	s9,12(a0)
    8000613c:	001c9c9b          	slliw	s9,s9,0x1
    80006140:	1c82                	slli	s9,s9,0x20
    80006142:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006146:	00024517          	auipc	a0,0x24
    8000614a:	13a50513          	addi	a0,a0,314 # 8002a280 <disk+0x128>
    8000614e:	ffffb097          	auipc	ra,0xffffb
    80006152:	a9c080e7          	jalr	-1380(ra) # 80000bea <acquire>
  for(int i = 0; i < 3; i++){
    80006156:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006158:	4ba1                	li	s7,8
      disk.free[i] = 0;
    8000615a:	00024b17          	auipc	s6,0x24
    8000615e:	ffeb0b13          	addi	s6,s6,-2 # 8002a158 <disk>
  for(int i = 0; i < 3; i++){
    80006162:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006164:	8a4e                	mv	s4,s3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006166:	00024c17          	auipc	s8,0x24
    8000616a:	11ac0c13          	addi	s8,s8,282 # 8002a280 <disk+0x128>
    8000616e:	a8b5                	j	800061ea <virtio_disk_rw+0xd2>
      disk.free[i] = 0;
    80006170:	00fb06b3          	add	a3,s6,a5
    80006174:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006178:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    8000617a:	0207c563          	bltz	a5,800061a4 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    8000617e:	2485                	addiw	s1,s1,1
    80006180:	0711                	addi	a4,a4,4
    80006182:	1f548a63          	beq	s1,s5,80006376 <virtio_disk_rw+0x25e>
    idx[i] = alloc_desc();
    80006186:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006188:	00024697          	auipc	a3,0x24
    8000618c:	fd068693          	addi	a3,a3,-48 # 8002a158 <disk>
    80006190:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006192:	0186c583          	lbu	a1,24(a3)
    80006196:	fde9                	bnez	a1,80006170 <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006198:	2785                	addiw	a5,a5,1
    8000619a:	0685                	addi	a3,a3,1
    8000619c:	ff779be3          	bne	a5,s7,80006192 <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    800061a0:	57fd                	li	a5,-1
    800061a2:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800061a4:	02905a63          	blez	s1,800061d8 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    800061a8:	f9042503          	lw	a0,-112(s0)
    800061ac:	00000097          	auipc	ra,0x0
    800061b0:	cfa080e7          	jalr	-774(ra) # 80005ea6 <free_desc>
      for(int j = 0; j < i; j++)
    800061b4:	4785                	li	a5,1
    800061b6:	0297d163          	bge	a5,s1,800061d8 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    800061ba:	f9442503          	lw	a0,-108(s0)
    800061be:	00000097          	auipc	ra,0x0
    800061c2:	ce8080e7          	jalr	-792(ra) # 80005ea6 <free_desc>
      for(int j = 0; j < i; j++)
    800061c6:	4789                	li	a5,2
    800061c8:	0097d863          	bge	a5,s1,800061d8 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    800061cc:	f9842503          	lw	a0,-104(s0)
    800061d0:	00000097          	auipc	ra,0x0
    800061d4:	cd6080e7          	jalr	-810(ra) # 80005ea6 <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800061d8:	85e2                	mv	a1,s8
    800061da:	00024517          	auipc	a0,0x24
    800061de:	f9650513          	addi	a0,a0,-106 # 8002a170 <disk+0x18>
    800061e2:	ffffc097          	auipc	ra,0xffffc
    800061e6:	f28080e7          	jalr	-216(ra) # 8000210a <sleep>
  for(int i = 0; i < 3; i++){
    800061ea:	f9040713          	addi	a4,s0,-112
    800061ee:	84ce                	mv	s1,s3
    800061f0:	bf59                	j	80006186 <virtio_disk_rw+0x6e>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800061f2:	00a60793          	addi	a5,a2,10 # 100a <_entry-0x7fffeff6>
    800061f6:	00479693          	slli	a3,a5,0x4
    800061fa:	00024797          	auipc	a5,0x24
    800061fe:	f5e78793          	addi	a5,a5,-162 # 8002a158 <disk>
    80006202:	97b6                	add	a5,a5,a3
    80006204:	4685                	li	a3,1
    80006206:	c794                	sw	a3,8(a5)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006208:	00024597          	auipc	a1,0x24
    8000620c:	f5058593          	addi	a1,a1,-176 # 8002a158 <disk>
    80006210:	00a60793          	addi	a5,a2,10
    80006214:	0792                	slli	a5,a5,0x4
    80006216:	97ae                	add	a5,a5,a1
    80006218:	0007a623          	sw	zero,12(a5)
  buf0->sector = sector;
    8000621c:	0197b823          	sd	s9,16(a5)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006220:	f6070693          	addi	a3,a4,-160
    80006224:	619c                	ld	a5,0(a1)
    80006226:	97b6                	add	a5,a5,a3
    80006228:	e388                	sd	a0,0(a5)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000622a:	6188                	ld	a0,0(a1)
    8000622c:	96aa                	add	a3,a3,a0
    8000622e:	47c1                	li	a5,16
    80006230:	c69c                	sw	a5,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006232:	4785                	li	a5,1
    80006234:	00f69623          	sh	a5,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006238:	f9442783          	lw	a5,-108(s0)
    8000623c:	00f69723          	sh	a5,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006240:	0792                	slli	a5,a5,0x4
    80006242:	953e                	add	a0,a0,a5
    80006244:	05890693          	addi	a3,s2,88
    80006248:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000624a:	6188                	ld	a0,0(a1)
    8000624c:	97aa                	add	a5,a5,a0
    8000624e:	40000693          	li	a3,1024
    80006252:	c794                	sw	a3,8(a5)
  if(write)
    80006254:	100d0d63          	beqz	s10,8000636e <virtio_disk_rw+0x256>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006258:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000625c:	00c7d683          	lhu	a3,12(a5)
    80006260:	0016e693          	ori	a3,a3,1
    80006264:	00d79623          	sh	a3,12(a5)
  disk.desc[idx[1]].next = idx[2];
    80006268:	f9842583          	lw	a1,-104(s0)
    8000626c:	00b79723          	sh	a1,14(a5)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006270:	00024697          	auipc	a3,0x24
    80006274:	ee868693          	addi	a3,a3,-280 # 8002a158 <disk>
    80006278:	00260793          	addi	a5,a2,2
    8000627c:	0792                	slli	a5,a5,0x4
    8000627e:	97b6                	add	a5,a5,a3
    80006280:	587d                	li	a6,-1
    80006282:	01078823          	sb	a6,16(a5)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006286:	0592                	slli	a1,a1,0x4
    80006288:	952e                	add	a0,a0,a1
    8000628a:	f9070713          	addi	a4,a4,-112
    8000628e:	9736                	add	a4,a4,a3
    80006290:	e118                	sd	a4,0(a0)
  disk.desc[idx[2]].len = 1;
    80006292:	6298                	ld	a4,0(a3)
    80006294:	972e                	add	a4,a4,a1
    80006296:	4585                	li	a1,1
    80006298:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000629a:	4509                	li	a0,2
    8000629c:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[2]].next = 0;
    800062a0:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800062a4:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    800062a8:	0127b423          	sd	s2,8(a5)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800062ac:	6698                	ld	a4,8(a3)
    800062ae:	00275783          	lhu	a5,2(a4)
    800062b2:	8b9d                	andi	a5,a5,7
    800062b4:	0786                	slli	a5,a5,0x1
    800062b6:	97ba                	add	a5,a5,a4
    800062b8:	00c79223          	sh	a2,4(a5)

  __sync_synchronize();
    800062bc:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800062c0:	6698                	ld	a4,8(a3)
    800062c2:	00275783          	lhu	a5,2(a4)
    800062c6:	2785                	addiw	a5,a5,1
    800062c8:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800062cc:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800062d0:	100017b7          	lui	a5,0x10001
    800062d4:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800062d8:	00492703          	lw	a4,4(s2)
    800062dc:	4785                	li	a5,1
    800062de:	02f71163          	bne	a4,a5,80006300 <virtio_disk_rw+0x1e8>
    sleep(b, &disk.vdisk_lock);
    800062e2:	00024997          	auipc	s3,0x24
    800062e6:	f9e98993          	addi	s3,s3,-98 # 8002a280 <disk+0x128>
  while(b->disk == 1) {
    800062ea:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800062ec:	85ce                	mv	a1,s3
    800062ee:	854a                	mv	a0,s2
    800062f0:	ffffc097          	auipc	ra,0xffffc
    800062f4:	e1a080e7          	jalr	-486(ra) # 8000210a <sleep>
  while(b->disk == 1) {
    800062f8:	00492783          	lw	a5,4(s2)
    800062fc:	fe9788e3          	beq	a5,s1,800062ec <virtio_disk_rw+0x1d4>
  }

  disk.info[idx[0]].b = 0;
    80006300:	f9042903          	lw	s2,-112(s0)
    80006304:	00290793          	addi	a5,s2,2
    80006308:	00479713          	slli	a4,a5,0x4
    8000630c:	00024797          	auipc	a5,0x24
    80006310:	e4c78793          	addi	a5,a5,-436 # 8002a158 <disk>
    80006314:	97ba                	add	a5,a5,a4
    80006316:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000631a:	00024997          	auipc	s3,0x24
    8000631e:	e3e98993          	addi	s3,s3,-450 # 8002a158 <disk>
    80006322:	00491713          	slli	a4,s2,0x4
    80006326:	0009b783          	ld	a5,0(s3)
    8000632a:	97ba                	add	a5,a5,a4
    8000632c:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006330:	854a                	mv	a0,s2
    80006332:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006336:	00000097          	auipc	ra,0x0
    8000633a:	b70080e7          	jalr	-1168(ra) # 80005ea6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000633e:	8885                	andi	s1,s1,1
    80006340:	f0ed                	bnez	s1,80006322 <virtio_disk_rw+0x20a>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006342:	00024517          	auipc	a0,0x24
    80006346:	f3e50513          	addi	a0,a0,-194 # 8002a280 <disk+0x128>
    8000634a:	ffffb097          	auipc	ra,0xffffb
    8000634e:	954080e7          	jalr	-1708(ra) # 80000c9e <release>
}
    80006352:	70a6                	ld	ra,104(sp)
    80006354:	7406                	ld	s0,96(sp)
    80006356:	64e6                	ld	s1,88(sp)
    80006358:	6946                	ld	s2,80(sp)
    8000635a:	69a6                	ld	s3,72(sp)
    8000635c:	6a06                	ld	s4,64(sp)
    8000635e:	7ae2                	ld	s5,56(sp)
    80006360:	7b42                	ld	s6,48(sp)
    80006362:	7ba2                	ld	s7,40(sp)
    80006364:	7c02                	ld	s8,32(sp)
    80006366:	6ce2                	ld	s9,24(sp)
    80006368:	6d42                	ld	s10,16(sp)
    8000636a:	6165                	addi	sp,sp,112
    8000636c:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000636e:	4689                	li	a3,2
    80006370:	00d79623          	sh	a3,12(a5)
    80006374:	b5e5                	j	8000625c <virtio_disk_rw+0x144>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006376:	f9042603          	lw	a2,-112(s0)
    8000637a:	00a60713          	addi	a4,a2,10
    8000637e:	0712                	slli	a4,a4,0x4
    80006380:	00024517          	auipc	a0,0x24
    80006384:	de050513          	addi	a0,a0,-544 # 8002a160 <disk+0x8>
    80006388:	953a                	add	a0,a0,a4
  if(write)
    8000638a:	e60d14e3          	bnez	s10,800061f2 <virtio_disk_rw+0xda>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    8000638e:	00a60793          	addi	a5,a2,10
    80006392:	00479693          	slli	a3,a5,0x4
    80006396:	00024797          	auipc	a5,0x24
    8000639a:	dc278793          	addi	a5,a5,-574 # 8002a158 <disk>
    8000639e:	97b6                	add	a5,a5,a3
    800063a0:	0007a423          	sw	zero,8(a5)
    800063a4:	b595                	j	80006208 <virtio_disk_rw+0xf0>

00000000800063a6 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800063a6:	1101                	addi	sp,sp,-32
    800063a8:	ec06                	sd	ra,24(sp)
    800063aa:	e822                	sd	s0,16(sp)
    800063ac:	e426                	sd	s1,8(sp)
    800063ae:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800063b0:	00024497          	auipc	s1,0x24
    800063b4:	da848493          	addi	s1,s1,-600 # 8002a158 <disk>
    800063b8:	00024517          	auipc	a0,0x24
    800063bc:	ec850513          	addi	a0,a0,-312 # 8002a280 <disk+0x128>
    800063c0:	ffffb097          	auipc	ra,0xffffb
    800063c4:	82a080e7          	jalr	-2006(ra) # 80000bea <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800063c8:	10001737          	lui	a4,0x10001
    800063cc:	533c                	lw	a5,96(a4)
    800063ce:	8b8d                	andi	a5,a5,3
    800063d0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800063d2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800063d6:	689c                	ld	a5,16(s1)
    800063d8:	0204d703          	lhu	a4,32(s1)
    800063dc:	0027d783          	lhu	a5,2(a5)
    800063e0:	04f70863          	beq	a4,a5,80006430 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800063e4:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800063e8:	6898                	ld	a4,16(s1)
    800063ea:	0204d783          	lhu	a5,32(s1)
    800063ee:	8b9d                	andi	a5,a5,7
    800063f0:	078e                	slli	a5,a5,0x3
    800063f2:	97ba                	add	a5,a5,a4
    800063f4:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800063f6:	00278713          	addi	a4,a5,2
    800063fa:	0712                	slli	a4,a4,0x4
    800063fc:	9726                	add	a4,a4,s1
    800063fe:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006402:	e721                	bnez	a4,8000644a <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006404:	0789                	addi	a5,a5,2
    80006406:	0792                	slli	a5,a5,0x4
    80006408:	97a6                	add	a5,a5,s1
    8000640a:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000640c:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006410:	ffffc097          	auipc	ra,0xffffc
    80006414:	d5e080e7          	jalr	-674(ra) # 8000216e <wakeup>

    disk.used_idx += 1;
    80006418:	0204d783          	lhu	a5,32(s1)
    8000641c:	2785                	addiw	a5,a5,1
    8000641e:	17c2                	slli	a5,a5,0x30
    80006420:	93c1                	srli	a5,a5,0x30
    80006422:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006426:	6898                	ld	a4,16(s1)
    80006428:	00275703          	lhu	a4,2(a4)
    8000642c:	faf71ce3          	bne	a4,a5,800063e4 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006430:	00024517          	auipc	a0,0x24
    80006434:	e5050513          	addi	a0,a0,-432 # 8002a280 <disk+0x128>
    80006438:	ffffb097          	auipc	ra,0xffffb
    8000643c:	866080e7          	jalr	-1946(ra) # 80000c9e <release>
}
    80006440:	60e2                	ld	ra,24(sp)
    80006442:	6442                	ld	s0,16(sp)
    80006444:	64a2                	ld	s1,8(sp)
    80006446:	6105                	addi	sp,sp,32
    80006448:	8082                	ret
      panic("virtio_disk_intr status");
    8000644a:	00002517          	auipc	a0,0x2
    8000644e:	5d650513          	addi	a0,a0,1494 # 80008a20 <syscalls+0x400>
    80006452:	ffffa097          	auipc	ra,0xffffa
    80006456:	0f2080e7          	jalr	242(ra) # 80000544 <panic>
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
