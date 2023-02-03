/* ========================================================================
    Author: Sonia Sawhney
    Description: Used for automatic syncing of new records with the DR organization
                 and re-establish the lookup relationships if the record is recieved from another organization
    Created Date : 07/16/2013
    ======================================================================== */
trigger TokenDRTrigger on EB_Token__c (after insert, after update)
{
    //Commented the code as the trigger is inactive
    /*if(!ExternalSharingHelper.isTriggerFutureControl && (!system.Test.isRunningTest() || (system.Test.isRunningTest() && ExternalSharingHelper.RunFromtestClass == true)))
    {
        if(Trigger.isInsert)
        {
            ExternalSharingHelper.createS2Ssync('', Trigger.new, 'EB_SelectedAccounts__c'); 
        }  
        else if(Trigger.isUpdate)
        {
            ExternalSharingHelper.CaptureRecordUpdate('EB_Token__c', Trigger.newMap.keyset());
        }
        Set<Id> Ids = ExternalSharingHelper.filterRecordIds('EB_Token__c',Trigger.isUpdate, Trigger.new, Trigger.oldMap);
        // call future method to link all lookups for the EB_Token__c object
        if (Ids.size() > 0) { 
            ExternalSharingHelper.linkObjects('EB_Token__c', Ids, ExternalSharingHelper.mpFields);
        } 
    }*/
}