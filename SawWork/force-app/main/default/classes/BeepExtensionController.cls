public class BeepExtensionController
{
    public ApexPages.StandardSetController standardController;


    public BeepExtensionController(ApexPages.StandardSetController stdController)
    {
        this.standardController = stdController;
    }

    public PageReference runSummarization()
    {
        try
        {
            List<Beep__c> selectedBeeps = 
                (List<Beep__c>)standardController.getSelected();
            Set<Id> bpIds = new Set<Id>();
            for(Beep__c bp : selectedBeeps)
            {
                bpIds.add(bp.Id);
            }

            Sawyer.summarizeBeeps(bpIds);
            return new PageReference('/' + Schema.Sobjecttype.Beep__c.getKeyPrefix());
        }
        catch(Exception exx)
        {
            ApexPages.addMessage(
            new ApexPages.Message(
            ApexPages.Severity.ERROR, 
            'Something went wrong:'+exx.getMessage()
        +' with Trace: '+exx.getStackTraceString()));    
            return null;
        }

    }

 }