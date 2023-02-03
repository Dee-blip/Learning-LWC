public without sharing class EnterSandboxCredentialsController {
    private ApexPages.StandardController controller;
    
    public EnterSandboxCredentialsController(ApexPages.StandardController stdController){
        this.controller = stdController;
    }
    
    public PageReference saveDetails() {
        Sandbox_Details__c detailFromPage = (Sandbox_Details__c)controller.getRecord();
        detailFromPage.Id = null;
        
        try {
            Schema.SObjectField externalIdField = Sandbox_Details__c.Fields.sandbox_name__c;
            Database.upsert(detailFromPage, externalIdField);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.CONFIRM, 'Details saved successfully.'));        
        } catch(exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, e.getMessage()));
        }
        
        return controller.view();
    }
}