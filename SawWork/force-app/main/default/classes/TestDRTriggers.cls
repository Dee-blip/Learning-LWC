/*
Author      : Sonia Sawhney
Description   : Contains test cases for all DR related triggers
Created Date  : 07/26/2013 
Modification History:
Modified by ssawhney on 20/03/2014 to Remove the see all data from test class 
Modified by ssawhney on 03/08/2016 to Add test setup method 
Modified by Vandhana on 2 June 2017 : Added case product for tech cases for case transitions to be created
Modified By Vamsee on 04/10/2017  : Added method for BOCCEntitlement Object
*/
@isTest
private class TestDRTriggers {
    
    @testSetup static void setupTestData(){
        utilTestClass.createCustomSettings();
        ExternalSharingHelper.RunFromtestClass = true; 
        
        list<Object_Lookup_Sync__c> lstLookups = new list<Object_Lookup_Sync__c>();
        Object_Lookup_Sync__c lookup1 = new Object_Lookup_Sync__c();
        lookup1.Name = 'Field1';
        lookup1.RW_Field_Name__c = 'User_RW__c';
        lookup1.Lookup_Field_Name__c = 'User__c';
        lookup1.Object_Name__c = 'Account_Team__c';
        lookup1.User_Lookup__c = true;
        lstLookups.add(lookup1);
        
        Object_Lookup_Sync__c lookup2 = new Object_Lookup_Sync__c();
        lookup2.Name = 'Field2';
        lookup2.RW_Field_Name__c = 'Account_RW__c';
        lookup2.Lookup_Field_Name__c = 'Account__c';
        lookup2.Object_Name__c = 'Account_Team__c';
        lookup2.User_Lookup__c = false;
        lstLookups.add(lookup2);
        insert lstLookups;
        
        list<Account> lstAcc = new list<Account>();
        Account acc = utilTestClass.CreateAccount('testDRAcc1');
        lstAcc.add(acc);
        
        Account acc1 = utilTestClass.CreateAccount('testDRAcc2');
        lstAcc.add(acc1);
        insert lstAcc;
        
        Contact cnt = utilTestClass.CreateContact('testDR' , 'contact1');
        cnt.AccountId = acc.Id;
        insert cnt;  

        EB_AccountProductMap__c ProdTest = new EB_AccountProductMap__c(); 
        ProdTest.Name = 'Riverbed_Product';
        ProdTest.EB_Account__c = acc.Id;
        ProdTest.EB_Product__c = 'Riverbed_Product';
        insert ProdTest;
        
        User usr = utilTestClass.CreateUser('testUsr1', 'System Administrator', 'System Administrator');
        usr.AKAM_User_ID__c = 'TEST_USER_ID';
        usr.UserPermissionsKnowledgeUser = true;

        User cUser = new User(Id = Userinfo.getUserId());

        System.runas(cUser) {
            insert usr;
        }
       
        Case objCase = utilTestClass.createCase(acc.Id);
    }
    //Test method to test the account trigger
    static testMethod void TestAccountDRTrigger() {
     
       ExternalSharingHelper.RunFromtestClass = true; 
       
       Account acc = [SELECT Id, Name FROM Account WHERE Name = 'testDRAcc1' LIMIT 1];
       Account acc1 = [SELECT Id, Name FROM Account WHERE Name = 'testDRAcc2' LIMIT 1];
     
       /*Test.startTest();
       acc1.Marketing_Parent_Account_RW__c = acc.Id;
       update acc1;
       Test.stopTest();*/
       Account account = [Select Marketing_Parent_Account__c from Account where Id = :acc1.Id];
       /* System.AssertEquals(account.Marketing_Parent_Account__c ,null);  */
    }
    static testMethod void TestContactDRTrigger() {
       ExternalSharingHelper.RunFromtestClass = true;

       Account acc = [SELECT Id, Name FROM Account WHERE Name = 'testDRAcc1' LIMIT 1];
     
       Contact cnt = [SELECT Id, Name FROM Contact WHERE AccountId = :acc.Id LIMIT 1];
       
       Test.startTest();
       Contact cnt1 = utilTestClass.CreateContact('test' , 'contact');
       cnt1.AccountId = acc.Id;
       cnt1.ReportsTo_RW__c = cnt.Id;
       insert cnt1;
       Test.stopTest();
        
       Contact contact = [Select ReportsToId from Contact where Id = :cnt1.Id];
       /* System.AssertEquals(contact.ReportsToId,null);   */
    }
    
    
    static testMethod void TestAccProductMapDRTrigger() {
      ExternalSharingHelper.RunFromtestClass = true;
     
      Account acc = [SELECT Id, Name FROM Account WHERE Name = 'testDRAcc1' LIMIT 1];

      Test.startTest();
      EB_AccountProductMap__c productMap = new EB_AccountProductMap__c(Name = 'test product map', EB_Account__c = acc.Id, EB_Account_RW__c = acc.Id, EB_Product__c ='product name');
      insert productMap ;

      EB_AccountProductMap__c  accProduct = [Select EB_Account__c from EB_AccountProductMap__c where Id = :productMap.Id];
      Test.stopTest();
        /* System.AssertEquals(accProduct.EB_Account__c, acc.Id);  */
      
     /* System.AssertEquals(
               database.countquery('SELECT COUNT()'
              +' FROM PartnerNetworkRecordConnection WHERE LocalRecordId = \'' + productMap.Id + '\''),
          1); */
    }
    
