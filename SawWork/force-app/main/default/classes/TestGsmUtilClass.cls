@isTest(seeAllData=false)
private class TestGsmUtilClass{
    
    static User dmlUser = new User(id=UserInfo.getUserId());
    private static Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
    
    // Setup method to create test data.
    @testSetup
    static void setupMethod(){
        System.runAs(dmlUser) {
            Test.loadData(globalDescribe.get('GSM_Custom_Settings__c'), 'CS_GSM_Custom_Settings');
            Test.loadData(globalDescribe.get('PRM_Settings__c'), 'CS_PRM_Settings');
            Test.loadData(globalDescribe.get('Features_Toggle__c'), 'CS_Features_Toggle');
            Test.loadData(globalDescribe.get('MDF_Configurations__c'), 'CS_MDF_Configurations');
            
            Account a1 = utilTestClass.createAccount('Account 1');
            insert a1;
        }
    }
    
    static testmethod void testTrimAndSendMails()
    {
        System.runAs(dmlUser)
        {
            GsmUtilClass.trimName('Long Ass string with more than 90 characters. Lorem Ipsum Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the indu');
            GsmUtilClass.createSingleEmail(dmlUser.Id,dmlUser.Id,'',GsmUtilClass.getPRMSettingValue('Partner_Admin_2nd_email_template_Id'),GsmUtilClass.getPRMSettingValue('Partner_Portal_Email_Id'));
            GsmUtilClass.createSingleEmail('eae-ops@akamai.com','l2q-dev@akamai.com','Sample subject','some text','some more');
            String orgId = UserInfo.getOrganizationId();
            GsmUtilClass.createSingleEmailWithOrgId('eae-ops@akamai.com','l2q-dev@akamai.com','Sample subject','some text','some text',orgId);
        }
        
    }
    
    static testmethod void testSalesStageSixValidation() {
        System.runAs(dmlUser) {
            Opportunity opp = utilTestClass.CreateOpportunity('Test Opportunity','2-Qualify');
            opp.Contract_Extension__c = false;
            opp.BED_Change__c = false;
            opp.CloseDate = System.today().addDays(30);
            upsert opp;
            GSMUtilClass.SalesStageSixValidation(opp.id);
        }
        
    }
    
    static testmethod void testCustomSettingsAndMetadata() {
        System.runAs(dmlUser) {
            GSMUtilClass.GetCustomSettingValue('AccountDelete','EnabledProfileId');
            GSMUtilClass.getGSMSettingValue('AcceptLogic_LeadStatus');
            GSMUtilClass.getPRMSettingValue('Partner_Admin_Id');
            GsmUtilClass.getDealRegRebateMatrixSettingValue('ExistingAccountExistingOppty');
            GsmUtilClass.getGsmSettingValue('AcceptLogic_LeadStatus');
            GsmUtilClass.getGSMSettingValuePartialMatch('Logic_Lead');
            //GsmUtilClass.getMarketPlaceMetadataRecords(); 
            GsmUtilClass.isFeatureToggleEnabled('AccountReassignment');
            GsmUtilClass.isFeatureToggleEnabledCustomMetadata('CreateRenewalOpportunityToggle');
            GsmUtilClass.getFeatureToggleDisabledAlertMessage('AccountReassignment');
            GsmUtilClass.isMP3enabled();
            GsmUtilClass.getErrorPageSettingValue('ContractAlreadyAssociated');
            //GsmUtilClass.getContactConversionMetadataRecords();
            GSMUtilClass.getGsmSettingValue();
            GSMUtilClass.getAllCustomSettingResult();
            
            GSMUtilClass.getGsmSettingKeyValue('OA_');
            GSMUtilClass.getAccReassignmentKeyValue();
            GSMUtilClass.featureToggleMsg('AccountReassignment');
        }
    }
    
