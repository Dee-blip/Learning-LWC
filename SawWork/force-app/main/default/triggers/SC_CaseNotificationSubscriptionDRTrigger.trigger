/* ========================================================================
    Modification History:
    1. Sonia Sawhney 07/17 CR 2712153 - Reverse Update Issue for Objects
    ======================================================================== */
trigger SC_CaseNotificationSubscriptionDRTrigger on Case_Notification_Subscription__c (before insert,after insert,before update,after update) {
    
    //Check for preventing recursive trigger calls
    if(!ExternalSharingHelper.isTriggerFutureControl && (!system.Test.isRunningTest() || (system.Test.isRunningTest() && ExternalSharingHelper.RunFromtestClass == true)))
    {
        //Re-establish all user lookups on the object 
        if(Trigger.isBefore){
            ExternalSharingHelper.linkUserLookups('Case_Notification_Subscription__c', Trigger.new, Trigger.isUpdate, Trigger.oldMap);
            //CR 2712153 Moved lookup resolution to before trigger
            ExternalSharingHelper.linkObjectsSync('Case_Notification_Subscription__c',Trigger.new, Trigger.isUpdate, Trigger.oldMap);
        }
                
        if(Trigger.isAfter) {
            if(Trigger.isInsert)
            {
                ExternalSharingHelper.createS2Ssync('', Trigger.new, null); 
            }
            else if(Trigger.isUpdate)
            {
                ExternalSharingHelper.CaptureRecordUpdate('Case_Notification_Subscription__c', Trigger.newMap.keyset());
            }
            //Commented out by ssawhney as lookup resolution is now done in the before trigger
            /*Set<Id> Ids = ExternalSharingHelper.filterRecordIds('Case_Notification_Subscription__c',Trigger.isUpdate, Trigger.new, Trigger.oldMap);
            // call future method to link all lookups for the Case_Notification_Subscription__c object
            if (Ids.size() > 0) { 
                ExternalSharingHelper.linkObjects('Case_Notification_Subscription__c', Ids, ExternalSharingHelper.mpFields);
            } */
       }
    }
    
    //Added a check for connection user to bypass this logic
    if(Trigger.isAfter && !UserInfo.getName().equalsIgnoreCase('Connection User'))
    {
        List<String> UniqueList = new List<String>();
        List<Id> idList = new List<Id>();
        for(Case_Notification_Subscription__c cns : Trigger.New)
        {
            UniqueList.add(cns.UniqueFormula__c);
            idList.add(cns.Id);
        }
        for(Case_Notification_Subscription__c cns : [Select Id,UniqueFormula__c from Case_Notification_Subscription__c where UniqueFormula__c 
                                                     IN :UniqueList and Id not IN: idList])
        {
            Trigger.New[0].addError('Error : This user already has a subscription for the selected Case Record Type.');
                    break;
        }
    }
}