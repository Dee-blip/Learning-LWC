/*
 * Author   : Vamsee Surya S
 * Date     : 12th Apr 2017
 * Purpose  : This is the Test class for CMC Application 
 */


@isTest(seeAllData = False)
public class CMC_TestClass {
    
    Static List<Account> accountObjectList;
    Static List<Contact> contactObjectList;
    Static List<EB_AkaMailer__c> mailerObjectList;
    Static List<Policy_Domain__c> pdObjectList;
    Static List<Authorized_Contact__c> acObjectList;
    Static List<Mailer_Acc_Policy_Domain_Association__c> mailerPDAssociationObjectList;
    Static List<CMC_Mailer_Filter__c> mailerFilerObjectList;
    
    @testSetup static void createTestData() {
        
        //Create custom settings for Account creation
        utilTestClass.createCustomSettings();
        CMC_Settings__mdt cmcSettingsRecord = [SELECT CMC_Exclude_Akamai_Email_Id__c,CMC_Default_Account_Id__c,CMC_Default_Contact_Id__c, CMC_Default_Policy_Domain_Id__c FROM CMC_Settings__mdt WHERE DeveloperName = 'CMC'];
        
        //Custom setting for CMC
        CMC_Report_Ids__c cmcReports = new CMC_Report_Ids__c();
      cmcReports.Pre_Mailer_Exception_Report__c = 'Test';
      Insert cmcReports;
        
     // Custom setting for SC_SupportEmail__c
     SC_SupportEmail__c autogenCs = new SC_SupportEmail__c(Support_Email_AutoGen__c='scdev@akamai.com',Name='1');
     Insert autogenCs;
        
        //Account Creation
        accountObjectList = new List<Account>();
        Account accountRecord1 = new Account(Name='Test Account1',AKAM_Account_ID__c=cmcSettingsRecord.CMC_Default_Account_Id__c,Indirect_Customer__c=True, Direct_Customer__c=True,IsPartnerCustom__c=True);
        accountObjectList.add(accountRecord1);
        Account accountRecord2 = new Account(Name='Test Account2',AKAM_Account_ID__c='Test_111',Indirect_Customer__c=True, Direct_Customer__c=True,IsPartnerCustom__c=True);
        accountObjectList.add(accountRecord2);
        Account accountRecord3 = new Account(Name='Test Account3',AKAM_Account_ID__c='Test_222',Indirect_Customer__c=True, Direct_Customer__c=True,IsPartnerCustom__c=True);
        accountObjectList.add(accountRecord3);
        Account accountRecord4 = new Account(Name='Test Account4',AKAM_Account_ID__c='Test_333',Indirect_Customer__c=True, Direct_Customer__c=True,IsPartnerCustom__c=True);
        accountObjectList.add(accountRecord4);
        insert accountObjectList;

        
        //Contact Creation
        contactObjectList = new List<Contact>();
        contact contactRecord1 = new Contact(AccountId = accountObjectList[0].Id, Login__c = 'Test_xyz',Akam_Contact_id__c =cmcSettingsRecord.CMC_Default_Contact_Id__c, Email = Userinfo.getUserEmail() ,No_Longer_with_Company__c = false, LastName = 'Test Contact', Contact_Type__c ='Technical Primary - 24x7',Primary_Contact_Method__c ='Mobile');
        contactObjectList.add(contactRecord1);
        contact contactRecord2 = new Contact(AccountId = accountObjectList[1].Id, Login__c = 'Test_xyz1',Akam_Contact_id__c ='test-111', Email = 'test111@test.com' ,No_Longer_with_Company__c = false, LastName = 'Test Contact1', Contact_Type__c ='Technical Primary - 24x7',Primary_Contact_Method__c ='Mobile');
        contactObjectList.add(contactRecord2);
        contact contactRecord3 = new Contact(AccountId = accountObjectList[2].Id, Login__c = 'Test_xyz2',Akam_Contact_id__c ='test-222', Email = 'test222@test.com' ,No_Longer_with_Company__c = false, LastName = 'Test Contact2', Contact_Type__c ='Technical Primary - 24x7',Primary_Contact_Method__c ='Mobile');
        contactObjectList.add(contactRecord3);
        insert contactObjectList;

        
        //Template Name 
        List<EmailTemplate> templates = [select Id, Name from EmailTemplate where folder.developername In ('CMC_INT_Single_Email_Templates') AND IsActive = True LIMIT 1];
        
        //24x7 Contacts Mailer Creation
        mailerObjectList = new List<EB_AkaMailer__c>();
        EB_AkaMailer__c mailer1 = new EB_AkaMailer__c(CMC_24x7_Contact_Types__c  = True,CMC_All_Customers__c = True, EB_Status__c = 'Draft', CMC_Selected_Customers__c  = False);
        mailer1.RecordTypeId = Schema.SObjectType.EB_AkaMailer__c.getRecordTypeInfosByName().get('CMC').getRecordTypeId();
        mailer1.CMC_Subject__c = 'Test';
        mailer1.EB_AdditionalIssueDescription__c = 'Test';
        if(templates.size() == 1){
            mailer1.EB_Type__c  ='Single Email';
            mailer1.CMC_Template_ID__c = templates[0].Id;
            mailer1.CMC_Template_Name__c = templates[0].Name;
         }
        else
            mailer1.EB_Type__c  ='Mass Email';
            
        insert mailer1;
        
        //mailer Account
        EB_AkaMAccount__c mailerAccount1 = new EB_AkaMAccount__c();
        mailerAccount1.RecordTypeId = Schema.SObjectType.EB_AkaMAccount__c.getRecordTypeInfosByName().get('CMC').getRecordTypeId();
        mailerAccount1.EB_Account__c = accountObjectList[0].Id;
        mailerAccount1.EB_AkaMailer__c = mailer1.Id;
        insert mailerAccount1; 
        
        EB_AkaMAccount__c mailerAccount2 = new EB_AkaMAccount__c();
        mailerAccount2.RecordTypeId = Schema.SObjectType.EB_AkaMAccount__c.getRecordTypeInfosByName().get('CMC').getRecordTypeId();
        mailerAccount2.EB_Account__c = accountObjectList[1].Id;
        mailerAccount2.EB_AkaMailer__c = mailer1.Id;
        insert mailerAccount2; 
        
        mailerObjectList.add(mailer1);
        
        //Manual Entered emails Mailer Creation
        EB_AkaMailer__c mailer2 = new EB_AkaMailer__c(CMC_24x7_Contact_Types__c  = False,CMC_All_Customers__c = False, EB_Status__c = 'Draft', CMC_Selected_Customers__c  = False, CMC_Manual_Email_Addresses__c = 'test@test.com, test1@test,com');
        mailer2.RecordTypeId = Schema.SObjectType.EB_AkaMailer__c.getRecordTypeInfosByName().get('CMC').getRecordTypeId();
        mailer2.CMC_Subject__c = 'Test';
        mailer2.EB_AdditionalIssueDescription__c = 'Test';
        mailer1.EB_Type__c  ='Mass Email';
            
        insert mailer2;
        
        //mailer Account
        EB_AkaMAccount__c mailerAccount3 = new EB_AkaMAccount__c();
        mailerAccount3.RecordTypeId = Schema.SObjectType.EB_AkaMAccount__c.getRecordTypeInfosByName().get('CMC').getRecordTypeId();
        mailerAccount3.EB_Account__c = accountObjectList[0].Id;
        mailerAccount3.EB_AkaMailer__c = mailer1.Id;
        insert mailerAccount3; 
        
        mailerObjectList.add(mailer2);
        
        //Authorized Contact Mailer Creation
        mailerObjectList = new List<EB_AkaMailer__c>();
        EB_AkaMailer__c mailer3 = new EB_AkaMailer__c(AuthCon_Authorized_Contacts__c = True,CMC_All_Customers__c = True, EB_Status__c = 'Draft', CMC_Selected_Customers__c  = False, AuthCon_Emergency_Notification_Recipient__c = True);
        mailer3.RecordTypeId = Schema.SObjectType.EB_AkaMailer__c.getRecordTypeInfosByName().get('CMC').getRecordTypeId();
        mailer3.CMC_Subject__c = 'Test';
        mailer3.EB_AdditionalIssueDescription__c = 'Test';
        if(templates.size() == 1){
            mailer3.EB_Type__c  ='Single Email';
            mailer3.CMC_Template_ID__c = templates[0].Id;
            mailer3.CMC_Template_Name__c = templates[0].Name;
         }
        else
            mailer3.EB_Type__c  ='Mass Email';
            
        insert mailer3;
        
        //mailer account
        EB_AkaMAccount__c mailerAccount4 = new EB_AkaMAccount__c();
        mailerAccount4.RecordTypeId = Schema.SObjectType.EB_AkaMAccount__c.getRecordTypeInfosByName().get('CMC').getRecordTypeId();
        mailerAccount4.EB_Account__c = accountObjectList[0].Id;
        mailerAccount4.EB_AkaMailer__c = mailer3.Id;
        insert mailerAccount4; 
        
        EB_AkaMAccount__c mailerAccount5 = new EB_AkaMAccount__c();
        mailerAccount5.RecordTypeId = Schema.SObjectType.EB_AkaMAccount__c.getRecordTypeInfosByName().get('CMC').getRecordTypeId();
        mailerAccount5.EB_Account__c = accountObjectList[1].Id;
        mailerAccount5.EB_AkaMailer__c = mailer3.Id;
        insert mailerAccount5; 
        
        //Policy Domain creation
        pdObjectList = new List<Policy_Domain__c>();
        Policy_Domain__c pd1 = new Policy_Domain__c(Name = 'testpd', Account_Name__c = accountObjectList[0].Id, AKAM_Policy_Domain_ID__c = 'Test-Pd-111', Policy_Domain_Description__c = 'Test-Pd-111', Policy_Domain_State__c = 'Active', Product__c = 'testproduct', Additional_Product__c = 'test add prod', Service_Account__c = accountObjectList[1].Id);
        pdObjectList.add(pd1);
        Integer i =0;
        for(String eachAkamPdId : cmcSettingsRecord.CMC_Default_Policy_Domain_Id__c.split(',')){
            Policy_Domain__c pd2 = new Policy_Domain__c(Name = 'DefaultTestpd' + i, Account_Name__c = accountObjectList[2].Id, AKAM_Policy_Domain_ID__c = eachAkamPdId, Policy_Domain_Description__c = 'default Test-Pd-123', Policy_Domain_State__c = 'Active', Product__c = 'defaulttestproduct', Additional_Product__c = 'test add prod', Service_Account__c = accountObjectList[3].Id);
            pdObjectList.add(pd2);
            i = i+1;
        }
        Policy_Domain__c pd3 = new Policy_Domain__c(Name = 'testpd2', Account_Name__c = accountObjectList[0].Id, AKAM_Policy_Domain_ID__c = 'Test-Pd-222', Policy_Domain_Description__c = 'Test-Pd-222', Policy_Domain_State__c = 'Active', Product__c = 'testproduct', Additional_Product__c = 'test add prod', Service_Account__c = accountObjectList[1].Id);
        pdObjectList.add(pd3);
        insert pdObjectList;
        
        //Authorized Contacts created
        acObjectList = new List<Authorized_Contact__c >();
        Authorized_Contact__c  ac1 = new Authorized_Contact__c (Contact_Name__c = contactObjectList[0].Id, Emergency_Email__c = true, Policy_Domain__c = pdObjectList[0].Id, Product_Interests__c = 'All');
        acObjectList.add(ac1);
        Authorized_Contact__c  ac2 = new Authorized_Contact__c (Contact_Name__c = contactObjectList[1].Id, Emergency_Email__c = true, Policy_Domain__c = pdObjectList[1].Id, Product_Interests__c = 'All', Service__c = true);
        acObjectList.add(ac2);
        Authorized_Contact__c  ac3 = new Authorized_Contact__c (Contact_Name__c = contactObjectList[2].Id, Emergency_Email__c = true, Policy_Domain__c = pdObjectList[2].Id, Product_Interests__c = 'All', Service__c = false);
        acObjectList.add(ac3);
        //Authorized_Contact__c  ac4 = new Authorized_Contact__c (Contact_Name__c = contactObjectList[3].Id, Emergency_Email__c = true, Policy_Domain__c = pdObjectList[3].Id, Product_Interests__c = 'All', Service__c = true);
        //acObjectList.add(ac4);
        insert acObjectList;
        
        //creating Mailer_Acc_Policy_Domain_Association__c
        mailerPDAssociationObjectList = new List<Mailer_Acc_Policy_Domain_Association__c>();
        Mailer_Acc_Policy_Domain_Association__c mailerPDAssociation1 = new Mailer_Acc_Policy_Domain_Association__c(Mailer_Account__c = mailerAccount4.Id, Policy_Domain__c = pd1.Id, Mailer__c = mailer3.Id);
        insert mailerPDAssociation1;
        mailerPDAssociationObjectList.add(mailerPDAssociation1);
        Mailer_Acc_Policy_Domain_Association__c mailerPDAssociation2 = new Mailer_Acc_Policy_Domain_Association__c(Mailer_Account__c = mailerAccount5.Id, Policy_Domain__c = pd1.Id, Mailer__c = mailer3.Id);
        insert mailerPDAssociation2;
        mailerPDAssociationObjectList.add(mailerPDAssociation2);
        
        //mailer filter creation for Authorized contacts
        mailerFilerObjectList = new List<CMC_Mailer_Filter__c>();
        CMC_Mailer_Filter__c mailerFilter1 = new CMC_Mailer_Filter__c(CMC_Filter_Mailer__c = mailer3.Id, CMC_Filter_Condition__c = 'Equal To', CMC_Filter_Field__c  = 'Policy Domain Name', CMC_Filter_Order__c = 1, CMC_Filter_Value__c = 'testpd');
        insert mailerFilter1;
        mailerFilerObjectList.add(mailerFilter1);
        CMC_Mailer_Filter__c mailerFilter2 = new CMC_Mailer_Filter__c(CMC_Filter_Mailer__c = mailer3.Id, CMC_Filter_Condition__c = 'In', CMC_Filter_Field__c  = 'Marketing Product Name', CMC_Filter_Order__c = 2, CMC_Filter_Value__c = 'testproduct');
        insert mailerFilter2;
        mailerFilerObjectList.add(mailerFilter2);
        
        mailerObjectList.add(mailer3);
        
            
        
        
        
    }
    
