
user/_xv6test:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <test_1>:
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/syscall.h"

void test_1(void) {
   0:	1101                	addi	sp,sp,-32
   2:	ec06                	sd	ra,24(sp)
   4:	e822                	sd	s0,16(sp)
   6:	1000                	addi	s0,sp,32
  printf("Test 1: Simple syscall\n");
   8:	00001517          	auipc	a0,0x1
   c:	86850513          	addi	a0,a0,-1944 # 870 <malloc+0xe8>
  10:	00000097          	auipc	ra,0x0
  14:	6ba080e7          	jalr	1722(ra) # 6ca <printf>
  int bruh = 12;
  18:	47b1                	li	a5,12
  1a:	fef42623          	sw	a5,-20(s0)
  wait(&bruh);
  1e:	fec40513          	addi	a0,s0,-20
  22:	00000097          	auipc	ra,0x0
  26:	328080e7          	jalr	808(ra) # 34a <wait>
}
  2a:	60e2                	ld	ra,24(sp)
  2c:	6442                	ld	s0,16(sp)
  2e:	6105                	addi	sp,sp,32
  30:	8082                	ret

0000000000000032 <test_2>:

void test_2(void) {
  32:	1101                	addi	sp,sp,-32
  34:	ec06                	sd	ra,24(sp)
  36:	e822                	sd	s0,16(sp)
  38:	1000                	addi	s0,sp,32
  printf("Test 2: Using audit\n");
  3a:	00001517          	auipc	a0,0x1
  3e:	84e50513          	addi	a0,a0,-1970 # 888 <malloc+0x100>
  42:	00000097          	auipc	ra,0x0
  46:	688080e7          	jalr	1672(ra) # 6ca <printf>
  // set up a binary number to be what we want to whitelist. 
  // so just whitelist the first 5 syscalls,
  // being fork, exit, wait, pipe, read

  int whitelist = 0b11111000000000000000000000000000;
  audit(whitelist);
  4a:	f8000537          	lui	a0,0xf8000
  4e:	00000097          	auipc	ra,0x0
  52:	394080e7          	jalr	916(ra) # 3e2 <audit>

  // call wait, which should make an audit log
  int sec = 5;
  56:	4795                	li	a5,5
  58:	fef42623          	sw	a5,-20(s0)
  wait(&sec);
  5c:	fec40513          	addi	a0,s0,-20
  60:	00000097          	auipc	ra,0x0
  64:	2ea080e7          	jalr	746(ra) # 34a <wait>

  // printf calls write, so let's see if that gets an audit
  printf("is there a write audit?\n");
  68:	00001517          	auipc	a0,0x1
  6c:	83850513          	addi	a0,a0,-1992 # 8a0 <malloc+0x118>
  70:	00000097          	auipc	ra,0x0
  74:	65a080e7          	jalr	1626(ra) # 6ca <printf>

  // call sleep, which should NOT make an audit log
  sec = 1;
  78:	4785                	li	a5,1
  7a:	fef42623          	sw	a5,-20(s0)

  // coincidentally this prints under wait because
  // sleep just makes the thread wait... *shrug*
  sleep(sec);
  7e:	4505                	li	a0,1
  80:	00000097          	auipc	ra,0x0
  84:	352080e7          	jalr	850(ra) # 3d2 <sleep>
}
  88:	60e2                	ld	ra,24(sp)
  8a:	6442                	ld	s0,16(sp)
  8c:	6105                	addi	sp,sp,32
  8e:	8082                	ret

0000000000000090 <main>:

int main(int argc, char *argv[]) {
  90:	1141                	addi	sp,sp,-16
  92:	e406                	sd	ra,8(sp)
  94:	e022                	sd	s0,0(sp)
  96:	0800                	addi	s0,sp,16
  // basic test.
  test_1();
  98:	00000097          	auipc	ra,0x0
  9c:	f68080e7          	jalr	-152(ra) # 0 <test_1>
  test_2();
  a0:	00000097          	auipc	ra,0x0
  a4:	f92080e7          	jalr	-110(ra) # 32 <test_2>

  // test using audit

  exit(0);
  a8:	4501                	li	a0,0
  aa:	00000097          	auipc	ra,0x0
  ae:	298080e7          	jalr	664(ra) # 342 <exit>

00000000000000b2 <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
  b2:	1141                	addi	sp,sp,-16
  b4:	e406                	sd	ra,8(sp)
  b6:	e022                	sd	s0,0(sp)
  b8:	0800                	addi	s0,sp,16
  extern int main();
  main();
  ba:	00000097          	auipc	ra,0x0
  be:	fd6080e7          	jalr	-42(ra) # 90 <main>
  exit(0);
  c2:	4501                	li	a0,0
  c4:	00000097          	auipc	ra,0x0
  c8:	27e080e7          	jalr	638(ra) # 342 <exit>

00000000000000cc <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
  cc:	1141                	addi	sp,sp,-16
  ce:	e422                	sd	s0,8(sp)
  d0:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  d2:	87aa                	mv	a5,a0
  d4:	0585                	addi	a1,a1,1
  d6:	0785                	addi	a5,a5,1
  d8:	fff5c703          	lbu	a4,-1(a1)
  dc:	fee78fa3          	sb	a4,-1(a5)
  e0:	fb75                	bnez	a4,d4 <strcpy+0x8>
    ;
  return os;
}
  e2:	6422                	ld	s0,8(sp)
  e4:	0141                	addi	sp,sp,16
  e6:	8082                	ret

