https://developers.google.com/identity/protocols/oauth2/openid-connect?fireglass_rsn=true#state-param

https://stackoverflow.com/questions/53736518/do-you-generate-a-state-parameter-back-or-front-end-for-an-oauth-2-0-request

https://stackoverflow.com/questions/46844285/difference-between-oauth-2-0-state-and-openid-nonce-parameter-why-state-cou/46859861#46859861

> An opaque string that is round-tripped in the protocol; that is to say, it is returned as a URI parameter in the Basic flow, and in the URI #fragment identifier in the Implicit flow.
> The state can be useful for correlating requests and responses. Because your redirect_uri can be guessed, using a state value can increase your assurance that an incoming connection is the result of an authentication request initiated by your app. If you generate a random string or encode the hash of some client state (e.g., a cookie) in this state variable, you can validate the response to additionally ensure that the request and response originated in the same browser. This provides protection against attacks such as cross-site request forgery.



> More about state parameter can be found from this answer.
> Where to generate the state and where to store will depend on the nature of your application. Regardless from client type, what client must do is to validate state parameter in authorization code response.
> For a single page application, which does not contain a backend, state will have to be generate and store in the browser itself. Once response arrives, state value will have to be compared.
> For a native application (ex:- Mobile app), state could be stored in application memory. It can be appended in authorization request. When response comes, it can be validated from memory
> If application desire, state can be stored in a backend (ex:- server). This can be considered more secure (compared to SPA) given that no one can intercept/obtain the value other than from request itself. Once redirect occur, backend can validate the response parameters. Moreover, it can be used to correlate client session.
> Also, stealing state value is only valuable for the party which tries to make a CSRF attack. But be mindful to generate state values that cannot be guessed. Further reading for storage - 3.6. "state" Parameter


