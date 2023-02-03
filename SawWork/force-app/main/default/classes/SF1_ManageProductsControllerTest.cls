@isTest(seeAllData=false)
public class SF1_ManageProductsControllerTest {
    static testmethod void fetchOpportunityTest(){
        String Message;
        OpportunityLineItem oppLineObj = new OpportunityLineItem();
        Opportunity oppRecord = new Opportunity();
        Map<String,String> prodNamesMap = new Map<String,String>();
        Map<String,List<String>> dependentPickListValues = new Map<String,List<String>>();
        Boolean negativeValueCheck = false;
        Profile prof = [SELECT Id FROM Profile WHERE Name like '%System Admin%'][0];
        User u = new User(alias = 'someUser', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__old_owner@akamai.com',profileid =prof.Id); 
        u.isActive=true;
        insert u;
        Account acc = utilTestClass.CreateAccount('__Test Account');
        acc.OwnerId =u.Id;
        acc.Website='https://TestOrg.co.in';
        insert acc;                       
        Opportunity oppty = utilTestClass.CreateOpportunity('__Test Oppty','1. Identify Need');
        oppty.AccountId =acc.Id;
        oppty.OwnerId = u.Id;
        oppty.CloseDate = Date.today().addMonths(4);            
        insert oppty; 
        
        Product2 p = new Product2();
        p.Name     = 'TESTManageProd';
        Database.insert(p);
        
        PricebookEntry pbe = new PricebookEntry();
        pbe.Pricebook2Id = Test.getStandardPricebookId();
        pbe.Product2Id   = p.id;
        pbe.IsActive     = true;
        pbe.UnitPrice    = 1;
        Database.insert(pbe);
        
        OpportunityLineItem i = new OpportunityLineItem();
        i.opportunityId       = oppty.id;
        i.pricebookentryid    = pbe.id;
        i.quantity            = 1;
        i.unitprice           = 1;
        i.Projected_Monthly_commit_fees__c = 0;
        i.Projected_Avg_Rev_Non_Commit__c = 0;
        Database.insert(i);
        
        OpportunityLineItem oppLineItem = new OpportunityLineItem();
        oppLineItem.opportunityId       = oppty.id;
        oppLineItem.pricebookentryid    = pbe.id;
        oppLineItem.quantity            = 1;
        oppLineItem.unitprice           = 1;
        oppLineItem.Projected_Monthly_commit_fees__c = 0;
        oppLineItem.Projected_Avg_Rev_Non_Commit__c = 0;
        
        oppty=SF1_ManageProductsController.fetchOpportunity(oppty.id);
        oppLineObj = SF1_ManageProductsController.saveProductObj(i);
        OpportunityLineItem line = SF1_ManageProductsController.fetchOpportunityLineItem(i.Id);
        Message = SF1_ManageProductsController.deleteProductObj(i);
        Message = SF1_ManageProductsController.cancelProductObj(i);
        prodNamesMap =  SF1_ManageProductsController.fetchProductNames(oppty);      
        dependentPickListValues = SF1_ManageProductsController.getDependentPicklist('Opportunity', 'Opportunity_Category__c', 'Opportunity_Sub_Category__c');
        Test.startTest();
        Message = SF1_ManageProductsController.insertProductObj(oppLineItem);
        Message = SF1_ManageProductsController.updateOpportunityObj(oppty);
        Message = SF1_ManageProductsController.fetchPricebookEntry(p.Id,'USD');
        negativeValueCheck = SF1_ManageProductsController.checkBaselineNegativeAmount(oppty.Id);
        oppRecord = SF1_ManageProductsController.noContractChanges(oppty.Id);
        oppRecord = SF1_ManageProductsController.performChurnCancelOnOppLines(oppty,false);
        String UITheme = SF1_ManageProductsController.getUIThemeDescription();
        Boolean oppData = SF1_ManageProductsController.validateSpecialistUser(u.Id);
        Map<String,String> initValues = SF1_ManageProductsController.getInitValues(oppty);
        String userN = SF1_ManageProductsController.getUserProfileName();
        SF1_ManageProductsController.fetchOpportunityLineItemWrapperFunction(oppLineItem.Id);
        SF1_ManageProductsController.fetchPicklistValues('Opportunity','StageName');
        Test.stopTest();
    }
}