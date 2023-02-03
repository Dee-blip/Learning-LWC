@isTest()
    private class ApprovalHistoryDelegationTestClass {

        @testSetUp static void insertCustomSettingsAndCreateData()
        {
                Map<String, String> objectToCustomSettingResource = new Map<String, String>{
                        'Environment_Setup__c' => 'CS_Environment_Setup'
                };
                utilTestClass.insertCustomSettings(objectToCustomSettingResource);
                System.runAs(utilTestClass.getTestRunUser())
                {
                    Account acc =  (Account)new SobjectBuilder(Account.sObjectType)
                        .eagerPopulate()
                        .put(Account.Type, 'Lead')
                        .create()
                        .getRecord();

                    List<User> partnerUsers = SObjectFactory.createPartnerUsers(1);
                    Account partAccount = SobjectRepository.getPartnerAccount();
                    List<User> sUsers = SobjectFactory.createSalesPaeWithDelegatedApprover();
                    User opptySCMOwnerUser = sUsers[0];
                    User delegatedApprover = sUsers[1];

                    Test.startTest();
                    Channel_Mapping__c cm = (Channel_Mapping__c)new SobjectBuilder(Channel_Mapping__c.sObjectType)
                        .eagerPopulate()
                        .put(Channel_Mapping__c.Master_Channel_Mapping__c, true)
                        .put(Channel_Mapping__c.Active__c, true)
                        .put(Channel_Mapping__c.PAE_ID__c, opptySCMOwnerUser.Id)
                        .put(Channel_Mapping__c.MDF_Approver__c, opptySCMOwnerUser.Id)
                        .put(Channel_Mapping__c.Partner_Group__c, 'Unknown')
                        .put(Channel_Mapping__c.Partner_Name__c, partAccount.Id)
                        .create()
                        .getRecord();

                    System.runAs(partnerUsers[0])
                    {
                        Opportunity oppty = (Opportunity)new SobjectBuilder(Opportunity.sObjectType)
                            .eagerPopulate()
                            .put(Opportunity.AccountId, partAccount.Id)
                            .put(Opportunity.Deal_Type__c, 'Indirect')
                            .put(Opportunity.Partner_Involved__c, partAccount.Id)
                            .put(Opportunity.Channel_Manager__c, cm.Id)
                            .put(Opportunity.CloseDate, Date.today())
                            .create()
                            .getRecord();
                    }



                    Test.stopTest();

                }
        }

        static testmethod void submitOpptyForApproval_positive_shouldAddDelegatedApproverOfChannelManagerToOpptyTeam()
        {
            System.runAs(utilTestClass.getTestRunUser())
            {
                disableDealMakerCoreSettings();
                Channel_Mapping__c cm = SobjectRepository.getMasterChannelMapping();
                Opportunity opp = SobjectRepository.getOpportunity();
                Test.startTest();

          //submitOpptyForApproval_positive_shouldAddDelegatedApproverOfChannelManagerToOpptyTeam()
                System.assertEquals(opp.Partner_Involved__c, cm.Partner_Name__c);
                System.assertEquals(opp.FCM__c, cm.PAE_ID__c);

                //Submit the Opportunity for Approval
                PRM_opportunity.submitForApproval(opp.id);
                List<User> userList = [select DelegatedApproverId from user where id=:cm.PAE_ID__c];
                Id delegatedApproverId = userList[0].DelegatedApproverId;

                System.assert([select id from OpportunityTeamMember where UserId=:delegatedApproverId and OpportunityId=:opp.id].size() != 0);

            //changeDelegatedApproverOfUser_positive_shouldChangeCorrespondingOpptyTeamAlso()
                User newDelegatedApprover=(User) new SObjectBuilder(User.SObjectType)
                    .eagerPopulate()
                    .put(User.UserName, 'ffddf@akamai.com')
                    .put(User.CommunityNickname, 'fdkdsjd')
                    .put(User.ProfileId, GsmUtilClass.getPRMSettingValue('Channel_manager_profile_id'))
                    .put(User.UserRoleId, GSMSettings.getValue('WorldwideUserRoleId'))
                    .create()
                    .getRecord();
                User opptySCMOwnerUser = new User(id=cm.PAE_ID__c);
                opptySCMOwnerUser.DelegatedApproverId = newDelegatedApprover.id;
                update opptySCMOwnerUser;
                Test.stopTest();
                System.assert([select id from OpportunityTeamMember where UserId=:delegatedApproverid and OpportunityId=:opp.id].size() == 0);
                System.assert([select id from OpportunityTeamMember where UserId=:newDelegatedApprover.id and OpportunityId=:opp.id].size() != 0);

            }
        }

        static testMethod void leaveDelegatedApproverUntouchedIfAlreadyPartOfOpptyTeam() {
            System.runAs(utilTestClass.getTestRunUser())
            {
                Channel_Mapping__c cm = SobjectRepository.getMasterChannelMapping();
                Opportunity opp = SobjectRepository.getOpportunity();
                Test.startTest();

                //Submit the Opportunity for Approval
                PRM_opportunity.submitForApproval(opp.id);
                List<User> userList = [select DelegatedApproverId from user where id=:cm.PAE_ID__c];
                Id delegatedApproverId = userList[0].DelegatedApproverId;

                System.assert([select id from OpportunityTeamMember where UserId=:delegatedApproverId and OpportunityId=:opp.id].size() != 0);

                User newDelegatedApprover=(User) new SObjectBuilder(User.SObjectType)
                    .eagerPopulate()
                    .put(User.UserName, 'ffddf@akamai.com')
                    .put(User.CommunityNickname, 'fdkdsjd')
                    .put(User.ProfileId, GsmUtilClass.getPRMSettingValue('Channel_manager_profile_id'))
                    .put(User.UserRoleId, GSMSettings.getValue('WorldwideUserRoleId'))
                    .create()
                    .getRecord();
                OpportunityTeamMember otm=new OpportunityTeamMember();
                otm.TeamMemberRole='Channel - Secondary';
                otm.UserId=newDelegatedApprover.id;
                otm.OpportunityId=opp.id;
                OpportunityShare os = new OpportunityShare();
                os.OpportunityId = opp.id;
                os.UserOrGroupId = newDelegatedApprover.id;
                os.OpportunityAccessLevel = 'Edit';
                insert os;
                insert otm;

                User opptySCMOwnerUser = new User(id=cm.PAE_ID__c);
                opptySCMOwnerUser.DelegatedApproverId = newDelegatedApprover.id;
                update opptySCMOwnerUser;


                Test.stopTest();
                List<OpportunityTeamMember> opptyTeamMembers = [select id, TeamMemberRole from OpportunityTeamMember where UserId=:newDelegatedApprover.id and OpportunityId=:opp.id];
                System.assert(opptyTeamMembers.size() != 0);
                System.assert(opptyTeamMembers[0].TeamMemberRole == 'Channel - Delegated Approver');
            }
        }


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
    }