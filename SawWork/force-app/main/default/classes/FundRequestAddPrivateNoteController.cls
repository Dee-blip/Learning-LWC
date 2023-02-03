public class FundRequestAddPrivateNoteController {
    
    public SFDC_MDF__c pageObject {get; set;} 
    public String message {get;set;}
    public String updateErrorMessage {get;set;}
    public FundRequestAddPrivateNoteController (ApexPages.standardController stdController) {
        String recordID = ApexPages.currentPage().getParameters().get('id');
        if(String.isBlank(recordID))
        {
        	ApexPages.Message noIDMessage = new ApexPages.Message(ApexPages.Severity.ERROR,'Error: No Fund Request ID specified.');
            ApexPages.addMessage(noIDMessage);
        }
        List<SFDC_MDF__c> listOfRecords= [select id, Private_Note__c from SFDC_MDF__c where id=:recordID];
        if(listOfRecords.size()>0)
        {
      
        	pageObject = listOfRecords[0];
        }   
       }
        
    public PageReference savePrivateNote()
    {
    	try{
    		update pageObject;
    		message = 'success';
    		return null;
    	}
    	catch (Exception e){
    		message = 'error';
    		updateErrorMessage = e.getMessage();
    		return null;
    }
   }
}