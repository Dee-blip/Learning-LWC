public class updatePBMonthModifiedDateController {
    public Id recordId;
    PageReference pageRef;
    
    public PageReference init() {
    	recordId = ApexPages.currentPage().getParameters().get('recordId');
        try {
        	Traffic_Share__c tsRec = [Select Id,P_B_Month_Modified_Date__c from Traffic_Share__c where Id = :recordId];
            tsRec.P_B_Month_Modified_Date__c = date.today();
            database.update(tsRec);
            pageRef = new PageReference('/'+recordId);
            pageRef.setRedirect(true);
            return pageRef;
        } catch (exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,ex.getMessage()));
            return null;
        }
    }

}