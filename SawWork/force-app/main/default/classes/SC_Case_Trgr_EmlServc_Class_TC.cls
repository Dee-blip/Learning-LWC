/*=====================================================================================================+
    Class name          :   SC_Case_Trgr_EmlServc_Class_TC 
    Author              :   Himanshu Kar
    Created             :   04-Jul-13
    Purpose             :   This test class is used to cover code for below Components
                            1. AutoGen Cases
                            2. Alert Case Maker
                            3. NIE
                            4. GSSActiveContractsCon
                            5. GSSInactivecontractsCon
                            6. Siebel Bridge
                            7. Smart Email Template
    Last Modified    Developer  Purpose            
    =============    =========  =======
    07-Dec-13        Himanshu   Initial Development 
    12-Mar-14        Himanshu   Optimize the Test class(3.39 Release) 
    23-05-14         Akhila     Added test case for Manual Subscription(NotificationTeam)
    24-09-14         Aditya     Added test case for default email template in Answer Customer widget
    04-12-14         Akhila     Added test cases for New Home Screen controllers
    04-05-2015       Akhila     Added test cases for UserTrigger_bi_bu
    30-Jul-15        Akhila     Added test Case for EPE-Home Page
    16-Nov-15        Vamsee     Added test Case for HomePagectrlv2
    02-may-16        Vamsee     Added test case for case transition
    05-Aug-16        Vamsee     Added test case for Special Instructions
    06-Sep-16        Aditya     Added test cases for CPS 
    05-Jan-17        Vamsee     Code Coverage Improvement
    31-Jan-17       Pinkesh     CR 3622181 Added test cases for SCEmailCaseTeamCtrl and SC_Utility
    27-Apr-17       Pinkesh     JIRA ESESP-542   - Added case transition feature for BOCC
    1-May-2017      Vandhana    JIRA ESESP-564 : Increase Code Coverage
    30-May-2017     Pinkesh     JIRA ESESP-591 : Increase Code Coverage
    09-Aug-2017     Aditya      JIRA ESESP-627 : Case Product Widget Code Coverage
    03-Oct -2017     Aditya      ESESP-435 -NQLB Code Coverage
    26-Dec-2017     Vikas        ESESP-822 Added test case for "SC_CaseTriggerHelperClass"
    08-Feb-2019     Vamsee       ESESP-1773 : Lightning Knowledge Migration
    03-Apr-2019     Supreeth   ESESP-2086 : Special Instructions Lightning - Lightning Knowledge Migration
  23-May-2020   Vamsee     ESESP-3567 : Removed BOCC References
  09-Sep-2020   Harshil    ESESP-4125 : Added method to cover UserTrigger_bi_bu changes for DR Sync job 
  05-Oct-2020   Tejaswini    ESESP-4020 : Set seeAllData = false , added testSetup method
  02-Jan-2021   Aditi Singh  ESESP-4697 : Made changes to the test method CPSTestMethod() to include changes done by me as part of this ticket
  04-April-2021   Aditi Singh  ESESP-5022 : Updated this test class to resolve fast deploy errors
  11-May-2021    Tejaswini      Added AuthContactTest method to fix fast deploy errors and made changes in CPSTestMethod()
  07-Feb-2022	 Sheena			Added testInternalAMGCustSurveys to cover Internal AMG Surveys functionality
  31-May-2022	Saiyam			ESESP-5957 : Added Case transition feature for BOCC
+============================================================================================================*/

@isTest
public class SC_Case_Trgr_EmlServc_Class_TC{
    
    /* @testSetup static void setup()
    {
  utilTestClass.createCustomSettings(); 
  utilTestClass.createData_SC_SupportEmail();
  utiltestClass.createData_SC_Serv_ReqTyp_value();
  utiltestClass.createData_SCUserIdCustomSetting();
  utiltestClass.createData_SC_Autogen_Run_Freq();
  }
  //Create Test Data variables 
  static Account accRec;
  static Merge_Contract_Header__c  merge_contract;
  static EB_AccountProductMap__c  eb_product;
  static Case csRec;
  static Contact conRec;
  static Knowledge__kav htRec;   
  static ApexPages.StandardController AccountCon;
  static GSSActiveContractsCon ActiveCon;
  static GSSInactiveContractsCon InactiveCon;*/
    
  
  //Creates the test data 
  @testSetup static void createTestData() {
  
      utilTestClass.createCustomSettings(); 
      utilTestClass.createData_SC_SupportEmail();
      utiltestClass.createData_SC_Serv_ReqTyp_value();
      utiltestClass.createData_SCUserIdCustomSetting();
      utiltestClass.createData_SC_Autogen_Run_Freq();
      utiltestClass.createData_SC_Autogen_Case_Freq();
      
      List<Account> lstAccounts = new List<Account>(); 
      List<Contact> lstContacts =new List<Contact>();  
      List<EB_AccountProductMap__c> lstAccountProduct = new List<EB_AccountProductMap__c>();
      List<Case> lcase= new List<Case>();
      
      Account accRec;
      Merge_Contract_Header__c  merge_contract;
      EB_AccountProductMap__c  eb_product;
      //Case csRec;
      Contact conRec;
      Knowledge__kav htRec; 
      ApexPages.StandardController AccountCon;
      
      User currentusr = [Select id from User where Id = :UserInfo.getUserId()];
      
      System.RunAs(currentusr)
      {
          Environment_Setup__c environmentSetup = Environment_Setup__c.getOrgDefaults();
          environmentSetup.Active_Org__c = true;
          update environmentSetup;
      }
      
      // For Account Record
      accRec = new Account(Name='Test Account1 zpxtx',AKAM_Account_ID__c='Test-111');
      lstAccounts.add(accRec);
      
      accRec = new Account(Name='Test Account IP Address',AKAM_Account_ID__c='Test-ABC-1234IPAddr',Type='Brand - Active', Is_SOCC_Premium_Customer__c = True, Parent_Division__c = 'Web Americas_Web', Division__c = 'Acquisition & ECG');
      lstAccounts.add(accRec);
      
      accRec = new Account(Name ='Test1234',Website ='www.google.com',AKAM_Account_ID__c='Test-222',Support_Level__c = 'Premium',Mailing_List_for_Technical_Case_auto_cc__c = 'adsing@akamai.com');
      lstAccounts.add(accRec);
      
      Account accRec1 = new Account(Name ='Test12345',Website ='www.google1.com',AKAM_Account_ID__c='Test-2222',Support_Level__c = 'Premium',Mailing_List_for_Technical_Case_auto_cc__c = 'adsing@akamai.com');
      accRec1.Type = 'Indirect Customer - Active';
      lstAccounts.add(accRec1);
      
      Account accRec2 = new Account(Name ='Test Account',Website ='www.google.com',Support_Level__c = 'Premium', Type='Direct Customer - Active');
      lstAccounts.add(accRec2);
            
      insert lstAccounts;
      
      // For Contract Record
      merge_contract = new Merge_Contract_Header__c(Name='Test Merge Contract',Contract_Id__c='Test-123',
                                                    Original_Contract_Id__c = 'Test-123',Account_Name__c = lstAccounts[2].Id, Contract_Type__c = 'Value Added Reseller');
      
      
      // For Case Product
      eb_product = new EB_AccountProductMap__c(Name='Test Product',EB_MarkedForDeletion__c = false,EB_Product__c='Test-456',
                                               EB_Account__c=accRec.id);
      lstAccountProduct.add(eb_product);
      
      eb_product = new EB_AccountProductMap__c (Name ='Test Prod 123', EB_Account__c = accRec.Id,EB_Product__c='Test Prod 123');
      lstAccountProduct.add(eb_product);            
      
      Profile pfl = [select id from Profile where name = 'System Administrator' limit 1];
      User usr = [select Id from User where IsActive = True and ProfileId = :pfl.Id limit 1];
      
      // For Case Record
      RecordType rectype= [select id from RecordType where sObjectType='Case' and Name='Technical' and isActive=true limit 1];    // For Case Record
      id communityResponseRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Community Response').getRecordTypeId();
      
      Case csRec = new Case(subject='Test', description='test',Ownerid = usr.Id,AKAM_Case_ID__c='ehsdsg',
                            RecordTypeId=rectype.Id,Do_not_show_in_portal__c = true,Origin = 'Email');
      lcase.add(csRec);
      
      Case csRec1 = new Case(subject='Milestone Case', description='test',Ownerid = usr.Id,AKAM_Case_ID__c='xyz123',
                             RecordTypeId=rectype.Id,Do_not_show_in_portal__c = false,Origin = 'Email');
      lcase.add(csRec1);
      
      /*csRec = new Case(subject='Test', description='test',RecordTypeId = communityResponseRTId,Origin = 'Community',status ='Assigned',OwnerId = userInfo.getuserid());
lcase.add(csRec);
csRec = new Case(subject='Test1', description='test1',RecordTypeId = communityResponseRTId,Origin = 'Community',status ='Assigned',OwnerId = userInfo.getuserid());
lcase.add(csRec);*/
      
      
      insert merge_contract;
      insert lstAccountProduct;
      //Insert csRec;
      insert lcase;
      
      // Creating Contact Record
      conRec = new Contact(AccountId = accRec.Id, Login__c = 'Test_xyz', Email = 'Test_xyz@akamai.com',
                           No_Longer_with_Company__c = false, LastName = 'Test Contact', Primary_Contact_Method__c = 'Phone');
      lstContacts.add(conRec) ;
      
      conRec = new Contact(AccountId = accRec.Id, Login__c = 'Test_xyz', Email = 'Test_xyz1234@akamai.com',
                           No_Longer_with_Company__c = false, LastName = 'Test ContactAcc', Primary_Contact_Method__c = 'Phone');
      lstContacts.add(conRec);
      
      conRec = new Contact(AccountId = lstAccounts[2].Id, Login__c = 'Test_xyz2', Email = 'Test_xyz2@akamai.com',
                           No_Longer_with_Company__c = false, LastName = 'Test ContactAcc2', Primary_Contact_Method__c = 'Phone',Partner_Contact_Type__c = 'Services Primary');
      lstContacts.add(conRec);
      
      conRec = new Contact(AccountId = accRec2.Id, Login__c = 'Test_xyz2', Email = 'abc@test.com',
                           No_Longer_with_Company__c = false, FirstName = 'Test', LastName = 'Contact 3', Primary_Contact_Method__c = 'Phone',Partner_Contact_Type__c = 'Services Primary');
      
      lstContacts.add(conRec);
      
      
      Insert lstContacts;
      
      // create a new Account standard controller by passing the account record
      AccountCon = new ApexPages.StandardController(accRec);
      
      
      
      
      
      
      Special_Instruction_Template__c splInstrTemp = new Special_Instruction_Template__c();
      splInstrTemp.Instructions__c = 'test';
      splInstrTemp.Show_for_Record_Types__c = 'All except Managed Security';
      splInstrTemp.Title__c = 'test';
      splInstrTemp.name = 'test';
      splInstrTemp.Flag_Icon__c = 'Media';   
      
      insert splInstrTemp;
      
      List<Special_Instructions__c> lSplInst = new List<Special_Instructions__c>();
      
      Special_Instructions__c splInstObj = new Special_Instructions__c();
      splInstObj.Title__c = 'test1';
      splInstObj.Instructions__c = 'test1';
      splInstObj.Start_Date__c = system.today();
      splInstObj.Account__c = accRec.Id;
      splInstObj.Show_for_Record_Types__c = 'All except Managed Security';
      splInstObj.Special_Instruction_Template__c = splInstrTemp.id ;
      lSplInst.add(splInstObj);
      
      Special_Instructions__c splInstObjNoTemp = new Special_Instructions__c();
      splInstObjNoTemp.Title__c = 'test1';
      splInstObjNoTemp.Instructions__c = 'test1';
      splInstObjNoTemp.Start_Date__c = system.today();
      splInstObjNoTemp.Account__c = accRec.Id;
      splInstObjNoTemp.Show_for_Record_Types__c = 'All except Managed Security';
      lSplInst.add(splInstObjNoTemp);
      
      insert lSplInst;
      
      	/*Policy_Domain__c pdRec = new Policy_Domain__c();
        pdRec.Name = 'Test PD1';
        pdRec.AKAM_Policy_Domain_ID__c = 'Test-123';
        pdRec.Account_Name__c = lstContacts[0].AccountId;
        pdRec.Product__c = 'Test Prod 123';
        pdRec.Policy_Domain_State__c = 'Active';
        insert pdRec;*/
      
      
}
    
    
    // Method# 1 - (Issue Scenario - 1)
    @isTest static void issue_CaseTrigger_Test_a()
    {
        
        Test.StartTest();
        
        User usr = [Select id from User where Id = :UserInfo.getUserId()];
        
        System.RunAs(usr)
        {
            Environment_Setup__c environmentSetup = Environment_Setup__c.getOrgDefaults();
            environmentSetup.Active_Org__c = true;
            update environmentSetup;
        }
        RecordType rectype= [select id from RecordType where sObjectType='Case' and isActive=true limit 1];
        
        //Scenario 1 - Insert a case record with issue__c field not null
        Case CaseRec = new case();
        CaseRec.Status = 'Unassigned';
        CaseRec.Origin = 'Email';
        CaseRec.Issue__c = 'testissue';
        CaseRec.RecordTypeId = rectype.id;
        CaseRec.subject = 'testissue-Him';
        CaseRec.CP_Account_Name__c = 'A2D Technologies';
        caseRec.Case_Assignment_Using_Active_Rules__c = true;
        caseRec.Next_Action__c = 'Case Owner';
        system.debug('Case object is '+CaseRec);
        insert CaseRec;
        
        SC_CaseTriggerHelperClass.flagvalue = False;
        
         
        //Scenario 2 - Update issue__c field from Not null -> Null
        CaseRec.Issue__c = Null;
        Caserec.Case_Assignment_Using_Active_Rules__c = true;
        caseRec.Next_Action__c = 'Customer';
        update CaseRec;
        SC_CaseTriggerHelperClass.flagvalue = False;
        
        
        Test.StopTest();
        
    }
    
