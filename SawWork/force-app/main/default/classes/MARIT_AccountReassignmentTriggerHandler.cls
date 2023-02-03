public without sharing class MARIT_AccountReassignmentTriggerHandler extends ApexTriggerHandlerAbstractClass {

    public override void beforeInsertBeforeUpdateTrigger(){
    }
    
    public override void afterInsertAfterUpdateTrigger(){
        
        Map<Id, Id> accToRuleIDMap = new Map<Id, Id>();
        list<Account_Reassignment__c> arTriggerNew = (list<Account_Reassignment__c>)newList;
        
        if(Trigger.IsInsert){
            for(Account_Reassignment__c aR : arTriggerNew){
                if(aR.Reassign__c == true){
                    accToRuleIDMap.put(ar.Account__c, ar.Assign_To__c); 
                }
            }
        }    
        
        if(accToRuleIDMap != null && !accToRuleIDMap.isEmpty()){
            MARIT_AccountReassignmentTriggerClass.createPlatformPublisher(accToRuleIDMap);
        }   
    }
    
    public override void beforeDeleteBeforeUndeleteTrigger(){
    }
    
    public override void afterDeleteAfterUndeleteTrigger(){
    }
}