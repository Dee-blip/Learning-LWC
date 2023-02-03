public class SF1_Controller_OpportunityGetBaseLine 
{
	public SF1_Controller_OpportunityGetBaseLine() {
		
	}

	@AuraEnabled
public static String checkOpportunity(String oppId)
{
	if(OpportunityUtilClass.isClosed(oppId))
        {
            return Label.Opportunity_is_in_Closed_Stage;

        }
         if(OpportunityUtilClass.hasAssociatedRenewalContract(oppId))
         {
            
           return GsmUtilClass.getErrorPageSettingValue('ContractAlreadyAssociated');      

         }
         return '';

}


 @AuraEnabled
	public static List<Merge_Contract_Header__c> getContractsFromAcount(Id accountId)
	{
	        List<Merge_Contract_Header__c> contractRecords = new List<Merge_Contract_Header__c>();
	        
        for(Merge_Contract_Header__c mc : [select Id,name,Contract_Type__c,Parent_Contract__c,Order_Id__c,Parent_Account_Name__c,Currency__c,Solution_Set__c,Effective_Start_Date__c,CurrencyIsoCode,Account_Name__c,Account_Name__r.Id,Account_Name__r.Name ,Active__c ,Effective_End_Date__c , Original_Contract_Id__c,Opportunity_Name__r.currencyIsoCode,Opportunity_Name__r.Deal_Type__c,Opportunity_Name__r.Partner_Involved__c,
  Contract_Product_Count__c,(Select Id,CurrencyIsoCode,Average_Renewal_Commit_MRR__c,Average_Renewal_Usage_MRR__c,Forecast_Product_Id__c from Contract_Products__r) from Merge_Contract_Header__c where Account_Name__c = :accountId and Active__c = true 
  AND Effective_End_Date__c >= LAST_N_MONTHS:2 
  AND Contract_Product_Count__c > 0 ORDER BY Effective_End_Date__c ASC])
        {
            contractRecords.add(mc);
            
            
        }
        
        return contractRecords;
    }

    @AuraEnabled
    public static String productIdToName(List<String> productIdList)
    {
    	Map<String,String> pIdtoName = new Map<String,String>();

      for(PricebookEntry pbe : [Select Name,product2.Akam_Product_Id__c from PricebookEntry where product2.Akam_Product_Id__c IN : productIdList])
      {


      		
      		 
      				pIdtoName.put(pbe.product2.Akam_Product_Id__c,pbe.Name);
      				
      		

      		}
      		return JSON.serialize(pIdtoName);
      	}
        
  
    

    @AuraEnabled
    public static String getContractBaseline(List<Merge_Contract_Header__c> mchList, String currencyCode, String oppId, Date opptyCloseDate)
    {

      GsmUtilClass.disableLossReasonValidation= false; //SFDC-8121
    	String returnMessage = '';
    	Boolean showError = false;
        try{

        List<OpportunityLineItem> opptyLineItemList = new List<OpportunityLineItem>();
        List<String> listOfOriginalContractIds = new List<String>();
        Set<String> contractCurrencySet = new Set<String>();
        for(Merge_Contract_Header__c mch : mchList)
        {
        	listOfOriginalContractIds.add(mch.Original_Contract_Id__c);
        	contractCurrencySet.add(mch.Currency__c);
        }

        CreateRenewalOpptyWithMultipleContracts roc = new CreateRenewalOpptyWithMultipleContracts(listOfOriginalContractIds);
        roc.setOpportunityCurrency(currencyCode);
        roc.setContractCurrency(contractCurrencySet);
        roc.setOpportunityCloseDate(opptyCloseDate);
        String contractName = roc.buildContractName();
        
        Opportunity opptyRecord = new Opportunity(Id = oppId, Opportunity_Type__c = 'Renewal', Validation_Override__c = true, Renew_Contract_Id_Text__c=contractName);
        
        DMLResults results = new DMLResults(true);
        results.clear();
        results.dmlUpdate(new List<Opportunity>{opptyRecord});
        results.withClassName('SF1_Controller_OpportunityGetBaseLine').insertRecordsInErrorLog();
        if(results.failureCount>0)
        {
            showError = true;
           returnMessage = 'An error occured while updating the opportunity.';
        }

        opptyLineItemList = roc.createOpportunityProducts(Id.valueOf(oppId));     
        if(opptyLineItemList.size()>0 && !showError)
        {
            results.clear();
            results.dmlInsert(opptyLineItemList);
            results.withClassName('SF1_Controller_OpportunityGetBaseLine').insertRecordsInErrorLog();
            if(results.failureCount>0)
            {
                showError = true;
               returnMessage = 'An error occured while inserting the opportunity products.';
            }
        }

        if(!showError)
        {
            roc.createRenewalContractObjects(Id.valueOf(oppId));
            if(roc.errorOccured)
            {
                showError = true;
                returnMessage = 'An error occured while inserting the associated contracts.';
            }
        }

    

        if(!showError)
        {
            showError = true;
           returnMessage = 'Opportunity get baseline successfully completed.';
        }
    }
    catch(Exception ex)
    {
    	returnMessage = ex.getMessage()+' '+ex.getStackTraceString();
    }

        return returnMessage;
    }
}