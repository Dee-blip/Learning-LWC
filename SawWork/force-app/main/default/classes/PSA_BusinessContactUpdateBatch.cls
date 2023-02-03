/******

Author: Sharath Prasanna
Created Date: 04/04/2016
Description: This is the batch class which is called from the finish method of PSA_LicenseDeprovisionBatch. It changes the contact
			records from PSA resource to Business Contact and removes the Permission Control
*/

public class PSA_BusinessContactUpdateBatch implements Database.Batchable<sObject>,Database.Stateful {
	
	String query;
	public List<String> AkamContactIDs;
	String recordTypeId;
	public Integer usersCount;
	public Integer contactsCount;
	//PSA_Settings__c EnggEmail = PSA_Settings__c.getInstance('Engineering Team Email');  
	//String fromEmailAddress = PSA_Settings__c.getInstance('FromEmailAdress').Value__c.trim();  

    PSA_Common_Setting__mdt EnggEmail = [select Value_Long__c from PSA_Common_Setting__mdt where Name__c='Engineering Team Email' limit 1];
    String fromEmailAddress = [select Value_Long__c from PSA_Common_Setting__mdt where Name__c='FromEmailAdress'  limit 1].Value_Long__c;
    String orgWideEmailId = [select Id from OrgWideEmailAddress where Address= :fromEmailAddress limit 1].Id;


	public PSA_BusinessContactUpdateBatch() {
		usersCount = 0;
		contactsCount = 0;
		recordTypeId = [select Id from RecordType where Name = 'Business Contact'].Id;		
	}
	
	public Database.QueryLocator start(Database.BatchableContext BC) {
		query = 'select id, name, email, profile.name,AKAM_User_ID__c from user where AKAM_User_ID__c in :AkamContactIDs';
		return Database.getQueryLocator(query);
	}

