@isTest(seeAllData=false)
public with sharing class SF1_EMRIOpportunityTest {

        static testmethod void executeRefreshBaselineSF1() {
                Account acc = new Account();
                acc.Name = 'TestABC';
                acc.Vertical__c = 'Gaming';
                acc.Sub_Vertical__c = 'Console Mfs';
                insert acc;

                Opportunity opp = new Opportunity();
                opp.Account = acc;
                opp.AccountId = acc.Id;
                opp.Name = 'OppName';
                opp.Deal_Type__c = 'Direct';
                opp.StageName = '1. Identify Need';
                opp.CloseDate = Date.today();
                opp.CurrencyIsoCode = 'BRL';
                insert opp;

                String returnVal = SF1_EMRIOpportunity.executeRefreshBaselineSF1(String.valueOf(opp.Id));
        }

        static testmethod void refreshBaselineSF1() {
                Account testAccount = utilTestClass.CreateAccount('Test Account');
                insert testAccount;

                Merge_Contract_Header__c testMCH = utilTestClass.CreateContractHeader('1-3F23H',testAccount.Id);
                testMCH.Currency__c = 'USD';
                insert testMCH;

                Opportunity testOppty = utilTestClass.CreateOpportunity('Test Oppty','1. Identify Need');
                testOppty.AccountId = testAccount.Id;
                testOppty.CloseDate = Date.today();
                testOppty.CurrencyISOCode = 'USD';
                testOppty.Renew_Contract_Id_Text__c = '1-3F23H';
                insert testOppty;

                Renewal_Contract_Object__c renewalContract    = new Renewal_Contract_Object__c();
                renewalContract.Name              = testMCH.Original_Contract_Id__c;
                renewalContract.Contract__c           = testMCH.Id;
                renewalContract.Opportunity__c                = testOppty.Id;
                renewalContract.Contract_Id_Text__c       = testMCH.Original_Contract_Id__c;
                insert renewalContract;

                String returnVal = SF1_EMRIOpportunity.executeRefreshBaselineSF1(String.valueOf(testOppty.Id));
                returnVal = SF1_EMRIOpportunity.refreshBaselineSF1(String.valueOf(testOppty.Renew_Contract_Id_Text__c), String.valueOf(testOppty.Id));
        }

        static testmethod void isDissociableSF1() {
                // Account acc = new Account();
                // acc.Name = 'TestABC';
                // acc.Vertical__c = 'Gaming';
                // acc.Sub_Vertical__c = 'Console Mfs';
                // insert acc;
                //
                // Opportunity opp = new Opportunity();
                // opp.Account = acc;
                // opp.AccountId = acc.Id;
                // opp.Name = 'OppName';
                // opp.Deal_Type__c = 'Direct';
                // opp.StageName = '0-Plan';
                // opp.CloseDate = Date.today();
                // opp.CurrencyIsoCode = 'BRL';
                // insert opp;
                //
                // String returnVal = SF1_EMRIOpportunity.isDissociableSF1(String.valueOf(opp.Id));

                Account account = utilTestClass.CreateAccount('Test_Account');
                account.BillingStreet = '#39,7th Cross';
                account.BillingCity   = 'LA';
                account.BillingState = 'CA';
                account.BillingPostalCode = '99999';
                account.BillingCountry = 'USA';
                account.Type='Lead';
                account.CurrencyISOCode='INR';
                insert account;

                Merge_Contract_Header__c renewalContract1 = new Merge_Contract_Header__c();
                renewalContract1.Original_Contract_Id__c = 'C-YJSEX11';
                renewalContract1.Name = 'C-YJSEX11';
                Integer numDays = 30;                 //Integer.valueOf(GSM_Custom_Settings__c.getInstance('Contract_HierarchyEndDateDays').Value__c)+2;
                renewalContract1.Effective_End_Date__c = Date.today().addDays(-Integer.valueOf(numDays));
                renewalContract1.Account_Name__c = account.Id;
                renewalContract1.Active__c= true;
                renewalContract1.Currency__c = 'USD';
                insert renewalContract1;

                Contract_Product__c contractProduct1 = utilTestClass.CreateContractProduct(renewalContract1.Original_Contract_Id__c,'PROD-123','AKAM-123');
                contractProduct1.Average_Renewal_Commit_MRR__c = 200;
                contractProduct1.Average_Renewal_Usage_MRR__c = 200;
                contractProduct1.UnitPrice__c = 1;
                contractProduct1.Original_Contract_id__c = renewalContract1.Id;
                contractProduct1.Forecast_Product_Id__c = 'Prod-12';
                insert contractProduct1;


                Pricebook2 pb = new Pricebook2();
                pb.name = 'Standard Price Book 2009';
                pb.Description = 'Price Book 2009 Products';
                pb.isactive = true;

                insert pb;

                Id pbId = Test.getStandardPricebookId();



                Product2 p = new Product2();
                p.Name     = 'TEST';
                p.Akam_Product_Id__c = contractProduct1.Forecast_Product_Id__c;

                Database.insert(p);


                /* Create a pricebook entry. */
                PricebookEntry pbe = new PricebookEntry();
                pbe.Pricebook2Id = pbId;
                pbe.Product2Id   = p.id;
                pbe.IsActive     = true;
                pbe.UnitPrice    = 1;
                pbe.CurrencyIsoCode = 'INR';
                pbe.UseStandardPrice = false;

                // pbe.product2.Akam_Product_Id__c = contractProduct1.Forecast_Product_Id__c;

                Test.startTest();
                Database.insert(pbe);

                List<opportunity> opp = new List<opportunity>();

                Opportunity oppty0 = utilTestClass.CreateOpportunity('Test_Opportunity', '1. Identify Need');
                oppty0.AccountId   = account.Id;
                oppty0.CurrencyIsoCode = 'INR';
                oppty0.CloseDate   = System.today();
                oppty0.Renew_Contract_Id_Text__c = 'C-YJSEX11,C-YJSEX10';
                insert oppty0;

                opp.add(oppty0);

                OpportunityLineItem oli = new OpportunityLineItem();
                oli.OpportunityId = oppty0.Id;
                oli.UnitPrice = contractProduct1.UnitPrice__c;
                oli.Quantity = 1;
                oli.Average_Renewal_Commit_MRR__c = contractProduct1.Average_Renewal_Commit_MRR__c;
                oli.Average_Renewal_Usage_MRR__c = contractProduct1.Average_Renewal_Usage_MRR__c;
                oli.pricebookEntryId = pbe.id;
                oli.Validation_Override__c = true;
                insert oli;


                //Opportunity with no contract associated
                Opportunity oppty1 = utilTestClass.CreateOpportunity('Test_Opportunity1', '1. Identify Need');
                oppty1.AccountId   = account.Id;
                oppty1.CurrencyIsoCode = 'INR';
                oppty1.CloseDate = System.today();
                insert oppty1;

                opp.add(oppty1);

                Renewal_Contract_Object__c RC = new Renewal_Contract_Object__c ();
                RC.Contract__c = renewalContract1.id;
                RC.Opportunity__c = oppty0.id;
                insert RC;

                for(opportunity opptyy : opp) {
                        String returnVal = SF1_EMRIOpportunity.isDissociableSF1(String.valueOf(opptyy.Id));
                }
        }

        static testmethod void disassociateContractSF1() {
                Account account = utilTestClass.CreateAccount('Test_Account');
                account.BillingStreet = '#39,7th Cross';
                account.BillingCity   = 'LA';
                account.BillingState = 'CA';
                account.BillingPostalCode = '99999';
                account.BillingCountry = 'USA';
                account.Type='Lead';
                account.CurrencyISOCode='INR';
                insert account;

                Merge_Contract_Header__c renewalContract1 = new Merge_Contract_Header__c();
                renewalContract1.Original_Contract_Id__c = 'C-YJSEX11';
                renewalContract1.Name = 'C-YJSEX11';
                Integer numDays = 30;                 //Integer.valueOf(GSM_Custom_Settings__c.getInstance('Contract_HierarchyEndDateDays').Value__c)+2;
                renewalContract1.Effective_End_Date__c = Date.today().addDays(-Integer.valueOf(numDays));
                renewalContract1.Account_Name__c = account.Id;
                renewalContract1.Active__c= true;
                renewalContract1.Currency__c = 'USD';
                insert renewalContract1;
                List<Merge_Contract_Header__c> li = new List<Merge_Contract_Header__c>();
                for(Merge_Contract_Header__c mch : [select Original_Contract_Id__c,Currency__c from Merge_Contract_Header__c where id =: renewalContract1.id])
                li.add(mch);
                

                Contract_Product__c contractProduct1 = utilTestClass.CreateContractProduct(renewalContract1.Original_Contract_Id__c,'PROD-123','AKAM-123');
                contractProduct1.Average_Renewal_Commit_MRR__c = 200;
                contractProduct1.Average_Renewal_Usage_MRR__c = 200;
                contractProduct1.UnitPrice__c = 1;
                contractProduct1.Original_Contract_id__c = renewalContract1.Id;
                contractProduct1.Forecast_Product_Id__c = 'Prod-12';
                insert contractProduct1;


                Pricebook2 pb = new Pricebook2();
                pb.name = 'Standard Price Book 2009';
                pb.Description = 'Price Book 2009 Products';
                pb.isactive = true;

                insert pb;

                Id pbId = Test.getStandardPricebookId();



                Product2 p = new Product2();
                p.Name     = 'TEST';
                p.Akam_Product_Id__c = contractProduct1.Forecast_Product_Id__c;

                Database.insert(p);


                /* Create a pricebook entry. */
                PricebookEntry pbe = new PricebookEntry();
                pbe.Pricebook2Id = pbId;
                pbe.Product2Id   = p.id;
                pbe.IsActive     = true;
                pbe.UnitPrice    = 1;
                pbe.CurrencyIsoCode = 'INR';
                pbe.UseStandardPrice = false;

                // pbe.product2.Akam_Product_Id__c = contractProduct1.Forecast_Product_Id__c;

                Test.startTest();
                Database.insert(pbe);

                List<opportunity> opp = new List<opportunity>();

                Opportunity oppty0 = utilTestClass.CreateOpportunity('Test_Opportunity', '1. Identify Need');
                oppty0.AccountId   = account.Id;
                oppty0.CurrencyIsoCode = 'INR';
                oppty0.CloseDate   = System.today();
                oppty0.Renew_Contract_Id_Text__c = 'C-YJSEX11,C-YJSEX10';
                insert oppty0;

                opp.add(oppty0);

                OpportunityLineItem oli = new OpportunityLineItem();
                oli.OpportunityId = oppty0.Id;
                oli.UnitPrice = contractProduct1.UnitPrice__c;
                oli.Quantity = 1;
                oli.Average_Renewal_Commit_MRR__c = contractProduct1.Average_Renewal_Commit_MRR__c;
                oli.Average_Renewal_Usage_MRR__c = contractProduct1.Average_Renewal_Usage_MRR__c;
                oli.pricebookEntryId = pbe.id;
                oli.Validation_Override__c = true;
                insert oli;


                //Opportunity with no contract associated
                Opportunity oppty1 = utilTestClass.CreateOpportunity('Test_Opportunity1', '1. Identify Need');
                oppty1.AccountId   = account.Id;
                oppty1.CurrencyIsoCode = 'INR';
                oppty1.CloseDate = System.today();
                insert oppty1;

                opp.add(oppty1);

                Renewal_Contract_Object__c RC = new Renewal_Contract_Object__c ();
                RC.Contract__c = renewalContract1.id;
                RC.Opportunity__c = oppty0.id;
                insert RC;
                SF1_EMRIOpportunity.getAssociatedContracts(oppty0.id);
                SF1_EMRIOpportunity.disassociateContracts(oppty0.id,li);
                

                Test.stopTest();

        }
}