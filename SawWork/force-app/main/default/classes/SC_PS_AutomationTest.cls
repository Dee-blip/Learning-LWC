/*
    SC_PS_AutomationTest
    @author         : Vishnu
    @Description    : This Class contains methods to cover test cases for PS Automation

    Last Modified         Developer                           Purpose            
    ============= ========================         			  ==========
    22-APR-2022     Ashin Louis                             Added test methods for SC_PSReminderEmailsForManager_Batch and SC_PSReminderEmailsForSc_Batch
*/

@isTest
public without sharing class SC_PS_AutomationTest 
{
	public static List<Account> accList = new List<Account>();
    public static List<PS_Automation_Admin_DL__c> dlList = new List<PS_Automation_Admin_DL__c>();
    public static List<PS_Customer_Mailers__c> customerMailerList = new List<PS_Customer_Mailers__c>();
    public static List<Merge_Contract_Header__c> contractList = new List<Merge_Contract_Header__c>();
    public static List<Autogen_Contract_Header_Detail__c> achdList = new List<Autogen_Contract_Header_Detail__c>();
    public static List<AccountTeamMember> atmList = new List<AccountTeamMember>();
    
    public static PSA_TestUtility testUtil; 
    public static User crmopsUser;
    
    
    // Setup method to create test data.
    static
    {
        crmopsUser = [SELECT id,name from user where alias='CRMOPS'];
       
    }
    @testSetup 
    public static void dataSetup() {
        
        // Creating Account test data
       	Account acc = utilTestClass.CreateAccount('Test Account1');
        acc.Support_Level__c = 'Premier';
        acc.Support_Advocate__c = true;
        acc.Vertical__c = 'Gaming';
        acc.Type ='- Active';
        accList.add(acc);
        
        Account acc2 = utilTestClass.CreateAccount('Test Account2');
        acc.Support_Level__c = 'Premier';
        acc.Support_Advocate__c = true;
        acc.Vertical__c = 'Gambling';
        acc.Type ='- Active';
        accList.add(acc2);
         
		insert accList; 
        
        AccountTeamMember atm = new AccountTeamMember();
        atm.AccountId = accList[0].Id;
        atm.TeamMemberRole = 'Security Services - Primary';
        atm.UserId = UserInfo.getUserId();
        insert atm;
        Account a1 = [Select Id,Name,Type,Vertical__c,Akam_Account_Id__c from Account limit 1];
        System.debug('acc***'+a1.Id+'**'+a1.Name+'**'+a1.Type+'**'+a1.Vertical__c+'**'+a1.Akam_Account_Id__c);
        
        // Creating DL Records test data
        PS_Automation_Admin_DL__c dlRec1 = new PS_Automation_Admin_DL__c();
        dlRec1.RecordTypeId = Schema.SObjectType.PS_Automation_Admin_DL__c.getRecordTypeInfosByName().get('Internal').getRecordTypeId();
        dlRec1.Name = 'Internal DL';
        dlRec1.DL_Email_Address__c = 'test1@example.com,test2@example.com';
        dlList.add(dlRec1);
        PS_Automation_Admin_DL__c dlRec2 = new PS_Automation_Admin_DL__c();
        dlRec2.RecordTypeId = Schema.SObjectType.PS_Automation_Admin_DL__c.getRecordTypeInfosByName().get('External').getRecordTypeId();
        dlRec2.Name = 'External DL';
        dlRec2.DL_Email_Address__c = 'test1@example.com';
        dlRec2.Account__c = accList[0].Id;
        dlList.add(dlRec2);
        
        
        insert dlList;
        
        try{
        PS_Automation_Admin_DL__c dlRec3 = new PS_Automation_Admin_DL__c();
        dlRec3.RecordTypeId = Schema.SObjectType.PS_Automation_Admin_DL__c.getRecordTypeInfosByName().get('Internal').getRecordTypeId();
        dlRec3.Name = 'Internal DL';
        dlRec3.DL_Email_Address__c = 'test4@example.com';
        insert dlRec3;
        }catch(Exception e)
        {
        String message = e.getMessage();
         system.assertEquals(message.contains('Internal Type record is already available.'),true);

        }    
        
        try{
        PS_Automation_Admin_DL__c dlRec4 = new PS_Automation_Admin_DL__c();
        dlRec4.RecordTypeId = Schema.SObjectType.PS_Automation_Admin_DL__c.getRecordTypeInfosByName().get('External').getRecordTypeId();
        dlRec4.Name = 'External DL';
        dlRec4.DL_Email_Address__c = 'test5@example.com';
        dlRec4.Account__c = accList[0].Id;
        insert dlRec4;
        }catch(Exception e)
        {
        String message = e.getMessage();
         system.assertEquals(message.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'),true);

        }   
        
        
        
        // Creating Customer Mailer Records test data
        PS_Customer_Mailers__c mailerRec1 = new PS_Customer_Mailers__c();
        mailerRec1.Account_List__c = accList[0].Name;
        mailerRec1.Audience_Type__c = 'Internal';
        mailerRec1.Is_Master_Record__c = true;
        mailerRec1.Instructions__c = 'Sample Instruction';
        mailerRec1.Product_Name__c = 'MSS;PLX';
        mailerRec1.PS_Customer_Mailer_Name__c = 'Mailer Rec 1';
        mailerRec1.Subject__c = 'Test Subject 1';
        mailerRec1.Content__c = 'Test Content';
        mailerRec1.RecordTypeId = Schema.SObjectType.PS_Customer_Mailers__c.getRecordTypeInfosByName().get('Security Bulletin').getRecordTypeId();
        insert mailerRec1;
        PS_Customer_Mailers__c mailerRec2 = new PS_Customer_Mailers__c();
        mailerRec2.Account__c = accList[0].Id;
        mailerRec2.Parent_PS_Customer_Mailer__c = mailerRec1.Id;
        mailerRec2.Audience_Type__c = 'Internal';
        mailerRec2.Instructions__c = 'Sample Instruction';
        mailerRec2.Product_Name__c = 'PLX';
        mailerRec2.PS_Customer_Mailer_Name__c = 'Mailer Rec 1';
        mailerRec2.Subject__c = 'Test Subject 1';
        mailerRec2.Content__c = 'Test Content';
        mailerRec2.RecordTypeId = Schema.SObjectType.PS_Customer_Mailers__c.getRecordTypeInfosByName().get('Security Bulletin').getRecordTypeId();
        mailerRec2.Team_Member_Id__c = UserInfo.getUserId();
       	mailerRec2.Manager_Id__c = UserInfo.getUserId();
        insert mailerRec2;
        PS_Customer_Mailers__c mailerRec3 = new PS_Customer_Mailers__c();
        mailerRec3.Account__c = accList[0].Id;
        mailerRec3.Parent_PS_Customer_Mailer__c = mailerRec1.Id;
        mailerRec3.Audience_Type__c = 'Internal';
        mailerRec3.Instructions__c = 'Sample Instruction';
        mailerRec3.Product_Name__c = 'PLX';
        mailerRec3.PS_Customer_Mailer_Name__c = 'Mailer Rec 3';
        mailerRec3.Subject__c = 'Test Subject 1';
        mailerRec3.Content__c = 'Test Content';
        mailerRec3.RecordTypeId = Schema.SObjectType.PS_Customer_Mailers__c.getRecordTypeInfosByName().get('Security Bulletin').getRecordTypeId();
        mailerRec3.Team_Member_Id__c = UserInfo.getUserId();
        mailerRec3.Manager_Id__c = UserInfo.getUserId();
        mailerRec3.Reminder_Date_for_Managers__c= system.today();
        mailerRec3.Reminder_Date_for_SCs__c = system.today();
        mailerRec3.Publish_Date__c = system.now();
        mailerRec3.Reminder_Mail_sent_to_SC__c = true;
        mailerRec3.Reminder_Mail_sent_to_Managers__c = false;
        mailerRec3.Email_forwarded_to_Contacts_On__c = null;
        mailerRec3.Is_Master_Record__c = false;
		 insert mailerRec3;

    	ContentVersion content=new ContentVersion(); 
        content.Title='Header_Picture1'; 
        content.PathOnClient='/' + 'Title' + '.jpg'; 
        Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body'); 
        content.VersionData=bodyBlob; 
        //content.LinkedEntityId=sub.id;
        content.origin = 'H';
        insert content;
        ContentDocumentLink contentlink=new ContentDocumentLink();
        contentlink.LinkedEntityId=mailerRec2.id;
        contentlink.contentdocumentid=[select contentdocumentid from contentversion where id =: content.id].contentdocumentid;
        contentlink.ShareType = 'I';
        contentlink.Visibility = 'AllUsers'; 
        
        
        insert contentlink;        
        
       /* PS_Customer_Mailers__c mailerRec4 = new PS_Customer_Mailers__c();
        mailerRec3.Account__c = accList[0].Id;
        mailerRec3.Parent_PS_Customer_Mailer__c = mailerRec1.Id;
        mailerRec3.Audience_Type__c = 'Internal';
        mailerRec3.Instructions__c = 'Sample Instruction';
        mailerRec3.Product_Name__c = 'PLX';
        mailerRec3.PS_Customer_Mailer_Name__c = 'Mailer Rec 3';
        mailerRec3.Subject__c = 'Test Subject 1';
        mailerRec3.Content__c = 'Test Content';
        mailerRec3.RecordTypeId = Schema.SObjectType.PS_Customer_Mailers__c.getRecordTypeInfosByName().get('Security Bulletin').getRecordTypeId();
        mailerRec3.Team_Member_Id__c = UserInfo.getUserId();
        mailerRec3.Manager_Id__c = UserInfo.getUserId();
        mailerRec3.Reminder_Date_for_Managers__c= system.today();
        mailerRec3.Reminder_Date_for_SCs__c = system.today();
        mailerRec3.Publish_Date__c = system.now();
        mailerRec3.Reminder_Mail_sent_to_SC__c = true;
        mailerRec3.Reminder_Mail_sent_to_Managers__c = false;
        mailerRec3.Email_forwarded_to_Contacts_On__c = null;
        mailerRec3.Is_Master_Record__c = false;*/

       

        


        
        // Creating Contract
       /* Merge_Contract_Header__c newHeader = new Merge_Contract_Header__c();
        newHeader.Original_Contract_Id__c = 'ABC';
        newHeader.Name = 'ABC';
        newHeader.Account_Name__c = accList[0].Id; 
        newHeader.CI_Account_Name__c = 'Test Account IP Addr';*/
        Merge_Contract_Header__c merge_contract = new Merge_Contract_Header__c();
            merge_contract.Name                       ='2Test Merge Contract-19';
            merge_contract.Contract_Id__c             ='2Test-123-19';
            merge_contract.Original_Contract_Id__c    ='2Test-123-19';
            merge_contract.Account_Name__c            = accList[0].Id;
        	merge_contract.CI_Account_Name__c 		  = a1.Akam_Account_Id__c;
            merge_contract.Locked__c                  = true;
            merge_contract.Cancellation_Date__c       = Null;
            merge_contract.Contract_Transferred_To__c = Null;
            merge_contract.Is_COB_Created__c          = False;
            merge_contract.Effective_Start_Date__c    = system.Today().addDays(-14);
            merge_contract.Effective_End_Date__c      = system.Today().addDays(2);
            merge_contract.AKAM_Created_Date__c       = system.Today();
            merge_contract.Active__c                  = true;
      
           // insert merge_contract;
        contractList.add(merge_contract);
        insert contractList;
        
        Merge_Contract_Header__c newHeader1 = [Select Id,Original_Contract_Id__c,Name,Account_Name__c,Account_Name__r.Name,Account_Name__r.Type from Merge_Contract_Header__c limit 1];
        System.debug('newHeader**'+newHeader1.Original_Contract_Id__c+'**'+newHeader1.Name+'**'+newHeader1.Account_Name__c);
        System.debug('newHeader**'+newHeader1.Account_Name__r.Name);
        System.debug('newHeader**'+newHeader1.Account_Name__r.Type);
        
        Merge_Contract_Detail__c contractDetail = new Merge_Contract_Detail__c();
        //contractDetail.Product_Id__c = productId;
        contractDetail.Effective_Start_Date__c = System.Today();
        contractDetail.Effective_End_Date__c = System.Today().addMonths(6);
        //contractDetail.Unit_of_Measure__c = ;
        //contractDetail.Billing_Duration__c = billingDuration;
        contractDetail.Record_Type__c = 'Committed';
        contractDetail.AKAM_Created_Date__c = System.now();
        contractDetail.Original_Detail_Id__c  = 'U-123';    
        contractDetail.Original_Contract_Id__c = contractList[0].Id;
        insert contractDetail;
        Merge_Contract_Detail__c cdetail = [Select Id,Original_Detail_Id__c,Original_Contract_Id__c from Merge_Contract_Detail__c];
        System.debug('Contract detail**'+cdetail.Original_Detail_Id__c+'***'+cdetail.Original_Contract_Id__c);
        
        
        // Creating ACHD recs
        Autogen_Contract_Header_Detail__c achd1 = new Autogen_Contract_Header_Detail__c();
        achd1.recordTypeId = Schema.SObjectType.Autogen_Contract_Header_Detail__c.getRecordTypeInfosByName().get('Line').getRecordTypeId();
        achd1.Effective_End_Date__c = Date.newInstance(2050, 12, 9);
        achd1.Marketing_Product_Name__c = 'Managed Security Services - New';
        achd1.Parent_Contract_Header__c = contractList[0].Id;
        achd1.Original_Detail_ID__c = 'U-123';
        achdList.add(achd1);
        insert achdList;
        Autogen_Contract_Header_Detail__c achd2 = [Select Id,Original_Detail_ID__c,recordType.Name,Effective_End_Date__c,Parent_Contract_Header__c,Parent_Contract_Header__r.Account_Name__c,Parent_Contract_Header__r.Account_Name__r.Type,Parent_Contract_Header__r.Account_Name__r.Vertical__c from Autogen_Contract_Header_Detail__c limit 1];
        System.debug('1****'+achd2.recordType.Name+'***'+achd2.Original_Detail_ID__c);
        System.debug('1***'+achd2.Effective_End_Date__c);
        System.debug('1***'+achd2.Parent_Contract_Header__c+'**'+achd2.Parent_Contract_Header__r.Account_Name__c);
       // System.debug('2****'+achd1.Parent_Contract_Header__r.Account_Name__c);
        System.debug('3****'+achd2.Parent_Contract_Header__r.Account_Name__r.Type);
        System.debug('4****'+achd2.Parent_Contract_Header__r.Account_Name__r.Vertical__c);
        

        
        
    }
    
    @isTest
    static void TestSC_PSAutomationController()
    {
        atmList = [Select Id, UserId from AccountTeamMember];
        system.debug('++_+_+_+_+_+ '+atmList);
        accList = [Select Id,Name from Account];
        customerMailerList = [Select Id,recordTypeId,PS_Customer_Mailer_Name__c,Account__c,Instructions__c,Subject__c,Content__c from PS_Customer_Mailers__c];
        System.runAs(crmopsUser){
            SC_PSAutomationController.getDLList('External',customerMailerList[1].Id);
            SC_PSAutomationController.getDLList('Internal',null);
            SC_PSAutomationController.getMappedAccounts(new List<String>{'Managed Kona','MSS','PLX'});
            
            SC_PSAutomationController.EmailWrapper emailWrapperInstance= new SC_PSAutomationController.EmailWrapper();
            emailWrapperInstance.body = '123';
            emailWrapperInstance.toAddress = new List<String>{'test2@example.com'};
            emailWrapperInstance.ccAddress = new List<String>{'test@example.com'};
            emailWrapperInstance.dlList =  new List<String>{'test1@example.com'};
            emailWrapperInstance.files = null;
            emailWrapperInstance.Instruction = 'test Instruction';
            emailWrapperInstance.subject = 'test Sub';
            
          
            
            List<SC_PSAutomationController.targetAccountWrapperClass> targetAccountWrapperRecList = new List<SC_PSAutomationController.targetAccountWrapperClass>();
            SC_PSAutomationController.targetAccountWrapperClass targetAccountWrapperRec= new SC_PSAutomationController.targetAccountWrapperClass();
            targetAccountWrapperRec.colour = 'black';
            targetAccountWrapperRec.Geography = 'EMEA';
            targetAccountWrapperRec.Id = accList[0].Id;
            targetAccountWrapperRec.Name = accList[0].Name;
            targetAccountWrapperRec.ownerId = UserInfo.getUserID(); //This line modified by Ashin. (Changed ownerEmail to ownerId)
            targetAccountWrapperRec.Product = 'Test Prod';
            targetAccountWrapperRec.TeamMember = '1234';
            
            Map<String,AccountTeamMember> sampleMap = new Map<String,AccountTeamMember>(); //This line modified by Ashin. 
            string userid = UserInfo.getUserID(); //This line modified by Ashin. Here instead of email, we are storing the actual userid
            sampleMap.put('Test',atmList[0]); //This line modified by Ashin
            targetAccountWrapperRec.TeamMemberMap = sampleMap;
            targetAccountWrapperRecList.add(targetAccountWrapperRec);
            
         //Below Added by Ashin to increase coverage for SC_PSAutomationController_BatchJob. These lines added to testing scenario where SSP is missing
            SC_PSAutomationController.targetAccountWrapperClass targetAccountWrapperRec1= new SC_PSAutomationController.targetAccountWrapperClass();
            targetAccountWrapperRec1.colour = 'black';
            targetAccountWrapperRec1.Geography = 'EMEA';
            targetAccountWrapperRec1.Id = accList[0].Id;
            targetAccountWrapperRec1.Name = accList[0].Name;
            targetAccountWrapperRec1.ownerId = UserInfo.getUserID();
            targetAccountWrapperRec1.Product = 'Test Prod';
            targetAccountWrapperRec1.TeamMember = '';
            
            Map<String,AccountTeamMember> sampleMap1 = new Map<String,AccountTeamMember>();
            string userid1 = UserInfo.getUserID();
            sampleMap.put(userid1,atmList[0]);
            targetAccountWrapperRec1.TeamMemberMap = sampleMap1;
            List<SC_PSAutomationController.targetAccountWrapperClass> targetAccountWrapperRecList1 = new List<SC_PSAutomationController.targetAccountWrapperClass>();
			targetAccountWrapperRecList1.add(targetAccountWrapperRec1);
        //Above Added by Ashin to increase coverage for SC_PSAutomationController_BatchJob. These lines added to testing scenario where SSP is missing
            
            SC_PSAutomationController.createRecords(JSON.serialize(emailWrapperInstance), 'Mailer Name', 'Test Instruction',JSON.serialize(targetAccountWrapperRecList) , 'Internal', new List<String>{'MSS','PLX'}, null , true);
            SC_PSAutomationController.sendEmailControllerForMailer(JSON.serialize(emailWrapperInstance), customerMailerList[0].Id, null, JSON.serialize(targetAccountWrapperRecList));
            SC_PSAutomationController.sendEmailForMissingTeamMember(JSON.serialize(targetAccountWrapperRecList1));
            SC_PSAutomationController.validateToPublishMasterMailer(customerMailerList[0].Id);
            SC_PSAutomationController.publishMasterMailer(customerMailerList[0].Id);
        }     
        
        
    }    
    
    @isTest
    static void TestSC_PSAutomationControllerForSC(){
        
        customerMailerList = [Select Id,recordTypeId,PS_Customer_Mailer_Name__c,Account__c,Instructions__c,Subject__c,Content__c from PS_Customer_Mailers__c];
		System.runAs(crmopsUser){	
        	SC_PSAutomationControllerForSC.getExternalMailInitDetail(customerMailerList[1].Id);
        	SC_PSAutomationControllerForSC.validateUser(customerMailerList[1].Id);
        	SC_PSAutomationControllerForSC.sendEmailControllerForSC('test Subject','test Body',customerMailerList[1].Id,null);
        }
    }
    
     @isTest
    static void TestSC_PS_CustomerMailerTrigger(){
        customerMailerList = [Select Id,Publish_Date__c,Is_Master_Record__c,recordTypeId,PS_Customer_Mailer_Name__c,Account__c,Instructions__c,Subject__c,Content__c from PS_Customer_Mailers__c WHERE PS_Customer_Mailer_Name__c = 'Mailer Rec 3'];
        System.runAs(crmopsUser){
            //Below lines 327-330, commented by Ashin
            /*customerMailerList[1].Reminder_Mail_sent_to_SC__c = true;
               update customerMailerList[1];
               customerMailerList[1].Reminder_Mail_sent_to_Managers__c = true;
               update customerMailerList[1];*/
            try{
                delete customerMailerList;
                
            }catch(Exception e)
            {
            String message = e.getMessage();
             system.assertEquals(message.contains('Child Customer Mailer Records can not be deleted.'),true);
    		
            } 
        }    
    } 
    

    // Below method added by Ashin to test SC_PSReminderEmailsForManager_Batch.  ESESP:- 7097
     @isTest
    static void Test_SC_PSReminderEmailsForManager_Batch()
    {
        //I'm crteating 2 users below, because - initially the team_memebr_Id and manager_id was userinfo.getUserID which would be CRM Ops user. And CRM Ops user dosent have a manager, so I'm changing the id's
        User u1 = utilTestClass.CreateUser('Test1','Worldwide','Engineering');
        insert u1;
        User u2 = utilTestClass.CreateUser('Test2','Worldwide','Engineering');
        u2.ManagerId = u1.id;
        insert u2;
       
        System.runAs(crmopsUser)
        {
        PS_Customer_Mailers__c dmailer = [Select Id,Publish_Date__c,Reminder_Mail_sent_to_Managers__c,Reminder_Mail_sent_to_SC__c,recordTypeId,PS_Customer_Mailer_Name__c,Account__c,Instructions__c,Subject__c,Content__c, Manager_Id__c, Team_Member_Id__c, Reminder_Date_for_Managers__c from PS_Customer_Mailers__c where  PS_Customer_Mailer_Name__c ='Mailer Rec 3' ];
        Datetime LastModifiedDateTime = dmailer.Publish_Date__c;  
        Date ModifiedDate = LastModifiedDateTime.Date();
        dmailer.Reminder_Date_for_Managers__c = ModifiedDate;
        dmailer.Manager_Id__c=u1.id;
        dmailer.Team_Member_Id__c=u2.id;
        update dmailer;
            
        Test.startTest();

		SC_PSReminderEmailsForManager_Batch b= new SC_PSReminderEmailsForManager_Batch();
		SchedulableContext sc = null;
		b.execute(sc);

        Test.stopTest();
        }
    }
    // Above method added by Ashin to test SC_PSReminderEmailsForManager_Batch.  ESESP:- 7097

    // Below method added by Ashin to test SC_PSReminderEmailsForSc_Batch.  ESESP:- 7097
    @isTest
    static void Test_SC_PSReminderEmailsForSc_Batch()
    {

        System.runAs(crmopsUser)
        {
        PS_Customer_Mailers__c dmailer = [Select Id,Publish_Date__c,Reminder_Mail_sent_to_Managers__c,Reminder_Mail_sent_to_SC__c,recordTypeId,PS_Customer_Mailer_Name__c,Account__c,Instructions__c,Subject__c,Content__c, Manager_Id__c, Team_Member_Id__c, Reminder_Date_for_Managers__c from PS_Customer_Mailers__c where  PS_Customer_Mailer_Name__c ='Mailer Rec 3' ];
        Datetime LastModifiedDateTime = dmailer.Publish_Date__c;  
        Date ModifiedDate = LastModifiedDateTime.Date();
        dmailer.Reminder_Date_for_SCs__c = ModifiedDate;
        dmailer.Reminder_Mail_sent_to_SC__c = false;
        dmailer.Reminder_Mail_sent_to_Managers__c = false;
        update dmailer;
            
        Test.startTest();

		SC_PSReminderEmailsForSc_Batch b= new SC_PSReminderEmailsForSc_Batch();
		SchedulableContext sc = null;
		b.execute(sc);

        Test.stopTest();
        }
        
    }
     // Above method added by Ashin to test SC_PSReminderEmailsForSc_Batch.  ESESP:- 7097
      
      @isTest
    static void Test_SC_PSAutomationMultipleAccount()
    {
       	customerMailerList = [Select Id,recordTypeId,PS_Customer_Mailer_Name__c,Account__c,Instructions__c,Subject__c,Content__c from PS_Customer_Mailers__c];
        accList = [Select Id,Name from Account];
        String JSON_ID = '["'+customerMailerList[1].Id+'"]';
        
        Test.startTest();
        	SC_PSAutomationMultipleAccount.getTargetListViewId();
        	SC_PSAutomationMultipleAccount.getInitData();
        	SC_PSAutomationMultipleAccount.createDLRec('/'+accList[1].Id,'test DL','testDL@example.com');
        	//SC_PSAutomationMultipleAccount.massEmailToCustomers('\'["'+customerMailerList[0].Id+'"]\'');
        	System.debug('String is :'+JSON_ID);
        SC_PSAutomationMultipleAccount.massEmailToCustomers(JSON_ID);
        Test.stopTest();
    }
    
          @isTest
    static void Test_SC_PSAutomationMassDisableController(){
        customerMailerList = [Select Id,recordTypeId,PS_Customer_Mailer_Name__c,Account__c,Instructions__c,Subject__c,Content__c from PS_Customer_Mailers__c];
        accList = [Select Id,Name from Account];
        List<SC_PSAutomationMassDisableController.ToBeDisableMailerWrapper> inputList = new List<SC_PSAutomationMassDisableController.ToBeDisableMailerWrapper>();
        SC_PSAutomationMassDisableController.ToBeDisableMailerWrapper sampleInput =  new SC_PSAutomationMassDisableController.ToBeDisableMailerWrapper();
        sampleInput.Id = String.valueOf(customerMailerList[1].Id);
        sampleInput.Reason = 'Sample Reason';
        inputList.add(sampleInput);
        Test.startTest();
        	SC_PSAutomationMassDisableController.getTargetListViewId();
        	SC_PSAutomationMassDisableController.getInitData();
        	SC_PSAutomationMassDisableController.massDisable(JSON.serialize(inputList));
        SC_PSAutomationMassDisableController.enableMailerRecord(String.valueOf(customerMailerList[1].Id));
        SC_PSAutomationMassDisableController.disableMailerRecord(String.valueOf(customerMailerList[1].Id),'Test');
        SC_PSAutomationMassDisableController.getRecDetail(String.valueOf(customerMailerList[1].Id));
        Test.stopTest();
        
        
    }

        @isTest
    static void Test_SC_PSMassMailerListViewVFController(){
         customerMailerList = [Select Id,recordTypeId,PS_Customer_Mailer_Name__c,Account__c,Instructions__c,Subject__c,Content__c from PS_Customer_Mailers__c];
        Test.startTest();
       	Test.setCurrentPage(Page.SC_PSMassMailerListViewVF);
        
        ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(customerMailerList);
        stdSetController.setSelected(customerMailerList);
        SC_PSMassMailerListViewVFController obj = new SC_PSMassMailerListViewVFController(stdSetController); 
        obj.isValidListView = true;
        obj.redirectOnValidListView();
        obj.redirectOnValidListViewForDisable();
        Test.stopTest();
        
        
    }

    
    
    
    

    
    

}