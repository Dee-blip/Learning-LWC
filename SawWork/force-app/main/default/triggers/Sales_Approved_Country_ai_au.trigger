trigger Sales_Approved_Country_ai_au on Sales_Approved_Country__c( after insert, after update) 
{
    /*

    Set<String> setOfCountries = new Set<String>();
    for(Sales_Approved_Country__c sac : Trigger.new)
    {
        if(Trigger.isInsert)
        {
            setOfCountries.add(sac.Name);
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
                setOfCountries.add(sac.Name);
            }
        }
    }

    if(setOfCountries.size()>0)
    {
        SalesApprovedCountryBatchClass sacbc= new SalesApprovedCountryBatchClass();
        Database.executebatch(sacbc);
    }
    */
}