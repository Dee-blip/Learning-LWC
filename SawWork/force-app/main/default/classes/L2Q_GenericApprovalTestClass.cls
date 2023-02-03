@isTest(seeAllData = false)
private class L2Q_GenericApprovalTestClass {
    @testSetUp static void insertCustomSettingsAndCreateData() {
        //taruni
        Map<String, String> objectToCustomSettingResource = new Map<String, String>{ 
            'Communities_Settings__c'   => 'CS_Communities_Settings',
                'LunaControlCenterSettings__c' => 'CS_LunaControlCenterSettings',
                'Environment_Setup__c' => 'CS_Environment_Setup'
                };
                    Integer numberOfFundBudgets = 3;
        User dmlUser = new User(id = UserInfo.getUserId());
        L2Q_GenericApprovalClass.FieldDescriptorWrapper fdw = new L2Q_GenericApprovalClass.FieldDescriptorWrapper();
        L2Q_GenericApprovalClass.FieldDescriptor fd = new L2Q_GenericApprovalClass.FieldDescriptor();
        System.runAs(dmlUser) {
            SObjectFactory.createPartnerUsers(1);
            Account partAccount = SobjectRepository.getPartnerAccount();
            //taruni
            User partnerUser = SobjectRepository.getPartnerUser();
            // some problem with this method SobjectRepository.getPartnerUser()
            // create two fund budgets
            new SObjectBuilder(SFDC_Budget__c.sObjectType)
                .eagerPopulate()
                .put(SFDC_Budget__c.Account__c, partAccount.Id)
                .count(numberOfFundBudgets)
                .create();
            PRMTriggerClass.InitializeFlagVariables();
            
            // create fund request in draft state, submitted state and approved state
            List<SFDC_MDF__c > fundRequests = (List<SFDC_MDF__c > )
                new SobjectBuilder(SFDC_MDF__c.sObjectType)
                .eagerPopulate()
                .put(SFDC_MDF__c.Account__c, partAccount.Id)
                .count(3)
                .create()
                .getRecords();
            
            // let fr0 remain in draft state. Submit fr1 and submit and approve fr2
            SFDC_MDF__c fr1 = fundRequests[1];
            SFDC_MDF__c fr2 = fundRequests[2];
            //SFDC_MDF__c fr3 = fundRequests[3];
            PRMTriggerClass.InitializeFlagVariables();
            
            List<User> paeUsers = SObjectRepository.getSalesPAEUsers(2);
            User frQualityQueueUser = SObjectRepository.getFundRequestQualityQueueUser();
            Id approverId = null;
            if (frQualityQueueUser != null) {
                approverId = frQualityQueueUser.Id;
            } else {
                //Not neccesary - Added to pass test in devqa
                approverId = paeUsers[1].Id;
            }
            
            // active master channel mapping with fr approver
            // Change MDF_Approver__c from paeUsers[1].Id to frQualityQueueUser.Id
            Channel_Mapping__c cm = (Channel_Mapping__c) new SobjectBuilder(Channel_Mapping__c.sObjectType)
                .eagerPopulate()
                .put(Channel_Mapping__c.PAE_ID__c, paeUsers[0].Id)
                .put(Channel_Mapping__c.MDF_Approver__c, approverId)
                .put(Channel_Mapping__c.Partner_Name__c, partAccount.Id)
                .create()
                .getRecord();
        }
        
        //insert oppty
        Test.startTest();
        Opportunity opp1 = utilTestClass.CreateOpportunity('TestOppty', '1-Create');
        opp1.CloseDate = Date.today().addDays(10);
        insert opp1;
        Test.stopTest();
        
    }
    static testmethod void testGenericApprovalClass() {
        User dmlUser = new User(id = UserInfo.getUserId());
        
        
        System.runAs(dmlUser) {
            //taruni
            User partnerUser = SobjectRepository.getPartnerUser(); 
            
            
            
            Account partAccount = SobjectRepository.getPartnerAccount();
            List<SFDC_MDF__c > fundRequests = (List<SFDC_MDF__c > )
                new SobjectBuilder(SFDC_MDF__c.sObjectType)
                .eagerPopulate()
                .put(SFDC_MDF__c.Account__c, partAccount.Id)
                .put(SFDC_MDF__c.Name, 'test')
                .put(SFDC_MDF__c.Spender_Confirmed__c ,true)
                .count(1)
                .create()
                .getRecords();
            
            //taruni
            
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
            test.startTest();
            pma = SobjectRepository.getPMA();

            
            
            
            
            
            
            
            
            
            
            
            SFDC_MDF__c fr3 = fundRequests[0];
            update fr3;
            
            SFDC_MDF__c fr4 = [Select id, Spender_Confirmed__c from SFDC_MDF__c where name = 'test' limit 1 ];
            
            Map<String, String> initialDataMap = new Map<String, String> ();
            Opportunity opp1 = [Select id, name from opportunity where name = 'TestOppty'
                                limit 1
                               ];
            
            initialDataMap = L2Q_GenericApprovalClass.getInitialData('SFDC_MDF__c', 'FundRequestApprovalFieldOrrideDetailJSON', opp1.id);
            Map<String, String> initialDataMap2 = L2Q_GenericApprovalClass.getInitialData('SFDC_MDF__c', 'FundRequestApprovalFieldOrrideDetailJSON', fr4.id);
            
            L2Q_GenericApprovalClass.getApprovalsForSpecifiedRecordId('recordId');
            L2Q_GenericApprovalClass.createPAElist(opp1.id); //taruni
            L2Q_GenericApprovalClass.checkPAEstep(opp1.id);
            
            
            
            
            
            SFDC_MDF__c fr = SobjectRepository.getDraftFundRequest();
            
            
            //taruni
            
           /* SFDC_Channel_Account_Plan__c cap = (SFDC_Channel_Account_Plan__c)new SobjectBuilder(SFDC_Channel_Account_Plan__c.sObjectType)
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
            pma = SobjectRepository.getPMA();*/
            
            
            
            
            L2Q_GenericApprovalClass.getApprovalsForSpecifiedRecordId(fr.Id);
            Map<String, Object> mapForFieldTOValue = new Map<String, Object> ();
            mapForFieldTOValue.put('Status__c', 'Rejected for Re-submit');
            L2Q_GenericApprovalClass.approveApprovalController('recordId', 'approvalComments', 'approvalWorkItemId', mapForFieldTOValue);
            L2Q_GenericApprovalClass.rejectApprovalController('recordId', 'approvalComments', 'approvalWorkItemId', new Map<String, Object> ());
            L2Q_GenericApprovalClass.reassignApprovalController('recordId', 'approvalComments', 'reassignTo', 'approvalWorkItemId');
            
            List<User> paeUsers = SObjectRepository.getSalesPAEUsers(1);
            fr.Partner_Account_Owner__c = paeUsers[0].Id;
            //taruni
            fr.Partner_Marketing_Activity__c = pma.Id;
            fr.Amount__c = 10;
            //fr.Status__c = 'Draft';
            
            
            update fr;
            
            // mark master mc as inactive
            Channel_Mapping__c cm = SobjectRepository.getMasterChannelMapping();
            
            cm.Master_Channel_Mapping__c = false;
            
            update cm;
            //test.startTest();
            User frOwner = new User(Id = fr.Partner_Account_Owner__c, IsActive = false);
            update frOwner;
            Test.setCurrentPage(Page.FundRequestButtonPage);
            ApexPages.currentPage().getParameters().put('fromButton', 'SubmitForApproval');
            ApexPages.currentPage().getParameters().put('recordId', fr.Id);
            ApexPages.currentPage().getParameters().put('userProfileId', UserInfo.getProfileId());
            
            FundRequestButtonPageController frbpc = new FundRequestButtonPageController();
            
            PageReference pageRef = frbpc.init();
            fr = [Select Id, Status__c,Spender_Confirmed__c from SFDC_MDF__c where id =: fr.Id];
            //System.assert(fr.Status__c=='Draft', 'Fund request got submitted even though account owner is inactive');
            frbpc.submitForApproval();
            L2Q_GenericApprovalClass.getApprovalsForSpecifiedRecordId(fr.Id);
            
            frbpc.associateToCampaign();
            frbpc.backToFundRequest();
            Group fundRequestQualityQueue = [Select Id, Name From Group Where Name = 'Fund Request Quality Queue' LIMIT 1]; //SDFC 7223
            //Set<Id> lst = L2Q_GenericApprovalClass.getValidApprovers('00G0f000005n0Cd');
            Set<Id> lst = L2Q_GenericApprovalClass.getValidApprovers(fundRequestQualityQueue.id);
            
            L2Q_GenericApprovalClass.createPAElist(fr.id); 
            //Set<Id> lst = L2Q_GenericApprovalClass.getValidApprovers('00G0f000005n0Cd');
            Map<String, String> mapObj = L2Q_GenericApprovalClass.getInitialData('', 'T', opp1.id);
            Map<String, String> mapObj1 = L2Q_GenericApprovalClass.getInitialData('SFDC_MDF__c', 'T', fr4.id);
            L2Q_GenericApprovalClass objobj = new L2Q_GenericApprovalClass();
            Test.stopTest();
        }
        
    }
}