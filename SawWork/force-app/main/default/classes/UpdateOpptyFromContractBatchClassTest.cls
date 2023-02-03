@isTest(seeAllData=false)
public with sharing class UpdateOpptyFromContractBatchClassTest {
    
    static User dmlUser = utilTestClass.getTestRunUser();
   
    
    @TestSetup
    static void setup(){
        
        system.runAs(dmlUser){
        List<Account> partnerAccountList = SObjectFactory.createPartnerAccounts(1);
    //partnerAccountList.remove(1);
     List<User> partnerUsers = SObjectFactory.createPartnerUsers(partnerAccountList);
        
		//User anyUser = utilTestClass.CreateUser('SysAdmin', 'Worldwide', 'System Administrator');
		       
        //Account acc = new Account(Name='Test Account', BillingCountry='USA', BillingPostalCode='67589', Type='Indirect Customer - Active',No_Rebate_Required__c = false, POA_Email_List__c = 'test@test.com' );
        //insert acc;
        
        
        
           // List<User> PartnerUsers=utilTestClass.createPartnerUsers(1,acc.id);
        	//User partner=PartnerUsers[0];
       
            
        
        

       /* Contact con = new Contact(LastName ='testCon',AccountId = acc.Id);
		insert con;
        System.runAs(dmlUser) {
             anyUser.Email = 'test@akamai.com';
             anyUser.Isactive=true;
             anyUser.ContactId = con.Id;
             insert anyUser;
        }
        
         AccountTeamMember atm = new AccountTeamMember();
            atm.AccountId = acc.Id;
            atm.UserId = anyUser.Id;
            atm.TeamMemberRole = 'Partner';
            insert atm;
        */

        Opportunity newOpp = new Opportunity();
        newOpp.AccountId =partnerAccountList.get(0).Id;
        newOpp.Name = 'Test Opp';
        newOpp.StageName = 'Closed Won';
        newOpp.Validation_Override__c = true;
        newOpp.Deal_Reg_Account_Status__c = 'New Account';
        newOpp.Registration_Status__c = 'Approved';
        newOpp.Deal_Registration_Approved_Date__c = Date.today();
        newOpp.Validation_Override__c = true;
		newOpp.CloseDate = Date.today().addMonths(4);
        newOpp.Partner_Involved__c  = partnerAccountList.get(0).Id;
        insert newOpp;
        
        
       OpportunityTeamMember otm=new OpportunityTeamMember();
            otm.TeamMemberRole='Partner';
            otm.UserId=partnerUsers.get(0).id;
            otm.OpportunityId=newOpp.id;
            otm.Validation_Override__c = true;
        	insert otm;
           
    

        Merge_Contract_Header__c merge_contract = new Merge_Contract_Header__c();
            merge_contract.Name                       ='2Test Merge Contract-19';
            merge_contract.Contract_Id__c             ='2Test-123-19';
            merge_contract.Original_Contract_Id__c    ='2Test-123-19';
            merge_contract.Account_Name__c            = partnerAccountList.get(0).Id;
            merge_contract.Locked__c                  = true;
            merge_contract.Cancellation_Date__c       = Null;
            merge_contract.Contract_Transferred_To__c = Null;
            merge_contract.Is_COB_Created__c          = False;
            merge_contract.Effective_Start_Date__c    = system.Today().addDays(-14);
            merge_contract.Effective_End_Date__c      = system.Today().addMonths(6);
            merge_contract.AKAM_Created_Date__c       = system.Today();
            merge_contract.Active__c                  = true;
            
            merge_contract.sync_needed__c             = true;

        insert merge_contract;
        merge_contract.Opportunity_Name__c        = newOpp.id;
        update merge_contract;

    }
    }

    static testmethod void test() {        
        Test.startTest();
        updateOpptyFromContractBatchClass upfcb = new updateOpptyFromContractBatchClass();
        Id batchId = Database.executeBatch(upfcb);
        Test.stopTest();
        // after the testing stops, assert records were deleted properly
        //System.assertEquals(0, [select count() from ContentVersion where isDuplicate__c = true]);

    
       
        
    }
}