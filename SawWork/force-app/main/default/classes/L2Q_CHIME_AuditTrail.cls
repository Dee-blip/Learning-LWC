/**
 * @description       : 
 * @author            : apyati
 * @team              : GSM
 * @last modified on  : 12-21-2021
 * @last modified by  : apyati
 * Modifications Log
 * Ver   Date         Author   Modification
 * 1.0   11-26-2021   apyati   SFDC-8654 modified grouping of trails by product/form
**/
public with sharing class L2Q_CHIME_AuditTrail {
    public L2Q_CHIME_AuditTrail() {}
    private static List<CHIME_Audit_Trail__c> getRequiredAuditTrails(String responseId) {
        List<CHIME_Audit_Trail__c> listOfAuditTrails = new List<CHIME_Audit_Trail__c>();
        for(CHIME_Audit_Trail__c eachTrail : [SELECT Id, CHIME_Response__c, CreatedById, CreatedBy.Name, CreatedDate, CurrentValue__c, isCustomerUpdated__c,CHIME_Response__r.Question_Type__c FROM CHIME_Audit_Trail__c WHERE CHIME_Response__c = :responseId ORDER BY CreatedDate DESC]) {
            if(eachTrail.CurrentValue__c != null) {
                eachTrail.CurrentValue__c = eachTrail.CurrentValue__c.stripHtmlTags();
            }
            listOfAuditTrails.add(eachTrail);
        }
        //CHIME_Response__c currentResponse = [SELECT Id, ]
        return listOfAuditTrails;
    }
    @AuraEnabled
    public static List<CHIME_Audit_Trail__c> getAuditTrails(String responseId){
        System.DEBUG('responseId : ' + responseId);
        try {
            return getRequiredAuditTrails(responseId);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static Boolean checkChimeVisiblity() {
        return !(Network.getNetworkId() != null && GSMSettings.getValue('communitiesForChimeAuditTrail').contains(String.valueOf(Network.getNetworkId())));
    }

    private static Map<String, List<CHIME_Audit_Trail__c>> getRequiredProductSpecificFormAuditTrails(String formId) {
        // List<CHIME_Product_Question__c> questionList = [SELECT Id, Question_Text__c FROM CHIME_Product_Question__c WHERE CHIME_Product__c IN 
        //                                                 (SELECT CHIME_Product__c FROM Chime_Product_Association__c WHERE CHIME__c = :formId)];
        Map<String, List<CHIME_Audit_Trail__c>> mapOfProductSpecificTrails = new Map<String, List<CHIME_Audit_Trail__c>>();
        for(CHIME_Audit_Trail__c eachTrail : [SELECT Id,  PreviousValue__c, CurrentValue__c,isCustomerUpdated__c,
                                                CreatedById, CreatedBy.Name,CreatedDate, 
                                                CHIME_Response__c,CHIME_Response__r.CHIME_Product_Question__r.Question_Text__c,
                                                CHIME_Response__r.CHIME_Product_Question__r.CHIME_Product__r.Product_Name__c,CHIME_Response__r.Question_Type__c,
                                                CHIME_Product__c,CHIME_Product__r.CHIME_Product__r.Product_Name__c,
                                                CHIME__c, Field__c,Source__c
                                                FROM CHIME_Audit_Trail__c WHERE CHIME__c = :formId
                                                ORDER BY CreatedDate DESC])
                                                //WHERE CHIME_Response__c IN (SELECT Id FROM CHIME_Response__c WHERE CHIME__c = :formId)ORDER BY CreatedDate DESC])
        {
            List<CHIME_Audit_Trail__c> productSpecificTrails = new List<CHIME_Audit_Trail__c>();
            String productName ='';
            if(eachTrail.CHIME_Response__c != null && eachTrail?.CHIME_Response__r?.CHIME_Product_Question__r?.CHIME_Product__r?.Product_Name__c !=null ){
                eachTrail.CHIME_Response__r.CHIME_Product_Question__r.Question_Text__c = eachTrail.CHIME_Response__r.CHIME_Product_Question__r.Question_Text__c.stripHtmlTags();
                if(eachTrail.PreviousValue__c != null) {
                    eachTrail.PreviousValue__c = eachTrail.PreviousValue__c.stripHtmlTags();
                }
                if(eachTrail.CurrentValue__c != null) {
                    eachTrail.CurrentValue__c = eachTrail.CurrentValue__c.stripHtmlTags();
                }
                productName = eachTrail.CHIME_Response__r.CHIME_Product_Question__r.CHIME_Product__r.Product_Name__c;
            }
            else if(eachTrail.CHIME_Product__c !=null && eachTrail.Field__c!=null){
                 productName = eachTrail.CHIME_Product__r.CHIME_Product__r.Product_Name__c;
            }else if(eachTrail.Source__c=='CHIME Form' && eachTrail.Field__c!=null){
                 productName= 'CHIME Form';
            }
            
            if(productName !=''){
                if(mapOfProductSpecificTrails.containsKey(productName)) {
                    productSpecificTrails = mapOfProductSpecificTrails.get(productName);
                }
                productSpecificTrails.add(eachTrail);
                mapOfProductSpecificTrails.put(productName, productSpecificTrails);
            }
            
            
        }
        return mapOfProductSpecificTrails;
    }

    @AuraEnabled
    public static Map<String, List<CHIME_Audit_Trail__c>> getProductSpecificFormAuditTrails(String formId){
        System.DEBUG('formId : ' + formId);
        try {
            return getRequiredProductSpecificFormAuditTrails(formId);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}