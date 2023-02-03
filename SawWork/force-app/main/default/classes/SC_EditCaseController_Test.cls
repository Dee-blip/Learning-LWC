/*---------------------------------------------------------------------------------
 * Test Class Name      : SC_EditCaseController_Test class
 * Developer Name       : Vandhana
 * Date                 : 12th September,2017
 * Test for class       : SC_EditCaseController
 ---------------------------------------------------------------------------------*/ 

@isTest(seeAllData = false)
public class SC_EditCaseController_Test 
{

    @testSetup static void setupTestData()
    {
        utilTestClass.createCustomSettings();  
        SC_PSEditCaseProfileId__c psCS = new SC_PSEditCaseProfileId__c();
        psCS.Name = 'LunaPortalIntegration';
//        psCS.ProfileId__c = '00eG0000000f0ZFIAY';
        psCS.ProfileId__c = 'Test1234 ';
        insert psCS;
    }
    
    public static testMethod void newPSCaseTest()
    {
        User adminUser = utilTestClass.CreateUser('TstUsr2', 'Worldwide', 'System Administrator');
        List<Account> lstAcc = new List<Account>();
        Account account1 = new Account(Name = 'Account1', Support_Level__c = 'Premium',AKAM_Account_ID__c='Test-111-ABC-XYZ',Auto_Escalate_Sev_1_Technical_Cases__c = true);
        lstAcc.add(account1);
        Account account2 = new Account(Name = 'Account2', Support_Level__c = 'Standard',AKAM_Account_ID__c='Test-222-ABC-XYZ');
        lstAcc.add(account2);
        insert lstAcc;
        Contact con = utilTestClass.CreateContact('FName','LName');
        con.AccountId = account1.Id;
        insert con;
        
        User psUser = [SELECT Id FROM User WHERE Isactive = TRUE AND Profile.Name = 'GSS Professional Services' LIMIT 1];
        
        Id psRTId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();
        
        Test.startTest();
        System.runAs(psUser)
        {
            Case newCase = new Case(RecordTypeId = psRTId,AccountId=account1.Id,Service__c = 'Emergency Integration',Request_Type__c = 'N/A', Close_Code__c = 'N/A');
            newCase.ContactId = con.Id;
            insert newCase;
            Case newCase2 = new Case(RecordTypeId = psRTId,AccountId=account1.Id,Service__c = 'Emergency Integration',Request_Type__c = 'N/A', Close_Code__c = 'N/A');
            insert newCase2;
            newCase2.Status = 'Closed';
            newCase2.Validation_Override__c = true;
            update newCase2;
            
            newCase.Service__c = 'Emergency Integration';
            PageReference scEditCasePage = Page.SC_EditCase;
	        Test.setCurrentPage(scEditCasePage);
            System.currentPageReference().getParameters().put('RecordType',psRTId);
            ApexPages.StandardController scEC = new ApexPages.StandardController(newCase);
            SC_EditCaseController ecCtrlr = new SC_EditCaseController(scEC);
            
            System.currentPageReference().getParameters().put('id', newCase.Id);
            System.currentPageReference().getParameters().put('RecordType',psRTId);
            scEC = new ApexPages.StandardController(newCase);
            ecCtrlr = new SC_EditCaseController(scEC);
            Component.Apex.outputpanel op;
            
            //op = ecCtrlr.getDynamicForm();
            List<SelectOption> lstSO = ecCtrlr.getStatuss();
            lstSO = ecCtrlr.getServices();
			newCase.Request_Type__c = newCase.Close_Code__c = 'N/A';
            
            op = ecCtrlr.getDynamicForm();
            scEditCasePage = ecCtrlr.Save();
            scEditCasePage = ecCtrlr.editCaseRedirect();
            scEditCasePage = ecCtrlr.CloseRedirect();
            scEditCasePage = ecCtrlr.Redirect();
            scEditCasePage = ecCtrlr.viewRedirect();
            scEditCasePage = ecCtrlr.reopenCase();
            //ecCtrlr.resetModal();
           	op = ecCtrlr.getViewDynamicForm();
            
            System.debug('CLOSE CASE STATUS : ' + newCase2.IsClosed);
            //Test.setCurrentPage(scEditCasePage);
            System.currentPageReference().getParameters().put('id', newCase2.Id);
            scEC = new ApexPages.StandardController(newCase2);
            ecCtrlr = new SC_EditCaseController(scEC);
            scEditCasePage = ecCtrlr.reopenCase();
        }
        Test.stopTest();
    }
    
    
    @IsTest
    static void test_getCaseProducts(){
        Id psRTId = Case.SObjectType.getDescribe().getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();
        Account account2 = new Account(Name = 'Account2', Support_Level__c = 'Standard',AKAM_Account_ID__c='Test-222-ABC-XYZ');
        insert account2;
        Contact con = utilTestClass.CreateContact('FName','LName');
        con.AccountId = account2.Id;
        insert con;
        List<EB_AccountProductMap__c> products = new List<EB_AccountProductMap__c>();
        String product1 = 'Test Product 1';
        String product2 = 'Test Product 2';
        products.add(new EB_AccountProductMap__c(Name=product1,EB_Product__c = product1, EB_Account__c=account2.Id));
        products.add(new EB_AccountProductMap__c(Name=product2,EB_Product__c = product2, EB_Account__c=account2.Id));
        insert products;
        Case newCase = new Case(RecordTypeId = psRTId,AccountId=account2.Id,Service__c = 'Emergency Integration',Request_Type__c = 'N/A', Close_Code__c = 'N/A');
        newCase.ContactId = con.Id;
        insert newCase;
        Test.startTest();
        System.currentPageReference().getParameters().put('id', newCase.Id);
        System.currentPageReference().getParameters().put('RecordType',psRTId);
        ApexPages.StandardController scEC = new ApexPages.StandardController(newCase);
        SC_EditCaseController controller = new SC_EditCaseController(scEC);
        List<SelectOption> productOptions = controller.getCaseProducts();
        Test.stopTest();
        System.assert(productOptions.size() > 0, 'No product options found');
        Set<String> productNames = new Set<String>();
        for (SelectOption option : productOptions){
            productNames.add(option.getLabel());
        }
        System.assert(productNames.contains(product1),'Product Not found: '+product1);
        System.assert(productNames.contains(product2),'Product Not found: '+product2);
    }
    
}