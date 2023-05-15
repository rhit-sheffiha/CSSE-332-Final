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
  printf("Test 2: Using audit\n");
  // set up a binary number to be what we want to whitelist. 
  // so just whitelist the first 5 syscalls,
  // being fork, exit, wait, pipe, read

  int whitelist = 0b11111000000000000000000000000000;
  audit(whitelist);

  // call wait, which should make an audit log
  int sec = 5;
  wait(&sec);

  // printf calls write, so let's see if that gets an audit
  printf("is there a write audit?\n");

  // call sleep, which should NOT make an audit log
  sec = 1;

  // coincidentally this prints under wait because
  // sleep just makes the thread wait... *shrug*
  sleep(sec);
}

int main(int argc, char *argv[]) {
  // basic test.
  test_1();
  test_2();

  // test using audit

  exit(0);
}


