@ControllerAdvice
public class GlobalExceptionHandlering {

    @ExceptionHandler({MethodArgumentNotValidException.class, BindException.class})
    public ResponseEntity<Object> methodArgumentNotValidHandler(HttpServletRequest request, MethodArgumentNotValidException exception) {
        Optional<BindingResult> bindingResult = Optional.ofNullable(exception.getBindingResult());
        List<String> fieldErrors = (List)((List)bindingResult.map(Errors::getFieldErrors).orElse(Collections.emptyList())).stream().map((error) -> {
            return getValidationMessage(error.getObjectName() + "." + error.getField() + "." + error.getCode(), error.getDefaultMessage());
        }).collect(Collectors.toList());
        List<String> gloableError = (List)((List)bindingResult.map(Errors::getGlobalErrors).orElse(Collections.emptyList())).stream().map((error) -> {
            return getValidationMessage(error.getObjectName() + "." + error.getCode(), error.getDefaultMessage());
        }).collect(Collectors.toList());
        fieldErrors.addAll(gloableError);
        return new ResponseEntity(String.join(",", fieldErrors), new HttpHeaders(), HttpStatus.OK);
    }

    @ExceptionHandler({DefaultApiException.class})
    public final ResponseEntity<Object> handleDefaultApiException(Exception e, HttpServletRequest request) {
        String errorCode = "";
        String errorDesc = "";
        if (e instanceof DefaultApiException) {
            DefaultApiException defaultExpt = (DefaultApiException)e;
            if (StringUtils.isNotEmpty(defaultExpt.getCode())) {
                errorCode = defaultExpt.getCode();
            }
            errorDesc = defaultExpt.getMessage();
        }

        List<String> errors = Arrays.asList(errorDesc);
        return new ResponseEntity(String.join(",", errors), new HttpHeaders(), httpStatus);
    }



    private static String getValidationMessage(String field, String detail) {
        StringBuilder sb = new StringBuilder();
        sb.append("[").append(field).append(" : ").append(detail).append("]");
        return sb.toString();
    }
}