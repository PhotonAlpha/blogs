参考文件地址： docker-config/docker-compose.yml

1. 创建镜像
  docker build -t docker-eureka-server:1.0.0 .

  - 尝试测试有没有成功
  docker run --name eureka-7001 -p 7001:7001 -v ${PWD}:/logs/ -e "SPRING_PROFILES_ACTIVE=eureka1" -d docker-eureka-server:1.0.0
  添加 `--restart always`, 总是重启
    
    spring boot 使用两种方式启用active
      1. `-e "SPRING_PROFILES_ACTIVE=eureka1"` 不添加 `-Dspring.profiles.active`
      2. 使用 `-Dspring.profiles.active=${SPRING_PROFILES_ACTIVE}` 传递环境变量

  - 出现问题不确定image是否打包成功
   docker run -it docker-eureka-server:1.0.0 sh 

2. 创建docker compose
  `docker-compose up -d`


docker run -d -p 8088:8088 -v %cd%:/logs/ com/ethan:1.0.0


docker image prune -f

docker exec -it ee0de47e9454  /bin/sh
docker logs --tail all d962c817e676

> in PowerShell

docker run --name my-spring-boot-docker -d -p 8088:8088 -p 8188:8188 -p 8288:8288 -v D:/logs:/logs/ com/ethan:1.0.0
docker ps -aq | % { docker stop $_ }
docker ps -aq | % { docker rm $_ }

# set timezone:
docker run -e "TZ=Asia/Shanghai"