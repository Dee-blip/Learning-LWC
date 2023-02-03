@isTest
public class MigrateOpptyPageControllerTestClass {

    // static{
    //    // utilTestClass.insertCustomSettings();
    //    GSM_Custom_Settings__c MAEProfileID = new GSM_Custom_Settings__c();
    //    MAEProfileID.Name = 'Forecast#MAEProfileID';
    //    MAEProfileID.Value__c = '00eA0000000dmONIAY,00eA0000000VTG1IAO,00eA0000000QkKxIAK,00e0f000000i4AOAAY,00e0f000000i4ATAAY,00e0f000000i4AdAAI,00e0f000000i4AYAAY,00eG0000000cNvDIAU,00eA0000000Qq4iIAC,00eA0000000QkL1IAK';
    //    insert MAEProfileID;
        
    //    GSM_Custom_Settings__c RSMProfileID = new GSM_Custom_Settings__c();
    //    RSMProfileID.Name = 'Forecast#RSMProfileID';
    //    RSMProfileID.Value__c = '00eA0000000ERErIAO,00eA0000000VTG1IAO,00e0f000000i4B7AAI,00e0f000000i4B2AAI,00eA0000000QkL2IAK,00e0f000000i491AAA';
    //    insert RSMProfileID;
        
    //    GSM_Custom_Settings__c RSMReportURL = new GSM_Custom_Settings__c();
    //    RSMReportURL.Name = 'Forecast#RSMReportURL';
    //    RSMReportURL.Value__c  = '/00OG0000004Azvf';
    //    insert RSMReportURL;
        
    //    GSM_Custom_Settings__c MAEReportURL = new GSM_Custom_Settings__c();
    //    MAEReportURL.Name = 'Forecast#MAEReportURL';
    //    MAEReportURL.Value__c  = '/00OG0000004Azug';
    //    insert MAEReportURL;
        
    //    GSM_Custom_Settings__c AkamaiForecastTabId = new GSM_Custom_Settings__c();
    //    AkamaiForecastTabId.Name = 'Forecast#AkamaiForecastTabId';
    //    AkamaiForecastTabId.Value__c  = '01rG0000000VGuv';
    //    insert AkamaiForecastTabId;
    // }
    
    // static testmethod void CustomForecastTabControllerTestMethod() {
    //     System.runAs(utilTestClass.getTestRunUser()) {
    //         CustomForecastTabController customForeastTabController = new CustomForecastTabController();
    //         customForeastTabController.pageRedirect();
    //     }
    //     User psUser= [Select Id from User where Profile.Name = 'Partner Support' and isActive=true limit 1];
    //     System.assertNotEquals(psUser,null);
    //     System.runAs(psUser){
    //         CustomForecastTabController customForeastTabController = new CustomForecastTabController();
    //         customForeastTabController.pageRedirect();
    //     }
        
    //      User maeUser= [Select Id from User where Profile.Name = 'Sales - Rep' and isActive=true limit 1];
    //      System.assertNotEquals(maeUser,null);
    //      System.runAs(maeUser){
    //         CustomForecastTabController customForeastTabController = new CustomForecastTabController();
    //         customForeastTabController.pageRedirect();
    //     }
    // }  SFDC- 7795  - codescan - Deleting CustomForecastTabController
    
