/**
* This class is used to create the quote for test classes. The method should be called only once per Test Class to avoid hitting the governor limits
* @author  Shashank Hegade / Kirti Mishra
* @version 1.0
* @since   2020-11-04
*/

@IsTest(seeAllData = false)
public without sharing class CPQ_TestQuoteSetupMethods {
    
    public static void simpleAutonomyQuoteSetup(){
        // This method create 1 Account, 1 opportunity, Standard Price Book, 1 partner Product, 1 Quote , 1 Quote Line and Custom Settings
        List<SBQQ__Quote__c> testQuotes = new List<SBQQ__Quote__c>();
        List<Opportunity> testOpps = new List<Opportunity>();
        // List<SBQQ__ProductOption__c> options = new List<SBQQ__ProductOption__c>();
        // List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>();
        
        Account testAccount = CPQ_TestDataFactory.createAccount(true);

        PriceBook2 stdPriceBook = CPQ_TestDataFactory.createStandardPriceBook();

        Product2 testProduct = new CPQ_TestDataFactory.ProductBuilder('Test Product 1', 'Partner_Products').saveRecord();

        PricebookEntry testEntry =  new CPQ_TestDataFactory.PriceBookEntryBuilder(testProduct.Id,stdPriceBook.Id).withCurrency('USD').withPrice(0.00).saveRecord();
        System.debug(LoggingLevel.INFO, 'testEntry: '+testEntry);

        
        for(Integer i = 0; i < 1 ; i++){
            testOpps.add(CPQ_TestDataFactory.createOpportunity(false,testAccount.Id));
        }
        
        insert testOpps;

        for(Integer i=0; i < 1; i++){
            testQuotes.add(new CPQ_TestDataFactory.CpqQuoteBuilder(testOpps[0]).withQuoteType('Partner').getRecord());
        }

        insert testQuotes;

        for (Integer i = 0; i < testQuotes.size(); i++) {
            SBQQ__QuoteLine__c testLine = new CPQ_TestDataFactory.QuoteLineBuilder(testQuotes[0],testProduct).saveRecord();
            System.debug(LoggingLevel.INFO, 'testLine: '+testLine);

        }
    }

    public static void autonomyQuoteWithBundleSetup(){
        //this method creates a quote with product bundle setup
        List<SBQQ__Quote__c> testQuotes = new List<SBQQ__Quote__c>();
        List<Opportunity> testOpps = new List<Opportunity>();
        List<Product2> products = new List<Product2>();
        List<SBQQ__ProductOption__c> options = new List<SBQQ__ProductOption__c>();
        List<SBQQ__QuoteLine__c> quoteLines = new List<SBQQ__QuoteLine__c>();
        
        Account testAccount = CPQ_TestDataFactory.createAccount(true);

        PriceBook2 stdPriceBook = CPQ_TestDataFactory.createStandardPriceBook();

        Product2 testProduct1 = new CPQ_TestDataFactory.ProductBuilder('Test Product 1', 'Partner_Products').getRecord();
        products.add(testProduct1);
        Product2 testProduct2 = new CPQ_TestDataFactory.ProductBuilder('Test Product 2', 'Partner_Products').getRecord();
        products.add(testProduct2);
        Product2 testProduct3 = new CPQ_TestDataFactory.ProductBuilder('Test Product 3', 'Partner_Products')
                                                                        .withCode('M-LC-134473')
                                                                        .getRecord();
                                                                        products.add(testProduct3);

        insert products;                                                    


        PricebookEntry testEntry1 =  new CPQ_TestDataFactory.PriceBookEntryBuilder(testProduct1.Id,stdPriceBook.Id).withCurrency('USD').withPrice(0.00).saveRecord();
        PricebookEntry testEntry2 =  new CPQ_TestDataFactory.PriceBookEntryBuilder(testProduct2.Id,stdPriceBook.Id).withCurrency('USD').withPrice(0.00).saveRecord();
        PricebookEntry testEntry3 =  new CPQ_TestDataFactory.PriceBookEntryBuilder(testProduct3.Id,stdPriceBook.Id).withCurrency('USD').withPrice(0.00).saveRecord();
        System.debug(LoggingLevel.INFO, 'testEntries: '+testEntry1+' -- '+testEntry2+' -- '+testEntry3);


        SBQQ__ProductFeature__c productFeature = new CPQ_TestDataFactory.ProductFeatureBuilder(testProduct1).saveRecord();

        SBQQ__ProductOption__c option1 = new CPQ_TestDataFactory.ProductOptionBuilder(testProduct1, testProduct2, productFeature)
                                            .withNumber(10)
                                            .getRecord();
                                            options.add(option1);

        SBQQ__ProductOption__c option2 = new CPQ_TestDataFactory.ProductOptionBuilder(testProduct1, testProduct2, productFeature)
                                            .withNumber(20)
                                            .getRecord();
                                            options.add(option2);

        SBQQ__ProductOption__c option3 = new CPQ_TestDataFactory.ProductOptionBuilder(testProduct1, testProduct3, productFeature)
                                            .withNumber(30)
                                            .getRecord();
                                            options.add(option3);

        insert options;

        //block price for Product #2
        SBQQ__BlockPrice__c prodBlockPrice = new SBQQ__BlockPrice__c(Name = 'Block price effect',
                                                                    SBQQ__LowerBound__c = 1,
                                                                    SBQQ__Price__c = 0,
                                                                    SBQQ__Product__c = testProduct2.Id);
                                                                    insert prodBlockPrice;
        
        
        testOpps.add(CPQ_TestDataFactory.createOpportunity(false,testAccount.Id));
        insert testOpps;

        testQuotes.add(new CPQ_TestDataFactory.CpqQuoteBuilder(testOpps[0]).withQuoteType('Partner').getRecord());
        insert testQuotes;

        SBQQ__QuoteLine__c testLine = new CPQ_TestDataFactory.QuoteLineBuilder(testQuotes[0],testProduct1).saveRecord();

        SBQQ__QuoteLine__c ql0 = new CPQ_TestDataFactory.QuoteLineBuilder(testQuotes[0],testProduct1)
                                                                            .withAssociatedProdId(testProduct1.ProductCode)
                                                                            .withNumber(5)
                                                                            .withUOM('GB')
                                                                            .withBillingFrequency('Monthly')
                                                                            .withChargeType('Commitment')
                                                                            .getRecord();
        ql0.SBQQ__RequiredBy__c = testLine.Id;
        quoteLines.add(ql0);
        
        SBQQ__QuoteLine__c ql1 = new CPQ_TestDataFactory.QuoteLineBuilder(testQuotes[0],testProduct2)
                                                                            .withProductOption(option2)
                                                                            .withAssociatedProdId(testProduct2.ProductCode)
                                                                            .withNumber(10)
                                                                            .withUOM('GB')
                                                                            .withBillingFrequency('Monthly')
                                                                            .withChargeType('Quantity based Commit')
                                                                            .withPricingMethod('Block')
                                                                            .withCustomName('Commitment')
                                                                            .getRecord();
        ql1.SBQQ__RequiredBy__c = testLine.Id;
        quoteLines.add(ql1);
                                                                            
        SBQQ__QuoteLine__c ql2 = new CPQ_TestDataFactory.QuoteLineBuilder(testQuotes[0],testProduct2)
                                                                            .withProductOption(option2)
                                                                            .withAssociatedProdId(testProduct2.ProductCode)
                                                                            .withNumber(20)
                                                                            .withUOM('Unit')
                                                                            .withBillingFrequency('Monthly')
                                                                            .withChargeType('Commitment + Overage')
                                                                            .getRecord();
        ql2.SBQQ__RequiredBy__c = testLine.Id;
        ql2.CPQ_Overage__c = CPQ_TestDataFactory.getindex();
        quoteLines.add(ql2);

        SBQQ__QuoteLine__c ql3 = new CPQ_TestDataFactory.QuoteLineBuilder(testQuotes[0],testProduct3)
                                                                            .withProductOption(option3)
                                                                            .withAssociatedProdId(testProduct3.ProductCode)
                                                                            .withNumber(30)
                                                                            .withUOM('Each')
                                                                            .withBillingFrequency('One-Time')
                                                                            .withChargeType('Flat Fee')
                                                                            .getRecord();
        ql3.SBQQ__RequiredBy__c = testLine.Id;
        quoteLines.add(ql3);

        // Usage based pricing
        SBQQ__QuoteLine__c ql4 = new CPQ_TestDataFactory.QuoteLineBuilder(testQuotes[0],testProduct1)
                                                                            .withAssociatedProdId(testProduct1.ProductCode)
                                                                            .withNumber(30)
                                                                            .withUOM('Each')
                                                                            .withBillingFrequency('Monthly')
                                                                            .withBillingModel('Usage Commitment')
                                                                            .withChargeType('Commitment + Overage')
                                                                            .getRecord();
        ql4.SBQQ__RequiredBy__c = testLine.Id;
        ql4.SBQQ__StartDate__c = System.today();
        ql4.SBQQ__EndDate__c = System.today() + 30;
        quoteLines.add(ql4);

        // Included
        SBQQ__QuoteLine__c ql5 = new CPQ_TestDataFactory.QuoteLineBuilder(testQuotes[0],testProduct3)
                                                                            .withProductOption(option3)
                                                                            .withAssociatedProdId(testProduct3.ProductCode)
                                                                            .withNumber(40)
                                                                            .withUOM('Mbps')
                                                                            .withBillingModel('Fee')
                                                                            .withChargeType('Included Units')
                                                                            .withCustomName('Included')
                                                                            .getRecord();
        ql5.SBQQ__RequiredBy__c = testLine.Id;
        ql5.SBQQ__Bundled__c = true;
        quoteLines.add(ql5);

        // SLC line
        SBQQ__QuoteLine__c ql6 = new CPQ_TestDataFactory.QuoteLineBuilder(testQuotes[0],testProduct1)
                                                                            .withAssociatedProdId(testProduct1.ProductCode)
                                                                            .withNumber(50)
                                                                            .withUOM('Each')
                                                                            .withBillingFrequency('Monthly')
                                                                            .withBillingModel('Straight Line Commitment')
                                                                            .withChargeType('Commitment + Overage')
                                                                            .getRecord();
        ql6.SBQQ__RequiredBy__c = testLine.Id;
        ql6.SBQQ__StartDate__c = System.today();
        ql6.SBQQ__EndDate__c = System.today() + 30;
        quoteLines.add(ql6);

        insert quoteLines;

    }

    // added on 04/08/2021 by shegade
    public static void testProductBundleBuilder(){

        List<Product2> products = new List<Product2>();
        List<SBQQ__ProductOption__c> options = new List<SBQQ__ProductOption__c>();
        
        PriceBook2 stdPriceBook = CPQ_TestDataFactory.createStandardPriceBook();

        Product2 testProduct1 = new CPQ_TestDataFactory.ProductBuilder('Test Product 1', 'Partner_Products').withCode('M-LC-162045').activate().getRecord();
        products.add(testProduct1);
        Product2 testProduct2 = new CPQ_TestDataFactory.ProductBuilder('Test Product 2', 'Partner_Products').activate().getRecord();
        products.add(testProduct2);
        Product2 testProduct3 = new CPQ_TestDataFactory.ProductBuilder('Test Product 3', 'Partner_Products')
                                                                        .withCode('M-LC-134473')
                                                                        .activate()
                                                                        .getRecord();
                                                                        products.add(testProduct3);

        insert products;                                                    


        new CPQ_TestDataFactory.PriceBookEntryBuilder(testProduct1.Id,stdPriceBook.Id).withCurrency('USD').withPrice(0.00).saveRecord();
        new CPQ_TestDataFactory.PriceBookEntryBuilder(testProduct2.Id,stdPriceBook.Id).withCurrency('USD').withPrice(0.00).saveRecord();
        new CPQ_TestDataFactory.PriceBookEntryBuilder(testProduct3.Id,stdPriceBook.Id).withCurrency('USD').withPrice(0.00).saveRecord();
        
        SBQQ__ProductFeature__c productFeature = new CPQ_TestDataFactory.ProductFeatureBuilder(testProduct1).saveRecord();

        SBQQ__ProductOption__c option1 = new CPQ_TestDataFactory.ProductOptionBuilder(testProduct1, testProduct2, productFeature)
                                            .withNumber(10)
                                            .getRecord();
                                            options.add(option1);

        SBQQ__ProductOption__c option2 = new CPQ_TestDataFactory.ProductOptionBuilder(testProduct1, testProduct2, productFeature)
                                            .withNumber(20)
                                            .getRecord();
                                            options.add(option2);

        SBQQ__ProductOption__c option3 = new CPQ_TestDataFactory.ProductOptionBuilder(testProduct1, testProduct3, productFeature)
                                            .withNumber(30)
                                            .getRecord();
                                            options.add(option3);

        insert options;

        //block price for Product #2
        SBQQ__BlockPrice__c prodBlockPrice = new SBQQ__BlockPrice__c(Name = 'Block price effect',
                                                                    SBQQ__LowerBound__c = 1,
                                                                    SBQQ__Price__c = 0,
                                                                    SBQQ__Product__c = testProduct2.Id);
                                                                    insert prodBlockPrice;
        
        SBQQ__ProductRule__c prodRule = new CPQ_TestDataFactory.ProductRuleBuilder('Integration Products Deselection').saveRecord();

        SBQQ__ConfigurationRule__c newRule = new SBQQ__ConfigurationRule__c(SBQQ__Product__c = testProduct1.Id,
                                                                            SBQQ__ProductRule__c = prodRule.Id);
        insert newRule;
    }
    public static void testProductBundleBuilderCarrier(){

        List<Product2> products = new List<Product2>();
        List<SBQQ__ProductOption__c> options = new List<SBQQ__ProductOption__c>();
        
        PriceBook2 stdPriceBook = CPQ_TestDataFactory.createStandardPriceBook();

        Product2 testProduct1 = new CPQ_TestDataFactory.ProductBuilder('Test Product 1', 'Carrier_Products').withCode('M-LC-162097').activate().getRecord();
        products.add(testProduct1);
        Product2 testProduct2 = new CPQ_TestDataFactory.ProductBuilder('Test Product 2', 'Carrier_Products').activate().getRecord();
        products.add(testProduct2);


        insert products;                                                    


        new CPQ_TestDataFactory.PriceBookEntryBuilder(testProduct1.Id,stdPriceBook.Id).withCurrency('USD').withPrice(0.00).saveRecord();
        new CPQ_TestDataFactory.PriceBookEntryBuilder(testProduct2.Id,stdPriceBook.Id).withCurrency('USD').withPrice(0.00).saveRecord();
        new CPQ_TestDataFactory.PriceBookEntryBuilder(testProduct2.Id,stdPriceBook.Id).withCurrency('AUD').withPrice(0.00).saveRecord();
        
        SBQQ__ProductFeature__c productFeature = new CPQ_TestDataFactory.ProductFeatureBuilder(testProduct1).saveRecord();

        SBQQ__ProductOption__c option1 = new CPQ_TestDataFactory.ProductOptionBuilder(testProduct1, testProduct2, productFeature)
                                            .withNumber(10)
                                            .getRecord();
                                            options.add(option1);

        SBQQ__ProductOption__c option2 = new CPQ_TestDataFactory.ProductOptionBuilder(testProduct1, testProduct2, productFeature)
                                            .withNumber(20)
                                            .getRecord();
                                            options.add(option2);

        

        insert options;

        
    }
}