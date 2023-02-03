/* ========================================================================
    Author: Sonia Sawhney
    Description: Used for automatic syncing of new records with the DR organization
    Created Date : 10/24/2013
    ======================================================================== */
trigger DivisionRoleDRTrigger on Division_Role__c (after insert, after update)
{
    if(!ExternalSharingHelper.isTriggerFutureControl && (!system.Test.isRunningTest() || (system.Test.isRunningTest() && ExternalSharingHelper.RunFromtestClass == true)))
    {
        if(Trigger.isInsert)
        {
            ExternalSharingHelper.createS2Ssync('Division__c', Trigger.new, ''); 
        }
        else if(Trigger.isUpdate)
        {
            ExternalSharingHelper.CaptureRecordUpdate('Division_Role__c', Trigger.newMap.keyset());
        }
    }
}