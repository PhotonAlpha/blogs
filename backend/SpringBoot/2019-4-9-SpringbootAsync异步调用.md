# @Async 异步调用
何为异步调用
说异步调用前，我们说说它对应的同步调用。通常开发过程中，一般上我们都是同步调用，即：程序按定义的顺序依次执行的过程，每一行代码执行过程必须等待上一行代码执行完毕后才执行。而异步调用指：程序在执行时，无需等待执行的返回值可继续执行后面的代码。显而易见，同步有依赖相关性，而异步没有，所以异步可并发执行，可提高执行效率，在相同的时间做更多的事情。

## 1. 启用异步调用
```java
@SpringBootApplication
@EnableAsync
@Slf4j
public class Chapter21Application {
    public static void main(String[] args) {
        SpringApplication.run(Chapter21Application.class, args);
    }
}
```
## 2. @Async异步调用
使用@Async很简单，只需要在需要异步执行的方法上加入此注解即可。这里创建一个控制层和一个服务层，进行简单示例下。

SyncService.java
```java
@Component
public class SyncService {
    @Async
    public void asyncEvent() throws InterruptedException {
        //休眠1s
        Thread.sleep(1000);
        //log.info("异步方法输出：{}!", System.currentTimeMillis());
    }
    public void syncEvent() throws InterruptedException {
        Thread.sleep(1000);
        //log.info("同步方法输出：{}!", System.currentTimeMillis());
    }
}
```
```text
2019-03-16 22:21:35.949  INFO 17152 --- [nio-8080-exec-5] c.l.l.s.c.controller.AsyncController     : 方法执行开始：1534429295949
2019-03-16 22:21:36.950  INFO 17152 --- [nio-8080-exec-5] c.l.l.s.c.controller.AsyncController     : 同步方法用时：1001
2019-03-16 22:21:36.950  INFO 17152 --- [nio-8080-exec-5] c.l.l.s.c.controller.AsyncController     : 异步方法用时：0
2019-03-16 22:21:36.950  INFO 17152 --- [nio-8080-exec-5] c.l.l.s.c.controller.AsyncController     : 方法执行完成：1534429296950!
2019-03-16 22:21:37.950  INFO 17152 --- [cTaskExecutor-3] c.l.l.s.chapter21.service.SyncService    : 异步方法内部线程名称：SimpleAsyncTaskExecutor-3!
```
可以看出，调用异步方法时，是立即返回的，基本没有耗时。
### 这里有几点需要注意下：

1. 在默认情况下，未设置`TaskExecutor`时，默认是使用`SimpleAsyncTaskExecutor`这个线程池，但此线程不是真正意义上的线程池，因为线程不重用，每次调用都会创建一个新的线程。可通过控制台日志输出可以看出，每次输出线程名都是递增的。
2. 调用的异步方法，不能为同一个类的方法，简单来说，因为Spring在启动扫描时会为其创建一个代理类，而同类调用时，还是调用本身的代理类的，所以和平常调用是一样的。其他的注解如@Cache等也是一样的道理，说白了，就是Spring的代理机制造成的。

### 自定义线程池
前面有提到，在默认情况下，系统使用的是默认的SimpleAsyncTaskExecutor进行线程创建。所以一般上我们会自定义线程池来进行线程的复用。
```java
@Configuration
@EnableAsync
@Slf4j
public class ThreadPoolConfig implements AsyncConfigurer {
    @Autowired
    private BeanFactory beanFactory;
    /**
     * 配置线程池
     * @return
     */
    @Bean(name = "asyncPoolTaskExecutor")
    public ThreadPoolTaskExecutor getAsyncThreadPoolTaskExecutor() {
        ThreadPoolTaskExecutor taskExecutor = new ThreadPoolTaskExecutor();
        taskExecutor.setCorePoolSize(20);
        taskExecutor.setMaxPoolSize(200);
        taskExecutor.setQueueCapacity(25);
        taskExecutor.setKeepAliveSeconds(200);
        taskExecutor.setThreadNamePrefix("Async-");
        // 线程池对拒绝任务（无线程可用）的处理策略，目前只支持AbortPolicy、CallerRunsPolicy；默认为后者
        taskExecutor.setRejectedExecutionHandler(new ThreadPoolExecutor.CallerRunsPolicy());
        //调度器shutdown被调用时等待当前被调度的任务完成
        taskExecutor.setWaitForTasksToCompleteOnShutdown(true);
        //等待时长
        taskExecutor.setAwaitTerminationSeconds(60);
        taskExecutor.initialize();
        //It is important to note here the use of LazyTraceExecutor. This class comes from the Sleuth library and is a special kind of executor that will propagate our traceIds to new threads and create new spanIds in the process.
        return new LazyTraceExecutor(beanFactory, taskExecutor);
    }

    @Override
    public AsyncUncaughtExceptionHandler getAsyncUncaughtExceptionHandler() {
        return new SpringAsyncExceptionHandler();
    }

    class SpringAsyncExceptionHandler implements AsyncUncaughtExceptionHandler {
        @Override
        public void handleUncaughtException(Throwable throwable, Method method, Object... obj) {
            log.error("[Exception occurs in async method]", throwable.getMessage());
        }
    }
}
```
#### It is important to note here the use of `LazyTraceExecutor`. This class comes from the Sleuth library and is a special kind of executor that will propagate our traceIds to new threads and create new spanIds in the process.

