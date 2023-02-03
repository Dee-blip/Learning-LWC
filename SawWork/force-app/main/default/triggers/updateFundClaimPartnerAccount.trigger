trigger updateFundClaimPartnerAccount on SFDC_MDF_Claim__c (before insert, before update) {

    PRMTriggerClass.FCUpdateFundClaimPartnerAccountTriggerMethod(Trigger.new, Trigger.oldMap, Trigger.newMap);

  /**
    *   Update the account field when the record is owned by a partner
    *   Vinay: isMultiCurrencyEnabled is made false to disable currency conversion PRM
    */
/*
    Set<Id> ownerIds = new Set<Id>();
    Set<Id> accountIdSet = new Set<Id>();
    Set<Id> fundRequestIdSet = new Set<Id>();
    
    boolean isMultiCurrencyEnabled = Util.isMultiCurrencyEnabled();
    Map<String, CurrencyWrapper>  currencyMap = null;
    if (isMultiCurrencyEnabled) {
        currencyMap =Util.getCurrencies();
    }
    
    //Loop through each fund claim and create a Set of all the UserIds for the fund claim owners 
    for (SFDC_MDF_Claim__c fundClaim : Trigger.new) {
        SFDC_MDF_Claim__c oldFundClaim = null;
        Id oldAccountId = null;
        if (Trigger.isUpdate) {
            oldFundClaim = trigger.oldMap.get(fundClaim.Id);
            oldAccountId = trigger.oldMap.get(fundClaim.Id).account__c;
        }
        //Figure out the owner ids of the fund claims
         if (fundClaim.Partner_Account_Owner__c == NULL || Util.hasChanges('Partner_Account_Owner__c',oldFundClaim,fundClaim) ||
             fundClaim.account__c == null ||  Util.hasChanges('Account__c',oldFundClaim,fundClaim)) {
             ownerIds.add(fundClaim.OwnerId);
         }
         if (Trigger.isInsert) {
             if (fundClaim.Account__c != null) {
                 accountIdSet.add(fundClaim.Account__c);
             }
             if(fundClaim.Fund_Request__c !=  null) {
                fundRequestIdSet.add(fundClaim.Fund_Request__c);
             }
         } else {
            if (oldAccountId != fundClaim.Account__c) {
                accountIdSet.add(fundClaim.Account__c);
            }
            if(fundClaim.Fund_Request__c !=  null && oldFundClaim.Approved_Amount__c != fundClaim.Approved_Amount__c ) {
                 fundRequestIdSet.add(fundClaim.Fund_Request__c);
            }
         }
        
    }
    Map<Id,Account> accountMap = null;
    if (accountIdSet != null && accountIdSet.size() > 0) {
        accountMap = new Map<Id,Account>([select id,OwnerId, Name from account where Id IN: accountIdSet]);
    }
     Map<Id, Integer> accountSeqMap = null;
     Map<Id,User> partnerAccts = null;
    //Create a map of the owernids to their partner accounts
    if (ownerIds!= null && ownerIds.size() > 0) {
        partnerAccts = new Map<Id,User>([Select Id, Contact.Account.Id,Contact.Account.OwnerId from User where id in :ownerIds]);
        if (partnerAccts != null && partnerAccts.size() > 0) {
            for(User currentUser : partnerAccts.values()) {
                accountIdSet.add(currentUser.Contact.Account.Id);
            }
        }
    }
    if (accountIdSet != null && accountIdSet.size() > 0) {
        accountSeqMap = Util.getMaxSequenceForGivenAccounts(accountIdSet,Util.FUND_CLAIM);
    }
    Map<Id, Decimal> fundRequestClaimedAmountMap = null;
    Map<Id, SFDC_MDF__c> fundRequestMap = null;
    if (fundRequestIdSet != null && fundRequestIdSet.size() > 0) {
        fundRequestClaimedAmountMap = Util.getClaimedAmtsForAGivenFundRequest(fundRequestIdSet);
        fundRequestMap = new Map<Id,SFDC_MDF__c>([Select Name, Id, Status__c, Funding_Approved__c From SFDC_MDF__c Where Status__c ='Approved' and Id IN : fundRequestIdSet]);
    } 
  
    
    //Now loop through each fund claim to set the Partner Account Id on the claim
    Integer sequence = 0;
    Id oldAccountId = null;
    Decimal claimedAmount = 0;
    Decimal frApprovedAmount = 0;
    Boolean hasInSufficientFundsTest = false;
    SFDC_MDF_Claim__c oldClaim = null;
    boolean amountChange = false;
    for (SFDC_MDF_Claim__c fundClaim : Trigger.new) {
         amountChange = false;
         if (Trigger.isUpdate) {
            oldClaim = Trigger.oldMap.get(fundClaim.Id);
            if (oldClaim.Approved_Amount__c != fundClaim.Approved_Amount__c ) {
                hasInSufficientFundsTest = true;
            }
            if (Util.hasChanges('Amount__c', trigger.oldMap.get(fundClaim.Id), fundClaim)) {
                amountChange = true;
            } else if (fundClaim.Amount_In_Corporate_Currency__c == null) {
                amountChange = true;
            }
         } else {
            hasInSufficientFundsTest = true;
            amountChange = true;
         } 
         //Vinay: isMultiCurrencyEnabled is made false to disable currency conversion
         isMultiCurrencyEnabled=false;
         if (amountChange) {
            if(isMultiCurrencyEnabled) {
                Util.convertAmountToCorporateCurrency(currencyMap,fundClaim);
            } else {
                fundClaim.Amount_In_Corporate_Currency__c = fundClaim.Amount__c;
            }
         }
         
         if (hasInSufficientFundsTest) {
             if (fundClaim.Fund_Request__c !=  null && fundRequestClaimedAmountMap != null && fundRequestClaimedAmountMap.containsKey(fundClaim.Fund_Request__c)) {
                claimedAmount = fundRequestClaimedAmountMap.get(fundClaim.Fund_Request__c);
                frApprovedAmount = fundRequestMap.get(fundClaim.Fund_Request__c).Funding_Approved__c;
                //if ((claimedAmount + fundClaim.Amount__c) > frApprovedAmount) {
                if ((claimedAmount + fundClaim.Amount_In_Corporate_Currency__c) > frApprovedAmount) {
                    //Vinay: commenting the below , as our own logic is writted for this.
                    //fundClaim.addError('<BR> Insufficient funds for this claim .Available Funds ' + (frApprovedAmount - claimedAmount));
                }
             }
         }
        //Only update the value for records that have an owner = partnerAccount
        if ((partnerAccts != null && partnerAccts.get(fundClaim.OwnerId).Contact.Account.Id != NULL) && (fundClaim.account__c == NULL)) {
            fundClaim.account__c = partnerAccts.get(fundClaim.OwnerId).Contact.Account.Id;
        }
        
        if ((partnerAccts != null && partnerAccts.get(fundClaim.OwnerId).Contact.Account.OwnerId != NULL) && (fundClaim.Partner_Account_Owner__c == NULL)) {
            fundClaim.Partner_Account_Owner__c = partnerAccts.get(fundClaim.OwnerId).Contact.Account.OwnerId;
        }
        
        if(fundClaim.Partner_Account_Owner__c == null && fundClaim.account__c != null) {
            if (accountMap != null && accountMap.containsKey(fundClaim.account__c)) {
                fundClaim.Partner_Account_Owner__c = accountMap.get(fundClaim.account__c).OwnerId;
            }
        }
        sequence = 0;
        if (fundClaim.account__c != null) {
            if (accountSeqMap != null && accountSeqMap.containsKey(fundClaim.account__c)) {
                sequence = accountSeqMap.get(fundClaim.account__c);
            }
            if (Trigger.isInsert) {
                fundClaim.Sequence__c = sequence + 1;
            } else {
                oldAccountId = trigger.oldMap.get(fundClaim.Id).account__c;
                if( oldAccountId == null || oldAccountId != fundClaim.account__c) {
                    fundClaim.Sequence__c = sequence + 1;
                }
            }
        }
    }
    */  
}