    static testmethod void createMailer_test(){

        test.startTest();
            PageReference pageRef1 = Page.CMC_IncidentNotificationTool;
            Test.setCurrentPage(pageRef1);
            ApexPages.Standardcontroller sc1 = new ApexPages.Standardcontroller(new EB_AkaMailer__c());
            CMC_IncidentNotificationToolController mailerclass = new CMC_IncidentNotificationToolController(sc1);
            mailerclass.mailerFormInput = '{"Filters":[{"Id":"","CMC_Filter_Order__c":1,"CMC_Filter_Field__c":"Account ID","CMC_Filter_Condition__c":"Equal To","CMC_Filter_Value__c":"test"},'+
            '{"Id":"","CMC_Filter_Order__c":2,"CMC_Filter_Field__c":"Customer Name","CMC_Filter_Condition__c":"Not Equal To","CMC_Filter_Value__c":"test"},'+
            '{"Id":"","CMC_Filter_Order__c":3,"CMC_Filter_Field__c":"Geography","CMC_Filter_Condition__c":"Contains","CMC_Filter_Value__c":"test"},' +
            '{"Id":"","CMC_Filter_Order__c":4,"CMC_Filter_Field__c":"Tier","CMC_Filter_Condition__c":"Does Not Contain","CMC_Filter_Value__c":"test"},'+
            '{"Id":"","CMC_Filter_Order__c":5,"CMC_Filter_Field__c":"Marketing Product Name","CMC_Filter_Condition__c":"In","CMC_Filter_Value__c":"test"}],'+
             '"FilterLogic":"","AccountInfo":{"ContactType":"24x7 Contact Types","AccountType":["Partner","Direct Customer"],"CustomerSelection":" Selected Customers"}}';
            List<SelectOption> templateList = mailerclass.getTemplateNames();
            mailerclass.getTypes();
            mailerclass.getConditions();
            mailerclass.templateName = [select Name from EmailTemplate where folder.developername In ('CMC_INT_Single_Email_Templates','CMC_INT_Mass_Email_Templates') AND IsActive = True LIMIT 1].Name;
            mailerclass.createMailerData();
            mailerclass.queryBuildForAttachment();
            
            //Download as CSV CTRL
            PageReference downloadCSVpage = Page.CMC_DownloadAsCSV;
            Test.setCurrentPage(downloadCSVpage);
            ApexPages.currentPage().getParameters().put('mailerId',mailerclass.mailerObject.Id);
            ApexPages.currentPage().getParameters().put('download','AccountDetails');
            CMC_DownloadAsCSVCtrl downloadCSVCtrl = new CMC_DownloadAsCSVCtrl();
            
            
            mailerclass.reloadPage();
            mailerclass.mailerFormInput = '{"Filters":"","FilterLogic":"","AccountInfo":{"ContactType":"24x7 Contact Types","AccountType":["Partner","Direct Customer","Indirect Customer"],"CustomerSelection":" All Customers"}}';
            mailerclass.createMailerData();
            mailerclass.queryBuildForAttachment();
            mailerclass.sendTestEmail();
            mailerclass.updatedFilterJSON = 'Test';
            mailerclass.mailerIdForUpdate = mailerclass.mailerObject.Id;
            mailerclass.updateFilterJSONWithId();
            mailerclass.SINumber = 'Test';
            mailerclass.ValidateSINumber();
            mailerclass.mailerObject.CMC_Approval_Status__c = 'Approved';
            mailerclass.createMailerData();
            mailerclass.queryBuildForAttachment();
            CMC_IncidentNotificationToolController.processChunk(True, mailerclass.mailerObject.Id, 'Test','Test','Test');
            mailerclass.emailProcessCount();
            system.debug([Select Id, Body, ContentType from ATTACHMENT where parentId =:mailerclass.mailerObject.Id AND Name = 'QueryString.txt' Limit 1]);
            
            //Email Preview CTRL
            PageReference emailPreviewpage = Page.CMC_EmailPreview;
            Test.setCurrentPage(emailPreviewpage);
            ApexPages.currentPage().getParameters().put('mailerId',mailerclass.mailerObject.Id);
            CMC_EmailPreviewCtrl emailPreviewCtrl = new CMC_EmailPreviewCtrl();
            emailPreviewCtrl.FetchEmailBody();
            
            //Trigger call
            Delete mailerclass.mailerObject;
            CMC_MailerHelper.QueryStringAttachment('queryString',mailerclass.mailerObject.id);
            CMC_MailerHelper.splitString(null); 

        Test.stopTest();
            
    }
    
