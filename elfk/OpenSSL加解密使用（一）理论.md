# OpenSSL加解密使用  [命令详解参考](https://blog.51cto.com/shjia/1427138)
这篇文章讲述以下几点

- 什么是OpenSSL
- 基本功能
- 密钥、证书的编码格式和后缀名
- 对称加密的基本使用
- 生成公私钥对
- 非对称加密的基本使用

## 1. 什么是OpenSSL
OpenSSL 是一个安全套接字层密码库，囊括主要的密码算法、常用的密钥和证书封装管理功能及SSL协议，并提供丰富的应用程序供测试或其它目的使用。

## 2. 基本功能
openssl是一个开源程序的套件、这个套件有三个部分组成：一是libcryto，这是一个具有通用功能的加密库，里面实现了众多的加密库；二是libssl，这个是实现ssl机制的，它是用于实现TLS/SSL的功能；三是openssl，是个多功能命令行工具，它可以实现加密解密，甚至还可以当CA来用，可以让你创建证书、吊销证书。

为了做个更简单的区分，我分成下面3种，可能你看着会亲切一些

- 加解密库（本章只讨论加解密）
- SSL协议实现
- 一些经过封装，方便你使用加解密和SSL的工具

### ******密钥、证书的编码格式和后缀名**
> 目前有以下两种编码格式.

- **PEM - Privacy Enhanced Mail**  
打开看文本格式,以"-----BEGIN-----"开头, "-----END-----"结尾,内容是Base64编码，查看PEM格式的信息可以用命令  
`openssl rsa -in my.pem -text -noout`  
Unix服务器偏向于使用这种编码格式.  
- **DER - Distinguished Encoding Rules**  
打开看是二进制格式,不可读，查看DER格式的信息可以用命令  
`openssl rsa -in my.der -inform der -text -noout`  
Java和Windows服务器偏向于使用这种编码格式.  
> 我们平时见到的多种后缀名，都是语义化的后缀，在生成密钥的时候，比如我们私钥的后缀名可以写.pem .key，都是可以的，以下几种为常用后缀

- CRT - CRT应该是certificate的三个字母,其实还是证书的意思,常见于Unix系统,有可能是PEM编码,也有可能是DER编码,大多数应该是PEM编码,相信你已经知道怎么辨别.

- CER - 还是certificate,还是证书,常见于Windows系统,同样的,可能是PEM编码,也可能是DER编码,大多数应该是DER编码.

- KEY - 通常用来存放一个公钥或者私钥,并非X.509证书,编码同样的,可能是PEM,也可能是DER.
查看KEY的办法:  
`openssl rsa -in mykey.key -text -noout`  
如果是DER格式的话,同理应该这样了:  
`openssl rsa -in mykey.key -text -noout -inform der`

- CSR - Certificate Signing Request,即证书签名请求,这个并不是证书,而是向权威证书颁发机构获得签名证书的申请,其核心内容是一个公钥(当然还附带了一些别的信息),在生成这个申请的时候,同时也会生成一个私钥,私钥要自己保管好，查看的办法:  
`openssl req -noout -text -in my.csr`  
(如果是DER格式的话照旧加上`-inform der`,这里不写了)

## 3. 常用加解密算法使用
我们重点讨论如何使用

> 1.对称加密

我们需要用到 `openssl enc` 命令，先看下帮助文档

    $ openssl enc -h 

    :<<!
    -in <file>     输入文件
    -out <file>    输出文件
    -pass <arg>    密码
    -S             盐，用于加盐加密，请避免人为输入，下面讨论
    -e             encrypt 加密操作
    -d             decrypt 解密操作
    -a/-base64     base64 encode/decode, depending on encryption flag  是否将结果base64编码
    -k             已被-pass参数取代
    -kfile         已被-pass参数取代
    -md            指定密钥生成的摘要算法 默认MD5
    -K/-iv         加密所需的key和iv向量，由输入的-pass生成
    -[pP]          print the iv/key (then exit if -P)  是否需要在控制台输出生成的 key和iv向量
    -bufsize <n>   读写文件的I/O缓存，一般不需要指定
    -engine e      指定三方加密设备，没有环境，暂不实验

    Cipher Types  以下是部分算法，我们可以选择用哪种算法加密
    -aes-128-cbc               -aes-128-cbc-hmac-sha1     -aes-128-cfb              
    -aes-128-cfb1              -aes-128-cfb8              -aes-128-ctr              
    -aes-128-ecb               -aes-128-gcm               -aes-128-ofb      
    …………
    !