    // Method# 2 - (Issue Scenario - 2)
    @isTest static void issue_CaseTrigger_Test_b()
    {
        
        Test.StartTest();
        
        User usr = [Select id from User where Id = :UserInfo.getUserId()];
 
        System.RunAs(usr)
        {
            Environment_Setup__c environmentSetup = Environment_Setup__c.getOrgDefaults();
            environmentSetup.Active_Org__c = true;
            update environmentSetup;
        }
         
        RecordType rectype= [select id from RecordType where sObjectType='Case' and isActive=true limit 1];
        
        //Insert a case record with issue__c field null
        Case CaseRec = new case();
        CaseRec.Status = 'Unassigned';
        CaseRec.Origin = 'Email';
        CaseRec.Issue__c = Null;
        CaseRec.RecordTypeId = rectype.id;
        CaseRec.subject = 'testissue-Him';
        CaseRec.CP_Account_Name__c = 'A2D Technologies';
        caseRec.Next_Action__c = 'Customer';
        system.debug('Case object is '+CaseRec);
        insert CaseRec;
        
        SC_CaseTriggerHelperClass.flagvalue = False;
        
        //Scenario 3 - Update issue__c field from Null -> Not null
        CaseRec.Issue__c = 'test2issue';
        caseRec.Next_Action__c = 'Engineering';
        update CaseRec;
        SC_CaseTriggerHelperClass.flagvalue = False;
        
        Test.StopTest();
        
    }
    
    // Method# 3 - (Issue Scenario - 3)
    @isTest static void issue_CaseTrigger_Test_c()
    {
        
        Test.StartTest();
        
        User usr = [Select id from User where Id = :UserInfo.getUserId()];
        
        System.RunAs(usr)
        {
            Environment_Setup__c environmentSetup = Environment_Setup__c.getOrgDefaults();
            environmentSetup.Active_Org__c = true;
            update environmentSetup;
        }
        RecordType rectype= [select id from RecordType where sObjectType='Case' and isActive=true limit 1];
        
        //Insert a case record with issue__c field not null
        Case CaseRec = new case();
        CaseRec.Status = 'Unassigned';
        CaseRec.Origin = 'Email';
        CaseRec.Issue__c = 'testissue';
        CaseRec.RecordTypeId = rectype.id;
        CaseRec.subject = 'testissue-Him';
        CaseRec.CP_Account_Name__c = 'A2D Technologies';
        caseRec.Next_Action__c = 'Customer';
        system.debug('Case object is '+CaseRec);
        insert CaseRec;
        
        SC_CaseTriggerHelperClass.flagvalue = False;
        
       
        //Scenario 4 - Update issue__c field from Not Null -> Not null
        CaseRec.Issue__c = 'test3issue';
        caseRec.Next_Action__c = 'AMG';
        update CaseRec;
        SC_CaseTriggerHelperClass.flagvalue = False;
        
        //Scenario 5 - Insert a duplicate issue record
        try
        {
            SC_Issues__c IssueRec = new SC_Issues__c(Related_Case__c = CaseRec.id, Name = 'test3issue');
            insert IssueRec;
            SC_CaseTriggerHelperClass.flagvalue = False;
        }
        catch(Exception e)
        {
            
        }
        
        Test.StopTest();
        
    }

    // Method# 4 - (Issue Scenario - 4 for Next Action) 
    @isTest static void issue_CaseTrigger_Test_d()
    {
        
        Test.StartTest();
        
        User usr = [Select id from User where Id = :UserInfo.getUserId()];
        
        System.RunAs(usr)
        {
            Environment_Setup__c environmentSetup = Environment_Setup__c.getOrgDefaults();
            environmentSetup.Active_Org__c = true;
            update environmentSetup;
        }
        RecordType rectype= [select id from RecordType where sObjectType='Case' and isActive=true limit 1];
        
        //Scenario 1 - Insert a case record with issue__c field not null
        Case CaseRec = new case();
        CaseRec.Status = 'Unassigned';
        CaseRec.Origin = 'Email';
        CaseRec.Issue__c = 'testissue';
        CaseRec.RecordTypeId = rectype.id;
        CaseRec.subject = 'testissue-Him';
        CaseRec.CP_Account_Name__c = 'A2D Technologies';
        caseRec.Case_Assignment_Using_Active_Rules__c = true;
        caseRec.Next_Action__c = 'Customer';
        system.debug('Case object is '+CaseRec);
        insert CaseRec;
        
        SC_CaseTriggerHelperClass.flagvalue = False;
        
         
        //Scenario 2 - Update issue__c field from Not null -> Null
        CaseRec.Issue__c = Null;
        Caserec.Case_Assignment_Using_Active_Rules__c = true;
        caseRec.Next_Action__c = 'Case Owner';
        update CaseRec;
        SC_CaseTriggerHelperClass.flagvalue = False;
        
        
        Test.StopTest();
        
    }
    
    
    // Method# 4 - (For Email Service - Task Creation)
    @isTest static void InboundEmail_TaskCreation_Charaka() { 
      
        Test.StartTest(); 
        
        User usr = [Select id from User where Id = :UserInfo.getUserId()];
        
        System.RunAs(usr)
        {
            Environment_Setup__c environmentSetup = Environment_Setup__c.getOrgDefaults();
            environmentSetup.Active_Org__c = true;
            update environmentSetup;
        }
         
        // create a new email and envelope object
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
      
       
        //new Case object
        Case newcase = new Case();
        newcase.Subject = 'Test Subject';
        newcase.origin = 'Others';
        insert newcase;
      
      
        //Retrieve CaseNumber 
        Case cs=[select caseNumber from Case where id =: newcase.id and origin != null Limit 1]; 
        String casenum=cs.caseNumber;
      
      
      
        // Scenario 1 - E-mail without attachments
        // setup the data for the email
        email.subject = 'Test Email Service';
        email.fromAddress = 'someaddress@email.com';
        email.plainTextBody  = '$$START$$ \n ##ACTIVITY## \n TYPE#Email#ENDTYPE\n COMMENT#TEST - 1#ENDCOMMENT |n DESCRIPTION#Some description value#ENDDESCRIPTION \n STATUS#Not Started#ENDSTATUS \n DUE#12/02/2013#ENDDUE \n CASEID#'+caseNum+'#ENDCASEID \n ##ENDACTIVITY## \n $$END$$';
        
        // call the email service class and test it with the data in the testMethod
        SC_TaskCreation_InboundEmail  testInbound = new SC_TaskCreation_InboundEmail();
        testInbound.handleInboundEmail(email, env);
        
        
        //Scenario 3 - Exception case
        // setup the data for the email
        email = new Messaging.InboundEmail() ;
        email.subject = 'Test Email Service 3';
        email.fromAddress = 'someaddress@email.com';
        email.plainTextBody  = '$$START$$ \n ##ACTIVITY## \n TYPE#Email#ENDTYPE\n COMMENT#TEST - 3#ENDCOMMENT |n DESCRIPTION#Some description value#ENDDESCRIPTION \n STATUS#Not Started#ENDSTATUS \n DUE#12/02/2013#ENDDUE \n CASEID# #ENDCASEID \n ##ENDACTIVITY## \n $$END$$';
        
        // call the email service class and test it with the data in the testMethod
        testInbound = new SC_TaskCreation_InboundEmail();
        testInbound.handleInboundEmail(email, env);
        
        Test.StopTest();
    } 
    
    // Method# 5 - (For Email Service - Task Creation-2)
    @isTest static void InboundEmail_TaskCreation_Charaka2() { 
    
        Test.StartTest(); 
        
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        //List of text attachments
        List<Messaging.InboundEmail.TextAttachment> tList = new List<Messaging.InboundEmail.TextAttachment>();
        Messaging.Inboundemail.TextAttachment tAttachment1 = new Messaging.Inboundemail.TextAttachment();
        Messaging.Inboundemail.TextAttachment tAttachment2 = new Messaging.Inboundemail.TextAttachment();
        
        
        // Scenario 2 - E-mail with attachments
        // setup the data for the email
        
        Case newcase = new Case();
        newcase.Subject = 'Test Subject';
        newcase.origin = 'Others';
        insert newcase;
        
        
        //Retrieve CaseNumber 
        Case cs=[select caseNumber from Case where id =: newcase.id and origin != null Limit 1];
        String casenum=cs.caseNumber;
        
        email.subject = 'Test Email Service 2';
        email.fromAddress = 'someaddress@email.com';
        email.plainTextBody  ='$$START$$ \n ##ACTIVITY## \n TYPE#Email#ENDTYPE\n COMMENT#TEST - 2#ENDCOMMENT |n DESCRIPTION#Some description value#ENDDESCRIPTION \n STATUS#Not Started#ENDSTATUS \n DUE#12/02/2013#ENDDUE \n CASEID#'+caseNum+'#ENDCASEID \n ##ENDACTIVITY## \n $$END$$';
        
        
        //setup data for attachments
        tAttachment1.fileName = 'testAttach1.txt';
        tAttachment1.body='This is the body of the test attachment1!';
        tAttachment2.fileName = 'testAttach2.txt';
        tAttachment2.body='This is the body of the test attachment2!';
        
        tList.add(tAttachment1);
        tList.add(tAttachment2);
        
        email.textAttachments=tList;
        
        // call the email service class and test it with the data in the testMethod
        SC_TaskCreation_InboundEmail testInbound = new SC_TaskCreation_InboundEmail();
        testInbound.handleInboundEmail(email, env);
        
        Test.StopTest();
    }
  
  // Method# 6 - (For AMS)
  @isTest static void AlertCaseMaker_Test() {
    
      Test.StartTest();
      
      // Calling Test data method
      Account accRec1 = [Select AKAM_Account_ID__c from Account Limit 1];
      //Scenario 1 - Alert Case Maker
      String emailData = '$$START$$ \n ##CASE## RECORDTYPE#Technical#ENDRECORDTYPE SUBTYPE#Event Support#ENDSUBTYPE SERVICE#Business Reports#ENDSERVICE REQUESTTYPE#Address Change#ENDREQUESTTYPE    SEVERITY#3 - Difficult to do Job#ENDSEVERITY CASEORIGIN#Email#ENDCASEORIGIN DONOTSHOWINPORTAL#y#ENDDONOTSHOWINPORTAL AKAMACCOUNTID#'+accRec1.AKAM_Account_ID__c+'#ENDAKAMACCOUNTID'+
          'OWNER#hkar1#ENDOWNER CASEPRODUCT##ENDCASEPRODUCT PROBLEM#Performance#ENDPROBLEM SUBJECT#Alert Case Maker-06-Aug-1#ENDSUBJECT'+  
          'DESCRIPTION#Alert Case Maker-06-Aug-1#ENDDESCRIPTION ##ENDCASE## $$END$$';
      
      //Declare email variable
      Messaging.InboundEmail email = new Messaging.InboundEmail() ;
      Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
      
      email = new Messaging.InboundEmail() ;
      email.subject = 'Alert Case Maker';
      email.fromAddress = 'someaddress@email.com';
      email.plainTextBody = emailData;
      
      SC_CaseCreation_InboundEmail testInbound = new SC_CaseCreation_InboundEmail();
      testInbound.handleInboundEmail(email, env);
      
      Test.StopTest();
  }
  
    // Method# 7 - (For AutoGen - COB)
    static testMethod void AutoGen_Test_COB() {
    
        Test.StartTest();
        
        // Calling Test data method
        
        
        // Fetching User
        User usr = [Select id,alias from User where Id = :UserInfo.getUserId()];
        
        //Setting Email Template
        Account accRec1 = [Select AKAM_Account_ID__c from Account Limit 1];
        Merge_Contract_Header__c  merge_contract1 = [Select Contract_Id__c from Merge_Contract_Header__c Limit 1];
        EB_AccountProductMap__c  eb_product1 =[Select EB_Product__c from EB_AccountProductMap__c Limit 1];
        String emailData = '$$START$$  ##Case## AccountId#'+accRec1.AKAM_Account_ID__c+'#EndAccountId Type#Value#EndType CaseProduct' + eb_product1.EB_Product__c+ '#EndCaseProduct'+
            'Service#Accounts Audits#EndService   RequestType#Customer Onboarding#EndRequestType Problem#Value#EndProblem Source#Proactive#EndSource Severity#Value#EndSeverity'+
            'Status#Value#EndStatus Do not show in Portal#Value#EndDo not show in Portal Original Contract Id#'+merge_contract1.Contract_Id__c+'#EndOriginal Contract Id'+
            'Title#Value#EndTitle Description#Value#EndDescription ##EndCase## $$END$$';
        
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        
        email = new Messaging.InboundEmail() ;
        email.subject = 'AutoGen : New Case Creation : UseCase#COB#EndUseCase';
        email.fromAddress = 'someaddress@email.com';
        email.plainTextBody = emailData;
        
        SC_CaseCreation_InboundEmail testInbound = new SC_CaseCreation_InboundEmail();
        
        // scenario-1..Calling COB
        testInbound.handleInboundEmail(email, env);
        
        // For Duplicate COB
        testInbound.handleInboundEmail(email, env);
        
        Test.StopTest();
    
  }
  
    // Method# 8 - (For AutoGen - PO)
    @isTest static void AutoGen_Test_PO() {
    
        Test.StartTest();
        
        // Calling Test data method
        
        Account accRec1 = [Select id from Account Limit 1];
        Merge_Contract_Header__c  merge_contract1 = [Select Contract_Id__c from Merge_Contract_Header__c Limit 1];
        EB_AccountProductMap__c  eb_product1 =[Select EB_Product__c from EB_AccountProductMap__c Limit 1];
        //Setting Email Template
        String emailData = '$$START$$  ##Case## AccountId#'+accRec1.id+'#EndAccountId Type#Value#EndType CaseProduct' + eb_product1.EB_Product__c+ '#EndCaseProduct'+
            'Service#Accounts Audits#EndService   RequestType#Customer Onboarding#EndRequestType Problem#Value#EndProblem Source#Proactive#EndSource Severity#Value#EndSeverity'+
            'Status#Value#EndStatus Do not show in Portal#Value#EndDo not show in Portal Original Contract Id#'+merge_contract1.Contract_Id__c+'#EndOriginal Contract Id'+
            'Title#Value#EndTitle Description#Value#EndDescription  ##EndCase## $$END$$';
        
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        
        email = new Messaging.InboundEmail() ;
        email.subject = 'AutoGen : New Case Creation : UseCase#PO#EndUseCase';
        email.fromAddress = 'someaddress@email.com';
        email.plainTextBody = emailData;
        
        SC_CaseCreation_InboundEmail testInbound = new SC_CaseCreation_InboundEmail();
        testInbound.handleInboundEmail(email, env);
        
        Test.StopTest();
    
  }
  
