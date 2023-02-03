@isTest(seeAllData=false)
public class MoveAccountPlansToFolderTest {
    @testSetup
    static void setupMethod() {
        string namedCredential = GsmUtilClass.getGSMSettingValue('Quip_Named_Credential');
        
        API_Connector_Object__c a = new API_Connector_Object__c();
        a.Name = namedCredential;
        a.Endpoint__c = '/1/';
        a.Named_Credential__c = 'callout:'+namedCredential;
        a.Timeout__c = 120000;
        insert a;
        
        //Account Creation
        Account acc = new Account();
        acc.Name = 'TestAccountPlan';
        acc.BillingCountry = 'India';
        acc.BillingState = 'DELHI';
        acc.website = 'www.AccountPlanWebsite.com';
        insert acc;
        
        //Account Plan Template Mapping Creation
        Account_Plan_Template_Mapping__c  mapping = new Account_Plan_Template_Mapping__c ();
        mapping.Name = 'Media & Carrier';
        mapping.Template_URL__c = 'https://www.google.com';
        insert mapping;
        
        list<Account_Plan__c> plans = new list<Account_Plan__c>();
        Account_Plan__c plan1 = new Account_Plan__c ();
        plan1.Name = 'TestAccountPlan Plan 1';
        plan1.Account__c = acc.Id;
        plan1.Plan_Type__c = 'Media & Carrier';
        plan1.Plan_Start_Date__c = System.today() - 30;
        plan1.Plan_End_Date__c = System.today() + 120;
        plan1.Quip_New_Document_URL__c = 'https://quip.com/e4V7AeaKCVmq';
        plans.add(plan1);
        insert plans;
    }
    
    @isTest static void testMoveAccountPlansToExecutiveFolder(){
        Test.setMock(HttpCalloutMock.class, new MockQuipHttpResponseGenerator());
        Test.startTest();
        String day = string.valueOf(system.now().day());
        String month = string.valueOf(system.now().month());
        String hour = string.valueOf(system.now().hour() + 1);
        String minute = string.valueOf(system.now().minute());
        String second = string.valueOf(system.now().second());
        String year = string.valueOf(system.now().year());
        String strSchedule = '0 ' + minute + ' ' + hour + ' ' + day + ' ' + month + ' ?' + ' ' + year;
        MoveAccountPlansToFolderSchedular sch = new MoveAccountPlansToFolderSchedular();
        system.schedule('Move Account Plans To Folder Test', strSchedule, sch);
        MoveAccountPlansToExecutiveFolder obj = new MoveAccountPlansToExecutiveFolder(0,null,'');
        Test.stopTest();
    }
}