#include "user/user.h"

int main(int argc, char *argv[]) {
    struct audit_node node = {.process_name = "Proc1\n", .pid = 0};  
    struct audit_node node1;
    struct audit_node node2;
    struct audit_node node3; 


    node.process_name = "PROC0\n";
    node1.process_name = "PROC1\n";
    node2.process_name = "PROC2\n";
    node3.process_name = "PROC3\n";

    node.next = &node1;
    node1.next = &node2;
    node2.next = &node3;

    struct audit_list auditlist;
    auditlist.size = 4;
    auditlist.head = &node;

    //write_to_logs((void *)&auditlist);

    return 1;
}
