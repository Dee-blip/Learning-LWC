/* ========================================================================
    Author: Denise Bacher (salesforce.com)
    Description: Used for automatic syncing of new Knowledge Article Versions
    Created Date : 10/29/2013
    ======================================================================== */
trigger GenericArticleDRTrigger on KA_Generic_Article__c (after insert, after update, before insert, before update) {
    //Check for preventing recursive trigger calls
    if(!ExternalSharingHelper.isTriggerFutureControl && (!system.Test.isRunningTest() || (system.Test.isRunningTest() && ExternalSharingHelper.RunFromtestClass == true)))
    {
        Environment_Setup__c environmentSetup = Environment_Setup__c.getInstance();
        if(environmentSetup.Environment_Type__c.equalsIgnorecase('Primary')){
             if(Trigger.isInsert && Trigger.isAfter)
                 ExternalSharingHelper.createS2Ssync('', Trigger.new, null); 
        }
        else{
            //Establish the lookup relationships in the before trigger
            if(Trigger.isBefore){
                ExternalSharingHelper.linkUserLookups('KA_Generic_Article__c', Trigger.new, Trigger.isUpdate, Trigger.oldMap);
                ExternalSharingHelper.linkObjectsSync('KA_Generic_Article__c', Trigger.new, Trigger.isUpdate, Trigger.oldMap);
            }
        }
    }
}