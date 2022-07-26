docker run --name my-redis -p 6379:6379 -d redis

docker exec -it my-redis redis-cli -h 127.0.0.1 -p 6379
docker exec -it my-redis redis-cli -h 172.17.0.3 -p 6379

mkdir -p /opt/mydata/redis/conf

touch /opt/mydata/redis/conf/redis.conf

docker run --name redis  -v /opt/mydata/redis/data:/data  -v /opt/mydata/redis/conf/redis.conf:/etc/redis/redis.conf -p 6379:6379 -d redis  redis-server /etc/redis/redis.conf --restart=always

docker exec -it redis redis-cli


redis.conf
```

```