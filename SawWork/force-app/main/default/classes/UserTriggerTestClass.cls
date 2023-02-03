@isTest(seeAllData=false)
private class UserTriggerTestClass
{
    static User dmlUser = new User(id=UserInfo.getUserId());
    private static Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
    @testSetup static void insertCustomSettings() 
    {
        System.runAs(dmlUser) 
        {
            /* Start Of Custom Setting Insertion */
            Test.loadData(globalDescribe.get('Communities_Settings__c'), 'CS_Communities_Settings');
            Test.loadData(globalDescribe.get('PRM_Settings__c'), 'CS_PRM_Settings');
            /* End Of Custom Setting Insertion */
            
            Account acc = utilTestClass.CreateAccount('__Test Account');
            insert acc;
            acc.IsPartner = true;
            acc.IsPartnerCustom__c=true;
            acc.Validation_Override__c=true;
            update acc;
        }

    }


    static testMethod void verifyAdditionOfUsersToChannelUsersGroup() 
    {
        System.runAs(dmlUser) 
        {
            ManagedPkgErrorClass.isFromManagedPackage = false;
            Integer bulkCount = 10;
            List<User> listOfUsers = new List<User>();
            Set<Id> setOfUserIds = new Set<Id>();
            for(integer i=0;i<bulkCount;i++)
            {
                User userWithPartnerProfile = utilTestClass.CreateUserWithProfileId('fdaijoi'+i, 'Worldwide',GsmUtilClass.getGSMSettingValue('UserTriggerClass_ChannelUsersProfiles').substring(0, GsmUtilClass.getGSMSettingValue('UserTriggerClass_ChannelUsersProfiles').indexOf(',', 0)) );
                listOfUsers.add(userWithPartnerProfile);
            }
            insert listOfUsers;
            String channelUsersGroupId = GsmUtilClass.getGSMSettingValue('UserTriggerClass_ChannelUsersGroupId');
            List<GroupMember> listOfGroupMembers = [Select UserOrGroupId, GroupId from GroupMember where GroupId= :channelUsersGroupId];
            System.assert(listOfGroupMembers.size()>=10);
            Set<Id> setOfUserIdsAddedToTheGroup = new Set<Id>();
            for(GroupMember gMember : listOfGroupMembers)
            {
                setOfUserIdsAddedToTheGroup.add(gMember.UserOrGroupId);
            }
            for(User ithUser : listOfUsers)
            {
                System.assert(setOfUserIdsAddedToTheGroup.contains(ithUser.Id));
                ithUser.profileId = GsmUtilClass.getGSMSettingValue('ApprovalHistory_SysAdminId');
            }
            update listOfUsers;
            listOfGroupMembers = [Select UserOrGroupId, GroupId from GroupMember where GroupId= :channelUsersGroupId and UserOrGroupId in :setOfUserIds];
            System.assert(listOfGroupMembers.size()==0);
        }
    }

