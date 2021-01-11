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