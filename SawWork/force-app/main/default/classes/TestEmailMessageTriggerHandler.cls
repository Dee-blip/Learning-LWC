/*****************************************************************************
 * Name             : TestEmailMessageTriggerHandler
 * Created By       : Vinod
 * Created Date     : June 4,2013
 * Purpose          : Test Class for the trigger EmailMessageTrigger and class EmailMessageTriggerHandler
 * 23-Apr-14        : avidapan - Optimization of test class
 
|  HISTORY  |                                                                            

|  DATE             DEVELOPER        CR/JIRA          DESCRIPTION                                                       

|  ===========      =========        =======     	============== 
                                    
|  	20-July-2020    Komal Dwivedi    ESESP-3929    - Set seeAllData = false
												   - Added testsetup method
|	16 Dec 2020		Sharath Prasanna ESESP-4435		Added method to cover the email validation code	
|   07 Feb 2022		Sheena Bhan		 ESESP-6229		Added method to cover default Task Loe on SOCC Cases
|	05 March 2022	Sheena Bhan		 ESESP-5143		Added testInternalAMGCustSurveys to cover Internal AMG Surveys functionality
 *********************************************************************************************************/
 
@isTest(seeAllData=false)
private class TestEmailMessageTriggerHandler {

    @testSetup static void setup() {
        utilTestClass.createCustomSettings();
        Account acc = utilTestClass.CreateAccount('Test AMG');
        acc.Type = 'Direct Customer - Active';
        acc.Support_Level__c = 'Premium';
        insert acc;
        
        Contact con = utilTestClass.CreateContact('Test','Contact');
        con.AccountId = acc.id;
        con.email='abcd@test.com';
        insert con;

    }
    static testMethod void testUpdateCaseResolutionSent() {
        
        test.startTest();
        Map<String, Schema.RecordTypeInfo> rtMap = Case.sObjectType.getDescribe().getRecordTypeInfosByName();       
        Case cs = new Case();
        cs.RecordTypeId = rtMap.get('Technical').getRecordTypeId();
        cs.Status = 'Unassigned';
        cs.Origin = 'Email';
        cs.ProductPL__c = 'Alta';
        cs.Resolution_Sent__c = false;
        insert cs;     
        EmailMessage[] newEmail = new EmailMessage[0]; 
        newEmail.add(new EmailMessage(FromAddress = 'test@akamai.com', Incoming = false, ToAddress= 'hello@670ocglw7xhomi4oyr5yw2zvf.8kp7yeag.8.case.salesforce.com', Subject = 'Test email', TextBody = 'hello this a test email Type: RESNOT ', ParentId = cs.Id));
        Database.insert(newEmail);  
        test.stopTest();    
    }
    
      static testMethod void test_soccmetrics()
    {
        Id usrId = Userinfo.getUserId(); 
        //Insert Account
        Account acc = utilTestClass.CreateAccount('test SOCCMetricAccount');
        insert acc;
        
        Test.startTest();
        
        //Insert Case
        Id rectypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Managed Security').getRecordTypeId();
        Case objCase = new Case();
        objCase.AccountId = acc.id;
        objCase.Subject = 'Test';
        objCase.Description = 'Test';
        objCase.Origin = 'Email';
        objCase.RecordTypeId = rectypeId;
        insert objCase;
        
        //Insert an email message for IR Calculation
        EmailMessage[] newEmail = new EmailMessage[0]; 
        newEmail.add(new EmailMessage(FromAddress = 'test@akamai.com', Incoming = false, ToAddress= 'tea@xyz.com', Subject = 'Test email', TextBody = 'hello this a test email Type: RESNOT ', ParentId =objCase.Id));
        Database.insert(newEmail); 
        
        Test.stopTest();
        
        //Insert another email for FU Metric Calculation
        EmailMessage[] newEmail2 = new EmailMessage[0]; 
        newEmail2.add(new EmailMessage(FromAddress = 'test@akamai.com', Incoming = false, ToAddress= 'tea@xyz.com', Subject = 'Test email', TextBody = 'hello this a test email Type: RESNOT ', ParentId =objCase.Id));
        Database.insert(newEmail2);  
        
    }
    
