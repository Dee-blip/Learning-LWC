/* =======================================================================================================
    Author          : Sonia Sawhney
    Description     : Used for automatic syncing of new records with the DR organization
    Created Date    : 10/24/2013
    Test Class      : TestDRTriggers (Method : TestSpecialInstructionsDRTrigger)
    ------------------------------------------------------------------------------------------------------
    Name            Date            Jira            Description
    ------------------------------------------------------------------------------------------------------
    Vamsee S        19/09/2017      ESESP-715       Enable Special Instruction Template DR Sync
    =================================================================================================== */
trigger SpecialInstructionsDRTrigger on Special_Instructions__c (after insert, after update, before insert, before update){
    if(!ExternalSharingHelper.isTriggerFutureControl && (!system.Test.isRunningTest() || (system.Test.isRunningTest() && ExternalSharingHelper.RunFromtestClass == true)))
    {
        if(Trigger.isBefore){
            ExternalSharingHelper.linkObjectsSync('Special_Instructions__c',Trigger.new, Trigger.isUpdate, Trigger.oldMap);
        }
        else if(Trigger.isAfter){
                if(Trigger.isInsert){
                    ExternalSharingHelper.createS2Ssync('Account__c', Trigger.new, null);
                }
                else if(Trigger.isUpdate){
                    ExternalSharingHelper.CaptureRecordUpdate('Special_Instructions__c', Trigger.newMap.keyset());
                }
        }
    }
}