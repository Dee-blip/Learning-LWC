trigger FundRequest_ai_au on SFDC_MDF__c (after insert, after update) {
	list<SFDC_MDF__c> FundRequestCreatelist = new List<SFDC_MDF__c>();
	list<SFDC_MDF__c> FundRequestDeletelist = new List<SFDC_MDF__c>();
    List<SFDC_MDF__c> approvedFRs = new List<SFDC_MDF__c>();
	/**Begin Rajesh Kumar JIRA# SFDC-5779 */
	List<Id> cancelledFRsPMAIds = new List<Id>();
	/**End Rajesh Kumar JIRA# SFDC-5779 */
	for(SFDC_MDF__c fr : Trigger.new)
    	{
            SFDC_MDF__c oldFR;
            if(Trigger.isUpdate)
                oldFR = Trigger.oldMap.get(fr.id);

    		if(Trigger.isInsert)
    		{
    			if(fr.Account__c!=null)
	    		    FundRequestCreatelist.add(fr);
    		}
    		if(fr.Account__c!=null && Trigger.isUpdate && fr.Account__c!=oldFR.Account__c)
    		{
    			FundRequestCreatelist.add(fr);
    			FundRequestDeletelist.add(fr);
    		}
    		//PRMAutomatefundRequest.validateAllocations(fm);
            if((Trigger.isInsert || (Trigger.isUpdate && fr.Status__c!=oldFR.Status__c)) && 'Approved'.equalsIgnoreCase(fr.Status__c) && fr.Partner_Marketing_Activity__c!=null)
            {
                approvedFRs.add(fr);
            }
			/**Begin Rajesh Kumar JIRA# SFDC-5779 */
			if(Trigger.isUpdate && fr.Cancelled__c && fr.Cancelled__c != oldFR.Cancelled__c)
			{
				cancelledFRsPMAIds.add(fr.Partner_Marketing_Activity__c);
			}
			/**End Rajesh Kumar JIRA# SFDC-5779 */
    	}

	if(FundRequestDeletelist.size()>0)
		PRM_FundMTV.FundRequestRemoveMTV(FundRequestDeletelist,Trigger.oldMap);
	if(FundRequestCreatelist.size()>0)
		PRM_FundMTV.FundRequestCreateMTV(FundRequestCreatelist);
	if(!approvedFRs.isEmpty())
		FundRequestTriggerClass.markPMAInProgress(approvedFRs);

		/**Begin Rajesh Kumar JIRA# SFDC-5779 */
		if(!cancelledFRsPMAIds.isEmpty())
			FundRequestTriggerClass.handleCancelledFRonPMA(cancelledFRsPMAIds);
		/**End Rajesh Kumar JIRA# SFDC-5779 */
}