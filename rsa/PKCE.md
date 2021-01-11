[http]
	sslVerify = false
[core]
	quotepath = false
	packedGitLimit = 500m
	packedGitWindowSize = 500m
[pack]
	windowMemory = 500m
	packSizeLimit = 500m
	deltaCacheSize = 500m
	threads = 1



# OAuth2
http://localhost:8080/o/oauth2/authorize?response_type=code&client_id=id-959a258c-ded8-d671-55ad-fa62ac1caee4

http://localhost:8080/o/oauth2/token
`application/x-www-form-urlencoded

client_id:id-959a258c-ded8-d671-55ad-fa62ac1caee4
grant_type:authorization_code
code:e627eb04751ed62b5f91fab7ad4ff7
redirect_uri:http://localhost:4200
client_secret:secret-662f48ac-f74f-b04e-14a8-a25119764a8
`

# OAuth2 With PKCE  (Client Profile  -> ['PKCE Extended Authorization Code', 'Refresh Token', 'Resource Owner Password Credentials'])

暴露OPEN API [Making Unauthenticated Requests](https://help.liferay.com/hc/zh-cn/articles/360039026192-Making-Authenticated-Requests)

```javaScript
https://tonyxu-io.github.io/pkce-generator/
https://tools.ietf.org/html/rfc7636#page-8

import crypto from 'crypto'
import base64url from 'base64url'

const code_verifier = 'test'
var code_verifier = generateRandomString(128)


const hash = crypto.createHash('sha256').update(code_verifier).digest()
const code_challenge = base64url.encode(hash)
console.log('code_verifier:', code_verifier, 'code_challenge:', code_challenge)


function generateRandomString(length) {
    var text = "";
    var possible = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~";
    for (var i = 0; i < length; i++) {
    text += possible.charAt(Math.floor(Math.random() * possible.length));
    }
    return text;
}
```

<!-- Code Challenge: n4bQgYhMfWWaL-qgxVrQFaO_TxsrC4Is0V1sFbDwCgg -->
<!-- code_verifier: test -->
Code Challenge: LUnrYInwrIVATTEwQzoGVqpCRG4tnveDk5daeOg-hwg
code_verifier: zBnuSeo8DXgvda-CW3MhjcFBo9pptUOVE0PbxEPWSzPv2Hb8B4pKEagXnFsy3gFhbRRw3PlXYKXNV-AgFYB3KQYiiv_1Q.bPUCQwWbNba-GaZevGfSE9lrxkDEdsdAAN

http://localhost:8080/o/oauth2/authorize?response_type=code&client_id=id-3679b988-fd45-ad70-538f-54262c137d5e&redirect_uri=http://localhost:4200/auth&code_challenge=LUnrYInwrIVATTEwQzoGVqpCRG4tnveDk5daeOg-hwg

http://localhost:8080/o/oauth2/authorize?response_type=code&client_id=id-3679b988-fd45-ad70-538f-54262c137d5e&redirect_uri=http://localhost:4200/auth&code_challenge=LUnrYInwrIVATTEwQzoGVqpCRG4tnveDk5daeOg-hwg&scope=analytics.read analytics.write

http://localhost:8080/o/oauth2/token
`application/x-www-form-urlencoded

client_id:id-3679b988-fd45-ad70-538f-54262c137d5e
grant_type:authorization_code
code:3183471f944d348c8112c273f977af
redirect_uri:http://localhost:4200/auth
code_verifier:zBnuSeo8DXgvda-CW3MhjcFBo9pptUOVE0PbxEPWSzPv2Hb8B4pKEagXnFsy3gFhbRRw3PlXYKXNV-AgFYB3KQYiiv_1Q.bPUCQwWbNba-GaZevGfSE9lrxkDEdsdAAN
`

```
{
    "access_token": "e8614daa8bd8e373ecddcc6129d4d465c4fdfe8fda94529798facf012646a",
    "token_type": "Bearer",
    "expires_in": 600,
    "scope": "Liferay.Headless.Portal.Instances.everything Liferay.Headless.Commerce.Admin.Account.everything.write Liferay.App.Builder.REST.everything.write Liferay.Headless.Commerce.Admin.Pricing.everything Liferay.Headless.Form.everything.write liferay-json-web-services.everything.write Liferay.Headless.Commerce.Delivery.Catalog.everything.read Liferay.Headless.Commerce.Admin.Inventory.everything.write Liferay.Headless.Portal.Instances.everything.write Liferay.Headless.Commerce.Admin.Catalog.everything.read Liferay.Headless.Commerce.Admin.Order.everything.read Liferay.Headless.Delivery.everything.read Liferay.Headless.Delivery.everything.write Liferay.Bulk.REST.everything.write Greetings.Rest.everything.read Liferay.Headless.Commerce.Admin.Site.Setting.everything.read Liferay.Headless.Admin.Taxonomy.everything.read Liferay.Headless.Admin.Content.everything Liferay.Headless.Discovery.OpenAPI.everything.read Liferay.Headless.Admin.User.everything.read liferay-json-web-services.everything.read.documents.download Liferay.Headless.Commerce.Admin.Channel.everything.read Liferay.Headless.Admin.User.everything Liferay.Headless.Form.everything.read liferay-json-web-services.analytics.read Liferay.App.Builder.REST.everything.read Liferay.Headless.Commerce.Admin.Order.everything.write Liferay.Headless.Delivery.everything Liferay.Headless.Commerce.Admin.Pricing.everything.write Liferay.Headless.Commerce.Admin.Account.everything.read Liferay.Headless.Commerce.Admin.Site.Setting.everything.write Liferay.Headless.Admin.User.everything.write Liferay.Headless.Commerce.Admin.Catalog.everything Liferay.Headless.Commerce.Admin.Inventory.everything.read Liferay.Headless.Batch.Engine.everything Liferay.Headless.Admin.Content.everything.read analytics.read Liferay.Headless.Portal.Instances.everything.read analytics.write Liferay.Data.Engine.REST.everything Liferay.App.Builder.REST.everything liferay-json-web-services.analytics.write Liferay.Bulk.REST.everything.read Liferay.Headless.Commerce.Admin.Site.Setting.everything liferay-json-web-services.everything Liferay.Headless.Commerce.Admin.Catalog.everything.write Liferay.Data.Engine.REST.everything.read Liferay.Headless.Batch.Engine.everything.read Liferay.Headless.Commerce.Admin.Channel.everything Liferay.Bulk.REST.everything Liferay.Headless.Discovery.API.everything.read liferay-json-web-services.everything.read Liferay.Headless.Commerce.Admin.Inventory.everything Liferay.Headless.Admin.Content.everything.write Liferay.Headless.Admin.Taxonomy.everything.write Liferay.Data.Engine.REST.everything.write Liferay.Headless.Commerce.Admin.Pricing.everything.read Liferay.Headless.Commerce.Admin.Order.everything Liferay.Headless.Form.everything liferay-json-web-services.everything.read.userprofile Liferay.Headless.Admin.Taxonomy.everything Liferay.Headless.Commerce.Admin.Account.everything Liferay.Headless.Commerce.Admin.Channel.everything.write Liferay.Headless.Batch.Engine.everything.write",
    "refresh_token": "35f6e1147f499bda6a1bd819ada65636c787272bde52acdd961aa6bc3433b1"
}
```


```
{
    "access_token": "f71eae28495cc33b8cfad9315b2a402e386eaf041dab1c54ae19f14376b8b83",
    "token_type": "Bearer",
    "expires_in": 600,
    "scope": "Liferay.Headless.Delivery.everything.write Liferay.Data.Engine.REST.everything Liferay.Headless.Form.everything Liferay.Headless.Form.everything.write Liferay.Data.Engine.REST.everything.read Liferay.Headless.Form.everything.read Greetings.Rest.everything.read Liferay.Data.Engine.REST.everything.write Liferay.Headless.Delivery.everything Liferay.Headless.Delivery.everything.read",
    "refresh_token": "1e1ae1e5e2cde87c22a9e47d852318b02467ee5f48ddb72af522b1aace31e15b"
}
```

https://auth0.com/docs/flows/authorization-code-flow-with-proof-key-for-code-exchange-pkce
set PKCE : https://developers.onelogin.com/openid-connect/guides/auth-flow-pkce
            https://developers.onelogin.com/openid-connect/api/authorization-code
            https://developers.onelogin.com/openid-connect/api/authorization-code-grant

# 3. Client Credentials:
clientId: id-60c7f1a1-1118-3d06-afed-d29f84ffee9
clientSecret: secret-25c4da74-fc15-4b9d-aa8a-c04aee1071


# JAX-RS [auth allowed允许认证](https://help.liferay.com/hc/en-us/articles/360031902292-JAX-RS)

https://help.liferay.com/hc/en-us/articles/360031902292-JAX-RS

Control Panel -> Configuration -> System Setting -> Web API ->





Scope : Content Delivery http://localhost:8080/o/headless-delivery/v1.0/openapi.yaml

# 4. [自定义deploy地址](https://docs.liferay.com/dxp/digital-enterprise/7.0-latest/propertiesdoc/portal.properties.html)
```
module.framework.base.dir=${liferay.home}/osgi

module.framework.auto.deploy.dirs=\
    ${module.framework.base.dir}/configs,\
    ${module.framework.base.dir}/marketplace,\
    ${module.framework.base.dir}/modules,\
    ${module.framework.base.dir}/war
############################################################################################
module.framework.modules.dir=D:/workspace/source/liferay_workspace/pweb/bundles/osgi/modules
```


# 5. Liferay OpenAPI [文档](https://app.swaggerhub.com/organizations/liferayinc)
1. Configuration -> System Settings -> Security -> Security Tools -> Protal Cross Resource Origin Sharing (CORS)
2. add new one 
3. Add url pattern  /o/appointments/*
4. save

1. after deploy -> configuration -> gogo shell -> jaxrs:check
2. 导入jackson包一定要用 `compileInclude`
```
compileInclude group: 'com.fasterxml.jackson.jaxrs', name: 'jackson-jaxrs-json-provider', version: '2.9.10'
```
3. 引用service需要先deploy service



# 6. resert password
https://liferay.dev/blogs/-/blogs/how-to-reset-the-password-for-a-liferay-portal-user