使用，默认从控制台输入密码，如果不指定加密算法，是不会进行加密的，也不会报错，比如我们不指定算法，只指定base64格式输出，就相当于只做了base64编码而已

    /*对文件进行base64编码*/
    openssl enc -base64 -in plain.txt -out base64.txt
    /*对base64格式文件进行解密*/
    openssl enc -base64 -d -in base64.txt -out plain2.txt
    /*使用diff命令查看可知解码前后明文一样*/
    diff plain.txt plain2.txt
不同输入密码的方式

    /*命令行输入，密码123456*/
    openssl enc -aes-128-cbc -in plain.txt -out out.txt -pass pass:123456
    /*文件输入，密码123456*/
    echo 123456 > passwd.txt
    openssl enc -aes-128-cbc -in plain.txt -out out.txt -pass file:passwd.txt
    /*环境变量输入，密码123456*/
    passwd=123456
    export passwd
    openssl enc -aes-128-cbc -in plain.txt -out out.txt -pass env:passwd
    /*从文件描述输入*/ 
    openssl enc -aes-128-cbc -in plain.txt -out out.txt -pass fd:1  
    /*从标准输入输入*/ 
    openssl enc -aes-128-cbc -in plain.txt -out out.txt -pass stdin 
- 对称加密的使用中，虽然我们输入了-pass，指定了密码，但是本质是采用key和iv向量进行加密的，我们输入的-pass，会转换成key和iv
- 为了增强安全性，在把用户密码转换成 key / iv 的时候需要使用盐值，默认盐值随机生成。使用-S参数，则盐值由用户指定。也可指用-nosalt指定不使用盐值，但降低了安全性，不推荐使用。
- 因为本质是采用 key / iv 加密，所以我们可以直接用 key / iv 解密或者加密  

手动指定Key和IV值，指定key / iv 后，-pass参数不起作用

    /*手动指定key和iv值*/
    $ openssl enc -aes-128-cbc -in plain.txt -out encrypt.txt  -K 1223 -iv f123 -p
    salt=0B00000000000000
    key=12230000000000000000000000000000
    iv =F1230000000000000000000000000000
    /*指定pass密码，不起作用，注意Key和IV值是16进制*/
    $ openssl enc -aes-128-cbc -in plain.txt -out encrypt.txt  -K 1223 -iv f123 -p -pass pass:123456
    salt=F502F4B8DE62E0E5
    key=12230000000000000000000000000000
    iv =F1230000000000000000000000000000
> 2.公私钥对的生成（这里演示RSA算法相关）

首先我们需要用到 `openssl genrsa` 命令，先看下帮助文档，这是一个简易的命令，为了方便我们生成自己的私钥

    $ openssl genrsa -h       

    /*
    usage: genrsa [args] [numbits]

    -des           生成的私钥采用DES算法加密
    -des3          生成的私钥采用DES3算法加密 (168 bit key)
    -seed          encrypt PEM output with cbc seed
    -aes128, -aes192, -aes256
                
    以上几个都是对称加密算法的指定，因为我们长期会把私钥加密，避免明文存放

    -out file       私钥输出位置
    -passout arg    输出文件的密码，如果我们指定了对称加密算法，也可以不带此参数，会有命令行提示你输入密码
    */

我们生成一个私钥

    ~ » openssl genrsa -out my.key -des3             

    /*                                                                   
    Generating RSA private key, 512 bit long modulus
    ...++++++++++++
    .++++++++++++
    e is 65537 (0x10001)
    # 因为指定了des3算法，并且没指定密码，所以会要求我输入密码
    Enter pass phrase for my.key:   
    Verifying - Enter pass phrase for my.key:
    ------------------------------------------------------------
    */

    ~ » cat my.key          

    /*                                                                        
    -----BEGIN RSA PRIVATE KEY-----
    Proc-Type: 4,ENCRYPTED
    DEK-Info: DES-EDE3-CBC,21A9C0CD76DFBF27

    i1h8ZmZxOZxDHigtXs0tAIWNs7THoN4t00F4xmYP7gDEU8vwWXltZisUqMJ2KHgZ
    ME70Tm2XvhEAwu3OLhCaV6Url+DJ/G6sMFpnvkebrW51Ndph87ZCRdhaOrXN2WVg
    +/KNRv2dMh4c98zgoJqYiN6qqdY9Sztj0DMtjn2f9k7mU8l2oN5bmlO6dy+mX2ZB
    Qaupx9PV2DZH7Yd5tcKLudCa44lJ9cJscnvIyzLhDHcrGytCsTeHNeVMx9gefd0p
    DzMBruiNhmXSe8a067OT5mWMi7++4WOYYWfIj2bat/pxsBNo0gOxqcuV0G1RFEDA
    uX0vk1ma3+hB01p51bPCjc2HF/nvs2s/YeYgJR/E3zuxQGMvi6G0uxVY10i5xhtb
    mIXi1J5RSoVcj2gMXD3GasGANNG3hdTWC+g6hfq+DczmGl8uR9lXwg==
    -----END RSA PRIVATE KEY-----

    */

