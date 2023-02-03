@isTest(seeAllData = false)
private class PartnerCommunityTestClass {
  
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
   
 
    static testmethod void testPartnerCommunityComponents()
    {
 
        User partnerUser = SobjectRepository.getPartnerUser();
       
        System.runAs(partnerUser)
        {
 
            Account accVal = new Account(id=partnerUser.Contact.AccountId, IsPartnerCustom__c = true);
            upsert accVal;
            /*SFDC_Channel_Account_Plan__c cap = (SFDC_Channel_Account_Plan__c)new SobjectBuilder(SFDC_Channel_Account_Plan__c.sObjectType)
                .eagerPopulate()
                .put(SFDC_Channel_Account_Plan__c.Partner_Account__c, partnerUser.Contact.AccountId)
                .put(SFDC_Channel_Account_Plan__c.Validation_Override__c, true)
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
                .put(Partner_Marketing_Activity__c.Partner__c, partnerUser.Contact.AccountId)
                .create()
                .getRecord();
 
            pmp.Plan_Status__c = 'Approved';
            update pmp;
            pma = SobjectRepository.getPMA();*/
            //Creating BU Plan

            //Id recordTypeId = Schema.SObjectType.Partner_Marketing_Activity__c.getRecordTypeInfosByName().get('Marketing - PDF').getRecordTypeId();

            SFDC_Channel_Account_Plan__c cap = new SFDC_Channel_Account_Plan__c(Partner_Account__c = partnerUser.Contact.AccountId, Name = '__Test__Partner__Plan');
            Insert cap;
            // Creating MDF Plan
            Partner_Marketing_Plan__c pmp = new Partner_Marketing_Plan__c(Business_Plan__c = cap.Id, Partner__c = partnerUser.Contact.AccountId, Name = '__Test_Partner__MDF__Plan');
            Insert pmp;
            // Creating PMA
            Partner_Marketing_Activity__c pma = new Partner_Marketing_Activity__c(Partner__c=partnerUser.Contact.AccountId, Activity_Status__c = 'In Progress', Forecast_DR__c = 0, Forecast_Leads__c = 0, Activity_Cost__c = 400, Partner_Marketing_Plan__c = pmp.id, Name = '__Test_MDF_Activity__', Validation_Override__c = true, Activity_Country__c = 'USA', Activity_Description__c = 'Test', Activity_End_Date__c=System.today().addDays(3));
            Insert pma;
            // Changing MDF Plan Status
            pmp.Plan_Status__c = 'Approved';
            update pmp;
           
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
 
            /*SFDC_Budget__c fb = [select id
                                from SFDC_Budget__c
                                where Partner_Marketing_Plan__c =:pmp.id];
            fb.Amount__c = 10000;
            fb.Fund_Claim_Deadline__c = System.today().addDays(7);
            fb.Fund_Request_Deadline__c = System.today().addDays(7);
            fb.Active__c = true;
            fb.Account__c = partnerUser.Contact.AccountId;
            update fb;
 
            SFDC_MDF__c fr = (SFDC_MDF__c)new SobjectBuilder(SFDC_MDF__c.sObjectType)
                .eagerPopulate()
                .put(SFDC_MDF__c.Account__c, partnerUser.Contact.AccountId)
                .put(SFDC_MDF__c.Fund_Request_Campaign__c, pma.Indirect_Campaign__c)
                .put(SFDC_MDF__c.Partner_Marketing_Activity__c,pma.Id)
                .put(SFDC_MDF__c.Validation_Override__c, true)
                .put(SFDC_MDF__c.Earliest_FC_Deadline__c, System.today().addDays(3))
                .put(SFDC_MDF__c.Account__c, partnerUser.Contact.AccountId)
                .create()
                .getRecord();
 
 
            fr.Status__c='Approved';
            update fr;*/
            
            SFDC_Budget__c fb = utilTestClass.CreateFundBudget(200);
            fb.account__c = partnerUser.Contact.AccountId;
            fb.Start_Earned_Date__c = system.today();
            fb.End_Earned_Date__c = system.today();
            fb.Amount__c = 200;
            fb.Partner_Marketing_Plan__c = pmp.id;
            insert fb;
            //Creating FUnd request
            SFDC_MDF__c fr = utilTestClass.CreateFundRequest('__Test__FR__Name', 200);
            fr.Activity_Date__c = System.today();
            fr.Program_End_Date__c = System.today();
            fr.Account__c = partnerUser.Contact.AccountId;
            fr.Program_Type__c = 'Advertising';
            fr.Partner_Marketing_Activity__c = pma.Id;
            fr.Program_Description__c = 'Test';
            insert fr;
            fr.status__c = 'Approved';
            update fr;

            Test.startTest();
            /*Opportunity opp = (Opportunity)new SobjectBuilder(Opportunity.sObjectType)
                .eagerPopulate()
                .put(Opportunity.Partner_Marketing_Activity__c, pma.Id)
                .put(Opportunity.Partner_Involved__c, partnerUser.Contact.AccountId)
                .put(Opportunity.StageName, '1. Identify Need')
                .put(Opportunity.Validation_Override__c, true)
                .put(Opportunity.Registration_Status__c, 'Approved')
                .create()
                .getRecord();*/
 
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
            
 
            NAPSettings.getSet('PPProductFamily_Cloud_Security');
            NAPSettings.getInt('NumberOfMonthsOfLatestNews');
 
            Map <String, Object> result = RecordApprovalRecallHandler.mApprovalRecallAction(fr.id);
            //System.debug('oParamater :'+result.get('oParamater'));
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
            
            /*
             * PartnerCommunityRecordsController is used to get the New buttons urls
             * Calling the getButtonUrl for some objects
             * Also some other methods used by the lightning components
             */
            String urlVal = PartnerCommunityRecordsController.getButtonUrl('Lead');
            String urlVal2 = PartnerCommunityRecordsController.getButtonUrl('Case');
            
            PartnerCommunityRecordsController.getDefaultValues('/partners/s/new_record?sObjectName=Lead&type=flow');
            PartnerCommunityRecordsController.getFlowDetails('/partners/s/new_record?sObjectName=Lead&type=flow');
            PartnerCommunityRecordsController.getRecordAPIName(pmp.id);
           
            System.runAs(dmlUser) {
                /*
                * PartnerCommunityNavigationController is used for getting the eligible Navigation items
                * for lightning partner community.
                */
                List<NavigationMenuItem> menuItems= PartnerCommunityNavigationController.getNavigationItems();
                List<NavigationMenuItem> menuItems2= PartnerCommunityNavigationController.getQuickCreateItems();
                if (menuItems != null && menuItems.size() > 0) {
                    PartnerCommunityNavigationController.getNavigationUrl(menuItems[3].id);
                }
               
            }
            try {
                AkamaiUniversityRedirectController.getAUURL();
            } catch(Exception e) {
                System.debug('Exception in university url');
            }
           
            Test.stopTest();
        }
 
    }
   
