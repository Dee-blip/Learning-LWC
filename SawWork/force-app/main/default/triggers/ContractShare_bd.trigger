trigger ContractShare_bd on Contract_Share__c (after delete, before delete) 
{	
	//SFDC-2686
	if (Trigger.isBefore && GsmUtilClass.isFeatureToggleEnabledCustomMetadata('isContractShareEnabled')) // if toggle is off; dont do anything.)
	{
		//List<Contract_Share__c> removeMCHShareList = new List<Contract_Share__c>();
		/*for (Contract_Share__c cs : Trigger.old)
		{
			//if (!cs.isContractTriggered__c)
		    //removeMCHShareList.add(cs);
		}
		if (removeMCHShareList.size()>0)
		{
	        // ContractSharing.removeContractShare(removeMCHShareList);
	        //ContractShareClass cShare = new ContractShareClass();
	        //cShare.delContractShare(removeMCHShareList);
		}*/
	}
}