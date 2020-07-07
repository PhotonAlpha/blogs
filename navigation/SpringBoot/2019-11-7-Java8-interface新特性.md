# Java 8 interface 接口里面的default关键字的使用，以及意义

## 1. default函数

在Java8以前，Interface中的函数是不能实现的，如下：

```java
public interface MyInterface {
	int MAX_SERVICE_TIME = 100;

	void test();
}
```
在Java8中，Interface中支持函数有实现，只要在函数前加上default关键字即可，如下：
```java
public interface MyInterface {
	int MAX_SERVICE_TIME = 100;

	void test();
	
	default void doSomething() {
		System.out.println("do something");
	}
}
```
> `default`函数，实现类可以不实现这个方法。
在Java8之前，如果我们想实现这样的功能，也是有办法的，那就是先定义Interface，然后定义Abstract Class实现Interface，然后再定义Class继承Abstract Class，这样Class就不用实现Interface中的全部方法。

## 2. static函数
在Java8中允许Interface定义static方法，这允许API设计者在接口中定义像getInstance一样的静态工具方法，这样就能够使得API简洁而精练，如下：
```java
public interface MyInterface {
    static void doNothing() {
        System.out.println("doNothing");
    }
}
```
测试：
```java
@Test
void testInterFace() {
  myInterface.doSomething();
  MyInterface.doNothing();
}
```
结果：
    do something
    doNothing

## 3. @FunctionalInterface注解
函数式接口其实本质上还是一个接口，但是它是一种特殊的接口：SAM类型的接口（Single Abstract Method）。定义了这种类型的接口，使得以其为参数的方法，可以在调用时，使用一个Lambda表达式作为参数。

```java
@FunctionalInterface
public interface MyInterface {
	void test();
}
```
使用方法
```java
@Test
void testInterFace() {
  MyFunctionInterface mf = () -> System.out.println(this.getClass().getName());
  mf.test();
}
```

`@FunctionalInterface`注解能帮我们检测Interface是否是函数式接口，但是这个注解是**非必须的，不加也不会报错。**

```java
@FunctionalInterface
public interface MyInterface {//报错
	void test();

	void doSomething();
}
```
>Interface中的非default／static方法都是abstract的，所以上面的接口不是函数式接口，加上@FunctionalInterface的话，就会提示我们这不是一个函数式接口。

## 4. **Java 9 接口 ( interface ) 的私有方法**
Java 9中，接口再次增强，可以实现private method和private static method。 接口中的私有方法供内部调用，不会暴露给实现类。

再Java 8以前，interface中只有`public static final 常量`和`抽象方法`，在有了这俩以后，接口和抽象类的区别，只剩下了构造器、成员变量、以及单继承。

```java
public interface MyInterface {
    default void doSomething() {
        System.out.println("do something");
        privateMethod();
    }

    static void doNothing() {
        System.out.println("doNothing");
        privateStaticMethod();
    }
    private void privateMethod() {
        System.out.println("privateMethod");
    }
    private static void privateStaticMethod() {
        System.out.println("privateStaticMethod");
    }

}
```