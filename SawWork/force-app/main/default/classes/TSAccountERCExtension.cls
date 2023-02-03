public class TSAccountERCExtension {

    ApexPages.StandardController sController;
    public Account accObj {get; set;}
    public Boolean success {get;set;}
    public String ercEntered {get;set;}
    public String ercNumeric {get; set;}

    public TSAccountERCExtension(ApexPages.StandardController controller) {
        sController = controller;
        this.accObj = (Account) sController.getRecord();
        if(accObj.id != null)
        {
            accObj = [Select Id, Name, AKERC__c, ERC_Numeric__c from Account where Id=:accObj.Id];
        }
        success = false;
        if(accObj.AKERC__c != null && accObj.AKERC__c != '')
        {
            ercEntered = accObj.AKERC__c;
            fetchErcNumeric();
        }
    }

    public void fetchErcNumeric()
    {
        String currentErc = System.currentPageReference().getParameters().get('currErc');
        currentErc = (currentErc != null && currentErc != '') ? currentErc : accObj.AKERC__c;
        if(currentErc != null && currentErc != '')  {
            ercNumeric = SupportTeamMgmt_Utility.getERCNumeric(currentErc);
        }
    }


    public PageReference save()
    {
        try
        {
            accObj.AKERC__c = ercEntered;
            update accObj;
            success = true;
        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        return null;
    }

}