    static testmethod void MigrateOpptyPageControllerTestClass() {
        Account account = utilTestClass.CreateAccount('Test_Account');
		account.BillingStreet = '#39,7th Cross';
		account.BillingCity	  = 'LA';
		account.BillingState = 'CA';
		account.BillingPostalCode = '56005';
		account.BillingCountry = 'USA';
        account.Type='Lead';
		insert account;
        
        Contact contact1 = utilTestClass.createcontact('Saket','More');
        contact1.AccountId = account.Id;
    	insert contact1;
        Contact contact2 = utilTestClass.createcontact('James','Bond');
        contact2.AccountId = account.Id;
        insert contact2;
        

		Opportunity oppty0 = utilTestClass.CreateOpportunity('Test_Opportunity', '0.5 AQL');
		oppty0.AccountId = account.Id;
        System.debug('zxxxxx:'+Schema.SObjectType.Opportunity.getRecordTypeInfosByName());
        System.debug('zxxxxxwwwwwww:'+Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('AWE Opportunities'));
        System.debug('zxxxxxwwwwwwwqqqqq:'+Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('AWE Opportunities').getRecordTypeId());
        oppty0.RecordTypeid = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('AWE Opportunities').getRecordTypeId();
		oppty0.CloseDate = System.today();
		insert oppty0;
        
        Opportunity oppty1 = utilTestClass.CreateOpportunity('Test_Opportunity', '0.5 AQL');
		oppty1.AccountId = account.Id;
        oppty1.RecordTypeid = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('AWE Opportunities').getRecordTypeId();
		oppty1.CloseDate = System.today();
		insert oppty1;
        
        OpportunityContactRole OCR1 = utilTestClass.createOpportunityContactRole(oppty0.Id, contact1.Id, 'Lead');
        OpportunityContactRole OCR2 = utilTestClass.createOpportunityContactRole(oppty1.Id, contact2.Id, 'Lead');
        Insert OCR1;
        Insert OCR2;
        
        Set<String> sourceOppty = new Set<String>();
        sourceOppty.add(oppty0.Id);
        
        PageReference pageRef = Page.migrateOpptyPage;
        Test.setCurrentPageReference(pageRef);
        pageRef.getParameters().put('recordId', oppty0.id);
        pageRef.getParameters().put('fromButton', 'Migrateoppty');
        pageRef.getParameters().put('recordName', oppty0.Name);
        pageRef.getParameters().put('SourceOppty', JSON.serialize(sourceOppty));
        
        MigrateOpptyPageController MOPC = new MigrateOpptyPageController();
        MOPC.targetOppty = oppty1.id;
        MOPC.init();
        MOPC.updateOppty();
        
        Opportunity OpptysWithContactRole = new Opportunity();
        OpptysWithContactRole = [Select id, name, StageName, Merged_Opportunity__c, QFA_Accept_Reject__c ,(Select id,opportunity.AKAM_Opportunity_ID__c,opportunity.name, opportunityid, contactid, contact.name, role from opportunitycontactroles) from opportunity where name ='Test_Opportunity' and RecordType.Name = 'AWE Opportunities' and Merged_Opportunity__c != NULL];
        
        System.assertEquals(OpptysWithContactRole.Merged_Opportunity__c, oppty1.id);
        
    }
    
    static testmethod void MigrateOpptyExistingOpportunityClass() {
        Account account = utilTestClass.CreateAccount('Test_Account');
		account.BillingStreet = '#39,7th Cross';
		account.BillingCity	  = 'LA';
		account.BillingState = 'CA';
		account.BillingPostalCode = '56052';
		account.BillingCountry = 'USA';
        account.Type='Lead';
		insert account;
        
        Contact contact1 = utilTestClass.createcontact('Saket','More');
        contact1.AccountId = account.Id;
    	insert contact1;
        Contact contact2 = utilTestClass.createcontact('James','Bond');
        contact2.AccountId = account.Id;
        insert contact2;
        

		Opportunity oppty0 = utilTestClass.CreateOpportunity('Test_Opportunity', '1-Create');
		oppty0.AccountId = account.Id;
        System.debug('zxxxxx:'+Schema.SObjectType.Opportunity.getRecordTypeInfosByName());
        System.debug('zxxxxxwwwwwww:'+Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('AWE Opportunities'));
        System.debug('zxxxxxwwwwwwwqqqqq new:'+Schema.SObjectType.Opportunity.getRecordTypeInfosByName());
        oppty0.RecordTypeid = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Akamai Opportunity').getRecordTypeId();
		oppty0.CloseDate = System.today();
		insert oppty0;
        
        Opportunity oppty1 = utilTestClass.CreateOpportunity('Test_Opportunity', '0.5 AQL');
		oppty1.AccountId = account.Id;
        oppty1.RecordTypeid = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('AWE Opportunities').getRecordTypeId();
		oppty1.CloseDate = System.today();
		insert oppty1;
        
        Opportunity oppty2 = utilTestClass.CreateOpportunity('Test_Opportunity', '0.5 AQL');
		oppty2.AccountId = account.Id;
        oppty2.RecordTypeid = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('AWE Opportunities').getRecordTypeId();
		oppty2.CloseDate = System.today();
		insert oppty2;
        
        OpportunityContactRole OCR2 = utilTestClass.createOpportunityContactRole(oppty2.Id, contact2.Id, 'Lead');
        OpportunityContactRole OCR1 = utilTestClass.createOpportunityContactRole(oppty1.Id, contact1.Id, 'Lead');
        Insert OCR2;
        Insert OCR1;
        
        Set<String> sourceOppty = new Set<String>();
        sourceOppty.add(oppty1.Id);
        sourceOppty.add(oppty2.Id);
        
        PageReference pageRef = Page.migrateOpptyPage;
        Test.setCurrentPageReference(pageRef);
        pageRef.getParameters().put('recordId', oppty0.id);
        pageRef.getParameters().put('fromButton', 'MigrateOpptyExisting');
        pageRef.getParameters().put('recordName', oppty0.Name);
        pageRef.getParameters().put('SourceOppty', JSON.serialize(sourceOppty));
        
        MigrateOpptyPageController MOPC = new MigrateOpptyPageController();
        MOPC.targetOppty = oppty0.id;
        MOPC.init();
        MOPC.updateOppty();
        
     }
}