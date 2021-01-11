# MySQL 主从配置
简单命令： docker run -d -uroot -e MYSQL_ROOT_PASSWORD=admin --name my-mysql -p 3306:3306 mysql 
# 1. mysql 配置准备
master my.cnf 配置
```
[mysqld]
#主库配置
server_id       = 101
#开启二进制日志
log_bin         = mysql-bin

pid-file        = /var/run/mysqld/mysqld.pid
socket          = /var/run/mysqld/mysqld.sock
datadir         = /var/lib/mysql
log-error       = /var/log/mysql/error.log

secure-file-priv= NULL

# Custom config should go here
!includedir /etc/mysql/conf.d/
```
slave my.cnf 配置
```
[mysqld]
#从库配置
server_id       = 102
#开启二进制日志
log_bin         = mysql-bin
log_slave_updates = 1
relay_log       = mysql-relay-bin
read_only       = 1

pid-file        = /var/run/mysqld/mysqld.pid
socket          = /var/run/mysqld/mysqld.sock
datadir         = /var/lib/mysql
log-error       = /var/log/mysql/error.log

secure-file-priv= NULL

# Custom config should go here
!includedir /etc/mysql/conf.d/
```
# 2. docker 配置
  1. 准备两个docker容器，为了固定docker container IP地址，首先自定义一个Network地址：
  `docker network create --subnet=172.18.0.0/16 mynetwork`
  2. master mysql 命令：（可以改用docker-compose.yml启动）
  `docker run -d -uroot -e MYSQL_ROOT_PASSWORD=admin --name mysql-master --net mynetwork --ip 172.18.0.2 -v ${PWD}/masterCnf/my.cnf:/etc/mysql/my.cnf -v ${PWD}/masterCnf/data:/var/lib/mysql -v ${PWD}/masterCnf/log/mysql:/var/log/mysql -p 3306:3306 mysql`
  3. slave mysql 命令：
  `docker run -d -uroot -e MYSQL_ROOT_PASSWORD=admin --name mysql-slave1 --net mynetwork --ip 172.18.0.3 -v ${PWD}/slave1Cnf/my.cnf:/etc/mysql/my.cnf -v ${PWD}/slave1Cnf/data:/var/lib/mysql -v ${PWD}/slave1Cnf/log/mysql:/var/log/mysql -p 3307:3306 mysql`
 4. 额外查看命令：
    - 进入container查看： docker exec -it mysql-master  /bin/sh
    - 复制镜像配置到本地： docker cp <containerId>:/ ${PWD}
    - 查看当前containerIP地址： docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' <containerId> 

# 3. MySQL主从设置
  1. Master配置
      - 分别在 主 从 创建DB，`sync`。
      - `mysql -u root -p`
      - 创建复制账号repl: `create user 'repl'@'172.18.0.%' identified by 'password';` 
      - 赋予replication slave权限: `grant replication slave on *.* to 'repl'@'172.18.0.%';`
      - `flush privileges;`
      - `Restart mysql server`
      - 执行命令，查看`show master status\G;`
        ```
        mysql> show master status;
        +------------------+----------+--------------+------------------+-------------------+
        | File             | Position | Binlog_Do_DB | Binlog_Ignore_DB | Executed_Gtid_Set |
        +------------------+----------+--------------+------------------+-------------------+
        | mysql-bin.000004 |      156 |              |                  |                   |
        +------------------+----------+--------------+------------------+-------------------+
        1 row in set (0.00 sec)
        ```
  2. Slave配置
      - `mysql -u root -p`
      - `CHANGE MASTER TO MASTER_HOST='172.18.0.2',MASTER_USER='repl',MASTER_PASSWORD='password',MASTER_LOG_FILE='mysql-bin.000004',MASTER_LOG_POS=156, GET_MASTER_PUBLIC_KEY=1;`
      - `start slave;`
      - `stop slave;`
      - 查看同步状态 `show slave status\G;`


