/* ========================================================================
    Author: Sonia Sawhney
    Description: Used for automatic syncing of new records with the DR organization
                 and re-establish the lookup relationships if the record is recieved from another organization
    Created Date : 07/17/2013
    ======================================================================== */
trigger SelectedAccountDRTrigger on EB_SelectedAccounts__c (after insert, after update) { 
   //Commented the code as trigger is inactive
   /* if(!ExternalSharingHelper.isTriggerFutureControl && (!system.Test.isRunningTest() || (system.Test.isRunningTest() && ExternalSharingHelper.RunFromtestClass == true)))
    {
        if(Trigger.isInsert)
        {
           ExternalSharingHelper.createS2Ssync('EB_ParentToken__c', Trigger.new, null);  
        }
        else if(Trigger.isUpdate)
        {
            ExternalSharingHelper.CaptureRecordUpdate('EB_SelectedAccounts__c', Trigger.newMap.keyset());
        }
        Set<Id> Ids = ExternalSharingHelper.filterRecordIds('EB_SelectedAccounts__c',Trigger.isUpdate, Trigger.new, Trigger.oldMap);
        // call future method to link all lookups for the EB_SelectedAccounts__c object
        if (Ids.size() > 0) { 
            ExternalSharingHelper.linkObjects('EB_SelectedAccounts__c', Ids, ExternalSharingHelper.mpFields);
        }  
    }*/
}