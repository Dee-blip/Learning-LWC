@isTest(seeAllData=false)
public class L2Q_TaskTriggerClassTest {
    private static Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
    
    //static User
    static User dmlUser = utilTestClass.getTestRunUser();
    
    // Setup method to create test data.
    @testSetup
    static void setupMethod() {
        System.runAs(dmlUser) {
            
            ManagedPkgErrorClass.isFromManagedPackage = false;
            
            /* Start Of Custom Setting Insertion */
            Test.loadData(globalDescribe.get('Communities_Settings__c'), 'CS_Communities_Settings');
            Test.loadData(globalDescribe.get('PRM_Settings__c'), 'CS_PRM_Settings');
            Test.loadData(globalDescribe.get('Environment_Setup__c'), 'CS_Environment_Setup');
            Test.loadData(globalDescribe.get('Q2O_Custom_Settings__c'), 'Q2O_Custom_Settings');
            /* End Of Custom Setting Insertion */
            
            User accOwnerUser = utilTestClass.CreateUser('newUser', GsmUtilClass.getGSMSettingValue('User_Role'), 'Sales Operations');
            insert accOwnerUser;

            Account_Reassignment_Rule__c rule = utilTestClass.CreateAccountReassignmentRule('__Test Rule', accOwnerUser.Id, GsmUtilClass.getGSMSettingValue('User_Role'));
            insert rule; 
            
            //Account Creation
            List<Account> accList = new List<Account>();
            Account acc = utilTestClass.CreateAccount('__Test Account');
            acc.Vertical__c = 'Gaming'; 
            acc.Sub_Vertical__c = 'Console Mfs';
            accList.add(acc);
            
            Account acc1 = utilTestClass.CreateAccount('__Test Account With Division And Area');
            acc1.Vertical__c = 'Gaming';
            acc1.TERR_HIER_2__c = 'A';
            acc1.TERR_HIER_5__c = 'B'; 
            acc1.OwnerId = accOwnerUser.Id;
            acc1.BillingCountry = 'USA';
            acc1.BillingPostalCode ='87967';
            acc1.BillingState = 'CA';
            accList.add(acc1);
            
            Account acc2 = utilTestClass.CreateAccount('__Test Account Credit Check');
            acc2.Vertical__c = 'Gaming';
            acc2.Sub_Vertical__c = 'Console Mfs';   
            acc2.taskCreatedForCreditCheck__c = true;
            accList.add(acc2);
            
            Account acc3 = utilTestClass.CreateAccount('__Test Account Credit Check 1');
            acc3.Vertical__c = 'Gaming';
            acc3.Sub_Vertical__c = 'Console Mfs';   
            acc3.taskCreatedForCreditCheck__c = true;
            accList.add(acc3);
            insert accList;
            
            //Contact Creation
            List<Contact> conList = new List<Contact>();
            Contact con = utilTestClass.CreateContact('__ Test First','__Test Contact 1');
            con.AccountId = acc.Id;
            conList.add(con);
            Contact con2 = utilTestClass.CreateContact('__ Test First','__Test Contact 2');
            con2.AccountId = acc.Id;                            
            conList.add(con2);
            insert conList;
            
            //Opportunity Creation
            List<Opportunity> oppList = new List<Opportunity>();
            Opportunity opp = utilTestClass.CreateOpportunity('__Test Oppty','1-Create');
            opp.AccountId = acc1.Id;
            opp.Opportunity_Leader__c = acc1.OwnerId;
            opp.Owner__c = acc1.OwnerId;
            opp.CloseDate = Date.today().addDays(30);   
            oppList.add(opp);   
            
            Opportunity opp1 = utilTestClass.CreateOpportunity('__Test Oppty 1','1-Create');
            opp1.AccountId = acc1.Id;
            opp1.CloseDate = Date.today().addDays(30);  
            oppList.add(opp1);  
            insert oppList;
            
            //Lead Creation
            Lead lead = utilTestClass.CreateLead();
            lead.Status = 'Qualifying';
            lead.LeadSource ='Live Chat';
            lead.How_did_you_hear_about_Akamai__c = 'Through good unit tests';
            lead.Associated_Contact__c = con.Id;    
            lead.Disposition__c='Existing Customer';
            lead.Product_line__c='Aura';
            lead.Company = 'Akamai';
            lead.LastName = 'iAMlead';
            lead.email='test21@test.com';
            insert lead; 
            
            //Campaign Creation
            List<Campaign> campaignList = new List<Campaign>();
            Campaign cmpgn1 = new Campaign();
            cmpgn1.Name = '__Test Campaign1';
            campaignList.add(cmpgn1);
            Campaign cmpgn2 = new Campaign();
            cmpgn2.Name = '__Test Campaign2';
            campaignList.add(cmpgn2);
            insert campaignList;
        }
    }
    
