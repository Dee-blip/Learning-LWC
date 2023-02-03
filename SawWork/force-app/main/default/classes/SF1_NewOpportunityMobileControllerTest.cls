@isTest(seeAllData=false)
public class SF1_NewOpportunityMobileControllerTest {

    static testmethod void loadPicklistValues() {
        String pickListVals = SF1_NewOpportunityMobileController.loadPicklistValues('Opportunity', 'Deal_Type__c');

    }

    static testmethod void getDefaultUserCurrency() {
        String UserCurrency = SF1_NewOpportunityMobileController.getDefaultUserCurrency();
    }

    // static testmethod void getActiveContractsWithProductsByAcc() {
    //     Account acc = new Account();
    //     acc.Name = 'TestABC';
    //     acc.Vertical__c = 'Gaming';
    //     acc.Sub_Vertical__c = 'Console Mfs';
    //
    //     SF1_ListContractsController.ResultSetCustom rs = SF1_NewOpportunityMobileController.getActiveContractsWithProductsByAcc(JSON.serialize(acc), 'Name', 'ASC');
    // }

    static testmethod void getOpportunitiesByContractIds() {
      Account acc = new Account();
      acc.Name = 'TestABC';
      acc.Vertical__c = 'Gaming';
      acc.Sub_Vertical__c = 'Console Mfs';
      insert acc;

      String[] contractIds;
      SF1_CreateOpportunityController.ResultSetCustom rs = SF1_NewOpportunityMobileController.getOpportunitiesByContractIds(acc.Id, contractIds, 'Name', 'ASC');
    }

    static testmethod void getAccountDetails() {
      Account acc = new Account();
      acc.Name = 'TestABC';
      acc.Vertical__c = 'Gaming';
      acc.Sub_Vertical__c = 'Console Mfs';
      insert acc;

      String returnVal = SF1_NewOpportunityMobileController.getAccountDetails(acc.Id);
    }

    static testmethod void getRenewalContractsByOpttyId() {
        Account acc = new Account();
        acc.Name = 'TestABC';
        acc.Vertical__c = 'Gaming';
        acc.Sub_Vertical__c = 'Console Mfs';
        insert acc;

        Opportunity opp = new Opportunity();
        opp.Account = acc;
        opp.AccountId = acc.Id;
        opp.Name = 'OppName';
        opp.Deal_Type__c = 'Direct';
        opp.StageName = '0-Plan';
        opp.CloseDate = Date.today();
        opp.CurrencyIsoCode = 'BRL';
        insert opp;

        List<Renewal_Contract_Object__c> lt = SF1_NewOpportunityMobileController.getRenewalContractsByOpttyId(opp.Id);
    }

    static testmethod void getOpportunitiesWithoutBL(){

        Account acc = new Account();
        acc.Name = 'TestABC';
        acc.Vertical__c = 'Gaming';
        acc.Sub_Vertical__c = 'Console Mfs';
        insert acc;

        SF1_CreateOpportunityController.ResultSetCustom opptyList = SF1_NewOpportunityMobileController.getOpportunitiesWithoutBL(acc.Id,'','');
        opptyList = SF1_NewOpportunityMobileController.getOpportunitiesWithoutBL(acc.Id,'MRR__c', 'Asc');
    }

    // static testmethod void createRenewalOpportunityFromContracts() {
    //     String[] contractIds;
    //     Opportunity oppty = SF1_NewOpportunityMobileController.createRenewalOpportunityFromContracts(contractIds, 'USD', false);
    // }

    static testmethod void insertNewOpportunity(){
        Account acc = new Account();
        acc.Name = 'TestABC';
        acc.Vertical__c = 'Gaming';
        acc.Sub_Vertical__c = 'Console Mfs';
        insert acc;

        Opportunity opp = new Opportunity();

        String returnVal = SF1_NewOpportunityMobileController.insertNewOpportunity(JSON.serialize(opp));

        opp.Account = acc;
        opp.AccountId = acc.Id;
        opp.Name = 'OppName';
        opp.Deal_Type__c = 'Direct';
        opp.StageName = '0-Plan';
        opp.CloseDate = Date.today();
        opp.CurrencyIsoCode = 'BRL';

        returnVal = SF1_NewOpportunityMobileController.insertNewOpportunity(JSON.serialize(opp));

    }

}