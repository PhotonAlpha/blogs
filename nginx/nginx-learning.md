#  nginx 常用命令 
    [root@localhost nginx]# nginx -h
    nginx version: nginx/1.10.2
    Usage: nginx [-?hvVtTq] [-s signal] [-c filename] [-p prefix] [-g directives]

    Options:
    -?,-h         : this help
    -v            : show version and exit
    -V            : show version and configure options then exit
    -t            : test configuration and exit
    -T            : test configuration, dump it and exit
    -q            : suppress non-error messages during configuration testing
    -s signal     : send signal to a master process: stop, quit, reopen, reload
    -p prefix     : set prefix path (default: /usr/local/nginx/)
    -c filename   : set configuration file (default: /usr/local/nginx/conf/nginx.conf)
    -g directives : set global directives out of configuration file
> Nginx 仅有几个命令行参数，完全通过配置文件来配置

> -c </path/to/config> 为 Nginx 指定一个配置文件，来代替缺省的。

> -t 不运行，而仅仅测试配置文件。nginx 将检查配置文件的语法的正确性，并尝试打开配置文件中所引用到的文件。

> -v 显示 nginx 的版本。

> -V 显示 nginx 的版本，编译器版本和配置参数。    

## 1.启动 nginx
    [root@localhost ~]# nginx

## 2.停止 nginx
    [root@localhost ~]# nginx -s stop  
    or  
    [root@localhost ~]# nginx -s quit
## 3.重载  nginx
    [root@localhost ~]# nginx -s reload  
    or  
    [root@localhost ~]# nginx -s quit
## 4.指定配置文件
    [root@localhost ~]# nginx -c /usr/local/nginx/conf/nginx.conf
## 5. 检查配置文件是否正确
    [root@localhost ~]# nginx -t
## 6. 帮助信息
    [root@localhost ~]# nginx -h  
    or  
    [root@localhost ~]# nginx -?
## 7. 查看 Nginx 版本
    [root@localhost ~]# nginx -v
    or
    [root@localhost ~]# nginx -V