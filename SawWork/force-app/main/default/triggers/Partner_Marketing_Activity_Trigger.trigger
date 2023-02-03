/**
   History
      
      --Developer       --Date         --Description
      Ruchika sharma    24/05/2018     Created this Trigger - SFDC-2706
    
*/

trigger Partner_Marketing_Activity_Trigger on Partner_Marketing_Activity__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {

       if(ByPassAndLimitUtils.isDisabled('Partner_Marketing_Activity__c')){
		//set akam field
		if(Trigger.isBefore)
		 	ByPassAndLimitUtils.setAkamField(Trigger.isInsert,Trigger.isUpdate,trigger.new);
		return;
	}
	ApexTriggerHandlerAbstractClass.createHandler('Partner_Marketing_Activity');

}