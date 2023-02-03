/********

Author: Sharath Prasanna
Created Date: July 8 2021
Description: This is a One time Batch job to inactivate the existing ACRs that get created on enabling ACR
*/

public without sharing class SC_Jarvis_AccountContactRelation_Batch implements Database.Batchable<sObject>,Database.Stateful{

    public String query;
    public Integer count;
    List<String> akamAccountIds;
    public SC_Jarvis_AccountContactRelation_Batch(List<String> akamAccountIds) {
        count = 0;
        this.akamAccountIds = akamAccountIds;
    }

	public Database.QueryLocator start(Database.BatchableContext BC) 
    {
		query = 'select Account.Akam_Account_Id__c, AKAM_Account_Contact_Id__c,  Contact.Akam_Contact_Id__c, Id, IsActive from AccountContactRelation where IsActive = true and Application__c != \'JARVIS\'';

        if(akamAccountIds != null && akamAccountIds.size() > 0)
        {
            query += ' and Account.Akam_Account_Id__c in :akamAccountIds';
        }
        if(System.Test.isRunningTest()) 
            query =  'select Account.Akam_Account_Id__c, AKAM_Account_Contact_Id__c,  Contact.Akam_Contact_Id__c, Id, IsActive from AccountContactRelation limit 10';
        
		return Database.getQueryLocator(query);
	}
    public void execute(Database.BatchableContext BC, List<sObject> scope) 
    {
        List<AccountContactRelation> accountContactRecords = (List<AccountContactRelation>) scope;
        List<AccountContactRelation> recordsToUpdate = new List<AccountContactRelation>();
        for(AccountContactRelation accountContactRec : accountContactRecords)
        {
            accountContactRec.IsActive = false;
            accountContactRec.AKAM_Account_Contact_Id__c = accountContactRec.Account.Akam_Account_Id__c + 
            accountContactRec.Contact.Akam_Contact_Id__c;
            recordsToUpdate.add(accountContactRec);
        }

        if(recordsToUpdate.size() > 0)
        {
            update recordsToUpdate;
        }

        count += recordsToUpdate.size();
    }

	public void finish(Database.BatchableContext BC) 
    {

		List<Messaging.SingleEmailMessage> mailsToBeSent = new List<Messaging.SingleEmailMessage>();
        List<String> sendTo = new List<String>{'shprasan@akamai.com'};
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();      
        email.setReplyTo('noreply@akamai.com');
        email.setToAddresses(sendTo);
        email.setSubject('ACR one time batch complete');
        email.setPlainTextBody('Processed : ' + count + ' Records');
        mailsToBeSent.add(email);
        Messaging.sendEmail(mailsToBeSent,false);
		
        database.executeBatch(new SC_JarvisDatafixJob(akamAccountIds));
	}

}