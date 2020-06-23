# SpringCloud中使用Ribbon和Feign调用服务以及服务的高可用(Ribbon篇)
在微服务架构中，业务会被拆分成一个个彼此独立的服务，服务间的通讯基于http restful。

Spring Cloud有两种服务间调用的方式，**Ribbon**和**Feign**。下面我们简单介绍下Ribbon。
### 1.Ribbon简介
Spring Cloud Ribbon 是一个基于HTTP和TCP的客户端负载均衡工具，它基于Netflix Ribbon实现。通过Spring Cloud的封装，可以让我们轻松地将面向服务的REST模版请求自动转换成客户端负载均衡的服务调用。Spring Cloud Ribbon虽然只是一个工具类框架，但它不像服务注册中心、配置中心、API网关那样需要独立部署。它几乎存在于每一个Spring Cloud构建的微服务和基础设施中。微服务间的调用、API网关的请求转发等内容，实际上都是通过Ribbon来实现的。包括Spring Cloud的另一种服务调用方式Feign，也是基于Ribbon实现的。
### 2. Ribbon负载均衡策略
Ribbon的核心组件是IRule，IRule是所有负载均衡策略的父接口，其子类有：
- **RandomRule**：随机选取负载均衡策略，随机Random对象，在所有服务实例中随机找一个服务的索引号，然后从上线的服务中获取对应的服务。
- **RoundRobinRule**：线性轮询负载均衡策略。即循环一次调用。
- **WeightedResponseTimeRule**：响应时间作为选取权重的负载均衡策略，根据平均响应时间计算所有服务的权重，响应时间越短的服务权重越大，被选中的概率越高。刚启动时，如果统计信息不足，则使用线性轮询策略，等信息足够时，再切换到WeightedResponseTimeRule。
- **RetryRule**：使用线性轮询策略获取服务，如果获取失败则在指定时间内重试，重新获取可用服务。
- **ClientConfigEnabledRoundRobinRule**：默认通过线性轮询策略选取服务。通过继承该类，并且对choose方法进行重写，可以实现更多的策略，继承后保底使用RoundRobinRule策略。
- **BestAvailableRule**：继承自ClientConfigEnabledRoundRobinRule。从所有没有断开的服务中，选取到目前为止请求数量最小的服务。
- **PredicateBasedRule**：抽象类，提供一个choose方法的模板，通过调用AbstractServerPredicate实现类的过滤方法来过滤出目标的服务，再通过轮询方法选出一个服务。
- **AvailabilityFilteringRule**：按可用性进行过滤服务的负载均衡策略，会先过滤掉由于多次访问故障而处于断路器跳闸状态的服务，还有并发的连接数超过阈值的服务，然后对剩余的服务列表进行线性轮询。
- **ZoneAvoidanceRule**：本身没有重写choose方法，用的还是抽象父类PredicateBasedRule的choose。

### 3. Ribbin实践