    @isTest
    public static void stampTQLSLACounterValue() {
        /*System.runAs(dmlUser)
        {
            Opportunity opp = [select Id from Opportunity where Name = '__Test Oppty' limit 1][0]; 
            //Set the opportunity record type as AWE record type and stamp N3_TQL_Date__c
            Id aweOppRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('AWE Opportunities').getRecordTypeId();
            try {
                Opportunity oppp = new Opportunity(id=opp.id,
                                                   recordTypeId=aweOppRecordTypeId,
                                                   N3_TQL_Date__c = Datetime.now());
                upsert oppp;
            } catch (Exception e) {
                System.debug(e.getMessage());
            }
            //Create Task
            Task tsk = new Task();
            tsk.whatid = opp.id;
            tsk.Subject = '__Test Subject';
            insert tsk; 
            
            Opportunity oppAfterTask = [Select id, TQL_SLA_End_Date__c, TQL_SLA_Activity_Counter__c 
                                        From Opportunity where id =:opp.id];
            //System.assertEquals(1, oppAfterTask.TQL_SLA_Activity_Counter__c);

        }*/
        L2Q_TaskTriggerClass.stampTQLSLACounterValue(null);
    }

    static testmethod void SingleTask_PositiveTest()
    {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        Lead lead = [select Id from Lead limit 1][0];
        Campaign cmpgn = [select Id from Campaign where Name = '__Test Campaign1' limit 1][0];
        Contact con = [select Id from Contact where LastName = '__Test Contact 1' limit 1][0];
        CampaignMember cmpgn_member1 = utilTestClass.CreateCampaignMember(lead.Id, cmpgn.Id);
        cmpgn_member1.ContactId = con.Id;
        insert cmpgn_member1;
        Test.startTest();
        Task tsk = new Task();
        tsk.WhoId = lead.Id;
        tsk.Subject = '__Test Subject';
        TaskTriggerClass.regularIdsMapFirstRunFlag = true;
        insert tsk;
        Test.stopTest();
        /*Refresh Account, Contact, Campaign and Task Objects*/
        Account acc = [select Id,Name,TERR_HIER_2__c,TERR_HIER_5__c,AKAM_Account_ID__c,OD_Account_ROW_ID__c,taskCreatedForCreditCheck__c from Account where Name = '__Test Account' limit 1][0];
        con = RefreshContact(con.Id);
        cmpgn = RefreshCampaign(cmpgn.Id);
        tsk = RefreshTask(tsk.Id);
        system.assertEquals(tsk.WhoId,lead.Id);
        system.assertEquals(tsk.Associated_AKAM_Contact_ID__c,con.AKAM_Contact_ID__c);
        system.assertEquals(tsk.whatID,null);
        system.assertEquals(tsk.Associated_AKAM_Account_ID__c,acc.AKAM_Account_ID__c);
        system.assertEquals(tsk.Associated_AKAM_Campaign_ID__c,cmpgn.AKAM_Campaign_ID__c);
    }