    static testmethod void staticmethods_test(){
        CMC_IncidentNotificationToolController.getAttachment('Test');
        CMC_IncidentNotificationToolController.getFilterMailer('Test');
        CMC_IncidentNotificationToolController.getMailer('Test');
        CMC_MailerHelper.splitString('"Test,test",test');
        CMC_MailerHelper.SplitStringForAttachment('Test,test,test,test');

    }
    
    
    static testmethod void createMailer_test2(){
        Test.startTest();
            PageReference pageRef1 = Page.CMC_IncidentNotificationTool;
            Test.setCurrentPage(pageRef1);
            ApexPages.Standardcontroller sc1 = new ApexPages.Standardcontroller(new EB_AkaMailer__c());
            CMC_IncidentNotificationToolController mailerclass = new CMC_IncidentNotificationToolController(sc1);
            mailerclass.mailerFormInput = '{"forDelete":"true","Filters":"","FilterLogic":"","AccountInfo":{"ContactType":"Manual Email Addresses","AccountType":[],"CustomerSelection":"","EmailTextArea":"vs-qa@akamai.com,asdfghjk"}}';
            mailerclass.createMailerData();
            mailerclass.queryBuildForAttachment();
            mailerclass.reloadPage();
            mailerclass.mailerObject.CMC_Subject__c = 'Test';
            mailerclass.mailerObject.EB_AdditionalIssueDescription__c = 'Test';
            mailerclass.sendTestEmail();
            mailerclass.mailerObject.CMC_Approval_Status__c = 'Approved';
            mailerclass.createMailerData();
            mailerclass.queryBuildForAttachment();
            
            //Download CSV CTRL
            PageReference downloadCSVpage = Page.CMC_DownloadAsCSV;
            Test.setCurrentPage(downloadCSVpage);
            ApexPages.currentPage().getParameters().put('mailerId',mailerclass.mailerObject.Id);
            ApexPages.currentPage().getParameters().put('download','ValidEmails');
            CMC_DownloadAsCSVCtrl downloadCSVCtrl = new CMC_DownloadAsCSVCtrl();
            downloadCSVCtrl.headers = 'Test';
            PageReference downloadCSVpage2 = Page.CMC_DownloadAsCSV;
            Test.setCurrentPage(downloadCSVpage2);
            ApexPages.currentPage().getParameters().put('mailerId',mailerclass.mailerObject.Id);
            ApexPages.currentPage().getParameters().put('download','InvalidEmails');
            CMC_DownloadAsCSVCtrl downloadCSVCtrl2 = new CMC_DownloadAsCSVCtrl();
            PageReference pageRef2 = Page.CMC_IncidentNotificationTool;
            Test.setCurrentPage(pageRef2);
            
            ApexPages.Standardcontroller sc2 = new ApexPages.Standardcontroller(new EB_AkaMailer__c());
            ApexPages.currentPage().getParameters().put('Id',mailerclass.mailerObject.Id);
            CMC_IncidentNotificationToolController mailerclass2 = new CMC_IncidentNotificationToolController(sc2);
            
            //Email Preview CTRL
            PageReference emailPreviewpage = Page.CMC_EmailPreview;
            Test.setCurrentPage(emailPreviewpage);
            ApexPages.currentPage().getParameters().put('mailerId',mailerclass.mailerObject.Id);
            CMC_EmailPreviewCtrl emailPreviewCtrl = new CMC_EmailPreviewCtrl();
            emailPreviewCtrl.FetchEmailBody();
            emailPreviewCtrl.PostMailer();
        Test.stopTest();
        
    }
    