1. 一般在使用SpringCloud的时候**不需要自己手动创建HttpClient**来进行远程调用.
可以使用Spring封装好的RestTemplate工具类. 其封装了GET,POST,PUT,PATCH,DELETE等方法，实现方式可以自行查看源码。
    - 一般使用方式是GET,POST,PUT,PATCH,DELETE等方法  
        ```java
        @Autowired
        private RestTemplate restTemplate;
        
        restTemplate.postForEntity(url, new HttpEntity<>(baseRequest, httpHeaders), responseType)
        ```
    - 当项目足够大的时候，可能需要使用泛型类替代
        ```java
        @Autowired
        private RestTemplate restTemplate;

        ParameterizedTypeReference typeRef = new ParameterizedTypeReference<GenericResponse>() {};
        restTemple.exchange(url, HttpMethod.POST, new HttpEntity<>(baseRequest, httpHeaders), typeRef)
      ```
    - 上篇中我们提到了SSL配置，下面我们来对restTemplate进行SSL配置.这里我们使用Apache HttpClient来替换RestTemplate的底层。
        ```java
        @Data
        @Component
        @ConfigurationProperties(prefix = "httpclient")
        public class HttpPoolConfig {
            /**
            * send request time limit milliseconds  请求连接池等待时间
            */
            private Integer connectTimeout = 5000;
            /**
            * fetching data time limit milliseconds 等待请求响应时间
            */
            private Integer socketTimeout = 3000000;
            /**
            * connect thread pool time limit milliseconds 请求超时时间，
            */
            private Integer connectionRequestTimeout = 500;
            /**
            * min thread pool 最小连接数
            */
            private Integer defaultMaxPerRoute = 20;
            /**
            * max thread pool 最大连接数
            */
            private Integer maxTotal = 199;
        }

        private static final int DEFAULT_KEEP_ALIVE_TIME_MILLIS = 20 * 1000;
        // httpclient 连接池配置 线程安全。
        // 默认情况下httpclient对象使用的连接管理类，内部维护一个HttpClientConnection连接池，连接池以HttpRoute为单位保持多个连接以供使用，每次请求会根据HttpRoute优先从池中获取连接，获取不到的情况下在连接数未超过配置时才会创建新连接。
        protected PoolingHttpClientConnectionManager poolingHttpClientConnectionManager(SSLConnectionSocketFactory csf, HttpPoolConfig httpPoolConfig) {
            Registry<ConnectionSocketFactory> registry = RegistryBuilder.<ConnectionSocketFactory>create()
                    .register("https", csf)
                    .register("http", new PlainConnectionSocketFactory())
                    .build();

            PoolingHttpClientConnectionManager  connManager = new PoolingHttpClientConnectionManager(registry);
            connManager.setMaxTotal(httpPoolConfig.getMaxTotal());
            connManager.setDefaultMaxPerRoute(httpPoolConfig.getDefaultMaxPerRoute());
            return connManager;
        }
        // httpclient 请求参数配置
        // 这个类属性很多，所以使用了典型的构建器模式，通过内部类RequestConfig.Builder的build()方法来创建RequestConfig对象。
        // 几个常用的属性：
        //    ConnectTimeout：建立连接的超时时间

        //    ConnectionRequestTimeout：从连接池中获取连接超时时间

        //    SocketTimeout：socket传输超时时间

        //    StaleConnectionCheckEnabled：是否启用检查失效连接，这个属性在4.4版本中被PoolingHttpClientConnectionManager中的#setValidateAfterInactivity(int)替换掉了。
        protected RequestConfig requestConfig(HttpPoolConfig httpPoolConfig) {
            return RequestConfig.custom()
            .setConnectTimeout(httpPoolConfig.getConnectTimeout())
            .setSocketTimeout(httpPoolConfig.getSocketTimeout())
            .setConnectionRequestTimeout(httpPoolConfig.getConnectionRequestTimeout()).build();
        }
        // httpclient KeepAliveStrategy配置
        protected ConnectionKeepAliveStrategy connectionKeepAliveStrategy() {
            return (HttpResponse response, HttpContext context) -> {
                HeaderElementIterator it = new BasicHeaderElementIterator
                        (response.headerIterator(HTTP.CONN_KEEP_ALIVE));
                while (it.hasNext()) {
                    HeaderElement he = it.nextElement();
                    String param = he.getName();
                    String value = he.getValue();
                    if (value != null && param.equalsIgnoreCase("timeout")) {
                        return Long.parseLong(value) * 1000;
                    }
                }
                return DEFAULT_KEEP_ALIVE_TIME_MILLIS;
            };
        }

        protected CloseableHttpClient httpClient(KeyStore clientStore, KeyStore serverStore, String serverStorePwd, HttpPoolConfig httpPoolConfig) throws Exception {
            SSLContext sslContext = org.apache.http.ssl.SSLContexts.custom()
                    // private key
                    .loadKeyMaterial(serverStore, serverStorePwd.toCharArray())
                    // public key
                    .loadTrustMaterial(clientStore, new TrustSelfSignedStrategy())
                    .build();
            // HostnameVerifier strategy
            final HostnameVerifier verifier = (String s, SSLSession sslSession) -> {
                log.info("SSL Verify host:{} <--> peerHost:{}", s , sslSession.getPeerHost());
                return s.equals(sslSession.getPeerHost());
            };
            SSLConnectionSocketFactory csf = new SSLConnectionSocketFactory(sslContext, verifier);
            // HttpClients final config
            CloseableHttpClient httpClient = HttpClients.custom()
                    .setConnectionManager(poolingHttpClientConnectionManager(csf, httpPoolConfig))
                    .setSSLSocketFactory(csf)
                    .setSSLHostnameVerifier(verifier)
                    .setKeepAliveStrategy(connectionKeepAliveStrategy())
                    .setDefaultRequestConfig(requestConfig(httpPoolConfig))
                    .build();
            return httpClient;
        }

        protected RestTemplate generateSslTemplate(HttpPoolConfig httpPoolConfig) {
            String trustStorePath = "/custom_test.jks";
            String storePath = "/custom_test_trust.jks";
            RestTemplate restTemplate = new RestTemplate();
            try (FileInputStream trustFileStream = new FileInputStream(trustStorePath);
                    FileInputStream serverFileStream = new FileInputStream(storePath)) {
                String pwd = "password";
                KeyStore clientStore = KeyStore.getInstance(KeyStore.getDefaultType());
                clientStore.load(trustFileStream, pwd.toCharArray());

                String storePwd = "password";
                KeyStore serverStore = KeyStore.getInstance(KeyStore.getDefaultType());
                serverStore.load(serverFileStream, storePwd.toCharArray());
                // set server and client auth
                CloseableHttpClient httpClient = httpClient(clientStore, serverStore, storePwd, httpPoolConfig);

                HttpComponentsClientHttpRequestFactory requestFactory = new HttpComponentsClientHttpRequestFactory();
                requestFactory.setHttpClient(httpClient);

                restTemplate.setRequestFactory(requestFactory);
            } catch (Exception e) {
                log.error("init SSL restTemplate Failure", e);
            }
            return restTemplate;
        }
            
        ```

