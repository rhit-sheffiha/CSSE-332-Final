
user/_xv6test:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <write_to_logs>:
#include "audit_list.h"
#include "types.h"

void write_to_logs(void *list){
   0:	1141                	addi	sp,sp,-16
   2:	e422                	sd	s0,8(sp)
   4:	0800                	addi	s0,sp,16

    //write(fd, data, strlen(data));
//    struct audit_list *auditlist = (struct audit_list *)list;

  //  struct audit_node *node = auditlist -> head;
}
   6:	6422                	ld	s0,8(sp)
   8:	0141                	addi	sp,sp,16
   a:	8082                	ret

000000000000000c <main>:
#include "kernel/audit_source.c"

int main(int argc, char *argv[]) {
   c:	1141                	addi	sp,sp,-16
   e:	e422                	sd	s0,8(sp)
  10:	0800                	addi	s0,sp,16


    return 1;
}
  12:	4505                	li	a0,1
  14:	6422                	ld	s0,8(sp)
  16:	0141                	addi	sp,sp,16
  18:	8082                	ret

000000000000001a <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
  1a:	1141                	addi	sp,sp,-16
  1c:	e406                	sd	ra,8(sp)
  1e:	e022                	sd	s0,0(sp)
  20:	0800                	addi	s0,sp,16
  extern int main();
  main();
  22:	00000097          	auipc	ra,0x0
  26:	fea080e7          	jalr	-22(ra) # c <main>
  exit(0);
  2a:	4501                	li	a0,0
  2c:	00000097          	auipc	ra,0x0
  30:	27e080e7          	jalr	638(ra) # 2aa <exit>

0000000000000034 <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
  34:	1141                	addi	sp,sp,-16
  36:	e422                	sd	s0,8(sp)
  38:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  3a:	87aa                	mv	a5,a0
  3c:	0585                	addi	a1,a1,1
  3e:	0785                	addi	a5,a5,1
  40:	fff5c703          	lbu	a4,-1(a1)
  44:	fee78fa3          	sb	a4,-1(a5)
  48:	fb75                	bnez	a4,3c <strcpy+0x8>
    ;
  return os;
}
  4a:	6422                	ld	s0,8(sp)
  4c:	0141                	addi	sp,sp,16
  4e:	8082                	ret

0000000000000050 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  50:	1141                	addi	sp,sp,-16
  52:	e422                	sd	s0,8(sp)
  54:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  56:	00054783          	lbu	a5,0(a0)
  5a:	cb91                	beqz	a5,6e <strcmp+0x1e>
  5c:	0005c703          	lbu	a4,0(a1)
  60:	00f71763          	bne	a4,a5,6e <strcmp+0x1e>
    p++, q++;
  64:	0505                	addi	a0,a0,1
  66:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
  68:	00054783          	lbu	a5,0(a0)
  6c:	fbe5                	bnez	a5,5c <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  6e:	0005c503          	lbu	a0,0(a1)
}
  72:	40a7853b          	subw	a0,a5,a0
  76:	6422                	ld	s0,8(sp)
  78:	0141                	addi	sp,sp,16
  7a:	8082                	ret

000000000000007c <strlen>:

uint
strlen(const char *s)
{
  7c:	1141                	addi	sp,sp,-16
  7e:	e422                	sd	s0,8(sp)
  80:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
  82:	00054783          	lbu	a5,0(a0)
  86:	cf91                	beqz	a5,a2 <strlen+0x26>
  88:	0505                	addi	a0,a0,1
  8a:	87aa                	mv	a5,a0
  8c:	4685                	li	a3,1
  8e:	9e89                	subw	a3,a3,a0
  90:	00f6853b          	addw	a0,a3,a5
  94:	0785                	addi	a5,a5,1
  96:	fff7c703          	lbu	a4,-1(a5)
  9a:	fb7d                	bnez	a4,90 <strlen+0x14>
    ;
  return n;
}
  9c:	6422                	ld	s0,8(sp)
  9e:	0141                	addi	sp,sp,16
  a0:	8082                	ret
  for(n = 0; s[n]; n++)
  a2:	4501                	li	a0,0
  a4:	bfe5                	j	9c <strlen+0x20>

00000000000000a6 <memset>:

void*
memset(void *dst, int c, uint n)
{
  a6:	1141                	addi	sp,sp,-16
  a8:	e422                	sd	s0,8(sp)
  aa:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
  ac:	ce09                	beqz	a2,c6 <memset+0x20>
  ae:	87aa                	mv	a5,a0
  b0:	fff6071b          	addiw	a4,a2,-1
  b4:	1702                	slli	a4,a4,0x20
  b6:	9301                	srli	a4,a4,0x20
  b8:	0705                	addi	a4,a4,1
  ba:	972a                	add	a4,a4,a0
    cdst[i] = c;
  bc:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
  c0:	0785                	addi	a5,a5,1
  c2:	fee79de3          	bne	a5,a4,bc <memset+0x16>
  }
  return dst;
}
  c6:	6422                	ld	s0,8(sp)
  c8:	0141                	addi	sp,sp,16
  ca:	8082                	ret

00000000000000cc <strchr>:

char*
strchr(const char *s, char c)
{
  cc:	1141                	addi	sp,sp,-16
  ce:	e422                	sd	s0,8(sp)
  d0:	0800                	addi	s0,sp,16
  for(; *s; s++)
  d2:	00054783          	lbu	a5,0(a0)
  d6:	cb99                	beqz	a5,ec <strchr+0x20>
    if(*s == c)
  d8:	00f58763          	beq	a1,a5,e6 <strchr+0x1a>
  for(; *s; s++)
  dc:	0505                	addi	a0,a0,1
  de:	00054783          	lbu	a5,0(a0)
  e2:	fbfd                	bnez	a5,d8 <strchr+0xc>
      return (char*)s;
  return 0;
  e4:	4501                	li	a0,0
}
  e6:	6422                	ld	s0,8(sp)
  e8:	0141                	addi	sp,sp,16
  ea:	8082                	ret
  return 0;
  ec:	4501                	li	a0,0
  ee:	bfe5                	j	e6 <strchr+0x1a>

00000000000000f0 <gets>:

char*
gets(char *buf, int max)
{
  f0:	711d                	addi	sp,sp,-96
  f2:	ec86                	sd	ra,88(sp)
  f4:	e8a2                	sd	s0,80(sp)
  f6:	e4a6                	sd	s1,72(sp)
  f8:	e0ca                	sd	s2,64(sp)
  fa:	fc4e                	sd	s3,56(sp)
  fc:	f852                	sd	s4,48(sp)
  fe:	f456                	sd	s5,40(sp)
 100:	f05a                	sd	s6,32(sp)
 102:	ec5e                	sd	s7,24(sp)
 104:	1080                	addi	s0,sp,96
 106:	8baa                	mv	s7,a0
 108:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 10a:	892a                	mv	s2,a0
 10c:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 10e:	4aa9                	li	s5,10
 110:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 112:	89a6                	mv	s3,s1
 114:	2485                	addiw	s1,s1,1
 116:	0344d863          	bge	s1,s4,146 <gets+0x56>
    cc = read(0, &c, 1);
 11a:	4605                	li	a2,1
 11c:	faf40593          	addi	a1,s0,-81
 120:	4501                	li	a0,0
 122:	00000097          	auipc	ra,0x0
 126:	1a0080e7          	jalr	416(ra) # 2c2 <read>
    if(cc < 1)
 12a:	00a05e63          	blez	a0,146 <gets+0x56>
    buf[i++] = c;
 12e:	faf44783          	lbu	a5,-81(s0)
 132:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 136:	01578763          	beq	a5,s5,144 <gets+0x54>
 13a:	0905                	addi	s2,s2,1
 13c:	fd679be3          	bne	a5,s6,112 <gets+0x22>
  for(i=0; i+1 < max; ){
 140:	89a6                	mv	s3,s1
 142:	a011                	j	146 <gets+0x56>
 144:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 146:	99de                	add	s3,s3,s7
 148:	00098023          	sb	zero,0(s3)
  return buf;
}
 14c:	855e                	mv	a0,s7
 14e:	60e6                	ld	ra,88(sp)
 150:	6446                	ld	s0,80(sp)
 152:	64a6                	ld	s1,72(sp)
 154:	6906                	ld	s2,64(sp)
 156:	79e2                	ld	s3,56(sp)
 158:	7a42                	ld	s4,48(sp)
 15a:	7aa2                	ld	s5,40(sp)
 15c:	7b02                	ld	s6,32(sp)
 15e:	6be2                	ld	s7,24(sp)
 160:	6125                	addi	sp,sp,96
 162:	8082                	ret

0000000000000164 <stat>:

int
stat(const char *n, struct stat *st)
{
 164:	1101                	addi	sp,sp,-32
 166:	ec06                	sd	ra,24(sp)
 168:	e822                	sd	s0,16(sp)
 16a:	e426                	sd	s1,8(sp)
 16c:	e04a                	sd	s2,0(sp)
 16e:	1000                	addi	s0,sp,32
 170:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 172:	4581                	li	a1,0
 174:	00000097          	auipc	ra,0x0
 178:	176080e7          	jalr	374(ra) # 2ea <open>
  if(fd < 0)
 17c:	02054563          	bltz	a0,1a6 <stat+0x42>
 180:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 182:	85ca                	mv	a1,s2
 184:	00000097          	auipc	ra,0x0
 188:	17e080e7          	jalr	382(ra) # 302 <fstat>
 18c:	892a                	mv	s2,a0
  close(fd);
 18e:	8526                	mv	a0,s1
 190:	00000097          	auipc	ra,0x0
 194:	142080e7          	jalr	322(ra) # 2d2 <close>
  return r;
}
 198:	854a                	mv	a0,s2
 19a:	60e2                	ld	ra,24(sp)
 19c:	6442                	ld	s0,16(sp)
 19e:	64a2                	ld	s1,8(sp)
 1a0:	6902                	ld	s2,0(sp)
 1a2:	6105                	addi	sp,sp,32
 1a4:	8082                	ret
    return -1;
 1a6:	597d                	li	s2,-1
 1a8:	bfc5                	j	198 <stat+0x34>

00000000000001aa <atoi>:

int
atoi(const char *s)
{
 1aa:	1141                	addi	sp,sp,-16
 1ac:	e422                	sd	s0,8(sp)
 1ae:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 1b0:	00054603          	lbu	a2,0(a0)
 1b4:	fd06079b          	addiw	a5,a2,-48
 1b8:	0ff7f793          	andi	a5,a5,255
 1bc:	4725                	li	a4,9
 1be:	02f76963          	bltu	a4,a5,1f0 <atoi+0x46>
 1c2:	86aa                	mv	a3,a0
  n = 0;
 1c4:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 1c6:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 1c8:	0685                	addi	a3,a3,1
 1ca:	0025179b          	slliw	a5,a0,0x2
 1ce:	9fa9                	addw	a5,a5,a0
 1d0:	0017979b          	slliw	a5,a5,0x1
 1d4:	9fb1                	addw	a5,a5,a2
 1d6:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 1da:	0006c603          	lbu	a2,0(a3)
 1de:	fd06071b          	addiw	a4,a2,-48
 1e2:	0ff77713          	andi	a4,a4,255
 1e6:	fee5f1e3          	bgeu	a1,a4,1c8 <atoi+0x1e>
  return n;
}
 1ea:	6422                	ld	s0,8(sp)
 1ec:	0141                	addi	sp,sp,16
 1ee:	8082                	ret
  n = 0;
 1f0:	4501                	li	a0,0
 1f2:	bfe5                	j	1ea <atoi+0x40>

00000000000001f4 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 1f4:	1141                	addi	sp,sp,-16
 1f6:	e422                	sd	s0,8(sp)
 1f8:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 1fa:	02b57663          	bgeu	a0,a1,226 <memmove+0x32>
    while(n-- > 0)
 1fe:	02c05163          	blez	a2,220 <memmove+0x2c>
 202:	fff6079b          	addiw	a5,a2,-1
 206:	1782                	slli	a5,a5,0x20
 208:	9381                	srli	a5,a5,0x20
 20a:	0785                	addi	a5,a5,1
 20c:	97aa                	add	a5,a5,a0
  dst = vdst;
 20e:	872a                	mv	a4,a0
      *dst++ = *src++;
 210:	0585                	addi	a1,a1,1
 212:	0705                	addi	a4,a4,1
 214:	fff5c683          	lbu	a3,-1(a1)
 218:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 21c:	fee79ae3          	bne	a5,a4,210 <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 220:	6422                	ld	s0,8(sp)
 222:	0141                	addi	sp,sp,16
 224:	8082                	ret
    dst += n;
 226:	00c50733          	add	a4,a0,a2
    src += n;
 22a:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 22c:	fec05ae3          	blez	a2,220 <memmove+0x2c>
 230:	fff6079b          	addiw	a5,a2,-1
 234:	1782                	slli	a5,a5,0x20
 236:	9381                	srli	a5,a5,0x20
 238:	fff7c793          	not	a5,a5
 23c:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 23e:	15fd                	addi	a1,a1,-1
 240:	177d                	addi	a4,a4,-1
 242:	0005c683          	lbu	a3,0(a1)
 246:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 24a:	fee79ae3          	bne	a5,a4,23e <memmove+0x4a>
 24e:	bfc9                	j	220 <memmove+0x2c>

0000000000000250 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 250:	1141                	addi	sp,sp,-16
 252:	e422                	sd	s0,8(sp)
 254:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 256:	ca05                	beqz	a2,286 <memcmp+0x36>
 258:	fff6069b          	addiw	a3,a2,-1
 25c:	1682                	slli	a3,a3,0x20
 25e:	9281                	srli	a3,a3,0x20
 260:	0685                	addi	a3,a3,1
 262:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 264:	00054783          	lbu	a5,0(a0)
 268:	0005c703          	lbu	a4,0(a1)
 26c:	00e79863          	bne	a5,a4,27c <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 270:	0505                	addi	a0,a0,1
    p2++;
 272:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 274:	fed518e3          	bne	a0,a3,264 <memcmp+0x14>
  }
  return 0;
 278:	4501                	li	a0,0
 27a:	a019                	j	280 <memcmp+0x30>
      return *p1 - *p2;
 27c:	40e7853b          	subw	a0,a5,a4
}
 280:	6422                	ld	s0,8(sp)
 282:	0141                	addi	sp,sp,16
 284:	8082                	ret
  return 0;
 286:	4501                	li	a0,0
 288:	bfe5                	j	280 <memcmp+0x30>

