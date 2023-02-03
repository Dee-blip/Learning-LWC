/**
 * @description       : 
 * @author            : apyati
 * @team              : GSM
 * @last modified on  : 09-08-2021
 * @last modified by  : apyati
 * Modifications Log
 * Ver   Date         Author   Modification
 * 1.0   09-08-2021   apyati   Initial Version
**/
@isTest(seeAllData=false)
public class l2qManageProductControllerTest {
	

    private static Merge_Contract_Header__c CreateContractHeader(String pOrignalContractId, Id pAccountId, String currencyString)
    {
        Merge_Contract_Header__c newHeader = new Merge_Contract_Header__c();
        newHeader.Original_Contract_Id__c = pOrignalContractId;
        newHeader.Name = pOrignalContractId;
        Integer numDays = 30 ;
        newHeader.Effective_Start_Date__c =  Date.today();
        newHeader.Effective_End_Date__c = Date.today().addmonths(6);
        newHeader.Account_Name__c = pAccountId; 
        newHeader.Active__c= true;
        newHeader.Currency__c = currencyString;
        return newHeader;
    }

    private static String getOppProdJson(Id oppId, Boolean isDelete){
        opportunitylineitem oli = [SELECT Product2.Id,Product2.Name, Id, name, Average_Renewal_Commit_MRR__c , Projected_Monthly_commit_fees__c,MRR__c,
            Specialist_Net_MRR__c,Average_Renewal_Usage_MRR__c,Projected_Avg_Rev_Non_Commit__c,Net_Non_Commit__c,
            NRR__c,Term__c,Opportunity.CurrencyIsoCode,Specialist_Projected_Monthly_Commit__c,
            Specialist_Forecast_Category__c,Specialist_Close_Date__c,Specialist_Touched__c,Specialist_NRR_Touched__c,
            Specialist_Forecast_Touched__c,Specialist_Usage_Touched__c,Specialist_Close_Date_Touched__c, Specialist_NRR__c,Emri__c,
            CurrencyIsoCode, opportunityId, (SELECT Contract_Product__c FROM Associated_Contract_Products__r)from OpportunityLineItem WHERE OpportunityId =: oppId][0];

        l2qManageProductController.OpportunityProductWrapper oppProdWrapperObj = new l2qManageProductController.OpportunityProductWrapper();
        oppProdWrapperObj.Name = oli.name;
        if(!isDelete){
            oppProdWrapperObj.SFid = null;
        }
        else{
            oppProdWrapperObj.SFid = oli.id;
        }
        oppProdWrapperObj.ProductId = oli.Product2.Id;
        oppProdWrapperObj.Baseline_Mrr = String.valueOf(oli.Average_Renewal_Commit_MRR__c);
        oppProdWrapperObj.Forecast_Mrr = String.valueOf(oli.Projected_Monthly_commit_fees__c);
        oppProdWrapperObj.Net_Mrr = String.valueOf(oli.MRR__c);
        oppProdWrapperObj.Specialist_Net_Mrr = String.valueOf(oli.Specialist_Net_MRR__c);
        oppProdWrapperObj.Baseline_Usage = String.valueOf(oli.Average_Renewal_Usage_MRR__c);
        oppProdWrapperObj.Forecast_Usage = String.valueOf(oli.Projected_Avg_Rev_Non_Commit__c);
        oppProdWrapperObj.Net_Usage = String.valueOf(oli.Net_Non_Commit__c);
        oppProdWrapperObj.Onetime_Fee = String.valueOf(oli.NRR__c);
        oppProdWrapperObj.Specialist_Onetime_Fee = String.valueOf(oli.Specialist_NRR__c);
        oppProdWrapperObj.Term = String.valueOf(oli.Term__c);
        oppProdWrapperObj.Specialist_Projected_Monthly_Commit = String.valueOf(oli.Specialist_Projected_Monthly_Commit__c);
        oppProdWrapperObj.Specialist_Forecast_Category = oli.Specialist_Forecast_Category__c;
        oppProdWrapperObj.Specialist_Close_Date = oli.Specialist_Close_Date__c;
        oppProdWrapperObj.isNew = false;
        oppProdWrapperObj.isDelete = isDelete;
        oppProdWrapperObj.currencyOpp = oli.Opportunity.CurrencyIsoCode;
        oppProdWrapperObj.oppId = oli.opportunityId;
        oppProdWrapperObj.SpCommitTouched = false;
        oppProdWrapperObj.SpUsageTouched = false;
        oppProdWrapperObj.SpForecastTouched = false;
        oppProdWrapperObj.SpOneTimeFeeTouched = false;
        oppProdWrapperObj.SpCloseDateTouched = false;
        oppProdWrapperObj.Emri = String.valueOf(oli.Emri__c);
        oppProdWrapperObj.isFromContractScreen = false;
        List<l2qManageProductController.ContractDetail> contractDetailsList = new List<l2qManageProductController.ContractDetail>();
        l2qManageProductController.ContractDetail contractDetails = new l2qManageProductController.ContractDetail();

        Merge_Contract_Header__c contract = [Select id, name, Currency__c, Effective_End_Date__c, Effective_Start_Date__c, Auto_Renew__c, Parent_Contract__c, Order_Id__c, Contract_Type__c, (Select id from Contract_Products__r where Forecast_Product_Id__c = 'F-PR-45734') from Merge_Contract_Header__c where Original_Contract_Id__c = 'C-YJSEX11'][0];
        contractDetails.ContractId = contract.id;
        contractDetails.Name = contract.name;
        contractDetails.CurrencyIsoCode = contract.Currency__c;
        contractDetails.EffectiveStartDat = contract.Effective_Start_Date__c;
        contractDetails.EffectiveEndDate = contract.Effective_End_Date__c;
        contractDetails.AutoRenew = null;
        contractDetails.ParentContract = null;
        contractDetails.OrderId = null;
        contractDetails.ContractType = null;
        contractDetails.contractProductId = contract.Contract_Products__r[0].id;

        contractDetailsList.add(contractDetails);

        oppProdWrapperObj.contractDetailObj = contractDetailsList;

        return JSON.serializePretty(oppProdWrapperObj);
    }