00000000000000e8 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  e8:	1141                	addi	sp,sp,-16
  ea:	e422                	sd	s0,8(sp)
  ec:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  ee:	00054783          	lbu	a5,0(a0)
  f2:	cb91                	beqz	a5,106 <strcmp+0x1e>
  f4:	0005c703          	lbu	a4,0(a1)
  f8:	00f71763          	bne	a4,a5,106 <strcmp+0x1e>
    p++, q++;
  fc:	0505                	addi	a0,a0,1
  fe:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 100:	00054783          	lbu	a5,0(a0)
 104:	fbe5                	bnez	a5,f4 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 106:	0005c503          	lbu	a0,0(a1)
}
 10a:	40a7853b          	subw	a0,a5,a0
 10e:	6422                	ld	s0,8(sp)
 110:	0141                	addi	sp,sp,16
 112:	8082                	ret

0000000000000114 <strlen>:

uint
strlen(const char *s)
{
 114:	1141                	addi	sp,sp,-16
 116:	e422                	sd	s0,8(sp)
 118:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 11a:	00054783          	lbu	a5,0(a0)
 11e:	cf91                	beqz	a5,13a <strlen+0x26>
 120:	0505                	addi	a0,a0,1
 122:	87aa                	mv	a5,a0
 124:	4685                	li	a3,1
 126:	9e89                	subw	a3,a3,a0
 128:	00f6853b          	addw	a0,a3,a5
 12c:	0785                	addi	a5,a5,1
 12e:	fff7c703          	lbu	a4,-1(a5)
 132:	fb7d                	bnez	a4,128 <strlen+0x14>
    ;
  return n;
}
 134:	6422                	ld	s0,8(sp)
 136:	0141                	addi	sp,sp,16
 138:	8082                	ret
  for(n = 0; s[n]; n++)
 13a:	4501                	li	a0,0
 13c:	bfe5                	j	134 <strlen+0x20>

000000000000013e <memset>:

void*
memset(void *dst, int c, uint n)
{
 13e:	1141                	addi	sp,sp,-16
 140:	e422                	sd	s0,8(sp)
 142:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 144:	ce09                	beqz	a2,15e <memset+0x20>
 146:	87aa                	mv	a5,a0
 148:	fff6071b          	addiw	a4,a2,-1
 14c:	1702                	slli	a4,a4,0x20
 14e:	9301                	srli	a4,a4,0x20
 150:	0705                	addi	a4,a4,1
 152:	972a                	add	a4,a4,a0
    cdst[i] = c;
 154:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 158:	0785                	addi	a5,a5,1
 15a:	fee79de3          	bne	a5,a4,154 <memset+0x16>
  }
  return dst;
}
 15e:	6422                	ld	s0,8(sp)
 160:	0141                	addi	sp,sp,16
 162:	8082                	ret

0000000000000164 <strchr>:

char*
strchr(const char *s, char c)
{
 164:	1141                	addi	sp,sp,-16
 166:	e422                	sd	s0,8(sp)
 168:	0800                	addi	s0,sp,16
  for(; *s; s++)
 16a:	00054783          	lbu	a5,0(a0)
 16e:	cb99                	beqz	a5,184 <strchr+0x20>
    if(*s == c)
 170:	00f58763          	beq	a1,a5,17e <strchr+0x1a>
  for(; *s; s++)
 174:	0505                	addi	a0,a0,1
 176:	00054783          	lbu	a5,0(a0)
 17a:	fbfd                	bnez	a5,170 <strchr+0xc>
      return (char*)s;
  return 0;
 17c:	4501                	li	a0,0
}
 17e:	6422                	ld	s0,8(sp)
 180:	0141                	addi	sp,sp,16
 182:	8082                	ret
  return 0;
 184:	4501                	li	a0,0
 186:	bfe5                	j	17e <strchr+0x1a>

0000000000000188 <gets>:

