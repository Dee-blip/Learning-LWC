/**
* This class is used to create custom exception for CPQ projects
* Test class: CPQ_Test_ExceptionLogger
* @author  Shashank Hegade
* @version 1.0
* @since   2021-09-24
*/

public virtual class CPQ_CustomException extends Exception{
    
    public enum StatusCode {

        PAC_ERROR,
        VALIDATION_ERROR,
        SALESFORCE_ERROR
        
    }

    private StatusCode errorCode = StatusCode.SALESFORCE_ERROR;

    /**
     * @description CPQ_CustomException is a parameterized constructor
     * @param  message custom message
     * @param  ec      error status code, If none then null
     * @return         CPQ_CustomException instance
     */
    public CPQ_CustomException(String message, CPQ_CustomException.StatusCode ec) {
        this(message);
        this.errorCode = ec;

    }

    /**
     * @description getStatusCode returns the error status code of the error instance
     * @return   error status code enum value
     */
    public CPQ_CustomException.StatusCode getStatusCode(){
        return this.errorCode;
    }
}