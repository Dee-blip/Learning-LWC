/* ========================================================================
    Author          :   Sonia Sawhney
    Description     :   Used for automatic syncing of new records with the DR organization
                        and re-establish the lookup relationships if the record is recieved from another organization
    Created Date    :   10/24/2013
    Test Class      :   TestDRTrigger   (Method : TestCaseTransitionDRTrigger)
    Modification History:
    1. Sonia Sawhney 07/17 CR 2712153 - Reverse Update Issue for Objects
    ======================================================================== */
trigger CaseTransitionDRTrigger on Case_Transition__c (after insert, after update, before insert, before update)
{
    //Check for preventing recursive trigger calls
    if(!ExternalSharingHelper.isTriggerFutureControl && (!system.Test.isRunningTest() || (system.Test.isRunningTest() && ExternalSharingHelper.RunFromtestClass == true)))
    {
        //Re-establish all user lookups on the object 
        if(Trigger.isBefore){
            ExternalSharingHelper.linkUserLookups('Case_Transition__c', Trigger.new, Trigger.isUpdate, Trigger.oldMap);
            //CR 2712153 Moved lookup resolution to before trigger
            ExternalSharingHelper.linkObjectsSync('Case_Transition__c',Trigger.new, Trigger.isUpdate, Trigger.oldMap);
            //ESESP-714 Case transition should work on DR
            ExternalSharingHelper.linkRecordType('Case_Transition__c', 'Record_Type_RW__c', Trigger.new);
        }
                
        if(Trigger.isAfter) {
            if(Trigger.isInsert){
                ExternalSharingHelper.createS2Ssync('Case__c', Trigger.new, null); 
            }
            else if(Trigger.isUpdate)
            {
                ExternalSharingHelper.CaptureRecordUpdate('Case_Transition__c', Trigger.newMap.keyset());
            }
            //Commented out by ssawhney as lookup resolution is now done in the before trigger
            /*Set<Id> Ids = ExternalSharingHelper.filterRecordIds('Case_Transition__c',Trigger.isUpdate, Trigger.new, Trigger.oldMap);
            // call future method to link all lookups for the Case_Transition__c object
            if (Ids.size() > 0) { 
                ExternalSharingHelper.linkObjects('Case_Transition__c', Ids, ExternalSharingHelper.mpFields);
            } */
       }
    }
}