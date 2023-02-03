/* ========================================================================
    Author: Sonia Sawhney
    Description: Used for automatic syncing of new email template records with the DR organization
    Created Date : 07/17/2013
    ======================================================================== */
trigger EBEmailTemplateDRTrigger on EB_EmailTemplate__c (before insert, before update, after insert, after update) 
{ 
    
    if(!ExternalSharingHelper.isTriggerFutureControl && (!system.Test.isRunningTest() || (system.Test.isRunningTest() && ExternalSharingHelper.RunFromtestClass == true)))
    {
        //This is used to populate the email template name/Id used for the DR functionality
        if(Trigger.isBefore)
        {
            ExternalSharingHelper.ManageEmailTemplates(Trigger.new, Trigger.isInsert);
        }
        //Create an entry for the DR sync 
        if(Trigger.isAfter)  
        {
            if(Trigger.isInsert)
            {
                ExternalSharingHelper.createS2Ssync('EB_NotificationType__c', Trigger.new, null);
            }
            else if(Trigger.isUpdate)
            {
                ExternalSharingHelper.CaptureRecordUpdate('EB_EmailTemplate__c', Trigger.newMap.keyset());
            }
        }
    }
}