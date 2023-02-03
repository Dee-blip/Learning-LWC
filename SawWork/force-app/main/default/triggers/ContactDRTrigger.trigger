/* ========================================================================
    Author: Sonia Sawhney
    Description: Used for automatic syncing of new contact records with the DR organization
                 and re-establish the lookup relationships if the record is recieved from another organization
    Created Date : 07/17/2013
    Modification History:
    1. Sonia Sawhney 07/17 CR 2712153 - Reverse Update Issue for Objects
    ======================================================================== */
trigger  ContactDRTrigger on Contact(after insert, after update, before update, before insert) 
{   
    if(!ExternalSharingHelper.isTriggerFutureControl && (!system.Test.isRunningTest() || (system.Test.isRunningTest() && ExternalSharingHelper.RunFromtestClass == true)))
    {
        //Re-establish all user lookups on the object 
        if(Trigger.isBefore){
            ExternalSharingHelper.linkUserLookups('Contact', Trigger.new, Trigger.isUpdate, Trigger.oldMap);
            //CR 2712153 Moved lookup resolution to before trigger
            ExternalSharingHelper.linkObjectsSync('Contact',Trigger.new, Trigger.isUpdate, Trigger.oldMap);
        }
        
        if(Trigger.isAfter){
            //added organization type to check for one way sync
            Environment_Setup__c environmentSetup = Environment_Setup__c.getInstance();
            if(Trigger.isInsert && environmentSetup.Environment_Type__c.equalsIgnorecase('Primary'))
            { 
                ExternalSharingHelper.createS2Ssync('AccountId', Trigger.new, null); 
            }
            //Commented out by ssawhney as lookup resolution is now done in the before trigger
            /*Set<Id> Ids = ExternalSharingHelper.filterRecordIds('Contact',Trigger.isUpdate, Trigger.new, Trigger.oldMap);
            // call future method to link all lookups for the contact object
            if (Ids.size() > 0) { 
                ExternalSharingHelper.linkObjects('Contact', Ids, ExternalSharingHelper.mpFields);
            } */
        }
    }
}