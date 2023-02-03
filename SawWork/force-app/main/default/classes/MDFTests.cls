@isTest
private class MDFTests
{
    // TEST INT JOB FAST DEPLOY
    private static User dmlUser = new User(id=UserInfo.getUserId());
    private static final Integer numberOfFundBudgets = 3;

    @testSetUp static void insertCustomSettingsAndCreateData()
        {
            //Test.startTest();
            Map<String, String> objectToCustomSettingResource = new Map<String, String>{
            'Communities_Settings__c'   => 'CS_Communities_Settings',
            'LunaControlCenterSettings__c' => 'CS_LunaControlCenterSettings',
            'Environment_Setup__c' => 'CS_Environment_Setup'
            };
            System.runAs(dmlUser)
                {

                    PRMTriggerClass.InitializeFlagVariables();
                    
                    List<User> paeUsers = SObjectRepository.getSalesPAEUsers(2);
                    utilTestClass.insertCustomSettings(objectToCustomSettingResource);
                     SObjectFactory.createPartnerUsers(1);
                    Account partAccount = SobjectRepository.getPartnerAccount();
                    User partnerUser = SobjectRepository.getPartnerUser();
                    /*Channel_Mapping__c cm = (Channel_Mapping__c)new SobjectBuilder(Channel_Mapping__c.sObjectType)
                            .eagerPopulate()
                            .put(Channel_Mapping__c.PAE_ID__c, paeUsers[0].Id)
                            .put(Channel_Mapping__c.MDF_Approver__c, approverId)
                            .put(Channel_Mapping__c.Partner_Name__c, partAccount.Id)
                            .create()
                            .getRecord();*/
                    
                    
                    SFDC_Channel_Account_Plan__c cap = (SFDC_Channel_Account_Plan__c)new SobjectBuilder(SFDC_Channel_Account_Plan__c.sObjectType)
                        .eagerPopulate()
                        .put(SFDC_Channel_Account_Plan__c.Partner_Account__c, partnerUser.Contact.AccountId)
                        .create()
                        .getRecord();

                    Partner_Marketing_Plan__c pmp = (Partner_Marketing_Plan__c)new SobjectBuilder(Partner_Marketing_Plan__c.sObjectType)
                        .eagerPopulate()
                        .put(Partner_Marketing_Plan__c.Business_Plan__c, cap.Id)
                        .put(Partner_Marketing_Plan__c.Plan_Period__c, '2H 2020')
                        .create()
                        .getRecord();

                    Partner_Marketing_Activity__c pma = (Partner_Marketing_Activity__c)new SobjectBuilder(Partner_Marketing_Activity__c.sObjectType)
                        .eagerPopulate()
                        .put(Partner_Marketing_Activity__c.Partner_Marketing_Plan__c, pmp.Id)
                        .put(Partner_Marketing_Activity__c.Activity_Status__c, 'In Progress')
                        .put(Partner_Marketing_Activity__c.Validation_Override__c, true)
                        //.put(Partner_Marketing_Activity__c.Activity_Cost__c,200)
                        .create()
                        .getRecord();

                    pmp.Plan_Status__c = 'Approved';
                    update pmp;
                    pma = SobjectRepository.getPMA();
					//System.assertEquals(1,2 , pma.Activity_Cost__c);




                    // utilTestClass.insertCustomSettings(objectToCustomSettingResource);
                    // SObjectFactory.createPartnerUsers(1);
                    // Account partAccount = SobjectRepository.getPartnerAccount();
                    // some problem with this method SobjectRepository.getPartnerUser()
                    // create two fund budgets
                    new SObjectBuilder(SFDC_Budget__c.sObjectType)
                            .eagerPopulate()
                            .put(SFDC_Budget__c.Account__c, partAccount.Id)
                            .count(numberOfFundBudgets)
                            .create();
                    PRMTriggerClass.InitializeFlagVariables();

                    // create fund request in draft state, submitted state and approved state
                    List<SFDC_MDF__c> fundRequests = (List<SFDC_MDF__c>)
                            new SobjectBuilder(SFDC_MDF__c.sObjectType)
                                    .eagerPopulate()
                                    .put(SFDC_MDF__c.Account__c, partAccount.Id)
                                    .count(3)
                                    .create()
                                    .getRecords();

                    // let fr0 remain in draft state. Submit fr1 and submit and approve fr2
                    SFDC_MDF__c fr1 = fundRequests[1];
                    SFDC_MDF__c fr2 = fundRequests[2];
                    fr1.Partner_Account_Owner__c = paeUsers[0].Id;
                    fr1.Partner_Marketing_Activity__c = pma.id;

                    fr2.Partner_Account_Owner__c = paeUsers[0].Id;
                    fr2.Partner_Marketing_Activity__c = pma.id;

                    List<SFDC_MDF__c> frs = new List<SFDC_MDF__c>();
                    frs.add(fr1);
                    frs.add(fr2);
                    
                    update frs;
                   // System.assertEquals(1, 2, '**FR1  ' + fr1);
                    Test.startTest();
                    //PRMTriggerClass.InitializeFlagVariables();

                   // List<User> paeUsers = SObjectRepository.getSalesPAEUsers(2);
                    User frQualityQueueUser = SObjectRepository.getFundRequestQualityQueueUser();
                    Id approverId = null;
                    if(frQualityQueueUser != null) {
                        approverId = frQualityQueueUser.Id;
                    } else {
                        //Not neccesary - Added to pass test in devqa
                        approverId = paeUsers[1].Id;
                    }
                    frQualityQueueUser.isActive = true;
                    
                    // active master channel mapping with fr approver
                    // Change MDF_Approver__c from paeUsers[1].Id to frQualityQueueUser.Id
                    // Channel_Mapping__c cm = (Channel_Mapping__c)new SobjectBuilder(Channel_Mapping__c.sObjectType)
                    //         .eagerPopulate()
                    //         .put(Channel_Mapping__c.PAE_ID__c, paeUsers[0].Id)
                    //         .put(Channel_Mapping__c.MDF_Approver__c, approverId)
                    //         .put(Channel_Mapping__c.Partner_Name__c, partAccount.Id)
                    //         .create()
                    //         .getRecord();
                    
					Channel_Mapping__c cm = (Channel_Mapping__c)new SobjectBuilder(Channel_Mapping__c.sObjectType)
                            .eagerPopulate()
                            .put(Channel_Mapping__c.PAE_ID__c, paeUsers[0].Id)
                            .put(Channel_Mapping__c.MDF_Approver__c, approverId)
                            .put(Channel_Mapping__c.Partner_Name__c, partAccount.Id)
                            .create()
                            .getRecord();

                    // submit the two FRs for approval
                    PRMTriggerClass.InitializeFlagVariables();
                    TestUtils.submitForApproval(fr1);
                    PRMTriggerClass.InitializeFlagVariables();

                    TestUtils.submitForApproval(fr2);
                    PRMTriggerClass.InitializeFlagVariables();

                    User frApprover = new User(id=cm.MDF_Approver__c);
                    //System.runAs(frApprover){}
                        
                            TestUtils.approveRecord(fr2);
                     
                        

                    User regionalManagerQueue = new User(Id=TestUtils.getNextApproverUserId(fr2));
                    PRMTriggerClass.InitializeFlagVariables();

                    System.runAs(regionalManagerQueue)
                        {
                            //TestUtils.approveRecordWithoutSettingNextApprover(fr2);
                        }
                    PRMTriggerClass.InitializeFlagVariables();
                }
                Test.stopTest();

        }

