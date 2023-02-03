@isTest
public class SC_AccountDepartmentTriggerHandlerTest {
    public static Account acc;
    public static Account_Department__c ad;

	@testSetup
    public static void testData(){
        utilTestClass.createCustomSettings();
        acc = utilTestClass.CreateAccount('TestSepcialEscalationAccount');   
        acc.Support_Advocacy_Special_Escalation__c = true;
        acc.Support_Level__c='Standard';
        acc.BillingCountry = 'India';
        insert acc;
        AccountTeamMember atm = utilTestClass.CreateAccountTeamMember(acc.id, userinfo.getuserId());
        atm.TeamMemberRole = 'PS - Primary';
        insert atm;
        ad = new Account_Department__c();
        ad.Account_Name__c = acc.Id;
        ad.Name = 'test';
        System.runAs(new User(Id = userInfo.getuserId())){
            insert ad;
        }
        
        
    }
    
    public testmethod static void testDuplicateRecord(){
        acc = [select id from account limit 1];
        ad = new Account_Department__c();
        ad.Account_Name__c = acc.Id;
        ad.Name = 'test';
        try{
            insert ad;
        } Catch(exception e){}
        System.assertEquals(1, [Select Id from Account_Department__c].size());
    }
    
    
}