000000000000028a <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 28a:	1141                	addi	sp,sp,-16
 28c:	e406                	sd	ra,8(sp)
 28e:	e022                	sd	s0,0(sp)
 290:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 292:	00000097          	auipc	ra,0x0
 296:	f62080e7          	jalr	-158(ra) # 1f4 <memmove>
}
 29a:	60a2                	ld	ra,8(sp)
 29c:	6402                	ld	s0,0(sp)
 29e:	0141                	addi	sp,sp,16
 2a0:	8082                	ret

00000000000002a2 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 2a2:	4885                	li	a7,1
 ecall
 2a4:	00000073          	ecall
 ret
 2a8:	8082                	ret

00000000000002aa <exit>:
.global exit
exit:
 li a7, SYS_exit
 2aa:	4889                	li	a7,2
 ecall
 2ac:	00000073          	ecall
 ret
 2b0:	8082                	ret

00000000000002b2 <wait>:
.global wait
wait:
 li a7, SYS_wait
 2b2:	488d                	li	a7,3
 ecall
 2b4:	00000073          	ecall
 ret
 2b8:	8082                	ret

00000000000002ba <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 2ba:	4891                	li	a7,4
 ecall
 2bc:	00000073          	ecall
 ret
 2c0:	8082                	ret

00000000000002c2 <read>:
.global read
read:
 li a7, SYS_read
 2c2:	4895                	li	a7,5
 ecall
 2c4:	00000073          	ecall
 ret
 2c8:	8082                	ret

