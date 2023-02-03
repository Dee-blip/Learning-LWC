global class OpportunityTriggerClass 
{
    public static User currentUserRecord;
    public static Boolean manageForecastCategoryFirstRunFlag = true;
    public static Boolean specialForecastCategoryFirstRunFlag = true;
    public static Boolean managePartnerForecastFirstRunFlag = true;
    public static Boolean manageSecurityForecastFirstRunFlag = true;
    //SFDC-1435
    public static Boolean manageServiceForecastFirstRunFlag = true;
    //SFDC-1560
    public static Boolean manageForecastFirstRunFlag = true;
    //public static Boolean genericPopulateMRRFirstRunFlag = true;
    public static Boolean updateOpportunityShiftedDateFirstRunFlag = true;
    public static Boolean updateOpptyOwnerFirstRunFlag = true;
    //public static Boolean verifyMinimumContactRolesOnStageChangeFirstRunFlag = true;
    public static Boolean sendEmailWhenClosedWonFirstRunFlag = true;
    public static Boolean createTaskWhenSalesStage6FirstRunFlag = true;
    public static Boolean populateRenewalOpptyFieldsFirstRunFlag = true;
    public static Boolean OpptyCategoryCheckFirstRunFlag = true;
    public static Boolean updatePrimaryProductNameOnOpptyFirstRunFlag = true;
    public static Boolean addOpptyShareFirstRunFlag = true;
    public static Boolean updateCampaignOnDealRegFirstRunFlag = true;
    //SFDC-2580
    public static String stageNameList = GsmUtilClass.getGSMSettingValue('Opportunity_Early_Influence_Tieback_Yes');
    public static Boolean delOpptyShareFirstRunFlag = true;
    //SFDC-1290
    public static Boolean fromProductWizard = false;

    public static integer NoOfEmailsSentWhenClosedWon = 0;
    public static Map<Id,User> userProfileMap = new Map<Id,User>();
    public static Map<Id, Account> acc_accOwnerMap = new Map<Id, Account>();
    public static Map<Id, Channel_Mapping__c> channelMapping = new Map<Id, Channel_Mapping__c>();
    public static Id akamaiRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Akamai Opportunity').getRecordTypeId();
    public static Id aweRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('AWE Opportunities').getRecordTypeId();
    public static Id amgRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('AMG Opportunity').getRecordTypeId();
    public static Id adsRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('ADS Record Type').getRecordTypeId();
    //SFDC-3261
    public static Id closedRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(GSMUtilClass.getGSMSettingValue('Closed_Opportunity_Rec_Type')).getRecordTypeId();

    public static Boolean channelManagerCheckFirstRunFlag = true;
    public static Boolean createAutomatedActivitiesFirstRunFlag = true;
    public static Boolean addDVPToFollowCheckFirstRunFlag=true;
    public static Boolean removePartnersFromSalesTeamForOldPartnerInvloved=true;
    public static Boolean stampPOBOnOpptyFirstRunFlag = true;
    public static Boolean resetPartnerAuthorisedCountryFlag = true;
    public static Boolean setPartnerAuthorisedCountryFlag = true;
    public static Boolean checkForDuplicateRenewalOpportunity=false;
    public static Set<Id> stpEnabledOpptyIdSet = new Set<Id>();
    public static Boolean fetchSubReseller = true;
    private static Map<Id,SubReseller__c> subMap;
    //SFDC-8991
    /*public static Boolean switchToAutoRenewalTypeFirstRunFlag = true;*/
    public static Boolean switchToAutoRenewalTypeOLIFirstRunFlag = true;
    public static Boolean autoAssignSpecialistFirstRunFlag = true;
    public static L2Q_ZOFF_Feature__mdt zoffMdtvalue = ZoffUtilClass.getZOFFmdtsetting('ZOFF'); //Rajesh-SFDC-7061 || ZOFF
    private static boolean zoffFirstrun  = true ;// Rajesh - SFDC-7061
    public static string loggedinUserId = UserInfo.getUserId();// Rajesh - SFDC-7061
    public static string loggedinProfileId = UserInfo.getProfileId();// Rajesh - SFDC-7061
    public static Map<Id,ZoffUtilClass.emailListwrapper> prepareEmailist = new Map<Id,ZoffUtilClass.emailListwrapper>();//Rajesh
	public static Messaging.SingleEmailMessage[] emailsToSend = new List<Messaging.SingleEmailMessage>();
    public static Boolean createCreditCheckTaskFlag = true;
    public static Boolean sendEmailToSpecialistFirstFlag = true;
    public static Boolean syncSpecialistFieldFlag = true;
    public static Boolean UpdateLossCategoryFlag = true;
    public static Boolean zoffEmailForMediaVerticalFirstRun = true;
    //public static Map<Id,Opportunity> opptyMapTriggerClass=new Map<Id,Opportunity> ();

    public static void initializeCurrentUserRecord()
    {
        if(currentUserRecord == null){
            list<User> userList = [select Id, Profile.Name, Profile.UserType, ProfileId from User where Id=:Userinfo.getUserId()];
            if(userList.size()>0)
                currentUserRecord = userList[0];
        }
    }
    //HC SFDC-1922 Depecrated feature
    //Code-coverage - QTOO
    //adding overloaded method as part of QTOO-2299
    public static Task createtask(string usrid,string taskwhatid,string subjecttext,string bodytext,string taskstatus,string agreementid)
    {

        Task ta=createtask(usrid,taskwhatid,subjecttext,bodytext,taskstatus);
        return ta;
    }

    //SFDC-2580
    public static void stampTiebackDateAndEarlyInfluence(Opportunity opp)
    {
        opp.Tieback_Date__c = Datetime.now();
        if(stageNameList.contains(opp.StageName))
            opp.Early_Influence_Tieback__c = 'Yes';
        else
            opp.Early_Influence_Tieback__c = 'No';
    }

    //SFDC-3545
    public static void checkOppContactRole(List<Opportunity> oppList)
    {
        List<Id> oppIdList = new List<Id>();
        Map<id,OpportunityContactRole> oppIdToOppConRole = new Map<id,OpportunityContactRole>();
        for(Opportunity opp: oppList){
            oppIdToOppConRole.put(opp.id, null);
            oppIdList.add(opp.id);
        }

        List<OpportunityContactRole> oppConRoleList = [Select id, OpportunityId from OpportunityContactRole where OpportunityId in :oppIdList];

        for(OpportunityContactRole oppConRole: oppConRoleList){
            oppIdToOppConRole.put(oppConRole.OpportunityId, oppConRole);
        }

        for(Opportunity opp: oppList){
            if(oppIdToOppConRole.get(opp.Id) == null)
                opp.addError('A Contact Role must be added before moving to any stage beyond Stage 2');
        }
    }

    //SFDC-4178 Start
    public static void CheckOppValidationRule(Map<Id, Opportunity> oppList){

       List<String> statusCheck = GSMUtilClass.getGSMSettingValue('Order_Management_Case_Approved_Status').split(',');
        if(!Test.isRunningTest()){
            for(Opportunity opp : [Select Id, Opportunity_Type__c, Auto_Renewal__c, No_Paper_Strategic_Opportunity__c, Churn_No_Paper__c, (Select id, Valid_Until_Date__c from Related_Cases__r where RecordType.Name = 'Order Approval-Order Management' and status IN :statusCheck limit 1) from Opportunity where id in:oppList.keyset()]){
                if(opp.Related_Cases__r.size() == 0){
                    oppList.get(opp.Id).addError('No Opportunity can be moved to Stage 6 - Signed, without an Order Management Approval in place.');
                }
                //SFDC-6902 Valid Until Date Expiration Validation Rule
                if(opp.Related_Cases__r.size() > 0 && opp.Related_Cases__r[0].Valid_Until_Date__c != null && opp.Related_Cases__r[0].Valid_Until_Date__c < Date.today() && opp.No_Paper_Strategic_Opportunity__c == false && opp.Churn_No_Paper__c == false){
                        oppList.get(opp.Id).addError('Valid Until Date has expired. Please contact your Sales Rep.');
                }
            }
        }
    }
    //SFDC-4178 End

    //SFDC-6974
    public static void stampCustomerProspect(Map<Id, List<Opportunity>> accToOpptyIds){
        for(Account acc : [select Id, Account_Status__c from account where Id IN :accToOpptyIds.keyset()]){
            for(Opportunity opp : accToOpptyIds.get(acc.Id)){
                if(acc.Account_Status__c != null && (acc.Account_Status__c == 'Lead' || acc.Account_Status__c.contains('Inactive')))
                    opp.Opportunity_Prospect_Customer__c = 'Prospect';
                else
                    opp.Opportunity_Prospect_Customer__c = 'Customer';
            }
        }
    }

    //SFDC-3547
    public static void checkOrderApprovalForOpp(List<Opportunity> oppList)
    {
        List<Id> oppIdList = new List<Id>();
        Map<id,Order_Approval__c> oppIdToOrderApp = new Map<id,Order_Approval__c>();
        for(Opportunity opp: oppList){
            oppIdToOrderApp.put(opp.id, null);
            oppIdList.add(opp.id);
        }

        List<Order_Approval__c> orderAppList = [Select id, Associated_Opportunity__c from Order_Approval__c where Associated_Opportunity__c in :oppIdList];

        for(Order_Approval__c orderApp: orderAppList){
            oppIdToOrderApp.put(orderApp.Associated_Opportunity__c, orderApp);
        }

        for(Opportunity opp: oppList){
            if(oppIdToOrderApp.get(opp.Id) == null)
                opp.addError('An Order Approval must be created before moving to any stage beyond Stage 4');
        }
    }

    //Code-coverage - QTOO - HC 1922 - Removed the depecrated feature
    public static Task createtask(string usrid,string taskwhatid,string subjecttext,string bodytext,string taskstatus,string agreementid, boolean isSTPEligible, String poRequired, String poNumber)
    {

        Task createdTask = createtask(usrid,taskwhatid,subjecttext,bodytext,taskstatus, agreementid);
        //createdTask.is_STP_Eligible__c = isSTPEligible;
        //createdTask.Purchase_Order_Required__c = poRequired;
        //createdTask.PO_Number__c = poNumber;
        return createdTask;
    }

    public static Task createtask(string usrid,string taskwhatid,string subjecttext,string bodytext,string taskstatus)
    {
        Task ta=new Task();
        ta.OwnerId=usrid;
        ta.WhatId=taskwhatid;
        ta.Subject=subjecttext;
        //ta.Type__c='Email';
        ta.Description =bodytext;
        ta.Status=taskstatus;
        ta.ActivityDate= datetime.now().date().addDays(2);
        return ta;
    }

    //End Commented by Chandra for CR 1501111
    /**
      ManagePartnerForecast(Map<Id, Opportunity> oppOldMap, Map<Id, Opportunity> oppNewMap)
      - This functions take care of the following:
      1. Allow Parter to Override 'Partner Forecast Amount' if  'Override PAE TCV' is checked && SalesStage != 6, otherwise it populates the 'Override PAE TCV' with 'Total Contract Value'
      2.
     */
    public static void ManagePartnerForecast(Opportunity[] opptys, Map<Id, Opportunity> oppOldMap, Map<Id, Opportunity> oppNewMap)
    {
        if (!managePartnerForecastFirstRunFlag)
            return;

        // Initialize currentUser record.
        initializeCurrentUserRecord();


        // Forecasting related changes... replace above for loop with this one.
        //SFDC-3831
        String opptyStageToOverride = GSMUtilClass.getGSMSettingValue('opptyStagesForRepsRecTypeChangeToClosed');
        for (Opportunity opp: opptys)
        {
            if (GsmUtilClass.isFeatureToggleEnabledCustomMetadata('isOOTBForecastingEnabled')) // run forecasting related code //SFDC-2304
            {   //Code-coverage
                // CR 1863928 --- start ---
                //SFDC-1435 - Removing profile check
                // Throw a validation error when user changes any of the PAE fields and Oppty.SS = 6-Signed/Closed Admin/Closed Lost during Edit/update.
                //SFDC-3831
                if(opptyStageToOverride.contains(opp.stageName) &&
                        !opp.Validation_Override__c && !Trigger.isInsert &&
                        (opp.Partner_Forecast_Amount__c != oppOldMap.get(opp.id).Partner_Forecast_Amount__c ||
                         opp.PAE_Close_Date__c != oppOldMap.get(opp.id).PAE_Close_Date__c || opp.Partner_Forecast__c != oppOldMap.get(opp.id).Partner_Forecast__c ||
                         opp.Override_PAE_TCV__c != oppOldMap.get(opp.id).Override_PAE_TCV__c || opp.Override_Close_Date__c != oppOldMap.get(opp.id).Override_Close_Date__c ||
                         opp.Override_Partner_Forecast__c != oppOldMap.get(opp.id).Override_Partner_Forecast__c || opp.PAE_Strategic_MRR_Override__c != oppOldMap.get(opp.id).PAE_Strategic_MRR_Override__c ||
                         opp.PAE_Strategic_MRR__c!=oppOldMap.get(opp.id).PAE_Strategic_MRR__c))
                    opp.addError(Label.PAEFieldChangeError);
                // CR 1863928 --- end ---

                // After stage 6, PAE MRR = MRR and PAE MRR override = false
                //SFDC-3831
                if(opptyStageToOverride.contains(opp.stageName))
                {   //Code-coverage
                    //opp.Partner_Forecast_Amount__c = opp.MRR__c;
                    opp.Override_PAE_TCV__c = false;
                }

                //SFDC-3831
                if(opptyStageToOverride.contains(opp.stageName)  || (!opp.Override_Close_Date__c && ((Trigger.isinsert &&
                                    opp.PAE_Close_Date__c==null) || (!Trigger.isInsert && !oppOldMap.get(opp.id).Override_Close_Date__c && opp.PAE_Close_Date__c != opp.CloseDate &&
                                        opp.PAE_Close_Date__c == oppOldMap.get(opp.id).PAE_Close_Date__c))))
                {
                    opp.PAE_Close_Date__c = opp.CloseDate;
                    opp.Override_Close_Date__c = false;
                }
            }
            else
            {//Code-coverage
                //SFDC-3831
                if(opptyStageToOverride.contains(opp.stageName)  || (!opp.Override_PAE_TCV__c && opp.Total_Contract_Value__c != null &&
                            ((Trigger.isInsert && opp.Partner_Forecast_Amount__c==null)|| (!Trigger.isInsert && !oppOldMap.get(opp.id).Override_PAE_TCV__c &&
                                opp.Partner_Forecast_Amount__c != opp.Total_Contract_Value__c && opp.Partner_Forecast_Amount__c == oppOldMap.get(opp.id).Partner_Forecast_Amount__c))))
                {
                    // Forecasting Change, need to look at MRR for PAE Forecast Amount instead of TCV.
                    //opp.Partner_Forecast_Amount__c = opp.Total_Contract_Value__c;
                    opp.Override_PAE_TCV__c = false;
                }
            }

            //Code-coverage
            // After stage 6, PAE SMRR = SMRR and PAE SMRR override = false
            //SFDC-3831 - not making changes w.r.t SMRR as its obsolete, not deleting code as well as not sure if its referred anywhere.
            if(opp.Probability == 0.0 || opp.Probability == 90.0 || opp.Probability == 100.0)
            {
                opp.PAE_Strategic_MRR__c = opp.Strategic_MRR__c;
                opp.PAE_Strategic_MRR_Override__c = false;
            }
            managePartnerForecastFirstRunFlag = false;
        }
    }



    /**Sonali Tandon - 22/02/2016 - CR 3313721 - NAP -- Enhance Partner Onboarding form :: When Partner onboarding record is created/ opportunity on
      it is updated, stamp the partner onboarding on the corresponding opportunity.**/

    public static void stampPartnerOnboardingOnOppty(Map<Id,Id> mapOfOpptyIdWithPobId, List<Id> listOfOldOpptysIds)
    {//Code-coverage
        if(!stampPOBOnOpptyFirstRunFlag)
            return;

        List<Opportunity> listOfOpptysToUpdate = new List<Opportunity>();
        for(Opportunity oppty : [Select Id/*,Partner_Onboarding__c*/ from Opportunity where Id IN : mapOfOpptyIdWithPobId.keySet()])
        {
            //oppty.Partner_Onboarding__c = mapOfOpptyIdWithPobId.get(oppty.Id);
            listOfOpptysToUpdate.add(oppty);
        }
        //Code-coverage
        for(Opportunity oppty : [Select Id/*,Partner_Onboarding__c*/ from Opportunity where Id IN:listOfOldOpptysIds])
        {
            //oppty.Partner_Onboarding__c = null;
            listOfOpptysToUpdate.add(oppty);
        }
        System.debug('listOfOpptysToUpdate' + listOfOpptysToUpdate);

        update listOfOpptysToUpdate;

        stampPOBOnOpptyFirstRunFlag = false;


    }

    /**
      ManageForecastCategory(Map<Id, Opportunity> oppOldMap, Map<Id, Opportunity> oppNewMap)
      - This functions take care of the following:
      1. Allow users to Override the ForecastCategory through a custom field called "Override ForecastCategory with"
      2. Manage when and how the overide fucntionality should be reserved or reverted to Out-of-box.
      - It uses the OpportunitySalesStage table to avoid all hard-coding.
     */
    public static void ManageForecastCategory(Opportunity[] opptys, Map<Id, Opportunity> oppOldMap, Map<Id, Opportunity> oppNewMap)
    {
        if(!manageForecastCategoryFirstRunFlag)
            return;

        //SFDC-2043
        List<Opportunity> gstCheckOppList = new List<Opportunity>();
        if(Trigger.isUpdate || Trigger.isInsert){
            Opportunity oldOpp = new Opportunity();
            Opportunity newOpp = new Opportunity();
            //SFDC-9221 Manish Mahajan
            List<L2Q_TaxID_Country_Code__mdt> listMdt = [Select Id,Prefix__c,Country_Name__c from L2Q_TaxID_Country_Code__mdt];
            List<String> GSTCountries = new List<String>();
            for(L2Q_TaxID_Country_Code__mdt mdt: listMdt){
                GSTCountries.add(mdt.Country_Name__c.toLowerCase());
            }
            
            for(Opportunity opp: opptys){
                if(oppOldMap != null){
                    oldOpp = oppOldMap.get(opp.id);
                }
                if(oppNewMap != null){
                    newOpp = oppNewMap.get(opp.id);
                } else{
                    newOpp = opp;
                }
                //SFDC-9221 Manish Mahajan
                if(String.isNotBlank(opp.Account_Primary_Country__c) && (oldOpp.stageName != '3. Verify Options'  && newOpp.stageName == '3. Verify Options') && GSTCountries.contains(opp.Account_Primary_Country__c.toLowerCase())){
                    gstCheckOppList.add(opp);
                }
                /*if((oldOpp.stageName != '3. Verify Options'  && newOpp.stageName == '3. Verify Options') && opp.Account_Primary_Country__c == 'India'){ //SFDC-3539
                    gstCheckOppList.add(opp);
                }*/
            }
            List<String> accIds = new List<String>();
            for(Opportunity opp1: gstCheckOppList){
                accIds.add(opp1.AccountId);
            }
            List<Account> accListForGST = [select id, Owner.name, Owner.email, GST__c, name, (select user.email from AccountTeamMembers) from account where id in :accIds];
            for(Account acc: accListForGST){
                if(acc.GST__c == null){
                    List<String> accTeamMemberIDs = new List<string>();
                    for(AccountTeamMember atm: acc.AccountTeamMembers){
                        accTeamMemberIDs.add(atm.user.email);
                    }

                    OpportunityTriggerClass.createToSendEmails(acc.id, acc.Name, acc.Owner.name, acc.Owner.email, accTeamMemberIDs);
                }
            }
            OpportunityTriggerClass.sendMails();
        }
        manageForecastCategoryFirstRunFlag = false;
    }

     public static void createToSendEmails(String accId, String accName, String ownerName, String accOwnerID, List<String> accTeamMemberIDs){
        Messaging.SingleEmailMessage email =new Messaging.SingleEmailMessage();
        String[] toAddresses = new list<string> {accOwnerID};
        String url = System.URL.getSalesforceBaseUrl().toExternalForm() +'/'+accId;
        String subject ='Sandbox: TAX ID# required for Account: ' + accName;
        email.setSubject(subject);
        email.setPlainTextBody('Hello '+ownerName+', \n\n Please add TAX ID# to '+accName+' '+url+' . To create an order form, TAX ID# is required.');

        email.setToAddresses( toAddresses );
        email.setCCAddresses(accTeamMemberIDs);
        emailsToSend.add(email);
    }

    public static void sendMails() {
       Messaging.SendEmailResult [] emailResult = Messaging.sendEmail(emailsToSend);
    }

    // //SFDC-2043
    // public static void sendMail(String accId, String accName, String ownerName, String accOwnerID, List<String> accTeamMemberIDs){
    //     Messaging.SingleEmailMessage email =new Messaging.SingleEmailMessage();
    //     String[] toAddresses = new list<string> {accOwnerID};
    //     String url = System.URL.getSalesforceBaseUrl().toExternalForm() +'/'+accId;
    //     String subject ='Sandbox: GST# required for Account: ' + accName;
    //     email.setSubject(subject);
    //     email.setPlainTextBody('Hello '+ownerName+', \n\n Please add GST# to '+accName+' '+url+' . To create an order form, GST# is required.');

    //     email.setToAddresses( toAddresses );
    //     email.setCCAddresses(accTeamMemberIDs);
    //     Messaging.SendEmailResult [] emailResult = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
    // }



    /**
      CloseOldOpportunities()
      - This function is called from a scheduled Apex class and runs asynchronously (@future).
      - Make Opportunity.Stage Name = 'Closed Admin', if month and half have passed since CloseDate and the Opportunity has still not been closed.
      - This is also called from the CronKit.
     */
    //@future
    public static void CloseOldOpportunities()//Code-coverage
    {
        // Get all Opportunities that need to be closed (i.e satisfy the criteria).
        List<Opportunity> updateOpptys = [select o.Id, o.StageName, o.CloseDate, o.Validation_Override__c from Opportunity o where o.CloseDate <= :Date.today().addDays(-16) and o.StageName != 'Closed Admin' and o.StageName != 'Closed Won' and o.StageName != 'Closed Lost' LIMIT 9000];
        for(Opportunity opp : updateOpptys)
        {
            opp.Validation_Override__c = true;
            opp.StageName = 'Closed Admin';
        }
        // Update
        if(updateOpptys.size() > 0)
            update updateOpptys;
    }

    //CR 1762643 Re-schedule job to make opportunity 'Closed Admin' . - START
    /**
      PreventOppDelete()
      Allows only the following profiles to delete Opportunities
      - System Administrator
      - CRM Integration
      - Business Operations
      SFDC-2249
     */
    public static void PreventOppDelete(Opportunity[] oppList)
    {
        Set<String> allowedProfileIds = new Set<String>();
        //make profiles configurable
        //for(Profile pr:[select Id from Profile where Name='System Administrator' or Name='CRM Integration'])

        allowedProfileIds.addAll(GSMUtilClass.getGSMSettingValue('OppDeletionAllowedProfiles').split(','));
        for(Opportunity opp: oppList)
        {
            if(!allowedProfileIds.contains(UserInfo.getProfileId()))
                opp.addError('Insufficient access. Please contact System Administrator for Opportunity deletion.');
        }
    }

    /* CR 774372 Add MSS Rep to Opportunity Sales Team -- start -- */
    /**
      addOpptySalesTeam( Opportunity[] opptys )
      - @comments: Checks if Oppty CreatedById.profile matches 'Sales - Mobile Sales Specialist', if it does:
      - creates OpportunityTeamMember & adds to Oppty Sales team with TeamRole = 'MSS Primary'
      - returns: void
     */
    //SFDC-2572
    public static void addOpptySalesTeam( Opportunity[] opptys )
    {
        //SFDC-2192
        List<OpportunityTeamMember> updateOpptySalesTeamMemberList = new List<OpportunityTeamMember>();
        String teamMemberProfile = 'Channel - Primary';

        for ( Opportunity opp : opptys )
        {

            if (opp.Channel_Manager__c==null)//opp.Deal_Type__c == 'Indirect'))
                updateOpptySalesTeamMemberList.add( opptyAddSalesTeamMember( opp.Id, UserInfo.getUserId(), teamMemberProfile ) );

        }

        if (updateOpptySalesTeamMemberList.size()>0)
            GsmUtilClass.doDatabaseInsert(updateOpptySalesTeamMemberList,'OpportunityTriggerClass','addOpptySalesTeam',true);
        //insert updateOpptySalesTeamMemberList;

    }

    /**
      opptyAddSalesTeamMember(Id p_oppty_id, Id p_user_Id, String p_role)
      - @comments: Creates OpportunityTeamMember
      - @params:  p_oppty_id = Opportunity Id; p_user_Id = Oppty CreatedById; p_role = OpptyTeamMember role
      - returns: OpportunityTeamMember
     */
    public static OpportunityTeamMember opptyAddSalesTeamMember(Id p_oppty_id, Id p_user_Id, String p_role)
    {
        OpportunityTeamMember otm = new OpportunityTeamMember();  //Create a new team member
        otm.OpportunityId = p_oppty_id; //Assign the Oppty to which the member belongs to.
        otm.UserId = p_user_Id;    //Make User with p_userId, the team member.
        otm.TeamMemberRole = p_role;//Update the team role as defined in DefaulOpportunityTeamMember
        //This is done automatically :=> Check if that record already exists (no duplicates)
        return otm;
    }
    /**
      opptyAddOpportunityShareSettings(Id pOpptyId, Id pUserId, String pOpptyAccessLevel)
      - @comments: Creates OpportunityShare with required permissions
      - @params: pOpptyId = Opportunity Id; pUserId = Oppty FCM__c; pOpptyAccessLevel = Permission to be set to the User
      - returns: OpportunityShare
     *///Code-coverage
    public static OpportunityShare opptyAddOpportunityShareSettings(Id pOpptyId, Id pUserId, String pOpptyAccessLevel)
    {
        OpportunityShare os = new OpportunityShare();
        os.OpportunityId = pOpptyId;
        os.UserOrGroupId = pUserId;
        os.OpportunityAccessLevel = pOpptyAccessLevel;
        return os;//
    }

    /**
      fetchUserProfileMap ( Opportunity[] opptys )
      - @comments: Maps OpportunityCreatedById to ProfileName.
      Created to check profile name prior to creating OpptySalesTeamMember
      - returns: void
     */
    public static void fetchUserProfileMap( Opportunity[] opptys )
    {
        Boolean requiredFlag = false;
        for(Opportunity opp : opptys)
        {
            if(!userProfileMap.containsKey(UserInfo.getUserId()))
                requiredFlag = true;
        }
        if(!requiredFlag)
            return;

        Set<Id> opptyOwnerIdSet = new Set<Id>();
        for(Opportunity opp : opptys)
        {
            opptyOwnerIdSet.add(UserInfo.getUserId());
        }
        for( User usr : [select Id, Profile.Name, Sales_Overlay__c from User where Id IN :opptyOwnerIdSet OR Id = :UserInfo.getUserId()] )
        {
            userProfileMap.put(usr.Id, usr);//.Profile.Name);
        }
    }

    /**
      updateOpptyOwnerId( Opportunity[] opptys )
      - @comments: If SS is not Closed Won, Oppty.Owner = Account.Owner always for Akamai Opportunities.
      - returns: void
     */
    public static void updateOpptyOwnerId( Opportunity[] opptys, Map<Id,Opportunity> triggerOldMap, Boolean triggerIsInsert, Boolean triggerIsUpdate )
    {
        if (!updateOpptyOwnerFirstRunFlag)
            return;

        String createdByUserProfileStr='';
        // intialize userProfileMap & AccOwnerMap
        fetchUserProfileMap( opptys );
        fetchAccOwnerMap( opptys );
        if(userProfileMap.containsKey(UserInfo.getUserId()))
            createdByUserProfileStr = userProfileMap.get(UserInfo.getUserId()).Profile.Name;

        for ( Opportunity opp : opptys)
        {
            // If oppty is edited && owner is changing && profile is not sys admin
            //      then the error alert.//Code-coverage
            //SFDC-3261
            if (triggerIsUpdate && !opp.Validation_Override__c && (opp.RecordTypeId==OpportunityTriggerClass.akamaiRecTypeId
                        || opp.RecordTypeId==OpportunityTriggerClass.aweRecTypeId || opp.RecordTypeId==OpportunityTriggerClass.amgRecTypeId || opp.RecordTypeId==OpportunityTriggerClass.closedRecTypeId) && opp.OwnerId!=triggerOldMap.get(opp.id).OwnerId &&
                    createdByUserProfileStr.indexOf('System Administrator') == -1)
                opp.OwnerId.addError(Label.ErrMsg_OpptyOwnerChange);
        }

        for ( Opportunity opp : opptys )
        {
            //CR 2756406  - If account owner is changed, owner of oppty should not change when oppty stage starts with 'Closed'

            //SFDC 839- added 'opp.RecordTypeId==OpportunityTriggerClass.amgRecTypeId' condition to change oppty owner to account owner even for AMG opptys
            //SFDC-2572
            //SFDC-3261
            if((UserInfo.getProfileId().contains(GsmUtilClass.getPRMSettingValue('Channel_manager_profile_id')) || createdByUserProfileStr.indexOf( 'Sales - Mobile Sales Specialist' ) > -1 ) ||
                    ((opp.RecordTypeId==OpportunityTriggerClass.akamaiRecTypeId || opp.RecordTypeId==OpportunityTriggerClass.aweRecTypeId || opp.RecordTypeId==OpportunityTriggerClass.amgRecTypeId || opp.RecordTypeId==OpportunityTriggerClass.closedRecTypeId) && (triggerIsInsert ||
                        (triggerIsUpdate && ((opp.StageName!=triggerOldMap.get(opp.id).StageName && !triggerOldMap.get(opp.id).StageName.startsWith('Closed') && opp.StageName.startsWith('Closed') ) || !(opp.StageName.startsWith('Closed')))))))
            {
                if(acc_accOwnerMap.containsKey(opp.AccountId) && acc_accOwnerMap.get(opp.AccountId).Owner.isActive)
                    opp.OwnerId = acc_accOwnerMap.get(opp.AccountId).OwnerId;
            }

            opp.Owner__c = opp.ownerID;
            //System.debug('opp.OwnerId=' + opp.OwnerID);
            //System.debug('opp.Owner__c=' + opp.Owner__c);
        }
        updateOpptyOwnerFirstRunFlag=false;
    }

    /**
      fetchAccOwnerMap ( Opportunity[] opptys )
      - @comments: Maps Oppty AccountId to AccountOwnerId.
      - returns: void
     */
    public static void fetchAccOwnerMap( Opportunity[] opptys )
    {
        Boolean requiredFlag = false;
        for(Opportunity opp : opptys)
        {
            if(!acc_accOwnerMap.containsKey(opp.AccountId))
                requiredFlag = true;
        }
        if(!requiredFlag)
            return;

        Set<Id> accIds = new Set<Id>();
        for(Opportunity opp : opptys)
        {
            accIds.add( opp.AccountId );
        }
        for ( Account acc : [select Id, OwnerId, Owner.isActive, Account_Split__c from Account where Id IN : accIds ] )
        {
            acc_accOwnerMap.put(acc.Id, acc);
        }
    }
    /* CR 774372 Add MSS Rep to Opportunity Sales Team -- end -- */
    /* CR 842447 Automate Field Channel Manager Account assignments -- start -- */

    /**
      initilizeChannelMappingdata ()
      - @comments: Initializes channelMapping by picking all rows from Channel_Mapping__c.
      - returns: void
     */
    public static void initilizeChannelMappingdata()
    {
        //Select Id, Partner_Name__c, PAE_ID__c, VAR_Manager_Team_Role__c From Channel_Mapping__c
        for (Channel_Mapping__c cm :[SELECT Id, Partner_Name__c,Active__c, PAE_ID__c, VAR_Manager_Team_Role__c,VAR_Manager_Status__c,Temp_PAE__c,Temp_PAE__r.isActive, Global_Account_Manager6__c, Global_Account_Manager6__r.isActive FROM Channel_Mapping__c where Active__c = true])
            // Incase you need to ensure Partner Involved account had partner type use this in above select query -> AND Partner_Name__r.Partner_Type__c !=null
        {
            channelMapping.put(cm.Id, cm);
            //channelMappingAll.put(cm.Id, cm);
        }
    }
    /**
      fetchChannelManagerIds (Opportunity opp)
      - @params: Receives an Opportunity
      - @comments: Looks up Channel_Mapping Map - channelMapping for matching 'opp partner involved' entries
      - returns: Returns a list of channel Mapping Ids
     */
    public static List<Id> fetchChannelManagerIds(Opportunity opp)
    {
        List<Id> channelMappingIds = new List<Id>();
        if (channelMapping.isEmpty())
            return channelMappingIds;
        for (Id id : channelMapping.keySet())
        {
            if (channelMapping.get(id).Partner_Name__c == opp.Partner_Involved__c)
                channelMappingIds.add(id);
        }
        return channelMappingIds;
    }
    /**
      channelManagerCheck_BeforeTrigger (Opportunity[] opptys)
      - @comments: Checks if opp.Partner_Involved__c has any matching Channel_Mapping__c instance.
      - If no Channel_Mapping__c instance is found: returns without doing anything
      - If 01 Channel_Mapping__c instance is found: add it to Oppty.Channel_Manager
      - If Multiple Channel_Mapping__c instance is found: validation kicks in prompting user to select an entry out of multiple choices.
      - If Channel_Manager__c is initialized, in afterTrigger code corresponding PAE_ID__c is added to Oppty SalesTeam.
      - returns: void
     */
    public static void channelManagerCheck_BeforeTrigger ( Opportunity[] opptys )
    {
        if (!channelManagerCheckFirstRunFlag)
            return;
        //if (channelMapping.isEmpty())
        initilizeChannelMappingdata();
        initializeCurrentUserRecord();
        String strProfileUserTypeExceptions = GsmUtilClass.getGSMSettingValue('OpptyTrigger_Exception_ProfileUsrTyp'); //SFDC-2304
        for (Opportunity opp: opptys)
        {
            //SFDC-3261
            if (opp.Channel_Manager__c == null && (opp.RecordTypeId == akamaiRecTypeId || opp.RecordTypeId == closedRecTypeId))
            {
                // fetch Channel Manager Ids
                List<Id> CMIds = fetchChannelManagerIds(opp);
                if(CMIds.isempty())
                    continue;
                if (CMIds.size() == 1)
                {
                    opp.Channel_Manager__c = CMIds.get(0);
                }
                // fetch the profile.userType and give override if it contains 'Partner'
                else if ( !opp.Validation_Override__c && CMIds.size() > 1 && currentUserRecord != null && !strProfileUserTypeExceptions.contains(currentUserRecord.Profile.UserType)) //CustomSetting Value = 'PowerPartner'
                {
                    opp.Channel_Manager__c.addError(GsmUtilClass.getGSMSettingValue('OpptyTrigger_Error_MissingFCM')); //SFDC-2304
                    //System.debug('oppId=' + opp.Id + ', Validation Override=' + opp.Validation_Override__c);
                }
            }
        }
        channelManagerCheckFirstRunFlag = false;
    }


    //Sonali Tandon
    public static void createAutomatedActivities(Opportunity[] opptyList, Map<Id, Opportunity> oppOldMap, Map<Id, Opportunity> oppNewMap)
    {
        if(createAutomatedActivitiesFirstRunFlag== false)
            return;

        Map<Id,Id> mapOfOpptyIdToAccountId = new Map<Id,Id>();

        for(Opportunity oppty : opptyList)
            mapOfOpptyIdToAccountId.put(oppty.Id,oppty.AccountId);
        CreateQuickActivitiesClass.quickActivityFromTrigger('Trigger', opptyList,oppOldMap,mapOfOpptyIdToAccountId);


        createAutomatedActivitiesFirstRunFlag = false;


    }

    /**
      channelManagerCheck_AfterTrigger( Opportunity[] opptys )
      - @comments: This method is called if new Channel_Manager__c is added/updated to an Oppty
      - Fetches Channel_Manager UserId; TeamRole from channelMapping mapper & Inserts as Oppty-SalesTeamMember for respective opportunity.
      - returns: void
     */
    public static void channelManagerCheck_AfterTrigger( Opportunity[] opptys )
    {
        List<OpportunityTeamMember> addOpptySalesTeamMemberList = new List<OpportunityTeamMember>();
        List<OpportunityShare> updateOpptyShareSettingsList = new List<OpportunityShare>();
        Map<Id, Id> delegatedApprovers = new Map<Id,Id>();
        String delegatedApproverRole = GsmUtilClass.getGSMSettingValue('OpptyTriggerClass_DelegatedApprover'); //SFDC-2304

        for (Opportunity o : [Select id, Channel_Manager__r.PAE_ID__r.DelegatedApproverId FROM Opportunity WHERE id IN :opptys])
        {
            if(o.Channel_Manager__r.PAE_ID__r.DelegatedApproverId != null)
                delegatedApprovers.put(o.id, o.Channel_Manager__r.PAE_ID__r.DelegatedApproverId);
        }

        // initialize Channel Mapping rows
        if (channelMapping.isEmpty())
            initilizeChannelMappingdata();//Code-coverage
        for (Opportunity opp : opptys)
        {
            // INACTIVE OWNER OR USER bug fix -- start --
            if (channelMapping.get(opp.Channel_Manager__c)!=null)
            {//if Temp PAE is not added then add var manager to the sales team
                //SFDC-2192 - optimize this code to have single criteria check.
                if((channelMapping.get(opp.Channel_Manager__c).Temp_PAE__c==null && channelMapping.get(opp.Channel_Manager__c).VAR_Manager_Status__c=='Active')||(channelMapping.get(opp.Channel_Manager__c).Temp_PAE__c!=null && channelMapping.get(opp.Channel_Manager__c).Temp_PAE__r.isActive==TRUE))
                {
                    //addOpptySalesTeamMemberList.add ( opptyAddSalesTeamMember (opp.Id, channelMapping.get(opp.Channel_Manager__c).PAE_ID__c, channelMapping.get(opp.Channel_Manager__c).VAR_Manager_Team_Role__c ) );
                    if(delegatedApprovers.get(opp.Id) != null)
                        addOpptySalesTeamMemberList.add ( opptyAddSalesTeamMember (opp.Id, delegatedApprovers.get(opp.Id),  delegatedApproverRole));//Code-coverage
                    //CR 1396306: Provide Edit Access to Users being added to Sales Team
                    //if(opp.OwnerId != channelMapping.get(opp.Channel_Manager__c).PAE_ID__c)
                    //  updateOpptyShareSettingsList.add(opptyAddOpportunityShareSettings(opp.Id,channelMapping.get(opp.Channel_Manager__c).PAE_ID__c,'Edit'));
                    if(delegatedApprovers.get(opp.Id) != null && opp.OwnerId != delegatedApprovers.get(opp.Id))
                        updateOpptyShareSettingsList.add(opptyAddOpportunityShareSettings(opp.Id,delegatedApprovers.get(opp.Id),'Edit'));    //Code-coverage
                }// if PAE is inactive , add the temp PAE to the sales team
            }
        }
        if (addOpptySalesTeamMemberList.size()>0)
        {
            Database.SaveResult[] MySaveResult = database.insert(addOpptySalesTeamMemberList,false); //Code-coverage
        }
        if (updateOpptyShareSettingsList.size()>0)
        {
            Database.SaveResult[] MySaveResult = database.insert(updateOpptyShareSettingsList,false); //Code-coverage
        }
    }

    /**
      updateShiftedDate(List<Opportunity> opportunityShifteddateToBeUpdated)
      Requirement -> Shift by two business days
      -> this method will shift the Akam created date by 'x' number of days based on the day it is created, previously it is shifted constantly by two days.
      -> Logic if the Akam created day is mon,tue,wed then shifting by two days will result in a business day,but shifting thu,fri,sat by 2 days will result in a weekend.
      -> so, we will conditionally check the day and increment by 'y' number of days according to day of the date, so that it will result in a weekday.
      -> Shited_Date field will be used to Auto route leads if they are not assigned until this date.
     */
    public static void updateShiftedDate(Opportunity[] opportunities)
    {
        if (!updateOpportunityShiftedDateFirstRunFlag)
            return;
        for(Opportunity ithOppty : opportunities)
        {
            ithOppty.Shifted_Created_date__c = ithOppty.AKAM_Created_Date__c.addDays(GsmUtilClass.getNumberOfDaysToShift(ithOppty.AKAM_Created_Date__c));
        }
        updateOpportunityShiftedDateFirstRunFlag = false;
    }

    /*updateOpptyStageForAMG(List<Opportunity> opportunityStatusToBeUpdated)
      SFDC-839:
      Update Opportunity stage to closed admin, when Amg Opportunity status is set to rejected for Amg Opportunity
     */
    public static void updateOpptyStageForAMG(List<Opportunity> opportunityStatusToBeUpdated){
        for(Opportunity oppty : opportunityStatusToBeUpdated ){
            oppty.Validation_Override__c = true;//Code-coverage
            oppty.StageName = 'Closed Admin';//
        }
    }
    //Code-coverage
    public static void checkForInactiveUser(List<Opportunity> opptys)
    {
        Set<id> accts = new Set<id>();
        Set<id> erroraccts = new Set<id>();
        for(Opportunity opp : opptys){
            accts.add(opp.accountId);
        }

        //Check if acct Owner is Active
        list<Account> o = new List<Account>();
        o = [Select id, owner.isActive from Account where id IN :accts];

        for(Account a:o){
            if(a.owner.isActive == false){
                erroraccts.add(a.id);
            }
        }

        for(Opportunity opp : opptys){
            if(erroraccts.contains(opp.accountId)){
                opp.adderror('Opportunities cannot have an account with an inactive owner. On the account page click on the "Reassign Button" to reassign the account an active user.');
            }
        }
    }

    /**
      sendEmailWhenClosedWon( Opportunity[] opptys)
      - @comments: When ANY Opportunity is Closed/Won and Oppty.Contract # is NOT null
      A.  Send individual emails to internal sales team, account team, and POA email list with internal SF link
      B.  Send individual emails to partner sales team, account team, POA list with partner friendly link
      C.  Users should be able to shut off these emails if so desired.
      D.  Subject:  [Opportunity.Name] has been processed.  Contract # is: [Opportunity.Contract #]
      E.   Akamai Branding should be used for the partner emails
      F.   Email sent with CRM-ops as FROM address
      - returns: void
     */
    public static void sendEmailWhenClosedWon( Opportunity[] opptys)
    {
        if(!sendEmailWhenClosedWonFirstRunFlag)
            return;
        string AkamaiEmailIdentifier = GsmUtilClass.getGSMSettingValue('OpptyTriggerClass_AkamaiIdentifier'); //SFDC-2304
        string SendEmailWhenClosedWonFlag = GsmUtilClass.getGSMSettingValue('OpptyTriggerClass_SendEmailClosedWon'); //SFDC-2304
        //SFDC-2572
        string PartnerPortalOrgWideId = GsmUtilClass.getPRMSettingValue('Partner_Portal_Email_Id');
        String emailHeader=GsmUtilClass.getGSMSettingValue('CFA_SendEmailController_EmailHeader'); //SFDC-2304
        String emailfooter=GsmUtilClass.getGSMSettingValue('CFA_SendEmailController_Emailfooter'); //SFDC-2304
        string PartnerSfURL='';
        string SfURL='';
        // a map of oppty and Account team member
        map<Id,list<AccountTeamMember>> AccAccountTeamMap = new map<id,list<AccountTeamMember>>();
        // a map of oppty and sales team member
        map<Id,list<OpportunityTeamMember>> OpptySalesTeamMap = new map<id,list<OpportunityTeamMember>>();
        // a list of OpportunityIds
        list<Id> opttylist = new list<Id>();
        // a list of AccountIds
        list<Id> AccountIdslist = new list<id>();
        // A map of id and Opportunity
        map<Id,Opportunity> idOpportunityMap = new map<id,Opportunity>();
        // Set the Partner url and internal salesforce url
        if(PartnerSfURL=='' || SfURL=='')
        {
            if (Test.isRunningTest()) {
                //PartnerSfURL= GSM_Custom_Settings__c.getInstance('CFA_SendEmailController#SfUrl').Value__c; //SFDC-2304
                //SfURL=GSM_Custom_Settings__c.getInstance('CFA_SendEmailController#SfUrl').Value__c; //SFDC-2304
                PartnerSfURL= GsmUtilClass.getGSMSettingValue('CFA_SendEmailController_SfUrl'); //SFDC-2304
                SfURL=GsmUtilClass.getGSMSettingValue('CFA_SendEmailController_SfUrl'); //SFDC-2304
            }
            else{
                Organization org=[select Fax,Division from Organization limit 1][0];
                PartnerSfURL=org.Fax;
                SFURL=org.Division;
            }
        }
        //Get the email template that needs to be used
        EmailTemplate EmTempInternal=null;
        EmailTemplate EmTempPartner=null;
        for(EmailTemplate em:[select Body,Subject,DeveloperName from EmailTemplate where DeveloperName='Email_When_Oppty_is_closed_Won' or DeveloperName='Email_When_Oppty_is_closed_Won_Partner'])
        {
            if(em.DeveloperName=='Email_When_Oppty_is_closed_Won')
                EmTempInternal=em;
            if(em.DeveloperName=='Email_When_Oppty_is_closed_Won_Partner')
                EmTempPartner=em;
        }
        system.assertNotEquals(EmTempInternal,null);
        system.assertNotEquals(EmTempPartner,null);
        for(Opportunity opp:opptys)
        {
            opttylist.add(opp.id);
            if(opp.AccountId!=null)
                AccountIdslist.add(opp.AccountId);
        }
        //Get all account team member for the opportunity
        //SFDC-2572 - Modified query to add conditions checked in if construct
        for(AccountTeamMember ctm:[select id,User.Email,TeamMemberRole,AccountId,User.Receive_email_when_Oppty_is_Closed_Won__c from AccountTeamMember where AccountId IN :AccountIdslist and User.Isactive=true and User.Receive_email_when_Oppty_is_Closed_Won__c=true and TeamMemberRole!='CMG - Analyst'])
        {
            if(AccAccountTeamMap.get(ctm.accountid)==null)
            {
                list<AccountTeamMember> atm=new list<AccountTeamMember>();
                atm.add(ctm);
                AccAccountTeamMap.put(ctm.AccountId,atm);
            }
            else
            {
                AccAccountTeamMap.get(ctm.accountid).add(ctm);
            }
        }
        system.debug('AccAccountTeamMap:'+AccAccountTeamMap);
        // Get all the same team members for the oppty
        //SFDC-2572 - Modified query to add conditions checked in if construct
        for(OpportunityTeamMember ctm:[select id,User.Email,TeamMemberRole,OpportunityId,User.Receive_email_when_Oppty_is_Closed_Won__c from OpportunityTeamMember where OpportunityId IN :opttylist  and User.Isactive=true and User.Receive_email_when_Oppty_is_Closed_Won__c=true and TeamMemberRole!='CMG - Analyst'])
        {
            if(OpptySalesTeamMap.get(ctm.OpportunityId)==null)
            {
                list<OpportunityTeamMember> atm=new list<OpportunityTeamMember>();
                atm.add(ctm);
                OpptySalesTeamMap.put(ctm.OpportunityId,atm);
            }
            else
            {
                OpptySalesTeamMap.get(ctm.OpportunityId).add(ctm);
            }
        }
        system.debug('OpptySalesTeam:'+OpptySalesTeamMap);
        // get more details from the oppty
        for(Opportunity opp:[select id,Account.Name,Partner_Involved__r.POA_Email_List__c from Opportunity where id IN :opttylist])
        {
            idOpportunityMap.put(opp.id,opp);
        }


        Messaging.SingleEmailMessage[] sendEmailList = new List<Messaging.SingleEmailMessage>();
        for(Opportunity opp:opptys)
        {
            // using set as emails might be repeated
            set<string> intEmails = new set<string>();
            set<string> partnerEmails = new set<string>();
            // Add all sales team members
            if(opp.AccountId!=null && AccAccountTeamMap.get(opp.AccountId)!=null)
            {
                for(AccountTeamMember atmSingle:AccAccountTeamMap.get(opp.AccountId))
                {
                    if(atmSingle.User.Receive_email_when_Oppty_is_Closed_Won__c && atmSingle.TeamMemberRole!='CMG - Analyst')
                    {
                        if(atmSingle.TeamMemberRole!='Partner' && atmSingle.User.Email.contains(AkamaiEmailIdentifier))
                            intEmails.add(atmSingle.User.Email);
                        else
                            partnerEmails.add(atmSingle.User.Email);
                    }
                }
            }
            // add all account team members
            if(OpptySalesTeamMap.get(opp.id)!=null)
            {
                for(OpportunityTeamMember otmSingle:OpptySalesTeamMap.get(opp.id))
                {
                    if(otmSingle.User.Receive_email_when_Oppty_is_Closed_Won__c && otmSingle.TeamMemberRole!='CMG - Analyst')
                    {
                        if(otmSingle.TeamMemberRole!='Partner' && otmSingle.User.Email.contains(AkamaiEmailIdentifier))
                            intEmails.add(otmSingle.User.Email);
                        else
                            partnerEmails.add(otmSingle.User.Email);
                    }
                }
            }
            // add the emails in POA email list
            if(opp.Partner_Involved__c!=null)
            {
                if(idOpportunityMap.get(opp.id).Partner_Involved__r.POA_Email_List__c!=null)
                {
                    for(string eml:idOpportunityMap.get(opp.id).Partner_Involved__r.POA_Email_List__c.replace(' ','').split(','))
                    {
                        if(eml.contains(AkamaiEmailIdentifier))
                            intEmails.add(eml);
                        else
                            partnerEmails.add(eml);
                    }
                }
            }
            // Prepare the Email subject and Body
            // For internal Users
            string SubjectText=EmTempInternal.Subject;
            string bodyText=EmTempInternal.Body;
            //SFDC-2572
            SubjectText = getModifiedText(SubjectText,opp,idOpportunityMap);
            bodyText = getModifiedText(bodyText,opp,idOpportunityMap);

            bodyText=bodyText.replace('#opptylink#',SfURL+'/'+opp.id); //if internal user , show internal user link

            string htmlBodyText=bodyText.replace('\n','<br/>');

            // For Partner Users
            string partnerSubjectText=EmTempPartner.Subject;
            string partnerBodyText=EmTempPartner.Body;
            //SFDC-2572
            partnerSubjectText = getModifiedText(partnerSubjectText,opp,idOpportunityMap);
            partnerBodyText = getModifiedText(partnerBodyText,opp,idOpportunityMap);
            // SFDC-9285 - adding new lines
            partnerBodyText = partnerBodyText+'<br/>'+'<br/>';
            // SFDC-9133
            partnerBodyText = getRebateModifiedText(partnerBodyText,opp,true);
            partnerBodyText=partnerBodyText.replace('#opptylink#',PartnerSfURL+'/'+opp.id); //if partner , show partner friendly link

            string partnerHtmlBodyText=emailHeader+partnerBodyText.replace('\n','<br/>')+'<br/>'+emailfooter;

            // Prepare the emails depending whether it is Partner or Internal
            if(intEmails.size()>0)
            {
                for(string emlSingle:intEmails)
                    sendEmailList.add(GsmUtilClass.createSingleEmailWithOrgId(emlSingle,'',SubjectText,bodyText,htmlBodyText,''));
            }
            if(partnerEmails.size()>0)
            {
                for(string emlSingle:partnerEmails)
                    sendEmailList.add(GsmUtilClass.createSingleEmailWithOrgId(emlSingle,'',partnerSubjectText,partnerBodyText,partnerHtmlBodyText,PartnerPortalOrgWideId));
            }


        }
        if (sendEmailList.size()>0 && SendEmailWhenClosedWonFlag=='True')
            Messaging.sendEmail(sendEmailList);
        system.debug('EmailList:'+sendEmailList);
        NoOfEmailsSentWhenClosedWon=sendEmailList.size();
        sendEmailWhenClosedWonFirstRunFlag=false;
    }
    //SFDC-2572
    private static string getModifiedText(String text,Opportunity opp,map<Id,Opportunity> idOpportunityMap){
        text = text.replace('#OpptyName#', opp.Name);
        text = text.replace('#OpptyContractNo#', opp.Contract_ID__c);
        //if(textType.equalsIgnoreCase('Body')){
        text = text.replace('#OpptyAccountName#', idOpportunityMap.get(opp.id).Account.Name);
        //}
        return text;
    }
   // SFDC-9133
   public static string getRebateModifiedText(String text,Opportunity opp, Boolean isClosedWon){
    String rebateText ='';
    String drRebateEligibleAccStatus = GsmUtilClass.getPRMSettingValue('DRRebateEligibleAccountDRStatus');
    List<String> rebateEligibleAccStatus = drRebateEligibleAccStatus.split(',');
    if(isClosedWon){
         Map<String, String> prmSettingMap = GSMUtilClass.getPRMSettingKeyValue('Rebate_Text');
         for(String prmValue : prmSettingMap.values()){

            rebateText += '<br/>'+'<br/>'+prmValue;
         }

    }
    else 
        rebateText = text;
    if(rebateText.contains('#OpptyName#'))
        rebateText = rebateText.replace('#OpptyName#', opp.Name);
    if(rebateText.contains('#PER#')){
        rebateText = rebateText.replace('#PER#', opp.rebate__c+'%');
        system.debug(LoggingLevel.Error,'opp.rebate__c:: '+opp.rebate__c);
    }
    if(rebateText.contains('#LEN#')){
        rebateText = rebateText.replace('#LEN#', (opp.Contract_Length__c!=null) ? String.valueOf(opp.Contract_Length__c) : '');
        rebateText += '<br/>'+'<br/>';
    }
        system.debug(LoggingLevel.Error,'rebateText:: '+rebateText);
    // rebate text should be added to closed won email, only if the DR is approved in 2022 and DR account status is new account or existing account.
    if(opp.rebate__c!= null && opp.rebate__c!= '0' && isClosedWon && opp.Deal_Registration_Approved_Date__c!=null && opp.Deal_Registration_Approved_Date__c.Year() >=2022 && rebateEligibleAccStatus!=null && rebateEligibleAccStatus.contains(opp.Deal_Reg_Account_Status__c))
        text = text.replace('#Rebate_Text#', rebateText);
    else if(!isClosedWon)
        text = rebateText;
    else
        text  = text.replace('#Rebate_Text#', '');
        system.debug(LoggingLevel.Error,'text:: '+text);
    //if(textType.equalsIgnoreCase('Body')){
    // text = text.replace('#OpptyAccountName#', idOpportunityMap.get(opp.id).Account.Name);
    //}
    return text;
}
    /**
      createTaskWhenSalesStage6( Opportunity[] opptys)
      - @comments: CR 1352333 Workflow not firing when Oppty Sales Stage changes to 6
      Task is created by code instead of workflow
      - returns: void

      SFDC-1922 - Removing the logic related to Apptus since that feature is depecrated now
     **/

    public static void createTaskWhenSalesStage6( Opportunity[] opptys)
    {
        if(!createTaskWhenSalesStage6FirstRunFlag)
            return;
        string SS6TaskSubject = GsmUtilClass.getGSMSettingValue('OpptyTrigger_SS6TaskSubject'); //SFDC-2304
        list<task> newTasks=new list<task>();
        List<Task> openRCETasks = new List<Task>();
        list<Id> agreementIds = new list<Id>();
        map<id,task> OpptyIdTaskMap=new map<id,task>();
        map<id,Boolean> OpptyidActiveMap = new map<id,Boolean>();
        map<id,id> OpptyidManagerMap = new map<id,id>();
        map<id,id> AccountidCMGAnalystMap = new map<id,id>();
        list<id> AccountIds = new list<id>();
        List<Id> subscriptionIds = new List<Id>();
        Map<Id, String> agreementTerminationMsg = new Map<Id, String>();
        Map<Id, Id> opptyAggrementMap = new Map<Id, Id>();
        Map<Id, Integer> accountAssetLineItemCount = new Map<Id, Integer>();
        Map<Id, Integer> accountAgreementLineItemCount = new Map<Id, Integer>();
        for(Task t:[select id,WhatId from Task where Subject=:SS6TaskSubject and WhatId IN :Opptys and IsClosed=false])
            OpptyIdTaskMap.put(t.WhatId,t);
        for(Opportunity o:[select id,Owner.isActive,Owner.Managerid,AccountId from Opportunity where id IN :Opptys])
        {
            OpptyidActiveMap.put(o.id,o.Owner.isActive);
            OpptyidManagerMap.put(o.id,o.Owner.Managerid);
            AccountIds.add(o.AccountId);
        }
        // Start of Code :CR 2890362 Inactive CMG Analyst: Opptys cannot be moved to stage 6
        //Added the User.isActive field in the query to avoid the inactive user not to be in the map.

        for (AccountTeamMember atm:[Select AccountId, UserId , User.isActive from AccountTeamMember where AccountId IN :AccountIds and TeamMemberRole='CMG - Analyst'])
        {
            if(atm.User.isActive == true) {
                AccountidCMGAnalystMap.put(atm.AccountId,atm.UserId);
                break;
            }
        }
        // End of Code: CR 2890362 Inactive CMG Analyst: Opptys cannot be moved to stage 6
        //Added the User.isActive field in the query to avoid the inactive user not to be in the map.

        for(Opportunity opp:opptys)
        {
            // if STP Agreement, don't create SS6 Task.
            if(OpptyIdTaskMap.get(opp.id)==null)
            {

                //if associated accout has an accout team member who is a CMG Analyst, then assign the task to the CMG Analyst
                //HC- Removed the Task Body since that is dependent on Agreements on Oppty which is a depractaed feature
                if(AccountidCMGAnalystMap.containsKey(opp.AccountId))
                {
                    newTasks.add(createtask(AccountidCMGAnalystMap.get(opp.AccountId),opp.id,SS6TaskSubject,'','Not Started'));
                }

                //if owner is active. Assign the task to owner
                else if(OpptyidActiveMap.get(opp.id)!=null && OpptyidActiveMap.get(opp.id))
                {
                    newTasks.add(createtask(opp.ownerid,opp.id,SS6TaskSubject,'','Not Started'));
                }
                else if(OpptyidManagerMap.get(opp.id)!=null)
                {//else if manager exists then assign the task to manager
                    newTasks.add(createtask(OpptyidManagerMap.get(opp.id),opp.id,SS6TaskSubject,'','Not Started'));
                }
                else
                {//else assign the task to current user
                    newTasks.add(createtask(Userinfo.getUserId(),opp.id,SS6TaskSubject,'','Not Started'));//
                }

            }
            else
            {

                //SFDC-1362
                Task updateDueDateTask = OpptyIdTaskMap.get(opp.Id);
                updateDueDateTask.ActivityDate = datetime.now().date().addDays(2);
                openRCETasks.add(updateDueDateTask);
            }
        }

        if(newTasks.size()>0)
        {
            System.debug('newTasks : '+newTasks);
            insert newTasks;
        }

        if(openRCETasks.size() > 0)
        {
            update openRCETasks;
        }
        //End of SFDC-1362


        createTaskWhenSalesStage6FirstRunFlag=false;
    }


    //Code-coverage
    public static void managerSwarmOpptys( Opportunity[] opptys){
        //String channelManager = '';
        //Id akamaiRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Akamai Opportunity').getRecordTypeId();

        List<EntitySubscription> subs = new List<EntitySubscription>();
        List<FeedItem> feeds = new List<FeedItem>();
        Opportunity opp;
        String url;
        Organization org = [Select Division from Organization limit 1];//SFDC-2393
        url = org.Division;


        for (Opportunity o : [SELECT id, Name,Account.name, owner__r.ManagerId,owner__r.Manager.Name, StageName, Channel_Manager__c, Channel_Manager__r.id, Channel_Manager__r.PAE_ID__c, Channel_Manager__r.PAE_ID__r.ManagerId,Channel_Manager__r.PAE_ID__r.Manager.Name  FROM Opportunity WHERE id IN :opptys]){

            if(o!= null){
                opp = o;

                Map<ID,String> managers = new Map<ID,String>();

                managers.put(o.owner__r.ManagerId, o.owner__r.Manager.Name);
                if(o.Channel_Manager__r.PAE_ID__r.ManagerId != null)
                    managers.put(o.Channel_Manager__r.PAE_ID__r.ManagerId,o.Channel_Manager__r.PAE_ID__r.Manager.Name );


                for(String managerId : managers.keyset()){

                    EntitySubscription es = new EntitySubscription(parentId = opp.id, SubscriberId = managerId);

                    subs.add(es);
                    FeedItem notification = new FeedItem();
                    notification.type = 'TextPost';
                    notification.ParentId = opp.id;
                    notification.Title = 'Added to Opportunity';
                    notification.Body = managers.get(managerId) + ' is now automatically following this opportunity since it is currently at sales stage '+ opp.stageName +' and related to the following account, ' + opp.Account.name ;
                    feeds.add(notification);
                }
            }

        }


        Database.SaveResult[] lsr = Database.insert(subs,false);
        List<FeedItem> feeds_db = new List<FeedItem>();
        integer index = 0;
        for(Database.SaveResult sr:lsr){


            if(sr.isSuccess())
            {
                feeds_db.add(feeds[index]);
            }

            index++;
        }

        Database.SaveResult[] fsr = Database.insert(feeds_db,false);

    }

    //SFDC-1334 - As discussed with BSA, this functionality (sendEmailtoCampaignOwner) is no more needed hence removing this code.
    // Ali changes for CR 1768502 - END -
    //Code-coverage
    //Changes for CR 1760780 Customer Save Program - Parent CR
    public static void populateRenewalOpptyFields(List<Opportunity> opptyList)
    {
        if(!populateRenewalOpptyFieldsFirstRunFlag)
            return;

        Set<String> PartnerInvolvedAKAMIdSet = new Set<String>();
        Set<String> contractIdSet = new Set<String>();
        Map<String,Channel_Mapping__c> partnerInvolvedIdCMMap = new Map<String,Channel_Mapping__c>();
        Map<String,Merge_Contract_Header__c> contractIdContractMap = new Map<String,Merge_Contract_Header__c>();
        Set<Date> effectiveEndDateSet=new Set<Date>(); //Added by Chandra for CR 2582211
        for(Opportunity o: opptyList)
        {
            if(o.Partner_Involved_AKAM_Id__c != null && o.Partner_Involved_AKAM_Id__c !='' && o.Deal_Type__c == 'Indirect')
                PartnerInvolvedAKAMIdSet.add(o.Partner_Involved_AKAM_Id__c);
            if(o.Renew_Contract_Id_Text__c != null && o.Renew_Contract_Id_Text__c !='')
                contractIdSet.add(o.Renew_Contract_Id_Text__c);
            if(o.Contract_Effective_End_Date__c !=null)   // Added by Chandra for CR 2582211 to add contract effective end date to check for duplicates
                effectiveEndDateSet.add(o.Contract_Effective_End_Date__c);
        }

        //System.debug('PartnerInvolvedAKAMIdSet size = '+PartnerInvolvedAKAMIdSet.size());
        //System.debug('contractIdSet size = '+contractIdSet.size());

        if(PartnerInvolvedAKAMIdSet.size() > 0)
        {
            // System.debug('PartnerInvolvedAKAMIdSet = '+PartnerInvolvedAKAMIdSet);
            for(Channel_Mapping__c c: [SELECT Id, Name, Partner_Name__r.Id, Partner_Name__r.AKAM_Account_Id__c, Master_Channel_Mapping__c FROM Channel_Mapping__c WHERE Partner_Name__r.AKAM_Account_Id__c IN: PartnerInvolvedAKAMIdSet AND Partner_Name__r.Partner_Type__c != null AND Partner_Name__r.Partner_Type__c !='' AND Master_Channel_Mapping__c = true])
                partnerInvolvedIdCMMap.put(c.Partner_Name__r.AKAM_Account_Id__c,c);

            // System.debug('partnerInvolvedIdCMMap size = '+partnerInvolvedIdCMMap.size());

            if(partnerInvolvedIdCMMap.size() > 0)
            {
                // System.debug('partnerInvolvedIdCMMap = '+partnerInvolvedIdCMMap);

                for(Opportunity o: opptyList)
                {
                    if(o.Partner_Involved_AKAM_Id__c != null && o.Partner_Involved_AKAM_Id__c != '' && o.Deal_Type__c == 'Indirect')
                    {
                        if(partnerInvolvedIdCMMap.get(o.Partner_Involved_AKAM_Id__c) != null && partnerInvolvedIdCMMap.get(o.Partner_Involved_AKAM_Id__c).Master_Channel_Mapping__c)
                        {
                            o.Partner_Involved__c = partnerInvolvedIdCMMap.get(o.Partner_Involved_AKAM_Id__c).Partner_Name__r.Id;
                            o.Channel_Manager__c = partnerInvolvedIdCMMap.get(o.Partner_Involved_AKAM_Id__c).Id;
                        }
                        else{
                            if(!ByPassAndLimitUtils.isDisabled('disableChannelManagerLogicRenewalBatchJob')){
                                    o.addError('There is no Master Channel Mapping associated for this account');
                                }
                        }
                    }
                }
            }
            else
            {
                for(Opportunity o:opptyList)
                {
                    if(!ByPassAndLimitUtils.isDisabled('disableChannelManagerLogicRenewalBatchJob')){
                        if(o.Partner_Involved_AKAM_Id__c != null && o.Partner_Involved_AKAM_Id__c != '' && o.Deal_Type__c == 'Indirect'){
                            o.addError('There are no Master channel mappings associated with this account');
                        }
                    }
                }
            }
        }
        //SFDC-1394 Removed renewal contract lookup stamping and checkForDuplicateRenewalOpportunity()

        populateRenewalOpptyFieldsFirstRunFlag = false;
    }


    public static void removePartnersFromSalesTeam(List<Opportunity> partnerInvolvedChangedList,Map<Id,Id> opportunityIdOldPartnerInvolvedIdMap)
    {
        if(removePartnersFromSalesTeamForOldPartnerInvloved)
        {
            List<OpportunityTeamMember> partnerSalesList=[select Id,OpportunityId,TeamMemberRole,User.Contact.AccountId from OpportunityTeamMember where OpportunityId IN : partnerInvolvedChangedList and TeamMemberRole ='Partner'];
            List<OpportunityTeamMember> opptyTeamMemberToRemove=new List<OpportunityTeamMember>();
            for(OpportunityTeamMember otm :partnerSalesList)
            {//Code-coverage
                Id oldPartnerInvlovedId=opportunityIdOldPartnerInvolvedIdMap.get(otm.OpportunityId);
                if(otm.User.contact.AccountId==oldPartnerInvlovedId)
                    opptyTeamMemberToRemove.add(otm);//
            }
            if(opptyTeamMemberToRemove.size()>0)
                delete opptyTeamMemberToRemove;//
            removePartnersFromSalesTeamForOldPartnerInvloved=false;
        }

    }

    public static String checkUnderSharingForPartners()
    {
        String result='1:';
        try
        {
            List<UserRole> userRoleIds=[SELECT Id,portalAccountId FROM UserRole where portalAccountId!=null and Name like '%Executive'];
            Map<Id,Id> roleIdGroupIdMap=new Map<Id,Id>();
            List<Group> partnerGroupList=[select Id,relatedId from Group where relatedId IN :userRoleIds and Type = 'RoleAndSubordinates'];
            for(Group g: partnerGroupList)
            {
                roleIdGroupIdMap.put(g.relatedId,g.Id);
            }
            Map<Id,Id> partnerGroupIdAccountIdMap=new Map<Id,Id>();
            Map<Id,Id> partnerAccountIdGroupIdMap=new Map<Id,Id>();
            for(UserRole ur: userRoleIds)
            {
                partnerGroupIdAccountIdMap.put(roleIdGroupIdMap.get(ur.Id),ur.PortalAccountId);
                partnerAccountIdGroupIdMap.put(ur.PortalAccountId,roleIdGroupIdMap.get(ur.Id));
            }
            System.debug('partnerAccountIdGroupIdMap======'+partnerAccountIdGroupIdMap);
            //List<OpportunityShare> opptySharesToBeDeleted=new List<OpportunityShare>();
            //Opportunity share for Partners
            List<SFDC_Budget__c> activeFundBudgets=[select id,Account__c,Account__r.ParentId from SFDC_Budget__c where Active__c=true];

            List<SFDC_Budget__Share> fundBugetShareList=[select Id,UserOrGroupId,ParentId,Parent.Account__c,Parent.Account__r.ParentId
                from SFDC_Budget__Share
                where userOrGroupId in :partnerGroupList
                and RowCause='Manual'
                and ParentId IN : activeFundBudgets];

            System.debug('fundBugetShareList======'+fundBugetShareList);
            String fundBudgetSharesToBeCreatedString='';
            List<SObject> oversharedRecordsToBeDeleted = new List<SObject>();
            List<SFDC_Budget__Share> fundBudgetSharestoBeCreated=new List<SFDC_Budget__Share>();// Added By chandra 06/25/2014 for CR 2631630


            Map<Id,List<SFDC_Budget__Share>> budgetIdShareListMap=new Map<Id,List<SFDC_Budget__Share>>();
            Map<Id,Id> budgetIdAccountIdMap=New Map<Id,Id>();

            for(SFDC_Budget__Share fbShare: fundBugetShareList)
            { //Code-coverage
                Id UserGroupAccountId=partnerGroupIdAccountIdMap.get(fbShare.UserOrGroupId);
                // Start : Added by chandra for CR 2631630
                List<SFDC_Budget__Share> individualFundBudgetShareList=null;
                if(!budgetIdShareListMap.keyset().contains(fbShare.parentId))
                {
                    individualFundBudgetShareList=new List<SFDC_Budget__Share>();
                }
                else
                {
                    individualFundBudgetShareList=budgetIdShareListMap.get(fbShare.parentId);
                }
                individualFundBudgetShareList.add(fbshare);
                budgetIdShareListMap.put(fbShare.parentId,individualFundBudgetShareList);
                system.debug('fund Budget Id: '+fbshare.parentId+'===individualFundBudgetShareList:'+individualFundBudgetShareList);
                budgetIdAccountIdMap.put(fbShare.Id,fbShare.parentId);
                // End : Added by chandra for CR 2631630

            }


            // Start : Added by Chandra for CR 2631630
            for(SFDC_Budget__c budget : activeFundBudgets)
            {
                Boolean isParentAccountShareExists=false;
                //CR 3287721: SFDC-757 -> repetetive mails should not come, FB share should be create for budget's account's parent
                Boolean isParentAccountsParentShareExists=false;
                Id UserGroupAccountId=null;
                if(budgetIdShareListMap.get(budget.Id)!=null)
                {
                    for(SFDC_Budget__Share indFbShare : budgetIdShareListMap.get(budget.Id))
                    {
                        UserGroupAccountId=partnerGroupIdAccountIdMap.get(indFbShare.UserOrGroupId);
                        if(UserGroupAccountId==indFbShare.Parent.Account__c )
                        {
                            isParentAccountShareExists=true;
                        }
                        if(UserGroupAccountId==indFbShare.Parent.Account__r.ParentId){
                            isParentAccountsParentShareExists=true;
                        }
                    }
                }
                System.debug('outside If ==='+isParentAccountShareExists+' Accounts parent exists: '+isParentAccountsParentShareExists);
                //CR 3287721: SFDC-757
                if(!isParentAccountShareExists || !isParentAccountsParentShareExists)
                {
                    System.debug('Inside If ==='+isParentAccountShareExists+' Accounts parent exists: '+isParentAccountsParentShareExists);

                    if(UserGroupAccountId ==null || !isParentAccountShareExists)
                    {
                        UserGroupAccountId= budget.Account__c;
                        String userOrGroupId=partnerAccountIdGroupIdMap.get(UserGroupAccountId);
                        if(userOrGroupId!=null)
                        {
                            SFDC_Budget__Share newFbShare=new SFDC_Budget__Share(UserOrGroupId=userOrGroupId,AccessLevel='Read',RowCause='Manual',ParentId=budget.Id);
                            System.debug('FB Share ====='+newFbShare);
                            fundBudgetSharesToBeCreatedString=fundBudgetSharesToBeCreatedString+newFbShare.ParentId+' : '+UserGroupAccountId+ '\n';
                            fundBudgetSharestoBeCreated.add(newFbShare);
                        }
                    }
                    if((UserGroupAccountId ==null || !isParentAccountsParentShareExists)&&budget.Account__r.parentId!=null){
                        UserGroupAccountId= budget.Account__r.parentId;
                        //UserGroupAccountId can be null if parent account is not there
                        //if(UserGroupAccountId!=null){
                        String userOrGroupId=partnerAccountIdGroupIdMap.get(UserGroupAccountId);
                        if(userOrGroupId!=null)
                        {
                            SFDC_Budget__Share newFbShare=new SFDC_Budget__Share(UserOrGroupId=userOrGroupId,AccessLevel='Read',RowCause='Manual',ParentId=budget.Id);
                            System.debug('FB Share ====='+newFbShare);
                            fundBudgetSharesToBeCreatedString=fundBudgetSharesToBeCreatedString+newFbShare.ParentId+' : '+UserGroupAccountId+ '\n';
                            fundBudgetSharestoBeCreated.add(newFbShare);
                        }
                        //}

                    }
                    System.debug('====fundBudgetSharestoBeCreated==='+fundBudgetSharestoBeCreated);

                }
            }

            if(fundBudgetSharestoBeCreated.size()>0)
            {
                insert fundBudgetSharestoBeCreated;
            }

            // End : Added by Chandra for CR 2631630
            List<Messaging.SingleEmailMessage> msgList=new List<Messaging.SingleEmailMessage>();
            List<String> toAddress=new List<String>();
            String toAddressString=GsmUtilClass.getGSMSettingValue('OpptyTriggerCls_PartnerOverSharingMail'); //SFDC-2304
            toAddress.addAll(toAddressString.split(','));

            if(fundBudgetSharesToBeCreatedString!='')
            {
                result =result + 'Fund Budget shares to be Created :'+fundBudgetSharesToBeCreatedString;
                Messaging.SingleEmailMessage msg=new Messaging.SingleEmailMessage();
                msg.setSubject('Fund budget Share records to be created.');
                msg.setToAddresses(toAddress);
                msg.setPlainTextBody(fundBudgetSharesToBeCreatedString);
                msgList.add(msg);
            }

            Messaging.sendEmail(msgList);
            //delete oversharedRecordsToBeDeleted;
        }

        catch(Exception e)
        {
            result='0#:'+e.getMessage();//
        }

        return result;
    }

    public static String checkOverSharingForPartners()
    {
        String result='1:';
        try
        {
            List<UserRole> userRoleIds=[SELECT Id,portalAccountId FROM UserRole where portalAccountId!=null and Name like '%Executive'];
            Map<Id,Id> roleIdGroupIdMap=new Map<Id,Id>();
            List<Group> partnerGroupList=[select Id,relatedId from Group where relatedId IN :userRoleIds and Type = 'RoleAndSubordinates'];
            for(Group g: partnerGroupList)
            {
                roleIdGroupIdMap.put(g.relatedId,g.Id);
            }
            Map<Id,Id> partnerGroupIdAccountIdMap=new Map<Id,Id>();
            for(UserRole ur: userRoleIds)
            {
                partnerGroupIdAccountIdMap.put(roleIdGroupIdMap.get(ur.Id),ur.PortalAccountId);
            }

            //Opportunity Share for Partners
            List<OpportunityShare> opptyShareList=[select Id,UserOrGroupId, OpportunityId,Opportunity.Name,Opportunity.AccountID,Opportunity.Partner_Involved__c, Opportunity.Partner_Involved__r.ParentId
                from OpportunityShare
                where userOrGroupId in : partnerGroupList
                and RowCause='Manual'];
            List<SFDC_Budget__Share> fundBugetShareList=[select Id,UserOrGroupId,ParentId,Parent.Account__c,Parent.Account__r.ParentId
                from SFDC_Budget__Share
                where userOrGroupId in :partnerGroupList
                and RowCause='Manual'];
            List<SFDC_MDF__Share> fundRequestShareList=[select Id,UserOrGroupId,ParentId,Parent.Account__c,Parent.Account__r.ParentId
                from SFDC_MDF__Share
                where userOrGroupId in : partnerGroupList
                and RowCause='Manual'];
            List<SFDC_MDF_Claim__Share> fundClaimShareList=[select Id,UserOrGroupId,ParentId,Parent.Account__c,Parent.Account__r.ParentId
                from SFDC_MDF_Claim__Share
                where userOrGroupId in : partnerGroupList
                and RowCause='Manual'];

            List<AccountShare> accountShareList=[select Id,UserOrGroupId,AccountId,Account.isPartner,Account.ParentId
                from AccountShare
                where userOrGroupId in : partnerGroupList
                and RowCause='Manual'];

            String accountSharesToBeDeletedString='';
            String opptySharesToBeDeletedString='';
            String fundBudgetSharesToBeDeletedString='';
            String fundRequestSharesToBeDeletedString='';
            String fundClaimSharesToBeDeletedString='';
            List<SObject> oversharedRecordsToBeDeleted = new List<SObject>();

            for(AccountShare acShare : accountShareList)
            {//Code-coverage
                Id UserGroupAccountId=partnerGroupIdAccountIdMap.get(acShare.UserOrGroupId);
                if(UserGroupAccountId!=acShare.Account.ParentId && UserGroupAccountId!=acShare.AccountId)
                {
                    accountSharesToBeDeletedString=accountSharesToBeDeletedString+acShare.id+' : '+acShare.AccountId+' , ';
                    oversharedRecordsToBeDeleted.add(acShare);
                }
            }

            for(SFDC_MDF_Claim__Share fcShare : fundClaimShareList)
            {
                Id UserGroupAccountId=partnerGroupIdAccountIdMap.get(fcShare.UserOrGroupId);
                if(UserGroupAccountId!=fcShare.Parent.Account__r.ParentId && UserGroupAccountId!=fcShare.Parent.Account__c)
                {
                    fundClaimSharesToBeDeletedString=fundClaimSharesToBeDeletedString+fcShare.id+' : '+fcShare.ParentId+' , ';
                    oversharedRecordsToBeDeleted.add(fcShare);
                }
            }

            for(SFDC_MDF__Share frShare: fundRequestShareList)
            {
                Id UserGroupAccountId=partnerGroupIdAccountIdMap.get(frShare.UserOrGroupId);
                if(UserGroupAccountId!=frShare.Parent.Account__r.ParentId && UserGroupAccountId!=frShare.Parent.Account__c)
                {
                    fundRequestSharesToBeDeletedString=fundRequestSharesToBeDeletedString+frShare.id+' : '+frShare.ParentId+' , ';
                    oversharedRecordsToBeDeleted.add(frShare);
                }
            }

            for(SFDC_Budget__Share fbShare: fundBugetShareList)
            {
                Id UserGroupAccountId=partnerGroupIdAccountIdMap.get(fbShare.UserOrGroupId);
                if(UserGroupAccountId!=fbShare.Parent.Account__r.ParentId && UserGroupAccountId!=fbShare.Parent.Account__c)
                {
                    fundBudgetSharesToBeDeletedString=fundBudgetSharesToBeDeletedString+fbShare.id+' : '+fbShare.ParentId+' , ';
                    oversharedRecordsToBeDeleted.add(fbShare);
                }
            }

            for(OpportunityShare opptyShare : opptyShareList)
            {
                Id UserGroupAccountId=partnerGroupIdAccountIdMap.get(opptyShare.UserOrGroupId);
                if(UserGroupAccountId!=opptyShare.Opportunity.Partner_Involved__r.ParentId && UserGroupAccountId!=opptyShare.Opportunity.Partner_Involved__c)
                {
                    opptySharesToBeDeletedString=opptySharesToBeDeletedString+opptyShare.Id+' : '+opptyShare.OpportunityId+' : '+opptyShare.Opportunity.Partner_Involved__c+'\n';
                    oversharedRecordsToBeDeleted.add(opptyShare);//
                }
            }

            List<Messaging.SingleEmailMessage> msgList=new List<Messaging.SingleEmailMessage>();
            List<String> toAddress=new List<String>();
            String toAddressString=GsmUtilClass.getGSMSettingValue('OpptyTriggerCls_PartnerOverSharingMail'); //SFDC-2304
            toAddress.addAll(toAddressString.split(','));
            if(opptySharesToBeDeletedString!='')
            {//Code-coverage
                result =result + '\n Opportunity Shares To be deleted :'+opptySharesToBeDeletedString;
                Messaging.SingleEmailMessage msg=new Messaging.SingleEmailMessage();
                msg.setSubject('Opportunity Share recrods for over shared partner opportunities.');
                msg.setToAddresses(toAddress);
                msg.setPlainTextBody(opptySharesToBeDeletedString);
                msgList.add(msg);
            }
            if(fundBudgetSharesToBeDeletedString!='')
            {
                result =result + '\n Fund Budget Shares To be deleted :'+fundBudgetSharesToBeDeletedString;
                Messaging.SingleEmailMessage msg=new Messaging.SingleEmailMessage();
                msg.setSubject('Fund Budget Share recrods for over shared partner Fund Budgets.');
                msg.setToAddresses(toAddress);
                msg.setPlainTextBody(fundBudgetSharesToBeDeletedString);
                msgList.add(msg);
            }
            if(fundRequestSharesToBeDeletedString!='')
            {
                result =result + '\n Fund Request Shares To be deleted :'+fundRequestSharesToBeDeletedString;
                Messaging.SingleEmailMessage msg=new Messaging.SingleEmailMessage();
                msg.setSubject('Fund Request Share recrods for over shared partner Fund requests.');
                msg.setToAddresses(toAddress);
                msg.setPlainTextBody(fundRequestSharesToBeDeletedString);
                msgList.add(msg);
            }
            if(fundClaimSharesToBeDeletedString!='')
            {
                result =result + '\n Fund Claim Shares To be deleted :'+fundClaimSharesToBeDeletedString;
                Messaging.SingleEmailMessage msg=new Messaging.SingleEmailMessage();
                msg.setSubject('Fund Claim Share recrods for over shared partner Fund Claims.');
                msg.setToAddresses(toAddress);
                msg.setPlainTextBody(fundClaimSharesToBeDeletedString);
                msgList.add(msg);
            }
            if(accountSharesToBeDeletedString!='')
            {
                result =result + 'AccountShares To be deleted :'+accountSharesToBeDeletedString;
                Messaging.SingleEmailMessage msg=new Messaging.SingleEmailMessage();
                msg.setSubject('Account Share recrods for over shared Account.');
                msg.setToAddresses(toAddress);
                msg.setPlainTextBody(accountSharesToBeDeletedString);
                msgList.add(msg);
            }

            Messaging.sendEmail(msgList);
            delete oversharedRecordsToBeDeleted;
        }

        catch(Exception e)
        {
            result='0#:'+e.getMessage();//
        }

        return result;
    }

    //CR 2403102 - Create new survey functionality for customers who may churn.
    //SFDC-7606
    /*public static void verifyMinimumContactRolesOnStageChange(List<Opportunity> listOfOpportunitiesWithChangedStageName)
    {
        if(!verifyMinimumContactRolesOnStageChangeFirstRunFlag)
            return;

        if(GsmUtilClass.getGSMSettingValue('OpptyTriggerClass_minCheck').trim()=='false') //SFDC-2304
            return;

        Profile currentUserProfile = [select Name from profile where id = :userinfo.getProfileId()];
        String excludedRoles = GsmUtilClass.getGSMSettingValue('OpptyTriggerClass_surveyExclude'); //SFDC-2304
        List<String> listOfExcludedRoles = excludedRoles.split(',');
        for( String role : listOfExcludedRoles)
        {
            if (currentUserProfile.Name == role.trim())
            {
                return;
            }
        }
        //Code-coverage
        Integer minimumNumberOfContactsRequired = Integer.valueof(GsmUtilClass.getGSMSettingValue('OpptyTriggerClass_minContacts').trim()); //SFDC-2304
        String contactRole = GsmUtilClass.getGSMSettingValue('OpptyTriggerClass_contactRole'); //SFDC-2304
        String errMsg = GsmUtilClass.getGSMSettingValue('OpptyTriggerClass_minOCRMsg'); //SFDC-2304
        List<String> listOfOpportunityIds = new List<String>();
        Map<Id, Opportunity> mapOfOpportunityIdToOpportunity = new Map<Id, Opportunity>();
        Map<Id, List<OpportunityContactRole>> mapOfOppIdToOCR = new Map<Id, List<OpportunityContactRole>>();

        for(Opportunity opp : listOfOpportunitiesWithChangedStageName )
        {
            listOfOpportunityIds.add(opp.Id);
            mapOfOpportunityIdToOpportunity.put(opp.Id, opp);
        }

        List<OpportunityContactRole> listOfContactRoles= [select id, contactid, opportunityid, role from OpportunityContactRole where opportunityid in :listOfOpportunityIds and role= :contactRole];

        for(OpportunityContactRole ocr : listOfContactRoles)
        {
            if(!mapOfOppIdToOCR.containsKey(ocr.OpportunityId))
                mapOfOppIdToOCR.put(ocr.OpportunityId, new List<OpportunityContactRole>());
            mapOfOppIdToOCR.get(ocr.OpportunityId).add(ocr);
        }



        for(Opportunity opp : listOfOpportunitiesWithChangedStageName)
        {
            if(!mapOfOppIdToOCR.containsKey(opp.Id) || (mapOfOppIdToOCR.get(opp.Id).size() < minimumNumberOfContactsRequired))
            {
                opp.put('StageName', Trigger.oldMap.get(opp.Id).get('StageName'));
                //  CR 2749773  - Changed the Trigger.addError(String) to  Trigger.addError(String, Boolean) for parsing Html
                opp.addError(errMsg);
            }
        }
        verifyMinimumContactRolesOnStageChangeFirstRunFlag = false;//
    }*/
    //Code-coverage
    public static Map<Id,Opportunity> UpdateCarrierApplicationOnOpportunity(List<OpportunityLineItem> oldOpttyLineItemList,Map<Id,Opportunity> opptyMap)
    {
        Boolean containsAuraProduct=false;

        String CarrierProductFamilyName=GsmUtilClass.getGSMSettingValue('OpptyLineItemTrigger_CarrierFamily'); //SFDC-2304
        Set<Id> opptyIdSet=new Set<Id>();
        Map<Id,List<OpportunityLineItem>> opptyIdOpportunityLineitemListMap=new Map<Id,List<OpportunityLineItem>>();
        for(OpportunityLineItem oppli : oldOpttyLineItemList)
        {
            opptyIdSet.add(oppli.OpportunityId);
        }
        List<OpportunityLineItem> opptyLineItems=[Select Product_Name__c,Forecast_Group__c,opportunityId FROM OpportunityLineItem where OpportunityId IN :opptyIdSet and Id Not IN :oldOpttyLineItemList];
        for(OpportunityLineItem oli: opptyLineItems)
        {
            List<OpportunityLineItem> opptyLineItemList=null;
            if(!opptyIdOpportunityLineitemListMap.containskey(oli.OpportunityId))
            {
                opptyLineItemList=new List<OpportunityLineItem>();
            }
            else
            {
                opptyLineItemList=opptyIdOpportunityLineitemListMap.get(oli.OpportunityId);
            }
            opptyLineItemList.add(oli);
            opptyIdOpportunityLineitemListMap.put(oli.OpportunityId,opptyLineItemList);
        }

        List<Opportunity> opptyListToUpdateCarrier=new List<Opportunity>();
        for(Id oppId: opptyIdSet)
        {
            List<OpportunityLineItem> opptyLineItemList=opptyIdOpportunityLineitemListMap.get(oppId);
            containsAuraProduct=false;
            if(opptyLineItemList!=null)
            {
                for(OpportunityLineItem oli: opptyLineItemList)
                {
                    if(oli.Forecast_Group__c==CarrierProductFamilyName)
                    {
                        containsAuraProduct=true;
                        break;
                    }
                }
            }
            if(!containsAuraProduct)
            {
                Opportunity opp=OpportunityUtilClass.getOpportunityRecord(opptyMap,oppId);
                opp.Carrier_Application__c='';
                opp.Validation_Override__c=true;
                //opptyListToUpdateCarrier.add(opp);
                opptyMap.put(oppId,opp);
            }
        }
        /*if(opptyListToUpdateCarrier.size()>0)
        {
            update opptyListToUpdateCarrier;
        }*/
        return opptyMap;
    }
    public static Map<Id,Opportunity> updatePrimaryProductNameOnOppty(Set<Id> p_opptyIdList,Map<Id,Opportunity> opptyMap)
    {
/*        opptyMapTriggerClass=opptyMap;
        updatePrimaryProductNameOnOppty(p_opptyIdList);
        return opptyMapTriggerClass;
    }
    public static void updatePrimaryProductNameOnOppty(Set<Id> p_opptyIdList)
    {*/
        if(!updatePrimaryProductNameOnOpptyFirstRunFlag)
            return opptyMap;

        List<OpportunityLineItem> opptyProdList = new List<OpportunityLineItem>();
        Set<Id> opptysWithoutProducts = new Set<Id>();
        Map<Id,String> oppIdPrimaryProductNameMap = new Map<Id,String>();
        Map<Id,Decimal> oppIdMRRValueMap = new Map<Id,Decimal>();
        List<Opportunity> updateOpptyList = new List<Opportunity>();
        Map<Id,Decimal> oppIdTotalMRRValueMap = new Map<Id,Decimal>();
        //Add all the opptys first, remove them later
        opptysWithoutProducts.addAll(p_opptyIdList);


        //Sonali Tandon - CR 2972963 - Primary Product Name: For Closed Opptys, field should not blank out
        // removing where clause so that primary product name is calculated for opptys at all stages
        for(OpportunityLineItem oli: [SELECT Id, PricebookEntry.Product2.Name, MRR__c, OpportunityId, Opportunity.Competitor__c , Opportunity.Account_MRR_Type__c
                FROM OpportunityLineItem
                WHERE OpportunityId IN : p_opptyIdList])
        {
            if(oppIdPrimaryProductNameMap.get(oli.OpportunityId) == null)
                oppIdPrimaryProductNameMap.put(oli.OpportunityId,'##No Product##');
            if(oppIdMRRValueMap.get(oli.OpportunityId) == null)
                oppIdMRRValueMap.put(oli.OpportunityId,0.00);
            if(oppIdTotalMRRValueMap.get(oli.OpportunityId) == null)
                oppIdTotalMRRValueMap.put(oli.OpportunityId,0.00);

            Decimal totalMRR = oppIdTotalMRRValueMap.get(oli.OpportunityId) + oli.MRR__c;
            oppIdTotalMRRValueMap.put(oli.OpportunityId,totalMRR);
            opptyProdList.add(oli);
            opptysWithoutProducts.remove(oli.OpportunityId);
        }

        for(OpportunityLineItem oli: opptyProdList)
        {
            if(oppIdTotalMRRValueMap.get(oli.OpportunityId) >= 0.00)
            {
                if(oppIdMRRValueMap.get(oli.OpportunityId) < oli.MRR__c)
                {
                    oppIdMRRValueMap.put(oli.OpportunityId,oli.MRR__c);
                    oppIdPrimaryProductNameMap.put(oli.OpportunityId,oli.PricebookEntry.Product2.Name);
                }
            }

            if(oppIdTotalMRRValueMap.get(oli.OpportunityId) < 0.00)
            {//Code-coverage
                if(oppIdMRRValueMap.get(oli.OpportunityId) > oli.MRR__c)
                {
                    oppIdMRRValueMap.put(oli.OpportunityId,oli.MRR__c);
                    oppIdPrimaryProductNameMap.put(oli.OpportunityId,oli.PricebookEntry.Product2.Name);//
                }
            }
        }

        for(OpportunityLineItem oli: opptyProdList)
        {
            if(oppIdPrimaryProductNameMap.get(oli.OpportunityId) != '##No Product##')
            {
                Opportunity opp = OpportunityUtilClass.getOpportunityRecord(opptyMap,oli.OpportunityId);
                opp.Primary_Product_Name__c = oppIdPrimaryProductNameMap.get(oli.OpportunityId);
                opp.Validation_Override__c = True;
                //updateOpptyList.add(opp);
                opptyMap.put(oli.OpportunityId, opp) ;          
            }
        }
        for(Id opptyId : opptysWithoutProducts)
        {//Code-coverage
            Opportunity opp = OpportunityUtilClass.getOpportunityRecord(opptyMap,opptyId);
            opp.Primary_Product_Name__c = '';
            opp.Validation_Override__c = True;
            updateOpptyList.add(opp);
            opptyMap.put(opptyId, opp);       
        }
        System.debug('##updateOpptyList## '+updateOpptyList);
        /*if(updateOpptyList.size() > 0 && !(trigger.isInsert || trigger.isUpdate))
        {
            List<Opportunity> updateOpptyListUnique=new List<Opportunity>();
            Set<Opportunity> UpdateOpportunityset=new Set<Opportunity>();
            UpdateOpportunityset.addAll(updateOpptyList);
            updateOpptyListUnique.addAll(UpdateOpportunityset);
            //Start Code :Added the Try Catch Block for the Developer exception. CR 2711073
            try{
                update updateOpptyListUnique;
            }catch (Exception ex) {//Code-coverage
                sawyer.saw(ex);
                if(ex.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION, Competitor is mandatory')){
                    String customErrorMsg  = GsmUtilClass.getGSMSettingValue('OpptyTriggerClass_CompetitorMandatory');   //SFDC-2304
                    if(customErrorMsg !='')
                        updateOpptyListUnique[0].adderror(customErrorMsg);
                } else if(ex.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION, Opportunity Category, Sub-Category, Cancellation/Loss Reason is required')){
                    String customErrorMsg1  = GsmUtilClass.getGSMSettingValue('OpptyTriggerClass_SubCategoryError');   //SFDC-2304
                    if(customErrorMsg1 !='')
                        updateOpptyListUnique[0].adderror(customErrorMsg1); //
                }
            }
            //End Code :Added the Try Catch Block for the Developer exception. CR 2711073
        }*/

        updatePrimaryProductNameOnOpptyFirstRunFlag = false;
        return opptyMap;
    }

    //End of CR 2412804


    /*SFDC-5392 To remove Account_Collector__c lookupfield
    public static void updateCollectorinOppty(List<Opportunity> opptyListForUserCollector){

        List<Account> accList = new List<Account>();
        Map<Id,Id> accIdToCollectorIdMap = new Map<Id,Id>();
        Set<Id> accIdSet = new Set<Id>();

        for(Opportunity opp : opptyListForUserCollector)
        {
            accIdSet.add(opp.AccountId);
        }
        if(accIdSet.size() > 0)
        {
            accList = [Select Id , Collector__c From Account Where Id IN  :accIdSet];
        }

        for(Account acc: accList)
        {
            accIdToCollectorIdMap.put(acc.Id,acc.Collector__c);
        }

        for(Opportunity opp: opptyListForUserCollector)
        {
            opp.Account_Collector__c = accIdToCollectorIdMap.get(opp.AccountId);

        }



    }*/

    //SFDC-5392 To remove Account_Collector__c lookupfield
    public static void sendEmailAlertOnHighRiskAccount(List<Opportunity> opptyListForUserCollector){

        Messaging.SingleEmailMessage[] sendEmailList = new List<Messaging.SingleEmailMessage>();

        Set<Id> accountIdSet = new Set<Id>();
        Set<Id> oppOwnerIds = new Set<Id>();
        Set<Id> accCollectorId = new Set<Id>();

        for(Opportunity opp : opptyListForUserCollector)
        {
            accountIdSet.add(opp.AccountId);
            oppOwnerIds.add(opp.OwnerId);
        }

        Map<Id,Account> accEmailMap = new Map<ID, Account>([Select Id, Name, Collector__c, Financial_Risk__c, (SELECT UserId FROM AccountTeamMembers WHERE TeamMemberRole IN ('Sales - Primary', 'Sales - Analyst', 'Sales - Secondary')) From Account Where Id IN :accountIdSet AND Financial_Risk__c != NULL AND Collector__c!=NULL]);
        Map<Id,User> ownerMap = new Map<Id,User>([SELECT Id, Name FROM User WHERE Id IN :oppOwnerIds]);

        for(Id accId : accEmailMap.keySet())
            accCollectorId.add(accEmailMap.get(accId).Collector__c);

        Map<Id,User> collectorMap = new Map<Id,User>([SELECT Id, Name FROM User WHERE Id IN :accCollectorId]);

        for(Opportunity opp : opptyListForUserCollector)
        {
            Account acc = accEmailMap.get(opp.AccountId);
            if(acc != NULL)
            {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                String oppCloseDate = opp.CloseDate.format();
                String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
                String emailSubject = 'A new Opportunity has been created for a high collectability risk Account - ' + acc.Name;
                String emailBody = 'A new Opportunity has been created for the Account - "' + acc.Name + '" which was identified as a HIGH COLLECTABILITY RISK ACCOUNT.'
                                    + '</br>'
                                    + 'Please seek approval from Collections team before pursuing this opportunity further.'
                                    + '</br>'
                                    + '</br>'
                                    + 'Opportunity Name - ' + opp.Name
                                    + '</br>'
                                    + 'Opportunity Owner - ' + ownerMap.get(opp.OwnerId).Name
                                    + '</br>'
                                    + 'Close Date - ' + oppCloseDate
                                    + '</br>'
                                    + 'Collection Analyst : ' + collectorMap.get(acc.Collector__c).Name
                                    + '</br>'
                                    + '</br>'
                                    + 'Link to Opportunity : '
                                    + baseUrl + '/' + opp.Id;
                List<String> recips = new List<String>();
                for(AccountTeamMember atm : acc.AccountTeamMembers)
                    recips.add(String.valueOf(atm.UserId));
                recips.add(String.valueOf(acc.Collector__c));
                mail.setSubject(emailSubject);
                mail.setHtmlBody(emailBody);
                mail.setToAddresses(recips);
                mail.setUseSignature(false);
                mail.setBccSender(false);
                mail.setSaveAsActivity(false);
                sendEmailList.add(mail);
            }
        }
        List<Messaging.Sendemailresult> results = Messaging.sendEmail(sendEmailList);
    }
    //End of SFDC-5392

    /*SFDC-948 updateDealRegOpptyShareForPartnerInvolved(dealRegOpptyForShareupdate,OpportunityAccess)
Desc: create opportunity share for partner exec of current partner involved account and its parent*/
    public static void updateDealRegOpptyShareForPartnerInvolved(List<Opportunity> dealRegOpptyForShareupdate,String OpportunityAccess){
        if(!addOpptyShareFirstRunFlag){
            return;
        }
        CloseOldOpptyScheduleClass.updateCloseOldOpportunityFlag = true;
        List<String> accIdList = new List<String>();
        Map<Id,Id> oppIdToPartnerInvolved = new Map<Id,Id>();
        for(Opportunity opp : dealRegOpptyForShareupdate){
            oppIdToPartnerInvolved.put(opp.id,opp.Partner_Involved__c);
            accIdList.add(opp.Partner_Involved__c);
        }

        Map<Id,List<Id>> parentHierarchy = new Map<Id,List<Id>>();
        Integer parentHierarchyLevel = Integer.valueOf(NAPSettings.getValue('Opportunity_Share_Hierarchy_Level'));
        parentHierarchy = GSMUtilClass.getAccParentsInHierarchy(accIdList,parentHierarchyLevel);
        List<Id> accountIdList = new List<Id>();
        for(Id accId: parentHierarchy.keySet()){
            accountIdList.add(accId);
            accountIdList.addAll(parentHierarchy.get(accId));
        }
        //intentionally keeping debug statements, that will help in prod in case of some issues.
        system.debug('parentHierarchy: '+parentHierarchy);
        //get connect between oppty id and groups for that oppty to create share.
        //oppty to partner involved; partner involved to parent accounts -> account to role -> role to group
        Map<Id,Set<Id>> opptyToGroupMap = new Map<Id,Set<Id>>();
        if(!oppIdToPartnerInvolved.isEmpty()){
            opptyToGroupMap = OpportunityTriggerClass.getOpptyToUserOrGroupList(accountIdList,oppIdToPartnerInvolved,parentHierarchy);
        }


        system.debug('opptyToGroupMap: '+opptyToGroupMap);
        List<OpportunityShare> newOppShares = new List<OpportunityShare>();
        for(Id oppId : opptyToGroupMap.keySet()){
            for(Id groupId : opptyToGroupMap.get(oppId)){
                newOppShares.add(new OpportunityShare(
                            OpportunityId = oppId,
                            userOrGroupId = groupId,
                            OpportunityAccessLevel = OpportunityAccess));
            }
        }

        if(newOppShares.size()>0)
        {
            try {
                Database.SaveResult[] results = Database.insert(newOppShares,false);
                Integer index = 0;
                List<Error_log__c> erroLogList = new List<Error_log__c>();
                if (results != null){
                    for (Database.SaveResult result : results) {

                        if (!result.isSuccess()) {
                            Database.Error[] errs = result.getErrors();

                            for(Database.Error err : errs){
                                Error_log__c erroLog = new Error_log__c(Class__c = 'OpportunityTriggerClass',Error_Message__c = err.getMessage(),RecordId__c = newOppShares.get(index).Id);

                                erroLogList.add(erroLog);
                                System.debug(err.getStatusCode() + ' - ' + err.getMessage());
                            }


                        }
                        index++;
                    }
                    if(!erroLogList.isEmpty())
                        insert erroLogList;
                }

            } catch (Exception err) {
                System.debug(err.getTypeName() + ' - ' + err.getCause() + ': ' + err.getMessage());
                Error_log__c erroLog = new Error_log__c(Class__c = 'OpportunityTriggerClass',Error_Message__c = err.getMessage()+'-'+err.getCause());
                insert erroLog;
            }
            //insert newOppShares;
        }
        addOpptyShareFirstRunFlag = false;
    }
    /*SFDC-948 updateDealRegOpptyShareForPartnerInvolved(dealRegOpptyForShareDelToOldAccount)
      -- Desc: When Partner Involved changed for Opty, the share will need to be removed if no longer associated with Parent or Child Partner Account */
    public static void updateDealRegOpptyShareForPartnerInvolved(Map<Id,Id> dealRegOpptyForShareDelToOldAccount){
        if(!delOpptyShareFirstRunFlag){
            return;
        }
        CloseOldOpptyScheduleClass.updateCloseOldOpportunityFlag = true;
        List<String> accIdList = new List<String>();
        Map<Id,Id> oppIdToPartnerInvolved = new Map<Id,Id>();
        oppIdToPartnerInvolved = dealRegOpptyForShareDelToOldAccount;

        for(Id oppId : oppIdToPartnerInvolved.keySet()){
            accIdList.add(oppIdToPartnerInvolved.get(oppId));
        }

        Map<Id,List<Id>> parentHierarchy = new Map<Id,List<Id>>();
        Integer parentHierarchyLevel = Integer.valueOf(NAPSettings.getValue('Opportunity_Share_Hierarchy_Level'));
        parentHierarchy = GSMUtilClass.getAccParentsInHierarchy(accIdList,parentHierarchyLevel);
        List<Id> accountIdList = new List<Id>();
        for(Id accId: parentHierarchy.keySet()){
            accountIdList.add(accId);
            accountIdList.addAll(parentHierarchy.get(accId));
        }
        system.debug('parentHierarchy: '+parentHierarchy);
        //get connect between oppty id and groups for that oppty to create share.
        //oppty to partner involved; partner involved to parent accounts -> account to role -> role to group
        Map<Id,Set<Id>> opptyToGroupMap = new Map<Id,Set<Id>>();
        if(!oppIdToPartnerInvolved.isEmpty()){
            opptyToGroupMap = OpportunityTriggerClass.getOpptyToUserOrGroupList(accountIdList,oppIdToPartnerInvolved,parentHierarchy);
        }
        system.debug('opptyToGroupMap: '+opptyToGroupMap+' dealRegOpptyForShareDelToOldAccount: '+dealRegOpptyForShareDelToOldAccount);
        List<OpportunityShare> oppSharesToDel = new List<OpportunityShare>();
        List<OpportunityShare> oldOppShares = new List<OpportunityShare>();
        oldOppShares = [select id, OpportunityAccessLevel, RowCause, UserOrGroupId,OpportunityId from OpportunityShare where OpportunityId in :opptyToGroupMap.keySet()];

        for(OpportunityShare oppShare : oldOppShares){
            if(opptyToGroupMap.get(oppShare.OpportunityId).contains(oppShare.UserOrGroupId)){
                oppSharesToDel.add(oppShare);
            }
        }

        system.debug('oppSharesToDel: '+oppSharesToDel);
        //Code-coverage
        if(!oppSharesToDel.isEmpty()){
            try {
                Database.DeleteResult[] results = Database.delete(oppSharesToDel,false);
                Integer index = 0;
                List<Error_log__c> erroLogList = new List<Error_log__c>();
                if (results != null){
                    for (Database.DeleteResult  result : results) {

                        if (!result.isSuccess()) {
                            Database.Error[] errs = result.getErrors();

                            for(Database.Error err : errs){
                                Error_log__c erroLog = new Error_log__c(Class__c = 'OpportunityTriggerClass',Error_Message__c = err.getMessage(),RecordId__c = oppSharesToDel.get(index).Id);

                                erroLogList.add(erroLog);
                                System.debug(err.getStatusCode() + ' - ' + err.getMessage());
                            }


                        }
                        index++;
                    }
                    if(!erroLogList.isEmpty())
                        insert erroLogList;
                }

            } catch (Exception err) {
                System.debug(err.getTypeName() + ' - ' + err.getCause() + ': ' + err.getMessage());
                Error_log__c erroLog = new Error_log__c(Class__c = 'OpportunityTriggerClass',Error_Message__c = err.getMessage()+'-'+err.getCause());
                insert erroLog;//
            }
            //delete oppSharesToDel;
        }
        delOpptyShareFirstRunFlag = false;
    }


    public static Map<Id,Set<Id>> getOpptyToUserOrGroupList(List<Id> accountIdList,Map<Id,Id> oppIdToPartnerInvolved,Map<Id,List<Id>> parentHierarchy){
        Map<Id,UserRole> userRolesMap = new Map<Id,UserRole>([SELECT Id,portalAccountId FROM UserRole where portalAccountId IN :accountIdList and Name like '%Executive']);
        List<Id> userRoleIds = new List<Id>();
        userRoleIds.addAll(userRolesMap.keySet());
        Map<Id,Id> accountToRoleMap = new Map<Id,Id>();
        for(Id userRoles : userRoleIds){
            accountToRoleMap.put(userRolesMap.get(userRoles).portalAccountId,userRoles);
        }

        //Role—Public Group that includes all of the User records in a particular UserRole.
        //RoleAndSubordinates—Public Group that includes all of the User records in a particular UserRole and all of the User records in any subordinateUserRole.
        Map<Id,Group> userGroupMap = new Map<Id,Group>([select Id,relatedId from Group where relatedId IN :userRoleIds and Type = 'RoleAndSubordinates']);

        Map<Id,Id> roleToGroupMap = new Map<Id,Id>();

        for(Id userGroups : userGroupMap.keySet()){
            roleToGroupMap.put(userGroupMap.get(userGroups).relatedId,userGroups);
        }

        system.debug('roleToGroupMap: '+roleToGroupMap);
        Map<Id,Set<Id>> opptyToGroupMap = new Map<Id,Set<Id>>();
        //Map<Id,Set<Id>> opptyToUserMap = new Map<Id,Set<Id>>();
        for(Id oppId : oppIdToPartnerInvolved.keySet()){
            Set<Id> groupIds = new Set<Id>();
            Id groupId = roleToGroupMap.get(accountToRoleMap.get(oppIdToPartnerInvolved.get(oppId)));
            if(groupId!=null)
                groupIds.add(groupId);
            //List<Id> accountIds = new List<Id>();
            if(!parentHierarchy.isEmpty())
                for(Id accId : parentHierarchy.get(oppIdToPartnerInvolved.get(oppId))){
                    groupId = roleToGroupMap.get(accountToRoleMap.get(accId));
                    groupIds.add(groupId);
                }
            opptyToGroupMap.put(oppId,groupIds);
            system.debug('groupIds: '+groupIds);
        }
        return opptyToGroupMap;
    }


    // Sonali Tandon - SFDC-1096 - Start
    public static void setPartnerAuthorisedCountryFlag(Set<Id> setOfAccountIds,Set<Id> setOfPartnerInvolvedIds, List<Opportunity> listOfOpptysForPartnerAuthorisedCountryFlag)
    {
        if(!setPartnerAuthorisedCountryFlag)
            return;

        Map<Id, String> mapOfAccountIdToBillingCountry                  = new Map<Id,String>();
        Map<Id,String> mapOfPartnerInvolvedToPartnerSellableCountries   = new Map<Id,String>();

        List<Id> listOfAccountIds         = new List<Id>();
        List<Id> listOfPartnerInvolvedIds = new List<Id>();


        listOfAccountIds.addAll(setOfAccountIds);
        listOfPartnerInvolvedIds.addAll(setOfPartnerInvolvedIds);

        for(Account opptyAccount : [Select Id, BillingCountry from Account WHERE Id IN : listOfAccountIds AND  BillingCountry!=null ])
        {
            mapOfAccountIdToBillingCountry.put(opptyAccount.Id, opptyAccount.BillingCountry);
        }

        for(Account partnerInvolvedAccount : [Select Id, Partner_Sellable_Countries__c from Account WHERE Id IN : listOfPartnerInvolvedIds  ])
        {
            if(String.isBlank(partnerInvolvedAccount.Partner_Sellable_Countries__c ))
                mapOfPartnerInvolvedToPartnerSellableCountries.put(partnerInvolvedAccount.Id, '');
            else
                mapOfPartnerInvolvedToPartnerSellableCountries.put(partnerInvolvedAccount.Id, partnerInvolvedAccount.Partner_Sellable_Countries__c);

        }

        L2Q_AccountTriggerClass.setPartnerAuthorisedCountryFlag(mapOfAccountIdToBillingCountry,mapOfPartnerInvolvedToPartnerSellableCountries,listOfOpptysForPartnerAuthorisedCountryFlag, 'Opportunity');

        setPartnerAuthorisedCountryFlag = false;

    }
    //Code-coverage
    public static void resetPartnerAuthorisedCountryFlag(List<Opportunity> listOfOpptysToResetPartnerAuthorsedCountryFlag)
    {

        if(!resetPartnerAuthorisedCountryFlag)
            return;

        for(Opportunity oppty : listOfOpptysToResetPartnerAuthorsedCountryFlag)
        {
            oppty.Is_Authorized_Partner_Sellable_Country__c = true;
        }

        resetPartnerAuthorisedCountryFlag = false;
    }

    public Class OrderRegionResponse {
        public String orderRegionValue;
        public Boolean validationFiresForContract = false;
    }

    //SFDC - 925 Shivam Verma Opportunity Order Region must match the Account Finance Region
    public static OpportunityTriggerClass.OrderRegionResponse updateOrderRegion(List<Opportunity> opportunities, Map<String,String> oppOrderRegionMap) {

        String accountStatus;
        String accFinanceRegion;
        List<Account> accountList;
        List<String> orderRegionListFromMapping;
        //String orderRegionValue;

        List<Id> accIds = new List<Id>();
        Map<Id,Account> accIdAccountMap = new Map<Id,Account>();
        Map<String,List<String>> mappingMap = new Map<String,List<String>>();
        Map<String,String> salesApprovedCountryMapping = new Map<String,String>();

        OpportunityTriggerClass.OrderRegionResponse orderRegionRes = new OpportunityTriggerClass.OrderRegionResponse();

        //Get the list of account ids from Opportunities
        for (Opportunity opp:opportunities) {
            accIds.add(opp.AccountId);
        }

        //Get list the Accounts
        accountList = [Select Account_Status__c ,BillingCountry, Finance_Region__c From Account where id IN :accIds];

        //Create account id to account map
        if (accountList.size() > 0) {
            for (Account acc:accountList) {
                accIdAccountMap.put(acc.id, acc);
            }
        }
        System.debug('accIdAccountMap :'+accIdAccountMap);

        //Get the Opportunity Order region to account finance region mapping
        List<Order_Region_Reporting_Region_Mapping__c> mappingList = [Select Reporting_Region__c,
            Order_Region__c
                From Order_Region_Reporting_Region_Mapping__c limit 50000];

        List<Sales_Approved_Country__c> salesApprovedCountriesList = [Select Name,Order_Region__c
            From Sales_Approved_Country__c limit 50000];

        for (Sales_Approved_Country__c sac:salesApprovedCountriesList) {
            salesApprovedCountryMapping.put(sac.Name, sac.Order_Region__c);//Code-coverage
        }

        if (mappingList.size() > 0) {

            //Create the Map for Account finance region and related opportunity region
            for (Order_Region_Reporting_Region_Mapping__c mapping:mappingList) {
                //Code-coverage
                if (mappingMap.get(mapping.Reporting_Region__c.toUpperCase()) == null) {
                    List<String> orderRegionList = new List<String>();
                    orderRegionList.add(mapping.Order_Region__c);
                    mappingMap.put(mapping.Reporting_Region__c.toUpperCase(), orderRegionList);
                } else {
                    //orderRegionList.add(mapping.Order_Region__c);
                    List<String> orderRegionList = mappingMap.get(mapping.Reporting_Region__c.toUpperCase());
                    orderRegionList.add(mapping.Order_Region__c);
                    mappingMap.put(mapping.Reporting_Region__c.toUpperCase(), orderRegionList);
                }

            }
            System.debug('mappingMap :'+mappingMap);

            if (accIdAccountMap != null) {

                //Iterate over opportunity to populate the Order Region value
                for (Opportunity o:opportunities) {

                    if (accIdAccountMap.get(o.AccountId) != null) {
                        accountStatus = accIdAccountMap.get(o.AccountId).Account_Status__c;
                        /*Check if the Account is Lead or Inactive account
                         * If yes then if order region is not populated then stamp the value form account
                         * else respect the value
                         */
                        if (o.Order_Region__c == null ) {

                            String country = accIdAccountMap.get(o.AccountId).BillingCountry;
                            accFinanceRegion = accIdAccountMap.get(o.AccountId).Finance_Region__c;

                            if (accFinanceRegion != null && accFinanceRegion != '' && accountStatus.endsWith('Active')) {
                                accFinanceRegion = accFinanceRegion.toUpperCase();
                                orderRegionListFromMapping = mappingMap.get(accFinanceRegion);

                                if (orderRegionListFromMapping != null) {
                                    Set<String> orderRegionSetFromMapping = new Set<String>();
                                    orderRegionSetFromMapping.addAll(orderRegionListFromMapping);

                                    if (orderRegionListFromMapping != null && orderRegionListFromMapping.size() > 0) {
                                        o.Order_Region__c = orderRegionListFromMapping[0];
                                        orderRegionRes.orderRegionValue = orderRegionListFromMapping[0];
                                    }
                                } else {
                                    o.Order_Region__c = 'North America';
                                    orderRegionRes.orderRegionValue = 'North America';
                                }
                            } else if(salesApprovedCountryMapping.size() > 0 && country != null && salesApprovedCountryMapping.get(country) != null && !accountStatus.endsWith('Active')) {
                                o.Order_Region__c = salesApprovedCountryMapping.get(country);
                                orderRegionRes.orderRegionValue = salesApprovedCountryMapping.get(country);
                            } else {
                                o.Order_Region__c = 'North America';
                                orderRegionRes.orderRegionValue = 'North America';
                            }
                        } else if (o.Order_Region__c != null ) {

                            String existingOrderRegion = o.Order_Region__c;
                            accFinanceRegion = accIdAccountMap.get(o.AccountId).Finance_Region__c;

                            if (accFinanceRegion != null && accFinanceRegion != '') {
                                accFinanceRegion = accFinanceRegion.toUpperCase();
                                orderRegionListFromMapping = mappingMap.get(accFinanceRegion);

                                if (orderRegionListFromMapping != null) {
                                    Set<String> orderRegionSetFromMapping = new Set<String>();
                                    orderRegionSetFromMapping.addAll(orderRegionListFromMapping);

                                    //Get the logged in user profile id
                                    String loggedInUserProfileId = userinfo.getProfileId();

                                    //Get the profile id list for which validation needs to be thrown
                                    //SFDC-3264 - profile split need to be accomodated in multiple metadata record

                                    List<String> excludedProfilesIdsList = new List<String>();
                                    for(String excludedProfilesIds : GsmUtilClass.getGSMSettingValuePartialMatch('AccFinanceRegionCheck_ValidationProf_'))
                                    {
                                        excludedProfilesIdsList.addAll(excludedProfilesIds.split(','));

                                    }
                                    /*String excludedProfilesIds = GSMUtilClass.getGSMSettingValue('AccFinanceRegionCheck_ValidationPorfiles');
                                      List<String> excludedProfilesIdsList = excludedProfilesIds.split(',');*/


                                    Set<String> excludedProfilesIdsSet = new Set<String>();
                                    excludedProfilesIdsSet.addAll(excludedProfilesIdsList);
                                    System.debug('excludedProfilesIdsSet : '+excludedProfilesIdsSet);
                                    System.Debug('Order Region List from Mapping :'+orderRegionListFromMapping);
                                    System.debug('Order Region size :'+orderRegionListFromMapping.size());
                                    System.debug('Is null :'+orderRegionListFromMapping != null);

                                    if (orderRegionListFromMapping != null && orderRegionListFromMapping.size() > 0) {
                                        System.debug('Inside the logic');

                                        if (excludedProfilesIdsSet.contains(loggedInUserProfileId) &&
                                                (accountStatus.endsWith('Active')) &&
                                                ((orderRegionListFromMapping[0] != existingOrderRegion) ||
                                                 (oppOrderRegionMap != null && oppOrderRegionMap.size() > 0 && orderRegionListFromMapping[0] != oppOrderRegionMap.get(o.id)))) {

                                            System.debug('Inside Order region validatin check');
                                            System.debug('orderRegionListFromMapping :'+orderRegionListFromMapping[0] + '------- Existing Order Region');

                                            if (accFinanceRegion != null && !o.Validation_Override__c && oppOrderRegionMap == null &&
                                                    !(orderRegionSetFromMapping.contains(o.Order_Region__c.toUpperCase()) ||
                                                        orderRegionSetFromMapping.contains(o.Order_Region__c))) {

                                                o.addError('The Account Region and Reporting Region are not aligned.  Reporting Region must match Account Region to proceed. If an Account level change is required, initiate a task with Sales Analyst team');

                                            } else if (accFinanceRegion != null && oppOrderRegionMap != null && oppOrderRegionMap.size() > 0 &&
                                                    !(orderRegionSetFromMapping.contains(oppOrderRegionMap.get(o.id).toUpperCase()) ||
                                                        orderRegionSetFromMapping.contains(oppOrderRegionMap.get(o.id)))) {
                                                orderRegionRes.validationFiresForContract = true;
                                                        }
                                        } else if (accountStatus.endsWith('Active')){
                                            //o.Order_Region__c = orderRegionListFromMapping[0];
                                        }
                                        orderRegionRes.orderRegionValue = orderRegionListFromMapping[0];
                                    }
                                }
                            }
                        }
                    } else {
                        o.Order_Region__c = 'North America';
                        orderRegionRes.orderRegionValue = 'North America';//
                    }
                }
            }
        }
        return orderRegionRes;
    }

    // Sonali Tandon - SFDC-1096 - End

    public static void sendDoubleByteNotification(List<Opportunity> oppList) {
        //SFDC-2228

        //SFDC-2228
        Boolean isEnabled = Boolean.valueOf(GSMUtilClass.getGSMSettingValue('DoubleBytesToggle'));

        if (isEnabled || Test.isRunningTest()) {
            ByPassAndLimitUtils.doRegisteration('OpportunityTriggerClass.sendDoubleByteNotification',1);
            if(!ByPassAndLimitUtils.run('OpportunityTriggerClass.sendDoubleByteNotification'))
                return;
            Set<String> doubleByteAccountsList = new Set<String>();
            List<String> accountIdList = new List<String>();
            Map<String,Opportunity> accountIdOppMap = new Map<String,Opportunity>();
            List<String> ownerIdList = new List<String>();

            for (Opportunity opp:oppList) {
                system.debug(LoggingLevel.ERROR,'Account id : '+opp.AccountId);
                accountIdList.add(opp.AccountId);
                ownerIdList.add(opp.OwnerId);
                accountIdOppMap.put(opp.AccountId, opp);
            }
            system.debug(LoggingLevel.ERROR,'Account id list :'+accountIdList);

            if (accountIdList.size() > 0) {
                List<Contact> contactsList = [Select id,name,Double_byte__c,Contact.AccountId From Contact where accountId IN:accountIdList AND Double_byte__c=true];
                system.debug(LoggingLevel.ERROR,'contactsList: '+contactsList);
                Map<String,List<Contact>> accountIdCOntactsListMap = new Map<String,List<Contact>>();

                if (contactsList.size() > 0)
                {
                    for (Contact c:contactsList)
                    {
                        if (accountIdCOntactsListMap.get(c.AccountId) == null)
                        {
                            accountIdCOntactsListMap.put(c.AccountId, new List<Contact>());
                        }
                        accountIdCOntactsListMap.get(c.AccountId).add(c);
                    }
                }
                system.debug(LoggingLevel.ERROR,'accountIdCOntactsListMap: '+accountIdCOntactsListMap);
                for (String accId:accountIdCOntactsListMap.keySet()) {
                    List<Contact> contacts = accountIdCOntactsListMap.get(accID);
                    if (contacts.size() > 0) {
                        for (Contact con:contacts) {
                            system.debug(LoggingLevel.ERROR,'con in double: '+con.id+' con.Double_byte__c: '+con.Double_byte__c);
                            if (con.Double_byte__c) {
                                doubleByteAccountsList.add(accId);
                            }
                            break;
                        }
                    }
                }

                List<User> oppOwnerList = [Select id,name,email from User where id in :ownerIdList];
                Map<String,String> userEmailMap = new Map<String,String>();
                if (oppOwnerList.size() > 0) {
                    for (User u:oppOwnerList) {
                        userEmailMap.put(u.id, u.email);
                    }
                }
                EmailTemplate et = [SELECT Id FROM EmailTemplate WHERE DeveloperName ='Double_Byte_Notification'];
                Id templateId = et.id;
                system.debug(LoggingLevel.ERROR,'oppOwnerList: '+oppOwnerList.size()+' doubleByteAccountsList:'+doubleByteAccountsList.size());
                for (String doubleByteAccount:doubleByteAccountsList) {

                    String ownerId = accountIdOppMap.get(doubleByteAccount).OwnerId;
                    String reportLink = GSMUtilClass.getGSMSettingValue('DoubleByteReportLink');


                    Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(templateId, ownerId, null);

                    String emailSubject = email.getSubject();
                    String emailTextBody = email.getPlainTextBody();
                    emailTextBody = emailTextBody.replace('##opptyname##',accountIdOppMap.get(doubleByteAccount).Name);
                    emailTextBody = emailTextBody.replace('##reportlink##',reportLink+'?pv1='+doubleByteAccount.substring(0, 15));

                    email.setTargetObjectId(ownerId);
                    email.setSubject(emailSubject);
                    email.setPlainTextBody(emailTextBody);
                    email.saveAsActivity = false;
                    system.debug(LoggingLevel.ERROR,'going to send mail: '+email);
                    // Send the email
                    if (!Test.isRunningTest()) {
                        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
                    }

                }
            }
        }

    }

    //SFDC-1333 //Code-coverage
    public static void updateOnlineChannelOpptyTaskStatus(List<Opportunity> onlineChannelOpptyList)
    {
        Set<Id> opptyIds = new Set<Id>();
        List<Task> OCtaskList = new List<Task>();

        for(Opportunity opp : onlineChannelOpptyList)
        {
            opptyIds.add(opp.Id);
        }

        List<Task> contractEntryTask = [select id,WhatId from Task where Subject='Request for Contract Entry' and WhatId=:opptyIds and Status != 'Completed'];

        System.debug('Contract Entry Task '+contractEntryTask);

        for(Task t:contractEntryTask)
        {
            t.Status='Completed';
            OCtaskList.add(t);
            System.debug('Contract Entry Task '+t);
        }

        System.debug('OCtaskList '+OCtaskList);

        if(OCtaskList.size() > 0)
        {
            Database.SaveResult[] results = Database.update(OCtaskList,false);
            List<Error_log__c> erroredRecords = new List<Error_log__c>();
            for(Database.SaveResult eachResult : results)
            {
                if(!eachResult.isSuccess())
                {
                    for(Database.Error eachError : eachResult.getErrors())
                    {
                        erroredRecords.add(new Error_Log__c(Class__c='OpportunityTriggerClass', Error_Message__c=eachError.getMessage(),RecordId__c=eachResult.getId()));
                    }
                }
            }

            if(erroredRecords.size() > 0)
            {
                insert erroredRecords;//
            }
        }
    }
    //SFDC-1333

    //Start of MOB-72 //Code-coverage- QTOO
    public static void validateAccountAndOpportunityStatus(Opportunity oppObj) {

        if(oppObj.Approvals_Received__c != null) {
              /** Begin Rajesh Kumar SFDC-5781 **/
            boolean issubResellerrequired = validateforSubreseller(oppObj);
            if(issubResellerrequired && !Test.isRunningTest())
            {
                oppObj.adderror('Click on Locate Sub-Reseller button to choose a sub-reseller before approving the deal.');
                return;
            }
           /** End Rajesh Kumar SFDC-5781 **/
            if((oppObj.Deal_Reg_Account_Status__c == '' || oppObj.Deal_Reg_Account_Status__c == null
                        || oppObj.AccountId == null) &&
                    (oppObj.Registration_Status__c == 'Approved' || oppObj.Approvals_Received__c  == 'Deal Reg Approval')) {
                if(!Test.isRunningTest())
                    oppObj.adderror('Click on Locate Account button to choose an account before approving the deal');
                    }
            else if((oppObj.Deal_Reg_Opportunity_Status__c == '' || oppObj.Deal_Reg_Opportunity_Status__c == null) &&
                    (oppObj.Registration_Status__c == 'Approved')) {
                if(!Test.isRunningTest())
                    oppObj.adderror('Click on Locate Existing Opportunity button to choose an Opportunity before approving the deal');
                    }
        }
    }
    // End of MOB-72
    // Start of MOB-292
    public static void updateOnlineChannelOpptyTaskStatus(Opportunity oppObj) {

        if((oppObj.Contract_Entered_by__c == oppObj.Contract_Reviewed_by__c) && (oppObj.Transaction_Type__c == null || oppObj.Transaction_Type__c == 'Not Applicable')) // SFDC-2591
            oppObj.adderror(System.Label.Contract_Fields_Validation); //The Contract cannot be entered and reviewed by the same user
        //SFDC-2704
        if(((oppObj.Contract_Entered_by__c == oppObj.Double_Reviewed_By__c) || (oppObj.Contract_Reviewed_by__c == oppObj.Double_Reviewed_By__c)) && !String.isBlank(oppObj.Double_Reviewed_By__c)){
            system.debug(LoggingLevel.Error,'oppObj.Contract_Entered_by__c in class:: '+oppObj.Contract_Entered_by__c+' Double_Reviewed_By__c: '+oppObj.Double_Reviewed_By__c+' Contract_Reviewed_by__c: '+oppObj.Contract_Reviewed_by__c);
            oppObj.adderror(GsmUtilClass.getGSMSettingValue('CMG_Double_reviewed_Error'));
        }

    }


    //SFDC-2125
    public static Opportunity setSQLDateTime(Opportunity opp){
        if(opp.ForecastCategoryName == 'Commit' && opp.SQLDateTime__c == null){
            opp.SQLDateTime__c = DateTime.now();
        }
        return opp;
    }

    // SFDC 2720
    // Refactoring : Bringing back SFDC logic for creditcheck task here from Q2O Codebase as part of Apttus purge
    // Creates tasks on credit check
    public static void creditCheckTask(List<Opportunity> opptyList)
    {
        if(!createCreditCheckTaskFlag){
            return;
        }

        List<Task> taskList = new List<Task>();
        List<Id> accountIdList = new List<Id>();
        List<Account> accountList = new List<Account>();
        Map<Id,Boolean> accTaskGeneratedFlag = new Map<Id,Boolean>();
        // taskRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get(customSettings.order_approval_record_type_name__c).getRecordTypeId();

        for(Opportunity opp : opptyList)
            accountIdList.add(opp.AccountId);

        // SFDC -1014 - Added Account Split condition
        accountList = [Select Id, Name ,taskCreatedForCreditCheck__c,Credit_Check_Status__c, Account_Status__c From Account where Id = :accountIdList and taskCreatedForCreditCheck__c = false and (NOT Name LIKE '%Account Split%')];
        for (Account acc : accountList)
            accTaskGeneratedFlag.put(acc.Id,acc.taskCreatedForCreditCheck__c);

        List<Invoice__c> invoices  = [SELECT Invoice_Date__c,Account_Name__c From Invoice__c Where Account_Name__c in :accountIdList ORDER BY Invoice_Date__c DESC];
        Map<Id,Boolean> accountIdToBilledForLast6Months = new Map<Id,Boolean>();
        Set<Id> latestInvoiceForAccount = new Set<Id>();
        for(Invoice__c invoice : invoices) {
            if(invoice.Invoice_Date__c.daysBetween(Date.today()) > 183 && !accountIdToBilledForLast6Months.containsKey(invoice.Account_Name__c) && !latestInvoiceForAccount.contains(invoice.Account_Name__c)) {
                accountIdToBilledForLast6Months.put(invoice.Account_Name__c,true);
            }
            latestInvoiceForAccount.add(invoice.Account_Name__c);
        }

        for(Account acc : accountList){
            // Creates a task if the credit check is NULL
            if (acc.Credit_Check_Status__c == NULL || acc.Credit_Check_Status__c.length() == 0)
            {
                Task tempTask = new Task();
                tempTask.OwnerId = Q2O_Custom_Settings__c.getInstance('CollectionUser').value__c;
                tempTask.Subject = 'Credit Check Needed';
                tempTask.WhatId = acc.Id;
                tempTask.Description = 'Requires a customer credit check and response to sales.';
                taskList.add(tempTask);
                acc.taskCreatedForCreditCheck__c = true;
                accTaskGeneratedFlag.put(acc.Id,true);

            }


            // Inactive Account customer not been billed for the past 12 months
            if(acc.Credit_Check_Status__c != NULL && acc.Account_Status__c.contains('Inactive') && !accTaskGeneratedFlag.get(acc.Id)) {
                if(accountIdToBilledForLast6Months.containsKey(acc.Id)) {
                    Task tempTask = new Task();
                    tempTask.OwnerId = Q2O_Custom_Settings__c.getInstance('CollectionUser').value__c;
                    tempTask.Subject = 'Credit Check Needed';
                    tempTask.WhatId = acc.Id;
                    tempTask.Description = 'Customer Not billed for last 6 months';
                    taskList.add(tempTask);
                    acc.taskCreatedForCreditCheck__c = true;
                }
            }
        }

        if (taskList.size() > 0){
            //insert(taskList);
            GsmUtilClass.doDatabaseInsert(taskList,'OpportunityTriggerClass','creditCheckTask', false);
        }
        if (accountList.size() > 0){
            //update accountList;
            GsmUtilClass.doDatabaseUpdate(accountList,'OpportunityTriggerClass','creditCheckTask');
        }
        createCreditCheckTaskFlag = false;
    }

    // SFDC-3289 : Nagaraj Desai
    public static String getAllFieldsToValidateAndCopy() {
        // get gsm metadata which specifies which all MigrateDealRegData__mdt to query
        String metadataNamesToQuery = GSMSettings.getValue('metadataNamesForMigrateDealRegFields');
        List<MigrateDealRegData__mdt> listOfMigrateDealRegDataMDT = [SELECT Id, FieldsToCopy__c, DeveloperName FROM MigrateDealRegData__mdt WHERE DeveloperName = :metadataNamesToQuery.split(',')];

        String dealRegFieldsToCopy = '';
        for(MigrateDealRegData__mdt eachMigrateDealRegData : listOfMigrateDealRegDataMDT) {
            dealRegFieldsToCopy += eachMigrateDealRegData.FieldsToCopy__c + ',';
        }
        String duplicateOpptyFieldsToCopy = GSMSettings.getValue('duplicateOpptyFieldsToCopyForClosedDup');
        // merge all fields into single string
        String allFieldsToCopy = dealRegFieldsToCopy + duplicateOpptyFieldsToCopy;
        return allFieldsToCopy;
    }

    // SFDC-3289 : Nagaraj Desai : This function returns a Map of Opportunity Ids Vs(Map of UserId vs OpportunityTeammember)
    // This is used to segregate OpportunityTeammembers based on UserId as it is used as a specifier while cloning the OpportunityTeammembers
    // For existing user dont copy; For new user add all records
    public static Map<Id, Map<Id, List<OpportunityTeammember>>> formulateOpportunityTeammemberMap(List<Opportunity> opptyList) {
        // Create map of opptyId vs Map of User Id vs OpportunityTeammember
        Map<Id, Map<Id, List<OpportunityTeammember>>> mapOfOpptyIdVsMapOfUserIdVsTeamMembers = new Map<Id, Map<Id, List<OpportunityTeammember>>>();
        for(Opportunity eachOpportunity : opptyList) {
            List<OpportunityTeammember> opptyTeamMembers = new List<OpportunityTeammember>();
            if(eachOpportunity.OpportunityTeammembers != null) {
                opptyTeamMembers = eachOpportunity.OpportunityTeammembers;
            }
            Map<Id, List<OpportunityTeammember>> tempMapTM = new Map<Id, List<OpportunityTeammember>>();
            for(OpportunityTeammember eachOpptyTeamMember : opptyTeamMembers) {
                List<OpportunityTeammember> tempTMList = new List<OpportunityTeammember>();
                if(tempMapTM.containsKey(eachOpptyTeamMember.UserId)) {
                    tempTMList = tempMapTM.get(eachOpptyTeamMember.UserId);
                }
                tempTMList.add(eachOpptyTeamMember);
                tempMapTM.put(eachOpptyTeamMember.UserId, tempTMList);
            }
            mapOfOpptyIdVsMapOfUserIdVsTeamMembers.put(eachOpportunity.Id, tempMapTM);
        }
        return mapOfOpptyIdVsMapOfUserIdVsTeamMembers;
    }

    // SFDC-3289 : Nagaraj Desai : This function does the same as 'formulateOpportunityTeammemberMap()' but for OpportunityContactRoles with ContactId as the specifier
    public static Map<Id, Map<Id, List<OpportunityContactRole>>> formulateOpportunityContactRoleMap(List<Opportunity> opptyList) {
        // Create map of OpptyId vs Contact Id vs OpportunityContactRole
        Map<Id, Map<Id, List<OpportunityContactRole>>> mapOfOpptyIdVsMapOfContactIdVsContactRole = new Map<Id, Map<Id, List<OpportunityContactRole>>>();
        for(Opportunity eachOpportunity : opptyList) {
            List<OpportunityContactRole> opptyContactRoles = new List<OpportunityContactRole>();
            if(eachOpportunity.OpportunityContactRoles != null) {
                opptyContactRoles = eachOpportunity.OpportunityContactRoles;
            }
            Map<Id, List<OpportunityContactRole>> tempMapCR = new Map<Id, List<OpportunityContactRole>>();
            for(OpportunityContactRole eachOpptyCR : opptyContactRoles) {
                List<OpportunityContactRole> tempCRList = new List<OpportunityContactRole>();
                if(tempMapCR.containsKey(eachOpptyCR.ContactId)) {
                    tempCRList = tempMapCR.get(eachOpptyCR.ContactId);
                }
                tempCRList.add(eachOpptyCR);
                tempMapCR.put(eachOpptyCR.ContactId, tempCRList);
            }
            mapOfOpptyIdVsMapOfContactIdVsContactRole.put(eachOpportunity.Id, tempMapCR);
        }
        return mapOfOpptyIdVsMapOfContactIdVsContactRole;
    }

    public static Map<Id, List<Deal_Support_Request__c>> formualteDealSupportRequestMap(List<Opportunity> opptyList) {
        Map<Id, List<Deal_Support_Request__c>> mapOfDuplicateOpptyVsListOfDealSupportRequest = new Map<Id, List<Deal_Support_Request__c>>();
        for(Opportunity eachOppty : opptyList) {
            if(eachOppty.Presales_Engagements__r != null) {
                mapOfDuplicateOpptyVsListOfDealSupportRequest.put(eachOppty.Id, eachOppty.Presales_Engagements__r);
            }
        }
        return mapOfDuplicateOpptyVsListOfDealSupportRequest;
    }

    // SFDC-3289 : Nagaraj Desai
    public static void updateRequiredDuplicateOpptyDetails(List<Opportunity> listOfDuplicateOpportunity, Set<Id> setOfOriginalOpptyIds) {
        String allFieldsToCopy = getAllFieldsToValidateAndCopy();
        // SFDC-8974
        // When oppty is marked as closed duplicate and if its an indirect opportunity and Associated Partner Lead is present, Copy Associated Partner Lead field as well and not Associated_Lead__c.
        for(Opportunity singleOpp: listOfDuplicateOpportunity){
            if(singleOpp.Deal_Type__c!=null && singleOpp.Deal_Type__c.equalsIgnoreCase('Indirect') && singleOpp.Associated_Partner_Lead__c!=null && allFieldsToCopy.containsIgnoreCase('Associated_Lead__c')){
                allFieldsToCopy = allFieldsToCopy.replace('Associated_Lead__c','Associated_Partner_Lead__c');
            }
        }
        Set<String> setOfFields = new Set<String>(allFieldsToCopy.split(','));

        // get set of all oppty Ids (Both duplicate and original) to query OpportunityTeammember & OpportunityContactRole
        Set<Id> allOpptyIds = new Set<Id>(setOfOriginalOpptyIds);
        for(Opportunity eachDuplicateOppty : listOfDuplicateOpportunity) {
            allOpptyIds.add(eachDuplicateOppty.Id);
        }
        // get opportunities and Related OpportunityTeammembers, OpportunityContactRoles
        String soql = 'SELECT ';
        for(String eachField : setOfFields) {
            soql += eachField + ', ';
        }
        soql += '(SELECT OpportunityTeammember.Id, OpportunityTeammember.UserId, OpportunityTeammember.TeamMemberRole FROM OpportunityTeammembers),';
        soql += '(SELECT OpportunityContactRole.Id, OpportunityContactRole.ContactId, OpportunityContactRole.Role, OpportunityContactRole.IsPrimary FROM OpportunityContactRoles),';
        soql += '(SELECT Close_Plan__c.Id FROM Close_Plans__r),';
        soql += '(SELECT Deal_Support_Request__c.Id FROM Presales_Engagements__r) ';
        soql += 'FROM Opportunity WHERE Id = :allOpptyIds';
        Map<Id, Opportunity> opportunityFamily = new Map<Id, Opportunity>((List<Opportunity>)Database.query(soql));

        // Create map of opptyId vs Map of User Id vs OpportunityTeammember
        Map<Id, Map<Id, List<OpportunityTeammember>>> mapOfOpptyIdVsMapOfUserIdVsTeamMembers = formulateOpportunityTeammemberMap(opportunityFamily.values());
        // Create map of OpptyId vs Contact Id vs OpportunityContactRole
        Map<Id, Map<Id, List<OpportunityContactRole>>> mapOfOpptyIdVsMapOfContactIdVsContactRole = formulateOpportunityContactRoleMap(opportunityFamily.values());

        Map<Id, List<Deal_Support_Request__c>> mapOfDuplicateOpptyVsListOfDealSupportRequest = formualteDealSupportRequestMap(opportunityFamily.values());

        //single list to update original opptys
        List<Opportunity> listOfOriginalOpptysToUpdate = new List<Opportunity>();
        // single list to insert OpportunityTeammembers of duplicate oppty to original oppty
        List<OpportunityTeammember> listOfOpportunityTeamMembersToMove = new List<OpportunityTeammember>();
        // single list to insert OpportunityContactRoles of duplicate oppty to original oppty
        List<OpportunityContactRole> listOfOpportunityContactRoleToMove = new List<OpportunityContactRole>();
        // single list to insert DealSupportRequest of duplicate oppty to original oppty
        List<Deal_Support_Request__c> listOfDealSupportRequestToMove = new List<Deal_Support_Request__c>();
        // single list to move ClosePlan of duplicate oppty to original oppty
        List<Close_Plan__c> listOfClosePlanToMove = new List<Close_Plan__c>();

        Set<Id> setOfUpdatedOriginalOpptyIds = new Set<Id>();
        for(Opportunity eachDuplicateOppty : listOfDuplicateOpportunity) {
            if(eachDuplicateOppty.Duplicate_Opportunity__c != null && setOfOriginalOpptyIds.contains(eachDuplicateOppty.Duplicate_Opportunity__c) && !setOfUpdatedOriginalOpptyIds.contains(eachDuplicateOppty.Duplicate_Opportunity__c)) {
                Opportunity originalOppty = opportunityFamily.get(eachDuplicateOppty.Duplicate_Opportunity__c);
                setOfUpdatedOriginalOpptyIds.add(originalOppty.Id);

                // specifies weather the current oppty requires update
                Boolean updateRequired = false;
                // verify if original oppty field is empty and populate data from duplicate oppty
                for(String eachField : setOfFields) {
                    eachField = eachField.trim();
                    if((originalOppty.get(eachField) == null || String.valueOf(originalOppty.get(eachField)) == '')
                            && (eachDuplicateOppty.get(eachField) != null && String.valueOf(eachDuplicateOppty.get(eachField)) != '')) {
                        originalOppty.put(eachField, eachDuplicateOppty.get(eachField));
                        updateRequired = true;
                            }
                }
                if(updateRequired) {
                    listOfOriginalOpptysToUpdate.add(originalOppty);
                }

                Map<Id, List<OpportunityTeammember>> mapOfUserIdVsDuplicateOpptyTeammembers = mapOfOpptyIdVsMapOfUserIdVsTeamMembers.get(eachDuplicateOppty.Id);
                Map<Id, List<OpportunityTeammember>> mapOfUserIdVsOriginalOpptyTeammembers = mapOfOpptyIdVsMapOfUserIdVsTeamMembers.get(originalOppty.Id);
                if(mapOfUserIdVsDuplicateOpptyTeammembers != null) {
                    for(Id eachUserId : mapOfUserIdVsDuplicateOpptyTeammembers.keySet()) {
                        List<OpportunityTeammember> opptyTMList = mapOfUserIdVsDuplicateOpptyTeammembers.get(eachUserId);
                        if(opptyTMList != null && (mapOfUserIdVsOriginalOpptyTeammembers == null || (mapOfUserIdVsOriginalOpptyTeammembers != null && !mapOfUserIdVsOriginalOpptyTeammembers.containsKey(eachUserId)))) {
                            for(OpportunityTeammember eachOpptyTM : opptyTMList) {
                                // clone the OpportunityTeammember of duplicate oppty and map the clone to Original Oppty
                                OpportunityTeammember newOPTM = eachOpptyTM.clone(false, true, false, false);
                                newOPTM.OpportunityId = originalOppty.Id;
                                listOfOpportunityTeamMembersToMove.add(newOPTM);
                            }
                        }
                    }
                }

                Map<Id, List<OpportunityContactRole>> mapOfContactIdVsDuplicateContactRole = mapOfOpptyIdVsMapOfContactIdVsContactRole.get(eachDuplicateOppty.Id);
                Map<Id, List<OpportunityContactRole>> mapOfContactIdVsOriginalContactRole = mapOfOpptyIdVsMapOfContactIdVsContactRole.get(originalOppty.Id);

                if(mapOfContactIdVsDuplicateContactRole != null) {
                    for(Id eachContactId : mapOfContactIdVsDuplicateContactRole.keySet()) {
                        List<OpportunityContactRole> opptyCRList = mapOfContactIdVsDuplicateContactRole.get(eachContactId);
                        if(opptyCRList != null && (mapOfContactIdVsOriginalContactRole == null || (mapOfContactIdVsOriginalContactRole != null && !mapOfContactIdVsOriginalContactRole.containsKey(eachContactId)))) {
                            for(OpportunityContactRole eachOpptyCR : opptyCRList) {
                                // clone the OpportunityContactRole of duplicate oppty and map the clone to Original Oppty
                                OpportunityContactRole newCR = eachOpptyCR.clone(false, true, false, false);
                                newCR.OpportunityId = originalOppty.Id;
                                listOfOpportunityContactRoleToMove.add(newCR);
                            }
                        }
                    }
                }

                if(mapOfDuplicateOpptyVsListOfDealSupportRequest != null && mapOfDuplicateOpptyVsListOfDealSupportRequest.containsKey(eachDuplicateOppty.Id)) {
                    List<Deal_Support_Request__c> listOfDSR = mapOfDuplicateOpptyVsListOfDealSupportRequest.get(eachDuplicateOppty.Id);
                    for(Deal_Support_Request__c eachDSR : listOfDSR) {
                        eachDSR.Opportunity__c = originalOppty.Id;
                        eachDSR.Validation_Override__c = true;
                        listOfDealSupportRequestToMove.add(eachDSR);
                    }
                }

                if(originalOppty.Close_Plans__r.size() == 0 && opportunityFamily.get(eachDuplicateOppty.Id).Close_Plans__r.size() > 0){
                    for(Close_Plan__c cp : opportunityFamily.get(eachDuplicateOppty.Id).Close_Plans__r){
                        cp.Opportunity__c = originalOppty.Id;
                        cp.Validation_Override__c = true;
                        listOfClosePlanToMove.add(cp);
                    }
                }
            }
        }

        if(listOfOriginalOpptysToUpdate.size() > 0) {
            try {
                update listOfOriginalOpptysToUpdate;
            } catch (Exception e) {
                Error_log__c erroLog = new Error_log__c(Name = 'Close Duplicate Opportunity Update Error', Class__c = 'OpportunityTriggerClass',Error_Message__c = e.getMessage());
                insert erroLog;
            }
        }
        if(listOfOpportunityTeamMembersToMove.size() > 0) {
            try {
                insert listOfOpportunityTeamMembersToMove;
            } catch (Exception e) {
                Error_log__c erroLog = new Error_log__c(Name = 'Close Duplicate Opportunity Team Member Insert Error', Class__c = 'OpportunityTriggerClass',Error_Message__c = e.getMessage());
                insert erroLog;
            }
        }
        if(listOfOpportunityContactRoleToMove.size() > 0) {
            try {
                insert listOfOpportunityContactRoleToMove;
            } catch (Exception e) {
                Error_log__c erroLog = new Error_log__c(Name = 'Close Duplicate Opportunity Contact Role Insert Error', Class__c = 'OpportunityTriggerClass',Error_Message__c = e.getMessage());
                insert erroLog;
            }
        }
        if(listOfDealSupportRequestToMove.size() > 0) {
            try {
                update listOfDealSupportRequestToMove;
            } catch (Exception e) {
                Error_log__c erroLog = new Error_log__c(Name = 'Close Duplicate Deal Support Request Update Error', Class__c = 'OpportunityTriggerClass',Error_Message__c = e.getMessage());
                insert erroLog;
            }
        }
        if(listOfClosePlanToMove.size() > 0) {
            try {
                update listOfClosePlanToMove;
            } catch (Exception e) {
                Error_log__c erroLog = new Error_log__c(Name = 'Close Duplicate Close Plan Update Error', Class__c = 'OpportunityTriggerClass',Error_Message__c = e.getMessage());
                insert erroLog;
            }
        }
    }

    public static void createOpportunityTeamMember(Map<Id,Set<Id>> accountOpportunityIds) {
        List<Id> accountIds = new List<Id>();
        List<OpportunityTeamMember> oppMemRecs = new List<OpportunityTeamMember>();
        OpportunityTeamMember oppMemRec;
        for(Id accId : accountOpportunityIds.keyset()){
            accountIds.add(accId);
        }
        system.debug('AccountIds = '+accountIds);
        for(AccountTeamMember teamMemObj : [Select Id, AccountAccessLevel, TeamMemberRole,
                UserId, AccountId, OpportunityAccessLevel
                from AccountTeamMember where AccountId In :accountIds
                AND TeamMemberRole = 'Technical Sales - Primary']) {
            system.debug('teamMemObj = '+teamMemObj);
            for(Id oppId : accountOpportunityIds.get(teamMemObj.AccountId)) {
                system.debug('oppId = '+oppId);
                oppMemRec = new OpportunityTeamMember();
                oppMemRec.OpportunityId = oppId;
                oppMemRec.OpportunityAccessLevel = 'Edit';
                oppMemRec.TeamMemberRole = 'Technical Sales - Primary';
                oppMemRec.UserId = teamMemObj.UserId;
                oppMemRecs.add(oppMemRec);
            }
                }
        system.debug('oppMemRecs = '+oppMemRecs);
        Insert oppMemRecs;
    }

    //SFDC-3535  Add/Remove Opportunity Team memeber for change in Opportunity Leader
    //SFDC-4292 - Passing unique map of Oppty to it's Old Leader for Delete of OTM
    public static void createDeleteOTMForLeader(Map<Id,Id> opptyIdToLeaderIdMapToAddOTM,Map<Id,Id> opptyToOTMUserIdMap){

        List<OpportunityTeamMember> oppMemRecsToAdd = new List<OpportunityTeamMember>();
        List<OpportunityTeamMember> oppMemRecs = new List<OpportunityTeamMember>();

        if(!opptyIdToLeaderIdMapToAddOTM.isEmpty())
        {
            OpportunityTeamMember oppMemRec;
            for(Id oppId : opptyIdToLeaderIdMapToAddOTM.keyset()) {
                oppMemRec = new OpportunityTeamMember();
                oppMemRec.OpportunityId = oppId;
                oppMemRec.OpportunityAccessLevel = 'Edit';
                oppMemRec.TeamMemberRole = 'Sales - Secondary';
                oppMemRec.UserId = opptyIdToLeaderIdMapToAddOTM.get(oppId);
                oppMemRecsToAdd.add(oppMemRec);
            }
        }
        List<OpportunityTeamMember> oppMemRecsToDelete = new List<OpportunityTeamMember>();

        if(!opptyToOTMUserIdMap.isEmpty())
        {

            oppMemRecs = [Select Id,OpportunityId,UserId From OpportunityTeamMember Where OpportunityId IN :opptyToOTMUserIdMap.keyset() AND UserId IN :opptyToOTMUserIdMap.values() AND TeamMemberRole = 'Sales - Secondary'];

        }
        if(oppMemRecs.size() > 0)
        {
            for(OpportunityTeamMember otmRec: oppMemRecs)
            {
                if(opptyToOTMUserIdMap.containsKey(otmRec.OpportunityId) && otmRec.UserID == opptyToOTMUserIdMap.get(otmRec.OpportunityId))
                    oppMemRecsToDelete.add(otmRec);
            }

        }

        System.Debug(LoggingLevel.Error, 'HC Before Insert of OTM '+oppMemRecsToAdd);

        DMLResults addResults = new DMLResults();
        if(oppMemRecsToAdd.size() > 0){
            addResults.add(Database.insert(oppMemRecsToAdd,false),oppMemRecsToAdd);
            addResults.withClassName('OpportunityTriggerClass-OpportunityLeader').insertRecordsInErrorLog();
        }

        DMLResults removeResults = new DMLResults();
        if(oppMemRecsToDelete.size() > 0){
            removeResults.add(Database.delete(oppMemRecsToDelete,false),oppMemRecsToDelete);
            removeResults.withClassName('OpportunityTriggerClass-OpportunityLeader').insertRecordsInErrorLog();
        }

    }

    /* Start of SFDC-3663, SFDC-4550 */
    @future
    public static void uncheckPullForward(){
        List<Opportunity> oppListToUpdate = new List<Opportunity>();
        for(Opportunity op : [select Id, Pull_Forward__c, PAE_Pull_Forward__c, ForecastCategoryName, CloseDate, Partner_Forecast__c, PAE_Close_Date__c, Validation_Override__c from Opportunity where IsClosed=false AND
                ((Pull_Forward__c=true AND (ForecastCategoryName != 'Commit' OR CloseDate <= THIS_MONTH)) OR
                 (PAE_Pull_Forward__c=true AND (Partner_Forecast__c != 'Commit' OR PAE_Close_Date__c <= THIS_MONTH)))])
        {
            if(op.Pull_Forward__c && (op.ForecastCategoryName != 'Commit') || op.CloseDate.Year() < System.Today().Year() || (op.CloseDate.Year() == System.Today().Year() && op.CloseDate.Month() <= System.Today().Month()))
                op.Pull_Forward__c = false;
            if(op.PAE_Pull_Forward__c && (op.Partner_Forecast__c != 'Commit') || op.PAE_Close_Date__c.Year() < System.Today().Year() || (op.PAE_Close_Date__c.Year() == System.Today().Year() && op.PAE_Close_Date__c.Month() <= System.Today().Month()))
                op.PAE_Pull_Forward__c = false;
            op.Validation_Override__c = true;
            oppListToUpdate.add(op);
        }
        DMLResults updateResults = new DMLResults();
        if(oppListToUpdate.size() > 0){
            updateResults.add(Database.update(oppListToUpdate,false),oppListToUpdate);
            updateResults.withClassName('OpportunityTriggerClass-UncheckPullForward').insertRecordsInErrorLog();
        }
        Integer errCount = [select count() from Error_Log__c where Name = 'OpportunityTriggerClass-UncheckPullForward' AND CreatedDate = TODAY];
        string results = 'Total records to be updated: '+oppListToUpdate.size()+', Success: '+(oppListToUpdate.size()-errCount)+', Failure: '+errCount;
        Util.updateCronRunWithResult('Uncheck Pull Forward On Opportunity', results);
    }
    /* End of SFDC-3663, SFDC-4550 */

    /* SFDC - 5392 Removed related trial opportunity
    Start of SFDC-3921
    @future
    public static void updateTrialOpptyWithSalesOppty(Map<Id,Id> trialToSalesOpptyMap){
        List<Opportunity> trialOpptyListToUpdate = new List<Opportunity>();
        for(Id trialOpptyId : trialToSalesOpptyMap.keySet()){
            Opportunity op = new Opportunity();
            op.Id = trialOpptyId;
            op.Opportunity_Type__c = 'Automated Trial';
            op.Parent_Buy_Opportunity__c = trialToSalesOpptyMap.get(trialOpptyId);
            op.Validation_Override__c = true;
            trialOpptyListToUpdate.add(op);
        }
        DMLResults updateResults = new DMLResults();
        if(trialOpptyListToUpdate.size() > 0){
            updateResults.add(Database.upsert(trialOpptyListToUpdate,false),trialOpptyListToUpdate);
            updateResults.withClassName('OpportunityTriggerClass').insertRecordsInErrorLog();
        }
    }
     End of SFDC-3921 */

   /* Start of SFDC-3543 */
// Modified autoAssignSpecialist to return Oppty list for SFDC - 8958  
public static Map<Id, Opportunity> autoAssignSpecialist(List<OpportunityLineItem> OLItems, Set<Id> OppIds){


        if(!autoAssignSpecialistFirstRunFlag)
            return new Map<Id,Opportunity>();
        Map<Id,String> oppIdsToSubTerritory = new Map<Id,String>();
        Map<Id,String> oppIdToOpptyType = new Map<Id,String>();
        Set<String> SubTerritory = new Set<String>();
        //Set<String> opptyType = new Set<String>();
        Map<String, Id> SubTerritoryToSpecialist = new Map<String, Id>();
        Set<Id> SpecialistUser = new Set<Id>();
        //Set<opportunityteammember> otm = new Set<opportunityteammember>();
        Set<opportunity> oppSet = new Set<opportunity>();

        for(Opportunity opp : [Select id, account.Anaplan_Sub_Territory__c,Opportunity_Type__c from opportunity where id IN : OppIds]){
            oppIdsToSubTerritory.put(opp.Id, opp.account.Anaplan_Sub_Territory__c);
            SubTerritory.add(opp.account.Anaplan_Sub_Territory__c);
            //opptyType.add(opp.Opportunity_Type__c);
            if(opp.Opportunity_Type__c == '' || opp.Opportunity_Type__c == null)
                opp.Opportunity_Type__c = 'EMPTY';
            oppIdToOpptyType.put(opp.Id,opp.Opportunity_Type__c);

        }
        system.debug('Oppty Map '+oppIdsToSubTerritory +' Other Map '+oppIdToOpptyType);
        //SFDC-6771 - Added logic to inlcude Oppty Type as a parameter - Map pf Sub Territory to Map of User to Oppty Type
        Map<String,Id> territoryUserTypeToOTypeMap = new Map<String,Id>();
        for(Specialist_Territory_Mapping__c STM : [Select Sub_Territory_Name__c, Specialist_User__c, User_Type__c,Opportunity_Type__c from Specialist_Territory_Mapping__c where Sub_Territory_Name__c IN :SubTerritory and User_Type__c='ESR' and Specialist_User__r.isActive = true])
           {
                if(STM.Opportunity_Type__c == '' || STM.Opportunity_Type__c == null)
                    STM.Opportunity_Type__c = 'EMPTY';
                String mapKey = STM.Sub_Territory_Name__c+':'+STM.User_Type__c+':'+STM.Opportunity_Type__c;
                territoryUserTypeToOTypeMap.put(mapKey,STM.Specialist_User__c);

                SpecialistUser.add(STM.Specialist_User__c);
            }
        Map<Id, Id> SpecialistcompToSpecialistUser = new Map<Id, Id>();

        for(Specialist_Comp_Team__c SCT : [Select id, Product_Specialist__c from Specialist_Comp_Team__c where Product_Specialist__c IN :SpecialistUser]){
            SpecialistcompToSpecialistUser.put(SCT.Product_Specialist__c, SCT.id);
        }
        system.debug('Specialist Map '+territoryUserTypeToOTypeMap +'Comp Team Map '+SpecialistcompToSpecialistUser);
        //SFDC-6771 - Assign the Specialist user based on Oppty's Account's Territory and Type
        for(OpportunityLineItem oli : OLItems){

            opportunity opp = new opportunity(Id = oli.opportunityId);
            String opptyType ='';
            String mapKeyActual ='';
            String mapKeyEmpty = '';
            Id spUserId ;
            if(!oppIdToOpptyType.isEmpty() && oppIdToOpptyType.containsKey(opp.Id) )
                opptyType = oppIdToOpptyType.get(opp.Id);
            if(oppIdsToSubTerritory.containsKey(opp.Id)  )
                 {
                     mapKeyActual = oppIdsToSubTerritory.get(opp.Id)+':'+'ESR'+':'+opptyType;
                     mapKeyEmpty =  oppIdsToSubTerritory.get(opp.Id)+':'+'ESR'+':'+'EMPTY';
                 }
            system.debug('Key1 '+mapKeyActual +'Key 2'+mapKeyEmpty+' Map '+territoryUserTypeToOTypeMap);
            if(!territoryUserTypeToOTypeMap.isEmpty())
            {
                if(territoryUserTypeToOTypeMap.containsKey(mapKeyActual))
                    spUserId = territoryUserTypeToOTypeMap.get(mapKeyActual);
                else if(territoryUserTypeToOTypeMap.containsKey(mapKeyEmpty))
                    spUserId = territoryUserTypeToOTypeMap.get(mapKeyEmpty);
            }
            system.debug('Specialist user '+spUserId);

            if(!SpecialistcompToSpecialistUser.isEmpty() && SpecialistcompToSpecialistUser.containsKey(spUserId))
            {
                opp.Soha_Specialist__c = SpecialistcompToSpecialistUser.get(spUserId);
                opp.Validation_Override__c = true;
                oppSet.add(opp);
            }
        }
        system.debug('Updated Oppy '+oppSet);
        //Converting Set to list
        //// SFDC - 8958 - Conslidating Oppty updates from OpptyLineItem, Commenting Oppty DML below.
       /*List<opportunity> oppList = new List<opportunity>();
            oppList.addAll(oppSet);*/
            Map<Id,Opportunity> opptyMap=new Map<Id,Opportunity>();
            for(Opportunity opp : oppSet)
                opptyMap.put(opp.Id, opp);  
            //SFDC-6771 - Added error log
            
           /* DMLResults updateResults = new DMLResults();
            if(oppList.size() > 0)
            {
                updateResults.add(Database.update(oppList,false),oppList);
                updateResults.withClassName('OpportunityTriggerClass-ESR-Specialist').insertRecordsInErrorLog();
            }*/
            /*if(oppList.size()>0)
                Update oppList;*/
            autoAssignSpecialistFirstRunFlag = false;
    
            return opptyMap;
    }

    /* End of SFDC-3543 */

    //SFDC-5774 - Added By Prabhanjan - Need to merge 2 autoassign specialist functions
    //Modified the method to accomodate Prolexic product SFDC-8125
    // Modified autoAssignSpecialist to return Oppty Set for SFDC - 8958
    /** Modified following for SFDC -8958
     * - Changed Reurn type from void to Map<Id,Opportunity>
     * - Added Map<Id, Opportunity> opptyMap as additional method paramter 
     * - Added logic to use Opportunity instance from Opptymap and creating new instance only if Oppty object instance doesn't exists in map
     * */
    public static Map<Id,Opportunity> autoAssignCIAMSpecialist(Set<Id> OppIds,Map<OpportunityLineItem,string> productUserType,Map<Id, Opportunity> opptyMap){
        Map<Id,String> oppIdsToSubTerritory = new Map<Id,String>();
        Set<String> SubTerritory = new Set<String>();
        Map<String, Id> SubTerritoryToSpecialist = new Map<String, Id>();
        Set<Id> SpecialistUser = new Set<Id>();
        Set<opportunity> oppSet = new Set<opportunity>();
        List<opportunity> oppList=null;
        for (Opportunity opp : [Select id, account.Anaplan_Sub_Territory__c from opportunity where id IN : OppIds]) {
            oppIdsToSubTerritory.put(opp.Id, opp.account.Anaplan_Sub_Territory__c);
            SubTerritory.add(opp.account.Anaplan_Sub_Territory__c);
        }

        if(SubTerritory.size() > 0) {
            for (Specialist_Territory_Mapping__c STM : [Select Sub_Territory_Name__c, Specialist_User__c, User_Type__c,Opportunity_Type__c from Specialist_Territory_Mapping__c where Sub_Territory_Name__c IN :SubTerritory and User_Type__c IN ('CIAM','Prolexic') and Specialist_User__r.isActive = true and Opportunity_Type__c = null]) {

                SubTerritoryToSpecialist.put(STM.Sub_Territory_Name__c + STM.User_Type__c, STM.Specialist_User__c);
                SpecialistUser.add(STM.Specialist_User__c);
            }
        }

        Map<string, Id> SpecialistcompToSpecialistUser = new Map<string, Id>();
        if(SpecialistUser.size() > 0) {
            for (Specialist_Comp_Team__c SCT : [Select id, Product_Specialist__c,Type__c from Specialist_Comp_Team__c where Product_Specialist__c IN :SpecialistUser and Type__c IN ('CIAM Specialist','Security Specialist')]) {
                    string userTypes='';
                   if(SCT.Type__c == 'CIAM Specialist')
                      userTypes='CIAM';
                   if(SCT.Type__c == 'Security Specialist')
                      userTypes='Prolexic';
                SpecialistcompToSpecialistUser.put(SCT.Product_Specialist__c+userTypes, SCT.id);
            }
        }

        //Map<id,opportunity> opptytoupdate = new Map<Id,opportunity>();
        // Using opptyMap which is being passed in the parameter, as part of SFDC-8958
        if(SpecialistcompToSpecialistUser.size() > 0) {
            for (OpportunityLineItem oli : productusertype.keyset()) {
                opportunity opp;    
                if(opptyMap.containskey(oli.opportunityId)){
                    opp = opptyMap.get(oli.opportunityId);
                    //opptytoupdate.remove(oli.opportunityId); - Need to check with Ambica why remove is used here.
                
                }else{
                     opp = new opportunity(Id = oli.opportunityId);
                }
                if(productusertype.get(oli)=='CIAM')
                    opp.CIAM_Specialist__c  = SpecialistcompToSpecialistUser.get(SubTerritoryToSpecialist.get(oppIdsToSubTerritory.get(oli.OpportunityId)+'CIAM')+'CIAM');
                if(productusertype.get(oli)=='Prolexic')
                    opp.Security_Specialist__c  = SpecialistcompToSpecialistUser.get(SubTerritoryToSpecialist.get(oppIdsToSubTerritory.get(oli.OpportunityId)+'Prolexic')+'Prolexic');
               
                opp.Validation_Override__c = true;
                opptyMap.put(oli.opportunityId,opp);
            }
            
            /*if(opptytoupdate.values().size() > 0) {
                update opptytoupdate.values();
            }*/
        }
        return opptyMap;
    }


    public static void updateCampaignForDealReg(List<Id> dealRegsIds) {

        if(!updateCampaignOnDealRegFirstRunFlag)
            return;

        List<Opportunity> dealRegs = [Select id,name,CampaignId,Partner_Marketing_Activity__c From Opportunity where id iN :dealRegsIds];

        List<Id> pmaIdList = new List<Id>();
        Map<Id,Id> pmaToCampaignIdMap = new Map<Id,Id>();

        for (Opportunity op:dealRegs) {
            pmaIdList.add(op.Partner_Marketing_Activity__c);
        }

        for (Partner_Marketing_Activity__c pma:[Select id,Indirect_Campaign__c
                From Partner_Marketing_Activity__c
                Where id IN:pmaIdList]) {

            pmaToCampaignIdMap.put(pma.id, pma.Indirect_Campaign__c);
                }

        for (opportunity opp:dealRegs) {
            System.debug('Updating campaignid from'+opp.name);
            opp.CampaignId = pmaToCampaignIdMap.get(opp.Partner_Marketing_Activity__c);
        }

        update dealRegs;

        updateCampaignOnDealRegFirstRunFlag = false;
    }

    //SFDC-4136
    public static void updateOpptyContractReviewedBy(List<Opportunity> contractReviewedChange){
        User userAlias = [select Id,Alias from User where Id = :UserInfo.getUserId() limit 1];
        for(Opportunity oppty : contractReviewedChange)
            oppty.Contract_Reviewed_by__c = userAlias.Alias;
    }

    // SFDC-5138 Sausharm : changes for Opportunity product's special forecast category and specialist close date
    // when Opportunity is closed
    //SFORCE-102
    @future
    public static void updateSpecialistFieldsOnClosedOpp(List<String> opptyList)
    {
        if(!specialForecastCategoryFirstRunFlag){
            return;
        }

        List<OpportunityLineItem> oliToUpdate = new List<OpportunityLineItem>();
        for(OpportunityLineItem oi : [Select Id,Specialist_Forecast_Category__c,Opportunity.StageName,Specialist_Close_Date__c,Opportunity.CloseDate
                from OpportunityLineItem where
                OpportunityId in : opptyList ])
        {
            if(oi.Opportunity.StageName == 'Closed Lost' || oi.Opportunity.StageName == 'Closed Duplicate')
            {
                oi.Specialist_Forecast_Category__c = 'Omitted';
                oi.Specialist_Close_Date__c = oi.Opportunity.CloseDate;
                oi.Validation_Override__c = true;
                oliToUpdate.add(oi);
            }
            else if(oi.Opportunity.StageName == 'Closed Won' || oi.Opportunity.StageName == 'Closed Contract Ended')
            {
                oi.Specialist_Forecast_Category__c = 'Closed';
                oi.Specialist_Close_Date__c = oi.Opportunity.CloseDate;
                oi.Validation_Override__c = true;
                oliToUpdate.add(oi);
            }
            else if(oi.Opportunity.StageName == '6. Signed')
            {
                oi.Specialist_Close_Date__c = oi.Opportunity.CloseDate;
                oi.Validation_Override__c = true;
                oliToUpdate.add(oi);
            }
        }
        if(oliToUpdate.size() > 0)
        {
            //GsmUtilClass.doDatabaseInsert(oliToUpdate,'OpportunityTriggerClass','updateSpecialistFieldsOnClosedOpp', false);
            ByPassAndLimitUtils.disable('OpportunityLineItemTrigger');
            GsmUtilClass.doDatabaseUpdate(oliToUpdate,'OpportunityTriggerClass','updateSpecialistFieldsOnClosedOpp');
        }
        specialForecastCategoryFirstRunFlag = false;
    }

    //SFDC-5295
    public static void updateOLISpecialistCloseDates(List<Opportunity> closeDateChangedOpptys)
    {
        List<OpportunityLineItem> oliToUpdate = [Select Id,Specialist_Close_Date__c,Opportunity.CloseDate from OpportunityLineItem where OpportunityId in : closeDateChangedOpptys and Specialist_Close_Date_Touched__c = false ];

        for(OpportunityLineItem oi : oliToUpdate)
        {
            oi.Specialist_Close_Date__c = oi.Opportunity.CloseDate;
        }

        if(oliToUpdate.size() > 0)
        {
            update oliToUpdate;
        }
    }
    //End of SFDC-5295

    /** Begin Rajesh Kumar SFDC-5781 **/
public static boolean validateforSubreseller(Opportunity oppty)
{
boolean issrRequired = false ;
List<String> subresPartlis = GsmUtilClass.getGSMSettingValue('Sub_reseller_partner_list').split(';');
 //subresPartlis = GsmUtilClass.getGSMSettingValue('Sub_reseller_partner_list').split(';');
        for (String srprtner : subresPartlis)
        {
        if (oppty.partner_involved__c == srprtner && String.isBlank(oppty.Sub_Reseller_Account__c))
         {
          issrRequired = true;
          return issrRequired;
         }
        }
return issrRequired;

}
/** End Rajesh Kumar SFDC-5781 **/
//SFDC-5991
public static Map<Id,SubReseller__c> fetchSubResellerMap(Set<Id> subresList){
    if(!fetchSubReseller && subMap != null)
        return subMap;
    subMap = new Map<Id,SubReseller__c>([Select id,Name,Account__c from SubReseller__c where Id in :subresList ]);
    fetchSubReseller = false;
    return subMap;
}
//SFDC-8991 - Commenting //SFDC-6398
    /*public static void switchToAutoRenewalType(List<Opportunity> opptyIdList)
        {
            if(!switchToAutoRenewalTypeFirstRunFlag)
            return;
            List<OpportunityLineItem> oliListToCheck =  [Select Id,Average_Renewal_Commit_MRR__c,Average_Renewal_Usage_MRR__c,MRR__c,EMRI__c,OpportunityId from OpportunityLineItem where OpportunityId in :opptyIdList ];
            Map<Opportunity,List<OpportunityLineItem>> opptyToOLIlistMap = new Map<Opportunity,List<OpportunityLineItem>>();
            List<Opportunity> opptyListToUpdate = new List<Opportunity>();
            Set<Id> opptyIdToRemove = new Set<Id>();

        //Check if all the existing products are baseline and have a net MRR and EMRI set as 0 then auto switch to auto renewal.
            if(oliListToCheck.size() > 0)
            {
                for(OpportunityLineItem oli : oliListToCheck)
                    {
                        if(oli.MRR__c != 0 || oli.EMRI__c != 0 || oli.Average_Renewal_Commit_MRR__c == null || oli.Average_Renewal_Usage_MRR__c == null)
                            opptyIdToRemove.add(oli.OpportunityId);
                    }
            }

            for(Opportunity oppRec : opptyIdList )
            {
                if(!opptyIdToRemove.contains(oppRec.Id))
                    {
                        oppRec.Opportunity_Type__c ='Auto-Renewal';
                    }
            }
            switchToAutoRenewalTypeFirstRunFlag = false;

        }*/
        //SFDC-6398 On delete of the line item if there are no other non baseline line items and net value of MRR/EMRI is 0 then switch to auto renew
    public static Map<Id,Opportunity> switchToAutoRenewalTypeFromOLI(Set<Id> opptyIdSet,List<Id> opptyOLISet,Map<Id,opportunity> opptyMap)
        {
            if(!switchToAutoRenewalTypeOLIFirstRunFlag)
                    return opptyMap;
            List<Opportunity> opptyList = [Select Id, Opportunity_Type__c,(Select Id,MRR__c,EMRI__c,Average_Renewal_Commit_MRR__c,Average_Renewal_Usage_MRR__c from opportunitylineitems) from opportunity where Id in :opptyIdSet and Auto_Renewal__c = True and MRR__c = 0 and Opportunity_Revenue_Impact__c = 0];
            List<Opportunity> opptyListToUpdate = new List<Opportunity>();
            //Set<Id> opptyIdToRemove = new Set<Id>(); - Commented by Chandra Not used

            if(opptyList.size() > 0)
            {
                for(Opportunity oppty : opptyList)
                    {
                        Boolean isNotAutoRenewalOppty = false;
                        Opportunity oppToUpdate=OpportunityUtilClass.getOpportunityRecord(opptyMap,oppty.Id);

                        for(OpportunityLineItem oli : oppty.opportunitylineitems)
                            {
                                if(!opptyOLISet.contains(oli.Id)  && oli.Average_Renewal_Commit_MRR__c == null && oli.Average_Renewal_Usage_MRR__c == null)
                                    isNotAutoRenewalOppty = true;
                            }
                        if(!isNotAutoRenewalOppty)
                            {
                                oppToUpdate.Opportunity_Type__c = 'Auto-Renewal';
                                oppToUpdate.Validation_Override__c = true;
                                //opptyListToUpdate.add(oppty);
                                opptyMap.put(oppty.Id,oppToUpdate);
                            }

                    }

            }
            DMLResults updateResults = new DMLResults();
            if(opptyListToUpdate.size() > 0)
                {
                    //updateResults.add(Database.update(opptyListToUpdate,false),opptyListToUpdate);
                    //updateResults.withClassName('OpportunityTriggerClass-Auto-Renewwal').insertRecordsInErrorLog();
                }
                
            switchToAutoRenewalTypeOLIFirstRunFlag = false;
            return opptyMap;
        }
//Begin , Rajesh - SFDC-7061  -|- ZOFF Related changes

//Method to verify access check for non ZOFF approver based on verifying from ARR and CM approvers
public static void checkzoffvalidApproval(List<Opportunity> oppList, Set<Id> ownerIds, Map<Id, Opportunity> opptyoldMap) {

    // @consideration : Metadata will always have the value to avoid null pointer exception
    if (zoffFirstrun ) { // using single flag for before and after context
        Map<String, Account_Reassignment_Rule__c > arrMap = !ownerIds.isEmpty() ? ZoffUtilClass.getzoffapproverfromArr(ownerIds) : new Map<String, Account_Reassignment_Rule__c > ();
        String defaultUser = zoffMdtvalue.Default_Approver__c;
        List<String> bussysOpsprofileList = zoffMdtvalue.Special_Approval_Field_Change_Profiles__c.split(',');

        for (Opportunity opp: oppList) {
			opportunity old = opptyoldMap.get(opp.id);
			if (defaultUser.equals(loggedinUserId) || (bussysOpsprofileList.contains(loggedinProfileId)) || (!Util.hasChanges(new Set<String> {'ZOFF_Decision_Reason__c'}, old, opp) && Util.hasChanges('ZOFF_Approval__c', old, opp) && 'Resubmitted'.equalsignoreCase(opp.zoff_approval__c))) {
                return;
			} else if ( ('Direct'.equalsIgnoreCase(opp.deal_type__c) || 'Indirect'.equalsIgnoreCase(opp.deal_type__c)) && arrMap.containsKey(opp.Account_OwnerId__c + opp.Zoff_Sub_Territory__c)) { // if direct deal type check approver from Account Reassignment Rule
				if (!(loggedinUserId == arrMap.get(opp.Account_OwnerId__c + opp.Zoff_Sub_Territory__c).Zoff_Delegated_Approver__c || loggedinUserId == arrMap.get(opp.Account_OwnerId__c + opp.Zoff_Sub_Territory__c).Zoff_Approver__c)) {
					opp.addError('Insufficient access on zoff approvals related fields.');
				}
            } else {
				opp.addError('Insufficient access on zoff approvals/rejection field.');
			}
		}
	}
}
// Method to stamp zoff approver when request is submitted !
public static void updateApprovername(List<Opportunity> oppList, Set<Id> ownerIds ) {
    if (zoffFirstrun && zoffMdtvalue.Feature_Enabled__c) {
		Map<id,String> gs = constructzoffopptyIdarrMap(oppList, ownerIds); // construct approval mapping and email list
		for (Opportunity op: oppList) {
			if (gs.containsKey(op.id)) {
				op.ZOFF_Approver_List__c = gs.get(op.id);
			}
		}
	}
}

//Method to construct zoffMapping for id to email and id to name
public static Map<id,String> constructzoffopptyIdarrMap(List < Opportunity > oppList, Set < Id > ownerIds) {
    List < String > status = 'Approved,Rejected'.split(',');
    Map < String, Account_Reassignment_Rule__c > arrMap = !ownerIds.isEmpty() ? ZoffUtilClass.getzoffapproverfromArr(ownerIds) : new Map < String, Account_Reassignment_Rule__c > (); //this method is called twice because filter criteria is different can't be avoided
    Map < Id, Channel_Mapping__c > rcmMap = ZoffUtilClass.findRCMmapping(oppList);//Rajesh Kumar SFDC-7473 Similar to ARR find RCM , Note : Here filtering channel Manager once because of sequencing issue in handler
    Map < Id, List < String >> mailinglistOppty = new Map < Id, List < String >> ();
    Map < Id, String > idtoNamemap = new Map < Id, String > ();
    user defaultUseremail = [select email, name from user where id =: zoffMdtvalue.Default_Approver__c limit 1]; // Describe VS SOQL ? Describe will consume some time to fetch data , opportunity create is by default slow
    for (Opportunity op: oppList) {
        ZoffUtilClass.emailListwrapper em = new ZoffUtilClass.emailListwrapper(); //Email List wrapper to store the date which require mail sending 
        em.zoffStatus = op.ZOFF_Approval__c;
        String diremaiList = '';
        String dirapprName = '';
        if (arrMap.containsKey(op.Account_OwnerId__c + op.Zoff_Sub_Territory__c)) {
            if (String.isnotBlank(arrMap.get(op.Account_OwnerId__c + op.Zoff_Sub_Territory__c).Zoff_Approver_Email__c)) {
                diremaiList = arrMap.get(op.Account_OwnerId__c + op.Zoff_Sub_Territory__c).Zoff_Approver_Email__c; //diremaiList && dirapprName having some logic to populate value so if one have value other will have
                dirapprName = arrMap.get(op.Account_OwnerId__c + op.Zoff_Sub_Territory__c).ZOFF_Approvers_Name__c;
            }
        }
        System.debug('op.deal_type__c###' + op.deal_type__c + 'diremaiList=' + diremaiList);
        if (('Direct'.equalsIgnorecase(op.deal_type__c) || 'Indirect'.equalsIgnorecase(op.deal_type__c)) && String.isNotBlank(diremaiList)) {
           if (op.ZOFF_Approval__c == 'Submitted' || op.ZOFF_Approval__c == 'Resubmitted') {
                em.toList = diremaiList.split(':');
                idtoNamemap.put(op.Id, dirapprName);
                //Rajesh Kumar SFDC-7473	:: Added RCM in CC for indirect Oppoty
                em.ccList.addAll(('Indirect'.equalsIgnorecase(op.deal_type__c) && rcmMap.containsKey(op.channel_manager__c) && String.isNotBlank(rcmMap.get(op.channel_manager__c).ZOFF_Approvers_Email__c )  ? rcmMap.get(op.channel_manager__c).ZOFF_Approvers_Email__c .split(':') : new List<String>() ));
            }
            if (ZoffUtilClass.listcontainsIgnorcase(status, op.ZOFF_Approval__c)) {
                em.toList = String.isNotblank(op.ZOFF_Owner_Email__c) ? op.ZOFF_Owner_Email__c.split(',') : new List < String > ();
                em.ccList = diremaiList.split(':');
                //Rajesh Kumar SFDC-7473	:: Added RCM in CC for indirect Oppoty
                em.ccList.addAll(('Indirect'.equalsIgnorecase(op.deal_type__c) && rcmMap.containsKey(op.channel_manager__c) && String.isNotBlank(rcmMap.get(op.channel_manager__c).ZOFF_Approvers_Email__c )  ? rcmMap.get(op.channel_manager__c).ZOFF_Approvers_Email__c .split(':') : new List<String>() ));                
            }
        } else { //if something wrong always add default user for approval
            em.toList = (op.ZOFF_Approval__c == 'Submitted') ? defaultUseremail.email.split(',') : new List < String > ();
            idtoNamemap.put(op.id, defaultUseremail.Name);
        }
        if (!em.toList.isEmpty()) {
            prepareEmailist.put(op.id, em);
        }
        
    }
    System.debug('prepareEmailist==' + prepareEmailist);
    return idtoNamemap;
}
//Method to Send ZOFF Appr/Reject/Re-Submit Email 
public static void sendApproveRejectEmail(List < Opportunity > oppList, Set < Id > ownerIds) {
    if (zoffFirstrun) {
        System.debug('inside job first run ::' + zoffFirstrun);
        constructzoffopptyIdarrMap(oppList, ownerIds);
    }
}

public static void sendZoffemail() {
    if (zoffFirstrun && !prepareEmailist.keySet().isEmpty()) {
        try {
            ZoffUtilClass.sendZoffEmail(prepareEmailist);
        } catch (exception ex) {
            sawyer.saw(ex); //Catch Error Log into Sawyer
        }

    }
    zoffFirstrun = false;
}
// End , Rajesh - SFDC-7061

public static void sendZoffEmailForMediaVertical(list<opportunity> opptyList, set<Id> ownerIds){
    if(!zoffEmailForMediaVerticalFirstRun){
        return;
    }
    List<Messaging.SingleEmailMessage > mailList = new List<Messaging.SingleEmailMessage >();
    Map < String, Account_Reassignment_Rule__c > arrMap = !ownerIds.isEmpty() ? ZoffUtilClass.getzoffapproverfromArr(ownerIds) : new Map < String, Account_Reassignment_Rule__c > ();
    Map < Id, Channel_Mapping__c > rcmMap = ZoffUtilClass.findRCMmapping(opptyList);
    EmailTemplate em = [select Id, DeveloperName, Subject, HtmlValue, Body from EmailTemplate where DeveloperName = 'Zoff_Template_For_Media'][0];
    String key;
    for(Opportunity oppty : opptyList){
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        if(arrMap.containsKey(oppty.Account_OwnerId__c + oppty.Zoff_Sub_Territory__c) && String.isNotBlank(arrMap.get(oppty.Account_OwnerId__c + oppty.Zoff_Sub_Territory__c).Associated_User_RSM__c)){
            mail.setTargetObjectId(zoffMdtvalue.Default_ContactId__c);
            mail.setTreatTargetObjectAsRecipient(false);
            mail.setTemplateId(em.Id);
            mail.setWhatId(oppty.id);
            mail.setToAddresses(new List<Id>{arrMap.get(oppty.Account_OwnerId__c + oppty.Zoff_Sub_Territory__c).Associated_User_RSM__c});
            mail.setSaveAsActivity(false);
            if('Indirect'.equalsIgnoreCase(oppty.Deal_Type__c) && rcmMap.containsKey(oppty.channel_manager__c) && String.isNotBlank(rcmMap.get(oppty.channel_manager__c).Comp_Owner1__c)){
                mail.setCcAddresses(new List<Id>{rcmMap.get(oppty.channel_manager__c).Comp_Owner1__c});
            }
            mailList.add(mail);
        }
    }
    if(mailList.size() > 0){
        Messaging.sendEmail(mailList);
    }
    zoffEmailForMediaVerticalFirstRun = false;
}

//SFDC-7474
Public static void updateOpptyCurrency(list<id> accountids,list<opportunity> opptytobeUpdate){
        
        Map<Id,Account> acclistcurrency =new Map<Id,Account>([select id,CurrencyIsoCode from Account where Id in: accountids]);
        for(opportunity opp : opptytobeUpdate){
            if(opp.currencyisocode != acclistcurrency.get(opp.AccountId).currencyisocode)
                opp.currencyisocode = acclistcurrency.get(opp.AccountId).currencyisocode;

            }
        
 }
//SFDC-7596
public static void UpdateLossCategory(list<opportunity> opptyList){
    if(!UpdateLossCategoryFlag){
        return;
    }
    UpdateLossCategoryFlag = false;
    Map<String, String> LossReasonToCategory = GSMSettings.getLargeMap('LossReasonToCategoryMapping');
    for(opportunity opp : opptyList){
        if(opp.Opportunity_Category__c == 'ALL' && LossReasonToCategory.containsKey(opp.Loss_Reason__c))
        {
            opp.Opportunity_Category__c = LossReasonToCategory.get(opp.Loss_Reason__c);
        }
        if(opp.Enterprise_Loss_Category__c == 'ALL' && LossReasonToCategory.containsKey(opp.Enterprise_Loss_Reason__c))
        {
            opp.Enterprise_Loss_Category__c = LossReasonToCategory.get(opp.Enterprise_Loss_Reason__c);
        }
        if(opp.Identity_Loss_Category__c == 'ALL' && LossReasonToCategory.containsKey(opp.Identity_Loss_Reason__c))
        {
            opp.Identity_Loss_Category__c = LossReasonToCategory.get(opp.Identity_Loss_Reason__c);
        }
    }
}
//SFDC-7598
public static void sentEmailToSpecialist(Map<Id, Opportunity> idToOpptyMap){
    if(!sendEmailToSpecialistFirstFlag){
        return;
    }
    String enterpriseAkamProductId = GSMSettings.getValue('Enterprise_Product_Akam_Id');
    String securityAkamProductId = GSMSettings.getValue('Security_Product_Akam_Id');
    sendEmailToSpecialistFirstFlag = false;
    System.debug('Inside sentEmailToSpecialist method');
    List<OpportunityLineItem> lineItem = new List<OpportunityLineItem>();
    Map<Id,String> opptyIdtoEnterpriseSecurityProductName = new Map<Id,String>();
    Map<Id,String> opptyIdToCiamProductName = new Map<Id,String>();
    lineItem = [select id, Product2.Name, Product2.family, Product2.AKAM_Product_ID__c, Product_MRR_Type__c, OpportunityId, Opportunity.stageName, Opportunity.Soha_Specialist__c, Opportunity.CIAM_Specialist__c from OpportunityLineItem  where Product2.family IN ('Enterprise','Security') and OpportunityId in :idToOpptyMap.keyset()];
    Map<Id, Set<Id>> oppIdToSpecialistUserIdSet = new Map<Id, Set<Id>>();
    Set<Id> spclistCompTeamId = new Set<Id>();
    for(OpportunityLineItem oli : lineItem){
        if(oli.Opportunity.Soha_Specialist__c != null && enterpriseAkamProductId.contains(oli.Product2.AKAM_Product_ID__c)){
            if('Closed Lost'.equalsIgnoreCase(oli.Opportunity.stageName) || 'Closed Contract Ended'.equalsIgnoreCase(oli.Opportunity.stageName) || ('Closed Won'.equalsIgnoreCase(oli.Opportunity.stageName) && 'LMRR'.equalsIgnoreCase(oli.Product_MRR_Type__c))){
                if(oppIdToSpecialistUserIdSet.containsKey(oli.OpportunityId)){
                    Set<id> compList = oppIdToSpecialistUserIdSet.get(oli.OpportunityId);
                    compList.add(oli.Opportunity.Soha_Specialist__c);
                    oppIdToSpecialistUserIdSet.put(oli.OpportunityId, compList);
                }
                else{
                    oppIdToSpecialistUserIdSet.put(oli.OpportunityId, new Set<Id>{oli.Opportunity.Soha_Specialist__c});
                }
                spclistCompTeamId.add(oli.Opportunity.Soha_Specialist__c);
                if(opptyIdtoEnterpriseSecurityProductName.containsKey(oli.OpportunityId)){
                    String prodNames = opptyIdtoEnterpriseSecurityProductName.get(oli.OpportunityId);
                    prodNames = prodNames + ', '+oli.Product2.Name;
                    opptyIdtoEnterpriseSecurityProductName.put(oli.OpportunityId, prodNames);
                }else{
                    opptyIdtoEnterpriseSecurityProductName.put(oli.OpportunityId, oli.Product2.Name);
                }
            }
        }
        else if(oli.Opportunity.CIAM_Specialist__c != null && securityAkamProductId.contains(oli.Product2.AKAM_Product_ID__c)){
            if('Closed Lost'.equalsIgnoreCase(oli.Opportunity.stageName) || 'Closed Contract Ended'.equalsIgnoreCase(oli.Opportunity.stageName) || ('Closed Won'.equalsIgnoreCase(oli.Opportunity.stageName) && 'LMRR'.equalsIgnoreCase(oli.Product_MRR_Type__c))){
                if(oppIdToSpecialistUserIdSet.containsKey(oli.OpportunityId)){
                    Set<id> compList = oppIdToSpecialistUserIdSet.get(oli.OpportunityId);
                    compList.add(oli.Opportunity.CIAM_Specialist__c);
                    oppIdToSpecialistUserIdSet.put(oli.OpportunityId, compList);
                }
                else{
                    oppIdToSpecialistUserIdSet.put(oli.OpportunityId, new Set<Id>{oli.Opportunity.CIAM_Specialist__c});
                }
                spclistCompTeamId.add(oli.Opportunity.CIAM_Specialist__c);
                if(opptyIdToCiamProductName.containsKey(oli.OpportunityId)){
                    String prodNames = opptyIdToCiamProductName.get(oli.OpportunityId);
                    prodNames = prodNames + ', '+oli.Product2.Name;
                    opptyIdToCiamProductName.put(oli.OpportunityId, prodNames);
                }else{
                    opptyIdToCiamProductName.put(oli.OpportunityId, oli.Product2.Name);
                }
            }
        }
    }
    Map<id, Specialist_Comp_Team__c> compIdtoProdSpecialist = new Map<id, Specialist_Comp_Team__c>();
    List<Specialist_Comp_Team__c> specialCompTeam = [Select id, Product_Specialist__r.Email, Product_Specialist__c, Product_Specialist__r.name, Type__c  from Specialist_Comp_Team__c where id in :spclistCompTeamId];
    for(Specialist_Comp_Team__c scp : specialCompTeam){
        compIdtoProdSpecialist.put(scp.id, scp);
    }
    System.Debug('compIdtoProdSpecialist:'+compIdtoProdSpecialist);
    List<Messaging.SingleEmailMessage> mailList = new List<Messaging.SingleEmailMessage>();
    EmailTemplate specialListTemplate = [select Id, DeveloperName, Subject, HtmlValue, Body from EmailTemplate where DeveloperName = 'Email_to_Opportunity_Specialist'][0];
    for(Id opptyId : oppIdToSpecialistUserIdSet.keyset()){
        for(Id scpId : oppIdToSpecialistUserIdSet.get(opptyId)){
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.setToAddresses(new list<Id>{compIdtoProdSpecialist.get(scpId).Product_Specialist__c});
            String body, sub;
            if(idToOpptyMap.get(opptyId).StageName == 'Closed Won'){
                body = (specialListTemplate.HtmlValue).replace('#OpptyStage', idToOpptyMap.get(opptyId).StageName+' w/ LMRR');
            }
            else{
                body = (specialListTemplate.HtmlValue).replace('#OpptyStage', idToOpptyMap.get(opptyId).StageName);
            }
            sub = (specialListTemplate.Subject).replace('#AccountName', idToOpptyMap.get(opptyId).Associated_Account_Name__c);
            body = body.replace('#OpptyName', idToOpptyMap.get(opptyId).Name);
            body = body.replace('#SpecialistName', compIdtoProdSpecialist.get(scpId).Product_Specialist__r.name);
            if(compIdtoProdSpecialist.get(scpId).Type__c == 'Enterprise Sales Specialist'){
                body = body.replace('#ProductName', opptyIdtoEnterpriseSecurityProductName.get(opptyId));
                body = body.replace('#SpecialistSection', 'Enterprise Specialist Information section');
            }
            else{
                body = body.replace('#ProductName', opptyIdToCiamProductName.get(opptyId));
                body = body.replace('#SpecialistSection', 'Identity Specialist Information section');
            }
            String url = URL.getSalesforceBaseUrl().toExternalForm();
            body = body.replace('#opptyLink', '<a href="'+url+'/'+opptyId+'">'+idToOpptyMap.get(opptyId).AKAM_Opportunity_ID__c+'<a/>');
            message.setSubject(sub);
            message.setHtmlBody(body);
            message.setWhatId(opptyId);
            message.setSaveAsActivity(false);
            mailList.add(message);
        }
    }
    if(mailList.size() > 0){
        System.Debug('mailSent Successfully'+mailList);
        Messaging.sendEmail(mailList);
    }
}

//SFDC-7772 //SFDC-9589
/*
public static void syncSpecialistField(Map<Id, opportunity> opptyList, Set<Id> specialistCompTeamId){

    if(!syncSpecialistFieldFlag){
        return;
    }
    syncSpecialistFieldFlag = false;
    System.debug('specialistCompTeamId:'+specialistCompTeamId);
    Map<Id, Id> specialistCompIdToProductSpecialist = new Map<Id, Id>();
    for(Specialist_Comp_Team__c sct : [select id, Product_Specialist__c from Specialist_Comp_Team__c where Id IN :specialistCompTeamId]){
        specialistCompIdToProductSpecialist.put(sct.id, sct.Product_Specialist__c);
    }
    System.debug('specialistCompIdToProductSpecialist:'+specialistCompIdToProductSpecialist);
    for(Id opptyId : opptyList.keyset()){
        if(opptyList.get(opptyId).Opportunity_Leader__c == specialistCompIdToProductSpecialist.get(opptyList.get(opptyId).Soha_Specialist__c)){
            System.debug('Inside Enterprise');
            opptyList.get(opptyId).Enterprise_Loss_Category__c = opptyList.get(opptyId).Opportunity_Category__c;
            opptyList.get(opptyId).Enterprise_Loss_Reason__c = opptyList.get(opptyId).Loss_Reason__c;
            opptyList.get(opptyId).Enterprise_Loss_Detail__c = opptyList.get(opptyId).Loss_Cancellation_Description__c;
            if(String.isNotBlank(opptyList.get(opptyId).Competitor__c) && ((opptyList.get(opptyId).Other_Competitor_Name__c != NULL && (opptyList.get(opptyId).Competitor__c).contains('Other -')) || !(opptyList.get(opptyId).Competitor__c).contains('Other -'))){
                opptyList.get(opptyId).Enterprise_Competitor_Primary__c = opptyList.get(opptyId).Competitor__c;
                opptyList.get(opptyId).Enterprise_Other_Competitor__c = opptyList.get(opptyId).Other_Competitor_Name__c;
            } 
        }
        if(opptyList.get(opptyId).Opportunity_Leader__c == specialistCompIdToProductSpecialist.get(opptyList.get(opptyId).CIAM_Specialist__c)){
            System.debug('Inside CIAM');
            opptyList.get(opptyId).Identity_Loss_Category__c = opptyList.get(opptyId).Opportunity_Category__c;
            opptyList.get(opptyId).Identity_Loss_Reason__c = opptyList.get(opptyId).Loss_Reason__c;
            opptyList.get(opptyId).Identity_Loss_Detail__c = opptyList.get(opptyId).Loss_Cancellation_Description__c;
            if(String.isNotBlank(opptyList.get(opptyId).Competitor__c) && ((opptyList.get(opptyId).Other_Competitor_Name__c != NULL && (opptyList.get(opptyId).Competitor__c).contains('Other -')) || !(opptyList.get(opptyId).Competitor__c).contains('Other -'))){
                opptyList.get(opptyId).Identity_Competitor_Primary__c = opptyList.get(opptyId).Competitor__c;
                opptyList.get(opptyId).Identity_Other_Competitor__c = opptyList.get(opptyId).Other_Competitor_Name__c;
            }
        }
    }
}*/

public static void autoClosureRenewalOpportunity(List<Opportunity> opptyList){

    List<Opportunity> updateOpptyList = new List<Opportunity>();
    for(Opportunity opp : opptyList){
        opportunity oppty = new opportunity(Id = opp.id);
        oppty.stageName = 'Closed Won';
        oppty.Contract_Accepted_Date__c = DateTime.newInstanceGmt(opp.closeDate.year(), opp.closeDate.month(), 1, 13, 0, 0);
        oppty.Contract_ID__c = opp.Renew_Contract_Id_Text__c;
        oppty.Momentum_Automated__c = 'Non-automatable';
        oppty.Automation_Reason__c = 'Auto Renewal';
        oppty.Credit_Rebill__c = 'No';
        oppty.Transaction_Type__c = 'Auto Renewal';
        oppty.Contract_Entered_by__c = 'Auto Renewal';
        oppty.Contract_Entry_Type__c = 'Auto Renewal';
        oppty.Contract_Reviewed_by__c = 'Auto Renewal';
        oppty.No_of_Contracts__c = '1';
        updateOpptyList.add(oppty);
    }

    if(updateOpptyList.size() > 0){
        GsmUtilClass.doDatabaseUpdate(updateOpptyList,'OpportunityTriggerClass','autoClosureRenewalOpportunity');
    }
}

public static void checkChimeContactForAccess(List<Opportunity> opptyList){    
    List<Id> chimeIdList = new List<Id>();
    for(CHIME__c chime : [Select id from CHIME__c where Opportunity__c IN :opptyList]){
        chimeIdList.add(chime.id);
    }

    if(chimeIdList.size() > 0){
        ChimeTriggerClass.checkChimeContactAccess(chimeIdList, 'Opportunity');
    }
}

// SFDC-9455 Rajul Vishwakarma
public static void closeAllChimeFormRelatedToClosedOpportunity(Set<Id> closedOppoIds){
    List<CHIME__c> closedChimeFormList = [Select Id,Stage__c from CHIME__c where Opportunity__c in :closedOppoIds AND Stage__c != 'Closed' AND Is_POC_Demo__c = TRUE];
    for(CHIME__c c:closedChimeFormList){
        c.Stage__c = 'Closed';
    }
    if(closedChimeFormList.size() > 0){
        update closedChimeFormList;
    }
}
//End

}