    static testMethod void TestEBEmailTemplateDRTrigger() {
      ExternalSharingHelper.RunFromtestClass = true;
        
      User cUser = new User(Id = Userinfo.getUserId());

      System.runAs (cUser) 
      {
          Test.startTest();
          EmailTemplate template = EB_InitializeObjects.createEmailTemplate('Test_Email_Template','Text');
          template.TemplateStyle= 'Freeform';
          insert template;
          
          EB_NotificationType__c templateType = new EB_NotificationType__c(Name = 'Test Type',Folder_Name__c = 'test folder');
          insert templateType ;
          
          EB_EmailTemplate__c emailTemplate = new EB_EmailTemplate__c(Name = 'Test template', EB_SFEmailTemplateId__c = template.Id,
                                                      EB_NotificationType__c = templateType.Id);
          insert emailTemplate;
          EB_EmailTemplate__c  objTemplate = [Select SFEmailTemplateName__c from EB_EmailTemplate__c where 
                          Id = :emailTemplate.Id limit 1];
          Test.stopTest();                
          /* System.AssertEquals(objTemplate.SFEmailTemplateName__c, template.DeveloperName); */
          /* System.AssertEquals(
                   database.countquery('SELECT COUNT()'
                  +' FROM PartnerNetworkRecordConnection WHERE LocalRecordId = \'' + emailTemplate.Id + '\''),
               0);  */
       }
    }
    
   static testMethod void TestEntitledProductDRTrigger() {
      ExternalSharingHelper.RunFromtestClass = true;
      Test.startTest();
      EB_Product__c product= new EB_Product__c(Product_Name__c  = 'Test product', EB_ProductId__c = 'Test1');
      insert product;
    Test.stopTest();
      /* System.AssertEquals(
               database.countquery('SELECT COUNT()'
              +' FROM PartnerNetworkRecordConnection WHERE LocalRecordId = \'' + product.Id + '\''),
           1);  */
    }
    
    static testMethod void TestTemplateTypeDRTrigger() {
      ExternalSharingHelper.RunFromtestClass = true;
      Test.startTest();
      EB_NotificationType__c templateType = new EB_NotificationType__c(Name = 'Test Type', Folder_Name__c = 'test folder');
      insert templateType ;
    Test.stopTest();
      /* System.AssertEquals(
               database.countquery('SELECT COUNT()'
              +' FROM PartnerNetworkRecordConnection WHERE LocalRecordId = \'' + templateType.Id + '\''),
           1);  */
    }
     
