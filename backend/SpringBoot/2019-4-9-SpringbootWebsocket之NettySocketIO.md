# netty-socketio
socket.io是一个netty.socket node版的java实现版，其性能优于webSocket等socket技术，socket.io有nameSpace等，分区方式，比较灵活。

# 1. 服务端实现
## Ⅰ 依赖引入
```maven 
<!-- https://mvnrepository.com/artifact/com.corundumstudio.socketio/netty-socketio -->
<dependency>
    <groupId>com.corundumstudio.socketio</groupId>
    <artifactId>netty-socketio</artifactId>
    <version>1.7.17</version>
</dependency>
```
## Ⅱ properties
```
wss:
  server:
    port: 8081
    host: 0.0.0.0
```
***serverHost请使用ip, 如果与spring boot 集成，并部署到server，使用`0.0.0.0`.*** [参考issues](https://github.com/mrniko/netty-socketio/wiki/Using-netty-socketio-server-in-AWS)

## Ⅲ annotation config

socketRunner，在springboot启动项目的时候，启动socket服务
```java
@Component
public class SocketRunner implements CommandLineRunner {
    @Autowired
    private SocketIOServer socketIOServer;

    @Override
    public void run(String... args) {
        socketIOServer.start();
    }
}
```
开启配置
```java
@Configuration
public class SocketIoConfig {
    @Value("${wss.server.host}")
    private String host;
    @Value("${wss.server.port}")
    private Integer port;

    @Bean
    public SocketIOServer socketIOServer() {
        com.corundumstudio.socketio.Configuration config = new com.corundumstudio.socketio.Configuration();
        config.setHostname(host);
        config.setPort(port);
        // config.setOrigin("*"); // 为了解决CORS问题，public class CORSFilter implements Filter 实现 filter 
        config.setUpgradeTimeout(10000);
        config.setPingInterval(60000);
        config.setPingTimeout(30000);

        // 务必配置，否则会无法启动，端口被占用异常
        SocketConfig sockConfig = new SocketConfig();
        sockConfig.setReuseAddress(true);
        config.setSocketConfig(sockConfig);

        config.setExceptionListener(new ExceptionListener() {
            @Override
            public void onEventException(Exception e, List<Object> list, SocketIOClient client) {
                log.error("{}，服务器异常:{}，传入数据:{}", client.getRemoteAddress(), e, list);
                Packet packet = new HeartBeatResponsePacket();
                packet.setSuccess(false);
                packet.setMessage("数据异常");
                client.sendEvent(CommonConstant.NOTIFICATION_DESTINATION, Utils.packetToString(packet));
            }

            @Override
            public void onDisconnectException(Exception e, SocketIOClient client) {
                log.error("{}，断开异常:{}",client.getRemoteAddress(), e);
                Packet packet = new HeartBeatResponsePacket();
                packet.setSuccess(false);
                packet.setMessage("断开异常");
                client.sendEvent(CommonConstant.NOTIFICATION_DESTINATION,Utils.packetToString(packet));
            }

            @Override
            public void onConnectException(Exception e, SocketIOClient client) {
                log.error("{}，连接异常:{}", client.getRemoteAddress(), e);
                Packet packet = new HeartBeatResponsePacket();
                packet.setSuccess(false);
                packet.setMessage("连接异常！");
                client.sendEvent(CommonConstant.NOTIFICATION_DESTINATION,Utils.packetToString(packet));
            }

            @Override
            public void onPingException(Exception e, SocketIOClient client) {
                log.error("{}，ping超时异常:{}", client.getRemoteAddress(), e);
                Packet packet = new HeartBeatResponsePacket();
                packet.setSuccess(false);
                packet.setMessage("ping超时异常！");
                client.sendEvent(CommonConstant.NOTIFICATION_DESTINATION,Utils.packetToString(packet));
            }

            @Override
            public boolean exceptionCaught(ChannelHandlerContext channelHandlerContext, Throwable throwable) {
                return false;
            }
        });

        // 握手协议参数使用JWT的Token认证方案
        config.setAuthorizationListener(data -> {
            boolean success = false;
            String token = data.getSingleUrlParam(CommonConstant.TOKEN);
            if (StringUtils.isNotEmpty(token)) {
                try {
                    String username = jwtTokenUtil.getUsernameFromToken(token);
                    if (StringUtils.isNotEmpty(username)) {
                        success = true;
                    }
                } catch (Exception e) {
                    log.error("token error {}", e.getMessage());
                    success = false;
                } finally {
                    if (!success) {
                        success = false;
                    }
                }
            }
            return success;
        });

        final SocketIOServer server = new SocketIOServer(config);
        return server;
    }

    @Bean
    public SpringAnnotationScanner springAnnotationScanner(SocketIOServer socketIOServer) {
        return new SpringAnnotationScanner(socketIOServer);
    }
}
```
处理请求
```java
@Service
@Slf4j
public class MessageEventHandler {
    @Autowired
    private SocketIOServer server;

    /**定义发送超时时间60s*/
    private int timeOut= 60;

    @PreDestroy
    public void close() {
        server.stop();
    }

    @OnConnect
    public void onConnect(SocketIOClient client) {
        String token = client.getHandshakeData().getSingleUrlParam(CommonConstant.TOKEN);
        String userName = jwtTokenUtil.getUsernameFromToken(token);
        log.info("online users{} ,current user：{}", Register.CLIENT_MAP.keySet(), userName);

        Packet packet = new HeartBeatResponsePacket();

        if (!Register.CLIENT_MAP.containsKey(userName)) {
            log.info("connect success");
            Register.CLIENT_MAP.put(userName, client);
            packet.setSuccess(true);
            packet.setMessage("200");
            client.sendEvent(CommonConstant.NOTIFICATION_DESTINATION, Utils.packetToString(packet));
        } else {
            log.info("connect failure, already login");
            packet.setSuccess(false);
            packet.setMessage("405");
            client.sendEvent(CommonConstant.NOTIFICATION_DESTINATION, Utils.packetToString(packet));
            client.disconnect();
        }

    }

    @OnDisconnect
    public void onDisconnect(SocketIOClient client) {
        String token = client.getHandshakeData().getSingleUrlParam(CommonConstant.TOKEN);
        String userName = jwtTokenUtil.getUsernameFromToken(token);
        log.info("logout：{}", userName);
        if (Register.CLIENT_MAP.containsKey(userName)) {
            Register.CLIENT_MAP.remove(userName);
            client.disconnect();
        } else {
            log.error("{} login time out!", userName);
        }
    }
    //自定义事件
    @OnEvent(CommonConstant.NOTIFICATION_DESTINATION)
    public void notification(SocketIOClient client, AckRequest ackRequest, String message) throws IOException, ClassNotFoundException {
        int hasSend = 0;
        final Packet packet = Utils.getPacket(message);

        String token = client.getHandshakeData().getSingleUrlParam(CommonConstant.TOKEN);
        String userName = jwtTokenUtil.getUsernameFromToken(token);
        log.info("from {} text {} ", userName, packet);
        int resCode = 200;
        if (client.getSessionId().toString().equals(Register.CLIENT_MAP.get(userName).getSessionId().toString())) {
            // applicationService.handleRequest(packet, client);
            log.info("received packet:{}", packet);
        } else {
            log.info("illegal operate，not the login users. ");
            resCode = 401;
        }
        // 客户端的回调函数，用于判断是否消息发送成功（传回给发送方）
        if (ackRequest.isAckRequested() && hasSend ==0) {
            ackRequest.sendAckData(resCode);
        }
    }
}
```

## Ⅳ java 客户端访问
```maven
<dependency>
    <groupId>io.socket</groupId>
    <artifactId>socket.io-client</artifactId>
    <version>1.0.0</version>
</dependency>

<dependency>
    <groupId>io.socket</groupId>
    <artifactId>engine.io-client</artifactId>
    <version>1.0.0</version>
</dependency>
```
```java
public class SocketClientTest {
    public static void main(String[] args) throws URISyntaxException {
        // https://blog.csdn.net/javacodekit/article/details/81416107

        IO.Options options = new IO.Options();
        options.transports = new String[]{"websocket"};
        options.reconnectionAttempts = 2;
        options.reconnectionDelay = 1000; //失败重连的时间间隔
        options.timeout = 2000; //连接超时时间(ms)
        options.query = "token=eyJhbGciOiJIUzUxMiJ9";
        final Socket socket = IO.socket("http://localhost:8081/", options);

        socket.connect();

        socket.on(Socket.EVENT_CONNECT, new Emitter.Listener() {
            @Override
            public void call(Object... args) {
                System.out.println("main::");
                socket.send("hello");
            }
        });

        socket.on(Socket.EVENT_DISCONNECT, new Emitter.Listener() {
            @Override
            public void call(Object... args) {
                System.out.println("连接关闭");
            }
        });

        //customer evenr
        socket.on("reply", new Emitter.Listener() {
            @Override
            public void call(Object... objects) {
                System.out.println("receive borcast data:" + objects[0].toString());
            }
        });
        socket.on(Socket.EVENT_CONNECT_ERROR, new Emitter.Listener() {
            @Override
            public void call(Object... args) {
                System.out.println(args);
            }
        });

        socket.on(Socket.EVENT_MESSAGE, new Emitter.Listener() {
            @Override
            public void call(Object... args) {
                System.out.println("sessionId:" + socket.id());
                for (Object obj : args) {
                    System.out.println(obj);
                }
                System.out.println("收到服务器应答，将要断开连接...");
                socket.disconnect();
            }
        });

        while (true){
            System.out.print("Script:");
            Scanner in=new Scanner(System.in);
            String command=in.nextLine();
            System.out.println(command);
            socket.emit("reply", command);
            try {
                Thread.sleep(2000);
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        }
    }
}
```