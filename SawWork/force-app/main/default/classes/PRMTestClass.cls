/**
  PRMTestClass
    @author : Vinayendra T N <vintara@akamai.com>
    @Description : This is the test class for the PRM.
    The test cases covered are:
    (Positive) Add FCM to a Deal on create
    (Negative) Add FCM to a Deal on create
    (Bulk) Add FCM to a Deal on create
    (Positive) Add User to Partner Owner field and sales team. Add Partner account to Pnertner invloved on create
    (Bulk) Add User to Partner Owner field and sales team. Add Partner account to Pnertner invloved on create
    (Positive) Change Opportunity owner to associated account owner when Account changes on update
    (Negative) Change Opportunity owner to associated account owner when Account changes on update
    (Bulk) Change Opportunity owner to associated account owner when Account changes on update
 */
@isTest
private class PRMTestClass
{
    static User partner;
    static User dmlUser = new User(id=UserInfo.getUserId());
    //SFDC-2572
    static Id channelMgrProfId = GsmUtilClass.getPRMSettingValue('Channel_manager_profile_id');

    @testSetup static void insertCustomSettings()
        {
            System.runAs(dmlUser) {
                Map<String, String> objectToCustomSettingResource = new Map<String, String>{
                'PRM_Settings__c'           => 'CS_PRM_Settings',
                'GSM_Custom_Settings__c'    => 'CS_GSM_Custom_Settings',
                'Communities_Settings__c'   => 'CS_Communities_Settings',
                'Opportunity_Trigger_Class_Settings__c' => 'CS_Opportunity_Trigger_Class_Settings',
                'Features_Toggle__c' => 'CS_Features_Toggle',
                'Environment_Setup__c' => 'CS_Environment_Setup'
                };
                utilTestClass.insertCustomSettings(objectToCustomSettingResource);
                Environment_Setup__c environmentSetup = Environment_Setup__c.getInstance();
                //SDFC 7619 commented because not used anywhere
                // String sysAdminProfileId = '00eA0000000VTG1';
                // if (environmentSetup.Environment_Type__c.equalsIgnorecase('DR'))
                //     sysAdminProfileId = '00eC0000001fJvrIAE'; 
            }
        }


    static testMethod void AddFCMtoDealNegative()
        {
            System.runAs(dmlUser) {
                ManagedPkgErrorClass.isFromManagedPackage = false;
                //DisableAllPartners();
                //Account acc = CreateAccount('__ Test Account');
                Account acc = utilTestClass.CreateAccount('__Test Account');
                insert acc;
                //Create a partner User for that account
                List<User> PartnerUsers=utilTestClass.createPartnerUsers(1,acc.id);
                partner=PartnerUsers[0];
                //Add the User to the chanell mapping table
                // Create 'SalesChannelMgr' User
                /*Profile prSCM = [Select Id, Name from profile where id=:PRM_Settings__c.getInstance('Channel manager profile id').Value__c][0];
				  UserRole roleDVA = [select id, name from UserRole where name='Worldwide'][0];
				  User opptySCMOwnerUser = new User(alias = 'scmUsr1', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OpptyOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__mss_owner@akamai.com',profileid = prSCM.Id, UserRoleId = roleDVA.Id );*/

                //1st FCM
                //SFDC-2572
                User opptySCMOwnerUser = utilTestClass.CreateUserWithProfileId('scmUsr1', 'Worldwide', channelMgrProfId);
                insert opptySCMOwnerUser;
                //2nd FCM
                //User opptySCMOwnerUser2 = new User(alias = 'scmUsr2', email='salesop2@akamai.com',emailencodingkey='UTF-8', lastname='OpptyOwner2', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__mss_owner2@akamai.com',profileid = prSCM.Id, UserRoleId = roleDVA.Id );
                //SFDC-2572
                User opptySCMOwnerUser2 = utilTestClass.CreateUserWithProfileId('scmUsr2', 'Worldwide', channelMgrProfId);
                insert opptySCMOwnerUser2;
                //Channel Mapping for 1st FCM
                //Channel_Mapping__c cm= new Channel_Mapping__c(Name = 'Test Channel Mapping', Partner_Name__c = acc.id, PAE_ID__c = opptySCMOwnerUser.id);
                Channel_Mapping__c cm = utilTestClass.CreateChannelMapping('Test Channel Mapping', acc.Id, opptySCMOwnerUser.Id);
                insert cm;
                //Channel Mapping for 2nd FCM
                //Channel_Mapping__c cm2= new Channel_Mapping__c(Name = 'Test Channel Mapping2', Partner_Name__c = acc.id, PAE_ID__c = opptySCMOwnerUser2.id);
                Channel_Mapping__c cm2 = utilTestClass.CreateChannelMapping('Test Channel Mapping2', acc.Id, opptySCMOwnerUser.Id);
                insert cm2;
                Opportunity opp= utilTestClass.CreateOpportunity('__Test Opportunity__','1-Create');
                opp.End_Customer_Country__c = 'USA';
                opp.End_Customer_State__c = 'NY';
                opp.End_Customer_City__c = 'Buffalo';
                opp.End_Customer_Street_Address__c = 'Line1 \r\n Line2';
                opp.CloseDate= Date.today();
                opp.Partner_Involved__c = acc.Id;

                system.runAs(Partner)
                    {
                        Test.startTest();
                        insert opp;
                        Test.stopTest();
                    }
                opp=[select FCM__c from Opportunity where id=:opp.id];
                System.assertEquals(opp.FCM__c,null);
            }
        }

