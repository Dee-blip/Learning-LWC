global without sharing class AMI_ExceptionLogger {
    
    public enum ErrorTypes{RESOLVE_SUBSCRIPTION,USER_FETCH,SAVE_SUBSCIPTION,UPDATE_OPERATION}
    
    public static void logException(String request,Exception ex,String errorType) {
        AMI_Error_Logs__c errorLog = new AMI_Error_Logs__c(
            Data__c = request,
            exception__c = ex.getMessage() + 'stack trace is' + ex.getStackTraceString(),
            Type__c = errorType
        );
        
        List<Database.SaveResult> errorLogInsertResult = Database.insert(new List<AMI_Error_Logs__c>{errorLog});
        
        for(Database.SaveResult sr : errorLogInsertResult) {
            
            if(sr.isSuccess()) {
                EmailTemplate template = AMI_EmailHandler.getEmailTemplateObject('Exception');
                List<Object> parameters = new List<Object>{
                    request,
                    errorType,
                    ex.getMessage(),
                    sr.id
                };
                String body = String.format(template.htmlvalue, parameters);
                AMI_EmailHandler.sendEmailGeneric(template.subject,body);
            }
        }        
    }

    public static void logExceptionWithoutEmailNotification(String request,Exception ex,String errorType) {
        AMI_Error_Logs__c errorLog = new AMI_Error_Logs__c(
            Data__c = request,
            exception__c = ex.getMessage() + 'stack trace is' + ex.getStackTraceString(),
            Type__c = errorType
        );
        
        List<Database.SaveResult> errorLogInsertResult = Database.insert(new List<AMI_Error_Logs__c>{errorLog});
    }
}