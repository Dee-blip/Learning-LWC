/** Sonali Tandon 6.12.2016 SFDC-1316 - EMRI Enhancements to Disassociate contract 
**/



public class DissociateContractPageClass {

    public Id opportunityId { get; set; }
	public Boolean showMessage{ get; set; }
	//public String renewalContractTextId;
	public List<Renewal_Contract_Object__c> renewalContracts;

	public DissociateContractPageClass(){
         
        showMessage= false;
        opportunityId = ApexPages.currentPage().getParameters().get('opportunityId');
        renewalContracts = [Select Id from Renewal_Contract_Object__c where Opportunity__c = :opportunityId];
        
		// profile check 
		checkForAllowedProfiles();

		//check if opportunity is associated to a contract
		if(!showMessage)
			checkAssociatedContract();

		//check if opportunity is closed 
		if(!showMessage)
			checkOpportunityStage();

	}

	private void checkAssociatedContract(){

		if(!OpportunityUtilClass.hasAssociatedRenewalContract(opportunityId))
  	    {
  	     	showMessage = true;
  	     	Apexpages.addMessage( new ApexPages.Message (ApexPages.Severity.ERROR,GsmUtilClass.getErrorPageSettingValue('NoContractAssociatedError')));      

  	    }
	}

	private void checkOpportunityStage(){

		if(OpportunityUtilClass.isClosed(opportunityID))
		{
			showMessage = true;
			Apexpages.addMessage( new ApexPages.Message (ApexPages.Severity.ERROR, Label.Opportunity_is_in_Closed_Stage));

		}
	}

	private void checkForAllowedProfiles(){
		
        
		if(!GsmUtilClass.getGSMSettingValue('DissociateContractAllowedProfiles').contains(UserInfo.getProfileId())){
			showMessage = true;
			Apexpages.addMessage(new ApexPages.Message(Apexpages.Severity.ERROR,'You do not have sufficient privileges to perform this action.'));
		}
	}

    public PageReference disassociateContract(){
        
        if(!showMessage){
        GsmUtilClass.disableLossReasonValidation= false; //SFDC-8121

		opportunityId = ApexPages.currentPage().getParameters().get('opportunityId');
		List<OpportunityLineItem> listOfOpportunityLineItemsToDelete = new List<OpportunityLineItem>();

		for(OpportunityLineItem lineItem : [Select Average_Renewal_Commit_MRR__c, Average_Renewal_Usage_MRR__c 
											from OpportunityLineItem
											where OpportunityId =:opportunityId  AND (Average_Renewal_Commit_MRR__c!=null OR Average_Renewal_Usage_MRR__c!=null) 
                                            ]){
			listOfOpportunityLineItemsToDelete.add(lineItem);
		}

		DMLResults results = new DMLResults(true);

		Opportunity opportunityObject = new Opportunity(Id=opportunityId,Renew_Contract_Id_Text__c ='');
        results.clear();
        results.dmlUpdate(new List<Opportunity>{opportunityObject});
        results.withClassName('DisassociateContractPageClass').insertRecordsInErrorLog();
	    if(results.failureCount>0 )
	    {
	        showMessage = true;
	        Apexpages.addmessage(new Apexpages.Message(Apexpages.severity.ERROR,'An error occured while updating opportunity.'));
	    }

		if(listOfOpportunityLineItemsToDelete.size()>0 && !showMessage)
		{
	        results.clear();
	        results.dmldelete(listOfOpportunityLineItemsToDelete);
	        results.withClassName('DisassociateContractPageClass').insertRecordsInErrorLog();
	        if(results.failureCount>0)
	        {
	            showMessage = true;
	            Apexpages.addmessage(new Apexpages.Message(Apexpages.severity.ERROR,'An error occured while deleting the opportunity products.'));
	        }
		}

		if(renewalContracts.size()>0 && !showMessage)
		{
	        results.clear();
	        results.dmldelete(renewalContracts);
	        results.withClassName('DisassociateContractPageClass').insertRecordsInErrorLog();
	        if(results.failureCount>0)
	        {
	            showMessage = true;
	            Apexpages.addmessage(new Apexpages.Message(Apexpages.severity.ERROR,'An error occured while deleting the associated contracts.'));
	        }

		}
		
        if(!showMessage)
        {
           	showMessage = true;
            Apexpages.addMessage(new ApexPages.Message(Apexpages.Severity.CONFIRM,'Contract(s) are successfully disassociated from opportunity.'));
        }

   	}

		
        return null;
    }
    
       public PageReference backToOppty()    
        {
           return new PageReference('/'+opportunityId);       
        }


}