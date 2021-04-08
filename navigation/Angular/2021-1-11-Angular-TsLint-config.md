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

# angular-cli server - how to proxy API requests to another server?
 
##  UPDATE 2017
> Better documentation is now available and you can use both JSON and JavaScript based configurations: ![angular-cli documentation proxy](https://github.com/angular/angular-cli/pull/1896?fireglass_rsn=true)
> sample https proxy configuration
```
{
  "/angular": {
     "target":  {
       "host": "github.com",
       "protocol": "https:",
       "port": 443
     },
     "secure": false,
     "changeOrigin": true,
     "logLevel": "info"
  }
}
```
> To my knowledge with Angular 2.0 release setting up proxies using .ember-cli file is not recommended. official way is like below
1. edit "start" of your package.json to look below
2. "start": "ng serve --proxy-config proxy.conf.json",
3. create a new file called proxy.conf.json in the root of the project and inside of that define your proxies like below
```
{
  "/api": {
    "target": "http://api.yourdomai.com",
    "secure": false
  }
}
```
3. Important thing is that you use `npm start` instead of `ng serve`
Read more from here : Proxy Setup Angular 2 cli