我们可以指定私钥长度，命令最后就是指定私钥长度，默认512bit

    openssl genrsa -out my.key -des3 1024

另外我们需要用到 `openssl rsa` 命令，我们会用它生成公钥，先看下帮助文档

    $ openssl rsa -h

    /*
    -inform arg     输入文件编码格式，只有pem和der两种
    -outform arg    输出文件编码格式，只有pem和der两种
    -in arg         input file  输入文件
    -sgckey         Use IIS SGC key format
    -passin arg     如果输入文件被对称加密过，需要指定输入文件的密码
    -out arg        输出文件位置
    -passout arg    如果输出文件也需要被对称加密，需要指定输出文件的密码

    -des            对输出结果采用对称加密 des算法
    -des3           对输出结果采用对称加密 des3算法
    -seed           
    -aes128, -aes192, -aes256

    以上几个都是对称加密算法的指定，生成私钥的时候一般会用到，我们不让私钥明文保存

    -text           以明文形式输出各个参数值
    -noout          不输出密钥到任何文件
    -modulus        输出模数值
    -check          检查输入密钥的正确性和一致性
    -pubin          指定输入文件是公钥
    -pubout         指定输出文件是公钥
    -engine e       指定三方加密库或者硬件
    */
    
我们利用刚才生成的私钥`my.key`，以此生成一个公钥

    ~ » openssl rsa -in my.key -pubout -out my_pub.key     

    /*                                                             
    Enter pass phrase for my.key: # 因为私钥有密码，我们需要输入
    writing RSA key
    ------------------------------------------------------------
    */

    ~ » cat my_pub.key                            

    /*                                                                      
    -----BEGIN PUBLIC KEY-----
    MFwwDQYJKoZIhvcNAQEBBQADSwAwSAJBAN4QWx/qPoOllcE8ZcR5zBzrSVFh7NXY
    4SJHB8+IM3Wv2aYi7F3GlZjpt6EP3vdd4x4cJnuPFnZ5mZ5wFPQ8xD0CAwEAAQ==
    -----END PUBLIC KEY-----
    */

> openssl rsa 命令的功能还有很多

----------------------------------
### 1. rsa 添加 和 去除 密钥的对称加密
    /*生成不加密的RSA密钥*/
    $ openssl genrsa -out RSA.pem

    Generating RSA private key, 512 bit long modulus
    ..............++++++++++++
    .....++++++++++++
    e is 65537 (0x10001)

    /*为RSA密钥增加口令保护*/
    $ openssl rsa -in RSA.pem -des3 -passout pass:123456 -out E_RSA.pem

    /*为RSA密钥去除口令保护*/
    $ openssl rsa -in E_RSA.pem -passin pass:123456 -out P_RSA.pem

    /*比较原始后的RSA密钥和去除口令后的RSA密钥，是一样*/
    $ diff RSA.pem P_RSA.pem

### 2. 修改密钥的保护口令和算法

    /*生成RSA密钥*/
    $ openssl genrsa -des3 -passout pass:123456 -out RSA.pem

    Generating RSA private key, 512 bit long modulus
    ..................++++++++++++
    ......................++++++++++++
    e is 65537 (0x10001)

    /*修改加密算法为aes128，口令是123456*/

    $ openssl rsa -in RSA.pem -passin pass:123456 -aes128 -passout pass:123456 -out E_RSA.pem
### 3. 查看密钥对中的各个参数

    $ openssl rsa -in RSA.pem -des -passin pass:123456 -text -noout

### 4、提取密钥中的公钥并打印模数值

    /*提取公钥，用pubout参数指定输出为公钥*/
    $ openssl rsa -in RSA.pem -passin pass:123456 -pubout -out pub.pem

    /*打印公钥中模数值*/
    $ openssl rsa -in pub.pem -pubin -modulus -noout

    Modulus=C35E0B54041D78466EAE7DE67C1DA4D26575BC1608CE6A199012E11D10ED36E2F7C651D4D8B40D93691D901E2CF4E21687E912B77DCCE069373A7F6585E946EF

### 5. 转换密钥的格式

    /*把pem格式转化成der格式，使用outform指定der格式*/
    $ openssl rsa -in RSA.pem -passin pass:123456 -des -passout pass:123456 -outform der -out rsa.der

    /*把der格式转化成pem格式，使用inform指定der格式*/
    $ openssl rsa -in rsa.der -inform der -passin pass:123456 -out rsa.pem

