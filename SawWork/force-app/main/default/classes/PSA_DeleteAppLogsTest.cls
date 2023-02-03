/* ========================================================================
    Author: Deepak Saxena
    Description: This is a test Class for PSA_DeleteAppLogData
    Created Date : 01/14/2015
    ======================================================================== */
@isTest(SeeAllData=false)  
private class PSA_DeleteAppLogsTest
{
    
    private static testmethod void TestDeleteBacth()
    {
        System.debug(' enteredered ');
        
        List<appirio_core__App_Log__c> appLogList = new List<appirio_core__App_Log__c>();
        for(Integer i = 0; i < 200; i++)
        {
            appirio_core__App_Log__c applog = new appirio_core__App_Log__c(appirio_core__Category__c = 'Test Category', appirio_core__Data__c = 'Test Data',
            appirio_core__Data2__c = 'Test Data2', appirio_core__Level__c = 1, appirio_core__Message__c = 'Test Message', appirio_core__Origin__c = 'Test Origin');
            appLogList.add(applog);
        
        }
        
        insert appLogList;
        
        PSA_Settings__c setting = new PSA_Settings__c(Name = 'Email', Value__c = 'dSaxena@akamai.com');
        insert setting;
        
        PSA_Settings__c setting2 = new PSA_Settings__c(Name = 'Days', Value__c = '0');
        insert setting2;
        
        Test.startTest();
        
        PSA_DeleteAppLogData b= new PSA_DeleteAppLogData(); 
        
        Id BatchProcessid=Database.executeBatch(b,200);
        
        Test.stopTest();
    
    
    }

}