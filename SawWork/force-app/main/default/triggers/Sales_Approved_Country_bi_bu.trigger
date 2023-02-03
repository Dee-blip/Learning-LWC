trigger Sales_Approved_Country_bi_bu on Sales_Approved_Country__c( before insert, before update) 
{
    for(Sales_Approved_Country__c sac : Trigger.new)
    {
        if(Trigger.isInsert)
        {
            sac.Has_Changed__c=true;
        }
        if(Trigger.isUpdate)
        {
            Sales_Approved_Country__c oldSac = Trigger.oldMap.get(sac.Id);
            if(Util.hasChanges('Name', oldSac, sac))
            {
                sac.addError('You cannot change the Country Name. Please delete the record and create again.');
            }
            else if(Util.hasChanges(new Set<String>{'Is_Direct_Allowed__c', 'Is_Reselling_Allowed__c'},oldSac, sac))
            {
                sac.Has_Changed__c=true;
            }
        }
    }
}