    static testMethod void TestEBTechSupportDRTrigger () {
      ExternalSharingHelper.RunFromtestClass = true;

      Account acc = [SELECT Id, Name FROM Account WHERE Name = 'testDRAcc1' LIMIT 1];
      User usr = [SELECT Id, Name FROM User WHERE AKAM_User_ID__c = 'TEST_USER_ID' LIMIT 1];
     
      Test.startTest();
      EB_TechSupportTeams__c techSupport = new EB_TechSupportTeams__c (EB_Account_Id__c = acc.Id,EB_Akam_User_Id__c = usr.Id, EB_Unique_Id__c = '23626bh');
      insert techSupport;
    Test.stopTest();
      /* System.AssertEquals(
      database.countquery('SELECT COUNT()'
      +' FROM PartnerNetworkRecordConnection WHERE LocalRecordId = \'' + techSupport.Id + '\''),
    1);  */
    }  

     static testMethod void TestAccountTeamDRTrigger(){
          ExternalSharingHelper.RunFromtestClass = true;
          
          Account acc = [SELECT Id, Name FROM Account WHERE Name = 'testDRAcc1' LIMIT 1];
      User usr = [SELECT Id, Name, AKAM_User_ID__c FROM User WHERE AKAM_User_ID__c = 'TEST_USER_ID' LIMIT 1];
     
          Test.startTest();
          
          System.runas(usr) {
             Environment_Setup__c environmentSetup = Environment_Setup__c.getOrgDefaults();
             environmentSetup.Active_Org__c = true;
             environmentSetup.Environment_Type__c = 'DR';
             update environmentSetup;
          }
         
          Account_Team__c member = new Account_Team__c();
          member.Account__c = acc.Id;
          member.Account_RW__c = acc.Id;
          member.User_RW__c = usr.AKAM_User_ID__c;   
          member.User__c = usr.Id;  
          member.TeamMemberRole__c = 'ADS AM';   
          insert member;  
         
          member.TeamMemberRole__c = 'ADS Sales';   
          update member;
          Test.stopTest();
     }
    
    static testMethod void TestAccountTeamDeleteDRTrigger(){
          ExternalSharingHelper.RunFromtestClass = true;
          
          Account acc = [SELECT Id, Name FROM Account WHERE Name = 'testDRAcc1' LIMIT 1];
       
          User currentUser = new User(Id = Userinfo.getUserId());
     
          Test.startTest();
          
          AccountTeamMember accteam = new AccountTeamMember();
          accteam.AccountId = acc.Id;
          accteam.UserId = currentUser.Id;   
          accteam.TeamMemberRole = 'ADS ADS';     
          insert accteam;
          
          Account_Team__c member = new Account_Team__c();
          member.Account__c = acc.Id;
          member.User_RW__c = currentUser.email;   
          member.User__c = currentUser.Id;  
          member.TeamMemberRole__c = 'ADS AM';   
          member.AccountteamId__c = accteam.Id;   
          insert member;  
         
          System.runas(currentUser) {
             Environment_Setup__c environmentSetup = Environment_Setup__c.getOrgDefaults();
             environmentSetup.Active_Org__c = true;
             environmentSetup.Environment_Type__c = 'DR';
             update environmentSetup;
          }
            
          delete member;
          Test.stopTest();
    }
     
    //Test method to test the contract trigger
    static testMethod void TestMergeContractDRTrigger() {
        ExternalSharingHelper.RunFromtestClass = true;  
        
        Account acc = [SELECT Id, Name FROM Account WHERE Name = 'testDRAcc1' LIMIT 1];
    Account acc1 = [SELECT Id, Name FROM Account WHERE Name = 'testDRAcc2' LIMIT 1];
    
        Test.startTest();
        Merge_Contract_Header__c contract=CastIronTestClass.CreateContractHeader('Test DR Contract1',acc.Id);
        contract.Parent_Account_Name_RW__c = acc1.Id;
        insert contract;
        Test.stopTest();

        Merge_Contract_Header__c cont = [Select Parent_Account_Name__c from Merge_Contract_Header__c where Id = :contract.Id];
        /* System.AssertEquals(cont.Parent_Account_Name__c ,null);  */
    }
    
