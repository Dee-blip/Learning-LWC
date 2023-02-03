/*---------------------------------------------------------------------------------
Class name          :   SC_SI_INT_Tool_Test
Author              :   Vamsee / Sheena
Created             :   20-March-2021
JIRA                :   ESESP-4360
Purpose             :   Test Class for INT Functionality

Last Modified         Developer         	Purpose            
============= ========================		==========
20-March-2021    	Sheena/Vamsee      		Initial Version
* --------------------------------------------------------------------------------*/
@isTest
public class SC_SI_INT_Tool_Test {
    
    @testSetup
    static void setupMethod()
    {
        utilTestClass.createCustomSettings();
        CMC_Settings__mdt cmcSettingsRecord = [SELECT CMC_Exclude_Akamai_Email_Id__c,CMC_Default_Account_Id__c,CMC_Default_Contact_Id__c, CMC_Default_Policy_Domain_Id__c FROM CMC_Settings__mdt WHERE DeveloperName = 'CMC'];
        
        
        String recordTypeId = Schema.SObjectType.EB_AkaMailer__c.getRecordTypeInfosByName().get('CMC').getRecordTypeId();
        String templateId = [Select Id from EmailTemplate where name = 'Blank Notification - HTML' and Folder.Name='INT - Single Email Templates'].Id;
        
        // Mailer Creation
        List<EB_AkaMailer__c> mailerList = new  List<EB_AkaMailer__c>();
        EB_AkaMailer__c newMailer = new EB_AkaMailer__c(CMC_Selected_Customers__c=true,CMC_All_Customers__c=false, CMC_24x7_Contact_Types__c=true, CMC_Partners__c=true,
                                                        CMC_Direct_Customers__c=true, CMC_Indirect_Customers__c=true, RecordTypeId=recordTypeId, 
                                                        CMC_Subject__c='Akamai Notification', EB_Status__c='Draft', CMC_Filter_Logic__c = '1 OR 2',
                                                        CMC_Template_Name__c='Blank Notification - HTML', CMC_Template_ID__c=templateId, EB_Type__c='Single Email',
                                                        EB_AdditionalIssueDescription__c='<p>Test Content</p>');
        mailerList.add(newMailer);
        EB_AkaMailer__c newMailer2 = new EB_AkaMailer__c(CMC_Selected_Customers__c=false,CMC_All_Customers__c=true, CMC_24x7_Contact_Types__c=true, CMC_Partners__c=true,
                                                         CMC_Direct_Customers__c=true, CMC_Indirect_Customers__c=true, RecordTypeId=recordTypeId, 
                                                         CMC_Subject__c='Akamai Notification', EB_Status__c='Processed', EB_Type__c='Single Email',
                                                         EB_AdditionalIssueDescription__c='<p>Test Mailer Content</p>');
        mailerList.add(newMailer2);
        
        EB_AkaMailer__c newMailer3 = new EB_AkaMailer__c(AuthCon_Authorized_Contacts__c=True, RecordTypeId=recordTypeId, AuthCon_Emergency_Notification_Recipient__c = True,
                                                         CMC_Subject__c='Akamai Notification', EB_Status__c='Draft', EB_Type__c='Single Email',
                                                         EB_AdditionalIssueDescription__c='<p>Test Mailer Content</p>', Reminder__c=system.now().addDays(1));
        
        mailerList.add(newMailer3);
        
        EB_AkaMailer__c newMailer4 = new EB_AkaMailer__c(RecordTypeId=recordTypeId,CMC_Subject__c='Akamai Notification', EB_Status__c='Draft', EB_Type__c='Mass Email',
                                                         EB_AdditionalIssueDescription__c='<p>Test Mailer Content</p>',CMC_Manual_Email_Addresses__c='abc@xyz.com');
        mailerList.add(newMailer4);
        insert mailerList;
        
        // Attachments Creation
        List<attachment> attachmentList = new List<attachment>();
        Attachment attachment = new Attachment();
        attachment.Body = Blob.valueOf('Test Email');
        attachment.Name = String.valueOf('QueryString.txt');
        attachment.ParentId = newMailer.Id;
        attachmentList.add(attachment);
        
        Attachment mailerAttachment = new Attachment();
        mailerAttachment.Body = Blob.valueOf('Test Email');
        mailerAttachment.Name = String.valueOf('QueryString.txt');
        mailerAttachment.ParentId = newMailer2.Id;
        attachmentList.add(mailerAttachment);
        
        Attachment authMailerAttachment = new Attachment();
        authMailerAttachment.Body = Blob.valueOf('Test Email');
        authMailerAttachment.Name = String.valueOf('QueryString.txt');
        authMailerAttachment.ParentId = newMailer3.Id;
        attachmentList.add(authMailerAttachment);
        insert attachmentList;
        
        //Create Filters
        List<CMC_Mailer_Filter__c> filterList = new List<CMC_Mailer_Filter__c>();
        CMC_Mailer_Filter__c mailerFilter1 = new CMC_Mailer_Filter__c(CMC_Filter_Mailer__c = newMailer.Id, CMC_Filter_Condition__c = 'Contains', CMC_Filter_Field__c  = 'Customer Name', CMC_Filter_Order__c = 1, CMC_Filter_Value__c = 'Test');
        CMC_Mailer_Filter__c mailerFilter2 = new CMC_Mailer_Filter__c(CMC_Filter_Mailer__c = newMailer.Id, CMC_Filter_Condition__c = 'In', CMC_Filter_Field__c  = 'Marketing Product Name', CMC_Filter_Order__c = 2, CMC_Filter_Value__c = 'Test');
        CMC_Mailer_Filter__c mailerFilter3 = new CMC_Mailer_Filter__c(CMC_Filter_Mailer__c = newMailer3.Id, CMC_Filter_Condition__c = 'Contains', CMC_Filter_Field__c  = 'Policy Domain Name', CMC_Filter_Order__c = 1, CMC_Filter_Value__c = 'testpd');
        CMC_Mailer_Filter__c mailerFilter4 = new CMC_Mailer_Filter__c(CMC_Filter_Mailer__c = newMailer3.Id, CMC_Filter_Condition__c = 'In', CMC_Filter_Field__c  = 'Marketing Product Name', CMC_Filter_Order__c = 2, CMC_Filter_Value__c = 'testpd');
        CMC_Mailer_Filter__c mailerFilter5 = new CMC_Mailer_Filter__c(CMC_Filter_Mailer__c = newMailer3.Id, CMC_Filter_Condition__c = 'Equal To', CMC_Filter_Field__c  = 'Marketing Product Name', CMC_Filter_Order__c = 3, CMC_Filter_Value__c = 'testpd');
        
        
        filterList.add(mailerFilter1);
        filterList.add(mailerFilter2);
        filterList.add(mailerFilter3);
        filterList.add(mailerFilter4);
        filterList.add(mailerFilter5);
        
        Insert filterList;
        
        
        // Account Creation
        List<Account> accountObjectList = new List<Account>();
        Account accountRecord1 = new Account(Name='Test Account1',AKAM_Account_ID__c=cmcSettingsRecord.CMC_Default_Account_Id__c,Indirect_Customer__c=True, Direct_Customer__c=True,IsPartnerCustom__c=True, Type = 'Brand - Active');
        accountObjectList.add(accountRecord1);
        Account accountRecord2 = new Account(Name='Test Account2',AKAM_Account_ID__c='Test_111',Indirect_Customer__c=True, Direct_Customer__c=True,IsPartnerCustom__c=True, Type = 'Brand - Active');
        accountObjectList.add(accountRecord2);
        Account accountRecord3 = new Account(Name='Test Account3',AKAM_Account_ID__c='Test_222',Indirect_Customer__c=True, Direct_Customer__c=True,IsPartnerCustom__c=True,  Type = 'Brand - Active');
        accountObjectList.add(accountRecord3);
        Account accountRecord4 = new Account(Name='Test Account4',AKAM_Account_ID__c='Test_333',Indirect_Customer__c=True, Direct_Customer__c=True,IsPartnerCustom__c=True,  Type = 'Brand - Active');
        accountObjectList.add(accountRecord4);
        insert accountObjectList;
        
        //Contact Creation
        List<Contact> contactObjectList = new List<Contact>();
        contact contactRecord1 = new Contact(AccountId = accountObjectList[0].Id, Login__c = 'Test_xyz',Akam_Contact_id__c =cmcSettingsRecord.CMC_Default_Contact_Id__c, Email = Userinfo.getUserEmail() ,No_Longer_with_Company__c = false, LastName = 'Test Contact', Contact_Type__c ='Technical Primary - 24x7',Primary_Contact_Method__c ='Mobile', SMS_Notifications__c = 'testsms1@test.com');
        contactObjectList.add(contactRecord1);
        contact contactRecord2 = new Contact(AccountId = accountObjectList[1].Id, Login__c = 'Test_xyz1',Akam_Contact_id__c ='test-111', Email = 'test111@test.com' ,No_Longer_with_Company__c = false, LastName = 'Test Contact1', Contact_Type__c ='Technical Primary - 24x7',Primary_Contact_Method__c ='Mobile', SMS_Notifications__c = 'testsms2@test.com');
        contactObjectList.add(contactRecord2);
        contact contactRecord3 = new Contact(AccountId = accountObjectList[2].Id, Login__c = 'Test_xyz2',Akam_Contact_id__c ='test-222', Email = 'test222@test.com' ,No_Longer_with_Company__c = false, LastName = 'Test Contact2', Contact_Type__c ='Technical Primary - 24x7',Primary_Contact_Method__c ='Mobile',SMS_Notifications__c = 'testsms3@test.com');
        contactObjectList.add(contactRecord3);
        insert contactObjectList;
        
        //Policy Domain creation
        List<Policy_Domain__c> pdObjectList = new List<Policy_Domain__c>();
        Policy_Domain__c pd1 = new Policy_Domain__c(Name = 'testpd', Account_Name__c = accountObjectList[0].Id, AKAM_Policy_Domain_ID__c = 'Test-Pd-111', Policy_Domain_Description__c = 'Test-Pd-111', Policy_Domain_State__c = 'Active', Product__c = 'testproduct', Additional_Product__c = 'test add prod');
        pdObjectList.add(pd1);
        Integer i =0;
        for(String eachAkamPdId : cmcSettingsRecord.CMC_Default_Policy_Domain_Id__c.split(',')){
            Policy_Domain__c pd2 = new Policy_Domain__c(Name = 'DefaultTestpd' + i, Account_Name__c = accountObjectList[2].Id, AKAM_Policy_Domain_ID__c = eachAkamPdId, Policy_Domain_Description__c = 'default Test-Pd-123', Policy_Domain_State__c = 'Active', Product__c = 'defaulttestproduct', Additional_Product__c = 'test add prod');
            pdObjectList.add(pd2);
            i = i+1;
        }
        Policy_Domain__c pd3 = new Policy_Domain__c(Name = 'testpd2', Account_Name__c = accountObjectList[0].Id, AKAM_Policy_Domain_ID__c = 'Test-Pd-222', Policy_Domain_Description__c = 'Test-Pd-222', Policy_Domain_State__c = 'Active', Product__c = 'testproduct', Additional_Product__c = 'test add prod');
        pdObjectList.add(pd3);
        insert pdObjectList;
        
        // Insert Service ACcount PD Mapping
        List<Service_Account_PD_Mapping__c> ServAccPdMaps = new List<Service_Account_PD_Mapping__c>();
        
        Service_Account_PD_Mapping__c serAcc1 = new Service_Account_PD_Mapping__c(Policy_Domain__c = pdObjectList[0].Id, Service_Account__c =  accountObjectList[1].Id);
        Service_Account_PD_Mapping__c serAcc2 = new Service_Account_PD_Mapping__c(Policy_Domain__c = pdObjectList[1].Id, Service_Account__c =  accountObjectList[3].Id);
        Service_Account_PD_Mapping__c serAcc3 = new Service_Account_PD_Mapping__c(Policy_Domain__c = pdObjectList[1].Id, Service_Account__c =  accountObjectList[1].Id);

        ServAccPdMaps.add(serAcc1);
        ServAccPdMaps.add(serAcc2);
        ServAccPdMaps.add(serAcc3);
        
        insert ServAccPdMaps;
        
        //Authorized Contacts created
        List<Authorized_Contact__c > acObjectList = new List<Authorized_Contact__c >();
        Authorized_Contact__c  ac1 = new Authorized_Contact__c (Contact_Name__c = contactObjectList[0].Id, Emergency_Email__c = true, Policy_Domain__c = pdObjectList[0].Id, Product_Interests__c = 'All');
        acObjectList.add(ac1);
        Authorized_Contact__c  ac2 = new Authorized_Contact__c (Contact_Name__c = contactObjectList[1].Id, Emergency_Email__c = true, Policy_Domain__c = pdObjectList[1].Id, Product_Interests__c = 'All', Service__c = true);
        acObjectList.add(ac2);
        Authorized_Contact__c  ac3 = new Authorized_Contact__c (Contact_Name__c = contactObjectList[2].Id, Emergency_Email__c = true, Policy_Domain__c = pdObjectList[2].Id, Product_Interests__c = 'All', Service__c = false);
        acObjectList.add(ac3);
        //Authorized_Contact__c  ac4 = new Authorized_Contact__c (Contact_Name__c = contactObjectList[3].Id, Emergency_Email__c = true, Policy_Domain__c = pdObjectList[3].Id, Product_Interests__c = 'All', Service__c = true);
        //acObjectList.add(ac4);
        insert acObjectList;
        
        // Custom Setting Record Creation
        SC_SupportEmail__c custSetting = new SC_SupportEmail__c();
        custSetting.Name='1';
        custSetting.CashAppsEmail__c = 'slebhxmmxxcq@ndhfzaqa.com';
        custSetting.Default_Task_Owner__c  = 'ONA';
        custSetting.KSDJobStartDate__c  =  Date.newInstance(2016, 4, 20);
        custSetting.Last_Contract_Detail_Synch_Job_Run__c  = datetime.newInstance(2008, 5, 12);
        custSetting.Last_Contract_Header_Synch_Job_Run__c = datetime.newInstance(2008, 5, 12);	
        custSetting.Last_EngMrktgProd_Synch_Job_Run__c= datetime.newInstance(2008, 5, 12);	
        custSetting.Last_SupportAdvocacy_EngProd_Job_Run__c = datetime.newInstance(2008, 10, 16);
        custSetting.PartnerCaseEmail__c = 'uduufcyhjyus@rhxoadsy.com';	
        custSetting.SOAJobStartDate__c  = Date.newInstance(2016, 5, 19);
        custSetting.Support_Email_AMS__c = 'ommmsdyryrdf@imtxoary.com';	
        custSetting.Support_Email_AutoGen__c  = 'nkjffxrgvazl@yysfuccl.com';
        insert custSetting;
        
         // Creating Mailer Account
        EB_AkaMAccount__c mailerAccount = new EB_AkaMAccount__c();
        mailerAccount.RecordTypeId = Schema.SObjectType.EB_AkaMAccount__c.getRecordTypeInfosByName().get('CMC').getRecordTypeId();
        mailerAccount.EB_Account__c = accountObjectList[1].Id;
        mailerAccount.EB_AkaMailer__c = newMailer3.Id;
        insert mailerAccount;
        
        
    }
    
