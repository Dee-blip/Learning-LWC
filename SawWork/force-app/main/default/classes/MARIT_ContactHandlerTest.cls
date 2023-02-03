@isTest
public class MARIT_ContactHandlerTest {
    
    private static Id marketoRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
    @testSetup static void dataSetup() {
        Account account = utilTestClass.CreateAccount('Test_Account');
        insert account;
        
        User marketoIntegration = [select id from user where profile.name='Marketo Integration' and isactive=true limit 1];
        System.runAs(marketoIntegration){
            Lead l = new Lead();
            l.RecordTypeId = marketoRecordTypeId;
            l.email = 'testApi@akamai.com.invalid';
            l.Associated_Account__c = account.Id;
            l.Status = 'New';
            l.firstname = 'Test';
            l.lastname = 'AccountMatchTest2';
            l.Company = 'Test Company';
            l.Lead_Qualification_Stage__c ='Qualified Lead - Warm';
            insert l;
        }
    }
    
    @isTest static void convertLead() {
        Contact con = MARIT_ContactHandler.convertExisitingLead('testApi@akamai.com.invalid');
        Lead l = [Select id,convertedcontactId  from Lead where email = 'testApi@akamai.com.invalid' limit 1];
        System.assertEquals(con.Id,l.convertedcontactId);
        
        Contact con1 = MARIT_ContactHandler.convertExisitingLead('');
        System.assertEquals(con1,null);
        
        Contact con2 = MARIT_ContactHandler.convertExisitingLead('t@t.com');
        System.assertEquals(con2,null);
    }    

}