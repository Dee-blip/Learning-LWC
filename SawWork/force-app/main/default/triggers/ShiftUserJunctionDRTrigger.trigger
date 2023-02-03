/* ========================================================================
    Author: Sonia Sawhney
    Description: Used for automatic syncing of new records with the DR organization
                 and re-establish the lookup relationships if the record is recieved from another organization
    Created Date : 10/24/2013
    ======================================================================== */
trigger ShiftUserJunctionDRTrigger on Shift_User_Junction__c (after insert, before insert, before update, after update)
{
    //Check for preventing recursive trigger calls
    if(!ExternalSharingHelper.isTriggerFutureControl && (!system.Test.isRunningTest() || (system.Test.isRunningTest() && ExternalSharingHelper.RunFromtestClass == true)))
    {
        //Re-establish all user lookups on the object 
        if(Trigger.isBefore){
            ExternalSharingHelper.linkUserLookups('Shift_Membership__c', Trigger.new, Trigger.isUpdate, Trigger.oldMap);
        }
                
        if(Trigger.isAfter && Trigger.isInsert){
            if(Trigger.isInsert)
            {
                ExternalSharingHelper.createS2Ssync('Shift__c', Trigger.new, null); 
            }
            else if(Trigger.isUpdate)
            {
                ExternalSharingHelper.CaptureRecordUpdate('Shift_User_Junction__c', Trigger.newMap.keyset());
            }
        }
    }
}