    @isTest
    public static void testControllerMethods()
    {
        Test.startTest();
        
        // Fetching Mailer
        EB_AkaMailer__c mailer = [Select Id from EB_AkaMailer__c where CMC_Selected_Customers__c = true limit 1];
        
        // JSON  to create Mailer
        String mailerJSON = '{"CMC_IRAPT_SI_Number__c":"","Is_Approved":false,"Content":"<p>Test Content</p>","Subject":"Akamai Notification","Template":"Blank Notification - HTML","ContactType":"24x7 Contact Types","AccountType":"Partner,Direct Customer,Indirect Customer","CustomerGroupValue":"Selected Customers"}';
        String filterJSON = '[{"field" : "Account ID","condition" : "Equal To","filterValue" : "Test","downloadLink" : "undefined","fileName" : "","removeButton" : "0","Order":"1"},{"field" : "Support Level","condition" : "In","filterValue" : "","downloadLink" : "undefined","fileName" : "Support Level.csv","removeButton" : "1","Order":"2"}]';
        
        List<testFileCreation> filesToInsert = new List<testFileCreation>();
        testFileCreation fileToInsert = new testFileCreation();
        fileToInsert.Title='Support Level.csv';
        fileToInsert.VersionData='123456=';
        fileToInsert.parentId= mailer.Id;
        filesToInsert.add(fileToInsert);
        
        String emailBody = '<p>Test Email</p>';
        
        
        // Controller Methods
        Map<String,EmailTemplate> templateMap = SC_SI_INT_Tool_Controller.getTemplateNames();
        SC_SI_INT_Tool_Controller.saveMailer(mailerJSON,filterJSON,mailer.Id,true,templateMap);
        SC_SI_INT_Tool_Controller.saveFile(filesToInsert,'Filter');
        SC_SI_INT_Tool_Controller.saveFile(filesToInsert,'Mailer');
        SC_SI_INT_Tool_Controller.getMailerData(mailer.Id);
        SC_SI_INT_Tool_Controller.sendTestEmail(mailer.Id);
        SC_SI_INT_Tool_Controller.fetchEmailBody(mailer.Id);
        SC_SI_INT_Tool_Controller.postMailer(mailer.Id,emailBody);
        SC_SI_INT_Tool_Controller.getAccountsCount(mailer.Id);
        SC_SI_INT_Tool_Controller.getEmailsCount('sbhan@akmamai.com',mailer.Id);
        SC_SI_INT_Tool_Controller.downloadAsCSV(mailer.Id,'AccountDetails');
        SC_SI_INT_Tool_Controller.emailProcessCount(mailer.Id);
        
        Test.stopTest();
        
    }
    