    // For Manual Entered Email Address
     static testmethod void createMailer_test3(){
        EB_AkaMailer__c mailer = [select Id, CMC_24x7_Contact_Types__c,CMC_Manual_Email_Addresses__c,CMC_Template_ID__c,
                            CMC_Subject__c,EB_AdditionalIssueDescription__c 
                            from EB_AkaMailer__c where CMC_24x7_Contact_Types__c = false limit 1];
         Test.startTest();
            
            CMC_postMailerActivityBatchJob  postMailerJob = new CMC_postMailerActivityBatchJob(null, true, mailer.Id);
            postMailerJob.postMailerActivity(mailer.Id); 
            
            List<Contact> FilterContacts = [select Id,Email,IsEmailBounced,AccountId,AKAM_Contact_ID__c,Name,Account.AKAM_Account_ID__c from Contact where Email != null];
            CMC_postMailerActivityBatchJob  postMailerJob1 = new CMC_postMailerActivityBatchJob();  
            postMailerJob1.sendEmailToContacts(FilterContacts,mailer);
            postMailerJob1.processBouncedContacts(FilterContacts,'..Exception',mailer.Id,true);
         
            
            postMailerJob1.UpdateMailerwithIncrementalCount(mailer.Id,5);
         
         Test.stopTest();
        
    }
    
