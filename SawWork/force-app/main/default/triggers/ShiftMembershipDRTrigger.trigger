/* ========================================================================
    Author: Sonia Sawhney
    Description: Used for automatic syncing of new records with the DR organization
                 and re-establish the lookup relationships if the record is recieved from another organization
    Created Date : 10/24/2013
    Modification History:
    1. Sonia Sawhney 07/17 CR 2712153 - Reverse Update Issue for Objects
    ======================================================================== */
trigger ShiftMembershipDRTrigger on Shift_Membership__c (after insert, after update, before insert, before update)
{
    //Check for preventing recursive trigger calls
    if(!ExternalSharingHelper.isTriggerFutureControl && (!system.Test.isRunningTest() || (system.Test.isRunningTest() && ExternalSharingHelper.RunFromtestClass == true)))
    {
        //Re-establish all lookups on the object 
        if(Trigger.isBefore){
            ExternalSharingHelper.linkUserLookups('Shift_Membership__c', Trigger.new, Trigger.isUpdate, Trigger.oldMap);
            //CR 2712153 Moved lookup resolution to before trigger
            ExternalSharingHelper.linkObjectsSync('Shift_Membership__c',Trigger.new, Trigger.isUpdate, Trigger.oldMap);
        }
                
        if(Trigger.isAfter) {
            if(Trigger.isInsert){
                ExternalSharingHelper.createS2Ssync('', Trigger.new, null); 
            }
            else if(Trigger.isUpdate)
            {
                ExternalSharingHelper.CaptureRecordUpdate('Shift_Membership__c', Trigger.newMap.keyset());
            }
            //Commented out by ssawhney as lookup resolution is now done in the before trigger
            /*Set<Id> Ids = ExternalSharingHelper.filterRecordIds('Shift_Membership__c',Trigger.isUpdate, Trigger.new, Trigger.oldMap);
            // call future method to link all lookups for the Shift_Membership__c object
            if (Ids.size() > 0) { 
                ExternalSharingHelper.linkObjects('Shift_Membership__c', Ids, ExternalSharingHelper.mpFields);
            } */
       }
    }
}