    @isTest
    public static void testControllerMethods2()
    {
        Test.startTest();
        
        // Fetching Mailer
        EB_AkaMailer__c mailer = [Select Id from EB_AkaMailer__c where CMC_Selected_Customers__c = false limit 1];
        
        User u = [Select id from User where IsActive=true limit 1];
        
        // JSON  to create Mailer
        String mailerJSON = '{"CMC_IRAPT_SI_Number__c":"","Is_Approved":false,"Content":"<p>Test Content</p>","Subject":"Akamai Notification","Template":"","ContactType":"Only Send To Manually Entered Email Addresses","EmailInputValue":"Enter Email Addresses","manualEmaliAddresses":"sbhan@akamai.com"}';
        String mailerJSON2 = '{"CMC_IRAPT_SI_Number__c":"","Is_Approved":false,"Content":"<p>Test Content</p>","Subject":"Akamai Notification","Template":"","ContactType":"Authorized Contacts","RecipientTypeValue":"Emergency Notification Recipients","CustomerGroupValue":"All Customers"}';
        
        Map<String,EmailTemplate> templateMap = SC_SI_INT_Tool_Controller.getTemplateNames();
        
        // Controller Methods
        SC_SI_INT_Tool_Controller.saveMailer(mailerJSON,null,null,true,templateMap);
        SC_SI_INT_Tool_Controller.saveMailer(mailerJSON2,null,null,false,templateMap);
        SC_SI_INT_Tool_Controller.sendTestEmail(mailer.Id);
        SC_SI_INT_Tool_Controller.fetchEmailBody(mailer.Id);
        SC_SI_INT_Tool_Controller.downloadAsCSV(mailer.Id,'PolicyDomainDetails');
        SC_SI_INT_Tool_Controller.downloadAsCSV(mailer.Id,'ValidEmails');
        SC_SI_INT_Tool_Controller.downloadAsCSV(mailer.Id,'InvalidEmails');
        SC_SI_INT_Tool_Controller.emailProcessCount(mailer.Id);
        SC_SI_INT_Tool_Controller.checkInternalUsers(u.Id);
        Test.stopTest();
    }
    
