// Modified under SFDC-2869 and made this class without sharing
public without sharing class gsm_AccountMergeFlowController {
    @AuraEnabled
    public static String getAccountData(String accountParam,Id accId) {
        String searchKey = accountParam + '%';
        List < Account > returnList = new List < Account > ();
        List < Account > lstOfAccount = [select Id, Name, AKAM_Account_ID__c , Account_Status__c ,
                                         AKAM_Created_Date__c,Owner.Name,BillingCountry  from Account where 
                                         (Name LIKE: searchKey OR AKAM_Account_ID__c LIKE: searchKey) 
                                         AND Id != :accId];
        for (Account acc: lstOfAccount) {
            returnList.add(acc);
        }
        return JSON.serialize(returnList); 
    }
    
    @AuraEnabled
    public static String createAccountMerge(String accountType,List<Id> targetAccIds,Id sourceAccId) {
        try {
            Set<Id> accObjIds = new Set<Id>();
            Set<Id> ownerIds = new Set<Id>();
            Set<Id> accIds = new Set<Id>();
            Id winningAccId = null;
            Account_Merge_Request__c accMergeRec;
            Account winningAccount = new Account();
            Map<Id,Account> accountsMap = new Map<Id,Account>();
            Map<String,Account_Reassignment_Rule__c> accReassignMap = new Map<String,Account_Reassignment_Rule__c>(); //SFDC-5455
            Map<Id,Id> accIdSalesPrimaryMap = new Map<Id,Id>();
            Map<Id,Id> accIdSalesSecondaryMap = new Map<Id,Id>();
            List<Account_Merge_Request__c> accMergeRecList = new List<Account_Merge_Request__c>();
            String returnMessage = 'success:';
            Boolean createMergeRequest = true;
            Id userId = userinfo.getUserId();
            List<String> accMapUserIds = new List<String>();
            String validationErrors = null;
            //AccountReassignmentInterfaceClass accReassignClass = new AccountReassignmentInterfaceClass();

            if(accountType == 'losing') {
                accIds.add(sourceAccId);
                winningAccId = targetAccIds.get(0);
            } else {
                winningAccId = sourceAccId;
                accIds.addAll(targetAccIds);
            }
            system.debug('Losing accIds = '+accIds);
            system.debug('winningAccId = '+winningAccId);
            system.debug('targetAccIds = '+targetAccIds);
            accObjIds.addAll(accIds);
            accObjIds.add(winningAccId);
            system.debug('accObjIds = '+accObjIds);
            
            for(Account_Merge_Request__c accMergeObj : [Select Losing_Account__c,Winning_Account__c 
                                                        from Account_Merge_Request__c
                                                        where (Losing_Account__c in :accObjIds OR 
                                                        Winning_Account__c in :accObjIds) AND 
                                                        Merge_Status__c != 'Rejected' AND Merge_completed__c != true]) {
                if(winningAccId == accMergeObj.Losing_Account__c) {
                    returnMessage = 'Error:Account Merge Request has already been submitted for the losing account. Please modify your selection and try again';
                    createMergeRequest = false;
                } else if(accIds.contains(accMergeObj.Losing_Account__c)) {
                    returnMessage = 'Error: Account Merge Request has already been submitted for one or more losing accounts, please modify your selection and try again'; 
                    createMergeRequest = false;
                } else if(accIds.contains(accMergeObj.Winning_Account__c)) {
                    returnMessage = 'Error: Account Merge Request has already been submitted for this account as a winning account, please modify your selection and try again'; 
                    createMergeRequest = false;
                }
            } 
            if(createMergeRequest) {

                List<AccountTeammember> teammembers = [Select Id, UserId, TeamMemberRole, AccountId  
                                                        From AccountTeamMember 
                                                            where accountId IN :accObjIds 
                                                                and Account.Account_Status__c like '%Active%' 
                                                                and Account.Account_Status__c like '%active%' 
                                                                and TeamMemberRole IN ('Services - Primary', 'Services - Secondary')];

                for (AccountTeammember teamMember:teammembers) {

                    if (teamMember.TeamMemberRole.equals('Services - Primary')) {
                        accIdSalesPrimaryMap.put(teamMember.AccountId, teamMember.UserId);
                    } else {
                        accIdSalesSecondaryMap.put(teamMember.AccountId, teamMember.UserId);
                    }

                }

                accMergeRec = new Account_Merge_Request__c();
                for (Account acc : [Select Id,Name,Type,Owner.Name,Owner.Alias,OwnerId,Account_Status__c, 
                                    Anaplan_Sub_Territory__c,TERR_HIER_1__c,TERR_HIER_2__c,TERR_HIER_3__c,TERR_HIER_4__c,TERR_HIER_5__c,    
                                   Revenue_Account__c from Account where Id in :accObjIds]) {
                    if(acc.Id == winningAccId) {
                        winningAccount = acc;
                    } else {
                        accountsMap.put(acc.Id,acc);
                    }
                    ownerIds.add(acc.OwnerId);
                }
                
                //SFDC-5455
                String uniqueUserWithDGRAT = '';
                for (Account_Reassignment_Rule__c accReassignRec : [Select Associated_User_RSM__c, Division_Formula__c,
                                                                    Geography_Formula__c, Division__c, Region__c, Area__c, 
                                                                    SubTerritory__c, Associated_User_RSM__r.name, Associated_User__c,
                                                                    TERR_HIER_1__c,TERR_HIER_2__c,TERR_HIER_3__c,TERR_HIER_4__c,TERR_HIER_5__c,Sales_Ops_Approver__c
                                                                    from Account_Reassignment_Rule__c where 
                                                                    Associated_User__c in :ownerIds]) {
                    //uniqueUserWithDGRAT = accReassignRec.Associated_User__c + '#' + accReassignRec.Division_Formula__c + '#' + accReassignRec.Geography_Formula__c + '#' + accReassignRec.Division__c + '#' + accReassignRec.Region__c + '#' + accReassignRec.Area__c + '#' + accReassignRec.SubTerritory__c;
                    uniqueUserWithDGRAT = accReassignRec.Associated_User__c + '#' + accReassignRec.TERR_HIER_1__c + '#' + accReassignRec.TERR_HIER_2__c + '#' + accReassignRec.TERR_HIER_3__c + '#' + accReassignRec.TERR_HIER_4__c + '#' + accReassignRec.TERR_HIER_5__c + '#' + accReassignRec.SubTerritory__c;
                    accReassignMap.put(uniqueUserWithDGRAT,accReassignRec);                                                           
                }
                for (Id accId : accountsMap.keySet()) {
                    Account loseAcc = accountsMap.get(accId);
                    system.debug('loseAcc = '+ loseAcc);
                    accMergeRec = new Account_Merge_Request__c();
                    accMergeRec.Losing_Account__c = loseAcc.Id;
                    accMergeRec.Winning_Account__c  = winningAccount.Id;
                    accMergeRec.Losing_Account__c = loseAcc.Id;
                    accMergeRec.Losing_Account_Name__c = loseAcc.Name;
                    accMergeRec.Winning_Account_Name__c = winningAccount.Name;
                    accMergeRec.Winning_Account_Owner__c = winningAccount.OwnerId;
                    accMergeRec.Losing_Account_Owner__c = loseAcc.OwnerId;
                    accMergeRec.Winning_Account_Owner_Name__c = winningAccount.Owner.Name;
                    accMergeRec.Losing_Account_Owner_Name__c = loseAcc.Owner.Name;
                    accMergeRec.NeedApproval__c = true;
                    
                    /*If services primary is null and services secondary has value, update 
                     * services secondary to both the values
                    */
                    if (accIdSalesPrimaryMap.get(loseAcc.Id) == null &&
                        accIdSalesSecondaryMap.get(loseAcc.Id) != null) {
                        accMergeRec.Sales_Primary__c = accIdSalesSecondaryMap.get(loseAcc.Id);
                        accMergeRec.Sales_Secondary__c = accIdSalesSecondaryMap.get(loseAcc.Id);
                    } else if (accIdSalesSecondaryMap.get(loseAcc.Id) == null &&
                               accIdSalesPrimaryMap.get(loseAcc.Id) != null) {
                        accMergeRec.Sales_Primary__c = accIdSalesPrimaryMap.get(loseAcc.Id);
                        accMergeRec.Sales_Secondary__c = accIdSalesPrimaryMap.get(loseAcc.Id);
                    } else {
                        accMergeRec.Sales_Primary__c = accIdSalesPrimaryMap.get(loseAcc.Id);
                        accMergeRec.Sales_Secondary__c = accIdSalesSecondaryMap.get(loseAcc.Id);
                    }

                    //SFDC-5455
                    String winningAccOwnerWithDGRAT = winningAccount.OwnerId + '#' + winningAccount.TERR_HIER_1__c + '#' + winningAccount.TERR_HIER_2__c + '#' + winningAccount.TERR_HIER_3__c + '#' + winningAccount.TERR_HIER_4__c + '#' + winningAccount.TERR_HIER_5__c + '#' + winningAccount.Anaplan_Sub_Territory__c;
                    String losingAccOwnerWithDGRAT = loseAcc.OwnerId + '#' + loseAcc.TERR_HIER_1__c + '#' + loseAcc.TERR_HIER_2__c + '#' + loseAcc.TERR_HIER_3__c + '#' + loseAcc.TERR_HIER_4__c + '#' + loseAcc.TERR_HIER_5__c + '#' + loseAcc.Anaplan_Sub_Territory__c;
                    
                    if(accReassignMap.size() > 0) {
                        if(accReassignMap.containsKey(winningAccOwnerWithDGRAT))
                            accMergeRec.Winning_Account_RSM__c = accReassignMap.get(winningAccOwnerWithDGRAT).Associated_User_RSM__c; //SFDC-5455

                        if(validateLosingAccountOwner(loseAcc) == true)
                        {
                            // SFDC-4219 set RSM approver as current user and skip level1 and 2 approvals
                            accMergeRec.Losing_Account_RSM__c = Userinfo.getuserid(); 
                            accMergeRec.Bypass_level1_approval__c  = true;
                            accMergeRec.Bypass_level2_approval__c  = true;       
                        }
                        else
                        {
                            if(accReassignMap.containsKey(losingAccOwnerWithDGRAT))
                                accMergeRec.Losing_Account_RSM__c = accReassignMap.get(losingAccOwnerWithDGRAT).Associated_User_RSM__c; //SFDC-5455
                        }
                       // accMergeRec.Losing_Account_Division__c = loseAcc.Division_Formula__c; //SFDC-5455
                       // accMergeRec.Winning_Account_Division__c = winningAccount.Division_Formula__c; //SFDC-5455
                    }
                    accMergeRec.Merge_Status__c = 'Approval Pending';
                    if((winningAccount.OwnerId == userId && winningAccount.Account_Status__c == 'Lead') && 
                       (loseAcc.OwnerId == userId && loseAcc.Account_Status__c == 'Lead')) {
                        accMergeRec.NeedApproval__c = false;
                        accMergeRec.Merge_Status__c = 'Approved';
                    } else {
                        accMergeRec.Number_of_Approvals__c = numberOfApprovalsRequired(accMergeRec,loseAcc.Account_Status__c,loseAcc.Revenue_Account__c);
                    }
                  
                    // Populate sales ops user 
                    if(accReassignMap.size() > 0 && accReassignMap.containsKey(losingAccOwnerWithDGRAT)){
                    
                        accMergeRec.Sales_Ops_User__c = accReassignMap.get(losingAccOwnerWithDGRAT).Sales_Ops_Approver__c;
                    
                    }
                    
                    // SFDC-6590 Populate Merge Account Status Type 
                    // Losing Account Type-> Winning Account type ; Ex: Lead to Active
                    String loseType = loseAcc.Type != 'Lead'?(loseAcc.Type.contains('- Active')?'Active':'Inactive'):'Lead';
                    String winType = winningAccount.Type != 'Lead'?(winningAccount.Type.contains('- Active')?'Active':'Inactive'):'Lead';
                    accMergeRec.Merge_Account_Status_Type__c = loseType +' to '+winType;
                    accMergeRec.Org_URL__c = System.URL.getSalesforceBaseURL().toExternalForm();
                    
                    accMergeRecList.add(accMergeRec);
                }
            }
            if(accMergeRecList.size() > 0) {
                validationErrors = checkValidationErros(accMergeRecList);
                if(validationErrors == null) {
                    insert accMergeRecList;    
                    returnMessage = returnMessage + accMergeRecList[0].Id;
                } else {
                    returnMessage = validationErrors;   
                }
            }
            return returnMessage;
        } catch (exception ex) {
            String errorMessage = null;
            errorMessage = ex.getMessage();
            if(errorMessage.contains('INSUFFICIENT')) {
                errorMessage = 'You do not have sufficient access to perform this activity. Please contact your local sales operations team';
            }
            return errorMessage;
        }
    }

    
    // SFDC-4219 set RSM approver as current user for this use-case
    private static boolean validateLosingAccountOwner(Account acc)
    {
        if( acc.Owner.Alias == 'ONA' ||  acc.Owner.Alias == 'SPOOL' )
        {
            return true;
        }
        else
        {
            return false;
        }
    }
    
    @AuraEnabled
    public static String checkAccountStatus(Id losingAccountId) {
        try {
            List<Merge_Contract_Header__c> contractRecs = new List<Merge_Contract_Header__c>();
            String accountStatus = 'Inactive'; 
            contractRecs = [Select Id,Effective_End_Date__c,Active__c from Merge_Contract_Header__c where 
                            Account_Name__c = :losingAccountId];
            if(contractRecs.size() > 0) {
                for(Merge_Contract_Header__c contObj : contractRecs){
                    if(contObj.Active__c && (contObj.Effective_End_Date__c > system.today() || 
                                             contObj.Effective_End_Date__c == system.today())) {
                        accountStatus = 'active';                                               
                    }                                            
                }
            } else 
                accountStatus = 'Inactive';    
            return accountStatus;
        } catch(exception ex) {
            return ex.getMessage();
        }
    }
    
    public static Integer numberOfApprovalsRequired(Account_Merge_Request__c accMergeReq,String accStatus, Boolean isRevenueAccount) {
        // Commenting as part of SFDC-2869 and always return 3
       /* if(!accMergeReq.Losing_Account_Owner_Name__c.contains('Owner Not Assigned')) {
            if(accMergeReq.Losing_Account_Division__c != accMergeReq.Winning_Account_Division__c ||
               accStatus.contains('Active') || accStatus.contains('active')) {
                if(isRevenueAccount) {
                    return 3;
                } else {
                    return 2;
                }
            } else {
                return 1;
            }
        } else {
            return 0;
        } */
        return 3;
    }

    public static String checkValidationErros(List<Account_Merge_Request__c> accMergeReqs) {
        String validationMessage = null;
        Set<Id> userIds = new Set<Id>();
        Set<Id> inactiveUserIds = new Set<Id>();
        List<String> accountNames = new List<String>();
        List<Account_Merge_Request__c> accMergeReqsWithApproval = new List<Account_Merge_Request__c>();
        for (Account_Merge_Request__c accMergeObj : accMergeReqs) {
            
                userIds.add(accMergeObj.Losing_Account_Owner__c);
                userIds.add(accMergeObj.Losing_Account_RSM__c);
                
                accMergeReqsWithApproval.add(accMergeObj);   
           
        }
        if(userIds.size() > 0) {
            for(User userObj: [Select Id,IsActive from user where Id in :userIds AND IsActive=false]) {
                inactiveUserIds.add(userObj.Id);    
            }
        }
        //SFDC-2869 Checking userIds instead of inactiveUserIds and added null check for below if conditions
        if(userIds.size() > 0) {
            for(Account_Merge_Request__c accMergeRec : accMergeReqsWithApproval) {
               
                    if(accMergeRec.Losing_Account_Owner__c == null || inactiveUserIds.contains(accMergeRec.Losing_Account_Owner__c) ||
                       accMergeRec.Losing_Account_RSM__c == null || inactiveUserIds.contains(accMergeRec.Losing_Account_RSM__c)) {
                        accountNames.add(accMergeRec.Losing_Account_Name__c);    
                    }    
                
            }
        }
        if(accountNames.size() > 0) {
            validationMessage = 'Unable to submit merge request: Losing Account Owner '+
                                'or Losing Account RSM for the following '+
                                'losing account(s) - '+ string.join(accountNames,',') + ' - is blank or inactive.'+
                                ' Kindly contact Globalsalesops@akamai.com' ;   
        }
        
        //SFDC-6590 Validation message for Active/Inactive to Lead merge
        if( validationMessage == null){

            List<String> accountNamesWithError = new List<String>() ;
            for(Account_Merge_Request__c amr : accMergeReqs){
                if(amr.Merge_Account_Status_Type__c == 'Active to Lead' || amr.Merge_Account_Status_Type__c == 'Inactive to Lead'){
                    accountNamesWithError.add(amr.Losing_Account_Name__c);
                }
            }
            if(accountNamesWithError.size() > 0) {
            validationMessage = 'Unable to submit merge request: Active/Inactive Losing accounts can not be merged into Lead Winning account'+
                                ' for the following '+
                                'losing account(s) - '+ string.join(accountNamesWithError,',');
        }
            
        }
        
        return validationMessage;
    }
    
    @AuraEnabled
    public static String checkLosingAccountsStatus(List<Id> losingAccountIds) {
        String activeAccountsMessage = 'inactive';
        Map<Id,String> accountIdNameMap = new Map<Id,String>();
        List<String> accNames = new List<String>();
        for(Merge_Contract_Header__c contObj : [Select Id,Effective_End_Date__c,Active__c,
                                                Account_Name__r.Name,Account_Name__c 
                                                from Merge_Contract_Header__c where 
                                                Account_Name__c in :losingAccountIds]){
            if(contObj.Active__c && (contObj.Effective_End_Date__c > system.today() || 
                                     contObj.Effective_End_Date__c == system.today())) {
                accountIdNameMap.put(contObj.Account_Name__c, contObj.Account_Name__r.Name);                                               
            }            
        }

        if(accountIdNameMap.size() > 0) {
            for(String accName : accountIdNameMap.values()) {
                accNames.add(accName);    
            }
            activeAccountsMessage = 'These accounts - '+ string.join(accNames,',') +
                                    ' - have active contract(s) , are you sure you want to proceed?';
        } 
        return activeAccountsMessage;   
    }
    
    @AuraEnabled
    public static Account getAccountDetail(Id accountId) {
        return [Select Id,Name from Account where Id = :accountId];
    } 
    
    @AuraEnabled
    public static String getUserTheme() {
        String theme =  UserInfo.getUiThemeDisplayed();
        return theme;
    }
    
    //SFDC-6590 Ability to have a Merge Request Auto Approved
    public static void evaluateAutoApproval(List<Account_Merge_Request__c> accMergeRequestList){
        List<Id> accountList = new List<Id>();
        for(Account_Merge_Request__c re : accMergeRequestList){
            accountList.add(re.Losing_Account__c);
            accountList.add(re.Winning_Account__c);
        }
        Map<Id,Boolean> accountToOwnerMap = new Map<Id,Boolean>();
        
        for(Account a: [select id,Owner.alias from Account where id in :accountList]){
            accountToOwnerMap.put(a.id, validateLosingAccountOwner(a));
        }
        
        
        Id profileId=userinfo.getProfileId();
        String profileName=[Select Id,Name from Profile where Id=:profileId].Name;
        for(Account_Merge_Request__c re : accMergeRequestList){
            boolean businessOpsAutoApprove = ((profileName == 'Business Operations') && 
                                              (re.Merge_Account_Status_Type__c == 'Lead to Lead' || 
                                               re.Merge_Account_Status_Type__c == 'Lead to Active' ||
                                               re.Merge_Account_Status_Type__c == 'Lead to Inactive'));
            
            boolean ownerIsSPOOLOrONA = (accountToOwnerMap.get(re.Losing_Account__c) && accountToOwnerMap.get(re.Winning_Account__c));
            boolean losingOwnerCondition = (profileName != 'Business Operations' && 
                                            re.Merge_Account_Status_Type__c == 'Lead to Lead' && 
                                            (Userinfo.getUserId() == re.Losing_Account_Owner__c || 
                                             Userinfo.getUserId() == re.Losing_Account_RSM__c));
            boolean winningOwnerCondition = (profileName != 'Business Operations' &&
                                                           (re.Merge_Account_Status_Type__c == 'Lead to Active' || 
                                                            re.Merge_Account_Status_Type__c == 'Lead to Inactive') &&
                                                           (Userinfo.getUserId() == re.Losing_Account_Owner__c || 
                                                            Userinfo.getUserId() == re.Losing_Account_RSM__c)&&
                                                           (Userinfo.getUserId() == re.Winning_Account_Owner__c ||
                                                            Userinfo.getUserId() == re.Winning_Account_RSM__c));
            if(businessOpsAutoApprove || 
               ownerIsSPOOLOrONA || 
               losingOwnerCondition||
               winningOwnerCondition){              
                re.Auto_Approved__c = true;
               }else{
                   re.Auto_Approved__c = false;
               }
        }
    }
    
    

    public static void autoPopulateMergeRequestFields(List<Account_Merge_Request__c> accMergeRequestList, Set<Id> losingAccountIds, Set<Id> winningAccountIds, Set<Id> salesOpsUserId)
    {
        Set<Id> combinedAccountIds = new Set<Id>();
        Set<Id> existingLosingAccountIds = new Set<Id>();
        Set<Id> existingWinningAccountIds = new Set<Id>();
        Map<Id,Account> accountIdToAccountMap = new Map<Id,Account>();
        Set<Id> accountOwnerIds = new Set<Id>();

        combinedAccountIds.addAll(losingAccountIds);
        combinedAccountIds.addAll(winningAccountIds);

        //SFDC-5455
        for(Account a : [select Id, AKAM_Account_ID__c, Name, Account_Name__c, OwnerId, Owner.name, Revenue_Account__c, Account_Status__c, Geography_Formula__c, Division_Formula__c, Division__c, Area__c, Anaplan_Sub_Territory__c, Region__c,TERR_HIER_1__c,TERR_HIER_2__c,TERR_HIER_3__c,TERR_HIER_4__c,TERR_HIER_5__c
                          from Account where id in :combinedAccountIds])
        {
            accountIdToAccountMap.put(a.Id,a);
            accountOwnerIds.add(a.OwnerId);
        }
       
        //SFDC-5455
        Map<String,Account_Reassignment_Rule__c> accReassignMap = new Map<String,Account_Reassignment_Rule__c>();
        String uniqueUserWithDGRAT = '';
        for (Account_Reassignment_Rule__c accReassignRec : [Select Associated_User_RSM__c,Division_Formula__c,
                                                                    Geography_Formula__c, Division__c, Region__c, Area__c,
                                                                    SubTerritory__c, Associated_User_RSM__r.name,Associated_User__c,
                                                                    TERR_HIER_1__c,TERR_HIER_2__c,TERR_HIER_3__c,TERR_HIER_4__c,TERR_HIER_5__c
                                                                    from Account_Reassignment_Rule__c where 
                                                                    Associated_User__c in :accountOwnerIds]) 
        {
            //uniqueUserWithDGRAT = accReassignRec.Associated_User__c + '#' + accReassignRec.Division_Formula__c + '#' + accReassignRec.Geography_Formula__c + '#' + accReassignRec.Division__c + '#' + accReassignRec.Region__c + '#' + accReassignRec.Area__c + '#' + accReassignRec.SubTerritory__c;
            uniqueUserWithDGRAT = accReassignRec.Associated_User__c + '#' + accReassignRec.TERR_HIER_1__c + '#' + accReassignRec.TERR_HIER_2__c + '#' + accReassignRec.TERR_HIER_3__c + '#' + accReassignRec.TERR_HIER_4__c + '#' + accReassignRec.TERR_HIER_5__c + '#' + accReassignRec.SubTerritory__c;

            accReassignMap.put(uniqueUserWithDGRAT,accReassignRec);                                                            
        }

        Map<Id, String> salesOpsIdToUserName = new Map<Id, String>();
        for(User u : [select Id,Name from User where id in : salesOpsUserId])
        {
            salesOpsIdToUserName.put(u.Id,u.Name);
        }

        for(Account_Merge_Request__c accMergeObj : [Select Losing_Account__c,Winning_Account__c 
                                                        from Account_Merge_Request__c
                                                        where (Losing_Account__c in :combinedAccountIds OR 
                                                        Winning_Account__c in :combinedAccountIds) AND 
                                                        Merge_Status__c != 'Rejected' AND Merge_completed__c != true]) {
            existingLosingAccountIds.add(accMergeObj.Losing_Account__c);
            existingWinningAccountIds.add(accMergeObj.Winning_Account__c);
        }

        //SFDC-5455
        String winningAccOwnerWithDGRAT = '';
        String losingAccOwnerWithDGRAT = '';
        for(Account_Merge_Request__c newRequest : accMergeRequestList)
        {
            //SFDC-5455
           // winningAccOwnerWithDGRAT = accountIdToAccountMap.get(newRequest.Winning_Account__c).OwnerId + '#' + accountIdToAccountMap.get(newRequest.Winning_Account__c).Division_Formula__c + '#' + accountIdToAccountMap.get(newRequest.Winning_Account__c).Geography_Formula__c + '#' + accountIdToAccountMap.get(newRequest.Winning_Account__c).Division__c + '#' + accountIdToAccountMap.get(newRequest.Winning_Account__c).Region__c + '#' + accountIdToAccountMap.get(newRequest.Winning_Account__c).Area__c + '#' + accountIdToAccountMap.get(newRequest.Winning_Account__c).Anaplan_Sub_Territory__c;
           // losingAccOwnerWithDGRAT = accountIdToAccountMap.get(newRequest.Losing_Account__c).OwnerId + '#' + accountIdToAccountMap.get(newRequest.Losing_Account__c).Division_Formula__c + '#' + accountIdToAccountMap.get(newRequest.Losing_Account__c).Geography_Formula__c + '#' + accountIdToAccountMap.get(newRequest.Losing_Account__c).Division__c + '#' + accountIdToAccountMap.get(newRequest.Losing_Account__c).Region__c + '#' + accountIdToAccountMap.get(newRequest.Losing_Account__c).Area__c + '#' + accountIdToAccountMap.get(newRequest.Losing_Account__c).Anaplan_Sub_Territory__c;
            winningAccOwnerWithDGRAT = accountIdToAccountMap.get(newRequest.Winning_Account__c).OwnerId + '#' + accountIdToAccountMap.get(newRequest.Winning_Account__c).TERR_HIER_1__c + '#' + accountIdToAccountMap.get(newRequest.Winning_Account__c).TERR_HIER_2__c + '#' + accountIdToAccountMap.get(newRequest.Winning_Account__c).TERR_HIER_3__c + '#' + accountIdToAccountMap.get(newRequest.Winning_Account__c).TERR_HIER_4__c + '#' + accountIdToAccountMap.get(newRequest.Winning_Account__c).TERR_HIER_5__c + '#' + accountIdToAccountMap.get(newRequest.Winning_Account__c).Anaplan_Sub_Territory__c;
          losingAccOwnerWithDGRAT = accountIdToAccountMap.get(newRequest.Losing_Account__c).OwnerId + '#' + accountIdToAccountMap.get(newRequest.Losing_Account__c).TERR_HIER_1__c + '#' + accountIdToAccountMap.get(newRequest.Losing_Account__c).TERR_HIER_2__c + '#' + accountIdToAccountMap.get(newRequest.Losing_Account__c).TERR_HIER_3__c+ '#' + accountIdToAccountMap.get(newRequest.Losing_Account__c).TERR_HIER_4__c + '#' + accountIdToAccountMap.get(newRequest.Losing_Account__c).TERR_HIER_5__c + '#' + accountIdToAccountMap.get(newRequest.Losing_Account__c).Anaplan_Sub_Territory__c;

            if(existingLosingAccountIds.contains(newRequest.Winning_Account__c)) {
                newRequest.addError('Error:Account Merge Request has already been submitted for the losing account. Please modify your selection and try again');
            } else if(existingLosingAccountIds.contains(newRequest.Losing_Account__c)) {
                newRequest.addError('Error: Account Merge Request has already been submitted for one or more losing accounts, please modify your selection and try again'); 
            }else if(existingWinningAccountIds.contains(newRequest.Losing_Account__c)) {
                newRequest.addError('Error: Account Merge Request has already been submitted for this account as a winning account, please modify your selection and try again'); 
            } else if(accReassignMap.size() < 1) {
                newRequest.addError('Error: Both Losing Account and Winning Account do not have Account Reassignment Rules'); 
            } else if(accReassignMap.size() > 0 && 
                      (accReassignMap.get(winningAccOwnerWithDGRAT) == null
                      || accReassignMap.get(losingAccOwnerWithDGRAT) == null)) {
                newRequest.addError('Error: Losing Account or Winning Account does not have Account Reassignment Rule');

            } else {
                // Default fields
                newRequest.Approval_Date__c = Date.today();
                newRequest.Approval_Level__c = 'Merge Approved';
                newRequest.Merge_Status__c = 'Approved';
                
                // Losing Account fields
                newRequest.Losing_Account_AKAM_ID_Text__c = accountIdToAccountMap.get(newRequest.Losing_Account__c).AKAM_Account_ID__c;
                newRequest.Losing_Account_Name__c = accountIdToAccountMap.get(newRequest.Losing_Account__c).Name ;
                newRequest.Losing_Account_Owner_Name__c  = accountIdToAccountMap.get(newRequest.Losing_Account__c).Owner.name;
                newRequest.Losing_Account_Owner_Approver__c  = accountIdToAccountMap.get(newRequest.Losing_Account__c).Owner.name;
                newRequest.Losing_Account_Status_Text__c = accountIdToAccountMap.get(newRequest.Losing_Account__c).Account_Status__c ;
                newRequest.Losing_Account_Must_Map_Text__c = String.valueof(accountIdToAccountMap.get(newRequest.Losing_Account__c).Revenue_Account__c);
                            
                //SFDC-5455            
                if(accReassignMap.size() > 0) 
                {
                    if(accReassignMap.containsKey(losingAccOwnerWithDGRAT)){
                        newRequest.Losing_Account_RSM_Approver__c = accReassignMap.get(losingAccOwnerWithDGRAT).Associated_User_RSM__r.name;
                        newRequest.Losing_Account_RSM__c = accReassignMap.get(losingAccOwnerWithDGRAT).Associated_User_RSM__c;
                    }
                    if(accReassignMap.containsKey(winningAccOwnerWithDGRAT)){
                        newRequest.Winning_Account_RSM__c  = accReassignMap.get(winningAccOwnerWithDGRAT).Associated_User_RSM__c;
                    }
                }
                
                //Winning Account fields
                newRequest.Winning_Account_AKAM_ID_Text__c = accountIdToAccountMap.get(newRequest.Winning_Account__c).AKAM_Account_ID__c;
                newRequest.Winning_Account_Name__c = accountIdToAccountMap.get(newRequest.Winning_Account__c).Name ;
                newRequest.Winning_Account_Owner_Name__c  = accountIdToAccountMap.get(newRequest.Winning_Account__c).Owner.name;
                newRequest.Winning_Account_Owner__c  = accountIdToAccountMap.get(newRequest.Winning_Account__c).OwnerId ;
                //SFDC-5455
               // newRequest.Winning_Account_Division__c = accountIdToAccountMap.get(newRequest.Winning_Account__c).Division_Formula__c;
                //newRequest.Losing_Account_Division__c = accountIdToAccountMap.get(newRequest.Losing_Account__c).Division_Formula__c;
                
                // Sales Ops Fields
                if(salesOpsIdToUserName.get(newRequest.Sales_Ops_User__c) != null)
                {
                    newRequest.Sales_Ops_Approver__c = salesOpsIdToUserName.get(newRequest.Sales_Ops_User__c);
                }
            }
        }
    }

    @AuraEnabled
    public static String getAccountRequestsData(Id accId) {
        List < Account_Merge_Request__c > returnList = new List < Account_Merge_Request__c > ();
        List < Account_Merge_Request__c > lstOfAccountMergeReqs = [select Id, Losing_Account_Name__c, 
                                                                   Winning_Account_Name__c,
                                                                   Name, CreatedDate, Merge_Status__c
                                                                   from Account_Merge_Request__c where 
                                                                   Winning_Account__c = :accId order by 
                                                                   CreatedDate desc];

        for (Account_Merge_Request__c accMergReq: lstOfAccountMergeReqs) {
            returnList.add(accMergReq);
        }
        system.debug('List of Accs = '+returnList);
        system.debug('Accs = '+JSON.serialize(returnList));
        return JSON.serialize(returnList); 
    }
}