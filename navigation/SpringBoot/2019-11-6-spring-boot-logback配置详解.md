//TODO

```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
	<include resource="org/springframework/boot/logging/logback/defaults.xml"/>
	<springProperty scope="context" name="countryCode" source="countryCode" defaultValue="CN" />
	<springProfile name="dev">
		<springProperty scope="context" name="logfolder" source="logging.dir" defaultValue="/logs/" />
		<springProperty scope="context" name="instance" source="logging.instance" defaultValue="xxx" />
	</springProfile>
	<springProfile name="!dev">
		<springProperty scope="context" name="logfolder" source="logging.dir" defaultValue="/logs/" />
		<springProperty scope="context" name="instance" source="logging.instance" defaultValue="xxx" />
	</springProfile>

	<property scope="context" name="maxfilesize" value="5MB" />
	<property scope="context" name="maxhistory" value="20" />
	<property scope="context" name="totalsizecap" value="5GB" />

	<property scope="context" name="logpattern" value="%d{yyyy-MM-dd HH:mm:ss.SSS} [${countryCode}] ${LOG_LEVEL_PATTERN:-%5p} ${PID:- } --- [%15.15t] %-40.40logger{39}[%line] : %m%n" />
	<property scope="context" name="colorconsole" value="%clr(%d{yyyy-MM-dd HH:mm:ss.SSS}){faint} [${countryCode}] %clr(${LOG_LEVEL_PATTERN:-%5p}) %clr(${PID:- }){magenta} %clr(---){faint} %clr([%15.15t]){faint} %clr(%-40.40logger{39}){cyan}[%line] %clr(:){faint} %m%n${LOG_EXCEPTION_CONVERSION_WORD:-%wEx}" />

	<appender name="CONSOLEAPPENDER"
			  class="ch.qos.logback.core.ConsoleAppender">
		<encoder>
			<Pattern> ${colorconsole}</Pattern>
		</encoder>
	</appender>

	<appender name="ROLLING"
			  class="ch.qos.logback.core.rolling.RollingFileAppender">
		<file>${logfolder}${instance}.log</file>
		<rollingPolicy
				class="ch.qos.logback.core.rolling.SizeAndTimeBasedRollingPolicy">
			<fileNamePattern>${logfolder}${instance}.log-%d{yyyy-MM-dd}.%i.gz</fileNamePattern>
			<maxFileSize>${maxfilesize}</maxFileSize>
			<maxHistory>${maxhistory}</maxHistory>
			<totalSizeCap>${totalsizecap}</totalSizeCap>
		</rollingPolicy>
		<encoder class="ch.qos.logback.core.encoder.LayoutWrappingEncoder">
			<layout class="com.uob.geb.ng.logger.utils.GEBNGMaskingPatternLayout">
				<Pattern> ${logpattern} </Pattern>
			</layout>
		</encoder>
	</appender>

	<root>
		<level value="INFO" />
		<appender-ref ref="CONSOLEAPPENDER" />
		<appender-ref ref="ROLLING" />
	</root>
</configuration>
```