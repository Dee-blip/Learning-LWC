public without sharing class ApexExceptionHandlerClass {
	
	public ApexExceptionHandlerClass() {
		
	}

	public void handleError(Exception e)
	{
        
        //TODO - @Saurabh fix this
	 String objectName= ApexTriggerHandlerAbstractClass.sObjectName;
	 String errorMessage='Error : '+e.getMessage() + '\n'+ 'Stack trace : '+e.getStackTraceString();
	 Error_Log__c el = new Error_Log__c(Name=objectName, Class__c='ApexTriggerHandlerAbstractClass', Error_Message__c=errorMessage);
	 insert el;
	 //new ErrorLog__c(errorMessage__c=e.getErrorMessage(),stackTraceMessage__c=e.getStackTraceString(),processName__c=processClassOrTriggerName);
     
	}
}