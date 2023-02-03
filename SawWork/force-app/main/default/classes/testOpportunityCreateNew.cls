/***
testOpportunityCreateNew
@author : Sonali Tandon <standon@akamai.com>
@Description : This Class tests the following logic for OpportunityCreateNew page & controller.

@History
--Developer           --Date            --Change
Sonali Tandon      15/01/2014          Created the class.
Sonali Tandon       15/01/2014          -testOpenOpptys () 
-testnoOpenOpptys()
*/   

@isTest(seeAllData = false)
public class testOpportunityCreateNew {
    
    public static List<Opportunity> opptyList = new List<Opportunity>();
    
    
    private static Id createAccount(){
        Account a = utilTestClass.CreateAccount('__ TEST');
        Database.insert(a);
        return a.id;
    }
    
    private static Opportunity CreateOpportunities(Id AccountId, String stage, Integer i) {
        
        Opportunity o = utilTestClass.CreateOpportunity('__ TEST'+i,stage);
        o.AccountId    = AccountId;
        o.CloseDate    = Date.today();
        //o.RecordTypeId ='012A0000000CvQL';
        o.Validation_Override__c = true;
        return o;
    }
    
    
    static testmethod void testOpenOpptys(){
        
        opptyList.clear();
        
        // create account
        Id accountId = createAccount();
        
        //Create open opportunities
        for(Integer i=0; i<10; i++)
        {
            Opportunity o = CreateOpportunities(accountId,'1. Identify Need',i);
            opptyList.add(o);
        }
        
        //Create closed opportunities
        for(Integer i =0; i<5; i++)
        {
            Opportunity o = CreateOpportunities(accountId,'Closed Won',i);
            opptyList.add(o);
        }
        
        insert opptyList;
        
        Opportunity o = CreateOpportunities(accountId,'Closed Won',10);
        
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(o);
        OpportunityCreateNew opptyCreateNewController = new OpportunityCreateNew(sc);      
        Test.stopTest();
        
        system.assertEquals(opptyCreateNewController.flag,true);
        system.assertEquals(opptyCreateNewController.openOpps.size(),10);
    }
    
    static testmethod void testnoOpenOpptys(){
        
        opptyList.clear();
        
        //create account
        Id accountId = createAccount();
        
        //Create closed opportunities only 
        for(Integer i =0; i<5; i++)
        {
            Opportunity o = CreateOpportunities(accountId,'Closed Won',i);
            opptyList.add(o);
        }
        
        insert(opptyList);
        
        Opportunity o = CreateOpportunities(accountId,'Closed Won',10);
        
        Test.startTest();
        ApexPages.StandardController sc = new ApexPages.StandardController(o);
        OpportunityCreateNew opptyCreateNewController = new OpportunityCreateNew(sc); 
        opptyCreateNewController.selectedOpptyType = 'New Logo';   
        opptyCreateNewController.pageRedirect(); 
        Test.stopTest();
        
        system.assertEquals(opptyCreateNewController.flag,false);
        system.assertEquals(opptyCreateNewController.openOpps.size(),0);
        
    }
    
