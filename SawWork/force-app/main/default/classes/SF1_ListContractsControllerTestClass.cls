@isTest(seeAllData=false)
public class SF1_ListContractsControllerTestClass {
    
    private static Merge_Contract_Header__c CreateContractHeader(String pOrignalContractId, Id pAccountId,String currencyString)
    {
        Merge_Contract_Header__c newHeader = new Merge_Contract_Header__c();
        newHeader.Original_Contract_Id__c = pOrignalContractId;
        newHeader.Name = pOrignalContractId;
        Integer numDays = 30 ; //Integer.valueOf(GSM_Custom_Settings__c.getInstance('Contract_HierarchyEndDateDays').Value__c)+2;
        newHeader.Effective_End_Date__c = Date.today(); //.addDays(-Integer.valueOf(numDays));
        newHeader.Account_Name__c = pAccountId; 
        newHeader.Active__c= true;
        newHeader.Currency__c = currencyString;
        return newHeader;
    }	
    
    static testmethod void getActiveContractsByAccIdPaginationPositiveTest(){
       	Account account = utilTestClass.CreateAccount('Test_Account');
        account.BillingStreet = '#39,7th Cross';
        account.BillingCity      = 'LA';
        account.BillingState = 'CA';
        account.BillingPostalCode = '50052';
        account.BillingCountry = 'USA';
        account.Type='Lead';
        insert account;
 
        Merge_Contract_Header__c renewalContract1 = CreateContractHeader('C-YJSEX45', account.Id,'USD'  );
        insert renewalContract1;
        
        Contract_Product__c contractProduct1 = utilTestClass.CreateContractProduct(renewalContract1.Original_Contract_Id__c,'PROD-123','AKAM-123');
        contractProduct1.Average_Renewal_Commit_MRR__c = 200;
        contractProduct1.Average_Renewal_Usage_MRR__c = 200;
        contractProduct1.UnitPrice__c = 1;
        contractProduct1.Original_Contract_id__c = renewalContract1.Id;
        contractProduct1.Forecast_Product_Id__c = 'Prod-12';
        insert contractProduct1;
        
        
        Merge_Contract_Header__c renewalContract2 = CreateContractHeader('C-YJSEX46', account.Id ,'SGD' );
        insert renewalContract2;
        
        
        Contract_Product__c contractProduct2 = utilTestClass.CreateContractProduct(renewalContract2.Original_Contract_Id__c ,'PROD-124','AKAM-124');
        contractProduct2.Average_Renewal_Commit_MRR__c = 400;
        contractProduct2.Average_Renewal_Usage_MRR__c = 400;
        contractProduct2.UnitPrice__c = 1;
        contractProduct2.Original_Contract_id__c = renewalContract2.Id;
        contractProduct2.Forecast_Product_Id__c = 'Prod-21';
        insert contractProduct2;
        
        System.debug('renewalContract1=' + JSON.serialize(renewalContract1));
        System.debug('contractProd1=' + JSON.serialize(contractProduct1));
        System.debug('renewalContract2=' + JSON.serialize(renewalContract2));
        System.debug('contractProd2=' + JSON.serialize(contractProduct2));   
        
		SF1_ListContractsController.ResultSetCustom activeContractsResults;// = new SF1_ListContractsController.ResultSetCustom();
        activeContractsResults = SF1_ListContractsController.getActiveContractsByAccIdPagination(account, 10, 0, null, null);
		//System.assertEquals(Json.serialize(activeContractsResults), '');
        //System.assertNotEquals(activeContractsResults.size, 0);
        //System.assertNotEquals(null, activeContractsResults.rows); 
    }
}