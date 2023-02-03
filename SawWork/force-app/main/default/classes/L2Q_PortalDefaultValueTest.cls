@isTest(seeAllData=false)
public class L2Q_PortalDefaultValueTest {

        static User dmlUser = new User(id=UserInfo.getUserId());

        @testSetUp static void insertCustomSettingsAndCreateData()
        {
                System.runAs(utilTestClass.getTestRunUser())
                {
                Map<String, String> objectToCustomSettingResource = new Map<String, String>{
                        'Environment_Setup__c' => 'CS_Environment_Setup'
                };
                utilTestClass.insertCustomSettings(objectToCustomSettingResource);
                insert new Features_Toggle__c(name='isCronErrorMailViaCode',Toggle__c=false);
                insert new PRM_Settings__c(name='NonLitePermissionSets', Value__c='Has_DealRegistration_Access__c,Has_PartnerPlans_Access__c');
                SObjectFactory.createPartnerUsers(1);
                User partnerUser = SobjectRepository.getPartnerUser();
                // create master CM for MDF_Approver__c
                SobjectFactory.createDealRegUnsubmitted(partnerUser.Contact.AccountId);
                }
        }

        static testmethod void getDefaultValues1() {

                User partnerUser = SobjectRepository.getPartnerUser();
                
                //System.runAs(partnerUser)
                
                //User u = [Select id From User where alias='prtSUser'];
                Lead l = createLead(partnerUser.id);

                ApexPages.StandardController leadController = new ApexPages.StandardController(l);

                L2Q_Portal_DefaultValues tempController = new L2Q_Portal_DefaultValues(leadController);
                tempController = new L2Q_Portal_DefaultValues(leadController);
                tempController.RedirectCheck();
            
            	L2Q_Portal_DefaultValues.getDefaultValuesOf_Case('');
            	L2Q_Portal_DefaultValues.getDefaultValuesOf_Contact('');
        }


        static testmethod void testPMPPMA()
        {
                
                User partnerUser = SobjectRepository.getPartnerUser();
                
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

                pmp.Plan_Status__c = 'Approved';
                update pmp;
                pma = SobjectRepository.getPMA();

                /*ApexPages.StandardController leadController = new ApexPages.StandardController(cap);

                PageReference pageRef = Page.L2Q_PartnerPlanCreation;
                Test.setCurrentPageReference(pageRef);
                L2Q_PartnerPlanCreationController gp= new L2Q_PartnerPlanCreationController(leadController);
                
                gp.RedirectCheck();*/
                }

        }
        
        private static Lead createLead(Id ownerId) {

        Id partnerRecordypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Partner Lead').getRecordTypeId();

        Lead l = new Lead();
        l.recordTypeId = partnerRecordypeId;
        l.email = 'testemail@email.com';
        l.status = 'New';
        l.CurrencyIsoCode = 'USD';
        l.company = 'Test Company';
        l.firstname = 'Test';
        l.lastname = 'Lead';
        l.ownerId = ownerId;
        l.website = 'testwebsite.com';
        l.industry = 'Banking';
        l.street = 'Test street';
        l.city = 'Test City';
        l.state = 'Test state';
        l.PostalCode  = '201323';
        l.country = 'USA';
        l.Primary_Product__c = 'Enterprise Security - Enterprise App Access';
        l.Services_Hostname__c = 'testwebsite.com';
        l.description = 'Test Description';
        insert l;
        return l;
    }

}