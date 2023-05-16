#include "kernel/audit_source.c"

int main(int argc, char *argv[]) {
    struct audit_list *auditlist = malloc(sizeof(struct audit_list));
    struct audit_node *node = malloc(sizeof(struct audit_node));
    struct audit_node *node1 =  malloc(sizeof(struct audit_node));
    struct audit_node *node2 =  malloc(sizeof(struct audit_node));
    struct audit_node *node3 =  malloc(sizeof(struct audit_node));

    auditlist -> head = node;

    node -> next = node1;
    node1 -> next = node2;
    node2 -> next = node3;

    node -> process_name = "PROC0\n";
    node1 -> process_name = "PROC1\n";
    node2 -> process_name = "PROC2\n";
    node3 -> process_name = "PROC3\n";

    write_to_logs((void *)auditlist);

    return 1;
}
