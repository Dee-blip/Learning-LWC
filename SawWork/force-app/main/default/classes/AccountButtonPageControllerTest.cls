@isTest(seeAllData=false)
public class AccountButtonPageControllerTest {
    
    public static User dmlUser = utilTestClass.getTestRunUser();

    private static Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();

    public static testmethod void TestAccountButtonPageController() {
        System.runAs(dmlUser) {

            Test.loadData(globalDescribe.get('Communities_Settings__c'), 'CS_Communities_Settings');
            Test.loadData(globalDescribe.get('Environment_Setup__c'), 'CS_Environment_Setup');
            
            GSM_Custom_Settings__c gs = new GSM_Custom_Settings__c();
            gs.Name = 'AccountTriggerClass#CheckCheckButton';
            gs.Value__c = '00eA0000000QkKm,00eA0000000VTG1';
            insert gs;
            
            String user_role = GsmUtilClass.getGSMSettingValue('User_Role');

            Account newAccount = new Account();
            PageReference pageRef;
            newAccount.Name = 'AccountworkFlowCreationPartnerBtn';
            newAccount.BillingCountry = 'India';
            newAccount.BillingState = 'Delhi';
            newAccount.Default_MDF_Currency__c ='USD';
            newAccount.CurrencyIsoCode ='USD';
            newAccount.IsPartnerCustom__c = true;
            insert newAccount;


            Account newAccount2 = new Account();
            PageReference pageRef2;
            newAccount2.Name = 'AccountworkFlowCreationPartnerBtn1';
            newAccount2.BillingCountry = 'India';
            newAccount2.BillingState = 'Delhi';
            newAccount2.Default_MDF_Currency__c ='USD';
            newAccount2.CurrencyIsoCode ='USD';
            newAccount2.IsPartnerCustom__c = false;
            insert newAccount2;

        	Test.setCurrentPage(Page.AccountButtonPage);	
            ApexPages.currentPage().getParameters().put('fromButton','UpdateCreditCheckStatus');
            ApexPages.currentPage().getParameters().put('function','UpdateCreditCheckStatus');
            ApexPages.currentPage().getParameters().put('recordId',newAccount.Id);
            ApexPages.currentPage().getParameters().put('accName',newAccount.Name);
            ApexPages.currentPage().getParameters().put('profileName','Akamai Partner Administrator');
            ApexPages.currentPage().getParameters().put('isPartnerCustom','1');
            AccountButtonPageController accPage = new AccountButtonPageController();
            pageRef = accPage.init();
            ApexPages.currentPage().getParameters().put('fromButton','DisableAsPartner');
            ApexPages.currentPage().getParameters().put('function','DisableAsPartner');
            pageRef = accPage.init();
            ApexPages.currentPage().getParameters().put('fromButton','EnableAsPartner');
            ApexPages.currentPage().getParameters().put('function','EnableAsPartner');
            pageRef = accPage.init();
            pageRef = accPage.disableAsPartner();
            pageRef = accPage.enableAsPartner();
            pageRef = accPage.backToAccount(); 
            ApexPages.currentPage().getParameters().put('fromButton','OutstandingInvoices');
            ApexPages.currentPage().getParameters().put('function','RedirectUrl');
            pageRef = accPage.init();


            Test.setCurrentPage(Page.AccountButtonPage);	
            ApexPages.currentPage().getParameters().put('recordId',newAccount2.Id);
            ApexPages.currentPage().getParameters().put('accName',newAccount2.Name);
            ApexPages.currentPage().getParameters().put('profileName','System Administrator');
            ApexPages.currentPage().getParameters().put('isPartnerCustom','0');
            AccountButtonPageController accPage2 = new AccountButtonPageController();
            pageRef2 = accPage2.init();
            ApexPages.currentPage().getParameters().put('fromButton','DisableAsPartner');
            ApexPages.currentPage().getParameters().put('function','DisableAsPartner');
            pageRef2 = accPage2.init();
            ApexPages.currentPage().getParameters().put('fromButton','EnableAsPartner');
            ApexPages.currentPage().getParameters().put('function','EnableAsPartner');
            pageRef2 = accPage2.init();
            pageRef2 = accPage2.disableAsPartner();
            pageRef2 = accPage2.init();
            pageRef2 = accPage2.enableAsPartner();
        }
    }

}