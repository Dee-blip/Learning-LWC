/* 
Owner : Chandra Lohani
		Hitesh CHawda  SFDC1108 - Class called from Get Baseline and Refresh Baseline Buttons
		*/
public with sharing class CustomButtonController {
	
	public String processName{get;set;}
	public String returnUrl{get;set;}
	public Pagereference returnPage {get;set;}
	public String contractID{get;set;}
	public String opportunityID{get; set;}
	public Boolean showError {get;set;}
    public static Boolean isRunning= true;
	//execute method called from button with Process name as parameter
	public PageReference execute()
	{
		if(processName!=null)
		{
			if(processName.equals('refreshBaseLine'))
				refreshBaseline();
		}

				
		returnPage=new PageReference(returnUrl);
		returnPage.setRedirect(true);
		
		return returnPage;
	}
	//Method called from Refresh Baseline to check for closed opportunity & associated contracts 
	public void executeRefreshBaseline()
	{
		if(OpportunityUtilClass.isClosed(opportunityID))
		{
			showError = true;
			Apexpages.addMessage( new ApexPages.Message (ApexPages.Severity.ERROR, Label.Opportunity_is_in_Closed_Stage));

		}

  	     if(!OpportunityUtilClass.hasAssociatedRenewalContract(opportunityID))
  	     {
  	     	showError = true;
  	     	Apexpages.addMessage( new ApexPages.Message (ApexPages.Severity.ERROR,GsmUtilClass.getErrorPageSettingValue('NoContractAssociatedError')));      

  	     }
        
	}

	public CustomButtonController()
	{
		
		returnUrl= ApexPages.currentPage().getParameters().get('returnUrl');
		processName=ApexPages.currentPage().getParameters().get('processName');
		contractID = ApexPages.currentPage().getParameters().get('contractID');
		opportunityID = ApexPages.currentPage().getParameters().get('opportunityID');
		returnPage=null;
	}

	public Pagereference refreshBaseline()
	{
		  GsmUtilClass.disableLossReasonValidation = False; //SFDC-8121

		// SFDC-1425
		system.debug('Inside refresh method ' +contractID +' Op ' +opportunityID );
		String opptyCurrency = ApexPages.currentPage().getParameters().get('opptyCurrency');
		Date opptyCloseDate = Date.parse(Apexpages.currentPage().getParameters().get('opptyCloseDate'));
		List<String> orignalContractIds = new List<String>();
		Set<String> contractCurrencySet = new Set<String>();
		for(Renewal_Contract_Object__c contractObj: [Select Name,Contract__r.Currency__c from Renewal_Contract_Object__c where Opportunity__c =:opportunityID])
		{
			orignalContractIds.add(contractObj.Name);
			contractCurrencySet.add(contractObj.Contract__r.Currency__c);
		}

		CreateRenewalOpptyWithMultipleContracts roc = new CreateRenewalOpptyWithMultipleContracts(orignalContractIds);
		roc.setOpportunityCurrency(opptyCurrency);
		roc.setContractCurrency(contractCurrencySet);
		roc.setOpportunityCloseDate(opptyCloseDate);
		roc.refreshOpportunityProducts(opportunityID);
		if(roc.errorOccured)
			Apexpages.addmessage(new Apexpages.Message(Apexpages.severity.ERROR,'An error occured while refreshing baseline.'));
		else
			Apexpages.addmessage(new Apexpages.Message(Apexpages.severity.CONFIRM,'Baseline sucessfully refreshed.'));
		showError = true;

		return null;

	}

	public Pagereference executeBackToOpportunity()
	{
		String backToOppty = '/'+opportunityID;
		Pagereference returnToOpptyPage =new PageReference(backToOppty);
		return returnToOpptyPage;

	}
    
}