    static testMethod void TestCaseDRTrigger() {
        ExternalSharingHelper.RunFromtestClass = true;
        
        User usr = [SELECT Id, Name FROM User WHERE AKAM_User_ID__c = 'TEST_USER_ID' LIMIT 1];
        
        Test.startTest();
        List<Case> caseLst = utilTestClass.createCases(1, false, usr.Id, '1');
        insert caseLst;
        Test.stopTest();

        /* System.AssertEquals(
            database.countquery('SELECT COUNT() FROM PartnerNetworkRecordConnection WHERE LocalRecordId = \'' + caseLst.get(0).Id + '\'')
            ,1
        );  */
    }
    
    static testMethod void TestGenericArticleDRTrigger() {
        ExternalSharingHelper.RunFromtestClass = true;
        KA_Generic_Article__c articleShadow = new KA_Generic_Article__c(Title__c='Title 1', Summary__c='Summary', URL_Name__c='URL-1');
        Test.startTest();
        insert articleShadow;
        
        User cUser = new User(Id = Userinfo.getUserId());
        System.runas(cUser) {
            Environment_Setup__c environmentSetup = Environment_Setup__c.getOrgDefaults();
            environmentSetup.Environment_Type__c = 'DR';
            update environmentSetup;
        }
        
        articleShadow.Summary__c = 'New Summary';
        update articleShadow;
        Test.stopTest();
    }
    
    static testMethod void TestCaseArticleDRTrigger() {
    /*
        ExternalSharingHelper.RunFromtestClass = true;
        
        Case objCase = [SELECT Id FROM Case WHERE Account.Name = 'testDRAcc1' LIMIT 1];

        User usr = [SELECT Id, Name FROM User WHERE AKAM_User_ID__c = 'TEST_USER_ID' LIMIT 1];
        
        System.runas(usr)
        {
            Test.startTest();
            List<SObject> articles = new List<SObject>();
            articles.add(new How_To__kav(Title='How To Test1', UrlName='How-To-Test1'+System.currentTimeMillis(), Summary='How To Summary1'));
            insert articles;
            
            List<How_To__kav> howTo = [Select ID, KnowledgeArticleId, UrlName, PublishStatus From How_To__kav Where ID IN : articles];
            for(How_To__kav k : howTo){
                KbManagement.PublishingService.publishArticle(k.KnowledgeArticleId, true);
            }
            
            CaseArticle caseArticle = new CaseArticle(CaseId = objCase.Id, KnowledgeArticleId = howTo[0].KnowledgeArticleId);
            insert caseArticle;
            
            Case_Article__c shadowCaseArticle = new Case_Article__c(
                Case__c = objCase.Id
                , KnowledgeArticleId__c = howTo[0].KnowledgeArticleId
                , KnowledgeArticle_URLName__c = howTo[0].UrlName
                , CaseArticleID__c = caseArticle.Id
            );
            
            insert shadowCaseArticle;
            update shadowCaseArticle;
            delete shadowCaseArticle;
            Test.stopTest();
        }*/
    }
    
    static testMethod void TestCaseTransitionDRTrigger() {
        ExternalSharingHelper.RunFromtestClass = true;
                  
        Case objCase = [SELECT Id FROM Case WHERE Account.Name = 'testDRAcc1' LIMIT 1];

        Id ProdTestId = [Select Id from EB_AccountProductMap__c where Name = 'Riverbed_Product' limit 1].Id;
        
        Test.startTest();
        objCase.Case_Product__c = ProdTestId;
        update objCase;
		Case_Transition__c caseTransition = new Case_Transition__c(Case__c = objCase.Id);
        insert caseTransition;
        Test.stopTest();
        /* System.AssertEquals(
            database.countquery('SELECT COUNT() FROM PartnerNetworkRecordConnection WHERE LocalRecordId = \'' + caseTransition.Id + '\'')
            ,0
        );  */
    }
    