    static testmethod void testPartnerCommunityComponents2()
    {
 
        User partnerUser = SobjectRepository.getPartnerUser();
       
        
        System.runAs(partnerUser)
        {
 
            Account accVal = new Account(id=partnerUser.Contact.AccountId, IsPartnerCustom__c = true);
            upsert accVal;
            /*SFDC_Channel_Account_Plan__c cap = (SFDC_Channel_Account_Plan__c)new SobjectBuilder(SFDC_Channel_Account_Plan__c.sObjectType)
                .eagerPopulate()
                .put(SFDC_Channel_Account_Plan__c.Partner_Account__c, partnerUser.Contact.AccountId)
                .put(SFDC_Channel_Account_Plan__c.Validation_Override__c, true)
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
                .put(Partner_Marketing_Activity__c.Partner__c, partnerUser.Contact.AccountId)
                .create()
                .getRecord();
 
            pmp.Plan_Status__c = 'Approved';
            update pmp;
            pma = SobjectRepository.getPMA();*/
            //Creating BU Plan

            //Id recordTypeId = Schema.SObjectType.Partner_Marketing_Activity__c.getRecordTypeInfosByName().get('Marketing - PDF').getRecordTypeId();

            SFDC_Channel_Account_Plan__c cap = new SFDC_Channel_Account_Plan__c(Partner_Account__c = partnerUser.Contact.AccountId, Name = '__Test__Partner__Plan');
            Insert cap;
            // Creating MDF Plan
            Partner_Marketing_Plan__c pmp = new Partner_Marketing_Plan__c(Business_Plan__c = cap.Id, Partner__c = partnerUser.Contact.AccountId, Name = '__Test_Partner__MDF__Plan');
            Insert pmp;
            // Creating PMA
            Partner_Marketing_Activity__c pma = new Partner_Marketing_Activity__c(Partner__c=partnerUser.Contact.AccountId, Activity_Status__c = 'In Progress', Forecast_DR__c = 0, Forecast_Leads__c = 0, Activity_Cost__c = 400, Partner_Marketing_Plan__c = pmp.id, Name = '__Test_MDF_Activity__', Validation_Override__c = true, Activity_Country__c = 'USA', Activity_Description__c = 'Test', Activity_End_Date__c=System.today().addDays(3));
            Insert pma;
            // Changing MDF Plan Status
            pmp.Plan_Status__c = 'Approved';
            update pmp;
           
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
 
            SFDC_Budget__c fb = utilTestClass.CreateFundBudget(200);
            fb.account__c = partnerUser.Contact.AccountId;
            fb.Start_Earned_Date__c = system.today();
            fb.End_Earned_Date__c = system.today();
            fb.Amount__c = 200;
            fb.Partner_Marketing_Plan__c = pmp.id;
            insert fb;
            //Creating FUnd request
            SFDC_MDF__c fr = utilTestClass.CreateFundRequest('__Test__FR__Name', 200);
            fr.Activity_Date__c = System.today();
            fr.Program_End_Date__c = System.today();
            fr.Account__c = partnerUser.Contact.AccountId;
            fr.Program_Type__c = 'Advertising';
            fr.Partner_Marketing_Activity__c = pma.Id;
            fr.Program_Description__c = 'Test';
            insert fr;
            fr.status__c = 'Approved';
            update fr;

            Test.startTest();
            /*Opportunity opp = (Opportunity)new SobjectBuilder(Opportunity.sObjectType)
                .eagerPopulate()
                .put(Opportunity.Partner_Marketing_Activity__c, pma.Id)
                .put(Opportunity.Partner_Involved__c, partnerUser.Contact.AccountId)
                .put(Opportunity.StageName, '1. Identify Need')
                .put(Opportunity.Validation_Override__c, true)
                .put(Opportunity.Registration_Status__c, 'Approved')
                .create()
                .getRecord();*/
 
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
                   
            
            
            
            System.runAs(dmlUser) {
                /*
                * PartnerCommunityCustomSearchController query the objects based on the Logged in user
                * access.
                */
                //PartnerCommunityCustomSearchController.searchForRecords('test');
                List<String> fieldsList = new List<String>();
                fieldsList.add('Id');
                fieldsList.add('Name');
                PartnerCommunityCustomSearchController.getFieldsLabels(fieldsList,'Lead');
                /*
                * Call the method to get object label based on the object API name
                */
                List<String> objectsList = new List<String>();
                objectsList.add('Lead');
                objectsList.add('Contact');
                PartnerCommunityCustomSearchController.getObjectLabelMap(objectsList);
                PartnerCommunityCustomSearchController.getMapOfObjectToFields();
               
                /*
                * Some methods needs to be called directly as admin can not have tab visiblity for few objects
                * so that method will not be called in the test class
                */
                Set<Id> idsList = new Set<Id>();
                PartnerCommunityCustomSearchController.getContacts(idsList);
                PartnerCommunityCustomSearchController.getLeads(idsList);
                PartnerCommunityCustomSearchController.getCases(idsList);
                PartnerCommunityCustomSearchController.getOpportunities(idsList);
                PartnerCommunityCustomSearchController.getPMAs(idsList);
                PartnerCommunityCustomSearchController.getPMPs(idsList);
                PartnerCommunityCustomSearchController.getPartnerPlans(idsList);
                PartnerCommunityCustomSearchController.getRebatePayouts(idsList);
                PartnerCommunityCustomSearchController.getPartnerProfiles(idsList);
               
                /*
                 * PartnerCommRelatedListButtonsController is used to get the related objects
                 */
                PartnerCommRelatedListButtonsController.getAllRelatedObjects('SFDC_MDF__c');
                PartnerCommRelatedListButtonsController.getRelatedObjects(fr.id);
                PartnerCommRelatedListButtonsController.getButtonUrl('SFDC_MDF__c',fr.id);
                PartnerCommunityOpptyHeaderController.generateCDlink();
            }
            try {
                AkamaiUniversityRedirectController.getAUURL();
            } catch(Exception e) {
                System.debug('Exception in university url');
            }
           
            Test.stopTest();
        }
 
    }
   