    // For Account Filter
    static testmethod void createMailer_test4(){
        EB_AkaMailer__c mailer = [select id from EB_AkaMailer__c where CMC_24x7_Contact_Types__c = true limit 1];
        
        Test.startTest();
        
            string contactQuery = 'select Id,Email,IsEmailBounced,AccountId,AKAM_Contact_ID__c,Name,Account.AKAM_Account_ID__c from Contact where Email != null ';
            CMC_postMailerActivityBatchJob asyncJob= new CMC_postMailerActivityBatchJob(contactQuery, true, mailer.Id);
            Database.executeBatch(asyncJob);    
            
            CMC_postMailerActivityBatchJob  postMailerJob = new CMC_postMailerActivityBatchJob(null, true, mailer.Id);
            postMailerJob.postMailerActivity(mailer.Id);
            postMailerJob.updateMailerCompleteStatus(mailer.Id);
               
         Test.stopTest();
        
    }

    // For Manual Entered Email Address - Asyn
     static testmethod void createMailer_test5(){
        EB_AkaMailer__c mailer = [select Id from EB_AkaMailer__c where CMC_24x7_Contact_Types__c = false limit 1];
         Test.startTest();
            
            // Creating Email List
            List<string> emailList = new List<string>();
            emailList.add('cmctest1@gmail.com');
            emailList.add('cmctest2@gmail.com');
         
            ID jobID = System.enqueueJob(new CMC_AsyncpostMailerActivtyManualEmail(emailList,mailer.Id)); 
         CMC_postMailerActivityBatchJob  postMailerJob1 = new CMC_postMailerActivityBatchJob(); 
         postMailerJob1.UpdateMailerwithTotalBatchCount(jobID,mailer.Id);         
            
         Test.stopTest();
        
    }
    
