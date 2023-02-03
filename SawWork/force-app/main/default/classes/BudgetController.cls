public with sharing class BudgetController 
{
    public Decimal availableFunds{get; set;}
    public BudgetController()
    {
        Id accountId = null;
        if (UserInfo.getUserType().equals('PowerPartner')) {
            User currentUser= (new InnerBudgetController()).getUserRecord(UserInfo.getUserId());
            accountId = currentUser.Contact.Account.Id;
        }
        Set<Id> accountIdSet = new Set<Id>();
        accountIdSet.add(accountId);
        Map<Id, List<SFDC_Budget__c>> accountAvlBudgetMap = GsmUtilClass.getAvlBudgetForGivenAccounts(accountIdSet);
        List<SFDC_Budget__c> listOfBudgetsForCurrentAccount = new List<SFDC_Budget__c>();
        if(accountAvlBudgetMap!=null && accountAvlBudgetMap.containsKey(accountId))
        {
            listOfBudgetsForCurrentAccount = accountAvlBudgetMap.get(accountId);
        }
        this.availableFunds = 0;
        for (SFDC_Budget__c ithBudget :listOfBudgetsForCurrentAccount)  
        {
            this.availableFunds = this.availableFunds + ithBudget.Available_Budget__c;
        }
    }
    
    public without sharing class InnerBudgetController
    {
        public User getUserRecord(Id userId)
        {
            return [Select u.Id, u.Contact.Account.Id, u.ContactId From User u Where u.Id =:userId][0];
        }
    }
}