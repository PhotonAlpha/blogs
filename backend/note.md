面试官除了希望能够完成基本的功能，还会考虑应聘者是否完成了边界条件、特殊输入（null, empty string）及错误处理

数组：是最简单的一种数据结构，它占据一块连续的内存并按照顺序存储。

# 事务特性
    - 原子性：要么一起成功，要么一起失败
    - 一致性：最终的结果与期望的结果一致
    - 隔离性：结果之间不会相互影响
    - 持久性：一旦成功，就永久性的改变数据，不再能回滚

# volatile
锁： 加锁机制可以确保可见性又可以确保原子性，而volatile变量只能确保可见性
当满足以下所有条件时，才应该使用volatile变量：
- 对变量的写入操作不依赖变量的当前值，或者能确定只有当个线程更新变量的值。
- 该变量不会与其他状态变量一起纳入不变性条件中。
- 在访问变量时不需要加锁。

1. 动态规划 
2. 贪婪算法

# 锁
ReentrantLock 
ReentrantLock的实现依赖于Java同步器框架AbstractQueuedSynchronizer（本文简称之为AQS）。AQS使用一个整型的volatile变量（命名为state）来维护同步状态，这个volatile变量是ReentrantLock内存语义实现的关键。
    AbstractQueuedSynchronizer
        private volatile int state
        public final void acquire(int arg)
        public final boolean release(int arg)

重进入是指任意线程在获取到锁之后能够再次获取该锁而不会被锁所阻塞，该特性的实现需要解决以下两个问题：
    1. 线程再次获取锁。锁需要去识别获取锁的线程是否为当前占据锁的线程，如果是，则再次成功获取    
    2. 锁的最终释放。线程重复n次获取了锁，随后在第n次释放该锁后，其他线程能够获取到该锁。锁的最终释放要求锁对于获取进行计数自增，计数表示当前锁被重复获取的次数，而锁被释放时，计数自减，当计数等于0时表示锁已经成功释放

    - 公平锁
        定义：如果在绝对时间上，先对锁进行获取的请求一定先被满足，那么这个锁是公平的。等待时间最长的线程优先获取锁。
        # 加锁方法lock()调用轨迹
        - ReentrantLock::lock()
        - FairSync::lock()
        - AbstractQueuedSynchronizer::acquire(int arg)
        - ReentrantLock::tryAcquire(int acquires)  # 开始真正加锁
        # 解锁方法unlock()调用轨迹
        - ReentrantLock::unlock()
        - AbstractQueuedSynchronizer::release(int arg)
        - Sync::tryRelease(int releases)           # 开始真正释放锁
    - 非公平锁
        定义：反之，是不公平的。公平的锁机制往往没有非公平的效率高，但是，并不是任何场景都是以TPS作为唯一的指标，公平锁能够减少“饥饿”发生的概率，等待越久的请求越是能够得到优先满足。
        # 非公平锁的释放和公平锁完全一样，所以这里仅仅分析非公平锁的获取。
        - ReentrantLock::lock()
        - NonfairSync::lock()
        - AbstractQueuedSynchronizer::compareAndSetState(int expect,int update) # 开始真正加锁

    - 公平锁、非公平锁 总结
        - 公平锁和非公平锁释放时，最后都要写一个volatile变量state
        - 公平锁获取时，首先会读取volatile变量
        - 非公平锁获取时，首先会用CAS更新volatile变量,这个操作同时具有volatile读和volatile写的内存语义


concurrent包的实现：
    由于Java的CAS同时具有volatile读和volatile写的内存语义，因此Java线程之间的通信现在有了下面4种方式
        1. A线程写volatile变量，随后B线程读这个volatile变量
        2. A线程写volatile变量，随后B线程用CAS更新这个volatile变量
        3. A线程用CAS更新一个volatile变量，随后B线程用CAS更新这个volatile变量
        4. A线程用CAS更新一个volatile变量，随后B线程读这个volatile变量
    我们仔细分析concurrent包的源代码实现，会发现一个通用化的实现模式
        1. 声明共享变量为volatile
        2. 使用CAS的原子条件更新来实现线程之间的同步
        3. 配合以volatile的读/写和CAS所具有的volatile读和写的内存语义来实现线程之间的通信。

