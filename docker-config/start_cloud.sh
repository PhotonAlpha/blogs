#!/bin/sh
echo "test xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
exec java -jar -Xms128m -Xmx256m -Dspring.profiles.active=${SPRING_PROFILES_ACTIVE} /eureka-server.jar  > /logs/api_${SPRING_PROFILES_ACTIVE}_server.log
#nohup java -jar -Xms128m -Xmx128m /app.jar -Dspring.profiles.active=prod > /logs/api_prod_server.log &