    /**
       OldestCampaign_PositiveTest()
       - Test if Oldest Campaign is selected.
    */
    static testmethod void OldestCampaign_PositiveTest()
    {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        Lead lead = [select Id from Lead limit 1][0];
        Campaign cmpgn1,cmpgn2;
        List<String> campaignNameList = new List<String>{'__Test Campaign1','__Test Campaign2'};
            for(Campaign c : [select Id, Name from Campaign where Name IN: campaignNameList]){
                if(c.Name == '__Test Campaign1')
                    cmpgn1 = c;
                else
                    cmpgn2 = c;
            }
        Contact con = [select Id from Contact where LastName = '__Test Contact 1' limit 1][0];
        List<CampaignMember> cmList = new List<CampaignMember>();
        CampaignMember cmpgn_member1 = utilTestClass.CreateCampaignMember(lead.Id, cmpgn1.Id);
        cmpgn_member1.ContactId = con.Id;
        cmList.add(cmpgn_member1);
        CampaignMember cmpgn_member2 = utilTestClass.CreateCampaignMember(lead.Id, cmpgn2.Id);
        cmpgn_member2.ContactId = con.Id;
        cmList.add(cmpgn_member2);
        insert cmList;
        
        Test.startTest();
        Task tsk = new Task();
        tsk.WhoId = lead.Id;
        tsk.Subject = '__Test Subject';
        TaskTriggerClass.regularIdsMapFirstRunFlag = true;      
        insert tsk;
        /*Refresh Account, Contact, Campaign and Task Objects*/
        Account acc = [select Id,Name,TERR_HIER_2__c,TERR_HIER_5__c,AKAM_Account_ID__c,OD_Account_ROW_ID__c,taskCreatedForCreditCheck__c from Account where Name = '__Test Account' limit 1][0];
        con = RefreshContact(con.Id);
        cmpgn1 = RefreshCampaign(cmpgn1.Id);
        cmpgn2 = RefreshCampaign(cmpgn2.Id);
        tsk = RefreshTask(tsk.Id);
        Test.stopTest();
        system.assertEquals(tsk.WhoId,lead.Id);
        system.assertEquals(tsk.Associated_AKAM_Contact_ID__c,con.AKAM_Contact_ID__c);
        system.assertEquals(tsk.whatID,null);
        system.assertEquals(tsk.Associated_AKAM_Account_ID__c,acc.AKAM_Account_ID__c);
        system.assert((tsk.Associated_AKAM_Campaign_ID__c == cmpgn1.AKAM_Campaign_ID__c) || (tsk.Associated_AKAM_Campaign_ID__c == cmpgn2.AKAM_Campaign_ID__c));
    }

    /**
       NoCampaign_PositiveTest()
       - Test with no Associated Campaign.
    */
    static testmethod void NoCampaign_PositiveTest()
    {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        Lead lead = [select Id from Lead limit 1][0];
        
        Test.startTest();
        Task tsk = new Task();
        tsk.WhoId = lead.Id;
        tsk.Subject = '__Test Subject';
        TaskTriggerClass.regularIdsMapFirstRunFlag = true;  
        insert tsk;
        Test.stopTest();
        
        /*Refresh Account, Contact, Campaign and Task Objects*/
        Account acc = [select Id,Name,TERR_HIER_2__c,TERR_HIER_5__c,AKAM_Account_ID__c,OD_Account_ROW_ID__c,taskCreatedForCreditCheck__c from Account where Name = '__Test Account' limit 1][0];
        Contact con = [select Id, AKAM_Contact_ID__c, OD_Contact_ROW_ID__c from Contact where LastName = '__Test Contact 1' limit 1][0];
        tsk = RefreshTask(tsk.Id);
        system.assertEquals(tsk.WhoId,lead.Id);
        system.assertEquals(tsk.Associated_AKAM_Contact_ID__c,con.AKAM_Contact_ID__c);
        system.assertEquals(tsk.whatID,null);
        system.assertEquals(tsk.Associated_AKAM_Account_ID__c,acc.AKAM_Account_ID__c);
        system.assertEquals(tsk.Associated_AKAM_Campaign_ID__c,null);
    }

    /**
       BulkTask_PositiveTest()
       - Bulk tasks update 
    */
    static testmethod void BulkTask_PositiveTest()
    {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        Lead lead = [select Id from Lead limit 1][0];
        Campaign cmpgn = [select Id from Campaign where Name = '__Test Campaign1' limit 1][0];
        Contact con = [select Id from Contact where LastName = '__Test Contact 1' limit 1][0];
        CampaignMember cmpgn_member1 = utilTestClass.CreateCampaignMember(lead.Id, cmpgn.Id);
        cmpgn_member1.ContactId = con.Id;
        insert cmpgn_member1;
        //Bulk Tasks
        Task[] BulkTasks = new Task[200];
        Integer i;
        for(i=0;i<200;i++)
        {
            BulkTasks[i] = new Task();
            BulkTasks[i].WhoId = lead.Id;
            BulkTasks[i].Subject = '__Test Subject ' + i;
        }
        Test.startTest();
        TaskTriggerClass.regularIdsMapFirstRunFlag = true;  
        insert BulkTasks;
        Test.stopTest();
        
        /*Refresh Account, Contact, Campaign and Task Objects*/
        Account acc = [select Id,Name,TERR_HIER_2__c,TERR_HIER_5__c,AKAM_Account_ID__c,OD_Account_ROW_ID__c,taskCreatedForCreditCheck__c from Account where Name = '__Test Account' limit 1][0];
        con = RefreshContact(con.Id);
        cmpgn = RefreshCampaign(cmpgn.Id);
        BulkTasks = [select Id,WhoId,Associated_AKAM_Contact_ID__c,whatID,Associated_AKAM_Account_ID__c,Associated_AKAM_Campaign_ID__c from Task where Id IN :BulkTasks];
        for(i=0;i<200;i++)
        {
            system.assertEquals(BulkTasks[i].WhoId,lead.Id);
            system.assertEquals(BulkTasks[i].Associated_AKAM_Contact_ID__c,con.AKAM_Contact_ID__c);
            system.assertEquals(BulkTasks[i].whatID,null);
            system.assertEquals(BulkTasks[i].Associated_AKAM_Account_ID__c,acc.AKAM_Account_ID__c);
            system.assertEquals(BulkTasks[i].Associated_AKAM_Campaign_ID__c,cmpgn.AKAM_Campaign_ID__c);
        }
    }