    // Method# 9 - (For AutoGen - TCR - Service = SMP (Non-Security))
    @isTest static void AutoGen_Test_TCR_NonSec() {
    
        Test.StartTest();
        
        // Calling Test data method
        
        Account accRec1 = [Select id from Account Limit 1];
        Merge_Contract_Header__c  merge_contract1 = [Select Contract_Id__c from Merge_Contract_Header__c Limit 1];
        EB_AccountProductMap__c  eb_product1 =[Select EB_Product__c from EB_AccountProductMap__c Limit 1];
        //Setting Email Template
        String emailData = '$$START$$  ##Case## AccountId#'+accRec1.id+'#EndAccountId Type#Value#EndType CaseProduct' + eb_product1.EB_Product__c+ '#EndCaseProduct'+
            'Service#SMP (Non-Security)#EndService   RequestType#' + SC_Serv_ReqTyp_value__c.getValues('TCR-Category1').RequestTypeVal__c + '#EndRequestType Problem#Value#EndProblem Source#Proactive#EndSource Severity#Value#EndSeverity'+
            'Status#Value#EndStatus Do not show in Portal#Value#EndDo not show in Portal Original Contract Id#'+merge_contract1.Contract_Id__c+'#EndOriginal Contract Id'+
            'Title#Value#EndTitle Description#Value#EndDescription  ##EndCase## $$END$$';
        
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        
        email = new Messaging.InboundEmail() ;
        email.subject = 'AutoGen : New Case Creation : UseCase#TCR#EndUseCase';
        email.fromAddress = 'someaddress@email.com';
        email.plainTextBody = emailData;
        
        SC_CaseCreation_InboundEmail testInbound = new SC_CaseCreation_InboundEmail();
        testInbound.handleInboundEmail(email, env);
        
        // For Duplicate TCR - Service = SMP (Non-Security)
        testInbound.handleInboundEmail(email, env);
        
        Test.StopTest();
    
  }
  
    // Method# 10 (For AutoGen - TCR - Service = SMP (Security))
    @isTest static void AutoGen_Test_TCR_Sec() {
    
        Test.StartTest();
        
        // Calling Test data method
        Account  accRec1= [Select id from Account Limit 1];
        Merge_Contract_Header__c  merge_contract1 = [Select Contract_Id__c from Merge_Contract_Header__c Limit 1];
        EB_AccountProductMap__c  eb_product1 =[Select EB_Product__c from EB_AccountProductMap__c Limit 1];
        //Setting Email Template
        String emailData = '$$START$$  ##Case## AccountId#'+accRec1.id+'#EndAccountId Type#Value#EndType CaseProduct#' + eb_product1.EB_Product__c+ '#EndCaseProduct'+
            'Service#SMP (Security)#EndService   RequestType#' + SC_Serv_ReqTyp_value__c.getValues('TCR-Category2').RequestTypeVal__c + '#EndRequestType Problem#Value#EndProblem Source#Proactive#EndSource Severity#Value#EndSeverity'+
            'Status#Value#EndStatus Do not show in Portal#Value#EndDo not show in Portal Original Contract Id#'+merge_contract1.Contract_Id__c+'#EndOriginal Contract Id'+
            'Title#Value#EndTitle Description#Value#EndDescription  ##EndCase## $$END$$';
        
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        
        email = new Messaging.InboundEmail() ;
        email.subject = 'AutoGen : New Case Creation : UseCase#TCR#EndUseCase';
        email.fromAddress = 'someaddress@email.com';
        email.plainTextBody = emailData;
        
        SC_CaseCreation_InboundEmail testInbound = new SC_CaseCreation_InboundEmail();
        testInbound.handleInboundEmail(email, env);
        
        // For Duplicate TCR - Service = SMP (Security)
        testInbound.handleInboundEmail(email, env);
        
        Test.StopTest();
    
  }
  
    // Method# 11 - (For Task Creation)
    @isTest static void AutoGen_Test_COB_Task() {
    
        Test.StartTest();
        
        // Calling Test data method
        
        
        Case csRec1 = [Select Id from Case Limit 1];
        Merge_Contract_Header__c  merge_contract1 = [Select Contract_Id__c from Merge_Contract_Header__c Limit 1];
        //Calling createTask Method
        SC_CaseCreation_InboundEmail.createTask(merge_contract1.Contract_Id__c,csRec1.Id);
        
        Test.StopTest();
    
    }
  
    // Method# 12 - (For NIE)
    @isTest static void NIE_Test() {
    
    Test.StartTest();
    
    // Calling Test data method
    Account  accRec1= [Select Name from Account Limit 1];
    Contact conRec1 = [Select Login__c from Contact limit 1];
    
    //Scenario-1 Setting Email Body for - NIE (For Active Contact)
    String emailData = '$$START$$ ##CASE## RECORDTYPE#Technical#ENDRECORDTYPE SUBTYPE#NIE/NOCC Request#ENDSUBTYPE' +
                     'SERVICECATEGORY#Business Reports#ENDSERVICECATEGORY PROBLEM#Performance#ENDPROBLEM' +
                   'CASEORIGIN#Email#ENDCASEORIGIN SEVERITY#3#ENDSEVERITY SUBJECT#NIE CASE 28 oct 2013-Him-3#ENDSUBJECT' +
                    'DESCRIPTION#NIE CASE-1#ENDDESCRIPTION PORTALLOGIN#' + conRec1.Login__c +'#ENDPORTALLOGIN' +                   
                        'AKAMACCOUNTID#' + accRec1.Name + '#ENDAKAMACCOUNTID' + '##ENDCASE## $$END$$';
                        
    Messaging.InboundEmail email = new Messaging.InboundEmail() ;
    Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
    
    email = new Messaging.InboundEmail() ;
    email.subject = 'NIE : New Case Creation';
    email.fromAddress = 'Test_xyz@akamai.com';
    email.plainTextBody = emailData;
  
    SC_CaseCreation_InboundEmail testInbound = new SC_CaseCreation_InboundEmail();
    testInbound.handleInboundEmail(email, env);
    
    /*Scenario-2 (For InActive Contact)
    conRec.Login__c = 'Test_xyz_abc';
    Update conRec;
    testInbound.handleInboundEmail(email, env);*/
    
    Test.StopTest();
    
  }
  
  
  
 // Method# 14 - for ActiveContractsCon Extension
  @isTest public static void ActiveContracts_Test(){

  Test.StartTest();
   //User usr = [Select id from User where Id = :UserInfo.getUserId()];
      Account accRec1 = [Select id from Account limit 1];
  //inserting active Contract record
  //Merge_Contract_Header__c Act_ContractRec = new Merge_Contract_Header__c(Active__c = true,Effective_End_Date__c=Date.today(),Account_Name__c=accRec.id);
    Merge_Contract_Header__c Act_ContractRec = new Merge_Contract_Header__c(Active__c = true,Effective_End_Date__c=Date.today(),Account_Name__c=accRec1.id);
      insert Act_ContractRec ;
      //GSSActiveContractsCon ActiveCon
  //ActiveCon = new GSSActiveContractsCon(AccountCon);
  ApexPages.StandardController AccountCon1= new ApexPages.StandardController(accRec1);
  GSSActiveContractsCon ActiveCon1 = new GSSActiveContractsCon(AccountCon1);
  Boolean flag;
  Integer numb;
 
  //Calling the methods of Controller extension GSSActiveContractsCon 
  ActiveCon1.getcntract();
  flag = ActiveCon1.hasNext ;
  flag = ActiveCon1.hasPrevious ;
  numb = ActiveCon1.pageNumber ;
  numb = ActiveCon1.TotalPages ;
  ActiveCon1.Beginning();
  ActiveCon1.Last();
  ActiveCon1.Previous();
  ActiveCon1.Next();
  
 Test.StopTest();
 }

// Method# 15 - for InactiveContractsCon Extension
 @isTest public static void InactiveContracts_Test(){
 
  Test.StartTest();
 
 Account accRec1 =[Select id from Account Limit 1];
  ApexPages.StandardController AccountCon1 = new ApexPages.StandardController(accRec1);
 
 //inserting active Contract record
  Merge_Contract_Header__c Inact_ContractRec = new Merge_Contract_Header__c(Active__c = false,Effective_End_Date__c=Date.today(),Account_Name__c=accRec1.id);
  insert Inact_ContractRec ;
  GSSInactiveContractsCon InactiveCon1 = new GSSInactiveContractsCon(AccountCon1);  
  Boolean flag;
  Integer numb;
 
  //Calling the methods of Controller extension GSSActiveContractsCon 
  InactiveCon1.getcntract();
  flag = InactiveCon1.hasNext ;
  flag = InactiveCon1.hasPrevious ;
  numb = InactiveCon1.pageNumber ;
  numb = InactiveCon1.TotalPages ;
  InactiveCon1.Beginning();
  InactiveCon1.Last();
  InactiveCon1.Previous();
  InactiveCon1.Next();
  
  Test.StopTest();
  }
  
  
 // Method# 16 -(Scenarion-1 for SiebelBridge)
  @isTest public static void SiebelBridge_Test_a(){
 
  Test.StartTest();
  
  
   Profile pfl = [select id from Profile where name = 'System Administrator' limit 1];
    User usr = [select Id,Email,Alias from User where IsActive = True and ProfileId = :pfl.Id limit 1];
      Account accRec1 = [Select AKAM_Account_ID__c from Account WHERE Account_Status__c = 'Indirect Customer - Active' Limit 1] ;
  //Scenario-1 Setting Email Body for - Case Creation (Valid Owner,New Case)
    String emailData = '$$START$$##CCASE##AKAMCASEID#test-sb#ENDAKAMCASEID PARENTID##ENDPARENTID ACCOUNTID#'+accRec1.AKAM_Account_ID__c+
    '#ENDACCOUNTID TYPE#Business Support#ENDTYPE# PRODUCTSERVICE#CP Codes#ENDPRODUCTSERVICE PROBLEMREQUESTTYPE#Renew Existing Certificate#ENDPROBLEMREQUESTTYPE SEVERITY#3-Low Impact#ENDSEVERITY'+
    'SOURCE#Phone#ENDSOURCE STATUS#Assigned#ENDSTATUS TITLE#“*HIGH IMPORTANCE* SSL Certificate Renewal – Validation Required#ENDTITLE DESCRIPTION#Test Case createtion by Siebel Bridge 2#ENDDESCRIPTION'+
    'OWNER#'+usr.Alias+'#ENDOWNER ##ENDCCASE## $$END$$';
                        
    Messaging.InboundEmail email = new Messaging.InboundEmail() ;
    Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
    
    email = new Messaging.InboundEmail() ;
    email.subject = 'sIEBEL';
    email.fromAddress = 'Test_xyz@akamai.com';
    email.plainTextBody = emailData;
  
    SC_SiebelCaseCreation_InboundEmail testInbound = new SC_SiebelCaseCreation_InboundEmail();
    testInbound.handleInboundEmail(email, env);
    SC_SiebelCaseCreation_InboundEmail.sendMail(usr.Email,'exceptionMsg',false,emailData);
    
    Test.StopTest();
 }
 
 // Method# 17 -(Scenarion-2 for SiebelBridge)
 @isTest public static void SiebelBridge_Test_b(){
 
  Test.StartTest();
  
  
    
    //Scenario-2 Setting Email Body for - Case Creation (Invalid Owner,New Case) 

    String emailData = '$$START$$##CCASE##AKAMCASEID#test-sb1#ENDAKAMCASEID PARENTID##ENDPARENTID ACCOUNTID#testacc#ENDACCOUNTID'+
    'TYPE#Business Support#ENDTYPE# PRODUCTSERVICE#User Admin#ENDPRODUCTSERVICE PROBLEMREQUESTTYPE#Renew Existing Certificate#ENDPROBLEMREQUESTTYPE SEVERITY#3-Low Impact#ENDSEVERITY'+
    'SOURCE#Phone#ENDSOURCE STATUS#Assigned#ENDSTATUS TITLE#“*HIGH IMPORTANCE* SSL Certificate Renewal – Validation Required#ENDTITLE DESCRIPTION#Test Case createtion by Siebel Bridge 2#ENDDESCRIPTION'+
    'OWNER##ENDOWNER ##ENDCCASE## $$END$$';
                        
    Messaging.InboundEmail email = new Messaging.InboundEmail() ;
    Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
    
    email = new Messaging.InboundEmail() ;
    email.subject = 'sIEBEL';
    email.fromAddress = 'Test_xyz@akamai.com';
    email.plainTextBody = emailData;
  
    SC_SiebelCaseCreation_InboundEmail testInbound = new SC_SiebelCaseCreation_InboundEmail();
    testInbound.handleInboundEmail(email, env);
    Test.StopTest();
 }

 // Method# 18 -(Scenarion-3 for SiebelBridge)
 @isTest public static void SiebelBridge_Test_c(){
 
  Test.StartTest();
  
  
    Profile pfl = [select id from Profile where name = 'System Administrator' limit 1];
    User usr = [select Id,Email,Alias from User where IsActive = True and ProfileId = :pfl.Id limit 1];
  
  //Scenario-3 Setting Email Body for - Case Creation (Invalid Owner,New Case,Invalid Service)     
    String emailData = '$$START$$##CCASE##AKAMCASEID#test-sb2#ENDAKAMCASEID PARENTID#ehsdsg#ENDPARENTID ACCOUNTID#testacc#ENDACCOUNTID'+
    'TYPE#Business Support#ENDTYPE# PRODUCTSERVICE#test service#ENDPRODUCTSERVICE PROBLEMREQUESTTYPE#Renew Existing Certificate#ENDPROBLEMREQUESTTYPE SEVERITY#3-Low Impact#ENDSEVERITY'+
    'SOURCE#Phone#ENDSOURCE STATUS#Assigned#ENDSTATUS TITLE#“*HIGH IMPORTANCE* SSL Certificate Renewal – Validation Required#ENDTITLE DESCRIPTION#Test Case createtion by Siebel Bridge 2#ENDDESCRIPTION'+
    'OWNER#testbbb#ENDOWNER ##ENDCCASE## $$END$$';
    Messaging.InboundEmail email = new Messaging.InboundEmail() ;
    Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
    
    email = new Messaging.InboundEmail() ;
    email.subject = 'sIEBEL';
    email.fromAddress = 'Test_xyz@akamai.com';
    email.plainTextBody = emailData;
  
    SC_SiebelCaseCreation_InboundEmail testInbound = new SC_SiebelCaseCreation_InboundEmail();
    testInbound.handleInboundEmail(email, env);
    SC_SiebelCaseCreation_InboundEmail.sendMail(usr.Email,'exceptionMsg',true,emailData);

  
     Test.StopTest();
 }

