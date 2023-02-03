@isTest(seeAllData = false)
 private class PartnerTransactionsTests
{

   
    static User dmlUser = new User(id=UserInfo.getUserId());

    @testSetUp static void insertCustomSettingsAndCreateData()
    {
        Test.startTest();
        System.runAs(utilTestClass.getTestRunUser())
        {
            new SobjectBuilder(Environment_Setup__c.sObjectType)
            .put(Environment_Setup__c.Environment_Type__c, 'Primary')
            .put(Environment_Setup__c.Active_Org__c, true)
            .put(Environment_Setup__c.Akam_Id_Start_String__c, 'F-')
            .create();

            new SObjectBuilder(Features_Toggle__c.sObjectType)
                .put(Features_Toggle__c.name, 'isCronErrorMailViaCode')
                .put(Features_Toggle__c.Toggle__c, false)
                .create();

            new SObjectBuilder(PRM_Settings__c.sObjectType)
                .put(PRM_Settings__c.name, 'NonLitePermissionSets')
                .put(PRM_Settings__c.Value__c, 'Has_DealRegistration_Access__c,Has_PartnerPlans_Access__c')
                .create();

            SObjectFactory.createPartnerUsers(1);
            User partnerUser = SobjectRepository.getPartnerUser();
             // create master CM for MDF_Approver__c
            SobjectFactory.createDealRegUnsubmitted(partnerUser.Contact.AccountId);
            
            
        }
        Test.stopTest();
    }


    // provides coverage to genericButtonPageController , PartnerProfileTriggerClass
    static testmethod void testPartnerProfileCreationAndSubmission()
    {

        User partnerUser = SobjectRepository.getPartnerUser();

        Partner_Profile__c pp;
        System.assert(partnerUser.Contact.AccountId!=null, 'partner user doesnt have contact:'+partnerUser.Contact.AccountId);
        Test.startTest();
        genericButtonPageController gp2= new genericButtonPageController();
        System.runAs(partnerUser)
        {
            pp = (Partner_Profile__c)new SobjectBuilder(Partner_Profile__c.sObjectType)
                .eagerPopulate()
                .put(Partner_Profile__c.Partner_Account_Name__c, partnerUser.Contact.AccountId)
                .create()
                .getRecord();

            System.assert(pp.Id!=null, 'wut'+pp);
            PageReference pageRef = Page.genericButtonpage;
            Test.setCurrentPageReference(pageRef);
            ApexPages.currentPage().getParameters().put('recordId',pp.Id);
            ApexPages.currentPage().getParameters().put('fromButton','SubmitPartner');
            genericButtonPageController gp= new genericButtonPageController();
            gp.recordId=pp.Id;
            gp.init();

            pp = SobjectRepository.getPartnerProfile();

            PartnerProfileTriggerClass.hasSubmissionCriteriaBeenValidated=false;
            TestUtils.attachFile(pp.Id);

            gp.submitRecordForApproval();

            pageRef = Page.ConfirmationErrorPartnerPage;
            Test.setCurrentPageReference(pageRef);
            ApexPages.currentPage().getParameters().put('recordId',pp.Id);
            ApexPages.currentPage().getParameters().put('fromButton','UnlockPartnerProfile');
            gp2.recordId=pp.Id;
            gp2.init();
            gp2.unlockRecord();
            
            pp.Partner_About__c='fdasjkl';
            update pp;

            PartnerProfileTriggerClass.hasCreatedNonEnglishProfiles=false;
            gp.submitRecordForApproval();
            ApexPages.StandardController ppController= new ApexPages.StandardController(pp);

            ApexPages.currentPage().getParameters().put('CF00NG0000008Nvop_lkid', partnerUser.Contact.AccountId);

            L2Q_PartnerProfileDefaultValues def = new L2Q_PartnerProfileDefaultValues(ppController);

        }
        ApexPages.currentPage().getParameters().put('recordId',partnerUser.Contact.AccountId);
        ApexPages.currentPage().getParameters().put('accountID',partnerUser.Contact.AccountId);
        ApexPages.currentPage().getParameters().put('taskCreatedForCreditCheck','0');
        ApexPages.currentPage().getParameters().put('fromButton','CreateCreditCheckTask');
        gp2.init();
        ApexPages.currentPage().getParameters().put('fromButton','DisqualifyDealDiscount');
        ApexPages.currentPage().getParameters().put('discountStatus','Disqualified');
        gp2.init();
        //ITREQ-3098
        Opportunity opp = SobjectRepository.getOpportunity();
        ApexPages.currentPage().getParameters().put('recordId',opp.id);
        ApexPages.currentPage().getParameters().put('fromButton','UsePartnerForecasting');
        gp2.init();

        PartnerProfileTriggerClass.performFastTrackOperations(new List<Partner_Profile__c>{pp});
        // todo asserts
        Test.stopTest();

    }
    
