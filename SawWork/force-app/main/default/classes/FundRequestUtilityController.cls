/*

   Anand Hegde - 83% coverage from TestFundRequestUtilityController
   Uncovered - Block_1, Block_2, Block_3


*/
public with sharing class FundRequestUtilityController {
    
    public FundRequestUtilityController(ApexPages.standardController controller) {
        this.request = (SFDC_MDF__c)controller.getRecord();
        HasError=false;
    }
    
    public SFDC_MDF__c request { get; private set; }
    
    public boolean HasError  { get; private set; }
    
    public PageReference back() {
        return new PageReference('/'+this.request.Id);
    }
    
    public PageReference cancelRequest() 
    {
       
        if (this.request.Status__c == 'Submitted') 
        {
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.FATAL, 'The fund request has been submitted for approval. Press "Recall Approval Request" on the fund request record to recall the record.');
            ApexPages.addMessage(msg);
            HasError=true;
            return null;
        }
        List<Budget_Allocation__c>  funfRequestBudgetAllocationList = [Select a.Fund_Request__c, a.Budget__r.Fund_Request_Deadline__c, a.Budget__c From Budget_Allocation__c a Where a.Fund_Request__c =:this.request.Id];
        if (funfRequestBudgetAllocationList != null && funfRequestBudgetAllocationList.size() > 0) 
        {
            Boolean hasExpiredBudgets = false;
            for (Budget_Allocation__c budgetAllocation : funfRequestBudgetAllocationList) {
                if (budgetAllocation.Budget__r.Fund_Request_Deadline__c <= System.today()) 
                {
                    hasExpiredBudgets = true;
                    break;
                }
            }
            if (hasExpiredBudgets) 
            {
                RequestAndClaimUtility.updateExpiredFundRequest(this.request); 
            }
        }
        
        list<SFDC_MDF_Claim__c> claims = new list<SFDC_MDF_Claim__c>([select Id,Name,Status__c from SFDC_MDF_Claim__c where Fund_Request__c = :this.request.Id]);
        if (claims.size() == 0) 
        {
            List<Budget_Allocation__c>  budgetAllocationList = [Select a.RecordTypeId, a.Name, a.Id, a.Fund_Request__c, a.Approved__c From Budget_Allocation__c a where a.Fund_Request__c =: this.request.Id];
            RequestAndClaimUtility.cancelFundRequest(this.request,budgetAllocationList);
            PageReference pageRef = new PageReference('/' + this.request.Id);
            return pageRef;
        } 
        else 
        {
            String prmMdfSettingValue = GsmUtilClass.getPRMSettingValue('MDF_Allow_FR_Cancel_if_FC_Status_Not_In'); //SFDC-2568
            if (prmMdfSettingValue != null)
            {
                List<String> statusStrList = prmMdfSettingValue.split(',');
                String fundClaimNames = '';
                boolean matched = false;
                String statusNames='';
                Set<Id> claimIdSet = new Set<Id>();
                for(SFDC_MDF_Claim__c claimInfo : claims) 
                {
                    matched = false;
                    for (String currentStatus : statusStrList) 
                    {
                        if (claimInfo.Status__c.equalsIgnoreCase(currentStatus)) 
                        {
                            fundClaimNames = fundClaimNames + claimInfo.Name + ' ,';
                            matched = true;
                            statusNames = statusNames + currentStatus + ',';
                            break;
                        }
                    }
                    if (!matched) 
                    {
                        //Block_1 begins
                        claimInfo.Status__c = 'Cancelled';
                        claimIdSet.add(claimInfo.Id);
                        //Block_1 ends
                    }
                }
                if (fundClaimNames == '') 
                {
                    //Block_2 begins
                    List<Budget_Allocation__c>  budgetAllocationList = [Select a.RecordTypeId, a.Name, a.Id, a.Fund_Request__c, a.Approved__c From Budget_Allocation__c a where a.Fund_Claim__c IN: claimIdSet];
                    List<Budget_Allocation__c>  frBudgetAllocationList = [Select a.RecordTypeId, a.Name, a.Id, a.Fund_Request__c, a.Approved__c From Budget_Allocation__c a where a.Fund_Request__c =: this.request.Id];
                    RequestAndClaimUtility.cancelFundRequest(this.request,frBudgetAllocationList,claims, budgetAllocationList);
                    PageReference pageRef = new PageReference('/' + this.request.Id);
                    return pageRef;
                    //Block_2 ends
                } 
                else 
                {
                    String errorMsg = 'You can not cancel this request because it has associated fund claims.';
                    errorMsg = errorMsg + ' Claims that are associated are  ';
                    if(fundClaimNames!='')
                    fundClaimNames=fundClaimNames.substring(0,(fundClaimNames.length()-1));
                    errorMsg = errorMsg + fundClaimNames;
                    ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.FATAL, errorMsg);
                    ApexPages.addMessage(msg);
                    HasError=true;
                }
            } 
            else 
            {
                //Block_3 
                String errorMsg = 'This request has a Fund Claim against it, and cannot be cancelled.';
                ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.FATAL, errorMsg);
                ApexPages.addMessage(msg);
                HasError=true;
            } 
            return null;
        }
    }
}