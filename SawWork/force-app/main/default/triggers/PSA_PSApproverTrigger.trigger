trigger PSA_PSApproverTrigger on PS_Approved_Hours__c (before insert, 
	before update, 
	before delete, 
	after insert, 
	after update, 
	after delete, 
	after undelete) 
{
        
    if(!UserInfo.getName().equalsIgnoreCase('Connection User'))
    {
        ApexTriggerHandlerAbstractClass.createHandler('PS_Approved_Hours__c');
    }
}