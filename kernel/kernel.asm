
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	b0013103          	ld	sp,-1280(sp) # 80008b00 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000068:	c8c78793          	addi	a5,a5,-884 # 80005cf0 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd061f>
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
    80000130:	41e080e7          	jalr	1054(ra) # 8000254a <either_copyin>
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
    800001d0:	1c8080e7          	jalr	456(ra) # 80002394 <killed>
    800001d4:	e535                	bnez	a0,80000240 <consoleread+0xdc>
      sleep(&cons.r, &cons.lock);
    800001d6:	85ce                	mv	a1,s3
    800001d8:	854a                	mv	a0,s2
    800001da:	00002097          	auipc	ra,0x2
    800001de:	f12080e7          	jalr	-238(ra) # 800020ec <sleep>
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
    8000021a:	2de080e7          	jalr	734(ra) # 800024f4 <either_copyout>
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
    800002fc:	2a8080e7          	jalr	680(ra) # 800025a0 <procdump>
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
    80000450:	d04080e7          	jalr	-764(ra) # 80002150 <wakeup>
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
    80000482:	bca78793          	addi	a5,a5,-1078 # 8002d048 <devsw>
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
    80000576:	41650513          	addi	a0,a0,1046 # 80008988 <syscalls+0x488>
    8000057a:	00000097          	auipc	ra,0x0
    8000057e:	014080e7          	jalr	20(ra) # 8000058e <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000582:	4785                	li	a5,1
    80000584:	00008717          	auipc	a4,0x8
    80000588:	58f72e23          	sw	a5,1436(a4) # 80008b20 <panicked>
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
    8000080e:	3167a783          	lw	a5,790(a5) # 80008b20 <panicked>
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
    8000084a:	2e273703          	ld	a4,738(a4) # 80008b28 <uart_tx_r>
    8000084e:	00008797          	auipc	a5,0x8
    80000852:	2e27b783          	ld	a5,738(a5) # 80008b30 <uart_tx_w>
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
    8000087c:	2b048493          	addi	s1,s1,688 # 80008b28 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000880:	00008997          	auipc	s3,0x8
    80000884:	2b098993          	addi	s3,s3,688 # 80008b30 <uart_tx_w>
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
    800008aa:	8aa080e7          	jalr	-1878(ra) # 80002150 <wakeup>
    
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
    800008f6:	22e7a783          	lw	a5,558(a5) # 80008b20 <panicked>
    800008fa:	e7c9                	bnez	a5,80000984 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fc:	00008797          	auipc	a5,0x8
    80000900:	2347b783          	ld	a5,564(a5) # 80008b30 <uart_tx_w>
    80000904:	00008717          	auipc	a4,0x8
    80000908:	22473703          	ld	a4,548(a4) # 80008b28 <uart_tx_r>
    8000090c:	02070713          	addi	a4,a4,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00010a17          	auipc	s4,0x10
    80000914:	458a0a13          	addi	s4,s4,1112 # 80010d68 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	21048493          	addi	s1,s1,528 # 80008b28 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	21090913          	addi	s2,s2,528 # 80008b30 <uart_tx_w>
    80000928:	00f71f63          	bne	a4,a5,80000946 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000092c:	85d2                	mv	a1,s4
    8000092e:	8526                	mv	a0,s1
    80000930:	00001097          	auipc	ra,0x1
    80000934:	7bc080e7          	jalr	1980(ra) # 800020ec <sleep>
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
    8000095e:	1cf73b23          	sd	a5,470(a4) # 80008b30 <uart_tx_w>
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
    80000a12:	0002d797          	auipc	a5,0x2d
    80000a16:	7ce78793          	addi	a5,a5,1998 # 8002e1e0 <end>
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
    80000ae2:	0002d517          	auipc	a0,0x2d
    80000ae6:	6fe50513          	addi	a0,a0,1790 # 8002e1e0 <end>
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
    80000ea8:	c9470713          	addi	a4,a4,-876 # 80008b38 <started>
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
    80000ede:	806080e7          	jalr	-2042(ra) # 800026e0 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ee2:	00005097          	auipc	ra,0x5
    80000ee6:	e4e080e7          	jalr	-434(ra) # 80005d30 <plicinithart>
  }

  scheduler();        
    80000eea:	00001097          	auipc	ra,0x1
    80000eee:	026080e7          	jalr	38(ra) # 80001f10 <scheduler>
    consoleinit();
    80000ef2:	fffff097          	auipc	ra,0xfffff
    80000ef6:	564080e7          	jalr	1380(ra) # 80000456 <consoleinit>
    printfinit();
    80000efa:	00000097          	auipc	ra,0x0
    80000efe:	87a080e7          	jalr	-1926(ra) # 80000774 <printfinit>
    printf("\n");
    80000f02:	00008517          	auipc	a0,0x8
    80000f06:	a8650513          	addi	a0,a0,-1402 # 80008988 <syscalls+0x488>
    80000f0a:	fffff097          	auipc	ra,0xfffff
    80000f0e:	684080e7          	jalr	1668(ra) # 8000058e <printf>
    printf("xv6 kernel is booting\n");
    80000f12:	00007517          	auipc	a0,0x7
    80000f16:	18e50513          	addi	a0,a0,398 # 800080a0 <digits+0x60>
    80000f1a:	fffff097          	auipc	ra,0xfffff
    80000f1e:	674080e7          	jalr	1652(ra) # 8000058e <printf>
    printf("\n");
    80000f22:	00008517          	auipc	a0,0x8
    80000f26:	a6650513          	addi	a0,a0,-1434 # 80008988 <syscalls+0x488>
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
    80000f56:	766080e7          	jalr	1894(ra) # 800026b8 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f5a:	00001097          	auipc	ra,0x1
    80000f5e:	786080e7          	jalr	1926(ra) # 800026e0 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f62:	00005097          	auipc	ra,0x5
    80000f66:	db8080e7          	jalr	-584(ra) # 80005d1a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f6a:	00005097          	auipc	ra,0x5
    80000f6e:	dc6080e7          	jalr	-570(ra) # 80005d30 <plicinithart>
    binit();         // buffer cache
    80000f72:	00002097          	auipc	ra,0x2
    80000f76:	f80080e7          	jalr	-128(ra) # 80002ef2 <binit>
    iinit();         // inode table
    80000f7a:	00002097          	auipc	ra,0x2
    80000f7e:	624080e7          	jalr	1572(ra) # 8000359e <iinit>
    fileinit();      // file table
    80000f82:	00003097          	auipc	ra,0x3
    80000f86:	5c2080e7          	jalr	1474(ra) # 80004544 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f8a:	00005097          	auipc	ra,0x5
    80000f8e:	eae080e7          	jalr	-338(ra) # 80005e38 <virtio_disk_init>
    userinit();      // first user process
    80000f92:	00001097          	auipc	ra,0x1
    80000f96:	d0c080e7          	jalr	-756(ra) # 80001c9e <userinit>
    __sync_synchronize();
    80000f9a:	0ff0000f          	fence
    started = 1;
    80000f9e:	4785                	li	a5,1
    80000fa0:	00008717          	auipc	a4,0x8
    80000fa4:	b8f72c23          	sw	a5,-1128(a4) # 80008b38 <started>
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
    80000fb8:	b8c7b783          	ld	a5,-1140(a5) # 80008b40 <kernel_pagetable>
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
    80001274:	8ca7b823          	sd	a0,-1840(a5) # 80008b40 <kernel_pagetable>
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
    80001a1a:	fca7a783          	lw	a5,-54(a5) # 800089e0 <first.1713>
    80001a1e:	eb89                	bnez	a5,80001a30 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a20:	00001097          	auipc	ra,0x1
    80001a24:	cd8080e7          	jalr	-808(ra) # 800026f8 <usertrapret>
}
    80001a28:	60a2                	ld	ra,8(sp)
    80001a2a:	6402                	ld	s0,0(sp)
    80001a2c:	0141                	addi	sp,sp,16
    80001a2e:	8082                	ret
    first = 0;
    80001a30:	00007797          	auipc	a5,0x7
    80001a34:	fa07a823          	sw	zero,-80(a5) # 800089e0 <first.1713>
    fsinit(ROOTDEV);
    80001a38:	4505                	li	a0,1
    80001a3a:	00002097          	auipc	ra,0x2
    80001a3e:	ae4080e7          	jalr	-1308(ra) # 8000351e <fsinit>
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
    80001a66:	f8278793          	addi	a5,a5,-126 # 800089e4 <nextpid>
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
    80001cb6:	e8a7bf23          	sd	a0,-354(a5) # 80008b50 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cba:	03400613          	li	a2,52
    80001cbe:	00007597          	auipc	a1,0x7
    80001cc2:	d3258593          	addi	a1,a1,-718 # 800089f0 <initcode>
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
    80001d00:	244080e7          	jalr	580(ra) # 80003f40 <namei>
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
    80001e1a:	00002097          	auipc	ra,0x2
    80001e1e:	7bc080e7          	jalr	1980(ra) # 800045d6 <filedup>
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
    80001e40:	920080e7          	jalr	-1760(ra) # 8000375c <idup>
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
    80001ecc:	c907a783          	lw	a5,-880(a5) # 80008b58 <ticks>
    80001ed0:	00007717          	auipc	a4,0x7
    80001ed4:	c7872703          	lw	a4,-904(a4) # 80008b48 <prev_tick>
    80001ed8:	9f99                	subw	a5,a5,a4
    80001eda:	03200713          	li	a4,50
    80001ede:	00f76463          	bltu	a4,a5,80001ee6 <check+0x1e>
    return 0;
    80001ee2:	4501                	li	a0,0
}
    80001ee4:	8082                	ret
check(void *list){
    80001ee6:	1141                	addi	sp,sp,-16
    80001ee8:	e406                	sd	ra,8(sp)
    80001eea:	e022                	sd	s0,0(sp)
    80001eec:	0800                	addi	s0,sp,16
	write_to_logs(list);
    80001eee:	00004097          	auipc	ra,0x4
    80001ef2:	4e8080e7          	jalr	1256(ra) # 800063d6 <write_to_logs>
	prev_tick = ticks;
    80001ef6:	00007797          	auipc	a5,0x7
    80001efa:	c627a783          	lw	a5,-926(a5) # 80008b58 <ticks>
    80001efe:	00007717          	auipc	a4,0x7
    80001f02:	c4f72523          	sw	a5,-950(a4) # 80008b48 <prev_tick>
	return 1;
    80001f06:	4505                	li	a0,1
}
    80001f08:	60a2                	ld	ra,8(sp)
    80001f0a:	6402                	ld	s0,0(sp)
    80001f0c:	0141                	addi	sp,sp,16
    80001f0e:	8082                	ret

0000000080001f10 <scheduler>:
{
    80001f10:	715d                	addi	sp,sp,-80
    80001f12:	e486                	sd	ra,72(sp)
    80001f14:	e0a2                	sd	s0,64(sp)
    80001f16:	fc26                	sd	s1,56(sp)
    80001f18:	f84a                	sd	s2,48(sp)
    80001f1a:	f44e                	sd	s3,40(sp)
    80001f1c:	f052                	sd	s4,32(sp)
    80001f1e:	ec56                	sd	s5,24(sp)
    80001f20:	e85a                	sd	s6,16(sp)
    80001f22:	e45e                	sd	s7,8(sp)
    80001f24:	e062                	sd	s8,0(sp)
    80001f26:	0880                	addi	s0,sp,80
    80001f28:	8492                	mv	s1,tp
  int id = r_tp();
    80001f2a:	2481                	sext.w	s1,s1
  init_list_head(&runq);
    80001f2c:	0000f517          	auipc	a0,0xf
    80001f30:	2c450513          	addi	a0,a0,708 # 800111f0 <runq>
    80001f34:	00004097          	auipc	ra,0x4
    80001f38:	436080e7          	jalr	1078(ra) # 8000636a <init_list_head>
  c->proc = 0;
    80001f3c:	00749b13          	slli	s6,s1,0x7
    80001f40:	0000f797          	auipc	a5,0xf
    80001f44:	e8078793          	addi	a5,a5,-384 # 80010dc0 <pid_lock>
    80001f48:	97da                	add	a5,a5,s6
    80001f4a:	0207b823          	sd	zero,48(a5)
        swtch(&c->context, &p->context);
    80001f4e:	0000f797          	auipc	a5,0xf
    80001f52:	eaa78793          	addi	a5,a5,-342 # 80010df8 <cpus+0x8>
    80001f56:	9b3e                	add	s6,s6,a5
        p->state = RUNNING;
    80001f58:	4b91                	li	s7,4
        c->proc = p;
    80001f5a:	049e                	slli	s1,s1,0x7
    80001f5c:	0000fa97          	auipc	s5,0xf
    80001f60:	e64a8a93          	addi	s5,s5,-412 # 80010dc0 <pid_lock>
    80001f64:	9aa6                	add	s5,s5,s1
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f66:	00015a17          	auipc	s4,0x15
    80001f6a:	e9aa0a13          	addi	s4,s4,-358 # 80016e00 <tickslock>
    not_runnable_count = 0;
    80001f6e:	4c01                	li	s8,0
    80001f70:	a0a9                	j	80001fba <scheduler+0xaa>
        p->state = RUNNING;
    80001f72:	0174ac23          	sw	s7,24(s1)
        c->proc = p;
    80001f76:	029ab823          	sd	s1,48(s5)
        swtch(&c->context, &p->context);
    80001f7a:	06048593          	addi	a1,s1,96
    80001f7e:	855a                	mv	a0,s6
    80001f80:	00000097          	auipc	ra,0x0
    80001f84:	6ce080e7          	jalr	1742(ra) # 8000264e <swtch>
        c->proc = 0;
    80001f88:	020ab823          	sd	zero,48(s5)
      release(&p->lock);
    80001f8c:	8526                	mv	a0,s1
    80001f8e:	fffff097          	auipc	ra,0xfffff
    80001f92:	d10080e7          	jalr	-752(ra) # 80000c9e <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f96:	17048493          	addi	s1,s1,368
    80001f9a:	01448c63          	beq	s1,s4,80001fb2 <scheduler+0xa2>
      acquire(&p->lock);
    80001f9e:	8526                	mv	a0,s1
    80001fa0:	fffff097          	auipc	ra,0xfffff
    80001fa4:	c4a080e7          	jalr	-950(ra) # 80000bea <acquire>
      if(p->state == RUNNABLE) {
    80001fa8:	4c9c                	lw	a5,24(s1)
    80001faa:	fd3784e3          	beq	a5,s3,80001f72 <scheduler+0x62>
        not_runnable_count++;
    80001fae:	2905                	addiw	s2,s2,1
    80001fb0:	bff1                	j	80001f8c <scheduler+0x7c>
    if (not_runnable_count == NPROC) {
    80001fb2:	04000793          	li	a5,64
    80001fb6:	00f90f63          	beq	s2,a5,80001fd4 <scheduler+0xc4>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fba:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001fbe:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001fc2:	10079073          	csrw	sstatus,a5
    not_runnable_count = 0;
    80001fc6:	8962                	mv	s2,s8
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fc8:	0000f497          	auipc	s1,0xf
    80001fcc:	23848493          	addi	s1,s1,568 # 80011200 <proc>
      if(p->state == RUNNABLE) {
    80001fd0:	498d                	li	s3,3
    80001fd2:	b7f1                	j	80001f9e <scheduler+0x8e>
  asm volatile("wfi");
    80001fd4:	10500073          	wfi
}
    80001fd8:	b7cd                	j	80001fba <scheduler+0xaa>

0000000080001fda <sched>:
{
    80001fda:	7179                	addi	sp,sp,-48
    80001fdc:	f406                	sd	ra,40(sp)
    80001fde:	f022                	sd	s0,32(sp)
    80001fe0:	ec26                	sd	s1,24(sp)
    80001fe2:	e84a                	sd	s2,16(sp)
    80001fe4:	e44e                	sd	s3,8(sp)
    80001fe6:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001fe8:	00000097          	auipc	ra,0x0
    80001fec:	9de080e7          	jalr	-1570(ra) # 800019c6 <myproc>
    80001ff0:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001ff2:	fffff097          	auipc	ra,0xfffff
    80001ff6:	b7e080e7          	jalr	-1154(ra) # 80000b70 <holding>
    80001ffa:	c93d                	beqz	a0,80002070 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001ffc:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001ffe:	2781                	sext.w	a5,a5
    80002000:	079e                	slli	a5,a5,0x7
    80002002:	0000f717          	auipc	a4,0xf
    80002006:	dbe70713          	addi	a4,a4,-578 # 80010dc0 <pid_lock>
    8000200a:	97ba                	add	a5,a5,a4
    8000200c:	0a87a703          	lw	a4,168(a5)
    80002010:	4785                	li	a5,1
    80002012:	06f71763          	bne	a4,a5,80002080 <sched+0xa6>
  if(p->state == RUNNING)
    80002016:	4c98                	lw	a4,24(s1)
    80002018:	4791                	li	a5,4
    8000201a:	06f70b63          	beq	a4,a5,80002090 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000201e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002022:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002024:	efb5                	bnez	a5,800020a0 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002026:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002028:	0000f917          	auipc	s2,0xf
    8000202c:	d9890913          	addi	s2,s2,-616 # 80010dc0 <pid_lock>
    80002030:	2781                	sext.w	a5,a5
    80002032:	079e                	slli	a5,a5,0x7
    80002034:	97ca                	add	a5,a5,s2
    80002036:	0ac7a983          	lw	s3,172(a5)
    8000203a:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000203c:	2781                	sext.w	a5,a5
    8000203e:	079e                	slli	a5,a5,0x7
    80002040:	0000f597          	auipc	a1,0xf
    80002044:	db858593          	addi	a1,a1,-584 # 80010df8 <cpus+0x8>
    80002048:	95be                	add	a1,a1,a5
    8000204a:	06048513          	addi	a0,s1,96
    8000204e:	00000097          	auipc	ra,0x0
    80002052:	600080e7          	jalr	1536(ra) # 8000264e <swtch>
    80002056:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002058:	2781                	sext.w	a5,a5
    8000205a:	079e                	slli	a5,a5,0x7
    8000205c:	97ca                	add	a5,a5,s2
    8000205e:	0b37a623          	sw	s3,172(a5)
}
    80002062:	70a2                	ld	ra,40(sp)
    80002064:	7402                	ld	s0,32(sp)
    80002066:	64e2                	ld	s1,24(sp)
    80002068:	6942                	ld	s2,16(sp)
    8000206a:	69a2                	ld	s3,8(sp)
    8000206c:	6145                	addi	sp,sp,48
    8000206e:	8082                	ret
    panic("sched p->lock");
    80002070:	00006517          	auipc	a0,0x6
    80002074:	1a850513          	addi	a0,a0,424 # 80008218 <digits+0x1d8>
    80002078:	ffffe097          	auipc	ra,0xffffe
    8000207c:	4cc080e7          	jalr	1228(ra) # 80000544 <panic>
    panic("sched locks");
    80002080:	00006517          	auipc	a0,0x6
    80002084:	1a850513          	addi	a0,a0,424 # 80008228 <digits+0x1e8>
    80002088:	ffffe097          	auipc	ra,0xffffe
    8000208c:	4bc080e7          	jalr	1212(ra) # 80000544 <panic>
    panic("sched running");
    80002090:	00006517          	auipc	a0,0x6
    80002094:	1a850513          	addi	a0,a0,424 # 80008238 <digits+0x1f8>
    80002098:	ffffe097          	auipc	ra,0xffffe
    8000209c:	4ac080e7          	jalr	1196(ra) # 80000544 <panic>
    panic("sched interruptible");
    800020a0:	00006517          	auipc	a0,0x6
    800020a4:	1a850513          	addi	a0,a0,424 # 80008248 <digits+0x208>
    800020a8:	ffffe097          	auipc	ra,0xffffe
    800020ac:	49c080e7          	jalr	1180(ra) # 80000544 <panic>

00000000800020b0 <yield>:
{
    800020b0:	1101                	addi	sp,sp,-32
    800020b2:	ec06                	sd	ra,24(sp)
    800020b4:	e822                	sd	s0,16(sp)
    800020b6:	e426                	sd	s1,8(sp)
    800020b8:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800020ba:	00000097          	auipc	ra,0x0
    800020be:	90c080e7          	jalr	-1780(ra) # 800019c6 <myproc>
    800020c2:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020c4:	fffff097          	auipc	ra,0xfffff
    800020c8:	b26080e7          	jalr	-1242(ra) # 80000bea <acquire>
  p->state = RUNNABLE;
    800020cc:	478d                	li	a5,3
    800020ce:	cc9c                	sw	a5,24(s1)
  sched();
    800020d0:	00000097          	auipc	ra,0x0
    800020d4:	f0a080e7          	jalr	-246(ra) # 80001fda <sched>
  release(&p->lock);
    800020d8:	8526                	mv	a0,s1
    800020da:	fffff097          	auipc	ra,0xfffff
    800020de:	bc4080e7          	jalr	-1084(ra) # 80000c9e <release>
}
    800020e2:	60e2                	ld	ra,24(sp)
    800020e4:	6442                	ld	s0,16(sp)
    800020e6:	64a2                	ld	s1,8(sp)
    800020e8:	6105                	addi	sp,sp,32
    800020ea:	8082                	ret

00000000800020ec <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800020ec:	7179                	addi	sp,sp,-48
    800020ee:	f406                	sd	ra,40(sp)
    800020f0:	f022                	sd	s0,32(sp)
    800020f2:	ec26                	sd	s1,24(sp)
    800020f4:	e84a                	sd	s2,16(sp)
    800020f6:	e44e                	sd	s3,8(sp)
    800020f8:	1800                	addi	s0,sp,48
    800020fa:	89aa                	mv	s3,a0
    800020fc:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800020fe:	00000097          	auipc	ra,0x0
    80002102:	8c8080e7          	jalr	-1848(ra) # 800019c6 <myproc>
    80002106:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80002108:	fffff097          	auipc	ra,0xfffff
    8000210c:	ae2080e7          	jalr	-1310(ra) # 80000bea <acquire>
  release(lk);
    80002110:	854a                	mv	a0,s2
    80002112:	fffff097          	auipc	ra,0xfffff
    80002116:	b8c080e7          	jalr	-1140(ra) # 80000c9e <release>

  // Go to sleep.
  p->chan = chan;
    8000211a:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    8000211e:	4789                	li	a5,2
    80002120:	cc9c                	sw	a5,24(s1)

  sched();
    80002122:	00000097          	auipc	ra,0x0
    80002126:	eb8080e7          	jalr	-328(ra) # 80001fda <sched>

  // Tidy up.
  p->chan = 0;
    8000212a:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    8000212e:	8526                	mv	a0,s1
    80002130:	fffff097          	auipc	ra,0xfffff
    80002134:	b6e080e7          	jalr	-1170(ra) # 80000c9e <release>
  acquire(lk);
    80002138:	854a                	mv	a0,s2
    8000213a:	fffff097          	auipc	ra,0xfffff
    8000213e:	ab0080e7          	jalr	-1360(ra) # 80000bea <acquire>
}
    80002142:	70a2                	ld	ra,40(sp)
    80002144:	7402                	ld	s0,32(sp)
    80002146:	64e2                	ld	s1,24(sp)
    80002148:	6942                	ld	s2,16(sp)
    8000214a:	69a2                	ld	s3,8(sp)
    8000214c:	6145                	addi	sp,sp,48
    8000214e:	8082                	ret

0000000080002150 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002150:	7139                	addi	sp,sp,-64
    80002152:	fc06                	sd	ra,56(sp)
    80002154:	f822                	sd	s0,48(sp)
    80002156:	f426                	sd	s1,40(sp)
    80002158:	f04a                	sd	s2,32(sp)
    8000215a:	ec4e                	sd	s3,24(sp)
    8000215c:	e852                	sd	s4,16(sp)
    8000215e:	e456                	sd	s5,8(sp)
    80002160:	0080                	addi	s0,sp,64
    80002162:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002164:	0000f497          	auipc	s1,0xf
    80002168:	09c48493          	addi	s1,s1,156 # 80011200 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000216c:	4989                	li	s3,2
        p->state = RUNNABLE;
    8000216e:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002170:	00015917          	auipc	s2,0x15
    80002174:	c9090913          	addi	s2,s2,-880 # 80016e00 <tickslock>
    80002178:	a821                	j	80002190 <wakeup+0x40>
        p->state = RUNNABLE;
    8000217a:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    8000217e:	8526                	mv	a0,s1
    80002180:	fffff097          	auipc	ra,0xfffff
    80002184:	b1e080e7          	jalr	-1250(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002188:	17048493          	addi	s1,s1,368
    8000218c:	03248463          	beq	s1,s2,800021b4 <wakeup+0x64>
    if(p != myproc()){
    80002190:	00000097          	auipc	ra,0x0
    80002194:	836080e7          	jalr	-1994(ra) # 800019c6 <myproc>
    80002198:	fea488e3          	beq	s1,a0,80002188 <wakeup+0x38>
      acquire(&p->lock);
    8000219c:	8526                	mv	a0,s1
    8000219e:	fffff097          	auipc	ra,0xfffff
    800021a2:	a4c080e7          	jalr	-1460(ra) # 80000bea <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800021a6:	4c9c                	lw	a5,24(s1)
    800021a8:	fd379be3          	bne	a5,s3,8000217e <wakeup+0x2e>
    800021ac:	709c                	ld	a5,32(s1)
    800021ae:	fd4798e3          	bne	a5,s4,8000217e <wakeup+0x2e>
    800021b2:	b7e1                	j	8000217a <wakeup+0x2a>
    }
  }
}
    800021b4:	70e2                	ld	ra,56(sp)
    800021b6:	7442                	ld	s0,48(sp)
    800021b8:	74a2                	ld	s1,40(sp)
    800021ba:	7902                	ld	s2,32(sp)
    800021bc:	69e2                	ld	s3,24(sp)
    800021be:	6a42                	ld	s4,16(sp)
    800021c0:	6aa2                	ld	s5,8(sp)
    800021c2:	6121                	addi	sp,sp,64
    800021c4:	8082                	ret

00000000800021c6 <reparent>:
{
    800021c6:	7179                	addi	sp,sp,-48
    800021c8:	f406                	sd	ra,40(sp)
    800021ca:	f022                	sd	s0,32(sp)
    800021cc:	ec26                	sd	s1,24(sp)
    800021ce:	e84a                	sd	s2,16(sp)
    800021d0:	e44e                	sd	s3,8(sp)
    800021d2:	e052                	sd	s4,0(sp)
    800021d4:	1800                	addi	s0,sp,48
    800021d6:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021d8:	0000f497          	auipc	s1,0xf
    800021dc:	02848493          	addi	s1,s1,40 # 80011200 <proc>
      pp->parent = initproc;
    800021e0:	00007a17          	auipc	s4,0x7
    800021e4:	970a0a13          	addi	s4,s4,-1680 # 80008b50 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800021e8:	00015997          	auipc	s3,0x15
    800021ec:	c1898993          	addi	s3,s3,-1000 # 80016e00 <tickslock>
    800021f0:	a029                	j	800021fa <reparent+0x34>
    800021f2:	17048493          	addi	s1,s1,368
    800021f6:	01348d63          	beq	s1,s3,80002210 <reparent+0x4a>
    if(pp->parent == p){
    800021fa:	7c9c                	ld	a5,56(s1)
    800021fc:	ff279be3          	bne	a5,s2,800021f2 <reparent+0x2c>
      pp->parent = initproc;
    80002200:	000a3503          	ld	a0,0(s4)
    80002204:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002206:	00000097          	auipc	ra,0x0
    8000220a:	f4a080e7          	jalr	-182(ra) # 80002150 <wakeup>
    8000220e:	b7d5                	j	800021f2 <reparent+0x2c>
}
    80002210:	70a2                	ld	ra,40(sp)
    80002212:	7402                	ld	s0,32(sp)
    80002214:	64e2                	ld	s1,24(sp)
    80002216:	6942                	ld	s2,16(sp)
    80002218:	69a2                	ld	s3,8(sp)
    8000221a:	6a02                	ld	s4,0(sp)
    8000221c:	6145                	addi	sp,sp,48
    8000221e:	8082                	ret

0000000080002220 <exit>:
{
    80002220:	7179                	addi	sp,sp,-48
    80002222:	f406                	sd	ra,40(sp)
    80002224:	f022                	sd	s0,32(sp)
    80002226:	ec26                	sd	s1,24(sp)
    80002228:	e84a                	sd	s2,16(sp)
    8000222a:	e44e                	sd	s3,8(sp)
    8000222c:	e052                	sd	s4,0(sp)
    8000222e:	1800                	addi	s0,sp,48
    80002230:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002232:	fffff097          	auipc	ra,0xfffff
    80002236:	794080e7          	jalr	1940(ra) # 800019c6 <myproc>
    8000223a:	89aa                	mv	s3,a0
  if(p == initproc)
    8000223c:	00007797          	auipc	a5,0x7
    80002240:	9147b783          	ld	a5,-1772(a5) # 80008b50 <initproc>
    80002244:	0d050493          	addi	s1,a0,208
    80002248:	15050913          	addi	s2,a0,336
    8000224c:	02a79363          	bne	a5,a0,80002272 <exit+0x52>
    panic("init exiting");
    80002250:	00006517          	auipc	a0,0x6
    80002254:	01050513          	addi	a0,a0,16 # 80008260 <digits+0x220>
    80002258:	ffffe097          	auipc	ra,0xffffe
    8000225c:	2ec080e7          	jalr	748(ra) # 80000544 <panic>
      fileclose(f);
    80002260:	00002097          	auipc	ra,0x2
    80002264:	3c8080e7          	jalr	968(ra) # 80004628 <fileclose>
      p->ofile[fd] = 0;
    80002268:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000226c:	04a1                	addi	s1,s1,8
    8000226e:	01248563          	beq	s1,s2,80002278 <exit+0x58>
    if(p->ofile[fd]){
    80002272:	6088                	ld	a0,0(s1)
    80002274:	f575                	bnez	a0,80002260 <exit+0x40>
    80002276:	bfdd                	j	8000226c <exit+0x4c>
  begin_op();
    80002278:	00002097          	auipc	ra,0x2
    8000227c:	ee4080e7          	jalr	-284(ra) # 8000415c <begin_op>
  iput(p->cwd);
    80002280:	1509b503          	ld	a0,336(s3)
    80002284:	00001097          	auipc	ra,0x1
    80002288:	6d0080e7          	jalr	1744(ra) # 80003954 <iput>
  end_op();
    8000228c:	00002097          	auipc	ra,0x2
    80002290:	f50080e7          	jalr	-176(ra) # 800041dc <end_op>
  p->cwd = 0;
    80002294:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002298:	0000f497          	auipc	s1,0xf
    8000229c:	b4048493          	addi	s1,s1,-1216 # 80010dd8 <wait_lock>
    800022a0:	8526                	mv	a0,s1
    800022a2:	fffff097          	auipc	ra,0xfffff
    800022a6:	948080e7          	jalr	-1720(ra) # 80000bea <acquire>
  reparent(p);
    800022aa:	854e                	mv	a0,s3
    800022ac:	00000097          	auipc	ra,0x0
    800022b0:	f1a080e7          	jalr	-230(ra) # 800021c6 <reparent>
  wakeup(p->parent);
    800022b4:	0389b503          	ld	a0,56(s3)
    800022b8:	00000097          	auipc	ra,0x0
    800022bc:	e98080e7          	jalr	-360(ra) # 80002150 <wakeup>
  acquire(&p->lock);
    800022c0:	854e                	mv	a0,s3
    800022c2:	fffff097          	auipc	ra,0xfffff
    800022c6:	928080e7          	jalr	-1752(ra) # 80000bea <acquire>
  p->xstate = status;
    800022ca:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800022ce:	4795                	li	a5,5
    800022d0:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800022d4:	8526                	mv	a0,s1
    800022d6:	fffff097          	auipc	ra,0xfffff
    800022da:	9c8080e7          	jalr	-1592(ra) # 80000c9e <release>
  sched();
    800022de:	00000097          	auipc	ra,0x0
    800022e2:	cfc080e7          	jalr	-772(ra) # 80001fda <sched>
  panic("zombie exit");
    800022e6:	00006517          	auipc	a0,0x6
    800022ea:	f8a50513          	addi	a0,a0,-118 # 80008270 <digits+0x230>
    800022ee:	ffffe097          	auipc	ra,0xffffe
    800022f2:	256080e7          	jalr	598(ra) # 80000544 <panic>

00000000800022f6 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800022f6:	7179                	addi	sp,sp,-48
    800022f8:	f406                	sd	ra,40(sp)
    800022fa:	f022                	sd	s0,32(sp)
    800022fc:	ec26                	sd	s1,24(sp)
    800022fe:	e84a                	sd	s2,16(sp)
    80002300:	e44e                	sd	s3,8(sp)
    80002302:	1800                	addi	s0,sp,48
    80002304:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002306:	0000f497          	auipc	s1,0xf
    8000230a:	efa48493          	addi	s1,s1,-262 # 80011200 <proc>
    8000230e:	00015997          	auipc	s3,0x15
    80002312:	af298993          	addi	s3,s3,-1294 # 80016e00 <tickslock>
    acquire(&p->lock);
    80002316:	8526                	mv	a0,s1
    80002318:	fffff097          	auipc	ra,0xfffff
    8000231c:	8d2080e7          	jalr	-1838(ra) # 80000bea <acquire>
    if(p->pid == pid){
    80002320:	589c                	lw	a5,48(s1)
    80002322:	01278d63          	beq	a5,s2,8000233c <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002326:	8526                	mv	a0,s1
    80002328:	fffff097          	auipc	ra,0xfffff
    8000232c:	976080e7          	jalr	-1674(ra) # 80000c9e <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002330:	17048493          	addi	s1,s1,368
    80002334:	ff3491e3          	bne	s1,s3,80002316 <kill+0x20>
  }
  return -1;
    80002338:	557d                	li	a0,-1
    8000233a:	a829                	j	80002354 <kill+0x5e>
      p->killed = 1;
    8000233c:	4785                	li	a5,1
    8000233e:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    80002340:	4c98                	lw	a4,24(s1)
    80002342:	4789                	li	a5,2
    80002344:	00f70f63          	beq	a4,a5,80002362 <kill+0x6c>
      release(&p->lock);
    80002348:	8526                	mv	a0,s1
    8000234a:	fffff097          	auipc	ra,0xfffff
    8000234e:	954080e7          	jalr	-1708(ra) # 80000c9e <release>
      return 0;
    80002352:	4501                	li	a0,0
}
    80002354:	70a2                	ld	ra,40(sp)
    80002356:	7402                	ld	s0,32(sp)
    80002358:	64e2                	ld	s1,24(sp)
    8000235a:	6942                	ld	s2,16(sp)
    8000235c:	69a2                	ld	s3,8(sp)
    8000235e:	6145                	addi	sp,sp,48
    80002360:	8082                	ret
        p->state = RUNNABLE;
    80002362:	478d                	li	a5,3
    80002364:	cc9c                	sw	a5,24(s1)
    80002366:	b7cd                	j	80002348 <kill+0x52>

0000000080002368 <setkilled>:

void
setkilled(struct proc *p)
{
    80002368:	1101                	addi	sp,sp,-32
    8000236a:	ec06                	sd	ra,24(sp)
    8000236c:	e822                	sd	s0,16(sp)
    8000236e:	e426                	sd	s1,8(sp)
    80002370:	1000                	addi	s0,sp,32
    80002372:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002374:	fffff097          	auipc	ra,0xfffff
    80002378:	876080e7          	jalr	-1930(ra) # 80000bea <acquire>
  p->killed = 1;
    8000237c:	4785                	li	a5,1
    8000237e:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002380:	8526                	mv	a0,s1
    80002382:	fffff097          	auipc	ra,0xfffff
    80002386:	91c080e7          	jalr	-1764(ra) # 80000c9e <release>
}
    8000238a:	60e2                	ld	ra,24(sp)
    8000238c:	6442                	ld	s0,16(sp)
    8000238e:	64a2                	ld	s1,8(sp)
    80002390:	6105                	addi	sp,sp,32
    80002392:	8082                	ret

0000000080002394 <killed>:

int
killed(struct proc *p)
{
    80002394:	1101                	addi	sp,sp,-32
    80002396:	ec06                	sd	ra,24(sp)
    80002398:	e822                	sd	s0,16(sp)
    8000239a:	e426                	sd	s1,8(sp)
    8000239c:	e04a                	sd	s2,0(sp)
    8000239e:	1000                	addi	s0,sp,32
    800023a0:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    800023a2:	fffff097          	auipc	ra,0xfffff
    800023a6:	848080e7          	jalr	-1976(ra) # 80000bea <acquire>
  k = p->killed;
    800023aa:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    800023ae:	8526                	mv	a0,s1
    800023b0:	fffff097          	auipc	ra,0xfffff
    800023b4:	8ee080e7          	jalr	-1810(ra) # 80000c9e <release>
  return k;
}
    800023b8:	854a                	mv	a0,s2
    800023ba:	60e2                	ld	ra,24(sp)
    800023bc:	6442                	ld	s0,16(sp)
    800023be:	64a2                	ld	s1,8(sp)
    800023c0:	6902                	ld	s2,0(sp)
    800023c2:	6105                	addi	sp,sp,32
    800023c4:	8082                	ret

00000000800023c6 <wait>:
{
    800023c6:	715d                	addi	sp,sp,-80
    800023c8:	e486                	sd	ra,72(sp)
    800023ca:	e0a2                	sd	s0,64(sp)
    800023cc:	fc26                	sd	s1,56(sp)
    800023ce:	f84a                	sd	s2,48(sp)
    800023d0:	f44e                	sd	s3,40(sp)
    800023d2:	f052                	sd	s4,32(sp)
    800023d4:	ec56                	sd	s5,24(sp)
    800023d6:	e85a                	sd	s6,16(sp)
    800023d8:	e45e                	sd	s7,8(sp)
    800023da:	e062                	sd	s8,0(sp)
    800023dc:	0880                	addi	s0,sp,80
    800023de:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800023e0:	fffff097          	auipc	ra,0xfffff
    800023e4:	5e6080e7          	jalr	1510(ra) # 800019c6 <myproc>
    800023e8:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800023ea:	0000f517          	auipc	a0,0xf
    800023ee:	9ee50513          	addi	a0,a0,-1554 # 80010dd8 <wait_lock>
    800023f2:	ffffe097          	auipc	ra,0xffffe
    800023f6:	7f8080e7          	jalr	2040(ra) # 80000bea <acquire>
    havekids = 0;
    800023fa:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    800023fc:	4a15                	li	s4,5
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800023fe:	00015997          	auipc	s3,0x15
    80002402:	a0298993          	addi	s3,s3,-1534 # 80016e00 <tickslock>
        havekids = 1;
    80002406:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002408:	0000fc17          	auipc	s8,0xf
    8000240c:	9d0c0c13          	addi	s8,s8,-1584 # 80010dd8 <wait_lock>
    havekids = 0;
    80002410:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002412:	0000f497          	auipc	s1,0xf
    80002416:	dee48493          	addi	s1,s1,-530 # 80011200 <proc>
    8000241a:	a0bd                	j	80002488 <wait+0xc2>
          pid = pp->pid;
    8000241c:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002420:	000b0e63          	beqz	s6,8000243c <wait+0x76>
    80002424:	4691                	li	a3,4
    80002426:	02c48613          	addi	a2,s1,44
    8000242a:	85da                	mv	a1,s6
    8000242c:	05093503          	ld	a0,80(s2)
    80002430:	fffff097          	auipc	ra,0xfffff
    80002434:	254080e7          	jalr	596(ra) # 80001684 <copyout>
    80002438:	02054563          	bltz	a0,80002462 <wait+0x9c>
          freeproc(pp);
    8000243c:	8526                	mv	a0,s1
    8000243e:	fffff097          	auipc	ra,0xfffff
    80002442:	73a080e7          	jalr	1850(ra) # 80001b78 <freeproc>
          release(&pp->lock);
    80002446:	8526                	mv	a0,s1
    80002448:	fffff097          	auipc	ra,0xfffff
    8000244c:	856080e7          	jalr	-1962(ra) # 80000c9e <release>
          release(&wait_lock);
    80002450:	0000f517          	auipc	a0,0xf
    80002454:	98850513          	addi	a0,a0,-1656 # 80010dd8 <wait_lock>
    80002458:	fffff097          	auipc	ra,0xfffff
    8000245c:	846080e7          	jalr	-1978(ra) # 80000c9e <release>
          return pid;
    80002460:	a0b5                	j	800024cc <wait+0x106>
            release(&pp->lock);
    80002462:	8526                	mv	a0,s1
    80002464:	fffff097          	auipc	ra,0xfffff
    80002468:	83a080e7          	jalr	-1990(ra) # 80000c9e <release>
            release(&wait_lock);
    8000246c:	0000f517          	auipc	a0,0xf
    80002470:	96c50513          	addi	a0,a0,-1684 # 80010dd8 <wait_lock>
    80002474:	fffff097          	auipc	ra,0xfffff
    80002478:	82a080e7          	jalr	-2006(ra) # 80000c9e <release>
            return -1;
    8000247c:	59fd                	li	s3,-1
    8000247e:	a0b9                	j	800024cc <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002480:	17048493          	addi	s1,s1,368
    80002484:	03348463          	beq	s1,s3,800024ac <wait+0xe6>
      if(pp->parent == p){
    80002488:	7c9c                	ld	a5,56(s1)
    8000248a:	ff279be3          	bne	a5,s2,80002480 <wait+0xba>
        acquire(&pp->lock);
    8000248e:	8526                	mv	a0,s1
    80002490:	ffffe097          	auipc	ra,0xffffe
    80002494:	75a080e7          	jalr	1882(ra) # 80000bea <acquire>
        if(pp->state == ZOMBIE){
    80002498:	4c9c                	lw	a5,24(s1)
    8000249a:	f94781e3          	beq	a5,s4,8000241c <wait+0x56>
        release(&pp->lock);
    8000249e:	8526                	mv	a0,s1
    800024a0:	ffffe097          	auipc	ra,0xffffe
    800024a4:	7fe080e7          	jalr	2046(ra) # 80000c9e <release>
        havekids = 1;
    800024a8:	8756                	mv	a4,s5
    800024aa:	bfd9                	j	80002480 <wait+0xba>
    if(!havekids || killed(p)){
    800024ac:	c719                	beqz	a4,800024ba <wait+0xf4>
    800024ae:	854a                	mv	a0,s2
    800024b0:	00000097          	auipc	ra,0x0
    800024b4:	ee4080e7          	jalr	-284(ra) # 80002394 <killed>
    800024b8:	c51d                	beqz	a0,800024e6 <wait+0x120>
      release(&wait_lock);
    800024ba:	0000f517          	auipc	a0,0xf
    800024be:	91e50513          	addi	a0,a0,-1762 # 80010dd8 <wait_lock>
    800024c2:	ffffe097          	auipc	ra,0xffffe
    800024c6:	7dc080e7          	jalr	2012(ra) # 80000c9e <release>
      return -1;
    800024ca:	59fd                	li	s3,-1
}
    800024cc:	854e                	mv	a0,s3
    800024ce:	60a6                	ld	ra,72(sp)
    800024d0:	6406                	ld	s0,64(sp)
    800024d2:	74e2                	ld	s1,56(sp)
    800024d4:	7942                	ld	s2,48(sp)
    800024d6:	79a2                	ld	s3,40(sp)
    800024d8:	7a02                	ld	s4,32(sp)
    800024da:	6ae2                	ld	s5,24(sp)
    800024dc:	6b42                	ld	s6,16(sp)
    800024de:	6ba2                	ld	s7,8(sp)
    800024e0:	6c02                	ld	s8,0(sp)
    800024e2:	6161                	addi	sp,sp,80
    800024e4:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800024e6:	85e2                	mv	a1,s8
    800024e8:	854a                	mv	a0,s2
    800024ea:	00000097          	auipc	ra,0x0
    800024ee:	c02080e7          	jalr	-1022(ra) # 800020ec <sleep>
    havekids = 0;
    800024f2:	bf39                	j	80002410 <wait+0x4a>

00000000800024f4 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024f4:	7179                	addi	sp,sp,-48
    800024f6:	f406                	sd	ra,40(sp)
    800024f8:	f022                	sd	s0,32(sp)
    800024fa:	ec26                	sd	s1,24(sp)
    800024fc:	e84a                	sd	s2,16(sp)
    800024fe:	e44e                	sd	s3,8(sp)
    80002500:	e052                	sd	s4,0(sp)
    80002502:	1800                	addi	s0,sp,48
    80002504:	84aa                	mv	s1,a0
    80002506:	892e                	mv	s2,a1
    80002508:	89b2                	mv	s3,a2
    8000250a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000250c:	fffff097          	auipc	ra,0xfffff
    80002510:	4ba080e7          	jalr	1210(ra) # 800019c6 <myproc>
  if(user_dst){
    80002514:	c08d                	beqz	s1,80002536 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002516:	86d2                	mv	a3,s4
    80002518:	864e                	mv	a2,s3
    8000251a:	85ca                	mv	a1,s2
    8000251c:	6928                	ld	a0,80(a0)
    8000251e:	fffff097          	auipc	ra,0xfffff
    80002522:	166080e7          	jalr	358(ra) # 80001684 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002526:	70a2                	ld	ra,40(sp)
    80002528:	7402                	ld	s0,32(sp)
    8000252a:	64e2                	ld	s1,24(sp)
    8000252c:	6942                	ld	s2,16(sp)
    8000252e:	69a2                	ld	s3,8(sp)
    80002530:	6a02                	ld	s4,0(sp)
    80002532:	6145                	addi	sp,sp,48
    80002534:	8082                	ret
    memmove((char *)dst, src, len);
    80002536:	000a061b          	sext.w	a2,s4
    8000253a:	85ce                	mv	a1,s3
    8000253c:	854a                	mv	a0,s2
    8000253e:	fffff097          	auipc	ra,0xfffff
    80002542:	808080e7          	jalr	-2040(ra) # 80000d46 <memmove>
    return 0;
    80002546:	8526                	mv	a0,s1
    80002548:	bff9                	j	80002526 <either_copyout+0x32>

000000008000254a <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000254a:	7179                	addi	sp,sp,-48
    8000254c:	f406                	sd	ra,40(sp)
    8000254e:	f022                	sd	s0,32(sp)
    80002550:	ec26                	sd	s1,24(sp)
    80002552:	e84a                	sd	s2,16(sp)
    80002554:	e44e                	sd	s3,8(sp)
    80002556:	e052                	sd	s4,0(sp)
    80002558:	1800                	addi	s0,sp,48
    8000255a:	892a                	mv	s2,a0
    8000255c:	84ae                	mv	s1,a1
    8000255e:	89b2                	mv	s3,a2
    80002560:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002562:	fffff097          	auipc	ra,0xfffff
    80002566:	464080e7          	jalr	1124(ra) # 800019c6 <myproc>
  if(user_src){
    8000256a:	c08d                	beqz	s1,8000258c <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000256c:	86d2                	mv	a3,s4
    8000256e:	864e                	mv	a2,s3
    80002570:	85ca                	mv	a1,s2
    80002572:	6928                	ld	a0,80(a0)
    80002574:	fffff097          	auipc	ra,0xfffff
    80002578:	19c080e7          	jalr	412(ra) # 80001710 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000257c:	70a2                	ld	ra,40(sp)
    8000257e:	7402                	ld	s0,32(sp)
    80002580:	64e2                	ld	s1,24(sp)
    80002582:	6942                	ld	s2,16(sp)
    80002584:	69a2                	ld	s3,8(sp)
    80002586:	6a02                	ld	s4,0(sp)
    80002588:	6145                	addi	sp,sp,48
    8000258a:	8082                	ret
    memmove(dst, (char*)src, len);
    8000258c:	000a061b          	sext.w	a2,s4
    80002590:	85ce                	mv	a1,s3
    80002592:	854a                	mv	a0,s2
    80002594:	ffffe097          	auipc	ra,0xffffe
    80002598:	7b2080e7          	jalr	1970(ra) # 80000d46 <memmove>
    return 0;
    8000259c:	8526                	mv	a0,s1
    8000259e:	bff9                	j	8000257c <either_copyin+0x32>

00000000800025a0 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800025a0:	715d                	addi	sp,sp,-80
    800025a2:	e486                	sd	ra,72(sp)
    800025a4:	e0a2                	sd	s0,64(sp)
    800025a6:	fc26                	sd	s1,56(sp)
    800025a8:	f84a                	sd	s2,48(sp)
    800025aa:	f44e                	sd	s3,40(sp)
    800025ac:	f052                	sd	s4,32(sp)
    800025ae:	ec56                	sd	s5,24(sp)
    800025b0:	e85a                	sd	s6,16(sp)
    800025b2:	e45e                	sd	s7,8(sp)
    800025b4:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800025b6:	00006517          	auipc	a0,0x6
    800025ba:	3d250513          	addi	a0,a0,978 # 80008988 <syscalls+0x488>
    800025be:	ffffe097          	auipc	ra,0xffffe
    800025c2:	fd0080e7          	jalr	-48(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025c6:	0000f497          	auipc	s1,0xf
    800025ca:	d9248493          	addi	s1,s1,-622 # 80011358 <proc+0x158>
    800025ce:	00015917          	auipc	s2,0x15
    800025d2:	98a90913          	addi	s2,s2,-1654 # 80016f58 <bruh+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025d6:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800025d8:	00006997          	auipc	s3,0x6
    800025dc:	ca898993          	addi	s3,s3,-856 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    800025e0:	00006a97          	auipc	s5,0x6
    800025e4:	ca8a8a93          	addi	s5,s5,-856 # 80008288 <digits+0x248>
    printf("\n");
    800025e8:	00006a17          	auipc	s4,0x6
    800025ec:	3a0a0a13          	addi	s4,s4,928 # 80008988 <syscalls+0x488>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025f0:	00006b97          	auipc	s7,0x6
    800025f4:	cd8b8b93          	addi	s7,s7,-808 # 800082c8 <states.1757>
    800025f8:	a00d                	j	8000261a <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800025fa:	ed86a583          	lw	a1,-296(a3)
    800025fe:	8556                	mv	a0,s5
    80002600:	ffffe097          	auipc	ra,0xffffe
    80002604:	f8e080e7          	jalr	-114(ra) # 8000058e <printf>
    printf("\n");
    80002608:	8552                	mv	a0,s4
    8000260a:	ffffe097          	auipc	ra,0xffffe
    8000260e:	f84080e7          	jalr	-124(ra) # 8000058e <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002612:	17048493          	addi	s1,s1,368
    80002616:	03248163          	beq	s1,s2,80002638 <procdump+0x98>
    if(p->state == UNUSED)
    8000261a:	86a6                	mv	a3,s1
    8000261c:	ec04a783          	lw	a5,-320(s1)
    80002620:	dbed                	beqz	a5,80002612 <procdump+0x72>
      state = "???";
    80002622:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002624:	fcfb6be3          	bltu	s6,a5,800025fa <procdump+0x5a>
    80002628:	1782                	slli	a5,a5,0x20
    8000262a:	9381                	srli	a5,a5,0x20
    8000262c:	078e                	slli	a5,a5,0x3
    8000262e:	97de                	add	a5,a5,s7
    80002630:	6390                	ld	a2,0(a5)
    80002632:	f661                	bnez	a2,800025fa <procdump+0x5a>
      state = "???";
    80002634:	864e                	mv	a2,s3
    80002636:	b7d1                	j	800025fa <procdump+0x5a>
  }
}
    80002638:	60a6                	ld	ra,72(sp)
    8000263a:	6406                	ld	s0,64(sp)
    8000263c:	74e2                	ld	s1,56(sp)
    8000263e:	7942                	ld	s2,48(sp)
    80002640:	79a2                	ld	s3,40(sp)
    80002642:	7a02                	ld	s4,32(sp)
    80002644:	6ae2                	ld	s5,24(sp)
    80002646:	6b42                	ld	s6,16(sp)
    80002648:	6ba2                	ld	s7,8(sp)
    8000264a:	6161                	addi	sp,sp,80
    8000264c:	8082                	ret

000000008000264e <swtch>:
    8000264e:	00153023          	sd	ra,0(a0)
    80002652:	00253423          	sd	sp,8(a0)
    80002656:	e900                	sd	s0,16(a0)
    80002658:	ed04                	sd	s1,24(a0)
    8000265a:	03253023          	sd	s2,32(a0)
    8000265e:	03353423          	sd	s3,40(a0)
    80002662:	03453823          	sd	s4,48(a0)
    80002666:	03553c23          	sd	s5,56(a0)
    8000266a:	05653023          	sd	s6,64(a0)
    8000266e:	05753423          	sd	s7,72(a0)
    80002672:	05853823          	sd	s8,80(a0)
    80002676:	05953c23          	sd	s9,88(a0)
    8000267a:	07a53023          	sd	s10,96(a0)
    8000267e:	07b53423          	sd	s11,104(a0)
    80002682:	0005b083          	ld	ra,0(a1)
    80002686:	0085b103          	ld	sp,8(a1)
    8000268a:	6980                	ld	s0,16(a1)
    8000268c:	6d84                	ld	s1,24(a1)
    8000268e:	0205b903          	ld	s2,32(a1)
    80002692:	0285b983          	ld	s3,40(a1)
    80002696:	0305ba03          	ld	s4,48(a1)
    8000269a:	0385ba83          	ld	s5,56(a1)
    8000269e:	0405bb03          	ld	s6,64(a1)
    800026a2:	0485bb83          	ld	s7,72(a1)
    800026a6:	0505bc03          	ld	s8,80(a1)
    800026aa:	0585bc83          	ld	s9,88(a1)
    800026ae:	0605bd03          	ld	s10,96(a1)
    800026b2:	0685bd83          	ld	s11,104(a1)
    800026b6:	8082                	ret

00000000800026b8 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026b8:	1141                	addi	sp,sp,-16
    800026ba:	e406                	sd	ra,8(sp)
    800026bc:	e022                	sd	s0,0(sp)
    800026be:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026c0:	00006597          	auipc	a1,0x6
    800026c4:	c3858593          	addi	a1,a1,-968 # 800082f8 <states.1757+0x30>
    800026c8:	00014517          	auipc	a0,0x14
    800026cc:	73850513          	addi	a0,a0,1848 # 80016e00 <tickslock>
    800026d0:	ffffe097          	auipc	ra,0xffffe
    800026d4:	48a080e7          	jalr	1162(ra) # 80000b5a <initlock>
}
    800026d8:	60a2                	ld	ra,8(sp)
    800026da:	6402                	ld	s0,0(sp)
    800026dc:	0141                	addi	sp,sp,16
    800026de:	8082                	ret

00000000800026e0 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800026e0:	1141                	addi	sp,sp,-16
    800026e2:	e422                	sd	s0,8(sp)
    800026e4:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026e6:	00003797          	auipc	a5,0x3
    800026ea:	57a78793          	addi	a5,a5,1402 # 80005c60 <kernelvec>
    800026ee:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800026f2:	6422                	ld	s0,8(sp)
    800026f4:	0141                	addi	sp,sp,16
    800026f6:	8082                	ret

00000000800026f8 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800026f8:	1141                	addi	sp,sp,-16
    800026fa:	e406                	sd	ra,8(sp)
    800026fc:	e022                	sd	s0,0(sp)
    800026fe:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002700:	fffff097          	auipc	ra,0xfffff
    80002704:	2c6080e7          	jalr	710(ra) # 800019c6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002708:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000270c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000270e:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002712:	00005617          	auipc	a2,0x5
    80002716:	8ee60613          	addi	a2,a2,-1810 # 80007000 <_trampoline>
    8000271a:	00005697          	auipc	a3,0x5
    8000271e:	8e668693          	addi	a3,a3,-1818 # 80007000 <_trampoline>
    80002722:	8e91                	sub	a3,a3,a2
    80002724:	040007b7          	lui	a5,0x4000
    80002728:	17fd                	addi	a5,a5,-1
    8000272a:	07b2                	slli	a5,a5,0xc
    8000272c:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000272e:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002732:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002734:	180026f3          	csrr	a3,satp
    80002738:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000273a:	6d38                	ld	a4,88(a0)
    8000273c:	6134                	ld	a3,64(a0)
    8000273e:	6585                	lui	a1,0x1
    80002740:	96ae                	add	a3,a3,a1
    80002742:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002744:	6d38                	ld	a4,88(a0)
    80002746:	00000697          	auipc	a3,0x0
    8000274a:	13068693          	addi	a3,a3,304 # 80002876 <usertrap>
    8000274e:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002750:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002752:	8692                	mv	a3,tp
    80002754:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002756:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000275a:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000275e:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002762:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002766:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002768:	6f18                	ld	a4,24(a4)
    8000276a:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000276e:	6928                	ld	a0,80(a0)
    80002770:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002772:	00005717          	auipc	a4,0x5
    80002776:	92a70713          	addi	a4,a4,-1750 # 8000709c <userret>
    8000277a:	8f11                	sub	a4,a4,a2
    8000277c:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    8000277e:	577d                	li	a4,-1
    80002780:	177e                	slli	a4,a4,0x3f
    80002782:	8d59                	or	a0,a0,a4
    80002784:	9782                	jalr	a5
}
    80002786:	60a2                	ld	ra,8(sp)
    80002788:	6402                	ld	s0,0(sp)
    8000278a:	0141                	addi	sp,sp,16
    8000278c:	8082                	ret

000000008000278e <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000278e:	1101                	addi	sp,sp,-32
    80002790:	ec06                	sd	ra,24(sp)
    80002792:	e822                	sd	s0,16(sp)
    80002794:	e426                	sd	s1,8(sp)
    80002796:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002798:	00014497          	auipc	s1,0x14
    8000279c:	66848493          	addi	s1,s1,1640 # 80016e00 <tickslock>
    800027a0:	8526                	mv	a0,s1
    800027a2:	ffffe097          	auipc	ra,0xffffe
    800027a6:	448080e7          	jalr	1096(ra) # 80000bea <acquire>
  ticks++;
    800027aa:	00006517          	auipc	a0,0x6
    800027ae:	3ae50513          	addi	a0,a0,942 # 80008b58 <ticks>
    800027b2:	411c                	lw	a5,0(a0)
    800027b4:	2785                	addiw	a5,a5,1
    800027b6:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800027b8:	00000097          	auipc	ra,0x0
    800027bc:	998080e7          	jalr	-1640(ra) # 80002150 <wakeup>
  release(&tickslock);
    800027c0:	8526                	mv	a0,s1
    800027c2:	ffffe097          	auipc	ra,0xffffe
    800027c6:	4dc080e7          	jalr	1244(ra) # 80000c9e <release>
}
    800027ca:	60e2                	ld	ra,24(sp)
    800027cc:	6442                	ld	s0,16(sp)
    800027ce:	64a2                	ld	s1,8(sp)
    800027d0:	6105                	addi	sp,sp,32
    800027d2:	8082                	ret

00000000800027d4 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800027d4:	1101                	addi	sp,sp,-32
    800027d6:	ec06                	sd	ra,24(sp)
    800027d8:	e822                	sd	s0,16(sp)
    800027da:	e426                	sd	s1,8(sp)
    800027dc:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027de:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800027e2:	00074d63          	bltz	a4,800027fc <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800027e6:	57fd                	li	a5,-1
    800027e8:	17fe                	slli	a5,a5,0x3f
    800027ea:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800027ec:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800027ee:	06f70363          	beq	a4,a5,80002854 <devintr+0x80>
  }
}
    800027f2:	60e2                	ld	ra,24(sp)
    800027f4:	6442                	ld	s0,16(sp)
    800027f6:	64a2                	ld	s1,8(sp)
    800027f8:	6105                	addi	sp,sp,32
    800027fa:	8082                	ret
     (scause & 0xff) == 9){
    800027fc:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002800:	46a5                	li	a3,9
    80002802:	fed792e3          	bne	a5,a3,800027e6 <devintr+0x12>
    int irq = plic_claim();
    80002806:	00003097          	auipc	ra,0x3
    8000280a:	562080e7          	jalr	1378(ra) # 80005d68 <plic_claim>
    8000280e:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002810:	47a9                	li	a5,10
    80002812:	02f50763          	beq	a0,a5,80002840 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002816:	4785                	li	a5,1
    80002818:	02f50963          	beq	a0,a5,8000284a <devintr+0x76>
    return 1;
    8000281c:	4505                	li	a0,1
    } else if(irq){
    8000281e:	d8f1                	beqz	s1,800027f2 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002820:	85a6                	mv	a1,s1
    80002822:	00006517          	auipc	a0,0x6
    80002826:	ade50513          	addi	a0,a0,-1314 # 80008300 <states.1757+0x38>
    8000282a:	ffffe097          	auipc	ra,0xffffe
    8000282e:	d64080e7          	jalr	-668(ra) # 8000058e <printf>
      plic_complete(irq);
    80002832:	8526                	mv	a0,s1
    80002834:	00003097          	auipc	ra,0x3
    80002838:	558080e7          	jalr	1368(ra) # 80005d8c <plic_complete>
    return 1;
    8000283c:	4505                	li	a0,1
    8000283e:	bf55                	j	800027f2 <devintr+0x1e>
      uartintr();
    80002840:	ffffe097          	auipc	ra,0xffffe
    80002844:	16e080e7          	jalr	366(ra) # 800009ae <uartintr>
    80002848:	b7ed                	j	80002832 <devintr+0x5e>
      virtio_disk_intr();
    8000284a:	00004097          	auipc	ra,0x4
    8000284e:	a6c080e7          	jalr	-1428(ra) # 800062b6 <virtio_disk_intr>
    80002852:	b7c5                	j	80002832 <devintr+0x5e>
    if(cpuid() == 0){
    80002854:	fffff097          	auipc	ra,0xfffff
    80002858:	146080e7          	jalr	326(ra) # 8000199a <cpuid>
    8000285c:	c901                	beqz	a0,8000286c <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000285e:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002862:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002864:	14479073          	csrw	sip,a5
    return 2;
    80002868:	4509                	li	a0,2
    8000286a:	b761                	j	800027f2 <devintr+0x1e>
      clockintr();
    8000286c:	00000097          	auipc	ra,0x0
    80002870:	f22080e7          	jalr	-222(ra) # 8000278e <clockintr>
    80002874:	b7ed                	j	8000285e <devintr+0x8a>

0000000080002876 <usertrap>:
{
    80002876:	1101                	addi	sp,sp,-32
    80002878:	ec06                	sd	ra,24(sp)
    8000287a:	e822                	sd	s0,16(sp)
    8000287c:	e426                	sd	s1,8(sp)
    8000287e:	e04a                	sd	s2,0(sp)
    80002880:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002882:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002886:	1007f793          	andi	a5,a5,256
    8000288a:	e3b1                	bnez	a5,800028ce <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000288c:	00003797          	auipc	a5,0x3
    80002890:	3d478793          	addi	a5,a5,980 # 80005c60 <kernelvec>
    80002894:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002898:	fffff097          	auipc	ra,0xfffff
    8000289c:	12e080e7          	jalr	302(ra) # 800019c6 <myproc>
    800028a0:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800028a2:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028a4:	14102773          	csrr	a4,sepc
    800028a8:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028aa:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800028ae:	47a1                	li	a5,8
    800028b0:	02f70763          	beq	a4,a5,800028de <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    800028b4:	00000097          	auipc	ra,0x0
    800028b8:	f20080e7          	jalr	-224(ra) # 800027d4 <devintr>
    800028bc:	892a                	mv	s2,a0
    800028be:	c151                	beqz	a0,80002942 <usertrap+0xcc>
  if(killed(p))
    800028c0:	8526                	mv	a0,s1
    800028c2:	00000097          	auipc	ra,0x0
    800028c6:	ad2080e7          	jalr	-1326(ra) # 80002394 <killed>
    800028ca:	c929                	beqz	a0,8000291c <usertrap+0xa6>
    800028cc:	a099                	j	80002912 <usertrap+0x9c>
    panic("usertrap: not from user mode");
    800028ce:	00006517          	auipc	a0,0x6
    800028d2:	a5250513          	addi	a0,a0,-1454 # 80008320 <states.1757+0x58>
    800028d6:	ffffe097          	auipc	ra,0xffffe
    800028da:	c6e080e7          	jalr	-914(ra) # 80000544 <panic>
    if(killed(p))
    800028de:	00000097          	auipc	ra,0x0
    800028e2:	ab6080e7          	jalr	-1354(ra) # 80002394 <killed>
    800028e6:	e921                	bnez	a0,80002936 <usertrap+0xc0>
    p->trapframe->epc += 4;
    800028e8:	6cb8                	ld	a4,88(s1)
    800028ea:	6f1c                	ld	a5,24(a4)
    800028ec:	0791                	addi	a5,a5,4
    800028ee:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028f0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800028f4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028f8:	10079073          	csrw	sstatus,a5
    syscall();
    800028fc:	00000097          	auipc	ra,0x0
    80002900:	2d4080e7          	jalr	724(ra) # 80002bd0 <syscall>
  if(killed(p))
    80002904:	8526                	mv	a0,s1
    80002906:	00000097          	auipc	ra,0x0
    8000290a:	a8e080e7          	jalr	-1394(ra) # 80002394 <killed>
    8000290e:	c911                	beqz	a0,80002922 <usertrap+0xac>
    80002910:	4901                	li	s2,0
    exit(-1);
    80002912:	557d                	li	a0,-1
    80002914:	00000097          	auipc	ra,0x0
    80002918:	90c080e7          	jalr	-1780(ra) # 80002220 <exit>
  if(which_dev == 2)
    8000291c:	4789                	li	a5,2
    8000291e:	04f90f63          	beq	s2,a5,8000297c <usertrap+0x106>
  usertrapret();
    80002922:	00000097          	auipc	ra,0x0
    80002926:	dd6080e7          	jalr	-554(ra) # 800026f8 <usertrapret>
}
    8000292a:	60e2                	ld	ra,24(sp)
    8000292c:	6442                	ld	s0,16(sp)
    8000292e:	64a2                	ld	s1,8(sp)
    80002930:	6902                	ld	s2,0(sp)
    80002932:	6105                	addi	sp,sp,32
    80002934:	8082                	ret
      exit(-1);
    80002936:	557d                	li	a0,-1
    80002938:	00000097          	auipc	ra,0x0
    8000293c:	8e8080e7          	jalr	-1816(ra) # 80002220 <exit>
    80002940:	b765                	j	800028e8 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002942:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002946:	5890                	lw	a2,48(s1)
    80002948:	00006517          	auipc	a0,0x6
    8000294c:	9f850513          	addi	a0,a0,-1544 # 80008340 <states.1757+0x78>
    80002950:	ffffe097          	auipc	ra,0xffffe
    80002954:	c3e080e7          	jalr	-962(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002958:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000295c:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002960:	00006517          	auipc	a0,0x6
    80002964:	a1050513          	addi	a0,a0,-1520 # 80008370 <states.1757+0xa8>
    80002968:	ffffe097          	auipc	ra,0xffffe
    8000296c:	c26080e7          	jalr	-986(ra) # 8000058e <printf>
    setkilled(p);
    80002970:	8526                	mv	a0,s1
    80002972:	00000097          	auipc	ra,0x0
    80002976:	9f6080e7          	jalr	-1546(ra) # 80002368 <setkilled>
    8000297a:	b769                	j	80002904 <usertrap+0x8e>
    yield();
    8000297c:	fffff097          	auipc	ra,0xfffff
    80002980:	734080e7          	jalr	1844(ra) # 800020b0 <yield>
    80002984:	bf79                	j	80002922 <usertrap+0xac>

0000000080002986 <kerneltrap>:
{
    80002986:	7179                	addi	sp,sp,-48
    80002988:	f406                	sd	ra,40(sp)
    8000298a:	f022                	sd	s0,32(sp)
    8000298c:	ec26                	sd	s1,24(sp)
    8000298e:	e84a                	sd	s2,16(sp)
    80002990:	e44e                	sd	s3,8(sp)
    80002992:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002994:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002998:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000299c:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800029a0:	1004f793          	andi	a5,s1,256
    800029a4:	cb85                	beqz	a5,800029d4 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029a6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800029aa:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800029ac:	ef85                	bnez	a5,800029e4 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800029ae:	00000097          	auipc	ra,0x0
    800029b2:	e26080e7          	jalr	-474(ra) # 800027d4 <devintr>
    800029b6:	cd1d                	beqz	a0,800029f4 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029b8:	4789                	li	a5,2
    800029ba:	06f50a63          	beq	a0,a5,80002a2e <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029be:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029c2:	10049073          	csrw	sstatus,s1
}
    800029c6:	70a2                	ld	ra,40(sp)
    800029c8:	7402                	ld	s0,32(sp)
    800029ca:	64e2                	ld	s1,24(sp)
    800029cc:	6942                	ld	s2,16(sp)
    800029ce:	69a2                	ld	s3,8(sp)
    800029d0:	6145                	addi	sp,sp,48
    800029d2:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800029d4:	00006517          	auipc	a0,0x6
    800029d8:	9bc50513          	addi	a0,a0,-1604 # 80008390 <states.1757+0xc8>
    800029dc:	ffffe097          	auipc	ra,0xffffe
    800029e0:	b68080e7          	jalr	-1176(ra) # 80000544 <panic>
    panic("kerneltrap: interrupts enabled");
    800029e4:	00006517          	auipc	a0,0x6
    800029e8:	9d450513          	addi	a0,a0,-1580 # 800083b8 <states.1757+0xf0>
    800029ec:	ffffe097          	auipc	ra,0xffffe
    800029f0:	b58080e7          	jalr	-1192(ra) # 80000544 <panic>
    printf("scause %p\n", scause);
    800029f4:	85ce                	mv	a1,s3
    800029f6:	00006517          	auipc	a0,0x6
    800029fa:	9e250513          	addi	a0,a0,-1566 # 800083d8 <states.1757+0x110>
    800029fe:	ffffe097          	auipc	ra,0xffffe
    80002a02:	b90080e7          	jalr	-1136(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a06:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a0a:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a0e:	00006517          	auipc	a0,0x6
    80002a12:	9da50513          	addi	a0,a0,-1574 # 800083e8 <states.1757+0x120>
    80002a16:	ffffe097          	auipc	ra,0xffffe
    80002a1a:	b78080e7          	jalr	-1160(ra) # 8000058e <printf>
    panic("kerneltrap");
    80002a1e:	00006517          	auipc	a0,0x6
    80002a22:	9e250513          	addi	a0,a0,-1566 # 80008400 <states.1757+0x138>
    80002a26:	ffffe097          	auipc	ra,0xffffe
    80002a2a:	b1e080e7          	jalr	-1250(ra) # 80000544 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a2e:	fffff097          	auipc	ra,0xfffff
    80002a32:	f98080e7          	jalr	-104(ra) # 800019c6 <myproc>
    80002a36:	d541                	beqz	a0,800029be <kerneltrap+0x38>
    80002a38:	fffff097          	auipc	ra,0xfffff
    80002a3c:	f8e080e7          	jalr	-114(ra) # 800019c6 <myproc>
    80002a40:	4d18                	lw	a4,24(a0)
    80002a42:	4791                	li	a5,4
    80002a44:	f6f71de3          	bne	a4,a5,800029be <kerneltrap+0x38>
    yield();
    80002a48:	fffff097          	auipc	ra,0xfffff
    80002a4c:	668080e7          	jalr	1640(ra) # 800020b0 <yield>
    80002a50:	b7bd                	j	800029be <kerneltrap+0x38>

0000000080002a52 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a52:	1101                	addi	sp,sp,-32
    80002a54:	ec06                	sd	ra,24(sp)
    80002a56:	e822                	sd	s0,16(sp)
    80002a58:	e426                	sd	s1,8(sp)
    80002a5a:	1000                	addi	s0,sp,32
    80002a5c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a5e:	fffff097          	auipc	ra,0xfffff
    80002a62:	f68080e7          	jalr	-152(ra) # 800019c6 <myproc>
  switch (n) {
    80002a66:	4795                	li	a5,5
    80002a68:	0497e163          	bltu	a5,s1,80002aaa <argraw+0x58>
    80002a6c:	048a                	slli	s1,s1,0x2
    80002a6e:	00006717          	auipc	a4,0x6
    80002a72:	a7a70713          	addi	a4,a4,-1414 # 800084e8 <states.1757+0x220>
    80002a76:	94ba                	add	s1,s1,a4
    80002a78:	409c                	lw	a5,0(s1)
    80002a7a:	97ba                	add	a5,a5,a4
    80002a7c:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a7e:	6d3c                	ld	a5,88(a0)
    80002a80:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a82:	60e2                	ld	ra,24(sp)
    80002a84:	6442                	ld	s0,16(sp)
    80002a86:	64a2                	ld	s1,8(sp)
    80002a88:	6105                	addi	sp,sp,32
    80002a8a:	8082                	ret
    return p->trapframe->a1;
    80002a8c:	6d3c                	ld	a5,88(a0)
    80002a8e:	7fa8                	ld	a0,120(a5)
    80002a90:	bfcd                	j	80002a82 <argraw+0x30>
    return p->trapframe->a2;
    80002a92:	6d3c                	ld	a5,88(a0)
    80002a94:	63c8                	ld	a0,128(a5)
    80002a96:	b7f5                	j	80002a82 <argraw+0x30>
    return p->trapframe->a3;
    80002a98:	6d3c                	ld	a5,88(a0)
    80002a9a:	67c8                	ld	a0,136(a5)
    80002a9c:	b7dd                	j	80002a82 <argraw+0x30>
    return p->trapframe->a4;
    80002a9e:	6d3c                	ld	a5,88(a0)
    80002aa0:	6bc8                	ld	a0,144(a5)
    80002aa2:	b7c5                	j	80002a82 <argraw+0x30>
    return p->trapframe->a5;
    80002aa4:	6d3c                	ld	a5,88(a0)
    80002aa6:	6fc8                	ld	a0,152(a5)
    80002aa8:	bfe9                	j	80002a82 <argraw+0x30>
  panic("argraw");
    80002aaa:	00006517          	auipc	a0,0x6
    80002aae:	96650513          	addi	a0,a0,-1690 # 80008410 <states.1757+0x148>
    80002ab2:	ffffe097          	auipc	ra,0xffffe
    80002ab6:	a92080e7          	jalr	-1390(ra) # 80000544 <panic>

0000000080002aba <fetchaddr>:
{
    80002aba:	1101                	addi	sp,sp,-32
    80002abc:	ec06                	sd	ra,24(sp)
    80002abe:	e822                	sd	s0,16(sp)
    80002ac0:	e426                	sd	s1,8(sp)
    80002ac2:	e04a                	sd	s2,0(sp)
    80002ac4:	1000                	addi	s0,sp,32
    80002ac6:	84aa                	mv	s1,a0
    80002ac8:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002aca:	fffff097          	auipc	ra,0xfffff
    80002ace:	efc080e7          	jalr	-260(ra) # 800019c6 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002ad2:	653c                	ld	a5,72(a0)
    80002ad4:	02f4f863          	bgeu	s1,a5,80002b04 <fetchaddr+0x4a>
    80002ad8:	00848713          	addi	a4,s1,8
    80002adc:	02e7e663          	bltu	a5,a4,80002b08 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002ae0:	46a1                	li	a3,8
    80002ae2:	8626                	mv	a2,s1
    80002ae4:	85ca                	mv	a1,s2
    80002ae6:	6928                	ld	a0,80(a0)
    80002ae8:	fffff097          	auipc	ra,0xfffff
    80002aec:	c28080e7          	jalr	-984(ra) # 80001710 <copyin>
    80002af0:	00a03533          	snez	a0,a0
    80002af4:	40a00533          	neg	a0,a0
}
    80002af8:	60e2                	ld	ra,24(sp)
    80002afa:	6442                	ld	s0,16(sp)
    80002afc:	64a2                	ld	s1,8(sp)
    80002afe:	6902                	ld	s2,0(sp)
    80002b00:	6105                	addi	sp,sp,32
    80002b02:	8082                	ret
    return -1;
    80002b04:	557d                	li	a0,-1
    80002b06:	bfcd                	j	80002af8 <fetchaddr+0x3e>
    80002b08:	557d                	li	a0,-1
    80002b0a:	b7fd                	j	80002af8 <fetchaddr+0x3e>

0000000080002b0c <fetchstr>:
{
    80002b0c:	7179                	addi	sp,sp,-48
    80002b0e:	f406                	sd	ra,40(sp)
    80002b10:	f022                	sd	s0,32(sp)
    80002b12:	ec26                	sd	s1,24(sp)
    80002b14:	e84a                	sd	s2,16(sp)
    80002b16:	e44e                	sd	s3,8(sp)
    80002b18:	1800                	addi	s0,sp,48
    80002b1a:	892a                	mv	s2,a0
    80002b1c:	84ae                	mv	s1,a1
    80002b1e:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b20:	fffff097          	auipc	ra,0xfffff
    80002b24:	ea6080e7          	jalr	-346(ra) # 800019c6 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002b28:	86ce                	mv	a3,s3
    80002b2a:	864a                	mv	a2,s2
    80002b2c:	85a6                	mv	a1,s1
    80002b2e:	6928                	ld	a0,80(a0)
    80002b30:	fffff097          	auipc	ra,0xfffff
    80002b34:	c6c080e7          	jalr	-916(ra) # 8000179c <copyinstr>
    80002b38:	00054e63          	bltz	a0,80002b54 <fetchstr+0x48>
  return strlen(buf);
    80002b3c:	8526                	mv	a0,s1
    80002b3e:	ffffe097          	auipc	ra,0xffffe
    80002b42:	32c080e7          	jalr	812(ra) # 80000e6a <strlen>
}
    80002b46:	70a2                	ld	ra,40(sp)
    80002b48:	7402                	ld	s0,32(sp)
    80002b4a:	64e2                	ld	s1,24(sp)
    80002b4c:	6942                	ld	s2,16(sp)
    80002b4e:	69a2                	ld	s3,8(sp)
    80002b50:	6145                	addi	sp,sp,48
    80002b52:	8082                	ret
    return -1;
    80002b54:	557d                	li	a0,-1
    80002b56:	bfc5                	j	80002b46 <fetchstr+0x3a>

0000000080002b58 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002b58:	1101                	addi	sp,sp,-32
    80002b5a:	ec06                	sd	ra,24(sp)
    80002b5c:	e822                	sd	s0,16(sp)
    80002b5e:	e426                	sd	s1,8(sp)
    80002b60:	1000                	addi	s0,sp,32
    80002b62:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b64:	00000097          	auipc	ra,0x0
    80002b68:	eee080e7          	jalr	-274(ra) # 80002a52 <argraw>
    80002b6c:	c088                	sw	a0,0(s1)
}
    80002b6e:	60e2                	ld	ra,24(sp)
    80002b70:	6442                	ld	s0,16(sp)
    80002b72:	64a2                	ld	s1,8(sp)
    80002b74:	6105                	addi	sp,sp,32
    80002b76:	8082                	ret

0000000080002b78 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002b78:	1101                	addi	sp,sp,-32
    80002b7a:	ec06                	sd	ra,24(sp)
    80002b7c:	e822                	sd	s0,16(sp)
    80002b7e:	e426                	sd	s1,8(sp)
    80002b80:	1000                	addi	s0,sp,32
    80002b82:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b84:	00000097          	auipc	ra,0x0
    80002b88:	ece080e7          	jalr	-306(ra) # 80002a52 <argraw>
    80002b8c:	e088                	sd	a0,0(s1)
}
    80002b8e:	60e2                	ld	ra,24(sp)
    80002b90:	6442                	ld	s0,16(sp)
    80002b92:	64a2                	ld	s1,8(sp)
    80002b94:	6105                	addi	sp,sp,32
    80002b96:	8082                	ret

0000000080002b98 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002b98:	7179                	addi	sp,sp,-48
    80002b9a:	f406                	sd	ra,40(sp)
    80002b9c:	f022                	sd	s0,32(sp)
    80002b9e:	ec26                	sd	s1,24(sp)
    80002ba0:	e84a                	sd	s2,16(sp)
    80002ba2:	1800                	addi	s0,sp,48
    80002ba4:	84ae                	mv	s1,a1
    80002ba6:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002ba8:	fd840593          	addi	a1,s0,-40
    80002bac:	00000097          	auipc	ra,0x0
    80002bb0:	fcc080e7          	jalr	-52(ra) # 80002b78 <argaddr>
  return fetchstr(addr, buf, max);
    80002bb4:	864a                	mv	a2,s2
    80002bb6:	85a6                	mv	a1,s1
    80002bb8:	fd843503          	ld	a0,-40(s0)
    80002bbc:	00000097          	auipc	ra,0x0
    80002bc0:	f50080e7          	jalr	-176(ra) # 80002b0c <fetchstr>
}
    80002bc4:	70a2                	ld	ra,40(sp)
    80002bc6:	7402                	ld	s0,32(sp)
    80002bc8:	64e2                	ld	s1,24(sp)
    80002bca:	6942                	ld	s2,16(sp)
    80002bcc:	6145                	addi	sp,sp,48
    80002bce:	8082                	ret

0000000080002bd0 <syscall>:
[SYS_check]   sys_check,
};

void
syscall(void)
{
    80002bd0:	7139                	addi	sp,sp,-64
    80002bd2:	fc06                	sd	ra,56(sp)
    80002bd4:	f822                	sd	s0,48(sp)
    80002bd6:	f426                	sd	s1,40(sp)
    80002bd8:	f04a                	sd	s2,32(sp)
    80002bda:	ec4e                	sd	s3,24(sp)
    80002bdc:	e852                	sd	s4,16(sp)
    80002bde:	0080                	addi	s0,sp,64
  int num;
  struct proc *p = myproc();
    80002be0:	fffff097          	auipc	ra,0xfffff
    80002be4:	de6080e7          	jalr	-538(ra) # 800019c6 <myproc>
    80002be8:	84aa                	mv	s1,a0

  // any time we are here, we are about to make a system call.
  // we can intercept args, etc.
  num = p->trapframe->a7;
    80002bea:	6d3c                	ld	a5,88(a0)
    80002bec:	0a87a903          	lw	s2,168(a5)
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002bf0:	fff9071b          	addiw	a4,s2,-1
    80002bf4:	47d9                	li	a5,22
    80002bf6:	08e7ed63          	bltu	a5,a4,80002c90 <syscall+0xc0>
    80002bfa:	00391713          	slli	a4,s2,0x3
    80002bfe:	00006797          	auipc	a5,0x6
    80002c02:	90278793          	addi	a5,a5,-1790 # 80008500 <syscalls>
    80002c06:	97ba                	add	a5,a5,a4
    80002c08:	0007b983          	ld	s3,0(a5)
    80002c0c:	08098263          	beqz	s3,80002c90 <syscall+0xc0>
    // steal the file away, if there is one, before we return a0.
    int fd = -1;
    struct file *f;

    // if it's any of these file related operations
    if (num == SYS_read || num == SYS_fstat || num == SYS_dup 
    80002c10:	47d5                	li	a5,21
    80002c12:	0327ea63          	bltu	a5,s2,80002c46 <syscall+0x76>
    80002c16:	002187b7          	lui	a5,0x218
    80002c1a:	52078793          	addi	a5,a5,1312 # 218520 <_entry-0x7fde7ae0>
    80002c1e:	0127d7b3          	srl	a5,a5,s2
    80002c22:	8b85                	andi	a5,a5,1
    80002c24:	c38d                	beqz	a5,80002c46 <syscall+0x76>
  argint(n, &fd);
    80002c26:	fcc40593          	addi	a1,s0,-52
    80002c2a:	4501                	li	a0,0
    80002c2c:	00000097          	auipc	ra,0x0
    80002c30:	f2c080e7          	jalr	-212(ra) # 80002b58 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80002c34:	fcc42703          	lw	a4,-52(s0)
    80002c38:	47bd                	li	a5,15
    80002c3a:	00e7e663          	bltu	a5,a4,80002c46 <syscall+0x76>
    80002c3e:	fffff097          	auipc	ra,0xfffff
    80002c42:	d88080e7          	jalr	-632(ra) # 800019c6 <myproc>
      // we are trying to do SOMETHING with this file.
      argfd(0, &fd, &f);
    }
    
    // let the system call go through.
    p->trapframe->a0 = syscalls[num]();
    80002c46:	0584ba03          	ld	s4,88(s1)
    80002c4a:	9982                	jalr	s3
    80002c4c:	06aa3823          	sd	a0,112(s4)
    if (num == 22) {
    80002c50:	47d9                	li	a5,22
    80002c52:	04f91e63          	bne	s2,a5,80002cae <syscall+0xde>
      // it was an audit call. Retrieve the number and parse the bits into an array.
      uint audit_num = (uint) p->trapframe->a0;
    80002c56:	6cbc                	ld	a5,88(s1)
    80002c58:	5bb8                	lw	a4,112(a5)
      for (int i = 0; i < NUM_SYS_CALLS; i++) {
    80002c5a:	00006797          	auipc	a5,0x6
    80002c5e:	dce78793          	addi	a5,a5,-562 # 80008a28 <whitelisted>
    80002c62:	00006617          	auipc	a2,0x6
    80002c66:	ddb60613          	addi	a2,a2,-549 # 80008a3d <whitelisted+0x15>
    80002c6a:	00179513          	slli	a0,a5,0x1
        whitelisted[i] = 0; // reset the array position first.
        // just and it with 32-bit 1
        if (audit_num & 0b00000000000000000000000000000001) { // bit was toggled, whitelist
          whitelisted[NUM_SYS_CALLS - i] = 1;
    80002c6e:	4585                	li	a1,1
    80002c70:	a031                	j	80002c7c <syscall+0xac>
        }
        // shift it right by 1
        audit_num = audit_num >> 1;
    80002c72:	0017571b          	srliw	a4,a4,0x1
      for (int i = 0; i < NUM_SYS_CALLS; i++) {
    80002c76:	0785                	addi	a5,a5,1
    80002c78:	02f60b63          	beq	a2,a5,80002cae <syscall+0xde>
        whitelisted[i] = 0; // reset the array position first.
    80002c7c:	00078023          	sb	zero,0(a5)
        if (audit_num & 0b00000000000000000000000000000001) { // bit was toggled, whitelist
    80002c80:	00177693          	andi	a3,a4,1
    80002c84:	d6fd                	beqz	a3,80002c72 <syscall+0xa2>
          whitelisted[NUM_SYS_CALLS - i] = 1;
    80002c86:	40f506b3          	sub	a3,a0,a5
    80002c8a:	00b68aa3          	sb	a1,21(a3)
    80002c8e:	b7d5                	j	80002c72 <syscall+0xa2>
      // here just so we don't throw unused variable errors
      int bruh = cur.process_pid;
      bruh++;
    }
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c90:	86ca                	mv	a3,s2
    80002c92:	15848613          	addi	a2,s1,344
    80002c96:	588c                	lw	a1,48(s1)
    80002c98:	00005517          	auipc	a0,0x5
    80002c9c:	78050513          	addi	a0,a0,1920 # 80008418 <states.1757+0x150>
    80002ca0:	ffffe097          	auipc	ra,0xffffe
    80002ca4:	8ee080e7          	jalr	-1810(ra) # 8000058e <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002ca8:	6cbc                	ld	a5,88(s1)
    80002caa:	577d                	li	a4,-1
    80002cac:	fbb8                	sd	a4,112(a5)
  }
}
    80002cae:	70e2                	ld	ra,56(sp)
    80002cb0:	7442                	ld	s0,48(sp)
    80002cb2:	74a2                	ld	s1,40(sp)
    80002cb4:	7902                	ld	s2,32(sp)
    80002cb6:	69e2                	ld	s3,24(sp)
    80002cb8:	6a42                	ld	s4,16(sp)
    80002cba:	6121                	addi	sp,sp,64
    80002cbc:	8082                	ret

0000000080002cbe <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002cbe:	1101                	addi	sp,sp,-32
    80002cc0:	ec06                	sd	ra,24(sp)
    80002cc2:	e822                	sd	s0,16(sp)
    80002cc4:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002cc6:	fec40593          	addi	a1,s0,-20
    80002cca:	4501                	li	a0,0
    80002ccc:	00000097          	auipc	ra,0x0
    80002cd0:	e8c080e7          	jalr	-372(ra) # 80002b58 <argint>
  exit(n);
    80002cd4:	fec42503          	lw	a0,-20(s0)
    80002cd8:	fffff097          	auipc	ra,0xfffff
    80002cdc:	548080e7          	jalr	1352(ra) # 80002220 <exit>
  return 0;  // not reached
}
    80002ce0:	4501                	li	a0,0
    80002ce2:	60e2                	ld	ra,24(sp)
    80002ce4:	6442                	ld	s0,16(sp)
    80002ce6:	6105                	addi	sp,sp,32
    80002ce8:	8082                	ret

0000000080002cea <sys_getpid>:

uint64
sys_getpid(void)
{
    80002cea:	1141                	addi	sp,sp,-16
    80002cec:	e406                	sd	ra,8(sp)
    80002cee:	e022                	sd	s0,0(sp)
    80002cf0:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002cf2:	fffff097          	auipc	ra,0xfffff
    80002cf6:	cd4080e7          	jalr	-812(ra) # 800019c6 <myproc>
}
    80002cfa:	5908                	lw	a0,48(a0)
    80002cfc:	60a2                	ld	ra,8(sp)
    80002cfe:	6402                	ld	s0,0(sp)
    80002d00:	0141                	addi	sp,sp,16
    80002d02:	8082                	ret

0000000080002d04 <sys_fork>:

uint64
sys_fork(void)
{
    80002d04:	1141                	addi	sp,sp,-16
    80002d06:	e406                	sd	ra,8(sp)
    80002d08:	e022                	sd	s0,0(sp)
    80002d0a:	0800                	addi	s0,sp,16
  return fork();
    80002d0c:	fffff097          	auipc	ra,0xfffff
    80002d10:	070080e7          	jalr	112(ra) # 80001d7c <fork>
}
    80002d14:	60a2                	ld	ra,8(sp)
    80002d16:	6402                	ld	s0,0(sp)
    80002d18:	0141                	addi	sp,sp,16
    80002d1a:	8082                	ret

0000000080002d1c <sys_wait>:

uint64
sys_wait(void)
{
    80002d1c:	1101                	addi	sp,sp,-32
    80002d1e:	ec06                	sd	ra,24(sp)
    80002d20:	e822                	sd	s0,16(sp)
    80002d22:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002d24:	fe840593          	addi	a1,s0,-24
    80002d28:	4501                	li	a0,0
    80002d2a:	00000097          	auipc	ra,0x0
    80002d2e:	e4e080e7          	jalr	-434(ra) # 80002b78 <argaddr>
  return wait(p);
    80002d32:	fe843503          	ld	a0,-24(s0)
    80002d36:	fffff097          	auipc	ra,0xfffff
    80002d3a:	690080e7          	jalr	1680(ra) # 800023c6 <wait>
}
    80002d3e:	60e2                	ld	ra,24(sp)
    80002d40:	6442                	ld	s0,16(sp)
    80002d42:	6105                	addi	sp,sp,32
    80002d44:	8082                	ret

0000000080002d46 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d46:	7179                	addi	sp,sp,-48
    80002d48:	f406                	sd	ra,40(sp)
    80002d4a:	f022                	sd	s0,32(sp)
    80002d4c:	ec26                	sd	s1,24(sp)
    80002d4e:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002d50:	fdc40593          	addi	a1,s0,-36
    80002d54:	4501                	li	a0,0
    80002d56:	00000097          	auipc	ra,0x0
    80002d5a:	e02080e7          	jalr	-510(ra) # 80002b58 <argint>
  addr = myproc()->sz;
    80002d5e:	fffff097          	auipc	ra,0xfffff
    80002d62:	c68080e7          	jalr	-920(ra) # 800019c6 <myproc>
    80002d66:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002d68:	fdc42503          	lw	a0,-36(s0)
    80002d6c:	fffff097          	auipc	ra,0xfffff
    80002d70:	fb4080e7          	jalr	-76(ra) # 80001d20 <growproc>
    80002d74:	00054863          	bltz	a0,80002d84 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002d78:	8526                	mv	a0,s1
    80002d7a:	70a2                	ld	ra,40(sp)
    80002d7c:	7402                	ld	s0,32(sp)
    80002d7e:	64e2                	ld	s1,24(sp)
    80002d80:	6145                	addi	sp,sp,48
    80002d82:	8082                	ret
    return -1;
    80002d84:	54fd                	li	s1,-1
    80002d86:	bfcd                	j	80002d78 <sys_sbrk+0x32>

0000000080002d88 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d88:	7139                	addi	sp,sp,-64
    80002d8a:	fc06                	sd	ra,56(sp)
    80002d8c:	f822                	sd	s0,48(sp)
    80002d8e:	f426                	sd	s1,40(sp)
    80002d90:	f04a                	sd	s2,32(sp)
    80002d92:	ec4e                	sd	s3,24(sp)
    80002d94:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002d96:	fcc40593          	addi	a1,s0,-52
    80002d9a:	4501                	li	a0,0
    80002d9c:	00000097          	auipc	ra,0x0
    80002da0:	dbc080e7          	jalr	-580(ra) # 80002b58 <argint>
  acquire(&tickslock);
    80002da4:	00014517          	auipc	a0,0x14
    80002da8:	05c50513          	addi	a0,a0,92 # 80016e00 <tickslock>
    80002dac:	ffffe097          	auipc	ra,0xffffe
    80002db0:	e3e080e7          	jalr	-450(ra) # 80000bea <acquire>
  ticks0 = ticks;
    80002db4:	00006917          	auipc	s2,0x6
    80002db8:	da492903          	lw	s2,-604(s2) # 80008b58 <ticks>
  while(ticks - ticks0 < n){
    80002dbc:	fcc42783          	lw	a5,-52(s0)
    80002dc0:	cf9d                	beqz	a5,80002dfe <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002dc2:	00014997          	auipc	s3,0x14
    80002dc6:	03e98993          	addi	s3,s3,62 # 80016e00 <tickslock>
    80002dca:	00006497          	auipc	s1,0x6
    80002dce:	d8e48493          	addi	s1,s1,-626 # 80008b58 <ticks>
    if(killed(myproc())){
    80002dd2:	fffff097          	auipc	ra,0xfffff
    80002dd6:	bf4080e7          	jalr	-1036(ra) # 800019c6 <myproc>
    80002dda:	fffff097          	auipc	ra,0xfffff
    80002dde:	5ba080e7          	jalr	1466(ra) # 80002394 <killed>
    80002de2:	ed15                	bnez	a0,80002e1e <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002de4:	85ce                	mv	a1,s3
    80002de6:	8526                	mv	a0,s1
    80002de8:	fffff097          	auipc	ra,0xfffff
    80002dec:	304080e7          	jalr	772(ra) # 800020ec <sleep>
  while(ticks - ticks0 < n){
    80002df0:	409c                	lw	a5,0(s1)
    80002df2:	412787bb          	subw	a5,a5,s2
    80002df6:	fcc42703          	lw	a4,-52(s0)
    80002dfa:	fce7ece3          	bltu	a5,a4,80002dd2 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002dfe:	00014517          	auipc	a0,0x14
    80002e02:	00250513          	addi	a0,a0,2 # 80016e00 <tickslock>
    80002e06:	ffffe097          	auipc	ra,0xffffe
    80002e0a:	e98080e7          	jalr	-360(ra) # 80000c9e <release>
  return 0;
    80002e0e:	4501                	li	a0,0
}
    80002e10:	70e2                	ld	ra,56(sp)
    80002e12:	7442                	ld	s0,48(sp)
    80002e14:	74a2                	ld	s1,40(sp)
    80002e16:	7902                	ld	s2,32(sp)
    80002e18:	69e2                	ld	s3,24(sp)
    80002e1a:	6121                	addi	sp,sp,64
    80002e1c:	8082                	ret
      release(&tickslock);
    80002e1e:	00014517          	auipc	a0,0x14
    80002e22:	fe250513          	addi	a0,a0,-30 # 80016e00 <tickslock>
    80002e26:	ffffe097          	auipc	ra,0xffffe
    80002e2a:	e78080e7          	jalr	-392(ra) # 80000c9e <release>
      return -1;
    80002e2e:	557d                	li	a0,-1
    80002e30:	b7c5                	j	80002e10 <sys_sleep+0x88>

0000000080002e32 <sys_kill>:

uint64
sys_kill(void)
{
    80002e32:	1101                	addi	sp,sp,-32
    80002e34:	ec06                	sd	ra,24(sp)
    80002e36:	e822                	sd	s0,16(sp)
    80002e38:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002e3a:	fec40593          	addi	a1,s0,-20
    80002e3e:	4501                	li	a0,0
    80002e40:	00000097          	auipc	ra,0x0
    80002e44:	d18080e7          	jalr	-744(ra) # 80002b58 <argint>
  return kill(pid);
    80002e48:	fec42503          	lw	a0,-20(s0)
    80002e4c:	fffff097          	auipc	ra,0xfffff
    80002e50:	4aa080e7          	jalr	1194(ra) # 800022f6 <kill>
}
    80002e54:	60e2                	ld	ra,24(sp)
    80002e56:	6442                	ld	s0,16(sp)
    80002e58:	6105                	addi	sp,sp,32
    80002e5a:	8082                	ret

0000000080002e5c <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e5c:	1101                	addi	sp,sp,-32
    80002e5e:	ec06                	sd	ra,24(sp)
    80002e60:	e822                	sd	s0,16(sp)
    80002e62:	e426                	sd	s1,8(sp)
    80002e64:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e66:	00014517          	auipc	a0,0x14
    80002e6a:	f9a50513          	addi	a0,a0,-102 # 80016e00 <tickslock>
    80002e6e:	ffffe097          	auipc	ra,0xffffe
    80002e72:	d7c080e7          	jalr	-644(ra) # 80000bea <acquire>
  xticks = ticks;
    80002e76:	00006497          	auipc	s1,0x6
    80002e7a:	ce24a483          	lw	s1,-798(s1) # 80008b58 <ticks>
  release(&tickslock);
    80002e7e:	00014517          	auipc	a0,0x14
    80002e82:	f8250513          	addi	a0,a0,-126 # 80016e00 <tickslock>
    80002e86:	ffffe097          	auipc	ra,0xffffe
    80002e8a:	e18080e7          	jalr	-488(ra) # 80000c9e <release>
  return xticks;
}
    80002e8e:	02049513          	slli	a0,s1,0x20
    80002e92:	9101                	srli	a0,a0,0x20
    80002e94:	60e2                	ld	ra,24(sp)
    80002e96:	6442                	ld	s0,16(sp)
    80002e98:	64a2                	ld	s1,8(sp)
    80002e9a:	6105                	addi	sp,sp,32
    80002e9c:	8082                	ret

0000000080002e9e <sys_audit>:

uint64
sys_audit(void)
{
    80002e9e:	1101                	addi	sp,sp,-32
    80002ea0:	ec06                	sd	ra,24(sp)
    80002ea2:	e822                	sd	s0,16(sp)
    80002ea4:	1000                	addi	s0,sp,32
  // fetch the integer
  int n;
  argint(0, &n); 
    80002ea6:	fec40593          	addi	a1,s0,-20
    80002eaa:	4501                	li	a0,0
    80002eac:	00000097          	auipc	ra,0x0
    80002eb0:	cac080e7          	jalr	-852(ra) # 80002b58 <argint>
  return audit(n);
    80002eb4:	fec42503          	lw	a0,-20(s0)
    80002eb8:	fffff097          	auipc	ra,0xfffff
    80002ebc:	000080e7          	jalr	ra # 80001eb8 <audit>
}
    80002ec0:	60e2                	ld	ra,24(sp)
    80002ec2:	6442                	ld	s0,16(sp)
    80002ec4:	6105                	addi	sp,sp,32
    80002ec6:	8082                	ret

0000000080002ec8 <sys_check>:

uint64
sys_check(void)
{
    80002ec8:	1101                	addi	sp,sp,-32
    80002eca:	ec06                	sd	ra,24(sp)
    80002ecc:	e822                	sd	s0,16(sp)
    80002ece:	1000                	addi	s0,sp,32
    uint64 list;
    argaddr(0, &list);
    80002ed0:	fe840593          	addi	a1,s0,-24
    80002ed4:	4501                	li	a0,0
    80002ed6:	00000097          	auipc	ra,0x0
    80002eda:	ca2080e7          	jalr	-862(ra) # 80002b78 <argaddr>
    return check((void *) list);
    80002ede:	fe843503          	ld	a0,-24(s0)
    80002ee2:	fffff097          	auipc	ra,0xfffff
    80002ee6:	fe6080e7          	jalr	-26(ra) # 80001ec8 <check>
}
    80002eea:	60e2                	ld	ra,24(sp)
    80002eec:	6442                	ld	s0,16(sp)
    80002eee:	6105                	addi	sp,sp,32
    80002ef0:	8082                	ret

0000000080002ef2 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002ef2:	7179                	addi	sp,sp,-48
    80002ef4:	f406                	sd	ra,40(sp)
    80002ef6:	f022                	sd	s0,32(sp)
    80002ef8:	ec26                	sd	s1,24(sp)
    80002efa:	e84a                	sd	s2,16(sp)
    80002efc:	e44e                	sd	s3,8(sp)
    80002efe:	e052                	sd	s4,0(sp)
    80002f00:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002f02:	00005597          	auipc	a1,0x5
    80002f06:	6be58593          	addi	a1,a1,1726 # 800085c0 <syscalls+0xc0>
    80002f0a:	00020517          	auipc	a0,0x20
    80002f0e:	f0e50513          	addi	a0,a0,-242 # 80022e18 <bcache>
    80002f12:	ffffe097          	auipc	ra,0xffffe
    80002f16:	c48080e7          	jalr	-952(ra) # 80000b5a <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f1a:	00028797          	auipc	a5,0x28
    80002f1e:	efe78793          	addi	a5,a5,-258 # 8002ae18 <bcache+0x8000>
    80002f22:	00028717          	auipc	a4,0x28
    80002f26:	15e70713          	addi	a4,a4,350 # 8002b080 <bcache+0x8268>
    80002f2a:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f2e:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f32:	00020497          	auipc	s1,0x20
    80002f36:	efe48493          	addi	s1,s1,-258 # 80022e30 <bcache+0x18>
    b->next = bcache.head.next;
    80002f3a:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f3c:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f3e:	00005a17          	auipc	s4,0x5
    80002f42:	68aa0a13          	addi	s4,s4,1674 # 800085c8 <syscalls+0xc8>
    b->next = bcache.head.next;
    80002f46:	2b893783          	ld	a5,696(s2)
    80002f4a:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f4c:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f50:	85d2                	mv	a1,s4
    80002f52:	01048513          	addi	a0,s1,16
    80002f56:	00001097          	auipc	ra,0x1
    80002f5a:	4c4080e7          	jalr	1220(ra) # 8000441a <initsleeplock>
    bcache.head.next->prev = b;
    80002f5e:	2b893783          	ld	a5,696(s2)
    80002f62:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f64:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f68:	45848493          	addi	s1,s1,1112
    80002f6c:	fd349de3          	bne	s1,s3,80002f46 <binit+0x54>
  }
}
    80002f70:	70a2                	ld	ra,40(sp)
    80002f72:	7402                	ld	s0,32(sp)
    80002f74:	64e2                	ld	s1,24(sp)
    80002f76:	6942                	ld	s2,16(sp)
    80002f78:	69a2                	ld	s3,8(sp)
    80002f7a:	6a02                	ld	s4,0(sp)
    80002f7c:	6145                	addi	sp,sp,48
    80002f7e:	8082                	ret

0000000080002f80 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f80:	7179                	addi	sp,sp,-48
    80002f82:	f406                	sd	ra,40(sp)
    80002f84:	f022                	sd	s0,32(sp)
    80002f86:	ec26                	sd	s1,24(sp)
    80002f88:	e84a                	sd	s2,16(sp)
    80002f8a:	e44e                	sd	s3,8(sp)
    80002f8c:	1800                	addi	s0,sp,48
    80002f8e:	89aa                	mv	s3,a0
    80002f90:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002f92:	00020517          	auipc	a0,0x20
    80002f96:	e8650513          	addi	a0,a0,-378 # 80022e18 <bcache>
    80002f9a:	ffffe097          	auipc	ra,0xffffe
    80002f9e:	c50080e7          	jalr	-944(ra) # 80000bea <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002fa2:	00028497          	auipc	s1,0x28
    80002fa6:	12e4b483          	ld	s1,302(s1) # 8002b0d0 <bcache+0x82b8>
    80002faa:	00028797          	auipc	a5,0x28
    80002fae:	0d678793          	addi	a5,a5,214 # 8002b080 <bcache+0x8268>
    80002fb2:	02f48f63          	beq	s1,a5,80002ff0 <bread+0x70>
    80002fb6:	873e                	mv	a4,a5
    80002fb8:	a021                	j	80002fc0 <bread+0x40>
    80002fba:	68a4                	ld	s1,80(s1)
    80002fbc:	02e48a63          	beq	s1,a4,80002ff0 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002fc0:	449c                	lw	a5,8(s1)
    80002fc2:	ff379ce3          	bne	a5,s3,80002fba <bread+0x3a>
    80002fc6:	44dc                	lw	a5,12(s1)
    80002fc8:	ff2799e3          	bne	a5,s2,80002fba <bread+0x3a>
      b->refcnt++;
    80002fcc:	40bc                	lw	a5,64(s1)
    80002fce:	2785                	addiw	a5,a5,1
    80002fd0:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fd2:	00020517          	auipc	a0,0x20
    80002fd6:	e4650513          	addi	a0,a0,-442 # 80022e18 <bcache>
    80002fda:	ffffe097          	auipc	ra,0xffffe
    80002fde:	cc4080e7          	jalr	-828(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    80002fe2:	01048513          	addi	a0,s1,16
    80002fe6:	00001097          	auipc	ra,0x1
    80002fea:	46e080e7          	jalr	1134(ra) # 80004454 <acquiresleep>
      return b;
    80002fee:	a8b9                	j	8000304c <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002ff0:	00028497          	auipc	s1,0x28
    80002ff4:	0d84b483          	ld	s1,216(s1) # 8002b0c8 <bcache+0x82b0>
    80002ff8:	00028797          	auipc	a5,0x28
    80002ffc:	08878793          	addi	a5,a5,136 # 8002b080 <bcache+0x8268>
    80003000:	00f48863          	beq	s1,a5,80003010 <bread+0x90>
    80003004:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003006:	40bc                	lw	a5,64(s1)
    80003008:	cf81                	beqz	a5,80003020 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000300a:	64a4                	ld	s1,72(s1)
    8000300c:	fee49de3          	bne	s1,a4,80003006 <bread+0x86>
  panic("bget: no buffers");
    80003010:	00005517          	auipc	a0,0x5
    80003014:	5c050513          	addi	a0,a0,1472 # 800085d0 <syscalls+0xd0>
    80003018:	ffffd097          	auipc	ra,0xffffd
    8000301c:	52c080e7          	jalr	1324(ra) # 80000544 <panic>
      b->dev = dev;
    80003020:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003024:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003028:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000302c:	4785                	li	a5,1
    8000302e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003030:	00020517          	auipc	a0,0x20
    80003034:	de850513          	addi	a0,a0,-536 # 80022e18 <bcache>
    80003038:	ffffe097          	auipc	ra,0xffffe
    8000303c:	c66080e7          	jalr	-922(ra) # 80000c9e <release>
      acquiresleep(&b->lock);
    80003040:	01048513          	addi	a0,s1,16
    80003044:	00001097          	auipc	ra,0x1
    80003048:	410080e7          	jalr	1040(ra) # 80004454 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000304c:	409c                	lw	a5,0(s1)
    8000304e:	cb89                	beqz	a5,80003060 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003050:	8526                	mv	a0,s1
    80003052:	70a2                	ld	ra,40(sp)
    80003054:	7402                	ld	s0,32(sp)
    80003056:	64e2                	ld	s1,24(sp)
    80003058:	6942                	ld	s2,16(sp)
    8000305a:	69a2                	ld	s3,8(sp)
    8000305c:	6145                	addi	sp,sp,48
    8000305e:	8082                	ret
    virtio_disk_rw(b, 0);
    80003060:	4581                	li	a1,0
    80003062:	8526                	mv	a0,s1
    80003064:	00003097          	auipc	ra,0x3
    80003068:	fc4080e7          	jalr	-60(ra) # 80006028 <virtio_disk_rw>
    b->valid = 1;
    8000306c:	4785                	li	a5,1
    8000306e:	c09c                	sw	a5,0(s1)
  return b;
    80003070:	b7c5                	j	80003050 <bread+0xd0>

0000000080003072 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003072:	1101                	addi	sp,sp,-32
    80003074:	ec06                	sd	ra,24(sp)
    80003076:	e822                	sd	s0,16(sp)
    80003078:	e426                	sd	s1,8(sp)
    8000307a:	1000                	addi	s0,sp,32
    8000307c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000307e:	0541                	addi	a0,a0,16
    80003080:	00001097          	auipc	ra,0x1
    80003084:	46e080e7          	jalr	1134(ra) # 800044ee <holdingsleep>
    80003088:	cd01                	beqz	a0,800030a0 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000308a:	4585                	li	a1,1
    8000308c:	8526                	mv	a0,s1
    8000308e:	00003097          	auipc	ra,0x3
    80003092:	f9a080e7          	jalr	-102(ra) # 80006028 <virtio_disk_rw>
}
    80003096:	60e2                	ld	ra,24(sp)
    80003098:	6442                	ld	s0,16(sp)
    8000309a:	64a2                	ld	s1,8(sp)
    8000309c:	6105                	addi	sp,sp,32
    8000309e:	8082                	ret
    panic("bwrite");
    800030a0:	00005517          	auipc	a0,0x5
    800030a4:	54850513          	addi	a0,a0,1352 # 800085e8 <syscalls+0xe8>
    800030a8:	ffffd097          	auipc	ra,0xffffd
    800030ac:	49c080e7          	jalr	1180(ra) # 80000544 <panic>

00000000800030b0 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800030b0:	1101                	addi	sp,sp,-32
    800030b2:	ec06                	sd	ra,24(sp)
    800030b4:	e822                	sd	s0,16(sp)
    800030b6:	e426                	sd	s1,8(sp)
    800030b8:	e04a                	sd	s2,0(sp)
    800030ba:	1000                	addi	s0,sp,32
    800030bc:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030be:	01050913          	addi	s2,a0,16
    800030c2:	854a                	mv	a0,s2
    800030c4:	00001097          	auipc	ra,0x1
    800030c8:	42a080e7          	jalr	1066(ra) # 800044ee <holdingsleep>
    800030cc:	c92d                	beqz	a0,8000313e <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800030ce:	854a                	mv	a0,s2
    800030d0:	00001097          	auipc	ra,0x1
    800030d4:	3da080e7          	jalr	986(ra) # 800044aa <releasesleep>

  acquire(&bcache.lock);
    800030d8:	00020517          	auipc	a0,0x20
    800030dc:	d4050513          	addi	a0,a0,-704 # 80022e18 <bcache>
    800030e0:	ffffe097          	auipc	ra,0xffffe
    800030e4:	b0a080e7          	jalr	-1270(ra) # 80000bea <acquire>
  b->refcnt--;
    800030e8:	40bc                	lw	a5,64(s1)
    800030ea:	37fd                	addiw	a5,a5,-1
    800030ec:	0007871b          	sext.w	a4,a5
    800030f0:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800030f2:	eb05                	bnez	a4,80003122 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800030f4:	68bc                	ld	a5,80(s1)
    800030f6:	64b8                	ld	a4,72(s1)
    800030f8:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800030fa:	64bc                	ld	a5,72(s1)
    800030fc:	68b8                	ld	a4,80(s1)
    800030fe:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003100:	00028797          	auipc	a5,0x28
    80003104:	d1878793          	addi	a5,a5,-744 # 8002ae18 <bcache+0x8000>
    80003108:	2b87b703          	ld	a4,696(a5)
    8000310c:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000310e:	00028717          	auipc	a4,0x28
    80003112:	f7270713          	addi	a4,a4,-142 # 8002b080 <bcache+0x8268>
    80003116:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003118:	2b87b703          	ld	a4,696(a5)
    8000311c:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000311e:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003122:	00020517          	auipc	a0,0x20
    80003126:	cf650513          	addi	a0,a0,-778 # 80022e18 <bcache>
    8000312a:	ffffe097          	auipc	ra,0xffffe
    8000312e:	b74080e7          	jalr	-1164(ra) # 80000c9e <release>
}
    80003132:	60e2                	ld	ra,24(sp)
    80003134:	6442                	ld	s0,16(sp)
    80003136:	64a2                	ld	s1,8(sp)
    80003138:	6902                	ld	s2,0(sp)
    8000313a:	6105                	addi	sp,sp,32
    8000313c:	8082                	ret
    panic("brelse");
    8000313e:	00005517          	auipc	a0,0x5
    80003142:	4b250513          	addi	a0,a0,1202 # 800085f0 <syscalls+0xf0>
    80003146:	ffffd097          	auipc	ra,0xffffd
    8000314a:	3fe080e7          	jalr	1022(ra) # 80000544 <panic>

000000008000314e <bpin>:

void
bpin(struct buf *b) {
    8000314e:	1101                	addi	sp,sp,-32
    80003150:	ec06                	sd	ra,24(sp)
    80003152:	e822                	sd	s0,16(sp)
    80003154:	e426                	sd	s1,8(sp)
    80003156:	1000                	addi	s0,sp,32
    80003158:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000315a:	00020517          	auipc	a0,0x20
    8000315e:	cbe50513          	addi	a0,a0,-834 # 80022e18 <bcache>
    80003162:	ffffe097          	auipc	ra,0xffffe
    80003166:	a88080e7          	jalr	-1400(ra) # 80000bea <acquire>
  b->refcnt++;
    8000316a:	40bc                	lw	a5,64(s1)
    8000316c:	2785                	addiw	a5,a5,1
    8000316e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003170:	00020517          	auipc	a0,0x20
    80003174:	ca850513          	addi	a0,a0,-856 # 80022e18 <bcache>
    80003178:	ffffe097          	auipc	ra,0xffffe
    8000317c:	b26080e7          	jalr	-1242(ra) # 80000c9e <release>
}
    80003180:	60e2                	ld	ra,24(sp)
    80003182:	6442                	ld	s0,16(sp)
    80003184:	64a2                	ld	s1,8(sp)
    80003186:	6105                	addi	sp,sp,32
    80003188:	8082                	ret

000000008000318a <bunpin>:

void
bunpin(struct buf *b) {
    8000318a:	1101                	addi	sp,sp,-32
    8000318c:	ec06                	sd	ra,24(sp)
    8000318e:	e822                	sd	s0,16(sp)
    80003190:	e426                	sd	s1,8(sp)
    80003192:	1000                	addi	s0,sp,32
    80003194:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003196:	00020517          	auipc	a0,0x20
    8000319a:	c8250513          	addi	a0,a0,-894 # 80022e18 <bcache>
    8000319e:	ffffe097          	auipc	ra,0xffffe
    800031a2:	a4c080e7          	jalr	-1460(ra) # 80000bea <acquire>
  b->refcnt--;
    800031a6:	40bc                	lw	a5,64(s1)
    800031a8:	37fd                	addiw	a5,a5,-1
    800031aa:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031ac:	00020517          	auipc	a0,0x20
    800031b0:	c6c50513          	addi	a0,a0,-916 # 80022e18 <bcache>
    800031b4:	ffffe097          	auipc	ra,0xffffe
    800031b8:	aea080e7          	jalr	-1302(ra) # 80000c9e <release>
}
    800031bc:	60e2                	ld	ra,24(sp)
    800031be:	6442                	ld	s0,16(sp)
    800031c0:	64a2                	ld	s1,8(sp)
    800031c2:	6105                	addi	sp,sp,32
    800031c4:	8082                	ret

00000000800031c6 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800031c6:	1101                	addi	sp,sp,-32
    800031c8:	ec06                	sd	ra,24(sp)
    800031ca:	e822                	sd	s0,16(sp)
    800031cc:	e426                	sd	s1,8(sp)
    800031ce:	e04a                	sd	s2,0(sp)
    800031d0:	1000                	addi	s0,sp,32
    800031d2:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800031d4:	00d5d59b          	srliw	a1,a1,0xd
    800031d8:	00028797          	auipc	a5,0x28
    800031dc:	31c7a783          	lw	a5,796(a5) # 8002b4f4 <sb+0x1c>
    800031e0:	9dbd                	addw	a1,a1,a5
    800031e2:	00000097          	auipc	ra,0x0
    800031e6:	d9e080e7          	jalr	-610(ra) # 80002f80 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800031ea:	0074f713          	andi	a4,s1,7
    800031ee:	4785                	li	a5,1
    800031f0:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800031f4:	14ce                	slli	s1,s1,0x33
    800031f6:	90d9                	srli	s1,s1,0x36
    800031f8:	00950733          	add	a4,a0,s1
    800031fc:	05874703          	lbu	a4,88(a4)
    80003200:	00e7f6b3          	and	a3,a5,a4
    80003204:	c69d                	beqz	a3,80003232 <bfree+0x6c>
    80003206:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003208:	94aa                	add	s1,s1,a0
    8000320a:	fff7c793          	not	a5,a5
    8000320e:	8ff9                	and	a5,a5,a4
    80003210:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003214:	00001097          	auipc	ra,0x1
    80003218:	120080e7          	jalr	288(ra) # 80004334 <log_write>
  brelse(bp);
    8000321c:	854a                	mv	a0,s2
    8000321e:	00000097          	auipc	ra,0x0
    80003222:	e92080e7          	jalr	-366(ra) # 800030b0 <brelse>
}
    80003226:	60e2                	ld	ra,24(sp)
    80003228:	6442                	ld	s0,16(sp)
    8000322a:	64a2                	ld	s1,8(sp)
    8000322c:	6902                	ld	s2,0(sp)
    8000322e:	6105                	addi	sp,sp,32
    80003230:	8082                	ret
    panic("freeing free block");
    80003232:	00005517          	auipc	a0,0x5
    80003236:	3c650513          	addi	a0,a0,966 # 800085f8 <syscalls+0xf8>
    8000323a:	ffffd097          	auipc	ra,0xffffd
    8000323e:	30a080e7          	jalr	778(ra) # 80000544 <panic>

0000000080003242 <balloc>:
{
    80003242:	711d                	addi	sp,sp,-96
    80003244:	ec86                	sd	ra,88(sp)
    80003246:	e8a2                	sd	s0,80(sp)
    80003248:	e4a6                	sd	s1,72(sp)
    8000324a:	e0ca                	sd	s2,64(sp)
    8000324c:	fc4e                	sd	s3,56(sp)
    8000324e:	f852                	sd	s4,48(sp)
    80003250:	f456                	sd	s5,40(sp)
    80003252:	f05a                	sd	s6,32(sp)
    80003254:	ec5e                	sd	s7,24(sp)
    80003256:	e862                	sd	s8,16(sp)
    80003258:	e466                	sd	s9,8(sp)
    8000325a:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000325c:	00028797          	auipc	a5,0x28
    80003260:	2807a783          	lw	a5,640(a5) # 8002b4dc <sb+0x4>
    80003264:	10078163          	beqz	a5,80003366 <balloc+0x124>
    80003268:	8baa                	mv	s7,a0
    8000326a:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000326c:	00028b17          	auipc	s6,0x28
    80003270:	26cb0b13          	addi	s6,s6,620 # 8002b4d8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003274:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003276:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003278:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000327a:	6c89                	lui	s9,0x2
    8000327c:	a061                	j	80003304 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000327e:	974a                	add	a4,a4,s2
    80003280:	8fd5                	or	a5,a5,a3
    80003282:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003286:	854a                	mv	a0,s2
    80003288:	00001097          	auipc	ra,0x1
    8000328c:	0ac080e7          	jalr	172(ra) # 80004334 <log_write>
        brelse(bp);
    80003290:	854a                	mv	a0,s2
    80003292:	00000097          	auipc	ra,0x0
    80003296:	e1e080e7          	jalr	-482(ra) # 800030b0 <brelse>
  bp = bread(dev, bno);
    8000329a:	85a6                	mv	a1,s1
    8000329c:	855e                	mv	a0,s7
    8000329e:	00000097          	auipc	ra,0x0
    800032a2:	ce2080e7          	jalr	-798(ra) # 80002f80 <bread>
    800032a6:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800032a8:	40000613          	li	a2,1024
    800032ac:	4581                	li	a1,0
    800032ae:	05850513          	addi	a0,a0,88
    800032b2:	ffffe097          	auipc	ra,0xffffe
    800032b6:	a34080e7          	jalr	-1484(ra) # 80000ce6 <memset>
  log_write(bp);
    800032ba:	854a                	mv	a0,s2
    800032bc:	00001097          	auipc	ra,0x1
    800032c0:	078080e7          	jalr	120(ra) # 80004334 <log_write>
  brelse(bp);
    800032c4:	854a                	mv	a0,s2
    800032c6:	00000097          	auipc	ra,0x0
    800032ca:	dea080e7          	jalr	-534(ra) # 800030b0 <brelse>
}
    800032ce:	8526                	mv	a0,s1
    800032d0:	60e6                	ld	ra,88(sp)
    800032d2:	6446                	ld	s0,80(sp)
    800032d4:	64a6                	ld	s1,72(sp)
    800032d6:	6906                	ld	s2,64(sp)
    800032d8:	79e2                	ld	s3,56(sp)
    800032da:	7a42                	ld	s4,48(sp)
    800032dc:	7aa2                	ld	s5,40(sp)
    800032de:	7b02                	ld	s6,32(sp)
    800032e0:	6be2                	ld	s7,24(sp)
    800032e2:	6c42                	ld	s8,16(sp)
    800032e4:	6ca2                	ld	s9,8(sp)
    800032e6:	6125                	addi	sp,sp,96
    800032e8:	8082                	ret
    brelse(bp);
    800032ea:	854a                	mv	a0,s2
    800032ec:	00000097          	auipc	ra,0x0
    800032f0:	dc4080e7          	jalr	-572(ra) # 800030b0 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800032f4:	015c87bb          	addw	a5,s9,s5
    800032f8:	00078a9b          	sext.w	s5,a5
    800032fc:	004b2703          	lw	a4,4(s6)
    80003300:	06eaf363          	bgeu	s5,a4,80003366 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    80003304:	41fad79b          	sraiw	a5,s5,0x1f
    80003308:	0137d79b          	srliw	a5,a5,0x13
    8000330c:	015787bb          	addw	a5,a5,s5
    80003310:	40d7d79b          	sraiw	a5,a5,0xd
    80003314:	01cb2583          	lw	a1,28(s6)
    80003318:	9dbd                	addw	a1,a1,a5
    8000331a:	855e                	mv	a0,s7
    8000331c:	00000097          	auipc	ra,0x0
    80003320:	c64080e7          	jalr	-924(ra) # 80002f80 <bread>
    80003324:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003326:	004b2503          	lw	a0,4(s6)
    8000332a:	000a849b          	sext.w	s1,s5
    8000332e:	8662                	mv	a2,s8
    80003330:	faa4fde3          	bgeu	s1,a0,800032ea <balloc+0xa8>
      m = 1 << (bi % 8);
    80003334:	41f6579b          	sraiw	a5,a2,0x1f
    80003338:	01d7d69b          	srliw	a3,a5,0x1d
    8000333c:	00c6873b          	addw	a4,a3,a2
    80003340:	00777793          	andi	a5,a4,7
    80003344:	9f95                	subw	a5,a5,a3
    80003346:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000334a:	4037571b          	sraiw	a4,a4,0x3
    8000334e:	00e906b3          	add	a3,s2,a4
    80003352:	0586c683          	lbu	a3,88(a3)
    80003356:	00d7f5b3          	and	a1,a5,a3
    8000335a:	d195                	beqz	a1,8000327e <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000335c:	2605                	addiw	a2,a2,1
    8000335e:	2485                	addiw	s1,s1,1
    80003360:	fd4618e3          	bne	a2,s4,80003330 <balloc+0xee>
    80003364:	b759                	j	800032ea <balloc+0xa8>
  printf("balloc: out of blocks\n");
    80003366:	00005517          	auipc	a0,0x5
    8000336a:	2aa50513          	addi	a0,a0,682 # 80008610 <syscalls+0x110>
    8000336e:	ffffd097          	auipc	ra,0xffffd
    80003372:	220080e7          	jalr	544(ra) # 8000058e <printf>
  return 0;
    80003376:	4481                	li	s1,0
    80003378:	bf99                	j	800032ce <balloc+0x8c>

000000008000337a <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    8000337a:	7179                	addi	sp,sp,-48
    8000337c:	f406                	sd	ra,40(sp)
    8000337e:	f022                	sd	s0,32(sp)
    80003380:	ec26                	sd	s1,24(sp)
    80003382:	e84a                	sd	s2,16(sp)
    80003384:	e44e                	sd	s3,8(sp)
    80003386:	e052                	sd	s4,0(sp)
    80003388:	1800                	addi	s0,sp,48
    8000338a:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000338c:	47ad                	li	a5,11
    8000338e:	02b7e763          	bltu	a5,a1,800033bc <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    80003392:	02059493          	slli	s1,a1,0x20
    80003396:	9081                	srli	s1,s1,0x20
    80003398:	048a                	slli	s1,s1,0x2
    8000339a:	94aa                	add	s1,s1,a0
    8000339c:	0504a903          	lw	s2,80(s1)
    800033a0:	06091e63          	bnez	s2,8000341c <bmap+0xa2>
      addr = balloc(ip->dev);
    800033a4:	4108                	lw	a0,0(a0)
    800033a6:	00000097          	auipc	ra,0x0
    800033aa:	e9c080e7          	jalr	-356(ra) # 80003242 <balloc>
    800033ae:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800033b2:	06090563          	beqz	s2,8000341c <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    800033b6:	0524a823          	sw	s2,80(s1)
    800033ba:	a08d                	j	8000341c <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    800033bc:	ff45849b          	addiw	s1,a1,-12
    800033c0:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800033c4:	0ff00793          	li	a5,255
    800033c8:	08e7e563          	bltu	a5,a4,80003452 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800033cc:	08052903          	lw	s2,128(a0)
    800033d0:	00091d63          	bnez	s2,800033ea <bmap+0x70>
      addr = balloc(ip->dev);
    800033d4:	4108                	lw	a0,0(a0)
    800033d6:	00000097          	auipc	ra,0x0
    800033da:	e6c080e7          	jalr	-404(ra) # 80003242 <balloc>
    800033de:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800033e2:	02090d63          	beqz	s2,8000341c <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800033e6:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800033ea:	85ca                	mv	a1,s2
    800033ec:	0009a503          	lw	a0,0(s3)
    800033f0:	00000097          	auipc	ra,0x0
    800033f4:	b90080e7          	jalr	-1136(ra) # 80002f80 <bread>
    800033f8:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800033fa:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800033fe:	02049593          	slli	a1,s1,0x20
    80003402:	9181                	srli	a1,a1,0x20
    80003404:	058a                	slli	a1,a1,0x2
    80003406:	00b784b3          	add	s1,a5,a1
    8000340a:	0004a903          	lw	s2,0(s1)
    8000340e:	02090063          	beqz	s2,8000342e <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003412:	8552                	mv	a0,s4
    80003414:	00000097          	auipc	ra,0x0
    80003418:	c9c080e7          	jalr	-868(ra) # 800030b0 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000341c:	854a                	mv	a0,s2
    8000341e:	70a2                	ld	ra,40(sp)
    80003420:	7402                	ld	s0,32(sp)
    80003422:	64e2                	ld	s1,24(sp)
    80003424:	6942                	ld	s2,16(sp)
    80003426:	69a2                	ld	s3,8(sp)
    80003428:	6a02                	ld	s4,0(sp)
    8000342a:	6145                	addi	sp,sp,48
    8000342c:	8082                	ret
      addr = balloc(ip->dev);
    8000342e:	0009a503          	lw	a0,0(s3)
    80003432:	00000097          	auipc	ra,0x0
    80003436:	e10080e7          	jalr	-496(ra) # 80003242 <balloc>
    8000343a:	0005091b          	sext.w	s2,a0
      if(addr){
    8000343e:	fc090ae3          	beqz	s2,80003412 <bmap+0x98>
        a[bn] = addr;
    80003442:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003446:	8552                	mv	a0,s4
    80003448:	00001097          	auipc	ra,0x1
    8000344c:	eec080e7          	jalr	-276(ra) # 80004334 <log_write>
    80003450:	b7c9                	j	80003412 <bmap+0x98>
  panic("bmap: out of range");
    80003452:	00005517          	auipc	a0,0x5
    80003456:	1d650513          	addi	a0,a0,470 # 80008628 <syscalls+0x128>
    8000345a:	ffffd097          	auipc	ra,0xffffd
    8000345e:	0ea080e7          	jalr	234(ra) # 80000544 <panic>

0000000080003462 <iget>:
{
    80003462:	7179                	addi	sp,sp,-48
    80003464:	f406                	sd	ra,40(sp)
    80003466:	f022                	sd	s0,32(sp)
    80003468:	ec26                	sd	s1,24(sp)
    8000346a:	e84a                	sd	s2,16(sp)
    8000346c:	e44e                	sd	s3,8(sp)
    8000346e:	e052                	sd	s4,0(sp)
    80003470:	1800                	addi	s0,sp,48
    80003472:	89aa                	mv	s3,a0
    80003474:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003476:	00028517          	auipc	a0,0x28
    8000347a:	08250513          	addi	a0,a0,130 # 8002b4f8 <itable>
    8000347e:	ffffd097          	auipc	ra,0xffffd
    80003482:	76c080e7          	jalr	1900(ra) # 80000bea <acquire>
  empty = 0;
    80003486:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003488:	00028497          	auipc	s1,0x28
    8000348c:	08848493          	addi	s1,s1,136 # 8002b510 <itable+0x18>
    80003490:	0002a697          	auipc	a3,0x2a
    80003494:	b1068693          	addi	a3,a3,-1264 # 8002cfa0 <log>
    80003498:	a039                	j	800034a6 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000349a:	02090b63          	beqz	s2,800034d0 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000349e:	08848493          	addi	s1,s1,136
    800034a2:	02d48a63          	beq	s1,a3,800034d6 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800034a6:	449c                	lw	a5,8(s1)
    800034a8:	fef059e3          	blez	a5,8000349a <iget+0x38>
    800034ac:	4098                	lw	a4,0(s1)
    800034ae:	ff3716e3          	bne	a4,s3,8000349a <iget+0x38>
    800034b2:	40d8                	lw	a4,4(s1)
    800034b4:	ff4713e3          	bne	a4,s4,8000349a <iget+0x38>
      ip->ref++;
    800034b8:	2785                	addiw	a5,a5,1
    800034ba:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800034bc:	00028517          	auipc	a0,0x28
    800034c0:	03c50513          	addi	a0,a0,60 # 8002b4f8 <itable>
    800034c4:	ffffd097          	auipc	ra,0xffffd
    800034c8:	7da080e7          	jalr	2010(ra) # 80000c9e <release>
      return ip;
    800034cc:	8926                	mv	s2,s1
    800034ce:	a03d                	j	800034fc <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034d0:	f7f9                	bnez	a5,8000349e <iget+0x3c>
    800034d2:	8926                	mv	s2,s1
    800034d4:	b7e9                	j	8000349e <iget+0x3c>
  if(empty == 0)
    800034d6:	02090c63          	beqz	s2,8000350e <iget+0xac>
  ip->dev = dev;
    800034da:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800034de:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800034e2:	4785                	li	a5,1
    800034e4:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800034e8:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800034ec:	00028517          	auipc	a0,0x28
    800034f0:	00c50513          	addi	a0,a0,12 # 8002b4f8 <itable>
    800034f4:	ffffd097          	auipc	ra,0xffffd
    800034f8:	7aa080e7          	jalr	1962(ra) # 80000c9e <release>
}
    800034fc:	854a                	mv	a0,s2
    800034fe:	70a2                	ld	ra,40(sp)
    80003500:	7402                	ld	s0,32(sp)
    80003502:	64e2                	ld	s1,24(sp)
    80003504:	6942                	ld	s2,16(sp)
    80003506:	69a2                	ld	s3,8(sp)
    80003508:	6a02                	ld	s4,0(sp)
    8000350a:	6145                	addi	sp,sp,48
    8000350c:	8082                	ret
    panic("iget: no inodes");
    8000350e:	00005517          	auipc	a0,0x5
    80003512:	13250513          	addi	a0,a0,306 # 80008640 <syscalls+0x140>
    80003516:	ffffd097          	auipc	ra,0xffffd
    8000351a:	02e080e7          	jalr	46(ra) # 80000544 <panic>

000000008000351e <fsinit>:
fsinit(int dev) {
    8000351e:	7179                	addi	sp,sp,-48
    80003520:	f406                	sd	ra,40(sp)
    80003522:	f022                	sd	s0,32(sp)
    80003524:	ec26                	sd	s1,24(sp)
    80003526:	e84a                	sd	s2,16(sp)
    80003528:	e44e                	sd	s3,8(sp)
    8000352a:	1800                	addi	s0,sp,48
    8000352c:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000352e:	4585                	li	a1,1
    80003530:	00000097          	auipc	ra,0x0
    80003534:	a50080e7          	jalr	-1456(ra) # 80002f80 <bread>
    80003538:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000353a:	00028997          	auipc	s3,0x28
    8000353e:	f9e98993          	addi	s3,s3,-98 # 8002b4d8 <sb>
    80003542:	02000613          	li	a2,32
    80003546:	05850593          	addi	a1,a0,88
    8000354a:	854e                	mv	a0,s3
    8000354c:	ffffd097          	auipc	ra,0xffffd
    80003550:	7fa080e7          	jalr	2042(ra) # 80000d46 <memmove>
  brelse(bp);
    80003554:	8526                	mv	a0,s1
    80003556:	00000097          	auipc	ra,0x0
    8000355a:	b5a080e7          	jalr	-1190(ra) # 800030b0 <brelse>
  if(sb.magic != FSMAGIC)
    8000355e:	0009a703          	lw	a4,0(s3)
    80003562:	102037b7          	lui	a5,0x10203
    80003566:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000356a:	02f71263          	bne	a4,a5,8000358e <fsinit+0x70>
  initlog(dev, &sb);
    8000356e:	00028597          	auipc	a1,0x28
    80003572:	f6a58593          	addi	a1,a1,-150 # 8002b4d8 <sb>
    80003576:	854a                	mv	a0,s2
    80003578:	00001097          	auipc	ra,0x1
    8000357c:	b40080e7          	jalr	-1216(ra) # 800040b8 <initlog>
}
    80003580:	70a2                	ld	ra,40(sp)
    80003582:	7402                	ld	s0,32(sp)
    80003584:	64e2                	ld	s1,24(sp)
    80003586:	6942                	ld	s2,16(sp)
    80003588:	69a2                	ld	s3,8(sp)
    8000358a:	6145                	addi	sp,sp,48
    8000358c:	8082                	ret
    panic("invalid file system");
    8000358e:	00005517          	auipc	a0,0x5
    80003592:	0c250513          	addi	a0,a0,194 # 80008650 <syscalls+0x150>
    80003596:	ffffd097          	auipc	ra,0xffffd
    8000359a:	fae080e7          	jalr	-82(ra) # 80000544 <panic>

000000008000359e <iinit>:
{
    8000359e:	7179                	addi	sp,sp,-48
    800035a0:	f406                	sd	ra,40(sp)
    800035a2:	f022                	sd	s0,32(sp)
    800035a4:	ec26                	sd	s1,24(sp)
    800035a6:	e84a                	sd	s2,16(sp)
    800035a8:	e44e                	sd	s3,8(sp)
    800035aa:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800035ac:	00005597          	auipc	a1,0x5
    800035b0:	0bc58593          	addi	a1,a1,188 # 80008668 <syscalls+0x168>
    800035b4:	00028517          	auipc	a0,0x28
    800035b8:	f4450513          	addi	a0,a0,-188 # 8002b4f8 <itable>
    800035bc:	ffffd097          	auipc	ra,0xffffd
    800035c0:	59e080e7          	jalr	1438(ra) # 80000b5a <initlock>
  for(i = 0; i < NINODE; i++) {
    800035c4:	00028497          	auipc	s1,0x28
    800035c8:	f5c48493          	addi	s1,s1,-164 # 8002b520 <itable+0x28>
    800035cc:	0002a997          	auipc	s3,0x2a
    800035d0:	9e498993          	addi	s3,s3,-1564 # 8002cfb0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800035d4:	00005917          	auipc	s2,0x5
    800035d8:	09c90913          	addi	s2,s2,156 # 80008670 <syscalls+0x170>
    800035dc:	85ca                	mv	a1,s2
    800035de:	8526                	mv	a0,s1
    800035e0:	00001097          	auipc	ra,0x1
    800035e4:	e3a080e7          	jalr	-454(ra) # 8000441a <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800035e8:	08848493          	addi	s1,s1,136
    800035ec:	ff3498e3          	bne	s1,s3,800035dc <iinit+0x3e>
}
    800035f0:	70a2                	ld	ra,40(sp)
    800035f2:	7402                	ld	s0,32(sp)
    800035f4:	64e2                	ld	s1,24(sp)
    800035f6:	6942                	ld	s2,16(sp)
    800035f8:	69a2                	ld	s3,8(sp)
    800035fa:	6145                	addi	sp,sp,48
    800035fc:	8082                	ret

00000000800035fe <ialloc>:
{
    800035fe:	715d                	addi	sp,sp,-80
    80003600:	e486                	sd	ra,72(sp)
    80003602:	e0a2                	sd	s0,64(sp)
    80003604:	fc26                	sd	s1,56(sp)
    80003606:	f84a                	sd	s2,48(sp)
    80003608:	f44e                	sd	s3,40(sp)
    8000360a:	f052                	sd	s4,32(sp)
    8000360c:	ec56                	sd	s5,24(sp)
    8000360e:	e85a                	sd	s6,16(sp)
    80003610:	e45e                	sd	s7,8(sp)
    80003612:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003614:	00028717          	auipc	a4,0x28
    80003618:	ed072703          	lw	a4,-304(a4) # 8002b4e4 <sb+0xc>
    8000361c:	4785                	li	a5,1
    8000361e:	04e7fa63          	bgeu	a5,a4,80003672 <ialloc+0x74>
    80003622:	8aaa                	mv	s5,a0
    80003624:	8bae                	mv	s7,a1
    80003626:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003628:	00028a17          	auipc	s4,0x28
    8000362c:	eb0a0a13          	addi	s4,s4,-336 # 8002b4d8 <sb>
    80003630:	00048b1b          	sext.w	s6,s1
    80003634:	0044d593          	srli	a1,s1,0x4
    80003638:	018a2783          	lw	a5,24(s4)
    8000363c:	9dbd                	addw	a1,a1,a5
    8000363e:	8556                	mv	a0,s5
    80003640:	00000097          	auipc	ra,0x0
    80003644:	940080e7          	jalr	-1728(ra) # 80002f80 <bread>
    80003648:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000364a:	05850993          	addi	s3,a0,88
    8000364e:	00f4f793          	andi	a5,s1,15
    80003652:	079a                	slli	a5,a5,0x6
    80003654:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003656:	00099783          	lh	a5,0(s3)
    8000365a:	c3a1                	beqz	a5,8000369a <ialloc+0x9c>
    brelse(bp);
    8000365c:	00000097          	auipc	ra,0x0
    80003660:	a54080e7          	jalr	-1452(ra) # 800030b0 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003664:	0485                	addi	s1,s1,1
    80003666:	00ca2703          	lw	a4,12(s4)
    8000366a:	0004879b          	sext.w	a5,s1
    8000366e:	fce7e1e3          	bltu	a5,a4,80003630 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003672:	00005517          	auipc	a0,0x5
    80003676:	00650513          	addi	a0,a0,6 # 80008678 <syscalls+0x178>
    8000367a:	ffffd097          	auipc	ra,0xffffd
    8000367e:	f14080e7          	jalr	-236(ra) # 8000058e <printf>
  return 0;
    80003682:	4501                	li	a0,0
}
    80003684:	60a6                	ld	ra,72(sp)
    80003686:	6406                	ld	s0,64(sp)
    80003688:	74e2                	ld	s1,56(sp)
    8000368a:	7942                	ld	s2,48(sp)
    8000368c:	79a2                	ld	s3,40(sp)
    8000368e:	7a02                	ld	s4,32(sp)
    80003690:	6ae2                	ld	s5,24(sp)
    80003692:	6b42                	ld	s6,16(sp)
    80003694:	6ba2                	ld	s7,8(sp)
    80003696:	6161                	addi	sp,sp,80
    80003698:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    8000369a:	04000613          	li	a2,64
    8000369e:	4581                	li	a1,0
    800036a0:	854e                	mv	a0,s3
    800036a2:	ffffd097          	auipc	ra,0xffffd
    800036a6:	644080e7          	jalr	1604(ra) # 80000ce6 <memset>
      dip->type = type;
    800036aa:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800036ae:	854a                	mv	a0,s2
    800036b0:	00001097          	auipc	ra,0x1
    800036b4:	c84080e7          	jalr	-892(ra) # 80004334 <log_write>
      brelse(bp);
    800036b8:	854a                	mv	a0,s2
    800036ba:	00000097          	auipc	ra,0x0
    800036be:	9f6080e7          	jalr	-1546(ra) # 800030b0 <brelse>
      return iget(dev, inum);
    800036c2:	85da                	mv	a1,s6
    800036c4:	8556                	mv	a0,s5
    800036c6:	00000097          	auipc	ra,0x0
    800036ca:	d9c080e7          	jalr	-612(ra) # 80003462 <iget>
    800036ce:	bf5d                	j	80003684 <ialloc+0x86>

00000000800036d0 <iupdate>:
{
    800036d0:	1101                	addi	sp,sp,-32
    800036d2:	ec06                	sd	ra,24(sp)
    800036d4:	e822                	sd	s0,16(sp)
    800036d6:	e426                	sd	s1,8(sp)
    800036d8:	e04a                	sd	s2,0(sp)
    800036da:	1000                	addi	s0,sp,32
    800036dc:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036de:	415c                	lw	a5,4(a0)
    800036e0:	0047d79b          	srliw	a5,a5,0x4
    800036e4:	00028597          	auipc	a1,0x28
    800036e8:	e0c5a583          	lw	a1,-500(a1) # 8002b4f0 <sb+0x18>
    800036ec:	9dbd                	addw	a1,a1,a5
    800036ee:	4108                	lw	a0,0(a0)
    800036f0:	00000097          	auipc	ra,0x0
    800036f4:	890080e7          	jalr	-1904(ra) # 80002f80 <bread>
    800036f8:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036fa:	05850793          	addi	a5,a0,88
    800036fe:	40c8                	lw	a0,4(s1)
    80003700:	893d                	andi	a0,a0,15
    80003702:	051a                	slli	a0,a0,0x6
    80003704:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003706:	04449703          	lh	a4,68(s1)
    8000370a:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000370e:	04649703          	lh	a4,70(s1)
    80003712:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003716:	04849703          	lh	a4,72(s1)
    8000371a:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000371e:	04a49703          	lh	a4,74(s1)
    80003722:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003726:	44f8                	lw	a4,76(s1)
    80003728:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000372a:	03400613          	li	a2,52
    8000372e:	05048593          	addi	a1,s1,80
    80003732:	0531                	addi	a0,a0,12
    80003734:	ffffd097          	auipc	ra,0xffffd
    80003738:	612080e7          	jalr	1554(ra) # 80000d46 <memmove>
  log_write(bp);
    8000373c:	854a                	mv	a0,s2
    8000373e:	00001097          	auipc	ra,0x1
    80003742:	bf6080e7          	jalr	-1034(ra) # 80004334 <log_write>
  brelse(bp);
    80003746:	854a                	mv	a0,s2
    80003748:	00000097          	auipc	ra,0x0
    8000374c:	968080e7          	jalr	-1688(ra) # 800030b0 <brelse>
}
    80003750:	60e2                	ld	ra,24(sp)
    80003752:	6442                	ld	s0,16(sp)
    80003754:	64a2                	ld	s1,8(sp)
    80003756:	6902                	ld	s2,0(sp)
    80003758:	6105                	addi	sp,sp,32
    8000375a:	8082                	ret

000000008000375c <idup>:
{
    8000375c:	1101                	addi	sp,sp,-32
    8000375e:	ec06                	sd	ra,24(sp)
    80003760:	e822                	sd	s0,16(sp)
    80003762:	e426                	sd	s1,8(sp)
    80003764:	1000                	addi	s0,sp,32
    80003766:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003768:	00028517          	auipc	a0,0x28
    8000376c:	d9050513          	addi	a0,a0,-624 # 8002b4f8 <itable>
    80003770:	ffffd097          	auipc	ra,0xffffd
    80003774:	47a080e7          	jalr	1146(ra) # 80000bea <acquire>
  ip->ref++;
    80003778:	449c                	lw	a5,8(s1)
    8000377a:	2785                	addiw	a5,a5,1
    8000377c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000377e:	00028517          	auipc	a0,0x28
    80003782:	d7a50513          	addi	a0,a0,-646 # 8002b4f8 <itable>
    80003786:	ffffd097          	auipc	ra,0xffffd
    8000378a:	518080e7          	jalr	1304(ra) # 80000c9e <release>
}
    8000378e:	8526                	mv	a0,s1
    80003790:	60e2                	ld	ra,24(sp)
    80003792:	6442                	ld	s0,16(sp)
    80003794:	64a2                	ld	s1,8(sp)
    80003796:	6105                	addi	sp,sp,32
    80003798:	8082                	ret

000000008000379a <ilock>:
{
    8000379a:	1101                	addi	sp,sp,-32
    8000379c:	ec06                	sd	ra,24(sp)
    8000379e:	e822                	sd	s0,16(sp)
    800037a0:	e426                	sd	s1,8(sp)
    800037a2:	e04a                	sd	s2,0(sp)
    800037a4:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800037a6:	c115                	beqz	a0,800037ca <ilock+0x30>
    800037a8:	84aa                	mv	s1,a0
    800037aa:	451c                	lw	a5,8(a0)
    800037ac:	00f05f63          	blez	a5,800037ca <ilock+0x30>
  acquiresleep(&ip->lock);
    800037b0:	0541                	addi	a0,a0,16
    800037b2:	00001097          	auipc	ra,0x1
    800037b6:	ca2080e7          	jalr	-862(ra) # 80004454 <acquiresleep>
  if(ip->valid == 0){
    800037ba:	40bc                	lw	a5,64(s1)
    800037bc:	cf99                	beqz	a5,800037da <ilock+0x40>
}
    800037be:	60e2                	ld	ra,24(sp)
    800037c0:	6442                	ld	s0,16(sp)
    800037c2:	64a2                	ld	s1,8(sp)
    800037c4:	6902                	ld	s2,0(sp)
    800037c6:	6105                	addi	sp,sp,32
    800037c8:	8082                	ret
    panic("ilock");
    800037ca:	00005517          	auipc	a0,0x5
    800037ce:	ec650513          	addi	a0,a0,-314 # 80008690 <syscalls+0x190>
    800037d2:	ffffd097          	auipc	ra,0xffffd
    800037d6:	d72080e7          	jalr	-654(ra) # 80000544 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037da:	40dc                	lw	a5,4(s1)
    800037dc:	0047d79b          	srliw	a5,a5,0x4
    800037e0:	00028597          	auipc	a1,0x28
    800037e4:	d105a583          	lw	a1,-752(a1) # 8002b4f0 <sb+0x18>
    800037e8:	9dbd                	addw	a1,a1,a5
    800037ea:	4088                	lw	a0,0(s1)
    800037ec:	fffff097          	auipc	ra,0xfffff
    800037f0:	794080e7          	jalr	1940(ra) # 80002f80 <bread>
    800037f4:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037f6:	05850593          	addi	a1,a0,88
    800037fa:	40dc                	lw	a5,4(s1)
    800037fc:	8bbd                	andi	a5,a5,15
    800037fe:	079a                	slli	a5,a5,0x6
    80003800:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003802:	00059783          	lh	a5,0(a1)
    80003806:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000380a:	00259783          	lh	a5,2(a1)
    8000380e:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003812:	00459783          	lh	a5,4(a1)
    80003816:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000381a:	00659783          	lh	a5,6(a1)
    8000381e:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003822:	459c                	lw	a5,8(a1)
    80003824:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003826:	03400613          	li	a2,52
    8000382a:	05b1                	addi	a1,a1,12
    8000382c:	05048513          	addi	a0,s1,80
    80003830:	ffffd097          	auipc	ra,0xffffd
    80003834:	516080e7          	jalr	1302(ra) # 80000d46 <memmove>
    brelse(bp);
    80003838:	854a                	mv	a0,s2
    8000383a:	00000097          	auipc	ra,0x0
    8000383e:	876080e7          	jalr	-1930(ra) # 800030b0 <brelse>
    ip->valid = 1;
    80003842:	4785                	li	a5,1
    80003844:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003846:	04449783          	lh	a5,68(s1)
    8000384a:	fbb5                	bnez	a5,800037be <ilock+0x24>
      panic("ilock: no type");
    8000384c:	00005517          	auipc	a0,0x5
    80003850:	e4c50513          	addi	a0,a0,-436 # 80008698 <syscalls+0x198>
    80003854:	ffffd097          	auipc	ra,0xffffd
    80003858:	cf0080e7          	jalr	-784(ra) # 80000544 <panic>

000000008000385c <iunlock>:
{
    8000385c:	1101                	addi	sp,sp,-32
    8000385e:	ec06                	sd	ra,24(sp)
    80003860:	e822                	sd	s0,16(sp)
    80003862:	e426                	sd	s1,8(sp)
    80003864:	e04a                	sd	s2,0(sp)
    80003866:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003868:	c905                	beqz	a0,80003898 <iunlock+0x3c>
    8000386a:	84aa                	mv	s1,a0
    8000386c:	01050913          	addi	s2,a0,16
    80003870:	854a                	mv	a0,s2
    80003872:	00001097          	auipc	ra,0x1
    80003876:	c7c080e7          	jalr	-900(ra) # 800044ee <holdingsleep>
    8000387a:	cd19                	beqz	a0,80003898 <iunlock+0x3c>
    8000387c:	449c                	lw	a5,8(s1)
    8000387e:	00f05d63          	blez	a5,80003898 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003882:	854a                	mv	a0,s2
    80003884:	00001097          	auipc	ra,0x1
    80003888:	c26080e7          	jalr	-986(ra) # 800044aa <releasesleep>
}
    8000388c:	60e2                	ld	ra,24(sp)
    8000388e:	6442                	ld	s0,16(sp)
    80003890:	64a2                	ld	s1,8(sp)
    80003892:	6902                	ld	s2,0(sp)
    80003894:	6105                	addi	sp,sp,32
    80003896:	8082                	ret
    panic("iunlock");
    80003898:	00005517          	auipc	a0,0x5
    8000389c:	e1050513          	addi	a0,a0,-496 # 800086a8 <syscalls+0x1a8>
    800038a0:	ffffd097          	auipc	ra,0xffffd
    800038a4:	ca4080e7          	jalr	-860(ra) # 80000544 <panic>

00000000800038a8 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800038a8:	7179                	addi	sp,sp,-48
    800038aa:	f406                	sd	ra,40(sp)
    800038ac:	f022                	sd	s0,32(sp)
    800038ae:	ec26                	sd	s1,24(sp)
    800038b0:	e84a                	sd	s2,16(sp)
    800038b2:	e44e                	sd	s3,8(sp)
    800038b4:	e052                	sd	s4,0(sp)
    800038b6:	1800                	addi	s0,sp,48
    800038b8:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800038ba:	05050493          	addi	s1,a0,80
    800038be:	08050913          	addi	s2,a0,128
    800038c2:	a021                	j	800038ca <itrunc+0x22>
    800038c4:	0491                	addi	s1,s1,4
    800038c6:	01248d63          	beq	s1,s2,800038e0 <itrunc+0x38>
    if(ip->addrs[i]){
    800038ca:	408c                	lw	a1,0(s1)
    800038cc:	dde5                	beqz	a1,800038c4 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800038ce:	0009a503          	lw	a0,0(s3)
    800038d2:	00000097          	auipc	ra,0x0
    800038d6:	8f4080e7          	jalr	-1804(ra) # 800031c6 <bfree>
      ip->addrs[i] = 0;
    800038da:	0004a023          	sw	zero,0(s1)
    800038de:	b7dd                	j	800038c4 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800038e0:	0809a583          	lw	a1,128(s3)
    800038e4:	e185                	bnez	a1,80003904 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800038e6:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800038ea:	854e                	mv	a0,s3
    800038ec:	00000097          	auipc	ra,0x0
    800038f0:	de4080e7          	jalr	-540(ra) # 800036d0 <iupdate>
}
    800038f4:	70a2                	ld	ra,40(sp)
    800038f6:	7402                	ld	s0,32(sp)
    800038f8:	64e2                	ld	s1,24(sp)
    800038fa:	6942                	ld	s2,16(sp)
    800038fc:	69a2                	ld	s3,8(sp)
    800038fe:	6a02                	ld	s4,0(sp)
    80003900:	6145                	addi	sp,sp,48
    80003902:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003904:	0009a503          	lw	a0,0(s3)
    80003908:	fffff097          	auipc	ra,0xfffff
    8000390c:	678080e7          	jalr	1656(ra) # 80002f80 <bread>
    80003910:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003912:	05850493          	addi	s1,a0,88
    80003916:	45850913          	addi	s2,a0,1112
    8000391a:	a811                	j	8000392e <itrunc+0x86>
        bfree(ip->dev, a[j]);
    8000391c:	0009a503          	lw	a0,0(s3)
    80003920:	00000097          	auipc	ra,0x0
    80003924:	8a6080e7          	jalr	-1882(ra) # 800031c6 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003928:	0491                	addi	s1,s1,4
    8000392a:	01248563          	beq	s1,s2,80003934 <itrunc+0x8c>
      if(a[j])
    8000392e:	408c                	lw	a1,0(s1)
    80003930:	dde5                	beqz	a1,80003928 <itrunc+0x80>
    80003932:	b7ed                	j	8000391c <itrunc+0x74>
    brelse(bp);
    80003934:	8552                	mv	a0,s4
    80003936:	fffff097          	auipc	ra,0xfffff
    8000393a:	77a080e7          	jalr	1914(ra) # 800030b0 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    8000393e:	0809a583          	lw	a1,128(s3)
    80003942:	0009a503          	lw	a0,0(s3)
    80003946:	00000097          	auipc	ra,0x0
    8000394a:	880080e7          	jalr	-1920(ra) # 800031c6 <bfree>
    ip->addrs[NDIRECT] = 0;
    8000394e:	0809a023          	sw	zero,128(s3)
    80003952:	bf51                	j	800038e6 <itrunc+0x3e>

0000000080003954 <iput>:
{
    80003954:	1101                	addi	sp,sp,-32
    80003956:	ec06                	sd	ra,24(sp)
    80003958:	e822                	sd	s0,16(sp)
    8000395a:	e426                	sd	s1,8(sp)
    8000395c:	e04a                	sd	s2,0(sp)
    8000395e:	1000                	addi	s0,sp,32
    80003960:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003962:	00028517          	auipc	a0,0x28
    80003966:	b9650513          	addi	a0,a0,-1130 # 8002b4f8 <itable>
    8000396a:	ffffd097          	auipc	ra,0xffffd
    8000396e:	280080e7          	jalr	640(ra) # 80000bea <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003972:	4498                	lw	a4,8(s1)
    80003974:	4785                	li	a5,1
    80003976:	02f70363          	beq	a4,a5,8000399c <iput+0x48>
  ip->ref--;
    8000397a:	449c                	lw	a5,8(s1)
    8000397c:	37fd                	addiw	a5,a5,-1
    8000397e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003980:	00028517          	auipc	a0,0x28
    80003984:	b7850513          	addi	a0,a0,-1160 # 8002b4f8 <itable>
    80003988:	ffffd097          	auipc	ra,0xffffd
    8000398c:	316080e7          	jalr	790(ra) # 80000c9e <release>
}
    80003990:	60e2                	ld	ra,24(sp)
    80003992:	6442                	ld	s0,16(sp)
    80003994:	64a2                	ld	s1,8(sp)
    80003996:	6902                	ld	s2,0(sp)
    80003998:	6105                	addi	sp,sp,32
    8000399a:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000399c:	40bc                	lw	a5,64(s1)
    8000399e:	dff1                	beqz	a5,8000397a <iput+0x26>
    800039a0:	04a49783          	lh	a5,74(s1)
    800039a4:	fbf9                	bnez	a5,8000397a <iput+0x26>
    acquiresleep(&ip->lock);
    800039a6:	01048913          	addi	s2,s1,16
    800039aa:	854a                	mv	a0,s2
    800039ac:	00001097          	auipc	ra,0x1
    800039b0:	aa8080e7          	jalr	-1368(ra) # 80004454 <acquiresleep>
    release(&itable.lock);
    800039b4:	00028517          	auipc	a0,0x28
    800039b8:	b4450513          	addi	a0,a0,-1212 # 8002b4f8 <itable>
    800039bc:	ffffd097          	auipc	ra,0xffffd
    800039c0:	2e2080e7          	jalr	738(ra) # 80000c9e <release>
    itrunc(ip);
    800039c4:	8526                	mv	a0,s1
    800039c6:	00000097          	auipc	ra,0x0
    800039ca:	ee2080e7          	jalr	-286(ra) # 800038a8 <itrunc>
    ip->type = 0;
    800039ce:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800039d2:	8526                	mv	a0,s1
    800039d4:	00000097          	auipc	ra,0x0
    800039d8:	cfc080e7          	jalr	-772(ra) # 800036d0 <iupdate>
    ip->valid = 0;
    800039dc:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800039e0:	854a                	mv	a0,s2
    800039e2:	00001097          	auipc	ra,0x1
    800039e6:	ac8080e7          	jalr	-1336(ra) # 800044aa <releasesleep>
    acquire(&itable.lock);
    800039ea:	00028517          	auipc	a0,0x28
    800039ee:	b0e50513          	addi	a0,a0,-1266 # 8002b4f8 <itable>
    800039f2:	ffffd097          	auipc	ra,0xffffd
    800039f6:	1f8080e7          	jalr	504(ra) # 80000bea <acquire>
    800039fa:	b741                	j	8000397a <iput+0x26>

00000000800039fc <iunlockput>:
{
    800039fc:	1101                	addi	sp,sp,-32
    800039fe:	ec06                	sd	ra,24(sp)
    80003a00:	e822                	sd	s0,16(sp)
    80003a02:	e426                	sd	s1,8(sp)
    80003a04:	1000                	addi	s0,sp,32
    80003a06:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a08:	00000097          	auipc	ra,0x0
    80003a0c:	e54080e7          	jalr	-428(ra) # 8000385c <iunlock>
  iput(ip);
    80003a10:	8526                	mv	a0,s1
    80003a12:	00000097          	auipc	ra,0x0
    80003a16:	f42080e7          	jalr	-190(ra) # 80003954 <iput>
}
    80003a1a:	60e2                	ld	ra,24(sp)
    80003a1c:	6442                	ld	s0,16(sp)
    80003a1e:	64a2                	ld	s1,8(sp)
    80003a20:	6105                	addi	sp,sp,32
    80003a22:	8082                	ret

0000000080003a24 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a24:	1141                	addi	sp,sp,-16
    80003a26:	e422                	sd	s0,8(sp)
    80003a28:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a2a:	411c                	lw	a5,0(a0)
    80003a2c:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a2e:	415c                	lw	a5,4(a0)
    80003a30:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a32:	04451783          	lh	a5,68(a0)
    80003a36:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a3a:	04a51783          	lh	a5,74(a0)
    80003a3e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a42:	04c56783          	lwu	a5,76(a0)
    80003a46:	e99c                	sd	a5,16(a1)
}
    80003a48:	6422                	ld	s0,8(sp)
    80003a4a:	0141                	addi	sp,sp,16
    80003a4c:	8082                	ret

0000000080003a4e <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a4e:	457c                	lw	a5,76(a0)
    80003a50:	0ed7e963          	bltu	a5,a3,80003b42 <readi+0xf4>
{
    80003a54:	7159                	addi	sp,sp,-112
    80003a56:	f486                	sd	ra,104(sp)
    80003a58:	f0a2                	sd	s0,96(sp)
    80003a5a:	eca6                	sd	s1,88(sp)
    80003a5c:	e8ca                	sd	s2,80(sp)
    80003a5e:	e4ce                	sd	s3,72(sp)
    80003a60:	e0d2                	sd	s4,64(sp)
    80003a62:	fc56                	sd	s5,56(sp)
    80003a64:	f85a                	sd	s6,48(sp)
    80003a66:	f45e                	sd	s7,40(sp)
    80003a68:	f062                	sd	s8,32(sp)
    80003a6a:	ec66                	sd	s9,24(sp)
    80003a6c:	e86a                	sd	s10,16(sp)
    80003a6e:	e46e                	sd	s11,8(sp)
    80003a70:	1880                	addi	s0,sp,112
    80003a72:	8b2a                	mv	s6,a0
    80003a74:	8bae                	mv	s7,a1
    80003a76:	8a32                	mv	s4,a2
    80003a78:	84b6                	mv	s1,a3
    80003a7a:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003a7c:	9f35                	addw	a4,a4,a3
    return 0;
    80003a7e:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a80:	0ad76063          	bltu	a4,a3,80003b20 <readi+0xd2>
  if(off + n > ip->size)
    80003a84:	00e7f463          	bgeu	a5,a4,80003a8c <readi+0x3e>
    n = ip->size - off;
    80003a88:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a8c:	0a0a8963          	beqz	s5,80003b3e <readi+0xf0>
    80003a90:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a92:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a96:	5c7d                	li	s8,-1
    80003a98:	a82d                	j	80003ad2 <readi+0x84>
    80003a9a:	020d1d93          	slli	s11,s10,0x20
    80003a9e:	020ddd93          	srli	s11,s11,0x20
    80003aa2:	05890613          	addi	a2,s2,88
    80003aa6:	86ee                	mv	a3,s11
    80003aa8:	963a                	add	a2,a2,a4
    80003aaa:	85d2                	mv	a1,s4
    80003aac:	855e                	mv	a0,s7
    80003aae:	fffff097          	auipc	ra,0xfffff
    80003ab2:	a46080e7          	jalr	-1466(ra) # 800024f4 <either_copyout>
    80003ab6:	05850d63          	beq	a0,s8,80003b10 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003aba:	854a                	mv	a0,s2
    80003abc:	fffff097          	auipc	ra,0xfffff
    80003ac0:	5f4080e7          	jalr	1524(ra) # 800030b0 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ac4:	013d09bb          	addw	s3,s10,s3
    80003ac8:	009d04bb          	addw	s1,s10,s1
    80003acc:	9a6e                	add	s4,s4,s11
    80003ace:	0559f763          	bgeu	s3,s5,80003b1c <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003ad2:	00a4d59b          	srliw	a1,s1,0xa
    80003ad6:	855a                	mv	a0,s6
    80003ad8:	00000097          	auipc	ra,0x0
    80003adc:	8a2080e7          	jalr	-1886(ra) # 8000337a <bmap>
    80003ae0:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003ae4:	cd85                	beqz	a1,80003b1c <readi+0xce>
    bp = bread(ip->dev, addr);
    80003ae6:	000b2503          	lw	a0,0(s6)
    80003aea:	fffff097          	auipc	ra,0xfffff
    80003aee:	496080e7          	jalr	1174(ra) # 80002f80 <bread>
    80003af2:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003af4:	3ff4f713          	andi	a4,s1,1023
    80003af8:	40ec87bb          	subw	a5,s9,a4
    80003afc:	413a86bb          	subw	a3,s5,s3
    80003b00:	8d3e                	mv	s10,a5
    80003b02:	2781                	sext.w	a5,a5
    80003b04:	0006861b          	sext.w	a2,a3
    80003b08:	f8f679e3          	bgeu	a2,a5,80003a9a <readi+0x4c>
    80003b0c:	8d36                	mv	s10,a3
    80003b0e:	b771                	j	80003a9a <readi+0x4c>
      brelse(bp);
    80003b10:	854a                	mv	a0,s2
    80003b12:	fffff097          	auipc	ra,0xfffff
    80003b16:	59e080e7          	jalr	1438(ra) # 800030b0 <brelse>
      tot = -1;
    80003b1a:	59fd                	li	s3,-1
  }
  return tot;
    80003b1c:	0009851b          	sext.w	a0,s3
}
    80003b20:	70a6                	ld	ra,104(sp)
    80003b22:	7406                	ld	s0,96(sp)
    80003b24:	64e6                	ld	s1,88(sp)
    80003b26:	6946                	ld	s2,80(sp)
    80003b28:	69a6                	ld	s3,72(sp)
    80003b2a:	6a06                	ld	s4,64(sp)
    80003b2c:	7ae2                	ld	s5,56(sp)
    80003b2e:	7b42                	ld	s6,48(sp)
    80003b30:	7ba2                	ld	s7,40(sp)
    80003b32:	7c02                	ld	s8,32(sp)
    80003b34:	6ce2                	ld	s9,24(sp)
    80003b36:	6d42                	ld	s10,16(sp)
    80003b38:	6da2                	ld	s11,8(sp)
    80003b3a:	6165                	addi	sp,sp,112
    80003b3c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b3e:	89d6                	mv	s3,s5
    80003b40:	bff1                	j	80003b1c <readi+0xce>
    return 0;
    80003b42:	4501                	li	a0,0
}
    80003b44:	8082                	ret

0000000080003b46 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b46:	457c                	lw	a5,76(a0)
    80003b48:	10d7e863          	bltu	a5,a3,80003c58 <writei+0x112>
{
    80003b4c:	7159                	addi	sp,sp,-112
    80003b4e:	f486                	sd	ra,104(sp)
    80003b50:	f0a2                	sd	s0,96(sp)
    80003b52:	eca6                	sd	s1,88(sp)
    80003b54:	e8ca                	sd	s2,80(sp)
    80003b56:	e4ce                	sd	s3,72(sp)
    80003b58:	e0d2                	sd	s4,64(sp)
    80003b5a:	fc56                	sd	s5,56(sp)
    80003b5c:	f85a                	sd	s6,48(sp)
    80003b5e:	f45e                	sd	s7,40(sp)
    80003b60:	f062                	sd	s8,32(sp)
    80003b62:	ec66                	sd	s9,24(sp)
    80003b64:	e86a                	sd	s10,16(sp)
    80003b66:	e46e                	sd	s11,8(sp)
    80003b68:	1880                	addi	s0,sp,112
    80003b6a:	8aaa                	mv	s5,a0
    80003b6c:	8bae                	mv	s7,a1
    80003b6e:	8a32                	mv	s4,a2
    80003b70:	8936                	mv	s2,a3
    80003b72:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b74:	00e687bb          	addw	a5,a3,a4
    80003b78:	0ed7e263          	bltu	a5,a3,80003c5c <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b7c:	00043737          	lui	a4,0x43
    80003b80:	0ef76063          	bltu	a4,a5,80003c60 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b84:	0c0b0863          	beqz	s6,80003c54 <writei+0x10e>
    80003b88:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b8a:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b8e:	5c7d                	li	s8,-1
    80003b90:	a091                	j	80003bd4 <writei+0x8e>
    80003b92:	020d1d93          	slli	s11,s10,0x20
    80003b96:	020ddd93          	srli	s11,s11,0x20
    80003b9a:	05848513          	addi	a0,s1,88
    80003b9e:	86ee                	mv	a3,s11
    80003ba0:	8652                	mv	a2,s4
    80003ba2:	85de                	mv	a1,s7
    80003ba4:	953a                	add	a0,a0,a4
    80003ba6:	fffff097          	auipc	ra,0xfffff
    80003baa:	9a4080e7          	jalr	-1628(ra) # 8000254a <either_copyin>
    80003bae:	07850263          	beq	a0,s8,80003c12 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003bb2:	8526                	mv	a0,s1
    80003bb4:	00000097          	auipc	ra,0x0
    80003bb8:	780080e7          	jalr	1920(ra) # 80004334 <log_write>
    brelse(bp);
    80003bbc:	8526                	mv	a0,s1
    80003bbe:	fffff097          	auipc	ra,0xfffff
    80003bc2:	4f2080e7          	jalr	1266(ra) # 800030b0 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bc6:	013d09bb          	addw	s3,s10,s3
    80003bca:	012d093b          	addw	s2,s10,s2
    80003bce:	9a6e                	add	s4,s4,s11
    80003bd0:	0569f663          	bgeu	s3,s6,80003c1c <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003bd4:	00a9559b          	srliw	a1,s2,0xa
    80003bd8:	8556                	mv	a0,s5
    80003bda:	fffff097          	auipc	ra,0xfffff
    80003bde:	7a0080e7          	jalr	1952(ra) # 8000337a <bmap>
    80003be2:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003be6:	c99d                	beqz	a1,80003c1c <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003be8:	000aa503          	lw	a0,0(s5)
    80003bec:	fffff097          	auipc	ra,0xfffff
    80003bf0:	394080e7          	jalr	916(ra) # 80002f80 <bread>
    80003bf4:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bf6:	3ff97713          	andi	a4,s2,1023
    80003bfa:	40ec87bb          	subw	a5,s9,a4
    80003bfe:	413b06bb          	subw	a3,s6,s3
    80003c02:	8d3e                	mv	s10,a5
    80003c04:	2781                	sext.w	a5,a5
    80003c06:	0006861b          	sext.w	a2,a3
    80003c0a:	f8f674e3          	bgeu	a2,a5,80003b92 <writei+0x4c>
    80003c0e:	8d36                	mv	s10,a3
    80003c10:	b749                	j	80003b92 <writei+0x4c>
      brelse(bp);
    80003c12:	8526                	mv	a0,s1
    80003c14:	fffff097          	auipc	ra,0xfffff
    80003c18:	49c080e7          	jalr	1180(ra) # 800030b0 <brelse>
  }

  if(off > ip->size)
    80003c1c:	04caa783          	lw	a5,76(s5)
    80003c20:	0127f463          	bgeu	a5,s2,80003c28 <writei+0xe2>
    ip->size = off;
    80003c24:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003c28:	8556                	mv	a0,s5
    80003c2a:	00000097          	auipc	ra,0x0
    80003c2e:	aa6080e7          	jalr	-1370(ra) # 800036d0 <iupdate>

  return tot;
    80003c32:	0009851b          	sext.w	a0,s3
}
    80003c36:	70a6                	ld	ra,104(sp)
    80003c38:	7406                	ld	s0,96(sp)
    80003c3a:	64e6                	ld	s1,88(sp)
    80003c3c:	6946                	ld	s2,80(sp)
    80003c3e:	69a6                	ld	s3,72(sp)
    80003c40:	6a06                	ld	s4,64(sp)
    80003c42:	7ae2                	ld	s5,56(sp)
    80003c44:	7b42                	ld	s6,48(sp)
    80003c46:	7ba2                	ld	s7,40(sp)
    80003c48:	7c02                	ld	s8,32(sp)
    80003c4a:	6ce2                	ld	s9,24(sp)
    80003c4c:	6d42                	ld	s10,16(sp)
    80003c4e:	6da2                	ld	s11,8(sp)
    80003c50:	6165                	addi	sp,sp,112
    80003c52:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c54:	89da                	mv	s3,s6
    80003c56:	bfc9                	j	80003c28 <writei+0xe2>
    return -1;
    80003c58:	557d                	li	a0,-1
}
    80003c5a:	8082                	ret
    return -1;
    80003c5c:	557d                	li	a0,-1
    80003c5e:	bfe1                	j	80003c36 <writei+0xf0>
    return -1;
    80003c60:	557d                	li	a0,-1
    80003c62:	bfd1                	j	80003c36 <writei+0xf0>

0000000080003c64 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c64:	1141                	addi	sp,sp,-16
    80003c66:	e406                	sd	ra,8(sp)
    80003c68:	e022                	sd	s0,0(sp)
    80003c6a:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c6c:	4639                	li	a2,14
    80003c6e:	ffffd097          	auipc	ra,0xffffd
    80003c72:	150080e7          	jalr	336(ra) # 80000dbe <strncmp>
}
    80003c76:	60a2                	ld	ra,8(sp)
    80003c78:	6402                	ld	s0,0(sp)
    80003c7a:	0141                	addi	sp,sp,16
    80003c7c:	8082                	ret

0000000080003c7e <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c7e:	7139                	addi	sp,sp,-64
    80003c80:	fc06                	sd	ra,56(sp)
    80003c82:	f822                	sd	s0,48(sp)
    80003c84:	f426                	sd	s1,40(sp)
    80003c86:	f04a                	sd	s2,32(sp)
    80003c88:	ec4e                	sd	s3,24(sp)
    80003c8a:	e852                	sd	s4,16(sp)
    80003c8c:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c8e:	04451703          	lh	a4,68(a0)
    80003c92:	4785                	li	a5,1
    80003c94:	00f71a63          	bne	a4,a5,80003ca8 <dirlookup+0x2a>
    80003c98:	892a                	mv	s2,a0
    80003c9a:	89ae                	mv	s3,a1
    80003c9c:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c9e:	457c                	lw	a5,76(a0)
    80003ca0:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003ca2:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ca4:	e79d                	bnez	a5,80003cd2 <dirlookup+0x54>
    80003ca6:	a8a5                	j	80003d1e <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003ca8:	00005517          	auipc	a0,0x5
    80003cac:	a0850513          	addi	a0,a0,-1528 # 800086b0 <syscalls+0x1b0>
    80003cb0:	ffffd097          	auipc	ra,0xffffd
    80003cb4:	894080e7          	jalr	-1900(ra) # 80000544 <panic>
      panic("dirlookup read");
    80003cb8:	00005517          	auipc	a0,0x5
    80003cbc:	a1050513          	addi	a0,a0,-1520 # 800086c8 <syscalls+0x1c8>
    80003cc0:	ffffd097          	auipc	ra,0xffffd
    80003cc4:	884080e7          	jalr	-1916(ra) # 80000544 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cc8:	24c1                	addiw	s1,s1,16
    80003cca:	04c92783          	lw	a5,76(s2)
    80003cce:	04f4f763          	bgeu	s1,a5,80003d1c <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003cd2:	4741                	li	a4,16
    80003cd4:	86a6                	mv	a3,s1
    80003cd6:	fc040613          	addi	a2,s0,-64
    80003cda:	4581                	li	a1,0
    80003cdc:	854a                	mv	a0,s2
    80003cde:	00000097          	auipc	ra,0x0
    80003ce2:	d70080e7          	jalr	-656(ra) # 80003a4e <readi>
    80003ce6:	47c1                	li	a5,16
    80003ce8:	fcf518e3          	bne	a0,a5,80003cb8 <dirlookup+0x3a>
    if(de.inum == 0)
    80003cec:	fc045783          	lhu	a5,-64(s0)
    80003cf0:	dfe1                	beqz	a5,80003cc8 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003cf2:	fc240593          	addi	a1,s0,-62
    80003cf6:	854e                	mv	a0,s3
    80003cf8:	00000097          	auipc	ra,0x0
    80003cfc:	f6c080e7          	jalr	-148(ra) # 80003c64 <namecmp>
    80003d00:	f561                	bnez	a0,80003cc8 <dirlookup+0x4a>
      if(poff)
    80003d02:	000a0463          	beqz	s4,80003d0a <dirlookup+0x8c>
        *poff = off;
    80003d06:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003d0a:	fc045583          	lhu	a1,-64(s0)
    80003d0e:	00092503          	lw	a0,0(s2)
    80003d12:	fffff097          	auipc	ra,0xfffff
    80003d16:	750080e7          	jalr	1872(ra) # 80003462 <iget>
    80003d1a:	a011                	j	80003d1e <dirlookup+0xa0>
  return 0;
    80003d1c:	4501                	li	a0,0
}
    80003d1e:	70e2                	ld	ra,56(sp)
    80003d20:	7442                	ld	s0,48(sp)
    80003d22:	74a2                	ld	s1,40(sp)
    80003d24:	7902                	ld	s2,32(sp)
    80003d26:	69e2                	ld	s3,24(sp)
    80003d28:	6a42                	ld	s4,16(sp)
    80003d2a:	6121                	addi	sp,sp,64
    80003d2c:	8082                	ret

0000000080003d2e <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d2e:	711d                	addi	sp,sp,-96
    80003d30:	ec86                	sd	ra,88(sp)
    80003d32:	e8a2                	sd	s0,80(sp)
    80003d34:	e4a6                	sd	s1,72(sp)
    80003d36:	e0ca                	sd	s2,64(sp)
    80003d38:	fc4e                	sd	s3,56(sp)
    80003d3a:	f852                	sd	s4,48(sp)
    80003d3c:	f456                	sd	s5,40(sp)
    80003d3e:	f05a                	sd	s6,32(sp)
    80003d40:	ec5e                	sd	s7,24(sp)
    80003d42:	e862                	sd	s8,16(sp)
    80003d44:	e466                	sd	s9,8(sp)
    80003d46:	1080                	addi	s0,sp,96
    80003d48:	84aa                	mv	s1,a0
    80003d4a:	8b2e                	mv	s6,a1
    80003d4c:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d4e:	00054703          	lbu	a4,0(a0)
    80003d52:	02f00793          	li	a5,47
    80003d56:	02f70363          	beq	a4,a5,80003d7c <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d5a:	ffffe097          	auipc	ra,0xffffe
    80003d5e:	c6c080e7          	jalr	-916(ra) # 800019c6 <myproc>
    80003d62:	15053503          	ld	a0,336(a0)
    80003d66:	00000097          	auipc	ra,0x0
    80003d6a:	9f6080e7          	jalr	-1546(ra) # 8000375c <idup>
    80003d6e:	89aa                	mv	s3,a0
  while(*path == '/')
    80003d70:	02f00913          	li	s2,47
  len = path - s;
    80003d74:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003d76:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d78:	4c05                	li	s8,1
    80003d7a:	a865                	j	80003e32 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003d7c:	4585                	li	a1,1
    80003d7e:	4505                	li	a0,1
    80003d80:	fffff097          	auipc	ra,0xfffff
    80003d84:	6e2080e7          	jalr	1762(ra) # 80003462 <iget>
    80003d88:	89aa                	mv	s3,a0
    80003d8a:	b7dd                	j	80003d70 <namex+0x42>
      iunlockput(ip);
    80003d8c:	854e                	mv	a0,s3
    80003d8e:	00000097          	auipc	ra,0x0
    80003d92:	c6e080e7          	jalr	-914(ra) # 800039fc <iunlockput>
      return 0;
    80003d96:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d98:	854e                	mv	a0,s3
    80003d9a:	60e6                	ld	ra,88(sp)
    80003d9c:	6446                	ld	s0,80(sp)
    80003d9e:	64a6                	ld	s1,72(sp)
    80003da0:	6906                	ld	s2,64(sp)
    80003da2:	79e2                	ld	s3,56(sp)
    80003da4:	7a42                	ld	s4,48(sp)
    80003da6:	7aa2                	ld	s5,40(sp)
    80003da8:	7b02                	ld	s6,32(sp)
    80003daa:	6be2                	ld	s7,24(sp)
    80003dac:	6c42                	ld	s8,16(sp)
    80003dae:	6ca2                	ld	s9,8(sp)
    80003db0:	6125                	addi	sp,sp,96
    80003db2:	8082                	ret
      iunlock(ip);
    80003db4:	854e                	mv	a0,s3
    80003db6:	00000097          	auipc	ra,0x0
    80003dba:	aa6080e7          	jalr	-1370(ra) # 8000385c <iunlock>
      return ip;
    80003dbe:	bfe9                	j	80003d98 <namex+0x6a>
      iunlockput(ip);
    80003dc0:	854e                	mv	a0,s3
    80003dc2:	00000097          	auipc	ra,0x0
    80003dc6:	c3a080e7          	jalr	-966(ra) # 800039fc <iunlockput>
      return 0;
    80003dca:	89d2                	mv	s3,s4
    80003dcc:	b7f1                	j	80003d98 <namex+0x6a>
  len = path - s;
    80003dce:	40b48633          	sub	a2,s1,a1
    80003dd2:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003dd6:	094cd463          	bge	s9,s4,80003e5e <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003dda:	4639                	li	a2,14
    80003ddc:	8556                	mv	a0,s5
    80003dde:	ffffd097          	auipc	ra,0xffffd
    80003de2:	f68080e7          	jalr	-152(ra) # 80000d46 <memmove>
  while(*path == '/')
    80003de6:	0004c783          	lbu	a5,0(s1)
    80003dea:	01279763          	bne	a5,s2,80003df8 <namex+0xca>
    path++;
    80003dee:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003df0:	0004c783          	lbu	a5,0(s1)
    80003df4:	ff278de3          	beq	a5,s2,80003dee <namex+0xc0>
    ilock(ip);
    80003df8:	854e                	mv	a0,s3
    80003dfa:	00000097          	auipc	ra,0x0
    80003dfe:	9a0080e7          	jalr	-1632(ra) # 8000379a <ilock>
    if(ip->type != T_DIR){
    80003e02:	04499783          	lh	a5,68(s3)
    80003e06:	f98793e3          	bne	a5,s8,80003d8c <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003e0a:	000b0563          	beqz	s6,80003e14 <namex+0xe6>
    80003e0e:	0004c783          	lbu	a5,0(s1)
    80003e12:	d3cd                	beqz	a5,80003db4 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e14:	865e                	mv	a2,s7
    80003e16:	85d6                	mv	a1,s5
    80003e18:	854e                	mv	a0,s3
    80003e1a:	00000097          	auipc	ra,0x0
    80003e1e:	e64080e7          	jalr	-412(ra) # 80003c7e <dirlookup>
    80003e22:	8a2a                	mv	s4,a0
    80003e24:	dd51                	beqz	a0,80003dc0 <namex+0x92>
    iunlockput(ip);
    80003e26:	854e                	mv	a0,s3
    80003e28:	00000097          	auipc	ra,0x0
    80003e2c:	bd4080e7          	jalr	-1068(ra) # 800039fc <iunlockput>
    ip = next;
    80003e30:	89d2                	mv	s3,s4
  while(*path == '/')
    80003e32:	0004c783          	lbu	a5,0(s1)
    80003e36:	05279763          	bne	a5,s2,80003e84 <namex+0x156>
    path++;
    80003e3a:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e3c:	0004c783          	lbu	a5,0(s1)
    80003e40:	ff278de3          	beq	a5,s2,80003e3a <namex+0x10c>
  if(*path == 0)
    80003e44:	c79d                	beqz	a5,80003e72 <namex+0x144>
    path++;
    80003e46:	85a6                	mv	a1,s1
  len = path - s;
    80003e48:	8a5e                	mv	s4,s7
    80003e4a:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003e4c:	01278963          	beq	a5,s2,80003e5e <namex+0x130>
    80003e50:	dfbd                	beqz	a5,80003dce <namex+0xa0>
    path++;
    80003e52:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003e54:	0004c783          	lbu	a5,0(s1)
    80003e58:	ff279ce3          	bne	a5,s2,80003e50 <namex+0x122>
    80003e5c:	bf8d                	j	80003dce <namex+0xa0>
    memmove(name, s, len);
    80003e5e:	2601                	sext.w	a2,a2
    80003e60:	8556                	mv	a0,s5
    80003e62:	ffffd097          	auipc	ra,0xffffd
    80003e66:	ee4080e7          	jalr	-284(ra) # 80000d46 <memmove>
    name[len] = 0;
    80003e6a:	9a56                	add	s4,s4,s5
    80003e6c:	000a0023          	sb	zero,0(s4)
    80003e70:	bf9d                	j	80003de6 <namex+0xb8>
  if(nameiparent){
    80003e72:	f20b03e3          	beqz	s6,80003d98 <namex+0x6a>
    iput(ip);
    80003e76:	854e                	mv	a0,s3
    80003e78:	00000097          	auipc	ra,0x0
    80003e7c:	adc080e7          	jalr	-1316(ra) # 80003954 <iput>
    return 0;
    80003e80:	4981                	li	s3,0
    80003e82:	bf19                	j	80003d98 <namex+0x6a>
  if(*path == 0)
    80003e84:	d7fd                	beqz	a5,80003e72 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003e86:	0004c783          	lbu	a5,0(s1)
    80003e8a:	85a6                	mv	a1,s1
    80003e8c:	b7d1                	j	80003e50 <namex+0x122>

0000000080003e8e <dirlink>:
{
    80003e8e:	7139                	addi	sp,sp,-64
    80003e90:	fc06                	sd	ra,56(sp)
    80003e92:	f822                	sd	s0,48(sp)
    80003e94:	f426                	sd	s1,40(sp)
    80003e96:	f04a                	sd	s2,32(sp)
    80003e98:	ec4e                	sd	s3,24(sp)
    80003e9a:	e852                	sd	s4,16(sp)
    80003e9c:	0080                	addi	s0,sp,64
    80003e9e:	892a                	mv	s2,a0
    80003ea0:	8a2e                	mv	s4,a1
    80003ea2:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003ea4:	4601                	li	a2,0
    80003ea6:	00000097          	auipc	ra,0x0
    80003eaa:	dd8080e7          	jalr	-552(ra) # 80003c7e <dirlookup>
    80003eae:	e93d                	bnez	a0,80003f24 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003eb0:	04c92483          	lw	s1,76(s2)
    80003eb4:	c49d                	beqz	s1,80003ee2 <dirlink+0x54>
    80003eb6:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003eb8:	4741                	li	a4,16
    80003eba:	86a6                	mv	a3,s1
    80003ebc:	fc040613          	addi	a2,s0,-64
    80003ec0:	4581                	li	a1,0
    80003ec2:	854a                	mv	a0,s2
    80003ec4:	00000097          	auipc	ra,0x0
    80003ec8:	b8a080e7          	jalr	-1142(ra) # 80003a4e <readi>
    80003ecc:	47c1                	li	a5,16
    80003ece:	06f51163          	bne	a0,a5,80003f30 <dirlink+0xa2>
    if(de.inum == 0)
    80003ed2:	fc045783          	lhu	a5,-64(s0)
    80003ed6:	c791                	beqz	a5,80003ee2 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ed8:	24c1                	addiw	s1,s1,16
    80003eda:	04c92783          	lw	a5,76(s2)
    80003ede:	fcf4ede3          	bltu	s1,a5,80003eb8 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003ee2:	4639                	li	a2,14
    80003ee4:	85d2                	mv	a1,s4
    80003ee6:	fc240513          	addi	a0,s0,-62
    80003eea:	ffffd097          	auipc	ra,0xffffd
    80003eee:	f10080e7          	jalr	-240(ra) # 80000dfa <strncpy>
  de.inum = inum;
    80003ef2:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ef6:	4741                	li	a4,16
    80003ef8:	86a6                	mv	a3,s1
    80003efa:	fc040613          	addi	a2,s0,-64
    80003efe:	4581                	li	a1,0
    80003f00:	854a                	mv	a0,s2
    80003f02:	00000097          	auipc	ra,0x0
    80003f06:	c44080e7          	jalr	-956(ra) # 80003b46 <writei>
    80003f0a:	1541                	addi	a0,a0,-16
    80003f0c:	00a03533          	snez	a0,a0
    80003f10:	40a00533          	neg	a0,a0
}
    80003f14:	70e2                	ld	ra,56(sp)
    80003f16:	7442                	ld	s0,48(sp)
    80003f18:	74a2                	ld	s1,40(sp)
    80003f1a:	7902                	ld	s2,32(sp)
    80003f1c:	69e2                	ld	s3,24(sp)
    80003f1e:	6a42                	ld	s4,16(sp)
    80003f20:	6121                	addi	sp,sp,64
    80003f22:	8082                	ret
    iput(ip);
    80003f24:	00000097          	auipc	ra,0x0
    80003f28:	a30080e7          	jalr	-1488(ra) # 80003954 <iput>
    return -1;
    80003f2c:	557d                	li	a0,-1
    80003f2e:	b7dd                	j	80003f14 <dirlink+0x86>
      panic("dirlink read");
    80003f30:	00004517          	auipc	a0,0x4
    80003f34:	7a850513          	addi	a0,a0,1960 # 800086d8 <syscalls+0x1d8>
    80003f38:	ffffc097          	auipc	ra,0xffffc
    80003f3c:	60c080e7          	jalr	1548(ra) # 80000544 <panic>

0000000080003f40 <namei>:

struct inode*
namei(char *path)
{
    80003f40:	1101                	addi	sp,sp,-32
    80003f42:	ec06                	sd	ra,24(sp)
    80003f44:	e822                	sd	s0,16(sp)
    80003f46:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f48:	fe040613          	addi	a2,s0,-32
    80003f4c:	4581                	li	a1,0
    80003f4e:	00000097          	auipc	ra,0x0
    80003f52:	de0080e7          	jalr	-544(ra) # 80003d2e <namex>
}
    80003f56:	60e2                	ld	ra,24(sp)
    80003f58:	6442                	ld	s0,16(sp)
    80003f5a:	6105                	addi	sp,sp,32
    80003f5c:	8082                	ret

0000000080003f5e <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f5e:	1141                	addi	sp,sp,-16
    80003f60:	e406                	sd	ra,8(sp)
    80003f62:	e022                	sd	s0,0(sp)
    80003f64:	0800                	addi	s0,sp,16
    80003f66:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f68:	4585                	li	a1,1
    80003f6a:	00000097          	auipc	ra,0x0
    80003f6e:	dc4080e7          	jalr	-572(ra) # 80003d2e <namex>
}
    80003f72:	60a2                	ld	ra,8(sp)
    80003f74:	6402                	ld	s0,0(sp)
    80003f76:	0141                	addi	sp,sp,16
    80003f78:	8082                	ret

0000000080003f7a <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f7a:	1101                	addi	sp,sp,-32
    80003f7c:	ec06                	sd	ra,24(sp)
    80003f7e:	e822                	sd	s0,16(sp)
    80003f80:	e426                	sd	s1,8(sp)
    80003f82:	e04a                	sd	s2,0(sp)
    80003f84:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f86:	00029917          	auipc	s2,0x29
    80003f8a:	01a90913          	addi	s2,s2,26 # 8002cfa0 <log>
    80003f8e:	01892583          	lw	a1,24(s2)
    80003f92:	02892503          	lw	a0,40(s2)
    80003f96:	fffff097          	auipc	ra,0xfffff
    80003f9a:	fea080e7          	jalr	-22(ra) # 80002f80 <bread>
    80003f9e:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003fa0:	02c92683          	lw	a3,44(s2)
    80003fa4:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003fa6:	02d05763          	blez	a3,80003fd4 <write_head+0x5a>
    80003faa:	00029797          	auipc	a5,0x29
    80003fae:	02678793          	addi	a5,a5,38 # 8002cfd0 <log+0x30>
    80003fb2:	05c50713          	addi	a4,a0,92
    80003fb6:	36fd                	addiw	a3,a3,-1
    80003fb8:	1682                	slli	a3,a3,0x20
    80003fba:	9281                	srli	a3,a3,0x20
    80003fbc:	068a                	slli	a3,a3,0x2
    80003fbe:	00029617          	auipc	a2,0x29
    80003fc2:	01660613          	addi	a2,a2,22 # 8002cfd4 <log+0x34>
    80003fc6:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003fc8:	4390                	lw	a2,0(a5)
    80003fca:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003fcc:	0791                	addi	a5,a5,4
    80003fce:	0711                	addi	a4,a4,4
    80003fd0:	fed79ce3          	bne	a5,a3,80003fc8 <write_head+0x4e>
  }
  bwrite(buf);
    80003fd4:	8526                	mv	a0,s1
    80003fd6:	fffff097          	auipc	ra,0xfffff
    80003fda:	09c080e7          	jalr	156(ra) # 80003072 <bwrite>
  brelse(buf);
    80003fde:	8526                	mv	a0,s1
    80003fe0:	fffff097          	auipc	ra,0xfffff
    80003fe4:	0d0080e7          	jalr	208(ra) # 800030b0 <brelse>
}
    80003fe8:	60e2                	ld	ra,24(sp)
    80003fea:	6442                	ld	s0,16(sp)
    80003fec:	64a2                	ld	s1,8(sp)
    80003fee:	6902                	ld	s2,0(sp)
    80003ff0:	6105                	addi	sp,sp,32
    80003ff2:	8082                	ret

0000000080003ff4 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003ff4:	00029797          	auipc	a5,0x29
    80003ff8:	fd87a783          	lw	a5,-40(a5) # 8002cfcc <log+0x2c>
    80003ffc:	0af05d63          	blez	a5,800040b6 <install_trans+0xc2>
{
    80004000:	7139                	addi	sp,sp,-64
    80004002:	fc06                	sd	ra,56(sp)
    80004004:	f822                	sd	s0,48(sp)
    80004006:	f426                	sd	s1,40(sp)
    80004008:	f04a                	sd	s2,32(sp)
    8000400a:	ec4e                	sd	s3,24(sp)
    8000400c:	e852                	sd	s4,16(sp)
    8000400e:	e456                	sd	s5,8(sp)
    80004010:	e05a                	sd	s6,0(sp)
    80004012:	0080                	addi	s0,sp,64
    80004014:	8b2a                	mv	s6,a0
    80004016:	00029a97          	auipc	s5,0x29
    8000401a:	fbaa8a93          	addi	s5,s5,-70 # 8002cfd0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000401e:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004020:	00029997          	auipc	s3,0x29
    80004024:	f8098993          	addi	s3,s3,-128 # 8002cfa0 <log>
    80004028:	a035                	j	80004054 <install_trans+0x60>
      bunpin(dbuf);
    8000402a:	8526                	mv	a0,s1
    8000402c:	fffff097          	auipc	ra,0xfffff
    80004030:	15e080e7          	jalr	350(ra) # 8000318a <bunpin>
    brelse(lbuf);
    80004034:	854a                	mv	a0,s2
    80004036:	fffff097          	auipc	ra,0xfffff
    8000403a:	07a080e7          	jalr	122(ra) # 800030b0 <brelse>
    brelse(dbuf);
    8000403e:	8526                	mv	a0,s1
    80004040:	fffff097          	auipc	ra,0xfffff
    80004044:	070080e7          	jalr	112(ra) # 800030b0 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004048:	2a05                	addiw	s4,s4,1
    8000404a:	0a91                	addi	s5,s5,4
    8000404c:	02c9a783          	lw	a5,44(s3)
    80004050:	04fa5963          	bge	s4,a5,800040a2 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004054:	0189a583          	lw	a1,24(s3)
    80004058:	014585bb          	addw	a1,a1,s4
    8000405c:	2585                	addiw	a1,a1,1
    8000405e:	0289a503          	lw	a0,40(s3)
    80004062:	fffff097          	auipc	ra,0xfffff
    80004066:	f1e080e7          	jalr	-226(ra) # 80002f80 <bread>
    8000406a:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000406c:	000aa583          	lw	a1,0(s5)
    80004070:	0289a503          	lw	a0,40(s3)
    80004074:	fffff097          	auipc	ra,0xfffff
    80004078:	f0c080e7          	jalr	-244(ra) # 80002f80 <bread>
    8000407c:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000407e:	40000613          	li	a2,1024
    80004082:	05890593          	addi	a1,s2,88
    80004086:	05850513          	addi	a0,a0,88
    8000408a:	ffffd097          	auipc	ra,0xffffd
    8000408e:	cbc080e7          	jalr	-836(ra) # 80000d46 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004092:	8526                	mv	a0,s1
    80004094:	fffff097          	auipc	ra,0xfffff
    80004098:	fde080e7          	jalr	-34(ra) # 80003072 <bwrite>
    if(recovering == 0)
    8000409c:	f80b1ce3          	bnez	s6,80004034 <install_trans+0x40>
    800040a0:	b769                	j	8000402a <install_trans+0x36>
}
    800040a2:	70e2                	ld	ra,56(sp)
    800040a4:	7442                	ld	s0,48(sp)
    800040a6:	74a2                	ld	s1,40(sp)
    800040a8:	7902                	ld	s2,32(sp)
    800040aa:	69e2                	ld	s3,24(sp)
    800040ac:	6a42                	ld	s4,16(sp)
    800040ae:	6aa2                	ld	s5,8(sp)
    800040b0:	6b02                	ld	s6,0(sp)
    800040b2:	6121                	addi	sp,sp,64
    800040b4:	8082                	ret
    800040b6:	8082                	ret

00000000800040b8 <initlog>:
{
    800040b8:	7179                	addi	sp,sp,-48
    800040ba:	f406                	sd	ra,40(sp)
    800040bc:	f022                	sd	s0,32(sp)
    800040be:	ec26                	sd	s1,24(sp)
    800040c0:	e84a                	sd	s2,16(sp)
    800040c2:	e44e                	sd	s3,8(sp)
    800040c4:	1800                	addi	s0,sp,48
    800040c6:	892a                	mv	s2,a0
    800040c8:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800040ca:	00029497          	auipc	s1,0x29
    800040ce:	ed648493          	addi	s1,s1,-298 # 8002cfa0 <log>
    800040d2:	00004597          	auipc	a1,0x4
    800040d6:	61658593          	addi	a1,a1,1558 # 800086e8 <syscalls+0x1e8>
    800040da:	8526                	mv	a0,s1
    800040dc:	ffffd097          	auipc	ra,0xffffd
    800040e0:	a7e080e7          	jalr	-1410(ra) # 80000b5a <initlock>
  log.start = sb->logstart;
    800040e4:	0149a583          	lw	a1,20(s3)
    800040e8:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800040ea:	0109a783          	lw	a5,16(s3)
    800040ee:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800040f0:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800040f4:	854a                	mv	a0,s2
    800040f6:	fffff097          	auipc	ra,0xfffff
    800040fa:	e8a080e7          	jalr	-374(ra) # 80002f80 <bread>
  log.lh.n = lh->n;
    800040fe:	4d3c                	lw	a5,88(a0)
    80004100:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004102:	02f05563          	blez	a5,8000412c <initlog+0x74>
    80004106:	05c50713          	addi	a4,a0,92
    8000410a:	00029697          	auipc	a3,0x29
    8000410e:	ec668693          	addi	a3,a3,-314 # 8002cfd0 <log+0x30>
    80004112:	37fd                	addiw	a5,a5,-1
    80004114:	1782                	slli	a5,a5,0x20
    80004116:	9381                	srli	a5,a5,0x20
    80004118:	078a                	slli	a5,a5,0x2
    8000411a:	06050613          	addi	a2,a0,96
    8000411e:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004120:	4310                	lw	a2,0(a4)
    80004122:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004124:	0711                	addi	a4,a4,4
    80004126:	0691                	addi	a3,a3,4
    80004128:	fef71ce3          	bne	a4,a5,80004120 <initlog+0x68>
  brelse(buf);
    8000412c:	fffff097          	auipc	ra,0xfffff
    80004130:	f84080e7          	jalr	-124(ra) # 800030b0 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004134:	4505                	li	a0,1
    80004136:	00000097          	auipc	ra,0x0
    8000413a:	ebe080e7          	jalr	-322(ra) # 80003ff4 <install_trans>
  log.lh.n = 0;
    8000413e:	00029797          	auipc	a5,0x29
    80004142:	e807a723          	sw	zero,-370(a5) # 8002cfcc <log+0x2c>
  write_head(); // clear the log
    80004146:	00000097          	auipc	ra,0x0
    8000414a:	e34080e7          	jalr	-460(ra) # 80003f7a <write_head>
}
    8000414e:	70a2                	ld	ra,40(sp)
    80004150:	7402                	ld	s0,32(sp)
    80004152:	64e2                	ld	s1,24(sp)
    80004154:	6942                	ld	s2,16(sp)
    80004156:	69a2                	ld	s3,8(sp)
    80004158:	6145                	addi	sp,sp,48
    8000415a:	8082                	ret

000000008000415c <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000415c:	1101                	addi	sp,sp,-32
    8000415e:	ec06                	sd	ra,24(sp)
    80004160:	e822                	sd	s0,16(sp)
    80004162:	e426                	sd	s1,8(sp)
    80004164:	e04a                	sd	s2,0(sp)
    80004166:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004168:	00029517          	auipc	a0,0x29
    8000416c:	e3850513          	addi	a0,a0,-456 # 8002cfa0 <log>
    80004170:	ffffd097          	auipc	ra,0xffffd
    80004174:	a7a080e7          	jalr	-1414(ra) # 80000bea <acquire>
  while(1){
    if(log.committing){
    80004178:	00029497          	auipc	s1,0x29
    8000417c:	e2848493          	addi	s1,s1,-472 # 8002cfa0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004180:	4979                	li	s2,30
    80004182:	a039                	j	80004190 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004184:	85a6                	mv	a1,s1
    80004186:	8526                	mv	a0,s1
    80004188:	ffffe097          	auipc	ra,0xffffe
    8000418c:	f64080e7          	jalr	-156(ra) # 800020ec <sleep>
    if(log.committing){
    80004190:	50dc                	lw	a5,36(s1)
    80004192:	fbed                	bnez	a5,80004184 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004194:	509c                	lw	a5,32(s1)
    80004196:	0017871b          	addiw	a4,a5,1
    8000419a:	0007069b          	sext.w	a3,a4
    8000419e:	0027179b          	slliw	a5,a4,0x2
    800041a2:	9fb9                	addw	a5,a5,a4
    800041a4:	0017979b          	slliw	a5,a5,0x1
    800041a8:	54d8                	lw	a4,44(s1)
    800041aa:	9fb9                	addw	a5,a5,a4
    800041ac:	00f95963          	bge	s2,a5,800041be <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800041b0:	85a6                	mv	a1,s1
    800041b2:	8526                	mv	a0,s1
    800041b4:	ffffe097          	auipc	ra,0xffffe
    800041b8:	f38080e7          	jalr	-200(ra) # 800020ec <sleep>
    800041bc:	bfd1                	j	80004190 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800041be:	00029517          	auipc	a0,0x29
    800041c2:	de250513          	addi	a0,a0,-542 # 8002cfa0 <log>
    800041c6:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800041c8:	ffffd097          	auipc	ra,0xffffd
    800041cc:	ad6080e7          	jalr	-1322(ra) # 80000c9e <release>
      break;
    }
  }
}
    800041d0:	60e2                	ld	ra,24(sp)
    800041d2:	6442                	ld	s0,16(sp)
    800041d4:	64a2                	ld	s1,8(sp)
    800041d6:	6902                	ld	s2,0(sp)
    800041d8:	6105                	addi	sp,sp,32
    800041da:	8082                	ret

00000000800041dc <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800041dc:	7139                	addi	sp,sp,-64
    800041de:	fc06                	sd	ra,56(sp)
    800041e0:	f822                	sd	s0,48(sp)
    800041e2:	f426                	sd	s1,40(sp)
    800041e4:	f04a                	sd	s2,32(sp)
    800041e6:	ec4e                	sd	s3,24(sp)
    800041e8:	e852                	sd	s4,16(sp)
    800041ea:	e456                	sd	s5,8(sp)
    800041ec:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800041ee:	00029497          	auipc	s1,0x29
    800041f2:	db248493          	addi	s1,s1,-590 # 8002cfa0 <log>
    800041f6:	8526                	mv	a0,s1
    800041f8:	ffffd097          	auipc	ra,0xffffd
    800041fc:	9f2080e7          	jalr	-1550(ra) # 80000bea <acquire>
  log.outstanding -= 1;
    80004200:	509c                	lw	a5,32(s1)
    80004202:	37fd                	addiw	a5,a5,-1
    80004204:	0007891b          	sext.w	s2,a5
    80004208:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000420a:	50dc                	lw	a5,36(s1)
    8000420c:	efb9                	bnez	a5,8000426a <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000420e:	06091663          	bnez	s2,8000427a <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004212:	00029497          	auipc	s1,0x29
    80004216:	d8e48493          	addi	s1,s1,-626 # 8002cfa0 <log>
    8000421a:	4785                	li	a5,1
    8000421c:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000421e:	8526                	mv	a0,s1
    80004220:	ffffd097          	auipc	ra,0xffffd
    80004224:	a7e080e7          	jalr	-1410(ra) # 80000c9e <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004228:	54dc                	lw	a5,44(s1)
    8000422a:	06f04763          	bgtz	a5,80004298 <end_op+0xbc>
    acquire(&log.lock);
    8000422e:	00029497          	auipc	s1,0x29
    80004232:	d7248493          	addi	s1,s1,-654 # 8002cfa0 <log>
    80004236:	8526                	mv	a0,s1
    80004238:	ffffd097          	auipc	ra,0xffffd
    8000423c:	9b2080e7          	jalr	-1614(ra) # 80000bea <acquire>
    log.committing = 0;
    80004240:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004244:	8526                	mv	a0,s1
    80004246:	ffffe097          	auipc	ra,0xffffe
    8000424a:	f0a080e7          	jalr	-246(ra) # 80002150 <wakeup>
    release(&log.lock);
    8000424e:	8526                	mv	a0,s1
    80004250:	ffffd097          	auipc	ra,0xffffd
    80004254:	a4e080e7          	jalr	-1458(ra) # 80000c9e <release>
}
    80004258:	70e2                	ld	ra,56(sp)
    8000425a:	7442                	ld	s0,48(sp)
    8000425c:	74a2                	ld	s1,40(sp)
    8000425e:	7902                	ld	s2,32(sp)
    80004260:	69e2                	ld	s3,24(sp)
    80004262:	6a42                	ld	s4,16(sp)
    80004264:	6aa2                	ld	s5,8(sp)
    80004266:	6121                	addi	sp,sp,64
    80004268:	8082                	ret
    panic("log.committing");
    8000426a:	00004517          	auipc	a0,0x4
    8000426e:	48650513          	addi	a0,a0,1158 # 800086f0 <syscalls+0x1f0>
    80004272:	ffffc097          	auipc	ra,0xffffc
    80004276:	2d2080e7          	jalr	722(ra) # 80000544 <panic>
    wakeup(&log);
    8000427a:	00029497          	auipc	s1,0x29
    8000427e:	d2648493          	addi	s1,s1,-730 # 8002cfa0 <log>
    80004282:	8526                	mv	a0,s1
    80004284:	ffffe097          	auipc	ra,0xffffe
    80004288:	ecc080e7          	jalr	-308(ra) # 80002150 <wakeup>
  release(&log.lock);
    8000428c:	8526                	mv	a0,s1
    8000428e:	ffffd097          	auipc	ra,0xffffd
    80004292:	a10080e7          	jalr	-1520(ra) # 80000c9e <release>
  if(do_commit){
    80004296:	b7c9                	j	80004258 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004298:	00029a97          	auipc	s5,0x29
    8000429c:	d38a8a93          	addi	s5,s5,-712 # 8002cfd0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800042a0:	00029a17          	auipc	s4,0x29
    800042a4:	d00a0a13          	addi	s4,s4,-768 # 8002cfa0 <log>
    800042a8:	018a2583          	lw	a1,24(s4)
    800042ac:	012585bb          	addw	a1,a1,s2
    800042b0:	2585                	addiw	a1,a1,1
    800042b2:	028a2503          	lw	a0,40(s4)
    800042b6:	fffff097          	auipc	ra,0xfffff
    800042ba:	cca080e7          	jalr	-822(ra) # 80002f80 <bread>
    800042be:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800042c0:	000aa583          	lw	a1,0(s5)
    800042c4:	028a2503          	lw	a0,40(s4)
    800042c8:	fffff097          	auipc	ra,0xfffff
    800042cc:	cb8080e7          	jalr	-840(ra) # 80002f80 <bread>
    800042d0:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800042d2:	40000613          	li	a2,1024
    800042d6:	05850593          	addi	a1,a0,88
    800042da:	05848513          	addi	a0,s1,88
    800042de:	ffffd097          	auipc	ra,0xffffd
    800042e2:	a68080e7          	jalr	-1432(ra) # 80000d46 <memmove>
    bwrite(to);  // write the log
    800042e6:	8526                	mv	a0,s1
    800042e8:	fffff097          	auipc	ra,0xfffff
    800042ec:	d8a080e7          	jalr	-630(ra) # 80003072 <bwrite>
    brelse(from);
    800042f0:	854e                	mv	a0,s3
    800042f2:	fffff097          	auipc	ra,0xfffff
    800042f6:	dbe080e7          	jalr	-578(ra) # 800030b0 <brelse>
    brelse(to);
    800042fa:	8526                	mv	a0,s1
    800042fc:	fffff097          	auipc	ra,0xfffff
    80004300:	db4080e7          	jalr	-588(ra) # 800030b0 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004304:	2905                	addiw	s2,s2,1
    80004306:	0a91                	addi	s5,s5,4
    80004308:	02ca2783          	lw	a5,44(s4)
    8000430c:	f8f94ee3          	blt	s2,a5,800042a8 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004310:	00000097          	auipc	ra,0x0
    80004314:	c6a080e7          	jalr	-918(ra) # 80003f7a <write_head>
    install_trans(0); // Now install writes to home locations
    80004318:	4501                	li	a0,0
    8000431a:	00000097          	auipc	ra,0x0
    8000431e:	cda080e7          	jalr	-806(ra) # 80003ff4 <install_trans>
    log.lh.n = 0;
    80004322:	00029797          	auipc	a5,0x29
    80004326:	ca07a523          	sw	zero,-854(a5) # 8002cfcc <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000432a:	00000097          	auipc	ra,0x0
    8000432e:	c50080e7          	jalr	-944(ra) # 80003f7a <write_head>
    80004332:	bdf5                	j	8000422e <end_op+0x52>

0000000080004334 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004334:	1101                	addi	sp,sp,-32
    80004336:	ec06                	sd	ra,24(sp)
    80004338:	e822                	sd	s0,16(sp)
    8000433a:	e426                	sd	s1,8(sp)
    8000433c:	e04a                	sd	s2,0(sp)
    8000433e:	1000                	addi	s0,sp,32
    80004340:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004342:	00029917          	auipc	s2,0x29
    80004346:	c5e90913          	addi	s2,s2,-930 # 8002cfa0 <log>
    8000434a:	854a                	mv	a0,s2
    8000434c:	ffffd097          	auipc	ra,0xffffd
    80004350:	89e080e7          	jalr	-1890(ra) # 80000bea <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004354:	02c92603          	lw	a2,44(s2)
    80004358:	47f5                	li	a5,29
    8000435a:	06c7c563          	blt	a5,a2,800043c4 <log_write+0x90>
    8000435e:	00029797          	auipc	a5,0x29
    80004362:	c5e7a783          	lw	a5,-930(a5) # 8002cfbc <log+0x1c>
    80004366:	37fd                	addiw	a5,a5,-1
    80004368:	04f65e63          	bge	a2,a5,800043c4 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000436c:	00029797          	auipc	a5,0x29
    80004370:	c547a783          	lw	a5,-940(a5) # 8002cfc0 <log+0x20>
    80004374:	06f05063          	blez	a5,800043d4 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004378:	4781                	li	a5,0
    8000437a:	06c05563          	blez	a2,800043e4 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000437e:	44cc                	lw	a1,12(s1)
    80004380:	00029717          	auipc	a4,0x29
    80004384:	c5070713          	addi	a4,a4,-944 # 8002cfd0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004388:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000438a:	4314                	lw	a3,0(a4)
    8000438c:	04b68c63          	beq	a3,a1,800043e4 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004390:	2785                	addiw	a5,a5,1
    80004392:	0711                	addi	a4,a4,4
    80004394:	fef61be3          	bne	a2,a5,8000438a <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004398:	0621                	addi	a2,a2,8
    8000439a:	060a                	slli	a2,a2,0x2
    8000439c:	00029797          	auipc	a5,0x29
    800043a0:	c0478793          	addi	a5,a5,-1020 # 8002cfa0 <log>
    800043a4:	963e                	add	a2,a2,a5
    800043a6:	44dc                	lw	a5,12(s1)
    800043a8:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800043aa:	8526                	mv	a0,s1
    800043ac:	fffff097          	auipc	ra,0xfffff
    800043b0:	da2080e7          	jalr	-606(ra) # 8000314e <bpin>
    log.lh.n++;
    800043b4:	00029717          	auipc	a4,0x29
    800043b8:	bec70713          	addi	a4,a4,-1044 # 8002cfa0 <log>
    800043bc:	575c                	lw	a5,44(a4)
    800043be:	2785                	addiw	a5,a5,1
    800043c0:	d75c                	sw	a5,44(a4)
    800043c2:	a835                	j	800043fe <log_write+0xca>
    panic("too big a transaction");
    800043c4:	00004517          	auipc	a0,0x4
    800043c8:	33c50513          	addi	a0,a0,828 # 80008700 <syscalls+0x200>
    800043cc:	ffffc097          	auipc	ra,0xffffc
    800043d0:	178080e7          	jalr	376(ra) # 80000544 <panic>
    panic("log_write outside of trans");
    800043d4:	00004517          	auipc	a0,0x4
    800043d8:	34450513          	addi	a0,a0,836 # 80008718 <syscalls+0x218>
    800043dc:	ffffc097          	auipc	ra,0xffffc
    800043e0:	168080e7          	jalr	360(ra) # 80000544 <panic>
  log.lh.block[i] = b->blockno;
    800043e4:	00878713          	addi	a4,a5,8
    800043e8:	00271693          	slli	a3,a4,0x2
    800043ec:	00029717          	auipc	a4,0x29
    800043f0:	bb470713          	addi	a4,a4,-1100 # 8002cfa0 <log>
    800043f4:	9736                	add	a4,a4,a3
    800043f6:	44d4                	lw	a3,12(s1)
    800043f8:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800043fa:	faf608e3          	beq	a2,a5,800043aa <log_write+0x76>
  }
  release(&log.lock);
    800043fe:	00029517          	auipc	a0,0x29
    80004402:	ba250513          	addi	a0,a0,-1118 # 8002cfa0 <log>
    80004406:	ffffd097          	auipc	ra,0xffffd
    8000440a:	898080e7          	jalr	-1896(ra) # 80000c9e <release>
}
    8000440e:	60e2                	ld	ra,24(sp)
    80004410:	6442                	ld	s0,16(sp)
    80004412:	64a2                	ld	s1,8(sp)
    80004414:	6902                	ld	s2,0(sp)
    80004416:	6105                	addi	sp,sp,32
    80004418:	8082                	ret

000000008000441a <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000441a:	1101                	addi	sp,sp,-32
    8000441c:	ec06                	sd	ra,24(sp)
    8000441e:	e822                	sd	s0,16(sp)
    80004420:	e426                	sd	s1,8(sp)
    80004422:	e04a                	sd	s2,0(sp)
    80004424:	1000                	addi	s0,sp,32
    80004426:	84aa                	mv	s1,a0
    80004428:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000442a:	00004597          	auipc	a1,0x4
    8000442e:	30e58593          	addi	a1,a1,782 # 80008738 <syscalls+0x238>
    80004432:	0521                	addi	a0,a0,8
    80004434:	ffffc097          	auipc	ra,0xffffc
    80004438:	726080e7          	jalr	1830(ra) # 80000b5a <initlock>
  lk->name = name;
    8000443c:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004440:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004444:	0204a423          	sw	zero,40(s1)
}
    80004448:	60e2                	ld	ra,24(sp)
    8000444a:	6442                	ld	s0,16(sp)
    8000444c:	64a2                	ld	s1,8(sp)
    8000444e:	6902                	ld	s2,0(sp)
    80004450:	6105                	addi	sp,sp,32
    80004452:	8082                	ret

0000000080004454 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004454:	1101                	addi	sp,sp,-32
    80004456:	ec06                	sd	ra,24(sp)
    80004458:	e822                	sd	s0,16(sp)
    8000445a:	e426                	sd	s1,8(sp)
    8000445c:	e04a                	sd	s2,0(sp)
    8000445e:	1000                	addi	s0,sp,32
    80004460:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004462:	00850913          	addi	s2,a0,8
    80004466:	854a                	mv	a0,s2
    80004468:	ffffc097          	auipc	ra,0xffffc
    8000446c:	782080e7          	jalr	1922(ra) # 80000bea <acquire>
  while (lk->locked) {
    80004470:	409c                	lw	a5,0(s1)
    80004472:	cb89                	beqz	a5,80004484 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004474:	85ca                	mv	a1,s2
    80004476:	8526                	mv	a0,s1
    80004478:	ffffe097          	auipc	ra,0xffffe
    8000447c:	c74080e7          	jalr	-908(ra) # 800020ec <sleep>
  while (lk->locked) {
    80004480:	409c                	lw	a5,0(s1)
    80004482:	fbed                	bnez	a5,80004474 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004484:	4785                	li	a5,1
    80004486:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004488:	ffffd097          	auipc	ra,0xffffd
    8000448c:	53e080e7          	jalr	1342(ra) # 800019c6 <myproc>
    80004490:	591c                	lw	a5,48(a0)
    80004492:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004494:	854a                	mv	a0,s2
    80004496:	ffffd097          	auipc	ra,0xffffd
    8000449a:	808080e7          	jalr	-2040(ra) # 80000c9e <release>
}
    8000449e:	60e2                	ld	ra,24(sp)
    800044a0:	6442                	ld	s0,16(sp)
    800044a2:	64a2                	ld	s1,8(sp)
    800044a4:	6902                	ld	s2,0(sp)
    800044a6:	6105                	addi	sp,sp,32
    800044a8:	8082                	ret

00000000800044aa <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800044aa:	1101                	addi	sp,sp,-32
    800044ac:	ec06                	sd	ra,24(sp)
    800044ae:	e822                	sd	s0,16(sp)
    800044b0:	e426                	sd	s1,8(sp)
    800044b2:	e04a                	sd	s2,0(sp)
    800044b4:	1000                	addi	s0,sp,32
    800044b6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044b8:	00850913          	addi	s2,a0,8
    800044bc:	854a                	mv	a0,s2
    800044be:	ffffc097          	auipc	ra,0xffffc
    800044c2:	72c080e7          	jalr	1836(ra) # 80000bea <acquire>
  lk->locked = 0;
    800044c6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044ca:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800044ce:	8526                	mv	a0,s1
    800044d0:	ffffe097          	auipc	ra,0xffffe
    800044d4:	c80080e7          	jalr	-896(ra) # 80002150 <wakeup>
  release(&lk->lk);
    800044d8:	854a                	mv	a0,s2
    800044da:	ffffc097          	auipc	ra,0xffffc
    800044de:	7c4080e7          	jalr	1988(ra) # 80000c9e <release>
}
    800044e2:	60e2                	ld	ra,24(sp)
    800044e4:	6442                	ld	s0,16(sp)
    800044e6:	64a2                	ld	s1,8(sp)
    800044e8:	6902                	ld	s2,0(sp)
    800044ea:	6105                	addi	sp,sp,32
    800044ec:	8082                	ret

00000000800044ee <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800044ee:	7179                	addi	sp,sp,-48
    800044f0:	f406                	sd	ra,40(sp)
    800044f2:	f022                	sd	s0,32(sp)
    800044f4:	ec26                	sd	s1,24(sp)
    800044f6:	e84a                	sd	s2,16(sp)
    800044f8:	e44e                	sd	s3,8(sp)
    800044fa:	1800                	addi	s0,sp,48
    800044fc:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800044fe:	00850913          	addi	s2,a0,8
    80004502:	854a                	mv	a0,s2
    80004504:	ffffc097          	auipc	ra,0xffffc
    80004508:	6e6080e7          	jalr	1766(ra) # 80000bea <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000450c:	409c                	lw	a5,0(s1)
    8000450e:	ef99                	bnez	a5,8000452c <holdingsleep+0x3e>
    80004510:	4481                	li	s1,0
  release(&lk->lk);
    80004512:	854a                	mv	a0,s2
    80004514:	ffffc097          	auipc	ra,0xffffc
    80004518:	78a080e7          	jalr	1930(ra) # 80000c9e <release>
  return r;
}
    8000451c:	8526                	mv	a0,s1
    8000451e:	70a2                	ld	ra,40(sp)
    80004520:	7402                	ld	s0,32(sp)
    80004522:	64e2                	ld	s1,24(sp)
    80004524:	6942                	ld	s2,16(sp)
    80004526:	69a2                	ld	s3,8(sp)
    80004528:	6145                	addi	sp,sp,48
    8000452a:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000452c:	0284a983          	lw	s3,40(s1)
    80004530:	ffffd097          	auipc	ra,0xffffd
    80004534:	496080e7          	jalr	1174(ra) # 800019c6 <myproc>
    80004538:	5904                	lw	s1,48(a0)
    8000453a:	413484b3          	sub	s1,s1,s3
    8000453e:	0014b493          	seqz	s1,s1
    80004542:	bfc1                	j	80004512 <holdingsleep+0x24>

0000000080004544 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004544:	1141                	addi	sp,sp,-16
    80004546:	e406                	sd	ra,8(sp)
    80004548:	e022                	sd	s0,0(sp)
    8000454a:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000454c:	00004597          	auipc	a1,0x4
    80004550:	1fc58593          	addi	a1,a1,508 # 80008748 <syscalls+0x248>
    80004554:	00029517          	auipc	a0,0x29
    80004558:	b9450513          	addi	a0,a0,-1132 # 8002d0e8 <ftable>
    8000455c:	ffffc097          	auipc	ra,0xffffc
    80004560:	5fe080e7          	jalr	1534(ra) # 80000b5a <initlock>
}
    80004564:	60a2                	ld	ra,8(sp)
    80004566:	6402                	ld	s0,0(sp)
    80004568:	0141                	addi	sp,sp,16
    8000456a:	8082                	ret

000000008000456c <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000456c:	1101                	addi	sp,sp,-32
    8000456e:	ec06                	sd	ra,24(sp)
    80004570:	e822                	sd	s0,16(sp)
    80004572:	e426                	sd	s1,8(sp)
    80004574:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004576:	00029517          	auipc	a0,0x29
    8000457a:	b7250513          	addi	a0,a0,-1166 # 8002d0e8 <ftable>
    8000457e:	ffffc097          	auipc	ra,0xffffc
    80004582:	66c080e7          	jalr	1644(ra) # 80000bea <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004586:	00029497          	auipc	s1,0x29
    8000458a:	b7a48493          	addi	s1,s1,-1158 # 8002d100 <ftable+0x18>
    8000458e:	0002a717          	auipc	a4,0x2a
    80004592:	b1270713          	addi	a4,a4,-1262 # 8002e0a0 <disk>
    if(f->ref == 0){
    80004596:	40dc                	lw	a5,4(s1)
    80004598:	cf99                	beqz	a5,800045b6 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000459a:	02848493          	addi	s1,s1,40
    8000459e:	fee49ce3          	bne	s1,a4,80004596 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800045a2:	00029517          	auipc	a0,0x29
    800045a6:	b4650513          	addi	a0,a0,-1210 # 8002d0e8 <ftable>
    800045aa:	ffffc097          	auipc	ra,0xffffc
    800045ae:	6f4080e7          	jalr	1780(ra) # 80000c9e <release>
  return 0;
    800045b2:	4481                	li	s1,0
    800045b4:	a819                	j	800045ca <filealloc+0x5e>
      f->ref = 1;
    800045b6:	4785                	li	a5,1
    800045b8:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800045ba:	00029517          	auipc	a0,0x29
    800045be:	b2e50513          	addi	a0,a0,-1234 # 8002d0e8 <ftable>
    800045c2:	ffffc097          	auipc	ra,0xffffc
    800045c6:	6dc080e7          	jalr	1756(ra) # 80000c9e <release>
}
    800045ca:	8526                	mv	a0,s1
    800045cc:	60e2                	ld	ra,24(sp)
    800045ce:	6442                	ld	s0,16(sp)
    800045d0:	64a2                	ld	s1,8(sp)
    800045d2:	6105                	addi	sp,sp,32
    800045d4:	8082                	ret

00000000800045d6 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800045d6:	1101                	addi	sp,sp,-32
    800045d8:	ec06                	sd	ra,24(sp)
    800045da:	e822                	sd	s0,16(sp)
    800045dc:	e426                	sd	s1,8(sp)
    800045de:	1000                	addi	s0,sp,32
    800045e0:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800045e2:	00029517          	auipc	a0,0x29
    800045e6:	b0650513          	addi	a0,a0,-1274 # 8002d0e8 <ftable>
    800045ea:	ffffc097          	auipc	ra,0xffffc
    800045ee:	600080e7          	jalr	1536(ra) # 80000bea <acquire>
  if(f->ref < 1)
    800045f2:	40dc                	lw	a5,4(s1)
    800045f4:	02f05263          	blez	a5,80004618 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800045f8:	2785                	addiw	a5,a5,1
    800045fa:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800045fc:	00029517          	auipc	a0,0x29
    80004600:	aec50513          	addi	a0,a0,-1300 # 8002d0e8 <ftable>
    80004604:	ffffc097          	auipc	ra,0xffffc
    80004608:	69a080e7          	jalr	1690(ra) # 80000c9e <release>
  return f;
}
    8000460c:	8526                	mv	a0,s1
    8000460e:	60e2                	ld	ra,24(sp)
    80004610:	6442                	ld	s0,16(sp)
    80004612:	64a2                	ld	s1,8(sp)
    80004614:	6105                	addi	sp,sp,32
    80004616:	8082                	ret
    panic("filedup");
    80004618:	00004517          	auipc	a0,0x4
    8000461c:	13850513          	addi	a0,a0,312 # 80008750 <syscalls+0x250>
    80004620:	ffffc097          	auipc	ra,0xffffc
    80004624:	f24080e7          	jalr	-220(ra) # 80000544 <panic>

0000000080004628 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004628:	7139                	addi	sp,sp,-64
    8000462a:	fc06                	sd	ra,56(sp)
    8000462c:	f822                	sd	s0,48(sp)
    8000462e:	f426                	sd	s1,40(sp)
    80004630:	f04a                	sd	s2,32(sp)
    80004632:	ec4e                	sd	s3,24(sp)
    80004634:	e852                	sd	s4,16(sp)
    80004636:	e456                	sd	s5,8(sp)
    80004638:	0080                	addi	s0,sp,64
    8000463a:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000463c:	00029517          	auipc	a0,0x29
    80004640:	aac50513          	addi	a0,a0,-1364 # 8002d0e8 <ftable>
    80004644:	ffffc097          	auipc	ra,0xffffc
    80004648:	5a6080e7          	jalr	1446(ra) # 80000bea <acquire>
  if(f->ref < 1)
    8000464c:	40dc                	lw	a5,4(s1)
    8000464e:	06f05163          	blez	a5,800046b0 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004652:	37fd                	addiw	a5,a5,-1
    80004654:	0007871b          	sext.w	a4,a5
    80004658:	c0dc                	sw	a5,4(s1)
    8000465a:	06e04363          	bgtz	a4,800046c0 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000465e:	0004a903          	lw	s2,0(s1)
    80004662:	0094ca83          	lbu	s5,9(s1)
    80004666:	0104ba03          	ld	s4,16(s1)
    8000466a:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000466e:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004672:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004676:	00029517          	auipc	a0,0x29
    8000467a:	a7250513          	addi	a0,a0,-1422 # 8002d0e8 <ftable>
    8000467e:	ffffc097          	auipc	ra,0xffffc
    80004682:	620080e7          	jalr	1568(ra) # 80000c9e <release>

  if(ff.type == FD_PIPE){
    80004686:	4785                	li	a5,1
    80004688:	04f90d63          	beq	s2,a5,800046e2 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000468c:	3979                	addiw	s2,s2,-2
    8000468e:	4785                	li	a5,1
    80004690:	0527e063          	bltu	a5,s2,800046d0 <fileclose+0xa8>
    begin_op();
    80004694:	00000097          	auipc	ra,0x0
    80004698:	ac8080e7          	jalr	-1336(ra) # 8000415c <begin_op>
    iput(ff.ip);
    8000469c:	854e                	mv	a0,s3
    8000469e:	fffff097          	auipc	ra,0xfffff
    800046a2:	2b6080e7          	jalr	694(ra) # 80003954 <iput>
    end_op();
    800046a6:	00000097          	auipc	ra,0x0
    800046aa:	b36080e7          	jalr	-1226(ra) # 800041dc <end_op>
    800046ae:	a00d                	j	800046d0 <fileclose+0xa8>
    panic("fileclose");
    800046b0:	00004517          	auipc	a0,0x4
    800046b4:	0a850513          	addi	a0,a0,168 # 80008758 <syscalls+0x258>
    800046b8:	ffffc097          	auipc	ra,0xffffc
    800046bc:	e8c080e7          	jalr	-372(ra) # 80000544 <panic>
    release(&ftable.lock);
    800046c0:	00029517          	auipc	a0,0x29
    800046c4:	a2850513          	addi	a0,a0,-1496 # 8002d0e8 <ftable>
    800046c8:	ffffc097          	auipc	ra,0xffffc
    800046cc:	5d6080e7          	jalr	1494(ra) # 80000c9e <release>
  }
}
    800046d0:	70e2                	ld	ra,56(sp)
    800046d2:	7442                	ld	s0,48(sp)
    800046d4:	74a2                	ld	s1,40(sp)
    800046d6:	7902                	ld	s2,32(sp)
    800046d8:	69e2                	ld	s3,24(sp)
    800046da:	6a42                	ld	s4,16(sp)
    800046dc:	6aa2                	ld	s5,8(sp)
    800046de:	6121                	addi	sp,sp,64
    800046e0:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800046e2:	85d6                	mv	a1,s5
    800046e4:	8552                	mv	a0,s4
    800046e6:	00000097          	auipc	ra,0x0
    800046ea:	34c080e7          	jalr	844(ra) # 80004a32 <pipeclose>
    800046ee:	b7cd                	j	800046d0 <fileclose+0xa8>

00000000800046f0 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800046f0:	715d                	addi	sp,sp,-80
    800046f2:	e486                	sd	ra,72(sp)
    800046f4:	e0a2                	sd	s0,64(sp)
    800046f6:	fc26                	sd	s1,56(sp)
    800046f8:	f84a                	sd	s2,48(sp)
    800046fa:	f44e                	sd	s3,40(sp)
    800046fc:	0880                	addi	s0,sp,80
    800046fe:	84aa                	mv	s1,a0
    80004700:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004702:	ffffd097          	auipc	ra,0xffffd
    80004706:	2c4080e7          	jalr	708(ra) # 800019c6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    8000470a:	409c                	lw	a5,0(s1)
    8000470c:	37f9                	addiw	a5,a5,-2
    8000470e:	4705                	li	a4,1
    80004710:	04f76763          	bltu	a4,a5,8000475e <filestat+0x6e>
    80004714:	892a                	mv	s2,a0
    ilock(f->ip);
    80004716:	6c88                	ld	a0,24(s1)
    80004718:	fffff097          	auipc	ra,0xfffff
    8000471c:	082080e7          	jalr	130(ra) # 8000379a <ilock>
    stati(f->ip, &st);
    80004720:	fb840593          	addi	a1,s0,-72
    80004724:	6c88                	ld	a0,24(s1)
    80004726:	fffff097          	auipc	ra,0xfffff
    8000472a:	2fe080e7          	jalr	766(ra) # 80003a24 <stati>
    iunlock(f->ip);
    8000472e:	6c88                	ld	a0,24(s1)
    80004730:	fffff097          	auipc	ra,0xfffff
    80004734:	12c080e7          	jalr	300(ra) # 8000385c <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004738:	46e1                	li	a3,24
    8000473a:	fb840613          	addi	a2,s0,-72
    8000473e:	85ce                	mv	a1,s3
    80004740:	05093503          	ld	a0,80(s2)
    80004744:	ffffd097          	auipc	ra,0xffffd
    80004748:	f40080e7          	jalr	-192(ra) # 80001684 <copyout>
    8000474c:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004750:	60a6                	ld	ra,72(sp)
    80004752:	6406                	ld	s0,64(sp)
    80004754:	74e2                	ld	s1,56(sp)
    80004756:	7942                	ld	s2,48(sp)
    80004758:	79a2                	ld	s3,40(sp)
    8000475a:	6161                	addi	sp,sp,80
    8000475c:	8082                	ret
  return -1;
    8000475e:	557d                	li	a0,-1
    80004760:	bfc5                	j	80004750 <filestat+0x60>

0000000080004762 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004762:	7179                	addi	sp,sp,-48
    80004764:	f406                	sd	ra,40(sp)
    80004766:	f022                	sd	s0,32(sp)
    80004768:	ec26                	sd	s1,24(sp)
    8000476a:	e84a                	sd	s2,16(sp)
    8000476c:	e44e                	sd	s3,8(sp)
    8000476e:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004770:	00854783          	lbu	a5,8(a0)
    80004774:	c3d5                	beqz	a5,80004818 <fileread+0xb6>
    80004776:	84aa                	mv	s1,a0
    80004778:	89ae                	mv	s3,a1
    8000477a:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000477c:	411c                	lw	a5,0(a0)
    8000477e:	4705                	li	a4,1
    80004780:	04e78963          	beq	a5,a4,800047d2 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004784:	470d                	li	a4,3
    80004786:	04e78d63          	beq	a5,a4,800047e0 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000478a:	4709                	li	a4,2
    8000478c:	06e79e63          	bne	a5,a4,80004808 <fileread+0xa6>
    ilock(f->ip);
    80004790:	6d08                	ld	a0,24(a0)
    80004792:	fffff097          	auipc	ra,0xfffff
    80004796:	008080e7          	jalr	8(ra) # 8000379a <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000479a:	874a                	mv	a4,s2
    8000479c:	5094                	lw	a3,32(s1)
    8000479e:	864e                	mv	a2,s3
    800047a0:	4585                	li	a1,1
    800047a2:	6c88                	ld	a0,24(s1)
    800047a4:	fffff097          	auipc	ra,0xfffff
    800047a8:	2aa080e7          	jalr	682(ra) # 80003a4e <readi>
    800047ac:	892a                	mv	s2,a0
    800047ae:	00a05563          	blez	a0,800047b8 <fileread+0x56>
      f->off += r;
    800047b2:	509c                	lw	a5,32(s1)
    800047b4:	9fa9                	addw	a5,a5,a0
    800047b6:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800047b8:	6c88                	ld	a0,24(s1)
    800047ba:	fffff097          	auipc	ra,0xfffff
    800047be:	0a2080e7          	jalr	162(ra) # 8000385c <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800047c2:	854a                	mv	a0,s2
    800047c4:	70a2                	ld	ra,40(sp)
    800047c6:	7402                	ld	s0,32(sp)
    800047c8:	64e2                	ld	s1,24(sp)
    800047ca:	6942                	ld	s2,16(sp)
    800047cc:	69a2                	ld	s3,8(sp)
    800047ce:	6145                	addi	sp,sp,48
    800047d0:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800047d2:	6908                	ld	a0,16(a0)
    800047d4:	00000097          	auipc	ra,0x0
    800047d8:	3ce080e7          	jalr	974(ra) # 80004ba2 <piperead>
    800047dc:	892a                	mv	s2,a0
    800047de:	b7d5                	j	800047c2 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800047e0:	02451783          	lh	a5,36(a0)
    800047e4:	03079693          	slli	a3,a5,0x30
    800047e8:	92c1                	srli	a3,a3,0x30
    800047ea:	4725                	li	a4,9
    800047ec:	02d76863          	bltu	a4,a3,8000481c <fileread+0xba>
    800047f0:	0792                	slli	a5,a5,0x4
    800047f2:	00029717          	auipc	a4,0x29
    800047f6:	85670713          	addi	a4,a4,-1962 # 8002d048 <devsw>
    800047fa:	97ba                	add	a5,a5,a4
    800047fc:	639c                	ld	a5,0(a5)
    800047fe:	c38d                	beqz	a5,80004820 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004800:	4505                	li	a0,1
    80004802:	9782                	jalr	a5
    80004804:	892a                	mv	s2,a0
    80004806:	bf75                	j	800047c2 <fileread+0x60>
    panic("fileread");
    80004808:	00004517          	auipc	a0,0x4
    8000480c:	f6050513          	addi	a0,a0,-160 # 80008768 <syscalls+0x268>
    80004810:	ffffc097          	auipc	ra,0xffffc
    80004814:	d34080e7          	jalr	-716(ra) # 80000544 <panic>
    return -1;
    80004818:	597d                	li	s2,-1
    8000481a:	b765                	j	800047c2 <fileread+0x60>
      return -1;
    8000481c:	597d                	li	s2,-1
    8000481e:	b755                	j	800047c2 <fileread+0x60>
    80004820:	597d                	li	s2,-1
    80004822:	b745                	j	800047c2 <fileread+0x60>

0000000080004824 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004824:	715d                	addi	sp,sp,-80
    80004826:	e486                	sd	ra,72(sp)
    80004828:	e0a2                	sd	s0,64(sp)
    8000482a:	fc26                	sd	s1,56(sp)
    8000482c:	f84a                	sd	s2,48(sp)
    8000482e:	f44e                	sd	s3,40(sp)
    80004830:	f052                	sd	s4,32(sp)
    80004832:	ec56                	sd	s5,24(sp)
    80004834:	e85a                	sd	s6,16(sp)
    80004836:	e45e                	sd	s7,8(sp)
    80004838:	e062                	sd	s8,0(sp)
    8000483a:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    8000483c:	00954783          	lbu	a5,9(a0)
    80004840:	10078663          	beqz	a5,8000494c <filewrite+0x128>
    80004844:	892a                	mv	s2,a0
    80004846:	8aae                	mv	s5,a1
    80004848:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000484a:	411c                	lw	a5,0(a0)
    8000484c:	4705                	li	a4,1
    8000484e:	02e78263          	beq	a5,a4,80004872 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004852:	470d                	li	a4,3
    80004854:	02e78663          	beq	a5,a4,80004880 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004858:	4709                	li	a4,2
    8000485a:	0ee79163          	bne	a5,a4,8000493c <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000485e:	0ac05d63          	blez	a2,80004918 <filewrite+0xf4>
    int i = 0;
    80004862:	4981                	li	s3,0
    80004864:	6b05                	lui	s6,0x1
    80004866:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000486a:	6b85                	lui	s7,0x1
    8000486c:	c00b8b9b          	addiw	s7,s7,-1024
    80004870:	a861                	j	80004908 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004872:	6908                	ld	a0,16(a0)
    80004874:	00000097          	auipc	ra,0x0
    80004878:	22e080e7          	jalr	558(ra) # 80004aa2 <pipewrite>
    8000487c:	8a2a                	mv	s4,a0
    8000487e:	a045                	j	8000491e <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004880:	02451783          	lh	a5,36(a0)
    80004884:	03079693          	slli	a3,a5,0x30
    80004888:	92c1                	srli	a3,a3,0x30
    8000488a:	4725                	li	a4,9
    8000488c:	0cd76263          	bltu	a4,a3,80004950 <filewrite+0x12c>
    80004890:	0792                	slli	a5,a5,0x4
    80004892:	00028717          	auipc	a4,0x28
    80004896:	7b670713          	addi	a4,a4,1974 # 8002d048 <devsw>
    8000489a:	97ba                	add	a5,a5,a4
    8000489c:	679c                	ld	a5,8(a5)
    8000489e:	cbdd                	beqz	a5,80004954 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800048a0:	4505                	li	a0,1
    800048a2:	9782                	jalr	a5
    800048a4:	8a2a                	mv	s4,a0
    800048a6:	a8a5                	j	8000491e <filewrite+0xfa>
    800048a8:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800048ac:	00000097          	auipc	ra,0x0
    800048b0:	8b0080e7          	jalr	-1872(ra) # 8000415c <begin_op>
      ilock(f->ip);
    800048b4:	01893503          	ld	a0,24(s2)
    800048b8:	fffff097          	auipc	ra,0xfffff
    800048bc:	ee2080e7          	jalr	-286(ra) # 8000379a <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800048c0:	8762                	mv	a4,s8
    800048c2:	02092683          	lw	a3,32(s2)
    800048c6:	01598633          	add	a2,s3,s5
    800048ca:	4585                	li	a1,1
    800048cc:	01893503          	ld	a0,24(s2)
    800048d0:	fffff097          	auipc	ra,0xfffff
    800048d4:	276080e7          	jalr	630(ra) # 80003b46 <writei>
    800048d8:	84aa                	mv	s1,a0
    800048da:	00a05763          	blez	a0,800048e8 <filewrite+0xc4>
        f->off += r;
    800048de:	02092783          	lw	a5,32(s2)
    800048e2:	9fa9                	addw	a5,a5,a0
    800048e4:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800048e8:	01893503          	ld	a0,24(s2)
    800048ec:	fffff097          	auipc	ra,0xfffff
    800048f0:	f70080e7          	jalr	-144(ra) # 8000385c <iunlock>
      end_op();
    800048f4:	00000097          	auipc	ra,0x0
    800048f8:	8e8080e7          	jalr	-1816(ra) # 800041dc <end_op>

      if(r != n1){
    800048fc:	009c1f63          	bne	s8,s1,8000491a <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004900:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004904:	0149db63          	bge	s3,s4,8000491a <filewrite+0xf6>
      int n1 = n - i;
    80004908:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    8000490c:	84be                	mv	s1,a5
    8000490e:	2781                	sext.w	a5,a5
    80004910:	f8fb5ce3          	bge	s6,a5,800048a8 <filewrite+0x84>
    80004914:	84de                	mv	s1,s7
    80004916:	bf49                	j	800048a8 <filewrite+0x84>
    int i = 0;
    80004918:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    8000491a:	013a1f63          	bne	s4,s3,80004938 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000491e:	8552                	mv	a0,s4
    80004920:	60a6                	ld	ra,72(sp)
    80004922:	6406                	ld	s0,64(sp)
    80004924:	74e2                	ld	s1,56(sp)
    80004926:	7942                	ld	s2,48(sp)
    80004928:	79a2                	ld	s3,40(sp)
    8000492a:	7a02                	ld	s4,32(sp)
    8000492c:	6ae2                	ld	s5,24(sp)
    8000492e:	6b42                	ld	s6,16(sp)
    80004930:	6ba2                	ld	s7,8(sp)
    80004932:	6c02                	ld	s8,0(sp)
    80004934:	6161                	addi	sp,sp,80
    80004936:	8082                	ret
    ret = (i == n ? n : -1);
    80004938:	5a7d                	li	s4,-1
    8000493a:	b7d5                	j	8000491e <filewrite+0xfa>
    panic("filewrite");
    8000493c:	00004517          	auipc	a0,0x4
    80004940:	e3c50513          	addi	a0,a0,-452 # 80008778 <syscalls+0x278>
    80004944:	ffffc097          	auipc	ra,0xffffc
    80004948:	c00080e7          	jalr	-1024(ra) # 80000544 <panic>
    return -1;
    8000494c:	5a7d                	li	s4,-1
    8000494e:	bfc1                	j	8000491e <filewrite+0xfa>
      return -1;
    80004950:	5a7d                	li	s4,-1
    80004952:	b7f1                	j	8000491e <filewrite+0xfa>
    80004954:	5a7d                	li	s4,-1
    80004956:	b7e1                	j	8000491e <filewrite+0xfa>

0000000080004958 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004958:	7179                	addi	sp,sp,-48
    8000495a:	f406                	sd	ra,40(sp)
    8000495c:	f022                	sd	s0,32(sp)
    8000495e:	ec26                	sd	s1,24(sp)
    80004960:	e84a                	sd	s2,16(sp)
    80004962:	e44e                	sd	s3,8(sp)
    80004964:	e052                	sd	s4,0(sp)
    80004966:	1800                	addi	s0,sp,48
    80004968:	84aa                	mv	s1,a0
    8000496a:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000496c:	0005b023          	sd	zero,0(a1)
    80004970:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004974:	00000097          	auipc	ra,0x0
    80004978:	bf8080e7          	jalr	-1032(ra) # 8000456c <filealloc>
    8000497c:	e088                	sd	a0,0(s1)
    8000497e:	c551                	beqz	a0,80004a0a <pipealloc+0xb2>
    80004980:	00000097          	auipc	ra,0x0
    80004984:	bec080e7          	jalr	-1044(ra) # 8000456c <filealloc>
    80004988:	00aa3023          	sd	a0,0(s4)
    8000498c:	c92d                	beqz	a0,800049fe <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000498e:	ffffc097          	auipc	ra,0xffffc
    80004992:	16c080e7          	jalr	364(ra) # 80000afa <kalloc>
    80004996:	892a                	mv	s2,a0
    80004998:	c125                	beqz	a0,800049f8 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    8000499a:	4985                	li	s3,1
    8000499c:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800049a0:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800049a4:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800049a8:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800049ac:	00004597          	auipc	a1,0x4
    800049b0:	aac58593          	addi	a1,a1,-1364 # 80008458 <states.1757+0x190>
    800049b4:	ffffc097          	auipc	ra,0xffffc
    800049b8:	1a6080e7          	jalr	422(ra) # 80000b5a <initlock>
  (*f0)->type = FD_PIPE;
    800049bc:	609c                	ld	a5,0(s1)
    800049be:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800049c2:	609c                	ld	a5,0(s1)
    800049c4:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800049c8:	609c                	ld	a5,0(s1)
    800049ca:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800049ce:	609c                	ld	a5,0(s1)
    800049d0:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800049d4:	000a3783          	ld	a5,0(s4)
    800049d8:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800049dc:	000a3783          	ld	a5,0(s4)
    800049e0:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800049e4:	000a3783          	ld	a5,0(s4)
    800049e8:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800049ec:	000a3783          	ld	a5,0(s4)
    800049f0:	0127b823          	sd	s2,16(a5)
  return 0;
    800049f4:	4501                	li	a0,0
    800049f6:	a025                	j	80004a1e <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800049f8:	6088                	ld	a0,0(s1)
    800049fa:	e501                	bnez	a0,80004a02 <pipealloc+0xaa>
    800049fc:	a039                	j	80004a0a <pipealloc+0xb2>
    800049fe:	6088                	ld	a0,0(s1)
    80004a00:	c51d                	beqz	a0,80004a2e <pipealloc+0xd6>
    fileclose(*f0);
    80004a02:	00000097          	auipc	ra,0x0
    80004a06:	c26080e7          	jalr	-986(ra) # 80004628 <fileclose>
  if(*f1)
    80004a0a:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a0e:	557d                	li	a0,-1
  if(*f1)
    80004a10:	c799                	beqz	a5,80004a1e <pipealloc+0xc6>
    fileclose(*f1);
    80004a12:	853e                	mv	a0,a5
    80004a14:	00000097          	auipc	ra,0x0
    80004a18:	c14080e7          	jalr	-1004(ra) # 80004628 <fileclose>
  return -1;
    80004a1c:	557d                	li	a0,-1
}
    80004a1e:	70a2                	ld	ra,40(sp)
    80004a20:	7402                	ld	s0,32(sp)
    80004a22:	64e2                	ld	s1,24(sp)
    80004a24:	6942                	ld	s2,16(sp)
    80004a26:	69a2                	ld	s3,8(sp)
    80004a28:	6a02                	ld	s4,0(sp)
    80004a2a:	6145                	addi	sp,sp,48
    80004a2c:	8082                	ret
  return -1;
    80004a2e:	557d                	li	a0,-1
    80004a30:	b7fd                	j	80004a1e <pipealloc+0xc6>

0000000080004a32 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a32:	1101                	addi	sp,sp,-32
    80004a34:	ec06                	sd	ra,24(sp)
    80004a36:	e822                	sd	s0,16(sp)
    80004a38:	e426                	sd	s1,8(sp)
    80004a3a:	e04a                	sd	s2,0(sp)
    80004a3c:	1000                	addi	s0,sp,32
    80004a3e:	84aa                	mv	s1,a0
    80004a40:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a42:	ffffc097          	auipc	ra,0xffffc
    80004a46:	1a8080e7          	jalr	424(ra) # 80000bea <acquire>
  if(writable){
    80004a4a:	02090d63          	beqz	s2,80004a84 <pipeclose+0x52>
    pi->writeopen = 0;
    80004a4e:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a52:	21848513          	addi	a0,s1,536
    80004a56:	ffffd097          	auipc	ra,0xffffd
    80004a5a:	6fa080e7          	jalr	1786(ra) # 80002150 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a5e:	2204b783          	ld	a5,544(s1)
    80004a62:	eb95                	bnez	a5,80004a96 <pipeclose+0x64>
    release(&pi->lock);
    80004a64:	8526                	mv	a0,s1
    80004a66:	ffffc097          	auipc	ra,0xffffc
    80004a6a:	238080e7          	jalr	568(ra) # 80000c9e <release>
    kfree((char*)pi);
    80004a6e:	8526                	mv	a0,s1
    80004a70:	ffffc097          	auipc	ra,0xffffc
    80004a74:	f8e080e7          	jalr	-114(ra) # 800009fe <kfree>
  } else
    release(&pi->lock);
}
    80004a78:	60e2                	ld	ra,24(sp)
    80004a7a:	6442                	ld	s0,16(sp)
    80004a7c:	64a2                	ld	s1,8(sp)
    80004a7e:	6902                	ld	s2,0(sp)
    80004a80:	6105                	addi	sp,sp,32
    80004a82:	8082                	ret
    pi->readopen = 0;
    80004a84:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a88:	21c48513          	addi	a0,s1,540
    80004a8c:	ffffd097          	auipc	ra,0xffffd
    80004a90:	6c4080e7          	jalr	1732(ra) # 80002150 <wakeup>
    80004a94:	b7e9                	j	80004a5e <pipeclose+0x2c>
    release(&pi->lock);
    80004a96:	8526                	mv	a0,s1
    80004a98:	ffffc097          	auipc	ra,0xffffc
    80004a9c:	206080e7          	jalr	518(ra) # 80000c9e <release>
}
    80004aa0:	bfe1                	j	80004a78 <pipeclose+0x46>

0000000080004aa2 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004aa2:	7159                	addi	sp,sp,-112
    80004aa4:	f486                	sd	ra,104(sp)
    80004aa6:	f0a2                	sd	s0,96(sp)
    80004aa8:	eca6                	sd	s1,88(sp)
    80004aaa:	e8ca                	sd	s2,80(sp)
    80004aac:	e4ce                	sd	s3,72(sp)
    80004aae:	e0d2                	sd	s4,64(sp)
    80004ab0:	fc56                	sd	s5,56(sp)
    80004ab2:	f85a                	sd	s6,48(sp)
    80004ab4:	f45e                	sd	s7,40(sp)
    80004ab6:	f062                	sd	s8,32(sp)
    80004ab8:	ec66                	sd	s9,24(sp)
    80004aba:	1880                	addi	s0,sp,112
    80004abc:	84aa                	mv	s1,a0
    80004abe:	8aae                	mv	s5,a1
    80004ac0:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004ac2:	ffffd097          	auipc	ra,0xffffd
    80004ac6:	f04080e7          	jalr	-252(ra) # 800019c6 <myproc>
    80004aca:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004acc:	8526                	mv	a0,s1
    80004ace:	ffffc097          	auipc	ra,0xffffc
    80004ad2:	11c080e7          	jalr	284(ra) # 80000bea <acquire>
  while(i < n){
    80004ad6:	0d405463          	blez	s4,80004b9e <pipewrite+0xfc>
    80004ada:	8ba6                	mv	s7,s1
  int i = 0;
    80004adc:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ade:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004ae0:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004ae4:	21c48c13          	addi	s8,s1,540
    80004ae8:	a08d                	j	80004b4a <pipewrite+0xa8>
      release(&pi->lock);
    80004aea:	8526                	mv	a0,s1
    80004aec:	ffffc097          	auipc	ra,0xffffc
    80004af0:	1b2080e7          	jalr	434(ra) # 80000c9e <release>
      return -1;
    80004af4:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004af6:	854a                	mv	a0,s2
    80004af8:	70a6                	ld	ra,104(sp)
    80004afa:	7406                	ld	s0,96(sp)
    80004afc:	64e6                	ld	s1,88(sp)
    80004afe:	6946                	ld	s2,80(sp)
    80004b00:	69a6                	ld	s3,72(sp)
    80004b02:	6a06                	ld	s4,64(sp)
    80004b04:	7ae2                	ld	s5,56(sp)
    80004b06:	7b42                	ld	s6,48(sp)
    80004b08:	7ba2                	ld	s7,40(sp)
    80004b0a:	7c02                	ld	s8,32(sp)
    80004b0c:	6ce2                	ld	s9,24(sp)
    80004b0e:	6165                	addi	sp,sp,112
    80004b10:	8082                	ret
      wakeup(&pi->nread);
    80004b12:	8566                	mv	a0,s9
    80004b14:	ffffd097          	auipc	ra,0xffffd
    80004b18:	63c080e7          	jalr	1596(ra) # 80002150 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b1c:	85de                	mv	a1,s7
    80004b1e:	8562                	mv	a0,s8
    80004b20:	ffffd097          	auipc	ra,0xffffd
    80004b24:	5cc080e7          	jalr	1484(ra) # 800020ec <sleep>
    80004b28:	a839                	j	80004b46 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b2a:	21c4a783          	lw	a5,540(s1)
    80004b2e:	0017871b          	addiw	a4,a5,1
    80004b32:	20e4ae23          	sw	a4,540(s1)
    80004b36:	1ff7f793          	andi	a5,a5,511
    80004b3a:	97a6                	add	a5,a5,s1
    80004b3c:	f9f44703          	lbu	a4,-97(s0)
    80004b40:	00e78c23          	sb	a4,24(a5)
      i++;
    80004b44:	2905                	addiw	s2,s2,1
  while(i < n){
    80004b46:	05495063          	bge	s2,s4,80004b86 <pipewrite+0xe4>
    if(pi->readopen == 0 || killed(pr)){
    80004b4a:	2204a783          	lw	a5,544(s1)
    80004b4e:	dfd1                	beqz	a5,80004aea <pipewrite+0x48>
    80004b50:	854e                	mv	a0,s3
    80004b52:	ffffe097          	auipc	ra,0xffffe
    80004b56:	842080e7          	jalr	-1982(ra) # 80002394 <killed>
    80004b5a:	f941                	bnez	a0,80004aea <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004b5c:	2184a783          	lw	a5,536(s1)
    80004b60:	21c4a703          	lw	a4,540(s1)
    80004b64:	2007879b          	addiw	a5,a5,512
    80004b68:	faf705e3          	beq	a4,a5,80004b12 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b6c:	4685                	li	a3,1
    80004b6e:	01590633          	add	a2,s2,s5
    80004b72:	f9f40593          	addi	a1,s0,-97
    80004b76:	0509b503          	ld	a0,80(s3)
    80004b7a:	ffffd097          	auipc	ra,0xffffd
    80004b7e:	b96080e7          	jalr	-1130(ra) # 80001710 <copyin>
    80004b82:	fb6514e3          	bne	a0,s6,80004b2a <pipewrite+0x88>
  wakeup(&pi->nread);
    80004b86:	21848513          	addi	a0,s1,536
    80004b8a:	ffffd097          	auipc	ra,0xffffd
    80004b8e:	5c6080e7          	jalr	1478(ra) # 80002150 <wakeup>
  release(&pi->lock);
    80004b92:	8526                	mv	a0,s1
    80004b94:	ffffc097          	auipc	ra,0xffffc
    80004b98:	10a080e7          	jalr	266(ra) # 80000c9e <release>
  return i;
    80004b9c:	bfa9                	j	80004af6 <pipewrite+0x54>
  int i = 0;
    80004b9e:	4901                	li	s2,0
    80004ba0:	b7dd                	j	80004b86 <pipewrite+0xe4>

0000000080004ba2 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004ba2:	715d                	addi	sp,sp,-80
    80004ba4:	e486                	sd	ra,72(sp)
    80004ba6:	e0a2                	sd	s0,64(sp)
    80004ba8:	fc26                	sd	s1,56(sp)
    80004baa:	f84a                	sd	s2,48(sp)
    80004bac:	f44e                	sd	s3,40(sp)
    80004bae:	f052                	sd	s4,32(sp)
    80004bb0:	ec56                	sd	s5,24(sp)
    80004bb2:	e85a                	sd	s6,16(sp)
    80004bb4:	0880                	addi	s0,sp,80
    80004bb6:	84aa                	mv	s1,a0
    80004bb8:	892e                	mv	s2,a1
    80004bba:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004bbc:	ffffd097          	auipc	ra,0xffffd
    80004bc0:	e0a080e7          	jalr	-502(ra) # 800019c6 <myproc>
    80004bc4:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004bc6:	8b26                	mv	s6,s1
    80004bc8:	8526                	mv	a0,s1
    80004bca:	ffffc097          	auipc	ra,0xffffc
    80004bce:	020080e7          	jalr	32(ra) # 80000bea <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bd2:	2184a703          	lw	a4,536(s1)
    80004bd6:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bda:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bde:	02f71763          	bne	a4,a5,80004c0c <piperead+0x6a>
    80004be2:	2244a783          	lw	a5,548(s1)
    80004be6:	c39d                	beqz	a5,80004c0c <piperead+0x6a>
    if(killed(pr)){
    80004be8:	8552                	mv	a0,s4
    80004bea:	ffffd097          	auipc	ra,0xffffd
    80004bee:	7aa080e7          	jalr	1962(ra) # 80002394 <killed>
    80004bf2:	e941                	bnez	a0,80004c82 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bf4:	85da                	mv	a1,s6
    80004bf6:	854e                	mv	a0,s3
    80004bf8:	ffffd097          	auipc	ra,0xffffd
    80004bfc:	4f4080e7          	jalr	1268(ra) # 800020ec <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c00:	2184a703          	lw	a4,536(s1)
    80004c04:	21c4a783          	lw	a5,540(s1)
    80004c08:	fcf70de3          	beq	a4,a5,80004be2 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c0c:	09505263          	blez	s5,80004c90 <piperead+0xee>
    80004c10:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c12:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004c14:	2184a783          	lw	a5,536(s1)
    80004c18:	21c4a703          	lw	a4,540(s1)
    80004c1c:	02f70d63          	beq	a4,a5,80004c56 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c20:	0017871b          	addiw	a4,a5,1
    80004c24:	20e4ac23          	sw	a4,536(s1)
    80004c28:	1ff7f793          	andi	a5,a5,511
    80004c2c:	97a6                	add	a5,a5,s1
    80004c2e:	0187c783          	lbu	a5,24(a5)
    80004c32:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c36:	4685                	li	a3,1
    80004c38:	fbf40613          	addi	a2,s0,-65
    80004c3c:	85ca                	mv	a1,s2
    80004c3e:	050a3503          	ld	a0,80(s4)
    80004c42:	ffffd097          	auipc	ra,0xffffd
    80004c46:	a42080e7          	jalr	-1470(ra) # 80001684 <copyout>
    80004c4a:	01650663          	beq	a0,s6,80004c56 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c4e:	2985                	addiw	s3,s3,1
    80004c50:	0905                	addi	s2,s2,1
    80004c52:	fd3a91e3          	bne	s5,s3,80004c14 <piperead+0x72>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c56:	21c48513          	addi	a0,s1,540
    80004c5a:	ffffd097          	auipc	ra,0xffffd
    80004c5e:	4f6080e7          	jalr	1270(ra) # 80002150 <wakeup>
  release(&pi->lock);
    80004c62:	8526                	mv	a0,s1
    80004c64:	ffffc097          	auipc	ra,0xffffc
    80004c68:	03a080e7          	jalr	58(ra) # 80000c9e <release>
  return i;
}
    80004c6c:	854e                	mv	a0,s3
    80004c6e:	60a6                	ld	ra,72(sp)
    80004c70:	6406                	ld	s0,64(sp)
    80004c72:	74e2                	ld	s1,56(sp)
    80004c74:	7942                	ld	s2,48(sp)
    80004c76:	79a2                	ld	s3,40(sp)
    80004c78:	7a02                	ld	s4,32(sp)
    80004c7a:	6ae2                	ld	s5,24(sp)
    80004c7c:	6b42                	ld	s6,16(sp)
    80004c7e:	6161                	addi	sp,sp,80
    80004c80:	8082                	ret
      release(&pi->lock);
    80004c82:	8526                	mv	a0,s1
    80004c84:	ffffc097          	auipc	ra,0xffffc
    80004c88:	01a080e7          	jalr	26(ra) # 80000c9e <release>
      return -1;
    80004c8c:	59fd                	li	s3,-1
    80004c8e:	bff9                	j	80004c6c <piperead+0xca>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c90:	4981                	li	s3,0
    80004c92:	b7d1                	j	80004c56 <piperead+0xb4>

0000000080004c94 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004c94:	1141                	addi	sp,sp,-16
    80004c96:	e422                	sd	s0,8(sp)
    80004c98:	0800                	addi	s0,sp,16
    80004c9a:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004c9c:	8905                	andi	a0,a0,1
    80004c9e:	c111                	beqz	a0,80004ca2 <flags2perm+0xe>
      perm = PTE_X;
    80004ca0:	4521                	li	a0,8
    if(flags & 0x2)
    80004ca2:	8b89                	andi	a5,a5,2
    80004ca4:	c399                	beqz	a5,80004caa <flags2perm+0x16>
      perm |= PTE_W;
    80004ca6:	00456513          	ori	a0,a0,4
    return perm;
}
    80004caa:	6422                	ld	s0,8(sp)
    80004cac:	0141                	addi	sp,sp,16
    80004cae:	8082                	ret

0000000080004cb0 <exec>:

int
exec(char *path, char **argv)
{
    80004cb0:	df010113          	addi	sp,sp,-528
    80004cb4:	20113423          	sd	ra,520(sp)
    80004cb8:	20813023          	sd	s0,512(sp)
    80004cbc:	ffa6                	sd	s1,504(sp)
    80004cbe:	fbca                	sd	s2,496(sp)
    80004cc0:	f7ce                	sd	s3,488(sp)
    80004cc2:	f3d2                	sd	s4,480(sp)
    80004cc4:	efd6                	sd	s5,472(sp)
    80004cc6:	ebda                	sd	s6,464(sp)
    80004cc8:	e7de                	sd	s7,456(sp)
    80004cca:	e3e2                	sd	s8,448(sp)
    80004ccc:	ff66                	sd	s9,440(sp)
    80004cce:	fb6a                	sd	s10,432(sp)
    80004cd0:	f76e                	sd	s11,424(sp)
    80004cd2:	0c00                	addi	s0,sp,528
    80004cd4:	84aa                	mv	s1,a0
    80004cd6:	dea43c23          	sd	a0,-520(s0)
    80004cda:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004cde:	ffffd097          	auipc	ra,0xffffd
    80004ce2:	ce8080e7          	jalr	-792(ra) # 800019c6 <myproc>
    80004ce6:	892a                	mv	s2,a0

  begin_op();
    80004ce8:	fffff097          	auipc	ra,0xfffff
    80004cec:	474080e7          	jalr	1140(ra) # 8000415c <begin_op>

  if((ip = namei(path)) == 0){
    80004cf0:	8526                	mv	a0,s1
    80004cf2:	fffff097          	auipc	ra,0xfffff
    80004cf6:	24e080e7          	jalr	590(ra) # 80003f40 <namei>
    80004cfa:	c92d                	beqz	a0,80004d6c <exec+0xbc>
    80004cfc:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004cfe:	fffff097          	auipc	ra,0xfffff
    80004d02:	a9c080e7          	jalr	-1380(ra) # 8000379a <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d06:	04000713          	li	a4,64
    80004d0a:	4681                	li	a3,0
    80004d0c:	e5040613          	addi	a2,s0,-432
    80004d10:	4581                	li	a1,0
    80004d12:	8526                	mv	a0,s1
    80004d14:	fffff097          	auipc	ra,0xfffff
    80004d18:	d3a080e7          	jalr	-710(ra) # 80003a4e <readi>
    80004d1c:	04000793          	li	a5,64
    80004d20:	00f51a63          	bne	a0,a5,80004d34 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004d24:	e5042703          	lw	a4,-432(s0)
    80004d28:	464c47b7          	lui	a5,0x464c4
    80004d2c:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d30:	04f70463          	beq	a4,a5,80004d78 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d34:	8526                	mv	a0,s1
    80004d36:	fffff097          	auipc	ra,0xfffff
    80004d3a:	cc6080e7          	jalr	-826(ra) # 800039fc <iunlockput>
    end_op();
    80004d3e:	fffff097          	auipc	ra,0xfffff
    80004d42:	49e080e7          	jalr	1182(ra) # 800041dc <end_op>
  }
  return -1;
    80004d46:	557d                	li	a0,-1
}
    80004d48:	20813083          	ld	ra,520(sp)
    80004d4c:	20013403          	ld	s0,512(sp)
    80004d50:	74fe                	ld	s1,504(sp)
    80004d52:	795e                	ld	s2,496(sp)
    80004d54:	79be                	ld	s3,488(sp)
    80004d56:	7a1e                	ld	s4,480(sp)
    80004d58:	6afe                	ld	s5,472(sp)
    80004d5a:	6b5e                	ld	s6,464(sp)
    80004d5c:	6bbe                	ld	s7,456(sp)
    80004d5e:	6c1e                	ld	s8,448(sp)
    80004d60:	7cfa                	ld	s9,440(sp)
    80004d62:	7d5a                	ld	s10,432(sp)
    80004d64:	7dba                	ld	s11,424(sp)
    80004d66:	21010113          	addi	sp,sp,528
    80004d6a:	8082                	ret
    end_op();
    80004d6c:	fffff097          	auipc	ra,0xfffff
    80004d70:	470080e7          	jalr	1136(ra) # 800041dc <end_op>
    return -1;
    80004d74:	557d                	li	a0,-1
    80004d76:	bfc9                	j	80004d48 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d78:	854a                	mv	a0,s2
    80004d7a:	ffffd097          	auipc	ra,0xffffd
    80004d7e:	d10080e7          	jalr	-752(ra) # 80001a8a <proc_pagetable>
    80004d82:	8baa                	mv	s7,a0
    80004d84:	d945                	beqz	a0,80004d34 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d86:	e7042983          	lw	s3,-400(s0)
    80004d8a:	e8845783          	lhu	a5,-376(s0)
    80004d8e:	c7ad                	beqz	a5,80004df8 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d90:	4a01                	li	s4,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d92:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004d94:	6c85                	lui	s9,0x1
    80004d96:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004d9a:	def43823          	sd	a5,-528(s0)
    80004d9e:	ac0d                	j	80004fd0 <exec+0x320>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004da0:	00004517          	auipc	a0,0x4
    80004da4:	9e850513          	addi	a0,a0,-1560 # 80008788 <syscalls+0x288>
    80004da8:	ffffb097          	auipc	ra,0xffffb
    80004dac:	79c080e7          	jalr	1948(ra) # 80000544 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004db0:	8756                	mv	a4,s5
    80004db2:	012d86bb          	addw	a3,s11,s2
    80004db6:	4581                	li	a1,0
    80004db8:	8526                	mv	a0,s1
    80004dba:	fffff097          	auipc	ra,0xfffff
    80004dbe:	c94080e7          	jalr	-876(ra) # 80003a4e <readi>
    80004dc2:	2501                	sext.w	a0,a0
    80004dc4:	1aaa9a63          	bne	s5,a0,80004f78 <exec+0x2c8>
  for(i = 0; i < sz; i += PGSIZE){
    80004dc8:	6785                	lui	a5,0x1
    80004dca:	0127893b          	addw	s2,a5,s2
    80004dce:	77fd                	lui	a5,0xfffff
    80004dd0:	01478a3b          	addw	s4,a5,s4
    80004dd4:	1f897563          	bgeu	s2,s8,80004fbe <exec+0x30e>
    pa = walkaddr(pagetable, va + i);
    80004dd8:	02091593          	slli	a1,s2,0x20
    80004ddc:	9181                	srli	a1,a1,0x20
    80004dde:	95ea                	add	a1,a1,s10
    80004de0:	855e                	mv	a0,s7
    80004de2:	ffffc097          	auipc	ra,0xffffc
    80004de6:	296080e7          	jalr	662(ra) # 80001078 <walkaddr>
    80004dea:	862a                	mv	a2,a0
    if(pa == 0)
    80004dec:	d955                	beqz	a0,80004da0 <exec+0xf0>
      n = PGSIZE;
    80004dee:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004df0:	fd9a70e3          	bgeu	s4,s9,80004db0 <exec+0x100>
      n = sz - i;
    80004df4:	8ad2                	mv	s5,s4
    80004df6:	bf6d                	j	80004db0 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004df8:	4a01                	li	s4,0
  iunlockput(ip);
    80004dfa:	8526                	mv	a0,s1
    80004dfc:	fffff097          	auipc	ra,0xfffff
    80004e00:	c00080e7          	jalr	-1024(ra) # 800039fc <iunlockput>
  end_op();
    80004e04:	fffff097          	auipc	ra,0xfffff
    80004e08:	3d8080e7          	jalr	984(ra) # 800041dc <end_op>
  p = myproc();
    80004e0c:	ffffd097          	auipc	ra,0xffffd
    80004e10:	bba080e7          	jalr	-1094(ra) # 800019c6 <myproc>
    80004e14:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004e16:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e1a:	6785                	lui	a5,0x1
    80004e1c:	17fd                	addi	a5,a5,-1
    80004e1e:	9a3e                	add	s4,s4,a5
    80004e20:	757d                	lui	a0,0xfffff
    80004e22:	00aa77b3          	and	a5,s4,a0
    80004e26:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004e2a:	4691                	li	a3,4
    80004e2c:	6609                	lui	a2,0x2
    80004e2e:	963e                	add	a2,a2,a5
    80004e30:	85be                	mv	a1,a5
    80004e32:	855e                	mv	a0,s7
    80004e34:	ffffc097          	auipc	ra,0xffffc
    80004e38:	5f8080e7          	jalr	1528(ra) # 8000142c <uvmalloc>
    80004e3c:	8b2a                	mv	s6,a0
  ip = 0;
    80004e3e:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004e40:	12050c63          	beqz	a0,80004f78 <exec+0x2c8>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e44:	75f9                	lui	a1,0xffffe
    80004e46:	95aa                	add	a1,a1,a0
    80004e48:	855e                	mv	a0,s7
    80004e4a:	ffffd097          	auipc	ra,0xffffd
    80004e4e:	808080e7          	jalr	-2040(ra) # 80001652 <uvmclear>
  stackbase = sp - PGSIZE;
    80004e52:	7c7d                	lui	s8,0xfffff
    80004e54:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e56:	e0043783          	ld	a5,-512(s0)
    80004e5a:	6388                	ld	a0,0(a5)
    80004e5c:	c535                	beqz	a0,80004ec8 <exec+0x218>
    80004e5e:	e9040993          	addi	s3,s0,-368
    80004e62:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004e66:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004e68:	ffffc097          	auipc	ra,0xffffc
    80004e6c:	002080e7          	jalr	2(ra) # 80000e6a <strlen>
    80004e70:	2505                	addiw	a0,a0,1
    80004e72:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e76:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004e7a:	13896663          	bltu	s2,s8,80004fa6 <exec+0x2f6>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e7e:	e0043d83          	ld	s11,-512(s0)
    80004e82:	000dba03          	ld	s4,0(s11)
    80004e86:	8552                	mv	a0,s4
    80004e88:	ffffc097          	auipc	ra,0xffffc
    80004e8c:	fe2080e7          	jalr	-30(ra) # 80000e6a <strlen>
    80004e90:	0015069b          	addiw	a3,a0,1
    80004e94:	8652                	mv	a2,s4
    80004e96:	85ca                	mv	a1,s2
    80004e98:	855e                	mv	a0,s7
    80004e9a:	ffffc097          	auipc	ra,0xffffc
    80004e9e:	7ea080e7          	jalr	2026(ra) # 80001684 <copyout>
    80004ea2:	10054663          	bltz	a0,80004fae <exec+0x2fe>
    ustack[argc] = sp;
    80004ea6:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004eaa:	0485                	addi	s1,s1,1
    80004eac:	008d8793          	addi	a5,s11,8
    80004eb0:	e0f43023          	sd	a5,-512(s0)
    80004eb4:	008db503          	ld	a0,8(s11)
    80004eb8:	c911                	beqz	a0,80004ecc <exec+0x21c>
    if(argc >= MAXARG)
    80004eba:	09a1                	addi	s3,s3,8
    80004ebc:	fb3c96e3          	bne	s9,s3,80004e68 <exec+0x1b8>
  sz = sz1;
    80004ec0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ec4:	4481                	li	s1,0
    80004ec6:	a84d                	j	80004f78 <exec+0x2c8>
  sp = sz;
    80004ec8:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004eca:	4481                	li	s1,0
  ustack[argc] = 0;
    80004ecc:	00349793          	slli	a5,s1,0x3
    80004ed0:	f9040713          	addi	a4,s0,-112
    80004ed4:	97ba                	add	a5,a5,a4
    80004ed6:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004eda:	00148693          	addi	a3,s1,1
    80004ede:	068e                	slli	a3,a3,0x3
    80004ee0:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004ee4:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004ee8:	01897663          	bgeu	s2,s8,80004ef4 <exec+0x244>
  sz = sz1;
    80004eec:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ef0:	4481                	li	s1,0
    80004ef2:	a059                	j	80004f78 <exec+0x2c8>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004ef4:	e9040613          	addi	a2,s0,-368
    80004ef8:	85ca                	mv	a1,s2
    80004efa:	855e                	mv	a0,s7
    80004efc:	ffffc097          	auipc	ra,0xffffc
    80004f00:	788080e7          	jalr	1928(ra) # 80001684 <copyout>
    80004f04:	0a054963          	bltz	a0,80004fb6 <exec+0x306>
  p->trapframe->a1 = sp;
    80004f08:	058ab783          	ld	a5,88(s5)
    80004f0c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f10:	df843783          	ld	a5,-520(s0)
    80004f14:	0007c703          	lbu	a4,0(a5)
    80004f18:	cf11                	beqz	a4,80004f34 <exec+0x284>
    80004f1a:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f1c:	02f00693          	li	a3,47
    80004f20:	a039                	j	80004f2e <exec+0x27e>
      last = s+1;
    80004f22:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004f26:	0785                	addi	a5,a5,1
    80004f28:	fff7c703          	lbu	a4,-1(a5)
    80004f2c:	c701                	beqz	a4,80004f34 <exec+0x284>
    if(*s == '/')
    80004f2e:	fed71ce3          	bne	a4,a3,80004f26 <exec+0x276>
    80004f32:	bfc5                	j	80004f22 <exec+0x272>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f34:	4641                	li	a2,16
    80004f36:	df843583          	ld	a1,-520(s0)
    80004f3a:	158a8513          	addi	a0,s5,344
    80004f3e:	ffffc097          	auipc	ra,0xffffc
    80004f42:	efa080e7          	jalr	-262(ra) # 80000e38 <safestrcpy>
  oldpagetable = p->pagetable;
    80004f46:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004f4a:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004f4e:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f52:	058ab783          	ld	a5,88(s5)
    80004f56:	e6843703          	ld	a4,-408(s0)
    80004f5a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f5c:	058ab783          	ld	a5,88(s5)
    80004f60:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f64:	85ea                	mv	a1,s10
    80004f66:	ffffd097          	auipc	ra,0xffffd
    80004f6a:	bc0080e7          	jalr	-1088(ra) # 80001b26 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f6e:	0004851b          	sext.w	a0,s1
    80004f72:	bbd9                	j	80004d48 <exec+0x98>
    80004f74:	e1443423          	sd	s4,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004f78:	e0843583          	ld	a1,-504(s0)
    80004f7c:	855e                	mv	a0,s7
    80004f7e:	ffffd097          	auipc	ra,0xffffd
    80004f82:	ba8080e7          	jalr	-1112(ra) # 80001b26 <proc_freepagetable>
  if(ip){
    80004f86:	da0497e3          	bnez	s1,80004d34 <exec+0x84>
  return -1;
    80004f8a:	557d                	li	a0,-1
    80004f8c:	bb75                	j	80004d48 <exec+0x98>
    80004f8e:	e1443423          	sd	s4,-504(s0)
    80004f92:	b7dd                	j	80004f78 <exec+0x2c8>
    80004f94:	e1443423          	sd	s4,-504(s0)
    80004f98:	b7c5                	j	80004f78 <exec+0x2c8>
    80004f9a:	e1443423          	sd	s4,-504(s0)
    80004f9e:	bfe9                	j	80004f78 <exec+0x2c8>
    80004fa0:	e1443423          	sd	s4,-504(s0)
    80004fa4:	bfd1                	j	80004f78 <exec+0x2c8>
  sz = sz1;
    80004fa6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004faa:	4481                	li	s1,0
    80004fac:	b7f1                	j	80004f78 <exec+0x2c8>
  sz = sz1;
    80004fae:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fb2:	4481                	li	s1,0
    80004fb4:	b7d1                	j	80004f78 <exec+0x2c8>
  sz = sz1;
    80004fb6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fba:	4481                	li	s1,0
    80004fbc:	bf75                	j	80004f78 <exec+0x2c8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004fbe:	e0843a03          	ld	s4,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fc2:	2b05                	addiw	s6,s6,1
    80004fc4:	0389899b          	addiw	s3,s3,56
    80004fc8:	e8845783          	lhu	a5,-376(s0)
    80004fcc:	e2fb57e3          	bge	s6,a5,80004dfa <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004fd0:	2981                	sext.w	s3,s3
    80004fd2:	03800713          	li	a4,56
    80004fd6:	86ce                	mv	a3,s3
    80004fd8:	e1840613          	addi	a2,s0,-488
    80004fdc:	4581                	li	a1,0
    80004fde:	8526                	mv	a0,s1
    80004fe0:	fffff097          	auipc	ra,0xfffff
    80004fe4:	a6e080e7          	jalr	-1426(ra) # 80003a4e <readi>
    80004fe8:	03800793          	li	a5,56
    80004fec:	f8f514e3          	bne	a0,a5,80004f74 <exec+0x2c4>
    if(ph.type != ELF_PROG_LOAD)
    80004ff0:	e1842783          	lw	a5,-488(s0)
    80004ff4:	4705                	li	a4,1
    80004ff6:	fce796e3          	bne	a5,a4,80004fc2 <exec+0x312>
    if(ph.memsz < ph.filesz)
    80004ffa:	e4043903          	ld	s2,-448(s0)
    80004ffe:	e3843783          	ld	a5,-456(s0)
    80005002:	f8f966e3          	bltu	s2,a5,80004f8e <exec+0x2de>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005006:	e2843783          	ld	a5,-472(s0)
    8000500a:	993e                	add	s2,s2,a5
    8000500c:	f8f964e3          	bltu	s2,a5,80004f94 <exec+0x2e4>
    if(ph.vaddr % PGSIZE != 0)
    80005010:	df043703          	ld	a4,-528(s0)
    80005014:	8ff9                	and	a5,a5,a4
    80005016:	f3d1                	bnez	a5,80004f9a <exec+0x2ea>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005018:	e1c42503          	lw	a0,-484(s0)
    8000501c:	00000097          	auipc	ra,0x0
    80005020:	c78080e7          	jalr	-904(ra) # 80004c94 <flags2perm>
    80005024:	86aa                	mv	a3,a0
    80005026:	864a                	mv	a2,s2
    80005028:	85d2                	mv	a1,s4
    8000502a:	855e                	mv	a0,s7
    8000502c:	ffffc097          	auipc	ra,0xffffc
    80005030:	400080e7          	jalr	1024(ra) # 8000142c <uvmalloc>
    80005034:	e0a43423          	sd	a0,-504(s0)
    80005038:	d525                	beqz	a0,80004fa0 <exec+0x2f0>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000503a:	e2843d03          	ld	s10,-472(s0)
    8000503e:	e2042d83          	lw	s11,-480(s0)
    80005042:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005046:	f60c0ce3          	beqz	s8,80004fbe <exec+0x30e>
    8000504a:	8a62                	mv	s4,s8
    8000504c:	4901                	li	s2,0
    8000504e:	b369                	j	80004dd8 <exec+0x128>

0000000080005050 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005050:	7179                	addi	sp,sp,-48
    80005052:	f406                	sd	ra,40(sp)
    80005054:	f022                	sd	s0,32(sp)
    80005056:	ec26                	sd	s1,24(sp)
    80005058:	e84a                	sd	s2,16(sp)
    8000505a:	1800                	addi	s0,sp,48
    8000505c:	892e                	mv	s2,a1
    8000505e:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005060:	fdc40593          	addi	a1,s0,-36
    80005064:	ffffe097          	auipc	ra,0xffffe
    80005068:	af4080e7          	jalr	-1292(ra) # 80002b58 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000506c:	fdc42703          	lw	a4,-36(s0)
    80005070:	47bd                	li	a5,15
    80005072:	02e7eb63          	bltu	a5,a4,800050a8 <argfd+0x58>
    80005076:	ffffd097          	auipc	ra,0xffffd
    8000507a:	950080e7          	jalr	-1712(ra) # 800019c6 <myproc>
    8000507e:	fdc42703          	lw	a4,-36(s0)
    80005082:	01a70793          	addi	a5,a4,26
    80005086:	078e                	slli	a5,a5,0x3
    80005088:	953e                	add	a0,a0,a5
    8000508a:	611c                	ld	a5,0(a0)
    8000508c:	c385                	beqz	a5,800050ac <argfd+0x5c>
    return -1;
  if(pfd)
    8000508e:	00090463          	beqz	s2,80005096 <argfd+0x46>
    *pfd = fd;
    80005092:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005096:	4501                	li	a0,0
  if(pf)
    80005098:	c091                	beqz	s1,8000509c <argfd+0x4c>
    *pf = f;
    8000509a:	e09c                	sd	a5,0(s1)
}
    8000509c:	70a2                	ld	ra,40(sp)
    8000509e:	7402                	ld	s0,32(sp)
    800050a0:	64e2                	ld	s1,24(sp)
    800050a2:	6942                	ld	s2,16(sp)
    800050a4:	6145                	addi	sp,sp,48
    800050a6:	8082                	ret
    return -1;
    800050a8:	557d                	li	a0,-1
    800050aa:	bfcd                	j	8000509c <argfd+0x4c>
    800050ac:	557d                	li	a0,-1
    800050ae:	b7fd                	j	8000509c <argfd+0x4c>

00000000800050b0 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800050b0:	1101                	addi	sp,sp,-32
    800050b2:	ec06                	sd	ra,24(sp)
    800050b4:	e822                	sd	s0,16(sp)
    800050b6:	e426                	sd	s1,8(sp)
    800050b8:	1000                	addi	s0,sp,32
    800050ba:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800050bc:	ffffd097          	auipc	ra,0xffffd
    800050c0:	90a080e7          	jalr	-1782(ra) # 800019c6 <myproc>
    800050c4:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800050c6:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd0ef0>
    800050ca:	4501                	li	a0,0
    800050cc:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800050ce:	6398                	ld	a4,0(a5)
    800050d0:	cb19                	beqz	a4,800050e6 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800050d2:	2505                	addiw	a0,a0,1
    800050d4:	07a1                	addi	a5,a5,8
    800050d6:	fed51ce3          	bne	a0,a3,800050ce <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800050da:	557d                	li	a0,-1
}
    800050dc:	60e2                	ld	ra,24(sp)
    800050de:	6442                	ld	s0,16(sp)
    800050e0:	64a2                	ld	s1,8(sp)
    800050e2:	6105                	addi	sp,sp,32
    800050e4:	8082                	ret
      p->ofile[fd] = f;
    800050e6:	01a50793          	addi	a5,a0,26
    800050ea:	078e                	slli	a5,a5,0x3
    800050ec:	963e                	add	a2,a2,a5
    800050ee:	e204                	sd	s1,0(a2)
      return fd;
    800050f0:	b7f5                	j	800050dc <fdalloc+0x2c>

00000000800050f2 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800050f2:	715d                	addi	sp,sp,-80
    800050f4:	e486                	sd	ra,72(sp)
    800050f6:	e0a2                	sd	s0,64(sp)
    800050f8:	fc26                	sd	s1,56(sp)
    800050fa:	f84a                	sd	s2,48(sp)
    800050fc:	f44e                	sd	s3,40(sp)
    800050fe:	f052                	sd	s4,32(sp)
    80005100:	ec56                	sd	s5,24(sp)
    80005102:	e85a                	sd	s6,16(sp)
    80005104:	0880                	addi	s0,sp,80
    80005106:	8b2e                	mv	s6,a1
    80005108:	89b2                	mv	s3,a2
    8000510a:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000510c:	fb040593          	addi	a1,s0,-80
    80005110:	fffff097          	auipc	ra,0xfffff
    80005114:	e4e080e7          	jalr	-434(ra) # 80003f5e <nameiparent>
    80005118:	84aa                	mv	s1,a0
    8000511a:	16050063          	beqz	a0,8000527a <create+0x188>
    return 0;

  ilock(dp);
    8000511e:	ffffe097          	auipc	ra,0xffffe
    80005122:	67c080e7          	jalr	1660(ra) # 8000379a <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005126:	4601                	li	a2,0
    80005128:	fb040593          	addi	a1,s0,-80
    8000512c:	8526                	mv	a0,s1
    8000512e:	fffff097          	auipc	ra,0xfffff
    80005132:	b50080e7          	jalr	-1200(ra) # 80003c7e <dirlookup>
    80005136:	8aaa                	mv	s5,a0
    80005138:	c931                	beqz	a0,8000518c <create+0x9a>
    iunlockput(dp);
    8000513a:	8526                	mv	a0,s1
    8000513c:	fffff097          	auipc	ra,0xfffff
    80005140:	8c0080e7          	jalr	-1856(ra) # 800039fc <iunlockput>
    ilock(ip);
    80005144:	8556                	mv	a0,s5
    80005146:	ffffe097          	auipc	ra,0xffffe
    8000514a:	654080e7          	jalr	1620(ra) # 8000379a <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000514e:	000b059b          	sext.w	a1,s6
    80005152:	4789                	li	a5,2
    80005154:	02f59563          	bne	a1,a5,8000517e <create+0x8c>
    80005158:	044ad783          	lhu	a5,68(s5)
    8000515c:	37f9                	addiw	a5,a5,-2
    8000515e:	17c2                	slli	a5,a5,0x30
    80005160:	93c1                	srli	a5,a5,0x30
    80005162:	4705                	li	a4,1
    80005164:	00f76d63          	bltu	a4,a5,8000517e <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005168:	8556                	mv	a0,s5
    8000516a:	60a6                	ld	ra,72(sp)
    8000516c:	6406                	ld	s0,64(sp)
    8000516e:	74e2                	ld	s1,56(sp)
    80005170:	7942                	ld	s2,48(sp)
    80005172:	79a2                	ld	s3,40(sp)
    80005174:	7a02                	ld	s4,32(sp)
    80005176:	6ae2                	ld	s5,24(sp)
    80005178:	6b42                	ld	s6,16(sp)
    8000517a:	6161                	addi	sp,sp,80
    8000517c:	8082                	ret
    iunlockput(ip);
    8000517e:	8556                	mv	a0,s5
    80005180:	fffff097          	auipc	ra,0xfffff
    80005184:	87c080e7          	jalr	-1924(ra) # 800039fc <iunlockput>
    return 0;
    80005188:	4a81                	li	s5,0
    8000518a:	bff9                	j	80005168 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    8000518c:	85da                	mv	a1,s6
    8000518e:	4088                	lw	a0,0(s1)
    80005190:	ffffe097          	auipc	ra,0xffffe
    80005194:	46e080e7          	jalr	1134(ra) # 800035fe <ialloc>
    80005198:	8a2a                	mv	s4,a0
    8000519a:	c921                	beqz	a0,800051ea <create+0xf8>
  ilock(ip);
    8000519c:	ffffe097          	auipc	ra,0xffffe
    800051a0:	5fe080e7          	jalr	1534(ra) # 8000379a <ilock>
  ip->major = major;
    800051a4:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800051a8:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800051ac:	4785                	li	a5,1
    800051ae:	04fa1523          	sh	a5,74(s4)
  iupdate(ip);
    800051b2:	8552                	mv	a0,s4
    800051b4:	ffffe097          	auipc	ra,0xffffe
    800051b8:	51c080e7          	jalr	1308(ra) # 800036d0 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800051bc:	000b059b          	sext.w	a1,s6
    800051c0:	4785                	li	a5,1
    800051c2:	02f58b63          	beq	a1,a5,800051f8 <create+0x106>
  if(dirlink(dp, name, ip->inum) < 0)
    800051c6:	004a2603          	lw	a2,4(s4)
    800051ca:	fb040593          	addi	a1,s0,-80
    800051ce:	8526                	mv	a0,s1
    800051d0:	fffff097          	auipc	ra,0xfffff
    800051d4:	cbe080e7          	jalr	-834(ra) # 80003e8e <dirlink>
    800051d8:	06054f63          	bltz	a0,80005256 <create+0x164>
  iunlockput(dp);
    800051dc:	8526                	mv	a0,s1
    800051de:	fffff097          	auipc	ra,0xfffff
    800051e2:	81e080e7          	jalr	-2018(ra) # 800039fc <iunlockput>
  return ip;
    800051e6:	8ad2                	mv	s5,s4
    800051e8:	b741                	j	80005168 <create+0x76>
    iunlockput(dp);
    800051ea:	8526                	mv	a0,s1
    800051ec:	fffff097          	auipc	ra,0xfffff
    800051f0:	810080e7          	jalr	-2032(ra) # 800039fc <iunlockput>
    return 0;
    800051f4:	8ad2                	mv	s5,s4
    800051f6:	bf8d                	j	80005168 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800051f8:	004a2603          	lw	a2,4(s4)
    800051fc:	00003597          	auipc	a1,0x3
    80005200:	5ac58593          	addi	a1,a1,1452 # 800087a8 <syscalls+0x2a8>
    80005204:	8552                	mv	a0,s4
    80005206:	fffff097          	auipc	ra,0xfffff
    8000520a:	c88080e7          	jalr	-888(ra) # 80003e8e <dirlink>
    8000520e:	04054463          	bltz	a0,80005256 <create+0x164>
    80005212:	40d0                	lw	a2,4(s1)
    80005214:	00003597          	auipc	a1,0x3
    80005218:	59c58593          	addi	a1,a1,1436 # 800087b0 <syscalls+0x2b0>
    8000521c:	8552                	mv	a0,s4
    8000521e:	fffff097          	auipc	ra,0xfffff
    80005222:	c70080e7          	jalr	-912(ra) # 80003e8e <dirlink>
    80005226:	02054863          	bltz	a0,80005256 <create+0x164>
  if(dirlink(dp, name, ip->inum) < 0)
    8000522a:	004a2603          	lw	a2,4(s4)
    8000522e:	fb040593          	addi	a1,s0,-80
    80005232:	8526                	mv	a0,s1
    80005234:	fffff097          	auipc	ra,0xfffff
    80005238:	c5a080e7          	jalr	-934(ra) # 80003e8e <dirlink>
    8000523c:	00054d63          	bltz	a0,80005256 <create+0x164>
    dp->nlink++;  // for ".."
    80005240:	04a4d783          	lhu	a5,74(s1)
    80005244:	2785                	addiw	a5,a5,1
    80005246:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000524a:	8526                	mv	a0,s1
    8000524c:	ffffe097          	auipc	ra,0xffffe
    80005250:	484080e7          	jalr	1156(ra) # 800036d0 <iupdate>
    80005254:	b761                	j	800051dc <create+0xea>
  ip->nlink = 0;
    80005256:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    8000525a:	8552                	mv	a0,s4
    8000525c:	ffffe097          	auipc	ra,0xffffe
    80005260:	474080e7          	jalr	1140(ra) # 800036d0 <iupdate>
  iunlockput(ip);
    80005264:	8552                	mv	a0,s4
    80005266:	ffffe097          	auipc	ra,0xffffe
    8000526a:	796080e7          	jalr	1942(ra) # 800039fc <iunlockput>
  iunlockput(dp);
    8000526e:	8526                	mv	a0,s1
    80005270:	ffffe097          	auipc	ra,0xffffe
    80005274:	78c080e7          	jalr	1932(ra) # 800039fc <iunlockput>
  return 0;
    80005278:	bdc5                	j	80005168 <create+0x76>
    return 0;
    8000527a:	8aaa                	mv	s5,a0
    8000527c:	b5f5                	j	80005168 <create+0x76>

000000008000527e <sys_dup>:
{
    8000527e:	7179                	addi	sp,sp,-48
    80005280:	f406                	sd	ra,40(sp)
    80005282:	f022                	sd	s0,32(sp)
    80005284:	ec26                	sd	s1,24(sp)
    80005286:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005288:	fd840613          	addi	a2,s0,-40
    8000528c:	4581                	li	a1,0
    8000528e:	4501                	li	a0,0
    80005290:	00000097          	auipc	ra,0x0
    80005294:	dc0080e7          	jalr	-576(ra) # 80005050 <argfd>
    return -1;
    80005298:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000529a:	02054363          	bltz	a0,800052c0 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000529e:	fd843503          	ld	a0,-40(s0)
    800052a2:	00000097          	auipc	ra,0x0
    800052a6:	e0e080e7          	jalr	-498(ra) # 800050b0 <fdalloc>
    800052aa:	84aa                	mv	s1,a0
    return -1;
    800052ac:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800052ae:	00054963          	bltz	a0,800052c0 <sys_dup+0x42>
  filedup(f);
    800052b2:	fd843503          	ld	a0,-40(s0)
    800052b6:	fffff097          	auipc	ra,0xfffff
    800052ba:	320080e7          	jalr	800(ra) # 800045d6 <filedup>
  return fd;
    800052be:	87a6                	mv	a5,s1
}
    800052c0:	853e                	mv	a0,a5
    800052c2:	70a2                	ld	ra,40(sp)
    800052c4:	7402                	ld	s0,32(sp)
    800052c6:	64e2                	ld	s1,24(sp)
    800052c8:	6145                	addi	sp,sp,48
    800052ca:	8082                	ret

00000000800052cc <sys_read>:
{
    800052cc:	7179                	addi	sp,sp,-48
    800052ce:	f406                	sd	ra,40(sp)
    800052d0:	f022                	sd	s0,32(sp)
    800052d2:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800052d4:	fd840593          	addi	a1,s0,-40
    800052d8:	4505                	li	a0,1
    800052da:	ffffe097          	auipc	ra,0xffffe
    800052de:	89e080e7          	jalr	-1890(ra) # 80002b78 <argaddr>
  argint(2, &n);
    800052e2:	fe440593          	addi	a1,s0,-28
    800052e6:	4509                	li	a0,2
    800052e8:	ffffe097          	auipc	ra,0xffffe
    800052ec:	870080e7          	jalr	-1936(ra) # 80002b58 <argint>
  if(argfd(0, 0, &f) < 0)
    800052f0:	fe840613          	addi	a2,s0,-24
    800052f4:	4581                	li	a1,0
    800052f6:	4501                	li	a0,0
    800052f8:	00000097          	auipc	ra,0x0
    800052fc:	d58080e7          	jalr	-680(ra) # 80005050 <argfd>
    80005300:	87aa                	mv	a5,a0
    return -1;
    80005302:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005304:	0007cc63          	bltz	a5,8000531c <sys_read+0x50>
  return fileread(f, p, n);
    80005308:	fe442603          	lw	a2,-28(s0)
    8000530c:	fd843583          	ld	a1,-40(s0)
    80005310:	fe843503          	ld	a0,-24(s0)
    80005314:	fffff097          	auipc	ra,0xfffff
    80005318:	44e080e7          	jalr	1102(ra) # 80004762 <fileread>
}
    8000531c:	70a2                	ld	ra,40(sp)
    8000531e:	7402                	ld	s0,32(sp)
    80005320:	6145                	addi	sp,sp,48
    80005322:	8082                	ret

0000000080005324 <sys_write>:
{
    80005324:	7179                	addi	sp,sp,-48
    80005326:	f406                	sd	ra,40(sp)
    80005328:	f022                	sd	s0,32(sp)
    8000532a:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000532c:	fd840593          	addi	a1,s0,-40
    80005330:	4505                	li	a0,1
    80005332:	ffffe097          	auipc	ra,0xffffe
    80005336:	846080e7          	jalr	-1978(ra) # 80002b78 <argaddr>
  argint(2, &n);
    8000533a:	fe440593          	addi	a1,s0,-28
    8000533e:	4509                	li	a0,2
    80005340:	ffffe097          	auipc	ra,0xffffe
    80005344:	818080e7          	jalr	-2024(ra) # 80002b58 <argint>
  if(argfd(0, 0, &f) < 0)
    80005348:	fe840613          	addi	a2,s0,-24
    8000534c:	4581                	li	a1,0
    8000534e:	4501                	li	a0,0
    80005350:	00000097          	auipc	ra,0x0
    80005354:	d00080e7          	jalr	-768(ra) # 80005050 <argfd>
    80005358:	87aa                	mv	a5,a0
    return -1;
    8000535a:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000535c:	0007cc63          	bltz	a5,80005374 <sys_write+0x50>
  return filewrite(f, p, n);
    80005360:	fe442603          	lw	a2,-28(s0)
    80005364:	fd843583          	ld	a1,-40(s0)
    80005368:	fe843503          	ld	a0,-24(s0)
    8000536c:	fffff097          	auipc	ra,0xfffff
    80005370:	4b8080e7          	jalr	1208(ra) # 80004824 <filewrite>
}
    80005374:	70a2                	ld	ra,40(sp)
    80005376:	7402                	ld	s0,32(sp)
    80005378:	6145                	addi	sp,sp,48
    8000537a:	8082                	ret

000000008000537c <sys_close>:
{
    8000537c:	1101                	addi	sp,sp,-32
    8000537e:	ec06                	sd	ra,24(sp)
    80005380:	e822                	sd	s0,16(sp)
    80005382:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005384:	fe040613          	addi	a2,s0,-32
    80005388:	fec40593          	addi	a1,s0,-20
    8000538c:	4501                	li	a0,0
    8000538e:	00000097          	auipc	ra,0x0
    80005392:	cc2080e7          	jalr	-830(ra) # 80005050 <argfd>
    return -1;
    80005396:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005398:	02054463          	bltz	a0,800053c0 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000539c:	ffffc097          	auipc	ra,0xffffc
    800053a0:	62a080e7          	jalr	1578(ra) # 800019c6 <myproc>
    800053a4:	fec42783          	lw	a5,-20(s0)
    800053a8:	07e9                	addi	a5,a5,26
    800053aa:	078e                	slli	a5,a5,0x3
    800053ac:	97aa                	add	a5,a5,a0
    800053ae:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800053b2:	fe043503          	ld	a0,-32(s0)
    800053b6:	fffff097          	auipc	ra,0xfffff
    800053ba:	272080e7          	jalr	626(ra) # 80004628 <fileclose>
  return 0;
    800053be:	4781                	li	a5,0
}
    800053c0:	853e                	mv	a0,a5
    800053c2:	60e2                	ld	ra,24(sp)
    800053c4:	6442                	ld	s0,16(sp)
    800053c6:	6105                	addi	sp,sp,32
    800053c8:	8082                	ret

00000000800053ca <sys_fstat>:
{
    800053ca:	1101                	addi	sp,sp,-32
    800053cc:	ec06                	sd	ra,24(sp)
    800053ce:	e822                	sd	s0,16(sp)
    800053d0:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800053d2:	fe040593          	addi	a1,s0,-32
    800053d6:	4505                	li	a0,1
    800053d8:	ffffd097          	auipc	ra,0xffffd
    800053dc:	7a0080e7          	jalr	1952(ra) # 80002b78 <argaddr>
  if(argfd(0, 0, &f) < 0)
    800053e0:	fe840613          	addi	a2,s0,-24
    800053e4:	4581                	li	a1,0
    800053e6:	4501                	li	a0,0
    800053e8:	00000097          	auipc	ra,0x0
    800053ec:	c68080e7          	jalr	-920(ra) # 80005050 <argfd>
    800053f0:	87aa                	mv	a5,a0
    return -1;
    800053f2:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800053f4:	0007ca63          	bltz	a5,80005408 <sys_fstat+0x3e>
  return filestat(f, st);
    800053f8:	fe043583          	ld	a1,-32(s0)
    800053fc:	fe843503          	ld	a0,-24(s0)
    80005400:	fffff097          	auipc	ra,0xfffff
    80005404:	2f0080e7          	jalr	752(ra) # 800046f0 <filestat>
}
    80005408:	60e2                	ld	ra,24(sp)
    8000540a:	6442                	ld	s0,16(sp)
    8000540c:	6105                	addi	sp,sp,32
    8000540e:	8082                	ret

0000000080005410 <sys_link>:
{
    80005410:	7169                	addi	sp,sp,-304
    80005412:	f606                	sd	ra,296(sp)
    80005414:	f222                	sd	s0,288(sp)
    80005416:	ee26                	sd	s1,280(sp)
    80005418:	ea4a                	sd	s2,272(sp)
    8000541a:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000541c:	08000613          	li	a2,128
    80005420:	ed040593          	addi	a1,s0,-304
    80005424:	4501                	li	a0,0
    80005426:	ffffd097          	auipc	ra,0xffffd
    8000542a:	772080e7          	jalr	1906(ra) # 80002b98 <argstr>
    return -1;
    8000542e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005430:	10054e63          	bltz	a0,8000554c <sys_link+0x13c>
    80005434:	08000613          	li	a2,128
    80005438:	f5040593          	addi	a1,s0,-176
    8000543c:	4505                	li	a0,1
    8000543e:	ffffd097          	auipc	ra,0xffffd
    80005442:	75a080e7          	jalr	1882(ra) # 80002b98 <argstr>
    return -1;
    80005446:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005448:	10054263          	bltz	a0,8000554c <sys_link+0x13c>
  begin_op();
    8000544c:	fffff097          	auipc	ra,0xfffff
    80005450:	d10080e7          	jalr	-752(ra) # 8000415c <begin_op>
  if((ip = namei(old)) == 0){
    80005454:	ed040513          	addi	a0,s0,-304
    80005458:	fffff097          	auipc	ra,0xfffff
    8000545c:	ae8080e7          	jalr	-1304(ra) # 80003f40 <namei>
    80005460:	84aa                	mv	s1,a0
    80005462:	c551                	beqz	a0,800054ee <sys_link+0xde>
  ilock(ip);
    80005464:	ffffe097          	auipc	ra,0xffffe
    80005468:	336080e7          	jalr	822(ra) # 8000379a <ilock>
  if(ip->type == T_DIR){
    8000546c:	04449703          	lh	a4,68(s1)
    80005470:	4785                	li	a5,1
    80005472:	08f70463          	beq	a4,a5,800054fa <sys_link+0xea>
  ip->nlink++;
    80005476:	04a4d783          	lhu	a5,74(s1)
    8000547a:	2785                	addiw	a5,a5,1
    8000547c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005480:	8526                	mv	a0,s1
    80005482:	ffffe097          	auipc	ra,0xffffe
    80005486:	24e080e7          	jalr	590(ra) # 800036d0 <iupdate>
  iunlock(ip);
    8000548a:	8526                	mv	a0,s1
    8000548c:	ffffe097          	auipc	ra,0xffffe
    80005490:	3d0080e7          	jalr	976(ra) # 8000385c <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005494:	fd040593          	addi	a1,s0,-48
    80005498:	f5040513          	addi	a0,s0,-176
    8000549c:	fffff097          	auipc	ra,0xfffff
    800054a0:	ac2080e7          	jalr	-1342(ra) # 80003f5e <nameiparent>
    800054a4:	892a                	mv	s2,a0
    800054a6:	c935                	beqz	a0,8000551a <sys_link+0x10a>
  ilock(dp);
    800054a8:	ffffe097          	auipc	ra,0xffffe
    800054ac:	2f2080e7          	jalr	754(ra) # 8000379a <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800054b0:	00092703          	lw	a4,0(s2)
    800054b4:	409c                	lw	a5,0(s1)
    800054b6:	04f71d63          	bne	a4,a5,80005510 <sys_link+0x100>
    800054ba:	40d0                	lw	a2,4(s1)
    800054bc:	fd040593          	addi	a1,s0,-48
    800054c0:	854a                	mv	a0,s2
    800054c2:	fffff097          	auipc	ra,0xfffff
    800054c6:	9cc080e7          	jalr	-1588(ra) # 80003e8e <dirlink>
    800054ca:	04054363          	bltz	a0,80005510 <sys_link+0x100>
  iunlockput(dp);
    800054ce:	854a                	mv	a0,s2
    800054d0:	ffffe097          	auipc	ra,0xffffe
    800054d4:	52c080e7          	jalr	1324(ra) # 800039fc <iunlockput>
  iput(ip);
    800054d8:	8526                	mv	a0,s1
    800054da:	ffffe097          	auipc	ra,0xffffe
    800054de:	47a080e7          	jalr	1146(ra) # 80003954 <iput>
  end_op();
    800054e2:	fffff097          	auipc	ra,0xfffff
    800054e6:	cfa080e7          	jalr	-774(ra) # 800041dc <end_op>
  return 0;
    800054ea:	4781                	li	a5,0
    800054ec:	a085                	j	8000554c <sys_link+0x13c>
    end_op();
    800054ee:	fffff097          	auipc	ra,0xfffff
    800054f2:	cee080e7          	jalr	-786(ra) # 800041dc <end_op>
    return -1;
    800054f6:	57fd                	li	a5,-1
    800054f8:	a891                	j	8000554c <sys_link+0x13c>
    iunlockput(ip);
    800054fa:	8526                	mv	a0,s1
    800054fc:	ffffe097          	auipc	ra,0xffffe
    80005500:	500080e7          	jalr	1280(ra) # 800039fc <iunlockput>
    end_op();
    80005504:	fffff097          	auipc	ra,0xfffff
    80005508:	cd8080e7          	jalr	-808(ra) # 800041dc <end_op>
    return -1;
    8000550c:	57fd                	li	a5,-1
    8000550e:	a83d                	j	8000554c <sys_link+0x13c>
    iunlockput(dp);
    80005510:	854a                	mv	a0,s2
    80005512:	ffffe097          	auipc	ra,0xffffe
    80005516:	4ea080e7          	jalr	1258(ra) # 800039fc <iunlockput>
  ilock(ip);
    8000551a:	8526                	mv	a0,s1
    8000551c:	ffffe097          	auipc	ra,0xffffe
    80005520:	27e080e7          	jalr	638(ra) # 8000379a <ilock>
  ip->nlink--;
    80005524:	04a4d783          	lhu	a5,74(s1)
    80005528:	37fd                	addiw	a5,a5,-1
    8000552a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000552e:	8526                	mv	a0,s1
    80005530:	ffffe097          	auipc	ra,0xffffe
    80005534:	1a0080e7          	jalr	416(ra) # 800036d0 <iupdate>
  iunlockput(ip);
    80005538:	8526                	mv	a0,s1
    8000553a:	ffffe097          	auipc	ra,0xffffe
    8000553e:	4c2080e7          	jalr	1218(ra) # 800039fc <iunlockput>
  end_op();
    80005542:	fffff097          	auipc	ra,0xfffff
    80005546:	c9a080e7          	jalr	-870(ra) # 800041dc <end_op>
  return -1;
    8000554a:	57fd                	li	a5,-1
}
    8000554c:	853e                	mv	a0,a5
    8000554e:	70b2                	ld	ra,296(sp)
    80005550:	7412                	ld	s0,288(sp)
    80005552:	64f2                	ld	s1,280(sp)
    80005554:	6952                	ld	s2,272(sp)
    80005556:	6155                	addi	sp,sp,304
    80005558:	8082                	ret

000000008000555a <sys_unlink>:
{
    8000555a:	7151                	addi	sp,sp,-240
    8000555c:	f586                	sd	ra,232(sp)
    8000555e:	f1a2                	sd	s0,224(sp)
    80005560:	eda6                	sd	s1,216(sp)
    80005562:	e9ca                	sd	s2,208(sp)
    80005564:	e5ce                	sd	s3,200(sp)
    80005566:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005568:	08000613          	li	a2,128
    8000556c:	f3040593          	addi	a1,s0,-208
    80005570:	4501                	li	a0,0
    80005572:	ffffd097          	auipc	ra,0xffffd
    80005576:	626080e7          	jalr	1574(ra) # 80002b98 <argstr>
    8000557a:	18054163          	bltz	a0,800056fc <sys_unlink+0x1a2>
  begin_op();
    8000557e:	fffff097          	auipc	ra,0xfffff
    80005582:	bde080e7          	jalr	-1058(ra) # 8000415c <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005586:	fb040593          	addi	a1,s0,-80
    8000558a:	f3040513          	addi	a0,s0,-208
    8000558e:	fffff097          	auipc	ra,0xfffff
    80005592:	9d0080e7          	jalr	-1584(ra) # 80003f5e <nameiparent>
    80005596:	84aa                	mv	s1,a0
    80005598:	c979                	beqz	a0,8000566e <sys_unlink+0x114>
  ilock(dp);
    8000559a:	ffffe097          	auipc	ra,0xffffe
    8000559e:	200080e7          	jalr	512(ra) # 8000379a <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800055a2:	00003597          	auipc	a1,0x3
    800055a6:	20658593          	addi	a1,a1,518 # 800087a8 <syscalls+0x2a8>
    800055aa:	fb040513          	addi	a0,s0,-80
    800055ae:	ffffe097          	auipc	ra,0xffffe
    800055b2:	6b6080e7          	jalr	1718(ra) # 80003c64 <namecmp>
    800055b6:	14050a63          	beqz	a0,8000570a <sys_unlink+0x1b0>
    800055ba:	00003597          	auipc	a1,0x3
    800055be:	1f658593          	addi	a1,a1,502 # 800087b0 <syscalls+0x2b0>
    800055c2:	fb040513          	addi	a0,s0,-80
    800055c6:	ffffe097          	auipc	ra,0xffffe
    800055ca:	69e080e7          	jalr	1694(ra) # 80003c64 <namecmp>
    800055ce:	12050e63          	beqz	a0,8000570a <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800055d2:	f2c40613          	addi	a2,s0,-212
    800055d6:	fb040593          	addi	a1,s0,-80
    800055da:	8526                	mv	a0,s1
    800055dc:	ffffe097          	auipc	ra,0xffffe
    800055e0:	6a2080e7          	jalr	1698(ra) # 80003c7e <dirlookup>
    800055e4:	892a                	mv	s2,a0
    800055e6:	12050263          	beqz	a0,8000570a <sys_unlink+0x1b0>
  ilock(ip);
    800055ea:	ffffe097          	auipc	ra,0xffffe
    800055ee:	1b0080e7          	jalr	432(ra) # 8000379a <ilock>
  if(ip->nlink < 1)
    800055f2:	04a91783          	lh	a5,74(s2)
    800055f6:	08f05263          	blez	a5,8000567a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800055fa:	04491703          	lh	a4,68(s2)
    800055fe:	4785                	li	a5,1
    80005600:	08f70563          	beq	a4,a5,8000568a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005604:	4641                	li	a2,16
    80005606:	4581                	li	a1,0
    80005608:	fc040513          	addi	a0,s0,-64
    8000560c:	ffffb097          	auipc	ra,0xffffb
    80005610:	6da080e7          	jalr	1754(ra) # 80000ce6 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005614:	4741                	li	a4,16
    80005616:	f2c42683          	lw	a3,-212(s0)
    8000561a:	fc040613          	addi	a2,s0,-64
    8000561e:	4581                	li	a1,0
    80005620:	8526                	mv	a0,s1
    80005622:	ffffe097          	auipc	ra,0xffffe
    80005626:	524080e7          	jalr	1316(ra) # 80003b46 <writei>
    8000562a:	47c1                	li	a5,16
    8000562c:	0af51563          	bne	a0,a5,800056d6 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005630:	04491703          	lh	a4,68(s2)
    80005634:	4785                	li	a5,1
    80005636:	0af70863          	beq	a4,a5,800056e6 <sys_unlink+0x18c>
  iunlockput(dp);
    8000563a:	8526                	mv	a0,s1
    8000563c:	ffffe097          	auipc	ra,0xffffe
    80005640:	3c0080e7          	jalr	960(ra) # 800039fc <iunlockput>
  ip->nlink--;
    80005644:	04a95783          	lhu	a5,74(s2)
    80005648:	37fd                	addiw	a5,a5,-1
    8000564a:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000564e:	854a                	mv	a0,s2
    80005650:	ffffe097          	auipc	ra,0xffffe
    80005654:	080080e7          	jalr	128(ra) # 800036d0 <iupdate>
  iunlockput(ip);
    80005658:	854a                	mv	a0,s2
    8000565a:	ffffe097          	auipc	ra,0xffffe
    8000565e:	3a2080e7          	jalr	930(ra) # 800039fc <iunlockput>
  end_op();
    80005662:	fffff097          	auipc	ra,0xfffff
    80005666:	b7a080e7          	jalr	-1158(ra) # 800041dc <end_op>
  return 0;
    8000566a:	4501                	li	a0,0
    8000566c:	a84d                	j	8000571e <sys_unlink+0x1c4>
    end_op();
    8000566e:	fffff097          	auipc	ra,0xfffff
    80005672:	b6e080e7          	jalr	-1170(ra) # 800041dc <end_op>
    return -1;
    80005676:	557d                	li	a0,-1
    80005678:	a05d                	j	8000571e <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000567a:	00003517          	auipc	a0,0x3
    8000567e:	13e50513          	addi	a0,a0,318 # 800087b8 <syscalls+0x2b8>
    80005682:	ffffb097          	auipc	ra,0xffffb
    80005686:	ec2080e7          	jalr	-318(ra) # 80000544 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000568a:	04c92703          	lw	a4,76(s2)
    8000568e:	02000793          	li	a5,32
    80005692:	f6e7f9e3          	bgeu	a5,a4,80005604 <sys_unlink+0xaa>
    80005696:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000569a:	4741                	li	a4,16
    8000569c:	86ce                	mv	a3,s3
    8000569e:	f1840613          	addi	a2,s0,-232
    800056a2:	4581                	li	a1,0
    800056a4:	854a                	mv	a0,s2
    800056a6:	ffffe097          	auipc	ra,0xffffe
    800056aa:	3a8080e7          	jalr	936(ra) # 80003a4e <readi>
    800056ae:	47c1                	li	a5,16
    800056b0:	00f51b63          	bne	a0,a5,800056c6 <sys_unlink+0x16c>
    if(de.inum != 0)
    800056b4:	f1845783          	lhu	a5,-232(s0)
    800056b8:	e7a1                	bnez	a5,80005700 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056ba:	29c1                	addiw	s3,s3,16
    800056bc:	04c92783          	lw	a5,76(s2)
    800056c0:	fcf9ede3          	bltu	s3,a5,8000569a <sys_unlink+0x140>
    800056c4:	b781                	j	80005604 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800056c6:	00003517          	auipc	a0,0x3
    800056ca:	10a50513          	addi	a0,a0,266 # 800087d0 <syscalls+0x2d0>
    800056ce:	ffffb097          	auipc	ra,0xffffb
    800056d2:	e76080e7          	jalr	-394(ra) # 80000544 <panic>
    panic("unlink: writei");
    800056d6:	00003517          	auipc	a0,0x3
    800056da:	11250513          	addi	a0,a0,274 # 800087e8 <syscalls+0x2e8>
    800056de:	ffffb097          	auipc	ra,0xffffb
    800056e2:	e66080e7          	jalr	-410(ra) # 80000544 <panic>
    dp->nlink--;
    800056e6:	04a4d783          	lhu	a5,74(s1)
    800056ea:	37fd                	addiw	a5,a5,-1
    800056ec:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800056f0:	8526                	mv	a0,s1
    800056f2:	ffffe097          	auipc	ra,0xffffe
    800056f6:	fde080e7          	jalr	-34(ra) # 800036d0 <iupdate>
    800056fa:	b781                	j	8000563a <sys_unlink+0xe0>
    return -1;
    800056fc:	557d                	li	a0,-1
    800056fe:	a005                	j	8000571e <sys_unlink+0x1c4>
    iunlockput(ip);
    80005700:	854a                	mv	a0,s2
    80005702:	ffffe097          	auipc	ra,0xffffe
    80005706:	2fa080e7          	jalr	762(ra) # 800039fc <iunlockput>
  iunlockput(dp);
    8000570a:	8526                	mv	a0,s1
    8000570c:	ffffe097          	auipc	ra,0xffffe
    80005710:	2f0080e7          	jalr	752(ra) # 800039fc <iunlockput>
  end_op();
    80005714:	fffff097          	auipc	ra,0xfffff
    80005718:	ac8080e7          	jalr	-1336(ra) # 800041dc <end_op>
  return -1;
    8000571c:	557d                	li	a0,-1
}
    8000571e:	70ae                	ld	ra,232(sp)
    80005720:	740e                	ld	s0,224(sp)
    80005722:	64ee                	ld	s1,216(sp)
    80005724:	694e                	ld	s2,208(sp)
    80005726:	69ae                	ld	s3,200(sp)
    80005728:	616d                	addi	sp,sp,240
    8000572a:	8082                	ret

000000008000572c <sys_open>:

uint64
sys_open(void)
{
    8000572c:	7131                	addi	sp,sp,-192
    8000572e:	fd06                	sd	ra,184(sp)
    80005730:	f922                	sd	s0,176(sp)
    80005732:	f526                	sd	s1,168(sp)
    80005734:	f14a                	sd	s2,160(sp)
    80005736:	ed4e                	sd	s3,152(sp)
    80005738:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    8000573a:	f4c40593          	addi	a1,s0,-180
    8000573e:	4505                	li	a0,1
    80005740:	ffffd097          	auipc	ra,0xffffd
    80005744:	418080e7          	jalr	1048(ra) # 80002b58 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005748:	08000613          	li	a2,128
    8000574c:	f5040593          	addi	a1,s0,-176
    80005750:	4501                	li	a0,0
    80005752:	ffffd097          	auipc	ra,0xffffd
    80005756:	446080e7          	jalr	1094(ra) # 80002b98 <argstr>
    8000575a:	87aa                	mv	a5,a0
    return -1;
    8000575c:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000575e:	0a07c963          	bltz	a5,80005810 <sys_open+0xe4>

  begin_op();
    80005762:	fffff097          	auipc	ra,0xfffff
    80005766:	9fa080e7          	jalr	-1542(ra) # 8000415c <begin_op>

  if(omode & O_CREATE){
    8000576a:	f4c42783          	lw	a5,-180(s0)
    8000576e:	2007f793          	andi	a5,a5,512
    80005772:	cfc5                	beqz	a5,8000582a <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005774:	4681                	li	a3,0
    80005776:	4601                	li	a2,0
    80005778:	4589                	li	a1,2
    8000577a:	f5040513          	addi	a0,s0,-176
    8000577e:	00000097          	auipc	ra,0x0
    80005782:	974080e7          	jalr	-1676(ra) # 800050f2 <create>
    80005786:	84aa                	mv	s1,a0
    if(ip == 0){
    80005788:	c959                	beqz	a0,8000581e <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000578a:	04449703          	lh	a4,68(s1)
    8000578e:	478d                	li	a5,3
    80005790:	00f71763          	bne	a4,a5,8000579e <sys_open+0x72>
    80005794:	0464d703          	lhu	a4,70(s1)
    80005798:	47a5                	li	a5,9
    8000579a:	0ce7ed63          	bltu	a5,a4,80005874 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000579e:	fffff097          	auipc	ra,0xfffff
    800057a2:	dce080e7          	jalr	-562(ra) # 8000456c <filealloc>
    800057a6:	89aa                	mv	s3,a0
    800057a8:	10050363          	beqz	a0,800058ae <sys_open+0x182>
    800057ac:	00000097          	auipc	ra,0x0
    800057b0:	904080e7          	jalr	-1788(ra) # 800050b0 <fdalloc>
    800057b4:	892a                	mv	s2,a0
    800057b6:	0e054763          	bltz	a0,800058a4 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800057ba:	04449703          	lh	a4,68(s1)
    800057be:	478d                	li	a5,3
    800057c0:	0cf70563          	beq	a4,a5,8000588a <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800057c4:	4789                	li	a5,2
    800057c6:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800057ca:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800057ce:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    800057d2:	f4c42783          	lw	a5,-180(s0)
    800057d6:	0017c713          	xori	a4,a5,1
    800057da:	8b05                	andi	a4,a4,1
    800057dc:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800057e0:	0037f713          	andi	a4,a5,3
    800057e4:	00e03733          	snez	a4,a4
    800057e8:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800057ec:	4007f793          	andi	a5,a5,1024
    800057f0:	c791                	beqz	a5,800057fc <sys_open+0xd0>
    800057f2:	04449703          	lh	a4,68(s1)
    800057f6:	4789                	li	a5,2
    800057f8:	0af70063          	beq	a4,a5,80005898 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800057fc:	8526                	mv	a0,s1
    800057fe:	ffffe097          	auipc	ra,0xffffe
    80005802:	05e080e7          	jalr	94(ra) # 8000385c <iunlock>
  end_op();
    80005806:	fffff097          	auipc	ra,0xfffff
    8000580a:	9d6080e7          	jalr	-1578(ra) # 800041dc <end_op>

  return fd;
    8000580e:	854a                	mv	a0,s2
}
    80005810:	70ea                	ld	ra,184(sp)
    80005812:	744a                	ld	s0,176(sp)
    80005814:	74aa                	ld	s1,168(sp)
    80005816:	790a                	ld	s2,160(sp)
    80005818:	69ea                	ld	s3,152(sp)
    8000581a:	6129                	addi	sp,sp,192
    8000581c:	8082                	ret
      end_op();
    8000581e:	fffff097          	auipc	ra,0xfffff
    80005822:	9be080e7          	jalr	-1602(ra) # 800041dc <end_op>
      return -1;
    80005826:	557d                	li	a0,-1
    80005828:	b7e5                	j	80005810 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000582a:	f5040513          	addi	a0,s0,-176
    8000582e:	ffffe097          	auipc	ra,0xffffe
    80005832:	712080e7          	jalr	1810(ra) # 80003f40 <namei>
    80005836:	84aa                	mv	s1,a0
    80005838:	c905                	beqz	a0,80005868 <sys_open+0x13c>
    ilock(ip);
    8000583a:	ffffe097          	auipc	ra,0xffffe
    8000583e:	f60080e7          	jalr	-160(ra) # 8000379a <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005842:	04449703          	lh	a4,68(s1)
    80005846:	4785                	li	a5,1
    80005848:	f4f711e3          	bne	a4,a5,8000578a <sys_open+0x5e>
    8000584c:	f4c42783          	lw	a5,-180(s0)
    80005850:	d7b9                	beqz	a5,8000579e <sys_open+0x72>
      iunlockput(ip);
    80005852:	8526                	mv	a0,s1
    80005854:	ffffe097          	auipc	ra,0xffffe
    80005858:	1a8080e7          	jalr	424(ra) # 800039fc <iunlockput>
      end_op();
    8000585c:	fffff097          	auipc	ra,0xfffff
    80005860:	980080e7          	jalr	-1664(ra) # 800041dc <end_op>
      return -1;
    80005864:	557d                	li	a0,-1
    80005866:	b76d                	j	80005810 <sys_open+0xe4>
      end_op();
    80005868:	fffff097          	auipc	ra,0xfffff
    8000586c:	974080e7          	jalr	-1676(ra) # 800041dc <end_op>
      return -1;
    80005870:	557d                	li	a0,-1
    80005872:	bf79                	j	80005810 <sys_open+0xe4>
    iunlockput(ip);
    80005874:	8526                	mv	a0,s1
    80005876:	ffffe097          	auipc	ra,0xffffe
    8000587a:	186080e7          	jalr	390(ra) # 800039fc <iunlockput>
    end_op();
    8000587e:	fffff097          	auipc	ra,0xfffff
    80005882:	95e080e7          	jalr	-1698(ra) # 800041dc <end_op>
    return -1;
    80005886:	557d                	li	a0,-1
    80005888:	b761                	j	80005810 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000588a:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000588e:	04649783          	lh	a5,70(s1)
    80005892:	02f99223          	sh	a5,36(s3)
    80005896:	bf25                	j	800057ce <sys_open+0xa2>
    itrunc(ip);
    80005898:	8526                	mv	a0,s1
    8000589a:	ffffe097          	auipc	ra,0xffffe
    8000589e:	00e080e7          	jalr	14(ra) # 800038a8 <itrunc>
    800058a2:	bfa9                	j	800057fc <sys_open+0xd0>
      fileclose(f);
    800058a4:	854e                	mv	a0,s3
    800058a6:	fffff097          	auipc	ra,0xfffff
    800058aa:	d82080e7          	jalr	-638(ra) # 80004628 <fileclose>
    iunlockput(ip);
    800058ae:	8526                	mv	a0,s1
    800058b0:	ffffe097          	auipc	ra,0xffffe
    800058b4:	14c080e7          	jalr	332(ra) # 800039fc <iunlockput>
    end_op();
    800058b8:	fffff097          	auipc	ra,0xfffff
    800058bc:	924080e7          	jalr	-1756(ra) # 800041dc <end_op>
    return -1;
    800058c0:	557d                	li	a0,-1
    800058c2:	b7b9                	j	80005810 <sys_open+0xe4>

00000000800058c4 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800058c4:	7175                	addi	sp,sp,-144
    800058c6:	e506                	sd	ra,136(sp)
    800058c8:	e122                	sd	s0,128(sp)
    800058ca:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800058cc:	fffff097          	auipc	ra,0xfffff
    800058d0:	890080e7          	jalr	-1904(ra) # 8000415c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800058d4:	08000613          	li	a2,128
    800058d8:	f7040593          	addi	a1,s0,-144
    800058dc:	4501                	li	a0,0
    800058de:	ffffd097          	auipc	ra,0xffffd
    800058e2:	2ba080e7          	jalr	698(ra) # 80002b98 <argstr>
    800058e6:	02054963          	bltz	a0,80005918 <sys_mkdir+0x54>
    800058ea:	4681                	li	a3,0
    800058ec:	4601                	li	a2,0
    800058ee:	4585                	li	a1,1
    800058f0:	f7040513          	addi	a0,s0,-144
    800058f4:	fffff097          	auipc	ra,0xfffff
    800058f8:	7fe080e7          	jalr	2046(ra) # 800050f2 <create>
    800058fc:	cd11                	beqz	a0,80005918 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058fe:	ffffe097          	auipc	ra,0xffffe
    80005902:	0fe080e7          	jalr	254(ra) # 800039fc <iunlockput>
  end_op();
    80005906:	fffff097          	auipc	ra,0xfffff
    8000590a:	8d6080e7          	jalr	-1834(ra) # 800041dc <end_op>
  return 0;
    8000590e:	4501                	li	a0,0
}
    80005910:	60aa                	ld	ra,136(sp)
    80005912:	640a                	ld	s0,128(sp)
    80005914:	6149                	addi	sp,sp,144
    80005916:	8082                	ret
    end_op();
    80005918:	fffff097          	auipc	ra,0xfffff
    8000591c:	8c4080e7          	jalr	-1852(ra) # 800041dc <end_op>
    return -1;
    80005920:	557d                	li	a0,-1
    80005922:	b7fd                	j	80005910 <sys_mkdir+0x4c>

0000000080005924 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005924:	7135                	addi	sp,sp,-160
    80005926:	ed06                	sd	ra,152(sp)
    80005928:	e922                	sd	s0,144(sp)
    8000592a:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000592c:	fffff097          	auipc	ra,0xfffff
    80005930:	830080e7          	jalr	-2000(ra) # 8000415c <begin_op>
  argint(1, &major);
    80005934:	f6c40593          	addi	a1,s0,-148
    80005938:	4505                	li	a0,1
    8000593a:	ffffd097          	auipc	ra,0xffffd
    8000593e:	21e080e7          	jalr	542(ra) # 80002b58 <argint>
  argint(2, &minor);
    80005942:	f6840593          	addi	a1,s0,-152
    80005946:	4509                	li	a0,2
    80005948:	ffffd097          	auipc	ra,0xffffd
    8000594c:	210080e7          	jalr	528(ra) # 80002b58 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005950:	08000613          	li	a2,128
    80005954:	f7040593          	addi	a1,s0,-144
    80005958:	4501                	li	a0,0
    8000595a:	ffffd097          	auipc	ra,0xffffd
    8000595e:	23e080e7          	jalr	574(ra) # 80002b98 <argstr>
    80005962:	02054b63          	bltz	a0,80005998 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005966:	f6841683          	lh	a3,-152(s0)
    8000596a:	f6c41603          	lh	a2,-148(s0)
    8000596e:	458d                	li	a1,3
    80005970:	f7040513          	addi	a0,s0,-144
    80005974:	fffff097          	auipc	ra,0xfffff
    80005978:	77e080e7          	jalr	1918(ra) # 800050f2 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000597c:	cd11                	beqz	a0,80005998 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000597e:	ffffe097          	auipc	ra,0xffffe
    80005982:	07e080e7          	jalr	126(ra) # 800039fc <iunlockput>
  end_op();
    80005986:	fffff097          	auipc	ra,0xfffff
    8000598a:	856080e7          	jalr	-1962(ra) # 800041dc <end_op>
  return 0;
    8000598e:	4501                	li	a0,0
}
    80005990:	60ea                	ld	ra,152(sp)
    80005992:	644a                	ld	s0,144(sp)
    80005994:	610d                	addi	sp,sp,160
    80005996:	8082                	ret
    end_op();
    80005998:	fffff097          	auipc	ra,0xfffff
    8000599c:	844080e7          	jalr	-1980(ra) # 800041dc <end_op>
    return -1;
    800059a0:	557d                	li	a0,-1
    800059a2:	b7fd                	j	80005990 <sys_mknod+0x6c>

00000000800059a4 <sys_chdir>:

uint64
sys_chdir(void)
{
    800059a4:	7135                	addi	sp,sp,-160
    800059a6:	ed06                	sd	ra,152(sp)
    800059a8:	e922                	sd	s0,144(sp)
    800059aa:	e526                	sd	s1,136(sp)
    800059ac:	e14a                	sd	s2,128(sp)
    800059ae:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800059b0:	ffffc097          	auipc	ra,0xffffc
    800059b4:	016080e7          	jalr	22(ra) # 800019c6 <myproc>
    800059b8:	892a                	mv	s2,a0
  
  begin_op();
    800059ba:	ffffe097          	auipc	ra,0xffffe
    800059be:	7a2080e7          	jalr	1954(ra) # 8000415c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800059c2:	08000613          	li	a2,128
    800059c6:	f6040593          	addi	a1,s0,-160
    800059ca:	4501                	li	a0,0
    800059cc:	ffffd097          	auipc	ra,0xffffd
    800059d0:	1cc080e7          	jalr	460(ra) # 80002b98 <argstr>
    800059d4:	04054b63          	bltz	a0,80005a2a <sys_chdir+0x86>
    800059d8:	f6040513          	addi	a0,s0,-160
    800059dc:	ffffe097          	auipc	ra,0xffffe
    800059e0:	564080e7          	jalr	1380(ra) # 80003f40 <namei>
    800059e4:	84aa                	mv	s1,a0
    800059e6:	c131                	beqz	a0,80005a2a <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800059e8:	ffffe097          	auipc	ra,0xffffe
    800059ec:	db2080e7          	jalr	-590(ra) # 8000379a <ilock>
  if(ip->type != T_DIR){
    800059f0:	04449703          	lh	a4,68(s1)
    800059f4:	4785                	li	a5,1
    800059f6:	04f71063          	bne	a4,a5,80005a36 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800059fa:	8526                	mv	a0,s1
    800059fc:	ffffe097          	auipc	ra,0xffffe
    80005a00:	e60080e7          	jalr	-416(ra) # 8000385c <iunlock>
  iput(p->cwd);
    80005a04:	15093503          	ld	a0,336(s2)
    80005a08:	ffffe097          	auipc	ra,0xffffe
    80005a0c:	f4c080e7          	jalr	-180(ra) # 80003954 <iput>
  end_op();
    80005a10:	ffffe097          	auipc	ra,0xffffe
    80005a14:	7cc080e7          	jalr	1996(ra) # 800041dc <end_op>
  p->cwd = ip;
    80005a18:	14993823          	sd	s1,336(s2)
  return 0;
    80005a1c:	4501                	li	a0,0
}
    80005a1e:	60ea                	ld	ra,152(sp)
    80005a20:	644a                	ld	s0,144(sp)
    80005a22:	64aa                	ld	s1,136(sp)
    80005a24:	690a                	ld	s2,128(sp)
    80005a26:	610d                	addi	sp,sp,160
    80005a28:	8082                	ret
    end_op();
    80005a2a:	ffffe097          	auipc	ra,0xffffe
    80005a2e:	7b2080e7          	jalr	1970(ra) # 800041dc <end_op>
    return -1;
    80005a32:	557d                	li	a0,-1
    80005a34:	b7ed                	j	80005a1e <sys_chdir+0x7a>
    iunlockput(ip);
    80005a36:	8526                	mv	a0,s1
    80005a38:	ffffe097          	auipc	ra,0xffffe
    80005a3c:	fc4080e7          	jalr	-60(ra) # 800039fc <iunlockput>
    end_op();
    80005a40:	ffffe097          	auipc	ra,0xffffe
    80005a44:	79c080e7          	jalr	1948(ra) # 800041dc <end_op>
    return -1;
    80005a48:	557d                	li	a0,-1
    80005a4a:	bfd1                	j	80005a1e <sys_chdir+0x7a>

0000000080005a4c <sys_exec>:

uint64
sys_exec(void)
{
    80005a4c:	7145                	addi	sp,sp,-464
    80005a4e:	e786                	sd	ra,456(sp)
    80005a50:	e3a2                	sd	s0,448(sp)
    80005a52:	ff26                	sd	s1,440(sp)
    80005a54:	fb4a                	sd	s2,432(sp)
    80005a56:	f74e                	sd	s3,424(sp)
    80005a58:	f352                	sd	s4,416(sp)
    80005a5a:	ef56                	sd	s5,408(sp)
    80005a5c:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005a5e:	e3840593          	addi	a1,s0,-456
    80005a62:	4505                	li	a0,1
    80005a64:	ffffd097          	auipc	ra,0xffffd
    80005a68:	114080e7          	jalr	276(ra) # 80002b78 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005a6c:	08000613          	li	a2,128
    80005a70:	f4040593          	addi	a1,s0,-192
    80005a74:	4501                	li	a0,0
    80005a76:	ffffd097          	auipc	ra,0xffffd
    80005a7a:	122080e7          	jalr	290(ra) # 80002b98 <argstr>
    80005a7e:	87aa                	mv	a5,a0
    return -1;
    80005a80:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005a82:	0c07c263          	bltz	a5,80005b46 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005a86:	10000613          	li	a2,256
    80005a8a:	4581                	li	a1,0
    80005a8c:	e4040513          	addi	a0,s0,-448
    80005a90:	ffffb097          	auipc	ra,0xffffb
    80005a94:	256080e7          	jalr	598(ra) # 80000ce6 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a98:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005a9c:	89a6                	mv	s3,s1
    80005a9e:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005aa0:	02000a13          	li	s4,32
    80005aa4:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005aa8:	00391513          	slli	a0,s2,0x3
    80005aac:	e3040593          	addi	a1,s0,-464
    80005ab0:	e3843783          	ld	a5,-456(s0)
    80005ab4:	953e                	add	a0,a0,a5
    80005ab6:	ffffd097          	auipc	ra,0xffffd
    80005aba:	004080e7          	jalr	4(ra) # 80002aba <fetchaddr>
    80005abe:	02054a63          	bltz	a0,80005af2 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005ac2:	e3043783          	ld	a5,-464(s0)
    80005ac6:	c3b9                	beqz	a5,80005b0c <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005ac8:	ffffb097          	auipc	ra,0xffffb
    80005acc:	032080e7          	jalr	50(ra) # 80000afa <kalloc>
    80005ad0:	85aa                	mv	a1,a0
    80005ad2:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005ad6:	cd11                	beqz	a0,80005af2 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005ad8:	6605                	lui	a2,0x1
    80005ada:	e3043503          	ld	a0,-464(s0)
    80005ade:	ffffd097          	auipc	ra,0xffffd
    80005ae2:	02e080e7          	jalr	46(ra) # 80002b0c <fetchstr>
    80005ae6:	00054663          	bltz	a0,80005af2 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005aea:	0905                	addi	s2,s2,1
    80005aec:	09a1                	addi	s3,s3,8
    80005aee:	fb491be3          	bne	s2,s4,80005aa4 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005af2:	10048913          	addi	s2,s1,256
    80005af6:	6088                	ld	a0,0(s1)
    80005af8:	c531                	beqz	a0,80005b44 <sys_exec+0xf8>
    kfree(argv[i]);
    80005afa:	ffffb097          	auipc	ra,0xffffb
    80005afe:	f04080e7          	jalr	-252(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b02:	04a1                	addi	s1,s1,8
    80005b04:	ff2499e3          	bne	s1,s2,80005af6 <sys_exec+0xaa>
  return -1;
    80005b08:	557d                	li	a0,-1
    80005b0a:	a835                	j	80005b46 <sys_exec+0xfa>
      argv[i] = 0;
    80005b0c:	0a8e                	slli	s5,s5,0x3
    80005b0e:	fc040793          	addi	a5,s0,-64
    80005b12:	9abe                	add	s5,s5,a5
    80005b14:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005b18:	e4040593          	addi	a1,s0,-448
    80005b1c:	f4040513          	addi	a0,s0,-192
    80005b20:	fffff097          	auipc	ra,0xfffff
    80005b24:	190080e7          	jalr	400(ra) # 80004cb0 <exec>
    80005b28:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b2a:	10048993          	addi	s3,s1,256
    80005b2e:	6088                	ld	a0,0(s1)
    80005b30:	c901                	beqz	a0,80005b40 <sys_exec+0xf4>
    kfree(argv[i]);
    80005b32:	ffffb097          	auipc	ra,0xffffb
    80005b36:	ecc080e7          	jalr	-308(ra) # 800009fe <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b3a:	04a1                	addi	s1,s1,8
    80005b3c:	ff3499e3          	bne	s1,s3,80005b2e <sys_exec+0xe2>
  return ret;
    80005b40:	854a                	mv	a0,s2
    80005b42:	a011                	j	80005b46 <sys_exec+0xfa>
  return -1;
    80005b44:	557d                	li	a0,-1
}
    80005b46:	60be                	ld	ra,456(sp)
    80005b48:	641e                	ld	s0,448(sp)
    80005b4a:	74fa                	ld	s1,440(sp)
    80005b4c:	795a                	ld	s2,432(sp)
    80005b4e:	79ba                	ld	s3,424(sp)
    80005b50:	7a1a                	ld	s4,416(sp)
    80005b52:	6afa                	ld	s5,408(sp)
    80005b54:	6179                	addi	sp,sp,464
    80005b56:	8082                	ret

0000000080005b58 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b58:	7139                	addi	sp,sp,-64
    80005b5a:	fc06                	sd	ra,56(sp)
    80005b5c:	f822                	sd	s0,48(sp)
    80005b5e:	f426                	sd	s1,40(sp)
    80005b60:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b62:	ffffc097          	auipc	ra,0xffffc
    80005b66:	e64080e7          	jalr	-412(ra) # 800019c6 <myproc>
    80005b6a:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005b6c:	fd840593          	addi	a1,s0,-40
    80005b70:	4501                	li	a0,0
    80005b72:	ffffd097          	auipc	ra,0xffffd
    80005b76:	006080e7          	jalr	6(ra) # 80002b78 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005b7a:	fc840593          	addi	a1,s0,-56
    80005b7e:	fd040513          	addi	a0,s0,-48
    80005b82:	fffff097          	auipc	ra,0xfffff
    80005b86:	dd6080e7          	jalr	-554(ra) # 80004958 <pipealloc>
    return -1;
    80005b8a:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b8c:	0c054463          	bltz	a0,80005c54 <sys_pipe+0xfc>
  fd0 = -1;
    80005b90:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b94:	fd043503          	ld	a0,-48(s0)
    80005b98:	fffff097          	auipc	ra,0xfffff
    80005b9c:	518080e7          	jalr	1304(ra) # 800050b0 <fdalloc>
    80005ba0:	fca42223          	sw	a0,-60(s0)
    80005ba4:	08054b63          	bltz	a0,80005c3a <sys_pipe+0xe2>
    80005ba8:	fc843503          	ld	a0,-56(s0)
    80005bac:	fffff097          	auipc	ra,0xfffff
    80005bb0:	504080e7          	jalr	1284(ra) # 800050b0 <fdalloc>
    80005bb4:	fca42023          	sw	a0,-64(s0)
    80005bb8:	06054863          	bltz	a0,80005c28 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bbc:	4691                	li	a3,4
    80005bbe:	fc440613          	addi	a2,s0,-60
    80005bc2:	fd843583          	ld	a1,-40(s0)
    80005bc6:	68a8                	ld	a0,80(s1)
    80005bc8:	ffffc097          	auipc	ra,0xffffc
    80005bcc:	abc080e7          	jalr	-1348(ra) # 80001684 <copyout>
    80005bd0:	02054063          	bltz	a0,80005bf0 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005bd4:	4691                	li	a3,4
    80005bd6:	fc040613          	addi	a2,s0,-64
    80005bda:	fd843583          	ld	a1,-40(s0)
    80005bde:	0591                	addi	a1,a1,4
    80005be0:	68a8                	ld	a0,80(s1)
    80005be2:	ffffc097          	auipc	ra,0xffffc
    80005be6:	aa2080e7          	jalr	-1374(ra) # 80001684 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005bea:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bec:	06055463          	bgez	a0,80005c54 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005bf0:	fc442783          	lw	a5,-60(s0)
    80005bf4:	07e9                	addi	a5,a5,26
    80005bf6:	078e                	slli	a5,a5,0x3
    80005bf8:	97a6                	add	a5,a5,s1
    80005bfa:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005bfe:	fc042503          	lw	a0,-64(s0)
    80005c02:	0569                	addi	a0,a0,26
    80005c04:	050e                	slli	a0,a0,0x3
    80005c06:	94aa                	add	s1,s1,a0
    80005c08:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005c0c:	fd043503          	ld	a0,-48(s0)
    80005c10:	fffff097          	auipc	ra,0xfffff
    80005c14:	a18080e7          	jalr	-1512(ra) # 80004628 <fileclose>
    fileclose(wf);
    80005c18:	fc843503          	ld	a0,-56(s0)
    80005c1c:	fffff097          	auipc	ra,0xfffff
    80005c20:	a0c080e7          	jalr	-1524(ra) # 80004628 <fileclose>
    return -1;
    80005c24:	57fd                	li	a5,-1
    80005c26:	a03d                	j	80005c54 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005c28:	fc442783          	lw	a5,-60(s0)
    80005c2c:	0007c763          	bltz	a5,80005c3a <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005c30:	07e9                	addi	a5,a5,26
    80005c32:	078e                	slli	a5,a5,0x3
    80005c34:	94be                	add	s1,s1,a5
    80005c36:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005c3a:	fd043503          	ld	a0,-48(s0)
    80005c3e:	fffff097          	auipc	ra,0xfffff
    80005c42:	9ea080e7          	jalr	-1558(ra) # 80004628 <fileclose>
    fileclose(wf);
    80005c46:	fc843503          	ld	a0,-56(s0)
    80005c4a:	fffff097          	auipc	ra,0xfffff
    80005c4e:	9de080e7          	jalr	-1570(ra) # 80004628 <fileclose>
    return -1;
    80005c52:	57fd                	li	a5,-1
}
    80005c54:	853e                	mv	a0,a5
    80005c56:	70e2                	ld	ra,56(sp)
    80005c58:	7442                	ld	s0,48(sp)
    80005c5a:	74a2                	ld	s1,40(sp)
    80005c5c:	6121                	addi	sp,sp,64
    80005c5e:	8082                	ret

0000000080005c60 <kernelvec>:
    80005c60:	7111                	addi	sp,sp,-256
    80005c62:	e006                	sd	ra,0(sp)
    80005c64:	e40a                	sd	sp,8(sp)
    80005c66:	e80e                	sd	gp,16(sp)
    80005c68:	ec12                	sd	tp,24(sp)
    80005c6a:	f016                	sd	t0,32(sp)
    80005c6c:	f41a                	sd	t1,40(sp)
    80005c6e:	f81e                	sd	t2,48(sp)
    80005c70:	fc22                	sd	s0,56(sp)
    80005c72:	e0a6                	sd	s1,64(sp)
    80005c74:	e4aa                	sd	a0,72(sp)
    80005c76:	e8ae                	sd	a1,80(sp)
    80005c78:	ecb2                	sd	a2,88(sp)
    80005c7a:	f0b6                	sd	a3,96(sp)
    80005c7c:	f4ba                	sd	a4,104(sp)
    80005c7e:	f8be                	sd	a5,112(sp)
    80005c80:	fcc2                	sd	a6,120(sp)
    80005c82:	e146                	sd	a7,128(sp)
    80005c84:	e54a                	sd	s2,136(sp)
    80005c86:	e94e                	sd	s3,144(sp)
    80005c88:	ed52                	sd	s4,152(sp)
    80005c8a:	f156                	sd	s5,160(sp)
    80005c8c:	f55a                	sd	s6,168(sp)
    80005c8e:	f95e                	sd	s7,176(sp)
    80005c90:	fd62                	sd	s8,184(sp)
    80005c92:	e1e6                	sd	s9,192(sp)
    80005c94:	e5ea                	sd	s10,200(sp)
    80005c96:	e9ee                	sd	s11,208(sp)
    80005c98:	edf2                	sd	t3,216(sp)
    80005c9a:	f1f6                	sd	t4,224(sp)
    80005c9c:	f5fa                	sd	t5,232(sp)
    80005c9e:	f9fe                	sd	t6,240(sp)
    80005ca0:	ce7fc0ef          	jal	ra,80002986 <kerneltrap>
    80005ca4:	6082                	ld	ra,0(sp)
    80005ca6:	6122                	ld	sp,8(sp)
    80005ca8:	61c2                	ld	gp,16(sp)
    80005caa:	7282                	ld	t0,32(sp)
    80005cac:	7322                	ld	t1,40(sp)
    80005cae:	73c2                	ld	t2,48(sp)
    80005cb0:	7462                	ld	s0,56(sp)
    80005cb2:	6486                	ld	s1,64(sp)
    80005cb4:	6526                	ld	a0,72(sp)
    80005cb6:	65c6                	ld	a1,80(sp)
    80005cb8:	6666                	ld	a2,88(sp)
    80005cba:	7686                	ld	a3,96(sp)
    80005cbc:	7726                	ld	a4,104(sp)
    80005cbe:	77c6                	ld	a5,112(sp)
    80005cc0:	7866                	ld	a6,120(sp)
    80005cc2:	688a                	ld	a7,128(sp)
    80005cc4:	692a                	ld	s2,136(sp)
    80005cc6:	69ca                	ld	s3,144(sp)
    80005cc8:	6a6a                	ld	s4,152(sp)
    80005cca:	7a8a                	ld	s5,160(sp)
    80005ccc:	7b2a                	ld	s6,168(sp)
    80005cce:	7bca                	ld	s7,176(sp)
    80005cd0:	7c6a                	ld	s8,184(sp)
    80005cd2:	6c8e                	ld	s9,192(sp)
    80005cd4:	6d2e                	ld	s10,200(sp)
    80005cd6:	6dce                	ld	s11,208(sp)
    80005cd8:	6e6e                	ld	t3,216(sp)
    80005cda:	7e8e                	ld	t4,224(sp)
    80005cdc:	7f2e                	ld	t5,232(sp)
    80005cde:	7fce                	ld	t6,240(sp)
    80005ce0:	6111                	addi	sp,sp,256
    80005ce2:	10200073          	sret
    80005ce6:	00000013          	nop
    80005cea:	00000013          	nop
    80005cee:	0001                	nop

0000000080005cf0 <timervec>:
    80005cf0:	34051573          	csrrw	a0,mscratch,a0
    80005cf4:	e10c                	sd	a1,0(a0)
    80005cf6:	e510                	sd	a2,8(a0)
    80005cf8:	e914                	sd	a3,16(a0)
    80005cfa:	6d0c                	ld	a1,24(a0)
    80005cfc:	7110                	ld	a2,32(a0)
    80005cfe:	6194                	ld	a3,0(a1)
    80005d00:	96b2                	add	a3,a3,a2
    80005d02:	e194                	sd	a3,0(a1)
    80005d04:	4589                	li	a1,2
    80005d06:	14459073          	csrw	sip,a1
    80005d0a:	6914                	ld	a3,16(a0)
    80005d0c:	6510                	ld	a2,8(a0)
    80005d0e:	610c                	ld	a1,0(a0)
    80005d10:	34051573          	csrrw	a0,mscratch,a0
    80005d14:	30200073          	mret
	...

0000000080005d1a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d1a:	1141                	addi	sp,sp,-16
    80005d1c:	e422                	sd	s0,8(sp)
    80005d1e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d20:	0c0007b7          	lui	a5,0xc000
    80005d24:	4705                	li	a4,1
    80005d26:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d28:	c3d8                	sw	a4,4(a5)
}
    80005d2a:	6422                	ld	s0,8(sp)
    80005d2c:	0141                	addi	sp,sp,16
    80005d2e:	8082                	ret

0000000080005d30 <plicinithart>:

void
plicinithart(void)
{
    80005d30:	1141                	addi	sp,sp,-16
    80005d32:	e406                	sd	ra,8(sp)
    80005d34:	e022                	sd	s0,0(sp)
    80005d36:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d38:	ffffc097          	auipc	ra,0xffffc
    80005d3c:	c62080e7          	jalr	-926(ra) # 8000199a <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d40:	0085171b          	slliw	a4,a0,0x8
    80005d44:	0c0027b7          	lui	a5,0xc002
    80005d48:	97ba                	add	a5,a5,a4
    80005d4a:	40200713          	li	a4,1026
    80005d4e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d52:	00d5151b          	slliw	a0,a0,0xd
    80005d56:	0c2017b7          	lui	a5,0xc201
    80005d5a:	953e                	add	a0,a0,a5
    80005d5c:	00052023          	sw	zero,0(a0)
}
    80005d60:	60a2                	ld	ra,8(sp)
    80005d62:	6402                	ld	s0,0(sp)
    80005d64:	0141                	addi	sp,sp,16
    80005d66:	8082                	ret

0000000080005d68 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d68:	1141                	addi	sp,sp,-16
    80005d6a:	e406                	sd	ra,8(sp)
    80005d6c:	e022                	sd	s0,0(sp)
    80005d6e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d70:	ffffc097          	auipc	ra,0xffffc
    80005d74:	c2a080e7          	jalr	-982(ra) # 8000199a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d78:	00d5179b          	slliw	a5,a0,0xd
    80005d7c:	0c201537          	lui	a0,0xc201
    80005d80:	953e                	add	a0,a0,a5
  return irq;
}
    80005d82:	4148                	lw	a0,4(a0)
    80005d84:	60a2                	ld	ra,8(sp)
    80005d86:	6402                	ld	s0,0(sp)
    80005d88:	0141                	addi	sp,sp,16
    80005d8a:	8082                	ret

0000000080005d8c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d8c:	1101                	addi	sp,sp,-32
    80005d8e:	ec06                	sd	ra,24(sp)
    80005d90:	e822                	sd	s0,16(sp)
    80005d92:	e426                	sd	s1,8(sp)
    80005d94:	1000                	addi	s0,sp,32
    80005d96:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005d98:	ffffc097          	auipc	ra,0xffffc
    80005d9c:	c02080e7          	jalr	-1022(ra) # 8000199a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005da0:	00d5151b          	slliw	a0,a0,0xd
    80005da4:	0c2017b7          	lui	a5,0xc201
    80005da8:	97aa                	add	a5,a5,a0
    80005daa:	c3c4                	sw	s1,4(a5)
}
    80005dac:	60e2                	ld	ra,24(sp)
    80005dae:	6442                	ld	s0,16(sp)
    80005db0:	64a2                	ld	s1,8(sp)
    80005db2:	6105                	addi	sp,sp,32
    80005db4:	8082                	ret

0000000080005db6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005db6:	1141                	addi	sp,sp,-16
    80005db8:	e406                	sd	ra,8(sp)
    80005dba:	e022                	sd	s0,0(sp)
    80005dbc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005dbe:	479d                	li	a5,7
    80005dc0:	04a7cc63          	blt	a5,a0,80005e18 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005dc4:	00028797          	auipc	a5,0x28
    80005dc8:	2dc78793          	addi	a5,a5,732 # 8002e0a0 <disk>
    80005dcc:	97aa                	add	a5,a5,a0
    80005dce:	0187c783          	lbu	a5,24(a5)
    80005dd2:	ebb9                	bnez	a5,80005e28 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005dd4:	00451613          	slli	a2,a0,0x4
    80005dd8:	00028797          	auipc	a5,0x28
    80005ddc:	2c878793          	addi	a5,a5,712 # 8002e0a0 <disk>
    80005de0:	6394                	ld	a3,0(a5)
    80005de2:	96b2                	add	a3,a3,a2
    80005de4:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005de8:	6398                	ld	a4,0(a5)
    80005dea:	9732                	add	a4,a4,a2
    80005dec:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005df0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005df4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005df8:	953e                	add	a0,a0,a5
    80005dfa:	4785                	li	a5,1
    80005dfc:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80005e00:	00028517          	auipc	a0,0x28
    80005e04:	2b850513          	addi	a0,a0,696 # 8002e0b8 <disk+0x18>
    80005e08:	ffffc097          	auipc	ra,0xffffc
    80005e0c:	348080e7          	jalr	840(ra) # 80002150 <wakeup>
}
    80005e10:	60a2                	ld	ra,8(sp)
    80005e12:	6402                	ld	s0,0(sp)
    80005e14:	0141                	addi	sp,sp,16
    80005e16:	8082                	ret
    panic("free_desc 1");
    80005e18:	00003517          	auipc	a0,0x3
    80005e1c:	9e050513          	addi	a0,a0,-1568 # 800087f8 <syscalls+0x2f8>
    80005e20:	ffffa097          	auipc	ra,0xffffa
    80005e24:	724080e7          	jalr	1828(ra) # 80000544 <panic>
    panic("free_desc 2");
    80005e28:	00003517          	auipc	a0,0x3
    80005e2c:	9e050513          	addi	a0,a0,-1568 # 80008808 <syscalls+0x308>
    80005e30:	ffffa097          	auipc	ra,0xffffa
    80005e34:	714080e7          	jalr	1812(ra) # 80000544 <panic>

0000000080005e38 <virtio_disk_init>:
{
    80005e38:	1101                	addi	sp,sp,-32
    80005e3a:	ec06                	sd	ra,24(sp)
    80005e3c:	e822                	sd	s0,16(sp)
    80005e3e:	e426                	sd	s1,8(sp)
    80005e40:	e04a                	sd	s2,0(sp)
    80005e42:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e44:	00003597          	auipc	a1,0x3
    80005e48:	9d458593          	addi	a1,a1,-1580 # 80008818 <syscalls+0x318>
    80005e4c:	00028517          	auipc	a0,0x28
    80005e50:	37c50513          	addi	a0,a0,892 # 8002e1c8 <disk+0x128>
    80005e54:	ffffb097          	auipc	ra,0xffffb
    80005e58:	d06080e7          	jalr	-762(ra) # 80000b5a <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e5c:	100017b7          	lui	a5,0x10001
    80005e60:	4398                	lw	a4,0(a5)
    80005e62:	2701                	sext.w	a4,a4
    80005e64:	747277b7          	lui	a5,0x74727
    80005e68:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e6c:	14f71e63          	bne	a4,a5,80005fc8 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005e70:	100017b7          	lui	a5,0x10001
    80005e74:	43dc                	lw	a5,4(a5)
    80005e76:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e78:	4709                	li	a4,2
    80005e7a:	14e79763          	bne	a5,a4,80005fc8 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e7e:	100017b7          	lui	a5,0x10001
    80005e82:	479c                	lw	a5,8(a5)
    80005e84:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005e86:	14e79163          	bne	a5,a4,80005fc8 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005e8a:	100017b7          	lui	a5,0x10001
    80005e8e:	47d8                	lw	a4,12(a5)
    80005e90:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e92:	554d47b7          	lui	a5,0x554d4
    80005e96:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005e9a:	12f71763          	bne	a4,a5,80005fc8 <virtio_disk_init+0x190>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e9e:	100017b7          	lui	a5,0x10001
    80005ea2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ea6:	4705                	li	a4,1
    80005ea8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eaa:	470d                	li	a4,3
    80005eac:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005eae:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005eb0:	c7ffe737          	lui	a4,0xc7ffe
    80005eb4:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd057f>
    80005eb8:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005eba:	2701                	sext.w	a4,a4
    80005ebc:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ebe:	472d                	li	a4,11
    80005ec0:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005ec2:	0707a903          	lw	s2,112(a5)
    80005ec6:	2901                	sext.w	s2,s2
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005ec8:	00897793          	andi	a5,s2,8
    80005ecc:	10078663          	beqz	a5,80005fd8 <virtio_disk_init+0x1a0>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005ed0:	100017b7          	lui	a5,0x10001
    80005ed4:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005ed8:	43fc                	lw	a5,68(a5)
    80005eda:	2781                	sext.w	a5,a5
    80005edc:	10079663          	bnez	a5,80005fe8 <virtio_disk_init+0x1b0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005ee0:	100017b7          	lui	a5,0x10001
    80005ee4:	5bdc                	lw	a5,52(a5)
    80005ee6:	2781                	sext.w	a5,a5
  if(max == 0)
    80005ee8:	10078863          	beqz	a5,80005ff8 <virtio_disk_init+0x1c0>
  if(max < NUM)
    80005eec:	471d                	li	a4,7
    80005eee:	10f77d63          	bgeu	a4,a5,80006008 <virtio_disk_init+0x1d0>
  disk.desc = kalloc();
    80005ef2:	ffffb097          	auipc	ra,0xffffb
    80005ef6:	c08080e7          	jalr	-1016(ra) # 80000afa <kalloc>
    80005efa:	00028497          	auipc	s1,0x28
    80005efe:	1a648493          	addi	s1,s1,422 # 8002e0a0 <disk>
    80005f02:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005f04:	ffffb097          	auipc	ra,0xffffb
    80005f08:	bf6080e7          	jalr	-1034(ra) # 80000afa <kalloc>
    80005f0c:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005f0e:	ffffb097          	auipc	ra,0xffffb
    80005f12:	bec080e7          	jalr	-1044(ra) # 80000afa <kalloc>
    80005f16:	87aa                	mv	a5,a0
    80005f18:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005f1a:	6088                	ld	a0,0(s1)
    80005f1c:	cd75                	beqz	a0,80006018 <virtio_disk_init+0x1e0>
    80005f1e:	00028717          	auipc	a4,0x28
    80005f22:	18a73703          	ld	a4,394(a4) # 8002e0a8 <disk+0x8>
    80005f26:	cb6d                	beqz	a4,80006018 <virtio_disk_init+0x1e0>
    80005f28:	cbe5                	beqz	a5,80006018 <virtio_disk_init+0x1e0>
  memset(disk.desc, 0, PGSIZE);
    80005f2a:	6605                	lui	a2,0x1
    80005f2c:	4581                	li	a1,0
    80005f2e:	ffffb097          	auipc	ra,0xffffb
    80005f32:	db8080e7          	jalr	-584(ra) # 80000ce6 <memset>
  memset(disk.avail, 0, PGSIZE);
    80005f36:	00028497          	auipc	s1,0x28
    80005f3a:	16a48493          	addi	s1,s1,362 # 8002e0a0 <disk>
    80005f3e:	6605                	lui	a2,0x1
    80005f40:	4581                	li	a1,0
    80005f42:	6488                	ld	a0,8(s1)
    80005f44:	ffffb097          	auipc	ra,0xffffb
    80005f48:	da2080e7          	jalr	-606(ra) # 80000ce6 <memset>
  memset(disk.used, 0, PGSIZE);
    80005f4c:	6605                	lui	a2,0x1
    80005f4e:	4581                	li	a1,0
    80005f50:	6888                	ld	a0,16(s1)
    80005f52:	ffffb097          	auipc	ra,0xffffb
    80005f56:	d94080e7          	jalr	-620(ra) # 80000ce6 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f5a:	100017b7          	lui	a5,0x10001
    80005f5e:	4721                	li	a4,8
    80005f60:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005f62:	4098                	lw	a4,0(s1)
    80005f64:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005f68:	40d8                	lw	a4,4(s1)
    80005f6a:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005f6e:	6498                	ld	a4,8(s1)
    80005f70:	0007069b          	sext.w	a3,a4
    80005f74:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005f78:	9701                	srai	a4,a4,0x20
    80005f7a:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005f7e:	6898                	ld	a4,16(s1)
    80005f80:	0007069b          	sext.w	a3,a4
    80005f84:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005f88:	9701                	srai	a4,a4,0x20
    80005f8a:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80005f8e:	4685                	li	a3,1
    80005f90:	c3f4                	sw	a3,68(a5)
    disk.free[i] = 1;
    80005f92:	4705                	li	a4,1
    80005f94:	00d48c23          	sb	a3,24(s1)
    80005f98:	00e48ca3          	sb	a4,25(s1)
    80005f9c:	00e48d23          	sb	a4,26(s1)
    80005fa0:	00e48da3          	sb	a4,27(s1)
    80005fa4:	00e48e23          	sb	a4,28(s1)
    80005fa8:	00e48ea3          	sb	a4,29(s1)
    80005fac:	00e48f23          	sb	a4,30(s1)
    80005fb0:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005fb4:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fb8:	0727a823          	sw	s2,112(a5)
}
    80005fbc:	60e2                	ld	ra,24(sp)
    80005fbe:	6442                	ld	s0,16(sp)
    80005fc0:	64a2                	ld	s1,8(sp)
    80005fc2:	6902                	ld	s2,0(sp)
    80005fc4:	6105                	addi	sp,sp,32
    80005fc6:	8082                	ret
    panic("could not find virtio disk");
    80005fc8:	00003517          	auipc	a0,0x3
    80005fcc:	86050513          	addi	a0,a0,-1952 # 80008828 <syscalls+0x328>
    80005fd0:	ffffa097          	auipc	ra,0xffffa
    80005fd4:	574080e7          	jalr	1396(ra) # 80000544 <panic>
    panic("virtio disk FEATURES_OK unset");
    80005fd8:	00003517          	auipc	a0,0x3
    80005fdc:	87050513          	addi	a0,a0,-1936 # 80008848 <syscalls+0x348>
    80005fe0:	ffffa097          	auipc	ra,0xffffa
    80005fe4:	564080e7          	jalr	1380(ra) # 80000544 <panic>
    panic("virtio disk should not be ready");
    80005fe8:	00003517          	auipc	a0,0x3
    80005fec:	88050513          	addi	a0,a0,-1920 # 80008868 <syscalls+0x368>
    80005ff0:	ffffa097          	auipc	ra,0xffffa
    80005ff4:	554080e7          	jalr	1364(ra) # 80000544 <panic>
    panic("virtio disk has no queue 0");
    80005ff8:	00003517          	auipc	a0,0x3
    80005ffc:	89050513          	addi	a0,a0,-1904 # 80008888 <syscalls+0x388>
    80006000:	ffffa097          	auipc	ra,0xffffa
    80006004:	544080e7          	jalr	1348(ra) # 80000544 <panic>
    panic("virtio disk max queue too short");
    80006008:	00003517          	auipc	a0,0x3
    8000600c:	8a050513          	addi	a0,a0,-1888 # 800088a8 <syscalls+0x3a8>
    80006010:	ffffa097          	auipc	ra,0xffffa
    80006014:	534080e7          	jalr	1332(ra) # 80000544 <panic>
    panic("virtio disk kalloc");
    80006018:	00003517          	auipc	a0,0x3
    8000601c:	8b050513          	addi	a0,a0,-1872 # 800088c8 <syscalls+0x3c8>
    80006020:	ffffa097          	auipc	ra,0xffffa
    80006024:	524080e7          	jalr	1316(ra) # 80000544 <panic>

0000000080006028 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006028:	7159                	addi	sp,sp,-112
    8000602a:	f486                	sd	ra,104(sp)
    8000602c:	f0a2                	sd	s0,96(sp)
    8000602e:	eca6                	sd	s1,88(sp)
    80006030:	e8ca                	sd	s2,80(sp)
    80006032:	e4ce                	sd	s3,72(sp)
    80006034:	e0d2                	sd	s4,64(sp)
    80006036:	fc56                	sd	s5,56(sp)
    80006038:	f85a                	sd	s6,48(sp)
    8000603a:	f45e                	sd	s7,40(sp)
    8000603c:	f062                	sd	s8,32(sp)
    8000603e:	ec66                	sd	s9,24(sp)
    80006040:	e86a                	sd	s10,16(sp)
    80006042:	1880                	addi	s0,sp,112
    80006044:	892a                	mv	s2,a0
    80006046:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006048:	00c52c83          	lw	s9,12(a0)
    8000604c:	001c9c9b          	slliw	s9,s9,0x1
    80006050:	1c82                	slli	s9,s9,0x20
    80006052:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006056:	00028517          	auipc	a0,0x28
    8000605a:	17250513          	addi	a0,a0,370 # 8002e1c8 <disk+0x128>
    8000605e:	ffffb097          	auipc	ra,0xffffb
    80006062:	b8c080e7          	jalr	-1140(ra) # 80000bea <acquire>
  for(int i = 0; i < 3; i++){
    80006066:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006068:	4ba1                	li	s7,8
      disk.free[i] = 0;
    8000606a:	00028b17          	auipc	s6,0x28
    8000606e:	036b0b13          	addi	s6,s6,54 # 8002e0a0 <disk>
  for(int i = 0; i < 3; i++){
    80006072:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006074:	8a4e                	mv	s4,s3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006076:	00028c17          	auipc	s8,0x28
    8000607a:	152c0c13          	addi	s8,s8,338 # 8002e1c8 <disk+0x128>
    8000607e:	a8b5                	j	800060fa <virtio_disk_rw+0xd2>
      disk.free[i] = 0;
    80006080:	00fb06b3          	add	a3,s6,a5
    80006084:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006088:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    8000608a:	0207c563          	bltz	a5,800060b4 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    8000608e:	2485                	addiw	s1,s1,1
    80006090:	0711                	addi	a4,a4,4
    80006092:	1f548a63          	beq	s1,s5,80006286 <virtio_disk_rw+0x25e>
    idx[i] = alloc_desc();
    80006096:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006098:	00028697          	auipc	a3,0x28
    8000609c:	00868693          	addi	a3,a3,8 # 8002e0a0 <disk>
    800060a0:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800060a2:	0186c583          	lbu	a1,24(a3)
    800060a6:	fde9                	bnez	a1,80006080 <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    800060a8:	2785                	addiw	a5,a5,1
    800060aa:	0685                	addi	a3,a3,1
    800060ac:	ff779be3          	bne	a5,s7,800060a2 <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    800060b0:	57fd                	li	a5,-1
    800060b2:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800060b4:	02905a63          	blez	s1,800060e8 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    800060b8:	f9042503          	lw	a0,-112(s0)
    800060bc:	00000097          	auipc	ra,0x0
    800060c0:	cfa080e7          	jalr	-774(ra) # 80005db6 <free_desc>
      for(int j = 0; j < i; j++)
    800060c4:	4785                	li	a5,1
    800060c6:	0297d163          	bge	a5,s1,800060e8 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    800060ca:	f9442503          	lw	a0,-108(s0)
    800060ce:	00000097          	auipc	ra,0x0
    800060d2:	ce8080e7          	jalr	-792(ra) # 80005db6 <free_desc>
      for(int j = 0; j < i; j++)
    800060d6:	4789                	li	a5,2
    800060d8:	0097d863          	bge	a5,s1,800060e8 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    800060dc:	f9842503          	lw	a0,-104(s0)
    800060e0:	00000097          	auipc	ra,0x0
    800060e4:	cd6080e7          	jalr	-810(ra) # 80005db6 <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800060e8:	85e2                	mv	a1,s8
    800060ea:	00028517          	auipc	a0,0x28
    800060ee:	fce50513          	addi	a0,a0,-50 # 8002e0b8 <disk+0x18>
    800060f2:	ffffc097          	auipc	ra,0xffffc
    800060f6:	ffa080e7          	jalr	-6(ra) # 800020ec <sleep>
  for(int i = 0; i < 3; i++){
    800060fa:	f9040713          	addi	a4,s0,-112
    800060fe:	84ce                	mv	s1,s3
    80006100:	bf59                	j	80006096 <virtio_disk_rw+0x6e>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006102:	00a60793          	addi	a5,a2,10 # 100a <_entry-0x7fffeff6>
    80006106:	00479693          	slli	a3,a5,0x4
    8000610a:	00028797          	auipc	a5,0x28
    8000610e:	f9678793          	addi	a5,a5,-106 # 8002e0a0 <disk>
    80006112:	97b6                	add	a5,a5,a3
    80006114:	4685                	li	a3,1
    80006116:	c794                	sw	a3,8(a5)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006118:	00028597          	auipc	a1,0x28
    8000611c:	f8858593          	addi	a1,a1,-120 # 8002e0a0 <disk>
    80006120:	00a60793          	addi	a5,a2,10
    80006124:	0792                	slli	a5,a5,0x4
    80006126:	97ae                	add	a5,a5,a1
    80006128:	0007a623          	sw	zero,12(a5)
  buf0->sector = sector;
    8000612c:	0197b823          	sd	s9,16(a5)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006130:	f6070693          	addi	a3,a4,-160
    80006134:	619c                	ld	a5,0(a1)
    80006136:	97b6                	add	a5,a5,a3
    80006138:	e388                	sd	a0,0(a5)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000613a:	6188                	ld	a0,0(a1)
    8000613c:	96aa                	add	a3,a3,a0
    8000613e:	47c1                	li	a5,16
    80006140:	c69c                	sw	a5,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006142:	4785                	li	a5,1
    80006144:	00f69623          	sh	a5,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006148:	f9442783          	lw	a5,-108(s0)
    8000614c:	00f69723          	sh	a5,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006150:	0792                	slli	a5,a5,0x4
    80006152:	953e                	add	a0,a0,a5
    80006154:	05890693          	addi	a3,s2,88
    80006158:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000615a:	6188                	ld	a0,0(a1)
    8000615c:	97aa                	add	a5,a5,a0
    8000615e:	40000693          	li	a3,1024
    80006162:	c794                	sw	a3,8(a5)
  if(write)
    80006164:	100d0d63          	beqz	s10,8000627e <virtio_disk_rw+0x256>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006168:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000616c:	00c7d683          	lhu	a3,12(a5)
    80006170:	0016e693          	ori	a3,a3,1
    80006174:	00d79623          	sh	a3,12(a5)
  disk.desc[idx[1]].next = idx[2];
    80006178:	f9842583          	lw	a1,-104(s0)
    8000617c:	00b79723          	sh	a1,14(a5)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006180:	00028697          	auipc	a3,0x28
    80006184:	f2068693          	addi	a3,a3,-224 # 8002e0a0 <disk>
    80006188:	00260793          	addi	a5,a2,2
    8000618c:	0792                	slli	a5,a5,0x4
    8000618e:	97b6                	add	a5,a5,a3
    80006190:	587d                	li	a6,-1
    80006192:	01078823          	sb	a6,16(a5)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006196:	0592                	slli	a1,a1,0x4
    80006198:	952e                	add	a0,a0,a1
    8000619a:	f9070713          	addi	a4,a4,-112
    8000619e:	9736                	add	a4,a4,a3
    800061a0:	e118                	sd	a4,0(a0)
  disk.desc[idx[2]].len = 1;
    800061a2:	6298                	ld	a4,0(a3)
    800061a4:	972e                	add	a4,a4,a1
    800061a6:	4585                	li	a1,1
    800061a8:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800061aa:	4509                	li	a0,2
    800061ac:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[2]].next = 0;
    800061b0:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800061b4:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    800061b8:	0127b423          	sd	s2,8(a5)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800061bc:	6698                	ld	a4,8(a3)
    800061be:	00275783          	lhu	a5,2(a4)
    800061c2:	8b9d                	andi	a5,a5,7
    800061c4:	0786                	slli	a5,a5,0x1
    800061c6:	97ba                	add	a5,a5,a4
    800061c8:	00c79223          	sh	a2,4(a5)

  __sync_synchronize();
    800061cc:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800061d0:	6698                	ld	a4,8(a3)
    800061d2:	00275783          	lhu	a5,2(a4)
    800061d6:	2785                	addiw	a5,a5,1
    800061d8:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800061dc:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800061e0:	100017b7          	lui	a5,0x10001
    800061e4:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800061e8:	00492703          	lw	a4,4(s2)
    800061ec:	4785                	li	a5,1
    800061ee:	02f71163          	bne	a4,a5,80006210 <virtio_disk_rw+0x1e8>
    sleep(b, &disk.vdisk_lock);
    800061f2:	00028997          	auipc	s3,0x28
    800061f6:	fd698993          	addi	s3,s3,-42 # 8002e1c8 <disk+0x128>
  while(b->disk == 1) {
    800061fa:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800061fc:	85ce                	mv	a1,s3
    800061fe:	854a                	mv	a0,s2
    80006200:	ffffc097          	auipc	ra,0xffffc
    80006204:	eec080e7          	jalr	-276(ra) # 800020ec <sleep>
  while(b->disk == 1) {
    80006208:	00492783          	lw	a5,4(s2)
    8000620c:	fe9788e3          	beq	a5,s1,800061fc <virtio_disk_rw+0x1d4>
  }

  disk.info[idx[0]].b = 0;
    80006210:	f9042903          	lw	s2,-112(s0)
    80006214:	00290793          	addi	a5,s2,2
    80006218:	00479713          	slli	a4,a5,0x4
    8000621c:	00028797          	auipc	a5,0x28
    80006220:	e8478793          	addi	a5,a5,-380 # 8002e0a0 <disk>
    80006224:	97ba                	add	a5,a5,a4
    80006226:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000622a:	00028997          	auipc	s3,0x28
    8000622e:	e7698993          	addi	s3,s3,-394 # 8002e0a0 <disk>
    80006232:	00491713          	slli	a4,s2,0x4
    80006236:	0009b783          	ld	a5,0(s3)
    8000623a:	97ba                	add	a5,a5,a4
    8000623c:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006240:	854a                	mv	a0,s2
    80006242:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006246:	00000097          	auipc	ra,0x0
    8000624a:	b70080e7          	jalr	-1168(ra) # 80005db6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000624e:	8885                	andi	s1,s1,1
    80006250:	f0ed                	bnez	s1,80006232 <virtio_disk_rw+0x20a>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006252:	00028517          	auipc	a0,0x28
    80006256:	f7650513          	addi	a0,a0,-138 # 8002e1c8 <disk+0x128>
    8000625a:	ffffb097          	auipc	ra,0xffffb
    8000625e:	a44080e7          	jalr	-1468(ra) # 80000c9e <release>
}
    80006262:	70a6                	ld	ra,104(sp)
    80006264:	7406                	ld	s0,96(sp)
    80006266:	64e6                	ld	s1,88(sp)
    80006268:	6946                	ld	s2,80(sp)
    8000626a:	69a6                	ld	s3,72(sp)
    8000626c:	6a06                	ld	s4,64(sp)
    8000626e:	7ae2                	ld	s5,56(sp)
    80006270:	7b42                	ld	s6,48(sp)
    80006272:	7ba2                	ld	s7,40(sp)
    80006274:	7c02                	ld	s8,32(sp)
    80006276:	6ce2                	ld	s9,24(sp)
    80006278:	6d42                	ld	s10,16(sp)
    8000627a:	6165                	addi	sp,sp,112
    8000627c:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000627e:	4689                	li	a3,2
    80006280:	00d79623          	sh	a3,12(a5)
    80006284:	b5e5                	j	8000616c <virtio_disk_rw+0x144>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006286:	f9042603          	lw	a2,-112(s0)
    8000628a:	00a60713          	addi	a4,a2,10
    8000628e:	0712                	slli	a4,a4,0x4
    80006290:	00028517          	auipc	a0,0x28
    80006294:	e1850513          	addi	a0,a0,-488 # 8002e0a8 <disk+0x8>
    80006298:	953a                	add	a0,a0,a4
  if(write)
    8000629a:	e60d14e3          	bnez	s10,80006102 <virtio_disk_rw+0xda>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    8000629e:	00a60793          	addi	a5,a2,10
    800062a2:	00479693          	slli	a3,a5,0x4
    800062a6:	00028797          	auipc	a5,0x28
    800062aa:	dfa78793          	addi	a5,a5,-518 # 8002e0a0 <disk>
    800062ae:	97b6                	add	a5,a5,a3
    800062b0:	0007a423          	sw	zero,8(a5)
    800062b4:	b595                	j	80006118 <virtio_disk_rw+0xf0>

00000000800062b6 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800062b6:	1101                	addi	sp,sp,-32
    800062b8:	ec06                	sd	ra,24(sp)
    800062ba:	e822                	sd	s0,16(sp)
    800062bc:	e426                	sd	s1,8(sp)
    800062be:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800062c0:	00028497          	auipc	s1,0x28
    800062c4:	de048493          	addi	s1,s1,-544 # 8002e0a0 <disk>
    800062c8:	00028517          	auipc	a0,0x28
    800062cc:	f0050513          	addi	a0,a0,-256 # 8002e1c8 <disk+0x128>
    800062d0:	ffffb097          	auipc	ra,0xffffb
    800062d4:	91a080e7          	jalr	-1766(ra) # 80000bea <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800062d8:	10001737          	lui	a4,0x10001
    800062dc:	533c                	lw	a5,96(a4)
    800062de:	8b8d                	andi	a5,a5,3
    800062e0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800062e2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800062e6:	689c                	ld	a5,16(s1)
    800062e8:	0204d703          	lhu	a4,32(s1)
    800062ec:	0027d783          	lhu	a5,2(a5)
    800062f0:	04f70863          	beq	a4,a5,80006340 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800062f4:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800062f8:	6898                	ld	a4,16(s1)
    800062fa:	0204d783          	lhu	a5,32(s1)
    800062fe:	8b9d                	andi	a5,a5,7
    80006300:	078e                	slli	a5,a5,0x3
    80006302:	97ba                	add	a5,a5,a4
    80006304:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006306:	00278713          	addi	a4,a5,2
    8000630a:	0712                	slli	a4,a4,0x4
    8000630c:	9726                	add	a4,a4,s1
    8000630e:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006312:	e721                	bnez	a4,8000635a <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006314:	0789                	addi	a5,a5,2
    80006316:	0792                	slli	a5,a5,0x4
    80006318:	97a6                	add	a5,a5,s1
    8000631a:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000631c:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006320:	ffffc097          	auipc	ra,0xffffc
    80006324:	e30080e7          	jalr	-464(ra) # 80002150 <wakeup>

    disk.used_idx += 1;
    80006328:	0204d783          	lhu	a5,32(s1)
    8000632c:	2785                	addiw	a5,a5,1
    8000632e:	17c2                	slli	a5,a5,0x30
    80006330:	93c1                	srli	a5,a5,0x30
    80006332:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006336:	6898                	ld	a4,16(s1)
    80006338:	00275703          	lhu	a4,2(a4)
    8000633c:	faf71ce3          	bne	a4,a5,800062f4 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006340:	00028517          	auipc	a0,0x28
    80006344:	e8850513          	addi	a0,a0,-376 # 8002e1c8 <disk+0x128>
    80006348:	ffffb097          	auipc	ra,0xffffb
    8000634c:	956080e7          	jalr	-1706(ra) # 80000c9e <release>
}
    80006350:	60e2                	ld	ra,24(sp)
    80006352:	6442                	ld	s0,16(sp)
    80006354:	64a2                	ld	s1,8(sp)
    80006356:	6105                	addi	sp,sp,32
    80006358:	8082                	ret
      panic("virtio_disk_intr status");
    8000635a:	00002517          	auipc	a0,0x2
    8000635e:	58650513          	addi	a0,a0,1414 # 800088e0 <syscalls+0x3e0>
    80006362:	ffffa097          	auipc	ra,0xffffa
    80006366:	1e2080e7          	jalr	482(ra) # 80000544 <panic>

000000008000636a <init_list_head>:
#include "defs.h"
#include "spinlock.h"
#include "proc.h"

void init_list_head(struct list_head *list)
{
    8000636a:	1141                	addi	sp,sp,-16
    8000636c:	e422                	sd	s0,8(sp)
    8000636e:	0800                	addi	s0,sp,16
  list->next = list;
    80006370:	e108                	sd	a0,0(a0)
  list->prev = list;
    80006372:	e508                	sd	a0,8(a0)
}
    80006374:	6422                	ld	s0,8(sp)
    80006376:	0141                	addi	sp,sp,16
    80006378:	8082                	ret

000000008000637a <list_add>:
  next->prev = prev;
  prev->next = next;
}

void list_add(struct list_head *head, struct list_head *new)
{
    8000637a:	1141                	addi	sp,sp,-16
    8000637c:	e422                	sd	s0,8(sp)
    8000637e:	0800                	addi	s0,sp,16
  __list_add(new, head, head->next);
    80006380:	611c                	ld	a5,0(a0)
  next->prev = new;
    80006382:	e78c                	sd	a1,8(a5)
  new->next = next;
    80006384:	e19c                	sd	a5,0(a1)
  new->prev = prev;
    80006386:	e588                	sd	a0,8(a1)
  prev->next = new;
    80006388:	e10c                	sd	a1,0(a0)
}
    8000638a:	6422                	ld	s0,8(sp)
    8000638c:	0141                	addi	sp,sp,16
    8000638e:	8082                	ret

0000000080006390 <list_add_tail>:

void list_add_tail(struct list_head *head, struct list_head *new)
{
    80006390:	1141                	addi	sp,sp,-16
    80006392:	e422                	sd	s0,8(sp)
    80006394:	0800                	addi	s0,sp,16
  __list_add(new, head->prev, head);
    80006396:	651c                	ld	a5,8(a0)
  next->prev = new;
    80006398:	e50c                	sd	a1,8(a0)
  new->next = next;
    8000639a:	e188                	sd	a0,0(a1)
  new->prev = prev;
    8000639c:	e59c                	sd	a5,8(a1)
  prev->next = new;
    8000639e:	e38c                	sd	a1,0(a5)
}
    800063a0:	6422                	ld	s0,8(sp)
    800063a2:	0141                	addi	sp,sp,16
    800063a4:	8082                	ret

00000000800063a6 <list_del>:

void list_del(struct list_head *entry)
{
    800063a6:	1141                	addi	sp,sp,-16
    800063a8:	e422                	sd	s0,8(sp)
    800063aa:	0800                	addi	s0,sp,16
  __list_del(entry->prev, entry->next);
    800063ac:	651c                	ld	a5,8(a0)
    800063ae:	6118                	ld	a4,0(a0)
  next->prev = prev;
    800063b0:	e71c                	sd	a5,8(a4)
  prev->next = next;
    800063b2:	e398                	sd	a4,0(a5)
  entry->prev = entry->next = entry;
    800063b4:	e108                	sd	a0,0(a0)
    800063b6:	e508                	sd	a0,8(a0)
}
    800063b8:	6422                	ld	s0,8(sp)
    800063ba:	0141                	addi	sp,sp,16
    800063bc:	8082                	ret

00000000800063be <list_del_init>:

void list_del_init(struct list_head *entry)
{
    800063be:	1141                	addi	sp,sp,-16
    800063c0:	e422                	sd	s0,8(sp)
    800063c2:	0800                	addi	s0,sp,16
  __list_del(entry->prev, entry->next);
    800063c4:	651c                	ld	a5,8(a0)
    800063c6:	6118                	ld	a4,0(a0)
  next->prev = prev;
    800063c8:	e71c                	sd	a5,8(a4)
  prev->next = next;
    800063ca:	e398                	sd	a4,0(a5)
  list->next = list;
    800063cc:	e108                	sd	a0,0(a0)
  list->prev = list;
    800063ce:	e508                	sd	a0,8(a0)
  init_list_head(entry);
}
    800063d0:	6422                	ld	s0,8(sp)
    800063d2:	0141                	addi	sp,sp,16
    800063d4:	8082                	ret

00000000800063d6 <write_to_logs>:
#include "file.h"
#include "fcntl.h"
#include "file_helper.h"
#include "audit_list.h"

void write_to_logs(void *list){
    800063d6:	1101                	addi	sp,sp,-32
    800063d8:	ec06                	sd	ra,24(sp)
    800063da:	e822                	sd	s0,16(sp)
    800063dc:	e426                	sd	s1,8(sp)
    800063de:	1000                	addi	s0,sp,32

    struct file *f;
    char *filename = "/AuditLogs.txt";
    f = open(filename, O_CREATE);
    800063e0:	20000593          	li	a1,512
    800063e4:	00002517          	auipc	a0,0x2
    800063e8:	51450513          	addi	a0,a0,1300 # 800088f8 <syscalls+0x3f8>
    800063ec:	00000097          	auipc	ra,0x0
    800063f0:	3dc080e7          	jalr	988(ra) # 800067c8 <open>

    f = open(filename, O_RDWR);
    800063f4:	4589                	li	a1,2
    800063f6:	00002517          	auipc	a0,0x2
    800063fa:	50250513          	addi	a0,a0,1282 # 800088f8 <syscalls+0x3f8>
    800063fe:	00000097          	auipc	ra,0x0
    80006402:	3ca080e7          	jalr	970(ra) # 800067c8 <open>

    if(f == (struct file *)-1)
    80006406:	57fd                	li	a5,-1
    80006408:	04f50f63          	beq	a0,a5,80006466 <write_to_logs+0x90>
    8000640c:	84aa                	mv	s1,a0
        panic("ERROR FILE");

    if(f == (struct file *)0) {
    8000640e:	c525                	beqz	a0,80006476 <write_to_logs+0xa0>
        panic("No File");
    }
    printf("6\n");
    80006410:	00002517          	auipc	a0,0x2
    80006414:	51050513          	addi	a0,a0,1296 # 80008920 <syscalls+0x420>
    80006418:	ffffa097          	auipc	ra,0xffffa
    8000641c:	176080e7          	jalr	374(ra) # 8000058e <printf>
    char *temp = "happy\n";
    printf("writable: %d\n", f -> writable);
    80006420:	0094c583          	lbu	a1,9(s1)
    80006424:	00002517          	auipc	a0,0x2
    80006428:	50450513          	addi	a0,a0,1284 # 80008928 <syscalls+0x428>
    8000642c:	ffffa097          	auipc	ra,0xffffa
    80006430:	162080e7          	jalr	354(ra) # 8000058e <printf>

    if (kfilewrite(f, (uint64)(temp), 7) <= 0){
    80006434:	461d                	li	a2,7
    80006436:	00002597          	auipc	a1,0x2
    8000643a:	50258593          	addi	a1,a1,1282 # 80008938 <syscalls+0x438>
    8000643e:	8526                	mv	a0,s1
    80006440:	00000097          	auipc	ra,0x0
    80006444:	058080e7          	jalr	88(ra) # 80006498 <kfilewrite>
    80006448:	02a05f63          	blez	a0,80006486 <write_to_logs+0xb0>

        printf("What\n");
    }

    printf("What1\n");
    8000644c:	00002517          	auipc	a0,0x2
    80006450:	4fc50513          	addi	a0,a0,1276 # 80008948 <syscalls+0x448>
    80006454:	ffffa097          	auipc	ra,0xffffa
    80006458:	13a080e7          	jalr	314(ra) # 8000058e <printf>

}
    8000645c:	60e2                	ld	ra,24(sp)
    8000645e:	6442                	ld	s0,16(sp)
    80006460:	64a2                	ld	s1,8(sp)
    80006462:	6105                	addi	sp,sp,32
    80006464:	8082                	ret
        panic("ERROR FILE");
    80006466:	00002517          	auipc	a0,0x2
    8000646a:	4a250513          	addi	a0,a0,1186 # 80008908 <syscalls+0x408>
    8000646e:	ffffa097          	auipc	ra,0xffffa
    80006472:	0d6080e7          	jalr	214(ra) # 80000544 <panic>
        panic("No File");
    80006476:	00002517          	auipc	a0,0x2
    8000647a:	4a250513          	addi	a0,a0,1186 # 80008918 <syscalls+0x418>
    8000647e:	ffffa097          	auipc	ra,0xffffa
    80006482:	0c6080e7          	jalr	198(ra) # 80000544 <panic>
        printf("What\n");
    80006486:	00002517          	auipc	a0,0x2
    8000648a:	4ba50513          	addi	a0,a0,1210 # 80008940 <syscalls+0x440>
    8000648e:	ffffa097          	auipc	ra,0xffffa
    80006492:	100080e7          	jalr	256(ra) # 8000058e <printf>
    80006496:	bf5d                	j	8000644c <write_to_logs+0x76>

0000000080006498 <kfilewrite>:



int
kfilewrite(struct file *f, uint64 addr, int n)
{
    80006498:	715d                	addi	sp,sp,-80
    8000649a:	e486                	sd	ra,72(sp)
    8000649c:	e0a2                	sd	s0,64(sp)
    8000649e:	fc26                	sd	s1,56(sp)
    800064a0:	f84a                	sd	s2,48(sp)
    800064a2:	f44e                	sd	s3,40(sp)
    800064a4:	f052                	sd	s4,32(sp)
    800064a6:	ec56                	sd	s5,24(sp)
    800064a8:	e85a                	sd	s6,16(sp)
    800064aa:	e45e                	sd	s7,8(sp)
    800064ac:	e062                	sd	s8,0(sp)
    800064ae:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0){
    800064b0:	00954783          	lbu	a5,9(a0)
    800064b4:	cb85                	beqz	a5,800064e4 <kfilewrite+0x4c>
    800064b6:	892a                	mv	s2,a0
    800064b8:	8aae                	mv	s5,a1
    800064ba:	8a32                	mv	s4,a2
    printf("First\n");
    return -1;
  }
  if(f->type == FD_PIPE){
    800064bc:	411c                	lw	a5,0(a0)
    800064be:	4705                	li	a4,1
    800064c0:	02e78c63          	beq	a5,a4,800064f8 <kfilewrite+0x60>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800064c4:	470d                	li	a4,3
    800064c6:	04e78063          	beq	a5,a4,80006506 <kfilewrite+0x6e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write){
      return -1;
    }
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800064ca:	4709                	li	a4,2
    800064cc:	0ee79b63          	bne	a5,a4,800065c2 <kfilewrite+0x12a>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800064d0:	0cc05763          	blez	a2,8000659e <kfilewrite+0x106>
    int i = 0;
    800064d4:	4981                	li	s3,0
    800064d6:	6b05                	lui	s6,0x1
    800064d8:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800064dc:	6b85                	lui	s7,0x1
    800064de:	c00b8b9b          	addiw	s7,s7,-1024
    800064e2:	a075                	j	8000658e <kfilewrite+0xf6>
    printf("First\n");
    800064e4:	00002517          	auipc	a0,0x2
    800064e8:	46c50513          	addi	a0,a0,1132 # 80008950 <syscalls+0x450>
    800064ec:	ffffa097          	auipc	ra,0xffffa
    800064f0:	0a2080e7          	jalr	162(ra) # 8000058e <printf>
    return -1;
    800064f4:	5a7d                	li	s4,-1
    800064f6:	a07d                	j	800065a4 <kfilewrite+0x10c>
    ret = pipewrite(f->pipe, addr, n);
    800064f8:	6908                	ld	a0,16(a0)
    800064fa:	ffffe097          	auipc	ra,0xffffe
    800064fe:	5a8080e7          	jalr	1448(ra) # 80004aa2 <pipewrite>
    80006502:	8a2a                	mv	s4,a0
    80006504:	a045                	j	800065a4 <kfilewrite+0x10c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write){
    80006506:	02451783          	lh	a5,36(a0)
    8000650a:	03079693          	slli	a3,a5,0x30
    8000650e:	92c1                	srli	a3,a3,0x30
    80006510:	4725                	li	a4,9
    80006512:	0cd76063          	bltu	a4,a3,800065d2 <kfilewrite+0x13a>
    80006516:	0792                	slli	a5,a5,0x4
    80006518:	00027717          	auipc	a4,0x27
    8000651c:	b3070713          	addi	a4,a4,-1232 # 8002d048 <devsw>
    80006520:	97ba                	add	a5,a5,a4
    80006522:	679c                	ld	a5,8(a5)
    80006524:	cbcd                	beqz	a5,800065d6 <kfilewrite+0x13e>
    ret = devsw[f->major].write(1, addr, n);
    80006526:	4505                	li	a0,1
    80006528:	9782                	jalr	a5
    8000652a:	8a2a                	mv	s4,a0
    8000652c:	a8a5                	j	800065a4 <kfilewrite+0x10c>
    8000652e:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80006532:	ffffe097          	auipc	ra,0xffffe
    80006536:	c2a080e7          	jalr	-982(ra) # 8000415c <begin_op>
      ilock(f->ip);
    8000653a:	01893503          	ld	a0,24(s2)
    8000653e:	ffffd097          	auipc	ra,0xffffd
    80006542:	25c080e7          	jalr	604(ra) # 8000379a <ilock>
      if ((r = writei(f->ip, 0, addr + i, f->off, n1)) > 0)
    80006546:	8762                	mv	a4,s8
    80006548:	02092683          	lw	a3,32(s2)
    8000654c:	01598633          	add	a2,s3,s5
    80006550:	4581                	li	a1,0
    80006552:	01893503          	ld	a0,24(s2)
    80006556:	ffffd097          	auipc	ra,0xffffd
    8000655a:	5f0080e7          	jalr	1520(ra) # 80003b46 <writei>
    8000655e:	84aa                	mv	s1,a0
    80006560:	00a05763          	blez	a0,8000656e <kfilewrite+0xd6>
        f->off += r;
    80006564:	02092783          	lw	a5,32(s2)
    80006568:	9fa9                	addw	a5,a5,a0
    8000656a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000656e:	01893503          	ld	a0,24(s2)
    80006572:	ffffd097          	auipc	ra,0xffffd
    80006576:	2ea080e7          	jalr	746(ra) # 8000385c <iunlock>
      end_op();
    8000657a:	ffffe097          	auipc	ra,0xffffe
    8000657e:	c62080e7          	jalr	-926(ra) # 800041dc <end_op>

      if(r != n1){
    80006582:	009c1f63          	bne	s8,s1,800065a0 <kfilewrite+0x108>
        // error from writei
        break;
      }
      i += r;
    80006586:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000658a:	0149db63          	bge	s3,s4,800065a0 <kfilewrite+0x108>
      int n1 = n - i;
    8000658e:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80006592:	84be                	mv	s1,a5
    80006594:	2781                	sext.w	a5,a5
    80006596:	f8fb5ce3          	bge	s6,a5,8000652e <kfilewrite+0x96>
    8000659a:	84de                	mv	s1,s7
    8000659c:	bf49                	j	8000652e <kfilewrite+0x96>
    int i = 0;
    8000659e:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800065a0:	013a1f63          	bne	s4,s3,800065be <kfilewrite+0x126>
  } else {
    panic("filewrite");
  }
  return ret;
}
    800065a4:	8552                	mv	a0,s4
    800065a6:	60a6                	ld	ra,72(sp)
    800065a8:	6406                	ld	s0,64(sp)
    800065aa:	74e2                	ld	s1,56(sp)
    800065ac:	7942                	ld	s2,48(sp)
    800065ae:	79a2                	ld	s3,40(sp)
    800065b0:	7a02                	ld	s4,32(sp)
    800065b2:	6ae2                	ld	s5,24(sp)
    800065b4:	6b42                	ld	s6,16(sp)
    800065b6:	6ba2                	ld	s7,8(sp)
    800065b8:	6c02                	ld	s8,0(sp)
    800065ba:	6161                	addi	sp,sp,80
    800065bc:	8082                	ret
    ret = (i == n ? n : -1);
    800065be:	5a7d                	li	s4,-1
    800065c0:	b7d5                	j	800065a4 <kfilewrite+0x10c>
    panic("filewrite");
    800065c2:	00002517          	auipc	a0,0x2
    800065c6:	1b650513          	addi	a0,a0,438 # 80008778 <syscalls+0x278>
    800065ca:	ffffa097          	auipc	ra,0xffffa
    800065ce:	f7a080e7          	jalr	-134(ra) # 80000544 <panic>
      return -1;
    800065d2:	5a7d                	li	s4,-1
    800065d4:	bfc1                	j	800065a4 <kfilewrite+0x10c>
    800065d6:	5a7d                	li	s4,-1
    800065d8:	b7f1                	j	800065a4 <kfilewrite+0x10c>

00000000800065da <fdalloc>:

int
fdalloc(struct file *f)
{
    800065da:	1101                	addi	sp,sp,-32
    800065dc:	ec06                	sd	ra,24(sp)
    800065de:	e822                	sd	s0,16(sp)
    800065e0:	e426                	sd	s1,8(sp)
    800065e2:	1000                	addi	s0,sp,32
    800065e4:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800065e6:	ffffb097          	auipc	ra,0xffffb
    800065ea:	3e0080e7          	jalr	992(ra) # 800019c6 <myproc>
    800065ee:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800065f0:	0d050793          	addi	a5,a0,208
    800065f4:	4501                	li	a0,0
    800065f6:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800065f8:	6398                	ld	a4,0(a5)
    800065fa:	cb19                	beqz	a4,80006610 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800065fc:	2505                	addiw	a0,a0,1
    800065fe:	07a1                	addi	a5,a5,8
    80006600:	fed51ce3          	bne	a0,a3,800065f8 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80006604:	557d                	li	a0,-1
}
    80006606:	60e2                	ld	ra,24(sp)
    80006608:	6442                	ld	s0,16(sp)
    8000660a:	64a2                	ld	s1,8(sp)
    8000660c:	6105                	addi	sp,sp,32
    8000660e:	8082                	ret
      p->ofile[fd] = f;
    80006610:	01a50793          	addi	a5,a0,26
    80006614:	078e                	slli	a5,a5,0x3
    80006616:	963e                	add	a2,a2,a5
    80006618:	e204                	sd	s1,0(a2)
      return fd;
    8000661a:	b7f5                	j	80006606 <fdalloc+0x2c>

000000008000661c <create>:

struct inode*
create(char *path, short type, short major, short minor)
{
    8000661c:	715d                	addi	sp,sp,-80
    8000661e:	e486                	sd	ra,72(sp)
    80006620:	e0a2                	sd	s0,64(sp)
    80006622:	fc26                	sd	s1,56(sp)
    80006624:	f84a                	sd	s2,48(sp)
    80006626:	f44e                	sd	s3,40(sp)
    80006628:	f052                	sd	s4,32(sp)
    8000662a:	ec56                	sd	s5,24(sp)
    8000662c:	e85a                	sd	s6,16(sp)
    8000662e:	0880                	addi	s0,sp,80
    80006630:	8b2e                	mv	s6,a1
    80006632:	89b2                	mv	s3,a2
    80006634:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80006636:	fb040593          	addi	a1,s0,-80
    8000663a:	ffffe097          	auipc	ra,0xffffe
    8000663e:	924080e7          	jalr	-1756(ra) # 80003f5e <nameiparent>
    80006642:	84aa                	mv	s1,a0
    80006644:	18050063          	beqz	a0,800067c4 <create+0x1a8>
    return 0;

  ilock(dp);
    80006648:	ffffd097          	auipc	ra,0xffffd
    8000664c:	152080e7          	jalr	338(ra) # 8000379a <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80006650:	4601                	li	a2,0
    80006652:	fb040593          	addi	a1,s0,-80
    80006656:	8526                	mv	a0,s1
    80006658:	ffffd097          	auipc	ra,0xffffd
    8000665c:	626080e7          	jalr	1574(ra) # 80003c7e <dirlookup>
    80006660:	8aaa                	mv	s5,a0
    80006662:	c931                	beqz	a0,800066b6 <create+0x9a>
    iunlockput(dp);
    80006664:	8526                	mv	a0,s1
    80006666:	ffffd097          	auipc	ra,0xffffd
    8000666a:	396080e7          	jalr	918(ra) # 800039fc <iunlockput>
    ilock(ip);
    8000666e:	8556                	mv	a0,s5
    80006670:	ffffd097          	auipc	ra,0xffffd
    80006674:	12a080e7          	jalr	298(ra) # 8000379a <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80006678:	000b059b          	sext.w	a1,s6
    8000667c:	4789                	li	a5,2
    8000667e:	02f59563          	bne	a1,a5,800066a8 <create+0x8c>
    80006682:	044ad783          	lhu	a5,68(s5)
    80006686:	37f9                	addiw	a5,a5,-2
    80006688:	17c2                	slli	a5,a5,0x30
    8000668a:	93c1                	srli	a5,a5,0x30
    8000668c:	4705                	li	a4,1
    8000668e:	00f76d63          	bltu	a4,a5,800066a8 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80006692:	8556                	mv	a0,s5
    80006694:	60a6                	ld	ra,72(sp)
    80006696:	6406                	ld	s0,64(sp)
    80006698:	74e2                	ld	s1,56(sp)
    8000669a:	7942                	ld	s2,48(sp)
    8000669c:	79a2                	ld	s3,40(sp)
    8000669e:	7a02                	ld	s4,32(sp)
    800066a0:	6ae2                	ld	s5,24(sp)
    800066a2:	6b42                	ld	s6,16(sp)
    800066a4:	6161                	addi	sp,sp,80
    800066a6:	8082                	ret
    iunlockput(ip);
    800066a8:	8556                	mv	a0,s5
    800066aa:	ffffd097          	auipc	ra,0xffffd
    800066ae:	352080e7          	jalr	850(ra) # 800039fc <iunlockput>
    return 0;
    800066b2:	4a81                	li	s5,0
    800066b4:	bff9                	j	80006692 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800066b6:	85da                	mv	a1,s6
    800066b8:	4088                	lw	a0,0(s1)
    800066ba:	ffffd097          	auipc	ra,0xffffd
    800066be:	f44080e7          	jalr	-188(ra) # 800035fe <ialloc>
    800066c2:	8a2a                	mv	s4,a0
    800066c4:	c125                	beqz	a0,80006724 <create+0x108>
  ilock(ip);
    800066c6:	ffffd097          	auipc	ra,0xffffd
    800066ca:	0d4080e7          	jalr	212(ra) # 8000379a <ilock>
  ip->major = major;
    800066ce:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800066d2:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800066d6:	4785                	li	a5,1
    800066d8:	04fa1523          	sh	a5,74(s4)
  iupdate(ip);
    800066dc:	8552                	mv	a0,s4
    800066de:	ffffd097          	auipc	ra,0xffffd
    800066e2:	ff2080e7          	jalr	-14(ra) # 800036d0 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800066e6:	000b059b          	sext.w	a1,s6
    800066ea:	4785                	li	a5,1
    800066ec:	04f58363          	beq	a1,a5,80006732 <create+0x116>
  if(dirlink(dp, name, ip->inum) < 0)
    800066f0:	004a2603          	lw	a2,4(s4)
    800066f4:	fb040593          	addi	a1,s0,-80
    800066f8:	8526                	mv	a0,s1
    800066fa:	ffffd097          	auipc	ra,0xffffd
    800066fe:	794080e7          	jalr	1940(ra) # 80003e8e <dirlink>
    80006702:	08054763          	bltz	a0,80006790 <create+0x174>
  iunlockput(dp);
    80006706:	8526                	mv	a0,s1
    80006708:	ffffd097          	auipc	ra,0xffffd
    8000670c:	2f4080e7          	jalr	756(ra) # 800039fc <iunlockput>
  printf("Successfully Created\n");
    80006710:	00002517          	auipc	a0,0x2
    80006714:	24850513          	addi	a0,a0,584 # 80008958 <syscalls+0x458>
    80006718:	ffffa097          	auipc	ra,0xffffa
    8000671c:	e76080e7          	jalr	-394(ra) # 8000058e <printf>
  return ip;
    80006720:	8ad2                	mv	s5,s4
    80006722:	bf85                	j	80006692 <create+0x76>
    iunlockput(dp);
    80006724:	8526                	mv	a0,s1
    80006726:	ffffd097          	auipc	ra,0xffffd
    8000672a:	2d6080e7          	jalr	726(ra) # 800039fc <iunlockput>
    return 0;
    8000672e:	8ad2                	mv	s5,s4
    80006730:	b78d                	j	80006692 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80006732:	004a2603          	lw	a2,4(s4)
    80006736:	00002597          	auipc	a1,0x2
    8000673a:	07258593          	addi	a1,a1,114 # 800087a8 <syscalls+0x2a8>
    8000673e:	8552                	mv	a0,s4
    80006740:	ffffd097          	auipc	ra,0xffffd
    80006744:	74e080e7          	jalr	1870(ra) # 80003e8e <dirlink>
    80006748:	04054463          	bltz	a0,80006790 <create+0x174>
    8000674c:	40d0                	lw	a2,4(s1)
    8000674e:	00002597          	auipc	a1,0x2
    80006752:	06258593          	addi	a1,a1,98 # 800087b0 <syscalls+0x2b0>
    80006756:	8552                	mv	a0,s4
    80006758:	ffffd097          	auipc	ra,0xffffd
    8000675c:	736080e7          	jalr	1846(ra) # 80003e8e <dirlink>
    80006760:	02054863          	bltz	a0,80006790 <create+0x174>
  if(dirlink(dp, name, ip->inum) < 0)
    80006764:	004a2603          	lw	a2,4(s4)
    80006768:	fb040593          	addi	a1,s0,-80
    8000676c:	8526                	mv	a0,s1
    8000676e:	ffffd097          	auipc	ra,0xffffd
    80006772:	720080e7          	jalr	1824(ra) # 80003e8e <dirlink>
    80006776:	00054d63          	bltz	a0,80006790 <create+0x174>
    dp->nlink++;  // for ".."
    8000677a:	04a4d783          	lhu	a5,74(s1)
    8000677e:	2785                	addiw	a5,a5,1
    80006780:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80006784:	8526                	mv	a0,s1
    80006786:	ffffd097          	auipc	ra,0xffffd
    8000678a:	f4a080e7          	jalr	-182(ra) # 800036d0 <iupdate>
    8000678e:	bfa5                	j	80006706 <create+0xea>
  printf("actually fails\n");
    80006790:	00002517          	auipc	a0,0x2
    80006794:	1e050513          	addi	a0,a0,480 # 80008970 <syscalls+0x470>
    80006798:	ffffa097          	auipc	ra,0xffffa
    8000679c:	df6080e7          	jalr	-522(ra) # 8000058e <printf>
  ip->nlink = 0;
    800067a0:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800067a4:	8552                	mv	a0,s4
    800067a6:	ffffd097          	auipc	ra,0xffffd
    800067aa:	f2a080e7          	jalr	-214(ra) # 800036d0 <iupdate>
  iunlockput(ip);
    800067ae:	8552                	mv	a0,s4
    800067b0:	ffffd097          	auipc	ra,0xffffd
    800067b4:	24c080e7          	jalr	588(ra) # 800039fc <iunlockput>
  iunlockput(dp);
    800067b8:	8526                	mv	a0,s1
    800067ba:	ffffd097          	auipc	ra,0xffffd
    800067be:	242080e7          	jalr	578(ra) # 800039fc <iunlockput>
  return 0;
    800067c2:	bdc1                	j	80006692 <create+0x76>
    return 0;
    800067c4:	8aaa                	mv	s5,a0
    800067c6:	b5f1                	j	80006692 <create+0x76>

00000000800067c8 <open>:


struct file *open(char *filename, int omode){
    800067c8:	7179                	addi	sp,sp,-48
    800067ca:	f406                	sd	ra,40(sp)
    800067cc:	f022                	sd	s0,32(sp)
    800067ce:	ec26                	sd	s1,24(sp)
    800067d0:	e84a                	sd	s2,16(sp)
    800067d2:	e44e                	sd	s3,8(sp)
    800067d4:	1800                	addi	s0,sp,48
    800067d6:	84aa                	mv	s1,a0
    800067d8:	892e                	mv	s2,a1
    int fd;
    struct file *f;
    struct inode *ip;

    if(strlen(filename) < 0)
    800067da:	ffffa097          	auipc	ra,0xffffa
    800067de:	690080e7          	jalr	1680(ra) # 80000e6a <strlen>
    800067e2:	18054e63          	bltz	a0,8000697e <open+0x1b6>
        return (struct file *)-1;

    begin_op();
    800067e6:	ffffe097          	auipc	ra,0xffffe
    800067ea:	976080e7          	jalr	-1674(ra) # 8000415c <begin_op>
    if(omode & O_CREATE){
    800067ee:	20097793          	andi	a5,s2,512
    800067f2:	10078263          	beqz	a5,800068f6 <open+0x12e>
        printf("CREATING\n");
    800067f6:	00002517          	auipc	a0,0x2
    800067fa:	18a50513          	addi	a0,a0,394 # 80008980 <syscalls+0x480>
    800067fe:	ffffa097          	auipc	ra,0xffffa
    80006802:	d90080e7          	jalr	-624(ra) # 8000058e <printf>
        ip = create(filename, T_FILE, 0, 0);
    80006806:	4681                	li	a3,0
    80006808:	4601                	li	a2,0
    8000680a:	4589                	li	a1,2
    8000680c:	8526                	mv	a0,s1
    8000680e:	00000097          	auipc	ra,0x0
    80006812:	e0e080e7          	jalr	-498(ra) # 8000661c <create>
    80006816:	89aa                	mv	s3,a0
        if(ip == 0){
    80006818:	c169                	beqz	a0,800068da <open+0x112>
            iunlockput(ip);
            end_op();
            return (struct file *)-1;
        }
    }
    printf("1\n");
    8000681a:	00002517          	auipc	a0,0x2
    8000681e:	19e50513          	addi	a0,a0,414 # 800089b8 <syscalls+0x4b8>
    80006822:	ffffa097          	auipc	ra,0xffffa
    80006826:	d6c080e7          	jalr	-660(ra) # 8000058e <printf>


    if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000682a:	04499703          	lh	a4,68(s3)
    8000682e:	478d                	li	a5,3
    80006830:	00f71763          	bne	a4,a5,8000683e <open+0x76>
    80006834:	0469d703          	lhu	a4,70(s3)
    80006838:	47a5                	li	a5,9
    8000683a:	12e7e163          	bltu	a5,a4,8000695c <open+0x194>
        iunlockput(ip);
        end_op();
        return (struct file *)-1;
    }

        printf("2\n");
    8000683e:	00002517          	auipc	a0,0x2
    80006842:	18250513          	addi	a0,a0,386 # 800089c0 <syscalls+0x4c0>
    80006846:	ffffa097          	auipc	ra,0xffffa
    8000684a:	d48080e7          	jalr	-696(ra) # 8000058e <printf>
    if((f = filealloc()) == 0 || (fd = fdalloc(f) < 0)){
    8000684e:	ffffe097          	auipc	ra,0xffffe
    80006852:	d1e080e7          	jalr	-738(ra) # 8000456c <filealloc>
    80006856:	84aa                	mv	s1,a0
    80006858:	14050163          	beqz	a0,8000699a <open+0x1d2>
    8000685c:	00000097          	auipc	ra,0x0
    80006860:	d7e080e7          	jalr	-642(ra) # 800065da <fdalloc>
    80006864:	12054663          	bltz	a0,80006990 <open+0x1c8>
        iunlockput(ip);
        end_op();
        return (struct file *)-1;
    }

        printf("3\n");
    80006868:	00002517          	auipc	a0,0x2
    8000686c:	16050513          	addi	a0,a0,352 # 800089c8 <syscalls+0x4c8>
    80006870:	ffffa097          	auipc	ra,0xffffa
    80006874:	d1e080e7          	jalr	-738(ra) # 8000058e <printf>
   f->type = FD_INODE;
    80006878:	4789                	li	a5,2
    8000687a:	c09c                	sw	a5,0(s1)
   f->off = 0;
    8000687c:	0204a023          	sw	zero,32(s1)
   f->ip = ip;
    80006880:	0134bc23          	sd	s3,24(s1)
   f->readable = !(omode & O_WRONLY);
    80006884:	00194793          	xori	a5,s2,1
    80006888:	8b85                	andi	a5,a5,1
    8000688a:	00f48423          	sb	a5,8(s1)
   f->writable = O_WRONLY;
    8000688e:	4785                	li	a5,1
    80006890:	00f484a3          	sb	a5,9(s1)

   if((omode & O_TRUNC) && ip->type == T_FILE){
    80006894:	40097913          	andi	s2,s2,1024
    80006898:	00090763          	beqz	s2,800068a6 <open+0xde>
    8000689c:	04499703          	lh	a4,68(s3)
    800068a0:	4789                	li	a5,2
    800068a2:	0cf70863          	beq	a4,a5,80006972 <open+0x1aa>
     itrunc(ip);
   }

        printf("4\n");
    800068a6:	00002517          	auipc	a0,0x2
    800068aa:	12a50513          	addi	a0,a0,298 # 800089d0 <syscalls+0x4d0>
    800068ae:	ffffa097          	auipc	ra,0xffffa
    800068b2:	ce0080e7          	jalr	-800(ra) # 8000058e <printf>
   iunlock(ip);
    800068b6:	854e                	mv	a0,s3
    800068b8:	ffffd097          	auipc	ra,0xffffd
    800068bc:	fa4080e7          	jalr	-92(ra) # 8000385c <iunlock>
   end_op();
    800068c0:	ffffe097          	auipc	ra,0xffffe
    800068c4:	91c080e7          	jalr	-1764(ra) # 800041dc <end_op>

        printf("5\n");
    800068c8:	00002517          	auipc	a0,0x2
    800068cc:	11050513          	addi	a0,a0,272 # 800089d8 <syscalls+0x4d8>
    800068d0:	ffffa097          	auipc	ra,0xffffa
    800068d4:	cbe080e7          	jalr	-834(ra) # 8000058e <printf>
   return f;
    800068d8:	a065                	j	80006980 <open+0x1b8>
            printf("Create Broke\n");
    800068da:	00002517          	auipc	a0,0x2
    800068de:	0b650513          	addi	a0,a0,182 # 80008990 <syscalls+0x490>
    800068e2:	ffffa097          	auipc	ra,0xffffa
    800068e6:	cac080e7          	jalr	-852(ra) # 8000058e <printf>
            end_op();
    800068ea:	ffffe097          	auipc	ra,0xffffe
    800068ee:	8f2080e7          	jalr	-1806(ra) # 800041dc <end_op>
            return (struct file *)-1;
    800068f2:	54fd                	li	s1,-1
    800068f4:	a071                	j	80006980 <open+0x1b8>
        printf("EXSITS ALREADY\n");
    800068f6:	00002517          	auipc	a0,0x2
    800068fa:	0aa50513          	addi	a0,a0,170 # 800089a0 <syscalls+0x4a0>
    800068fe:	ffffa097          	auipc	ra,0xffffa
    80006902:	c90080e7          	jalr	-880(ra) # 8000058e <printf>
        if((ip = namei(filename)) == 0){
    80006906:	8526                	mv	a0,s1
    80006908:	ffffd097          	auipc	ra,0xffffd
    8000690c:	638080e7          	jalr	1592(ra) # 80003f40 <namei>
    80006910:	89aa                	mv	s3,a0
    80006912:	c51d                	beqz	a0,80006940 <open+0x178>
        ilock(ip);
    80006914:	ffffd097          	auipc	ra,0xffffd
    80006918:	e86080e7          	jalr	-378(ra) # 8000379a <ilock>
        if(ip->type == T_DIR && omode != O_RDONLY){
    8000691c:	04499703          	lh	a4,68(s3)
    80006920:	4785                	li	a5,1
    80006922:	eef71ce3          	bne	a4,a5,8000681a <open+0x52>
    80006926:	ee090ae3          	beqz	s2,8000681a <open+0x52>
            iunlockput(ip);
    8000692a:	854e                	mv	a0,s3
    8000692c:	ffffd097          	auipc	ra,0xffffd
    80006930:	0d0080e7          	jalr	208(ra) # 800039fc <iunlockput>
            end_op();
    80006934:	ffffe097          	auipc	ra,0xffffe
    80006938:	8a8080e7          	jalr	-1880(ra) # 800041dc <end_op>
            return (struct file *)-1;
    8000693c:	54fd                	li	s1,-1
    8000693e:	a089                	j	80006980 <open+0x1b8>
            end_op();
    80006940:	ffffe097          	auipc	ra,0xffffe
    80006944:	89c080e7          	jalr	-1892(ra) # 800041dc <end_op>
            printf("OOPs");
    80006948:	00002517          	auipc	a0,0x2
    8000694c:	06850513          	addi	a0,a0,104 # 800089b0 <syscalls+0x4b0>
    80006950:	ffffa097          	auipc	ra,0xffffa
    80006954:	c3e080e7          	jalr	-962(ra) # 8000058e <printf>
            return (struct file *)-1;
    80006958:	54fd                	li	s1,-1
    8000695a:	a01d                	j	80006980 <open+0x1b8>
        iunlockput(ip);
    8000695c:	854e                	mv	a0,s3
    8000695e:	ffffd097          	auipc	ra,0xffffd
    80006962:	09e080e7          	jalr	158(ra) # 800039fc <iunlockput>
        end_op();
    80006966:	ffffe097          	auipc	ra,0xffffe
    8000696a:	876080e7          	jalr	-1930(ra) # 800041dc <end_op>
        return (struct file *)-1;
    8000696e:	54fd                	li	s1,-1
    80006970:	a801                	j	80006980 <open+0x1b8>
     itrunc(ip);
    80006972:	854e                	mv	a0,s3
    80006974:	ffffd097          	auipc	ra,0xffffd
    80006978:	f34080e7          	jalr	-204(ra) # 800038a8 <itrunc>
    8000697c:	b72d                	j	800068a6 <open+0xde>
        return (struct file *)-1;
    8000697e:	54fd                	li	s1,-1
}
    80006980:	8526                	mv	a0,s1
    80006982:	70a2                	ld	ra,40(sp)
    80006984:	7402                	ld	s0,32(sp)
    80006986:	64e2                	ld	s1,24(sp)
    80006988:	6942                	ld	s2,16(sp)
    8000698a:	69a2                	ld	s3,8(sp)
    8000698c:	6145                	addi	sp,sp,48
    8000698e:	8082                	ret
            fileclose(f);
    80006990:	8526                	mv	a0,s1
    80006992:	ffffe097          	auipc	ra,0xffffe
    80006996:	c96080e7          	jalr	-874(ra) # 80004628 <fileclose>
        iunlockput(ip);
    8000699a:	854e                	mv	a0,s3
    8000699c:	ffffd097          	auipc	ra,0xffffd
    800069a0:	060080e7          	jalr	96(ra) # 800039fc <iunlockput>
        end_op();
    800069a4:	ffffe097          	auipc	ra,0xffffe
    800069a8:	838080e7          	jalr	-1992(ra) # 800041dc <end_op>
        return (struct file *)-1;
    800069ac:	54fd                	li	s1,-1
    800069ae:	bfc9                	j	80006980 <open+0x1b8>
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
