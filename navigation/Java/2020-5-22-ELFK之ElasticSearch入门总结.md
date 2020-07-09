# Elastic集群搭建（3节点）

[7.0集群配置新特性](https://www.jianshu.com/p/57831f716422)

[官网地址](https://www.elastic.co/guide/en/elasticsearch/reference/current/discovery-settings.html)

# 〇 概念
 基于Elasticsearch衍生出来了一系列开源软件，统称为Elastic Stack ， 主要包括分布式搜索引擎Elasticsearch 、日志采集与解析工具Logstash 、可视化分析平台Kibana 、数据来集工具Beats 家族等。在没有引入Beats 之前， Elasticsearch 、Logstash 、Kibana 三者简称ELK Stack,是非常流行的集中式日志解决方案。Logstash 既可以作为日志搜集器又能解析日志， 但是Logstash 会消耗较多的CPU 和内存资源，容易造成服务器性能下降。后来Elastic公司推出了Beats家族，在数据收集方面使用Beats取代Logstash ，解决了Logstash 在各服务器节点上占用系统资源高的问题。相比Logstash, Beats 所占系统的CPU 和内存几乎可以忽略不计，另外，Beats 和Logstash 之间支持SSL/TLS 加密传输以及客户端和服务器双向认证，保证了通信安全。Beats 家族的5 个成员简介如下：
- File beat 轻量级的日志采集器，可用于收集文件数据。
- Metricbeat 5.0 版本之前名为Top beat ，搜集系统、进程和文件系统级别的CPU 和内存使
- Packetbeat 收集网络流数据，可以实时监控系统应用和服务，可以将延迟时间、错误、响应时间、SLA 性能等信息发送到Logstash 或Elasticsearch 。
- Winlogbeat 搜集Windows 事件日志数据。
- Heartbeat 监控服务器运行状态。  

## 1. 集群

一个或多个安装 Elasticsearch 的服务器节点组织在一起就是集群，它们共同持有你整个的
数据，并一起提供索引和搜索功能。一个集群由一个唯一的名字标识，称为cluster name ，集
群名称默认是"elasticsearch"。集群名称非常重要，就像一个组织的名称，具有相同集群名
称的节点才会组成一个集群。集群名称可以在配置文件中指定。

## 2. 节点

一个节点是你集群中的一个服务器， 作为集群的一部分，它存储你的数据，参与集群的
索引和搜索功能。

一个节点可以通过配置集群名称的方式来加入一个指定的集群。默认情况下，每个节点
都会被安排加入到一个集群名称为"elasticsearch"的集群中，这意味着如果你在你的网络中
启动了若干个节点， 井假定它们能够相互发现彼此， 它们将会自动地形成并加入到一个叫做
"elasticsearch"的集群中。但是有的时候这种机制并不可靠，会发生脑裂现象，往往不如在
每一个节点上配置节点的名字在启动时进行被动发现来的安全稳定。

## 3. 索引

一个索引就是一个拥有几分相似特征的文档的集合，索引的数据结构仍然是倒排索引。
比如说，你可以有一个客户数据的索引，另一个产品目录的索引， 还有一个订单数据的索引。
一个索引由一个名字来标识（必须全部是小写字母的〉，并且当我们要对这个索引中的文档进
行索引、搜索、更新和删除的时候， 都要使用到这个名字。在一个集群中，可以定义任意多的
索引。索引做动词来讲的时候表示索引数据和对数据进行索引操作。

## 4. 类型(重要)

在ElasticSearch 7.0之前所有发布的版本中，每个文档存储在单独的映射类型里面。一个映射类型被代表了一个文档的类型或者实体索引。

在 ElasticSearch 7.0之后映射类型被移除了。最重要的是同一个索引中共同字段比较少或者没有，那么会导致数据太稀疏，这会影响Lucene有效压缩文档的能力，导致你的搜索很慢。es官方决定删除映射type这个概念。

替换方案有
* 自定义类型属性
```
PUT twitter
{
  "mappings": {
    "_doc": {
      "properties": {
        "type": { "type": "keyword" }, 
        "name": { "type": "text" },
        "user_name": { "type": "keyword" },
        "email": { "type": "keyword" },
        "content": { "type": "text" },
        "tweeted_at": { "type": "date" }
      }
    }
  }
}

PUT twitter/_doc/user-kimchy
{
  "type": "user", 
  "name": "Shay Banon",
  "user_name": "kimchy",
  "email": "shay@kimchy.com"
}

PUT twitter/_doc/tweet-1
{
  "type": "tweet", 
  "user_name": "kimchy",
  "tweeted_at": "2017-10-24T09:00:00Z",
  "content": "Types are going away"
}

GET twitter/_search
{
  "query": {
    "bool": {
      "must": {
        "match": {
          "user_name": "kimchy"
        }
      },
      "filter": {
        "match": {
          "type": "tweet" 
        }
      }
    }
  }
}
```

## 5. 文档
一个文档是一个可被索引的基础信息单元。比如，你可以拥有某一个客户的文档，某一
个产品的一个文档。当然，也可以拥有某个订单的一个文档。文档都是JSON 格式。

## 6. 分片(shards)
一个索引可以存储超出单个节点硬件限制的大量数据。比如， 一个具有10 亿文档的索引占据lTB 的磁盘空间，而任一节点都没有这样大的磁盘空间; 或者单个节点处理搜索请求，响应慢。为了解决这个问题， Elasticsearch 提供了将索引划分成多份的能力，这些份就叫作分片。当你创建一个索引的时候，可以指定想要的分片的数量，每个分片本身也是一个功能完善井且独立的“索引”，这个“索引”可以被放置到集群中的任何节点上。  
分片之所以重要，主要有以下两方面的原因：  
(1) 允许你水平分割／扩展你的内容容量。  
(2) 允许你在分片 (潜在地，位于多个节点上) 上进行分布式的、并行的操作，进而提
高性能和吞吐量，至于一个分片怎样分布，它的文档怎样聚合回搜索请求，完全由Elasticsearch管理， 对于用户来说，这些都是透明的。

## 7. 副本(replicas)
在一个网络／云的环境里， 失败随时都可能发生，在某个分片／节点不知怎么的就处于离线状态， 或者由于某种原因消失了，这种情况下，有一个故障转移机制非常有用，并且也是强烈推荐的。为此， Elasticsearch 允许你创建分片的一份或多份拷贝，这些拷贝叫作复制分片，或者直接叫副本。  
副本之所以重要，有以下两个主要原因：  
(1) 在分片／节点失败的情况下，保证高可用性。因为这个原因，复制分片不与主分片置
于同一节点上，这一点非常重要。  
(2) 扩展你的搜索量／吞吐量，因为搜索可以在所有的副本上并行运行。

**总之，每个索引可以被分成多个分片。一个索引可以有一至多个副本。一旦有了副本，每个索引就有了主分片（作为复制源的原来的分片）和副本分片（主分片的拷贝）之别。分片和副本的数量可以在索引创建的时候指定。在索引创建之后，可以在任何时候动态地改变副本的数量，但是事后不能改变分片的数量。**

---------------------------------------------------
----------------------------------------------------

# ① 索引管理  

1. Elasticsearch 索引名称中不能出现大写字母,否则会出现400错误

```
新增索引
PUT blog

响应：
{
  "acknowledged" : true,
  "shards_acknowledged" : true,
  "index" : "blog"
}

```
2. Elasticsearch 默认给一个索引设置5个分片1个副本，**一个索引的分片数一经指定后就不能再修改，副本数可以通过命令随时修改**。如果想创建自定义分片数和副本数的索引，可以通过`setting`参数在索引时设置初始化信息。以创建3 个分片0 个副本名为blog 的索引为例：

```
//创建索引并设置分片以及副本
PUT blog
{
  "settings": {
    "number_of_shards": 3, 
    "number_of_replicas": 0
  }
}
//更新副本
PUT blog/_settings
{
  "number_of_replicas": 1
}

//查询索引setting设置
GET blog/_settings
//查询多个索引setting设置
GET blog,twitter/ settings
```
3. 除了设置分片和副本，还可以对索引的读写操作进行限制，下面是三个读写权限的参数：

    * `blocks.read_only: true` 设置当前索引只允许读不允许写或者更新。
    * `blocks.read: true` 禁止对当前索引进行读操作。
    * `blocks.write: true` 禁止对当前索引进行写操作。

4. Elasticsearch 中的索引可以进行打开和关闭操作， 一个关闭了的索引几乎不占用系统资源.关闭一个索引的命令如下

```
//索引关闭
POST blog/_close
//索引打开
POST blog/_open
```

5. 复制索引

reindex API 可以把文档从一个索引（源索引）复制到另一个索引（目标索引）， 目标索引
不会复制源索引中的配置信息， **reindex 操作之前需要设置目标索引的分片数、副本数等信息**。
```
POST _reindex
{
  "source": {"index": "blog"},
  "dest": {"index": "blog_new"}
}
```

6. 收缩索引

一个索引的分片初始化以后是无法再做修改的，但可以使用shrink index AP 提供的缩小索引分片数机制，把一个索引变成一个更少分片的索引，但是**收缩后的分片数必须是原始分片数的因子**，比如有8 个分片的索引可以收缩为4\2\1 ，有15 个分片的索引可以收缩为5\3\l ，如果**分片数为素数（ 7, 11 等），那么只能收缩为1个分片**。收缩索引之前，索引中的每
个分片都要在同一个节点上。收缩索引的完成过程如下：
 - 首先，创建一个新的目标索引，设置与源索引相同，但新索引的分片数量较少。
 - 然后，把源索引硬链接到目标索引。（如果文件系统不支持硬链接，那么所有段都被复制到新索引中，这是一个耗费更多时间的过程。）
 - 最后，新的索引恢复使用。

在缩小索引之前，索引必须被标记为只读，所有分片都会复制到一个相同的节点并且节
点健康值为绿色的。这两个条件可以通过下列请求实现，以收缩blog 索引为例，命令如下：
```
//设置只读模式
PUT blog_new/_settings
{
  "settings": {
    "index.routing.allocation.require._name": "shrink_node_name", 
    "index.blocks.write": true 
  }
}
//开始压缩
POST blog_new/_shrink/blog_compression
{
  "settings": {
    "index.routing.allocation.require._name": null, 
    "index.blocks.write": null,
    "index.number_of_replicas": 0,
    "index.number_of_shards": 1, 
    "index.codec": "best_compression"
  }
}

//取消只读模式
PUT blog_new/_settings
{
  "settings": {
    "index.routing.allocation.require._name": null, 
    "index.blocks.write": null 
  }
}

```
7. 索引别名

索引别名就是给一个索引或者多个索引起的另一个名字
```
//创建匿名
POST _aliases
{
  "actions": [
    {
      "add": {
        "index": "blog",
        "alias": "blog_alias"
      }
    },
    {
      "add": {
        "index": "blog_new",
        "alias": "blog_alias"
      }
    }
  ]
}
//移除匿名
POST _aliases
{
  "actions": [
    {
      "remove": {
        "indices": ["blog", "blog_new"],
        "alias": "blog_alias"
      }
    }
  ]
}
```

# ② 文档管理
1. 插入数据
```
PUT blog/_doc/1
{
    "id": 1,
    "title": "Java 编程思想",
    "language": "java",
    "author": "Bruce Eckel",
    "price": 70.2,
    "publish_time": "2007-10-01",
    "description": "Java 学习必读经典,殿堂级著作！赢得了全球程序员的广泛赞誉"
}
```
响应信息中包含创建的文档所在的索引(index),类型(type),id(_id),version(_version),分片(_shards)、是否创建成功等信息。

如果不指定文档的id, Elasticsearch 会自动生成它
```
POST blog/_doc
{
    "id": 1,
    "title": "Java 编程思想",
    "language": "java",
    "author": "Bruce Eckel",
    "price": 70.2,
    "publish_time": "2007-10-01",
    "description": "Java 学习必读经典,殿堂级著作！赢得了全球程序员的广泛赞誉"
}
```
2. 获取文档
```
GET blog/_doc/1
```
3. 更新文档
```
PUT blog/_doc/1
{
    "id": 1,
    "title": "Java 编程思想 - update",
    "language": "java",
    "author": "Bruce Eckel",
    "price": 70.2,
    "publish_time": "2007-10-01",
    "description": "Java 学习必读经典,殿堂级著作！赢得了全球程序员的广泛赞誉"
}

POST blog/_update/RTmpRnIB4KQiFA2dtK3w
{
  "script": "ctx._source.title=\"Python 科学计算 - update\" "
}

//在更新文档时可以指定外部文档的版本号，如果外部版本不高于当前文档版本， 同样会发生异常。只有外部版本比当前文档版本高，更新操作才能成功执行。
GET blog/_doc/RTmpRnIB4KQiFA2dtK3w?version=1

PUT blog/_doc/RTmpRnIB4KQiFA2dtK3w?version=8&version_type=external
{
  "title": "Python 科学计算 - update"
}
```
4. 查询更新
```
POST blog/_update_by_query
{
  "script": {
    "inline": "ctx._source.title = params.title",
    "lang": "painless",
    "params": {"title": "Java 编程思想 - update2"}
  },
  "query": {
    "term": {"id": 1}
  }
}
```
5. 删除文档
```
DELETE blog/_doc/l
//查询删除
POST blog/_delete_by_query
{
  "query": {
    "term": {"id": 1}
  }
}
```

6. 批量操作
每一行的结尾处都必须有换行字符旧”，最后一行也要有，换行符可以有效地分隔每行。另外，这些行里不能包含非转义字符，以免干扰数据解析。

action_and_meta_data 行指定了将要在哪个文档中执行什么操作，其中action 必须是index 、create 、update 或者delete, metadata 需要指明需要被操作文档的 _index _id(不指定会自动生成)

index 和 create 区别是如果文档blog/_doc/1 己存在, create 会创建失败(`version_conflict_engine_exception`), index会更新.
```json
Request:
POST _bulk
{ "index" : { "_index" : "test", "_id" : "1" } }
{"id": 1,"title": "Java 编程思想","language": "java","author": "Bruce Eckel","price": 70.2,"publish_time": "2007-10-01","description": "Java 学习必读经典,殿堂级著作！赢得了全球程序员的广泛赞誉"}
{ "create" : { "_index" : "test", "_id" : "_zmYRnIB4KQiFA2dZarK" } }
{"id": 3,"title": "Python 科学计算","language": "python","author": "张若愚","price": 81.40,"publish_time": "2016-05-01","description": "零基础学python ，光盘中作者独家整合开发winPython 运行环境，涵盖了Python 各个扩展库"}

Response:
{
  "took" : 89,
  "errors" : true,
  "items" : [
    {
      "index" : {
        "_index" : "test",
        "_type" : "_doc",
        "_id" : "1",
        "_version" : 13,
        "result" : "updated",
        "_shards" : {
          "total" : 2,
          "successful" : 1,
          "failed" : 0
        },
        "_seq_no" : 15,
        "_primary_term" : 1,
        "status" : 200
      }
    },
    {
      "create" : {
        "_index" : "test",
        "_type" : "_doc",
        "_id" : "_zmYRnIB4KQiFA2dZarK",
        "status" : 409,
        "error" : {
          "type" : "version_conflict_engine_exception",
          "reason" : "[_zmYRnIB4KQiFA2dZarK]: version conflict, document already exists (current version [2])",
          "index_uuid" : "GLmrQIzmQLSq3tdfD97Zfw",
          "shard" : "0",
          "index" : "test"
        }
      }
    }
  ]
}

// 批量的写入操作
POST _bulk
{ "index" : { "_index" : "test", "_id" : "1" } }
{"id": 1,"title": "Java 编程思想","language": "java","author": "Bruce Eckel","price": 70.2,"publish_time": "2007-10-01","description": "Java 学习必读经典,殿堂级著作！赢得了全球程序员的广泛赞誉"}
{ "create" : { "_index" : "test", "_id" : "2" } }
{"id": 3,"title": "Python 科学计算","language": "python","author": "张若愚","price": 81.40,"publish_time": "2016-05-01","description": "零基础学python ，光盘中作者独家整合开发winPython 运行环境，涵盖了Python 各个扩展库"}
{ "delete" : { "_index" : "test", "_id" : "2" } }
{ "create" : { "_index" : "test", "_id" : "3" } }
{"id": 2,"title": "Java 程序性能优化","language": "java","author": "葛一鸣","price": 46.50,"publish_time": "2012-08-01","description": "让你的Java 程序更快、更稳定。深入剖析软件设计层面、代码层面、JVM 虚拟机层面的优化方法"}
{ "update" : {"_id" : "1", "_index" : "test"} }
{ "doc" : {"title" : "Java 编程思想 - update"} }

// 批量的读取操作
GET blog/_mget
{
  "docs": [
    {
    "_index" : "blog",
    "_id" : "1"
  }]
}
```

# ③ 路由机制
Elasticsearch 是一个分布式系统，当索引一个文档时文档会被存储到master 节点上的一个主分片上。那么Elasticsearch 是如何知道文档属于哪个分片的呢？再有当你创建一个新文档，Elasticsearch 是如何知道应该存储在分片l 还是分片2 上？要想回答这些问题，就需要了解Elasticsearch 的路由机制。Elasticsearch 的路由机制即是通过哈希算法，将具有相同哈希值的
文档放置到同一个主分片中，分片位置计算方法：

shard= hash(routing) % number_of_primary_shards

routing 值可以是一个任意字符串， Elasticsearch 默认将文档的id 值作为routing 值，通过哈希函数根据routing 字符串生成一个数字，然后除以主切片的数量得到一个余数(remainder)余数的范围永远是0 到number_of_primary_shards -1 ,这个数字就是特定文档所在的分片。这种算法基本上会保持所有数据在所有分片上的一个平均分布，而不会造成数据分配不均衡的情况。

# ④ 动态映射
动态映射是一种偷懒的方式，可直接创建索引并写入文档，文档中宇段的类型是Elasticsearch 自动识别的，不需要在创建索引的时候设置字段的类型。在实际项目中，如果遇到的业务在导入数据之前不确定有哪些字段，也不清楚字段的类型是什么，使用动态映射非常合适。
[官方参考](https://www.elastic.co/guide/en/elasticsearch/reference/7.x/mapping.html)

- 创建index并且指定映射  
    index一旦被创建就不能在被修改
```json
PUT /my-index
{
  "mappings": {
    "properties": {
      "age":    { "type": "integer" },  
      "email":  { "type": "keyword"  }, 
      "name":   { "type": "text"  }     
    }
  }
}
```
- 但是可以添加不存在的新的映射
```json
PUT /my-index/_mapping
{
  "properties": {
    "employee-id": {
      "type": "keyword",
      "index": false
    }
  }
}
```
- 使用动态Mapping 要结合实际业务需求来综合考虑，如果将Elasticsearch 当作主要的数据存储使用，井且希望出现未知宇段时抛出异常来提醒你注意这一问题，那么开启动态Mapping并不适用。在Mapping 中可以通过dynamic 设置来控制是否自动新增宇段，接受以下参数：
    - true 默认值为true ， 自动添加字段。
    - false 忽略新的字段。
    - strict 严格模式，发现新的宇段抛出异常。
    - [官网地址](https://www.elastic.co/guide/en/elasticsearch/reference/current/dynamic.html)
    - [主要类型可以参考](https://www.elastic.co/guide/en/elasticsearch/reference/current/mapping-types.html)

# ⑤ 字段类型
- ### 核心类型
    - 字符串类型
      - `text` 

        如果一个字段是要被全文搜索的，比如邮件内容、产品描述、新闻内容，应该使用text类型。设置text 类型以后， 字段内容会被分析，在生成倒排索引以前，字符串会被分词器分成一个一个词项。text 类型的字段不用于排序， 很少用于聚合（ terrnsAggregation 除外） 。
      - `keyword`

        keyword 类型适用于索引结构化的字段，比如email 地址、主机名、状态码和标签，通常用于过滤(比如查找已发布博客中status 属性为published 的文章)、排序、聚合。类型为keyword的字段只能通过精确值搜索到， 区别于text 类型。153页

    - 数字类型
      - `long`
      - `integer`
      - `short`
      - `byte`
      - `double`
      - `float`
      - `half_float`
      - `scaled_float`
    - 日期类型
      - `Date`
    - 布尔类型
      - `Boolean`
    - 二进制类型
      - `Binary`
    - 范围类型
      - `integer_range`
      - `float_range`
      - `long_range`
      - `double_range`
      - `date_range`
      - `ip_range`
- ### 复合类型
  - `Object`

    写入到Elasticsearch 之后， 文档会被索引成简单的扁平key-value(" manager.name.first" : "John")

  - `Nested`

    nested 类型是object 类型中的一个特例，可以让对象数组独立索引和查询。Lucene 没有内部对象的概念， 所以Elasticsearch 将对象层次扁平化，转化成字段名字和值构成的简单列表。nested 对象类型可以保持数组中每个对象的独立性。

- ### 地理类型
  - Geo-point
  - Geo-shape
- ### 特殊类型
  - [太多了, 参考官方文档](https://www.elastic.co/guide/en/elasticsearch/reference/current/mapping-types.html#mapping-types)

- ## 映射参数   
    Elasticsearch 提供了足够多的映射参数对宇段的映射进行参数设置， 一些常用功能的实现，比如字段的分词器、字段的权重、日期格式、检索模型的选择等都是通过映射参数来配置完成的。
    
    **简单来说就是设置字段类型时,设置参数可以使字段限定一些功能**

    [keyword可用参数](https://www.elastic.co/guide/en/elasticsearch/reference/current/keyword.html)
    
    [所有参数文档](https://www.elastic.co/guide/en/elasticsearch/reference/current/mapping-params.html)

    部分参数解释:
    - `index`

      `index` 属性指定字段是否索引，不索引也就不可搜索，取值可以为true 或者false

        ```json
      // 当 index 不存在时,可以在创建的时候设置 参数
      PUT blog
      {
        "mappings": {
          "properties": {
            "employee-name": {
              "type": "keyword",
              "index": false // index 属性指定字段是否索引，不索引也就不可搜索，取值可以为true 或者false 。
            }
          }
        }
      }

      // 当 index 已经存在时, 新增mapping参数
      PUT blog/_mapping
      {
        "properties": {
          "employee-id": {
            "type": "keyword"
          }
        }
      }
      ```
    - `store`

      默认情况下, **字段是被索引的，也可以搜索，但是不存储**, 这也没关系，因为source 字段里保存了一份原始文档。在某些情况下, store 参数有意义，比如一个文档里有title, date和超大的content 字段，如果只想获取title和date, 可以设置

    - `boost`

      `boost` 字段用于设置字段的权重, 在索引期设置权重, 如果不重新索引文档, 权重无法修改.

    - `ignore_above`

      `ignore_above`用于指定字段分词和索引的字符串最大长度， 超过最大值的会被忽略，只用于`keyword` 类型.

    - `normalizer`

      `normalizer` 参数用于解析前的标准化配置，比如把所有的字符转化为小写

    - `doc_values`

      `doc_values` 参数是为了加快排序、聚合操作，在建立倒排索引的时候，额外增加一个列式存储映射，是一种空间换时间的做法。默认是开启的

    - `format`

      Elasticsearch 中的date类型支持多种格式, `format` 参数就是用于指定日期格式的
      ```
      "properties": {
        "date": {
          "type": "date",
          "format": "yyyy-MM-dd HH:mm:ss || yyyy-MM-dd || epoch_millis"
        }
      }
      ```
    - `fields`

      fields 参数可以让同一字段有多种不同的索引方式。比如一个文本类型的字段, 可以使用text 类型做全文检, 使用keyword 类型做聚合和排序.
      ```json
      {
        "properties": {
          "city": {
            "type": "text",
            "fields": {
              "raw": { "type": "keyword" }
            }
          }
        }
      }
      ``` 

    - `null_value`

      值为null的字段不索引也不可以搜, `null_value` 参数可以让值为null 的宇段显式的可索引、可搜索

    - `动态模板`(Dynamic templates)

      [通过动态映射模板，可以在mapping 之上拥有对新宇段的完整控制，甚至可以根据字段的名称来设置映射。每个模板都有一个名字，用来描述这个模板做了什么。同时它有一个映射用来指定具体的映射信息，还有至少一个参数（比如match ）用来规定对于什么字段需要使用该模板。模板的匹配有先后，只有第一个匹配的模板会被使用](https://www.elastic.co/guide/en/elasticsearch/reference/current/dynamic-templates.html)
      ```json
      PUT my_index
      {
        "mappings": {
          "dynamic_templates": [
            {
              "integers": {
                "match_mapping_type": "long",
                "mapping": {
                  "type": "integer"
                }
              }
            },
            {
              "strings": {
                "match_mapping_type": "string",
                "mapping": {
                  "type": "text",
                  "fields": {
                    "raw": {
                      "type":  "keyword",
                      "ignore_above": 256
                    }
                  }
                }
              }
            },
            {
              "long_as_string": {
                "match_mapping_type": "string",
                "match": "long_*",
                "unmatch": "*_text",
                "mapping": {
                  "type": "long"
                }
              }
            }
          ]
        }
      }

      PUT my_index/_doc/1
      {
        "long_num": "5",
        "long_text": "foo"
      }
      ```

# ⑥ 元字段
具体属性作用
| Identity meta-fieldsedit | 文档属性的元字段 |
| ------- | --------------- |
|`_index`   | The index to which the document belongs. |
|`_type` | The document’s mapping type.|
|`_id`    | The document’s ID. |

| Document source meta-fieldsedit | 源文档的元字段 |
| ------- | --------------- |
| `_source` | The original JSON representing the body of the document. |
| `_size` | The size of the _source field in bytes, provided by the mapper-size plugin.|

> `_source` 存储文档的原始值，默认source 字段是开启的，也可以在映射中通过enabled 参数关闭。  
但是一般情况下不要关闭， 因为update 、update_by_ query 、reindex ， 关键字高亮， 数据备份，改变mapping，升级索引。通过原始宇段debug 查询或者聚合等诸多操作都需要用到source 字段中存储的文档原始值。

> `_size` 用于描述文档本身的字节大小， 默认是不支持的。如果有统计文档大小的需求， 需
要安装mapper-size 插件

| Indexing meta-fieldsedit | 索引的元字段 |
| -------------- | --------------- |
| `_field_names` | All fields in the document which contain non-null values. |
| `_ignored` | All fields in the document that have been ignored at index time because of ignore_malformed.| 

| Routing meta-fieldedit | 路由的元字段 |
| -------------- | --------------- |
| `_routing` | A custom routing value which routes a document to a particular shard. |

| Other meta-fieldedit | 自定义元字段 |
| -------------- | --------------- |
| `_meta` | Application specific metadata. |


# ⑦ 搜索总结
-----------------------------------------------
-----------------------------------------------
match_ all返回所有文档
```json
GET blog/_search
{
  "query": {
    "match_all": {}
  }
}
//简写
GET blog/_search
```

### 1. 词项 (Term & Terms Query)

  term 查询用来查找指定字段中包含给定单词的文档，term 查询不被解析，只有查询词和文档中的词精确匹配才会被搜索到，应用场景为查询人名、地名等需要精准配备的需求。

  terms查询是term查询的升级,可以用来查询文档中包含多个词的文档

  词项是经过语言学预处理之后归一化的词条。词项是索引的最小单位， 一般情况下可以把词项当作词，但词项不一定就是词。
  whatever happend tomorrow, we have had today.
  对于上面的句子， 产生词项如下：whatever happend tomorrow we have had today

  ```json
  GET blog/_search
  {
    "from": 0, //分页
    "size": 20, 
    "version": true, //默认情况下返回结果中不包含文档的版本号
    "_source": ["id", "author", "price", "language"], //默认情况下返回结果中包含了文档的所有字段信息,有时候为了简洁,只需要在查询结果中返回某些字段 
    "min_score": 0.6, // 只有评分超过这个分数的文档才会被返回
    "query": {
      "term": {
        "language": "javascript"
      }
    },
    "highlight": { //高亮查询关键字
      "fields": {
        "title": {}
      }
    }
  }

GET blog/_search
{
  "query": {
    "terms": {
      "language":  ["java", "javascript"]
    }
  }
}
  ```

### 2. match query
match 查询会解析查询语句, 分词后查询语句中的任何一个词项被匹配, 文档就
会被搜索到, 例如"Java 编程思想" 经过分词以后会变成"java" "编程" "思想" 等多个词项.

### 3. match_phrase query
match_phrase query 首先会把query可内容分词,分词器可以自定义,同时文档还要满足以下两个条件才会被搜索到:
- 分词后所有词项都要出现在该字段中
- 字段中的词项顺序要一致
```json
GET blog/_search
{
  "query": {
    "match_phrase": {
      "title": "JavaScript 高级程序设计"
    }
  }
}
```
### 4. match_phrase_prefix query
match_phrase_prefix 和 match_phrase 类似，只不过 match_phrase _prefix 支持最后一个 term前缀匹配
```json
GET blog/_search
{
  "query": {
    "match_phrase_prefix": {
      "title": "JavaScript 高"
    }
  }
}
```

### 5. multi_match query
multi_ match 是 match 的升级,用于搜索多个字段,查询语句为"JavaScript",查询域为title和language,并且支持对要搜索的字段的名称使用通配符.

也可以用指数符指定搜索字段的权重,指定关键词出现在title中的权重是出现在language字段中的3倍.
```json
GET blog/_search
{
  "query": {
    "multi_match": {
      "query": "JavaScript",
      "fields": ["title^3", "*language"]
    }
  },
  "highlight": {
    "fields": {
      "title": {}
    }
  }
}
```

### 6. range query
range查询用于匹配在某一范围内的数值型,日期类型或者字符串型字段的文档，比如搜索哪些书籍的价格在50到100之间,哪些书籍的出版时间在2014年到 2016年之间.使用range查询只能查询一个字段,不能作用在多个字段上range查询支持的参数有以下几种：
- `gt` 大于,查询范围的最小值,也就是下界,但是不包含临界值
- `gte` 大于等于,和 gt 的区别在于包含临界值
- `lt` 小于,查询范围的最大值,也就是上界,但是不包含临界值
- `lte` 小于等于,和 lt 的区别在于包含临界值
```json
//价格
GET blog/_search
{
  "query": {
    "range": {
      "price": {
        "gte": 10,
        "lte": 200
      }
    }
  }
}
//日期
GET blog/_search
{
  "query": {
    "range": {
      "publish_time": {
        "gte": "2012-01-01",
        "lte": "2013-01-01",
        "format": "dd/MM/yyyy||yyyy-MM-dd"
      }
    }   
  }
}
```

### 7. exists query
exists 查询会返回字段中至少有一个非空值的文档
```json
GET blog/_search
{
  "query": {
    "exists": {
      "field": "language" 
    }
  }
}
```
### 8. prefix query
prefix查询用于查询某个字段中以给定前缀开始的文档,比如查询title中含有以java为前缀的关键词的文档,那么含有java,javascript,javaee等所有以 java开头关键词的文档都会被匹配
```json
GET blog/_search
{
  "query": {
    "prefix": {
      "title": "java" 
    }
  }
}
```
### 9. wildcard query
wildcard query通配符查询,支持单字符通配符和多字符通配符, ?用来匹配一个任意字符, *用来匹配零个或者多个字符. 和prefix查询一样,wildcard 查询的查询性能也不是很高,需要消耗较多的CPU资源
### 10. regexp query
Elasticsearch也支持正则表达式查询,通过regex可以查询指定字段包含与指定正则表达式匹配的文档
### 11. 复合查询
  - Boolean query

    Boolean 查询可以把任意多个简单查询组合在一起,使用must/should/must not/filter 选项来表示简单查询之间的逻辑,每个选项都可以出现 0 次到多次,它们的含义如下:
    - `must` 文档必须匹配 must 选项下的查询条件,相当于逻辑运算的AND
    - `should`文档可以匹配 should 选项下的查询条件也可以不匹配,相当于逻辑运算的OR
    - `must_not` 与must相反,匹配该选项下的查询条件的文档不会被返回
    - `filter` 和 must 一样,匹配filter选项下的查询条件的文档才会被返回,但是filter不评分,只起到过滤功能

  - Boosting
    
    [太多了,以下详细例子可以参考官方文档](https://www.elastic.co/guide/en/elasticsearch/reference/current/compound-queries.html)

    boosting 查询用于需要对两个查询的评分进行调整的场景 ，boosting 查询会把两个查询封装在一起并降低其中 一个查询的评分
    
  - Constant score

    constant_score 可以包装一个其他类型的查询，并返回匹配过滤器中的查询条件且具有相同评分的文档 
  - Disjunction max
  - Function score  

    function_score 可以修改查询的文档得分，这个查询在有些情况下非常有用，比如通过评分函数计算文档得分代价较高，可以改用过滤器加自定义评分函数的方式来取代传统的评分方式  

### 12. 嵌套查询
[在Elasticsearch这样的分布式系统中执行全SQL风格的连接查询代价昂贵，是不可行的。相应地，为了实现水平规模地扩展，Elasticsearch 提供了一些嵌套查询](https://www.elastic.co/guide/en/elasticsearch/reference/current/joining-queries.html):
  - nested query (嵌套查询)

    文档中可能包含嵌套类型的字段，这些字段用来索引 一些数组对象，每个对象都可以作为一条独立的文档被查询出来。

  - has_child query (有子查询) 和 has_parent query (有父查询)

    父子关系可以存在单个的索引的两个类型的文档之间。 has_child 查询将返回其子文档能满足特定查询的父文档，而has_parent 则返回其父文档能满足特定查询的子文档。

### 13. 位置查询(Geo queries)
// TODO 218
### 14. 特殊查询(Specialized queries)
// TODO 221
### 15. 搜索高亮(Geo queries)
// TODO
### 16. 搜索排序(Geo queries)
// TODO

# ⑧ 指标聚合
// TODO

# ⑨ JAVA ELASTICSEARCH-REST-HIGH-LEVEL-CLIENT
// TODO

# ⑩ ElasticSearch优化参考
### 1. 应用场景 [优化参考](http://www.iocoder.cn/Fight/There's-no-ElasticSearch-tuning:-there-you-have-it/?self)
- 你想从类似Google的界面接受用户的输入，然后根据这些输入搜索文档
    
        如果想支持+/-或者在特定字段中搜索，就使用matCh查询simple_query_string查询

- 你想将输入作为词组并搜索包含这个词组的文档，词组中的单词间也许包含一些间隔（51。p）
    
        要查找和用户搜索相似的词组，使用match-phrase查询，并设置一定量的slop

- 你想在not_analyzed字段中搜索单个的关键词，并完全清楚这个词应该是如何出现的

        使用term查询，因为查询的词条不会被分析

- 你希望组合许多不同的搜索请求或者不同类型的搜索，创建一个单独的搜索来处理它们

        使用bool查询，将任意数量的子查询组合到一个单独的查询

- 你希望在某个文档中的多个字段搜索特定的单词

        使用mulm吡ch查询，它和match查询的表现类似，不过是在多个字段上搜索

- 你希望通过一次搜索返回所有的文档


        使用match_all查询，在一次搜索中返固全部文档

- 你希望在字段中搜索一定取值范围内的值

        使用range查询，搜索取值在一定范围内的文档

- 你希望在字段中搜索以特定字符串开头的取值

        使用prefix查询，搜索以给定字符串开头的词条

- 你希望根据用户已经输入的内容，提供单个关键词的自动完成功能

        使用prefix查询，发送用户己经输入的内容，然后获取以此文本开头的匹配项

- 你希望搜索特定字段没有取值的所有文档使用的查询问类型

        使用missing过滤器过滤出缺失某些字段的文档

### 2. 分片规则
分片数不够时，可以考虑新建索引，搜索1个有着50个分片的索引与搜索50个每个都有1个分片的索引完全等价，或者使用splitAPI来拆分索引（6、1版本开始支持）。

在实际应用中，我们不应该向单个索引持续写数据，直到它的分片巨大无比。巨大的索引会在数据老化后难以删除，以id为单位删除文档不会立刻释放空间，删除的doc只在Lucene分段合并时才会真正从磁盘中删除。即使手工触发分段合并，仍然会引起较高的1/0压力，并且可能因为分段巨大导致在合并过程中磁盘空间不足（分段大小大于磁盘可用空间的一半）。因此，我们建议周期性地创建新索引。例如，每天创建一个。假如有一个索引website，可以将它命名为website_20180319。然后创建一个名为website的索引别名来关联这些索引。这样，对于业务方来说，读取时使用的名称不变，当需要删除数据的时候，可以直接删除整个索引。

索引别名就像一个快捷方式或软链接，不同的是它可以指向一个或多个索引。可以用于实 现索引分组，或者索引间的无缝切换。

现在我们己经确定好了主分片数量，并且保证单个索引的数据量不会太大，周期忄生创建新索引带来的一个新问题是集群整体分片数量较多，集群管理的总分片数越多压力就越大。在每天生成一个新索引的场景中，可能某天产生的数据量很小，实际上不需要这么多分片，甚至一个就够。这时，可以使用_shrinkAPI来缩减主分片数量，降低集群负载。


-----------------------------------------------------------------
-----------------------------------------------------------------
[ElasticSearch7.0 移除了 type](https://www.elastic.co/guide/en/elasticsearch/reference/current/dynamic-templates.html)

[ElasticSearch7.0 移除了 type](https://www.elastic.co/guide/en/elasticsearch/reference/current/removal-of-types.html)


一些准备的数据

{
    "id": 1,
    "title": "Java 编程思想",
    "language": "java",
    "author": "Bruce Eckel",
    "price": 70.2,
    "publish_time": "2007-10-01",
    "description": "Java 学习必读经典,殿堂级著作！赢得了全球程序员的广泛赞誉"
},
{
    "id": 2,
    "title": "Java 程序性能优化",
    "language": "java",
    "author": "葛一鸣",
    "price": 46. 50,
    "publish_time": "2012-08-01",
    "description": "让你的Java 程序更快、更稳定。深入剖析软件设计层面、代码层面、JVM 虚拟机层面的优化方法"
},
{
    "id": 3,
    "title": "Python 科学计算",
    "language": "python",
    "author": "张若愚",
    "price": 81.40,
    "publish_time": "2016-05-01",
    "description": "零基础学python ，光盘中作者独家整合开发winPython 运行环境，涵盖了Python 各个扩展库"
},
{
    "id": 4,
    "title": "Python 基础教程",
    "language": "python",
    "author": "Helant",
    "price": 54.50,
    "publish_time": "2014-03-01",
    "description": "经典的Python 入门教程， 层次鲜明，结构严谨，内容翔实"
},
{
    "id": 5,
    "title": "JavaScript 高级程序设计",
    "language": "javascript",
    "author": "Nicholas C. Zakas",
    "price": 66.40,
    "publish_time": "2012-10-01",
    "description": "JavaScript 技术经典名著"
},
{
    "id": 6,
    "title": "JavaScript设计模式与开发实践",
    "language": "javascript",
    "author": "曾探",
    "price": 59.0,
    "publish_time": "2015-05-01",
    "description": "本书将教会你如何把经典的设计模式应用到JavaScript语言中，编写出优美高效、结构化和可维护的代码"
}
