## Caffeine是使用Java8对Guava缓存的重写版本，在Spring Boot 2.0中将取代Guava。如果出现Caffeine，CaffeineCacheManager将会自动配置。

# 1. 引入依赖
```maven
<!-- open cache -->
<dependency>
    <groupId>com.github.ben-manes.caffeine</groupId>
    <artifactId>caffeine</artifactId>
</dependency>
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-cache</artifactId>
</dependency>
<!-- open cache -->
```

## 2. 开启缓存支持
使用@EnableCaching注解让Spring Boot开启对缓存的支持
```java
@SpringBootApplication
@EnableCaching// 开启缓存，需要显示的指定
public class SpringBootStudentCacheCaffeineApplication {

    public static void main(String[] args) {
        SpringApplication.run(SpringBootStudentCacheCaffeineApplication.class, args);
    }
}
``` 

## 3. 使用动态配置
```yaml
caffeine:
  configs:
    -
      cacheName: p-list-cache
      initialCapacity: 50
      maximumSize: 500
      expireAfterWriteMins: 90
    -
      cacheName: l-list-cache
      initialCapacity: 50
      maximumSize: 500
      expireAfterWriteMins: 90
    -
      cacheName: long-term-cache
      initialCapacity: 5
      maximumSize: 50
      expireAfterWriteMins: 300
```
```java
@Data
@Component
@ConfigurationProperties("caffeine")
public class CachePropertiesBean {
    {
        configs = Arrays.asList(new CacheConfig("default-cache", 10, 50L, 30L));
    }
    private List<CacheConfig> configs;

    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class CacheConfig{
        private String cacheName;
        private Integer initialCapacity;
        private Long maximumSize;
        private Long expireAfterWriteMins;
    }
}
// listener
@Component
public class PrimaryCacheRemovaListener implements RemovalListener<Object, Object> {
    @Override
    public void onRemoval(Object o, Object o2, RemovalCause removalCause) {
        log.info("PrimaryCacheRemovaListener:{}:{}", o , removalCause);
    }
}
// spring manager
@Bean
public CacheManager cacheManager() {
    final List<CaffeineCache> caches = cachePropertiesBean.getConfigs().stream().map(bean -> {
        Cache<Object, Object> cache = Caffeine.newBuilder()
                .initialCapacity(bean.getInitialCapacity())
                .maximumSize(bean.getMaximumSize())
                .expireAfterWrite(bean.getExpireAfterWriteMins(), TimeUnit.MINUTES)
                // .weakValues() 
                .removalListener(primaryListener)
                .recordStats()
                .build();
        return new CaffeineCache(bean.getCacheName(), cache);
    }).collect(Collectors.toList());

    SimpleCacheManager manager = new SimpleCacheManager();
    manager.setCaches(caches);
    return manager;
}
```
## 4. Caffeine配置说明：

- initialCapacity=[integer]: 初始的缓存空间大小
- maximumSize=[long]: 缓存的最大条数
- maximumWeight=[long]: 缓存的最大权重
- expireAfterAccess=[duration]: 最后一次写入或访问后经过固定时间过期
- expireAfterWrite=[duration]: 最后一次写入后经过固定时间过期
- refreshAfterWrite=[duration]: 创建缓存或者最近一次更新缓存后经过固定的时间间隔，刷新缓存
- weakKeys: 打开key的弱引用，使用 == match值，开启之后会被GC回收而不是等待expire
- weakValues：打开value的弱引用，开启之后会被GC回收而不是等待expire
- softValues：打开value的软引用
- recordStats：开发统计功能 [API](https://github.com/ben-manes/caffeine/wiki/Statistics) 
#### 注意：
- expireAfterWrite和expireAfterAccess同事存在时，以expireAfterWrite为准。
- maximumSize和maximumWeight不可以同时使用
- weakValues和softValues不可以同时使用

## 5. 示例
```java
@CacheConfig(cacheNames = {CacheNameSpace.PERMISSION_LIST_CACHE})
@Service
class xxx {}

@Override
@CachePut(value = "people", key = "#person.id")
public Person save(Person person) {
    Person p = personRepository.save(person);
    logger.info("为id、key为:" + p.getId() + "数据做了缓存");
    return p;
}

@Override
@CacheEvict(value = "people")//2
public void remove(Long id) {
    logger.info("删除了id、key为" + id + "的数据缓存");
    //这里不做实际删除操作
}

/**
* Cacheable
* value：缓存的名称，在 spring 配置文件中定义，必须指定至少一个 相当于 cacheNames
* key：缓存key的后缀。
* sync：设置如果缓存过期是不是只放一个请求去请求数据库，其他请求阻塞，默认是false。
*/
@Override
@Cacheable(value = "people", key = "#person.id", sync = true)
public Person findOne(Person person, String a, String[] b, List<Long> c) {
    Person p = personRepository.findOne(person.getId());
    logger.info("为id、key为:" + p.getId() + "数据做了缓存");
    return p;
}

@Override
@Cacheable(value = "people1")//3
public Person findOne1() {
    Person p = personRepository.findOne(2L);
    logger.info("为id、key为:" + p.getId() + "数据做了缓存");
    return p;
}

@Override
@Cacheable(value = "people2")//3
public Person findOne2(Person person) {
    Person p = personRepository.findOne(person.getId());
    logger.info("为id、key为:" + p.getId() + "数据做了缓存");
    return p;
}

```

## 6. SpEL上下文数据
Spring Cache提供了一些供我们使用的SpEL上下文数据，下表直接摘自Spring官方文档：

|名称|位置|描述|示例|
|:-|:-:|:-:|-:|
|methodName|root对象|当前被调用的方法名|root.methodName|
|method|root对象|当前被调用的方法|root.method.name
|target|root对象|当前被调用的目标对象|root.target
|targetClass|root对象|当前被调用的目标对象类|root.targetClass
|args|root对象|当前被调用的方法的参数列表|root.args[0]
|caches|root对象|当前方法调用使用的缓存列表（如@Cacheable(value={“cache1”, “cache2”})），则有两个cache|root.caches[0].name
|argument name|执行上下文|当前被调用的方法的参数，如findById(Long id)，我们可以通过#id拿到参数|user.id
|result|执行上下文|方法执行后的返回值（仅当方法执行之后的判断有效，如‘unless’，’cache evict’的beforeInvocation=false）|result

如果忘记了SpEL怎么用了， 请查看：[Chapter 9, Spring Expression Language (SpEL)](https://docs.spring.io/spring/docs/4.2.x/spring-framework-reference/html/expressions.html)