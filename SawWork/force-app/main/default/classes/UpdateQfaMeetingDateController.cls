/***
    UpdateQfaMeetingDateController
    @author : Karteek Mekala <kmekala@akamai.com>
    @Description : This class is used as a VisualForce controller for the VisualForce page "apex/UdpateQfaMeetingDate".
          - CR 681886  Allow ADE's to edit QFA Meeting date after the lead is converted
          - The button will update the inputted QFA meeting date on the Lead as well as on the Opportunity.
          
  @History
  --Developer         --Date      --Change
  Karteek Kumar M     --/06/10      Created the class
  Ali KM          18/10/2010    CR 828372 Changes to Lead Field
                      - Initializing Disposition to New when Leads are created.           
          
*/
public class UpdateQfaMeetingDateController 
{
    public Lead lead {get; set;}
    public Opportunity opp {get; set;}
    public Boolean initializedFlag {get; set;}
    /**
      UpdateQfaMeetingDateController()
      - Contstructor : initializes the lead and the opportunities
    */
    public UpdateQfaMeetingDateController() 
    {
         initializedFlag = true;
         try
         {
             lead = [select Id, Name, OwnerID, QFA_Meeting_Date__c, Status, Associated_Contact__c, Validation_Override__c from Lead where Id = :ApexPages.currentPage().getParameters().get('id')];
             system.assertNotEquals(lead, null);             
             opp = [select Id, Name, OwnerId, AccountId, StageName, QFA_Meeting_Date__c, Validation_Override__c from Opportunity where Associated_Lead__c = :lead.Id];             
             system.assertNotEquals(opp, null);
         }
         catch(Exception e)
         {
             ApexPages.Message errMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to find lead with specified Id.');
             ApexPages.addMessage(errMsg);                   
             initializedFlag = false;
         }
    }
    /**
      save()
      - Updates the inputted QFA meeting date on the Lead as well as on the Opportunity.
    */
    public PageReference save() 
    {
        if(lead.QFA_Meeting_Date__c >= Date.today())
            lead.Validation_Override__c = true;
        opp.QFA_Meeting_Date__c = lead.QFA_Meeting_Date__c;
        opp.Validation_Override__c = true;
        try
        {
            update lead;
            update opp;
        }
        catch(Exception e)
        {
             ApexPages.Message errMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'An error occured while trying to save the record.');
             ApexPages.addMessage(errMsg);  
             return null;                 
        }
        return new PageReference('/apex/leadView?id='+lead.Id);
    }
}