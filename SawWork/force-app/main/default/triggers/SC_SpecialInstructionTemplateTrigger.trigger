/*=====================================================================================================+
    Trigger name        :   SC_SpecialInstructionTemplateTrigger 
    Author              :   Vamsee Surya
    Created             :   01-Aug-16
    Purpose             :   Trigger to delete the special instructions which are associated with special instruction template while deleting
    Test Class          :   SC_Case_Trgr_EmlServc_Class_TC (Method : testSpecialInstruction)
 ------------------------------------------------------------------------------------------------------
  Name      Date      Jira      Description
 ------------------------------------------------------------------------------------------------------
  Vamsee S    19/09/2017    ESESP-715     Enable Special Instruction Template DR Sync
                          Renamed SC_SpecialInstructionTemplateDelete to SC_SpecialInstructionTemplateTrigger
  Vamsee S	  03/11/2020    ESESP-4246 	  Removed SOQL inside Loop
+=====================================================================================================*/

trigger SC_SpecialInstructionTemplateTrigger on Special_Instruction_Template__c (after insert, after update, before insert, before update, before delete) {
  List<Special_Instructions__C> SIListforDelete = new List<Special_Instructions__C>();
    if(Trigger.isDelete){
		for(Special_Instructions__C si :[SELECT id from Special_Instructions__C where Special_Instruction_Template__c in :Trigger.oldMap.keySet()]){
        	SIListforDelete.add(si);
      	}
        if(SIListforDelete.size() > 0)
      		Delete SIListforDelete;
    }
    //Code related to DR
    else{
        //Check for preventing recursive trigger calls
    if(!ExternalSharingHelper.isTriggerFutureControl && (!system.Test.isRunningTest() || (system.Test.isRunningTest() && ExternalSharingHelper.RunFromtestClass == true))){
          if(Trigger.isBefore){
                ExternalSharingHelper.linkUserLookups('Special_Instruction_Template__c', Trigger.new, Trigger.isUpdate, Trigger.oldMap);
            }
            
      if(Trigger.isAfter) {
            if(Trigger.isInsert){
                  ExternalSharingHelper.createS2Ssync('', Trigger.new, '');
            }
            else if(Trigger.isUpdate){
                ExternalSharingHelper.CaptureRecordUpdate('Special_Instruction_Template__c', Trigger.newMap.keyset());
            }
        }
      }
    }
}