   	public void execute(Database.BatchableContext BC, List<sObject> scope) {

   			List<user> users = scope;
   			List<string> akamUserID = new List<string>();

   			List<id> PCUserIds = new List<id>();
   			for (User licensedUser : users)
   			{
	              akamUserID.add(licensedUser.AKAM_User_ID__c);
	              PCUserIds.add(licensedUser.id);
   			}				
/*
Changes by Sharath Ravishankar :The modification of PSA contact to Business Contact is commented out as it was hindering the timecard approval process for the inactive 
employees and the employees whose role changes to non GSS-PS Profile 
*/
/*
   			List<Contact> contacts = new List<Contact>();
   			List<Contact> updateContacts = new List<Contact>();
   			
			contacts = [select id,RecordTypeId,pse__Is_Resource__c,pse__Is_Resource_Active__c,pse__Region__c,pse__Practice__c,pse__Group__c,pse__Start_Date__c,pse__Salesforce_User__c,AKAM_Contact_ID__c from contact where AKAM_Contact_ID__c in : akamUserID];
   			
   			for (Contact businessContact : contacts)
   			{   				
	              businessContact.RecordTypeId = recordTypeId;	             
	              businessContact.pse__Is_Resource__c = FALSE;
	              businessContact.pse__Is_Resource_Active__c = FALSE;
	              businessContact.pse__Region__c = NULL;
	              businessContact.pse__Practice__c = NULL;
	              businessContact.pse__Group__c = NULL;
	              businessContact.pse__Start_Date__c = NULL;
	              businessContact.pse__Salesforce_User__c = NULL;  
	              businessContact.pse__Work_Calendar__c = NULL;  	              
	              updateContacts.add(businessContact); 			

   			}   

   			try
   			{
   				Database.update(updateContacts,false);
   			}
   			catch(Exception e)
   			{
	            List<String> sendTo1 = new List<String>();
	            List<Messaging.SingleEmailMessage> mailsToBeSent1 = new List<Messaging.SingleEmailMessage>();
	            sendTo1.add(UserInfo.getUserEmail());
	            Messaging.SingleEmailMessage email1 = new Messaging.SingleEmailMessage();      
	            email1.setToAddresses(sendTo1);
		        email1.setReplyTo('noreply@akamai.com');            
	            email1.setOrgWideEmailAddressId(orgWideEmailId);
		        email1.setToAddresses(new list<String>{EnggEmail.Value__c});            
	            email1.setSubject('De Provisioning PSA License');
	            email1.setPlainTextBody('Hi Team'  + '\n\n There was as error in updating the contact records: ' + e.getMessage());
	            mailsToBeSent1.add(email1);
	            Messaging.sendEmail(mailsToBeSent1,false);
   			}
*/
        //Removal of Permission control
	       List<pse__Permission_Control__c> toDeletePermissionControlList = [select Id,pse__User__c from pse__Permission_Control__c where pse__User__r.Id  in :PCUserIds];
    	   
   			try
   			{
   				Database.Delete(toDeletePermissionControlList,false);  
   			}
   			catch(Exception e)
   			{
	         //   List<String> sendTo1 = new List<String>();
	         //   List<Messaging.SingleEmailMessage> mailsToBeSent1 = new List<Messaging.SingleEmailMessage>();
	         //   sendTo1.add(UserInfo.getUserEmail());
	         //   Messaging.SingleEmailMessage email1 = new Messaging.SingleEmailMessage();      
	         //   email1.setToAddresses(sendTo1);
		        //email1.setReplyTo('noreply@akamai.com');            
	         //   email1.setOrgWideEmailAddressId(orgWideEmailId);
		        //email1.setToAddresses(new list<String>{EnggEmail.Value__c});            
	         //   email1.setSubject('De Provisioning PSA License');
	         //   email1.setPlainTextBody('Hi Team'  + '\n\n There was as error in deleting the permission control records: ' + e.getMessage());
	         //   mailsToBeSent1.add(email1);
	         //   Messaging.sendEmail(mailsToBeSent1,false);

	            PSA_AutoCreateProjectUtil.sendErrorMails(' Error in deleting the permission control records: ',e.getMessage()); 				

   			}

   			List<PSA_License_DeProvisioned_User__c> deprovisionedList = new List<PSA_License_DeProvisioned_User__c>();
   			deprovisionedList = [select Id, License_removed__c ,User__c   from PSA_License_DeProvisioned_User__c where License_removed__c = false and User__c in :PCUserIds];
   			List<PSA_License_DeProvisioned_User__c> toUpdateList = new List<PSA_License_DeProvisioned_User__c>();
   			for (PSA_License_DeProvisioned_User__c deprovisionedUser: deprovisionedList)
   			{
   					deprovisionedUser.License_removed__c = true;
   					toUpdateList.add(deprovisionedUser);	
   			}
   			try
   			{
   				Database.update(toUpdateList,false);
   			}
   			catch(Exception e)
   			{
	         //   List<String> sendTo1 = new List<String>();
	         //   List<Messaging.SingleEmailMessage> mailsToBeSent1 = new List<Messaging.SingleEmailMessage>();
	         //   sendTo1.add(UserInfo.getUserEmail());
	         //   Messaging.SingleEmailMessage email1 = new Messaging.SingleEmailMessage();      
	         //   email1.setToAddresses(sendTo1);
		        //email1.setReplyTo('noreply@akamai.com');            
	         //   email1.setOrgWideEmailAddressId(orgWideEmailId);
		        //email1.setToAddresses(new list<String>{EnggEmail.Value__c});            
	         //   email1.setSubject('De Provisioning PSA License');
	         //   email1.setPlainTextBody('Hi Team'  + '\n\n There was as error in inserting the PSA_License_DeProvisioned_User__c records: ' + e.getMessage());
	         //   mailsToBeSent1.add(email1);
	         //   Messaging.sendEmail(mailsToBeSent1,false);  

	            PSA_AutoCreateProjectUtil.sendErrorMails(' Error in inserting the PSA_License_DeProvisioned_User__c records: ',e.getMessage()); 				
   			}
	

   			usersCount += toUpdateList.size();
   			//contactsCount += updateContacts.size();
   			
	
	}
	
	public void finish(Database.BatchableContext BC) {

		
        AsyncApexJob a =[SELECT Id, NumberOfErrors, JobItemsProcessed,TotalJobItems FROM AsyncApexJob WHERE Id =:BC.getJobId()];
        List<String> sendTo = new List<String>();
        List<Messaging.SingleEmailMessage> mailsToBeSent = new List<Messaging.SingleEmailMessage>();
        sendTo.add('shprasan@akamai.com');
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();      
        email.setReplyTo('noreply@akamai.com');
        email.setOrgWideEmailAddressId(orgWideEmailId);
        email.setToAddresses(new list<String>{EnggEmail.Value_Long__c});
        //email.setToAddresses(new list<String>{'shprasan@akamai.com'});
        email.setSubject('De Provisioning PSA License');
        email.setPlainTextBody( 'The batch Apex job to update contact records processed ' + a.TotalJobItems +' batches with '+ a.NumberOfErrors + ' failures. The number of licenses de-provisioned = ' + usersCount + '\n Number of contacts updated = ' + contactsCount );
        mailsToBeSent.add(email);
        Messaging.sendEmail(mailsToBeSent,false);
		
	}
	
}