/***
    InformaticaEmailVerificationJob
    @author : Shivam Verma <shiverma@akamai.com>
    @Description : 
   
    @History
    --Developer           --Date            --Change
    Shivam Verma          15/05/2015        Created the class.
***/
global class InformaticaEmailValidationJob implements Database.Batchable<sObject>,Database.Stateful,Database.AllowsCallouts
{

    /*global Integer failedUpdates;
     global List<String> errorString ;
     global Boolean errorFlag {get;set;}
     public static Boolean nowRunningDataFix =false;*/
     
     global InformaticaEmailValidationJob()
     {
         /*failedUpdates = 0;
         errorFlag = false;
         nowRunningDataFix = false;
         errorString = new List<String>();*/
     }
     
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
      Date dateValue = System.today().addDays(-1);
      return Database.getQueryLocator([select Id,
                                            Email,
                                            phone,
                                            FirstName,
                                            LastName,
                                            Phone_Verified_By_StrikeIron__c,
                                            Email_Verified_by_StrikeIron__c
                                        From Contact 
                                        Where (Email_Verified_by_StrikeIron__c = false OR Phone_Verified_By_StrikeIron__c = false)  AND
                                              (CreatedDate >:dateValue OR lastModifiedDate >:dateValue)]);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope)
    {
        /*List<Email_and_Phone_Verification__c> verificationRecords = new List<Email_and_Phone_Verification__c>();
        
        /* Getting the list of contact records to be updated - Where the Email is not null and nt verified by Address Doctor
        */
        /*String email;
        String[] temp;
        nowRunningDataFix = true; 
        List<Contact> contactsList = (List<Contact>)scope;
        List<Contact> contactsListAfterDomainFilter = new List<Contact>();
        String delimeter = '@';
        for (Contact c:contactsList) {
            if (c.Email_Verified_by_StrikeIron__c = false && c.Email != null && c.Email != null) {
                email = c.email;
                temp = email.split(delimeter);
                if (temp[1] != 'akamai.com') {
                        contactsListAfterDomainFilter.add(c);
                }
            }
        }
        /* Getting the address doctor response for the Contact records. 
        */
        /*verificationRecords = InformaticaContactEmailVerification.updatEmailRelatedInfoForContact(contactsListAfterDomainFilter);

        List<Contact> contactsListForPhone = new List<Contact>();
        for(Contact c:contactListForPhone) {
            if ((c.MailingCountry == 'USA' OR c.MailingCountry == 'Canada') && c.Phone_Verified_By_StrikeIron__c = false)
                contactsListForPhone.add(c);
        }
        System.debug('Total Number of Contacts : '+contactsListForPhone.size());
        
        List<Email_and_Phone_Verification__c> verificationRecordsForPhone = new List<Email_and_Phone_Verification__c>();

        verificationRecordsForPhone = InformaticaContactPhoneVerification.updatePhoneRelatedInfoForContact(contactsListForPhone);
        verificationRecords.add(verificationRecordsForPhone);
        try {
            upsert verificationRecords;
        }
        catch(DmlException e) {
            System.debug('Update Error :'+e.getMessage());
        }*/
        
    }
   
    global void finish(Database.BatchableContext BC)
    {
        
    }
}