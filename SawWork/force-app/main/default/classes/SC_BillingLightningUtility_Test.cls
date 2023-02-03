/******

Author: Sharath Prasanna
Created Date: 1st Sep 2020
Description: Test class for SC_BillingLightningUtility

Developer               Date                Jira            Description
Sharath Prasanna     1st Sep 2020        ESESP-3536    	    Test Class
*/
@isTest(SeeAllData=false)
public class SC_BillingLightningUtility_Test 
{
    public SC_BillingLightningUtility_Test() 
    {

    }

    Public static PSA_TestUtility testUtil;
    public static Case caseRec;
    Public static Account acct;
    Public static User usr;
    Public static User usr2;
    Public static Task taskRecord;
    Public static SC_Case_Issue_Sync_Admin_Setting__c adminRec;

    static
    {

        SCUtilTestClass.createCustomSettingsForCase();

        
        // List<PSA_Settings__c> psaSettings = new List<PSA_Settings__c>();
        // PSA_Settings__c workItemLimit;

        // workItemLimit = new PSA_Settings__c();
        // workItemLimit.Name = 'Engineering Team Email';
        // workItemLimit.Value__c = 'services-engg@akamai.com';
        // psaSettings.add(workItemLimit);
            
        // insert psaSettings;
        createTestData();
                
    }

    Public static void createTestData()
    {
        testUtil = new PSA_TestUtility();
        acct = testUtil.newAccount(true);
        
        id recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Billing').getRecordTypeId();

        caseRec = new Case();
        caseRec.RecordTypeID = recordTypeId;
        caseRec.AccountID = acct.id;
        caseRec.Origin = 'Phone';        
        caseRec.Description = 'test';
        caseRec.Validation_Override__c = true;
        caseRec.Akam_case_Id__c = 'abcd';

        usr = testUtil.newUserSysAdmin(true); 

        
        
    }

    @isTest static void testGetCasesMyview()
    {
    
        test.startTest();       

            system.runAs(usr)
            {
                caseRec.OwnerId = UserInfo.getUserId();         
                insert caseRec;                    
    
                SC_BillingLightningUtility.getCases('MyView');
                
            }

            

            
        test.stopTest();        
    }


    @isTest static void testGetCasesQueues()
    {
    
        test.startTest();       

            system.runAs(usr)
            {

                List<String> queueIds = new List<String>();
                for (SC_Utility__mdt billingQueueRec : [Select Value__c,developername from SC_Utility__mdt where 
                Active__c = true and developername like 'BillingQueues%'  limit 1])
                {
                    if(billingQueueRec.Value__c != null)
                    {
                        queueIds.addAll(billingQueueRec.Value__c.split(','));
                    }
                    
                } 
                
                caseRec.OwnerId = queueIds.get(0);         
                insert caseRec;                    
    
                SC_BillingLightningUtility.getCases('AllCases');
                
                
            }

            

            
        test.stopTest();        
    }

    @isTest static void testGetExternalDependancyList()
    {
        test.startTest();       

            system.runAs(usr)
            {
                caseRec.OwnerId = UserInfo.getUserId();         
                insert caseRec;                    
    
                External_Dependency__c eachRec = new External_Dependency__c();
                eachRec.Id__c = 'ESESP-3536';
                eachRec.Case__c = caseRec.Id;
                eachRec.Comment_del__c = 'Test';
                eachRec.Type__c = 'Jira';
                insert eachRec;

                SC_BillingLightningUtility.getExternalDependancyList(caseRec.Id);
            }

        test.stopTest();        

    }


    @isTest static void testConvertMinsToString()
    {
        test.startTest();       

            system.runAs(usr)
            {
                SC_BillingLightningUtility utility = new SC_BillingLightningUtility();
                SC_BillingLightningUtility.convertMinsToString(14400);
                SC_BillingLightningUtility.convertMinsToString(7240);
                SC_BillingLightningUtility.getRecordTypes();
                SC_BillingLightningUtility.renderUserfriendlyError('FIELD_CUSTOM_VALIDATION_EXCEPTION,  : No Error!');
            }

        test.stopTest();        

    }

