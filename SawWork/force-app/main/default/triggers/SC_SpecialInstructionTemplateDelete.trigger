/*=====================================================================================================+
    Trigger name        :   SC_SpecialInstructionTemplateDelete 
    Author              :   Vamsee Surya
    Created             :   01-Aug-16
    Purpose             :   Trigger to delete the special instructions which are associated with special instruction template while deleting
                            (Marked status as Inactive in Meta File)
+=====================================================================================================*/
trigger SC_SpecialInstructionTemplateDelete on Special_Instruction_Template__c (before delete) {
    /* Moving this logic to SC_SpecialInstructionTemplateTrigger
    List<Special_Instructions__C> SIListforDelete = new List<Special_Instructions__C>();
    if(Trigger.isDelete){
        for(Id templateId  : Trigger.oldMap.keySet()){
            for(Special_Instructions__C si :[SELECT id from Special_Instructions__C where Special_Instruction_Template__c = :templateId]){
                SIListforDelete.add(si);
            }
        }
        Delete SIListforDelete;
    }
    */
}