    static User partner;
    private static Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
   
    static testMethod void TestFCMSelection()
    {
        System.runAs(dmlUser) {
            ManagedPkgErrorClass.isFromManagedPackage = false;
            //Account acc = CreateAccount('__ Test Account');
            Account acc = utilTestClass.CreateAccount('__ Test Account');
            insert acc;
            //Create a partner User for that account
            List<User> PartnerUsers=utilTestClass.createPartnerUsers(1,acc.id);
            partner=PartnerUsers[0];
 
            User opptySCMOwnerUser;
            User opptySCMOwnerUser2;
 
            //opptySCMOwnerUser = utilTestClass.CreateUserWithProfileId('scmUsr1', 'Worldwide', PRM_Settings__c.getInstance('Channel manager profile id').Value__c); //SFDC-2573
            opptySCMOwnerUser = utilTestClass.CreateUserWithProfileId('scmUsr1', 'Worldwide', GsmUtilClass.getPRMSettingValue('Channel_manager_profile_id')); //SFDC-2573
            insert opptySCMOwnerUser;
 
            //2nd FCM
            //opptySCMOwnerUser2 = utilTestClass.CreateUserWithProfileId('scmUsr2', 'Worldwide', PRM_Settings__c.getInstance('Channel manager profile id').Value__c); //SFDC-2573
            opptySCMOwnerUser2 = utilTestClass.CreateUserWithProfileId('scmUsr2', 'Worldwide', GsmUtilClass.getPRMSettingValue('Channel_manager_profile_id')); //SFDC-2573
            insert opptySCMOwnerUser2;
            Channel_Mapping__c cm = utilTestClass.CreateChannelMapping('Test Channel Mapping', acc.Id, opptySCMOwnerUser.Id);
            insert cm;
            Channel_Mapping__c cm2 = utilTestClass.CreateChannelMapping('Test Channel Mapping2', acc.Id, opptySCMOwnerUser2.Id);
            insert cm2;
            Opportunity opp = utilTestClass.CreateOpportunity('__Test Opportunity__','1-Create');
            opp.End_Customer_Country__c = 'USA';
            opp.End_Customer_State__c = 'NY';
            opp.End_Customer_City__c = 'Buffalo';
            opp.End_Customer_Street_Address__c = 'Line1 \r\n Line2';
            opp.Partner_Involved__c = acc.Id;
            opp.CloseDate= Date.today();
 
            SFDC_Budget__c fb = utilTestClass.CreateFundBudget(2000);
            fb.Account__c = acc.Id;
 
            SFDC_MDF__c Fr = utilTestClass.CreateFundRequest('__ Fund Request__',1000);
            fr.Account__c = acc.Id;
 
            system.runAs(Partner)
            {
                insert opp;
                Test.startTest();
                PartnerCommunityFCMController.getFCMValues(opp.id);
                PartnerCommunityFCMController.updateRecord(opp.id,'NONE');
                Test.stopTest();
            }
        }     
    }
   