    //For Authorized Contacts
    static testmethod void createMailer_test6(){
        test.startTest();
            PageReference pageRef1 = Page.CMC_IncidentNotificationTool;
            Test.setCurrentPage(pageRef1);
            ApexPages.Standardcontroller sc1 = new ApexPages.Standardcontroller(new EB_AkaMailer__c());
            CMC_IncidentNotificationToolController mailerclass = new CMC_IncidentNotificationToolController(sc1);
            mailerclass.mailerFormInput = '{"Filters":[{"Id":"","CMC_Filter_Order__c":1,"CMC_Filter_Field__c":"Policy Domain Name","CMC_Filter_Condition__c":"Equal To","CMC_Filter_Value__c":"testpd"},'+
            '{"Id":"","CMC_Filter_Order__c":2,"CMC_Filter_Field__c":"Marketing Product Name","CMC_Filter_Condition__c":"In","CMC_Filter_Value__c":"testproduct"}],'+
             '"FilterLogic":"","AccountInfo":{"ContactType":"Authorized Contacts","AccountType":["Emergency Notification Recipients"],"CustomerSelection":" Selected Customers"}}';
            List<SelectOption> templateList = mailerclass.getTemplateNames();
            mailerclass.getTypes();
            mailerclass.getConditions();
            mailerclass.getRadioItems();
            mailerclass.updateFilterListValue();
            mailerclass.templateName = [select Name from EmailTemplate where folder.developername In ('CMC_INT_Single_Email_Templates','CMC_INT_Mass_Email_Templates') AND IsActive = True LIMIT 1].Name;
            mailerclass.createMailerData();
            mailerclass.queryBuildForAttachment();
            
            //Download as CSV CTRL
            PageReference downloadCSVpage = Page.CMC_DownloadAsCSV;
            Test.setCurrentPage(downloadCSVpage);
            ApexPages.currentPage().getParameters().put('mailerId',mailerclass.mailerObject.Id);
            ApexPages.currentPage().getParameters().put('download','PolicyDomainDetails');
            CMC_DownloadAsCSVCtrl downloadCSVCtrl = new CMC_DownloadAsCSVCtrl();
        
            mailerclass.reloadPage();
            mailerclass.mailerObject.CMC_Approval_Status__c = 'Approved';
            mailerclass.createMailerData();
            mailerclass.queryBuildForAttachment();
        
            mailerclass.mailerFormInput = '{"Filters":"","FilterLogic":"","AccountInfo":{"ContactType":"Authorized Contact","AccountType":["Emergency Notification Recipients"],"CustomerSelection":" All Customers"}}';
            mailerclass.mailerObject.CMC_Is_Approved__c = false;
            mailerclass.createMailerData();
            mailerclass.queryBuildForAttachment();
            mailerclass.sendTestEmail();
            mailerclass.updatedFilterJSON = 'Test';
            mailerclass.mailerIdForUpdate = mailerclass.mailerObject.Id;
            mailerclass.updateFilterJSONWithId();
            mailerclass.SINumber = 'Test';
            mailerclass.ValidateSINumber();
            mailerclass.mailerObject.CMC_Approval_Status__c = 'Approved';
            mailerclass.createMailerData();
            mailerclass.queryBuildForAttachment();
            CMC_IncidentNotificationToolController.processChunk(True, mailerclass.mailerObject.Id, 'Test','Test','Test');
            mailerclass.emailProcessCount();
            system.debug([Select Id, Body, ContentType from ATTACHMENT where parentId =:mailerclass.mailerObject.Id AND Name = 'QueryString.txt' Limit 1]);
            
            //Email Preview CTRL
            PageReference emailPreviewpage = Page.CMC_EmailPreview;
            Test.setCurrentPage(emailPreviewpage);
            ApexPages.currentPage().getParameters().put('mailerId',mailerclass.mailerObject.Id);
            CMC_EmailPreviewCtrl emailPreviewCtrl = new CMC_EmailPreviewCtrl();
            emailPreviewCtrl.FetchEmailBody();
            
            //Trigger call
            Delete mailerclass.mailerObject;

        Test.stopTest();
            
    }
    //For Authorized Contacts filter with attachments
    static testmethod void createMailer_test6_2(){
    
    EB_AkaMailer__c mailer = new EB_AkaMailer__c(AuthCon_Authorized_Contacts__c = True,CMC_24x7_Contact_Types__c = False, EB_Status__c = 'Draft', CMC_Selected_Customers__c = True, AuthCon_Maint_Notification_Recipient__c = True, AuthCon_Emergency_Notification_Recipient__c = False);
    mailer.RecordTypeId = Schema.SObjectType.EB_AkaMailer__c.getRecordTypeInfosByName().get('CMC').getRecordTypeId();
    mailer.CMC_Subject__c = 'Test';
    mailer.EB_AdditionalIssueDescription__c = 'Test';
    mailer.EB_Type__c  ='Mass Email';    
    insert mailer;

    CMC_Mailer_Filter__c filter = new CMC_Mailer_Filter__c();
    filter.CMC_Filter_Condition__c = 'In';
    filter.CMC_Filter_Value__c = '';
    filter.CMC_Filter_Field__c = 'Marketing Product Name';
    filter.CMC_Filter_Mailer__c = mailer.Id;
    filter.CMC_Filter_Order__c = 1;
    insert filter;
        
    String pdString  = 'testproduct,testproduct2';
        Attachment attachmentfilter = new Attachment();
        attachmentfilter.parentId = filter.Id;
        attachmentfilter.Name = 'MPName.txt'; 
        attachmentfilter.ContentType = 'application/text';
        attachmentfilter.body = Blob.valueOf(pdString);
        Upsert attachmentfilter;  
        
    EB_AkaMailer__c mailerobject = [Select id, AuthCon_Authorized_Contacts__c, CMC_24x7_Contact_Types__c, AuthCon_Maint_Notification_Recipient__c, AuthCon_Emergency_Notification_Recipient__c, (select id, CMC_Filter_Condition__c, CMC_Filter_Value__c, CMC_Filter_Field__c, CMC_Filter_Order__c from CMC_Mailer_Filters__r) from EB_AkaMailer__c where id = :mailer.id limit 1];
        
    String queryString = 'SELECT Id FROM Policy_Domain__c WHERE (Policy_Domain_State__c = \'Active\')';

    Test.startTest();
        CMC_MailerHelper.createAccount(queryString, mailerobject);
    Test.stopTest();
        
    }
    
