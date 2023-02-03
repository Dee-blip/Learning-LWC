/* Author : Smore */
@isTest
private class UpdateLeadStatusBatchTestClass {
    
	static void createData(){
		System.runAs(utilTestClass.getTestRunUser())
        {
            utilTestClass.insertCustomSettings();
        }
        
        Account acc = utilTestClass.CreateAccount('__Test Account');
        acc.Vertical__c = 'Gaming';
        acc.Sub_Vertical__c = 'Console Mfs';
        insert acc;
        
        Contact con = utilTestClass.CreateContact('__Test Contact FirstName','__Test Contact LastName');
        con.AccountId = acc.Id; 
        insert con;
        
        Lead lead = utilTestClass.CreateLead();
        lead.Associated_Contact__c = con.Id;     
        lead.Disposition__c='Existing Customer';
        lead.Product_line__c='Aura';            
        insert lead;
        
        Campaign cmpgn = utilTestClass.CreateCampaign('__ Test Cmpgn');
        insert cmpgn;
        
        CampaignMember cmpgnMember = new CampaignMember();
        cmpgnMember.ContactId = con.Id;
        cmpgnMember.CampaignId = cmpgn.Id;
        cmpgnMember.Status = 'Meeting';
        insert cmpgnMember;
        
        CampaignMember cmpgnMember1 = new CampaignMember();
        cmpgnMember1.leadId = lead.Id;
        cmpgnMember1.CampaignId = cmpgn.Id;
        cmpgnMember1.Status = 'Member';
        insert cmpgnMember1;
 
        
    }
    
    @isTest static void test_method_one() {
		// Implement test code
		createData();
		Test.startTest();
        UpdateLeadStatusBatchClass bClass = new UpdateLeadStatusBatchClass();
        Database.executeBatch(bClass);

        Test.stopTest();
	}
	
	
}