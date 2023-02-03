/*
This class contains all the triggers used by Following objects
- Fund Accrual
- Fund Budget
- Fund Claim
- Fund Request
- Fund Budget Allocation
*/
global class PRMTriggerClass
{
    public static boolean FundAccrualTriggerFirstRunFlag = true;
    public static boolean FundBudgetTriggerFirstRunFlag = true;
    public static boolean FundClaimTriggerFirstRunFlag = true;
    public static boolean FundClaimTriggerFirstRunFlag1 = true;
    public static boolean FundClaimTriggerFirstRunFlag2 = true;
    public static boolean FundClaimTriggerFirstRunFlag3 = true;
    public static boolean FundClaimTriggerFirstRunFlag4 = true;
    public static boolean FundRequestTriggerFirstRunFlag1 = true;
    public static boolean FundRequestTriggerFirstRunFlag2 = true;
    public static boolean FundRequestTriggerFirstRunFlag3 = true;
    public static boolean FundRequestTriggerFirstRunFlag4 = true;
    public static boolean FundRequestTriggerFirstRunFlag5 = true;
    public static boolean FundRequestTriggerFirstRunFlag6 = true;
    public static boolean FBATriggerFirstRunFlag = true;
    public static Map<string,string> prmMdfMap = GsmUtilClass.getPRMSettingKeyValue('MDF_'); //SFDC-2568
    
    public static void InitializeFlagVariables()
    {
        FundAccrualTriggerFirstRunFlag = true;
        FundBudgetTriggerFirstRunFlag = true;
        FundClaimTriggerFirstRunFlag = true;
        FundClaimTriggerFirstRunFlag1 = true;
        FundClaimTriggerFirstRunFlag2 = true;
        FundClaimTriggerFirstRunFlag3 = true;
        FundClaimTriggerFirstRunFlag4 = true;
        FundRequestTriggerFirstRunFlag1 = true;
        FundRequestTriggerFirstRunFlag2 = true;
        FundRequestTriggerFirstRunFlag3 = true;
        FundRequestTriggerFirstRunFlag4 = true;
        FundRequestTriggerFirstRunFlag5 = true;
        FundRequestTriggerFirstRunFlag6 = true;
        FBATriggerFirstRunFlag = true;
    }
    
    public static void FundAccrualTriggerMethod(list<SFDC_Fund_Accural__c> Triggernew , map<id,SFDC_Fund_Accural__c> TriggeroldMap,map<id,SFDC_Fund_Accural__c> TriggernewMap)
    {
        if (!FundAccrualTriggerFirstRunFlag)
            return; 
        Set<String> accountMatchingIdSet = new Set<String>();
       // MDF_Configurations__c mdfConfigurations = GsmUtilClass.getConfigurations();

        Set<Id> accountIdSet = new Set<Id>();
        Map<Id,SFDC_Fund_Accural__c> fundAccrualMap = new Map<Id,SFDC_Fund_Accural__c>();
        for(SFDC_Fund_Accural__c fundAccural : Triggernew){
            if (Trigger.isInsert) {
                if(fundAccural.Account_Match_Id__c != null) {
                    accountMatchingIdSet.add(fundAccural.Account_Match_Id__c);
                }
            } else {
                if(fundAccural.Account__c != null) {
                    fundAccrualMap.put(fundAccural.Id,fundAccural);
                    accountIdSet.add(fundAccural.Account__c);
                } else {
                    if(fundAccural.Account_Match_Id__c != null) {
                        accountMatchingIdSet.add(fundAccural.Account_Match_Id__c);
                    }
                }
            }
        }
   
        if(accountMatchingIdSet.size() > 0 ) {
            List<Account> accountList =GsmUtilClass.getAccountDetailsGivenNames(accountMatchingIdSet,prmMdfMap);
        
            Map<String , Account> accountMap = null; 
            if (accountList != null && accountList.size() > 0) {
                accountMap = new Map<String , Account>();
                String value = null;
                String fieldName = GsmUtilClass.getAccountIdentityFieldName(prmMdfMap);
                for(SObject currentAccount : accountList) {
                    if(fieldName != null) {
                        value = (String)currentAccount.get(fieldName);
                        if (fieldName.equalsIgnoreCase('Id')) {
                            value = (String)currentAccount.get(fieldName);
                            if (value.length() > 15) {
                                value = value.substring(0,15);
                            }
                        }  
                        accountMap.put(value, (Account)currentAccount);
                    }
                }
            }
        
            List<SFDC_Budget__c> fundBudgetList = new List<SFDC_Budget__c>();
            String value = null;
            Map<String,String> fundAccuralAndAccountIdMap = new Map<String,String>();
            for(SFDC_Fund_Accural__c fundAccural : Triggernew){
                if (fundAccural.Account_Match_Id__c != null && accountMap !=null && accountMap.containsKey(fundAccural.Account_Match_Id__c)) {
                    fundBudgetList.add(GsmUtilClass.createFundBudgetGivenDetails(accountMap.get(fundAccural.Account_Match_Id__c), fundAccural,prmMdfMap));
                    fundAccuralAndAccountIdMap.put(fundAccural.Id, accountMap.get(fundAccural.Account_Match_Id__c).Id);
                } else {
                    fundAccural.addError('Unable to create a budget from this accrual \n Account does not exist');
                }
            }
            Map<String,String> accountIdAndBudgetIdMap = new Map<String,String>();
            if (fundBudgetList != null && fundBudgetList.size() > 0) {
                insert fundBudgetList;
                for(SFDC_Budget__c fundBuget : fundBudgetList) {
                    accountIdAndBudgetIdMap.put(fundBuget.Account__c,fundBuget.Id);
                }
              
                GsmUtilClass.updateFundAccuralWithAccountAndBudgetDetails(fundAccuralAndAccountIdMap,accountIdAndBudgetIdMap);  
            }
        }
        if(fundAccrualMap.size() > 0) {
            Map<Id,SObject> accountMap = GsmUtilClass.getAccountDetailsGivenIds(accountIdSet,prmMdfMap); 
            List<SFDC_Budget__c> updateFundBudgetList = new List<SFDC_Budget__c>();
            Account accountInfo = null;
            for(SFDC_Fund_Accural__c fundAccural :fundAccrualMap.values()) {
                accountInfo = (Account)accountMap.get(fundAccural.Account__c);
                if (accountInfo != null) {
                    updateFundBudgetList.add(GsmUtilClass.createFundBudgetGivenDetails(accountInfo, fundAccural,prmMdfMap, new SFDC_Budget__c(Id=fundAccural.Fund_Budget__c)));
                }
            }
            if (updateFundBudgetList.size() > 0) {
                update updateFundBudgetList;
            }
        }
        FundAccrualTriggerFirstRunFlag = false;
    }
    
  /*  public static void FBShareBudgetWithPartnerTriggerMethod(list<SFDC_Budget__c> Triggernew , map<id,SFDC_Budget__c> TriggeroldMap,map<id,SFDC_Budget__c> TriggernewMap)
    {
        if (!FundBudgetTriggerFirstRunFlag)
            return;
        //map - FBId => PartnerId
        Map<Id, Id> sObject_partner_map = new Map<Id, Id>();
        //map - FBId => Old PartnerId
        Map<Id, Id> sObject_oldPartner_map = new Map<Id, Id>();
 
        for (SFDC_Budget__c budget : Triggernew) {
            Boolean partnerChanged = trigger.isUpdate && Util.hasChanges('Account__c', 
            TriggeroldMap.get(budget.Id), budget);
            if (partnerChanged) { 
                sObject_oldPartner_map.put(budget.Id, TriggeroldMap.get(budget.Id).Account__c);
            }
            if (trigger.isInsert || partnerChanged) {
                sObject_partner_map.put(budget.Id, budget.Account__c);
            }
        }
  
        if (! sObject_oldPartner_map.isEmpty()) {
            FundBudgetShares.removeFundBudgetShare(sObject_oldPartner_map);
        }

        if (! sObject_partner_map.isEmpty()) {
            FundBudgetShares.createFBShare(sObject_partner_map);
        }
        FundBudgetTriggerFirstRunFlag = false;
    }
    */
    public static void FCUpdateFundClaimPartnerAccountTriggerMethod(list<SFDC_MDF_Claim__c> Triggernew , map<id,SFDC_MDF_Claim__c> TriggeroldMap,map<id,SFDC_MDF_Claim__c> TriggernewMap)
    {
        if (!FundClaimTriggerFirstRunFlag1)
            return;
        Set<Id> ownerIds = new Set<Id>();
        Set<Id> accountIdSet = new Set<Id>();
        Set<Id> fundRequestIdSet = new Set<Id>();
    
        boolean isMultiCurrencyEnabled = Util.isMultiCurrencyEnabled();
        Map<String, CurrencyWrapper>  currencyMap = null;
        if (isMultiCurrencyEnabled) {
            currencyMap =Util.getCurrencies();
        }
    
        //Loop through each fund claim and create a Set of all the UserIds for the fund claim owners 
        for (SFDC_MDF_Claim__c fundClaim : Triggernew) {
            SFDC_MDF_Claim__c oldFundClaim = null;
            Id oldAccountId = null;
            if (Trigger.isUpdate) {
                oldFundClaim = TriggeroldMap.get(fundClaim.Id);
                oldAccountId = TriggeroldMap.get(fundClaim.Id).account__c;
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
            accountSeqMap = GsmUtilClass.getMaxSequenceForGivenAccounts(accountIdSet,Util.FUND_CLAIM);
        }
        Map<Id, Decimal> fundRequestClaimedAmountMap = null;
        Map<Id, SFDC_MDF__c> fundRequestMap = null;
        if (fundRequestIdSet != null && fundRequestIdSet.size() > 0) {
            fundRequestClaimedAmountMap = GsmUtilClass.getClaimedAmtsForAGivenFundRequest(fundRequestIdSet);
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
        for (SFDC_MDF_Claim__c fundClaim : Triggernew) {
             amountChange = false;
             if (Trigger.isUpdate) {
                oldClaim = TriggeroldMap.get(fundClaim.Id);
                if (oldClaim.Approved_Amount__c != fundClaim.Approved_Amount__c ) {
                    hasInSufficientFundsTest = true;
                }
                if (Util.hasChanges('Amount__c', TriggeroldMap.get(fundClaim.Id), fundClaim)) {
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
                 if (fundClaim.Fund_Request__c !=  null && fundRequestClaimedAmountMap != null && fundRequestClaimedAmountMap.containsKey(fundClaim.Fund_Request__c) && fundRequestMap.containsKey(fundClaim.Fund_Request__c)) {
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
                    oldAccountId = TriggeroldMap.get(fundClaim.Id).account__c;
                    if( oldAccountId == null || oldAccountId != fundClaim.account__c) {
                        fundClaim.Sequence__c = sequence + 1;
                    }
                }
            }
        }
        FundClaimTriggerFirstRunFlag1 = false;
    }
    
    public static void FCValidateFundClaimOnApprovalTriggerMethod(list<SFDC_MDF_Claim__c> Triggernew , map<id,SFDC_MDF_Claim__c> TriggeroldMap,map<id,SFDC_MDF_Claim__c> TriggernewMap)
    {
        if (!FundClaimTriggerFirstRunFlag2)
            return;
       // MDF_Configurations__c mdfConfigurations = GsmUtilClass.getConfigurations();

        Set<Id> verifiedFcIds = new Set<Id>();
        Set<Id> frIds = new Set<Id>();
        Set<Id> submittedFcIds = new Set<Id>();
        //SFDC-3953 start
        Map<Id, List<ContentDocumentLink>> fundClaimAttachmentMap = new Map<Id, List<ContentDocumentLink>>();
        //SFDC-3953 end
    
        for(SFDC_MDF_Claim__c fc : Triggernew){
          SFDC_MDF_Claim__c oldFcInfo = TriggeroldMap.get(fc.Id);
          if (oldFcInfo.Status__c != fc.Status__c) {
            if ('Submitted'.equalsIgnoreCase(fc.Status__c)) {
                submittedFcIds.add(fc.Id);
            } else if ('Verified'.equalsIgnoreCase(fc.Status__c)) {
              verifiedFcIds.add(fc.Id);
            }
        }
        }
    
    //    if (mdfConfigurations != null && mdfConfigurations.Alert_Claim_Without_Attachments__c && submittedFcIds.size() > 0) {
            if(prmMdfMap.get('MDF_Alert_Claim_Without_Attachments').touppercase() == 'TRUE' && submittedFcIds.size() > 0){
            //SFDC-3953 start
                        for(ContentDocumentLink attachment : [SELECT ContentDocumentId, LinkedEntityId, ContentDocument.LatestPublishedVersionId, ContentDocument.LatestPublishedVersion.Title FROM ContentDocumentLink WHERE LinkedEntityId IN : submittedFcIds ]) {
                                if (!fundClaimAttachmentMap.containsKey(attachment.LinkedEntityId)) {
                                        fundClaimAttachmentMap.put(attachment.LinkedEntityId, new List<ContentDocumentLink>());
                                }
                                fundClaimAttachmentMap.get(attachment.LinkedEntityId).add(attachment);
                        }
                        //SFDC-3953 end
    
        }
    
        if (verifiedFcIds.size() > 0) {
          for(SFDC_MDF_Claim__c fc :[Select Id, (Select Id, Reserve_Closed__c from Fund_Budget_Allocations__r) from SFDC_MDF_Claim__c where Id in :verifiedFcIds]){
            if (fc.Fund_Budget_Allocations__r.isEmpty()) {
               fc.addError(Label.No_Alocations_On_Fund_Claim_On_Verified_Status);
            }
        }   
        }
    
        for(SFDC_MDF_Claim__c fc : Triggernew){
            String newStatus = fc.Status__c == null ? '' : fc.Status__c;
            String oldStatus = TriggeroldMap.get(fc.Id).Status__c == null ? '' : TriggeroldMap.get(fc.Id).Status__c;
        
            //Verify field before update
            if(trigger.isBefore){
                //Verify fields before a Fund Claim is 'Verified'
                if(!newStatus.equals(oldStatus) && newStatus.equals('Verified')){
                    if(!fc.Performance_Attached__c){
                        fc.addError(Label.Performance_Verification_Msg);
                    }
                    if(!fc.Performance_Verified__c){
                        fc.addError(Label.Performance_Verification_Msg);
                    }
                    if(fc.Performance_Verified_Date__c == null){
                        fc.addError(Label.Empty_Performance_Date_Msg);
                    }
                }
            
                //Verify fields before a Fund Claim is 'Paid'
                //if (mdfConfigurations != null && mdfConfigurations.Payment_Details_Validation__c) {
                if(prmMdfMap.get('MDF_Payment_Details_Validation').touppercase() == 'TRUE' || Test.isRunningTest()){
                    if(!newStatus.equals(oldStatus) && newStatus.equals('Paid')){
                        String refNum = fc.Paid_Check_Number__c == null ? '' : fc.Paid_Check_Number__c;
                        String settlementMethod = fc.Settlement_Method__c == null ? '' : fc.Settlement_Method__c;
                        if(fc.Claim_Paid_Date__c == null){
                            fc.addError(Label.Empty_Claim_Date_Msg);
                        }
                        if(refNum.equals('')){
                            fc.addError(Label.Empty_Settlement_Reference_Number);
                        }
                        if(fc.Invoice_Date_del__c == null){
                            fc.addError(Label.Empty_Invoice_Date);
                        }
                        if(settlementMethod.equals('')){
                            fc.addError(Label.Empty_Settlement_Method);
                        }
                    
                        frIds.add(fc.Fund_Request__c);
                    }
                }
                // if (mdfConfigurations != null && mdfConfigurations.Alert_Claim_Without_Attachments__c) {
                if(prmMdfMap.get('MDF_Alert_Claim_Without_Attachments').touppercase() == 'TRUE'){
                    if(!newStatus.equals(oldStatus) && newStatus.equals('Submitted')){
                        if (!fundClaimAttachmentMap.containsKey(fc.Id)) {
                            fc.addError(Label.Fund_Claim_Without_Attachments_Msg);
                        }
                    }
                }
            }
        }

        List<Budget_Allocation__c> budgetAllocations = new List<Budget_Allocation__c>();
    
        if (! frIds.isEmpty()) { //
            for(Budget_Allocation__c fba : [Select Id, Reserve_Closed__c, Temp_Actual_Spent__c from Budget_Allocation__c where Fund_Request__c In :frIds]) {
                fba.Reserve_Closed__c = true;
                fba.Actual_Spend__c = fba.Temp_Actual_Spent__c;
                budgetAllocations.add(fba);
            }
        }
        if (! budgetAllocations.isEmpty()) {
            update budgetAllocations;
        }   
        FundClaimTriggerFirstRunFlag2 = false;
    }
    
    public static void FCCreateFundClaimSharesTriggerMethod(list<SFDC_MDF_Claim__c> Triggernew , map<id,SFDC_MDF_Claim__c> TriggeroldMap,map<id,SFDC_MDF_Claim__c> TriggernewMap)
    {
        if(!FundClaimTriggerFirstRunFlag3)
            return;
        //map - SObjectId => PartnerId
        Map<Id, Id> sObject_partner_map = new Map<Id, Id>();
        //map - SObjectId => Old PartnerId
        Map<Id, Id> sObject_oldPartner_map = new Map<Id, Id>();
        //  DataPrime__c fundClaimPrime = DataPrime__c.getValues('Fund Claim');
        //  Boolean PRIME = fundClaimPrime.Prime__c;

        Map<Id, Id> fundRequestIds = new Map<Id, Id>();
        Map<Id, Id> oldFundRequestIds = new Map<Id, Id>();
    
        for (SFDC_MDF_Claim__c sObj : Triggernew) {
            Boolean frChanged = trigger.isUpdate && Util.hasChanges('Fund_Request__c', 
                TriggeroldMap.get(sObj.Id), sObj);
            if (frChanged) { 
                oldFundRequestIds.put(sObj.Id, TriggeroldMap.get(sObj.Id).Fund_Request__c);
            }

    //      if ((trigger.isInsert || PRIME) && sObj.Fund_Request__c != null) {
            if ((trigger.isInsert ) && sObj.Fund_Request__c != null) {
                fundRequestIds.put(sObj.Id, sObj.Fund_Request__c);
            }
        }
        if (oldFundRequestIds.size() > 0 || fundRequestIds.size() > 0) {
          Map<Id, SFDC_MDF__c> fundRequestMap = new Map<Id, SFDC_MDF__c>([Select Account__c from SFDC_MDF__c where Id In :fundRequestIds.values() Or Id In :oldFundRequestIds.values()]);
  
          for (Id sObjId : fundRequestIds.keySet()) {
              Id distyId = fundRequestMap.get(fundRequestIds.get(sObjId)).Account__c;
              if (distyId != null) {
                  sObject_partner_map.put(sObjId, distyId);
              }
          }
  
          for (Id sObjId : oldFundRequestIds.keySet()) {
              Id distyId = fundRequestMap.get(oldFundRequestIds.get(sObjId)).Account__c;
              if (distyId != null) {
                  sObject_oldPartner_map.put(sObjId, distyId);
            }
        }
          if (! sObject_oldPartner_map.isEmpty()) {
              if(!(Test.isRunningTest() && Limits.getFutureCalls() >= Limits.getLimitFutureCalls()))
              {
                FundBudgetShares.removeFundClaimShare(sObject_oldPartner_map);
              }              
        }
  
          if (! sObject_partner_map.isEmpty()) {
            if(!(Test.isRunningTest() && Limits.getFutureCalls() >= Limits.getLimitFutureCalls()))
              {
               FundBudgetShares.createFCShare(sObject_partner_map);
              }
        }
        }   
        FundClaimTriggerFirstRunFlag3 = false;  
    }
    
    public static void FCUpdateFundRequestWithClaimcountTriggerMethod(list<SFDC_MDF_Claim__c> Triggernew , map<id,SFDC_MDF_Claim__c> TriggeroldMap,map<id,SFDC_MDF_Claim__c> TriggernewMap, list<SFDC_MDF_Claim__c> Triggerold)
    {
        if(!FundClaimTriggerFirstRunFlag4)  
            return;
        List <SFDC_MDF__c> FRlist = new List<SFDC_MDF__c>();
        Decimal count;
        Decimal fundingAmt;
        Set<Id> frIds = new Set<Id>();
        if (Trigger.isInsert){  
            for(SFDC_MDF_Claim__c fundClaim : Triggernew){
                frIds.add(fundClaim.Fund_Request__c);
            }       
        
            for(SFDC_MDF__c fr : [Select NumClaims__c, Funding_Approved__c From SFDC_MDF__c where Id in :frIds]){
                count = 1;
                if (fr.NumClaims__c != null){
                    count = fr.NumClaims__c + 1;
                }
                fundingAmt = fr.Funding_Approved__c == null ? 0 : fr.Funding_Approved__c;
                FRlist.add(new SFDC_MDF__c(Id = fr.Id, NumClaims__c = count, Funding_Approved__c = fundingAmt));          
            }    
        } else {
            for(SFDC_MDF_Claim__c fundClaim : Triggerold){
                frIds.add(fundClaim.Fund_Request__c);
            }
        
            for(SFDC_MDF__c fr : [Select NumClaims__c, Funding_Approved__c From SFDC_MDF__c where Id in :frIds]){
                count = 0;
                if (fr.NumClaims__c != null){
                    count = fr.NumClaims__c - 1;
                }
                fundingAmt = fr.Funding_Approved__c == null ? 0 : fr.Funding_Approved__c;
                FRlist.add(new SFDC_MDF__c(Id = fr.Id, NumClaims__c = count, Funding_Approved__c = fundingAmt));          
            }   
        }
        if(!FRlist.isEmpty()){
            update FRlist;
        }
        FundClaimTriggerFirstRunFlag4 = false;
    }
    
    public static void FRUpdateFundRequestWithoutAllocationsTriggerMethod(list<SFDC_MDF__c> Triggernew , map<id,SFDC_MDF__c> TriggeroldMap,map<id,SFDC_MDF__c> TriggernewMap)
    {
        if(!FundRequestTriggerFirstRunFlag1)
            return;
      //  MDF_Configurations__c mdfConfigurations = GsmUtilClass.getConfigurations();
        Set<Id> accountIdSet = new Set<Id>();
        boolean isMultiCurrencyEnabled = Util.isMultiCurrencyEnabled();
        Map<String, CurrencyWrapper>  currencyMap = null;
        if (isMultiCurrencyEnabled) 
        {
            currencyMap =Util.getCurrencies();
        }   

        for(SFDC_MDF__c fr : Triggernew)
        {
            String newStatus = fr.Status__c == null ? '' : fr.Status__c;
            String oldStatus = null;
            Decimal oldAmount = null;
            String oldAccount = null;
            if ( TriggeroldMap != null) 
            {
                oldStatus = TriggeroldMap.get(fr.Id).Status__c;
                oldAmount = TriggeroldMap.get(fr.Id).Amount__c;
                oldAccount = TriggeroldMap.get(fr.Id).Account__c;
            }
            if(!newStatus.equals(oldStatus) && (newStatus.equals('Draft') || newStatus.equals('Submitted') || newStatus.equals('In Process')))
            {
                if (fr.Account__c != null && fr.Account__c != oldAccount && fr.Fund_Budget_Allocations__r.isEmpty()) 
                {
                    accountIdSet.add(fr.Account__c);
                }
            }
            if (oldAmount == null || oldAmount != fr.Amount__c || fr.Amount_In_Corporate_Currency__c == null) 
            {
                if(isMultiCurrencyEnabled) 
                {
                    Util.convertAmountToCorporateCurrency(currencyMap,fr);
                } 
                else 
                {
                    fr.Amount_In_Corporate_Currency__c = fr.Amount__c;
                }
                accountIdSet.add(fr.Account__c);
            }
        }   

        if (prmMdfMap.get('MDF_Block_Insufficient_Funds_Request').touppercase() == 'TRUE' && accountIdSet.size() > 0) 
        {
            Map<Id,SObject> accountMap = null;
           // if(mdfConfigurations.Account_Region_Field_Name__c != null ) 
            if(prmMdfMap.get('MDF_Account_Region_Field_Name') != null ) 
            {
                accountMap = GsmUtilClass.getAccountRegions(accountIdSet,prmMdfMap);
            }
            Map<Id, List<SFDC_Budget__c>> accountAvlBudgetMap = GsmUtilClass.getAvlBudgetForGivenAccounts(accountIdSet);
            Map<Id, Decimal> accountIdToUsedUpAmount = new Map<Id, Decimal>();
            System.debug('accountAvlBudgetMap--------->'+ accountAvlBudgetMap);
            Decimal avlBudget = 0;
            Boolean validateInsufficientFunds = true;
            for(SFDC_MDF__c fr : Triggernew)
            {
                validateInsufficientFunds = true;
                if(prmMdfMap.get('MDF_Account_Region_Field_Name') != null && prmMdfMap.get('MDF_Regions_Without_Fund_Allocations') != null) 
                {
                    if (accountMap != null && accountMap.containsKey(fr.Account__c)) 
                    {
                        validateInsufficientFunds = GsmUtilClass.checkValidationFundRequired(accountMap.get(fr.Account__c), prmMdfMap);
                    }
                }
                if (validateInsufficientFunds) 
                {
                    if (accountAvlBudgetMap != null && accountAvlBudgetMap.containsKey(fr.Account__c)) 
                    {
                        List<SFDC_Budget__c> listOfBudgetsForTheAccount = new List<SFDC_Budget__c>();
                        listOfBudgetsForTheAccount = accountAvlBudgetMap.get(fr.Account__c);
                        for(SFDC_Budget__c ithBudget : listOfBudgetsForTheAccount)
                        {
                            if(ithBudget.Fund_Claim_DeadLine__c >= fr.Earliest_FC_Deadline__c && ithBudget.Available_Budget__c!=null)
                            {
                                avlBudget = avlBudget + ithBudget.Available_Budget__c; 
                            }
                        }
                        System.debug('avlBudget--------->'+ avlBudget);
                        System.debug('fr.Amount_In_Corporate_Currency__c--------->'+ fr.Amount_In_Corporate_Currency__c);
                        if((accountIdToUsedUpAmount!=null && accountIdToUsedUpAmount.containsKey(fr.Account__c) && ((fr.Amount_In_Corporate_Currency__c + accountIdToUsedUpAmount.get(fr.Account__c)) > avlBudget)) || (fr.Amount_In_Corporate_Currency__c > avlBudget))
                        {
                            fr.addError(Label.Insufficient_Funds_Request_Msg+' '+ avlBudget);
                        } 
                        else 
                        {
                            if(accountIdToUsedUpAmount!=null && accountIdToUsedUpAmount.containsKey(fr.Account__c))
                            {
                                Decimal currentUsedAmount = accountIdToUsedUpAmount.get(fr.Account__c);
                                accountIdToUsedUpAmount.put(fr.Account__c, currentUsedAmount + fr.Amount_In_Corporate_Currency__c);
                            }
                        }
                    }
                }   
            }
        }
        FundRequestTriggerFirstRunFlag1 = false;
    }
    
    public static void FRUpdateBudgetAllocationOnFundRequestApprovalTriggerMethod(list<SFDC_MDF__c> Triggernew , map<id,SFDC_MDF__c> TriggeroldMap,map<id,SFDC_MDF__c> TriggernewMap)
    {
        // if(!FundRequestTriggerFirstRunFlag2)
        //     return;
        
      //  MDF_Configurations__c mdfConfigurations = GsmUtilClass.getConfigurations();
        SFDC_MDF__c oldMDFRequest = null;
        //Vinay: creating a temp object
        //PRMAutomatefundRequest tempObj;
        Boolean CreateAllocationSuccess;
        //End of the change
        Map<Id,SFDC_MDF__c> fundRequestMap  = new Map<Id,SFDC_MDF__c>();
        Set<Id> accountIdSet = new Set<Id>();
        for (SFDC_MDF__c fundRequest : Triggernew) {
            oldMDFRequest = TriggeroldMap.get(fundRequest.Id);
            if (fundRequest.Status__c == 'Approved' && oldMDFRequest.Status__c != 'Approved') {
              //Vinay: Adding logic to clone the functions of allocate button call, on click of button
            //tempObj = new PRMAutomateFundRequest(fundRequest);
            CreateAllocationSuccess=PRM_opportunity.createBudgetAllocation(fundRequest);//tempObj.validateAllocations();
                if(CreateAllocationSuccess==True)
                {
                  fundRequestMap.put(fundRequest.Id,fundRequest);
                  if (fundRequest.Account__c != null) {
                      accountIdSet.add(fundRequest.Account__c);
                  }
                if (fundRequest.Funding_Approved__c == null) {
                      fundRequest.Funding_Approved__c = fundRequest.Amount_In_Corporate_Currency__c;
                }
                }
                else
                    Continue;
                 //End of the change
            }
        }   
        if (fundRequestMap != null && fundRequestMap.size() > 0) {
          List<Budget_Allocation__c>  bugetAllocationList = [Select b.Name, b.Id, b.Fund_Request__c,b.Approved__c From Budget_Allocation__c b where b.Fund_Request__c IN :fundRequestMap.keySet() ];
          Map<Id, List<Budget_Allocation__c>> fundRequestBudgetAllocationMap = new Map<Id, List<Budget_Allocation__c>>();
          if (bugetAllocationList != null && bugetAllocationList.size() > 0) {
              for(Budget_Allocation__c budgetAllocation : bugetAllocationList) {
                  if (!fundRequestBudgetAllocationMap.containsKey(budgetAllocation.Fund_Request__c)) {
                      fundRequestBudgetAllocationMap.put(budgetAllocation.Fund_Request__c, new List<Budget_Allocation__c>());
                }
                fundRequestBudgetAllocationMap.get(budgetAllocation.Fund_Request__c).add(budgetAllocation);
              }
          }
      
          List<Budget_Allocation__c>  updateBugetAllocationList = new List<Budget_Allocation__c>();
          Map<Id,SObject> accountMap = null;
         // if(mdfConfigurations != null) {
              if(prmMdfMap.get('MDF_Account_Region_Field_Name') != null && accountIdSet.size() > 0) { 
                  accountMap = GsmUtilClass.getAccountRegions(accountIdSet,prmMdfMap);
            }
       // }
        Boolean validateAllocations = true;
        for (SFDC_MDF__c fundRequest : fundRequestMap.values()) {
            validateAllocations = true;
            if (!fundRequestBudgetAllocationMap.containsKey(fundRequest.Id)) {
                if(prmMdfMap.get('MDF_Account_Region_Field_Name') != null && prmMdfMap.get('MDF_Regions_Without_Fund_Allocations') != null) {
                    if (accountMap != null && accountMap.containsKey(fundRequest.Account__c)) {
                        validateAllocations = GsmUtilClass.checkValidationFundRequired(accountMap.get(fundRequest.Account__c), prmMdfMap);
                      }
                  }
                  if (prmMdfMap.get('MDF_Alert_FC_or_FR_Without_Allocations').touppercase() == 'TRUE' && validateAllocations) {
                    trigger.newMap.get(fundRequest.Id).addError('<BR>' +  Label.Fund_Request_Without_Allocations_Msg);
                    }
            } else {
            for (Budget_Allocation__c budgetAllocation : fundRequestBudgetAllocationMap.get(fundRequest.Id)) {
                budgetAllocation.Approved__c = true;
                updateBugetAllocationList.add(budgetAllocation);
            } 
          }
        }
      
        if (updateBugetAllocationList != null && updateBugetAllocationList.size() > 0) {
            update updateBugetAllocationList;
        }
    }   
    FundRequestTriggerFirstRunFlag2 = false;
    }
    
    public static void FRCancelFundRequestTriggerMethod(list<SFDC_MDF__c> Triggernew , map<id,SFDC_MDF__c> TriggeroldMap,map<id,SFDC_MDF__c> TriggernewMap)
    {
        if(!FundRequestTriggerFirstRunFlag3)
            return;
        set<Id> frids = new set<Id>();
         list<SFDC_MDF__c> frlist = new list<SFDC_MDF__c>();
         SFDC_MDF__c oldFundRequest = null;
         for (SFDC_MDF__c fr : Triggernew) {
            oldFundRequest = TriggeroldMap.get(fr.Id);
            if ((fr.Status__c == 'Cancelled') && (oldFundRequest.Status__c != 'Cancelled')) {
                frids.add(fr.Id);
                frlist.add(fr);
            }
        }
        if (frids != null && frids.size() > 0) {
            list<Budget_Allocation__c> updBAs = new list<Budget_Allocation__c>();
            Id rtid = [select Id from RecordType where SObjectType = 'Budget_Allocation__c' and Name = 'Cancelled' limit 1].Id;
            for (Budget_Allocation__c ba : [select Id, RecordTypeId from Budget_Allocation__c where Fund_Request__c in :frids and RecordType.Name = 'Reserved']) 
            {
                ba.RecordTypeId = rtid;
                updBAs.add(ba);
            }
         
            if (updBAs.size() > 0) {
                 try {
                    update updBAs;
                } catch(Exception e) {
                    String message = 'An error occurred: '+ '\nMessage: ' + e.getMessage() + '\nCause: ' + e.getCause();
                    frlist.get(0).addError(message);
                 }
             }
        }
        FundRequestTriggerFirstRunFlag3 = false;
    }
    
    public static void FRUpdateFundRequestPartnerAccountTriggerMethod(list<SFDC_MDF__c> Triggernew , map<id,SFDC_MDF__c> TriggeroldMap,map<id,SFDC_MDF__c> TriggernewMap)
    {
        if(!FundRequestTriggerFirstRunFlag4)
            return;
        Set<Id> ownerIds = new Set<Id>();
         Set<Id> accountIdSet = new Set<Id>();
         boolean isMultiCurrencyEnabled = Util.isMultiCurrencyEnabled();
         Map<String, CurrencyWrapper>  currencyMap = null;
         if (isMultiCurrencyEnabled) {
             currencyMap =Util.getCurrencies();
        }
    
         //Loop through each fund request and create a Set of all the UserIds for the fund request owners 
         for (SFDC_MDF__c fundRequest : Triggernew) {
            SFDC_MDF__c oldFundRequest = null;
          if (Trigger.isUpdate) {
            oldFundRequest = TriggeroldMap.get(fundRequest.Id);
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
            accountSeqMap = GsmUtilClass.getMaxSequenceForGivenAccounts(accountIdSet,Util.FUND_REQUEST);
        }
         Integer sequence = 0;
         Id oldAccountId = null;
         boolean amountChange = false;
         //Now loop through each fund request to set the Partner Account Id on the request
         for (SFDC_MDF__c fundRequest : Triggernew) {
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
                    oldAccountId = TriggeroldMap.get(fundRequest.Id).account__c;
                    if( oldAccountId == null || oldAccountId != fundRequest.account__c) {
                        fundRequest.Sequence__c = sequence + 1;
                    }
                    if (Util.hasChanges('Amount__c', TriggeroldMap.get(fundRequest.Id), fundRequest)) {
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
        FundRequestTriggerFirstRunFlag4 = false;    
    }
    
    public static void FRCreateFundRequestSharesTriggerMethod(list<SFDC_MDF__c> Triggernew , map<id,SFDC_MDF__c> TriggeroldMap,map<id,SFDC_MDF__c> TriggernewMap)
    {
        if(!FundRequestTriggerFirstRunFlag5)
            return;
        //map - FBId => PartnerId
        Map<Id, Id> sObject_partner_map = new Map<Id, Id>();
        //map - FBId => Old PartnerId
        Map<Id, Id> sObject_oldPartner_map = new Map<Id, Id>();

    //  DataPrime__c fundRequestPrime = DataPrime__c.getValues('Fund Request');
    //  Boolean PRIME = fundRequestPrime.Prime__c;
    
        for (SFDC_MDF__c sObj : Triggernew) {
            Boolean partnerChanged = trigger.isUpdate && Util.hasChanges('Account__c', 
                TriggeroldMap.get(sObj.Id), sObj);
    
        if (partnerChanged) { 
            sObject_oldPartner_map.put(sObj.Id, TriggeroldMap.get(sObj.Id).Account__c);
        }

    //      if (trigger.isInsert || partnerChanged || PRIME) {
            if (trigger.isInsert || partnerChanged ) {
                sObject_partner_map.put(sObj.Id, sObj.Account__c);
            }
        }
      
        if (! sObject_oldPartner_map.isEmpty()) {
            if(!(Test.isRunningTest() && Limits.getFutureCalls() >= Limits.getLimitFutureCalls()))
              {
               FundBudgetShares.removeFundRequestShare(sObject_oldPartner_map);
              }
        }
    
        if (! sObject_partner_map.isEmpty()) {
            if(!(Test.isRunningTest() && Limits.getFutureCalls() >= Limits.getLimitFutureCalls()))
              {
               FundBudgetShares.createFRShare(sObject_partner_map);
              }
        }   
        FundRequestTriggerFirstRunFlag5 = false;
    }
    
    public static void FundClaimTrigger(list<SFDC_MDF_Claim__c> Triggernew , map<id,SFDC_MDF_Claim__c> TriggeroldMap,map<id,SFDC_MDF_Claim__c> TriggernewMap)
    {
        if(!FundClaimTriggerFirstRunFlag)
        return;
      //  MDF_Configurations__c mdfConfigurations = GsmUtilClass.getConfigurations();
        SFDC_MDF_Claim__c oldMDFClaim = null;
        //Vinay: creating a temp object
        //PRMAutomateFundClaim tempObj;
        Boolean CreateAllocationSuccess;
        list<SFDC_MDF_Claim__c> FundClaimList = new list<SFDC_MDF_Claim__c>();
        //End of the change
        Map<Id,SFDC_MDF_Claim__c> fundClaimMap  = new Map<Id,SFDC_MDF_Claim__c>();
        //SFDC-3953 start
        Map<Id, List<ContentDocumentLink>> fundClaimAttachmentMap = new Map<Id, List<ContentDocumentLink>>();
        //SFDC-3953 end
        Set<Id> fundRequestIdSet = new Set<Id>();
        //Changed by VINAY for testing curency
        for (SFDC_MDF_Claim__c fundClaim : Triggernew) {
            oldMDFClaim = TriggeroldMap.get(fundClaim.Id);
            system.debug('NEw status'+fundClaim.Status__c +'OLD VALUE '+oldMDFClaim.Status__c);
            if ((fundClaim.Status__c.contains('Approved') && !oldMDFClaim.Status__c.contains('Approved')) || (fundClaim.Status__c == 'Submitted' && oldMDFClaim.Status__c != 'Submitted') || (fundClaim.Amount__c != oldMDFClaim.Amount__c) ) {
                FundClaimList.add(fundClaim);
            }
        }
        Map<Id,Boolean> FcflagMap = new Map<Id,Boolean>();
        if(FundClaimList.size()>0)
        FcflagMap = PRM_opportunity.convertAndCheckFC(FundClaimList);
        // Code for creating budget Allocation for FC
        for (SFDC_MDF_Claim__c fundClaim : Triggernew) {
            oldMDFClaim = TriggeroldMap.get(fundClaim.Id);
            if (fundClaim.Status__c.contains('Approved') && !oldMDFClaim.Status__c.contains('Approved')) {
                //Vinay: Adding logic to clone the functions of allocate button call, on click of button
                Boolean CurrencyValidateSuccess=FcflagMap.get(fundClaim.id);    
               if(CurrencyValidateSuccess==true){
                    //tempObj = new PRMAutomateFundClaim(fundClaim);
                    CreateAllocationSuccess=PRM_opportunity.createBudgetAllocation(fundClaim);//tempObj.saveAllocations();
                    if(CreateAllocationSuccess==True)
                    {
                        fundClaimMap.put(fundClaim.Id,fundClaim);
                        fundRequestIdSet.add(fundClaim.Fund_Request__c);
                    }
                    else
                        Continue;
                }
                //End of the change
            }
        }
        if (fundClaimMap != null && fundClaimMap.size() > 0  && fundRequestIdSet != null && fundRequestIdSet.size() > 0) {
            
            List<Budget_Allocation__c>  bugetAllocationList = [Select b.Name, b.Id, b.Fund_Claim__c,b.Approved__c From Budget_Allocation__c b where b.Fund_Claim__c IN :fundClaimMap.keySet() ];
            Map<Id, List<Budget_Allocation__c>> fundClaimBudgetAllocationMap = new Map<Id, List<Budget_Allocation__c>>();
            if (bugetAllocationList != null && bugetAllocationList.size() > 0) {
                for(Budget_Allocation__c budgetAllocation : bugetAllocationList) {
                    if (!fundClaimBudgetAllocationMap.containsKey(budgetAllocation.Fund_Claim__c)) {
                        fundClaimBudgetAllocationMap.put(budgetAllocation.Fund_Claim__c, new List<Budget_Allocation__c>());
                    }
                    fundClaimBudgetAllocationMap.get(budgetAllocation.Fund_Claim__c).add(budgetAllocation);
                }
            }
            if (prmMdfMap.get('MDF_Alert_Claim_Without_Attachments').touppercase() == 'TRUE') {
                //SFDC-3953 start
                                Set<Id> temporaryIdSet = fundClaimMap.keySet();
                                List<ContentDocumentLink>  attachmentList = [SELECT LinkedEntityId, ContentDocument.LatestPublishedVersion.Title, ContentDocumentId FROM ContentDocumentLink where LinkedEntityId IN :temporaryIdSet ];
                                if (attachmentList != null && attachmentList.size() > 0) {
                                        for(ContentDocumentLink attachment : attachmentList) {
                                                if (!fundClaimAttachmentMap.containsKey(attachment.LinkedEntityId)) {
                                                        fundClaimAttachmentMap.put(attachment.LinkedEntityId, new List<ContentDocumentLink>());
                                                }
                                                fundClaimAttachmentMap.get(attachment.LinkedEntityId).add(attachment);
                                        }
                                }
                                //SFDC-3953 end
            }
            Map<Id,SFDC_MDF__c> fundRequestMap = null;
            Map<Id, List<Budget_Allocation__c>> fundRequestBudgetAllocationMap = null;
            if (fundRequestIdSet.size() > 0) {
                fundRequestMap = new Map<Id,SFDC_MDF__c>([select id, name,Status__c from SFDC_MDF__c where id IN : fundRequestIdSet]);
                
                List<Budget_Allocation__c>  fundRequestBudgetAllocationList = [Select b.Name, b.Id, b.Fund_Request__c,b.Approved__c From Budget_Allocation__c b where b.Fund_Request__c IN :fundRequestIdSet ];
                fundRequestBudgetAllocationMap = new Map<Id, List<Budget_Allocation__c>>();
                if (fundRequestBudgetAllocationList != null && fundRequestBudgetAllocationList.size() > 0) {
                    for(Budget_Allocation__c budgetAllocation : fundRequestBudgetAllocationList) {
                        if (!fundRequestBudgetAllocationMap.containsKey(budgetAllocation.Fund_Request__c)) {
                            fundRequestBudgetAllocationMap.put(budgetAllocation.Fund_Request__c, new List<Budget_Allocation__c>());
                        }
                        fundRequestBudgetAllocationMap.get(budgetAllocation.Fund_Request__c).add(budgetAllocation);
                    }
                }
            }
            
            List<Budget_Allocation__c>  updateBugetAllocationList = new List<Budget_Allocation__c>();
            boolean hasErrors = false;
            for (SFDC_MDF_Claim__c fundClaim : fundClaimMap.values()) {
                hasErrors = false;
                if (fundRequestMap != null &&fundRequestBudgetAllocationMap != null) {
                    if (!(fundRequestMap.get(fundClaim.Fund_Request__c).Status__c.contains('Approved')) || (!fundRequestBudgetAllocationMap.containsKey(fundClaim.Fund_Request__c) || fundRequestBudgetAllocationMap.get(fundClaim.Fund_Request__c).size() == 0)) {
                        TriggernewMap.get(fundClaim.Id).addError('<BR>' +  Label.Fund_Request_has_to_be_approved);
                        hasErrors = true;
                    }
                }
                if (prmMdfMap.get('MDF_Alert_FC_or_FR_Without_Allocations').touppercase() == 'TRUE') {
                    if (!fundClaimBudgetAllocationMap.containsKey(fundClaim.Id)) {
                        TriggernewMap.get(fundClaim.Id).addError('<BR>' +  Label.Fund_Claim_Without_Allocations_Msg);
                        hasErrors = true;
                    }
                }
                if (prmMdfMap.get('MDF_Alert_Claim_Without_Attachments').touppercase() == 'TRUE') {
                    if (!fundClaimAttachmentMap.containsKey(fundClaim.Id)) {
                        TriggernewMap.get(fundClaim.Id).addError('<BR>' +  Label.Fund_Claim_Without_Attachments_Msg);
                        hasErrors = true;
                    }
                }
                if (!hasErrors) {
                    for (Budget_Allocation__c budgetAllocation : fundClaimBudgetAllocationMap.get(fundClaim.Id)) {
                        budgetAllocation.Approved__c = true;
                        updateBugetAllocationList.add(budgetAllocation);
                    } 
                }
            }
            if (updateBugetAllocationList != null && updateBugetAllocationList.size() > 0) {
                update updateBugetAllocationList;
            }
        }
        FundClaimTriggerFirstRunFlag=false;
    }
    
    public static void resetValuesOnDeletingAllocationTrigger(list<Budget_Allocation__c> Triggernew , map<id,Budget_Allocation__c> TriggeroldMap,map<id,Budget_Allocation__c> TriggernewMap, list<Budget_Allocation__c> Triggerold)
    {
        if (!FBATriggerFirstRunFlag)
            return;
            
        Map<Id,Decimal> fundRequestIdAndAmt = new Map<Id,Decimal>();
        Map<Id,Decimal> fundClaimIdAndAmt = new Map<Id,Decimal>();
        Decimal amount = null;
        for (Budget_Allocation__c allocation : Triggerold) {
            if(allocation.Fund_Request__c != null) {
                amount =  allocation.Amount__c;
                if(fundRequestIdAndAmt.containsKey(allocation.Fund_Request__c)) {
                    amount = amount + fundRequestIdAndAmt.get(allocation.Fund_Request__c);
                }
                fundRequestIdAndAmt.put(allocation.Fund_Request__c, amount);
            } else if (allocation.Fund_Claim__c != null) {
                amount =  allocation.Amount__c;
                if(fundClaimIdAndAmt.containsKey(allocation.Fund_Claim__c)) {
                    amount = amount + fundRequestIdAndAmt.get(allocation.Fund_Claim__c);
                }
                fundClaimIdAndAmt.put(allocation.Fund_Claim__c, amount);
            }
        }
    
        if (fundRequestIdAndAmt != null && fundRequestIdAndAmt.size() > 0) {
            List<SFDC_MDF__c> fundRequestList = new List<SFDC_MDF__c>();
            for(SFDC_MDF__c fundRequest : [select id,name,Funding_Approved__c from SFDC_MDF__c Where Id IN : fundRequestIdAndAmt.keySet()]) {

                if(fundRequest.Funding_Approved__c==null)
                    fundRequest.Funding_Approved__c=0;
                fundRequest.Funding_Approved__c = fundRequest.Funding_Approved__c - fundRequestIdAndAmt.get(fundRequest.Id);
                fundRequestList.add(fundRequest);
            }
            update fundRequestList;
        }
        if (fundClaimIdAndAmt != null && fundClaimIdAndAmt.size() > 0) {
            List<SFDC_MDF_Claim__c> fundClaimList = new List<SFDC_MDF_Claim__c>();
            for(SFDC_MDF_Claim__c fundClaim : [select id,name,Approved_Amount__c from SFDC_MDF_Claim__c Where Id IN : fundClaimIdAndAmt.keySet()]) {
                fundClaim.Approved_Amount__c = fundClaim.Approved_Amount__c - fundClaimIdAndAmt.get(fundClaim.Id);
                fundClaimList.add(fundClaim);
            }
            update fundClaimList;
        }
        FBATriggerFirstRunFlag = false;
    }
}