    public class testFileCreation
    {
        String Title;
        String VersionData;
        String parentId;
    }
    @isTest
    public static void testHelperMethods1(){
        // Fetching Mailer
        EB_AkaMailer__c mailer = [Select Id, CMC_Approval_Status__c from EB_AkaMailer__c where CMC_Selected_Customers__c = True limit 1];
        mailer.CMC_Approval_Status__c = 'Approved';
        Update mailer;
        SC_SI_INT_Tool_Helper.generateQueryString(mailer.Id);
        SC_SI_INT_Tool_Helper.ValidateEmailAddresses('test@akamai.com,test2@akamai.com,test',mailer.Id, True);
        SC_SI_INT_Tool_Helper.ValidateEmailAddresses('test@akamai.com,test2@akamai.com,test',mailer.Id, False);
        SC_SI_INT_Tool_Helper.splitString('test@akamai.com,test2@akamai.com,test');
        SC_SI_INT_Tool_Helper.SplitStringForAttachment('test@akamai.com,test2@akamai.com,test');
        
        
    }
    
    @isTest
    public static void testHelperMethods2(){
        // Fetching Mailer
        EB_AkaMailer__c mailer = [Select Id, CMC_Approval_Status__c from EB_AkaMailer__c where AuthCon_Authorized_Contacts__c = True limit 1];
        mailer.CMC_Approval_Status__c = 'Approved';
        Update mailer;
        SC_SI_INT_Tool_Helper.generateQueryString(mailer.Id);
        SC_SI_INT_Tool_Helper.CreateException(mailer.Id, new List<string>{'test1','test2'}, 'Emails');
        
        User u = [Select id from User where Profile.Name='Support - Tech Support Manager with Customer Notification' and Id IN (SELECT AssigneeId FROM PermissionSetAssignment WHERE PermissionSet.Name = 'CMC_Incident_Notification_User') and IsActive=true limit 1];
        CMC_Mailer_Filter__c mailerFilter = [Select id from CMC_Mailer_Filter__c where CMC_Filter_Condition__c='Equal To'];
        
        try{
            system.runAs(u){
                delete mailerFilter;
            }
        }
        catch(exception ex){
            system.debug('exception message//'+ex.getMessage());
        }
        
        
    }
    
    
    @isTest
    public static void testSendEmails(){
        EB_AkaMailer__c mailer = [select Id, CMC_24x7_Contact_Types__c,CMC_Manual_Email_Addresses__c,CMC_Template_ID__c,
                                  CMC_Subject__c,EB_AdditionalIssueDescription__c,AuthCon_Authorized_Contacts__c 
                                  from EB_AkaMailer__c where  EB_Type__c='Mass Email' limit 1];
        Test.startTest();
        
        SC_SI_INT_Tool_BatchJob  postMailerJob = new SC_SI_INT_Tool_BatchJob(null, true, mailer.Id);
        postMailerJob.postMailerActivity(mailer.Id); 
        
        List<Contact> FilterContacts = [select Id,Email,IsEmailBounced,AccountId,AKAM_Contact_ID__c,Name,Account.AKAM_Account_ID__c,SMS_Notifications__c from Contact where Email != null];
        SC_SI_INT_Tool_BatchJob  postMailerJob1 = new SC_SI_INT_Tool_BatchJob();  
        postMailerJob1.sendEmailToContacts(FilterContacts,mailer);
        postMailerJob1.processBouncedContacts(FilterContacts,'..Exception',mailer.Id,true);
        
        
        postMailerJob1.updateMailerwithIncrementalCount(mailer.Id,5);
        postMailerJob1.sendEmailToContacts(FilterContacts,mailer,'Process Mass Mail');
        
        Test.stopTest();
        
    }
    @isTest
    // For Account Filter
    public static void testSendEmails2(){
        EB_AkaMailer__c mailer = [select id from EB_AkaMailer__c where CMC_24x7_Contact_Types__c = true limit 1];
        
        Test.startTest();
        
        string contactQuery = 'select Id,Email,IsEmailBounced,AccountId,AKAM_Contact_ID__c,Name,Account.AKAM_Account_ID__c from Contact where Email != null ';
        SC_SI_INT_Tool_BatchJob asyncJob= new SC_SI_INT_Tool_BatchJob(contactQuery, true, mailer.Id);
        Database.executeBatch(asyncJob);    
        
        SC_SI_INT_Tool_BatchJob  postMailerJob = new SC_SI_INT_Tool_BatchJob(null, true, mailer.Id);
        postMailerJob.postMailerActivity(mailer.Id);
        postMailerJob.updateMailerCompleteStatus(mailer.Id);
        
        Test.stopTest();
        
    }
    
