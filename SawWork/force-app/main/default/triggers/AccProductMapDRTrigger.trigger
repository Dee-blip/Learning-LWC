/* ========================================================================
    Author: Sonia Sawhney
    Description: Used for automatic syncing of new records with the DR organization
                 and re-establish the lookup relationships if the record is recieved from another organization
    Created Date : 07/17/2013
    Modification History:
    1. Sonia Sawhney 07/17 CR 2712153 - Reverse Update Issue for Objects
    ======================================================================== */
trigger AccProductMapDRTrigger on EB_AccountProductMap__c (after insert, after update, before insert, before update)
{ 
    if(!ExternalSharingHelper.isTriggerFutureControl && (!system.Test.isRunningTest() || (system.Test.isRunningTest() && ExternalSharingHelper.RunFromtestClass == true)))
    {
      //CR 2712153 Moved lookup resolution to before trigger
      if(trigger.isBefore)
      {
          //Establish lookup relationship
          ExternalSharingHelper.linkObjectsSync('EB_AccountProductMap__c',Trigger.new, Trigger.isUpdate, Trigger.oldMap);
      }
      else if(Trigger.isAfter)
      {
          if(Trigger.isInsert)
          {
              ExternalSharingHelper.createS2Ssync('', Trigger.new,null);
          }
          else if(Trigger.isUpdate)
          {
              ExternalSharingHelper.CaptureRecordUpdate('EB_AccountProductMap__c', Trigger.newMap.keyset());
          }
      }
    //Commented out by ssawhney as lookup resolution is now done in the before trigger
    /*Set<Id> Ids = ExternalSharingHelper.filterRecordIds('EB_AccountProductMap__c',Trigger.isUpdate, Trigger.new, Trigger.oldMap);
    // call future method to link all lookups for the EB_AccountProductMap__c object
    if (Ids.size() > 0) { 
        ExternalSharingHelper.linkObjects('EB_AccountProductMap__c', Ids, ExternalSharingHelper.mpFields);
    } */
   }
}