/*
   Provides coverage to
   1. NominumAPICalloutClass
   2. L2Q_CarrierQuoteManagementController
   3. ValidateOpptyController
   4. ValidateOpptyLineItemController

 */

@isTest(seeAllData = false)
private class OpportunityTests
{

    @testSetUp static void insertCustomSettingsAndCreateData()
        {
            System.runAs(utilTestClass.getTestRunUser())
                {
                    new SobjectBuilder(Environment_Setup__c.sObjectType)
                            .put(Environment_Setup__c.Environment_Type__c, 'Primary')
                            .put(Environment_Setup__c.Active_Org__c, true)
                            .put(Environment_Setup__c.Akam_Id_Start_String__c, 'F-')
                            .create();
                     Account acc=new account();
                                      acc.type='Lead';
                                      acc.website='www.locate.com';
                                      acc.name='LocateName';
                                      acc.Vertical__c = 'Unknown';
                                      acc.Sub_Vertical__c = 'Unknown';
                                      acc.Anaplan_Sub_Territory__c = 'Anaplan-Sub';
                                      acc.BillingCountry = 'India';
                                      acc.BillingState = 'DELHI';
                                      acc.Override_Visual_Compliance__c = True;
                                      insert acc;

                    Account_Reassignment_Rule__c rule = utilTestClass.CreateAccountReassignmentRule('__TestRule', acc.ownerId, 'Worldwide');
                    rule.SubTerritory__c = 'Anaplan-Sub';
                    rule.Associated_User_RSM__c = acc.ownerId;
                    insert rule;

                    List<User> partnerUsers = SObjectFactory.createPartnerUsers(1);
                    Account partAccount = SobjectRepository.getPartnerAccount();
                    Channel_Mapping__c channelMapping = SObjectFactory.createChannelMapping(partAccount.Id);
                    Opportunity oppty = (Opportunity)new SobjectBuilder(Opportunity.sObjectType)
                            .eagerPopulate()
                            .put(Opportunity.AccountId, acc.Id)
                            .put(Opportunity.Deal_Type__c, 'Indirect')
                            .put(Opportunity.Partner_Involved__c, partAccount.Id)
                            .put(Opportunity.Channel_Manager__c, channelMapping.Id)
                            .put(Opportunity.Validation_Override__c,true)
                        	.put(Opportunity.Opportunity_Category__c, 'Product')
                        	.put(Opportunity.Competitor__c, 'Adobe')
                            .create()
                            .getRecord();

                    // add a carrier product
                    Product2 p1 = (Product2)new SobjectBuilder(Product2.sObjectType)
                            .put(Product2.Name, 'CarrierProduct1')
                            .put(Product2.Family, 'Carrier')
                            .put(Product2.IsActive, true)
                            .create()
                            .getRecord();

                    
                    PricebookEntry pbEntry= (PriceBookEntry)new SObjectBuilder(PriceBookEntry.sObjectType)
                            .put(PriceBookEntry.Pricebook2Id, Test.getStandardPricebookId())
                            .put(PriceBookEntry.Product2Id, p1.Id)
                            .put(PriceBookEntry.CurrencyIsoCode, 'USD')
                            .put(PriceBookEntry.IsActive, true)
                            .put(PriceBookEntry.UnitPrice, 1)
                            .create()
                            .getRecord();
                            
                    Test.startTest();
                    List<PriceBookEntry> pbEntries = [select id from PriceBookEntry limit 1];
                    new SobjectBuilder(OpportunityLineItem.sObjectType)
                            .eagerPopulate()
                            .put(OpportunityLineItem.PriceBookEntryId, pbEntry.id)
                            .put(OpportunityLineItem.OpportunityId, oppty.Id)
                            .create();

                    SobjectFactory.insertOpptyTeamMemberForPartner(partnerUsers, oppty.id);

                    Order_Approval__c oa = (Order_Approval__c)new SobjectBuilder(Order_Approval__c.sObjectType)
                            .eagerPopulate()
                            .put(Order_Approval__c.Associated_Opportunity__c, oppty.Id)
                            .create()
                            .getRecord();

                    new SobjectBuilder(API_Connector_Object__c.sObjectType)
                            .eagerPopulate()
                            .put(API_Connector_Object__c.Name, 'NominumSQAForTestClass')
                            .create();
                    
                    GSM_Custom_Settings__c setting = new GSM_Custom_Settings__c();
                    setting.Name = 'CronBatchJob#EmailDestro';
                    setting.Value__c = 'eae-ops@akamai.com,partnersupport@akamai.com';
                    insert setting;

                    Test.stopTest();
                }
        }