    static testMethod void TestCaseUpdateHistoryDRTrigger() {
        ExternalSharingHelper.RunFromtestClass = true;
                
        Case objCase = [SELECT Id FROM Case WHERE Account.Name = 'testDRAcc1' LIMIT 1];
    
        Test.startTest();
        Case_Update_History__c caseHistory = new Case_Update_History__c(Case__c = objCase.Id, Case_Update_Time__c = Datetime.now());
        insert caseHistory;
        Test.stopTest();
        /* System.AssertEquals(
            database.countquery('SELECT COUNT() FROM PartnerNetworkRecordConnection WHERE LocalRecordId = \'' + caseHistory.Id + '\'')
            ,0
        );  */
    }
    
    static testMethod void TestExternalDependencyDRTrigger() {
        ExternalSharingHelper.RunFromtestClass = true;
        
        Case objCase = [SELECT Id FROM Case WHERE Account.Name = 'testDRAcc1' LIMIT 1];
    
        Test.startTest();
        External_Dependency__c dependency = new External_Dependency__c(Case__c = objCase.Id);
        insert dependency;
        Test.stopTest();
        
        /* System.AssertEquals(
            database.countquery('SELECT COUNT() FROM PartnerNetworkRecordConnection WHERE LocalRecordId = \'' + dependency.Id + '\'')
            ,0
        );  */
    } 
    
    static testMethod void TestEngagementRequestDRTrigger() {
        ExternalSharingHelper.RunFromtestClass = true;
        
        Case objCase = [SELECT Id FROM Case WHERE Account.Name = 'testDRAcc1' LIMIT 1];

        User usr = [SELECT Id, Name FROM User WHERE AKAM_User_ID__c = 'TEST_USER_ID' LIMIT 1];

        Test.startTest();
        Engagement_Request__c request = new Engagement_Request__c(Case__c = objCase.Id, Assigned_To__c = usr.Id);
        insert request;
        Test.stopTest();
        
        /* System.AssertEquals(
            database.countquery('SELECT COUNT() FROM PartnerNetworkRecordConnection WHERE LocalRecordId = \'' + request.Id + '\'')
            ,0
        );  */
    }   
    
    static testMethod void TestHolidayDRTrigger() {
        ExternalSharingHelper.RunFromtestClass = true;
        
        Test.startTest();
        Holiday__c holiday = new Holiday__c(Date__c = Date.today(), Region__c = 'test_region');
        insert holiday;
        Test.stopTest();
        /* System.AssertEquals(
            database.countquery('SELECT COUNT() FROM PartnerNetworkRecordConnection WHERE LocalRecordId = \'' + holiday.Id + '\'')
            ,1
        );  */
    }   
    
