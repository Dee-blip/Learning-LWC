/* ========================================================================
    Author: Sonia Sawhney
    Description: Used for automatic syncing of new account records with the DR organization
                 and re-establish the lookup relationships if the record is recieved from another organization
    Created Date : 09/30/2013
    Modification History:
    1. Sonia Sawhney 07/17 CR 2712153 - Reverse Update Issue for Objects
    ======================================================================== */
trigger MergeContractDRTrigger on Merge_Contract_Header__c (after insert, after update, before update, before insert)  
{   
    if(!ExternalSharingHelper.isTriggerFutureControl && (!system.Test.isRunningTest() || (system.Test.isRunningTest() && ExternalSharingHelper.RunFromtestClass == true)))
    { 
        if(Trigger.isBefore){
            //CR 2712153 Moved lookup resolution to before trigger
            ExternalSharingHelper.linkObjectsSync('Merge_Contract_Header__c',Trigger.new, Trigger.isUpdate, Trigger.oldMap);
        }

        if(Trigger.isAfter){
            //added organization type to check for one way sync
            Environment_Setup__c environmentSetup = Environment_Setup__c.getInstance();
            if(Trigger.isInsert && environmentSetup.Environment_Type__c.equalsIgnorecase('Primary'))
            {
                ExternalSharingHelper.createS2Ssync('', Trigger.new, null);
            }
            //Commented out by ssawhney as lookup resolution is now done in the before trigger
            /*Set<Id> Ids = ExternalSharingHelper.filterRecordIds('Merge_Contract_Header__c',Trigger.isUpdate, Trigger.new, Trigger.oldMap);
            // call future method to link all lookups for the contract object
            if (Ids.size() > 0) { 
                ExternalSharingHelper.linkObjects('Merge_Contract_Header__c', Ids, ExternalSharingHelper.mpFields);
            }*/
         }
    }
}