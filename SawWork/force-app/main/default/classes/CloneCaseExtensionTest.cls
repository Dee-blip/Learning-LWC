/*=====================================================================================================+
    Class name          :   CloneCaseExtensionTest 
    Author              :   Himanshu Kar
    Created             :   05-AUG-14
    Purpose             :   This test class is used to cover code for below Components
                            1. CloneCaseExtension
                            
    Last Modified Developer  Purpose            
    ============= =========  =======
    13-JUL-13     Appirio    Initial Development 	
    05-AUG-14     Himanshu   Removed SeeAllData and Optimized the Class
    
+=====================================================================================================*/
 
@isTest
private class CloneCaseExtensionTest 
{  
    // Create Case 
    public static Case caseObj;
    public static String accId;
    
    // Create Account
    public static List<Account> accList;
    
    // Method for Creating Test Data
    public static void testDataSetup()
    {        
        utilTestClass.createCustomSettings();
        accId = '';
        
        List<Account> lstAcc = new List<Account>();
        Account acc = new Account();
        acc.Name = 'MainAccount';
        acc.Type = 'Agency - Active';
        acc.BillingCountry = 'India';
        acc.BillingState = 'DELHI';
        lstAcc.add(acc);
        
        acc = new Account();
        acc.Name = 'SubAccount';
        acc.Type = 'Agency - Active';
        acc.BillingCountry = 'India';
        acc.BillingState = 'DELHI';
        lstAcc.add(acc);
        insert lstAcc;
        
        // Creating Case
        caseObj = new Case();
        caseObj.Description = 'testAMG';
        caseObj.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('AMG').getRecordTypeId();
        caseObj.AccountId = acc.Id;
        caseObj.Subject = 'testAMG';
        caseObj.Service__c = 'Alerts';
        caseObj.Request_Type__c = 'Add Alerts';
        caseObj.Severity__c = '3';
        caseObj.Origin = 'Phone';
        caseObj.Validation_Override__c = true;
        insert caseObj;
        System.debug('ID : ' + caseObj.Id);
    }
    
    static testMethod void myUnitTest() 
    {  
        // Calling dataSetup Method
        testDataSetup();
        Case c = [SELECT Id,AccountId from Case where Subject = 'testAMG' limit 1];
        
        accId = [SELECT Id from Account where Name = 'SubAccount' limit 1].Id;
        
        PageReference pageRef = new PageReference('/apex/CloneCase?id='+ c.Id);
        Test.setCurrentPage(pageRef);
        
        Apexpages.Standardcontroller std = new Apexpages.Standardcontroller(c);
        ApexPages.currentPage().getParameters().put('aname','Account');
        CloneCaseExtension con = new CloneCaseExtension();
        con = new CloneCaseExtension(std);
        
        con.searchKey = 'SubAccount';
        con.SearchAccounts();
        con.selectedAccounts = con.searchResults;
        
        con.CloneCaseForAccounts();
        
        List<Case> caseList = [select Id,AccountId from Case where RecordType.Name = 'AMG'];
        
        system.assert(caseList.size() > 0);
        con.search();
        
        pageRef = new PageReference('/apex/CustomLookUpForCloneCasePage?lksrch=' + 'Account');
        Test.setCurrentPage(pageRef);
        con.searchKey = 'Account';
        con.CopyToSelectedAccounts();
        con.getResultsname();
        
        boolean flag = con.getHasparams();
        flag = con.getHasnoresults();
        con.avoidRefresh();
        
        caseObj = new Case();
        std = new Apexpages.Standardcontroller(c);
        con = new CloneCaseExtension(std);
        ApexPages.currentPage().getParameters().put('aname','Account');
        ApexPages.currentPage().getParameters().put('lksrch','Account');
        con.cloneSingleCase();
        con.tempCon = new Case();
        con.tempCon.AccountId = accId;
        con.accountName = 'SubAccount';
        
        con.searchKey = 'Account';
        con.DoSort();
        con.searchSuggestions();
        //con.selectedAccounts = null;
        con.CopyToSelectedAccounts1();
        con.CloneCaseForAccounts();
    }
    
}