    static testMethod void TestShiftAndDivisonObjectDRTrigger() {
        ExternalSharingHelper.RunFromtestClass = true;
        User usr = [SELECT Id, Name FROM User WHERE AKAM_User_ID__c = 'TEST_USER_ID' LIMIT 1];

        Test.startTest();
        Division__c division = new Division__c(Name = 'Test_Division_Trigger', Description__c = 'Test_Division_Trigger');
        insert division;
        
        /* System.AssertEquals(
            database.countquery('SELECT COUNT() FROM PartnerNetworkRecordConnection WHERE LocalRecordId = \'' + division.Id + '\'')
            ,1
        );  */
        Division_Role__c role = new Division_Role__c(Name = 'Test_Division_Role_Trigger', Description__c = 'Test_Division_Role_Trigger', Division__c = division.Id);
        insert role;
        /* System.AssertEquals(
            database.countquery('SELECT COUNT() FROM PartnerNetworkRecordConnection WHERE LocalRecordId = \'' + role.Id + '\'')
            ,0
        );  */
        Shift_Membership__c member = new Shift_Membership__c(Division__c = division.Id, User_RW__c = 'TEST_USER_ID',User__c = usr.Id);
        insert member; 
        /* System.AssertEquals(
            database.countquery('SELECT COUNT() FROM PartnerNetworkRecordConnection WHERE LocalRecordId = \'' + member.Id + '\'')
            ,1
        );   */
        
        Shift__c shift = new Shift__c(Name = 'Test_Shift_trigger', Start_Time__c = '1:00', End_Time__c = '10:00');
        insert shift;
        /* System.AssertEquals(
            database.countquery('SELECT COUNT() FROM PartnerNetworkRecordConnection WHERE LocalRecordId = \'' + shift.Id + '\'')
            ,1
        ); */
        
        Shift_Role_Assignment__c shiftRole= new Shift_Role_Assignment__c(Date__c = date.today(), Assigned_User__c = usr.Id, Team_Role__c = role.Id, Shift__c = shift.Id, Team_Role_RW__c = role.Id);
        insert shiftRole;
        /* System.AssertEquals(
            database.countquery('SELECT COUNT() FROM PartnerNetworkRecordConnection WHERE LocalRecordId = \'' + shiftRole.Id + '\'')
            ,0
        );   */  
        
        Shift_User_Junction__c junction= new Shift_User_Junction__c(Shift__c = shift.Id, User__c = usr.Id);
        insert junction;
        Test.stopTest();
        /* System.AssertEquals(
            database.countquery('SELECT COUNT() FROM PartnerNetworkRecordConnection WHERE LocalRecordId = \'' + junction.Id + '\'')
            ,0
        );   */
    }  
    
    static testMethod void TestSpecialInstructionsDRTrigger() {
        ExternalSharingHelper.RunFromtestClass = true;
        
        Account acc = [SELECT Id, Name FROM Account WHERE Name = 'testDRAcc1' LIMIT 1];
    
        Test.startTest();
        Special_Instructions__c instructions= new Special_Instructions__c(Account__c = acc.Id, Instructions__c = 'TEST_INSTRUCTION_TRIGGER');
        insert instructions;
        Test.stopTest();
       
        /* System.AssertEquals(
            database.countquery('SELECT COUNT() FROM PartnerNetworkRecordConnection WHERE LocalRecordId = \'' + instructions.Id + '\'')
            ,0
        );   */
    }  
    
    static testMethod void TestStatusReportDRTrigger() {
        ExternalSharingHelper.RunFromtestClass = true;
        
        Case objCase = [SELECT Id FROM Case WHERE Account.Name = 'testDRAcc1' LIMIT 1];
    
        Test.startTest();
        Status_Report__c report= new Status_Report__c(Case__c = objCase.Id);
        insert report;
        Test.stopTest();
       
        /* System.AssertEquals(
            database.countquery('SELECT COUNT() FROM PartnerNetworkRecordConnection WHERE LocalRecordId = \'' + report.Id + '\'')
            ,0
        );   */
    }  
    
    static testMethod void TestProductAndCategoryDRTrigger() {
        ExternalSharingHelper.RunFromtestClass = true;      
        
        Test.startTest();
        Product_Category__c parentCategory = new Product_Category__c(Name = 'PARENT_CATEGORY');
        insert parentCategory;
        
        Product_Category__c category = new Product_Category__c(Name = 'PRODUCT_CATEGORY_TEST',Parent_Product_Category_RW__c = parentCategory.Id, Parent_Product_Category__c = parentCategory.Id);
        insert category;
       
        /* System.AssertEquals(
            database.countquery('SELECT COUNT() FROM PartnerNetworkRecordConnection WHERE LocalRecordId = \'' + category.Id + '\'')
            ,1
        );   */
        
        Product__c product = new Product__c(Name = 'TEST_PRODUCT_TRIGGER', Product_Category__c = category.Id);
        insert product;
        
        product.Name = 'TEST_PRODUCT_TRIGGER_UPDATE';
        update product;
        
        Test.stopTest();
        /* System.AssertEquals(
            database.countquery('SELECT COUNT() FROM PartnerNetworkRecordConnection WHERE LocalRecordId = \'' + product.Id + '\'')
            ,0
        );   */
    }  
    