char*
gets(char *buf, int max)
{
 188:	711d                	addi	sp,sp,-96
 18a:	ec86                	sd	ra,88(sp)
 18c:	e8a2                	sd	s0,80(sp)
 18e:	e4a6                	sd	s1,72(sp)
 190:	e0ca                	sd	s2,64(sp)
 192:	fc4e                	sd	s3,56(sp)
 194:	f852                	sd	s4,48(sp)
 196:	f456                	sd	s5,40(sp)
 198:	f05a                	sd	s6,32(sp)
 19a:	ec5e                	sd	s7,24(sp)
 19c:	1080                	addi	s0,sp,96
 19e:	8baa                	mv	s7,a0
 1a0:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 1a2:	892a                	mv	s2,a0
 1a4:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 1a6:	4aa9                	li	s5,10
 1a8:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 1aa:	89a6                	mv	s3,s1
 1ac:	2485                	addiw	s1,s1,1
 1ae:	0344d863          	bge	s1,s4,1de <gets+0x56>
    cc = read(0, &c, 1);
 1b2:	4605                	li	a2,1
 1b4:	faf40593          	addi	a1,s0,-81
 1b8:	4501                	li	a0,0
 1ba:	00000097          	auipc	ra,0x0
 1be:	1a0080e7          	jalr	416(ra) # 35a <read>
    if(cc < 1)
 1c2:	00a05e63          	blez	a0,1de <gets+0x56>
    buf[i++] = c;
 1c6:	faf44783          	lbu	a5,-81(s0)
 1ca:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 1ce:	01578763          	beq	a5,s5,1dc <gets+0x54>
 1d2:	0905                	addi	s2,s2,1
 1d4:	fd679be3          	bne	a5,s6,1aa <gets+0x22>
  for(i=0; i+1 < max; ){
 1d8:	89a6                	mv	s3,s1
 1da:	a011                	j	1de <gets+0x56>
 1dc:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 1de:	99de                	add	s3,s3,s7
 1e0:	00098023          	sb	zero,0(s3)
  return buf;
}
 1e4:	855e                	mv	a0,s7
 1e6:	60e6                	ld	ra,88(sp)
 1e8:	6446                	ld	s0,80(sp)
 1ea:	64a6                	ld	s1,72(sp)
 1ec:	6906                	ld	s2,64(sp)
 1ee:	79e2                	ld	s3,56(sp)
 1f0:	7a42                	ld	s4,48(sp)
 1f2:	7aa2                	ld	s5,40(sp)
 1f4:	7b02                	ld	s6,32(sp)
 1f6:	6be2                	ld	s7,24(sp)
 1f8:	6125                	addi	sp,sp,96
 1fa:	8082                	ret

00000000000001fc <stat>:

int
stat(const char *n, struct stat *st)
{
 1fc:	1101                	addi	sp,sp,-32
 1fe:	ec06                	sd	ra,24(sp)
 200:	e822                	sd	s0,16(sp)
 202:	e426                	sd	s1,8(sp)
 204:	e04a                	sd	s2,0(sp)
 206:	1000                	addi	s0,sp,32
 208:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 20a:	4581                	li	a1,0
 20c:	00000097          	auipc	ra,0x0
 210:	176080e7          	jalr	374(ra) # 382 <open>
  if(fd < 0)
 214:	02054563          	bltz	a0,23e <stat+0x42>
 218:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 21a:	85ca                	mv	a1,s2
 21c:	00000097          	auipc	ra,0x0
 220:	17e080e7          	jalr	382(ra) # 39a <fstat>
 224:	892a                	mv	s2,a0
  close(fd);
 226:	8526                	mv	a0,s1
 228:	00000097          	auipc	ra,0x0
 22c:	142080e7          	jalr	322(ra) # 36a <close>
  return r;
}
 230:	854a                	mv	a0,s2
 232:	60e2                	ld	ra,24(sp)
 234:	6442                	ld	s0,16(sp)
 236:	64a2                	ld	s1,8(sp)
 238:	6902                	ld	s2,0(sp)
 23a:	6105                	addi	sp,sp,32
 23c:	8082                	ret
    return -1;
 23e:	597d                	li	s2,-1
 240:	bfc5                	j	230 <stat+0x34>

0000000000000242 <atoi>:

int
atoi(const char *s)
{
 242:	1141                	addi	sp,sp,-16
 244:	e422                	sd	s0,8(sp)
 246:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 248:	00054603          	lbu	a2,0(a0)
 24c:	fd06079b          	addiw	a5,a2,-48
 250:	0ff7f793          	andi	a5,a5,255
 254:	4725                	li	a4,9
 256:	02f76963          	bltu	a4,a5,288 <atoi+0x46>
 25a:	86aa                	mv	a3,a0
  n = 0;
 25c:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 25e:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 260:	0685                	addi	a3,a3,1
 262:	0025179b          	slliw	a5,a0,0x2
 266:	9fa9                	addw	a5,a5,a0
 268:	0017979b          	slliw	a5,a5,0x1
 26c:	9fb1                	addw	a5,a5,a2
 26e:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 272:	0006c603          	lbu	a2,0(a3)
 276:	fd06071b          	addiw	a4,a2,-48
 27a:	0ff77713          	andi	a4,a4,255
 27e:	fee5f1e3          	bgeu	a1,a4,260 <atoi+0x1e>
  return n;
}
 282:	6422                	ld	s0,8(sp)
 284:	0141                	addi	sp,sp,16
 286:	8082                	ret
  n = 0;
 288:	4501                	li	a0,0
 28a:	bfe5                	j	282 <atoi+0x40>

000000000000028c <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 28c:	1141                	addi	sp,sp,-16
 28e:	e422                	sd	s0,8(sp)
 290:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 292:	02b57663          	bgeu	a0,a1,2be <memmove+0x32>
    while(n-- > 0)
 296:	02c05163          	blez	a2,2b8 <memmove+0x2c>
 29a:	fff6079b          	addiw	a5,a2,-1
 29e:	1782                	slli	a5,a5,0x20
 2a0:	9381                	srli	a5,a5,0x20
 2a2:	0785                	addi	a5,a5,1
 2a4:	97aa                	add	a5,a5,a0
  dst = vdst;
 2a6:	872a                	mv	a4,a0
      *dst++ = *src++;
 2a8:	0585                	addi	a1,a1,1
 2aa:	0705                	addi	a4,a4,1
 2ac:	fff5c683          	lbu	a3,-1(a1)
 2b0:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 2b4:	fee79ae3          	bne	a5,a4,2a8 <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 2b8:	6422                	ld	s0,8(sp)
 2ba:	0141                	addi	sp,sp,16
 2bc:	8082                	ret
    dst += n;
 2be:	00c50733          	add	a4,a0,a2
    src += n;
 2c2:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 2c4:	fec05ae3          	blez	a2,2b8 <memmove+0x2c>
 2c8:	fff6079b          	addiw	a5,a2,-1
 2cc:	1782                	slli	a5,a5,0x20
 2ce:	9381                	srli	a5,a5,0x20
 2d0:	fff7c793          	not	a5,a5
 2d4:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 2d6:	15fd                	addi	a1,a1,-1
 2d8:	177d                	addi	a4,a4,-1
 2da:	0005c683          	lbu	a3,0(a1)
 2de:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 2e2:	fee79ae3          	bne	a5,a4,2d6 <memmove+0x4a>
 2e6:	bfc9                	j	2b8 <memmove+0x2c>

00000000000002e8 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 2e8:	1141                	addi	sp,sp,-16
 2ea:	e422                	sd	s0,8(sp)
 2ec:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 2ee:	ca05                	beqz	a2,31e <memcmp+0x36>
 2f0:	fff6069b          	addiw	a3,a2,-1
 2f4:	1682                	slli	a3,a3,0x20
 2f6:	9281                	srli	a3,a3,0x20
 2f8:	0685                	addi	a3,a3,1
 2fa:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 2fc:	00054783          	lbu	a5,0(a0)
 300:	0005c703          	lbu	a4,0(a1)
 304:	00e79863          	bne	a5,a4,314 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 308:	0505                	addi	a0,a0,1
    p2++;
 30a:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 30c:	fed518e3          	bne	a0,a3,2fc <memcmp+0x14>
  }
  return 0;
 310:	4501                	li	a0,0
 312:	a019                	j	318 <memcmp+0x30>
      return *p1 - *p2;
 314:	40e7853b          	subw	a0,a5,a4
}
 318:	6422                	ld	s0,8(sp)
 31a:	0141                	addi	sp,sp,16
 31c:	8082                	ret
  return 0;
 31e:	4501                	li	a0,0
 320:	bfe5                	j	318 <memcmp+0x30>

