trigger InvWorkBox_DGRATvalues on Inv_WorkBox_Region_Mapping__c (before insert, before update, before delete, after insert, after update) {

if(Trigger.isBefore ){
        
        if(Trigger.isInsert){
            PSA_Inv_WorkBoxReagionHandler iwReg = new PSA_Inv_WorkBoxReagionHandler();
            /****** send all records to set the GDRAT Alignment *******/
            iwReg.setGDRATvalues(trigger.new); 
            
        }
        
        if(Trigger.isUpdate){
            PSA_Inv_WorkBoxReagionHandler iwReg = new PSA_Inv_WorkBoxReagionHandler();
            /****** send all records to set the GDRAT Alignment *******/
            //iwReg.setGDRATvalues(trigger.new); 
            iwReg.setGDRATvaluesOnUpdate(Trigger.newMap, Trigger.oldMap);
        }
    
        if(Trigger.isDelete){
            PSA_Inv_WorkBoxReagionHandler iwReg = new PSA_Inv_WorkBoxReagionHandler();
            /****** send all records to see if user has access to delete *******/
            iwReg.beforeDeleteRecs(Trigger.old);
        }
            
    }
else if(Trigger.isAfter){
        
        if(Trigger.isInsert) {
            SC_DD_DealPermissions.recalcDealDeskPermissions(Trigger.New);
        }
        
        if(Trigger.isUpdate) {
            SC_DD_DealPermissions.recalcDealDeskPermissions(Trigger.New, Trigger.oldMap);
        }
    }
    
}