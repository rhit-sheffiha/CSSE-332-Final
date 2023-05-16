#include "audit_list.h"
#include "types.h"
#include "user/user.h"
#include "kernel/fcntl.h"

void write_to_logs(void *list){
    char *filename = "AuditLogs.txt";
    int fd = open(filename, O_CREATE | O_WRONLY);

//    uint64 fd = open(filename);
    
    //write(fd, data, strlen(data)); 
    struct audit_list *auditlist = (struct audit_list *)list;
    struct audit_node *node = auditlist -> head;
    while(node != 0){
	write(fd, node -> process_name, strlen(node -> process_name));
	node = node -> next;
    }



}
