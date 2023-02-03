public class TSSupportTeamExtension {
    
    ApexPages.StandardController sController;
    public TS_Support_Team__c sTeam {get; set;}
    public Boolean success {get;set;}
    
    public TSSupportTeamExtension(ApexPages.StandardController controller) {
        sController = controller;
        this.sTeam = (TS_Support_Team__c) sController.getRecord();
        success = null;
    }
    
    public PageReference save()
    {
        try
        {
            System.debug('T&S -> Debug Called');
            sController.save();
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'A new support team has been successfully created'));
            success = true;
            System.debug('T&S -> Save successful');
            return null;
            
        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
        }
    }
  
}