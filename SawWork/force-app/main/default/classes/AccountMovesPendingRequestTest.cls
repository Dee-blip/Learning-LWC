@isTest(seeAllData=false)
public class AccountMovesPendingRequestTest {

    //static User
    static User dmlUser = utilTestClass.getTestRunUser();

    // Setup method to create test data.
    @testSetup
    static void setupMethod()
    {
        System.runAs(dmlUser) {
            ManagedPkgErrorClass.isFromManagedPackage = false;
            User oldOwner,oldOwnerRSM,newOwner,newOwnerRSM,accNewOwnerUser2,accNewOwnerUser;
            Territory_Mapping__c oldTM,newTM;
            Account_Reassignment_Rule__c oldOwnerRule,newOwnerRule;

            List<String> profileNames = new List<String>{'Sales - Media','Sales Operations'};

            Id salesRepProfileId, salesOpsProfileId;
            for(Profile p : [Select Id,Name from profile where name IN : profileNames]){
                If(p.Name == 'Sales - Media')
                    salesRepProfileId = p.Id;
                else
                    salesOpsProfileId = p.Id;
            }

            String roleName = GsmUtilClass.getGSMSettingValue('User_Role');
            Id roleId = [select Id from UserRole where name =: roleName][0].Id;

            // Create Old Owner User
            oldOwner = CreateUser('TST_OUSR', salesRepProfileId, roleId);
            oldOwnerRSM = CreateUser('TST_ORSM', salesRepProfileId, roleId);
            newOwner = CreateUser('TST_NUSR', salesRepProfileId, roleId);
            newOwnerRSM = CreateUser('TST_NRSM', salesRepProfileId, roleId);
            accNewOwnerUser2 = new User(alias = 'newUse', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='NewOwne', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__new_user@akamai.com', profileid=salesOpsProfileId, UserRoleId=roleId);
            insert (new User[] {oldOwner, oldOwnerRSM, newOwner, newOwnerRSM, accNewOwnerUser2});

            accNewOwnerUser = new User(alias = 'newUser', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='NewOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__new_usr@akamai.com',profileid=salesOpsProfileId, UserRoleId=roleId);
            accNewOwnerUser.DelegatedApproverId = accNewOwnerUser2.Id;
            insert accNewOwnerUser;

            oldOwnerRule = utilTestClass.CreateAccountReassignmentRule(oldOwner.Name, oldOwner.Id, roleName);
            oldOwnerRule.Associated_User_RSM__c = oldOwnerRSM.Id;

            oldTM = utilTestClass.createTerritoryMapping('ANZ - ANZ EAST' , 'Carrier North America_Carrier North America' , 'ANZ');
            newTM = utilTestClass.createTerritoryMapping('India - ECG INDIA' , 'Carrier ANZ_Carrier ANZ' , 'DM INDIA');
            insert (new Territory_Mapping__c[] {oldTM, newTM});

            oldOwnerRule.Territory_ID__c = oldTM.Id;

            newOwnerRule = utilTestClass.CreateAccountReassignmentRule(newOwner.Name, newOwner.Id, roleName);
            newOwnerRule.Associated_User_RSM__c = newOwnerRSM.Id;
            newOwnerRule.Territory_ID__c = newTM.Id;

            insert (new Account_Reassignment_Rule__c[] {oldOwnerRule, newOwnerRule});

            //Create Account
            Account acc1 = utilTestClass.CreateAccount('__Test Account');
            acc1.OwnerId = oldOwner.Id;
            acc1.Type = 'Lead';
            acc1.Website = 'www.test.com';

            System.runAs(oldOwner){insert acc1;}

            // Reassign
            Account_Reassignment__c accReassign1=new Account_Reassignment__c();
            accReassign1.Account__c = acc1.Id;
            accReassign1.Assign_To__c=newOwnerRule.Id;
            accReassign1.Reassign__c=false;
            accReassign1.Reason_Code__c ='Workload Rebalancing';
            accReassign1.Approver_1__c = accNewOwnerUser.Id;
            accReassign1.Approver_2__c = accNewOwnerUser.Id;
            accReassign1.Account_Owner_RSM__c = oldOwnerRSM.Id;
            accReassign1.Reassign_Status__c = 'Approval Pending';

            insert accReassign1;
        }
    }


    static testmethod void SingleARR_PositiveTest()
    {
        Account_Reassignment__c accReassign = [select id, Name, Account__c, Assign_To__c, Reassign__c, Reason_Code__c, 
        Approver_1__c, Approver_2__c, Account_Owner_RSM__c, Reassign_Status__c from Account_Reassignment__c 
        where Reason_Code__c = 'Workload Rebalancing' limit 1][0];

        User accNewOwnerUser,accNewOwnerUser2;
        List<String> userAlias = new List<String>{'newUser','newUse'};
        for(User u : [Select Id, Alias from User where Alias IN : userAlias]){
            if(u.Alias == 'newUser')
                accNewOwnerUser = u;
            else
                accNewOwnerUser2 = u;
        }

        AccountMovesPendingRequestController.item_to_approve_wrapper itWrap = new AccountMovesPendingRequestController.item_to_approve_wrapper(
            'requestName', null, 'submittedDate', 'accountName', null, 'accountStatus', 'targetCategory', 'accountOwner', null, 'assignToUser', null, 'originalActor', null, 'changeLevel', 'reasonCode', 'reasonForChange', null);

        System.runAs(dmlUser)
        {
            ManagedPkgErrorClass.isFromManagedPackage = false;

            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setComments('Submitting request for approval.');
            req.setObjectId(accReassign.id);

            Approval.ProcessResult result = Approval.process(req);
            List<Id> newWorkItemIds = result.getNewWorkitemIds();

            system.runAs(accNewOwnerUser)
            {
                PageReference pageRef = Page.AccountMovesPendingRequest;
                pageRef.getParameters().put('pageId','detailPage');

                Test.setCurrentPage(pageRef);

                ApexPages.StandardController sc = new ApexPages.StandardController(accReassign);
                AccountMovesPendingRequestController controller = new AccountMovesPendingRequestController(sc);
                AccountMovesPendingRequestController controller1 = new AccountMovesPendingRequestController();

                controller1.massApproveRejectIdSet.add(newWorkItemIds[0]);
                controller1.userID = accNewOwnerUser2.Id;
                PageReference pgI = controller1.massReassignRequests();

                controller.searchString = 'Rahul';
                PageReference pg1 = controller1.search();
                String nav = AccountMovesPendingRequestController.ApproveRejectnavigation();
                String navR = AccountMovesPendingRequestController.REASSIGNnavigation();

                PageReference pr1 = controller1.inputCheckForSelectRequest();
                PageReference pr2 = controller1.inputCheckForSelectUser();
                controller1.showPopup();
                controller1.closePopup();
                controller1.showReassignSectionMethod();
                controller1.redirectToNewPage();
                PageReference pr3 = controller1.approveSelected();

            }

        }
    }

    static testmethod void SingleARR_PositiveTest2()
    {
        System.runAs(dmlUser)
        {
            ManagedPkgErrorClass.isFromManagedPackage = false;

            Account_Reassignment__c accReassign1 = [select id, Name, Account__c, Assign_To__c, Reassign__c, Reason_Code__c, 
            Approver_1__c, Approver_2__c, Account_Owner_RSM__c, Reassign_Status__c from Account_Reassignment__c 
            where Reason_Code__c = 'Workload Rebalancing' limit 1][0];

            User oldOwnerRSM,oldOwner,accNewOwnerUser2;
            List<String> userAlias = new List<String>{'TST_ORSM','TST_OUSR','newUse'};
            for(User u : [Select Id, Alias from User where Alias IN : userAlias]){
                if(u.Alias == 'TST_ORSM')
                    oldOwnerRSM = u;
                else if(u.Alias == 'TST_OUSR')
                    oldOwner = u;
                else if(u.Alias == 'newUse')
                    accNewOwnerUser2 = u;
            }

            Approval.ProcessResult result1;
            System.runAs(oldOwnerRSM){
                Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();

                req1.setComments('Submitting request for approval.');
                req1.setObjectId(accReassign1.id);
                req1.setSubmitterId(oldOwner.Id);
                req1.setSkipEntryCriteria(true);

                result1 = Approval.process(req1);
                Set<Id> userIDset = new Set<Id>();
                userIDset.add(Userinfo.getUserId());
                Integer limitCount = 50;

                List<ProcessInstance> PIList =  [Select (Select Id,ActorId,Actor.Name,OriginalActorId,ProcessInstance.TargetObjectId,CreatedDate,ProcessInstance.TargetObject.Name,ProcessInstance.TargetObject.type From Workitems Where ActorId IN :userIDset ORDER BY CreatedDate DESC),(Select Id, IsDeleted, LastActorId, NodeStatus, ProcessInstanceId, ProcessNodeId, ProcessNodeName From Nodes Where NodeStatus='Pending' ORDER BY CreatedDate DESC) From ProcessInstance p WHERE TargetObject.Type = 'Account_Reassignment__c' AND Status= 'Pending' Order by CreatedDate Desc Limit :limitCount];
                
            }
            List<Id> newWorkItemIds = result1.getNewWorkitemIds();
            system.runAs(accNewOwnerUser2)
            {
                PageReference pageRef1 = Page.AccountMovesPendingRequest;
                pageRef1.getParameters().put('pageId','detailPage');

                Test.setCurrentPage(pageRef1);

                ApexPages.StandardController sc = new ApexPages.StandardController(accReassign1);
                AccountMovesPendingRequestController controller = new AccountMovesPendingRequestController(sc);
                AccountMovesPendingRequestController controller1 = new AccountMovesPendingRequestController();

                controller1.massApproveRejectIdSet.add(newWorkItemIds[0]);
                PageReference pg3 = controller1.rejectSelected() ;
            }
            system.runAs(oldOwnerRSM)
            {
                PageReference pageRef1 = Page.AccountMovesPendingRequest;
                pageRef1.getParameters().put('pageId','detailPage');

                Test.setCurrentPage(pageRef1);

                ApexPages.StandardController sc = new ApexPages.StandardController(accReassign1);
                AccountMovesPendingRequestController controller = new AccountMovesPendingRequestController(sc);
                AccountMovesPendingRequestController controller1 = new AccountMovesPendingRequestController();


                controller1.massApproveRejectIdSet.add(newWorkItemIds[0]);
                PageReference pg3 = controller1.rejectSelected() ;

            }
        }
    }

    /**
        CreateUser()
        - Return a new User with selected Alias, Profile and Role
    */
    private static User CreateUser(String pUsrAlias, String pProfile, String pRole)
    {
        Profile pr = [select Id from Profile where Name=:pProfile][0];
        UserRole role = [select Id, Name from UserRole where Name=:pRole][0];
        User newUser = new User(alias = pUsrAlias,
                                email=pUsrAlias+'@akamai.com',
                                emailencodingkey='UTF-8',
                                lastname=pUsrAlias,
                                languagelocalekey='en_US',
                                localesidkey='en_US',
                                timezonesidkey='America/Los_Angeles',
                                username=pUsrAlias+'@akamai.com.tclass',
                                profileid = pr.Id,
                                UserRoleId = role.Id );
        return newUser;
    }

    private static User CreateUser(String pUsrAlias, Id profileId, Id roleId)
    {
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
}