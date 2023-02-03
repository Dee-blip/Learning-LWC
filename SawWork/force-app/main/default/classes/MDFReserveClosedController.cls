public class MDFReserveClosedController {

    public MDFReserveClosedController(ApexPages.StandardController controller) {
        this.request = (SFDC_MDF__c)controller.getRecord();
        HasError=false;
        SFDC_MDF__c FundReq=[select Reserve_Closed__c,Status__c from SFDC_MDF__c where id=:this.request.id];
        
        if (FundReq.Status__c == 'Submitted') {
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.FATAL, 'The fund request cannot be Reserve Closed if the status is Submitted. ');
            ApexPages.addMessage(msg);
            HasError=true;
        }
        else if(FundReq.Reserve_Closed__c==true)
        {
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.FATAL, 'The fund request is already Reserve Closed.');
            ApexPages.addMessage(msg);
            HasError=true;
        }
    }
     public SFDC_MDF__c request { get; private set; }
    
    public boolean HasError  { get; private set; }
    
    public PageReference back() {
        return new PageReference('/'+this.request.Id);
    }
    
     public PageReference ReserveClosedRequest() {
         PageReference pRef;
         this.request.Reserve_Closed__c=true;
         this.request.Status__c = 'Reserved Closed';
         try
         {
            update this.request;
         }
         catch(Exception e)
         {
            pRef = SiteLoginController.exceptionNotification(ApexPages.currentPage(),e);
         }
         
         list<SFDC_MDF_Claim__c> FundClaims = new list<SFDC_MDF_Claim__c>();
         for(SFDC_MDF_Claim__c fc:[select id from SFDC_MDF_Claim__c where Fund_Request__c=:this.request.id])
         FundClaims.add(fc);
         list<Budget_Allocation__c> BudAlloc = new list<Budget_Allocation__c>();
         for(Budget_Allocation__c ba:[select id,Reserve_Closed__c from Budget_Allocation__c where Fund_Request__c=:this.request.id OR Fund_Claim__c IN :FundClaims])
         BudAlloc.add(ba);
         if(BudAlloc.size()>0)
         {
             For(Budget_Allocation__c ba:BudAlloc)
                 ba.Reserve_Closed__c=true;
             
             try
             {
                update BudAlloc;
             }
             catch(Exception e)
             {
                pRef = SiteLoginController.exceptionNotification(ApexPages.currentPage(),e);
             }
         }
         return new PageReference('/'+this.request.Id);
     }
}