    static testmethod void methodsCoveredByOtherClass_1(){
        system.runAs(dmlUser){
            Test.startTest();
            List<SFDC_Budget__c> budgetList = new List<SFDC_Budget__c>{new SFDC_Budget__c()};
            List<Budget_Allocation__c> allocationList = new List<Budget_Allocation__c>{new Budget_Allocation__c()};
            List<OpportunityLineItem> listOfLineItems = new List<OpportunityLineItem>{new OpportunityLineItem()};
            String str = 'test';
            List<String> listOfStr = new List<String>{str};
            set<Id> idSet = new set<Id>{UserInfo.getUserId()};
            Datetime dt = system.now();
            OpportunityLineItem oli = new OpportunityLineItem();
            GsmUtilClass.getCurrencyIsoCodes();
            Merge_Contract_PO__c mcp = new Merge_Contract_PO__c();
            List<Invoice__c> invList = new List<Invoice__c>{new Invoice__c()};
            Map<Merge_Contract_PO__c,List<Invoice__c>> poToInvoiceListMap = new Map<Merge_Contract_PO__c,List<Invoice__c>>();
            GsmUtilClass.calculateRemaingFundOnPurchaseOrder(poToInvoiceListMap);
            Invoice__c inv = new Invoice__c();
            Map<Invoice__c,String> invoiceToCurrencyMap = new Map<Invoice__c,String>{inv => str};
            GsmUtilClass.genericConvertContractInvoiceCurrencies(invoiceToCurrencyMap,poToInvoiceListMap);
            GsmUtilClass.getCurrencies(str,str);
            List<FieldSetMember> fs = new List<FieldSetMember>();
            GsmUtilClass.toSelectByFieldSet(fs); 
            GsmUtilClass.isSandbox();
            GsmUtilClass.listContainsMatch(listOfStr,str);
            Account acc = [select Id from Account where Name = 'Account 1' limit 1][0];
            set<Id> accIds = new set<Id>{acc.Id};
            GsmUtilClass.getMaxSequenceForGivenAccounts(accIds,'FR');
            GsmUtilClass.getMaxSequenceForGivenAccounts(accIds,'FC');
            GsmUtilClass.getAvlBudgetForGivenAccounts(idSet); 
            GsmUtilClass.getEarliestFCDeadlineFromListOfBudgetsOrBudgetAllocations(budgetList);
            GsmUtilClass.getEarliestFCDeadlineFromListOfBudgetsOrBudgetAllocations(allocationList);
            Test.stopTest();
        }
    }
    
    static testmethod void methodsCoveredByOtherClass_2(){
        system.runAs(dmlUser){
            Test.startTest();
            set<Id> idSet = new set<Id>();
            string str = 'test';
            Set<String> setOfStr = new Set<String>{str};
            Account account = new Account();
            Map<String,String> mapOfStrStr = new Map<String,String>();
            SFDC_Fund_Accural__c fundAccural = new SFDC_Fund_Accural__c();
            Map<string,string> prmMDFMap = GsmUtilClass.getPRMSettingKeyValue('MDF_'); //SFDC-2568
            SFDC_Budget__c fundBudget = new SFDC_Budget__c();
            GsmUtilClass.createFundBudgetGivenDetails(account,fundAccural,prmMDFMap);
            GsmUtilClass.createFundBudgetGivenDetails(account,fundAccural,prmMDFMap,fundBudget); 
            GsmUtilClass.getAccountDetailsGivenNames(setOfStr,prmMDFMap);
            Account acc = [select Id from Account where Name = 'Account 1' limit 1][0];
            set<Id> accIds = new set<Id>{acc.Id};
            GsmUtilClass.getAccountDetailsGivenIds(accIds,prmMDFMap);
            GsmUtilClass.isAccountIdentityNumber(str);
            GsmUtilClass.buildInExpression(setOfStr,prmMDFMap);
            GsmUtilClass.buildInExpression(idSet); 
            GsmUtilClass.getAccountRegions(accIds,prmMDFMap);
            GsmUtilClass.checkValidationFundRequired(acc,prmMDFMap);
            GsmUtilClass.getClaimedAmtsForAGivenFundRequest(str);
            GsmUtilClass.getClaimedAmtsForAGivenFundRequest(idSet);
            GsmUtilClass.getAccountIdentityFieldName(prmMDFMap);
            GsmUtilClass.updateFundAccuralWithAccountAndBudgetDetails(mapOfStrStr,mapOfStrStr);
            GsmUtilClass.getFundRequestApprovedAmount(null,null);
            GsmUtilClass.convertToCommunityURL(str);
            Test.stopTest();
        }
    }
    
    static testmethod void testValidateEmailAddress() {
        System.runAs(dmlUser) {
            //Test valid email address method for correct and incorrect email
            Boolean result1 = GSMUtilClass.validateEmailAddress('test123@test.com');
            Boolean result2 = GSMUtilClass.validateEmailAddress('testtest.com');
            System.assertEquals(true,result1);
            System.assertEquals(false,result2);
        }
    }
    
