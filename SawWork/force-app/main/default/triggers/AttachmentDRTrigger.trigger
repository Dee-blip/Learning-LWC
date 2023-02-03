/* ========================================================================
    Author: Sonia Sawhney
    Description: Used for automatic syncing of new records with the DR organization
    Created Date : 10/29/2013
    ======================================================================== */
trigger AttachmentDRTrigger on Attachment (after insert, after update)
{
    if(!ExternalSharingHelper.isTriggerFutureControl && (!system.Test.isRunningTest() || (system.Test.isRunningTest() && ExternalSharingHelper.RunFromtestClass == true)))
    {
        if(Trigger.isInsert)
        {
            ExternalSharingHelper.createS2Ssync('ParentId', Trigger.new, null); 
        }
        else
        {
            ExternalSharingHelper.CaptureRecordUpdate('Attachment', Trigger.newMap.keyset());
        }
    }
}