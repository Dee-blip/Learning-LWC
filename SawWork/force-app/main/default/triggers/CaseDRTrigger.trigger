/* ========================================================================
    Author: Denise Bacher (salesforce.com)
    Description: Used for automatic syncing of new case records with the DR organization
                 and re-establish the lookup relationships if the record is recieved from another organization
    Created Date : 10/22/2013
    ======================================================================== */
trigger CaseDRTrigger on Case (after insert, after update, before insert, before update) {
    //Commented the code as trigger is inactive
    /*//Check for preventing recursive trigger calls
    if(!ExternalSharingHelper.isTriggerFutureControl){
        // on insert/update set Owner_RW__c field
        if(Trigger.isBefore){
            ExternalSharingHelper.linkUserLookups('Case', Trigger.new, Trigger.isUpdate, Trigger.oldMap);
            ExternalSharingHelper.linkRecordType('Case', 'Record_Type_RW__c', Trigger.new);
            ExternalSharingHelper.CaseSetOwnerRW(Trigger.new, Trigger.oldMap, Trigger.isUpdate);
        }
        
        if(Trigger.isAfter){
            if(Trigger.isInsert){
                ExternalSharingHelper.createS2Ssync('', Trigger.new, 'CaseComment');
            }
            
            // call future method to link all lookups for the Case object
            Set<Id> ids = ExternalSharingHelper.filterRecordIds('Case', Trigger.isUpdate, Trigger.new, Trigger.oldMap);
            if (ids.size() > 0) { 
                ExternalSharingHelper.linkObjects('Case', Ids, ExternalSharingHelper.mpFields);
            } 
        }
    }*/
}