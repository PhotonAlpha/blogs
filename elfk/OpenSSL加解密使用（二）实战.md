1. `\elasticsearch-7.7.0\bin` command: `elasticsearch`
2. `\logstash-7.7.0\bin`  command: `logstash -f ../config/logstash-sample.conf`
3. `\filebeat-7.7.0-windows-x86_64` command: `filebeat`
4. `\kibana-7.7.0-windows-x86_64\bin` command: `kibana.bat`



docker run -it -v %cd%:/export frapsoft/openssl

docker run -it -v %cd%:/export frapsoft/openssl req -nodes -new -newkey rsa:2048 -sha256 -out /export/cert.pem

openssl x509 -in /export/cert.pem -noout -text
openssl req -in /export/cert.pem -noout -text


生成CA私钥（.key）-->生成CA证书请求（.csr）-->自签名得到根证书（.crt）（CA给自已颁发的证书）。
# Generate CA private key 
openssl genrsa -out ca.key 2048 

docker run -it -v %cd%:/export frapsoft/openssl genrsa -out /export/ca.key 2048
docker run -it -v %cd%:/export frapsoft/openssl genrsa -out /export/ca-key.pem 1024
# Generate CSR 
openssl req -new -key ca.key -out ca.csr

docker run -it -v %cd%:/export frapsoft/openssl req -new -key /export/ca.key -out /export/ca.csr
# Generate Self Signed certificate（CA 根证书）
openssl x509 -req -days 365 -in ca.csr -signkey ca.key -out ca.crt

docker run -it -v %cd%:/export frapsoft/openssl x509 -req -days 365 -in /export/ca.csr -signkey /export/ca.key -out /export/ca.crt
--------------------------------------------------------------------------------------------------------------
# 生成证书
## 一.  生成CA证书 
目前不使用第三方权威机构的CA来认证，自己充当CA的角色。  
1. 创建私钥 ： 
docker run -it -v %cd%:/export frapsoft/openssl genrsa -out /export/ca-key.key 1024  

docker run -it -v %cd%:/export frapsoft/openssl genrsa -des3 -out /export/ca-key.key 1024  
        密码为: ca-changeit

2. 创建证书请求 ： 
docker run -it -v %cd%:/export frapsoft/openssl req -new -out /export/ca-req.csr -key /export/ca-key.key    

        Country Name (2 letter code) [AU]:CN 
        State or Province Name (full name) [Some-State]:jiangsu 
        Locality Name (eg, city) []:suzhou 
        Organization Name (eg, company) [Internet Widgits Pty Ltd]: EthanCreed 
        Organizational Unit Name (eg, section) []: ethan 
        Common Name (eg, YOUR name) []:  creed.jetz.com    // 在YOUR name 处一定要填写项目布置服务器所属域名或ip地址。
        Email Address []: ca@gmail.com 
        
        Please enter the following 'extra' attributes to be sent with your certificate request  //加密证书请求的密码
        A challenge password []:password
        An optional company name []:ethan-co

3. 自签署证书 ： 
docker run -it -v %cd%:/export frapsoft/openssl x509 -req -in /export/ca-req.csr -out /export/ca-cert.pem -signkey /export/ca-key.key -days 3650 

4. 将证书导出成浏览器支持的.p12格式 ： 
docker run -it -v %cd%:/export frapsoft/openssl pkcs12 -export -clcerts -in /export/ca-cert.pem -inkey /export/ca-key.key -out /export/ca.p12  
密码：changeit    

## 二.  创建服务端证书
1. 创建私钥 ： 
docker run -it -v %cd%:/export frapsoft/openssl genrsa -out /export/server-key.key 1024  

docker run -it -v %cd%:/export frapsoft/openssl genrsa -des3 -out /export/server-key.key 1024  
        密码为: server-changeit

2. 创建证书请求 ： 
docker run -it -v %cd%:/export frapsoft/openssl req -new -out /export/server-req.csr -key /export/server-key.key  

        Country Name (2 letter code) [AU]:CN 
        State or Province Name (full name) [Some-State]:jiangsu 
        Locality Name (eg, city) []:suzhou 
        Organization Name (eg, company) [Internet Widgits Pty Ltd]: EthanCreed 
        Organizational Unit Name (eg, section) []:ethan 
        Common Name (eg, YOUR name) []: creed.jetz.com   注释：在名字和姓氏处填写项目布置服务器所属域名或ip地址 一定要写服务器所在的ip地址 
        Email Address []: ca@gmail.com  

        Please enter the following 'extra' attributes to be sent with your certificate request
        A challenge password []:password
        An optional company name []:ethan-co.

