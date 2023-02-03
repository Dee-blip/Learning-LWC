@isTest(seeAllData=false)
public class FundRequestButtonPageControllerTest
{
    private static User dmlUser = new User(id=UserInfo.getUserId());
    private static final Integer numberOfFundBudgets = 3;

    @testSetUp static void insertCustomSettingsAndCreateData()
    {
        Map<String, String> objectToCustomSettingResource = new Map<String, String>{ 
                'Communities_Settings__c'   => 'CS_Communities_Settings',
                'LunaControlCenterSettings__c' => 'CS_LunaControlCenterSettings',
                'Environment_Setup__c' => 'CS_Environment_Setup'
        };
        System.runAs(dmlUser)
        {
            //utilTestClass.insertCustomSettings(objectToCustomSettingResource);
            SObjectFactory.createPartnerUsers(1);
            User partnerUser = SobjectRepository.getPartnerUser();
            Account partAccount = SobjectRepository.getPartnerAccount();
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
            PRMTriggerClass.InitializeFlagVariables();

            List<User> paeUsers = SObjectRepository.getSalesPAEUsers(2);
            User frQualityQueueUser = SObjectRepository.getFundRequestQualityQueueUser();
            Id approverId = null;
            if(frQualityQueueUser != null) {
                approverId = frQualityQueueUser.Id;
            } else {
                //Not neccesary - Added to pass test in devqa
                approverId = paeUsers[1].Id;
            }

            // active master channel mapping with fr approver
            // Change MDF_Approver__c from paeUsers[1].Id to frQualityQueueUser.Id
            Channel_Mapping__c cm = (Channel_Mapping__c)new SobjectBuilder(Channel_Mapping__c.sObjectType)
                .eagerPopulate()
                .put(Channel_Mapping__c.PAE_ID__c, paeUsers[0].Id)
                .put(Channel_Mapping__c.MDF_Approver__c, approverId)
                .put(Channel_Mapping__c.Partner_Name__c, partAccount.Id)
                .create()
                .getRecord();


            // submit the two FRs for approval
            // PRMTriggerClass.InitializeFlagVariables();
            // TestUtils.submitForApproval(fr1);
            // PRMTriggerClass.InitializeFlagVariables();

            // TestUtils.submitForApproval(fr2);
            // PRMTriggerClass.InitializeFlagVariables();

            // User frApprover = new User(id=cm.MDF_Approver__c);
            // System.runAs(frApprover)
            // {
            //     TestUtils.approveRecord(fr2);
            // }

            // User regionalManagerQueue = new User(Id=TestUtils.getNextApproverUserId(fr2));
            // PRMTriggerClass.InitializeFlagVariables();

            // System.runAs(regionalManagerQueue)
            // {
            //     //TestUtils.approveRecordWithoutSettingNextApprover(fr2);
            // }
            // PRMTriggerClass.InitializeFlagVariables();
        }

    }
    
    static testmethod void testFundRequestButtonPageController()
    {
        system.runas(dmlUser)
        {

            User partnerUser = SobjectRepository.getPartnerUser(); 
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
                .put(Partner_Marketing_Activity__c.Activity_Cost__c,20)
                .create()
                .getRecord();

            pmp.Plan_Status__c = 'Approved';
            update pmp;
            pma = SobjectRepository.getPMA();


            SFDC_MDF__c fr = SobjectRepository.getDraftFundRequest();
            List<User> paeUsers = SObjectRepository.getSalesPAEUsers(1);
            fr.Partner_Account_Owner__c = paeUsers[0].Id;
            fr.Partner_Marketing_Activity__c = pma.id;
            fr.Amount__c = 10;
            update fr;
            // mark master mc as inactive
            Channel_Mapping__c cm = SobjectRepository.getMasterChannelMapping();
            cm.Master_Channel_Mapping__c= false;

            update cm;
            test.startTest();
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
            frbpc.submitForApproval();
            frbpc.associateToCampaign();
            frbpc.backToFundRequest();
            Test.stopTest();
        }
    }
}