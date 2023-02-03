@isTest
public class GenericApprovalProcessTest {

    private static User dmlUser = new User(id=UserInfo.getUserId());
    private static final Integer numberOfFundBudgets = 3;
    static User partner;

    static testmethod void testGenericApprovalProcessGetData()
    {
        Map<String, String> objectToCustomSettingResource = new Map<String, String>{ 
                'Communities_Settings__c'   => 'CS_Communities_Settings',
                'LunaControlCenterSettings__c' => 'CS_LunaControlCenterSettings',
                'Environment_Setup__c' => 'CS_Environment_Setup'
        };
        System.runAs(dmlUser)
        {
            utilTestClass.insertCustomSettings(objectToCustomSettingResource);
            SObjectFactory.createPartnerUsers(1);
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
            // active master channel mapping with fr approver
            Channel_Mapping__c cm = (Channel_Mapping__c)new SobjectBuilder(Channel_Mapping__c.sObjectType)
                .eagerPopulate()
                .put(Channel_Mapping__c.PAE_ID__c, paeUsers[0].Id)
                .put(Channel_Mapping__c.MDF_Approver__c, paeUsers[1].Id)
                .put(Channel_Mapping__c.Partner_Name__c, partAccount.Id)
                .create()
                .getRecord();


            // submit the two FRs for approval
            PRMTriggerClass.InitializeFlagVariables();
            TestUtils.submitForApproval(fr1);
            PRMTriggerClass.InitializeFlagVariables();

            TestUtils.submitForApproval(fr2);
            PRMTriggerClass.InitializeFlagVariables();

            Test.startTest();
            GenericApprovalProcessController.getReassignableData(fr1.id);
            Test.stopTest();
        }

    }
    
    static testmethod void testGenericApprovalProcessApproval()
    {
        Map<String, String> objectToCustomSettingResource = new Map<String, String>{ 
                'Communities_Settings__c'   => 'CS_Communities_Settings',
                'LunaControlCenterSettings__c' => 'CS_LunaControlCenterSettings',
                'Environment_Setup__c' => 'CS_Environment_Setup'
        };
        System.runAs(dmlUser)
        {
            utilTestClass.insertCustomSettings(objectToCustomSettingResource);
            SObjectFactory.createPartnerUsers(1);
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
            // active master channel mapping with fr approver
            Channel_Mapping__c cm = (Channel_Mapping__c)new SobjectBuilder(Channel_Mapping__c.sObjectType)
                .eagerPopulate()
                .put(Channel_Mapping__c.PAE_ID__c, paeUsers[0].Id)
                .put(Channel_Mapping__c.MDF_Approver__c, paeUsers[1].Id)
                .put(Channel_Mapping__c.Partner_Name__c, partAccount.Id)
                .create()
                .getRecord();


            // submit the two FRs for approval
            PRMTriggerClass.InitializeFlagVariables();
            //TestUtils.submitForApproval(fr1);
            Approval.ProcessSubmitRequest app = new Approval.ProcessSubmitRequest();
		    app.setObjectId(fr1.id);
		    Approval.ProcessResult result = Approval.process(app);
            PRMTriggerClass.InitializeFlagVariables();

            TestUtils.submitForApproval(fr2);
            PRMTriggerClass.InitializeFlagVariables();

            Test.startTest();
            List<ProcessInstance> PIList =  [Select Status,TargetObjectId,
                                             	(Select Id From Workitems ORDER BY CreatedDate DESC),
                                                        (Select Id From Nodes ORDER BY CreatedDate DESC) ,
                                                        (Select Id From StepsAndWorkitems ORDER BY CreatedDate DESC)
                                                 From ProcessInstance p 
                                                 WHERE TargetObjectId =:fr1.id Order by CreatedDate Desc];
            
            String approvalComments = 'Approved level';
            Map<String,Object> mapForFieldTOValue = new Map<String,Object>();
            mapForFieldTOValue.put('Status__c','Rejected for Re-submit');
            GenericApprovalProcessController.approveItem(PIList[0].Workitems[0].id,approvalComments,fr1.id,mapForFieldTOValue);
            Test.stopTest();
        }

    }
    