# final
    与前面介绍的锁和volatile相比，对final域的读和写更像是普通的变量访问, 但是编译器和处理器要遵守两个重排序规则:
    1. 在构造函数内对一个final域的写入，与随后把这个被构造对象的引用赋值给一个引用变量，这两个操作之间不能重排序
    2. 初次读一个包含final域的对象的引用，与随后初次读这个final域，这两个操作之间不能重排序。

# 双重检查锁定与延迟初始化（142页）

    实现线程安全的延迟初始化
        - 不允许2和3重排序
        - 允许2和3重排序，但不允许其他线程“看到”这个重排序

    - 基于volatile的解决方案
        ```java
        // 当声明对象的引用为volatile后，3.8.2节中的3行伪代码中的2和3之间的重排序，在多线程 
        public class SafeDoubleCheckedLocking {
            private volatile static Instance instance;

            public static Instance getInstance() {
                if (instance == null) {
                    synchronized (SafeDoubleCheckedLocking.class) {
                    if (instance == null)
                        instance = new Instance(); // instance为volatile，现在没问题了
                    }
                }
                return instance;
            }
        }
        ```

    - 基于类初始化的解决方案
    原理：JVM在类的初始化阶段（即在Class被加载后，且被线程使用之前），会执行类的初始化。在执行类的初始化期间，JVM会去获取一个锁。这个锁可以同步多个线程对同一个类的初始化。
        ```java
        public class InstanceFactory {
            private InstanceFactory() {
            }
            public static DashboardController getInstance() {
                return InstanceHolder.instance; // 这里将导致InstanceHolder类被初始化
            }

            private static class InstanceHolder {
                public static final Instance instance = new Instance();
            }
        }
        ```

# 等待/通知的相关方法是任意Java对象都具备的，因为这些方法被定义在所有对象的超类java.lang.Object
    1. notify()         :
    2. notifyAll()      :
    3. wait()           :
    4. wait(long)       :
    5. wait(log, int)   :

# ThreadLocal的使用
ThreadLocal，即线程变量，是一个以ThreadLocal对象为键、任意对象为值的存储结构。这个结构被附带在线程上，也就是说一个线程可以根据一个ThreadLocal对象查询到绑定在这个线程上的一个值

# 线程池技术
如果服务端每次接受到一个任务，创建一个线程，然后进行执行，这在原型阶段是个不错的选择，但是面对成千上万的任务递交进服务器时，如果还是采用一个任务一个线程的方式，那么将会创建数以万记的线程，这不是一个好的选择。
因为这会使操作系统频繁的进行线程上下文切换，无故增加系统的负载，而线程的创建和消亡都是需要耗费系统资源的，也无疑浪费了系统资源。

# Lock接口提供的synchronized关键字不具备的主要特性
    - 尝试非阻塞的获取锁【当前线程尝试获取锁，如果这一时刻锁没有被其他线程获取到，则成功获取并持有锁】 ::lock() ::tryLock() ::unlock()
    - 能被中断的获取锁【与synchronized不同，获取到锁的线程能够响应中断，当获取到的线程被中断时，中断异常将被抛出，同时锁会被释放】 ::lockInterruptibly() 
    - 超时获取锁【在指定的截止时间之前获取锁，如果截止时间到了仍旧无法获取到锁，则返回】 ::tryLock(long, timeUint)

# 队列同步器AbstractQueuedSynchronizer（AQS） & ReentrantLock
队列同步器AbstractQueuedSynchronizer（以下简称同步器），是用来构建锁或者其他同步组件的基础框架，它使用了一个int成员变量表示同步状态，通过内置的FIFO队列来完成资源获取线程的排队工作，并发包的作者（Doug Lea）期望它能够成为实现大部分同步需求的基础。