    static testmethod void testMigrateDealRegData() {
        System.runAs(dmlUser) {
            
            Account acc = utilTestClass.createAccount('Test Account');
            acc.Partner_Type__c = 'ADS Partner';
            acc.Partner_status__c = 'Partner';
            insert acc;
            
            Opportunity opp1 = utilTestClass.CreateOpportunity('Test Opportunity','2-Qualify');
            opp1.CloseDate = System.today().addDays(30);
            opp1.Partner_Involved__c = acc.id;
            upsert opp1;
            String result = GSMUtilClass.migrateDealRegData(opp1.id);
            
            Opportunity opp2 = utilTestClass.CreateOpportunity('Test Opportunity 2','2-Qualify');
            opp2.CloseDate = System.today().addDays(30);
            opp2.Partner_Involved__c = acc.id;
            upsert opp2;
            
            opp1.Duplicate_Opportunity__c = opp2.id;
            opp1.Registration_Status__c = 'Approved';
            opp1.Deal_Reg_Account_Status__c = 'New Account';
            opp1.Deal_Reg_Opportunity_Status__c = 'New Opportunity';
            opp1.Validation_Override__c = true;
            update opp1;
            
            String result2 = GsmUtilClass.migrateDealRegData(opp1.id);
            System.assertEquals(result2,'Deal Registration Information is successfully migrated.');
            
        }
    }
    
    static testmethod void testCloneAndTiebackLead() {
        
        Account acc = utilTestClass.createAccount('Test Account');
        insert acc;
        String result1 = GSMUtilClass.cloneAndTiebackLead(acc.id,acc.id);
        System.assertEquals(result1,'There was an error in retrieving this Opportunity, please contact eae-ops@akamai.com');
        
        Opportunity opp1 = utilTestClass.CreateOpportunity('Test Opportunity','2-Qualify');
        opp1.CloseDate = System.today().addDays(30);
        upsert opp1;
        
        //String result2 = GSMUtilClass.cloneAndTiebackLead(acc.id,opp1.id);
        //System.assertEquals(result2,'This Opportunity already has a lead associated with it. Please remove that association before proceeding');
        
        Lead l = utilTestClass.CreateLead();
        l.Validation_Override__c = true;
        l.LastName = 'Test Name';
        l.Company = 'Test Company';
        l.Email = 'test@test.test.com';
        upsert l;
        
        String result3 = GSMUtilClass.cloneAndTiebackLead(l.id,opp1.id);
        
        String result4 = GSMUtilClass.cloneAndTiebackLead(l.id,opp1.id);
        
    }
    
