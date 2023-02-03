/**
    History

        --Developer         --Date          --Description 
        Chandra Lohani                      Created this Class
        Shivam              29/01/15          CR 2898147 Account Moves Mails
                                                ->  Generalize the logic of sending mails on account moves and comment the hardcode values
        Shivam              24/02/15          CR 2915418 Account Moves mail: Americas Geo - Area Condition
        Hitesh              04/11/2015        CR 3213751 - Create Inside Sales Account Pool ( Shark Tank Pool )
        Rahul               3/5/2016             Changed the query from for loop to LIst<Account>
        Nagaraj Desai       19 Jan 2018       MOB-360 Changes: a) Added a constructor -> public AccountReassignmentInterfaceClass(Id accountID),
                                                               b) Changed String id in constructor AccountReassignmentInterfaceClass() to global String id in order remove ApexPages Reference from  queries.
                                                               c) Changed ApexPages addMessage to JSON conditionally while accessing from SF1
 */

global class AccountReassignmentInterfaceClass implements AccountReassignmentInterface 
{

    //Instance variables for AccountReassignment2_Controller
    public User accOwner {get; set;}
    public Account account {get; set;}
    public Account_Reassignment__c accReassign {get; set;}
    public Boolean isAccountActive {get; set;}
    public Boolean isAccountOwnerInactive {get; set;}
    public Boolean initializedFlag {get; set;}
    public Boolean isRevenueAccount {get; set;}
    public Id pendingAccountReassignmentId {get; set;}
    public Boolean isAccountIdPresent {get; set;}
    public Boolean isNetOpsOwnedAccount {get; set;}
    public Boolean isAdminProfile {get; set;}
    public Boolean isNotInternalRevenueAccount {get; set;}
    Set<Id> groupMemberUserIdSet;
    public static boolean isFromBatch = false;

    private String id; // MOB-360 changes
    public String sf1ReturnMessageJSON {get; set;} // MOB-360 changes

    private AccountReassignmentDataClass accReassignDataObject;


    public AccountReassignmentInterfaceClass()
    {
        initializeAccReassignDataObject('VFPage');
        //accReassignDataObject.setFromWhere();
        id = ApexPages.currentPage().getParameters().get('id'); // MOB-360 changes

        if(id == null || (id !=null && id==''))
        {
            isAccountIdPresent=false;
            showErrorAndDiscontinue(accReassignDataObject.getAccountIdNotPresentErrorMessage());
        }
        else
        {
            isAccountIdPresent=true;
            doInitialize();
        }

    }

    public class ResultSetCustom { // MOB-360 changes : addedd a custom class
        @AuraEnabled public Boolean errorOccured {get; set;}
        @AuraEnabled public String returnMessage {get; set;}

        public ResultSetCustom(){
        }
        public ResultSetCustom(Boolean errorOccured, String returnMessage) {
            this.errorOccured = errorOccured;
            this.returnMessage = returnMessage;
        }
    }

    public AccountReassignmentInterfaceClass(Id accountID) { // MOB-360 changes : added a constructor
        initializeAccReassignDataObject('SF1');
        sf1ReturnMessageJSON = JSON.serialize( new ResultSetCustom(true, 'Unknown') );
        id = accountID;

        if(id == null || (id != null && id == '')) {
            isAccountIdPresent=false;
            sf1ReturnMessageJSON = JSON.serialize(new ResultSetCustom(true, accReassignDataObject.getAccountIdNotPresentErrorMessage()));
        }
        else {
            isAccountIdPresent=true;
            doInitialize();
        }
    }

    public AccountReassignmentInterfaceClass(List<Account> accounts)
    {

        initializeAccReassignDataObject(accounts,'AccountTrigger');
        doInitialize();
    }

    public AccountReassignmentInterfaceClass(Account_Reassignment__c[] accReassignmentList,Boolean isInsert,Boolean isBefore,Map<Id,Account_Reassignment__c> oldAccReassignmentMap)
    {
        initializeAccReassignDataObject(accReassignmentList,'AccountReassignmentTrigger',isInsert,isBefore,oldAccReassignmentMap);
        doInitialize();
    }
    // custom constructor to set up data for AccountTriggerClass.sendEmailToUpdateAnaplanSubTerritory
    public AccountReassignmentInterfaceClass(List<Account> accounts,Boolean forAnaplanSubTerritoryEmail){

        if(forAnaplanSubTerritoryEmail) {
            initializeAccReassignDataObject(accounts,'AccountTrigger');
            doInitialize();
            initRegionalSalesOps();
            initUserMap(groupMemberUserIdSet);
        }

    }
    
    // SFDC-5465 custom constructor to set up Sales Ops related data
    public AccountReassignmentInterfaceClass(Boolean initalizeRegionalForSalesOps)
    {
        if(initalizeRegionalForSalesOps)
        {
            initializeAccReassignDataObject('GSM_SendEmailToSalesOpsBatchClass');
            initRegionalSalesOps();
            initUserMap(groupMemberUserIdSet);
        }
    }

    public AccountReassignmentDataClass getAccReassignDataObject()
    {
        return accReassignDataObject;
    }

    public void initializeAccReassignDataObject(String fromWhere)
    {
        if(accReassignDataObject== null)
        {
            this.accReassignDataObject=new AccountReassignmentDataClass();
        }
        accReassignDataObject.setFromWhere(fromWhere);
    }
    public void initializeAccReassignDataObject(List<Account> accounts, String fromWhere)
    {
        initializeAccReassignDataObject(fromWhere);
        accReassignDataObject.setAccounts(accounts);
    }
    public void initializeAccReassignDataObject(List<Account_Reassignment__c> accReassignmentList,String fromWhere,Boolean isInsert,Boolean isBefore,Map<Id,Account_Reassignment__c> oldAccReassignmentMap)
    {
        initializeAccReassignDataObject(fromWhere);
        accReassignDataObject.setAccReassignmentList(accReassignmentList);
        accReassignDataObject.setIsBefore(isBefore);
        accReassignDataObject.setIsInsert(isInsert);
        accReassignDataObject.setOldAccReassignmentMap(oldAccReassignmentMap);
    }
    public static void showErrorAndDiscontinue(String pErrorMessage)
    {

        ApexPages.Message errMsg = new ApexPages.Message(ApexPages.Severity.ERROR, pErrorMessage);
        ApexPages.addMessage(errMsg);

    }
    
    public PageReference cancel()
    {
        return new PageReference('/'+account.Id);
    }
    public PageReference save()
    {
        try
        {
            insert accReassign;
        }
        catch(DMLException e)
        {
            for (Integer i = 0; i < e.getNumDml(); i++)
            {
                if(e.getDmlType(i) == Statuscode.FIELD_CUSTOM_VALIDATION_EXCEPTION
                        || e.getDmlType(i)==StatusCode.FIELD_FILTER_VALIDATION_EXCEPTION
                        || e.getDmlType(i)==StatusCode.CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY)
                {
                    String errMessage=e.getDmlMessage(i);
                    //String error=GSM_Custom_Settings__c.getInstance('AccountReassignment#ErrorToCompare').value__C; //SFDC-2304
                    String error=GsmUtilClass.getGSMSettingValue('AccountReassignment_ErrorToCompare'); //SFDC-2304
                    if(errMessage.contains(error))
                    {
                        //errMessage='.Error : '+GSM_Custom_Settings__c.getInstance('AccountReassignment#ErrorToShow').value__C; //SFDC-2304
                        errMessage='.Error : '+GsmUtilClass.getGSMSettingValue('AccountReassignment_ErrorToShow'); //SFDC-2304
                    }
                    if(accReassignDataObject.getFromWhere().equals('SF1')) { // MOB-360 changes
                        sf1ReturnMessageJSON = JSON.serialize(new ResultSetCustom(true, errMessage));
                    }
                    else {
                        ApexPages.Message errMsg = new ApexPages.Message(ApexPages.Severity.ERROR, errMessage);
                        ApexPages.addMessage(errMsg);
                    }
                }
                else
                    throw e;
            }
            return null;
        }
        sf1ReturnMessageJSON = JSON.serialize(new ResultSetCustom(false, 'Success')); // MOB-360 changes
        return new PageReference('/'+accReassign.Id);
    }

    //SFDC-4547-4
    public static void createAccountReassignmentRequest(Map<Id, Id> AccountToReassignmentRuleMap){
        List<Account_Reassignment__c> accReassignList = new List<Account_Reassignment__c>();
        for(Id accId: AccountToReassignmentRuleMap.keySet()){
            if(AccountToReassignmentRuleMap.get(accId) != null){
                Account_Reassignment__c accReassign=new Account_Reassignment__c();
                accReassign.Account__c=accId;
                accReassign.Assign_To__c=AccountToReassignmentRuleMap.get(accId);
                //accReassign.CurrencyIsoCode = acc.CurrencyIsoCode;
                accReassign.Reassign__c=true;
                accReassign.Reason_Code__c='Other';
                accReassignList.add(accReassign);
            }
        }
        insert accReassignList;
    }

    public void doInitialize()
    {
        if(accReassignDataObject.getFromWhere().equals('VFPage') || accReassignDataObject.getFromWhere().equals('SF1')) // MOB-360 changes added a extra check for SF1
        {
            system.debug(LoggingLevel.Error, 'AGH_D Do Initialize VF Page');
            String salesOpsProfileId = AccountReassignmentDataClass.getCustomSettings('SalesOpsProfileId') + ',' + AccountReassignmentDataClass.getCustomSettings('Exception_Profile_Ids'); //SFDC-2304
            Boolean isBusinessOpsUser = false;
            String businessOpsProfileId = AccountReassignmentDataClass.getCustomSettings('BusinessOpeartionsProfileId'); //SFDC-2304
            //Features_Toggle__c customSettingsIntRevAccOwnerChange = Features_Toggle__c.getInstance('AccountInternalRevenue');
            String customSettingsIntRevAccOwnerChange = GSMUtilClass.getGSMSettingValue('AccReassign_InternalRevAccountToggle');
            Set<String> accountAkamIdList = new Set<String>();
            if(salesOpsProfileId.contains(UserInfo.getProfileId()))
                isAdminProfile=true;
            else
                isAdminProfile=false;

            Set<Id> revenueAccounts = new Set<Id>();
            initializedFlag=true;
            isNotInternalRevenueAccount = true;
            if(UserInfo.getProfileId().contains(businessOpsProfileId))
                isBusinessOpsUser=true;
            //Features_Toggle__c featureToggle = Features_Toggle__c.getInstance('AccountReassignment'); //SFDC-2304
            //if(featureToggle.Toggle__c == false) //SFDC-2304
            if(GsmUtilClass.isFeatureToggleEnabledCustomMetadata('AccountReassignment') == false) //SFDC-2304
            {
                if(accReassignDataObject.getFromWhere().equals('SF1')) { // MOB-360 changes
                    //sf1ReturnMessageJSON = JSON.serialize(new ResultSetCustom(true, featureToggle.Disabled_Alert_Message__c)); //SFDC-2304
                    sf1ReturnMessageJSON = JSON.serialize(new ResultSetCustom(true, GsmUtilClass.featureToggleMsg('AccountReassignment'))); //SFDC-2304
                }
                else {
                    //showErrorAndDiscontinue(featureToggle.Disabled_Alert_Message__c); //SFDC-2304
                    showErrorAndDiscontinue(GsmUtilClass.featureToggleMsg('AccountReassignment')); //SFDC-2304
                }
                //return false;
                initializedFlag=false;
            }
            //SFDC-3831
            List<Account>  accList =  [select Id,
                Name,
                Website,
                Account_Status__c,
                OwnerId,
                Old_Account_Owner__c,
                Owner.Status__c,
                Parent_Division__c,
                Region__c,
                Division__c,
                Area__c,
                Division_Formula__c,
                Geography_Formula__c,
                Anaplan_Sub_Territory__c,
                Akam_Territory_Mapping_Id__c,
                Normalized_Territory_ID__c,
                Normalized_Territory_Name__c,
                Customer_Type__c,
                Pipeline_Status__c,
                Revenue_Account__c,
                CurrencyIsoCode,
                Owner.Alias,
                Owner.ManagerId,
                AKAM_Account_ID__c,
                (Select Id, Probability, Associated_Lead__c, StageName from Opportunities where (isClosed=false OR (Probability=100 AND CloseDate>= :Date.today().addYears(-1)))
                 AND RecordTypeId IN : accReassignDataObject.getReassignOpptyRecTypes())
                    from Account where Id = : id]; // MOB-360 changes added id instead of Apex page Reference
            If(accList != null && !accList.isEmpty())
                account = accList[0];

            if(account == null)
            {
                isAccountIdPresent=false;

                if(accReassignDataObject.getFromWhere().equals('SF1')) { // MOB-360 changes : add apex page message only if not called from SF1
                    sf1ReturnMessageJSON = JSON.serialize(new ResultSetCustom(true, accReassignDataObject.getAccountIdNotPresentErrorMessage()));
                }
                else {
                    showErrorAndDiscontinue(accReassignDataObject.getAccountIdNotPresentErrorMessage());
                }
                //return false;
                initializedFlag=false;
            }
            else
            {
                if(customSettingsIntRevAccOwnerChange == 'False' && !isBusinessOpsUser)
                {
                    //for (Internal_Revenue_Account__c accountAkamId : [SELECT Name,value__c FROM Internal_Revenue_Account__c])
                    for(GSM_Settings__mdt mdtRecord :[select Id, Value__c from GSM_Settings__mdt where DeveloperName like 'InternalRevAcc%'])
                    {
                        accountAkamIdList.add(mdtRecord.value__c);
                    }
                    if(accountAkamIdList.contains(account.AKAM_Account_ID__c) )
                    {
                        isNotInternalRevenueAccount = false;

                        if(accReassignDataObject.getFromWhere().equals('SF1')) { // MOB-360 changes
                            sf1ReturnMessageJSON = JSON.serialize(new ResultSetCustom(true, accReassignDataObject.getAccountIsIntRevenueAccountErrorMsg()));
                        }
                        else {
                            showErrorAndDiscontinue(accReassignDataObject.getAccountIsIntRevenueAccountErrorMsg());
                        }
                    }
                }

                isAccountIdPresent=true;
                pendingAccountReassignmentId = AccountReassignmentInterfaceClass.getPendingReassignmentRequestId(account.Id);
                if(pendingAccountReassignmentId!=null)
                {
                    if(accReassignDataObject.getFromWhere().equals('SF1')) { // MOB-360 changes
                        sf1ReturnMessageJSON = JSON.serialize(new ResultSetCustom(true, AccountReassignmentDataClass.getCustomSettings('Error_Prevent_Duplicates'))); //SFDC-2304
                    }
                    else {
                        showErrorAndDiscontinue(AccountReassignmentDataClass.getCustomSettings('Error_Prevent_Duplicates')); //SFDC-2304
                        //return false;
                    }
                    initializedFlag=false;
                }
            }
            if (initializedFlag)
            {
                //User accOwner = new User();
                for (User u : [Select Id,Alias,email,profile.Name,UserRole.Name,isActive from User where Id =: account.OwnerId])
                    accOwner = u;

                // EffectiveMonthOftransfer String
                String strEffectiveMonthOftransfer = '';

                //Boolean isPastCutOffDate = (Date.today()>=Date.today().toStartOfMonth().addDays(Integer.valueOf('20'))?true:false);
                Boolean isPastCutOffDate= (Date.today().day()>=Integer.valueOf(AccountReassignmentDataClass.getCustomSettings('AssignNextMonthCutOffStart')) ? true : false); //SFDC-2304

                // check if Revenue Account
                if (account.Revenue_Account__c || account.Opportunities.size()>0 || account.Account_Status__c.contains('Active'))
                {
                    // instead flag it as a revenue Account boolean.
                    accReassignDataObject.setRevenueAccounts(new Set<Id>{account.Id});
                    isRevenueAccount=true;
                    if (isPastCutOffDate)
                        strEffectiveMonthOftransfer='next';
                }

                // InActive Account associated code...
                if(account.Owner.Status__c != 'Active')
                    isAccountOwnerInactive = true;
                else
                    isAccountOwnerInactive = false;

                // EffectiveMonthOftransfer String
                // String strEffectiveMonthOftransfer = '';

                if (accOwner.alias.containsIgnoreCase('netops'))
                    isNetOpsOwnedAccount=true;
                else if (isAccountOwnerInactive && account.Account_Status__c.contains('Lead'))
                {
                    strEffectiveMonthOftransfer = 'current';
                    if (account.Pipeline_Status__c == null ||  account.Pipeline_Status__c.contains(AccountReassignmentDataClass.getCustomSettings('DeferredAutoApprovedPipelineStatus'))) //SFDC-2304
                        strEffectiveMonthOftransfer = 'next';
                }
                else if (!isAccountOwnerInactive && account.Account_Status__c.contains('Lead')) {
                    if (isPastCutOffDate)
                        strEffectiveMonthOftransfer='next';
                    else
                        strEffectiveMonthOftransfer='current';
                }
                else if (isAccountOwnerInactive && account.Account_Status__c.contains('Active'))
                    strEffectiveMonthOftransfer = 'next';
                else if (!isAccountOwnerInactive && account.Account_Status__c.contains('Active'))
                    isAccountActive = true;

                List<Id> accountIdList = new List<Id>();
                accountIdList.add(account.id);


                accReassign = new Account_Reassignment__c();
                accReassign.CurrencyIsoCode = account.CurrencyIsoCode;
                accReassign.Account__c = account.Id;
                if (strEffectiveMonthOftransfer!=null)
                {
                    if (strEffectiveMonthOftransfer.equalsIgnoreCase('current'))
                        accReassign.Effective_Month_Of_Transfer__c = 'Current Month';
                    else if(strEffectiveMonthOftransfer.equalsIgnoreCase('next'))
                        accReassign.Effective_Month_Of_Transfer__c = 'Next Month';
                }
            }
        }
        else if(accReassignDataObject.getFromWhere().equals('AccountTrigger'))
        {
            system.debug(LoggingLevel.Error, 'AGH_D Inside Account Trigger Initialzie');
            fetchUserRule(accReassignDataObject.getAccounts());
        }
    }

    /**
      fetchUserRule(Account[] accounts)
      - This function initializes Account_Reassignment_Rule__c rule_Map
      - Also fetches ONA - No Owner Reassignment Rule.
     */
    public void fetchUserRule(List<Account> accountList)
    {
        String onaRuleName=AccountReassignmentDataClass.getCustomSettings('ONA_Reassignment_Rule_Name'); //SFDC-2304
        Set<Id> accountOwnerIdsSet=accReassignDataObject.getAccOwnerIdsSet();
        Map<Id,Id> ruleMap=accReassignDataObject.getRuleMap();
        Id ONARuleId=accReassignDataObject.getONARuleId();
        for (Account acc : accountList)
        {
            accountOwnerIdsSet.add(acc.OwnerId);
        }
        accReassignDataObject.setAccOwnerIdsSet(accountOwnerIdsSet);
        //for (Account_Reassignment_Rule__c rule : [select Name, Id, Associated_User__c from Account_Reassignment_Rule__c where (Associated_User__c in :accOwnerIdsSet OR Name = 'No Owner')])
        for (Account_Reassignment_Rule__c rule : [select Name, Id, Associated_User__c from Account_Reassignment_Rule__c where (Associated_User__c in :accountOwnerIdsSet OR Name = :onaRuleName)])
        {
            //if (rule.Name == 'No Owner' && ONARuleId == null)
            if (rule.Name == onaRuleName && ONARuleId == null)
                accReassignDataObject.setONARuleId(rule.Id);
            else
                ruleMap.put(rule.Associated_User__c, rule.Id);
        }
        accReassignDataObject.setRuleMap(ruleMap);
    }
    
    
    /**
      FetchUserRole (Account[] accounts)
      - @comments: Maps AccountOwnerID to RoleName
      Returns UserRoleMap
      created to check owner role name prior to team role assignment
     */

    public void FetchUserRole (Account[] accounts)
    {
        Map<Id,String> userRoleMap = accReassignDataObject.getUserRoleMap();
        Boolean requiredFlag = false;
        for(Account acc : accounts)
        {
            if(!userRoleMap.containsKey(acc.OwnerId))
                requiredFlag = true;
        }
        if(!requiredFlag)
            return;
        Set<Id> accOwnerIdSet = new Set<Id>();
        for(Account acc : accounts)
        {
            accOwnerIdSet.add(acc.OwnerID);
        }
        for(User usr : [select Id, UserRole.Name from User where Id IN :accOwnerIdSet])
        {
            userRoleMap.put(usr.Id, usr.UserRole.Name);
        }
        accReassignDataObject.setUserRoleMap(userRoleMap);
    }
    /**
      AddTeamMember(Id p_account_id, Id p_user_Id, String p_role)
      - This function adds a member with User Id - p_userId to the p_account_id's Account Team Members
      - The team role is updated as defined in the rule.
     */
    public AccountTeamMember AddTeamMember(Id p_account_id, Id p_user_Id, String p_role)
    {
        AccountTeamMember atm = new AccountTeamMember(); //Create a new team member
        atm.AccountId = p_account_id; //Assign the Account to which the member belongs to.
        atm.UserId = p_user_Id; //Make User with p_userId, the team member.
        atm.TeamMemberRole = p_role;//Update the team role as defined in DefaulAccountTeamMember
        //This is done automatically :=> Check if that record already exists (no duplicates)
        return atm;
    }
    /**
      UpdateAccessLevel(String p_access)
      - Maps the access levels for AccountAccessLevel and OpportunityAccessLevel
      - Check below link for more information.
      - http://www.salesforce.com/us/developer/docs/apexcode/Content/apex_bulk_sharing_understanding.htm
      - Defaults to 'Read' for unrecongnized AccessLevels.
      - The access level 'All' is also being defaulted to Read, because it is not a valid picklist option for Default Account Team Member.
     */
    public static String UpdateAccessLevel(String p_access)
    {
        if (p_access == 'Private')
            return 'None';
        else if (p_access == 'Read/Write')
            return 'Edit';
        else
            return 'Read';
    }

    public static Boolean isPastCutOffDate(Account_Reassignment__c pReassignReq)
    {
        Integer startDay = Integer.valueOf(AccountReassignmentDataClass.getCustomSettings('AssignNextMonthCutOffStart')); //SFDC-2304
        Integer endDay = Integer.valueOf(AccountReassignmentDataClass.getCustomSettings('AssignNextMonthCutOffEnd')); //SFDC-2304
        Boolean isPastCutOff=false;
        Account_Reassignment__c ReassignReq = pReassignReq;
        Date createdDate;
        if (ReassignReq.CreatedDate == null) {
            createdDate = System.today();
        } else {
            createdDate = ReassignReq.CreatedDate.date();
        }

        /*if ((Date.today().month() == createdDate.month() && Date.today().day() >= startDay) //Integer.valueOf('19'))
          || (Date.today().month() == createdDate.month()+1 && Date.today().day() <= endDay)) //Integer.valueOf('4')))
          isPastCutOff=true;*/
        if(Date.today().day()>=startDay || Date.today().day() <= endDay)
            isPastCutOff=true;
        //if(EffectiveMonth==Next || ReassignmentDueDate=5th of Month)
        //ReassisgnmentDueDate=5th of Month CreatedDate.Month+1
        return isPastCutOff;
    }

    /**
      Accept(Account_Reassignment__c accReassign)
      - Marks the Reassignment as accepted and triggers reassignment

      public static void Accept(Account_Reassignment__c accReassign)
      {
      accReassign.Reassign__c = true;
      accReassign.Reassign_Status__c = 'Accepted';
      accReassign.Status_Message__c = AccountReassignmentDataClass.getCustomSettings('Status - Accepted');
      }
     */
    public static void Accept(Account_Reassignment__c accReassign)
    {
        Integer startDay = Integer.valueOf(AccountReassignmentDataClass.getCustomSettings('AssignNextMonthCutOffStart')); //SFDC-2304
        Integer endDay = Integer.valueOf(AccountReassignmentDataClass.getCustomSettings('AssignNextMonthCutOffEnd')); //SFDC-2304

        Map<String,ReasonCodeSettings> accReasonCodeSettingsmap = getAccountReasonCodeSettings();

        Boolean respectCutOff = true;
        if (accReassign.Reason_Code__c != null) {
            String reasonCode = accReassign.Reason_Code__c.replace(' ','_');
            reasonCode = reasonCode.replace('-', '_');
            ReasonCodeSettings reasonCodeSettings = accReasonCodeSettingsmap.get(reasonCode);
            respectCutOff = reasonCodeSettings.respectCutoff;
        }


        if (accReassign.Action__c == AccountReassignmentDataClass.getCustomSettings('Action_Active_Approval')) //SFDC-2304
        {
            //Boolean isPastCutOffDate = (Date.today()>=Date.today().toStartOfMonth().addDays(Integer.valueOf('20'))?true:false);
            Boolean isPastCutOffDate = false;

            isPastCutOffDate=isPastCutOffDate(accReassign);


            if(accReassign.Reassign__c || !respectCutOff || accReassign.Account_Status__c.contains('Inactive') || accReassign.Account_Status__c.contains('Lead')) {
                accReassign.Reassign__c = true;
                accReassign.Reassign_Status__c = 'Accepted';
                accReassign.Status_Message__c = AccountReassignmentDataClass.getCustomSettings('Status_Accepted'); //SFDC-2304
                accReassign.Reassignment_Due_Date__c=Date.today();
            }

            else if(accReassign.IsPoolUserRequest__c == true)
            {
                system.debug(LoggingLevel.error, 'AGH_D Inside pool user check for approval');
                accReassign.Reassign__c = true;
                accReassign.Reassign_Status__c = 'Approved';
                accReassign.Status_Message__c = AccountReassignmentDataClass.getCustomSettings('Status_Approved'); //SFDC-2304
            }
            else if (!accReassign.Adhoc_Request__c /*&& !accIdToValidAQLMap.get(accReassign.Account__c)*/ && (isPastCutOffDate || (accReassign.Reassignment_Due_Date__c!=null && accReassign.Reassignment_Due_Date__c>Date.today())))
            {
                accReassign.Reassign_Status__c='Approved';
                accReassign.Status_Message__c = AccountReassignmentDataClass.getCustomSettings('Status_Approved'); //SFDC-2304
                if(Date.today().day()>=startDay)
                {
                    if(Date.today().month()<12)
                        accReassign.Reassignment_Due_Date__c = Date.newInstance(Date.today().year(), Date.today().addMonths(1).month(), Integer.valueOf(AccountReassignmentDataClass.getCustomSettings('Active_Account_Next_Month_Day'))); //SFDC-2304
                    else
                        accReassign.Reassignment_Due_Date__c = Date.newInstance(Date.today().addYears(1).year(), Date.today().addMonths(1).month(), Integer.valueOf(AccountReassignmentDataClass.getCustomSettings('Active_Account_Next_Month_Day'))); //SFDC-2304
                }
                else if(Date.today().day()<=endDay)
                {
                    accReassign.Reassignment_Due_Date__c = Date.newInstance(Date.today().year(), Date.today().month(), Integer.valueOf(AccountReassignmentDataClass.getCustomSettings('Active_Account_Next_Month_Day'))); //SFDC-2304
                }
            }

            else
            {
                accReassign.Reassign__c = true;
                accReassign.Reassign_Status__c = 'Accepted';
                accReassign.Status_Message__c = AccountReassignmentDataClass.getCustomSettings('Status_Accepted'); //SFDC-2304
                accReassign.Reassignment_Due_Date__c=Date.today();
            }
        }
        else if (accReassign.Reassignment_Due_Date__c!=null && accReassign.Reassignment_Due_Date__c>Date.today())
        {
            accReassign.Reassign_Status__c='Approved';
            accReassign.Status_Message__c = AccountReassignmentDataClass.getCustomSettings('Status_Approved'); //SFDC-2304
        }
        else
        {
            accReassign.Reassign__c = true;
            accReassign.Reassign_Status__c = 'Accepted';
            accReassign.Status_Message__c = AccountReassignmentDataClass.getCustomSettings('Status_Accepted'); //SFDC-2304
        }
    }

    /**
      Decline(Account_Reassignment__c accReassign)
      - Marks the Reassignment as rejected
     */
    public static void Decline(Account_Reassignment__c accReassign)
    {
        accReassign.Reassign_Status__c = 'Rejected';
        accReassign.Rejected_On__c = Date.today();
        accReassign.Status_Message__c = AccountReassignmentDataClass.getCustomSettings('Status_Rejected'); //SFDC-2304
    }
    /**
      SendForApproval(Account_Reassignment__c accReassign, String stausMessage)
      - Marks the Reassignment as pending approval
     */
    public void SendForApproval(Account_Reassignment__c accReassign, String stausMessage)
    {
        accReassign.Reassign_Status__c = 'Approval Pending';
        accReassign.Status_Message__c = stausMessage;
    }
    /**
      PassDenialOfReassignment(Account_Reassignment__c accReassign)
      - This function is called when the Time Triggered worlfow marks the Reassignment as Approved after 5 days
      Then, we wait for scheduled job to pick it up
     */
    public void PassDenialOfReassignment(Account_Reassignment__c accReassign)
    {
        accReassign.Status_Message__c = AccountReassignmentDataClass.getCustomSettings('Status_Approved'); //SFDC-2304

    }
    /**
      AcceptButton(Id accReassignId)
      - Called by a JavaScript button on the Account Reassignment page.
     */
    Webservice static String AcceptButton(Id accReassignId)
    {
        //Account
        //AccountReassignmentInterfaceClass accReassignInterfaceClassObject=new AccountReassignmentInterfaceClass(accReassignId);
        Account_Reassignment__c accReassign =getAccountReassignmentRecord(accReassignId);
        if(!isPrivilegedForAction(UserInfo.getUserId(), UserInfo.getProfileId(), accReassign, 'Accept'))
            return AccountReassignmentDataClass.getCustomSettings('Error_Insufficient_Privileges'); //SFDC-2304
        else if(accReassign.Reassign_Status__c != 'Approval Pending' && accReassign.Reassign_Status__c != 'Escalated')
            return AccountReassignmentDataClass.getCustomSettings('Error_Action_already_taken').replaceAll('##Reassign_Status##', accReassign.Reassign_Status__c); //SFDC-2304
        Accept(accReassign);
        update accReassign;
        return accReassign.Status_Message__c;
    }
    /**
      RejectButton(Id accReassignId)
      - Called by a JavaScript button on the Account Reassignment page.
     */
    Webservice static String RejectButton(Id accReassignId)
    {
        //selfObject=new AccountReassignmentOOClass(accReassignId);
        Account_Reassignment__c accReassign = getAccountReassignmentRecord(accReassignId);
        if(!isPrivilegedForAction(UserInfo.getUserId(), UserInfo.getProfileId(), accReassign, 'Reject'))
            return AccountReassignmentDataClass.getCustomSettings('Error_Insufficient_Privileges'); //SFDC-2304
        else if(accReassign.Reassign_Status__c != 'Approval Pending' && accReassign.Reassign_Status__c != 'Escalated')
            return AccountReassignmentDataClass.getCustomSettings('Error_Action_already_taken').replaceAll('##Reassign_Status##', accReassign.Reassign_Status__c); //SFDC-2304
        Decline(accReassign);
        update accReassign;
        return accReassign.Status_Message__c;
    }
    /**
      EscalateButton(Id accReassignId)
      - Called by a JavaScript button on the Account Reassignment page.
      - @todo:
      Check if Account Reassignment Request qualifies for Escalations. ie. Request within the  Escalationwindow.
      Check if its already escalated.
     */
    Webservice static String EscalateButton(Id accReassignId)
    {
        Account_Reassignment__c accReassign = getAccountReassignmentRecord(accReassignId);
        if(!isPrivilegedForAction(UserInfo.getUserId(), UserInfo.getProfileId(), accReassign, 'Escalate'))
            return AccountReassignmentDataClass.getCustomSettings('Error_Insufficient_Privileges'); //SFDC-2304
        else if (accReassign.Reassign_Status__c!=null && accReassign.Reassign_Status__c != 'Rejected' && accReassign.Reassign_Status__c != 'Approval Pending')
            return AccountReassignmentDataClass.getCustomSettings('Error_Action_already_taken').replaceAll('##Reassign_Status##', accReassign.Reassign_Status__c); //SFDC-2304
        else
            return '1';
    }
    /**
      isPrivilegedForAction(Id currentUserId, Id currentUserProfileId, Account_Reassignment__c accReassign, String action)
      Users who can Accept :
      - Inactive Account
      - Account Owner RSM
      - Lead Account
      - Account Owner
      - Account Owner RSM
      - Inactive Account
      - Account Owner RSM
      Users who can Reject :
      - Account Owner
      - Account Owner RSM
      - Requesting User
      - Assign To User
      - Assign To User RSM
      Exception Profiles
      - CRM Integration
      - System Administrator
      - Sales Operations
      - Business Operations
     */
    public static Boolean isPrivilegedForAction(Id currentUserId, Id currentUserProfileId, Account_Reassignment__c accReassign, String action)
    {
        if(action == 'Accept')
        {
            if(accReassign.Action__c == AccountReassignmentDataClass.getCustomSettings('Action_Inactive_Approval')) //SFDC-2304
            {
                if(currentUserId == accReassign.Account_Owner_RSM__c)
                    return true;
            }
            else if(accReassign.Action__c == AccountReassignmentDataClass.getCustomSettings('Action_Lead_Approval')) //SFDC-2304
            {
                if(currentUserId == accReassign.Account_Owner__c ||
                        currentUserId == accReassign.Account_Owner_RSM__c)
                    return true;
            }
            else if(accReassign.Action__c == AccountReassignmentDataClass.getCustomSettings('Action_Active_Approval')) //SFDC-2304
            {
                if (currentUserId == accReassign.Account_Owner__c || currentUserId == accReassign.Account_Owner_RSM__c
                        || (accReassign.RegionalSalesOpsUserIDs__c!=null && accReassign.RegionalSalesOpsUserIDs__c.containsIgnoreCase(currentUserId)))
                    return true;
            }
            // Active Account Reassignments cannot be Accepted
        }
        else if(action == 'Reject')
        {
            /*
               if(accReassign.Action__c == AccountReassignmentDataClass.getCustomSettings('Action : Active Approval'))
               {
               if (currentUserId == accReassign.Account_Owner__c || currentUserId == accReassign.Account_Owner_RSM__c
               || (accReassign.RegionalSalesOpsUserIDs__c!=null && accReassign.RegionalSalesOpsUserIDs__c.containsIgnoreCase(currentUserId)))
               return true;
               }
               else */
            if(currentUserId == accReassign.Account_Owner__c || currentUserId == accReassign.Account_Owner_RSM__c || currentUserId == accReassign.Requesting_User__c
                    || currentUserId == accReassign.Assign_To_User__c || currentUserId == accReassign.Assign_To_User_RSM__c
                    || (accReassign.RegionalSalesOpsUserIDs__c!=null && accReassign.RegionalSalesOpsUserIDs__c.containsIgnoreCase(currentUserId)))
                return true;
        }
        else if (action=='Escalate')
        {
            if(currentUserId==accReassign.Requesting_User__c || (accReassign.RegionalSalesOpsUserIDs__c!=null && accReassign.RegionalSalesOpsUserIDs__c.containsIgnoreCase(currentUserId)))
                return true;
        }
        String exceptionProfileIdsStr = AccountReassignmentDataClass.getCustomSettings('Exception_Profile_Ids'); //SFDC-2304
        if(exceptionProfileIdsStr.contains(currentUserProfileId))
            return true;
        return false;
    }
    /**
      getAccountReassignmentRecord(Id pAccReassign)
      - Fetches the Account Reassignmnet record for the specified Id
     */
    public static Account_Reassignment__c getAccountReassignmentRecord(Id pAccReassign)
    {
        return [select Id,
               Reassign__c,
               Account_Owner__c,
               Account_Owner_RSM__c,
               Reassign_Status__c,
               Status_Message__c,
               Action__c,
               Account__c,
               Reason_Code__c,
               Requesting_User__c,
               Assign_To_User__c,
               Assign_To_User_RSM__c,
               Reassignment_Due_Date__c,
               RegionalSalesOpsUserIDs__c,
               RegionalSalesOpsEmailIDs__c,
               Rejected_On__c,
               CreatedDate,
               Account_Owner__r.ManagerId,
               Assign_To_User__r.ManagerId,
               IsPoolUserRequest__c,
               Adhoc_Request__c,
               Approval_Level__c,
               AccountOwnerManager__c,
               ToBeAssignedUserManager__c,
               Approver_1__c,
               Approver_2__c,
               Account_Status__c


                   from Account_Reassignment__c
                   where Id=: pAccReassign];



    }
    /**
      UpdateOldOwner(Account[] triggerNew, Map<Id, Account> oldMap)
      - Update the Old Account Owner field with the old value if Owner is changing.
      - The value of the Old Account Owner will be same as OwnerId on creation or for data that the Owner has not changed.
     */
    public void UpdateOldOwner(Account acc)
    {
        if(acc.Old_Account_Owner__c != null && acc.OwnerId != accReassignDataObject.getAccountOwnerMap().get(acc.Id))
        {
            acc.Old_Account_Owner__c = accReassignDataObject.getAccountOwnerMap().get(acc.Id);
        }
        else if(acc.Old_Account_Owner__c == null)
        {
            acc.Old_Account_Owner__c = acc.OwnerId;
        }

    }

    /**
      PreventDuplicateAccountReassignments(Account_Reassignment__c[] accReassgnList)
      - Prevent an account reassignment request if there is an existing reassignment on the account with Status = Approval Pending
     */
    public void PreventDuplicateAccountReassignments()
    {
        Account_Reassignment__c[] accReassignList=accReassignDataObject.getAccReassignmentList();
        Set<Id> accountIdSet = new Set<Id>();
        for(Account_Reassignment__c accReassign: accReassignList)
            accountIdSet.add(accReassign.Account__c);
        Map<Id,Account_Reassignment__c> accountIdMap = getPendingReassignmentRequests(accountIdSet);
        for(Account_Reassignment__c accReassign: accReassignList)
        {
            if(accountIdMap.keySet().contains(accReassign.Account__c))
                accReassign.addError(AccountReassignmentDataClass.getCustomSettings('Error_Prevent_Duplicates')); //SFDC-2304
        }
    }
    /**
      getPendingReassignmentRequests(Id accountId)
      - Overload getPendingReassignmentRequests for Single Account Id
     */
    public static Account_Reassignment__c getPendingReassignmentRequests(Id accountId)
    {
        Set<Id> accIdSet = new Set<Id>();
        accIdSet.add(accountId);
        return getPendingReassignmentRequests(accIdSet).get(accountId);
    }
    public static Id getPendingReassignmentRequestId(Id accountId)
    {
        Account_Reassignment__c accReassign = getPendingReassignmentRequests(accountId);
        if(accReassign != null)
            return accReassign.Id;
        return null;
    }
    /**
      getPendingReassignmentRequests(Set<Id> accountIds)
      - Returns a map of all the pending request for the account Ids that are passed as parameters
     */
    public static Map<Id, Account_Reassignment__c> getPendingReassignmentRequests(Set<Id> accountIds)
    {
        Map<Id,Account_Reassignment__c> accountIdMap = new Map<Id,Account_Reassignment__c>();
        for(Account_Reassignment__c accReass : [select Id,
                Name,
                Account__c,
                Adhoc_Request__c
                from Account_Reassignment__c
                where Account__c IN :accountIds and
                Reassign_Status__c != 'Accepted' and
                Reassign_Status__c != 'Rejected'])
            accountIdMap.put(accReass.Account__c, accReass);
        return accountIdMap;
    }
    /**
      Reassign_ApprovedReassignments()
      - This is the scheduled function that takes care of Active account reassignments
      - It will process reassignments that have been approved and have past the Reassignment Due Date
     */
    public static String Reassign_ApprovedReassignments()
    {
        String res='1:';
        Integer count=0;
        String ids='';
        List<Account_Reassignment__c> pendingApprovedReassignments;
        datetime tempDate = datetime.now();
        try
        {
            pendingApprovedReassignments= [select Id,
                Name,
                Reassign__c,
                Reassign_Status__c,
                Status_Message__c,
                Effective_Month_Of_Transfer__c,
                Action__c,
                CreatedDate,
                Reassignment_Due_Date__c,
                IsPoolUserRequest__c,
                Account__c,
                Reason_Code__c,
                Adhoc_Request__c,
                Account_Status__c
                    from Account_Reassignment__c
                    where Reassign__c != true and
                    (Reassign_Status__c = 'Approved' OR Reassign_Status__c = 'Auto Approved') and
                    Reassignment_Due_Date__c != null and Reassignment_Due_Date__c <= :Date.today() and
                    CreatedDate=LAST_90_DAYS];

            //populate map for AQL Scenario
            List<Id> accountIds = new List<Id>();
            for(Account_Reassignment__c accReassign : pendingApprovedReassignments) {
                accountIds.add(accReassign.Account__c);
            }
            //accIdToValidAQLMap = validAQLScenario(accountIds);


            for(Account_Reassignment__c accReassign : pendingApprovedReassignments)
                //update the aql map
                Accept(accReassign);
            if(pendingApprovedReassignments.size()>0)
            {
                list<Database.SaveResult> results = Database.update(pendingApprovedReassignments,false);
                Integer i =0;
                for (Database.SaveResult r : results) {
                    if (r.isSuccess()) {
                        if(i==0) {
                            ids=r.getId();
                            count = 1;
                        }
                        else {
                            ids=ids+','+r.getId();
                            count++;
                        }
                        i++;
                    }    
                }
            }
            res=res+'\n Count: '+ count+'\nIds processed: '+ids;
        }
        catch(Exception e)
        {
            res='0#'+e;
        }
        return res;

    }

    public void initRegionalSalesOps()
    {
        String userType = Schema.SObjectType.User.getKeyPrefix();
        groupMemberUserIdSet = new Set<Id>();
        Map<String,Set<Id>> salesOpsGroupMemberMap = new Map<String,Set<Id>>();
        Map<Id,User> salesOpsUsersMap = new Map<Id,User>();
        String groupDevNamePrefix = GsmUtilClass.getGSMSettingValue('AccountReassignment_Prefix'); //SFDC-2304
        groupDevNamePrefix = groupDevNamePrefix + '%';
        for (Group g : [SELECT Id,Name,DeveloperName,Type, (SELECT GroupId,Id,SystemModstamp,UserOrGroupId FROM GroupMembers) FROM Group where Type = 'Regular' and Name like :groupDevNamePrefix])
        {
            Set<Id> tempGroupMemberSet = getGroupMembers(g.GroupMembers,userType);
            if (tempGroupMemberSet.size()>0)
            {
                salesOpsGroupMemberMap.put(g.DeveloperName,tempGroupMemberSet);
                groupMemberUserIdSet.addAll(tempGroupMemberSet);
            }
        }

        if (salesOpsGroupMemberMap.size()>0)
        {
            accReassignDataObject.setSalesOpsGroupMemberMap(salesOpsGroupMemberMap);
            accReassignDataObject.setUserIdSet(groupMemberUserIdSet);
            //salesOpsUsersMap = getActiveUsersMap(groupMemberUserIdSet);
            //accReassignDataObject.setSalesOpsUsersMap(salesOpsUsersMap);
        }

    }

    public Set<Id> getGroupMembers(List<GroupMember> pGroupMembersList, String pUserType)
    {
        Set<Id> tempGroupMemberSet = new Set<Id>();
        for (GroupMember gm : pGroupMembersList)
        {
            if (((String)gm.UserOrGroupId).startsWith(pUserType))
                tempGroupMemberSet.add(gm.UserOrGroupId);
            //else
            // throw exception
        }
        return tempGroupMemberSet;
    }

    public void initUserMap(Set<Id> pUserIds)
    {
        Boolean requiredFlag = false;
        Map<Id,User> userMap = new Map<Id,User>();
        Set<Id> inMapUserIds = new Set<Id>();

        userMap = accReassignDataObject.getUserMap();
        inMapUserIds = userMap.keySet();

        for(Id usrId : pUserIds)
        {
            if (userMap.size()<1 || !inMapUserIds.contains(usrId))
            {
                requiredFlag=true;
                break;
            }
        }
        if(!requiredFlag)
            return;

        for (User u : [Select Id,Alias,email,profile.Name,UserRole.Name,isActive, Name, Manager.email from User where Id IN : pUserIds])
            userMap.put(u.Id,u);

        accReassignDataObject.setUserMap(userMap);
    }

    public List<User> getRegionalSalesOps(String pGeography,String pDivision, String pArea,String pRegion)
    {
        Map<String,Set<Id>> salesOpsGroupMemberMap = accReassignDataObject.getSalesOpsGroupMemberMap();
        List<User> opsUsers = new List<User>();
        Map<Id,User> userMap = accReassignDataObject.getUserMap();

        List<String> groupNameContructedList = getGroupContructedSet(pGeography,pDivision,pArea,pRegion);

        for (String groupName:groupNameContructedList) {
            if (salesOpsGroupMemberMap != null && groupName != null ) {

                if (salesOpsGroupMemberMap.keySet().contains(groupName)) {
                    Set<Id> grpMember = salesOpsGroupMemberMap.get(groupName);
                    for (Id uId : grpMember)
                    {
                        User usr = userMap.get(uId);
                        if (usr!=null && usr.isActive)
                            opsUsers.add(usr);
                    }
                }
            }
        }

        return opsUsers;
    }


    public List<String> getGroupContructedSet(String pGeography,String pDivision, String pArea,String pRegion) {

        String groupDevNamePrefix = GsmUtilClass.getGSMSettingValue('AccountReassignment_Prefix'); //SFDC-2304
        groupDevNamePrefix = groupDevNamePrefix + '_';

        List<String> groupNameContructedList = new List<String>();

        if ( (pDivision != null && !String.isEmpty(pDivision))) {
            String groupNameForDivision = groupDevNamePrefix+(pGeography.replace(' ','_'))+'_'+(pDivision.replace(' ','_'));
            groupNameForDivision = groupNameForDivision.replace('&','and');
            groupNameForDivision = groupNameForDivision.substring(0, Math.min(groupNameForDivision.length(), 40));
            groupNameContructedList.add(groupNameForDivision);
        }

        if (pArea != null && !String.isEmpty(pArea) ) {
            String groupNameForArea = groupDevNamePrefix+(pGeography.replace(' ','_'))+'_'+(pArea.replace(' ','_'));
            groupNameForArea = groupNameForArea.replace('&','and');
            groupNameForArea = groupNameForArea.substring(0, Math.min(groupNameForArea.length(), 40));
            groupNameContructedList.add(groupNameForArea);
        }

        if (pRegion != null && !String.isEmpty(pRegion) ) {
            String groupNameForRegion = groupDevNamePrefix+(pGeography.replace(' ','_'))+'_'+(pRegion.replace(' ','_'));
            groupNameForRegion = groupNameForRegion.replace('&','and');
            groupNameForRegion = groupNameForRegion.substring(0, Math.min(groupNameForRegion.length(), 40));
            groupNameContructedList.add(groupNameForRegion);
        }
        return groupNameContructedList;

    }

    public Set<String> getUserEmailId(Set<Id> pUserIdSet)
    {
        Map<Id,User> userMap = accReassignDataObject.getUserMap();
        Set<String> emailIdSet = new Set<String>();
        for (Id uId : pUserIdSet)
        {
            User usr = userMap.get(uId);
            if (usr!=null && usr.isActive)
                emailIdSet.add(usr.Email);
        }
        return emailIdSet;
    }
    public String concatTwoStrings(String pExistingVal, String pNewVal)
    {
        String concatenatedString=pNewVal;
        if (pExistingVal!=null && pExistingVal.length()>0)
            concatenatedString= pExistingVal + ',' + pNewVal;

        return concatenatedString;
    }

    public static Messaging.SingleEmailMessage createSingleEmailWithVFTemplate(Id pReassignmentRequestId,Id pUserId,string pCcEmail,string pToEmail, string pTemplateId)
    {
        boolean CcEmailflag=false;
        if(pCcEmail!='')
            CcEmailflag=true;
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] ccAddresses = pCcEmail.split(',');
        String[] toAddresses = pToEmail.split(',');
        mail.setWhatId(pReassignmentRequestId);
        mail.setTargetObjectId(pUserId);
        if(CcEmailflag==true)
            mail.setCcAddresses(ccAddresses);
        mail.setToAddresses(toAddresses);
        mail.setTemplateId(pTemplateId);
        mail.setSaveAsActivity(false);
        return mail;
    }
    /*
     * This method is called from the AccountReassignmentTrigger to submit the
     * list of Account Reassignment requests for approval
     */
    public static void submitForApproval(List<Id> accReassignIdId)
    {

        List<Approval.ProcessSubmitRequest> approvalReqList=new List<Approval.ProcessSubmitRequest>();
        List<Error_Log__c> errorLogs = new List<Error_Log__c>();

        for (Id reqId:accReassignIdId) {
            // create the new approval request to submit
            Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
            req.setComments('Submitted for approval. Please approve.');
            req.setObjectId(reqId);
            approvalReqList.add(req);
        }

        try
        {
            // submit the approval request for processing
            if (!Test.isRunningTest()) {
                List<Approval.ProcessResult> resultList = Approval.process(approvalReqList);
            }

        }
        catch(System.DmlException e)
        {
            for (Integer i = 0; i < e.getNumDml(); i++)
            {
                if(e.getDmlType(i) == Statuscode.FIELD_CUSTOM_VALIDATION_EXCEPTION ||e.getDmlType(i) == Statuscode.FIELD_INTEGRITY_EXCEPTION)
                {
                    Error_Log__c el = new Error_Log__c(Name='AccountReassignmentApprovalDMLError', Class__c='AccountReassignmentInterfaceClass', Error_Message__c=e.getDmlMessage(i));
                    errorLogs.add(el);
                }
            }
        }
        catch(Exception e)
        {
            Error_Log__c el = new Error_Log__c(Name='AccountReassignmentApprovalError', Class__c='AccountReassignmentInterfaceClass', Error_Message__c=e.getMessage());
            errorLogs.add(el);
        }
        if(errorLogs.size()>0)
            Database.insert(errorLogs, false);
    }



    public class ReasonCodeSettings {
        public boolean approvalRequired;
        public boolean respectCutOff;
    }

    public static Map<String,ReasonCodeSettings> getAccountReasonCodeSettings() {

        List<Account_Reassignment_Reason_Code__mdt>  arrcRecords = [select Id,developerName, Approval_Required__c, Respect_Cut_off__c
            from Account_Reassignment_Reason_Code__mdt limit 50000];

        Map<String,ReasonCodeSettings> accReasonCodeSettingsmap = new Map<String,ReasonCodeSettings>();

        for (Account_Reassignment_Reason_Code__mdt s:arrcRecords) {
            ReasonCodeSettings settings = new ReasonCodeSettings();
            settings.approvalRequired = s.Approval_Required__c;
            settings.respectCutOff = s.Respect_Cut_off__c;
            accReasonCodeSettingsmap.put(s.developerName,settings);
        }

        return accReasonCodeSettingsmap;
    }

    public static void noApprovalRequired(List<Id> noApprovalRequiredList){
        List<Account_Reassignment__c> noApprovalList = [Select id,Approval_Level__c From Account_Reassignment__c
            Where id IN : noApprovalRequiredList];
        for (Account_Reassignment__c arr : noApprovalList) {
            arr.Approval_Level__c = 'Reassignment Approved';
        }
        try{
            update noApprovalList;
        }
        catch(Exception e){

        }
    }
}