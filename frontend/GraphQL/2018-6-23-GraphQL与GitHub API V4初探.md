# GraphQL API v4 手把手教我使用Github GraphQL 
[工具传送门](https://developer.github.com/v4/explorer/) `Ctrl+D` 比较顺手，可以触发提示，其实任意快捷键都可以。

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
### Query 查询
查询类型定义从服务器检索数据的GraphQL操作,类似于GET请求。
### Mutations 突变
突变类型定义了在服务器上更改数据的GraphQL操作。它类似于执行HTTP动词，如`POST`，`PATCH`和`DELETE`。


## Git Data Query 使用方法
首先我们需要找到有哪些repository code， 可以想象成repository下有很多object
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
### 2. Git Trees Recursive 目测不支持递归查询 只能以一下形式
> Our GraphQL API currently doesn’t expose any recursive functionality. To achieve this, you’ll have to manually recurse on the tree entry objects. This query gets more information when the object is a Tree. You can also add ... on Blob { ... } if you want more information about blob tree entries. ---[原文](https://platform.github.community/t/how-can-build-a-tree-view-from-a-git-repository-tree/6003)
```
REST API v3 GET 办法最简单 /repos/:owner/:repo/git/trees/:tree_sha?recursive=1
```
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

## GitIssues 使用方法
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
* `issues(last`: first last为必填项 必须写一个

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

## Comment
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

## Git Data Mutations
大概的查询都在这里了，下面就要说一下突变了。
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

