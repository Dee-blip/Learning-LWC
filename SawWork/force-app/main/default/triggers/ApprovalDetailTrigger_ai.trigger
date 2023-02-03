trigger ApprovalDetailTrigger_ai on Approval_Details__c (after insert) 
{
	if(!UserInfo.getName().equalsIgnoreCase('Connection User'))
    {
        Map<Id,Id> adCaseMap = new Map<Id,Id>();
        
        for(Approval_Details__c ad : Trigger.new)
        {
        	adCaseMap.put(ad.Id,ad.Related_To__c);
        }
        if(!adCaseMap.isEmpty())
        {
            ApprovalDetailClass.mailAppDetailsForCase(adCaseMap,Trigger.newMap);
        }
    }
}