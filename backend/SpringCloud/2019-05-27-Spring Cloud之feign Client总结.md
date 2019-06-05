# SpringCloud中使用Ribbon和Feign调用服务以及服务的高可用(Feign篇)
**Feign**是一个声明式的**Web Service**客户端，它使得编写Web Serivce客户端变得更加简单。我们只需要使用Feign来创建一个接口并用注解来配置它既可完成。

在实际开发中，feign使用的还是挺多的，feign底层还是使用了ribbon。废话不多说，直接上步骤，在服务消费者中使用feign访问服务提供者。

1. 引入maven配置
```
    // 在上文中已经引入了hystrix了，所以这边省略
    <dependency>
        <groupId>org.springframework.cloud</groupId>
        <artifactId>spring-cloud-starter-openfeign</artifactId>
    </dependency>
    <dependency>
        <groupId>io.github.openfeign</groupId>
        <artifactId>feign-httpclient</artifactId>
    </dependency>
```
2. 配置yaml
```yaml
feign:
  hystrix:
    enabled: true
  httpclient:
    enabled: true
    connectTimeout: 30000
    socketTimeout: 10000
    connectionRequestTimeout: 500
    defaultMaxPerRoute: 20
    maxTotal: 200

hystrix:
  command:
    default:
      execution:
        isolation:
          thread:
            timeoutInMilliseconds: 360000

# spring cloud load balance config !!
ribbon-cluster:
  ribbon:
    protocol: https
    eureka: false
    OkToRetryOnAllOperations: true
    MaxAutoRetries: 1
    MaxAutoRetriesNextServer: 1
    listOfServers: localhost:8004
    ServerListRefreshInterval: 15000
    ConnectTimeout: 10000
    ReadTimeout: 30000
```
>  feign的默认请求超时时间是1s，所以经常会出现超时的问题，这里我设置的是10s。ribbon的请求时间也要设置，因为feign用的是ribbon。

3. 编码
```java
@EnableFeignClients
@EnableSwagger2
@EnableHystrix
public class Application {
    ... ...
}
```
### 1. 编写`Feign`接口
- name是指要请求的服务名称。这里请求的是服务提供者
- fallback 是指请求失败，进入断路器的类，和使用ribbon是一样的。
- configuration 是feign的一些配置，例如编码器等。
```java
@FeignClient(name = "${ribbon-cluster.ribbon.protocol:http}://ribbon-cluster", fallbackFactory = HystrixFeignFallback.class)
public interface FeignClient {
    @PostMapping(value = "/user/list")
    List<User> getUsers();
}

// 此处 @Component需要被实力化，否则fallbackFactory无法获取
@Component
public class HystrixFeignFallback implements FallbackFactory<FeignClient> {
    @Override
    public TransactionsClient create(Throwable throwable) {
        return new FeignClient() {
            return () ->
                new ArrayList<>()
        };
    }
}
```
### 2. 引入自定义ribbon配置
```java
@RibbonClients(defaultConfiguration = FailoverRule.class)
public class LoadBalanceConfig {

}
```
### 3. 配置了feign的打印日志等级
由于feign在转发Http请求时，不会带上HttpHeaders,需要额外注入配置，将HttpHeaders注入，我们可以实现`implements RequestInterceptor` 来将HttpHeaders注入。  
这样，Feign使用这个拦截器时，就会用你这个Header去请求了。
```java
@Slf4j
@Configuration
public class RouterClientConfig implements RequestInterceptor {
    @Bean
    public Logger.Level feignLoggerLevel() {
        return Logger.Level.FULL;
    }

    @Override
    public void apply(RequestTemplate requestTemplate) {
        ServletRequestAttributes attributes = (ServletRequestAttributes) RequestContextHolder
                .getRequestAttributes();
        if (attributes != null) {
            HttpServletRequest request = attributes.getRequest();
            Enumeration<String> headerNames = request.getHeaderNames();
            if (headerNames != null) {
                while (headerNames.hasMoreElements()) {
                    String name = headerNames.nextElement();
                    String values = request.getHeader(name);
                    requestTemplate.header(name, values);
                }
                // log.info("computing interceptor header:{}",requestTemplate);
            }
        }
    }
}
```