0000000000000322 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 322:	1141                	addi	sp,sp,-16
 324:	e406                	sd	ra,8(sp)
 326:	e022                	sd	s0,0(sp)
 328:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 32a:	00000097          	auipc	ra,0x0
 32e:	f62080e7          	jalr	-158(ra) # 28c <memmove>
}
 332:	60a2                	ld	ra,8(sp)
 334:	6402                	ld	s0,0(sp)
 336:	0141                	addi	sp,sp,16
 338:	8082                	ret

000000000000033a <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 33a:	4885                	li	a7,1
 ecall
 33c:	00000073          	ecall
 ret
 340:	8082                	ret

0000000000000342 <exit>:
.global exit
exit:
 li a7, SYS_exit
 342:	4889                	li	a7,2
 ecall
 344:	00000073          	ecall
 ret
 348:	8082                	ret

000000000000034a <wait>:
.global wait
wait:
 li a7, SYS_wait
 34a:	488d                	li	a7,3
 ecall
 34c:	00000073          	ecall
 ret
 350:	8082                	ret

0000000000000352 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 352:	4891                	li	a7,4
 ecall
 354:	00000073          	ecall
 ret
 358:	8082                	ret

000000000000035a <read>:
.global read
read:
 li a7, SYS_read
 35a:	4895                	li	a7,5
 ecall
 35c:	00000073          	ecall
 ret
 360:	8082                	ret

0000000000000362 <write>:
.global write
write:
 li a7, SYS_write
 362:	48c1                	li	a7,16
 ecall
 364:	00000073          	ecall
 ret
 368:	8082                	ret

000000000000036a <close>:
.global close
close:
 li a7, SYS_close
 36a:	48d5                	li	a7,21
 ecall
 36c:	00000073          	ecall
 ret
 370:	8082                	ret

0000000000000372 <kill>:
.global kill
kill:
 li a7, SYS_kill
 372:	4899                	li	a7,6
 ecall
 374:	00000073          	ecall
 ret
 378:	8082                	ret

000000000000037a <exec>:
.global exec
exec:
 li a7, SYS_exec
 37a:	489d                	li	a7,7
 ecall
 37c:	00000073          	ecall
 ret
 380:	8082                	ret

0000000000000382 <open>:
.global open
open:
 li a7, SYS_open
 382:	48bd                	li	a7,15
 ecall
 384:	00000073          	ecall
 ret
 388:	8082                	ret

000000000000038a <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 38a:	48c5                	li	a7,17
 ecall
 38c:	00000073          	ecall
 ret
 390:	8082                	ret

0000000000000392 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 392:	48c9                	li	a7,18
 ecall
 394:	00000073          	ecall
 ret
 398:	8082                	ret

000000000000039a <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 39a:	48a1                	li	a7,8
 ecall
 39c:	00000073          	ecall
 ret
 3a0:	8082                	ret

00000000000003a2 <link>:
.global link
link:
 li a7, SYS_link
 3a2:	48cd                	li	a7,19
 ecall
 3a4:	00000073          	ecall
 ret
 3a8:	8082                	ret

00000000000003aa <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 3aa:	48d1                	li	a7,20
 ecall
 3ac:	00000073          	ecall
 ret
 3b0:	8082                	ret

00000000000003b2 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 3b2:	48a5                	li	a7,9
 ecall
 3b4:	00000073          	ecall
 ret
 3b8:	8082                	ret

00000000000003ba <dup>:
.global dup
dup:
 li a7, SYS_dup
 3ba:	48a9                	li	a7,10
 ecall
 3bc:	00000073          	ecall
 ret
 3c0:	8082                	ret

00000000000003c2 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 3c2:	48ad                	li	a7,11
 ecall
 3c4:	00000073          	ecall
 ret
 3c8:	8082                	ret

00000000000003ca <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 3ca:	48b1                	li	a7,12
 ecall
 3cc:	00000073          	ecall
 ret
 3d0:	8082                	ret

00000000000003d2 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 3d2:	48b5                	li	a7,13
 ecall
 3d4:	00000073          	ecall
 ret
 3d8:	8082                	ret

00000000000003da <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 3da:	48b9                	li	a7,14
 ecall
 3dc:	00000073          	ecall
 ret
 3e0:	8082                	ret

00000000000003e2 <audit>:
.global audit
audit:
 li a7, SYS_audit
 3e2:	48d9                	li	a7,22
 ecall
 3e4:	00000073          	ecall
 ret
 3e8:	8082                	ret

00000000000003ea <check>:
.global check
check:
 li a7, SYS_check
 3ea:	48dd                	li	a7,23
 ecall
 3ec:	00000073          	ecall
 ret
 3f0:	8082                	ret

