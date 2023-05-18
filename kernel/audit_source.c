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

static struct inode*
create(char *path, short type, short major, short minor)
{
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    return 0;

  ilock(dp);

  if((ip = dirlookup(dp, name, 0)) != 0){
    iunlockput(dp);
    ilock(ip);
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
      return ip;
    iunlockput(ip);
    return 0;
  }

  if((ip = ialloc(dp->dev, type)) == 0){
    iunlockput(dp);
    return 0;
  }

  ilock(ip);
  ip->major = major;
  ip->minor = minor;
  ip->nlink = 1;
  iupdate(ip);

  if(type == T_DIR){  // Create . and .. entries.
    // No ip->nlink++ for ".": avoid cyclic ref count.
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
      goto fail;
  }

  if(dirlink(dp, name, ip->inum) < 0)
    goto fail;

  if(type == T_DIR){
    // now that success is guaranteed:
    dp->nlink++;  // for ".."
    iupdate(dp);
  }

  iunlockput(dp);
  printf("Happy\n");
  return ip;

 fail:
  // something went wrong. de-allocate ip.
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}


struct file *open(char *filename){
    int omode;
    struct file *f;
    struct inode *ip;

    omode = O_CREATE;
    if(strlen(filename) < 0)
	return (struct file *)-1;

    begin_op();
    if(omode & O_CREATE){
	ip = create(filename, T_FILE, 0, 0);
	if(ip == 0){
	    end_op();
	    return (struct file *)-1;
	}
    } else {
	printf("NOOO\n");
	if((ip = namei(filename)) == 0){
	    end_op();
	    printf("OOPs");
	    //this is where it breaks`
	    return (struct file *)-1;
	}
    }
    printf("Gone\n");
//    ilock(ip);

    printf("Gone\n");
    if(ip->type == T_DIR && omode != O_RDONLY){
	iunlockput(ip);
	end_op();
	return (struct file *)-1;
    }
    printf("1\n");
    

    if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
	iunlockput(ip);
	end_op();
	return (struct file *)-1;
    }

	printf("2\n");
    if((f = filealloc()) == 0){
	if(f)
	    fileclose(f);
	iunlockput(ip);
	end_op();
	return (struct file *)-1;
    }

	printf("3\n");
   f->type = FD_INODE;
   f->off = 0;
   f->ip = ip;
   f->readable = !(omode & O_WRONLY);
   f->writable = (omode & O_WRONLY) || (omode & O_RDWR);

   if((omode & O_TRUNC) && ip->type == T_FILE){
     itrunc(ip);
   }

	printf("4\n");
   //iunlock(ip);
   end_op();

	printf("5\n");
   return f;
}

void write_to_logs(void *list){
    struct file *f;
    char *filename = "/AuditLogs.txt";
    
    f = open(filename);

//    uint64 fd = open(filename);
    if(f == (struct file *)-1)
	exit(0);

    printf("6\n");
    char temp[5] = "happ";
    filewrite(f, (uint64)(temp), 5);

    printf("What\n");


}
