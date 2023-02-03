@isTest 
public class MARIT_createBulkCTAControllerTest {
    
    private static Id marketoRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
    @testSetup static void dataSetup() {
        Account account = utilTestClass.CreateAccount('Test_Account');
        insert account;
        
        User marketoIntegration = [select id from user where profile.name='Marketo Integration' and isactive=true limit 1];
        System.runAs(marketoIntegration){
            Lead l = new Lead();
            l.RecordTypeId = marketoRecordTypeId;
            l.email = 'testcta@akamai.com.invalid';
            l.Associated_Account__c = account.Id;
            l.Status = 'New';
            l.firstname = 'Test';
            l.lastname = 'AccountMatchTest2';
            l.Company = 'Test Company';
            insert l;
        }
        
        System.runAs(marketoIntegration){
            Lead l1 = new Lead();
            l1.RecordTypeId = marketoRecordTypeId;
            l1.email = 'testcta1@akamai.com.invalid';
            l1.Associated_Account__c = account.Id;
            l1.Status = 'New';
            l1.firstname = 'Test';
            l1.lastname = 'AccountMatchTest2';
            l1.Company = 'Test Company';
            l1.DoNotCall = true;
            l1.HasOptedOutOfEmail = true;
            insert l1;
        }
        
        // Create contact
        Contact con = utilTestClass.CreateContact('__ Test First','__Test Contact');
        con.AccountId = account.Id;
        con.email = 'testcta@akamai.com.invalid';
        con.Description = 'test data';
        insert con; 
        
        // Create contact
        Contact con1 = utilTestClass.CreateContact('__ Test First','__Test Contact');
        con1.AccountId = account.Id;
        con1.email = 'testcta1@akamai.com.invalid';
        con1.Description = 'test data';
        con1.DoNotCall = true;
        con1.HasOptedOutOfEmail = true;
        insert con1; 
    }
    
     static testMethod void createCTAonPersonLead() 
	 {
		
		Test.StartTest();
            lead l = [Select Id from Lead where email = 'testcta@akamai.com.invalid'][0];

			PageReference pageRef = Page.createCTA;
			pageRef.getParameters().put('Id', l.Id);
			Test.setCurrentPage(pageRef);

			MARIT_createBulkCTAController bulkcta = new MARIT_createBulkCTAController();
			PageReference ctapageRef = bulkcta.dmlOperation();	
            system.assert(ctapageRef != null);
            ctapageRef = bulkcta.dmlOperation();	
            system.assert(ctapageRef == null);
		Test.StopTest();
	 }
    
     static testMethod void createCTAonContact() 
	 {
		
		Test.StartTest();
            contact con = [Select Id from Contact where email = 'testcta@akamai.com.invalid'][0];

			PageReference pageRef = Page.createCTA;
			pageRef.getParameters().put('Id', con.Id);
			Test.setCurrentPage(pageRef);

			MARIT_createBulkCTAController bulkcta = new MARIT_createBulkCTAController();
			PageReference ctapageRef = bulkcta.dmlOperation();	
            system.assert(ctapageRef != null);
            ctapageRef = bulkcta.dmlOperation();	
            system.assert(ctapageRef == null);
		Test.StopTest();
	 }
    
     static testMethod void createCTABulk() 
	 {
		
		Test.StartTest();
            contact con = [Select Id from Contact where email = 'testcta1@akamai.com.invalid'][0];
            lead l = [Select Id from Lead where email = 'testcta1@akamai.com.invalid'][0];
            Account a = [Select Id from Account where Name = 'Test_Account'][0];

			PageReference pageRef = Page.createCTA;
			pageRef.getParameters().put('Id', con.Id+','+l.Id+','+a.Id);
			Test.setCurrentPage(pageRef);

			MARIT_createBulkCTAController bulkcta = new MARIT_createBulkCTAController();
			PageReference ctapageRef = bulkcta.dmlOperation();	
            system.assert(ctapageRef == null);
		Test.StopTest();
	 }

}