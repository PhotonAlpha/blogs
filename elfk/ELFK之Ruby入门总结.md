# Ruby 数据类型

## 数值类型(Number)
#### 1、整型(Integer)
```ruby
123                  # Fixnum 十进制
1_234                # Fixnum 带有下划线的十进制
-500                 # 负的 Fixnum
0377                 # 八进制
0xff                 # 十六进制
0b1011               # 二进制
"a".ord              # "a" 的字符编码
?\n                  # 换行符（0x0a）的编码
12345678901234567890 # 大数
 
#整型 Integer 以下是一些整型字面量 
#字面量（literal）：代码中能见到的值，数值，bool值，字符串等都叫字面量 
#如以下的0,1_000_000,0xa等 
a1=0 
 
#带千分符的整型 
a2=1_000_000 
 
#其它进制的表示 
a3=0xa 
puts a1,a2 
puts a3 
 
#puts print 都是向控制台打印字符，其中puts带回车换行符 
=begin 
这是注释，称作：嵌入式文档注释 
类似C#中的/**/ 
=end
```
#### 2、浮点型(Float)
Ruby 支持浮点数。它们是带有小数的数字。浮点数是类 Float 的对象，且可以是下列中任意一个。

```ruby
123.4                # 浮点值
1.0e6                # 科学记数法
4E20                 # 不是必需的
4e+20                # 指数前的符号
 
#浮点型 
f1=0.0 
f2=2.1 
f3=1000000.1 
puts f3
```
#### 3、算术操作
加减乘除操作符：+-*/；指数操作符为**

指数不必是整数
```ruby
#指数算术 
puts 2**(1/4)#1与4的商为0，然后2的0次方为1 
puts 16**(1/4.0)#1与4.0的商为0.25（四分之一），然后开四次方根
```

#### 4、字符串类型
Ruby 字符串分为单引号字符串（'）和双引号字符串（"），区别在于双引号字符串能够支持更多的转义字符