    static testmethod void testNominumAccountCreation()
        {

            // Have to separate account, oppty and quote creation because
            // you get uncommitted work pending
            Opportunity opp = SobjectRepository.getOpportunity();

            Test.setCurrentPage(Page.L2Q_CarrierQuoteManagement);
            ApexPages.currentPage().getParameters().put('id', opp.Id);
            ApexPages.StandardController opptyStdController =  new ApexPages.StandardController(opp);
            L2Q_CarrierQuoteManagementController cntroller = new L2Q_CarrierQuoteManagementController(opptyStdController);

            L2Q_CarrierQuoteManagementController.getUIThemeDescription();
            opp = L2Q_CarrierQuoteManagementController.populateOppty(opp.Id);


            Test.startTest();
            /*
			   API Callout sequence -

			   1. Search User Success
			   2. Search Currency Success
			   3. Account Creation Success
			 */

            Test.setMock(HttpCalloutMock.class, new CalloutMock(new List<String>{
                    'NominumGetUserIdSuccess'
                    ,'NominumGetCurrencyIdSuccess'
                    ,'NominumCreateAccountSuccess'
                    ,'NominumGetUserIdSuccess'
                    ,'NominumGetOpportunityRecordTypeId'
                    ,'NominumCreateOpportunitySuccess'
                    }));

            NominumAPICalloutClass.APIResponse ar = L2Q_CarrierQuoteManagementController.createAccountAndUpdateNomAccount(opp);

            System.assert(ar.resultId!=null, 'Carrier Account Creation failed with:'+ar.responseMessage);

            Test.stopTest();
        }


    // static testmethod void testNominumOpportunityCreation()
    //     {
    //         Opportunity opp = SobjectRepository.getOpportunity();

    //         update new Account(Id=opp.AccountId
    //                 ,Validation_Override__c=true
    //                 ,NOM_Account_ID__c='0013F000009NmxUQAS');

    //         opp = L2Q_CarrierQuoteManagementController.populateOppty(opp.Id);

    //         Test.startTest();
    //         /*
	// 		   API Callout sequence -

	// 		   1. Search User Success
	// 		   2. Get Opportunity Record Type Id Success
	// 		   3. Opportunity Creation success
	// 		 */

    //         Test.setMock(HttpCalloutMock.class, new CalloutMock(new List<String>{
    //                 'NominumGetUserIdSuccess'
    //                 ,'NominumGetUserIdSuccess'
    //                 ,'NominumGetCurrencyIdSuccess'
    //                 ,'NominumGetOpportunityRecordTypeId'
    //                 ,'NominumCreateOpportunitySuccess'
    //                 }));

    //         NominumAPICalloutClass.APIResponse ar = L2Q_CarrierQuoteManagementController.createAccountAndUpdateNomAccount(opp);

    //         // test no carrier products
    //         ar = L2Q_CarrierQuoteManagementController.createOpportunityAndUpdateNomOpportunity(opp
    //                 ,opp.Account.NOM_Account_Id__c
    //                 ,new List<OpportunityLineItem>());

    //         System.assert(ar.resultId==null, 'Opportunity creation succeeded even though it didnt have carrier products');

    //         ar = L2Q_CarrierQuoteManagementController.createOpportunityAndUpdateNomOpportunity(opp
    //                 ,opp.Account.NOM_Account_Id__c
    //                 ,opp.OpportunityLineItems);

    //         System.assert(ar.resultId!=null, 'Carrier Opportunity Creation failed with:'+ar.responseMessage);
    //         Test.stopTest();


    //     }

    // static testmethod void testNominumQuoteCreation()
    //     {
    //         Opportunity opp = SobjectRepository.getOpportunity();
    //         opp.NOM_Opportunity_Id__c = '0063F000007UjFPQA0';
    //         update opp;

    //         opp = L2Q_CarrierQuoteManagementController.populateOppty(opp.Id);


    //         Test.startTest();
    //         /*
	// 		   API Callout sequence -
	// 		   1. Get Quote Id Failure
	// 		   2. Get Quote Record Type Id Success
	// 		   3. Quote creation Success

	// 		 */

    //         Test.setMock(HttpCalloutMock.class, new CalloutMock(new List<String>{
    //                 'NominumGetQuoteIdFailure'
    //                 ,'NominumGetQuoteRecordTypeId'
    //                 ,'NominumCreateQuoteSuccess'
    //                 }));

    //         NominumAPICalloutClass.APIResponse ar = L2Q_CarrierQuoteManagementController.createOpportunityAndUpdateNomOpportunity(opp
    //                 ,'0013F000009NmxUQAS'
    //                 ,opp.OpportunityLineItems);