    static testmethod void testopptymethod1(){
        Id accountId = createAccount();
        Opportunity o = CreateOpportunities(accountId,'Closed Won',11121);
        Merge_Contract_Header__c contractHeader = new Merge_Contract_Header__c();
        contractHeader.Original_Contract_Id__c = '_TEST CONTRACT _ 12';
        contractHeader.Name = '_TEST CONTRACT _ 12';
        contractHeader.Account_Name__c = accountId;
        contractHeader.Active__c = true;
        contractHeader.Locked__c = true;
        contractHeader.Effective_End_Date__c = Date.today()+100;
        contractHeader.Currency__c = 'USD';
        contractHeader.Opportunity_Name__c = o.Id;
        insert contractHeader;
        contractHeader.Account_Name__c = accountId; 
        update contractHeader;
        
        Contract_Product__c cp = new Contract_Product__c ();
        cp.Original_Contract_Id__c = contractHeader.Id;
        cp.Contract_Product_Akam_Id__c = 'test123';
        cp.Forecast_Product_Id__c  = 'test124';
        cp.Deleted_From_Source__c = False;  
        insert cp;
        Test.startTest();
        OpportunityCreateNew createNewOppty = new OpportunityCreateNew();
        createNewOppty.opp = o;
        createNewOppty.openRenewalOpps = new List<Opportunity>();
        createNewOppty.contractBaselineOption = '';
        createNewOppty.contractSelected = '';
        createNewOppty.mchSelected = contractHeader;
        createNewOppty.isContractSelected = true;
        createNewOppty.opportunityContract = contractHeader;
        createNewOppty.hasContractBaseline = false;
        createNewOppty.isFeatureToggle = false;
        createNewOppty.selectedCurrency = '';
        createNewOppty.selectedcurrencyOption = '';
        createNewOppty.setOfSelectedContracts = new List<Merge_Contract_Header__c>{contractHeader};
        createNewOppty.showContractRelatedSection = false;
        createNewOppty.opportunityIdForContracts = null;
        createNewOppty.showContractsAssociatedToOppty = false;
        createNewOppty.associatedContracts = new List<Merge_Contract_Header__c>{contractHeader};
        createNewOppty.isContractCurrencyMismatch = false;
        createNewOppty.getContractBaselineOptions();
        createNewOppty.getContractBaselineOption();
        createNewOppty.setContractBaselineOption('test');
        createNewOppty.getContractFromAccount();
        OpportunityCreateNew.ContractWrapper ob = new OpportunityCreateNew.ContractWrapper();
        ob.mch = contractHeader;
        ob.CheckBox = true;
        OpportunityCreateNew.cwList = new List<OpportunityCreateNew.ContractWrapper>{ob};
        createNewOppty.getContractWrapper();
        createNewOppty.contractBaselineOption = 'Test New Opportunity without Contract Baseline Test';
        createNewOppty.checkOptionValue();
        createNewOppty.contractBaselineOption = 'Test New Create Opportunity With Contract Baseline Test';
        createNewOppty.checkOptionValue();
        createNewOppty.contractBaselineOption = 'Test New Contract Change Opportunity Test';
        createNewOppty.checkOptionValue();
        OpportunityCreateNew.cwList = new List<OpportunityCreateNew.ContractWrapper>{ob};
        createNewOppty.inputCheckForRenewalOppty();
        createNewOppty.setOfSelectedContracts = new List<Merge_Contract_Header__c>{contractHeader};
        createNewOppty.SkipIntermediateOpptyCreationPage = 'Test';
        createNewOppty.selectedOpptyType = 'Churn';
        createNewOppty.createOpportunity();
        createNewOppty.inputCheckForGetBaseline();
        createNewOppty.getCurrencies();
        createNewOppty.getcurrencyOptions();
        OpportunityCreateNew.ContractProductWrapper obj = new OpportunityCreateNew.ContractProductWrapper();
        obj.averageRenewalCommit = 0;
        obj.averageRenewalUsage = 0;
        obj.currencyCode = '';
        obj.forecastProductName = '';
        createNewOppty.contractIdForProduct = '_TEST CONTRACT _ 12';
        //createNewOppty.getContractProductWrapper();
        createNewOppty.showContractProducts();
        createNewOppty.closePopup();
        createNewOppty.showContractsAssociatedToOppty();
        createNewOppty.closeContractsAssociatedToOppty();
        createNewOppty.setOfSelectedContracts = new List<Merge_Contract_Header__c>{contractHeader};
        createNewOppty.contractChangeType = 'OTHERS';
        createNewOppty.getContractChangeOptions();  
        createNewOppty.onContractTypeChange();  
        createNewOppty.navigateToNextScreen();  
        createNewOppty.closeContractsAssociatedToOppty();   
        createNewOppty.showContractsAssociatedToOppty();    
        createNewOppty.closePopup();    
        createNewOppty.showContractProducts();
        createNewOppty.navigateToNextScreen();
        Test.stopTest();
    }
    
}