trigger docuSignTrigger on dsfs__DocuSign_Envelope__c (before insert) {
 
   
  ApexTriggerHandlerAbstractClass.createHandler('dsfs__DocuSign_Envelope__c');

}