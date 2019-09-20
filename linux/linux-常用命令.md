# 查看Linux版本
1. cat /etc/redhat-release
2. cat /proc/version

# 查看端口访问情况
1. 先用telnet连接不存在的端口
    telnet 10.0.250.3 80
    Trying 10.0.250.3...
    telnet: connect to address 10.0.250.3: Connection refused #直接提示连接被拒绝
2.  wget是linux下的下载工具，需要先安装.
    用法: wget ip:port

# MAC 查看
 3. nc -zv 47.96.253.192 8081   