 // Method# 19 -(Scenarion-4 for SiebelBridge)
 @isTest public static void SiebelBridge_Test_d(){
 
  Test.StartTest();
 
  
   User usr = [select Id,Email,Alias from User where IsActive = True limit 1];
    
   //Scenario-4 Setting Email Body for - Case Updation (Invalid Owner,Existing Case) 
   String emailData = '$$START$$##UCASE##AKAMCASEID#ehsdsg#ENDAKAMCASEID PARENTID##ENDPARENTID ACCOUNTID#testacc#ENDACCOUNTID'+
    'TYPE#Business Support#ENDTYPE# PRODUCTSERVICE#SSL Certificate Validation#ENDPRODUCTSERVICE PROBLEMREQUESTTYPE#Renew Existing Certificate#ENDPROBLEMREQUESTTYPE SEVERITY#3-Low Impact#ENDSEVERITY'+
    'SOURCE#Phone#ENDSOURCE STATUS#Assigned#ENDSTATUS TITLE#“*HIGH IMPORTANCE* SSL Certificate Renewal – Validation Required updated#ENDTITLE DESCRIPTION#Test Case createtion by Siebel Bridge 2#ENDDESCRIPTION'+
    'OWNER#test#ENDOWNER ##ENDUCASE## $$END$$';
                        
    Messaging.InboundEmail email = new Messaging.InboundEmail() ;
    Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
    
    email = new Messaging.InboundEmail() ;
    email.subject = 'sIEBEL';
    email.fromAddress = 'Test_xyz@akamai.com';
    email.plainTextBody = emailData;
  
    SC_SiebelCaseCreation_InboundEmail testInbound = new SC_SiebelCaseCreation_InboundEmail();
    testInbound.handleInboundEmail(email, env);
    SC_SiebelCaseCreation_InboundEmail.sendMail(usr.Email,'exceptionMsg',false,emailData);
    
    Test.StopTest();
 }
   
 // Method# 20 - KBSync
 @isTest public static void KBDocumentSync_Test(){
    
    Test.StartTest();
    
    //Create Test Data
    Knowledge__kav htRec=new Knowledge__kav();
    htRec.Title='Test How To Title';
    htRec.UrlName='Test-How-To-TitleXXX';
    htRec.Description__c ='Test How To Description';
    htRec.Applies_To__c='Test How To Applies To';
    htRec.How_To_Procedure__c='Test How To Procedure';
    htRec.Visibility__c='External';
    Insert htRec;
     
    //Publish article
    Knowledge__kav ht=[select knowledgearticleid,articlenumber from Knowledge__kav where id =: htRec.id Limit 1];
    KbManagement.PublishingService.publishArticle(ht.knowledgearticleid, true);
    
    Knowledge__kav ht2=[select knowledgearticleid from Knowledge__kav where publishstatus='Online' and Visibility__c='External' and Language='en_US' Limit 1];
    String hid = KbManagement.PublishingService.editOnlineArticle(ht2.knowledgearticleId, true);
    Knowledge__kav ht3=[select knowledgearticleid,id,Applies_To__c,Description__c from Knowledge__kav where id=: hid Limit 1];
    ht3.Applies_To__c='Updated Applies To';
    ht3.Description__c='Updated Description';
    update ht3;
    
    KbManagement.PublishingService.publishArticle(ht3.knowledgearticleid,true);
     
    //Schedule for sync.
    SC_KBDocumentSync_Scheduler testSync= new SC_KBDocumentSync_Scheduler();
    testSync.isTestCall=true;
    Environment_Setup__c environmentSetup = Environment_Setup__c.getInstance();
    if(environmentSetup.Environment_Type__c.equalsIgnorecase('Primary'))
    String jobId = System.schedule('testKBDocumentSync', '0 0 0 3 9 ? 2022', testSync);
    testSync.deleteArticles();
    
    Test.StopTest();
 }
 
// Method# 21 - Deleting Case record
  @isTest public static void DeleteCaseRec_Test(){
   
    Test.StartTest();
       
        Case csrec1 = [Select subject,description,Ownerid,AKAM_Case_ID__c,RecordTypeId,Do_not_show_in_portal__c, Origin from Case Limit 1];
      csrec1.status = 'Mitigated / Solution Provided';
      csrec1.OwnerId = Userinfo.getUserId();
      csrec1.status = 'Mitigated / Solution Provided';
      CaseTriggerClass.isOneTimeRun = True;
        csrec1.Override_Next_Case_Update__c = System.now().addMinutes(10);
        csrec1.Override_Next_Case_Update_Reason__c = 'test';
        csrec1.IsStopped = False;
        csrec1.MilestoneFire__c = 'Case Update';
        csrec1.Validation_Override__c = True;
      update csrec1;
        csrec1.Status = 'Assigned';
        CaseTriggerClass.isOneTimeRun = True;
        csrec1.IsStopped = True;
      update csrec1;
      SC_CaseTriggerHelperClass.flagvalue = False;
      try{
        delete csrec1;
      }
      catch(Exception e){
      }
    Test.StopTest();
 }
 
 
 
 //Method# 23 Sending Notifications to Manual subscribers
    @isTest public static void SendEmailToCaseNotificationSubscription_test(){

        Map<String, Schema.RecordTypeInfo> rtMap = Case.sObjectType.getDescribe().getRecordTypeInfosByName();
        /*Account acc = new Account(AKAM_Account_ID__c='Test1234abc',Name='Test1234abc');
        insert acc;
        
        Contact con = utilTestClass.CreateContact('cNotificationlname','cNotificationfname');
        con.AccountId = acc.Id;
        insert con;
        Case_Notification_Subscription__c notSub = new Case_Notification_Subscription__c(Account__c = acc.Id,User__C=UserInfo.getUserId(),Case_Record_Type__c ='Technical',Portal_Visibility__c ='All',Case_Origin__c ='All',Sub_Type__c ='All');
        insert notSub;
        Case c = new Case(AKAM_Case_ID__c='Case123abc',AccountId=acc.Id,ContactId=con.Id,RecordTypeId=rtMap.get('Technical').getRecordTypeId(),
                  origin = 'Others');
        insert c;*/
        BMCServiceDesk__CategoryTypes__c ctype = new BMCServiceDesk__CategoryTypes__c(Name = 'categoryTypeTest');       
        insert ctype;

        BMCServiceDesk__Category__c cat = new BMCServiceDesk__Category__c();
        cat.Name='TempCategory';
        cat.SI_Applies_to_Service_Incident__c = true;
        cat.BMCServiceDesk__AvailableForServiceCatalog__c = true;
        cat.BMCServiceDesk__FKCategoryType__c = ctype.Id;
        insert cat;
        
        BMCServiceDesk__Impact__c ima = new BMCServiceDesk__Impact__c();
        ima.Name='tempImpact';
        ima.SI_Applies_to_Service_Incident__c = true;
        insert ima;
        
        BMCServiceDesk__Urgency__c  urg = new BMCServiceDesk__Urgency__c();
        urg.Name='tempUrgency1';
        urg.SI_Applies_to_Service_Incident__c = true;
        insert urg;

        List<BMCServiceDesk__Incident__c> lstIncident = new List<BMCServiceDesk__Incident__c>();
        BMCServiceDesk__Incident__c incident = new BMCServiceDesk__Incident__c();
        incident.RecordTypeId = BMCServiceDesk__Incident__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Service Incident').getRecordTypeId();
        incident.BMCServiceDesk__FKCategory__c = cat.Id;
        incident.BMCServiceDesk__FKUrgency__c = urg.id;
        incident.BMCServiceDesk__FKImpact__c = ima.Id;
        incident.BMCServiceDesk__shortDescription__c = 'Inc1';
        incident.how_was_the_issue_detected__c = 'others';
        lstIncident.add(incident);
        
        incident = new BMCServiceDesk__Incident__c();
        incident.RecordTypeId = BMCServiceDesk__Incident__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Service Incident').getRecordTypeId();
        incident.BMCServiceDesk__FKCategory__c = cat.Id;
        incident.BMCServiceDesk__FKUrgency__c = urg.id;
        incident.BMCServiceDesk__FKImpact__c = ima.Id;
        incident.BMCServiceDesk__shortDescription__c = 'Inc2';
        incident.how_was_the_issue_detected__c = 'others';
        lstIncident.add(incident);
        
        /*Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u = new User(Alias = 'CRMOPS', Email='standarduser@testorg.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg.com');*/
        
        User usr = [select Id, Name from User where alias = 'CRMOPS' LIMIT 1];

        System.runAs(usr) {
            insert lstIncident[0];
            insert lstIncident[1];
        }

        
        
        List<Account> accountList = new List<Account>();
        List<AccountTeamMember> atmList = new List<AccountTeamMember>();
        List<Case_Notification_Subscription__c> CNSList = new List<Case_Notification_Subscription__c>();
        List<Case> caseList = new List<Case>();
        Account acc1 = new Account(AKAM_Account_ID__c='Test1234abc1',Name='Test1234abc1',Type='- Active');
        accountList.add(acc1);
        Account acc2 = new Account(AKAM_Account_ID__c='Test1234abc2',Name='Test1234abc2',Type='Agency - Inactive');
        accountList.add(acc2);
        insert accountList;
        AccountTeamMember atmRec = new AccountTeamMember(AccountId = acc1.Id,UserId = UserInfo.getUserId(),TeamMemberRole = 'CXM');
        atmList.add(atmRec);
        AccountTeamMember atmRec1 = new AccountTeamMember(AccountId = acc1.Id,UserId = UserInfo.getUserId(),TeamMemberRole = 'Services Primary');   
        atmList.add(atmRec1);
        AccountTeamMember atmRec2 = new AccountTeamMember(AccountId = acc2.Id,UserId = UserInfo.getUserId(),TeamMemberRole = 'CXM');
        atmList.add(atmRec2);
        AccountTeamMember atmRec3 = new AccountTeamMember(AccountId = acc2.Id,UserId = UserInfo.getUserId(),TeamMemberRole = 'Services Primary');   
        atmList.add(atmRec3);
        insert atmList;

        test.startTest();
        
        Case_Notification_Subscription__c notSub1 = new Case_Notification_Subscription__c(Account__c = accountList[1].Id,User__C=UserInfo.getUserId(),Case_Record_Type__c ='Technical',Portal_Visibility__c ='All',Case_Origin__c ='All',Severity__c = '1;2',Incident__c = 'Yes');
        CNSList.add(notSub1);
        
        Case_Notification_Subscription__c notSub2 = new Case_Notification_Subscription__c(Account__c = accountList[1].Id,User__C=UserInfo.getUserId(),Case_Record_Type__c ='All',Portal_Visibility__c ='All',Case_Origin__c ='All',Severity__c = '1;2;3 & below',Incident__c = 'Yes');
        CNSList.add(notSub2);
        
        Case_Notification_Subscription__c notSub = new Case_Notification_Subscription__c(Account__c = acc2.Id,User__C=UserInfo.getUserId(),Case_Record_Type__c ='Managed Security',Portal_Visibility__c ='All',Case_Origin__c ='All',Severity__c = '1;2',Incident__c = 'Yes');
        CNSList.add(notSub);
        
        insert CNSList;
        accountList[1].Type = '- Active';
        update accountList[1];
        
        atmList[1].TeamMemberRole =  'CXM';
        update atmList[1];
        Contact con = utilTestClass.CreateContact('cNotificationlname','cNotificationfname');
        con.AccountId = accountList[1].Id;
        insert con;
        
        Case c1 = new Case(AKAM_Case_ID__c='Case124abc',AccountId=acc2.Id,ContactId=con.Id,RecordTypeId=rtMap.get('Managed Security').getRecordTypeId(),
                  origin = 'Others',Do_not_show_in_portal__c = false,Severity__c = '1',Customer_Temperature__c='Low',Level_of_Impact__c='Low');
        caseList.add(c1);
        insert caseList;
        caseList[0].Incident__c = lstIncident[1].Id;
        update caseList;
        test.stopTest();
}
 
//Method# 24 For Setting Default Email Template for service cloud console 
  @isTest public static void testSmartLoader() {
   
    test.startTest();
    
        Account Acc = utilTestClass.CreateAccount('TestAccount');
        Case c = utilTestClass.CreateCase(Acc.id);
        SC_DefaultTemplate_Console loader = new SC_DefaultTemplate_Console();
        Id getTemplateId = loader.getDefaultEmailTemplateId(c.id);
               
     test.stopTest();
                    
    }
   
  
// Method # 28: Riverbed SAAS OEM Test
    
    @isTest Public static void  RiverbedRecordTest(){
         
     User currentusr = [Select id from User where Id = :UserInfo.getUserId()];
     System.RunAs(currentusr)
     {
         Environment_Setup__c environmentSetup = Environment_Setup__c.getOrgDefaults();
         environmentSetup.Active_Org__c = true;
         update environmentSetup;
     }
      Account accTest = new Account();
      accTest.Name ='Riverbed1234';
      accTest.Website ='www.google.com';
        
      insert accTest;
      
      EB_AccountProductMap__c ProdTest = new EB_AccountProductMap__c(); 
      ProdTest.Name = 'Riverbed_Product';
      ProdTest.EB_Account__c = accTest.Id;
      ProdTest.EB_Product__c = 'Riverbed_Product';
      
      insert ProdTest;
      
     SC_RiverbedCaseProdID__c RBProduct = SC_RiverbedCaseProdID__c.getValues('Riverbed_SAAS_OEM');
      RBProduct.Case_Product_ID__c = ProdTest.Id ;
      update RBProduct ;
        
      test.startTest();
      
        
        Case caseTest = new Case();
        caseTest.AccountID = accTest.Id ;
        caseTest.Severity__c = '3';
        caseTest.Status = 'Unassigned';  
        caseTest.Subject = 'CCCC';
        caseTest.Description = 'CCCCC123';
        caseTest.Case_Product__c  = ProdTest.Id;
        caseTest.Problem__c = 'Alerts';
        caseTest.Service_Category__c ='Product Support';
        caseTest.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical').getRecordTypeId();       
        caseTest.origin = 'Others';
        insert caseTest;
        test.stopTest();
    } 
    
 
   
