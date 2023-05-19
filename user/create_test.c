#include "kernel/types.h"
#include "user/user.h"
#include "kernel/audit_list.h"

int main(int argc, char *argv[]) {
    /*
    struct audit_list *list = malloc(sizeof(struct audit_list));
    struct audit_node node;

    node.pid = 0;
    node.time_stamp = 0;
    list -> head = node;
    */
    check((void*)0);

    exit(0);

}
