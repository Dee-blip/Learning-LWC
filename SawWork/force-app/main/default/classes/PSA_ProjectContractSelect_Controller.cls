/*********************************************************************************
    PSA_ProjectContractSelect_Controller
    @author Liz Ichihashi
    @Description : This Class is invoked from the Contract and Contract Line 
                   related lists on the Project view page.  The page is 
                   designed to make it easier for users to find and add 
                   contracts and contract line items to associate to the project.
                   
                   This class supports PSA customization requirment 4.1.2 and 4.1.3 - Add/Remove Project Contract Line Item
	@History
	--Developer		      --Date			--Change
	Liz Ichihashi    	  01/04/2013		Created the class.	   
*********************************************************************************/
public with sharing class PSA_ProjectContractSelect_Controller extends PSA_ProjectContractBase_Controller {
  
	public PSA_ProjectContractSelect_Controller() {
		isComingFromProjTemplatePage = false;
	}
	
    public boolean isClassic
    {
        get
        {
            return (UserInfo.getUiThemeDisplayed() == 'Theme3');

        }
        set;
    }    
	
	public PSA_ProjectContractSelect_Controller(ApexPages.StandardController stdCon) {
		isComingFromProjTemplatePage = false;
        Project_Contract_Line_Item__c projContLineItem = (Project_Contract_Line_Item__c) stdCon.getRecord();
        if (projContLineItem !=  null && projContLineItem.Id != null) {
	        projContLineItem = [Select Id, Project__c from Project_Contract_Line_Item__c where id = :projContLineItem.Id];
	        projId = projContLineItem.Project__c;
        }    
    }

   public PageReference returnToProject()
   {
        return new PageReference('/'+proj.Id); 
   }
}