00000000000003f2 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 3f2:	1101                	addi	sp,sp,-32
 3f4:	ec06                	sd	ra,24(sp)
 3f6:	e822                	sd	s0,16(sp)
 3f8:	1000                	addi	s0,sp,32
 3fa:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 3fe:	4605                	li	a2,1
 400:	fef40593          	addi	a1,s0,-17
 404:	00000097          	auipc	ra,0x0
 408:	f5e080e7          	jalr	-162(ra) # 362 <write>
}
 40c:	60e2                	ld	ra,24(sp)
 40e:	6442                	ld	s0,16(sp)
 410:	6105                	addi	sp,sp,32
 412:	8082                	ret

0000000000000414 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 414:	7139                	addi	sp,sp,-64
 416:	fc06                	sd	ra,56(sp)
 418:	f822                	sd	s0,48(sp)
 41a:	f426                	sd	s1,40(sp)
 41c:	f04a                	sd	s2,32(sp)
 41e:	ec4e                	sd	s3,24(sp)
 420:	0080                	addi	s0,sp,64
 422:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 424:	c299                	beqz	a3,42a <printint+0x16>
 426:	0805c863          	bltz	a1,4b6 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 42a:	2581                	sext.w	a1,a1
  neg = 0;
 42c:	4881                	li	a7,0
 42e:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 432:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 434:	2601                	sext.w	a2,a2
 436:	00000517          	auipc	a0,0x0
 43a:	49250513          	addi	a0,a0,1170 # 8c8 <digits>
 43e:	883a                	mv	a6,a4
 440:	2705                	addiw	a4,a4,1
 442:	02c5f7bb          	remuw	a5,a1,a2
 446:	1782                	slli	a5,a5,0x20
 448:	9381                	srli	a5,a5,0x20
 44a:	97aa                	add	a5,a5,a0
 44c:	0007c783          	lbu	a5,0(a5)
 450:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 454:	0005879b          	sext.w	a5,a1
 458:	02c5d5bb          	divuw	a1,a1,a2
 45c:	0685                	addi	a3,a3,1
 45e:	fec7f0e3          	bgeu	a5,a2,43e <printint+0x2a>
  if(neg)
 462:	00088b63          	beqz	a7,478 <printint+0x64>
    buf[i++] = '-';
 466:	fd040793          	addi	a5,s0,-48
 46a:	973e                	add	a4,a4,a5
 46c:	02d00793          	li	a5,45
 470:	fef70823          	sb	a5,-16(a4)
 474:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 478:	02e05863          	blez	a4,4a8 <printint+0x94>
 47c:	fc040793          	addi	a5,s0,-64
 480:	00e78933          	add	s2,a5,a4
 484:	fff78993          	addi	s3,a5,-1
 488:	99ba                	add	s3,s3,a4
 48a:	377d                	addiw	a4,a4,-1
 48c:	1702                	slli	a4,a4,0x20
 48e:	9301                	srli	a4,a4,0x20
 490:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 494:	fff94583          	lbu	a1,-1(s2)
 498:	8526                	mv	a0,s1
 49a:	00000097          	auipc	ra,0x0
 49e:	f58080e7          	jalr	-168(ra) # 3f2 <putc>
  while(--i >= 0)
 4a2:	197d                	addi	s2,s2,-1
 4a4:	ff3918e3          	bne	s2,s3,494 <printint+0x80>
}
 4a8:	70e2                	ld	ra,56(sp)
 4aa:	7442                	ld	s0,48(sp)
 4ac:	74a2                	ld	s1,40(sp)
 4ae:	7902                	ld	s2,32(sp)
 4b0:	69e2                	ld	s3,24(sp)
 4b2:	6121                	addi	sp,sp,64
 4b4:	8082                	ret
    x = -xx;
 4b6:	40b005bb          	negw	a1,a1
    neg = 1;
 4ba:	4885                	li	a7,1
    x = -xx;
 4bc:	bf8d                	j	42e <printint+0x1a>

