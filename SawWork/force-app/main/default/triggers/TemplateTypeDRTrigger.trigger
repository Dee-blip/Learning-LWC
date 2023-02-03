/* ========================================================================
    Author: Sonia Sawhney
    Description: Used for automatic syncing of new email template type records with the DR organization
    Created Date : 07/17/2013
    ======================================================================== */
trigger TemplateTypeDRTrigger on EB_NotificationType__c (after insert, after update) 
{ 
    if(!ExternalSharingHelper.isTriggerFutureControl && (!system.Test.isRunningTest() || (system.Test.isRunningTest() && ExternalSharingHelper.RunFromtestClass == true)))
    {
        if(Trigger.isInsert)
        {
            ExternalSharingHelper.createS2Ssync('', Trigger.new,'EB_EmailTemplate__c'); 
        }
        else if(Trigger.isUpdate)
        {
            ExternalSharingHelper.CaptureRecordUpdate('EB_NotificationType__c', Trigger.newMap.keyset());
        }
    }
}