    static testmethod void testGenericApprovalProcessRejection()
    {
        Map<String, String> objectToCustomSettingResource = new Map<String, String>{ 
                'Communities_Settings__c'   => 'CS_Communities_Settings',
                'LunaControlCenterSettings__c' => 'CS_LunaControlCenterSettings',
                'Environment_Setup__c' => 'CS_Environment_Setup'
        };
        System.runAs(dmlUser)
        {
            utilTestClass.insertCustomSettings(objectToCustomSettingResource);
            SObjectFactory.createPartnerUsers(1);
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
            // active master channel mapping with fr approver
            Channel_Mapping__c cm = (Channel_Mapping__c)new SobjectBuilder(Channel_Mapping__c.sObjectType)
                .eagerPopulate()
                .put(Channel_Mapping__c.PAE_ID__c, paeUsers[0].Id)
                .put(Channel_Mapping__c.MDF_Approver__c, paeUsers[1].Id)
                .put(Channel_Mapping__c.Partner_Name__c, partAccount.Id)
                .create()
                .getRecord();


            // submit the two FRs for approval
            PRMTriggerClass.InitializeFlagVariables();
            //TestUtils.submitForApproval(fr1);
            Approval.ProcessSubmitRequest app = new Approval.ProcessSubmitRequest();
		    app.setObjectId(fr1.id);
		    Approval.ProcessResult result = Approval.process(app);
            PRMTriggerClass.InitializeFlagVariables();

            TestUtils.submitForApproval(fr2);
            PRMTriggerClass.InitializeFlagVariables();

            Test.startTest();
            List<ProcessInstance> PIList =  [Select Status,TargetObjectId,
                                             	(Select Id From Workitems ORDER BY CreatedDate DESC),
                                                        (Select Id From Nodes ORDER BY CreatedDate DESC) ,
                                                        (Select Id From StepsAndWorkitems ORDER BY CreatedDate DESC)
                                                 From ProcessInstance p 
                                                 WHERE TargetObjectId =:fr1.id Order by CreatedDate Desc];
            
            String rejectionComments = 'Rejected level';
            String rejectType = 'Rejected';
            Map<String,Object> mapForFieldTOValue = new Map<String,Object>();
            mapForFieldTOValue.put('Status__c','Rejected for Re-submit');
            GenericApprovalProcessController.rejectItem((String)PIList[0].Workitems[0].id,rejectionComments,(String)fr1.id,mapForFieldTOValue);
            Test.stopTest();
        }

    }

    public static testmethod void testGenericApprovalProcessForOpportunityValidation()
    {
      System.runAs(utilTestClass.getTestRunUser())
      {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        utilTestClass.insertCustomSettings();
        ApprovalHistoryPageControllerTestClass.disableDealMakerCoreSettings();
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
        
        //Submit the Opportunity for Approval
        PRM_opportunity.submitForApproval(opp.Id);
        PRM_opportunity.submitForApproval(opp2.Id);

        Opportunity oppty = [Select id,Deal_Reg_Approval_Level__c From Opportunity where id=:opp.id];
        oppty.Deal_Reg_Approval_Level__c = 'First-Level Approved';
        update oppty;

        //Test.startTest();
            List<ProcessInstance> PIList =  [Select Status,TargetObjectId,
                                             	(Select Id From Workitems ORDER BY CreatedDate DESC),
                                                        (Select Id From Nodes ORDER BY CreatedDate DESC) ,
                                                        (Select Id From StepsAndWorkitems ORDER BY CreatedDate DESC)
                                                 From ProcessInstance p 
                                                 WHERE TargetObjectId =:opp.id Order by CreatedDate Desc];
            
            String approveComments = 'Approve level';
            Map<String,Object> mapForFieldTOValue = new Map<String,Object>();
            mapForFieldTOValue.put('Managed_By__c','Partner');
            Database.Error[] listOfErrors = new Database.Error[]{};
            GenericApprovalProcessUtil.getConsolidatedErrors(listOfErrors);
            GenericApprovalProcessUtil.reAssign_approver_wrapper r = new GenericApprovalProcessUtil.reAssign_approver_wrapper(Partner.name,Partner.id);
            GenericApprovalProcessController.approveItem((String)PIList[0].Workitems[0].id,approveComments,(String)opp.id,mapForFieldTOValue);
           // Test.stopTest();
         
      }
    }

