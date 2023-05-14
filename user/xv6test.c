#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"
#include "kernel/syscall.h"

void test_1(void) {
  int bruh = 12;
  wait(&bruh);
}

void test_2(void) {
  printf("Trying to call audit\n");
  int arr[] = {1, 2, 3, 4, 5};
  int length = 5;
  // call audit with the set array. keep kernel calls on
  printf("edit\n");
  audit(arr, &length);
  // wait should be whitelisted, try it.
  int sec = 2;
  wait(&sec);
}

int main(int argc, char *argv[]) {
  // basic test.
  test_1();
  test_2();

  // test using audit

  exit(0);
}


