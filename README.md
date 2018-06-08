# **photon-repository-tasklist**

- [x] intergrate kafka with spring bus

- [x] spring cloud config password encrypt
> keytool -genkeypair -alias config-server-key -keyalg RSA -keysize 4096 -sigalg SHA512withRSA -dname 'CN=Config Server,OU=Spring Cloud,O=Baeldung' -keypass my-k34-s3cr3t -keystore config-server.jks  -storepass my-s70r3-s3cr3t
- [x] jasypt encrypt

- [x] docker-compose with nginx and springboot
- [ ] nginx config
- [ ] docker Swarm

- [ ] intergate mongoDB and redis

- [ ] spring start gateway & cloud stream

- [ ] use RPC backend service communicate

- [ ] start learning netty


--------------------------
Quartz JDBC job store: <https://examples.javacodegeeks.com/enterprise-java/quartz/java-quartz-configuration-example/>
        Tables: https://github.com/quartznet/quartznet/tree/master/database




>Your link is working, but you're on separate networks inside of Docker. From the docker-compose.yml docs:
>
>Note: If you’re using the version 2 file format, the externally-created containers must be connected to at least one of the same networks as the service which is linking to them.
>
>To solve this, you can create your own network:
>
>docker network create dbnet
>docker network connect dbnet mysql



https://github.com/phpsb/book
https://github.com/cjl3080434008/2014/tree/master/read_book
https://github.com/EbookFoundation/free-programming-books/blob/master/free-programming-books-zh.md

spring 3.x 异常处理方案：
http://www.baeldung.com/exception-handling-for-rest-with-spring



Jmeter
https://github.com/qiuchunjoy/jmeter
React js rumen
https://github.com/brickspert/blog/issues/1
https://github.com/xiaomuzhu/vue-ts-daily/tree/master/src TS Project
plugin: https://juejin.im/entry/599d4cb96fb9a024a27bf090
----nginx----
* 静态web服务器 反向代理服务器
* nginx -t 检测配置错误
* nginx -s stop 
* nginx -s reload 重新加载

        http {
            server_tokens off;//禁用版本号
            upstream tomcats {/负载均衡策略
                server 127.0.0.1:8080;
                server 127.0.0.1:8080;
                server 127.0.0.1:8080;
            }
            server {
                listen       80; //端口
                server_name  a.ttlsa.com; //DNS解析  C:\Windows\System32\drivers\etc\hosts
                location / { //反向代理 也可以正向代理
                        proxy_set_header X-Forwarded-Host $host;
                        proxy_set_header X-Forwarded-Server $host;
                        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                        proxy_pass http://tomcats;
                }
            }
                //静态网页地址
            server {
                server_name b.ttlsa.com c.ttlsa.com;
                listen 127.0.0.1:80;
                root data/site/b.ttlsa.com;
                access_log data/logs/nginx/b.ttlsa.com-access.log main;
                location / {

                }
            }
        }