    /*static testMethod void TestTaskDRTrigger() {
        ExternalSharingHelper.RunFromtestClass = true;
        
        Account acc = [SELECT Id, Name FROM Account WHERE Name = 'testDRAcc1' LIMIT 1];

        User usr = [SELECT Id, Name FROM User WHERE AKAM_User_ID__c = 'TEST_USER_ID' LIMIT 1];
    
        Contact cnt1 = [SELECT Id, Name FROM Contact WHERE AccountId = :acc.Id LIMIT 1];
    
        Test.startTest();
        Task tsk =  utilTestClass.CreateTask(usr.Id, 'Call', 'Completed', 'Meeting', acc.Id);
        tsk.Record_Type_RW__c = 'Standard Activity';
        tsk.WhoId = cnt1.Id;
        tsk.Who_RW__c = cnt1.Id;
        insert tsk; 
        Test.stopTest();
        /* System.AssertEquals(
            database.countquery('SELECT COUNT() FROM PartnerNetworkRecordConnection WHERE LocalRecordId = \'' + tsk.Id + '\'')
            ,0
        );  
    }   */
    
    static testMethod void TestAttachmentDRTrigger() {
        ExternalSharingHelper.RunFromtestClass = true;
        
        Case objCase = [SELECT Id FROM Case WHERE Account.Name = 'testDRAcc1' LIMIT 1];
    
        Test.startTest();
        Attachment attach= new Attachment(Name ='Test_Attachment_trigger', ParentId = objCase.Id, Body = Blob.valueOf('Test Attachment'));
        insert attach;
        update attach;
        Test.stopTest();
        /* System.AssertEquals(
            database.countquery('SELECT COUNT() FROM PartnerNetworkRecordConnection WHERE LocalRecordId = \'' + attach.Id + '\'')
            ,0
        );   */
    }  
    
   static testMethod void TestCaseNotificationSubscriptionDRTrigger() {
        ExternalSharingHelper.RunFromtestClass = true;
        
        Account acc = [SELECT Id, Name FROM Account WHERE Name = 'testDRAcc1' LIMIT 1];

        User usr = [SELECT Id, Name FROM User WHERE AKAM_User_ID__c = 'TEST_USER_ID' LIMIT 1];
    
        Test.startTest();
        Case_Notification_Subscription__c NS =  new Case_Notification_Subscription__c (Account__C=acc.Id, User__c=usr.Id, Severity__c='3 & below');
        insert NS;
        Test.stopTest();
        
        /* System.AssertEquals(
            database.countquery('SELECT COUNT() FROM PartnerNetworkRecordConnection WHERE LocalRecordId = \'' + NS.Id + '\'')
            ,1
        ); */
    }
    