    static testmethod void testFundClaimApprovalTriggers()
        {
            SFDC_MDF__c fr = SobjectRepository.getApprovedFundRequest();
            PRMTriggerClass.InitializeFlagVariables();

            Test.startTest();
            SFDC_MDF_Claim__c fc = (SFDC_MDF_Claim__c)new SobjectBuilder(SFDC_MDF_Claim__c.sObjectType)
                    .eagerPopulate()
                    .put(SFDC_MDF_Claim__c.Fund_Request__c, fr.Id)
                    .create()
                    .getRecord();

            PRMTriggerClass.InitializeFlagVariables();

            TestUtils.attachFile(fc.Id);
            fc.Status__c='Submitted';
            PRMTriggerClass.InitializeFlagVariables();
            //update fc;
            TestUtils.submitForApproval(fc);

            fc.Status__c='Approved - Reimburse';
            PRMTriggerClass.InitializeFlagVariables();
            update fc;

            fr = (SFDC_MDF__c)SobjectRepository.get(fr.Id);
            //testFundRequestClosing
            // all the funds on the FR have been used up. Its status should now be closed
            System.assert(fr.Status__c=='Closed', 'Fund Claim is approved but fund request is not in closed state yet:'+fr.Status__c);

            fc.Status__c='Paid';
            fc.Settlement_Method__c = 'Check';
            fc.PO_Number__c = '123';
            //SFDC-5962 Replacing Paid By (Paid_By__c) with Fund_Claim_Activity_Spender__c
            fc.Fund_Claim_Activity_Spender__c = 'Akamai';
            fc.Paid_Check_Number__c = 'SBI43920';
            fc.Invoice_Date_del__c = Date.today();
            fc.Claim_Paid_Date__c = Date.today();
            PRMTriggerClass.InitializeFlagVariables();
            update fc;

            SFDC_Budget__c b1 = SobjectRepository.getFundBudget();
            FundClaimCustomAllocationController fcca = new FundClaimCustomAllocationController();
            FundClaimCustomAllocationController.BudgetWrapper bw = new FundClaimCustomAllocationController.BudgetWrapper(b1);
            String throw1 = bw.sallocation;
            bw.sallocation = '45.0';

            Budget_Allocation__c fundClaimAllocation = (Budget_Allocation__c)new SObjectBuilder(Budget_Allocation__c.sObjectType)
                    .eagerPopulate()
                    .put(Budget_Allocation__c.Fund_Claim__c, fc.Id)
                    .put(Budget_Allocation__c.Budget__c, b1.Id)
                    .put(Budget_Allocation__c.Fund_Request__c, fr.Id)
                    .create()
                    .getRecord();

            // cancel fund request
            fr.Status__c='Cancelled';
            PRMTriggerClass.InitializeFlagVariables();
            update fr;
            // delete fund claim
            //PRMTriggerClass.InitializeFlagVariables();
            //delete fc;
            Test.stopTest();

        }



    static testmethod void testUtilMethodsFromUtilClass()
        {
            Map<String, CurrencyWrapper> currencyMap=Util.getCurrencies();
            SFDC_MDF__c fr = SobjectRepository.getApprovedFundRequest();
            Util.convertAmountToCorporateCurrency(currencyMap, fr);
            Util.getCorporateCurrency(currencyMap);

            System.assert(Util.isLevel3Partner('testAkamID')==false, 'This cant be a level 3 account surely!');
            Util.getSystemAdminProfileId();
            Util.getCsodSamlUrl();
            Util.getLunaProfilePageUrl();
            Util.getMyAkamaiDocLink();
            Util.getLunaPortalUrl();
            Util.getLunaIdpUrl();

            System.assertNotEquals(Util.isContactId(dmlUser.Id), true);
            System.assertNotEquals(Util.isUserId(dmlUser.Id), false);
            System.assertNotEquals(Util.isPartnerAdminProfile(dmlUser), true);

            String sampleJSON = '{"title": "Example Schema", "type": "object"}';
            Map<String, String> sampleMap = new Map<String, String>{ 't1' => 't2', 't3' => 't4' };
            List<String> sampleListOfStrings = new List<String>{'t1', 't2', 't3'};
            Util.convertJSONToMap(sampleJSON);
            Util.convertJSONToList(sampleJSON);
            Util.convertMapToJson(sampleListOfStrings);
            Util.convertMapToJson(sampleMap);
            List<SFDC_MDF__c> frs = new List<SFDC_MDF__c>{fr};
            Util.pluckField(frs, SFDC_MDF__c.Id);
            Util.pluckAsString(frs, SFDC_MDF__c.Id);
            Util.createCommunityAwareURL('http://akamai.my.salesforce.com/apex/somepage');
            Util.isLevel3Partner('string');
            Util.updateAndSaveLogs(frs, 'Content Version Tag Copy', true);
            Util.updateCronRunWithResult('Content Version Tag Copy', 'restul');
            Util.hasChangedTo('Id', fr, 'newvalue', 'contains');
            Util.hasChangedTo('Id', fr, 'newvalue', 'equals');
            Util.hasChangedFrom('Id', fr, 'newvalue', 'contains');
            Util.hasChangedFrom('Id', fr, 'newvalue', 'equals');
            Set<String> sampleSetOfStrings = new Set<String>{'Id'};
            Util.inClausify(sampleSetOfStrings);
            Boolean stringMatch = Util.stringContains('abc,bca,ucl','ucl');
        }


    //static testMethod void testFRToCampaignAssociationControllerNegative()
    //{
    //    // insert fr in draft state
    //    PageReference pageRef = Page.FRToCampaignAssociationPage;
    //    //Call the controller with blank id set in page.
    //    ApexPages.currentPage().getParameters().put('id','');
    //    Test.startTest();
    //    SFDC_MDF__c fundRequest = SobjectRepository.getSubmittedFundRequest();