    // Account Filter for Authorized Contacts
    static testmethod void createMailer_test7(){
        EB_AkaMailer__c mailer = [select id from EB_AkaMailer__c where AuthCon_Authorized_Contacts__c = true limit 1];
        
        Test.startTest();
        
            string contactQuery = 'select Id,Email,IsEmailBounced,AccountId,AKAM_Contact_ID__c,Name,Account.AKAM_Account_ID__c from Contact where Email != null ';
            CMC_postMailerActivityBatchJob asyncJob= new CMC_postMailerActivityBatchJob(contactQuery, true, mailer.Id);
            Database.executeBatch(asyncJob);    
            
            CMC_postMailerActivityBatchJob  postMailerJob = new CMC_postMailerActivityBatchJob(null, true, mailer.Id);
            postMailerJob.postMailerActivity(mailer.Id);
            postMailerJob.updateMailerCompleteStatus(mailer.Id);
               
         Test.stopTest();
        
    }
    static testmethod void createMailer_test8_2(){
    EB_AkaMailer__c mailer = [select Id from EB_AkaMailer__c where CMC_24x7_Contact_Types__c = true limit 1];
    CMC_Mailer_Filter__c filter = new CMC_Mailer_Filter__c();
    filter.CMC_Filter_Condition__c = 'Equal To';
    filter.CMC_Filter_Value__c = 'testproduct';
    filter.CMC_Filter_Field__c = 'Marketing Product Name';
    filter.CMC_Filter_Mailer__c = mailer.Id;
    filter.CMC_Filter_Order__c = 1;
    insert filter;
    List<CMC_Mailer_Filter__c> lfilter = new List<CMC_Mailer_Filter__c>();
    lfilter.add(filter);
    Test.startTest();
        CMC_MailerHelper.generateQueryForFilters(lfilter, '', true);
    Test.stopTest();
        
    }
    
