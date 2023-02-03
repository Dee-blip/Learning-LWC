/* ========================================================================
    Author: Deepak Saxena
    Description: Trigger to sync Issue records
    Created Date : 01/27/2015
    ======================================================================== */
    
trigger IssueDRTrigger on SC_Issues__c (after insert, after update, before insert, before update) {
 //Check for preventing recursive trigger calls
if(!ExternalSharingHelper.isTriggerFutureControl && (!system.Test.isRunningTest() || (system.Test.isRunningTest() && ExternalSharingHelper.RunFromtestClass == true)))
{
  if(Trigger.isBefore){
    
      ExternalSharingHelper.linkUserLookups('SC_Issues__c', Trigger.new, Trigger.isUpdate, Trigger.oldMap);
      //Below method call is needed if object has other lookups. Change the placeholder below to pass the object api name.
      ExternalSharingHelper.linkObjectsSync('SC_Issues__c',Trigger.new, Trigger.isUpdate, Trigger.oldMap);
  }

  //Below calls are always needed
  if(Trigger.isAfter) {
      if(Trigger.isInsert)
      {
          //Pass the Parent field API name below. If no master present, leave as blank. 
          //Also add comma-separated list of API names of all S2S shared child objects for the current object
          ExternalSharingHelper.createS2Ssync('Related_Case__c', Trigger.new, 'Case_Issue__c');
      }
      else if(Trigger.isUpdate)
      {
          //Add the object API name below
          ExternalSharingHelper.CaptureRecordUpdate('SC_Issues__c', Trigger.newMap.keyset());
      }
    }
  }
}