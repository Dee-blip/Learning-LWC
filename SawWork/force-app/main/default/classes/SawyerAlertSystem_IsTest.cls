@isTest(seeAllData = false)
public class SawyerAlertSystem_IsTest {
    @testsetup
    public static void testSetup(){
        Beep__c beep = new Beep__c (fingerprint__c = 'test' , Investigation_Notification_Channel__c = 'test@akamai.com' , Investigation_Status__c= 'Pending');
        insert beep;
        SawedLawg__c sl = new SawedLawg__c (Beep__c = beep.id, method__c = 'test');
        insert sl;
        Mulesoft_Polling__c mp = new Mulesoft_Polling__c (Beep__c = beep.id, Unique_Key__c = 'test');
        insert mp;
        Callout_Log__c cl = new Callout_Log__c (Beep__c = beep.id, Response_Body__c = 'test', Response_Status__c= 'test');
        insert cl;
        
    }
    
    @isTest
    public static void sawyerAlerts(){
        test.startTest();
        Database.executeBatch(new SawyerAlertSystem());
        test.stopTest();
    }

}