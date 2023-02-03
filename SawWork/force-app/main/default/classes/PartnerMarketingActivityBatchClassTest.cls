@isTest(seeAllData=false)
public class PartnerMarketingActivityBatchClassTest {

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

    static testmethod void PartnerMarketingActivityBatchTest()
    {

        User partnerUser = SobjectRepository.getPartnerUser();
        System.debug('partner user : '+partnerUser.Contact.AccountId);
        System.debug('partner user : '+[Select id From Account limit 1].id);
        SFDC_Budget__c fbdgt = utilTestClass.CreateFundBudget(2000);
        fbdgt.Account__c = partnerUser.Contact.AccountId;  
       // String recordTypeId  = GsmUtilClass.getGSMSettingValue('PDA_Record_Types_For_Batch_Class').split(',')[0];

        
        
        System.runAs(partnerUser)
        {
            
             
             insert fbdgt;
            
            
            SFDC_Channel_Account_Plan__c cap = (SFDC_Channel_Account_Plan__c)new SobjectBuilder(SFDC_Channel_Account_Plan__c.sObjectType)
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
                //.put(Partner_Marketing_Activity__c.RecordType.Name , 'Marketing - PDF')
                .put(Partner_Marketing_Activity__c.Activity_End_Date__c , Date.today().addDays(1))
                //.put(Partner_Marketing_Activity__c.Disposition_Status__c , 'Draft')
                //.put(Partner_Marketing_Activity__c.Activity_Cost_Mirrored__c , 100.00)
               // .put(Partner_Marketing_Activity__c.RecordTypeId, Schema.SObjectType.Partner_Marketing_Activity__c.getRecordTypeInfosByName().get('Marketing - PDF').getRecordTypeId())
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
            
            PartnerMarketingActivityBatchClass pmabc= new PartnerMarketingActivityBatchClass();
            Database.executebatch(pmabc);
            Test.stopTest();
        }

    }
}