此时，使用的是就只需要在@Async加入线程池名称即可：
```java
@Async("asyncPoolTaskExecutor")
public void asyncEvent() throws InterruptedException {
    //休眠1s
    Thread.sleep(1000);
    log.info("异步方法内部线程名称：{}!", Thread.currentThread().getName());
}
```
这里简单说明下，关于`ThreadPoolTaskExecutor`参数说明：
1. `corePoolSize`：线程池维护线程的最少数量
2. `keepAliveSeconds`：允许的空闲时间,当超过了核心线程出之外的线程在空闲时间到达之后会被销毁
3. `maxPoolSize`：线程池维护线程的最大数量,只有在缓冲队列满了之后才会申请超过核心线程数的线程
4. `queueCapacity`：缓存队列
5. `rejectedExecutionHandler`：线程池对拒绝任务（无线程可用）的处理策略。这里采用了CallerRunsPolicy策略，当线程池没有处理能力的时候，该策略会直接在 execute 方法的调用线程中运行被拒绝的任务；如果执行程序已关闭，则会丢弃该任务。还有一个是AbortPolicy策略：处理程序遭到拒绝将抛出运行时RejectedExecutionException。

而在一些场景下，若需要在关闭线程池时等待当前调度任务完成后才开始关闭，可以通过简单的配置，进行优雅的停机策略配置。关键就是通过`setWaitForTasksToCompleteOnShutdown(true)`和`setAwaitTerminationSeconds`方法。

`setWaitForTasksToCompleteOnShutdown`:表明等待所有线程执行完，默认为false。
`setAwaitTerminationSeconds`:等待的时间，因为不能无限的等待下去。


## 3.CompletableFuture异步编程
在Java 8中，引入了CompletableFuture类。与Future接口一起，它还实现了CompletionStage接口。此接口定义了可与其他步骤组合的异步计算步骤的契约。
```java
@Async("asyncPoolTaskExecutor")
public CompletableFuture<GenericResponse> asyncEvent() {
    ...
    return CompletableFuture.completedFuture(response);
}

CompletableFuture future = service.asyncEvent();
future.handle((genericResponse, throwable) -> {
    if (throwable != null) {
        log.error("profileFuture {}", throwable);
    }
    return genericResponse;
});
CompletableFuture.allOf(future1, future2, future3, future4).join();//等待所有县城执行完毕
future.get(); //在等待执行结果时，程序会一直block，如果此时调用complete(T t)会立即执行。
```

并行运行多个任务
当我们需要并行执行多个任务时，我们通常希望等待所有它们执行，然后处理它们的组合结果。

该`CompletableFuture.allOf`静态方法允许等待所有的完成任务


```java
@Aspect
@Component
public class LogExecutionTimeAspect {
    @Around("@annotation(LogExecutionTime)")
    public Object logExecutionTime(ProceedingJoinPoint joinPoint) throws Throwable {
        final long start = System.currentTimeMillis();
        final Object proceed = joinPoint.proceed();
        final long executionTime = System.currentTimeMillis() - start;
        log.info("Execution Time For {} is -->> {}  ms",joinPoint.getSignature(),executionTime);
        return proceed;
    }
}
```

[更多参考](https://juejin.im/post/5ca47aa0e51d457131257269#heading-4)