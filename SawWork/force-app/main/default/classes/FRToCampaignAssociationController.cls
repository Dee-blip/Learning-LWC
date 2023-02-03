public class FRToCampaignAssociationController {
    
    public SFDC_MDF__c pageObject {get; set;} 
    public String updateErrorMessage;
    public Id recordID;
    PageReference pageRef;

    public FRToCampaignAssociationController (ApexPages.standardController stdController) {
        recordID = ApexPages.currentPage().getParameters().get('id');
        List<SFDC_MDF__c> listOfRecords= [select id, Fund_Request_Campaign__c from SFDC_MDF__c where id=:recordID];
        if(listOfRecords.size()>0)
        {
          pageObject = listOfRecords[0];
        }
        else
        {
            ApexPages.Message noIDMessage = new ApexPages.Message(ApexPages.Severity.ERROR,'Error: Not a valid Fund Request ID.');
            ApexPages.addMessage(noIDMessage);
         }
           
       }
        
    public PageReference saveCampaignID()
    {
      try
      {
        update pageObject;
        recordID = ApexPages.currentPage().getParameters().get('id');
        system.debug('Record Id = '+recordID);
        pageRef = new PageReference('/'+recordID);
        pageRef.setRedirect(true);
        return pageRef;
      }
      catch (Exception e)
      {
        updateErrorMessage = e.getMessage();
        ApexPages.Message noIDMessage = new ApexPages.Message(ApexPages.Severity.ERROR,updateErrorMessage);
        return null;
      }
   }

   public PageReference redirectToRequest() {
      recordID = ApexPages.currentPage().getParameters().get('id');
      system.debug('Record Id = '+recordID);
      pageRef = new PageReference('/'+recordID);
      pageRef.setRedirect(true);
      return pageRef;  
   }
}