@isTest
public class MARIT_MarketoActivityTests{
  
   public static testMethod void testMarketoActivity() {   
       
       Id marketoRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
       User testMarketoSyncUser = [select id from User where name= 'Marketo SyncUser'];
       Datetime yesterday = Datetime.now().addDays(-1);
       
       Account testAccount = utilTestClass.CreateAccount('Test Account1');
       insert testAccount;
       
       Lead testLead = new Lead();
       testLead.CreatedById = testMarketoSyncUser.Id;
       testLead.RecordTypeId = marketoRecordTypeId;
       testLead.Associated_Account__c = testAccount.Id;
       testLead.email = 'test01@akamai.com';
       testLead.status = 'New';
       testLead.CurrencyIsoCode = 'USD';
       testLead.company = 'Test Company01';
       testLead.firstname = 'Test';
       testLead.lastname = 'Lead1';
       testLead.website = 'testwebsite.com';
       insert testLead;
       test.setCreatedDate(testLead.Id, yesterday);
       Lead onjL = [Select Id, CreatedDate, CreatedById from Lead where Id = :testLead.Id];
       System.debug('Test marketo lead: '+ onjL.CreatedById + ' ' + onjL.CreatedDate );
       test.starttest();
       MARIT_MarketoActivity testActivity = new  MARIT_MarketoActivity();   
       testActivity.execute(null);
       test.stopTest();
       List<Marketo_Activity_Details__c> detailsList = [Select Id, Object_Type__c, Count_Of_Records__c from Marketo_Activity_Details__c where Object_Type__c = 'Marketo Lead'];
       System.assertEquals(1, detailsList[0].Count_Of_Records__c, 'Count of marketo activity should be 1');
    }
}