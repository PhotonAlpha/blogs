```java
/**
    * Generic Remote Call
    * @date 14/03/2019 7:06 PM
    */
ParameterizedTypeReference typeRef = new ParameterizedTypeReference<GenericResponse<
        ResponseHeader, ReponseBody
    >>() {};
ResponseEntity<GenericResponse> result2 = restTemplate.exchange(remoteHost.replace(":code", statuscode), HttpMethod.POST, new HttpEntity<>(request), typeRef);

/**
    * Common Remote Call
    */
Reponse result = restTemplate.postForObject("", request, Reponse.class, statuscode);
return Optional.ofNullable(result);
```