    @testSetup
    static void setupMethod(){
        Account acc = utilTestClass.CreateAccount('Test_Account');
        acc.BillingStreet = '#39,7th Cross';
        acc.BillingCity   = 'LA';
        acc.BillingState = 'CA';
        acc.BillingPostalCode = '99992';
        acc.BillingCountry = 'USA';
        acc.Type='Lead';
        acc.Parent_Division__c = 'Web EMEA_Web' ; // SFDC 7061
        insert acc;

        Merge_Contract_Header__c renewalContract = CreateContractHeader('C-YJSEX11', acc.Id,'USD');
        insert renewalContract;

        List<Contract_Product__c> contractProductList = new List<Contract_Product__c>();
        Contract_Product__c contractProduct1 = utilTestClass.CreateContractProduct(renewalContract.Original_Contract_Id__c,'PROD-123','AKAM-123');
        contractProduct1.Average_Renewal_Commit_MRR__c = 200;
        contractProduct1.Average_Renewal_Usage_MRR__c = 200;
        contractProduct1.UnitPrice__c = 1;
        contractProduct1.Original_Contract_id__c = renewalContract.Id;
        contractProduct1.Forecast_Product_Id__c = 'F-PR-4573';
        contractProduct1.Effective_End_Date__c = Date.today().addmonths(4);
        contractProductList.add(contractProduct1);

        Contract_Product__c contractProduct2 = utilTestClass.CreateContractProduct(renewalContract.Original_Contract_Id__c,'PROD-1234','AKAM-1234');
        contractProduct2.Average_Renewal_Commit_MRR__c = 200;
        contractProduct2.Average_Renewal_Usage_MRR__c = 200;
        contractProduct2.UnitPrice__c = 1;
        contractProduct2.Original_Contract_id__c = renewalContract.Id;
        contractProduct2.Forecast_Product_Id__c = 'F-PR-45734';
        contractProduct2.Effective_End_Date__c = Date.today().addmonths(4);
        contractProductList.add(contractProduct2);

        insert contractProductList;

        Opportunity oppty = utilTestClass.CreateOpportunity('__Test Oppty','1. Identify Need');
        oppty.AccountId = acc.Id;
        oppty.CloseDate = Date.today().addMonths(4);
        oppty.Validation_Override__c = true;
        insert oppty;

        List<Product2> Product2List = new List<Product2>();
        Product2 testProduct= new Product2();
        testProduct.Name = 'Test_Service_Product';
        testProduct.family = 'Service';
        testProduct.AKAM_INT_ID__c = 333;
        testProduct.AKAM_Product_ID__c = 'F-PR-4573';
        testProduct.isActive = true;
        testProduct.RecordTypeId = '012G00000010kXdIAI';
        Product2List.add(testProduct);
        

        Product2 testProduct1= new Product2();
        testProduct1.Name = 'Test_Service_Product2';
        testProduct1.family = 'Service2';
        testProduct1.AKAM_INT_ID__c = 3334;
        testProduct1.AKAM_Product_ID__c = 'F-PR-45734';
        testProduct1.isActive = true;
        testProduct1.RecordTypeId = '012G00000010kXdIAI';
        Product2List.add(testProduct1);

        insert Product2List;

        List<PricebookEntry> pricebookEntryList = new List<PricebookEntry>();
        PricebookEntry pbEntry = new PricebookEntry();
        pbEntry.Pricebook2Id = Test.getStandardPricebookId();
        pbEntry.Product2Id   = testProduct.id;
        pbEntry.CurrencyIsoCode = 'USD';
        pbEntry.IsActive     = true;
        pbEntry.UnitPrice    = 1; 
        pricebookEntryList.add(pbEntry);

        PricebookEntry pbEntry1 = new PricebookEntry();
        pbEntry1.Pricebook2Id = Test.getStandardPricebookId();
        pbEntry1.Product2Id   = testProduct1.id;
        pbEntry1.CurrencyIsoCode = 'USD';
        pbEntry1.IsActive     = true;
        pbEntry1.UnitPrice    = 1; 
        pricebookEntryList.add(pbEntry1);

        insert pricebookEntryList;

        OpportunityLineItem oli = new OpportunityLineItem();
        oli.opportunityId       = oppty.id;
        oli.pricebookentryid    = pbEntry.Id;
        oli.quantity            = 1;
        oli.unitprice           = 200;
        oli.Average_Renewal_Commit_MRR__c = 100;
        oli.Average_Renewal_Usage_MRR__c = 100;
        oli.Projected_Monthly_commit_fees__c = 100;
        oli.Projected_Avg_Rev_Non_Commit__c = 100;
        insert oli;
        /*
        Renewal_Contract_Object__c renewalContractRecord    = new Renewal_Contract_Object__c();
        renewalContractRecord.Name = renewalContract.Original_Contract_Id__c;
        renewalContractRecord.Contract__c = renewalContract.Id;
        renewalContractRecord.Opportunity__c = oppty.id;
        renewalContractRecord.Contract_Id_Text__c = renewalContract.Original_Contract_Id__c;
        renewalContractRecord.Contract_Effective_End_Date__c  = oppty.closeDate;
        insert renewalContractRecord;

        Renewal_Contract_Product__c acp = new Renewal_Contract_Product__c();
        acp.Associated_Contract__c = renewalContractRecord.id;
        acp.Opportunity_Product__c = oli.id;
        acp.Contract_Product__c = contractProduct1.id;
        acp.End_Month__c = contractProduct1.Effective_End_Date__c.year()+'-'+contractProduct1.Effective_End_Date__c.month();
        acp.name = contractProduct1.Forecast_Product_id__c;
        insert acp;*/

    }


