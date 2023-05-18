int
kfilewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0){
    printf("First\n");
    return -1;
  }
  if(f->type == FD_PIPE){
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write){
      return -1;
    }
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    // write a few blocks at a time to avoid exceeding
    // the maximum log transaction size, including
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
      ilock(f->ip);
      if ((r = writei(f->ip, 0, addr + i, f->off, n1)) > 0)
        f->off += r;
      iunlock(f->ip);
      end_op();

      if(r != n1){
        // error from writei
        break;
      }
      i += r;
    }
    ret = (i == n ? n : -1);
  } else {
    panic("filewrite");
  }
  return ret;
}

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
  printf("Successfully Created\n");
  return ip;

 fail:
  // something went wrong. de-allocate ip.
  printf("actually fails\n");
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}


struct file *open(char *filename, int omode){
    int fd;
    struct file *f;
    struct inode *ip;

    if(strlen(filename) < 0)
        return (struct file *)-1;

    begin_op();
    if(omode & O_CREATE){
        printf("CREATING\n");
        ip = create(filename, T_FILE, 0, 0);
        if(ip == 0){
            printf("Create Broke\n");
            end_op();
            return (struct file *)-1;
        }
    } else {
        printf("EXSITS ALREADY\n");
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

