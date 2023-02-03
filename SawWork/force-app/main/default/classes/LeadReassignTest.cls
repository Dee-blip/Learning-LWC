@isTest
private class LeadReassignTest {
	static User dmlUser = new User(id=UserInfo.getUserId());
    
    static{
      utilTestClass.insertCustomSettings();
    } 
    private static List<Lead> leads = new List<Lead>();
    @testSetup static void setupData(){
    	Account acc = utilTestClass.CreateAccount('__Test Account');
    	acc.Vertical__c = 'Gaming';
    	acc.Sub_Vertical__c = 'Console Mfs';	       	
    	insert acc;

		Contact con = utilTestClass.CreateContact('__Test Contact FirstName','__Test Contact LastName');
		con.AccountId = acc.Id;	
		con.Email = 'generictesting@generictester.com';
		System.runAs(dmlUser){
			insert con;
		}	
		Lead lead = utilTestClass.CreateLead();
		lead.Disposition__c = 'Existing Customer';
		lead.Associated_Contact__c = con.Id;
		lead.Product_line__c='Aura';	
		leads.add(lead);
		//CR 2842869 : rsharma- putting system.runAs to avoid mixed-dml exception
        User marketingOpsUser = [select id from user where profile.name='Marketing Operations' and isactive=true and title like '%Marketing%' and title like '%Director%' limit 1];
		Campaign autoConvertCampaign = (Campaign) new SObjectBuilder(Campaign.sObjectType)
	            .eagerPopulate()
	            .put(Campaign.Auto_Convert_Lead__c, true)
                .put(Campaign.Auto_Convert_Justification__c, 'TBD')
            	.put(Campaign.Sales_Approval__c, marketingOpsUser.id)
            	.put(Campaign.Marketing_Approval__c, marketingOpsUser.id)
	            .create()
	            .getRecord();
	   	Lead lead1 = utilTestClass.CreateLead();

		lead1.Disposition__c = 'Existing Customer';
		lead1.Associated_Contact__c = con.Id;
		lead1.Product_line__c='Aura';
		lead1.OwnerId = GsmUtilClass.getGSMSettingValue('LeadAutoConvert_QueueId');
		//lead1.Primary_Campaign__c = autoConvertCampaign.id;
		leads.add(lead1);
        System.runAs(dmlUser){
			insert leads;
		}
		System.runAs(dmlUser){
		List<CampaignMember> cmpgnMember = (List<CampaignMember>) new SObjectBuilder(CampaignMember.sObjectType)
		            .put(CampaignMember.CampaignId, autoConvertCampaign.Id)
		            .put(CampaignMember.Status, 'Sent')
		            .put(CampaignMember.LeadId, lead1.id)
		            .count(1)
		            .create()
		            .getRecords();
		        }
    }

	@isTest static void test_LeadReassignDetailController() {
		// Implement test code
		leads = [select id,name from lead limit 1];
		if(leads!=null && !leads.isEmpty()){
				ApexPages.StandardController sc = new ApexPages.StandardController(leads[0]);
			    LeadReassignDetailController testController = new LeadReassignDetailController(sc);
				PageReference pageRef = Page.LeadReassignDetailRedirctor;
	            Test.setCurrentPage(pageRef);
	            testController.forwardToListController();
	            //ApexPages.CurrentPage().getparameters().put('id',leads[0].id);
	        }

	}
	
	@isTest static void test_method_two() {
		// Implement test code
		leads = [select id,name from lead where Primary_Campaign__c=null];
		if(leads!=null && !leads.isEmpty()){
				ApexPages.StandardSetController sc = new ApexPages.StandardSetController(leads);
			    LeadReassignController testController = new LeadReassignController(sc);
				PageReference pageRef = Page.LeadReassign;
	            Test.setCurrentPage(pageRef);
	            List<String> leadIds = new List<String>();
	            //Mock no No Lead Found error
	            try{
	            	LeadReassignController.fetchLead(leadIds);
	            	}Catch(Exception e){
	            		system.assert(e.getMessage().contains('No Lead Found'));
	            	}
	            try{
	            	String ld='';
	            	LeadReassignController.fetchLeadQA(ld);
	            	}Catch(Exception e){
	            		system.assert(e.getMessage().contains('No Lead Found'));
	            	}
	            for(Lead lead:leads)
	            	leadIds.add(lead.id);
	            LeadReassignController.fetchLead(leadIds);
	            LeadReassignController.fetchLeadQA(leads[0].id);
	            LeadReassignController.getUIThemeDescription();
	            LeadReassignController.getLeadQueues();
	            LeadReassignController.save('assignUser','test class',leadIds,dmlUser.id);
	            leads = [select id,name,ownerId,status from lead LIMIT 20];
	            //system.assertEquals(leads[0].ownerId,dmlUser.id);
	            LeadReassignController.save('RunRules','test class',leadIds,null);
	           
	        }
	}
	@isTest static void test_Conversion() {
    test.startTest();
              List<Lead> leads = SobjectRepository.getLeads(2);
       
            
         if(leads!=null && !leads.isEmpty()){
        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(leads);
          LeadReassignController testController = new LeadReassignController(sc);
        PageReference pageRef = Page.LeadReassign;
              Test.setCurrentPage(pageRef);
              List<String> leadIds = new List<String>();

              for(Lead lead:leads){
                //lead.Status='Converted';
                leadIds.add(lead.id);
              }
              //update leads;
              try{
                 LeadReassignController.fetchLead(leadIds);
              }Catch(Exception e){
                 system.assert(e.getMessage().contains(GsmUtilClass.getGSMSettingValue('converted_leads_error')));
              }
              LeadReassignController.fetchLeadQA(leads[0].id);
              LeadReassignController.getUIThemeDescription();
              LeadReassignController.getLeadQueues();

              LeadReassignController.save('assignUser','test class',leadIds,dmlUser.id);

              try {
              	LeadReassignController.sendEmailToPartner(leads);
              	ApexPages.CurrentPage().getparameters().put('id',leads[0].id);
              } catch (Exception e) {
              	System.debug('Exception occured');
              }
        	  
          }
          test.stopTest();
  }
  