   //Method 30: Test Case for EPE HomePage
   @isTest public static void testEPEHomePage()
   {
        Case casenew = new Case();
        casenew.Subject = 'Test Case Notification';
        casenew.Recent_Update__c = True;
        casenew.RecordTypeid = Schema.SObjectType.case.getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        casenew.Origin = 'Email';
        casenew.Case_Assignment_Using_Active_Rules__c = true;
        insert casenew;
       
        Engagement_Request__c request = new Engagement_Request__c(Case__c = casenew.Id, OwnerId = UserInfo.getUserId());
        test.startTest();
        insert request;
       
        List<Case> lcs = new List<Case>();
        //lcs = [Select Id from case where isClosed=False and Owner.Name like 'ATS%' and RecordType.Name != 'Invalid Case' and origin != null limit 1];
        lcs = [Select Id from case where isClosed=False and RecordType.Name != 'Invalid Case' and Subject  = 'Milestone Case' and origin != null limit 1];
        List<Engagement_Request__c> ler = new List<Engagement_Request__c>();

        //ler = [Select Id from Engagement_Request__c where Request_Status__c NOT IN ('Closed','Cancelled','Rejected') and Owner.Name like 'ATS%' limit 1];
        ler = [Select Id from Engagement_Request__c where Request_Status__c NOT IN ('Closed','Cancelled','Rejected') limit 1];
    
        System.debug('Case' + lcs);
        System.debug('ER' + ler);
       
        //test.startTest();
        SC_EPE_HomePageCtrl c = new SC_EPE_HomePageCtrl();
        
        if(lcs.size()>0)
        {
            c.passRecId = lcs[0].Id;
            c.pickCaseER();
        }
        
        if(ler.size()>0)
        {
            c.passRecId = ler[0].Id;
            c.pickCaseER();
        }
        
        c.MyFilter = 'Hide Pending';
        c.QFilter = 'All CCare Queues - Cases';
                
        c.populateQTable();
        c.populateMyTable();
        c.populateMyTeamTable();

        c.MyFilter = 'My Work';
        c.QFilter = 'All CCare Queues - ERs';
        
        c.populateQTable();
        c.populateMyTable();
       
        c.MyFilter = 'Followed';
        c.QFilter = 'My Queues';
        c.populateMyTable();      
        c.populateMyTeamTable();
        test.stopTest();
    } 
    
    //Method# 31 For Creating Transition on the Case 
    @isTest public static void testCaseTransition() {
        Account Acc = utilTestClass.CreateAccount('TestAccount');
        Case c = utilTestClass.CreateCase(Acc.id);
        c.OwnerId = userInfo.getuserid();
        c.Issue_Summary__c = 'Test';
        c.Troubleshooting_to_Date__c = 'test';
        c.Data_Collected__c = 'test';
        c.Customer_Expectations__c = 'test';
        c.Next_Action_Recommendation__c = 'test';
        c.Validation_Override__c  = true;
        update c;
        PageReference pageRef = Page.SC_CaseTransitionCreateV2;
        Test.setCurrentPage(pageRef);
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(c);
        ApexPages.currentPage().getParameters().put('Id',c.id);
        test.startTest();
          SC_CaseTransitionControllerV2 ctc = new SC_CaseTransitionControllerV2(sc);
          case_transition__c ct = new case_transition__c();
          ct.target_shift__C = 'Transition Now';
          ct.approved_by__c = userinfo.getUserId();
          ct.case__c = c.id;
          ctc.caseTransitionObject = ct;
          List<Id> lCt = new List<Id>{ct.id};
          List<Id> lC = new List<Id>{c.id};
          ctc.approveTransition();
          ctc.getActiveTransition();
          ctc.getDisplayTransitionButton();
          ctc.updateTargetDate();
          SC_CaseTransitionControllerV2.updateCaseAsync(lCt, lC);
          Case caseRec = SC_CaseTransitionControllerV2.retCaseDetails(c.id);
          Boolean canCreateTransition = SC_CaseTransitionControllerV2.canCreateCT(caseRec);
          String transtionCreationStatus = SC_CaseTransitionControllerV2.createTransitionRec(caseRec, false, 'APAC');
          String username = SC_CaseTransitionControllerV2.getUserName();
          String currentShiftDetails = SC_CaseTransitionControllerV2.getCurrentShiftDetails();
          Id transitionRecTypeId = SC_CaseTransitionControllerV2.getCaseTransRecTypeId('Akatec');
          String shiftWakeUpTime = SC_CaseTransitionControllerV2.wakeUpTimeMethod('APAC');
          shiftWakeUpTime = SC_CaseTransitionControllerV2.wakeUpTimeMethod('None'); 
          shiftWakeUpTime = SC_CaseTransitionControllerV2.wakeUpTimeMethod('transition now');
        test.stopTest();
      }
     //Method# 32 For Creating Transition on the Case - scenario - 2 For negative scenario
    @isTest public static void testCaseTransition2() {
        
        Account Acc = utilTestClass.CreateAccount('TestAccount');
        Case c = utilTestClass.CreateCase(Acc.id);
        c.Case_Assignment_Using_Active_Rules__c = true;
        c.Issue_Summary__c = 'Test';
        c.Troubleshooting_to_Date__c = 'test';
        c.Data_Collected__c = 'test';
        c.Customer_Expectations__c = 'test';
        c.Next_Action_Recommendation__c = '';
        c.has_active_transition__c = false;
        update c;
        
        PageReference pageRef = Page.SC_CaseTransitionCreateV2;
        Test.setCurrentPage(pageRef);
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(c);
        ApexPages.currentPage().getParameters().put('Id',c.id);
        test.startTest();
          SC_CaseTransitionControllerV2 ctc = new SC_CaseTransitionControllerV2(sc);
          case_transition__c ct = new case_transition__c();
          ct.target_shift__C = '';
          ct.approved_by__c = userinfo.getUserId();
          ct.case__c = c.id;
          ctc.caseTransitionObject = ct;
          ctc.getActiveTransition();
          ctc.getDisplayTransitionButton();
          ctc.updateTargetDate();
          ctc.approveTransition();
          SC_Utility.getNextSaturday();
          String s = SC_Utility.ImageConverter('testimage');
        test.stopTest();
        }
    
    // Method# 33 for case transition 
    @isTest public static void testCaseTransition3() {
        
        Account Acc = utilTestClass.CreateAccount('TestAccount');
        Case c = utilTestClass.CreateCase(Acc.id);
        c.OwnerId = userInfo.getuserid();
        c.Issue_Summary__c = 'Test';
        c.Troubleshooting_to_Date__c = 'test';
        c.Data_Collected__c = 'test';
        c.Customer_Expectations__c = 'test';
        c.Next_Action_Recommendation__c = 'test';
        c.has_active_transition__c = false;
        update c;
        
        PageReference pageRef = Page.SC_CaseTransitionCreateV2;
        Test.setCurrentPage(pageRef);
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(c);
        ApexPages.currentPage().getParameters().put('Id',c.id);
        test.startTest();
          SC_CaseTransitionControllerV2 ctc = new SC_CaseTransitionControllerV2(sc);
          case_transition__c ct = new case_transition__c();
          //This will give the next shift name
          String currentShift = SC_utility.getCurrentShiftDetails('Akatec');
          //String nextShift = SC_utility.getNextShift(currentShift);
          ct.target_shift__C = 'APAC';
          ct.approved_by__c = userinfo.getUserId();
          ct.Shift_Tracker__c = true;
          ct.case__c = c.id;
          ctc.caseTransitionObject = ct;
          ctc.getActiveTransition();
          ctc.getDisplayTransitionButton();
          ctc.updateTargetDate();
          ctc.approveTransition();
        c.OwnerId = userInfo.getuserid();
        SC_CaseTriggerHelperClass.flagvalue = False;
        update c;
        test.stopTest();
        }
 
    // Method# 35
    /*@isTest public static void testRelatedAccountContact() {
        
        Account Acc = utilTestClass.CreateAccount('TestAccountzxsoccunique3');
        insert Acc;
        Case c = utilTestClass.CreateCase(Acc.id);
        Contact con = utilTestClass.CreateContact('TestFirstName','TestLastName');
        con.Contact_Type__c ='BOCC/BMS';
        con.AccountId = Acc.Id;
        insert con;
        c.OwnerId = userInfo.getuserid();
        update c; 
        test.startTest();
        PageReference pageRef = Page.RelatedAccountContact;
        Test.setCurrentPage(pageRef);
        ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(c);
        ApexPages.currentPage().getParameters().put('Id',c.id);
        RelatedAccountContactController ctc = new RelatedAccountContactController(sc);
        ctc.first();
        ctc.last();
        ctc.previous();
        ctc.next();
        test.stopTest();
   } */


