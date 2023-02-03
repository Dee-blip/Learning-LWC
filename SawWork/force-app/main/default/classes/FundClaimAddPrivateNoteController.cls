public class FundClaimAddPrivateNoteController {
    
    public SFDC_MDF_Claim__c pageObject {get; set;} 
    public String updateErrorMessage {get;set;}
    public String recordID;
    PageReference pageRef;

    public FundClaimAddPrivateNoteController (ApexPages.standardController stdController) {
        String recordID = ApexPages.currentPage().getParameters().get('id');
        if(String.isBlank(recordID))
        {
        	ApexPages.Message noIDMessage = new ApexPages.Message(ApexPages.Severity.ERROR,'Error: No Fund Claim ID specified.');
            ApexPages.addMessage(noIDMessage);
        }
        List<SFDC_MDF_Claim__c> listOfRecords= [select id, Private_Note__c from SFDC_MDF_Claim__c where id=:recordID];
        if(listOfRecords.size()>0)
        {
        	pageObject = listOfRecords[0];
        }
    }
        
    public PageReference savePrivateNote()
    {
    	try{
    		update pageObject;
    		recordID = ApexPages.currentPage().getParameters().get('id');
            system.debug('Record Id = '+recordID);
            pageRef = new PageReference('/'+(Id)recordID);
            pageRef.setRedirect(true);
            return pageRef;
    	}
    	catch (Exception e){
    		updateErrorMessage = e.getMessage();
            ApexPages.Message noIDMessage = new ApexPages.Message(ApexPages.Severity.ERROR,updateErrorMessage);
            return null;
        }
   }

   public PageReference redirectToFundClaim() {
      recordID = ApexPages.currentPage().getParameters().get('id');
      system.debug('Record Id = '+recordID);
      pageRef = new PageReference('/'+(Id)recordID);
      pageRef.setRedirect(true);
      return pageRef;  
   }
}