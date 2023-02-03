public class AccountReassignmentTriggerClass {

    public static void preventDuplicateAccountReassignments(AccountReassignmentDataProvider dataObj){
        Account_Reassignment__c[] accReassignList = dataObj.getNewReassignmentList();
        Set<Id> accountIdSet = dataObj.getAccountIdSet();
        Map<Id,Account_Reassignment__c> accountIdMap = getPendingReassignmentRequests(accountIdSet);
        for(Account_Reassignment__c accReassign: accReassignList){
            if(accountIdMap.keySet().contains(accReassign.Account__c))
                accReassign.addError(dataObj.getReassignConfigSetting().get('Error_Prevent_Duplicates'));
        }
    }
    
    public static map<Id, Account_Reassignment__c> getPendingReassignmentRequests(set<Id> accountIds){
        map<Id,Account_Reassignment__c> accountIdMap = new map<Id,Account_Reassignment__c>();
        List<String> arrPreventDuplicationStatus = GsmUtilClass.getGSMSettingValue('ARR_Prevent_Duplication_Status').split(',');
        for(Account_Reassignment__c accReass : [select Id,
                                                Name,
                                                Account__c,
                                                Adhoc_Request__c
                                                from Account_Reassignment__c
                                                where Account__c IN :accountIds and
                                                Reassign_Status__c NOT IN :arrPreventDuplicationStatus])
            accountIdMap.put(accReass.Account__c, accReass);
        return accountIdMap;
    }
    
    public static AccountReassignmentDataProvider setDataVariables(AccountReassignmentDataProvider dataObj){
        map<Id,Account> accIdToAccMap = new map<Id,Account>();
        map<Id,Id> accOwnerToRsmMap = new map<Id,Id>();
        map<Id,Account_Reassignment_Rule__c> userIdToRuleMap = new map<Id,Account_Reassignment_Rule__c>();
        map<Id,Account_Reassignment_Rule__c> ruleIdToRuleMap = new map<Id, Account_Reassignment_Rule__c>();
        set<Id> revenueAccountIdSet = new set<Id>();
        map<Id,Boolean> accOwnerToStatusMap = new map<Id,Boolean>();
        map<Id,string> associatedUserIdToRoleMap = new map<Id,string>();
        list<Account> accList = [select Id,Owner.Alias,OwnerId,Owner.Status__c,Account_Status__c,Network_Account__c,
                                 Revenue_Account__c,Anaplan_Sub_Territory__c,Account_Reassignment_Rule__c,
                                 TERR_HIER_1__c, TERR_HIER_2__c, TERR_HIER_3__c, TERR_HIER_4__c, TERR_HIER_5__c,
                                 /*Division_Formula__c,Geography_Formula__c,Region__c,Area__c,Division__c,*/
                                 Old_Account_Owner__c,Akam_Territory_Mapping_Id__c, 
                                 (select Id, UserId, AccountId, TeamMemberRole from AccountTeamMembers),
                                 (select Id,Probability,StageName from Opportunities where (NOT StageName like 'Closed%') AND RecordTypeId IN : dataObj.getReassignOpptyRecTypes()) 
                                 from Account 
                                 where Id IN : dataObj.getAccountIdSet()];
        for(Account acc : accList)
        {
            accIdToAccMap.put(acc.Id,acc);
            accOwnerToRsmMap.put(acc.OwnerId,null);
            if(acc.Owner.Status__c != 'Active')
                accOwnerToStatusMap.put(acc.OwnerId,false);
            else
                accOwnerToStatusMap.put(acc.OwnerId,true);
            if(acc.Revenue_Account__c || acc.Opportunities.size()>0)
                revenueAccountIdSet.add(acc.Id);
        }
        if(accOwnerToStatusMap.size()>0)
            dataObj.setAccOwnerStatusMap(accOwnerToStatusMap);
        if(accIdToAccMap.size()>0)
            dataObj.setAccIdToAccountMap(accIdToAccMap);
        if(revenueAccountIdSet.size()>0)
            dataObj.setRevenueAccountSet(revenueAccountIdSet);
        
        for(Account_Reassignment_Rule__c rule : [select Id, Name, Associated_User__c,Associated_User__r.ManagerId,SubTerritory__c, Area__c,
                                                 Associated_User__r.Manager.IsActive,Division__c, Associated_User_RSM__c, Associated_User__r.UserRole.Name,
                                                 Associated_User_RSM__r.IsActive, /*Division_Formula__c, Region__c, Geography_Formula__c,
                                                 Parent_Division__c,*/ Territory_ID__r.Akam_Territory_Mapping_Id__c,Remove_Existing_Team_Members__c,
                                                 TERR_HIER_1__c, TERR_HIER_2__c, TERR_HIER_3__c, TERR_HIER_4__c, TERR_HIER_5__c, Sales_Ops_Approver__c, Sales_Ops_Approver__r.email, Sales_Ops_Approver__r.Name
                                                 from Account_Reassignment_Rule__c 
                                                 where (NOT Name LIKE 'OLD_%') AND (Associated_User__c IN : accOwnerToRsmMap.keySet() 
                                                 OR Id IN : dataObj.getAssignToRuleIdSet()  
                                                 OR Name =: dataObj.getReassignConfigSetting().get('ONA_Reassignment_Rule_Name'))])
        {
            accOwnerToRsmMap.put(rule.Associated_User__c,getUserRSM(rule));
            userIdToRuleMap.put(rule.Associated_User__c,rule);
            ruleIdToRuleMap.put(rule.Id,rule);
            associatedUserIdToRoleMap.put(rule.Associated_User__c,rule.Associated_User__r.UserRole.Name);

        }
        
        if(ruleIdToRuleMap.size()>0)
            dataObj.setRuleIdToRuleMap(ruleIdToRuleMap);
        if(accOwnerToRsmMap.size()>0){
            dataObj.setAccOwnerToRsmMap(accOwnerToRsmMap);
            dataObj.setAssociatedUserIdSet(accOwnerToRsmMap.keySet());
            set<Id> rsmSet = new set<Id>();
            rsmSet.addAll(accOwnerToRsmMap.values());
            dataObj.setAssociatedUserIdSet(rsmSet);
        }
        if(associatedUserIdToRoleMap.size()>0)
            dataObj.setAssociatedUserIdToRoleMap(associatedUserIdToRoleMap);

        if(userIdToRuleMap.size() > 0){
            dataObj.setUserIdToRuleMap(userIdToRuleMap);
        }
        
        return dataObj;
    }
    
    public static Id getUserRSM(Account_Reassignment_Rule__c assignToRule){
        if(assignToRule.Associated_User_RSM__c != null && assignToRule.Associated_User_RSM__r.IsActive)
            return assignToRule.Associated_User_RSM__c;
        else if(assignToRule.Associated_User__r.ManagerId != null && assignToRule.Associated_User__r.Manager.IsActive)
            return assignToRule.Associated_User__r.ManagerId;
        else
            return null;
    }
    
    public static Account_Reassignment__c setDGRAT(Account_Reassignment__c aR,Account acc,Account_Reassignment_Rule__c assignToRule,AccountReassignmentDataProvider dataObj){
        aR.Requesting_User__c = Userinfo.getUserId();
        if(acc != null){
            aR.Account_Status__c = acc.Account_Status__c;
            aR.Account_Owner__c = acc.OwnerId;
            aR.Account_Owner_RSM__c = dataObj.getAccOwnerToRsmMap().get(acc.OwnerID);
        }
        if(assignToRule != null){
            aR.Assign_To_User__c = assignToRule.Associated_User__c;
            aR.Assign_To_User_RSM__c = AccountReassignmentTriggerClass.getUserRSM(assignToRule);
            //aR.AssignTo_Div_Area__c = assignToRule.Geography_Formula__c +'-'+assignToRule.Division_Formula__c + '-' + assignToRule.Region__c + '-' + assignToRule.Division__c;
            
            if(assignToRule.TERR_HIER_1__c != null)
                aR.Assign_To_Geography__c = assignToRule.TERR_HIER_1__c;

            if(assignToRule.TERR_HIER_2__c != null)
                aR.Assign_To_Region__c = assignToRule.TERR_HIER_2__c;

            if(assignToRule.TERR_HIER_3__c!=null)
                aR.Assign_To_Area__c = assignToRule.TERR_HIER_3__c;
            
            if(assignToRule.TERR_HIER_4__c!=null)
                aR.Assign_To_Zone__c = assignToRule.TERR_HIER_4__c;

            if(assignToRule.TERR_HIER_5__c!=null)
                aR.Assign_To_Territory__c = assignToRule.TERR_HIER_5__c;
            
            if(assignToRule.SubTerritory__c!=null)
                aR.Assign_To_Sub_Territory__c = assignToRule.SubTerritory__c;
            
            String poolUsersAlias = dataObj.getReassignConfigSetting().get('SalesInsidePoolUserAlias'); 
            
            List<String> poolUserList = poolUsersAlias.split('\\,');
            if(poolUsersAlias.contains(acc.Owner.alias))
                aR.IsPoolUserRequest__c = true;
            
            if(assignToRule!= null && assignToRule.Associated_User__c==acc.ownerId) 
                aR.Reassign__c=true;
            /*
            aR.AcctOwner_Div_Area__c = String.format('{0}-{1}-{2}-{3}', new List<String>{
                acc.Geography_Formula__c,
                    acc.Division_Formula__c,
                    acc.Region__c,
                    acc.Division__c
                    });
            */

            //aR.Account_Owner_Division__c = acc.Division_Formula__c;
            aR.Account_Owner_Geography__c = acc.TERR_HIER_1__c;
            aR.Account_Owner_Region__c = acc.TERR_HIER_2__c;
            aR.Account_Owner_Area__c = acc.TERR_HIER_3__c;
            aR.Account_Owner_Zone__c = acc.TERR_HIER_4__c;
            aR.Account_Owner_Territory__c = acc.TERR_HIER_5__c;
            aR.Account_Owner_Sub_Territory__c = acc.Anaplan_Sub_Territory__c;
        }
        return aR;
    }
    
    /*public static AccountReassignmentDataProvider setRegionalSalesOps(AccountReassignmentDataProvider dataObj){
        String userType = Schema.SObjectType.User.getKeyPrefix();
        set<Id> groupMemberUserIdSet = new set<Id>();
        map<string,Set<Id>> salesOpsGroupMemberMap = new map<string,Set<Id>>();
        String groupDevNamePrefix = dataObj.getGsmSetting().get('AccountReassignment_Prefix');
        groupDevNamePrefix = groupDevNamePrefix + '%';
        for(Group g : [SELECT Id,Name,DeveloperName,Type, 
                       (SELECT GroupId,Id,SystemModstamp,UserOrGroupId FROM GroupMembers) 
                       FROM Group 
                       where Type = 'Regular' and Name like :groupDevNamePrefix])
        {
            set<Id> tempGroupMemberSet = getGroupMembers(g.GroupMembers,userType);
            if (tempGroupMemberSet.size()>0){
                salesOpsGroupMemberMap.put(g.DeveloperName,tempGroupMemberSet);
                groupMemberUserIdSet.addAll(tempGroupMemberSet);
            }
        }
        
        if (salesOpsGroupMemberMap.size()>0){
            dataObj.setSalesOpsGroupMemberMap(salesOpsGroupMemberMap);
            dataObj.setAssociatedUserIdSet(groupMemberUserIdSet);
        }
        return dataObj;
    }
    
    public static set<Id> getGroupMembers(list<GroupMember> pGroupMembersList,string pUserType){
        set<Id> tempGroupMemberSet = new set<Id>();
        for(GroupMember gm : pGroupMembersList){
            if(((string)gm.UserOrGroupId).startsWith(pUserType))
                tempGroupMemberSet.add(gm.UserOrGroupId);
        }
        return tempGroupMemberSet;
    }*/
    
    public static string concatTwoStrings(String pExistingVal, String pNewVal){
        String concatenatedString=pNewVal;
        if (pExistingVal!=null && pExistingVal.length()>0)
            concatenatedString= pExistingVal + ',' + pNewVal;
        return concatenatedString;
    }
    
    public static void accept(Account_Reassignment__c accReassign, AccountReassignmentDataProvider dataObj){
        Integer startDay = Integer.valueOf(dataObj.getReassignConfigSetting().get('AssignNextMonthCutOffStart'));
        Integer endDay = Integer.valueOf(dataObj.getReassignConfigSetting().get('AssignNextMonthCutOffEnd'));
        map<String,ReasonCodeSettings> accReasonCodeSettingsmap = getAccountReasonCodeSettings(dataObj);
        Boolean respectCutOff = true;
        
        if(accReassign.Reason_Code__c != null) {
            String reasonCode = accReassign.Reason_Code__c.replace(' ','_');
            reasonCode = reasonCode.replace('-', '_');
            ReasonCodeSettings reasonCodeSettings = accReasonCodeSettingsmap.get(reasonCode);
            respectCutOff = reasonCodeSettings.respectCutoff;
        }
        if(accReassign.Action__c == dataObj.getReassignConfigSetting().get('Action_Active_Approval')){
            Boolean isPastCutOffDate = false;
            isPastCutOffDate=isPastCutOffDate(accReassign,dataObj);
            if(accReassign.Reassign__c || !respectCutOff || accReassign.Account_Status__c.contains('Inactive') || accReassign.Account_Status__c.contains('Lead'))
            {
                accReassign.Reassign__c = true;
                accReassign.Reassign_Status__c = 'Accepted';
                accReassign.Status_Message__c = dataObj.getReassignConfigSetting().get('Status_Accepted');
                accReassign.Reassignment_Due_Date__c=Date.today();
            }
            else if(accReassign.IsPoolUserRequest__c == true)
            {
                accReassign.Reassign__c = true;
                accReassign.Reassign_Status__c = 'Approved';
                accReassign.Status_Message__c = dataObj.getReassignConfigSetting().get('Status_Approved');
            }
            else if(!accReassign.Adhoc_Request__c && (isPastCutOffDate || (accReassign.Reassignment_Due_Date__c!=null && accReassign.Reassignment_Due_Date__c>Date.today())))
            {
                accReassign.Reassign_Status__c='Approved';
                accReassign.Status_Message__c = dataObj.getReassignConfigSetting().get('Status_Approved');
                if(Date.today().day()>=startDay){
                    if(Date.today().month()<12)
                        accReassign.Reassignment_Due_Date__c = Date.newInstance(Date.today().year(), Date.today().addMonths(1).month(), Integer.valueOf(dataObj.getReassignConfigSetting().get('Active_Account_Next_Month_Day')));
                    else
                        accReassign.Reassignment_Due_Date__c = Date.newInstance(Date.today().addYears(1).year(), Date.today().addMonths(1).month(), Integer.valueOf(dataObj.getReassignConfigSetting().get('Active_Account_Next_Month_Day')));
                }
                else if(Date.today().day()<=endDay){
                    accReassign.Reassignment_Due_Date__c = Date.newInstance(Date.today().year(), Date.today().month(), Integer.valueOf(dataObj.getReassignConfigSetting().get('Active_Account_Next_Month_Day')));
                }
            }
            else{
                accReassign.Reassign__c = true;
                accReassign.Reassign_Status__c = 'Accepted';
                accReassign.Status_Message__c = dataObj.getReassignConfigSetting().get('Status_Accepted');
                accReassign.Reassignment_Due_Date__c=Date.today();
            }
        }
        else if(accReassign.Reassignment_Due_Date__c!=null && accReassign.Reassignment_Due_Date__c>Date.today()){
            accReassign.Reassign_Status__c='Approved';
            accReassign.Status_Message__c = dataObj.getReassignConfigSetting().get('Status_Approved');
        }
        else{
            accReassign.Reassign__c = true;
            accReassign.Reassign_Status__c = 'Accepted';
            accReassign.Status_Message__c = dataObj.getReassignConfigSetting().get('Status_Accepted');
        }
    }
    
    public class ReasonCodeSettings {
        public boolean approvalRequired;
        public boolean respectCutOff;
    }
    
    public static Map<String,ReasonCodeSettings> getAccountReasonCodeSettings(AccountReassignmentDataProvider dataObj) {
        list<Account_Reassignment_Reason_Code__mdt>  arrcRecords = dataObj.getReasonCodeSetting();
        map<String,ReasonCodeSettings> accReasonCodeSettingsmap = new map<String,ReasonCodeSettings>();
        for(Account_Reassignment_Reason_Code__mdt rCode : arrcRecords){
            ReasonCodeSettings settings = new ReasonCodeSettings();
            settings.approvalRequired = rCode.Approval_Required__c;
            settings.respectCutOff = rCode.Respect_Cut_off__c;
            accReasonCodeSettingsmap.put(rCode.developerName,settings);
        }
        return accReasonCodeSettingsmap;
    }
    
    public static Boolean isPastCutOffDate(Account_Reassignment__c pReassignReq, AccountReassignmentDataProvider dataObj){
        Integer startDay = Integer.valueOf(dataObj.getReassignConfigSetting().get('AssignNextMonthCutOffStart'));
        Integer endDay = Integer.valueOf(dataObj.getReassignConfigSetting().get('AssignNextMonthCutOffEnd'));
        Boolean isPastCutOff=false;
        Account_Reassignment__c reassignReq = pReassignReq;
        Date createdDate;
        if (reassignReq.CreatedDate == null) {
            createdDate = System.today();
        } else {
            createdDate = reassignReq.CreatedDate.date();
        }
        if(Date.today().day()>=startDay || Date.today().day() <= endDay)
            isPastCutOff=true;
        return isPastCutOff;
    }
    
    public static void sendForApproval(Account_Reassignment__c accReassign, String stausMessage){
        accReassign.Reassign_Status__c = 'Approval Pending';
        accReassign.Status_Message__c = stausMessage;
    }
    
    public static AccountReassignmentDataProvider setUserIdToUserMap(AccountReassignmentDataProvider dataObj){
        boolean requiredFlag = false;
        map<Id,User> userMap = new Map<Id,User>();
        set<Id> inMapUserIds = new Set<Id>();
        userMap = dataObj.getUserIdToUserMap();
        inMapUserIds = userMap.keySet();
        
        for(Id usrId : dataObj.getAssociatedUserIdSet()){
            if (userMap.size()<1 || !inMapUserIds.contains(usrId)){
                requiredFlag=true;
                break;
            }
        }
        if(!requiredFlag)
            return dataObj;
        
        for(User u : [Select Id,Alias,email,profile.Name,UserRole.Name,isActive, Name from User where Id IN : dataObj.getAssociatedUserIdSet()])
            userMap.put(u.Id,u);
        
        dataObj.setUserIdToUserMap(userMap);
        return dataObj;
    }
    
    /*public static list<User> getRegionalSalesOps(String pGeography,String pDivision, String pArea,String pRegion, AccountReassignmentDataProvider dataObj){
        map<String,Set<Id>> salesOpsGroupMemberMap = dataObj.getSalesOpsGroupMemberMap();
        list<User> opsUsers = new list<User>();
        map<Id,User> userMap = dataObj.getUserIdToUserMap();
        list<String> groupNameContructedList = getGroupContructedSet(pGeography,pDivision,pArea,pRegion,dataObj);
        for(String groupName:groupNameContructedList) {
            if (salesOpsGroupMemberMap != null && groupName != null ) {
                if (salesOpsGroupMemberMap.keySet().contains(groupName)) {
                    Set<Id> grpMember = salesOpsGroupMemberMap.get(groupName);
                    for (Id uId : grpMember){
                        User usr = userMap.get(uId);
                        if (usr!=null && usr.isActive)
                            opsUsers.add(usr);
                    }
                }
            }
        }
    }*/

    /*
    public static list<String> getGroupContructedSet(String pGeography,String pDivision,String pArea,String pRegion,AccountReassignmentDataProvider dataObj){
        String groupDevNamePrefix = dataObj.getGsmSetting().get('AccountReassignment_Prefix');
        groupDevNamePrefix = groupDevNamePrefix + '_';
        List<String> groupNameContructedList = new List<String>();
        String pGeo = !String.isEmpty(pGeography)?pGeography.replace(' ','_'):'';
        if (pArea != null && !String.isEmpty(pArea) ) {
            String groupNameForArea = groupDevNamePrefix+ pGeo +'_'+(pArea.replace(' ','_'));
            groupNameForArea = groupNameForArea.replace('&','and');
            groupNameForArea = groupNameForArea.substring(0, Math.min(groupNameForArea.length(), 40));
            groupNameContructedList.add(groupNameForArea);
        }
        if (pRegion != null && !String.isEmpty(pRegion) ) {
            String groupNameForRegion = groupDevNamePrefix + pGeo + '_' + (pRegion.replace(' ','_'));
            groupNameForRegion = groupNameForRegion.replace('&','and');
            groupNameForRegion = groupNameForRegion.substring(0, Math.min(groupNameForRegion.length(), 40));
            groupNameContructedList.add(groupNameForRegion);
        }
        if ((pDivision != null && !String.isEmpty(pDivision))) {
            String groupNameForDivision = groupDevNamePrefix+ pGeo +'_'+(pDivision.replace(' ','_'));
            groupNameForDivision = groupNameForDivision.replace('&','and');
            groupNameForDivision = groupNameForDivision.substring(0, Math.min(groupNameForDivision.length(), 40));
            groupNameContructedList.add(groupNameForDivision);
        }
        return groupNameContructedList;
    }
    */
    
    public static set<String> getUserEmailId(Set<Id> pUserIdSet,AccountReassignmentDataProvider dataObj){
        Map<Id,User> userMap = dataObj.getUserIdToUserMap();
        Set<String> emailIdSet = new Set<String>();
        for (Id uId : pUserIdSet)
        {
            User usr = userMap.get(uId);
            if (usr!=null && usr.isActive)
                emailIdSet.add(usr.Email);
        }
        return emailIdSet;
    }
    
    public static void decideAction(Account_Reassignment__c accReassign,AccountReassignmentDataProvider dataObj){
        //list<Id> salesOpsUsers = new list<Id>();
        Account tempAcc = dataObj.getAccIdToAccountMap().get(accReassign.Account__c);
        User accOwner = dataObj.getUserIdToUserMap().get(accReassign.Account_Owner__c);
        String salesOpsId;
        Account_Reassignment_Rule__c assignToRule = dataObj.getRuleIdToRuleMap().get(accReassign.Assign_To__c);
        if(assignToRule != null){
            if(String.isNotBlank(assignToRule.Sales_Ops_Approver__c)){
                //salesOpsUsers.add(assignToRule.Sales_Ops_Approver__c);
                salesOpsId = assignToRule.Sales_Ops_Approver__c;
            }
            //salesOpsUsers = getRegionalSalesOps(assignToRule.Geography_Formula__c,assignToRule.Division_Formula__c,assignToRule.Region__c,assignToRule.Division__c,dataObj);
            if(salesOpsId != null ){
                accReassign.Approver_2__c = salesOpsId;
                if(accReassign.Assign_To_User_RSM__c == null){
                    accReassign.Assign_To_User_RSM__c = accReassign.Approver_2__c;
                }
                accReassign.RegionalSalesOpsUserIDs__c = concatTwoStrings(accReassign.RegionalSalesOpsUserIDs__c,salesOpsId);
                accReassign.RegionalSalesOpsEmailIDs__c = concatTwoStrings(accReassign.RegionalSalesOpsEmailIDs__c, assignToRule.Sales_Ops_Approver__r.email);

            }
        }
        System.debug('salesOpsId:'+salesOpsId);
        //salesOpsUsers.clear();
        salesOpsId = null;
        //salesOpsUsers = getRegionalSalesOps(tempAcc.Geography_Formula__c,tempAcc.Division_Formula__c,tempAcc.Region__c,tempAcc.Division__c,dataObj);
        System.debug('dataObj.getUserIdToRuleMap():'+dataObj.getUserIdToRuleMap());
        Account_Reassignment_Rule__c oldAccountOwnerRule = dataObj.getUserIdToRuleMap().get(accOwner.id);
        if(oldAccountOwnerRule != null){
            if(String.isNotBlank(oldAccountOwnerRule.Sales_Ops_Approver__c)){
                salesOpsId = oldAccountOwnerRule.Sales_Ops_Approver__c;
            }
        }
        System.debug('salesOpsId::'+salesOpsId);
        if(salesOpsId != null){
            accReassign.Approver_1__c = salesOpsId;
            if(accReassign.Account_Owner_RSM__c==null)
                accReassign.Account_Owner_RSM__c = accReassign.Approver_1__c;

            accReassign.RegionalSalesOpsUserIDs__c = concatTwoStrings(accReassign.RegionalSalesOpsUserIDs__c, salesOpsId);
            accReassign.RegionalSalesOpsEmailIDs__c = concatTwoStrings(accReassign.RegionalSalesOpsEmailIDs__c, oldAccountOwnerRule.Sales_Ops_Approver__r.email);
            //accReassign.RegionalSalesOpsUserIDs__c = concatTwoStrings(accReassign.RegionalSalesOpsUserIDs__c,Util.pluckAsString(salesOpsUsers,User.Id));
            //accReassign.RegionalSalesOpsEmailIDs__c = concatTwoStrings(accReassign.RegionalSalesOpsEmailIDs__c,Util.pluckAsString(salesOpsUsers,User.Email));
        }
        
        if(accReassign.Account_Owner_RSM__c==null)
            accReassign.Account_Owner_RSM__c=dataObj.getGsmSetting().get('AccReassign_DefaultRSMID');
        
        if(accReassign.Assign_To_User_RSM__c==null)
            accReassign.Assign_To_User_RSM__c = dataObj.getGsmSetting().get('AccReassign_DefaultRSMID');
        
        if(!accReassign.Skip_Validations__c && !String.isBlank(accReassign.Sales_Ops_Approver__c)){
            if(salesOpsId != null){
                if(!accReassign.Sales_Ops_Approver__c.containsIgnoreCase(oldAccountOwnerRule.Sales_Ops_Approver__r.Name))
                    accReassign.Sales_Ops_Approver__c.addError('Sending Sales Ops Manager is incorrect. It should be '+oldAccountOwnerRule.Sales_Ops_Approver__r.Name+'.');
            }
            else
                accReassign.Sales_Ops_Approver__c.addError('Sending Sales Ops Manager is incorrect.');
        }
        
        if(!accReassign.Skip_Validations__c && !String.isBlank(accReassign.Receiving_RSM_Approver__c)){
            if(accReassign.Assign_To_User_RSM__c!=null && dataObj.getUserIdToUserMap().containsKey(accReassign.Assign_To_User_RSM__c)){
                User assignToUserRSMUser= dataObj.getUserIdToUserMap().get(accReassign.Assign_To_User_RSM__c);
                if(!accReassign.Receiving_RSM_Approver__c.containsIgnoreCase(assignToUserRSMUser.Name))
                    accReassign.Receiving_RSM_Approver__c.addError('Receiving RSM is incorrect. It should be '+assignToUserRSMUser.Name);
            }
            else
                accReassign.Receiving_RSM_Approver__c.addError('Receiving RSM is incorrect.');
        }
        
        if(!accReassign.Skip_Validations__c && !String.isBlank(accReassign.Giving_RSM_Approver__c)){
            if(accReassign.Account_Owner_RSM__c!=null && dataObj.getUserIdToUserMap().containsKey(accReassign.Account_Owner_RSM__c)){
                User accountOwnerRSMUser = dataObj.getUserIdToUserMap().get(accReassign.Account_Owner_RSM__c);
                if(!accReassign.Giving_RSM_Approver__c.containsIgnoreCase(accountOwnerRSMUser.Name))
                    accReassign.Giving_RSM_Approver__c.addError('Sending RSM is incorrect. It should be '+accountOwnerRSMUser.Name);
            }
            else
                accReassign.Giving_RSM_Approver__c.addError('Sending RSM is incorrect.');
        }
        
        if(accOwner.alias.containsIgnoreCase('netops'))
            accReassign.Action__c = dataObj.getReassignConfigSetting().get('Action_AccountMoves_Approval');
        else if((accReassign.Account_Owner__c + '').contains(dataObj.getReassignConfigSetting().get('ONA_User_Id')) || accOwner.profile.Name.containsIgnoreCase('Account Development') || accReassign.IsPoolUserRequest__c == True)
            accReassign.Action__c = dataObj.getReassignConfigSetting().get('Action_No_Approval');
        else if(tempAcc.Revenue_Account__c || dataObj.getRevenueAccountSet().contains(accReassign.Account__c))
            accReassign.Action__c = dataObj.getReassignConfigSetting().get('Action_Active_Approval');
        else if(accReassign.Account_Status__c == 'Lead'){
            if (dataObj.getAccOwnerStatusMap().containsKey(accReassign.Account_Owner__c) && 
                dataObj.getAccOwnerStatusMap().get(accReassign.Account_Owner__c)){
                if(Userinfo.getUserId() == accReassign.Account_Owner__c)
                    accReassign.Action__c = dataObj.getReassignConfigSetting().get('Action_Active_Approval');
                else
                    accReassign.Action__c = dataObj.getReassignConfigSetting().get('Action_Lead_Approval');
            }
            else
                accReassign.Action__c = dataObj.getReassignConfigSetting().get('Action_Active_Approval');
        }
        else if((accReassign.Account_Status__c + '').contains('Active'))
            accReassign.Action__c = dataObj.getReassignConfigSetting().get('Action_Active_Approval');
        else if((accReassign.Account_Status__c + '').contains('Inactive'))
            accReassign.Action__c = dataObj.getReassignConfigSetting().get('Action_Inactive_Approval');
        else
            accReassign.Action__c = dataObj.getReassignConfigSetting().get('Action_AccountMoves_Approval');
        
        if(accReassign.Action__c == dataObj.getReassignConfigSetting().get('Action_No_Approval')){
            accept(accReassign,dataObj);
            accReassign.RecordTypeId = dataObj.getReassignConfigSetting().get('RecType_No_Approval');
        }
        else if(accReassign.Action__c == dataObj.getReassignConfigSetting().get('Action_Lead_Approval')){
            sendForApproval(accReassign,dataObj.getReassignConfigSetting().get('Status_New_Lead_Approval'));
            accReassign.RecordTypeId = dataObj.getReassignConfigSetting().get('RecType_Lead_Inactive_Approval');
        }
        else if(accReassign.Action__c == dataObj.getReassignConfigSetting().get('Action_Inactive_Approval')){
            sendForApproval(accReassign,dataObj.getReassignConfigSetting().get('Status_New_Inactive_Approval')); 
            accReassign.RecordTypeId = dataObj.getReassignConfigSetting().get('RecType_Lead_Inactive_Approval');
        }
        else if(accReassign.Action__c == dataObj.getReassignConfigSetting().get('Action_Active_Approval')){
            Set<Id> requestUserIdSet = new Set<Id>();
            if (accReassign.Account_Owner_RSM__c!=null)
                requestUserIdSet.add(accReassign.Account_Owner_RSM__c);
            if (accReassign.Assign_To_User__c!=null)
                requestUserIdSet.add(accReassign.Assign_To_User__c);
            if (accReassign.Assign_To_User_RSM__c!=null)
                requestUserIdSet.add(accReassign.Assign_To_User_RSM__c);
            if (accReassign.Requesting_User__c!=null)
                requestUserIdSet.add(accReassign.Requesting_User__c);
            
            if (requestUserIdSet.size()>0){
                List<String> tmpList = new List<String>();
                tmpList.addAll(getUserEmailId(requestUserIdSet,dataObj));
                String tmpStr = String.join(tmpList,',');
                accReassign.RegionalSalesOpsEmailIDs__c =  concatTwoStrings(accReassign.RegionalSalesOpsEmailIDs__c, tmpStr);
            }
            
            sendForApproval(accReassign,dataObj.getReassignConfigSetting().get('Status_New_Active_Approval'));
            accReassign.RecordTypeId = dataObj.getReassignConfigSetting().get('RecType_Active_Approval');
            
            if(accReassign.Effective_Month_Of_Transfer__c == 'Next Month'){
                if(Date.today().month()<12)
                    accReassign.Reassignment_Due_Date__c = Date.newInstance(Date.today().year(), Date.today().addMonths(1).month(), Integer.valueOf(dataObj.getReassignConfigSetting().get('Active_Account_Next_Month_Day'))); //SFDC-2304
                else
                    accReassign.Reassignment_Due_Date__c = Date.newInstance(Date.today().addYears(1).year(), Date.today().addMonths(1).month(), Integer.valueOf(dataObj.getReassignConfigSetting().get('Active_Account_Next_Month_Day'))); //SFDC-2304
            }
        }
        else if(accReassign.Action__c == dataObj.getReassignConfigSetting().get('Action_AccountMoves_Approval')){
            sendForApproval(accReassign,dataObj.getReassignConfigSetting().get('Status_New_Account_Moves_Approval'));
            accReassign.RecordTypeId = dataObj.getReassignConfigSetting().get('RecType_No_Approval'); 
        }
        else if(accReassign.Action__c == dataObj.getReassignConfigSetting().get('Action_Lead_No_Approval')){
            if(accReassign.Effective_Month_Of_Transfer__c == 'Current Month'){
                accept(accReassign,dataObj);
                accReassign.RecordTypeId = dataObj.getReassignConfigSetting().get('RecType_No_Approval'); 
            }
            else if(accReassign.Effective_Month_Of_Transfer__c == 'Next Month'){
                if(Date.today().month()<12)
                    accReassign.Reassignment_Due_Date__c = Date.newInstance(Date.today().year(), Date.today().addMonths(1).month(), Integer.valueOf(dataObj.getReassignConfigSetting().get('Active Account Next Month Day')));
                else
                    accReassign.Reassignment_Due_Date__c = Date.newInstance(Date.today().addYears(1).year(), Date.today().addMonths(1).month(), Integer.valueOf(dataObj.getReassignConfigSetting().get('Active Account Next Month Day')));
                accReassign.RecordTypeId = dataObj.getReassignConfigSetting().get('RecType_No_Approval'); 
                accReassign.Reassign_Status__c = 'Auto Approved';
                accReassign.Status_Message__c = dataObj.getReassignConfigSetting().get('Status_New_Auto_Approval'); 
            }
        }
        if(!accReassign.Reassign__c && 'Approval Pending'.equalsIgnoreCase(accReassign.Reassign_Status__c)){
            String validationError;
            if(String.isBlank(accReassign.Approver_2__c) && String.isBlank(accReassign.Approver_1__c))
                validationError = dataObj.getReassignConfigSetting().get('No_Approver_error');
            else if(String.isBlank(accReassign.Approver_1__c))
                validationError = dataObj.getReassignConfigSetting().get('Approver_1_error');
            else if(String.isBlank(accReassign.Approver_2__c))
                validationError = dataObj.getReassignConfigSetting().get('Approver_2_error');
            
            if(!String.isBlank(validationError))
                accReassign.addError(validationError);
        }
    }
    
    public static AccountReassignmentDataProvider setRelatedOpportunities(AccountReassignmentDataProvider dataObj){
        map<Id,list<Opportunity>> accountToOpenOpportunites = new map<Id,list<Opportunity>>();
        list<Opportunity> oppList = [select AccountId,OwnerId,Dollar_MRR__c,CloseDate,StageName
                                     from Opportunity
                                     where (NOT StageName like 'Closed%')
                                     and AccountId IN : dataObj.getAccountIdSet()
                                     and RecordTypeId IN : dataObj.getReassignOpptyRecTypes()];
        for(Opportunity opp : oppList){
            if (accountToOpenOpportunites.keySet().contains(opp.AccountId)) {
                List<Opportunity> opptyList = accountToOpenOpportunites.get(opp.AccountId);
                opptyList.add(opp);
                accountToOpenOpportunites.put(opp.AccountId,opptyList);
            } else {
                List<Opportunity> opptyList = new List<Opportunity>();
                opptyList.add(opp);
                accountToOpenOpportunites.put(opp.AccountId,opptyList);
            }
        }
        dataObj.setAccountToOpenOpportunites(accountToOpenOpportunites);
        return dataObj;
    }
    
    public static Account_Reassignment__c setThirdLevelApproval(Account_Reassignment__c aR,AccountReassignmentDataProvider dataObj){
        Date dateAfter6MOnths = System.today().addMonths(6);
        Decimal mrrValueSum = 0.00;
        Boolean haveClosedDateWithInSixMonths = false;
        List<Opportunity> accountRelatedOppties = dataObj.getAccountToOpenOpportunites().get(aR.Account__c);
        if(accountRelatedOppties != null && accountRelatedOppties.size() > 0) {
            for(Opportunity op : accountRelatedOppties) {
                if (op.Dollar_MRR__c != null)
                    mrrValueSum += op.Dollar_MRR__c;
                if (op.CloseDate < dateAfter6MOnths)
                    haveClosedDateWithInSixMonths = true;
            }
            if (haveClosedDateWithInSixMonths && mrrValueSum > 15000.00) {
                aR.Third_Level_Mandatory__c = true;
            }
        }
        aR.Skip_Validations__c = false;
        return aR;
    }
    
    public static map<Id,Id> getUserIdToProfileIdMap(set<Id> userIds){
        map<Id,Id> userIdToProfileIdMap = new map<Id,Id>();
        for(User usr: [Select Id, ProfileId From User Where Id IN : userIds])
            userIdToProfileIdMap.put(usr.Id, usr.ProfileId);
        return userIdToProfileIdMap;
    }
    
    public static void reassignAccount(List<Account_Reassignment__c> accReassignmentsToBeDone,AccountReassignmentDataProvider dataObj){
        map<Id,Account> accountsToBeReassigned = new map<Id,Account>();
        list<Account> accListToUpdate = new list<Account>();
        list<AccountTeamMember> atmToInsert = new list<AccountTeamMember>(); 
        map<Id,Account_Reassignment__c> accountIdToReassignmentMap = new map<Id,Account_Reassignment__c>();
        string userRole = null, userAlias = null;
        list<string> userAliasToExclude = dataObj.getGsmSetting().get('ATMOTMInvalidUserAlias').split(',');
        for(Account_Reassignment__c aR : accReassignmentsToBeDone){
        accountIdToReassignmentMap.put(aR.Account__c,aR);
            if(aR.Reassign__c && aR.Assign_To__c==null)
                aR.Reassign__c.addError('Please enter a value in the "Account Reassignment Rule" field.');
            else
                accountsToBeReassigned.put(aR.Account__c,dataObj.getAccIdToAccountMap().get(aR.Account__c));
        }
        Account_Reassignment__c accReassign = null;
        Account_Reassignment_Rule__c rule = null;
        if(accountsToBeReassigned.size()>0){
            for(Account acc : accountsToBeReassigned.values()){
                accReassign = dataObj.getAccIdToReassignmentMap().get(acc.Id);
                rule = dataObj.getRuleIdToRuleMap().get(accReassign.Assign_To__c);
                if(rule==null)
                    accReassign.Assign_To__c.addError('Cannot find the specified rule.');
                else
                {
                    userRole = dataObj.getAssociatedUserIdToRoleMap().get(rule.Associated_User__c);

                    //Reinsertion of AccountTeamMember
                    if(!rule.Remove_Existing_Team_Members__c){
                        for(AccountTeamMember atm : acc.AccountTeamMembers){
                            if(acc.OwnerId != atm.UserId && atm.TeamMemberRole != 'Sales - Primary'){
                                atmToInsert.add(new AccountTeamMember(AccountId = acc.Id,UserId = atm.UserId,TeamMemberRole = atm.TeamMemberRole));
                            }
                        }
                    }

                    acc.Old_Account_Owner__c = acc.OwnerId;
                    acc.OwnerId = rule.Associated_User__c;

                    acc.TERR_HIER_1__c = rule.TERR_HIER_1__c;
                    acc.TERR_HIER_2__c = rule.TERR_HIER_2__c;
                    acc.TERR_HIER_3__c = rule.TERR_HIER_3__c;
                    acc.TERR_HIER_4__c = rule.TERR_HIER_4__c;
                    acc.TERR_HIER_5__c = rule.TERR_HIER_5__c;

                    acc.Anaplan_Sub_Territory__c = rule.SubTerritory__c;
                    if((acc.Old_Account_Owner__c + '').contains(dataObj.getReassignConfigSetting().get('ONA_User_Id'))){
                        acc.Normalized_Territory_Name__c = rule.TERR_HIER_5__c;
                        acc.Normalized_Territory_ID__c = rule.Territory_ID__r.Akam_Territory_Mapping_Id__c;
                    } 
                    else {
                        if(String.isBlank(acc.TERR_HIER_5__c) && String.isNotBlank(rule.TERR_HIER_5__c))
                            acc.Normalized_Territory_Name__c = rule.TERR_HIER_5__c;
                        if(String.isBlank(acc.Akam_Territory_Mapping_Id__c) && String.isNotBlank(rule.Territory_ID__r.Akam_Territory_Mapping_Id__c))
                            acc.Normalized_Territory_ID__c = rule.Territory_ID__r.Akam_Territory_Mapping_Id__c;
                    }

                    acc.Akam_Territory_Mapping_Id__c = rule.Territory_ID__r.AKAM_Territory_Mapping_ID__c;
                    acc.Validation_Override__c = true;
                    accListToUpdate.add(acc);
                    /* ATM Addition */
                    userAlias = dataObj.getUserIdToUserMap().get(rule.Associated_User__c).Alias;
                    if(!userAliasToExclude.contains(userAlias)){
                        if(userRole != null && userRole.indexOf('ECG') > -1)
                            atmToInsert.add(new AccountTeamMember(AccountId=acc.Id,UserId=acc.OwnerId,TeamMemberRole='Services - Primary'));
                        else
                            atmToInsert.add(new AccountTeamMember(AccountId=acc.Id,UserId=acc.OwnerId,TeamMemberRole='Sales - Primary'));
                    }
                    /* ATM Addition */
                }
            }
        }
        
        //SFDC-9288: Capture the backend failures in error file during bulk load
        if(accListToUpdate.size()>0){ 
            Database.SaveResult[] saveRes = Database.Update(accListToUpdate, false);
            for(integer i=0; i<accListToUpdate.size();i++){
                Account erroredAccount = accListToUpdate.get(i);
                Database.SaveResult sr = saveRes.get(i);          
                if (!sr.isSuccess()){
                    String errMessage = '';
                    for(Database.Error err : sr.getErrors()){
                        if(err.getFields().size()>0){
                            errMessage += String.join(err.getFields(), ' AND ') +': ' + err.getMessage() + '\n';
                        }
                        else{
                            errMessage += err.getMessage() + '\n';
                        }
                    }
                    accountIdToReassignmentMap.get(erroredAccount.id).Account__c.addError(errMessage);
                }    
            }
        }
        
        if(atmToInsert.size()>0){
            //L2Q_AaccountTeamMemberTriggerClass.AccountTeamMemberUpdateExclusion=true;
            GsmUtilClass.doDatabaseInsert(atmToInsert,'AccountReassignmentTriggerClass','reassignAccount:atmToInsert',false);
            //L2Q_AaccountTeamMemberTriggerClass.AccountTeamMemberUpdateExclusion=false;
        }
    }
    
    @future
    public static void updateRequestForSalesAccount(set<Id> requestForSalesAccount){
        list<Account> accListToUpdate = new list<Account>();
        for(Id accId : requestForSalesAccount){
            accListToUpdate.add(new Account(Id=accId,Request_for_Sales_Account__c=true,Validation_Override__c=true));
        }
        GsmUtilClass.doDatabaseUpdate(accListToUpdate,'AccountReassignmentTriggerClass','updateRequestForSalesAccount');
    }
    
    @future
    public static void updateNoApprovalRequired(list<Id> noApprovalRequired){
        list<Account_Reassignment__c> arrListToUpdate = new list<Account_Reassignment__c>();
        for(Id arrId : noApprovalRequired){
            arrListToUpdate.add(new Account_Reassignment__c(Id=arrId,Approval_Level__c='Reassignment Approved'));
        }
        GsmUtilClass.doDatabaseUpdate(arrListToUpdate,'AccountReassignmentTriggerClass','updateNoApprovalRequired');
    }
    
    public static Messaging.SingleEmailMessage createSingleEmailWithVFTemplate(Id pReassignmentRequestId, Id pUserId, string pCcEmail, string pToEmail, string pTemplateId) {
        boolean CcEmailflag = false;
        if (pCcEmail != '')
            CcEmailflag = true;
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] ccAddresses = pCcEmail.split(',');
        String[] toAddresses = pToEmail.split(',');
        mail.setWhatId(pReassignmentRequestId);
        mail.setTargetObjectId(pUserId);
        if (CcEmailflag == true)
            mail.setCcAddresses(ccAddresses);
        mail.setToAddresses(toAddresses);
        mail.setTemplateId(pTemplateId);
        mail.setSaveAsActivity(false);
        return mail;
    }
    
    public static void sendActiveAccountReassignmentEmails(List<Account_Reassignment__c> pAccReassign,Id pActiveAccountReassignmentTemplateId,AccountReassignmentDataProvider dataObj) {
        Messaging.SendEmailResult[] sendEmailResultList = new List<Messaging.SendEmailResult > ();
        Messaging.SingleEmailMessage[] sendEmailList = new List<Messaging.SingleEmailMessage > ();
        for(Account_Reassignment__c accReq: pAccReassign) {
            if (accReq.RegionalSalesOpsEmailIDs__c != null && accReq.RegionalSalesOpsEmailIDs__c.length() > 0)
                sendEmailList.add(createSingleEmailWithVFTemplate(accReq.Id, accReq.Account_Owner__c, dataObj.getReassignConfigSetting().get('AccountReassignmentRequestEmailsCCList'), accReq.RegionalSalesOpsEmailIDs__c, pActiveAccountReassignmentTemplateId));
        }
        if(sendEmailList.size() > 0){
            sendEmailResultList = Messaging.sendEmail(sendEmailList, false);
        }
    }
    
    public static void submitForApproval(List<Id> accReassignIds) {
        List<Approval.ProcessSubmitRequest> approvalReqList = new List<Approval.ProcessSubmitRequest>();
        List<Error_Log__c> errorLogs = new List<Error_Log__c>();
        
        for (Id reqId: accReassignIds) {
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setComments('Submitted for approval. Please approve.');
            req.setObjectId(reqId);
            approvalReqList.add(req);
        }
        
        try {
            if (!Test.isRunningTest()) {
                List<Approval.ProcessResult> resultList = Approval.process(approvalReqList);
            }
        } 
        catch(System.DmlException e) {
            for (Integer i = 0; i<e.getNumDml(); i++) {
                if (e.getDmlType(i) == Statuscode.FIELD_CUSTOM_VALIDATION_EXCEPTION || e.getDmlType(i) == Statuscode.FIELD_INTEGRITY_EXCEPTION) {
                    Error_Log__c el = new Error_Log__c(Name='AccountReassignmentApprovalDMLError', Class__c='AccountReassignmentTriggerClass', Error_Message__c=e.getDmlMessage(i));
                    errorLogs.add(el);
                }
            }
        }catch(Exception e) {
            Error_Log__c el = new Error_Log__c(Name='AccountReassignmentApprovalError', Class__c='AccountReassignmentTriggerClass', Error_Message__c=e.getMessage());
            errorLogs.add(el);
        }
        if (errorLogs.size() > 0)
            Database.insert(errorLogs, false);
    }
    
    public static void updateAccountRelatedRecords(list<string> ownerChangeRecordIds){
        list<AccountTeamMember> atmToInsert = new list<AccountTeamMember>();
        List<string> userAliasToExclude = GsmUtilClass.getGSMSettingValue('ATMOTMInvalidUserAlias').split(',');
        string userRole = null;
        list<Account> accList = [select Id, OwnerId, Owner.UserRoleId, Owner.Alias, Owner.UserRole.Name from Account where Id IN : ownerChangeRecordIds and Owner.Alias NOT IN : userAliasToExclude];
        for(Account acc : accList){
            if(acc.Owner.UserRoleId != null)
                userRole = acc.Owner.UserRole.Name;
            if(userRole != null && userRole.indexOf('ECG') > -1)
                atmToInsert.add(new AccountTeamMember(AccountId=acc.Id,UserId=acc.OwnerId,TeamMemberRole='Services - Primary'));
            else
                atmToInsert.add(new AccountTeamMember(AccountId=acc.Id,UserId=acc.OwnerId,TeamMemberRole='Sales - Primary'));
        }
        if(atmToInsert.size()>0)
            GsmUtilClass.doDatabaseInsert(atmToInsert,'AccountCDCEventHandler','reassignAccount:atmToInsert',false);
    }
    
    public static void updateAccountShareForPartnerAdmins(list<string> ownerChangeRecordIds) {
        String partnerAdminProfileName = GsmUtilClass.getGSMSettingValue('AccTrgrCls_PartnerAdminProfile');
        List<AccountShare> partnerAdminAccountShareList = new List<AccountShare> ();
        List<User> partnerAdminUserList = [select Id, Contact.AccountId from User where Profile.Name =: partnerAdminProfileName and isActive = true and Contact.AccountId IN: ownerChangeRecordIds];
        if (partnerAdminUserList != null) {
            for (string accId : ownerChangeRecordIds) {
                for (User partnerAdminUser: partnerAdminUserList) {
                    if (partnerAdminUser.Contact.AccountId == accId) {
                        AccountShare tempAccSh = new AccountShare(AccountAccessLevel = 'Edit', AccountId = accId, UserOrGroupId = partnerAdminUser.Id, OpportunityAccessLevel = 'None');
                        partnerAdminAccountShareList.add(tempAccSh);
                    }
                }
            }
        }
        if(partnerAdminAccountShareList.size() >0){
            GsmUtilClass.doDatabaseUpsert(partnerAdminAccountShareList,'AccountCDCEventHandler','reassignAccount:updateAccountShareForPartnerAdmins',false);
        }
    }
    
    public static void updateOpptysChannelLevel(list<string> channelLevelAccFieldChangeRecIds){
        set<string> gssmKeySet = new set<string>();
        map<string,Id> gssmKeyToChannelHierarchy = new map<string,Id>();
        list<Opportunity> oppList = [select Id, Channel_Hierarchy_Map__c, GSSM_Key__c from Opportunity
                                     where (AccountId IN : channelLevelAccFieldChangeRecIds or Partner_Involved__c IN : channelLevelAccFieldChangeRecIds) and 
                                     (Account.Indirect_Customer__c=true or Account.IsPartnerCustom__c=true or Account.IsPartner=true) 
                                     and Deal_Type__c!=null and Deal_Type__c='Indirect' and Partner_Involved__c!=null and (NOT stageName Like 'Closed%')];
        for(Opportunity opp : oppList){
            gssmKeySet.add(opp.GSSM_Key__c);
            opp.Channel_Hierarchy_Map__c = null;
        }
        for(Channel_Hierarchy_Map__c cH : [select Id,Name from Channel_Hierarchy_Map__c where Name IN : gssmKeySet]){
            gssmKeyToChannelHierarchy.put(cH.Name,cH.Id);
        }
        for(Opportunity opp : oppList){
            if(gssmKeyToChannelHierarchy.containsKey(opp.GSSM_Key__c))
                opp.Channel_Hierarchy_Map__c = gssmKeyToChannelHierarchy.get(opp.GSSM_Key__c);
        }
        if(oppList.size()>0)
            GsmUtilClass.doDatabaseUpdate(oppList,'AccountCDCEventHandler','reassignAccount:updateOpptysChannelLevel');
    }
    
    public static void createAccountReassignmentRequests(list<Account> accList){
        set<Id> accountOwnerIdsSet = new set<Id>();
        map<Id,Id> associatedUserToRuleId = new map<Id,Id>();
        string onaRuleName = GsmUtilClass.getAccountReassignSettingValue('ONA_Reassignment_Rule_Name');
        string onaRuleId = null;
        List<Account_Reassignment__c > accReassignList = new List<Account_Reassignment__c > ();
        
        for(Account acc: accList) {
            accountOwnerIdsSet.add(acc.OwnerId);
        }
        for(Account_Reassignment_Rule__c rule: [select Name, Id, Associated_User__c from Account_Reassignment_Rule__c where (NOT Name LIKE 'OLD_%') and (Associated_User__c in: accountOwnerIdsSet OR Name =: onaRuleName)]){
            if (rule.Name == onaRuleName)
                onaRuleId = rule.Id;
            else
                associatedUserToRuleId.put(rule.Associated_User__c, rule.Id);
        }
        
        for(Account acc : accList){
            Account_Reassignment__c accReassign = getAccReassignmentInstance(acc,associatedUserToRuleId,onaRuleId);
            accReassignList.add(accReassign);
        }
        if(accReassignList.size()>0)
            GsmUtilClass.doDatabaseInsert(accReassignList,'AccountReassignmentTriggerClass','createAccountReassignmentRequests',false);
        
    }
    
    public static Account_Reassignment__c getAccReassignmentInstance(Account acc,map<Id,Id> associatedUserToRuleId,string onaRuleId) {
        Account_Reassignment__c accReassign = new Account_Reassignment__c();
        accReassign.Account__c = acc.Id;
        if(associatedUserToRuleId.containsKey(acc.OwnerId)) {
            accReassign.Assign_To__c = associatedUserToRuleId.get(acc.OwnerId);
        }else if (onaRuleId != null) {
            accReassign.Assign_To__c = onaRuleId;
        }
        accReassign.CurrencyIsoCode = acc.CurrencyIsoCode;
        accReassign.Reassign__c = true;
        return accReassign;
    }
    //SFDC-7770
    public static void updateRevenueCreditOwnerAccount(map<Id,Id> accIdtoOwnerId){
        list<Account> accListToUpdate = new list<Account>();
        system.debug('ACR&&');
        for(Id accId : accIdtoOwnerId.keyset()){
            accListToUpdate.add(new Account(Id=accId, Revenue_Credit_Owner__c = accIdtoOwnerId.get(accId)));
        }
        //system.debug('ACR&&'+arrListToUpdate);
        GsmUtilClass.doDatabaseUpdate(accListToUpdate,'AccountReassignmentTriggerClass','updateRevenueCreditOwnerAccount');
    }
}