# 4. MySQL主从设置排坑过程
1. 坑1：主从同步设置成功之后，遇到无法同步的情况。
```
2020-11-08T06:59:25.249362Z 12 [ERROR] [MY-010584] [Repl] Slave I/O for channel '': error connecting to master 'repl@172.18.0.2:3306' - retry-time: 60 retries: 1 message: Authentication plugin 'caching_sha2_password' reported error: Authentication requires secure connection. Error_code: MY-002061

 show slave status\G;
*************************** 1. row ***************************
               Slave_IO_State: Waiting for master to send event
                  Master_Host: 172.18.0.2
                  Master_User: repl
                  Master_Port: 3306
                Connect_Retry: 60
              Master_Log_File: mysql-bin.000004
          Read_Master_Log_Pos: 1067
               Relay_Log_File: mysql-relay-bin.000002
                Relay_Log_Pos: 324
        Relay_Master_Log_File: mysql-bin.000004
             Slave_IO_Running: Connecting
            Slave_SQL_Running: No
```
> 其错误码为：Error_code: MY-002061,这是因为MySQL 8默认启用了caching_sha2_password authentication plugin。官方文档在CHANGE MASTER TO添加GET_MASTER_PUBLIC_KEY=1参数来解决这个问题。
官网地址：https://dev.mysql.com/doc/refman/8.0/en/upgrading-from-previous-series.html#upgrade-caching-sha2-password-replication

2. 坑2：主从同步设置成功之后，遇到错误，slave一直卡住的情况。
```
2020-11-08T07:20:01.810120Z 16 [ERROR] [MY-010584] [Repl] Slave SQL for channel '': Error 'Unknown database 'sync'' on query. Default database: 'sync'. Query: 'CREATE TABLE `student` (
 	`id` INT NOT NULL AUTO_INCREMENT,
 	`name` VARCHAR(50) NULL DEFAULT NULL,
 	PRIMARY KEY (`id`)
 ) COLLATE='utf8mb4_0900_ai_ci'', Error_code: MY-001049

mysql> show slave status\G;
*************************** 1. row ***************************
               Slave_IO_State: Waiting for master to send event
                  Master_Host: 172.18.0.2
                  Master_User: repl
                  Master_Port: 3306
                Connect_Retry: 60
              Master_Log_File: mysql-bin.000004
          Read_Master_Log_Pos: 1067
               Relay_Log_File: mysql-relay-bin.000002
                Relay_Log_Pos: 324
        Relay_Master_Log_File: mysql-bin.000004
             Slave_IO_Running: Yes
            Slave_SQL_Running: No
              Replicate_Do_DB:
          Replicate_Ignore_DB:
           Replicate_Do_Table:
       Replicate_Ignore_Table:
      Replicate_Wild_Do_Table:
  Replicate_Wild_Ignore_Table:
                   Last_Errno: 1050
                   Last_Error: Error 'Table 'student' already exists' on query. Default database: 'sync'. Query: 'CREATE TABLE `student` (
        `id` INT NOT NULL AUTO_INCREMENT,
        `name` VARCHAR(50) NULL DEFAULT NULL,
        PRIMARY KEY (`id`)
)
```
> 其错误码为：Error_code：MY-001049。 
> 方案1：停掉主从同步，忽略一次错误，再开启同步： stop slave; set global sql_slave_skip_counter=1;  startslave;



=================================
分库分表


shardingDS1：
docker run -uroot -e MYSQL_ROOT_PASSWORD=admin --name shardingDS1 --net mynetwork --ip 172.18.1.11 -v ${PWD}/shardingDS1/my.cnf:/etc/mysql/my.cnf -v ${PWD}/shardingDS1/data:/var/lib/mysql -v ${PWD}/shardingDS1/log/mysql:/var/log/mysql -p 3306:3306 --restart always -d mysql

shardingDS2：
docker run -uroot -e MYSQL_ROOT_PASSWORD=admin --name shardingDS2 --net mynetwork --ip 172.18.1.12 -v ${PWD}/shardingDS2/my.cnf:/etc/mysql/my.cnf -v ${PWD}/shardingDS2/data:/var/lib/mysql -v ${PWD}/shardingDS2/log/mysql:/var/log/mysql -p 3307:3306 -d mysql

shardingDS3：
docker run -uroot -e MYSQL_ROOT_PASSWORD=admin --name shardingDS3 --net mynetwork --ip 172.18.1.13 -v ${PWD}/shardingDS3/my.cnf:/etc/mysql/my.cnf -v ${PWD}/shardingDS3/data:/var/lib/mysql -v ${PWD}/shardingDS3/log/mysql:/var/log/mysql -p 3308:3306 -d mysql


---------
docker run -uroot -e MYSQL_ROOT_PASSWORD=admin --name shardingDS3 --net mynetwork --ip 172.18.1.13 -v ${PWD}/shardingDS3/my.cnf:/etc/mysql/my.cnf -v ${PWD}/shardingDS3/data:/var/lib/mysql -v ${PWD}/shardingDS3/log/mysql:/var/log/mysql -p 3306:3306 --restart always -d mysql:5.7.32