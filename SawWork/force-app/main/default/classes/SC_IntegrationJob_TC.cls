/* 
/***************************************************************************
 * Name             : SC_IntegrationJob_TC
 * Created By       : Sharath Prasanna
 * Created Date     : 27-Aug-2020
 * Purpose          : Code Coverage for below Components:
 						1. SC_SiebelIssueSync - Apex Class
                        2. SC_SiebelIssueSyncHttpRequestMock - Mock HTTP class
                        3. SC_CaseSiebelIssueSyncBatch - Apex Class
                        4. SC_CaseSiebelIssueSyncOneTimeBatch - Apex Class
                        5. TaskTrigger_ai_au - Apex Trigger
						6. SC_User_FilterTrigger
						7. SC_DeleteSobject
 Last Modified BY   Last Modified Date  Purpose
 ----------------   ------------------  ---------
 Harshil			08-Sep-2020			Added test method to cover SC_User_FilterTrigger and SC_DeleteSobject
 *****************************************************************************/ 


@isTest(SeeAllData=false)
public class SC_IntegrationJob_TC 
{

    Public static PSA_TestUtility testUtil;
    public static Case caseRec;
    Public static Account acct;
    Public static User usr;
    Public static Task taskRecord;
    Public static SC_Case_Issue_Sync_Admin_Setting__c adminRec;

    //Static block to create custom settings
    static
    {

        SCUtilTestClass.createCustomSettingsForCase();

        adminRec =  new SC_Case_Issue_Sync_Admin_Setting__c();
        adminRec.Access_Token_Issues_API__c = '';
        adminRec.Client_Certificate__c = 'EAA_KMI_Signed_Certificate';
        adminRec.Client_Id_Issues_API__c = '90f8e0f1-696b-46f9-a504-3811b8ce00fc';
        adminRec.Client_Secret_Issues_API__c = 'b8a4f2c9-24e5-4d5e-a794-6b98730b6915';
        adminRec.Hostname_Issues_API__c = 'https://qa.dash-ext.akamai.com/';
        adminRec.Oauth_Endpoint_Issues_API__c = 'oauth2/token';
        adminRec.Scope_Issues_API__c = 'network-services/issues/v1/issues/';
        insert adminRec;
        
        List<PSA_Settings__c> psaSettings = new List<PSA_Settings__c>();
        PSA_Settings__c workItemLimit;

        workItemLimit = new PSA_Settings__c();
        workItemLimit.Name = 'Engineering Team Email';
        workItemLimit.Value__c = 'services-engg@akamai.com';
        psaSettings.add(workItemLimit);
            
        insert psaSettings;
        createTestData();
                
    }

    //Static method to create Test data
    Public static void createTestData()
    {
        testUtil = new PSA_TestUtility();
        acct = testUtil.newAccount(true);
        
        id technicalId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical').getRecordTypeId();

        caseRec = new Case();
        caseRec.RecordTypeID = technicalId;
        caseRec.AccountID = acct.id;
        caseRec.Origin = 'Phone';        
        caseRec.Description = 'test';
        caseRec.Validation_Override__c = true;
        caseRec.Sub_Type__c = 'CMP Alerts';
        caseRec.Akam_case_Id__c = 'abcd';
        caseRec.Issue__c = '12345';                

        usr = testUtil.newUserSysAdmin(true); 
        
    }

    //Test method to cover SC_SiebelIssueSync: Positive use case
    @isTest static void testSiebelSyncPositive()
    {
        system.runAs(usr)
        {
            
            insert caseRec;
            
            taskRecord = new Task();        
            taskRecord.whatid = caseRec.Id;
            taskRecord.description = 'test';
            taskRecord.subject = 'single';
            taskRecord.AKAM_Activity_ID__c = 'xyzas';
            insert taskRecord;
            

        }
    
        test.startTest();       

            Test.setMock(HttpCalloutMock.class, new SC_SiebelIssueSyncHttpRequestMock(false)); 
            List<SC_SiebelIssueSync.IssueActivityWrapper> wrappers = new List<SC_SiebelIssueSync.IssueActivityWrapper>();
            SC_SiebelIssueSync.IssueActivityWrapper wrapper = new SC_SiebelIssueSync.IssueActivityWrapper(taskRecord.AKAM_Activity_ID__c,caseRec.Id, caseRec.AKAM_Case_ID__c
            ,caseRec.CaseNumber, caseRec.Issue__c, '123456789', 
            taskRecord.Description);
                wrappers.add(wrapper);                    
            SC_SiebelIssueSync.syncActivitySiebel(JSON.serialize(wrappers),new Set<String>{'123456789'},false, false);

            
        test.stopTest();        
    }

    //Test method to cover SC_SiebelIssueSync: Negative use case
    @isTest static void testSiebelSyncNegative()
    {
        adminRec.Access_Token_Issues_API__c = 'J1OieGGnuqWKitpvLEW8CDo4LI4YsJEwJJu6ujlO4BMa3PRp4G10nWA3gpFgK14b4Gg5dl05PTJl8re6ibbg1Q';
        adminRec.Token_Expiry_Date_Issues_API__c = datetime.now().addDays(3);
        update adminRec;

        system.runAs(usr)
        {
            
            insert caseRec;
            
            taskRecord = new Task();        
            taskRecord.whatid = caseRec.Id;
            taskRecord.description = 'test';
            taskRecord.subject = 'single';
            taskRecord.AKAM_Activity_ID__c = 'xyzas';
            insert taskRecord;
            

        }
    
        test.startTest();       

            Test.setMock(HttpCalloutMock.class, new SC_SiebelIssueSyncHttpRequestMock(true)); 
            List<SC_SiebelIssueSync.IssueActivityWrapper> wrappers = new List<SC_SiebelIssueSync.IssueActivityWrapper>();
            SC_SiebelIssueSync.IssueActivityWrapper wrapper = new SC_SiebelIssueSync.IssueActivityWrapper(taskRecord.AKAM_Activity_ID__c,caseRec.Id, caseRec.AKAM_Case_ID__c
            ,caseRec.CaseNumber, caseRec.Issue__c, '123456789', 
            taskRecord.Description);
                wrappers.add(wrapper);                    
            SC_SiebelIssueSync.syncActivitySiebel(JSON.serialize(wrappers),new Set<String>{'123456789'},false, false);

            
        test.stopTest();        
    }
    