    //    ApexPages.StandardController FRStdController = new ApexPages.standardController(fundRequest);
    //    FRToCampaignAssociationController extensionController = new FRToCampaignAssociationController(FRStdController);
    //    //Call the controller again with non existing id set in page.
    //    ApexPages.currentPage().getParameters().put('id','Test-00');
    //    extensionController = new FRToCampaignAssociationController(FRStdController);
    //    extensionController.saveCampaignID();
    //    Test.stopTest();
    //    //assert that the apex page has error message
    //    System.assert(ApexPages.hasMessages());
    //}

    static testMethod void testFRToCampaignAssociationControllerPositive()
        {
            SFDC_MDF__c fundRequest = SobjectRepository.getDraftFundRequest();
            Test.setCurrentPage(Page.FRToCampaignAssociationPage);
            ApexPages.currentPage().getParameters().put('id',fundRequest.Id);

            User frOwner = new User(Id=fundRequest.OwnerId);

            Test.startTest();
            Campaign cmpgn = (Campaign)new SobjectBuilder(Campaign.sObjectType).eagerPopulate().create().getRecord();


            System.runAs(frOwner)
                {
                    ApexPages.StandardController FRStdController = new ApexPages.standardController(fundRequest);
                    FRToCampaignAssociationController extensionController = new FRToCampaignAssociationController(FRStdController);
                    extensionController.pageObject.Fund_Request_Campaign__c = cmpgn.Id;

                    extensionController.saveCampaignID();
                    fundRequest = (SFDC_MDF__c)SobjectRepository.get(fundRequest.Id);
                    Test.stopTest();

                    extensionController.redirectToRequest();
                    System.assertEquals(fundRequest.Fund_Request_Campaign__c, cmpgn.Id);

                    delete fundRequest;
                    extensionController.saveCampaignID();
                }
        }
    //MOB-154
    static testMethod void testSF1EditFundRequestController()
        {
            SF1_EditFundRequestController.hasEditingRights(UserInfo.getUserId());
            Test.startTest(); //SFDC-5962
            SFDC_MDF__c draftFR = SobjectRepository.getDraftFundRequest();
            // testSaveObjIfNotSFDCSubmitted
            User fOwner = new User(Id=draftFR.OwnerId);
            System.runAs(fOwner)
                {
                    SF1_EditFundRequestController.saveObj(draftFR);
                    SF1_EditFundRequestController.getPageObject(draftFR.Id);
                }

            // SF1_EditFundRequestControllerTes.testSaveObjIfSFDCSubmitted
            SFDC_MDF__c submittedFR = SobjectRepository.getSubmittedFundRequest();
            // testCheckIfStatusSubmitted
            System.runAs(new User(Id=submittedFR.OwnerId))
                {
                    SF1_EditFundRequestController.checkIfStatusSubmitted(submittedFR.Id);
                    SF1_EditFundRequestController.saveObj(submittedFr);
                    SF1_EditFundRequestController.loadPickListValuesFromUtil('SFDC_MDF__c', 'SOE_or_PubSec_Event__c');
                }
            Test.stopTest(); // SFDC-5962
        }

    static testmethod void testSF1FundRequestService()
        {
            SF1_FundRequestAddPrivateNoteController.accessAllowedToCurrentUserProfile();

            SFDC_MDF__c draftFR = SobjectRepository.getDraftFundRequest();
            // testSaveObjIfNotSFDCSubmitted
            Test.startTest(); // SFDC-5962
            User fOwner = new User(Id=draftFR.OwnerId);
            System.runAs(fOwner)
                {
                    SF1_FundRequestAddPrivateNoteController.getPageObject(draftFR.Id);
                    SF1_FundRequestService.getPageObject(draftFR.Id);
                    SF1_FundRequestAddPrivateNoteController.saveNote(draftFR);
                    SF1_FundRequestService.saveNote(draftFR);
                    SF1_FundRequestService.getPageObjectForEditFundRequest(draftFR.Id);
                    SF1_FundRequestService.hasEditingRights(draftFR.Id);
                }
            Test.stopTest();// SFDC-5962
        }

    static testmethod void testCurrencyWrapper()
        {
            if( Util.isMultiCurrencyEnabled())
            {
                CurrencyType ct = SobjectRepository.getCurrencyType();
                CurrencyWrapper obj=new CurrencyWrapper(ct);
                obj.getDecimalPlaces();
                obj.getConversionRate();
                obj.isCorporateCurrency();
                obj.getIsoCode();

                System.assertEquals(ct.get('DecimalPlaces'), obj.getDecimalPlaces());
            }

        }

    /*static testmethod void testFundRequestButtonPageController()
        {
            system.runas(dmlUser)
                {
                    SFDC_MDF__c fr = SobjectRepository.getDraftFundRequest();
                    List<User> paeUsers = SObjectRepository.getSalesPAEUsers(1);
                    fr.Partner_Account_Owner__c = paeUsers[0].Id;
                    update fr;
                    // mark master mc as inactive
                    test.startTest(); // SFDC-5962
                    Channel_Mapping__c cm = SobjectRepository.getMasterChannelMapping();
                    cm.Master_Channel_Mapping__c= false;

                    update cm;

                    User frOwner = new User(Id=fr.Partner_Account_Owner__c, IsActive=false);
                    update frOwner;
                    Test.setCurrentPage(Page.FundRequestButtonPage);
                    ApexPages.currentPage().getParameters().put('fromButton','SubmitForApproval');
                    ApexPages.currentPage().getParameters().put('recordId',fr.Id);
                    ApexPages.currentPage().getParameters().put('userProfileId',UserInfo.getProfileId());

                    FundRequestButtonPageController frbpc = new FundRequestButtonPageController();

                    PageReference pageRef = frbpc.init();
                    fr = [Select Id,Status__c from SFDC_MDF__c where id=:fr.Id];
                    //System.assert(fr.Status__c=='Draft', 'Fund request got submitted even though account owner is inactive');

                    frbpc.associateToCampaign();
                    frbpc.backToFundRequest();
                    Test.stopTest();
                }
        }*/ 

