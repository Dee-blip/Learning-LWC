trigger BeepTrigger on Beep__c (before update) 
{

	ApexTriggerHandlerAbstractClass.createHandler('Beep__c');
}