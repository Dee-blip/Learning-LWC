@isTest
public class ApprovalHistoryPageControllerTestClass
{
    static User partner;

    public static void disableDealMakerCoreSettings()
    {
        /*DMAPP__Dealmaker_Core_Settings__c settings = DMAPP__Dealmaker_Core_Settings__c.getOrgDefaults();//new DMAPP__Dealmaker_Core_Settings__c(DMAPP__Create_Shadow_Opp_during_Opp_Upsert__c = false);
        System.debug('DMAPP__Dealmaker_Core_Settings__c=' + settings);
        if (settings!=null && settings.DMAPP__Create_Shadow_Opp_during_Opp_Upsert__c)
        {
            settings.DMAPP__Create_Shadow_Opp_during_Opp_Upsert__c=false;
            update settings;
        }*/
    }

    static testmethod void submitOpptyForApproval_Positive()
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            utilTestClass.insertCustomSettings();
            ManagedPkgErrorClass.isFromManagedPackage = false;
            disableDealMakerCoreSettings();
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
            cm.Partner_Group__c = 'Unknown';
            insert cm;

            Opportunity opp = utilTestClass.CreateOpportunity('__Test Opportunity','1-Create');
            opp.Channel_Manager__c = cm.Id;
            opp.End_Customer_Country__c = 'USA';
            opp.End_Customer_State__c = 'NY';
            opp.End_Customer_City__c = 'Buffalo';
            opp.End_Customer_Street_Address__c = 'Line1 \r\n Line2';
            opp.CloseDate= Date.today();
            opp.Partner_Involved__c = acc.Id;
            opp.AccountId = acc.Id;

            system.runAs(Partner)
            {
                Test.startTest();
                insert opp;
                Test.stopTest();
            }
            opp=[select id,FCM__c,Channel_Manager__c from Opportunity where id=:opp.id];
            System.assertEquals(opp.FCM__c,opptySCMOwnerUser.id);
            System.assertEquals(opp.Channel_Manager__c,cm.id);

            //Submit the Opportunity for Approval
            PRM_opportunity.submitForApproval(opp.id);

            PageReference pageRef = Page.ApprovalHistoryPage;
            Test.setCurrentPageReference(pageRef);
            pageRef.getParameters().put('pid', partner.id);
            ApexPages.StandardController sc = new ApexPages.StandardController(opp);
            ApprovalHistoryPageController fruc = new ApprovalHistoryPageController(sc);