    static testmethod void testManageProductPage(){
        Test.startTest();
        Opportunity opp = [Select id, Opportunity_Sub_Category__c, Opportunity_Category__c, Aggregation_Partner__c, Competitor__c, Loss_Reason__c from opportunity where name = '__Test Oppty'][0];
        product2 product = [Select id from product2 where AKAM_Product_ID__c = 'F-PR-4573'];

        List<OpportunityLineItem> oliList = l2qManageProductController.getOpportunityProductsWithContracts(opp.id);
        Map<String,String> priceBookEntryToProdAkamId = l2qManageProductController.getPriceBookEntry(new List<String>{product.id}, 'USD');
        l2qManageProductController.OpportunityProductWrapper oppProductWrapperObj = (l2qManageProductController.OpportunityProductWrapper)JSON.deserialize(getOppProdJson(opp.id, false), l2qManageProductController.OpportunityProductWrapper.class);
        l2qManageProductController.doDmlOnOpportunityLineItems(new List<l2qManageProductController.OpportunityProductWrapper>{oppProductWrapperObj});
    
        List<l2qManageProductController.OpportunityWrapper> updateOpttyDetailsWrapperList = new List<l2qManageProductController.OpportunityWrapper>();

        l2qManageProductController.OpportunityWrapper updateOpttyDetailsWrapper1 = new l2qManageProductController.OpportunityWrapper();
        updateOpttyDetailsWrapper1.fieldApiName = 'Order_Level__c';
        updateOpttyDetailsWrapper1.value = 'Test Data';
        updateOpttyDetailsWrapperList.add(updateOpttyDetailsWrapper1);

        l2qManageProductController.OpportunityWrapper updateOpttyDetailsWrapper2 = new l2qManageProductController.OpportunityWrapper();
        updateOpttyDetailsWrapper2.fieldApiName = 'Id';
        updateOpttyDetailsWrapper2.value = String.valueOf(opp.id);
        updateOpttyDetailsWrapperList.add(updateOpttyDetailsWrapper2);
        
        try{

            l2qManageProductController.getGSMSettingValue('termValidationProfiles');

            l2qManageProductController.saveOpptyAndProductHandler( JSON.serializePretty(opp) ,JSON.serializePretty(updateOpttyDetailsWrapperList));

            l2qManageProductController.insertOpportunity(JSON.serializePretty(updateOpttyDetailsWrapperList));

            l2qManageProductController.save(JSON.serializePretty(updateOpttyDetailsWrapperList), getOppProdJson(opp.id, false));
        }
        catch(AuraHandledException e){
            System.debug('exception handled');
        }
        
        Test.stopTest();
    }

