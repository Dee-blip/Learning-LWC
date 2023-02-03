public class TSAgentIdExtension {

    ApexPages.StandardController sController;
    public User userObj {get; set;}
    public String agentId {get; set;}
    public Boolean success {get; set;}
    
    public TSAgentIdExtension(ApexPages.StandardController controller) {
        sController = controller;
        this.userObj = (User) sController.getRecord();
        success = null;
        //accObj = [SELECT Id, Name, ERC__c FROM Account WHERE Id = :ApexPages.currentPage().getParameters().get('id')];        
    }
    
    public void save()
    {
        //PageReference ref = new PageReference('/apex/ACDEmployees');
        //accObj.ERC__c = ERC;
        try
        {
            update userObj;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'ACD agent ID was saved successfully'));
            success = true;
        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There was a problem saving the Agent ID, please remember that duplicate Agent IDs are not allowed.'));
        }        
        //return null;        
    }
}