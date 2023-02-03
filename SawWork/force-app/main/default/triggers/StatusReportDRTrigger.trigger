/* ========================================================================
    Author: Sonia Sawhney
    Description: Used for automatic syncing of new records with the DR organization
    Created Date : 10/24/2013
    ======================================================================== */
trigger StatusReportDRTrigger on Status_Report__c (after insert, after update){
    if(!ExternalSharingHelper.isTriggerFutureControl && (!system.Test.isRunningTest() || (system.Test.isRunningTest() && ExternalSharingHelper.RunFromtestClass == true)))
    {
        if(Trigger.isInsert)
        {
            ExternalSharingHelper.createS2Ssync('Case__c', Trigger.new, null);
        }
        else if(Trigger.isUpdate)
        {
            ExternalSharingHelper.CaptureRecordUpdate('Status_Report__c', Trigger.newMap.keyset());
        } 
     }
}