### 4. 现实很骨感
以上代码可完美运行——但仅限于Feign不开启Hystrix支持时。
> 注：Spring Cloud Dalston以及更高版可使用 feign.hystrix.enabled=true 为Feign开启Hystrix支持。

Hystrix默认当隔离策略为 THREAD 时，是没办法拿到 ThreadLocal 中的值的。

当Feign开启Hystrix支持时，ServletRequestAttributes attributes = (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
是 null 。

原因在于，Hystrix的默认隔离策略是THREAD 。而 RequestContextHolder 源码中，使用了两个血淋淋的ThreadLocal 。

#### 解决方案一：调整隔离策略
将隔离策略设为`SEMAPHORE`即可：

    hystrix.command.default.execution.isolation.strategy: SEMAPHORE
这样配置后，`Feign`可以正常工作。

但该方案不是特别好。原因是Hystrix官方强烈建议使用THREAD作为隔离策略！ 参考文档：

> Thread or Semaphore
> The default, and the recommended setting, is to run HystrixCommands using thread isolation (THREAD) and HystrixObservableCommands using semaphore isolation (SEMAPHORE).
> 
> Commands executed in threads have an extra layer of protection against latencies beyond what network timeouts can offer.
> 
> Generally the only time you should use semaphore isolation for HystrixCommands is when the call is so high volume (hundreds per second, per instance) that the overhead of separate threads is too high; this typically only applies to non-network calls.

于是，那么有没有更好的方案呢？
#### 解决方案二：自定义并发策略
既然Hystrix不太建议使用SEMAPHORE作为隔离策略，那么是否有其他方案呢？答案是自定义并发策略，目前，Spring Cloud Sleuth以及Spring Security都通过该方式传递 ThreadLocal 对象。

下面我们来编写自定义的并发策略。

编写自定义并发策略
编写自定义并发策略比较简单，只需编写一个类，让其继承HystrixConcurrencyStrategy ，并重写wrapCallable 方法即可。
```java
@Slf4j
@Component
public class RouterAttributeHystrixConcurrencyStrategy extends HystrixConcurrencyStrategy {
    private HystrixConcurrencyStrategy delegate;

    public RouterAttributeHystrixConcurrencyStrategy() {
        try {
            this.delegate = HystrixPlugins.getInstance().getConcurrencyStrategy();
            if (this.delegate instanceof RouterAttributeHystrixConcurrencyStrategy) {
                return;
            }
            HystrixCommandExecutionHook commandExecutionHook =
                    HystrixPlugins.getInstance().getCommandExecutionHook();
            HystrixEventNotifier eventNotifier = HystrixPlugins.getInstance().getEventNotifier();
            HystrixMetricsPublisher metricsPublisher = HystrixPlugins.getInstance().getMetricsPublisher();
            HystrixPropertiesStrategy propertiesStrategy =
                    HystrixPlugins.getInstance().getPropertiesStrategy();
            this.logCurrentStateOfHystrixPlugins(eventNotifier, metricsPublisher, propertiesStrategy);
            HystrixPlugins.reset();
            HystrixPlugins.getInstance().registerConcurrencyStrategy(this);
            HystrixPlugins.getInstance().registerCommandExecutionHook(commandExecutionHook);
            HystrixPlugins.getInstance().registerEventNotifier(eventNotifier);
            HystrixPlugins.getInstance().registerMetricsPublisher(metricsPublisher);
            HystrixPlugins.getInstance().registerPropertiesStrategy(propertiesStrategy);
        } catch (Exception e) {
            log.error("Failed to register Sleuth Hystrix Concurrency Strategy", e);
        }
    }

    private void logCurrentStateOfHystrixPlugins(HystrixEventNotifier eventNotifier,
                                                 HystrixMetricsPublisher metricsPublisher, HystrixPropertiesStrategy propertiesStrategy) {
        if (log.isDebugEnabled()) {
            log.debug("Current Hystrix plugins configuration is [" + "concurrencyStrategy ["
                    + this.delegate + "]," + "eventNotifier [" + eventNotifier + "]," + "metricPublisher ["
                    + metricsPublisher + "]," + "propertiesStrategy [" + propertiesStrategy + "]," + "]");
            log.debug("Registering Sleuth Hystrix Concurrency Strategy.");
        }
    }


    @Override
    public ThreadPoolExecutor getThreadPool(HystrixThreadPoolKey threadPoolKey, HystrixProperty<Integer> corePoolSize, HystrixProperty<Integer> maximumPoolSize, HystrixProperty<Integer> keepAliveTime, TimeUnit unit, BlockingQueue<Runnable> workQueue) {
        return this.delegate.getThreadPool(threadPoolKey, corePoolSize, maximumPoolSize, keepAliveTime,
                unit, workQueue);
    }

    @Override
    public ThreadPoolExecutor getThreadPool(HystrixThreadPoolKey threadPoolKey, HystrixThreadPoolProperties threadPoolProperties) {
        return this.delegate.getThreadPool(threadPoolKey, threadPoolProperties);
    }

    @Override
    public BlockingQueue<Runnable> getBlockingQueue(int maxQueueSize) {
        return this.delegate.getBlockingQueue(maxQueueSize);
    }

    @Override
    public <T> Callable<T> wrapCallable(Callable<T> callable) {
        RequestAttributes requestAttributes = RequestContextHolder.getRequestAttributes();
        return new WrappedCallable<>(callable, requestAttributes);
    }

    @Override
    public <T> HystrixRequestVariable<T> getRequestVariable(HystrixRequestVariableLifecycle<T> rv) {
        return this.delegate.getRequestVariable(rv);
    }

    static class WrappedCallable<T> implements Callable<T> {
        private final Callable<T> target;
        private final RequestAttributes requestAttributes;

        public WrappedCallable(Callable<T> target, RequestAttributes requestAttributes) {
            this.target = target;
            this.requestAttributes = requestAttributes;
        }
        @Override
        public T call() throws Exception {
            try {
                RequestContextHolder.setRequestAttributes(requestAttributes);
                return target.call();
            } finally {
                RequestContextHolder.resetRequestAttributes();
            }
        }
    }
}
```
如代码所示，我们编写了一个`RouterAttributeHystrixConcurrencyStrategy` ，在其中：

- `wrapCallable` 方法拿到 `RequestContextHolder.getRequestAttributes()` ，也就是我们想传播的对象
- 在 `WrappedCallable` 类中，我们将要传播的对象作为成员变量，并在其中的`call`方法中，为静态方法设值。
- 这样，在Hystrix包裹的方法中，就可以使用`RequestContextHolder.getRequestAttributes()` 获取到相关属性——也就是说，可以拿到`RequestContextHolder` 中的`ThreadLocal` 属性。
经过测试，代码能正常工作。
- 将现有的并发策略作为新并发策略的成员变量
- 在新并发策略中，返回现有并发策略的线程池、Queue。

我们知道，`Spring Cloud`中，`Spring Cloud Security`与`Spring Cloud Sleuth`是可以共存的！我们不妨参考下Sleuth以及Spring Security的实现：

- `Sleuth`：org.springframework.cloud.sleuth.instrument.hystrix.SleuthHystrixConcurrencyStrategy
- `Spring Security`：org.springframework.cloud.netflix.hystrix.security.SecurityContextConcurrencyStrategy

### 5. 新的问题
默认情况下，feign通过jdk中的`HttpURLConnection`向下游服务发起http请求，这种情况下，由于缺乏连接池的支持，在达到一定流量的后服务肯定会出问题。因此我们需要使用更加完备的方案。下面我们以HttpClient作为事例，来看一下怎样改变feign的底层http方案
- pom文件增加feign-httpclient的依赖（请注意与feign-core的版本保持一致）
```yaml
<dependency>
    <groupId>io.github.openfeign</groupId>
    <artifactId>feign-httpclient</artifactId>
    <version>9.4.0</version>
</dependency>
```
- application.yml配置激活
```yaml
feign:
  hystrix:
    enabled: true
  httpclient:
    enabled: true
    connectTimeout: 30000
    socketTimeout: 10000
    connectionRequestTimeout: 500
    defaultMaxPerRoute: 20
    maxTotal: 200
```
- 添加HttpClient配置（spring bean），请根据实际情况配置相关参数（例如最大连接数、超时时间等）
```java

/**
*@see org.springframework.cloud.openfeign.FeignAutoConfiguration.HttpClientFeignConfiguration
*/
@Import(FeignAutoConfiguration.class)
@Configuration
@Slf4j
public class HttpClientConfiguration extends SslClientComponentAbstract {

    @Bean
    @Order(1)
    public FilterRegistrationBean inputStreamWrapperFilterRegistration() {
        FilterRegistrationBean registrationBean = new FilterRegistrationBean();
        registrationBean.setFilter(new InputStreamWrapperFilter());
        registrationBean.setName("inputStreamWrapperFilter");
        registrationBean.addUrlPatterns("/*");

        return registrationBean;
    }

    @Bean
    public CloseableHttpClient httpClient(HttpPoolConfig httpPoolConfig) {
        if (SSLParamsConfig.isEnabled()) {
            String trustStorePath = "/custom_test.jks";
            String storePath = "/custom_test_trust.jks";

            try (FileInputStream trustFileStream = new FileInputStream(trustStorePath);
                    FileInputStream serverFileStream = new FileInputStream(storePath)) {
                String pwd = "password";
                KeyStore clientStore = KeyStore.getInstance(KeyStore.getDefaultType());
                clientStore.load(trustFileStream, pwd.toCharArray());

                String storePwd = "password";
                KeyStore serverStore = KeyStore.getInstance(KeyStore.getDefaultType());
                serverStore.load(serverFileStream, storePwd.toCharArray());
                // set server and client auth
                return httpClient(clientStore, serverStore, storePwd, httpPoolConfig);
            } catch (Exception e) {
                log.error("init SSL restTemplate Failure", e);
            }
        }

        PoolingHttpClientConnectionManager connManager = new PoolingHttpClientConnectionManager();
        connManager.setMaxTotal(httpPoolConfig.getMaxTotal());
        connManager.setDefaultMaxPerRoute(httpPoolConfig.getDefaultMaxPerRoute());
        return HttpClients.custom()
                .setConnectionManager(connManager)
                .setKeepAliveStrategy(connectionKeepAliveStrategy())
                .setDefaultRequestConfig(requestConfig(httpPoolConfig))
                .build();
    }
}
```

### 6. 异常处理

但在实际过程中, `@ControllerAdvice`中，我们会发现通过request.getInputStream()方式获取的数据为空。

> 根据Servlet规范，如果同时满足下列条件，则请求体(Entity)中的表单数据，将被填充到request的parameter集合中（request.getParameter系列方法可以读取相关数据）

- 这是一个HTTP/HTTPS请求
- 请求方法是POST（querystring无论是否POST都将被设置到parameter中）
- 请求的类型（Content-Type头）是application/x-www-form-urlencoded
- Servlet调用了getParameter系列方法

这里的表单数据已经被填充到parameterMap中，不能再通过getInputStream获取。
如何解决这个问题呢。

在javax.servlet.http包下面有一个装饰器类HttpServletRequestWrapper，利用这个装饰器类，我们可以重新包装一个HttpServletRequest对象。
```java
public class HttpServletRequestWrapper extends ServletRequestWrapper implements HttpServletRequest {
    ...
}
```
定义一个装饰器继承`HttpServletRequestWrapper,streamBody`字节变量用来保存读取的数据，以便于多次读取。
```java
public class InputStreamHttpServletRequestWrapper extends HttpServletRequestWrapper{


    private final byte[] streamBody;
    private static final int BUFFER_SIZE = 4096;

   
    public InputStreamHttpServletRequestWrapper(HttpServletRequest request) throws IOException {
        super(request);
        byte[] bytes = inputStream2Byte(request.getInputStream());
        if (bytes.length == 0 && RequestMethod.POST.name().equals(request.getMethod())) {
            //从ParameterMap获取参数，并保存以便多次获取
            bytes = request.getParameterMap().entrySet().stream()
                    .map(entry -> {
                        String result;
                        String[] value = entry.getValue();
                        if (value != null && value.length > 1) {
                            result = Arrays.stream(value).map(s -> entry.getKey() + "=" + s)
                                    .collect(Collectors.joining("&"));
                        } else {
                            result = entry.getKey() + "=" + value[0];
                        }

                        return result;
                    }).collect(Collectors.joining("&")).getBytes();
        }

        streamBody = bytes;
    }

    private byte[] inputStream2Byte(InputStream inputStream) throws IOException {
        ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
        byte[] bytes = new byte[BUFFER_SIZE];
        int length;
        while ((length = inputStream.read(bytes, 0, BUFFER_SIZE)) != -1) {
            outputStream.write(bytes, 0, length);
        }

        return outputStream.toByteArray();
    }


    @Override
    public ServletInputStream getInputStream() throws IOException {
        ByteArrayInputStream inputStream = new ByteArrayInputStream(streamBody);

        return new ServletInputStream() {
            @Override
            public boolean isFinished() {
                return false;
            }

            @Override
            public boolean isReady() {
                return false;
            }

            @Override
            public void setReadListener(ReadListener listener) {

            }

            @Override
            public int read() throws IOException {
                return inputStream.read();
            }
        };
    }

    @Override
    public BufferedReader getReader() throws IOException {
        return new BufferedReader(new InputStreamReader(getInputStream()));
    }
}
```

声明一个带有HttpServletRequest入参的构造器，从该参数对象的流中解析数据，如果没有则继续从parameterMap中获取，然后以key=value&key=value形式拼接。用streamBody接收。然后我们重写getInputStream方法，以后每次调用getInputStream方法，其实是重新利用streamBody重新new一个流，所以可以多次读取。  
有了装饰器后，我们就要装饰目标对象。我们都知道SpringMVC的一次请求会被一个个过滤器层层调用，也就是我们常说的责任链模式。利用`Filter`我们就可以在某个特定的位置装饰HttpServletRequest对象。
```java
public class InputStreamWrapperFilter extends OncePerRequestFilter{
    @Override
    protected void doFilterInternal(HttpServletRequest httpServletRequest, HttpServletResponse httpServletResponse, FilterChain filterChain) throws ServletException, IOException {
        ServletRequest servletRequest = new InputStreamHttpServletRequestWrapper(httpServletRequest);

        filterChain.doFilter(servletRequest, httpServletResponse);
    }
}
```
`OncePerRequestFilter`这个过滤器能够保证一次请求只经过一次过滤器，所以我们直接继承该类就行了。
```java
@Bean
@Order(1)
public FilterRegistrationBean inputStreamWrapperFilterRegistration() {
    FilterRegistrationBean registrationBean = new FilterRegistrationBean();
    registrationBean.setFilter(new InputStreamWrapperFilter());
    registrationBean.setName("inputStreamWrapperFilter");
    registrationBean.addUrlPatterns("/*");

    return registrationBean;
}
```
然后注册该过滤器，设置优先级为1。Spring Boot 会按照order值的大小，从小到大的顺序来依次过滤。

参考[SpringCloud Feign的分析](https://zhuanlan.zhihu.com/p/45495904)