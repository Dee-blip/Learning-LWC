trigger AccountDepartmentTrigger on Account_Department__c (before insert, before update, after Insert, after update) {
    if(SC_AccountDepartmentTriggerHandler.isTriggerActive){
        if(trigger.isInsert && Trigger.isBefore){
            SC_AccountDepartmentTriggerHandler.beforeInsert(Trigger.New);
        }
        if(trigger.isUpdate && Trigger.isBefore){
            SC_AccountDepartmentTriggerHandler.beforeUpdate(Trigger.New, Trigger.OldMap);
        }
        if(trigger.isInsert && Trigger.isAfter){
            SC_AccountDepartmentTriggerHandler.afterInsert(Trigger.New);
        }
        if(trigger.isUpdate && Trigger.isAfter){
            SC_AccountDepartmentTriggerHandler.afterUpdate(Trigger.New, Trigger.OldMap);
        }
    }
    

}