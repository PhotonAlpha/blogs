


spring security ref:
	1. https://dzone.com/articles/spring-security-authentication
	2. https://www.jianshu.com/p/ac42f38baf6e

### AuthenticationTokenFilter Strategy
```java
public class AuthenticationTokenFilter extends OncePerRequestFilter {
	@Override
    protected void doFilterInternal(HttpServletRequest httpServletRequest, HttpServletResponse response, FilterChain filterChain) throws ServletException, IOException {
        final String authHeader = httpServletRequest.getHeader("Authorization");
        final String uri = httpServletRequest.getRequestURI(); 
        MultiReadHttpServletRequest request = new MultiReadHttpServletRequest(httpServletRequest);

        SecurityContextHolder.getContext().setAuthentication(null);
		if (StringUtils.isNotEmpty(authHeader) && authHeader.startsWith("Bearer ")) {
			String requestBody = IOUtils.toString(request.getInputStream(), request.getCharacterEncoding());
			StatusCode status = StatusCode.JWT_FAILURE;
			log.info("-- JWT Validate Status -- :{}", status);
			if (status == StatusCode.JWT_SUCCESS && SecurityContextHolder.getContext().getAuthentication() == null) {
				/** if the token verify is disable, just add simple  AuthenticationToken */
				SecurityContextHolder.getContext().setAuthentication(genericUsernamePasswordAuthenticationToken(request));
			} else {
				// if auth failure, the UnAuthenticationEntryPoint can fetch the error status and generate response with status code
				request.setAttribute(Constants.REQUEST_STATUS, status);
			}
		} else {
			// if auth failure, the UnAuthenticationEntryPoint can fetch the error status and generate response with status code
			request.setAttribute(Constants.REQUEST_STATUS, StatusCode.JWT_FAILURE);
		}
        filterChain.doFilter(request, response);
    }

    private UsernamePasswordAuthenticationToken genericUsernamePasswordAuthenticationToken(HttpServletRequest request) {
        UserDetails userDetails = new User("GATEWAY", "", Arrays.asList(new SimpleGrantedAuthority("ADMIN")));
        // For simple validation it is completely sufficient to just check the token integrity. You don't have to call
        final UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(userDetails, null, userDetails.getAuthorities());
        authentication.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
        return authentication;
    }
}
```

### MultiReadHttpServletRequest
```java
public class MultiReadHttpServletRequest extends HttpServletRequestWrapper {
    private ByteArrayOutputStream cachedBytes;
    private final Map<String, String> httpHeaders;

    public MultiReadHttpServletRequest(HttpServletRequest request) {
        super(request);
        httpHeaders = new HashMap<>(0);
    }

    public void putHeader(String name, String value){
        String key = Optional.ofNullable(super.getHeaderNames()).map(Collections::list).orElse(new ArrayList<>(0))
            .stream().filter(header -> header.equalsIgnoreCase(name)).findFirst().orElse(name);
        this.httpHeaders.put(key, value);
    }

    @Override
    public String getHeader(String name) {
        String headerValue = httpHeaders.get(name);
        if (StringUtils.isNotEmpty(headerValue)) {
            return headerValue;
        }
        return super.getHeader(name);
    }

    @Override
    public Enumeration<String> getHeaderNames() {
        List<String> names = Collections.list(super.getHeaderNames());
        Set<String> nameSets = new HashSet<>(names);

        for (String name : httpHeaders.keySet()) {
            Optional<String> optional = nameSets.stream().filter(header -> header.equalsIgnoreCase(name)).findAny();
            if (optional.isPresent()) {
                continue;
            }
            names.add(name);
        }
        return Collections.enumeration(names);
    }

    @Override
    public Enumeration<String> getHeaders(String name) {
        List<String> values = Collections.list(super.getHeaders(name));
        if (httpHeaders.containsKey(name)) {
            values = Arrays.asList(httpHeaders.get(name));
        }
        return Collections.enumeration(values);
    }

    @Override
    public ServletInputStream getInputStream() throws IOException {
        if (cachedBytes == null) {
            cacheInputStream();
        }
        return new CachedServletInputStream();
    }

    @Override
    public BufferedReader getReader() throws IOException {
        return new BufferedReader(new InputStreamReader(getInputStream()));
    }

    private void cacheInputStream() throws IOException {
        /* Cache the inputstream in order to read it multiple times. For
         * convenience, I use apache.commons IOUtils
         */
        cachedBytes = new ByteArrayOutputStream();
		IOUtils.copy(super.getInputStream(), cachedBytes);
    }
    
    /* An inputstream which reads the cached request body */
    public class CachedServletInputStream extends ServletInputStream {
        private ByteArrayInputStream input;

        public CachedServletInputStream() {
            /* create a new input stream from the cached request body */
            input = new ByteArrayInputStream(cachedBytes.toByteArray());
        }

        @Override
        public boolean isFinished() {
            return input.available() == 0;
        }

        @Override
        public boolean isReady() {
            return true;
        }

        @Override
        public void setReadListener(ReadListener readListener) {
            // Do nothing because of no need implement readListener
        }

        @Override
        public int read() throws IOException {
            return input.read();
        }
    }
}
```

```java
@Component
@Order(TraceWebServletAutoConfiguration.TRACING_FILTER_ORDER + 1)
public class CustomTracingFilter extends GenericFilterBean {
    private Logger log = Logger.getLogger(CustomTracingFilter.class);
    private final Tracer tracer;
   
    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain) throws IOException, ServletException {
        Span currentSpan = this.tracer.currentSpan();
        if (currentSpan == null) {
            chain.doFilter(request, response);
            return;
        }

        HttpServletRequest servletRequest = (HttpServletRequest) request;

        MultiReadHttpServletRequest requestToCache = new MultiReadHttpServletRequest(servletRequest);
        String requestBody = IOUtils.toString(requestToCache.getInputStream(), requestToCache.getCharacterEncoding());

        if (StringUtils.isEmpty(traceId)) {
            traceId = currentSpan.context().traceIdString();
        }
        // for readability we're returning trace id in a hex form
        MDC.put(CommonConstants.TRACE_ID, traceId);
        MDC.put(CommonConstants.SPAN_ID, traceId);

        ((HttpServletResponse) response).addHeader(CommonConstants.TRACE_ID, traceId);

        // we can also add some custom tags
        currentSpan.tag("customerSpa", "tag");

        chain.doFilter(requestToCache, response);
    }
}
```
