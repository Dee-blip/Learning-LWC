public  class L2Q_CustomExceptionData {
    public String errName;
    public String errorMessage;
    public Integer errorCode;
    public String errorType;
    public String userMessage;
    public String errorsourceName;

    public L2Q_CustomExceptionData(String errName, String errorMessage, Integer errorCode,String errorType,String userMessage,String errorsourceName) {
        this.errName = errName;
        this.errorMessage = errorMessage;
        this.errorCode = errorCode;
        this.errorType = errorType;
        this.userMessage  = userMessage;
        this.errorsourceName = errorsourceName;
    }
}