最近Mac经常出现npm安装 access denine的问题

> path /Users/caoqiang/Desktop/workspace/workspace_idea/photonalpha.github.io/Portal/node_modules/react
> npm ERR! code EACCES
> npm ERR! errno -13
> npm ERR! syscall access
> npm ERR! Error: EACCES: permission denied, access '/Users/caoqiang/Desktop/workspace/workspace_idea/photonalpha.github.io/Portal/node_modules/react'

`ls -la` 发现权限都为root

    drwxr-xr-x  1137 root      staff  36384 Apr  1 21:50 .
    drwxr-xr-x    17 xxxx      staff    544 Apr  1 21:49 ..
    drwxr-xr-x    49 root      staff   1568 Apr  1 21:49 .bin
    drwxr-xr-x    12 root      staff    384 Apr  1 21:49 @babel
    drwxr-xr-x     8 root      staff    256 Apr  1 21:49 abab
    drwxr-xr-x     7 root      staff    224 Apr  1 21:49 accepts

使用权限修改命令 `sudo chown -R ownerName: /usr/local/lib/node_modules`

