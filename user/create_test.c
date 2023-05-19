#include "kernel/types.h"
#include "user/user.h"

int main(int argc, char *argv[]) {
    uint64 p = 0xDEADBEEF;

    check((void*) p);

    exit(0);

}
