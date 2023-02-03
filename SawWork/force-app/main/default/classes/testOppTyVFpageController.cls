@isTest(SeeAllData=false)
public class testOppTyVFpageController {


    public static Map<String,GSM_Settings__mdt> testcaseCustomSettings = GsmUtilClass.getGsmSettingValue();
    private static Map<String,Features_Toggle__c> featureToggleCustomSettings = Features_Toggle__c.getAll();
    
    private static Id createAccount(){
        Account a = utilTestClass.CreateAccount('__ TEST');
        // Add Owner to the Account
       // a.OwnerId = accOwnerUser.Id; 
        a.BillingStreet = 'Maple Ave';
        a.BillingState = 'NY';
        a.BillingPostalCode = '10514';
        a.BillingCountry = 'USA';
        a.BillingCity = 'Chappaqua';
        Database.insert(a);
        return a.id;
    }

    private static id generatePriceBook(){
        /* Create the opportunity */
        /* Get the standard pricebook. There must be a standard pricebook already 
        in the target org.  */
       /* Pricebook2 pb = [select id,name, isactive from Pricebook2 where IsStandard = true limit 1];

        if(!pb.isactive) {
            pb.isactive = true;
            Database.update(pb);
        }*/
        Pricebook2 pb = new Pricebook2();
        pb.name = 'Standard Price Book 2009';
        pb.Description = 'Price Book 2009 Products';
        pb.isactive = true;
      // pb.IsStandard = true;
        insert pb;
        return pb.id;

    }

    private static Id CreateOpportunity(Id AccountId, Id pricebookId) {
        Opportunity o = utilTestClass.CreateOpportunity('__ TEST','1. Identify Need');
        o.AccountId    = AccountId;
        o.CloseDate    = Date.today();
        o.Pricebook2Id = pricebookId;
        o.RecordTypeId = GsmUtilClass.getGSMSettingValue('OpptyTrigger_AkamaiOpptyRecType'); // SFDC-2705 Custom Settings Migration
        Database.insert(o);
        return o.id;
    }

    private static Id createPriceBookandProduct(Id pricebookId){
        /* Create a product2 */
        Product2 p = new Product2();
        p.Name     = 'TEST';
        Database.insert(p);

        /* Create a pricebook entry. */
        PricebookEntry pbe = new PricebookEntry();
        pbe.Pricebook2Id = pricebookId;
        //Test.getStandardPricebookId();
        pbe.Product2Id   = p.id;
        pbe.IsActive     = true;
        pbe.UnitPrice    = 1;

        Database.insert(pbe);
        return pbe.Id;

    }

    private static Id createOLI(Id OppId, Id PricebookEntry){
        /* Create a line item */
        OpportunityLineItem i = new OpportunityLineItem();
        i.opportunityId       = OppId;
        i.pricebookentryid    = PricebookEntry;
        i.quantity            = 1;
        i.unitprice           = 1;

        Database.insert(i);
        return i.Id;

    }     
        
        static testmethod void testPageOppTyVfPage(){
        Id accountId = createAccount();
        
        Id pricebookId = generatePriceBook();
        /* Setup a basic opportunity */
        Opportunity o = utilTestClass.CreateOpportunity('__ TEST','1. Identify Need');
        o.AccountId    = AccountId;
        o.CloseDate    = Date.today();
        o.Pricebook2Id = pricebookId;
        o.RecordTypeId = GsmUtilClass.getGSMSettingValue('OpptyTrigger_AkamaiOpptyRecType'); // SFDC-2705 Custom Settings Migration
        Database.insert(o);
        
        VisualFlowOppty__c VFlow=new VisualFlowOppty__c();
        VFlow.Name='not having auto renewal claus';
        VFlow.FullName__c ='not having auto renewal clause';
        VFlow.IsActive__c = true;
        VFlow.List_Order__c =1;
        VFlow.Value__c ='not having auto renewal clause';
        VFlow.Is_it_contains_Flow__c = true;
        insert VFlow;

        /* Switch to runtime context */
        Test.startTest();
    
        ApexPages.StandardController sc = new ApexPages.StandardController(o);
        opptyVFpageController opptyController = new opptyVFpageController(sc);
        
        PageReference pageRef = Page.opptyVFpage;
        pageRef.getParameters().put('id', o.id);
        Test.setCurrentPageReference(pageRef);
        Test.stopTest();
    }

    static testmethod void  testMarkOpptyAsChurnFlow() {
        Id accountId = createAccount();
        Id pricebookId = generatePriceBook();
        Id pricebookId1 = Test.getStandardPricebookId();
        /* Setup a basic opportunity */
        Id OppId = CreateOpportunity(AccountId ,pricebookId1);
        Id PricebookEntry = createPriceBookandProduct(pricebookId1);
        Id oLi = createOLI(OppId, PricebookEntry);
       
        Test.startTest();
        PageReference pageRef = Page.MarkOpptyAsChurnPage;
        pageRef.getParameters().put('id', OppId);
        pageRef.getParameters().put('Name' ,'Mark OpportunityAsChurn');
        Test.setCurrentPageReference(pageRef);
        opptyVFpageController opptyController = new opptyVFpageController();
        opptyController.SaveOli();
        opptyController.saveOLiAndOppty();
        opptyController.getPageA();
        Test.stopTest();

    }