    static testmethod void testFundRequestEditBeforeApprovalControllerPositive()
        {

            System.runAs(dmlUser)
                {
                    Test.startTest();
                    SFDC_MDF__c fundRequest = SobjectRepository.getSubmittedFundRequest();

                    FundRequestEditBeforeApprovalController extensionController;
                    User scmOwnerUser = new User(Id=fundRequest.OwnerId);
                    System.runAs(scmOwnerUser)
                        {
                            //only constructor needs to be run as scmOwner
                            //not the save method
                            Test.setCurrentPage(Page.FundRequestEditBeforeApproval);
                            ApexPages.currentPage().getParameters().put('id',fundRequest.Id);
                            ApexPages.StandardController FRStdController = new ApexPages.standardController(fundRequest);
                            extensionController = new FundRequestEditBeforeApprovalController(FRStdController);
                        }

                    extensionController.pageObject = fundRequest;
                    extensionController.pageObject.Total_Activity_Event_Cost__c= 25;

                    extensionController.save();
                    Test.stopTest();
                    List<ApexPages.Message> msgList = ApexPages.getMessages();
                    fundRequest = [select Id, Total_Activity_Event_Cost__c from SFDC_MDF__c where id=:fundRequest.Id];
                    System.assertEquals(fundRequest.Total_Activity_Event_Cost__c, 25);
                    //Have coverage for cancel also
                    extensionController.cancel();
                }
        }
    //SFDC-2572
    static testmethod void testUtilCoverage1(){
        SFDC_MDF__c fr = SobjectRepository.getApprovedFundRequest();
        PRMTriggerClass.InitializeFlagVariables();

        Test.startTest();
        SFDC_MDF_Claim__c fc = (SFDC_MDF_Claim__c)new SobjectBuilder(SFDC_MDF_Claim__c.sObjectType)
                .eagerPopulate()
                .put(SFDC_MDF_Claim__c.Fund_Request__c, fr.Id)
                .create()
                .getRecord();

        PRMTriggerClass.InitializeFlagVariables();

        Util.submitForApproval(fc.id,'test approval');

    }

    static testMethod void testUtilCoverage2(){
        Account testAccount = utilTestClass.CreateAccount('Test Account');
        test.startTest();  // SFDC-5962
        insert testAccount;
        Opportunity testOppty = utilTestClass.CreateOpportunity('Test Oppty','1-Create');
        testOppty.AccountId = testAccount.Id;
        testOppty.CloseDate = Date.today();
        insert testOppty;
        test.stopTest();
        List<SObject> sObjectList = new List<SObject>{testOppty};

        SObject opptySObject = (SObject)testOppty;

        String result = Util.updateAndSaveLogs(sObjectList,'Update Oppty Forecast Count',true);

    }

    static testmethod void testFundRequestEditBeforeApprovalControllerNegative()
        {
            SFDC_MDF__c fundRequest = SobjectRepository.getSubmittedFundRequest();
            User scmOwnerUserWhoDoesntHaveRights = SobjectRepository.getSalesPAEUsers(1)[0];
            Test.startTest();
            System.runas(scmOwnerUserWhoDoesntHaveRights)
                {
                    Test.setCurrentPage(Page.FundRequestEditBeforeApproval);
                    ApexPages.currentPage().getParameters().put('id',fundRequest.Id);
                    ApexPages.StandardController FRStdController = new ApexPages.standardController(fundRequest);
                    FundRequestEditBeforeApprovalController extensionController = new FundRequestEditBeforeApprovalController(FRStdController);
                    TestUtils.verifyPageMessageDisplayed('You dont have the editing rights');
                }

        }
    static testmethod void testBudgetShareAndFundRequestShare()
        {
            // SobjectRepository.getPartnerUser() is not returning the correct user

            List<SFDC_Budget__c> fbs = new List<SFDC_Budget__c>();
            List<SFDC_MDF__c> frs = new List<SFDC_MDF__c>();

            System.runAs(dmlUser)
                {
                    fbs = SobjectRepository.getFundBudgets(numberOfFundBudgets);
                    frs = SobjectRepository.getFundRequests(1);
                    // test budget controller
                    BudgetController bc1 = new BudgetController();
                    FundRequestCustomController fc = new FundRequestCustomController();

                    System.assert(fbs.size()==numberOfFundBudgets, 'Fund budget not created - '+fbs.size());
                    System.assert(frs.size()==1, 'Fund Request not created ');
                }
        }

    static testmethod void testGsmUtilClass()
        {
            SFDC_MDF__c fundRequest = SobjectRepository.getApprovedFundRequest();
            Map<string,string> prmMDFMap = GsmUtilClass.getPRMSettingKeyValue('MDF_');
            String fundRequestId=fundRequest.Id;
            Set<Id> fieldID=new Set<Id>{fundRequest.Account__c};
            GsmUtilClass.getClaimedAmtsForAGivenFundRequest(fundRequestId);
            GsmUtilClass.getClaimedAmtsForAGivenFundRequest(fieldID);
            GsmUtilClass.getAccountIdentityFieldName(prmMDFMap);
            GsmUtilClass.getClaimedAmtsForAGivenFundRequest(fieldID);
            Set<String> accountNameSet=new Set<String>{fundRequest.Account__c};
            Set<Id> accountIdSet = new Set<Id>{fundRequest.Account__c};
            GsmUtilClass.getAccountDetailsGivenNames( accountNameSet, prmMDFMap);
            GsmUtilClass.getAccountDetailsGivenIds(accountIdSet, prmMDFMap);
            string fieldName='id';
            Boolean res = GsmUtilClass.isAccountIdentityNumber(fieldName);
            System.assert(!res,'Success');
            Test.startTest();
            GsmUtilClass.buildInExpression(accountNameSet, prmMDFMap);
            GsmUtilClass.buildInExpression(fieldID);
            GsmUtilClass.getAccountRegions(fieldID,prmMDFMap);
            //GsmUtilClass.checkValidationFundRequired(account, prmMDFMap);
            GsmUtilClass.getMaxSequenceForGivenAccounts(fieldID,'FC');
            GsmUtilClass.getAvlBudgetForGivenAccounts(fieldID);
            List<SFDC_Budget__c> listOfSampleBudgets = SobjectRepository.get(SFDC_Budget__c.sObjectType, 5);
            GsmUtilClass.getEarliestFCDeadlineFromListOfBudgetsOrBudgetAllocations(listOfSampleBudgets);
            GsmUtilClass.getAccountRegions(accountIdSet,prmMDFMap);
            test.stopTest();
        }

