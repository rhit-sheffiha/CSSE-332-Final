#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "riscv.h"
#include "spinlock.h"
#include "proc.h"
#include "syscall.h"
#include "fs.h"
#include "sleeplock.h"
#include "file.h"
#include "defs.h"
#include "audit_source.h"

struct audit_data {
  // process information
  int process_pid;
  char* process_name;

  // did it use a file?
  int fd_used;

  // what are the perms if it did?
  int fd_read;
  int fd_write;

  // what call did it make?
  char* call_name;
  
  // what time was the call at?
  uint64 time;
};

#define MAX_SIZE 1024
struct audit_data bruh[MAX_SIZE];
int num_entries = 0;
int prev_tickss = 0;
char buff [2048];
int offset = 0;

// excluding audit, since it should ALWAYS be apparent.
#define NUM_SYS_CALLS 21

// set everything to be whitelisted by default
char whitelisted[NUM_SYS_CALLS] = 
                        {1, 1, 1, 1, 1,
                         1, 1, 1, 1, 1,
                         1, 1, 1, 1, 1,
                         1, 1, 1, 1, 1,
                         1};

char* name_from_num[] = {"unknown",
                        "fork", "exit", "wait",
                        "pipe", "read", "kill",
                        "exec", "fstat", "chdir",
                        "dup", "getpid", "sbrk",
                        "sleep", "uptime", "open",
                        "write", "mknod", "unlink", 
                        "link", "mkdir", "close", "audit"};

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

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
// copied straight from sysfile.c instead of doing all imports
static int
argfd(int n, int *pfd, struct file **pf)
{
  int fd;
  struct file *f;

  argint(n, &fd);
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    return -1;
  if(pfd)
    *pfd = fd;
  if(pf)
    *pf = f;
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
extern uint64 sys_check(void);

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
[SYS_check]   sys_check,
};

void
syscall(void)
{
  int num;
  struct proc *p = myproc();

  // any time we are here, we are about to make a system call.
  // we can intercept args, etc.
  num = p->trapframe->a7;
   if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0

    // steal the file away, if there is one, before we return a0.
    int fd = -1;
    struct file *f;

    // if it's any of these file related operations
    if (num == SYS_read || num == SYS_fstat || num == SYS_dup 
        || num == SYS_open || num == SYS_write || num == SYS_close) {
      // we are trying to do SOMETHING with this file.
      argfd(0, &fd, &f);
    }
    
    // let the system call go through.
    p->trapframe->a0 = syscalls[num]();
    if (num == 22) {
      // it was an audit call. Retrieve the number and parse the bits into an array.
      uint audit_num = (uint) p->trapframe->a0;
      for (int i = 0; i < NUM_SYS_CALLS; i++) {
        whitelisted[i] = 0; // reset the array position first.
        // just and it with 32-bit 1
        if (audit_num & 0b00000000000000000000000000000001) { // bit was toggled, whitelist
          whitelisted[NUM_SYS_CALLS - i] = 1;
        }
        // shift it right by 1
        audit_num = audit_num >> 1;
      }
    }

    // it should always be apparent when audit is called.
    if (whitelisted[num - 1] || num == SYS_audit) {
      // these things will be consistent across processes, no matter if it used a file
    if(ticks - prev_tickss > 100){
       write_to_logs((void *)buff);
       prev_tickss = ticks;
       offset = 0;
       buff[0] = '\0';
    }

      struct audit_data cur;
      cur.process_pid = p->pid;
      cur.process_name = p->name;
      cur.time = ticks;
      cur.process_name = name_from_num[num];
      if (fd != -1) {
        // need to set fd info
        cur.fd_used = 1;
        cur.fd_read = f->readable;
        cur.fd_write = f->writable;


	strncpy(buff + offset,p->name, strlen(p->name));
	offset += strlen(p->name);
	buff[offset] = '\t';
	offset += 1;
	strncpy(buff + offset,name_from_num[num], strlen(name_from_num[num]));
	offset += strlen(name_from_num[num]);
	buff[offset] = '\t';
	offset += 1;
    /*
	strncpy("FD With Permissions r: ", buff + offset, 23);
	buff[offset + 1] = f->readable ? 49: 48;
	offset+=1;
//	strncpy(" w: ", buff + offset, 4);
	buff[offset + 1] = f->writable ? 49: 48;
	offset +=1;
    */
	buff[offset] = '\n';
        offset +=1;
	
//        printf("Process %s pid %d called syscall %s at time %d and used FD %d (perms r: %d, w: %d)\n",
//                p->name, p->pid, name_from_num[num], ticks, fd, f->readable, f->writable);
      } else {
        // just say we didn't use one
        cur.fd_used = 0;
	

	strncpy(buff + offset,p->name, strlen(p->name));
	offset += strlen(p->name);
	buff[offset] = '\t';
	offset += 1;
	strncpy(buff + offset,name_from_num[num], strlen(name_from_num[num]));
	offset += strlen(p->name);

	buff[offset] = '\n';
        offset +=1;
	
	
//        printf("Process %s pid %d called syscall %s at time %d\n", 
//                p->name, p->pid, name_from_num[num], ticks);
      }
      // here just so we don't throw unused variable errors
      int bruh = cur.process_pid;
      bruh++;
    }
  } else {
    printf("%d %s: unknown sys call %d\n",
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
  }
}
