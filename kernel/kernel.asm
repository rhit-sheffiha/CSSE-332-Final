
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	ae013103          	ld	sp,-1312(sp) # 80008ae0 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000056:	b0e70713          	addi	a4,a4,-1266 # 80008b60 <timer_scratch>
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
    80000068:	eec78793          	addi	a5,a5,-276 # 80005f50 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffcfe1f>
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
    80000130:	43a080e7          	jalr	1082(ra) # 80002566 <either_copyin>
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
    80000190:	b1450513          	addi	a0,a0,-1260 # 80010ca0 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a56080e7          	jalr	-1450(ra) # 80000bea <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	b0448493          	addi	s1,s1,-1276 # 80010ca0 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	b9290913          	addi	s2,s2,-1134 # 80010d38 <cons+0x98>
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
    800001d0:	1e4080e7          	jalr	484(ra) # 800023b0 <killed>
    800001d4:	e535                	bnez	a0,80000240 <consoleread+0xdc>
      sleep(&cons.r, &cons.lock);
    800001d6:	85ce                	mv	a1,s3
    800001d8:	854a                	mv	a0,s2
    800001da:	00002097          	auipc	ra,0x2
    800001de:	f2e080e7          	jalr	-210(ra) # 80002108 <sleep>
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
    8000021a:	2fa080e7          	jalr	762(ra) # 80002510 <either_copyout>
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
    8000022e:	a7650513          	addi	a0,a0,-1418 # 80010ca0 <cons>
    80000232:	00001097          	auipc	ra,0x1
    80000236:	a6c080e7          	jalr	-1428(ra) # 80000c9e <release>

  return target - n;
    8000023a:	414b853b          	subw	a0,s7,s4
    8000023e:	a811                	j	80000252 <consoleread+0xee>
        release(&cons.lock);
    80000240:	00011517          	auipc	a0,0x11
    80000244:	a6050513          	addi	a0,a0,-1440 # 80010ca0 <cons>
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
    8000027c:	acf72023          	sw	a5,-1344(a4) # 80010d38 <cons+0x98>
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
    800002d6:	9ce50513          	addi	a0,a0,-1586 # 80010ca0 <cons>
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
    800002fc:	2c4080e7          	jalr	708(ra) # 800025bc <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000300:	00011517          	auipc	a0,0x11
    80000304:	9a050513          	addi	a0,a0,-1632 # 80010ca0 <cons>
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
    80000328:	97c70713          	addi	a4,a4,-1668 # 80010ca0 <cons>
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
    80000352:	95278793          	addi	a5,a5,-1710 # 80010ca0 <cons>
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
    80000380:	9bc7a783          	lw	a5,-1604(a5) # 80010d38 <cons+0x98>
    80000384:	9f1d                	subw	a4,a4,a5
    80000386:	08000793          	li	a5,128
    8000038a:	f6f71be3          	bne	a4,a5,80000300 <consoleintr+0x3c>
    8000038e:	a07d                	j	8000043c <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000390:	00011717          	auipc	a4,0x11
    80000394:	91070713          	addi	a4,a4,-1776 # 80010ca0 <cons>
    80000398:	0a072783          	lw	a5,160(a4)
    8000039c:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a0:	00011497          	auipc	s1,0x11
    800003a4:	90048493          	addi	s1,s1,-1792 # 80010ca0 <cons>
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
    800003e0:	8c470713          	addi	a4,a4,-1852 # 80010ca0 <cons>
    800003e4:	0a072783          	lw	a5,160(a4)
    800003e8:	09c72703          	lw	a4,156(a4)
    800003ec:	f0f70ae3          	beq	a4,a5,80000300 <consoleintr+0x3c>
      cons.e--;
    800003f0:	37fd                	addiw	a5,a5,-1
    800003f2:	00011717          	auipc	a4,0x11
    800003f6:	94f72723          	sw	a5,-1714(a4) # 80010d40 <cons+0xa0>
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
    8000041c:	88878793          	addi	a5,a5,-1912 # 80010ca0 <cons>
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
    80000440:	90c7a023          	sw	a2,-1792(a5) # 80010d3c <cons+0x9c>
        wakeup(&cons.r);
    80000444:	00011517          	auipc	a0,0x11
    80000448:	8f450513          	addi	a0,a0,-1804 # 80010d38 <cons+0x98>
    8000044c:	00002097          	auipc	ra,0x2
    80000450:	d20080e7          	jalr	-736(ra) # 8000216c <wakeup>
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
    8000046a:	83a50513          	addi	a0,a0,-1990 # 80010ca0 <cons>
    8000046e:	00000097          	auipc	ra,0x0
    80000472:	6ec080e7          	jalr	1772(ra) # 80000b5a <initlock>

  uartinit();
    80000476:	00000097          	auipc	ra,0x0
    8000047a:	330080e7          	jalr	816(ra) # 800007a6 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047e:	0002d797          	auipc	a5,0x2d
    80000482:	3ca78793          	addi	a5,a5,970 # 8002d848 <devsw>
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
    80000554:	8007a823          	sw	zero,-2032(a5) # 80010d60 <pr+0x18>
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
    80000576:	3ee50513          	addi	a0,a0,1006 # 80008960 <syscalls+0x460>
    8000057a:	00000097          	auipc	ra,0x0
    8000057e:	014080e7          	jalr	20(ra) # 8000058e <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000582:	4785                	li	a5,1
    80000584:	00008717          	auipc	a4,0x8
    80000588:	56f72e23          	sw	a5,1404(a4) # 80008b00 <panicked>
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
    800005c0:	00010d97          	auipc	s11,0x10
    800005c4:	7a0dad83          	lw	s11,1952(s11) # 80010d60 <pr+0x18>
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
    80000602:	74a50513          	addi	a0,a0,1866 # 80010d48 <pr>
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
    80000766:	5e650513          	addi	a0,a0,1510 # 80010d48 <pr>
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
    80000782:	5ca48493          	addi	s1,s1,1482 # 80010d48 <pr>
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
    800007e2:	58a50513          	addi	a0,a0,1418 # 80010d68 <uart_tx_lock>
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
    8000080e:	2f67a783          	lw	a5,758(a5) # 80008b00 <panicked>
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
    8000084a:	2c273703          	ld	a4,706(a4) # 80008b08 <uart_tx_r>
    8000084e:	00008797          	auipc	a5,0x8
    80000852:	2c27b783          	ld	a5,706(a5) # 80008b10 <uart_tx_w>
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
    80000874:	4f8a0a13          	addi	s4,s4,1272 # 80010d68 <uart_tx_lock>
    uart_tx_r += 1;
    80000878:	00008497          	auipc	s1,0x8
    8000087c:	29048493          	addi	s1,s1,656 # 80008b08 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000880:	00008997          	auipc	s3,0x8
    80000884:	29098993          	addi	s3,s3,656 # 80008b10 <uart_tx_w>
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
    800008aa:	8c6080e7          	jalr	-1850(ra) # 8000216c <wakeup>
    
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
    800008e6:	48650513          	addi	a0,a0,1158 # 80010d68 <uart_tx_lock>
    800008ea:	00000097          	auipc	ra,0x0
    800008ee:	300080e7          	jalr	768(ra) # 80000bea <acquire>
  if(panicked){
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	20e7a783          	lw	a5,526(a5) # 80008b00 <panicked>
    800008fa:	e7c9                	bnez	a5,80000984 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fc:	00008797          	auipc	a5,0x8
    80000900:	2147b783          	ld	a5,532(a5) # 80008b10 <uart_tx_w>
    80000904:	00008717          	auipc	a4,0x8
    80000908:	20473703          	ld	a4,516(a4) # 80008b08 <uart_tx_r>
    8000090c:	02070713          	addi	a4,a4,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00010a17          	auipc	s4,0x10
    80000914:	458a0a13          	addi	s4,s4,1112 # 80010d68 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	1f048493          	addi	s1,s1,496 # 80008b08 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	1f090913          	addi	s2,s2,496 # 80008b10 <uart_tx_w>
    80000928:	00f71f63          	bne	a4,a5,80000946 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000092c:	85d2                	mv	a1,s4
    8000092e:	8526                	mv	a0,s1
    80000930:	00001097          	auipc	ra,0x1
    80000934:	7d8080e7          	jalr	2008(ra) # 80002108 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000938:	00093783          	ld	a5,0(s2)
    8000093c:	6098                	ld	a4,0(s1)
    8000093e:	02070713          	addi	a4,a4,32
    80000942:	fef705e3          	beq	a4,a5,8000092c <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000946:	00010497          	auipc	s1,0x10
    8000094a:	42248493          	addi	s1,s1,1058 # 80010d68 <uart_tx_lock>
    8000094e:	01f7f713          	andi	a4,a5,31
    80000952:	9726                	add	a4,a4,s1
    80000954:	01370c23          	sb	s3,24(a4)
  uart_tx_w += 1;
    80000958:	0785                	addi	a5,a5,1
    8000095a:	00008717          	auipc	a4,0x8
    8000095e:	1af73b23          	sd	a5,438(a4) # 80008b10 <uart_tx_w>
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
    800009d4:	39848493          	addi	s1,s1,920 # 80010d68 <uart_tx_lock>
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
    80000a12:	0002e797          	auipc	a5,0x2e
    80000a16:	fce78793          	addi	a5,a5,-50 # 8002e9e0 <end>
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
    80000a36:	36e90913          	addi	s2,s2,878 # 80010da0 <kmem>
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
    80000ad2:	2d250513          	addi	a0,a0,722 # 80010da0 <kmem>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	084080e7          	jalr	132(ra) # 80000b5a <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ade:	45c5                	li	a1,17
    80000ae0:	05ee                	slli	a1,a1,0x1b
    80000ae2:	0002e517          	auipc	a0,0x2e
    80000ae6:	efe50513          	addi	a0,a0,-258 # 8002e9e0 <end>
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
    80000b08:	29c48493          	addi	s1,s1,668 # 80010da0 <kmem>
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
    80000b20:	28450513          	addi	a0,a0,644 # 80010da0 <kmem>
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
    80000b4c:	25850513          	addi	a0,a0,600 # 80010da0 <kmem>
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
    80000ea8:	c7470713          	addi	a4,a4,-908 # 80008b18 <started>
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
    80000ede:	822080e7          	jalr	-2014(ra) # 800026fc <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ee2:	00005097          	auipc	ra,0x5
    80000ee6:	0ae080e7          	jalr	174(ra) # 80005f90 <plicinithart>
  }

  scheduler();        
    80000eea:	00001097          	auipc	ra,0x1
    80000eee:	042080e7          	jalr	66(ra) # 80001f2c <scheduler>
    consoleinit();
    80000ef2:	fffff097          	auipc	ra,0xfffff
    80000ef6:	564080e7          	jalr	1380(ra) # 80000456 <consoleinit>
    printfinit();
    80000efa:	00000097          	auipc	ra,0x0
    80000efe:	87a080e7          	jalr	-1926(ra) # 80000774 <printfinit>
    printf("\n");
    80000f02:	00008517          	auipc	a0,0x8
    80000f06:	a5e50513          	addi	a0,a0,-1442 # 80008960 <syscalls+0x460>
    80000f0a:	fffff097          	auipc	ra,0xfffff
    80000f0e:	684080e7          	jalr	1668(ra) # 8000058e <printf>
    printf("xv6 kernel is booting\n");
    80000f12:	00007517          	auipc	a0,0x7
    80000f16:	18e50513          	addi	a0,a0,398 # 800080a0 <digits+0x60>
    80000f1a:	fffff097          	auipc	ra,0xfffff
    80000f1e:	674080e7          	jalr	1652(ra) # 8000058e <printf>
    printf("\n");
    80000f22:	00008517          	auipc	a0,0x8
    80000f26:	a3e50513          	addi	a0,a0,-1474 # 80008960 <syscalls+0x460>
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
    80000f56:	782080e7          	jalr	1922(ra) # 800026d4 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5a:	00001097          	auipc	ra,0x1
    80000f5e:	7a2080e7          	jalr	1954(ra) # 800026fc <trapinithart>
    plicinit();      // set up interrupt controller
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	018080e7          	jalr	24(ra) # 80005f7a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6a:	00005097          	auipc	ra,0x5
    80000f6e:	026080e7          	jalr	38(ra) # 80005f90 <plicinithart>
    binit();         // buffer cache
    80000f72:	00002097          	auipc	ra,0x2
    80000f76:	1d2080e7          	jalr	466(ra) # 80003144 <binit>
    iinit();         // inode table
    80000f7a:	00003097          	auipc	ra,0x3
    80000f7e:	876080e7          	jalr	-1930(ra) # 800037f0 <iinit>
    fileinit();      // file table
    80000f82:	00004097          	auipc	ra,0x4
    80000f86:	814080e7          	jalr	-2028(ra) # 80004796 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8a:	00005097          	auipc	ra,0x5
    80000f8e:	10e080e7          	jalr	270(ra) # 80006098 <virtio_disk_init>
    userinit();      // first user process
    80000f92:	00001097          	auipc	ra,0x1
    80000f96:	d0c080e7          	jalr	-756(ra) # 80001c9e <userinit>
    __sync_synchronize();
    80000f9a:	0ff0000f          	fence
    started = 1;
    80000f9e:	4785                	li	a5,1
    80000fa0:	00008717          	auipc	a4,0x8
    80000fa4:	b6f72c23          	sw	a5,-1160(a4) # 80008b18 <started>
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
    80000fb8:	b6c7b783          	ld	a5,-1172(a5) # 80008b20 <kernel_pagetable>
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
    80001274:	8aa7b823          	sd	a0,-1872(a5) # 80008b20 <kernel_pagetable>
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
    8000186a:	99a48493          	addi	s1,s1,-1638 # 80011200 <proc>
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
    80001884:	580a0a13          	addi	s4,s4,1408 # 80016e00 <tickslock>
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
    80001906:	4be50513          	addi	a0,a0,1214 # 80010dc0 <pid_lock>
    8000190a:	fffff097          	auipc	ra,0xfffff
    8000190e:	250080e7          	jalr	592(ra) # 80000b5a <initlock>
  initlock(&wait_lock, "wait_lock");
    80001912:	00007597          	auipc	a1,0x7
    80001916:	8d658593          	addi	a1,a1,-1834 # 800081e8 <digits+0x1a8>
    8000191a:	0000f517          	auipc	a0,0xf
    8000191e:	4be50513          	addi	a0,a0,1214 # 80010dd8 <wait_lock>
    80001922:	fffff097          	auipc	ra,0xfffff
    80001926:	238080e7          	jalr	568(ra) # 80000b5a <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000192a:	00010497          	auipc	s1,0x10
    8000192e:	8d648493          	addi	s1,s1,-1834 # 80011200 <proc>
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
    80001950:	4b498993          	addi	s3,s3,1204 # 80016e00 <tickslock>
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
    800019ba:	43a50513          	addi	a0,a0,1082 # 80010df0 <cpus>
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
    800019e2:	3e270713          	addi	a4,a4,994 # 80010dc0 <pid_lock>
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
    80001a1a:	faa7a783          	lw	a5,-86(a5) # 800089c0 <first.1717>
    80001a1e:	eb89                	bnez	a5,80001a30 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a20:	00001097          	auipc	ra,0x1
    80001a24:	cf4080e7          	jalr	-780(ra) # 80002714 <usertrapret>
}
    80001a28:	60a2                	ld	ra,8(sp)
    80001a2a:	6402                	ld	s0,0(sp)
    80001a2c:	0141                	addi	sp,sp,16
    80001a2e:	8082                	ret
    first = 0;
    80001a30:	00007797          	auipc	a5,0x7
    80001a34:	f807a823          	sw	zero,-112(a5) # 800089c0 <first.1717>
    fsinit(ROOTDEV);
    80001a38:	4505                	li	a0,1
    80001a3a:	00002097          	auipc	ra,0x2
    80001a3e:	d36080e7          	jalr	-714(ra) # 80003770 <fsinit>
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
    80001a54:	37090913          	addi	s2,s2,880 # 80010dc0 <pid_lock>
    80001a58:	854a                	mv	a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	190080e7          	jalr	400(ra) # 80000bea <acquire>
  pid = nextpid;
    80001a62:	00007797          	auipc	a5,0x7
    80001a66:	f6278793          	addi	a5,a5,-158 # 800089c4 <nextpid>
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
    80001be0:	62448493          	addi	s1,s1,1572 # 80011200 <proc>
    80001be4:	00015917          	auipc	s2,0x15
    80001be8:	21c90913          	addi	s2,s2,540 # 80016e00 <tickslock>
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
    80001cb6:	e6a7bf23          	sd	a0,-386(a5) # 80008b30 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cba:	03400613          	li	a2,52
    80001cbe:	00007597          	auipc	a1,0x7
    80001cc2:	d1258593          	addi	a1,a1,-750 # 800089d0 <initcode>
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
    80001d00:	496080e7          	jalr	1174(ra) # 80004192 <namei>
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
    80001e1e:	a0e080e7          	jalr	-1522(ra) # 80004828 <filedup>
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
    80001e40:	b72080e7          	jalr	-1166(ra) # 800039ae <idup>
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
    80001e6c:	f7048493          	addi	s1,s1,-144 # 80010dd8 <wait_lock>
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
    80001eb8:	1141                	addi	sp,sp,-16
    80001eba:	e422                	sd	s0,8(sp)
    80001ebc:	0800                	addi	s0,sp,16
}
    80001ebe:	00a5551b          	srliw	a0,a0,0xa
    80001ec2:	6422                	ld	s0,8(sp)
    80001ec4:	0141                	addi	sp,sp,16
    80001ec6:	8082                	ret

0000000080001ec8 <check>:
    if(ticks - prev_tick > 50){
    80001ec8:	00007797          	auipc	a5,0x7
    80001ecc:	c707a783          	lw	a5,-912(a5) # 80008b38 <ticks>
    80001ed0:	00007717          	auipc	a4,0x7
    80001ed4:	c5872703          	lw	a4,-936(a4) # 80008b28 <prev_tick>
    80001ed8:	9f99                	subw	a5,a5,a4
    80001eda:	03200713          	li	a4,50
    return 0;
    80001ede:	4501                	li	a0,0
    if(ticks - prev_tick > 50){
    80001ee0:	00f76363          	bltu	a4,a5,80001ee6 <check+0x1e>
}
    80001ee4:	8082                	ret
check(void *list){
    80001ee6:	1101                	addi	sp,sp,-32
    80001ee8:	ec06                	sd	ra,24(sp)
    80001eea:	e822                	sd	s0,16(sp)
    80001eec:	1000                	addi	s0,sp,32
	a[0] = 'H';
    80001eee:	04800793          	li	a5,72
    80001ef2:	fef40423          	sb	a5,-24(s0)
	a[1] = 'A';
    80001ef6:	04100793          	li	a5,65
    80001efa:	fef404a3          	sb	a5,-23(s0)
	a[2] = 'P';
    80001efe:	05000793          	li	a5,80
    80001f02:	fef40523          	sb	a5,-22(s0)
	write_to_logs((void *)a);
    80001f06:	fe840513          	addi	a0,s0,-24
    80001f0a:	00004097          	auipc	ra,0x4
    80001f0e:	776080e7          	jalr	1910(ra) # 80006680 <write_to_logs>
	prev_tick = ticks;
    80001f12:	00007797          	auipc	a5,0x7
    80001f16:	c267a783          	lw	a5,-986(a5) # 80008b38 <ticks>
    80001f1a:	00007717          	auipc	a4,0x7
    80001f1e:	c0f72723          	sw	a5,-1010(a4) # 80008b28 <prev_tick>
	return 1;
    80001f22:	4505                	li	a0,1
}
    80001f24:	60e2                	ld	ra,24(sp)
    80001f26:	6442                	ld	s0,16(sp)
    80001f28:	6105                	addi	sp,sp,32
    80001f2a:	8082                	ret

0000000080001f2c <scheduler>:
{
    80001f2c:	715d                	addi	sp,sp,-80
    80001f2e:	e486                	sd	ra,72(sp)
    80001f30:	e0a2                	sd	s0,64(sp)
    80001f32:	fc26                	sd	s1,56(sp)
    80001f34:	f84a                	sd	s2,48(sp)
    80001f36:	f44e                	sd	s3,40(sp)
    80001f38:	f052                	sd	s4,32(sp)
    80001f3a:	ec56                	sd	s5,24(sp)
    80001f3c:	e85a                	sd	s6,16(sp)
    80001f3e:	e45e                	sd	s7,8(sp)
    80001f40:	e062                	sd	s8,0(sp)
    80001f42:	0880                	addi	s0,sp,80
    80001f44:	8492                	mv	s1,tp
  int id = r_tp();
    80001f46:	2481                	sext.w	s1,s1
  init_list_head(&runq);
    80001f48:	0000f517          	auipc	a0,0xf
    80001f4c:	2a850513          	addi	a0,a0,680 # 800111f0 <runq>
    80001f50:	00004097          	auipc	ra,0x4
    80001f54:	67a080e7          	jalr	1658(ra) # 800065ca <init_list_head>
  c->proc = 0;
    80001f58:	00749b13          	slli	s6,s1,0x7
    80001f5c:	0000f797          	auipc	a5,0xf
    80001f60:	e6478793          	addi	a5,a5,-412 # 80010dc0 <pid_lock>
    80001f64:	97da                	add	a5,a5,s6
    80001f66:	0207b823          	sd	zero,48(a5)
        swtch(&c->context, &p->context);
    80001f6a:	0000f797          	auipc	a5,0xf
    80001f6e:	e8e78793          	addi	a5,a5,-370 # 80010df8 <cpus+0x8>
    80001f72:	9b3e                	add	s6,s6,a5
        p->state = RUNNING;
    80001f74:	4b91                	li	s7,4
        c->proc = p;
    80001f76:	049e                	slli	s1,s1,0x7
    80001f78:	0000fa97          	auipc	s5,0xf
    80001f7c:	e48a8a93          	addi	s5,s5,-440 # 80010dc0 <pid_lock>
    80001f80:	9aa6                	add	s5,s5,s1
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f82:	00015a17          	auipc	s4,0x15
    80001f86:	e7ea0a13          	addi	s4,s4,-386 # 80016e00 <tickslock>
    not_runnable_count = 0;
    80001f8a:	4c01                	li	s8,0
    80001f8c:	a0a9                	j	80001fd6 <scheduler+0xaa>
        p->state = RUNNING;
    80001f8e:	0174ac23          	sw	s7,24(s1)
        c->proc = p;
    80001f92:	029ab823          	sd	s1,48(s5)
        swtch(&c->context, &p->context);
    80001f96:	06048593          	addi	a1,s1,96
    80001f9a:	855a                	mv	a0,s6
    80001f9c:	00000097          	auipc	ra,0x0
    80001fa0:	6ce080e7          	jalr	1742(ra) # 8000266a <swtch>
        c->proc = 0;
    80001fa4:	020ab823          	sd	zero,48(s5)
      release(&p->lock);
    80001fa8:	8526                	mv	a0,s1
    80001faa:	fffff097          	auipc	ra,0xfffff
    80001fae:	cf4080e7          	jalr	-780(ra) # 80000c9e <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fb2:	17048493          	addi	s1,s1,368
    80001fb6:	01448c63          	beq	s1,s4,80001fce <scheduler+0xa2>
      acquire(&p->lock);
    80001fba:	8526                	mv	a0,s1
    80001fbc:	fffff097          	auipc	ra,0xfffff
    80001fc0:	c2e080e7          	jalr	-978(ra) # 80000bea <acquire>
      if(p->state == RUNNABLE) {
    80001fc4:	4c9c                	lw	a5,24(s1)
    80001fc6:	fd3784e3          	beq	a5,s3,80001f8e <scheduler+0x62>
        not_runnable_count++;
    80001fca:	2905                	addiw	s2,s2,1
    80001fcc:	bff1                	j	80001fa8 <scheduler+0x7c>
    if (not_runnable_count == NPROC) {
    80001fce:	04000793          	li	a5,64
    80001fd2:	00f90f63          	beq	s2,a5,80001ff0 <scheduler+0xc4>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fd6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001fda:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001fde:	10079073          	csrw	sstatus,a5
    not_runnable_count = 0;
    80001fe2:	8962                	mv	s2,s8
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fe4:	0000f497          	auipc	s1,0xf
    80001fe8:	21c48493          	addi	s1,s1,540 # 80011200 <proc>
      if(p->state == RUNNABLE) {
    80001fec:	498d                	li	s3,3
    80001fee:	b7f1                	j	80001fba <scheduler+0x8e>
  asm volatile("wfi");
    80001ff0:	10500073          	wfi
}
    80001ff4:	b7cd                	j	80001fd6 <scheduler+0xaa>

0000000080001ff6 <sched>:
{
    80001ff6:	7179                	addi	sp,sp,-48
    80001ff8:	f406                	sd	ra,40(sp)
    80001ffa:	f022                	sd	s0,32(sp)
    80001ffc:	ec26                	sd	s1,24(sp)
    80001ffe:	e84a                	sd	s2,16(sp)
    80002000:	e44e                	sd	s3,8(sp)
    80002002:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002004:	00000097          	auipc	ra,0x0
    80002008:	9c2080e7          	jalr	-1598(ra) # 800019c6 <myproc>
    8000200c:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000200e:	fffff097          	auipc	ra,0xfffff
    80002012:	b62080e7          	jalr	-1182(ra) # 80000b70 <holding>
    80002016:	c93d                	beqz	a0,8000208c <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002018:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    8000201a:	2781                	sext.w	a5,a5
    8000201c:	079e                	slli	a5,a5,0x7
    8000201e:	0000f717          	auipc	a4,0xf
    80002022:	da270713          	addi	a4,a4,-606 # 80010dc0 <pid_lock>
    80002026:	97ba                	add	a5,a5,a4
    80002028:	0a87a703          	lw	a4,168(a5)
    8000202c:	4785                	li	a5,1
    8000202e:	06f71763          	bne	a4,a5,8000209c <sched+0xa6>
  if(p->state == RUNNING)
    80002032:	4c98                	lw	a4,24(s1)
    80002034:	4791                	li	a5,4
    80002036:	06f70b63          	beq	a4,a5,800020ac <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000203a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000203e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002040:	efb5                	bnez	a5,800020bc <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002042:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002044:	0000f917          	auipc	s2,0xf
    80002048:	d7c90913          	addi	s2,s2,-644 # 80010dc0 <pid_lock>
    8000204c:	2781                	sext.w	a5,a5
    8000204e:	079e                	slli	a5,a5,0x7
    80002050:	97ca                	add	a5,a5,s2
    80002052:	0ac7a983          	lw	s3,172(a5)
    80002056:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002058:	2781                	sext.w	a5,a5
    8000205a:	079e                	slli	a5,a5,0x7
    8000205c:	0000f597          	auipc	a1,0xf
    80002060:	d9c58593          	addi	a1,a1,-612 # 80010df8 <cpus+0x8>
    80002064:	95be                	add	a1,a1,a5
    80002066:	06048513          	addi	a0,s1,96
    8000206a:	00000097          	auipc	ra,0x0
    8000206e:	600080e7          	jalr	1536(ra) # 8000266a <swtch>
    80002072:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002074:	2781                	sext.w	a5,a5
    80002076:	079e                	slli	a5,a5,0x7
    80002078:	97ca                	add	a5,a5,s2
    8000207a:	0b37a623          	sw	s3,172(a5)
}
    8000207e:	70a2                	ld	ra,40(sp)
    80002080:	7402                	ld	s0,32(sp)
    80002082:	64e2                	ld	s1,24(sp)
    80002084:	6942                	ld	s2,16(sp)
    80002086:	69a2                	ld	s3,8(sp)
    80002088:	6145                	addi	sp,sp,48
    8000208a:	8082                	ret
    panic("sched p->lock");
    8000208c:	00006517          	auipc	a0,0x6
    80002090:	18c50513          	addi	a0,a0,396 # 80008218 <digits+0x1d8>
    80002094:	ffffe097          	auipc	ra,0xffffe
    80002098:	4b0080e7          	jalr	1200(ra) # 80000544 <panic>
    panic("sched locks");
    8000209c:	00006517          	auipc	a0,0x6
    800020a0:	18c50513          	addi	a0,a0,396 # 80008228 <digits+0x1e8>
    800020a4:	ffffe097          	auipc	ra,0xffffe
    800020a8:	4a0080e7          	jalr	1184(ra) # 80000544 <panic>
    panic("sched running");
    800020ac:	00006517          	auipc	a0,0x6
    800020b0:	18c50513          	addi	a0,a0,396 # 80008238 <digits+0x1f8>
    800020b4:	ffffe097          	auipc	ra,0xffffe
    800020b8:	490080e7          	jalr	1168(ra) # 80000544 <panic>
    panic("sched interruptible");
    800020bc:	00006517          	auipc	a0,0x6
    800020c0:	18c50513          	addi	a0,a0,396 # 80008248 <digits+0x208>
    800020c4:	ffffe097          	auipc	ra,0xffffe
    800020c8:	480080e7          	jalr	1152(ra) # 80000544 <panic>

00000000800020cc <yield>:
{
    800020cc:	1101                	addi	sp,sp,-32
    800020ce:	ec06                	sd	ra,24(sp)
    800020d0:	e822                	sd	s0,16(sp)
    800020d2:	e426                	sd	s1,8(sp)
    800020d4:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800020d6:	00000097          	auipc	ra,0x0
    800020da:	8f0080e7          	jalr	-1808(ra) # 800019c6 <myproc>
    800020de:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020e0:	fffff097          	auipc	ra,0xfffff
    800020e4:	b0a080e7          	jalr	-1270(ra) # 80000bea <acquire>
  p->state = RUNNABLE;
    800020e8:	478d                	li	a5,3
    800020ea:	cc9c                	sw	a5,24(s1)
  sched();
    800020ec:	00000097          	auipc	ra,0x0
    800020f0:	f0a080e7          	jalr	-246(ra) # 80001ff6 <sched>
  release(&p->lock);
    800020f4:	8526                	mv	a0,s1
    800020f6:	fffff097          	auipc	ra,0xfffff
    800020fa:	ba8080e7          	jalr	-1112(ra) # 80000c9e <release>
}
    800020fe:	60e2                	ld	ra,24(sp)
    80002100:	6442                	ld	s0,16(sp)
    80002102:	64a2                	ld	s1,8(sp)
    80002104:	6105                	addi	sp,sp,32
    80002106:	8082                	ret

0000000080002108 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002108:	7179                	addi	sp,sp,-48
    8000210a:	f406                	sd	ra,40(sp)
    8000210c:	f022                	sd	s0,32(sp)
    8000210e:	ec26                	sd	s1,24(sp)
    80002110:	e84a                	sd	s2,16(sp)
    80002112:	e44e                	sd	s3,8(sp)
    80002114:	1800                	addi	s0,sp,48
    80002116:	89aa                	mv	s3,a0
    80002118:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000211a:	00000097          	auipc	ra,0x0
    8000211e:	8ac080e7          	jalr	-1876(ra) # 800019c6 <myproc>
    80002122:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002124:	fffff097          	auipc	ra,0xfffff
    80002128:	ac6080e7          	jalr	-1338(ra) # 80000bea <acquire>
  release(lk);
    8000212c:	854a                	mv	a0,s2
    8000212e:	fffff097          	auipc	ra,0xfffff
    80002132:	b70080e7          	jalr	-1168(ra) # 80000c9e <release>

  // Go to sleep.
  p->chan = chan;
    80002136:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000213a:	4789                	li	a5,2
    8000213c:	cc9c                	sw	a5,24(s1)

  sched();
    8000213e:	00000097          	auipc	ra,0x0
    80002142:	eb8080e7          	jalr	-328(ra) # 80001ff6 <sched>

  // Tidy up.
  p->chan = 0;
    80002146:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000214a:	8526                	mv	a0,s1
    8000214c:	fffff097          	auipc	ra,0xfffff
    80002150:	b52080e7          	jalr	-1198(ra) # 80000c9e <release>
  acquire(lk);
    80002154:	854a                	mv	a0,s2
    80002156:	fffff097          	auipc	ra,0xfffff
    8000215a:	a94080e7          	jalr	-1388(ra) # 80000bea <acquire>
}
    8000215e:	70a2                	ld	ra,40(sp)
    80002160:	7402                	ld	s0,32(sp)
    80002162:	64e2                	ld	s1,24(sp)
    80002164:	6942                	ld	s2,16(sp)
    80002166:	69a2                	ld	s3,8(sp)
    80002168:	6145                	addi	sp,sp,48
    8000216a:	8082                	ret

000000008000216c <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000216c:	7139                	addi	sp,sp,-64
    8000216e:	fc06                	sd	ra,56(sp)
    80002170:	f822                	sd	s0,48(sp)
    80002172:	f426                	sd	s1,40(sp)
    80002174:	f04a                	sd	s2,32(sp)
    80002176:	ec4e                	sd	s3,24(sp)
    80002178:	e852                	sd	s4,16(sp)
    8000217a:	e456                	sd	s5,8(sp)
    8000217c:	0080                	addi	s0,sp,64
    8000217e:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002180:	0000f497          	auipc	s1,0xf
    80002184:	08048493          	addi	s1,s1,128 # 80011200 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002188:	4989                	li	s3,2
        p->state = RUNNABLE;
    8000218a:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000218c:	00015917          	auipc	s2,0x15
    80002190:	c7490913          	addi	s2,s2,-908 # 80016e00 <tickslock>
    80002194:	a821                	j	800021ac <wakeup+0x40>
        p->state = RUNNABLE;
    80002196:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    8000219a:	8526                	mv	a0,s1
    8000219c:	fffff097          	auipc	ra,0xfffff
    800021a0:	b02080e7          	jalr	-1278(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800021a4:	17048493          	addi	s1,s1,368
    800021a8:	03248463          	beq	s1,s2,800021d0 <wakeup+0x64>
    if(p != myproc()){
    800021ac:	00000097          	auipc	ra,0x0
    800021b0:	81a080e7          	jalr	-2022(ra) # 800019c6 <myproc>
    800021b4:	fea488e3          	beq	s1,a0,800021a4 <wakeup+0x38>
      acquire(&p->lock);
    800021b8:	8526                	mv	a0,s1
    800021ba:	fffff097          	auipc	ra,0xfffff
    800021be:	a30080e7          	jalr	-1488(ra) # 80000bea <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800021c2:	4c9c                	lw	a5,24(s1)
    800021c4:	fd379be3          	bne	a5,s3,8000219a <wakeup+0x2e>
    800021c8:	709c                	ld	a5,32(s1)
    800021ca:	fd4798e3          	bne	a5,s4,8000219a <wakeup+0x2e>
    800021ce:	b7e1                	j	80002196 <wakeup+0x2a>
    }
  }
}
    800021d0:	70e2                	ld	ra,56(sp)
    800021d2:	7442                	ld	s0,48(sp)
    800021d4:	74a2                	ld	s1,40(sp)
    800021d6:	7902                	ld	s2,32(sp)
    800021d8:	69e2                	ld	s3,24(sp)
    800021da:	6a42                	ld	s4,16(sp)
    800021dc:	6aa2                	ld	s5,8(sp)
    800021de:	6121                	addi	sp,sp,64
    800021e0:	8082                	ret

00000000800021e2 <reparent>:
{
    800021e2:	7179                	addi	sp,sp,-48
    800021e4:	f406                	sd	ra,40(sp)
    800021e6:	f022                	sd	s0,32(sp)
    800021e8:	ec26                	sd	s1,24(sp)
    800021ea:	e84a                	sd	s2,16(sp)
    800021ec:	e44e                	sd	s3,8(sp)
    800021ee:	e052                	sd	s4,0(sp)
    800021f0:	1800                	addi	s0,sp,48
    800021f2:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021f4:	0000f497          	auipc	s1,0xf
    800021f8:	00c48493          	addi	s1,s1,12 # 80011200 <proc>
      pp->parent = initproc;
    800021fc:	00007a17          	auipc	s4,0x7
    80002200:	934a0a13          	addi	s4,s4,-1740 # 80008b30 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002204:	00015997          	auipc	s3,0x15
    80002208:	bfc98993          	addi	s3,s3,-1028 # 80016e00 <tickslock>
    8000220c:	a029                	j	80002216 <reparent+0x34>
    8000220e:	17048493          	addi	s1,s1,368
    80002212:	01348d63          	beq	s1,s3,8000222c <reparent+0x4a>
    if(pp->parent == p){
    80002216:	7c9c                	ld	a5,56(s1)
    80002218:	ff279be3          	bne	a5,s2,8000220e <reparent+0x2c>
      pp->parent = initproc;
    8000221c:	000a3503          	ld	a0,0(s4)
    80002220:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002222:	00000097          	auipc	ra,0x0
    80002226:	f4a080e7          	jalr	-182(ra) # 8000216c <wakeup>
    8000222a:	b7d5                	j	8000220e <reparent+0x2c>
}
    8000222c:	70a2                	ld	ra,40(sp)
    8000222e:	7402                	ld	s0,32(sp)
    80002230:	64e2                	ld	s1,24(sp)
    80002232:	6942                	ld	s2,16(sp)
    80002234:	69a2                	ld	s3,8(sp)
    80002236:	6a02                	ld	s4,0(sp)
    80002238:	6145                	addi	sp,sp,48
    8000223a:	8082                	ret

000000008000223c <exit>:
{
    8000223c:	7179                	addi	sp,sp,-48
    8000223e:	f406                	sd	ra,40(sp)
    80002240:	f022                	sd	s0,32(sp)
    80002242:	ec26                	sd	s1,24(sp)
    80002244:	e84a                	sd	s2,16(sp)
    80002246:	e44e                	sd	s3,8(sp)
    80002248:	e052                	sd	s4,0(sp)
    8000224a:	1800                	addi	s0,sp,48
    8000224c:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000224e:	fffff097          	auipc	ra,0xfffff
    80002252:	778080e7          	jalr	1912(ra) # 800019c6 <myproc>
    80002256:	89aa                	mv	s3,a0
  if(p == initproc)
    80002258:	00007797          	auipc	a5,0x7
    8000225c:	8d87b783          	ld	a5,-1832(a5) # 80008b30 <initproc>
    80002260:	0d050493          	addi	s1,a0,208
    80002264:	15050913          	addi	s2,a0,336
    80002268:	02a79363          	bne	a5,a0,8000228e <exit+0x52>
    panic("init exiting");
    8000226c:	00006517          	auipc	a0,0x6
    80002270:	ff450513          	addi	a0,a0,-12 # 80008260 <digits+0x220>
    80002274:	ffffe097          	auipc	ra,0xffffe
    80002278:	2d0080e7          	jalr	720(ra) # 80000544 <panic>
      fileclose(f);
    8000227c:	00002097          	auipc	ra,0x2
    80002280:	5fe080e7          	jalr	1534(ra) # 8000487a <fileclose>
      p->ofile[fd] = 0;
    80002284:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002288:	04a1                	addi	s1,s1,8
    8000228a:	01248563          	beq	s1,s2,80002294 <exit+0x58>
    if(p->ofile[fd]){
    8000228e:	6088                	ld	a0,0(s1)
    80002290:	f575                	bnez	a0,8000227c <exit+0x40>
    80002292:	bfdd                	j	80002288 <exit+0x4c>
  begin_op();
    80002294:	00002097          	auipc	ra,0x2
    80002298:	11a080e7          	jalr	282(ra) # 800043ae <begin_op>
  iput(p->cwd);
    8000229c:	1509b503          	ld	a0,336(s3)
    800022a0:	00002097          	auipc	ra,0x2
    800022a4:	906080e7          	jalr	-1786(ra) # 80003ba6 <iput>
  end_op();
    800022a8:	00002097          	auipc	ra,0x2
    800022ac:	186080e7          	jalr	390(ra) # 8000442e <end_op>
  p->cwd = 0;
    800022b0:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800022b4:	0000f497          	auipc	s1,0xf
    800022b8:	b2448493          	addi	s1,s1,-1244 # 80010dd8 <wait_lock>
    800022bc:	8526                	mv	a0,s1
    800022be:	fffff097          	auipc	ra,0xfffff
    800022c2:	92c080e7          	jalr	-1748(ra) # 80000bea <acquire>
  reparent(p);
    800022c6:	854e                	mv	a0,s3
    800022c8:	00000097          	auipc	ra,0x0
    800022cc:	f1a080e7          	jalr	-230(ra) # 800021e2 <reparent>
  wakeup(p->parent);
    800022d0:	0389b503          	ld	a0,56(s3)
    800022d4:	00000097          	auipc	ra,0x0
    800022d8:	e98080e7          	jalr	-360(ra) # 8000216c <wakeup>
  acquire(&p->lock);
    800022dc:	854e                	mv	a0,s3
    800022de:	fffff097          	auipc	ra,0xfffff
    800022e2:	90c080e7          	jalr	-1780(ra) # 80000bea <acquire>
  p->xstate = status;
    800022e6:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800022ea:	4795                	li	a5,5
    800022ec:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800022f0:	8526                	mv	a0,s1
    800022f2:	fffff097          	auipc	ra,0xfffff
    800022f6:	9ac080e7          	jalr	-1620(ra) # 80000c9e <release>
  sched();
    800022fa:	00000097          	auipc	ra,0x0
    800022fe:	cfc080e7          	jalr	-772(ra) # 80001ff6 <sched>
  panic("zombie exit");
    80002302:	00006517          	auipc	a0,0x6
    80002306:	f6e50513          	addi	a0,a0,-146 # 80008270 <digits+0x230>
    8000230a:	ffffe097          	auipc	ra,0xffffe
    8000230e:	23a080e7          	jalr	570(ra) # 80000544 <panic>

0000000080002312 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002312:	7179                	addi	sp,sp,-48
    80002314:	f406                	sd	ra,40(sp)
    80002316:	f022                	sd	s0,32(sp)
    80002318:	ec26                	sd	s1,24(sp)
    8000231a:	e84a                	sd	s2,16(sp)
    8000231c:	e44e                	sd	s3,8(sp)
    8000231e:	1800                	addi	s0,sp,48
    80002320:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002322:	0000f497          	auipc	s1,0xf
    80002326:	ede48493          	addi	s1,s1,-290 # 80011200 <proc>
    8000232a:	00015997          	auipc	s3,0x15
    8000232e:	ad698993          	addi	s3,s3,-1322 # 80016e00 <tickslock>
    acquire(&p->lock);
    80002332:	8526                	mv	a0,s1
    80002334:	fffff097          	auipc	ra,0xfffff
    80002338:	8b6080e7          	jalr	-1866(ra) # 80000bea <acquire>
    if(p->pid == pid){
    8000233c:	589c                	lw	a5,48(s1)
    8000233e:	01278d63          	beq	a5,s2,80002358 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002342:	8526                	mv	a0,s1
    80002344:	fffff097          	auipc	ra,0xfffff
    80002348:	95a080e7          	jalr	-1702(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000234c:	17048493          	addi	s1,s1,368
    80002350:	ff3491e3          	bne	s1,s3,80002332 <kill+0x20>
  }
  return -1;
    80002354:	557d                	li	a0,-1
    80002356:	a829                	j	80002370 <kill+0x5e>
      p->killed = 1;
    80002358:	4785                	li	a5,1
    8000235a:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000235c:	4c98                	lw	a4,24(s1)
    8000235e:	4789                	li	a5,2
    80002360:	00f70f63          	beq	a4,a5,8000237e <kill+0x6c>
      release(&p->lock);
    80002364:	8526                	mv	a0,s1
    80002366:	fffff097          	auipc	ra,0xfffff
    8000236a:	938080e7          	jalr	-1736(ra) # 80000c9e <release>
      return 0;
    8000236e:	4501                	li	a0,0
}
    80002370:	70a2                	ld	ra,40(sp)
    80002372:	7402                	ld	s0,32(sp)
    80002374:	64e2                	ld	s1,24(sp)
    80002376:	6942                	ld	s2,16(sp)
    80002378:	69a2                	ld	s3,8(sp)
    8000237a:	6145                	addi	sp,sp,48
    8000237c:	8082                	ret
        p->state = RUNNABLE;
    8000237e:	478d                	li	a5,3
    80002380:	cc9c                	sw	a5,24(s1)
    80002382:	b7cd                	j	80002364 <kill+0x52>

0000000080002384 <setkilled>:

void
setkilled(struct proc *p)
{
    80002384:	1101                	addi	sp,sp,-32
    80002386:	ec06                	sd	ra,24(sp)
    80002388:	e822                	sd	s0,16(sp)
    8000238a:	e426                	sd	s1,8(sp)
    8000238c:	1000                	addi	s0,sp,32
    8000238e:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002390:	fffff097          	auipc	ra,0xfffff
    80002394:	85a080e7          	jalr	-1958(ra) # 80000bea <acquire>
  p->killed = 1;
    80002398:	4785                	li	a5,1
    8000239a:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    8000239c:	8526                	mv	a0,s1
    8000239e:	fffff097          	auipc	ra,0xfffff
    800023a2:	900080e7          	jalr	-1792(ra) # 80000c9e <release>
}
    800023a6:	60e2                	ld	ra,24(sp)
    800023a8:	6442                	ld	s0,16(sp)
    800023aa:	64a2                	ld	s1,8(sp)
    800023ac:	6105                	addi	sp,sp,32
    800023ae:	8082                	ret

00000000800023b0 <killed>:

int
killed(struct proc *p)
{
    800023b0:	1101                	addi	sp,sp,-32
    800023b2:	ec06                	sd	ra,24(sp)
    800023b4:	e822                	sd	s0,16(sp)
    800023b6:	e426                	sd	s1,8(sp)
    800023b8:	e04a                	sd	s2,0(sp)
    800023ba:	1000                	addi	s0,sp,32
    800023bc:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    800023be:	fffff097          	auipc	ra,0xfffff
    800023c2:	82c080e7          	jalr	-2004(ra) # 80000bea <acquire>
  k = p->killed;
    800023c6:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800023ca:	8526                	mv	a0,s1
    800023cc:	fffff097          	auipc	ra,0xfffff
    800023d0:	8d2080e7          	jalr	-1838(ra) # 80000c9e <release>
  return k;
}
    800023d4:	854a                	mv	a0,s2
    800023d6:	60e2                	ld	ra,24(sp)
    800023d8:	6442                	ld	s0,16(sp)
    800023da:	64a2                	ld	s1,8(sp)
    800023dc:	6902                	ld	s2,0(sp)
    800023de:	6105                	addi	sp,sp,32
    800023e0:	8082                	ret

00000000800023e2 <wait>:
{
    800023e2:	715d                	addi	sp,sp,-80
    800023e4:	e486                	sd	ra,72(sp)
    800023e6:	e0a2                	sd	s0,64(sp)
    800023e8:	fc26                	sd	s1,56(sp)
    800023ea:	f84a                	sd	s2,48(sp)
    800023ec:	f44e                	sd	s3,40(sp)
    800023ee:	f052                	sd	s4,32(sp)
    800023f0:	ec56                	sd	s5,24(sp)
    800023f2:	e85a                	sd	s6,16(sp)
    800023f4:	e45e                	sd	s7,8(sp)
    800023f6:	e062                	sd	s8,0(sp)
    800023f8:	0880                	addi	s0,sp,80
    800023fa:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800023fc:	fffff097          	auipc	ra,0xfffff
    80002400:	5ca080e7          	jalr	1482(ra) # 800019c6 <myproc>
    80002404:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002406:	0000f517          	auipc	a0,0xf
    8000240a:	9d250513          	addi	a0,a0,-1582 # 80010dd8 <wait_lock>
    8000240e:	ffffe097          	auipc	ra,0xffffe
    80002412:	7dc080e7          	jalr	2012(ra) # 80000bea <acquire>
    havekids = 0;
    80002416:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    80002418:	4a15                	li	s4,5
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000241a:	00015997          	auipc	s3,0x15
    8000241e:	9e698993          	addi	s3,s3,-1562 # 80016e00 <tickslock>
        havekids = 1;
    80002422:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002424:	0000fc17          	auipc	s8,0xf
    80002428:	9b4c0c13          	addi	s8,s8,-1612 # 80010dd8 <wait_lock>
    havekids = 0;
    8000242c:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000242e:	0000f497          	auipc	s1,0xf
    80002432:	dd248493          	addi	s1,s1,-558 # 80011200 <proc>
    80002436:	a0bd                	j	800024a4 <wait+0xc2>
          pid = pp->pid;
    80002438:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    8000243c:	000b0e63          	beqz	s6,80002458 <wait+0x76>
    80002440:	4691                	li	a3,4
    80002442:	02c48613          	addi	a2,s1,44
    80002446:	85da                	mv	a1,s6
    80002448:	05093503          	ld	a0,80(s2)
    8000244c:	fffff097          	auipc	ra,0xfffff
    80002450:	238080e7          	jalr	568(ra) # 80001684 <copyout>
    80002454:	02054563          	bltz	a0,8000247e <wait+0x9c>
          freeproc(pp);
    80002458:	8526                	mv	a0,s1
    8000245a:	fffff097          	auipc	ra,0xfffff
    8000245e:	71e080e7          	jalr	1822(ra) # 80001b78 <freeproc>
          release(&pp->lock);
    80002462:	8526                	mv	a0,s1
    80002464:	fffff097          	auipc	ra,0xfffff
    80002468:	83a080e7          	jalr	-1990(ra) # 80000c9e <release>
          release(&wait_lock);
    8000246c:	0000f517          	auipc	a0,0xf
    80002470:	96c50513          	addi	a0,a0,-1684 # 80010dd8 <wait_lock>
    80002474:	fffff097          	auipc	ra,0xfffff
    80002478:	82a080e7          	jalr	-2006(ra) # 80000c9e <release>
          return pid;
    8000247c:	a0b5                	j	800024e8 <wait+0x106>
            release(&pp->lock);
    8000247e:	8526                	mv	a0,s1
    80002480:	fffff097          	auipc	ra,0xfffff
    80002484:	81e080e7          	jalr	-2018(ra) # 80000c9e <release>
            release(&wait_lock);
    80002488:	0000f517          	auipc	a0,0xf
    8000248c:	95050513          	addi	a0,a0,-1712 # 80010dd8 <wait_lock>
    80002490:	fffff097          	auipc	ra,0xfffff
    80002494:	80e080e7          	jalr	-2034(ra) # 80000c9e <release>
            return -1;
    80002498:	59fd                	li	s3,-1
    8000249a:	a0b9                	j	800024e8 <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    8000249c:	17048493          	addi	s1,s1,368
    800024a0:	03348463          	beq	s1,s3,800024c8 <wait+0xe6>
      if(pp->parent == p){
    800024a4:	7c9c                	ld	a5,56(s1)
    800024a6:	ff279be3          	bne	a5,s2,8000249c <wait+0xba>
        acquire(&pp->lock);
    800024aa:	8526                	mv	a0,s1
    800024ac:	ffffe097          	auipc	ra,0xffffe
    800024b0:	73e080e7          	jalr	1854(ra) # 80000bea <acquire>
        if(pp->state == ZOMBIE){
    800024b4:	4c9c                	lw	a5,24(s1)
    800024b6:	f94781e3          	beq	a5,s4,80002438 <wait+0x56>
        release(&pp->lock);
    800024ba:	8526                	mv	a0,s1
    800024bc:	ffffe097          	auipc	ra,0xffffe
    800024c0:	7e2080e7          	jalr	2018(ra) # 80000c9e <release>
        havekids = 1;
    800024c4:	8756                	mv	a4,s5
    800024c6:	bfd9                	j	8000249c <wait+0xba>
    if(!havekids || killed(p)){
    800024c8:	c719                	beqz	a4,800024d6 <wait+0xf4>
    800024ca:	854a                	mv	a0,s2
    800024cc:	00000097          	auipc	ra,0x0
    800024d0:	ee4080e7          	jalr	-284(ra) # 800023b0 <killed>
    800024d4:	c51d                	beqz	a0,80002502 <wait+0x120>
      release(&wait_lock);
    800024d6:	0000f517          	auipc	a0,0xf
    800024da:	90250513          	addi	a0,a0,-1790 # 80010dd8 <wait_lock>
    800024de:	ffffe097          	auipc	ra,0xffffe
    800024e2:	7c0080e7          	jalr	1984(ra) # 80000c9e <release>
      return -1;
    800024e6:	59fd                	li	s3,-1
}
    800024e8:	854e                	mv	a0,s3
    800024ea:	60a6                	ld	ra,72(sp)
    800024ec:	6406                	ld	s0,64(sp)
    800024ee:	74e2                	ld	s1,56(sp)
    800024f0:	7942                	ld	s2,48(sp)
    800024f2:	79a2                	ld	s3,40(sp)
    800024f4:	7a02                	ld	s4,32(sp)
    800024f6:	6ae2                	ld	s5,24(sp)
    800024f8:	6b42                	ld	s6,16(sp)
    800024fa:	6ba2                	ld	s7,8(sp)
    800024fc:	6c02                	ld	s8,0(sp)
    800024fe:	6161                	addi	sp,sp,80
    80002500:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002502:	85e2                	mv	a1,s8
    80002504:	854a                	mv	a0,s2
    80002506:	00000097          	auipc	ra,0x0
    8000250a:	c02080e7          	jalr	-1022(ra) # 80002108 <sleep>
    havekids = 0;
    8000250e:	bf39                	j	8000242c <wait+0x4a>

0000000080002510 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002510:	7179                	addi	sp,sp,-48
    80002512:	f406                	sd	ra,40(sp)
    80002514:	f022                	sd	s0,32(sp)
    80002516:	ec26                	sd	s1,24(sp)
    80002518:	e84a                	sd	s2,16(sp)
    8000251a:	e44e                	sd	s3,8(sp)
    8000251c:	e052                	sd	s4,0(sp)
    8000251e:	1800                	addi	s0,sp,48
    80002520:	84aa                	mv	s1,a0
    80002522:	892e                	mv	s2,a1
    80002524:	89b2                	mv	s3,a2
    80002526:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002528:	fffff097          	auipc	ra,0xfffff
    8000252c:	49e080e7          	jalr	1182(ra) # 800019c6 <myproc>
  if(user_dst){
    80002530:	c08d                	beqz	s1,80002552 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002532:	86d2                	mv	a3,s4
    80002534:	864e                	mv	a2,s3
    80002536:	85ca                	mv	a1,s2
    80002538:	6928                	ld	a0,80(a0)
    8000253a:	fffff097          	auipc	ra,0xfffff
    8000253e:	14a080e7          	jalr	330(ra) # 80001684 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002542:	70a2                	ld	ra,40(sp)
    80002544:	7402                	ld	s0,32(sp)
    80002546:	64e2                	ld	s1,24(sp)
    80002548:	6942                	ld	s2,16(sp)
    8000254a:	69a2                	ld	s3,8(sp)
    8000254c:	6a02                	ld	s4,0(sp)
    8000254e:	6145                	addi	sp,sp,48
    80002550:	8082                	ret
    memmove((char *)dst, src, len);
    80002552:	000a061b          	sext.w	a2,s4
    80002556:	85ce                	mv	a1,s3
    80002558:	854a                	mv	a0,s2
    8000255a:	ffffe097          	auipc	ra,0xffffe
    8000255e:	7ec080e7          	jalr	2028(ra) # 80000d46 <memmove>
    return 0;
    80002562:	8526                	mv	a0,s1
    80002564:	bff9                	j	80002542 <either_copyout+0x32>

0000000080002566 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002566:	7179                	addi	sp,sp,-48
    80002568:	f406                	sd	ra,40(sp)
    8000256a:	f022                	sd	s0,32(sp)
    8000256c:	ec26                	sd	s1,24(sp)
    8000256e:	e84a                	sd	s2,16(sp)
    80002570:	e44e                	sd	s3,8(sp)
    80002572:	e052                	sd	s4,0(sp)
    80002574:	1800                	addi	s0,sp,48
    80002576:	892a                	mv	s2,a0
    80002578:	84ae                	mv	s1,a1
    8000257a:	89b2                	mv	s3,a2
    8000257c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000257e:	fffff097          	auipc	ra,0xfffff
    80002582:	448080e7          	jalr	1096(ra) # 800019c6 <myproc>
  if(user_src){
    80002586:	c08d                	beqz	s1,800025a8 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002588:	86d2                	mv	a3,s4
    8000258a:	864e                	mv	a2,s3
    8000258c:	85ca                	mv	a1,s2
    8000258e:	6928                	ld	a0,80(a0)
    80002590:	fffff097          	auipc	ra,0xfffff
    80002594:	180080e7          	jalr	384(ra) # 80001710 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002598:	70a2                	ld	ra,40(sp)
    8000259a:	7402                	ld	s0,32(sp)
    8000259c:	64e2                	ld	s1,24(sp)
    8000259e:	6942                	ld	s2,16(sp)
    800025a0:	69a2                	ld	s3,8(sp)
    800025a2:	6a02                	ld	s4,0(sp)
    800025a4:	6145                	addi	sp,sp,48
    800025a6:	8082                	ret
    memmove(dst, (char*)src, len);
    800025a8:	000a061b          	sext.w	a2,s4
    800025ac:	85ce                	mv	a1,s3
    800025ae:	854a                	mv	a0,s2
    800025b0:	ffffe097          	auipc	ra,0xffffe
    800025b4:	796080e7          	jalr	1942(ra) # 80000d46 <memmove>
    return 0;
    800025b8:	8526                	mv	a0,s1
    800025ba:	bff9                	j	80002598 <either_copyin+0x32>

00000000800025bc <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800025bc:	715d                	addi	sp,sp,-80
    800025be:	e486                	sd	ra,72(sp)
    800025c0:	e0a2                	sd	s0,64(sp)
    800025c2:	fc26                	sd	s1,56(sp)
    800025c4:	f84a                	sd	s2,48(sp)
    800025c6:	f44e                	sd	s3,40(sp)
    800025c8:	f052                	sd	s4,32(sp)
    800025ca:	ec56                	sd	s5,24(sp)
    800025cc:	e85a                	sd	s6,16(sp)
    800025ce:	e45e                	sd	s7,8(sp)
    800025d0:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800025d2:	00006517          	auipc	a0,0x6
    800025d6:	38e50513          	addi	a0,a0,910 # 80008960 <syscalls+0x460>
    800025da:	ffffe097          	auipc	ra,0xffffe
    800025de:	fb4080e7          	jalr	-76(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025e2:	0000f497          	auipc	s1,0xf
    800025e6:	d7648493          	addi	s1,s1,-650 # 80011358 <proc+0x158>
    800025ea:	00015917          	auipc	s2,0x15
    800025ee:	96e90913          	addi	s2,s2,-1682 # 80016f58 <buff+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025f2:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800025f4:	00006997          	auipc	s3,0x6
    800025f8:	c8c98993          	addi	s3,s3,-884 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    800025fc:	00006a97          	auipc	s5,0x6
    80002600:	c8ca8a93          	addi	s5,s5,-884 # 80008288 <digits+0x248>
    printf("\n");
    80002604:	00006a17          	auipc	s4,0x6
    80002608:	35ca0a13          	addi	s4,s4,860 # 80008960 <syscalls+0x460>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000260c:	00006b97          	auipc	s7,0x6
    80002610:	cbcb8b93          	addi	s7,s7,-836 # 800082c8 <states.1761>
    80002614:	a00d                	j	80002636 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002616:	ed86a583          	lw	a1,-296(a3)
    8000261a:	8556                	mv	a0,s5
    8000261c:	ffffe097          	auipc	ra,0xffffe
    80002620:	f72080e7          	jalr	-142(ra) # 8000058e <printf>
    printf("\n");
    80002624:	8552                	mv	a0,s4
    80002626:	ffffe097          	auipc	ra,0xffffe
    8000262a:	f68080e7          	jalr	-152(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000262e:	17048493          	addi	s1,s1,368
    80002632:	03248163          	beq	s1,s2,80002654 <procdump+0x98>
    if(p->state == UNUSED)
    80002636:	86a6                	mv	a3,s1
    80002638:	ec04a783          	lw	a5,-320(s1)
    8000263c:	dbed                	beqz	a5,8000262e <procdump+0x72>
      state = "???";
    8000263e:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002640:	fcfb6be3          	bltu	s6,a5,80002616 <procdump+0x5a>
    80002644:	1782                	slli	a5,a5,0x20
    80002646:	9381                	srli	a5,a5,0x20
    80002648:	078e                	slli	a5,a5,0x3
    8000264a:	97de                	add	a5,a5,s7
    8000264c:	6390                	ld	a2,0(a5)
    8000264e:	f661                	bnez	a2,80002616 <procdump+0x5a>
      state = "???";
    80002650:	864e                	mv	a2,s3
    80002652:	b7d1                	j	80002616 <procdump+0x5a>
  }
}
    80002654:	60a6                	ld	ra,72(sp)
    80002656:	6406                	ld	s0,64(sp)
    80002658:	74e2                	ld	s1,56(sp)
    8000265a:	7942                	ld	s2,48(sp)
    8000265c:	79a2                	ld	s3,40(sp)
    8000265e:	7a02                	ld	s4,32(sp)
    80002660:	6ae2                	ld	s5,24(sp)
    80002662:	6b42                	ld	s6,16(sp)
    80002664:	6ba2                	ld	s7,8(sp)
    80002666:	6161                	addi	sp,sp,80
    80002668:	8082                	ret

000000008000266a <swtch>:
    8000266a:	00153023          	sd	ra,0(a0)
    8000266e:	00253423          	sd	sp,8(a0)
    80002672:	e900                	sd	s0,16(a0)
    80002674:	ed04                	sd	s1,24(a0)
    80002676:	03253023          	sd	s2,32(a0)
    8000267a:	03353423          	sd	s3,40(a0)
    8000267e:	03453823          	sd	s4,48(a0)
    80002682:	03553c23          	sd	s5,56(a0)
    80002686:	05653023          	sd	s6,64(a0)
    8000268a:	05753423          	sd	s7,72(a0)
    8000268e:	05853823          	sd	s8,80(a0)
    80002692:	05953c23          	sd	s9,88(a0)
    80002696:	07a53023          	sd	s10,96(a0)
    8000269a:	07b53423          	sd	s11,104(a0)
    8000269e:	0005b083          	ld	ra,0(a1)
    800026a2:	0085b103          	ld	sp,8(a1)
    800026a6:	6980                	ld	s0,16(a1)
    800026a8:	6d84                	ld	s1,24(a1)
    800026aa:	0205b903          	ld	s2,32(a1)
    800026ae:	0285b983          	ld	s3,40(a1)
    800026b2:	0305ba03          	ld	s4,48(a1)
    800026b6:	0385ba83          	ld	s5,56(a1)
    800026ba:	0405bb03          	ld	s6,64(a1)
    800026be:	0485bb83          	ld	s7,72(a1)
    800026c2:	0505bc03          	ld	s8,80(a1)
    800026c6:	0585bc83          	ld	s9,88(a1)
    800026ca:	0605bd03          	ld	s10,96(a1)
    800026ce:	0685bd83          	ld	s11,104(a1)
    800026d2:	8082                	ret

00000000800026d4 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026d4:	1141                	addi	sp,sp,-16
    800026d6:	e406                	sd	ra,8(sp)
    800026d8:	e022                	sd	s0,0(sp)
    800026da:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026dc:	00006597          	auipc	a1,0x6
    800026e0:	c1c58593          	addi	a1,a1,-996 # 800082f8 <states.1761+0x30>
    800026e4:	00014517          	auipc	a0,0x14
    800026e8:	71c50513          	addi	a0,a0,1820 # 80016e00 <tickslock>
    800026ec:	ffffe097          	auipc	ra,0xffffe
    800026f0:	46e080e7          	jalr	1134(ra) # 80000b5a <initlock>
}
    800026f4:	60a2                	ld	ra,8(sp)
    800026f6:	6402                	ld	s0,0(sp)
    800026f8:	0141                	addi	sp,sp,16
    800026fa:	8082                	ret

00000000800026fc <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800026fc:	1141                	addi	sp,sp,-16
    800026fe:	e422                	sd	s0,8(sp)
    80002700:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002702:	00003797          	auipc	a5,0x3
    80002706:	7be78793          	addi	a5,a5,1982 # 80005ec0 <kernelvec>
    8000270a:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    8000270e:	6422                	ld	s0,8(sp)
    80002710:	0141                	addi	sp,sp,16
    80002712:	8082                	ret

0000000080002714 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002714:	1141                	addi	sp,sp,-16
    80002716:	e406                	sd	ra,8(sp)
    80002718:	e022                	sd	s0,0(sp)
    8000271a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000271c:	fffff097          	auipc	ra,0xfffff
    80002720:	2aa080e7          	jalr	682(ra) # 800019c6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002724:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002728:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000272a:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    8000272e:	00005617          	auipc	a2,0x5
    80002732:	8d260613          	addi	a2,a2,-1838 # 80007000 <_trampoline>
    80002736:	00005697          	auipc	a3,0x5
    8000273a:	8ca68693          	addi	a3,a3,-1846 # 80007000 <_trampoline>
    8000273e:	8e91                	sub	a3,a3,a2
    80002740:	040007b7          	lui	a5,0x4000
    80002744:	17fd                	addi	a5,a5,-1
    80002746:	07b2                	slli	a5,a5,0xc
    80002748:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000274a:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000274e:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002750:	180026f3          	csrr	a3,satp
    80002754:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002756:	6d38                	ld	a4,88(a0)
    80002758:	6134                	ld	a3,64(a0)
    8000275a:	6585                	lui	a1,0x1
    8000275c:	96ae                	add	a3,a3,a1
    8000275e:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002760:	6d38                	ld	a4,88(a0)
    80002762:	00000697          	auipc	a3,0x0
    80002766:	13068693          	addi	a3,a3,304 # 80002892 <usertrap>
    8000276a:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000276c:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000276e:	8692                	mv	a3,tp
    80002770:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002772:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002776:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000277a:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000277e:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002782:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002784:	6f18                	ld	a4,24(a4)
    80002786:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000278a:	6928                	ld	a0,80(a0)
    8000278c:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    8000278e:	00005717          	auipc	a4,0x5
    80002792:	90e70713          	addi	a4,a4,-1778 # 8000709c <userret>
    80002796:	8f11                	sub	a4,a4,a2
    80002798:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    8000279a:	577d                	li	a4,-1
    8000279c:	177e                	slli	a4,a4,0x3f
    8000279e:	8d59                	or	a0,a0,a4
    800027a0:	9782                	jalr	a5
}
    800027a2:	60a2                	ld	ra,8(sp)
    800027a4:	6402                	ld	s0,0(sp)
    800027a6:	0141                	addi	sp,sp,16
    800027a8:	8082                	ret

00000000800027aa <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800027aa:	1101                	addi	sp,sp,-32
    800027ac:	ec06                	sd	ra,24(sp)
    800027ae:	e822                	sd	s0,16(sp)
    800027b0:	e426                	sd	s1,8(sp)
    800027b2:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800027b4:	00014497          	auipc	s1,0x14
    800027b8:	64c48493          	addi	s1,s1,1612 # 80016e00 <tickslock>
    800027bc:	8526                	mv	a0,s1
    800027be:	ffffe097          	auipc	ra,0xffffe
    800027c2:	42c080e7          	jalr	1068(ra) # 80000bea <acquire>
  ticks++;
    800027c6:	00006517          	auipc	a0,0x6
    800027ca:	37250513          	addi	a0,a0,882 # 80008b38 <ticks>
    800027ce:	411c                	lw	a5,0(a0)
    800027d0:	2785                	addiw	a5,a5,1
    800027d2:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800027d4:	00000097          	auipc	ra,0x0
    800027d8:	998080e7          	jalr	-1640(ra) # 8000216c <wakeup>
  release(&tickslock);
    800027dc:	8526                	mv	a0,s1
    800027de:	ffffe097          	auipc	ra,0xffffe
    800027e2:	4c0080e7          	jalr	1216(ra) # 80000c9e <release>
}
    800027e6:	60e2                	ld	ra,24(sp)
    800027e8:	6442                	ld	s0,16(sp)
    800027ea:	64a2                	ld	s1,8(sp)
    800027ec:	6105                	addi	sp,sp,32
    800027ee:	8082                	ret

00000000800027f0 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800027f0:	1101                	addi	sp,sp,-32
    800027f2:	ec06                	sd	ra,24(sp)
    800027f4:	e822                	sd	s0,16(sp)
    800027f6:	e426                	sd	s1,8(sp)
    800027f8:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027fa:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800027fe:	00074d63          	bltz	a4,80002818 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002802:	57fd                	li	a5,-1
    80002804:	17fe                	slli	a5,a5,0x3f
    80002806:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002808:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000280a:	06f70363          	beq	a4,a5,80002870 <devintr+0x80>
  }
}
    8000280e:	60e2                	ld	ra,24(sp)
    80002810:	6442                	ld	s0,16(sp)
    80002812:	64a2                	ld	s1,8(sp)
    80002814:	6105                	addi	sp,sp,32
    80002816:	8082                	ret
     (scause & 0xff) == 9){
    80002818:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000281c:	46a5                	li	a3,9
    8000281e:	fed792e3          	bne	a5,a3,80002802 <devintr+0x12>
    int irq = plic_claim();
    80002822:	00003097          	auipc	ra,0x3
    80002826:	7a6080e7          	jalr	1958(ra) # 80005fc8 <plic_claim>
    8000282a:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000282c:	47a9                	li	a5,10
    8000282e:	02f50763          	beq	a0,a5,8000285c <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002832:	4785                	li	a5,1
    80002834:	02f50963          	beq	a0,a5,80002866 <devintr+0x76>
    return 1;
    80002838:	4505                	li	a0,1
    } else if(irq){
    8000283a:	d8f1                	beqz	s1,8000280e <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000283c:	85a6                	mv	a1,s1
    8000283e:	00006517          	auipc	a0,0x6
    80002842:	ac250513          	addi	a0,a0,-1342 # 80008300 <states.1761+0x38>
    80002846:	ffffe097          	auipc	ra,0xffffe
    8000284a:	d48080e7          	jalr	-696(ra) # 8000058e <printf>
      plic_complete(irq);
    8000284e:	8526                	mv	a0,s1
    80002850:	00003097          	auipc	ra,0x3
    80002854:	79c080e7          	jalr	1948(ra) # 80005fec <plic_complete>
    return 1;
    80002858:	4505                	li	a0,1
    8000285a:	bf55                	j	8000280e <devintr+0x1e>
      uartintr();
    8000285c:	ffffe097          	auipc	ra,0xffffe
    80002860:	152080e7          	jalr	338(ra) # 800009ae <uartintr>
    80002864:	b7ed                	j	8000284e <devintr+0x5e>
      virtio_disk_intr();
    80002866:	00004097          	auipc	ra,0x4
    8000286a:	cb0080e7          	jalr	-848(ra) # 80006516 <virtio_disk_intr>
    8000286e:	b7c5                	j	8000284e <devintr+0x5e>
    if(cpuid() == 0){
    80002870:	fffff097          	auipc	ra,0xfffff
    80002874:	12a080e7          	jalr	298(ra) # 8000199a <cpuid>
    80002878:	c901                	beqz	a0,80002888 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000287a:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000287e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002880:	14479073          	csrw	sip,a5
    return 2;
    80002884:	4509                	li	a0,2
    80002886:	b761                	j	8000280e <devintr+0x1e>
      clockintr();
    80002888:	00000097          	auipc	ra,0x0
    8000288c:	f22080e7          	jalr	-222(ra) # 800027aa <clockintr>
    80002890:	b7ed                	j	8000287a <devintr+0x8a>

0000000080002892 <usertrap>:
{
    80002892:	1101                	addi	sp,sp,-32
    80002894:	ec06                	sd	ra,24(sp)
    80002896:	e822                	sd	s0,16(sp)
    80002898:	e426                	sd	s1,8(sp)
    8000289a:	e04a                	sd	s2,0(sp)
    8000289c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000289e:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    800028a2:	1007f793          	andi	a5,a5,256
    800028a6:	e3b1                	bnez	a5,800028ea <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028a8:	00003797          	auipc	a5,0x3
    800028ac:	61878793          	addi	a5,a5,1560 # 80005ec0 <kernelvec>
    800028b0:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800028b4:	fffff097          	auipc	ra,0xfffff
    800028b8:	112080e7          	jalr	274(ra) # 800019c6 <myproc>
    800028bc:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800028be:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028c0:	14102773          	csrr	a4,sepc
    800028c4:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028c6:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800028ca:	47a1                	li	a5,8
    800028cc:	02f70763          	beq	a4,a5,800028fa <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    800028d0:	00000097          	auipc	ra,0x0
    800028d4:	f20080e7          	jalr	-224(ra) # 800027f0 <devintr>
    800028d8:	892a                	mv	s2,a0
    800028da:	c151                	beqz	a0,8000295e <usertrap+0xcc>
  if(killed(p))
    800028dc:	8526                	mv	a0,s1
    800028de:	00000097          	auipc	ra,0x0
    800028e2:	ad2080e7          	jalr	-1326(ra) # 800023b0 <killed>
    800028e6:	c929                	beqz	a0,80002938 <usertrap+0xa6>
    800028e8:	a099                	j	8000292e <usertrap+0x9c>
    panic("usertrap: not from user mode");
    800028ea:	00006517          	auipc	a0,0x6
    800028ee:	a3650513          	addi	a0,a0,-1482 # 80008320 <states.1761+0x58>
    800028f2:	ffffe097          	auipc	ra,0xffffe
    800028f6:	c52080e7          	jalr	-942(ra) # 80000544 <panic>
    if(killed(p))
    800028fa:	00000097          	auipc	ra,0x0
    800028fe:	ab6080e7          	jalr	-1354(ra) # 800023b0 <killed>
    80002902:	e921                	bnez	a0,80002952 <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002904:	6cb8                	ld	a4,88(s1)
    80002906:	6f1c                	ld	a5,24(a4)
    80002908:	0791                	addi	a5,a5,4
    8000290a:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000290c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002910:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002914:	10079073          	csrw	sstatus,a5
    syscall();
    80002918:	00000097          	auipc	ra,0x0
    8000291c:	2d4080e7          	jalr	724(ra) # 80002bec <syscall>
  if(killed(p))
    80002920:	8526                	mv	a0,s1
    80002922:	00000097          	auipc	ra,0x0
    80002926:	a8e080e7          	jalr	-1394(ra) # 800023b0 <killed>
    8000292a:	c911                	beqz	a0,8000293e <usertrap+0xac>
    8000292c:	4901                	li	s2,0
    exit(-1);
    8000292e:	557d                	li	a0,-1
    80002930:	00000097          	auipc	ra,0x0
    80002934:	90c080e7          	jalr	-1780(ra) # 8000223c <exit>
  if(which_dev == 2)
    80002938:	4789                	li	a5,2
    8000293a:	04f90f63          	beq	s2,a5,80002998 <usertrap+0x106>
  usertrapret();
    8000293e:	00000097          	auipc	ra,0x0
    80002942:	dd6080e7          	jalr	-554(ra) # 80002714 <usertrapret>
}
    80002946:	60e2                	ld	ra,24(sp)
    80002948:	6442                	ld	s0,16(sp)
    8000294a:	64a2                	ld	s1,8(sp)
    8000294c:	6902                	ld	s2,0(sp)
    8000294e:	6105                	addi	sp,sp,32
    80002950:	8082                	ret
      exit(-1);
    80002952:	557d                	li	a0,-1
    80002954:	00000097          	auipc	ra,0x0
    80002958:	8e8080e7          	jalr	-1816(ra) # 8000223c <exit>
    8000295c:	b765                	j	80002904 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000295e:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002962:	5890                	lw	a2,48(s1)
    80002964:	00006517          	auipc	a0,0x6
    80002968:	9dc50513          	addi	a0,a0,-1572 # 80008340 <states.1761+0x78>
    8000296c:	ffffe097          	auipc	ra,0xffffe
    80002970:	c22080e7          	jalr	-990(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002974:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002978:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000297c:	00006517          	auipc	a0,0x6
    80002980:	9f450513          	addi	a0,a0,-1548 # 80008370 <states.1761+0xa8>
    80002984:	ffffe097          	auipc	ra,0xffffe
    80002988:	c0a080e7          	jalr	-1014(ra) # 8000058e <printf>
    setkilled(p);
    8000298c:	8526                	mv	a0,s1
    8000298e:	00000097          	auipc	ra,0x0
    80002992:	9f6080e7          	jalr	-1546(ra) # 80002384 <setkilled>
    80002996:	b769                	j	80002920 <usertrap+0x8e>
    yield();
    80002998:	fffff097          	auipc	ra,0xfffff
    8000299c:	734080e7          	jalr	1844(ra) # 800020cc <yield>
    800029a0:	bf79                	j	8000293e <usertrap+0xac>

00000000800029a2 <kerneltrap>:
{
    800029a2:	7179                	addi	sp,sp,-48
    800029a4:	f406                	sd	ra,40(sp)
    800029a6:	f022                	sd	s0,32(sp)
    800029a8:	ec26                	sd	s1,24(sp)
    800029aa:	e84a                	sd	s2,16(sp)
    800029ac:	e44e                	sd	s3,8(sp)
    800029ae:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029b0:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029b4:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029b8:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800029bc:	1004f793          	andi	a5,s1,256
    800029c0:	cb85                	beqz	a5,800029f0 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029c2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800029c6:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800029c8:	ef85                	bnez	a5,80002a00 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800029ca:	00000097          	auipc	ra,0x0
    800029ce:	e26080e7          	jalr	-474(ra) # 800027f0 <devintr>
    800029d2:	cd1d                	beqz	a0,80002a10 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029d4:	4789                	li	a5,2
    800029d6:	06f50a63          	beq	a0,a5,80002a4a <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029da:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029de:	10049073          	csrw	sstatus,s1
}
    800029e2:	70a2                	ld	ra,40(sp)
    800029e4:	7402                	ld	s0,32(sp)
    800029e6:	64e2                	ld	s1,24(sp)
    800029e8:	6942                	ld	s2,16(sp)
    800029ea:	69a2                	ld	s3,8(sp)
    800029ec:	6145                	addi	sp,sp,48
    800029ee:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800029f0:	00006517          	auipc	a0,0x6
    800029f4:	9a050513          	addi	a0,a0,-1632 # 80008390 <states.1761+0xc8>
    800029f8:	ffffe097          	auipc	ra,0xffffe
    800029fc:	b4c080e7          	jalr	-1204(ra) # 80000544 <panic>
    panic("kerneltrap: interrupts enabled");
    80002a00:	00006517          	auipc	a0,0x6
    80002a04:	9b850513          	addi	a0,a0,-1608 # 800083b8 <states.1761+0xf0>
    80002a08:	ffffe097          	auipc	ra,0xffffe
    80002a0c:	b3c080e7          	jalr	-1220(ra) # 80000544 <panic>
    printf("scause %p\n", scause);
    80002a10:	85ce                	mv	a1,s3
    80002a12:	00006517          	auipc	a0,0x6
    80002a16:	9c650513          	addi	a0,a0,-1594 # 800083d8 <states.1761+0x110>
    80002a1a:	ffffe097          	auipc	ra,0xffffe
    80002a1e:	b74080e7          	jalr	-1164(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a22:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a26:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a2a:	00006517          	auipc	a0,0x6
    80002a2e:	9be50513          	addi	a0,a0,-1602 # 800083e8 <states.1761+0x120>
    80002a32:	ffffe097          	auipc	ra,0xffffe
    80002a36:	b5c080e7          	jalr	-1188(ra) # 8000058e <printf>
    panic("kerneltrap");
    80002a3a:	00006517          	auipc	a0,0x6
    80002a3e:	9c650513          	addi	a0,a0,-1594 # 80008400 <states.1761+0x138>
    80002a42:	ffffe097          	auipc	ra,0xffffe
    80002a46:	b02080e7          	jalr	-1278(ra) # 80000544 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a4a:	fffff097          	auipc	ra,0xfffff
    80002a4e:	f7c080e7          	jalr	-132(ra) # 800019c6 <myproc>
    80002a52:	d541                	beqz	a0,800029da <kerneltrap+0x38>
    80002a54:	fffff097          	auipc	ra,0xfffff
    80002a58:	f72080e7          	jalr	-142(ra) # 800019c6 <myproc>
    80002a5c:	4d18                	lw	a4,24(a0)
    80002a5e:	4791                	li	a5,4
    80002a60:	f6f71de3          	bne	a4,a5,800029da <kerneltrap+0x38>
    yield();
    80002a64:	fffff097          	auipc	ra,0xfffff
    80002a68:	668080e7          	jalr	1640(ra) # 800020cc <yield>
    80002a6c:	b7bd                	j	800029da <kerneltrap+0x38>

0000000080002a6e <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a6e:	1101                	addi	sp,sp,-32
    80002a70:	ec06                	sd	ra,24(sp)
    80002a72:	e822                	sd	s0,16(sp)
    80002a74:	e426                	sd	s1,8(sp)
    80002a76:	1000                	addi	s0,sp,32
    80002a78:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a7a:	fffff097          	auipc	ra,0xfffff
    80002a7e:	f4c080e7          	jalr	-180(ra) # 800019c6 <myproc>
  switch (n) {
    80002a82:	4795                	li	a5,5
    80002a84:	0497e163          	bltu	a5,s1,80002ac6 <argraw+0x58>
    80002a88:	048a                	slli	s1,s1,0x2
    80002a8a:	00006717          	auipc	a4,0x6
    80002a8e:	a5e70713          	addi	a4,a4,-1442 # 800084e8 <states.1761+0x220>
    80002a92:	94ba                	add	s1,s1,a4
    80002a94:	409c                	lw	a5,0(s1)
    80002a96:	97ba                	add	a5,a5,a4
    80002a98:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a9a:	6d3c                	ld	a5,88(a0)
    80002a9c:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a9e:	60e2                	ld	ra,24(sp)
    80002aa0:	6442                	ld	s0,16(sp)
    80002aa2:	64a2                	ld	s1,8(sp)
    80002aa4:	6105                	addi	sp,sp,32
    80002aa6:	8082                	ret
    return p->trapframe->a1;
    80002aa8:	6d3c                	ld	a5,88(a0)
    80002aaa:	7fa8                	ld	a0,120(a5)
    80002aac:	bfcd                	j	80002a9e <argraw+0x30>
    return p->trapframe->a2;
    80002aae:	6d3c                	ld	a5,88(a0)
    80002ab0:	63c8                	ld	a0,128(a5)
    80002ab2:	b7f5                	j	80002a9e <argraw+0x30>
    return p->trapframe->a3;
    80002ab4:	6d3c                	ld	a5,88(a0)
    80002ab6:	67c8                	ld	a0,136(a5)
    80002ab8:	b7dd                	j	80002a9e <argraw+0x30>
    return p->trapframe->a4;
    80002aba:	6d3c                	ld	a5,88(a0)
    80002abc:	6bc8                	ld	a0,144(a5)
    80002abe:	b7c5                	j	80002a9e <argraw+0x30>
    return p->trapframe->a5;
    80002ac0:	6d3c                	ld	a5,88(a0)
    80002ac2:	6fc8                	ld	a0,152(a5)
    80002ac4:	bfe9                	j	80002a9e <argraw+0x30>
  panic("argraw");
    80002ac6:	00006517          	auipc	a0,0x6
    80002aca:	94a50513          	addi	a0,a0,-1718 # 80008410 <states.1761+0x148>
    80002ace:	ffffe097          	auipc	ra,0xffffe
    80002ad2:	a76080e7          	jalr	-1418(ra) # 80000544 <panic>

0000000080002ad6 <fetchaddr>:
{
    80002ad6:	1101                	addi	sp,sp,-32
    80002ad8:	ec06                	sd	ra,24(sp)
    80002ada:	e822                	sd	s0,16(sp)
    80002adc:	e426                	sd	s1,8(sp)
    80002ade:	e04a                	sd	s2,0(sp)
    80002ae0:	1000                	addi	s0,sp,32
    80002ae2:	84aa                	mv	s1,a0
    80002ae4:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002ae6:	fffff097          	auipc	ra,0xfffff
    80002aea:	ee0080e7          	jalr	-288(ra) # 800019c6 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002aee:	653c                	ld	a5,72(a0)
    80002af0:	02f4f863          	bgeu	s1,a5,80002b20 <fetchaddr+0x4a>
    80002af4:	00848713          	addi	a4,s1,8
    80002af8:	02e7e663          	bltu	a5,a4,80002b24 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002afc:	46a1                	li	a3,8
    80002afe:	8626                	mv	a2,s1
    80002b00:	85ca                	mv	a1,s2
    80002b02:	6928                	ld	a0,80(a0)
    80002b04:	fffff097          	auipc	ra,0xfffff
    80002b08:	c0c080e7          	jalr	-1012(ra) # 80001710 <copyin>
    80002b0c:	00a03533          	snez	a0,a0
    80002b10:	40a00533          	neg	a0,a0
}
    80002b14:	60e2                	ld	ra,24(sp)
    80002b16:	6442                	ld	s0,16(sp)
    80002b18:	64a2                	ld	s1,8(sp)
    80002b1a:	6902                	ld	s2,0(sp)
    80002b1c:	6105                	addi	sp,sp,32
    80002b1e:	8082                	ret
    return -1;
    80002b20:	557d                	li	a0,-1
    80002b22:	bfcd                	j	80002b14 <fetchaddr+0x3e>
    80002b24:	557d                	li	a0,-1
    80002b26:	b7fd                	j	80002b14 <fetchaddr+0x3e>

0000000080002b28 <fetchstr>:
{
    80002b28:	7179                	addi	sp,sp,-48
    80002b2a:	f406                	sd	ra,40(sp)
    80002b2c:	f022                	sd	s0,32(sp)
    80002b2e:	ec26                	sd	s1,24(sp)
    80002b30:	e84a                	sd	s2,16(sp)
    80002b32:	e44e                	sd	s3,8(sp)
    80002b34:	1800                	addi	s0,sp,48
    80002b36:	892a                	mv	s2,a0
    80002b38:	84ae                	mv	s1,a1
    80002b3a:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b3c:	fffff097          	auipc	ra,0xfffff
    80002b40:	e8a080e7          	jalr	-374(ra) # 800019c6 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002b44:	86ce                	mv	a3,s3
    80002b46:	864a                	mv	a2,s2
    80002b48:	85a6                	mv	a1,s1
    80002b4a:	6928                	ld	a0,80(a0)
    80002b4c:	fffff097          	auipc	ra,0xfffff
    80002b50:	c50080e7          	jalr	-944(ra) # 8000179c <copyinstr>
    80002b54:	00054e63          	bltz	a0,80002b70 <fetchstr+0x48>
  return strlen(buf);
    80002b58:	8526                	mv	a0,s1
    80002b5a:	ffffe097          	auipc	ra,0xffffe
    80002b5e:	310080e7          	jalr	784(ra) # 80000e6a <strlen>
}
    80002b62:	70a2                	ld	ra,40(sp)
    80002b64:	7402                	ld	s0,32(sp)
    80002b66:	64e2                	ld	s1,24(sp)
    80002b68:	6942                	ld	s2,16(sp)
    80002b6a:	69a2                	ld	s3,8(sp)
    80002b6c:	6145                	addi	sp,sp,48
    80002b6e:	8082                	ret
    return -1;
    80002b70:	557d                	li	a0,-1
    80002b72:	bfc5                	j	80002b62 <fetchstr+0x3a>

0000000080002b74 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002b74:	1101                	addi	sp,sp,-32
    80002b76:	ec06                	sd	ra,24(sp)
    80002b78:	e822                	sd	s0,16(sp)
    80002b7a:	e426                	sd	s1,8(sp)
    80002b7c:	1000                	addi	s0,sp,32
    80002b7e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b80:	00000097          	auipc	ra,0x0
    80002b84:	eee080e7          	jalr	-274(ra) # 80002a6e <argraw>
    80002b88:	c088                	sw	a0,0(s1)
}
    80002b8a:	60e2                	ld	ra,24(sp)
    80002b8c:	6442                	ld	s0,16(sp)
    80002b8e:	64a2                	ld	s1,8(sp)
    80002b90:	6105                	addi	sp,sp,32
    80002b92:	8082                	ret

0000000080002b94 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002b94:	1101                	addi	sp,sp,-32
    80002b96:	ec06                	sd	ra,24(sp)
    80002b98:	e822                	sd	s0,16(sp)
    80002b9a:	e426                	sd	s1,8(sp)
    80002b9c:	1000                	addi	s0,sp,32
    80002b9e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002ba0:	00000097          	auipc	ra,0x0
    80002ba4:	ece080e7          	jalr	-306(ra) # 80002a6e <argraw>
    80002ba8:	e088                	sd	a0,0(s1)
}
    80002baa:	60e2                	ld	ra,24(sp)
    80002bac:	6442                	ld	s0,16(sp)
    80002bae:	64a2                	ld	s1,8(sp)
    80002bb0:	6105                	addi	sp,sp,32
    80002bb2:	8082                	ret

0000000080002bb4 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002bb4:	7179                	addi	sp,sp,-48
    80002bb6:	f406                	sd	ra,40(sp)
    80002bb8:	f022                	sd	s0,32(sp)
    80002bba:	ec26                	sd	s1,24(sp)
    80002bbc:	e84a                	sd	s2,16(sp)
    80002bbe:	1800                	addi	s0,sp,48
    80002bc0:	84ae                	mv	s1,a1
    80002bc2:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002bc4:	fd840593          	addi	a1,s0,-40
    80002bc8:	00000097          	auipc	ra,0x0
    80002bcc:	fcc080e7          	jalr	-52(ra) # 80002b94 <argaddr>
  return fetchstr(addr, buf, max);
    80002bd0:	864a                	mv	a2,s2
    80002bd2:	85a6                	mv	a1,s1
    80002bd4:	fd843503          	ld	a0,-40(s0)
    80002bd8:	00000097          	auipc	ra,0x0
    80002bdc:	f50080e7          	jalr	-176(ra) # 80002b28 <fetchstr>
}
    80002be0:	70a2                	ld	ra,40(sp)
    80002be2:	7402                	ld	s0,32(sp)
    80002be4:	64e2                	ld	s1,24(sp)
    80002be6:	6942                	ld	s2,16(sp)
    80002be8:	6145                	addi	sp,sp,48
    80002bea:	8082                	ret

0000000080002bec <syscall>:
[SYS_check]   sys_check,
};

void
syscall(void)
{
    80002bec:	711d                	addi	sp,sp,-96
    80002bee:	ec86                	sd	ra,88(sp)
    80002bf0:	e8a2                	sd	s0,80(sp)
    80002bf2:	e4a6                	sd	s1,72(sp)
    80002bf4:	e0ca                	sd	s2,64(sp)
    80002bf6:	fc4e                	sd	s3,56(sp)
    80002bf8:	f852                	sd	s4,48(sp)
    80002bfa:	f456                	sd	s5,40(sp)
    80002bfc:	f05a                	sd	s6,32(sp)
    80002bfe:	ec5e                	sd	s7,24(sp)
    80002c00:	1080                	addi	s0,sp,96
  int num;
  struct proc *p = myproc();
    80002c02:	fffff097          	auipc	ra,0xfffff
    80002c06:	dc4080e7          	jalr	-572(ra) # 800019c6 <myproc>
    80002c0a:	84aa                	mv	s1,a0

  // any time we are here, we are about to make a system call.
  // we can intercept args, etc.
  num = p->trapframe->a7;
    80002c0c:	6d3c                	ld	a5,88(a0)
    80002c0e:	0a87a903          	lw	s2,168(a5)
   if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c12:	fff9071b          	addiw	a4,s2,-1
    80002c16:	47d9                	li	a5,22
    80002c18:	2ce7e263          	bltu	a5,a4,80002edc <syscall+0x2f0>
    80002c1c:	00391713          	slli	a4,s2,0x3
    80002c20:	00006797          	auipc	a5,0x6
    80002c24:	8e078793          	addi	a5,a5,-1824 # 80008500 <syscalls>
    80002c28:	97ba                	add	a5,a5,a4
    80002c2a:	0007ba83          	ld	s5,0(a5)
    80002c2e:	2a0a8763          	beqz	s5,80002edc <syscall+0x2f0>
    // steal the file away, if there is one, before we return a0.
    int fd = -1;
    struct file *f;

    // if it's any of these file related operations
    if (num == SYS_read || num == SYS_fstat || num == SYS_dup 
    80002c32:	47d5                	li	a5,21
    int fd = -1;
    80002c34:	5a7d                	li	s4,-1
    if (num == SYS_read || num == SYS_fstat || num == SYS_dup 
    80002c36:	0527e463          	bltu	a5,s2,80002c7e <syscall+0x92>
    80002c3a:	002187b7          	lui	a5,0x218
    80002c3e:	52078793          	addi	a5,a5,1312 # 218520 <_entry-0x7fde7ae0>
    80002c42:	0127d7b3          	srl	a5,a5,s2
    80002c46:	8b85                	andi	a5,a5,1
    80002c48:	cb9d                	beqz	a5,80002c7e <syscall+0x92>
  argint(n, &fd);
    80002c4a:	fac40593          	addi	a1,s0,-84
    80002c4e:	4501                	li	a0,0
    80002c50:	00000097          	auipc	ra,0x0
    80002c54:	f24080e7          	jalr	-220(ra) # 80002b74 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80002c58:	fac42703          	lw	a4,-84(s0)
    80002c5c:	47bd                	li	a5,15
    80002c5e:	16e7e663          	bltu	a5,a4,80002dca <syscall+0x1de>
    80002c62:	fffff097          	auipc	ra,0xfffff
    80002c66:	d64080e7          	jalr	-668(ra) # 800019c6 <myproc>
    80002c6a:	fac42a03          	lw	s4,-84(s0)
    80002c6e:	01aa0793          	addi	a5,s4,26
    80002c72:	078e                	slli	a5,a5,0x3
    80002c74:	953e                	add	a0,a0,a5
    80002c76:	00053983          	ld	s3,0(a0)
    80002c7a:	14098663          	beqz	s3,80002dc6 <syscall+0x1da>
      // we are trying to do SOMETHING with this file.
      argfd(0, &fd, &f);
    }
    
    // let the system call go through.
    p->trapframe->a0 = syscalls[num]();
    80002c7e:	0584bb03          	ld	s6,88(s1)
    80002c82:	9a82                	jalr	s5
    80002c84:	06ab3823          	sd	a0,112(s6)
    if (num == 22) {
    80002c88:	47d9                	li	a5,22
    80002c8a:	14f90263          	beq	s2,a5,80002dce <syscall+0x1e2>
        audit_num = audit_num >> 1;
      }
    }

    // it should always be apparent when audit is called.
    if (whitelisted[num - 1] || num == SYS_audit) {
    80002c8e:	fff9071b          	addiw	a4,s2,-1
    80002c92:	00006797          	auipc	a5,0x6
    80002c96:	d7678793          	addi	a5,a5,-650 # 80008a08 <whitelisted>
    80002c9a:	97ba                	add	a5,a5,a4
    80002c9c:	0007c783          	lbu	a5,0(a5)
    80002ca0:	24078d63          	beqz	a5,80002efa <syscall+0x30e>
      // these things will be consistent across processes, no matter if it used a file
    if(ticks - prev_tickss > 100){
    80002ca4:	00006797          	auipc	a5,0x6
    80002ca8:	e947a783          	lw	a5,-364(a5) # 80008b38 <ticks>
    80002cac:	00006717          	auipc	a4,0x6
    80002cb0:	e9472703          	lw	a4,-364(a4) # 80008b40 <prev_tickss>
    80002cb4:	9f99                	subw	a5,a5,a4
    80002cb6:	06400713          	li	a4,100
    80002cba:	14f76763          	bltu	a4,a5,80002e08 <syscall+0x21c>
       buff[0] = '\0';
    }

      struct audit_data cur;
      cur.process_pid = p->pid;
      cur.process_name = p->name;
    80002cbe:	15848493          	addi	s1,s1,344
      cur.time = ticks;
      cur.process_name = name_from_num[num];
      if (fd != -1) {
    80002cc2:	57fd                	li	a5,-1
    80002cc4:	16fa0b63          	beq	s4,a5,80002e3a <syscall+0x24e>
        cur.fd_used = 1;
        cur.fd_read = f->readable;
        cur.fd_write = f->writable;

//here
	strncpy(buff + offset,p->name, strlen(p->name));
    80002cc8:	00006a97          	auipc	s5,0x6
    80002ccc:	e74a8a93          	addi	s5,s5,-396 # 80008b3c <offset>
    80002cd0:	000aab03          	lw	s6,0(s5)
    80002cd4:	00014a17          	auipc	s4,0x14
    80002cd8:	144a0a13          	addi	s4,s4,324 # 80016e18 <buff>
    80002cdc:	9b52                	add	s6,s6,s4
    80002cde:	8526                	mv	a0,s1
    80002ce0:	ffffe097          	auipc	ra,0xffffe
    80002ce4:	18a080e7          	jalr	394(ra) # 80000e6a <strlen>
    80002ce8:	862a                	mv	a2,a0
    80002cea:	85a6                	mv	a1,s1
    80002cec:	855a                	mv	a0,s6
    80002cee:	ffffe097          	auipc	ra,0xffffe
    80002cf2:	10c080e7          	jalr	268(ra) # 80000dfa <strncpy>
	offset += strlen(p->name);
    80002cf6:	8526                	mv	a0,s1
    80002cf8:	ffffe097          	auipc	ra,0xffffe
    80002cfc:	172080e7          	jalr	370(ra) # 80000e6a <strlen>
    80002d00:	000aa783          	lw	a5,0(s5)
    80002d04:	9fa9                	addw	a5,a5,a0
    80002d06:	0007871b          	sext.w	a4,a5
	buff[offset] = '\t';
    80002d0a:	9752                	add	a4,a4,s4
    80002d0c:	44a5                	li	s1,9
    80002d0e:	00970023          	sb	s1,0(a4)
	offset += 1;
    80002d12:	2785                	addiw	a5,a5,1
    80002d14:	00078b9b          	sext.w	s7,a5
    80002d18:	00faa023          	sw	a5,0(s5)
	strncpy(buff + offset,name_from_num[num], strlen(name_from_num[num]));
    80002d1c:	090e                	slli	s2,s2,0x3
    80002d1e:	00006797          	auipc	a5,0x6
    80002d22:	cea78793          	addi	a5,a5,-790 # 80008a08 <whitelisted>
    80002d26:	993e                	add	s2,s2,a5
    80002d28:	01893b03          	ld	s6,24(s2)
    80002d2c:	855a                	mv	a0,s6
    80002d2e:	ffffe097          	auipc	ra,0xffffe
    80002d32:	13c080e7          	jalr	316(ra) # 80000e6a <strlen>
    80002d36:	862a                	mv	a2,a0
    80002d38:	85da                	mv	a1,s6
    80002d3a:	017a0533          	add	a0,s4,s7
    80002d3e:	ffffe097          	auipc	ra,0xffffe
    80002d42:	0bc080e7          	jalr	188(ra) # 80000dfa <strncpy>
	offset += strlen(name_from_num[num]);
    80002d46:	01893503          	ld	a0,24(s2)
    80002d4a:	ffffe097          	auipc	ra,0xffffe
    80002d4e:	120080e7          	jalr	288(ra) # 80000e6a <strlen>
    80002d52:	000aa783          	lw	a5,0(s5)
    80002d56:	9d3d                	addw	a0,a0,a5
    80002d58:	0005079b          	sext.w	a5,a0
	buff[offset] = '\t';
    80002d5c:	9a3e                	add	s4,s4,a5
    80002d5e:	009a0023          	sb	s1,0(s4)
	offset += 1;
    80002d62:	0015071b          	addiw	a4,a0,1
//end
/*
	strncpy("FD With Permissions r: ", buff + offset, 23);
*/
	*(buff + offset) = f->readable ? 49: 48;
    80002d66:	0089c783          	lbu	a5,8(s3)
    80002d6a:	00f037b3          	snez	a5,a5
    80002d6e:	03078793          	addi	a5,a5,48
    80002d72:	00014697          	auipc	a3,0x14
    80002d76:	0a668693          	addi	a3,a3,166 # 80016e18 <buff>
    80002d7a:	9736                	add	a4,a4,a3
    80002d7c:	00f70023          	sb	a5,0(a4)
	offset+=1;
//	strncpy(" w: ", buff + offset, 4);
        *(buff + offset) = '\t';
    80002d80:	0025071b          	addiw	a4,a0,2
    80002d84:	96ba                	add	a3,a3,a4
    80002d86:	47a5                	li	a5,9
    80002d88:	00f68023          	sb	a5,0(a3)
	*(buff + offset + 1) = f->writable ? 49: 48;
    80002d8c:	0099c783          	lbu	a5,9(s3)
    80002d90:	00f037b3          	snez	a5,a5
    80002d94:	03078793          	addi	a5,a5,48
    80002d98:	00014697          	auipc	a3,0x14
    80002d9c:	08168693          	addi	a3,a3,129 # 80016e19 <buff+0x1>
    80002da0:	9736                	add	a4,a4,a3
    80002da2:	00f70023          	sb	a5,0(a4)
	offset +=2;
//start
	buff[offset] = '\n';
    80002da6:	0045071b          	addiw	a4,a0,4
    80002daa:	00014797          	auipc	a5,0x14
    80002dae:	06e78793          	addi	a5,a5,110 # 80016e18 <buff>
    80002db2:	97ba                	add	a5,a5,a4
    80002db4:	4729                	li	a4,10
    80002db6:	00e78023          	sb	a4,0(a5)
        offset +=1;
    80002dba:	2515                	addiw	a0,a0,5
    80002dbc:	00006797          	auipc	a5,0x6
    80002dc0:	d8a7a023          	sw	a0,-640(a5) # 80008b3c <offset>
    80002dc4:	aa1d                	j	80002efa <syscall+0x30e>
    int fd = -1;
    80002dc6:	5a7d                	li	s4,-1
    80002dc8:	bd5d                	j	80002c7e <syscall+0x92>
    80002dca:	5a7d                	li	s4,-1
    80002dcc:	bd4d                	j	80002c7e <syscall+0x92>
      uint audit_num = (uint) p->trapframe->a0;
    80002dce:	6cbc                	ld	a5,88(s1)
    80002dd0:	5bb8                	lw	a4,112(a5)
      for (int i = 0; i < NUM_SYS_CALLS; i++) {
    80002dd2:	00006797          	auipc	a5,0x6
    80002dd6:	c3678793          	addi	a5,a5,-970 # 80008a08 <whitelisted>
    80002dda:	00006617          	auipc	a2,0x6
    80002dde:	c4360613          	addi	a2,a2,-957 # 80008a1d <whitelisted+0x15>
    80002de2:	00179513          	slli	a0,a5,0x1
          whitelisted[NUM_SYS_CALLS - i] = 1;
    80002de6:	4585                	li	a1,1
    80002de8:	a031                	j	80002df4 <syscall+0x208>
        audit_num = audit_num >> 1;
    80002dea:	0017571b          	srliw	a4,a4,0x1
      for (int i = 0; i < NUM_SYS_CALLS; i++) {
    80002dee:	0785                	addi	a5,a5,1
    80002df0:	eaf60ae3          	beq	a2,a5,80002ca4 <syscall+0xb8>
        whitelisted[i] = 0; // reset the array position first.
    80002df4:	00078023          	sb	zero,0(a5)
        if (audit_num & 0b00000000000000000000000000000001) { // bit was toggled, whitelist
    80002df8:	00177693          	andi	a3,a4,1
    80002dfc:	d6fd                	beqz	a3,80002dea <syscall+0x1fe>
          whitelisted[NUM_SYS_CALLS - i] = 1;
    80002dfe:	40f506b3          	sub	a3,a0,a5
    80002e02:	00b68aa3          	sb	a1,21(a3)
    80002e06:	b7d5                	j	80002dea <syscall+0x1fe>
       write_to_logs((void *)buff);
    80002e08:	00014517          	auipc	a0,0x14
    80002e0c:	01050513          	addi	a0,a0,16 # 80016e18 <buff>
    80002e10:	00004097          	auipc	ra,0x4
    80002e14:	870080e7          	jalr	-1936(ra) # 80006680 <write_to_logs>
       prev_tickss = ticks;
    80002e18:	00006797          	auipc	a5,0x6
    80002e1c:	d207a783          	lw	a5,-736(a5) # 80008b38 <ticks>
    80002e20:	00006717          	auipc	a4,0x6
    80002e24:	d2f72023          	sw	a5,-736(a4) # 80008b40 <prev_tickss>
       offset = 0;
    80002e28:	00006797          	auipc	a5,0x6
    80002e2c:	d007aa23          	sw	zero,-748(a5) # 80008b3c <offset>
       buff[0] = '\0';
    80002e30:	00014797          	auipc	a5,0x14
    80002e34:	fe078423          	sb	zero,-24(a5) # 80016e18 <buff>
    80002e38:	b559                	j	80002cbe <syscall+0xd2>
      } else {
        // just say we didn't use one
        cur.fd_used = 0;
	

	strncpy(buff + offset,p->name, strlen(p->name));
    80002e3a:	00006a17          	auipc	s4,0x6
    80002e3e:	d02a0a13          	addi	s4,s4,-766 # 80008b3c <offset>
    80002e42:	000a2a83          	lw	s5,0(s4)
    80002e46:	00014997          	auipc	s3,0x14
    80002e4a:	fd298993          	addi	s3,s3,-46 # 80016e18 <buff>
    80002e4e:	9ace                	add	s5,s5,s3
    80002e50:	8526                	mv	a0,s1
    80002e52:	ffffe097          	auipc	ra,0xffffe
    80002e56:	018080e7          	jalr	24(ra) # 80000e6a <strlen>
    80002e5a:	862a                	mv	a2,a0
    80002e5c:	85a6                	mv	a1,s1
    80002e5e:	8556                	mv	a0,s5
    80002e60:	ffffe097          	auipc	ra,0xffffe
    80002e64:	f9a080e7          	jalr	-102(ra) # 80000dfa <strncpy>
	offset += strlen(p->name);
    80002e68:	8526                	mv	a0,s1
    80002e6a:	ffffe097          	auipc	ra,0xffffe
    80002e6e:	000080e7          	jalr	ra # 80000e6a <strlen>
    80002e72:	000a2783          	lw	a5,0(s4)
    80002e76:	9fa9                	addw	a5,a5,a0
    80002e78:	0007871b          	sext.w	a4,a5
	buff[offset] = '\t';
    80002e7c:	974e                	add	a4,a4,s3
    80002e7e:	46a5                	li	a3,9
    80002e80:	00d70023          	sb	a3,0(a4)
	offset += 1;
    80002e84:	2785                	addiw	a5,a5,1
    80002e86:	00078a9b          	sext.w	s5,a5
    80002e8a:	00fa2023          	sw	a5,0(s4)
	strncpy(buff + offset,name_from_num[num], strlen(name_from_num[num]));
    80002e8e:	090e                	slli	s2,s2,0x3
    80002e90:	00006797          	auipc	a5,0x6
    80002e94:	b7878793          	addi	a5,a5,-1160 # 80008a08 <whitelisted>
    80002e98:	993e                	add	s2,s2,a5
    80002e9a:	01893903          	ld	s2,24(s2)
    80002e9e:	854a                	mv	a0,s2
    80002ea0:	ffffe097          	auipc	ra,0xffffe
    80002ea4:	fca080e7          	jalr	-54(ra) # 80000e6a <strlen>
    80002ea8:	862a                	mv	a2,a0
    80002eaa:	85ca                	mv	a1,s2
    80002eac:	01598533          	add	a0,s3,s5
    80002eb0:	ffffe097          	auipc	ra,0xffffe
    80002eb4:	f4a080e7          	jalr	-182(ra) # 80000dfa <strncpy>
	offset += strlen(p->name);
    80002eb8:	8526                	mv	a0,s1
    80002eba:	ffffe097          	auipc	ra,0xffffe
    80002ebe:	fb0080e7          	jalr	-80(ra) # 80000e6a <strlen>
    80002ec2:	000a2783          	lw	a5,0(s4)
    80002ec6:	9d3d                	addw	a0,a0,a5
    80002ec8:	0005079b          	sext.w	a5,a0

	buff[offset] = '\n';
    80002ecc:	99be                	add	s3,s3,a5
    80002ece:	47a9                	li	a5,10
    80002ed0:	00f98023          	sb	a5,0(s3)
        offset +=1;
    80002ed4:	2505                	addiw	a0,a0,1
    80002ed6:	00aa2023          	sw	a0,0(s4)
    80002eda:	a005                	j	80002efa <syscall+0x30e>
      // here just so we don't throw unused variable errors
      int bruh = cur.process_pid;
      bruh++;
    }
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002edc:	86ca                	mv	a3,s2
    80002ede:	15848613          	addi	a2,s1,344
    80002ee2:	588c                	lw	a1,48(s1)
    80002ee4:	00005517          	auipc	a0,0x5
    80002ee8:	53450513          	addi	a0,a0,1332 # 80008418 <states.1761+0x150>
    80002eec:	ffffd097          	auipc	ra,0xffffd
    80002ef0:	6a2080e7          	jalr	1698(ra) # 8000058e <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002ef4:	6cbc                	ld	a5,88(s1)
    80002ef6:	577d                	li	a4,-1
    80002ef8:	fbb8                	sd	a4,112(a5)
  }
}
    80002efa:	60e6                	ld	ra,88(sp)
    80002efc:	6446                	ld	s0,80(sp)
    80002efe:	64a6                	ld	s1,72(sp)
    80002f00:	6906                	ld	s2,64(sp)
    80002f02:	79e2                	ld	s3,56(sp)
    80002f04:	7a42                	ld	s4,48(sp)
    80002f06:	7aa2                	ld	s5,40(sp)
    80002f08:	7b02                	ld	s6,32(sp)
    80002f0a:	6be2                	ld	s7,24(sp)
    80002f0c:	6125                	addi	sp,sp,96
    80002f0e:	8082                	ret

0000000080002f10 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002f10:	1101                	addi	sp,sp,-32
    80002f12:	ec06                	sd	ra,24(sp)
    80002f14:	e822                	sd	s0,16(sp)
    80002f16:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002f18:	fec40593          	addi	a1,s0,-20
    80002f1c:	4501                	li	a0,0
    80002f1e:	00000097          	auipc	ra,0x0
    80002f22:	c56080e7          	jalr	-938(ra) # 80002b74 <argint>
  exit(n);
    80002f26:	fec42503          	lw	a0,-20(s0)
    80002f2a:	fffff097          	auipc	ra,0xfffff
    80002f2e:	312080e7          	jalr	786(ra) # 8000223c <exit>
  return 0;  // not reached
}
    80002f32:	4501                	li	a0,0
    80002f34:	60e2                	ld	ra,24(sp)
    80002f36:	6442                	ld	s0,16(sp)
    80002f38:	6105                	addi	sp,sp,32
    80002f3a:	8082                	ret

0000000080002f3c <sys_getpid>:

uint64
sys_getpid(void)
{
    80002f3c:	1141                	addi	sp,sp,-16
    80002f3e:	e406                	sd	ra,8(sp)
    80002f40:	e022                	sd	s0,0(sp)
    80002f42:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002f44:	fffff097          	auipc	ra,0xfffff
    80002f48:	a82080e7          	jalr	-1406(ra) # 800019c6 <myproc>
}
    80002f4c:	5908                	lw	a0,48(a0)
    80002f4e:	60a2                	ld	ra,8(sp)
    80002f50:	6402                	ld	s0,0(sp)
    80002f52:	0141                	addi	sp,sp,16
    80002f54:	8082                	ret

0000000080002f56 <sys_fork>:

uint64
sys_fork(void)
{
    80002f56:	1141                	addi	sp,sp,-16
    80002f58:	e406                	sd	ra,8(sp)
    80002f5a:	e022                	sd	s0,0(sp)
    80002f5c:	0800                	addi	s0,sp,16
  return fork();
    80002f5e:	fffff097          	auipc	ra,0xfffff
    80002f62:	e1e080e7          	jalr	-482(ra) # 80001d7c <fork>
}
    80002f66:	60a2                	ld	ra,8(sp)
    80002f68:	6402                	ld	s0,0(sp)
    80002f6a:	0141                	addi	sp,sp,16
    80002f6c:	8082                	ret

0000000080002f6e <sys_wait>:

uint64
sys_wait(void)
{
    80002f6e:	1101                	addi	sp,sp,-32
    80002f70:	ec06                	sd	ra,24(sp)
    80002f72:	e822                	sd	s0,16(sp)
    80002f74:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002f76:	fe840593          	addi	a1,s0,-24
    80002f7a:	4501                	li	a0,0
    80002f7c:	00000097          	auipc	ra,0x0
    80002f80:	c18080e7          	jalr	-1000(ra) # 80002b94 <argaddr>
  return wait(p);
    80002f84:	fe843503          	ld	a0,-24(s0)
    80002f88:	fffff097          	auipc	ra,0xfffff
    80002f8c:	45a080e7          	jalr	1114(ra) # 800023e2 <wait>
}
    80002f90:	60e2                	ld	ra,24(sp)
    80002f92:	6442                	ld	s0,16(sp)
    80002f94:	6105                	addi	sp,sp,32
    80002f96:	8082                	ret

0000000080002f98 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f98:	7179                	addi	sp,sp,-48
    80002f9a:	f406                	sd	ra,40(sp)
    80002f9c:	f022                	sd	s0,32(sp)
    80002f9e:	ec26                	sd	s1,24(sp)
    80002fa0:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002fa2:	fdc40593          	addi	a1,s0,-36
    80002fa6:	4501                	li	a0,0
    80002fa8:	00000097          	auipc	ra,0x0
    80002fac:	bcc080e7          	jalr	-1076(ra) # 80002b74 <argint>
  addr = myproc()->sz;
    80002fb0:	fffff097          	auipc	ra,0xfffff
    80002fb4:	a16080e7          	jalr	-1514(ra) # 800019c6 <myproc>
    80002fb8:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002fba:	fdc42503          	lw	a0,-36(s0)
    80002fbe:	fffff097          	auipc	ra,0xfffff
    80002fc2:	d62080e7          	jalr	-670(ra) # 80001d20 <growproc>
    80002fc6:	00054863          	bltz	a0,80002fd6 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002fca:	8526                	mv	a0,s1
    80002fcc:	70a2                	ld	ra,40(sp)
    80002fce:	7402                	ld	s0,32(sp)
    80002fd0:	64e2                	ld	s1,24(sp)
    80002fd2:	6145                	addi	sp,sp,48
    80002fd4:	8082                	ret
    return -1;
    80002fd6:	54fd                	li	s1,-1
    80002fd8:	bfcd                	j	80002fca <sys_sbrk+0x32>

0000000080002fda <sys_sleep>:

uint64
sys_sleep(void)
{
    80002fda:	7139                	addi	sp,sp,-64
    80002fdc:	fc06                	sd	ra,56(sp)
    80002fde:	f822                	sd	s0,48(sp)
    80002fe0:	f426                	sd	s1,40(sp)
    80002fe2:	f04a                	sd	s2,32(sp)
    80002fe4:	ec4e                	sd	s3,24(sp)
    80002fe6:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002fe8:	fcc40593          	addi	a1,s0,-52
    80002fec:	4501                	li	a0,0
    80002fee:	00000097          	auipc	ra,0x0
    80002ff2:	b86080e7          	jalr	-1146(ra) # 80002b74 <argint>
  acquire(&tickslock);
    80002ff6:	00014517          	auipc	a0,0x14
    80002ffa:	e0a50513          	addi	a0,a0,-502 # 80016e00 <tickslock>
    80002ffe:	ffffe097          	auipc	ra,0xffffe
    80003002:	bec080e7          	jalr	-1044(ra) # 80000bea <acquire>
  ticks0 = ticks;
    80003006:	00006917          	auipc	s2,0x6
    8000300a:	b3292903          	lw	s2,-1230(s2) # 80008b38 <ticks>
  while(ticks - ticks0 < n){
    8000300e:	fcc42783          	lw	a5,-52(s0)
    80003012:	cf9d                	beqz	a5,80003050 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003014:	00014997          	auipc	s3,0x14
    80003018:	dec98993          	addi	s3,s3,-532 # 80016e00 <tickslock>
    8000301c:	00006497          	auipc	s1,0x6
    80003020:	b1c48493          	addi	s1,s1,-1252 # 80008b38 <ticks>
    if(killed(myproc())){
    80003024:	fffff097          	auipc	ra,0xfffff
    80003028:	9a2080e7          	jalr	-1630(ra) # 800019c6 <myproc>
    8000302c:	fffff097          	auipc	ra,0xfffff
    80003030:	384080e7          	jalr	900(ra) # 800023b0 <killed>
    80003034:	ed15                	bnez	a0,80003070 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80003036:	85ce                	mv	a1,s3
    80003038:	8526                	mv	a0,s1
    8000303a:	fffff097          	auipc	ra,0xfffff
    8000303e:	0ce080e7          	jalr	206(ra) # 80002108 <sleep>
  while(ticks - ticks0 < n){
    80003042:	409c                	lw	a5,0(s1)
    80003044:	412787bb          	subw	a5,a5,s2
    80003048:	fcc42703          	lw	a4,-52(s0)
    8000304c:	fce7ece3          	bltu	a5,a4,80003024 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80003050:	00014517          	auipc	a0,0x14
    80003054:	db050513          	addi	a0,a0,-592 # 80016e00 <tickslock>
    80003058:	ffffe097          	auipc	ra,0xffffe
    8000305c:	c46080e7          	jalr	-954(ra) # 80000c9e <release>
  return 0;
    80003060:	4501                	li	a0,0
}
    80003062:	70e2                	ld	ra,56(sp)
    80003064:	7442                	ld	s0,48(sp)
    80003066:	74a2                	ld	s1,40(sp)
    80003068:	7902                	ld	s2,32(sp)
    8000306a:	69e2                	ld	s3,24(sp)
    8000306c:	6121                	addi	sp,sp,64
    8000306e:	8082                	ret
      release(&tickslock);
    80003070:	00014517          	auipc	a0,0x14
    80003074:	d9050513          	addi	a0,a0,-624 # 80016e00 <tickslock>
    80003078:	ffffe097          	auipc	ra,0xffffe
    8000307c:	c26080e7          	jalr	-986(ra) # 80000c9e <release>
      return -1;
    80003080:	557d                	li	a0,-1
    80003082:	b7c5                	j	80003062 <sys_sleep+0x88>

0000000080003084 <sys_kill>:

uint64
sys_kill(void)
{
    80003084:	1101                	addi	sp,sp,-32
    80003086:	ec06                	sd	ra,24(sp)
    80003088:	e822                	sd	s0,16(sp)
    8000308a:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    8000308c:	fec40593          	addi	a1,s0,-20
    80003090:	4501                	li	a0,0
    80003092:	00000097          	auipc	ra,0x0
    80003096:	ae2080e7          	jalr	-1310(ra) # 80002b74 <argint>
  return kill(pid);
    8000309a:	fec42503          	lw	a0,-20(s0)
    8000309e:	fffff097          	auipc	ra,0xfffff
    800030a2:	274080e7          	jalr	628(ra) # 80002312 <kill>
}
    800030a6:	60e2                	ld	ra,24(sp)
    800030a8:	6442                	ld	s0,16(sp)
    800030aa:	6105                	addi	sp,sp,32
    800030ac:	8082                	ret

00000000800030ae <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800030ae:	1101                	addi	sp,sp,-32
    800030b0:	ec06                	sd	ra,24(sp)
    800030b2:	e822                	sd	s0,16(sp)
    800030b4:	e426                	sd	s1,8(sp)
    800030b6:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800030b8:	00014517          	auipc	a0,0x14
    800030bc:	d4850513          	addi	a0,a0,-696 # 80016e00 <tickslock>
    800030c0:	ffffe097          	auipc	ra,0xffffe
    800030c4:	b2a080e7          	jalr	-1238(ra) # 80000bea <acquire>
  xticks = ticks;
    800030c8:	00006497          	auipc	s1,0x6
    800030cc:	a704a483          	lw	s1,-1424(s1) # 80008b38 <ticks>
  release(&tickslock);
    800030d0:	00014517          	auipc	a0,0x14
    800030d4:	d3050513          	addi	a0,a0,-720 # 80016e00 <tickslock>
    800030d8:	ffffe097          	auipc	ra,0xffffe
    800030dc:	bc6080e7          	jalr	-1082(ra) # 80000c9e <release>
  return xticks;
}
    800030e0:	02049513          	slli	a0,s1,0x20
    800030e4:	9101                	srli	a0,a0,0x20
    800030e6:	60e2                	ld	ra,24(sp)
    800030e8:	6442                	ld	s0,16(sp)
    800030ea:	64a2                	ld	s1,8(sp)
    800030ec:	6105                	addi	sp,sp,32
    800030ee:	8082                	ret

00000000800030f0 <sys_audit>:

uint64
sys_audit(void)
{
    800030f0:	1101                	addi	sp,sp,-32
    800030f2:	ec06                	sd	ra,24(sp)
    800030f4:	e822                	sd	s0,16(sp)
    800030f6:	1000                	addi	s0,sp,32
  // fetch the integer
  int n;
  argint(0, &n); 
    800030f8:	fec40593          	addi	a1,s0,-20
    800030fc:	4501                	li	a0,0
    800030fe:	00000097          	auipc	ra,0x0
    80003102:	a76080e7          	jalr	-1418(ra) # 80002b74 <argint>
  return audit(n);
    80003106:	fec42503          	lw	a0,-20(s0)
    8000310a:	fffff097          	auipc	ra,0xfffff
    8000310e:	dae080e7          	jalr	-594(ra) # 80001eb8 <audit>
}
    80003112:	60e2                	ld	ra,24(sp)
    80003114:	6442                	ld	s0,16(sp)
    80003116:	6105                	addi	sp,sp,32
    80003118:	8082                	ret

000000008000311a <sys_check>:

uint64
sys_check(void)
{
    8000311a:	1101                	addi	sp,sp,-32
    8000311c:	ec06                	sd	ra,24(sp)
    8000311e:	e822                	sd	s0,16(sp)
    80003120:	1000                	addi	s0,sp,32
    uint64 list;
    argaddr(0, &list);
    80003122:	fe840593          	addi	a1,s0,-24
    80003126:	4501                	li	a0,0
    80003128:	00000097          	auipc	ra,0x0
    8000312c:	a6c080e7          	jalr	-1428(ra) # 80002b94 <argaddr>
    return check((void *) list);
    80003130:	fe843503          	ld	a0,-24(s0)
    80003134:	fffff097          	auipc	ra,0xfffff
    80003138:	d94080e7          	jalr	-620(ra) # 80001ec8 <check>
}
    8000313c:	60e2                	ld	ra,24(sp)
    8000313e:	6442                	ld	s0,16(sp)
    80003140:	6105                	addi	sp,sp,32
    80003142:	8082                	ret

0000000080003144 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003144:	7179                	addi	sp,sp,-48
    80003146:	f406                	sd	ra,40(sp)
    80003148:	f022                	sd	s0,32(sp)
    8000314a:	ec26                	sd	s1,24(sp)
    8000314c:	e84a                	sd	s2,16(sp)
    8000314e:	e44e                	sd	s3,8(sp)
    80003150:	e052                	sd	s4,0(sp)
    80003152:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003154:	00005597          	auipc	a1,0x5
    80003158:	46c58593          	addi	a1,a1,1132 # 800085c0 <syscalls+0xc0>
    8000315c:	00020517          	auipc	a0,0x20
    80003160:	4bc50513          	addi	a0,a0,1212 # 80023618 <bcache>
    80003164:	ffffe097          	auipc	ra,0xffffe
    80003168:	9f6080e7          	jalr	-1546(ra) # 80000b5a <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000316c:	00028797          	auipc	a5,0x28
    80003170:	4ac78793          	addi	a5,a5,1196 # 8002b618 <bcache+0x8000>
    80003174:	00028717          	auipc	a4,0x28
    80003178:	70c70713          	addi	a4,a4,1804 # 8002b880 <bcache+0x8268>
    8000317c:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003180:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003184:	00020497          	auipc	s1,0x20
    80003188:	4ac48493          	addi	s1,s1,1196 # 80023630 <bcache+0x18>
    b->next = bcache.head.next;
    8000318c:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000318e:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003190:	00005a17          	auipc	s4,0x5
    80003194:	438a0a13          	addi	s4,s4,1080 # 800085c8 <syscalls+0xc8>
    b->next = bcache.head.next;
    80003198:	2b893783          	ld	a5,696(s2)
    8000319c:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000319e:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800031a2:	85d2                	mv	a1,s4
    800031a4:	01048513          	addi	a0,s1,16
    800031a8:	00001097          	auipc	ra,0x1
    800031ac:	4c4080e7          	jalr	1220(ra) # 8000466c <initsleeplock>
    bcache.head.next->prev = b;
    800031b0:	2b893783          	ld	a5,696(s2)
    800031b4:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800031b6:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800031ba:	45848493          	addi	s1,s1,1112
    800031be:	fd349de3          	bne	s1,s3,80003198 <binit+0x54>
  }
}
    800031c2:	70a2                	ld	ra,40(sp)
    800031c4:	7402                	ld	s0,32(sp)
    800031c6:	64e2                	ld	s1,24(sp)
    800031c8:	6942                	ld	s2,16(sp)
    800031ca:	69a2                	ld	s3,8(sp)
    800031cc:	6a02                	ld	s4,0(sp)
    800031ce:	6145                	addi	sp,sp,48
    800031d0:	8082                	ret

00000000800031d2 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800031d2:	7179                	addi	sp,sp,-48
    800031d4:	f406                	sd	ra,40(sp)
    800031d6:	f022                	sd	s0,32(sp)
    800031d8:	ec26                	sd	s1,24(sp)
    800031da:	e84a                	sd	s2,16(sp)
    800031dc:	e44e                	sd	s3,8(sp)
    800031de:	1800                	addi	s0,sp,48
    800031e0:	89aa                	mv	s3,a0
    800031e2:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800031e4:	00020517          	auipc	a0,0x20
    800031e8:	43450513          	addi	a0,a0,1076 # 80023618 <bcache>
    800031ec:	ffffe097          	auipc	ra,0xffffe
    800031f0:	9fe080e7          	jalr	-1538(ra) # 80000bea <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800031f4:	00028497          	auipc	s1,0x28
    800031f8:	6dc4b483          	ld	s1,1756(s1) # 8002b8d0 <bcache+0x82b8>
    800031fc:	00028797          	auipc	a5,0x28
    80003200:	68478793          	addi	a5,a5,1668 # 8002b880 <bcache+0x8268>
    80003204:	02f48f63          	beq	s1,a5,80003242 <bread+0x70>
    80003208:	873e                	mv	a4,a5
    8000320a:	a021                	j	80003212 <bread+0x40>
    8000320c:	68a4                	ld	s1,80(s1)
    8000320e:	02e48a63          	beq	s1,a4,80003242 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003212:	449c                	lw	a5,8(s1)
    80003214:	ff379ce3          	bne	a5,s3,8000320c <bread+0x3a>
    80003218:	44dc                	lw	a5,12(s1)
    8000321a:	ff2799e3          	bne	a5,s2,8000320c <bread+0x3a>
      b->refcnt++;
    8000321e:	40bc                	lw	a5,64(s1)
    80003220:	2785                	addiw	a5,a5,1
    80003222:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003224:	00020517          	auipc	a0,0x20
    80003228:	3f450513          	addi	a0,a0,1012 # 80023618 <bcache>
    8000322c:	ffffe097          	auipc	ra,0xffffe
    80003230:	a72080e7          	jalr	-1422(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    80003234:	01048513          	addi	a0,s1,16
    80003238:	00001097          	auipc	ra,0x1
    8000323c:	46e080e7          	jalr	1134(ra) # 800046a6 <acquiresleep>
      return b;
    80003240:	a8b9                	j	8000329e <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003242:	00028497          	auipc	s1,0x28
    80003246:	6864b483          	ld	s1,1670(s1) # 8002b8c8 <bcache+0x82b0>
    8000324a:	00028797          	auipc	a5,0x28
    8000324e:	63678793          	addi	a5,a5,1590 # 8002b880 <bcache+0x8268>
    80003252:	00f48863          	beq	s1,a5,80003262 <bread+0x90>
    80003256:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003258:	40bc                	lw	a5,64(s1)
    8000325a:	cf81                	beqz	a5,80003272 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000325c:	64a4                	ld	s1,72(s1)
    8000325e:	fee49de3          	bne	s1,a4,80003258 <bread+0x86>
  panic("bget: no buffers");
    80003262:	00005517          	auipc	a0,0x5
    80003266:	36e50513          	addi	a0,a0,878 # 800085d0 <syscalls+0xd0>
    8000326a:	ffffd097          	auipc	ra,0xffffd
    8000326e:	2da080e7          	jalr	730(ra) # 80000544 <panic>
      b->dev = dev;
    80003272:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003276:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000327a:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000327e:	4785                	li	a5,1
    80003280:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003282:	00020517          	auipc	a0,0x20
    80003286:	39650513          	addi	a0,a0,918 # 80023618 <bcache>
    8000328a:	ffffe097          	auipc	ra,0xffffe
    8000328e:	a14080e7          	jalr	-1516(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    80003292:	01048513          	addi	a0,s1,16
    80003296:	00001097          	auipc	ra,0x1
    8000329a:	410080e7          	jalr	1040(ra) # 800046a6 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000329e:	409c                	lw	a5,0(s1)
    800032a0:	cb89                	beqz	a5,800032b2 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800032a2:	8526                	mv	a0,s1
    800032a4:	70a2                	ld	ra,40(sp)
    800032a6:	7402                	ld	s0,32(sp)
    800032a8:	64e2                	ld	s1,24(sp)
    800032aa:	6942                	ld	s2,16(sp)
    800032ac:	69a2                	ld	s3,8(sp)
    800032ae:	6145                	addi	sp,sp,48
    800032b0:	8082                	ret
    virtio_disk_rw(b, 0);
    800032b2:	4581                	li	a1,0
    800032b4:	8526                	mv	a0,s1
    800032b6:	00003097          	auipc	ra,0x3
    800032ba:	fd2080e7          	jalr	-46(ra) # 80006288 <virtio_disk_rw>
    b->valid = 1;
    800032be:	4785                	li	a5,1
    800032c0:	c09c                	sw	a5,0(s1)
  return b;
    800032c2:	b7c5                	j	800032a2 <bread+0xd0>

00000000800032c4 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800032c4:	1101                	addi	sp,sp,-32
    800032c6:	ec06                	sd	ra,24(sp)
    800032c8:	e822                	sd	s0,16(sp)
    800032ca:	e426                	sd	s1,8(sp)
    800032cc:	1000                	addi	s0,sp,32
    800032ce:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800032d0:	0541                	addi	a0,a0,16
    800032d2:	00001097          	auipc	ra,0x1
    800032d6:	46e080e7          	jalr	1134(ra) # 80004740 <holdingsleep>
    800032da:	cd01                	beqz	a0,800032f2 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800032dc:	4585                	li	a1,1
    800032de:	8526                	mv	a0,s1
    800032e0:	00003097          	auipc	ra,0x3
    800032e4:	fa8080e7          	jalr	-88(ra) # 80006288 <virtio_disk_rw>
}
    800032e8:	60e2                	ld	ra,24(sp)
    800032ea:	6442                	ld	s0,16(sp)
    800032ec:	64a2                	ld	s1,8(sp)
    800032ee:	6105                	addi	sp,sp,32
    800032f0:	8082                	ret
    panic("bwrite");
    800032f2:	00005517          	auipc	a0,0x5
    800032f6:	2f650513          	addi	a0,a0,758 # 800085e8 <syscalls+0xe8>
    800032fa:	ffffd097          	auipc	ra,0xffffd
    800032fe:	24a080e7          	jalr	586(ra) # 80000544 <panic>

0000000080003302 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003302:	1101                	addi	sp,sp,-32
    80003304:	ec06                	sd	ra,24(sp)
    80003306:	e822                	sd	s0,16(sp)
    80003308:	e426                	sd	s1,8(sp)
    8000330a:	e04a                	sd	s2,0(sp)
    8000330c:	1000                	addi	s0,sp,32
    8000330e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003310:	01050913          	addi	s2,a0,16
    80003314:	854a                	mv	a0,s2
    80003316:	00001097          	auipc	ra,0x1
    8000331a:	42a080e7          	jalr	1066(ra) # 80004740 <holdingsleep>
    8000331e:	c92d                	beqz	a0,80003390 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003320:	854a                	mv	a0,s2
    80003322:	00001097          	auipc	ra,0x1
    80003326:	3da080e7          	jalr	986(ra) # 800046fc <releasesleep>

  acquire(&bcache.lock);
    8000332a:	00020517          	auipc	a0,0x20
    8000332e:	2ee50513          	addi	a0,a0,750 # 80023618 <bcache>
    80003332:	ffffe097          	auipc	ra,0xffffe
    80003336:	8b8080e7          	jalr	-1864(ra) # 80000bea <acquire>
  b->refcnt--;
    8000333a:	40bc                	lw	a5,64(s1)
    8000333c:	37fd                	addiw	a5,a5,-1
    8000333e:	0007871b          	sext.w	a4,a5
    80003342:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003344:	eb05                	bnez	a4,80003374 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003346:	68bc                	ld	a5,80(s1)
    80003348:	64b8                	ld	a4,72(s1)
    8000334a:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000334c:	64bc                	ld	a5,72(s1)
    8000334e:	68b8                	ld	a4,80(s1)
    80003350:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003352:	00028797          	auipc	a5,0x28
    80003356:	2c678793          	addi	a5,a5,710 # 8002b618 <bcache+0x8000>
    8000335a:	2b87b703          	ld	a4,696(a5)
    8000335e:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003360:	00028717          	auipc	a4,0x28
    80003364:	52070713          	addi	a4,a4,1312 # 8002b880 <bcache+0x8268>
    80003368:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000336a:	2b87b703          	ld	a4,696(a5)
    8000336e:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003370:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003374:	00020517          	auipc	a0,0x20
    80003378:	2a450513          	addi	a0,a0,676 # 80023618 <bcache>
    8000337c:	ffffe097          	auipc	ra,0xffffe
    80003380:	922080e7          	jalr	-1758(ra) # 80000c9e <release>
}
    80003384:	60e2                	ld	ra,24(sp)
    80003386:	6442                	ld	s0,16(sp)
    80003388:	64a2                	ld	s1,8(sp)
    8000338a:	6902                	ld	s2,0(sp)
    8000338c:	6105                	addi	sp,sp,32
    8000338e:	8082                	ret
    panic("brelse");
    80003390:	00005517          	auipc	a0,0x5
    80003394:	26050513          	addi	a0,a0,608 # 800085f0 <syscalls+0xf0>
    80003398:	ffffd097          	auipc	ra,0xffffd
    8000339c:	1ac080e7          	jalr	428(ra) # 80000544 <panic>

00000000800033a0 <bpin>:

void
bpin(struct buf *b) {
    800033a0:	1101                	addi	sp,sp,-32
    800033a2:	ec06                	sd	ra,24(sp)
    800033a4:	e822                	sd	s0,16(sp)
    800033a6:	e426                	sd	s1,8(sp)
    800033a8:	1000                	addi	s0,sp,32
    800033aa:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800033ac:	00020517          	auipc	a0,0x20
    800033b0:	26c50513          	addi	a0,a0,620 # 80023618 <bcache>
    800033b4:	ffffe097          	auipc	ra,0xffffe
    800033b8:	836080e7          	jalr	-1994(ra) # 80000bea <acquire>
  b->refcnt++;
    800033bc:	40bc                	lw	a5,64(s1)
    800033be:	2785                	addiw	a5,a5,1
    800033c0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800033c2:	00020517          	auipc	a0,0x20
    800033c6:	25650513          	addi	a0,a0,598 # 80023618 <bcache>
    800033ca:	ffffe097          	auipc	ra,0xffffe
    800033ce:	8d4080e7          	jalr	-1836(ra) # 80000c9e <release>
}
    800033d2:	60e2                	ld	ra,24(sp)
    800033d4:	6442                	ld	s0,16(sp)
    800033d6:	64a2                	ld	s1,8(sp)
    800033d8:	6105                	addi	sp,sp,32
    800033da:	8082                	ret

00000000800033dc <bunpin>:

void
bunpin(struct buf *b) {
    800033dc:	1101                	addi	sp,sp,-32
    800033de:	ec06                	sd	ra,24(sp)
    800033e0:	e822                	sd	s0,16(sp)
    800033e2:	e426                	sd	s1,8(sp)
    800033e4:	1000                	addi	s0,sp,32
    800033e6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800033e8:	00020517          	auipc	a0,0x20
    800033ec:	23050513          	addi	a0,a0,560 # 80023618 <bcache>
    800033f0:	ffffd097          	auipc	ra,0xffffd
    800033f4:	7fa080e7          	jalr	2042(ra) # 80000bea <acquire>
  b->refcnt--;
    800033f8:	40bc                	lw	a5,64(s1)
    800033fa:	37fd                	addiw	a5,a5,-1
    800033fc:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800033fe:	00020517          	auipc	a0,0x20
    80003402:	21a50513          	addi	a0,a0,538 # 80023618 <bcache>
    80003406:	ffffe097          	auipc	ra,0xffffe
    8000340a:	898080e7          	jalr	-1896(ra) # 80000c9e <release>
}
    8000340e:	60e2                	ld	ra,24(sp)
    80003410:	6442                	ld	s0,16(sp)
    80003412:	64a2                	ld	s1,8(sp)
    80003414:	6105                	addi	sp,sp,32
    80003416:	8082                	ret

0000000080003418 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003418:	1101                	addi	sp,sp,-32
    8000341a:	ec06                	sd	ra,24(sp)
    8000341c:	e822                	sd	s0,16(sp)
    8000341e:	e426                	sd	s1,8(sp)
    80003420:	e04a                	sd	s2,0(sp)
    80003422:	1000                	addi	s0,sp,32
    80003424:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003426:	00d5d59b          	srliw	a1,a1,0xd
    8000342a:	00029797          	auipc	a5,0x29
    8000342e:	8ca7a783          	lw	a5,-1846(a5) # 8002bcf4 <sb+0x1c>
    80003432:	9dbd                	addw	a1,a1,a5
    80003434:	00000097          	auipc	ra,0x0
    80003438:	d9e080e7          	jalr	-610(ra) # 800031d2 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000343c:	0074f713          	andi	a4,s1,7
    80003440:	4785                	li	a5,1
    80003442:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003446:	14ce                	slli	s1,s1,0x33
    80003448:	90d9                	srli	s1,s1,0x36
    8000344a:	00950733          	add	a4,a0,s1
    8000344e:	05874703          	lbu	a4,88(a4)
    80003452:	00e7f6b3          	and	a3,a5,a4
    80003456:	c69d                	beqz	a3,80003484 <bfree+0x6c>
    80003458:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000345a:	94aa                	add	s1,s1,a0
    8000345c:	fff7c793          	not	a5,a5
    80003460:	8ff9                	and	a5,a5,a4
    80003462:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003466:	00001097          	auipc	ra,0x1
    8000346a:	120080e7          	jalr	288(ra) # 80004586 <log_write>
  brelse(bp);
    8000346e:	854a                	mv	a0,s2
    80003470:	00000097          	auipc	ra,0x0
    80003474:	e92080e7          	jalr	-366(ra) # 80003302 <brelse>
}
    80003478:	60e2                	ld	ra,24(sp)
    8000347a:	6442                	ld	s0,16(sp)
    8000347c:	64a2                	ld	s1,8(sp)
    8000347e:	6902                	ld	s2,0(sp)
    80003480:	6105                	addi	sp,sp,32
    80003482:	8082                	ret
    panic("freeing free block");
    80003484:	00005517          	auipc	a0,0x5
    80003488:	17450513          	addi	a0,a0,372 # 800085f8 <syscalls+0xf8>
    8000348c:	ffffd097          	auipc	ra,0xffffd
    80003490:	0b8080e7          	jalr	184(ra) # 80000544 <panic>

0000000080003494 <balloc>:
{
    80003494:	711d                	addi	sp,sp,-96
    80003496:	ec86                	sd	ra,88(sp)
    80003498:	e8a2                	sd	s0,80(sp)
    8000349a:	e4a6                	sd	s1,72(sp)
    8000349c:	e0ca                	sd	s2,64(sp)
    8000349e:	fc4e                	sd	s3,56(sp)
    800034a0:	f852                	sd	s4,48(sp)
    800034a2:	f456                	sd	s5,40(sp)
    800034a4:	f05a                	sd	s6,32(sp)
    800034a6:	ec5e                	sd	s7,24(sp)
    800034a8:	e862                	sd	s8,16(sp)
    800034aa:	e466                	sd	s9,8(sp)
    800034ac:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800034ae:	00029797          	auipc	a5,0x29
    800034b2:	82e7a783          	lw	a5,-2002(a5) # 8002bcdc <sb+0x4>
    800034b6:	10078163          	beqz	a5,800035b8 <balloc+0x124>
    800034ba:	8baa                	mv	s7,a0
    800034bc:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800034be:	00029b17          	auipc	s6,0x29
    800034c2:	81ab0b13          	addi	s6,s6,-2022 # 8002bcd8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034c6:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800034c8:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034ca:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800034cc:	6c89                	lui	s9,0x2
    800034ce:	a061                	j	80003556 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    800034d0:	974a                	add	a4,a4,s2
    800034d2:	8fd5                	or	a5,a5,a3
    800034d4:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800034d8:	854a                	mv	a0,s2
    800034da:	00001097          	auipc	ra,0x1
    800034de:	0ac080e7          	jalr	172(ra) # 80004586 <log_write>
        brelse(bp);
    800034e2:	854a                	mv	a0,s2
    800034e4:	00000097          	auipc	ra,0x0
    800034e8:	e1e080e7          	jalr	-482(ra) # 80003302 <brelse>
  bp = bread(dev, bno);
    800034ec:	85a6                	mv	a1,s1
    800034ee:	855e                	mv	a0,s7
    800034f0:	00000097          	auipc	ra,0x0
    800034f4:	ce2080e7          	jalr	-798(ra) # 800031d2 <bread>
    800034f8:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800034fa:	40000613          	li	a2,1024
    800034fe:	4581                	li	a1,0
    80003500:	05850513          	addi	a0,a0,88
    80003504:	ffffd097          	auipc	ra,0xffffd
    80003508:	7e2080e7          	jalr	2018(ra) # 80000ce6 <memset>
  log_write(bp);
    8000350c:	854a                	mv	a0,s2
    8000350e:	00001097          	auipc	ra,0x1
    80003512:	078080e7          	jalr	120(ra) # 80004586 <log_write>
  brelse(bp);
    80003516:	854a                	mv	a0,s2
    80003518:	00000097          	auipc	ra,0x0
    8000351c:	dea080e7          	jalr	-534(ra) # 80003302 <brelse>
}
    80003520:	8526                	mv	a0,s1
    80003522:	60e6                	ld	ra,88(sp)
    80003524:	6446                	ld	s0,80(sp)
    80003526:	64a6                	ld	s1,72(sp)
    80003528:	6906                	ld	s2,64(sp)
    8000352a:	79e2                	ld	s3,56(sp)
    8000352c:	7a42                	ld	s4,48(sp)
    8000352e:	7aa2                	ld	s5,40(sp)
    80003530:	7b02                	ld	s6,32(sp)
    80003532:	6be2                	ld	s7,24(sp)
    80003534:	6c42                	ld	s8,16(sp)
    80003536:	6ca2                	ld	s9,8(sp)
    80003538:	6125                	addi	sp,sp,96
    8000353a:	8082                	ret
    brelse(bp);
    8000353c:	854a                	mv	a0,s2
    8000353e:	00000097          	auipc	ra,0x0
    80003542:	dc4080e7          	jalr	-572(ra) # 80003302 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003546:	015c87bb          	addw	a5,s9,s5
    8000354a:	00078a9b          	sext.w	s5,a5
    8000354e:	004b2703          	lw	a4,4(s6)
    80003552:	06eaf363          	bgeu	s5,a4,800035b8 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    80003556:	41fad79b          	sraiw	a5,s5,0x1f
    8000355a:	0137d79b          	srliw	a5,a5,0x13
    8000355e:	015787bb          	addw	a5,a5,s5
    80003562:	40d7d79b          	sraiw	a5,a5,0xd
    80003566:	01cb2583          	lw	a1,28(s6)
    8000356a:	9dbd                	addw	a1,a1,a5
    8000356c:	855e                	mv	a0,s7
    8000356e:	00000097          	auipc	ra,0x0
    80003572:	c64080e7          	jalr	-924(ra) # 800031d2 <bread>
    80003576:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003578:	004b2503          	lw	a0,4(s6)
    8000357c:	000a849b          	sext.w	s1,s5
    80003580:	8662                	mv	a2,s8
    80003582:	faa4fde3          	bgeu	s1,a0,8000353c <balloc+0xa8>
      m = 1 << (bi % 8);
    80003586:	41f6579b          	sraiw	a5,a2,0x1f
    8000358a:	01d7d69b          	srliw	a3,a5,0x1d
    8000358e:	00c6873b          	addw	a4,a3,a2
    80003592:	00777793          	andi	a5,a4,7
    80003596:	9f95                	subw	a5,a5,a3
    80003598:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000359c:	4037571b          	sraiw	a4,a4,0x3
    800035a0:	00e906b3          	add	a3,s2,a4
    800035a4:	0586c683          	lbu	a3,88(a3)
    800035a8:	00d7f5b3          	and	a1,a5,a3
    800035ac:	d195                	beqz	a1,800034d0 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035ae:	2605                	addiw	a2,a2,1
    800035b0:	2485                	addiw	s1,s1,1
    800035b2:	fd4618e3          	bne	a2,s4,80003582 <balloc+0xee>
    800035b6:	b759                	j	8000353c <balloc+0xa8>
  printf("balloc: out of blocks\n");
    800035b8:	00005517          	auipc	a0,0x5
    800035bc:	05850513          	addi	a0,a0,88 # 80008610 <syscalls+0x110>
    800035c0:	ffffd097          	auipc	ra,0xffffd
    800035c4:	fce080e7          	jalr	-50(ra) # 8000058e <printf>
  return 0;
    800035c8:	4481                	li	s1,0
    800035ca:	bf99                	j	80003520 <balloc+0x8c>

00000000800035cc <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800035cc:	7179                	addi	sp,sp,-48
    800035ce:	f406                	sd	ra,40(sp)
    800035d0:	f022                	sd	s0,32(sp)
    800035d2:	ec26                	sd	s1,24(sp)
    800035d4:	e84a                	sd	s2,16(sp)
    800035d6:	e44e                	sd	s3,8(sp)
    800035d8:	e052                	sd	s4,0(sp)
    800035da:	1800                	addi	s0,sp,48
    800035dc:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800035de:	47ad                	li	a5,11
    800035e0:	02b7e763          	bltu	a5,a1,8000360e <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    800035e4:	02059493          	slli	s1,a1,0x20
    800035e8:	9081                	srli	s1,s1,0x20
    800035ea:	048a                	slli	s1,s1,0x2
    800035ec:	94aa                	add	s1,s1,a0
    800035ee:	0504a903          	lw	s2,80(s1)
    800035f2:	06091e63          	bnez	s2,8000366e <bmap+0xa2>
      addr = balloc(ip->dev);
    800035f6:	4108                	lw	a0,0(a0)
    800035f8:	00000097          	auipc	ra,0x0
    800035fc:	e9c080e7          	jalr	-356(ra) # 80003494 <balloc>
    80003600:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003604:	06090563          	beqz	s2,8000366e <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    80003608:	0524a823          	sw	s2,80(s1)
    8000360c:	a08d                	j	8000366e <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    8000360e:	ff45849b          	addiw	s1,a1,-12
    80003612:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003616:	0ff00793          	li	a5,255
    8000361a:	08e7e563          	bltu	a5,a4,800036a4 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    8000361e:	08052903          	lw	s2,128(a0)
    80003622:	00091d63          	bnez	s2,8000363c <bmap+0x70>
      addr = balloc(ip->dev);
    80003626:	4108                	lw	a0,0(a0)
    80003628:	00000097          	auipc	ra,0x0
    8000362c:	e6c080e7          	jalr	-404(ra) # 80003494 <balloc>
    80003630:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003634:	02090d63          	beqz	s2,8000366e <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003638:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    8000363c:	85ca                	mv	a1,s2
    8000363e:	0009a503          	lw	a0,0(s3)
    80003642:	00000097          	auipc	ra,0x0
    80003646:	b90080e7          	jalr	-1136(ra) # 800031d2 <bread>
    8000364a:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000364c:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003650:	02049593          	slli	a1,s1,0x20
    80003654:	9181                	srli	a1,a1,0x20
    80003656:	058a                	slli	a1,a1,0x2
    80003658:	00b784b3          	add	s1,a5,a1
    8000365c:	0004a903          	lw	s2,0(s1)
    80003660:	02090063          	beqz	s2,80003680 <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003664:	8552                	mv	a0,s4
    80003666:	00000097          	auipc	ra,0x0
    8000366a:	c9c080e7          	jalr	-868(ra) # 80003302 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000366e:	854a                	mv	a0,s2
    80003670:	70a2                	ld	ra,40(sp)
    80003672:	7402                	ld	s0,32(sp)
    80003674:	64e2                	ld	s1,24(sp)
    80003676:	6942                	ld	s2,16(sp)
    80003678:	69a2                	ld	s3,8(sp)
    8000367a:	6a02                	ld	s4,0(sp)
    8000367c:	6145                	addi	sp,sp,48
    8000367e:	8082                	ret
      addr = balloc(ip->dev);
    80003680:	0009a503          	lw	a0,0(s3)
    80003684:	00000097          	auipc	ra,0x0
    80003688:	e10080e7          	jalr	-496(ra) # 80003494 <balloc>
    8000368c:	0005091b          	sext.w	s2,a0
      if(addr){
    80003690:	fc090ae3          	beqz	s2,80003664 <bmap+0x98>
        a[bn] = addr;
    80003694:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003698:	8552                	mv	a0,s4
    8000369a:	00001097          	auipc	ra,0x1
    8000369e:	eec080e7          	jalr	-276(ra) # 80004586 <log_write>
    800036a2:	b7c9                	j	80003664 <bmap+0x98>
  panic("bmap: out of range");
    800036a4:	00005517          	auipc	a0,0x5
    800036a8:	f8450513          	addi	a0,a0,-124 # 80008628 <syscalls+0x128>
    800036ac:	ffffd097          	auipc	ra,0xffffd
    800036b0:	e98080e7          	jalr	-360(ra) # 80000544 <panic>

00000000800036b4 <iget>:
{
    800036b4:	7179                	addi	sp,sp,-48
    800036b6:	f406                	sd	ra,40(sp)
    800036b8:	f022                	sd	s0,32(sp)
    800036ba:	ec26                	sd	s1,24(sp)
    800036bc:	e84a                	sd	s2,16(sp)
    800036be:	e44e                	sd	s3,8(sp)
    800036c0:	e052                	sd	s4,0(sp)
    800036c2:	1800                	addi	s0,sp,48
    800036c4:	89aa                	mv	s3,a0
    800036c6:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800036c8:	00028517          	auipc	a0,0x28
    800036cc:	63050513          	addi	a0,a0,1584 # 8002bcf8 <itable>
    800036d0:	ffffd097          	auipc	ra,0xffffd
    800036d4:	51a080e7          	jalr	1306(ra) # 80000bea <acquire>
  empty = 0;
    800036d8:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800036da:	00028497          	auipc	s1,0x28
    800036de:	63648493          	addi	s1,s1,1590 # 8002bd10 <itable+0x18>
    800036e2:	0002a697          	auipc	a3,0x2a
    800036e6:	0be68693          	addi	a3,a3,190 # 8002d7a0 <log>
    800036ea:	a039                	j	800036f8 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800036ec:	02090b63          	beqz	s2,80003722 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800036f0:	08848493          	addi	s1,s1,136
    800036f4:	02d48a63          	beq	s1,a3,80003728 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800036f8:	449c                	lw	a5,8(s1)
    800036fa:	fef059e3          	blez	a5,800036ec <iget+0x38>
    800036fe:	4098                	lw	a4,0(s1)
    80003700:	ff3716e3          	bne	a4,s3,800036ec <iget+0x38>
    80003704:	40d8                	lw	a4,4(s1)
    80003706:	ff4713e3          	bne	a4,s4,800036ec <iget+0x38>
      ip->ref++;
    8000370a:	2785                	addiw	a5,a5,1
    8000370c:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000370e:	00028517          	auipc	a0,0x28
    80003712:	5ea50513          	addi	a0,a0,1514 # 8002bcf8 <itable>
    80003716:	ffffd097          	auipc	ra,0xffffd
    8000371a:	588080e7          	jalr	1416(ra) # 80000c9e <release>
      return ip;
    8000371e:	8926                	mv	s2,s1
    80003720:	a03d                	j	8000374e <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003722:	f7f9                	bnez	a5,800036f0 <iget+0x3c>
    80003724:	8926                	mv	s2,s1
    80003726:	b7e9                	j	800036f0 <iget+0x3c>
  if(empty == 0)
    80003728:	02090c63          	beqz	s2,80003760 <iget+0xac>
  ip->dev = dev;
    8000372c:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003730:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003734:	4785                	li	a5,1
    80003736:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000373a:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000373e:	00028517          	auipc	a0,0x28
    80003742:	5ba50513          	addi	a0,a0,1466 # 8002bcf8 <itable>
    80003746:	ffffd097          	auipc	ra,0xffffd
    8000374a:	558080e7          	jalr	1368(ra) # 80000c9e <release>
}
    8000374e:	854a                	mv	a0,s2
    80003750:	70a2                	ld	ra,40(sp)
    80003752:	7402                	ld	s0,32(sp)
    80003754:	64e2                	ld	s1,24(sp)
    80003756:	6942                	ld	s2,16(sp)
    80003758:	69a2                	ld	s3,8(sp)
    8000375a:	6a02                	ld	s4,0(sp)
    8000375c:	6145                	addi	sp,sp,48
    8000375e:	8082                	ret
    panic("iget: no inodes");
    80003760:	00005517          	auipc	a0,0x5
    80003764:	ee050513          	addi	a0,a0,-288 # 80008640 <syscalls+0x140>
    80003768:	ffffd097          	auipc	ra,0xffffd
    8000376c:	ddc080e7          	jalr	-548(ra) # 80000544 <panic>

0000000080003770 <fsinit>:
fsinit(int dev) {
    80003770:	7179                	addi	sp,sp,-48
    80003772:	f406                	sd	ra,40(sp)
    80003774:	f022                	sd	s0,32(sp)
    80003776:	ec26                	sd	s1,24(sp)
    80003778:	e84a                	sd	s2,16(sp)
    8000377a:	e44e                	sd	s3,8(sp)
    8000377c:	1800                	addi	s0,sp,48
    8000377e:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003780:	4585                	li	a1,1
    80003782:	00000097          	auipc	ra,0x0
    80003786:	a50080e7          	jalr	-1456(ra) # 800031d2 <bread>
    8000378a:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000378c:	00028997          	auipc	s3,0x28
    80003790:	54c98993          	addi	s3,s3,1356 # 8002bcd8 <sb>
    80003794:	02000613          	li	a2,32
    80003798:	05850593          	addi	a1,a0,88
    8000379c:	854e                	mv	a0,s3
    8000379e:	ffffd097          	auipc	ra,0xffffd
    800037a2:	5a8080e7          	jalr	1448(ra) # 80000d46 <memmove>
  brelse(bp);
    800037a6:	8526                	mv	a0,s1
    800037a8:	00000097          	auipc	ra,0x0
    800037ac:	b5a080e7          	jalr	-1190(ra) # 80003302 <brelse>
  if(sb.magic != FSMAGIC)
    800037b0:	0009a703          	lw	a4,0(s3)
    800037b4:	102037b7          	lui	a5,0x10203
    800037b8:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800037bc:	02f71263          	bne	a4,a5,800037e0 <fsinit+0x70>
  initlog(dev, &sb);
    800037c0:	00028597          	auipc	a1,0x28
    800037c4:	51858593          	addi	a1,a1,1304 # 8002bcd8 <sb>
    800037c8:	854a                	mv	a0,s2
    800037ca:	00001097          	auipc	ra,0x1
    800037ce:	b40080e7          	jalr	-1216(ra) # 8000430a <initlog>
}
    800037d2:	70a2                	ld	ra,40(sp)
    800037d4:	7402                	ld	s0,32(sp)
    800037d6:	64e2                	ld	s1,24(sp)
    800037d8:	6942                	ld	s2,16(sp)
    800037da:	69a2                	ld	s3,8(sp)
    800037dc:	6145                	addi	sp,sp,48
    800037de:	8082                	ret
    panic("invalid file system");
    800037e0:	00005517          	auipc	a0,0x5
    800037e4:	e7050513          	addi	a0,a0,-400 # 80008650 <syscalls+0x150>
    800037e8:	ffffd097          	auipc	ra,0xffffd
    800037ec:	d5c080e7          	jalr	-676(ra) # 80000544 <panic>

00000000800037f0 <iinit>:
{
    800037f0:	7179                	addi	sp,sp,-48
    800037f2:	f406                	sd	ra,40(sp)
    800037f4:	f022                	sd	s0,32(sp)
    800037f6:	ec26                	sd	s1,24(sp)
    800037f8:	e84a                	sd	s2,16(sp)
    800037fa:	e44e                	sd	s3,8(sp)
    800037fc:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800037fe:	00005597          	auipc	a1,0x5
    80003802:	e6a58593          	addi	a1,a1,-406 # 80008668 <syscalls+0x168>
    80003806:	00028517          	auipc	a0,0x28
    8000380a:	4f250513          	addi	a0,a0,1266 # 8002bcf8 <itable>
    8000380e:	ffffd097          	auipc	ra,0xffffd
    80003812:	34c080e7          	jalr	844(ra) # 80000b5a <initlock>
  for(i = 0; i < NINODE; i++) {
    80003816:	00028497          	auipc	s1,0x28
    8000381a:	50a48493          	addi	s1,s1,1290 # 8002bd20 <itable+0x28>
    8000381e:	0002a997          	auipc	s3,0x2a
    80003822:	f9298993          	addi	s3,s3,-110 # 8002d7b0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003826:	00005917          	auipc	s2,0x5
    8000382a:	e4a90913          	addi	s2,s2,-438 # 80008670 <syscalls+0x170>
    8000382e:	85ca                	mv	a1,s2
    80003830:	8526                	mv	a0,s1
    80003832:	00001097          	auipc	ra,0x1
    80003836:	e3a080e7          	jalr	-454(ra) # 8000466c <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000383a:	08848493          	addi	s1,s1,136
    8000383e:	ff3498e3          	bne	s1,s3,8000382e <iinit+0x3e>
}
    80003842:	70a2                	ld	ra,40(sp)
    80003844:	7402                	ld	s0,32(sp)
    80003846:	64e2                	ld	s1,24(sp)
    80003848:	6942                	ld	s2,16(sp)
    8000384a:	69a2                	ld	s3,8(sp)
    8000384c:	6145                	addi	sp,sp,48
    8000384e:	8082                	ret

0000000080003850 <ialloc>:
{
    80003850:	715d                	addi	sp,sp,-80
    80003852:	e486                	sd	ra,72(sp)
    80003854:	e0a2                	sd	s0,64(sp)
    80003856:	fc26                	sd	s1,56(sp)
    80003858:	f84a                	sd	s2,48(sp)
    8000385a:	f44e                	sd	s3,40(sp)
    8000385c:	f052                	sd	s4,32(sp)
    8000385e:	ec56                	sd	s5,24(sp)
    80003860:	e85a                	sd	s6,16(sp)
    80003862:	e45e                	sd	s7,8(sp)
    80003864:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003866:	00028717          	auipc	a4,0x28
    8000386a:	47e72703          	lw	a4,1150(a4) # 8002bce4 <sb+0xc>
    8000386e:	4785                	li	a5,1
    80003870:	04e7fa63          	bgeu	a5,a4,800038c4 <ialloc+0x74>
    80003874:	8aaa                	mv	s5,a0
    80003876:	8bae                	mv	s7,a1
    80003878:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000387a:	00028a17          	auipc	s4,0x28
    8000387e:	45ea0a13          	addi	s4,s4,1118 # 8002bcd8 <sb>
    80003882:	00048b1b          	sext.w	s6,s1
    80003886:	0044d593          	srli	a1,s1,0x4
    8000388a:	018a2783          	lw	a5,24(s4)
    8000388e:	9dbd                	addw	a1,a1,a5
    80003890:	8556                	mv	a0,s5
    80003892:	00000097          	auipc	ra,0x0
    80003896:	940080e7          	jalr	-1728(ra) # 800031d2 <bread>
    8000389a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000389c:	05850993          	addi	s3,a0,88
    800038a0:	00f4f793          	andi	a5,s1,15
    800038a4:	079a                	slli	a5,a5,0x6
    800038a6:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800038a8:	00099783          	lh	a5,0(s3)
    800038ac:	c3a1                	beqz	a5,800038ec <ialloc+0x9c>
    brelse(bp);
    800038ae:	00000097          	auipc	ra,0x0
    800038b2:	a54080e7          	jalr	-1452(ra) # 80003302 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800038b6:	0485                	addi	s1,s1,1
    800038b8:	00ca2703          	lw	a4,12(s4)
    800038bc:	0004879b          	sext.w	a5,s1
    800038c0:	fce7e1e3          	bltu	a5,a4,80003882 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    800038c4:	00005517          	auipc	a0,0x5
    800038c8:	db450513          	addi	a0,a0,-588 # 80008678 <syscalls+0x178>
    800038cc:	ffffd097          	auipc	ra,0xffffd
    800038d0:	cc2080e7          	jalr	-830(ra) # 8000058e <printf>
  return 0;
    800038d4:	4501                	li	a0,0
}
    800038d6:	60a6                	ld	ra,72(sp)
    800038d8:	6406                	ld	s0,64(sp)
    800038da:	74e2                	ld	s1,56(sp)
    800038dc:	7942                	ld	s2,48(sp)
    800038de:	79a2                	ld	s3,40(sp)
    800038e0:	7a02                	ld	s4,32(sp)
    800038e2:	6ae2                	ld	s5,24(sp)
    800038e4:	6b42                	ld	s6,16(sp)
    800038e6:	6ba2                	ld	s7,8(sp)
    800038e8:	6161                	addi	sp,sp,80
    800038ea:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800038ec:	04000613          	li	a2,64
    800038f0:	4581                	li	a1,0
    800038f2:	854e                	mv	a0,s3
    800038f4:	ffffd097          	auipc	ra,0xffffd
    800038f8:	3f2080e7          	jalr	1010(ra) # 80000ce6 <memset>
      dip->type = type;
    800038fc:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003900:	854a                	mv	a0,s2
    80003902:	00001097          	auipc	ra,0x1
    80003906:	c84080e7          	jalr	-892(ra) # 80004586 <log_write>
      brelse(bp);
    8000390a:	854a                	mv	a0,s2
    8000390c:	00000097          	auipc	ra,0x0
    80003910:	9f6080e7          	jalr	-1546(ra) # 80003302 <brelse>
      return iget(dev, inum);
    80003914:	85da                	mv	a1,s6
    80003916:	8556                	mv	a0,s5
    80003918:	00000097          	auipc	ra,0x0
    8000391c:	d9c080e7          	jalr	-612(ra) # 800036b4 <iget>
    80003920:	bf5d                	j	800038d6 <ialloc+0x86>

0000000080003922 <iupdate>:
{
    80003922:	1101                	addi	sp,sp,-32
    80003924:	ec06                	sd	ra,24(sp)
    80003926:	e822                	sd	s0,16(sp)
    80003928:	e426                	sd	s1,8(sp)
    8000392a:	e04a                	sd	s2,0(sp)
    8000392c:	1000                	addi	s0,sp,32
    8000392e:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003930:	415c                	lw	a5,4(a0)
    80003932:	0047d79b          	srliw	a5,a5,0x4
    80003936:	00028597          	auipc	a1,0x28
    8000393a:	3ba5a583          	lw	a1,954(a1) # 8002bcf0 <sb+0x18>
    8000393e:	9dbd                	addw	a1,a1,a5
    80003940:	4108                	lw	a0,0(a0)
    80003942:	00000097          	auipc	ra,0x0
    80003946:	890080e7          	jalr	-1904(ra) # 800031d2 <bread>
    8000394a:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000394c:	05850793          	addi	a5,a0,88
    80003950:	40c8                	lw	a0,4(s1)
    80003952:	893d                	andi	a0,a0,15
    80003954:	051a                	slli	a0,a0,0x6
    80003956:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003958:	04449703          	lh	a4,68(s1)
    8000395c:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003960:	04649703          	lh	a4,70(s1)
    80003964:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003968:	04849703          	lh	a4,72(s1)
    8000396c:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003970:	04a49703          	lh	a4,74(s1)
    80003974:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003978:	44f8                	lw	a4,76(s1)
    8000397a:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000397c:	03400613          	li	a2,52
    80003980:	05048593          	addi	a1,s1,80
    80003984:	0531                	addi	a0,a0,12
    80003986:	ffffd097          	auipc	ra,0xffffd
    8000398a:	3c0080e7          	jalr	960(ra) # 80000d46 <memmove>
  log_write(bp);
    8000398e:	854a                	mv	a0,s2
    80003990:	00001097          	auipc	ra,0x1
    80003994:	bf6080e7          	jalr	-1034(ra) # 80004586 <log_write>
  brelse(bp);
    80003998:	854a                	mv	a0,s2
    8000399a:	00000097          	auipc	ra,0x0
    8000399e:	968080e7          	jalr	-1688(ra) # 80003302 <brelse>
}
    800039a2:	60e2                	ld	ra,24(sp)
    800039a4:	6442                	ld	s0,16(sp)
    800039a6:	64a2                	ld	s1,8(sp)
    800039a8:	6902                	ld	s2,0(sp)
    800039aa:	6105                	addi	sp,sp,32
    800039ac:	8082                	ret

00000000800039ae <idup>:
{
    800039ae:	1101                	addi	sp,sp,-32
    800039b0:	ec06                	sd	ra,24(sp)
    800039b2:	e822                	sd	s0,16(sp)
    800039b4:	e426                	sd	s1,8(sp)
    800039b6:	1000                	addi	s0,sp,32
    800039b8:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800039ba:	00028517          	auipc	a0,0x28
    800039be:	33e50513          	addi	a0,a0,830 # 8002bcf8 <itable>
    800039c2:	ffffd097          	auipc	ra,0xffffd
    800039c6:	228080e7          	jalr	552(ra) # 80000bea <acquire>
  ip->ref++;
    800039ca:	449c                	lw	a5,8(s1)
    800039cc:	2785                	addiw	a5,a5,1
    800039ce:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800039d0:	00028517          	auipc	a0,0x28
    800039d4:	32850513          	addi	a0,a0,808 # 8002bcf8 <itable>
    800039d8:	ffffd097          	auipc	ra,0xffffd
    800039dc:	2c6080e7          	jalr	710(ra) # 80000c9e <release>
}
    800039e0:	8526                	mv	a0,s1
    800039e2:	60e2                	ld	ra,24(sp)
    800039e4:	6442                	ld	s0,16(sp)
    800039e6:	64a2                	ld	s1,8(sp)
    800039e8:	6105                	addi	sp,sp,32
    800039ea:	8082                	ret

00000000800039ec <ilock>:
{
    800039ec:	1101                	addi	sp,sp,-32
    800039ee:	ec06                	sd	ra,24(sp)
    800039f0:	e822                	sd	s0,16(sp)
    800039f2:	e426                	sd	s1,8(sp)
    800039f4:	e04a                	sd	s2,0(sp)
    800039f6:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800039f8:	c115                	beqz	a0,80003a1c <ilock+0x30>
    800039fa:	84aa                	mv	s1,a0
    800039fc:	451c                	lw	a5,8(a0)
    800039fe:	00f05f63          	blez	a5,80003a1c <ilock+0x30>
  acquiresleep(&ip->lock);
    80003a02:	0541                	addi	a0,a0,16
    80003a04:	00001097          	auipc	ra,0x1
    80003a08:	ca2080e7          	jalr	-862(ra) # 800046a6 <acquiresleep>
  if(ip->valid == 0){
    80003a0c:	40bc                	lw	a5,64(s1)
    80003a0e:	cf99                	beqz	a5,80003a2c <ilock+0x40>
}
    80003a10:	60e2                	ld	ra,24(sp)
    80003a12:	6442                	ld	s0,16(sp)
    80003a14:	64a2                	ld	s1,8(sp)
    80003a16:	6902                	ld	s2,0(sp)
    80003a18:	6105                	addi	sp,sp,32
    80003a1a:	8082                	ret
    panic("ilock");
    80003a1c:	00005517          	auipc	a0,0x5
    80003a20:	c7450513          	addi	a0,a0,-908 # 80008690 <syscalls+0x190>
    80003a24:	ffffd097          	auipc	ra,0xffffd
    80003a28:	b20080e7          	jalr	-1248(ra) # 80000544 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a2c:	40dc                	lw	a5,4(s1)
    80003a2e:	0047d79b          	srliw	a5,a5,0x4
    80003a32:	00028597          	auipc	a1,0x28
    80003a36:	2be5a583          	lw	a1,702(a1) # 8002bcf0 <sb+0x18>
    80003a3a:	9dbd                	addw	a1,a1,a5
    80003a3c:	4088                	lw	a0,0(s1)
    80003a3e:	fffff097          	auipc	ra,0xfffff
    80003a42:	794080e7          	jalr	1940(ra) # 800031d2 <bread>
    80003a46:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a48:	05850593          	addi	a1,a0,88
    80003a4c:	40dc                	lw	a5,4(s1)
    80003a4e:	8bbd                	andi	a5,a5,15
    80003a50:	079a                	slli	a5,a5,0x6
    80003a52:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003a54:	00059783          	lh	a5,0(a1)
    80003a58:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003a5c:	00259783          	lh	a5,2(a1)
    80003a60:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003a64:	00459783          	lh	a5,4(a1)
    80003a68:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003a6c:	00659783          	lh	a5,6(a1)
    80003a70:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003a74:	459c                	lw	a5,8(a1)
    80003a76:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003a78:	03400613          	li	a2,52
    80003a7c:	05b1                	addi	a1,a1,12
    80003a7e:	05048513          	addi	a0,s1,80
    80003a82:	ffffd097          	auipc	ra,0xffffd
    80003a86:	2c4080e7          	jalr	708(ra) # 80000d46 <memmove>
    brelse(bp);
    80003a8a:	854a                	mv	a0,s2
    80003a8c:	00000097          	auipc	ra,0x0
    80003a90:	876080e7          	jalr	-1930(ra) # 80003302 <brelse>
    ip->valid = 1;
    80003a94:	4785                	li	a5,1
    80003a96:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003a98:	04449783          	lh	a5,68(s1)
    80003a9c:	fbb5                	bnez	a5,80003a10 <ilock+0x24>
      panic("ilock: no type");
    80003a9e:	00005517          	auipc	a0,0x5
    80003aa2:	bfa50513          	addi	a0,a0,-1030 # 80008698 <syscalls+0x198>
    80003aa6:	ffffd097          	auipc	ra,0xffffd
    80003aaa:	a9e080e7          	jalr	-1378(ra) # 80000544 <panic>

0000000080003aae <iunlock>:
{
    80003aae:	1101                	addi	sp,sp,-32
    80003ab0:	ec06                	sd	ra,24(sp)
    80003ab2:	e822                	sd	s0,16(sp)
    80003ab4:	e426                	sd	s1,8(sp)
    80003ab6:	e04a                	sd	s2,0(sp)
    80003ab8:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003aba:	c905                	beqz	a0,80003aea <iunlock+0x3c>
    80003abc:	84aa                	mv	s1,a0
    80003abe:	01050913          	addi	s2,a0,16
    80003ac2:	854a                	mv	a0,s2
    80003ac4:	00001097          	auipc	ra,0x1
    80003ac8:	c7c080e7          	jalr	-900(ra) # 80004740 <holdingsleep>
    80003acc:	cd19                	beqz	a0,80003aea <iunlock+0x3c>
    80003ace:	449c                	lw	a5,8(s1)
    80003ad0:	00f05d63          	blez	a5,80003aea <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003ad4:	854a                	mv	a0,s2
    80003ad6:	00001097          	auipc	ra,0x1
    80003ada:	c26080e7          	jalr	-986(ra) # 800046fc <releasesleep>
}
    80003ade:	60e2                	ld	ra,24(sp)
    80003ae0:	6442                	ld	s0,16(sp)
    80003ae2:	64a2                	ld	s1,8(sp)
    80003ae4:	6902                	ld	s2,0(sp)
    80003ae6:	6105                	addi	sp,sp,32
    80003ae8:	8082                	ret
    panic("iunlock");
    80003aea:	00005517          	auipc	a0,0x5
    80003aee:	bbe50513          	addi	a0,a0,-1090 # 800086a8 <syscalls+0x1a8>
    80003af2:	ffffd097          	auipc	ra,0xffffd
    80003af6:	a52080e7          	jalr	-1454(ra) # 80000544 <panic>

0000000080003afa <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003afa:	7179                	addi	sp,sp,-48
    80003afc:	f406                	sd	ra,40(sp)
    80003afe:	f022                	sd	s0,32(sp)
    80003b00:	ec26                	sd	s1,24(sp)
    80003b02:	e84a                	sd	s2,16(sp)
    80003b04:	e44e                	sd	s3,8(sp)
    80003b06:	e052                	sd	s4,0(sp)
    80003b08:	1800                	addi	s0,sp,48
    80003b0a:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003b0c:	05050493          	addi	s1,a0,80
    80003b10:	08050913          	addi	s2,a0,128
    80003b14:	a021                	j	80003b1c <itrunc+0x22>
    80003b16:	0491                	addi	s1,s1,4
    80003b18:	01248d63          	beq	s1,s2,80003b32 <itrunc+0x38>
    if(ip->addrs[i]){
    80003b1c:	408c                	lw	a1,0(s1)
    80003b1e:	dde5                	beqz	a1,80003b16 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003b20:	0009a503          	lw	a0,0(s3)
    80003b24:	00000097          	auipc	ra,0x0
    80003b28:	8f4080e7          	jalr	-1804(ra) # 80003418 <bfree>
      ip->addrs[i] = 0;
    80003b2c:	0004a023          	sw	zero,0(s1)
    80003b30:	b7dd                	j	80003b16 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003b32:	0809a583          	lw	a1,128(s3)
    80003b36:	e185                	bnez	a1,80003b56 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003b38:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003b3c:	854e                	mv	a0,s3
    80003b3e:	00000097          	auipc	ra,0x0
    80003b42:	de4080e7          	jalr	-540(ra) # 80003922 <iupdate>
}
    80003b46:	70a2                	ld	ra,40(sp)
    80003b48:	7402                	ld	s0,32(sp)
    80003b4a:	64e2                	ld	s1,24(sp)
    80003b4c:	6942                	ld	s2,16(sp)
    80003b4e:	69a2                	ld	s3,8(sp)
    80003b50:	6a02                	ld	s4,0(sp)
    80003b52:	6145                	addi	sp,sp,48
    80003b54:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003b56:	0009a503          	lw	a0,0(s3)
    80003b5a:	fffff097          	auipc	ra,0xfffff
    80003b5e:	678080e7          	jalr	1656(ra) # 800031d2 <bread>
    80003b62:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003b64:	05850493          	addi	s1,a0,88
    80003b68:	45850913          	addi	s2,a0,1112
    80003b6c:	a811                	j	80003b80 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003b6e:	0009a503          	lw	a0,0(s3)
    80003b72:	00000097          	auipc	ra,0x0
    80003b76:	8a6080e7          	jalr	-1882(ra) # 80003418 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003b7a:	0491                	addi	s1,s1,4
    80003b7c:	01248563          	beq	s1,s2,80003b86 <itrunc+0x8c>
      if(a[j])
    80003b80:	408c                	lw	a1,0(s1)
    80003b82:	dde5                	beqz	a1,80003b7a <itrunc+0x80>
    80003b84:	b7ed                	j	80003b6e <itrunc+0x74>
    brelse(bp);
    80003b86:	8552                	mv	a0,s4
    80003b88:	fffff097          	auipc	ra,0xfffff
    80003b8c:	77a080e7          	jalr	1914(ra) # 80003302 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003b90:	0809a583          	lw	a1,128(s3)
    80003b94:	0009a503          	lw	a0,0(s3)
    80003b98:	00000097          	auipc	ra,0x0
    80003b9c:	880080e7          	jalr	-1920(ra) # 80003418 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003ba0:	0809a023          	sw	zero,128(s3)
    80003ba4:	bf51                	j	80003b38 <itrunc+0x3e>

0000000080003ba6 <iput>:
{
    80003ba6:	1101                	addi	sp,sp,-32
    80003ba8:	ec06                	sd	ra,24(sp)
    80003baa:	e822                	sd	s0,16(sp)
    80003bac:	e426                	sd	s1,8(sp)
    80003bae:	e04a                	sd	s2,0(sp)
    80003bb0:	1000                	addi	s0,sp,32
    80003bb2:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003bb4:	00028517          	auipc	a0,0x28
    80003bb8:	14450513          	addi	a0,a0,324 # 8002bcf8 <itable>
    80003bbc:	ffffd097          	auipc	ra,0xffffd
    80003bc0:	02e080e7          	jalr	46(ra) # 80000bea <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003bc4:	4498                	lw	a4,8(s1)
    80003bc6:	4785                	li	a5,1
    80003bc8:	02f70363          	beq	a4,a5,80003bee <iput+0x48>
  ip->ref--;
    80003bcc:	449c                	lw	a5,8(s1)
    80003bce:	37fd                	addiw	a5,a5,-1
    80003bd0:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003bd2:	00028517          	auipc	a0,0x28
    80003bd6:	12650513          	addi	a0,a0,294 # 8002bcf8 <itable>
    80003bda:	ffffd097          	auipc	ra,0xffffd
    80003bde:	0c4080e7          	jalr	196(ra) # 80000c9e <release>
}
    80003be2:	60e2                	ld	ra,24(sp)
    80003be4:	6442                	ld	s0,16(sp)
    80003be6:	64a2                	ld	s1,8(sp)
    80003be8:	6902                	ld	s2,0(sp)
    80003bea:	6105                	addi	sp,sp,32
    80003bec:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003bee:	40bc                	lw	a5,64(s1)
    80003bf0:	dff1                	beqz	a5,80003bcc <iput+0x26>
    80003bf2:	04a49783          	lh	a5,74(s1)
    80003bf6:	fbf9                	bnez	a5,80003bcc <iput+0x26>
    acquiresleep(&ip->lock);
    80003bf8:	01048913          	addi	s2,s1,16
    80003bfc:	854a                	mv	a0,s2
    80003bfe:	00001097          	auipc	ra,0x1
    80003c02:	aa8080e7          	jalr	-1368(ra) # 800046a6 <acquiresleep>
    release(&itable.lock);
    80003c06:	00028517          	auipc	a0,0x28
    80003c0a:	0f250513          	addi	a0,a0,242 # 8002bcf8 <itable>
    80003c0e:	ffffd097          	auipc	ra,0xffffd
    80003c12:	090080e7          	jalr	144(ra) # 80000c9e <release>
    itrunc(ip);
    80003c16:	8526                	mv	a0,s1
    80003c18:	00000097          	auipc	ra,0x0
    80003c1c:	ee2080e7          	jalr	-286(ra) # 80003afa <itrunc>
    ip->type = 0;
    80003c20:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003c24:	8526                	mv	a0,s1
    80003c26:	00000097          	auipc	ra,0x0
    80003c2a:	cfc080e7          	jalr	-772(ra) # 80003922 <iupdate>
    ip->valid = 0;
    80003c2e:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003c32:	854a                	mv	a0,s2
    80003c34:	00001097          	auipc	ra,0x1
    80003c38:	ac8080e7          	jalr	-1336(ra) # 800046fc <releasesleep>
    acquire(&itable.lock);
    80003c3c:	00028517          	auipc	a0,0x28
    80003c40:	0bc50513          	addi	a0,a0,188 # 8002bcf8 <itable>
    80003c44:	ffffd097          	auipc	ra,0xffffd
    80003c48:	fa6080e7          	jalr	-90(ra) # 80000bea <acquire>
    80003c4c:	b741                	j	80003bcc <iput+0x26>

0000000080003c4e <iunlockput>:
{
    80003c4e:	1101                	addi	sp,sp,-32
    80003c50:	ec06                	sd	ra,24(sp)
    80003c52:	e822                	sd	s0,16(sp)
    80003c54:	e426                	sd	s1,8(sp)
    80003c56:	1000                	addi	s0,sp,32
    80003c58:	84aa                	mv	s1,a0
  iunlock(ip);
    80003c5a:	00000097          	auipc	ra,0x0
    80003c5e:	e54080e7          	jalr	-428(ra) # 80003aae <iunlock>
  iput(ip);
    80003c62:	8526                	mv	a0,s1
    80003c64:	00000097          	auipc	ra,0x0
    80003c68:	f42080e7          	jalr	-190(ra) # 80003ba6 <iput>
}
    80003c6c:	60e2                	ld	ra,24(sp)
    80003c6e:	6442                	ld	s0,16(sp)
    80003c70:	64a2                	ld	s1,8(sp)
    80003c72:	6105                	addi	sp,sp,32
    80003c74:	8082                	ret

0000000080003c76 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003c76:	1141                	addi	sp,sp,-16
    80003c78:	e422                	sd	s0,8(sp)
    80003c7a:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003c7c:	411c                	lw	a5,0(a0)
    80003c7e:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003c80:	415c                	lw	a5,4(a0)
    80003c82:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003c84:	04451783          	lh	a5,68(a0)
    80003c88:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003c8c:	04a51783          	lh	a5,74(a0)
    80003c90:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003c94:	04c56783          	lwu	a5,76(a0)
    80003c98:	e99c                	sd	a5,16(a1)
}
    80003c9a:	6422                	ld	s0,8(sp)
    80003c9c:	0141                	addi	sp,sp,16
    80003c9e:	8082                	ret

0000000080003ca0 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ca0:	457c                	lw	a5,76(a0)
    80003ca2:	0ed7e963          	bltu	a5,a3,80003d94 <readi+0xf4>
{
    80003ca6:	7159                	addi	sp,sp,-112
    80003ca8:	f486                	sd	ra,104(sp)
    80003caa:	f0a2                	sd	s0,96(sp)
    80003cac:	eca6                	sd	s1,88(sp)
    80003cae:	e8ca                	sd	s2,80(sp)
    80003cb0:	e4ce                	sd	s3,72(sp)
    80003cb2:	e0d2                	sd	s4,64(sp)
    80003cb4:	fc56                	sd	s5,56(sp)
    80003cb6:	f85a                	sd	s6,48(sp)
    80003cb8:	f45e                	sd	s7,40(sp)
    80003cba:	f062                	sd	s8,32(sp)
    80003cbc:	ec66                	sd	s9,24(sp)
    80003cbe:	e86a                	sd	s10,16(sp)
    80003cc0:	e46e                	sd	s11,8(sp)
    80003cc2:	1880                	addi	s0,sp,112
    80003cc4:	8b2a                	mv	s6,a0
    80003cc6:	8bae                	mv	s7,a1
    80003cc8:	8a32                	mv	s4,a2
    80003cca:	84b6                	mv	s1,a3
    80003ccc:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003cce:	9f35                	addw	a4,a4,a3
    return 0;
    80003cd0:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003cd2:	0ad76063          	bltu	a4,a3,80003d72 <readi+0xd2>
  if(off + n > ip->size)
    80003cd6:	00e7f463          	bgeu	a5,a4,80003cde <readi+0x3e>
    n = ip->size - off;
    80003cda:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003cde:	0a0a8963          	beqz	s5,80003d90 <readi+0xf0>
    80003ce2:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ce4:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003ce8:	5c7d                	li	s8,-1
    80003cea:	a82d                	j	80003d24 <readi+0x84>
    80003cec:	020d1d93          	slli	s11,s10,0x20
    80003cf0:	020ddd93          	srli	s11,s11,0x20
    80003cf4:	05890613          	addi	a2,s2,88
    80003cf8:	86ee                	mv	a3,s11
    80003cfa:	963a                	add	a2,a2,a4
    80003cfc:	85d2                	mv	a1,s4
    80003cfe:	855e                	mv	a0,s7
    80003d00:	fffff097          	auipc	ra,0xfffff
    80003d04:	810080e7          	jalr	-2032(ra) # 80002510 <either_copyout>
    80003d08:	05850d63          	beq	a0,s8,80003d62 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003d0c:	854a                	mv	a0,s2
    80003d0e:	fffff097          	auipc	ra,0xfffff
    80003d12:	5f4080e7          	jalr	1524(ra) # 80003302 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d16:	013d09bb          	addw	s3,s10,s3
    80003d1a:	009d04bb          	addw	s1,s10,s1
    80003d1e:	9a6e                	add	s4,s4,s11
    80003d20:	0559f763          	bgeu	s3,s5,80003d6e <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003d24:	00a4d59b          	srliw	a1,s1,0xa
    80003d28:	855a                	mv	a0,s6
    80003d2a:	00000097          	auipc	ra,0x0
    80003d2e:	8a2080e7          	jalr	-1886(ra) # 800035cc <bmap>
    80003d32:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003d36:	cd85                	beqz	a1,80003d6e <readi+0xce>
    bp = bread(ip->dev, addr);
    80003d38:	000b2503          	lw	a0,0(s6)
    80003d3c:	fffff097          	auipc	ra,0xfffff
    80003d40:	496080e7          	jalr	1174(ra) # 800031d2 <bread>
    80003d44:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d46:	3ff4f713          	andi	a4,s1,1023
    80003d4a:	40ec87bb          	subw	a5,s9,a4
    80003d4e:	413a86bb          	subw	a3,s5,s3
    80003d52:	8d3e                	mv	s10,a5
    80003d54:	2781                	sext.w	a5,a5
    80003d56:	0006861b          	sext.w	a2,a3
    80003d5a:	f8f679e3          	bgeu	a2,a5,80003cec <readi+0x4c>
    80003d5e:	8d36                	mv	s10,a3
    80003d60:	b771                	j	80003cec <readi+0x4c>
      brelse(bp);
    80003d62:	854a                	mv	a0,s2
    80003d64:	fffff097          	auipc	ra,0xfffff
    80003d68:	59e080e7          	jalr	1438(ra) # 80003302 <brelse>
      tot = -1;
    80003d6c:	59fd                	li	s3,-1
  }
  return tot;
    80003d6e:	0009851b          	sext.w	a0,s3
}
    80003d72:	70a6                	ld	ra,104(sp)
    80003d74:	7406                	ld	s0,96(sp)
    80003d76:	64e6                	ld	s1,88(sp)
    80003d78:	6946                	ld	s2,80(sp)
    80003d7a:	69a6                	ld	s3,72(sp)
    80003d7c:	6a06                	ld	s4,64(sp)
    80003d7e:	7ae2                	ld	s5,56(sp)
    80003d80:	7b42                	ld	s6,48(sp)
    80003d82:	7ba2                	ld	s7,40(sp)
    80003d84:	7c02                	ld	s8,32(sp)
    80003d86:	6ce2                	ld	s9,24(sp)
    80003d88:	6d42                	ld	s10,16(sp)
    80003d8a:	6da2                	ld	s11,8(sp)
    80003d8c:	6165                	addi	sp,sp,112
    80003d8e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d90:	89d6                	mv	s3,s5
    80003d92:	bff1                	j	80003d6e <readi+0xce>
    return 0;
    80003d94:	4501                	li	a0,0
}
    80003d96:	8082                	ret

0000000080003d98 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d98:	457c                	lw	a5,76(a0)
    80003d9a:	10d7e863          	bltu	a5,a3,80003eaa <writei+0x112>
{
    80003d9e:	7159                	addi	sp,sp,-112
    80003da0:	f486                	sd	ra,104(sp)
    80003da2:	f0a2                	sd	s0,96(sp)
    80003da4:	eca6                	sd	s1,88(sp)
    80003da6:	e8ca                	sd	s2,80(sp)
    80003da8:	e4ce                	sd	s3,72(sp)
    80003daa:	e0d2                	sd	s4,64(sp)
    80003dac:	fc56                	sd	s5,56(sp)
    80003dae:	f85a                	sd	s6,48(sp)
    80003db0:	f45e                	sd	s7,40(sp)
    80003db2:	f062                	sd	s8,32(sp)
    80003db4:	ec66                	sd	s9,24(sp)
    80003db6:	e86a                	sd	s10,16(sp)
    80003db8:	e46e                	sd	s11,8(sp)
    80003dba:	1880                	addi	s0,sp,112
    80003dbc:	8aaa                	mv	s5,a0
    80003dbe:	8bae                	mv	s7,a1
    80003dc0:	8a32                	mv	s4,a2
    80003dc2:	8936                	mv	s2,a3
    80003dc4:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003dc6:	00e687bb          	addw	a5,a3,a4
    80003dca:	0ed7e263          	bltu	a5,a3,80003eae <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003dce:	00043737          	lui	a4,0x43
    80003dd2:	0ef76063          	bltu	a4,a5,80003eb2 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003dd6:	0c0b0863          	beqz	s6,80003ea6 <writei+0x10e>
    80003dda:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ddc:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003de0:	5c7d                	li	s8,-1
    80003de2:	a091                	j	80003e26 <writei+0x8e>
    80003de4:	020d1d93          	slli	s11,s10,0x20
    80003de8:	020ddd93          	srli	s11,s11,0x20
    80003dec:	05848513          	addi	a0,s1,88
    80003df0:	86ee                	mv	a3,s11
    80003df2:	8652                	mv	a2,s4
    80003df4:	85de                	mv	a1,s7
    80003df6:	953a                	add	a0,a0,a4
    80003df8:	ffffe097          	auipc	ra,0xffffe
    80003dfc:	76e080e7          	jalr	1902(ra) # 80002566 <either_copyin>
    80003e00:	07850263          	beq	a0,s8,80003e64 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003e04:	8526                	mv	a0,s1
    80003e06:	00000097          	auipc	ra,0x0
    80003e0a:	780080e7          	jalr	1920(ra) # 80004586 <log_write>
    brelse(bp);
    80003e0e:	8526                	mv	a0,s1
    80003e10:	fffff097          	auipc	ra,0xfffff
    80003e14:	4f2080e7          	jalr	1266(ra) # 80003302 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e18:	013d09bb          	addw	s3,s10,s3
    80003e1c:	012d093b          	addw	s2,s10,s2
    80003e20:	9a6e                	add	s4,s4,s11
    80003e22:	0569f663          	bgeu	s3,s6,80003e6e <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003e26:	00a9559b          	srliw	a1,s2,0xa
    80003e2a:	8556                	mv	a0,s5
    80003e2c:	fffff097          	auipc	ra,0xfffff
    80003e30:	7a0080e7          	jalr	1952(ra) # 800035cc <bmap>
    80003e34:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003e38:	c99d                	beqz	a1,80003e6e <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003e3a:	000aa503          	lw	a0,0(s5)
    80003e3e:	fffff097          	auipc	ra,0xfffff
    80003e42:	394080e7          	jalr	916(ra) # 800031d2 <bread>
    80003e46:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e48:	3ff97713          	andi	a4,s2,1023
    80003e4c:	40ec87bb          	subw	a5,s9,a4
    80003e50:	413b06bb          	subw	a3,s6,s3
    80003e54:	8d3e                	mv	s10,a5
    80003e56:	2781                	sext.w	a5,a5
    80003e58:	0006861b          	sext.w	a2,a3
    80003e5c:	f8f674e3          	bgeu	a2,a5,80003de4 <writei+0x4c>
    80003e60:	8d36                	mv	s10,a3
    80003e62:	b749                	j	80003de4 <writei+0x4c>
      brelse(bp);
    80003e64:	8526                	mv	a0,s1
    80003e66:	fffff097          	auipc	ra,0xfffff
    80003e6a:	49c080e7          	jalr	1180(ra) # 80003302 <brelse>
  }

  if(off > ip->size)
    80003e6e:	04caa783          	lw	a5,76(s5)
    80003e72:	0127f463          	bgeu	a5,s2,80003e7a <writei+0xe2>
    ip->size = off;
    80003e76:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003e7a:	8556                	mv	a0,s5
    80003e7c:	00000097          	auipc	ra,0x0
    80003e80:	aa6080e7          	jalr	-1370(ra) # 80003922 <iupdate>

  return tot;
    80003e84:	0009851b          	sext.w	a0,s3
}
    80003e88:	70a6                	ld	ra,104(sp)
    80003e8a:	7406                	ld	s0,96(sp)
    80003e8c:	64e6                	ld	s1,88(sp)
    80003e8e:	6946                	ld	s2,80(sp)
    80003e90:	69a6                	ld	s3,72(sp)
    80003e92:	6a06                	ld	s4,64(sp)
    80003e94:	7ae2                	ld	s5,56(sp)
    80003e96:	7b42                	ld	s6,48(sp)
    80003e98:	7ba2                	ld	s7,40(sp)
    80003e9a:	7c02                	ld	s8,32(sp)
    80003e9c:	6ce2                	ld	s9,24(sp)
    80003e9e:	6d42                	ld	s10,16(sp)
    80003ea0:	6da2                	ld	s11,8(sp)
    80003ea2:	6165                	addi	sp,sp,112
    80003ea4:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ea6:	89da                	mv	s3,s6
    80003ea8:	bfc9                	j	80003e7a <writei+0xe2>
    return -1;
    80003eaa:	557d                	li	a0,-1
}
    80003eac:	8082                	ret
    return -1;
    80003eae:	557d                	li	a0,-1
    80003eb0:	bfe1                	j	80003e88 <writei+0xf0>
    return -1;
    80003eb2:	557d                	li	a0,-1
    80003eb4:	bfd1                	j	80003e88 <writei+0xf0>

0000000080003eb6 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003eb6:	1141                	addi	sp,sp,-16
    80003eb8:	e406                	sd	ra,8(sp)
    80003eba:	e022                	sd	s0,0(sp)
    80003ebc:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003ebe:	4639                	li	a2,14
    80003ec0:	ffffd097          	auipc	ra,0xffffd
    80003ec4:	efe080e7          	jalr	-258(ra) # 80000dbe <strncmp>
}
    80003ec8:	60a2                	ld	ra,8(sp)
    80003eca:	6402                	ld	s0,0(sp)
    80003ecc:	0141                	addi	sp,sp,16
    80003ece:	8082                	ret

0000000080003ed0 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003ed0:	7139                	addi	sp,sp,-64
    80003ed2:	fc06                	sd	ra,56(sp)
    80003ed4:	f822                	sd	s0,48(sp)
    80003ed6:	f426                	sd	s1,40(sp)
    80003ed8:	f04a                	sd	s2,32(sp)
    80003eda:	ec4e                	sd	s3,24(sp)
    80003edc:	e852                	sd	s4,16(sp)
    80003ede:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003ee0:	04451703          	lh	a4,68(a0)
    80003ee4:	4785                	li	a5,1
    80003ee6:	00f71a63          	bne	a4,a5,80003efa <dirlookup+0x2a>
    80003eea:	892a                	mv	s2,a0
    80003eec:	89ae                	mv	s3,a1
    80003eee:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ef0:	457c                	lw	a5,76(a0)
    80003ef2:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003ef4:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ef6:	e79d                	bnez	a5,80003f24 <dirlookup+0x54>
    80003ef8:	a8a5                	j	80003f70 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003efa:	00004517          	auipc	a0,0x4
    80003efe:	7b650513          	addi	a0,a0,1974 # 800086b0 <syscalls+0x1b0>
    80003f02:	ffffc097          	auipc	ra,0xffffc
    80003f06:	642080e7          	jalr	1602(ra) # 80000544 <panic>
      panic("dirlookup read");
    80003f0a:	00004517          	auipc	a0,0x4
    80003f0e:	7be50513          	addi	a0,a0,1982 # 800086c8 <syscalls+0x1c8>
    80003f12:	ffffc097          	auipc	ra,0xffffc
    80003f16:	632080e7          	jalr	1586(ra) # 80000544 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f1a:	24c1                	addiw	s1,s1,16
    80003f1c:	04c92783          	lw	a5,76(s2)
    80003f20:	04f4f763          	bgeu	s1,a5,80003f6e <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f24:	4741                	li	a4,16
    80003f26:	86a6                	mv	a3,s1
    80003f28:	fc040613          	addi	a2,s0,-64
    80003f2c:	4581                	li	a1,0
    80003f2e:	854a                	mv	a0,s2
    80003f30:	00000097          	auipc	ra,0x0
    80003f34:	d70080e7          	jalr	-656(ra) # 80003ca0 <readi>
    80003f38:	47c1                	li	a5,16
    80003f3a:	fcf518e3          	bne	a0,a5,80003f0a <dirlookup+0x3a>
    if(de.inum == 0)
    80003f3e:	fc045783          	lhu	a5,-64(s0)
    80003f42:	dfe1                	beqz	a5,80003f1a <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003f44:	fc240593          	addi	a1,s0,-62
    80003f48:	854e                	mv	a0,s3
    80003f4a:	00000097          	auipc	ra,0x0
    80003f4e:	f6c080e7          	jalr	-148(ra) # 80003eb6 <namecmp>
    80003f52:	f561                	bnez	a0,80003f1a <dirlookup+0x4a>
      if(poff)
    80003f54:	000a0463          	beqz	s4,80003f5c <dirlookup+0x8c>
        *poff = off;
    80003f58:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003f5c:	fc045583          	lhu	a1,-64(s0)
    80003f60:	00092503          	lw	a0,0(s2)
    80003f64:	fffff097          	auipc	ra,0xfffff
    80003f68:	750080e7          	jalr	1872(ra) # 800036b4 <iget>
    80003f6c:	a011                	j	80003f70 <dirlookup+0xa0>
  return 0;
    80003f6e:	4501                	li	a0,0
}
    80003f70:	70e2                	ld	ra,56(sp)
    80003f72:	7442                	ld	s0,48(sp)
    80003f74:	74a2                	ld	s1,40(sp)
    80003f76:	7902                	ld	s2,32(sp)
    80003f78:	69e2                	ld	s3,24(sp)
    80003f7a:	6a42                	ld	s4,16(sp)
    80003f7c:	6121                	addi	sp,sp,64
    80003f7e:	8082                	ret

0000000080003f80 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003f80:	711d                	addi	sp,sp,-96
    80003f82:	ec86                	sd	ra,88(sp)
    80003f84:	e8a2                	sd	s0,80(sp)
    80003f86:	e4a6                	sd	s1,72(sp)
    80003f88:	e0ca                	sd	s2,64(sp)
    80003f8a:	fc4e                	sd	s3,56(sp)
    80003f8c:	f852                	sd	s4,48(sp)
    80003f8e:	f456                	sd	s5,40(sp)
    80003f90:	f05a                	sd	s6,32(sp)
    80003f92:	ec5e                	sd	s7,24(sp)
    80003f94:	e862                	sd	s8,16(sp)
    80003f96:	e466                	sd	s9,8(sp)
    80003f98:	1080                	addi	s0,sp,96
    80003f9a:	84aa                	mv	s1,a0
    80003f9c:	8b2e                	mv	s6,a1
    80003f9e:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003fa0:	00054703          	lbu	a4,0(a0)
    80003fa4:	02f00793          	li	a5,47
    80003fa8:	02f70363          	beq	a4,a5,80003fce <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003fac:	ffffe097          	auipc	ra,0xffffe
    80003fb0:	a1a080e7          	jalr	-1510(ra) # 800019c6 <myproc>
    80003fb4:	15053503          	ld	a0,336(a0)
    80003fb8:	00000097          	auipc	ra,0x0
    80003fbc:	9f6080e7          	jalr	-1546(ra) # 800039ae <idup>
    80003fc0:	89aa                	mv	s3,a0
  while(*path == '/')
    80003fc2:	02f00913          	li	s2,47
  len = path - s;
    80003fc6:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003fc8:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003fca:	4c05                	li	s8,1
    80003fcc:	a865                	j	80004084 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003fce:	4585                	li	a1,1
    80003fd0:	4505                	li	a0,1
    80003fd2:	fffff097          	auipc	ra,0xfffff
    80003fd6:	6e2080e7          	jalr	1762(ra) # 800036b4 <iget>
    80003fda:	89aa                	mv	s3,a0
    80003fdc:	b7dd                	j	80003fc2 <namex+0x42>
      iunlockput(ip);
    80003fde:	854e                	mv	a0,s3
    80003fe0:	00000097          	auipc	ra,0x0
    80003fe4:	c6e080e7          	jalr	-914(ra) # 80003c4e <iunlockput>
      return 0;
    80003fe8:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003fea:	854e                	mv	a0,s3
    80003fec:	60e6                	ld	ra,88(sp)
    80003fee:	6446                	ld	s0,80(sp)
    80003ff0:	64a6                	ld	s1,72(sp)
    80003ff2:	6906                	ld	s2,64(sp)
    80003ff4:	79e2                	ld	s3,56(sp)
    80003ff6:	7a42                	ld	s4,48(sp)
    80003ff8:	7aa2                	ld	s5,40(sp)
    80003ffa:	7b02                	ld	s6,32(sp)
    80003ffc:	6be2                	ld	s7,24(sp)
    80003ffe:	6c42                	ld	s8,16(sp)
    80004000:	6ca2                	ld	s9,8(sp)
    80004002:	6125                	addi	sp,sp,96
    80004004:	8082                	ret
      iunlock(ip);
    80004006:	854e                	mv	a0,s3
    80004008:	00000097          	auipc	ra,0x0
    8000400c:	aa6080e7          	jalr	-1370(ra) # 80003aae <iunlock>
      return ip;
    80004010:	bfe9                	j	80003fea <namex+0x6a>
      iunlockput(ip);
    80004012:	854e                	mv	a0,s3
    80004014:	00000097          	auipc	ra,0x0
    80004018:	c3a080e7          	jalr	-966(ra) # 80003c4e <iunlockput>
      return 0;
    8000401c:	89d2                	mv	s3,s4
    8000401e:	b7f1                	j	80003fea <namex+0x6a>
  len = path - s;
    80004020:	40b48633          	sub	a2,s1,a1
    80004024:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80004028:	094cd463          	bge	s9,s4,800040b0 <namex+0x130>
    memmove(name, s, DIRSIZ);
    8000402c:	4639                	li	a2,14
    8000402e:	8556                	mv	a0,s5
    80004030:	ffffd097          	auipc	ra,0xffffd
    80004034:	d16080e7          	jalr	-746(ra) # 80000d46 <memmove>
  while(*path == '/')
    80004038:	0004c783          	lbu	a5,0(s1)
    8000403c:	01279763          	bne	a5,s2,8000404a <namex+0xca>
    path++;
    80004040:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004042:	0004c783          	lbu	a5,0(s1)
    80004046:	ff278de3          	beq	a5,s2,80004040 <namex+0xc0>
    ilock(ip);
    8000404a:	854e                	mv	a0,s3
    8000404c:	00000097          	auipc	ra,0x0
    80004050:	9a0080e7          	jalr	-1632(ra) # 800039ec <ilock>
    if(ip->type != T_DIR){
    80004054:	04499783          	lh	a5,68(s3)
    80004058:	f98793e3          	bne	a5,s8,80003fde <namex+0x5e>
    if(nameiparent && *path == '\0'){
    8000405c:	000b0563          	beqz	s6,80004066 <namex+0xe6>
    80004060:	0004c783          	lbu	a5,0(s1)
    80004064:	d3cd                	beqz	a5,80004006 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004066:	865e                	mv	a2,s7
    80004068:	85d6                	mv	a1,s5
    8000406a:	854e                	mv	a0,s3
    8000406c:	00000097          	auipc	ra,0x0
    80004070:	e64080e7          	jalr	-412(ra) # 80003ed0 <dirlookup>
    80004074:	8a2a                	mv	s4,a0
    80004076:	dd51                	beqz	a0,80004012 <namex+0x92>
    iunlockput(ip);
    80004078:	854e                	mv	a0,s3
    8000407a:	00000097          	auipc	ra,0x0
    8000407e:	bd4080e7          	jalr	-1068(ra) # 80003c4e <iunlockput>
    ip = next;
    80004082:	89d2                	mv	s3,s4
  while(*path == '/')
    80004084:	0004c783          	lbu	a5,0(s1)
    80004088:	05279763          	bne	a5,s2,800040d6 <namex+0x156>
    path++;
    8000408c:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000408e:	0004c783          	lbu	a5,0(s1)
    80004092:	ff278de3          	beq	a5,s2,8000408c <namex+0x10c>
  if(*path == 0)
    80004096:	c79d                	beqz	a5,800040c4 <namex+0x144>
    path++;
    80004098:	85a6                	mv	a1,s1
  len = path - s;
    8000409a:	8a5e                	mv	s4,s7
    8000409c:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    8000409e:	01278963          	beq	a5,s2,800040b0 <namex+0x130>
    800040a2:	dfbd                	beqz	a5,80004020 <namex+0xa0>
    path++;
    800040a4:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800040a6:	0004c783          	lbu	a5,0(s1)
    800040aa:	ff279ce3          	bne	a5,s2,800040a2 <namex+0x122>
    800040ae:	bf8d                	j	80004020 <namex+0xa0>
    memmove(name, s, len);
    800040b0:	2601                	sext.w	a2,a2
    800040b2:	8556                	mv	a0,s5
    800040b4:	ffffd097          	auipc	ra,0xffffd
    800040b8:	c92080e7          	jalr	-878(ra) # 80000d46 <memmove>
    name[len] = 0;
    800040bc:	9a56                	add	s4,s4,s5
    800040be:	000a0023          	sb	zero,0(s4)
    800040c2:	bf9d                	j	80004038 <namex+0xb8>
  if(nameiparent){
    800040c4:	f20b03e3          	beqz	s6,80003fea <namex+0x6a>
    iput(ip);
    800040c8:	854e                	mv	a0,s3
    800040ca:	00000097          	auipc	ra,0x0
    800040ce:	adc080e7          	jalr	-1316(ra) # 80003ba6 <iput>
    return 0;
    800040d2:	4981                	li	s3,0
    800040d4:	bf19                	j	80003fea <namex+0x6a>
  if(*path == 0)
    800040d6:	d7fd                	beqz	a5,800040c4 <namex+0x144>
  while(*path != '/' && *path != 0)
    800040d8:	0004c783          	lbu	a5,0(s1)
    800040dc:	85a6                	mv	a1,s1
    800040de:	b7d1                	j	800040a2 <namex+0x122>

00000000800040e0 <dirlink>:
{
    800040e0:	7139                	addi	sp,sp,-64
    800040e2:	fc06                	sd	ra,56(sp)
    800040e4:	f822                	sd	s0,48(sp)
    800040e6:	f426                	sd	s1,40(sp)
    800040e8:	f04a                	sd	s2,32(sp)
    800040ea:	ec4e                	sd	s3,24(sp)
    800040ec:	e852                	sd	s4,16(sp)
    800040ee:	0080                	addi	s0,sp,64
    800040f0:	892a                	mv	s2,a0
    800040f2:	8a2e                	mv	s4,a1
    800040f4:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800040f6:	4601                	li	a2,0
    800040f8:	00000097          	auipc	ra,0x0
    800040fc:	dd8080e7          	jalr	-552(ra) # 80003ed0 <dirlookup>
    80004100:	e93d                	bnez	a0,80004176 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004102:	04c92483          	lw	s1,76(s2)
    80004106:	c49d                	beqz	s1,80004134 <dirlink+0x54>
    80004108:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000410a:	4741                	li	a4,16
    8000410c:	86a6                	mv	a3,s1
    8000410e:	fc040613          	addi	a2,s0,-64
    80004112:	4581                	li	a1,0
    80004114:	854a                	mv	a0,s2
    80004116:	00000097          	auipc	ra,0x0
    8000411a:	b8a080e7          	jalr	-1142(ra) # 80003ca0 <readi>
    8000411e:	47c1                	li	a5,16
    80004120:	06f51163          	bne	a0,a5,80004182 <dirlink+0xa2>
    if(de.inum == 0)
    80004124:	fc045783          	lhu	a5,-64(s0)
    80004128:	c791                	beqz	a5,80004134 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000412a:	24c1                	addiw	s1,s1,16
    8000412c:	04c92783          	lw	a5,76(s2)
    80004130:	fcf4ede3          	bltu	s1,a5,8000410a <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004134:	4639                	li	a2,14
    80004136:	85d2                	mv	a1,s4
    80004138:	fc240513          	addi	a0,s0,-62
    8000413c:	ffffd097          	auipc	ra,0xffffd
    80004140:	cbe080e7          	jalr	-834(ra) # 80000dfa <strncpy>
  de.inum = inum;
    80004144:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004148:	4741                	li	a4,16
    8000414a:	86a6                	mv	a3,s1
    8000414c:	fc040613          	addi	a2,s0,-64
    80004150:	4581                	li	a1,0
    80004152:	854a                	mv	a0,s2
    80004154:	00000097          	auipc	ra,0x0
    80004158:	c44080e7          	jalr	-956(ra) # 80003d98 <writei>
    8000415c:	1541                	addi	a0,a0,-16
    8000415e:	00a03533          	snez	a0,a0
    80004162:	40a00533          	neg	a0,a0
}
    80004166:	70e2                	ld	ra,56(sp)
    80004168:	7442                	ld	s0,48(sp)
    8000416a:	74a2                	ld	s1,40(sp)
    8000416c:	7902                	ld	s2,32(sp)
    8000416e:	69e2                	ld	s3,24(sp)
    80004170:	6a42                	ld	s4,16(sp)
    80004172:	6121                	addi	sp,sp,64
    80004174:	8082                	ret
    iput(ip);
    80004176:	00000097          	auipc	ra,0x0
    8000417a:	a30080e7          	jalr	-1488(ra) # 80003ba6 <iput>
    return -1;
    8000417e:	557d                	li	a0,-1
    80004180:	b7dd                	j	80004166 <dirlink+0x86>
      panic("dirlink read");
    80004182:	00004517          	auipc	a0,0x4
    80004186:	55650513          	addi	a0,a0,1366 # 800086d8 <syscalls+0x1d8>
    8000418a:	ffffc097          	auipc	ra,0xffffc
    8000418e:	3ba080e7          	jalr	954(ra) # 80000544 <panic>

0000000080004192 <namei>:

struct inode*
namei(char *path)
{
    80004192:	1101                	addi	sp,sp,-32
    80004194:	ec06                	sd	ra,24(sp)
    80004196:	e822                	sd	s0,16(sp)
    80004198:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000419a:	fe040613          	addi	a2,s0,-32
    8000419e:	4581                	li	a1,0
    800041a0:	00000097          	auipc	ra,0x0
    800041a4:	de0080e7          	jalr	-544(ra) # 80003f80 <namex>
}
    800041a8:	60e2                	ld	ra,24(sp)
    800041aa:	6442                	ld	s0,16(sp)
    800041ac:	6105                	addi	sp,sp,32
    800041ae:	8082                	ret

00000000800041b0 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800041b0:	1141                	addi	sp,sp,-16
    800041b2:	e406                	sd	ra,8(sp)
    800041b4:	e022                	sd	s0,0(sp)
    800041b6:	0800                	addi	s0,sp,16
    800041b8:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800041ba:	4585                	li	a1,1
    800041bc:	00000097          	auipc	ra,0x0
    800041c0:	dc4080e7          	jalr	-572(ra) # 80003f80 <namex>
}
    800041c4:	60a2                	ld	ra,8(sp)
    800041c6:	6402                	ld	s0,0(sp)
    800041c8:	0141                	addi	sp,sp,16
    800041ca:	8082                	ret

00000000800041cc <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800041cc:	1101                	addi	sp,sp,-32
    800041ce:	ec06                	sd	ra,24(sp)
    800041d0:	e822                	sd	s0,16(sp)
    800041d2:	e426                	sd	s1,8(sp)
    800041d4:	e04a                	sd	s2,0(sp)
    800041d6:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800041d8:	00029917          	auipc	s2,0x29
    800041dc:	5c890913          	addi	s2,s2,1480 # 8002d7a0 <log>
    800041e0:	01892583          	lw	a1,24(s2)
    800041e4:	02892503          	lw	a0,40(s2)
    800041e8:	fffff097          	auipc	ra,0xfffff
    800041ec:	fea080e7          	jalr	-22(ra) # 800031d2 <bread>
    800041f0:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800041f2:	02c92683          	lw	a3,44(s2)
    800041f6:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800041f8:	02d05763          	blez	a3,80004226 <write_head+0x5a>
    800041fc:	00029797          	auipc	a5,0x29
    80004200:	5d478793          	addi	a5,a5,1492 # 8002d7d0 <log+0x30>
    80004204:	05c50713          	addi	a4,a0,92
    80004208:	36fd                	addiw	a3,a3,-1
    8000420a:	1682                	slli	a3,a3,0x20
    8000420c:	9281                	srli	a3,a3,0x20
    8000420e:	068a                	slli	a3,a3,0x2
    80004210:	00029617          	auipc	a2,0x29
    80004214:	5c460613          	addi	a2,a2,1476 # 8002d7d4 <log+0x34>
    80004218:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000421a:	4390                	lw	a2,0(a5)
    8000421c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000421e:	0791                	addi	a5,a5,4
    80004220:	0711                	addi	a4,a4,4
    80004222:	fed79ce3          	bne	a5,a3,8000421a <write_head+0x4e>
  }
  bwrite(buf);
    80004226:	8526                	mv	a0,s1
    80004228:	fffff097          	auipc	ra,0xfffff
    8000422c:	09c080e7          	jalr	156(ra) # 800032c4 <bwrite>
  brelse(buf);
    80004230:	8526                	mv	a0,s1
    80004232:	fffff097          	auipc	ra,0xfffff
    80004236:	0d0080e7          	jalr	208(ra) # 80003302 <brelse>
}
    8000423a:	60e2                	ld	ra,24(sp)
    8000423c:	6442                	ld	s0,16(sp)
    8000423e:	64a2                	ld	s1,8(sp)
    80004240:	6902                	ld	s2,0(sp)
    80004242:	6105                	addi	sp,sp,32
    80004244:	8082                	ret

0000000080004246 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004246:	00029797          	auipc	a5,0x29
    8000424a:	5867a783          	lw	a5,1414(a5) # 8002d7cc <log+0x2c>
    8000424e:	0af05d63          	blez	a5,80004308 <install_trans+0xc2>
{
    80004252:	7139                	addi	sp,sp,-64
    80004254:	fc06                	sd	ra,56(sp)
    80004256:	f822                	sd	s0,48(sp)
    80004258:	f426                	sd	s1,40(sp)
    8000425a:	f04a                	sd	s2,32(sp)
    8000425c:	ec4e                	sd	s3,24(sp)
    8000425e:	e852                	sd	s4,16(sp)
    80004260:	e456                	sd	s5,8(sp)
    80004262:	e05a                	sd	s6,0(sp)
    80004264:	0080                	addi	s0,sp,64
    80004266:	8b2a                	mv	s6,a0
    80004268:	00029a97          	auipc	s5,0x29
    8000426c:	568a8a93          	addi	s5,s5,1384 # 8002d7d0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004270:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004272:	00029997          	auipc	s3,0x29
    80004276:	52e98993          	addi	s3,s3,1326 # 8002d7a0 <log>
    8000427a:	a035                	j	800042a6 <install_trans+0x60>
      bunpin(dbuf);
    8000427c:	8526                	mv	a0,s1
    8000427e:	fffff097          	auipc	ra,0xfffff
    80004282:	15e080e7          	jalr	350(ra) # 800033dc <bunpin>
    brelse(lbuf);
    80004286:	854a                	mv	a0,s2
    80004288:	fffff097          	auipc	ra,0xfffff
    8000428c:	07a080e7          	jalr	122(ra) # 80003302 <brelse>
    brelse(dbuf);
    80004290:	8526                	mv	a0,s1
    80004292:	fffff097          	auipc	ra,0xfffff
    80004296:	070080e7          	jalr	112(ra) # 80003302 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000429a:	2a05                	addiw	s4,s4,1
    8000429c:	0a91                	addi	s5,s5,4
    8000429e:	02c9a783          	lw	a5,44(s3)
    800042a2:	04fa5963          	bge	s4,a5,800042f4 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800042a6:	0189a583          	lw	a1,24(s3)
    800042aa:	014585bb          	addw	a1,a1,s4
    800042ae:	2585                	addiw	a1,a1,1
    800042b0:	0289a503          	lw	a0,40(s3)
    800042b4:	fffff097          	auipc	ra,0xfffff
    800042b8:	f1e080e7          	jalr	-226(ra) # 800031d2 <bread>
    800042bc:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800042be:	000aa583          	lw	a1,0(s5)
    800042c2:	0289a503          	lw	a0,40(s3)
    800042c6:	fffff097          	auipc	ra,0xfffff
    800042ca:	f0c080e7          	jalr	-244(ra) # 800031d2 <bread>
    800042ce:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800042d0:	40000613          	li	a2,1024
    800042d4:	05890593          	addi	a1,s2,88
    800042d8:	05850513          	addi	a0,a0,88
    800042dc:	ffffd097          	auipc	ra,0xffffd
    800042e0:	a6a080e7          	jalr	-1430(ra) # 80000d46 <memmove>
    bwrite(dbuf);  // write dst to disk
    800042e4:	8526                	mv	a0,s1
    800042e6:	fffff097          	auipc	ra,0xfffff
    800042ea:	fde080e7          	jalr	-34(ra) # 800032c4 <bwrite>
    if(recovering == 0)
    800042ee:	f80b1ce3          	bnez	s6,80004286 <install_trans+0x40>
    800042f2:	b769                	j	8000427c <install_trans+0x36>
}
    800042f4:	70e2                	ld	ra,56(sp)
    800042f6:	7442                	ld	s0,48(sp)
    800042f8:	74a2                	ld	s1,40(sp)
    800042fa:	7902                	ld	s2,32(sp)
    800042fc:	69e2                	ld	s3,24(sp)
    800042fe:	6a42                	ld	s4,16(sp)
    80004300:	6aa2                	ld	s5,8(sp)
    80004302:	6b02                	ld	s6,0(sp)
    80004304:	6121                	addi	sp,sp,64
    80004306:	8082                	ret
    80004308:	8082                	ret

000000008000430a <initlog>:
{
    8000430a:	7179                	addi	sp,sp,-48
    8000430c:	f406                	sd	ra,40(sp)
    8000430e:	f022                	sd	s0,32(sp)
    80004310:	ec26                	sd	s1,24(sp)
    80004312:	e84a                	sd	s2,16(sp)
    80004314:	e44e                	sd	s3,8(sp)
    80004316:	1800                	addi	s0,sp,48
    80004318:	892a                	mv	s2,a0
    8000431a:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000431c:	00029497          	auipc	s1,0x29
    80004320:	48448493          	addi	s1,s1,1156 # 8002d7a0 <log>
    80004324:	00004597          	auipc	a1,0x4
    80004328:	3c458593          	addi	a1,a1,964 # 800086e8 <syscalls+0x1e8>
    8000432c:	8526                	mv	a0,s1
    8000432e:	ffffd097          	auipc	ra,0xffffd
    80004332:	82c080e7          	jalr	-2004(ra) # 80000b5a <initlock>
  log.start = sb->logstart;
    80004336:	0149a583          	lw	a1,20(s3)
    8000433a:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000433c:	0109a783          	lw	a5,16(s3)
    80004340:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004342:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004346:	854a                	mv	a0,s2
    80004348:	fffff097          	auipc	ra,0xfffff
    8000434c:	e8a080e7          	jalr	-374(ra) # 800031d2 <bread>
  log.lh.n = lh->n;
    80004350:	4d3c                	lw	a5,88(a0)
    80004352:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004354:	02f05563          	blez	a5,8000437e <initlog+0x74>
    80004358:	05c50713          	addi	a4,a0,92
    8000435c:	00029697          	auipc	a3,0x29
    80004360:	47468693          	addi	a3,a3,1140 # 8002d7d0 <log+0x30>
    80004364:	37fd                	addiw	a5,a5,-1
    80004366:	1782                	slli	a5,a5,0x20
    80004368:	9381                	srli	a5,a5,0x20
    8000436a:	078a                	slli	a5,a5,0x2
    8000436c:	06050613          	addi	a2,a0,96
    80004370:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004372:	4310                	lw	a2,0(a4)
    80004374:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004376:	0711                	addi	a4,a4,4
    80004378:	0691                	addi	a3,a3,4
    8000437a:	fef71ce3          	bne	a4,a5,80004372 <initlog+0x68>
  brelse(buf);
    8000437e:	fffff097          	auipc	ra,0xfffff
    80004382:	f84080e7          	jalr	-124(ra) # 80003302 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004386:	4505                	li	a0,1
    80004388:	00000097          	auipc	ra,0x0
    8000438c:	ebe080e7          	jalr	-322(ra) # 80004246 <install_trans>
  log.lh.n = 0;
    80004390:	00029797          	auipc	a5,0x29
    80004394:	4207ae23          	sw	zero,1084(a5) # 8002d7cc <log+0x2c>
  write_head(); // clear the log
    80004398:	00000097          	auipc	ra,0x0
    8000439c:	e34080e7          	jalr	-460(ra) # 800041cc <write_head>
}
    800043a0:	70a2                	ld	ra,40(sp)
    800043a2:	7402                	ld	s0,32(sp)
    800043a4:	64e2                	ld	s1,24(sp)
    800043a6:	6942                	ld	s2,16(sp)
    800043a8:	69a2                	ld	s3,8(sp)
    800043aa:	6145                	addi	sp,sp,48
    800043ac:	8082                	ret

00000000800043ae <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800043ae:	1101                	addi	sp,sp,-32
    800043b0:	ec06                	sd	ra,24(sp)
    800043b2:	e822                	sd	s0,16(sp)
    800043b4:	e426                	sd	s1,8(sp)
    800043b6:	e04a                	sd	s2,0(sp)
    800043b8:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800043ba:	00029517          	auipc	a0,0x29
    800043be:	3e650513          	addi	a0,a0,998 # 8002d7a0 <log>
    800043c2:	ffffd097          	auipc	ra,0xffffd
    800043c6:	828080e7          	jalr	-2008(ra) # 80000bea <acquire>
  while(1){
    if(log.committing){
    800043ca:	00029497          	auipc	s1,0x29
    800043ce:	3d648493          	addi	s1,s1,982 # 8002d7a0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800043d2:	4979                	li	s2,30
    800043d4:	a039                	j	800043e2 <begin_op+0x34>
      sleep(&log, &log.lock);
    800043d6:	85a6                	mv	a1,s1
    800043d8:	8526                	mv	a0,s1
    800043da:	ffffe097          	auipc	ra,0xffffe
    800043de:	d2e080e7          	jalr	-722(ra) # 80002108 <sleep>
    if(log.committing){
    800043e2:	50dc                	lw	a5,36(s1)
    800043e4:	fbed                	bnez	a5,800043d6 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800043e6:	509c                	lw	a5,32(s1)
    800043e8:	0017871b          	addiw	a4,a5,1
    800043ec:	0007069b          	sext.w	a3,a4
    800043f0:	0027179b          	slliw	a5,a4,0x2
    800043f4:	9fb9                	addw	a5,a5,a4
    800043f6:	0017979b          	slliw	a5,a5,0x1
    800043fa:	54d8                	lw	a4,44(s1)
    800043fc:	9fb9                	addw	a5,a5,a4
    800043fe:	00f95963          	bge	s2,a5,80004410 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004402:	85a6                	mv	a1,s1
    80004404:	8526                	mv	a0,s1
    80004406:	ffffe097          	auipc	ra,0xffffe
    8000440a:	d02080e7          	jalr	-766(ra) # 80002108 <sleep>
    8000440e:	bfd1                	j	800043e2 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004410:	00029517          	auipc	a0,0x29
    80004414:	39050513          	addi	a0,a0,912 # 8002d7a0 <log>
    80004418:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000441a:	ffffd097          	auipc	ra,0xffffd
    8000441e:	884080e7          	jalr	-1916(ra) # 80000c9e <release>
      break;
    }
  }
}
    80004422:	60e2                	ld	ra,24(sp)
    80004424:	6442                	ld	s0,16(sp)
    80004426:	64a2                	ld	s1,8(sp)
    80004428:	6902                	ld	s2,0(sp)
    8000442a:	6105                	addi	sp,sp,32
    8000442c:	8082                	ret

000000008000442e <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000442e:	7139                	addi	sp,sp,-64
    80004430:	fc06                	sd	ra,56(sp)
    80004432:	f822                	sd	s0,48(sp)
    80004434:	f426                	sd	s1,40(sp)
    80004436:	f04a                	sd	s2,32(sp)
    80004438:	ec4e                	sd	s3,24(sp)
    8000443a:	e852                	sd	s4,16(sp)
    8000443c:	e456                	sd	s5,8(sp)
    8000443e:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004440:	00029497          	auipc	s1,0x29
    80004444:	36048493          	addi	s1,s1,864 # 8002d7a0 <log>
    80004448:	8526                	mv	a0,s1
    8000444a:	ffffc097          	auipc	ra,0xffffc
    8000444e:	7a0080e7          	jalr	1952(ra) # 80000bea <acquire>
  log.outstanding -= 1;
    80004452:	509c                	lw	a5,32(s1)
    80004454:	37fd                	addiw	a5,a5,-1
    80004456:	0007891b          	sext.w	s2,a5
    8000445a:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000445c:	50dc                	lw	a5,36(s1)
    8000445e:	efb9                	bnez	a5,800044bc <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004460:	06091663          	bnez	s2,800044cc <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004464:	00029497          	auipc	s1,0x29
    80004468:	33c48493          	addi	s1,s1,828 # 8002d7a0 <log>
    8000446c:	4785                	li	a5,1
    8000446e:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004470:	8526                	mv	a0,s1
    80004472:	ffffd097          	auipc	ra,0xffffd
    80004476:	82c080e7          	jalr	-2004(ra) # 80000c9e <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000447a:	54dc                	lw	a5,44(s1)
    8000447c:	06f04763          	bgtz	a5,800044ea <end_op+0xbc>
    acquire(&log.lock);
    80004480:	00029497          	auipc	s1,0x29
    80004484:	32048493          	addi	s1,s1,800 # 8002d7a0 <log>
    80004488:	8526                	mv	a0,s1
    8000448a:	ffffc097          	auipc	ra,0xffffc
    8000448e:	760080e7          	jalr	1888(ra) # 80000bea <acquire>
    log.committing = 0;
    80004492:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004496:	8526                	mv	a0,s1
    80004498:	ffffe097          	auipc	ra,0xffffe
    8000449c:	cd4080e7          	jalr	-812(ra) # 8000216c <wakeup>
    release(&log.lock);
    800044a0:	8526                	mv	a0,s1
    800044a2:	ffffc097          	auipc	ra,0xffffc
    800044a6:	7fc080e7          	jalr	2044(ra) # 80000c9e <release>
}
    800044aa:	70e2                	ld	ra,56(sp)
    800044ac:	7442                	ld	s0,48(sp)
    800044ae:	74a2                	ld	s1,40(sp)
    800044b0:	7902                	ld	s2,32(sp)
    800044b2:	69e2                	ld	s3,24(sp)
    800044b4:	6a42                	ld	s4,16(sp)
    800044b6:	6aa2                	ld	s5,8(sp)
    800044b8:	6121                	addi	sp,sp,64
    800044ba:	8082                	ret
    panic("log.committing");
    800044bc:	00004517          	auipc	a0,0x4
    800044c0:	23450513          	addi	a0,a0,564 # 800086f0 <syscalls+0x1f0>
    800044c4:	ffffc097          	auipc	ra,0xffffc
    800044c8:	080080e7          	jalr	128(ra) # 80000544 <panic>
    wakeup(&log);
    800044cc:	00029497          	auipc	s1,0x29
    800044d0:	2d448493          	addi	s1,s1,724 # 8002d7a0 <log>
    800044d4:	8526                	mv	a0,s1
    800044d6:	ffffe097          	auipc	ra,0xffffe
    800044da:	c96080e7          	jalr	-874(ra) # 8000216c <wakeup>
  release(&log.lock);
    800044de:	8526                	mv	a0,s1
    800044e0:	ffffc097          	auipc	ra,0xffffc
    800044e4:	7be080e7          	jalr	1982(ra) # 80000c9e <release>
  if(do_commit){
    800044e8:	b7c9                	j	800044aa <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044ea:	00029a97          	auipc	s5,0x29
    800044ee:	2e6a8a93          	addi	s5,s5,742 # 8002d7d0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800044f2:	00029a17          	auipc	s4,0x29
    800044f6:	2aea0a13          	addi	s4,s4,686 # 8002d7a0 <log>
    800044fa:	018a2583          	lw	a1,24(s4)
    800044fe:	012585bb          	addw	a1,a1,s2
    80004502:	2585                	addiw	a1,a1,1
    80004504:	028a2503          	lw	a0,40(s4)
    80004508:	fffff097          	auipc	ra,0xfffff
    8000450c:	cca080e7          	jalr	-822(ra) # 800031d2 <bread>
    80004510:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004512:	000aa583          	lw	a1,0(s5)
    80004516:	028a2503          	lw	a0,40(s4)
    8000451a:	fffff097          	auipc	ra,0xfffff
    8000451e:	cb8080e7          	jalr	-840(ra) # 800031d2 <bread>
    80004522:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004524:	40000613          	li	a2,1024
    80004528:	05850593          	addi	a1,a0,88
    8000452c:	05848513          	addi	a0,s1,88
    80004530:	ffffd097          	auipc	ra,0xffffd
    80004534:	816080e7          	jalr	-2026(ra) # 80000d46 <memmove>
    bwrite(to);  // write the log
    80004538:	8526                	mv	a0,s1
    8000453a:	fffff097          	auipc	ra,0xfffff
    8000453e:	d8a080e7          	jalr	-630(ra) # 800032c4 <bwrite>
    brelse(from);
    80004542:	854e                	mv	a0,s3
    80004544:	fffff097          	auipc	ra,0xfffff
    80004548:	dbe080e7          	jalr	-578(ra) # 80003302 <brelse>
    brelse(to);
    8000454c:	8526                	mv	a0,s1
    8000454e:	fffff097          	auipc	ra,0xfffff
    80004552:	db4080e7          	jalr	-588(ra) # 80003302 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004556:	2905                	addiw	s2,s2,1
    80004558:	0a91                	addi	s5,s5,4
    8000455a:	02ca2783          	lw	a5,44(s4)
    8000455e:	f8f94ee3          	blt	s2,a5,800044fa <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004562:	00000097          	auipc	ra,0x0
    80004566:	c6a080e7          	jalr	-918(ra) # 800041cc <write_head>
    install_trans(0); // Now install writes to home locations
    8000456a:	4501                	li	a0,0
    8000456c:	00000097          	auipc	ra,0x0
    80004570:	cda080e7          	jalr	-806(ra) # 80004246 <install_trans>
    log.lh.n = 0;
    80004574:	00029797          	auipc	a5,0x29
    80004578:	2407ac23          	sw	zero,600(a5) # 8002d7cc <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000457c:	00000097          	auipc	ra,0x0
    80004580:	c50080e7          	jalr	-944(ra) # 800041cc <write_head>
    80004584:	bdf5                	j	80004480 <end_op+0x52>

0000000080004586 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004586:	1101                	addi	sp,sp,-32
    80004588:	ec06                	sd	ra,24(sp)
    8000458a:	e822                	sd	s0,16(sp)
    8000458c:	e426                	sd	s1,8(sp)
    8000458e:	e04a                	sd	s2,0(sp)
    80004590:	1000                	addi	s0,sp,32
    80004592:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004594:	00029917          	auipc	s2,0x29
    80004598:	20c90913          	addi	s2,s2,524 # 8002d7a0 <log>
    8000459c:	854a                	mv	a0,s2
    8000459e:	ffffc097          	auipc	ra,0xffffc
    800045a2:	64c080e7          	jalr	1612(ra) # 80000bea <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800045a6:	02c92603          	lw	a2,44(s2)
    800045aa:	47f5                	li	a5,29
    800045ac:	06c7c563          	blt	a5,a2,80004616 <log_write+0x90>
    800045b0:	00029797          	auipc	a5,0x29
    800045b4:	20c7a783          	lw	a5,524(a5) # 8002d7bc <log+0x1c>
    800045b8:	37fd                	addiw	a5,a5,-1
    800045ba:	04f65e63          	bge	a2,a5,80004616 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800045be:	00029797          	auipc	a5,0x29
    800045c2:	2027a783          	lw	a5,514(a5) # 8002d7c0 <log+0x20>
    800045c6:	06f05063          	blez	a5,80004626 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800045ca:	4781                	li	a5,0
    800045cc:	06c05563          	blez	a2,80004636 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800045d0:	44cc                	lw	a1,12(s1)
    800045d2:	00029717          	auipc	a4,0x29
    800045d6:	1fe70713          	addi	a4,a4,510 # 8002d7d0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800045da:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800045dc:	4314                	lw	a3,0(a4)
    800045de:	04b68c63          	beq	a3,a1,80004636 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800045e2:	2785                	addiw	a5,a5,1
    800045e4:	0711                	addi	a4,a4,4
    800045e6:	fef61be3          	bne	a2,a5,800045dc <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800045ea:	0621                	addi	a2,a2,8
    800045ec:	060a                	slli	a2,a2,0x2
    800045ee:	00029797          	auipc	a5,0x29
    800045f2:	1b278793          	addi	a5,a5,434 # 8002d7a0 <log>
    800045f6:	963e                	add	a2,a2,a5
    800045f8:	44dc                	lw	a5,12(s1)
    800045fa:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800045fc:	8526                	mv	a0,s1
    800045fe:	fffff097          	auipc	ra,0xfffff
    80004602:	da2080e7          	jalr	-606(ra) # 800033a0 <bpin>
    log.lh.n++;
    80004606:	00029717          	auipc	a4,0x29
    8000460a:	19a70713          	addi	a4,a4,410 # 8002d7a0 <log>
    8000460e:	575c                	lw	a5,44(a4)
    80004610:	2785                	addiw	a5,a5,1
    80004612:	d75c                	sw	a5,44(a4)
    80004614:	a835                	j	80004650 <log_write+0xca>
    panic("too big a transaction");
    80004616:	00004517          	auipc	a0,0x4
    8000461a:	0ea50513          	addi	a0,a0,234 # 80008700 <syscalls+0x200>
    8000461e:	ffffc097          	auipc	ra,0xffffc
    80004622:	f26080e7          	jalr	-218(ra) # 80000544 <panic>
    panic("log_write outside of trans");
    80004626:	00004517          	auipc	a0,0x4
    8000462a:	0f250513          	addi	a0,a0,242 # 80008718 <syscalls+0x218>
    8000462e:	ffffc097          	auipc	ra,0xffffc
    80004632:	f16080e7          	jalr	-234(ra) # 80000544 <panic>
  log.lh.block[i] = b->blockno;
    80004636:	00878713          	addi	a4,a5,8
    8000463a:	00271693          	slli	a3,a4,0x2
    8000463e:	00029717          	auipc	a4,0x29
    80004642:	16270713          	addi	a4,a4,354 # 8002d7a0 <log>
    80004646:	9736                	add	a4,a4,a3
    80004648:	44d4                	lw	a3,12(s1)
    8000464a:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000464c:	faf608e3          	beq	a2,a5,800045fc <log_write+0x76>
  }
  release(&log.lock);
    80004650:	00029517          	auipc	a0,0x29
    80004654:	15050513          	addi	a0,a0,336 # 8002d7a0 <log>
    80004658:	ffffc097          	auipc	ra,0xffffc
    8000465c:	646080e7          	jalr	1606(ra) # 80000c9e <release>
}
    80004660:	60e2                	ld	ra,24(sp)
    80004662:	6442                	ld	s0,16(sp)
    80004664:	64a2                	ld	s1,8(sp)
    80004666:	6902                	ld	s2,0(sp)
    80004668:	6105                	addi	sp,sp,32
    8000466a:	8082                	ret

000000008000466c <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000466c:	1101                	addi	sp,sp,-32
    8000466e:	ec06                	sd	ra,24(sp)
    80004670:	e822                	sd	s0,16(sp)
    80004672:	e426                	sd	s1,8(sp)
    80004674:	e04a                	sd	s2,0(sp)
    80004676:	1000                	addi	s0,sp,32
    80004678:	84aa                	mv	s1,a0
    8000467a:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000467c:	00004597          	auipc	a1,0x4
    80004680:	0bc58593          	addi	a1,a1,188 # 80008738 <syscalls+0x238>
    80004684:	0521                	addi	a0,a0,8
    80004686:	ffffc097          	auipc	ra,0xffffc
    8000468a:	4d4080e7          	jalr	1236(ra) # 80000b5a <initlock>
  lk->name = name;
    8000468e:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004692:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004696:	0204a423          	sw	zero,40(s1)
}
    8000469a:	60e2                	ld	ra,24(sp)
    8000469c:	6442                	ld	s0,16(sp)
    8000469e:	64a2                	ld	s1,8(sp)
    800046a0:	6902                	ld	s2,0(sp)
    800046a2:	6105                	addi	sp,sp,32
    800046a4:	8082                	ret

00000000800046a6 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800046a6:	1101                	addi	sp,sp,-32
    800046a8:	ec06                	sd	ra,24(sp)
    800046aa:	e822                	sd	s0,16(sp)
    800046ac:	e426                	sd	s1,8(sp)
    800046ae:	e04a                	sd	s2,0(sp)
    800046b0:	1000                	addi	s0,sp,32
    800046b2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800046b4:	00850913          	addi	s2,a0,8
    800046b8:	854a                	mv	a0,s2
    800046ba:	ffffc097          	auipc	ra,0xffffc
    800046be:	530080e7          	jalr	1328(ra) # 80000bea <acquire>
  while (lk->locked) {
    800046c2:	409c                	lw	a5,0(s1)
    800046c4:	cb89                	beqz	a5,800046d6 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800046c6:	85ca                	mv	a1,s2
    800046c8:	8526                	mv	a0,s1
    800046ca:	ffffe097          	auipc	ra,0xffffe
    800046ce:	a3e080e7          	jalr	-1474(ra) # 80002108 <sleep>
  while (lk->locked) {
    800046d2:	409c                	lw	a5,0(s1)
    800046d4:	fbed                	bnez	a5,800046c6 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800046d6:	4785                	li	a5,1
    800046d8:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800046da:	ffffd097          	auipc	ra,0xffffd
    800046de:	2ec080e7          	jalr	748(ra) # 800019c6 <myproc>
    800046e2:	591c                	lw	a5,48(a0)
    800046e4:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800046e6:	854a                	mv	a0,s2
    800046e8:	ffffc097          	auipc	ra,0xffffc
    800046ec:	5b6080e7          	jalr	1462(ra) # 80000c9e <release>
}
    800046f0:	60e2                	ld	ra,24(sp)
    800046f2:	6442                	ld	s0,16(sp)
    800046f4:	64a2                	ld	s1,8(sp)
    800046f6:	6902                	ld	s2,0(sp)
    800046f8:	6105                	addi	sp,sp,32
    800046fa:	8082                	ret

00000000800046fc <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800046fc:	1101                	addi	sp,sp,-32
    800046fe:	ec06                	sd	ra,24(sp)
    80004700:	e822                	sd	s0,16(sp)
    80004702:	e426                	sd	s1,8(sp)
    80004704:	e04a                	sd	s2,0(sp)
    80004706:	1000                	addi	s0,sp,32
    80004708:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000470a:	00850913          	addi	s2,a0,8
    8000470e:	854a                	mv	a0,s2
    80004710:	ffffc097          	auipc	ra,0xffffc
    80004714:	4da080e7          	jalr	1242(ra) # 80000bea <acquire>
  lk->locked = 0;
    80004718:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000471c:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004720:	8526                	mv	a0,s1
    80004722:	ffffe097          	auipc	ra,0xffffe
    80004726:	a4a080e7          	jalr	-1462(ra) # 8000216c <wakeup>
  release(&lk->lk);
    8000472a:	854a                	mv	a0,s2
    8000472c:	ffffc097          	auipc	ra,0xffffc
    80004730:	572080e7          	jalr	1394(ra) # 80000c9e <release>
}
    80004734:	60e2                	ld	ra,24(sp)
    80004736:	6442                	ld	s0,16(sp)
    80004738:	64a2                	ld	s1,8(sp)
    8000473a:	6902                	ld	s2,0(sp)
    8000473c:	6105                	addi	sp,sp,32
    8000473e:	8082                	ret

0000000080004740 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004740:	7179                	addi	sp,sp,-48
    80004742:	f406                	sd	ra,40(sp)
    80004744:	f022                	sd	s0,32(sp)
    80004746:	ec26                	sd	s1,24(sp)
    80004748:	e84a                	sd	s2,16(sp)
    8000474a:	e44e                	sd	s3,8(sp)
    8000474c:	1800                	addi	s0,sp,48
    8000474e:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004750:	00850913          	addi	s2,a0,8
    80004754:	854a                	mv	a0,s2
    80004756:	ffffc097          	auipc	ra,0xffffc
    8000475a:	494080e7          	jalr	1172(ra) # 80000bea <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000475e:	409c                	lw	a5,0(s1)
    80004760:	ef99                	bnez	a5,8000477e <holdingsleep+0x3e>
    80004762:	4481                	li	s1,0
  release(&lk->lk);
    80004764:	854a                	mv	a0,s2
    80004766:	ffffc097          	auipc	ra,0xffffc
    8000476a:	538080e7          	jalr	1336(ra) # 80000c9e <release>
  return r;
}
    8000476e:	8526                	mv	a0,s1
    80004770:	70a2                	ld	ra,40(sp)
    80004772:	7402                	ld	s0,32(sp)
    80004774:	64e2                	ld	s1,24(sp)
    80004776:	6942                	ld	s2,16(sp)
    80004778:	69a2                	ld	s3,8(sp)
    8000477a:	6145                	addi	sp,sp,48
    8000477c:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000477e:	0284a983          	lw	s3,40(s1)
    80004782:	ffffd097          	auipc	ra,0xffffd
    80004786:	244080e7          	jalr	580(ra) # 800019c6 <myproc>
    8000478a:	5904                	lw	s1,48(a0)
    8000478c:	413484b3          	sub	s1,s1,s3
    80004790:	0014b493          	seqz	s1,s1
    80004794:	bfc1                	j	80004764 <holdingsleep+0x24>

0000000080004796 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004796:	1141                	addi	sp,sp,-16
    80004798:	e406                	sd	ra,8(sp)
    8000479a:	e022                	sd	s0,0(sp)
    8000479c:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000479e:	00004597          	auipc	a1,0x4
    800047a2:	faa58593          	addi	a1,a1,-86 # 80008748 <syscalls+0x248>
    800047a6:	00029517          	auipc	a0,0x29
    800047aa:	14250513          	addi	a0,a0,322 # 8002d8e8 <ftable>
    800047ae:	ffffc097          	auipc	ra,0xffffc
    800047b2:	3ac080e7          	jalr	940(ra) # 80000b5a <initlock>
}
    800047b6:	60a2                	ld	ra,8(sp)
    800047b8:	6402                	ld	s0,0(sp)
    800047ba:	0141                	addi	sp,sp,16
    800047bc:	8082                	ret

00000000800047be <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800047be:	1101                	addi	sp,sp,-32
    800047c0:	ec06                	sd	ra,24(sp)
    800047c2:	e822                	sd	s0,16(sp)
    800047c4:	e426                	sd	s1,8(sp)
    800047c6:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800047c8:	00029517          	auipc	a0,0x29
    800047cc:	12050513          	addi	a0,a0,288 # 8002d8e8 <ftable>
    800047d0:	ffffc097          	auipc	ra,0xffffc
    800047d4:	41a080e7          	jalr	1050(ra) # 80000bea <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800047d8:	00029497          	auipc	s1,0x29
    800047dc:	12848493          	addi	s1,s1,296 # 8002d900 <ftable+0x18>
    800047e0:	0002a717          	auipc	a4,0x2a
    800047e4:	0c070713          	addi	a4,a4,192 # 8002e8a0 <disk>
    if(f->ref == 0){
    800047e8:	40dc                	lw	a5,4(s1)
    800047ea:	cf99                	beqz	a5,80004808 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800047ec:	02848493          	addi	s1,s1,40
    800047f0:	fee49ce3          	bne	s1,a4,800047e8 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800047f4:	00029517          	auipc	a0,0x29
    800047f8:	0f450513          	addi	a0,a0,244 # 8002d8e8 <ftable>
    800047fc:	ffffc097          	auipc	ra,0xffffc
    80004800:	4a2080e7          	jalr	1186(ra) # 80000c9e <release>
  return 0;
    80004804:	4481                	li	s1,0
    80004806:	a819                	j	8000481c <filealloc+0x5e>
      f->ref = 1;
    80004808:	4785                	li	a5,1
    8000480a:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000480c:	00029517          	auipc	a0,0x29
    80004810:	0dc50513          	addi	a0,a0,220 # 8002d8e8 <ftable>
    80004814:	ffffc097          	auipc	ra,0xffffc
    80004818:	48a080e7          	jalr	1162(ra) # 80000c9e <release>
}
    8000481c:	8526                	mv	a0,s1
    8000481e:	60e2                	ld	ra,24(sp)
    80004820:	6442                	ld	s0,16(sp)
    80004822:	64a2                	ld	s1,8(sp)
    80004824:	6105                	addi	sp,sp,32
    80004826:	8082                	ret

0000000080004828 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004828:	1101                	addi	sp,sp,-32
    8000482a:	ec06                	sd	ra,24(sp)
    8000482c:	e822                	sd	s0,16(sp)
    8000482e:	e426                	sd	s1,8(sp)
    80004830:	1000                	addi	s0,sp,32
    80004832:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004834:	00029517          	auipc	a0,0x29
    80004838:	0b450513          	addi	a0,a0,180 # 8002d8e8 <ftable>
    8000483c:	ffffc097          	auipc	ra,0xffffc
    80004840:	3ae080e7          	jalr	942(ra) # 80000bea <acquire>
  if(f->ref < 1)
    80004844:	40dc                	lw	a5,4(s1)
    80004846:	02f05263          	blez	a5,8000486a <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000484a:	2785                	addiw	a5,a5,1
    8000484c:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000484e:	00029517          	auipc	a0,0x29
    80004852:	09a50513          	addi	a0,a0,154 # 8002d8e8 <ftable>
    80004856:	ffffc097          	auipc	ra,0xffffc
    8000485a:	448080e7          	jalr	1096(ra) # 80000c9e <release>
  return f;
}
    8000485e:	8526                	mv	a0,s1
    80004860:	60e2                	ld	ra,24(sp)
    80004862:	6442                	ld	s0,16(sp)
    80004864:	64a2                	ld	s1,8(sp)
    80004866:	6105                	addi	sp,sp,32
    80004868:	8082                	ret
    panic("filedup");
    8000486a:	00004517          	auipc	a0,0x4
    8000486e:	ee650513          	addi	a0,a0,-282 # 80008750 <syscalls+0x250>
    80004872:	ffffc097          	auipc	ra,0xffffc
    80004876:	cd2080e7          	jalr	-814(ra) # 80000544 <panic>

000000008000487a <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000487a:	7139                	addi	sp,sp,-64
    8000487c:	fc06                	sd	ra,56(sp)
    8000487e:	f822                	sd	s0,48(sp)
    80004880:	f426                	sd	s1,40(sp)
    80004882:	f04a                	sd	s2,32(sp)
    80004884:	ec4e                	sd	s3,24(sp)
    80004886:	e852                	sd	s4,16(sp)
    80004888:	e456                	sd	s5,8(sp)
    8000488a:	0080                	addi	s0,sp,64
    8000488c:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000488e:	00029517          	auipc	a0,0x29
    80004892:	05a50513          	addi	a0,a0,90 # 8002d8e8 <ftable>
    80004896:	ffffc097          	auipc	ra,0xffffc
    8000489a:	354080e7          	jalr	852(ra) # 80000bea <acquire>
  if(f->ref < 1)
    8000489e:	40dc                	lw	a5,4(s1)
    800048a0:	06f05163          	blez	a5,80004902 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800048a4:	37fd                	addiw	a5,a5,-1
    800048a6:	0007871b          	sext.w	a4,a5
    800048aa:	c0dc                	sw	a5,4(s1)
    800048ac:	06e04363          	bgtz	a4,80004912 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800048b0:	0004a903          	lw	s2,0(s1)
    800048b4:	0094ca83          	lbu	s5,9(s1)
    800048b8:	0104ba03          	ld	s4,16(s1)
    800048bc:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800048c0:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800048c4:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800048c8:	00029517          	auipc	a0,0x29
    800048cc:	02050513          	addi	a0,a0,32 # 8002d8e8 <ftable>
    800048d0:	ffffc097          	auipc	ra,0xffffc
    800048d4:	3ce080e7          	jalr	974(ra) # 80000c9e <release>

  if(ff.type == FD_PIPE){
    800048d8:	4785                	li	a5,1
    800048da:	04f90d63          	beq	s2,a5,80004934 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800048de:	3979                	addiw	s2,s2,-2
    800048e0:	4785                	li	a5,1
    800048e2:	0527e063          	bltu	a5,s2,80004922 <fileclose+0xa8>
    begin_op();
    800048e6:	00000097          	auipc	ra,0x0
    800048ea:	ac8080e7          	jalr	-1336(ra) # 800043ae <begin_op>
    iput(ff.ip);
    800048ee:	854e                	mv	a0,s3
    800048f0:	fffff097          	auipc	ra,0xfffff
    800048f4:	2b6080e7          	jalr	694(ra) # 80003ba6 <iput>
    end_op();
    800048f8:	00000097          	auipc	ra,0x0
    800048fc:	b36080e7          	jalr	-1226(ra) # 8000442e <end_op>
    80004900:	a00d                	j	80004922 <fileclose+0xa8>
    panic("fileclose");
    80004902:	00004517          	auipc	a0,0x4
    80004906:	e5650513          	addi	a0,a0,-426 # 80008758 <syscalls+0x258>
    8000490a:	ffffc097          	auipc	ra,0xffffc
    8000490e:	c3a080e7          	jalr	-966(ra) # 80000544 <panic>
    release(&ftable.lock);
    80004912:	00029517          	auipc	a0,0x29
    80004916:	fd650513          	addi	a0,a0,-42 # 8002d8e8 <ftable>
    8000491a:	ffffc097          	auipc	ra,0xffffc
    8000491e:	384080e7          	jalr	900(ra) # 80000c9e <release>
  }
}
    80004922:	70e2                	ld	ra,56(sp)
    80004924:	7442                	ld	s0,48(sp)
    80004926:	74a2                	ld	s1,40(sp)
    80004928:	7902                	ld	s2,32(sp)
    8000492a:	69e2                	ld	s3,24(sp)
    8000492c:	6a42                	ld	s4,16(sp)
    8000492e:	6aa2                	ld	s5,8(sp)
    80004930:	6121                	addi	sp,sp,64
    80004932:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004934:	85d6                	mv	a1,s5
    80004936:	8552                	mv	a0,s4
    80004938:	00000097          	auipc	ra,0x0
    8000493c:	34c080e7          	jalr	844(ra) # 80004c84 <pipeclose>
    80004940:	b7cd                	j	80004922 <fileclose+0xa8>

0000000080004942 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004942:	715d                	addi	sp,sp,-80
    80004944:	e486                	sd	ra,72(sp)
    80004946:	e0a2                	sd	s0,64(sp)
    80004948:	fc26                	sd	s1,56(sp)
    8000494a:	f84a                	sd	s2,48(sp)
    8000494c:	f44e                	sd	s3,40(sp)
    8000494e:	0880                	addi	s0,sp,80
    80004950:	84aa                	mv	s1,a0
    80004952:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004954:	ffffd097          	auipc	ra,0xffffd
    80004958:	072080e7          	jalr	114(ra) # 800019c6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000495c:	409c                	lw	a5,0(s1)
    8000495e:	37f9                	addiw	a5,a5,-2
    80004960:	4705                	li	a4,1
    80004962:	04f76763          	bltu	a4,a5,800049b0 <filestat+0x6e>
    80004966:	892a                	mv	s2,a0
    ilock(f->ip);
    80004968:	6c88                	ld	a0,24(s1)
    8000496a:	fffff097          	auipc	ra,0xfffff
    8000496e:	082080e7          	jalr	130(ra) # 800039ec <ilock>
    stati(f->ip, &st);
    80004972:	fb840593          	addi	a1,s0,-72
    80004976:	6c88                	ld	a0,24(s1)
    80004978:	fffff097          	auipc	ra,0xfffff
    8000497c:	2fe080e7          	jalr	766(ra) # 80003c76 <stati>
    iunlock(f->ip);
    80004980:	6c88                	ld	a0,24(s1)
    80004982:	fffff097          	auipc	ra,0xfffff
    80004986:	12c080e7          	jalr	300(ra) # 80003aae <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000498a:	46e1                	li	a3,24
    8000498c:	fb840613          	addi	a2,s0,-72
    80004990:	85ce                	mv	a1,s3
    80004992:	05093503          	ld	a0,80(s2)
    80004996:	ffffd097          	auipc	ra,0xffffd
    8000499a:	cee080e7          	jalr	-786(ra) # 80001684 <copyout>
    8000499e:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800049a2:	60a6                	ld	ra,72(sp)
    800049a4:	6406                	ld	s0,64(sp)
    800049a6:	74e2                	ld	s1,56(sp)
    800049a8:	7942                	ld	s2,48(sp)
    800049aa:	79a2                	ld	s3,40(sp)
    800049ac:	6161                	addi	sp,sp,80
    800049ae:	8082                	ret
  return -1;
    800049b0:	557d                	li	a0,-1
    800049b2:	bfc5                	j	800049a2 <filestat+0x60>

00000000800049b4 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800049b4:	7179                	addi	sp,sp,-48
    800049b6:	f406                	sd	ra,40(sp)
    800049b8:	f022                	sd	s0,32(sp)
    800049ba:	ec26                	sd	s1,24(sp)
    800049bc:	e84a                	sd	s2,16(sp)
    800049be:	e44e                	sd	s3,8(sp)
    800049c0:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800049c2:	00854783          	lbu	a5,8(a0)
    800049c6:	c3d5                	beqz	a5,80004a6a <fileread+0xb6>
    800049c8:	84aa                	mv	s1,a0
    800049ca:	89ae                	mv	s3,a1
    800049cc:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800049ce:	411c                	lw	a5,0(a0)
    800049d0:	4705                	li	a4,1
    800049d2:	04e78963          	beq	a5,a4,80004a24 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800049d6:	470d                	li	a4,3
    800049d8:	04e78d63          	beq	a5,a4,80004a32 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800049dc:	4709                	li	a4,2
    800049de:	06e79e63          	bne	a5,a4,80004a5a <fileread+0xa6>
    ilock(f->ip);
    800049e2:	6d08                	ld	a0,24(a0)
    800049e4:	fffff097          	auipc	ra,0xfffff
    800049e8:	008080e7          	jalr	8(ra) # 800039ec <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800049ec:	874a                	mv	a4,s2
    800049ee:	5094                	lw	a3,32(s1)
    800049f0:	864e                	mv	a2,s3
    800049f2:	4585                	li	a1,1
    800049f4:	6c88                	ld	a0,24(s1)
    800049f6:	fffff097          	auipc	ra,0xfffff
    800049fa:	2aa080e7          	jalr	682(ra) # 80003ca0 <readi>
    800049fe:	892a                	mv	s2,a0
    80004a00:	00a05563          	blez	a0,80004a0a <fileread+0x56>
      f->off += r;
    80004a04:	509c                	lw	a5,32(s1)
    80004a06:	9fa9                	addw	a5,a5,a0
    80004a08:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004a0a:	6c88                	ld	a0,24(s1)
    80004a0c:	fffff097          	auipc	ra,0xfffff
    80004a10:	0a2080e7          	jalr	162(ra) # 80003aae <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004a14:	854a                	mv	a0,s2
    80004a16:	70a2                	ld	ra,40(sp)
    80004a18:	7402                	ld	s0,32(sp)
    80004a1a:	64e2                	ld	s1,24(sp)
    80004a1c:	6942                	ld	s2,16(sp)
    80004a1e:	69a2                	ld	s3,8(sp)
    80004a20:	6145                	addi	sp,sp,48
    80004a22:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004a24:	6908                	ld	a0,16(a0)
    80004a26:	00000097          	auipc	ra,0x0
    80004a2a:	3ce080e7          	jalr	974(ra) # 80004df4 <piperead>
    80004a2e:	892a                	mv	s2,a0
    80004a30:	b7d5                	j	80004a14 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004a32:	02451783          	lh	a5,36(a0)
    80004a36:	03079693          	slli	a3,a5,0x30
    80004a3a:	92c1                	srli	a3,a3,0x30
    80004a3c:	4725                	li	a4,9
    80004a3e:	02d76863          	bltu	a4,a3,80004a6e <fileread+0xba>
    80004a42:	0792                	slli	a5,a5,0x4
    80004a44:	00029717          	auipc	a4,0x29
    80004a48:	e0470713          	addi	a4,a4,-508 # 8002d848 <devsw>
    80004a4c:	97ba                	add	a5,a5,a4
    80004a4e:	639c                	ld	a5,0(a5)
    80004a50:	c38d                	beqz	a5,80004a72 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004a52:	4505                	li	a0,1
    80004a54:	9782                	jalr	a5
    80004a56:	892a                	mv	s2,a0
    80004a58:	bf75                	j	80004a14 <fileread+0x60>
    panic("fileread");
    80004a5a:	00004517          	auipc	a0,0x4
    80004a5e:	d0e50513          	addi	a0,a0,-754 # 80008768 <syscalls+0x268>
    80004a62:	ffffc097          	auipc	ra,0xffffc
    80004a66:	ae2080e7          	jalr	-1310(ra) # 80000544 <panic>
    return -1;
    80004a6a:	597d                	li	s2,-1
    80004a6c:	b765                	j	80004a14 <fileread+0x60>
      return -1;
    80004a6e:	597d                	li	s2,-1
    80004a70:	b755                	j	80004a14 <fileread+0x60>
    80004a72:	597d                	li	s2,-1
    80004a74:	b745                	j	80004a14 <fileread+0x60>

0000000080004a76 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004a76:	715d                	addi	sp,sp,-80
    80004a78:	e486                	sd	ra,72(sp)
    80004a7a:	e0a2                	sd	s0,64(sp)
    80004a7c:	fc26                	sd	s1,56(sp)
    80004a7e:	f84a                	sd	s2,48(sp)
    80004a80:	f44e                	sd	s3,40(sp)
    80004a82:	f052                	sd	s4,32(sp)
    80004a84:	ec56                	sd	s5,24(sp)
    80004a86:	e85a                	sd	s6,16(sp)
    80004a88:	e45e                	sd	s7,8(sp)
    80004a8a:	e062                	sd	s8,0(sp)
    80004a8c:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004a8e:	00954783          	lbu	a5,9(a0)
    80004a92:	10078663          	beqz	a5,80004b9e <filewrite+0x128>
    80004a96:	892a                	mv	s2,a0
    80004a98:	8aae                	mv	s5,a1
    80004a9a:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a9c:	411c                	lw	a5,0(a0)
    80004a9e:	4705                	li	a4,1
    80004aa0:	02e78263          	beq	a5,a4,80004ac4 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004aa4:	470d                	li	a4,3
    80004aa6:	02e78663          	beq	a5,a4,80004ad2 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004aaa:	4709                	li	a4,2
    80004aac:	0ee79163          	bne	a5,a4,80004b8e <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004ab0:	0ac05d63          	blez	a2,80004b6a <filewrite+0xf4>
    int i = 0;
    80004ab4:	4981                	li	s3,0
    80004ab6:	6b05                	lui	s6,0x1
    80004ab8:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004abc:	6b85                	lui	s7,0x1
    80004abe:	c00b8b9b          	addiw	s7,s7,-1024
    80004ac2:	a861                	j	80004b5a <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004ac4:	6908                	ld	a0,16(a0)
    80004ac6:	00000097          	auipc	ra,0x0
    80004aca:	22e080e7          	jalr	558(ra) # 80004cf4 <pipewrite>
    80004ace:	8a2a                	mv	s4,a0
    80004ad0:	a045                	j	80004b70 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004ad2:	02451783          	lh	a5,36(a0)
    80004ad6:	03079693          	slli	a3,a5,0x30
    80004ada:	92c1                	srli	a3,a3,0x30
    80004adc:	4725                	li	a4,9
    80004ade:	0cd76263          	bltu	a4,a3,80004ba2 <filewrite+0x12c>
    80004ae2:	0792                	slli	a5,a5,0x4
    80004ae4:	00029717          	auipc	a4,0x29
    80004ae8:	d6470713          	addi	a4,a4,-668 # 8002d848 <devsw>
    80004aec:	97ba                	add	a5,a5,a4
    80004aee:	679c                	ld	a5,8(a5)
    80004af0:	cbdd                	beqz	a5,80004ba6 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004af2:	4505                	li	a0,1
    80004af4:	9782                	jalr	a5
    80004af6:	8a2a                	mv	s4,a0
    80004af8:	a8a5                	j	80004b70 <filewrite+0xfa>
    80004afa:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004afe:	00000097          	auipc	ra,0x0
    80004b02:	8b0080e7          	jalr	-1872(ra) # 800043ae <begin_op>
      ilock(f->ip);
    80004b06:	01893503          	ld	a0,24(s2)
    80004b0a:	fffff097          	auipc	ra,0xfffff
    80004b0e:	ee2080e7          	jalr	-286(ra) # 800039ec <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004b12:	8762                	mv	a4,s8
    80004b14:	02092683          	lw	a3,32(s2)
    80004b18:	01598633          	add	a2,s3,s5
    80004b1c:	4585                	li	a1,1
    80004b1e:	01893503          	ld	a0,24(s2)
    80004b22:	fffff097          	auipc	ra,0xfffff
    80004b26:	276080e7          	jalr	630(ra) # 80003d98 <writei>
    80004b2a:	84aa                	mv	s1,a0
    80004b2c:	00a05763          	blez	a0,80004b3a <filewrite+0xc4>
        f->off += r;
    80004b30:	02092783          	lw	a5,32(s2)
    80004b34:	9fa9                	addw	a5,a5,a0
    80004b36:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004b3a:	01893503          	ld	a0,24(s2)
    80004b3e:	fffff097          	auipc	ra,0xfffff
    80004b42:	f70080e7          	jalr	-144(ra) # 80003aae <iunlock>
      end_op();
    80004b46:	00000097          	auipc	ra,0x0
    80004b4a:	8e8080e7          	jalr	-1816(ra) # 8000442e <end_op>

      if(r != n1){
    80004b4e:	009c1f63          	bne	s8,s1,80004b6c <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004b52:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004b56:	0149db63          	bge	s3,s4,80004b6c <filewrite+0xf6>
      int n1 = n - i;
    80004b5a:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004b5e:	84be                	mv	s1,a5
    80004b60:	2781                	sext.w	a5,a5
    80004b62:	f8fb5ce3          	bge	s6,a5,80004afa <filewrite+0x84>
    80004b66:	84de                	mv	s1,s7
    80004b68:	bf49                	j	80004afa <filewrite+0x84>
    int i = 0;
    80004b6a:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004b6c:	013a1f63          	bne	s4,s3,80004b8a <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004b70:	8552                	mv	a0,s4
    80004b72:	60a6                	ld	ra,72(sp)
    80004b74:	6406                	ld	s0,64(sp)
    80004b76:	74e2                	ld	s1,56(sp)
    80004b78:	7942                	ld	s2,48(sp)
    80004b7a:	79a2                	ld	s3,40(sp)
    80004b7c:	7a02                	ld	s4,32(sp)
    80004b7e:	6ae2                	ld	s5,24(sp)
    80004b80:	6b42                	ld	s6,16(sp)
    80004b82:	6ba2                	ld	s7,8(sp)
    80004b84:	6c02                	ld	s8,0(sp)
    80004b86:	6161                	addi	sp,sp,80
    80004b88:	8082                	ret
    ret = (i == n ? n : -1);
    80004b8a:	5a7d                	li	s4,-1
    80004b8c:	b7d5                	j	80004b70 <filewrite+0xfa>
    panic("filewrite");
    80004b8e:	00004517          	auipc	a0,0x4
    80004b92:	bea50513          	addi	a0,a0,-1046 # 80008778 <syscalls+0x278>
    80004b96:	ffffc097          	auipc	ra,0xffffc
    80004b9a:	9ae080e7          	jalr	-1618(ra) # 80000544 <panic>
    return -1;
    80004b9e:	5a7d                	li	s4,-1
    80004ba0:	bfc1                	j	80004b70 <filewrite+0xfa>
      return -1;
    80004ba2:	5a7d                	li	s4,-1
    80004ba4:	b7f1                	j	80004b70 <filewrite+0xfa>
    80004ba6:	5a7d                	li	s4,-1
    80004ba8:	b7e1                	j	80004b70 <filewrite+0xfa>

0000000080004baa <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004baa:	7179                	addi	sp,sp,-48
    80004bac:	f406                	sd	ra,40(sp)
    80004bae:	f022                	sd	s0,32(sp)
    80004bb0:	ec26                	sd	s1,24(sp)
    80004bb2:	e84a                	sd	s2,16(sp)
    80004bb4:	e44e                	sd	s3,8(sp)
    80004bb6:	e052                	sd	s4,0(sp)
    80004bb8:	1800                	addi	s0,sp,48
    80004bba:	84aa                	mv	s1,a0
    80004bbc:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004bbe:	0005b023          	sd	zero,0(a1)
    80004bc2:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004bc6:	00000097          	auipc	ra,0x0
    80004bca:	bf8080e7          	jalr	-1032(ra) # 800047be <filealloc>
    80004bce:	e088                	sd	a0,0(s1)
    80004bd0:	c551                	beqz	a0,80004c5c <pipealloc+0xb2>
    80004bd2:	00000097          	auipc	ra,0x0
    80004bd6:	bec080e7          	jalr	-1044(ra) # 800047be <filealloc>
    80004bda:	00aa3023          	sd	a0,0(s4)
    80004bde:	c92d                	beqz	a0,80004c50 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004be0:	ffffc097          	auipc	ra,0xffffc
    80004be4:	f1a080e7          	jalr	-230(ra) # 80000afa <kalloc>
    80004be8:	892a                	mv	s2,a0
    80004bea:	c125                	beqz	a0,80004c4a <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004bec:	4985                	li	s3,1
    80004bee:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004bf2:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004bf6:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004bfa:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004bfe:	00004597          	auipc	a1,0x4
    80004c02:	85a58593          	addi	a1,a1,-1958 # 80008458 <states.1761+0x190>
    80004c06:	ffffc097          	auipc	ra,0xffffc
    80004c0a:	f54080e7          	jalr	-172(ra) # 80000b5a <initlock>
  (*f0)->type = FD_PIPE;
    80004c0e:	609c                	ld	a5,0(s1)
    80004c10:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004c14:	609c                	ld	a5,0(s1)
    80004c16:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004c1a:	609c                	ld	a5,0(s1)
    80004c1c:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004c20:	609c                	ld	a5,0(s1)
    80004c22:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004c26:	000a3783          	ld	a5,0(s4)
    80004c2a:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004c2e:	000a3783          	ld	a5,0(s4)
    80004c32:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004c36:	000a3783          	ld	a5,0(s4)
    80004c3a:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004c3e:	000a3783          	ld	a5,0(s4)
    80004c42:	0127b823          	sd	s2,16(a5)
  return 0;
    80004c46:	4501                	li	a0,0
    80004c48:	a025                	j	80004c70 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004c4a:	6088                	ld	a0,0(s1)
    80004c4c:	e501                	bnez	a0,80004c54 <pipealloc+0xaa>
    80004c4e:	a039                	j	80004c5c <pipealloc+0xb2>
    80004c50:	6088                	ld	a0,0(s1)
    80004c52:	c51d                	beqz	a0,80004c80 <pipealloc+0xd6>
    fileclose(*f0);
    80004c54:	00000097          	auipc	ra,0x0
    80004c58:	c26080e7          	jalr	-986(ra) # 8000487a <fileclose>
  if(*f1)
    80004c5c:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004c60:	557d                	li	a0,-1
  if(*f1)
    80004c62:	c799                	beqz	a5,80004c70 <pipealloc+0xc6>
    fileclose(*f1);
    80004c64:	853e                	mv	a0,a5
    80004c66:	00000097          	auipc	ra,0x0
    80004c6a:	c14080e7          	jalr	-1004(ra) # 8000487a <fileclose>
  return -1;
    80004c6e:	557d                	li	a0,-1
}
    80004c70:	70a2                	ld	ra,40(sp)
    80004c72:	7402                	ld	s0,32(sp)
    80004c74:	64e2                	ld	s1,24(sp)
    80004c76:	6942                	ld	s2,16(sp)
    80004c78:	69a2                	ld	s3,8(sp)
    80004c7a:	6a02                	ld	s4,0(sp)
    80004c7c:	6145                	addi	sp,sp,48
    80004c7e:	8082                	ret
  return -1;
    80004c80:	557d                	li	a0,-1
    80004c82:	b7fd                	j	80004c70 <pipealloc+0xc6>

0000000080004c84 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004c84:	1101                	addi	sp,sp,-32
    80004c86:	ec06                	sd	ra,24(sp)
    80004c88:	e822                	sd	s0,16(sp)
    80004c8a:	e426                	sd	s1,8(sp)
    80004c8c:	e04a                	sd	s2,0(sp)
    80004c8e:	1000                	addi	s0,sp,32
    80004c90:	84aa                	mv	s1,a0
    80004c92:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004c94:	ffffc097          	auipc	ra,0xffffc
    80004c98:	f56080e7          	jalr	-170(ra) # 80000bea <acquire>
  if(writable){
    80004c9c:	02090d63          	beqz	s2,80004cd6 <pipeclose+0x52>
    pi->writeopen = 0;
    80004ca0:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004ca4:	21848513          	addi	a0,s1,536
    80004ca8:	ffffd097          	auipc	ra,0xffffd
    80004cac:	4c4080e7          	jalr	1220(ra) # 8000216c <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004cb0:	2204b783          	ld	a5,544(s1)
    80004cb4:	eb95                	bnez	a5,80004ce8 <pipeclose+0x64>
    release(&pi->lock);
    80004cb6:	8526                	mv	a0,s1
    80004cb8:	ffffc097          	auipc	ra,0xffffc
    80004cbc:	fe6080e7          	jalr	-26(ra) # 80000c9e <release>
    kfree((char*)pi);
    80004cc0:	8526                	mv	a0,s1
    80004cc2:	ffffc097          	auipc	ra,0xffffc
    80004cc6:	d3c080e7          	jalr	-708(ra) # 800009fe <kfree>
  } else
    release(&pi->lock);
}
    80004cca:	60e2                	ld	ra,24(sp)
    80004ccc:	6442                	ld	s0,16(sp)
    80004cce:	64a2                	ld	s1,8(sp)
    80004cd0:	6902                	ld	s2,0(sp)
    80004cd2:	6105                	addi	sp,sp,32
    80004cd4:	8082                	ret
    pi->readopen = 0;
    80004cd6:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004cda:	21c48513          	addi	a0,s1,540
    80004cde:	ffffd097          	auipc	ra,0xffffd
    80004ce2:	48e080e7          	jalr	1166(ra) # 8000216c <wakeup>
    80004ce6:	b7e9                	j	80004cb0 <pipeclose+0x2c>
    release(&pi->lock);
    80004ce8:	8526                	mv	a0,s1
    80004cea:	ffffc097          	auipc	ra,0xffffc
    80004cee:	fb4080e7          	jalr	-76(ra) # 80000c9e <release>
}
    80004cf2:	bfe1                	j	80004cca <pipeclose+0x46>

0000000080004cf4 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004cf4:	7159                	addi	sp,sp,-112
    80004cf6:	f486                	sd	ra,104(sp)
    80004cf8:	f0a2                	sd	s0,96(sp)
    80004cfa:	eca6                	sd	s1,88(sp)
    80004cfc:	e8ca                	sd	s2,80(sp)
    80004cfe:	e4ce                	sd	s3,72(sp)
    80004d00:	e0d2                	sd	s4,64(sp)
    80004d02:	fc56                	sd	s5,56(sp)
    80004d04:	f85a                	sd	s6,48(sp)
    80004d06:	f45e                	sd	s7,40(sp)
    80004d08:	f062                	sd	s8,32(sp)
    80004d0a:	ec66                	sd	s9,24(sp)
    80004d0c:	1880                	addi	s0,sp,112
    80004d0e:	84aa                	mv	s1,a0
    80004d10:	8aae                	mv	s5,a1
    80004d12:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004d14:	ffffd097          	auipc	ra,0xffffd
    80004d18:	cb2080e7          	jalr	-846(ra) # 800019c6 <myproc>
    80004d1c:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004d1e:	8526                	mv	a0,s1
    80004d20:	ffffc097          	auipc	ra,0xffffc
    80004d24:	eca080e7          	jalr	-310(ra) # 80000bea <acquire>
  while(i < n){
    80004d28:	0d405463          	blez	s4,80004df0 <pipewrite+0xfc>
    80004d2c:	8ba6                	mv	s7,s1
  int i = 0;
    80004d2e:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d30:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004d32:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004d36:	21c48c13          	addi	s8,s1,540
    80004d3a:	a08d                	j	80004d9c <pipewrite+0xa8>
      release(&pi->lock);
    80004d3c:	8526                	mv	a0,s1
    80004d3e:	ffffc097          	auipc	ra,0xffffc
    80004d42:	f60080e7          	jalr	-160(ra) # 80000c9e <release>
      return -1;
    80004d46:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004d48:	854a                	mv	a0,s2
    80004d4a:	70a6                	ld	ra,104(sp)
    80004d4c:	7406                	ld	s0,96(sp)
    80004d4e:	64e6                	ld	s1,88(sp)
    80004d50:	6946                	ld	s2,80(sp)
    80004d52:	69a6                	ld	s3,72(sp)
    80004d54:	6a06                	ld	s4,64(sp)
    80004d56:	7ae2                	ld	s5,56(sp)
    80004d58:	7b42                	ld	s6,48(sp)
    80004d5a:	7ba2                	ld	s7,40(sp)
    80004d5c:	7c02                	ld	s8,32(sp)
    80004d5e:	6ce2                	ld	s9,24(sp)
    80004d60:	6165                	addi	sp,sp,112
    80004d62:	8082                	ret
      wakeup(&pi->nread);
    80004d64:	8566                	mv	a0,s9
    80004d66:	ffffd097          	auipc	ra,0xffffd
    80004d6a:	406080e7          	jalr	1030(ra) # 8000216c <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004d6e:	85de                	mv	a1,s7
    80004d70:	8562                	mv	a0,s8
    80004d72:	ffffd097          	auipc	ra,0xffffd
    80004d76:	396080e7          	jalr	918(ra) # 80002108 <sleep>
    80004d7a:	a839                	j	80004d98 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004d7c:	21c4a783          	lw	a5,540(s1)
    80004d80:	0017871b          	addiw	a4,a5,1
    80004d84:	20e4ae23          	sw	a4,540(s1)
    80004d88:	1ff7f793          	andi	a5,a5,511
    80004d8c:	97a6                	add	a5,a5,s1
    80004d8e:	f9f44703          	lbu	a4,-97(s0)
    80004d92:	00e78c23          	sb	a4,24(a5)
      i++;
    80004d96:	2905                	addiw	s2,s2,1
  while(i < n){
    80004d98:	05495063          	bge	s2,s4,80004dd8 <pipewrite+0xe4>
    if(pi->readopen == 0 || killed(pr)){
    80004d9c:	2204a783          	lw	a5,544(s1)
    80004da0:	dfd1                	beqz	a5,80004d3c <pipewrite+0x48>
    80004da2:	854e                	mv	a0,s3
    80004da4:	ffffd097          	auipc	ra,0xffffd
    80004da8:	60c080e7          	jalr	1548(ra) # 800023b0 <killed>
    80004dac:	f941                	bnez	a0,80004d3c <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004dae:	2184a783          	lw	a5,536(s1)
    80004db2:	21c4a703          	lw	a4,540(s1)
    80004db6:	2007879b          	addiw	a5,a5,512
    80004dba:	faf705e3          	beq	a4,a5,80004d64 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004dbe:	4685                	li	a3,1
    80004dc0:	01590633          	add	a2,s2,s5
    80004dc4:	f9f40593          	addi	a1,s0,-97
    80004dc8:	0509b503          	ld	a0,80(s3)
    80004dcc:	ffffd097          	auipc	ra,0xffffd
    80004dd0:	944080e7          	jalr	-1724(ra) # 80001710 <copyin>
    80004dd4:	fb6514e3          	bne	a0,s6,80004d7c <pipewrite+0x88>
  wakeup(&pi->nread);
    80004dd8:	21848513          	addi	a0,s1,536
    80004ddc:	ffffd097          	auipc	ra,0xffffd
    80004de0:	390080e7          	jalr	912(ra) # 8000216c <wakeup>
  release(&pi->lock);
    80004de4:	8526                	mv	a0,s1
    80004de6:	ffffc097          	auipc	ra,0xffffc
    80004dea:	eb8080e7          	jalr	-328(ra) # 80000c9e <release>
  return i;
    80004dee:	bfa9                	j	80004d48 <pipewrite+0x54>
  int i = 0;
    80004df0:	4901                	li	s2,0
    80004df2:	b7dd                	j	80004dd8 <pipewrite+0xe4>

0000000080004df4 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004df4:	715d                	addi	sp,sp,-80
    80004df6:	e486                	sd	ra,72(sp)
    80004df8:	e0a2                	sd	s0,64(sp)
    80004dfa:	fc26                	sd	s1,56(sp)
    80004dfc:	f84a                	sd	s2,48(sp)
    80004dfe:	f44e                	sd	s3,40(sp)
    80004e00:	f052                	sd	s4,32(sp)
    80004e02:	ec56                	sd	s5,24(sp)
    80004e04:	e85a                	sd	s6,16(sp)
    80004e06:	0880                	addi	s0,sp,80
    80004e08:	84aa                	mv	s1,a0
    80004e0a:	892e                	mv	s2,a1
    80004e0c:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004e0e:	ffffd097          	auipc	ra,0xffffd
    80004e12:	bb8080e7          	jalr	-1096(ra) # 800019c6 <myproc>
    80004e16:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004e18:	8b26                	mv	s6,s1
    80004e1a:	8526                	mv	a0,s1
    80004e1c:	ffffc097          	auipc	ra,0xffffc
    80004e20:	dce080e7          	jalr	-562(ra) # 80000bea <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e24:	2184a703          	lw	a4,536(s1)
    80004e28:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e2c:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e30:	02f71763          	bne	a4,a5,80004e5e <piperead+0x6a>
    80004e34:	2244a783          	lw	a5,548(s1)
    80004e38:	c39d                	beqz	a5,80004e5e <piperead+0x6a>
    if(killed(pr)){
    80004e3a:	8552                	mv	a0,s4
    80004e3c:	ffffd097          	auipc	ra,0xffffd
    80004e40:	574080e7          	jalr	1396(ra) # 800023b0 <killed>
    80004e44:	e941                	bnez	a0,80004ed4 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e46:	85da                	mv	a1,s6
    80004e48:	854e                	mv	a0,s3
    80004e4a:	ffffd097          	auipc	ra,0xffffd
    80004e4e:	2be080e7          	jalr	702(ra) # 80002108 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e52:	2184a703          	lw	a4,536(s1)
    80004e56:	21c4a783          	lw	a5,540(s1)
    80004e5a:	fcf70de3          	beq	a4,a5,80004e34 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e5e:	09505263          	blez	s5,80004ee2 <piperead+0xee>
    80004e62:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e64:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004e66:	2184a783          	lw	a5,536(s1)
    80004e6a:	21c4a703          	lw	a4,540(s1)
    80004e6e:	02f70d63          	beq	a4,a5,80004ea8 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004e72:	0017871b          	addiw	a4,a5,1
    80004e76:	20e4ac23          	sw	a4,536(s1)
    80004e7a:	1ff7f793          	andi	a5,a5,511
    80004e7e:	97a6                	add	a5,a5,s1
    80004e80:	0187c783          	lbu	a5,24(a5)
    80004e84:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e88:	4685                	li	a3,1
    80004e8a:	fbf40613          	addi	a2,s0,-65
    80004e8e:	85ca                	mv	a1,s2
    80004e90:	050a3503          	ld	a0,80(s4)
    80004e94:	ffffc097          	auipc	ra,0xffffc
    80004e98:	7f0080e7          	jalr	2032(ra) # 80001684 <copyout>
    80004e9c:	01650663          	beq	a0,s6,80004ea8 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ea0:	2985                	addiw	s3,s3,1
    80004ea2:	0905                	addi	s2,s2,1
    80004ea4:	fd3a91e3          	bne	s5,s3,80004e66 <piperead+0x72>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004ea8:	21c48513          	addi	a0,s1,540
    80004eac:	ffffd097          	auipc	ra,0xffffd
    80004eb0:	2c0080e7          	jalr	704(ra) # 8000216c <wakeup>
  release(&pi->lock);
    80004eb4:	8526                	mv	a0,s1
    80004eb6:	ffffc097          	auipc	ra,0xffffc
    80004eba:	de8080e7          	jalr	-536(ra) # 80000c9e <release>
  return i;
}
    80004ebe:	854e                	mv	a0,s3
    80004ec0:	60a6                	ld	ra,72(sp)
    80004ec2:	6406                	ld	s0,64(sp)
    80004ec4:	74e2                	ld	s1,56(sp)
    80004ec6:	7942                	ld	s2,48(sp)
    80004ec8:	79a2                	ld	s3,40(sp)
    80004eca:	7a02                	ld	s4,32(sp)
    80004ecc:	6ae2                	ld	s5,24(sp)
    80004ece:	6b42                	ld	s6,16(sp)
    80004ed0:	6161                	addi	sp,sp,80
    80004ed2:	8082                	ret
      release(&pi->lock);
    80004ed4:	8526                	mv	a0,s1
    80004ed6:	ffffc097          	auipc	ra,0xffffc
    80004eda:	dc8080e7          	jalr	-568(ra) # 80000c9e <release>
      return -1;
    80004ede:	59fd                	li	s3,-1
    80004ee0:	bff9                	j	80004ebe <piperead+0xca>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ee2:	4981                	li	s3,0
    80004ee4:	b7d1                	j	80004ea8 <piperead+0xb4>

0000000080004ee6 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004ee6:	1141                	addi	sp,sp,-16
    80004ee8:	e422                	sd	s0,8(sp)
    80004eea:	0800                	addi	s0,sp,16
    80004eec:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004eee:	8905                	andi	a0,a0,1
    80004ef0:	c111                	beqz	a0,80004ef4 <flags2perm+0xe>
      perm = PTE_X;
    80004ef2:	4521                	li	a0,8
    if(flags & 0x2)
    80004ef4:	8b89                	andi	a5,a5,2
    80004ef6:	c399                	beqz	a5,80004efc <flags2perm+0x16>
      perm |= PTE_W;
    80004ef8:	00456513          	ori	a0,a0,4
    return perm;
}
    80004efc:	6422                	ld	s0,8(sp)
    80004efe:	0141                	addi	sp,sp,16
    80004f00:	8082                	ret

0000000080004f02 <exec>:

int
exec(char *path, char **argv)
{
    80004f02:	df010113          	addi	sp,sp,-528
    80004f06:	20113423          	sd	ra,520(sp)
    80004f0a:	20813023          	sd	s0,512(sp)
    80004f0e:	ffa6                	sd	s1,504(sp)
    80004f10:	fbca                	sd	s2,496(sp)
    80004f12:	f7ce                	sd	s3,488(sp)
    80004f14:	f3d2                	sd	s4,480(sp)
    80004f16:	efd6                	sd	s5,472(sp)
    80004f18:	ebda                	sd	s6,464(sp)
    80004f1a:	e7de                	sd	s7,456(sp)
    80004f1c:	e3e2                	sd	s8,448(sp)
    80004f1e:	ff66                	sd	s9,440(sp)
    80004f20:	fb6a                	sd	s10,432(sp)
    80004f22:	f76e                	sd	s11,424(sp)
    80004f24:	0c00                	addi	s0,sp,528
    80004f26:	84aa                	mv	s1,a0
    80004f28:	dea43c23          	sd	a0,-520(s0)
    80004f2c:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004f30:	ffffd097          	auipc	ra,0xffffd
    80004f34:	a96080e7          	jalr	-1386(ra) # 800019c6 <myproc>
    80004f38:	892a                	mv	s2,a0

  begin_op();
    80004f3a:	fffff097          	auipc	ra,0xfffff
    80004f3e:	474080e7          	jalr	1140(ra) # 800043ae <begin_op>

  if((ip = namei(path)) == 0){
    80004f42:	8526                	mv	a0,s1
    80004f44:	fffff097          	auipc	ra,0xfffff
    80004f48:	24e080e7          	jalr	590(ra) # 80004192 <namei>
    80004f4c:	c92d                	beqz	a0,80004fbe <exec+0xbc>
    80004f4e:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004f50:	fffff097          	auipc	ra,0xfffff
    80004f54:	a9c080e7          	jalr	-1380(ra) # 800039ec <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004f58:	04000713          	li	a4,64
    80004f5c:	4681                	li	a3,0
    80004f5e:	e5040613          	addi	a2,s0,-432
    80004f62:	4581                	li	a1,0
    80004f64:	8526                	mv	a0,s1
    80004f66:	fffff097          	auipc	ra,0xfffff
    80004f6a:	d3a080e7          	jalr	-710(ra) # 80003ca0 <readi>
    80004f6e:	04000793          	li	a5,64
    80004f72:	00f51a63          	bne	a0,a5,80004f86 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004f76:	e5042703          	lw	a4,-432(s0)
    80004f7a:	464c47b7          	lui	a5,0x464c4
    80004f7e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004f82:	04f70463          	beq	a4,a5,80004fca <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004f86:	8526                	mv	a0,s1
    80004f88:	fffff097          	auipc	ra,0xfffff
    80004f8c:	cc6080e7          	jalr	-826(ra) # 80003c4e <iunlockput>
    end_op();
    80004f90:	fffff097          	auipc	ra,0xfffff
    80004f94:	49e080e7          	jalr	1182(ra) # 8000442e <end_op>
  }
  return -1;
    80004f98:	557d                	li	a0,-1
}
    80004f9a:	20813083          	ld	ra,520(sp)
    80004f9e:	20013403          	ld	s0,512(sp)
    80004fa2:	74fe                	ld	s1,504(sp)
    80004fa4:	795e                	ld	s2,496(sp)
    80004fa6:	79be                	ld	s3,488(sp)
    80004fa8:	7a1e                	ld	s4,480(sp)
    80004faa:	6afe                	ld	s5,472(sp)
    80004fac:	6b5e                	ld	s6,464(sp)
    80004fae:	6bbe                	ld	s7,456(sp)
    80004fb0:	6c1e                	ld	s8,448(sp)
    80004fb2:	7cfa                	ld	s9,440(sp)
    80004fb4:	7d5a                	ld	s10,432(sp)
    80004fb6:	7dba                	ld	s11,424(sp)
    80004fb8:	21010113          	addi	sp,sp,528
    80004fbc:	8082                	ret
    end_op();
    80004fbe:	fffff097          	auipc	ra,0xfffff
    80004fc2:	470080e7          	jalr	1136(ra) # 8000442e <end_op>
    return -1;
    80004fc6:	557d                	li	a0,-1
    80004fc8:	bfc9                	j	80004f9a <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004fca:	854a                	mv	a0,s2
    80004fcc:	ffffd097          	auipc	ra,0xffffd
    80004fd0:	abe080e7          	jalr	-1346(ra) # 80001a8a <proc_pagetable>
    80004fd4:	8baa                	mv	s7,a0
    80004fd6:	d945                	beqz	a0,80004f86 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fd8:	e7042983          	lw	s3,-400(s0)
    80004fdc:	e8845783          	lhu	a5,-376(s0)
    80004fe0:	c7ad                	beqz	a5,8000504a <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004fe2:	4a01                	li	s4,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fe4:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004fe6:	6c85                	lui	s9,0x1
    80004fe8:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004fec:	def43823          	sd	a5,-528(s0)
    80004ff0:	ac0d                	j	80005222 <exec+0x320>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004ff2:	00003517          	auipc	a0,0x3
    80004ff6:	79650513          	addi	a0,a0,1942 # 80008788 <syscalls+0x288>
    80004ffa:	ffffb097          	auipc	ra,0xffffb
    80004ffe:	54a080e7          	jalr	1354(ra) # 80000544 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005002:	8756                	mv	a4,s5
    80005004:	012d86bb          	addw	a3,s11,s2
    80005008:	4581                	li	a1,0
    8000500a:	8526                	mv	a0,s1
    8000500c:	fffff097          	auipc	ra,0xfffff
    80005010:	c94080e7          	jalr	-876(ra) # 80003ca0 <readi>
    80005014:	2501                	sext.w	a0,a0
    80005016:	1aaa9a63          	bne	s5,a0,800051ca <exec+0x2c8>
  for(i = 0; i < sz; i += PGSIZE){
    8000501a:	6785                	lui	a5,0x1
    8000501c:	0127893b          	addw	s2,a5,s2
    80005020:	77fd                	lui	a5,0xfffff
    80005022:	01478a3b          	addw	s4,a5,s4
    80005026:	1f897563          	bgeu	s2,s8,80005210 <exec+0x30e>
    pa = walkaddr(pagetable, va + i);
    8000502a:	02091593          	slli	a1,s2,0x20
    8000502e:	9181                	srli	a1,a1,0x20
    80005030:	95ea                	add	a1,a1,s10
    80005032:	855e                	mv	a0,s7
    80005034:	ffffc097          	auipc	ra,0xffffc
    80005038:	044080e7          	jalr	68(ra) # 80001078 <walkaddr>
    8000503c:	862a                	mv	a2,a0
    if(pa == 0)
    8000503e:	d955                	beqz	a0,80004ff2 <exec+0xf0>
      n = PGSIZE;
    80005040:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005042:	fd9a70e3          	bgeu	s4,s9,80005002 <exec+0x100>
      n = sz - i;
    80005046:	8ad2                	mv	s5,s4
    80005048:	bf6d                	j	80005002 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000504a:	4a01                	li	s4,0
  iunlockput(ip);
    8000504c:	8526                	mv	a0,s1
    8000504e:	fffff097          	auipc	ra,0xfffff
    80005052:	c00080e7          	jalr	-1024(ra) # 80003c4e <iunlockput>
  end_op();
    80005056:	fffff097          	auipc	ra,0xfffff
    8000505a:	3d8080e7          	jalr	984(ra) # 8000442e <end_op>
  p = myproc();
    8000505e:	ffffd097          	auipc	ra,0xffffd
    80005062:	968080e7          	jalr	-1688(ra) # 800019c6 <myproc>
    80005066:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005068:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    8000506c:	6785                	lui	a5,0x1
    8000506e:	17fd                	addi	a5,a5,-1
    80005070:	9a3e                	add	s4,s4,a5
    80005072:	757d                	lui	a0,0xfffff
    80005074:	00aa77b3          	and	a5,s4,a0
    80005078:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    8000507c:	4691                	li	a3,4
    8000507e:	6609                	lui	a2,0x2
    80005080:	963e                	add	a2,a2,a5
    80005082:	85be                	mv	a1,a5
    80005084:	855e                	mv	a0,s7
    80005086:	ffffc097          	auipc	ra,0xffffc
    8000508a:	3a6080e7          	jalr	934(ra) # 8000142c <uvmalloc>
    8000508e:	8b2a                	mv	s6,a0
  ip = 0;
    80005090:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005092:	12050c63          	beqz	a0,800051ca <exec+0x2c8>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005096:	75f9                	lui	a1,0xffffe
    80005098:	95aa                	add	a1,a1,a0
    8000509a:	855e                	mv	a0,s7
    8000509c:	ffffc097          	auipc	ra,0xffffc
    800050a0:	5b6080e7          	jalr	1462(ra) # 80001652 <uvmclear>
  stackbase = sp - PGSIZE;
    800050a4:	7c7d                	lui	s8,0xfffff
    800050a6:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    800050a8:	e0043783          	ld	a5,-512(s0)
    800050ac:	6388                	ld	a0,0(a5)
    800050ae:	c535                	beqz	a0,8000511a <exec+0x218>
    800050b0:	e9040993          	addi	s3,s0,-368
    800050b4:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800050b8:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    800050ba:	ffffc097          	auipc	ra,0xffffc
    800050be:	db0080e7          	jalr	-592(ra) # 80000e6a <strlen>
    800050c2:	2505                	addiw	a0,a0,1
    800050c4:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800050c8:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800050cc:	13896663          	bltu	s2,s8,800051f8 <exec+0x2f6>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800050d0:	e0043d83          	ld	s11,-512(s0)
    800050d4:	000dba03          	ld	s4,0(s11)
    800050d8:	8552                	mv	a0,s4
    800050da:	ffffc097          	auipc	ra,0xffffc
    800050de:	d90080e7          	jalr	-624(ra) # 80000e6a <strlen>
    800050e2:	0015069b          	addiw	a3,a0,1
    800050e6:	8652                	mv	a2,s4
    800050e8:	85ca                	mv	a1,s2
    800050ea:	855e                	mv	a0,s7
    800050ec:	ffffc097          	auipc	ra,0xffffc
    800050f0:	598080e7          	jalr	1432(ra) # 80001684 <copyout>
    800050f4:	10054663          	bltz	a0,80005200 <exec+0x2fe>
    ustack[argc] = sp;
    800050f8:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800050fc:	0485                	addi	s1,s1,1
    800050fe:	008d8793          	addi	a5,s11,8
    80005102:	e0f43023          	sd	a5,-512(s0)
    80005106:	008db503          	ld	a0,8(s11)
    8000510a:	c911                	beqz	a0,8000511e <exec+0x21c>
    if(argc >= MAXARG)
    8000510c:	09a1                	addi	s3,s3,8
    8000510e:	fb3c96e3          	bne	s9,s3,800050ba <exec+0x1b8>
  sz = sz1;
    80005112:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005116:	4481                	li	s1,0
    80005118:	a84d                	j	800051ca <exec+0x2c8>
  sp = sz;
    8000511a:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    8000511c:	4481                	li	s1,0
  ustack[argc] = 0;
    8000511e:	00349793          	slli	a5,s1,0x3
    80005122:	f9040713          	addi	a4,s0,-112
    80005126:	97ba                	add	a5,a5,a4
    80005128:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    8000512c:	00148693          	addi	a3,s1,1
    80005130:	068e                	slli	a3,a3,0x3
    80005132:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005136:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000513a:	01897663          	bgeu	s2,s8,80005146 <exec+0x244>
  sz = sz1;
    8000513e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005142:	4481                	li	s1,0
    80005144:	a059                	j	800051ca <exec+0x2c8>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005146:	e9040613          	addi	a2,s0,-368
    8000514a:	85ca                	mv	a1,s2
    8000514c:	855e                	mv	a0,s7
    8000514e:	ffffc097          	auipc	ra,0xffffc
    80005152:	536080e7          	jalr	1334(ra) # 80001684 <copyout>
    80005156:	0a054963          	bltz	a0,80005208 <exec+0x306>
  p->trapframe->a1 = sp;
    8000515a:	058ab783          	ld	a5,88(s5)
    8000515e:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005162:	df843783          	ld	a5,-520(s0)
    80005166:	0007c703          	lbu	a4,0(a5)
    8000516a:	cf11                	beqz	a4,80005186 <exec+0x284>
    8000516c:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000516e:	02f00693          	li	a3,47
    80005172:	a039                	j	80005180 <exec+0x27e>
      last = s+1;
    80005174:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005178:	0785                	addi	a5,a5,1
    8000517a:	fff7c703          	lbu	a4,-1(a5)
    8000517e:	c701                	beqz	a4,80005186 <exec+0x284>
    if(*s == '/')
    80005180:	fed71ce3          	bne	a4,a3,80005178 <exec+0x276>
    80005184:	bfc5                	j	80005174 <exec+0x272>
  safestrcpy(p->name, last, sizeof(p->name));
    80005186:	4641                	li	a2,16
    80005188:	df843583          	ld	a1,-520(s0)
    8000518c:	158a8513          	addi	a0,s5,344
    80005190:	ffffc097          	auipc	ra,0xffffc
    80005194:	ca8080e7          	jalr	-856(ra) # 80000e38 <safestrcpy>
  oldpagetable = p->pagetable;
    80005198:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    8000519c:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    800051a0:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800051a4:	058ab783          	ld	a5,88(s5)
    800051a8:	e6843703          	ld	a4,-408(s0)
    800051ac:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800051ae:	058ab783          	ld	a5,88(s5)
    800051b2:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800051b6:	85ea                	mv	a1,s10
    800051b8:	ffffd097          	auipc	ra,0xffffd
    800051bc:	96e080e7          	jalr	-1682(ra) # 80001b26 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800051c0:	0004851b          	sext.w	a0,s1
    800051c4:	bbd9                	j	80004f9a <exec+0x98>
    800051c6:	e1443423          	sd	s4,-504(s0)
    proc_freepagetable(pagetable, sz);
    800051ca:	e0843583          	ld	a1,-504(s0)
    800051ce:	855e                	mv	a0,s7
    800051d0:	ffffd097          	auipc	ra,0xffffd
    800051d4:	956080e7          	jalr	-1706(ra) # 80001b26 <proc_freepagetable>
  if(ip){
    800051d8:	da0497e3          	bnez	s1,80004f86 <exec+0x84>
  return -1;
    800051dc:	557d                	li	a0,-1
    800051de:	bb75                	j	80004f9a <exec+0x98>
    800051e0:	e1443423          	sd	s4,-504(s0)
    800051e4:	b7dd                	j	800051ca <exec+0x2c8>
    800051e6:	e1443423          	sd	s4,-504(s0)
    800051ea:	b7c5                	j	800051ca <exec+0x2c8>
    800051ec:	e1443423          	sd	s4,-504(s0)
    800051f0:	bfe9                	j	800051ca <exec+0x2c8>
    800051f2:	e1443423          	sd	s4,-504(s0)
    800051f6:	bfd1                	j	800051ca <exec+0x2c8>
  sz = sz1;
    800051f8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800051fc:	4481                	li	s1,0
    800051fe:	b7f1                	j	800051ca <exec+0x2c8>
  sz = sz1;
    80005200:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005204:	4481                	li	s1,0
    80005206:	b7d1                	j	800051ca <exec+0x2c8>
  sz = sz1;
    80005208:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000520c:	4481                	li	s1,0
    8000520e:	bf75                	j	800051ca <exec+0x2c8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005210:	e0843a03          	ld	s4,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005214:	2b05                	addiw	s6,s6,1
    80005216:	0389899b          	addiw	s3,s3,56
    8000521a:	e8845783          	lhu	a5,-376(s0)
    8000521e:	e2fb57e3          	bge	s6,a5,8000504c <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005222:	2981                	sext.w	s3,s3
    80005224:	03800713          	li	a4,56
    80005228:	86ce                	mv	a3,s3
    8000522a:	e1840613          	addi	a2,s0,-488
    8000522e:	4581                	li	a1,0
    80005230:	8526                	mv	a0,s1
    80005232:	fffff097          	auipc	ra,0xfffff
    80005236:	a6e080e7          	jalr	-1426(ra) # 80003ca0 <readi>
    8000523a:	03800793          	li	a5,56
    8000523e:	f8f514e3          	bne	a0,a5,800051c6 <exec+0x2c4>
    if(ph.type != ELF_PROG_LOAD)
    80005242:	e1842783          	lw	a5,-488(s0)
    80005246:	4705                	li	a4,1
    80005248:	fce796e3          	bne	a5,a4,80005214 <exec+0x312>
    if(ph.memsz < ph.filesz)
    8000524c:	e4043903          	ld	s2,-448(s0)
    80005250:	e3843783          	ld	a5,-456(s0)
    80005254:	f8f966e3          	bltu	s2,a5,800051e0 <exec+0x2de>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005258:	e2843783          	ld	a5,-472(s0)
    8000525c:	993e                	add	s2,s2,a5
    8000525e:	f8f964e3          	bltu	s2,a5,800051e6 <exec+0x2e4>
    if(ph.vaddr % PGSIZE != 0)
    80005262:	df043703          	ld	a4,-528(s0)
    80005266:	8ff9                	and	a5,a5,a4
    80005268:	f3d1                	bnez	a5,800051ec <exec+0x2ea>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000526a:	e1c42503          	lw	a0,-484(s0)
    8000526e:	00000097          	auipc	ra,0x0
    80005272:	c78080e7          	jalr	-904(ra) # 80004ee6 <flags2perm>
    80005276:	86aa                	mv	a3,a0
    80005278:	864a                	mv	a2,s2
    8000527a:	85d2                	mv	a1,s4
    8000527c:	855e                	mv	a0,s7
    8000527e:	ffffc097          	auipc	ra,0xffffc
    80005282:	1ae080e7          	jalr	430(ra) # 8000142c <uvmalloc>
    80005286:	e0a43423          	sd	a0,-504(s0)
    8000528a:	d525                	beqz	a0,800051f2 <exec+0x2f0>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000528c:	e2843d03          	ld	s10,-472(s0)
    80005290:	e2042d83          	lw	s11,-480(s0)
    80005294:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005298:	f60c0ce3          	beqz	s8,80005210 <exec+0x30e>
    8000529c:	8a62                	mv	s4,s8
    8000529e:	4901                	li	s2,0
    800052a0:	b369                	j	8000502a <exec+0x128>

00000000800052a2 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800052a2:	7179                	addi	sp,sp,-48
    800052a4:	f406                	sd	ra,40(sp)
    800052a6:	f022                	sd	s0,32(sp)
    800052a8:	ec26                	sd	s1,24(sp)
    800052aa:	e84a                	sd	s2,16(sp)
    800052ac:	1800                	addi	s0,sp,48
    800052ae:	892e                	mv	s2,a1
    800052b0:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800052b2:	fdc40593          	addi	a1,s0,-36
    800052b6:	ffffe097          	auipc	ra,0xffffe
    800052ba:	8be080e7          	jalr	-1858(ra) # 80002b74 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800052be:	fdc42703          	lw	a4,-36(s0)
    800052c2:	47bd                	li	a5,15
    800052c4:	02e7eb63          	bltu	a5,a4,800052fa <argfd+0x58>
    800052c8:	ffffc097          	auipc	ra,0xffffc
    800052cc:	6fe080e7          	jalr	1790(ra) # 800019c6 <myproc>
    800052d0:	fdc42703          	lw	a4,-36(s0)
    800052d4:	01a70793          	addi	a5,a4,26
    800052d8:	078e                	slli	a5,a5,0x3
    800052da:	953e                	add	a0,a0,a5
    800052dc:	611c                	ld	a5,0(a0)
    800052de:	c385                	beqz	a5,800052fe <argfd+0x5c>
    return -1;
  if(pfd)
    800052e0:	00090463          	beqz	s2,800052e8 <argfd+0x46>
    *pfd = fd;
    800052e4:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800052e8:	4501                	li	a0,0
  if(pf)
    800052ea:	c091                	beqz	s1,800052ee <argfd+0x4c>
    *pf = f;
    800052ec:	e09c                	sd	a5,0(s1)
}
    800052ee:	70a2                	ld	ra,40(sp)
    800052f0:	7402                	ld	s0,32(sp)
    800052f2:	64e2                	ld	s1,24(sp)
    800052f4:	6942                	ld	s2,16(sp)
    800052f6:	6145                	addi	sp,sp,48
    800052f8:	8082                	ret
    return -1;
    800052fa:	557d                	li	a0,-1
    800052fc:	bfcd                	j	800052ee <argfd+0x4c>
    800052fe:	557d                	li	a0,-1
    80005300:	b7fd                	j	800052ee <argfd+0x4c>

0000000080005302 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005302:	1101                	addi	sp,sp,-32
    80005304:	ec06                	sd	ra,24(sp)
    80005306:	e822                	sd	s0,16(sp)
    80005308:	e426                	sd	s1,8(sp)
    8000530a:	1000                	addi	s0,sp,32
    8000530c:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000530e:	ffffc097          	auipc	ra,0xffffc
    80005312:	6b8080e7          	jalr	1720(ra) # 800019c6 <myproc>
    80005316:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005318:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd06f0>
    8000531c:	4501                	li	a0,0
    8000531e:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005320:	6398                	ld	a4,0(a5)
    80005322:	cb19                	beqz	a4,80005338 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005324:	2505                	addiw	a0,a0,1
    80005326:	07a1                	addi	a5,a5,8
    80005328:	fed51ce3          	bne	a0,a3,80005320 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000532c:	557d                	li	a0,-1
}
    8000532e:	60e2                	ld	ra,24(sp)
    80005330:	6442                	ld	s0,16(sp)
    80005332:	64a2                	ld	s1,8(sp)
    80005334:	6105                	addi	sp,sp,32
    80005336:	8082                	ret
      p->ofile[fd] = f;
    80005338:	01a50793          	addi	a5,a0,26
    8000533c:	078e                	slli	a5,a5,0x3
    8000533e:	963e                	add	a2,a2,a5
    80005340:	e204                	sd	s1,0(a2)
      return fd;
    80005342:	b7f5                	j	8000532e <fdalloc+0x2c>

0000000080005344 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005344:	715d                	addi	sp,sp,-80
    80005346:	e486                	sd	ra,72(sp)
    80005348:	e0a2                	sd	s0,64(sp)
    8000534a:	fc26                	sd	s1,56(sp)
    8000534c:	f84a                	sd	s2,48(sp)
    8000534e:	f44e                	sd	s3,40(sp)
    80005350:	f052                	sd	s4,32(sp)
    80005352:	ec56                	sd	s5,24(sp)
    80005354:	e85a                	sd	s6,16(sp)
    80005356:	0880                	addi	s0,sp,80
    80005358:	8b2e                	mv	s6,a1
    8000535a:	89b2                	mv	s3,a2
    8000535c:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000535e:	fb040593          	addi	a1,s0,-80
    80005362:	fffff097          	auipc	ra,0xfffff
    80005366:	e4e080e7          	jalr	-434(ra) # 800041b0 <nameiparent>
    8000536a:	84aa                	mv	s1,a0
    8000536c:	16050063          	beqz	a0,800054cc <create+0x188>
    return 0;

  ilock(dp);
    80005370:	ffffe097          	auipc	ra,0xffffe
    80005374:	67c080e7          	jalr	1660(ra) # 800039ec <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005378:	4601                	li	a2,0
    8000537a:	fb040593          	addi	a1,s0,-80
    8000537e:	8526                	mv	a0,s1
    80005380:	fffff097          	auipc	ra,0xfffff
    80005384:	b50080e7          	jalr	-1200(ra) # 80003ed0 <dirlookup>
    80005388:	8aaa                	mv	s5,a0
    8000538a:	c931                	beqz	a0,800053de <create+0x9a>
    iunlockput(dp);
    8000538c:	8526                	mv	a0,s1
    8000538e:	fffff097          	auipc	ra,0xfffff
    80005392:	8c0080e7          	jalr	-1856(ra) # 80003c4e <iunlockput>
    ilock(ip);
    80005396:	8556                	mv	a0,s5
    80005398:	ffffe097          	auipc	ra,0xffffe
    8000539c:	654080e7          	jalr	1620(ra) # 800039ec <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800053a0:	000b059b          	sext.w	a1,s6
    800053a4:	4789                	li	a5,2
    800053a6:	02f59563          	bne	a1,a5,800053d0 <create+0x8c>
    800053aa:	044ad783          	lhu	a5,68(s5)
    800053ae:	37f9                	addiw	a5,a5,-2
    800053b0:	17c2                	slli	a5,a5,0x30
    800053b2:	93c1                	srli	a5,a5,0x30
    800053b4:	4705                	li	a4,1
    800053b6:	00f76d63          	bltu	a4,a5,800053d0 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800053ba:	8556                	mv	a0,s5
    800053bc:	60a6                	ld	ra,72(sp)
    800053be:	6406                	ld	s0,64(sp)
    800053c0:	74e2                	ld	s1,56(sp)
    800053c2:	7942                	ld	s2,48(sp)
    800053c4:	79a2                	ld	s3,40(sp)
    800053c6:	7a02                	ld	s4,32(sp)
    800053c8:	6ae2                	ld	s5,24(sp)
    800053ca:	6b42                	ld	s6,16(sp)
    800053cc:	6161                	addi	sp,sp,80
    800053ce:	8082                	ret
    iunlockput(ip);
    800053d0:	8556                	mv	a0,s5
    800053d2:	fffff097          	auipc	ra,0xfffff
    800053d6:	87c080e7          	jalr	-1924(ra) # 80003c4e <iunlockput>
    return 0;
    800053da:	4a81                	li	s5,0
    800053dc:	bff9                	j	800053ba <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800053de:	85da                	mv	a1,s6
    800053e0:	4088                	lw	a0,0(s1)
    800053e2:	ffffe097          	auipc	ra,0xffffe
    800053e6:	46e080e7          	jalr	1134(ra) # 80003850 <ialloc>
    800053ea:	8a2a                	mv	s4,a0
    800053ec:	c921                	beqz	a0,8000543c <create+0xf8>
  ilock(ip);
    800053ee:	ffffe097          	auipc	ra,0xffffe
    800053f2:	5fe080e7          	jalr	1534(ra) # 800039ec <ilock>
  ip->major = major;
    800053f6:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800053fa:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800053fe:	4785                	li	a5,1
    80005400:	04fa1523          	sh	a5,74(s4)
  iupdate(ip);
    80005404:	8552                	mv	a0,s4
    80005406:	ffffe097          	auipc	ra,0xffffe
    8000540a:	51c080e7          	jalr	1308(ra) # 80003922 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000540e:	000b059b          	sext.w	a1,s6
    80005412:	4785                	li	a5,1
    80005414:	02f58b63          	beq	a1,a5,8000544a <create+0x106>
  if(dirlink(dp, name, ip->inum) < 0)
    80005418:	004a2603          	lw	a2,4(s4)
    8000541c:	fb040593          	addi	a1,s0,-80
    80005420:	8526                	mv	a0,s1
    80005422:	fffff097          	auipc	ra,0xfffff
    80005426:	cbe080e7          	jalr	-834(ra) # 800040e0 <dirlink>
    8000542a:	06054f63          	bltz	a0,800054a8 <create+0x164>
  iunlockput(dp);
    8000542e:	8526                	mv	a0,s1
    80005430:	fffff097          	auipc	ra,0xfffff
    80005434:	81e080e7          	jalr	-2018(ra) # 80003c4e <iunlockput>
  return ip;
    80005438:	8ad2                	mv	s5,s4
    8000543a:	b741                	j	800053ba <create+0x76>
    iunlockput(dp);
    8000543c:	8526                	mv	a0,s1
    8000543e:	fffff097          	auipc	ra,0xfffff
    80005442:	810080e7          	jalr	-2032(ra) # 80003c4e <iunlockput>
    return 0;
    80005446:	8ad2                	mv	s5,s4
    80005448:	bf8d                	j	800053ba <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000544a:	004a2603          	lw	a2,4(s4)
    8000544e:	00003597          	auipc	a1,0x3
    80005452:	35a58593          	addi	a1,a1,858 # 800087a8 <syscalls+0x2a8>
    80005456:	8552                	mv	a0,s4
    80005458:	fffff097          	auipc	ra,0xfffff
    8000545c:	c88080e7          	jalr	-888(ra) # 800040e0 <dirlink>
    80005460:	04054463          	bltz	a0,800054a8 <create+0x164>
    80005464:	40d0                	lw	a2,4(s1)
    80005466:	00003597          	auipc	a1,0x3
    8000546a:	34a58593          	addi	a1,a1,842 # 800087b0 <syscalls+0x2b0>
    8000546e:	8552                	mv	a0,s4
    80005470:	fffff097          	auipc	ra,0xfffff
    80005474:	c70080e7          	jalr	-912(ra) # 800040e0 <dirlink>
    80005478:	02054863          	bltz	a0,800054a8 <create+0x164>
  if(dirlink(dp, name, ip->inum) < 0)
    8000547c:	004a2603          	lw	a2,4(s4)
    80005480:	fb040593          	addi	a1,s0,-80
    80005484:	8526                	mv	a0,s1
    80005486:	fffff097          	auipc	ra,0xfffff
    8000548a:	c5a080e7          	jalr	-934(ra) # 800040e0 <dirlink>
    8000548e:	00054d63          	bltz	a0,800054a8 <create+0x164>
    dp->nlink++;  // for ".."
    80005492:	04a4d783          	lhu	a5,74(s1)
    80005496:	2785                	addiw	a5,a5,1
    80005498:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000549c:	8526                	mv	a0,s1
    8000549e:	ffffe097          	auipc	ra,0xffffe
    800054a2:	484080e7          	jalr	1156(ra) # 80003922 <iupdate>
    800054a6:	b761                	j	8000542e <create+0xea>
  ip->nlink = 0;
    800054a8:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800054ac:	8552                	mv	a0,s4
    800054ae:	ffffe097          	auipc	ra,0xffffe
    800054b2:	474080e7          	jalr	1140(ra) # 80003922 <iupdate>
  iunlockput(ip);
    800054b6:	8552                	mv	a0,s4
    800054b8:	ffffe097          	auipc	ra,0xffffe
    800054bc:	796080e7          	jalr	1942(ra) # 80003c4e <iunlockput>
  iunlockput(dp);
    800054c0:	8526                	mv	a0,s1
    800054c2:	ffffe097          	auipc	ra,0xffffe
    800054c6:	78c080e7          	jalr	1932(ra) # 80003c4e <iunlockput>
  return 0;
    800054ca:	bdc5                	j	800053ba <create+0x76>
    return 0;
    800054cc:	8aaa                	mv	s5,a0
    800054ce:	b5f5                	j	800053ba <create+0x76>

00000000800054d0 <sys_dup>:
{
    800054d0:	7179                	addi	sp,sp,-48
    800054d2:	f406                	sd	ra,40(sp)
    800054d4:	f022                	sd	s0,32(sp)
    800054d6:	ec26                	sd	s1,24(sp)
    800054d8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800054da:	fd840613          	addi	a2,s0,-40
    800054de:	4581                	li	a1,0
    800054e0:	4501                	li	a0,0
    800054e2:	00000097          	auipc	ra,0x0
    800054e6:	dc0080e7          	jalr	-576(ra) # 800052a2 <argfd>
    return -1;
    800054ea:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800054ec:	02054363          	bltz	a0,80005512 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800054f0:	fd843503          	ld	a0,-40(s0)
    800054f4:	00000097          	auipc	ra,0x0
    800054f8:	e0e080e7          	jalr	-498(ra) # 80005302 <fdalloc>
    800054fc:	84aa                	mv	s1,a0
    return -1;
    800054fe:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005500:	00054963          	bltz	a0,80005512 <sys_dup+0x42>
  filedup(f);
    80005504:	fd843503          	ld	a0,-40(s0)
    80005508:	fffff097          	auipc	ra,0xfffff
    8000550c:	320080e7          	jalr	800(ra) # 80004828 <filedup>
  return fd;
    80005510:	87a6                	mv	a5,s1
}
    80005512:	853e                	mv	a0,a5
    80005514:	70a2                	ld	ra,40(sp)
    80005516:	7402                	ld	s0,32(sp)
    80005518:	64e2                	ld	s1,24(sp)
    8000551a:	6145                	addi	sp,sp,48
    8000551c:	8082                	ret

000000008000551e <sys_read>:
{
    8000551e:	7179                	addi	sp,sp,-48
    80005520:	f406                	sd	ra,40(sp)
    80005522:	f022                	sd	s0,32(sp)
    80005524:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005526:	fd840593          	addi	a1,s0,-40
    8000552a:	4505                	li	a0,1
    8000552c:	ffffd097          	auipc	ra,0xffffd
    80005530:	668080e7          	jalr	1640(ra) # 80002b94 <argaddr>
  argint(2, &n);
    80005534:	fe440593          	addi	a1,s0,-28
    80005538:	4509                	li	a0,2
    8000553a:	ffffd097          	auipc	ra,0xffffd
    8000553e:	63a080e7          	jalr	1594(ra) # 80002b74 <argint>
  if(argfd(0, 0, &f) < 0)
    80005542:	fe840613          	addi	a2,s0,-24
    80005546:	4581                	li	a1,0
    80005548:	4501                	li	a0,0
    8000554a:	00000097          	auipc	ra,0x0
    8000554e:	d58080e7          	jalr	-680(ra) # 800052a2 <argfd>
    80005552:	87aa                	mv	a5,a0
    return -1;
    80005554:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005556:	0007cc63          	bltz	a5,8000556e <sys_read+0x50>
  return fileread(f, p, n);
    8000555a:	fe442603          	lw	a2,-28(s0)
    8000555e:	fd843583          	ld	a1,-40(s0)
    80005562:	fe843503          	ld	a0,-24(s0)
    80005566:	fffff097          	auipc	ra,0xfffff
    8000556a:	44e080e7          	jalr	1102(ra) # 800049b4 <fileread>
}
    8000556e:	70a2                	ld	ra,40(sp)
    80005570:	7402                	ld	s0,32(sp)
    80005572:	6145                	addi	sp,sp,48
    80005574:	8082                	ret

0000000080005576 <sys_write>:
{
    80005576:	7179                	addi	sp,sp,-48
    80005578:	f406                	sd	ra,40(sp)
    8000557a:	f022                	sd	s0,32(sp)
    8000557c:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000557e:	fd840593          	addi	a1,s0,-40
    80005582:	4505                	li	a0,1
    80005584:	ffffd097          	auipc	ra,0xffffd
    80005588:	610080e7          	jalr	1552(ra) # 80002b94 <argaddr>
  argint(2, &n);
    8000558c:	fe440593          	addi	a1,s0,-28
    80005590:	4509                	li	a0,2
    80005592:	ffffd097          	auipc	ra,0xffffd
    80005596:	5e2080e7          	jalr	1506(ra) # 80002b74 <argint>
  if(argfd(0, 0, &f) < 0)
    8000559a:	fe840613          	addi	a2,s0,-24
    8000559e:	4581                	li	a1,0
    800055a0:	4501                	li	a0,0
    800055a2:	00000097          	auipc	ra,0x0
    800055a6:	d00080e7          	jalr	-768(ra) # 800052a2 <argfd>
    800055aa:	87aa                	mv	a5,a0
    return -1;
    800055ac:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800055ae:	0007cc63          	bltz	a5,800055c6 <sys_write+0x50>
  return filewrite(f, p, n);
    800055b2:	fe442603          	lw	a2,-28(s0)
    800055b6:	fd843583          	ld	a1,-40(s0)
    800055ba:	fe843503          	ld	a0,-24(s0)
    800055be:	fffff097          	auipc	ra,0xfffff
    800055c2:	4b8080e7          	jalr	1208(ra) # 80004a76 <filewrite>
}
    800055c6:	70a2                	ld	ra,40(sp)
    800055c8:	7402                	ld	s0,32(sp)
    800055ca:	6145                	addi	sp,sp,48
    800055cc:	8082                	ret

00000000800055ce <sys_close>:
{
    800055ce:	1101                	addi	sp,sp,-32
    800055d0:	ec06                	sd	ra,24(sp)
    800055d2:	e822                	sd	s0,16(sp)
    800055d4:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800055d6:	fe040613          	addi	a2,s0,-32
    800055da:	fec40593          	addi	a1,s0,-20
    800055de:	4501                	li	a0,0
    800055e0:	00000097          	auipc	ra,0x0
    800055e4:	cc2080e7          	jalr	-830(ra) # 800052a2 <argfd>
    return -1;
    800055e8:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800055ea:	02054463          	bltz	a0,80005612 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800055ee:	ffffc097          	auipc	ra,0xffffc
    800055f2:	3d8080e7          	jalr	984(ra) # 800019c6 <myproc>
    800055f6:	fec42783          	lw	a5,-20(s0)
    800055fa:	07e9                	addi	a5,a5,26
    800055fc:	078e                	slli	a5,a5,0x3
    800055fe:	97aa                	add	a5,a5,a0
    80005600:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005604:	fe043503          	ld	a0,-32(s0)
    80005608:	fffff097          	auipc	ra,0xfffff
    8000560c:	272080e7          	jalr	626(ra) # 8000487a <fileclose>
  return 0;
    80005610:	4781                	li	a5,0
}
    80005612:	853e                	mv	a0,a5
    80005614:	60e2                	ld	ra,24(sp)
    80005616:	6442                	ld	s0,16(sp)
    80005618:	6105                	addi	sp,sp,32
    8000561a:	8082                	ret

000000008000561c <sys_fstat>:
{
    8000561c:	1101                	addi	sp,sp,-32
    8000561e:	ec06                	sd	ra,24(sp)
    80005620:	e822                	sd	s0,16(sp)
    80005622:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005624:	fe040593          	addi	a1,s0,-32
    80005628:	4505                	li	a0,1
    8000562a:	ffffd097          	auipc	ra,0xffffd
    8000562e:	56a080e7          	jalr	1386(ra) # 80002b94 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005632:	fe840613          	addi	a2,s0,-24
    80005636:	4581                	li	a1,0
    80005638:	4501                	li	a0,0
    8000563a:	00000097          	auipc	ra,0x0
    8000563e:	c68080e7          	jalr	-920(ra) # 800052a2 <argfd>
    80005642:	87aa                	mv	a5,a0
    return -1;
    80005644:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005646:	0007ca63          	bltz	a5,8000565a <sys_fstat+0x3e>
  return filestat(f, st);
    8000564a:	fe043583          	ld	a1,-32(s0)
    8000564e:	fe843503          	ld	a0,-24(s0)
    80005652:	fffff097          	auipc	ra,0xfffff
    80005656:	2f0080e7          	jalr	752(ra) # 80004942 <filestat>
}
    8000565a:	60e2                	ld	ra,24(sp)
    8000565c:	6442                	ld	s0,16(sp)
    8000565e:	6105                	addi	sp,sp,32
    80005660:	8082                	ret

0000000080005662 <sys_link>:
{
    80005662:	7169                	addi	sp,sp,-304
    80005664:	f606                	sd	ra,296(sp)
    80005666:	f222                	sd	s0,288(sp)
    80005668:	ee26                	sd	s1,280(sp)
    8000566a:	ea4a                	sd	s2,272(sp)
    8000566c:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000566e:	08000613          	li	a2,128
    80005672:	ed040593          	addi	a1,s0,-304
    80005676:	4501                	li	a0,0
    80005678:	ffffd097          	auipc	ra,0xffffd
    8000567c:	53c080e7          	jalr	1340(ra) # 80002bb4 <argstr>
    return -1;
    80005680:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005682:	10054e63          	bltz	a0,8000579e <sys_link+0x13c>
    80005686:	08000613          	li	a2,128
    8000568a:	f5040593          	addi	a1,s0,-176
    8000568e:	4505                	li	a0,1
    80005690:	ffffd097          	auipc	ra,0xffffd
    80005694:	524080e7          	jalr	1316(ra) # 80002bb4 <argstr>
    return -1;
    80005698:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000569a:	10054263          	bltz	a0,8000579e <sys_link+0x13c>
  begin_op();
    8000569e:	fffff097          	auipc	ra,0xfffff
    800056a2:	d10080e7          	jalr	-752(ra) # 800043ae <begin_op>
  if((ip = namei(old)) == 0){
    800056a6:	ed040513          	addi	a0,s0,-304
    800056aa:	fffff097          	auipc	ra,0xfffff
    800056ae:	ae8080e7          	jalr	-1304(ra) # 80004192 <namei>
    800056b2:	84aa                	mv	s1,a0
    800056b4:	c551                	beqz	a0,80005740 <sys_link+0xde>
  ilock(ip);
    800056b6:	ffffe097          	auipc	ra,0xffffe
    800056ba:	336080e7          	jalr	822(ra) # 800039ec <ilock>
  if(ip->type == T_DIR){
    800056be:	04449703          	lh	a4,68(s1)
    800056c2:	4785                	li	a5,1
    800056c4:	08f70463          	beq	a4,a5,8000574c <sys_link+0xea>
  ip->nlink++;
    800056c8:	04a4d783          	lhu	a5,74(s1)
    800056cc:	2785                	addiw	a5,a5,1
    800056ce:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056d2:	8526                	mv	a0,s1
    800056d4:	ffffe097          	auipc	ra,0xffffe
    800056d8:	24e080e7          	jalr	590(ra) # 80003922 <iupdate>
  iunlock(ip);
    800056dc:	8526                	mv	a0,s1
    800056de:	ffffe097          	auipc	ra,0xffffe
    800056e2:	3d0080e7          	jalr	976(ra) # 80003aae <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800056e6:	fd040593          	addi	a1,s0,-48
    800056ea:	f5040513          	addi	a0,s0,-176
    800056ee:	fffff097          	auipc	ra,0xfffff
    800056f2:	ac2080e7          	jalr	-1342(ra) # 800041b0 <nameiparent>
    800056f6:	892a                	mv	s2,a0
    800056f8:	c935                	beqz	a0,8000576c <sys_link+0x10a>
  ilock(dp);
    800056fa:	ffffe097          	auipc	ra,0xffffe
    800056fe:	2f2080e7          	jalr	754(ra) # 800039ec <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005702:	00092703          	lw	a4,0(s2)
    80005706:	409c                	lw	a5,0(s1)
    80005708:	04f71d63          	bne	a4,a5,80005762 <sys_link+0x100>
    8000570c:	40d0                	lw	a2,4(s1)
    8000570e:	fd040593          	addi	a1,s0,-48
    80005712:	854a                	mv	a0,s2
    80005714:	fffff097          	auipc	ra,0xfffff
    80005718:	9cc080e7          	jalr	-1588(ra) # 800040e0 <dirlink>
    8000571c:	04054363          	bltz	a0,80005762 <sys_link+0x100>
  iunlockput(dp);
    80005720:	854a                	mv	a0,s2
    80005722:	ffffe097          	auipc	ra,0xffffe
    80005726:	52c080e7          	jalr	1324(ra) # 80003c4e <iunlockput>
  iput(ip);
    8000572a:	8526                	mv	a0,s1
    8000572c:	ffffe097          	auipc	ra,0xffffe
    80005730:	47a080e7          	jalr	1146(ra) # 80003ba6 <iput>
  end_op();
    80005734:	fffff097          	auipc	ra,0xfffff
    80005738:	cfa080e7          	jalr	-774(ra) # 8000442e <end_op>
  return 0;
    8000573c:	4781                	li	a5,0
    8000573e:	a085                	j	8000579e <sys_link+0x13c>
    end_op();
    80005740:	fffff097          	auipc	ra,0xfffff
    80005744:	cee080e7          	jalr	-786(ra) # 8000442e <end_op>
    return -1;
    80005748:	57fd                	li	a5,-1
    8000574a:	a891                	j	8000579e <sys_link+0x13c>
    iunlockput(ip);
    8000574c:	8526                	mv	a0,s1
    8000574e:	ffffe097          	auipc	ra,0xffffe
    80005752:	500080e7          	jalr	1280(ra) # 80003c4e <iunlockput>
    end_op();
    80005756:	fffff097          	auipc	ra,0xfffff
    8000575a:	cd8080e7          	jalr	-808(ra) # 8000442e <end_op>
    return -1;
    8000575e:	57fd                	li	a5,-1
    80005760:	a83d                	j	8000579e <sys_link+0x13c>
    iunlockput(dp);
    80005762:	854a                	mv	a0,s2
    80005764:	ffffe097          	auipc	ra,0xffffe
    80005768:	4ea080e7          	jalr	1258(ra) # 80003c4e <iunlockput>
  ilock(ip);
    8000576c:	8526                	mv	a0,s1
    8000576e:	ffffe097          	auipc	ra,0xffffe
    80005772:	27e080e7          	jalr	638(ra) # 800039ec <ilock>
  ip->nlink--;
    80005776:	04a4d783          	lhu	a5,74(s1)
    8000577a:	37fd                	addiw	a5,a5,-1
    8000577c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005780:	8526                	mv	a0,s1
    80005782:	ffffe097          	auipc	ra,0xffffe
    80005786:	1a0080e7          	jalr	416(ra) # 80003922 <iupdate>
  iunlockput(ip);
    8000578a:	8526                	mv	a0,s1
    8000578c:	ffffe097          	auipc	ra,0xffffe
    80005790:	4c2080e7          	jalr	1218(ra) # 80003c4e <iunlockput>
  end_op();
    80005794:	fffff097          	auipc	ra,0xfffff
    80005798:	c9a080e7          	jalr	-870(ra) # 8000442e <end_op>
  return -1;
    8000579c:	57fd                	li	a5,-1
}
    8000579e:	853e                	mv	a0,a5
    800057a0:	70b2                	ld	ra,296(sp)
    800057a2:	7412                	ld	s0,288(sp)
    800057a4:	64f2                	ld	s1,280(sp)
    800057a6:	6952                	ld	s2,272(sp)
    800057a8:	6155                	addi	sp,sp,304
    800057aa:	8082                	ret

00000000800057ac <sys_unlink>:
{
    800057ac:	7151                	addi	sp,sp,-240
    800057ae:	f586                	sd	ra,232(sp)
    800057b0:	f1a2                	sd	s0,224(sp)
    800057b2:	eda6                	sd	s1,216(sp)
    800057b4:	e9ca                	sd	s2,208(sp)
    800057b6:	e5ce                	sd	s3,200(sp)
    800057b8:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800057ba:	08000613          	li	a2,128
    800057be:	f3040593          	addi	a1,s0,-208
    800057c2:	4501                	li	a0,0
    800057c4:	ffffd097          	auipc	ra,0xffffd
    800057c8:	3f0080e7          	jalr	1008(ra) # 80002bb4 <argstr>
    800057cc:	18054163          	bltz	a0,8000594e <sys_unlink+0x1a2>
  begin_op();
    800057d0:	fffff097          	auipc	ra,0xfffff
    800057d4:	bde080e7          	jalr	-1058(ra) # 800043ae <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800057d8:	fb040593          	addi	a1,s0,-80
    800057dc:	f3040513          	addi	a0,s0,-208
    800057e0:	fffff097          	auipc	ra,0xfffff
    800057e4:	9d0080e7          	jalr	-1584(ra) # 800041b0 <nameiparent>
    800057e8:	84aa                	mv	s1,a0
    800057ea:	c979                	beqz	a0,800058c0 <sys_unlink+0x114>
  ilock(dp);
    800057ec:	ffffe097          	auipc	ra,0xffffe
    800057f0:	200080e7          	jalr	512(ra) # 800039ec <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800057f4:	00003597          	auipc	a1,0x3
    800057f8:	fb458593          	addi	a1,a1,-76 # 800087a8 <syscalls+0x2a8>
    800057fc:	fb040513          	addi	a0,s0,-80
    80005800:	ffffe097          	auipc	ra,0xffffe
    80005804:	6b6080e7          	jalr	1718(ra) # 80003eb6 <namecmp>
    80005808:	14050a63          	beqz	a0,8000595c <sys_unlink+0x1b0>
    8000580c:	00003597          	auipc	a1,0x3
    80005810:	fa458593          	addi	a1,a1,-92 # 800087b0 <syscalls+0x2b0>
    80005814:	fb040513          	addi	a0,s0,-80
    80005818:	ffffe097          	auipc	ra,0xffffe
    8000581c:	69e080e7          	jalr	1694(ra) # 80003eb6 <namecmp>
    80005820:	12050e63          	beqz	a0,8000595c <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005824:	f2c40613          	addi	a2,s0,-212
    80005828:	fb040593          	addi	a1,s0,-80
    8000582c:	8526                	mv	a0,s1
    8000582e:	ffffe097          	auipc	ra,0xffffe
    80005832:	6a2080e7          	jalr	1698(ra) # 80003ed0 <dirlookup>
    80005836:	892a                	mv	s2,a0
    80005838:	12050263          	beqz	a0,8000595c <sys_unlink+0x1b0>
  ilock(ip);
    8000583c:	ffffe097          	auipc	ra,0xffffe
    80005840:	1b0080e7          	jalr	432(ra) # 800039ec <ilock>
  if(ip->nlink < 1)
    80005844:	04a91783          	lh	a5,74(s2)
    80005848:	08f05263          	blez	a5,800058cc <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000584c:	04491703          	lh	a4,68(s2)
    80005850:	4785                	li	a5,1
    80005852:	08f70563          	beq	a4,a5,800058dc <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005856:	4641                	li	a2,16
    80005858:	4581                	li	a1,0
    8000585a:	fc040513          	addi	a0,s0,-64
    8000585e:	ffffb097          	auipc	ra,0xffffb
    80005862:	488080e7          	jalr	1160(ra) # 80000ce6 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005866:	4741                	li	a4,16
    80005868:	f2c42683          	lw	a3,-212(s0)
    8000586c:	fc040613          	addi	a2,s0,-64
    80005870:	4581                	li	a1,0
    80005872:	8526                	mv	a0,s1
    80005874:	ffffe097          	auipc	ra,0xffffe
    80005878:	524080e7          	jalr	1316(ra) # 80003d98 <writei>
    8000587c:	47c1                	li	a5,16
    8000587e:	0af51563          	bne	a0,a5,80005928 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005882:	04491703          	lh	a4,68(s2)
    80005886:	4785                	li	a5,1
    80005888:	0af70863          	beq	a4,a5,80005938 <sys_unlink+0x18c>
  iunlockput(dp);
    8000588c:	8526                	mv	a0,s1
    8000588e:	ffffe097          	auipc	ra,0xffffe
    80005892:	3c0080e7          	jalr	960(ra) # 80003c4e <iunlockput>
  ip->nlink--;
    80005896:	04a95783          	lhu	a5,74(s2)
    8000589a:	37fd                	addiw	a5,a5,-1
    8000589c:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800058a0:	854a                	mv	a0,s2
    800058a2:	ffffe097          	auipc	ra,0xffffe
    800058a6:	080080e7          	jalr	128(ra) # 80003922 <iupdate>
  iunlockput(ip);
    800058aa:	854a                	mv	a0,s2
    800058ac:	ffffe097          	auipc	ra,0xffffe
    800058b0:	3a2080e7          	jalr	930(ra) # 80003c4e <iunlockput>
  end_op();
    800058b4:	fffff097          	auipc	ra,0xfffff
    800058b8:	b7a080e7          	jalr	-1158(ra) # 8000442e <end_op>
  return 0;
    800058bc:	4501                	li	a0,0
    800058be:	a84d                	j	80005970 <sys_unlink+0x1c4>
    end_op();
    800058c0:	fffff097          	auipc	ra,0xfffff
    800058c4:	b6e080e7          	jalr	-1170(ra) # 8000442e <end_op>
    return -1;
    800058c8:	557d                	li	a0,-1
    800058ca:	a05d                	j	80005970 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800058cc:	00003517          	auipc	a0,0x3
    800058d0:	eec50513          	addi	a0,a0,-276 # 800087b8 <syscalls+0x2b8>
    800058d4:	ffffb097          	auipc	ra,0xffffb
    800058d8:	c70080e7          	jalr	-912(ra) # 80000544 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800058dc:	04c92703          	lw	a4,76(s2)
    800058e0:	02000793          	li	a5,32
    800058e4:	f6e7f9e3          	bgeu	a5,a4,80005856 <sys_unlink+0xaa>
    800058e8:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800058ec:	4741                	li	a4,16
    800058ee:	86ce                	mv	a3,s3
    800058f0:	f1840613          	addi	a2,s0,-232
    800058f4:	4581                	li	a1,0
    800058f6:	854a                	mv	a0,s2
    800058f8:	ffffe097          	auipc	ra,0xffffe
    800058fc:	3a8080e7          	jalr	936(ra) # 80003ca0 <readi>
    80005900:	47c1                	li	a5,16
    80005902:	00f51b63          	bne	a0,a5,80005918 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005906:	f1845783          	lhu	a5,-232(s0)
    8000590a:	e7a1                	bnez	a5,80005952 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000590c:	29c1                	addiw	s3,s3,16
    8000590e:	04c92783          	lw	a5,76(s2)
    80005912:	fcf9ede3          	bltu	s3,a5,800058ec <sys_unlink+0x140>
    80005916:	b781                	j	80005856 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005918:	00003517          	auipc	a0,0x3
    8000591c:	eb850513          	addi	a0,a0,-328 # 800087d0 <syscalls+0x2d0>
    80005920:	ffffb097          	auipc	ra,0xffffb
    80005924:	c24080e7          	jalr	-988(ra) # 80000544 <panic>
    panic("unlink: writei");
    80005928:	00003517          	auipc	a0,0x3
    8000592c:	ec050513          	addi	a0,a0,-320 # 800087e8 <syscalls+0x2e8>
    80005930:	ffffb097          	auipc	ra,0xffffb
    80005934:	c14080e7          	jalr	-1004(ra) # 80000544 <panic>
    dp->nlink--;
    80005938:	04a4d783          	lhu	a5,74(s1)
    8000593c:	37fd                	addiw	a5,a5,-1
    8000593e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005942:	8526                	mv	a0,s1
    80005944:	ffffe097          	auipc	ra,0xffffe
    80005948:	fde080e7          	jalr	-34(ra) # 80003922 <iupdate>
    8000594c:	b781                	j	8000588c <sys_unlink+0xe0>
    return -1;
    8000594e:	557d                	li	a0,-1
    80005950:	a005                	j	80005970 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005952:	854a                	mv	a0,s2
    80005954:	ffffe097          	auipc	ra,0xffffe
    80005958:	2fa080e7          	jalr	762(ra) # 80003c4e <iunlockput>
  iunlockput(dp);
    8000595c:	8526                	mv	a0,s1
    8000595e:	ffffe097          	auipc	ra,0xffffe
    80005962:	2f0080e7          	jalr	752(ra) # 80003c4e <iunlockput>
  end_op();
    80005966:	fffff097          	auipc	ra,0xfffff
    8000596a:	ac8080e7          	jalr	-1336(ra) # 8000442e <end_op>
  return -1;
    8000596e:	557d                	li	a0,-1
}
    80005970:	70ae                	ld	ra,232(sp)
    80005972:	740e                	ld	s0,224(sp)
    80005974:	64ee                	ld	s1,216(sp)
    80005976:	694e                	ld	s2,208(sp)
    80005978:	69ae                	ld	s3,200(sp)
    8000597a:	616d                	addi	sp,sp,240
    8000597c:	8082                	ret

000000008000597e <sys_open>:

uint64
sys_open(void)
{
    8000597e:	7131                	addi	sp,sp,-192
    80005980:	fd06                	sd	ra,184(sp)
    80005982:	f922                	sd	s0,176(sp)
    80005984:	f526                	sd	s1,168(sp)
    80005986:	f14a                	sd	s2,160(sp)
    80005988:	ed4e                	sd	s3,152(sp)
    8000598a:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    8000598c:	f4c40593          	addi	a1,s0,-180
    80005990:	4505                	li	a0,1
    80005992:	ffffd097          	auipc	ra,0xffffd
    80005996:	1e2080e7          	jalr	482(ra) # 80002b74 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000599a:	08000613          	li	a2,128
    8000599e:	f5040593          	addi	a1,s0,-176
    800059a2:	4501                	li	a0,0
    800059a4:	ffffd097          	auipc	ra,0xffffd
    800059a8:	210080e7          	jalr	528(ra) # 80002bb4 <argstr>
    800059ac:	87aa                	mv	a5,a0
    return -1;
    800059ae:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    800059b0:	0a07c963          	bltz	a5,80005a62 <sys_open+0xe4>

  begin_op();
    800059b4:	fffff097          	auipc	ra,0xfffff
    800059b8:	9fa080e7          	jalr	-1542(ra) # 800043ae <begin_op>

  if(omode & O_CREATE){
    800059bc:	f4c42783          	lw	a5,-180(s0)
    800059c0:	2007f793          	andi	a5,a5,512
    800059c4:	cfc5                	beqz	a5,80005a7c <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800059c6:	4681                	li	a3,0
    800059c8:	4601                	li	a2,0
    800059ca:	4589                	li	a1,2
    800059cc:	f5040513          	addi	a0,s0,-176
    800059d0:	00000097          	auipc	ra,0x0
    800059d4:	974080e7          	jalr	-1676(ra) # 80005344 <create>
    800059d8:	84aa                	mv	s1,a0
    if(ip == 0){
    800059da:	c959                	beqz	a0,80005a70 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800059dc:	04449703          	lh	a4,68(s1)
    800059e0:	478d                	li	a5,3
    800059e2:	00f71763          	bne	a4,a5,800059f0 <sys_open+0x72>
    800059e6:	0464d703          	lhu	a4,70(s1)
    800059ea:	47a5                	li	a5,9
    800059ec:	0ce7ed63          	bltu	a5,a4,80005ac6 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800059f0:	fffff097          	auipc	ra,0xfffff
    800059f4:	dce080e7          	jalr	-562(ra) # 800047be <filealloc>
    800059f8:	89aa                	mv	s3,a0
    800059fa:	10050363          	beqz	a0,80005b00 <sys_open+0x182>
    800059fe:	00000097          	auipc	ra,0x0
    80005a02:	904080e7          	jalr	-1788(ra) # 80005302 <fdalloc>
    80005a06:	892a                	mv	s2,a0
    80005a08:	0e054763          	bltz	a0,80005af6 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005a0c:	04449703          	lh	a4,68(s1)
    80005a10:	478d                	li	a5,3
    80005a12:	0cf70563          	beq	a4,a5,80005adc <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005a16:	4789                	li	a5,2
    80005a18:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005a1c:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005a20:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005a24:	f4c42783          	lw	a5,-180(s0)
    80005a28:	0017c713          	xori	a4,a5,1
    80005a2c:	8b05                	andi	a4,a4,1
    80005a2e:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005a32:	0037f713          	andi	a4,a5,3
    80005a36:	00e03733          	snez	a4,a4
    80005a3a:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005a3e:	4007f793          	andi	a5,a5,1024
    80005a42:	c791                	beqz	a5,80005a4e <sys_open+0xd0>
    80005a44:	04449703          	lh	a4,68(s1)
    80005a48:	4789                	li	a5,2
    80005a4a:	0af70063          	beq	a4,a5,80005aea <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005a4e:	8526                	mv	a0,s1
    80005a50:	ffffe097          	auipc	ra,0xffffe
    80005a54:	05e080e7          	jalr	94(ra) # 80003aae <iunlock>
  end_op();
    80005a58:	fffff097          	auipc	ra,0xfffff
    80005a5c:	9d6080e7          	jalr	-1578(ra) # 8000442e <end_op>

  return fd;
    80005a60:	854a                	mv	a0,s2
}
    80005a62:	70ea                	ld	ra,184(sp)
    80005a64:	744a                	ld	s0,176(sp)
    80005a66:	74aa                	ld	s1,168(sp)
    80005a68:	790a                	ld	s2,160(sp)
    80005a6a:	69ea                	ld	s3,152(sp)
    80005a6c:	6129                	addi	sp,sp,192
    80005a6e:	8082                	ret
      end_op();
    80005a70:	fffff097          	auipc	ra,0xfffff
    80005a74:	9be080e7          	jalr	-1602(ra) # 8000442e <end_op>
      return -1;
    80005a78:	557d                	li	a0,-1
    80005a7a:	b7e5                	j	80005a62 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005a7c:	f5040513          	addi	a0,s0,-176
    80005a80:	ffffe097          	auipc	ra,0xffffe
    80005a84:	712080e7          	jalr	1810(ra) # 80004192 <namei>
    80005a88:	84aa                	mv	s1,a0
    80005a8a:	c905                	beqz	a0,80005aba <sys_open+0x13c>
    ilock(ip);
    80005a8c:	ffffe097          	auipc	ra,0xffffe
    80005a90:	f60080e7          	jalr	-160(ra) # 800039ec <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005a94:	04449703          	lh	a4,68(s1)
    80005a98:	4785                	li	a5,1
    80005a9a:	f4f711e3          	bne	a4,a5,800059dc <sys_open+0x5e>
    80005a9e:	f4c42783          	lw	a5,-180(s0)
    80005aa2:	d7b9                	beqz	a5,800059f0 <sys_open+0x72>
      iunlockput(ip);
    80005aa4:	8526                	mv	a0,s1
    80005aa6:	ffffe097          	auipc	ra,0xffffe
    80005aaa:	1a8080e7          	jalr	424(ra) # 80003c4e <iunlockput>
      end_op();
    80005aae:	fffff097          	auipc	ra,0xfffff
    80005ab2:	980080e7          	jalr	-1664(ra) # 8000442e <end_op>
      return -1;
    80005ab6:	557d                	li	a0,-1
    80005ab8:	b76d                	j	80005a62 <sys_open+0xe4>
      end_op();
    80005aba:	fffff097          	auipc	ra,0xfffff
    80005abe:	974080e7          	jalr	-1676(ra) # 8000442e <end_op>
      return -1;
    80005ac2:	557d                	li	a0,-1
    80005ac4:	bf79                	j	80005a62 <sys_open+0xe4>
    iunlockput(ip);
    80005ac6:	8526                	mv	a0,s1
    80005ac8:	ffffe097          	auipc	ra,0xffffe
    80005acc:	186080e7          	jalr	390(ra) # 80003c4e <iunlockput>
    end_op();
    80005ad0:	fffff097          	auipc	ra,0xfffff
    80005ad4:	95e080e7          	jalr	-1698(ra) # 8000442e <end_op>
    return -1;
    80005ad8:	557d                	li	a0,-1
    80005ada:	b761                	j	80005a62 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005adc:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005ae0:	04649783          	lh	a5,70(s1)
    80005ae4:	02f99223          	sh	a5,36(s3)
    80005ae8:	bf25                	j	80005a20 <sys_open+0xa2>
    itrunc(ip);
    80005aea:	8526                	mv	a0,s1
    80005aec:	ffffe097          	auipc	ra,0xffffe
    80005af0:	00e080e7          	jalr	14(ra) # 80003afa <itrunc>
    80005af4:	bfa9                	j	80005a4e <sys_open+0xd0>
      fileclose(f);
    80005af6:	854e                	mv	a0,s3
    80005af8:	fffff097          	auipc	ra,0xfffff
    80005afc:	d82080e7          	jalr	-638(ra) # 8000487a <fileclose>
    iunlockput(ip);
    80005b00:	8526                	mv	a0,s1
    80005b02:	ffffe097          	auipc	ra,0xffffe
    80005b06:	14c080e7          	jalr	332(ra) # 80003c4e <iunlockput>
    end_op();
    80005b0a:	fffff097          	auipc	ra,0xfffff
    80005b0e:	924080e7          	jalr	-1756(ra) # 8000442e <end_op>
    return -1;
    80005b12:	557d                	li	a0,-1
    80005b14:	b7b9                	j	80005a62 <sys_open+0xe4>

0000000080005b16 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005b16:	7175                	addi	sp,sp,-144
    80005b18:	e506                	sd	ra,136(sp)
    80005b1a:	e122                	sd	s0,128(sp)
    80005b1c:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005b1e:	fffff097          	auipc	ra,0xfffff
    80005b22:	890080e7          	jalr	-1904(ra) # 800043ae <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005b26:	08000613          	li	a2,128
    80005b2a:	f7040593          	addi	a1,s0,-144
    80005b2e:	4501                	li	a0,0
    80005b30:	ffffd097          	auipc	ra,0xffffd
    80005b34:	084080e7          	jalr	132(ra) # 80002bb4 <argstr>
    80005b38:	02054963          	bltz	a0,80005b6a <sys_mkdir+0x54>
    80005b3c:	4681                	li	a3,0
    80005b3e:	4601                	li	a2,0
    80005b40:	4585                	li	a1,1
    80005b42:	f7040513          	addi	a0,s0,-144
    80005b46:	fffff097          	auipc	ra,0xfffff
    80005b4a:	7fe080e7          	jalr	2046(ra) # 80005344 <create>
    80005b4e:	cd11                	beqz	a0,80005b6a <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b50:	ffffe097          	auipc	ra,0xffffe
    80005b54:	0fe080e7          	jalr	254(ra) # 80003c4e <iunlockput>
  end_op();
    80005b58:	fffff097          	auipc	ra,0xfffff
    80005b5c:	8d6080e7          	jalr	-1834(ra) # 8000442e <end_op>
  return 0;
    80005b60:	4501                	li	a0,0
}
    80005b62:	60aa                	ld	ra,136(sp)
    80005b64:	640a                	ld	s0,128(sp)
    80005b66:	6149                	addi	sp,sp,144
    80005b68:	8082                	ret
    end_op();
    80005b6a:	fffff097          	auipc	ra,0xfffff
    80005b6e:	8c4080e7          	jalr	-1852(ra) # 8000442e <end_op>
    return -1;
    80005b72:	557d                	li	a0,-1
    80005b74:	b7fd                	j	80005b62 <sys_mkdir+0x4c>

0000000080005b76 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005b76:	7135                	addi	sp,sp,-160
    80005b78:	ed06                	sd	ra,152(sp)
    80005b7a:	e922                	sd	s0,144(sp)
    80005b7c:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005b7e:	fffff097          	auipc	ra,0xfffff
    80005b82:	830080e7          	jalr	-2000(ra) # 800043ae <begin_op>
  argint(1, &major);
    80005b86:	f6c40593          	addi	a1,s0,-148
    80005b8a:	4505                	li	a0,1
    80005b8c:	ffffd097          	auipc	ra,0xffffd
    80005b90:	fe8080e7          	jalr	-24(ra) # 80002b74 <argint>
  argint(2, &minor);
    80005b94:	f6840593          	addi	a1,s0,-152
    80005b98:	4509                	li	a0,2
    80005b9a:	ffffd097          	auipc	ra,0xffffd
    80005b9e:	fda080e7          	jalr	-38(ra) # 80002b74 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ba2:	08000613          	li	a2,128
    80005ba6:	f7040593          	addi	a1,s0,-144
    80005baa:	4501                	li	a0,0
    80005bac:	ffffd097          	auipc	ra,0xffffd
    80005bb0:	008080e7          	jalr	8(ra) # 80002bb4 <argstr>
    80005bb4:	02054b63          	bltz	a0,80005bea <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005bb8:	f6841683          	lh	a3,-152(s0)
    80005bbc:	f6c41603          	lh	a2,-148(s0)
    80005bc0:	458d                	li	a1,3
    80005bc2:	f7040513          	addi	a0,s0,-144
    80005bc6:	fffff097          	auipc	ra,0xfffff
    80005bca:	77e080e7          	jalr	1918(ra) # 80005344 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005bce:	cd11                	beqz	a0,80005bea <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005bd0:	ffffe097          	auipc	ra,0xffffe
    80005bd4:	07e080e7          	jalr	126(ra) # 80003c4e <iunlockput>
  end_op();
    80005bd8:	fffff097          	auipc	ra,0xfffff
    80005bdc:	856080e7          	jalr	-1962(ra) # 8000442e <end_op>
  return 0;
    80005be0:	4501                	li	a0,0
}
    80005be2:	60ea                	ld	ra,152(sp)
    80005be4:	644a                	ld	s0,144(sp)
    80005be6:	610d                	addi	sp,sp,160
    80005be8:	8082                	ret
    end_op();
    80005bea:	fffff097          	auipc	ra,0xfffff
    80005bee:	844080e7          	jalr	-1980(ra) # 8000442e <end_op>
    return -1;
    80005bf2:	557d                	li	a0,-1
    80005bf4:	b7fd                	j	80005be2 <sys_mknod+0x6c>

0000000080005bf6 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005bf6:	7135                	addi	sp,sp,-160
    80005bf8:	ed06                	sd	ra,152(sp)
    80005bfa:	e922                	sd	s0,144(sp)
    80005bfc:	e526                	sd	s1,136(sp)
    80005bfe:	e14a                	sd	s2,128(sp)
    80005c00:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005c02:	ffffc097          	auipc	ra,0xffffc
    80005c06:	dc4080e7          	jalr	-572(ra) # 800019c6 <myproc>
    80005c0a:	892a                	mv	s2,a0
  
  begin_op();
    80005c0c:	ffffe097          	auipc	ra,0xffffe
    80005c10:	7a2080e7          	jalr	1954(ra) # 800043ae <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005c14:	08000613          	li	a2,128
    80005c18:	f6040593          	addi	a1,s0,-160
    80005c1c:	4501                	li	a0,0
    80005c1e:	ffffd097          	auipc	ra,0xffffd
    80005c22:	f96080e7          	jalr	-106(ra) # 80002bb4 <argstr>
    80005c26:	04054b63          	bltz	a0,80005c7c <sys_chdir+0x86>
    80005c2a:	f6040513          	addi	a0,s0,-160
    80005c2e:	ffffe097          	auipc	ra,0xffffe
    80005c32:	564080e7          	jalr	1380(ra) # 80004192 <namei>
    80005c36:	84aa                	mv	s1,a0
    80005c38:	c131                	beqz	a0,80005c7c <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005c3a:	ffffe097          	auipc	ra,0xffffe
    80005c3e:	db2080e7          	jalr	-590(ra) # 800039ec <ilock>
  if(ip->type != T_DIR){
    80005c42:	04449703          	lh	a4,68(s1)
    80005c46:	4785                	li	a5,1
    80005c48:	04f71063          	bne	a4,a5,80005c88 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005c4c:	8526                	mv	a0,s1
    80005c4e:	ffffe097          	auipc	ra,0xffffe
    80005c52:	e60080e7          	jalr	-416(ra) # 80003aae <iunlock>
  iput(p->cwd);
    80005c56:	15093503          	ld	a0,336(s2)
    80005c5a:	ffffe097          	auipc	ra,0xffffe
    80005c5e:	f4c080e7          	jalr	-180(ra) # 80003ba6 <iput>
  end_op();
    80005c62:	ffffe097          	auipc	ra,0xffffe
    80005c66:	7cc080e7          	jalr	1996(ra) # 8000442e <end_op>
  p->cwd = ip;
    80005c6a:	14993823          	sd	s1,336(s2)
  return 0;
    80005c6e:	4501                	li	a0,0
}
    80005c70:	60ea                	ld	ra,152(sp)
    80005c72:	644a                	ld	s0,144(sp)
    80005c74:	64aa                	ld	s1,136(sp)
    80005c76:	690a                	ld	s2,128(sp)
    80005c78:	610d                	addi	sp,sp,160
    80005c7a:	8082                	ret
    end_op();
    80005c7c:	ffffe097          	auipc	ra,0xffffe
    80005c80:	7b2080e7          	jalr	1970(ra) # 8000442e <end_op>
    return -1;
    80005c84:	557d                	li	a0,-1
    80005c86:	b7ed                	j	80005c70 <sys_chdir+0x7a>
    iunlockput(ip);
    80005c88:	8526                	mv	a0,s1
    80005c8a:	ffffe097          	auipc	ra,0xffffe
    80005c8e:	fc4080e7          	jalr	-60(ra) # 80003c4e <iunlockput>
    end_op();
    80005c92:	ffffe097          	auipc	ra,0xffffe
    80005c96:	79c080e7          	jalr	1948(ra) # 8000442e <end_op>
    return -1;
    80005c9a:	557d                	li	a0,-1
    80005c9c:	bfd1                	j	80005c70 <sys_chdir+0x7a>

0000000080005c9e <sys_exec>:

uint64
sys_exec(void)
{
    80005c9e:	7145                	addi	sp,sp,-464
    80005ca0:	e786                	sd	ra,456(sp)
    80005ca2:	e3a2                	sd	s0,448(sp)
    80005ca4:	ff26                	sd	s1,440(sp)
    80005ca6:	fb4a                	sd	s2,432(sp)
    80005ca8:	f74e                	sd	s3,424(sp)
    80005caa:	f352                	sd	s4,416(sp)
    80005cac:	ef56                	sd	s5,408(sp)
    80005cae:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005cb0:	e3840593          	addi	a1,s0,-456
    80005cb4:	4505                	li	a0,1
    80005cb6:	ffffd097          	auipc	ra,0xffffd
    80005cba:	ede080e7          	jalr	-290(ra) # 80002b94 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005cbe:	08000613          	li	a2,128
    80005cc2:	f4040593          	addi	a1,s0,-192
    80005cc6:	4501                	li	a0,0
    80005cc8:	ffffd097          	auipc	ra,0xffffd
    80005ccc:	eec080e7          	jalr	-276(ra) # 80002bb4 <argstr>
    80005cd0:	87aa                	mv	a5,a0
    return -1;
    80005cd2:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005cd4:	0c07c263          	bltz	a5,80005d98 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005cd8:	10000613          	li	a2,256
    80005cdc:	4581                	li	a1,0
    80005cde:	e4040513          	addi	a0,s0,-448
    80005ce2:	ffffb097          	auipc	ra,0xffffb
    80005ce6:	004080e7          	jalr	4(ra) # 80000ce6 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005cea:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005cee:	89a6                	mv	s3,s1
    80005cf0:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005cf2:	02000a13          	li	s4,32
    80005cf6:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005cfa:	00391513          	slli	a0,s2,0x3
    80005cfe:	e3040593          	addi	a1,s0,-464
    80005d02:	e3843783          	ld	a5,-456(s0)
    80005d06:	953e                	add	a0,a0,a5
    80005d08:	ffffd097          	auipc	ra,0xffffd
    80005d0c:	dce080e7          	jalr	-562(ra) # 80002ad6 <fetchaddr>
    80005d10:	02054a63          	bltz	a0,80005d44 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005d14:	e3043783          	ld	a5,-464(s0)
    80005d18:	c3b9                	beqz	a5,80005d5e <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005d1a:	ffffb097          	auipc	ra,0xffffb
    80005d1e:	de0080e7          	jalr	-544(ra) # 80000afa <kalloc>
    80005d22:	85aa                	mv	a1,a0
    80005d24:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005d28:	cd11                	beqz	a0,80005d44 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005d2a:	6605                	lui	a2,0x1
    80005d2c:	e3043503          	ld	a0,-464(s0)
    80005d30:	ffffd097          	auipc	ra,0xffffd
    80005d34:	df8080e7          	jalr	-520(ra) # 80002b28 <fetchstr>
    80005d38:	00054663          	bltz	a0,80005d44 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005d3c:	0905                	addi	s2,s2,1
    80005d3e:	09a1                	addi	s3,s3,8
    80005d40:	fb491be3          	bne	s2,s4,80005cf6 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d44:	10048913          	addi	s2,s1,256
    80005d48:	6088                	ld	a0,0(s1)
    80005d4a:	c531                	beqz	a0,80005d96 <sys_exec+0xf8>
    kfree(argv[i]);
    80005d4c:	ffffb097          	auipc	ra,0xffffb
    80005d50:	cb2080e7          	jalr	-846(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d54:	04a1                	addi	s1,s1,8
    80005d56:	ff2499e3          	bne	s1,s2,80005d48 <sys_exec+0xaa>
  return -1;
    80005d5a:	557d                	li	a0,-1
    80005d5c:	a835                	j	80005d98 <sys_exec+0xfa>
      argv[i] = 0;
    80005d5e:	0a8e                	slli	s5,s5,0x3
    80005d60:	fc040793          	addi	a5,s0,-64
    80005d64:	9abe                	add	s5,s5,a5
    80005d66:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005d6a:	e4040593          	addi	a1,s0,-448
    80005d6e:	f4040513          	addi	a0,s0,-192
    80005d72:	fffff097          	auipc	ra,0xfffff
    80005d76:	190080e7          	jalr	400(ra) # 80004f02 <exec>
    80005d7a:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d7c:	10048993          	addi	s3,s1,256
    80005d80:	6088                	ld	a0,0(s1)
    80005d82:	c901                	beqz	a0,80005d92 <sys_exec+0xf4>
    kfree(argv[i]);
    80005d84:	ffffb097          	auipc	ra,0xffffb
    80005d88:	c7a080e7          	jalr	-902(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d8c:	04a1                	addi	s1,s1,8
    80005d8e:	ff3499e3          	bne	s1,s3,80005d80 <sys_exec+0xe2>
  return ret;
    80005d92:	854a                	mv	a0,s2
    80005d94:	a011                	j	80005d98 <sys_exec+0xfa>
  return -1;
    80005d96:	557d                	li	a0,-1
}
    80005d98:	60be                	ld	ra,456(sp)
    80005d9a:	641e                	ld	s0,448(sp)
    80005d9c:	74fa                	ld	s1,440(sp)
    80005d9e:	795a                	ld	s2,432(sp)
    80005da0:	79ba                	ld	s3,424(sp)
    80005da2:	7a1a                	ld	s4,416(sp)
    80005da4:	6afa                	ld	s5,408(sp)
    80005da6:	6179                	addi	sp,sp,464
    80005da8:	8082                	ret

0000000080005daa <sys_pipe>:

uint64
sys_pipe(void)
{
    80005daa:	7139                	addi	sp,sp,-64
    80005dac:	fc06                	sd	ra,56(sp)
    80005dae:	f822                	sd	s0,48(sp)
    80005db0:	f426                	sd	s1,40(sp)
    80005db2:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005db4:	ffffc097          	auipc	ra,0xffffc
    80005db8:	c12080e7          	jalr	-1006(ra) # 800019c6 <myproc>
    80005dbc:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005dbe:	fd840593          	addi	a1,s0,-40
    80005dc2:	4501                	li	a0,0
    80005dc4:	ffffd097          	auipc	ra,0xffffd
    80005dc8:	dd0080e7          	jalr	-560(ra) # 80002b94 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005dcc:	fc840593          	addi	a1,s0,-56
    80005dd0:	fd040513          	addi	a0,s0,-48
    80005dd4:	fffff097          	auipc	ra,0xfffff
    80005dd8:	dd6080e7          	jalr	-554(ra) # 80004baa <pipealloc>
    return -1;
    80005ddc:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005dde:	0c054463          	bltz	a0,80005ea6 <sys_pipe+0xfc>
  fd0 = -1;
    80005de2:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005de6:	fd043503          	ld	a0,-48(s0)
    80005dea:	fffff097          	auipc	ra,0xfffff
    80005dee:	518080e7          	jalr	1304(ra) # 80005302 <fdalloc>
    80005df2:	fca42223          	sw	a0,-60(s0)
    80005df6:	08054b63          	bltz	a0,80005e8c <sys_pipe+0xe2>
    80005dfa:	fc843503          	ld	a0,-56(s0)
    80005dfe:	fffff097          	auipc	ra,0xfffff
    80005e02:	504080e7          	jalr	1284(ra) # 80005302 <fdalloc>
    80005e06:	fca42023          	sw	a0,-64(s0)
    80005e0a:	06054863          	bltz	a0,80005e7a <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e0e:	4691                	li	a3,4
    80005e10:	fc440613          	addi	a2,s0,-60
    80005e14:	fd843583          	ld	a1,-40(s0)
    80005e18:	68a8                	ld	a0,80(s1)
    80005e1a:	ffffc097          	auipc	ra,0xffffc
    80005e1e:	86a080e7          	jalr	-1942(ra) # 80001684 <copyout>
    80005e22:	02054063          	bltz	a0,80005e42 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005e26:	4691                	li	a3,4
    80005e28:	fc040613          	addi	a2,s0,-64
    80005e2c:	fd843583          	ld	a1,-40(s0)
    80005e30:	0591                	addi	a1,a1,4
    80005e32:	68a8                	ld	a0,80(s1)
    80005e34:	ffffc097          	auipc	ra,0xffffc
    80005e38:	850080e7          	jalr	-1968(ra) # 80001684 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005e3c:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e3e:	06055463          	bgez	a0,80005ea6 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005e42:	fc442783          	lw	a5,-60(s0)
    80005e46:	07e9                	addi	a5,a5,26
    80005e48:	078e                	slli	a5,a5,0x3
    80005e4a:	97a6                	add	a5,a5,s1
    80005e4c:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005e50:	fc042503          	lw	a0,-64(s0)
    80005e54:	0569                	addi	a0,a0,26
    80005e56:	050e                	slli	a0,a0,0x3
    80005e58:	94aa                	add	s1,s1,a0
    80005e5a:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005e5e:	fd043503          	ld	a0,-48(s0)
    80005e62:	fffff097          	auipc	ra,0xfffff
    80005e66:	a18080e7          	jalr	-1512(ra) # 8000487a <fileclose>
    fileclose(wf);
    80005e6a:	fc843503          	ld	a0,-56(s0)
    80005e6e:	fffff097          	auipc	ra,0xfffff
    80005e72:	a0c080e7          	jalr	-1524(ra) # 8000487a <fileclose>
    return -1;
    80005e76:	57fd                	li	a5,-1
    80005e78:	a03d                	j	80005ea6 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005e7a:	fc442783          	lw	a5,-60(s0)
    80005e7e:	0007c763          	bltz	a5,80005e8c <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005e82:	07e9                	addi	a5,a5,26
    80005e84:	078e                	slli	a5,a5,0x3
    80005e86:	94be                	add	s1,s1,a5
    80005e88:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005e8c:	fd043503          	ld	a0,-48(s0)
    80005e90:	fffff097          	auipc	ra,0xfffff
    80005e94:	9ea080e7          	jalr	-1558(ra) # 8000487a <fileclose>
    fileclose(wf);
    80005e98:	fc843503          	ld	a0,-56(s0)
    80005e9c:	fffff097          	auipc	ra,0xfffff
    80005ea0:	9de080e7          	jalr	-1570(ra) # 8000487a <fileclose>
    return -1;
    80005ea4:	57fd                	li	a5,-1
}
    80005ea6:	853e                	mv	a0,a5
    80005ea8:	70e2                	ld	ra,56(sp)
    80005eaa:	7442                	ld	s0,48(sp)
    80005eac:	74a2                	ld	s1,40(sp)
    80005eae:	6121                	addi	sp,sp,64
    80005eb0:	8082                	ret
	...

0000000080005ec0 <kernelvec>:
    80005ec0:	7111                	addi	sp,sp,-256
    80005ec2:	e006                	sd	ra,0(sp)
    80005ec4:	e40a                	sd	sp,8(sp)
    80005ec6:	e80e                	sd	gp,16(sp)
    80005ec8:	ec12                	sd	tp,24(sp)
    80005eca:	f016                	sd	t0,32(sp)
    80005ecc:	f41a                	sd	t1,40(sp)
    80005ece:	f81e                	sd	t2,48(sp)
    80005ed0:	fc22                	sd	s0,56(sp)
    80005ed2:	e0a6                	sd	s1,64(sp)
    80005ed4:	e4aa                	sd	a0,72(sp)
    80005ed6:	e8ae                	sd	a1,80(sp)
    80005ed8:	ecb2                	sd	a2,88(sp)
    80005eda:	f0b6                	sd	a3,96(sp)
    80005edc:	f4ba                	sd	a4,104(sp)
    80005ede:	f8be                	sd	a5,112(sp)
    80005ee0:	fcc2                	sd	a6,120(sp)
    80005ee2:	e146                	sd	a7,128(sp)
    80005ee4:	e54a                	sd	s2,136(sp)
    80005ee6:	e94e                	sd	s3,144(sp)
    80005ee8:	ed52                	sd	s4,152(sp)
    80005eea:	f156                	sd	s5,160(sp)
    80005eec:	f55a                	sd	s6,168(sp)
    80005eee:	f95e                	sd	s7,176(sp)
    80005ef0:	fd62                	sd	s8,184(sp)
    80005ef2:	e1e6                	sd	s9,192(sp)
    80005ef4:	e5ea                	sd	s10,200(sp)
    80005ef6:	e9ee                	sd	s11,208(sp)
    80005ef8:	edf2                	sd	t3,216(sp)
    80005efa:	f1f6                	sd	t4,224(sp)
    80005efc:	f5fa                	sd	t5,232(sp)
    80005efe:	f9fe                	sd	t6,240(sp)
    80005f00:	aa3fc0ef          	jal	ra,800029a2 <kerneltrap>
    80005f04:	6082                	ld	ra,0(sp)
    80005f06:	6122                	ld	sp,8(sp)
    80005f08:	61c2                	ld	gp,16(sp)
    80005f0a:	7282                	ld	t0,32(sp)
    80005f0c:	7322                	ld	t1,40(sp)
    80005f0e:	73c2                	ld	t2,48(sp)
    80005f10:	7462                	ld	s0,56(sp)
    80005f12:	6486                	ld	s1,64(sp)
    80005f14:	6526                	ld	a0,72(sp)
    80005f16:	65c6                	ld	a1,80(sp)
    80005f18:	6666                	ld	a2,88(sp)
    80005f1a:	7686                	ld	a3,96(sp)
    80005f1c:	7726                	ld	a4,104(sp)
    80005f1e:	77c6                	ld	a5,112(sp)
    80005f20:	7866                	ld	a6,120(sp)
    80005f22:	688a                	ld	a7,128(sp)
    80005f24:	692a                	ld	s2,136(sp)
    80005f26:	69ca                	ld	s3,144(sp)
    80005f28:	6a6a                	ld	s4,152(sp)
    80005f2a:	7a8a                	ld	s5,160(sp)
    80005f2c:	7b2a                	ld	s6,168(sp)
    80005f2e:	7bca                	ld	s7,176(sp)
    80005f30:	7c6a                	ld	s8,184(sp)
    80005f32:	6c8e                	ld	s9,192(sp)
    80005f34:	6d2e                	ld	s10,200(sp)
    80005f36:	6dce                	ld	s11,208(sp)
    80005f38:	6e6e                	ld	t3,216(sp)
    80005f3a:	7e8e                	ld	t4,224(sp)
    80005f3c:	7f2e                	ld	t5,232(sp)
    80005f3e:	7fce                	ld	t6,240(sp)
    80005f40:	6111                	addi	sp,sp,256
    80005f42:	10200073          	sret
    80005f46:	00000013          	nop
    80005f4a:	00000013          	nop
    80005f4e:	0001                	nop

0000000080005f50 <timervec>:
    80005f50:	34051573          	csrrw	a0,mscratch,a0
    80005f54:	e10c                	sd	a1,0(a0)
    80005f56:	e510                	sd	a2,8(a0)
    80005f58:	e914                	sd	a3,16(a0)
    80005f5a:	6d0c                	ld	a1,24(a0)
    80005f5c:	7110                	ld	a2,32(a0)
    80005f5e:	6194                	ld	a3,0(a1)
    80005f60:	96b2                	add	a3,a3,a2
    80005f62:	e194                	sd	a3,0(a1)
    80005f64:	4589                	li	a1,2
    80005f66:	14459073          	csrw	sip,a1
    80005f6a:	6914                	ld	a3,16(a0)
    80005f6c:	6510                	ld	a2,8(a0)
    80005f6e:	610c                	ld	a1,0(a0)
    80005f70:	34051573          	csrrw	a0,mscratch,a0
    80005f74:	30200073          	mret
	...

0000000080005f7a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005f7a:	1141                	addi	sp,sp,-16
    80005f7c:	e422                	sd	s0,8(sp)
    80005f7e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005f80:	0c0007b7          	lui	a5,0xc000
    80005f84:	4705                	li	a4,1
    80005f86:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005f88:	c3d8                	sw	a4,4(a5)
}
    80005f8a:	6422                	ld	s0,8(sp)
    80005f8c:	0141                	addi	sp,sp,16
    80005f8e:	8082                	ret

0000000080005f90 <plicinithart>:

void
plicinithart(void)
{
    80005f90:	1141                	addi	sp,sp,-16
    80005f92:	e406                	sd	ra,8(sp)
    80005f94:	e022                	sd	s0,0(sp)
    80005f96:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f98:	ffffc097          	auipc	ra,0xffffc
    80005f9c:	a02080e7          	jalr	-1534(ra) # 8000199a <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005fa0:	0085171b          	slliw	a4,a0,0x8
    80005fa4:	0c0027b7          	lui	a5,0xc002
    80005fa8:	97ba                	add	a5,a5,a4
    80005faa:	40200713          	li	a4,1026
    80005fae:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005fb2:	00d5151b          	slliw	a0,a0,0xd
    80005fb6:	0c2017b7          	lui	a5,0xc201
    80005fba:	953e                	add	a0,a0,a5
    80005fbc:	00052023          	sw	zero,0(a0)
}
    80005fc0:	60a2                	ld	ra,8(sp)
    80005fc2:	6402                	ld	s0,0(sp)
    80005fc4:	0141                	addi	sp,sp,16
    80005fc6:	8082                	ret

0000000080005fc8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005fc8:	1141                	addi	sp,sp,-16
    80005fca:	e406                	sd	ra,8(sp)
    80005fcc:	e022                	sd	s0,0(sp)
    80005fce:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005fd0:	ffffc097          	auipc	ra,0xffffc
    80005fd4:	9ca080e7          	jalr	-1590(ra) # 8000199a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005fd8:	00d5179b          	slliw	a5,a0,0xd
    80005fdc:	0c201537          	lui	a0,0xc201
    80005fe0:	953e                	add	a0,a0,a5
  return irq;
}
    80005fe2:	4148                	lw	a0,4(a0)
    80005fe4:	60a2                	ld	ra,8(sp)
    80005fe6:	6402                	ld	s0,0(sp)
    80005fe8:	0141                	addi	sp,sp,16
    80005fea:	8082                	ret

0000000080005fec <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005fec:	1101                	addi	sp,sp,-32
    80005fee:	ec06                	sd	ra,24(sp)
    80005ff0:	e822                	sd	s0,16(sp)
    80005ff2:	e426                	sd	s1,8(sp)
    80005ff4:	1000                	addi	s0,sp,32
    80005ff6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005ff8:	ffffc097          	auipc	ra,0xffffc
    80005ffc:	9a2080e7          	jalr	-1630(ra) # 8000199a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006000:	00d5151b          	slliw	a0,a0,0xd
    80006004:	0c2017b7          	lui	a5,0xc201
    80006008:	97aa                	add	a5,a5,a0
    8000600a:	c3c4                	sw	s1,4(a5)
}
    8000600c:	60e2                	ld	ra,24(sp)
    8000600e:	6442                	ld	s0,16(sp)
    80006010:	64a2                	ld	s1,8(sp)
    80006012:	6105                	addi	sp,sp,32
    80006014:	8082                	ret

0000000080006016 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006016:	1141                	addi	sp,sp,-16
    80006018:	e406                	sd	ra,8(sp)
    8000601a:	e022                	sd	s0,0(sp)
    8000601c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000601e:	479d                	li	a5,7
    80006020:	04a7cc63          	blt	a5,a0,80006078 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006024:	00029797          	auipc	a5,0x29
    80006028:	87c78793          	addi	a5,a5,-1924 # 8002e8a0 <disk>
    8000602c:	97aa                	add	a5,a5,a0
    8000602e:	0187c783          	lbu	a5,24(a5)
    80006032:	ebb9                	bnez	a5,80006088 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006034:	00451613          	slli	a2,a0,0x4
    80006038:	00029797          	auipc	a5,0x29
    8000603c:	86878793          	addi	a5,a5,-1944 # 8002e8a0 <disk>
    80006040:	6394                	ld	a3,0(a5)
    80006042:	96b2                	add	a3,a3,a2
    80006044:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80006048:	6398                	ld	a4,0(a5)
    8000604a:	9732                	add	a4,a4,a2
    8000604c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006050:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006054:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006058:	953e                	add	a0,a0,a5
    8000605a:	4785                	li	a5,1
    8000605c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80006060:	00029517          	auipc	a0,0x29
    80006064:	85850513          	addi	a0,a0,-1960 # 8002e8b8 <disk+0x18>
    80006068:	ffffc097          	auipc	ra,0xffffc
    8000606c:	104080e7          	jalr	260(ra) # 8000216c <wakeup>
}
    80006070:	60a2                	ld	ra,8(sp)
    80006072:	6402                	ld	s0,0(sp)
    80006074:	0141                	addi	sp,sp,16
    80006076:	8082                	ret
    panic("free_desc 1");
    80006078:	00002517          	auipc	a0,0x2
    8000607c:	78050513          	addi	a0,a0,1920 # 800087f8 <syscalls+0x2f8>
    80006080:	ffffa097          	auipc	ra,0xffffa
    80006084:	4c4080e7          	jalr	1220(ra) # 80000544 <panic>
    panic("free_desc 2");
    80006088:	00002517          	auipc	a0,0x2
    8000608c:	78050513          	addi	a0,a0,1920 # 80008808 <syscalls+0x308>
    80006090:	ffffa097          	auipc	ra,0xffffa
    80006094:	4b4080e7          	jalr	1204(ra) # 80000544 <panic>

0000000080006098 <virtio_disk_init>:
{
    80006098:	1101                	addi	sp,sp,-32
    8000609a:	ec06                	sd	ra,24(sp)
    8000609c:	e822                	sd	s0,16(sp)
    8000609e:	e426                	sd	s1,8(sp)
    800060a0:	e04a                	sd	s2,0(sp)
    800060a2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800060a4:	00002597          	auipc	a1,0x2
    800060a8:	77458593          	addi	a1,a1,1908 # 80008818 <syscalls+0x318>
    800060ac:	00029517          	auipc	a0,0x29
    800060b0:	91c50513          	addi	a0,a0,-1764 # 8002e9c8 <disk+0x128>
    800060b4:	ffffb097          	auipc	ra,0xffffb
    800060b8:	aa6080e7          	jalr	-1370(ra) # 80000b5a <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800060bc:	100017b7          	lui	a5,0x10001
    800060c0:	4398                	lw	a4,0(a5)
    800060c2:	2701                	sext.w	a4,a4
    800060c4:	747277b7          	lui	a5,0x74727
    800060c8:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800060cc:	14f71e63          	bne	a4,a5,80006228 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800060d0:	100017b7          	lui	a5,0x10001
    800060d4:	43dc                	lw	a5,4(a5)
    800060d6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800060d8:	4709                	li	a4,2
    800060da:	14e79763          	bne	a5,a4,80006228 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800060de:	100017b7          	lui	a5,0x10001
    800060e2:	479c                	lw	a5,8(a5)
    800060e4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800060e6:	14e79163          	bne	a5,a4,80006228 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800060ea:	100017b7          	lui	a5,0x10001
    800060ee:	47d8                	lw	a4,12(a5)
    800060f0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800060f2:	554d47b7          	lui	a5,0x554d4
    800060f6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800060fa:	12f71763          	bne	a4,a5,80006228 <virtio_disk_init+0x190>
  *R(VIRTIO_MMIO_STATUS) = status;
    800060fe:	100017b7          	lui	a5,0x10001
    80006102:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006106:	4705                	li	a4,1
    80006108:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000610a:	470d                	li	a4,3
    8000610c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000610e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006110:	c7ffe737          	lui	a4,0xc7ffe
    80006114:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fcfd7f>
    80006118:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    8000611a:	2701                	sext.w	a4,a4
    8000611c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000611e:	472d                	li	a4,11
    80006120:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006122:	0707a903          	lw	s2,112(a5)
    80006126:	2901                	sext.w	s2,s2
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006128:	00897793          	andi	a5,s2,8
    8000612c:	10078663          	beqz	a5,80006238 <virtio_disk_init+0x1a0>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006130:	100017b7          	lui	a5,0x10001
    80006134:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006138:	43fc                	lw	a5,68(a5)
    8000613a:	2781                	sext.w	a5,a5
    8000613c:	10079663          	bnez	a5,80006248 <virtio_disk_init+0x1b0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006140:	100017b7          	lui	a5,0x10001
    80006144:	5bdc                	lw	a5,52(a5)
    80006146:	2781                	sext.w	a5,a5
  if(max == 0)
    80006148:	10078863          	beqz	a5,80006258 <virtio_disk_init+0x1c0>
  if(max < NUM)
    8000614c:	471d                	li	a4,7
    8000614e:	10f77d63          	bgeu	a4,a5,80006268 <virtio_disk_init+0x1d0>
  disk.desc = kalloc();
    80006152:	ffffb097          	auipc	ra,0xffffb
    80006156:	9a8080e7          	jalr	-1624(ra) # 80000afa <kalloc>
    8000615a:	00028497          	auipc	s1,0x28
    8000615e:	74648493          	addi	s1,s1,1862 # 8002e8a0 <disk>
    80006162:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006164:	ffffb097          	auipc	ra,0xffffb
    80006168:	996080e7          	jalr	-1642(ra) # 80000afa <kalloc>
    8000616c:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000616e:	ffffb097          	auipc	ra,0xffffb
    80006172:	98c080e7          	jalr	-1652(ra) # 80000afa <kalloc>
    80006176:	87aa                	mv	a5,a0
    80006178:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    8000617a:	6088                	ld	a0,0(s1)
    8000617c:	cd75                	beqz	a0,80006278 <virtio_disk_init+0x1e0>
    8000617e:	00028717          	auipc	a4,0x28
    80006182:	72a73703          	ld	a4,1834(a4) # 8002e8a8 <disk+0x8>
    80006186:	cb6d                	beqz	a4,80006278 <virtio_disk_init+0x1e0>
    80006188:	cbe5                	beqz	a5,80006278 <virtio_disk_init+0x1e0>
  memset(disk.desc, 0, PGSIZE);
    8000618a:	6605                	lui	a2,0x1
    8000618c:	4581                	li	a1,0
    8000618e:	ffffb097          	auipc	ra,0xffffb
    80006192:	b58080e7          	jalr	-1192(ra) # 80000ce6 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006196:	00028497          	auipc	s1,0x28
    8000619a:	70a48493          	addi	s1,s1,1802 # 8002e8a0 <disk>
    8000619e:	6605                	lui	a2,0x1
    800061a0:	4581                	li	a1,0
    800061a2:	6488                	ld	a0,8(s1)
    800061a4:	ffffb097          	auipc	ra,0xffffb
    800061a8:	b42080e7          	jalr	-1214(ra) # 80000ce6 <memset>
  memset(disk.used, 0, PGSIZE);
    800061ac:	6605                	lui	a2,0x1
    800061ae:	4581                	li	a1,0
    800061b0:	6888                	ld	a0,16(s1)
    800061b2:	ffffb097          	auipc	ra,0xffffb
    800061b6:	b34080e7          	jalr	-1228(ra) # 80000ce6 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800061ba:	100017b7          	lui	a5,0x10001
    800061be:	4721                	li	a4,8
    800061c0:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800061c2:	4098                	lw	a4,0(s1)
    800061c4:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800061c8:	40d8                	lw	a4,4(s1)
    800061ca:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800061ce:	6498                	ld	a4,8(s1)
    800061d0:	0007069b          	sext.w	a3,a4
    800061d4:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800061d8:	9701                	srai	a4,a4,0x20
    800061da:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800061de:	6898                	ld	a4,16(s1)
    800061e0:	0007069b          	sext.w	a3,a4
    800061e4:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800061e8:	9701                	srai	a4,a4,0x20
    800061ea:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800061ee:	4685                	li	a3,1
    800061f0:	c3f4                	sw	a3,68(a5)
    disk.free[i] = 1;
    800061f2:	4705                	li	a4,1
    800061f4:	00d48c23          	sb	a3,24(s1)
    800061f8:	00e48ca3          	sb	a4,25(s1)
    800061fc:	00e48d23          	sb	a4,26(s1)
    80006200:	00e48da3          	sb	a4,27(s1)
    80006204:	00e48e23          	sb	a4,28(s1)
    80006208:	00e48ea3          	sb	a4,29(s1)
    8000620c:	00e48f23          	sb	a4,30(s1)
    80006210:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006214:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006218:	0727a823          	sw	s2,112(a5)
}
    8000621c:	60e2                	ld	ra,24(sp)
    8000621e:	6442                	ld	s0,16(sp)
    80006220:	64a2                	ld	s1,8(sp)
    80006222:	6902                	ld	s2,0(sp)
    80006224:	6105                	addi	sp,sp,32
    80006226:	8082                	ret
    panic("could not find virtio disk");
    80006228:	00002517          	auipc	a0,0x2
    8000622c:	60050513          	addi	a0,a0,1536 # 80008828 <syscalls+0x328>
    80006230:	ffffa097          	auipc	ra,0xffffa
    80006234:	314080e7          	jalr	788(ra) # 80000544 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006238:	00002517          	auipc	a0,0x2
    8000623c:	61050513          	addi	a0,a0,1552 # 80008848 <syscalls+0x348>
    80006240:	ffffa097          	auipc	ra,0xffffa
    80006244:	304080e7          	jalr	772(ra) # 80000544 <panic>
    panic("virtio disk should not be ready");
    80006248:	00002517          	auipc	a0,0x2
    8000624c:	62050513          	addi	a0,a0,1568 # 80008868 <syscalls+0x368>
    80006250:	ffffa097          	auipc	ra,0xffffa
    80006254:	2f4080e7          	jalr	756(ra) # 80000544 <panic>
    panic("virtio disk has no queue 0");
    80006258:	00002517          	auipc	a0,0x2
    8000625c:	63050513          	addi	a0,a0,1584 # 80008888 <syscalls+0x388>
    80006260:	ffffa097          	auipc	ra,0xffffa
    80006264:	2e4080e7          	jalr	740(ra) # 80000544 <panic>
    panic("virtio disk max queue too short");
    80006268:	00002517          	auipc	a0,0x2
    8000626c:	64050513          	addi	a0,a0,1600 # 800088a8 <syscalls+0x3a8>
    80006270:	ffffa097          	auipc	ra,0xffffa
    80006274:	2d4080e7          	jalr	724(ra) # 80000544 <panic>
    panic("virtio disk kalloc");
    80006278:	00002517          	auipc	a0,0x2
    8000627c:	65050513          	addi	a0,a0,1616 # 800088c8 <syscalls+0x3c8>
    80006280:	ffffa097          	auipc	ra,0xffffa
    80006284:	2c4080e7          	jalr	708(ra) # 80000544 <panic>

0000000080006288 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006288:	7159                	addi	sp,sp,-112
    8000628a:	f486                	sd	ra,104(sp)
    8000628c:	f0a2                	sd	s0,96(sp)
    8000628e:	eca6                	sd	s1,88(sp)
    80006290:	e8ca                	sd	s2,80(sp)
    80006292:	e4ce                	sd	s3,72(sp)
    80006294:	e0d2                	sd	s4,64(sp)
    80006296:	fc56                	sd	s5,56(sp)
    80006298:	f85a                	sd	s6,48(sp)
    8000629a:	f45e                	sd	s7,40(sp)
    8000629c:	f062                	sd	s8,32(sp)
    8000629e:	ec66                	sd	s9,24(sp)
    800062a0:	e86a                	sd	s10,16(sp)
    800062a2:	1880                	addi	s0,sp,112
    800062a4:	892a                	mv	s2,a0
    800062a6:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800062a8:	00c52c83          	lw	s9,12(a0)
    800062ac:	001c9c9b          	slliw	s9,s9,0x1
    800062b0:	1c82                	slli	s9,s9,0x20
    800062b2:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800062b6:	00028517          	auipc	a0,0x28
    800062ba:	71250513          	addi	a0,a0,1810 # 8002e9c8 <disk+0x128>
    800062be:	ffffb097          	auipc	ra,0xffffb
    800062c2:	92c080e7          	jalr	-1748(ra) # 80000bea <acquire>
  for(int i = 0; i < 3; i++){
    800062c6:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800062c8:	4ba1                	li	s7,8
      disk.free[i] = 0;
    800062ca:	00028b17          	auipc	s6,0x28
    800062ce:	5d6b0b13          	addi	s6,s6,1494 # 8002e8a0 <disk>
  for(int i = 0; i < 3; i++){
    800062d2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    800062d4:	8a4e                	mv	s4,s3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800062d6:	00028c17          	auipc	s8,0x28
    800062da:	6f2c0c13          	addi	s8,s8,1778 # 8002e9c8 <disk+0x128>
    800062de:	a8b5                	j	8000635a <virtio_disk_rw+0xd2>
      disk.free[i] = 0;
    800062e0:	00fb06b3          	add	a3,s6,a5
    800062e4:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800062e8:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800062ea:	0207c563          	bltz	a5,80006314 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    800062ee:	2485                	addiw	s1,s1,1
    800062f0:	0711                	addi	a4,a4,4
    800062f2:	1f548a63          	beq	s1,s5,800064e6 <virtio_disk_rw+0x25e>
    idx[i] = alloc_desc();
    800062f6:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800062f8:	00028697          	auipc	a3,0x28
    800062fc:	5a868693          	addi	a3,a3,1448 # 8002e8a0 <disk>
    80006300:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006302:	0186c583          	lbu	a1,24(a3)
    80006306:	fde9                	bnez	a1,800062e0 <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006308:	2785                	addiw	a5,a5,1
    8000630a:	0685                	addi	a3,a3,1
    8000630c:	ff779be3          	bne	a5,s7,80006302 <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    80006310:	57fd                	li	a5,-1
    80006312:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006314:	02905a63          	blez	s1,80006348 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    80006318:	f9042503          	lw	a0,-112(s0)
    8000631c:	00000097          	auipc	ra,0x0
    80006320:	cfa080e7          	jalr	-774(ra) # 80006016 <free_desc>
      for(int j = 0; j < i; j++)
    80006324:	4785                	li	a5,1
    80006326:	0297d163          	bge	a5,s1,80006348 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    8000632a:	f9442503          	lw	a0,-108(s0)
    8000632e:	00000097          	auipc	ra,0x0
    80006332:	ce8080e7          	jalr	-792(ra) # 80006016 <free_desc>
      for(int j = 0; j < i; j++)
    80006336:	4789                	li	a5,2
    80006338:	0097d863          	bge	a5,s1,80006348 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    8000633c:	f9842503          	lw	a0,-104(s0)
    80006340:	00000097          	auipc	ra,0x0
    80006344:	cd6080e7          	jalr	-810(ra) # 80006016 <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006348:	85e2                	mv	a1,s8
    8000634a:	00028517          	auipc	a0,0x28
    8000634e:	56e50513          	addi	a0,a0,1390 # 8002e8b8 <disk+0x18>
    80006352:	ffffc097          	auipc	ra,0xffffc
    80006356:	db6080e7          	jalr	-586(ra) # 80002108 <sleep>
  for(int i = 0; i < 3; i++){
    8000635a:	f9040713          	addi	a4,s0,-112
    8000635e:	84ce                	mv	s1,s3
    80006360:	bf59                	j	800062f6 <virtio_disk_rw+0x6e>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006362:	00a60793          	addi	a5,a2,10 # 100a <_entry-0x7fffeff6>
    80006366:	00479693          	slli	a3,a5,0x4
    8000636a:	00028797          	auipc	a5,0x28
    8000636e:	53678793          	addi	a5,a5,1334 # 8002e8a0 <disk>
    80006372:	97b6                	add	a5,a5,a3
    80006374:	4685                	li	a3,1
    80006376:	c794                	sw	a3,8(a5)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006378:	00028597          	auipc	a1,0x28
    8000637c:	52858593          	addi	a1,a1,1320 # 8002e8a0 <disk>
    80006380:	00a60793          	addi	a5,a2,10
    80006384:	0792                	slli	a5,a5,0x4
    80006386:	97ae                	add	a5,a5,a1
    80006388:	0007a623          	sw	zero,12(a5)
  buf0->sector = sector;
    8000638c:	0197b823          	sd	s9,16(a5)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006390:	f6070693          	addi	a3,a4,-160
    80006394:	619c                	ld	a5,0(a1)
    80006396:	97b6                	add	a5,a5,a3
    80006398:	e388                	sd	a0,0(a5)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000639a:	6188                	ld	a0,0(a1)
    8000639c:	96aa                	add	a3,a3,a0
    8000639e:	47c1                	li	a5,16
    800063a0:	c69c                	sw	a5,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800063a2:	4785                	li	a5,1
    800063a4:	00f69623          	sh	a5,12(a3)
  disk.desc[idx[0]].next = idx[1];
    800063a8:	f9442783          	lw	a5,-108(s0)
    800063ac:	00f69723          	sh	a5,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800063b0:	0792                	slli	a5,a5,0x4
    800063b2:	953e                	add	a0,a0,a5
    800063b4:	05890693          	addi	a3,s2,88
    800063b8:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    800063ba:	6188                	ld	a0,0(a1)
    800063bc:	97aa                	add	a5,a5,a0
    800063be:	40000693          	li	a3,1024
    800063c2:	c794                	sw	a3,8(a5)
  if(write)
    800063c4:	100d0d63          	beqz	s10,800064de <virtio_disk_rw+0x256>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800063c8:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800063cc:	00c7d683          	lhu	a3,12(a5)
    800063d0:	0016e693          	ori	a3,a3,1
    800063d4:	00d79623          	sh	a3,12(a5)
  disk.desc[idx[1]].next = idx[2];
    800063d8:	f9842583          	lw	a1,-104(s0)
    800063dc:	00b79723          	sh	a1,14(a5)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800063e0:	00028697          	auipc	a3,0x28
    800063e4:	4c068693          	addi	a3,a3,1216 # 8002e8a0 <disk>
    800063e8:	00260793          	addi	a5,a2,2
    800063ec:	0792                	slli	a5,a5,0x4
    800063ee:	97b6                	add	a5,a5,a3
    800063f0:	587d                	li	a6,-1
    800063f2:	01078823          	sb	a6,16(a5)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800063f6:	0592                	slli	a1,a1,0x4
    800063f8:	952e                	add	a0,a0,a1
    800063fa:	f9070713          	addi	a4,a4,-112
    800063fe:	9736                	add	a4,a4,a3
    80006400:	e118                	sd	a4,0(a0)
  disk.desc[idx[2]].len = 1;
    80006402:	6298                	ld	a4,0(a3)
    80006404:	972e                	add	a4,a4,a1
    80006406:	4585                	li	a1,1
    80006408:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000640a:	4509                	li	a0,2
    8000640c:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[2]].next = 0;
    80006410:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006414:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006418:	0127b423          	sd	s2,8(a5)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    8000641c:	6698                	ld	a4,8(a3)
    8000641e:	00275783          	lhu	a5,2(a4)
    80006422:	8b9d                	andi	a5,a5,7
    80006424:	0786                	slli	a5,a5,0x1
    80006426:	97ba                	add	a5,a5,a4
    80006428:	00c79223          	sh	a2,4(a5)

  __sync_synchronize();
    8000642c:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006430:	6698                	ld	a4,8(a3)
    80006432:	00275783          	lhu	a5,2(a4)
    80006436:	2785                	addiw	a5,a5,1
    80006438:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    8000643c:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006440:	100017b7          	lui	a5,0x10001
    80006444:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006448:	00492703          	lw	a4,4(s2)
    8000644c:	4785                	li	a5,1
    8000644e:	02f71163          	bne	a4,a5,80006470 <virtio_disk_rw+0x1e8>
    sleep(b, &disk.vdisk_lock);
    80006452:	00028997          	auipc	s3,0x28
    80006456:	57698993          	addi	s3,s3,1398 # 8002e9c8 <disk+0x128>
  while(b->disk == 1) {
    8000645a:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    8000645c:	85ce                	mv	a1,s3
    8000645e:	854a                	mv	a0,s2
    80006460:	ffffc097          	auipc	ra,0xffffc
    80006464:	ca8080e7          	jalr	-856(ra) # 80002108 <sleep>
  while(b->disk == 1) {
    80006468:	00492783          	lw	a5,4(s2)
    8000646c:	fe9788e3          	beq	a5,s1,8000645c <virtio_disk_rw+0x1d4>
  }

  disk.info[idx[0]].b = 0;
    80006470:	f9042903          	lw	s2,-112(s0)
    80006474:	00290793          	addi	a5,s2,2
    80006478:	00479713          	slli	a4,a5,0x4
    8000647c:	00028797          	auipc	a5,0x28
    80006480:	42478793          	addi	a5,a5,1060 # 8002e8a0 <disk>
    80006484:	97ba                	add	a5,a5,a4
    80006486:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000648a:	00028997          	auipc	s3,0x28
    8000648e:	41698993          	addi	s3,s3,1046 # 8002e8a0 <disk>
    80006492:	00491713          	slli	a4,s2,0x4
    80006496:	0009b783          	ld	a5,0(s3)
    8000649a:	97ba                	add	a5,a5,a4
    8000649c:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800064a0:	854a                	mv	a0,s2
    800064a2:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800064a6:	00000097          	auipc	ra,0x0
    800064aa:	b70080e7          	jalr	-1168(ra) # 80006016 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800064ae:	8885                	andi	s1,s1,1
    800064b0:	f0ed                	bnez	s1,80006492 <virtio_disk_rw+0x20a>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800064b2:	00028517          	auipc	a0,0x28
    800064b6:	51650513          	addi	a0,a0,1302 # 8002e9c8 <disk+0x128>
    800064ba:	ffffa097          	auipc	ra,0xffffa
    800064be:	7e4080e7          	jalr	2020(ra) # 80000c9e <release>
}
    800064c2:	70a6                	ld	ra,104(sp)
    800064c4:	7406                	ld	s0,96(sp)
    800064c6:	64e6                	ld	s1,88(sp)
    800064c8:	6946                	ld	s2,80(sp)
    800064ca:	69a6                	ld	s3,72(sp)
    800064cc:	6a06                	ld	s4,64(sp)
    800064ce:	7ae2                	ld	s5,56(sp)
    800064d0:	7b42                	ld	s6,48(sp)
    800064d2:	7ba2                	ld	s7,40(sp)
    800064d4:	7c02                	ld	s8,32(sp)
    800064d6:	6ce2                	ld	s9,24(sp)
    800064d8:	6d42                	ld	s10,16(sp)
    800064da:	6165                	addi	sp,sp,112
    800064dc:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800064de:	4689                	li	a3,2
    800064e0:	00d79623          	sh	a3,12(a5)
    800064e4:	b5e5                	j	800063cc <virtio_disk_rw+0x144>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800064e6:	f9042603          	lw	a2,-112(s0)
    800064ea:	00a60713          	addi	a4,a2,10
    800064ee:	0712                	slli	a4,a4,0x4
    800064f0:	00028517          	auipc	a0,0x28
    800064f4:	3b850513          	addi	a0,a0,952 # 8002e8a8 <disk+0x8>
    800064f8:	953a                	add	a0,a0,a4
  if(write)
    800064fa:	e60d14e3          	bnez	s10,80006362 <virtio_disk_rw+0xda>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800064fe:	00a60793          	addi	a5,a2,10
    80006502:	00479693          	slli	a3,a5,0x4
    80006506:	00028797          	auipc	a5,0x28
    8000650a:	39a78793          	addi	a5,a5,922 # 8002e8a0 <disk>
    8000650e:	97b6                	add	a5,a5,a3
    80006510:	0007a423          	sw	zero,8(a5)
    80006514:	b595                	j	80006378 <virtio_disk_rw+0xf0>

0000000080006516 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006516:	1101                	addi	sp,sp,-32
    80006518:	ec06                	sd	ra,24(sp)
    8000651a:	e822                	sd	s0,16(sp)
    8000651c:	e426                	sd	s1,8(sp)
    8000651e:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006520:	00028497          	auipc	s1,0x28
    80006524:	38048493          	addi	s1,s1,896 # 8002e8a0 <disk>
    80006528:	00028517          	auipc	a0,0x28
    8000652c:	4a050513          	addi	a0,a0,1184 # 8002e9c8 <disk+0x128>
    80006530:	ffffa097          	auipc	ra,0xffffa
    80006534:	6ba080e7          	jalr	1722(ra) # 80000bea <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006538:	10001737          	lui	a4,0x10001
    8000653c:	533c                	lw	a5,96(a4)
    8000653e:	8b8d                	andi	a5,a5,3
    80006540:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006542:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006546:	689c                	ld	a5,16(s1)
    80006548:	0204d703          	lhu	a4,32(s1)
    8000654c:	0027d783          	lhu	a5,2(a5)
    80006550:	04f70863          	beq	a4,a5,800065a0 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006554:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006558:	6898                	ld	a4,16(s1)
    8000655a:	0204d783          	lhu	a5,32(s1)
    8000655e:	8b9d                	andi	a5,a5,7
    80006560:	078e                	slli	a5,a5,0x3
    80006562:	97ba                	add	a5,a5,a4
    80006564:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006566:	00278713          	addi	a4,a5,2
    8000656a:	0712                	slli	a4,a4,0x4
    8000656c:	9726                	add	a4,a4,s1
    8000656e:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006572:	e721                	bnez	a4,800065ba <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006574:	0789                	addi	a5,a5,2
    80006576:	0792                	slli	a5,a5,0x4
    80006578:	97a6                	add	a5,a5,s1
    8000657a:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000657c:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006580:	ffffc097          	auipc	ra,0xffffc
    80006584:	bec080e7          	jalr	-1044(ra) # 8000216c <wakeup>

    disk.used_idx += 1;
    80006588:	0204d783          	lhu	a5,32(s1)
    8000658c:	2785                	addiw	a5,a5,1
    8000658e:	17c2                	slli	a5,a5,0x30
    80006590:	93c1                	srli	a5,a5,0x30
    80006592:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006596:	6898                	ld	a4,16(s1)
    80006598:	00275703          	lhu	a4,2(a4)
    8000659c:	faf71ce3          	bne	a4,a5,80006554 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800065a0:	00028517          	auipc	a0,0x28
    800065a4:	42850513          	addi	a0,a0,1064 # 8002e9c8 <disk+0x128>
    800065a8:	ffffa097          	auipc	ra,0xffffa
    800065ac:	6f6080e7          	jalr	1782(ra) # 80000c9e <release>
}
    800065b0:	60e2                	ld	ra,24(sp)
    800065b2:	6442                	ld	s0,16(sp)
    800065b4:	64a2                	ld	s1,8(sp)
    800065b6:	6105                	addi	sp,sp,32
    800065b8:	8082                	ret
      panic("virtio_disk_intr status");
    800065ba:	00002517          	auipc	a0,0x2
    800065be:	32650513          	addi	a0,a0,806 # 800088e0 <syscalls+0x3e0>
    800065c2:	ffffa097          	auipc	ra,0xffffa
    800065c6:	f82080e7          	jalr	-126(ra) # 80000544 <panic>

00000000800065ca <init_list_head>:
#include "defs.h"
#include "spinlock.h"
#include "proc.h"

void init_list_head(struct list_head *list)
{
    800065ca:	1141                	addi	sp,sp,-16
    800065cc:	e422                	sd	s0,8(sp)
    800065ce:	0800                	addi	s0,sp,16
  list->next = list;
    800065d0:	e108                	sd	a0,0(a0)
  list->prev = list;
    800065d2:	e508                	sd	a0,8(a0)
}
    800065d4:	6422                	ld	s0,8(sp)
    800065d6:	0141                	addi	sp,sp,16
    800065d8:	8082                	ret

00000000800065da <list_add>:
  next->prev = prev;
  prev->next = next;
}

void list_add(struct list_head *head, struct list_head *new)
{
    800065da:	1141                	addi	sp,sp,-16
    800065dc:	e422                	sd	s0,8(sp)
    800065de:	0800                	addi	s0,sp,16
  __list_add(new, head, head->next);
    800065e0:	611c                	ld	a5,0(a0)
  next->prev = new;
    800065e2:	e78c                	sd	a1,8(a5)
  new->next = next;
    800065e4:	e19c                	sd	a5,0(a1)
  new->prev = prev;
    800065e6:	e588                	sd	a0,8(a1)
  prev->next = new;
    800065e8:	e10c                	sd	a1,0(a0)
}
    800065ea:	6422                	ld	s0,8(sp)
    800065ec:	0141                	addi	sp,sp,16
    800065ee:	8082                	ret

00000000800065f0 <list_add_tail>:

void list_add_tail(struct list_head *head, struct list_head *new)
{
    800065f0:	1141                	addi	sp,sp,-16
    800065f2:	e422                	sd	s0,8(sp)
    800065f4:	0800                	addi	s0,sp,16
  __list_add(new, head->prev, head);
    800065f6:	651c                	ld	a5,8(a0)
  next->prev = new;
    800065f8:	e50c                	sd	a1,8(a0)
  new->next = next;
    800065fa:	e188                	sd	a0,0(a1)
  new->prev = prev;
    800065fc:	e59c                	sd	a5,8(a1)
  prev->next = new;
    800065fe:	e38c                	sd	a1,0(a5)
}
    80006600:	6422                	ld	s0,8(sp)
    80006602:	0141                	addi	sp,sp,16
    80006604:	8082                	ret

0000000080006606 <list_del>:

void list_del(struct list_head *entry)
{
    80006606:	1141                	addi	sp,sp,-16
    80006608:	e422                	sd	s0,8(sp)
    8000660a:	0800                	addi	s0,sp,16
  __list_del(entry->prev, entry->next);
    8000660c:	651c                	ld	a5,8(a0)
    8000660e:	6118                	ld	a4,0(a0)
  next->prev = prev;
    80006610:	e71c                	sd	a5,8(a4)
  prev->next = next;
    80006612:	e398                	sd	a4,0(a5)
  entry->prev = entry->next = entry;
    80006614:	e108                	sd	a0,0(a0)
    80006616:	e508                	sd	a0,8(a0)
}
    80006618:	6422                	ld	s0,8(sp)
    8000661a:	0141                	addi	sp,sp,16
    8000661c:	8082                	ret

000000008000661e <list_del_init>:

void list_del_init(struct list_head *entry)
{
    8000661e:	1141                	addi	sp,sp,-16
    80006620:	e422                	sd	s0,8(sp)
    80006622:	0800                	addi	s0,sp,16
  __list_del(entry->prev, entry->next);
    80006624:	651c                	ld	a5,8(a0)
    80006626:	6118                	ld	a4,0(a0)
  next->prev = prev;
    80006628:	e71c                	sd	a5,8(a4)
  prev->next = next;
    8000662a:	e398                	sd	a4,0(a5)
  list->next = list;
    8000662c:	e108                	sd	a0,0(a0)
  list->prev = list;
    8000662e:	e508                	sd	a0,8(a0)
  init_list_head(entry);
}
    80006630:	6422                	ld	s0,8(sp)
    80006632:	0141                	addi	sp,sp,16
    80006634:	8082                	ret

0000000080006636 <int_to_char>:
#include "file_helper.h"

static int opened = 0;
static struct file *f;

int int_to_char(int num, char *buff){
    80006636:	1141                	addi	sp,sp,-16
    80006638:	e422                	sd	s0,8(sp)
    8000663a:	0800                	addi	s0,sp,16
    8000663c:	86aa                	mv	a3,a0
    int temp = num;
    8000663e:	87aa                	mv	a5,a0
    int len = 0;
    80006640:	4501                	li	a0,0
    do{
	temp/=10;
    80006642:	48a9                	li	a7,10
	len++;
    }while(temp > 0);
    80006644:	4825                	li	a6,9
	temp/=10;
    80006646:	873e                	mv	a4,a5
    80006648:	0317c7bb          	divw	a5,a5,a7
	len++;
    8000664c:	862a                	mv	a2,a0
    8000664e:	2505                	addiw	a0,a0,1
    }while(temp > 0);
    80006650:	fee84be3          	blt	a6,a4,80006646 <int_to_char+0x10>

    int i = 0;
    while(i < len){
    80006654:	02a05363          	blez	a0,8000667a <int_to_char+0x44>
	buff[i] = num%10 + 48;
    80006658:	4729                	li	a4,10
    8000665a:	02e6e73b          	remw	a4,a3,a4
    8000665e:	0307071b          	addiw	a4,a4,48
    80006662:	0ff77713          	andi	a4,a4,255
    80006666:	87ae                	mv	a5,a1
    while(i < len){
    80006668:	fff5c593          	not	a1,a1
	buff[i] = num%10 + 48;
    8000666c:	00e78023          	sb	a4,0(a5)
    while(i < len){
    80006670:	0785                	addi	a5,a5,1
    80006672:	00f586bb          	addw	a3,a1,a5
    80006676:	fec6cbe3          	blt	a3,a2,8000666c <int_to_char+0x36>
	i++;
    }
    return len;
}
    8000667a:	6422                	ld	s0,8(sp)
    8000667c:	0141                	addi	sp,sp,16
    8000667e:	8082                	ret

0000000080006680 <write_to_logs>:

void write_to_logs(void *buf){
    80006680:	1101                	addi	sp,sp,-32
    80006682:	ec06                	sd	ra,24(sp)
    80006684:	e822                	sd	s0,16(sp)
    80006686:	e426                	sd	s1,8(sp)
    80006688:	e04a                	sd	s2,0(sp)
    8000668a:	1000                	addi	s0,sp,32
    8000668c:	84aa                	mv	s1,a0

    char *filename = "/AuditLogs.txt";
    if(!opened){
    8000668e:	00002797          	auipc	a5,0x2
    80006692:	4c27a783          	lw	a5,1218(a5) # 80008b50 <opened>
    80006696:	c7b9                	beqz	a5,800066e4 <write_to_logs+0x64>
	f = open(filename, O_CREATE);
	opened = 1;
    }

    if(f == (struct file *)-1)
    80006698:	00002797          	auipc	a5,0x2
    8000669c:	4b07b783          	ld	a5,1200(a5) # 80008b48 <f>
    800066a0:	577d                	li	a4,-1
    800066a2:	06e78563          	beq	a5,a4,8000670c <write_to_logs+0x8c>
        panic("ERROR FILE");

    if(f == (struct file *)0) {
    800066a6:	cbbd                	beqz	a5,8000671c <write_to_logs+0x9c>
        panic("No File");
    }

    printf("6\n");
    800066a8:	00002517          	auipc	a0,0x2
    800066ac:	27850513          	addi	a0,a0,632 # 80008920 <syscalls+0x420>
    800066b0:	ffffa097          	auipc	ra,0xffffa
    800066b4:	ede080e7          	jalr	-290(ra) # 8000058e <printf>
    //struct audit_node *node = a_list.head;

  //  while(node != 0){
//	char buff[512];
    char *buff = (char *)buf;
    kfilewrite(f, (uint64)(buff), strlen(buff));
    800066b8:	00002917          	auipc	s2,0x2
    800066bc:	49093903          	ld	s2,1168(s2) # 80008b48 <f>
    800066c0:	8526                	mv	a0,s1
    800066c2:	ffffa097          	auipc	ra,0xffffa
    800066c6:	7a8080e7          	jalr	1960(ra) # 80000e6a <strlen>
    800066ca:	862a                	mv	a2,a0
    800066cc:	85a6                	mv	a1,s1
    800066ce:	854a                	mv	a0,s2
    800066d0:	00000097          	auipc	ra,0x0
    800066d4:	05c080e7          	jalr	92(ra) # 8000672c <kfilewrite>
}
    800066d8:	60e2                	ld	ra,24(sp)
    800066da:	6442                	ld	s0,16(sp)
    800066dc:	64a2                	ld	s1,8(sp)
    800066de:	6902                	ld	s2,0(sp)
    800066e0:	6105                	addi	sp,sp,32
    800066e2:	8082                	ret
	f = open(filename, O_CREATE);
    800066e4:	20000593          	li	a1,512
    800066e8:	00002517          	auipc	a0,0x2
    800066ec:	21050513          	addi	a0,a0,528 # 800088f8 <syscalls+0x3f8>
    800066f0:	00000097          	auipc	ra,0x0
    800066f4:	36c080e7          	jalr	876(ra) # 80006a5c <open>
    800066f8:	00002797          	auipc	a5,0x2
    800066fc:	44a7b823          	sd	a0,1104(a5) # 80008b48 <f>
	opened = 1;
    80006700:	4785                	li	a5,1
    80006702:	00002717          	auipc	a4,0x2
    80006706:	44f72723          	sw	a5,1102(a4) # 80008b50 <opened>
    8000670a:	b779                	j	80006698 <write_to_logs+0x18>
        panic("ERROR FILE");
    8000670c:	00002517          	auipc	a0,0x2
    80006710:	1fc50513          	addi	a0,a0,508 # 80008908 <syscalls+0x408>
    80006714:	ffffa097          	auipc	ra,0xffffa
    80006718:	e30080e7          	jalr	-464(ra) # 80000544 <panic>
        panic("No File");
    8000671c:	00002517          	auipc	a0,0x2
    80006720:	1fc50513          	addi	a0,a0,508 # 80008918 <syscalls+0x418>
    80006724:	ffffa097          	auipc	ra,0xffffa
    80006728:	e20080e7          	jalr	-480(ra) # 80000544 <panic>

000000008000672c <kfilewrite>:



int
kfilewrite(struct file *f, uint64 addr, int n)
{
    8000672c:	715d                	addi	sp,sp,-80
    8000672e:	e486                	sd	ra,72(sp)
    80006730:	e0a2                	sd	s0,64(sp)
    80006732:	fc26                	sd	s1,56(sp)
    80006734:	f84a                	sd	s2,48(sp)
    80006736:	f44e                	sd	s3,40(sp)
    80006738:	f052                	sd	s4,32(sp)
    8000673a:	ec56                	sd	s5,24(sp)
    8000673c:	e85a                	sd	s6,16(sp)
    8000673e:	e45e                	sd	s7,8(sp)
    80006740:	e062                	sd	s8,0(sp)
    80006742:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0){
    80006744:	00954783          	lbu	a5,9(a0)
    80006748:	cb85                	beqz	a5,80006778 <kfilewrite+0x4c>
    8000674a:	892a                	mv	s2,a0
    8000674c:	8aae                	mv	s5,a1
    8000674e:	8a32                	mv	s4,a2
    printf("First\n");
    return -1;
  }
  if(f->type == FD_PIPE){
    80006750:	411c                	lw	a5,0(a0)
    80006752:	4705                	li	a4,1
    80006754:	02e78c63          	beq	a5,a4,8000678c <kfilewrite+0x60>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80006758:	470d                	li	a4,3
    8000675a:	04e78063          	beq	a5,a4,8000679a <kfilewrite+0x6e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write){
      return -1;
    }
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000675e:	4709                	li	a4,2
    80006760:	0ee79b63          	bne	a5,a4,80006856 <kfilewrite+0x12a>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80006764:	0cc05763          	blez	a2,80006832 <kfilewrite+0x106>
    int i = 0;
    80006768:	4981                	li	s3,0
    8000676a:	6b05                	lui	s6,0x1
    8000676c:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80006770:	6b85                	lui	s7,0x1
    80006772:	c00b8b9b          	addiw	s7,s7,-1024
    80006776:	a075                	j	80006822 <kfilewrite+0xf6>
    printf("First\n");
    80006778:	00002517          	auipc	a0,0x2
    8000677c:	1b050513          	addi	a0,a0,432 # 80008928 <syscalls+0x428>
    80006780:	ffffa097          	auipc	ra,0xffffa
    80006784:	e0e080e7          	jalr	-498(ra) # 8000058e <printf>
    return -1;
    80006788:	5a7d                	li	s4,-1
    8000678a:	a07d                	j	80006838 <kfilewrite+0x10c>
    ret = pipewrite(f->pipe, addr, n);
    8000678c:	6908                	ld	a0,16(a0)
    8000678e:	ffffe097          	auipc	ra,0xffffe
    80006792:	566080e7          	jalr	1382(ra) # 80004cf4 <pipewrite>
    80006796:	8a2a                	mv	s4,a0
    80006798:	a045                	j	80006838 <kfilewrite+0x10c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write){
    8000679a:	02451783          	lh	a5,36(a0)
    8000679e:	03079693          	slli	a3,a5,0x30
    800067a2:	92c1                	srli	a3,a3,0x30
    800067a4:	4725                	li	a4,9
    800067a6:	0cd76063          	bltu	a4,a3,80006866 <kfilewrite+0x13a>
    800067aa:	0792                	slli	a5,a5,0x4
    800067ac:	00027717          	auipc	a4,0x27
    800067b0:	09c70713          	addi	a4,a4,156 # 8002d848 <devsw>
    800067b4:	97ba                	add	a5,a5,a4
    800067b6:	679c                	ld	a5,8(a5)
    800067b8:	cbcd                	beqz	a5,8000686a <kfilewrite+0x13e>
    ret = devsw[f->major].write(1, addr, n);
    800067ba:	4505                	li	a0,1
    800067bc:	9782                	jalr	a5
    800067be:	8a2a                	mv	s4,a0
    800067c0:	a8a5                	j	80006838 <kfilewrite+0x10c>
    800067c2:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800067c6:	ffffe097          	auipc	ra,0xffffe
    800067ca:	be8080e7          	jalr	-1048(ra) # 800043ae <begin_op>
      ilock(f->ip);
    800067ce:	01893503          	ld	a0,24(s2)
    800067d2:	ffffd097          	auipc	ra,0xffffd
    800067d6:	21a080e7          	jalr	538(ra) # 800039ec <ilock>
      if ((r = writei(f->ip, 0, addr + i, f->off, n1)) > 0)
    800067da:	8762                	mv	a4,s8
    800067dc:	02092683          	lw	a3,32(s2)
    800067e0:	01598633          	add	a2,s3,s5
    800067e4:	4581                	li	a1,0
    800067e6:	01893503          	ld	a0,24(s2)
    800067ea:	ffffd097          	auipc	ra,0xffffd
    800067ee:	5ae080e7          	jalr	1454(ra) # 80003d98 <writei>
    800067f2:	84aa                	mv	s1,a0
    800067f4:	00a05763          	blez	a0,80006802 <kfilewrite+0xd6>
        f->off += r;
    800067f8:	02092783          	lw	a5,32(s2)
    800067fc:	9fa9                	addw	a5,a5,a0
    800067fe:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80006802:	01893503          	ld	a0,24(s2)
    80006806:	ffffd097          	auipc	ra,0xffffd
    8000680a:	2a8080e7          	jalr	680(ra) # 80003aae <iunlock>
      end_op();
    8000680e:	ffffe097          	auipc	ra,0xffffe
    80006812:	c20080e7          	jalr	-992(ra) # 8000442e <end_op>

      if(r != n1){
    80006816:	009c1f63          	bne	s8,s1,80006834 <kfilewrite+0x108>
        // error from writei
        break;
      }
      i += r;
    8000681a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000681e:	0149db63          	bge	s3,s4,80006834 <kfilewrite+0x108>
      int n1 = n - i;
    80006822:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80006826:	84be                	mv	s1,a5
    80006828:	2781                	sext.w	a5,a5
    8000682a:	f8fb5ce3          	bge	s6,a5,800067c2 <kfilewrite+0x96>
    8000682e:	84de                	mv	s1,s7
    80006830:	bf49                	j	800067c2 <kfilewrite+0x96>
    int i = 0;
    80006832:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80006834:	013a1f63          	bne	s4,s3,80006852 <kfilewrite+0x126>
  } else {
    panic("filewrite");
  }
  return ret;
}
    80006838:	8552                	mv	a0,s4
    8000683a:	60a6                	ld	ra,72(sp)
    8000683c:	6406                	ld	s0,64(sp)
    8000683e:	74e2                	ld	s1,56(sp)
    80006840:	7942                	ld	s2,48(sp)
    80006842:	79a2                	ld	s3,40(sp)
    80006844:	7a02                	ld	s4,32(sp)
    80006846:	6ae2                	ld	s5,24(sp)
    80006848:	6b42                	ld	s6,16(sp)
    8000684a:	6ba2                	ld	s7,8(sp)
    8000684c:	6c02                	ld	s8,0(sp)
    8000684e:	6161                	addi	sp,sp,80
    80006850:	8082                	ret
    ret = (i == n ? n : -1);
    80006852:	5a7d                	li	s4,-1
    80006854:	b7d5                	j	80006838 <kfilewrite+0x10c>
    panic("filewrite");
    80006856:	00002517          	auipc	a0,0x2
    8000685a:	f2250513          	addi	a0,a0,-222 # 80008778 <syscalls+0x278>
    8000685e:	ffffa097          	auipc	ra,0xffffa
    80006862:	ce6080e7          	jalr	-794(ra) # 80000544 <panic>
      return -1;
    80006866:	5a7d                	li	s4,-1
    80006868:	bfc1                	j	80006838 <kfilewrite+0x10c>
    8000686a:	5a7d                	li	s4,-1
    8000686c:	b7f1                	j	80006838 <kfilewrite+0x10c>

000000008000686e <fdalloc>:

int
fdalloc(struct file *f)
{
    8000686e:	1101                	addi	sp,sp,-32
    80006870:	ec06                	sd	ra,24(sp)
    80006872:	e822                	sd	s0,16(sp)
    80006874:	e426                	sd	s1,8(sp)
    80006876:	1000                	addi	s0,sp,32
    80006878:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000687a:	ffffb097          	auipc	ra,0xffffb
    8000687e:	14c080e7          	jalr	332(ra) # 800019c6 <myproc>
    80006882:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80006884:	0d050793          	addi	a5,a0,208
    80006888:	4501                	li	a0,0
    8000688a:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000688c:	6398                	ld	a4,0(a5)
    8000688e:	cb19                	beqz	a4,800068a4 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80006890:	2505                	addiw	a0,a0,1
    80006892:	07a1                	addi	a5,a5,8
    80006894:	fed51ce3          	bne	a0,a3,8000688c <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80006898:	557d                	li	a0,-1
}
    8000689a:	60e2                	ld	ra,24(sp)
    8000689c:	6442                	ld	s0,16(sp)
    8000689e:	64a2                	ld	s1,8(sp)
    800068a0:	6105                	addi	sp,sp,32
    800068a2:	8082                	ret
      p->ofile[fd] = f;
    800068a4:	01a50793          	addi	a5,a0,26
    800068a8:	078e                	slli	a5,a5,0x3
    800068aa:	963e                	add	a2,a2,a5
    800068ac:	e204                	sd	s1,0(a2)
      return fd;
    800068ae:	b7f5                	j	8000689a <fdalloc+0x2c>

00000000800068b0 <create>:

struct inode*
create(char *path, short type, short major, short minor)
{
    800068b0:	715d                	addi	sp,sp,-80
    800068b2:	e486                	sd	ra,72(sp)
    800068b4:	e0a2                	sd	s0,64(sp)
    800068b6:	fc26                	sd	s1,56(sp)
    800068b8:	f84a                	sd	s2,48(sp)
    800068ba:	f44e                	sd	s3,40(sp)
    800068bc:	f052                	sd	s4,32(sp)
    800068be:	ec56                	sd	s5,24(sp)
    800068c0:	e85a                	sd	s6,16(sp)
    800068c2:	0880                	addi	s0,sp,80
    800068c4:	8b2e                	mv	s6,a1
    800068c6:	89b2                	mv	s3,a2
    800068c8:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800068ca:	fb040593          	addi	a1,s0,-80
    800068ce:	ffffe097          	auipc	ra,0xffffe
    800068d2:	8e2080e7          	jalr	-1822(ra) # 800041b0 <nameiparent>
    800068d6:	84aa                	mv	s1,a0
    800068d8:	18050063          	beqz	a0,80006a58 <create+0x1a8>
    return 0;

  ilock(dp);
    800068dc:	ffffd097          	auipc	ra,0xffffd
    800068e0:	110080e7          	jalr	272(ra) # 800039ec <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800068e4:	4601                	li	a2,0
    800068e6:	fb040593          	addi	a1,s0,-80
    800068ea:	8526                	mv	a0,s1
    800068ec:	ffffd097          	auipc	ra,0xffffd
    800068f0:	5e4080e7          	jalr	1508(ra) # 80003ed0 <dirlookup>
    800068f4:	8aaa                	mv	s5,a0
    800068f6:	c931                	beqz	a0,8000694a <create+0x9a>
    iunlockput(dp);
    800068f8:	8526                	mv	a0,s1
    800068fa:	ffffd097          	auipc	ra,0xffffd
    800068fe:	354080e7          	jalr	852(ra) # 80003c4e <iunlockput>
    ilock(ip);
    80006902:	8556                	mv	a0,s5
    80006904:	ffffd097          	auipc	ra,0xffffd
    80006908:	0e8080e7          	jalr	232(ra) # 800039ec <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000690c:	000b059b          	sext.w	a1,s6
    80006910:	4789                	li	a5,2
    80006912:	02f59563          	bne	a1,a5,8000693c <create+0x8c>
    80006916:	044ad783          	lhu	a5,68(s5)
    8000691a:	37f9                	addiw	a5,a5,-2
    8000691c:	17c2                	slli	a5,a5,0x30
    8000691e:	93c1                	srli	a5,a5,0x30
    80006920:	4705                	li	a4,1
    80006922:	00f76d63          	bltu	a4,a5,8000693c <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80006926:	8556                	mv	a0,s5
    80006928:	60a6                	ld	ra,72(sp)
    8000692a:	6406                	ld	s0,64(sp)
    8000692c:	74e2                	ld	s1,56(sp)
    8000692e:	7942                	ld	s2,48(sp)
    80006930:	79a2                	ld	s3,40(sp)
    80006932:	7a02                	ld	s4,32(sp)
    80006934:	6ae2                	ld	s5,24(sp)
    80006936:	6b42                	ld	s6,16(sp)
    80006938:	6161                	addi	sp,sp,80
    8000693a:	8082                	ret
    iunlockput(ip);
    8000693c:	8556                	mv	a0,s5
    8000693e:	ffffd097          	auipc	ra,0xffffd
    80006942:	310080e7          	jalr	784(ra) # 80003c4e <iunlockput>
    return 0;
    80006946:	4a81                	li	s5,0
    80006948:	bff9                	j	80006926 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    8000694a:	85da                	mv	a1,s6
    8000694c:	4088                	lw	a0,0(s1)
    8000694e:	ffffd097          	auipc	ra,0xffffd
    80006952:	f02080e7          	jalr	-254(ra) # 80003850 <ialloc>
    80006956:	8a2a                	mv	s4,a0
    80006958:	c125                	beqz	a0,800069b8 <create+0x108>
  ilock(ip);
    8000695a:	ffffd097          	auipc	ra,0xffffd
    8000695e:	092080e7          	jalr	146(ra) # 800039ec <ilock>
  ip->major = major;
    80006962:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80006966:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    8000696a:	4785                	li	a5,1
    8000696c:	04fa1523          	sh	a5,74(s4)
  iupdate(ip);
    80006970:	8552                	mv	a0,s4
    80006972:	ffffd097          	auipc	ra,0xffffd
    80006976:	fb0080e7          	jalr	-80(ra) # 80003922 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000697a:	000b059b          	sext.w	a1,s6
    8000697e:	4785                	li	a5,1
    80006980:	04f58363          	beq	a1,a5,800069c6 <create+0x116>
  if(dirlink(dp, name, ip->inum) < 0)
    80006984:	004a2603          	lw	a2,4(s4)
    80006988:	fb040593          	addi	a1,s0,-80
    8000698c:	8526                	mv	a0,s1
    8000698e:	ffffd097          	auipc	ra,0xffffd
    80006992:	752080e7          	jalr	1874(ra) # 800040e0 <dirlink>
    80006996:	08054763          	bltz	a0,80006a24 <create+0x174>
  iunlockput(dp);
    8000699a:	8526                	mv	a0,s1
    8000699c:	ffffd097          	auipc	ra,0xffffd
    800069a0:	2b2080e7          	jalr	690(ra) # 80003c4e <iunlockput>
  printf("Successfully Created\n");
    800069a4:	00002517          	auipc	a0,0x2
    800069a8:	f8c50513          	addi	a0,a0,-116 # 80008930 <syscalls+0x430>
    800069ac:	ffffa097          	auipc	ra,0xffffa
    800069b0:	be2080e7          	jalr	-1054(ra) # 8000058e <printf>
  return ip;
    800069b4:	8ad2                	mv	s5,s4
    800069b6:	bf85                	j	80006926 <create+0x76>
    iunlockput(dp);
    800069b8:	8526                	mv	a0,s1
    800069ba:	ffffd097          	auipc	ra,0xffffd
    800069be:	294080e7          	jalr	660(ra) # 80003c4e <iunlockput>
    return 0;
    800069c2:	8ad2                	mv	s5,s4
    800069c4:	b78d                	j	80006926 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800069c6:	004a2603          	lw	a2,4(s4)
    800069ca:	00002597          	auipc	a1,0x2
    800069ce:	dde58593          	addi	a1,a1,-546 # 800087a8 <syscalls+0x2a8>
    800069d2:	8552                	mv	a0,s4
    800069d4:	ffffd097          	auipc	ra,0xffffd
    800069d8:	70c080e7          	jalr	1804(ra) # 800040e0 <dirlink>
    800069dc:	04054463          	bltz	a0,80006a24 <create+0x174>
    800069e0:	40d0                	lw	a2,4(s1)
    800069e2:	00002597          	auipc	a1,0x2
    800069e6:	dce58593          	addi	a1,a1,-562 # 800087b0 <syscalls+0x2b0>
    800069ea:	8552                	mv	a0,s4
    800069ec:	ffffd097          	auipc	ra,0xffffd
    800069f0:	6f4080e7          	jalr	1780(ra) # 800040e0 <dirlink>
    800069f4:	02054863          	bltz	a0,80006a24 <create+0x174>
  if(dirlink(dp, name, ip->inum) < 0)
    800069f8:	004a2603          	lw	a2,4(s4)
    800069fc:	fb040593          	addi	a1,s0,-80
    80006a00:	8526                	mv	a0,s1
    80006a02:	ffffd097          	auipc	ra,0xffffd
    80006a06:	6de080e7          	jalr	1758(ra) # 800040e0 <dirlink>
    80006a0a:	00054d63          	bltz	a0,80006a24 <create+0x174>
    dp->nlink++;  // for ".."
    80006a0e:	04a4d783          	lhu	a5,74(s1)
    80006a12:	2785                	addiw	a5,a5,1
    80006a14:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80006a18:	8526                	mv	a0,s1
    80006a1a:	ffffd097          	auipc	ra,0xffffd
    80006a1e:	f08080e7          	jalr	-248(ra) # 80003922 <iupdate>
    80006a22:	bfa5                	j	8000699a <create+0xea>
  printf("actually fails\n");
    80006a24:	00002517          	auipc	a0,0x2
    80006a28:	f2450513          	addi	a0,a0,-220 # 80008948 <syscalls+0x448>
    80006a2c:	ffffa097          	auipc	ra,0xffffa
    80006a30:	b62080e7          	jalr	-1182(ra) # 8000058e <printf>
  ip->nlink = 0;
    80006a34:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80006a38:	8552                	mv	a0,s4
    80006a3a:	ffffd097          	auipc	ra,0xffffd
    80006a3e:	ee8080e7          	jalr	-280(ra) # 80003922 <iupdate>
  iunlockput(ip);
    80006a42:	8552                	mv	a0,s4
    80006a44:	ffffd097          	auipc	ra,0xffffd
    80006a48:	20a080e7          	jalr	522(ra) # 80003c4e <iunlockput>
  iunlockput(dp);
    80006a4c:	8526                	mv	a0,s1
    80006a4e:	ffffd097          	auipc	ra,0xffffd
    80006a52:	200080e7          	jalr	512(ra) # 80003c4e <iunlockput>
  return 0;
    80006a56:	bdc1                	j	80006926 <create+0x76>
    return 0;
    80006a58:	8aaa                	mv	s5,a0
    80006a5a:	b5f1                	j	80006926 <create+0x76>

0000000080006a5c <open>:


struct file *open(char *filename, int omode){
    80006a5c:	7179                	addi	sp,sp,-48
    80006a5e:	f406                	sd	ra,40(sp)
    80006a60:	f022                	sd	s0,32(sp)
    80006a62:	ec26                	sd	s1,24(sp)
    80006a64:	e84a                	sd	s2,16(sp)
    80006a66:	e44e                	sd	s3,8(sp)
    80006a68:	1800                	addi	s0,sp,48
    80006a6a:	84aa                	mv	s1,a0
    80006a6c:	892e                	mv	s2,a1
    int fd;
    struct file *f;
    struct inode *ip;

    if(strlen(filename) < 0)
    80006a6e:	ffffa097          	auipc	ra,0xffffa
    80006a72:	3fc080e7          	jalr	1020(ra) # 80000e6a <strlen>
    80006a76:	18054e63          	bltz	a0,80006c12 <open+0x1b6>
        return (struct file *)-1;

    begin_op();
    80006a7a:	ffffe097          	auipc	ra,0xffffe
    80006a7e:	934080e7          	jalr	-1740(ra) # 800043ae <begin_op>
    if(omode & O_CREATE){
    80006a82:	20097793          	andi	a5,s2,512
    80006a86:	10078263          	beqz	a5,80006b8a <open+0x12e>
        printf("CREATING\n");
    80006a8a:	00002517          	auipc	a0,0x2
    80006a8e:	ece50513          	addi	a0,a0,-306 # 80008958 <syscalls+0x458>
    80006a92:	ffffa097          	auipc	ra,0xffffa
    80006a96:	afc080e7          	jalr	-1284(ra) # 8000058e <printf>
        ip = create(filename, T_FILE, 0, 0);
    80006a9a:	4681                	li	a3,0
    80006a9c:	4601                	li	a2,0
    80006a9e:	4589                	li	a1,2
    80006aa0:	8526                	mv	a0,s1
    80006aa2:	00000097          	auipc	ra,0x0
    80006aa6:	e0e080e7          	jalr	-498(ra) # 800068b0 <create>
    80006aaa:	89aa                	mv	s3,a0
        if(ip == 0){
    80006aac:	c169                	beqz	a0,80006b6e <open+0x112>
            iunlockput(ip);
            end_op();
            return (struct file *)-1;
        }
    }
    printf("1\n");
    80006aae:	00002517          	auipc	a0,0x2
    80006ab2:	ee250513          	addi	a0,a0,-286 # 80008990 <syscalls+0x490>
    80006ab6:	ffffa097          	auipc	ra,0xffffa
    80006aba:	ad8080e7          	jalr	-1320(ra) # 8000058e <printf>


    if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80006abe:	04499703          	lh	a4,68(s3)
    80006ac2:	478d                	li	a5,3
    80006ac4:	00f71763          	bne	a4,a5,80006ad2 <open+0x76>
    80006ac8:	0469d703          	lhu	a4,70(s3)
    80006acc:	47a5                	li	a5,9
    80006ace:	12e7e163          	bltu	a5,a4,80006bf0 <open+0x194>
        iunlockput(ip);
        end_op();
        return (struct file *)-1;
    }

        printf("2\n");
    80006ad2:	00002517          	auipc	a0,0x2
    80006ad6:	ec650513          	addi	a0,a0,-314 # 80008998 <syscalls+0x498>
    80006ada:	ffffa097          	auipc	ra,0xffffa
    80006ade:	ab4080e7          	jalr	-1356(ra) # 8000058e <printf>
    if((f = filealloc()) == 0 || (fd = fdalloc(f) < 0)){
    80006ae2:	ffffe097          	auipc	ra,0xffffe
    80006ae6:	cdc080e7          	jalr	-804(ra) # 800047be <filealloc>
    80006aea:	84aa                	mv	s1,a0
    80006aec:	14050163          	beqz	a0,80006c2e <open+0x1d2>
    80006af0:	00000097          	auipc	ra,0x0
    80006af4:	d7e080e7          	jalr	-642(ra) # 8000686e <fdalloc>
    80006af8:	12054663          	bltz	a0,80006c24 <open+0x1c8>
        iunlockput(ip);
        end_op();
        return (struct file *)-1;
    }

        printf("3\n");
    80006afc:	00002517          	auipc	a0,0x2
    80006b00:	ea450513          	addi	a0,a0,-348 # 800089a0 <syscalls+0x4a0>
    80006b04:	ffffa097          	auipc	ra,0xffffa
    80006b08:	a8a080e7          	jalr	-1398(ra) # 8000058e <printf>
   f->type = FD_INODE;
    80006b0c:	4789                	li	a5,2
    80006b0e:	c09c                	sw	a5,0(s1)
   f->off = 0;
    80006b10:	0204a023          	sw	zero,32(s1)
   f->ip = ip;
    80006b14:	0134bc23          	sd	s3,24(s1)
   f->readable = !(omode & O_WRONLY);
    80006b18:	00194793          	xori	a5,s2,1
    80006b1c:	8b85                	andi	a5,a5,1
    80006b1e:	00f48423          	sb	a5,8(s1)
   f->writable = O_WRONLY;
    80006b22:	4785                	li	a5,1
    80006b24:	00f484a3          	sb	a5,9(s1)

   if((omode & O_TRUNC) && ip->type == T_FILE){
    80006b28:	40097913          	andi	s2,s2,1024
    80006b2c:	00090763          	beqz	s2,80006b3a <open+0xde>
    80006b30:	04499703          	lh	a4,68(s3)
    80006b34:	4789                	li	a5,2
    80006b36:	0cf70863          	beq	a4,a5,80006c06 <open+0x1aa>
     itrunc(ip);
   }

        printf("4\n");
    80006b3a:	00002517          	auipc	a0,0x2
    80006b3e:	e6e50513          	addi	a0,a0,-402 # 800089a8 <syscalls+0x4a8>
    80006b42:	ffffa097          	auipc	ra,0xffffa
    80006b46:	a4c080e7          	jalr	-1460(ra) # 8000058e <printf>
   iunlock(ip);
    80006b4a:	854e                	mv	a0,s3
    80006b4c:	ffffd097          	auipc	ra,0xffffd
    80006b50:	f62080e7          	jalr	-158(ra) # 80003aae <iunlock>
   end_op();
    80006b54:	ffffe097          	auipc	ra,0xffffe
    80006b58:	8da080e7          	jalr	-1830(ra) # 8000442e <end_op>

        printf("5\n");
    80006b5c:	00002517          	auipc	a0,0x2
    80006b60:	e5450513          	addi	a0,a0,-428 # 800089b0 <syscalls+0x4b0>
    80006b64:	ffffa097          	auipc	ra,0xffffa
    80006b68:	a2a080e7          	jalr	-1494(ra) # 8000058e <printf>
   return f;
    80006b6c:	a065                	j	80006c14 <open+0x1b8>
            printf("Create Broke\n");
    80006b6e:	00002517          	auipc	a0,0x2
    80006b72:	dfa50513          	addi	a0,a0,-518 # 80008968 <syscalls+0x468>
    80006b76:	ffffa097          	auipc	ra,0xffffa
    80006b7a:	a18080e7          	jalr	-1512(ra) # 8000058e <printf>
            end_op();
    80006b7e:	ffffe097          	auipc	ra,0xffffe
    80006b82:	8b0080e7          	jalr	-1872(ra) # 8000442e <end_op>
            return (struct file *)-1;
    80006b86:	54fd                	li	s1,-1
    80006b88:	a071                	j	80006c14 <open+0x1b8>
        printf("EXSITS ALREADY\n");
    80006b8a:	00002517          	auipc	a0,0x2
    80006b8e:	dee50513          	addi	a0,a0,-530 # 80008978 <syscalls+0x478>
    80006b92:	ffffa097          	auipc	ra,0xffffa
    80006b96:	9fc080e7          	jalr	-1540(ra) # 8000058e <printf>
        if((ip = namei(filename)) == 0){
    80006b9a:	8526                	mv	a0,s1
    80006b9c:	ffffd097          	auipc	ra,0xffffd
    80006ba0:	5f6080e7          	jalr	1526(ra) # 80004192 <namei>
    80006ba4:	89aa                	mv	s3,a0
    80006ba6:	c51d                	beqz	a0,80006bd4 <open+0x178>
        ilock(ip);
    80006ba8:	ffffd097          	auipc	ra,0xffffd
    80006bac:	e44080e7          	jalr	-444(ra) # 800039ec <ilock>
        if(ip->type == T_DIR && omode != O_RDONLY){
    80006bb0:	04499703          	lh	a4,68(s3)
    80006bb4:	4785                	li	a5,1
    80006bb6:	eef71ce3          	bne	a4,a5,80006aae <open+0x52>
    80006bba:	ee090ae3          	beqz	s2,80006aae <open+0x52>
            iunlockput(ip);
    80006bbe:	854e                	mv	a0,s3
    80006bc0:	ffffd097          	auipc	ra,0xffffd
    80006bc4:	08e080e7          	jalr	142(ra) # 80003c4e <iunlockput>
            end_op();
    80006bc8:	ffffe097          	auipc	ra,0xffffe
    80006bcc:	866080e7          	jalr	-1946(ra) # 8000442e <end_op>
            return (struct file *)-1;
    80006bd0:	54fd                	li	s1,-1
    80006bd2:	a089                	j	80006c14 <open+0x1b8>
            end_op();
    80006bd4:	ffffe097          	auipc	ra,0xffffe
    80006bd8:	85a080e7          	jalr	-1958(ra) # 8000442e <end_op>
            printf("OOPs");
    80006bdc:	00002517          	auipc	a0,0x2
    80006be0:	dac50513          	addi	a0,a0,-596 # 80008988 <syscalls+0x488>
    80006be4:	ffffa097          	auipc	ra,0xffffa
    80006be8:	9aa080e7          	jalr	-1622(ra) # 8000058e <printf>
            return (struct file *)-1;
    80006bec:	54fd                	li	s1,-1
    80006bee:	a01d                	j	80006c14 <open+0x1b8>
        iunlockput(ip);
    80006bf0:	854e                	mv	a0,s3
    80006bf2:	ffffd097          	auipc	ra,0xffffd
    80006bf6:	05c080e7          	jalr	92(ra) # 80003c4e <iunlockput>
        end_op();
    80006bfa:	ffffe097          	auipc	ra,0xffffe
    80006bfe:	834080e7          	jalr	-1996(ra) # 8000442e <end_op>
        return (struct file *)-1;
    80006c02:	54fd                	li	s1,-1
    80006c04:	a801                	j	80006c14 <open+0x1b8>
     itrunc(ip);
    80006c06:	854e                	mv	a0,s3
    80006c08:	ffffd097          	auipc	ra,0xffffd
    80006c0c:	ef2080e7          	jalr	-270(ra) # 80003afa <itrunc>
    80006c10:	b72d                	j	80006b3a <open+0xde>
        return (struct file *)-1;
    80006c12:	54fd                	li	s1,-1
}
    80006c14:	8526                	mv	a0,s1
    80006c16:	70a2                	ld	ra,40(sp)
    80006c18:	7402                	ld	s0,32(sp)
    80006c1a:	64e2                	ld	s1,24(sp)
    80006c1c:	6942                	ld	s2,16(sp)
    80006c1e:	69a2                	ld	s3,8(sp)
    80006c20:	6145                	addi	sp,sp,48
    80006c22:	8082                	ret
            fileclose(f);
    80006c24:	8526                	mv	a0,s1
    80006c26:	ffffe097          	auipc	ra,0xffffe
    80006c2a:	c54080e7          	jalr	-940(ra) # 8000487a <fileclose>
        iunlockput(ip);
    80006c2e:	854e                	mv	a0,s3
    80006c30:	ffffd097          	auipc	ra,0xffffd
    80006c34:	01e080e7          	jalr	30(ra) # 80003c4e <iunlockput>
        end_op();
    80006c38:	ffffd097          	auipc	ra,0xffffd
    80006c3c:	7f6080e7          	jalr	2038(ra) # 8000442e <end_op>
        return (struct file *)-1;
    80006c40:	54fd                	li	s1,-1
    80006c42:	bfc9                	j	80006c14 <open+0x1b8>
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