3. 自签署证书 ： 
docker run -it -v %cd%:/export frapsoft/openssl rsa -in /export/server-key.key -text -noout

docker run -it -v %cd%:/export frapsoft/openssl x509 -req -in /export/server-req.csr -out /export/server-cert.pem -signkey /export/server-key.key -CA /export/ca-cert.pem -CAkey /export/ca-key.key -CAcreateserial -days 3650  

4. 将证书导出成浏览器支持的.p12格式 ： 
docker run -it -v %cd%:/export frapsoft/openssl pkcs12 -export -clcerts -in /export/server-cert.pem -inkey /export/server-key.key -out /export/server.p12  
密码：changeit 

## 三. 创建客户端证书  
1. 创建私钥 ： 
docker run -it -v %cd%:/export frapsoft/openssl genrsa -des3 -out /export/client-key.key 1024
        密码为: cli-changeit

2.创建证书请求 ： 
docker run -it -v %cd%:/export frapsoft/openssl req -new -out /export/client-req.csr -key /export/client-key.key 

        Country Name (2 letter code) [AU]:CN 
        State or Province Name (full name) [Some-State]:jiangsu 
        Locality Name (eg, city) []:suzhou 
        Organization Name (eg, company) [Internet Widgits Pty Ltd]:EthanCreed 
        Organizational Unit Name (eg, section) []:ethan 
        Common Name (eg, YOUR name) []: cli 
        Email Address []: ca@gmail.com 

        Please enter the following 'extra' attributes 
        to be sent with your certificate request 
        A challenge password []:password 
        An optional company name []:ethan-co.  

3. 自签署证书 ： 
docker run -it -v %cd%:/export frapsoft/openssl x509 -req -in /export/client-req.csr -out /export/client-cert.pem -signkey /export/client-key.key -CA /export/ca-cert.pem -CAkey /export/ca-key.key -CAcreateserial -days 3650  

4. 将证书导出成浏览器支持的.p12格式 ： 
docker run -it -v %cd%:/export frapsoft/openssl pkcs12 -export -clcerts -in /export/client-cert.pem -inkey /export/client-key.key -out /export/client.p12  
密码： changeit    

## 四：Java项目使用

1 服务端使用

trustStore使用root.p12，keyStroe使用server.p12

同时设置：

        sslEngine.setUseClientMode(false);
        sslEngine.setNeedClientAuth(true);//启动对客户端证书的校验


2 客户端使用

trustStore使用root.p12,keyStore使用client.p12
        sslEngine.setUseClientMode(true);



说明: 根证书作为CA,用来验证对方发送的签名是否正确。如果不对签名进行验证，则不需要根证书放到trustStore中.