            System.assert(fruc.showTable);
        }
    }

    static testmethod void submitOpptyForApproval_Negative()
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            utilTestClass.insertCustomSettings();
            ManagedPkgErrorClass.isFromManagedPackage = false;
            disableDealMakerCoreSettings();
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
            cm.Partner_Group__c = 'Unknown';
            insert cm;

            Opportunity opp = utilTestClass.CreateOpportunity('__Test Opportunity','1-Create');
            opp.Channel_Manager__c = cm.Id;
            opp.End_Customer_Country__c = 'USA';
            opp.End_Customer_State__c = 'NY';
            opp.End_Customer_City__c = 'Buffalo';
            opp.End_Customer_Street_Address__c = 'Line1 \r\n Line2';
            opp.CloseDate= Date.today();
            opp.Partner_Involved__c = acc.Id;
            opp.AccountId = acc.Id;

            system.runAs(Partner)
            {
                Test.startTest();
                insert opp;
                Test.stopTest();
            }
            opp=[select id,FCM__c,Channel_Manager__c from Opportunity where id=:opp.id];
            System.assertEquals(opp.FCM__c,opptySCMOwnerUser.id);
            System.assertEquals(opp.Channel_Manager__c,cm.id);

            PageReference pageRef = Page.ApprovalHistoryPage;
            Test.setCurrentPageReference(pageRef);
            pageRef.getParameters().put('pid', partner.id);
            ApexPages.StandardController sc = new ApexPages.StandardController(opp);
            ApprovalHistoryPageController fruc = new ApprovalHistoryPageController(sc);

            System.assertEquals(fruc.showTable,false);
        }
    }

    static testmethod void submitOpptyForApproval_Accepted()
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            utilTestClass.insertCustomSettings();
            ManagedPkgErrorClass.isFromManagedPackage = false;
            disableDealMakerCoreSettings();
            Account acc = utilTestClass.CreateAccount('__ test Account');
            insert acc;
            //Create a partner User for that account
            List<User> PartnerUsers=utilTestClass.createPartnerUsers(1,acc.id);
            partner=PartnerUsers[0];
            //Add the User to the chanell mapping table
            // Create 'SalesChannelMgr' User
            //Profile prSCM = [Select Id, Name from profile where id=:PRM_Settings__c.getInstance('Channel manager profile id').Value__c][0]; //SFDC-2573
            Profile prSCM = [Select Id, Name from profile where id=:GsmUtilClass.getPRMSettingValue('Channel_manager_profile_id')][0]; //SFDC-2573
            //Profile prSA = [Select Id, Name from profile where id=:PRM_Settings__c.getInstance('SystemAdminProfileID').Value__c][0]; //SFDC-2573
            Profile prSA = [Select Id, Name from profile where id=:GsmUtilClass.getPRMSettingValue('SystemAdminProfileID')][0]; //SFDC-2573

            UserRole roleDVA = [select id, name from UserRole where name='Worldwide'][0];
            User opptySCMOwnerUser = new User(alias = 'scmUsr1', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OpptyOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__mss_owner@akamai.com',profileid = prSCM.Id, UserRoleId = roleDVA.Id );
            insert opptySCMOwnerUser;


            //Channel_Mapping__c cm= new Channel_Mapping__c(Name = 'Test Channel Mapping', Partner_Name__c = acc.id, PAE_ID__c = opptySCMOwnerUser.id);
            Channel_Mapping__c cm = utilTestClass.CreateChannelMapping('Test Channel Mapping', acc.Id, opptySCMOwnerUser.Id);
            cm.Partner_Group__c = 'Unknown';
            insert cm;

            Opportunity opp = utilTestClass.CreateOpportunity('__Test Opportunity','1-Create');
            opp.Channel_Manager__c = cm.Id;
            opp.End_Customer_Country__c = 'USA';
            opp.End_Customer_State__c = 'NY';
            opp.End_Customer_City__c = 'Buffalo';
            opp.End_Customer_Street_Address__c = 'Line1 \r\n Line2';
            opp.CloseDate= Date.today();
            opp.Partner_Involved__c = acc.Id;
            opp.AccountId = acc.Id;
            system.runAs(Partner)
            {
                Test.startTest();
                insert opp;
                Test.stopTest();
            }
            opp=[select id,FCM__c,Channel_Manager__c from Opportunity where id=:opp.id];
            System.assertEquals(opp.FCM__c,opptySCMOwnerUser.id);
            System.assertEquals(opp.Channel_Manager__c,cm.id);


            Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();


            req1.setComments('Submitting request for approval.');
            req1.setObjectId(opp.id);


            // Submit the approval request for the account

            Approval.ProcessResult result = Approval.process(req1);


            String res = ApprovalHistoryPageController.redirectURL(String.ValueOf(opp.Id),'approveXPercent',False);

            List<Id> newWorkItemIds = result.getNewWorkitemIds();
            Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
            req2.setComments('Approving request.');
            req2.setAction('Approve');
            req2.setNextApproverIds(new Id[] {UserInfo.getUserId()});

            // Use the ID from the newly created item to specify the item to be worked

            req2.setWorkitemId(newWorkItemIds.get(0));
            // Submit the request for approval

            Approval.ProcessResult result2 =  Approval.process(req2);

            PageReference pageRef = Page.ApprovalHistoryPage;
            Test.setCurrentPageReference(pageRef);
            pageRef.getParameters().put('pid', partner.id);
            ApexPages.StandardController sc = new ApexPages.StandardController(opp);
            ApprovalHistoryPageController fruc = new ApprovalHistoryPageController(sc);
            //PageReference pr = fruc.redirectURLAcknowledged();


            opp=[select id,FCM__c,Channel_Manager__c, Rebate__c, Rebate_Type__c from Opportunity where id=:opp.id];

            // Verify the results
            System.assert(result2.isSuccess(), 'Result Status:'+result2.isSuccess());
            System.assertEquals('Pending', result2.getInstanceStatus(),'Instance Status'+result2.getInstanceStatus());


        }
    }

    static testmethod void submitOpptyForApproval_Rejected()
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            utilTestClass.insertCustomSettings();
            ManagedPkgErrorClass.isFromManagedPackage = false;
            disableDealMakerCoreSettings();
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
            cm.Partner_Group__c = 'Unknown';
            insert cm;

            Opportunity opp = utilTestClass.CreateOpportunity('__Test Opportunity','1-Create');
            opp.Channel_Manager__c = cm.Id;
            opp.End_Customer_Country__c = 'USA';
            opp.End_Customer_State__c = 'NY';
            opp.End_Customer_City__c = 'Buffalo';
            opp.End_Customer_Street_Address__c = 'Line1 \r\n Line2';
            opp.CloseDate= Date.today();
            opp.Partner_Involved__c = acc.Id;
            opp.AccountId = acc.Id;

            system.runAs(Partner)
            {
                Test.startTest();
                insert opp;
                Test.stopTest();
            }
            opp=[select id,FCM__c,Channel_Manager__c from Opportunity where id=:opp.id];
            System.assertEquals(opp.FCM__c,opptySCMOwnerUser.id);
            System.assertEquals(opp.Channel_Manager__c,cm.id);

            PageReference pageRef = Page.ApprovalHistoryPage;
            Test.setCurrentPageReference(pageRef);
            pageRef.getParameters().put('pid', partner.id);
            ApexPages.StandardController sc = new ApexPages.StandardController(opp);
            ApprovalHistoryPageController fruc = new ApprovalHistoryPageController(sc);
            //PageReference pr = fruc.redirectURLEarlyReg();


            String res = ApprovalHistoryPageController.redirectURL(String.ValueOf(opp.Id),'approveXPercent',False);

            Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
            req1.setComments('Submitting request for approval.');
            req1.setObjectId(opp.id);

            // Submit the approval request for the account
            Approval.ProcessResult result = Approval.process(req1);
            List<Id> newWorkItemIds = result.getNewWorkitemIds();
            Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
            req2.setComments('Rejecting request.');
            req2.setAction('Reject');
            req2.setNextApproverIds(new Id[] {UserInfo.getUserId()});
            // Use the ID from the newly created item to specify the item to be worked
            req2.setWorkitemId(newWorkItemIds.get(0));
            // Submit the request for approval
            Approval.ProcessResult result2 =  Approval.process(req2);

            PageReference pageRef2 = Page.ApprovalHistoryPage;
            Test.setCurrentPageReference(pageRef2);
            pageRef.getParameters().put('pid', partner.id);
            ApexPages.StandardController sc2 = new ApexPages.StandardController(opp);
            ApprovalHistoryPageController fruc2 = new ApprovalHistoryPageController(sc2);

            opp=[select id,FCM__c,Channel_Manager__c, Rebate__c, Rebate_Type__c from Opportunity where id=:opp.id];

            // Verify the results
            System.assertEquals('Rejected', result2.getInstanceStatus(),'Instance Status'+result2.getInstanceStatus());

            //System.assertEquals(fruc2.displayList[1][2], 'Rejected');
            System.assertEquals(opp.Rebate__c, '0');
        }
    }

    static testmethod void submitPubSecOpptyForApproval_Accepted()
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            utilTestClass.insertCustomSettings();
            ManagedPkgErrorClass.isFromManagedPackage = false;
            disableDealMakerCoreSettings();
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
            cm.Partner_Group__c = 'PUBSEC VAR';
            insert cm;

            Opportunity opp = utilTestClass.CreateOpportunity('__Test Opportunity','1-Create');
            opp.Channel_Manager__c = cm.Id;
            opp.End_Customer_Country__c = 'USA';
            opp.End_Customer_State__c = 'NY';
            opp.End_Customer_City__c = 'Buffalo';
            opp.End_Customer_Street_Address__c = 'Line1 \r\n Line2';
            opp.CloseDate= Date.today();
            opp.Partner_Involved__c = acc.Id;
            opp.AccountId = acc.Id;

            system.runAs(Partner)
            {
                Test.startTest();
                insert opp;
                Test.stopTest();
            }
            opp=[select id,FCM__c,Channel_Manager__c from Opportunity where id=:opp.id];
            System.assertEquals(opp.FCM__c,opptySCMOwnerUser.id);
            System.assertEquals(opp.Channel_Manager__c,cm.id);

            Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
            req1.setComments('Submitting request for approval.');
            req1.setObjectId(opp.id);

            // Submit the approval request for the account

            Approval.ProcessResult result = Approval.process(req1);

            String res = ApprovalHistoryPageController.redirectURL(String.ValueOf(opp.Id),'approveXPercent',False);

            List<Id> newWorkItemIds = result.getNewWorkitemIds();
            Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
            req2.setComments('Approving request.');
            req2.setAction('Approve');
            req2.setNextApproverIds(new Id[] {UserInfo.getUserId()});

            // Use the ID from the newly created item to specify the item to be worked

            req2.setWorkitemId(newWorkItemIds.get(0));

            // Submit the request for approval

            Approval.ProcessResult result2 =  Approval.process(req2);

            PageReference pageRef = Page.ApprovalHistoryPage;
            Test.setCurrentPageReference(pageRef);
            pageRef.getParameters().put('pid', partner.id);
            ApexPages.StandardController sc = new ApexPages.StandardController(opp);
            ApprovalHistoryPageController fruc = new ApprovalHistoryPageController(sc);
            //PageReference pr = fruc.redirectURLAcknowledged();


            opp=[select id,FCM__c,Channel_Manager__c, MDF__c, MDF_Type__c from Opportunity where id=:opp.id];

            // Verify the results
            System.assert(result2.isSuccess(), 'Result Status:'+result2.isSuccess());
            System.assertEquals('Pending', result2.getInstanceStatus(),'Instance Status'+result2.getInstanceStatus());


        }
    }

    static testmethod void submitPubSecOpptyForApproval_Rejected()
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            utilTestClass.insertCustomSettings();
            ManagedPkgErrorClass.isFromManagedPackage = false;
            disableDealMakerCoreSettings();
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
            cm.Partner_Group__c = 'PUBSEC VAR';
            insert cm;

            Opportunity opp = utilTestClass.CreateOpportunity('__Test Opportunity','1-Create');
            opp.Channel_Manager__c = cm.Id;
            opp.End_Customer_Country__c = 'USA';
            opp.End_Customer_State__c = 'NY';
            opp.End_Customer_City__c = 'Buffalo';
            opp.End_Customer_Street_Address__c = 'Line1 \r\n Line2';
            opp.CloseDate= Date.today();
            opp.Partner_Involved__c = acc.Id;
            opp.AccountId = acc.Id;

            system.runAs(Partner)
            {
                Test.startTest();
                insert opp;
                Test.stopTest();
            }
            opp=[select id,FCM__c,Channel_Manager__c from Opportunity where id=:opp.id];
            System.assertEquals(opp.FCM__c,opptySCMOwnerUser.id);
            System.assertEquals(opp.Channel_Manager__c,cm.id);

            PageReference pageRef = Page.ApprovalHistoryPage;
            Test.setCurrentPageReference(pageRef);
            pageRef.getParameters().put('pid', partner.id);
            ApexPages.StandardController sc = new ApexPages.StandardController(opp);
            ApprovalHistoryPageController fruc = new ApprovalHistoryPageController(sc);
            //PageReference pr = fruc.redirectURLEarlyReg();
            String res = ApprovalHistoryPageController.redirectURL(String.ValueOf(opp.Id),'approveXPercent',False);

            Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
            req1.setComments('Submitting request for approval.');
            req1.setObjectId(opp.id);

            // Submit the approval request for the account
            Approval.ProcessResult result = Approval.process(req1);
            List<Id> newWorkItemIds = result.getNewWorkitemIds();
            Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
            req2.setComments('Rejecting request.');
            req2.setAction('Reject');
            req2.setNextApproverIds(new Id[] {UserInfo.getUserId()});
            // Use the ID from the newly created item to specify the item to be worked
            req2.setWorkitemId(newWorkItemIds.get(0));
            // Submit the request for approval
            Approval.ProcessResult result2 =  Approval.process(req2);

            PageReference pageRef2 = Page.ApprovalHistoryPage;
            Test.setCurrentPageReference(pageRef2);
            pageRef.getParameters().put('pid', partner.id);
            ApexPages.StandardController sc2 = new ApexPages.StandardController(opp);
            ApprovalHistoryPageController fruc2 = new ApprovalHistoryPageController(sc2);

            opp=[select id,FCM__c,Channel_Manager__c, MDF__c, MDF_Type__c from Opportunity where id=:opp.id];

            // Verify the results
            System.assertEquals('Rejected', result2.getInstanceStatus(),'Instance Status'+result2.getInstanceStatus());

            //Since there are multiple approvers for this request, displayList actual position is hard to predict here
            //System.assertEquals(fruc2.displayList[1][2], 'Rejected');
            System.assertEquals(opp.MDF__c, '0');
        }
    }
}