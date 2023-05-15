#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/syscall.h"

void test_1(void) {
  printf("Test 1: Simple syscall\n");
  int bruh = 12;
  wait(&bruh);
}

void test_2(void) {
  printf("bruh\n");

}

int main(int argc, char *argv[]) {
  // basic test.
  test_1();
  test_2();

  // test using audit

  exit(0);
}