   static testMethod void test_soccrecentupdate()
    {
        User usrobj = [Select Id,Name from User where Name = 'CRM Ops' limit 1];
        
        //Insert Account
        Account acc = utilTestClass.CreateAccount('test SOCCMetricAccount');
        insert acc;
        
        //Insert Case
        system.runAs(usrobj)
        {
            Id rectypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Managed Security').getRecordTypeId();
            Case objCase = new Case();
            objCase.AccountId = acc.id;
            objCase.Subject = 'Test';
            objCase.Description = 'Test';
            objCase.Origin = 'Email';
            objCase.RecordTypeId = rectypeId;
            insert objCase;
            
            //Insert an email message for IR Calculation
            EmailMessage[] newEmail = new EmailMessage[0]; 
            newEmail.add(new EmailMessage(FromAddress = 'test@akamai.com', Incoming = true, ToAddress= 'tea@xyz.com', Subject = 'Test email', TextBody = 'hello this a test email Type: RESNOT ', ParentId =objCase.Id));
            Database.insert(newEmail); 
            
            //Insert another email Message
            
            Test.startTest(); //new set of governor limits
            EmailMessage[] newEmail2 = new EmailMessage[0]; 
            newEmail2.add(new EmailMessage(FromAddress = 'test1@akamai.com', Incoming = false, ToAddress= 'tea2@xyz.com', Subject = 'Test email', TextBody = 'hello this a test email Type: RESNOT ', ParentId =objCase.Id));
            Database.insert(newEmail2);
            Test.stopTest();
            
            
        }
        
    }
    
    //ESESP-2698
    static testMethod void test_soccRecentUpdateSOOCNonSOCC()
    {
        //Create a new user with Managed Security Profile
        User u = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Managed Security – SOC'].Id,
            LastName = 'lastsocc',
            Email = 'soccemailtest@akamai.com',
            Username = 'soccemailtest@xyz.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
        
        //Create a Managed Security Case
        //Insert Account
        Account acc = utilTestClass.CreateAccount('test SOCCMetricAccount2');
        insert acc;
        
        //Insert Case
        Id rectypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Managed Security').getRecordTypeId();
        Case objCase = new Case();
        objCase.AccountId = acc.id;
        objCase.Subject = 'Test';
        objCase.Description = 'Test';
        objCase.Origin = 'Email';
        objCase.RecordTypeId = rectypeId;
        insert objCase;
        
        Test.startTest();
        //Create an Inbound Email Message
        EmailMessage[] newEmail = new EmailMessage[0]; 
        newEmail.add(new EmailMessage(FromAddress = 'soccemailtest@akamai.com', Incoming = true, ToAddress= 'tea@xyz.com', Subject = 'Test email', TextBody = 'hello this a test email Type: RESNOT ', ParentId =objCase.Id));
        Database.insert(newEmail); 
        Test.stopTest();
    }
    
    //ESESP-1702 : Order Approval Test 
    //modified the method to avoid the insufficient access error: By Sharath for ESESP-4435
    static testMethod void test_OACaseStatusUpdates()
    {
        User omUser = [Select id from User where profile.name  = 'SA - Manager' and isactive = true limit 1];
        
        Account thisAccount = utilTestClass.CreateAccount('Test Account for OA');           
        insert thisAccount;
                
        Opportunity opp = utilTestClass.CreateOpportunity('Test Opportuniry for OA','1. Identify Need');
        opp.AccountId = thisAccount.Id;
        opp.CloseDate = Date.today().addMonths(4);
        opp.Validation_Override__c = true;
        insert opp;
        
        Order_Approval__c thisOA = new Order_Approval__c();
        thisOA.Associated_Opportunity__c = opp.id;
        thisOA.Validation_Override__c = true;
        insert thisOA;
        
        Case thisCase = new Case();
        thisCase.Description = 'testPS1';
        thisCase.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Order Approval-Deal Desk').getRecordTypeId();
        thisCase.Subject = 'testS2ET1';
        thisCase.Service__c = 'Managed Integration';
        thisCase.Validation_Override__c = true;
        thisCase.AccountId = thisAccount.Id;
        thisCase.Opportunity__c = opp.Id;
        thisCase.Order_Approval__c = thisOA.id;
        //insert thisCase;
        
        Test.startTest();
        //Create an Inbound Email Message
        
        System.runAs(omUser){
            EmailMessage[] newEmail = new EmailMessage[0]; 
            newEmail.add(new EmailMessage(FromAddress = 'sf-approvalcases@akamai.com', Incoming = true, ToAddress= 'tea@xyz.com', Subject = 'Test email', TextBody = 'hello this a test email Type: RESNOT ', ParentId =thisCase.Id));
            Database.insert(newEmail); 
            
            insert thisCase;
            thisCase.Status = 'Closed-Approved';
            update thisCase;
        }
        EmailMessage[] newCloseEmail = new EmailMessage[0]; 
        newCloseEmail.add(new EmailMessage(FromAddress = 'sf-approvalcases@akamai.com', Incoming = true, ToAddress= 'tea@xyz.com', Subject = 'Test email', TextBody = 'hello this a test email Type: RESNOT ', ParentId =thisCase.Id));
        Database.insert(newCloseEmail); 
        Test.stopTest();
    }
    
