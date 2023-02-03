// Developer: Ruchika Sharma
// Created class for : SFDC - 6609
// created Test class which covers PartnerCommCommonController and PartnerCommSubmitForApprovalController
@isTest(seeAllData = false)
private class PartnerCommButtonsTestClass {
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
            partnerUser.Has_PartnerPlans_Access__c = true;
            update partnerUser;
            Contact partnerContact = [select id,Partner_User__c,AccountId,Has_Akamai_University_Access__c from Contact where Account.isPartnerCustom__c=true limit 1];
            SFDC_Budget__c fb = utilTestClass.CreateFundBudget(2000);

                fb.Account__c = partnerContact.AccountId;
                fb.Validation_Override__c = true;
                insert fb;
           PartnerAccessController.updateRemoveUserPermissionSet(partnerUser, partnerContact);
           
        }
        Test.stopTest();
    }
        static testmethod void submissionAndUnlockForPartnerRecordsNegative(){
            User partnerUser = SobjectRepository.getPartnerUser();
        //     Contact partnerContact = [select id,Partner_User__c,AccountId,Has_Akamai_University_Access__c from Contact where Account.isPartnerCustom__c=true limit 1];
        //     SFDC_Budget__c fb = utilTestClass.CreateFundBudget(2000);

        //         fb.Account__c = partnerContact.AccountId;
        //         fb.Validation_Override__c = true;
        //         insert fb;
        //    PartnerAccessController.updateRemoveUserPermissionSet(partnerUser, partnerContact);
        SFDC_Channel_Account_Plan__c cap;
        Partner_Marketing_Plan__c pmp;
        Test.startTest();
        System.runAs(partnerUser)
            {
                 cap = (SFDC_Channel_Account_Plan__c)new SobjectBuilder(SFDC_Channel_Account_Plan__c.sObjectType)
                .eagerPopulate()
                .put(SFDC_Channel_Account_Plan__c.Partner_Account__c, partnerUser.Contact.AccountId)
                .create()
                .getRecord();
                 pmp = (Partner_Marketing_Plan__c)new SobjectBuilder(Partner_Marketing_Plan__c.sObjectType)
                    .eagerPopulate()
                    .put(Partner_Marketing_Plan__c.Business_Plan__c, cap.Id)
                    .put(Partner_Marketing_Plan__c.Plan_Period__c, '2H 2020')
                    .create()
                    .getRecord();
                String recordId = pmp.id;
                try{
                    PartnerCommSubmitForApprovalController.handleApproval(recordId);
                }catch(Exception e){
                    system.debug('ee::: '+e.getMessage());
                    system.assert(e.getMessage()!=null, 'some error has occured');
                }
            }
             partnerUser = SobjectRepository.getPartnerUser();
            partnerUser.Has_PartnerPlans_Access__c = false;
            update partnerUser;
            System.runAs(partnerUser){
                String recordId = pmp.id;
                try{
                    PartnerCommCommonController.handleUnlockRecord(recordId);
                }catch(Exception e){
                    system.debug('ee::: '+e.getMessage());
                    system.assert(e.getMessage()!=null, 'some error has occured');
                }
                
            }
            Test.stopTest();
        }
        static testmethod void submissionAndUnlockForPartnerRecords(){
            User partnerUser = SobjectRepository.getPartnerUser();
            
            Partner_Profile__c pp;
            SFDC_MDF__c fr;
            System.assert(partnerUser.Contact.AccountId!=null, 'partner user doesnt have contact:'+partnerUser.Contact.AccountId);
            
            pp = (Partner_Profile__c)new SobjectBuilder(Partner_Profile__c.sObjectType)
                .eagerPopulate()
                .put(Partner_Profile__c.Partner_Account_Name__c, partnerUser.Contact.AccountId)
                .create()
                .getRecord();
            System.assert(pp.Id!=null, 'wut'+pp);
            // TestUtils.verifyPageMessageDisplayed(NAPSettings.getValue('PartnerProfileNoLogoErrorMessage'));

            PartnerProfileTriggerClass.hasSubmissionCriteriaBeenValidated=false;
            TestUtils.attachFile(pp.Id);
            Test.startTest();
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

            
            

            String recordId = pp.id;
            PartnerProfileTriggerClass.hasSubmissionCriteriaBeenValidated=false;
            // PartnerCommSubmitForApprovalController.handleApproval(recordId);
            PartnerCommCommonController.getUnlockRecordText();
            PartnerCommCommonController.handleUnlockRecord(recordId);
            // Partner_Marketing_Plan__c pmp = [select id from Partner_Marketing_Plan__c Limit 1];
            recordId = pmp.id;
            PartnerCommSubmitForApprovalController.handleApproval(recordId);
            PartnerCommCommonController.handleUnlockRecord(recordId);
            
            // Partner_Marketing_Activity__c pma = SObjectRepository.getPMA();
            
            fr = (SFDC_MDF__c)new SobjectBuilder(SFDC_MDF__c.sObjectType)
                .eagerPopulate()
                .put(SFDC_MDF__c.Account__c, partnerUser.Contact.AccountId)
                .put(SFDC_MDF__c.Fund_Request_Campaign__c, pma.Indirect_Campaign__c)
                .put(SFDC_MDF__c.Partner_Marketing_Activity__c,pma.Id)
                .create()
                .getRecord();
            recordId = fr.id;
            PartnerCommSubmitForApprovalController.handleApproval(recordId);
            // Channel_Mapping__c channelMapping = SObjectFactory.createChannelMapping(partnerUser.Contact.AccountId);
            // Opportunity opp = (Opportunity)new SobjectBuilder(Opportunity.sObjectType)
            //     .eagerPopulate()
            //     .put(Opportunity.Partner_Marketing_Activity__c, pma.Id)
            //     .put(Opportunity.Partner_Involved__c, partnerUser.Contact.AccountId)
            //     .put(Opportunity.StageName, '1. Identify Need')
            //     .put(Opportunity.Validation_Override__c, true)
            //     .put(Opportunity.Channel_Manager__c, channelMapping.Id)
            //     .put(Opportunity.Registration_Status__c, 'Approved')
            //     .create()
            //     .getRecord();
            // recordId = opp.id;
            // PartnerCommSubmitForApprovalController.handleApproval(recordId);
            }
            fr.status__c = 'Approved';
            update fr;
            fr = SObjectRepository.getFundRequests(1).get(0);
            system.assert(fr.status__c=='Approved','Fr status is not approved');
            System.runAs(partnerUser)
            {
                SFDC_MDF_Claim__c fc = (SFDC_MDF_Claim__c)new SobjectBuilder(SFDC_MDF_Claim__c.sObjectType)
                .eagerPopulate()
                .put(SFDC_MDF_Claim__c.Account__c, partnerUser.Contact.AccountId)
                .put(SFDC_MDF_Claim__c.Fund_Request__c, fr.id)
                .put(SFDC_MDF_Claim__c.Fund_Claim_Activity_Spender__c, 'Partner')
                .create()
                .getRecord();
            String recordId = fc.id;
            PartnerCommSubmitForApprovalController.handleApproval(recordId);
            PartnerCommSubmitForApprovalController.errorMessage('7');
            

                // .put(Opportunity.Registration_Status__c, 'Approved')
        }
    }

    // static testmethod void submissionOfDR(){
    //         User partnerUser = SobjectRepository.getPartnerUser();
        
    //     Test.startTest();
    //     System.runAs(partnerUser)
    //     {
    //         Opportunity opp = SObjectRepository.getOpportunity();
    //         String recordId = opp.id;
    //         PartnerCommSubmitForApprovalController.handleApproval(recordId);

    //     }
    // }
}