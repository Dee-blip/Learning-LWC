@isTest
private class PartnerAlertPageControllerTest {

	//static User
    static User dmlUser = utilTestClass.getTestRunUser();
   
    @isTest
    public static void testcheckForRenewal(){
        User partnerUser = new User();
        Contact con = null;
        Opportunity opp = null;
        System.runAs(dmlUser){
            List<Account> partnerAccount = SObjectFactory.createPartnerAccounts(1);
            partnerAccount[0].Rebate_TC_Status__c = '';
            update partnerAccount;
            List<User> partnerUserList =  SObjectFactory.createPartnerUsers(partnerAccount);
            partnerUser = partnerUserList.get(0);
            con = [Select id, name, AccountId, FirstName, LastName, Email, MailingCountry from Contact where id = :partnerUser.contactId][0];
            con.isRebateTCToShow__c = false;
            update con;
            
            opp = utilTestClass.CreateOpportunity('__Test Oppty','1-Create');
            opp.AccountId = partnerAccount[0].Id;
            opp.CloseDate = Date.today().addDays(30); 
            insert opp;
        }
        
        System.runAs(partnerUser){
            ApexPages.currentPage().getParameters().put('id',opp.Id);
            
            ApexPages.StandardController sc = new ApexPages.StandardController(con);
            PartnerAlertPageController papc = new PartnerAlertPageController(sc);
            papc.checkForRenewal();
        }
    }
}