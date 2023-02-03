/***
UserTriggerClass
    @version 1.0
    @author : Ali KM <mohkhan@akamai.com>   
    @Description : This class implements Trigger logic on "Users" when they are deactivated
                   The following is implemented :
                    1. After update, when user is deactivated & owns contacts with count greater than or equal to 9900
                    2. Contact owner is changed to either Account.Owner or ONA.
                    
    @History
    --Developer           --Date            --Change
    Ali KM                31/10/2011        CR 1327133 Bug: Inactive User Contact owner update fails for bulk records.
    
*/
global class BatchableUpdateContactOwner implements Database.Batchable<sObject>
{	
	// variable declaration
    global final String query;
    //global final List<String> inactiveContactOwnerList;
    global final String[] recipientEmailList;
    
    // constructor #1
    global 	BatchableUpdateContactOwner() {}
    // constructor #2    
    global 	BatchableUpdateContactOwner(String pQuery) //String[] pInactiveContactOwnerList, String[] pRecipientEmailList  
    {
    	this.query = pQuery;
    	//this.inactiveContactOwnerList = pInactiveContactOwnerList;
    	String strRecipientList = GsmUtilClass.getGSMSettingValue('BatchableUpdateContactOwner_EmailId'); //SFDC-2304
    	this.recipientEmailList = strRecipientList.split(',');
    	System.debug('this.recipientList=' + this.recipientEmailList);
    }
    
    // implement start method
    global database.querylocator start(Database.BatchableContext BC)
    {
        return Database.getQueryLocator(query);
	}
	
	// implement execute method
	global void execute(Database.BatchableContext BC, List<sObject> scope)
	{
	    //List<Account> accns = new List<Account>();
	    List<Contact> updateContactOwnerList = new List<Contact>();
	    //UserTriggerClassSettings__c userTriggerCustomSettings = UserTriggerClassSettings__c.getInstance('v1.0'); //SFDC-2304
		try 
		{
			for(sObject s : scope)
			{
				Contact c = (Contact)s;
	            if (c.OwnerId != c.Account.OwnerId && c.Account.Owner.isActive)
	            {
	                c.OwnerId = c.Account.OwnerId;
	                c.Validation_Override__c = true;
	            }
	            else // if Account.Owner is Inactive put ONA as Contact.Owner
	            {                   
	                //c.OwnerId = userTriggerCustomSettings.ONAUserId__c; //SFDC-2304
                    c.OwnerId = GsmUtilClass.getGSMSettingValue('ONA_User_Id'); //SFDC-2304
	                c.Validation_Override__c = true;
	            }
	            updateContactOwnerList.add(c);
			}
			if (updateContactOwnerList.size()>0)
				update updateContactOwnerList;
		}
        catch (Exception e)
        {
            //String[] toAddresses = new String[] {userTriggerCustomSettings.Email__c}; //SFDC-2304
            String[] toAddresses = new String[] {GsmUtilClass.getGSMSettingValue('UsrTrgrCls_Email')}; //SFDC-2304
            String subject='Exception Occurred while updating Inactive Contact Owner records';      
            String message = e.getMessage();        
            
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(toAddresses);       
            mail.setSubject(subject);
            mail.setBccSender(false);
            mail.setUseSignature(false);
            mail.setPlainTextBody(message);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }  
	}
	
	// implement the finish method
    global void finish(Database.BatchableContext BC)
    {   
		// Get the ID of the AsyncApexJob representing this batch job from Database.BatchableContext.   
		// Query the AsyncApexJob object to retrieve the current job's information.
		AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email
							FROM AsyncApexJob WHERE Id = :BC.getJobId()];
							
		// Send an email to the Apex job's submitter notifying of job completion. 
		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		String[] toAddresses = new String[] {a.CreatedBy.Email};
		mail.setToAddresses(toAddresses);
		mail.setSubject('BatchableUpdateContactOwner Apex job is ' + a.Status);
		mail.setPlainTextBody('The batch Apex job processed ' + a.TotalJobItems + ' batches with '+ a.NumberOfErrors + ' failures.');
		Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    	
    	/*
    	Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

		mail.setToAddresses(recipientEmailList);
		mail.setReplyTo('mohkhan@akamai.com');
		mail.setSenderDisplayName('Batch Processing');
		mail.setSubject('Batch Process Completed');
		mail.setPlainTextBody('Batch Process has completed');
		
		Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
		*/
	}
}