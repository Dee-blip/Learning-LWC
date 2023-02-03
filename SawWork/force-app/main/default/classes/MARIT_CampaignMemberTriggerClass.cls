public without sharing class MARIT_CampaignMemberTriggerClass {
// MARIT-1761
    public static void SetAccountDetailsViaContact(Map<CampaignMember, Id> cmpgnMemToContactId) {
        Map<Id, Contact> contactIdToContactMap = new Map<Id, Contact>([Select Id, Account.Id, Account.Account_Status__c from Contact where Id in : cmpgnMemToContactId.values()]);
        string accountStatus = '';
        string accountId = '';
        // populate the campaign member values here
        System.debug('contact map :' + contactIdToContactMap);
        for(CampaignMember cmpgnMem : cmpgnMemToContactId.KeySet()) {
            accountStatus = contactIdToContactMap.get(cmpgnMemToContactId.get(cmpgnMem)).Account.Account_Status__c;
            accountId = contactIdToContactMap.get(cmpgnMemToContactId.get(cmpgnMem)).Account.Id;
            cmpgnMem.Account_Status__c = accountStatus;
            cmpgnMem.AccountId__c = accountId;
        }
    }
    public static void SetAccountDetailsViaLead(Map<CampaignMember, Id> cmpgnMemToLeadId) {
        Map<Id, Lead> leadIdToLeadMap = new Map<Id, Lead>([Select Id, Associated_Account__r.Id, Associated_Account__r.Account_Status__c from Lead where Id in : cmpgnMemToLeadId.values()]);
        string accountStatus = '';
        string accountId = '';
        for(CampaignMember cmpgnMem : cmpgnMemToLeadId.KeySet()) {
            accountStatus = leadIdToLeadMap.get(cmpgnMemToLeadId.get(cmpgnMem)).Associated_Account__r.Account_Status__c;
            accountId = leadIdToLeadMap.get(cmpgnMemToLeadId.get(cmpgnMem)).Associated_Account__r.Id;
            cmpgnMem.Account_Status__c = accountStatus;
            cmpgnMem.AccountId__c = accountId;
        }
    }
}