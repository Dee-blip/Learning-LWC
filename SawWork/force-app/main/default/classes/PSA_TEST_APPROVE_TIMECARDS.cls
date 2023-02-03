@isTest(SeeAllData=false)
public class PSA_TEST_APPROVE_TIMECARDS 
{
    public static testMethod void testProjectCreation()
    {
        test.startTest();
        PSA_APPROVE_PENDING_TIMECARDS APT = new PSA_APPROVE_PENDING_TIMECARDS();
        Database.executeBatch(APT);
        test.stopTest();
    }
}