双引号标记的字符串允许替换和使用反斜线符号，单引号标记的字符串不允许替换，且只允许使用 \\ 和 \' 两个反斜线符号。
```ruby
puts 'escape using "\\"'
puts 'That\'s right'
```
[更多用法戳这里](https://www.runoob.com/ruby/ruby-string.html)

#### 5、数组 & 哈希类型
数组字面量通过[]中以逗号分隔定义，且支持range定义。

- 数组通过[]索引访问
- 通过赋值操作插入、删除、替换元素
- 过+，－号进行合并和删除元素，且集合做为新集合出现
- 通过<<号向原数据追加元素
- 通过*号重复数组元素
- 通过｜和&符号做并集和交集操作（注意顺序）

[更多用法戳这里](https://www.runoob.com/ruby/ruby-array.html)
```ruby
ary = [ "fred", 10, 3.14, "This is a string", "last element", ]
ary.each { |i| puts i }

hsh = colors = { "red" => 0xf00, "green" => 0x0f0, "blue" => 0x00f }
hsh.each { |key, value| print key," is ", value, "\n"}
```

#### 6、Ruby 类中的变量
- **常数**: 大写字母开头：常数（Constant）
- **全局变量**：类变量不能跨类使用。如果您想要有一个可以跨类使用的变量，您需要定义全局变量。全局变量总是以美元符号（`$`）开始。
- **实例变量**：实例变量可以跨任何特定的实例或对象中的方法使用。这意味着，实例变量可以从对象到对象的改变。实例变量在变量名之前放置符号（`@`）。
- **类变量**：类变量可以跨不同的对象使用。类变量属于类，且是类的一个属性。类变量在变量名之前放置符号（`@@`）。
- **局部变量**：局部变量是在方法中定义的变量。局部变量在方法外是不可用的。局部变量以`小写字母或 _`开始。

    [**运算符操作**](https://www.runoob.com/ruby/ruby-operator.html)
```ruby
$global_variable = 10 # 全局变量
VAR_CONSTANT = 100
class Customer
  @@no_of_customers = 0 # 类变量
=begin
  您可以给方法 new 传递参数，这些参数可用于初始化类变量。
  当您想要声明带参数的 new 方法时，您需要在创建类的同时声明方法 initialize。
  initialize 方法是一种特殊类型的方法，将在调用带参数的类的 new 方法时执行。
=end
  def initialize(id, name, addr)
    @cust_id = id  # 实例变量
    @cust_name = name
    @cust_addr = addr
  end

=begin
  在 Ruby 中，函数被称为方法。类中的每个方法是以关键字 def 开始，后跟方法名。
  方法名总是以小写字母开头。在 Ruby 中，您可以使用关键字 end 来结束一个方法。
=end
  def hello
    puts "Hello Ruby!"
  end

=begin
  将在一个单行上显示文本 Customer id 和变量 @cust_id 的值。
  1. 当您想要在一个单行上显示实例变量的文本和值时，您需要在 puts 语句的变量名前面放置符号（#）。文本和带有符号（#）的实例变量应使用双引号标记。
  2. 第二个方法，total_no_of_customers，包含了类变量 @@no_of_customers。
  表达式 @@no_of_ customers+=1 在每次调用方法 total_no_of_customers 时，把变量 no_of_customers 加 1。通过这种方式，您将得到类变量中的客户总数量。
=end
  def display_details
    puts "Customer id #@cust_id"
    puts "Customer name #@cust_name"
    puts "Customer address #@cust_addr"
  end

  def total_no_of_customers
    @@no_of_customers += 1
    puts "Total number of customers: #@@no_of_customers"
  end
end

class Class1
  def display_global
    puts "全局变量在 Class1 中输出为 #$global_variable"
    puts "常量在 Class1 中输出为#{VAR_CONSTANT}"
  end
end
class Class2
  def display_global
    puts "全局变量在 Class2 中输出为 #$global_variable"
    puts "常量在 Class2 中输出为#{VAR_CONSTANT}"
  end
end

cust1=Customer.new("1", "John", "Wisdom Apartments, Ludhiya")
cust2=Customer.new("2", "Poul", "New Empire road, Khandala")
cust3=Class1.new
cust4=Class2.new

cust1.display_details()
cust1.total_no_of_customers()
puts "------------"
cust2.display_details()
cust2.total_no_of_customers()
puts "------"
cust3.display_global
cust4.display_global
puts "--------"
```

#### 7、Ruby 条件判断 & 循环
- `if` conditional `[then]` `elseif`
- code `if` condition
- `unless` conditional `[then]` `else`
- `case` expression
--------------------------------
- `while` conditional code `end`
- `begin` code `end` `while` conditional
- `until` conditional code `end`
- `begin` code `end` `until` conditional
- `for`

#### 8、Ruby 类方法
- 
    当方法定义在类的外部，方法默认标记为`private`。另一方面，如果方法定义在类中的，则默认标记为 `public`。

    方法默认的可见性和 private 标记可通过模块（Module）的 `public` 或 `private` 改变。

    当你想要访问类的方法时，首先需要`实例化类`。然后，使用对象，可以访问`类的任何成员`。

    Ruby 提供了一种不用实例化即可访问方法的方式。
    ```ruby
    class Accounts
    def reading_charge
    end
    def Accounts.return_date
    end
    end
    # 可以直接访问
    Accounts.return_date
    ```
- **alias 语句**

    这个语句用于为**方法或全局变量起别名**。`别名`不能在方法主体内定义。即使方法被重写，方法的别名也保持方法的当前定义。

    为编号的全局变量（$1, $2,...）起别名是**被禁止的**。重写内置的全局变量可能会导致严重的问题。
    ```
    alias 方法名 方法名
    alias 全局变量 全局变量
    ```    
- **块 语句**
    
    Ruby 有一个块的概念。

    每个 Ruby 源文件可以声明当文件被加载时要运行的代码块（`BEGIN` 块），以及程序完成执行后要运行的代码块（`END` 块）。
    - 块由大量的代码组成。
    - 您需要给块取个名称。
    - 块中的代码总是包含在大括号 `{}` 内。
    - 块总是从与其具有相同名称的函数调用。这意味着如果您的块名称为 test，那么您要使用函数 test 来调用这个块。
    - 您可以使用 `yield` 语句来调用块。

    ```ruby
    BEGIN {
    # BEGIN 代码块
        puts "BEGIN 代码块"
    }

    END {
    # END 代码块
        puts "END 代码块"
    }

    def test
        puts "在 test 方法内"
        yield 5, 2
        puts "你又回到了 test 方法内"
        yield 100, 2
    end

    test {|i,j| puts "你在块内 #{i} #{j} "} # 通常使用 yield 语句从与其具有相同名称的方法调用块

    # 如果方法的最后一个参数前带有 &，那么您可以向该方法传递一个块，且这个块可被赋给最后一个参数。如果 * 和 & 同时出现在参数列表中，& 应放在后面
    def test2(i, &block)
        puts "num:#{i}"
        block.call
    end
    test2(100) { puts "Hello World!"}
    ```

- **模块 (Module)**

    模块（Module）是一种把方法、类和常量组合在一起的方式。模块（Module）为您提供了两大好处。

    - 模块提供了一个命名空间和避免名字冲突。
    - 模块实现了 mixin 装置。

    模块（Module）定义了一个命名空间，相当于一个沙盒，在里边您的方法和常量不会与其他地方的方法常量冲突。

    模块类似与类，但有以下不同：

    - 模块不能实例化
    - 模块没有子类
    - 模块只能被另一个模块定义

    `require` 语句类似于 C 和 C++ 中的 `include` 语句以及 Java 中的 `import` 语句。如果一个第三方的程序想要使用任何已定义的模块，则可以简单地使用 Ruby require 语句来加载模块文件.
    
    可以设置`$LOAD_PATH << '.'` 让 Ruby 知道必须在当前目录中搜索被引用的文件。如果您不想使用 $LOAD_PATH，那么您可以使用 `require_relative` 来从一个相对目录引用文件

    你也可以在类中嵌入模块。为了在类中嵌入模块，可以在类中使用 `include` 语句

    Ruby 不直接支持多重继承，但是 Ruby 的模块（Module）有另一个神奇的功能。它几乎消除了多重继承的需要，提供了一种名为 `mixin` 的装置
    ```ruby
    # 定义
    module Week
        PI = 3.141592654
        def Week.sin(x, y)
            puts "sig #{x} #{y}"
        end

        def Week.cos(x)
            puts "cos #{x}"
        end
        FIRST_DAY = "Sunday"
        def Week.weeks_in_month
            puts "You have four weeks in a month"
        end
        def Week.weeks_in_year
            puts "You have 52 weeks in a year"
        end
    end
    # 使用
    require_relative 'Week'
    Week.sin Week::PI/2, "abc"

    # class中使用
    require_relative 'Week'
    class Decade
    include Week
    no_of_yrs=10
        def no_of_months
            puts Week::FIRST_DAY
            number=10*12
            puts number
        end
    end
    d1=Decade.new
    puts Week::FIRST_DAY
    Week.weeks_in_month
    Week.weeks_in_year
    d1.no_of_months
    ```