同步器的主要使用方式是继承，子类通过继承同步器并实现它的抽象方法来管理同步状态，在抽象方法的实现过程中免不了要对同步状态进行更改，这时就需要使用同步器提供的3个方法（getState()、setState(int newState)和compareAndSetState(int expect,int update)）来进行操作，因为它们能够保证状态的改变是安全的。
子类推荐被定义为自定义同步组件的静态内部类，同步器自身没有实现任何同步接口，它仅仅是定义了若干同步状态获取和释放的方法来供自定义同步组件使用，同步器既可以支持独占式地获取同步状态，也可以支持共享式地获取同步状态，这样就可以方便实现不同类型的同步组件（ReentrantLock、ReentrantReadWriteLock和CountDownLatch等）

同步器是实现锁（也可以是任意同步组件）的关键，在锁的实现中聚合同步器，利用同步器实现锁的语义。
可以这样理解二者之间的关系：锁是面向使用者的，它定义了使用者与锁交互的接口（比如可以允许两个线程并行访问），隐藏了实现细节；同步器面向的是锁的实现者，它简化了锁的实现方式，屏蔽了同步状态管理、线程的排队、等待与唤醒等底层操作。
锁和同步器很好地隔离了使用者和实现者所需关注的领域。

    - 同步队列
        同步器依赖内部的同步队列（一个FIFO双向队列）来完成同步状态的管理，当前线程获取同步状态失败时，同步器会将当前线程以及等待状态等信息构造成为一个节点（Node）并将其加入同步队列，同时会阻塞当前线程，当同步状态释放时，会把首节点中的线程唤醒，使其再次尝试获取同步状态。

    - 独占式同步状态获取与释放
        通过调用同步器的acquire(int arg)方法可以获取同步状态，该方法对中断不敏感，也就是由于线程获取同步状态失败后进入同步队列中，后续对线程进行中断操作时，线程不会从同步队列中移出.

    - 共享式同步状态获取与释放
        共享式获取与独占式获取最主要的区别在于同一时刻能否有多个线程同时获取到同步状态.
        以文件的读写为例，如果一个程序在对文件进行读操作，那么这一时刻对于该文件的写操作均被阻塞，而读操作能够同时进行。写操作要求对资源的独占式访问，而读操作可以是共享式访问.

## 队列同步器的接口与示例
同步器的设计是基于模板方法模式的，也就是说，使用者需要继承同步器并重写指定的方法，随后将同步器组合在自定义同步组件的实现中，并调用同步器提供的模板方法，而这些模板方法将会调用使用者重写的方法。
需要重写的方法：
    - getState()：获取当前同步状态
    - setState(int newState)：设置当前同步状态
    - compareAndSetState(int expect,int update)：使用CAS设置当前状态，该方法能够保证状态设置的原子性。
可重写的方法:
    - tryAcquire(int arg) 独占式获取同步状态，实现该方法需要查询当前状态并判断同步状态是否符合预期，然后再进行CAS设置同步状态
    - tryRelease(int arg) 独占式释放同步状态，等待获取同步状态的线程将有机会获取同步状态
    - tryAcquireShared(int arg) 共享式的获取同步状态，返回大于等于0的值，表示获取成功，反之，获取失败
    - tryReleaseShared(int arg) 共享式释放同步状态
    - isHeldExclusively() 当前同步器是否独占模式下被线程占用，一般该方法表示是否被当前线程所独占

1. 独占锁:就是在同一时刻只能有一个线程获取到锁，而其他获取锁的线程只能处于同步队列中等待，只有获取锁的线程释放了锁，后继的线程才能够获取锁
2. 

Java中的锁
1. Lock接口
    锁是用来控制多个线程访问共享资源的方式，一般来说，一个锁能够防止多个线程同时访问共享资源（但是有些锁可以允许多个线程并发的访问共享资源，比如读写锁）。
    在Lock接口出现之前，Java程序是靠synchronized关键字实现锁功能的。
    它缺少了（通过synchronized块或者方法所提供的）隐式获取释放锁的便捷性，但是却拥有了锁获取与释放的可操作性、可中断的获取锁以及超时获取锁等多种synchronized关键字所不具备的同步特性。
