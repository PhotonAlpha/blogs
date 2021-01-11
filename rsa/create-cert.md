docker run -it -v C:/Users/Ethan/Desktop/tmp/rsa:/export frapsoft/openssl genrsa -out /export/ca-key.key 1024 

docker run -it -v C:/Users/Ethan/Desktop/tmp/rsa:/export frapsoft/openssl genrsa -des3 -out /export/ca-key.key 1024  
changeit

# 创建证书
docker run -it -v C:/Users/Ethan/Desktop/tmp/rsa:/export frapsoft/openssl req -subj "/C=CN/ST=Jiangsu/L=suzhou/O=AAA/OU=ethan/CN=creed.jetz.com/emailAddress=ca@gmail.com" -new -out /export/ca-req.csr -key /export/ca-key.key

# 自定义签名证书
docker run -it -v C:/Users/Ethan/Desktop/tmp/rsa:/export frapsoft/openssl x509 -req -in /export/ca-req.csr -out /export/ca-cert.pem -signkey /export/ca-key.key -days 3650

# 导出浏览器支持的格式
docker run -it -v C:/Users/Ethan/Desktop/tmp/rsa:/export frapsoft/openssl pkcs12 -export -clcerts -in /export/ca-cert.pem -inkey /export/ca-key.key -out /export/ca.p12

创建服务端RSA
docker run -it -v C:/Users/Ethan/Desktop/tmp/rsa:/export frapsoft/openssl genrsa -out /export/server-key.key 1024
docker run -it -v C:/Users/Ethan/Desktop/tmp/rsa:/export frapsoft/openssl req -subj "/C=CN/ST=Jiangsu/L=suzhou/O=AAA/OU=ethan/CN=creed.jetz.com/emailAddress=ca@gmail.com" -new -out /export/server-req.csr -key /export/server-key.key  
docker run -it -v C:/Users/Ethan/Desktop/tmp/rsa:/export frapsoft/openssl x509 -req -in /export/server-req.csr -out /export/server-cert.pem -signkey /export/server-key.key -CA /export/ca-cert.pem -CAkey /export/ca-key.key -CAcreateserial -days 3650 
docker run -it -v C:/Users/Ethan/Desktop/tmp/rsa:/export frapsoft/openssl pkcs12 -export -clcerts -in /export/server-cert.pem -inkey /export/server-key.key -out /export/server.p12 

-----------------------------
生成私钥
docker run -it -v C:/Users/Ethan/Desktop/tmp/rsa:/export frapsoft/openssl genrsa -out /export/rsa_private_key.pem 1024

私钥生成公钥
docker run -it -v C:/Users/Ethan/Desktop/tmp/rsa:/export frapsoft/openssl rsa -in /export/rsa_private_key.pem -out /export/rsa_public_key.pem -pubout

此时的私钥还不能直接被java使用（但可以被openssl使用），需要进行PKCS#8编码
docker run -it -v C:/Users/Ethan/Desktop/tmp/rsa:/export frapsoft/openssl pkcs8 -topk8 -in /export/rsa_private_key.pem -out /export/pkcs8_rsa_private_key.pem -nocrypt

openssl生成签名文件：因为java端签名验证使用sha1算法做摘要。故openssl使用sha1签名
docker run -it -v C:/Users/Ethan/Desktop/tmp/rsa:/export frapsoft/openssl sha1 -sign /export/rsa_private_key.pem -out /export/rsasign.bin /export/tos.txt


# Generate private key with pkcs8 encoding
docker run -it -v C:/Users/Ethan/Desktop/tmp/rsa:/export frapsoft/openssl genpkey -out /export/private_key_rsa_4096_pkcs8-generated.pem -algorithm RSA -pkeyopt rsa_keygen_bits:4096
# Export public key in pkcs8 format
docker run -it -v C:/Users/Ethan/Desktop/tmp/rsa:/export frapsoft/openssl rsa -pubout -outform pem -in /export/private_key_rsa_4096_pkcs8-generated.pem -out /export/public_key_rsa_4096_pkcs8-exported.pem


docker run -it -v C:/Users/Ethan/Desktop/tmp/rsa:/export frapsoft/openssl rsa -in /export/server-key.key -text -noout