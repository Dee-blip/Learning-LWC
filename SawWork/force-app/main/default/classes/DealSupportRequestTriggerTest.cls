/* Created By: Vivek Baidya
* Created Date: 18-May-2018
* Description: Test class for DealSupportRequestTriggerFramework. 
*/
@isTest(seeAllData=false)
private class DealSupportRequestTriggerTest {
    //static User
    static User dmlUser = utilTestClass.getTestRunUser();
    
    // Setup method to create test data.
    @testSetup
    static void setupMethod() {
        System.runAs(dmlUser) {
            //Account Creation
            Account acc = utilTestClass.CreateAccount('Test Account');
            acc.TERR_HIER_1__c = 'APJ';
            acc.TERR_HIER_2__c = 'APJ Adjust';
            acc.TERR_HIER_3__c = 'APJ Adjust';
            acc.TERR_HIER_4__c = 'APJ Adjust';
            acc.TERR_HIER_5__c = 'APJ Adjust';
            acc.Validation_Override__c = true;
            insert acc;

            Territory_Mapping__c tm = new Territory_Mapping__c();
            tm.name = 'APJ Adjust - APJ Adjust';
            tm.TERR_HIER_1__c = 'APJ';
            tm.TERR_HIER_2__c = 'APJ Adjust';
            tm.TERR_HIER_3__c = 'APJ Adjust';
            tm.TERR_HIER_4__c = 'APJ Adjust';
            tm.TERR_HIER_5__c = 'APJ Adjust';
            tm.Queue__c = 'Solution Engineer Queue';
            tm.Queue_DL__c = 'smore@akamai.com';
            tm.VSE_Queue__c ='VSE Queue';
            tm.VSE_Queue_DL__c ='swmahapa@akamai.com';
            //tm.WPA_Queue__c = 'WPA Queue';
            //tm.WPA_Queue_DL__c = 'smore@akamai.com';
            insert tm;

            List<DSR_Routing__c> dsrRoutingList = new List<DSR_Routing__c>();

            DSR_Routing__c dsrRouting = new DSR_Routing__c();
            dsrRouting.Territory_Mapping_Id__c = tm.id;
            dsrRouting.Request_Type__c = 'ETG Specialist';
            dsrRouting.Request_Sub_Type__c = 'Ad Hoc Support';
            dsrRouting.Product__c = 'API Gateway';
            dsrRouting.Queue__c = 'ETG Specialist Queue';
            dsrRouting.Queue_DL__c = 'smore@akamai.com.qa';
            dsrRoutingList.add(dsrRouting);

            DSR_Routing__c dsrRouting1 = new DSR_Routing__c();
            dsrRouting1.Territory_Mapping_Id__c = tm.id;
            dsrRouting1.Request_Type__c = 'Solution Engineer';
            dsrRouting1.Request_Sub_Type__c = 'Account Support';
            dsrRouting1.Product__c = 'Media';
            dsrRouting1.Queue__c = 'Solution Engineer Queue';
            dsrRouting1.Queue_DL__c = 'smore@akamai.com.qa';
            dsrRoutingList.add(dsrRouting1);

            DSR_Routing__c dsrRouting2 = new DSR_Routing__c();
            dsrRouting2.Territory_Mapping_Id__c = tm.id;
            dsrRouting2.Request_Type__c = 'VSE';
            dsrRouting2.Request_Sub_Type__c = 'null';
            dsrRouting2.Product__c = 'null';
            dsrRouting2.Queue__c = 'VSE Queue';
            dsrRouting2.Queue_DL__c = 'smore@akamai.com.qa';
            dsrRoutingList.add(dsrRouting2);

            insert dsrRoutingList;
            
            //Opportunity Creation
            Opportunity oppty = utilTestClass.CreateOpportunity('__Test Opportunity','1-Create');
            oppty.AccountId = acc.Id;
            oppty.CloseDate = Date.today().addMonths(4);
            insert oppty;
            
            //User Creation
            Profile p = [select Id from profile where name='Solutions Engineer' LIMIT 1][0];
            UserRole role = [select Id from UserRole where Name = 'Worldwide' LIMIT 1][0];
            List<User> userList = new List<User>();
            User seUser = new User(alias='newSE', email='newse@akamai.com',emailencodingkey='UTF-8', lastname='newSE', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__new_se@akamai.com',profileid = p.Id, UserRoleId = role.Id );
            userList.add(seUser);
            User managerSEUser = new User(alias='seMan', email='managerse@akamai.com',emailencodingkey='UTF-8', lastname='managerSE', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__manager_se@akamai.com',profileid = p.Id, UserRoleId = role.Id );
            userList.add(managerSEUser);
            insert userList;
            
            seUser.ManagerId = managerSEUser.Id;
            update seUser;
        }
    }
    
    @isTest static void testDealSupportRequestCreation(){
        User seUser = [select Id from User where alias = 'newSE' LIMIT 1][0];
        Opportunity oppty = [Select Id, AccountId from Opportunity where Name = '__Test Opportunity' Limit 1][0];
        //Territory_Mapping__c tm = [Select Id from Territory_Mapping__c where Name = 'Web Americas Channels - Web Americas Channels' Limit 1][0];
        system.runAs(seUser){
            Deal_Support_Request__c dsr = new Deal_Support_Request__c();
            dsr.Opportunity__c = oppty.Id;
            dsr.RecordTypeId = Schema.SObjectType.Deal_Support_Request__c.getRecordTypeInfosByDeveloperName().get('Pre_Sales_Engagement').getRecordTypeId();
            dsr.Request_Type__c = 'POC';
            dsr.POC_Status__c = 'Planned';
            dsr.Start_Date__c = System.today();
            dsr.End_Date__c = System.today() + 5;
            dsr.Contract_Type__c = 'Out Clause';
            dsr.Success_Criteria__c = 'Success';
            dsr.Product__c = 'Adaptive Media Delivery';
            
            Test.startTest();
            
            //Insert Deal_Support_Request__c
            insert dsr;
            
            //Update Deal_Support_Request__c
            dsr.POC_Status__c = 'In Progress';
            update dsr;
            
            //Update Deal_Support_Request__c
            dsr.POC_Status__c = 'Completed';
            
            update dsr;
            
            /*
            dsr.POC_Status__c = 'Completed'; 
            dsr.Request_Type__c  = 'Web VSE';
            dsr.Validation_Override__c = false;
            dsr.LOE__c  =4;
            dsr.RecordTypeId = Schema.SObjectType.Deal_Support_Request__c.getRecordTypeInfosByDeveloperName().get('Pre_Sales_Request').getRecordTypeId();
            ContentVersion contentVersion = new ContentVersion(
                Title = 'Penguins',
                PathOnClient = 'Penguins.jpg',
                VersionData = Blob.valueOf('Test Content'),
                IsMajorVersion = true
            );
            insert contentVersion;    
            List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
            
            //create ContentDocumentLink  record 
            ContentDocumentLink cdl = New ContentDocumentLink();
            cdl.LinkedEntityId = dsr.id;
            cdl.ContentDocumentId = documents[0].Id;
            cdl.shareType = 'V';
            insert cdl;
            update dsr;
            */

            Id preSalesRequestId = Schema.SObjectType.Deal_Support_Request__c.getRecordTypeInfosByDeveloperName().get('Pre_Sales_Request').getRecordTypeId();
            List<Deal_Support_Request__c> dsrList = new List<Deal_Support_Request__c>();

            Deal_Support_Request__c dsrWebvse = new Deal_Support_Request__c();
            dsrWebvse.Opportunity__c = oppty.Id;
            dsrWebvse.RecordTypeId = preSalesRequestId;
            dsrWebvse.Request_Type__c  = 'VSE';
            dsrWebvse.Validation_Override__c = true;
            dsrList.add(dsrWebvse);

           /* Deal_Support_Request__c dsrMTC = new Deal_Support_Request__c();
            dsrMTC.Opportunity__c = oppty.Id;
            dsrMTC.RecordTypeId = preSalesRequestId;
            dsrMTC.Request_Type__c  = 'VSE';
            dsrMTC.Validation_Override__c = true;
            dsrList.add(dsrMTC);*/
            
            Deal_Support_Request__c dsrSolutionEngineer = new Deal_Support_Request__c();
            dsrSolutionEngineer.Account__c = oppty.AccountId;
            dsrSolutionEngineer.Request_Type__c = 'Solution Engineer';
            dsrSolutionEngineer.Request_Sub_Type__c = 'Account Support';
            dsrSolutionEngineer.Product__c = 'Media';
            dsrSolutionEngineer.RecordTypeId = preSalesRequestId;
            dsrSolutionEngineer.Notes__c = 'Testing Data';
            dsrSolutionEngineer.Validation_Override__c = true;
            dsrList.add(dsrSolutionEngineer);

            Deal_Support_Request__c dsrSolutionEngineer2 = new Deal_Support_Request__c();
            dsrSolutionEngineer2.Account__c = oppty.AccountId;
            dsrSolutionEngineer2.Request_Type__c = 'Solution Engineer';
            dsrSolutionEngineer2.Request_Sub_Type__c = 'Account Support';
            dsrSolutionEngineer2.Product__c = 'Media';
            dsrSolutionEngineer2.RecordTypeId = preSalesRequestId;
            dsrSolutionEngineer2.Notes__c = 'Testing Data';
            dsrSolutionEngineer2.Validation_Override__c = true;
            dsrList.add(dsrSolutionEngineer2);

            Insert dsrList;

            DealSupportRequestTriggerClass.populatePrimarySE(dsrList);
            DealSupportRequestTriggerClass.changeStatustoInProgress(dsrList);

            dsrSolutionEngineer.POC_Status__c = 'In Progress';
            Update dsrSolutionEngineer;
            
            //Refresh Deal_Support_Request__c
            dsr = [Select Id, Age__c from Deal_Support_Request__c where Id =: dsr.Id];
           // system.assertEquals(dsr.Age__c, 5);
            Test.stopTest();
        }
        
        system.runAs(dmlUser){
            Deal_Support_Request__c dsr = [Select Id from Deal_Support_Request__c LIMIT 1];
            //Delete Deal_Support_Request__c
            ByPassAndLimitUtils.disable('DSRTrigger');
            delete dsr;
        }
    }

    static testmethod void testDSRPreSalesRequestType(){

        Id preSalesRequestId = Schema.SObjectType.Deal_Support_Request__c.getRecordTypeInfosByDeveloperName().get('Pre_Sales_Request').getRecordTypeId();
        Opportunity oppty = [Select Id, AccountId from Opportunity where Name = '__Test Opportunity' Limit 1][0];
        
        List<Deal_Support_Request__c> dsrList = new List<Deal_Support_Request__c>();

        Deal_Support_Request__c dsrWPA = new Deal_Support_Request__c();
        dsrWPA.Opportunity__c = oppty.Id;
        dsrWPA.Account__c = oppty.AccountId;
        dsrWPA.RecordTypeId = preSalesRequestId;
        dsrWPA.Request_Type__c  = 'ETG Specialist';
        dsrWPA.Request_Sub_Type__c  = 'Ad Hoc Support';
        dsrWPA.Product__c  = 'API Gateway';
        dsrWPA.Summary__c  = 'Test Data';
        dsrWPA.Notes__c  = 'Test Notes';
        dsrWPA.Validation_Override__c = true;

        Insert dsrWPA;

        User usr = [Select id from User where email = 'newse@akamai.com' limit 1];

        dsrWPA.SE__c = usr.id;
        update dsrWPA;

    }

    @isTest static void testDSRChimeProductApproval(){

        utilTestClass.createCustomSettings();
            CHIME_GSS_Settings__c sett = new CHIME_GSS_Settings__c ();
            sett.Name = 'TestSetting';
            sett.Question_Admin_Email__c = 'abc@test.com';
            insert sett;


        User seUser = [select Id from User where alias = 'newSE' LIMIT 1][0];
        system.runAs(seUser){
            
        Opportunity oppty = [Select Id, AccountId from Opportunity where Name = '__Test Opportunity' Limit 1][0];
        
        //CHime Form
        CHIME__c chimeRecord = new CHIME__c();
        chimeRecord.Account__c = oppty.AccountId;
        chimeRecord.Opportunity__c = oppty.Id;
        chimeRecord.CHIME_Name__c = 'Chime Test Record';
        chimeRecord.Implementation_Type__c = 'Standard';
        insert chimeRecord;
        
        //PAC Product
        PAC_Product_Catalog__c pacProduct = new PAC_Product_Catalog__c();
        pacProduct.Product_Name__c = 'Test Product';
        pacProduct.Is_Available_For_Chime__c = true;
        pacProduct.Phase__c = 'Beta';
        insert pacProduct;

        //Template
        Chime_Product_Template__c template = new Chime_Product_Template__c();
        template.Product__c= pacProduct.Id;
        template.Is_Latest__c= true;
        insert template;
        
        //CPA
        Chime_Product_Association__c newCPA = new Chime_Product_Association__c(CHIME_Product__c=pacProduct.Id,CHIME__c=chimeRecord.Id, Chime_Product_Template__c=template.id);
        insert newCPA;


        //Gating Review DSR
        Deal_Support_Request__c dsr = new Deal_Support_Request__c();
        dsr.Opportunity__c = oppty.Id;
        dsr.chime__c = chimeRecord.Id;
        dsr.RecordTypeId = Schema.SObjectType.Deal_Support_Request__c.getRecordTypeInfosByDeveloperName().get('Pre_Sales_Request').getRecordTypeId();
        dsr.Request_Type__c = 'STG Specialist';
        dsr.Request_Sub_Type__c = 'Gating Review';
        dsr.POC_Status__c = 'New';
        dsr.Start_Date__c = System.today();
        dsr.End_Date__c = System.today() + 5;
        dsr.Notes__c = 'Prolexic Products';
        dsr.Product__c = 'Prolexic';

        insert dsr;
        }
        
    }
}