      static testmethod void createMailer_test8(){
        EB_AkaMailer__c mailer = [select Id from EB_AkaMailer__c where CMC_24x7_Contact_Types__c = true limit 1];
        String emailString  = 'cmcemail1.com,cmcemail2.com';
        Attachment attachment = new Attachment();
        attachment.parentId = mailer.Id;
        attachment.Name = 'emailaddress.txt';
        attachment.ContentType = 'application/text';
        attachment.body = Blob.valueOf(emailString);
        Upsert attachment;

        String queryString  = 'SELECT Id FROM Policy_Domain__c WHERE (Policy_Domain_State__c = \'Active\') ';
        Attachment attachment1 = new Attachment();
        attachment1.parentId = mailer.Id;
        attachment1.Name = 'QueryString.txt';
        attachment1.ContentType = 'application/text';
        attachment1.body = Blob.valueOf(queryString);
        Upsert attachment1;


        String rawEmailAddresses = '';
        
        List<CMC_Mailer_Filter__c> lfilter = new List<CMC_Mailer_Filter__c>();
    CMC_Mailer_Filter__c filter1 = new CMC_Mailer_Filter__c();
    filter1.CMC_Filter_Condition__c = 'In';
    filter1.CMC_Filter_Value__c = '';
    filter1.CMC_Filter_Field__c = 'Policy Domain Name';
    filter1.CMC_Filter_Mailer__c = mailer.Id;
    filter1.CMC_Filter_Order__c = 1;
    insert filter1;
    CMC_Mailer_Filter__c filter2 = new CMC_Mailer_Filter__c();
    filter2.CMC_Filter_Condition__c = 'Equal To';
    filter2.CMC_Filter_Value__c = 'testproduct';
    filter2.CMC_Filter_Field__c = 'Marketing Product Name';
    filter2.CMC_Filter_Mailer__c = mailer.Id;
    filter2.CMC_Filter_Order__c = 2;
    lfilter.add(filter2);
    CMC_Mailer_Filter__c filter3 = new CMC_Mailer_Filter__c();
    filter3.CMC_Filter_Condition__c = 'Not Equal To';
    filter3.CMC_Filter_Value__c = 'testproduct';
    filter3.CMC_Filter_Field__c = 'Marketing Product Name';
    filter3.CMC_Filter_Mailer__c = mailer.Id;
    filter3.CMC_Filter_Order__c = 3;
    lfilter.add(filter3);
    insert lfilter;
    lfilter.add(filter1);

    String pdString  = 'testpd,testpd123';
    Attachment attachmentfilter = new Attachment();
        attachmentfilter.parentId = filter1.Id;
        attachmentfilter.Name = 'PdName.txt'; 
        attachmentfilter.ContentType = 'application/text';
        attachmentfilter.body = Blob.valueOf(pdString);
        Upsert attachmentfilter;
    Test.startTest();
            
        CMC_MailerHelper.ValidateEmailAddresses(rawEmailAddresses,mailer.Id,true); 
        CMC_MailerHelper.ValidateEmailAddresses(rawEmailAddresses,mailer.Id,false); 
        CMC_MailerHelper.GetEmailsCount(rawEmailAddresses,mailer.Id); 
        CMC_MailerHelper.generateQueryForFilters(lfilter, '', false);
        CMC_MailerHelper.cleanUpBeforeSave(mailer.Id, 'Attachment');
        CMC_MailerHelper.cleanUpBeforeSave(mailer.Id, 'QueryString');
        CMC_MailerHelper.UpdateAttachmentIds(mailer.Id);
    Test.stopTest();
        
    }
    static testmethod void createMailer_test9(){
    CMC_Settings__mdt cmcSettingsRecord = [SELECT CMC_Exclude_Akamai_Email_Id__c,CMC_Default_Account_Id__c,CMC_Default_Contact_Id__c, CMC_Default_Policy_Domain_Id__c FROM CMC_Settings__mdt WHERE DeveloperName = 'CMC'];
    EB_AkaMailer__c mailer = [select Id from EB_AkaMailer__c where CMC_24x7_Contact_Types__c = true limit 1];
    String defaultAccountId = cmcSettingsRecord.CMC_Default_Account_Id__c;
    Account acc = [select Id from Account where AKAM_Account_ID__c = :defaultAccountId limit 1]; 
    Policy_Domain__c pd = [select Id from Policy_Domain__c where Account_Name__c = :acc.Id limit 1];

    Test.startTest();
    List<String> lAccId = new List<String>();
    lAccId.add(acc.id);
    List<String> lPDId = new List<String>();
    lPDId.add(pd.id);

    CMC_MailerHelper.CreateException(mailer.Id, lAccId, 'Accounts');
    CMC_MailerHelper.CreateException(mailer.Id, lPDId, 'PolicyDomainsWithAllBouncedAC');


    Test.stopTest();
        
    }

}