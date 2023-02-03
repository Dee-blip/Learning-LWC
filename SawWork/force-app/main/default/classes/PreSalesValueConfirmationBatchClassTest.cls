@isTest(seeAllData=false)
public class PreSalesValueConfirmationBatchClassTest {


    static
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            utilTestClass.insertCustomSettings();
        } 
    }


    public static testmethod void startBatch()
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            Test.startTest();
            List<Account> Acclist = new List<Account>();

            Account acc = utilTestClass.CreateAccount('Test Account CBR1');
            acc.Website = 'www.CbrWebTesting.com';
            acc.Type = 'Brand - Active';
            acc.Parent_Division__c = 'Web';
            Acclist.add(acc);

            Account acc1 = utilTestClass.CreateAccount('Test Account CBR2');
            acc1.Website = 'www.CbrMediaTesting.com';
            acc1.Type = 'Brand - Active';
            acc1.Parent_Division__c = 'Media & Carrier';
            acc1.Commercial_Segmentation__c = 'Preferred Growth';
            Acclist.add(acc1);

            insert Acclist;

            List<AccountTeamMember> ATMember = new List<AccountTeamMember>();

            for(Account account : Acclist){
                AccountTeamMember atm = new AccountTeamMember();
                atm.AccountId = account.id;
                atm.TeamMemberRole = 'Technical Sales - Primary';
                atm.UserId = UserInfo.getUserId();
                ATMember.add(atm);
            }

            insert ATMember;

            Cron_Batch_Job__c testBatchJob = utilTestClass.createCronBatchJob('Pre Sales Value Confirmation','Pre Sales Value Confirmation');
            insert testBatchJob;
            Cron_Batch_Run__c testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
            insert testBatchRun;
            testBatchRun.Trigger_Batch_Run__c = true;
            update testBatchRun;

            Test.stopTest();

        }
    }    
    

}