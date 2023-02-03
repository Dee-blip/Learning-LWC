/* ========================================================================
    Author: Sonia Sawhney
    Description: Used for automatic syncing of new records with the DR organization
                 and re-establish the lookup relationships if the record is recieved from another organization
    Created Date : 10/24/2013
	Modification History:
		Sonia Sawhney:	05/24/2014:	CR 2643825 - DR : Issues related to case sync to QA
    ======================================================================== */
trigger EngagementRequestDRTrigger on Engagement_Request__c (after insert, after update, before insert, before update)
{
    //Check for preventing recursive trigger calls
    if(!ExternalSharingHelper.isTriggerFutureControl && (!system.Test.isRunningTest() || (system.Test.isRunningTest() && ExternalSharingHelper.RunFromtestClass == true)))
    {
        //Re-establish all user lookups on the object 
        if(Trigger.isBefore){
            ExternalSharingHelper.linkUserLookups('Engagement_Request__c', Trigger.new, Trigger.isUpdate, Trigger.oldMap);
            ExternalSharingHelper.linkRecordType('Engagement_Request__c', 'Record_Type_RW__c', Trigger.new);
        }
                
        if(Trigger.isAfter) {
            if(Trigger.isInsert)
            {
				//Modified by ssawhney for CR 2643825 to treat the Case object as the parent of the Engagement request
				//even though the actual parent child relationship does not exist. This is done to sync the data correctly for engagement requests.
                ExternalSharingHelper.createS2Ssync('Case__c', Trigger.new, null); 
            }
            else if(Trigger.isUpdate)
            {
                ExternalSharingHelper.CaptureRecordUpdate('Engagement_Request__c', Trigger.newMap.keyset());
            }
            //Commented to ssawhney on 22/05/2014 as this is not needed now
            /*Set<Id> Ids = ExternalSharingHelper.filterRecordIds('Engagement_Request__c',Trigger.isUpdate, Trigger.new, Trigger.oldMap);
            // call future method to link all lookups for the Engagement_Request__c object
            if (Ids.size() > 0) { 
                ExternalSharingHelper.linkObjects('Engagement_Request__c', Ids, ExternalSharingHelper.mpFields);
            } */
       }
    }
}