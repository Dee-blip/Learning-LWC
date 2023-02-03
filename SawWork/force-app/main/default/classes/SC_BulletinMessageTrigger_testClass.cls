@isTest(seeAllData = false)
public class SC_BulletinMessageTrigger_testClass{
    public SC_BulletinMessageTrigger_testClass(){
    }
    
    public static testMethod void createBUlletinMessages(){
        SC_BulletinMsg__c c = new SC_BulletinMsg__c();
        DateTime currentTime = system.now();
        c.start_date__c = currentTime.adddays(-1);
        c.message_text__c = 'Test data. ';
        c.end_date__c = currentTime.addDays(2);
        insert c;
        SC_HomePageBulletinCtrl v = new SC_HomePageBulletinCtrl();
        v.loadScrollMessage();
        
    }
    
}