00000000000002ca <write>:
.global write
write:
 li a7, SYS_write
 2ca:	48c1                	li	a7,16
 ecall
 2cc:	00000073          	ecall
 ret
 2d0:	8082                	ret

00000000000002d2 <close>:
.global close
close:
 li a7, SYS_close
 2d2:	48d5                	li	a7,21
 ecall
 2d4:	00000073          	ecall
 ret
 2d8:	8082                	ret

00000000000002da <kill>:
.global kill
kill:
 li a7, SYS_kill
 2da:	4899                	li	a7,6
 ecall
 2dc:	00000073          	ecall
 ret
 2e0:	8082                	ret

00000000000002e2 <exec>:
.global exec
exec:
 li a7, SYS_exec
 2e2:	489d                	li	a7,7
 ecall
 2e4:	00000073          	ecall
 ret
 2e8:	8082                	ret

00000000000002ea <open>:
.global open
open:
 li a7, SYS_open
 2ea:	48bd                	li	a7,15
 ecall
 2ec:	00000073          	ecall
 ret
 2f0:	8082                	ret

00000000000002f2 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 2f2:	48c5                	li	a7,17
 ecall
 2f4:	00000073          	ecall
 ret
 2f8:	8082                	ret

00000000000002fa <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 2fa:	48c9                	li	a7,18
 ecall
 2fc:	00000073          	ecall
 ret
 300:	8082                	ret

0000000000000302 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 302:	48a1                	li	a7,8
 ecall
 304:	00000073          	ecall
 ret
 308:	8082                	ret

000000000000030a <link>:
.global link
link:
 li a7, SYS_link
 30a:	48cd                	li	a7,19
 ecall
 30c:	00000073          	ecall
 ret
 310:	8082                	ret

0000000000000312 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 312:	48d1                	li	a7,20
 ecall
 314:	00000073          	ecall
 ret
 318:	8082                	ret

000000000000031a <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 31a:	48a5                	li	a7,9
 ecall
 31c:	00000073          	ecall
 ret
 320:	8082                	ret

0000000000000322 <dup>:
.global dup
dup:
 li a7, SYS_dup
 322:	48a9                	li	a7,10
 ecall
 324:	00000073          	ecall
 ret
 328:	8082                	ret

000000000000032a <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 32a:	48ad                	li	a7,11
 ecall
 32c:	00000073          	ecall
 ret
 330:	8082                	ret

0000000000000332 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 332:	48b1                	li	a7,12
 ecall
 334:	00000073          	ecall
 ret
 338:	8082                	ret

000000000000033a <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 33a:	48b5                	li	a7,13
 ecall
 33c:	00000073          	ecall
 ret
 340:	8082                	ret

0000000000000342 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 342:	48b9                	li	a7,14
 ecall
 344:	00000073          	ecall
 ret
 348:	8082                	ret

000000000000034a <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 34a:	1101                	addi	sp,sp,-32
 34c:	ec06                	sd	ra,24(sp)
 34e:	e822                	sd	s0,16(sp)
 350:	1000                	addi	s0,sp,32
 352:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 356:	4605                	li	a2,1
 358:	fef40593          	addi	a1,s0,-17
 35c:	00000097          	auipc	ra,0x0
 360:	f6e080e7          	jalr	-146(ra) # 2ca <write>
}
 364:	60e2                	ld	ra,24(sp)
 366:	6442                	ld	s0,16(sp)
 368:	6105                	addi	sp,sp,32
 36a:	8082                	ret

