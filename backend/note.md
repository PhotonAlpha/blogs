面试官除了希望能够完成基本的功能，还会考虑应聘者是否完成了边界条件、特殊输入（null, empty string）及错误处理

数组：是最简单的一种数据结构，它占据一块连续的内存并按照顺序存储。

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

    - 公平锁
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

