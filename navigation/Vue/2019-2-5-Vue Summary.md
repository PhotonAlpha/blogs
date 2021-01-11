# Vue

## ESLint

不管是多人合作还是个人项目，代码规范是很重要的。这样做不仅可以很大程度地避免基本语法错误，也保证了代码的可读性。这所谓工欲善其事，必先利其器，个人推荐 eslint+vscode 来写 vue，绝对有种飞一般的感觉。

每次保存，vscode 就能标红不符合 eslint 规则的地方，同时还会做一些简单的自我修正。安装不走如下

- 首先安装 eslint 插件
- Ctrl + Shift + P
- Preferences:Open Settings(JSON)
- ```json
  {
    "editor.tabSize": 2,
    /* 关闭编辑器自带保存格式化功能，此功能会用Vetur进行格式化。*/
    "editor.formatOnSave": false,
    "editor.codeActionsOnSave": {
      "source.fixAll": true
    }
  }
  ```
- Preferences:Open Keyboard Shotcuts(JSON) 修改快捷键
  ```json
  [
    {
      "key": "ctrl+shift+u",
      "command": "-workbench.action.output.toggleOutput"
    },
    {
      "key": "ctrl+shift+u",
      "command": "editor.action.transformToUppercase"
    },
    {
      "key": "ctrl+shift+x",
      "command": "-workbench.view.extensions"
    },
    {
      "key": "ctrl+shift+x",
      "command": "editor.action.transformToLowercase"
    }
  ]
  ```

```

[Vue Router](https://router.vuejs.org/zh/guide/advanced/navigation-guards.html#%E5%85%A8%E5%B1%80%E5%89%8D%E7%BD%AE%E5%AE%88%E5%8D%AB)

[vue-admin-template](https://github.com/PanJiaChen/vue-admin-template/blob/master/README-zh.md)

[手摸手，带你封装一个 vue component](https://segmentfault.com/a/1190000009090836)

[ Vue.js](https://cn.vuejs.org/v2/guide/events.html)
```


# VsCode 启用tslint
1. tslint.json --> "trailing-comma": true
2. Ctrl+, --> setting.json
  ```
  {
    "editor.tabSize": 2,
    /* 关闭编辑器自带保存格式化功能，此功能会用Vetur进行格式化。*/
    "editor.formatOnSave": false,
    "editor.codeActionsOnSave": {
      "source.organizeImports": true,
      "source.fixAll": true
    },
    "eslint.lintTask.enable": true
  }

  ```