    //Test method to cover TaskTrigger_ai_au
    @isTest static void testTaskTrigger1()
    {
    
        test.startTest();       

        system.runAs(usr)
        {
            insert caseRec;
            
            
            
            taskRecord = new Task();        
            taskRecord.whatid = caseRec.Id;
            taskRecord.description = 'test';
            taskRecord.subject = 'single';
            taskRecord.AKAM_Activity_ID__c = 'xyzas';
            taskRecord.Type__c = 'Task';
            taskRecord.subject='User Setup';

            insert taskRecord;
            
            Id serviceActivityRT = Task.sObjectType.getDescribe().getRecordTypeInfosByName().get('Service Activity').getRecordTypeId();
            taskRecord.RecordTypeId = serviceActivityRT;
            taskRecord.description = '1234';
            taskRecord.Status='Completed';
            update taskRecord;

        }    
            
        test.stopTest();        
    }
    
    //Test method to cover TaskTrigger_ai_au
    @isTest static void testTaskTrigger2()
    {
    
        test.startTest();       

        system.runAs(usr)
        {
            insert caseRec;
            
            MSAzureHandler.varActivateMSAzureCode = true;        
            Id serviceActivityRT = Task.sObjectType.getDescribe().getRecordTypeInfosByName().get('Service Activity').getRecordTypeId();

            taskRecord = new Task();        
            taskRecord.whatid = caseRec.Id;
            taskRecord.description = 'test';
            taskRecord.subject = 'single';
            taskRecord.AKAM_Activity_ID__c = 'xyzas';
            taskRecord.RecordTypeId = serviceActivityRT;

            try 
            {
                insert taskRecord;
            } 
            catch (Exception e) 
            {
                
            }
                
        }    
            
        test.stopTest();        
    }

    //Test method to cover SC_CaseSiebelIssueSyncBatch
    @isTest static void testRetryBatch()
    {
        system.runAs(usr)
        {
            
            insert caseRec;
            
            taskRecord = new Task();        
            taskRecord.whatid = caseRec.Id;
            taskRecord.description = 'test';
            taskRecord.subject = 'single';
            taskRecord.AKAM_Activity_ID__c = 'xyzas';
            insert taskRecord;
            

        }
    
        test.startTest();       

            SC_CaseIssueStaging__c stagingRec = new SC_CaseIssueStaging__c();
            stagingRec.Activity_Id__c = 'xyzas';
            stagingRec.Issue__c = '12345';
            stagingRec.Retry_Count__c = 3;
            stagingRec.Case__c = caseRec.Id;
            stagingRec.Last_Sync_Status__c = 'Failure';
            stagingRec.Unique_Key__c = 'abcd12345xyzas1';
            insert stagingRec;

            Database.executeBatch(new SC_CaseSiebelIssueSyncBatch(),20);
        test.stopTest();        
    }

    //Test method to cover SC_CaseSiebelIssueSyncOneTimeBatch
    @isTest static void testTemporaryBatch()
    {
         system.runAs(usr)
         {
            
             insert caseRec;
            
             taskRecord = new Task();        
             taskRecord.whatid = caseRec.Id;
             taskRecord.description = 'test';
             taskRecord.subject = 'single';
             taskRecord.AKAM_Activity_ID__c = 'xyzas';
             insert taskRecord;
            

         }
    
         test.startTest();       

             SC_CaseIssueStaging__c stagingRec = new SC_CaseIssueStaging__c();
             stagingRec.Activity_Id__c = 'xyzas';
             stagingRec.Issue__c = '12345';
             stagingRec.Retry_Count__c = 3;
             stagingRec.Case__c = caseRec.Id;
             stagingRec.Last_Sync_Status__c = 'Failure';
             stagingRec.Unique_Key__c = null;
             insert stagingRec;

             Database.executeBatch(new SC_CaseSiebelIssueSyncOneTimeBatch(),20);
         test.stopTest();        
     }
    
    //Test method to cover SC_User_FilterTrigger and SC_DeleteSobject batch job (EB Product Job)
    @isTest static void testEBProductJob(){
        
        //Creating Test Data for SC_User_FilterTrigger (EB_Product_Job) trigger
        Id metadataId = Schema.SObjectType.SC_User_Filter__c.getRecordTypeInfosByName().get('Metadata').getRecordTypeId();
        SC_User_Filter__c userFilterRecord = new SC_User_Filter__c();
        userFilterRecord.Unique_ID__c = 'EB_Product_Job';
        userFilterRecord.Filter_Values__c = 'Up-to-date';
        userFilterRecord.RecordTypeId = metadataId;
        Insert userFilterRecord;
        
        test.startTest();
        userFilterRecord.Filter_Values__c = 'Synced';
        //This will invoke the trigger which in turn will invoke the SC_DeleteSobject batch job
        Update userFilterRecord;
        test.stopTest();
    }

    
}