    static testmethod void testDistributorMDF()
        {
            // insert SFDC_MDF_Claim__Share
            // insert SFDC_Budget__Share
            SFDC_MDF__c fr = SobjectRepository.getApprovedFundRequest();
            PRMTriggerClass.InitializeFlagVariables();

            Test.startTest();
            SFDC_MDF_Claim__c fc = (SFDC_MDF_Claim__c)new SobjectBuilder(SFDC_MDF_Claim__c.sObjectType)
                    .eagerPopulate()
                    .put(SFDC_MDF_Claim__c.Fund_Request__c, fr.Id)
                    .create()
                    .getRecord();

            PRMTriggerClass.InitializeFlagVariables();
            TestUtils.attachFile(fc.Id);
            TestUtils.submitForApproval(fc);

            fc = (SFDC_MDF_Claim__c)SobjectRepository.get(fc.Id);

            Map<Id, Id> fbAccountIdMap = new Map<Id, Id>();
            Map<Id, Id> frAccountIdMap = new Map<Id, Id>();
            Map<Id, Id> fcAccountIdMap = new Map<Id, Id>();



            List<SFDC_Budget__Share> budgetShareList1= new List<SFDC_Budget__Share>();
            SFDC_Budget__Share share= new SFDC_Budget__Share();

            List<SFDC_Budget__c> budgetlist=SobjectRepository.get(SFDC_Budget__c.sObjectType, 3);
            for (SFDC_Budget__c budget : budgetlist)
                {
                    fbAccountIdMap.put(budget.Id, budget.Account__c);
                }

            FundBudgetShares.removeFundBudgetShare(fbAccountIdMap);
            FundBudgetShares.createFBShare(fbAccountIdMap);
            List <SFDC_MDF__c> fundRequestList =SobjectRepository.get(SFDC_MDF__c.sObjectType, 5);
            for (SFDC_MDF__c fundRequest : fundRequestList)
                {
                    if(fundRequest!=null && fundRequest.Account__c!=null)
                    {
                        frAccountIdMap.put(fundRequest.Id, fundRequest.Account__c);
                    }
                }
            FundBudgetShares.createFRShare(frAccountIdMap);

            List<SFDC_MDF_Claim__c> fundClaimList=SobjectRepository.get(SFDC_MDF_Claim__c.sObjectType, 2);
            for (SFDC_MDF_Claim__c fundClaim : fundClaimList) {
                fcAccountIdMap.put(fundClaim.Id, fundClaim.Account__c);
            }

            FundBudgetShares.createFCShare(fcAccountIdMap);

            List<Account> accs= SobjectRepository.get(Account.sObjectType, 1);

            Set<Id> distiAccountIds = new Set<Id>();
            List<Account> accountList = new List<Account>();
            for(Account ac : accs)
                {
                    distiAccountIds.add(ac.Id);
                    accountList.add(ac);
                }


            Map<Id, Id> accountIdUserRoleIdMap = SharingUtil.getRoles(distiAccountIds);
            Map<Id,Id> gMap = SharingUtil.getGroups(accountIdUserRoleIdMap.values());
            FundBudgetShares.removeFundRequestShare(gMap);
            FundBudgetShares.removeFundClaimShare(gMap);

            CreatePartnerShare.runOnce();
            CreatePartnerShare.addToShare(budgetlist.get(0).id, accountList.get(0).id, accountIdUserRoleIdMap, gMap, 'BUDGET');
            CreatePartnerShare.addToShare(fundRequestList.get(0).id, accountList.get(0).id, accountIdUserRoleIdMap, gMap, 'FUND_REQUEST');
            CreatePartnerShare.addToShare(fundClaimList.get(0).id, accountList.get(0).id, accountIdUserRoleIdMap, gMap, 'FUND_CLAIM');

            Test.stopTest();


        }

    static testMethod void testFundRequestAddPrivateNoteController()
        {
            SFDC_MDF__c fundRequest = SobjectRepository.getDraftFundRequest();
            Test.startTest();
            Test.setCurrentPage(Page.FundRequestAddPrivateNote);
            ApexPages.currentPage().getParameters().put('id','');
            ApexPages.StandardController FRStdController = new ApexPages.standardController(fundRequest);
            FundRequestAddPrivateNoteController extensionController = new FundRequestAddPrivateNoteController(FRStdController);
            List<ApexPages.Message> msgList = ApexPages.getMessages();
            for(ApexPages.Message msg :  ApexPages.getMessages())
                {
                    System.assertEquals('Error: No Fund Request ID specified.', msg.getSummary());
                    System.assertEquals(ApexPages.Severity.ERROR, msg.getSeverity());
                }
            ApexPages.currentPage().getParameters().put('id', fundRequest.Id);

            String privateNote = 'Some important note';
            extensionController.pageObject = fundRequest;
            extensionController.pageObject.Private_Note__c = privateNote;

            extensionController.savePrivateNote();
            fundRequest = [select Id, Private_Note__c from SFDC_MDF__c where id=:fundRequest.Id];
            System.assertEquals(fundRequest.Private_Note__c, privateNote);
            Test.stopTest();

        }