    static testmethod void test2ManageProductPage(){
        Test.startTest();
        Opportunity opp = [Select id, accountId, Opportunity_Sub_Category__c, Opportunity_Category__c, Aggregation_Partner__c, Competitor__c, Loss_Reason__c from opportunity where name = '__Test Oppty'][0];
        product2 product = [Select id from product2 where AKAM_Product_ID__c = 'F-PR-4573'];
        Merge_Contract_Header__c contract = [Select id, name, Currency__c, Effective_End_Date__c, Effective_Start_Date__c, Auto_Renew__c, Parent_Contract__c, Order_Id__c, Contract_Type__c, (Select id from Contract_Products__r where Forecast_Product_Id__c = 'F-PR-45734') from Merge_Contract_Header__c where Original_Contract_Id__c = 'C-YJSEX11'][0];
        
        contract.Account_Name__c = opp.accountId;
        contract.Active__c = true;
        update contract;

        List<String> getForecastCategoryList = l2qManageProductController.getForecastCategory();
        User usr = l2qManageProductController.getUserInfo();
        Boolean hasAccessss = l2qManageProductController.hasEditAccess(String.valueOf(usr.id));
        map<String,Decimal> isoCodeToConversionRate = l2qManageProductController.getCurrencyConversionRates(Date.today());

        List<String> picklistValues = new List<String>{'Opportunity_Sub_Category','Opportunity_Category','Aggregation_Partner','Competitor','Loss_Reason','Opportunity_Type','Zoff_Status'};
        for(String valueString : picklistValues){
            String value = l2qManageProductController.removeNoneFromPicklist(valueString, '--None--');
        }

        Map<String,Product2> akamIdToProduct = l2qManageProductController.getProduct2Records(opp.accountId);

        List<OpportunityLineItem> oliList = l2qManageProductController.getOpportunityProducts(String.valueOf(opp.id));

        Map<String,Map<String,List<Contract_Product__c>>> ContractProdd = l2qManageProductController.getContractProducts(opp.accountId);

        Map<String,List<Product2>> familyToProduct = l2qManageProductController.getForecastProducts();


        
        l2qManageProductController.OpportunityProductWrapper oppProductWrapperObj = (l2qManageProductController.OpportunityProductWrapper)JSON.deserialize(getOppProdJson(opp.id, true), l2qManageProductController.OpportunityProductWrapper.class);
        l2qManageProductController.doDmlOnOpportunityLineItems(new List<l2qManageProductController.OpportunityProductWrapper>{oppProductWrapperObj});
    
        l2qManageProductController.ContractDetail contractDetails = new l2qManageProductController.ContractDetail();
        contractDetails.ContractId = contract.id;
        contractDetails.Name = contract.name;
        contractDetails.CurrencyIsoCode = contract.Currency__c;
        contractDetails.EffectiveStartDat = contract.Effective_Start_Date__c;
        contractDetails.EffectiveEndDate = contract.Effective_End_Date__c;
        contractDetails.AutoRenew = null;
        contractDetails.ParentContract = null;
        contractDetails.OrderId = null;
        contractDetails.ContractType = null;
        contractDetails.contractProductId = contract.Contract_Products__r[0].id;

        try{
            List<l2qManageProductController.OpportunityWrapper> updateOpttyDetailsWrapperList = new List<l2qManageProductController.OpportunityWrapper>();

            l2qManageProductController.OpportunityWrapper updateOpttyDetailsWrapper1 = new l2qManageProductController.OpportunityWrapper();
            updateOpttyDetailsWrapper1.fieldApiName = 'Order_Level';
            updateOpttyDetailsWrapper1.value = 'Test Data';
            updateOpttyDetailsWrapperList.add(updateOpttyDetailsWrapper1);
            l2qManageProductController.insertOpportunity(JSON.serializePretty(updateOpttyDetailsWrapperList));
        }
        catch(AuraHandledException e){
            System.debug('exception handled');
        }
    

        //Renewal_Contract_Object__c rcb = l2qManageProductController.createRenewalContractRecord(contractDetails, String.valueOf(opp.id));
        Test.stopTest();
    }
}