    static testMethod void AddFCMtoDealBulk()
        {
            System.runAs(dmlUser) {
                ManagedPkgErrorClass.isFromManagedPackage = false;
                //DisableAllPartners();
                //Account acc = CreateAccount('__ Test Account');
                Account acc = utilTestClass.CreateAccount('__Test Account');
                insert acc;
                Integer count;
                //Create a partner User for that account
                List<User> PartnerUsers=utilTestClass.createPartnerUsers(1,acc.id);
                partner=PartnerUsers[0];
                //Add the User to the chanell mapping table
                // Create 'SalesChannelMgr' User
                /*Profile prSCM = [Select Id, Name from profile where id=:PRM_Settings__c.getInstance('Channel manager profile id').Value__c][0];
				  UserRole roleDVA = [select id, name from UserRole where name='Worldwide'][0];
				  User opptySCMOwnerUser = new User(alias = 'scmUsr1', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OpptyOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__mss_owner@akamai.com',profileid = prSCM.Id, UserRoleId = roleDVA.Id );*/
                //SFDC-2572
                User opptySCMOwnerUser = utilTestClass.CreateUserWithProfileId('scmUsr1', 'Worldwide', channelMgrProfId);
                insert opptySCMOwnerUser;

                //Channel_Mapping__c cm= new Channel_Mapping__c(Name = 'Test Channel Mapping', Partner_Name__c = acc.id, PAE_ID__c = opptySCMOwnerUser.id);
                Channel_Mapping__c cm = utilTestClass.CreateChannelMapping('Test Channel Mapping', acc.Id, opptySCMOwnerUser.Id);
                insert cm;
                Opportunity[] BulkOpptys = new Opportunity[15];
                for(count=0;count<15;count++)
                    {
                        /*BulkOpptys[count] = new Opportunity();
						  BulkOpptys[count].Name = 'TestOpportunity'+ count;
						  BulkOpptys[count].StageName = '1-Create';*/
                        BulkOpptys[count] = utilTestClass.CreateOpportunity('TestOpportunity'+count,'1-Create');
                        BulkOpptys[count].End_Customer_Country__c = 'USA';
                        BulkOpptys[count].End_Customer_State__c = 'NY';
                        BulkOpptys[count].End_Customer_City__c = 'Buffalo';
                        BulkOpptys[count].End_Customer_Street_Address__c = 'Line1 \r\n Line2';
                        BulkOpptys[count].CloseDate= Date.today();
                        BulkOpptys[count].Partner_Involved__c = acc.Id;
                    }
                system.runAs(Partner)
                    {
                        Test.startTest();
                        insert BulkOpptys;
                        Test.stopTest();
                    }
                count=0;
                for(Opportunity opp:[select FCM__c from Opportunity where id=:BulkOpptys[count].id])
                    {
                        System.assertEquals(opp.FCM__c,opptySCMOwnerUser.id);
                        if(count<15)
                            count++;
                        else
                            break;
                    }
            }
        }

    static testMethod void DealCreationPostive()
        {
            System.runAs(dmlUser) {
                ManagedPkgErrorClass.isFromManagedPackage = false;
                //DisableAllPartners();
                //Account acc = CreateAccount('__ Test Account');
                Account acc = utilTestClass.CreateAccount('__Test Account');
                insert acc;
                //Create a partner User for that account
                List<User> PartnerUsers=utilTestClass.createPartnerUsers(1,acc.id);
                partner=PartnerUsers[0];
                //Add the User to the chanell mapping table
                // Create 'SalesChannelMgr' User
                /*Profile prSCM = [Select Id, Name from profile where id=:PRM_Settings__c.getInstance('Channel manager profile id').Value__c][0];
				  UserRole roleDVA = [select id, name from UserRole where name='Worldwide'][0];
				  User opptySCMOwnerUser = new User(alias = 'scmUsr1', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OpptyOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__mss_owner@akamai.com',profileid = prSCM.Id, UserRoleId = roleDVA.Id );*/
                //SFDC-2572
                User opptySCMOwnerUser = utilTestClass.CreateUserWithProfileId('scmUsr1', 'Worldwide', channelMgrProfId);
                insert opptySCMOwnerUser;

                //Channel_Mapping__c cm= new Channel_Mapping__c(Name = 'Test Channel Mapping', Partner_Name__c = acc.id, PAE_ID__c = opptySCMOwnerUser.id);
                Channel_Mapping__c cm = utilTestClass.CreateChannelMapping('Test Channel Mapping', acc.Id, opptySCMOwnerUser.Id);
                insert cm;
                Opportunity opp= utilTestClass.CreateOpportunity('__Test Opportunity__','1-Create');
                opp.End_Customer_Country__c = 'USA';
                opp.End_Customer_State__c = 'NY';
                opp.End_Customer_City__c = 'Buffalo';
                opp.End_Customer_Street_Address__c = 'Line1 \r\n Line2';
                opp.CloseDate= Date.today();
                opp.Partner_Involved__c = acc.Id;

                system.runAs(Partner)
                    {
                        Test.startTest();
                        insert opp;
                        Test.stopTest();
                        opp.Registration_Status__c='Pending';
                        update opp;
                    }
                User PartnerUser=[select ContactId from User where id=:Partner.id];
                Contact con=[select Id from Contact where id=:PartnerUser.ContactId];
                opp=[select Partner_Involved__c,Partner_Owner__c from Opportunity where id=:opp.id];
                System.assertEquals(opp.Partner_Owner__c,con.id);
                System.assertEquals(opp.Partner_Involved__c,acc.id);
                OpportunityTeamMember otm=[select TeamMemberRole from OpportunityTeamMember where OpportunityId=:opp.id and UserId=:partner.id ];
                System.assertEquals(otm.TeamMemberRole,'Partner');
            }
        }


