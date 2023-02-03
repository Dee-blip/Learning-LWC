public class HD_ApprovalEmailController {

    // ID of the record whose most recent approval process comments to retrieve
    public ID targetObjectId { get; set; }
    
    
    public String url {
        get {
            if (url == null ) {
            	String wId = getWorkItemId();
            	url = ( wId != null ) ? System.URL.getSalesforceBaseUrl().toExternalForm() + '/p/process/ProcessInstanceWorkitemWizardStageManager?id='+ wId : '';
            }
            return url;
        }
        private set;
    }
    
    public HD_ApprovalEmailController() {}
    
    
    private String getWorkItemId() {
        List<ProcessInstance> pIs = [SELECT Id, (SELECT Id, ActorId, ProcessInstanceId FROM Workitems)
		FROM ProcessInstance where targetObjectid = :targetObjectId order by createddate desc limit 1];
        if(pIs.size()>0 ){
            String workItemId = pIs[0].workitems[0].Id;
            return workItemId;
        }else {
            return null;
        }
        
    }
    
}