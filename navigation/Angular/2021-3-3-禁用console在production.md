# 在生产环境禁用console log 方法
In main.ts
```javascript
if(environment.production){
    window.console.log = () => {}
    enableProdMode();
}
```

# 设置环境变量，根据不同的环境build不同的配置文件
1. 在 `/environments` 文件夹下创建环境参数，并修改如下：
    - environment.prod.ts
    ```javascript
    export const environment = {
        production: true,
        apiUrl: 'https://xx.xx.xx.xx:80'
    };
    ```
    - environment.sit.ts
    ```javascript
    export const environment = {
        production: false,
        apiUrl: 'https://xx.xx.xx.xx:8080'
    };
    ```
    - environment.uat.ts
    ```javascript
    export const environment = {
        production: true,
        apiUrl: 'https://xx.xx.xx.xx:80'
    };
    ```
2. 找到`angular.json`并添加如下配置
    ```json
    {
        "configurations": {
            "production": {
              "fileReplacements": [
                {
                  "replace": "src/environments/environment.ts",
                  "with": "src/environments/environment.prod.ts"
                }
              ],
              "optimization": true,
              "outputHashing": "all",
              "sourceMap": false,
              "extractCss": true,
              "namedChunks": false,
              "aot": true,
              "extractLicenses": true,
              "vendorChunk": true,
              "buildOptimizer": true,
              "budgets": [
                {
                  "type": "initial",
                  "maximumWarning": "3mb",
                  "maximumError": "5mb"
                },
                {
                  "type": "anyComponentStyle",
                  "maximumWarning": "10kb",
                  "maximumError": "20kb"
                }
              ]
            },
            "sit": {
              "fileReplacements": [
                {
                  "replace": "src/environments/environment.ts",
                  "with": "src/environments/environment.sit.ts"
                }
              ],
              "optimization": true,
              "outputHashing": "all",
              "sourceMap": false,
              "extractCss": true,
              "namedChunks": false,
              "aot": true,
              "extractLicenses": true,
              "vendorChunk": true,
              "buildOptimizer": true,
              "budgets": [
                {
                  "type": "initial",
                  "maximumWarning": "3mb",
                  "maximumError": "5mb"
                },
                {
                  "type": "anyComponentStyle",
                  "maximumWarning": "10kb",
                  "maximumError": "20kb"
                }
              ]
            },
            "uat": {
              "fileReplacements": [
                {
                  "replace": "src/environments/environment.ts",
                  "with": "src/environments/environment.uat.ts"
                }
              ],
              "optimization": true,
              "outputHashing": "all",
              "sourceMap": false,
              "extractCss": true,
              "namedChunks": false,
              "aot": true,
              "extractLicenses": true,
              "vendorChunk": true,
              "buildOptimizer": true,
              "budgets": [
                {
                  "type": "initial",
                  "maximumWarning": "3mb",
                  "maximumError": "5mb"
                },
                {
                  "type": "anyComponentStyle",
                  "maximumWarning": "10kb",
                  "maximumError": "20kb"
                }
              ]
            }
        }
    }
    ```

3. 生产环境编译
```
ng build --base-href=/xxx/xx/ --prod
ng build --base-href=/xxx/xx/ --configuration=sit
ng build --base-href=/xxx/xx/ --configuration=uat
```


# `ng` command fix in windows 10 命令行无效修复
1. Search for Environment Variables in the Windows search
2. "Edit the System environment variables" option will be popped in the result
3. Open that, select the "Path" and click on edit, then click "New" add your nodeJS Bin path i.e `C:\Users\{yourName}\AppData\Roaming\npm`
4. Once you added click "Ok" then close

# TS lint setup with Visual Studio Code.
**To make the code format more standardized**, we should use TSLint to make sure there is a more standardized format to make the project easier to maintain and handover when coding.
1. install `TSLint` plugin from VS Code extensions.
2. Ctrl + Shift + P, search and open **`Open Settings(JSON)`**
3. Paste below settings and save
  ```json
  {
      "editor.tabSize": 2,
      // disable VS code auto format
      "editor.formatOnSave": false,
      "editor.codeActionsOnSave": {
        // auto fix ts format
          "source.fixAll": true
      }
  }
  ```
4. Click the `TypeScript` enable At the VS Code bottom right.

# 自定义angular upload上传组件
./note/angular-自定义upload组件.7z

```html
<cq-upload class="upload-demo"
  action="https://jsonplaceholder.typicode.com/posts/"
  [beforeUpload]="beforeUpload.bind(this)"
  [upload-filter]="limit.bind(this)"
  [drag]="true"
  [multiple]="true"
  (success)="successHandle($event)"
  (error)="errorHandle($event)">
  <ng-template #trigger>
    <div fxLayout="row" fxFlexFill fxLayoutAlign="start center" class="u-padding-16" fxLayoutGap="16px">
      <div>
        <span class="icon icon__upload dialog-icon-size"></span>
      </div>
      <div>
        <div fxLayout="column" fxLayoutAlign="start" fxLayoutGap="4px" class="u-text">
          <p class="font-bold">
            Drag and drop your file here
          </p>
          <p class="p-error-desc">
            Or click here to browse
          </p>
          <p class="u-font-light">
            Upload only .jpg, .jpeg, .png, .pdf or .doc files below 2 MB.
          </p>
        </div>
      </div>
    </div>
  </ng-template>
</cq-upload>
```

## 文档 Upload Attributes
| Param | Description                                    | Type | Optional | Default|
| ----- | -------                                        |----- |-------   |------- |
|action	| Required parameters, upload address                | string	| —	     | -      |
|headers|	Optional parameter, set the upload request header                  |object	 |—       |	-     |  
|multiple|	Optional parameter, whether to support multiple selection files                 |boolean	|       —	| false |
|amount-limit|	limit the total uploadload successful amount  (default no limit)              |number	|       —	| -1 |
|beforeUpload|	prevent the action auto upload    (default will not prevent action), and can submit file by custome           |boolean	|       —	| true |
|with-credentials	|Support sending cookie credential information	|boolean|	—	|false|
|show-file-list	|Whether to display the list of uploaded files	|boolean|	—|	true|
|drag	|Whether to enable drag and drop upload|	boolean	|—|	false|
|accept	|Optional parameter, accept upload file type	|string	|—|	-|
|preview	|Optional parameters, optional parameters when clicking the uploaded file link, events when clicking the uploaded file link |	EventEmitter<CommonFile>, CommonFile: { id: string, size: number,status: string,name: string,raw: File,url?: SafeUrl, percentage?: number }	|—	|-|
|remove	|Optional parameter, the event when a file is removed from the file list	|EventEmitter<CommonFile>|	—	|-|
|progress	|Optional parameter, file upload progress event	|EventEmitter<{ commonFile: CommonFile, percentage: number }>	|—|	-|
|success	|Optional parameter, event when file upload is successful|	EventEmitter<{ commonFile: CommonFile, response: HttpResponse<any> }>	|—	|-|
|error	|Optional parameter, event when file upload fails	|EventEmitter<{ commonFile: CommonFile, error: any }>	|—|	-|
|upload-filter	|The filter function before upload, you can filter according to the file object in the parameter, return false to prevent the file upload.|	(f: File) => boolean	|—|	f => true|
|list-type	|File list display method|	string|	text / picture / picture-card	text|
|file-list	|List of uploaded files	|Array<{ name: string, url: string }>	|—	|-|
|elDisabled	|Whether to disable	|boolean|	—	|false|
