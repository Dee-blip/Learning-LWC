@isTest
public class RevenueAlignmentUpdateContractTest {

	//static User
    static User dmlUser = utilTestClass.getTestRunUser();

    //@testSetup
    static void setupMethod()
    {
        System.runAs(dmlUser) {

            //Create Account
            Account acc1 = utilTestClass.CreateAccount('__Test Account');
            acc1.Type = 'Lead';
            acc1.Website = 'www.test.com';
            acc1.Rev_Aligned__c = false;
            insert acc1;

            Merge_Contract_Header__c contract = new Merge_Contract_Header__c();
            contract.Account_Name__c = acc1.id;
            contract.Revenue_Aligned__c = true;
            insert contract;

            Cron_Batch_Job__c cron = new Cron_Batch_Job__c();
            cron.Batch_Job_Type__c = 'Revenue Alignment Update Contract To Account';
            cron.CreatedDate = System.now();
            cron.Scheduled_to_Run__c = System.now();
            insert cron;
        }
    }

    static testmethod void testSendEmailBatch(){
        
        System.runAs(dmlUser)
        {
            RevenueAlignmentUpdateContractTest.setupMethod();

            Test.StartTest();
            RevenueAlignmentUpdateContractToAccount revenue = new RevenueAlignmentUpdateContractToAccount();
            Database.executeBatch(revenue);
            Test.stopTest();
        }
    }

}