/**
   @author: Nagaraj Desai
   MOB-276, 281 : Opportunity Creation for SF1
 * History:
 * =========================
 * Developer        Date        Description

   Nagaraj Desai    22/Nov/17        Added this class for MOB-276, 281.
 **/

public without sharing class SF1_NewOpportunityMobileController {

        @AuraEnabled
        public static String loadPicklistValues(String sobjectName, String picklistFieldName) {
                return GSMLite_UtilClass.populatePickListWithLabelAndValues(sobjectName, picklistFieldName);
        }

        @AuraEnabled
        public static String getAccountDetails(String accountId) {
                Account accountDetails = [SELECT Id, Name, OwnerId, Owner.Name, Owner.Alias,Account_Status__c,Account_Owner_Alias__c FROM Account WHERE Id =: accountId ];
                return JSON.serialize(accountDetails);
        }

        @AuraEnabled
        public static String getDefaultUserCurrency() {
                User u = [SELECT DefaultCurrencyIsoCode FROM USER WHERE Id = :UserInfo.getUserId()];
                return String.valueOf(u.DefaultCurrencyIsoCode);
        }

        @AuraEnabled
        public static SF1_ListContractsController.ResultSetCustom getActiveContractsWithProductsByAcc(String accountJsonData, String sortField, String sortOrder) {
                return SF1_ListContractsController.getActiveContractsByAccIdPagination((Account)JSON.deserialize(accountJsonData, Account.Class), 50000, 0,  sortField, sortOrder);
        }

        @AuraEnabled
        public static SF1_CreateOpportunityController.ResultSetCustom getOpportunitiesByContractIds(String accountId, String[] contractIds, String sortField, String sortOrder) {
                return SF1_CreateOpportunityController.getOpportunitiesByContractIdsPaginated(accountId, contractIds, 50000, 0, sortField, sortOrder);
        }

        @AuraEnabled
        public static List<Renewal_Contract_Object__c> getRenewalContractsByOpttyId(String opptyId) {
                return SF1_CreateOpportunityController.getRenewalContractsByOpttyId(opptyId);
        }

        @AuraEnabled
        public static SF1_CreateOpportunityController.ResultSetCustom getOpportunitiesWithoutBL(Id accountId, String sortField, String sortOrder) {
                return SF1_CreateOpportunityController.getOpportunitiesByAccountIdPaginated(accountId, 50000, 0, sortField, sortOrder);
        }

        @AuraEnabled
        public static Opportunity createRenewalOpportunityFromContracts(String[] selectedContractIds, String selectedCurrency, Boolean isContractCurrencyMismatch, String selectedOpptyType) {
                return SF1_CreateNewOpportunityFlowController.createRenewalOpportunityFromContracts(selectedContractIds, selectedCurrency, isContractCurrencyMismatch, selectedOpptyType);
        }

        @AuraEnabled
        public static String insertNewOpportunity(String opptyJsonData) {

                String returnMessage = 'SUCCESSFUL';
                Opportunity newOppty = new Opportunity();
                try {
                        newOppty = (Opportunity)JSON.deserialize(opptyJsonData, Opportunity.Class);
                        insert newOppty;
                        returnMessage = returnMessage + ':' + newOppty.Id;
                }
                catch (Exception ex) {
                        System.debug('Opportunity Creation Failure:'+ex.getMessage());
                        returnMessage = 'FAILED:' + String.valueOf(ex);
                }
                return returnMessage;
        }

        // @AuraEnabled
        // public static Opportunity getOpportunityCurrencyValues() {
        //         return [SELECT Id, CurrencyIsoCode FROM Opportunity LIMIT 1];
        // }

}