    static testMethod void DealCreationBulk()
        {
            System.runAs(dmlUser) {
                ManagedPkgErrorClass.isFromManagedPackage = false;
                //DisableAllPartners();
                //Account acc = CreateAccount('__ Test Account');
                Account acc = utilTestClass.CreateAccount('__Test Account');
                insert acc;
                Integer count;
                //Create a partner User for that account
                List<User> PartnerUsers=utilTestClass.createPartnerUsers(1,acc.id);
                partner=PartnerUsers[0];
                //Add the User to the chanell mapping table
                // Create 'SalesChannelMgr' User
                /*Profile prSCM = [Select Id, Name from profile where id=:PRM_Settings__c.getInstance('Channel manager profile id').Value__c][0];
				  UserRole roleDVA = [select id, name from UserRole where name='Worldwide'][0];
				  User opptySCMOwnerUser = new User(alias = 'scmUsr1', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OpptyOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__mss_owner@akamai.com',profileid = prSCM.Id, UserRoleId = roleDVA.Id );*/
                //SFDC-2572
                User opptySCMOwnerUser = utilTestClass.CreateUserWithProfileId('scmUsr1', 'Worldwide', channelMgrProfId);
                insert opptySCMOwnerUser;

                //Channel_Mapping__c cm= new Channel_Mapping__c(Name = 'Test Channel Mapping', Partner_Name__c = acc.id, PAE_ID__c = opptySCMOwnerUser.id);
                Channel_Mapping__c cm = utilTestClass.CreateChannelMapping('Test Channel Mapping', acc.Id, opptySCMOwnerUser.Id);
                insert cm;
                Opportunity[] BulkOpptys = new Opportunity[15];
                for(count=0;count<15;count++)
                    {
                        /*BulkOpptys[count] = new Opportunity();
						  BulkOpptys[count].Name = 'TestOpportunity'+ count;
						  BulkOpptys[count].StageName = '1-Create';*/
                        BulkOpptys[count] = utilTestClass.CreateOpportunity('TestOpportunity'+count,'1-Create');
                        BulkOpptys[count].End_Customer_Country__c = 'USA';
                        BulkOpptys[count].End_Customer_State__c = 'NY';
                        BulkOpptys[count].End_Customer_City__c = 'Buffalo';
                        BulkOpptys[count].End_Customer_Street_Address__c = 'Line1 \r\n Line2';
                        BulkOpptys[count].CloseDate= Date.today();
                        BulkOpptys[count].Partner_Involved__c = acc.Id;
                    }
                system.runAs(Partner)
                    {
                        Test.startTest();
                        insert BulkOpptys;
                        Test.stopTest();
                    }
                count=0;
                User PartnerUser=[select ContactId from User where id=:Partner.id];
                Contact con=[select Id from Contact where id=:PartnerUser.ContactId];
                for(Opportunity opp:[select Partner_Involved__c,Partner_Owner__c from Opportunity where id=:BulkOpptys[count].id])
                    {
                        System.assertEquals(opp.Partner_Owner__c,con.id);
                        System.assertEquals(opp.Partner_Involved__c,acc.id);
                        if(count<15)
                            count++;
                        else
                            break;
                    }
                for(OpportunityTeamMember otm:[select TeamMemberRole from OpportunityTeamMember where OpportunityId=:BulkOpptys[count].id and UserId=:partner.id ])
                    {
                        System.assertEquals(otm.TeamMemberRole,'Partner');
                        if(count<15)
                            count++;
                        else
                            break;
                    }
            }
        }

    static testMethod void ChangeOpportunityOwnerPositive()
        {
            System.runAs(dmlUser) {
                Test.startTest();
                ManagedPkgErrorClass.isFromManagedPackage = false;
                //DisableAllPartners();
                //Account accPartner = CreateAccount('__ Test Account Parnter');
                Account accPartner = utilTestClass.CreateAccount('__Test Account Partner');
                insert accPartner;
                List<User> PartnerUsers=utilTestClass.createPartnerUsers(1,accPartner.id);
                partner=PartnerUsers[0];

                /*Profile pr = [select id from profile where name='Sales Operations'][0];
				  UserRole role = [select id, Name from UserRole where name='Sales Operations'][0];
				  User tmUser1 = new User(alias = 'tmUser1', email='stdusr1@akamai.com',emailencodingkey='UTF-8', lastname='TmUser1', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__team_member1@akamai.com',profileid = pr.Id, UserRoleId = role.Id );*/

                User tmUser1 = utilTestClass.CreateUser('tmUser1', 'Sales Operations', 'Sales Operations');
                insert tmUser1;
                Account_Reassignment_Rule__c rule1 = utilTestClass.CreateAccountReassignmentRule('TestRule1', tmUser1.Id, 'Sales Operations');
                insert rule1;

                //Account acc = CreateAccount('__ Test Account1');
                Account acc = utilTestClass.CreateAccount('__Test Accntoi1');
                System.runAs(tmUser1)
                    {
                        insert acc;
                    }

                Test.stopTest();

                Opportunity opp= utilTestClass.CreateOpportunity('__Test Opportunity__','1-Create');
                opp.End_Customer_Country__c = 'USA';
                opp.End_Customer_State__c = 'NY';
                opp.End_Customer_City__c = 'Buffalo';
                opp.End_Customer_Street_Address__c = 'Line1 \r\n Line2';
                opp.CloseDate= Date.today();
                opp.Partner_Involved__c = accPartner.Id;

                System.runAs(Partner)
                    {
                        insert opp;
                    }
                opp=[select OwnerId,AccountId from Opportunity where id=:opp.id];
                System.assertEquals(opp.OwnerId,Partner.Id);
                //change the account so that ever owner changes
                opp.AccountId=acc.id;
                opp.Validation_Override__c = true;
                List<recordType> recordTypeIDs = [Select id from RecordType where name = 'Akamai Opportunity' limit 1];
                ID recordtypeID= recordTypeIDs[0].ID; 
                opp.RecordTypeId =recordtypeID ; // SFDC-7619
                //opp.RecordTypeId = '012A0000000CvQLIA0'; // SFDC-5907
                update opp;
                opp=[select OwnerId from Opportunity where id=:opp.id];
                System.assertEquals(opp.OwnerId,tmUser1.Id);
                OpportunityTriggerClass.checkOverSharingForPartners();
                OpportunityTriggerClass.checkUnderSharingForPartners();
            }
        }