    static testmethod void testOtherMethods() {
        
        System.runAs(dmlUser) {
            GSMUtilClass.getNumberOfDaysToShift(System.now());
            GSMUtilClass.isPilotUser(dmlUser.id);
            GSMUtilClass.getPriceBookForProduct();
            GSMUtilClass.getCurrencyIsoCodes('test','test');
            
            // Test getDynamicPicklist
            // Map<String, MarketPlace_Product_Details__mdt > marketPlaceMetadataRecords = GsmUtilClass.getMarketPlaceMetadataRecords();
            // GSMUtilClass.getDynamicPicklist('metadata','MarketPlace_Product_Details__mdt','productName__c',marketPlaceMetadataRecords);
            
            GSMUtilClass.getDynamicPicklist('object','Lead','adg_Status_Performance__c',null);
            GsmUtilClass.getAccountReassignSettingValue('ONA_Reassignment_Rule_Name');
            GsmUtilClass.getNAPSettingValue('NAP_Pulsar_Endpoint_Reset_Password');
            GsmUtilClass.getGSMSettingValuePartialMatchMap('PMA');
            // Test getCreatableFieldsSOQL
            GSMUtilClass.getCreatableFieldsSOQL('Account','email != null');
            
            //getAllCSFieldsAndQueryByType
            Set<Schema.DisplayType> types = new Set<Schema.DisplayType>{Schema.DisplayType.Email, Schema.DisplayType.anytype, Schema.DisplayType.TextArea,Schema.DisplayType.String};
                Map<String,String> objToSoqlMap = GsmUtilClass.getAllCSFieldsAndQueryByType(GsmUtilClass.getAllCustomSettingResult(),types);
            
            //marketplaceContactRoleValidationOnOpportunity
            Opportunity opp1 = utilTestClass.CreateOpportunity('Test Opportunity','2-Qualify');
            opp1.CloseDate = System.today().addDays(30);
            upsert opp1;
            GSMUtilClass.marketplaceContactRoleValidationOnOpportunity(opp1.id);
            
            //Test doDatabseInsert with success
            Account acc = utilTestClass.createAccount('Test Account');
            
            List<SObject> sObjtList = new List<SObject>();
            sObjtList.add(acc);
            GSMUtilClass.doDatabaseInsert(sObjtList,'test','test',true);
             
            //Check doDatabseInsert with errors
            Opportunity oppToInsert = utilTestClass.CreateOpportunity('Test Opportunity','2-Qualify');
            List<SObject> sObjtList2 = new List<SObject>();
            sObjtList2.add(oppToInsert);
            GSMUtilClass.doDatabaseInsert(sObjtList2,'test','test',false);
            List<String> li = new List<String>();
            li.add('name');
            GSMUtilClass.doDatabaseInsertWithErrorEmail(sObjtList2,'test','test',false,li);
            
            //Test doDatabaseUpdate with success
            Account acc2 = utilTestClass.createAccount('Test Account old');
            insert acc2;
            acc2.name = 'Test Account new';
            List<SObject> sObjtList3 = new List<SObject>();
            sObjtList3.add(acc2);
            
            GSMUtilClass.doDatabaseUpdate(sObjtList3,'test','test');
            
            //Test doDatabaseUpdate with error
            Opportunity oppObj = utilTestClass.CreateOpportunity('Test Opportunity','2-Qualify');
            oppObj.CloseDate = System.today().addDays(30);
            upsert oppObj;
            oppObj.CloseDate = null;
            List<SObject> sObjtList4 = new List<SObject>();
            sObjtList4.add(oppObj);
            GSMUtilClass.doDatabaseUpdate(sObjtList4,'test','test');
            
            List<Id> ownerIds = new List<Id>();
            ownerIds.add(userinfo.getuserid());
            GSMUtilClass.isPilotUser(ownerIds);
            GSMUtilClass.isEMRIDeskUser();
            
        }
    }

