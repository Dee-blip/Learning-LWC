/***
    FundClaim_au_ai
    @author Vinayendra T N <Vinatara@akamai.com>
    @Description : This trigger is called on 'After insert after update '
 * History:
 * =========================
 * Developer        Date        Description
 * --------------------------------------------------------------------------------------------------
 * Vinayendra T N   21/01/11    CR 919522 Developments related to PRM
                                
*/   
trigger FundClaim_au_ai on SFDC_MDF_Claim__c (after insert, after update) {
    list<SFDC_MDF_Claim__c> FundClaimCreatelist = new List<SFDC_MDF_Claim__c>();
    list<SFDC_MDF_Claim__c> FundClaimDeletelist = new List<SFDC_MDF_Claim__c>();
    list<SFDC_MDF_Claim__c> FundClaimList = new list<SFDC_MDF_Claim__c>();
    SFDC_MDF_Claim__c oldMDFClaim = null;
    for(SFDC_MDF_Claim__c fm : Trigger.new)
    {
        if(Trigger.isInsert)
        {
            if(fm.Account__c!=null)
                FundClaimCreatelist.add(fm);
        }
        if(Trigger.isUpdate)
        {
            oldMDFClaim = Trigger.oldMap.get(fm.Id);
            if((fm.Status__c.contains('Approved') && !oldMDFClaim.Status__c.contains('Approved')) || (fm.Status__c == 'Closed' && oldMDFClaim.Status__c == 'Submitted'))
                FundClaimList.add(fm);
            if(fm.Account__c!=Trigger.oldMap.get(fm.id).Account__c)
            {
                if(fm.Account__c!=null)
                    FundClaimCreatelist.add(fm);
                if(Trigger.oldMap.get(fm.id).Account__c!=null)
                    FundClaimDeletelist.add(fm);
            }
        }
    }
    if(FundClaimList.size()>0)
            PRM_opportunity.convertAndUpdateFR(FundClaimList);
    if(FundClaimDeletelist.size()>0)
            PRM_FundMTV.FundClaimRemoveMTV(FundClaimDeletelist,Trigger.oldMap);
    if(FundClaimCreatelist.size()>0)
            PRM_FundMTV.FundClaimCreateMTV(FundClaimCreatelist);
}