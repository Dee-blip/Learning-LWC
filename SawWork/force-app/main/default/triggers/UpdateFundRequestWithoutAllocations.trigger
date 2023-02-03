trigger UpdateFundRequestWithoutAllocations on SFDC_MDF__c (before insert ,before update) {
PRMTriggerClass.FRUpdateFundRequestWithoutAllocationsTriggerMethod(Trigger.new, Trigger.oldMap, Trigger.newMap);
/*
    MDF_Configurations__c mdfConfigurations = Util.getConfigurations();
    Set<Id> accountIdSet = new Set<Id>();
    boolean isMultiCurrencyEnabled = Util.isMultiCurrencyEnabled();
    Map<String, CurrencyWrapper>  currencyMap = null;
    if (isMultiCurrencyEnabled) {
        currencyMap =Util.getCurrencies();
    }
    
    for(SFDC_MDF__c fr : trigger.new){
        String newStatus = fr.Status__c == null ? '' : fr.Status__c;
        String oldStatus = null;
        Decimal oldAmount = null;
        String oldAccount = null;
        if ( trigger.oldMap != null) {
            oldStatus = trigger.oldMap.get(fr.Id).Status__c;
            oldAmount = trigger.oldMap.get(fr.Id).Amount__c;
            oldAccount = trigger.oldMap.get(fr.Id).Account__c;
        }
        if(!newStatus.equals(oldStatus) && (newStatus.equals('Draft') || newStatus.equals('Submitted') || newStatus.equals('In Process'))){
            if (fr.Account__c != null && fr.Account__c != oldAccount && fr.Fund_Budget_Allocations__r.isEmpty()) {
                accountIdSet.add(fr.Account__c);
            }
        }
        if (oldAmount == null || oldAmount != fr.Amount__c || fr.Amount_In_Corporate_Currency__c == null) {
            if(isMultiCurrencyEnabled) {
                Util.convertAmountToCorporateCurrency(currencyMap,fr);
            } else {
                fr.Amount_In_Corporate_Currency__c = fr.Amount__c;
            }
            accountIdSet.add(fr.Account__c);
        }
    }
        
    if (mdfConfigurations != null && mdfConfigurations.Block_Insufficient_Funds_Request__c && accountIdSet.size() > 0) {
        Map<Id,SObject> accountMap = null;
        if(mdfConfigurations.Account_Region_Field_Name__c != null ) {
            accountMap = Util.getAccountRegions(accountIdSet,mdfConfigurations);
        }
        Map<Id, Decimal> accountAvlBudgetMap = Util.getAvlBudgetForGivenAccounts(accountIdSet);
        System.debug('accountAvlBudgetMap--------->'+ accountAvlBudgetMap);
        Decimal avlBudget = 0;
        Boolean validateInsufficientFunds = true;
        for(SFDC_MDF__c fr : trigger.new){
            validateInsufficientFunds = true;
            if(mdfConfigurations.Account_Region_Field_Name__c != null && mdfConfigurations.Regions_Without_Fund_Allocations__c != null) {
                if (accountMap != null && accountMap.containsKey(fr.Account__c)) {
                    validateInsufficientFunds = Util.checkValidationFundRequired(accountMap.get(fr.Account__c), mdfConfigurations);
                }
            }
            if (validateInsufficientFunds) {
                if (accountAvlBudgetMap != null && accountAvlBudgetMap.containsKey(fr.Account__c)) {
                    avlBudget = accountAvlBudgetMap.get(fr.Account__c);
                    System.debug('avlBudget--------->'+ avlBudget);
                    System.debug('fr.Amount_In_Corporate_Currency__c--------->'+ fr.Amount_In_Corporate_Currency__c);
                    if (fr.Amount_In_Corporate_Currency__c > avlBudget) {
                        fr.addError(Label.Insufficient_Funds_Request_Msg+' '+ avlBudget);
                    } else {
                        accountAvlBudgetMap.put(fr.Account__c, (avlBudget - fr.Amount_In_Corporate_Currency__c));
                    }
                } 
            }
        }   
    }
    */
}