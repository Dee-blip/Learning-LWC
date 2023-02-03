@isTest(SeeAllData=TRUE)
 /*
     *@author           Chakradhar 
     *@date             11-July-2013
     *@description      Unit test case for testing trigger populate_accnt_name.
     */
public class TestPopulateAccntNameOneOff{
    private static List<Merge_Contract_Header__c> getContractHeaderList()
    {
        //return [select Id From Merge_Contract_Header__c limit 1];
        Account acc = utilTestClass.CreateAccount('Test Populate Account');
        insert acc;
        Merge_Contract_Header__c contract = new Merge_Contract_Header__c(name = 'test contract testclass', Account_Name__c = acc.Id);
        insert contract;
        list<Merge_Contract_Header__c> lstContract = new list<Merge_Contract_Header__c> ();
        lstContract.add(Contract);
        return lstContract;
    }
    /* 
     *  Below nmethod will test the auto populate functionality of 
     *  Account Name in Multi_Batch 
     */

    static testMethod void testPopulate(){
        Master_Batch_Name__c masterBatch = new Master_Batch_Name__c();
        date startDate = date.newInstance(2013,5,31);
        masterBatch.Name='test_ais';
        masterBatch.Batch_Run__c='One-off';
        masterBatch.Batch_Type__c='No Stats Run – X';
        masterBatch.Statistics_End_Date__c=startDate;
        masterBatch.Statistics_Start_Date__c = startDate;
        insert masterBatch;
        
        List<Merge_Contract_Header__c>  contract =  getContractHeaderList();
        Multi_Batch_Order_ID__c multiBatch = new Multi_Batch_Order_ID__c();
        multiBatch.Original_ID__c = contract[0].Id;
        multiBatch.Parent_Batch_Name__c = masterBatch.id;
        System.test.startTest();
        insert multiBatch;
        System.test.stopTest();
        
        List<Multi_Batch_Order_ID__c> mbReord = [select Account_Name__c from Multi_Batch_Order_ID__c where Id=:multiBatch.Id];
        //System.debug(mbReord[0].Account_Name__c);
        List<Account> accnt = [select Name from Account where id in (select Account_Name__c from Merge_Contract_Header__c where Id=:contract[0].Id)];
        System.assertEquals(mbReord[0].Account_Name__c,accnt[0].Name);
    }
}