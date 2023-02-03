/***
    InformaticaPhoneValidationBatchJob
    @author : Shivam Verma <shiverma@akamai.com>
    @Description : 
   
    @History
    --Developer           --Date            --Change
    Shivam Verma          25/05/2015        Created the class.
***/
global class InformaticaPhoneValidationJob implements Database.Batchable<sObject>,Database.Stateful, Database.AllowsCallouts
{

    /*global Integer failedUpdates;
     global List<String> errorString ;
     global Boolean errorFlag {get;set;}
     public static Boolean nowRunningDataFix =false;*/
     
     global InformaticaPhoneValidationJob()
     {
         /*failedUpdates = 0;
         errorFlag = false;
         nowRunningDataFix = false;
         errorString = new List<String>();*/
     }
     
     global Database.QueryLocator start(Database.BatchableContext BC)
     {
         Date dateValue = System.today().addDays(-1);
         
         return Database.getQueryLocator([select Id,Phone_Verified_By_StrikeIron__c,Phone_Status_Code__c,
                                            Phone_Status_Description__c,phone,FirstName,LastName
                                           from Contact where Phone_Verified_By_StrikeIron__c = false and
                                                            (CreatedDate >:dateValue OR lastModifiedDate >:dateValue) AND
                                                            MailingCountry IN ('USA','US','United States of America','Canada','United States')]);
     }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope)
    {
        
        /*nowRunningDataFix = true; 
        List<Contact> contactsList = (List<Contact>)scope;
        System.debug('Total Number of Contacts : '+contactsList.size());
        
        //List<Contact> listOfContacts = new List<Contact>();
        List<Contact> listOfContactsToUpdate = new List<Contact>();
        
        //listOfContactsToUpdate = InformaticaContactPhoneVerification.updatePhoneRelatedInfoForContact(listOfContacts);
        listOfContactsToUpdate = InformaticaContactPhoneVerification.updatePhoneRelatedInfoForContact(contactsList,logRecord);

        try {
            update listOfContactsToUpdate;
        }
        catch(DmlException e) {
        }
        try {
            insert logRecord;
        }catch (DMLException e) {
        }*/
    }
   
    global void finish(Database.BatchableContext BC)
    {
        
    }
}