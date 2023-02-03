//SFDC-2135
global class L2Q_UserTriggerClass
{
    /**Begin Rajesh Kumar JIRA# > SFDC-5088  */
    public static Boolean handleContentfirstrun = true;
    /**End Rajesh Kumar JIRA# > SFDC-5088  */
    // Set of InActive Account Owners; used in setInactiveContactOwner() method.
    public static Set<Id> inActiveAccOwnerIdSet = new Set<Id>();
    //public static Features_Toggle__c customSettings = Features_Toggle__c.getInstance('UpdateContactOwnerForInActiveUsers'); //SFDC-2304
    //public static UserTriggerClassSettings__c userTriggerCustomSettings = UserTriggerClassSettings__c.getInstance('v1.0'); //SFDC-2304
    //public static GSM_Custom_Settings__c gsmCustomSettings=GSM_Custom_Settings__c.getInstance('UserTriggerClass#TemplateId'); //SFDC-2304
    private static Set<String> updatedAccountIdUserIdSet=new Set<String>();
    public static Boolean updateAccountShareSettingFirstRunFlag = true;
    public static Boolean handleUserAutomationActionsFirstRunFlag = true;
    public static Boolean updateAccountLicensesFirstRunFlagFuture = true;
    public static Boolean handleUserAutomationFieldUpdatesFirstRunFlag = true;
    public static Map<String, List<User_Automation_Action__c>> actionsMap= new Map<String, List<User_Automation_Action__c>>();
    public static Boolean updateAccountLicensesFirstRunFlag = true;
    public static Integer limitNo =  Integer.valueof(GsmUtilClass.getGSMSettingValue('Update_Contact_Limit'));
    // UserTriggerClass#BatchNotifyEmail
    /**
      Set_AKAM_User_ID_Before(User[] users)
      - On before insert and before update, just copy the AKAM_User_Id value from the AutoID.
     */
    public static void Set_AKAM_User_ID_Before(User[] users)
    {
        for (User u : users)
        {
            if (u.AKAM_User_ID__c == null)
                u.AKAM_User_ID__c = u.UserAutoID__c;
        }
    }
    /**
      Set_AKAM_User_ID_After(User[] users)
      - Since during insert, the autoId is not generated -> fire the trigger again through a DML-SOQL.
     */
    public static void Set_AKAM_User_ID_After(User[] users)
    {
        List<User> toUpdateUsers = new List<User>();
        User tempUser;
        User[] usersNew = [select Id,AKAM_User_ID__c,UserAutoID__c from User usr where usr.Id IN :users];
        for (User u : usersNew)
        {
            tempUser = new User(id=u.Id);
            if (u.AKAM_User_ID__c == null)
            {
                //u.AKAM_User_ID__c = u.UserAutoID__c;
                tempUser.AKAM_User_ID__c = u.UserAutoID__c;
                toUpdateUsers.add(tempUser);
            }
        }
        //update usersNew;
        if (toUpdateUsers.size()>0)
            update toUpdateUsers;
    }


    /**
      setUserIdSet(Id[] accOwnerIds)
      - Initializes Set of InActiveAccOwners associated to Contacts with InActive Owners.
     */
    public static void setUserIdSet(Id[] accOwnerIds)
    {
        Boolean requiredFlag = false;
        for(Id usrIds : accOwnerIds)
        {
            if(!inActiveAccOwnerIdSet.contains(usrIds))
                requiredFlag = true;
        }
        if(!requiredFlag)
            return;
        //Set<Id> accOwnerIdSet = new Set<Id>();
        for(User usr : [SELECT Id FROM User WHERE Id IN :accOwnerIds AND isActive=false])
        {
            inActiveAccOwnerIdSet.add(usr.Id);
        }
    }
    /**
      resetContactOwnerForInActiveUsers(User[] users)
      - This method runs thru a list of Users and checks for AKAM Ids, if AKAM Ids exist it calls
      setInactiveContactOwner() method which runs @future and fixes Account Contacts with InActive Users.
     */
    public void resetContactOwnerForInActiveUsers(User[] users)
    {
        List<String> userAkamIdList = new List<String>();
        for (User usr : users)
        {
            if (usr.AKAM_User_ID__c!=null)
                userAkamIdList.add(usr.AKAM_User_ID__c);
        }
        if (userAkamIdList.size()>0)
        {
            //UserTriggerClass.setInactiveContactOwner(userAkamIdList);
            L2Q_UserTriggerClass.decideUpdateContactOwnerAction(userAkamIdList);
        }
    }

    @future
    public static void updateMCHShare(String[] pActivatedUserIds)
    {
        Map<Id,List<Id>> accUsrIdMap = new Map<Id,List<Id>>();
        Map<Id,List<Id>> oppUsrIdMap = new Map<Id,List<Id>>();

        Map<Id,Id> accOwnerIdMap = new Map<Id,Id>();
        Map<Id,Id> oppOwnerIdMap = new Map<Id,Id>();

        Set<Id> accIdSet = new Set<Id>();
        set<Id> oppIdSet = new Set<Id>();

        // pull all the ATMs
        for (AccountTeamMember atm : [Select Id, UserID, AccountId from AccountTeamMember where UserId IN : pActivatedUserIds])
        {
            accIdSet.add(atm.AccountId);
            if(accUsrIdMap.containsKey(atm.AccountId))
                accUsrIdMap.get(atm.AccountId).add(atm.UserId);
            else
                accUsrIdMap.put(atm.AccountId, new List<Id>{atm.UserId});
        }

        // pull all the OTMs
        for (OpportunityTeamMember otm : [Select Id, UserID, OpportunityId from OpportunityTeamMember where UserId IN : pActivatedUserIds])
        {
            oppIdSet.add(otm.OpportunityId);
            if(oppUsrIdMap.containsKey(otm.OpportunityId))
                oppUsrIdMap.get(otm.OpportunityId).add(otm.UserId);
            else
                oppUsrIdMap.put(otm.OpportunityId, new List<Id>{otm.UserId});
        }

        // pull all the Accounts owned by reActivated Users
        for(Account acc : [Select Id, OwnerId from Account where OwnerId IN : pActivatedUserIds])
        {
            accIdSet.add(acc.Id);
            accOwnerIdMap.put(acc.Id, acc.OwnerId);

            if(accUsrIdMap.containsKey(acc.Id))
                accUsrIdMap.get(acc.Id).add(acc.OwnerId);
            else
                accUsrIdMap.put(acc.Id, new List<Id>{acc.OwnerId});
        }

        // pull all the Opptys owned by reActivated Users
        for(Opportunity opp : [Select Id, OwnerId from Opportunity where OwnerId IN : pActivatedUserIds])
        {
            oppIdSet.add(opp.Id);
            oppOwnerIdMap.put(opp.Id, opp.OwnerId);

            if(oppUsrIdMap.containsKey(opp.Id))
                oppUsrIdMap.get(opp.Id).add(opp.OwnerId);
            else
                oppUsrIdMap.put(opp.Id, new List<Id>{opp.OwnerId});
        }

        List<Merge_Contract_Header__Share> createMCHShareList = new List<Merge_Contract_Header__Share>();
        List<Contract_Share__c> createCShareList = new List<Contract_Share__c>();
        // pull all the contracts
        for (Merge_Contract_Header__c mch : [Select Id, OwnerId, Account_Name__c, Opportunity_Name__c from Merge_Contract_Header__c where Account_Name__c IN :accIdSet
                OR (Opportunity_Name__c!=null AND Opportunity_Name__c IN :oppIdSet)])
        {
            if (accUsrIdMap.containsKey(mch.Account_Name__c))
            {
                for (Id usrId : accUsrIdMap.get(mch.Account_Name__c))
                {
                    if (mch.OwnerId!=usrId)
                    {
                        createMCHShareList.add(MergeContractHeaderClass.getMCHShareRecord(usrId, mch.Id));
                        if (accOwnerIdMap.containsKey(mch.Account_Name__c) && usrId==accOwnerIdMap.get(mch.Account_Name__c))
                            createCShareList.add(MergeContractHeaderClass.getOwnerCShareRecord(mch.Account_Name__c, accOwnerIdMap.remove(mch.Account_Name__c))); // add as Owner && remove acc/Owner row from accOwnerMap so that there are no duplicate rows.
                        // @todo: else add ATM Contract Share record.
                    }
                    if (createMCHShareList.size()==9900)
                    {
                        System.debug('createMCHShareList=' +createMCHShareList.size());
                        insert createMCHShareList;
                        createMCHShareList.clear();

                    }
                    if (createCShareList.size()==9900)
                    {
                        System.debug('createCShareList=' +createCShareList.size());
                        upsert createCShareList ATM_OTM_SF_Id__c;
                        createCShareList.clear();
                    }
                }
            }
            if(mch.Opportunity_Name__c!=null && oppUsrIdMap.containsKey(mch.Opportunity_Name__c))
            {
                for (Id usrId : oppUsrIdMap.get(mch.Opportunity_Name__c))
                {
                    if (mch.OwnerId!=usrId)
                    {
                        createMCHShareList.add(MergeContractHeaderClass.getMCHShareRecord(usrId, mch.Id));
                        if (oppOwnerIdMap.containsKey(mch.Opportunity_Name__c) && usrId==oppOwnerIdMap.get(mch.Opportunity_Name__c))
                            createCShareList.add(MergeContractHeaderClass.getOwnerCShareRecord(mch.Opportunity_Name__c, oppOwnerIdMap.remove(mch.Opportunity_Name__c))); // add as Owner && remove acc/Owner row from accOwnerMap so that there are no duplicate rows.
                        // @todo: else add ATM Contract Share record.
                    }
                    if (createMCHShareList.size()==9900)
                    {
                        System.debug('createMCHShareList=' +createMCHShareList.size());
                        insert createMCHShareList;
                        createMCHShareList.clear();
                    }
                    if (createCShareList.size()==9900)
                    {
                        System.debug('createCShareList=' +createCShareList.size());
                        upsert createCShareList ATM_OTM_SF_Id__c;
                        createCShareList.clear();
                    }
                }
            }
        }
        if (createMCHShareList.size()>0)
            insert createMCHShareList;
        if (createCShareList.size()>0)
            upsert createCShareList ATM_OTM_SF_Id__c;
    }



    public static void decideUpdateContactOwnerAction(String[] pInactiveUserIds)
    {
        List<Contact> updateContactOwnerList = new List<Contact>();

        Contact[] inactiveUserContacts = [SELECT Owner.AKAM_User_ID__c, Id, OwnerId, Account.OwnerId, Account.Owner.isActive
            FROM Contact WHERE Owner.AKAM_User_ID__c IN : pInactiveUserIds AND AccountId!=null];
        if (inactiveUserContacts.size()>0 && inactiveUserContacts.size()<limitNo)
        {
            L2Q_UserTriggerClass.setInactiveContactOwner(pInactiveUserIds);
        }
        else if (inactiveUserContacts.size()>0 && inactiveUserContacts.size()>=limitNo)
        {
            // do nothing.
            //System.debug('insde inactiveusercontacts size > 9900');

            String strInactiveUserId = '';

            for (String usrId : pInactiveUserIds)
            {
                if (strInactiveUserId=='')
                    strInactiveUserId = '\'' + usrId + '\'';
                else
                    strInactiveUserId += ',\'' + usrId + '\'';
            }
            System.debug('strInactiveUserId=' + strInactiveUserId);

            // form the query
            String query = 'SELECT Owner.AKAM_User_ID__c, Id, OwnerId, Account.OwnerId, Account.Owner.isActive FROM Contact WHERE AccountId!=null AND Owner.AKAM_User_ID__c IN (' + strInactiveUserId +')';
                    //String query = 'SELECT Owner.AKAM_User_ID__c, Id, OwnerId, Account.OwnerId, Account.Owner.isActive FROM Contact WHERE AccountId!=null AND Owner.isActive = false';
                    System.debug('query='+ query);

                    BatchableUpdateContactOwner changeContactOwner = new BatchableUpdateContactOwner(query);
                    ID batchprocessid = Database.executeBatch(changeContactOwner);

        }
    }

    /**
      refreshDelegatedApproversInOpptys(Id userId, Id delegatedApproverId, Id oldDelegatedApproverId)
      - This takes the user and fetches all opptys that the user is part of.
      - Checks if old delegated approver is there as well, if yes, removes the entry
      - Adds new delegated approver to the oppty teams
     */

    //SFDC-1332
    @future
    public static void refreshDelegatedApproversInOpptys(Map<String,String> userIdDelegatedApproverIdMap, Map<String,String> userIdOldDelegatedApproveridMap) {

        List<Opportunity> opptys = new List<Opportunity>();
        List<OpportunityTeamMember> opptyTeamMembersToBeAdded = new List<OpportunityTeamMember>();
        Set<Id> opptyTeamMembersNotToBeDeleted = new Set<Id>();
        List<OpportunityShare> opptySharesToBeAdded = new List<OpportunityShare>();
        List<OpportunityTeamMember> opptyTeamMembersToBeDeletedAllUserIds = new List<OpportunityTeamMember>();

        Map<String,List<Opportunity>> userToOpportunitiesMap = new Map<String,List<Opportunity>>();


        String delegatedApproverRole = GSMUtilClass.getGSMSettingValue('OpptyTriggerClass_DelegatedApprover');

        if (!userIdDelegatedApproverIdMap.isEmpty()){

            List<Opportunity> allOpptys = [Select id, Channel_Manager__r.PAE_ID__c, OwnerId FROM Opportunity WHERE Channel_Manager__r.PAE_ID__c IN :userIdDelegatedApproverIdMap.keySet() AND (not Stagename like 'Closed%')];

            for (Opportunity op:allOpptys) {
                if (userToOpportunitiesMap.containsKey(op.Channel_Manager__r.PAE_ID__c)){
                    List<Opportunity> oppListForUser = userToOpportunitiesMap.get(op.Channel_Manager__r.PAE_ID__c);
                    oppListForUser.add(op);
                    userToOpportunitiesMap.put(op.Channel_Manager__r.PAE_ID__c, oppListForUser);
                } else {
                    List<Opportunity> oppListForUser = new List<Opportunity>();
                    oppListForUser.add(op);
                    userToOpportunitiesMap.put(op.Channel_Manager__r.PAE_ID__c, oppListForUser);
                }
            }

            Map<String,List<OpportunityTeamMember>> userIdToOppTeamMemberMap = new Map<String,List<OpportunityTeamMember>>();

            if (!userToOpportunitiesMap.isEmpty()) {

                Set<Id> oldDelegatedApproverIds = new Set<Id>();

                for(Id approverId : userIdOldDelegatedApproveridMap.keyset())
                {
                    oldDelegatedApproverIds.add(userIdOldDelegatedApproveridMap.get(approverId));
                }

                opptyTeamMembersToBeDeletedAllUserIds = [Select id,UserId from OpportunityTeamMember
                                                                         where TeamMemberRole = :delegatedApproverRole
                                                                         and OpportunityId IN :allOpptys and UserId IN :oldDelegatedApproverIds];

                Set<Id> newDelegatedApproverIds = new Set<Id>();

                for(Id approverId : userIdDelegatedApproverIdMap.keyset())
                {
                    newDelegatedApproverIds.add(userIdDelegatedApproverIdMap.get(approverId));
                }

                List<OpportunityTeamMember> existingDelegatedApproverTeamMembers = [Select Id,OpportunityId,UserId from OpportunityTeamMember where UserId IN :newDelegatedApproverIds and OpportunityId IN :opptys];

                Map<Id,Set<Id>> approverIdToOpptyId = new Map<Id,Set<Id>>();

                for (OpportunityTeamMember otm:existingDelegatedApproverTeamMembers) {

                    if (approverIdToOpptyId.containsKey(otm.UserId)) {
                        Set<Id> opptyIds = approverIdToOpptyId.get(otm.UserId);
                        opptyIds.add(otm.OpportunityId);
                        approverIdToOpptyId.put(otm.UserId, opptyIds);
                    } else {
                        Set<Id> opptyIds = new Set<Id>();
                        opptyIds.add(otm.OpportunityId);
                        approverIdToOpptyId.put(otm.UserId, opptyIds);
                    }
                }

                opptyTeamMembersToBeAdded = new List<OpportunityTeamMember>();
                opptyTeamMembersNotToBeDeleted = new Set<Id>();
                opptySharesToBeAdded = new List<OpportunityShare>();

                for (String userId:userIdDelegatedApproverIdMap.keySet()) {

                    //opptys = [Select id, Channel_Manager__r.PAE_ID__c, OwnerId FROM Opportunity WHERE Channel_Manager__r.PAE_ID__c = :userId];
                    opptys = userToOpportunitiesMap.get(userId);



                    //opptyTeamMembersToBeDeleted = [Select id from OpportunityTeamMember where UserId =:userIdOldDelegatedApproveridMap.get(userId)
                                                                               //and TeamMemberRole = :delegatedApproverRole and OpportunityId IN :opptys];


                    /*for(OpportunityTeamMember otm : [Select id, OpportunityId from OpportunityTeamMember
                                                     where UserId =:userIdDelegatedApproverIdMap.get(userId)
                                                     and OpportunityId IN :opptys]) {
                        opptyTeamMembersNotToBeDeleted.add(otm.OpportunityId);
                    }*/

                    if(approverIdToOpptyId.containsKey(userIdDelegatedApproverIdMap.get(userId)))
                    {
                        opptyTeamMembersNotToBeDeleted = approverIdToOpptyId.get(userIdDelegatedApproverIdMap.get(userId));
                    }

                    for (Opportunity o : opptys) {
                        if(!opptyTeamMembersNotToBeDeleted.contains(o.id) && userIdDelegatedApproverIdMap.get(userId) != null && o.OwnerId != userIdDelegatedApproverIdMap.get(userId)) {
                            opptyTeamMembersToBeAdded.add(OpportunityTriggerClass.opptyAddSalesTeamMember(o.id, userIdDelegatedApproverIdMap.get(userId), delegatedApproverRole));
                            opptySharesToBeAdded.add(OpportunityTriggerClass.opptyAddOpportunityShareSettings(o.id, userIdDelegatedApproverIdMap.get(userId), 'Edit'));
                        }
                    }
                }
            }
        }

        if(opptyTeamMembersToBeDeletedAllUserIds != null && !opptyTeamMembersToBeDeletedAllUserIds.isEmpty())
                    delete opptyTeamMembersToBeDeletedAllUserIds;

        if(opptyTeamMembersToBeAdded != null && opptyTeamMembersToBeAdded.size() > 0)
            insert opptyTeamMembersToBeAdded;
        if(opptySharesToBeAdded != null && opptySharesToBeAdded.size() > 0)
            insert opptySharesToBeAdded;
    }
    //End of SFDC-1332

    /**
      setInactiveContactOwner(String[] akamIds)
      - This method runs thru a list of AKAM User Ids and fetches all Contacts with those AKAM User Ids
      - It runs asynchronously, if its not set this way (@future) this update will result in 'MIXED DML EXCEPTION'
      - It updates Contact.OwnerId to Contact.Account.OwnerId
      - Incase of any errors during the update; email is triggered to alert the admin.
     */
    @future
    public static void setInactiveContactOwner(String[] akamIds)
    {
        List<Contact> updateContactOwnerList = new List<Contact>();
        try
        {
            Contact[] inactiveUserContacts = [SELECT Owner.AKAM_User_ID__c, Id, OwnerId, Account.OwnerId
                FROM Contact WHERE Owner.AKAM_User_ID__c IN : akamIds AND AccountId!=null];
            if (inactiveUserContacts.size()>0)
            {
                List<Id> accOwners = new List<Id>();
                for (Contact cntct : inactiveUserContacts)
                    accOwners.add(cntct.Account.OwnerId);

                setUserIdSet(accOwners);
                for (Contact cntct : inactiveUserContacts)
                {
                    if (cntct.OwnerId != cntct.Account.OwnerId && (!inActiveAccOwnerIdSet.contains(cntct.Account.OwnerId)))
                        //&& (activeUserIds.contains(accOwnerId)
                    {
                        cntct.OwnerId = cntct.Account.OwnerId;
                        cntct.Validation_Override__c = true;
                    }
                    else // if Account.Owner is Inactive put ONA as Contact.Owner
                    {
                        //cntct.OwnerId = L2Q_UserTriggerClass.userTriggerCustomSettings.ONAUserId__c; //SFDC-2304
                        cntct.OwnerId = GsmUtilClass.getGSMSettingValue('ONA_User_Id'); //SFDC-2304
                        cntct.Validation_Override__c = true;
                    }
                    updateContactOwnerList.add(cntct);
                    if (updateContactOwnerList.size()==limitNo)
                    {
                        System.debug('updateContactOwnerList=' +updateContactOwnerList.size());
                        update updateContactOwnerList;
                        updateContactOwnerList.clear();
                    }
                }
                //update inactiveUserContacts;
                update updateContactOwnerList;

                /*try
                  {
                  update inactiveUserContacts;
                  }
                  catch (Exception e)
                  {
                //throw CustomException('Contacts Update Failed ' + e);
                  }
                 */
            }
        }
        catch (Exception e)
        {
            //String[] toAddresses = new String[] {userTriggerCustomSettings.Email__c}; //SFDC-2304
            String[] toAddresses = new String[] {GsmUtilClass.getGSMSettingValue('UsrTrgrCls_Email')}; //SFDC-2304
            String subject='Exception Occurred while updating Inactive Contact Owner records';
            String message = e.getMessage();

            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(toAddresses);
            mail.setSubject(subject);
            mail.setBccSender(false);
            mail.setUseSignature(false);
            mail.setPlainTextBody(message);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    }

        /**
      sendEmailToUsers()
      - sends mail to user which gets activated in system
     */
    public  static void sendEmailToUsers(List<User> userList)
    {
        //String[] toAddresses = new String[] {customSettings.EmailId__c};
        for(User user: userList)
        {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            //mail.setToAddresses(toAddresses);
            mail.setTargetObjectId(user.Id);
            //mail.setTemplateId(gsmCustomSettings.value__c); //SFDC-2304
            mail.setTemplateId(GsmUtilClass.getGSMSettingValue('UserTriggerClass_TemplateId')); //SFDC-2304
            //mail.setSubject(subject);
            //mail.setBccSender(false);
            //mail.setUseSignature(false);
            //mail.setPlainTextBody(message);
            mail.setSaveAsActivity(false);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    }
    /**
      updateActivatedOnDate()
      - update Activated date for user when user gets activated
     */
    public static void updateUserActivationInactivationDate(List<User> userList,Boolean isActive)
    {
        Datetime currentDateTime = DateTime.now();
        String LongDate = currentDateTime.format();
        for(User u: userList)
        {
            if(isActive)
            {
                u.Activated_On__c=DateTime.parse(LongDate);
            }
            else
            {
                u.Inactivated_On__c=DateTime.parse(LongDate);
            }
        }
    }

    public static void updateAccountShareSettingFuture(List<String> userListStr)
    {
        if(updateAccountShareSettingFirstRunFlag)
        {
            updateAccountShareSetting(userListStr);
            updateAccountShareSettingFirstRunFlag=false;
        }
    }
    //CR 1268122: Enable Read/Write access to the Partner Admins.
    @future
    public static void updateAccountShareSetting(List<String> userListStr)
    {
        System.debug('User String List :'+userListStr);
        List<AccountShare> updatedAccountShare = new List<AccountShare>();
        List<User> userList = new List<User>();
        Set<Id> updatedUserSet = new Set<Id>();
        Map<Id,Id> UserIdAccId = new Map<Id,Id>();
        String[] s = null;

        /*for(String uStr: userListStr)
        {
            s = uStr.split('#');
            UserIdAccId.put(s[0],s[1]);
        }*/

        updatedUserSet = UserIdAccId.keySet();

        for(String uStr: userListStr)
        {
            s = uStr.split('#');
            System.debug('String array :'+s);
            //String accountIdUserIdString=UserIdAccId.get(uId)+'-'+uId;
            AccountShare accShare = new AccountShare();
            accShare.AccountId = s[1];
            accShare.UserOrGroupId = s[0];
            accShare.AccountAccessLevel = 'Edit';
            accShare.CaseAccessLevel = 'None';
            accShare.OpportunityAccessLevel = 'None';
            updatedAccountShare.add(accShare);

        }
        if(updatedAccountShare.size()>0)
        {
            System.debug('Account Shares to be inserted:'+updatedAccountShare);
            insert updatedAccountShare;
        }
    }

    public static void addUsersToChannelUsersGroup(Set<Id> setOfUsersToBeAddedToChannelUsersGroup)
    {
        List<GroupMember> groupMembersToBeAdded = new List<GroupMember>();
        for(Id userId : setOfUsersToBeAddedToChannelUsersGroup)
        {
            GroupMember groupMemberToBeAdded = new GroupMember();
            groupMemberToBeAdded.GroupId = GsmUtilClass.getGSMSettingValue('UserTriggerClass_ChannelUsersGroupId'); //SFDC-2304
            groupMemberToBeAdded.UserOrGroupId = userId;
            groupMembersToBeAdded.add(groupMemberToBeAdded);
        }
        insert groupMembersToBeAdded;
    }

    public static void removeUsersFromChannelUsersGroup(Set<Id> setOfUsersToBeRemovedFromChannelUsersGroup)
    {
        List<GroupMember> listOfGroupMembersToBeRemoved = [Select Id from GroupMember where GroupId = :GsmUtilClass.getGSMSettingValue('UserTriggerClass_ChannelUsersGroupId') and UserOrGroupId in :setOfUsersToBeRemovedFromChannelUsersGroup]; //SFDC-2304
        if (listOfGroupMembersToBeRemoved.size()>0)
        {
            delete listOfGroupMembersToBeRemoved;
        }
    }

    private static List<User_Automation_Action__c> getUserActions(User usr)
    {
        List<User_Automation_Action__c> userActions = new List<User_Automation_Action__c>();
        if(actionsMap.containsKey('1__'+usr.User_Profile_Name__c))
        {
            userActions.addAll(actionsMap.get('1__'+usr.User_Profile_Name__c));
        }
        else if(actionsMap.containsKey('2__'+usr.User_Role_Name__c))
        {
            userActions.addAll(actionsMap.get('2__'+usr.User_Role_Name__c));
        }
        else if(actionsMap.containsKey('3__'+usr.User_Profile_Name__c+usr.User_Role_Name__c))
        {
            userActions.addAll(actionsMap.get('3__'+usr.User_Profile_Name__c+usr.User_Role_Name__c));
        }
        System.Debug(LoggingLevel.Error, 'AGH_ getUserActions'+userActions);
        return userActions;
    }


    public static void handleUserAutomationFieldUpdates(List<User> usersForAutomationActions)
    {
        if(!handleUserAutomationFieldUpdatesFirstRunFlag)
            return;

        System.Debug(LoggingLevel.Error, 'AGH_ handling field updates');
        Set<String> profiles = new Set<String>();
        Set<String> roles = new Set<String>();

        // u.User_Profile_Name__c for the standard Read Only profile is PT3 which is very strange
        // So this wont work for the standard Read Only profile
        for(User u : usersForAutomationActions)
        {
            profiles.add(u.User_Profile_Name__c);
            roles.add(u.User_Role_Name__c);
        }


        for(User_Automation_Action__c uaa : [select Id, Field_API_Name__c, Field_Value__c, Permission_Sets__c, Permission_Set_Licenses__c, Trigger_Condition__r.Profile__c, Action_Type__c, Trigger_Condition__r.Filter_Condition__c, Trigger_Condition__r.Role__c from User_Automation_Action__c where
                ((Trigger_Condition__r.Filter_Condition__c='Profile Only' and Trigger_Condition__r.Profile__c in :profiles)
                 or (Trigger_Condition__r.Filter_Condition__c='Role Only' and Trigger_Condition__r.Role__c in :roles)
                 or
                 (Trigger_Condition__r.Filter_Condition__c='Profile AND Role' and Trigger_Condition__r.Profile__c in :profiles and Trigger_Condition__r.Role__c in :roles)) and Trigger_Condition__r.Active__c=true])
        {
            String conditionKey = '';
            // could have had 3 different maps but i think this is simpler since i doubt anyone will
            // name their profiles or roles with 2__ or 1__ or 3__

            if(uaa.Trigger_Condition__r.Filter_Condition__c.equalsIgnoreCase('Profile AND Role'))
            {
                conditionKey = '3__'+uaa.Trigger_Condition__r.Profile__c+uaa.Trigger_Condition__r.Role__c;
            }
            else if(uaa.Trigger_Condition__r.Filter_Condition__c.equalsIgnoreCase('Profile Only'))
            {
                conditionKey = '1__'+uaa.Trigger_Condition__r.Profile__c;
            }
            else
            {
                conditionKey = '2__'+uaa.Trigger_Condition__r.Role__c;
            }
            if(actionsMap.containsKey(conditionKey))
            {
                actionsMap.get(conditionKey).add(uaa);
            }
            else
            {
                actionsMap.put(conditionKey, new List<User_Automation_Action__c>{uaa});
            }

        }

        System.Debug(LoggingLevel.Error, 'found these actionsMap'+actionsMap);

        if(actionsMap.size()>0)
        {
            for(User usr : usersForAutomationActions)
            {


                for(User_Automation_Action__c action : getUserActions(usr))
                {
                    System.Debug(LoggingLevel.Error, 'found these in action'+action);
                    if(action.Action_Type__c.equals('Field Update'))
                    {
                        System.Debug(LoggingLevel.Error, 'found these in field update'+action.Field_API_Name__c);
                        if(action.Field_Value__c.equalsIgnoreCase('true') || action.Field_Value__c.equalsIgnoreCase('false'))
                        {
                            usr.put(action.Field_API_Name__c, Boolean.valueOf(action.Field_Value__c));
                        }
                        else
                        {
                            usr.put(action.Field_API_Name__c, action.Field_Value__c);
                        }
                    }
                }
            }
        }

        handleUserAutomationFieldUpdatesFirstRunFlag=false;
    }

    public static void handleUserAutomationActions(List<User> usersWithChangedProfile)
    {
        if(!handleUserAutomationActionsFirstRunFlag)
            return;
        System.Debug(LoggingLevel.Error, 'AGH_ handling actions');

        Map<Id, List<String>> userIdToPermissionSetNames = new Map<Id, List<String>>();
        Map<Id, List<String>> userIdToPermissionSetLicenseNames = new Map<Id, List<String>>();

        if(actionsMap.size()>0)
        {

            for(User usr : usersWithChangedProfile)
            {
                System.Debug(LoggingLevel.Error, 'AGH_ profile name'+usr.User_Profile_Name__c);
                for(User_Automation_Action__c action : getUserActions(usr))
                {
                    if(action.Action_Type__c.equals('Permission Set Assignment'))
                    {
                        userIdToPermissionSetNames.put(usr.Id, new List<String>());
                        for(String permissionSetName : action.Permission_Sets__c.split(';'))
                        {
                            userIdToPermissionSetNames.get(usr.Id).add(permissionSetName.trim());
                        }
                    }
                    else if(action.Action_Type__c.equals('Permission Set License Assignment'))
                    {
                        userIdToPermissionSetLicenseNames.put(usr.Id, new List<String>());
                        for(String pSetLicenseName : action.Permission_Set_Licenses__c.split(';'))
                        {
                            userIdToPermissionSetLicenseNames.get(usr.Id).add(pSetLicenseName.trim());
                        }
                    }
                }
            }
        }
        System.Debug(LoggingLevel.error, 'AGH_ userIdToPermissionSetNames'+userIdToPermissionSetNames);
        System.Debug(LoggingLevel.error, 'AGH_ userIdToPermissionSetLicenseNames'+userIdToPermissionSetLicenseNames);

        if(userIdToPermissionSetNames.size()>0 || userIdToPermissionSetLicenseNames.size()>0)
        {
            // making it synchronous
            insertPermissionSetsAndLicenses(userIdToPermissionSetNames, userIdToPermissionSetLicenseNames);
        }

        handleUserAutomationActionsFirstRunFlag=false;
    }

    private static void insertPermissionSetsAndLicenses(Map<Id, List<String>> userIdToPermissionSetNames, Map<Id, List<String>> userIdToPermissionSetLicenseNames)
    {
        Set<String> pSetNames = new Set<String>();
        Set<String> pSetLicenseNames = new Set<String>();
        for(Id uId : userIdToPermissionSetNames.keySet())
        {
            pSetNames.addAll(userIdToPermissionSetNames.get(uId));
        }

        for(Id uId : userIdToPermissionSetLicenseNames.keySet())
        {
            pSetLicenseNames.addAll(userIdToPermissionSetLicenseNames.get(uId));
        }


        Map<String, Id> permissionSetLabelToId = new Map<String, Id>();
        Map<String, Id> permissionSetLicenseLabelToId = new Map<String, Id>();

        if(pSetNames.size()>0)
        {
            for(PermissionSet pSet : [select id, Label from PermissionSet where label in :pSetNames])
            {
                permissionSetLabelToId.put(pSet.Label, pSet.Id);
            }
        }
        if(pSetLicenseNames.size()>0)
        {
            for(PermissionSetLicense pSetLicense : [select Id, MasterLabel from PermissionSetLicense where MasterLabel in :pSetLicenseNames])
            {
                permissionSetLicenseLabelToId.put(pSetLicense.MasterLabel, pSetLicense.Id);
            }
        }

        System.Debug(LoggingLevel.error, 'AGH_ permissionSetLabelToId '+permissionSetLabelToId);
        System.Debug(LoggingLevel.error, 'AGH_ permissionSetLicenseLabelToId'+permissionSetLicenseLabelToId);

        List<PermissionSetAssignment> pSetAssignments = new List<PermissionSetAssignment>();
        for(Id uId : userIdToPermissionSetNames.keySet())
        {
            for(String pSetName : userIdToPermissionSetNames.get(uId))
            {
                PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId=uId, PermissionSetId=permissionSetLabelToId.get(pSetName));
                pSetAssignments.add(psa);
            }
        }

        List<PermissionSetLicenseAssign> pSetLicenseAssignments = new List<PermissionSetLicenseAssign>();
        for(Id uId :userIdToPermissionSetLicenseNames.keySet())
        {
            for(String pSetLicenseName : userIdToPermissionSetLicenseNames.get(uId))
            {
                PermissionSetLicenseAssign psa = new PermissionSetLicenseAssign(AssigneeId=uId,PermissionSetLicenseId=permissionSetLicenseLabelToId.get(pSetLicenseName));
                pSetLicenseAssignments.add(psa);
            }
        }

        if(pSetAssignments.size()>0)
        {
            System.Debug(LoggingLevel.Error, 'AGH_ inserting permission sets'+pSetAssignments);
            GsmUtilClass.doDatabaseInsert(pSetAssignments, 'User Automation Permission Set Assignment', 'UserTriggerClass',true);

        }
        if(pSetLicenseAssignments.size()>0)
        {
            System.Debug(LoggingLevel.Error, 'AGH_ inserting permission set licenses'+pSetLicenseAssignments);
            GsmUtilClass.doDatabaseInsert(pSetLicenseAssignments, 'User Automation Permission Set License Assignment', 'UserTriggerClass',true);
        }

    }

    public static void updateAccountLicenses(List<UpdatedUser> userList)
    {
        if(!updateAccountLicensesFirstRunFlag)
            return;
        System.Debug(LoggingLevel.Error, 'AGH_D userList'+userList);
        // get accounts belonging to these users
        // user id, accountid, contactid, old profile, new profile
        Set<Id> accIds = new Set<Id>();

        for(UpdatedUser ithUser : userList)
        {
            accIds.add(ithUser.getAccountId());
            if(ithUser.hasChangedAccount())
            {
                accIds.add(ithUser.getOldAccountId());
            }
        }

        Map<Id, AccountLicenseInfo> accIdToLicenseInfo= new Map<Id, AccountLicenseinfo>();

        Integer lite;
        Integer nonLite;
        for(Account acc: [select id, current_licenses__c, Current_Lite_Licenses__c from Account where id in :accIds])
        {
            lite = (acc.Current_Lite_Licenses__c==null)?0:acc.Current_Lite_Licenses__c.IntValue();
            nonLite = (acc.Current_Licenses__c==null)?0:acc.Current_Licenses__c.IntValue();
            accIdToLicenseInfo.put(acc.id, new AccountLicenseInfo(acc.id, lite, nonLite));
        }


        List<Contact> contactsToBeUpdated = new List<Contact>();

        for(UpdatedUser ithUser : userList)
        {
            System.Debug(LoggingLevel.Error, 'AGH_D ithUser'+ithUser);
            AccountLicenseInfo acc = accIdToLicenseInfo.get(ithUser.getAccountId());
            if(ithUser.hasChangedAccount())
            {
                System.Debug(LoggingLevel.Error, 'AGH_D accountschanged');
                if(ithUser.isActive())
                {
                    AccountLicenseInfo oldAcc = accIdToLicenseInfo.get(ithUser.getOldAccountId());
                    System.Debug(LoggingLevel.Error, 'AGH_D old account bef'+oldAcc);
                    if(ithUser.isLiteProfile())
                    {
                        System.Debug(LoggingLevel.Error, 'AGH_D account change islite');
                        acc.incrementLiteLicense();
                        oldAcc.decrementLiteLicense();
                    }
                    else
                    {
                        acc.incrementNonLiteLicense();
                        oldAcc.decrementNonLiteLicense();
                    }
                    System.Debug(LoggingLevel.Error, 'AGH_D old account after'+oldAcc);
                }

            }
            else
            {
                if(!ithUser.isGettingDeactivated())
                {

                    if(ithUser.isChangingFromLiteToNonLite())
                    {
                        acc.decrementLiteLicense();
                        acc.incrementNonLiteLicense();
                    }
                    else if(ithUser.isChangingFromNonLiteToLite())
                    {
                        acc.incrementLiteLicense();
                        acc.decrementNonLiteLicense();
                    }
                    else if(ithUser.isChangingFromNonLiteAToNonLiteB())
                    {
                        // do nothing
                        // keep the same count
                    }
                    else if(ithUser.isLiteProfile())
                    {
                        System.Debug(LoggingLevel.Error, 'AGH_D islite');
                        acc.incrementLiteLicense();
                    }
                    else if(ithUser.isNonLiteProfile())
                    {
                        System.DEbug(LoggingLevel.Error, 'AGH_D isnonlite');
                        acc.incrementNonLiteLicense();
                    }
                }
                else
                {
                    //for deactivation
                    if(ithUser.wasLiteProfile())
                    {
                        acc.decrementLiteLicense();
                    }
                    else
                    {
                        acc.decrementNonLiteLicense();
                    }
                }

                if(ithUser.contactNeedsUpdate())
                {
                    System.Debug(LoggingLevel.Error, 'AGH_D contactNeedsUpdate');
                    contactsToBeUpdated.add(ithUser.getContact());
                }
            }
        }


        List<Account> accountsToBeUpdated = new List<Account>();

        for(Id accId : accIdToLicenseInfo.keySet())
        {
            accountsToBeUpdated.add(accIdToLicenseInfo.get(accId).getAccount());
        }
        System.Debug(LoggingLevel.Error, 'AGH_D acc'+accountsToBeUpdated);

        if(accountsToBeUpdated.size()>0)
            GsmUtilClass.doDatabaseUpdate(accountsToBeUpdated, 'UserTriggerClass', 'LicenseUpdate');

        if(contactsToBeUpdated.size()>0)
        {
            System.Debug(LoggingLevel.Error, 'AGH_D contactNeedsUpdate'+contactsToBeUpdated);
            GsmUtilClass.doDatabaseUpdate(contactsToBeUpdated, 'UserTriggerClass', 'UpdatePartnerUserLookupOnContact');
        }


        updateAccountLicensesFirstRunFlag=false;
    }


    @future
    public static void updateAccountLicenses(String userListJson)
    {
        if(!updateAccountLicensesFirstRunFlagFuture)
            return;

        List<UpdatedUser> userList = (List<UpdatedUser>)JSON.deserialize(userListJson, List<UpdatedUser>.class);
        updateAccountLicenses(userList);

        updateAccountLicensesFirstRunFlagFuture=false;
    }

    /**
      ButtonInvoke2()
      - Allows inactiveContactowner update logic to be invoked by OnClick JavaScript button .
     */
    Webservice static String ButtonInvoke2()
    {
        String retMessage = 'This feature is disabled!';
        String profileIdsWithAccess = GsmUtilClass.getGSMSettingValue('DataFixButtonContactOwner_ProfileIDs'); //SFDC-2304
        List<String> exemptedUserAliasList;
        if (GsmUtilClass.isFeatureToggleEnabledCustomMetadata('UpdateContactOwnerForInActiveUsers') == true) //SFDC-2304
        {
            if (!profileIdsWithAccess.contains(Userinfo.getProfileId()))
            {
                retMessage = 'You do not have sufficient privileges to perform this action. Please contact System Administrator for access.';
            }
            else
            {
                //String exemptedUserAlias = L2Q_UserTriggerClass.userTriggerCustomSettings.exemptedUserAlias__c; //SFDC-2304
                String exemptedUserAlias = GsmUtilClass.getGSMSettingValue('UsrTrgrCls_ExemptedUserAlias'); //SFDC-2304
                exemptedUserAliasList = exemptedUserAlias.split(',');
                String exemptedUserQueryClause='';
                for (String usrAlias : exemptedUserAliasList)
                {
                    if (exemptedUserQueryClause=='')
                        exemptedUserQueryClause = '\'' + usrAlias.trim() + '\'';
                    else
                        exemptedUserQueryClause += ',\'' + usrAlias.trim() + '\'';
                }
                String query =  'SELECT Owner.AKAM_User_ID__c, Id, OwnerId, Account.OwnerId, Account.Owner.isActive FROM Contact WHERE Owner.IsActive = false AND AccountId!=null AND Owner.Alias NOT IN (' + exemptedUserQueryClause +')';
                        System.debug('Query=' + query);
                        BatchableUpdateContactOwner changeContactOwner = new BatchableUpdateContactOwner(query);
                        ID batchprocessid = Database.executeBatch(changeContactOwner);
                        retMessage = 'Update Contact Owner batch apex has been scheduled.';

            }
            /*else
              {
              String exemptedUserAlias = UserTriggerClass.userTriggerCustomSettings.exemptedUserAlias__c;

              List<String> allInactiveContactOwners = new List<String>();
              List<Contact> updateContactsList = [Select Owner.AKAM_User_ID__c, Owner.Alias From Contact where Owner.IsActive = false AND AccountId!=null];
              for (Contact cntct : updateContactsList)
              {
              if (cntct.Owner.AKAM_User_ID__c!=null && !exemptedUserAlias.contains(cntct.Owner.Alias))
              allInactiveContactOwners.add(cntct.Owner.AKAM_User_ID__c);
              }
              if (allInactiveContactOwners.size()>0)
              {
              String strInactiveUserId = '';
              for (String usrId : allInactiveContactOwners)
              {
              if (strInactiveUserId=='')
              strInactiveUserId = '\'' + usrId + '\'';
              else
              strInactiveUserId += ',\'' + usrId + '\'';
              }
              System.debug('strInactiveUserId=' + strInactiveUserId);

            // form the query
            String query = 'SELECT Owner.AKAM_User_ID__c, Id, OwnerId, Account.OwnerId, Account.Owner.isActive FROM Contact WHERE AccountId!=null AND Owner.AKAM_User_ID__c IN (' + strInactiveUserId +')';
            System.debug('query='+ query);

            BatchableUpdateContactOwner changeContactOwner = new BatchableUpdateContactOwner(query);
            ID batchprocessid = Database.executeBatch(changeContactOwner);
            retMessage = 'Update Contact Owner batch apex has been scheduled.';
              }
              else
              retMessage = 'No Contacts qualify for InActive Owner change update';
              }*/
        }
        return retMessage;
    }
    /**Begin Rajesh Kumar JIRA# > SFDC-5088  */
   //Below method assign content licence to  to defined user in Salesforce
   public static void contentLicenceupdate(List < User > users) {
       List<Error_Log__c> errorLogs = new List<Error_Log__c>();
       try {
       if (handleContentfirstrun) {
           List < Id > profileList = new List < Id > ();
           List < GSM_Settings_Verbose__mdt > configProfiles = [select Id, Value__c, DeveloperName from GSM_Settings_Verbose__mdt where DeveloperName = 'SF_Profiles' Limit 1];
           String configProfile = configProfiles[0].Value__c;
           System.debug('configProfile>>' + configProfile);
           List < GSM_Settings__mdt > configUserTypes = [select Id, Value__c, DeveloperName from GSM_Settings__mdt where DeveloperName = 'SF_UserType' Limit 1];
           String configUserType = configUserTypes[0].Value__c;
           System.debug('configUserType>>' + configUserType);
           List < GSM_Settings_Verbose__mdt > configUserlicenses = [select Id, Value__c, DeveloperName from GSM_Settings_Verbose__mdt where DeveloperName = 'SF_User_Licenses' Limit 1];
           String configUserlicense = configUserlicenses[0].Value__c;
           System.debug('configUserlicense>>' + configUserlicense);

           for (User usr: users) {
               profileList.add(usr.profileId);
           }
           //map to store corresponding user licence ,type and profile name
           Map < Id, profile > userTypemap = new Map < Id, Profile > ([Select Id, Name, UserType, UserLicense.Name from profile where Id in: profileList]);
           for (User usr: users) {
               //SFDC-6913 Start
               if (userTypemap.containsKey(usr.profileId) && configUserType.containsIgnoreCase(userTypemap.get(usr.profileId).UserType)) {
                   if(!String.isEmpty(configProfile) && !String.isEmpty(configUserlicense)) {
                       if(configProfile.containsIgnoreCase(userTypemap.get(usr.profileId).Name) && configUserlicense.containsIgnoreCase(userTypemap.get(usr.profileId).UserLicense.Name)) {
                            usr.UserPermissionsSFContentUser = true;
                       }
                   } else {
                        usr.UserPermissionsSFContentUser = true;
                   }
               }
               //SFDC-6913 End
           }
          handleContentfirstrun = false;
       }

       }
       catch (Exception ex){
           handleContentfirstrun = false;
           Error_Log__c el = new Error_Log__c(Name='SalesforceContentLicenceAssignmentError', Class__c='L2Q_UserTriggerClass', Error_Message__c=ex.getMessage());
           errorLogs.add(el);
       }
       if(errorLogs.size()>0)
            Database.insert(errorLogs, false);
   }
   /**End Rajesh Kumar JIRA# > SFDC-5088  */

    //SFDC-8975
    @future
    public static void getRebatePayouts(List<Id> accountIds, List<id> addRpShares, List<id> deleteRpShare){
        List<Id> accountIdList=new List<Id>();
        List<Rebate_Payout__c> rpsList = new List<Rebate_Payout__c>();
        for(Rebate_Payout__C rps :[Select id,ownerId, Associated_Partner__c from Rebate_Payout__c where Associated_Partner__c in :accountIds]){
            accountIdList.add(rps.Associated_Partner__c);
            rpsList.add(rps);
        }
        System.debug('**********TS rpsList ' +rpsList );
        System.debug('**********TS accountIdList '+ accountIdList);
        if(rpsList.size() >0 ){
            //PRM_opportunity.addPartnerAdminSharing(accountIdList, rpsList);
            PRM_opportunity.modifyPartnerAdminSharingForUser(rpsList, addRpShares, deleteRpshare);

        }
    }

}