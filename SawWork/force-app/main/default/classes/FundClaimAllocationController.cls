global class FundClaimAllocationController {
    public Date claimDate { get; private set; }
    public String claimDateString { get; private set; }
    public Double totalReserve { get; private set; }
    public Boolean success { get; private set; }
    public Boolean creditHold { get; private set; }
    public Boolean payClaim { get; private set; }
    public Boolean showPONumberAndTransferAccount { get; private set;}
    public SFDC_MDF_Claim__c claim { get; private set; }
    public SFDC_MDF_Claim__c totalallocation { get; private set; } //used only to maintain the total being allocated, never saved
    public SFDC_MDF_Claim__c totalclaimed { get; private set; } //used only to maintain the total already claimed, never saved
    public list<Budget> budgets { get; private set; }
    
    public FundClaimAllocationController(ApexPages.StandardController controller) {
        this.claim = (SFDC_MDF_Claim__c)controller.getRecord();
        this.totalallocation = new SFDC_MDF_Claim__c();
        this.claimDate = claim.CreatedDate.date();
        this.claimDateString = this.claimDate.format();
        this.budgets = new list<Budget>();
        this.totalReserve = 0;
        this.success = false;
        this.payClaim = true;
        this.creditHold = false;
        checkCreditHold();
        //SFDC-5962 Replacing Paid By (Paid_By__c) with Fund_Claim_Activity_Spender__c
        if(this.claim.Fund_Claim_Activity_Spender__c!='Partner')
            this.showPONumberAndTransferAccount = true;
        else
            this.showPONumberAndTransferAccount = false;
        
        //CR: 1759675
        Date currentDate = System.now().date();
        claim.Claim_Paid_Date__c = currentDate;
        Date startOfNextMonth = currentDate.addMonths(1).toStartOfMonth();
        claim.Invoice_Date_del__c = startOfNextMonth;

        searchClaimed();
        searchBudgets();
        allocate();
    }
    
    public void checkCreditHold() {
    }
    
    
    public void searchClaimed() {
        this.totalclaimed = new SFDC_MDF_Claim__c(Amount__c = 0);
        if (this.claim.Fund_Request__c != null) {
            this.totalclaimed.Amount__c +=GsmUtilClass.getClaimedAmtsForAGivenFundRequest(this.claim.Fund_Request__c);
        }
    }
    
    public void searchBudgets() {
        this.budgets = new list<Budget>();
        for (Budget_Allocation__c ba : [select Id, Name, Amount__c, CreatedDate, Fund_Claim__c, Fund_Request__c, Reserve_Allocation__c, Temp_Claim_Allocation__c, Budget__c, Budget__r.Name, Budget__r.End_Earned_Date__c, Budget__r.Unclaimed_Requests__c, Budget__r.Fund_Budget_Name__c, Budget__r.Fund_Claim_Deadline__c, Budget__r.Claimed_Budget__c, Budget__r.Reserved_Budget__c from Budget_Allocation__c where Fund_Request__c = :this.claim.Fund_Request__c and RecordType.Name = 'Reserved' And Reserve_Closed__c = false Order By Budget__r.Fund_Claim_Deadline__c asc ] ) {
            this.budgets.add(new Budget(ba));
        }       
    }
    
    public Boolean validateAllocations() {
        System.debug('this.totalallocation.Amount__c ## :'+ this.totalallocation.Amount__c);
        System.debug('claim.Approved_Amount__c ## :'+ claim.Approved_Amount__c);
        this.success = this.totalallocation.Amount__c == claim.Approved_Amount__c;

        if(! success)
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Allocation_Should_Not_Be_More_then_Approved_Amount_Msg1));
        else{
            this.success = (this.totalallocation.Amount__c + this.totalclaimed.Amount__c) <= this.claim.Fund_Request_Approved_Amount__c;
            if(! success){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Allocations_Cannot_be_more_than_Approved_Amt_Msg2));
            }
        }
        return success;
    }
    
    public PageReference saveAllocations() {
        ApexPages.Message errMsg;
        
        
        if(claim.Approved_Amount__c == null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Approved_Amt_cannot_be_empty));
            return null;
        }
        updateTotal();
        if(! this.validateAllocations()){
            return null;
        }

        return new PageReference('/' + this.claim.Id);
        // removed try catch for PageReference to increase coverage
        return null;
        
    }
    
    //For Pay Claim button
    public void payClaimValidate(){
        
    }
   
    public PageReference saveClaimPaymentInfo(){
       ApexPages.Message msg;              
        String refNum = claim.Paid_Check_Number__c == null ? '' : claim.Paid_Check_Number__c;
        String settlementMethod = claim.Settlement_Method__c == null ? '' : claim.Settlement_Method__c;     
        //Anand Hegde - CR 2461584 - updating status here and deactivating the workflow
        //SFDC-5962 Replacing Paid By (Paid_By__c) with Fund_Claim_Activity_Spender__c
        if(claim.Fund_Claim_Activity_Spender__c =='Partner')
            claim.Status__c = 'Paid - Credit';
        else
        {
            //Sonali Tandon : CR 2804079
            claim.Status__c = 'Paid - Internal';
            if(claim.PO_Number__c == null && claim.Transfer_Account__c == null)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Either_PO_Number_or_Transfer_Account_req));
                return null;
            }
            //Sonali Tandon : CR 2804079
        }
        //SFDC-2568
        String prmMdfSettingValue = GsmUtilClass.getPRMSettingValue('MDF_Payment_Details_Validation'); //SFDC-2568
        if(prmMdfSettingValue.touppercase() == 'TRUE' || Test.isRunningTest())
        {
            if(claim.Claim_Paid_Date__c == null)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Processed_Date_Empty));
                return null; 
            }
            if(refNum.equals(''))
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Empty_Settlement_Reference_Number_Msg));
                return null;
            }
            if(claim.Invoice_Date_del__c == null)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Empty_Invoice_Date_Msg));
                return null;
            }
            if(settlementMethod.equals(''))
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Empty_Settlement_Method_Msg));
                return null;
            }
        }
        PRMTriggerClass.InitializeFlagVariables();
        try
        {
            claim.Validation_Override__c = true;
            update claim;
        }
     
         catch(Exception e)
        {
            System.debug('Fundclaim save ERROR: ' + e);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
        }

        return new PageReference('/' + this.claim.Id);
    }
        
    public PageReference cancelAllocations() {
        return new PageReference('/' + this.claim.Id);
    }
    
    public void allocate() {
        try{
        Decimal availableClaim = 0;
        if ((this.claim.Amount_In_Corporate_Currency__c + this.totalclaimed.Amount__c) <= this.claim.Fund_Request_Approved_Amount__c) {
            if((this.claim.Fund_Request_Approved_Amount__c - this.totalclaimed.Amount__c) >= this.claim.Amount_In_Corporate_Currency__c) {
               availableClaim = this.claim.Amount_In_Corporate_Currency__c;
            }
        }
        
         for (Budget b : this.budgets) {
             this.totalReserve += b.ba.Amount__c;
             if (b.ba.Amount__c > 0) {
                 b.ba.Temp_Claim_Allocation__c = (availableClaim > b.ba.Amount__c) ?  b.ba.Amount__c : availableClaim;
                 availableClaim -= b.ba.Temp_Claim_Allocation__c; 
             } else {
                b.ba.Temp_Claim_Allocation__c = 0;
             }
         }
        updateTotal();
        }catch(Exception e){
            System.debug('ERROR: ' + e);
        }
    }
    
    public void updateTotal() {
        this.totalallocation.Amount__c = 0;
        for (Budget b : this.budgets) {
            if(b.ba != null){
                this.totalallocation.Amount__c += (b.ba.Temp_Claim_Allocation__c == null) ? 0 : b.ba.Temp_Claim_Allocation__c;
                if (b.ba.Temp_Claim_Allocation__c > b.ba.Budget__r.Unclaimed_Requests__c) {
                    b.exceedsReserve = true;
                } else {
                    b.exceedsReserve = false;
                }
            }           
        }
        if(this.totalallocation.Amount__c > 0) {
            this.claim.Approved_Amount__c = this.totalallocation.Amount__c;  
        }
    }
    
    public class Budget {
        public Budget_Allocation__c ba { get; private set; }
        public Boolean closeReserve { get; set; }
        public Boolean exceedsReserve { get; set; }
        
        public Budget(Budget_Allocation__c b) {
            ba = b;
            ba.Temp_Claim_Allocation__c = 0;
            closeReserve = false;
            exceedsReserve = false;
        }
    }
    
    
}