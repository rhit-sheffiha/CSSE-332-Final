#include "kernel/param.h"
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/fs.h"
#include "kernel/fcntl.h"
#include "kernel/syscall.h"
#include "kernel/memlayout.h"
#include "kernel/riscv.h"


int main(int argc, char *argv[]) {
  uint64 p = 0xdeadbeef;

  try2((void*)p);

  exit(0);
}