    /**
       WhatIdNull_PositiveTest()
       - Use case where WhatId is null and WhoId is a Contact.
    */
    static testmethod void WhatIdNull_PositiveTest()
    {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        Contact con = [select Id from Contact where LastName = '__Test Contact 1' limit 1][0];
        
        Test.startTest();
        Task tsk = new Task();
        tsk.WhoId = con.Id;
        tsk.Subject = '__Test Subject';
        insert tsk; 
        Test.stopTest();
        
        /*Refresh Account, Contact and Task Objects*/
        Account acc = [select Id,Name,TERR_HIER_2__c,TERR_HIER_5__c,AKAM_Account_ID__c,OD_Account_ROW_ID__c,taskCreatedForCreditCheck__c from Account where Name = '__Test Account' limit 1][0];
        con = RefreshContact(con.Id);
        tsk = RefreshTask(tsk.Id);
        system.assertEquals(tsk.whatId,acc.Id);
        system.assertEquals(tsk.Associated_AKAM_Contact_ID__c,con.AKAM_Contact_ID__c);
    }

    static testmethod void UpdateAssocFieldsTest_Account()
    {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        Account acc = [select Id from Account where Name = '__Test Account With Division And Area' limit 1][0];
        
        Test.startTest();
        // Create Task
        Task tsk = new Task();
        tsk.WhatId = acc.Id;
        tsk.Subject = '__Test Subject';
        insert tsk; 
        Test.stopTest();
        
        /*Refresh Account and Task Objects*/
        acc = RefreshAccount(acc.Id);
        tsk =RefreshTask(tsk.Id);
        system.assertEquals(tsk.Associated_Account__c, acc.Name);
        system.assertEquals(tsk.Account_Sales_Region__c, acc.TERR_HIER_2__c + ' ' + acc.TERR_HIER_5__c ); 
    }

    static testmethod void UpdateAssocFieldsTest_Opportunity()
    {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        Opportunity opp = [select Id, Name from Opportunity where Name = '__Test Oppty 1' limit 1][0];
        
        Test.startTest();
        // Create Task
        Task tsk = new Task();
        tsk.WhatId = opp.Id;
        tsk.Subject = '__Test Subject';
        insert tsk; 
        Test.stopTest();
        
        /*Refresh Account, Task Objects*/
        Account acc = [select Id,Name,TERR_HIER_2__c,TERR_HIER_5__c,AKAM_Account_ID__c,OD_Account_ROW_ID__c,taskCreatedForCreditCheck__c from Account where Name = '__Test Account With Division And Area' limit 1][0];
        tsk =RefreshTask(tsk.Id);
        system.assertEquals(tsk.Associated_Opportunity__c, opp.Name);
        system.assertEquals(tsk.Associated_Account__c, acc.Name);
        system.assert((tsk.Account_Sales_Region__c == acc.TERR_HIER_2__c + ' ' + acc.TERR_HIER_5__c )|| (tsk.Account_Sales_Region__c == acc.TERR_HIER_2__c));
    }

