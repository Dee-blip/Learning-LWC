trigger RebatePayoutTrigger on Rebate_Payout__c (before update,after insert, after update) {
	
	if(Trigger.isBefore && Trigger.isUpdate)
	{
		for(Rebate_Payout__c rp: Trigger.New)
		{
		 if(Trigger.isUpdate && Trigger.oldMap.get(rp.id).Contract_Reviewed_Date__c != rp.Contract_Reviewed_Date__c) 
	    		rp.Contract_Reviewed_By__c = UserInfo.getUserID();
    	}
	}
	if(Trigger.isAfter)
	{
		List<Id> accountIdsToAddRemovePartnerAdminSharing=new List<Id>();
		List<Rebate_Payout__c> rebatePayoutListForAdd=new List<Rebate_Payout__c>();
		List<Rebate_Payout__c> rebatePayoutListForDelete=new List<Rebate_Payout__c>();
		List<Id> accountIdsToRemovePartnerAdminSharing=new List<Id>();
		for(Rebate_Payout__c rp: Trigger.New)
		{
			if((Trigger.isInsert && rp.Associated_Partner__c !=null) || (Trigger.isUpdate && rp.Associated_Partner__c!=trigger.oldmap.get(rp.id).Associated_Partner__c))
			{
				if(rp.Associated_Partner__c!=null)
				  accountIdsToAddRemovePartnerAdminSharing.add(rp.Associated_Partner__c);
				rebatePayoutListForAdd.add(rp);
			}
			/*else if(Trigger.isUpdate && rp.Associated_Partner__c ==null && rp.Associated_Partner__c!=trigger.oldmap.get(rp.id).Associated_Partner__c)
			{
				accountIdsToRemovePartnerAdminSharing.add(rp.Associated_Partner__c);
				rebatePayoutListForDelete.add(rp);
			}*/
		}
		
		if(accountIdsToAddRemovePartnerAdminSharing.size()>0)
		{
			PRM_Opportunity.addPartnerAdminSharing(accountIdsToAddRemovePartnerAdminSharing,rebatePayoutListForAdd);
		}
	   /* if(accountIdsToRemovePartnerAdminSharing.size()>0)
	    {
	    	PRM_Opportunity.removePartnerAdminSharing(accountIdsToRemovePartnerAdminSharing,rebatePayoutListForDelete);
	    }*/
   }
}