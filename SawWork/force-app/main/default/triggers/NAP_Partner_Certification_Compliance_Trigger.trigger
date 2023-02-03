/**
   History
      
      --Developer       --Date         --Description
      Ruchika sharma    08/06/2020     Created this Trigger - SFDC-6405
    
*/
trigger NAP_Partner_Certification_Compliance_Trigger on NAP_Partner_Certification_Compliance__c(before insert, before update, before delete, after insert, after update, after delete, after undelete) {
if(ByPassAndLimitUtils.isDisabled('NAP_Partner_Certification_Compliance_Trigger')){
		//set akam field
		if(Trigger.isBefore)
		 	ByPassAndLimitUtils.setAkamField(Trigger.isInsert,Trigger.isUpdate,trigger.new);
		return;
	}
	ApexTriggerHandlerAbstractClass.createHandler('NAP_Partner_Certification_Compliance__c');

}