    @isTest static void testAssignCaseToUser()
    {
        test.startTest();       

            system.runAs(usr)
            {
                List<String> queueIds = new List<String>();
                for (SC_Utility__mdt billingQueueRec : [Select Value__c,developername from SC_Utility__mdt where 
                Active__c = true and developername like 'BillingQueues%'  limit 1])
                {
                    if(billingQueueRec.Value__c != null)
                    {
                        queueIds.addAll(billingQueueRec.Value__c.split(','));
                    }
                    
                } 
                
                caseRec.OwnerId = queueIds.get(0);         
                insert caseRec;                    

                SC_BillingLightningUtility.assignCaseToUser(caseRec.Id);
            }

        test.stopTest();        

    }

    @isTest static void testGetNotificationDetailsUnassigned()
    {
        test.startTest();       

            system.runAs(usr)
            {
                List<String> queueIds = new List<String>();
                for (SC_Utility__mdt billingQueueRec : [Select Value__c,developername from SC_Utility__mdt where 
                Active__c = true and developername like 'BillingQueues%'  limit 1])
                {
                    if(billingQueueRec.Value__c != null)
                    {
                        queueIds.addAll(billingQueueRec.Value__c.split(','));
                    }
                    
                } 
                
                caseRec.OwnerId = queueIds.get(0);         
                insert caseRec;                    

                SC_BillingLightningUtility.getNotificationDetails('Month','unassigned');
            }

        test.stopTest();        

    }
    
    @isTest static void testGetNotificationDetailsMilestones()
    {
        test.startTest();       

            system.runAs(usr)
            {                
                caseRec.OwnerId = UserInfo.getUserId();         
                insert caseRec;                    

                SC_BillingLightningUtility.getNotificationDetails('Month','IR');
            }

        test.stopTest();        

    }

    @isTest static void testGetSummaryOwner()
    {
        test.startTest();       

            system.runAs(usr)
            {                
                caseRec.OwnerId = UserInfo.getUserId();         
                insert caseRec;                    

                SC_BillingLightningUtility.getSummary('Month');
            }

        test.stopTest();        

    }

    @isTest static void testGetSummaryQueue()
    {
        test.startTest();       

            system.runAs(usr)
            {                
                List<String> queueIds = new List<String>();
                for (SC_Utility__mdt billingQueueRec : [Select Value__c,developername from SC_Utility__mdt where 
                Active__c = true and developername like 'BillingQueues%'  limit 1])
                {
                    if(billingQueueRec.Value__c != null)
                    {
                        queueIds.addAll(billingQueueRec.Value__c.split(','));
                    }
                    
                } 
                
                caseRec.OwnerId = queueIds.get(0);         
                insert caseRec;                    

                SC_BillingLightningUtility.getSummary('Month');
            }

        test.stopTest();        

    }

    @isTest static void testUpdateCases()
    {
        test.startTest();       

            system.runAs(usr)
            {                
                caseRec.OwnerId = UserInfo.getUserId();         
                insert caseRec;                    

                Map<String,String> jsonBody = new Map<String,String>();
                jsonBody.put('OwnerId','Cash Apps');

                SC_BillingLightningUtility.updateCases(caseRec.Id, JSON.serialize(jsonBody));

            }

        test.stopTest();        

    }

    @isTest static void testCloneBillingCases()
    {
        test.startTest();       

            system.runAs(usr)
            {                
                caseRec.OwnerId = UserInfo.getUserId();         
                insert caseRec;                    


                SC_Case_LightningUtility.cloneBillingCases(caseRec.Id, '3');

            }

        test.stopTest();        

    }

    @isTest static void testCaseHelper3()
    {
        test.startTest();       

            system.runAs(usr)
            {                
                SC_CaseTriggerHelperClass3 helper = new SC_CaseTriggerHelperClass3();
                Boolean publish = SC_CaseTriggerHelperClass3.publishBilling;
                SC_CaseTriggerHelperClass3.publishPlatformEventBilling();

            }

        test.stopTest();        

    }
    
}