    static testMethod void TestRebateTC()
    {
        System.runAs(dmlUser) {
            ManagedPkgErrorClass.isFromManagedPackage = false;
            //Account acc = CreateAccount('__ Test Account');
            Account acc = utilTestClass.CreateAccount('__ Test Account');
            insert acc;
            //Create a partner User for that account
            List<User> PartnerUsers=utilTestClass.createPartnerUsers(1,acc.id);
            partner=PartnerUsers[0];
 
            User opptySCMOwnerUser;
            User opptySCMOwnerUser2;
 
            //opptySCMOwnerUser = utilTestClass.CreateUserWithProfileId('scmUsr1', 'Worldwide', PRM_Settings__c.getInstance('Channel manager profile id').Value__c); //SFDC-2573
            opptySCMOwnerUser = utilTestClass.CreateUserWithProfileId('scmUsr1', 'Worldwide', GsmUtilClass.getPRMSettingValue('Channel_manager_profile_id')); //SFDC-2573
            insert opptySCMOwnerUser;
 
            //2nd FCM
            //opptySCMOwnerUser2 = utilTestClass.CreateUserWithProfileId('scmUsr2', 'Worldwide', PRM_Settings__c.getInstance('Channel manager profile id').Value__c); //SFDC-2573
            opptySCMOwnerUser2 = utilTestClass.CreateUserWithProfileId('scmUsr2', 'Worldwide', GsmUtilClass.getPRMSettingValue('Channel_manager_profile_id')); //SFDC-2573
            insert opptySCMOwnerUser2;
            Channel_Mapping__c cm = utilTestClass.CreateChannelMapping('Test Channel Mapping', acc.Id, opptySCMOwnerUser.Id);
            insert cm;
            Channel_Mapping__c cm2 = utilTestClass.CreateChannelMapping('Test Channel Mapping2', acc.Id, opptySCMOwnerUser2.Id);
            insert cm2;
            Opportunity opp = utilTestClass.CreateOpportunity('__Test Opportunity__','1-Create');
            opp.End_Customer_Country__c = 'USA';
            opp.End_Customer_State__c = 'NY';
            opp.End_Customer_City__c = 'Buffalo';
            opp.End_Customer_Street_Address__c = 'Line1 \r\n Line2';
            opp.Partner_Involved__c = acc.Id;
            opp.CloseDate= Date.today();
 
            SFDC_Budget__c fb = utilTestClass.CreateFundBudget(2000);
            fb.Account__c = acc.Id;
 
            SFDC_MDF__c Fr = utilTestClass.CreateFundRequest('__ Fund Request__',1000);
            fr.Account__c = acc.Id;
 
            system.runAs(Partner)
            {
                insert opp;
                Test.startTest();
                PartnerCommunityOpptyHeaderController.getObjectName(opp.id);
                PartnerCommunityOpptyHeaderController.getOppty(opp.id);
                PartnerCommunityOpptyHeaderController.getRebateTermsConditions();
                PartnerCommunityOpptyHeaderController.accept();
                PartnerCommunityOpptyHeaderController.reject();
                Test.stopTest();
            }
        }     
    }
   
