public without sharing class AccSalesPlayAssociationTriggerHandler extends ApexTriggerHandlerAbstractClass{
	
    public AccSalesPlayAssociationTriggerHandler(){
        
    }
    
    public override void beforeInsertBeforeUpdateTrigger(){
        List<Account_Sales_Play_Association__c> dsrTriggerNew = (List<Account_Sales_Play_Association__c>)newList;
        system.debug('Akam Creation');
        ByPassAndLimitUtils.setAkamField(Trigger.isInsert, Trigger.isUpdate, dsrTriggerNew);
    }
    
    public override void afterInsertAfterUpdateTrigger() {

        System.debug('This is after insert and after update.');
        List<Account_Sales_Play_Association__c> ASPATriggerNew = 
            (List<Account_Sales_Play_Association__c>)newList;
        List<Account_Sales_Play_Association__c> ASPATriggerOld = 
            (List<Account_Sales_Play_Association__c>)oldList;
        Map<Id,Account_Sales_Play_Association__c> ASPATriggerNewMap = 
            (Map<Id,Account_Sales_Play_Association__c>)newMap;
        Map<Id,Account_Sales_Play_Association__c> ASPATriggerOldMap = 
            (Map<Id,Account_Sales_Play_Association__c>)oldMap;
        List<Account_Sales_Play_Association__c> ASPAList = 
            new List<Account_Sales_Play_Association__c>();
        Set<Id> salesPlayIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();

        for(SObject soRec : newList) {
            Account_Sales_Play_Association__c ASPARec = (Account_Sales_Play_Association__c)soRec;

            if(Trigger.isInsert) {
                if(ASPARec.Active__c)
                    ASPAList.add(ASPARec);
                    salesPlayIds.add(ASPARec.Sales_Play__c);
                    accountIds.add(ASPARec.Account__c);
            }

        }

        if(ASPAList.size() > 0) {
            System.debug('ASPAList = '+ASPAList);
            AccSalesPlayAssociationTriggerClass.insertOSPARecords(ASPAList,salesPlayIds,accountIds);
        }

    }
    
    public override void beforeDeleteBeforeUndeleteTrigger() {

        List<Account_Sales_Play_Association__c> ASPATriggerOld = 
            (List<Account_Sales_Play_Association__c>)oldList;
        Set<Id> accountIds = new Set<Id>();
        Set<Id> salesPlayIds = new Set<Id>();
            
        for(SObject soRec : oldList) {
            Account_Sales_Play_Association__c ASPARec = (Account_Sales_Play_Association__c)soRec;

            if(Trigger.isDelete && ASPARec.Account__c != null) {
                accountIds.add(ASPARec.Account__c);    

                salesPlayIds.add(ASPARec.Sales_Play__c);
            }
        }

        if(accountIds.size() > 0) {
            AccSalesPlayAssociationTriggerClass.deleteOSPARecords(accountIds,salesPlayIds);
        }
    }
    
    public override void afterDeleteAfterUndeleteTrigger() {
        
    }
}