    //         ar = L2Q_CarrierQuoteManagementController.createQuoteAndRedirect(ar.resultId);

    //         System.assert(ar.resultId!=null, 'Carrier Quote Creation failed with:'+ar.responseMessage);
    //         Test.stopTest();
    //     }


    static testmethod void validateOpptyAndOpptyLineItemTests()
        {
            Opportunity opp = SobjectRepository.getOpportunity();
            ApexPages.StandardController sc = new ApexPages.StandardController(opp);

            Test.startTest();
            PageReference pageRef = Page.ValidateOppty;
            pageRef.getParameters().put('id', opp.id);
            Test.setCurrentPageReference(pageRef);
            ValidateOpptyController vocController = new ValidateOpptyController(sc);
            vocController.pageRedirect();
            pageRef.getParameters().put('flow', 'yes');
            vocController.pageRedirect();
            vocController.isParentOpptyLocked = true;
            vocController.parentOpptyLockedErrorMEssage = 'setting this for coverage';
            /**Begin Rajesh Kumar SFDC-5897 **/
            vocController.getHtmlMessage();
            /**End Rajesh Kumar SFDC-5897 **/
            vocController.pageRedirect();


            OpportunityLineItem oli = SobjectRepository.getOpportunityLineItem();

            ApexPages.StandardController scOli = new ApexPages.StandardController(oli);
            pageRef = Page.ValidateOpptyLineItemPage;
            pageRef.getParameters().put('id', oli.id);
            Test.setCurrentPageReference(pageRef);
            ValidateOpptyLineItemController vocControllerOli = new ValidateOpptyLineItemController(scOli);
            vocControllerOli.UpdateOppty();
            vocControllerOli.pageRedirect();
            vocControllerOli.pageRedirectDel();
            /**Begin Rajesh Kumar SFDC-5897 **/
            vocControllerOli.getHtmlMessage();
            /**End Rajesh Kumar SFDC-5897 **/

            Test.stopTest();

        }

