@isTest(seeAllData=false)
private class SalesApprovedCountryTestClass
{
    static
    {
        utilTestClass.insertCustomSettings();
    }

    //tests accountrigger
    static testmethod void testRestrictedCountryOnAccount()
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            ManagedPkgErrorClass.isFromManagedPackage=false;
            List<Sales_Approved_Country__c> sacList = new List<Sales_Approved_Country__c>();
            Sales_Approved_Country__c tempSAC = new Sales_Approved_Country__c(Name='India', Is_Direct_Allowed__c=false, Is_Reselling_Allowed__c=false, Region__c='APJ', Sub_Region__c='South East Asia', ISO_Country__c='India');
            sacList.add(tempSAC);
            tempSAC = new Sales_Approved_Country__c(Name='USA', Is_Direct_Allowed__c=true, Is_Reselling_Allowed__c=true, Region__c='Americas', Sub_Region__c='Americas', ISO_Country__c='United States of America');
            sacList.add(tempSAC);

            insert sacList;

            List<Account> accountList = new List<Account>();
            Integer numberOfTestAccounts = 100;
            for(Integer i=0;i<numberOfTestAccounts;i++)
            {
                Account acc = utilTestClass.CreateAccount('__tes'+i);
                acc.Website = 'www.Testi'+i+'.com';
                acc.BillingPostalcode ='78654';
                // Kejri's odd even rule
                acc.BillingCountry = (Math.mod(i, 2)==0)? 'USA': 'India';
                accountList.add(acc);
            }
            Test.startTest();
            insert accountList;

            accountList = [select id, Is_Restricted_Country__c, BillingCountry from Account where Id in :accountList];

            for(Account acc : accountList)
            {
                if(acc.BillingCountry=='USA')
                {
                    System.assertEquals(acc.Is_Restricted_Country__c, false);
                }
                else
                {
                    System.assertEquals(acc.Is_Restricted_Country__c,true);
                }
            }
            //Update countries of all accounts to USA
            for(Account acc : accountList)
            {
                acc.BillingCountry= 'USA';
                acc.Validation_Override__c=true;
            }

            SalesApprovedCountryClass.updateRestrictedCountryOnAccountsFirstRunFlag=true;

            update accountList;

            //Refresh and check again

            accountList = [select id, Is_Restricted_Country__c, BillingCountry from Account where Id in :accountList];

            for(Account acc : accountList)
            {
                System.assert(acc.BillingCountry=='USA','country is '+acc.BillingCountry);
                System.assertEquals(acc.Is_Restricted_Country__c, false);
            }

            // Make USA a restricted country. BAM!

            tempSAC.Is_Direct_Allowed__c = false;
            tempSAC.Is_Reselling_Allowed__c = false;

            update tempSAC;

            SalesApprovedCountryBatchClass sacbc= new SalesApprovedCountryBatchClass();
            Database.executebatch(sacbc);
            Test.stopTest();

            accountList = [select id, Is_Restricted_Country__c, BillingCountry from Account where Id in :accountList];

            for(Account acc : accountList)
            {
                    System.assertEquals(acc.Is_Restricted_Country__c,true);
            }

        }
    }

    static testmethod void testOpportunityWarnings()
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            ManagedPkgErrorClass.isFromManagedPackage=false;
            Links__c l = new Links__c(Name='IALTApproval', value__c='akamai.com');
            insert l;

            Error_Page_Settings__c eps = new Error_Page_Settings__c(name='OpptyInsufficientPrivileges', value__c='You dont have access');

            insert eps;
            
            List<Sales_Approved_Country__c> sacList = new List<Sales_Approved_Country__c>();
            Sales_Approved_Country__c tempSAC = new Sales_Approved_Country__c(Name='India', Is_Direct_Allowed__c=false, Is_Reselling_Allowed__c=false, Region__c='APJ', Sub_Region__c='South East Asia', ISO_Country__c='India');
            sacList.add(tempSAC);
            tempSAC = new Sales_Approved_Country__c(Name='USA', Is_Direct_Allowed__c=true, Is_Reselling_Allowed__c=true, Region__c='Americas', Sub_Region__c='Americas', ISO_Country__c='United States of America');
            sacList.add(tempSAC);

            insert sacList;
            User accOwnerUser = utilTestClass.CreateUser('newU__', 'Worldwide', 'Sales Operations');
            insert accOwnerUser;
            System.assertNotEquals(accOwnerUser.Id, null);
            Opportunity o;

            Account a = utilTestClass.CreateAccount('__ TEST');
            a.BillingCountry = 'India';
            a.OwnerId = accOwnerUser.Id;
            a.PO_Required__c = 'Yes';
            Test.startTest();
            insert a;
            OpportunityStage stage = [select MasterLabel from OpportunityStage limit 1];
            o = utilTestClass.CreateOpportunity('__ TEST',stage.MasterLabel);
            o.AccountId = a.id;
            o.CurrencyIsoCode = 'INR';  
            o.name = 'test__a';
            o.StageName='1. Identify Need';
            o.deal_type__c = 'Direct';
            o.CloseDate    = Date.today() + 365;
            insert o;

            /*System.runAs(accOwnerUser)
            {
                ApexPages.StandardController sc = new ApexPages.StandardController(o);

                OpportunityWarningsExtensionController owe = new OpportunityWarningsExtensionController(sc);

                owe.fieldName = 'IALT_Received__c';
                owe.markFieldAsChecked();


            }*/
            ApexPages.StandardController sc = new ApexPages.StandardController(o);
            OpportunityWarningsExtensionController owe = new OpportunityWarningsExtensionController(sc);

            a.eCustoms_Legal_Approved__c = false;
            a.RPS_Status__c = 'Red';
            update a;
            
            PageReference pageRef = Page.OpportunityWarningsInit;
            Test.setCurrentPageReference(pageRef);
            pageRef.getParameters().put('opptyId', o.id);
            
            System.runAs(accOwnerUser){
                OpportunityWarningsExtensionController owe1 = new OpportunityWarningsExtensionController(sc);
                owe.fieldName = 'IALT_Received__c';
                owe.markFieldAsChecked();
            }
            Test.stopTest();
        }
    }
}