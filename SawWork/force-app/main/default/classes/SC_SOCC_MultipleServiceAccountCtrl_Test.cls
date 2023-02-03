/*
************************************************************************************************************
    Author              :   Tejaswini 
    Created             :   14-April-2021
    Purpose             :   Test Class for SC_SOCC_MultipleServiceAccountCtrl

	Date                 Developer                  JIRA #          Description                                                      
-----------------------------------------------------------------------------------------------------------
	14 Apr 2021          Tejaswini      			ESESP-4953		SOCC CAR 2 - RunBooks 2

************************************************************************************************************
*/
@isTest
public with sharing class SC_SOCC_MultipleServiceAccountCtrl_Test {
    
    @testSetup
    static void testDataSetup()
    {
        utilTestClass.createCustomSettings();

        // Create Account
        List<Account> lAcc =  new List<Account>();

        Account acc = utilTestClass.CreateAccount('TestServiceAccount 1');   
        lAcc.add(acc);

        Account acc2 = utilTestClass.CreateAccount('TestServiceAccount 2');   
        lAcc.add(acc2);

        Account acc3 = utilTestClass.CreateAccount('TestServiceAccount 3');   
        lAcc.add(acc3);
        
        insert lAcc;

        //Create Policy Domain

        Policy_Domain__c pd = new Policy_Domain__c();
        pd.Account_name__c = acc.Id;
        pd.Name = 'test PD';
        pd.Product__c  = 'PLX';
        pd.Policy_Domain_State__c = 'Active';
        insert pd;

        Service_Account_PD_Mapping__c serviceAccPdMap=new Service_Account_PD_Mapping__c();
        serviceAccPdMap.Policy_Domain__c=pd.Id;
        serviceAccPdMap.Service_Account__c=acc2.Id;
        
        insert serviceAccPdMap;
    }
    
    
    public static testMethod void accPdMappingTest()
    {

        Policy_Domain__c pd=[SELECT Id from Policy_Domain__c LIMIT 1];

        List<Id> lAccId=new List<Id>();
        List<Account> lAcc = new List<Account>();
        
        Account acc = utilTestClass.CreateAccount('TestServiceAccount 4');
        lAcc.add(acc);
        insert lAcc;

        lAccId.add(acc.id);

        Test.startTest();
        SC_SOCC_MultipleServiceAccountCtrl.getServiceAccounts(pd.id);
        SC_SOCC_MultipleServiceAccountCtrl.saveServiceAccountMappings(lAccId,pd.id);
        SC_SOCC_MultipleServiceAccountCtrl.deleteServiceAccountMappings(lAccId,pd.id);
        
        Test.stopTest();
    }

    public static testMethod void searchTest()
    {
        Account acc = [SELECT Id FROM Account where Name='TestServiceAccount 2' LIMIT 1];
        Policy_Domain__c pd=[SELECT Id from Policy_Domain__c LIMIT 1];
        
        List<String> accStrList = new List<String>();
        accStrList.add(String.valueOf(acc.id));
        SC_SOCC_MultipleServiceAccountCtrl.search('Test',accStrList,String.valueOf(pd.id));
        
        /*String ACCURL = URL.getSalesforceBaseUrl().toExternalForm() + '/lightning/r/Account/';
        List<SC_LookupSearchResult> results = new List<SC_LookupSearchResult>();
        results.add(
            new SC_LookupSearchResult(
                acc.Id,
                'Account',
                'standard:account',
                'acc1',
                ACCURL+acc.Id));
        results.add(
            new SC_LookupSearchResult(
                acc.Id,
                'Account',
                'standard:account',
                'acc2',
                ACCURL+acc.Id));

        results[0].getId();
        results[0].getSObjectType();
        results[0].getIcon();
        results[0].getTitle();
        results[0].getRecordUrl();
        results[1].compareTo(results[0]);*/
    }
}