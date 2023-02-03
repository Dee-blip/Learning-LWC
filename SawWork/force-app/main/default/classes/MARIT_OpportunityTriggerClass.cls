//Created by Priyanka Malhotra as part of marit-1070
public without sharing class MARIT_OpportunityTriggerClass {
    public static void updateAssociatedLeadOwner(Map<Id,Opportunity> oppForPopulatingLeadOwner){
        String soqll = 'Select Id, Owner__c from Lead where Id in ';
        soqll += MarketingUtilClass.parseIdsForDynamicQuery(new List<Id>(oppForPopulatingLeadOwner.keySet()));
        for(Lead ld: (List<Lead>)MarketingUtilClass.fetchFromDataBase(soqll)){
            Opportunity o = oppForPopulatingLeadOwner.get(ld.Id);
            o.Associated_Lead_Owner__c = ld.Owner__c;
        }
    }
}