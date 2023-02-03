/* ========================================================================
    Author: Sonia Sawhney
    Description: Used for automatic syncing of new records with the DR organization
    Created Date : 10/24/2013
    ======================================================================== */
trigger ShiftDRTrigger on Shift__c (after insert, after update){
    if(!ExternalSharingHelper.isTriggerFutureControl && (!system.Test.isRunningTest() || (system.Test.isRunningTest() && ExternalSharingHelper.RunFromtestClass == true)))
    {
        if(Trigger.isInsert)
        {
            ExternalSharingHelper.createS2Ssync('', Trigger.new, 'Shift_Role_Assignment__c,Shift_User_Junction__c'); 
        }
        else if(Trigger.isUpdate)
        {
            ExternalSharingHelper.CaptureRecordUpdate('Shift__c', Trigger.newMap.keyset());
        }
    }
}