00000000000004be <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 4be:	7119                	addi	sp,sp,-128
 4c0:	fc86                	sd	ra,120(sp)
 4c2:	f8a2                	sd	s0,112(sp)
 4c4:	f4a6                	sd	s1,104(sp)
 4c6:	f0ca                	sd	s2,96(sp)
 4c8:	ecce                	sd	s3,88(sp)
 4ca:	e8d2                	sd	s4,80(sp)
 4cc:	e4d6                	sd	s5,72(sp)
 4ce:	e0da                	sd	s6,64(sp)
 4d0:	fc5e                	sd	s7,56(sp)
 4d2:	f862                	sd	s8,48(sp)
 4d4:	f466                	sd	s9,40(sp)
 4d6:	f06a                	sd	s10,32(sp)
 4d8:	ec6e                	sd	s11,24(sp)
 4da:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 4dc:	0005c903          	lbu	s2,0(a1)
 4e0:	18090f63          	beqz	s2,67e <vprintf+0x1c0>
 4e4:	8aaa                	mv	s5,a0
 4e6:	8b32                	mv	s6,a2
 4e8:	00158493          	addi	s1,a1,1
  state = 0;
 4ec:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 4ee:	02500a13          	li	s4,37
      if(c == 'd'){
 4f2:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 4f6:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 4fa:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 4fe:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 502:	00000b97          	auipc	s7,0x0
 506:	3c6b8b93          	addi	s7,s7,966 # 8c8 <digits>
 50a:	a839                	j	528 <vprintf+0x6a>
        putc(fd, c);
 50c:	85ca                	mv	a1,s2
 50e:	8556                	mv	a0,s5
 510:	00000097          	auipc	ra,0x0
 514:	ee2080e7          	jalr	-286(ra) # 3f2 <putc>
 518:	a019                	j	51e <vprintf+0x60>
    } else if(state == '%'){
 51a:	01498f63          	beq	s3,s4,538 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 51e:	0485                	addi	s1,s1,1
 520:	fff4c903          	lbu	s2,-1(s1)
 524:	14090d63          	beqz	s2,67e <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 528:	0009079b          	sext.w	a5,s2
    if(state == 0){
 52c:	fe0997e3          	bnez	s3,51a <vprintf+0x5c>
      if(c == '%'){
 530:	fd479ee3          	bne	a5,s4,50c <vprintf+0x4e>
        state = '%';
 534:	89be                	mv	s3,a5
 536:	b7e5                	j	51e <vprintf+0x60>
      if(c == 'd'){
 538:	05878063          	beq	a5,s8,578 <vprintf+0xba>
      } else if(c == 'l') {
 53c:	05978c63          	beq	a5,s9,594 <vprintf+0xd6>
      } else if(c == 'x') {
 540:	07a78863          	beq	a5,s10,5b0 <vprintf+0xf2>
      } else if(c == 'p') {
 544:	09b78463          	beq	a5,s11,5cc <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 548:	07300713          	li	a4,115
 54c:	0ce78663          	beq	a5,a4,618 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 550:	06300713          	li	a4,99
 554:	0ee78e63          	beq	a5,a4,650 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 558:	11478863          	beq	a5,s4,668 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 55c:	85d2                	mv	a1,s4
 55e:	8556                	mv	a0,s5
 560:	00000097          	auipc	ra,0x0
 564:	e92080e7          	jalr	-366(ra) # 3f2 <putc>
        putc(fd, c);
 568:	85ca                	mv	a1,s2
 56a:	8556                	mv	a0,s5
 56c:	00000097          	auipc	ra,0x0
 570:	e86080e7          	jalr	-378(ra) # 3f2 <putc>
      }
      state = 0;
 574:	4981                	li	s3,0
 576:	b765                	j	51e <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 578:	008b0913          	addi	s2,s6,8
 57c:	4685                	li	a3,1
 57e:	4629                	li	a2,10
 580:	000b2583          	lw	a1,0(s6)
 584:	8556                	mv	a0,s5
 586:	00000097          	auipc	ra,0x0
 58a:	e8e080e7          	jalr	-370(ra) # 414 <printint>
 58e:	8b4a                	mv	s6,s2
      state = 0;
 590:	4981                	li	s3,0
 592:	b771                	j	51e <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 594:	008b0913          	addi	s2,s6,8
 598:	4681                	li	a3,0
 59a:	4629                	li	a2,10
 59c:	000b2583          	lw	a1,0(s6)
 5a0:	8556                	mv	a0,s5
 5a2:	00000097          	auipc	ra,0x0
 5a6:	e72080e7          	jalr	-398(ra) # 414 <printint>
 5aa:	8b4a                	mv	s6,s2
      state = 0;
 5ac:	4981                	li	s3,0
 5ae:	bf85                	j	51e <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 5b0:	008b0913          	addi	s2,s6,8
 5b4:	4681                	li	a3,0
 5b6:	4641                	li	a2,16
 5b8:	000b2583          	lw	a1,0(s6)
 5bc:	8556                	mv	a0,s5
 5be:	00000097          	auipc	ra,0x0
 5c2:	e56080e7          	jalr	-426(ra) # 414 <printint>
 5c6:	8b4a                	mv	s6,s2
      state = 0;
 5c8:	4981                	li	s3,0
 5ca:	bf91                	j	51e <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 5cc:	008b0793          	addi	a5,s6,8
 5d0:	f8f43423          	sd	a5,-120(s0)
 5d4:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 5d8:	03000593          	li	a1,48
 5dc:	8556                	mv	a0,s5
 5de:	00000097          	auipc	ra,0x0
 5e2:	e14080e7          	jalr	-492(ra) # 3f2 <putc>
  putc(fd, 'x');
 5e6:	85ea                	mv	a1,s10
 5e8:	8556                	mv	a0,s5
 5ea:	00000097          	auipc	ra,0x0
 5ee:	e08080e7          	jalr	-504(ra) # 3f2 <putc>
 5f2:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 5f4:	03c9d793          	srli	a5,s3,0x3c
 5f8:	97de                	add	a5,a5,s7
 5fa:	0007c583          	lbu	a1,0(a5)
 5fe:	8556                	mv	a0,s5
 600:	00000097          	auipc	ra,0x0
 604:	df2080e7          	jalr	-526(ra) # 3f2 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 608:	0992                	slli	s3,s3,0x4
 60a:	397d                	addiw	s2,s2,-1
 60c:	fe0914e3          	bnez	s2,5f4 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 610:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 614:	4981                	li	s3,0
 616:	b721                	j	51e <vprintf+0x60>
        s = va_arg(ap, char*);
 618:	008b0993          	addi	s3,s6,8
 61c:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 620:	02090163          	beqz	s2,642 <vprintf+0x184>
        while(*s != 0){
 624:	00094583          	lbu	a1,0(s2)
 628:	c9a1                	beqz	a1,678 <vprintf+0x1ba>
          putc(fd, *s);
 62a:	8556                	mv	a0,s5
 62c:	00000097          	auipc	ra,0x0
 630:	dc6080e7          	jalr	-570(ra) # 3f2 <putc>
          s++;
 634:	0905                	addi	s2,s2,1
        while(*s != 0){
 636:	00094583          	lbu	a1,0(s2)
 63a:	f9e5                	bnez	a1,62a <vprintf+0x16c>
        s = va_arg(ap, char*);
 63c:	8b4e                	mv	s6,s3
      state = 0;
 63e:	4981                	li	s3,0
 640:	bdf9                	j	51e <vprintf+0x60>
          s = "(null)";
 642:	00000917          	auipc	s2,0x0
 646:	27e90913          	addi	s2,s2,638 # 8c0 <malloc+0x138>
        while(*s != 0){
 64a:	02800593          	li	a1,40
 64e:	bff1                	j	62a <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 650:	008b0913          	addi	s2,s6,8
 654:	000b4583          	lbu	a1,0(s6)
 658:	8556                	mv	a0,s5
 65a:	00000097          	auipc	ra,0x0
 65e:	d98080e7          	jalr	-616(ra) # 3f2 <putc>
 662:	8b4a                	mv	s6,s2
      state = 0;
 664:	4981                	li	s3,0
 666:	bd65                	j	51e <vprintf+0x60>
        putc(fd, c);
 668:	85d2                	mv	a1,s4
 66a:	8556                	mv	a0,s5
 66c:	00000097          	auipc	ra,0x0
 670:	d86080e7          	jalr	-634(ra) # 3f2 <putc>
      state = 0;
 674:	4981                	li	s3,0
 676:	b565                	j	51e <vprintf+0x60>
        s = va_arg(ap, char*);
 678:	8b4e                	mv	s6,s3
      state = 0;
 67a:	4981                	li	s3,0
 67c:	b54d                	j	51e <vprintf+0x60>
    }
  }
}
 67e:	70e6                	ld	ra,120(sp)
 680:	7446                	ld	s0,112(sp)
 682:	74a6                	ld	s1,104(sp)
 684:	7906                	ld	s2,96(sp)
 686:	69e6                	ld	s3,88(sp)
 688:	6a46                	ld	s4,80(sp)
 68a:	6aa6                	ld	s5,72(sp)
 68c:	6b06                	ld	s6,64(sp)
 68e:	7be2                	ld	s7,56(sp)
 690:	7c42                	ld	s8,48(sp)
 692:	7ca2                	ld	s9,40(sp)
 694:	7d02                	ld	s10,32(sp)
 696:	6de2                	ld	s11,24(sp)
 698:	6109                	addi	sp,sp,128
 69a:	8082                	ret

000000000000069c <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 69c:	715d                	addi	sp,sp,-80
 69e:	ec06                	sd	ra,24(sp)
 6a0:	e822                	sd	s0,16(sp)
 6a2:	1000                	addi	s0,sp,32
 6a4:	e010                	sd	a2,0(s0)
 6a6:	e414                	sd	a3,8(s0)
 6a8:	e818                	sd	a4,16(s0)
 6aa:	ec1c                	sd	a5,24(s0)
 6ac:	03043023          	sd	a6,32(s0)
 6b0:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 6b4:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 6b8:	8622                	mv	a2,s0
 6ba:	00000097          	auipc	ra,0x0
 6be:	e04080e7          	jalr	-508(ra) # 4be <vprintf>
}
 6c2:	60e2                	ld	ra,24(sp)
 6c4:	6442                	ld	s0,16(sp)
 6c6:	6161                	addi	sp,sp,80
 6c8:	8082                	ret

00000000000006ca <printf>:

void
printf(const char *fmt, ...)
{
 6ca:	711d                	addi	sp,sp,-96
 6cc:	ec06                	sd	ra,24(sp)
 6ce:	e822                	sd	s0,16(sp)
 6d0:	1000                	addi	s0,sp,32
 6d2:	e40c                	sd	a1,8(s0)
 6d4:	e810                	sd	a2,16(s0)
 6d6:	ec14                	sd	a3,24(s0)
 6d8:	f018                	sd	a4,32(s0)
 6da:	f41c                	sd	a5,40(s0)
 6dc:	03043823          	sd	a6,48(s0)
 6e0:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 6e4:	00840613          	addi	a2,s0,8
 6e8:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 6ec:	85aa                	mv	a1,a0
 6ee:	4505                	li	a0,1
 6f0:	00000097          	auipc	ra,0x0
 6f4:	dce080e7          	jalr	-562(ra) # 4be <vprintf>
}
 6f8:	60e2                	ld	ra,24(sp)
 6fa:	6442                	ld	s0,16(sp)
 6fc:	6125                	addi	sp,sp,96
 6fe:	8082                	ret

0000000000000700 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 700:	1141                	addi	sp,sp,-16
 702:	e422                	sd	s0,8(sp)
 704:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 706:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 70a:	00001797          	auipc	a5,0x1
 70e:	8f67b783          	ld	a5,-1802(a5) # 1000 <freep>
 712:	a805                	j	742 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 714:	4618                	lw	a4,8(a2)
 716:	9db9                	addw	a1,a1,a4
 718:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 71c:	6398                	ld	a4,0(a5)
 71e:	6318                	ld	a4,0(a4)
 720:	fee53823          	sd	a4,-16(a0)
 724:	a091                	j	768 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 726:	ff852703          	lw	a4,-8(a0)
 72a:	9e39                	addw	a2,a2,a4
 72c:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 72e:	ff053703          	ld	a4,-16(a0)
 732:	e398                	sd	a4,0(a5)
 734:	a099                	j	77a <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 736:	6398                	ld	a4,0(a5)
 738:	00e7e463          	bltu	a5,a4,740 <free+0x40>
 73c:	00e6ea63          	bltu	a3,a4,750 <free+0x50>
{
 740:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 742:	fed7fae3          	bgeu	a5,a3,736 <free+0x36>
 746:	6398                	ld	a4,0(a5)
 748:	00e6e463          	bltu	a3,a4,750 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 74c:	fee7eae3          	bltu	a5,a4,740 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 750:	ff852583          	lw	a1,-8(a0)
 754:	6390                	ld	a2,0(a5)
 756:	02059713          	slli	a4,a1,0x20
 75a:	9301                	srli	a4,a4,0x20
 75c:	0712                	slli	a4,a4,0x4
 75e:	9736                	add	a4,a4,a3
 760:	fae60ae3          	beq	a2,a4,714 <free+0x14>
    bp->s.ptr = p->s.ptr;
 764:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 768:	4790                	lw	a2,8(a5)
 76a:	02061713          	slli	a4,a2,0x20
 76e:	9301                	srli	a4,a4,0x20
 770:	0712                	slli	a4,a4,0x4
 772:	973e                	add	a4,a4,a5
 774:	fae689e3          	beq	a3,a4,726 <free+0x26>
  } else
    p->s.ptr = bp;
 778:	e394                	sd	a3,0(a5)
  freep = p;
 77a:	00001717          	auipc	a4,0x1
 77e:	88f73323          	sd	a5,-1914(a4) # 1000 <freep>
}
 782:	6422                	ld	s0,8(sp)
 784:	0141                	addi	sp,sp,16
 786:	8082                	ret

0000000000000788 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 788:	7139                	addi	sp,sp,-64
 78a:	fc06                	sd	ra,56(sp)
 78c:	f822                	sd	s0,48(sp)
 78e:	f426                	sd	s1,40(sp)
 790:	f04a                	sd	s2,32(sp)
 792:	ec4e                	sd	s3,24(sp)
 794:	e852                	sd	s4,16(sp)
 796:	e456                	sd	s5,8(sp)
 798:	e05a                	sd	s6,0(sp)
 79a:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 79c:	02051493          	slli	s1,a0,0x20
 7a0:	9081                	srli	s1,s1,0x20
 7a2:	04bd                	addi	s1,s1,15
 7a4:	8091                	srli	s1,s1,0x4
 7a6:	0014899b          	addiw	s3,s1,1
 7aa:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 7ac:	00001517          	auipc	a0,0x1
 7b0:	85453503          	ld	a0,-1964(a0) # 1000 <freep>
 7b4:	c515                	beqz	a0,7e0 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7b6:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7b8:	4798                	lw	a4,8(a5)
 7ba:	02977f63          	bgeu	a4,s1,7f8 <malloc+0x70>
 7be:	8a4e                	mv	s4,s3
 7c0:	0009871b          	sext.w	a4,s3
 7c4:	6685                	lui	a3,0x1
 7c6:	00d77363          	bgeu	a4,a3,7cc <malloc+0x44>
 7ca:	6a05                	lui	s4,0x1
 7cc:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 7d0:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 7d4:	00001917          	auipc	s2,0x1
 7d8:	82c90913          	addi	s2,s2,-2004 # 1000 <freep>
  if(p == (char*)-1)
 7dc:	5afd                	li	s5,-1
 7de:	a88d                	j	850 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 7e0:	00001797          	auipc	a5,0x1
 7e4:	83078793          	addi	a5,a5,-2000 # 1010 <base>
 7e8:	00001717          	auipc	a4,0x1
 7ec:	80f73c23          	sd	a5,-2024(a4) # 1000 <freep>
 7f0:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 7f2:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 7f6:	b7e1                	j	7be <malloc+0x36>
      if(p->s.size == nunits)
 7f8:	02e48b63          	beq	s1,a4,82e <malloc+0xa6>
        p->s.size -= nunits;
 7fc:	4137073b          	subw	a4,a4,s3
 800:	c798                	sw	a4,8(a5)
        p += p->s.size;
 802:	1702                	slli	a4,a4,0x20
 804:	9301                	srli	a4,a4,0x20
 806:	0712                	slli	a4,a4,0x4
 808:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 80a:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 80e:	00000717          	auipc	a4,0x0
 812:	7ea73923          	sd	a0,2034(a4) # 1000 <freep>
      return (void*)(p + 1);
 816:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 81a:	70e2                	ld	ra,56(sp)
 81c:	7442                	ld	s0,48(sp)
 81e:	74a2                	ld	s1,40(sp)
 820:	7902                	ld	s2,32(sp)
 822:	69e2                	ld	s3,24(sp)
 824:	6a42                	ld	s4,16(sp)
 826:	6aa2                	ld	s5,8(sp)
 828:	6b02                	ld	s6,0(sp)
 82a:	6121                	addi	sp,sp,64
 82c:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 82e:	6398                	ld	a4,0(a5)
 830:	e118                	sd	a4,0(a0)
 832:	bff1                	j	80e <malloc+0x86>
  hp->s.size = nu;
 834:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 838:	0541                	addi	a0,a0,16
 83a:	00000097          	auipc	ra,0x0
 83e:	ec6080e7          	jalr	-314(ra) # 700 <free>
  return freep;
 842:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 846:	d971                	beqz	a0,81a <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 848:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 84a:	4798                	lw	a4,8(a5)
 84c:	fa9776e3          	bgeu	a4,s1,7f8 <malloc+0x70>
    if(p == freep)
 850:	00093703          	ld	a4,0(s2)
 854:	853e                	mv	a0,a5
 856:	fef719e3          	bne	a4,a5,848 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 85a:	8552                	mv	a0,s4
 85c:	00000097          	auipc	ra,0x0
 860:	b6e080e7          	jalr	-1170(ra) # 3ca <sbrk>
  if(p == (char*)-1)
 864:	fd5518e3          	bne	a0,s5,834 <malloc+0xac>
        return 0;
 868:	4501                	li	a0,0
 86a:	bf45                	j	81a <malloc+0x92>
