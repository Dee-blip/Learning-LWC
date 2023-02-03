public without sharing class LeadTriggerClassWithoutSharing 
{
    public static Boolean populateVerticalFieldsFromAccountFirstRunFlag = true;
    public static Boolean updateClosedCampaignDetails = true;

    //SFDC-2509
    public static void createCampaignMemberbasedOnPrimaryCampaign(List<Lead> leads) 
    {
        List<CampaignMember> cmList = new List<CampaignMember>();

        for(Lead l: leads) 
        {
            CampaignMember cm = new CampaignMember();
            cm.CampaignId = l.Primary_Campaign__c;
            cm.LeadId = l.id;
            cmList.add(cm);
        }
        insert cmList;
    }

    public static void populateVerticalFieldsFromAccountForLead(List<Lead> leadsForVerticalPopulation)
    {
        if(!populateVerticalFieldsFromAccountFirstRunFlag)
            return;

        Map<Id, Account> accIdToAccount = new Map<Id, Account>();
        Set<Id> accIdSet = new Set<Id>();
        for(Lead l : leadsForVerticalPopulation)
        {
            accIdSet.add(l.Associated_Account__c);
        }

        String exclusionAccounts = GSMUtilClass.getGSMSettingValue('AccTriggerCls_ExclusionAccountList');
        Set<String> exclusionList= new Set<String>();
        if(exclusionAccounts!= null ) 
        {
            exclusionList.addAll(exclusionAccounts.split(','));
        }

        for(Account acc:[select Vertical__c,
                Sub_Vertical__c,
                Website
                from Account
                where Id in :accIdSet
                And Name not in :exclusionList])
        {
            accIdToAccount.put(acc.Id, acc);
        }

        for(Lead l : leadsForVerticalPopulation)
        {
            if(accIdToAccount.containsKey(l.Associated_Account__c))
            {
                Account ithAccount  = accIdToAccount.get(l.Associated_Account__c);
                l.Website = ithAccount.Website;
            }
        }
        System.debug(LoggingLevel.Error, 'AGH_D List of leads to update ' + leadsForVerticalPopulation);

        populateVerticalFieldsFromAccountFirstRunFlag = false;
    }


}