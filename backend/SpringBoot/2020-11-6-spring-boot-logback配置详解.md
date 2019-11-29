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