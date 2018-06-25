# GraphQL API v4 手把手教我使用Github GraphQL 

近几年提供 HTTP API 服务的公司越来越多，许多公司都把 API 作为产品重要的一部分，作为服务提供出去。而微服务的兴起，也让企业内部开始重视和频繁使用 HTTP API 。好的 HTTP API 设计容易理解、符合 RFC 标准、提供使用者便利的功能，其中经常被拿来作为教科书典范的当属 `Github API`。现在我们来学习一下Github新的API。

## 什么是 [GraphQL](https://graphql.org/)？
GraphQL数据查询语言是：

* 强类型 ： GraphQL与C 和Java 等后端语言相得益彰， 服务端能对响应的形状和性质做出一定保证，而RESTful是弱类型的，缺少机器可读的元数据；
* 分工 ： GraphQL让服务端定义好支持哪些Queries ，把对数据的Query需求下放到客户端管理，分工明确的同时保持对API 的聚焦；
* 分层 ： GraphQL的Query本身是一组分层的字段，查询就像返回的数据一样，是一种产品(工程师)描述数据和需求的自然方式；(PS：部分翻译的，国外好像都把产品叫做Product Engineers 而不是Product Manager。感觉在吐槽的样子)
* 预测性 ： GraphQL的Query只返回客户端要求的内容，没有任何冗余(不浪费流量)，而且它只有一个接口地址 ，由此衍生了另一个特性；
* 兼容性 ：需求变动带来的新增字段不影响老客户端，服务端再也不需要版本号了，极大简化了兼容问题；(App 通常是1-2 周的固定周期发版，在原生应用不强制升级的世界里，会出现用户1-2 年都不升级的情况。 这意味可能同时有52 个版本的客户端查询我们的服务端，而在Fackbook 中GraphQL API 曾支持了横跨3 年的移动端)
* 自检性 ： GraphQL能在执行Query之前(即在开发时)提供描述性错误消息，在给定查询的情况下，工具可以确保其句法是正确有效的，这使得构建高质量的客户端变得更加容易；
* Doc & Mock ： GraphQL的文档永远和代码同步，开发无需维护散落多处的文档，调用者也无需担心过期问题，而且基于类型系统的强力支撑和graphql-tools ，mocking 会变得无比容易。
>> * A [specification](http://facebook.github.io/graphql/). The spec determines the validity of the schema on the API server. The schema determines the validity of client calls.
>>
>> * [Strongly typed](https://developer.github.com/v4/#about-the-graphql-schema-reference). The schema defines an API's type system and all object relationships.
>>
>> * [Introspective](https://developer.github.com/v4/guides/intro-to-graphql/#discovering-the-graphql-api). A client can query the schema for details about the schema.
>>
>> * [Hierarchical](https://developer.github.com/v4/guides/forming-calls/). The shape of a GraphQL call mirrors the shape of the JSON data it returns. Nested fields let you query for and receive only the data you specify in a single round trip.
>>
>> * An application layer. GraphQL is not a storage model or a database query language. The graph refers to graph structures defined in the schema, where nodes define objects and edges define relationships between objects. The API traverses and returns application data based on the schema definitions, independent of how the data is stored.

每个GraphQL模式都有一个用于查询和突变的根类型。

GraphQL所有请求都是POST，URL `https://api.github.com/graphql`。

下面我们开始第一个API的查询方法吧。开始之前，如果对[GitHub's GraphQL Explorer查询工具](https://developer.github.com/v4/explorer/) 不熟悉的话，可以先尝试PostMan，但是需要先申请一个token。(Explorer查询工具触发提示，`Ctrl+D` 比较顺手，其实任意快捷键都可以。)

先用PostMan尝试一下。
1. [UI申请Token方法传送门](https://help.github.com/articles/creating-a-personal-access-token-for-the-command-line/)

2. 将拿到的token 放入header之中，Authorization: bearer `token`。
![配置方法](https://photonalpha.github.io/assets/gqlStep4.png)

3. 将下方例子的查询一句转换成Json。
![step1](https://photonalpha.github.io/assets/gqlStep1.png)
![step2](https://photonalpha.github.io/assets/gqlStep2.png)
![step3](https://photonalpha.github.io/assets/gqlStep3.png)
即: `{"query":"{\n  repository(name: \"blogs\", owner: \"photonalpha\") {\n    object(expression: \"master:backend/SpringBoot\") {\n      ... on Tree {\n        entries {\n          name\n          oid\n          type\n        }\n      }\n    }\n  }\n}"}`

4. 放入PostMan Body之中，现在可以看到结果啦。
![step5](https://photonalpha.github.io/assets/gqlStep5.png)

体验过了之后是不是似乎有点明白了呢？下面我们开始使用Explorer查询。

## Query 查询
查询类型定义从服务器检索数据的GraphQL操作,类似于执行HTTP动词`GET`请求。
## Mutations 突变
突变类型定义了在服务器上更改数据的GraphQL操作。它类似于执行HTTP动词，如`POST`，`PATCH`和`DELETE`。


## Git Data Query 使用方法
### 1. 查询content下的文件列表
```
{
  repository(name: "blogs", owner: "photonalpha") {
    object(expression: "master:backend/SpringBoot") {
      ... on Tree {
        entries {
          name
          oid
          type
        }
      }
    }
  }
}
```
* `expression: "master:backend/SpringBoot"`: expression:path/to/file
* `oid`: The Git object ID 查询内容所用的ID
* `type`: 返回内容类型
* `name`: 文件名
* `repository name`: repository的名字
* `repository owner`: 用户名

### 2. Git Trees Recursive 目前不支持递归查询 只能手动递归查询
> Our GraphQL API currently doesn’t expose any recursive functionality. To achieve this, you’ll have to manually recurse on the tree entry objects. This query gets more information when the object is a Tree. You can also add ... on Blob { ... } if you want more information about blob tree entries. ---[原文](https://platform.github.community/t/how-can-build-a-tree-view-from-a-git-repository-tree/6003)
```
REST API v3 GET 办法最简单 /repos/:owner/:repo/git/trees/:tree_sha?recursive=1
```
或者
```
{
  repository(name: "blogs", owner: "photonalpha") {
    object(expression: "master:") {
      ... on Tree {
        entries {
          name
          oid
          type
          object {
            ... on Tree {
              entries {
                name
                oid
                type
                object {
                  ... on Tree {
                    entries {
                      name
                      oid
                      type
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
```
### 3. 查询Git Blobs
得到文件列表之后就可以查询文件内容了
```
{
  repository(name: "blogs", owner: "photonalpha") {
    object(oid: $oid) {
      ... on Blob {
        byteSize
        isBinary
        text
      }
    }
  }
}
```

## Git Issues Query 使用方法
下面就是查询issue了
issues (IssueConnection!)
A list of issues that have been opened in the repository.

| Argument | Type | Description|
|:--- | :----: | ---:|
|after|	String | Returns the elements in the list that come after the specified cursor.|
|before	|String	|Returns the elements in the list that come before the specified cursor.|
|first	|Int	|Returns the first n elements from the list.|
|labels	|[String!]	|A list of label names to filter the pull requests by.|
|last|	Int	|Returns the last n elements from the list.|
|orderBy	|IssueOrder	|Ordering options for issues returned from the connection.
|states	|[IssueState!]	|A list of states to filter the issues by.|
[官网传送门](https://developer.github.com/v4/object/repository/)
```
{
  repository(name: "blogs", owner: "photonalpha") {
    issues(last: 20, labels: ["rare", "BlogWorks"], states: OPEN, orderBy: {direction: DESC, field: CREATED_AT}) {
      nodes {
        title
        body
        number
        id
        url
        state
        createdAt
        labels(last: 20) {
          nodes {
            name
            url
          }
        }
      }
      pageInfo {
        hasNextPage
        endCursor
        hasPreviousPage
        startCursor
      }
    }
  }
}
```
* `issues(last or first)`: first last为必填项 必须写一个

search提供的参数很少，只有`after` `before` `first` `last` `query` `type`，如果需要根据issue title查询怎么办呢？
```
{
  search(query:"ReactJS常用功能汇总 in:title state:open repo:photonalpha/blogs", type:ISSUE, first:2){
    nodes {
    	... on Issue {
        title,
        body,
        number
      }
    }
  }
}
```
* `query: ReactJS常用功能汇总 in:title state:open repo:photonalpha/blogs`: 用法有点类似[REST API v3 Search](https://developer.github.com/v3/search/#search-issues)的用法，而且`x-ratelimit-limit →5000`变成了5000哟! [v3的search rate limit](https://developer.github.com/v3/rate_limit/)只有30呢。

## Git Comment Query 使用方法
知道issue number之后就可以查询comment了
```
{
  repository(name: "blogs", owner: "photonalpha") {
    issue(number: 7) {
      comments(last: 20) {
        nodes {
            body
            createdAt
            author {
                avatarUrl
                login
                url
            }
        }
      }
    }
  }
}
```
基本的查询大概就是这样了，还有更多方法，可以查询官网API文档。

## Git Data Mutations
如果需要提交、删除、更新数据，就需要使用突变(Mutations) [传送门](https://developer.github.com/v4/mutation/addcomment/)

```
query findComment{
  repository(name: "blogs", owner: "photonalpha") {
    issue(number: 7) {
      id
      comments(last: 20) {
        nodes {
          id
          body
          createdAt
          author {
          	avatarUrl
            login
            url
          }
        }
      }
    }
  }
}

mutation addCommentToIssue{
  addComment(input:{body:"GraphQL's\n>hello", subjectId:"MDU6SXNzdWUzMzUxNTQ3NzQ"}) {
    subject {
      id
    }
  }
}
```
* 第一条为查询操作
* 第二条为Add操作

### 大概的使用方法就在这里了，可以满足基本的操作流程了。
Github API 不管是Rest API还是Graph API都可以作为教科书来参考设计自己的API，接下来就是自己手动搭建server，设计API了。会在下一篇帖子中介绍。

设计API需要理解一个概念叫幂等性。
## 理解HTTP API设计的幂等性
幂等性定义

>Methods can also have the property of "idempotence" in that (aside from error or expiration issues) the side-effects of N > 0 identical requests is the same as for a single request.

从定义上看，HTTP方法的幂等性是指一次和多次请求某一个资源应该具有同样的副作用。幂等性属于语义范畴，正如编译器只能帮助检查语法错误一样，HTTP规范也没有办法通过消息格式等语法手段来定义它，这可能是它不太受到重视的原因之一。但实际上，幂等性是分布式系统设计中十分重要的概念，而HTTP的分布式本质也决定了它在HTTP中具有重要地位。

### HTTP的幂等性
HTTP协议本身是一种面向资源的应用层协议，但对HTTP协议的使用实际上存在着两种不同的方式：一种是RESTful的，它把HTTP当成应用层协议，比较忠实地遵守了HTTP协议的各种规定；另一种是SOA的，它并没有完全把HTTP当成应用层协议，而是把HTTP协议作为了传输层协议，然后在HTTP之上建立了自己的应用层协议。本文所讨论的HTTP幂等性主要针对RESTful风格的，不过正如上一节所看到的那样，幂等性并不属于特定的协议，它是分布式系统的一种特性；所以，不论是SOA还是RESTful的Web API设计都应该考虑幂等性。下面将介绍HTTP GET、DELETE、PUT、POST四种主要方法的语义和幂等性。

HTTP GET方法用于获取资源，不应有副作用，所以是幂等的。比如：GET `http://www.bank.com/account/123456`，不会改变资源的状态，不论调用一次还是N次都没有副作用。请注意，这里强调的是一次和N次具有相同的副作用，而不是每次GET的结果相同。GET `http://www.news.com/latest-news`这个HTTP请求可能会每次得到不同的结果，但它本身并没有产生任何副作用，因而是满足幂等性的。

HTTP DELETE方法用于删除资源，有副作用，但它应该满足幂等性。比如：DELETE `http://www.forum.com/article/4231`，调用一次和N次对系统产生的副作用是相同的，即删掉id为4231的帖子；因此，调用者可以多次调用或刷新页面而不必担心引起错误。

比较容易混淆的是HTTP POST和PUT。POST和PUT的区别容易被简单地误认为“POST表示创建资源，PUT表示更新资源”；而实际上，二者均可用于创建资源，更为本质的差别是在幂等性方面。在HTTP规范中对POST和PUT是这样定义的：

>The POST method is used to request that the origin server accept the entity enclosed in the request as a new subordinate of the resource identified by the Request-URI in the Request-Line ...... If a resource has been created on the origin server, the response SHOULD be 201 (Created) and contain an entity which describes the status of the request and refers to the new resource, and a Location header.

>The PUT method requests that the enclosed entity be stored under the supplied Request-URI. If the Request-URI refers to an already existing resource, the enclosed entity SHOULD be considered as a modified version of the one residing on the origin server. If the Request-URI does not point to an existing resource, and that URI is capable of being defined as a new resource by the requesting user agent, the origin server can create the resource with that URI.

POST所对应的URI并非创建的资源本身，而是资源的接收者。比如：POST `http://www.forum.com/articles`的语义是在`http://www.forum.com/articles`下创建一篇帖子，HTTP响应中应包含帖子的创建状态以及帖子的URI。两次相同的POST请求会在服务器端创建两份资源，它们具有不同的URI；所以，POST方法不具备幂等性。而PUT所对应的URI是要创建或更新的资源本身。比如：PUT `http://www.forum/articles/4231`的语义是创建或更新ID为`4231`的帖子。对同一URI进行多次PUT的副作用和一次PUT是相同的；因此，PUT方法具有幂等性。

在介绍了几种操作的语义和幂等性之后，我们来看看如何通过Web API的形式实现前面所提到的取款功能。很简单，用`POST /tickets`来实现`create_ticket`；用`PUT /accounts/account_id/ticket_id?amount=xxx`来实现`idempotent_withdraw`。值得注意的是严格来讲amount参数不应该作为URI的一部分，真正的URI应该是`/accounts/account_id/ticket_id`，而`amount`应该放在请求的body中。这种模式可以应用于很多场合，比如：论坛网站中防止意外的重复发帖。


（转载本站文章请注明作者和出处 Eric的小站）