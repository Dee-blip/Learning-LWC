@isTest
private class L2Q_PAEOverrideControllerTest {
    static User dmlUser = new User(id=UserInfo.getUserId());
    @testSetUp static void insertCustomSettingsAndCreateData()
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            Map<String, String> objectToCustomSettingResource = new Map<String, String>{'Environment_Setup__c' => 'CS_Environment_Setup'};
                utilTestClass.insertCustomSettings(objectToCustomSettingResource);
            SObjectFactory.createPartnerUsers(1);
        }
    }
    
    @isTest static void testMethodFetchPMA() {
        // Implement test code
        Test.startTest();
        
        User partnerUser = SobjectRepository.getPartnerUser();
        System.assert(partnerUser.Contact.AccountId!=null, 'partner user doesnt have contact:'+partnerUser.Contact.AccountId);
        
        System.runAs(partnerUser)
        {
            SFDC_Channel_Account_Plan__c cap = (SFDC_Channel_Account_Plan__c)new SobjectBuilder(SFDC_Channel_Account_Plan__c.sObjectType)
                .eagerPopulate()
                .put(SFDC_Channel_Account_Plan__c.Partner_Account__c, partnerUser.Contact.AccountId)
                .create()
                .getRecord();
            
            Partner_Marketing_Plan__c pmp = (Partner_Marketing_Plan__c)new SobjectBuilder(Partner_Marketing_Plan__c.sObjectType)
                .eagerPopulate()
                .put(Partner_Marketing_Plan__c.Business_Plan__c, cap.Id)
                .create()
                .getRecord();
            
            Partner_Marketing_Activity__c pma = (Partner_Marketing_Activity__c)new SobjectBuilder(Partner_Marketing_Activity__c.sObjectType)
                .eagerPopulate()
                .put(Partner_Marketing_Activity__c.Partner_Marketing_Plan__c, pmp.Id)
                .create()
                .getRecord();
            PageReference pageRef = Page.L2Q_PAEOverridePage;
            Test.setCurrentPageReference(pageRef);
            ApexPages.currentPage().getParameters().put('pmaId',pma.Id);
            Partner_Marketing_Activity__c pmaRet = L2Q_PAEOverrideController.fetchPMA(pma.Id);
            List<String> fieldAPINames = new List<String>{'PAE_Forecast_DR__c','PAE_Forecast_Total_Contract_Value__c'};
                L2Q_PAEOverrideController.fieldAPINameToLabel(fieldAPINames);
            Test.stopTest();
        }
    }
    
    @isTest static void updateOpportunityTest() {
        Account acc = new Account();
        acc.Name = '__Test Account';
        acc.BillingCountry = 'India';
        acc.BillingState = 'Delhi';
        insert acc;
        Opportunity oppty = utilTestClass.CreateOpportunity('__Test Oppty','1. Identify Need');
        oppty.AccountId = acc.Id;
        oppty.CloseDate = Date.today().addMonths(4);
        insert oppty;
        Test.startTest();
        User partnerUser = SobjectRepository.getPartnerUser();
        Partner_Marketing_Activity__c pma = new Partner_Marketing_Activity__c();
        System.runAs(partnerUser)
        {
            SFDC_Channel_Account_Plan__c cap = (SFDC_Channel_Account_Plan__c)new SobjectBuilder(SFDC_Channel_Account_Plan__c.sObjectType)
                .eagerPopulate()
                .put(SFDC_Channel_Account_Plan__c.Partner_Account__c, partnerUser.Contact.AccountId)
                .create()
                .getRecord();
            
            Partner_Marketing_Plan__c pmp = (Partner_Marketing_Plan__c)new SobjectBuilder(Partner_Marketing_Plan__c.sObjectType)
                .eagerPopulate()
                .put(Partner_Marketing_Plan__c.Business_Plan__c, cap.Id)
                .create()
                .getRecord();
            
            pma = (Partner_Marketing_Activity__c)new SobjectBuilder(Partner_Marketing_Activity__c.sObjectType)
                .eagerPopulate()
                .put(Partner_Marketing_Activity__c.Partner_Marketing_Plan__c, pmp.Id)
                .create()
                .getRecord();
        }
        L2Q_PAEOverrideController.updateOpportunity(pma.Id,oppty.Id);
        L2Q_PAEOverrideController.getInitialValues();
        Test.stopTest();
    }
}