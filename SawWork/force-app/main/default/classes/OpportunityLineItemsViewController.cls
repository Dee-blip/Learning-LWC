/*
 * History:
 * ==================================================================================================
 * Developer        Date        Description
 * --------------------------------------------------------------------------------------------------
 * Ali KM			16/02/2012	CR 1477954 Forecasting: Need to update QA env for forecasting
 								-> Created this Class.
 								-> This class is used by OpportunityLineItemsView page, this page overrides the OOTB Oppty-Prod View & Edit functionality.
 								-> Overriding the OOTB View/Edit screens in-order to control fields on the page layouts.
 								
 * Lisha Murthy		30/09/2012	CR 1901395 - Fix redirect on Oppty Prod issue
 								-> Commented out adding existing parameters to the return URL to Opportunity on Cancel() 
 * Lisha Murthy		20/05/2014	CR 2602830 - Oppty: For Closed Won Oppty, when product is deleted, irrelevant error message obtained
								-> Add a constraint for deletion of products on Closed Opportunities
*/
global class OpportunityLineItemsViewController 
{
    public OpportunityLineItem oli;
    public boolean isFeatureDisabled {get; set;}
    public String featureDisabledMessage {get; set;}
    
    public OpportunityLineItemsViewController(ApexPages.StandardController stdController) 
    {
        this.oli = (OpportunityLineItem)stdController.getRecord();
        //SFDC-2686
        this.isFeatureDisabled=GsmUtilClass.isFeatureToggleEnabledCustomMetadata('isOOTBForecastingEnabled');
        this.featureDisabledMessage=GsmUtilClass.featureToggleMsg('isOOTBForecastingEnabled');
    }           
    public PageReference cancel() 
    {
    	PageReference opptyDetailPage = new PageReference('/'+oli.OpportunityId); //oli.OpportunityId
        
		/*for(string key:ApexPages.currentPage().getParameters().keySet())
		{
			opptyDetailPage.getParameters().put(key, ApexPages.currentPage().getParameters().get(key));
		}
        opptyDetailPage.getParameters().put('nooverride', '1');*/
        opptyDetailPage.setRedirect(true);
        return opptyDetailPage; 
    }
    public PageReference remove()
    {
        boolean isDeleted = true;
        PageReference opptyDetailPage = new PageReference('/'+oli.OpportunityId); //oli.OpportunityId
        opptyDetailPage.setRedirect(true);
        //SFDC-2686
        String deletionErrorMessage = GsmUtilClass.getGSMSettingValue('OpptyLineItemTrigCls_delErrMsg');
                
        try 
        {
            delete oli;
        }
        catch (Exception ex1)
        {
			if(ex1.getMessage().contains('CustomException: You cannot delete a product on Closed Opportunities.'))	
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You cannot delete a product on Closed Opportunities.'));
			 if(ex1.getMessage().contains('You cannot delete this product as the "Invoiced Monthly Commitment/Usage" is filled.'))
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You cannot delete this product as the "Invoiced Monthly Commitment/Usage" is filled.'));
	        else    			
				ApexPages.addMessages(ex1);

			isDeleted = false;
        }
        
        if (isDeleted)
            return opptyDetailPage;
        else
            return null;
    }
}