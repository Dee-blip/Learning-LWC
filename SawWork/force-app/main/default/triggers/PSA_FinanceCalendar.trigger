trigger PSA_FinanceCalendar on Finance_Calendar__c (before insert, 
	before update, 
	before delete, 
	after insert, 
	after update, 
	after delete, 
	after undelete) 
{
        
    if(!UserInfo.getName().equalsIgnoreCase('Connection User'))
    {
        ApexTriggerHandlerAbstractClass.createHandler('Finance_Calendar__c');
    }
}