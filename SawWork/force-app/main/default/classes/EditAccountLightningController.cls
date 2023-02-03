/**
   History
      
      --Developer       --Date         --Description        --Story
      Ruchika sharma    30/06/2017     Created this Class   SFDC-1592
        
*/
public without sharing class EditAccountLightningController {

    private final sObject mysObject;
    public String linkUrl {get; set;}
    // The extension constructor initializes the private member
    // variable mysObject by using the getRecord method from the standard
    // controller.
    public EditAccountLightningController(ApexPages.StandardController stdController) {
        this.mysObject = (sObject)stdController.getRecord();
        String baseURL = ApexPages.currentPage().getHeaders().get('Host');
        system.debug(LoggingLevel.Error,'URL:: '+System.URL.getSalesforceBaseUrl().toExternalForm()+' baseURL: '+baseURL);
        linkUrl = System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + this.mysObject.id;
    }

     @AuraEnabled
    public static void updateAccountRecord(String accId, String ddSpecialInstructions){
        
        try{
            System.debug(LoggingLevel.Error,'Calling accId controller :'+accId + '----- ddSpecialInstructions :'+ddSpecialInstructions);
            Account account = [Select id, Deal_Desk_Special_Instructions__c  
                                           from Account 
                                           where id=:accId];
            System.debug(LoggingLevel.Error,'account :'+account);
            if(account != null){
                account.Deal_Desk_Special_Instructions__c = ddSpecialInstructions;
                account.Validation_Override__c = true;
                update account;
            }
            
        } catch (Exception ex){
            //Create a record for error log
            System.debug(LoggingLevel.ERROR,'ex.getmessage(): '+ex.getmessage());
            Error_log__c errorLog = new Error_log__c(Class__c = 'EditAccountLightningController',Error_Message__c = ex.getMessage(),RecordId__c = accId);
            insert errorLog;
            throw new AuraHandledException(ex.getmessage());
        } 
        
    } 
}