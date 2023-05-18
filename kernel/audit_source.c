#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "stat.h"
#include "spinlock.h"
#include "proc.h"
#include "fs.h"
#include "sleeplock.h"
#include "file.h"
#include "fcntl.h"

#include "audit_list.h"
#include "file_helper.h"

void write_to_logs(void *list){
    struct file *f;
    char *filename = "/AuditLogs.txt";
    f = open(filename, O_CREATE);

    f = open(filename, O_RDWR);
   
    if(f == (struct file *)-1)
	panic("ERROR FILE");

    if(f == (struct file *)0) {
	panic("No File");
    }
    printf("6\n");
    char *temp = "happy\n";
    printf("writable: %d\n", f -> writable);

    if (kfilewrite(f, (uint64)(temp), 7) <= 0){

	printf("What\n");
    }
   
    printf("What1\n");

}