  @isTest static void test_updatePBMonthModifiedDateController() {
        //Account Creation
        List<Account> accList = new List<Account>();
        Account acc1 = utilTestClass.CreateAccount('Test Account1');
        accList.add(acc1);
        Test.startTest();
        insert accList;
        
        //Traffic_Share__c Creation
        List<Traffic_Share__c> tShareList = new List<Traffic_Share__c>();
        Traffic_Share__c tShare1 = new Traffic_Share__c();
        tShare1.Account__c = acc1.Id;
        tShareList.add(tShare1);
        insert tShareList;
        Test.stopTest();
        Test.setCurrentPage(Page.updatePBMonthModifiedDate);
        ApexPages.currentPage().getParameters().put('recordId',tShare1.Id);
        updatePBMonthModifiedDateController ob = new updatePBMonthModifiedDateController();
        ob.recordId = tShare1.Id;
        ob.init();
    }
    
    @isTest static void test_OverrideNewLeadController() {
        User partnerCommunityAdmin = [select Id from User where Profile.Name = 'Partner Marketing' and IsActive = true limit 1][0];
        Lead ld = [select Id from Lead where Disposition__c = 'Existing Customer' limit 1][0];
        Test.startTest();
        system.runAs(partnerCommunityAdmin){
            PageReference pageRef = Page.OverrideNewLead;
            Test.setCurrentPage(pageRef);
            ApexPages.StandardController sc = new ApexPages.StandardController(ld);
            OverrideNewLeadController ob = new OverrideNewLeadController(sc);
            ob.Back();
            ob.redirect();
            ob.ErrorMsg = 'Test';
            ob.severity = 'error';
        }
        system.runAs(dmlUser){
            PageReference pageRef = Page.OverrideNewLead;
            Test.setCurrentPage(pageRef);
            ApexPages.StandardController sc = new ApexPages.StandardController(ld);
            OverrideNewLeadController ob = new OverrideNewLeadController(sc);
            ob.Back();
            ob.redirect();
            ob.ErrorMsg = 'Test';
            ob.severity = 'error';
        }
        Test.stopTest();
    }

    //Marit-934 test method
    @isTest static void test_ReAssignValidationForPartnerMarketingProfile(){
        Account acc = [Select Id from Account where Vertical__c = 'Gaming' limit 1];
        Contact con = [Select Id from Contact where Email = 'generictesting@generictester.com' limit 1];
        Id akamaiRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Akamai Lead').getRecordTypeId();
        //create akamai lead
        List<Lead> leads = new List<Lead>();
        Lead al = new Lead();
        al.RecordTypeId = akamaiRecordTypeId;
        al.email = 'test2@akamai.com.invalid';
        al.Associated_Account__c = acc.Id;
        al.Status = 'New';
        al.firstname = 'Test';
        al.lastname = 'AccountMatchTest2';
        al.Company = 'Test Company';
        al.Associated_Contact__c=con.Id;
        al.Product_Line__c = 'Media';
        insert al;
        Test.startTest();
        Lead l = [Select Id from Lead where Product_Line__c = 'Media' limit 1];
        List<Id> lst = new List<Id>();
        lst.add(l.Id);
        User partnerMarketingProfile = [select Id from User where Profile.Name = 'Partner Marketing' and IsActive = true limit 1][0];
        System.runAs(partnerMarketingProfile){
            Boolean result = LeadReassignController.fetchUserProfile(lst);
            System.assert(result == false);
        }
        Test.stopTest();
    }
	
}