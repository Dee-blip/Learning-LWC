public class HD_AutomatedTicketAssignmentException extends Exception {

    public void updateErrorLog(){

    	try{
	    	HD_Round_Robin_error_log__c newLog = new HD_Round_Robin_error_log__c();

	    	newLog.Error_Message__c = this.getMessage();
	    	newLog.Error_Cause__c = string.valueof(this.getCause());
	    	newLog.Error_Line_Number__c = Integer.valueOf(this.getLineNumber());

	    	insert newLog;
	    }
	    catch(Exception e){
	    	system.debug(e.getMessage());
	    }

    }

}