    static testmethod void testDoDatabasedelete(){
        user accOwner = utilTestClass.CreateUser('SysAdmin', 'Worldwide', 'Business Operations');
        accOwner.IsActive = true;
        insert accOwner;
        System.runAs(accOwner){
            Test.startTest();
            Account acc = utilTestClass.createAccount('Test Account');
            insert acc;

            Opportunity oppty = utilTestClass.CreateOpportunity('__Test Opportunity','1-Create');
            oppty.AccountId = acc.Id;
            oppty.CloseDate = Date.today().addMonths(4);
            insert oppty;

            oppty.CloseDate = Date.today().addMonths(5);
            List<Opportunity> oppList = new List<Opportunity>();
            oppList.add(oppty);
            
            GSMUtilClass.doDatabaseUpsert(oppList, 'Test', 'Test', false);

            Test.stopTest();

            order_approval__c orderApproval = [Select Id from order_approval__c where Associated_Opportunity__c  = :oppty.id][0];
            ContentDocument cd = new ContentDocument();
            
            //Create Document
            ContentVersion cv = new ContentVersion();
            cv.Title = 'Test Document';
            cv.PathOnClient = 'TestDocument.pdf';
            cv.VersionData = Blob.valueOf('Test Content');
            cv.IsMajorVersion = true;
            Insert cv;
            
            //Get Content Version
            ContentVersion cvList = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id][0];

            List<ContentDocument> CDLList = [Select id, title, Owner.name, createddate, LastModifiedDate from ContentDocument where id = :cvList.ContentDocumentId];
            
            GSMUtilClass.doDatabaseDelete(CDLList,'test','test');

        }
    }
    
    static testmethod void testCreditCheckButtonInvoke() {
        System.runAs(dmlUser) {
            
            //Test CreditCheckButtonInvoke
            Account acc = utilTestClass.createAccount('Test Account');
            insert acc;
            GSMUtilClass.CreditCheckButtonInvoke('CreditApproved',acc.id);
            GSMUtilClass.CreditCheckButtonInvoke('SECDEP',acc.id);
            GSMUtilClass.CreditCheckButtonInvoke('SECDEPWAIVE',acc.id);
            GSMUtilClass.CreditCheckButtonInvoke('Marketplace',acc.id);
        }
    }
    
    static testmethod void testSalesApprovalStatus() {
        System.runAs(dmlUser) {
            
            Sales_Approved_Country__c s1 = new Sales_Approved_Country__c();
            s1.Name = 'Test1';
            s1.Region__c = 'Americas';
            s1.Sub_Region__c = 'DACH';
            s1.Is_Reselling_Allowed__c = true;
            s1.Is_Direct_Allowed__c = true;
            insert s1;
            
            System.assertEquals(GSMUtilClass.getSalesApprovalStatus(s1),'Both Direct and Reselling Allowed');
            
            
            Sales_Approved_Country__c s2 = new Sales_Approved_Country__c();
            s2.Name = 'Test2';
            s2.Region__c = 'Americas';
            s2.Sub_Region__c = 'DACH';
            s2.Is_Reselling_Allowed__c = true;
            insert s2;
            
            System.assertEquals(GSMUtilClass.getSalesApprovalStatus(s2),'Only Reselling Allowed');
            
            Sales_Approved_Country__c s3 = new Sales_Approved_Country__c();
            s3.Name = 'Test3';
            s3.Region__c = 'Americas';
            s3.Sub_Region__c = 'DACH';
            s3.Is_Direct_Allowed__c = true;
            insert s3;
            
            System.assertEquals(GSMUtilClass.getSalesApprovalStatus(s3),'Only Direct Allowed');
            
            Sales_Approved_Country__c s4 = new Sales_Approved_Country__c();
            s4.Name = 'Test4';
            s4.Region__c = 'Americas';
            s4.Sub_Region__c = 'DACH';
            insert s4;
            
            System.assertEquals(GSMUtilClass.getSalesApprovalStatus(s4),'Both Restricted');                
            
        }
    }
    
    static testmethod void testGetAccParentsInHierarchy() {
        System.runAs(dmlUser) {
            List<String> accIds = new List<String>();
            
            Account acc1 = utilTestClass.createAccount('Test Account 1');
            insert acc1;
            accIds.add(acc1.id);
            
            Account acc2 = utilTestClass.createAccount('Test Account 2');
            insert acc2;
            accIds.add(acc2.id);
            
            acc2.parentId = acc1.id;
            update acc2;
            
            Account acc3 = utilTestClass.createAccount('Test Account 3');
            insert acc3;
            accIds.add(acc3.id);
            
            acc3.parentId = acc2.id;
            update acc3;
            
            Account acc4 = utilTestClass.createAccount('Test Account 4');
            insert acc4;
            accIds.add(acc4.id);
            
            acc4.parentId = acc3.id;
            update acc4;
            
            Account acc5 = utilTestClass.createAccount('Test Account 5');
            insert acc5;
            accIds.add(acc5.id);
            
            acc5.parentId = acc4.id;
            update acc5;
            
            GSMUtilClass.getAccParentsInHierarchy(accIds,1);
            GSMUtilClass.getAccParentsInHierarchy(accIds,2);
            GSMUtilClass.getAccParentsInHierarchy(accIds,3);
            GSMUtilClass.getAccParentsInHierarchy(accIds,4);
            GSMUtilClass.getAccParentsInHierarchy(accIds,5);
            
            GSMUtilClass.getAccCompleteHierarchy(accIds,'Down');
            GSMUtilClass.getAccCompleteHierarchy(accIds,'up');
            GSMUtilClass.getAccCompleteHierarchy(acc1.id,'Down');
        }
    }
    
    @isTest static void getKeyValueMetadata_test(){
        GsmUtilClass.getKeyValueMetadata('Account_Reassignment_Config__mdt','Value__c','',true);
        GsmUtilClass.getKeyValueMetadata('GSM_Settings__mdt','Value__c','AccReassign_InternalRevAccountToggle',false);
        GsmUtilClass.getReasonCodeSetting();
        GsmUtilClass.captureTransactionalLimits('AccountReassignmentTriggerHandlerNew','beforeInsertBeforeUpdateTrigger',10,10,10,10,10,10,10,10,10,10);
        Opportunity oppObj = utilTestClass.CreateOpportunity('Test Opportunity Demo','2-Qualify');
        oppObj.CloseDate = System.today().addDays(30);
        insert oppObj;
        oppObj.CloseDate = null;
        GsmUtilClass.FailureEmailClass emailWrapper = GsmUtilClass.doDatabaseUpdateWithErrorEmail(new List<Opportunity>{oppObj},'UpdateOpptyOnAccountOwnerChangeBatch','reassignAccount:oppListToUpdate','',new list<string>{'Id'});
    }
}