2. 队列同步器
    队列同步器AbstractQueuedSynchronizer（以下简称同步器），是用来构建锁或者其他同步组件的基础框架，它使用了一个int成员变量表示同步状态，通过内置的FIFO队列来完成资源获取线程的排队工作，并发包的作者（Doug Lea）期望它能够成为实现大部分同步需求的基础。
3. 重入锁(ReentrantLock)
    重入锁ReentrantLock，顾名思义，就是支持重进入的锁，它表示该锁能够支持一个线程对资源的重复加锁。除此之外，该锁的还支持获取锁时的公平和非公平性选择。
4. 读写锁（ReentrantReadWriteLock）
    之前提到锁（如Mutex和ReentrantLock）基本都是排他锁，这些锁在同一时刻只允许一个线程进行访问，而读写锁在同一时刻可以允许多个读线程访问，但是在写线程访问时，所有的读线程和其他写线程均被阻塞。
    读写锁维护了一对锁，一个读锁和一个写锁，通过分离读锁和写锁，使得并发性相比一般的排他锁有了很大提升。

        读写锁（ReentrantReadWriteLock）支持锁降级：锁降级指的是写锁降级成为读锁。
                                                    如果当前线程拥有写锁，然后将其释放，最后再获取读锁，这种分段完成的过程不能称之为锁降级。
                                                    锁降级是指把持住（当前拥有的）写锁，再获取到读锁，随后释放（先前拥有的）写锁的过程。
5. LockSupport工具
    当需要阻塞或唤醒一个线程的时候，都会使用LockSupport工具类来完成相应工作。LockSupport定义了一组的公共静态方法，这些方法提供了最基本的线程阻塞和唤醒功能，而LockSupport也成为构建同步组件的基础工具。
    LockSupport定义了一组以park开头的方法用来阻塞当前线程，以及unpark(Thread thread)方法来唤醒一个被阻塞的线程。
6. Condition接口
    任意一个Java对象，都拥有一组监视器方法（定义在java.lang.Object上），主要包括wait()、wait(long timeout)、notify()以及notifyAll()方法，这些方法与synchronized同步关键字配合，可以实现等待/通知模式。
    Condition接口也提供了类似Object的监视器方法，与Lock配合可以实现等待/通知模式，但是这两者在使用方式以及功能特性上还是有差别的。
    Condition定义了等待/通知两种类型的方法，当前线程调用这些方法时，需要提前获取到Condition对象关联的锁。
    Condition对象是由Lock对象（调用Lock对象的newCondition()方法）创建出来的，换句话说，Condition是依赖Lock对象的。

# Java并发容器和框架
## ConcurrentHashMap的实现原理与使用
1. 线程不安全的HashMap
    在多线程环境下，使用HashMap进行put操作会引起死循环，导致CPU利用率接近100%，所以在并发情况下不能使用HashMap。
    HashMap在并发执行put操作时会引起死循环，是因为多线程会导致HashMap的Entry链表形成环形数据结构，一旦形成环形数据结构，Entry的next节点永远不为空，就会产生死循环获取Entry。

2. 效率低下的HashTable
    HashTable容器使用synchronized来保证线程安全，但在线程竞争激烈的情况下HashTable的效率非常低下。
    因为当一个线程访问HashTable的同步方法，其他线程也访问HashTable的同步方法时，会进入阻塞或轮询状态。
    如线程1使用put进行元素添加，线程2不但不能使用put方法添加元素，也不能使用get方法来获取元素，所以竞争越激烈效率越低。    