    public static testmethod void testGenericApprovalProcessForOpportunity()
    {
      System.runAs(utilTestClass.getTestRunUser())
      {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        utilTestClass.insertCustomSettings();
        ApprovalHistoryPageControllerTestClass.disableDealMakerCoreSettings();
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
        
        //Submit the Opportunity for Approval
        PRM_opportunity.submitForApproval(opp.Id);
        PRM_opportunity.submitForApproval(opp2.Id);

        //Test.startTest();
            List<ProcessInstance> PIList =  [Select Status,TargetObjectId,
                                             	(Select Id From Workitems ORDER BY CreatedDate DESC),
                                                        (Select Id From Nodes ORDER BY CreatedDate DESC) ,
                                                        (Select Id From StepsAndWorkitems ORDER BY CreatedDate DESC)
                                                 From ProcessInstance p 
                                                 WHERE TargetObjectId =:opp.id Order by CreatedDate Desc];
            
            String approveComments = 'Approve level';
            Map<String,Object> mapForFieldTOValue = new Map<String,Object>();
            mapForFieldTOValue.put('Managed_By__c','Partner');
            Database.Error[] listOfErrors = new Database.Error[]{};
            GenericApprovalProcessUtil.getConsolidatedErrors(listOfErrors);
            GenericApprovalProcessUtil.reAssign_approver_wrapper r = new GenericApprovalProcessUtil.reAssign_approver_wrapper(Partner.name,Partner.id);
            GenericApprovalProcessController.approveItem((String)PIList[0].Workitems[0].id,approveComments,(String)opp.id,mapForFieldTOValue);
           // Test.stopTest();
         
      }
    }
    
    static testmethod void testGenericApprovalProcessReassign()
    {
        Map<String, String> objectToCustomSettingResource = new Map<String, String>{ 
                'Communities_Settings__c'   => 'CS_Communities_Settings',
                'LunaControlCenterSettings__c' => 'CS_LunaControlCenterSettings',
                'Environment_Setup__c' => 'CS_Environment_Setup'
        };
        System.runAs(dmlUser)
        {
            utilTestClass.insertCustomSettings(objectToCustomSettingResource);
            SObjectFactory.createPartnerUsers(1);
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
            // active master channel mapping with fr approver
            Channel_Mapping__c cm = (Channel_Mapping__c)new SobjectBuilder(Channel_Mapping__c.sObjectType)
                .eagerPopulate()
                .put(Channel_Mapping__c.PAE_ID__c, paeUsers[0].Id)
                .put(Channel_Mapping__c.MDF_Approver__c, paeUsers[1].Id)
                .put(Channel_Mapping__c.Partner_Name__c, partAccount.Id)
                .create()
                .getRecord();


            // submit the two FRs for approval
            PRMTriggerClass.InitializeFlagVariables();
            //TestUtils.submitForApproval(fr1);
            Approval.ProcessSubmitRequest app = new Approval.ProcessSubmitRequest();
		    app.setObjectId(fr1.id);
		    Approval.ProcessResult result = Approval.process(app);
            PRMTriggerClass.InitializeFlagVariables();

            TestUtils.submitForApproval(fr2);
            PRMTriggerClass.InitializeFlagVariables();

            Test.startTest();
            List<ProcessInstance> PIList =  [Select Status,TargetObjectId,
                                             	(Select Id From Workitems ORDER BY CreatedDate DESC),
                                                        (Select Id From Nodes ORDER BY CreatedDate DESC) ,
                                                        (Select Id From StepsAndWorkitems ORDER BY CreatedDate DESC)
                                                 From ProcessInstance p 
                                                 WHERE TargetObjectId =:fr1.id Order by CreatedDate Desc];
            
            String reassignComments = 'Reassigned';
            GenericApprovalProcessController.reassignItem((String)PIList[0].Workitems[0].id,UserInfo.getUserId(),(String)fr1.id,reassignComments);
            Test.stopTest();
        }

    }
    
}