https://stackoverflow.com/questions/46040922/angular4-httpclient-csrf-does-not-send-x-xsrf-token


```javascript
imports: [   
 HttpClientModule,  
 HttpClientXsrfModule.withOptions({
   cookieName: 'My-Xsrf-Cookie', // this is optional
   headerName: 'My-Xsrf-Header' // this is optional
 }) 
]

@Injectable()
export class HttpXsrfInterceptor implements HttpInterceptor {
  constructor(private tokenExtractor: HttpXsrfTokenExtractor) {
  }
  intercept(req: HttpRequest<any>, next: HttpHandler): Observable<HttpEvent<any>> {
    const headerName = 'X-XSRF-TOKEN';
    let token = this.tokenExtractor.getToken() as string;
    if (token !== null && !req.headers.has(headerName)) {
      req = req.clone({ headers: req.headers.set(headerName, token) });
    }
    return next.handle(req);
  }
}

providers: [
  { provide: HTTP_INTERCEPTORS, useClass: HttpXsrfInterceptor, multi: true }
]
```
