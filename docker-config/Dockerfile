FROM openjdk:11.0-jdk
ENV TZ=Asia/Shanghai
ENV LANG=zh_CN.UTF-8 \
    LC_ALL=zh_CN.UTF-8
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
VOLUME /tmp
COPY start_cloud.sh /usr/bin/start_cloud.sh
RUN chmod +x /usr/bin/start_cloud.sh
RUN mkdir -p /logs
COPY build/libs/cloud-eureka-server-1.0.0.jar eureka-server.jar
# ENTRYPOINT ["java", "-Xms128m","-Xmx256m", "-jar", "/eureka-server.jar", "-c"]

CMD ["start_cloud.sh"]