    static testMethod void ChangeOpportunityOwnerNegative()
        {
            System.runAs(dmlUser) {
                ManagedPkgErrorClass.isFromManagedPackage = false;
                //DisableAllPartners();
                //Account accPartner = CreateAccount('__ Test Account Parnter');
                Account accPartner = utilTestClass.CreateAccount('__Test Account Partner');
                insert accPartner;
                List<User> PartnerUsers=utilTestClass.createPartnerUsers(1,accPartner.id);
                partner=PartnerUsers[0];

                User usr=[select id from User where Alias='ONA'];
                //Account acc = CreateAccount('__ Test Account1');
                Account acc = utilTestClass.CreateAccount('__Test Account1');
                acc.OwnerId=usr.id;
                insert acc;

                Opportunity opp= utilTestClass.CreateOpportunity('__Test Opportunity__','1-Create');
                opp.End_Customer_Country__c = 'USA';
                opp.End_Customer_State__c = 'NY';
                opp.End_Customer_City__c = 'Buffalo';
                opp.End_Customer_Street_Address__c = 'Line1 \r\n Line2';
                opp.CloseDate= Date.today();
                opp.Partner_Involved__c = accPartner.Id;

                System.runAs(Partner)
                    {
                        insert opp;
                    }
                opp=[select OwnerId,AccountId from Opportunity where id=:opp.id];
                System.assertEquals(opp.OwnerId,Partner.Id);
                //change the account so that ever owner changes
                opp.AccountId=acc.id;
                try{
                    update opp;
                }
                catch(exception e)
                {

                }
            }
        }

