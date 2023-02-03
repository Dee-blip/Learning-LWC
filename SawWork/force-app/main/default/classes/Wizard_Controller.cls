/* ========================================================================
    Author: Sonia Sawhney
    Description: Class used for fetching the wizard related Custom Settings
    Created Date : 23/06/2014
    ======================================================================== */
public class Wizard_Controller
{
    //Start of Changes for CR 2679240 - Wizards: Idea Counter  
    public integer TotalIdeas {get; set;}
    
    public Wizard_Controller()
    {
        RefreshIdeaCount();
    }
    
    //Method used to refresh the Idea Count
    public PageReference RefreshIdeaCount()
    {
        //get the total number of Ideas submitted
        this.TotalIdeas = [SELECT COUNT() FROM Idea WHERE Community.Name = 'Wizards' and Categories != 'Discarded'];
        return null;
    }    
    //End of Changes for CR 2679240 - Wizards: Idea Counter 
    
    //Start of Changes for CR 2676612 - Wizards: Implement Dynamic Banner 
    //Get the idea URL's 
    public List<Wizards_Idea_URL__c> getURLs() 
    {
        List<Wizards_Idea_URL__c> fields = [select Link__c, Order__c from Wizards_Idea_URL__c order by Order__c limit 50000];
        return fields;
    }
    
    //Get the Image links for the banner
    public List<Wizards_Slider_Image__c> getImages() 
    {
        List<Wizards_Slider_Image__c> fields = [select Link__c, Order__c from Wizards_Slider_Image__c order by Order__c limit 50000];
        return fields;
    }
    //End of changes for CR 2676612 - Wizards: Implement Dynamic Banner 
}