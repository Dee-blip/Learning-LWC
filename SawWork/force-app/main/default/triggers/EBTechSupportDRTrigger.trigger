/* ========================================================================
    Author: Sonia Sawhney
    Description: Used for automatic syncing of records with the DR organization
                 and re-establish the lookup relationships if the record is recieved from another organization
    Created Date : 07/17/2013
    ======================================================================== */
trigger EBTechSupportDRTrigger on EB_TechSupportTeams__c (after insert, before insert, before update, after update) { 
 
    if(!ExternalSharingHelper.isTriggerFutureControl && (!system.Test.isRunningTest() || (system.Test.isRunningTest() && ExternalSharingHelper.RunFromtestClass == true)))
    {
        if(Trigger.isAfter)
        {  
            if(Trigger.isInsert)
            {
                ExternalSharingHelper.createS2Ssync('', Trigger.new,null); 
            }
            else if(Trigger.isUpdate)
            {
                ExternalSharingHelper.CaptureRecordUpdate('EB_TechSupportTeams__c', Trigger.newMap.keyset());
            }
        }
        if(Trigger.isBefore)
        {
             //Establish lookup relationship
             ExternalSharingHelper.linkObjectsSync('EB_TechSupportTeams__c',Trigger.new, Trigger.isUpdate, Trigger.oldMap);
        }
    }
}