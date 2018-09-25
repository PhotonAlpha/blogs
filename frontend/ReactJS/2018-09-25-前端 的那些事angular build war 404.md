## angular build war file 404
由于对于前端`base-href`知识点存在盲点,所以特地写一些知识点总结在这里.

## `缘起`
事情的起因是客户提出需要,需要把`前端静态HTML单独打包到war`,然后跑在JBOSS中.

因为之前后端打包都是在一个spring boot war包中,当时也是迷迷糊糊的就成功了,但是对于现在的需求也是一脸懵逼的.

然后开始疯狂Google,但是总是找不到满意的答案.网上给出的方案大致有三种.

1. 配置Jboss的config实现404重定向功能.
2. Nginx静态代理.(这也是最常用的功能)
3. 前端使用hash路由

由于客户没有Nginx,方案二pass,需要配置Jboss,方案一pass,方案三可行,但是URL又特别丑.个人决定也是pass.

## `转机`
那总要解决吧,于是过了1天,在晚上一次日常锻炼的时候来了灵感,把`静态HTML打到spring boot空包`中那不是OK了吗?只需要使用springMVC即可.于是顺利的打成了war包,在IDEA中运行成功了

## `掉坑`
这时候又出现了另一个问题,war放入Jboss中一直无法加载JS CSS 等文件,遇到了404问题.文件一直无法加载出来.
![404错误](https://photonalpha.github.io/assets/front_end_404.PNG)

这个时候,脑回路打了死结,到底是什么情况,server-context去哪里了?`一直在refresh的解决思路那块在打转`,真想扇自己.

## `曙光`
在一次清晨,梳理了一下问题的症结所在之后,总了出了问题的思路.
* 以下代码只是解决了前端刷新问题,跟JS CSS等问题件加载并没有关系
```python
    @Controller
    public class IndexController {
        /**
        * @return index page
        */
        @RequestMapping({"/welcome", "/main/**", ""})
        public String index() {
            return "forward:/index.html";
        }
    }
```
* 加载不出来,很可能是因为文件使用了绝对路径
```python
<script type="text/javascript" src="runtime.a66f828dca56eeb90e02.js"></script>
<script type="text/javascript" src="polyfills.7a0e6866a34e280f48e7.js"></script>
<script type="text/javascript" src="main.abc26c35802ac9f06695.js"></script></body>
```

### 于是我手动修改成了相对路径,居然成功了!
但是每次自己修改也不能这么做呀,因为上面这段代码是build自定生成的,最后分析原因在于base-href用法写错了, 此处的 /<context-root>/**两个`/`必不可少**!
`ng build --prod --base-href /spring-boot-client/`
这样问题就解决了.关于刷新问题也在上面解决了.