    @isTest
    // For Manual Entered Email Address - Asyn
    public static void testSendEmails3(){
        EB_AkaMailer__c mailer = [select Id from EB_AkaMailer__c where EB_Type__c = 'Mass Email' limit 1];
        Test.startTest();
        
        // Creating Email List
        List<string> emailList = new List<string>();
        emailList.add('cmctest1@gmail.com');
        emailList.add('cmctest2@gmail.com');
        
        ID jobID = System.enqueueJob(new SC_SI_INT_AsyncPostMailerManualEmail(emailList,mailer.Id)); 
        SC_SI_INT_Tool_BatchJob  postMailerJob1 = new SC_SI_INT_Tool_BatchJob(); 
        postMailerJob1.updateMailerwithTotalBatchCount(jobID,mailer.Id);         
        
        Test.stopTest();
        
    }
    
    @isTest
    // Account Filter for Authorized Contacts
    public static  void testSendEmails4(){
        EB_AkaMailer__c mailer = [select id from EB_AkaMailer__c where AuthCon_Authorized_Contacts__c = true limit 1];
        system.debug('mailer// socc'+mailer);
        
        Test.startTest();
        
        string contactQuery = 'select Id,Email,IsEmailBounced,AccountId,AKAM_Contact_ID__c,Name,Account.AKAM_Account_ID__c from Contact where Email != null ';
        SC_SI_INT_Tool_BatchJob asyncJob= new SC_SI_INT_Tool_BatchJob(contactQuery, true, mailer.Id);
        Database.executeBatch(asyncJob);    
        
        SC_SI_INT_Tool_BatchJob  postMailerJob = new SC_SI_INT_Tool_BatchJob(null, true, mailer.Id);
        postMailerJob.postMailerActivity(mailer.Id);
        postMailerJob.updateMailerCompleteStatus(mailer.Id);
        
        
        Test.stopTest();
        
    }
    
    
    
}