trigger SC_Elevation on Elevation__c (before insert,before update,after insert,after update,before delete) 
{
    if((Trigger.isInsert || Trigger.isUpdate) && Trigger.isBefore)
    {
        SC_Elevation_TriggerHandler.beforeInsertUpdate(Trigger.isInsert,null,Trigger.new,null,Trigger.newMap);
    }
    if((Trigger.isInsert || Trigger.isUpdate) && Trigger.isAfter)
    {
        SC_Elevation_TriggerHandler.afterInsertUpdate(Trigger.isInsert,Trigger.old,Trigger.new,Trigger.oldMap,Trigger.newMap);
    }
    else if(Trigger.isDelete)
    {
        for(Elevation__c eachRec : Trigger.old)
        {
            if(!eachRec.Validation_Override__c)
            {   eachRec.addError('You cannot delete an Elevation record.'); }
        }
    }
}