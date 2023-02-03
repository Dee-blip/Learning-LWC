/******

Author: Sharath Prasanna
Created Date: 27th Aug 2020
Description: Test class for TaskTrigger_bi_bu and TaskTrigger_ai

Developer               Date                Jira            Description
Sharath Prasanna     30th Sep 2020        	ACD2-2    		Test Class
*/
@isTest(SeeAllData=false)
public class SC_TaskTrigger_Test 
{
    Public static PSA_TestUtility testUtil;
    public static Case caseRec;
    Public static Account acct;
    Public static User usr;
    Public static Task taskRecord;
    
    static
    {
        //Create custom settings
        SCUtilTestClass.createCustomSettingsForCase();
        
        SC_Case_Issue_Sync_Admin_Setting__c adminRec =  new SC_Case_Issue_Sync_Admin_Setting__c();
        adminRec.Access_Token_Issues_API__c = '';
        adminRec.Client_Certificate__c = 'EAA_KMI_Signed_Certificate';
        adminRec.Client_Id_Issues_API__c = '90f8e0f1-696b-46f9-a504-3811b8ce00fc';
        adminRec.Client_Secret_Issues_API__c = 'b8a4f2c9-24e5-4d5e-a794-6b98730b6915';
        adminRec.Hostname_Issues_API__c = 'https://qa.dash-ext.akamai.com/';
        adminRec.Oauth_Endpoint_Issues_API__c = 'oauth2/token';
        adminRec.Scope_Issues_API__c = 'network-services/issues/v1/issues/';
        insert adminRec;
        
        //create test data
        createTestData();
    }

    //Creates Account, Admin User and sets the case record fields
    Public static void createTestData()
    {
        //Create Account
        testUtil = new PSA_TestUtility();
        acct = testUtil.newAccount(true);
        
        //Prepare technical case
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
	
        //Create user
        usr = testUtil.newUserSysAdmin(true); 
        
        //Prepare Task record
        taskRecord = new Task();        
        taskRecord.description = 'test';
        taskRecord.subject = 'User Setup';
        taskRecord.AKAM_Activity_ID__c = 'xyzas';
        taskRecord.CallDurationInSeconds = 120;
        taskRecord.DueDateProlexic__c = DateTime.now().addDays(2);
        taskRecord.cnx__CTIInfo__c = 'test';
		taskRecord.Status = 'Unassigned';    
        taskRecord.Type__c = 'Task';
    }
    //test method for Service Activity Task
    @isTest static void testTaskTriggerServiceActivity()
    {    
        test.startTest();       
            system.runAs(usr)
            {
                Id amgRecordType = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('AMG').getRecordTypeId();
                caseRec.Work_Type__c = 'Proactive';
                caseRec.Request_Type__c = 'Existing Customer Onboarding';
                caseRec.Service__c = 'Accounts Audits';            
                caseRec.RecordTypeId = amgRecordType;
                caseRec.AKAM_Created_By__c = 'CRMOPS';            
                insert caseRec;
                
                caseRec.AKAM_Created_By__c = 'CRMOPS';
                update caseRec;
                
                Id serviceActivityRT = Task.sObjectType.getDescribe().getRecordTypeInfosByName().get('Service Activity').getRecordTypeId();
                taskRecord.whatid = caseRec.Id;
                taskRecord.RecordTypeId = serviceActivityRT;
                try 
                {
                    insert taskRecord;
                    Id onaId = [SELECT DeveloperName,Value_Text__c
                        FROM SC_Utility__mdt
                        WHERE DeveloperName IN ('Owner_Not_Assigned_User_Id')].Value_Text__c;
                    taskRecord.OwnerId = onaId;
                    taskRecord.Status = 'Unassigned';                
                } 
                catch (Exception e) 
                {
                    
                }
        	}                
        test.stopTest();        
    }
    
    //test method for SecurityServicesActivity
    @isTest static void testTaskTriggerSecurityServicesActivity()
    {
    
        test.startTest();       
            system.runAs(usr)
            {
                insert caseRec;
                
                Id serviceActivityRT = Task.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Security_Services_Activity').getRecordTypeId();
                taskRecord.whatid = caseRec.Id;
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
    //test method for ProvisioningActivity    
    @isTest static void testTaskTriggerProvisioningActivity()
    {
    
        test.startTest();       
            system.runAs(usr)
            {
                insert caseRec;
                
                Id plxRecTypeId = Task.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Provisioning_Activity').getRecordTypeId();
                taskRecord = new Task();        
                taskRecord.whatid = caseRec.Id;
                taskRecord.RecordTypeId = plxRecTypeId;
                try 
                {
                    insert taskRecord;
                    Id onaId = [SELECT DeveloperName,Value_Text__c
                        FROM SC_Utility__mdt
                        WHERE DeveloperName IN ('Owner_Not_Assigned_User_Id')].Value_Text__c;
                    taskRecord.OwnerId = onaId;
                    taskRecord.Status = 'Unassigned';
                    update taskRecord;
                } 
                catch (Exception e) 
                {
                    
                }                
            }                
        test.stopTest();        
    }

    @isTest static void testTaskTriggerForMSAzure()
    {
    
        test.startTest();       
            system.runAs(usr)
            {
                insert caseRec;
                
                MSAzureHandler.varActivateMSAzureCode = true;        
                Id serviceActivityRT = Task.sObjectType.getDescribe().getRecordTypeInfosByName().get('Service Activity').getRecordTypeId();
                taskRecord.whatid = caseRec.Id;
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
    @isTest static void testTaskServiceActivity2()
    {
        test.startTest();       
            system.runAs(usr)
            {
                insert caseRec;
    
                taskRecord.whatid = caseRec.Id;
                insert taskRecord;
                
                Id serviceActivityRT = Task.sObjectType.getDescribe().getRecordTypeInfosByName().get('Service Activity').getRecordTypeId();
                taskRecord.RecordTypeId = serviceActivityRT;
                taskRecord.description = '1234';
                taskRecord.Status='Completed';
                update taskRecord;
            }                
        test.stopTest();        
    }
    
}