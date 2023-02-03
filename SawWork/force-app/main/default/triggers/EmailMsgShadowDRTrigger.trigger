/* ============================================================================================
    Author: Sonia Sawhney
    Description: CR 2753364 - Need to Sync Email messages from Prod to DR and Vice Verse
                 Used to sync the email msg shadow to the other environment and create an email
                 message when a new shadow record is created by the connection
    Created Date : 07/24/2014
    =========================================================================================== */
trigger EmailMsgShadowDRTrigger on Email_Message_Shadow__c (after insert) 
{ 
    if(trigger.isAfter && trigger.isInsert && (!system.Test.isRunningTest() || (system.Test.isRunningTest() && ExternalSharingHelper.RunFromtestClass)))
    {
        //Create an entry in S2S objects
        if(!UserInfo.getName().equalsIgnoreCase('Connection User'))
        {
            ExternalSharingHelper.createS2Ssync('ParentId__c', Trigger.new, null); 
        }
        //Create a new email message of the shadow record is coming from Connection
        else
        {
            ExternalSharingHelper.CreateEmailMessages(Trigger.new);
        }
    }
}