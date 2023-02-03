trigger PSA_PSOverageScheduleTrigger on PS_Overage_Schedule__c (before insert, 
	before update, 
	before delete, 
	after insert, 
	after update, 
	after delete, 
	after undelete) 
{

    if(!UserInfo.getName().equalsIgnoreCase('Connection User'))
    {
        ApexTriggerHandlerAbstractClass.createHandler('PS_Overage_Schedule__c');
    }
}