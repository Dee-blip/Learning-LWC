@istest
public class L2Q_Sales_processInactiveUserTest {
    static testmethod void test() {
        Test.startTest();
        Profile p = [select id,name from Profile where (Name like'Sales%') limit 1];
        User u = new User();
        u.FirstName = 'test';
        u.alias= 'testas';
        u.LastName = 'test';
        u.email = 'test@akamai.com';
        u.IsActive = true;
        u.ProfileId = p.id;
        u.LanguageLocaleKey='en_US';
                        u.LocaleSidKey='en_US';
                        u.EmailEncodingKey='UTF-8';
                        u.TimeZoneSidKey='America/Los_Angeles';
        u.Username = 'testRandom911@akamai.com';
        insert u;

        u.IsActive = false;
        u.Sales_Team_Member_Inactive_Proccessed__c = true;
        update u;

        // Schedule the test job

        SchedulableContext sc = null;
        L2Q_Sales_processInactiveUserScheduler tsc = new L2Q_Sales_processInactiveUserScheduler();
        tsc.execute(sc);


        Test.stopTest();
    }

}