> 3.利用已有的公私钥对 ，进行非对称加解密

我们这里需要用到 `openssl rsautl` 命令

> 注意：无论是使用公钥加密还是私钥加密，RSA每次能够加密的数据长度不能超过RSA密钥长度，并且根据具体的补齐方式不同输入的加密数据最大长度也不一样，而输出长度则总是跟RSA密钥长度相等。RSA不同的补齐方法对应的输入输入长度如下表

| 数据补齐方式 | 输入数据长度 | 输出数据长度 | 参数字符串 |
| ----------- | ----------- | ----------- | ---------- |
|PKCS#1 v1.5 | 少于(密钥长度-11)字节 | 同密钥长度 | -pkcs |
|PKCS#1 OAEP | 少于(密钥长度-11)字节 | 同密钥长度 | -oaep |
|PKCS#1 for SSLv23 | 少于(密钥长度-11)字节 | 同密钥长度 | -ssl |
|不使用补齐 | 同密钥长度 | 同密钥长度 | -raw |

> 使用rsautl进行加密和解密操作，我们还是先看一下帮助文档

    $ openssl rsautl -h
    Usage: rsautl [options]                  
    -in file        input file                                           //输入文件
    -out file       output file                                          //输出文件
    -inkey file     input key                                            //输入的密钥
    -keyform arg    private key format - default PEM                     //指定密钥格式
    -pubin          input is an RSA public                               //指定输入的是RSA公钥
    -certin         input is a certificate carrying an RSA public key    //指定输入的是证书文件
    -ssl            use SSL v2 padding                                   //使用SSLv23的填充方式
    -raw            use no padding                                       //不进行填充
    -pkcs           use PKCS#1 v1.5 padding (default)                    //使用V1.5的填充方式
    -oaep           use PKCS#1 OAEP                                      //使用OAEP的填充方式
    -sign           sign with private key                                //使用私钥做签名
    -verify         verify with public key                               //使用公钥认证签名
    -encrypt        encrypt with public key                              //使用公钥加密
    -decrypt        decrypt with private key                             //使用私钥解密
    -hexdump        hex dump output                                      //以16进制dump输出
    -engine e       use engine e, possibly a hardware device.            //指定三方库或者硬件设备
    -passin arg    pass phrase source                                    //指定输入的密码

> openssl rsautl 基本的加解密使用

    /*生成RSA密钥*/
    $ openssl genrsa -des3 -passout pass:123456 -out RSA.pem 

    Generating RSA private key, 512 bit long modulus
    ............++++++++++++
    ...++++++++++++
    e is 65537 (0x10001)

    /*提取公钥*/
    $ openssl rsa -in RSA.pem -passin pass:123456 -pubout -out pub.pem 

    /*使用RSA作为密钥进行加密，实际上使用其中的公钥进行加密*/
    $ openssl rsautl -encrypt -in plain.txt -inkey RSA.pem -passin pass:123456 -out enc.txt

    /*使用RSA作为密钥进行解密，实际上使用其中的私钥进行解密*/
    $ openssl rsautl -decrypt -in enc.txt -inkey RSA.pem -passin pass:123456 -out replain.txt

    /*比较原始文件和解密后文件*/
    $ diff plain.txt replain.txt 

    /*使用公钥进行加密*/
    $ openssl rsautl -encrypt -in plain.txt -inkey pub.pem -pubin -out enc1.txt

    /*私钥进行解密*/
    $ openssl rsautl -decrypt -in enc1.txt -inkey RSA.pem -passin pass:123456 -out replain1.txt

    /*比较原始文件和解密后文件*/
    $ diff plain.txt replain1.txt

> 签名与验证操作


    /*提取PCKS8格式的私钥*/
    $ openssl pkcs8 -topk8 -in RSA.pem -passin pass:123456 -out pri.pem -nocrypt

    /*使用RSA密钥进行签名，实际上使用私钥进行加密*/
    $ openssl rsautl -sign -in plain.txt -inkey RSA.pem -passin pass:123456 -out sign.txt

    /*使用RSA密钥进行验证，实际上使用公钥进行解密*/
    $ openssl rsautl -verify -in sign.txt -inkey RSA.pem -passin pass:123456 -out replain.txt

    /*对比原始文件和签名解密后的文件*/
    $ diff plain.txt replain.txt 

    /*使用私钥进行签名*/
    $ openssl rsautl -sign -in plain.txt -inkey pri.pem  -out sign1.txt

    /*使用公钥进行验证*/
    $ openssl rsautl -verify -in sign1.txt -inkey pub.pem -pubin -out replain1.txt

    /*对比原始文件和签名解密后的文件*/
    $ cat plain replain1.txt