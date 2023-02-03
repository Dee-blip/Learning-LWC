trigger updateFundRequestPartnerAccount on SFDC_MDF__c (before insert, before update) {
  /**
    *   Update the account field when the record is owned by a partner
    *   Vinay: Made changes to disable currenly conversion For PRM
    */

    //Anand Hegde - CR 2505504 - Moving this to FundRequest_bi trigger as we need the partner account to be populated before we check for available budgets
//PRMTriggerClass.FRUpdateFundRequestPartnerAccountTriggerMethod(Trigger.new, Trigger.oldMap, Trigger.newMap);
/*
     Set<Id> ownerIds = new Set<Id>();
     Set<Id> accountIdSet = new Set<Id>();
     boolean isMultiCurrencyEnabled = Util.isMultiCurrencyEnabled();
     Map<String, CurrencyWrapper>  currencyMap = null;
     if (isMultiCurrencyEnabled) {
         currencyMap =Util.getCurrencies();
     }
    
     //Loop through each fund request and create a Set of all the UserIds for the fund request owners 
     for (SFDC_MDF__c fundRequest : Trigger.new) {
        SFDC_MDF__c oldFundRequest = null;
        if (Trigger.isUpdate) {
            oldFundRequest = trigger.oldMap.get(fundRequest.Id);
        }
        if (fundRequest.Partner_Account_Owner__c == NULL || Util.hasChanges('Partner_Account_Owner__c',oldFundRequest,fundRequest) ||
             fundRequest.account__c == null ||  Util.hasChanges('Account__c',oldFundRequest,fundRequest)) {
             //Figure out the owner ids of the fund requests    
             ownerIds.add(fundRequest.OwnerId);
         }      
         if (fundRequest.Account__c != null && Util.hasChanges('Account__c',oldFundRequest,fundRequest)) {
             accountIdSet.add(fundRequest.Account__c);
         }         
     }
     Map<Id,Account> accountMap = null;
     if (accountIdSet != null && accountIdSet.size() > 0) {
         accountMap = new Map<Id,Account>([select id,OwnerId, Name from account where Id IN: accountIdSet]);
     }
     Map<Id,User> partnerAccts = null;
     Map<Id, Integer> accountSeqMap = null;
     if (ownerIds != null && ownerIds.size() > 0) {
         //Create a map of the owernids to their partner accounts
        partnerAccts = new Map<Id,User>([Select Id, Contact.Account.Id,Contact.Account.OwnerId from User where id in :ownerIds]);
         if (partnerAccts != null && partnerAccts.size() > 0) {
             for(User currentUser : partnerAccts.values()) {
                accountIdSet.add(currentUser.Contact.Account.Id);
             }
         }
     }
     if (accountIdSet != null && accountIdSet.size() > 0) {
        accountSeqMap = Util.getMaxSequenceForGivenAccounts(accountIdSet,Util.FUND_REQUEST);
     }
     Integer sequence = 0;
     Id oldAccountId = null;
     boolean amountChange = false;
     //Now loop through each fund request to set the Partner Account Id on the request
     for (SFDC_MDF__c fundRequest : Trigger.new) {
          amountChange = false;
         //Only update the value for records that have an owner = partnerAccount
         if (partnerAccts != null && (partnerAccts.get(fundRequest.OwnerId).Contact.Account.Id != NULL) && (fundRequest.Account__c == NULL)) {
            fundRequest.Account__c = partnerAccts.get(fundRequest.OwnerId).Contact.Account.Id;
         }
         if (partnerAccts != null && (partnerAccts.get(fundRequest.OwnerId).Contact.Account.OwnerId != NULL) && (fundRequest.Partner_Account_Owner__c == NULL)) {
            fundRequest.Partner_Account_Owner__c = partnerAccts.get(fundRequest.OwnerId).Contact.Account.OwnerId;
         }
         if (fundRequest.Partner_Account_Owner__c == null && fundRequest.Account__c != null && accountMap != null && accountMap.containsKey(fundRequest.Account__c)) {
            fundRequest.Partner_Account_Owner__c = accountMap.get(fundRequest.Account__c).ownerId;
         }    
         sequence = 0;
         if (fundRequest.account__c != null) {
            if (accountSeqMap != null && accountSeqMap.containsKey(fundRequest.account__c)) {
                sequence = accountSeqMap.get(fundRequest.account__c);
            }
            if (Trigger.isInsert) {
                fundRequest.Sequence__c = sequence + 1;
                amountChange = true;
            } else {
                oldAccountId = trigger.oldMap.get(fundRequest.Id).account__c;
                if( oldAccountId == null || oldAccountId != fundRequest.account__c) {
                    fundRequest.Sequence__c = sequence + 1;
                }
                if (Util.hasChanges('Amount__c', trigger.oldMap.get(fundRequest.Id), fundRequest)) {
                    amountChange = true;
                } else if (fundRequest.Amount_In_Corporate_Currency__c == null) {
                    amountChange = true;
                }
                
            }

         }
         //Vinay: Made changes to disable currenly conversion
         isMultiCurrencyEnabled=false;
         if (amountChange) {
            if(isMultiCurrencyEnabled) {
                Util.convertAmountToCorporateCurrency(currencyMap,fundRequest);
            } else {
                fundRequest.Amount_In_Corporate_Currency__c = fundRequest.Amount__c;
            }
         }
           
     } 
     */
}