3. ConcurrentHashMap的锁分段技术可有效提升并发访问率
    HashTable容器在竞争激烈的并发环境下表现出效率低下的原因是所有访问HashTable的线程都必须竞争同一把锁，假如容器里有多把锁，每一把锁用于锁容器其中一部分数据，那么当多线程访问容器里不同数据段的数据时，线程间就不会存在锁竞争，从而可以有效提高并发访问效率，这就是ConcurrentHashMap所使用的锁分段技术。
    首先将数据分成一段一段地存储，然后给每一段数据配一把锁，当一个线程占用锁访问其中一个段数据的时候，其他段的数据也能被其他线程访问。

    ConcurrentHashMap是由Segment数组结构和HashEntry数组结构组成。
    Segment是一种可重入锁（ReentrantLock），在ConcurrentHashMap里扮演锁的角色；HashEntry则用于存储键值对数据。
    一个ConcurrentHashMap里包含一个Segment数组。
    Segment的结构和HashMap类似，是一种数组和链表结构。
    一个Segment里包含一个HashEntry数组，每个HashEntry是一个链表结构的元素，每个Segment守护着一个HashEntry数组里的元素，当对HashEntry数组的数据进行修改时，必须首先获得与它对应的Segment锁。

    1. 初始化segments数组- segments数组的长度ssize是通过concurrencyLevel计算得出的
    2. 初始化segmentShift和segmentMask
    3. 初始化每个segment

## ConcurrentLinkedQueue    
在并发编程中，有时候需要使用线程安全的队列。如果要实现一个线程安全的队列有两种方式：
    一种是使用阻塞算法，另一种是使用非阻塞算法。
    使用阻塞算法的队列可以用一个锁（入队和出队用同一把锁）或两个锁（入队和出队用不同的锁）等方式来实现。
    非阻塞的实现方式则可以使用循环CAS的方式来实现。
    本节让我们一起来研究一下Doug Lea是如何使用非阻塞的方式来实现线程安全队列ConcurrentLinkedQueue的，相信从大师身上我们能学到不少并发编程的技巧。

# Fork/Join框架
1. ForkJoinTask：我们要使用ForkJoin框架，必须首先创建一个ForkJoin任务。它提供在任务中执行fork()和join()操作的机制。
通常情况下，我们不需要直接继承ForkJoinTask类，只需要继承它的子类，Fork/Join框架提供了以下两个子类。
    - RecursiveAction：用于没有返回结果的任务。
    - RecursiveTask：用于有返回结果的任务。

2. ForkJoinPool：ForkJoinTask需要通过ForkJoinPool来执行

# Java中的13个原子操作类
    在Atomic包里一共提供了12个类，属于4种类型的原子更新方式，分别是原子更新基本类型、原子更新数组、原子更新引用和原子更新属性（字段）.Atomic包里的类基本都是使用Unsafe实现的包装类.

    - AtomicBoolean：原子更新布尔类型
    - AtomicInteger：原子更新整型
    - AtomicLong：原子更新长整型

    - AtomicIntegerArray：原子更新整型数组里的元素
    - AtomicLongArray：原子更新长整型数组里的元素
    - AtomicReferenceArray：原子更新引用类型数组里的元素
    - AtomicIntegerArray类主要是提供原子的方式更新数组里的整型

    - AtomicReference：原子更新引用类型
    - AtomicReferenceFieldUpdater：原子更新引用类型里的字段
    - AtomicMarkableReference：原子更新带有标记位的引用类型

    - AtomicIntegerFieldUpdater：原子更新整型的字段的更新器
    - AtomicLongFieldUpdater：原子更新长整型字段的更新器
    - AtomicStampedReference：原子更新带有版本号的引用类型

