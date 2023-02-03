public class TSProductSkillExtension {

    ApexPages.StandardController sController;
    public TS_Product_Skill__c pSkill {get; set;}
    public Boolean success {get;set;}
    
    public TSProductSkillExtension(ApexPages.StandardController controller) {
        sController = controller;
        this.pSkill = (TS_Product_Skill__c) sController.getRecord();
        success = null;
    }
    
    public PageReference skillsList()
    {
        PageReference ref = new PageReference('/apex/ACDEmployees');
        return ref;
    }

    public PageReference save()
    {
        try
        {
            PageReference ref = sController.save();
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'A new ACD skill has been successfully created'));
            success = true;
            return null;
        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
        }        
    }

}