    static testMethod void CFATestClassPositive()
        {
            User partner = SobjectRepository.getPartnerUser();
            ContentDocumentLink att;
            System.runAs(utilTestClass.getTestRunUser())
                {
                    test.startTest();
                    Order_Approval__c oa = SobjectRepository.getOrderApproval();
                    ApexPages.currentPage().getParameters().put('id',oa.Id);
                    CFA_SendEmailController fruc1 = new CFA_SendEmailController();
                    fruc1.showNotificationAndDiscontinue('Test Message');
                    fruc1.userTheme = 'fromSF1';
                    fruc1.showNotificationAndDiscontinue('Test Message Mobile');
                    
                    //Begin SFDC-8568 - Harsh Pandey
                    Set<String> Test_Email_list=new Set<String>();
                    Test_Email_list.add('Test String1');
                    Test_Email_list.add('Test String2');
                    String str = CFA_SendEmailController.emailListString(Test_Email_list);
                    system.assertEquals('Test String1,Test String2', str);
                    //End SFDC-8568 - Harsh Pandey

                    fruc1.AutonomyNotificationApproved();
                    PageReference pg = fruc1.canceltoOppty();

                    // Order_Approval__c oa = SobjectRepository.getOrderApproval();
                    // Opportunity oppty = SobjectRepository.getOpportunity();
                    // Contact partnerContact = SobjectRepository.getPartnerContact();
                    // System.assert(partnerContact.Partner_User__c!=null, 'Partner User lookup not populated:'+partnerContact);
                    // TestUtils.attachFile(oa.Id);

                    // PageReference pageRef1 = Page.CFA_SendEmail;
                    // Test.setCurrentPageReference(pageRef1);
                    // pageRef1.getParameters().put('id', oa.id);
                    // //rsharma-fixed test class
                    // ContentVersion conVer = L2Q_ContentDocumentUtilClass.setContentVersion('S', 'Name', 'Name', 'Body');
                    // insert conVer;
                    // ContentVersion conVer2 = [SELECT Id, ContentDocumentId,VersionData, PathOnClient FROM ContentVersion WHERE Id = :conVer.Id];
                    // att = L2Q_ContentDocumentUtilClass.setContentDocumentLink(conVer2.ContentDocumentId, oa.Id, 'I', 'AllUsers');
                    // insert att;
                    // CFA_SendEmailController fruc1 = new CFA_SendEmailController();
                    // fruc1.validate();
                    // fruc1.canceltoOppty();
                    // fruc1.AutonomyNotificationApproved();
                    // fruc1.showNotificationAndDiscontinue('test message');
                    // //fruc1.createConfirmSendTestMethod();

                    // CustomObjectLookupController lookupController=new CustomObjectLookupController();
                    // lookupController.query='John';
                    // lookupController.oppId=oppty.Id;
                    // lookupController.runQuery();
                    
                    // fruc1.preview();             
                    // fruc1.opp.CFA_To__c=partnerContact.Id;
                    // fruc1.preview();
                    // fruc1.SendEmail();
                    // fruc1.back();
                    // fruc1.preview();

                    // fruc1.cancel();


                    // Partner_Order_Acceptance_Document__c poad= [select id,Order_Acceptance_Status__c from Partner_Order_Acceptance_Document__c where Opportunity__c=:oppty.id][0];

                    // //system.assertEquals(poad.Order_Acceptance_Status__c, 'Pending Acceptance');
                    // att = [SELECT Id, ContentDocumentId, ContentDocument.LatestPublishedVersion.Title from ContentDocumentLink where LinkedEntityId=:poad.id][0];
                    // system.assertNotEquals(att.ContentDocument.LatestPublishedVersion.Title, '');
                    // List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument where id!=:conVer2.ContentDocumentId];
                    // User usr = utilTestClass.getTestRunUser();
                    // usr.Can_Accept_POA__c = true;
                    // update usr;

                    // poad.Order_Acceptance_Status__c = 'Pending Acceptance';
                    // poad.Validation_Override__c = true;
                    // update poad;
                    
                    // Partner_Order_Acceptance_Document__c poadRec1 = new Partner_Order_Acceptance_Document__c();
                    // poadRec1.Name = 'testName';
                    // poadRec1.Opportunity__c = oppty.Id;
                    // poadRec1.Order_Acceptance_Status__c = 'Pending Acceptance';
                    // poadRec1.Validation_Override__c = true;
                    // insert poadRec1;
                    
                    // ContentVersion conVerPOA = L2Q_ContentDocumentUtilClass.setContentVersion('S', 'testName', 'testName', 'Body');
                    // insert conVerPOA;
                    
                    // ContentVersion conVerPOAIns = [SELECT Id, ContentDocumentId,VersionData, PathOnClient FROM ContentVersion WHERE Id = :conVerPOA.Id];
                    // att = L2Q_ContentDocumentUtilClass.setContentDocumentLink(conVerPOAIns.ContentDocumentId, oa.Id, 'I', 'AllUsers');
                    // insert att;
                    
                    // L2Q_POA_NoFilesFixerBatch obj = new L2Q_POA_NoFilesFixerBatch();
                    // Database.executeBatch(obj);

                    // fruc1.SendEmail();
                    
                }

            test.stopTest();
        }