    static testMethod void testFundClaimAddPrivateNoteController()
        {
            SFDC_MDF__c fr = SobjectRepository.getApprovedFundRequest();
            PRMTriggerClass.InitializeFlagVariables();

            Test.startTest();
            SFDC_MDF_Claim__c fundClaim = (SFDC_MDF_Claim__c)new SobjectBuilder(SFDC_MDF_Claim__c.sObjectType)
                    .eagerPopulate()
                    .put(SFDC_MDF_Claim__c.Fund_Request__c, fr.Id)
                    .create()
                    .getRecord();

            PRMTriggerClass.InitializeFlagVariables();

            TestUtils.attachFile(fundClaim.Id);
            PRMTriggerClass.InitializeFlagVariables();
            TestUtils.submitForApproval(fundClaim);
            Test.setCurrentPage(Page.FundClaimAddPrivateNote);
            ApexPages.currentPage().getParameters().put('id','');
            ApexPages.StandardController FCStdController = new ApexPages.standardController(fundClaim);
            FundClaimAddPrivateNoteController extensionController = new FundClaimAddPrivateNoteController(FCStdController);
            List<ApexPages.Message> msgList = ApexPages.getMessages();
            for(ApexPages.Message msg :  ApexPages.getMessages())
                {
                    System.assertEquals('Error: No Fund Claim ID specified.', msg.getSummary());
                    System.assertEquals(ApexPages.Severity.ERROR, msg.getSeverity());
                }
            ApexPages.currentPage().getParameters().put('id', fundClaim.Id);
            ApexPages.StandardController fc2 = new ApexPages.StandardController(fundClaim);
            FundClaimAddPrivateNoteController e2 = new FundClaimAddPrivateNoteController(fc2);

            String privateNote = 'Some important note';
            e2.pageObject = fundClaim;
            e2.pageObject.Private_Note__c = privateNote;

            e2.savePrivateNote();
            fundClaim = [select Id, Private_Note__c from SFDC_MDF_Claim__c where id=:fundClaim.Id];
            System.assertEquals(fundClaim.Private_Note__c, privateNote);

            e2.redirectToFundClaim();
            Test.stopTest();

        }
    static testMethod void FundRequestReserveClose()
        {
            SFDC_MDF__c fr = SobjectRepository.getApprovedFundRequest();
            PRMTriggerClass.InitializeFlagVariables();
            Test.startTest();
            SFDC_MDF_Claim__c fc = (SFDC_MDF_Claim__c)new SobjectBuilder(SFDC_MDF_Claim__c.sObjectType)
                    .eagerPopulate()
                    .put(SFDC_MDF_Claim__c.Fund_Request__c, fr.Id)
                    .create()
                    .getRecord();

            PRMTriggerClass.InitializeFlagVariables();

            TestUtils.attachFile(fc.Id);
            fc.Status__c='Submitted';
            PRMTriggerClass.InitializeFlagVariables();
            //update fc;
            TestUtils.submitForApproval(fc);

            ApexPages.StandardController sc = new ApexPages.StandardController(fr);
            MDFReserveClosedController fruc = new MDFReserveClosedController(sc);
            fruc.ReserveClosedRequest();
            fr=(SFDC_MDF__c)SobjectRepository.get(fr.Id);
            system.assert(fr.Reserve_Closed__c);
            for(Budget_Allocation__c ba:[select Reserve_Closed__c from Budget_Allocation__c where Fund_Request__c=:fr.id])
                system.assert(ba.Reserve_Closed__c);
            sc = new ApexPages.StandardController(fr);
            fruc = new MDFReserveClosedController(sc);
            fruc.back();
            Test.stopTest();

        }
    static testMethod void FundRequestBudgetAllocationNegative()
        {
            System.runAs(dmlUser)
                {
                    SFDC_MDF__c fr= SobjectRepository.getSubmittedFundRequest();
                    List<SFDC_Budget__c> budgets = SobjectRepository.get(SFDC_Budget__c.sObjectType, 2*numberOfFundBudgets);

                    delete budgets;
                    PRMTriggerClass.InitializeFlagVariables();
                    fr.Status__c='Approved';
                    Boolean noAllocationErrorShown = false;
                    try
                    {
                        PRMTriggerClass.InitializeFlagVariables();
                        update fr;
                    }
                    catch(Exception e)
                    {
                        // System.assert(e.getMessage().contains(Label.No_Allocations_Msg)); //SFDC-5962
                        noAllocationErrorShown = true;
                    }

                    System.assert(noAllocationErrorShown==true, 'Fund Request got approved even though it had no allocatinos');
                }
        }
    static testMethod void testFundClaimDeadlineMailer()
        {
            SFDC_MDF__c fr = SobjectRepository.getApprovedFundRequest();
            fr.Activity_Date__c = Date.today();
            fr.Program_End_Date__c = Date.today();
            fr.Validation_Override__c = true;
            test.startTest(); // SFDC-5962
            PRMTriggerClass.InitializeFlagVariables();
            update fr;

            fr = (SFDC_MDF__c)SobjectRepository.get(fr.Id);

            User frOwner = new User(Id=fr.OwnerId, email='fdajk@akamai.com');
            update frOwner;

            String str = FundClaimDeadlineMailer.sendMails();
            fr = (SFDC_MDF__c)SobjectRepository.get(fr.Id);
            test.stopTest();
            system.assert(true==str.contains('No. of emails to be sent -'), 'Fund claim deadline mailer result:'+str+ ' and fr is'+fr);
        }


/*Removed as part of SFDC-6979
    static testmethod void testFCApprovalHistoryController()
        {
            // also contains testFCAllocationsDelete
            SFDC_MDF__c fr = SobjectRepository.getApprovedFundRequest();
            PRMTriggerClass.InitializeFlagVariables();
            Test.startTest();
            SFDC_MDF_Claim__c fc = (SFDC_MDF_Claim__c)new SobjectBuilder(SFDC_MDF_Claim__c.sObjectType)
                    .eagerPopulate()
                    .put(SFDC_MDF_Claim__c.Fund_Request__c, fr.Id)
                    .create()
                    .getRecord();

            PRMTriggerClass.InitializeFlagVariables();

            TestUtils.attachFile(fc.Id);
            PRMTriggerClass.InitializeFlagVariables();
            TestUtils.submitForApproval(fc);

            PageReference pageRef = Page.FC_ApprovalHistory;
            Test.setCurrentPageReference(pageRef);
            pageRef.getParameters().put('id', fc.id);
            ApexPages.StandardController sc = new ApexPages.StandardController(fc);
            FCApprovalHistoryController fruc = new FCApprovalHistoryController(sc);
            SFDC_Budget__c fb = SobjectRepository.getFundBudget();
            Budget_Allocation__c ba = (Budget_Allocation__c)new SobjectBuilder(Budget_Allocation__c.sObjectType)
                    .eagerPopulate()
                    .put(Budget_Allocation__c.Amount__c, 10)
                    .put(Budget_Allocation__c.Budget__c, fb.Id)
                    .put(Budget_Allocation__c.Fund_Claim__c, fc.Id)
                    .create()
                    .getRecord();

            fc = (SFDC_MDF_Claim__c)SobjectRepository.get(fc.Id);
            Test.stopTest();
            System.assert(fc.Fund_Request_Approved_Amount__c>0, 'Approved amount is still 0 on fc even though allocation was created'+fc);
        }
*/

    static testmethod void testFRAllocationsDelete()
        {
            SFDC_MDF__c fr = SobjectRepository.getSubmittedFundRequest();
            SFDC_Budget__c fb = SobjectRepository.getFundBudget();
            // create budget allocation with reserved recordtpe and update Funding_Approved__c on fr
            PRMTriggerClass.InitializeFlagVariables();
            Budget_Allocation__c ba = (Budget_Allocation__c)new SobjectBuilder(Budget_Allocation__c.sObjectType)
                    .eagerPopulate()
                    .put(Budget_Allocation__c.Amount__c, 10)
                    .put(Budget_Allocation__c.Fund_Request__c, fr.Id)
                    .put(Budget_Allocation__c.Budget__c, fb.Id)
                    .create()
                    .getRecord();

            Test.startTest(); // SFDC 5962
            fr =(SFDC_MDF__c) SobjectRepository.get(fr.Id);
            System.assert(fr.Funding_Approved__c==null, 'Inserting allocations increases funding approved on fr'+fr);

            delete ba;

            fr =(SFDC_MDF__c) SobjectRepository.get(fr.Id);
            System.assert(Integer.valueOf(fr.Funding_Approved__c)<0, 'Funding approved is still 0 even after deleting allocations'+fr.Funding_Approved__c+ ' and status:'+fr.Status__c);
            Test.stopTest(); // SFDC 5962
        }