     // Method# 37 : Test Method for Special Instruction Visibility      
    @isTest public static void specialInstructionVisibility() {
    
        List<folder> fol = new list<folder>([select id,name from folder where name ='SC Data' limit 1]);
    
        Document doc = new Document();
        doc.Name = 'Media';
        doc.FolderId = fol[0].id;
        insert doc;
            
        //Account Acc = utilTestClass.CreateAccount('TestAccountzxsoccunique2');
        //insert Acc ;
        Account Acc=[Select Id from Account Limit 1];
        
        /*Special_Instruction_Template__c splInstrTemp = new Special_Instruction_Template__c();
        splInstrTemp.Instructions__c = 'test';
        splInstrTemp.Show_for_Record_Types__c = 'All except Managed Security';
        splInstrTemp.Title__c = 'test';
        splInstrTemp.name = 'test';
        splInstrTemp.Flag_Icon__c = 'Media';   
        
        insert splInstrTemp;*/
        
        /*Special_Instructions__c splInstObj = new Special_Instructions__c();
        splInstObj.Title__c = 'test1';
        splInstObj.Instructions__c = 'test1';
        splInstObj.Start_Date__c = system.today();
        splInstObj.Account__c = Acc.Id;
        splInstObj.Show_for_Record_Types__c = 'All except Managed Security';
        splInstObj.Special_Instruction_Template__c = splInstrTemp.id ; 

        insert splInstObj;
        
        Special_Instructions__c splInstObjNoTemp = new Special_Instructions__c();
 
        splInstObjNoTemp.Title__c = 'test1';
        splInstObjNoTemp.Instructions__c = 'test1';
        splInstObjNoTemp.Start_Date__c = system.today();
        splInstObjNoTemp.Account__c = Acc.Id;
        splInstObjNoTemp.Show_for_Record_Types__c = 'All except Managed Security';

        insert splInstObjNoTemp;*/
        
        

        
        /*Case c = utilTestClass.CreateCase(Acc.id);
        c.OwnerId = userInfo.getuserid();
        c.recordtypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical').getRecordTypeId(); 
        c.Subject ='test';
        c.Description = 'test';
        c.AccountId = Acc.id;
        c.Origin = 'Other';
        update c;*/
        
        List<Case> caseList = new List<Case>();

        Case c = new Case(AccountId = Acc.id , Subject = 'Case with a account' , Origin = 'Other', OwnerId = userInfo.getuserid(),
                          recordtypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical').getRecordTypeId(),Description = 'Testing the case' );
        caseList.add(c);
        
            
        Case caseWithNoAcc = new case();
          caseWithNoAcc.Subject ='test';
          caseWithNoAcc.Description = 'test';
          caseWithNoAcc.Recent_Update__c = true;
          caseWithNoAcc.OwnerId = userInfo.getuserid();
          caseWithNoAcc.Origin = 'Other';
        caseList.add(caseWithNoAcc);

        insert caseList;
        
      test.startTest();
            PageReference pageRef = Page.Special_Instructions;
            Test.setCurrentPage(pageRef);
            
          ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(c);
            ApexPages.currentPage().getParameters().put('Id',c.id);
            SpecialInstructionsListController scCont = new SpecialInstructionsListController(sc); 
           
          ApexPages.Standardcontroller scNoAcc = new ApexPages.Standardcontroller(caseWithNoAcc);
            ApexPages.currentPage().getParameters().put('Id',caseWithNoAcc.id);
            SpecialInstructionsListController scContNoAcc = new SpecialInstructionsListController(scNoAcc); 
            scContNoAcc.setRecentUpdateOnCaseTrue();
      test.stopTest();
    }
     // Method# 38
    @isTest public static void testSpecialInstruction(){
        
        //For DR Code Coverage
        ExternalSharingHelper.RunFromtestClass = true;  

        Id id1,id2;
        //Special Instruction template creation
        Special_instruction_template__c specialInstructionTemplate = new Special_instruction_template__c();
        specialInstructionTemplate.Name ='test template test 12345';
        specialInstructionTemplate.Title__c ='test template test 12345';
        specialInstructionTemplate.Instructions__c ='test template test 12345';
        specialInstructionTemplate.Show_for_Record_Types__c ='All except Managed Security';
        insert specialInstructionTemplate;

        //For Update Trigger
        specialInstructionTemplate.Instructions__c ='test template instructions';
        update specialInstructionTemplate;
        
        //Account Acc = utilTestClass.CreateAccount('TestAccount1 zpxtx');
        //insert Acc;
        Account Acc= [Select Id from Account Limit 1];
        test.startTest();
        PageReference pageRef1 = Page.SC_SpecialInstructionTemplatePage;
        Test.setCurrentPage(pageRef1);
        //Special instruction with template
        ApexPages.Standardcontroller sc1 = new ApexPages.Standardcontroller(new Special_instructions__c());
        ApexPages.currentPage().getParameters().put('accountId',Acc.Id);
        ApexPages.currentPage().getParameters().put('isTemplate','true');
        SC_SpecialInstructionTemplateCtrl ctrl1 = new SC_SpecialInstructionTemplateCtrl(sc1);  
        ctrl1.specialInstructionsObject.Start_Date__c = Date.newInstance( 2014, 1, 1 );
        ctrl1.specialInstructionsObject.Expiration_Date__c = Date.newInstance( 2014, 2, 1 );
        ctrl1.templateTitle ='test template test 12345' ;
        ctrl1.loadPreview();
        ctrl1.createSpecialInstruction();
        id1 = ctrl1.specialInstructionsObject.Id;
        ctrl1.templateTitle ='---None---';
        ctrl1.loadPreview();
        ctrl1.createSpecialInstruction();
        
        //Special Instructions without template
        
        ApexPages.Standardcontroller sc2 = new ApexPages.Standardcontroller(new Special_instructions__c());
        SC_SpecialInstructionTemplateCtrl ctrl2 = new SC_SpecialInstructionTemplateCtrl(sc2);        
        ApexPages.currentPage().getParameters().put('accountId',Acc.Id);
        ApexPages.currentPage().getParameters().put('isTemplate','false');
        ctrl2.specialInstructionsObject.Title__c ='Test';
        ctrl2.specialInstructionsObject.Instructions__c ='Test';
        ctrl2.specialInstructionsObject.Show_for_Record_Types__c ='All except Managed Security';
        ctrl2.specialInstructionsObject.Start_Date__c = Date.newInstance(2016, 1, 1);
        ctrl2.specialInstructionsObject.Expiration_Date__c = Date.newInstance(2017, 1, 1 );
        ctrl2.createSpecialInstruction();
        id2 = ctrl2.specialInstructionsObject.Id;
        ctrl2.specialInstructionsObject.Start_Date__c = Date.newInstance(2016, 1, 1);
        ctrl2.specialInstructionsObject.Expiration_Date__c = Date.newInstance(2015, 1, 1 );
        ctrl2.createSpecialInstruction();
        
        //Special Instruction view page
        PageReference pageRef2 = Page.SC_SpecialInstructionViewPage;
        Test.setCurrentPage(pageRef2);
        ApexPages.Standardcontroller sc3 = new ApexPages.Standardcontroller(new Special_instructions__c());
        ApexPages.currentPage().getParameters().put('Id',id1);
        SC_SpecialInstructionViewCtrl viewCtrl1 = new SC_SpecialInstructionViewCtrl(sc3);
        ApexPages.Standardcontroller sc4 = new ApexPages.Standardcontroller(new Special_instructions__c());
        ApexPages.currentPage().getParameters().put('Id',id2);
        SC_SpecialInstructionViewCtrl viewCtrl2 = new SC_SpecialInstructionViewCtrl(sc4);
        
        Delete specialInstructionTemplate;
        test.stopTest();
      }   

     // Method# 39
     @isTest public static void CPSTestMethod(){
      List<Case> caseList = new List<Case>();   
         /*Account accTest = new Account();
         accTest.Name ='Test1234';
         accTest.Website ='www.google.com';
         accTest.Support_Level__c = 'Premium'; 
         accTest.Mailing_List_for_Technical_Case_auto_cc__c = 'adsing@akamai.com';
         System.debug('accTest ::'+accTest);
         insert accTest;
         System.debug('accTest.Id ::'+accTest.Id);  
         
      
      Contact CPSconRec = new Contact(AccountId = accTest.Id, Login__c = 'Test_xyz', Email = 'Test_xyz123@akamai.com',
      No_Longer_with_Company__c = false, LastName = 'Test Contact',Partner_Contact_Type__c = 'Services Primary');
      Insert CPSconRec;*/
         
         Account accTest = [Select Id from Account where Name='Test1234' Limit 1];
         Contact CPSconRec =[Select Id from Contact where LastName='Test ContactAcc2' Limit 1];
         

      List<AccountTeamMember> lstofTeamMembers = new List<AccountTeamMember>();
      AccountTeamMember atmRec = new AccountTeamMember(AccountId = accTest.Id,UserId = UserInfo.getUserId(),TeamMemberRole = 'Services - Secondary');
         lstofTeamMembers.add(atmRec);
      Insert lstofTeamMembers;
         System.debug('lstofTeamMembers ::'+lstofTeamMembers);
               
      /*Merge_Contract_Header__c contractRec = new Merge_Contract_Header__c();
      contractRec.Name = 'Test12345';
      contractRec.Account_Name__c = accTest.ID;
      contractRec.Original_Contract_Id__c ='Test12345';
      contractRec.Contract_Type__c = 'Value Added Reseller';       
      insert contractRec;*/
         
      Merge_Contract_Header__c contractRec = [Select Id from Merge_Contract_Header__c LIMIT 1];
         
      Merge_Contract_Header__c contractRec1 = new Merge_Contract_Header__c();
      contractRec1.Name = 'Test1234';
      contractRec1.Account_Name__c = accTest.ID;
      contractRec1.Original_Contract_Id__c ='Test1234';
      contractRec1.Contract_Type__c = 'Tier 1 Reseller';
      contractRec1.Parent_Contract__c =  contractRec.id;      
      insert contractRec1;  
  
         Case caseTest;
         test.startTest();
         //SC_CPSNotifications.accIdForTestClass.add(accTest.Id);
         for(integer i = 0;i <= 8;i++){
             caseTest = new case();
             caseTest.AccountId = accTest.Id ;
             caseTest.Severity__c = '3';  
             caseTest.Subject = 'CPS Test';
             caseTest.Description = 'CPS Test';
             caseTest.Service__c = 'TLS/SSL Certificate Provisioning';
             caseTest.Request_Type__c ='Renew Certificate';
             caseTest.Do_Not_Show_in_Portal__c = False;          
             caseTest.Sub_Type__c = 'Product Support'; 
             caseTest.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Web Experience').getRecordTypeId();       
             caseTest.origin = 'Others';
             caseTest.Cert_Admin_Contact_Email__c = 'abc@test.com';
             caseTest.CertTechnicalContactEmail__c = 'abc@test.com';
             caseTest.CertRequestorEmail__c = 'abc@test.com';
             caseTest.IR_Original_Contract_Id__c = contractRec1.id;
             if(i == 0){
                 caseTest.Status = 'Renewal Started';//done
                 caseTest.Request_Sub_Type__c = 'CPS-Automated';
                 caseTest.CertificateAuthority__c =  'Will Encrypt';   
             }
             else if( i == 1){
                 caseTest.Status = 'Renewal Started';
                 caseTest.Request_Sub_Type__c = 'Third Party';
             }
             else if(i == 2){
                 caseTest.Status = 'New Certificate Requested';
                 caseTest.Request_Sub_Type__c = 'CPS-Automated';
                 caseTest.CertificateAuthority__c =  'Will Encrypt';//done
             }
             else if(i == 3){
                 caseTest.Status = 'New Certificate Requested';
                 caseTest.Request_Sub_Type__c = 'CPS-Automated';
                 caseTest.CertificateAuthority__c =  'Let\'s Encrypt';//done
             }
             else if(i == 4){
                 caseTest.Status = 'Renewal Started';
                 caseTest.Request_Sub_Type__c = 'CPS-Automated';
                 caseTest.CertificateAuthority__c =  'Let\'s Encrypt';//done
             }
             else if(i == 5){
                 caseTest.Status = 'Renewal Started';
                 caseTest.Request_Sub_Type__c = 'CPS-Automated';
                 caseTest.CertificateAuthority__c =  'Testing 123';//done
             }
             else if(i == 6){
                 caseTest.Status = 'Renewal Started';
                 caseTest.Service__c = 'TLS/SSL Certificate Provisioning';
                 caseTest.Request_Type__c =  'Renew Certificate';
                 caseTest.Request_Sub_Type__c = 'Third-Party';//done
             }
             else if(i == 7){
                 caseTest.Status = 'Renewal Started';
                 caseTest.Service__c = 'TLS/SSL Certificate Provisioning';
                 caseTest.Request_Type__c =  'New Certificate';//done
             }
             caseList.add(caseTest);            
         } 
         Insert caseList;
         
         list<case> caseUpdateList = [Select id,AccountId,Status,CPSExpiration5Days__c,CPSExpiration15Days__c,CPSExpiration8Days__c,CPSExpiration1DayAfter__c,CPSDaysBeforeExpiry__c,CertificateAuthority__c,Request_Sub_Type__c,Service__c,Request_Type__c 
                                      from case where Id IN :caseList]; 
         List<Case> cUpdate = new List<Case>();     
         for(Case varCase : caseUpdateList){
             SC_CPSNotifications.cpsRecCheck = False;
             if(varCase.Status == 'Renewal Started' && varCase.Request_Sub_Type__c ==  'Third-Party'){
                 varCase.Status =  'Error in Order at CA';
             }
             if(varCase.Status == 'Renewal Started' && varCase.Request_Sub_Type__c == 'CPS-Automated' && varCase.CertificateAuthority__c ==  'Will Encrypt'){
                 varCase.CertificateAuthority__c =  'Will Encrypt 123';
                 varCase.CPSExpiration5Days__c = true;
             }
             if(varCase.Status == 'Renewal Started' && varCase.Request_Sub_Type__c == 'CPS-Automated' && varCase.CertificateAuthority__c ==  'Let\'s Encrypt'){
                 varCase.Request_Sub_Type__c =  'Third-Party';
                 varCase.CPSExpiration15Days__c = true;
             }
             if(varCase.Status == 'Renewal Started' && varCase.Request_Sub_Type__c == 'CPS-Automated' && varCase.CertificateAuthority__c ==  'Testing 123'){
                 varCase.Status = 'Pre-verification Failed';
                 varCase.CPSExpiration8Days__c = true;
             }
             if(varCase.Status == 'Renewal Started' && varCase.Service__c == 'TLS/SSL Certificate Provisioning' && varCase.Request_Type__c ==  'Renew Certificate'){
                 varCase.Status =  'Post-verification Warning';
                 varCase.CPSExpiration1DayAfter__c = true;
             }
             if(varCase.Status == 'Renewal Started' && varCase.Service__c == 'TLS/SSL Certificate Provisioning' && varCase.Request_Type__c ==  'New Certificate'){
                 varCase.Status =  'Post-verification Error';
             }
             if(varCase.Status == 'New Certificate Requested' && varCase.Request_Sub_Type__c == 'CPS-Automated' && varCase.CertificateAuthority__c ==  'Will Encrypt'){
                 varCase.Status =  'Waiting on Change Management';
                 varCase.CPSDaysBeforeExpiry__c = '1';
             }
             if(varCase.Status == 'New Certificate Requested' && varCase.Request_Sub_Type__c == 'CPS-Automated' && varCase.CertificateAuthority__c ==  'Let\'s Encrypt'){
                 varCase.Status = 'Certificate Deployed';
             }
             cUpdate.add(varCase); 
         }
         Update cUpdate;
         test.stopTest();
    }

     // Method# 40: CR 3622181
    @isTest public static void testSCEmailCaseTeamCtrl(){
        //List<Account> lAc = [Select id from Account Limit 3];
        //print lAc value.....
        //System.debug('----------------The value of lAc is '+ lAc);
        /*List<Account> lAc = new List<Account>();
        for(Integer i=0; i<3; i++)
        { Account ac = utilTestClass.CreateAccount('TestAccount zpxtx '+i);
            lAc.add(ac);
        }
        insert lAc;*/
        /*List<Case> lC = new List<Case>();
        for(Account ac : lAc)
        { Case c = utilTestClass.CreateCase(ac.Id);
          lC.add(c);
        }
        
        List<Contact> lCon = new List<Contact>();
        
        List<Contact> lExContacts = [Select Id from Contact Limit 3];
        for(Integer i=0; i<2; i++)
        {
            //Contact con = utilTestClass.CreateContact('Pinkesh'+i,'Rathore'+i);
            lExContacts[i].AccountId = lAc[i].Id;            
            lCon.add(lExContacts[i]);
        }
        insert lCon;
        */
        List<CaseTeamRole> ctr = [Select Id, Name from CaseTeamRole where Name='Technical Escalation' or Name='Stability Eng' Limit 1];
        
        Account accRec = [Select Id from Account Limit 1];
        List<Case> lC = [Select Id from Case Limit 1];
        Contact conRec = [Select Id from Contact Limit 1];
        
        List<CaseTeamMember> lctm = new List<CaseTeamMember>();
        
       /*for(Integer i=0; i<2; i++)
        {
            CaseTeamMember ctm = new CaseTeamMember();
          ctm.ParentId = lC[i].Id;
          ctm.TeamRoleId = ctr[0].Id;
          ctm.MemberId = lCon[i].Id;
          lctm.add(ctm);
        }
        CaseTeamMember ctm = new CaseTeamMember();
        ctm.ParentId = lC[2].Id;
        ctm.TeamRoleId = ctr[0].Id;
        System.runAs ( new User(Id = UserInfo.getUserId()) ){
          User u = utilTestClass.CreateUser('prathore', 'Worldwide', 'System Administrator');
          insert u;
            ctm.MemberId = u.Id;
        }
        lctm.add(ctm);
        insert lctm;*/
        
        CaseTeamMember ctm = new CaseTeamMember(ParentId = lC[0].Id,TeamRoleId = ctr[0].Id,MemberId=conRec.Id);
        lctm.add(ctm);
        
      /*  Profile pfl = [select id from Profile where name = 'System Administrator' limit 1];
      User usr = [select Id from User where IsActive = True and ProfileId = :pfl.Id limit 1];
        
        CaseTeamMember ctm1 = new CaseTeamMember(ParentId = lC[0].Id,TeamRoleId = ctr[0].Id,MemberId=usr.Id);
        lctm.add(ctm1);*/
        
        insert lctm;
        
        test.startTest();
        for(Case c : lC){
          PageReference pageRef = Page.EmailCaseTeam;
          test.setCurrentPage(pageRef);
          ApexPages.StandardController sc = new ApexPages.StandardController(c);
          ApexPages.currentPage().getParameters().put('Id',c.ID);
          SCEmailCaseTeamCtrl SCEmail = new SCEmailCaseTeamCtrl(sc);
          SCEmail.allCaseTeamMembers();
        }
        
        test.stopTest();
        
    } 
    
     // Method# 41 : Method to cover CommonUtilClass
    @isTest static void CommonUtilClassTest()
    {
        
        Test.StartTest();
        try{
          Task TaskRec = new Task();
          TaskRec.subject=null;
          TaskRec.OwnerId='004566666';
          insert TaskRec;
        }catch(Exception e){
            e.setMessage('First exception on row 0; first error: FIELD_CUSTOM_VALIDATION_EXCEPTION, You must select an Organization or Contact: []');
          CommonUtilClass.ExtractValidationExMsg(e);
        }
         
        Test.StopTest();
        
    }
    
     // Method# 42 : Method to cover CommonUtilClass
    @isTest static void BillingCashAppsClassTest()
    {
        set<Id> allIds = new set<Id>();
      //Step 1 - Create Case record
        Case CaseRec = new case();
        CaseRec.Status = 'Unassigned';
        CaseRec.Origin = 'Email';
        CaseRec.subject = 'Billing-CashAppTest';
        CaseRec.Description = 'Billing-CashAppTest';
        insert CaseRec;
        allIds.add(CaseRec.Id);
        
        //Step 2 - Create EmailMessage Record
        EmailMessage emailrec = new EmailMessage();
        emailrec.FromAddress = 'billing_test@akam.com';
        emailrec.Incoming = true;
        emailrec.ParentId = CaseRec.Id;
        emailrec.Subject = 'Update Invoice';
        emailrec.TextBody = 'Update Invoice';
        emailrec.ToAddress = 'billingTo@akam.com';
        Insert emailrec;
        
        //Step 3 - Create Attachment Record
        List<Attachment> attList = new List<Attachment>();
        Attachment attrec = new Attachment();
        attrec.Body = Blob.valueOf('billing details are here..');
        attrec.Name = 'Billing Invoice#123-1';
        attrec.ParentId = emailrec.Id;
        attList.add(attrec);
        
        attrec = new Attachment();
        attrec.Body = Blob.valueOf('billing details are here..');
        attrec.Name = 'Billing Invoice#123-2';
        attrec.ParentId = emailrec.Id;
        attList.add(attrec);

      /**** Commenting out this code since *****/
      
        // changes by Vandhana - ESESP-564 Increase code coverage
        /*
        Draft_Invoice__c draftInv = new Draft_Invoice__c(Name='DF123');
        insert draftInv;
        attrec = new Attachment();
        attrec.Body = Blob.valueOf('billing details are here..');
        attrec.Name = 'Billing Invoice#123-2';
        attrec.ParentId = draftInv.Id;
        attList.add(attrec);

        attrec = new Attachment();
        attrec.Body = Blob.valueOf('Billing Details');
        attrec.Name = 'Billing Invoice#123-7';
        attrec.ParentId = CaseRec.Id;
        attrec.OwnerId = SCUserIdCustomSetting__c.getValues('LunaPortalIntegration').UserId__c;
        attList.add(attrec);
        */

        //end of changes
      /**** Commenting out this code since ******/
        
        Insert attList;
        
        Test.StartTest();
        
          SC_Billing_CashApps.SendEmailToCashAppsTeam(allIds);
        
        try{
            SC_SupportEmail__c ss = SC_SupportEmail__c.getValues('1');
            ss.CashAppsEmail__c= null;
            update ss;
            
          SC_Billing_CashApps.SendEmailToCashAppsTeam(allIds);
        }catch(exception e){}
         
        Test.StopTest();
        
    }
    
    // Method# 43 : Method to cover SC_CaseTriggerHelperClass ----- Changes by Sumukh SS
    @isTest static void SC_TriggerHelperTest()
    {
        /*System.debug('Number of Queries used in this apex code so far SC_TriggerHelperTest: ' + Limits.getQueries());

Account accRec = new Account(Name='Test Account IP Address',AKAM_Account_ID__c='Test-ABC-1234IPAddr',Type='Brand - Active', Is_SOCC_Premium_Customer__c = True, Parent_Division__c = 'Web Americas_Web', Division__c = 'Acquisition & ECG');
insert accRec; 
System.debug('Number of Queries used in this apex code so far SC_TriggerHelperTest after account: ' + Limits.getQueries());


list<contact> lcont = new list<contact>();
Contact conRec = new Contact(AccountId = accRec.Id, Login__c = 'Test_xyz', Email = 'Test_xyz1234@akamai.com',
No_Longer_with_Company__c = false, LastName = 'Test ContactAcc');
lcont.add(conRec);

contact conRec2 = new Contact(AccountId = accRec.Id, Login__c = 'Test_xyz2', Email = 'Test_xyz2@akamai.com',
No_Longer_with_Company__c = false, LastName = 'Test ContactAcc2');

lcont.add(conRec2);

insert lcont;*/
        //Account accRec = [Select Id from Account Limit 1];
        List<Contact> lConRec = [Select Id,Name,AccountId from Contact Limit 2];
        //Policy_Domain__c pdRec=[Select Id from Policy_Domain__c LIMIT 1 ];
        System.debug('----The contacts list are '+ lConRec);
        //Id accId = lconRec[0].AccountId;
        //conRec = [Select Id,Name from Contact Limit 2];
        //Contact conRec2 = [Select Id,Name from Contact Limit 1];
        
        System.debug('Number of Queries used in this apex code so far SC_TriggerHelperTest after contact: ' + Limits.getQueries());
        
        // Creating Policy Domain Record
        Policy_Domain__c pdRec = new Policy_Domain__c();
        pdRec.Name = 'Test PD1';
        pdRec.AKAM_Policy_Domain_ID__c = 'Test-123';
        pdRec.Account_Name__c = lconRec[0].AccountId;
        pdRec.Product__c = 'Test Prod 123';
        pdRec.Policy_Domain_State__c = 'Active';
        insert pdRec;
        
        System.debug('Number of Queries used in this apex code so far SC_TriggerHelperTest after PD: ' + Limits.getQueries());
        
        // Creating Authorized Contacts
        /*list<Authorized_Contact__c> lAuthContact = new list<Authorized_Contact__c>();
        
        Authorized_Contact__c acRec = new Authorized_Contact__c(Policy_Domain__c=pdRec.Id, Contact_Name__c = lConRec[0].Id, Product_Interests__c = 'All',Contact_Created_By__c =lConRec[1].Id );
        lAuthContact.add(acRec);
        Authorized_Contact__c serAcRec = new Authorized_Contact__c(Policy_Domain__c = pdRec.Id, Contact_Name__c = lConRec[1].Id, Service__c = true, Product_Interests__c = 'All',Contact_Created_By__c =lConRec[1].Id);
        lAuthContact.add(serAcRec);
        
        insert lAuthContact;*/
        
        System.debug('Number of Queries used in this apex code so far SC_TriggerHelperTest after Auth contact: ' + Limits.getQueries());
        
        //Creating Case Products
        
        /* EB_AccountProductMap__c caseProd = new EB_AccountProductMap__c ();
caseProd.Name = 'Test Prod 123';
caseProd.EB_Account__c = accRec.Id;
caseProd.EB_Product__c = 'Test Prod 123';
insert caseProd;*/
        //EB_AccountProductMap__c caseProd;
        //if(lConRec.size()>0){caseProd = [Select id from EB_AccountProductMap__c where EB_Account__c = :lConRec[0].AccountId Limit 1];}
        EB_AccountProductMap__c caseProd = [Select id from EB_AccountProductMap__c where EB_Account__c = :lConRec[0].AccountId and Name ='Test Prod 123' Limit 1];
        System.debug('Number of Queries used in this apex code so far SC_TriggerHelperTest after Case prod: ' + Limits.getQueries());
        
        Entitlement entl = new entitlement(name='Carrier Entitlement',accountid = lconRec[0].AccountId,type ='Phone Support', StartDate=Date.valueof(System.now().addDays(-2)), EndDate=Date.valueof(System.now().addYears(2)));
        insert entl;
        Test.StartTest();
        List<SlaProcess> lstEntitlementProcess = [SELECT Id, Name FROM SlaProcess WHERE Name='Carrier Products EP' and IsActive = true LIMIT 1];
        if (lstEntitlementProcess.size()>0)
        {
            entl.SlaProcessId = lstEntitlementProcess[0].id;
            update entl;        
        }
        
        
        
        List<Case> lstCase = new List<Case>();
        List<Id> lstCaseId = new List<Id>();

        Case cs = new Case();
        cs.Description = 'test';
        cs.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        cs.Sub_Type__c = 'Carrier';
        cs.Subject = 'New Carrier';
        cs.Do_Not_Show_In_Portal__c = true;
        cs.Validation_Override__c = true;
        cs.EntitlementId = entl.Id;
        lstCase.add(cs);
        lstCaseId.add(cs.Id);
        
        Id managedSecurityRT = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Managed Security').getRecordTypeId();
        list<string> allIds = new list<string>();
        //Step 1 - Create Case record
        Case CaseRec = new case();
        CaseRec.Status = 'Unassigned';
        CaseRec.RecordTypeId = managedSecurityRT;
        CaseRec.Origin = 'Email';
        CaseRec.subject = 'Sample Case';
        CaseRec.Description = 'Sample Case';
        CaseRec.ContactId = lconRec[0].Id;
        CaseRec.AccountId = lconRec[0].AccountId;
        lstCase.add(CaseRec);
        
        insert lstCase;
        allIds.add(CaseRec.Id);
        
        SC_CaseTriggerHelperClass.technicalBOCCnCarrierMilestonesUpdate(allIds,'Resolution');
        
        Map<id,id> lCasePolicyDomainIdMap = new Map<id,id>();
        Map<Id,String> caseProductMap = new Map<Id,String>();
        Map<id,id> lClosedCasePolicyDomainIdMap = new Map<id,id>();
        Map<Id,String> closedCaseProductMap = new Map<Id,String>();
        Map<Id,Boolean> additionalEmailMap = new Map<Id,Boolean>();
        Map<Id,Boolean> authConEmailMap = new Map<Id,Boolean>();
        
        Case updateCaseRec;
        Case updateClosedCaseRec;
        
        //System.debug('--------The Ids are  ' +varCase.Id );
        System.debug('--------The Ids are a ' +caseProd.Id );
        System.debug('--------The Ids are b ' +pdRec.Id );
        for(Case varCase : [Select id, policy_domain__c, Case_Product__c, AuthorizedContacts__c, Case_Prod_Name__c from Case where id in: allIds])
        {
            updateCaseRec = new case();
            updateCaseRec.id = varCase.Id;
            updateCaseRec.Case_Product__c = caseProd.Id;
            updateCaseRec.Policy_Domain__c = pdRec.Id;
            //updateCaseRec.Case_Product__c = caseProd.Id;
            //updateCaseRec.Policy_Domain__c = lconRec[0].AccountId;
            updateCaseRec.AuthorizedContacts__c = 'test@akamai.com';
            additionalEmailMap.put(varCase.Id, true);
            authConEmailMap.put(varCase.Id, true);
            System.debug('--------The Ids are 1 ' +varCase.Id );
        }
        update updateCaseRec;
        
         //System.debug('--------The Ids are  ' +varCase.Id );
        System.debug('--------The Ids are 2 ' +caseProd.Id );
        System.debug('--------The Ids are 3 ' +pdRec.Id );
        for(Case varCase : [Select id,policy_domain__c, Case_Product__c, Case_Prod_Name__c,Status from Case where id =: updateCaseRec.ID])
        {
            lCasePolicyDomainIdMap.put(varCase.id, varCase.policy_Domain__c);
            caseProductMap.put(varCase.id, varCase.Case_Prod_Name__c);
            updateClosedCaseRec = new case();
            updateClosedCaseRec.id = varCase.Id;
            updateClosedCaseRec.status = 'Closed';
        }
        update updateClosedCaseRec;
        for(Case varCase : [Select id,policy_domain__c, Case_Product__c, Case_Prod_Name__c,Status from Case where id =: updateClosedCaseRec.Id])
        {
            lClosedCasePolicyDomainIdMap.put(varCase.id, varCase.policy_Domain__c);
            closedCaseProductMap.put(varCase.id, varCase.Case_Prod_Name__c);
        }
        
        SC_CaseTriggerHelperClass.sendEmailToAuthorisedContacts(allIds,false,lCasePolicyDomainIdMap,caseProductMap,additionalEmailMap,authConEmailMap);
        SC_CaseTriggerHelperClass.sendEmailToAuthorisedContacts(allIds,true,lCasePolicyDomainIdMap,caseProductMap,additionalEmailMap,authConEmailMap);
        SC_CaseTriggerHelperClass.sendEmailToAuthorisedContacts(allIds,false,lClosedCasePolicyDomainIdMap,closedCaseProductMap,null,null);
        SC_CaseTriggerHelperClass.sendEmailToAuthorisedContacts(allIds,true,lClosedCasePolicyDomainIdMap,closedCaseProductMap,null,null);
        //SC_CaseTriggerHelperClass.sendEmailOnVerivueUpdate(allIds);
        SC_CaseTriggerHelperClass.createEmailSubjectForCaseCloser(CaseRec);
        SC_CaseTriggerHelperClass.createEmailBodyForCaseCloser(CaseRec);
        string getDetails = SC_CaseTriggerHelperClass.createEmailBody(CaseRec);
        //getDetails = SC_CaseTriggerHelperClass.createEmailBodyForVerivue(CaseRec);
        getDetails = SC_CaseTriggerHelperClass.createEmailSubject(CaseRec);
        //getDetails = SC_CaseTriggerHelperClass.createEmailSubjectForVerivue(CaseRec);
        getDetails = SC_CaseTriggerHelperClass.createEmailSubjectForCaseCloser(CaseRec);
        getDetails = SC_CaseTriggerHelperClass.createEmailBodyForCaseCloser(CaseRec);
        
        Test.StopTest();
    }
  
    //3622181 This test method is used to cover code for SC_Utility class
    //changes by Saiyam - To increase coverage in SC_Utility for BOCC Case Transition logic - ESESP-5957
    @isTest public static void SC_UtilityTest()
    {
        test.startTest();
        //changes by Saiyam - BOCC Case Transition logic - ESESP-5957
        SC_Utility.getCurrentShiftDetails('BOCC');
        SC_Utility.getShiftDateTime('Weekend APAC/EMEA','BOCC');
        SC_Utility.getShiftDateTime('Weekend America','BOCC');
        SC_Utility.getShiftDateTime('Americas - 1','BOCC');
        SC_Utility.getShiftDateTime('Americas - 2','BOCC');
        SC_Utility.getShiftDateTime('APJ','BOCC');
        SC_Utility.getShiftDateTime('EMEA','BOCC');
        
        SC_Utility.getCurrentShiftDetails('Akatec');
        SC_Utility.getShiftDateTime('Weekend','Akatec');
        SC_Utility.getShiftDateTime('EMEA','Akatec');
        SC_Utility.getShiftDateTime('US East','Akatec');
        SC_Utility.getShiftDateTime('US West','Akatec');
        SC_Utility.getShiftDateTime('APAC','Akatec');
        String s = SC_Utility.ImageConverter('<img src="smiley.gif">');
        
        //changes by Saiyam - To cover SC_Utility.createOffboardingCase - ESESP-5957
        
        PSA_TestUtility testUtil;
        pse__Region__c reg;
        Account acct;
        Contact resource;
        pse__Proj__c proj1;
        pse__Practice__c pract;
        Id practId;
        User usr;
        User usr2;
        Merge_Contract_Header__c contract;
        
        testUtil = new PSA_TestUtility();
        usr = testUtil.newUserSysAdmin(false); 
        usr2 = testUtil.newUserSysAdmin(true); 
        usr.ManagerId = usr2.id;
        usr.UserName =  '4201' + usr.UserName;
        usr.Title = 'Manager..Service Line';
		insert usr;
        
        reg = testUtil.newRegionMaster(true);
        acct = testUtil.newAccount(true);
        pract = testUtil.newPracticeMaster(true);
        practId = pract.ID;
        
        resource = testUtil.newResource(false, acct.Id, usr.Id);
        resource.email = 'PSAProjMgr2@akamai.com';
        insert resource;


        proj1 = testUtil.newProject(true,reg.id,practId,true,'One-Time: Fixed Price', resource.Id, acct.Id);
        
        contract = testUtil.newContract(true, acct.Id, '123','456',null,System.today(), System.today().addDays(50));
        Case cs = SC_Utility.createOffboardingCase('SOA', proj1, contract.Id, false);
        Case cs2 = SC_Utility.createOffboardingCase('PLUS', proj1, contract.Id, false);
    test.stopTest();
    }
    
    //cover autogen usecases
    @isTest public static void test_autogen(){
        id psQueueId = [select Id from Group where Name = 'PS_APJ_Queue' and Type = 'Queue' limit 1].id;
        id rtId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('AMG').getRecordTypeId();
        Case cs = new Case(subject='Test', description='test',OwnerId = psQueueId,
            RecordTypeId=rtId,Origin = 'Autogen', Autogen_UseCase__c='PLXR-COB');
        insert cs;
        Test.startTest();
        SC_CaseTriggerHelperClass.flagvalue = false;
        cs.Request_Type__c = 'Customer Onboarding';
        cs.AKAM_Created_By__c = 'CRMOPS';
        cs.Service__c = 'Accounts Audits';
        //cs.OwnerId = userInfo.getUserId();
        update cs;
        SC_CaseTriggerHelperClass.createEmailSubjectForCaseCloser(cs);
        SC_CaseTriggerHelperClass.createEmailBodyForCaseCloser(cs);
        Test.stopTest();
        
        
    }
    @isTest public static void CaseProductWidget(){
    User currentusrCPW = [Select id from User where Id = :UserInfo.getUserId()];
     List<Case> cUpdateCPW = new List<Case>();    
     System.RunAs(currentusrCPW)
     {
         Environment_Setup__c environmentSetup = Environment_Setup__c.getOrgDefaults();
         environmentSetup.Active_Org__c = true;
         update environmentSetup;
     }
      Account accTestCPW = new Account();
      accTestCPW.Name ='Test1234';
      accTestCPW.Website ='www.google.com';
      accTestCPW.Support_Level__c = 'Premium';  
        
      insert accTestCPW;
      
      EB_AccountProductMap__c ProdTestCPW = new EB_AccountProductMap__c(); 
      ProdTestCPW.Name = 'Other';
      ProdTestCPW.EB_Account__c = accTestCPW.Id;
      ProdTestCPW.EB_Product__c = 'Other';
      
      insert ProdTestCPW;
        
      
        
        Case caseTestCPW = new Case();
        caseTestCPW.AccountID = accTestCPW.Id ;
        caseTestCPW.Severity__c = '2';
        caseTestCPW.Status = 'Unassigned';  
        caseTestCPW.Subject = 'CCCC';
        caseTestCPW.Description = 'CCCCC123';
        caseTestCPW.Case_Product__c  = ProdTestCPW.Id;
        caseTestCPW.Problem__c = 'Alerts';
        caseTestCPW.Service_Category__c ='Product Support';
        caseTestCPW.Do_Not_Show_in_Portal__c = False;
        caseTestCPW.Sub_Type__c = 'Product Support';  
        caseTestCPW.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical').getRecordTypeId();       
        caseTestCPW.origin = 'Others';
        
        insert caseTestCPW;
        test.startTest();
          PageReference pageRef = Page.SC_CaseProductWidget;
          test.setCurrentPage(pageRef);
          ApexPages.StandardController sc = new ApexPages.StandardController(caseTestCPW);
          ApexPages.currentPage().getParameters().put('Id',caseTestCPW.ID);
          SC_CaseProductWidget scCPW = new SC_CaseProductWidget(sc);
          scCPW.saveCaseProduct();
          scCPW.getisWidgetEnabled();

        test.stopTest();
    
    }
        //Test Coverage for NQLB in CaseTrigger_bi_bu 
    @isTest public static void test_NQLB(){
  
       id communityResponseRTId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Community Response').getRecordTypeId();
        
    
        Test.startTest();
        List<Case> lCase= new List<Case>();
        Case cs = new Case(subject='Test', description='test',RecordTypeId = communityResponseRTId,Origin = 'Community',status ='Assigned',OwnerId = userInfo.getuserid());
        lCase.add(cs);
        Case cs1 = new Case(subject='Test1', description='test1',RecordTypeId = communityResponseRTId,Origin = 'Community',status ='Assigned',OwnerId = userInfo.getuserid());
        lCase.add(cs1);
        
        insert lCase;
        
        //List<Case> lcase= [Select Id from Case Limit 2];
        Case updatecase = new case();
        updatecase.id = lCase[0].id;
        updatecase.status = 'Work in Progress';
        update updatecase;
        
        Case updatecase1 = new case();
        updatecase1.id = lCase[1].id;
        updatecase1.JNQ__isCorrectAnswer__c = true;
        update updatecase1;
        Test.stopTest(); 
    }
    
    @isTest public static void SC_Special_Instrcutions_Test_Lightning()
    {   
        
        
        List<folder> fol = new list<folder>([select id,name from folder where name ='SC Data' limit 1]);

        Document doc = new Document();
        doc.Name = 'Media';
        doc.FolderId = fol[0].id;
        insert doc;
            
        //Account Acc = utilTestClass.CreateAccount('TestAccountzxunique');
        //insert Acc ;
        
        Account Acc= [Select Id from Account Limit 1]; 
        
        /*Special_Instruction_Template__c splInstrTemp = new Special_Instruction_Template__c();
        splInstrTemp.Instructions__c = 'test';
        splInstrTemp.Show_for_Record_Types__c = 'All except Managed Security';
        splInstrTemp.Title__c = 'test';
        splInstrTemp.name = 'test';
        splInstrTemp.Flag_Icon__c = 'Media';   
        
        insert splInstrTemp;
        
        Special_Instructions__c splInstObj = new Special_Instructions__c();
        splInstObj.Title__c = 'test1';
        splInstObj.Instructions__c = 'test1';
        splInstObj.Start_Date__c = system.today();
        splInstObj.Account__c = Acc.Id;
        splInstObj.Show_for_Record_Types__c = 'All except Managed Security';
        splInstObj.Special_Instruction_Template__c = splInstrTemp.id ; 

        insert splInstObj;
        
        Special_Instructions__c splInstObjNoTemp = new Special_Instructions__c();
 
        splInstObjNoTemp.Title__c = 'test95';
        splInstObjNoTemp.Instructions__c = 'test95';
        splInstObjNoTemp.Start_Date__c = system.today();
        splInstObjNoTemp.Account__c = Acc.Id;
        splInstObjNoTemp.Show_for_Record_Types__c = 'All except Managed Security';

        insert splInstObjNoTemp;*/
        
        List<Special_Instructions__c> lSplInstObj = [Select Id, Title__c,Instructions__c,Start_Date__c,Account__c,Show_for_Record_Types__c from Special_Instructions__c Limit 2];
      Special_Instruction_Template__c splInstrTempObj = [Select Id,Instructions__c,Show_for_Record_Types__c,Title__c,name,Flag_Icon__c from Special_Instruction_Template__c Limit 1];

        List<Special_Instruction_Template__c> SIT_List; 
        String ret_Val;
        Boolean ret_bool;
        test.startTest();
           SIT_List=SC_Special_Instructions.get_Special_Instruction_Template_List();
      ret_Val=SC_Special_Instructions.Insert_Special_Instruction_With_Template(system.today(),system.today(),splInstrTempObj.id,Acc.id);
    ret_Val=SC_Special_Instructions.Insert_Special_Instruction_WithOut_Template(Acc.id,system.today(),system.today(),lSplInstObj[0].Title__c,splInstrTempObj.Instructions__c,lSplInstObj[0].Show_for_Record_Types__c);
      ret_Val=SC_Special_Instructions.Update_Special_Instruction_With_Template(system.today(),system.today(),splInstrTempObj.id,Acc.id,lSplInstObj[0].id);
      ret_Val=SC_Special_Instructions.Update_Special_Instruction_WithOut_Template(Acc.id,system.today(),system.today(),lSplInstObj[0].Title__c,splInstrTempObj.Instructions__c,lSplInstObj[0].Show_for_Record_Types__c,lSplInstObj[0].id);
      ret_bool=SC_Special_Instructions.Is_SI_With_Template(lSplInstObj[0].id);
      ret_bool=SC_Special_Instructions.Is_SI_With_Template(lSplInstObj[1].id);
      SIT_List=SC_Special_Instructions.get_SI_Template_details(lSplInstObj[0].id);
        SIT_List=SC_Special_Instructions.get_SI_Template_details(lSplInstObj[1].id);
      ret_Val=SC_Special_Instructions.getLogoUrl(splInstrTempObj.name);
      
      
        Test.stopTest(); 
        
    }
    
    //Deleting Account team member should delete case notification record
    public testmethod static void test_deleteAccTeamMember(){
      test.startTest();
            Account acc = new Account(AKAM_Account_ID__c='Test1234abc1',Name='Test1234abc1',Type='- Active');
            insert acc;
            AccountTeamMember atmRec = new AccountTeamMember(AccountId = acc.Id,UserId = UserInfo.getUserId(),TeamMemberRole = 'CXM');
            insert atmRec;
            System.assertEquals([select id from Case_Notification_Subscription__c where Account__c=:acc.id].size(),1);
            delete atmRec;
            System.assertEquals([select id from Case_Notification_Subscription__c where Account__c=:acc.id].size(),0);
        test.stopTest();
  }
    //Changes by Harshil
    //Test case for User License change to GSS- UserTrigger_bi_bu
    static testmethod void UserLicenseChangeTest()
    {
        
        User currentusr = [Select id from User where Profile.Name = 'System Administrator' and isactive = true LIMIT 1];
      
      System.RunAs(currentusr)
      {
     
        SC_KB_GSS_profiles__c gssProfile = new SC_KB_GSS_profiles__c();
        gssProfile.ProfileId__c  = '00eG0000000f2cjIAA';
        gssProfile.Name = 'GSS Professional Services';   
        insert gssProfile;
        
        PSA_Profiles_For_License_Automation__c psaSetting = new PSA_Profiles_For_License_Automation__c();
        psaSetting.Name  = 'GSS Professional Services';
        psaSetting.Profile_Names__c = '00eA0000000QkKr';
        insert psaSetting;
          
      }
        test.startTest();
        User testUser1 = UtilTestClass.createUser('SEUsr','Worldwide','Salesforce Engineering');
        insert testUser1;
        User testUser2 = UtilTestClass.createUser('SPUsr','Worldwide','Standard Platform User');
        insert testUser2;
        User testUser3 = UtilTestClass.createUser('GSSUsr','Worldwide','GSS Professional Services');
        insert testUser3;
        Id platformProfileId = [Select Id from Profile where Name = 'Standard Platform User'].Id;
        Id sfEnggProfileId = [Select Id from Profile where Name = 'Salesforce Engineering'].Id;
        //Updating Profile will change license and trigger UserTrigger_bi_bu
        testUser1.ProfileId = platformProfileId;
        update testUser1;
        testUser2.ProfileId = sfEnggProfileId;
        update testUser2;
        test.stopTest();
    }
    //End of changes by Harshil
  
    static testmethod void AuthContactTest(){
        
        System.debug('Number of Queries used in this apex code so far method 1' + Limits.getQueries());
        
        //Policy_Domain__c pdRec=[Select Id from Policy_Domain__c LIMIT 1 ];
        List<Contact> lConRec = [Select Id,Name,AccountId from Contact Limit 2];

		Policy_Domain__c pdRec = new Policy_Domain__c();
        pdRec.Name = 'Test PD1';
        pdRec.AKAM_Policy_Domain_ID__c = 'Test-123';
        pdRec.Account_Name__c = lconRec[0].AccountId;
        pdRec.Product__c = 'Test Prod 123';
        pdRec.Policy_Domain_State__c = 'Active';
        insert pdRec;  
        
        System.debug('Number of Queries used in this apex code so far method 2' + Limits.getQueries());
        
        list<Authorized_Contact__c> lAuthContact = new list<Authorized_Contact__c>();
        
        Authorized_Contact__c acRec = new Authorized_Contact__c(Policy_Domain__c=pdRec.Id, Contact_Name__c = lConRec[0].Id, Product_Interests__c = 'All',Contact_Created_By__c =lConRec[1].Id );
        lAuthContact.add(acRec);
        Authorized_Contact__c serAcRec = new Authorized_Contact__c(Policy_Domain__c = pdRec.Id, Contact_Name__c = lConRec[1].Id, Service__c = true, Product_Interests__c = 'All',Contact_Created_By__c =lConRec[1].Id);
        lAuthContact.add(serAcRec);
        
        test.startTest();
        insert lAuthContact;
        test.stopTest();
        
        System.debug('Number of Queries used in this apex code so far method 3' + Limits.getQueries());
    }
 
    // Test method for customer surveys on internal AMG Cases 
    @isTest public static void testInternalAMGCustSurveys(){
        
        User amgUser = [Select id,email from user where profile.name like '%Support - AMG%' and isactive = true and email !='' limit 1]; 
        Account acc = [Select id,Account_Status__c, Support_Level__c from Account where Name='Test Account'];
        Contact con = [Select id, email, Name, AccountId, Active_Portal_Login__c, Last_Time_Contact_Surveyed__c,No_Longer_with_Company__c from Contact where Email = 'abc@test.com'];
        
        system.runAs(amgUser)
        {
            Test.startTest();
            
            //Insert Case
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
            insert cs;
            
            // Insert Email Message
            EmailMessage[] newEmail = new EmailMessage[0]; 
            newEmail.add(new EmailMessage(FromAddress = amgUser.Email, Incoming = false, ToAddress= 'abc@test.com', Subject = 'Test email', TextBody = 'hello this a test email', ParentId = cs.Id));
            Database.insert(newEmail);
            
            cs.Request_Type__c = 'Contract Inquiry';
            cs.Solution_Summary__c = 'Test Summary';
            cs.Request_Sub_Type__c = 'Account Name Change';
            cs.LOE_Hours__c = 1;
            cs.LOE_Minutes__c = 2;
            cs.Origin = 'Akamai';
            cs.PRISM_Used__c= 'Yes';
            cs.Resolution_Field__c = 'N/A - Not Applicable';
            cs.ResolvableByPartner__c = 'No';
            cs.Status='Closed';
            update cs;

            // Insert Survey Contact
            CS_Survey_Contact__c surveyContact = new CS_Survey_Contact__c();
            surveyContact.CS_Contact_Name__c =con.Id;
            surveyContact.CS_Case__c = cs.Id;
            surveyContact.CS_Contact_Email__c = con.Email;
            insert surveyContact;
            
            surveyContact.Qualtrics_Survey_Notification_Sent__c = true;
            update surveyContact;
            
            Test.stopTest();
        }
    }
 }