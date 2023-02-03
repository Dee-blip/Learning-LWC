//Modified By: ssawhney on 29/08/2013 CR 2137582 - Survey Opt Out functionality changed
@isTest
private class CS_EligibleContacts_TestClass {

  static CS_Survey__c survey;
    static CS_SurveyAccount__c surveyAccount;
    static CS_SurveyContacts__c surveyContact;
    static Account account1;
    static Account account2;
    static Contact contact1;
    static Contact contact2;
    static Contact contact3;
    static Contact contact4;
    static String accountName = 'TestAccount';
    static String surveyName = 'SQ-Test-Survey';
    static String surveyType = 'CSAT';
    static String surveyStatus = 'Active';
    static String surveyOpenedDate = '12/4/2012';
    static List<Contact> contactList; 
    
    /*
     Author : Sharath K
     Description: This method initialises data. CR
     Created Date: 16/4/2012
    */ 
    static void init() 
    {
    ManagedPkgErrorClass.isFromManagedPackage=false;
        survey = CS_InitializeObjects.createSurvey(surveyName,surveyType,surveyStatus,surveyOpenedDate);
        insert survey;
        
        account1 = CS_InitializeObjects.createAccount('acc1');
        account1.Survey_Group__c = '1 - Feb/Aug';
        account1.Type = 'Direct Customer - Active';
        account1.Vertical__c = 'Business Services';
        insert account1;
        
        account2 = CS_InitializeObjects.createAccount('acc2');
        account2.Survey_Group__c = '2 - May/Nov';
        account2.Type = 'Direct Customer - Active';
        account2.Vertical__c = 'Business Services';
        insert account2;
        
        contactList = new List<Contact>();
        
        contact1 = CS_InitializeObjects.createContact('Test', 'Test1', account1.Id, 'A-Test');
        contact1.Survey_Opt_Out__c = true;
        contactList.add(contact1);
        
        contact2 = CS_InitializeObjects.createContact('Test', 'Test2', account1.Id, 'A2-Test');
        contact2.Survey_Opt_Out__c = true;
        contactList.add(contact2);
        
        contact3 = CS_InitializeObjects.createContact('Test', 'Test1', account2.Id, 'B-Test');
        contact3.Survey_Opt_Out__c = true;
        contactList.add(contact3);
        
        contact4 = CS_InitializeObjects.createContact('Test', 'Test2', account2.Id, 'B2-Test');
        contact4.Survey_Opt_Out__c = true;
        contactList.add(contact4);
        insert contactList;
         
        CSAT_CustomSettings__c testValue = CSAT_CustomSettings__c.getInstance('EligibleContactsPerPage');
        testValue.CSAT_Value__c = '10';
        update testValue;
    }
    
    static testMethod void myUnitTest() {
      init();
      PageReference pg = new PageReference('apex/CS_VfpEligibleCustomerList?acct_id=' + account1.Id);
      Test.setCurrentPage(pg);
      Test.startTest();
      CS_EligibleCustomerListViewController controller = new CS_EligibleCustomerListViewController();
      
      
      //search for a different account on the page
      Contact c = controller.getContactForAccSearch();
      c.AccountId = account2.Id;
      controller.doNothing();
      
      //get the flags of the rendered buttons on the page
      system.assertEquals(controller.getDisplayStyle(),'display:none');
      system.assertEquals(controller.getDisplayMassStyle(),'display:block');
      system.assertEquals(controller.getRenderMassEdit(),false);
      
      // simulate clicking the edit button
      controller.showMassEdit();
      system.assertEquals(controller.getDisplayStyle(),'display:block');
      system.assertEquals(controller.getDisplayMassStyle(),'display:none');
      system.assertEquals(controller.getRenderMassEdit(),true);
      controller.cancel();
      
      //simulate marking a contact as survey Opt Out
      controller.showMassEdit();
      Contact dc = controller.getDummyContact();
      dc.Survey_Opt_Out__c = true;
      dc.CS_SurveyOptOutReason__c = 'Contact Opted Out';
      List<CS_ContactWrapper> contacts = controller.getContactRecords();
      contacts[0].selected = true;
      controller.save();
      controller.first();
      controller.last();
      controller.previous();
      controller.next();
      Test.stopTest();
        // TO DO: implement unit test
    }
}