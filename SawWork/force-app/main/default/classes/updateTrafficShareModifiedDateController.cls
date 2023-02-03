public class updateTrafficShareModifiedDateController {
    public Id recordId;
    PageReference pageRef;
    
    public PageReference init() {
    	recordId = ApexPages.currentPage().getParameters().get('recordId');
        try {
        	Delivery_Vendor__c dvRec = [Select Id,Vendor_Traffic_Share_Modified_Date__c from
                                        Delivery_Vendor__c where Id = :recordId];
            dvRec.Vendor_Traffic_Share_Modified_Date__c  = date.today();
            database.update(dvRec);
            pageRef = new PageReference('/'+recordId);
            pageRef.setRedirect(true);
            return pageRef;
        } catch (exception ex) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,ex.getMessage()));
            return null;
        }
    }

}