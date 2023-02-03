@isTest(seeAllData=false)
public class AccountReassignmentTestClass {
    //static User
    static User dmlUser = utilTestClass.getTestRunUser();
    
    // Setup method to create test data.
    @testSetup
    static void setupMethod() {
        System.runAs(dmlUser) {
            User oldOwner,oldOwnerRSM,newOwner,newOwnerRSM,oldSalesOpsUser,newSalesOpsUser;
            Account_Reassignment_Rule__c oldOwnerRule,newOwnerRule;
            List<Territory_Mapping__c> tms = (List<Territory_Mapping__c>)new SobjectBuilder(Territory_Mapping__c.sObjectType)
                .count(5)
                .create()
                .getRecords();
            Profile pr = [select id from profile where name='Sales Operations'][0];
            UserRole role = [select id, Name from UserRole where name=:GsmUtilClass.getGSMSettingValue('User_Role')][0];
            Id salesRepProfileId = [select id from profile where name='Sales - Media'][0].Id;
            String roleName = GsmUtilClass.getGSMSettingValue('User_Role');
            Id roleId = [select Id from UserRole where name=:roleName][0].Id;
            List<User> userList = new List<User>();
            User accOldOwnerUser = new User(alias = 'oldUser', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__old_owner@akamai.com',profileid = pr.Id, UserRoleId = role.Id );
            userList.add(accOldOwnerUser);
            User accNewOwnerUser = new User(alias = 'newUser', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='NewOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__new_user@akamai.com',profileid = pr.Id, UserRoleId = role.Id );
            userList.add(accNewOwnerUser);
            User tmUser1 = new User(alias = 'tmUser1', email='stdusr1@akamai.com',emailencodingkey='UTF-8', lastname='TmUser1', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__team_member1@akamai.com',profileid = pr.Id, UserRoleId = role.Id );
            userList.add(tmUser1);
            User tmUser2 = new User(alias = 'tmUser2', email='stdusr1@akamai.com',emailencodingkey='UTF-8', lastname='TmUser2', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__team_member2@akamai.com',profileid = pr.Id, UserRoleId = role.Id );
            userList.add(tmUser2);
            oldOwner = CreateUser('TST_OUSR', salesRepProfileId, roleId);
            userList.add(oldOwner);
            oldOwnerRSM = CreateUser('TST_ORSM', salesRepProfileId, roleId);
            userList.add(oldOwnerRSM);
            newOwner = CreateUser('TST_NUSR', salesRepProfileId, roleId);
            userList.add(newOwner);
            newOwnerRSM = CreateUser('TST_NRSM', salesRepProfileId, roleId);
            userList.add(newOwnerRSM);
            oldSalesOpsUser = CreateUser('TST_OPS1', salesRepProfileId, roleId);
            userList.add(oldSalesOpsUser);
            newSalesOpsUser = CreateUser('TST_OPS2', salesRepProfileId, roleId);
            userList.add(newSalesOpsUser);
            insert userList;
            
            User ONAUser = [SELECT Id, Name FROM User WHERE ALIAS = 'ONA'][0];
            
            Account_Reassignment_Rule__c ONAReassignmentRule = utilTestClass.CreateAccountReassignmentRule('No Owner', ONAUser.Id, 'Owner Not Assigned');
            ONAReassignmentRule.Territory_ID__c = tms[0].Id;
            
            List<Account_Reassignment_Rule__c> ruleList = new List<Account_Reassignment_Rule__c>();
            Account_Reassignment_Rule__c rule = utilTestClass.CreateAccountReassignmentRule('__TestRule', accNewOwnerUser.Id, role.Name);
            rule.Territory_ID__c = tms[1].Id;
            
            Account_Reassignment_Rule__c oldRule = utilTestClass.CreateAccountReassignmentRule('__OldRule', accOldOwnerUser.Id, role.Name);
            oldRule.Territory_ID__c = tms[2].Id;
            
            oldOwnerRule = utilTestClass.CreateAccountReassignmentRule(oldOwner.ALIAS, oldOwner.Id, roleName);
            oldOwnerRule.Associated_User_RSM__c = oldOwnerRSM.Id;
            oldOwnerRule.Territory_ID__c = tms[3].Id;
            oldOwnerRule.Sales_Ops_Approver__c = oldSalesOpsUser.id;
            
            newOwnerRule = utilTestClass.CreateAccountReassignmentRule(newOwner.ALIAS, newOwner.Id, roleName);
            newOwnerRule.Associated_User_RSM__c = newOwnerRSM.Id;
            newOwnerRule.Territory_ID__c = tms[4].Id;
            newOwnerRule.Sales_Ops_Approver__c = newSalesOpsUser.id;
            
            insert (new Account_Reassignment_Rule__c[] {ONAReassignmentRule, oldOwnerRule, newOwnerRule,rule, oldRule});
        }
    }
    
    private static User CreateUser(String pUsrAlias, Id profileId, Id roleId) {
        User newUser = new User(alias = pUsrAlias,
                                email=pUsrAlias+'@akamai.com',
                                emailencodingkey='UTF-8',
                                lastname=pUsrAlias,
                                languagelocalekey='en_US',
                                localesidkey='en_US',
                                timezonesidkey='America/Los_Angeles',
                                username=pUsrAlias+'@akamai.com.tclass',
                                profileid = profileId,
                                UserRoleId = roleId );
        return newUser;
    }
    
    @isTest static void test_UpdateMissingAccReassignRelatedRecords(){
        Account_Reassignment_Rule__c rule = [select Id from Account_Reassignment_Rule__c where Name='__TestRule' limit 1][0];
        User accOldOwnerUser = [select Id from User where alias = 'oldUser'][0];
        Account acc=utilTestClass.CreateAccount('__Test Account');
        acc.OwnerId=accOldOwnerUser.Id;
        system.runAs(accOldOwnerUser){
            insert acc;
        }
        Opportunity oppty = utilTestClass.CreateOpportunity('__Test Oppty','1. Identify Need');
        oppty.AccountId=acc.Id;
        oppty.OwnerId=accOldOwnerUser.Id;
        oppty.CloseDate=Date.today().addMonths(4);
        insert oppty;
        Contact con=utilTestClass.CreateContact('__ Test First','__Test Contact');
        con.AccountId=acc.Id;
        con.OwnerId=accOldOwnerUser.Id;
        con.Projected_SDR__c=UserInfo.getUserId();
        insert con;
        Account_Reassignment__c accReassign = utilTestClass.CreateAccountReassignment(acc.Id, rule.Id);
        accReassign.Is_Opportunity_Failed__c=true;
        accReassign.Is_Contact_Failed__c=true;
        insert accReassign;
        Test.startTest();
        UpdateMissingAccReassignRelatedRecords obj = new UpdateMissingAccReassignRelatedRecords();
        Database.executeBatch(obj,10);
        Test.stopTest();
    } 
    
    @isTest static void test_UpdateOpptyOnAccountOwnerChangeBatch(){
        User accOldOwnerUser = [select Id from User where alias = 'oldUser'][0];
        Account acc=utilTestClass.CreateAccount('__Test Account');
        acc.OwnerId=accOldOwnerUser.Id;
        system.runAs(accOldOwnerUser){
            insert acc;
        }
        Opportunity oppty = utilTestClass.CreateOpportunity('__Test Oppty','1. Identify Need');
        oppty.AccountId=acc.Id;
        oppty.CloseDate=Date.today().addMonths(4);
        insert oppty;
        acc.OwnerId=UserInfo.getUserId();
        update acc;
        Test.startTest();
        UpdateOpptyOnAccountOwnerChangeBatch obj = new UpdateOpptyOnAccountOwnerChangeBatch(new list<string>{acc.Id});
        Database.executeBatch(obj,10);
        Test.stopTest();
    }
    
    @isTest static void test_UpdateContactOnAccountOwnerChangeBatch(){
        User accOldOwnerUser = [select Id from User where alias = 'oldUser'][0];
        Account acc=utilTestClass.CreateAccount('__Test Account');
        acc.OwnerId=accOldOwnerUser.Id;
        system.runAs(accOldOwnerUser){
            insert acc;
        }
        Contact con=utilTestClass.CreateContact('__ Test First','__Test Contact');
        con.AccountId=acc.Id;
        con.OwnerId=accOldOwnerUser.Id;
        insert con;
        acc.OwnerId=UserInfo.getUserId();
        update acc;
        Test.startTest();
        UpdateContactOnAccountOwnerChangeBatch obj = new UpdateContactOnAccountOwnerChangeBatch(new list<string>{acc.Id});
        Database.executeBatch(obj,10);
        Test.stopTest();
    }
    
    @isTest static void test_UpdateLeadOnAccountOwnerChangeBatch(){
        User accOldOwnerUser = [select Id from User where alias = 'oldUser'][0];
        Account acc=utilTestClass.CreateAccount('__Test Account');
        acc.OwnerId=accOldOwnerUser.Id;
        system.runAs(accOldOwnerUser){
            insert acc;
        }
        Id marketoRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
        Lead l = new Lead();
        l.Associated_Account__c=acc.Id;
        l.RecordTypeId=marketoRecordTypeId;
        l.email = 'testemail@email.com';
        l.status = 'New';
        l.lastname = 'Lead';
        l.company = 'Test Company';
        l.Validation_Override__c = true;
        insert l;
        acc.OwnerId=UserInfo.getUserId();
        update acc;
        Test.startTest();
        UpdateLeadOnAccountOwnerChangeBatch obj = new UpdateLeadOnAccountOwnerChangeBatch(new list<string>{acc.Id});
        Database.executeBatch(obj,10);
        Test.stopTest();
    }
    
    @isTest static void test_AccountReassignmentTriggerClass(){
        Account_Reassignment_Rule__c rule = [select Id from Account_Reassignment_Rule__c where Name='__TestRule' limit 1][0];
        User accOldOwnerUser = [select Id from User where alias = 'oldUser'][0];
        Account acc=utilTestClass.CreateAccount('__Test Account');
        acc.OwnerId=accOldOwnerUser.Id;
        system.runAs(accOldOwnerUser){
            insert acc;
        }
        Opportunity oppty = utilTestClass.CreateOpportunity('__Test Oppty','1. Identify Need');
        oppty.AccountId=acc.Id;
        oppty.OwnerId=accOldOwnerUser.Id;
        oppty.CloseDate=Date.today().addMonths(4);
        insert oppty;
        Contact con=utilTestClass.CreateContact('__ Test First','__Test Contact');
        con.AccountId=acc.Id;
        con.OwnerId=accOldOwnerUser.Id;
        con.Projected_SDR__c=UserInfo.getUserId();
        insert con;
        Account_Reassignment__c accReassign = utilTestClass.CreateAccountReassignment(acc.Id, rule.Id);
        accReassign.Is_Opportunity_Failed__c=true;
        accReassign.Is_Contact_Failed__c=true;
        insert accReassign;
        Test.startTest();
        Id pActiveAccountReqEscalationTemplateId = [Select Id, DeveloperName from EmailTemplate where DeveloperName='AccountReassignmentEscalationRequest'][0].Id;
        AccountReassignmentTriggerClass.updateRequestForSalesAccount(new set<Id>{acc.Id});
        AccountReassignmentTriggerClass.updateNoApprovalRequired(new list<Id>{accReassign.Id});
        AccountReassignmentTriggerClass.createSingleEmailWithVFTemplate(accReassign.Id,UserInfo.getUserId(),'','',pActiveAccountReqEscalationTemplateId);
        AccountReassignmentTriggerClass.sendActiveAccountReassignmentEmails(new List<Account_Reassignment__c>{accReassign},pActiveAccountReqEscalationTemplateId,null);
        AccountReassignmentTriggerClass.submitForApproval(new List<Id>{accReassign.Id});
        AccountReassignmentTriggerClass.updateAccountRelatedRecords(new list<string>{acc.Id});
        AccountReassignmentTriggerClass.updateAccountShareForPartnerAdmins(new list<string>{acc.Id});
        AccountReassignmentTriggerClass.updateOpptysChannelLevel(new list<string>{acc.Id});
        AccountReassignmentTriggerClass.createAccountReassignmentRequests(new List<Account>{acc});
        Test.stopTest();
    } 
    
    @isTest static void test_AccountReassignmentPageController(){
        User accOldOwnerUser = [select Id from User where alias = 'oldUser'][0];
        Account acc=utilTestClass.CreateAccount('__Test Account');
        acc.OwnerId=accOldOwnerUser.Id;
        system.runAs(accOldOwnerUser){
            insert acc;
        }
        PageReference aPage = Page.AccountReassignment2;
        aPage.getParameters().put('id', acc.Id);
        test.setCurrentPage(aPage);
        AccountReassignmentPageController cntrl = new AccountReassignmentPageController();
        cntrl.save();
        cntrl.cancel();
        PageReference aPage1 = Page.AccountReassignment2;
        aPage1.getParameters().put('id', '');
        test.setCurrentPage(aPage1);
        AccountReassignmentPageController cntrl1 = new AccountReassignmentPageController();
        cntrl1.accOwner=[select id from User where id =: UserInfo.getUserId()];
        cntrl1.isAccountActive=true;
        cntrl1.isRevenueAccount=true;
        cntrl1.isNetOpsOwnedAccount=true;
        cntrl1.isAdminProfile=true;
    }
    
    @isTest static void test_AccountReassignmentBatchClass(){
        User newOwner,oldOwner;
        List<String> userAliasList = new List<String>{'TST_NUSR','TST_OUSR'};
            for(User u : [select Id, ALIAS, Name from User where ALIAS IN : userAliasList]){
                if(u.ALIAS == 'TST_NUSR')
                    newOwner = u;
                else if(u.ALIAS == 'TST_OUSR')
                    oldOwner = u;
            }
        Account_Reassignment_Rule__c newOwnerRule = [select Id from Account_Reassignment_Rule__c where Name='TST_NUSR' limit 1][0];
        Account acc = utilTestClass.CreateAccount('__AccReass_TestCase_');
        Contact con = utilTestClass.CreateContact('test', 'cnt');
        
        acc.OwnerId = oldOwner.Id;
        acc.Type = 'ISP - Active';
        acc.Partner_Type__c='Unknown';
        acc.Revenue_Account__c=true;
        system.runAs(oldOwner)
        {
            insert acc;
            Test.startTest();
            con.AccountId = acc.Id;
            insert con;
            
        }
        // newOwner requests for the account
        system.runAs(newOwner)
        {
            Account_Reassignment__c accReassign=new Account_Reassignment__c();
            accReassign.Account__c=acc.Id;
            accReassign.Assign_To__c=newOwnerRule.Id;
            accReassign.Approver_2__c = UserInfo.getUserId();
            accReassign.Approver_1__c = UserInfo.getUserId();
            insert accReassign;
            accReassign.Reassign__c=false;
            accReassign.Reassign_Status__c = 'Approved';
            accReassign.Reassignment_Due_Date__c = System.today();
            update accReassign;
        }
        Integer batchSize = Integer.valueOf(GSMSettings.getValue('AccountReassignmentBatchClass_BatchSize'));
        AccountReassignmentBatchClass batchObj = new AccountReassignmentBatchClass();
        Database.executebatch(batchObj,batchSize);
        Test.stopTest();
    }
    /*
    @isTest static void test_AccountReassignmentAutoRejectEmailNotification(){
          User newOwner,oldOwner;
        List<String> userAliasList = new List<String>{'TST_NUSR','TST_OUSR'};
            for(User u : [select Id, ALIAS, Name from User where ALIAS IN : userAliasList]){
                if(u.ALIAS == 'TST_NUSR')
                    newOwner = u;
                else if(u.ALIAS == 'TST_OUSR')
                    oldOwner = u;
            }

        Account_Reassignment_Rule__c newOwnerRule = [select Id from Account_Reassignment_Rule__c where Name='TST_NUSR' limit 1][0];
        Account acc = utilTestClass.CreateAccount('__AccReass_TestCase_EmailNotification');
        Contact con = utilTestClass.CreateContact('test', 'cnt');
        
        acc.OwnerId = oldOwner.Id;
        acc.Type = 'ISP - Active';
        acc.Partner_Type__c='Unknown';
        acc.Revenue_Account__c=true;
        system.runAs(oldOwner)
        {
            insert acc;
            Test.startTest();
            con.AccountId = acc.Id;
            insert con;
            
        }
        List<Account_Reassignment__c> arrListUpdate = new List<Account_Reassignment__c>();
        Account_Reassignment__c accReassign=new Account_Reassignment__c();
        Account_Reassignment__c accReassign1=new Account_Reassignment__c();
        Account_Reassignment__c accReassign2=new Account_Reassignment__c();
        system.runAs(newOwner)
        {
            List<Account_Reassignment__c> arrListInsert = new List<Account_Reassignment__c>();
            
            
            accReassign.Account__c=acc.Id;
            accReassign.Assign_To__c=newOwnerRule.Id;
            accReassign.Approver_2__c = UserInfo.getUserId();
            accReassign.Approver_1__c = UserInfo.getUserId();
            arrListInsert.add(accReassign);
                   
            accReassign1.Account__c=acc.Id;
            accReassign1.Assign_To__c=newOwnerRule.Id;
            accReassign1.Approver_2__c = UserInfo.getUserId();
            accReassign1.Approver_1__c = UserInfo.getUserId();
            arrListInsert.add(accReassign1);

            accReassign2.Account__c=acc.Id;
            accReassign2.Assign_To__c=newOwnerRule.Id;
            accReassign2.Approver_2__c = UserInfo.getUserId();
            accReassign2.Approver_1__c = UserInfo.getUserId();
            arrListInsert.add(accReassign2);

            Insert arrListInsert;

            List<Approval.ProcessSubmitRequest> reqList = new List<Approval.ProcessSubmitRequest>();
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();          
            req.setComments('Submitting approval request using Trigger');        
            req.setObjectId(accReassign.id);
            reqList.add(req);

            Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();          
            req1.setComments('Submitting approval request using Trigger');        
            req1.setObjectId(accReassign1.id);
            reqList.add(req1);

            Approval.ProcessSubmitRequest req2 = new Approval.ProcessSubmitRequest();          
            req2.setComments('Submitting approval request using Trigger');        
            req2.setObjectId(accReassign2.id);
            reqList.add(req2);

            Approval.process(reqList);

            Test.stopTest();
        }

        accReassign.Approval_Submitted_Date__c = Date.today().addDays(-1 * Integer.valueof(GsmUtilClass.getGSMSettingValue('Acc_Reassignment_Pending_Days_Interval')));
        arrListUpdate.add(accReassign);
        accReassign1.Approval_Submitted_Date__c = Date.today().addDays(-1* Integer.valueof(GsmUtilClass.getGSMSettingValue('AccReassignment_AutoReject_Days_Interval')));
        arrListUpdate.add(accReassign1);
        accReassign2.Approval_Submitted_Date__c = Date.today().addDays(-1* Integer.valueof(GsmUtilClass.getGSMSettingValue('Acc_Reassignment_Reminder_Days_Interval')));
        arrListUpdate.add(accReassign2);

        Update arrListUpdate;

        GSM_AccountReassignmentAutoRejection ArrReasignmentAutoReject = new GSM_AccountReassignmentAutoRejection();
        ArrReasignmentAutoReject.sendMailAndAutoRejectARR();
    }*/
}