    static testmethod void UpdateAssocFieldsTest_OrderApproval()
    {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        Opportunity opp = [select Id, Name, RecordTypeId, StageName from Opportunity where Name = '__Test Oppty 1' limit 1][0];
        // Create Order Approval
        String returnMsg = OrderApprovalClass.Create_OrderApproval(opp.Id,opp.RecordTypeId+'',opp.StageName);
        system.assert(returnMsg.contains('1:'));
        // Get Order Approval
        Order_Approval__c oa = [select Id, 
                                Associated_Opportunity__c, 
                                RecordTypeId, 
                                Deal_Desk_Owner__c,
                                Legal_Owner__c, CCG__c, 
                                Deal_Desk__c, Legal__c 
                                from Order_Approval__c 
                                where Associated_Opportunity__c=:opp.Id][0];
        system.assertNotEquals(oa, null);   
        
        Test.startTest();
        // Create Task
        Task tsk = new Task();
        //SFDC-4326
        tsk.RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Order Approval Activity').getRecordTypeId();
        tsk.WhatId = oa.Id;
        tsk.Subject = '__Test Subject';
        insert tsk; 
        Test.stopTest();
        
        /*Refresh Account & Task*/
        Account acc = [select Id,Name,TERR_HIER_2__c,TERR_HIER_5__c,AKAM_Account_ID__c,OD_Account_ROW_ID__c,taskCreatedForCreditCheck__c from Account where Name = '__Test Account With Division And Area' limit 1][0];
        tsk = RefreshTask(tsk.Id);
        system.assertEquals(tsk.Associated_Opportunity__c, opp.Name);
        system.assertEquals(tsk.Associated_Account__c, acc.Name);
        system.assert((tsk.Account_Sales_Region__c == acc.TERR_HIER_2__c + ' ' + acc.TERR_HIER_5__c )|| (tsk.Account_Sales_Region__c == acc.TERR_HIER_2__c));
    }

    static testmethod void WhoIdUpdate_SingleTask_PositiveTest()
    {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        Lead lead = [select Id from Lead limit 1][0];
        Campaign cmpgn = [select Id from Campaign where Name = '__Test Campaign1' limit 1][0];
        Contact con2 = [select Id from Contact where LastName = '__Test Contact 2' limit 1][0];
        CampaignMember cmpgn_member1 = utilTestClass.CreateCampaignMember(lead.Id, cmpgn.Id);
        cmpgn_member1.ContactId = con2.Id;
        insert cmpgn_member1;
        Test.startTest();
        Task tsk = new Task();
        tsk.WhoId=lead.Id;
        tsk.Subject = '__Test Subject';
        insert tsk; 
        Test.stopTest();
        // PUT IN ASSERTS
    }

    static testmethod void WhoIdUpdate_BulkTask_PositiveTest()
    {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        Lead lead1 = [select Id from Lead limit 1][0];
        Campaign cmpgn = [select Id from Campaign where Name = '__Test Campaign1' limit 1][0];
        Contact con2 = [select Id from Contact where LastName = '__Test Contact 2' limit 1][0];
        CampaignMember cmpgn_member1 = utilTestClass.CreateCampaignMember(lead1.Id, cmpgn.Id);
        cmpgn_member1.ContactId = con2.Id;
        insert cmpgn_member1;
        Test.startTest();
        Integer i=0;
        Task[] BulkTasks = new Task[200];
        for(i=0;i<200;i++)
        {
            BulkTasks[i] = new Task();
            BulkTasks[i].WhoId=lead1.Id;
            BulkTasks[i].Subject = '__Test Subject ' + i;
        }
        insert BulkTasks;
        Test.stopTest();
        // PUT IN ASSERTS
    }

    //CR 3081361
    static testmethod void creditCheckFlagUpdate_SingleTask_PositiveTest()
    {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        Account acc = [select Id from Account where Name = '__Test Account Credit Check' limit 1][0];
        Test.startTest();
        Task tsk = new Task();
        tsk.whatId=acc.Id;
        tsk.Subject = 'Credit Check Needed';
        tsk.Status = 'In Progress';
        insert tsk;     
        tsk.Status = 'Completed';
        update tsk;
        Test.stopTest();
        Account refreshedAccount = RefreshAccount(acc.id);
        System.assertEquals(refreshedAccount.taskCreatedForCreditCheck__c, true);
    }

    static testmethod void creditCheckFlagUpdate_SingleTask_NegatieTest()
    {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        Account acc = [select Id from Account where Name = '__Test Account Credit Check' limit 1][0];
        Test.startTest();
        Task tsk = new Task();
        tsk.whatId=acc.Id;
        tsk.Subject = 'Send Letter';
        tsk.Status = 'In Progress';
        insert tsk;     
        tsk.Status = 'Completed';
        update tsk;
        Test.stopTest();
        Account refreshedAccount = RefreshAccount(acc.id);
        System.assertEquals(refreshedAccount.taskCreatedForCreditCheck__c,true);
    }

