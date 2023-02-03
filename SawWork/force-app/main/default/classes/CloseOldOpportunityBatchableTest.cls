/***
    CloseOldOpportunityBatchableTest
    @author : Ali KM <mohkhan@akamai.com>
    @Description : This Class tests the CloseOldOpportunityBatchable schedule job.
    
    @History
    --Developer           --Date            --Change
    Ali KM              22/Aug/2012         CR 1762643 Re-schedule job to make opportunity 'Closed Admin'.
*/

@isTest (seeAllData=false)
private class CloseOldOpportunityBatchableTest 
{   
    private static Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
    
    private static List<Opportunity> RefreshOpportunity(Opportunity pOpp)
    {
        return RefreshOpportunity(new List<Opportunity> {pOpp});
    }

    static{
        Test.loadData(globalDescribe.get('GSM_Custom_Settings__c'), 'CS_GSM_Custom_Settings');
    }
    
    /**
        RefreshOpportunity()
        - Overloaded to refresh bulk Opportunities
    */
    private static List<Opportunity> RefreshOpportunity(List<Opportunity> pOppList)
    {
        return [select Id,
                       Name,
                       OwnerId,
                       CloseDate,
                       StageName,
                       CreatedById
                from Opportunity 
                where Id IN :pOppList];
    }           
  
    /** 
        getUserWithAccountReassignmentRule()
            - Generates a user with AccountReassignment Rule
            - Returns User          
    */
    private static User getUserWithAccountReassignmentRule()
    {   
        ManagedPkgErrorClass.isFromManagedPackage = false;

        // Added 2 line for CR 2842878(fix the Mixed Dml Exception)
        User accOwnerUser;
       
        accOwnerUser = utilTestClass.CreateUser('newUser', GsmUtilClass.getGsmSettingValue('User_Role'), 'Sales Operations');
        insert accOwnerUser;    
       
        // Create a rule
        Account_Reassignment_Rule__c rule = utilTestClass.CreateAccountReassignmentRule('__TestRule', accOwnerUser.Id, GsmUtilClass.getGsmSettingValue('User_Role'));
        insert rule;
       
        //insert getAccountReassignmentRule(accOwnerUser, role);        
        return accOwnerUser;   
              
    }
    
    static testmethod void Test1() 
    {   ManagedPkgErrorClass.isFromManagedPackage = false;
        Integer intNoOfMonthsOldSetting=1+CloseOldOpportunityBatchable.NO_OF_MONTHS_OLD; //1+Integer.valueOf(GsmUtilClass.GetCustomSettingValue('SchOpptyClose', 'NoOfMonthsOld'));
        List<String> Record_Type_Ids = GsmUtilClass.getGSMSettingValue('Opportunity_Record_Type_Ids').split(',');
        Test.startTest();
        Account acc = utilTestClass.CreateAccount('__Test Account');
        insert acc;
        
        // Create Opportunities. 
        List<Opportunity> bulkOpportunityList = new List<Opportunity>();    
        for(Integer i=0;i<10;i++)
        {   
            Opportunity oppty = utilTestClass.CreateOpportunity('OpptySchTest__'+i,'1-Create');
            oppty.AccountId = acc.Id;
            oppty.RecordTypeId = Record_Type_Ids[0];
            oppty.CloseDate = Date.today().addMonths(-1*intNoOfMonthsOldSetting); //Date.today();
            bulkOpportunityList.add(oppty);
        }
        insert bulkOpportunityList; 
           
        CloseOldOpportunityBatchable batchObj = new CloseOldOpportunityBatchable();
        Database.executeBatch(batchObj);
        Test.stopTest();
   }

   static testmethod void Test2()
   {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        Integer intNoOfMonthsOldSetting=1+CloseOldOpportunityBatchable.NO_OF_MONTHS_OLD; //1+Integer.valueOf(GsmUtilClass.GetCustomSettingValue('SchOpptyClose', 'NoOfMonthsOld'));
        Test.startTest();
        Account acc = utilTestClass.CreateAccount('__Test Account');
        insert acc;
        
        // Create Opportunities. 
        List<Opportunity> bulkOpportunityList = new List<Opportunity>();    
        for(Integer i=0;i<10;i++)
        {   
            Opportunity oppty = utilTestClass.CreateOpportunity('OpptySchTest__'+i,'1-Create');
            oppty.AccountId = acc.Id;
            oppty.CloseDate = Date.today().addMonths(-1*intNoOfMonthsOldSetting); //Date.today();
            bulkOpportunityList.add(oppty);
        }
        insert bulkOpportunityList; 

        // Create the CronBatch Job record.
        Cron_Batch_Job__c batchJob = new Cron_Batch_Job__c();
        batchJob.Name = 'CloseOldOppty:Testcase';
        batchJob.Batch_Job_Type__c = 'Close Old Opportunities';
        batchJob.RecordTypeId = Schema.SObjectType.Cron_Batch_Job__c.getRecordTypeInfosByName().get('Custom Job').getRecordTypeId();
        batchJob.Run_Every__c = 1;
        batchJob.Period__c = 'Month';
        batchJob.Scheduled_to_Run__c = DateTime.now();
        batchJob.Validation_Override__c = true;
        insert batchJob;

        // Create the BatchRun record.
        Cron_Batch_Run__c batchRun = new Cron_Batch_Run__c();
        batchRun.Trigger_Batch_Run__c = true;
        batchRun.Cron_Batch_Job__c = batchJob.Id; 
        batchRun.Scheduled_to_Run__c =  DateTime.now();
        batchRun.Validation_Override__c = true;  
        insert batchRun;
           
        CloseOldOpportunityBatchable batchObj = new CloseOldOpportunityBatchable(batchRun);
        Database.executeBatch(batchObj);
        Test.stopTest();
   } 
}