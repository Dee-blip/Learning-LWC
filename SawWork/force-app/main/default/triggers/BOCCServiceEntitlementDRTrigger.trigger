/* ========================================================================
    Author      : Vamsee Surya
    Description   : Used for automatic syncing of new records with the DR organization
    Created Date  : 15/09/2017
  Test Class    : TestDRTriggers (Method : TestBOCCServiceEntitlementDRTrigger)
    ======================================================================== */

trigger BOCCServiceEntitlementDRTrigger on SC_BOCC_Contract_Eng_Mrktng_Product_Dtl__c (after insert, after update, before insert, before update) {
    if(!ExternalSharingHelper.isTriggerFutureControl && (!system.Test.isRunningTest() || (system.Test.isRunningTest() && ExternalSharingHelper.RunFromtestClass == true)))
  {
        if(Trigger.isBefore){
            ExternalSharingHelper.linkObjectsSync('SC_BOCC_Contract_Eng_Mrktng_Product_Dtl__c',Trigger.new, Trigger.isUpdate, Trigger.oldMap);
      }

      if(Trigger.isAfter) {
          if(Trigger.isInsert){
                ExternalSharingHelper.createS2Ssync('', Trigger.new, '');
          }
          else if(Trigger.isUpdate){
              ExternalSharingHelper.CaptureRecordUpdate('SC_BOCC_Contract_Eng_Mrktng_Product_Dtl__c', Trigger.newMap.keyset());
          }
      }
    }
}