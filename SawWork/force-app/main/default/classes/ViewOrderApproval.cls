public class ViewOrderApproval {
    
    public String recordId {get;set;}
    PageReference pageRef;

    public PageReference init()
    {

        recordId = ApexPages.currentPage().getParameters().get('recordId');
        System.debug('recordId: '+recordId);
        List<order_approval__c> oa = new List<order_approval__c>();
        if(!String.isBlank(recordId)){
            oa = [Select id from order_approval__c where Associated_Opportunity__c =:recordId limit 1];
            if(oa.size() > 0){
                pageRef = new PageReference('/'+oa[0].Id);
                pageRef.setRedirect(true);
                return pageRef;
            }  
        }
        ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.ERROR,'An unexpected error has occurred. Please contact your System Administrator');
        ApexPages.addMessage(msg);
        return null;
    }
}