    static testMethod void test_plxCase()
    {
        Id usrId = Userinfo.getUserId();
        
        //Insert Account
        Account acc = utilTestClass.CreateAccount('test PlxAccount');
        insert acc;
        
        //Insert Case
        Id rectypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();
        Case objCase = new Case();
        objCase.AccountId = acc.id;
        objCase.Subject = 'Test';
        objCase.Description = 'Test';
        objCase.Origin = 'Email';
        objCase.Service__c = 'Managed Integration';
        objCase.RecordTypeId = rectypeId;
        insert objCase;
        

        Test.startTest();
        //Insert an email message for IR Calculation
        EmailMessage[] newEmail = new EmailMessage[0]; 
        newEmail.add(new EmailMessage(FromAddress = 'test@akamai.com', Incoming = false, ToAddress= 'tea@xyz.com', Subject = 'Test email', TextBody = 'hello this a test email Type: RESNOT ', ParentId =objCase.Id));
        Database.insert(newEmail); 
        
        //Insert another email for FU Metric Calculation
        EmailMessage[] newEmail2 = new EmailMessage[0]; 
        newEmail2.add(new EmailMessage(FromAddress = 'test@akamai.com', Incoming = true, ToAddress= 'tea@xyz.com', Subject = 'Test email', TextBody = 'hello this a test email Type: RESNOT ', ParentId =objCase.Id));
        Database.insert(newEmail2);  
        
        Test.stopTest();
        
        
    }
    //Covers the validateEmailMessageRecords method
    static testMethod void testValidation()
    {
        Id usrId = Userinfo.getUserId();
        
        //Insert Account
        Account acc = utilTestClass.CreateAccount('test PlxAccount');
        insert acc;
        
        //Insert Case
        Id rectypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();
        Case objCase = new Case();
        objCase.AccountId = acc.id;
        objCase.Subject = 'Test';
        objCase.Description = 'Test';
        objCase.Origin = 'Email';
        objCase.Service__c = 'Managed Integration';
        objCase.RecordTypeId = rectypeId;
        insert objCase;
        

        Test.startTest();
            Contact thisContact = utilTestClass.CreateContact('firstName','lastName');
            thisContact.AccountId = acc.id;
        	thisContact.email='abc@test.com';
            thisContact.Akam_Contact_Id__c = 'F-CO-2435149';
            insert thisContact;
        
            EmailMessage[] newEmail = new EmailMessage[0]; 
            newEmail.add(new EmailMessage(FromAddress = 'test@akamai.com', Incoming = false, ToAddress= 'abc@test.com',bccAddress= 'abc@test.com',CcAddress= 'abc@test.com', Subject = 'Test email', TextBody = 'hello this a test email Type: RESNOT ', ParentId =objCase.Id));
            Database.insert(newEmail); 
            
        	EmailMessageTriggerHandler.validateEmailMessageRecords(new Map<Id, case>{objCase.Id => objCase},newEmail);
        Test.stopTest();
        
        
    }
        