    static testMethod void TestDRDowntime() {
        ExternalSharingHelper.RunFromtestClass = true;
        
        User cUser = new User(Id = Userinfo.getUserId());
    System.runas(cUser) {
            Environment_Setup__c environmentSetup = Environment_Setup__c.getOrgDefaults();
            environmentSetup.Active_Org__c = true;
            environmentSetup.Environment_Type__c = 'DR';
            update environmentSetup;
        }
        
        Test.startTest();
        Account ObjAcc = utilTestClass.CreateAccount('test account');
        insert ObjAcc;
       
        Case case1 = utilTestClass.createCase(ObjAcc.Id);
             
        Partner_Connection__c  partner =  [Select Id from Partner_Connection__c  where LocalRecordId__c = :case1.Id];
        
        /* System.AssertEquals(
            database.countquery('SELECT COUNT() FROM Partner_Connection__c  WHERE Operation__c = \'Insert\' AND LocalRecordId__c = \'' + objCase.Id + '\'')
            ,1
        ); */
        
        Case_Update_History__c caseHistory = new Case_Update_History__c(Case__c = case1.Id, Case_Update_Time__c = Datetime.now());
        insert caseHistory;
        
        /* System.AssertEquals(
            database.countquery('SELECT COUNT() FROM Partner_Connection__c  WHERE Operation__c = \'Insert\' AND LocalRecordId__c = \'' + caseHistory.Id + '\'')
            ,0
        ); */
        
        caseHistory.Case_Update_Time__c = Datetime.now(); 
        update caseHistory;
        Test.stopTest();
        /* System.AssertEquals(
            database.countquery('SELECT COUNT() FROM Partner_Connection__c  WHERE Operation__c = \'Update\' AND LocalRecordId__c = \'' + caseHistory.Id + '\'')
            ,1
        );      */
    }
    
    static testMethod void TestEmailMessageDRTrigger() {
        ExternalSharingHelper.RunFromtestClass = true;
       
        Case objCase = [SELECT Id FROM Case WHERE Account.Name = 'testDRAcc1' LIMIT 1];

        Test.startTest();
        EmailMessage msg = new EmailMessage(ParentId = objCase.Id, TextBody = 'Test Email Message', Subject = 'Test Subject', ToAddress = 'ssawhney@akamai.com', Incoming = True, FromAddress = 'ssawhney@akamai.com');
        insert msg;
        Test.stopTest(); 
        /* System.AssertEquals(
            database.countquery('SELECT COUNT() FROM Email_Message_Shadow__c WHERE LocalRecordId__c = \'' + msg.Id + '\'')
            ,1
        ); */
        
        Id shadowId = [Select Id from Email_Message_Shadow__c  where LocalRecordId__c = :msg.Id].Id;
        
        /* System.AssertEquals(
            database.countquery('SELECT COUNT() FROM PartnerNetworkRecordConnection WHERE LocalRecordId = \'' + msg.Id + '\'')
            ,0
        );      */
    }  
    
    static testMethod void TestIssueDRTrigger() {
        ExternalSharingHelper.RunFromtestClass = true;
        Case objCase = [SELECT Id FROM Case WHERE Account.Name = 'testDRAcc1' LIMIT 1];

        Test.startTest();
        SC_Issues__c issue = utilTestClass.createIssue('123', '456', objCase.Id);
        insert issue;
        Test.stopTest();
         
        /* System.AssertEquals(
            database.countquery('SELECT COUNT() FROM PartnerNetworkRecordConnection WHERE LocalRecordId = \'' + issue.Id + '\'')
            ,1
        );  */
    }
    
    static testMethod void TestBOCCServiceEntitlementDRTrigger(){
        ExternalSharingHelper.RunFromtestClass = true;  
        Account acc = [SELECT Id, Name FROM Account WHERE Name = 'testDRAcc1' LIMIT 1];
        Test.startTest();
          Merge_Contract_Header__c contract=CastIronTestClass.CreateContractHeader('Test DR Contract1',acc.Id);
          insert contract;
        
          SC_BOCC_Contract_Eng_Mrktng_Product_Dtl__c  boccServiceEntitlement = new SC_BOCC_Contract_Eng_Mrktng_Product_Dtl__c ();
      boccServiceEntitlement.Account__c  = acc.Id;
      boccServiceEntitlement.Original_Contract_Id__c = contract.Id;
          boccServiceEntitlement.Unique_Key__c = 'Test@test123';
          insert boccServiceEntitlement;
          
          //for Update Call
          boccServiceEntitlement.Unique_Key__c = 'Test@test1234';
          Update boccServiceEntitlement;
        
        Test.stopTest();    
  }
}