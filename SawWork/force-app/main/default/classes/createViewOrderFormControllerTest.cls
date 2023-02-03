@isTest(seeAllData=false)
private class createViewOrderFormControllerTest {
	private static Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
	static User dmlUser = utilTestClass.getTestRunUser();

	@testSetup
    static void setupMethod() {
    	System.runAs(dmlUser) {
	    	ManagedPkgErrorClass.isFromManagedPackage = false;
	            
	        /* Start Of Custom Setting Insertion */
	        Test.loadData(globalDescribe.get('Communities_Settings__c'), 'CS_Communities_Settings');
	        //Test.loadData(globalDescribe.get('PRM_Settings__c'), 'CS_PRM_Settings');
	        Test.loadData(globalDescribe.get('Environment_Setup__c'), 'CS_Environment_Setup');
	        /* End Of Custom Setting Insertion */

	        String user_role = GsmUtilClass.getGSMSettingValue('User_Role');
	        List<User> userList = new List<User>();
	        User accOwnerUser = utilTestClass.CreateUser('newUser', user_role, 'Sales Operations');
	        userList.add(accOwnerUser);
	        User usrSysAdmin = utilTestClass.CreateUser('SysAdmin', 'Worldwide', 'System Administrator');
	        userList.add(usrSysAdmin);
	        insert userList; 

	        Account acc = new Account();
	        acc.Name = '__Test Account';
	        acc.OwnerId = accOwnerUser.Id;
	        acc.BillingCountry = 'India';
	        acc.BillingState = 'Delhi';
	        insert acc;

	        Map<String, Schema.RecordTypeInfo> rtMap = Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName();
	        Opportunity oppty1 = utilTestClass.CreateOpportunity('__Test Oppty1 Create View Order','1. Identify Need');
	        oppty1.AccountId = acc.Id;
	        oppty1.CloseDate = Date.today().addMonths(4);
	        oppty1.Partner_Forecast_Amount__c = 10;
	        oppty1.Deal_Type__c='Direct';
	        oppty1.stageName= '3. Verify Options';
	        oppty1.recordtypeId = rtMap.get('Akamai Opportunity').getRecordTypeId();
            oppty1.Validation_Override__c = true;
	        insert oppty1;
    	}
    }

    static testMethod void testCreateViewOrderForm() {
        System.runAs(dmlUser) {
            List<String> opptyNames = new List<String>();
            opptyNames.add('__Test Oppty1 Create View Order');
            Opportunity oppty = [select Id, StageName, RecordTypeId, AKAM_Opportunity_ID__c, Deal_Type__c
                                from Opportunity 
                                where Name in :opptyNames];
            Test.setCurrentPage(Page.createViewOrderForm);
            ApexPages.currentPage().getParameters().put('recordId',oppty.Id);
            ApexPages.currentPage().getParameters().put('recordTypeId',oppty.RecordTypeId);
            ApexPages.currentPage().getParameters().put('stageName',oppty.StageName);
            ApexPages.currentPage().getParameters().put('getField','Order_Form_Url__c');
            ApexPages.currentPage().getParameters().put('akamId',oppty.AKAM_Opportunity_ID__c);
            ApexPages.currentPage().getParameters().put('dealType',oppty.Deal_Type__c);
    		Order_Approval__c oa2 = new Order_Approval__c();
            oa2.Associated_Opportunity__c = oppty.Id;
            insert oa2;
            upsert oppty;
            createViewOrderFormController op = new createViewOrderFormController();
            PageReference pg;
            pg = op.redirectBuyAkamaiorMomentum();
            pg = op.createViewOrderForm();
            createViewOrderFormController.getBuyAkamaiOrderFormProducts();
            String momentumURL = createViewOrderFormController.getMomentumURL(oppty.Id,oppty.RecordTypeId,oppty.StageName,'Order_Form_Url__c');
            ApexPages.currentPage().getParameters().put('dealType',oppty.Deal_Type__c);
        }
    }
         	static testMethod void testCreateViewOrderFormFromCaseObject(){
            Opportunity oppty = [select Id, StageName, RecordTypeId, AKAM_Opportunity_ID__c, Deal_Type__c
                                from Opportunity 
                                where Name = '__Test Oppty1 Create View Order'];
            Order_Approval__c OA = [select id from Order_Approval__c where Associated_Opportunity__c =:oppty.Id limit 1];
            Test.setCurrentPage(Page.createViewOrderForm);
            ApexPages.currentPage().getParameters().put('recordId',oppty.Id);
            ApexPages.currentPage().getParameters().put('FromObject', 'Case');
            ApexPages.currentPage().getParameters().put('orderApprovalId',OA.Id);
            ApexPages.currentPage().getParameters().put('getField','Order_Form_Url__c');
            
            createViewOrderFormController op = new createViewOrderFormController();
            PageReference pg;
            pg = op.redirectBuyAkamaiorMomentum();
        }
    }