    // Test method for default Task Loe values on Managed Security Cases
    public static testMethod void testCalculateSOCCCaseLOE()
    {
        User usrobj = [Select Id,Name from User where Name = 'CRM Ops' limit 1];
        system.runAs(usrobj)
        {
        
        //Create Case
        Case newCase = new Case();
        newCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Managed Security').getRecordTypeId();
        newCase.Subject = 'Test Case';
        newCase.Status = 'Unassigned';
        newCase.Origin = 'Email';
        insert newCase;
        Test.startTest();

        // Create  Loe Tracking Template Records
        List<LOE_Tracking_Template__c> tempList = new List<LOE_Tracking_Template__c>();
        
        LOE_Tracking_Template__c tempRec = new LOE_Tracking_Template__c();
        tempRec.Name='Default Email Template LOE';
        tempRec.LOE_Hours__c=1;
        tempList.add(tempRec);
        
        LOE_Tracking_Template__c tempRec2 = new LOE_Tracking_Template__c();
        tempRec2.Name='BMP01 - IR, EVENT INIT';
        tempRec2.LOE_Hours__c=2;
        tempList.add(tempRec2);
        
        Insert tempList;
                
        String templateId = [Select Id from EmailTemplate where Name='BMP01 - IR, EVENT INIT' limit 1].Id;

        Map<EmailMessage, Case> emailMessageCaseMap = new  Map<EmailMessage, Case>();
        Map<Id,Id> activityIdTemplateIdMap = new Map<Id,Id>();
        
        EmailMessage[] newEmail = new EmailMessage[0]; 
        newEmail.add(new EmailMessage(FromAddress = 'test@akamai.com', Incoming = false, ToAddress= 'abc@test.com', Subject = 'Test email', TextBody = 'hello this a test email', ParentId = newCase.Id));
        Database.insert(newEmail);
        
        EmailMessage em = [Select id, ActivityId from EmailMessage limit 1];

        emailMessageCaseMap.put(newEmail[0], newCase);
        activityIdTemplateIdMap.put(em.ActivityId, templateId);
        EmailMessageTriggerHandler.calculateSOCCCaseLOE(emailMessageCaseMap,activityIdTemplateIdMap);
        Test.stopTest();
        }
    }
    
    // Test method for customer surveys on internal AMG Cases
    public static testMethod void testInternalAMGCustSurveys()
    {
        Account acc = [Select id,Account_Status__c, Support_Level__c from Account where Name='Test AMG'];
        Contact con = [Select id, Name, AccountId, email, Active_Portal_Login__c, Last_Time_Contact_Surveyed__c,No_Longer_with_Company__c  from Contact where name = 'Test Contact'];
        
        Test.startTest();
        User amgUser = [Select id,email from user where profile.name like '%Support - AMG%' and email !='' limit 1]; 
        //Case Creation
        List<Case> caseList = new List<Case>();
        Case cs = new Case();
        cs.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('AMG').getRecordTypeId();
        cs.AccountId = acc.Id;
        cs.Subject = 'Test Case';
        cs.Status = 'Unassigned';
        cs.Origin = 'Akamai';
        cs.Service__c = 'Contract Management';
        cs.Request_Type__c = 'Contract Update';
        cs.Resolution_Sent__c = false;
        cs.Do_Not_Show_In_Portal_Picklist__c = 'Internal Only';
        cs.OwnerId = amgUser.Id;
        caseList.add(cs);
        
        Case cs2 = new Case();
        cs2.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('AMG').getRecordTypeId();
        cs2.AccountId = acc.Id;
        cs2.Subject = 'Test Case';
        cs2.Status = 'Unassigned';
        cs2.Origin = 'Email';
        cs2.Service__c = 'Contract Management';
        cs2.Request_Type__c = 'Contract Update';
        cs2.Resolution_Sent__c = false;
        cs2.Do_Not_Show_In_Portal_Picklist__c = 'Internal Only';
        cs2.OwnerId = amgUser.Id;
        cs2.Internal_Case_Survey_Enabled__c = true;
        caseList.add(cs2);
        insert caseList;
        
       
        // Insert Email Message
        EmailMessage[] newEmail = new EmailMessage[0]; 
        newEmail.add(new EmailMessage(FromAddress = amgUser.Email, Incoming = false, ToAddress= 'abcd@test.com', Subject = 'Test email', TextBody = 'hello this a test email', ParentId = cs.Id));
        Database.insert(newEmail);
        Test.stopTest(); 
        EmailMessage[] newEmail2 = new EmailMessage[0]; 
        newEmail2.add(new EmailMessage(FromAddress = amgUser.Email, Incoming = false, ToAddress= 'abcd@test.com', Subject = 'Test email', TextBody = 'hello this a test email', ParentId = cs2.Id));
        Database.insert(newEmail2);
        

    }    
    
}