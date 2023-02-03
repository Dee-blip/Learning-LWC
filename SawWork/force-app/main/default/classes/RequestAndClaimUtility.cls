public without sharing class RequestAndClaimUtility {
    
    //SFDC-2135 - Commenting out unused code
    /*public static void createCustomAllocations(SFDC_MDF_Claim__c claim,List<FundClaimCustomAllocationController.BudgetWrapper> bwList) {
        Boolean checkLineBudget = true;
        List<Budget_Allocation__c> allocs = new List<Budget_Allocation__c>();
        List<Budget_Allocation__c> claimAllocations = new List<Budget_Allocation__c>();
        Id rtid = [select Id from RecordType where Name = 'Reserved' and SObjectType = 'Budget_Allocation__c' limit 1].Id;
        for (FundClaimCustomAllocationController.BudgetWrapper bw : bwList) {
            if (bw.tempAllocation > bw.b.Available_Budget__c) {
                ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.FATAL, Label.Individual_allocations_cannot_exceed_Budget);
                ApexPages.addMessage(msg);
                //this.success = false;
                checkLineBudget = false;
                allocs = new list<Budget_Allocation__c>();
                break;
            } else if (bw.tempAllocation > 0) {
                Budget_Allocation__c a = new Budget_Allocation__c(
                    Amount__c = bw.tempAllocation,
                    Budget__c = bw.b.Id,
                    Fund_Request__c = claim.Fund_Request__c,
                    RecordTypeId = rtid,
                    Approved__c = true,
                    Temp_Actual_Spent__c = bw.tempAllocation,
                    Reserve_Closed__c = false
                );
                allocs.add(a);
            }
        }
        if (checkLineBudget && (allocs.size() > 0)) {
            insert allocs;
            Id claimRtid = [select Id from RecordType where Name = 'Claimed' and SObjectType = 'Budget_Allocation__c' limit 1].Id;
            Decimal totalApprovedAmt = 0;
            for (Budget_Allocation__c a : allocs) {
                Budget_Allocation__c claimAllocation = new Budget_Allocation__c(
                Amount__c = a.Amount__c,
                Budget__c = a.Budget__c,
                Fund_Claim__c = claim.Id,
                Reserve_Allocation__c = a.Id,
                Exceeds_Available_Balance__c = false,
                RecordTypeId = claimRtid
                );  
                totalApprovedAmt+= a.Amount__c;    
                claimAllocations.add(claimAllocation); 
            }
            insert claimAllocations;    
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.CONFIRM, allocs.size() + ' allocations saved.');
            ApexPages.addMessage(msg);
            claim.Amount__c = totalApprovedAmt;
            update claim;
        } else {
            throw new MDFException('No Allocations were created. Please contact System Administrator');
        }
    }
    
    public static void createClaimAllocations(SFDC_MDF_Claim__c claim,List<FundClaimAllocationController.Budget> budgets) {
        
        list<Budget_Allocation__c> claimAllocations = new list<Budget_Allocation__c>();
        list<Budget_Allocation__c> updReserves = new list<Budget_Allocation__c>();
        Id rtid = [select Id from RecordType where Name = 'Claimed' and SObjectType = 'Budget_Allocation__c' limit 1].Id;
                    
        for (FundClaimAllocationController.Budget b : budgets) {
            System.debug('b.ba.Temp_Claim_Allocation__c ###:'+ b.ba.Temp_Claim_Allocation__c);
            System.debug('b.ba.Budget__r.Unclaimed_Requests__c ###:'+ b.ba.Budget__r.Unclaimed_Requests__c);
            if(b.ba.Temp_Claim_Allocation__c > b.ba.Budget__r.Unclaimed_Requests__c){
                ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.FATAL, Label.Allocations_Should_not_be_more_than_Avl_funds);
                ApexPages.addMessage(msg);
            }
            if (b.ba.Temp_Claim_Allocation__c > 0) {
                Budget_Allocation__c a = new Budget_Allocation__c(
                    Amount__c = b.ba.Temp_Claim_Allocation__c,
                    Budget__c = b.ba.Budget__r.Id,
                    Fund_Claim__c = claim.Id,
                    Reserve_Allocation__c = b.ba.Id,
                    Exceeds_Available_Balance__c = b.exceedsReserve,
                    RecordTypeId = rtid
                );
                claimAllocations.add(a);
                //update any closed reserve allocations
                Budget_Allocation__c r = new Budget_Allocation__c(
                    Id = b.ba.Id,
                    //Actual_Spend__c = b.ba.Temp_Claim_Allocation__c,
                    Temp_Actual_Spent__c = b.ba.Temp_Claim_Allocation__c,
                    Reserve_Closed__c = b.closeReserve
                );
                updReserves.add(r);
            }
        }
        if (claimAllocations.size() > 0) {
            update claim;
            insert claimAllocations;
            update updReserves;
            
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.CONFIRM, claimAllocations.size() + ' allocations saved.');
            ApexPages.addMessage(msg);
        } else {
            throw new MDFException('No Allocations were created. Please contact System Administrator');
        }
        
    }*/
    
    public static void createRequestAllocations(SFDC_MDF__c request,List<FundRequestAllocationController.BudgetWrapper> bwList) {
        
        Boolean checkLineBudget = true;
        list<Budget_Allocation__c> allocs = new list<Budget_Allocation__c>();
        Id rtid = [select Id from RecordType where Name = 'Reserved' and SObjectType = 'Budget_Allocation__c' limit 1].Id;
        for (FundRequestAllocationController.BudgetWrapper bw : bwList) {
            if (bw.tempAllocation > bw.b.Available_Budget__c) {
                ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.FATAL, Label.Individual_allocations_cannot_exceed_Budget);
                ApexPages.addMessage(msg);
                checkLineBudget = false;
                allocs = new list<Budget_Allocation__c>();
                break;
            } else if (bw.tempAllocation > 0) {
                Budget_Allocation__c a = new Budget_Allocation__c(
                    Amount__c = bw.tempAllocation,
                    Budget__c = bw.b.Id,
                    Fund_Request__c = request.Id,
                    RecordTypeId = rtid
                );
                allocs.add(a);
            }
        }
        if (checkLineBudget && (allocs.size() > 0)) {
            insert allocs;
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.CONFIRM, allocs.size() + ' allocations saved.');
            ApexPages.addMessage(msg);
            //create fund request links for these allocations
            //finally update the FR with the approved amount
            Decimal approvedAmt = GsmUtilClass.getFundRequestApprovedAmount(request.Id, rtid);
            SFDC_MDF__c fr = new SFDC_MDF__c(Id = request.Id, Funding_Approved__c = approvedAmt);
            update fr;
        } else {
            throw new MDFException('No Allocations were created. Please contact System Administrator');
        }
        
        
    }
   
   
    public static void updateExpiredFundRequest(SFDC_MDF__c request) {
        request.Request_Expired__c = true;
        update request;
    } 
    
    public static void cancelFundRequest(SFDC_MDF__c request,List<Budget_Allocation__c>  budgetAllocationList) {
        if (budgetAllocationList != null) {
            delete budgetAllocationList;
        }
        request.Status__c = 'Cancelled';
        request.Funding_Approved__c = null;
        request.Cancelled__c = true;
        update request;
        
    }
    
     public static void cancelFundRequest(SFDC_MDF__c request,List<Budget_Allocation__c>  frBudgetAllocationList,list<SFDC_MDF_Claim__c> claims,List<Budget_Allocation__c>  fcBudgetAllocationList ) {
        if (fcBudgetAllocationList != null) {
            delete fcBudgetAllocationList;
        }
        update claims;
        
        if (frBudgetAllocationList != null) {
            delete frBudgetAllocationList;
        }
        request.Status__c = 'Cancelled';
        request.Cancelled__c = true;
        request.Funding_Approved__c = null;
        update request;
        
    }

}