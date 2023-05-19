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
#include "file_helper.h"

static int opened = 0;
static struct file *f;

int int_to_char(int num, char *buff){
    int temp = num;
    int len = 0;
    do{
	temp/=10;
	len++;
    }while(temp > 0);

    int i = 0;
    while(i < len){
	buff[i] = num%10 + 48;
	i++;
    }
    return len;
}

void write_to_logs(void *buf){

    char *filename = "/AuditLogs.txt";
    if(!opened){
	f = open(filename, O_CREATE);
	opened = 1;
    }

    if(f == (struct file *)-1)
        panic("ERROR FILE");

    if(f == (struct file *)0) {
        panic("No File");
    }

    printf("6\n");
    //struct audit_node *node = a_list.head;

  //  while(node != 0){
//	char buff[512];
    char *buff = (char *)buf;
    kfilewrite(f, (uint64)(buff), strlen(buff));
}