    static testMethod void ChangeOpportunityOwnerBulk()
        {
            System.runAs(dmlUser) {
                Test.startTest();
                ManagedPkgErrorClass.isFromManagedPackage = false;
                //DisableAllPartners();
                //Account accPartner = CreateAccount('__ Test Account Parnter');
                Account accPartner = utilTestClass.CreateAccount('__Test Account Partner');
                insert accPartner;
                List<User> PartnerUsers=utilTestClass.createPartnerUsers(1,accPartner.id);
                partner=PartnerUsers[0];

                /*Profile pr = [select id from profile where name='Sales Operations'][0];
				  UserRole role = [select id, Name from UserRole where name='Sales Operations'][0];
				  User tmUser1 = new User(alias = 'tmUser1', email='stdusr1@akamai.com',emailencodingkey='UTF-8', lastname='TmUser1', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__team_member1@akamai.com',profileid = pr.Id, UserRoleId = role.Id );*/

                User tmUser1 = utilTestClass.CreateUser('tmUser1', 'Sales Operations', 'Sales Operations');
                insert tmUser1;
                Account_Reassignment_Rule__c rule1 = utilTestClass.CreateAccountReassignmentRule('TestRule1', tmUser1.Id, 'Sales Operations');
                insert rule1;

                //Account acc = CreateAccount('__ Test Account1');
                Account acc = utilTestClass.CreateAccount('__Tet Acoujgnt1');
                acc.Partner_Type__c='SRA Partner';
                System.runAs(tmUser1)
                    {
                        insert acc;
                    }
                Opportunity[] BulkOpptys = new Opportunity[15];
                Integer count;
                for(count=0;count<15;count++)
                    {
                        /*BulkOpptys[count] = new Opportunity();
						  BulkOpptys[count].Name = 'TestOpportunity'+ count;
						  BulkOpptys[count].StageName = '1-Create';*/
                        Bulkopptys[count] = utilTestClass.CreateOpportunity('TestOpportunity'+count,'1-Create');
                        BulkOpptys[count].End_Customer_Country__c = 'USA';
                        BulkOpptys[count].End_Customer_State__c = 'NY';
                        BulkOpptys[count].End_Customer_City__c = 'Buffalo';
                        BulkOpptys[count].End_Customer_Street_Address__c = 'Line1 \r\n Line2';
                        BulkOpptys[count].CloseDate= Date.today();
                        BulkOpptys[count].Partner_Involved__c = acc.Id;
                    }
                Test.stopTest();

                insert BulkOpptys;
                for(count=0;count<15;count++)
                    {
                        BulkOpptys[count].accountId=acc.id;
                    }
                update BulkOpptys;
                count=0;
                for(Opportunity opp:[select OwnerId from Opportunity where id=:BulkOpptys[count].id])
                    {
                        System.assertEquals(opp.OwnerId,tmUser1.Id);
                        if(count<15)
                            count++;
                        else
                            break;
                    }
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

                Account acc = utilTestClass.CreateAccount('__Test Account');
                insert acc;
                acc.IsPartner = true;
                acc.IsPartnerCustom__c=true;
                acc.Validation_Override__c=true;
                update acc;

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



    static testMethod void AccountTriggerValidation()
        {
            System.runAs(dmlUser) {
                ManagedPkgErrorClass.isFromManagedPackage = false;
                //Account acc = CreateAccount('__ Test Account');
                Account acc = utilTestClass.CreateAccount('__Test Account');
                acc.No_Portal_Access__c=true;
                acc.Type='Indirect Customer - Active';
                insert acc;

                acc.IsPartner = true;
                string expstring;
                PRM_opportunity.AddErrorToAccountFristRunFlag=true;
                try{
                    update acc;
                }
                catch(Exception e)
                {
                    expstring=e.getMessage();
                }
                system.assert(expstring.contains('Cannot Provide Portal Access to '+acc.Name));
            }
        }

    static testMethod void editAccContact()
        {
            System.runAs(dmlUser) {
                ManagedPkgErrorClass.isFromManagedPackage = false;
                //Account acc = CreateAccount('__ Test Account');
                Account acc = utilTestClass.CreateAccount('__Test Account');
                insert acc;
                //Create a partner User for that account
                List<User> PartnerUsers=utilTestClass.createPartnerUsers(1,acc.id);
                partner=PartnerUsers[0];
                //Make the partner as Admin.
                //SFDC-2572
                partner.ProfileId = GsmUtilClass.getPRMSettingValue('Partner_Admin_Id');
                update partner;

                List<string> usrIdAccId = new List<string>();
                usrIdAccId.add(partner.Id + '#' + acc.Id);

                Test.startTest();
                L2Q_UserTriggerClass.updateAccountShareSetting(usrIdAccId);
                Test.stopTest();

                AccountShare accShare = new AccountShare();
                for(AccountShare accSh: [SELECT UserOrGroupId, AccountAccessLevel, CaseAccessLevel, OpportunityAccessLevel FROM AccountShare WHERE AccountId=: acc.Id and UserOrGroupId=:partner.id])
                    accShare=accSh;

                System.assertEquals(accShare.AccountAccessLevel,'Edit');
            }
        }

    static testMethod void makePartnerAndDisableAccountTest()
        {
            System.runAs(dmlUser) {
                ManagedPkgErrorClass.isFromManagedPackage = false;
                //Account acc = CreateAccount('__ Test Account');
                Account acc = utilTestClass.CreateAccount('__Test Account');
                acc.No_Portal_Access__c=true;
                acc.Type='Indirect Customer - Active';
                insert acc;

                PRM_opportunity.AddErrorToAccountFristRunFlag=true;
                string retmsg=PRM_opportunity.makePartnerAccount(acc.id);
                system.debug('test'+retmsg);
                system.debug('test2'+[select isPartner from Account where id=:acc.id][0].isPartner);
                system.assert(retmsg.contains('Cannot Provide Portal Access to '), 'found - ' + retmsg);

                acc.IsPartner=true;
                acc.Validation_Override__c=true;
                acc.Partner_Type__c='Unknown';
                acc.Rebate_TC_Status__c='Accepted';
                acc.Rebate_TC_Accepted_At__c=DateTime.now();
                acc.Type='Indirect Customer - Active';
                update acc;
                Contact c = utilTestClass.CreateContact('John','Doe00');
                c.AccountId= acc.Id;
                c.MailingStreet='123 Main';
                c.MailingCity='Peoria';
                c.MailingState='IL';
                c.MailingPostalCode='33333';
                c.MobilePhone='3213213211';
                c.Fax='3213123211';
                c.Email = 'testintgint@akamai.com';
                c.Active_Partner__c=True;
                insert c;
                Id akamaiPartnerUserId = [select id from profile where name='Akamai Partner User'][0].Id;
                User tempUser = new User(
                        Username='fdjklfds@akamai.com',
                        Alias = 'test00',
                        Email='johndfdf@akamai.com',
                        FirstName='John',
                        LastName='Doe00',
                        ProfileId = akamaiPartnerUserId,
                        LanguageLocaleKey='en_US',
                        LocaleSidKey='en_US',
                        EmailEncodingKey='UTF-8',
                        TimeZoneSidKey='America/Los_Angeles',
                        ContactId = c.Id,
                        IsActive=true,
                        Can_Accept_POA__c=true);

                insert tempUser;




                acc=[select id,IsPartner,IsPartnerCustom__c from Account where id=:acc.id][0];
                system.assertEquals(acc.IsPartner,true);
                system.assertEquals(acc.IsPartnerCustom__c,true);
                test.starttest();
                retmsg=PRM_opportunity.DisablePartnerAccount(acc.id);
                //PRM_opportunity.DeactivateParterAccount(acc.id);

                test.stopTest();

                system.assertEquals(retmsg,'');

                acc=[select id,IsPartnerCustom__c, IsPartner from Account where id=:acc.id][0];
                system.assertEquals(acc.IsPartnerCustom__c,false);

                User puser=[select IsActive from User where id=:tempUser.id][0];
                system.assertEquals(puser.IsActive,false);
            }
        }

    static testmethod void testSRAPartnerAdminfunctionality()
        {
            System.runAs(dmlUser) {
                ManagedPkgErrorClass.isFromManagedPackage = false;
                Account acc = utilTestClass.CreateAccount('__Test Account');
                acc.Partner_Type__c='SRA Partner';
                acc.Type='Indirect Customer - Active';
                insert acc;
                string retmsg=PRM_opportunity.makePartnerAccount(acc.id);
                acc=[select id,Maximum_Licenses__c from Account where id=:acc.id][0];
                system.assertEquals(acc.Maximum_Licenses__c,2);
            }
        }

    static testmethod void testRebateTermsConditionsController()
        {
            System.runAs(dmlUser) {
                ManagedPkgErrorClass.isFromManagedPackage = false;
                Account acc = utilTestClass.CreateAccount('__Test Account');
                acc.Type='Indirect Customer - Active';
                insert acc;
                Account childAcc = utilTestClass.CreateAccount('__Test Account Child');
                childAcc.parentId = acc.Id;
                childAcc.Type='Indirect Customer - Active';
                insert childAcc;

                string retmsg=PRM_opportunity.makePartnerAccount(acc.id);

                //Create a partner User for that account
                List<User> PartnerUsers=utilTestClass.createPartnerUsers(1,acc.id);
                partner=PartnerUsers[0];

                User opptySCMOwnerUser = utilTestClass.CreateUserWithProfileId('scmUsr1', 'Worldwide', channelMgrProfId);
                insert opptySCMOwnerUser;

                Channel_Mapping__c cm = utilTestClass.CreateChannelMapping('Test Channel Mapping', acc.Id, opptySCMOwnerUser.Id);
                insert cm;
                Opportunity opp= utilTestClass.CreateOpportunity('__Test Opportunity__','1-Create');
                opp.End_Customer_Country__c = 'USA';
                opp.End_Customer_State__c = 'NY';
                opp.End_Customer_City__c = 'Buffalo';
                opp.End_Customer_Street_Address__c = 'Line1 \r\n Line2';
                opp.CloseDate= Date.today();
                opp.Partner_Involved__c = acc.Id;

                Test.startTest();
                insert opp;
                PageReference pageref=new PageReference('/apex/RebateTermsConditions');
                pageRef.getParameters().put('id',opp.id);
                pageRef.getParameters().put('accountId',acc.id);
                Test.setCurrentPageReference(pageRef);
                RebateTermsConditionsController rebateCon=new RebateTermsConditionsController();
                rebateCon.accept();
                Test.stopTest();
                acc=[select Id,Rebate_TC_Status__c from Account where id =: acc.id];
                System.assertEquals(acc.Rebate_TC_Status__c,'Accepted');
                rebateCon.reject();
            }
        }

    static testmethod void testRebatePayoutFunctionalityPositive()
        {
            System.runAs(dmlUser) {
                ManagedPkgErrorClass.isFromManagedPackage = false;
                List<Account> acclist = new List<Account>();
                List<Account> acclist1 = new List<Account>();

                Account acc1 = utilTestClass.CreateAccount('__Test Account1');
                acc1.Type='Indirect Customer - Active';
                acc1.Invoice_Currency__c = 'USD';
                acclist.add(acc1);
                //insert acc1;

                Account acc2 = utilTestClass.CreateAccount('__Test Account2');
                acc2.Type='Indirect Customer - Active';
                acc2.Invoice_Currency__c = 'USD';
                //acc2.parentid = acc1.Id;
                //insert acc2;
                acclist.add(acc2);

                Account acc3 = utilTestClass.CreateAccount('__Test Account3');
                acc3.Type='Indirect Customer - Active';
                acc3.Invoice_Currency__c = 'USD';
                //acc3.parentid = acc2.Id;
                //insert acc3;
                acclist.add(acc3);

                Account acc4 = utilTestClass.CreateAccount('__Test Account4');
                acc4.Type='Indirect Customer - Active';
                acc4.Invoice_Currency__c = 'USD';
                //acc4.parentid = acc3.Id;
                //insert acc4;
                acclist.add(acc4);

                Account acc5 = utilTestClass.CreateAccount('__Test Account5');
                acc5.Type='Indirect Customer - Active';
                acc5.Invoice_Currency__c = 'USD';
                //acc.parentid = acc4.Id;
                //insert acc;
                acclist.add(acc5);

                Account acc = utilTestClass.CreateAccount('__Test Account');
                acc.Type='Indirect Customer - Active';
                acc.Invoice_Currency__c = 'USD';
                acclist.add(acc);

                insert acclist;

                acc2.parentid = acc1.Id;
                acclist1.add(acc2);
                acc3.parentid = acc2.Id;
                acclist1.add(acc3);
                acc4.parentid = acc3.Id;
                acclist1.add(acc4);
                acc5.parentid = acc4.Id;
                acclist1.add(acc5);
                acc.parentid = acc5.id;
                acclist1.add(acc);

                update acclist1;

                string retmsg=PRM_opportunity.makePartnerAccount(acc.id);

                Contact c = utilTestClass.CreateContact('John','Doe');
                c.AccountId=acc.id;
                c.MailingStreet='123 Main';
                c.MailingCity='Peoria';
                c.MailingState='IL';
                c.MailingPostalCode='33333';
                c.MobilePhone='3213213211';
                c.Fax='3213123211';
                c.Active_Partner__c=True;

                insert c;

                Contact c1 = utilTestClass.CreateContact('James','Bond');
                c1.AccountId=acc1.id;
                c1.MailingStreet='123 Main';
                c1.MailingCity='Peoria';
                c1.MailingState='IL';
                c1.MailingPostalCode='33333';
                c1.MobilePhone='3213213211';
                c1.Fax='3213123211';
                c1.Active_Partner__c=True;

                insert c1;

                List<Profile> pr=[select Id from Profile where Name='Akamai Partner Administrator'];
                List<User> userList=new List<User>();
                User partnerUser=new User(
                        Username='tpuAdmin@akamai.com',
                        Alias = 'tpuAdmin',
                        Email='tpuAdmin@akamai.com',
                        FirstName='John',
                        LastName='Doe',
                        ProfileId =pr[0].Id ,
                        LanguageLocaleKey='en_US',
                        LocaleSidKey='en_US',
                        EmailEncodingKey='UTF-8',
                        TimeZoneSidKey='America/Los_Angeles',
                        ContactId = c.id,
                        Can_Accept_POA__c=true
                );

                User partnerUser1=new User(
                        Username='tp_Admin@akamai.com',
                        Alias = 'tp_Admin',
                        Email='tp_Admin@akamai.com',
                        FirstName='James',
                        LastName='Bond',
                        ProfileId =pr[0].Id ,
                        LanguageLocaleKey='en_US',
                        LocaleSidKey='en_US',
                        EmailEncodingKey='UTF-8',
                        TimeZoneSidKey='America/Los_Angeles',
                        ContactId = c1.id,
                        Can_Accept_POA__c=true
                );

                userList.add(partnerUser);
                userList.add(partnerUser1);

                User psUser=utilTestClass.CreateUser('Test_PS','Worldwide','Partner Support');
                userList.add(psUser);
                User cmgUser=utilTestClass.CreateUser('Test_CMG','CMG','CMG');
                userList.add(cmgUser);
                insert userList;
                c.Partner_User__c=partnerUser.Id;
                update c;
                c1.Partner_User__c = partnerUser1.Id;
                update c1;

                Rebate_Payout__c rp=new Rebate_Payout__c();
                rp.Name='Test Rebate Payout';
                rp.Associated_Partner__c=acc.Id;
                rp.Description__c='Test rebate for partners';
                rp.Start_Date__c=Date.today();
                rp.End_Date__C=Date.today().addDays(4);
                rp.CurrencyIsoCode = acc.Invoice_Currency__c;
                rp.Rebate_Payout_Amount__c=125.00;

                Rebate_Payout__c rp1=new Rebate_Payout__c();
                rp1.Name='Test Rebate Payout1';
                rp1.Associated_Partner__c=acc1.Id;
                rp1.Description__c='Test rebate for partners';
                rp1.Start_Date__c=Date.today();
                rp1.End_Date__C=Date.today().addDays(4);
                rp1.CurrencyIsoCode = acc1.Invoice_Currency__c;
                rp1.Rebate_Payout_Amount__c=125.00;

                String msg='';
                Test.startTest();
                system.runas(psUser)
                    {
                        insert rp;
                        msg=PRM_Opportunity.updateRebatePayoutStatusAndCreateTask(rp.Id, rp.Associated_Partner__c);

                        insert rp1;
                        msg=PRM_Opportunity.updateRebatePayoutStatusAndCreateTask(rp1.Id, rp1.Associated_Partner__c);

                    }

                System.assertEquals(msg,'Successfully sent to CMG');
                Pagereference pageRef=new Pagereference('/apex/payRebate');
                pageRef.getParameters().put('id',rp.Id);

                System.runAs(cmgUser)
                    {
                        test.setCurrentPageReference(pageRef);
                        ApexPages.StandardController std=new ApexPages.StandardController(rp);
                        PayRebateController prcon=new PayRebateController(std);
                        prcon.rebatePayout.Contract_Id__c='1-23THK1';
                        prcon.saveRebate();
                        prcon.goBacktoRebate();
                        rp.Contract_Reviewed_Date__c=Date.today();
                        update rp;
                    }
                Test.stopTest();
                rp=[select contract_reviewed_by__c,Status__c,Credit_invoice_date__c,Paid_Processed_Date__c from Rebate_Payout__c where id=:rp.id];
                System.assertEquals(rp.Status__c,'Paid');
                System.assertEquals(rp.contract_reviewed_by__c,cmgUser.Id);
            }
        }

    public static testmethod void partnerOversharingTest()
        {
            System.runAs(dmlUser) {
                ManagedPkgErrorClass.isFromManagedPackage = false;
                //DisableAllPartners();

                Account accParent=utilTestClass.createAccount('Test Partner Parent Account');
                accParent.Partner_Type__c='Unknown';
                //accParent.IsPartner = true;
                insert accParent;
                List<Account> accList=new List<Account>();
                Account acc = utilTestClass.CreateAccount('__Test Partner Account');
                acc.Partner_Type__c='Unknown';
                //acc.IsPartner = true;
                acc.parentId=accParent.Id;
                accList.add(acc);

                Account accNew=utilTestClass.CreateAccount('__Test Partner Account New');
                accNew.Partner_Type__c='Unknown';
                //accNew.IsPartner = true;
                accList.add(accNew);
                insert accList;
                accList.add(accParent);
                for(Account acc1 : accList)
                    acc1.isPartner=true;

                update accList;

                Test.startTest(); // SFDC -5962
                List<User> PartnerUsers=utilTestClass.createPartnerUsers(1,accList[0].id);
                partner=PartnerUsers[0];

                List<User> partnerUserNew=utilTestClass.createPartnerUsers(1,accNew.id);
                User partnerNew=partnerUserNew[0];
                //SFDC-2572

                //User opptySCMOwnerUser = utilTestClass.CreateUserWithProfileId('scmUsr1', 'Worldwide', channelMgrProfId);
                //insert opptySCMOwnerUser;


                //Channel_Mapping__c cm= new Channel_Mapping__c(Name = 'Test Channel Mapping', Partner_Name__c = acc.id, PAE_ID__c = opptySCMOwnerUser.id);

                //Channel_Mapping__c cm = utilTestClass.CreateChannelMapping('Test Channel Mapping', accNew.Id, opptySCMOwnerUser.Id);
                //insert cm;



                Opportunity opp= utilTestClass.CreateOpportunity('__Test Opportunity__','1-Create');
                opp.End_Customer_Country__c = 'USA';
                opp.End_Customer_State__c = 'NY';
                opp.End_Customer_City__c = 'Buffalo';
                opp.End_Customer_Street_Address__c = 'Line1 \r\n Line2';
                opp.CloseDate= Date.today();
                opp.Partner_Involved__c = acc.Id;


                system.runAs(Partner)
                    {

                        insert opp;

                    }
                PRM_opportunity.submitForApproval(opp.id);

                List<UserRole> userRoleIds=[SELECT Id,portalAccountId FROM UserRole where Name like '%Executive' and portalAccountId!=null and portalAccountId=:accNew.id];
                List<Group> userGroupIds=[select Id,relatedId from Group where relatedId =:userRoleIds[0].id and Type = 'RoleAndSubordinates'];

                OpportunityShare opptyShare=new OpportunityShare(OpportunityId=opp.Id,UserOrGroupId=userGroupIds[0].Id,OpportunityAccessLevel='Edit');
                insert opptyShare;
                Test.stopTest();

                String result=OpportunityTriggerClass.checkOverSharingForPartners();

                //System.assert(result.contains('Opportunity Shares To be deleted'));
                OpportunityTriggerClass.checkUnderSharingForPartners();

                

            }
        }


    // tests related to fund request and claims have been moved to MDFTests
    static testMethod void Test123(){
        System.runAs(dmlUser) {
            ManagedPkgErrorClass.isFromManagedPackage = false;
            Account acc = utilTestClass.CreateAccount('1__Test Account');
            insert acc;
            Integer count;
            List<User> PartnerUsers=utilTestClass.createPartnerUsers(1,acc.id);
            partner=PartnerUsers[0];

            Opportunity opp= utilTestClass.CreateOpportunity('__Test Opportunity__','1-Create');
            opp.End_Customer_Country__c = 'USA';
            opp.End_Customer_State__c = 'NY';
            opp.End_Customer_City__c = 'Buffalo';
            opp.End_Customer_Street_Address__c = 'Line1 \r\n Line2';
            opp.CloseDate= Date.today();
            opp.Partner_Involved__c = acc.Id;
            opp.Validation_Override__c  = true; //SDFC 7619
            //opp.Partner_Owner__c = partner.id;

            system.runAs(Partner)
                {
                    Test.startTest();
                    insert opp;
                    Test.stopTest();
                }

            List<Opportunity> Opportunity = new List<Opportunity>();
            
            
            Opportunity.add(opp);

            OpportunityTeamMember otm = PRM_opportunity.opptyAddSalesTeamMember(opp.id, partner.id, 'Partner'); 
            otm.Validation_Override__c  = true; // SDFC 7619
            insert otm;
            
           // PRM_opportunity.AddToPartnerOwnerToSalesTeam(Opportunity);

        }

    }

    

    static testMethod void methodForCodeCoverage(){
        System.runAs(dmlUser) {
            ManagedPkgErrorClass.isFromManagedPackage = false;
            Account acc = utilTestClass.CreateAccount('1__Test Account');
            insert acc;
            acc.Validation_Override__c=true;
            acc.IsPartner = true;
            acc.IsPartnercustom__C = true;
            // SFDC-9222
            acc.Partner_Type__c = 'ADS Partner';
            acc.Partner_status__c = 'Partner';
            update acc;
            Opportunity opp= utilTestClass.CreateOpportunity('__Test Opportunity__','1-Create');
            opp.End_Customer_Country__c = 'USA';
            opp.End_Customer_State__c = 'NY';
            opp.End_Customer_City__c = 'Buffalo';
            opp.End_Customer_Street_Address__c = 'Line1 \r\n Line2';
            opp.CloseDate= Date.today();
            opp.Partner_Involved__c = acc.Id;
            opp.Deal_Type__c = 'Indirect';
            opp.Deal_Reg_Account_Status__c = 'New Account';
            opp.contract_id__c = 'test';
            Test.startTest();
            insert opp;
            Merge_Contract_Header__c mch = UtilTestClass.CreateContractHeader('MCH-1011234',acc.id);
            mch.Opportunity_Name__c = opp.id;
            mch.Effective_End_Date__c = Date.today();
            mch.Effective_Start_Date__c = Date.today();
            insert mch;
            
            List<Opportunity> opList = new List<Opportunity>();
            opList.add(opp);
            OpportunityPRMTriggerClass.initilizeCurrencyRate();
            OpportunityPRMTriggerClass.setFieldsWhenDealIsRejected(opList);
            OpportunityPRMTriggerClass.UpdateChannelManager(opList);
            OpportunityPRMTriggerClass.onDealApproval(opList);
            OpportunityPRMTriggerClass.calcDRRebateAtClosedWon(opList);
            Test.stopTest();
        }
    }
}