# Java中的并发工具类
    - 等待多线程完成的CountDownLatch

        应用场景: Excel多sheet解析,主线程等待所有线程完成sheet的解析操作. 视屏聊天室等.

    - 同步屏障CyclicBarrier
        CountDownLatch的计数器只能使用一次，而CyclicBarrier的计数器可以使用reset()方法重置。
        所以CyclicBarrier能处理更为复杂的业务场景。例如，如果计算发生错误，可以重置计数器，并让线程重新执行一次。

        应用场景: 用一个Excel保存用户所有银行流水，每个Sheet保存一个账户近一年的每笔银行流水,现在需要统计用户的日均银行流水，
        先用多线程处理每个sheet里的银行流水，都执行完之后，得到每个sheet的日均银行流水，最后，再用barrierAction用这些线程的计算结果，计算出整个Excel的日均银行流水

    - 控制并发线程数的Semaphore    
        Semaphore（信号量）是用来控制同时访问特定资源的线程数量，它通过协调各个线程，以保证合理的使用公共资源。

        应用场景: Semaphore可以用于做流量控制,数据库的连接数只有10个，这时我们必须控制只有10个线程同时获取数据库连接保存数据，否则会报错无法获取数据库连接。这个时候，就可以使用Semaphore来做流量控制 

    - 线程间交换数据的Exchanger
        Exchanger（交换者）是一个用于线程间协作的工具类。Exchanger用于进行线程间的数据交换。
        它提供一个同步点，在这个同步点，两个线程可以交换彼此的数据。这两个线程通过exchange方法交换数据，如果第一个线程先执行exchange()方法，
        它会一直等待第二个线程也执行exchange方法，当两个线程都到达同步点时，这两个线程就可以交换数据，将本线程生产出来的数据传递给对方。    

        应用场景: Exchanger可以用于遗传算法，遗传算法里需要选出两个人作为交配对象，这时候会交换两人的数据，并使用交叉规则得出2个交配结果。
        Exchanger也可以用于校对工作，比如我们需要将纸制银行流水通过人工的方式录入成电子银行流水，为了避免错误，采用AB岗两人进行录入，录入到Excel之后，
        系统需要加载这两个Excel，并对两个Excel数据进行校对，看看是否录入一致.

# Java中的线程池
    合理地使用线程池能够带来3个好处:
        1. 降低资源消耗。通过重复利用已创建的线程降低线程创建和销毁造成的消耗
        2. 提高响应速度。当任务到达时，任务可以不需要等到线程创建就能立即执行
        3. 提高线程的可管理性。线程是稀缺资源，如果无限制地创建，不仅会消耗系统资源，还会降低系统的稳定性，使用线程池可以进行统一分配、调优和监控。

    流程:
        核心线程池是否已满(core pool) --> 队列是否已满(BlockingQueue) -->  线程池是否已满(maximumPool) --> 安装管理策略处理(RejectedExecutionHandler)

# Executor框架的结构
    - ThreadPoolExecutor
        ThreadPoolExecutor通常使用工厂类Executors来创建。Executors可以创建3种类型的ThreadPoolExecutor：SingleThreadExecutor、FixedThreadPool和CachedThreadPool。
        
    - ScheduledThreadPoolExecutor
        ScheduledThreadPoolExecutor通常使用工厂类Executors来创建。Executors可以创建2种类型的ScheduledThreadPoolExecutor，如下。
            - ScheduledThreadPoolExecutor。包含若干个线程的ScheduledThreadPoolExecutor。
            - SingleThreadScheduledExecutor。只包含一个线程的ScheduledThreadPoolExecuto

    - Future接口
        Future接口和实现Future接口的FutureTask类用来表示异步计算的结果。

    - Runnable接口
        Runnable接口和Callable接口的实现类，都可以被ThreadPoolExecutor或Scheduled-ThreadPoolExecutor执行。它们之间的区别是Runnable不会返回结果，而Callable可以返回结果。

    - Callable接口
        见上

    - Executors 
        工厂类Executors, 还可以把一个Runnable包装成一个Callable      

# FutureTask的实现
    FutureTask的实现基于AbstractQueuedSynchronizer（以下简称为AQS）。java.util.concurrent中的很多可阻塞类（比如ReentrantLock）都是基于AQS来实现的。
    AQS是一个同步框架，它提供通用机制来原子性管理同步状态、阻塞和唤醒线程，以及维护被阻塞线程的队列。
    JDK 6中AQS被广泛使用，基于AQS实现的同步器包括：ReentrantLock、Semaphore、ReentrantReadWriteLock、CountDownLatch和FutureTask。
