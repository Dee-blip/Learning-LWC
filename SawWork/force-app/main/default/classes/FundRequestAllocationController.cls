public with sharing class FundRequestAllocationController {
    public Date requestDate { get; set; }
    public String requestDateString { get; set; }
    public Double totalBudget { get; set; }
    public Double tempAllocation { get; set; }
    public Boolean success { get; set; }
    public Boolean loadError { get; set; }
    public SFDC_MDF__c request { get; set; }
    public SFDC_MDF__c totalallocation { get; set; } //used only to maintain the total being allocated, never saved
    public SFDC_MDF__c totalreserved { get; set; } //used only to maintain the total already reserved, never saved
    public list<SFDC_Budget__c> budgets;
    @TestVisible public list<BudgetWrapper> bwList;
    
    public FundRequestAllocationController(ApexPages.StandardController controller) {
        this.request = (SFDC_MDF__c)controller.getRecord();
        this.totalallocation = new SFDC_MDF__c();
        this.requestDate = request.CreatedDate.date();
        this.requestDateString = this.requestDate.format();
        this.budgets = (list<SFDC_Budget__c>)setCon.getRecords();
        this.loadError = this.budgets.isEmpty();
        this.bwList = new list<BudgetWrapper>();
        for(SFDC_Budget__c b : this.budgets){
            bwList.add(new BudgetWrapper(b));
        }
        this.totalBudget = 0;
        this.success = false;
        searchReserved();
        allocate();
    }
    
        
    @TestVisible private void searchReserved() {
        this.totalreserved = new SFDC_MDF__c(Amount__c = 0);
        for (Budget_Allocation__c r : [select Id, Amount__c from Budget_Allocation__c where Fund_Request__c = :this.request.Id and RecordType.Name = 'Reserved']) {
            this.totalreserved.Amount__c += r.Amount__c;
        }
    }
    
    public ApexPages.StandardSetController setCon {
        get {
            if (setCon == null) {           
                setCon = new ApexPages.StandardSetController(Database.getQueryLocator([select Id, Name, Account__r.Name, Active__c, Amount__c, Available_Budget__c, Claimed_Budget__c, End_Earned_Date__c, Fund_Budget_Name__c, Fund_Claim_Deadline__c, Fund_Request_Deadline__c, Reserved_Budget__c, Start_Earned_Date__c, Temp_Allocation__c, Unclaimed_Requests__c from SFDC_Budget__c where (Account__c = :this.request.Account__c or Account__c = null) and Available_Budget__c > 0 and Fund_Request_Deadline__c >= :this.requestDate order by End_Earned_Date__c]));
            }
            return setCon;
        }
        set;
    }
    
    public list<BudgetWrapper> getbwList() {
        return this.bwList;
    }
    
    public list<SFDC_Budget__c> getBudgets() {
        return this.budgets;
    }
    
    public PageReference validateAllocations() {
        PageReference p = null;
        updateTotal();
        if (this.totalreserved.Amount__c == this.request.Funding_Approved__c) {
            try {
                update this.request;
                return new PageReference('/' + this.request.Id);
            } catch (Exception e) {
                return null;
            }
        }
        
        if (this.request.Funding_Approved__c == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Funding_Amount_Empty));
            this.success = false;
        } else if (this.request.Funding_Approved__c > this.request.Amount_In_Corporate_Currency__c) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Approved_Amount_Cannot_be_more_than_requested));
            this.success = false;
        } else if (this.totalallocation.Amount__c == 0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Total_Allocations_Cannot_Be_Empty));
            this.success = false;
        } else if (this.totalallocation.Amount__c != this.request.Funding_Approved__c) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.Allocation_and_Approved_must_be_same));
            this.success = false;
        } else {
            p = saveAllocations();
        }
        return p;
    }
    
    @TestVisible private PageReference saveAllocations() {
        
        try {
            RequestAndClaimUtility.createRequestAllocations(this.request, this.bwList);
             return new PageReference('/' + this.request.Id);
        } catch(System.DmlException e){
            System.debug('DML ERROR: ' + e);
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getDmlMessage(0));
        } catch(MDFException ex){
            System.debug('ERROR: ' + ex);
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage());
            
        }
        return null;
        
        
    }
    
    public PageReference cancelAllocations() {
        return new PageReference('/' + this.request.Id);
    }
    
    @TestVisible private void allocate() {
        Decimal availableRequest = ((this.request.Amount_In_Corporate_Currency__c - this.totalreserved.Amount__c) < 0) ? 0 : this.request.Amount_In_Corporate_Currency__c - this.totalreserved.Amount__c;
       
        
        for (BudgetWrapper bw : this.bwList) {
   
            if (bw.b.Account__c != null) {     
                this.totalBudget += bw.b.Available_Budget__c;
                if (bw.b.Available_Budget__c > 0) {
                    bw.tempAllocation = Decimal.valueOf('0.00');
                    bw.tempAllocation = (availableRequest > bw.b.Available_Budget__c) ? bw.b.Available_Budget__c : availableRequest;
                    availableRequest -= bw.tempAllocation; 
                } else {
                    bw.tempAllocation = 0;
                }
                bw.tempAllocation.setScale(2);
            }
        }
        if (availableRequest > 0) {
            for (BudgetWrapper bw : this.bwList) {
                if (bw.b.Account__c == null) {     
                    this.totalBudget += bw.b.Available_Budget__c;
                    if (bw.b.Available_Budget__c > 0) {
                        bw.tempAllocation = Decimal.valueOf('0.00');
                        bw.tempAllocation = (availableRequest > bw.b.Available_Budget__c) ? bw.b.Available_Budget__c : availableRequest;
                        availableRequest -= bw.tempAllocation; 
                    } else {
                        bw.tempAllocation = 0;
                    }
                    bw.tempAllocation.setScale(2);
                }
            }           
        }
        
        updateTotal();
    }
    
    public void updateTotal() {
        this.totalallocation.Amount__c = 0;
        for (BudgetWrapper bw : this.bwList) {
            if ( bw.tempAllocation != null) {
                this.totalallocation.Amount__c += bw.tempAllocation;
            } else {
                bw.tempAllocation = Decimal.valueOf('0.00');
            }
        }
        this.request.Funding_Approved__c = this.totalallocation.Amount__c;
        if(this.loadError){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, Label.No_Allocations_Msg));
        }
    }
    
    @TestVisible public class BudgetWrapper {
        public SFDC_Budget__c b { get; private set; }
        public Decimal tempAllocation { get; set; }
        
        public BudgetWrapper(SFDC_Budget__c b){
            this.b = b;
        }
        
        public String sAllocation {
            get {
                return (tempAllocation == null) ? '0.00' : tempAllocation.toPlainString();
            }
            set {
                if (value == null || value.length() == 0) {
                    tempAllocation = Decimal.valueOf('0.00');
                } else {
                    tempAllocation = Decimal.valueOf(value);
                }
            }
        }
    }
    
}