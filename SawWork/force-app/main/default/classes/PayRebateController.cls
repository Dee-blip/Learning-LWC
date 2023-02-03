public class PayRebateController {
    public String rebateCreateDateString{get;set;}
    public Rebate_Payout__C rebatePayout{get;set;}
    public Boolean showRebate{get;set;}
    
    public PayRebateController(ApexPages.StandardController controller) 
    {
      String id=ApexPages.currentPage().getParameters().get('id');
      rebatePayout=[Select Id,Name,Associated_Partner__c,Status__c,Paid_Processed_Date__c,Credit_Invoice_Date__c,Contract_Reviewed_Date__c,Contract_Id__c,CreatedDate,Validation_Override__c from Rebate_Payout__c where id=:id];
      showRebate=true;
      if(rebatePayout!=null  && rebatePayout.Status__c!='Paid')
      {
      DateTime payoutDate=rebatePayout.CreatedDate;
      rebateCreateDateString=payoutDate.date().format();
      rebatePayout.Paid_Processed_Date__c=Date.today().addDays(1);
      rebatePayout.Credit_Invoice_Date__c=DateTime.newInstance(Date.today().addMonths(1).year(),Date.today().addMonths(1).month(),01).date();
      }
      else
      {
       showRebate=false;
      }
    }
    
    public PageReference saveRebate()
    {
     try
     {
      rebatePayout.Validation_Override__c=true;
      //throw new CustomException('This is test message');
      update rebatePayout;
      showRebate=false;
     }
     catch(Exception e)
     {
      Apexpages.addMessage(new ApexPages.Message(Apexpages.SEVERITY.ERROR,e.getMessage()));
     }
     return null;
    }
    public Pagereference goBackToRebate()
    {
     return new PageReference('/'+rebatePayout.Id);
    }

}