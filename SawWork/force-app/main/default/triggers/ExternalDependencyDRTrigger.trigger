/* ========================================================================
    Author: Sonia Sawhney
    Description: Used for automatic syncing of new records with the DR organization
    Created Date : 10/24/2013
    ======================================================================== */
trigger ExternalDependencyDRTrigger on External_Dependency__c (before insert, before update, after insert, after update){
    if(!ExternalSharingHelper.isTriggerFutureControl && (!system.Test.isRunningTest() || (system.Test.isRunningTest() && ExternalSharingHelper.RunFromtestClass == true)))
    {
        if(Trigger.isBefore){
            // Added by Deepak Saxena for CR 2884611 
                ExternalSharingHelper.linkRecordType('External_Dependency__c', 'Record_Type_RW__c', Trigger.new);
        }
                
        if(Trigger.isAfter) {
            if(Trigger.isInsert)
            {
                ExternalSharingHelper.createS2Ssync('Case__c', Trigger.new, null); 
            }
            else if(Trigger.isUpdate)
            {
                ExternalSharingHelper.CaptureRecordUpdate('External_Dependency__c', Trigger.newMap.keyset());
            }
            
       }
       
    }
}