000000000000036c <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 36c:	7139                	addi	sp,sp,-64
 36e:	fc06                	sd	ra,56(sp)
 370:	f822                	sd	s0,48(sp)
 372:	f426                	sd	s1,40(sp)
 374:	f04a                	sd	s2,32(sp)
 376:	ec4e                	sd	s3,24(sp)
 378:	0080                	addi	s0,sp,64
 37a:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 37c:	c299                	beqz	a3,382 <printint+0x16>
 37e:	0805c863          	bltz	a1,40e <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 382:	2581                	sext.w	a1,a1
  neg = 0;
 384:	4881                	li	a7,0
 386:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 38a:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 38c:	2601                	sext.w	a2,a2
 38e:	00000517          	auipc	a0,0x0
 392:	44a50513          	addi	a0,a0,1098 # 7d8 <digits>
 396:	883a                	mv	a6,a4
 398:	2705                	addiw	a4,a4,1
 39a:	02c5f7bb          	remuw	a5,a1,a2
 39e:	1782                	slli	a5,a5,0x20
 3a0:	9381                	srli	a5,a5,0x20
 3a2:	97aa                	add	a5,a5,a0
 3a4:	0007c783          	lbu	a5,0(a5)
 3a8:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 3ac:	0005879b          	sext.w	a5,a1
 3b0:	02c5d5bb          	divuw	a1,a1,a2
 3b4:	0685                	addi	a3,a3,1
 3b6:	fec7f0e3          	bgeu	a5,a2,396 <printint+0x2a>
  if(neg)
 3ba:	00088b63          	beqz	a7,3d0 <printint+0x64>
    buf[i++] = '-';
 3be:	fd040793          	addi	a5,s0,-48
 3c2:	973e                	add	a4,a4,a5
 3c4:	02d00793          	li	a5,45
 3c8:	fef70823          	sb	a5,-16(a4)
 3cc:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 3d0:	02e05863          	blez	a4,400 <printint+0x94>
 3d4:	fc040793          	addi	a5,s0,-64
 3d8:	00e78933          	add	s2,a5,a4
 3dc:	fff78993          	addi	s3,a5,-1
 3e0:	99ba                	add	s3,s3,a4
 3e2:	377d                	addiw	a4,a4,-1
 3e4:	1702                	slli	a4,a4,0x20
 3e6:	9301                	srli	a4,a4,0x20
 3e8:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 3ec:	fff94583          	lbu	a1,-1(s2)
 3f0:	8526                	mv	a0,s1
 3f2:	00000097          	auipc	ra,0x0
 3f6:	f58080e7          	jalr	-168(ra) # 34a <putc>
  while(--i >= 0)
 3fa:	197d                	addi	s2,s2,-1
 3fc:	ff3918e3          	bne	s2,s3,3ec <printint+0x80>
}
 400:	70e2                	ld	ra,56(sp)
 402:	7442                	ld	s0,48(sp)
 404:	74a2                	ld	s1,40(sp)
 406:	7902                	ld	s2,32(sp)
 408:	69e2                	ld	s3,24(sp)
 40a:	6121                	addi	sp,sp,64
 40c:	8082                	ret
    x = -xx;
 40e:	40b005bb          	negw	a1,a1
    neg = 1;
 412:	4885                	li	a7,1
    x = -xx;
 414:	bf8d                	j	386 <printint+0x1a>

