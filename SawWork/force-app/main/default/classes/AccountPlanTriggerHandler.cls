/*Created By: Vivek Baidya
* Created Date: 04-Sep-2019
* Description: Trigger handler for AccountPlanTriggerFramework Trigger. 
*/
public without sharing class AccountPlanTriggerHandler extends ApexTriggerHandlerAbstractClass {
    public static Boolean accPlanToAccFieldMappingFirstRunFlag = true;
    public static Map<String, Object> accountPlanToAccountFieldMapping = new Map<String, Object>();
    
    public override void beforeInsertBeforeUpdateTrigger(){
        List<Account_Plan__c> accountPlanTriggerNew = (List<Account_Plan__c>)newList;
        Map<Id,Account_Plan__c> accountPlanTriggerOldMap = (Map<Id,Account_Plan__c>)oldMap;
        List<Id> accountIds = new List<Id>();
        List<Account_Plan__c> planListToSetTemplate = new List<Account_Plan__c>();  
        Map<Account_Plan__c, Id> accPlanToAccId = new Map<Account_Plan__c, Id>();
        Map<Account_Plan__c, Id> plansToValidateStatus = new Map<Account_Plan__c, Id>();
        Map<Id, Account_Plan__c> AccIdToAccountPlan = new Map<Id, Account_Plan__c>();
        
        for(Account_Plan__c newPlan : accountPlanTriggerNew){
            
            Account_Plan__c oldPlan = null;
            if(Trigger.isUpdate)
                oldPlan = accountPlanTriggerOldMap.get(newPlan.Id);
            
            if(Trigger.isInsert){
                accountIds.add(newPlan.Account__c);
                AccIdToAccountPlan.put(newPlan.Account__c, newPlan);
            }
            
            if(Trigger.IsInsert || (Trigger.IsUpdate && Util.hasChanges('Language__c', oldPlan, newPlan))){
                planListToSetTemplate.add(newPlan);
            }
            
            if(Trigger.IsInsert && newPlan.isClone()){
                accPlanToAccId.put(newPlan, newPlan.getCloneSourceId());
            }
            
            if(Trigger.IsInsert || (Trigger.IsUpdate && Util.hasChanges('Plan_Start_Date__c', oldPlan, newPlan))){
                plansToValidateStatus.put(newPlan, newPlan.Account__c);
            }
        }
        
        if(Trigger.IsInsert && !Test.isRunningTest())
            AccountPlanTriggerClass.validateQuipConnection(accountPlanTriggerNew);
        if(AccIdToAccountPlan.size()>0)
            AccountPlanTriggerClass.validateAccountPlanOwner(AccIdToAccountPlan);
        if(plansToValidateStatus.size() > 0)
           // AccountPlanTriggerClass.validatePlanStatus(plansToValidateStatus);
        if(Trigger.isInsert){
            AccountPlanTriggerClass.setAccountTeamMemberEmailAddresses(accountIds, accountPlanTriggerNew);
            AccountPlanTriggerClass.archiveAccountPlans(accountIds);
        }
        if(planListToSetTemplate.size() > 0)
            AccountPlanTriggerClass.setAccountPlanTemplate(planListToSetTemplate);
        if(accPlanToAccId.size() > 0)
            AccountPlanTriggerClass.setNewDocumentUrlForCloning(accPlanToAccId);
        
        ByPassAndLimitUtils.setAkamField(Trigger.isInsert, Trigger.isUpdate, accountPlanTriggerNew);
    }
    
    public override void afterInsertAfterUpdateTrigger(){
        List<Account_Plan__c> accountPlanTriggerNew = (List<Account_Plan__c>)newList;
        Map<Id,Account_Plan__c> accountPlanTriggerOldMap = (Map<Id,Account_Plan__c>)oldMap;
        if(accPlanToAccFieldMappingFirstRunFlag){
            accountPlanToAccountFieldMapping = (Map<String, Object>)JSON.deserializeUntyped([SELECT Value__c FROM GSM_Settings_Verbose__mdt WHERE DeveloperName = 'AccountPlanToAccountFieldMapping'][0].Value__c);
            accPlanToAccFieldMappingFirstRunFlag = false;
        }
        Boolean isChange;
        Map<Account_Plan__c, List<String>> mapOfPlanToChangedFields = new Map<Account_Plan__c, List<String>>();
        for(Account_Plan__c newPlan : accountPlanTriggerNew){
            isChange = false;
            Account_Plan__c oldPlan = null;
            if(Trigger.isUpdate)
                oldPlan = accountPlanTriggerOldMap.get(newPlan.Id);
            
            if(Trigger.isUpdate){
                List<String> changedFields = new List<String>();
                for(String field : accountPlanToAccountFieldMapping.keySet()){
                    if(Util.hasChanges(field, oldPlan, newPlan)){
                        isChange = true;
                        changedFields.add(field);
                    }
                }
                if(isChange)
                    mapOfPlanToChangedFields.put(newPlan, changedFields);
            }
        }
        if(mapOfPlanToChangedFields.size() > 0){
            AccountPlanTriggerClass.syncToAccount(mapOfPlanToChangedFields,accountPlanToAccountFieldMapping);
        }
    }
    
    public override void beforeDeleteBeforeUndeleteTrigger(){
        
    }
    
    public override void afterDeleteAfterUndeleteTrigger(){
        
    }
}