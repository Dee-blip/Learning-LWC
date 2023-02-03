/*
Author          :  Vikas
Description     :  Class for bulk edit of authorized contacts
Test Class      :  

Date                 Developer                  JIRA #          Description                                                       
-----------------------------------------------------------------------------------------------------------------
22 Feb 2021          Vikas     					SOCC CAR 2 - RunBooks 2
------------------------------------------------------------------------------------------------------------------
*/
public without sharing class SC_AC_BulkEdit {
    @AuraEnabled(cacheable=true)
    public static List<sObject> getRecordsToDisplay(String parentId) {
        return [
            SELECT Id, Policy_Domain__c, Contact__c, Contact_Name__c, PD_Lead__c, Product_Interests__c, 
            Service__c, Instruct__c, Maintenance_Email__c,Contact_Name__r.name,Policy_Domain__r.name, 
            Emergency_Email__c, Emergency_Text__c, Emergency_Voice__c,Passphrase__c 
            FROM Authorized_Contact__c 
            WHERE Policy_Domain__c = :parentId
        ];
    }
    
    public class ProductInterestWrapper {
        @AuraEnabled public List<String> getProductInterests;
    }
    
    @AuraEnabled(cacheable=true)
    public static ProductInterestWrapper getProductInterestsOnLoad(){
        ProductInterestWrapper onLoadWrapper = new ProductInterestWrapper();
        List<String> options = new List<String>();
        
        Schema.DescribeFieldResult fieldResult =
            Authorized_Contact__c.Product_Interests__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        
        for( Schema.PicklistEntry f : ple)
        {
            options.add(f.getLabel());
        }   
        onLoadWrapper.getProductInterests = options;
        return onLoadWrapper;
        
    }
    
    @AuraEnabled
    public static string updateContacts(Object data) {
        system.debug('data  :  :  :'+data);
        List<Authorized_Contact__c> contactsForUpdate = (List<Authorized_Contact__c>) JSON.deserialize(
            JSON.serialize(data),
            List<Authorized_Contact__c>.class
        );
        system.debug(LoggingLevel.DEBUG,'contactsForUpdate : '+contactsForUpdate);
        try {
            update contactsForUpdate;
            return 'Success: contacts updated successfully';
        }
        catch (Exception e) {
            return 'The following exception has occurred: ' + e.getMessage();
        }
    }
}