2. 使用ribbon需要先引入相应的jar包，hystrix断路器也是推荐配置之一
```yaml
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-netflix-hystrix</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.cloud</groupId>
    <artifactId>spring-cloud-starter-netflix-ribbon</artifactId>
</dependency>
```
2. 配置.yml文件
```yaml
# spring cloud load balance config !!
ribbon-cluster:
  ribbon:
    eureka: false
    OkToRetryOnAllOperations: true
    MaxAutoRetries: 1 # 最大重试次数，理论上MaxAutoRetriesNextServer应该是MaxAutoRetries总数-1
    MaxAutoRetriesNextServer: 1 # 最大重试服务次数
    listOfServers: localhost:8000,localhost:8001 # 可用服务列表
    ServerListRefreshInterval: 15000 # 服务可用监控
    ConnectTimeout: 500 # 连接超时
    ReadTimeout: 8000 # 读取超时设置
```
3. 启用ribbon
##### 自定义负载均衡策略
```java
// 自定义负载均衡策略, 永远只访问第一个server,当第一个出现问题，启用备用server
public class PollRule extends AbstractLoadBalancerRule {
    private LoadBalancerStats loadBalancerStats;
    private AtomicInteger nextServerCyclicCounter;
    private static final boolean AVAILABLE_ONLY_SERVERS = true;
    private static final boolean ALL_SERVERS = false;

    public PollRule() {
        this.nextServerCyclicCounter = new AtomicInteger(0);
    }

    @SuppressWarnings({"RCN_REDUNDANT_NULLCHECK_OF_NULL_VALUE"})
    public Server choose(ILoadBalancer lb, Object key) {
        if (lb == null) {
            return null;
        } else {
            Server server = null;

            while(server == null) {
                if (Thread.interrupted()) {
                    return null;
                }
                List<Server> upList = lb.getReachableServers();
                List<Server> allList = lb.getAllServers();
                int serverCount = allList.size();
                if (serverCount == 0) {
                    return null;
                }
                int index = 0;
                server = upList.get(index);
                ServerStats serverStats = this.loadBalancerStats.getSingleServerStat(server);
                // check the first server is up, if false, choose the next server
                boolean isCircuitBreaker = serverStats.isCircuitBreakerTripped();
                if (isCircuitBreaker && serverCount > 1) {
                    index = this.incrementAndGetModulo(serverCount);
                    server = upList.get(index);
                }
                if (server == null) {
                    Thread.yield();
                } else {
                    if (server.isAlive()) {
                        return server;
                    }
                    server = null;
                    Thread.yield();
                }
            }
            return server;
        }
    }

    @Override
    public void initWithNiwsConfig(IClientConfig iClientConfig) {
    }

    @Override
    public Server choose(Object key) {
        return this.choose(this.getLoadBalancer(), key);
    }

    @Override
    public void setLoadBalancer(ILoadBalancer lb) {
        super.setLoadBalancer(lb);
        if (lb instanceof AbstractLoadBalancer) {
            this.loadBalancerStats = ((AbstractLoadBalancer)lb).getLoadBalancerStats();
        }
    }
    private int incrementAndGetModulo(int modulo) {
        int current;
        int next;
        do {
            current = this.nextServerCyclicCounter.get();
            next = (current + 1) % modulo;
            if (next == 0) {
                next++;
            }
        } while(!this.nextServerCyclicCounter.compareAndSet(current, next));

        return next;
    }
}

@Configuration
public class FailoverRule {
	@Bean
	public IRule myRule() {
		//return new RandomRule();// Ribbon默认是轮询，我自定义为随机
		//return new RoundRobinRule();// Ribbon默认是轮询，我自定义为随机
		return new PollRule();// 自定义故障转移策略
	}
}

@Configuration
@RibbonClient(name = "ribbon-cluster", configuration = FailoverRule.class)
@ConditionalOnProperty(prefix = "ribbon-cluster.ribbon", name = "listOfServers")
@Slf4j
// 根据配置，确认是否启用SSL配置策略
public class CustomRibbonConfiguration extends SslClientAbstract {
    @Bean("LoadBalanceRestTemplate")
    @LoadBalanced
    @ConditionalOnBean(value =HttpPoolConfig.class)
    public RestTemplate restTemplate(HttpPoolConfig httpPoolConfig) {
        return generateSslTemplate(httpPoolConfig);
    }

    @Bean("LoadBalanceRestTemplate")
    @LoadBalanced
    @ConditionalOnMissingBean(value = SSLConfig.class)
    public RestTemplate restTemplate2() {
        return new RestTemplate();
    }
}
```

