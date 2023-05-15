struct audit_node {
    struct audit_node *next;
    int pid;
    int time_stamp;
    int perms;

    char *process_name;
    char *syscall_name;
};

struct audit_list {
    int size;
    struct audit_node *head;
};