    static testmethod void creditCheckFlagUpdate_BulkTask_PositiveTest()
    {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        Account acc, acc1;
        List<string> accNameList = new List<string>{'__Test Account Credit Check', '__Test Account Credit Check 1'};
            for(Account a : [select Id, Name from Account where Name IN : accNameList]){
                if(a.Name == '__Test Account Credit Check')
                    acc = a;
                else
                    acc1 = a;
            }
        
        Test.startTest();
        Integer i=0;
        List<Task> BulkTasks = new List<Task>();
        for(i=0;i<100;i++)
        {
            Task tsk = new Task();
            tsk.whatId=acc.Id;
            tsk.Subject = 'Credit Check Needed';
            tsk.Status = 'In Progress';
            BulkTasks.add(tsk);
            Task tsk1 = new Task();
            tsk1.whatId=acc1.Id;
            tsk1.Subject = 'Credit Check Needed';
            tsk1.Status = 'In Progress';
            BulkTasks.add(tsk1);
        }
        insert BulkTasks;

        //BulkTasks = [Select id,Status from Task where ]
        for(Task tsk: BulkTasks){
            tsk.Status = 'Completed';
        }

        update BulkTasks;
        Test.stopTest();
        
        Account refreshedAccount = RefreshAccount(acc.id);
        Account refreshedAccount1 = RefreshAccount(acc1.id);
        System.assertEquals(refreshedAccount.taskCreatedForCreditCheck__c, true);
        System.assertEquals(refreshedAccount1.taskCreatedForCreditCheck__c, true);
    }

    //SFDC-2266
    static testmethod void cmgReviwTaskTest()
    {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        Opportunity opp = [select Id, StageName, OwnerId,CurrencyIsoCode from Opportunity where Name = '__Test Oppty' limit 1][0]; 
        Test.startTest();
        utilTestClass.insertOpptyProductForEach(new List<Opportunity>{opp},1,opp.CurrencyIsoCode);
        //move opportunity to SS 6
        opp.StageName = '6-Signed';
        opp.Validation_Override__c = true;
        update opp;
        //Contract entry task should have created
        Task tsk = [select id,Status,Subject,OwnerId from task where whatId=:opp.id and subject=:GsmUtilClass.getGSMSettingValue('OpptyTrigger_SS6TaskSubject')];
        System.assertNotEquals(tsk,null);
        tsk.Status = 'Completed';
        update tsk;
        try{
            //Contract Review task should have created
            Task rvwTsk = [select id,Status,Subject from task where whatId=:opp.id and subject=:GsmUtilClass.getGSMSettingValue('cmgReviewTaskSubject')];
            System.assertNotEquals(rvwTsk,null);
            //update review task to defrred
            rvwTsk.Status = 'Deferred';
            try{
                update rvwTsk;
            }catch(DmlException e){
                system.assert(e.getMessage().contains('Reason Code'));
            }
            rvwTsk.Reason_Code__c = 'Address Error';
            update rvwTsk;
            //Owner should have changed to 
            rvwTsk = [select id,Status,Subject,OwnerId from task where whatId=:opp.id and subject=:GsmUtilClass.getGSMSettingValue('cmgReviewTaskSubject')];
            System.assertEquals(rvwTsk.OwnerId,tsk.OwnerId);
            //SFDC-2704
            rvwTsk.Status = 'Completed';
            try{
                update rvwTsk;
            }catch(DmlException e){
                //system.assert(e.getMessage().contains(GsmUtilClass.getGSMSettingValue('TaskTriggerErrorMsg')));
            }
            Test.stopTest();
        }
        catch(Exception e){
            
        }
    }
    
    private static Account RefreshAccount(string acc)
    {
        return [select Id,Name,TERR_HIER_2__c,TERR_HIER_5__c,AKAM_Account_ID__c,OD_Account_ROW_ID__c,taskCreatedForCreditCheck__c from Account where Id=:acc];
    }
    //Create Campaign Refresh function
    private static Campaign RefreshCampaign(string camp)
    {
        return [select ID,AKAM_Campaign_ID__c from Campaign where Id=:camp];
    }
    //Create Contact Refresh function
    private static Contact RefreshContact(string con)
    {
        return [select Id,AKAM_Contact_ID__c,OD_Contact_ROW_ID__c from Contact where Id=:con][0];
    }
    //Create Task Refresh function
    private static Task RefreshTask(string tsk)
    {
        return [select Id,WhoId,Associated_Account__c,Associated_Opportunity__c,Account_Sales_Region__c,Associated_AKAM_Contact_ID__c,whatID,Associated_AKAM_Account_ID__c,Associated_AKAM_Campaign_ID__c from Task where Id=:tsk][0];
    }
}