#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "syscall.h"
#include "defs.h"
#include "audit_list.h"
#include "audit_source.h"

#define MAX_SIZE 1024
struct audit_data bruh[MAX_SIZE];
struct audit_list list;

// idea that is if we're in one of these, we need
// to fetch file fd. This changes a0, so we need to know.
int file_processes[] = {5, 9, 16, 17, 22};

// currently have 22 system calls; so all of them could potentially be whitelisted...
# define NUM_CALLS 22
int whitelisted[NUM_CALLS] = {0};
int declared_length = 0;

char* name_from_num[] = {"unknown",
                        "fork", "exit", "wait",
                        "pipe", "read", "kill",
                        "exec", "fstat", "chdir",
                        "dup", "getpid", "sbrk",
                        "sleep", "uptime", "open",
                        "write", "mknod", "unlink", 
                        "link", "mkdir", "close", "audit"};

struct aud {
  int* arr;
  int* length;
};


// Fetch the uint64 at addr from the current process.
int
fetchaddr(uint64 addr, uint64 *ip)
{
  struct proc *p = myproc();
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    return -1;
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    return -1;
  return 0;
}

// Fetch the nul-terminated string at addr from the current process.
// Returns length of string, not including nul, or -1 for error.
int
fetchstr(uint64 addr, char *buf, int max)
{
  struct proc *p = myproc();
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    return -1;
  return strlen(buf);
}

static uint64
argraw(int n)
{
  struct proc *p = myproc();
  switch (n) {
  case 0:
    return p->trapframe->a0;
  case 1:
    return p->trapframe->a1;
  case 2:
    return p->trapframe->a2;
  case 3:
    return p->trapframe->a3;
  case 4:
    return p->trapframe->a4;
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
  *ip = argraw(n);
}

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
  *ip = argraw(n);
}

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
  uint64 addr;
  argaddr(n, &addr);
  return fetchstr(addr, buf, max);
}

// Prototypes for the functions that handle system calls.
extern uint64 sys_fork(void);
extern uint64 sys_exit(void);
extern uint64 sys_wait(void);
extern uint64 sys_pipe(void);
extern uint64 sys_read(void);
extern uint64 sys_kill(void);
extern uint64 sys_exec(void);
extern uint64 sys_fstat(void);
extern uint64 sys_chdir(void);
extern uint64 sys_dup(void);
extern uint64 sys_getpid(void);
extern uint64 sys_sbrk(void);
extern uint64 sys_sleep(void);
extern uint64 sys_uptime(void);
extern uint64 sys_open(void);
extern uint64 sys_write(void);
extern uint64 sys_mknod(void);
extern uint64 sys_unlink(void);
extern uint64 sys_link(void);
extern uint64 sys_mkdir(void);
extern uint64 sys_close(void);
extern uint64 sys_audit(void);
extern uint64 sys_logs(void);

// An array mapping syscall numbers from syscall.h
// to the function that handles the system call.
static uint64 (*syscalls[])(void) = {
[SYS_fork]    sys_fork,
[SYS_exit]    sys_exit,
[SYS_wait]    sys_wait,
[SYS_pipe]    sys_pipe,
[SYS_read]    sys_read,
[SYS_kill]    sys_kill,
[SYS_exec]    sys_exec,
[SYS_fstat]   sys_fstat,
[SYS_chdir]   sys_chdir,
[SYS_dup]     sys_dup,
[SYS_getpid]  sys_getpid,
[SYS_sbrk]    sys_sbrk,
[SYS_sleep]   sys_sleep,
[SYS_uptime]  sys_uptime,
[SYS_open]    sys_open,
[SYS_write]   sys_write,
[SYS_mknod]   sys_mknod,
[SYS_unlink]  sys_unlink,
[SYS_link]    sys_link,
[SYS_mkdir]   sys_mkdir,
[SYS_close]   sys_close,
[SYS_audit]   sys_audit,
[SYS_logs]    sys_logs,
};


void
syscall(void)
{
  int num;
  struct proc *p = myproc();

  num = p->trapframe->a7;
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0

    p->trapframe->a0 = syscalls[num]();
    // if our system call was AUDIT, we specifically need to take what's in a0
    // out right here. this contains the whitelist array for what calls to audit
    if (num == 22) {
      // audit call.
      struct aud* bruh = (struct aud*)p->trapframe->a0;
      printf("edit in kernel\n");
      for (int i = 0; i < *(bruh->length); i++) {
        whitelisted[i] = *(bruh->arr + i);
      }
      declared_length = *(bruh->length);
      //printf("process %s with id %d called audit at time %d\n", p->name, p->pid, ticks);
      printf("declared length: %d\n", declared_length);
    }
    if (!declared_length) {
      // nothing is whitelisted.
      printf("process %s with id %d called %s at time %d\n", p->name, p->pid, name_from_num[num], ticks);
    } else {
      // something is whitelisted.
      for (int i = 0; i < declared_length; i++) {
        // if it's whitelisted, we care. otherwise, just let it time out.
        if (num == whitelisted[i]) {
          printf("process %s with id %d called %s at time %d\n", p->name, p->pid, name_from_num[num], ticks);
        }
      }
    }

  } else {
    printf("%d %s: unknown sys call %d\n",
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
  }

}