    //SFDC-6889
    static testmethod void testPartnerProfileSubmission() {
        User partnerUser = SobjectRepository.getPartnerUser();
        Partner_Profile__c pp = (Partner_Profile__c)new SobjectBuilder(Partner_Profile__c.sObjectType)
                                .eagerPopulate()
                                .put(Partner_Profile__c.Partner_Account_Name__c, partnerUser.Contact.AccountId)
                                .create()
                                .getRecord();

        Boolean flag = genericButtonPageController.getFastTrackDetailsBeforeSubmission(pp.Id);
        System.assertEquals(false, flag); //Except 'false' as we haven't yet set the fast track flag for a newly created Partner_Profile__c record in Draft State
        ContentVersion cvRecord = L2Q_ContentDocumentUtilClass.setContentVersion('S', 'Logo.png', 'Logo.png', 'LogoData');
        insert cvRecord;
        ContentVersion cvRecordInserted = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cvRecord.Id];
        ContentDocumentLink conDocLink = L2Q_ContentDocumentUtilClass.setContentDocumentLink(cvRecordInserted.ContentDocumentId, pp.Id, 'I', 'AllUsers');
        insert conDocLink;

        String returnValue = genericButtonPageController.submitPartnerProfileForApproval(pp.Id, true, true);
        System.assertEquals('SUCCESS', returnValue); //Expect the Successful submission via updating the fast track flag in same transaction
    }

    static testmethod void testPMPPMA()
    {


        User partnerUser = SobjectRepository.getPartnerUser();
         SFDC_Budget__c fbdgt = utilTestClass.CreateFundBudget(2000);
        fbdgt.Account__c = partnerUser.Contact.AccountId;  
        System.assert(partnerUser.Contact.AccountId!=null, 'partner user doesnt have contact:'+partnerUser.Contact.AccountId);

        System.runAs(partnerUser)
        {
            insert fbdgt;
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
                .create()
                .getRecord();

            pmp.Plan_Status__c = 'Approved';
            update pmp;
            pma = SobjectRepository.getPMA();
            system.assertNotEquals(pma,null);
            system.assertNotEquals(pma.Activity_Quarter__c,null);
            //system.assertEquals(pma.Activity_status__c,'Approved');
            //system.assertNotEquals(pma.Approved_By__c,null);
            //system.assertNotEquals(pma.Approved_Date__c,null);
            //system.assertNotEquals(pma.Indirect_Campaign__c,null);
            //
            
            string trg1 = 'Partner_Marketing_Plan_Trigger';
            String trg2 = 'Partner_Marketing_Activity__c';
            SObjectFactory.startBatchRun('Partner Marketing Activity Roll-Ups');


            PageReference pageRef = Page.genericButtonpage;
            Test.setCurrentPageReference(pageRef);
            ApexPages.currentPage().getParameters().put('recordId',pmp.Id);
            ApexPages.currentPage().getParameters().put('fromButton','SubmitPartnerMarketingPlan');
            genericButtonPageController gp= new genericButtonPageController();
            gp.recordId=pmp.Id;
            gp.init();

            pageRef = Page.ConfirmationErrorPartnerPage;
            Test.setCurrentPageReference(pageRef);
            ApexPages.currentPage().getParameters().put('recordId',pmp.Id);
            ApexPages.currentPage().getParameters().put('fromButton','UnlockPartnerMarketingPlan');
            gp.recordId=pmp.Id;
            gp.init();
            gp.unlockRecord();

            //SFDC-6322
            ApexPages.StandardController pmpController = new ApexPages.StandardController(pmp);
                //Covers L2Q_PMPFlowController
            L2Q_PMPFlowController tempControllerForFlow = new L2Q_PMPFlowController(pmpController);

            SFDC_Budget__c fb = [select id
                                from SFDC_Budget__c
                                where Partner_Marketing_Plan__c =:pmp.id];

            SFDC_MDF__c fr = (SFDC_MDF__c)new SobjectBuilder(SFDC_MDF__c.sObjectType)
                .eagerPopulate()
                .put(SFDC_MDF__c.Account__c, partnerUser.Contact.AccountId)
                .put(SFDC_MDF__c.Fund_Request_Campaign__c, pma.Indirect_Campaign__c)
                .put(SFDC_MDF__c.Partner_Marketing_Activity__c,pma.Id)
                .create()
                .getRecord();


            fr.Status__c='Approved';
            update fr;
            Test.startTest();
            Opportunity opp = (Opportunity)new SobjectBuilder(Opportunity.sObjectType)
                .eagerPopulate()
                .put(Opportunity.Partner_Marketing_Activity__c, pma.Id)
                .put(Opportunity.Partner_Involved__c, partnerUser.Contact.AccountId)
                .put(Opportunity.StageName, '1. Identify Need')
                .put(Opportunity.Validation_Override__c, true)
                .put(Opportunity.Registration_Status__c, 'Approved')
                .create()
                .getRecord();

            Opportunity opp2 = (Opportunity)new SobjectBuilder(Opportunity.sObjectType)
                .eagerPopulate()
                .put(Opportunity.Partner_Marketing_Activity__c, pma.Id)
                .put(Opportunity.Partner_Involved__c, partnerUser.Contact.AccountId)
                .put(Opportunity.Validation_Override__c, true)
                .create()
                .getRecord();

            opp2.Registration_Status__c = 'Approved';
            opp2.Validation_Override__c = true;
            update opp2;


            ApexPages.StandardController fundRequestController = new ApexPages.StandardController(fr);

            L2Q_MDF_DefaultValues tempController = new L2Q_MDF_DefaultValues(fundRequestController);
            ApexPages.currentPage().getParameters().put(GsmUtilClass.getGSMSettingValue('FR_PM_Relationship_Id'), pma.Id);
            tempController = new L2Q_MDF_DefaultValues(fundRequestController);

            Budget_Allocation__c ba = utilTestClass.CreateFBA(fr.id,fb.id,100);
            insert ba;
            try{
                pma.Activity_status__c = 'Planned';
                update pma;
            }catch(Exception e){
                system.assert(e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'));
            }

            ByPassAndLimitUtils.disable(trg1);
            ByPassAndLimitUtils.disable(trg2);
            //update pma;
            update pmp;
            system.assertNotEquals(true, ByPassAndLimitUtils.canRun(new Set<String>{trg1,trg2}));
            system.assertEquals(true, ByPassAndLimitUtils.isDisabled(trg1));

            NAPSettings.getSet('PPProductFamily_Cloud_Security');
            NAPSettings.getInt('NumberOfMonthsOfLatestNews');

            Map <String, Object> result = RecordApprovalRecallHandler.mApprovalRecallAction(fr.id);
            System.debug('oParamater :'+result.get('oParamater'));
            String parameters = (String)result.get('oParamater');
            if (parameters == null) {
                Map<String,Object> parameterMap = new Map<String,Object>{
                                                    'sAction' => 'mApprovalRecallActionWithAdminPermissions',
                                                    'sApprovalID' => pma.id,
                                                    'RecallingUser' => partnerUser.name,
                                                    'RecallingUserId' => partnerUser.id
                                                    };
                parameters = System.JSON.serialize(parameterMap);
            }
            Messaging.InboundEmail email = new Messaging.InboundEmail();
            Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
            email.subject = 'Recall Approvals';
            email.plainTextBody = parameters;
            envelope.fromAddress = 'dummy123@akamai.com';
            RecordApprovalRecallHandler handler = new RecordApprovalRecallHandler();
            handler.handleInboundEmail(email, envelope);
            Test.stopTest();
        }

    }
    
    static testmethod void testPMPPMA2()
    {
        User partnerUser = SobjectRepository.getPartnerUser();
        System.assert(partnerUser.Contact.AccountId!=null, 'partner user doesnt have contact:'+partnerUser.Contact.AccountId);

        System.runAs(partnerUser)
        {
            SFDC_Channel_Account_Plan__c cap = (SFDC_Channel_Account_Plan__c)new SobjectBuilder(SFDC_Channel_Account_Plan__c.sObjectType)
                .eagerPopulate()
                .put(SFDC_Channel_Account_Plan__c.Partner_Account__c, partnerUser.Contact.AccountId)
                .create()
                .getRecord();

            List<Account> partnerAccounts = [Select id From Account limit 1];
            Account accRec =  partnerAccounts.get(0);

            Campaign c1= (Campaign) new SObjectBuilder(Campaign.sObjectType)
            .eagerPopulate()
            .put(Campaign.Division__c,'Enterprise')
            .put(Campaign.Indirect_Campaign__c,true)
            .put(Campaign.Partner_Involved__c,accRec.id)
            .create()
            .getRecord();

            Partner_Marketing_Plan__c pmp = (Partner_Marketing_Plan__c)new SobjectBuilder(Partner_Marketing_Plan__c.sObjectType)
                .eagerPopulate()
                .put(Partner_Marketing_Plan__c.Business_Plan__c, cap.Id)
                .put(Partner_Marketing_Plan__c.Plan_Period__c,'2H 2020')
                .create()
                .getRecord();

            Partner_Marketing_Activity__c pma = (Partner_Marketing_Activity__c)new SobjectBuilder(Partner_Marketing_Activity__c.sObjectType)
                .eagerPopulate()
                .put(Partner_Marketing_Activity__c.Partner_Marketing_Plan__c, pmp.Id)
                .put(Partner_Marketing_Activity__c.Indirect_Campaign__c, c1.id)
                .put(Partner_Marketing_Activity__c.Validation_Override__c, true)
                .put(Partner_Marketing_Activity__c.Partner__c, accRec.id)
                .create()
                .getRecord();

            Test.startTest();
            pma = SobjectRepository.getPMA();
            system.assertNotEquals(pma,null);
            system.assertNotEquals(pma.Activity_Quarter__c,null);

            pma.Activity_status__c = 'Approved';
            pma.Validation_Override__c = true;
            update pma;

            pma.Activity_status__c = 'Cancelled';
            update pma;
            Test.stopTest();
            
        }

    }
}