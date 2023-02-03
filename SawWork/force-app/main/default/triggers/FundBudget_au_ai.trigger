trigger FundBudget_au_ai on SFDC_Budget__c (after insert, after update) 
{
    list<SFDC_Budget__c> FundBudgetCreatelist = new List<SFDC_Budget__c>();
    list<SFDC_Budget__c> FundBudgetDeletelist = new List<SFDC_Budget__c>();
    List<SFDC_Budget__c> listOfBudgetsWithUpdatedFCDeadline = new List<SFDC_Budget__c>();
    for(SFDC_Budget__c fm : Trigger.new)
    {
        if(Trigger.isInsert)
        {
            FundBudgetCreatelist.add(fm);
        }
        if(Trigger.isUpdate && fm.Account__c!=Trigger.oldMap.get(fm.id).Account__c)
        {
            FundBudgetCreatelist.add(fm);
            FundBudgetDeletelist.add(fm);
        }
        if(Trigger.isUpdate && fm.Fund_Claim_Deadline__c!=Trigger.oldMap.get(fm.Id).Fund_Claim_Deadline__c)
        {
            listOfBudgetsWithUpdatedFCDeadline.add(fm);
        }
        //PRMAutomatefundRequest.validateAllocations(fm);
    }

    if(FundBudgetDeletelist.size()>0)
        PRM_FundMTV.FundBudgetRemoveMTV(FundBudgetDeletelist,Trigger.oldMap);
    if(FundBudgetCreatelist.size()>0)
        PRM_FundMTV.FundBudgetCreateMTV(FundBudgetCreatelist);
    //Commenting as part of CR 3265961 
    /*if(listOfBudgetsWithUpdatedFCDeadline.size()>0)
        PRM_opportunity.updateEarliestFCDeadlineOnFundRequests(listOfBudgetsWithUpdatedFCDeadline);*/
}