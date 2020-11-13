# Zookeeper 主从配置
简单命令： docker run --name my-zookeeper -p 2181:2181 --restart always -d zookeeper
客户端命令： docker exec -it my-zookeeper  /bin/sh
# 1. 配置服务器的编号
zkData 文件夹创建 文件 myid, 给唯一ID

Docker命令： docker run -d --name zookeeper-1 --net mynetwork --ip 172.18.0.10 -v ${PWD}/zkMater/conf:/etc/mysql/my.cnf -v ${PWD}/masterCnf/data:/var/lib/mysql -v ${PWD}/masterCnf/log/mysql:/var/log/mysql -p 3306:3306 zookeeper


/ZkMater/zkData:/tmp/zkData

# 2. 配置服务器信息
```
## cluster
#server.2=ip:2888:3888
#server.3=ip:2888:3888
#server.4=ip:2888:3888
```
配置参数
server.A=B:C:D
A是一个数字，表示这个服务器的唯一编号
B是这个服务器的IP地址
C是这个服务器与集群中的Leader服务器交换信息的端口
D是万一一个集群中的Leader服务器挂了，需要一个端口来重新进行选举，选出一个新的Leader,而这个端口就是用来执行选举时服务器相互通信的端口。

# 3. 启动服务器

# 4. 集群操作
> zkServer.sh start
> zkServer.sh status 查看状态
> zkServer.sh stop
客户端命令
> ls <path> [watch]  简单信息
> ls2 <path>  详细信息
> set <path> data  修改节点信息
> get <path> [watch] 查看节点信息
> stat <path> 查看所有节点信息
> delete <path> [version]
> rmr <path> 定位删除
> create [-s]（顺序节点） [-e]（临时节点） <path> data acl(访问权限)
> quit



参考配置：
```
dataDir=/data
dataLogDir=/datalog
tickTime=2000
initLimit=5
syncLimit=2
autopurge.snapRetainCount=3
autopurge.purgeInterval=0
maxClientCnxns=60
standaloneEnabled=true
admin.enableServer=true
server.1=localhost:2888:3888;2181
```
