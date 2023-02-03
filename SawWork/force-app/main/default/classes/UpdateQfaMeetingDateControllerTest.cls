@isTest
private class UpdateQfaMeetingDateControllerTest {
	
    static testmethod void testUpdateQfaMeetingDateController()
    {
    	System.runAs(utilTestClass.getTestRunUser())
        {
        
        UpdateQfaMeetingDateController controller1 = new UpdateQfaMeetingDateController();
        Map<String,GSM_Settings__mdt> generalTestcaseCustomSettings = GsmUtilClass.getGSMSettingValue();
    	User accOwnerUser = utilTestClass.CreateUser('newUser', generalTestcaseCustomSettings.get('User_Role').Value__c, 'Sales Operations');
		insert accOwnerUser;		
		Account_Reassignment_Rule__c rule = utilTestClass.CreateAccountReassignmentRule('__TestRule', accOwnerUser.Id, generalTestcaseCustomSettings.get('User_Role').Value__c);
		insert rule;
    	
    	Account acc = utilTestClass.CreateAccount('__Test Account');
		acc.OwnerId = accOwnerUser.Id;
		insert acc;
		Contact con = utilTestClass.CreateContact('__Test Contact FirstName', '__Test Contact LastName');
        con.AccountId = acc.Id;		
		insert con;
		Lead lead = utilTestClass.CreateLead();
        lead.Status = 'Open';
        lead.Disposition__c = 'New';
        lead.Product_line__c='Aura';
        lead.Associated_Contact__c = con.Id;
		lead.LastName = 'Test Lead LastName';
		lead.Company = 'Test Lead Update QFA Company';
		insert lead;
		Opportunity oppty = utilTestClass.CreateOpportunity('__Test Oppty', '1-Create');
		oppty.AccountId = acc.Id;
		oppty.RecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('AWE Opportunities').getRecordTypeId();		
		oppty.CloseDate = Date.today().addMonths(4);
		oppty.Associated_Lead__c = lead.Id;
		insert oppty;		
		
		lead.Associated_Opportunity__c = oppty.Id;
		update lead;
		
		Test.startTest();
		PageReference qfaUpdatePage = Page.UpdateQfaMeetingDate;
		qfaUpdatePage.getParameters().put('id', lead.Id);
		Test.setCurrentPageReference(qfaUpdatePage);
		
		UpdateQfaMeetingDateController controller = new UpdateQfaMeetingDateController();
		controller.lead.QFA_Meeting_Date__c = Date.today();
		controller.save();
		Test.stopTest();
		
		// Refresh the Oppty and Lead
		oppty = [select Id, Qfa_Meeting_Date__c from Opportunity where Id = :oppty.Id][0];
		lead = [select Id, Qfa_Meeting_Date__c from Lead where Id = :lead.Id][0];
		
		// Verify the changes
		system.assertEquals(oppty.Qfa_Meeting_Date__c, Date.today());
		system.assertEquals(lead.Qfa_Meeting_Date__c, Date.today());
        }
		    	
    } 
    
    static testmethod void testInactivateOldCampaigns()
    {
    	System.runAs(utilTestClass.getTestRunUser())
        {
            Campaign cmpgn = utilTestClass.CreateCampaign('__ Test Cmpgn');
            cmpgn.AKAM_System__c = '';
            cmpgn.AKAM_Created_By__c = '';
            cmpgn.AKAM_Created_Date__c = null;
            cmpgn.IsActive = true;
            cmpgn.Active_Duration__c = 'As Per End Date';
            cmpgn.EndDate = Date.today()-1;
            insert cmpgn; 
            
            InactivateOldCampaigns.InactivateOldCampaigns();
        }
    }
}