0000000000000416 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 416:	7119                	addi	sp,sp,-128
 418:	fc86                	sd	ra,120(sp)
 41a:	f8a2                	sd	s0,112(sp)
 41c:	f4a6                	sd	s1,104(sp)
 41e:	f0ca                	sd	s2,96(sp)
 420:	ecce                	sd	s3,88(sp)
 422:	e8d2                	sd	s4,80(sp)
 424:	e4d6                	sd	s5,72(sp)
 426:	e0da                	sd	s6,64(sp)
 428:	fc5e                	sd	s7,56(sp)
 42a:	f862                	sd	s8,48(sp)
 42c:	f466                	sd	s9,40(sp)
 42e:	f06a                	sd	s10,32(sp)
 430:	ec6e                	sd	s11,24(sp)
 432:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 434:	0005c903          	lbu	s2,0(a1)
 438:	18090f63          	beqz	s2,5d6 <vprintf+0x1c0>
 43c:	8aaa                	mv	s5,a0
 43e:	8b32                	mv	s6,a2
 440:	00158493          	addi	s1,a1,1
  state = 0;
 444:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 446:	02500a13          	li	s4,37
      if(c == 'd'){
 44a:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 44e:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 452:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 456:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 45a:	00000b97          	auipc	s7,0x0
 45e:	37eb8b93          	addi	s7,s7,894 # 7d8 <digits>
 462:	a839                	j	480 <vprintf+0x6a>
        putc(fd, c);
 464:	85ca                	mv	a1,s2
 466:	8556                	mv	a0,s5
 468:	00000097          	auipc	ra,0x0
 46c:	ee2080e7          	jalr	-286(ra) # 34a <putc>
 470:	a019                	j	476 <vprintf+0x60>
    } else if(state == '%'){
 472:	01498f63          	beq	s3,s4,490 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 476:	0485                	addi	s1,s1,1
 478:	fff4c903          	lbu	s2,-1(s1)
 47c:	14090d63          	beqz	s2,5d6 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 480:	0009079b          	sext.w	a5,s2
    if(state == 0){
 484:	fe0997e3          	bnez	s3,472 <vprintf+0x5c>
      if(c == '%'){
 488:	fd479ee3          	bne	a5,s4,464 <vprintf+0x4e>
        state = '%';
 48c:	89be                	mv	s3,a5
 48e:	b7e5                	j	476 <vprintf+0x60>
      if(c == 'd'){
 490:	05878063          	beq	a5,s8,4d0 <vprintf+0xba>
      } else if(c == 'l') {
 494:	05978c63          	beq	a5,s9,4ec <vprintf+0xd6>
      } else if(c == 'x') {
 498:	07a78863          	beq	a5,s10,508 <vprintf+0xf2>
      } else if(c == 'p') {
 49c:	09b78463          	beq	a5,s11,524 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 4a0:	07300713          	li	a4,115
 4a4:	0ce78663          	beq	a5,a4,570 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 4a8:	06300713          	li	a4,99
 4ac:	0ee78e63          	beq	a5,a4,5a8 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 4b0:	11478863          	beq	a5,s4,5c0 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 4b4:	85d2                	mv	a1,s4
 4b6:	8556                	mv	a0,s5
 4b8:	00000097          	auipc	ra,0x0
 4bc:	e92080e7          	jalr	-366(ra) # 34a <putc>
        putc(fd, c);
 4c0:	85ca                	mv	a1,s2
 4c2:	8556                	mv	a0,s5
 4c4:	00000097          	auipc	ra,0x0
 4c8:	e86080e7          	jalr	-378(ra) # 34a <putc>
      }
      state = 0;
 4cc:	4981                	li	s3,0
 4ce:	b765                	j	476 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 4d0:	008b0913          	addi	s2,s6,8
 4d4:	4685                	li	a3,1
 4d6:	4629                	li	a2,10
 4d8:	000b2583          	lw	a1,0(s6)
 4dc:	8556                	mv	a0,s5
 4de:	00000097          	auipc	ra,0x0
 4e2:	e8e080e7          	jalr	-370(ra) # 36c <printint>
 4e6:	8b4a                	mv	s6,s2
      state = 0;
 4e8:	4981                	li	s3,0
 4ea:	b771                	j	476 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 4ec:	008b0913          	addi	s2,s6,8
 4f0:	4681                	li	a3,0
 4f2:	4629                	li	a2,10
 4f4:	000b2583          	lw	a1,0(s6)
 4f8:	8556                	mv	a0,s5
 4fa:	00000097          	auipc	ra,0x0
 4fe:	e72080e7          	jalr	-398(ra) # 36c <printint>
 502:	8b4a                	mv	s6,s2
      state = 0;
 504:	4981                	li	s3,0
 506:	bf85                	j	476 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 508:	008b0913          	addi	s2,s6,8
 50c:	4681                	li	a3,0
 50e:	4641                	li	a2,16
 510:	000b2583          	lw	a1,0(s6)
 514:	8556                	mv	a0,s5
 516:	00000097          	auipc	ra,0x0
 51a:	e56080e7          	jalr	-426(ra) # 36c <printint>
 51e:	8b4a                	mv	s6,s2
      state = 0;
 520:	4981                	li	s3,0
 522:	bf91                	j	476 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 524:	008b0793          	addi	a5,s6,8
 528:	f8f43423          	sd	a5,-120(s0)
 52c:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 530:	03000593          	li	a1,48
 534:	8556                	mv	a0,s5
 536:	00000097          	auipc	ra,0x0
 53a:	e14080e7          	jalr	-492(ra) # 34a <putc>
  putc(fd, 'x');
 53e:	85ea                	mv	a1,s10
 540:	8556                	mv	a0,s5
 542:	00000097          	auipc	ra,0x0
 546:	e08080e7          	jalr	-504(ra) # 34a <putc>
 54a:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 54c:	03c9d793          	srli	a5,s3,0x3c
 550:	97de                	add	a5,a5,s7
 552:	0007c583          	lbu	a1,0(a5)
 556:	8556                	mv	a0,s5
 558:	00000097          	auipc	ra,0x0
 55c:	df2080e7          	jalr	-526(ra) # 34a <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 560:	0992                	slli	s3,s3,0x4
 562:	397d                	addiw	s2,s2,-1
 564:	fe0914e3          	bnez	s2,54c <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 568:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 56c:	4981                	li	s3,0
 56e:	b721                	j	476 <vprintf+0x60>
        s = va_arg(ap, char*);
 570:	008b0993          	addi	s3,s6,8
 574:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 578:	02090163          	beqz	s2,59a <vprintf+0x184>
        while(*s != 0){
 57c:	00094583          	lbu	a1,0(s2)
 580:	c9a1                	beqz	a1,5d0 <vprintf+0x1ba>
          putc(fd, *s);
 582:	8556                	mv	a0,s5
 584:	00000097          	auipc	ra,0x0
 588:	dc6080e7          	jalr	-570(ra) # 34a <putc>
          s++;
 58c:	0905                	addi	s2,s2,1
        while(*s != 0){
 58e:	00094583          	lbu	a1,0(s2)
 592:	f9e5                	bnez	a1,582 <vprintf+0x16c>
        s = va_arg(ap, char*);
 594:	8b4e                	mv	s6,s3
      state = 0;
 596:	4981                	li	s3,0
 598:	bdf9                	j	476 <vprintf+0x60>
          s = "(null)";
 59a:	00000917          	auipc	s2,0x0
 59e:	23690913          	addi	s2,s2,566 # 7d0 <malloc+0xf0>
        while(*s != 0){
 5a2:	02800593          	li	a1,40
 5a6:	bff1                	j	582 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 5a8:	008b0913          	addi	s2,s6,8
 5ac:	000b4583          	lbu	a1,0(s6)
 5b0:	8556                	mv	a0,s5
 5b2:	00000097          	auipc	ra,0x0
 5b6:	d98080e7          	jalr	-616(ra) # 34a <putc>
 5ba:	8b4a                	mv	s6,s2
      state = 0;
 5bc:	4981                	li	s3,0
 5be:	bd65                	j	476 <vprintf+0x60>
        putc(fd, c);
 5c0:	85d2                	mv	a1,s4
 5c2:	8556                	mv	a0,s5
 5c4:	00000097          	auipc	ra,0x0
 5c8:	d86080e7          	jalr	-634(ra) # 34a <putc>
      state = 0;
 5cc:	4981                	li	s3,0
 5ce:	b565                	j	476 <vprintf+0x60>
        s = va_arg(ap, char*);
 5d0:	8b4e                	mv	s6,s3
      state = 0;
 5d2:	4981                	li	s3,0
 5d4:	b54d                	j	476 <vprintf+0x60>
    }
  }
}
 5d6:	70e6                	ld	ra,120(sp)
 5d8:	7446                	ld	s0,112(sp)
 5da:	74a6                	ld	s1,104(sp)
 5dc:	7906                	ld	s2,96(sp)
 5de:	69e6                	ld	s3,88(sp)
 5e0:	6a46                	ld	s4,80(sp)
 5e2:	6aa6                	ld	s5,72(sp)
 5e4:	6b06                	ld	s6,64(sp)
 5e6:	7be2                	ld	s7,56(sp)
 5e8:	7c42                	ld	s8,48(sp)
 5ea:	7ca2                	ld	s9,40(sp)
 5ec:	7d02                	ld	s10,32(sp)
 5ee:	6de2                	ld	s11,24(sp)
 5f0:	6109                	addi	sp,sp,128
 5f2:	8082                	ret

00000000000005f4 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 5f4:	715d                	addi	sp,sp,-80
 5f6:	ec06                	sd	ra,24(sp)
 5f8:	e822                	sd	s0,16(sp)
 5fa:	1000                	addi	s0,sp,32
 5fc:	e010                	sd	a2,0(s0)
 5fe:	e414                	sd	a3,8(s0)
 600:	e818                	sd	a4,16(s0)
 602:	ec1c                	sd	a5,24(s0)
 604:	03043023          	sd	a6,32(s0)
 608:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 60c:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 610:	8622                	mv	a2,s0
 612:	00000097          	auipc	ra,0x0
 616:	e04080e7          	jalr	-508(ra) # 416 <vprintf>
}
 61a:	60e2                	ld	ra,24(sp)
 61c:	6442                	ld	s0,16(sp)
 61e:	6161                	addi	sp,sp,80
 620:	8082                	ret

0000000000000622 <printf>:

void
printf(const char *fmt, ...)
{
 622:	711d                	addi	sp,sp,-96
 624:	ec06                	sd	ra,24(sp)
 626:	e822                	sd	s0,16(sp)
 628:	1000                	addi	s0,sp,32
 62a:	e40c                	sd	a1,8(s0)
 62c:	e810                	sd	a2,16(s0)
 62e:	ec14                	sd	a3,24(s0)
 630:	f018                	sd	a4,32(s0)
 632:	f41c                	sd	a5,40(s0)
 634:	03043823          	sd	a6,48(s0)
 638:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 63c:	00840613          	addi	a2,s0,8
 640:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 644:	85aa                	mv	a1,a0
 646:	4505                	li	a0,1
 648:	00000097          	auipc	ra,0x0
 64c:	dce080e7          	jalr	-562(ra) # 416 <vprintf>
}
 650:	60e2                	ld	ra,24(sp)
 652:	6442                	ld	s0,16(sp)
 654:	6125                	addi	sp,sp,96
 656:	8082                	ret

0000000000000658 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 658:	1141                	addi	sp,sp,-16
 65a:	e422                	sd	s0,8(sp)
 65c:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 65e:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 662:	00001797          	auipc	a5,0x1
 666:	99e7b783          	ld	a5,-1634(a5) # 1000 <freep>
 66a:	a805                	j	69a <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 66c:	4618                	lw	a4,8(a2)
 66e:	9db9                	addw	a1,a1,a4
 670:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 674:	6398                	ld	a4,0(a5)
 676:	6318                	ld	a4,0(a4)
 678:	fee53823          	sd	a4,-16(a0)
 67c:	a091                	j	6c0 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 67e:	ff852703          	lw	a4,-8(a0)
 682:	9e39                	addw	a2,a2,a4
 684:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 686:	ff053703          	ld	a4,-16(a0)
 68a:	e398                	sd	a4,0(a5)
 68c:	a099                	j	6d2 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 68e:	6398                	ld	a4,0(a5)
 690:	00e7e463          	bltu	a5,a4,698 <free+0x40>
 694:	00e6ea63          	bltu	a3,a4,6a8 <free+0x50>
{
 698:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 69a:	fed7fae3          	bgeu	a5,a3,68e <free+0x36>
 69e:	6398                	ld	a4,0(a5)
 6a0:	00e6e463          	bltu	a3,a4,6a8 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6a4:	fee7eae3          	bltu	a5,a4,698 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 6a8:	ff852583          	lw	a1,-8(a0)
 6ac:	6390                	ld	a2,0(a5)
 6ae:	02059713          	slli	a4,a1,0x20
 6b2:	9301                	srli	a4,a4,0x20
 6b4:	0712                	slli	a4,a4,0x4
 6b6:	9736                	add	a4,a4,a3
 6b8:	fae60ae3          	beq	a2,a4,66c <free+0x14>
    bp->s.ptr = p->s.ptr;
 6bc:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 6c0:	4790                	lw	a2,8(a5)
 6c2:	02061713          	slli	a4,a2,0x20
 6c6:	9301                	srli	a4,a4,0x20
 6c8:	0712                	slli	a4,a4,0x4
 6ca:	973e                	add	a4,a4,a5
 6cc:	fae689e3          	beq	a3,a4,67e <free+0x26>
  } else
    p->s.ptr = bp;
 6d0:	e394                	sd	a3,0(a5)
  freep = p;
 6d2:	00001717          	auipc	a4,0x1
 6d6:	92f73723          	sd	a5,-1746(a4) # 1000 <freep>
}
 6da:	6422                	ld	s0,8(sp)
 6dc:	0141                	addi	sp,sp,16
 6de:	8082                	ret

00000000000006e0 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 6e0:	7139                	addi	sp,sp,-64
 6e2:	fc06                	sd	ra,56(sp)
 6e4:	f822                	sd	s0,48(sp)
 6e6:	f426                	sd	s1,40(sp)
 6e8:	f04a                	sd	s2,32(sp)
 6ea:	ec4e                	sd	s3,24(sp)
 6ec:	e852                	sd	s4,16(sp)
 6ee:	e456                	sd	s5,8(sp)
 6f0:	e05a                	sd	s6,0(sp)
 6f2:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 6f4:	02051493          	slli	s1,a0,0x20
 6f8:	9081                	srli	s1,s1,0x20
 6fa:	04bd                	addi	s1,s1,15
 6fc:	8091                	srli	s1,s1,0x4
 6fe:	0014899b          	addiw	s3,s1,1
 702:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 704:	00001517          	auipc	a0,0x1
 708:	8fc53503          	ld	a0,-1796(a0) # 1000 <freep>
 70c:	c515                	beqz	a0,738 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 70e:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 710:	4798                	lw	a4,8(a5)
 712:	02977f63          	bgeu	a4,s1,750 <malloc+0x70>
 716:	8a4e                	mv	s4,s3
 718:	0009871b          	sext.w	a4,s3
 71c:	6685                	lui	a3,0x1
 71e:	00d77363          	bgeu	a4,a3,724 <malloc+0x44>
 722:	6a05                	lui	s4,0x1
 724:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 728:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 72c:	00001917          	auipc	s2,0x1
 730:	8d490913          	addi	s2,s2,-1836 # 1000 <freep>
  if(p == (char*)-1)
 734:	5afd                	li	s5,-1
 736:	a88d                	j	7a8 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 738:	00001797          	auipc	a5,0x1
 73c:	8d878793          	addi	a5,a5,-1832 # 1010 <base>
 740:	00001717          	auipc	a4,0x1
 744:	8cf73023          	sd	a5,-1856(a4) # 1000 <freep>
 748:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 74a:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 74e:	b7e1                	j	716 <malloc+0x36>
      if(p->s.size == nunits)
 750:	02e48b63          	beq	s1,a4,786 <malloc+0xa6>
        p->s.size -= nunits;
 754:	4137073b          	subw	a4,a4,s3
 758:	c798                	sw	a4,8(a5)
        p += p->s.size;
 75a:	1702                	slli	a4,a4,0x20
 75c:	9301                	srli	a4,a4,0x20
 75e:	0712                	slli	a4,a4,0x4
 760:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 762:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 766:	00001717          	auipc	a4,0x1
 76a:	88a73d23          	sd	a0,-1894(a4) # 1000 <freep>
      return (void*)(p + 1);
 76e:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 772:	70e2                	ld	ra,56(sp)
 774:	7442                	ld	s0,48(sp)
 776:	74a2                	ld	s1,40(sp)
 778:	7902                	ld	s2,32(sp)
 77a:	69e2                	ld	s3,24(sp)
 77c:	6a42                	ld	s4,16(sp)
 77e:	6aa2                	ld	s5,8(sp)
 780:	6b02                	ld	s6,0(sp)
 782:	6121                	addi	sp,sp,64
 784:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 786:	6398                	ld	a4,0(a5)
 788:	e118                	sd	a4,0(a0)
 78a:	bff1                	j	766 <malloc+0x86>
  hp->s.size = nu;
 78c:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 790:	0541                	addi	a0,a0,16
 792:	00000097          	auipc	ra,0x0
 796:	ec6080e7          	jalr	-314(ra) # 658 <free>
  return freep;
 79a:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 79e:	d971                	beqz	a0,772 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7a0:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7a2:	4798                	lw	a4,8(a5)
 7a4:	fa9776e3          	bgeu	a4,s1,750 <malloc+0x70>
    if(p == freep)
 7a8:	00093703          	ld	a4,0(s2)
 7ac:	853e                	mv	a0,a5
 7ae:	fef719e3          	bne	a4,a5,7a0 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 7b2:	8552                	mv	a0,s4
 7b4:	00000097          	auipc	ra,0x0
 7b8:	b7e080e7          	jalr	-1154(ra) # 332 <sbrk>
  if(p == (char*)-1)
 7bc:	fd5518e3          	bne	a0,s5,78c <malloc+0xac>
        return 0;
 7c0:	4501                	li	a0,0
 7c2:	bf45                	j	772 <malloc+0x92>