4. 引出Hystrix  
到目前为止，我们的服务看起来好像挺好的了：能够根据服务名来远程调用其他的服务，可以实现客户端的负载均衡。  
但是，如果我们在调用多个远程服务时，某个服务出现延迟，会怎么样??  
在高并发的情况下，由于单个服务的延迟，可能导致所有的请求都处于延迟状态，甚至在几秒钟就使服务处于负载饱和的状态，资源耗尽，直到不可用，最终导致这个分布式系统都不可用，这就是“雪崩”。  
针对上述问题， `Spring Cloud Hystrix`实现了断路器、线程隔离等一系列服务保护功能。
- Fallback(失败快速返回)：当某个服务单元发生故障（类似用电器发生短路）之后，通过断路器的故障监控（类似熔断保险丝）， 向调用方返回一个错误响应， 而不是长时间的等待。这样就不会使得线程因调用故障服务被长时间占用不释放，避免了故障在分布式系统中的蔓延。
- 资源/依赖隔离(线程池隔离)：它会为每一个依赖服务创建一个独立的线程池，这样就算某个依赖服务出现延迟过高的情况，也只是对该依赖服务的调用产生影响， 而不会拖慢其他的依赖服务。  
参考 [深入理解Hystrix之文档翻译](https://zhuanlan.zhihu.com/p/28523060)

详细配置为
```java
@SpringBootApplication
@EnableCircuitBreaker
public class Application {
    ... ...
}

@HystrixCommand(fallbackMethod = "failureExceptionFallBack", commandKey = "invoke-service")
public GenericResponse getIllegalArgument(@RequestBody GenericRequest request, HttpSession session) {
    Thread.sleep(6000);
    throw new DefaultApiException("Value is null or empty");
}

public GenericResponse failureExceptionFallBack(GenericRequest request, HttpSession session, Throwable e){

}
```

```yaml
hystrix:
  command:
    default:
      execution:
        isolation:
          thread:
            timeoutInMilliseconds: 5000
    invoke-service:
      execution:
        isolation:
          thread:
            timeoutInMilliseconds: 90000
```