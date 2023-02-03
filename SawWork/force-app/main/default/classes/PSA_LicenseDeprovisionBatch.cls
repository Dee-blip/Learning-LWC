/******

Author: Sharath Prasanna
Created Date: 04/04/2016
Description: This is the batch class which removes the PSA license assigned to users whose profiles change from PSA to non-PSA.
			A record is created in the object PSA_License_DeProvisioned_User__c for every such user. The record consists of the UserID, name, email, Old and New profiles. The object has a flag called License_removed
    		which is false by default. When the batch job runs, it picks up all the records where the flag is false, removes the license for the
    		corresponding users and sets the flag to true.

*/

public class PSA_LicenseDeprovisionBatch implements Database.Batchable<sObject>,Database.Stateful {
	
	String query;
	static String PACKAGE_NAMESPACE_PREFIX = 'pse';	
    //public Integer count;
    public PackageLicense pl;
	public List<String> contactIDs;
	//PSA_Settings__c EnggEmail = PSA_Settings__c.getInstance('Engineering Team Email');  
	//String fromEmailAddress = PSA_Settings__c.getInstance('FromEmailAdress').Value__c.trim();  

    PSA_Common_Setting__mdt EnggEmail = [select Value_Long__c from PSA_Common_Setting__mdt where Name__c='Engineering Team Email' limit 1];
    String fromEmailAddress = [select Value_Long__c from PSA_Common_Setting__mdt where Name__c='FromEmailAdress'  limit 1].Value_Long__c;

    String orgWideEmailId = [select Id from OrgWideEmailAddress where Address= :fromEmailAddress limit 1].Id;    
	public PSA_LicenseDeprovisionBatch() {
		//count = 0;
        contactIDs = new List<String>();
	}
	
	public Database.QueryLocator start(Database.BatchableContext BC) {
	
		set <String> LicensedusersToRemove = new set <String> ();
		pl = [SELECT Id FROM PackageLicense WHERE NamespacePrefix = :PACKAGE_NAMESPACE_PREFIX];      
		query = 'select Id, License_removed__c ,User__c   from PSA_License_DeProvisioned_User__c where License_removed__c = false ' ;
        return Database.getQueryLocator(query);
	}

   	public void execute(Database.BatchableContext BC, List<sObject> scope) {
		
        List <PSA_License_DeProvisioned_User__c> licenses = (List<PSA_License_DeProvisioned_User__c>)scope;
        List <id> userIDs = new List <id>();
        for (PSA_License_DeProvisioned_User__c license : licenses)
        {
            userIDs.add(license.User__c);
        }
        
        for (User LicenseUser : [select Id, AKAM_User_ID__c, Profile.Name  from User where id in :userIDs])
        {
	        contactIDs.add(LicenseUser.AKAM_User_ID__c); 
            //userIDs.add(LicenseUser.id);
        }
        List <UserPackageLicense> licensesToDelete = new List <UserPackageLicense>();
        licensesToDelete = [select id from UserPackageLicense where PackageLicenseId = :pl.Id and userid in :userIDs];
        
        try
        {
        	Database.delete(licensesToDelete,false);    
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
         //   email1.setPlainTextBody('Hi Team'  + '\n\n There was as error in deleting the UserPackageLicense records: ' + e.getMessage());
         //   mailsToBeSent1.add(email1);
         //   Messaging.sendEmail(mailsToBeSent1,false);

         PSA_AutoCreateProjectUtil.sendErrorMails(' Error in deleting the UserPackageLicense records: ',e.getMessage());
            
        }
        //count += users.size();
    }
	
	public void finish(Database.BatchableContext BC) {
        //AsyncApexJob a =[SELECT Id, NumberOfErrors, JobItemsProcessed,TotalJobItems FROM AsyncApexJob WHERE Id =:BC.getJobId()];
        //List<String> sendTo = new List<String>();
        //List<Messaging.SingleEmailMessage> mailsToBeSent = new List<Messaging.SingleEmailMessage>();
        //sendTo.add('shprasan@akamai.com');
        //Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();      
        //email.setToAddresses(sendTo);
        //email.setSubject('user count');
        //email.setPlainTextBody( 'The batch Apex job to delete user license records processed ' + a.TotalJobItems +' batches with '+ a.NumberOfErrors + ' failures. count = ' + count + ' the contact size: ' + contactIDs.size());
        //mailsToBeSent.add(email);
        //Messaging.sendEmail(mailsToBeSent,false);
        
		PSA_BusinessContactUpdateBatch contactUpdateBatch = new PSA_BusinessContactUpdateBatch();
        contactUpdateBatch.AkamContactIDs = contactIDs;
        Database.executeBatch(contactUpdateBatch);
	}
	
}