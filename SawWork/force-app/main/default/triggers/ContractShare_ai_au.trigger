trigger ContractShare_ai_au on Contract_Share__c (after delete, before delete)
{
    if (Trigger.isBefore && GsmUtilClass.isFeatureToggleEnabledCustomMetadata('isContractShareEnabled')) // if toggle is off; dont do anything.)
	{
        //Test
    }

}