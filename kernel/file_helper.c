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




int
fdalloc(struct file *f)
{
  int fd;
  struct proc *p = myproc();

  for(fd = 0; fd < NOFILE; fd++){
    if(p->ofile[fd] == 0){
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
}

struct inode*
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
    int fd, omode;
    struct file *f;
    struct inode *ip;

    omode = O_WRONLY;
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
	    return (struct file *)-1;
	}
    
	ilock(ip);

	if(ip->type == T_DIR && omode != O_RDONLY){
	    iunlockput(ip);
	    end_op();
	    return (struct file *)-1;
	}
    }
    printf("1\n");
    

    if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
	iunlockput(ip);
	end_op();
	return (struct file *)-1;
    }

	printf("2\n");
    if((f = filealloc()) == 0 || (fd = fdalloc(f) < 0)){
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
   f->writable = O_WRONLY;

   if((omode & O_TRUNC) && ip->type == T_FILE){
     itrunc(ip);
   }

	printf("4\n");
   iunlock(ip);
   end_op();

	printf("5\n");
   return f;
}