    static testMethod void testFundAccuralTrigger()
        {
            Test.startTest();
            Account partAccount = SobjectRepository.getPartnerAccount();
            List<SFDC_Budget__c> fbs = new List<SFDC_Budget__c>();

            fbs = SobjectRepository.getFundBudgets(2*numberOfFundBudgets);
           // System.assert(fbs.size()==numberOfFundBudgets, 'Partner cannot see fund budgets - '+fbs.size()); //taruni

            delete fbs;
            fbs = SobjectRepository.getFundBudgets(2*numberOfFundBudgets);
            System.assert(fbs.size()==0, 'Budgets have not been deleted'+fbs.size());
            PRMTriggerClass.InitializeFlagVariables();
            // create accural
            SFDC_Fund_Accural__c fa = (SFDC_Fund_Accural__c)new SobjectBuilder(SFDC_Fund_Accural__c.sObjectType)
                    .put(SFDC_Fund_Accural__c.Account_Name__c, partAccount.Id)
                    .put(SFDC_Fund_Accural__c.Account_Match_Id__c, String.valueOf(partAccount.Id).substring(0,15))
                    .put(SFDC_Fund_Accural__c.Account__c, partAccount.Id)
                    .put(SFDC_Fund_Accural__c.End_Earned_Date__c, Date.today().addDays(70))
                    .create()
                    .getRecord();


            fbs = SobjectRepository.getFundBudgets(2*numberOfFundBudgets);

            // accural should create fund budget
            System.assert(fbs.size()==1, 'Accurals have not created any fund budgets '+fbs.size());

            fa.Revenue__c = 50;
            update fa;
            Test.stopTest();

        }

    static testmethod void testEarliestFCDeadline()
        {
            SFDC_MDF__c fr = SobjectRepository.getDraftFundRequest();

            System.assertEquals(fr.Fund_Request_Approver__c, null);
            Test.startTest();
            Pagereference pageRef = Page.FCMselectionpage;
            pageRef.getParameters().put('fr', fr.id);
            Test.setCurrentPageReference(pageRef);
            FCM_page_controller fpc = new FCM_page_controller();
            fpc.init();
            fpc.getItems();
            fpc.checkForNoFCM();
            fpc.setCountry(fr.OwnerId);
            fpc.getCountry();
            PRMTriggerClass.InitializeFlagVariables();
            fpc.updateoppty();
            fr = (SFDC_MDF__c) SobjectRepository.get(fr.Id);

            System.assertEquals(fr.Status__c, 'Submitted');
            System.assertNotEquals(fr.Earliest_FC_Deadline__c, null);
            fr.Status__c='Approved';
            PRMTriggerClass.InitializeFlagVariables();
            update fr;
            fr = (SFDC_MDF__c) SobjectRepository.get(fr.Id);
            //make sure the earliest FC Deadline is now updated
            System.assert(fr.Earliest_FC_Deadline__c!=null, 'Earliest_FC_Deadline__c is still :'+fr.Earliest_FC_Deadline__c+' with status'+fr.Status__c);

            //lower the deadline

            Date earliestFCDeadline = date.newinstance(2016, 12, 31);
            SFDC_Budget__c fb = SobjectRepository.getFundBudget();
            fb.Fund_Claim_DeadLine__c = earliestFCDeadline;
            fb.Validation_Override__c = true;
            PRMTriggerClass.InitializeFlagVariables();
            update fb;
            Test.stopTest();
            fb = (SFDC_Budget__c)SobjectRepository.get(fb.Id);
            System.assert(fb.Fund_Claim_DeadLine__c!=null, 'fund claim deadline did not update'+fb.Fund_Claim_DeadLine__c);
        }

    static testMethod void testFundRequestUtilityControllerNegative()
        {
            // submitted fr
            SFDC_MDF__c fr= SObjectRepository.getSubmittedFundRequest();
            Test.startTest(); // SFDC-5962
            Test.setCurrentPageReference(Page.cancelFundRequest);
            ApexPages.StandardController sc = new ApexPages.StandardController(fr);
            fundRequestUtilityController fruc = new fundRequestUtilityController(sc);
            fr = SobjectRepository.getApprovedFundRequest();
            PRMTriggerClass.InitializeFlagVariables();


            SFDC_MDF_Claim__c fc = (SFDC_MDF_Claim__c)new SobjectBuilder(SFDC_MDF_Claim__c.sObjectType)
                    .eagerPopulate()
                    .put(SFDC_MDF_Claim__c.Fund_Request__c, fr.Id)
                    .create()
                    .getRecord();

            PRMTriggerClass.InitializeFlagVariables();

            TestUtils.attachFile(fc.Id);
            TestUtils.submitForApproval(fc);

            fruc.cancelRequest();
            Test.setCurrentPageReference(Page.cancelFundRequest);
            fr = (SFDC_MDF__c) SobjectRepository.get(fr.Id);
            sc = new ApexPages.StandardController(fr);
            fruc = new fundRequestUtilityController(sc);
            fruc.cancelRequest();
            System.assert(fr.Status__c!='Cancelled', 'Fund request was not cancelled because claim was created against it'+fr);
            Test.setCurrentPageReference(Page.cancelFundRequest);
            fruc.back();
            Test.stopTest();
            RequestAndClaimUtility.cancelFundRequest(fr,null, new List<SFDC_MDF_Claim__c>{fc},null);
        }
    public  static testMethod void testFundRequestAllocationController()
        {
            //run the allocation controller
            SFDC_MDF__c request = SobjectRepository.getSubmittedFundRequest();
            ApexPages.StandardController sc = new ApexPages.StandardController(request);
            FundRequestAllocationController frac = new fundRequestAllocationController(sc);
            list<SFDC_Budget__c> budgets = frac.getBudgets();
            frac.updateTotal();
            list<FundRequestAllocationController.BudgetWrapper> bwList= frac.getbwList();
            //test no funding approved
            frac.request.Funding_Approved__c = 0;
            frac.totalreserved.Amount__c = frac.request.Funding_Approved__c;
            update frac.request;
            Test.startTest();
            PageReference checkRequest = frac.validateAllocations();
            frac.saveAllocations();
            frac.searchReserved();
            frac.getbwList();
            frac.updateTotal();
            System.assert(!frac.success, 'ERROR: Saved incorrectly.');
            frac.allocate();
            frac.totalBudget = 0;
            for(FundRequestAllocationController.BudgetWrapper bb:frac.bwList) {
                bb.tempAllocation=5;
                bb.b.Account__c = null;
                frac.totalBudget += bb.b.Available_Budget__c;
                bb.sallocation = '50.50';
                String tt = bb.sallocation;

            }
            frac.totalallocation.Amount__c = 0;
            checkRequest = frac.validateAllocations();
            //approve funding and test greater condition
            frac.request.Funding_Approved__c = null;

            checkRequest = frac.validateAllocations();
            System.assert(!frac.success, 'ERROR: Saved incorrectly.');

            frac.request.Amount__c = 100000;
            frac.request.Funding_Approved__c = 1111110;
            for(FundRequestAllocationController.BudgetWrapper bb:frac.bwList) {
                bb.tempAllocation=0;
            }

            checkRequest = frac.validateAllocations();
            frac.request.Amount__c = 0;
            checkRequest = frac.validateAllocations();

            //reduce funding approved and test total allocation amount
            frac.request.Funding_Approved__c = 100000;

            frac.request.Amount__c = 100000;
            for (SFDC_Budget__c testb : budgets) {
                testb.Temp_Allocation__c = 150000;
            }
            frac.tempAllocation = 40.0;
            Double tt = frac.tempAllocation;
            checkRequest = frac.validateAllocations();
            System.assert(!frac.success, 'ERROR: Improper save.');

            PageReference checkRequest1 = frac.saveAllocations();
            System.assert(checkRequest1==null,'');
            //test lesser condition
            for (SFDC_Budget__c testb : budgets) {
                testb.Temp_Allocation__c = 20000;
            }

            checkRequest = frac.validateAllocations();

            System.assert(!frac.success, 'ERROR: Save failed.');

            PageReference cancelRequest = frac.cancelAllocations();

            RequestAndClaimUtility.cancelFundRequest(request,null);

            Test.stopTest();

        }