    public static testmethod void testOpptyApprovalProcess_Negative()
    {
      System.runAs(utilTestClass.getTestRunUser())
      {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        utilTestClass.insertCustomSettings();
        //ApprovalHistoryPageControllerTestClass.disableDealMakerCoreSettings();
        Account acc = utilTestClass.CreateAccount('__ test Account');
        insert acc;
        //Create a partner User for that account
        List<User> PartnerUsers=utilTestClass.createPartnerUsers(1,acc.id);
        partner=PartnerUsers[0];
        //Add the User to the chanell mapping table
        // Create 'SalesChannelMgr' User
        //Profile prSCM = [Select Id, Name from profile where id=:PRM_Settings__c.getInstance('Channel manager profile id').Value__c][0]; //SFDC-2573
        Profile prSCM = [Select Id, Name from profile where id=:GsmUtilClass.getPRMSettingValue('Channel_manager_profile_id')][0]; //SFDC-2573
        UserRole roleDVA = [select id, name from UserRole where name='Worldwide'][0];
        User opptySCMOwnerUser = new User(alias = 'scmUsr1', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OpptyOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__mss_owner@akamai.com',profileid = prSCM.Id, UserRoleId = roleDVA.Id );
        insert opptySCMOwnerUser;
       
        //Channel_Mapping__c cm= new Channel_Mapping__c(Name = 'Test Channel Mapping', Partner_Name__c = acc.id, PAE_ID__c = opptySCMOwnerUser.id);
        Channel_Mapping__c cm = utilTestClass.CreateChannelMapping('Test Channel Mapping', acc.Id, opptySCMOwnerUser.Id);
        insert cm;
       
        List<Opportunity> oppList = new List<Opportunity>();
       
        Opportunity opp = utilTestClass.CreateOpportunity('__Test Opportunity','1-Create');
        opp.Channel_Manager__c = cm.Id;
        opp.End_Customer_Country__c = 'USA';
        opp.End_Customer_State__c = 'NY';
        opp.End_Customer_City__c = 'Buffalo';
        opp.End_Customer_Street_Address__c = 'Line1 \r\n Line2'; 
        opp.CloseDate= Date.today();
        opp.Partner_Involved__c = acc.Id;
        opp.AccountId = acc.Id;
        opp.Deal_Reg_Account_Status__c='New Account';
        opp.Deal_Reg_Opportunity_Status__c='New Opportunity';
        oppList.add(opp);
       
        Opportunity opp2 = utilTestClass.CreateOpportunity('__Test Opportunity2','1-Create');
        opp2.Channel_Manager__c = cm.Id;
        opp2.End_Customer_Country__c = 'USA';
        opp2.End_Customer_State__c = 'NY';
        opp2.End_Customer_City__c = 'Buffalo';
        opp2.End_Customer_Street_Address__c = 'Line1 \r\n Line2'; 
        opp2.CloseDate= Date.today();
        opp2.Partner_Involved__c = acc.Id;
        opp2.AccountId = acc.Id;
        opp2.Deal_Reg_Account_Status__c='New Account';
        opp2.Deal_Reg_Opportunity_Status__c='New Opportunity';
        oppList.add(opp2);
       
        system.runAs(Partner)
        {
          Test.startTest();
          insert oppList;
        }
       
        /*
        * Get oppty method called from Lightning component
        */
        List<Opportunity> opptyList = [Select id From Opportunity];
         
        PartnerCommSubmitForApprovalController.getOppty(opptyList[0].id);
           
        //Submit the Opportunity for Approval
          try {
              PartnerCommSubmitForApprovalController.handleApproval(opptyList[0].id);
              PartnerCommSubmitForApprovalController.handleApproval(opptyList[1].id);
              //Opportunity oppAfterApproval=[select id,FCM__c,Channel_Manager__c,Rebate__c, Registration_Status__c from Opportunity where id=:opptyList[0].id];
          } catch(Exception e) {
              System.debug('Error approving');
          }
          try {
              PartnerCommSubmitForApprovalController.errorMessage('7');
          } catch(Exception e) {
              System.debug('Error approving');
          }
       
      }
    }

    public static testmethod void testGroupSharing()
    {
 
        User partnerUser = SobjectRepository.getPartnerUser();
        utilTestClass.createCustomSettings();
       
        System.runAs(partnerUser)
        {
 
            Account accVal = new Account(id=partnerUser.Contact.AccountId, IsPartnerCustom__c = true);
            upsert accVal;
            /*SFDC_Channel_Account_Plan__c cap = (SFDC_Channel_Account_Plan__c)new SobjectBuilder(SFDC_Channel_Account_Plan__c.sObjectType)
                .eagerPopulate()
                .put(SFDC_Channel_Account_Plan__c.Partner_Account__c, partnerUser.Contact.AccountId)
                .put(SFDC_Channel_Account_Plan__c.Validation_Override__c, true)
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
                .put(Partner_Marketing_Activity__c.Partner__c, partnerUser.Contact.AccountId)
                .create()
                .getRecord();
 
            pmp.Plan_Status__c = 'Approved';
            update pmp;
            pma = SobjectRepository.getPMA();*/
            //Creating BU Plan

            //Id recordTypeId = Schema.SObjectType.Partner_Marketing_Activity__c.getRecordTypeInfosByName().get('Marketing - PDF').getRecordTypeId();

            SFDC_Channel_Account_Plan__c cap = new SFDC_Channel_Account_Plan__c(Partner_Account__c = partnerUser.Contact.AccountId, Name = '__Test__Partner__Plan');
            Insert cap;
            // Creating MDF Plan
            Partner_Marketing_Plan__c pmp = new Partner_Marketing_Plan__c(Business_Plan__c = cap.Id, Partner__c = partnerUser.Contact.AccountId, Name = '__Test_Partner__MDF__Plan');
            Insert pmp;
            // Creating PMA
            Partner_Marketing_Activity__c pma = new Partner_Marketing_Activity__c(Partner__c=partnerUser.Contact.AccountId, Activity_Status__c = 'In Progress', Forecast_DR__c = 0, Forecast_Leads__c = 0, Activity_Cost__c = 400, Partner_Marketing_Plan__c = pmp.id, Name = '__Test_MDF_Activity__', Validation_Override__c = true, Activity_Country__c = 'USA', Activity_Description__c = 'Test', Activity_End_Date__c=System.today().addDays(3));
            Insert pma;
            // Changing MDF Plan Status
            pmp.Plan_Status__c = 'Approved';
            update pmp;
           
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
 
            SFDC_Budget__c fb = utilTestClass.CreateFundBudget(200);
            fb.account__c = partnerUser.Contact.AccountId;
            fb.Start_Earned_Date__c = system.today();
            fb.End_Earned_Date__c = system.today();
            fb.Amount__c = 200;
            fb.Partner_Marketing_Plan__c = pmp.id;
            insert fb;
            //Creating FUnd request
            SFDC_MDF__c fr = utilTestClass.CreateFundRequest('__Test__FR__Name', 200);
            fr.Activity_Date__c = System.today();
            fr.Program_End_Date__c = System.today();
            fr.Account__c = partnerUser.Contact.AccountId;
            fr.Program_Type__c = 'Advertising';
            fr.Partner_Marketing_Activity__c = pma.Id;
            fr.Program_Description__c = 'Test';
            insert fr;
            fr.status__c = 'Approved';
            update fr;

            /*Opportunity opp = (Opportunity)new SobjectBuilder(Opportunity.sObjectType)
                .eagerPopulate()
                .put(Opportunity.Partner_Marketing_Activity__c, pma.Id)
                .put(Opportunity.Partner_Involved__c, partnerUser.Contact.AccountId)
                .put(Opportunity.StageName, '1. Identify Need')
                .put(Opportunity.Validation_Override__c, true)
                .put(Opportunity.Registration_Status__c, 'Approved')
                .create()
                .getRecord();*/
 
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
           
            Test.startTest();
            System.runAs(dmlUser) {
                
                List<Account> partnerAccounts = SobjectFactory.createPartnerAccounts(2);
                Account accRec1 =  partnerAccounts.get(0);
                Account updateacc = new Account(id=accRec1.id,parentId=partnerUser.Contact.AccountId);
                upsert updateacc;
                Account accRec2 =  partnerAccounts.get(1);
                Account updateacc2 = new Account(id=accRec2.id,parentId=partnerUser.Contact.AccountId);
                Set<Id> childId = new Set<Id>();
                childId.add(partnerUser.Contact.AccountId);
                childId.add(accRec1.id);
                childId.add(accRec2.id);
                List<Id> accList = new List<Id>();
                accList.addAll(childId);

                Default__c defaultSetting = new Default__c();
                defaultSetting.name = 'Default';
                defaultSetting.Is_Partner_Portal_Enabled__c = true;
                defaultSetting.Case_Access_Level__c = 'edit';
                defaultSetting.Opportunity_Access_Level__c = 'edit';
                insert defaultSetting;
                //Map<Id, Set<Id>> accChildAccMap = new Map<Id, Set<Id>>();
                //accChildAccMap.put(partnerUser.Contact.AccountId,childId);
                Map<Id,Id> accountIdUserRoleIdMap = GroupSharingHelper.getRoles(accList, 'Partner');
                    Map<Id,Id> gMap = GroupSharingHelper.getGroups(accountIdUserRoleIdMap.values());
                    GroupSharing.calcChildSharesFromUser(childId, accountIdUserRoleIdMap, gMap, null);
    
                    Map<Id, String> accChildAccMap = new Map<Id, String>();
                    accChildAccMap.put(partnerUser.Contact.AccountId,accRec1.id);
                    accChildAccMap.put(partnerUser.Contact.AccountId,accRec2.id);
                    
     
                    Case cs1 = new Case();
                    cs1.Description = 'testcase1';
                    cs1.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Partner Portal Case').getRecordTypeId();
                    cs1.Subject = 'testS2ET1';
                    cs1.Service__c = 'Managed Integration';
                    cs1.Validation_Override__c = true;
                    cs1.AccountId = partnerUser.Contact.AccountId;
                    insert cs1;
                    Map<Id,String> caseAccMap = new Map<Id,String>();
                    caseAccMap.put(cs1.id,partnerUser.Contact.AccountId);
                    GroupSharing.createCaseShares(caseAccMap,accountIdUserRoleIdMap, gMap);
                    Set<Id> caseIdSet = new Set<Id>();
                    caseIdSet.add(cs1.id);
                    //GroupSharing.removeCaseShares(caseIdSet,null);
                    List<Id> gList = new List<Id>();
                    Map<Id,String> oppToaccMap = new Map<Id,String>();
                    oppToaccMap.put(opp2.id,partnerUser.Contact.AccountId);
                    GroupSharing.createOppShares(oppToaccMap,accountIdUserRoleIdMap, gMap);
                try {
                    GroupSharing.removeShares(accList, gList);
                    GroupSharing.calcChildShares(accChildAccMap, accountIdUserRoleIdMap, gMap, 'add');
                } catch(Exception e) {
                    System.System.debug('error');
                }
                
            }
            Test.stopTest();
        }
 
    }
}