    static testmethod void testUpdateAsChurnFlow_ValidationFailed(){

        Id accountId = createAccount();
        Id pricebookId = Test.getStandardPricebookId();

        //generatePriceBook();
        /* Setup a basic opportunity */
        Id OppId = CreateOpportunity(AccountId ,pricebookId);
        Id PricebookEntry = createPriceBookandProduct(pricebookId);
        //Id oLi = createOLI(OppId, PricebookEntry);
        Test.startTest();
        PageReference pageRef = Page.MarkOpptyAsChurnPage;
        pageRef.getParameters().put('id', OppId);
        pageRef.getParameters().put('Name' ,'not having auto renewal clause');
        Test.setCurrentPageReference(pageRef);
        opptyVFpageController opptyController = new opptyVFpageController();
       // opptyController.getSubCategoriesOptions();
       // opptyController.Subcategory ='Lost Customer';
        opptyController.getLossOptions();
        //opptyController.saveOLiAndOppty();
        Test.stopTest();
    }

     static testmethod void testUpdateAsChurnFlow_VaLidPass(){

        Id accountId = createAccount();
        Id pricebookId = Test.getStandardPricebookId(); 
        //generatePriceBook();
        /* Setup a basic opportunity */
        Opportunity o = utilTestClass.CreateOpportunity('__ TEST','1. Identify Need');
        o.AccountId    = AccountId;
        o.CloseDate    = Date.today();
        o.Pricebook2Id = pricebookId;
        o.RecordTypeId = GsmUtilClass.getGSMSettingValue('OpptyTrigger_AkamaiOpptyRecType'); // SFDC-2705 Custom Settings Migration
        o.competitor__c ='21 vianet';
        o.Aggregation_Partner__c ='TestPartner';
        Database.insert(o);
        Id PricebookEntry = createPriceBookandProduct(pricebookId);
        //Id oLi = createOLI(o.id, PricebookEntry);
        Test.startTest();
        PageReference pageRef = Page.MarkOpptyAsChurnPage;
        pageRef.getParameters().put('id', o.id);
        pageRef.getParameters().put('Name' ,'not having auto renewal clause');
        Test.setCurrentPageReference(pageRef);
        opptyVFpageController opptyController = new opptyVFpageController();
       // opptyController.getSubCategoriesOptions();
        //opptyController.Subcategory ='Aggregation through a Partner (Pick Partner)';
        opptyController.getLossOptions();
        opptyController.lossReason='Aggregation through Partner';
       // opptyController.renderAggregateFlag();
        opptyController.Next();
        opptyController.saveOLiAndOppty();
        Test.stopTest();
    }


     static testmethod void testMiscellaneousScenario(){

        Id accountId = createAccount();
        Id pricebookId = Test.getStandardPricebookId();
        //generatePriceBook();
        /* Setup a basic opportunity */
        Opportunity o = utilTestClass.CreateOpportunity('__ TEST','1. Identify Need');
        o.AccountId    = AccountId;
        o.CloseDate    = Date.today();
        o.Pricebook2Id = pricebookId;
        o.RecordTypeId = GsmUtilClass.getGSMSettingValue('OpptyTrigger_AkamaiOpptyRecType'); // SFDC-2705 Custom Settings Migration
        o.competitor__c ='21 vianet';
        o.Aggregation_Partner__c ='TestPartner';
        Database.insert(o);
        Id PricebookEntry = createPriceBookandProduct(pricebookId);
        VisualFlowOppty__c VFlow=new VisualFlowOppty__c();
        VFlow.Name='not having auto renewal clause';
        VFlow.FullName__c ='not having auto renewal clause';
        VFlow.IsActive__c = true;
        VFlow.List_Order__c =1;
        VFlow.Value__c ='not having auto renewal clause';
        VFlow.Is_it_contains_Flow__c = true;
        insert VFlow;
        Flow_Tracker__c fltracker=new Flow_Tracker__c();
        fltracker.name='not having auto renewal clause';
        insert fltracker;
        Test.startTest();
        PageReference pageRef = Page.MarkOpptyAsChurnPage;
        pageRef.getParameters().put('id', o.id);
        pageRef.getParameters().put('Name' ,'not having auto renewal clause');
        Test.setCurrentPageReference(pageRef);
        opptyVFpageController opptyController = new opptyVFpageController();
        //testing the flow
        // opptyVFpageController.updateChurnFlow  = new Flow.Interview.Update_Renewal_Opportunity_as_Churn();
         //opptyVFpageController.SysGenOppToChurn = new Flow.Interview.Changing_a_System_Generated_Opportunity_from_a_Churn();
      //  opptyController.getSubCategoriesOptions();
       // opptyController.Subcategory ='Contract Consolidation with Akamai Customer';
        opptyController.getLossOptions();
        opptyController.lossReason='Contract Consolidation';
        opptyController.checkLossReason();
       // opptyController.renderAggregateFlag();
        List<opptyVFpageController.WrapperClass> wc = opptyController.getWrapperList();
        opptyController.saveOLiAndOppty();
        //Sonali Tandon - CR 2841078 - Visual WF 4.2: Add Opportunity product
        opptyController.opptyProdRedirect();
        opptyController.lossReason='Competition - Features/Performance';
        opptyController.checkLossReason();
        //opptyController.lossReason='Will not accept Akamai Terms and Conditions';
        //opptyController.checkLossReason();
        //opptyController.lossReason='Initial Out Clause';
        //opptyController.checkLossReason();
        opptyController.FlowName = System.Label.not_having_auto_renewal_clause;
        opptyController.validate();
        opptyController.lossReason = '--- None ---';
        opptyController.FlowDetail();
        //opptyController.validate();
        Test.stopTest();
    }
}