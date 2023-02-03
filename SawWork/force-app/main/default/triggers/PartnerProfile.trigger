trigger PartnerProfile on Partner_Profile__c(after delete, after insert, after undelete, after update, before delete, before insert, before update) 
{
	ApexTriggerHandlerAbstractClass.createHandler('Partner_Profile');
}