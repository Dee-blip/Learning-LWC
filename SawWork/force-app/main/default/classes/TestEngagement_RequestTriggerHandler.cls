/*****************************************************************************
 * Name             : TestEngagement_RequestTriggerHandler
 * Created By       : Vinod
 * Created Date     : June 11,2013
 * Related task     : T-150208
 * Purpose          : Test Class for the trigger Engagement_RequestTrigger and class Engagement_RequestTriggerHandler
 Last Modified  Developer   Purpose            
 =============    =========   =======
 10-Mar-14      Himanshu    Optimize the Test Class
 23-Jul-14      Akhila      Renamed Tier 2 Technical Support ER Record type to CCare Technical Escalation
 05-Apr-17      Pinkesh     Bug Fixes
 31-May-18      Vandhana    ESESP-319 OLA (External Team Escalation)
 *****************************************************************************/
 
@isTest(seeAllData=false)
private class TestEngagement_RequestTriggerHandler
{
    @TestSetup
    static void setup(){
        SC_SuperProfileID__c objScSuperProfileId = new SC_SuperProfileID__c();
        objScSuperProfileId.Name = 'SA Test';
        objScSuperProfileId.ProfileId__c =  [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
        
        System.runas(new User(Id = Userinfo.getUserId()))
        { 
            utilTestClass.createCustomSettings();
            insert objScSuperProfileId;
        }
    }
    
    // Test Method - 1
    static testMethod void test1()
    {
        Test.startTest();
        
        // Fetching Case Record Type
        Map<String, Schema.RecordTypeInfo> rtMap = Case.sObjectType.getDescribe().getRecordTypeInfosByName();  
        
        // Creating Account     
        Account acc1 = utilTestClass.createAccount('AccountTest1');  
        insert acc1;  
        
        // Creating Case Product
        EB_AccountProductMap__c caseProduct = new EB_AccountProductMap__c(EB_Product__c = 'Alta',
                                    Name = 'Alta',EB_Account__c = acc1.Id,
                                    EB_MarkedForDeletion__c = false);  
        insert caseProduct;
        
        // Creating Case
        Case cs = new Case();
        cs.RecordTypeId     = rtMap.get('Technical').getRecordTypeId();
        cs.Status       = 'Unassigned';
        cs.Origin       = 'Email';
        cs.ProductPL__c     = 'Alta';
        cs.Resolution_Sent__c = false;
        cs.AccountId        = acc1.Id;
        cs.Case_Product__c  = caseProduct.Id;
        cs.Case_Assignment_Using_Active_Rules__c = true;
        insert cs;
        
        // Fetching Engagement Request Record Type
        Map<String, Schema.RecordTypeInfo> requetRecordTypeMap = Engagement_Request__c.sObjectType.getDescribe().getRecordTypeInfosByName();
        
        // Creating New Engagement Request
        Engagement_Request__c eReq = new Engagement_Request__c();
        eReq.Case__c            = cs.ID;
        eReq.RecordTypeId       = requetRecordTypeMap.get('Stability Engineering').getRecordTypeId();
        eReq.Request_Status__c  = 'Open';
        eReq.Assigned_To__c     = userinfo.getUserId();
        eReq.Area__c            = 'Media';
        insert eReq; 
        
        Test.stopTest();

        List<Engagement_Request__c> engagementRequests = [SELECT Id FROM Engagement_Request__c];
        System.assert(engagementRequests.size() > 0, 'Engagement Request not created.');
    }
    
    // Test Method - 2
    static testMethod void test2()
    {
        Test.startTest();
        
        // Fetching Case Record Type
        Map<String, Schema.RecordTypeInfo> rtMap = Case.sObjectType.getDescribe().getRecordTypeInfosByName();  
        
        // Creating Account     
        Account acc1 = utilTestClass.createAccount('AccountTest2');  
        insert acc1;  
        
        // Creating Case Product
        EB_AccountProductMap__c caseProduct = new EB_AccountProductMap__c(EB_Product__c = 'Alta',
                                                                          Name = 'Alta',EB_Account__c = acc1.Id,
                                                                          EB_MarkedForDeletion__c = false);  
        insert caseProduct;
        
        // Creating Case
        Case cs = new Case();
        cs.RecordTypeId = rtMap.get('Technical').getRecordTypeId();
        cs.Status = 'Unassigned';
        cs.Origin = 'Email';
        cs.ProductPL__c = 'Alta';
        cs.Resolution_Sent__c = false;
        cs.AccountId = acc1.Id;
        cs.Case_Product__c = caseProduct.Id;
        cs.Case_Assignment_Using_Active_Rules__c = true;
        insert cs;
        
        // Fetching Engagement Request Record Type
        Map<String, Schema.RecordTypeInfo> requetRecordTypeMap = Engagement_Request__c.sObjectType.getDescribe().getRecordTypeInfosByName();
        
        // Creating New Engagement Request
        List<Engagement_Request__c> lst = new List<Engagement_Request__c>();
        Engagement_Request__c eReq3 = new Engagement_Request__c();
        eReq3.Case__c = cs.ID;
        eReq3.RecordTypeId = requetRecordTypeMap.get('CCare Technical Escalation').getRecordTypeId();
        eReq3.Request_Status__c = 'Open';
        eReq3.OwnerId = userinfo.getUserId();
        lst.add(eReq3);
        
        insert lst;
        
        Test.stopTest();

        List<Engagement_Request__c> engagementRequests = [SELECT Id FROM Engagement_Request__c];
        System.assert(engagementRequests.size() > 0, 'Engagement Request not created.');

    }
    
    // Test Method - 2
    static testMethod void testMethod2() 
    {
        // Fetching Case Record Type
        Map<String, Schema.RecordTypeInfo> rtMap = Case.sObjectType.getDescribe().getRecordTypeInfosByName();  
        
        // Creating Account     
        Account acc1 = utilTestClass.createAccount('testMethod2Account');  
        insert acc1;  
        
        // Creating Case Product
        EB_AccountProductMap__c caseProduct = new EB_AccountProductMap__c(EB_Product__c = 'Alta',
                                                                          Name = 'Alta',EB_Account__c = acc1.Id,
                                                                          EB_MarkedForDeletion__c = false);  
        insert caseProduct;
        
        // Creating Case
        Case cs = new Case();
        cs.RecordTypeId = rtMap.get('Technical').getRecordTypeId();
        cs.Status = 'Unassigned';
        cs.Origin = 'Email';
        cs.ProductPL__c = 'Alta';
        cs.Resolution_Sent__c = false;
        cs.AccountId = acc1.Id;
        cs.Case_Product__c = caseProduct.Id;
        cs.Case_Assignment_Using_Active_Rules__c = true;
        insert cs;
        
        System_to_Area_Mapping__c s2a = new System_to_Area_Mapping__c(System__c = 'JIRA',Area__c = 'JIRA',System_URL__c='jiralink');
        insert s2a;
        
        // Fetching Engagement Request Record Type
        Map<String, Schema.RecordTypeInfo> requetRecordTypeMap = Engagement_Request__c.sObjectType.getDescribe().getRecordTypeInfosByName();
        
        List<Engagement_Request__c> lst = new List<Engagement_Request__c>();
        Engagement_Request__c eReq3 = new Engagement_Request__c();
        
        eReq3.Case__c = cs.ID;
        eReq3.System__c = 'JIRA';
        eReq3.Area__c = 'JIRA';
        eReq3.RecordTypeId = requetRecordTypeMap.get('External Team').getRecordTypeId();
        eReq3.ID__c = 'JIRA-123';
        eReq3.OwnerId = userinfo.getUserId();
        lst.add(eReq3);
        
        eReq3 = new Engagement_Request__c();
        eReq3.Case__c = cs.ID;
        eReq3.System__c = 'Non - JIRA';
        eReq3.Area__c = 'JIRA';
        eReq3.RecordTypeId = requetRecordTypeMap.get('External Team').getRecordTypeId();
        eReq3.ID__c = 'NJ-123';
        eReq3.OwnerId = userinfo.getUserId();
        lst.add(eReq3);
        
        eReq3 = new Engagement_Request__c();
        eReq3.Case__c = cs.ID;
        eReq3.System__c = 'LUNA';
        eReq3.Area__c = 'LUNA System';
        eReq3.RecordTypeId = requetRecordTypeMap.get('External Team').getRecordTypeId();
        eReq3.ID__c = 'LUNA-123';
        eReq3.OwnerId = userinfo.getUserId();
        lst.add(eReq3);
        
        eReq3 = new Engagement_Request__c();
        eReq3.Case__c = cs.ID;
        eReq3.System__c = 'JIRA';
        eReq3.RecordTypeId = requetRecordTypeMap.get('AMG Escalation').getRecordTypeId();
        eReq3.ID__c = 'JIRA-123';
        eReq3.OwnerId = userinfo.getUserId();
        lst.add(eReq3);
        
        eReq3 = new Engagement_Request__c();
        eReq3.Case__c = cs.ID;
        eReq3.Description__c = 'Desc';
        eReq3.RecordTypeId = requetRecordTypeMap.get('CCare Mgmt Escalation').getRecordTypeId();
        eReq3.OwnerId = userinfo.getUserId();
        eReq3.Validation_Override__c = true;
        lst.add(eReq3);

        Test.startTest();
        
        insert lst;
        lst.clear();
        
        Engagement_Request__c erq1 = [Select ID from Engagement_Request__c where System__c = 'JIRA' limit 1];
        erq1.System__c = 'Bugzilla';
        erq1.Validation_Override__c = true;
        lst.add(erq1);
        
        Engagement_Request__c erq = [Select ID from Engagement_Request__c where System__c = 'LUNA' limit 1];
        erq.Validation_Override__c = true;
        erq.System__c = 'JIRA';
        //erq.System__c = 'Non - JIRA';
        lst.add(erq);
        update lst;
        
        
        Test.stopTest();

        List<Engagement_Request__c> engagementRequests = [SELECT Id FROM Engagement_Request__c];
        System.assert(engagementRequests.size() > 0, 'Engagement Request not created.');
    }
    
    // Test Method - 3
    static testMethod void test3()
    {
        Test.startTest();
        
        // Fetching Case Record Type
        Map<String, Schema.RecordTypeInfo> rtMap = Case.sObjectType.getDescribe().getRecordTypeInfosByName();  
        
        // Creating Account     
        Account acc1 = utilTestClass.createAccount('AccountTest3');  
        insert acc1;  
        
        // Creating Case Product
        EB_AccountProductMap__c caseProduct = new EB_AccountProductMap__c(EB_Product__c = 'Alta',
                                                                          Name = 'Alta',EB_Account__c = acc1.Id,
                                                                          EB_MarkedForDeletion__c = false);  
        insert caseProduct;
        
        // Creating Case
        Case cs = new Case();
        cs.RecordTypeId = rtMap.get('Technical').getRecordTypeId();
        cs.Status = 'Unassigned';
        cs.Origin = 'Email';
        cs.ProductPL__c = 'Alta';
        cs.Resolution_Sent__c = false;
        cs.AccountId = acc1.Id;
        cs.Case_Product__c = caseProduct.Id;
        cs.Case_Assignment_Using_Active_Rules__c = true;
        insert cs;
        
        // Fetching Engagement Request Record Type
        Map<String, Schema.RecordTypeInfo> requetRecordTypeMap = Engagement_Request__c.sObjectType.getDescribe().getRecordTypeInfosByName();
        
        // Creating New Engagement Request
        Engagement_Request__c eReq1 = new Engagement_Request__c();
        eReq1.Case__c = cs.ID;
        eReq1.RecordTypeId = requetRecordTypeMap.get('Stability Engineering').getRecordTypeId();
        eReq1.Request_Status__c = 'Open';
        eReq1.Area__c = 'Media';     
        insert eReq1;
        
        eReq1.Assigned_To__c = userinfo.getUserId();
        update eReq1;
        
        Test.stopTest();

        List<Engagement_Request__c> engagementRequests = [SELECT Id FROM Engagement_Request__c];
        System.assert(engagementRequests.size() > 0, 'Engagement Request not created.');
        
    }
    
    //Test Method - 4(for covering class ExternalDependencyTriggerHandler)
    static testMethod void test4()
    {
        // Fetching Case Record Type
        Map<String, Schema.RecordTypeInfo> rtMap = Case.sObjectType.getDescribe().getRecordTypeInfosByName();  
        
        // Creating Account     
        Account acc1 = utilTestClass.createAccount('AccountTest4');  
        acc1.Support_Advocate__c = true;
        insert acc1;  
        
        // Creating Case Product
        EB_AccountProductMap__c caseProduct = new EB_AccountProductMap__c(EB_Product__c = 'Alta',
                                                                          Name = 'Alta',EB_Account__c = acc1.Id,
                                                                          EB_MarkedForDeletion__c = false);  
        insert caseProduct;
        
        // Creating Case
        Case cs = new Case();
        cs.RecordTypeId = rtMap.get('Technical').getRecordTypeId();
        cs.Status = 'Unassigned';
        cs.Origin  = 'Email';
        cs.ProductPL__c = 'Alta';
        cs.Resolution_Sent__c = false;
        cs.AccountId = acc1.Id;
        cs.Case_Product__c = caseProduct.Id;
        cs.Case_Assignment_Using_Active_Rules__c = true;
        insert cs;
        
        //Creating Ecternal Dependency
        External_Dependency__c ext1 = new External_Dependency__c();
        ext1.ID__c = '345654';
        ext1.Type__c = 'Bugzilla';
        ext1.Case__c = cs.Id;
        ext1.Comment__c = 'Test Comment';
        insert ext1;
        
        // Fetching Engagement Request Record Type
        Map<String, Schema.RecordTypeInfo> requetRecordTypeMap = Engagement_Request__c.sObjectType.getDescribe().getRecordTypeInfosByName();
        
        // Creating New Engagement Request
        List<Engagement_Request__c> lst = new List<Engagement_Request__c>();
        Engagement_Request__c eReq1 = new Engagement_Request__c();
        eReq1.Case__c  = cs.ID;
        eReq1.RecordTypeId = requetRecordTypeMap.get('CCare Technical Escalation').getRecordTypeId();
        eReq1.Request_Status__c = 'Unassigned';
        eReq1.Area__c = 'Web Experience';     
        lst.add(eReq1);
        
        insert lst;
        
        Test.startTest();
        ext1.ID__c = '345655';
        update ext1;
        Test.stopTest();

        List<Engagement_Request__c> engagementRequests = [SELECT Id FROM Engagement_Request__c];
        System.assert(engagementRequests.size() > 0, 'Engagement Request not created.');
      }
    
}