/* ========================================================================
    Author: Sonia Sawhney
    Description: Used for automatic syncing of new records with the DR organization
                 and re-establish the lookup relationships if the record is recieved from another organization
    Created Date : 10/24/2013
    Modification History:
    1. Sonia Sawhney 07/17 CR 2712153 - Reverse Update Issue for Objects
    ======================================================================== */
trigger ProductCategoryDRTrigger on Product_Category__c (after insert, after update, before update, before insert) 
{
    //Check for preventing recursive trigger calls
   if(!ExternalSharingHelper.isTriggerFutureControl && (!system.Test.isRunningTest() || (system.Test.isRunningTest() && ExternalSharingHelper.RunFromtestClass == true)))
    {
        //Re-establish all lookups on the object 
        if(Trigger.isBefore){
            //CR 2712153 Moved lookup resolution to before trigger
            ExternalSharingHelper.linkObjectsSync('Product_Category__c',Trigger.new, Trigger.isUpdate, Trigger.oldMap);
        }
        
        if(Trigger.isAfter){
            if(Trigger.isInsert){
                ExternalSharingHelper.createS2Ssync('', Trigger.new, 'Product__c'); 
            }
            else if(Trigger.isUpdate)
            {
                ExternalSharingHelper.CaptureRecordUpdate('Product_Category__c', Trigger.newMap.keyset());
            }
            //Commented out by ssawhney as lookup resolution is now done in the before trigger
            /*Set<Id> Ids = ExternalSharingHelper.filterRecordIds('Product_Category__c',Trigger.isUpdate, Trigger.new, Trigger.oldMap);
            // call future method to link all lookups for the Product_Category__c object
            if (Ids.size() > 0) { 
                ExternalSharingHelper.linkObjects('Product_Category__c', Ids, ExternalSharingHelper.mpFields);
            } */
        }
    }
}