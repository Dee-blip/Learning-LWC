/* ========================================================================
    Author: Sonia Sawhney
    Description: Used for automatic syncing of new records with the DR organization
                 and re-establish the lookup relationships if the record is recieved from another organization
    Created Date : 10/29/2013
    Modification History:
    1. Sonia Sawhney 07/17 CR 2712153 - Reverse Update Issue for Objects - Moved lookup sync to before trigger 
    ======================================================================== */
trigger TaskDRTrigger on Task (after insert, after update, before insert, before update)
{
    //Check for preventing recursive trigger calls
    if(!ExternalSharingHelper.isTriggerFutureControl && (!system.Test.isRunningTest() || (system.Test.isRunningTest() && ExternalSharingHelper.RunFromtestClass == true)))
    {
        //Re-establish all lookups on the object 
        if(Trigger.isBefore){
            ExternalSharingHelper.linkUserLookups('Task', Trigger.new, Trigger.isUpdate, Trigger.oldMap);
            ExternalSharingHelper.linkRecordType('Task', 'Record_Type_RW__c', Trigger.new);
            //Establish lookup relationship
            ExternalSharingHelper.linkObjectsSync('Task',Trigger.new, Trigger.isUpdate, Trigger.oldMap);
        }
                
        if(Trigger.isAfter) {
            if(Trigger.isInsert){
                ExternalSharingHelper.createS2Ssync('WhatId', Trigger.new, null); 
            }
            else if(Trigger.isUpdate)
            {
                ExternalSharingHelper.CaptureRecordUpdate('Task', Trigger.newMap.keyset());
            }
            //Commented by ssawhney to remove the asyc lookup binding
            /*Set<Id> Ids = ExternalSharingHelper.filterRecordIds('Task',Trigger.isUpdate, Trigger.new, Trigger.oldMap);
            // call future method to link all lookups for the Case_Transition__c object
            if (Ids.size() > 0) { 
                ExternalSharingHelper.linkObjects('Task', Ids, ExternalSharingHelper.mpFields);
            } */
       }
    }
}