    static testMethod void CFATestClassNegative()
        {
            System.runAs(utilTestClass.getTestRunUser())
                {
                    Order_Approval__c oa = SobjectRepository.getOrderApproval();
                    Opportunity oppty = SobjectRepository.getOpportunity();
                    User partner = SobjectRepository.getPartnerUser();
                    test.startTest();
                    Channel_Mapping__c cm = SobjectRepository.getMasterChannelMapping();
                    User opptySCMOwnerUser = new User(id=cm.PAE_Id__c);
                    //Attachment att = TestUtils.attachFile(oa.Id);
                    ContentVersion conVer11 = L2Q_ContentDocumentUtilClass.setContentVersion('S', 'NameThatExceeds80CharactersNameThatExceeds80CharactersNameThatExceeds80CharactersNameThatExceeds80Characters', 'NameThatExceeds80CharactersNameThatExceeds80CharactersNameThatExceeds80CharactersNameThatExceeds80CharactersNameThatExceeds80Character', 'Body');
                    insert conVer11;
                    ContentVersion conVer22 = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :conVer11.Id];
                    ContentDocumentLink att = L2Q_ContentDocumentUtilClass.setContentDocumentLink(conVer22.ContentDocumentId, oa.Id, 'I', 'AllUsers');
                    insert att;

                    system.runAs(opptySCMOwnerUser)
                        {
                            try {
                            PageReference pageRef = Page.CFA_SendEmail;
                            Test.setCurrentPageReference(pageRef);
                            pageRef.getParameters().put('id', '');
                            CFA_SendEmailController fruc = new CFA_SendEmailController();
                            fruc.preview();

                            fruc.PartnerEmail = 'fdjakld@akamaipartner.com';
                            fruc.preview();
                            }
                            catch (exception ex)
                            {

                            }
                        }

                    PageReference pageRef1 = Page.CFA_SendEmail;
                    Test.setCurrentPageReference(pageRef1);
                    pageRef1.getParameters().put('id', oa.id);
                    CFA_SendEmailController fruc2 = new CFA_SendEmailController();
                    System.assertNotEquals(fruc2.oa,null);
                    if(fruc2.opp != null) {
                        fruc2.opp = new Opportunity();
                    }
                    fruc2.opp.CFA_To__c=partner.contactid;
                    fruc2.preview();
                    fruc2.back();
                    fruc2.preview();
                    fruc2.SendEmail();
                    fruc2.cancel();
                    Partner_Order_Acceptance_Document__c poad= [select id,Order_Acceptance_Status__c from Partner_Order_Acceptance_Document__c where Opportunity__c=:oppty.id][0];
                    system.assertEquals(poad.Order_Acceptance_Status__c, 'Pending Acceptance');
                    ContentVersion conVerr = L2Q_ContentDocumentUtilClass.setContentVersion('S', 'Name', 'Name', 'Body');
                    insert conVerr;
                    ContentVersion conVerr2 = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :conVerr.Id];
                    att = L2Q_ContentDocumentUtilClass.setContentDocumentLink(conVerr2.ContentDocumentId, poad.Id, 'I', 'AllUsers');
                    //update att;


                    
                    //fruc.SendEmail();
                    test.stopTest();
                }
        }

     	static testmethod void SF1_SendForOrderAcceptanceTest()
         {

             User testRunUser = utilTestClass.getTestRunUser();
             System.runAs(testRunUser)
                 {

                     test.startTest();

                    Opportunity oppty = SobjectRepository.getOpportunity();
                    Order_Approval__c oa = SobjectRepository.getOrderApproval();
                    User partner = SobjectRepository.getPartnerUser();
                    System.assertNotEquals(partner,null);
                    //Attachment att = TestUtils.attachFile(oa.Id);
                    ContentVersion conVer111 = L2Q_ContentDocumentUtilClass.setContentVersion('S', 'Name', 'Name', 'Body');
                    insert conVer111;
                    ContentVersion conVer222 = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :conVer111.Id];
                    ContentDocumentLink att = L2Q_ContentDocumentUtilClass.setContentDocumentLink(conVer222.ContentDocumentId, oa.Id, 'I', 'AllUsers');
                    insert att;

                    String returnVal = SF1_SendForOrderAcceptance.getInitialValidation(oa.id);

                    List<Id> listOfCheckedIds = new List<Id>();
                    listOfCheckedIds.add(att.ContentDocumentId);

                    Map<String, String> htmlData = new Map<String, String>();
                    htmlData.put('contactName', partner.Name);
                    htmlData.put('contactId', partner.Id);
                    htmlData.put('emailSubject', 'Test');
                    htmlData.put('htmlBodyOfEmail', 'Test');

                    returnVal = SF1_SendForOrderAcceptance.sendOAEmail(oa.id, listOfCheckedIds, htmlData);

                    returnVal = SF1_SendForOrderAcceptance.resultSetCustom(true, 'Test', 'Test', 'Test', 'Test');
                    returnVal = SF1_SendForOrderAcceptance.constructHtmlData('Test', 'Test', 'Test', 'Test', 'Test');
                    returnVal = SF1_SendForOrderAcceptance.getAssociatedOpptyData(oppty.id);
                    returnVal = SF1_SendForOrderAcceptance.getUIThemeDescription();

                    test.stopTest();
                }

        }

    public static testmethod void testConvertCurrency()
        {

            Test.startTest();
            Opportunity testOppty = SobjectRepository.getOpportunity();

            ApexPages.StandardController stdCtrl = new ApexPages.StandardController(testOppty);

            ChangeOpportunityCurrencyController cocc = new ChangeOpportunityCurrencyController(stdCtrl);

            List<SelectOption> options = cocc.getCurrencies();

            Test.setCurrentPage(Page.SelectCurrencyPage);

            testOppty.CurrencyISOCode = 'INR';

            PageReference pageRef = cocc.convertCurrency();
            testOppty=SF1_OpportunityService.getOpportunity(testOppty.Id);
            SF1_OpportunityService.getExistingOpportunityList(testOppty, 1,1,null);
            SF1_OpportunityService.getOAForCurrentOpportunity(testOppty.Id);
            SF1_OpportunityService.getOpportunitiesForCurrentOwner(testOppty.Id);

            Test.stopTest();
        }

        static testmethod void testPRMSearchOpportunityController()
        {
            Opportunity opp = SobjectRepository.getOpportunity();
            opp = [select Id, Partner_Involved__r.No_Rebate_Required__c, Deal_Reg_Account_Status__c,Existing_Opportunity__c, AccountId, Deal_Reg_Account_Discount__c, Deal_Reg_Opportunity_Discount__c from Opportunity where Id=:opp.id];
            
            ApexPages.StandardController sc = new ApexPages.StandardController(opp);

            Test.startTest();
            PageReference pageRef = Page.PRMSearchOpportunity;

            pageRef.getParameters().put('opptyid', opp.id);
            Test.setCurrentPageReference(pageRef);
            PRMSearchOpportunityController prc = new PRMSearchOpportunityController();
            prc.createNew();
            prc.addOppty();
            prc.cancel();

            prc.search();
            PRMSearchOpportunityController.populateRebateDiscountPercentageAndStatus(opp, 'ExistingAccountExistingOppty');

            PageReference pr2 = Page.PRMSearchOpportunity;
            Test.setCurrentPageReference(pr2);
            PRMSearchOpportunityController prc2=new PRMSearchOpportunityController();

            Test.stopTest();

        }

        static testmethod void CFA_ConfirmAttachmentControllerTest2() {
            User testRunUser = utilTestClass.getTestRunUser();
            System.runAs(testRunUser) {
                Opportunity oppty = SobjectRepository.getOpportunity();
                User partner = SobjectRepository.getPartnerUser();
                ContentVersion conVer = L2Q_ContentDocumentUtilClass.setContentVersion('S', 'Name', 'Name', 'Body');
                Test.startTest();
                
                insert conVer;
                Partner_Order_Acceptance_Document__c poad = new Partner_Order_Acceptance_Document__c();
                poad.opportunity__c = oppty.Id;
                poad.Validation_Override__c = true;
                poad.Attachment__c = conVer.Id;
                poad.Order_Acceptance_Status__c = 'Pending Acceptance';

                Map<String, String> initialDataMap;
                System.runAs(partner) {
                    initialDataMap = CFA_ConfirmAttachmentController.getInitialDataMap(conVer.Id);
                }

                insert poad;
                
                System.runAs(partner) {
                    initialDataMap = CFA_ConfirmAttachmentController.getInitialDataMap('');
                    initialDataMap = CFA_ConfirmAttachmentController.getInitialDataMap(conVer.Id);
                }

                poad = [SELECT Id,
                Opportunity__c,
                Opportunity__r.Name,
                Opportunity__r.Account.Id,
                Opportunity__r.Account.Name,
                Opportunity__r.Account.AKAM_Account_ID__c,
                Opportunity__r.Owner.Email, // SFDC-5907
                Opportunity__r.Partner_Involved__c,
                Opportunity__r.Partner_Involved__r.Name,
                Opportunity__r.Partner_Involved__r.Partner_PO_Required__c,
                Opportunity__r.Partner_Involved__r.Parent.Id,
                Partner_Account_ID__c,
                Partner_Involved_Name__c,
                Opportunity__r.Partner_Involved__r.POA_Email_List__c,
                Opportunity__r.Id,
                Opportunity__r.CloseDate,
                Opportunity__r.StageName,
                Notification__c,
                Notification_email_list__c,
                Partner_Notes__c,
                Customer_Unique_Id__c,
                Order_Acceptance_Status__c,
                Customer_Name__c,
                Accepted_At__c,
                Accepted_By__r.Name,
                Accepted_By__c,
                Rejection_Comments__c,
                URL_for_Partners__c,
                CreatedById,
                Attachment__c,
                PO_Number__c
                FROM Partner_Order_Acceptance_Document__c WHERE Id = :poad.Id];

                poad.Order_Acceptance_Status__c = 'Accepted';
                poad.Accepted_At__c = DateTime.now();
                poad.Accepted_By__c = partner.Id;
                Boolean flag = CFA_ConfirmAttachmentController.sendConfirmationEmail(poad, conVer.Id);

                poad.Validation_Override__c = true;
                update poad;
                System.runAs(partner) {
                    initialDataMap = CFA_ConfirmAttachmentController.getInitialDataMap(conVer.Id);
                }
                poad.Order_Acceptance_Status__c = 'Voided';
                poad.Validation_Override__c = true;
                update poad;
                System.runAs(partner) {
                    initialDataMap = CFA_ConfirmAttachmentController.getInitialDataMap(conVer.Id);
                }
                Test.stopTest();
            }
        }

        static testmethod void OpportunityTeamMemberTest() {
            User testRunUser = utilTestClass.getTestRunUser();
            System.runAs(testRunUser) {
                Test.startTest();
                Opportunity oppty = SobjectRepository.getOpportunity();
                OpportunityTeamMember otm=new OpportunityTeamMember();
                otm.TeamMemberRole='Sales - Primary';
                otm.UserId=testRunUser.id;
                otm.OpportunityId=oppty.id;

                insert otm;
                delete otm;
                Test.stopTest();
            }
        }

        static testmethod void CFA_ConfirmAttachmentControllerTest1() {
           
            User testRunUser = utilTestClass.getTestRunUser();
            System.runAs(testRunUser) {
                Opportunity oppty = SobjectRepository.getOpportunity();
                Order_Approval__c oa = SobjectRepository.getOrderApproval();
                User partner = SobjectRepository.getPartnerUser();
                Account partAccount = SobjectRepository.getPartnerAccount();
                List<ContentVersion> lstConV = new List<ContentVersion>();
                
                ContentVersion conVer = L2Q_ContentDocumentUtilClass.setContentVersion('S', 'Name', 'Name', 'Body');
                ContentVersion conVer3 = L2Q_ContentDocumentUtilClass.setContentVersion('S', 'Name', 'Name', 'Body');
                ContentVersion poDoc = L2Q_ContentDocumentUtilClass.setContentVersion('S', 'Name', 'Name', 'Body');

                Test.startTest();

                lstConV.add(conVer);
                lstConV.add(conVer3);
                lstConV.add(poDoc);
                insert lstConV;
                
                Partner_Order_Acceptance_Document__c poad = new Partner_Order_Acceptance_Document__c();
                poad.opportunity__c = oppty.Id;
                poad.Validation_Override__c = true;
                poad.Attachment__c = conVer.Id;
                poad.Order_Acceptance_Status__c = 'Pending Acceptance';

                Partner_Order_Acceptance_Document__c poad3 = new Partner_Order_Acceptance_Document__c();
                poad3.opportunity__c = oppty.Id;
                poad3.Validation_Override__c = true;
                poad3.Attachment__c = conVer3.Id;
                poad3.Order_Acceptance_Status__c = 'Pending Acceptance';

                List<Partner_Order_Acceptance_Document__c> lstPoad = new List<Partner_Order_Acceptance_Document__c>();
                lstPoad.add(poad);
                lstPoad.add(poad3);

                insert lstPoad;
                poad = lstPoad.get(0);
                poad3 = lstPoad.get(1);

                Map<Id, ContentVersion> mapOfIdvsConV = new Map<Id, ContentVersion>([SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :lstConV]);
                ContentVersion conVer2 = mapOfIdvsConV.get(lstConV.get(0).Id);
                ContentVersion conVer4 = mapOfIdvsConV.get(lstConV.get(1).Id);
                ContentVersion poDoc2 = mapOfIdvsConV.get(lstConV.get(2).Id);
                
                List<ContentDocumentLink> lstConDocLink = new List<ContentDocumentLink>();
                ContentDocumentLink att = L2Q_ContentDocumentUtilClass.setContentDocumentLink(conVer2.ContentDocumentId, poad.Id, 'I', 'AllUsers');
                ContentDocumentLink conDocLink2 = L2Q_ContentDocumentUtilClass.setContentDocumentLink(conVer4.ContentDocumentId, poad3.Id, 'I', 'AllUsers');
                ContentDocumentLink poDocLink = L2Q_ContentDocumentUtilClass.setContentDocumentLink(poDoc2.ContentDocumentId, poad.Id, 'I', 'AllUsers');
                lstConDocLink.add(att);
                lstConDocLink.add(conDocLink2);
                lstConDocLink.add(poDocLink);

                partner.Can_Accept_POA__c = true;
                update partner;
                
                partAccount.Partner_PO_Required__c = true;
                update partAccount;

                insert lstConDocLink;
    
                Map<String, String> initialDataMap;
                
                System.runAs(partner) {
                    initialDataMap = CFA_ConfirmAttachmentController.getInitialDataMap(conVer2.Id);
                }
                Partner_Order_Acceptance_Document__c poad2 = (Partner_Order_Acceptance_Document__c) JSON.deserialize(initialDataMap.get('acceptanceDoc'), Partner_Order_Acceptance_Document__c.Class);
                poad2.Order_Acceptance_Status__c = 'Accepted';
    
                initialDataMap.put('acceptanceDoc', JSON.serialize(poad2));
                Map<String, String> returnValMap;
                System.runAs(partner) {
                    returnValMap = CFA_ConfirmAttachmentController.processPartnerOrderAcceptance(initialDataMap);
                }
                poad2.Opportunity__r.Partner_Involved__r.Partner_PO_Required__c = false;
                initialDataMap.put('acceptanceDoc', JSON.serialize(poad2));
                //System.runAs(partner) {
                   returnValMap = CFA_ConfirmAttachmentController.processPartnerOrderAcceptance(initialDataMap);
                   ContentDocument cd = CFA_ConfirmAttachmentController.getPODocuments(poad2.Id, conVer2.Id);
                //}
                
                System.runAs(partner) {
                    ContentDocument cd2 = CFA_ConfirmAttachmentController.getPODocuments(poad2.Id, conVer2.Id);
                    poad2.Opportunity__r.Partner_Involved__r.Partner_PO_Required__c = true;
                    initialDataMap.put('acceptanceDoc', JSON.serialize(poad2));
                    returnValMap = CFA_ConfirmAttachmentController.processPartnerOrderAcceptance(initialDataMap);
                    Boolean returnFlag = CFA_ConfirmAttachmentController.deletePODocument(cd2.Id);
                }
                Test.setCurrentPage(Page.CFA_ConfirmAttachment);
                ApexPages.currentPage().getParameters().put('id', conVer2.Id);
                ApexPages.currentPage().getParameters().put('acceptanceRecordId', poad.Id);
    
                //For Classic Partner User
                CFA_ConfirmAttachmentController cfa = new CFA_ConfirmAttachmentController();
    
                System.runAs(partner) {
                    initialDataMap = CFA_ConfirmAttachmentController.getInitialDataMap(conVer3.Id);
                }
    
                PageReference pg = cfa.upload();
                
                cfa.attachmentt.Title = 'Attachement Title';
                cfa.attachmentt.VersionData = Blob.valueOf('VersionData');
                pg = cfa.upload();

                cfa.attachmentt.Title = '';
                cfa.attachmentt.VersionData = Blob.valueOf('VersionData');
                pg = cfa.upload();
    
                System.runAs(partner) {
                    poad2.Order_Acceptance_Status__c = 'Rejected';
                    returnValMap = CFA_ConfirmAttachmentController.processPartnerOrderAcceptance(initialDataMap);
                }    
                Test.stopTest();
            }
           
    
        }

        static testmethod void  DocumentJsonControllerTest(){
            Test.startTest();
            PageReference pageRef = Page.DocumentJson;
            Test.setCurrentPageReference(pageRef);
            List<ContentVersion> listOfContentVersion = new List<ContentVersion>();
            listOfContentVersion.add(L2Q_ContentDocumentUtilClass.setContentVersion('S', 'Title', 'Title', 'Test Data'));
            insert listOfContentVersion;
            ContentVersion cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:listOfContentVersion.get(0).Id];
            List<ContentWorkspaceDoc> listOfContentWorkspaceDoc = new List<ContentWorkspaceDoc>();
            listOfContentWorkspaceDoc.add(L2Q_ContentDocumentUtilClass.setContentWorkspaceDoc(GSMSettings.getValue('DocumentJSON_WorkspaceId'), cv.ContentDocumentId));
            DocumentJsonController fruc = new DocumentJsonController();
            ContentVersion cvv = L2Q_ContentDocumentUtilClass.setContentVersion('S', 'Title', 'Title', 'Test Data');
            cvv.TagCsv = '.png,.jpg';
            insert cvv;
            ContentDocument cd = [SELECT Id, LatestPublishedVersion.TagCsv, LatestPublishedVersion.title, LatestPublishedVersion.id, LatestPublishedVersion.URL_for_Partners__c FROM ContentDocument Where LatestPublishedVersion.id = :cvv.Id];
            DocumentJsonController.JsonWrapper jw = fruc.generateJSONWrapper(cd, 'l2qjan', '.png', 'xml');
            jw = fruc.generateJSONWrapper(cd, 'l2qjan', 'xml', '.png');
            Test.stopTest();
        }
     static testMethod void testZOFFchanges()
        {
            try {
                    test.startTest();
                    Opportunity oppty = SobjectRepository.getOpportunity();
                    update new opportunity (id = oppty.id,Validation_Override__c = true,opportunity_type__c = 'Direct');
                    Opportunity oppty0 = SobjectRepository.getOpportunity();
                    Order_Approval__c oa = SobjectRepository.getOrderApproval();
                    CFA_SendEmailController fruc1 = new CFA_SendEmailController();
                    
                    //System.assert(false,oa);
                    test.stopTest();  
            }
            catch (Exception ex)
            {}
           
        }

        static testMethod void testMediaEmail(){
        test.startTest();

        Opportunity oppty = SobjectRepository.getOpportunity();
        update new opportunity (id = oppty.id,Validation_Override__c = true, ZOFF_Status__c = 'Yes', Opt_Out_Reason__c = 'Testing');


        test.stopTest();
    }
    
}