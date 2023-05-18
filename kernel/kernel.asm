
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	c4013103          	ld	sp,-960(sp) # 80008c40 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000056:	c4e70713          	addi	a4,a4,-946 # 80008ca0 <timer_scratch>
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
    80000068:	dac78793          	addi	a5,a5,-596 # 80005e10 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd4477>
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
    80000190:	c5450513          	addi	a0,a0,-940 # 80010de0 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a56080e7          	jalr	-1450(ra) # 80000bea <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	c4448493          	addi	s1,s1,-956 # 80010de0 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	cd290913          	addi	s2,s2,-814 # 80010e78 <cons+0x98>
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
    8000022e:	bb650513          	addi	a0,a0,-1098 # 80010de0 <cons>
    80000232:	00001097          	auipc	ra,0x1
    80000236:	a6c080e7          	jalr	-1428(ra) # 80000c9e <release>

  return target - n;
    8000023a:	414b853b          	subw	a0,s7,s4
    8000023e:	a811                	j	80000252 <consoleread+0xee>
        release(&cons.lock);
    80000240:	00011517          	auipc	a0,0x11
    80000244:	ba050513          	addi	a0,a0,-1120 # 80010de0 <cons>
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
    8000027c:	c0f72023          	sw	a5,-1024(a4) # 80010e78 <cons+0x98>
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
    800002d6:	b0e50513          	addi	a0,a0,-1266 # 80010de0 <cons>
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
    80000304:	ae050513          	addi	a0,a0,-1312 # 80010de0 <cons>
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
    80000328:	abc70713          	addi	a4,a4,-1348 # 80010de0 <cons>
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
    80000352:	a9278793          	addi	a5,a5,-1390 # 80010de0 <cons>
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
    80000380:	afc7a783          	lw	a5,-1284(a5) # 80010e78 <cons+0x98>
    80000384:	9f1d                	subw	a4,a4,a5
    80000386:	08000793          	li	a5,128
    8000038a:	f6f71be3          	bne	a4,a5,80000300 <consoleintr+0x3c>
    8000038e:	a07d                	j	8000043c <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000390:	00011717          	auipc	a4,0x11
    80000394:	a5070713          	addi	a4,a4,-1456 # 80010de0 <cons>
    80000398:	0a072783          	lw	a5,160(a4)
    8000039c:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a0:	00011497          	auipc	s1,0x11
    800003a4:	a4048493          	addi	s1,s1,-1472 # 80010de0 <cons>
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
    800003e0:	a0470713          	addi	a4,a4,-1532 # 80010de0 <cons>
    800003e4:	0a072783          	lw	a5,160(a4)
    800003e8:	09c72703          	lw	a4,156(a4)
    800003ec:	f0f70ae3          	beq	a4,a5,80000300 <consoleintr+0x3c>
      cons.e--;
    800003f0:	37fd                	addiw	a5,a5,-1
    800003f2:	00011717          	auipc	a4,0x11
    800003f6:	a8f72723          	sw	a5,-1394(a4) # 80010e80 <cons+0xa0>
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
    8000041c:	9c878793          	addi	a5,a5,-1592 # 80010de0 <cons>
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
    80000440:	a4c7a023          	sw	a2,-1472(a5) # 80010e7c <cons+0x9c>
        wakeup(&cons.r);
    80000444:	00011517          	auipc	a0,0x11
    80000448:	a3450513          	addi	a0,a0,-1484 # 80010e78 <cons+0x98>
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
    8000046a:	97a50513          	addi	a0,a0,-1670 # 80010de0 <cons>
    8000046e:	00000097          	auipc	ra,0x0
    80000472:	6ec080e7          	jalr	1772(ra) # 80000b5a <initlock>

  uartinit();
    80000476:	00000097          	auipc	ra,0x0
    8000047a:	330080e7          	jalr	816(ra) # 800007a6 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047e:	00029797          	auipc	a5,0x29
    80000482:	d7278793          	addi	a5,a5,-654 # 800291f0 <devsw>
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
    80000554:	9407a823          	sw	zero,-1712(a5) # 80010ea0 <pr+0x18>
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
    80000576:	4fe50513          	addi	a0,a0,1278 # 80008a70 <syscalls+0x480>
    8000057a:	00000097          	auipc	ra,0x0
    8000057e:	014080e7          	jalr	20(ra) # 8000058e <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000582:	4785                	li	a5,1
    80000584:	00008717          	auipc	a4,0x8
    80000588:	6cf72e23          	sw	a5,1756(a4) # 80008c60 <panicked>
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
    800005c4:	8e0dad83          	lw	s11,-1824(s11) # 80010ea0 <pr+0x18>
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
    80000602:	88a50513          	addi	a0,a0,-1910 # 80010e88 <pr>
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
    80000766:	72650513          	addi	a0,a0,1830 # 80010e88 <pr>
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
    80000782:	70a48493          	addi	s1,s1,1802 # 80010e88 <pr>
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
    800007e2:	6ca50513          	addi	a0,a0,1738 # 80010ea8 <uart_tx_lock>
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
    8000080e:	4567a783          	lw	a5,1110(a5) # 80008c60 <panicked>
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
    8000084a:	42273703          	ld	a4,1058(a4) # 80008c68 <uart_tx_r>
    8000084e:	00008797          	auipc	a5,0x8
    80000852:	4227b783          	ld	a5,1058(a5) # 80008c70 <uart_tx_w>
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
    80000874:	638a0a13          	addi	s4,s4,1592 # 80010ea8 <uart_tx_lock>
    uart_tx_r += 1;
    80000878:	00008497          	auipc	s1,0x8
    8000087c:	3f048493          	addi	s1,s1,1008 # 80008c68 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000880:	00008997          	auipc	s3,0x8
    80000884:	3f098993          	addi	s3,s3,1008 # 80008c70 <uart_tx_w>
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
    800008e6:	5c650513          	addi	a0,a0,1478 # 80010ea8 <uart_tx_lock>
    800008ea:	00000097          	auipc	ra,0x0
    800008ee:	300080e7          	jalr	768(ra) # 80000bea <acquire>
  if(panicked){
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	36e7a783          	lw	a5,878(a5) # 80008c60 <panicked>
    800008fa:	e7c9                	bnez	a5,80000984 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fc:	00008797          	auipc	a5,0x8
    80000900:	3747b783          	ld	a5,884(a5) # 80008c70 <uart_tx_w>
    80000904:	00008717          	auipc	a4,0x8
    80000908:	36473703          	ld	a4,868(a4) # 80008c68 <uart_tx_r>
    8000090c:	02070713          	addi	a4,a4,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00010a17          	auipc	s4,0x10
    80000914:	598a0a13          	addi	s4,s4,1432 # 80010ea8 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	35048493          	addi	s1,s1,848 # 80008c68 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	35090913          	addi	s2,s2,848 # 80008c70 <uart_tx_w>
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
    8000094a:	56248493          	addi	s1,s1,1378 # 80010ea8 <uart_tx_lock>
    8000094e:	01f7f713          	andi	a4,a5,31
    80000952:	9726                	add	a4,a4,s1
    80000954:	01370c23          	sb	s3,24(a4)
  uart_tx_w += 1;
    80000958:	0785                	addi	a5,a5,1
    8000095a:	00008717          	auipc	a4,0x8
    8000095e:	30f73b23          	sd	a5,790(a4) # 80008c70 <uart_tx_w>
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
    800009d4:	4d848493          	addi	s1,s1,1240 # 80010ea8 <uart_tx_lock>
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
    80000a16:	97678793          	addi	a5,a5,-1674 # 8002a388 <end>
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
    80000a36:	4ae90913          	addi	s2,s2,1198 # 80010ee0 <kmem>
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
    80000ad2:	41250513          	addi	a0,a0,1042 # 80010ee0 <kmem>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	084080e7          	jalr	132(ra) # 80000b5a <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ade:	45c5                	li	a1,17
    80000ae0:	05ee                	slli	a1,a1,0x1b
    80000ae2:	0002a517          	auipc	a0,0x2a
    80000ae6:	8a650513          	addi	a0,a0,-1882 # 8002a388 <end>
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
    80000b08:	3dc48493          	addi	s1,s1,988 # 80010ee0 <kmem>
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
    80000b20:	3c450513          	addi	a0,a0,964 # 80010ee0 <kmem>
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
    80000b4c:	39850513          	addi	a0,a0,920 # 80010ee0 <kmem>
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
    80000ea8:	dd470713          	addi	a4,a4,-556 # 80008c78 <started>
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
    80000ee6:	f6e080e7          	jalr	-146(ra) # 80005e50 <plicinithart>
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
    80000f02:	00008517          	auipc	a0,0x8
    80000f06:	b6e50513          	addi	a0,a0,-1170 # 80008a70 <syscalls+0x480>
    80000f0a:	fffff097          	auipc	ra,0xfffff
    80000f0e:	684080e7          	jalr	1668(ra) # 8000058e <printf>
    printf("xv6 kernel is booting\n");
    80000f12:	00007517          	auipc	a0,0x7
    80000f16:	18e50513          	addi	a0,a0,398 # 800080a0 <digits+0x60>
    80000f1a:	fffff097          	auipc	ra,0xfffff
    80000f1e:	674080e7          	jalr	1652(ra) # 8000058e <printf>
    printf("\n");
    80000f22:	00008517          	auipc	a0,0x8
    80000f26:	b4e50513          	addi	a0,a0,-1202 # 80008a70 <syscalls+0x480>
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
    80000f66:	ed8080e7          	jalr	-296(ra) # 80005e3a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6a:	00005097          	auipc	ra,0x5
    80000f6e:	ee6080e7          	jalr	-282(ra) # 80005e50 <plicinithart>
    binit();         // buffer cache
    80000f72:	00002097          	auipc	ra,0x2
    80000f76:	064080e7          	jalr	100(ra) # 80002fd6 <binit>
    iinit();         // inode table
    80000f7a:	00002097          	auipc	ra,0x2
    80000f7e:	708080e7          	jalr	1800(ra) # 80003682 <iinit>
    fileinit();      // file table
    80000f82:	00003097          	auipc	ra,0x3
    80000f86:	6ce080e7          	jalr	1742(ra) # 80004650 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8a:	00005097          	auipc	ra,0x5
    80000f8e:	fce080e7          	jalr	-50(ra) # 80005f58 <virtio_disk_init>
    userinit();      // first user process
    80000f92:	00001097          	auipc	ra,0x1
    80000f96:	d0c080e7          	jalr	-756(ra) # 80001c9e <userinit>
    __sync_synchronize();
    80000f9a:	0ff0000f          	fence
    started = 1;
    80000f9e:	4785                	li	a5,1
    80000fa0:	00008717          	auipc	a4,0x8
    80000fa4:	ccf72c23          	sw	a5,-808(a4) # 80008c78 <started>
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
    80000fb8:	ccc7b783          	ld	a5,-820(a5) # 80008c80 <kernel_pagetable>
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
    80001274:	a0a7b823          	sd	a0,-1520(a5) # 80008c80 <kernel_pagetable>
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
    8000186a:	ada48493          	addi	s1,s1,-1318 # 80011340 <proc>
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
    80001884:	6c0a0a13          	addi	s4,s4,1728 # 80016f40 <tickslock>
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
    80001906:	5fe50513          	addi	a0,a0,1534 # 80010f00 <pid_lock>
    8000190a:	fffff097          	auipc	ra,0xfffff
    8000190e:	250080e7          	jalr	592(ra) # 80000b5a <initlock>
  initlock(&wait_lock, "wait_lock");
    80001912:	00007597          	auipc	a1,0x7
    80001916:	8d658593          	addi	a1,a1,-1834 # 800081e8 <digits+0x1a8>
    8000191a:	0000f517          	auipc	a0,0xf
    8000191e:	5fe50513          	addi	a0,a0,1534 # 80010f18 <wait_lock>
    80001922:	fffff097          	auipc	ra,0xfffff
    80001926:	238080e7          	jalr	568(ra) # 80000b5a <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000192a:	00010497          	auipc	s1,0x10
    8000192e:	a1648493          	addi	s1,s1,-1514 # 80011340 <proc>
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
    80001950:	5f498993          	addi	s3,s3,1524 # 80016f40 <tickslock>
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
    800019ba:	57a50513          	addi	a0,a0,1402 # 80010f30 <cpus>
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
    800019e2:	52270713          	addi	a4,a4,1314 # 80010f00 <pid_lock>
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
    80001a1a:	10a7a783          	lw	a5,266(a5) # 80008b20 <first.1740>
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
    80001a34:	0e07a823          	sw	zero,240(a5) # 80008b20 <first.1740>
    fsinit(ROOTDEV);
    80001a38:	4505                	li	a0,1
    80001a3a:	00002097          	auipc	ra,0x2
    80001a3e:	bc8080e7          	jalr	-1080(ra) # 80003602 <fsinit>
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
    80001a54:	4b090913          	addi	s2,s2,1200 # 80010f00 <pid_lock>
    80001a58:	854a                	mv	a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	190080e7          	jalr	400(ra) # 80000bea <acquire>
  pid = nextpid;
    80001a62:	00007797          	auipc	a5,0x7
    80001a66:	0c278793          	addi	a5,a5,194 # 80008b24 <nextpid>
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
    80001be0:	76448493          	addi	s1,s1,1892 # 80011340 <proc>
    80001be4:	00015917          	auipc	s2,0x15
    80001be8:	35c90913          	addi	s2,s2,860 # 80016f40 <tickslock>
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
    80001cb6:	fca7bb23          	sd	a0,-42(a5) # 80008c88 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cba:	03400613          	li	a2,52
    80001cbe:	00007597          	auipc	a1,0x7
    80001cc2:	e7258593          	addi	a1,a1,-398 # 80008b30 <initcode>
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
    80001d00:	350080e7          	jalr	848(ra) # 8000404c <namei>
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
    80001e1e:	8c8080e7          	jalr	-1848(ra) # 800046e2 <filedup>
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
    80001e40:	a04080e7          	jalr	-1532(ra) # 80003840 <idup>
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
    80001e6c:	0b048493          	addi	s1,s1,176 # 80010f18 <wait_lock>
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
    80001f62:	fa270713          	addi	a4,a4,-94 # 80010f00 <pid_lock>
    80001f66:	975a                	add	a4,a4,s6
    80001f68:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f6c:	0000f717          	auipc	a4,0xf
    80001f70:	fcc70713          	addi	a4,a4,-52 # 80010f38 <cpus+0x8>
    80001f74:	9b3a                	add	s6,s6,a4
        p->state = RUNNING;
    80001f76:	4b91                	li	s7,4
        c->proc = p;
    80001f78:	079e                	slli	a5,a5,0x7
    80001f7a:	0000fa97          	auipc	s5,0xf
    80001f7e:	f86a8a93          	addi	s5,s5,-122 # 80010f00 <pid_lock>
    80001f82:	9abe                	add	s5,s5,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f84:	00015a17          	auipc	s4,0x15
    80001f88:	fbca0a13          	addi	s4,s4,-68 # 80016f40 <tickslock>
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
    80001fea:	35a48493          	addi	s1,s1,858 # 80011340 <proc>
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
    80002024:	ee070713          	addi	a4,a4,-288 # 80010f00 <pid_lock>
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
    8000204a:	eba90913          	addi	s2,s2,-326 # 80010f00 <pid_lock>
    8000204e:	2781                	sext.w	a5,a5
    80002050:	079e                	slli	a5,a5,0x7
    80002052:	97ca                	add	a5,a5,s2
    80002054:	0ac7a983          	lw	s3,172(a5)
    80002058:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000205a:	2781                	sext.w	a5,a5
    8000205c:	079e                	slli	a5,a5,0x7
    8000205e:	0000f597          	auipc	a1,0xf
    80002062:	eda58593          	addi	a1,a1,-294 # 80010f38 <cpus+0x8>
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
    80002186:	1be48493          	addi	s1,s1,446 # 80011340 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000218a:	4989                	li	s3,2
        p->state = RUNNABLE;
    8000218c:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000218e:	00015917          	auipc	s2,0x15
    80002192:	db290913          	addi	s2,s2,-590 # 80016f40 <tickslock>
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
    800021fa:	14a48493          	addi	s1,s1,330 # 80011340 <proc>
      pp->parent = initproc;
    800021fe:	00007a17          	auipc	s4,0x7
    80002202:	a8aa0a13          	addi	s4,s4,-1398 # 80008c88 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002206:	00015997          	auipc	s3,0x15
    8000220a:	d3a98993          	addi	s3,s3,-710 # 80016f40 <tickslock>
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
    8000225e:	a2e7b783          	ld	a5,-1490(a5) # 80008c88 <initproc>
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
    80002282:	4b6080e7          	jalr	1206(ra) # 80004734 <fileclose>
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
    8000229a:	fd2080e7          	jalr	-46(ra) # 80004268 <begin_op>
  iput(p->cwd);
    8000229e:	1509b503          	ld	a0,336(s3)
    800022a2:	00001097          	auipc	ra,0x1
    800022a6:	796080e7          	jalr	1942(ra) # 80003a38 <iput>
  end_op();
    800022aa:	00002097          	auipc	ra,0x2
    800022ae:	03e080e7          	jalr	62(ra) # 800042e8 <end_op>
  p->cwd = 0;
    800022b2:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800022b6:	0000f497          	auipc	s1,0xf
    800022ba:	c6248493          	addi	s1,s1,-926 # 80010f18 <wait_lock>
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
    80002328:	01c48493          	addi	s1,s1,28 # 80011340 <proc>
    8000232c:	00015997          	auipc	s3,0x15
    80002330:	c1498993          	addi	s3,s3,-1004 # 80016f40 <tickslock>
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
    8000240c:	b1050513          	addi	a0,a0,-1264 # 80010f18 <wait_lock>
    80002410:	ffffe097          	auipc	ra,0xffffe
    80002414:	7da080e7          	jalr	2010(ra) # 80000bea <acquire>
    havekids = 0;
    80002418:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    8000241a:	4a15                	li	s4,5
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000241c:	00015997          	auipc	s3,0x15
    80002420:	b2498993          	addi	s3,s3,-1244 # 80016f40 <tickslock>
        havekids = 1;
    80002424:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002426:	0000fc17          	auipc	s8,0xf
    8000242a:	af2c0c13          	addi	s8,s8,-1294 # 80010f18 <wait_lock>
    havekids = 0;
    8000242e:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002430:	0000f497          	auipc	s1,0xf
    80002434:	f1048493          	addi	s1,s1,-240 # 80011340 <proc>
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
    80002472:	aaa50513          	addi	a0,a0,-1366 # 80010f18 <wait_lock>
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
    8000248e:	a8e50513          	addi	a0,a0,-1394 # 80010f18 <wait_lock>
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
    800024dc:	a4050513          	addi	a0,a0,-1472 # 80010f18 <wait_lock>
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
    800025d8:	49c50513          	addi	a0,a0,1180 # 80008a70 <syscalls+0x480>
    800025dc:	ffffe097          	auipc	ra,0xffffe
    800025e0:	fb2080e7          	jalr	-78(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025e4:	0000f497          	auipc	s1,0xf
    800025e8:	eb448493          	addi	s1,s1,-332 # 80011498 <proc+0x158>
    800025ec:	00015917          	auipc	s2,0x15
    800025f0:	aac90913          	addi	s2,s2,-1364 # 80017098 <bruh+0xd8>
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
    8000260a:	46aa0a13          	addi	s4,s4,1130 # 80008a70 <syscalls+0x480>
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
    800026a6:	300080e7          	jalr	768(ra) # 800069a2 <write_to_logs>
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
    80002756:	7ee50513          	addi	a0,a0,2030 # 80016f40 <tickslock>
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
    80002774:	61078793          	addi	a5,a5,1552 # 80005d80 <kernelvec>
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
    80002826:	71e48493          	addi	s1,s1,1822 # 80016f40 <tickslock>
    8000282a:	8526                	mv	a0,s1
    8000282c:	ffffe097          	auipc	ra,0xffffe
    80002830:	3be080e7          	jalr	958(ra) # 80000bea <acquire>
  ticks++;
    80002834:	00006517          	auipc	a0,0x6
    80002838:	45c50513          	addi	a0,a0,1116 # 80008c90 <ticks>
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
    80002894:	5f8080e7          	jalr	1528(ra) # 80005e88 <plic_claim>
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
    800028c2:	5ee080e7          	jalr	1518(ra) # 80005eac <plic_complete>
    return 1;
    800028c6:	4505                	li	a0,1
    800028c8:	bf55                	j	8000287c <devintr+0x1e>
      uartintr();
    800028ca:	ffffe097          	auipc	ra,0xffffe
    800028ce:	0e4080e7          	jalr	228(ra) # 800009ae <uartintr>
    800028d2:	b7ed                	j	800028bc <devintr+0x5e>
      virtio_disk_intr();
    800028d4:	00004097          	auipc	ra,0x4
    800028d8:	b02080e7          	jalr	-1278(ra) # 800063d6 <virtio_disk_intr>
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
    8000291a:	46a78793          	addi	a5,a5,1130 # 80005d80 <kernelvec>
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
    80002afc:	ae070713          	addi	a4,a4,-1312 # 800085d8 <states.1784+0x248>
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
    80002c5a:	7179                	addi	sp,sp,-48
    80002c5c:	f406                	sd	ra,40(sp)
    80002c5e:	f022                	sd	s0,32(sp)
    80002c60:	ec26                	sd	s1,24(sp)
    80002c62:	e84a                	sd	s2,16(sp)
    80002c64:	e44e                	sd	s3,8(sp)
    80002c66:	1800                	addi	s0,sp,48
  int num;
  struct proc *p = myproc();
    80002c68:	fffff097          	auipc	ra,0xfffff
    80002c6c:	d5e080e7          	jalr	-674(ra) # 800019c6 <myproc>
    80002c70:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002c72:	05853903          	ld	s2,88(a0)
    80002c76:	0a893783          	ld	a5,168(s2)
    80002c7a:	0007899b          	sext.w	s3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c7e:	37fd                	addiw	a5,a5,-1
    80002c80:	475d                	li	a4,23
    80002c82:	08f76a63          	bltu	a4,a5,80002d16 <syscall+0xbc>
    80002c86:	00399713          	slli	a4,s3,0x3
    80002c8a:	00006797          	auipc	a5,0x6
    80002c8e:	96678793          	addi	a5,a5,-1690 # 800085f0 <syscalls>
    80002c92:	97ba                	add	a5,a5,a4
    80002c94:	639c                	ld	a5,0(a5)
    80002c96:	c3c1                	beqz	a5,80002d16 <syscall+0xbc>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0

    p->trapframe->a0 = syscalls[num]();
    80002c98:	9782                	jalr	a5
    80002c9a:	06a93823          	sd	a0,112(s2)
    // if our system call was AUDIT, we specifically need to take what's in a0
    // out right here. this contains the whitelist array for what calls to audit
    if (num == 22) {
    80002c9e:	47d9                	li	a5,22
    80002ca0:	00f98d63          	beq	s3,a5,80002cba <syscall+0x60>
      }
      declared_length = *(bruh->length);
      //printf("process %s with id %d called audit at time %d\n", p->name, p->pid, ticks);
      printf("declared length: %d\n", declared_length);
    }
    if (!declared_length) {
    80002ca4:	00006717          	auipc	a4,0x6
    80002ca8:	ff072703          	lw	a4,-16(a4) # 80008c94 <declared_length>
      // nothing is whitelisted.
      //printf("process %s with id %d called %s at time %d\n", p->name, p->pid, name_from_num[num], ticks);
    } else {
      // something is whitelisted.
      for (int i = 0; i < declared_length; i++) {
    80002cac:	08e05463          	blez	a4,80002d34 <syscall+0xda>
    80002cb0:	4781                	li	a5,0
    80002cb2:	2785                	addiw	a5,a5,1
    80002cb4:	fef71fe3          	bne	a4,a5,80002cb2 <syscall+0x58>
    80002cb8:	a8b5                	j	80002d34 <syscall+0xda>
      struct aud* bruh = (struct aud*)p->trapframe->a0;
    80002cba:	6cbc                	ld	a5,88(s1)
    80002cbc:	7ba4                	ld	s1,112(a5)
      printf("edit in kernel\n");
    80002cbe:	00006517          	auipc	a0,0x6
    80002cc2:	82250513          	addi	a0,a0,-2014 # 800084e0 <states.1784+0x150>
    80002cc6:	ffffe097          	auipc	ra,0xffffe
    80002cca:	8c8080e7          	jalr	-1848(ra) # 8000058e <printf>
      for (int i = 0; i < *(bruh->length); i++) {
    80002cce:	649c                	ld	a5,8(s1)
    80002cd0:	438c                	lw	a1,0(a5)
    80002cd2:	02b05563          	blez	a1,80002cfc <syscall+0xa2>
    80002cd6:	00014697          	auipc	a3,0x14
    80002cda:	28268693          	addi	a3,a3,642 # 80016f58 <whitelisted>
    80002cde:	4781                	li	a5,0
        whitelisted[i] = *(bruh->arr + i);
    80002ce0:	6098                	ld	a4,0(s1)
    80002ce2:	00279613          	slli	a2,a5,0x2
    80002ce6:	9732                	add	a4,a4,a2
    80002ce8:	4318                	lw	a4,0(a4)
    80002cea:	c298                	sw	a4,0(a3)
      for (int i = 0; i < *(bruh->length); i++) {
    80002cec:	6498                	ld	a4,8(s1)
    80002cee:	430c                	lw	a1,0(a4)
    80002cf0:	0785                	addi	a5,a5,1
    80002cf2:	0691                	addi	a3,a3,4
    80002cf4:	0007871b          	sext.w	a4,a5
    80002cf8:	feb744e3          	blt	a4,a1,80002ce0 <syscall+0x86>
      declared_length = *(bruh->length);
    80002cfc:	00006797          	auipc	a5,0x6
    80002d00:	f8b7ac23          	sw	a1,-104(a5) # 80008c94 <declared_length>
      printf("declared length: %d\n", declared_length);
    80002d04:	00005517          	auipc	a0,0x5
    80002d08:	7ec50513          	addi	a0,a0,2028 # 800084f0 <states.1784+0x160>
    80002d0c:	ffffe097          	auipc	ra,0xffffe
    80002d10:	882080e7          	jalr	-1918(ra) # 8000058e <printf>
    80002d14:	bf41                	j	80002ca4 <syscall+0x4a>
        }
      }
    }

  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d16:	86ce                	mv	a3,s3
    80002d18:	15848613          	addi	a2,s1,344
    80002d1c:	588c                	lw	a1,48(s1)
    80002d1e:	00005517          	auipc	a0,0x5
    80002d22:	7ea50513          	addi	a0,a0,2026 # 80008508 <states.1784+0x178>
    80002d26:	ffffe097          	auipc	ra,0xffffe
    80002d2a:	868080e7          	jalr	-1944(ra) # 8000058e <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d2e:	6cbc                	ld	a5,88(s1)
    80002d30:	577d                	li	a4,-1
    80002d32:	fbb8                	sd	a4,112(a5)
  }

}
    80002d34:	70a2                	ld	ra,40(sp)
    80002d36:	7402                	ld	s0,32(sp)
    80002d38:	64e2                	ld	s1,24(sp)
    80002d3a:	6942                	ld	s2,16(sp)
    80002d3c:	69a2                	ld	s3,8(sp)
    80002d3e:	6145                	addi	sp,sp,48
    80002d40:	8082                	ret

0000000080002d42 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002d42:	1101                	addi	sp,sp,-32
    80002d44:	ec06                	sd	ra,24(sp)
    80002d46:	e822                	sd	s0,16(sp)
    80002d48:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002d4a:	fec40593          	addi	a1,s0,-20
    80002d4e:	4501                	li	a0,0
    80002d50:	00000097          	auipc	ra,0x0
    80002d54:	e92080e7          	jalr	-366(ra) # 80002be2 <argint>
  exit(n);
    80002d58:	fec42503          	lw	a0,-20(s0)
    80002d5c:	fffff097          	auipc	ra,0xfffff
    80002d60:	4e2080e7          	jalr	1250(ra) # 8000223e <exit>
  return 0;  // not reached
}
    80002d64:	4501                	li	a0,0
    80002d66:	60e2                	ld	ra,24(sp)
    80002d68:	6442                	ld	s0,16(sp)
    80002d6a:	6105                	addi	sp,sp,32
    80002d6c:	8082                	ret

0000000080002d6e <sys_getpid>:

uint64
sys_getpid(void)
{
    80002d6e:	1141                	addi	sp,sp,-16
    80002d70:	e406                	sd	ra,8(sp)
    80002d72:	e022                	sd	s0,0(sp)
    80002d74:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002d76:	fffff097          	auipc	ra,0xfffff
    80002d7a:	c50080e7          	jalr	-944(ra) # 800019c6 <myproc>
}
    80002d7e:	5908                	lw	a0,48(a0)
    80002d80:	60a2                	ld	ra,8(sp)
    80002d82:	6402                	ld	s0,0(sp)
    80002d84:	0141                	addi	sp,sp,16
    80002d86:	8082                	ret

0000000080002d88 <sys_fork>:

uint64
sys_fork(void)
{
    80002d88:	1141                	addi	sp,sp,-16
    80002d8a:	e406                	sd	ra,8(sp)
    80002d8c:	e022                	sd	s0,0(sp)
    80002d8e:	0800                	addi	s0,sp,16
  return fork();
    80002d90:	fffff097          	auipc	ra,0xfffff
    80002d94:	fec080e7          	jalr	-20(ra) # 80001d7c <fork>
}
    80002d98:	60a2                	ld	ra,8(sp)
    80002d9a:	6402                	ld	s0,0(sp)
    80002d9c:	0141                	addi	sp,sp,16
    80002d9e:	8082                	ret

0000000080002da0 <sys_wait>:

uint64
sys_wait(void)
{
    80002da0:	1101                	addi	sp,sp,-32
    80002da2:	ec06                	sd	ra,24(sp)
    80002da4:	e822                	sd	s0,16(sp)
    80002da6:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002da8:	fe840593          	addi	a1,s0,-24
    80002dac:	4501                	li	a0,0
    80002dae:	00000097          	auipc	ra,0x0
    80002db2:	e54080e7          	jalr	-428(ra) # 80002c02 <argaddr>
  return wait(p);
    80002db6:	fe843503          	ld	a0,-24(s0)
    80002dba:	fffff097          	auipc	ra,0xfffff
    80002dbe:	62a080e7          	jalr	1578(ra) # 800023e4 <wait>
}
    80002dc2:	60e2                	ld	ra,24(sp)
    80002dc4:	6442                	ld	s0,16(sp)
    80002dc6:	6105                	addi	sp,sp,32
    80002dc8:	8082                	ret

0000000080002dca <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002dca:	7179                	addi	sp,sp,-48
    80002dcc:	f406                	sd	ra,40(sp)
    80002dce:	f022                	sd	s0,32(sp)
    80002dd0:	ec26                	sd	s1,24(sp)
    80002dd2:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002dd4:	fdc40593          	addi	a1,s0,-36
    80002dd8:	4501                	li	a0,0
    80002dda:	00000097          	auipc	ra,0x0
    80002dde:	e08080e7          	jalr	-504(ra) # 80002be2 <argint>
  addr = myproc()->sz;
    80002de2:	fffff097          	auipc	ra,0xfffff
    80002de6:	be4080e7          	jalr	-1052(ra) # 800019c6 <myproc>
    80002dea:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002dec:	fdc42503          	lw	a0,-36(s0)
    80002df0:	fffff097          	auipc	ra,0xfffff
    80002df4:	f30080e7          	jalr	-208(ra) # 80001d20 <growproc>
    80002df8:	00054863          	bltz	a0,80002e08 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002dfc:	8526                	mv	a0,s1
    80002dfe:	70a2                	ld	ra,40(sp)
    80002e00:	7402                	ld	s0,32(sp)
    80002e02:	64e2                	ld	s1,24(sp)
    80002e04:	6145                	addi	sp,sp,48
    80002e06:	8082                	ret
    return -1;
    80002e08:	54fd                	li	s1,-1
    80002e0a:	bfcd                	j	80002dfc <sys_sbrk+0x32>

0000000080002e0c <sys_sleep>:

uint64
sys_sleep(void)
{
    80002e0c:	7139                	addi	sp,sp,-64
    80002e0e:	fc06                	sd	ra,56(sp)
    80002e10:	f822                	sd	s0,48(sp)
    80002e12:	f426                	sd	s1,40(sp)
    80002e14:	f04a                	sd	s2,32(sp)
    80002e16:	ec4e                	sd	s3,24(sp)
    80002e18:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002e1a:	fcc40593          	addi	a1,s0,-52
    80002e1e:	4501                	li	a0,0
    80002e20:	00000097          	auipc	ra,0x0
    80002e24:	dc2080e7          	jalr	-574(ra) # 80002be2 <argint>
  acquire(&tickslock);
    80002e28:	00014517          	auipc	a0,0x14
    80002e2c:	11850513          	addi	a0,a0,280 # 80016f40 <tickslock>
    80002e30:	ffffe097          	auipc	ra,0xffffe
    80002e34:	dba080e7          	jalr	-582(ra) # 80000bea <acquire>
  ticks0 = ticks;
    80002e38:	00006917          	auipc	s2,0x6
    80002e3c:	e5892903          	lw	s2,-424(s2) # 80008c90 <ticks>
  while(ticks - ticks0 < n){
    80002e40:	fcc42783          	lw	a5,-52(s0)
    80002e44:	cf9d                	beqz	a5,80002e82 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002e46:	00014997          	auipc	s3,0x14
    80002e4a:	0fa98993          	addi	s3,s3,250 # 80016f40 <tickslock>
    80002e4e:	00006497          	auipc	s1,0x6
    80002e52:	e4248493          	addi	s1,s1,-446 # 80008c90 <ticks>
    if(killed(myproc())){
    80002e56:	fffff097          	auipc	ra,0xfffff
    80002e5a:	b70080e7          	jalr	-1168(ra) # 800019c6 <myproc>
    80002e5e:	fffff097          	auipc	ra,0xfffff
    80002e62:	554080e7          	jalr	1364(ra) # 800023b2 <killed>
    80002e66:	ed15                	bnez	a0,80002ea2 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002e68:	85ce                	mv	a1,s3
    80002e6a:	8526                	mv	a0,s1
    80002e6c:	fffff097          	auipc	ra,0xfffff
    80002e70:	29e080e7          	jalr	670(ra) # 8000210a <sleep>
  while(ticks - ticks0 < n){
    80002e74:	409c                	lw	a5,0(s1)
    80002e76:	412787bb          	subw	a5,a5,s2
    80002e7a:	fcc42703          	lw	a4,-52(s0)
    80002e7e:	fce7ece3          	bltu	a5,a4,80002e56 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002e82:	00014517          	auipc	a0,0x14
    80002e86:	0be50513          	addi	a0,a0,190 # 80016f40 <tickslock>
    80002e8a:	ffffe097          	auipc	ra,0xffffe
    80002e8e:	e14080e7          	jalr	-492(ra) # 80000c9e <release>
  return 0;
    80002e92:	4501                	li	a0,0
}
    80002e94:	70e2                	ld	ra,56(sp)
    80002e96:	7442                	ld	s0,48(sp)
    80002e98:	74a2                	ld	s1,40(sp)
    80002e9a:	7902                	ld	s2,32(sp)
    80002e9c:	69e2                	ld	s3,24(sp)
    80002e9e:	6121                	addi	sp,sp,64
    80002ea0:	8082                	ret
      release(&tickslock);
    80002ea2:	00014517          	auipc	a0,0x14
    80002ea6:	09e50513          	addi	a0,a0,158 # 80016f40 <tickslock>
    80002eaa:	ffffe097          	auipc	ra,0xffffe
    80002eae:	df4080e7          	jalr	-524(ra) # 80000c9e <release>
      return -1;
    80002eb2:	557d                	li	a0,-1
    80002eb4:	b7c5                	j	80002e94 <sys_sleep+0x88>

0000000080002eb6 <sys_kill>:

uint64
sys_kill(void)
{
    80002eb6:	1101                	addi	sp,sp,-32
    80002eb8:	ec06                	sd	ra,24(sp)
    80002eba:	e822                	sd	s0,16(sp)
    80002ebc:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002ebe:	fec40593          	addi	a1,s0,-20
    80002ec2:	4501                	li	a0,0
    80002ec4:	00000097          	auipc	ra,0x0
    80002ec8:	d1e080e7          	jalr	-738(ra) # 80002be2 <argint>
  return kill(pid);
    80002ecc:	fec42503          	lw	a0,-20(s0)
    80002ed0:	fffff097          	auipc	ra,0xfffff
    80002ed4:	444080e7          	jalr	1092(ra) # 80002314 <kill>
}
    80002ed8:	60e2                	ld	ra,24(sp)
    80002eda:	6442                	ld	s0,16(sp)
    80002edc:	6105                	addi	sp,sp,32
    80002ede:	8082                	ret

0000000080002ee0 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002ee0:	1101                	addi	sp,sp,-32
    80002ee2:	ec06                	sd	ra,24(sp)
    80002ee4:	e822                	sd	s0,16(sp)
    80002ee6:	e426                	sd	s1,8(sp)
    80002ee8:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002eea:	00014517          	auipc	a0,0x14
    80002eee:	05650513          	addi	a0,a0,86 # 80016f40 <tickslock>
    80002ef2:	ffffe097          	auipc	ra,0xffffe
    80002ef6:	cf8080e7          	jalr	-776(ra) # 80000bea <acquire>
  xticks = ticks;
    80002efa:	00006497          	auipc	s1,0x6
    80002efe:	d964a483          	lw	s1,-618(s1) # 80008c90 <ticks>
  release(&tickslock);
    80002f02:	00014517          	auipc	a0,0x14
    80002f06:	03e50513          	addi	a0,a0,62 # 80016f40 <tickslock>
    80002f0a:	ffffe097          	auipc	ra,0xffffe
    80002f0e:	d94080e7          	jalr	-620(ra) # 80000c9e <release>
  return xticks;
}
    80002f12:	02049513          	slli	a0,s1,0x20
    80002f16:	9101                	srli	a0,a0,0x20
    80002f18:	60e2                	ld	ra,24(sp)
    80002f1a:	6442                	ld	s0,16(sp)
    80002f1c:	64a2                	ld	s1,8(sp)
    80002f1e:	6105                	addi	sp,sp,32
    80002f20:	8082                	ret

0000000080002f22 <sys_audit>:

uint64
sys_audit(void)
{
    80002f22:	1101                	addi	sp,sp,-32
    80002f24:	ec06                	sd	ra,24(sp)
    80002f26:	e822                	sd	s0,16(sp)
    80002f28:	1000                	addi	s0,sp,32
  printf("in sys audit\n");
    80002f2a:	00005517          	auipc	a0,0x5
    80002f2e:	78e50513          	addi	a0,a0,1934 # 800086b8 <syscalls+0xc8>
    80002f32:	ffffd097          	auipc	ra,0xffffd
    80002f36:	65c080e7          	jalr	1628(ra) # 8000058e <printf>
  uint64 arr_addr;
  uint64 length;
  argaddr(0, &arr_addr);
    80002f3a:	fe840593          	addi	a1,s0,-24
    80002f3e:	4501                	li	a0,0
    80002f40:	00000097          	auipc	ra,0x0
    80002f44:	cc2080e7          	jalr	-830(ra) # 80002c02 <argaddr>
  argaddr(1, &length);
    80002f48:	fe040593          	addi	a1,s0,-32
    80002f4c:	4505                	li	a0,1
    80002f4e:	00000097          	auipc	ra,0x0
    80002f52:	cb4080e7          	jalr	-844(ra) # 80002c02 <argaddr>
  printf("address of length: %p\n", (int*) length);
    80002f56:	fe043583          	ld	a1,-32(s0)
    80002f5a:	00005517          	auipc	a0,0x5
    80002f5e:	76e50513          	addi	a0,a0,1902 # 800086c8 <syscalls+0xd8>
    80002f62:	ffffd097          	auipc	ra,0xffffd
    80002f66:	62c080e7          	jalr	1580(ra) # 8000058e <printf>
  return audit((int*) arr_addr, (int*) length);
    80002f6a:	fe043583          	ld	a1,-32(s0)
    80002f6e:	fe843503          	ld	a0,-24(s0)
    80002f72:	fffff097          	auipc	ra,0xfffff
    80002f76:	f46080e7          	jalr	-186(ra) # 80001eb8 <audit>
}
    80002f7a:	60e2                	ld	ra,24(sp)
    80002f7c:	6442                	ld	s0,16(sp)
    80002f7e:	6105                	addi	sp,sp,32
    80002f80:	8082                	ret

0000000080002f82 <sys_logs>:

uint64           
sys_logs(void)
{
    80002f82:	1101                	addi	sp,sp,-32
    80002f84:	ec06                	sd	ra,24(sp)
    80002f86:	e822                	sd	s0,16(sp)
    80002f88:	1000                	addi	s0,sp,32
    uint64 addr;
    argaddr(0, &addr);
    80002f8a:	fe840593          	addi	a1,s0,-24
    80002f8e:	4501                	li	a0,0
    80002f90:	00000097          	auipc	ra,0x0
    80002f94:	c72080e7          	jalr	-910(ra) # 80002c02 <argaddr>
    return logs((void *) addr);
    80002f98:	fe843503          	ld	a0,-24(s0)
    80002f9c:	fffff097          	auipc	ra,0xfffff
    80002fa0:	6d0080e7          	jalr	1744(ra) # 8000266c <logs>
}
    80002fa4:	60e2                	ld	ra,24(sp)
    80002fa6:	6442                	ld	s0,16(sp)
    80002fa8:	6105                	addi	sp,sp,32
    80002faa:	8082                	ret

0000000080002fac <sys_try2>:

uint64 sys_try2(void){
    80002fac:	1101                	addi	sp,sp,-32
    80002fae:	ec06                	sd	ra,24(sp)
    80002fb0:	e822                	sd	s0,16(sp)
    80002fb2:	1000                	addi	s0,sp,32
    uint64 addr;
    argaddr(0, &addr);
    80002fb4:	fe840593          	addi	a1,s0,-24
    80002fb8:	4501                	li	a0,0
    80002fba:	00000097          	auipc	ra,0x0
    80002fbe:	c48080e7          	jalr	-952(ra) # 80002c02 <argaddr>
    return try2((void *) addr);
    80002fc2:	fe843503          	ld	a0,-24(s0)
    80002fc6:	fffff097          	auipc	ra,0xfffff
    80002fca:	6ee080e7          	jalr	1774(ra) # 800026b4 <try2>
}
    80002fce:	60e2                	ld	ra,24(sp)
    80002fd0:	6442                	ld	s0,16(sp)
    80002fd2:	6105                	addi	sp,sp,32
    80002fd4:	8082                	ret

0000000080002fd6 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002fd6:	7179                	addi	sp,sp,-48
    80002fd8:	f406                	sd	ra,40(sp)
    80002fda:	f022                	sd	s0,32(sp)
    80002fdc:	ec26                	sd	s1,24(sp)
    80002fde:	e84a                	sd	s2,16(sp)
    80002fe0:	e44e                	sd	s3,8(sp)
    80002fe2:	e052                	sd	s4,0(sp)
    80002fe4:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002fe6:	00005597          	auipc	a1,0x5
    80002fea:	6fa58593          	addi	a1,a1,1786 # 800086e0 <syscalls+0xf0>
    80002fee:	0001c517          	auipc	a0,0x1c
    80002ff2:	fd250513          	addi	a0,a0,-46 # 8001efc0 <bcache>
    80002ff6:	ffffe097          	auipc	ra,0xffffe
    80002ffa:	b64080e7          	jalr	-1180(ra) # 80000b5a <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002ffe:	00024797          	auipc	a5,0x24
    80003002:	fc278793          	addi	a5,a5,-62 # 80026fc0 <bcache+0x8000>
    80003006:	00024717          	auipc	a4,0x24
    8000300a:	22270713          	addi	a4,a4,546 # 80027228 <bcache+0x8268>
    8000300e:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003012:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003016:	0001c497          	auipc	s1,0x1c
    8000301a:	fc248493          	addi	s1,s1,-62 # 8001efd8 <bcache+0x18>
    b->next = bcache.head.next;
    8000301e:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003020:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003022:	00005a17          	auipc	s4,0x5
    80003026:	6c6a0a13          	addi	s4,s4,1734 # 800086e8 <syscalls+0xf8>
    b->next = bcache.head.next;
    8000302a:	2b893783          	ld	a5,696(s2)
    8000302e:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003030:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003034:	85d2                	mv	a1,s4
    80003036:	01048513          	addi	a0,s1,16
    8000303a:	00001097          	auipc	ra,0x1
    8000303e:	4ec080e7          	jalr	1260(ra) # 80004526 <initsleeplock>
    bcache.head.next->prev = b;
    80003042:	2b893783          	ld	a5,696(s2)
    80003046:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003048:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000304c:	45848493          	addi	s1,s1,1112
    80003050:	fd349de3          	bne	s1,s3,8000302a <binit+0x54>
  }
}
    80003054:	70a2                	ld	ra,40(sp)
    80003056:	7402                	ld	s0,32(sp)
    80003058:	64e2                	ld	s1,24(sp)
    8000305a:	6942                	ld	s2,16(sp)
    8000305c:	69a2                	ld	s3,8(sp)
    8000305e:	6a02                	ld	s4,0(sp)
    80003060:	6145                	addi	sp,sp,48
    80003062:	8082                	ret

0000000080003064 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003064:	7179                	addi	sp,sp,-48
    80003066:	f406                	sd	ra,40(sp)
    80003068:	f022                	sd	s0,32(sp)
    8000306a:	ec26                	sd	s1,24(sp)
    8000306c:	e84a                	sd	s2,16(sp)
    8000306e:	e44e                	sd	s3,8(sp)
    80003070:	1800                	addi	s0,sp,48
    80003072:	89aa                	mv	s3,a0
    80003074:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003076:	0001c517          	auipc	a0,0x1c
    8000307a:	f4a50513          	addi	a0,a0,-182 # 8001efc0 <bcache>
    8000307e:	ffffe097          	auipc	ra,0xffffe
    80003082:	b6c080e7          	jalr	-1172(ra) # 80000bea <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003086:	00024497          	auipc	s1,0x24
    8000308a:	1f24b483          	ld	s1,498(s1) # 80027278 <bcache+0x82b8>
    8000308e:	00024797          	auipc	a5,0x24
    80003092:	19a78793          	addi	a5,a5,410 # 80027228 <bcache+0x8268>
    80003096:	02f48f63          	beq	s1,a5,800030d4 <bread+0x70>
    8000309a:	873e                	mv	a4,a5
    8000309c:	a021                	j	800030a4 <bread+0x40>
    8000309e:	68a4                	ld	s1,80(s1)
    800030a0:	02e48a63          	beq	s1,a4,800030d4 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800030a4:	449c                	lw	a5,8(s1)
    800030a6:	ff379ce3          	bne	a5,s3,8000309e <bread+0x3a>
    800030aa:	44dc                	lw	a5,12(s1)
    800030ac:	ff2799e3          	bne	a5,s2,8000309e <bread+0x3a>
      b->refcnt++;
    800030b0:	40bc                	lw	a5,64(s1)
    800030b2:	2785                	addiw	a5,a5,1
    800030b4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800030b6:	0001c517          	auipc	a0,0x1c
    800030ba:	f0a50513          	addi	a0,a0,-246 # 8001efc0 <bcache>
    800030be:	ffffe097          	auipc	ra,0xffffe
    800030c2:	be0080e7          	jalr	-1056(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    800030c6:	01048513          	addi	a0,s1,16
    800030ca:	00001097          	auipc	ra,0x1
    800030ce:	496080e7          	jalr	1174(ra) # 80004560 <acquiresleep>
      return b;
    800030d2:	a8b9                	j	80003130 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030d4:	00024497          	auipc	s1,0x24
    800030d8:	19c4b483          	ld	s1,412(s1) # 80027270 <bcache+0x82b0>
    800030dc:	00024797          	auipc	a5,0x24
    800030e0:	14c78793          	addi	a5,a5,332 # 80027228 <bcache+0x8268>
    800030e4:	00f48863          	beq	s1,a5,800030f4 <bread+0x90>
    800030e8:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800030ea:	40bc                	lw	a5,64(s1)
    800030ec:	cf81                	beqz	a5,80003104 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030ee:	64a4                	ld	s1,72(s1)
    800030f0:	fee49de3          	bne	s1,a4,800030ea <bread+0x86>
  panic("bget: no buffers");
    800030f4:	00005517          	auipc	a0,0x5
    800030f8:	5fc50513          	addi	a0,a0,1532 # 800086f0 <syscalls+0x100>
    800030fc:	ffffd097          	auipc	ra,0xffffd
    80003100:	448080e7          	jalr	1096(ra) # 80000544 <panic>
      b->dev = dev;
    80003104:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003108:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000310c:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003110:	4785                	li	a5,1
    80003112:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003114:	0001c517          	auipc	a0,0x1c
    80003118:	eac50513          	addi	a0,a0,-340 # 8001efc0 <bcache>
    8000311c:	ffffe097          	auipc	ra,0xffffe
    80003120:	b82080e7          	jalr	-1150(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    80003124:	01048513          	addi	a0,s1,16
    80003128:	00001097          	auipc	ra,0x1
    8000312c:	438080e7          	jalr	1080(ra) # 80004560 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003130:	409c                	lw	a5,0(s1)
    80003132:	cb89                	beqz	a5,80003144 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003134:	8526                	mv	a0,s1
    80003136:	70a2                	ld	ra,40(sp)
    80003138:	7402                	ld	s0,32(sp)
    8000313a:	64e2                	ld	s1,24(sp)
    8000313c:	6942                	ld	s2,16(sp)
    8000313e:	69a2                	ld	s3,8(sp)
    80003140:	6145                	addi	sp,sp,48
    80003142:	8082                	ret
    virtio_disk_rw(b, 0);
    80003144:	4581                	li	a1,0
    80003146:	8526                	mv	a0,s1
    80003148:	00003097          	auipc	ra,0x3
    8000314c:	000080e7          	jalr	ra # 80006148 <virtio_disk_rw>
    b->valid = 1;
    80003150:	4785                	li	a5,1
    80003152:	c09c                	sw	a5,0(s1)
  return b;
    80003154:	b7c5                	j	80003134 <bread+0xd0>

0000000080003156 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003156:	1101                	addi	sp,sp,-32
    80003158:	ec06                	sd	ra,24(sp)
    8000315a:	e822                	sd	s0,16(sp)
    8000315c:	e426                	sd	s1,8(sp)
    8000315e:	1000                	addi	s0,sp,32
    80003160:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003162:	0541                	addi	a0,a0,16
    80003164:	00001097          	auipc	ra,0x1
    80003168:	496080e7          	jalr	1174(ra) # 800045fa <holdingsleep>
    8000316c:	cd01                	beqz	a0,80003184 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000316e:	4585                	li	a1,1
    80003170:	8526                	mv	a0,s1
    80003172:	00003097          	auipc	ra,0x3
    80003176:	fd6080e7          	jalr	-42(ra) # 80006148 <virtio_disk_rw>
}
    8000317a:	60e2                	ld	ra,24(sp)
    8000317c:	6442                	ld	s0,16(sp)
    8000317e:	64a2                	ld	s1,8(sp)
    80003180:	6105                	addi	sp,sp,32
    80003182:	8082                	ret
    panic("bwrite");
    80003184:	00005517          	auipc	a0,0x5
    80003188:	58450513          	addi	a0,a0,1412 # 80008708 <syscalls+0x118>
    8000318c:	ffffd097          	auipc	ra,0xffffd
    80003190:	3b8080e7          	jalr	952(ra) # 80000544 <panic>

0000000080003194 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003194:	1101                	addi	sp,sp,-32
    80003196:	ec06                	sd	ra,24(sp)
    80003198:	e822                	sd	s0,16(sp)
    8000319a:	e426                	sd	s1,8(sp)
    8000319c:	e04a                	sd	s2,0(sp)
    8000319e:	1000                	addi	s0,sp,32
    800031a0:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031a2:	01050913          	addi	s2,a0,16
    800031a6:	854a                	mv	a0,s2
    800031a8:	00001097          	auipc	ra,0x1
    800031ac:	452080e7          	jalr	1106(ra) # 800045fa <holdingsleep>
    800031b0:	c92d                	beqz	a0,80003222 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800031b2:	854a                	mv	a0,s2
    800031b4:	00001097          	auipc	ra,0x1
    800031b8:	402080e7          	jalr	1026(ra) # 800045b6 <releasesleep>

  acquire(&bcache.lock);
    800031bc:	0001c517          	auipc	a0,0x1c
    800031c0:	e0450513          	addi	a0,a0,-508 # 8001efc0 <bcache>
    800031c4:	ffffe097          	auipc	ra,0xffffe
    800031c8:	a26080e7          	jalr	-1498(ra) # 80000bea <acquire>
  b->refcnt--;
    800031cc:	40bc                	lw	a5,64(s1)
    800031ce:	37fd                	addiw	a5,a5,-1
    800031d0:	0007871b          	sext.w	a4,a5
    800031d4:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800031d6:	eb05                	bnez	a4,80003206 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800031d8:	68bc                	ld	a5,80(s1)
    800031da:	64b8                	ld	a4,72(s1)
    800031dc:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800031de:	64bc                	ld	a5,72(s1)
    800031e0:	68b8                	ld	a4,80(s1)
    800031e2:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800031e4:	00024797          	auipc	a5,0x24
    800031e8:	ddc78793          	addi	a5,a5,-548 # 80026fc0 <bcache+0x8000>
    800031ec:	2b87b703          	ld	a4,696(a5)
    800031f0:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800031f2:	00024717          	auipc	a4,0x24
    800031f6:	03670713          	addi	a4,a4,54 # 80027228 <bcache+0x8268>
    800031fa:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800031fc:	2b87b703          	ld	a4,696(a5)
    80003200:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003202:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003206:	0001c517          	auipc	a0,0x1c
    8000320a:	dba50513          	addi	a0,a0,-582 # 8001efc0 <bcache>
    8000320e:	ffffe097          	auipc	ra,0xffffe
    80003212:	a90080e7          	jalr	-1392(ra) # 80000c9e <release>
}
    80003216:	60e2                	ld	ra,24(sp)
    80003218:	6442                	ld	s0,16(sp)
    8000321a:	64a2                	ld	s1,8(sp)
    8000321c:	6902                	ld	s2,0(sp)
    8000321e:	6105                	addi	sp,sp,32
    80003220:	8082                	ret
    panic("brelse");
    80003222:	00005517          	auipc	a0,0x5
    80003226:	4ee50513          	addi	a0,a0,1262 # 80008710 <syscalls+0x120>
    8000322a:	ffffd097          	auipc	ra,0xffffd
    8000322e:	31a080e7          	jalr	794(ra) # 80000544 <panic>

0000000080003232 <bpin>:

void
bpin(struct buf *b) {
    80003232:	1101                	addi	sp,sp,-32
    80003234:	ec06                	sd	ra,24(sp)
    80003236:	e822                	sd	s0,16(sp)
    80003238:	e426                	sd	s1,8(sp)
    8000323a:	1000                	addi	s0,sp,32
    8000323c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000323e:	0001c517          	auipc	a0,0x1c
    80003242:	d8250513          	addi	a0,a0,-638 # 8001efc0 <bcache>
    80003246:	ffffe097          	auipc	ra,0xffffe
    8000324a:	9a4080e7          	jalr	-1628(ra) # 80000bea <acquire>
  b->refcnt++;
    8000324e:	40bc                	lw	a5,64(s1)
    80003250:	2785                	addiw	a5,a5,1
    80003252:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003254:	0001c517          	auipc	a0,0x1c
    80003258:	d6c50513          	addi	a0,a0,-660 # 8001efc0 <bcache>
    8000325c:	ffffe097          	auipc	ra,0xffffe
    80003260:	a42080e7          	jalr	-1470(ra) # 80000c9e <release>
}
    80003264:	60e2                	ld	ra,24(sp)
    80003266:	6442                	ld	s0,16(sp)
    80003268:	64a2                	ld	s1,8(sp)
    8000326a:	6105                	addi	sp,sp,32
    8000326c:	8082                	ret

000000008000326e <bunpin>:

void
bunpin(struct buf *b) {
    8000326e:	1101                	addi	sp,sp,-32
    80003270:	ec06                	sd	ra,24(sp)
    80003272:	e822                	sd	s0,16(sp)
    80003274:	e426                	sd	s1,8(sp)
    80003276:	1000                	addi	s0,sp,32
    80003278:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000327a:	0001c517          	auipc	a0,0x1c
    8000327e:	d4650513          	addi	a0,a0,-698 # 8001efc0 <bcache>
    80003282:	ffffe097          	auipc	ra,0xffffe
    80003286:	968080e7          	jalr	-1688(ra) # 80000bea <acquire>
  b->refcnt--;
    8000328a:	40bc                	lw	a5,64(s1)
    8000328c:	37fd                	addiw	a5,a5,-1
    8000328e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003290:	0001c517          	auipc	a0,0x1c
    80003294:	d3050513          	addi	a0,a0,-720 # 8001efc0 <bcache>
    80003298:	ffffe097          	auipc	ra,0xffffe
    8000329c:	a06080e7          	jalr	-1530(ra) # 80000c9e <release>
}
    800032a0:	60e2                	ld	ra,24(sp)
    800032a2:	6442                	ld	s0,16(sp)
    800032a4:	64a2                	ld	s1,8(sp)
    800032a6:	6105                	addi	sp,sp,32
    800032a8:	8082                	ret

00000000800032aa <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800032aa:	1101                	addi	sp,sp,-32
    800032ac:	ec06                	sd	ra,24(sp)
    800032ae:	e822                	sd	s0,16(sp)
    800032b0:	e426                	sd	s1,8(sp)
    800032b2:	e04a                	sd	s2,0(sp)
    800032b4:	1000                	addi	s0,sp,32
    800032b6:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800032b8:	00d5d59b          	srliw	a1,a1,0xd
    800032bc:	00024797          	auipc	a5,0x24
    800032c0:	3e07a783          	lw	a5,992(a5) # 8002769c <sb+0x1c>
    800032c4:	9dbd                	addw	a1,a1,a5
    800032c6:	00000097          	auipc	ra,0x0
    800032ca:	d9e080e7          	jalr	-610(ra) # 80003064 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800032ce:	0074f713          	andi	a4,s1,7
    800032d2:	4785                	li	a5,1
    800032d4:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800032d8:	14ce                	slli	s1,s1,0x33
    800032da:	90d9                	srli	s1,s1,0x36
    800032dc:	00950733          	add	a4,a0,s1
    800032e0:	05874703          	lbu	a4,88(a4)
    800032e4:	00e7f6b3          	and	a3,a5,a4
    800032e8:	c69d                	beqz	a3,80003316 <bfree+0x6c>
    800032ea:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800032ec:	94aa                	add	s1,s1,a0
    800032ee:	fff7c793          	not	a5,a5
    800032f2:	8ff9                	and	a5,a5,a4
    800032f4:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800032f8:	00001097          	auipc	ra,0x1
    800032fc:	148080e7          	jalr	328(ra) # 80004440 <log_write>
  brelse(bp);
    80003300:	854a                	mv	a0,s2
    80003302:	00000097          	auipc	ra,0x0
    80003306:	e92080e7          	jalr	-366(ra) # 80003194 <brelse>
}
    8000330a:	60e2                	ld	ra,24(sp)
    8000330c:	6442                	ld	s0,16(sp)
    8000330e:	64a2                	ld	s1,8(sp)
    80003310:	6902                	ld	s2,0(sp)
    80003312:	6105                	addi	sp,sp,32
    80003314:	8082                	ret
    panic("freeing free block");
    80003316:	00005517          	auipc	a0,0x5
    8000331a:	40250513          	addi	a0,a0,1026 # 80008718 <syscalls+0x128>
    8000331e:	ffffd097          	auipc	ra,0xffffd
    80003322:	226080e7          	jalr	550(ra) # 80000544 <panic>

0000000080003326 <balloc>:
{
    80003326:	711d                	addi	sp,sp,-96
    80003328:	ec86                	sd	ra,88(sp)
    8000332a:	e8a2                	sd	s0,80(sp)
    8000332c:	e4a6                	sd	s1,72(sp)
    8000332e:	e0ca                	sd	s2,64(sp)
    80003330:	fc4e                	sd	s3,56(sp)
    80003332:	f852                	sd	s4,48(sp)
    80003334:	f456                	sd	s5,40(sp)
    80003336:	f05a                	sd	s6,32(sp)
    80003338:	ec5e                	sd	s7,24(sp)
    8000333a:	e862                	sd	s8,16(sp)
    8000333c:	e466                	sd	s9,8(sp)
    8000333e:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003340:	00024797          	auipc	a5,0x24
    80003344:	3447a783          	lw	a5,836(a5) # 80027684 <sb+0x4>
    80003348:	10078163          	beqz	a5,8000344a <balloc+0x124>
    8000334c:	8baa                	mv	s7,a0
    8000334e:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003350:	00024b17          	auipc	s6,0x24
    80003354:	330b0b13          	addi	s6,s6,816 # 80027680 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003358:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000335a:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000335c:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000335e:	6c89                	lui	s9,0x2
    80003360:	a061                	j	800033e8 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003362:	974a                	add	a4,a4,s2
    80003364:	8fd5                	or	a5,a5,a3
    80003366:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000336a:	854a                	mv	a0,s2
    8000336c:	00001097          	auipc	ra,0x1
    80003370:	0d4080e7          	jalr	212(ra) # 80004440 <log_write>
        brelse(bp);
    80003374:	854a                	mv	a0,s2
    80003376:	00000097          	auipc	ra,0x0
    8000337a:	e1e080e7          	jalr	-482(ra) # 80003194 <brelse>
  bp = bread(dev, bno);
    8000337e:	85a6                	mv	a1,s1
    80003380:	855e                	mv	a0,s7
    80003382:	00000097          	auipc	ra,0x0
    80003386:	ce2080e7          	jalr	-798(ra) # 80003064 <bread>
    8000338a:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000338c:	40000613          	li	a2,1024
    80003390:	4581                	li	a1,0
    80003392:	05850513          	addi	a0,a0,88
    80003396:	ffffe097          	auipc	ra,0xffffe
    8000339a:	950080e7          	jalr	-1712(ra) # 80000ce6 <memset>
  log_write(bp);
    8000339e:	854a                	mv	a0,s2
    800033a0:	00001097          	auipc	ra,0x1
    800033a4:	0a0080e7          	jalr	160(ra) # 80004440 <log_write>
  brelse(bp);
    800033a8:	854a                	mv	a0,s2
    800033aa:	00000097          	auipc	ra,0x0
    800033ae:	dea080e7          	jalr	-534(ra) # 80003194 <brelse>
}
    800033b2:	8526                	mv	a0,s1
    800033b4:	60e6                	ld	ra,88(sp)
    800033b6:	6446                	ld	s0,80(sp)
    800033b8:	64a6                	ld	s1,72(sp)
    800033ba:	6906                	ld	s2,64(sp)
    800033bc:	79e2                	ld	s3,56(sp)
    800033be:	7a42                	ld	s4,48(sp)
    800033c0:	7aa2                	ld	s5,40(sp)
    800033c2:	7b02                	ld	s6,32(sp)
    800033c4:	6be2                	ld	s7,24(sp)
    800033c6:	6c42                	ld	s8,16(sp)
    800033c8:	6ca2                	ld	s9,8(sp)
    800033ca:	6125                	addi	sp,sp,96
    800033cc:	8082                	ret
    brelse(bp);
    800033ce:	854a                	mv	a0,s2
    800033d0:	00000097          	auipc	ra,0x0
    800033d4:	dc4080e7          	jalr	-572(ra) # 80003194 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800033d8:	015c87bb          	addw	a5,s9,s5
    800033dc:	00078a9b          	sext.w	s5,a5
    800033e0:	004b2703          	lw	a4,4(s6)
    800033e4:	06eaf363          	bgeu	s5,a4,8000344a <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    800033e8:	41fad79b          	sraiw	a5,s5,0x1f
    800033ec:	0137d79b          	srliw	a5,a5,0x13
    800033f0:	015787bb          	addw	a5,a5,s5
    800033f4:	40d7d79b          	sraiw	a5,a5,0xd
    800033f8:	01cb2583          	lw	a1,28(s6)
    800033fc:	9dbd                	addw	a1,a1,a5
    800033fe:	855e                	mv	a0,s7
    80003400:	00000097          	auipc	ra,0x0
    80003404:	c64080e7          	jalr	-924(ra) # 80003064 <bread>
    80003408:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000340a:	004b2503          	lw	a0,4(s6)
    8000340e:	000a849b          	sext.w	s1,s5
    80003412:	8662                	mv	a2,s8
    80003414:	faa4fde3          	bgeu	s1,a0,800033ce <balloc+0xa8>
      m = 1 << (bi % 8);
    80003418:	41f6579b          	sraiw	a5,a2,0x1f
    8000341c:	01d7d69b          	srliw	a3,a5,0x1d
    80003420:	00c6873b          	addw	a4,a3,a2
    80003424:	00777793          	andi	a5,a4,7
    80003428:	9f95                	subw	a5,a5,a3
    8000342a:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000342e:	4037571b          	sraiw	a4,a4,0x3
    80003432:	00e906b3          	add	a3,s2,a4
    80003436:	0586c683          	lbu	a3,88(a3)
    8000343a:	00d7f5b3          	and	a1,a5,a3
    8000343e:	d195                	beqz	a1,80003362 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003440:	2605                	addiw	a2,a2,1
    80003442:	2485                	addiw	s1,s1,1
    80003444:	fd4618e3          	bne	a2,s4,80003414 <balloc+0xee>
    80003448:	b759                	j	800033ce <balloc+0xa8>
  printf("balloc: out of blocks\n");
    8000344a:	00005517          	auipc	a0,0x5
    8000344e:	2e650513          	addi	a0,a0,742 # 80008730 <syscalls+0x140>
    80003452:	ffffd097          	auipc	ra,0xffffd
    80003456:	13c080e7          	jalr	316(ra) # 8000058e <printf>
  return 0;
    8000345a:	4481                	li	s1,0
    8000345c:	bf99                	j	800033b2 <balloc+0x8c>

000000008000345e <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    8000345e:	7179                	addi	sp,sp,-48
    80003460:	f406                	sd	ra,40(sp)
    80003462:	f022                	sd	s0,32(sp)
    80003464:	ec26                	sd	s1,24(sp)
    80003466:	e84a                	sd	s2,16(sp)
    80003468:	e44e                	sd	s3,8(sp)
    8000346a:	e052                	sd	s4,0(sp)
    8000346c:	1800                	addi	s0,sp,48
    8000346e:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003470:	47ad                	li	a5,11
    80003472:	02b7e763          	bltu	a5,a1,800034a0 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    80003476:	02059493          	slli	s1,a1,0x20
    8000347a:	9081                	srli	s1,s1,0x20
    8000347c:	048a                	slli	s1,s1,0x2
    8000347e:	94aa                	add	s1,s1,a0
    80003480:	0504a903          	lw	s2,80(s1)
    80003484:	06091e63          	bnez	s2,80003500 <bmap+0xa2>
      addr = balloc(ip->dev);
    80003488:	4108                	lw	a0,0(a0)
    8000348a:	00000097          	auipc	ra,0x0
    8000348e:	e9c080e7          	jalr	-356(ra) # 80003326 <balloc>
    80003492:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003496:	06090563          	beqz	s2,80003500 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    8000349a:	0524a823          	sw	s2,80(s1)
    8000349e:	a08d                	j	80003500 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    800034a0:	ff45849b          	addiw	s1,a1,-12
    800034a4:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800034a8:	0ff00793          	li	a5,255
    800034ac:	08e7e563          	bltu	a5,a4,80003536 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800034b0:	08052903          	lw	s2,128(a0)
    800034b4:	00091d63          	bnez	s2,800034ce <bmap+0x70>
      addr = balloc(ip->dev);
    800034b8:	4108                	lw	a0,0(a0)
    800034ba:	00000097          	auipc	ra,0x0
    800034be:	e6c080e7          	jalr	-404(ra) # 80003326 <balloc>
    800034c2:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800034c6:	02090d63          	beqz	s2,80003500 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800034ca:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800034ce:	85ca                	mv	a1,s2
    800034d0:	0009a503          	lw	a0,0(s3)
    800034d4:	00000097          	auipc	ra,0x0
    800034d8:	b90080e7          	jalr	-1136(ra) # 80003064 <bread>
    800034dc:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800034de:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800034e2:	02049593          	slli	a1,s1,0x20
    800034e6:	9181                	srli	a1,a1,0x20
    800034e8:	058a                	slli	a1,a1,0x2
    800034ea:	00b784b3          	add	s1,a5,a1
    800034ee:	0004a903          	lw	s2,0(s1)
    800034f2:	02090063          	beqz	s2,80003512 <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800034f6:	8552                	mv	a0,s4
    800034f8:	00000097          	auipc	ra,0x0
    800034fc:	c9c080e7          	jalr	-868(ra) # 80003194 <brelse>
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
    8000351a:	e10080e7          	jalr	-496(ra) # 80003326 <balloc>
    8000351e:	0005091b          	sext.w	s2,a0
      if(addr){
    80003522:	fc090ae3          	beqz	s2,800034f6 <bmap+0x98>
        a[bn] = addr;
    80003526:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    8000352a:	8552                	mv	a0,s4
    8000352c:	00001097          	auipc	ra,0x1
    80003530:	f14080e7          	jalr	-236(ra) # 80004440 <log_write>
    80003534:	b7c9                	j	800034f6 <bmap+0x98>
  panic("bmap: out of range");
    80003536:	00005517          	auipc	a0,0x5
    8000353a:	21250513          	addi	a0,a0,530 # 80008748 <syscalls+0x158>
    8000353e:	ffffd097          	auipc	ra,0xffffd
    80003542:	006080e7          	jalr	6(ra) # 80000544 <panic>

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
    8000355e:	14650513          	addi	a0,a0,326 # 800276a0 <itable>
    80003562:	ffffd097          	auipc	ra,0xffffd
    80003566:	688080e7          	jalr	1672(ra) # 80000bea <acquire>
  empty = 0;
    8000356a:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000356c:	00024497          	auipc	s1,0x24
    80003570:	14c48493          	addi	s1,s1,332 # 800276b8 <itable+0x18>
    80003574:	00026697          	auipc	a3,0x26
    80003578:	bd468693          	addi	a3,a3,-1068 # 80029148 <log>
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
    800035a4:	10050513          	addi	a0,a0,256 # 800276a0 <itable>
    800035a8:	ffffd097          	auipc	ra,0xffffd
    800035ac:	6f6080e7          	jalr	1782(ra) # 80000c9e <release>
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
    800035d4:	0d050513          	addi	a0,a0,208 # 800276a0 <itable>
    800035d8:	ffffd097          	auipc	ra,0xffffd
    800035dc:	6c6080e7          	jalr	1734(ra) # 80000c9e <release>
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
    800035f6:	16e50513          	addi	a0,a0,366 # 80008760 <syscalls+0x170>
    800035fa:	ffffd097          	auipc	ra,0xffffd
    800035fe:	f4a080e7          	jalr	-182(ra) # 80000544 <panic>

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
    80003618:	a50080e7          	jalr	-1456(ra) # 80003064 <bread>
    8000361c:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000361e:	00024997          	auipc	s3,0x24
    80003622:	06298993          	addi	s3,s3,98 # 80027680 <sb>
    80003626:	02000613          	li	a2,32
    8000362a:	05850593          	addi	a1,a0,88
    8000362e:	854e                	mv	a0,s3
    80003630:	ffffd097          	auipc	ra,0xffffd
    80003634:	716080e7          	jalr	1814(ra) # 80000d46 <memmove>
  brelse(bp);
    80003638:	8526                	mv	a0,s1
    8000363a:	00000097          	auipc	ra,0x0
    8000363e:	b5a080e7          	jalr	-1190(ra) # 80003194 <brelse>
  if(sb.magic != FSMAGIC)
    80003642:	0009a703          	lw	a4,0(s3)
    80003646:	102037b7          	lui	a5,0x10203
    8000364a:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000364e:	02f71263          	bne	a4,a5,80003672 <fsinit+0x70>
  initlog(dev, &sb);
    80003652:	00024597          	auipc	a1,0x24
    80003656:	02e58593          	addi	a1,a1,46 # 80027680 <sb>
    8000365a:	854a                	mv	a0,s2
    8000365c:	00001097          	auipc	ra,0x1
    80003660:	b68080e7          	jalr	-1176(ra) # 800041c4 <initlog>
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
    80003676:	0fe50513          	addi	a0,a0,254 # 80008770 <syscalls+0x180>
    8000367a:	ffffd097          	auipc	ra,0xffffd
    8000367e:	eca080e7          	jalr	-310(ra) # 80000544 <panic>

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
    80003694:	0f858593          	addi	a1,a1,248 # 80008788 <syscalls+0x198>
    80003698:	00024517          	auipc	a0,0x24
    8000369c:	00850513          	addi	a0,a0,8 # 800276a0 <itable>
    800036a0:	ffffd097          	auipc	ra,0xffffd
    800036a4:	4ba080e7          	jalr	1210(ra) # 80000b5a <initlock>
  for(i = 0; i < NINODE; i++) {
    800036a8:	00024497          	auipc	s1,0x24
    800036ac:	02048493          	addi	s1,s1,32 # 800276c8 <itable+0x28>
    800036b0:	00026997          	auipc	s3,0x26
    800036b4:	aa898993          	addi	s3,s3,-1368 # 80029158 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800036b8:	00005917          	auipc	s2,0x5
    800036bc:	0d890913          	addi	s2,s2,216 # 80008790 <syscalls+0x1a0>
    800036c0:	85ca                	mv	a1,s2
    800036c2:	8526                	mv	a0,s1
    800036c4:	00001097          	auipc	ra,0x1
    800036c8:	e62080e7          	jalr	-414(ra) # 80004526 <initsleeplock>
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
    800036fc:	f9472703          	lw	a4,-108(a4) # 8002768c <sb+0xc>
    80003700:	4785                	li	a5,1
    80003702:	04e7fa63          	bgeu	a5,a4,80003756 <ialloc+0x74>
    80003706:	8aaa                	mv	s5,a0
    80003708:	8bae                	mv	s7,a1
    8000370a:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000370c:	00024a17          	auipc	s4,0x24
    80003710:	f74a0a13          	addi	s4,s4,-140 # 80027680 <sb>
    80003714:	00048b1b          	sext.w	s6,s1
    80003718:	0044d593          	srli	a1,s1,0x4
    8000371c:	018a2783          	lw	a5,24(s4)
    80003720:	9dbd                	addw	a1,a1,a5
    80003722:	8556                	mv	a0,s5
    80003724:	00000097          	auipc	ra,0x0
    80003728:	940080e7          	jalr	-1728(ra) # 80003064 <bread>
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
    80003744:	a54080e7          	jalr	-1452(ra) # 80003194 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003748:	0485                	addi	s1,s1,1
    8000374a:	00ca2703          	lw	a4,12(s4)
    8000374e:	0004879b          	sext.w	a5,s1
    80003752:	fce7e1e3          	bltu	a5,a4,80003714 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003756:	00005517          	auipc	a0,0x5
    8000375a:	04250513          	addi	a0,a0,66 # 80008798 <syscalls+0x1a8>
    8000375e:	ffffd097          	auipc	ra,0xffffd
    80003762:	e30080e7          	jalr	-464(ra) # 8000058e <printf>
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
    8000378a:	560080e7          	jalr	1376(ra) # 80000ce6 <memset>
      dip->type = type;
    8000378e:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003792:	854a                	mv	a0,s2
    80003794:	00001097          	auipc	ra,0x1
    80003798:	cac080e7          	jalr	-852(ra) # 80004440 <log_write>
      brelse(bp);
    8000379c:	854a                	mv	a0,s2
    8000379e:	00000097          	auipc	ra,0x0
    800037a2:	9f6080e7          	jalr	-1546(ra) # 80003194 <brelse>
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
    800037cc:	ed05a583          	lw	a1,-304(a1) # 80027698 <sb+0x18>
    800037d0:	9dbd                	addw	a1,a1,a5
    800037d2:	4108                	lw	a0,0(a0)
    800037d4:	00000097          	auipc	ra,0x0
    800037d8:	890080e7          	jalr	-1904(ra) # 80003064 <bread>
    800037dc:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037de:	05850793          	addi	a5,a0,88
    800037e2:	40c8                	lw	a0,4(s1)
    800037e4:	893d                	andi	a0,a0,15
    800037e6:	051a                	slli	a0,a0,0x6
    800037e8:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800037ea:	04449703          	lh	a4,68(s1)
    800037ee:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800037f2:	04649703          	lh	a4,70(s1)
    800037f6:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800037fa:	04849703          	lh	a4,72(s1)
    800037fe:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003802:	04a49703          	lh	a4,74(s1)
    80003806:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000380a:	44f8                	lw	a4,76(s1)
    8000380c:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000380e:	03400613          	li	a2,52
    80003812:	05048593          	addi	a1,s1,80
    80003816:	0531                	addi	a0,a0,12
    80003818:	ffffd097          	auipc	ra,0xffffd
    8000381c:	52e080e7          	jalr	1326(ra) # 80000d46 <memmove>
  log_write(bp);
    80003820:	854a                	mv	a0,s2
    80003822:	00001097          	auipc	ra,0x1
    80003826:	c1e080e7          	jalr	-994(ra) # 80004440 <log_write>
  brelse(bp);
    8000382a:	854a                	mv	a0,s2
    8000382c:	00000097          	auipc	ra,0x0
    80003830:	968080e7          	jalr	-1688(ra) # 80003194 <brelse>
}
    80003834:	60e2                	ld	ra,24(sp)
    80003836:	6442                	ld	s0,16(sp)
    80003838:	64a2                	ld	s1,8(sp)
    8000383a:	6902                	ld	s2,0(sp)
    8000383c:	6105                	addi	sp,sp,32
    8000383e:	8082                	ret

0000000080003840 <idup>:
{
    80003840:	1101                	addi	sp,sp,-32
    80003842:	ec06                	sd	ra,24(sp)
    80003844:	e822                	sd	s0,16(sp)
    80003846:	e426                	sd	s1,8(sp)
    80003848:	1000                	addi	s0,sp,32
    8000384a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000384c:	00024517          	auipc	a0,0x24
    80003850:	e5450513          	addi	a0,a0,-428 # 800276a0 <itable>
    80003854:	ffffd097          	auipc	ra,0xffffd
    80003858:	396080e7          	jalr	918(ra) # 80000bea <acquire>
  ip->ref++;
    8000385c:	449c                	lw	a5,8(s1)
    8000385e:	2785                	addiw	a5,a5,1
    80003860:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003862:	00024517          	auipc	a0,0x24
    80003866:	e3e50513          	addi	a0,a0,-450 # 800276a0 <itable>
    8000386a:	ffffd097          	auipc	ra,0xffffd
    8000386e:	434080e7          	jalr	1076(ra) # 80000c9e <release>
}
    80003872:	8526                	mv	a0,s1
    80003874:	60e2                	ld	ra,24(sp)
    80003876:	6442                	ld	s0,16(sp)
    80003878:	64a2                	ld	s1,8(sp)
    8000387a:	6105                	addi	sp,sp,32
    8000387c:	8082                	ret

000000008000387e <ilock>:
{
    8000387e:	1101                	addi	sp,sp,-32
    80003880:	ec06                	sd	ra,24(sp)
    80003882:	e822                	sd	s0,16(sp)
    80003884:	e426                	sd	s1,8(sp)
    80003886:	e04a                	sd	s2,0(sp)
    80003888:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000388a:	c115                	beqz	a0,800038ae <ilock+0x30>
    8000388c:	84aa                	mv	s1,a0
    8000388e:	451c                	lw	a5,8(a0)
    80003890:	00f05f63          	blez	a5,800038ae <ilock+0x30>
  acquiresleep(&ip->lock);
    80003894:	0541                	addi	a0,a0,16
    80003896:	00001097          	auipc	ra,0x1
    8000389a:	cca080e7          	jalr	-822(ra) # 80004560 <acquiresleep>
  if(ip->valid == 0){
    8000389e:	40bc                	lw	a5,64(s1)
    800038a0:	cf99                	beqz	a5,800038be <ilock+0x40>
}
    800038a2:	60e2                	ld	ra,24(sp)
    800038a4:	6442                	ld	s0,16(sp)
    800038a6:	64a2                	ld	s1,8(sp)
    800038a8:	6902                	ld	s2,0(sp)
    800038aa:	6105                	addi	sp,sp,32
    800038ac:	8082                	ret
    panic("ilock");
    800038ae:	00005517          	auipc	a0,0x5
    800038b2:	f0250513          	addi	a0,a0,-254 # 800087b0 <syscalls+0x1c0>
    800038b6:	ffffd097          	auipc	ra,0xffffd
    800038ba:	c8e080e7          	jalr	-882(ra) # 80000544 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038be:	40dc                	lw	a5,4(s1)
    800038c0:	0047d79b          	srliw	a5,a5,0x4
    800038c4:	00024597          	auipc	a1,0x24
    800038c8:	dd45a583          	lw	a1,-556(a1) # 80027698 <sb+0x18>
    800038cc:	9dbd                	addw	a1,a1,a5
    800038ce:	4088                	lw	a0,0(s1)
    800038d0:	fffff097          	auipc	ra,0xfffff
    800038d4:	794080e7          	jalr	1940(ra) # 80003064 <bread>
    800038d8:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800038da:	05850593          	addi	a1,a0,88
    800038de:	40dc                	lw	a5,4(s1)
    800038e0:	8bbd                	andi	a5,a5,15
    800038e2:	079a                	slli	a5,a5,0x6
    800038e4:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800038e6:	00059783          	lh	a5,0(a1)
    800038ea:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800038ee:	00259783          	lh	a5,2(a1)
    800038f2:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800038f6:	00459783          	lh	a5,4(a1)
    800038fa:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800038fe:	00659783          	lh	a5,6(a1)
    80003902:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003906:	459c                	lw	a5,8(a1)
    80003908:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000390a:	03400613          	li	a2,52
    8000390e:	05b1                	addi	a1,a1,12
    80003910:	05048513          	addi	a0,s1,80
    80003914:	ffffd097          	auipc	ra,0xffffd
    80003918:	432080e7          	jalr	1074(ra) # 80000d46 <memmove>
    brelse(bp);
    8000391c:	854a                	mv	a0,s2
    8000391e:	00000097          	auipc	ra,0x0
    80003922:	876080e7          	jalr	-1930(ra) # 80003194 <brelse>
    ip->valid = 1;
    80003926:	4785                	li	a5,1
    80003928:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000392a:	04449783          	lh	a5,68(s1)
    8000392e:	fbb5                	bnez	a5,800038a2 <ilock+0x24>
      panic("ilock: no type");
    80003930:	00005517          	auipc	a0,0x5
    80003934:	e8850513          	addi	a0,a0,-376 # 800087b8 <syscalls+0x1c8>
    80003938:	ffffd097          	auipc	ra,0xffffd
    8000393c:	c0c080e7          	jalr	-1012(ra) # 80000544 <panic>

0000000080003940 <iunlock>:
{
    80003940:	1101                	addi	sp,sp,-32
    80003942:	ec06                	sd	ra,24(sp)
    80003944:	e822                	sd	s0,16(sp)
    80003946:	e426                	sd	s1,8(sp)
    80003948:	e04a                	sd	s2,0(sp)
    8000394a:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000394c:	c905                	beqz	a0,8000397c <iunlock+0x3c>
    8000394e:	84aa                	mv	s1,a0
    80003950:	01050913          	addi	s2,a0,16
    80003954:	854a                	mv	a0,s2
    80003956:	00001097          	auipc	ra,0x1
    8000395a:	ca4080e7          	jalr	-860(ra) # 800045fa <holdingsleep>
    8000395e:	cd19                	beqz	a0,8000397c <iunlock+0x3c>
    80003960:	449c                	lw	a5,8(s1)
    80003962:	00f05d63          	blez	a5,8000397c <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003966:	854a                	mv	a0,s2
    80003968:	00001097          	auipc	ra,0x1
    8000396c:	c4e080e7          	jalr	-946(ra) # 800045b6 <releasesleep>
}
    80003970:	60e2                	ld	ra,24(sp)
    80003972:	6442                	ld	s0,16(sp)
    80003974:	64a2                	ld	s1,8(sp)
    80003976:	6902                	ld	s2,0(sp)
    80003978:	6105                	addi	sp,sp,32
    8000397a:	8082                	ret
    panic("iunlock");
    8000397c:	00005517          	auipc	a0,0x5
    80003980:	e4c50513          	addi	a0,a0,-436 # 800087c8 <syscalls+0x1d8>
    80003984:	ffffd097          	auipc	ra,0xffffd
    80003988:	bc0080e7          	jalr	-1088(ra) # 80000544 <panic>

000000008000398c <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000398c:	7179                	addi	sp,sp,-48
    8000398e:	f406                	sd	ra,40(sp)
    80003990:	f022                	sd	s0,32(sp)
    80003992:	ec26                	sd	s1,24(sp)
    80003994:	e84a                	sd	s2,16(sp)
    80003996:	e44e                	sd	s3,8(sp)
    80003998:	e052                	sd	s4,0(sp)
    8000399a:	1800                	addi	s0,sp,48
    8000399c:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000399e:	05050493          	addi	s1,a0,80
    800039a2:	08050913          	addi	s2,a0,128
    800039a6:	a021                	j	800039ae <itrunc+0x22>
    800039a8:	0491                	addi	s1,s1,4
    800039aa:	01248d63          	beq	s1,s2,800039c4 <itrunc+0x38>
    if(ip->addrs[i]){
    800039ae:	408c                	lw	a1,0(s1)
    800039b0:	dde5                	beqz	a1,800039a8 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800039b2:	0009a503          	lw	a0,0(s3)
    800039b6:	00000097          	auipc	ra,0x0
    800039ba:	8f4080e7          	jalr	-1804(ra) # 800032aa <bfree>
      ip->addrs[i] = 0;
    800039be:	0004a023          	sw	zero,0(s1)
    800039c2:	b7dd                	j	800039a8 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800039c4:	0809a583          	lw	a1,128(s3)
    800039c8:	e185                	bnez	a1,800039e8 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800039ca:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800039ce:	854e                	mv	a0,s3
    800039d0:	00000097          	auipc	ra,0x0
    800039d4:	de4080e7          	jalr	-540(ra) # 800037b4 <iupdate>
}
    800039d8:	70a2                	ld	ra,40(sp)
    800039da:	7402                	ld	s0,32(sp)
    800039dc:	64e2                	ld	s1,24(sp)
    800039de:	6942                	ld	s2,16(sp)
    800039e0:	69a2                	ld	s3,8(sp)
    800039e2:	6a02                	ld	s4,0(sp)
    800039e4:	6145                	addi	sp,sp,48
    800039e6:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800039e8:	0009a503          	lw	a0,0(s3)
    800039ec:	fffff097          	auipc	ra,0xfffff
    800039f0:	678080e7          	jalr	1656(ra) # 80003064 <bread>
    800039f4:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800039f6:	05850493          	addi	s1,a0,88
    800039fa:	45850913          	addi	s2,a0,1112
    800039fe:	a811                	j	80003a12 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003a00:	0009a503          	lw	a0,0(s3)
    80003a04:	00000097          	auipc	ra,0x0
    80003a08:	8a6080e7          	jalr	-1882(ra) # 800032aa <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003a0c:	0491                	addi	s1,s1,4
    80003a0e:	01248563          	beq	s1,s2,80003a18 <itrunc+0x8c>
      if(a[j])
    80003a12:	408c                	lw	a1,0(s1)
    80003a14:	dde5                	beqz	a1,80003a0c <itrunc+0x80>
    80003a16:	b7ed                	j	80003a00 <itrunc+0x74>
    brelse(bp);
    80003a18:	8552                	mv	a0,s4
    80003a1a:	fffff097          	auipc	ra,0xfffff
    80003a1e:	77a080e7          	jalr	1914(ra) # 80003194 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003a22:	0809a583          	lw	a1,128(s3)
    80003a26:	0009a503          	lw	a0,0(s3)
    80003a2a:	00000097          	auipc	ra,0x0
    80003a2e:	880080e7          	jalr	-1920(ra) # 800032aa <bfree>
    ip->addrs[NDIRECT] = 0;
    80003a32:	0809a023          	sw	zero,128(s3)
    80003a36:	bf51                	j	800039ca <itrunc+0x3e>

0000000080003a38 <iput>:
{
    80003a38:	1101                	addi	sp,sp,-32
    80003a3a:	ec06                	sd	ra,24(sp)
    80003a3c:	e822                	sd	s0,16(sp)
    80003a3e:	e426                	sd	s1,8(sp)
    80003a40:	e04a                	sd	s2,0(sp)
    80003a42:	1000                	addi	s0,sp,32
    80003a44:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a46:	00024517          	auipc	a0,0x24
    80003a4a:	c5a50513          	addi	a0,a0,-934 # 800276a0 <itable>
    80003a4e:	ffffd097          	auipc	ra,0xffffd
    80003a52:	19c080e7          	jalr	412(ra) # 80000bea <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a56:	4498                	lw	a4,8(s1)
    80003a58:	4785                	li	a5,1
    80003a5a:	02f70363          	beq	a4,a5,80003a80 <iput+0x48>
  ip->ref--;
    80003a5e:	449c                	lw	a5,8(s1)
    80003a60:	37fd                	addiw	a5,a5,-1
    80003a62:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003a64:	00024517          	auipc	a0,0x24
    80003a68:	c3c50513          	addi	a0,a0,-964 # 800276a0 <itable>
    80003a6c:	ffffd097          	auipc	ra,0xffffd
    80003a70:	232080e7          	jalr	562(ra) # 80000c9e <release>
}
    80003a74:	60e2                	ld	ra,24(sp)
    80003a76:	6442                	ld	s0,16(sp)
    80003a78:	64a2                	ld	s1,8(sp)
    80003a7a:	6902                	ld	s2,0(sp)
    80003a7c:	6105                	addi	sp,sp,32
    80003a7e:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a80:	40bc                	lw	a5,64(s1)
    80003a82:	dff1                	beqz	a5,80003a5e <iput+0x26>
    80003a84:	04a49783          	lh	a5,74(s1)
    80003a88:	fbf9                	bnez	a5,80003a5e <iput+0x26>
    acquiresleep(&ip->lock);
    80003a8a:	01048913          	addi	s2,s1,16
    80003a8e:	854a                	mv	a0,s2
    80003a90:	00001097          	auipc	ra,0x1
    80003a94:	ad0080e7          	jalr	-1328(ra) # 80004560 <acquiresleep>
    release(&itable.lock);
    80003a98:	00024517          	auipc	a0,0x24
    80003a9c:	c0850513          	addi	a0,a0,-1016 # 800276a0 <itable>
    80003aa0:	ffffd097          	auipc	ra,0xffffd
    80003aa4:	1fe080e7          	jalr	510(ra) # 80000c9e <release>
    itrunc(ip);
    80003aa8:	8526                	mv	a0,s1
    80003aaa:	00000097          	auipc	ra,0x0
    80003aae:	ee2080e7          	jalr	-286(ra) # 8000398c <itrunc>
    ip->type = 0;
    80003ab2:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003ab6:	8526                	mv	a0,s1
    80003ab8:	00000097          	auipc	ra,0x0
    80003abc:	cfc080e7          	jalr	-772(ra) # 800037b4 <iupdate>
    ip->valid = 0;
    80003ac0:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003ac4:	854a                	mv	a0,s2
    80003ac6:	00001097          	auipc	ra,0x1
    80003aca:	af0080e7          	jalr	-1296(ra) # 800045b6 <releasesleep>
    acquire(&itable.lock);
    80003ace:	00024517          	auipc	a0,0x24
    80003ad2:	bd250513          	addi	a0,a0,-1070 # 800276a0 <itable>
    80003ad6:	ffffd097          	auipc	ra,0xffffd
    80003ada:	114080e7          	jalr	276(ra) # 80000bea <acquire>
    80003ade:	b741                	j	80003a5e <iput+0x26>

0000000080003ae0 <iunlockput>:
{
    80003ae0:	1101                	addi	sp,sp,-32
    80003ae2:	ec06                	sd	ra,24(sp)
    80003ae4:	e822                	sd	s0,16(sp)
    80003ae6:	e426                	sd	s1,8(sp)
    80003ae8:	1000                	addi	s0,sp,32
    80003aea:	84aa                	mv	s1,a0
  iunlock(ip);
    80003aec:	00000097          	auipc	ra,0x0
    80003af0:	e54080e7          	jalr	-428(ra) # 80003940 <iunlock>
  iput(ip);
    80003af4:	8526                	mv	a0,s1
    80003af6:	00000097          	auipc	ra,0x0
    80003afa:	f42080e7          	jalr	-190(ra) # 80003a38 <iput>
}
    80003afe:	60e2                	ld	ra,24(sp)
    80003b00:	6442                	ld	s0,16(sp)
    80003b02:	64a2                	ld	s1,8(sp)
    80003b04:	6105                	addi	sp,sp,32
    80003b06:	8082                	ret

0000000080003b08 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003b08:	1141                	addi	sp,sp,-16
    80003b0a:	e422                	sd	s0,8(sp)
    80003b0c:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003b0e:	411c                	lw	a5,0(a0)
    80003b10:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003b12:	415c                	lw	a5,4(a0)
    80003b14:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003b16:	04451783          	lh	a5,68(a0)
    80003b1a:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003b1e:	04a51783          	lh	a5,74(a0)
    80003b22:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003b26:	04c56783          	lwu	a5,76(a0)
    80003b2a:	e99c                	sd	a5,16(a1)
}
    80003b2c:	6422                	ld	s0,8(sp)
    80003b2e:	0141                	addi	sp,sp,16
    80003b30:	8082                	ret

0000000080003b32 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b32:	457c                	lw	a5,76(a0)
    80003b34:	0ed7e963          	bltu	a5,a3,80003c26 <readi+0xf4>
{
    80003b38:	7159                	addi	sp,sp,-112
    80003b3a:	f486                	sd	ra,104(sp)
    80003b3c:	f0a2                	sd	s0,96(sp)
    80003b3e:	eca6                	sd	s1,88(sp)
    80003b40:	e8ca                	sd	s2,80(sp)
    80003b42:	e4ce                	sd	s3,72(sp)
    80003b44:	e0d2                	sd	s4,64(sp)
    80003b46:	fc56                	sd	s5,56(sp)
    80003b48:	f85a                	sd	s6,48(sp)
    80003b4a:	f45e                	sd	s7,40(sp)
    80003b4c:	f062                	sd	s8,32(sp)
    80003b4e:	ec66                	sd	s9,24(sp)
    80003b50:	e86a                	sd	s10,16(sp)
    80003b52:	e46e                	sd	s11,8(sp)
    80003b54:	1880                	addi	s0,sp,112
    80003b56:	8b2a                	mv	s6,a0
    80003b58:	8bae                	mv	s7,a1
    80003b5a:	8a32                	mv	s4,a2
    80003b5c:	84b6                	mv	s1,a3
    80003b5e:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003b60:	9f35                	addw	a4,a4,a3
    return 0;
    80003b62:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003b64:	0ad76063          	bltu	a4,a3,80003c04 <readi+0xd2>
  if(off + n > ip->size)
    80003b68:	00e7f463          	bgeu	a5,a4,80003b70 <readi+0x3e>
    n = ip->size - off;
    80003b6c:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b70:	0a0a8963          	beqz	s5,80003c22 <readi+0xf0>
    80003b74:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b76:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003b7a:	5c7d                	li	s8,-1
    80003b7c:	a82d                	j	80003bb6 <readi+0x84>
    80003b7e:	020d1d93          	slli	s11,s10,0x20
    80003b82:	020ddd93          	srli	s11,s11,0x20
    80003b86:	05890613          	addi	a2,s2,88
    80003b8a:	86ee                	mv	a3,s11
    80003b8c:	963a                	add	a2,a2,a4
    80003b8e:	85d2                	mv	a1,s4
    80003b90:	855e                	mv	a0,s7
    80003b92:	fffff097          	auipc	ra,0xfffff
    80003b96:	980080e7          	jalr	-1664(ra) # 80002512 <either_copyout>
    80003b9a:	05850d63          	beq	a0,s8,80003bf4 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003b9e:	854a                	mv	a0,s2
    80003ba0:	fffff097          	auipc	ra,0xfffff
    80003ba4:	5f4080e7          	jalr	1524(ra) # 80003194 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ba8:	013d09bb          	addw	s3,s10,s3
    80003bac:	009d04bb          	addw	s1,s10,s1
    80003bb0:	9a6e                	add	s4,s4,s11
    80003bb2:	0559f763          	bgeu	s3,s5,80003c00 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003bb6:	00a4d59b          	srliw	a1,s1,0xa
    80003bba:	855a                	mv	a0,s6
    80003bbc:	00000097          	auipc	ra,0x0
    80003bc0:	8a2080e7          	jalr	-1886(ra) # 8000345e <bmap>
    80003bc4:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003bc8:	cd85                	beqz	a1,80003c00 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003bca:	000b2503          	lw	a0,0(s6)
    80003bce:	fffff097          	auipc	ra,0xfffff
    80003bd2:	496080e7          	jalr	1174(ra) # 80003064 <bread>
    80003bd6:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bd8:	3ff4f713          	andi	a4,s1,1023
    80003bdc:	40ec87bb          	subw	a5,s9,a4
    80003be0:	413a86bb          	subw	a3,s5,s3
    80003be4:	8d3e                	mv	s10,a5
    80003be6:	2781                	sext.w	a5,a5
    80003be8:	0006861b          	sext.w	a2,a3
    80003bec:	f8f679e3          	bgeu	a2,a5,80003b7e <readi+0x4c>
    80003bf0:	8d36                	mv	s10,a3
    80003bf2:	b771                	j	80003b7e <readi+0x4c>
      brelse(bp);
    80003bf4:	854a                	mv	a0,s2
    80003bf6:	fffff097          	auipc	ra,0xfffff
    80003bfa:	59e080e7          	jalr	1438(ra) # 80003194 <brelse>
      tot = -1;
    80003bfe:	59fd                	li	s3,-1
  }
  return tot;
    80003c00:	0009851b          	sext.w	a0,s3
}
    80003c04:	70a6                	ld	ra,104(sp)
    80003c06:	7406                	ld	s0,96(sp)
    80003c08:	64e6                	ld	s1,88(sp)
    80003c0a:	6946                	ld	s2,80(sp)
    80003c0c:	69a6                	ld	s3,72(sp)
    80003c0e:	6a06                	ld	s4,64(sp)
    80003c10:	7ae2                	ld	s5,56(sp)
    80003c12:	7b42                	ld	s6,48(sp)
    80003c14:	7ba2                	ld	s7,40(sp)
    80003c16:	7c02                	ld	s8,32(sp)
    80003c18:	6ce2                	ld	s9,24(sp)
    80003c1a:	6d42                	ld	s10,16(sp)
    80003c1c:	6da2                	ld	s11,8(sp)
    80003c1e:	6165                	addi	sp,sp,112
    80003c20:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c22:	89d6                	mv	s3,s5
    80003c24:	bff1                	j	80003c00 <readi+0xce>
    return 0;
    80003c26:	4501                	li	a0,0
}
    80003c28:	8082                	ret

0000000080003c2a <writei>:
// Returns the number of bytes successfully written.
// If the return value is less than the requested n,
// there was an error of some kind.
int
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
    80003c2a:	7119                	addi	sp,sp,-128
    80003c2c:	fc86                	sd	ra,120(sp)
    80003c2e:	f8a2                	sd	s0,112(sp)
    80003c30:	f4a6                	sd	s1,104(sp)
    80003c32:	f0ca                	sd	s2,96(sp)
    80003c34:	ecce                	sd	s3,88(sp)
    80003c36:	e8d2                	sd	s4,80(sp)
    80003c38:	e4d6                	sd	s5,72(sp)
    80003c3a:	e0da                	sd	s6,64(sp)
    80003c3c:	fc5e                	sd	s7,56(sp)
    80003c3e:	f862                	sd	s8,48(sp)
    80003c40:	f466                	sd	s9,40(sp)
    80003c42:	f06a                	sd	s10,32(sp)
    80003c44:	ec6e                	sd	s11,24(sp)
    80003c46:	0100                	addi	s0,sp,128
    80003c48:	f8b43423          	sd	a1,-120(s0)
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off){
    80003c4c:	457c                	lw	a5,76(a0)
    80003c4e:	10d7eb63          	bltu	a5,a3,80003d64 <writei+0x13a>
    80003c52:	8c2a                	mv	s8,a0
    80003c54:	8ab2                	mv	s5,a2
    80003c56:	89b6                	mv	s3,a3
    80003c58:	8cba                	mv	s9,a4
    80003c5a:	00e687bb          	addw	a5,a3,a4
    80003c5e:	10d7e563          	bltu	a5,a3,80003d68 <writei+0x13e>
    return -1;
  }
  if(off + n > MAXFILE*BSIZE){
    80003c62:	00043737          	lui	a4,0x43
    80003c66:	10f76363          	bltu	a4,a5,80003d6c <writei+0x142>
    return -1;
  }

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c6a:	0e0c8b63          	beqz	s9,80003d60 <writei+0x136>
    80003c6e:	4a01                	li	s4,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0){
      break;
    }
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c70:	40000d93          	li	s11,1024
    printf("m: %d\n",m);
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003c74:	5d7d                	li	s10,-1
    80003c76:	a8a9                	j	80003cd0 <writei+0xa6>
    printf("m: %d\n",m);
    80003c78:	0009059b          	sext.w	a1,s2
    80003c7c:	00005517          	auipc	a0,0x5
    80003c80:	b5450513          	addi	a0,a0,-1196 # 800087d0 <syscalls+0x1e0>
    80003c84:	ffffd097          	auipc	ra,0xffffd
    80003c88:	90a080e7          	jalr	-1782(ra) # 8000058e <printf>
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003c8c:	02091b93          	slli	s7,s2,0x20
    80003c90:	020bdb93          	srli	s7,s7,0x20
    80003c94:	05848513          	addi	a0,s1,88
    80003c98:	86de                	mv	a3,s7
    80003c9a:	8656                	mv	a2,s5
    80003c9c:	f8843583          	ld	a1,-120(s0)
    80003ca0:	955a                	add	a0,a0,s6
    80003ca2:	fffff097          	auipc	ra,0xfffff
    80003ca6:	8c6080e7          	jalr	-1850(ra) # 80002568 <either_copyin>
    80003caa:	07a50263          	beq	a0,s10,80003d0e <writei+0xe4>
      brelse(bp);
      printf("I am going to cry\n");
      break;
    }
    log_write(bp);
    80003cae:	8526                	mv	a0,s1
    80003cb0:	00000097          	auipc	ra,0x0
    80003cb4:	790080e7          	jalr	1936(ra) # 80004440 <log_write>
    brelse(bp);
    80003cb8:	8526                	mv	a0,s1
    80003cba:	fffff097          	auipc	ra,0xfffff
    80003cbe:	4da080e7          	jalr	1242(ra) # 80003194 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cc2:	01490a3b          	addw	s4,s2,s4
    80003cc6:	013909bb          	addw	s3,s2,s3
    80003cca:	9ade                	add	s5,s5,s7
    80003ccc:	059a7e63          	bgeu	s4,s9,80003d28 <writei+0xfe>
    uint addr = bmap(ip, off/BSIZE);
    80003cd0:	00a9d59b          	srliw	a1,s3,0xa
    80003cd4:	8562                	mv	a0,s8
    80003cd6:	fffff097          	auipc	ra,0xfffff
    80003cda:	788080e7          	jalr	1928(ra) # 8000345e <bmap>
    80003cde:	0005059b          	sext.w	a1,a0
    if(addr == 0){
    80003ce2:	c1b9                	beqz	a1,80003d28 <writei+0xfe>
    bp = bread(ip->dev, addr);
    80003ce4:	000c2503          	lw	a0,0(s8)
    80003ce8:	fffff097          	auipc	ra,0xfffff
    80003cec:	37c080e7          	jalr	892(ra) # 80003064 <bread>
    80003cf0:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cf2:	3ff9fb13          	andi	s6,s3,1023
    80003cf6:	416d87bb          	subw	a5,s11,s6
    80003cfa:	414c873b          	subw	a4,s9,s4
    80003cfe:	893e                	mv	s2,a5
    80003d00:	2781                	sext.w	a5,a5
    80003d02:	0007069b          	sext.w	a3,a4
    80003d06:	f6f6f9e3          	bgeu	a3,a5,80003c78 <writei+0x4e>
    80003d0a:	893a                	mv	s2,a4
    80003d0c:	b7b5                	j	80003c78 <writei+0x4e>
      brelse(bp);
    80003d0e:	8526                	mv	a0,s1
    80003d10:	fffff097          	auipc	ra,0xfffff
    80003d14:	484080e7          	jalr	1156(ra) # 80003194 <brelse>
      printf("I am going to cry\n");
    80003d18:	00005517          	auipc	a0,0x5
    80003d1c:	ac050513          	addi	a0,a0,-1344 # 800087d8 <syscalls+0x1e8>
    80003d20:	ffffd097          	auipc	ra,0xffffd
    80003d24:	86e080e7          	jalr	-1938(ra) # 8000058e <printf>
  }

  if(off > ip->size)
    80003d28:	04cc2783          	lw	a5,76(s8)
    80003d2c:	0137f463          	bgeu	a5,s3,80003d34 <writei+0x10a>
    ip->size = off;
    80003d30:	053c2623          	sw	s3,76(s8)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003d34:	8562                	mv	a0,s8
    80003d36:	00000097          	auipc	ra,0x0
    80003d3a:	a7e080e7          	jalr	-1410(ra) # 800037b4 <iupdate>

  return tot;
    80003d3e:	000a051b          	sext.w	a0,s4
}
    80003d42:	70e6                	ld	ra,120(sp)
    80003d44:	7446                	ld	s0,112(sp)
    80003d46:	74a6                	ld	s1,104(sp)
    80003d48:	7906                	ld	s2,96(sp)
    80003d4a:	69e6                	ld	s3,88(sp)
    80003d4c:	6a46                	ld	s4,80(sp)
    80003d4e:	6aa6                	ld	s5,72(sp)
    80003d50:	6b06                	ld	s6,64(sp)
    80003d52:	7be2                	ld	s7,56(sp)
    80003d54:	7c42                	ld	s8,48(sp)
    80003d56:	7ca2                	ld	s9,40(sp)
    80003d58:	7d02                	ld	s10,32(sp)
    80003d5a:	6de2                	ld	s11,24(sp)
    80003d5c:	6109                	addi	sp,sp,128
    80003d5e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d60:	8a66                	mv	s4,s9
    80003d62:	bfc9                	j	80003d34 <writei+0x10a>
    return -1;
    80003d64:	557d                	li	a0,-1
    80003d66:	bff1                	j	80003d42 <writei+0x118>
    80003d68:	557d                	li	a0,-1
    80003d6a:	bfe1                	j	80003d42 <writei+0x118>
    return -1;
    80003d6c:	557d                	li	a0,-1
    80003d6e:	bfd1                	j	80003d42 <writei+0x118>

0000000080003d70 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003d70:	1141                	addi	sp,sp,-16
    80003d72:	e406                	sd	ra,8(sp)
    80003d74:	e022                	sd	s0,0(sp)
    80003d76:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003d78:	4639                	li	a2,14
    80003d7a:	ffffd097          	auipc	ra,0xffffd
    80003d7e:	044080e7          	jalr	68(ra) # 80000dbe <strncmp>
}
    80003d82:	60a2                	ld	ra,8(sp)
    80003d84:	6402                	ld	s0,0(sp)
    80003d86:	0141                	addi	sp,sp,16
    80003d88:	8082                	ret

0000000080003d8a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003d8a:	7139                	addi	sp,sp,-64
    80003d8c:	fc06                	sd	ra,56(sp)
    80003d8e:	f822                	sd	s0,48(sp)
    80003d90:	f426                	sd	s1,40(sp)
    80003d92:	f04a                	sd	s2,32(sp)
    80003d94:	ec4e                	sd	s3,24(sp)
    80003d96:	e852                	sd	s4,16(sp)
    80003d98:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003d9a:	04451703          	lh	a4,68(a0)
    80003d9e:	4785                	li	a5,1
    80003da0:	00f71a63          	bne	a4,a5,80003db4 <dirlookup+0x2a>
    80003da4:	892a                	mv	s2,a0
    80003da6:	89ae                	mv	s3,a1
    80003da8:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003daa:	457c                	lw	a5,76(a0)
    80003dac:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003dae:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003db0:	e79d                	bnez	a5,80003dde <dirlookup+0x54>
    80003db2:	a8a5                	j	80003e2a <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003db4:	00005517          	auipc	a0,0x5
    80003db8:	a3c50513          	addi	a0,a0,-1476 # 800087f0 <syscalls+0x200>
    80003dbc:	ffffc097          	auipc	ra,0xffffc
    80003dc0:	788080e7          	jalr	1928(ra) # 80000544 <panic>
      panic("dirlookup read");
    80003dc4:	00005517          	auipc	a0,0x5
    80003dc8:	a4450513          	addi	a0,a0,-1468 # 80008808 <syscalls+0x218>
    80003dcc:	ffffc097          	auipc	ra,0xffffc
    80003dd0:	778080e7          	jalr	1912(ra) # 80000544 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dd4:	24c1                	addiw	s1,s1,16
    80003dd6:	04c92783          	lw	a5,76(s2)
    80003dda:	04f4f763          	bgeu	s1,a5,80003e28 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003dde:	4741                	li	a4,16
    80003de0:	86a6                	mv	a3,s1
    80003de2:	fc040613          	addi	a2,s0,-64
    80003de6:	4581                	li	a1,0
    80003de8:	854a                	mv	a0,s2
    80003dea:	00000097          	auipc	ra,0x0
    80003dee:	d48080e7          	jalr	-696(ra) # 80003b32 <readi>
    80003df2:	47c1                	li	a5,16
    80003df4:	fcf518e3          	bne	a0,a5,80003dc4 <dirlookup+0x3a>
    if(de.inum == 0)
    80003df8:	fc045783          	lhu	a5,-64(s0)
    80003dfc:	dfe1                	beqz	a5,80003dd4 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003dfe:	fc240593          	addi	a1,s0,-62
    80003e02:	854e                	mv	a0,s3
    80003e04:	00000097          	auipc	ra,0x0
    80003e08:	f6c080e7          	jalr	-148(ra) # 80003d70 <namecmp>
    80003e0c:	f561                	bnez	a0,80003dd4 <dirlookup+0x4a>
      if(poff)
    80003e0e:	000a0463          	beqz	s4,80003e16 <dirlookup+0x8c>
        *poff = off;
    80003e12:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003e16:	fc045583          	lhu	a1,-64(s0)
    80003e1a:	00092503          	lw	a0,0(s2)
    80003e1e:	fffff097          	auipc	ra,0xfffff
    80003e22:	728080e7          	jalr	1832(ra) # 80003546 <iget>
    80003e26:	a011                	j	80003e2a <dirlookup+0xa0>
  return 0;
    80003e28:	4501                	li	a0,0
}
    80003e2a:	70e2                	ld	ra,56(sp)
    80003e2c:	7442                	ld	s0,48(sp)
    80003e2e:	74a2                	ld	s1,40(sp)
    80003e30:	7902                	ld	s2,32(sp)
    80003e32:	69e2                	ld	s3,24(sp)
    80003e34:	6a42                	ld	s4,16(sp)
    80003e36:	6121                	addi	sp,sp,64
    80003e38:	8082                	ret

0000000080003e3a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003e3a:	711d                	addi	sp,sp,-96
    80003e3c:	ec86                	sd	ra,88(sp)
    80003e3e:	e8a2                	sd	s0,80(sp)
    80003e40:	e4a6                	sd	s1,72(sp)
    80003e42:	e0ca                	sd	s2,64(sp)
    80003e44:	fc4e                	sd	s3,56(sp)
    80003e46:	f852                	sd	s4,48(sp)
    80003e48:	f456                	sd	s5,40(sp)
    80003e4a:	f05a                	sd	s6,32(sp)
    80003e4c:	ec5e                	sd	s7,24(sp)
    80003e4e:	e862                	sd	s8,16(sp)
    80003e50:	e466                	sd	s9,8(sp)
    80003e52:	1080                	addi	s0,sp,96
    80003e54:	84aa                	mv	s1,a0
    80003e56:	8b2e                	mv	s6,a1
    80003e58:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003e5a:	00054703          	lbu	a4,0(a0)
    80003e5e:	02f00793          	li	a5,47
    80003e62:	02f70363          	beq	a4,a5,80003e88 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003e66:	ffffe097          	auipc	ra,0xffffe
    80003e6a:	b60080e7          	jalr	-1184(ra) # 800019c6 <myproc>
    80003e6e:	15053503          	ld	a0,336(a0)
    80003e72:	00000097          	auipc	ra,0x0
    80003e76:	9ce080e7          	jalr	-1586(ra) # 80003840 <idup>
    80003e7a:	89aa                	mv	s3,a0
  while(*path == '/')
    80003e7c:	02f00913          	li	s2,47
  len = path - s;
    80003e80:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003e82:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003e84:	4c05                	li	s8,1
    80003e86:	a865                	j	80003f3e <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003e88:	4585                	li	a1,1
    80003e8a:	4505                	li	a0,1
    80003e8c:	fffff097          	auipc	ra,0xfffff
    80003e90:	6ba080e7          	jalr	1722(ra) # 80003546 <iget>
    80003e94:	89aa                	mv	s3,a0
    80003e96:	b7dd                	j	80003e7c <namex+0x42>
      iunlockput(ip);
    80003e98:	854e                	mv	a0,s3
    80003e9a:	00000097          	auipc	ra,0x0
    80003e9e:	c46080e7          	jalr	-954(ra) # 80003ae0 <iunlockput>
      return 0;
    80003ea2:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003ea4:	854e                	mv	a0,s3
    80003ea6:	60e6                	ld	ra,88(sp)
    80003ea8:	6446                	ld	s0,80(sp)
    80003eaa:	64a6                	ld	s1,72(sp)
    80003eac:	6906                	ld	s2,64(sp)
    80003eae:	79e2                	ld	s3,56(sp)
    80003eb0:	7a42                	ld	s4,48(sp)
    80003eb2:	7aa2                	ld	s5,40(sp)
    80003eb4:	7b02                	ld	s6,32(sp)
    80003eb6:	6be2                	ld	s7,24(sp)
    80003eb8:	6c42                	ld	s8,16(sp)
    80003eba:	6ca2                	ld	s9,8(sp)
    80003ebc:	6125                	addi	sp,sp,96
    80003ebe:	8082                	ret
      iunlock(ip);
    80003ec0:	854e                	mv	a0,s3
    80003ec2:	00000097          	auipc	ra,0x0
    80003ec6:	a7e080e7          	jalr	-1410(ra) # 80003940 <iunlock>
      return ip;
    80003eca:	bfe9                	j	80003ea4 <namex+0x6a>
      iunlockput(ip);
    80003ecc:	854e                	mv	a0,s3
    80003ece:	00000097          	auipc	ra,0x0
    80003ed2:	c12080e7          	jalr	-1006(ra) # 80003ae0 <iunlockput>
      return 0;
    80003ed6:	89d2                	mv	s3,s4
    80003ed8:	b7f1                	j	80003ea4 <namex+0x6a>
  len = path - s;
    80003eda:	40b48633          	sub	a2,s1,a1
    80003ede:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003ee2:	094cd463          	bge	s9,s4,80003f6a <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003ee6:	4639                	li	a2,14
    80003ee8:	8556                	mv	a0,s5
    80003eea:	ffffd097          	auipc	ra,0xffffd
    80003eee:	e5c080e7          	jalr	-420(ra) # 80000d46 <memmove>
  while(*path == '/')
    80003ef2:	0004c783          	lbu	a5,0(s1)
    80003ef6:	01279763          	bne	a5,s2,80003f04 <namex+0xca>
    path++;
    80003efa:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003efc:	0004c783          	lbu	a5,0(s1)
    80003f00:	ff278de3          	beq	a5,s2,80003efa <namex+0xc0>
    ilock(ip);
    80003f04:	854e                	mv	a0,s3
    80003f06:	00000097          	auipc	ra,0x0
    80003f0a:	978080e7          	jalr	-1672(ra) # 8000387e <ilock>
    if(ip->type != T_DIR){
    80003f0e:	04499783          	lh	a5,68(s3)
    80003f12:	f98793e3          	bne	a5,s8,80003e98 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003f16:	000b0563          	beqz	s6,80003f20 <namex+0xe6>
    80003f1a:	0004c783          	lbu	a5,0(s1)
    80003f1e:	d3cd                	beqz	a5,80003ec0 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003f20:	865e                	mv	a2,s7
    80003f22:	85d6                	mv	a1,s5
    80003f24:	854e                	mv	a0,s3
    80003f26:	00000097          	auipc	ra,0x0
    80003f2a:	e64080e7          	jalr	-412(ra) # 80003d8a <dirlookup>
    80003f2e:	8a2a                	mv	s4,a0
    80003f30:	dd51                	beqz	a0,80003ecc <namex+0x92>
    iunlockput(ip);
    80003f32:	854e                	mv	a0,s3
    80003f34:	00000097          	auipc	ra,0x0
    80003f38:	bac080e7          	jalr	-1108(ra) # 80003ae0 <iunlockput>
    ip = next;
    80003f3c:	89d2                	mv	s3,s4
  while(*path == '/')
    80003f3e:	0004c783          	lbu	a5,0(s1)
    80003f42:	05279763          	bne	a5,s2,80003f90 <namex+0x156>
    path++;
    80003f46:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f48:	0004c783          	lbu	a5,0(s1)
    80003f4c:	ff278de3          	beq	a5,s2,80003f46 <namex+0x10c>
  if(*path == 0)
    80003f50:	c79d                	beqz	a5,80003f7e <namex+0x144>
    path++;
    80003f52:	85a6                	mv	a1,s1
  len = path - s;
    80003f54:	8a5e                	mv	s4,s7
    80003f56:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003f58:	01278963          	beq	a5,s2,80003f6a <namex+0x130>
    80003f5c:	dfbd                	beqz	a5,80003eda <namex+0xa0>
    path++;
    80003f5e:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003f60:	0004c783          	lbu	a5,0(s1)
    80003f64:	ff279ce3          	bne	a5,s2,80003f5c <namex+0x122>
    80003f68:	bf8d                	j	80003eda <namex+0xa0>
    memmove(name, s, len);
    80003f6a:	2601                	sext.w	a2,a2
    80003f6c:	8556                	mv	a0,s5
    80003f6e:	ffffd097          	auipc	ra,0xffffd
    80003f72:	dd8080e7          	jalr	-552(ra) # 80000d46 <memmove>
    name[len] = 0;
    80003f76:	9a56                	add	s4,s4,s5
    80003f78:	000a0023          	sb	zero,0(s4)
    80003f7c:	bf9d                	j	80003ef2 <namex+0xb8>
  if(nameiparent){
    80003f7e:	f20b03e3          	beqz	s6,80003ea4 <namex+0x6a>
    iput(ip);
    80003f82:	854e                	mv	a0,s3
    80003f84:	00000097          	auipc	ra,0x0
    80003f88:	ab4080e7          	jalr	-1356(ra) # 80003a38 <iput>
    return 0;
    80003f8c:	4981                	li	s3,0
    80003f8e:	bf19                	j	80003ea4 <namex+0x6a>
  if(*path == 0)
    80003f90:	d7fd                	beqz	a5,80003f7e <namex+0x144>
  while(*path != '/' && *path != 0)
    80003f92:	0004c783          	lbu	a5,0(s1)
    80003f96:	85a6                	mv	a1,s1
    80003f98:	b7d1                	j	80003f5c <namex+0x122>

0000000080003f9a <dirlink>:
{
    80003f9a:	7139                	addi	sp,sp,-64
    80003f9c:	fc06                	sd	ra,56(sp)
    80003f9e:	f822                	sd	s0,48(sp)
    80003fa0:	f426                	sd	s1,40(sp)
    80003fa2:	f04a                	sd	s2,32(sp)
    80003fa4:	ec4e                	sd	s3,24(sp)
    80003fa6:	e852                	sd	s4,16(sp)
    80003fa8:	0080                	addi	s0,sp,64
    80003faa:	892a                	mv	s2,a0
    80003fac:	8a2e                	mv	s4,a1
    80003fae:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003fb0:	4601                	li	a2,0
    80003fb2:	00000097          	auipc	ra,0x0
    80003fb6:	dd8080e7          	jalr	-552(ra) # 80003d8a <dirlookup>
    80003fba:	e93d                	bnez	a0,80004030 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fbc:	04c92483          	lw	s1,76(s2)
    80003fc0:	c49d                	beqz	s1,80003fee <dirlink+0x54>
    80003fc2:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003fc4:	4741                	li	a4,16
    80003fc6:	86a6                	mv	a3,s1
    80003fc8:	fc040613          	addi	a2,s0,-64
    80003fcc:	4581                	li	a1,0
    80003fce:	854a                	mv	a0,s2
    80003fd0:	00000097          	auipc	ra,0x0
    80003fd4:	b62080e7          	jalr	-1182(ra) # 80003b32 <readi>
    80003fd8:	47c1                	li	a5,16
    80003fda:	06f51163          	bne	a0,a5,8000403c <dirlink+0xa2>
    if(de.inum == 0)
    80003fde:	fc045783          	lhu	a5,-64(s0)
    80003fe2:	c791                	beqz	a5,80003fee <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fe4:	24c1                	addiw	s1,s1,16
    80003fe6:	04c92783          	lw	a5,76(s2)
    80003fea:	fcf4ede3          	bltu	s1,a5,80003fc4 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003fee:	4639                	li	a2,14
    80003ff0:	85d2                	mv	a1,s4
    80003ff2:	fc240513          	addi	a0,s0,-62
    80003ff6:	ffffd097          	auipc	ra,0xffffd
    80003ffa:	e04080e7          	jalr	-508(ra) # 80000dfa <strncpy>
  de.inum = inum;
    80003ffe:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004002:	4741                	li	a4,16
    80004004:	86a6                	mv	a3,s1
    80004006:	fc040613          	addi	a2,s0,-64
    8000400a:	4581                	li	a1,0
    8000400c:	854a                	mv	a0,s2
    8000400e:	00000097          	auipc	ra,0x0
    80004012:	c1c080e7          	jalr	-996(ra) # 80003c2a <writei>
    80004016:	1541                	addi	a0,a0,-16
    80004018:	00a03533          	snez	a0,a0
    8000401c:	40a00533          	neg	a0,a0
}
    80004020:	70e2                	ld	ra,56(sp)
    80004022:	7442                	ld	s0,48(sp)
    80004024:	74a2                	ld	s1,40(sp)
    80004026:	7902                	ld	s2,32(sp)
    80004028:	69e2                	ld	s3,24(sp)
    8000402a:	6a42                	ld	s4,16(sp)
    8000402c:	6121                	addi	sp,sp,64
    8000402e:	8082                	ret
    iput(ip);
    80004030:	00000097          	auipc	ra,0x0
    80004034:	a08080e7          	jalr	-1528(ra) # 80003a38 <iput>
    return -1;
    80004038:	557d                	li	a0,-1
    8000403a:	b7dd                	j	80004020 <dirlink+0x86>
      panic("dirlink read");
    8000403c:	00004517          	auipc	a0,0x4
    80004040:	7dc50513          	addi	a0,a0,2012 # 80008818 <syscalls+0x228>
    80004044:	ffffc097          	auipc	ra,0xffffc
    80004048:	500080e7          	jalr	1280(ra) # 80000544 <panic>

000000008000404c <namei>:

struct inode*
namei(char *path)
{
    8000404c:	1101                	addi	sp,sp,-32
    8000404e:	ec06                	sd	ra,24(sp)
    80004050:	e822                	sd	s0,16(sp)
    80004052:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004054:	fe040613          	addi	a2,s0,-32
    80004058:	4581                	li	a1,0
    8000405a:	00000097          	auipc	ra,0x0
    8000405e:	de0080e7          	jalr	-544(ra) # 80003e3a <namex>
}
    80004062:	60e2                	ld	ra,24(sp)
    80004064:	6442                	ld	s0,16(sp)
    80004066:	6105                	addi	sp,sp,32
    80004068:	8082                	ret

000000008000406a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000406a:	1141                	addi	sp,sp,-16
    8000406c:	e406                	sd	ra,8(sp)
    8000406e:	e022                	sd	s0,0(sp)
    80004070:	0800                	addi	s0,sp,16
    80004072:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004074:	4585                	li	a1,1
    80004076:	00000097          	auipc	ra,0x0
    8000407a:	dc4080e7          	jalr	-572(ra) # 80003e3a <namex>
}
    8000407e:	60a2                	ld	ra,8(sp)
    80004080:	6402                	ld	s0,0(sp)
    80004082:	0141                	addi	sp,sp,16
    80004084:	8082                	ret

0000000080004086 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004086:	1101                	addi	sp,sp,-32
    80004088:	ec06                	sd	ra,24(sp)
    8000408a:	e822                	sd	s0,16(sp)
    8000408c:	e426                	sd	s1,8(sp)
    8000408e:	e04a                	sd	s2,0(sp)
    80004090:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004092:	00025917          	auipc	s2,0x25
    80004096:	0b690913          	addi	s2,s2,182 # 80029148 <log>
    8000409a:	01892583          	lw	a1,24(s2)
    8000409e:	02892503          	lw	a0,40(s2)
    800040a2:	fffff097          	auipc	ra,0xfffff
    800040a6:	fc2080e7          	jalr	-62(ra) # 80003064 <bread>
    800040aa:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800040ac:	02c92683          	lw	a3,44(s2)
    800040b0:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800040b2:	02d05763          	blez	a3,800040e0 <write_head+0x5a>
    800040b6:	00025797          	auipc	a5,0x25
    800040ba:	0c278793          	addi	a5,a5,194 # 80029178 <log+0x30>
    800040be:	05c50713          	addi	a4,a0,92
    800040c2:	36fd                	addiw	a3,a3,-1
    800040c4:	1682                	slli	a3,a3,0x20
    800040c6:	9281                	srli	a3,a3,0x20
    800040c8:	068a                	slli	a3,a3,0x2
    800040ca:	00025617          	auipc	a2,0x25
    800040ce:	0b260613          	addi	a2,a2,178 # 8002917c <log+0x34>
    800040d2:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800040d4:	4390                	lw	a2,0(a5)
    800040d6:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800040d8:	0791                	addi	a5,a5,4
    800040da:	0711                	addi	a4,a4,4
    800040dc:	fed79ce3          	bne	a5,a3,800040d4 <write_head+0x4e>
  }
  bwrite(buf);
    800040e0:	8526                	mv	a0,s1
    800040e2:	fffff097          	auipc	ra,0xfffff
    800040e6:	074080e7          	jalr	116(ra) # 80003156 <bwrite>
  brelse(buf);
    800040ea:	8526                	mv	a0,s1
    800040ec:	fffff097          	auipc	ra,0xfffff
    800040f0:	0a8080e7          	jalr	168(ra) # 80003194 <brelse>
}
    800040f4:	60e2                	ld	ra,24(sp)
    800040f6:	6442                	ld	s0,16(sp)
    800040f8:	64a2                	ld	s1,8(sp)
    800040fa:	6902                	ld	s2,0(sp)
    800040fc:	6105                	addi	sp,sp,32
    800040fe:	8082                	ret

0000000080004100 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004100:	00025797          	auipc	a5,0x25
    80004104:	0747a783          	lw	a5,116(a5) # 80029174 <log+0x2c>
    80004108:	0af05d63          	blez	a5,800041c2 <install_trans+0xc2>
{
    8000410c:	7139                	addi	sp,sp,-64
    8000410e:	fc06                	sd	ra,56(sp)
    80004110:	f822                	sd	s0,48(sp)
    80004112:	f426                	sd	s1,40(sp)
    80004114:	f04a                	sd	s2,32(sp)
    80004116:	ec4e                	sd	s3,24(sp)
    80004118:	e852                	sd	s4,16(sp)
    8000411a:	e456                	sd	s5,8(sp)
    8000411c:	e05a                	sd	s6,0(sp)
    8000411e:	0080                	addi	s0,sp,64
    80004120:	8b2a                	mv	s6,a0
    80004122:	00025a97          	auipc	s5,0x25
    80004126:	056a8a93          	addi	s5,s5,86 # 80029178 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000412a:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000412c:	00025997          	auipc	s3,0x25
    80004130:	01c98993          	addi	s3,s3,28 # 80029148 <log>
    80004134:	a035                	j	80004160 <install_trans+0x60>
      bunpin(dbuf);
    80004136:	8526                	mv	a0,s1
    80004138:	fffff097          	auipc	ra,0xfffff
    8000413c:	136080e7          	jalr	310(ra) # 8000326e <bunpin>
    brelse(lbuf);
    80004140:	854a                	mv	a0,s2
    80004142:	fffff097          	auipc	ra,0xfffff
    80004146:	052080e7          	jalr	82(ra) # 80003194 <brelse>
    brelse(dbuf);
    8000414a:	8526                	mv	a0,s1
    8000414c:	fffff097          	auipc	ra,0xfffff
    80004150:	048080e7          	jalr	72(ra) # 80003194 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004154:	2a05                	addiw	s4,s4,1
    80004156:	0a91                	addi	s5,s5,4
    80004158:	02c9a783          	lw	a5,44(s3)
    8000415c:	04fa5963          	bge	s4,a5,800041ae <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004160:	0189a583          	lw	a1,24(s3)
    80004164:	014585bb          	addw	a1,a1,s4
    80004168:	2585                	addiw	a1,a1,1
    8000416a:	0289a503          	lw	a0,40(s3)
    8000416e:	fffff097          	auipc	ra,0xfffff
    80004172:	ef6080e7          	jalr	-266(ra) # 80003064 <bread>
    80004176:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004178:	000aa583          	lw	a1,0(s5)
    8000417c:	0289a503          	lw	a0,40(s3)
    80004180:	fffff097          	auipc	ra,0xfffff
    80004184:	ee4080e7          	jalr	-284(ra) # 80003064 <bread>
    80004188:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000418a:	40000613          	li	a2,1024
    8000418e:	05890593          	addi	a1,s2,88
    80004192:	05850513          	addi	a0,a0,88
    80004196:	ffffd097          	auipc	ra,0xffffd
    8000419a:	bb0080e7          	jalr	-1104(ra) # 80000d46 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000419e:	8526                	mv	a0,s1
    800041a0:	fffff097          	auipc	ra,0xfffff
    800041a4:	fb6080e7          	jalr	-74(ra) # 80003156 <bwrite>
    if(recovering == 0)
    800041a8:	f80b1ce3          	bnez	s6,80004140 <install_trans+0x40>
    800041ac:	b769                	j	80004136 <install_trans+0x36>
}
    800041ae:	70e2                	ld	ra,56(sp)
    800041b0:	7442                	ld	s0,48(sp)
    800041b2:	74a2                	ld	s1,40(sp)
    800041b4:	7902                	ld	s2,32(sp)
    800041b6:	69e2                	ld	s3,24(sp)
    800041b8:	6a42                	ld	s4,16(sp)
    800041ba:	6aa2                	ld	s5,8(sp)
    800041bc:	6b02                	ld	s6,0(sp)
    800041be:	6121                	addi	sp,sp,64
    800041c0:	8082                	ret
    800041c2:	8082                	ret

00000000800041c4 <initlog>:
{
    800041c4:	7179                	addi	sp,sp,-48
    800041c6:	f406                	sd	ra,40(sp)
    800041c8:	f022                	sd	s0,32(sp)
    800041ca:	ec26                	sd	s1,24(sp)
    800041cc:	e84a                	sd	s2,16(sp)
    800041ce:	e44e                	sd	s3,8(sp)
    800041d0:	1800                	addi	s0,sp,48
    800041d2:	892a                	mv	s2,a0
    800041d4:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800041d6:	00025497          	auipc	s1,0x25
    800041da:	f7248493          	addi	s1,s1,-142 # 80029148 <log>
    800041de:	00004597          	auipc	a1,0x4
    800041e2:	64a58593          	addi	a1,a1,1610 # 80008828 <syscalls+0x238>
    800041e6:	8526                	mv	a0,s1
    800041e8:	ffffd097          	auipc	ra,0xffffd
    800041ec:	972080e7          	jalr	-1678(ra) # 80000b5a <initlock>
  log.start = sb->logstart;
    800041f0:	0149a583          	lw	a1,20(s3)
    800041f4:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800041f6:	0109a783          	lw	a5,16(s3)
    800041fa:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800041fc:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004200:	854a                	mv	a0,s2
    80004202:	fffff097          	auipc	ra,0xfffff
    80004206:	e62080e7          	jalr	-414(ra) # 80003064 <bread>
  log.lh.n = lh->n;
    8000420a:	4d3c                	lw	a5,88(a0)
    8000420c:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000420e:	02f05563          	blez	a5,80004238 <initlog+0x74>
    80004212:	05c50713          	addi	a4,a0,92
    80004216:	00025697          	auipc	a3,0x25
    8000421a:	f6268693          	addi	a3,a3,-158 # 80029178 <log+0x30>
    8000421e:	37fd                	addiw	a5,a5,-1
    80004220:	1782                	slli	a5,a5,0x20
    80004222:	9381                	srli	a5,a5,0x20
    80004224:	078a                	slli	a5,a5,0x2
    80004226:	06050613          	addi	a2,a0,96
    8000422a:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000422c:	4310                	lw	a2,0(a4)
    8000422e:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004230:	0711                	addi	a4,a4,4
    80004232:	0691                	addi	a3,a3,4
    80004234:	fef71ce3          	bne	a4,a5,8000422c <initlog+0x68>
  brelse(buf);
    80004238:	fffff097          	auipc	ra,0xfffff
    8000423c:	f5c080e7          	jalr	-164(ra) # 80003194 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004240:	4505                	li	a0,1
    80004242:	00000097          	auipc	ra,0x0
    80004246:	ebe080e7          	jalr	-322(ra) # 80004100 <install_trans>
  log.lh.n = 0;
    8000424a:	00025797          	auipc	a5,0x25
    8000424e:	f207a523          	sw	zero,-214(a5) # 80029174 <log+0x2c>
  write_head(); // clear the log
    80004252:	00000097          	auipc	ra,0x0
    80004256:	e34080e7          	jalr	-460(ra) # 80004086 <write_head>
}
    8000425a:	70a2                	ld	ra,40(sp)
    8000425c:	7402                	ld	s0,32(sp)
    8000425e:	64e2                	ld	s1,24(sp)
    80004260:	6942                	ld	s2,16(sp)
    80004262:	69a2                	ld	s3,8(sp)
    80004264:	6145                	addi	sp,sp,48
    80004266:	8082                	ret

0000000080004268 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004268:	1101                	addi	sp,sp,-32
    8000426a:	ec06                	sd	ra,24(sp)
    8000426c:	e822                	sd	s0,16(sp)
    8000426e:	e426                	sd	s1,8(sp)
    80004270:	e04a                	sd	s2,0(sp)
    80004272:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004274:	00025517          	auipc	a0,0x25
    80004278:	ed450513          	addi	a0,a0,-300 # 80029148 <log>
    8000427c:	ffffd097          	auipc	ra,0xffffd
    80004280:	96e080e7          	jalr	-1682(ra) # 80000bea <acquire>
  while(1){
    if(log.committing){
    80004284:	00025497          	auipc	s1,0x25
    80004288:	ec448493          	addi	s1,s1,-316 # 80029148 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000428c:	4979                	li	s2,30
    8000428e:	a039                	j	8000429c <begin_op+0x34>
      sleep(&log, &log.lock);
    80004290:	85a6                	mv	a1,s1
    80004292:	8526                	mv	a0,s1
    80004294:	ffffe097          	auipc	ra,0xffffe
    80004298:	e76080e7          	jalr	-394(ra) # 8000210a <sleep>
    if(log.committing){
    8000429c:	50dc                	lw	a5,36(s1)
    8000429e:	fbed                	bnez	a5,80004290 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042a0:	509c                	lw	a5,32(s1)
    800042a2:	0017871b          	addiw	a4,a5,1
    800042a6:	0007069b          	sext.w	a3,a4
    800042aa:	0027179b          	slliw	a5,a4,0x2
    800042ae:	9fb9                	addw	a5,a5,a4
    800042b0:	0017979b          	slliw	a5,a5,0x1
    800042b4:	54d8                	lw	a4,44(s1)
    800042b6:	9fb9                	addw	a5,a5,a4
    800042b8:	00f95963          	bge	s2,a5,800042ca <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800042bc:	85a6                	mv	a1,s1
    800042be:	8526                	mv	a0,s1
    800042c0:	ffffe097          	auipc	ra,0xffffe
    800042c4:	e4a080e7          	jalr	-438(ra) # 8000210a <sleep>
    800042c8:	bfd1                	j	8000429c <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800042ca:	00025517          	auipc	a0,0x25
    800042ce:	e7e50513          	addi	a0,a0,-386 # 80029148 <log>
    800042d2:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800042d4:	ffffd097          	auipc	ra,0xffffd
    800042d8:	9ca080e7          	jalr	-1590(ra) # 80000c9e <release>
      break;
    }
  }
}
    800042dc:	60e2                	ld	ra,24(sp)
    800042de:	6442                	ld	s0,16(sp)
    800042e0:	64a2                	ld	s1,8(sp)
    800042e2:	6902                	ld	s2,0(sp)
    800042e4:	6105                	addi	sp,sp,32
    800042e6:	8082                	ret

00000000800042e8 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800042e8:	7139                	addi	sp,sp,-64
    800042ea:	fc06                	sd	ra,56(sp)
    800042ec:	f822                	sd	s0,48(sp)
    800042ee:	f426                	sd	s1,40(sp)
    800042f0:	f04a                	sd	s2,32(sp)
    800042f2:	ec4e                	sd	s3,24(sp)
    800042f4:	e852                	sd	s4,16(sp)
    800042f6:	e456                	sd	s5,8(sp)
    800042f8:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800042fa:	00025497          	auipc	s1,0x25
    800042fe:	e4e48493          	addi	s1,s1,-434 # 80029148 <log>
    80004302:	8526                	mv	a0,s1
    80004304:	ffffd097          	auipc	ra,0xffffd
    80004308:	8e6080e7          	jalr	-1818(ra) # 80000bea <acquire>
  log.outstanding -= 1;
    8000430c:	509c                	lw	a5,32(s1)
    8000430e:	37fd                	addiw	a5,a5,-1
    80004310:	0007891b          	sext.w	s2,a5
    80004314:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004316:	50dc                	lw	a5,36(s1)
    80004318:	efb9                	bnez	a5,80004376 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000431a:	06091663          	bnez	s2,80004386 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    8000431e:	00025497          	auipc	s1,0x25
    80004322:	e2a48493          	addi	s1,s1,-470 # 80029148 <log>
    80004326:	4785                	li	a5,1
    80004328:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000432a:	8526                	mv	a0,s1
    8000432c:	ffffd097          	auipc	ra,0xffffd
    80004330:	972080e7          	jalr	-1678(ra) # 80000c9e <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004334:	54dc                	lw	a5,44(s1)
    80004336:	06f04763          	bgtz	a5,800043a4 <end_op+0xbc>
    acquire(&log.lock);
    8000433a:	00025497          	auipc	s1,0x25
    8000433e:	e0e48493          	addi	s1,s1,-498 # 80029148 <log>
    80004342:	8526                	mv	a0,s1
    80004344:	ffffd097          	auipc	ra,0xffffd
    80004348:	8a6080e7          	jalr	-1882(ra) # 80000bea <acquire>
    log.committing = 0;
    8000434c:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004350:	8526                	mv	a0,s1
    80004352:	ffffe097          	auipc	ra,0xffffe
    80004356:	e1c080e7          	jalr	-484(ra) # 8000216e <wakeup>
    release(&log.lock);
    8000435a:	8526                	mv	a0,s1
    8000435c:	ffffd097          	auipc	ra,0xffffd
    80004360:	942080e7          	jalr	-1726(ra) # 80000c9e <release>
}
    80004364:	70e2                	ld	ra,56(sp)
    80004366:	7442                	ld	s0,48(sp)
    80004368:	74a2                	ld	s1,40(sp)
    8000436a:	7902                	ld	s2,32(sp)
    8000436c:	69e2                	ld	s3,24(sp)
    8000436e:	6a42                	ld	s4,16(sp)
    80004370:	6aa2                	ld	s5,8(sp)
    80004372:	6121                	addi	sp,sp,64
    80004374:	8082                	ret
    panic("log.committing");
    80004376:	00004517          	auipc	a0,0x4
    8000437a:	4ba50513          	addi	a0,a0,1210 # 80008830 <syscalls+0x240>
    8000437e:	ffffc097          	auipc	ra,0xffffc
    80004382:	1c6080e7          	jalr	454(ra) # 80000544 <panic>
    wakeup(&log);
    80004386:	00025497          	auipc	s1,0x25
    8000438a:	dc248493          	addi	s1,s1,-574 # 80029148 <log>
    8000438e:	8526                	mv	a0,s1
    80004390:	ffffe097          	auipc	ra,0xffffe
    80004394:	dde080e7          	jalr	-546(ra) # 8000216e <wakeup>
  release(&log.lock);
    80004398:	8526                	mv	a0,s1
    8000439a:	ffffd097          	auipc	ra,0xffffd
    8000439e:	904080e7          	jalr	-1788(ra) # 80000c9e <release>
  if(do_commit){
    800043a2:	b7c9                	j	80004364 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043a4:	00025a97          	auipc	s5,0x25
    800043a8:	dd4a8a93          	addi	s5,s5,-556 # 80029178 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800043ac:	00025a17          	auipc	s4,0x25
    800043b0:	d9ca0a13          	addi	s4,s4,-612 # 80029148 <log>
    800043b4:	018a2583          	lw	a1,24(s4)
    800043b8:	012585bb          	addw	a1,a1,s2
    800043bc:	2585                	addiw	a1,a1,1
    800043be:	028a2503          	lw	a0,40(s4)
    800043c2:	fffff097          	auipc	ra,0xfffff
    800043c6:	ca2080e7          	jalr	-862(ra) # 80003064 <bread>
    800043ca:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800043cc:	000aa583          	lw	a1,0(s5)
    800043d0:	028a2503          	lw	a0,40(s4)
    800043d4:	fffff097          	auipc	ra,0xfffff
    800043d8:	c90080e7          	jalr	-880(ra) # 80003064 <bread>
    800043dc:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800043de:	40000613          	li	a2,1024
    800043e2:	05850593          	addi	a1,a0,88
    800043e6:	05848513          	addi	a0,s1,88
    800043ea:	ffffd097          	auipc	ra,0xffffd
    800043ee:	95c080e7          	jalr	-1700(ra) # 80000d46 <memmove>
    bwrite(to);  // write the log
    800043f2:	8526                	mv	a0,s1
    800043f4:	fffff097          	auipc	ra,0xfffff
    800043f8:	d62080e7          	jalr	-670(ra) # 80003156 <bwrite>
    brelse(from);
    800043fc:	854e                	mv	a0,s3
    800043fe:	fffff097          	auipc	ra,0xfffff
    80004402:	d96080e7          	jalr	-618(ra) # 80003194 <brelse>
    brelse(to);
    80004406:	8526                	mv	a0,s1
    80004408:	fffff097          	auipc	ra,0xfffff
    8000440c:	d8c080e7          	jalr	-628(ra) # 80003194 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004410:	2905                	addiw	s2,s2,1
    80004412:	0a91                	addi	s5,s5,4
    80004414:	02ca2783          	lw	a5,44(s4)
    80004418:	f8f94ee3          	blt	s2,a5,800043b4 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000441c:	00000097          	auipc	ra,0x0
    80004420:	c6a080e7          	jalr	-918(ra) # 80004086 <write_head>
    install_trans(0); // Now install writes to home locations
    80004424:	4501                	li	a0,0
    80004426:	00000097          	auipc	ra,0x0
    8000442a:	cda080e7          	jalr	-806(ra) # 80004100 <install_trans>
    log.lh.n = 0;
    8000442e:	00025797          	auipc	a5,0x25
    80004432:	d407a323          	sw	zero,-698(a5) # 80029174 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004436:	00000097          	auipc	ra,0x0
    8000443a:	c50080e7          	jalr	-944(ra) # 80004086 <write_head>
    8000443e:	bdf5                	j	8000433a <end_op+0x52>

0000000080004440 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004440:	1101                	addi	sp,sp,-32
    80004442:	ec06                	sd	ra,24(sp)
    80004444:	e822                	sd	s0,16(sp)
    80004446:	e426                	sd	s1,8(sp)
    80004448:	e04a                	sd	s2,0(sp)
    8000444a:	1000                	addi	s0,sp,32
    8000444c:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000444e:	00025917          	auipc	s2,0x25
    80004452:	cfa90913          	addi	s2,s2,-774 # 80029148 <log>
    80004456:	854a                	mv	a0,s2
    80004458:	ffffc097          	auipc	ra,0xffffc
    8000445c:	792080e7          	jalr	1938(ra) # 80000bea <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004460:	02c92603          	lw	a2,44(s2)
    80004464:	47f5                	li	a5,29
    80004466:	06c7c563          	blt	a5,a2,800044d0 <log_write+0x90>
    8000446a:	00025797          	auipc	a5,0x25
    8000446e:	cfa7a783          	lw	a5,-774(a5) # 80029164 <log+0x1c>
    80004472:	37fd                	addiw	a5,a5,-1
    80004474:	04f65e63          	bge	a2,a5,800044d0 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004478:	00025797          	auipc	a5,0x25
    8000447c:	cf07a783          	lw	a5,-784(a5) # 80029168 <log+0x20>
    80004480:	06f05063          	blez	a5,800044e0 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004484:	4781                	li	a5,0
    80004486:	06c05563          	blez	a2,800044f0 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000448a:	44cc                	lw	a1,12(s1)
    8000448c:	00025717          	auipc	a4,0x25
    80004490:	cec70713          	addi	a4,a4,-788 # 80029178 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004494:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004496:	4314                	lw	a3,0(a4)
    80004498:	04b68c63          	beq	a3,a1,800044f0 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000449c:	2785                	addiw	a5,a5,1
    8000449e:	0711                	addi	a4,a4,4
    800044a0:	fef61be3          	bne	a2,a5,80004496 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800044a4:	0621                	addi	a2,a2,8
    800044a6:	060a                	slli	a2,a2,0x2
    800044a8:	00025797          	auipc	a5,0x25
    800044ac:	ca078793          	addi	a5,a5,-864 # 80029148 <log>
    800044b0:	963e                	add	a2,a2,a5
    800044b2:	44dc                	lw	a5,12(s1)
    800044b4:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800044b6:	8526                	mv	a0,s1
    800044b8:	fffff097          	auipc	ra,0xfffff
    800044bc:	d7a080e7          	jalr	-646(ra) # 80003232 <bpin>
    log.lh.n++;
    800044c0:	00025717          	auipc	a4,0x25
    800044c4:	c8870713          	addi	a4,a4,-888 # 80029148 <log>
    800044c8:	575c                	lw	a5,44(a4)
    800044ca:	2785                	addiw	a5,a5,1
    800044cc:	d75c                	sw	a5,44(a4)
    800044ce:	a835                	j	8000450a <log_write+0xca>
    panic("too big a transaction");
    800044d0:	00004517          	auipc	a0,0x4
    800044d4:	37050513          	addi	a0,a0,880 # 80008840 <syscalls+0x250>
    800044d8:	ffffc097          	auipc	ra,0xffffc
    800044dc:	06c080e7          	jalr	108(ra) # 80000544 <panic>
    panic("log_write outside of trans");
    800044e0:	00004517          	auipc	a0,0x4
    800044e4:	37850513          	addi	a0,a0,888 # 80008858 <syscalls+0x268>
    800044e8:	ffffc097          	auipc	ra,0xffffc
    800044ec:	05c080e7          	jalr	92(ra) # 80000544 <panic>
  log.lh.block[i] = b->blockno;
    800044f0:	00878713          	addi	a4,a5,8
    800044f4:	00271693          	slli	a3,a4,0x2
    800044f8:	00025717          	auipc	a4,0x25
    800044fc:	c5070713          	addi	a4,a4,-944 # 80029148 <log>
    80004500:	9736                	add	a4,a4,a3
    80004502:	44d4                	lw	a3,12(s1)
    80004504:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004506:	faf608e3          	beq	a2,a5,800044b6 <log_write+0x76>
  }
  release(&log.lock);
    8000450a:	00025517          	auipc	a0,0x25
    8000450e:	c3e50513          	addi	a0,a0,-962 # 80029148 <log>
    80004512:	ffffc097          	auipc	ra,0xffffc
    80004516:	78c080e7          	jalr	1932(ra) # 80000c9e <release>
}
    8000451a:	60e2                	ld	ra,24(sp)
    8000451c:	6442                	ld	s0,16(sp)
    8000451e:	64a2                	ld	s1,8(sp)
    80004520:	6902                	ld	s2,0(sp)
    80004522:	6105                	addi	sp,sp,32
    80004524:	8082                	ret

0000000080004526 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004526:	1101                	addi	sp,sp,-32
    80004528:	ec06                	sd	ra,24(sp)
    8000452a:	e822                	sd	s0,16(sp)
    8000452c:	e426                	sd	s1,8(sp)
    8000452e:	e04a                	sd	s2,0(sp)
    80004530:	1000                	addi	s0,sp,32
    80004532:	84aa                	mv	s1,a0
    80004534:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004536:	00004597          	auipc	a1,0x4
    8000453a:	34258593          	addi	a1,a1,834 # 80008878 <syscalls+0x288>
    8000453e:	0521                	addi	a0,a0,8
    80004540:	ffffc097          	auipc	ra,0xffffc
    80004544:	61a080e7          	jalr	1562(ra) # 80000b5a <initlock>
  lk->name = name;
    80004548:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000454c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004550:	0204a423          	sw	zero,40(s1)
}
    80004554:	60e2                	ld	ra,24(sp)
    80004556:	6442                	ld	s0,16(sp)
    80004558:	64a2                	ld	s1,8(sp)
    8000455a:	6902                	ld	s2,0(sp)
    8000455c:	6105                	addi	sp,sp,32
    8000455e:	8082                	ret

0000000080004560 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004560:	1101                	addi	sp,sp,-32
    80004562:	ec06                	sd	ra,24(sp)
    80004564:	e822                	sd	s0,16(sp)
    80004566:	e426                	sd	s1,8(sp)
    80004568:	e04a                	sd	s2,0(sp)
    8000456a:	1000                	addi	s0,sp,32
    8000456c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000456e:	00850913          	addi	s2,a0,8
    80004572:	854a                	mv	a0,s2
    80004574:	ffffc097          	auipc	ra,0xffffc
    80004578:	676080e7          	jalr	1654(ra) # 80000bea <acquire>
  while (lk->locked) {
    8000457c:	409c                	lw	a5,0(s1)
    8000457e:	cb89                	beqz	a5,80004590 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004580:	85ca                	mv	a1,s2
    80004582:	8526                	mv	a0,s1
    80004584:	ffffe097          	auipc	ra,0xffffe
    80004588:	b86080e7          	jalr	-1146(ra) # 8000210a <sleep>
  while (lk->locked) {
    8000458c:	409c                	lw	a5,0(s1)
    8000458e:	fbed                	bnez	a5,80004580 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004590:	4785                	li	a5,1
    80004592:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004594:	ffffd097          	auipc	ra,0xffffd
    80004598:	432080e7          	jalr	1074(ra) # 800019c6 <myproc>
    8000459c:	591c                	lw	a5,48(a0)
    8000459e:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800045a0:	854a                	mv	a0,s2
    800045a2:	ffffc097          	auipc	ra,0xffffc
    800045a6:	6fc080e7          	jalr	1788(ra) # 80000c9e <release>
}
    800045aa:	60e2                	ld	ra,24(sp)
    800045ac:	6442                	ld	s0,16(sp)
    800045ae:	64a2                	ld	s1,8(sp)
    800045b0:	6902                	ld	s2,0(sp)
    800045b2:	6105                	addi	sp,sp,32
    800045b4:	8082                	ret

00000000800045b6 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800045b6:	1101                	addi	sp,sp,-32
    800045b8:	ec06                	sd	ra,24(sp)
    800045ba:	e822                	sd	s0,16(sp)
    800045bc:	e426                	sd	s1,8(sp)
    800045be:	e04a                	sd	s2,0(sp)
    800045c0:	1000                	addi	s0,sp,32
    800045c2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045c4:	00850913          	addi	s2,a0,8
    800045c8:	854a                	mv	a0,s2
    800045ca:	ffffc097          	auipc	ra,0xffffc
    800045ce:	620080e7          	jalr	1568(ra) # 80000bea <acquire>
  lk->locked = 0;
    800045d2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800045d6:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800045da:	8526                	mv	a0,s1
    800045dc:	ffffe097          	auipc	ra,0xffffe
    800045e0:	b92080e7          	jalr	-1134(ra) # 8000216e <wakeup>
  release(&lk->lk);
    800045e4:	854a                	mv	a0,s2
    800045e6:	ffffc097          	auipc	ra,0xffffc
    800045ea:	6b8080e7          	jalr	1720(ra) # 80000c9e <release>
}
    800045ee:	60e2                	ld	ra,24(sp)
    800045f0:	6442                	ld	s0,16(sp)
    800045f2:	64a2                	ld	s1,8(sp)
    800045f4:	6902                	ld	s2,0(sp)
    800045f6:	6105                	addi	sp,sp,32
    800045f8:	8082                	ret

00000000800045fa <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800045fa:	7179                	addi	sp,sp,-48
    800045fc:	f406                	sd	ra,40(sp)
    800045fe:	f022                	sd	s0,32(sp)
    80004600:	ec26                	sd	s1,24(sp)
    80004602:	e84a                	sd	s2,16(sp)
    80004604:	e44e                	sd	s3,8(sp)
    80004606:	1800                	addi	s0,sp,48
    80004608:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000460a:	00850913          	addi	s2,a0,8
    8000460e:	854a                	mv	a0,s2
    80004610:	ffffc097          	auipc	ra,0xffffc
    80004614:	5da080e7          	jalr	1498(ra) # 80000bea <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004618:	409c                	lw	a5,0(s1)
    8000461a:	ef99                	bnez	a5,80004638 <holdingsleep+0x3e>
    8000461c:	4481                	li	s1,0
  release(&lk->lk);
    8000461e:	854a                	mv	a0,s2
    80004620:	ffffc097          	auipc	ra,0xffffc
    80004624:	67e080e7          	jalr	1662(ra) # 80000c9e <release>
  return r;
}
    80004628:	8526                	mv	a0,s1
    8000462a:	70a2                	ld	ra,40(sp)
    8000462c:	7402                	ld	s0,32(sp)
    8000462e:	64e2                	ld	s1,24(sp)
    80004630:	6942                	ld	s2,16(sp)
    80004632:	69a2                	ld	s3,8(sp)
    80004634:	6145                	addi	sp,sp,48
    80004636:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004638:	0284a983          	lw	s3,40(s1)
    8000463c:	ffffd097          	auipc	ra,0xffffd
    80004640:	38a080e7          	jalr	906(ra) # 800019c6 <myproc>
    80004644:	5904                	lw	s1,48(a0)
    80004646:	413484b3          	sub	s1,s1,s3
    8000464a:	0014b493          	seqz	s1,s1
    8000464e:	bfc1                	j	8000461e <holdingsleep+0x24>

0000000080004650 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004650:	1141                	addi	sp,sp,-16
    80004652:	e406                	sd	ra,8(sp)
    80004654:	e022                	sd	s0,0(sp)
    80004656:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004658:	00004597          	auipc	a1,0x4
    8000465c:	23058593          	addi	a1,a1,560 # 80008888 <syscalls+0x298>
    80004660:	00025517          	auipc	a0,0x25
    80004664:	c3050513          	addi	a0,a0,-976 # 80029290 <ftable>
    80004668:	ffffc097          	auipc	ra,0xffffc
    8000466c:	4f2080e7          	jalr	1266(ra) # 80000b5a <initlock>
}
    80004670:	60a2                	ld	ra,8(sp)
    80004672:	6402                	ld	s0,0(sp)
    80004674:	0141                	addi	sp,sp,16
    80004676:	8082                	ret

0000000080004678 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004678:	1101                	addi	sp,sp,-32
    8000467a:	ec06                	sd	ra,24(sp)
    8000467c:	e822                	sd	s0,16(sp)
    8000467e:	e426                	sd	s1,8(sp)
    80004680:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004682:	00025517          	auipc	a0,0x25
    80004686:	c0e50513          	addi	a0,a0,-1010 # 80029290 <ftable>
    8000468a:	ffffc097          	auipc	ra,0xffffc
    8000468e:	560080e7          	jalr	1376(ra) # 80000bea <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004692:	00025497          	auipc	s1,0x25
    80004696:	c1648493          	addi	s1,s1,-1002 # 800292a8 <ftable+0x18>
    8000469a:	00026717          	auipc	a4,0x26
    8000469e:	bae70713          	addi	a4,a4,-1106 # 8002a248 <disk>
    if(f->ref == 0){
    800046a2:	40dc                	lw	a5,4(s1)
    800046a4:	cf99                	beqz	a5,800046c2 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046a6:	02848493          	addi	s1,s1,40
    800046aa:	fee49ce3          	bne	s1,a4,800046a2 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800046ae:	00025517          	auipc	a0,0x25
    800046b2:	be250513          	addi	a0,a0,-1054 # 80029290 <ftable>
    800046b6:	ffffc097          	auipc	ra,0xffffc
    800046ba:	5e8080e7          	jalr	1512(ra) # 80000c9e <release>
  return 0;
    800046be:	4481                	li	s1,0
    800046c0:	a819                	j	800046d6 <filealloc+0x5e>
      f->ref = 1;
    800046c2:	4785                	li	a5,1
    800046c4:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800046c6:	00025517          	auipc	a0,0x25
    800046ca:	bca50513          	addi	a0,a0,-1078 # 80029290 <ftable>
    800046ce:	ffffc097          	auipc	ra,0xffffc
    800046d2:	5d0080e7          	jalr	1488(ra) # 80000c9e <release>
}
    800046d6:	8526                	mv	a0,s1
    800046d8:	60e2                	ld	ra,24(sp)
    800046da:	6442                	ld	s0,16(sp)
    800046dc:	64a2                	ld	s1,8(sp)
    800046de:	6105                	addi	sp,sp,32
    800046e0:	8082                	ret

00000000800046e2 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800046e2:	1101                	addi	sp,sp,-32
    800046e4:	ec06                	sd	ra,24(sp)
    800046e6:	e822                	sd	s0,16(sp)
    800046e8:	e426                	sd	s1,8(sp)
    800046ea:	1000                	addi	s0,sp,32
    800046ec:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800046ee:	00025517          	auipc	a0,0x25
    800046f2:	ba250513          	addi	a0,a0,-1118 # 80029290 <ftable>
    800046f6:	ffffc097          	auipc	ra,0xffffc
    800046fa:	4f4080e7          	jalr	1268(ra) # 80000bea <acquire>
  if(f->ref < 1)
    800046fe:	40dc                	lw	a5,4(s1)
    80004700:	02f05263          	blez	a5,80004724 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004704:	2785                	addiw	a5,a5,1
    80004706:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004708:	00025517          	auipc	a0,0x25
    8000470c:	b8850513          	addi	a0,a0,-1144 # 80029290 <ftable>
    80004710:	ffffc097          	auipc	ra,0xffffc
    80004714:	58e080e7          	jalr	1422(ra) # 80000c9e <release>
  return f;
}
    80004718:	8526                	mv	a0,s1
    8000471a:	60e2                	ld	ra,24(sp)
    8000471c:	6442                	ld	s0,16(sp)
    8000471e:	64a2                	ld	s1,8(sp)
    80004720:	6105                	addi	sp,sp,32
    80004722:	8082                	ret
    panic("filedup");
    80004724:	00004517          	auipc	a0,0x4
    80004728:	16c50513          	addi	a0,a0,364 # 80008890 <syscalls+0x2a0>
    8000472c:	ffffc097          	auipc	ra,0xffffc
    80004730:	e18080e7          	jalr	-488(ra) # 80000544 <panic>

0000000080004734 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004734:	7139                	addi	sp,sp,-64
    80004736:	fc06                	sd	ra,56(sp)
    80004738:	f822                	sd	s0,48(sp)
    8000473a:	f426                	sd	s1,40(sp)
    8000473c:	f04a                	sd	s2,32(sp)
    8000473e:	ec4e                	sd	s3,24(sp)
    80004740:	e852                	sd	s4,16(sp)
    80004742:	e456                	sd	s5,8(sp)
    80004744:	0080                	addi	s0,sp,64
    80004746:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004748:	00025517          	auipc	a0,0x25
    8000474c:	b4850513          	addi	a0,a0,-1208 # 80029290 <ftable>
    80004750:	ffffc097          	auipc	ra,0xffffc
    80004754:	49a080e7          	jalr	1178(ra) # 80000bea <acquire>
  if(f->ref < 1)
    80004758:	40dc                	lw	a5,4(s1)
    8000475a:	06f05163          	blez	a5,800047bc <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000475e:	37fd                	addiw	a5,a5,-1
    80004760:	0007871b          	sext.w	a4,a5
    80004764:	c0dc                	sw	a5,4(s1)
    80004766:	06e04363          	bgtz	a4,800047cc <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000476a:	0004a903          	lw	s2,0(s1)
    8000476e:	0094ca83          	lbu	s5,9(s1)
    80004772:	0104ba03          	ld	s4,16(s1)
    80004776:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000477a:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000477e:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004782:	00025517          	auipc	a0,0x25
    80004786:	b0e50513          	addi	a0,a0,-1266 # 80029290 <ftable>
    8000478a:	ffffc097          	auipc	ra,0xffffc
    8000478e:	514080e7          	jalr	1300(ra) # 80000c9e <release>

  if(ff.type == FD_PIPE){
    80004792:	4785                	li	a5,1
    80004794:	04f90d63          	beq	s2,a5,800047ee <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004798:	3979                	addiw	s2,s2,-2
    8000479a:	4785                	li	a5,1
    8000479c:	0527e063          	bltu	a5,s2,800047dc <fileclose+0xa8>
    begin_op();
    800047a0:	00000097          	auipc	ra,0x0
    800047a4:	ac8080e7          	jalr	-1336(ra) # 80004268 <begin_op>
    iput(ff.ip);
    800047a8:	854e                	mv	a0,s3
    800047aa:	fffff097          	auipc	ra,0xfffff
    800047ae:	28e080e7          	jalr	654(ra) # 80003a38 <iput>
    end_op();
    800047b2:	00000097          	auipc	ra,0x0
    800047b6:	b36080e7          	jalr	-1226(ra) # 800042e8 <end_op>
    800047ba:	a00d                	j	800047dc <fileclose+0xa8>
    panic("fileclose");
    800047bc:	00004517          	auipc	a0,0x4
    800047c0:	0dc50513          	addi	a0,a0,220 # 80008898 <syscalls+0x2a8>
    800047c4:	ffffc097          	auipc	ra,0xffffc
    800047c8:	d80080e7          	jalr	-640(ra) # 80000544 <panic>
    release(&ftable.lock);
    800047cc:	00025517          	auipc	a0,0x25
    800047d0:	ac450513          	addi	a0,a0,-1340 # 80029290 <ftable>
    800047d4:	ffffc097          	auipc	ra,0xffffc
    800047d8:	4ca080e7          	jalr	1226(ra) # 80000c9e <release>
  }
}
    800047dc:	70e2                	ld	ra,56(sp)
    800047de:	7442                	ld	s0,48(sp)
    800047e0:	74a2                	ld	s1,40(sp)
    800047e2:	7902                	ld	s2,32(sp)
    800047e4:	69e2                	ld	s3,24(sp)
    800047e6:	6a42                	ld	s4,16(sp)
    800047e8:	6aa2                	ld	s5,8(sp)
    800047ea:	6121                	addi	sp,sp,64
    800047ec:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800047ee:	85d6                	mv	a1,s5
    800047f0:	8552                	mv	a0,s4
    800047f2:	00000097          	auipc	ra,0x0
    800047f6:	35a080e7          	jalr	858(ra) # 80004b4c <pipeclose>
    800047fa:	b7cd                	j	800047dc <fileclose+0xa8>

00000000800047fc <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800047fc:	715d                	addi	sp,sp,-80
    800047fe:	e486                	sd	ra,72(sp)
    80004800:	e0a2                	sd	s0,64(sp)
    80004802:	fc26                	sd	s1,56(sp)
    80004804:	f84a                	sd	s2,48(sp)
    80004806:	f44e                	sd	s3,40(sp)
    80004808:	0880                	addi	s0,sp,80
    8000480a:	84aa                	mv	s1,a0
    8000480c:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000480e:	ffffd097          	auipc	ra,0xffffd
    80004812:	1b8080e7          	jalr	440(ra) # 800019c6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004816:	409c                	lw	a5,0(s1)
    80004818:	37f9                	addiw	a5,a5,-2
    8000481a:	4705                	li	a4,1
    8000481c:	04f76763          	bltu	a4,a5,8000486a <filestat+0x6e>
    80004820:	892a                	mv	s2,a0
    ilock(f->ip);
    80004822:	6c88                	ld	a0,24(s1)
    80004824:	fffff097          	auipc	ra,0xfffff
    80004828:	05a080e7          	jalr	90(ra) # 8000387e <ilock>
    stati(f->ip, &st);
    8000482c:	fb840593          	addi	a1,s0,-72
    80004830:	6c88                	ld	a0,24(s1)
    80004832:	fffff097          	auipc	ra,0xfffff
    80004836:	2d6080e7          	jalr	726(ra) # 80003b08 <stati>
    iunlock(f->ip);
    8000483a:	6c88                	ld	a0,24(s1)
    8000483c:	fffff097          	auipc	ra,0xfffff
    80004840:	104080e7          	jalr	260(ra) # 80003940 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004844:	46e1                	li	a3,24
    80004846:	fb840613          	addi	a2,s0,-72
    8000484a:	85ce                	mv	a1,s3
    8000484c:	05093503          	ld	a0,80(s2)
    80004850:	ffffd097          	auipc	ra,0xffffd
    80004854:	e34080e7          	jalr	-460(ra) # 80001684 <copyout>
    80004858:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000485c:	60a6                	ld	ra,72(sp)
    8000485e:	6406                	ld	s0,64(sp)
    80004860:	74e2                	ld	s1,56(sp)
    80004862:	7942                	ld	s2,48(sp)
    80004864:	79a2                	ld	s3,40(sp)
    80004866:	6161                	addi	sp,sp,80
    80004868:	8082                	ret
  return -1;
    8000486a:	557d                	li	a0,-1
    8000486c:	bfc5                	j	8000485c <filestat+0x60>

000000008000486e <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000486e:	7179                	addi	sp,sp,-48
    80004870:	f406                	sd	ra,40(sp)
    80004872:	f022                	sd	s0,32(sp)
    80004874:	ec26                	sd	s1,24(sp)
    80004876:	e84a                	sd	s2,16(sp)
    80004878:	e44e                	sd	s3,8(sp)
    8000487a:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000487c:	00854783          	lbu	a5,8(a0)
    80004880:	c3d5                	beqz	a5,80004924 <fileread+0xb6>
    80004882:	84aa                	mv	s1,a0
    80004884:	89ae                	mv	s3,a1
    80004886:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004888:	411c                	lw	a5,0(a0)
    8000488a:	4705                	li	a4,1
    8000488c:	04e78963          	beq	a5,a4,800048de <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004890:	470d                	li	a4,3
    80004892:	04e78d63          	beq	a5,a4,800048ec <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004896:	4709                	li	a4,2
    80004898:	06e79e63          	bne	a5,a4,80004914 <fileread+0xa6>
    ilock(f->ip);
    8000489c:	6d08                	ld	a0,24(a0)
    8000489e:	fffff097          	auipc	ra,0xfffff
    800048a2:	fe0080e7          	jalr	-32(ra) # 8000387e <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800048a6:	874a                	mv	a4,s2
    800048a8:	5094                	lw	a3,32(s1)
    800048aa:	864e                	mv	a2,s3
    800048ac:	4585                	li	a1,1
    800048ae:	6c88                	ld	a0,24(s1)
    800048b0:	fffff097          	auipc	ra,0xfffff
    800048b4:	282080e7          	jalr	642(ra) # 80003b32 <readi>
    800048b8:	892a                	mv	s2,a0
    800048ba:	00a05563          	blez	a0,800048c4 <fileread+0x56>
      f->off += r;
    800048be:	509c                	lw	a5,32(s1)
    800048c0:	9fa9                	addw	a5,a5,a0
    800048c2:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800048c4:	6c88                	ld	a0,24(s1)
    800048c6:	fffff097          	auipc	ra,0xfffff
    800048ca:	07a080e7          	jalr	122(ra) # 80003940 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800048ce:	854a                	mv	a0,s2
    800048d0:	70a2                	ld	ra,40(sp)
    800048d2:	7402                	ld	s0,32(sp)
    800048d4:	64e2                	ld	s1,24(sp)
    800048d6:	6942                	ld	s2,16(sp)
    800048d8:	69a2                	ld	s3,8(sp)
    800048da:	6145                	addi	sp,sp,48
    800048dc:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800048de:	6908                	ld	a0,16(a0)
    800048e0:	00000097          	auipc	ra,0x0
    800048e4:	3dc080e7          	jalr	988(ra) # 80004cbc <piperead>
    800048e8:	892a                	mv	s2,a0
    800048ea:	b7d5                	j	800048ce <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800048ec:	02451783          	lh	a5,36(a0)
    800048f0:	03079693          	slli	a3,a5,0x30
    800048f4:	92c1                	srli	a3,a3,0x30
    800048f6:	4725                	li	a4,9
    800048f8:	02d76863          	bltu	a4,a3,80004928 <fileread+0xba>
    800048fc:	0792                	slli	a5,a5,0x4
    800048fe:	00025717          	auipc	a4,0x25
    80004902:	8f270713          	addi	a4,a4,-1806 # 800291f0 <devsw>
    80004906:	97ba                	add	a5,a5,a4
    80004908:	639c                	ld	a5,0(a5)
    8000490a:	c38d                	beqz	a5,8000492c <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000490c:	4505                	li	a0,1
    8000490e:	9782                	jalr	a5
    80004910:	892a                	mv	s2,a0
    80004912:	bf75                	j	800048ce <fileread+0x60>
    panic("fileread");
    80004914:	00004517          	auipc	a0,0x4
    80004918:	f9450513          	addi	a0,a0,-108 # 800088a8 <syscalls+0x2b8>
    8000491c:	ffffc097          	auipc	ra,0xffffc
    80004920:	c28080e7          	jalr	-984(ra) # 80000544 <panic>
    return -1;
    80004924:	597d                	li	s2,-1
    80004926:	b765                	j	800048ce <fileread+0x60>
      return -1;
    80004928:	597d                	li	s2,-1
    8000492a:	b755                	j	800048ce <fileread+0x60>
    8000492c:	597d                	li	s2,-1
    8000492e:	b745                	j	800048ce <fileread+0x60>

0000000080004930 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004930:	715d                	addi	sp,sp,-80
    80004932:	e486                	sd	ra,72(sp)
    80004934:	e0a2                	sd	s0,64(sp)
    80004936:	fc26                	sd	s1,56(sp)
    80004938:	f84a                	sd	s2,48(sp)
    8000493a:	f44e                	sd	s3,40(sp)
    8000493c:	f052                	sd	s4,32(sp)
    8000493e:	ec56                	sd	s5,24(sp)
    80004940:	e85a                	sd	s6,16(sp)
    80004942:	e45e                	sd	s7,8(sp)
    80004944:	e062                	sd	s8,0(sp)
    80004946:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0){
    80004948:	00954783          	lbu	a5,9(a0)
    8000494c:	cb85                	beqz	a5,8000497c <filewrite+0x4c>
    8000494e:	892a                	mv	s2,a0
    80004950:	8aae                	mv	s5,a1
    80004952:	8a32                	mv	s4,a2
    printf("First\n");
    return -1;
  }
  if(f->type == FD_PIPE){
    80004954:	411c                	lw	a5,0(a0)
    80004956:	4705                	li	a4,1
    80004958:	02e78c63          	beq	a5,a4,80004990 <filewrite+0x60>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000495c:	470d                	li	a4,3
    8000495e:	04e78063          	beq	a5,a4,8000499e <filewrite+0x6e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write){
      return -1;
    }
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004962:	4709                	li	a4,2
    80004964:	0ee79b63          	bne	a5,a4,80004a5a <filewrite+0x12a>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004968:	0cc05763          	blez	a2,80004a36 <filewrite+0x106>
    int i = 0;
    8000496c:	4981                	li	s3,0
    8000496e:	6b05                	lui	s6,0x1
    80004970:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004974:	6b85                	lui	s7,0x1
    80004976:	c00b8b9b          	addiw	s7,s7,-1024
    8000497a:	a075                	j	80004a26 <filewrite+0xf6>
    printf("First\n");
    8000497c:	00004517          	auipc	a0,0x4
    80004980:	f3c50513          	addi	a0,a0,-196 # 800088b8 <syscalls+0x2c8>
    80004984:	ffffc097          	auipc	ra,0xffffc
    80004988:	c0a080e7          	jalr	-1014(ra) # 8000058e <printf>
    return -1;
    8000498c:	5a7d                	li	s4,-1
    8000498e:	a07d                	j	80004a3c <filewrite+0x10c>
    ret = pipewrite(f->pipe, addr, n);
    80004990:	6908                	ld	a0,16(a0)
    80004992:	00000097          	auipc	ra,0x0
    80004996:	22a080e7          	jalr	554(ra) # 80004bbc <pipewrite>
    8000499a:	8a2a                	mv	s4,a0
    8000499c:	a045                	j	80004a3c <filewrite+0x10c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write){
    8000499e:	02451783          	lh	a5,36(a0)
    800049a2:	03079693          	slli	a3,a5,0x30
    800049a6:	92c1                	srli	a3,a3,0x30
    800049a8:	4725                	li	a4,9
    800049aa:	0cd76063          	bltu	a4,a3,80004a6a <filewrite+0x13a>
    800049ae:	0792                	slli	a5,a5,0x4
    800049b0:	00025717          	auipc	a4,0x25
    800049b4:	84070713          	addi	a4,a4,-1984 # 800291f0 <devsw>
    800049b8:	97ba                	add	a5,a5,a4
    800049ba:	679c                	ld	a5,8(a5)
    800049bc:	cbcd                	beqz	a5,80004a6e <filewrite+0x13e>
    ret = devsw[f->major].write(1, addr, n);
    800049be:	4505                	li	a0,1
    800049c0:	9782                	jalr	a5
    800049c2:	8a2a                	mv	s4,a0
    800049c4:	a8a5                	j	80004a3c <filewrite+0x10c>
    800049c6:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800049ca:	00000097          	auipc	ra,0x0
    800049ce:	89e080e7          	jalr	-1890(ra) # 80004268 <begin_op>
      ilock(f->ip);
    800049d2:	01893503          	ld	a0,24(s2)
    800049d6:	fffff097          	auipc	ra,0xfffff
    800049da:	ea8080e7          	jalr	-344(ra) # 8000387e <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800049de:	8762                	mv	a4,s8
    800049e0:	02092683          	lw	a3,32(s2)
    800049e4:	01598633          	add	a2,s3,s5
    800049e8:	4585                	li	a1,1
    800049ea:	01893503          	ld	a0,24(s2)
    800049ee:	fffff097          	auipc	ra,0xfffff
    800049f2:	23c080e7          	jalr	572(ra) # 80003c2a <writei>
    800049f6:	84aa                	mv	s1,a0
    800049f8:	00a05763          	blez	a0,80004a06 <filewrite+0xd6>
        f->off += r;
    800049fc:	02092783          	lw	a5,32(s2)
    80004a00:	9fa9                	addw	a5,a5,a0
    80004a02:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004a06:	01893503          	ld	a0,24(s2)
    80004a0a:	fffff097          	auipc	ra,0xfffff
    80004a0e:	f36080e7          	jalr	-202(ra) # 80003940 <iunlock>
      end_op();
    80004a12:	00000097          	auipc	ra,0x0
    80004a16:	8d6080e7          	jalr	-1834(ra) # 800042e8 <end_op>

      if(r != n1){
    80004a1a:	009c1f63          	bne	s8,s1,80004a38 <filewrite+0x108>
        // error from writei
        break;
      }
      i += r;
    80004a1e:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004a22:	0149db63          	bge	s3,s4,80004a38 <filewrite+0x108>
      int n1 = n - i;
    80004a26:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004a2a:	84be                	mv	s1,a5
    80004a2c:	2781                	sext.w	a5,a5
    80004a2e:	f8fb5ce3          	bge	s6,a5,800049c6 <filewrite+0x96>
    80004a32:	84de                	mv	s1,s7
    80004a34:	bf49                	j	800049c6 <filewrite+0x96>
    int i = 0;
    80004a36:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004a38:	013a1f63          	bne	s4,s3,80004a56 <filewrite+0x126>
  } else {
    panic("filewrite");
  }
  return ret;
}
    80004a3c:	8552                	mv	a0,s4
    80004a3e:	60a6                	ld	ra,72(sp)
    80004a40:	6406                	ld	s0,64(sp)
    80004a42:	74e2                	ld	s1,56(sp)
    80004a44:	7942                	ld	s2,48(sp)
    80004a46:	79a2                	ld	s3,40(sp)
    80004a48:	7a02                	ld	s4,32(sp)
    80004a4a:	6ae2                	ld	s5,24(sp)
    80004a4c:	6b42                	ld	s6,16(sp)
    80004a4e:	6ba2                	ld	s7,8(sp)
    80004a50:	6c02                	ld	s8,0(sp)
    80004a52:	6161                	addi	sp,sp,80
    80004a54:	8082                	ret
    ret = (i == n ? n : -1);
    80004a56:	5a7d                	li	s4,-1
    80004a58:	b7d5                	j	80004a3c <filewrite+0x10c>
    panic("filewrite");
    80004a5a:	00004517          	auipc	a0,0x4
    80004a5e:	e6650513          	addi	a0,a0,-410 # 800088c0 <syscalls+0x2d0>
    80004a62:	ffffc097          	auipc	ra,0xffffc
    80004a66:	ae2080e7          	jalr	-1310(ra) # 80000544 <panic>
      return -1;
    80004a6a:	5a7d                	li	s4,-1
    80004a6c:	bfc1                	j	80004a3c <filewrite+0x10c>
    80004a6e:	5a7d                	li	s4,-1
    80004a70:	b7f1                	j	80004a3c <filewrite+0x10c>

0000000080004a72 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004a72:	7179                	addi	sp,sp,-48
    80004a74:	f406                	sd	ra,40(sp)
    80004a76:	f022                	sd	s0,32(sp)
    80004a78:	ec26                	sd	s1,24(sp)
    80004a7a:	e84a                	sd	s2,16(sp)
    80004a7c:	e44e                	sd	s3,8(sp)
    80004a7e:	e052                	sd	s4,0(sp)
    80004a80:	1800                	addi	s0,sp,48
    80004a82:	84aa                	mv	s1,a0
    80004a84:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004a86:	0005b023          	sd	zero,0(a1)
    80004a8a:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004a8e:	00000097          	auipc	ra,0x0
    80004a92:	bea080e7          	jalr	-1046(ra) # 80004678 <filealloc>
    80004a96:	e088                	sd	a0,0(s1)
    80004a98:	c551                	beqz	a0,80004b24 <pipealloc+0xb2>
    80004a9a:	00000097          	auipc	ra,0x0
    80004a9e:	bde080e7          	jalr	-1058(ra) # 80004678 <filealloc>
    80004aa2:	00aa3023          	sd	a0,0(s4)
    80004aa6:	c92d                	beqz	a0,80004b18 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004aa8:	ffffc097          	auipc	ra,0xffffc
    80004aac:	052080e7          	jalr	82(ra) # 80000afa <kalloc>
    80004ab0:	892a                	mv	s2,a0
    80004ab2:	c125                	beqz	a0,80004b12 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004ab4:	4985                	li	s3,1
    80004ab6:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004aba:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004abe:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004ac2:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004ac6:	00004597          	auipc	a1,0x4
    80004aca:	a8258593          	addi	a1,a1,-1406 # 80008548 <states.1784+0x1b8>
    80004ace:	ffffc097          	auipc	ra,0xffffc
    80004ad2:	08c080e7          	jalr	140(ra) # 80000b5a <initlock>
  (*f0)->type = FD_PIPE;
    80004ad6:	609c                	ld	a5,0(s1)
    80004ad8:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004adc:	609c                	ld	a5,0(s1)
    80004ade:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004ae2:	609c                	ld	a5,0(s1)
    80004ae4:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004ae8:	609c                	ld	a5,0(s1)
    80004aea:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004aee:	000a3783          	ld	a5,0(s4)
    80004af2:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004af6:	000a3783          	ld	a5,0(s4)
    80004afa:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004afe:	000a3783          	ld	a5,0(s4)
    80004b02:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004b06:	000a3783          	ld	a5,0(s4)
    80004b0a:	0127b823          	sd	s2,16(a5)
  return 0;
    80004b0e:	4501                	li	a0,0
    80004b10:	a025                	j	80004b38 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004b12:	6088                	ld	a0,0(s1)
    80004b14:	e501                	bnez	a0,80004b1c <pipealloc+0xaa>
    80004b16:	a039                	j	80004b24 <pipealloc+0xb2>
    80004b18:	6088                	ld	a0,0(s1)
    80004b1a:	c51d                	beqz	a0,80004b48 <pipealloc+0xd6>
    fileclose(*f0);
    80004b1c:	00000097          	auipc	ra,0x0
    80004b20:	c18080e7          	jalr	-1000(ra) # 80004734 <fileclose>
  if(*f1)
    80004b24:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004b28:	557d                	li	a0,-1
  if(*f1)
    80004b2a:	c799                	beqz	a5,80004b38 <pipealloc+0xc6>
    fileclose(*f1);
    80004b2c:	853e                	mv	a0,a5
    80004b2e:	00000097          	auipc	ra,0x0
    80004b32:	c06080e7          	jalr	-1018(ra) # 80004734 <fileclose>
  return -1;
    80004b36:	557d                	li	a0,-1
}
    80004b38:	70a2                	ld	ra,40(sp)
    80004b3a:	7402                	ld	s0,32(sp)
    80004b3c:	64e2                	ld	s1,24(sp)
    80004b3e:	6942                	ld	s2,16(sp)
    80004b40:	69a2                	ld	s3,8(sp)
    80004b42:	6a02                	ld	s4,0(sp)
    80004b44:	6145                	addi	sp,sp,48
    80004b46:	8082                	ret
  return -1;
    80004b48:	557d                	li	a0,-1
    80004b4a:	b7fd                	j	80004b38 <pipealloc+0xc6>

0000000080004b4c <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004b4c:	1101                	addi	sp,sp,-32
    80004b4e:	ec06                	sd	ra,24(sp)
    80004b50:	e822                	sd	s0,16(sp)
    80004b52:	e426                	sd	s1,8(sp)
    80004b54:	e04a                	sd	s2,0(sp)
    80004b56:	1000                	addi	s0,sp,32
    80004b58:	84aa                	mv	s1,a0
    80004b5a:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004b5c:	ffffc097          	auipc	ra,0xffffc
    80004b60:	08e080e7          	jalr	142(ra) # 80000bea <acquire>
  if(writable){
    80004b64:	02090d63          	beqz	s2,80004b9e <pipeclose+0x52>
    pi->writeopen = 0;
    80004b68:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004b6c:	21848513          	addi	a0,s1,536
    80004b70:	ffffd097          	auipc	ra,0xffffd
    80004b74:	5fe080e7          	jalr	1534(ra) # 8000216e <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004b78:	2204b783          	ld	a5,544(s1)
    80004b7c:	eb95                	bnez	a5,80004bb0 <pipeclose+0x64>
    release(&pi->lock);
    80004b7e:	8526                	mv	a0,s1
    80004b80:	ffffc097          	auipc	ra,0xffffc
    80004b84:	11e080e7          	jalr	286(ra) # 80000c9e <release>
    kfree((char*)pi);
    80004b88:	8526                	mv	a0,s1
    80004b8a:	ffffc097          	auipc	ra,0xffffc
    80004b8e:	e74080e7          	jalr	-396(ra) # 800009fe <kfree>
  } else
    release(&pi->lock);
}
    80004b92:	60e2                	ld	ra,24(sp)
    80004b94:	6442                	ld	s0,16(sp)
    80004b96:	64a2                	ld	s1,8(sp)
    80004b98:	6902                	ld	s2,0(sp)
    80004b9a:	6105                	addi	sp,sp,32
    80004b9c:	8082                	ret
    pi->readopen = 0;
    80004b9e:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004ba2:	21c48513          	addi	a0,s1,540
    80004ba6:	ffffd097          	auipc	ra,0xffffd
    80004baa:	5c8080e7          	jalr	1480(ra) # 8000216e <wakeup>
    80004bae:	b7e9                	j	80004b78 <pipeclose+0x2c>
    release(&pi->lock);
    80004bb0:	8526                	mv	a0,s1
    80004bb2:	ffffc097          	auipc	ra,0xffffc
    80004bb6:	0ec080e7          	jalr	236(ra) # 80000c9e <release>
}
    80004bba:	bfe1                	j	80004b92 <pipeclose+0x46>

0000000080004bbc <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004bbc:	7159                	addi	sp,sp,-112
    80004bbe:	f486                	sd	ra,104(sp)
    80004bc0:	f0a2                	sd	s0,96(sp)
    80004bc2:	eca6                	sd	s1,88(sp)
    80004bc4:	e8ca                	sd	s2,80(sp)
    80004bc6:	e4ce                	sd	s3,72(sp)
    80004bc8:	e0d2                	sd	s4,64(sp)
    80004bca:	fc56                	sd	s5,56(sp)
    80004bcc:	f85a                	sd	s6,48(sp)
    80004bce:	f45e                	sd	s7,40(sp)
    80004bd0:	f062                	sd	s8,32(sp)
    80004bd2:	ec66                	sd	s9,24(sp)
    80004bd4:	1880                	addi	s0,sp,112
    80004bd6:	84aa                	mv	s1,a0
    80004bd8:	8aae                	mv	s5,a1
    80004bda:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004bdc:	ffffd097          	auipc	ra,0xffffd
    80004be0:	dea080e7          	jalr	-534(ra) # 800019c6 <myproc>
    80004be4:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004be6:	8526                	mv	a0,s1
    80004be8:	ffffc097          	auipc	ra,0xffffc
    80004bec:	002080e7          	jalr	2(ra) # 80000bea <acquire>
  while(i < n){
    80004bf0:	0d405463          	blez	s4,80004cb8 <pipewrite+0xfc>
    80004bf4:	8ba6                	mv	s7,s1
  int i = 0;
    80004bf6:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004bf8:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004bfa:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004bfe:	21c48c13          	addi	s8,s1,540
    80004c02:	a08d                	j	80004c64 <pipewrite+0xa8>
      release(&pi->lock);
    80004c04:	8526                	mv	a0,s1
    80004c06:	ffffc097          	auipc	ra,0xffffc
    80004c0a:	098080e7          	jalr	152(ra) # 80000c9e <release>
      return -1;
    80004c0e:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004c10:	854a                	mv	a0,s2
    80004c12:	70a6                	ld	ra,104(sp)
    80004c14:	7406                	ld	s0,96(sp)
    80004c16:	64e6                	ld	s1,88(sp)
    80004c18:	6946                	ld	s2,80(sp)
    80004c1a:	69a6                	ld	s3,72(sp)
    80004c1c:	6a06                	ld	s4,64(sp)
    80004c1e:	7ae2                	ld	s5,56(sp)
    80004c20:	7b42                	ld	s6,48(sp)
    80004c22:	7ba2                	ld	s7,40(sp)
    80004c24:	7c02                	ld	s8,32(sp)
    80004c26:	6ce2                	ld	s9,24(sp)
    80004c28:	6165                	addi	sp,sp,112
    80004c2a:	8082                	ret
      wakeup(&pi->nread);
    80004c2c:	8566                	mv	a0,s9
    80004c2e:	ffffd097          	auipc	ra,0xffffd
    80004c32:	540080e7          	jalr	1344(ra) # 8000216e <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004c36:	85de                	mv	a1,s7
    80004c38:	8562                	mv	a0,s8
    80004c3a:	ffffd097          	auipc	ra,0xffffd
    80004c3e:	4d0080e7          	jalr	1232(ra) # 8000210a <sleep>
    80004c42:	a839                	j	80004c60 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004c44:	21c4a783          	lw	a5,540(s1)
    80004c48:	0017871b          	addiw	a4,a5,1
    80004c4c:	20e4ae23          	sw	a4,540(s1)
    80004c50:	1ff7f793          	andi	a5,a5,511
    80004c54:	97a6                	add	a5,a5,s1
    80004c56:	f9f44703          	lbu	a4,-97(s0)
    80004c5a:	00e78c23          	sb	a4,24(a5)
      i++;
    80004c5e:	2905                	addiw	s2,s2,1
  while(i < n){
    80004c60:	05495063          	bge	s2,s4,80004ca0 <pipewrite+0xe4>
    if(pi->readopen == 0 || killed(pr)){
    80004c64:	2204a783          	lw	a5,544(s1)
    80004c68:	dfd1                	beqz	a5,80004c04 <pipewrite+0x48>
    80004c6a:	854e                	mv	a0,s3
    80004c6c:	ffffd097          	auipc	ra,0xffffd
    80004c70:	746080e7          	jalr	1862(ra) # 800023b2 <killed>
    80004c74:	f941                	bnez	a0,80004c04 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004c76:	2184a783          	lw	a5,536(s1)
    80004c7a:	21c4a703          	lw	a4,540(s1)
    80004c7e:	2007879b          	addiw	a5,a5,512
    80004c82:	faf705e3          	beq	a4,a5,80004c2c <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c86:	4685                	li	a3,1
    80004c88:	01590633          	add	a2,s2,s5
    80004c8c:	f9f40593          	addi	a1,s0,-97
    80004c90:	0509b503          	ld	a0,80(s3)
    80004c94:	ffffd097          	auipc	ra,0xffffd
    80004c98:	a7c080e7          	jalr	-1412(ra) # 80001710 <copyin>
    80004c9c:	fb6514e3          	bne	a0,s6,80004c44 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004ca0:	21848513          	addi	a0,s1,536
    80004ca4:	ffffd097          	auipc	ra,0xffffd
    80004ca8:	4ca080e7          	jalr	1226(ra) # 8000216e <wakeup>
  release(&pi->lock);
    80004cac:	8526                	mv	a0,s1
    80004cae:	ffffc097          	auipc	ra,0xffffc
    80004cb2:	ff0080e7          	jalr	-16(ra) # 80000c9e <release>
  return i;
    80004cb6:	bfa9                	j	80004c10 <pipewrite+0x54>
  int i = 0;
    80004cb8:	4901                	li	s2,0
    80004cba:	b7dd                	j	80004ca0 <pipewrite+0xe4>

0000000080004cbc <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004cbc:	715d                	addi	sp,sp,-80
    80004cbe:	e486                	sd	ra,72(sp)
    80004cc0:	e0a2                	sd	s0,64(sp)
    80004cc2:	fc26                	sd	s1,56(sp)
    80004cc4:	f84a                	sd	s2,48(sp)
    80004cc6:	f44e                	sd	s3,40(sp)
    80004cc8:	f052                	sd	s4,32(sp)
    80004cca:	ec56                	sd	s5,24(sp)
    80004ccc:	e85a                	sd	s6,16(sp)
    80004cce:	0880                	addi	s0,sp,80
    80004cd0:	84aa                	mv	s1,a0
    80004cd2:	892e                	mv	s2,a1
    80004cd4:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004cd6:	ffffd097          	auipc	ra,0xffffd
    80004cda:	cf0080e7          	jalr	-784(ra) # 800019c6 <myproc>
    80004cde:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004ce0:	8b26                	mv	s6,s1
    80004ce2:	8526                	mv	a0,s1
    80004ce4:	ffffc097          	auipc	ra,0xffffc
    80004ce8:	f06080e7          	jalr	-250(ra) # 80000bea <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cec:	2184a703          	lw	a4,536(s1)
    80004cf0:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004cf4:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cf8:	02f71763          	bne	a4,a5,80004d26 <piperead+0x6a>
    80004cfc:	2244a783          	lw	a5,548(s1)
    80004d00:	c39d                	beqz	a5,80004d26 <piperead+0x6a>
    if(killed(pr)){
    80004d02:	8552                	mv	a0,s4
    80004d04:	ffffd097          	auipc	ra,0xffffd
    80004d08:	6ae080e7          	jalr	1710(ra) # 800023b2 <killed>
    80004d0c:	e941                	bnez	a0,80004d9c <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d0e:	85da                	mv	a1,s6
    80004d10:	854e                	mv	a0,s3
    80004d12:	ffffd097          	auipc	ra,0xffffd
    80004d16:	3f8080e7          	jalr	1016(ra) # 8000210a <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d1a:	2184a703          	lw	a4,536(s1)
    80004d1e:	21c4a783          	lw	a5,540(s1)
    80004d22:	fcf70de3          	beq	a4,a5,80004cfc <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d26:	09505263          	blez	s5,80004daa <piperead+0xee>
    80004d2a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d2c:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004d2e:	2184a783          	lw	a5,536(s1)
    80004d32:	21c4a703          	lw	a4,540(s1)
    80004d36:	02f70d63          	beq	a4,a5,80004d70 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004d3a:	0017871b          	addiw	a4,a5,1
    80004d3e:	20e4ac23          	sw	a4,536(s1)
    80004d42:	1ff7f793          	andi	a5,a5,511
    80004d46:	97a6                	add	a5,a5,s1
    80004d48:	0187c783          	lbu	a5,24(a5)
    80004d4c:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d50:	4685                	li	a3,1
    80004d52:	fbf40613          	addi	a2,s0,-65
    80004d56:	85ca                	mv	a1,s2
    80004d58:	050a3503          	ld	a0,80(s4)
    80004d5c:	ffffd097          	auipc	ra,0xffffd
    80004d60:	928080e7          	jalr	-1752(ra) # 80001684 <copyout>
    80004d64:	01650663          	beq	a0,s6,80004d70 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d68:	2985                	addiw	s3,s3,1
    80004d6a:	0905                	addi	s2,s2,1
    80004d6c:	fd3a91e3          	bne	s5,s3,80004d2e <piperead+0x72>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004d70:	21c48513          	addi	a0,s1,540
    80004d74:	ffffd097          	auipc	ra,0xffffd
    80004d78:	3fa080e7          	jalr	1018(ra) # 8000216e <wakeup>
  release(&pi->lock);
    80004d7c:	8526                	mv	a0,s1
    80004d7e:	ffffc097          	auipc	ra,0xffffc
    80004d82:	f20080e7          	jalr	-224(ra) # 80000c9e <release>
  return i;
}
    80004d86:	854e                	mv	a0,s3
    80004d88:	60a6                	ld	ra,72(sp)
    80004d8a:	6406                	ld	s0,64(sp)
    80004d8c:	74e2                	ld	s1,56(sp)
    80004d8e:	7942                	ld	s2,48(sp)
    80004d90:	79a2                	ld	s3,40(sp)
    80004d92:	7a02                	ld	s4,32(sp)
    80004d94:	6ae2                	ld	s5,24(sp)
    80004d96:	6b42                	ld	s6,16(sp)
    80004d98:	6161                	addi	sp,sp,80
    80004d9a:	8082                	ret
      release(&pi->lock);
    80004d9c:	8526                	mv	a0,s1
    80004d9e:	ffffc097          	auipc	ra,0xffffc
    80004da2:	f00080e7          	jalr	-256(ra) # 80000c9e <release>
      return -1;
    80004da6:	59fd                	li	s3,-1
    80004da8:	bff9                	j	80004d86 <piperead+0xca>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004daa:	4981                	li	s3,0
    80004dac:	b7d1                	j	80004d70 <piperead+0xb4>

0000000080004dae <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004dae:	1141                	addi	sp,sp,-16
    80004db0:	e422                	sd	s0,8(sp)
    80004db2:	0800                	addi	s0,sp,16
    80004db4:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004db6:	8905                	andi	a0,a0,1
    80004db8:	c111                	beqz	a0,80004dbc <flags2perm+0xe>
      perm = PTE_X;
    80004dba:	4521                	li	a0,8
    if(flags & 0x2)
    80004dbc:	8b89                	andi	a5,a5,2
    80004dbe:	c399                	beqz	a5,80004dc4 <flags2perm+0x16>
      perm |= PTE_W;
    80004dc0:	00456513          	ori	a0,a0,4
    return perm;
}
    80004dc4:	6422                	ld	s0,8(sp)
    80004dc6:	0141                	addi	sp,sp,16
    80004dc8:	8082                	ret

0000000080004dca <exec>:

int
exec(char *path, char **argv)
{
    80004dca:	df010113          	addi	sp,sp,-528
    80004dce:	20113423          	sd	ra,520(sp)
    80004dd2:	20813023          	sd	s0,512(sp)
    80004dd6:	ffa6                	sd	s1,504(sp)
    80004dd8:	fbca                	sd	s2,496(sp)
    80004dda:	f7ce                	sd	s3,488(sp)
    80004ddc:	f3d2                	sd	s4,480(sp)
    80004dde:	efd6                	sd	s5,472(sp)
    80004de0:	ebda                	sd	s6,464(sp)
    80004de2:	e7de                	sd	s7,456(sp)
    80004de4:	e3e2                	sd	s8,448(sp)
    80004de6:	ff66                	sd	s9,440(sp)
    80004de8:	fb6a                	sd	s10,432(sp)
    80004dea:	f76e                	sd	s11,424(sp)
    80004dec:	0c00                	addi	s0,sp,528
    80004dee:	84aa                	mv	s1,a0
    80004df0:	dea43c23          	sd	a0,-520(s0)
    80004df4:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004df8:	ffffd097          	auipc	ra,0xffffd
    80004dfc:	bce080e7          	jalr	-1074(ra) # 800019c6 <myproc>
    80004e00:	892a                	mv	s2,a0

  begin_op();
    80004e02:	fffff097          	auipc	ra,0xfffff
    80004e06:	466080e7          	jalr	1126(ra) # 80004268 <begin_op>

  if((ip = namei(path)) == 0){
    80004e0a:	8526                	mv	a0,s1
    80004e0c:	fffff097          	auipc	ra,0xfffff
    80004e10:	240080e7          	jalr	576(ra) # 8000404c <namei>
    80004e14:	c92d                	beqz	a0,80004e86 <exec+0xbc>
    80004e16:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004e18:	fffff097          	auipc	ra,0xfffff
    80004e1c:	a66080e7          	jalr	-1434(ra) # 8000387e <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004e20:	04000713          	li	a4,64
    80004e24:	4681                	li	a3,0
    80004e26:	e5040613          	addi	a2,s0,-432
    80004e2a:	4581                	li	a1,0
    80004e2c:	8526                	mv	a0,s1
    80004e2e:	fffff097          	auipc	ra,0xfffff
    80004e32:	d04080e7          	jalr	-764(ra) # 80003b32 <readi>
    80004e36:	04000793          	li	a5,64
    80004e3a:	00f51a63          	bne	a0,a5,80004e4e <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004e3e:	e5042703          	lw	a4,-432(s0)
    80004e42:	464c47b7          	lui	a5,0x464c4
    80004e46:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004e4a:	04f70463          	beq	a4,a5,80004e92 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004e4e:	8526                	mv	a0,s1
    80004e50:	fffff097          	auipc	ra,0xfffff
    80004e54:	c90080e7          	jalr	-880(ra) # 80003ae0 <iunlockput>
    end_op();
    80004e58:	fffff097          	auipc	ra,0xfffff
    80004e5c:	490080e7          	jalr	1168(ra) # 800042e8 <end_op>
  }
  return -1;
    80004e60:	557d                	li	a0,-1
}
    80004e62:	20813083          	ld	ra,520(sp)
    80004e66:	20013403          	ld	s0,512(sp)
    80004e6a:	74fe                	ld	s1,504(sp)
    80004e6c:	795e                	ld	s2,496(sp)
    80004e6e:	79be                	ld	s3,488(sp)
    80004e70:	7a1e                	ld	s4,480(sp)
    80004e72:	6afe                	ld	s5,472(sp)
    80004e74:	6b5e                	ld	s6,464(sp)
    80004e76:	6bbe                	ld	s7,456(sp)
    80004e78:	6c1e                	ld	s8,448(sp)
    80004e7a:	7cfa                	ld	s9,440(sp)
    80004e7c:	7d5a                	ld	s10,432(sp)
    80004e7e:	7dba                	ld	s11,424(sp)
    80004e80:	21010113          	addi	sp,sp,528
    80004e84:	8082                	ret
    end_op();
    80004e86:	fffff097          	auipc	ra,0xfffff
    80004e8a:	462080e7          	jalr	1122(ra) # 800042e8 <end_op>
    return -1;
    80004e8e:	557d                	li	a0,-1
    80004e90:	bfc9                	j	80004e62 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004e92:	854a                	mv	a0,s2
    80004e94:	ffffd097          	auipc	ra,0xffffd
    80004e98:	bf6080e7          	jalr	-1034(ra) # 80001a8a <proc_pagetable>
    80004e9c:	8baa                	mv	s7,a0
    80004e9e:	d945                	beqz	a0,80004e4e <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ea0:	e7042983          	lw	s3,-400(s0)
    80004ea4:	e8845783          	lhu	a5,-376(s0)
    80004ea8:	c7ad                	beqz	a5,80004f12 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004eaa:	4a01                	li	s4,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004eac:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004eae:	6c85                	lui	s9,0x1
    80004eb0:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004eb4:	def43823          	sd	a5,-528(s0)
    80004eb8:	ac0d                	j	800050ea <exec+0x320>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004eba:	00004517          	auipc	a0,0x4
    80004ebe:	a1650513          	addi	a0,a0,-1514 # 800088d0 <syscalls+0x2e0>
    80004ec2:	ffffb097          	auipc	ra,0xffffb
    80004ec6:	682080e7          	jalr	1666(ra) # 80000544 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004eca:	8756                	mv	a4,s5
    80004ecc:	012d86bb          	addw	a3,s11,s2
    80004ed0:	4581                	li	a1,0
    80004ed2:	8526                	mv	a0,s1
    80004ed4:	fffff097          	auipc	ra,0xfffff
    80004ed8:	c5e080e7          	jalr	-930(ra) # 80003b32 <readi>
    80004edc:	2501                	sext.w	a0,a0
    80004ede:	1aaa9a63          	bne	s5,a0,80005092 <exec+0x2c8>
  for(i = 0; i < sz; i += PGSIZE){
    80004ee2:	6785                	lui	a5,0x1
    80004ee4:	0127893b          	addw	s2,a5,s2
    80004ee8:	77fd                	lui	a5,0xfffff
    80004eea:	01478a3b          	addw	s4,a5,s4
    80004eee:	1f897563          	bgeu	s2,s8,800050d8 <exec+0x30e>
    pa = walkaddr(pagetable, va + i);
    80004ef2:	02091593          	slli	a1,s2,0x20
    80004ef6:	9181                	srli	a1,a1,0x20
    80004ef8:	95ea                	add	a1,a1,s10
    80004efa:	855e                	mv	a0,s7
    80004efc:	ffffc097          	auipc	ra,0xffffc
    80004f00:	17c080e7          	jalr	380(ra) # 80001078 <walkaddr>
    80004f04:	862a                	mv	a2,a0
    if(pa == 0)
    80004f06:	d955                	beqz	a0,80004eba <exec+0xf0>
      n = PGSIZE;
    80004f08:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004f0a:	fd9a70e3          	bgeu	s4,s9,80004eca <exec+0x100>
      n = sz - i;
    80004f0e:	8ad2                	mv	s5,s4
    80004f10:	bf6d                	j	80004eca <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004f12:	4a01                	li	s4,0
  iunlockput(ip);
    80004f14:	8526                	mv	a0,s1
    80004f16:	fffff097          	auipc	ra,0xfffff
    80004f1a:	bca080e7          	jalr	-1078(ra) # 80003ae0 <iunlockput>
  end_op();
    80004f1e:	fffff097          	auipc	ra,0xfffff
    80004f22:	3ca080e7          	jalr	970(ra) # 800042e8 <end_op>
  p = myproc();
    80004f26:	ffffd097          	auipc	ra,0xffffd
    80004f2a:	aa0080e7          	jalr	-1376(ra) # 800019c6 <myproc>
    80004f2e:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004f30:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004f34:	6785                	lui	a5,0x1
    80004f36:	17fd                	addi	a5,a5,-1
    80004f38:	9a3e                	add	s4,s4,a5
    80004f3a:	757d                	lui	a0,0xfffff
    80004f3c:	00aa77b3          	and	a5,s4,a0
    80004f40:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004f44:	4691                	li	a3,4
    80004f46:	6609                	lui	a2,0x2
    80004f48:	963e                	add	a2,a2,a5
    80004f4a:	85be                	mv	a1,a5
    80004f4c:	855e                	mv	a0,s7
    80004f4e:	ffffc097          	auipc	ra,0xffffc
    80004f52:	4de080e7          	jalr	1246(ra) # 8000142c <uvmalloc>
    80004f56:	8b2a                	mv	s6,a0
  ip = 0;
    80004f58:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004f5a:	12050c63          	beqz	a0,80005092 <exec+0x2c8>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004f5e:	75f9                	lui	a1,0xffffe
    80004f60:	95aa                	add	a1,a1,a0
    80004f62:	855e                	mv	a0,s7
    80004f64:	ffffc097          	auipc	ra,0xffffc
    80004f68:	6ee080e7          	jalr	1774(ra) # 80001652 <uvmclear>
  stackbase = sp - PGSIZE;
    80004f6c:	7c7d                	lui	s8,0xfffff
    80004f6e:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004f70:	e0043783          	ld	a5,-512(s0)
    80004f74:	6388                	ld	a0,0(a5)
    80004f76:	c535                	beqz	a0,80004fe2 <exec+0x218>
    80004f78:	e9040993          	addi	s3,s0,-368
    80004f7c:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004f80:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004f82:	ffffc097          	auipc	ra,0xffffc
    80004f86:	ee8080e7          	jalr	-280(ra) # 80000e6a <strlen>
    80004f8a:	2505                	addiw	a0,a0,1
    80004f8c:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004f90:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004f94:	13896663          	bltu	s2,s8,800050c0 <exec+0x2f6>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004f98:	e0043d83          	ld	s11,-512(s0)
    80004f9c:	000dba03          	ld	s4,0(s11)
    80004fa0:	8552                	mv	a0,s4
    80004fa2:	ffffc097          	auipc	ra,0xffffc
    80004fa6:	ec8080e7          	jalr	-312(ra) # 80000e6a <strlen>
    80004faa:	0015069b          	addiw	a3,a0,1
    80004fae:	8652                	mv	a2,s4
    80004fb0:	85ca                	mv	a1,s2
    80004fb2:	855e                	mv	a0,s7
    80004fb4:	ffffc097          	auipc	ra,0xffffc
    80004fb8:	6d0080e7          	jalr	1744(ra) # 80001684 <copyout>
    80004fbc:	10054663          	bltz	a0,800050c8 <exec+0x2fe>
    ustack[argc] = sp;
    80004fc0:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004fc4:	0485                	addi	s1,s1,1
    80004fc6:	008d8793          	addi	a5,s11,8
    80004fca:	e0f43023          	sd	a5,-512(s0)
    80004fce:	008db503          	ld	a0,8(s11)
    80004fd2:	c911                	beqz	a0,80004fe6 <exec+0x21c>
    if(argc >= MAXARG)
    80004fd4:	09a1                	addi	s3,s3,8
    80004fd6:	fb3c96e3          	bne	s9,s3,80004f82 <exec+0x1b8>
  sz = sz1;
    80004fda:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fde:	4481                	li	s1,0
    80004fe0:	a84d                	j	80005092 <exec+0x2c8>
  sp = sz;
    80004fe2:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004fe4:	4481                	li	s1,0
  ustack[argc] = 0;
    80004fe6:	00349793          	slli	a5,s1,0x3
    80004fea:	f9040713          	addi	a4,s0,-112
    80004fee:	97ba                	add	a5,a5,a4
    80004ff0:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004ff4:	00148693          	addi	a3,s1,1
    80004ff8:	068e                	slli	a3,a3,0x3
    80004ffa:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004ffe:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005002:	01897663          	bgeu	s2,s8,8000500e <exec+0x244>
  sz = sz1;
    80005006:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000500a:	4481                	li	s1,0
    8000500c:	a059                	j	80005092 <exec+0x2c8>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000500e:	e9040613          	addi	a2,s0,-368
    80005012:	85ca                	mv	a1,s2
    80005014:	855e                	mv	a0,s7
    80005016:	ffffc097          	auipc	ra,0xffffc
    8000501a:	66e080e7          	jalr	1646(ra) # 80001684 <copyout>
    8000501e:	0a054963          	bltz	a0,800050d0 <exec+0x306>
  p->trapframe->a1 = sp;
    80005022:	058ab783          	ld	a5,88(s5)
    80005026:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000502a:	df843783          	ld	a5,-520(s0)
    8000502e:	0007c703          	lbu	a4,0(a5)
    80005032:	cf11                	beqz	a4,8000504e <exec+0x284>
    80005034:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005036:	02f00693          	li	a3,47
    8000503a:	a039                	j	80005048 <exec+0x27e>
      last = s+1;
    8000503c:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005040:	0785                	addi	a5,a5,1
    80005042:	fff7c703          	lbu	a4,-1(a5)
    80005046:	c701                	beqz	a4,8000504e <exec+0x284>
    if(*s == '/')
    80005048:	fed71ce3          	bne	a4,a3,80005040 <exec+0x276>
    8000504c:	bfc5                	j	8000503c <exec+0x272>
  safestrcpy(p->name, last, sizeof(p->name));
    8000504e:	4641                	li	a2,16
    80005050:	df843583          	ld	a1,-520(s0)
    80005054:	158a8513          	addi	a0,s5,344
    80005058:	ffffc097          	auipc	ra,0xffffc
    8000505c:	de0080e7          	jalr	-544(ra) # 80000e38 <safestrcpy>
  oldpagetable = p->pagetable;
    80005060:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005064:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80005068:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000506c:	058ab783          	ld	a5,88(s5)
    80005070:	e6843703          	ld	a4,-408(s0)
    80005074:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005076:	058ab783          	ld	a5,88(s5)
    8000507a:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000507e:	85ea                	mv	a1,s10
    80005080:	ffffd097          	auipc	ra,0xffffd
    80005084:	aa6080e7          	jalr	-1370(ra) # 80001b26 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005088:	0004851b          	sext.w	a0,s1
    8000508c:	bbd9                	j	80004e62 <exec+0x98>
    8000508e:	e1443423          	sd	s4,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005092:	e0843583          	ld	a1,-504(s0)
    80005096:	855e                	mv	a0,s7
    80005098:	ffffd097          	auipc	ra,0xffffd
    8000509c:	a8e080e7          	jalr	-1394(ra) # 80001b26 <proc_freepagetable>
  if(ip){
    800050a0:	da0497e3          	bnez	s1,80004e4e <exec+0x84>
  return -1;
    800050a4:	557d                	li	a0,-1
    800050a6:	bb75                	j	80004e62 <exec+0x98>
    800050a8:	e1443423          	sd	s4,-504(s0)
    800050ac:	b7dd                	j	80005092 <exec+0x2c8>
    800050ae:	e1443423          	sd	s4,-504(s0)
    800050b2:	b7c5                	j	80005092 <exec+0x2c8>
    800050b4:	e1443423          	sd	s4,-504(s0)
    800050b8:	bfe9                	j	80005092 <exec+0x2c8>
    800050ba:	e1443423          	sd	s4,-504(s0)
    800050be:	bfd1                	j	80005092 <exec+0x2c8>
  sz = sz1;
    800050c0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050c4:	4481                	li	s1,0
    800050c6:	b7f1                	j	80005092 <exec+0x2c8>
  sz = sz1;
    800050c8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050cc:	4481                	li	s1,0
    800050ce:	b7d1                	j	80005092 <exec+0x2c8>
  sz = sz1;
    800050d0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800050d4:	4481                	li	s1,0
    800050d6:	bf75                	j	80005092 <exec+0x2c8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800050d8:	e0843a03          	ld	s4,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050dc:	2b05                	addiw	s6,s6,1
    800050de:	0389899b          	addiw	s3,s3,56
    800050e2:	e8845783          	lhu	a5,-376(s0)
    800050e6:	e2fb57e3          	bge	s6,a5,80004f14 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800050ea:	2981                	sext.w	s3,s3
    800050ec:	03800713          	li	a4,56
    800050f0:	86ce                	mv	a3,s3
    800050f2:	e1840613          	addi	a2,s0,-488
    800050f6:	4581                	li	a1,0
    800050f8:	8526                	mv	a0,s1
    800050fa:	fffff097          	auipc	ra,0xfffff
    800050fe:	a38080e7          	jalr	-1480(ra) # 80003b32 <readi>
    80005102:	03800793          	li	a5,56
    80005106:	f8f514e3          	bne	a0,a5,8000508e <exec+0x2c4>
    if(ph.type != ELF_PROG_LOAD)
    8000510a:	e1842783          	lw	a5,-488(s0)
    8000510e:	4705                	li	a4,1
    80005110:	fce796e3          	bne	a5,a4,800050dc <exec+0x312>
    if(ph.memsz < ph.filesz)
    80005114:	e4043903          	ld	s2,-448(s0)
    80005118:	e3843783          	ld	a5,-456(s0)
    8000511c:	f8f966e3          	bltu	s2,a5,800050a8 <exec+0x2de>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005120:	e2843783          	ld	a5,-472(s0)
    80005124:	993e                	add	s2,s2,a5
    80005126:	f8f964e3          	bltu	s2,a5,800050ae <exec+0x2e4>
    if(ph.vaddr % PGSIZE != 0)
    8000512a:	df043703          	ld	a4,-528(s0)
    8000512e:	8ff9                	and	a5,a5,a4
    80005130:	f3d1                	bnez	a5,800050b4 <exec+0x2ea>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005132:	e1c42503          	lw	a0,-484(s0)
    80005136:	00000097          	auipc	ra,0x0
    8000513a:	c78080e7          	jalr	-904(ra) # 80004dae <flags2perm>
    8000513e:	86aa                	mv	a3,a0
    80005140:	864a                	mv	a2,s2
    80005142:	85d2                	mv	a1,s4
    80005144:	855e                	mv	a0,s7
    80005146:	ffffc097          	auipc	ra,0xffffc
    8000514a:	2e6080e7          	jalr	742(ra) # 8000142c <uvmalloc>
    8000514e:	e0a43423          	sd	a0,-504(s0)
    80005152:	d525                	beqz	a0,800050ba <exec+0x2f0>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005154:	e2843d03          	ld	s10,-472(s0)
    80005158:	e2042d83          	lw	s11,-480(s0)
    8000515c:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005160:	f60c0ce3          	beqz	s8,800050d8 <exec+0x30e>
    80005164:	8a62                	mv	s4,s8
    80005166:	4901                	li	s2,0
    80005168:	b369                	j	80004ef2 <exec+0x128>

000000008000516a <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000516a:	7179                	addi	sp,sp,-48
    8000516c:	f406                	sd	ra,40(sp)
    8000516e:	f022                	sd	s0,32(sp)
    80005170:	ec26                	sd	s1,24(sp)
    80005172:	e84a                	sd	s2,16(sp)
    80005174:	1800                	addi	s0,sp,48
    80005176:	892e                	mv	s2,a1
    80005178:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    8000517a:	fdc40593          	addi	a1,s0,-36
    8000517e:	ffffe097          	auipc	ra,0xffffe
    80005182:	a64080e7          	jalr	-1436(ra) # 80002be2 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005186:	fdc42703          	lw	a4,-36(s0)
    8000518a:	47bd                	li	a5,15
    8000518c:	02e7eb63          	bltu	a5,a4,800051c2 <argfd+0x58>
    80005190:	ffffd097          	auipc	ra,0xffffd
    80005194:	836080e7          	jalr	-1994(ra) # 800019c6 <myproc>
    80005198:	fdc42703          	lw	a4,-36(s0)
    8000519c:	01a70793          	addi	a5,a4,26
    800051a0:	078e                	slli	a5,a5,0x3
    800051a2:	953e                	add	a0,a0,a5
    800051a4:	611c                	ld	a5,0(a0)
    800051a6:	c385                	beqz	a5,800051c6 <argfd+0x5c>
    return -1;
  if(pfd)
    800051a8:	00090463          	beqz	s2,800051b0 <argfd+0x46>
    *pfd = fd;
    800051ac:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800051b0:	4501                	li	a0,0
  if(pf)
    800051b2:	c091                	beqz	s1,800051b6 <argfd+0x4c>
    *pf = f;
    800051b4:	e09c                	sd	a5,0(s1)
}
    800051b6:	70a2                	ld	ra,40(sp)
    800051b8:	7402                	ld	s0,32(sp)
    800051ba:	64e2                	ld	s1,24(sp)
    800051bc:	6942                	ld	s2,16(sp)
    800051be:	6145                	addi	sp,sp,48
    800051c0:	8082                	ret
    return -1;
    800051c2:	557d                	li	a0,-1
    800051c4:	bfcd                	j	800051b6 <argfd+0x4c>
    800051c6:	557d                	li	a0,-1
    800051c8:	b7fd                	j	800051b6 <argfd+0x4c>

00000000800051ca <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800051ca:	1101                	addi	sp,sp,-32
    800051cc:	ec06                	sd	ra,24(sp)
    800051ce:	e822                	sd	s0,16(sp)
    800051d0:	e426                	sd	s1,8(sp)
    800051d2:	1000                	addi	s0,sp,32
    800051d4:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800051d6:	ffffc097          	auipc	ra,0xffffc
    800051da:	7f0080e7          	jalr	2032(ra) # 800019c6 <myproc>
    800051de:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800051e0:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd4d48>
    800051e4:	4501                	li	a0,0
    800051e6:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800051e8:	6398                	ld	a4,0(a5)
    800051ea:	cb19                	beqz	a4,80005200 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800051ec:	2505                	addiw	a0,a0,1
    800051ee:	07a1                	addi	a5,a5,8
    800051f0:	fed51ce3          	bne	a0,a3,800051e8 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800051f4:	557d                	li	a0,-1
}
    800051f6:	60e2                	ld	ra,24(sp)
    800051f8:	6442                	ld	s0,16(sp)
    800051fa:	64a2                	ld	s1,8(sp)
    800051fc:	6105                	addi	sp,sp,32
    800051fe:	8082                	ret
      p->ofile[fd] = f;
    80005200:	01a50793          	addi	a5,a0,26
    80005204:	078e                	slli	a5,a5,0x3
    80005206:	963e                	add	a2,a2,a5
    80005208:	e204                	sd	s1,0(a2)
      return fd;
    8000520a:	b7f5                	j	800051f6 <fdalloc+0x2c>

000000008000520c <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    8000520c:	715d                	addi	sp,sp,-80
    8000520e:	e486                	sd	ra,72(sp)
    80005210:	e0a2                	sd	s0,64(sp)
    80005212:	fc26                	sd	s1,56(sp)
    80005214:	f84a                	sd	s2,48(sp)
    80005216:	f44e                	sd	s3,40(sp)
    80005218:	f052                	sd	s4,32(sp)
    8000521a:	ec56                	sd	s5,24(sp)
    8000521c:	e85a                	sd	s6,16(sp)
    8000521e:	0880                	addi	s0,sp,80
    80005220:	8b2e                	mv	s6,a1
    80005222:	89b2                	mv	s3,a2
    80005224:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005226:	fb040593          	addi	a1,s0,-80
    8000522a:	fffff097          	auipc	ra,0xfffff
    8000522e:	e40080e7          	jalr	-448(ra) # 8000406a <nameiparent>
    80005232:	84aa                	mv	s1,a0
    80005234:	16050063          	beqz	a0,80005394 <create+0x188>
    return 0;

  ilock(dp);
    80005238:	ffffe097          	auipc	ra,0xffffe
    8000523c:	646080e7          	jalr	1606(ra) # 8000387e <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005240:	4601                	li	a2,0
    80005242:	fb040593          	addi	a1,s0,-80
    80005246:	8526                	mv	a0,s1
    80005248:	fffff097          	auipc	ra,0xfffff
    8000524c:	b42080e7          	jalr	-1214(ra) # 80003d8a <dirlookup>
    80005250:	8aaa                	mv	s5,a0
    80005252:	c931                	beqz	a0,800052a6 <create+0x9a>
    iunlockput(dp);
    80005254:	8526                	mv	a0,s1
    80005256:	fffff097          	auipc	ra,0xfffff
    8000525a:	88a080e7          	jalr	-1910(ra) # 80003ae0 <iunlockput>
    ilock(ip);
    8000525e:	8556                	mv	a0,s5
    80005260:	ffffe097          	auipc	ra,0xffffe
    80005264:	61e080e7          	jalr	1566(ra) # 8000387e <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005268:	000b059b          	sext.w	a1,s6
    8000526c:	4789                	li	a5,2
    8000526e:	02f59563          	bne	a1,a5,80005298 <create+0x8c>
    80005272:	044ad783          	lhu	a5,68(s5)
    80005276:	37f9                	addiw	a5,a5,-2
    80005278:	17c2                	slli	a5,a5,0x30
    8000527a:	93c1                	srli	a5,a5,0x30
    8000527c:	4705                	li	a4,1
    8000527e:	00f76d63          	bltu	a4,a5,80005298 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005282:	8556                	mv	a0,s5
    80005284:	60a6                	ld	ra,72(sp)
    80005286:	6406                	ld	s0,64(sp)
    80005288:	74e2                	ld	s1,56(sp)
    8000528a:	7942                	ld	s2,48(sp)
    8000528c:	79a2                	ld	s3,40(sp)
    8000528e:	7a02                	ld	s4,32(sp)
    80005290:	6ae2                	ld	s5,24(sp)
    80005292:	6b42                	ld	s6,16(sp)
    80005294:	6161                	addi	sp,sp,80
    80005296:	8082                	ret
    iunlockput(ip);
    80005298:	8556                	mv	a0,s5
    8000529a:	fffff097          	auipc	ra,0xfffff
    8000529e:	846080e7          	jalr	-1978(ra) # 80003ae0 <iunlockput>
    return 0;
    800052a2:	4a81                	li	s5,0
    800052a4:	bff9                	j	80005282 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800052a6:	85da                	mv	a1,s6
    800052a8:	4088                	lw	a0,0(s1)
    800052aa:	ffffe097          	auipc	ra,0xffffe
    800052ae:	438080e7          	jalr	1080(ra) # 800036e2 <ialloc>
    800052b2:	8a2a                	mv	s4,a0
    800052b4:	c921                	beqz	a0,80005304 <create+0xf8>
  ilock(ip);
    800052b6:	ffffe097          	auipc	ra,0xffffe
    800052ba:	5c8080e7          	jalr	1480(ra) # 8000387e <ilock>
  ip->major = major;
    800052be:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800052c2:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800052c6:	4785                	li	a5,1
    800052c8:	04fa1523          	sh	a5,74(s4)
  iupdate(ip);
    800052cc:	8552                	mv	a0,s4
    800052ce:	ffffe097          	auipc	ra,0xffffe
    800052d2:	4e6080e7          	jalr	1254(ra) # 800037b4 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800052d6:	000b059b          	sext.w	a1,s6
    800052da:	4785                	li	a5,1
    800052dc:	02f58b63          	beq	a1,a5,80005312 <create+0x106>
  if(dirlink(dp, name, ip->inum) < 0)
    800052e0:	004a2603          	lw	a2,4(s4)
    800052e4:	fb040593          	addi	a1,s0,-80
    800052e8:	8526                	mv	a0,s1
    800052ea:	fffff097          	auipc	ra,0xfffff
    800052ee:	cb0080e7          	jalr	-848(ra) # 80003f9a <dirlink>
    800052f2:	06054f63          	bltz	a0,80005370 <create+0x164>
  iunlockput(dp);
    800052f6:	8526                	mv	a0,s1
    800052f8:	ffffe097          	auipc	ra,0xffffe
    800052fc:	7e8080e7          	jalr	2024(ra) # 80003ae0 <iunlockput>
  return ip;
    80005300:	8ad2                	mv	s5,s4
    80005302:	b741                	j	80005282 <create+0x76>
    iunlockput(dp);
    80005304:	8526                	mv	a0,s1
    80005306:	ffffe097          	auipc	ra,0xffffe
    8000530a:	7da080e7          	jalr	2010(ra) # 80003ae0 <iunlockput>
    return 0;
    8000530e:	8ad2                	mv	s5,s4
    80005310:	bf8d                	j	80005282 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005312:	004a2603          	lw	a2,4(s4)
    80005316:	00003597          	auipc	a1,0x3
    8000531a:	5da58593          	addi	a1,a1,1498 # 800088f0 <syscalls+0x300>
    8000531e:	8552                	mv	a0,s4
    80005320:	fffff097          	auipc	ra,0xfffff
    80005324:	c7a080e7          	jalr	-902(ra) # 80003f9a <dirlink>
    80005328:	04054463          	bltz	a0,80005370 <create+0x164>
    8000532c:	40d0                	lw	a2,4(s1)
    8000532e:	00003597          	auipc	a1,0x3
    80005332:	5ca58593          	addi	a1,a1,1482 # 800088f8 <syscalls+0x308>
    80005336:	8552                	mv	a0,s4
    80005338:	fffff097          	auipc	ra,0xfffff
    8000533c:	c62080e7          	jalr	-926(ra) # 80003f9a <dirlink>
    80005340:	02054863          	bltz	a0,80005370 <create+0x164>
  if(dirlink(dp, name, ip->inum) < 0)
    80005344:	004a2603          	lw	a2,4(s4)
    80005348:	fb040593          	addi	a1,s0,-80
    8000534c:	8526                	mv	a0,s1
    8000534e:	fffff097          	auipc	ra,0xfffff
    80005352:	c4c080e7          	jalr	-948(ra) # 80003f9a <dirlink>
    80005356:	00054d63          	bltz	a0,80005370 <create+0x164>
    dp->nlink++;  // for ".."
    8000535a:	04a4d783          	lhu	a5,74(s1)
    8000535e:	2785                	addiw	a5,a5,1
    80005360:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005364:	8526                	mv	a0,s1
    80005366:	ffffe097          	auipc	ra,0xffffe
    8000536a:	44e080e7          	jalr	1102(ra) # 800037b4 <iupdate>
    8000536e:	b761                	j	800052f6 <create+0xea>
  ip->nlink = 0;
    80005370:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005374:	8552                	mv	a0,s4
    80005376:	ffffe097          	auipc	ra,0xffffe
    8000537a:	43e080e7          	jalr	1086(ra) # 800037b4 <iupdate>
  iunlockput(ip);
    8000537e:	8552                	mv	a0,s4
    80005380:	ffffe097          	auipc	ra,0xffffe
    80005384:	760080e7          	jalr	1888(ra) # 80003ae0 <iunlockput>
  iunlockput(dp);
    80005388:	8526                	mv	a0,s1
    8000538a:	ffffe097          	auipc	ra,0xffffe
    8000538e:	756080e7          	jalr	1878(ra) # 80003ae0 <iunlockput>
  return 0;
    80005392:	bdc5                	j	80005282 <create+0x76>
    return 0;
    80005394:	8aaa                	mv	s5,a0
    80005396:	b5f5                	j	80005282 <create+0x76>

0000000080005398 <sys_dup>:
{
    80005398:	7179                	addi	sp,sp,-48
    8000539a:	f406                	sd	ra,40(sp)
    8000539c:	f022                	sd	s0,32(sp)
    8000539e:	ec26                	sd	s1,24(sp)
    800053a0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800053a2:	fd840613          	addi	a2,s0,-40
    800053a6:	4581                	li	a1,0
    800053a8:	4501                	li	a0,0
    800053aa:	00000097          	auipc	ra,0x0
    800053ae:	dc0080e7          	jalr	-576(ra) # 8000516a <argfd>
    return -1;
    800053b2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800053b4:	02054363          	bltz	a0,800053da <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800053b8:	fd843503          	ld	a0,-40(s0)
    800053bc:	00000097          	auipc	ra,0x0
    800053c0:	e0e080e7          	jalr	-498(ra) # 800051ca <fdalloc>
    800053c4:	84aa                	mv	s1,a0
    return -1;
    800053c6:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800053c8:	00054963          	bltz	a0,800053da <sys_dup+0x42>
  filedup(f);
    800053cc:	fd843503          	ld	a0,-40(s0)
    800053d0:	fffff097          	auipc	ra,0xfffff
    800053d4:	312080e7          	jalr	786(ra) # 800046e2 <filedup>
  return fd;
    800053d8:	87a6                	mv	a5,s1
}
    800053da:	853e                	mv	a0,a5
    800053dc:	70a2                	ld	ra,40(sp)
    800053de:	7402                	ld	s0,32(sp)
    800053e0:	64e2                	ld	s1,24(sp)
    800053e2:	6145                	addi	sp,sp,48
    800053e4:	8082                	ret

00000000800053e6 <sys_read>:
{
    800053e6:	7179                	addi	sp,sp,-48
    800053e8:	f406                	sd	ra,40(sp)
    800053ea:	f022                	sd	s0,32(sp)
    800053ec:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800053ee:	fd840593          	addi	a1,s0,-40
    800053f2:	4505                	li	a0,1
    800053f4:	ffffe097          	auipc	ra,0xffffe
    800053f8:	80e080e7          	jalr	-2034(ra) # 80002c02 <argaddr>
  argint(2, &n);
    800053fc:	fe440593          	addi	a1,s0,-28
    80005400:	4509                	li	a0,2
    80005402:	ffffd097          	auipc	ra,0xffffd
    80005406:	7e0080e7          	jalr	2016(ra) # 80002be2 <argint>
  if(argfd(0, 0, &f) < 0)
    8000540a:	fe840613          	addi	a2,s0,-24
    8000540e:	4581                	li	a1,0
    80005410:	4501                	li	a0,0
    80005412:	00000097          	auipc	ra,0x0
    80005416:	d58080e7          	jalr	-680(ra) # 8000516a <argfd>
    8000541a:	87aa                	mv	a5,a0
    return -1;
    8000541c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000541e:	0007cc63          	bltz	a5,80005436 <sys_read+0x50>
  return fileread(f, p, n);
    80005422:	fe442603          	lw	a2,-28(s0)
    80005426:	fd843583          	ld	a1,-40(s0)
    8000542a:	fe843503          	ld	a0,-24(s0)
    8000542e:	fffff097          	auipc	ra,0xfffff
    80005432:	440080e7          	jalr	1088(ra) # 8000486e <fileread>
}
    80005436:	70a2                	ld	ra,40(sp)
    80005438:	7402                	ld	s0,32(sp)
    8000543a:	6145                	addi	sp,sp,48
    8000543c:	8082                	ret

000000008000543e <sys_write>:
{
    8000543e:	7179                	addi	sp,sp,-48
    80005440:	f406                	sd	ra,40(sp)
    80005442:	f022                	sd	s0,32(sp)
    80005444:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005446:	fd840593          	addi	a1,s0,-40
    8000544a:	4505                	li	a0,1
    8000544c:	ffffd097          	auipc	ra,0xffffd
    80005450:	7b6080e7          	jalr	1974(ra) # 80002c02 <argaddr>
  argint(2, &n);
    80005454:	fe440593          	addi	a1,s0,-28
    80005458:	4509                	li	a0,2
    8000545a:	ffffd097          	auipc	ra,0xffffd
    8000545e:	788080e7          	jalr	1928(ra) # 80002be2 <argint>
  if(argfd(0, 0, &f) < 0)
    80005462:	fe840613          	addi	a2,s0,-24
    80005466:	4581                	li	a1,0
    80005468:	4501                	li	a0,0
    8000546a:	00000097          	auipc	ra,0x0
    8000546e:	d00080e7          	jalr	-768(ra) # 8000516a <argfd>
    80005472:	87aa                	mv	a5,a0
    return -1;
    80005474:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005476:	0007cc63          	bltz	a5,8000548e <sys_write+0x50>
  return filewrite(f, p, n);
    8000547a:	fe442603          	lw	a2,-28(s0)
    8000547e:	fd843583          	ld	a1,-40(s0)
    80005482:	fe843503          	ld	a0,-24(s0)
    80005486:	fffff097          	auipc	ra,0xfffff
    8000548a:	4aa080e7          	jalr	1194(ra) # 80004930 <filewrite>
}
    8000548e:	70a2                	ld	ra,40(sp)
    80005490:	7402                	ld	s0,32(sp)
    80005492:	6145                	addi	sp,sp,48
    80005494:	8082                	ret

0000000080005496 <sys_close>:
{
    80005496:	1101                	addi	sp,sp,-32
    80005498:	ec06                	sd	ra,24(sp)
    8000549a:	e822                	sd	s0,16(sp)
    8000549c:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000549e:	fe040613          	addi	a2,s0,-32
    800054a2:	fec40593          	addi	a1,s0,-20
    800054a6:	4501                	li	a0,0
    800054a8:	00000097          	auipc	ra,0x0
    800054ac:	cc2080e7          	jalr	-830(ra) # 8000516a <argfd>
    return -1;
    800054b0:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800054b2:	02054463          	bltz	a0,800054da <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800054b6:	ffffc097          	auipc	ra,0xffffc
    800054ba:	510080e7          	jalr	1296(ra) # 800019c6 <myproc>
    800054be:	fec42783          	lw	a5,-20(s0)
    800054c2:	07e9                	addi	a5,a5,26
    800054c4:	078e                	slli	a5,a5,0x3
    800054c6:	97aa                	add	a5,a5,a0
    800054c8:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800054cc:	fe043503          	ld	a0,-32(s0)
    800054d0:	fffff097          	auipc	ra,0xfffff
    800054d4:	264080e7          	jalr	612(ra) # 80004734 <fileclose>
  return 0;
    800054d8:	4781                	li	a5,0
}
    800054da:	853e                	mv	a0,a5
    800054dc:	60e2                	ld	ra,24(sp)
    800054de:	6442                	ld	s0,16(sp)
    800054e0:	6105                	addi	sp,sp,32
    800054e2:	8082                	ret

00000000800054e4 <sys_fstat>:
{
    800054e4:	1101                	addi	sp,sp,-32
    800054e6:	ec06                	sd	ra,24(sp)
    800054e8:	e822                	sd	s0,16(sp)
    800054ea:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800054ec:	fe040593          	addi	a1,s0,-32
    800054f0:	4505                	li	a0,1
    800054f2:	ffffd097          	auipc	ra,0xffffd
    800054f6:	710080e7          	jalr	1808(ra) # 80002c02 <argaddr>
  if(argfd(0, 0, &f) < 0)
    800054fa:	fe840613          	addi	a2,s0,-24
    800054fe:	4581                	li	a1,0
    80005500:	4501                	li	a0,0
    80005502:	00000097          	auipc	ra,0x0
    80005506:	c68080e7          	jalr	-920(ra) # 8000516a <argfd>
    8000550a:	87aa                	mv	a5,a0
    return -1;
    8000550c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000550e:	0007ca63          	bltz	a5,80005522 <sys_fstat+0x3e>
  return filestat(f, st);
    80005512:	fe043583          	ld	a1,-32(s0)
    80005516:	fe843503          	ld	a0,-24(s0)
    8000551a:	fffff097          	auipc	ra,0xfffff
    8000551e:	2e2080e7          	jalr	738(ra) # 800047fc <filestat>
}
    80005522:	60e2                	ld	ra,24(sp)
    80005524:	6442                	ld	s0,16(sp)
    80005526:	6105                	addi	sp,sp,32
    80005528:	8082                	ret

000000008000552a <sys_link>:
{
    8000552a:	7169                	addi	sp,sp,-304
    8000552c:	f606                	sd	ra,296(sp)
    8000552e:	f222                	sd	s0,288(sp)
    80005530:	ee26                	sd	s1,280(sp)
    80005532:	ea4a                	sd	s2,272(sp)
    80005534:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005536:	08000613          	li	a2,128
    8000553a:	ed040593          	addi	a1,s0,-304
    8000553e:	4501                	li	a0,0
    80005540:	ffffd097          	auipc	ra,0xffffd
    80005544:	6e2080e7          	jalr	1762(ra) # 80002c22 <argstr>
    return -1;
    80005548:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000554a:	10054e63          	bltz	a0,80005666 <sys_link+0x13c>
    8000554e:	08000613          	li	a2,128
    80005552:	f5040593          	addi	a1,s0,-176
    80005556:	4505                	li	a0,1
    80005558:	ffffd097          	auipc	ra,0xffffd
    8000555c:	6ca080e7          	jalr	1738(ra) # 80002c22 <argstr>
    return -1;
    80005560:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005562:	10054263          	bltz	a0,80005666 <sys_link+0x13c>
  begin_op();
    80005566:	fffff097          	auipc	ra,0xfffff
    8000556a:	d02080e7          	jalr	-766(ra) # 80004268 <begin_op>
  if((ip = namei(old)) == 0){
    8000556e:	ed040513          	addi	a0,s0,-304
    80005572:	fffff097          	auipc	ra,0xfffff
    80005576:	ada080e7          	jalr	-1318(ra) # 8000404c <namei>
    8000557a:	84aa                	mv	s1,a0
    8000557c:	c551                	beqz	a0,80005608 <sys_link+0xde>
  ilock(ip);
    8000557e:	ffffe097          	auipc	ra,0xffffe
    80005582:	300080e7          	jalr	768(ra) # 8000387e <ilock>
  if(ip->type == T_DIR){
    80005586:	04449703          	lh	a4,68(s1)
    8000558a:	4785                	li	a5,1
    8000558c:	08f70463          	beq	a4,a5,80005614 <sys_link+0xea>
  ip->nlink++;
    80005590:	04a4d783          	lhu	a5,74(s1)
    80005594:	2785                	addiw	a5,a5,1
    80005596:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000559a:	8526                	mv	a0,s1
    8000559c:	ffffe097          	auipc	ra,0xffffe
    800055a0:	218080e7          	jalr	536(ra) # 800037b4 <iupdate>
  iunlock(ip);
    800055a4:	8526                	mv	a0,s1
    800055a6:	ffffe097          	auipc	ra,0xffffe
    800055aa:	39a080e7          	jalr	922(ra) # 80003940 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800055ae:	fd040593          	addi	a1,s0,-48
    800055b2:	f5040513          	addi	a0,s0,-176
    800055b6:	fffff097          	auipc	ra,0xfffff
    800055ba:	ab4080e7          	jalr	-1356(ra) # 8000406a <nameiparent>
    800055be:	892a                	mv	s2,a0
    800055c0:	c935                	beqz	a0,80005634 <sys_link+0x10a>
  ilock(dp);
    800055c2:	ffffe097          	auipc	ra,0xffffe
    800055c6:	2bc080e7          	jalr	700(ra) # 8000387e <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800055ca:	00092703          	lw	a4,0(s2)
    800055ce:	409c                	lw	a5,0(s1)
    800055d0:	04f71d63          	bne	a4,a5,8000562a <sys_link+0x100>
    800055d4:	40d0                	lw	a2,4(s1)
    800055d6:	fd040593          	addi	a1,s0,-48
    800055da:	854a                	mv	a0,s2
    800055dc:	fffff097          	auipc	ra,0xfffff
    800055e0:	9be080e7          	jalr	-1602(ra) # 80003f9a <dirlink>
    800055e4:	04054363          	bltz	a0,8000562a <sys_link+0x100>
  iunlockput(dp);
    800055e8:	854a                	mv	a0,s2
    800055ea:	ffffe097          	auipc	ra,0xffffe
    800055ee:	4f6080e7          	jalr	1270(ra) # 80003ae0 <iunlockput>
  iput(ip);
    800055f2:	8526                	mv	a0,s1
    800055f4:	ffffe097          	auipc	ra,0xffffe
    800055f8:	444080e7          	jalr	1092(ra) # 80003a38 <iput>
  end_op();
    800055fc:	fffff097          	auipc	ra,0xfffff
    80005600:	cec080e7          	jalr	-788(ra) # 800042e8 <end_op>
  return 0;
    80005604:	4781                	li	a5,0
    80005606:	a085                	j	80005666 <sys_link+0x13c>
    end_op();
    80005608:	fffff097          	auipc	ra,0xfffff
    8000560c:	ce0080e7          	jalr	-800(ra) # 800042e8 <end_op>
    return -1;
    80005610:	57fd                	li	a5,-1
    80005612:	a891                	j	80005666 <sys_link+0x13c>
    iunlockput(ip);
    80005614:	8526                	mv	a0,s1
    80005616:	ffffe097          	auipc	ra,0xffffe
    8000561a:	4ca080e7          	jalr	1226(ra) # 80003ae0 <iunlockput>
    end_op();
    8000561e:	fffff097          	auipc	ra,0xfffff
    80005622:	cca080e7          	jalr	-822(ra) # 800042e8 <end_op>
    return -1;
    80005626:	57fd                	li	a5,-1
    80005628:	a83d                	j	80005666 <sys_link+0x13c>
    iunlockput(dp);
    8000562a:	854a                	mv	a0,s2
    8000562c:	ffffe097          	auipc	ra,0xffffe
    80005630:	4b4080e7          	jalr	1204(ra) # 80003ae0 <iunlockput>
  ilock(ip);
    80005634:	8526                	mv	a0,s1
    80005636:	ffffe097          	auipc	ra,0xffffe
    8000563a:	248080e7          	jalr	584(ra) # 8000387e <ilock>
  ip->nlink--;
    8000563e:	04a4d783          	lhu	a5,74(s1)
    80005642:	37fd                	addiw	a5,a5,-1
    80005644:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005648:	8526                	mv	a0,s1
    8000564a:	ffffe097          	auipc	ra,0xffffe
    8000564e:	16a080e7          	jalr	362(ra) # 800037b4 <iupdate>
  iunlockput(ip);
    80005652:	8526                	mv	a0,s1
    80005654:	ffffe097          	auipc	ra,0xffffe
    80005658:	48c080e7          	jalr	1164(ra) # 80003ae0 <iunlockput>
  end_op();
    8000565c:	fffff097          	auipc	ra,0xfffff
    80005660:	c8c080e7          	jalr	-884(ra) # 800042e8 <end_op>
  return -1;
    80005664:	57fd                	li	a5,-1
}
    80005666:	853e                	mv	a0,a5
    80005668:	70b2                	ld	ra,296(sp)
    8000566a:	7412                	ld	s0,288(sp)
    8000566c:	64f2                	ld	s1,280(sp)
    8000566e:	6952                	ld	s2,272(sp)
    80005670:	6155                	addi	sp,sp,304
    80005672:	8082                	ret

0000000080005674 <sys_unlink>:
{
    80005674:	7151                	addi	sp,sp,-240
    80005676:	f586                	sd	ra,232(sp)
    80005678:	f1a2                	sd	s0,224(sp)
    8000567a:	eda6                	sd	s1,216(sp)
    8000567c:	e9ca                	sd	s2,208(sp)
    8000567e:	e5ce                	sd	s3,200(sp)
    80005680:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005682:	08000613          	li	a2,128
    80005686:	f3040593          	addi	a1,s0,-208
    8000568a:	4501                	li	a0,0
    8000568c:	ffffd097          	auipc	ra,0xffffd
    80005690:	596080e7          	jalr	1430(ra) # 80002c22 <argstr>
    80005694:	18054163          	bltz	a0,80005816 <sys_unlink+0x1a2>
  begin_op();
    80005698:	fffff097          	auipc	ra,0xfffff
    8000569c:	bd0080e7          	jalr	-1072(ra) # 80004268 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800056a0:	fb040593          	addi	a1,s0,-80
    800056a4:	f3040513          	addi	a0,s0,-208
    800056a8:	fffff097          	auipc	ra,0xfffff
    800056ac:	9c2080e7          	jalr	-1598(ra) # 8000406a <nameiparent>
    800056b0:	84aa                	mv	s1,a0
    800056b2:	c979                	beqz	a0,80005788 <sys_unlink+0x114>
  ilock(dp);
    800056b4:	ffffe097          	auipc	ra,0xffffe
    800056b8:	1ca080e7          	jalr	458(ra) # 8000387e <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800056bc:	00003597          	auipc	a1,0x3
    800056c0:	23458593          	addi	a1,a1,564 # 800088f0 <syscalls+0x300>
    800056c4:	fb040513          	addi	a0,s0,-80
    800056c8:	ffffe097          	auipc	ra,0xffffe
    800056cc:	6a8080e7          	jalr	1704(ra) # 80003d70 <namecmp>
    800056d0:	14050a63          	beqz	a0,80005824 <sys_unlink+0x1b0>
    800056d4:	00003597          	auipc	a1,0x3
    800056d8:	22458593          	addi	a1,a1,548 # 800088f8 <syscalls+0x308>
    800056dc:	fb040513          	addi	a0,s0,-80
    800056e0:	ffffe097          	auipc	ra,0xffffe
    800056e4:	690080e7          	jalr	1680(ra) # 80003d70 <namecmp>
    800056e8:	12050e63          	beqz	a0,80005824 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800056ec:	f2c40613          	addi	a2,s0,-212
    800056f0:	fb040593          	addi	a1,s0,-80
    800056f4:	8526                	mv	a0,s1
    800056f6:	ffffe097          	auipc	ra,0xffffe
    800056fa:	694080e7          	jalr	1684(ra) # 80003d8a <dirlookup>
    800056fe:	892a                	mv	s2,a0
    80005700:	12050263          	beqz	a0,80005824 <sys_unlink+0x1b0>
  ilock(ip);
    80005704:	ffffe097          	auipc	ra,0xffffe
    80005708:	17a080e7          	jalr	378(ra) # 8000387e <ilock>
  if(ip->nlink < 1)
    8000570c:	04a91783          	lh	a5,74(s2)
    80005710:	08f05263          	blez	a5,80005794 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005714:	04491703          	lh	a4,68(s2)
    80005718:	4785                	li	a5,1
    8000571a:	08f70563          	beq	a4,a5,800057a4 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000571e:	4641                	li	a2,16
    80005720:	4581                	li	a1,0
    80005722:	fc040513          	addi	a0,s0,-64
    80005726:	ffffb097          	auipc	ra,0xffffb
    8000572a:	5c0080e7          	jalr	1472(ra) # 80000ce6 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000572e:	4741                	li	a4,16
    80005730:	f2c42683          	lw	a3,-212(s0)
    80005734:	fc040613          	addi	a2,s0,-64
    80005738:	4581                	li	a1,0
    8000573a:	8526                	mv	a0,s1
    8000573c:	ffffe097          	auipc	ra,0xffffe
    80005740:	4ee080e7          	jalr	1262(ra) # 80003c2a <writei>
    80005744:	47c1                	li	a5,16
    80005746:	0af51563          	bne	a0,a5,800057f0 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000574a:	04491703          	lh	a4,68(s2)
    8000574e:	4785                	li	a5,1
    80005750:	0af70863          	beq	a4,a5,80005800 <sys_unlink+0x18c>
  iunlockput(dp);
    80005754:	8526                	mv	a0,s1
    80005756:	ffffe097          	auipc	ra,0xffffe
    8000575a:	38a080e7          	jalr	906(ra) # 80003ae0 <iunlockput>
  ip->nlink--;
    8000575e:	04a95783          	lhu	a5,74(s2)
    80005762:	37fd                	addiw	a5,a5,-1
    80005764:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005768:	854a                	mv	a0,s2
    8000576a:	ffffe097          	auipc	ra,0xffffe
    8000576e:	04a080e7          	jalr	74(ra) # 800037b4 <iupdate>
  iunlockput(ip);
    80005772:	854a                	mv	a0,s2
    80005774:	ffffe097          	auipc	ra,0xffffe
    80005778:	36c080e7          	jalr	876(ra) # 80003ae0 <iunlockput>
  end_op();
    8000577c:	fffff097          	auipc	ra,0xfffff
    80005780:	b6c080e7          	jalr	-1172(ra) # 800042e8 <end_op>
  return 0;
    80005784:	4501                	li	a0,0
    80005786:	a84d                	j	80005838 <sys_unlink+0x1c4>
    end_op();
    80005788:	fffff097          	auipc	ra,0xfffff
    8000578c:	b60080e7          	jalr	-1184(ra) # 800042e8 <end_op>
    return -1;
    80005790:	557d                	li	a0,-1
    80005792:	a05d                	j	80005838 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005794:	00003517          	auipc	a0,0x3
    80005798:	16c50513          	addi	a0,a0,364 # 80008900 <syscalls+0x310>
    8000579c:	ffffb097          	auipc	ra,0xffffb
    800057a0:	da8080e7          	jalr	-600(ra) # 80000544 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057a4:	04c92703          	lw	a4,76(s2)
    800057a8:	02000793          	li	a5,32
    800057ac:	f6e7f9e3          	bgeu	a5,a4,8000571e <sys_unlink+0xaa>
    800057b0:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800057b4:	4741                	li	a4,16
    800057b6:	86ce                	mv	a3,s3
    800057b8:	f1840613          	addi	a2,s0,-232
    800057bc:	4581                	li	a1,0
    800057be:	854a                	mv	a0,s2
    800057c0:	ffffe097          	auipc	ra,0xffffe
    800057c4:	372080e7          	jalr	882(ra) # 80003b32 <readi>
    800057c8:	47c1                	li	a5,16
    800057ca:	00f51b63          	bne	a0,a5,800057e0 <sys_unlink+0x16c>
    if(de.inum != 0)
    800057ce:	f1845783          	lhu	a5,-232(s0)
    800057d2:	e7a1                	bnez	a5,8000581a <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800057d4:	29c1                	addiw	s3,s3,16
    800057d6:	04c92783          	lw	a5,76(s2)
    800057da:	fcf9ede3          	bltu	s3,a5,800057b4 <sys_unlink+0x140>
    800057de:	b781                	j	8000571e <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800057e0:	00003517          	auipc	a0,0x3
    800057e4:	13850513          	addi	a0,a0,312 # 80008918 <syscalls+0x328>
    800057e8:	ffffb097          	auipc	ra,0xffffb
    800057ec:	d5c080e7          	jalr	-676(ra) # 80000544 <panic>
    panic("unlink: writei");
    800057f0:	00003517          	auipc	a0,0x3
    800057f4:	14050513          	addi	a0,a0,320 # 80008930 <syscalls+0x340>
    800057f8:	ffffb097          	auipc	ra,0xffffb
    800057fc:	d4c080e7          	jalr	-692(ra) # 80000544 <panic>
    dp->nlink--;
    80005800:	04a4d783          	lhu	a5,74(s1)
    80005804:	37fd                	addiw	a5,a5,-1
    80005806:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000580a:	8526                	mv	a0,s1
    8000580c:	ffffe097          	auipc	ra,0xffffe
    80005810:	fa8080e7          	jalr	-88(ra) # 800037b4 <iupdate>
    80005814:	b781                	j	80005754 <sys_unlink+0xe0>
    return -1;
    80005816:	557d                	li	a0,-1
    80005818:	a005                	j	80005838 <sys_unlink+0x1c4>
    iunlockput(ip);
    8000581a:	854a                	mv	a0,s2
    8000581c:	ffffe097          	auipc	ra,0xffffe
    80005820:	2c4080e7          	jalr	708(ra) # 80003ae0 <iunlockput>
  iunlockput(dp);
    80005824:	8526                	mv	a0,s1
    80005826:	ffffe097          	auipc	ra,0xffffe
    8000582a:	2ba080e7          	jalr	698(ra) # 80003ae0 <iunlockput>
  end_op();
    8000582e:	fffff097          	auipc	ra,0xfffff
    80005832:	aba080e7          	jalr	-1350(ra) # 800042e8 <end_op>
  return -1;
    80005836:	557d                	li	a0,-1
}
    80005838:	70ae                	ld	ra,232(sp)
    8000583a:	740e                	ld	s0,224(sp)
    8000583c:	64ee                	ld	s1,216(sp)
    8000583e:	694e                	ld	s2,208(sp)
    80005840:	69ae                	ld	s3,200(sp)
    80005842:	616d                	addi	sp,sp,240
    80005844:	8082                	ret

0000000080005846 <sys_open>:

uint64
sys_open(void)
{
    80005846:	7131                	addi	sp,sp,-192
    80005848:	fd06                	sd	ra,184(sp)
    8000584a:	f922                	sd	s0,176(sp)
    8000584c:	f526                	sd	s1,168(sp)
    8000584e:	f14a                	sd	s2,160(sp)
    80005850:	ed4e                	sd	s3,152(sp)
    80005852:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005854:	f4c40593          	addi	a1,s0,-180
    80005858:	4505                	li	a0,1
    8000585a:	ffffd097          	auipc	ra,0xffffd
    8000585e:	388080e7          	jalr	904(ra) # 80002be2 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005862:	08000613          	li	a2,128
    80005866:	f5040593          	addi	a1,s0,-176
    8000586a:	4501                	li	a0,0
    8000586c:	ffffd097          	auipc	ra,0xffffd
    80005870:	3b6080e7          	jalr	950(ra) # 80002c22 <argstr>
    80005874:	87aa                	mv	a5,a0
    return -1;
    80005876:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005878:	0a07c963          	bltz	a5,8000592a <sys_open+0xe4>

  begin_op();
    8000587c:	fffff097          	auipc	ra,0xfffff
    80005880:	9ec080e7          	jalr	-1556(ra) # 80004268 <begin_op>

  if(omode & O_CREATE){
    80005884:	f4c42783          	lw	a5,-180(s0)
    80005888:	2007f793          	andi	a5,a5,512
    8000588c:	cfc5                	beqz	a5,80005944 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000588e:	4681                	li	a3,0
    80005890:	4601                	li	a2,0
    80005892:	4589                	li	a1,2
    80005894:	f5040513          	addi	a0,s0,-176
    80005898:	00000097          	auipc	ra,0x0
    8000589c:	974080e7          	jalr	-1676(ra) # 8000520c <create>
    800058a0:	84aa                	mv	s1,a0
    if(ip == 0){
    800058a2:	c959                	beqz	a0,80005938 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800058a4:	04449703          	lh	a4,68(s1)
    800058a8:	478d                	li	a5,3
    800058aa:	00f71763          	bne	a4,a5,800058b8 <sys_open+0x72>
    800058ae:	0464d703          	lhu	a4,70(s1)
    800058b2:	47a5                	li	a5,9
    800058b4:	0ce7ed63          	bltu	a5,a4,8000598e <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800058b8:	fffff097          	auipc	ra,0xfffff
    800058bc:	dc0080e7          	jalr	-576(ra) # 80004678 <filealloc>
    800058c0:	89aa                	mv	s3,a0
    800058c2:	10050363          	beqz	a0,800059c8 <sys_open+0x182>
    800058c6:	00000097          	auipc	ra,0x0
    800058ca:	904080e7          	jalr	-1788(ra) # 800051ca <fdalloc>
    800058ce:	892a                	mv	s2,a0
    800058d0:	0e054763          	bltz	a0,800059be <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800058d4:	04449703          	lh	a4,68(s1)
    800058d8:	478d                	li	a5,3
    800058da:	0cf70563          	beq	a4,a5,800059a4 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800058de:	4789                	li	a5,2
    800058e0:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800058e4:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800058e8:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    800058ec:	f4c42783          	lw	a5,-180(s0)
    800058f0:	0017c713          	xori	a4,a5,1
    800058f4:	8b05                	andi	a4,a4,1
    800058f6:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800058fa:	0037f713          	andi	a4,a5,3
    800058fe:	00e03733          	snez	a4,a4
    80005902:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005906:	4007f793          	andi	a5,a5,1024
    8000590a:	c791                	beqz	a5,80005916 <sys_open+0xd0>
    8000590c:	04449703          	lh	a4,68(s1)
    80005910:	4789                	li	a5,2
    80005912:	0af70063          	beq	a4,a5,800059b2 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005916:	8526                	mv	a0,s1
    80005918:	ffffe097          	auipc	ra,0xffffe
    8000591c:	028080e7          	jalr	40(ra) # 80003940 <iunlock>
  end_op();
    80005920:	fffff097          	auipc	ra,0xfffff
    80005924:	9c8080e7          	jalr	-1592(ra) # 800042e8 <end_op>

  return fd;
    80005928:	854a                	mv	a0,s2
}
    8000592a:	70ea                	ld	ra,184(sp)
    8000592c:	744a                	ld	s0,176(sp)
    8000592e:	74aa                	ld	s1,168(sp)
    80005930:	790a                	ld	s2,160(sp)
    80005932:	69ea                	ld	s3,152(sp)
    80005934:	6129                	addi	sp,sp,192
    80005936:	8082                	ret
      end_op();
    80005938:	fffff097          	auipc	ra,0xfffff
    8000593c:	9b0080e7          	jalr	-1616(ra) # 800042e8 <end_op>
      return -1;
    80005940:	557d                	li	a0,-1
    80005942:	b7e5                	j	8000592a <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005944:	f5040513          	addi	a0,s0,-176
    80005948:	ffffe097          	auipc	ra,0xffffe
    8000594c:	704080e7          	jalr	1796(ra) # 8000404c <namei>
    80005950:	84aa                	mv	s1,a0
    80005952:	c905                	beqz	a0,80005982 <sys_open+0x13c>
    ilock(ip);
    80005954:	ffffe097          	auipc	ra,0xffffe
    80005958:	f2a080e7          	jalr	-214(ra) # 8000387e <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000595c:	04449703          	lh	a4,68(s1)
    80005960:	4785                	li	a5,1
    80005962:	f4f711e3          	bne	a4,a5,800058a4 <sys_open+0x5e>
    80005966:	f4c42783          	lw	a5,-180(s0)
    8000596a:	d7b9                	beqz	a5,800058b8 <sys_open+0x72>
      iunlockput(ip);
    8000596c:	8526                	mv	a0,s1
    8000596e:	ffffe097          	auipc	ra,0xffffe
    80005972:	172080e7          	jalr	370(ra) # 80003ae0 <iunlockput>
      end_op();
    80005976:	fffff097          	auipc	ra,0xfffff
    8000597a:	972080e7          	jalr	-1678(ra) # 800042e8 <end_op>
      return -1;
    8000597e:	557d                	li	a0,-1
    80005980:	b76d                	j	8000592a <sys_open+0xe4>
      end_op();
    80005982:	fffff097          	auipc	ra,0xfffff
    80005986:	966080e7          	jalr	-1690(ra) # 800042e8 <end_op>
      return -1;
    8000598a:	557d                	li	a0,-1
    8000598c:	bf79                	j	8000592a <sys_open+0xe4>
    iunlockput(ip);
    8000598e:	8526                	mv	a0,s1
    80005990:	ffffe097          	auipc	ra,0xffffe
    80005994:	150080e7          	jalr	336(ra) # 80003ae0 <iunlockput>
    end_op();
    80005998:	fffff097          	auipc	ra,0xfffff
    8000599c:	950080e7          	jalr	-1712(ra) # 800042e8 <end_op>
    return -1;
    800059a0:	557d                	li	a0,-1
    800059a2:	b761                	j	8000592a <sys_open+0xe4>
    f->type = FD_DEVICE;
    800059a4:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800059a8:	04649783          	lh	a5,70(s1)
    800059ac:	02f99223          	sh	a5,36(s3)
    800059b0:	bf25                	j	800058e8 <sys_open+0xa2>
    itrunc(ip);
    800059b2:	8526                	mv	a0,s1
    800059b4:	ffffe097          	auipc	ra,0xffffe
    800059b8:	fd8080e7          	jalr	-40(ra) # 8000398c <itrunc>
    800059bc:	bfa9                	j	80005916 <sys_open+0xd0>
      fileclose(f);
    800059be:	854e                	mv	a0,s3
    800059c0:	fffff097          	auipc	ra,0xfffff
    800059c4:	d74080e7          	jalr	-652(ra) # 80004734 <fileclose>
    iunlockput(ip);
    800059c8:	8526                	mv	a0,s1
    800059ca:	ffffe097          	auipc	ra,0xffffe
    800059ce:	116080e7          	jalr	278(ra) # 80003ae0 <iunlockput>
    end_op();
    800059d2:	fffff097          	auipc	ra,0xfffff
    800059d6:	916080e7          	jalr	-1770(ra) # 800042e8 <end_op>
    return -1;
    800059da:	557d                	li	a0,-1
    800059dc:	b7b9                	j	8000592a <sys_open+0xe4>

00000000800059de <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800059de:	7175                	addi	sp,sp,-144
    800059e0:	e506                	sd	ra,136(sp)
    800059e2:	e122                	sd	s0,128(sp)
    800059e4:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800059e6:	fffff097          	auipc	ra,0xfffff
    800059ea:	882080e7          	jalr	-1918(ra) # 80004268 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800059ee:	08000613          	li	a2,128
    800059f2:	f7040593          	addi	a1,s0,-144
    800059f6:	4501                	li	a0,0
    800059f8:	ffffd097          	auipc	ra,0xffffd
    800059fc:	22a080e7          	jalr	554(ra) # 80002c22 <argstr>
    80005a00:	02054963          	bltz	a0,80005a32 <sys_mkdir+0x54>
    80005a04:	4681                	li	a3,0
    80005a06:	4601                	li	a2,0
    80005a08:	4585                	li	a1,1
    80005a0a:	f7040513          	addi	a0,s0,-144
    80005a0e:	fffff097          	auipc	ra,0xfffff
    80005a12:	7fe080e7          	jalr	2046(ra) # 8000520c <create>
    80005a16:	cd11                	beqz	a0,80005a32 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a18:	ffffe097          	auipc	ra,0xffffe
    80005a1c:	0c8080e7          	jalr	200(ra) # 80003ae0 <iunlockput>
  end_op();
    80005a20:	fffff097          	auipc	ra,0xfffff
    80005a24:	8c8080e7          	jalr	-1848(ra) # 800042e8 <end_op>
  return 0;
    80005a28:	4501                	li	a0,0
}
    80005a2a:	60aa                	ld	ra,136(sp)
    80005a2c:	640a                	ld	s0,128(sp)
    80005a2e:	6149                	addi	sp,sp,144
    80005a30:	8082                	ret
    end_op();
    80005a32:	fffff097          	auipc	ra,0xfffff
    80005a36:	8b6080e7          	jalr	-1866(ra) # 800042e8 <end_op>
    return -1;
    80005a3a:	557d                	li	a0,-1
    80005a3c:	b7fd                	j	80005a2a <sys_mkdir+0x4c>

0000000080005a3e <sys_mknod>:

uint64
sys_mknod(void)
{
    80005a3e:	7135                	addi	sp,sp,-160
    80005a40:	ed06                	sd	ra,152(sp)
    80005a42:	e922                	sd	s0,144(sp)
    80005a44:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005a46:	fffff097          	auipc	ra,0xfffff
    80005a4a:	822080e7          	jalr	-2014(ra) # 80004268 <begin_op>
  argint(1, &major);
    80005a4e:	f6c40593          	addi	a1,s0,-148
    80005a52:	4505                	li	a0,1
    80005a54:	ffffd097          	auipc	ra,0xffffd
    80005a58:	18e080e7          	jalr	398(ra) # 80002be2 <argint>
  argint(2, &minor);
    80005a5c:	f6840593          	addi	a1,s0,-152
    80005a60:	4509                	li	a0,2
    80005a62:	ffffd097          	auipc	ra,0xffffd
    80005a66:	180080e7          	jalr	384(ra) # 80002be2 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a6a:	08000613          	li	a2,128
    80005a6e:	f7040593          	addi	a1,s0,-144
    80005a72:	4501                	li	a0,0
    80005a74:	ffffd097          	auipc	ra,0xffffd
    80005a78:	1ae080e7          	jalr	430(ra) # 80002c22 <argstr>
    80005a7c:	02054b63          	bltz	a0,80005ab2 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005a80:	f6841683          	lh	a3,-152(s0)
    80005a84:	f6c41603          	lh	a2,-148(s0)
    80005a88:	458d                	li	a1,3
    80005a8a:	f7040513          	addi	a0,s0,-144
    80005a8e:	fffff097          	auipc	ra,0xfffff
    80005a92:	77e080e7          	jalr	1918(ra) # 8000520c <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005a96:	cd11                	beqz	a0,80005ab2 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a98:	ffffe097          	auipc	ra,0xffffe
    80005a9c:	048080e7          	jalr	72(ra) # 80003ae0 <iunlockput>
  end_op();
    80005aa0:	fffff097          	auipc	ra,0xfffff
    80005aa4:	848080e7          	jalr	-1976(ra) # 800042e8 <end_op>
  return 0;
    80005aa8:	4501                	li	a0,0
}
    80005aaa:	60ea                	ld	ra,152(sp)
    80005aac:	644a                	ld	s0,144(sp)
    80005aae:	610d                	addi	sp,sp,160
    80005ab0:	8082                	ret
    end_op();
    80005ab2:	fffff097          	auipc	ra,0xfffff
    80005ab6:	836080e7          	jalr	-1994(ra) # 800042e8 <end_op>
    return -1;
    80005aba:	557d                	li	a0,-1
    80005abc:	b7fd                	j	80005aaa <sys_mknod+0x6c>

0000000080005abe <sys_chdir>:

uint64
sys_chdir(void)
{
    80005abe:	7135                	addi	sp,sp,-160
    80005ac0:	ed06                	sd	ra,152(sp)
    80005ac2:	e922                	sd	s0,144(sp)
    80005ac4:	e526                	sd	s1,136(sp)
    80005ac6:	e14a                	sd	s2,128(sp)
    80005ac8:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005aca:	ffffc097          	auipc	ra,0xffffc
    80005ace:	efc080e7          	jalr	-260(ra) # 800019c6 <myproc>
    80005ad2:	892a                	mv	s2,a0
  
  begin_op();
    80005ad4:	ffffe097          	auipc	ra,0xffffe
    80005ad8:	794080e7          	jalr	1940(ra) # 80004268 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005adc:	08000613          	li	a2,128
    80005ae0:	f6040593          	addi	a1,s0,-160
    80005ae4:	4501                	li	a0,0
    80005ae6:	ffffd097          	auipc	ra,0xffffd
    80005aea:	13c080e7          	jalr	316(ra) # 80002c22 <argstr>
    80005aee:	04054b63          	bltz	a0,80005b44 <sys_chdir+0x86>
    80005af2:	f6040513          	addi	a0,s0,-160
    80005af6:	ffffe097          	auipc	ra,0xffffe
    80005afa:	556080e7          	jalr	1366(ra) # 8000404c <namei>
    80005afe:	84aa                	mv	s1,a0
    80005b00:	c131                	beqz	a0,80005b44 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005b02:	ffffe097          	auipc	ra,0xffffe
    80005b06:	d7c080e7          	jalr	-644(ra) # 8000387e <ilock>
  if(ip->type != T_DIR){
    80005b0a:	04449703          	lh	a4,68(s1)
    80005b0e:	4785                	li	a5,1
    80005b10:	04f71063          	bne	a4,a5,80005b50 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005b14:	8526                	mv	a0,s1
    80005b16:	ffffe097          	auipc	ra,0xffffe
    80005b1a:	e2a080e7          	jalr	-470(ra) # 80003940 <iunlock>
  iput(p->cwd);
    80005b1e:	15093503          	ld	a0,336(s2)
    80005b22:	ffffe097          	auipc	ra,0xffffe
    80005b26:	f16080e7          	jalr	-234(ra) # 80003a38 <iput>
  end_op();
    80005b2a:	ffffe097          	auipc	ra,0xffffe
    80005b2e:	7be080e7          	jalr	1982(ra) # 800042e8 <end_op>
  p->cwd = ip;
    80005b32:	14993823          	sd	s1,336(s2)
  return 0;
    80005b36:	4501                	li	a0,0
}
    80005b38:	60ea                	ld	ra,152(sp)
    80005b3a:	644a                	ld	s0,144(sp)
    80005b3c:	64aa                	ld	s1,136(sp)
    80005b3e:	690a                	ld	s2,128(sp)
    80005b40:	610d                	addi	sp,sp,160
    80005b42:	8082                	ret
    end_op();
    80005b44:	ffffe097          	auipc	ra,0xffffe
    80005b48:	7a4080e7          	jalr	1956(ra) # 800042e8 <end_op>
    return -1;
    80005b4c:	557d                	li	a0,-1
    80005b4e:	b7ed                	j	80005b38 <sys_chdir+0x7a>
    iunlockput(ip);
    80005b50:	8526                	mv	a0,s1
    80005b52:	ffffe097          	auipc	ra,0xffffe
    80005b56:	f8e080e7          	jalr	-114(ra) # 80003ae0 <iunlockput>
    end_op();
    80005b5a:	ffffe097          	auipc	ra,0xffffe
    80005b5e:	78e080e7          	jalr	1934(ra) # 800042e8 <end_op>
    return -1;
    80005b62:	557d                	li	a0,-1
    80005b64:	bfd1                	j	80005b38 <sys_chdir+0x7a>

0000000080005b66 <sys_exec>:

uint64
sys_exec(void)
{
    80005b66:	7145                	addi	sp,sp,-464
    80005b68:	e786                	sd	ra,456(sp)
    80005b6a:	e3a2                	sd	s0,448(sp)
    80005b6c:	ff26                	sd	s1,440(sp)
    80005b6e:	fb4a                	sd	s2,432(sp)
    80005b70:	f74e                	sd	s3,424(sp)
    80005b72:	f352                	sd	s4,416(sp)
    80005b74:	ef56                	sd	s5,408(sp)
    80005b76:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005b78:	e3840593          	addi	a1,s0,-456
    80005b7c:	4505                	li	a0,1
    80005b7e:	ffffd097          	auipc	ra,0xffffd
    80005b82:	084080e7          	jalr	132(ra) # 80002c02 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005b86:	08000613          	li	a2,128
    80005b8a:	f4040593          	addi	a1,s0,-192
    80005b8e:	4501                	li	a0,0
    80005b90:	ffffd097          	auipc	ra,0xffffd
    80005b94:	092080e7          	jalr	146(ra) # 80002c22 <argstr>
    80005b98:	87aa                	mv	a5,a0
    return -1;
    80005b9a:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005b9c:	0c07c263          	bltz	a5,80005c60 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005ba0:	10000613          	li	a2,256
    80005ba4:	4581                	li	a1,0
    80005ba6:	e4040513          	addi	a0,s0,-448
    80005baa:	ffffb097          	auipc	ra,0xffffb
    80005bae:	13c080e7          	jalr	316(ra) # 80000ce6 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005bb2:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005bb6:	89a6                	mv	s3,s1
    80005bb8:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005bba:	02000a13          	li	s4,32
    80005bbe:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005bc2:	00391513          	slli	a0,s2,0x3
    80005bc6:	e3040593          	addi	a1,s0,-464
    80005bca:	e3843783          	ld	a5,-456(s0)
    80005bce:	953e                	add	a0,a0,a5
    80005bd0:	ffffd097          	auipc	ra,0xffffd
    80005bd4:	f74080e7          	jalr	-140(ra) # 80002b44 <fetchaddr>
    80005bd8:	02054a63          	bltz	a0,80005c0c <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005bdc:	e3043783          	ld	a5,-464(s0)
    80005be0:	c3b9                	beqz	a5,80005c26 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005be2:	ffffb097          	auipc	ra,0xffffb
    80005be6:	f18080e7          	jalr	-232(ra) # 80000afa <kalloc>
    80005bea:	85aa                	mv	a1,a0
    80005bec:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005bf0:	cd11                	beqz	a0,80005c0c <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005bf2:	6605                	lui	a2,0x1
    80005bf4:	e3043503          	ld	a0,-464(s0)
    80005bf8:	ffffd097          	auipc	ra,0xffffd
    80005bfc:	f9e080e7          	jalr	-98(ra) # 80002b96 <fetchstr>
    80005c00:	00054663          	bltz	a0,80005c0c <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005c04:	0905                	addi	s2,s2,1
    80005c06:	09a1                	addi	s3,s3,8
    80005c08:	fb491be3          	bne	s2,s4,80005bbe <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c0c:	10048913          	addi	s2,s1,256
    80005c10:	6088                	ld	a0,0(s1)
    80005c12:	c531                	beqz	a0,80005c5e <sys_exec+0xf8>
    kfree(argv[i]);
    80005c14:	ffffb097          	auipc	ra,0xffffb
    80005c18:	dea080e7          	jalr	-534(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c1c:	04a1                	addi	s1,s1,8
    80005c1e:	ff2499e3          	bne	s1,s2,80005c10 <sys_exec+0xaa>
  return -1;
    80005c22:	557d                	li	a0,-1
    80005c24:	a835                	j	80005c60 <sys_exec+0xfa>
      argv[i] = 0;
    80005c26:	0a8e                	slli	s5,s5,0x3
    80005c28:	fc040793          	addi	a5,s0,-64
    80005c2c:	9abe                	add	s5,s5,a5
    80005c2e:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005c32:	e4040593          	addi	a1,s0,-448
    80005c36:	f4040513          	addi	a0,s0,-192
    80005c3a:	fffff097          	auipc	ra,0xfffff
    80005c3e:	190080e7          	jalr	400(ra) # 80004dca <exec>
    80005c42:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c44:	10048993          	addi	s3,s1,256
    80005c48:	6088                	ld	a0,0(s1)
    80005c4a:	c901                	beqz	a0,80005c5a <sys_exec+0xf4>
    kfree(argv[i]);
    80005c4c:	ffffb097          	auipc	ra,0xffffb
    80005c50:	db2080e7          	jalr	-590(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005c54:	04a1                	addi	s1,s1,8
    80005c56:	ff3499e3          	bne	s1,s3,80005c48 <sys_exec+0xe2>
  return ret;
    80005c5a:	854a                	mv	a0,s2
    80005c5c:	a011                	j	80005c60 <sys_exec+0xfa>
  return -1;
    80005c5e:	557d                	li	a0,-1
}
    80005c60:	60be                	ld	ra,456(sp)
    80005c62:	641e                	ld	s0,448(sp)
    80005c64:	74fa                	ld	s1,440(sp)
    80005c66:	795a                	ld	s2,432(sp)
    80005c68:	79ba                	ld	s3,424(sp)
    80005c6a:	7a1a                	ld	s4,416(sp)
    80005c6c:	6afa                	ld	s5,408(sp)
    80005c6e:	6179                	addi	sp,sp,464
    80005c70:	8082                	ret

0000000080005c72 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005c72:	7139                	addi	sp,sp,-64
    80005c74:	fc06                	sd	ra,56(sp)
    80005c76:	f822                	sd	s0,48(sp)
    80005c78:	f426                	sd	s1,40(sp)
    80005c7a:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005c7c:	ffffc097          	auipc	ra,0xffffc
    80005c80:	d4a080e7          	jalr	-694(ra) # 800019c6 <myproc>
    80005c84:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005c86:	fd840593          	addi	a1,s0,-40
    80005c8a:	4501                	li	a0,0
    80005c8c:	ffffd097          	auipc	ra,0xffffd
    80005c90:	f76080e7          	jalr	-138(ra) # 80002c02 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005c94:	fc840593          	addi	a1,s0,-56
    80005c98:	fd040513          	addi	a0,s0,-48
    80005c9c:	fffff097          	auipc	ra,0xfffff
    80005ca0:	dd6080e7          	jalr	-554(ra) # 80004a72 <pipealloc>
    return -1;
    80005ca4:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005ca6:	0c054463          	bltz	a0,80005d6e <sys_pipe+0xfc>
  fd0 = -1;
    80005caa:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005cae:	fd043503          	ld	a0,-48(s0)
    80005cb2:	fffff097          	auipc	ra,0xfffff
    80005cb6:	518080e7          	jalr	1304(ra) # 800051ca <fdalloc>
    80005cba:	fca42223          	sw	a0,-60(s0)
    80005cbe:	08054b63          	bltz	a0,80005d54 <sys_pipe+0xe2>
    80005cc2:	fc843503          	ld	a0,-56(s0)
    80005cc6:	fffff097          	auipc	ra,0xfffff
    80005cca:	504080e7          	jalr	1284(ra) # 800051ca <fdalloc>
    80005cce:	fca42023          	sw	a0,-64(s0)
    80005cd2:	06054863          	bltz	a0,80005d42 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005cd6:	4691                	li	a3,4
    80005cd8:	fc440613          	addi	a2,s0,-60
    80005cdc:	fd843583          	ld	a1,-40(s0)
    80005ce0:	68a8                	ld	a0,80(s1)
    80005ce2:	ffffc097          	auipc	ra,0xffffc
    80005ce6:	9a2080e7          	jalr	-1630(ra) # 80001684 <copyout>
    80005cea:	02054063          	bltz	a0,80005d0a <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005cee:	4691                	li	a3,4
    80005cf0:	fc040613          	addi	a2,s0,-64
    80005cf4:	fd843583          	ld	a1,-40(s0)
    80005cf8:	0591                	addi	a1,a1,4
    80005cfa:	68a8                	ld	a0,80(s1)
    80005cfc:	ffffc097          	auipc	ra,0xffffc
    80005d00:	988080e7          	jalr	-1656(ra) # 80001684 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005d04:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005d06:	06055463          	bgez	a0,80005d6e <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005d0a:	fc442783          	lw	a5,-60(s0)
    80005d0e:	07e9                	addi	a5,a5,26
    80005d10:	078e                	slli	a5,a5,0x3
    80005d12:	97a6                	add	a5,a5,s1
    80005d14:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005d18:	fc042503          	lw	a0,-64(s0)
    80005d1c:	0569                	addi	a0,a0,26
    80005d1e:	050e                	slli	a0,a0,0x3
    80005d20:	94aa                	add	s1,s1,a0
    80005d22:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005d26:	fd043503          	ld	a0,-48(s0)
    80005d2a:	fffff097          	auipc	ra,0xfffff
    80005d2e:	a0a080e7          	jalr	-1526(ra) # 80004734 <fileclose>
    fileclose(wf);
    80005d32:	fc843503          	ld	a0,-56(s0)
    80005d36:	fffff097          	auipc	ra,0xfffff
    80005d3a:	9fe080e7          	jalr	-1538(ra) # 80004734 <fileclose>
    return -1;
    80005d3e:	57fd                	li	a5,-1
    80005d40:	a03d                	j	80005d6e <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005d42:	fc442783          	lw	a5,-60(s0)
    80005d46:	0007c763          	bltz	a5,80005d54 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005d4a:	07e9                	addi	a5,a5,26
    80005d4c:	078e                	slli	a5,a5,0x3
    80005d4e:	94be                	add	s1,s1,a5
    80005d50:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005d54:	fd043503          	ld	a0,-48(s0)
    80005d58:	fffff097          	auipc	ra,0xfffff
    80005d5c:	9dc080e7          	jalr	-1572(ra) # 80004734 <fileclose>
    fileclose(wf);
    80005d60:	fc843503          	ld	a0,-56(s0)
    80005d64:	fffff097          	auipc	ra,0xfffff
    80005d68:	9d0080e7          	jalr	-1584(ra) # 80004734 <fileclose>
    return -1;
    80005d6c:	57fd                	li	a5,-1
}
    80005d6e:	853e                	mv	a0,a5
    80005d70:	70e2                	ld	ra,56(sp)
    80005d72:	7442                	ld	s0,48(sp)
    80005d74:	74a2                	ld	s1,40(sp)
    80005d76:	6121                	addi	sp,sp,64
    80005d78:	8082                	ret
    80005d7a:	0000                	unimp
    80005d7c:	0000                	unimp
	...

0000000080005d80 <kernelvec>:
    80005d80:	7111                	addi	sp,sp,-256
    80005d82:	e006                	sd	ra,0(sp)
    80005d84:	e40a                	sd	sp,8(sp)
    80005d86:	e80e                	sd	gp,16(sp)
    80005d88:	ec12                	sd	tp,24(sp)
    80005d8a:	f016                	sd	t0,32(sp)
    80005d8c:	f41a                	sd	t1,40(sp)
    80005d8e:	f81e                	sd	t2,48(sp)
    80005d90:	fc22                	sd	s0,56(sp)
    80005d92:	e0a6                	sd	s1,64(sp)
    80005d94:	e4aa                	sd	a0,72(sp)
    80005d96:	e8ae                	sd	a1,80(sp)
    80005d98:	ecb2                	sd	a2,88(sp)
    80005d9a:	f0b6                	sd	a3,96(sp)
    80005d9c:	f4ba                	sd	a4,104(sp)
    80005d9e:	f8be                	sd	a5,112(sp)
    80005da0:	fcc2                	sd	a6,120(sp)
    80005da2:	e146                	sd	a7,128(sp)
    80005da4:	e54a                	sd	s2,136(sp)
    80005da6:	e94e                	sd	s3,144(sp)
    80005da8:	ed52                	sd	s4,152(sp)
    80005daa:	f156                	sd	s5,160(sp)
    80005dac:	f55a                	sd	s6,168(sp)
    80005dae:	f95e                	sd	s7,176(sp)
    80005db0:	fd62                	sd	s8,184(sp)
    80005db2:	e1e6                	sd	s9,192(sp)
    80005db4:	e5ea                	sd	s10,200(sp)
    80005db6:	e9ee                	sd	s11,208(sp)
    80005db8:	edf2                	sd	t3,216(sp)
    80005dba:	f1f6                	sd	t4,224(sp)
    80005dbc:	f5fa                	sd	t5,232(sp)
    80005dbe:	f9fe                	sd	t6,240(sp)
    80005dc0:	c51fc0ef          	jal	ra,80002a10 <kerneltrap>
    80005dc4:	6082                	ld	ra,0(sp)
    80005dc6:	6122                	ld	sp,8(sp)
    80005dc8:	61c2                	ld	gp,16(sp)
    80005dca:	7282                	ld	t0,32(sp)
    80005dcc:	7322                	ld	t1,40(sp)
    80005dce:	73c2                	ld	t2,48(sp)
    80005dd0:	7462                	ld	s0,56(sp)
    80005dd2:	6486                	ld	s1,64(sp)
    80005dd4:	6526                	ld	a0,72(sp)
    80005dd6:	65c6                	ld	a1,80(sp)
    80005dd8:	6666                	ld	a2,88(sp)
    80005dda:	7686                	ld	a3,96(sp)
    80005ddc:	7726                	ld	a4,104(sp)
    80005dde:	77c6                	ld	a5,112(sp)
    80005de0:	7866                	ld	a6,120(sp)
    80005de2:	688a                	ld	a7,128(sp)
    80005de4:	692a                	ld	s2,136(sp)
    80005de6:	69ca                	ld	s3,144(sp)
    80005de8:	6a6a                	ld	s4,152(sp)
    80005dea:	7a8a                	ld	s5,160(sp)
    80005dec:	7b2a                	ld	s6,168(sp)
    80005dee:	7bca                	ld	s7,176(sp)
    80005df0:	7c6a                	ld	s8,184(sp)
    80005df2:	6c8e                	ld	s9,192(sp)
    80005df4:	6d2e                	ld	s10,200(sp)
    80005df6:	6dce                	ld	s11,208(sp)
    80005df8:	6e6e                	ld	t3,216(sp)
    80005dfa:	7e8e                	ld	t4,224(sp)
    80005dfc:	7f2e                	ld	t5,232(sp)
    80005dfe:	7fce                	ld	t6,240(sp)
    80005e00:	6111                	addi	sp,sp,256
    80005e02:	10200073          	sret
    80005e06:	00000013          	nop
    80005e0a:	00000013          	nop
    80005e0e:	0001                	nop

0000000080005e10 <timervec>:
    80005e10:	34051573          	csrrw	a0,mscratch,a0
    80005e14:	e10c                	sd	a1,0(a0)
    80005e16:	e510                	sd	a2,8(a0)
    80005e18:	e914                	sd	a3,16(a0)
    80005e1a:	6d0c                	ld	a1,24(a0)
    80005e1c:	7110                	ld	a2,32(a0)
    80005e1e:	6194                	ld	a3,0(a1)
    80005e20:	96b2                	add	a3,a3,a2
    80005e22:	e194                	sd	a3,0(a1)
    80005e24:	4589                	li	a1,2
    80005e26:	14459073          	csrw	sip,a1
    80005e2a:	6914                	ld	a3,16(a0)
    80005e2c:	6510                	ld	a2,8(a0)
    80005e2e:	610c                	ld	a1,0(a0)
    80005e30:	34051573          	csrrw	a0,mscratch,a0
    80005e34:	30200073          	mret
	...

0000000080005e3a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005e3a:	1141                	addi	sp,sp,-16
    80005e3c:	e422                	sd	s0,8(sp)
    80005e3e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005e40:	0c0007b7          	lui	a5,0xc000
    80005e44:	4705                	li	a4,1
    80005e46:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005e48:	c3d8                	sw	a4,4(a5)
}
    80005e4a:	6422                	ld	s0,8(sp)
    80005e4c:	0141                	addi	sp,sp,16
    80005e4e:	8082                	ret

0000000080005e50 <plicinithart>:

void
plicinithart(void)
{
    80005e50:	1141                	addi	sp,sp,-16
    80005e52:	e406                	sd	ra,8(sp)
    80005e54:	e022                	sd	s0,0(sp)
    80005e56:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e58:	ffffc097          	auipc	ra,0xffffc
    80005e5c:	b42080e7          	jalr	-1214(ra) # 8000199a <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005e60:	0085171b          	slliw	a4,a0,0x8
    80005e64:	0c0027b7          	lui	a5,0xc002
    80005e68:	97ba                	add	a5,a5,a4
    80005e6a:	40200713          	li	a4,1026
    80005e6e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005e72:	00d5151b          	slliw	a0,a0,0xd
    80005e76:	0c2017b7          	lui	a5,0xc201
    80005e7a:	953e                	add	a0,a0,a5
    80005e7c:	00052023          	sw	zero,0(a0)
}
    80005e80:	60a2                	ld	ra,8(sp)
    80005e82:	6402                	ld	s0,0(sp)
    80005e84:	0141                	addi	sp,sp,16
    80005e86:	8082                	ret

0000000080005e88 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005e88:	1141                	addi	sp,sp,-16
    80005e8a:	e406                	sd	ra,8(sp)
    80005e8c:	e022                	sd	s0,0(sp)
    80005e8e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e90:	ffffc097          	auipc	ra,0xffffc
    80005e94:	b0a080e7          	jalr	-1270(ra) # 8000199a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005e98:	00d5179b          	slliw	a5,a0,0xd
    80005e9c:	0c201537          	lui	a0,0xc201
    80005ea0:	953e                	add	a0,a0,a5
  return irq;
}
    80005ea2:	4148                	lw	a0,4(a0)
    80005ea4:	60a2                	ld	ra,8(sp)
    80005ea6:	6402                	ld	s0,0(sp)
    80005ea8:	0141                	addi	sp,sp,16
    80005eaa:	8082                	ret

0000000080005eac <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005eac:	1101                	addi	sp,sp,-32
    80005eae:	ec06                	sd	ra,24(sp)
    80005eb0:	e822                	sd	s0,16(sp)
    80005eb2:	e426                	sd	s1,8(sp)
    80005eb4:	1000                	addi	s0,sp,32
    80005eb6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005eb8:	ffffc097          	auipc	ra,0xffffc
    80005ebc:	ae2080e7          	jalr	-1310(ra) # 8000199a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005ec0:	00d5151b          	slliw	a0,a0,0xd
    80005ec4:	0c2017b7          	lui	a5,0xc201
    80005ec8:	97aa                	add	a5,a5,a0
    80005eca:	c3c4                	sw	s1,4(a5)
}
    80005ecc:	60e2                	ld	ra,24(sp)
    80005ece:	6442                	ld	s0,16(sp)
    80005ed0:	64a2                	ld	s1,8(sp)
    80005ed2:	6105                	addi	sp,sp,32
    80005ed4:	8082                	ret

0000000080005ed6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005ed6:	1141                	addi	sp,sp,-16
    80005ed8:	e406                	sd	ra,8(sp)
    80005eda:	e022                	sd	s0,0(sp)
    80005edc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005ede:	479d                	li	a5,7
    80005ee0:	04a7cc63          	blt	a5,a0,80005f38 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005ee4:	00024797          	auipc	a5,0x24
    80005ee8:	36478793          	addi	a5,a5,868 # 8002a248 <disk>
    80005eec:	97aa                	add	a5,a5,a0
    80005eee:	0187c783          	lbu	a5,24(a5)
    80005ef2:	ebb9                	bnez	a5,80005f48 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005ef4:	00451613          	slli	a2,a0,0x4
    80005ef8:	00024797          	auipc	a5,0x24
    80005efc:	35078793          	addi	a5,a5,848 # 8002a248 <disk>
    80005f00:	6394                	ld	a3,0(a5)
    80005f02:	96b2                	add	a3,a3,a2
    80005f04:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005f08:	6398                	ld	a4,0(a5)
    80005f0a:	9732                	add	a4,a4,a2
    80005f0c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005f10:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005f14:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005f18:	953e                	add	a0,a0,a5
    80005f1a:	4785                	li	a5,1
    80005f1c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80005f20:	00024517          	auipc	a0,0x24
    80005f24:	34050513          	addi	a0,a0,832 # 8002a260 <disk+0x18>
    80005f28:	ffffc097          	auipc	ra,0xffffc
    80005f2c:	246080e7          	jalr	582(ra) # 8000216e <wakeup>
}
    80005f30:	60a2                	ld	ra,8(sp)
    80005f32:	6402                	ld	s0,0(sp)
    80005f34:	0141                	addi	sp,sp,16
    80005f36:	8082                	ret
    panic("free_desc 1");
    80005f38:	00003517          	auipc	a0,0x3
    80005f3c:	a0850513          	addi	a0,a0,-1528 # 80008940 <syscalls+0x350>
    80005f40:	ffffa097          	auipc	ra,0xffffa
    80005f44:	604080e7          	jalr	1540(ra) # 80000544 <panic>
    panic("free_desc 2");
    80005f48:	00003517          	auipc	a0,0x3
    80005f4c:	a0850513          	addi	a0,a0,-1528 # 80008950 <syscalls+0x360>
    80005f50:	ffffa097          	auipc	ra,0xffffa
    80005f54:	5f4080e7          	jalr	1524(ra) # 80000544 <panic>

0000000080005f58 <virtio_disk_init>:
{
    80005f58:	1101                	addi	sp,sp,-32
    80005f5a:	ec06                	sd	ra,24(sp)
    80005f5c:	e822                	sd	s0,16(sp)
    80005f5e:	e426                	sd	s1,8(sp)
    80005f60:	e04a                	sd	s2,0(sp)
    80005f62:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005f64:	00003597          	auipc	a1,0x3
    80005f68:	9fc58593          	addi	a1,a1,-1540 # 80008960 <syscalls+0x370>
    80005f6c:	00024517          	auipc	a0,0x24
    80005f70:	40450513          	addi	a0,a0,1028 # 8002a370 <disk+0x128>
    80005f74:	ffffb097          	auipc	ra,0xffffb
    80005f78:	be6080e7          	jalr	-1050(ra) # 80000b5a <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f7c:	100017b7          	lui	a5,0x10001
    80005f80:	4398                	lw	a4,0(a5)
    80005f82:	2701                	sext.w	a4,a4
    80005f84:	747277b7          	lui	a5,0x74727
    80005f88:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005f8c:	14f71e63          	bne	a4,a5,800060e8 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005f90:	100017b7          	lui	a5,0x10001
    80005f94:	43dc                	lw	a5,4(a5)
    80005f96:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f98:	4709                	li	a4,2
    80005f9a:	14e79763          	bne	a5,a4,800060e8 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f9e:	100017b7          	lui	a5,0x10001
    80005fa2:	479c                	lw	a5,8(a5)
    80005fa4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005fa6:	14e79163          	bne	a5,a4,800060e8 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005faa:	100017b7          	lui	a5,0x10001
    80005fae:	47d8                	lw	a4,12(a5)
    80005fb0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005fb2:	554d47b7          	lui	a5,0x554d4
    80005fb6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005fba:	12f71763          	bne	a4,a5,800060e8 <virtio_disk_init+0x190>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fbe:	100017b7          	lui	a5,0x10001
    80005fc2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fc6:	4705                	li	a4,1
    80005fc8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fca:	470d                	li	a4,3
    80005fcc:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005fce:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005fd0:	c7ffe737          	lui	a4,0xc7ffe
    80005fd4:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd43d7>
    80005fd8:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005fda:	2701                	sext.w	a4,a4
    80005fdc:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fde:	472d                	li	a4,11
    80005fe0:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005fe2:	0707a903          	lw	s2,112(a5)
    80005fe6:	2901                	sext.w	s2,s2
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005fe8:	00897793          	andi	a5,s2,8
    80005fec:	10078663          	beqz	a5,800060f8 <virtio_disk_init+0x1a0>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005ff0:	100017b7          	lui	a5,0x10001
    80005ff4:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005ff8:	43fc                	lw	a5,68(a5)
    80005ffa:	2781                	sext.w	a5,a5
    80005ffc:	10079663          	bnez	a5,80006108 <virtio_disk_init+0x1b0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006000:	100017b7          	lui	a5,0x10001
    80006004:	5bdc                	lw	a5,52(a5)
    80006006:	2781                	sext.w	a5,a5
  if(max == 0)
    80006008:	10078863          	beqz	a5,80006118 <virtio_disk_init+0x1c0>
  if(max < NUM)
    8000600c:	471d                	li	a4,7
    8000600e:	10f77d63          	bgeu	a4,a5,80006128 <virtio_disk_init+0x1d0>
  disk.desc = kalloc();
    80006012:	ffffb097          	auipc	ra,0xffffb
    80006016:	ae8080e7          	jalr	-1304(ra) # 80000afa <kalloc>
    8000601a:	00024497          	auipc	s1,0x24
    8000601e:	22e48493          	addi	s1,s1,558 # 8002a248 <disk>
    80006022:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006024:	ffffb097          	auipc	ra,0xffffb
    80006028:	ad6080e7          	jalr	-1322(ra) # 80000afa <kalloc>
    8000602c:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000602e:	ffffb097          	auipc	ra,0xffffb
    80006032:	acc080e7          	jalr	-1332(ra) # 80000afa <kalloc>
    80006036:	87aa                	mv	a5,a0
    80006038:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    8000603a:	6088                	ld	a0,0(s1)
    8000603c:	cd75                	beqz	a0,80006138 <virtio_disk_init+0x1e0>
    8000603e:	00024717          	auipc	a4,0x24
    80006042:	21273703          	ld	a4,530(a4) # 8002a250 <disk+0x8>
    80006046:	cb6d                	beqz	a4,80006138 <virtio_disk_init+0x1e0>
    80006048:	cbe5                	beqz	a5,80006138 <virtio_disk_init+0x1e0>
  memset(disk.desc, 0, PGSIZE);
    8000604a:	6605                	lui	a2,0x1
    8000604c:	4581                	li	a1,0
    8000604e:	ffffb097          	auipc	ra,0xffffb
    80006052:	c98080e7          	jalr	-872(ra) # 80000ce6 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006056:	00024497          	auipc	s1,0x24
    8000605a:	1f248493          	addi	s1,s1,498 # 8002a248 <disk>
    8000605e:	6605                	lui	a2,0x1
    80006060:	4581                	li	a1,0
    80006062:	6488                	ld	a0,8(s1)
    80006064:	ffffb097          	auipc	ra,0xffffb
    80006068:	c82080e7          	jalr	-894(ra) # 80000ce6 <memset>
  memset(disk.used, 0, PGSIZE);
    8000606c:	6605                	lui	a2,0x1
    8000606e:	4581                	li	a1,0
    80006070:	6888                	ld	a0,16(s1)
    80006072:	ffffb097          	auipc	ra,0xffffb
    80006076:	c74080e7          	jalr	-908(ra) # 80000ce6 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    8000607a:	100017b7          	lui	a5,0x10001
    8000607e:	4721                	li	a4,8
    80006080:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006082:	4098                	lw	a4,0(s1)
    80006084:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006088:	40d8                	lw	a4,4(s1)
    8000608a:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000608e:	6498                	ld	a4,8(s1)
    80006090:	0007069b          	sext.w	a3,a4
    80006094:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006098:	9701                	srai	a4,a4,0x20
    8000609a:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000609e:	6898                	ld	a4,16(s1)
    800060a0:	0007069b          	sext.w	a3,a4
    800060a4:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800060a8:	9701                	srai	a4,a4,0x20
    800060aa:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800060ae:	4685                	li	a3,1
    800060b0:	c3f4                	sw	a3,68(a5)
    disk.free[i] = 1;
    800060b2:	4705                	li	a4,1
    800060b4:	00d48c23          	sb	a3,24(s1)
    800060b8:	00e48ca3          	sb	a4,25(s1)
    800060bc:	00e48d23          	sb	a4,26(s1)
    800060c0:	00e48da3          	sb	a4,27(s1)
    800060c4:	00e48e23          	sb	a4,28(s1)
    800060c8:	00e48ea3          	sb	a4,29(s1)
    800060cc:	00e48f23          	sb	a4,30(s1)
    800060d0:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    800060d4:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    800060d8:	0727a823          	sw	s2,112(a5)
}
    800060dc:	60e2                	ld	ra,24(sp)
    800060de:	6442                	ld	s0,16(sp)
    800060e0:	64a2                	ld	s1,8(sp)
    800060e2:	6902                	ld	s2,0(sp)
    800060e4:	6105                	addi	sp,sp,32
    800060e6:	8082                	ret
    panic("could not find virtio disk");
    800060e8:	00003517          	auipc	a0,0x3
    800060ec:	88850513          	addi	a0,a0,-1912 # 80008970 <syscalls+0x380>
    800060f0:	ffffa097          	auipc	ra,0xffffa
    800060f4:	454080e7          	jalr	1108(ra) # 80000544 <panic>
    panic("virtio disk FEATURES_OK unset");
    800060f8:	00003517          	auipc	a0,0x3
    800060fc:	89850513          	addi	a0,a0,-1896 # 80008990 <syscalls+0x3a0>
    80006100:	ffffa097          	auipc	ra,0xffffa
    80006104:	444080e7          	jalr	1092(ra) # 80000544 <panic>
    panic("virtio disk should not be ready");
    80006108:	00003517          	auipc	a0,0x3
    8000610c:	8a850513          	addi	a0,a0,-1880 # 800089b0 <syscalls+0x3c0>
    80006110:	ffffa097          	auipc	ra,0xffffa
    80006114:	434080e7          	jalr	1076(ra) # 80000544 <panic>
    panic("virtio disk has no queue 0");
    80006118:	00003517          	auipc	a0,0x3
    8000611c:	8b850513          	addi	a0,a0,-1864 # 800089d0 <syscalls+0x3e0>
    80006120:	ffffa097          	auipc	ra,0xffffa
    80006124:	424080e7          	jalr	1060(ra) # 80000544 <panic>
    panic("virtio disk max queue too short");
    80006128:	00003517          	auipc	a0,0x3
    8000612c:	8c850513          	addi	a0,a0,-1848 # 800089f0 <syscalls+0x400>
    80006130:	ffffa097          	auipc	ra,0xffffa
    80006134:	414080e7          	jalr	1044(ra) # 80000544 <panic>
    panic("virtio disk kalloc");
    80006138:	00003517          	auipc	a0,0x3
    8000613c:	8d850513          	addi	a0,a0,-1832 # 80008a10 <syscalls+0x420>
    80006140:	ffffa097          	auipc	ra,0xffffa
    80006144:	404080e7          	jalr	1028(ra) # 80000544 <panic>

0000000080006148 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006148:	7159                	addi	sp,sp,-112
    8000614a:	f486                	sd	ra,104(sp)
    8000614c:	f0a2                	sd	s0,96(sp)
    8000614e:	eca6                	sd	s1,88(sp)
    80006150:	e8ca                	sd	s2,80(sp)
    80006152:	e4ce                	sd	s3,72(sp)
    80006154:	e0d2                	sd	s4,64(sp)
    80006156:	fc56                	sd	s5,56(sp)
    80006158:	f85a                	sd	s6,48(sp)
    8000615a:	f45e                	sd	s7,40(sp)
    8000615c:	f062                	sd	s8,32(sp)
    8000615e:	ec66                	sd	s9,24(sp)
    80006160:	e86a                	sd	s10,16(sp)
    80006162:	1880                	addi	s0,sp,112
    80006164:	892a                	mv	s2,a0
    80006166:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006168:	00c52c83          	lw	s9,12(a0)
    8000616c:	001c9c9b          	slliw	s9,s9,0x1
    80006170:	1c82                	slli	s9,s9,0x20
    80006172:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006176:	00024517          	auipc	a0,0x24
    8000617a:	1fa50513          	addi	a0,a0,506 # 8002a370 <disk+0x128>
    8000617e:	ffffb097          	auipc	ra,0xffffb
    80006182:	a6c080e7          	jalr	-1428(ra) # 80000bea <acquire>
  for(int i = 0; i < 3; i++){
    80006186:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006188:	4ba1                	li	s7,8
      disk.free[i] = 0;
    8000618a:	00024b17          	auipc	s6,0x24
    8000618e:	0beb0b13          	addi	s6,s6,190 # 8002a248 <disk>
  for(int i = 0; i < 3; i++){
    80006192:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006194:	8a4e                	mv	s4,s3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006196:	00024c17          	auipc	s8,0x24
    8000619a:	1dac0c13          	addi	s8,s8,474 # 8002a370 <disk+0x128>
    8000619e:	a8b5                	j	8000621a <virtio_disk_rw+0xd2>
      disk.free[i] = 0;
    800061a0:	00fb06b3          	add	a3,s6,a5
    800061a4:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800061a8:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800061aa:	0207c563          	bltz	a5,800061d4 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    800061ae:	2485                	addiw	s1,s1,1
    800061b0:	0711                	addi	a4,a4,4
    800061b2:	1f548a63          	beq	s1,s5,800063a6 <virtio_disk_rw+0x25e>
    idx[i] = alloc_desc();
    800061b6:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800061b8:	00024697          	auipc	a3,0x24
    800061bc:	09068693          	addi	a3,a3,144 # 8002a248 <disk>
    800061c0:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800061c2:	0186c583          	lbu	a1,24(a3)
    800061c6:	fde9                	bnez	a1,800061a0 <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    800061c8:	2785                	addiw	a5,a5,1
    800061ca:	0685                	addi	a3,a3,1
    800061cc:	ff779be3          	bne	a5,s7,800061c2 <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    800061d0:	57fd                	li	a5,-1
    800061d2:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800061d4:	02905a63          	blez	s1,80006208 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    800061d8:	f9042503          	lw	a0,-112(s0)
    800061dc:	00000097          	auipc	ra,0x0
    800061e0:	cfa080e7          	jalr	-774(ra) # 80005ed6 <free_desc>
      for(int j = 0; j < i; j++)
    800061e4:	4785                	li	a5,1
    800061e6:	0297d163          	bge	a5,s1,80006208 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    800061ea:	f9442503          	lw	a0,-108(s0)
    800061ee:	00000097          	auipc	ra,0x0
    800061f2:	ce8080e7          	jalr	-792(ra) # 80005ed6 <free_desc>
      for(int j = 0; j < i; j++)
    800061f6:	4789                	li	a5,2
    800061f8:	0097d863          	bge	a5,s1,80006208 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    800061fc:	f9842503          	lw	a0,-104(s0)
    80006200:	00000097          	auipc	ra,0x0
    80006204:	cd6080e7          	jalr	-810(ra) # 80005ed6 <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006208:	85e2                	mv	a1,s8
    8000620a:	00024517          	auipc	a0,0x24
    8000620e:	05650513          	addi	a0,a0,86 # 8002a260 <disk+0x18>
    80006212:	ffffc097          	auipc	ra,0xffffc
    80006216:	ef8080e7          	jalr	-264(ra) # 8000210a <sleep>
  for(int i = 0; i < 3; i++){
    8000621a:	f9040713          	addi	a4,s0,-112
    8000621e:	84ce                	mv	s1,s3
    80006220:	bf59                	j	800061b6 <virtio_disk_rw+0x6e>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006222:	00a60793          	addi	a5,a2,10 # 100a <_entry-0x7fffeff6>
    80006226:	00479693          	slli	a3,a5,0x4
    8000622a:	00024797          	auipc	a5,0x24
    8000622e:	01e78793          	addi	a5,a5,30 # 8002a248 <disk>
    80006232:	97b6                	add	a5,a5,a3
    80006234:	4685                	li	a3,1
    80006236:	c794                	sw	a3,8(a5)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006238:	00024597          	auipc	a1,0x24
    8000623c:	01058593          	addi	a1,a1,16 # 8002a248 <disk>
    80006240:	00a60793          	addi	a5,a2,10
    80006244:	0792                	slli	a5,a5,0x4
    80006246:	97ae                	add	a5,a5,a1
    80006248:	0007a623          	sw	zero,12(a5)
  buf0->sector = sector;
    8000624c:	0197b823          	sd	s9,16(a5)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006250:	f6070693          	addi	a3,a4,-160
    80006254:	619c                	ld	a5,0(a1)
    80006256:	97b6                	add	a5,a5,a3
    80006258:	e388                	sd	a0,0(a5)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000625a:	6188                	ld	a0,0(a1)
    8000625c:	96aa                	add	a3,a3,a0
    8000625e:	47c1                	li	a5,16
    80006260:	c69c                	sw	a5,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006262:	4785                	li	a5,1
    80006264:	00f69623          	sh	a5,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006268:	f9442783          	lw	a5,-108(s0)
    8000626c:	00f69723          	sh	a5,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006270:	0792                	slli	a5,a5,0x4
    80006272:	953e                	add	a0,a0,a5
    80006274:	05890693          	addi	a3,s2,88
    80006278:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000627a:	6188                	ld	a0,0(a1)
    8000627c:	97aa                	add	a5,a5,a0
    8000627e:	40000693          	li	a3,1024
    80006282:	c794                	sw	a3,8(a5)
  if(write)
    80006284:	100d0d63          	beqz	s10,8000639e <virtio_disk_rw+0x256>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006288:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000628c:	00c7d683          	lhu	a3,12(a5)
    80006290:	0016e693          	ori	a3,a3,1
    80006294:	00d79623          	sh	a3,12(a5)
  disk.desc[idx[1]].next = idx[2];
    80006298:	f9842583          	lw	a1,-104(s0)
    8000629c:	00b79723          	sh	a1,14(a5)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800062a0:	00024697          	auipc	a3,0x24
    800062a4:	fa868693          	addi	a3,a3,-88 # 8002a248 <disk>
    800062a8:	00260793          	addi	a5,a2,2
    800062ac:	0792                	slli	a5,a5,0x4
    800062ae:	97b6                	add	a5,a5,a3
    800062b0:	587d                	li	a6,-1
    800062b2:	01078823          	sb	a6,16(a5)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800062b6:	0592                	slli	a1,a1,0x4
    800062b8:	952e                	add	a0,a0,a1
    800062ba:	f9070713          	addi	a4,a4,-112
    800062be:	9736                	add	a4,a4,a3
    800062c0:	e118                	sd	a4,0(a0)
  disk.desc[idx[2]].len = 1;
    800062c2:	6298                	ld	a4,0(a3)
    800062c4:	972e                	add	a4,a4,a1
    800062c6:	4585                	li	a1,1
    800062c8:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800062ca:	4509                	li	a0,2
    800062cc:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[2]].next = 0;
    800062d0:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800062d4:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    800062d8:	0127b423          	sd	s2,8(a5)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800062dc:	6698                	ld	a4,8(a3)
    800062de:	00275783          	lhu	a5,2(a4)
    800062e2:	8b9d                	andi	a5,a5,7
    800062e4:	0786                	slli	a5,a5,0x1
    800062e6:	97ba                	add	a5,a5,a4
    800062e8:	00c79223          	sh	a2,4(a5)

  __sync_synchronize();
    800062ec:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800062f0:	6698                	ld	a4,8(a3)
    800062f2:	00275783          	lhu	a5,2(a4)
    800062f6:	2785                	addiw	a5,a5,1
    800062f8:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800062fc:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006300:	100017b7          	lui	a5,0x10001
    80006304:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006308:	00492703          	lw	a4,4(s2)
    8000630c:	4785                	li	a5,1
    8000630e:	02f71163          	bne	a4,a5,80006330 <virtio_disk_rw+0x1e8>
    sleep(b, &disk.vdisk_lock);
    80006312:	00024997          	auipc	s3,0x24
    80006316:	05e98993          	addi	s3,s3,94 # 8002a370 <disk+0x128>
  while(b->disk == 1) {
    8000631a:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    8000631c:	85ce                	mv	a1,s3
    8000631e:	854a                	mv	a0,s2
    80006320:	ffffc097          	auipc	ra,0xffffc
    80006324:	dea080e7          	jalr	-534(ra) # 8000210a <sleep>
  while(b->disk == 1) {
    80006328:	00492783          	lw	a5,4(s2)
    8000632c:	fe9788e3          	beq	a5,s1,8000631c <virtio_disk_rw+0x1d4>
  }

  disk.info[idx[0]].b = 0;
    80006330:	f9042903          	lw	s2,-112(s0)
    80006334:	00290793          	addi	a5,s2,2
    80006338:	00479713          	slli	a4,a5,0x4
    8000633c:	00024797          	auipc	a5,0x24
    80006340:	f0c78793          	addi	a5,a5,-244 # 8002a248 <disk>
    80006344:	97ba                	add	a5,a5,a4
    80006346:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000634a:	00024997          	auipc	s3,0x24
    8000634e:	efe98993          	addi	s3,s3,-258 # 8002a248 <disk>
    80006352:	00491713          	slli	a4,s2,0x4
    80006356:	0009b783          	ld	a5,0(s3)
    8000635a:	97ba                	add	a5,a5,a4
    8000635c:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006360:	854a                	mv	a0,s2
    80006362:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006366:	00000097          	auipc	ra,0x0
    8000636a:	b70080e7          	jalr	-1168(ra) # 80005ed6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000636e:	8885                	andi	s1,s1,1
    80006370:	f0ed                	bnez	s1,80006352 <virtio_disk_rw+0x20a>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006372:	00024517          	auipc	a0,0x24
    80006376:	ffe50513          	addi	a0,a0,-2 # 8002a370 <disk+0x128>
    8000637a:	ffffb097          	auipc	ra,0xffffb
    8000637e:	924080e7          	jalr	-1756(ra) # 80000c9e <release>
}
    80006382:	70a6                	ld	ra,104(sp)
    80006384:	7406                	ld	s0,96(sp)
    80006386:	64e6                	ld	s1,88(sp)
    80006388:	6946                	ld	s2,80(sp)
    8000638a:	69a6                	ld	s3,72(sp)
    8000638c:	6a06                	ld	s4,64(sp)
    8000638e:	7ae2                	ld	s5,56(sp)
    80006390:	7b42                	ld	s6,48(sp)
    80006392:	7ba2                	ld	s7,40(sp)
    80006394:	7c02                	ld	s8,32(sp)
    80006396:	6ce2                	ld	s9,24(sp)
    80006398:	6d42                	ld	s10,16(sp)
    8000639a:	6165                	addi	sp,sp,112
    8000639c:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000639e:	4689                	li	a3,2
    800063a0:	00d79623          	sh	a3,12(a5)
    800063a4:	b5e5                	j	8000628c <virtio_disk_rw+0x144>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800063a6:	f9042603          	lw	a2,-112(s0)
    800063aa:	00a60713          	addi	a4,a2,10
    800063ae:	0712                	slli	a4,a4,0x4
    800063b0:	00024517          	auipc	a0,0x24
    800063b4:	ea050513          	addi	a0,a0,-352 # 8002a250 <disk+0x8>
    800063b8:	953a                	add	a0,a0,a4
  if(write)
    800063ba:	e60d14e3          	bnez	s10,80006222 <virtio_disk_rw+0xda>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800063be:	00a60793          	addi	a5,a2,10
    800063c2:	00479693          	slli	a3,a5,0x4
    800063c6:	00024797          	auipc	a5,0x24
    800063ca:	e8278793          	addi	a5,a5,-382 # 8002a248 <disk>
    800063ce:	97b6                	add	a5,a5,a3
    800063d0:	0007a423          	sw	zero,8(a5)
    800063d4:	b595                	j	80006238 <virtio_disk_rw+0xf0>

00000000800063d6 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800063d6:	1101                	addi	sp,sp,-32
    800063d8:	ec06                	sd	ra,24(sp)
    800063da:	e822                	sd	s0,16(sp)
    800063dc:	e426                	sd	s1,8(sp)
    800063de:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800063e0:	00024497          	auipc	s1,0x24
    800063e4:	e6848493          	addi	s1,s1,-408 # 8002a248 <disk>
    800063e8:	00024517          	auipc	a0,0x24
    800063ec:	f8850513          	addi	a0,a0,-120 # 8002a370 <disk+0x128>
    800063f0:	ffffa097          	auipc	ra,0xffffa
    800063f4:	7fa080e7          	jalr	2042(ra) # 80000bea <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800063f8:	10001737          	lui	a4,0x10001
    800063fc:	533c                	lw	a5,96(a4)
    800063fe:	8b8d                	andi	a5,a5,3
    80006400:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006402:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006406:	689c                	ld	a5,16(s1)
    80006408:	0204d703          	lhu	a4,32(s1)
    8000640c:	0027d783          	lhu	a5,2(a5)
    80006410:	04f70863          	beq	a4,a5,80006460 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006414:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006418:	6898                	ld	a4,16(s1)
    8000641a:	0204d783          	lhu	a5,32(s1)
    8000641e:	8b9d                	andi	a5,a5,7
    80006420:	078e                	slli	a5,a5,0x3
    80006422:	97ba                	add	a5,a5,a4
    80006424:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006426:	00278713          	addi	a4,a5,2
    8000642a:	0712                	slli	a4,a4,0x4
    8000642c:	9726                	add	a4,a4,s1
    8000642e:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006432:	e721                	bnez	a4,8000647a <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006434:	0789                	addi	a5,a5,2
    80006436:	0792                	slli	a5,a5,0x4
    80006438:	97a6                	add	a5,a5,s1
    8000643a:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000643c:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006440:	ffffc097          	auipc	ra,0xffffc
    80006444:	d2e080e7          	jalr	-722(ra) # 8000216e <wakeup>

    disk.used_idx += 1;
    80006448:	0204d783          	lhu	a5,32(s1)
    8000644c:	2785                	addiw	a5,a5,1
    8000644e:	17c2                	slli	a5,a5,0x30
    80006450:	93c1                	srli	a5,a5,0x30
    80006452:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006456:	6898                	ld	a4,16(s1)
    80006458:	00275703          	lhu	a4,2(a4)
    8000645c:	faf71ce3          	bne	a4,a5,80006414 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006460:	00024517          	auipc	a0,0x24
    80006464:	f1050513          	addi	a0,a0,-240 # 8002a370 <disk+0x128>
    80006468:	ffffb097          	auipc	ra,0xffffb
    8000646c:	836080e7          	jalr	-1994(ra) # 80000c9e <release>
}
    80006470:	60e2                	ld	ra,24(sp)
    80006472:	6442                	ld	s0,16(sp)
    80006474:	64a2                	ld	s1,8(sp)
    80006476:	6105                	addi	sp,sp,32
    80006478:	8082                	ret
      panic("virtio_disk_intr status");
    8000647a:	00002517          	auipc	a0,0x2
    8000647e:	5ae50513          	addi	a0,a0,1454 # 80008a28 <syscalls+0x438>
    80006482:	ffffa097          	auipc	ra,0xffffa
    80006486:	0c2080e7          	jalr	194(ra) # 80000544 <panic>

000000008000648a <kfilewrite>:
int
kfilewrite(struct file *f, uint64 addr, int n)
{
    8000648a:	715d                	addi	sp,sp,-80
    8000648c:	e486                	sd	ra,72(sp)
    8000648e:	e0a2                	sd	s0,64(sp)
    80006490:	fc26                	sd	s1,56(sp)
    80006492:	f84a                	sd	s2,48(sp)
    80006494:	f44e                	sd	s3,40(sp)
    80006496:	f052                	sd	s4,32(sp)
    80006498:	ec56                	sd	s5,24(sp)
    8000649a:	e85a                	sd	s6,16(sp)
    8000649c:	e45e                	sd	s7,8(sp)
    8000649e:	e062                	sd	s8,0(sp)
    800064a0:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0){
    800064a2:	00954783          	lbu	a5,9(a0)
    800064a6:	cb85                	beqz	a5,800064d6 <kfilewrite+0x4c>
    800064a8:	892a                	mv	s2,a0
    800064aa:	8aae                	mv	s5,a1
    800064ac:	8a32                	mv	s4,a2
    printf("First\n");
    return -1;
  }
  if(f->type == FD_PIPE){
    800064ae:	411c                	lw	a5,0(a0)
    800064b0:	4705                	li	a4,1
    800064b2:	02e78c63          	beq	a5,a4,800064ea <kfilewrite+0x60>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800064b6:	470d                	li	a4,3
    800064b8:	04e78063          	beq	a5,a4,800064f8 <kfilewrite+0x6e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write){
      return -1;
    }
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800064bc:	4709                	li	a4,2
    800064be:	0ee79b63          	bne	a5,a4,800065b4 <kfilewrite+0x12a>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800064c2:	0cc05763          	blez	a2,80006590 <kfilewrite+0x106>
    int i = 0;
    800064c6:	4981                	li	s3,0
    800064c8:	6b05                	lui	s6,0x1
    800064ca:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800064ce:	6b85                	lui	s7,0x1
    800064d0:	c00b8b9b          	addiw	s7,s7,-1024
    800064d4:	a075                	j	80006580 <kfilewrite+0xf6>
    printf("First\n");
    800064d6:	00002517          	auipc	a0,0x2
    800064da:	3e250513          	addi	a0,a0,994 # 800088b8 <syscalls+0x2c8>
    800064de:	ffffa097          	auipc	ra,0xffffa
    800064e2:	0b0080e7          	jalr	176(ra) # 8000058e <printf>
    return -1;
    800064e6:	5a7d                	li	s4,-1
    800064e8:	a07d                	j	80006596 <kfilewrite+0x10c>
    ret = pipewrite(f->pipe, addr, n);
    800064ea:	6908                	ld	a0,16(a0)
    800064ec:	ffffe097          	auipc	ra,0xffffe
    800064f0:	6d0080e7          	jalr	1744(ra) # 80004bbc <pipewrite>
    800064f4:	8a2a                	mv	s4,a0
    800064f6:	a045                	j	80006596 <kfilewrite+0x10c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write){
    800064f8:	02451783          	lh	a5,36(a0)
    800064fc:	03079693          	slli	a3,a5,0x30
    80006500:	92c1                	srli	a3,a3,0x30
    80006502:	4725                	li	a4,9
    80006504:	0cd76063          	bltu	a4,a3,800065c4 <kfilewrite+0x13a>
    80006508:	0792                	slli	a5,a5,0x4
    8000650a:	00023717          	auipc	a4,0x23
    8000650e:	ce670713          	addi	a4,a4,-794 # 800291f0 <devsw>
    80006512:	97ba                	add	a5,a5,a4
    80006514:	679c                	ld	a5,8(a5)
    80006516:	cbcd                	beqz	a5,800065c8 <kfilewrite+0x13e>
    ret = devsw[f->major].write(1, addr, n);
    80006518:	4505                	li	a0,1
    8000651a:	9782                	jalr	a5
    8000651c:	8a2a                	mv	s4,a0
    8000651e:	a8a5                	j	80006596 <kfilewrite+0x10c>
    80006520:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80006524:	ffffe097          	auipc	ra,0xffffe
    80006528:	d44080e7          	jalr	-700(ra) # 80004268 <begin_op>
      ilock(f->ip);
    8000652c:	01893503          	ld	a0,24(s2)
    80006530:	ffffd097          	auipc	ra,0xffffd
    80006534:	34e080e7          	jalr	846(ra) # 8000387e <ilock>
      if ((r = writei(f->ip, 0, addr + i, f->off, n1)) > 0)
    80006538:	8762                	mv	a4,s8
    8000653a:	02092683          	lw	a3,32(s2)
    8000653e:	01598633          	add	a2,s3,s5
    80006542:	4581                	li	a1,0
    80006544:	01893503          	ld	a0,24(s2)
    80006548:	ffffd097          	auipc	ra,0xffffd
    8000654c:	6e2080e7          	jalr	1762(ra) # 80003c2a <writei>
    80006550:	84aa                	mv	s1,a0
    80006552:	00a05763          	blez	a0,80006560 <kfilewrite+0xd6>
        f->off += r;
    80006556:	02092783          	lw	a5,32(s2)
    8000655a:	9fa9                	addw	a5,a5,a0
    8000655c:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80006560:	01893503          	ld	a0,24(s2)
    80006564:	ffffd097          	auipc	ra,0xffffd
    80006568:	3dc080e7          	jalr	988(ra) # 80003940 <iunlock>
      end_op();
    8000656c:	ffffe097          	auipc	ra,0xffffe
    80006570:	d7c080e7          	jalr	-644(ra) # 800042e8 <end_op>

      if(r != n1){
    80006574:	009c1f63          	bne	s8,s1,80006592 <kfilewrite+0x108>
        // error from writei
        break;
      }
      i += r;
    80006578:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000657c:	0149db63          	bge	s3,s4,80006592 <kfilewrite+0x108>
      int n1 = n - i;
    80006580:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80006584:	84be                	mv	s1,a5
    80006586:	2781                	sext.w	a5,a5
    80006588:	f8fb5ce3          	bge	s6,a5,80006520 <kfilewrite+0x96>
    8000658c:	84de                	mv	s1,s7
    8000658e:	bf49                	j	80006520 <kfilewrite+0x96>
    int i = 0;
    80006590:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80006592:	013a1f63          	bne	s4,s3,800065b0 <kfilewrite+0x126>
  } else {
    panic("filewrite");
  }
  return ret;
}
    80006596:	8552                	mv	a0,s4
    80006598:	60a6                	ld	ra,72(sp)
    8000659a:	6406                	ld	s0,64(sp)
    8000659c:	74e2                	ld	s1,56(sp)
    8000659e:	7942                	ld	s2,48(sp)
    800065a0:	79a2                	ld	s3,40(sp)
    800065a2:	7a02                	ld	s4,32(sp)
    800065a4:	6ae2                	ld	s5,24(sp)
    800065a6:	6b42                	ld	s6,16(sp)
    800065a8:	6ba2                	ld	s7,8(sp)
    800065aa:	6c02                	ld	s8,0(sp)
    800065ac:	6161                	addi	sp,sp,80
    800065ae:	8082                	ret
    ret = (i == n ? n : -1);
    800065b0:	5a7d                	li	s4,-1
    800065b2:	b7d5                	j	80006596 <kfilewrite+0x10c>
    panic("filewrite");
    800065b4:	00002517          	auipc	a0,0x2
    800065b8:	30c50513          	addi	a0,a0,780 # 800088c0 <syscalls+0x2d0>
    800065bc:	ffffa097          	auipc	ra,0xffffa
    800065c0:	f88080e7          	jalr	-120(ra) # 80000544 <panic>
      return -1;
    800065c4:	5a7d                	li	s4,-1
    800065c6:	bfc1                	j	80006596 <kfilewrite+0x10c>
    800065c8:	5a7d                	li	s4,-1
    800065ca:	b7f1                	j	80006596 <kfilewrite+0x10c>

00000000800065cc <fdalloc>:

int
fdalloc(struct file *f)
{
    800065cc:	1101                	addi	sp,sp,-32
    800065ce:	ec06                	sd	ra,24(sp)
    800065d0:	e822                	sd	s0,16(sp)
    800065d2:	e426                	sd	s1,8(sp)
    800065d4:	1000                	addi	s0,sp,32
    800065d6:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800065d8:	ffffb097          	auipc	ra,0xffffb
    800065dc:	3ee080e7          	jalr	1006(ra) # 800019c6 <myproc>
    800065e0:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800065e2:	0d050793          	addi	a5,a0,208
    800065e6:	4501                	li	a0,0
    800065e8:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800065ea:	6398                	ld	a4,0(a5)
    800065ec:	cb19                	beqz	a4,80006602 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800065ee:	2505                	addiw	a0,a0,1
    800065f0:	07a1                	addi	a5,a5,8
    800065f2:	fed51ce3          	bne	a0,a3,800065ea <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800065f6:	557d                	li	a0,-1
}
    800065f8:	60e2                	ld	ra,24(sp)
    800065fa:	6442                	ld	s0,16(sp)
    800065fc:	64a2                	ld	s1,8(sp)
    800065fe:	6105                	addi	sp,sp,32
    80006600:	8082                	ret
      p->ofile[fd] = f;
    80006602:	01a50793          	addi	a5,a0,26
    80006606:	078e                	slli	a5,a5,0x3
    80006608:	963e                	add	a2,a2,a5
    8000660a:	e204                	sd	s1,0(a2)
      return fd;
    8000660c:	b7f5                	j	800065f8 <fdalloc+0x2c>

000000008000660e <create>:

struct inode*
create(char *path, short type, short major, short minor)
{
    8000660e:	715d                	addi	sp,sp,-80
    80006610:	e486                	sd	ra,72(sp)
    80006612:	e0a2                	sd	s0,64(sp)
    80006614:	fc26                	sd	s1,56(sp)
    80006616:	f84a                	sd	s2,48(sp)
    80006618:	f44e                	sd	s3,40(sp)
    8000661a:	f052                	sd	s4,32(sp)
    8000661c:	ec56                	sd	s5,24(sp)
    8000661e:	e85a                	sd	s6,16(sp)
    80006620:	0880                	addi	s0,sp,80
    80006622:	8b2e                	mv	s6,a1
    80006624:	89b2                	mv	s3,a2
    80006626:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80006628:	fb040593          	addi	a1,s0,-80
    8000662c:	ffffe097          	auipc	ra,0xffffe
    80006630:	a3e080e7          	jalr	-1474(ra) # 8000406a <nameiparent>
    80006634:	84aa                	mv	s1,a0
    80006636:	18050063          	beqz	a0,800067b6 <create+0x1a8>
    return 0;

  ilock(dp);
    8000663a:	ffffd097          	auipc	ra,0xffffd
    8000663e:	244080e7          	jalr	580(ra) # 8000387e <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80006642:	4601                	li	a2,0
    80006644:	fb040593          	addi	a1,s0,-80
    80006648:	8526                	mv	a0,s1
    8000664a:	ffffd097          	auipc	ra,0xffffd
    8000664e:	740080e7          	jalr	1856(ra) # 80003d8a <dirlookup>
    80006652:	8aaa                	mv	s5,a0
    80006654:	c931                	beqz	a0,800066a8 <create+0x9a>
    iunlockput(dp);
    80006656:	8526                	mv	a0,s1
    80006658:	ffffd097          	auipc	ra,0xffffd
    8000665c:	488080e7          	jalr	1160(ra) # 80003ae0 <iunlockput>
    ilock(ip);
    80006660:	8556                	mv	a0,s5
    80006662:	ffffd097          	auipc	ra,0xffffd
    80006666:	21c080e7          	jalr	540(ra) # 8000387e <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000666a:	000b059b          	sext.w	a1,s6
    8000666e:	4789                	li	a5,2
    80006670:	02f59563          	bne	a1,a5,8000669a <create+0x8c>
    80006674:	044ad783          	lhu	a5,68(s5)
    80006678:	37f9                	addiw	a5,a5,-2
    8000667a:	17c2                	slli	a5,a5,0x30
    8000667c:	93c1                	srli	a5,a5,0x30
    8000667e:	4705                	li	a4,1
    80006680:	00f76d63          	bltu	a4,a5,8000669a <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80006684:	8556                	mv	a0,s5
    80006686:	60a6                	ld	ra,72(sp)
    80006688:	6406                	ld	s0,64(sp)
    8000668a:	74e2                	ld	s1,56(sp)
    8000668c:	7942                	ld	s2,48(sp)
    8000668e:	79a2                	ld	s3,40(sp)
    80006690:	7a02                	ld	s4,32(sp)
    80006692:	6ae2                	ld	s5,24(sp)
    80006694:	6b42                	ld	s6,16(sp)
    80006696:	6161                	addi	sp,sp,80
    80006698:	8082                	ret
    iunlockput(ip);
    8000669a:	8556                	mv	a0,s5
    8000669c:	ffffd097          	auipc	ra,0xffffd
    800066a0:	444080e7          	jalr	1092(ra) # 80003ae0 <iunlockput>
    return 0;
    800066a4:	4a81                	li	s5,0
    800066a6:	bff9                	j	80006684 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800066a8:	85da                	mv	a1,s6
    800066aa:	4088                	lw	a0,0(s1)
    800066ac:	ffffd097          	auipc	ra,0xffffd
    800066b0:	036080e7          	jalr	54(ra) # 800036e2 <ialloc>
    800066b4:	8a2a                	mv	s4,a0
    800066b6:	c125                	beqz	a0,80006716 <create+0x108>
  ilock(ip);
    800066b8:	ffffd097          	auipc	ra,0xffffd
    800066bc:	1c6080e7          	jalr	454(ra) # 8000387e <ilock>
  ip->major = major;
    800066c0:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800066c4:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800066c8:	4785                	li	a5,1
    800066ca:	04fa1523          	sh	a5,74(s4)
  iupdate(ip);
    800066ce:	8552                	mv	a0,s4
    800066d0:	ffffd097          	auipc	ra,0xffffd
    800066d4:	0e4080e7          	jalr	228(ra) # 800037b4 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800066d8:	000b059b          	sext.w	a1,s6
    800066dc:	4785                	li	a5,1
    800066de:	04f58363          	beq	a1,a5,80006724 <create+0x116>
  if(dirlink(dp, name, ip->inum) < 0)
    800066e2:	004a2603          	lw	a2,4(s4)
    800066e6:	fb040593          	addi	a1,s0,-80
    800066ea:	8526                	mv	a0,s1
    800066ec:	ffffe097          	auipc	ra,0xffffe
    800066f0:	8ae080e7          	jalr	-1874(ra) # 80003f9a <dirlink>
    800066f4:	08054763          	bltz	a0,80006782 <create+0x174>
  iunlockput(dp);
    800066f8:	8526                	mv	a0,s1
    800066fa:	ffffd097          	auipc	ra,0xffffd
    800066fe:	3e6080e7          	jalr	998(ra) # 80003ae0 <iunlockput>
  printf("Successfully Created\n");
    80006702:	00002517          	auipc	a0,0x2
    80006706:	33e50513          	addi	a0,a0,830 # 80008a40 <syscalls+0x450>
    8000670a:	ffffa097          	auipc	ra,0xffffa
    8000670e:	e84080e7          	jalr	-380(ra) # 8000058e <printf>
  return ip;
    80006712:	8ad2                	mv	s5,s4
    80006714:	bf85                	j	80006684 <create+0x76>
    iunlockput(dp);
    80006716:	8526                	mv	a0,s1
    80006718:	ffffd097          	auipc	ra,0xffffd
    8000671c:	3c8080e7          	jalr	968(ra) # 80003ae0 <iunlockput>
    return 0;
    80006720:	8ad2                	mv	s5,s4
    80006722:	b78d                	j	80006684 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80006724:	004a2603          	lw	a2,4(s4)
    80006728:	00002597          	auipc	a1,0x2
    8000672c:	1c858593          	addi	a1,a1,456 # 800088f0 <syscalls+0x300>
    80006730:	8552                	mv	a0,s4
    80006732:	ffffe097          	auipc	ra,0xffffe
    80006736:	868080e7          	jalr	-1944(ra) # 80003f9a <dirlink>
    8000673a:	04054463          	bltz	a0,80006782 <create+0x174>
    8000673e:	40d0                	lw	a2,4(s1)
    80006740:	00002597          	auipc	a1,0x2
    80006744:	1b858593          	addi	a1,a1,440 # 800088f8 <syscalls+0x308>
    80006748:	8552                	mv	a0,s4
    8000674a:	ffffe097          	auipc	ra,0xffffe
    8000674e:	850080e7          	jalr	-1968(ra) # 80003f9a <dirlink>
    80006752:	02054863          	bltz	a0,80006782 <create+0x174>
  if(dirlink(dp, name, ip->inum) < 0)
    80006756:	004a2603          	lw	a2,4(s4)
    8000675a:	fb040593          	addi	a1,s0,-80
    8000675e:	8526                	mv	a0,s1
    80006760:	ffffe097          	auipc	ra,0xffffe
    80006764:	83a080e7          	jalr	-1990(ra) # 80003f9a <dirlink>
    80006768:	00054d63          	bltz	a0,80006782 <create+0x174>
    dp->nlink++;  // for ".."
    8000676c:	04a4d783          	lhu	a5,74(s1)
    80006770:	2785                	addiw	a5,a5,1
    80006772:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80006776:	8526                	mv	a0,s1
    80006778:	ffffd097          	auipc	ra,0xffffd
    8000677c:	03c080e7          	jalr	60(ra) # 800037b4 <iupdate>
    80006780:	bfa5                	j	800066f8 <create+0xea>
  printf("actually fails\n");
    80006782:	00002517          	auipc	a0,0x2
    80006786:	2d650513          	addi	a0,a0,726 # 80008a58 <syscalls+0x468>
    8000678a:	ffffa097          	auipc	ra,0xffffa
    8000678e:	e04080e7          	jalr	-508(ra) # 8000058e <printf>
  ip->nlink = 0;
    80006792:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80006796:	8552                	mv	a0,s4
    80006798:	ffffd097          	auipc	ra,0xffffd
    8000679c:	01c080e7          	jalr	28(ra) # 800037b4 <iupdate>
  iunlockput(ip);
    800067a0:	8552                	mv	a0,s4
    800067a2:	ffffd097          	auipc	ra,0xffffd
    800067a6:	33e080e7          	jalr	830(ra) # 80003ae0 <iunlockput>
  iunlockput(dp);
    800067aa:	8526                	mv	a0,s1
    800067ac:	ffffd097          	auipc	ra,0xffffd
    800067b0:	334080e7          	jalr	820(ra) # 80003ae0 <iunlockput>
  return 0;
    800067b4:	bdc1                	j	80006684 <create+0x76>
    return 0;
    800067b6:	8aaa                	mv	s5,a0
    800067b8:	b5f1                	j	80006684 <create+0x76>

00000000800067ba <open>:


struct file *open(char *filename, int omode){
    800067ba:	7179                	addi	sp,sp,-48
    800067bc:	f406                	sd	ra,40(sp)
    800067be:	f022                	sd	s0,32(sp)
    800067c0:	ec26                	sd	s1,24(sp)
    800067c2:	e84a                	sd	s2,16(sp)
    800067c4:	e44e                	sd	s3,8(sp)
    800067c6:	1800                	addi	s0,sp,48
    800067c8:	84aa                	mv	s1,a0
    800067ca:	892e                	mv	s2,a1
    int fd;
    struct file *f;
    struct inode *ip;

    if(strlen(filename) < 0)
    800067cc:	ffffa097          	auipc	ra,0xffffa
    800067d0:	69e080e7          	jalr	1694(ra) # 80000e6a <strlen>
    800067d4:	18054e63          	bltz	a0,80006970 <open+0x1b6>
	return (struct file *)-1;

    begin_op();
    800067d8:	ffffe097          	auipc	ra,0xffffe
    800067dc:	a90080e7          	jalr	-1392(ra) # 80004268 <begin_op>
    if(omode & O_CREATE){
    800067e0:	20097793          	andi	a5,s2,512
    800067e4:	10078263          	beqz	a5,800068e8 <open+0x12e>
	printf("CREATING\n");
    800067e8:	00002517          	auipc	a0,0x2
    800067ec:	28050513          	addi	a0,a0,640 # 80008a68 <syscalls+0x478>
    800067f0:	ffffa097          	auipc	ra,0xffffa
    800067f4:	d9e080e7          	jalr	-610(ra) # 8000058e <printf>
	ip = create(filename, T_FILE, 0, 0);
    800067f8:	4681                	li	a3,0
    800067fa:	4601                	li	a2,0
    800067fc:	4589                	li	a1,2
    800067fe:	8526                	mv	a0,s1
    80006800:	00000097          	auipc	ra,0x0
    80006804:	e0e080e7          	jalr	-498(ra) # 8000660e <create>
    80006808:	89aa                	mv	s3,a0
	if(ip == 0){ 
    8000680a:	c169                	beqz	a0,800068cc <open+0x112>
	    iunlockput(ip);
	    end_op();
	    return (struct file *)-1;
	}
    }
    printf("1\n");
    8000680c:	00002517          	auipc	a0,0x2
    80006810:	29450513          	addi	a0,a0,660 # 80008aa0 <syscalls+0x4b0>
    80006814:	ffffa097          	auipc	ra,0xffffa
    80006818:	d7a080e7          	jalr	-646(ra) # 8000058e <printf>
    

    if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000681c:	04499703          	lh	a4,68(s3)
    80006820:	478d                	li	a5,3
    80006822:	00f71763          	bne	a4,a5,80006830 <open+0x76>
    80006826:	0469d703          	lhu	a4,70(s3)
    8000682a:	47a5                	li	a5,9
    8000682c:	12e7e163          	bltu	a5,a4,8000694e <open+0x194>
	iunlockput(ip);
	end_op();
	return (struct file *)-1;
    }

	printf("2\n");
    80006830:	00002517          	auipc	a0,0x2
    80006834:	27850513          	addi	a0,a0,632 # 80008aa8 <syscalls+0x4b8>
    80006838:	ffffa097          	auipc	ra,0xffffa
    8000683c:	d56080e7          	jalr	-682(ra) # 8000058e <printf>
    if((f = filealloc()) == 0 || (fd = fdalloc(f) < 0)){
    80006840:	ffffe097          	auipc	ra,0xffffe
    80006844:	e38080e7          	jalr	-456(ra) # 80004678 <filealloc>
    80006848:	84aa                	mv	s1,a0
    8000684a:	14050163          	beqz	a0,8000698c <open+0x1d2>
    8000684e:	00000097          	auipc	ra,0x0
    80006852:	d7e080e7          	jalr	-642(ra) # 800065cc <fdalloc>
    80006856:	12054663          	bltz	a0,80006982 <open+0x1c8>
	iunlockput(ip);
	end_op();
	return (struct file *)-1;
    }

	printf("3\n");
    8000685a:	00002517          	auipc	a0,0x2
    8000685e:	25650513          	addi	a0,a0,598 # 80008ab0 <syscalls+0x4c0>
    80006862:	ffffa097          	auipc	ra,0xffffa
    80006866:	d2c080e7          	jalr	-724(ra) # 8000058e <printf>
   f->type = FD_INODE;
    8000686a:	4789                	li	a5,2
    8000686c:	c09c                	sw	a5,0(s1)
   f->off = 0;
    8000686e:	0204a023          	sw	zero,32(s1)
   f->ip = ip;
    80006872:	0134bc23          	sd	s3,24(s1)
   f->readable = !(omode & O_WRONLY);
    80006876:	00194793          	xori	a5,s2,1
    8000687a:	8b85                	andi	a5,a5,1
    8000687c:	00f48423          	sb	a5,8(s1)
   f->writable = O_WRONLY;
    80006880:	4785                	li	a5,1
    80006882:	00f484a3          	sb	a5,9(s1)

   if((omode & O_TRUNC) && ip->type == T_FILE){
    80006886:	40097913          	andi	s2,s2,1024
    8000688a:	00090763          	beqz	s2,80006898 <open+0xde>
    8000688e:	04499703          	lh	a4,68(s3)
    80006892:	4789                	li	a5,2
    80006894:	0cf70863          	beq	a4,a5,80006964 <open+0x1aa>
     itrunc(ip);
   }

	printf("4\n");
    80006898:	00002517          	auipc	a0,0x2
    8000689c:	22050513          	addi	a0,a0,544 # 80008ab8 <syscalls+0x4c8>
    800068a0:	ffffa097          	auipc	ra,0xffffa
    800068a4:	cee080e7          	jalr	-786(ra) # 8000058e <printf>
   iunlock(ip);
    800068a8:	854e                	mv	a0,s3
    800068aa:	ffffd097          	auipc	ra,0xffffd
    800068ae:	096080e7          	jalr	150(ra) # 80003940 <iunlock>
   end_op();
    800068b2:	ffffe097          	auipc	ra,0xffffe
    800068b6:	a36080e7          	jalr	-1482(ra) # 800042e8 <end_op>

	printf("5\n");
    800068ba:	00002517          	auipc	a0,0x2
    800068be:	20650513          	addi	a0,a0,518 # 80008ac0 <syscalls+0x4d0>
    800068c2:	ffffa097          	auipc	ra,0xffffa
    800068c6:	ccc080e7          	jalr	-820(ra) # 8000058e <printf>
   return f;
    800068ca:	a065                	j	80006972 <open+0x1b8>
	    printf("Create Broke\n");
    800068cc:	00002517          	auipc	a0,0x2
    800068d0:	1ac50513          	addi	a0,a0,428 # 80008a78 <syscalls+0x488>
    800068d4:	ffffa097          	auipc	ra,0xffffa
    800068d8:	cba080e7          	jalr	-838(ra) # 8000058e <printf>
	    end_op();
    800068dc:	ffffe097          	auipc	ra,0xffffe
    800068e0:	a0c080e7          	jalr	-1524(ra) # 800042e8 <end_op>
	    return (struct file *)-1;
    800068e4:	54fd                	li	s1,-1
    800068e6:	a071                	j	80006972 <open+0x1b8>
	printf("EXSITS ALREADY\n");
    800068e8:	00002517          	auipc	a0,0x2
    800068ec:	1a050513          	addi	a0,a0,416 # 80008a88 <syscalls+0x498>
    800068f0:	ffffa097          	auipc	ra,0xffffa
    800068f4:	c9e080e7          	jalr	-866(ra) # 8000058e <printf>
	if((ip = namei(filename)) == 0){
    800068f8:	8526                	mv	a0,s1
    800068fa:	ffffd097          	auipc	ra,0xffffd
    800068fe:	752080e7          	jalr	1874(ra) # 8000404c <namei>
    80006902:	89aa                	mv	s3,a0
    80006904:	c51d                	beqz	a0,80006932 <open+0x178>
	ilock(ip);
    80006906:	ffffd097          	auipc	ra,0xffffd
    8000690a:	f78080e7          	jalr	-136(ra) # 8000387e <ilock>
	if(ip->type == T_DIR && omode != O_RDONLY){
    8000690e:	04499703          	lh	a4,68(s3)
    80006912:	4785                	li	a5,1
    80006914:	eef71ce3          	bne	a4,a5,8000680c <open+0x52>
    80006918:	ee090ae3          	beqz	s2,8000680c <open+0x52>
	    iunlockput(ip);
    8000691c:	854e                	mv	a0,s3
    8000691e:	ffffd097          	auipc	ra,0xffffd
    80006922:	1c2080e7          	jalr	450(ra) # 80003ae0 <iunlockput>
	    end_op();
    80006926:	ffffe097          	auipc	ra,0xffffe
    8000692a:	9c2080e7          	jalr	-1598(ra) # 800042e8 <end_op>
	    return (struct file *)-1;
    8000692e:	54fd                	li	s1,-1
    80006930:	a089                	j	80006972 <open+0x1b8>
	    end_op();
    80006932:	ffffe097          	auipc	ra,0xffffe
    80006936:	9b6080e7          	jalr	-1610(ra) # 800042e8 <end_op>
	    printf("OOPs");
    8000693a:	00002517          	auipc	a0,0x2
    8000693e:	15e50513          	addi	a0,a0,350 # 80008a98 <syscalls+0x4a8>
    80006942:	ffffa097          	auipc	ra,0xffffa
    80006946:	c4c080e7          	jalr	-948(ra) # 8000058e <printf>
	    return (struct file *)-1;
    8000694a:	54fd                	li	s1,-1
    8000694c:	a01d                	j	80006972 <open+0x1b8>
	iunlockput(ip);
    8000694e:	854e                	mv	a0,s3
    80006950:	ffffd097          	auipc	ra,0xffffd
    80006954:	190080e7          	jalr	400(ra) # 80003ae0 <iunlockput>
	end_op();
    80006958:	ffffe097          	auipc	ra,0xffffe
    8000695c:	990080e7          	jalr	-1648(ra) # 800042e8 <end_op>
	return (struct file *)-1;
    80006960:	54fd                	li	s1,-1
    80006962:	a801                	j	80006972 <open+0x1b8>
     itrunc(ip);
    80006964:	854e                	mv	a0,s3
    80006966:	ffffd097          	auipc	ra,0xffffd
    8000696a:	026080e7          	jalr	38(ra) # 8000398c <itrunc>
    8000696e:	b72d                	j	80006898 <open+0xde>
	return (struct file *)-1;
    80006970:	54fd                	li	s1,-1
}
    80006972:	8526                	mv	a0,s1
    80006974:	70a2                	ld	ra,40(sp)
    80006976:	7402                	ld	s0,32(sp)
    80006978:	64e2                	ld	s1,24(sp)
    8000697a:	6942                	ld	s2,16(sp)
    8000697c:	69a2                	ld	s3,8(sp)
    8000697e:	6145                	addi	sp,sp,48
    80006980:	8082                	ret
	    fileclose(f);
    80006982:	8526                	mv	a0,s1
    80006984:	ffffe097          	auipc	ra,0xffffe
    80006988:	db0080e7          	jalr	-592(ra) # 80004734 <fileclose>
	iunlockput(ip);
    8000698c:	854e                	mv	a0,s3
    8000698e:	ffffd097          	auipc	ra,0xffffd
    80006992:	152080e7          	jalr	338(ra) # 80003ae0 <iunlockput>
	end_op();
    80006996:	ffffe097          	auipc	ra,0xffffe
    8000699a:	952080e7          	jalr	-1710(ra) # 800042e8 <end_op>
	return (struct file *)-1;
    8000699e:	54fd                	li	s1,-1
    800069a0:	bfc9                	j	80006972 <open+0x1b8>

00000000800069a2 <write_to_logs>:
#include "fcntl.h"

#include "audit_list.h"
#include "file_helper.h"

void write_to_logs(void *list){
    800069a2:	1101                	addi	sp,sp,-32
    800069a4:	ec06                	sd	ra,24(sp)
    800069a6:	e822                	sd	s0,16(sp)
    800069a8:	e426                	sd	s1,8(sp)
    800069aa:	1000                	addi	s0,sp,32
    struct file *f;
    char *filename = "/AuditLogs.txt";
    f = open(filename, O_CREATE);
    800069ac:	20000593          	li	a1,512
    800069b0:	00002517          	auipc	a0,0x2
    800069b4:	11850513          	addi	a0,a0,280 # 80008ac8 <syscalls+0x4d8>
    800069b8:	00000097          	auipc	ra,0x0
    800069bc:	e02080e7          	jalr	-510(ra) # 800067ba <open>

    f = open(filename, O_RDWR);
    800069c0:	4589                	li	a1,2
    800069c2:	00002517          	auipc	a0,0x2
    800069c6:	10650513          	addi	a0,a0,262 # 80008ac8 <syscalls+0x4d8>
    800069ca:	00000097          	auipc	ra,0x0
    800069ce:	df0080e7          	jalr	-528(ra) # 800067ba <open>
   
    if(f == (struct file *)-1)
    800069d2:	57fd                	li	a5,-1
    800069d4:	04f50f63          	beq	a0,a5,80006a32 <write_to_logs+0x90>
    800069d8:	84aa                	mv	s1,a0
	panic("ERROR FILE");

    if(f == (struct file *)0) {
    800069da:	c525                	beqz	a0,80006a42 <write_to_logs+0xa0>
	panic("No File");
    }
    printf("6\n");
    800069dc:	00002517          	auipc	a0,0x2
    800069e0:	11450513          	addi	a0,a0,276 # 80008af0 <syscalls+0x500>
    800069e4:	ffffa097          	auipc	ra,0xffffa
    800069e8:	baa080e7          	jalr	-1110(ra) # 8000058e <printf>
    char *temp = "happy\n";
    printf("writable: %d\n", f -> writable);
    800069ec:	0094c583          	lbu	a1,9(s1)
    800069f0:	00002517          	auipc	a0,0x2
    800069f4:	10850513          	addi	a0,a0,264 # 80008af8 <syscalls+0x508>
    800069f8:	ffffa097          	auipc	ra,0xffffa
    800069fc:	b96080e7          	jalr	-1130(ra) # 8000058e <printf>

    if (kfilewrite(f, (uint64)(temp), 7) <= 0){
    80006a00:	461d                	li	a2,7
    80006a02:	00002597          	auipc	a1,0x2
    80006a06:	10658593          	addi	a1,a1,262 # 80008b08 <syscalls+0x518>
    80006a0a:	8526                	mv	a0,s1
    80006a0c:	00000097          	auipc	ra,0x0
    80006a10:	a7e080e7          	jalr	-1410(ra) # 8000648a <kfilewrite>
    80006a14:	02a05f63          	blez	a0,80006a52 <write_to_logs+0xb0>

	printf("What\n");
    }
   
    printf("What1\n");
    80006a18:	00002517          	auipc	a0,0x2
    80006a1c:	10050513          	addi	a0,a0,256 # 80008b18 <syscalls+0x528>
    80006a20:	ffffa097          	auipc	ra,0xffffa
    80006a24:	b6e080e7          	jalr	-1170(ra) # 8000058e <printf>

}
    80006a28:	60e2                	ld	ra,24(sp)
    80006a2a:	6442                	ld	s0,16(sp)
    80006a2c:	64a2                	ld	s1,8(sp)
    80006a2e:	6105                	addi	sp,sp,32
    80006a30:	8082                	ret
	panic("ERROR FILE");
    80006a32:	00002517          	auipc	a0,0x2
    80006a36:	0a650513          	addi	a0,a0,166 # 80008ad8 <syscalls+0x4e8>
    80006a3a:	ffffa097          	auipc	ra,0xffffa
    80006a3e:	b0a080e7          	jalr	-1270(ra) # 80000544 <panic>
	panic("No File");
    80006a42:	00002517          	auipc	a0,0x2
    80006a46:	0a650513          	addi	a0,a0,166 # 80008ae8 <syscalls+0x4f8>
    80006a4a:	ffffa097          	auipc	ra,0xffffa
    80006a4e:	afa080e7          	jalr	-1286(ra) # 80000544 <panic>
	printf("What\n");
    80006a52:	00002517          	auipc	a0,0x2
    80006a56:	0be50513          	addi	a0,a0,190 # 80008b10 <syscalls+0x520>
    80006a5a:	ffffa097          	auipc	ra,0xffffa
    80006a5e:	b34080e7          	jalr	-1228(ra) # 8000058e <printf>
    80006a62:	bf5d                	j	80006a18 <write_to_logs+0x76>
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
