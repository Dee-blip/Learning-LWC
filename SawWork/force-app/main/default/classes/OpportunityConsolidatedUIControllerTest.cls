/**
   History
      
      --Developer       --Date         --Description        --Story
      Ruchika sharma    10/05/2017     Created this Class   SFDC-1548
        
*/
@isTest
private class OpportunityConsolidatedUIControllerTest {
	
	static User dmlUser = new User(id=UserInfo.getUserId());
    static
    {
      utilTestClass.insertCustomSettings();
    } 
    @testSetup static void createTestData() {
		Account acc = utilTestClass.CreateAccount('testAccConsolidatedUI');
		insert acc;
		Contact con = utilTestClass.CreateContact('test', 'consolidation');
		con.accountId = acc.id;
		insert con;
		Task tsk = new Task(WhoId = con.Id,Subject = '__Test Subject');
		
		Event tesk = new Event(WhoId = con.Id,Subject = '__Test Subject',ActivityDatetime= datetime.now(),DurationInMinutes = 60);
		Campaign camp = utilTestClass.CreateCampaign('test camp');
		insert camp;
		Lead lead = utilTestClass.CreateLead();
		lead.Associated_Contact__c = con.id;
		lead.Associated_Account__c = acc.id;
		//lead.Campaign = camp;
		System.runAs(dmlUser){
			insert lead;
			insert tsk;
			insert tesk;
		}
		insert utilTestClass.CreateCampaignMember(lead.id, camp.id);
		Opportunity opp = utilTestClass.CreateOpportunity('testOpptyForConsolidatedView','1. Identify Need');
		opp.CloseDate = Date.today().addDays(60);
		opp.stagename = '1. Identify Need';
		opp.accountId= acc.id;
		opp.associated_lead__c = lead.id;
		opp.campaignid = camp.id;
		insert opp;
		
		//Test.startTest();
	
		//Test.stopTest();
		
		
	}
	
	@isTest static void test_method_one() {
		// Implement test code
		Opportunity oppty =[select id,Associated_Lead__c,Associated_Lead__r.Associated_Contact__c,campaignId from Opportunity where Name = 'testOpptyForConsolidatedView'];
		PageReference pageRef = Page.OpportunityConsolidatedUIPage;
        Test.setCurrentPageReference(pageRef);
		ApexPages.StandardController sc = new ApexPages.StandardController(oppty);
		OpportunityConsolidatedUIController testController = new OpportunityConsolidatedUIController(sc);
		OpportunityConsolidatedUIController.getContact(oppty.Associated_Lead__c);
		OpportunityConsolidatedUIController.getCampaign(oppty.campaignId);
		OpportunityConsolidatedUIController.getRecords(oppty.Associated_Lead__r.Associated_Contact__c,1,2,0,0);
	}
	
	
}