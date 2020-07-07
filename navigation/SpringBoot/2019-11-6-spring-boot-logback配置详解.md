# Spring Boot logback 配置

## 1. Common Logback Config with Spring Boot
```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
	<include resource="org/springframework/boot/logging/logback/defaults.xml"/>
	<springProperty scope="context" name="springAppName" source="spring.application.name" defaultValue="creed"/>
	<springProperty scope="context" name="countryCode" source="logging" defaultValue="CN"/>
	<springProfile name="dev">
		<springProperty scope="context" name="log-directory" source="logging.dir" defaultValue="/logs" />
		<springProperty scope="context" name="instance" source="logging.instance" defaultValue="spring-creed" />
	</springProfile>
	<springProfile name="!dev">
		<springProperty scope="context" name="log-directory" source="logging.dir" defaultValue="/logs" />
		<springProperty scope="context" name="instance" source="logging.instance" defaultValue="spring-creed" />
	</springProfile>

	<property scope="context" name="max-file-size" value="250MB" />
	<property scope="context" name="max-history" value="20" />
	<property scope="context" name="total-size-cap" value="5GB" />

	<property scope="context" name="log-pattern" value="%d{yyyy-MM-dd HH:mm:ss.SSS} [${countryCode}] ${LOG_LEVEL_PATTERN:-%5p} ${PID:- } --- [%15.15t] %-40.40logger{39}[%line] : %m%n" />
	<property scope="context" name="console-pattern" value="%clr(%d{yyyy-MM-dd HH:mm:ss.SSS}){faint} [${countryCode}] %clr(${LOG_LEVEL_PATTERN:-%5p}) %clr(${PID:- }){magenta} %clr(---){faint} %clr([%15.15t]){faint} %clr(%-40.40logger{39}){cyan}[%line] %clr(:){faint} %m%n${LOG_EXCEPTION_CONVERSION_WORD:-%wEx}" />

	<appender name="consoleAppender" class="ch.qos.logback.core.ConsoleAppender">
		<encoder>
			<pattern>${console-pattern}</pattern>
			<charset>utf8</charset>
		</encoder>
	</appender>

	<appender name="rolling" class="ch.qos.logback.core.rolling.RollingFileAppender">
		<file>${log-directory}/${instance}.log</file>
		<rollingPolicy class="ch.qos.logback.core.rolling.SizeAndTimeBasedRollingPolicy">
			<fileNamePattern>${log-directory}/${instance}.log-%d{yyyy-MM-dd}.%i</fileNamePattern>
			<!-- each file should be at most 250MB, keep 60 days worth of history,
				but at most 20GB -->
			<maxFileSize>${max-file-size}</maxFileSize>
			<maxHistory>${max-history}</maxHistory>
			<totalSizeCap>${total-size-cap}</totalSizeCap>
		</rollingPolicy>
		<encoder>
			<pattern>${log-pattern} </pattern>
			<charset>utf8</charset>
		</encoder>
	</appender>

	<!-- logstash: https://github.com/spring-cloud-samples/sleuth-documentation-apps/blob/master/service1/src/main/resources/logback-spring.xml -->

	<logger name="com.netflix.loadbalancer" level="debug" additivity="false">
		<appender-ref ref="consoleAppender" />
		<appender-ref ref="rolling" />
	</logger>
	<!-- 指定 -->
	<logger name="com.ethan" level="debug" additivity="false">
		<appender-ref ref="consoleAppender" />
		<appender-ref ref="rolling" />
	</logger>

	<root>
		<level value="info" />
		<appender-ref ref="consoleAppender" />
		<appender-ref ref="rolling" />
	</root>
</configuration>
```

## 2. AsyncAppender, Asynchronous logging

```xml
<!-- 异步输出 -->  
<appender name ="ASYNC" class= "ch.qos.logback.classic.AsyncAppender">  
	<!-- 不丢失日志.默认的,如果队列的80%已满,则会丢弃TRACT、DEBUG、INFO级别的日志 -->  
	<discardingThreshold>0</discardingThreshold>  
	<!-- 更改默认的队列的深度,该值会影响性能.默认值为256 -->  
	<queueSize>256</queueSize>  
	<!-- 添加附加的appender,最多只能添加一个 -->  
	<appender-ref ref ="rolling"/>  
</appender>
```

## 3. A standalone log class,Point to the specified address
1. create a customer class
```java
public class AuditLogger {
    public static final Logger LOGGER = Logger.getLogger(AuditLogger.class);

    private AuditLogger(){}
}

```
2. setting the logger class
```xml
<appender name="AUDITLOG" class="ch.qos.logback.core.rolling.RollingFileAppender">
	<rollingPolicy class="ch.qos.logback.core.rolling.TimeBasedRollingPolicy">
		<fileNamePattern>${auditlogfolder}${instance}.log</fileNamePattern>
	</rollingPolicy>
	<encoder>
		<Pattern> ${logpattern}</Pattern>
		<charset>utf8</charset>
	</encoder>
</appender>
<logger name="com.aaa.bbb.AuditLogger" level="info" additivity="false">
	<appender-ref ref="consoleAppender" /> <!--append console depends on you-->
	<appender-ref ref="AUDITLOG" />
</logger>

```
3. useage
```java
public class BaseClazz {
	protected final Logger log = AuditLogger.LOGGER;

	public void logger(){
		log.info("{}", "123");
	}
}
```

## 4. Filter
It means to filter again under the current log level

- LevelFilter

	I see that although `<logger>` is configured with `DEBUG`, the output is only `warn` because `ACCEPT` was done when `WARN` level was matched in `<filter>`, but not matched. WARN level did `DENY`, of course, can only print out the log of `WARN` level
	
	```xml
	<configuration scan="false" scanPeriod="60000" debug="false">

			<appender name="STDOUT" class="ch.qos.logback.core.ConsoleAppender">
					<encoder>
							<pattern>%d{yyyy-MM-dd HH:mm:ss.SSS} [%thread] %-5level %logger - %msg%n</pattern>
					</encoder>
					<filter class="ch.qos.logback.classic.filter.LevelFilter">
							<level>WARN</level>
							<onMatch>ACCEPT</onMatch>
							<onMismatch>DENY</onMismatch>
					</filter>
			</appender>

			<logger name="java" additivity="false" />
			<logger name="java.lang" level="DEBUG">
					<appender-ref ref="STDOUT" />
			</logger>

			<root level="INFO">
					<appender-ref ref="STDOUT" />
			</root>

	</configuration>
	```

- ThresholdFilter

	Filter all log levels less than `<level>`, so although the DEBUG level is specified, only INFO and above can be printed
	```xml
	<?xml version="1.0" encoding="UTF-8" ?>
	<configuration scan="false" scanPeriod="60000" debug="false">

			<appender name="STDOUT" class="ch.qos.logback.core.ConsoleAppender">
					<encoder>
							<pattern>%d{yyyy-MM-dd HH:mm:ss.SSS} [%thread] %-5level %logger - %msg%n</pattern>
					</encoder>
					<filter class="ch.qos.logback.classic.filter.ThresholdFilter">
							<level>INFO</level>
					</filter>
			</appender>

			<logger name="java" additivity="false" />
			<logger name="java.lang" level="DEBUG">
					<appender-ref ref="STDOUT" />
			</logger>

			<root level="INFO">
					<appender-ref ref="STDOUT" />
			</root>

	</configuration>
	```