参考： [实现web项目的ssl双向认证客户端证书代码生成](https://www.cnblogs.com/zhangshitong/p/9015482.html)

--------------web 项目的ssl双向认证客户端证书代码生成----------------------------------------
# 1. 使用openssl生成ca证书和服务端证书，当然也可以通过代码实现

1）创建CA私钥,创建目录ca
docker run -it -v %cd%:/export frapsoft/openssl genrsa -out /export/ca-key.pem 1024

2）创建证书请求
docker run -it -v %cd%:/export frapsoft/openssl req -new -out /export/ca-req.csr -key /export/ca-key.pem
    Country Name (2 letter code) [AU]:CN
    State or Province Name (full name) [Some-State]:jiangsu
    Locality Name (eg, city) []:suzhou
    Organization Name (eg, company) [Internet Widgits Pty Ltd]:EthanCreed
    Organizational Unit Name (eg, section) []:ethan
    Common Name (e.g. server FQDN or YOUR name) []:creed.jetz.com
    Email Address []:ca@gmail.com

    Please enter the following 'extra' attributes
    to be sent with your certificate request
    A challenge password []:password
    An optional company name []:ethan-co

    修改配置参数
    docker run -it -v %cd%:/export frapsoft/openssl req -new -out ca/ca-req.csr -keyca/ca-key.pem -config openssl.cnf 

在YOUR name 处一定要填写项目布置服务器所属域名或ip地址。

3）自签署证书
docker run -it -v %cd%:/export frapsoft/openssl x509 -req -in /export/ca-req.csr -out /export/ca-cert.pem -signkey /export/ca-key.pem -days 3650

4）导出ca证书
docker run -it -v %cd%:/export frapsoft/openssl pkcs12 -export -clcerts -in /export/ca-cert.pem -inkey /export/ca-key.pem -out /export/ca.p12

只导出 ca证书，不导出ca的秘钥
docker run -it -v %cd%:/export frapsoft/openssl pkcs12 -export -nokeys -cacerts -in /export/ca-cert.pem -inkey /export/ca-key.pem -out /export/ca1.p12


# 2. 注册服务端证书
1）创建服务端密钥库，别名为server，validity有效期为365天，密钥算法为RSA， storepass密钥库密码，keypass别名条码密码。
keytool -genkey -alias server -validity 3650 -keyalg RSA -keysize 1024 -keypass 123456 -storepass 123456 -dname "CN=CN,OU=ethan,O=EthanCreed,L=suzhou,S=jiangsu,C=creed.jetz.com" -keystore server.jks 

在名字和姓氏处填写项目布置服务器所属域名或ip地址。

2）生成服务端证书
keytool -certreq -alias server -sigalg MD5withRSA -file server.csr -keypass 123456 -keystore server.jks -storepass 123456

3）使用CA的密钥生成服务端密钥，使用CA签证
docker run -it -v %cd%:/export frapsoft/openssl x509 -req -in /export/server.csr -out /export/server.pem -CA /export/ca-cert.pem -CAkey /export/ca-key.pem -days 3650 -set_serial 1

4）使密钥库信任证书
keytool -import -v -trustcacerts -keypass 123456 -storepass 123456 -alias root -file ca-cert.pem -keystore server.jks

5）将证书回复安装在密钥库中
keytool -import -v -trustcacerts -storepass 123456 -alias server -file server.pem -keystore server.jks

6）生成服务端servertrust.jks信任库
keytool -import -alias server-ca-trustcacerts -file ca-cert.pem -keystore servertrust.jks



# 3. 注册客户端证书
1）创建客户端密钥，指定用户名，下列命令中的user将替换为颁发证书的用户名

docker run -it -v %cd%:/export frapsoft/openssl genrsa -out /export/user-key.pem 1024

2）
docker run -it -v %cd%:/export frapsoft/openssl req -new -out /export/user-req.csr -key /export/user-key.pem

        Country Name (2 letter code) [AU]:CN 
        State or Province Name (full name) [Some-State]:jiangsu 
        Locality Name (eg, city) []:suzhou 
        Organization Name (eg, company) [Internet Widgits Pty Ltd]: EthanCreed 
        Organizational Unit Name (eg, section) []: ethan 
        Common Name (eg, YOUR name) []:  creed.jetz.com    // 在YOUR name 处一定要填写项目布置服务器所属域名或ip地址。
        Email Address []: ca@gmail.com
                
        Please enter the following 'extra' attributes to be sent with your certificate request  //加密证书请求的密码
        A challenge password []:password
        An optional company name []:ethan-co

3）生成对应用户名的客户端证书，并使用CA签证

docker run -it -v %cd%:/export frapsoft/openssl x509 -req -in /export/user-req.csr -out /export/user-cert.pem -signkey /export/user-key.pem -CA /export/ca-cert.pem -CAkey /export/ca-key.pem -CAcreateserial -days 3650



4）将签证之后的证书文件user-cert.pem导出为p12格式文件（p12格式可以被浏览器识别并安装到证书库中）

docker run -it -v %cd%:/export frapsoft/openssl pkcs12 -export -clcerts -in /export/user-cert.pem -inkey /export/user-key.pem -out /export/user.p12 

5）将签证之后的证书文件user-cert.pem导入至信任秘钥库中（这里由于没有去ca认证中心购买个人证书，所以只有导入信任库才可进行双向ssl交互

keytool -import -alias user -trustcacerts -file user-cert.pem -keystore servertrust.jks

6）
keytool -list -v -alias user -keystore servertrust.jks -storepass 123456

3.配置web容器（tomcat或weblogic）tomcat conf 文件夹下的server.xml

关于X.509不同的数字证书所包含的内容信息和格式可能不尽相同，因此，需要一种格式标准来规范数字证书的存储和校验，大多数数字证书都以一种标准的格式（即X.509）来存储他们的信息，X.509

提供了一种标准的方式，将证书信息规范地存储到一系列可解析的字段中，X.509 V3 是X.509标准中目前使用最为广泛的版本