    static testMethod void testLicenseCountBulk()
    {
        System.runAs(dmlUser) {
            ManagedPkgErrorClass.isFromManagedPackage = false;
            Profile partnerProfile =
                [select id,name from Profile where UserType = 'PowerPartner' and Name='Partner Community Admin' limit 1];
            Profile liteProfile=
                [select id,name from Profile where UserType = 'PowerPartner' and Name='Partner Community Lite' limit 1];

            Account acc = [select Id from Account where Name = '__Test Account'];

            List<Contact> contacts = new List<Contact>();
            Integer numberOfLiteUsers = 51;
            Integer numberOfNonLiteUsers = 49;

            //create 4 contacts
            for(Integer i = 0; i < numberOfNonLiteUsers + numberOfLiteUsers; i++){
                Contact c = utilTestClass.CreateContact('John','Poe'+i);
                c.AccountId = acc.Id;
                c.MailingStreet='123 Main';
                c.MailingCity='Peoria';
                c.MailingState='IL';
                c.MailingPostalCode='33333';
                c.Phone='3213213211';
                c.MobilePhone='3213213211';
                c.Fax='3213123211';
                contacts.add(c);
            }
            insert contacts;
            List<User> userList=new List<User>();
            for(Integer i = 0; i < numberOfNonLiteUsers + numberOfLiteUsers; i++){
                User PartnerUser = new User(
                        Username='fndjkfd'+i+'@akamai.com',
                        Alias = 'test'+i,
                        Email=''+i+'@akamai.com',
                        ProfileId = partnerProfile.Id,
                        FirstName='John',
                        LastName='Poe'+i,
                        LanguageLocaleKey='en_US',
                        LocaleSidKey='en_US',
                        EmailEncodingKey='UTF-8',
                        TimeZoneSidKey='America/Los_Angeles',
                        ContactId = contacts[i].id
                        );
                if(i>=numberOfNonLiteUsers)
                {
                    PartnerUser.ProfileId = liteProfile.Id;
                }
                userList.add(PartnerUser);
            }

            Test.startTest();
            insert userList;
            Test.stopTest();

            acc = [select id, current_licenses__c, current_lite_licenses__c from account where id=:acc.Id];

            System.assertEquals(acc.current_licenses__c, numberOfNonLiteUsers);
            System.assertEquals(acc.current_lite_licenses__c, numberOfLiteUsers);

        }
    }

