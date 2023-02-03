//Created By Saket More


@isTest
public class DissociateContractPageTestClass {
    
    static{
        utilTestClass.insertCustomSettings();
    }

    static testmethod void DissociateContract() {

        Account account = utilTestClass.CreateAccount('Test_Account');
        account.BillingStreet = '#39,7th Cross';
        account.BillingCity   = 'LA';
        account.BillingState = 'CA';
        account.BillingPostalCode = '56005';
        account.BillingCountry = 'USA';
        account.Type='Lead';
        insert account;
        
        Opportunity oppty0 = utilTestClass.CreateOpportunity('Test_Opportunity', '1. Identify Need');
        oppty0.AccountId      = account.Id;
        //oppty0.CurrencyIsoCode = 'INR'; 
        oppty0.CloseDate   = System.today();
        oppty0.Renew_Contract_Id_Text__c = 'C-YJSEX11,C-YJSEX10';
        insert oppty0;


        Merge_Contract_Header__c contObj = new Merge_Contract_Header__c();
        contObj.Account_Name__c =oppty0.accountid;
        contObj.Active__c = true;
        contObj.Effective_End_Date__c = system.today();
        insert contObj;
        
          Renewal_Contract_Object__c renewalContract    = new Renewal_Contract_Object__c();
          renewalContract.Name              = contObj.Original_Contract_Id__c;
          renewalContract.Contract__c           = contObj.Id;
          renewalContract.Opportunity__c                = oppty0.Id;
          renewalContract.Contract_Id_Text__c       = contObj.Original_Contract_Id__c;
          insert renewalContract;

        List<Product2> productList = new List<Product2>();
            
            Product2 testProduct1= new Product2();
            testProduct1.Name = 'Test_Security_Product';
            testProduct1.family = 'Security';
            testProduct1.AKAM_INT_ID__c = 111;
            testProduct1.AKAM_Product_ID__c='F-PR-4575';
            productList.add(testProduct1);
            
            Product2 testProduct2= new Product2();
            testProduct2.Name = 'Test_Web_Product';
            testProduct2.family = 'Web';
            testProduct2.AKAM_INT_ID__c = 222;
            testProduct2.AKAM_Product_ID__c='F-PR-4574';
            productList.add(testProduct2);
            
            Product2 testProduct3= new Product2();
            testProduct3.Name = 'Test_Service_Product';
            testProduct3.family = 'Service';
            testProduct3.AKAM_INT_ID__c = 333;
            testProduct3.AKAM_Product_ID__c='F-PR-4573';
            productList.add(testProduct3);

            Product2 testProduct4= new Product2();
            testProduct4.Name = 'Test_Enterprise_Product';
            testProduct4.family = 'Enterprise';
            testProduct4.AKAM_INT_ID__c = 444;
            testProduct4.AKAM_Product_ID__c='F-PR-55000';
            productList.add(testProduct4);
            
            Test.startTest();
            insert productList;
            
            // Create pricebook entries
            List<PricebookEntry> pricebookList = new List<PricebookEntry>();
            for(Product2 product : productList)
            {
                PricebookEntry pbEntry= new PricebookEntry();
                pbEntry.Pricebook2Id = Test.getStandardPricebookId();
                pbEntry.Product2Id   = product.id;
                pbEntry.CurrencyIsoCode = 'USD';
                pbEntry.IsActive     = true;
                pbEntry.UnitPrice    = 1; 
                pricebookList.add(pbEntry);      
            }
            insert(pricebookList);
            // Create line items 
            List<OpportunityLineItem> OpportunityLineItemList= new List<OpportunityLineItem>();
            for(PricebookEntry pbEntry : pricebookList) {
                OpportunityLineItem oli = new OpportunityLineItem();
                oli.opportunityId       = oppty0.id;
                oli.pricebookentryid    = pbEntry.Id;
                oli.quantity            = 1;
                oli.unitprice           = 200;
                oli.Average_Renewal_Commit_MRR__c = 100;
                oli.Average_Renewal_Usage_MRR__c = 100;
                oli.Projected_Monthly_commit_fees__c = 100;
                oli.Projected_Avg_Rev_Non_Commit__c = 100;
                OpportunityLineItemList.add(oli);
            }
            
            insert OpportunityLineItemList;
            Test.stopTest();
            



        PageReference pageRef = Page.disassociateContractPage;
        Test.setCurrentPageReference(pageRef);
        pageRef.getParameters().put('opportunityId', oppty0.id);
        DissociateContractPageClass fruc1 = new DissociateContractPageClass();
        fruc1.disassociateContract();
        fruc1.backToOppty();

        list<OpportunityLineItem> lineItem = [Select id, Average_Renewal_Commit_MRR__c, Average_Renewal_Usage_MRR__c from OpportunityLineItem where OpportunityId =:oppty0.Id]; 


       // System.assertEquals(lineItem.size(),0);



        //Opportunity with no contract associated
        Opportunity oppty1 = utilTestClass.CreateOpportunity('Test_Opportunity1', '2. Explore Options');
        oppty1.AccountId      = account.Id;
        oppty1.CurrencyIsoCode = 'INR'; 
        oppty1.CloseDate = System.today();
        insert oppty1;



        pageRef.getParameters().put('opportunityId', oppty1.id);
        fruc1.showMessage = false;
        fruc1.disassociateContract();
        fruc1.backToOppty();
       // fruc1.checkOpportunityStage();

        lineItem = [Select id, Average_Renewal_Commit_MRR__c, Average_Renewal_Usage_MRR__c from OpportunityLineItem where OpportunityId =:oppty1.Id]; 


        System.assertEquals(lineItem.size(),0);


    }
    
}