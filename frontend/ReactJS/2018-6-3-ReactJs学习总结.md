# 小贴士
这里插入一些小贴示，大家可以注意到我们组件的命名和方法的摆放顺序其实有一定的讲究，这里可以简单分享一下个人的习惯，仅供参考。

组件的私有方法都用 _ 开头，所有事件监听的方法都用 handle 开头。把事件监听方法传给组件的时候，属性名用 on 开头。例如：
`
<CommentInput
  onSubmit={this.handleSubmitComment.bind(this)} />
`
这样统一规范处理事件命名会给我们带来语义化组件的好处，监听（on）CommentInput 的 Submit 事件，并且交给 this 去处理（handle）。这种规范在多人协作的时候也会非常方便。

另外，组件的内容编写顺序如下：

static 开头的类属性，如 defaultProps、propTypes。

构造函数，constructor。

getter/setter（还不了解的同学可以暂时忽略）。

组件生命周期。

_ 开头的私有方法。

事件监听方法，handle*。

render*开头的方法，有时候 render() 方法里面的内容会分开到不同函数里面进行，这些函数都以 render* 开头。

render() 方法。
如果所有的组件都按这种顺序来编写，那么维护起来就会方便很多，多人协作的时候别人理解代码也会一目了然。