    static testMethod void testHandleUserAutomationAndOthermethods()
    {
        System.runAs(dmlUser) {
            ManagedPkgErrorClass.isFromManagedPackage = false;

            Profile partnerProfile =
                [select id,name from Profile where UserType = 'PowerPartner' and Name='Partner Community Admin' limit 1];
            Profile liteProfile=
                [select id,name from Profile where UserType = 'PowerPartner' and Name='Partner Community Lite' limit 1];

            Account acc = [select Id from Account where Name = '__Test Account'];

            List<Contact> contacts = new List<Contact>();

            //create 4 contacts
            for(Integer i = 0; i < 3; i++){
                Contact c = utilTestClass.CreateContact('John','Poe'+i);
                c.AccountId = acc.Id;
                c.MailingStreet='123 Main';
                c.MailingCity='Peoria';
                c.MailingState='IL';
                c.MailingPostalCode='33333';
                c.Phone='3213213211';
                c.MobilePhone='3213213211';
                c.Fax='3213123211';
                contacts.add(c);
            }
            insert contacts;

            User_Automation_Trigger_Condition__c uatc = new User_Automation_Trigger_Condition__c();
            uatc.Filter_Condition__c = 'Profile Only';
            uatc.Profile__c = 'Partner Community Admin';
            uatc.Active__c = true;
            insert uatc;

            User_Automation_Action__c uaa = new User_Automation_Action__c();
            uaa.Action_Type__c = 'Permission Set Assignment';
            uaa.Permission_Sets__c = 'Data.com users';
            uaa.Trigger_Condition__c = uatc.id;
            insert uaa;

            User_Automation_Action__c uaa2 = new User_Automation_Action__c();
            uaa2.Action_Type__c = 'Permission Set License Assignment';
            uaa2.Permission_Set_Licenses__c = 'Admin Analytics Apps';
            uaa2.Trigger_Condition__c = uatc.id;
            insert uaa2;

            List<User> userList=new List<User>();
            for(Integer i = 0; i < 3; i++){
                User PartnerUser = new User(
                        Username='fndjkfd'+i+'@akamai.com',
                        Alias = 'test'+i,
                        Email=''+i+'@akamai.com',
                        ProfileId = partnerProfile.Id,
                        FirstName='John',
                        LastName='Poe'+i,
                        LanguageLocaleKey='en_US',
                        LocaleSidKey='en_US',
                        EmailEncodingKey='UTF-8',
                        TimeZoneSidKey='America/Los_Angeles',
                        ContactId = contacts[i].id
                        );
                if(i>=3)
                {
                    PartnerUser.ProfileId = liteProfile.Id;
                }
                userList.add(PartnerUser);
            }

            
            insert userList;
            

            List<Id> userIds = new List<Id>();
            for (User us:userList) {
                userIds.add(us.id);
            }

            List<User> userListForTest = [Select id,Username,ProfileId,ContactId,Email,User_Profile_Name__c,User_Role_Name__c,AKAM_User_ID__c From User where id in:userIds];

            L2Q_UserTriggerClass.handleUserAutomationFieldUpdates(userListForTest);
            L2Q_UserTriggerClass.handleUserAutomationActions(userListForTest);

            //Test Send Email to users
            L2Q_UserTriggerClass.sendEmailToUsers(userListForTest);

            //UserTriggerClass.ButtonInvoke();
            L2Q_UserTriggerClass.ButtonInvoke2();
            L2Q_UserTriggerClass.setUseridSet(userIds);
            //UserTriggerClass.resetContactOwnerForInActiveUsers(userListForTest);

            User testUser1 = utilTestClass.CreateUser('userAR1','Worldwide','System Administrator');
            User testUser2 = utilTestClass.CreateUser('userAR2','Worldwide','System Administrator');

            List<User> userLists = new List<User>{testUser1,testUser2};
            insert userLists;
            Test.startTest();
            testUser2.ManagerId = testUser1.Id;
            update testUser2;

            Account testAccount = utilTestClass.CreateAccount('Test Account');
            testAccount.OwnerId = userLists[0].Id;
            insert testAccount;

            Opportunity testOppty = utilTestClass.CreateOpportunity('Test Oppty','1-Create');
            testOppty.AccountId = testAccount.Id;
            testOppty.CloseDate = Date.today();
            testOppty.Partner_Involved__c = testAccount.Id;
            testOppty.OwnerId = userLists[0].Id;
            insert testOppty;
            
            AccountTeamMember testATM = utilTestClass.CreateAccountTeamMember(testAccount.Id,userLists[0].Id);
            insert testATM;
            Test.stopTest();
            OpportunityTeamMember testOTM = new OpportunityTeamMember(UserId = userLists[0].Id,OpportunityId = testOppty.Id,TeamMemberRole = 'Sales - Secondary');
            insert testOTM;

            List<String> userIdSet = new List<String>();

            for(User eachUser : userLists)
            {
                userIdSet.add(eachUser.Id);
            }

            Merge_Contract_Header__c testMCH = utilTestClass.CreateContractHeader('1-4FS5J',testAccount.Id);
            insert testMCH;

            L2Q_UserTriggerClass.updateMCHShare(userIdSet);
            L2Q_UserTriggerClass.decideUpdateContactOwnerAction(userIds);
            
            L2Q_UserTriggerClass utc = new L2Q_UserTriggerClass();
            utc.resetContactOwnerForInActiveUsers(userListForTest);

            Channel_Mapping__c testCM = utilTestClass.CreateChannelMapping('Test CM',testAccount.Id,userLists[1].Id,userLists[0].Id);
            insert testCM;

            testOppty.Channel_Manager__c = testCM.Id;
            update testOppty;

            userLists[1].DelegatedApproverId = userLists[0].Id;
            update userLists;

            userLists = [select Id,AKAM_User_ID__c from User where Id in :userLists];
            List<String> userIDList = new List<String>();
            for(User eachUser : userLists)
            {
                userIDList.add(eachUser.AKAM_User_ID__c);
            }

            List<Contact> contactList = [select Id, AccountId, Owner.AKAM_User_ID__c from Contact Order By CreatedDate Desc LIMIT 2];
            
            for(Contact eachContact : contactList)
            {
                userIDList.add(eachContact.Owner.AKAM_User_ID__c);
                //eachContact.AccountId = testAccount.Id;
            }
            //update contactList;

            L2Q_UserTriggerClass.setInactiveContactOwner(userIDList);
            
        }
    }
}