    static testMethod void testFundRequestUtilityControllerPositive()
        {
            //load the controller and cancel the request
            SFDC_MDF__c fr = SobjectRepository.getDraftFundRequest();
            ApexPages.StandardController sc = new ApexPages.StandardController(fr);
            FundRequestUtilityController fruc = new FundRequestUtilityController(sc);
            Test.startTest();
            fruc.cancelRequest();
            fr = (SFDC_MDF__c)SobjectRepository.get(fr.Id);

            System.assert(fr.Status__c == 'Cancelled','ERROR: Status was ' +fr.Status__c + 's/b Cancelled');

            fr = SobjectRepository.getApprovedFundRequest();
            PRMTriggerClass.InitializeFlagVariables();

            SFDC_MDF_Claim__c fc = (SFDC_MDF_Claim__c)new SobjectBuilder(SFDC_MDF_Claim__c.sObjectType)
                    .eagerPopulate()
                    .put(SFDC_MDF_Claim__c.Fund_Request__c, fr.Id)
                    .create()
                    .getRecord();

            PRMTriggerClass.InitializeFlagVariables();

            TestUtils.attachFile(fc.Id);
            TestUtils.submitForApproval(fc);

            //try to cancel the request again
            fr = (SFDC_MDF__c)SobjectRepository.get(fr.Id);
            System.assert(fr.Status__c == 'Approved','ERROR: Status was ' + fr.Status__c + ' s/b Draft');
            sc = new ApexPages.StandardController(fr);
            fruc = new FundRequestUtilityController(sc);
            fruc.cancelRequest();
            //Anand - Shouldnt be cancelled since an FC is associated to this
            fr =(SFDC_MDF__c) SobjectRepository.get(fr.Id);
            System.assert(fr.Status__c == 'Approved','ERROR: Status was ' + fr.Status__c + 's/b Draft');
            Test.stopTest();
        }





    static testMethod void testFundClaimAllocationController()
        {
            SFDC_MDF__c fr = SobjectRepository.getApprovedFundRequest();
            PRMTriggerClass.InitializeFlagVariables();
            Test.startTest();
            SFDC_MDF_Claim__c fc = (SFDC_MDF_Claim__c)new SobjectBuilder(SFDC_MDF_Claim__c.sObjectType)
                    .eagerPopulate()
                    .put(SFDC_MDF_Claim__c.Fund_Request__c, fr.Id)
                    .create()
                    .getRecord();

            PRMTriggerClass.InitializeFlagVariables();
            TestUtils.attachFile(fc.Id);
            TestUtils.submitForApproval(fc);
            fc.Status__c = 'Approved - Internal';
            //SFDC-5962 Replacing Paid By (Paid_By__c) with Fund_Claim_Activity_Spender__c
            fc.Fund_Claim_Activity_Spender__c = 'Akamai';
            fc.PO_Number__c = 'po450';
            fc.Transfer_Account__c = 'my account';
            fc.Claim_Paid_Date__c = Date.today();
            fc.Invoice_Date_del__c = Date.today();
            fc.Paid_Check_Number__c = '3254354';
            fc.Settlement_Method__c = 'Check';
            fc.Amount_In_Corporate_Currency__c = 100;

            PRMTriggerClass.InitializeFlagVariables();
            update fc;

            // Approved_Claims__c
            // query tasks
            // Task test case for approval
            List<Task> tasks = SobjectRepository.getTasks(new List<Id>{fc.Id});
            //Anand Hegde - Task should be created irrespective of who its paid by
            System.assertEquals(tasks.size(),1);
            //SFDC-5962 Replacing Paid By (Paid_By__c) with Fund_Claim_Activity_Spender__c
            fc = (SFDC_MDF_Claim__c)(SobjectRepository.get(SFDC_MDF_Claim__c.sObjectType, 'Id, Name, Amount__c,Paid_Check_Number__c,Claim_Paid_Date__c,Settlement_Method__c, Approved_Amount__c, Performance_Attached__c, Performance_Verified__c, Performance_Verified_Date__c, Fund_Claim_Activity_Spender__c, CreatedDate, Fund_Request__c, Fund_Request__r.Account__c,PO_Number__c,Transfer_Account__c, Invoice_Date_del__c, Amount_In_Corporate_Currency__c, Fund_Request_Approved_Amount__c', 1)[0]);
            ApexPages.StandardController sc = new ApexPages.StandardController(fc);
            fundClaimAllocationController fcac = new fundClaimAllocationController(sc);
            fcac.updateTotal();

            PageReference cancelRequest = fcac.cancelAllocations();
            System.assertEquals(new PageReference('/'+fc.Id).getURL(), cancelRequest.getUrl());
            PageReference checkRequest = fcac.saveAllocations();

            fcac.searchClaimed();
            fcac.saveClaimPaymentInfo();
            fcac.claim.Approved_Amount__c = 9000;
            fcac.validateAllocations();
            fcac.payClaimValidate();
            fcac.allocate();
            fcac.cancelAllocations();
            fcac.checkCreditHold();
            fcac.saveClaimPaymentInfo();
            fcac.searchBudgets();
            fcac.validateAllocations();

            Test.stopTest();
        }

    // TODO write tests on non USD currency

}