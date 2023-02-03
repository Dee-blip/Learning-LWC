@isTest
public class MARIT_HelloAkamaiTriggerHandlerTest {
    @isTest
    public static void positiveTest(){
        Account acc = utilTestClass.CreateAccount('__Test Account');
        insert acc;
        
        Contact con = utilTestClass.CreateContact('__ Test First','__Test Contact');
        con.AccountId = acc.Id;
        con.email = 'testHelloAkamai@akamai.com';
        insert con;
        
        List<Hello_Akamai_Activity__c> activityList = new List<Hello_Akamai_Activity__c>();
        Hello_Akamai_Activity__c acRec= new Hello_Akamai_Activity__c();
        acRec.Contact__c=con.Id;
        acRec.Event__c='TarballDeployed';
        activityList.add(acRec);
        
        Hello_Akamai_Activity__c acRec2= new Hello_Akamai_Activity__c();
        acRec2.Contact__c=con.Id;
        acRec2.Event__c='TarballDeployed';
        activityList.add(acRec2);
        
        Hello_Akamai_Activity__c acRec3= new Hello_Akamai_Activity__c();
        acRec3.Contact__c=con.Id;
        acRec3.Event__c='Activation';
        activityList.add(acRec3);
        
        Hello_Akamai_Activity__c acRec4= new Hello_Akamai_Activity__c();
        acRec4.Contact__c=con.Id;
        acRec4.Event__c='Activation';
        activityList.add(acRec4);
        
        Hello_Akamai_Activity__c acRec5= new Hello_Akamai_Activity__c();
        acRec5.Contact__c=con.Id;
        acRec5.Event__c='Login';
        activityList.add(acRec5);
        
        insert activityList;
        List<Contact> conList = [Select Id, HelloAkamai_Weekly_Activation__c,HelloAkamai_Cumulative_Activation__c,HelloAkamai_Cumulative_Tarballs__c,HelloAkamai_Last_Login_Date__c,HelloAkamai_Weekly_Logins__c,HelloAkamai_Weekly_Tarballs__c from Contact where email = 'testHelloAkamai@akamai.com'];
        System.assert(conList.size() > 0 , 'Contact should be present');
        System.assertEquals(2, conList[0].HelloAkamai_Weekly_Activation__c, 'Weekly activation count mismatch');
        System.assertEquals(2, conList[0].HelloAkamai_Cumulative_Activation__c, 'Cumulative activation count mismatch');
        System.assertEquals(2, conList[0].HelloAkamai_Weekly_Tarballs__c, 'Cumulative tarballs count mismatch');
        System.assertEquals(2, conList[0].HelloAkamai_Cumulative_Tarballs__c, 'Cumulative tarballs count mismatch');
        System.assertEquals(1, conList[0].HelloAkamai_Weekly_Logins__c, 'Weekly logins count mismatch');
    }
}