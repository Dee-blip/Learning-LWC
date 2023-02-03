/*Created By: Vivek Baidya
* Created Date: 29-Nov-2018
* Description: Trigger handler for ClosePlan Trigger. 
*/
public without sharing class ClosePlanTriggerHandler extends ApexTriggerHandlerAbstractClass {
	
    public override void beforeInsertBeforeUpdateTrigger(){
        List<Close_Plan__c> cpTriggerNew = (List<Close_Plan__c>)newList;
        ByPassAndLimitUtils.setAkamField(Trigger.isInsert, Trigger.isUpdate, cpTriggerNew);
    }
    
    public override void afterInsertAfterUpdateTrigger(){
        List<Close_Plan__c> closePlanTriggerNew = (List<Close_Plan__c>)newList;
        List<Close_Plan__c> closePlanTriggerOld = (List<Close_Plan__c>)oldList;

        Set<Id> associatedOpptyIds = new Set<Id>();
        Set<Id> associatedOpptyIdsRemoved = new Set<Id>();
        for(Close_Plan__c cp : closePlanTriggerNew) {
            if(Trigger.isInsert){
               associatedOpptyIds.add(cp.Opportunity__c);
            } 
            if(Trigger.isUpdate) {
                Close_Plan__c cpOld = (Close_Plan__c)oldMap.get(cp.Id);
                if(Util.hasChanges('Opportunity__c',cpOld,cp)) {
                    associatedOpptyIdsRemoved.add(cpOld.Opportunity__c);
                	associatedOpptyIds.add(cp.Opportunity__c);
                }
            }
        }
        if(associatedOpptyIds.size() > 0) {
           ClosePlanTriggerClass.handleClosePlanOperation(associatedOpptyIds,true);
        }
        if(associatedOpptyIdsRemoved.size() > 0) {
             ClosePlanTriggerClass.handleClosePlanOperation(associatedOpptyIdsRemoved,false);
        }
    }
    
    public override void beforeDeleteBeforeUndeleteTrigger(){
        
    }
    
    public override void afterDeleteAfterUndeleteTrigger(){
        List<Close_Plan__c> closePlanTriggerOld = (List<Close_Plan__c>)oldList;
        Set<Id> associatedOpptyIds = new Set<Id>();
        System.debug(closePlanTriggerOld);
		 for(Close_Plan__c cp : closePlanTriggerOld) {
            associatedOpptyIds.add(cp.Opportunity__c);
        }
        if(associatedOpptyIds.size() > 0) {
           ClosePlanTriggerClass.handleClosePlanOperation(associatedOpptyIds,false);
        }
    }
}