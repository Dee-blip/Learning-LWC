/* ========================================================================
    Author: Vandhana Krishnamurthy
    Description: Test class for Batch Class PSA_DeleteBillingQueueData_Test
    Created Date : 12/09/2015
    ======================================================================== */

@isTest(SeeAllData=false)
public class PSA_DeleteBillingQueueData_Test 
{
    public static testMethod void testDeleteBillingQueueData()
    {
        PSA_Settings__c psSetting1 = new PSA_Settings__c();
        psSetting1.Name = 'Engineering Team Email';
        psSetting1.Value__c = 'services-engg@akamai.com';
        insert psSetting1;

        PSA_Settings__c psSetting2 = new PSA_Settings__c();
        psSetting2.Name = 'FromEmailAdress';
        psSetting2.Value__c = 'qa-ps-notify@akamai.com';
        insert psSetting2;

        test.startTest();
        PSA_DeleteBillingQueueData delBillQueue = new PSA_DeleteBillingQueueData();
        Database.executeBatch(delBillQueue);
        test.stopTest();
    }
}