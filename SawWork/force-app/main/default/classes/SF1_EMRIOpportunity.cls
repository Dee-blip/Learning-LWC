/**
   @author: Nagaraj Desai
   MOB-262 : Created SF1_EMRIOpportunity class : This class contains refreshBaseline Method for SF1.

 * History:
 * =========================
 * Developer        Date        Description

   Nagaraj    21/Dec/17         added   refreshBaselineSF1 function as part of MOB-344
   Saurabh    24 June 202       SFDC-6907 Allow selective contract disassociation
 **/

public without sharing class SF1_EMRIOpportunity {
        public class ResultSetCustom {
                @AuraEnabled public Boolean errorOccured {get; set;}
                @AuraEnabled public String returnMessage {get; set;}

                public ResultSetCustom(){
                }
                public ResultSetCustom(Boolean errorOccured, String returnMessage) {
                        this.errorOccured = errorOccured;
                        this.returnMessage = returnMessage;
                }
        }

        @AuraEnabled
        public static String executeRefreshBaselineSF1(String opportunityID) {


                ResultSetCustom initialMessage;
                if(OpportunityUtilClass.isClosed(opportunityID)) {
                        initialMessage = new ResultSetCustom(true, String.valueOf(Label.Opportunity_is_in_Closed_Stage));
                        return JSON.serialize(initialMessage);
                }

                if(!OpportunityUtilClass.hasAssociatedRenewalContract(opportunityID)) {
                        initialMessage = new ResultSetCustom(true, String.valueOf(GsmUtilClass.getErrorPageSettingValue('NoContractAssociatedError')));
                        return JSON.serialize(initialMessage);
                }
                initialMessage = new ResultSetCustom(false, 'Are you sure you want to refresh baseline?');
                return JSON.serialize(initialMessage);
        }

        @AuraEnabled
        public static String refreshBaselineSF1(String contractID, String opportunityID) {

                 GsmUtilClass.disableLossReasonValidation= false; //SFDC-8121

                system.debug('Inside refresh method ' +contractID +' Op ' +opportunityID );
                Opportunity oppty = [SELECT CurrencyIsoCode, CloseDate FROM Opportunity WHERE Id = :opportunityID];
                String opptyCurrency = oppty.CurrencyIsoCode;
                Date opptyCloseDate = oppty.CloseDate;
                List<String> orignalContractIds = new List<String>();
                Set<String> contractCurrencySet = new Set<String>();
                for(Renewal_Contract_Object__c contractObj: [Select Name,Contract__r.Currency__c from Renewal_Contract_Object__c where Opportunity__c =:opportunityID])
                {
                        orignalContractIds.add(contractObj.Name);
                        contractCurrencySet.add(contractObj.Contract__r.Currency__c);
                }

                CreateRenewalOpptyWithMultipleContracts roc = new CreateRenewalOpptyWithMultipleContracts(orignalContractIds);
                roc.setOpportunityCurrency(opptyCurrency);
                roc.setContractCurrency(contractCurrencySet);
                roc.setOpportunityCloseDate(opptyCloseDate);
                roc.refreshOpportunityProducts(opportunityID);
                ResultSetCustom returnVal = new ResultSetCustom();
                if(roc.errorOccured) {
                        returnVal = new ResultSetCustom(roc.errorOccured, 'An error occured while refreshing baseline.');
                }
                else {
                        returnVal = new ResultSetCustom(roc.errorOccured, 'Baseline sucessfully refreshed.');
                }
                return JSON.serialize(returnVal);
        }

        @AuraEnabled
        public static String isDissociableSF1(String opportunityID) {

                ResultSetCustom initialMessage;
                if(!GsmUtilClass.getGSMSettingValue('DissociateContractAllowedProfiles').contains(UserInfo.getProfileId())) {
                        initialMessage = new ResultSetCustom(true, 'You do not have sufficient privileges to perform this action.');
                        return JSON.serialize(initialMessage);
                }
                if(!OpportunityUtilClass.hasAssociatedRenewalContract(opportunityID)) {
                        initialMessage = new ResultSetCustom(true, String.valueOf(GsmUtilClass.getErrorPageSettingValue('NoContractAssociatedError')));
                        return JSON.serialize(initialMessage);

                }
                if(OpportunityUtilClass.isClosed(opportunityID)) {
                        initialMessage = new ResultSetCustom(true, String.valueOf(Label.Opportunity_is_in_Closed_Stage));
                        return JSON.serialize(initialMessage);

                }
                initialMessage = new ResultSetCustom(false, 'Disassociating will delete all the Contract(s) and it’s Baseline Product(s). Do you want to continue?');
                return JSON.serialize(initialMessage);
        }

        @AuraEnabled
        public static String disassociateContractSF1(String opportunityID) {

                List<OpportunityLineItem> listOfOpportunityLineItemsToDelete = new List<OpportunityLineItem>();

                for(OpportunityLineItem lineItem : [Select Average_Renewal_Commit_MRR__c, Average_Renewal_Usage_MRR__c from OpportunityLineItem where OpportunityId =:opportunityID AND (Average_Renewal_Commit_MRR__c!=null OR Average_Renewal_Usage_MRR__c!=null)]) {
                        listOfOpportunityLineItemsToDelete.add(lineItem);
                }

                DMLResults results = new DMLResults(true);

                Opportunity opportunityObject = new Opportunity(Id=opportunityID,Renew_Contract_Id_Text__c ='');
                results.clear();
                results.dmlUpdate(new List<Opportunity>{opportunityObject});
                results.withClassName('DisassociateContractPageClass').insertRecordsInErrorLog();
                ResultSetCustom returnVal = new ResultSetCustom();
                if(results.failureCount>0 ) {
                        returnVal = new ResultSetCustom(true, 'An error occured while updating opportunity.' );
                        return JSON.serialize(returnVal);
                }

                if(listOfOpportunityLineItemsToDelete.size()>0) {
                        results.clear();
                        results.dmldelete(listOfOpportunityLineItemsToDelete);
                        results.withClassName('DisassociateContractPageClass').insertRecordsInErrorLog();
                        if(results.failureCount>0) {
                                returnVal = new ResultSetCustom(true, 'An error occured while deleting the opportunity products.');
                                return JSON.serialize(returnVal);
                        }
                }

                List<Renewal_Contract_Object__c>renewalContracts = [Select Id from Renewal_Contract_Object__c where Opportunity__c = :opportunityID];

                if(renewalContracts.size()>0) {
                        results.clear();
                        results.dmldelete(renewalContracts);
                        results.withClassName('DisassociateContractPageClass').insertRecordsInErrorLog();
                        if(results.failureCount>0) {
                                returnVal = new ResultSetCustom(true, 'An error occured while deleting the associated contracts.');
                                return JSON.serialize(returnVal);
                        }

                }

                returnVal = new ResultSetCustom(false, 'Contract(s) are successfully disassociated from opportunity.');
                return JSON.serialize(returnVal);
        }
    
    @AuraEnabled
    public static Map<String,String> getProductNames(List<String> akamProductIds) {
        Map<String, String> productMap = new Map<String, String>();
        for(PricebookEntry pbe : [Select Name,product2.Akam_Product_Id__c from PricebookEntry where product2.Akam_Product_Id__c IN : akamProductIds]){
            productMap.put(pbe.product2.Akam_Product_Id__c,pbe.Name);
        }
        return productMap;
    }
    
    // SFDC-6907 Get all Contracts associated with this Opportunity
    @AuraEnabled
    public static List<Merge_Contract_Header__c> getAssociatedContracts(String opportunityID) {
        List<String> associatedContractNames = new List<String>();
        for( Renewal_Contract_Object__c contract: [select id,contract__r.original_contract_id__c 
                                                   from Renewal_Contract_Object__c 
                                                   where opportunity__c =: opportunityID]){
                                                       associatedContractNames.add(contract.contract__r.original_contract_id__c);                                               
                                                   }
     
        return [select Id,name,Contract_Type__c,Parent_Contract__c,Parent_Contract__r.Original_Contract_Id__c,Order_Id__c,Parent_Account_Name__c,Currency__c,
                Parent_Account_Name__r.Name,Solution_Set__c,Effective_Start_Date__c,CurrencyIsoCode,Account_Name__c,Account_Name__r.Id,
                Account_Name__r.Name ,Active__c ,Effective_End_Date__c , Original_Contract_Id__c,
                Opportunity_Name__r.currencyIsoCode,Opportunity_Name__r.Deal_Type__c,Opportunity_Name__r.Partner_Involved__c,
                Contract_Product_Count__c,(Select Id,CurrencyIsoCode,Average_Renewal_Commit_MRR__c,
                                           Average_Renewal_Usage_MRR__c,Forecast_Product_Id__c 
                                           from Contract_Products__r) 
                from Merge_Contract_Header__c where original_contract_id__c in :associatedContractNames];
        
    }

    // SFDC-6907 Remove selective COntracts by 1. Removing all 2. Selectively adding the remaning ones
    @AuraEnabled
    public static String disassociateContracts(String opportunityID, List<Merge_Contract_Header__c> contractsToRetain) {
       
        GsmUtilClass.disableLossReasonValidation= false; //SFDC-8121

        ResultSetCustom returnVal = new ResultSetCustom(false, '');
        try{
            String errorMessageRemove = disassociateContractSF1( opportunityID);
            if(contractsToRetain.size()>0 && errorMessageRemove.contains('errorOccured":false')){
                Opportunity oppty = [SELECT CurrencyIsoCode, CloseDate FROM Opportunity WHERE Id = :opportunityID];
                String opptyCurrency = oppty.CurrencyIsoCode;
                Date opptyCloseDate = oppty.CloseDate;
                
                String errorMessageAdd = SF1_Controller_OpportunityGetBaseLine.getContractBaseline(contractsToRetain, 
                                                                                                   opptyCurrency, 
                                                                                                   opportunityID, 
                                                                                                   opptyCloseDate);
                if(!errorMessageAdd.contains('error')){
                    returnVal = new ResultSetCustom(false, 'Selected Contracts have been disassociated from this Opportunity');    
                }
                else{
                    returnVal = new ResultSetCustom(true, errorMessageAdd);     
                }
            }else{
                if(errorMessageRemove.contains('errorOccured":false')){
                    returnVal = new ResultSetCustom(false, 'All Contracts have been disassociated from this Opportunity'); 
                }else{
                    returnVal = new ResultSetCustom(true, errorMessageRemove); 
                }
                
            }
        }
        catch(Exception ex){
            returnVal = new ResultSetCustom(false, 'Error :'+ex.getStackTraceString()+' '+ ex.getMessage());
            return JSON.serialize(returnVal);
        }
        
        
        return JSON.serialize(returnVal);
    }

}