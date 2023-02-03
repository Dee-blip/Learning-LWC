/***
    PRM_opportunity
    @version 1.0
    @author Vinayendra T N <vinatara@akamai.com>
    @Description : This Class is used for management of PRM.
    @History
  --Developer         --Date      --Change
  Vinayendra T N     3/2011       Created the class for management of PRM
  Vinayendra T N     5/2011       CR 1077168 PRM - Add associated contact field to deal registration page
                      - Changed logic so that Partner Owner user becomes the owner when the oppty is submitted
                      - Changed logic so that partner owner user is added to sales team when the oppty is submitted
                      CR 1107453 PRM: Sync partner contact record and partner user record
                      - Copy email in user level to contact level
                      - Copy Active flag value in user level to Active Partner in contact                   
  Vinayendra T N     6/2011       CR 1153054 PRM: Display error message if a deal registration is approved BEFORE the user associates an account
                      - onDealApproval() function is called when the deal is approved which throws a error if account is not added
  Vinayendra T N     2/2012       CR 1502425 PRM Need to allow Partner Support the capability to add sharing rules to Fund Budget
                      - UpdateFundBudgetSharesFutureCall() : A future method to create sharing rules for budget when a user is activated for the first time
                      
  Chandra Lohani      04/05/2012          CR 1633387- Add Last Login date to the report PAE Netalliance report
                                          Modified 'UpdateUserRoleProfile' method to update Partner_User__c field
    Vinayendra T N      4/07/2012     CR 1778789 PRM: Fix Account.Current Licenses count when Partners are activated/deactivated in bulk
                        Made changes in updateUserRoleProfile() to make the correct number is subtracted/added when users are added/removed
                        CR 1754059 Can we disable NAP access on Account level too?
                        added a method DisablePartnerAccount() which is called from a button click. This deactivates IsPartnerCustom Flag.
                        Also added changed LimitPartnerUserCreation() to add a validaiton when user is created after account is deactivated as partner account.
    Lisha Murthy    20/10/2012      CR 1900756 - PRM: remove Has MDF checkbox for all contacts if partner doesnt have MDF
                        - Added method convertAndCheckFR()
                        - This check the roll-up summary field called "Available Amount" and if requested amount is greater than that, then show error message.     
    //CR 2565228  - Anand Hegde - Add 30 days time to FR activity end date and get only those budgets which have FC deadline greater than that
                               - None of the fund budgets associated to the fund request should have expired. Fund_Claim_Deadline__c field decides if its expired or not.
*/
global class PRM_opportunity {
  public static map<id,User> FirstPartnerUser = new map<id,User>();
    public static map<id,User> FirstPartnerUserForAccount = new map<id,User>();
   // private static MDF_Configurations__c mdfConfigurations = GsmUtilClass.getConfigurations();
  public static map<String,Double> IsoMap = new map<String,Double>();
  private static Boolean CreateAllocationFirstRunFlag = true;
  private static Boolean CheckAllocationFirstRunFlag = true;
  private static Boolean FundClaimTriggerFirstRunFlag = true;
  public static Boolean AddErrorToAccountFristRunFlag = true;
  public static Boolean updateCampaignOnFundRequestFirstRunFlag = true;
  //private static Boolean onDealApprovalFristRunFlag = true;
  private static Boolean UpdateRoleOfPartnerFirstRunFlag = true;
  private static Boolean SendEmailToAdminFirstRunFlag = true;
  public static Boolean UpdateFundBudgetSharesFirstRunFlag = true;
  public static Boolean ValidateFundBudgetCurrencyFirstRunFlag = true;
  public static Boolean ValidateFundRequestCurrencyFirstRunFlag = true;
  public static Boolean ValidateFundClaimCurrencyFirstRunFlag = true; 
  public static Boolean FundClaimCreateTaskFirstRunFlag = true;
    public static Boolean updateUserRoleProfileFutureInvokeFirstRunFlag = true;
    public static Boolean updateUserUsernameOrEmailFutureInvokeFirstRunFlag = true;
    public static Boolean convertAndUpdateFRFirstRunFlag = true;
    public static Boolean updateUserFutureFlag =false;
    //SFDC-3089
    public static Boolean populateFieldsFromPMAFirstRunFlag = true;
  public static list<Channel_Mapping__c> channelMapping = new list<Channel_Mapping__c>();
  
  
  // The curreny is fetched and put in a map so that it can used later if needed.
  public static void initilizeCurrencyRate()
    {   
        for (CurrencyType ct :[Select IsoCode, ConversionRate From CurrencyType where IsActive=true])
            IsoMap.put(ct.IsoCode,ct.ConversionRate);
    }
    //This function is used to add user to sales team.
    public static OpportunityTeamMember opptyAddSalesTeamMember(Id p_oppty_id, Id p_user_Id, String p_role )
    {
      OpportunityTeamMember otm = new OpportunityTeamMember();  //Create a new team member      
      otm.OpportunityId = p_oppty_id; //Assign the Oppty to which the member belongs to.
      otm.UserId = p_user_Id;    //Make User with p_userId, the team member.
      otm.TeamMemberRole = p_role;//Update the team role as defined in DefaulOpportunityTeamMember
      //otm.OpportunityAccessLevel = 'All';
      //otm.OpportunityAccessLevel = p_perm;
      return otm;        
    }
    // A Webservice call for approval process
     WebService static String submitForApproval(Id p_OppId)
     {
         // create the new approval request to submit
         Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
         req.setComments('Submitted for approval. Please approve.');
         req.setObjectId(p_OppId);
         String customSettingsExceptionCheck = GsmUtilClass.getPRMSettingValue('DealRegSubmit_ProfileException');
         String userProfileId = userinfo.getProfileId();
         // submit the approval request for processing
         Boolean isOppty=String.valueOf(p_OppId).startsWith('006');
         Opportunity oppty;
         if(isOppty)
         {
             oppty = [Select CloseDate from Opportunity where Id=:p_OppId][0];
         }

         if(!isOppty || customSettingsExceptionCheck.contains(userProfileId) || ( isOppty && oppty.CloseDate!=null && oppty.CloseDate>=Date.today()))
         {
             String statusMessage = '';
             Boolean hasError=false;
             try
             {
                 Approval.ProcessResult result = Approval.process(req);
             }
             catch(System.DmlException e)
             {
                 hasError=true;
                 for (Integer i = 0; i < e.getNumDml(); i++)
                 {
                     if(e.getDmlType(i) == Statuscode.FIELD_CUSTOM_VALIDATION_EXCEPTION ||e.getDmlType(i) == Statuscode.FIELD_INTEGRITY_EXCEPTION)
                     {
                         statusMessage += e.getDmlMessage(i);
                     }
                     else
                     {
                        String errMessage = e.getMessage();
                        if(errMessage.contains('MANAGER_NOT_DEFINED'))
                          statusMessage += 'Fund Request Approver on the Channel Mapping is an invalid user.';
                        else
                          statusMessage += errMessage;
                     }
                 }
             }
             catch(Exception e)
             {
                 hasError=true;
                 String errMessage = e.getMessage();
                 if(errMessage.contains('MANAGER_NOT_DEFINED'))
                     statusMessage += 'Fund Request Approver on the Channel Mapping is an invalid user.';
                 else
                     statusMessage += errMessage;
             }

             if(hasError)
                 return statusMessage;
             else
                return 'Succesfully Submitted for Approval';
         }
         else
         {
             return 'A Deal Registration can not be submitted after the close date.';
         }
     }
    //HC Moved this logic to OpportunityPRMTriggerClass
    // Add Fcm and set Channel manager on record Creation for Opporunirty (Only for partners)
    /*
    public static void addFCMdealcreation ( Opportunity[] opptys )   
    {       
        //initilizeChannelMappingdata();    
        User partnerUser = [select contactId,contact.AccountId from User where id =:Userinfo.getUserId()];                      
    //Contact partnerContactId = [select AccountId from Contact where Id=:partnerUser.ContactId ];    
        list<id> AccId = new list<id>();
        AccId.add(partnerUser.contact.AccountId); 
        Map<Id, Channel_Mapping__c> cm_accid_map;
        if(AccId.size()>0)
        cm_accid_map = OpportunityTriggerClass.GetChannelMapping(AccId);
      List<Channel_Mapping__c> fcmIds= OpportunityTriggerClass.getCMRecordsForAccount(partnerUser.contact.AccountId);
      for (Opportunity opp: opptys)
        {
          if(fcmIds.size()==1)
          {
            opp.FCM__c=fcmIds[0].PAE_ID__c;
            opp.Channel_Manager__c=fcmIds[0].id;
          }
        }
           
    }*/
    // Add Fcm on record Creation for Fund Claims
    public static void addFCMdealcreation ( SFDC_MDF_Claim__c[] FundClaims )   
    {       
      list<id> FundRequestIds = new list<id>();
        for (SFDC_MDF_Claim__c fc: FundClaims)
        {
            FundRequestIds.add(fc.Fund_Request__c);
        }   
        
        list<SFDC_MDF__c> FundReqs = [select id,FCM__c from SFDC_MDF__c where id IN :FundRequestIds];
        Map<id,id> FundReqID_FCM_map = new Map<id,id>();
        for(SFDC_MDF__c Fr:FundReqs)
        {
          FundReqID_FCM_map.put(Fr.id,Fr.FCM__c);
        }
        map<id,string> FCMApproverMAP = new map<id,string>();
        for(Channel_Mapping__c cm:[select PAE_ID__c,FC_Approver__c from Channel_Mapping__c where PAE_ID__c IN :FundReqID_FCM_map.Values()])
        {
          //if(cm.FC_Approver__c!=null || cm.FC_Approver__c!='')
          if(cm!=null) // SDFC 7619
          {
            FCMApproverMAP.put(cm.PAE_ID__c,cm.FC_Approver__c);
          }
        }
        for (SFDC_MDF_Claim__c fc: FundClaims)
        {
          if(FundReqID_FCM_map.get(fc.Fund_Request__c)!=null)
          {
            fc.FCM__c=FundReqID_FCM_map.get(fc.Fund_Request__c);
            if(FCMApproverMAP.get(FundReqID_FCM_map.get(fc.Fund_Request__c))!=null)
              fc.Fund_Claim_Approver__c=FCMApproverMAP.get(FundReqID_FCM_map.get(fc.Fund_Request__c));
          }
        }
    }

    //HC Moving this logic to OpportunityPRMTriggerClass
    // Update the Owners of deal and add to case team (after trigger)
    /*
    public static void dealOwnershipUpdate ( Opportunity[] opptys )   
    {       
        User partnerUser = [select contactId,contact.AccountId from User where id =:Userinfo.getUserId()];                      
    //Contact partnerContactId = [select AccountId from Contact where Id=:partnerUser.ContactId ];    
        for (Opportunity opp: opptys)
        {
              //opp.Partner_Involved__c=partnerUser.contact.AccountId;
              if(opp.Partner_Owner__c==null)
              opp.Partner_Owner__c=partnerUser.ContactId;
              opp.Deal_Type__c='Indirect';
      }
    }
    */
    //HC Moving this logic to OpportunityPRMTriggerClass
    // On Deal approval check if Account is added
    /*
    public static void onDealApproval ( Opportunity[] opptys )   
    {   
         
      if(!onDealApprovalFristRunFlag)
      return;
        for (Opportunity opp: opptys)
        {
          if(!opp.Validation_Override__c && opp.AccountId==null)
              opp.AddError('Account is mandatory before Approval of the deal');
      }
      onDealApprovalFristRunFlag=false;
    }
    */
    //HC Moved the logic to OpportunityPRMTriggerClass 
    // Update Owner to Partner Owner
    // CR 1077168 PRM - Add associated contact field to deal registration page
    /*
    public static void OwnerUpdateOnSubmit( Opportunity[] opptys )   
    {    
      list<Id> ContactIdList = new list<Id>();
      Map<id,User> ContactIdUserMap = new Map<id,User>();
      for (Opportunity opp: opptys)
        {
          ContactIdList.add(opp.Partner_Owner__c);  
        }
        for(User usr:[select id,contact.AccountId,ContactId from User where ContactId In :ContactIdList])
        {
          ContactIdUserMap.put(usr.ContactId,usr);
        }                      
        for (Opportunity opp: opptys)
        {
          
              if(opp.Owner!=ContactIdUserMap.get(opp.Partner_Owner__c))
              opp.OwnerId=ContactIdUserMap.get(opp.Partner_Owner__c).id;
      }
    }
    */

    private static Id getAccountCMGAnalyst(Id accountId)
    {
        return getAccountToCMGAnalystMap(new Set<Id>{accountId}).get(accountId);
    }

    private static Map<Id, Id> getAccountToCMGAnalystMap(Set<Id> accountIds)
    {
        Map<Id, Id> accountIdToCMGAnalystId = new Map<Id, Id>();

        if(accountIds.size()>0)
        {
            for(AccountTeamMember atm : [select UserId, AccountId from AccountTeamMember where AccountId in :accountIds and TeamMemberRole='CMG - Analyst' order by CreatedDate ASC])
            {
                accountIdToCMGAnalystId.put(atm.AccountId, atm.UserId);
            }
        }

        return accountIdToCMGAnalystId;
    }


    // After Insert
    // converts amount and update Fund Request with claimed amount
    // Gets the fund claim amount. 
    // Checks if the currency type is same 
    // If yes just add it to claimed amount
    // If no converts and then adds the claimed amount
    // Updates the Claimed amount of the FR.
    public static void convertAndUpdateFR(SFDC_MDF_Claim__c[] FundClaims)
    {
      //if(!CreateAllocationFirstRunFlag)
      //return;
        if(!convertAndUpdateFRFirstRunFlag)
            return;
      initilizeCurrencyRate();
      list<Id> FundRequestid = new list<Id>();
        Set<Id> partnerAccountIdSet = new Set<Id>();
      for(SFDC_MDF_Claim__c fc:FundClaims)
      {
            partnerAccountIdSet.add(fc.Account__c);
      }

      list<SFDC_MDF__c> fundRequestList=new list<SFDC_MDF__c>();
        Map<Id, Id> accountIdToCMGAnalystId = getAccountToCMGAnalystMap(partnerAccountIdSet);
      
      TaskUtility tasks = new TaskUtility();
      String taskSubject = GsmUtilClass.getPRMSettingValue('FundClaimApproval_TaskSubject'); //Request For Fund Claim Entry
      
      for(SFDC_MDF_Claim__c fc:FundClaims)
      {
         FundRequestid.add(fc.Fund_Request__c);
         //  Sonali Tandon- CR 2762445 - MDF -- Create Task when FC is Approved - Internal and Approved-Credit
          //if('Partner'.equalsIgnoreCase(fc.Paid_By__c))
        if(fc.Status__c.equals(GsmUtilClass.getGSMSettingValue('FC_StatusValue_ApprovedInternal'))){
          tasks.queue(fc.id,GsmUtilClass.getGSMSettingValue('FC_For_Approved_Internal_User'),taskSubject);
        }
        else{
          tasks.queue(fc.id,accountIdToCMGAnalystId.get(fc.Account__c),taskSubject);
        }

      }
      Map<Id,String> FRidIsoMap= new Map<Id,String>();
      Map<Id,decimal> FRidClaimedMap= new Map<Id,decimal>();
        //Anand Hegde - check if this is the only open FC for this FR. If so, close the FR
        Map<Id, Decimal> frIdToApprovedAmount = new Map<Id, Decimal>();
      For(SFDC_MDF__c fundr:[select id,CurrencyIsoCode,Claimed_Amount__c, Funding_Approved__c, Status__c from SFDC_MDF__c where id IN :FundRequestid])
      {
        FRidIsoMap.put(fundr.id,fundr.CurrencyIsoCode);
        FRidClaimedMap.put(fundr.id,fundr.Claimed_Amount__c==null?0:fundr.Claimed_Amount__c);
            frIdToApprovedAmount.put(fundr.Id, fundr.Funding_Approved__c==null?0:fundr.Funding_Approved__c);
      }
      for(SFDC_MDF_Claim__c fc:FundClaims)
      { 
        Decimal amount;
        //Check if currency is same, if not convert
      if(fc.CurrencyIsoCode != FRidIsoMap.get(fc.Fund_Request__c))
      {
        amount=(fc.Amount__c * (IsoMap.get(FRidIsoMap.get(fc.Fund_Request__c))))/IsoMap.get(fc.CurrencyIsoCode);
      }
      else
        amount=fc.Amount__c;
      decimal newAmount=FRidClaimedMap.get(fc.Fund_Request__c)+amount;
      //update FR with new Fund Claim amount
      SFDC_MDF__c fr= new SFDC_MDF__c(id=fc.Fund_Request__c,Claimed_Amount__c=newAmount);
            //Anand Hegde - Close the fund request if it has no more remaining amount
            if(frIdToApprovedAmount.containsKey(fr.Id) && fr.Claimed_Amount__c==frIdToApprovedAmount.get(fr.Id) && fr.Claimed_Amount__c!=0)
            {
                fr.Status__c = 'Closed' ;
            }
      fundRequestList.add(fr);
      }
      update fundRequestList;
      
      // Akam modified double check 
      if(FundClaimCreateTaskFirstRunFlag == true) {
        // Insert Tasks
        tasks.insertQueue();
        FundClaimCreateTaskFirstRunFlag = false;
      }
        convertAndUpdateFRFirstRunFlag = false;
      
      //CreateAllocationFirstRunFlag=false;
    }
    // Before Insert
    // converts amount and update Fund Request with claimed amount
    // Gets the fund claim amount. 
    // Checks if the currency type is same 
    // If yes then check if Claimed amount is greater then requested fund claim amount
    // If no converts the FC amount to FR currency and then checks
    // Updates the Claimed amount of the FR.
    public static map<id,Boolean> convertAndCheckFC(SFDC_MDF_Claim__c[] FundClaims)
    {
      initilizeCurrencyRate();
      map<Id,Boolean> returnmap= new map<Id,Boolean>();
      list<Id> FundRequestid = new list<Id>();
      list<SFDC_MDF__c> fundRequestList=new list<SFDC_MDF__c>();
      for(SFDC_MDF_Claim__c fc:FundClaims)
      {
      FundRequestid.add(fc.Fund_Request__c);
      }
      Map<Id,String> FRidIsoMap= new Map<Id,String>();
      Map<Id,decimal> FRidClaimedMap= new Map<Id,decimal>();
      Map<Id,decimal> FRidFundAppMap= new Map<Id,decimal>();
        Map<Id, Date> fundRequestToFCDeadline = new Map<Id, Date>();
      For(SFDC_MDF__c fundr:[select id,CurrencyIsoCode,Claimed_Amount__c,Funding_Approved__c,Earliest_FC_Deadline__c from SFDC_MDF__c where id IN :FundRequestid])
      {
        FRidIsoMap.put(fundr.id,fundr.CurrencyIsoCode);
        FRidClaimedMap.put(fundr.id,fundr.Claimed_Amount__c==null?0:fundr.Claimed_Amount__c);
        FRidFundAppMap.put(fundr.id,fundr.Funding_Approved__c==null?0:fundr.Funding_Approved__c);
            fundRequestToFCDeadline.put(fundr.id, fundr.Earliest_FC_Deadline__c);
      }
      for(SFDC_MDF_Claim__c fc:FundClaims)
      { 
            if('Submitted'.equals(fc.Status__c) && fundRequestToFCDeadline.get(fc.Fund_Request__c)<fc.FC_First_Submitted__c)
            {
                fc.addError(NAPSettings.getValue('MDF_FCDeadlinePassedError'));
            }
        Boolean ErrorNotFound=True;
        Decimal amount;
        //throw new CustomException('here'+fc.CurrencyIsoCode+'-->'+FRidIsoMap.get(fc.Fund_Request__c));
      if(fc.CurrencyIsoCode != FRidIsoMap.get(fc.Fund_Request__c))
      {
        amount=(fc.Amount__c * (IsoMap.get(FRidIsoMap.get(fc.Fund_Request__c))))/IsoMap.get(fc.CurrencyIsoCode);
      }
      else
        amount=fc.Amount__c;
      decimal newAmount=(FRidClaimedMap.get(fc.Fund_Request__c)+amount).setScale(2);
      if(fc.CurrencyIsoCode != FRidIsoMap.get(fc.Fund_Request__c))
      {
        Decimal AvailableAmt=FRidFundAppMap.get(fc.Fund_Request__c)-FRidClaimedMap.get(fc.Fund_Request__c);
        //throw new CustomException('here'+newamount+'Fund amout '+FRidFundAppMap.get(fc.Fund_Request__c));
        if(newamount>FRidFundAppMap.get(fc.Fund_Request__c))
        {
          Decimal amt = (AvailableAmt*IsoMap.get(fc.CurrencyIsoCode))/(IsoMap.get(FRidIsoMap.get(fc.Fund_Request__c)));
          fc.AddError('Insufficient funds for this claim. Available funds: '+amt.setScale(2)+' '+fc.CurrencyIsoCode);
          ErrorNotFound=False;
        }
      }
      else
      {
        //throw new CustomException('here'+newamount);
        Decimal AvailableAmt=FRidFundAppMap.get(fc.Fund_Request__c)-FRidClaimedMap.get(fc.Fund_Request__c);
        if(newamount>FRidFundAppMap.get(fc.Fund_Request__c))
        {
          fc.AddError('Insufficient funds for this claim. Available funds: '+AvailableAmt.setScale(2)+' '+fc.CurrencyIsoCode);
          ErrorNotFound=False;
        }
      }
      returnmap.put(fc.id,ErrorNotFound);
      system.debug('I have come here'+ ErrorNotFound);
      }
      //CheckAllocationFirstRunFlag=false;
      return returnmap;
    }
    
    /*
    convertAndCheckFR()
    - Input: List of Fund requests being created
    - Retun value: Id of FR (if present/on update) with error Boolean
    - Functionality: Takes the AvailableAmount (Roll-up summary field on FB) and checks if the requested amount is greater than that (after currency conversion if needed).
            - If unavailable, add an error to the record. 
      Anand Hegde              CR 2565228  - PRM: Alter the FC Deadline logic for FBAs
    */
    public static map<id,Boolean> convertAndCheckFR(SFDC_MDF__c[] FundRequests)
    {
        initilizeCurrencyRate();
        map<Id,Boolean> returnmap= new map<Id,Boolean>();
        list<Id> accIdList = new list<Id>();
        Map<Id, decimal> FRIdToAvailableBudgetMap = new Map<Id, decimal>();
        Map<Id, List<Id>> AccIdToListOfFBIds = new Map<Id, List<Id>>();
        
        for(SFDC_MDF__c fr: FundRequests)
        {
            accIdList.add(fr.Account__c);
        }

        Map<Id,String> FBAccIdFBIdMap = new Map<Id,String>();
        Map<Id,decimal> FBIdToAvailableBudgetMap= new Map<Id,decimal>();
        Map<Id, Date> FBIdToFRDeadlineMap = new Map<Id, Date>();
        Map<Id, Date> FBIdToFRCreationDeadline = new Map<Id, Date>();
        
        System.Debug('check@@@' + accIdList);
        if(accIdList.size() > 0)
        {
            for(SFDC_Budget__c fb:[select Id, Active__c, CurrencyIsoCode, Account__c, Amount__c, Available_Budget__c, Approved_Requests__c, Fund_Claim_Deadline__c, Fund_Request_Deadline__c from SFDC_Budget__c where Account__c IN :accIdList AND Active__c = TRUE])
            {
                FBAccIdFBIdMap.put(fb.Account__c,fb.Id);
                FBIdToFRDeadlineMap.put(fb.Id, fb.Fund_Claim_Deadline__c);
                FBIdToFRCreationDeadline.put(fb.Id, fb.Fund_Request_Deadline__c);
                FBIdToAvailableBudgetMap.put(fb.Id, fb.Available_Budget__c);
                if (AccIdToListOfFBIds.containsKey(fb.Account__c))
                    AccIdToListOfFBIds.get(fb.Account__c).add(fb.Id);
                else
                    AccIdToListOfFBIds.put(fb.Account__c, new List<Id> {fb.Id});
            }
            for(SFDC_MDF__c fr:FundRequests)
            {
                if(AccIdToListOfFBIds.containsKey(fr.Account__c))
                {
                    for(Id fbId : AccIdToListOfFBIds.get(fr.Account__c))
                    {
                        if((!FRIdToAvailableBudgetMap.containsKey(fr.Id)) || FRIdToAvailableBudgetMap.get(fr.Id)==null)
                        {
                            FRIdToAvailableBudgetMap.put(fr.Id, 0);
                        }
                        //Anand Hegde - CR 2565228  While allocating funds for a Fund Request, only those Fund Budgets are used which have their Fund Claim Deadline > Fund Request.Activity End Date + 30
                        if(fr.Earliest_FC_Deadline__c <= FBIdToFRDeadlineMap.get(fbId) && fr.AKAM_Created_Date__c.date()<=FBIdToFRCreationDeadline.get(fbId))
                        {
                            if(FBIdToAvailableBudgetMap.containsKey(fbId))
                            {
                                FRIdToAvailableBudgetMap.put(fr.Id, FRIdToAvailableBudgetMap.get(fr.Id)+FBIdToAvailableBudgetMap.get(fbId));
                            }
                        }
                    }
                }
            }

            
            System.Debug('check@@@ FRIdToAvailableBudgetMap' + FRIdToAvailableBudgetMap);
            for(SFDC_MDF__c fr:FundRequests)
            {
              Boolean ErrorNotFound=True;
              Decimal amount;
              
              if(FBAccIdFBIdMap.get(fr.Account__c) != null)
              {                 
                  amount=fr.Amount__c;
                 
                  if(FRIdToAvailableBudgetMap.get(fr.Id) == 0)
                  {
                      fr.AddError(GsmUtilClass.getPRMSettingValue('PRM_oppty_0FBavailable'));
                      ErrorNotFound=False;
                  }
                  else if(fr.Amount__c > FRIdToAvailableBudgetMap.get(fr.Id))
                  {
                      fr.AddError('Insufficient funds for this request. Available funds: '+FRIdToAvailableBudgetMap.get(fr.Id).setScale(2)+' '+fr.CurrencyIsoCode);
                      ErrorNotFound=False;
                  }
              }
              else
              {
                fr.AddError(GsmUtilClass.getPRMSettingValue('PRM_oppty_FBUnavailableError'));
                  ErrorNotFound=False;
              }
              returnmap.put(fr.id,ErrorNotFound);
            system.debug('FR - here'+ ErrorNotFound);
            }
        }
        //CheckAllocationFirstRunFlag=false;
        return returnmap;
    }
    


    // For fund request 
    // Create Budget allocations for FR
    // Currency check is done and FR allocation is created as per FR`s currency
    public static Boolean createBudgetAllocation(SFDC_MDF__c FundRequest)
    {
      initilizeCurrencyRate();
      list<SFDC_Budget__c> budgets = new list<SFDC_Budget__c> ();
      list<Budget_Allocation__c> budgetsAllocAdd= new list<Budget_Allocation__c>();
      Decimal AvailableAmount=0;
      Id rtid = [select Id from RecordType where Name = 'Reserved' and SObjectType = 'Budget_Allocation__c' limit 1].Id;
      for (SFDC_Budget__c ba : [select Id, Name,CurrencyIsoCode, Account__r.Name, Active__c, Amount__c, Available_Budget__c, Claimed_Budget__c, End_Earned_Date__c, Fund_Budget_Name__c, Fund_Claim_Deadline__c, Fund_Request_Deadline__c, Reserved_Budget__c, Start_Earned_Date__c, Temp_Allocation__c, Unclaimed_Requests__c from SFDC_Budget__c where (Account__c = :FundRequest.Account__c or Account__c = null) and Available_Budget__c > 0 and Fund_Request_Deadline__c >=
                :FundRequest.CreatedDate.date() and Active__c=true  and Fund_Claim_Deadline__c >=:FundRequest.Earliest_FC_Deadline__c order by Fund_Claim_Deadline__c asc] ) {
            if(ba.CurrencyIsoCode==FundRequest.CurrencyIsoCode)
              AvailableAmount+=ba.Available_Budget__c;
            else
              AvailableAmount+=(ba.Available_Budget__c*IsoMap.get(FundRequest.CurrencyIsoCode))/(IsoMap.get(ba.CurrencyIsoCode));
            budgets.add(ba);
        }
        Decimal AmountLeft=FundRequest.Amount__c;
        if(budgets.size()>0)
        {
          for(SFDC_Budget__c ba:budgets)
          {
            if(ba.CurrencyIsoCode==FundRequest.CurrencyIsoCode)
            {
              decimal allocationAmount=ba.Available_Budget__c;
              if(AmountLeft<=allocationAmount)
              {
                budgetsAllocAdd.add(new Budget_Allocation__c(Budget__c=ba.id,Fund_Request__c=FundRequest.id,Amount__c=AmountLeft,RecordTypeId = rtid,CurrencyIsoCode=FundRequest.CurrencyIsoCode));
                AmountLeft=0;
                break;
              }
              else
              {
                budgetsAllocAdd.add(new Budget_Allocation__c(Budget__c=ba.id,Fund_Request__c=FundRequest.id,Amount__c=allocationAmount,RecordTypeId = rtid,CurrencyIsoCode=FundRequest.CurrencyIsoCode));
                AmountLeft=AmountLeft-allocationAmount;
              }
            }
            else
            {
              
              decimal allocationAmount=(ba.Available_Budget__c*IsoMap.get(FundRequest.CurrencyIsoCode))/(IsoMap.get(ba.CurrencyIsoCode));
              //throw new CustomException('here'+AmountLeft+' '+allocationAmount);
              if(AmountLeft<=allocationAmount)
              {
                budgetsAllocAdd.add(new Budget_Allocation__c(Budget__c=ba.id,Fund_Request__c=FundRequest.id,Amount__c=AmountLeft,RecordTypeId = rtid,CurrencyIsoCode=FundRequest.CurrencyIsoCode));
                AmountLeft=0;
                break;
              }
              else
              {
                budgetsAllocAdd.add(new Budget_Allocation__c(Budget__c=ba.id,Fund_Request__c=FundRequest.id,Amount__c=allocationAmount,RecordTypeId = rtid,CurrencyIsoCode=FundRequest.CurrencyIsoCode));
                AmountLeft=AmountLeft-allocationAmount;
              }
              
            }
          }
          if(budgetsAllocAdd.size()>0)
            {
              insert budgetsAllocAdd;
            }
          FundRequest.Funding_Approved__c=FundRequest.Amount__c-AmountLeft;
            //Anand Hegde - removed this from future call and added this here
            if(FundRequest.NumClaims__c==null)
                FundRequest.NumClaims__c = 0;
          return true;
        }
        else
        {
          FundRequest.addError(Label.No_Allocations_Msg);
          return false;
        }
    }

    // For fund request 
    // Create Budget allocations for FC
    // Currency check is done and FC allocation is created as per FC`s currency
    public static Boolean createBudgetAllocation(SFDC_MDF_Claim__c FundClaim)
    {
      
      initilizeCurrencyRate();
      SFDC_MDF_Claim__c claim;
      list<Budget_Allocation__c> budgetsAlloc= new list<Budget_Allocation__c> ();
      list<Budget_Allocation__c> budgetsAllocAdd= new list<Budget_Allocation__c>();
      claim = FundClaim;
      Id rtid = [select Id from RecordType where Name = 'Claimed' and SObjectType = 'Budget_Allocation__c' limit 1].Id;
      for (Budget_Allocation__c ba : [select Id, Name,CurrencyIsoCode, Amount__c, CreatedDate, Fund_Claim__c, Fund_Request__c, Reserve_Allocation__c, Temp_Claim_Allocation__c, Budget__c, Budget__r.Name,Budget__r.CurrencyIsoCode, Budget__r.End_Earned_Date__c, Budget__r.Unclaimed_Requests__c, Budget__r.Fund_Budget_Name__c, Budget__r.Fund_Claim_Deadline__c, Budget__r.Active__c, Budget__r.Claimed_Budget__c, Budget__r.Reserved_Budget__c from Budget_Allocation__c where Fund_Request__c = :claim.Fund_Request__c and RecordType.Name = 'Reserved' And Reserve_Closed__c = false And Budget__r.Unclaimed_Requests__c>0 order by Budget__r.End_Earned_Date__c ] ) {
            budgetsAlloc.add(ba);
        }
        //CR 2505504 - Anand Hegde - None of the fund budgets associated to the fund request should have expired.
        Boolean hasExpiredBudgets = false;
        for(Budget_Allocation__c ba : budgetsAlloc)
        {
            if(ba.Budget__r.Fund_Claim_Deadline__c!=null && ba.Budget__r.Fund_Claim_Deadline__c < Date.today())
            {
                hasExpiredBudgets = true;
                break;
            }
        }
        if(hasExpiredBudgets == true)
        {
            FundClaim.addError('Atleast one of the fund budgets associated with the fund request has passed the Fund Claim Deadline date. Please activate it and try again.');
            return false;
        }
                

            
        Decimal AmountLeft=claim.Amount__c;
        if(budgetsAlloc.size()>0)
        {
          for(Budget_Allocation__c ba:budgetsAlloc)
          {
            if(ba.CurrencyIsoCode==claim.CurrencyIsoCode)
            {
              decimal allocationAmount=ba.Amount__c;
              decimal BudgetUnclaimedAmount = (ba.Budget__r.Unclaimed_Requests__c*IsoMap.get(FundClaim.CurrencyIsoCode))/(IsoMap.get(ba.Budget__r.CurrencyIsoCode));//ba.Budget__r.Unclaimed_Requests__c;
              if(AmountLeft<=allocationAmount && AmountLeft<=BudgetUnclaimedAmount)
              {
                budgetsAllocAdd.add(new Budget_Allocation__c(Budget__c=ba.Budget__r.id,Fund_Claim__c=claim.id,Amount__c=AmountLeft,RecordTypeId = rtid,CurrencyIsoCode=claim.CurrencyIsoCode));
                AmountLeft=0;
                break;
              }
              else
              {
                allocationAmount=BudgetUnclaimedAmount<allocationAmount?BudgetUnclaimedAmount:allocationAmount;
                budgetsAllocAdd.add(new Budget_Allocation__c(Budget__c=ba.Budget__r.id,Fund_Claim__c=claim.id,Amount__c=allocationAmount,RecordTypeId = rtid,CurrencyIsoCode=claim.CurrencyIsoCode));
                AmountLeft=AmountLeft-allocationAmount;
              }
            }
            else
            {
              decimal allocationAmount=(ba.Amount__c*IsoMap.get(FundClaim.CurrencyIsoCode))/(IsoMap.get(ba.CurrencyIsoCode));
              decimal BudgetUnclaimedAmount = (ba.Budget__r.Unclaimed_Requests__c*IsoMap.get(FundClaim.CurrencyIsoCode))/(IsoMap.get(ba.Budget__r.CurrencyIsoCode));
              if(AmountLeft<=allocationAmount && AmountLeft<=BudgetUnclaimedAmount)
              {
                budgetsAllocAdd.add(new Budget_Allocation__c(Budget__c=ba.Budget__r.id,Fund_Claim__c=claim.id,Amount__c=AmountLeft,RecordTypeId = rtid,CurrencyIsoCode=claim.CurrencyIsoCode));
                AmountLeft=0;
                break;
              }
              else
              {
                allocationAmount=BudgetUnclaimedAmount<allocationAmount?BudgetUnclaimedAmount:allocationAmount;
                budgetsAllocAdd.add(new Budget_Allocation__c(Budget__c=ba.Budget__r.id,Fund_Claim__c=claim.id,Amount__c=allocationAmount,RecordTypeId = rtid,CurrencyIsoCode=claim.CurrencyIsoCode));
                AmountLeft=AmountLeft-allocationAmount;
              }
              
            }
          }
          if(budgetsAllocAdd.size()>0)
          insert budgetsAllocAdd;
          FundClaim.Approved_Amount__c=claim.Amount__c-AmountLeft;
          return true;
        }
        else
        {
          FundClaim.addError('No Fund Allocations found for Fund Requests.');
          return false;
        }
    }
    // Add channel mapping to Channel Manager field
    /*
    public static void UpdateChannelManager ( Opportunity[] opptys )   
    {  
      list<id> PartnerInvolvedIds = new list<id>();     
        for (Opportunity opp: opptys)
        {
              PartnerInvolvedIds.add(opp.Partner_Involved__c);
      }
      Boolean CmEntry;
      Map<Id, Channel_Mapping__c> cm_accid_map= OpportunityTriggerClass.GetChannelMapping(PartnerInvolvedIds);
      for (Opportunity opp: opptys)
        {
          CmEntry = false;
        for(Channel_Mapping__c cm: cm_accid_map.values())
        {
          if(cm.Partner_Name__c == opp.Partner_Involved__c && cm.PAE_ID__c == opp.FCM__c)
            {
              opp.Channel_Manager__c=cm.id;
              CmEntry = true;
            }
        }
        if(CmEntry == false)
        opp.addError(Label.Channel_Manager_to_Partner_Mapping_not_found);
        }
    }
    */
    // Add the Associated Partner Owner to Sales Team
    public static void AddToPartnerOwnerToSalesTeam ( Opportunity[] opptys )   
    {
      List<OpportunityTeamMember> updateOpptySalesTeamMemberList = new List<OpportunityTeamMember>();
      List<Id> ContactIdList = new List<Id>();
      map<id,User> contactIdUserMap = new map<id,User>(); 
      for (Opportunity opp: opptys)
        {
          ContactIdList.add(opp.Partner_Owner__c);
        }
        for(User usr:[select id,contact.AccountId,ContactId from User where ContactId In :ContactIdList])
        {
          contactIdUserMap.put(usr.ContactId,usr);
        } 
      for (Opportunity opp: opptys)
        {
          updateOpptySalesTeamMemberList.add(opptyAddSalesTeamMember(opp.id,contactIdUserMap.get(opp.Partner_Owner__c).id,'Partner'));
        }
        if(updateOpptySalesTeamMemberList.size()>0)
        insert updateOpptySalesTeamMemberList;
    }
    //HC this logic is moved to OpportunityPRMTriggerClass
    // Add Make Account owner as Opporunity owner
    /*
    public static void AddAccountOwner ( Opportunity[] opptys )   
    {     
      list<Id> opptylist = new list<Id>();  
      for (Opportunity opp: opptys)
        {
          opptylist.add(opp.AccountId);
        }
        List<Account> accList = [select OwnerId,Owner.Alias from Account where id IN :opptylist];
        Map<Id,Id> OwnerId_AccountIdMap=new Map<Id,Id>();
        Map<Id,string> OwnerId_AliasMap=new Map<Id,string>();
        for(Account acc:acclist)
        {
          OwnerId_AccountIdMap.put(acc.Id,acc.OwnerId);
          OwnerId_AliasMap.put(acc.id,acc.Owner.Alias);
        } 
        for (Opportunity opp: opptys)
        {
          if(OwnerId_AliasMap.get(opp.AccountId)=='ONA')
          {
            if(opp.Validation_Override__c==false)
            opp.AccountId.addError(label.Account_cannot_be_added_if_owner_is_Owner_Not_Assigned);
          }
          else
          opp.OwnerId = OwnerId_AccountIdMap.get(opp.AccountId);
        }
    }
    */
    // Increase/delete the current lincences count in account
    public static void UpdateContactEmail (User[] users ) 
    {   
    if(!updateUserRoleProfileFutureInvokeFirstRunFlag)
    return;
        System.Debug('=== UpdateContactEmail updateUserFutureFlag ' + updateUserFutureFlag);
    if(updateUserFutureFlag || system.Test.isRunningTest())
    return;
      List<String> Ids= new List<String>();
      for(User usr:users)
      {
        Ids.add(usr.ContactId+'#'+usr.Email);
      }
      if(Ids.size()>0)
    PRM_opportunity.updateContactEmailFutureInvoke(ids);
    }
    
    
  
    public static void updateUserUsernameOrEmail(Map<Id, String> contactIdToNewEmailMap, Map<Id, String> contactIdToNewLoginMap)
    {
        updateUserFutureFlag = true;
        System.Debug('=====$ updateUserFutureFlag ' + updateUserFutureFlag);
        Set<Id> setOfContactIds = new Set<Id>();
        if(contactIdToNewEmailMap!=null && contactIdToNewEmailMap.size()>0)
        {
            for(Id conId: contactIdToNewEmailMap.keySet())
            {
                setOfContactIds.add(conId);
            }
        }
        if(contactIdToNewLoginMap!=null && contactIdToNewLoginMap.size()>0)
        {
            for(Id conId: contactIdToNewLoginMap.keySet())
            {
                if(!setOfContactIds.contains(conId))
                    setOfContactIds.add(conId);
            }
        }
        System.Debug('==== inside ContactTriggerClass ' + setOfContactIds);
        Map<Id, String> userIdToNewEmailMap = new Map<Id,String>();
        Map<Id, String> userIdToNewUsernameMap = new Map<Id,String>();
        List<Contact> listOfPartnerContactsWithChangedLoginOrEmail = [select id, Active_Partner__c, Partner_User__c, Partner_User__r.isActive, Email, Login__c from Contact where Id IN :setOfContactIds and (Active_Partner__c=true or Partner_User__r.isActive=true)];
        List<User> listOfPartnerUsersToBeUpdated = new List<User>();
        if(listOfPartnerContactsWithChangedLoginOrEmail.size()>0)
        {
            for(Contact ithContact : listOfPartnerContactsWithChangedLoginOrEmail)
            {
                if(ithContact.Partner_User__c!=null)
                {
                    if(contactIdToNewEmailMap!=null && contactIdToNewEmailMap.containsKey(ithContact.Id))
                    {
                        userIdToNewEmailMap.put(ithContact.Partner_User__c, ithContact.Email);
                    }
                    if(contactIdToNewLoginMap!=null && contactIdToNewLoginMap.containsKey(ithContact.Id))
                    {
                        userIdToNewUsernameMap.put(ithContact.Partner_User__c, ithContact.Login__c);
                    }
                }
            }
            //SFDC-2741 Resolvng future to future error
            if(!system.isFuture())
            updateUserUsernamesOrEmailFuture(userIdToNewEmailMap , userIdToNewUsernameMap);
        }
    }

    @future
    public static void updateUserUsernamesOrEmailFuture(Map<Id, String> userIdToNewEmail, Map<Id, String> userIdToNewUsername)
    {
        updateUserFutureFlag = true;
        System.Debug('=====$ updateUserFutureFlag ' + updateUserFutureFlag);
        Set<Id> setOfUsers= new Set<Id>();
        List<User> userList = new List<User>();
        for(Id tempId: userIdToNewEmail.keySet())
        {
            User tempUser = new User(id=tempId);
            tempUser.Email = userIdToNewEmail.get(tempId);
            if(userIdToNewUsername!=null && userIdToNewUsername.containsKey(tempId))
            {
                tempUser.Username = userIdToNewUsername.get(tempId)+'.akamai';
            }
            setOfUsers.add(tempId);
            userList.add(tempUser);
        }
        for(Id tempId : userIdToNewUsername.keySet())
        {
            if(!setOfUsers.contains(tempId))
            {
                User tempUser = new User(id=tempId);
                tempUser.Username= userIdToNewUsername.get(tempId)+'.akamai';
                userList.add(tempUser);
                setOfUsers.add(tempId);
            }
        }

        System.Debug('>>>> setOfUsers' + setOfUsers + 'userList' + userList);

        if(userList.size()>0)
            update userList;
    }

  @future
  public static void updateContactEmailFutureInvoke(String[] Ids)
  {
        updateContactEmail(Ids);
  }
  public static void updateContactEmail(String[] Ids)
  {
    list<Contact> contactlist = new list<Contact>();
    if(ids.size()>0)
    {
      for(String idEmailMap:ids)
      {
        contactlist.add(new contact(id=idEmailMap.substring(0,idEmailMap.indexOf('#')),Email=idEmailMap.substring(idEmailMap.indexOf('#')+1,idEmailMap.length()),Validation_Override__c=true));
      }
      if(contactlist.size()>0)
        update contactlist;
    }
  }
  public static void AddErrorToAccount(list<Account> TriggerNew,map<id,Account> TriggeroldMap )
  {
    if(!AddErrorToAccountFristRunFlag)
    return;

    for(Account acc:TriggerNew)
    {
      system.debug('Validation override='+acc.Validation_Override__c);
      if(acc.IsPartner!=TriggeroldMap.get(acc.id).IsPartner && !acc.Validation_Override__c && (acc.No_Portal_Access__c==true || acc.Account_Status__c.contains('Inactive') || (acc.Partner_Type__c==null || acc.Partner_Type__c=='')))
        acc.AddError('Cannot Provide Portal Access to '+acc.Name+'. Please contact channelsupport@akamai.com for further support.');
    }
    AddErrorToAccountFristRunFlag=false;
  }
  public static void UpdateRoleOfPartner(list<User> usrs)
  {
    if(!UpdateRoleOfPartnerFirstRunFlag)
    return;
    list<User> usrlist= new list<User>();
    list<id> acidlist = new list<id>();
    for(User usr:usrs)
    {
      acidlist.add(usr.AccountId__c);
    }
    map<id,id> accidUsrroleMap = new map<id,id>();
    for(UserRole ur:[select id,PortalAccountId from UserRole where PortalAccountId IN :acidlist and Name like '%Partner Executive'])
    accidUsrroleMap.put(ur.PortalAccountId,ur.id);
    for(User usr:usrs)
    {
      if(accidUsrroleMap.get(usr.AccountId__c)!=null)
      {
        User newuser= new User(id=usr.id);
        newuser.UserRoleId=accidUsrroleMap.get(usr.AccountId__c);
        usrlist.add(newuser);
      }
    }
    if(usrlist.size()>0)
    update usrlist;
    UpdateRoleOfPartnerFirstRunFlag=false;
  }

  
  webservice static String campaignManagerApproval(Id opptyId){
    Opportunity updateObject;
    for(Opportunity o:[Select id, Associated_Lead__c, Campaign_Manager_Approved__c from Opportunity where id = :opptyId]){
      if(o != null) {updateObject = o;}
    }
    
    if(updateObject.Associated_Lead__c == null) {
      return 'There is no lead associated with this Opportunity';
    }
    
    if(updateObject.Campaign_Manager_Approved__c == true) {
      return 'This Tieback has already been approved';
    }
    
    updateObject.Campaign_Manager_Approved__c = true;
    updateObject.Validation_Override__c = true;
    
    update updateObject;
    
    return 'Successfully Approved this tieback';
  }
  public static void UpdateFundBudgetShares(string[] AccountIds)
  {
    if(!UpdateFundBudgetSharesFirstRunFlag)
    return;
    //throw new CustomException('Here'+AccountIds);
    UpdateFundBudgetSharesFutureCall(AccountIds);
    
    UpdateFundBudgetSharesFirstRunFlag=false;
  }
  //CR 1502425 PRM Need to allow Partner Support the capability to add sharing rules to Fund Budget
  // UpdateFundBudgetSharesFutureCall : A future method to create sharing rules for budget when a user is activated for the first time
  @future
  public static void UpdateFundBudgetSharesFutureCall(string[] AccountIds)
  {
    map<id,id> BudgetAccount_Map = new map<id,id>();
    List<SFDC_Budget__Share> newSObjectShares = new List<SFDC_Budget__Share>();
    for(SFDC_Budget__c fb:[select id,Account__c from SFDC_Budget__c where Account__c IN :AccountIds and Active__c=True])
    {
      BudgetAccount_Map.put(fb.id,fb.Account__c);
    }
    if (! BudgetAccount_Map.isEmpty()) {
            FundBudgetShares.createSObjectShare(BudgetAccount_Map, newSObjectShares, 'BUDGET');
        } 
  }
  
  WebService static String makePartnerAccount(Id p_accId)
    {
      string returnmsg='';
      Account acc=[select IsPartner from Account where id=:p_accId][0];
        acc.IsPartner=true;
        acc.IsPartnerCustom__c=true;
        /*
           Anand replaced this if else with the above 2 lines
      if(acc.IsPartner==false)
        acc.IsPartner=True;
      else
        acc.IsPartnerCustom__c=True;
            */
      try
      {
        update acc;
      }
      catch(Exception e)
        {
             for (Integer i = 0; i < e.getNumDml(); i++)
             { 
                 returnmsg+=e.getDmlMessage(i)+'<br/>';
             }
        }
        if(returnmsg!='')
          return returnmsg;
        else
          return '';
    }
    WebService static String DisablePartnerAccount(Id p_accId)
    {
      string returnmsg='';
      try
      {
          if(returnmsg=='')
          {
            //disable all users for that account
            list<User> DisableUserList=new list<User>();
            for(User u:[select id from User where AccountId=:p_accId and Isactive=true])
            {
              u.IsActive=false;
              DisableUserList.add(u);
            }
          
            if(DisableUserList.size()>0)
            update DisableUserList;
            
          }
      }
      catch(Exception e)
        {
             for (Integer i = 0; i < e.getNumDml(); i++)
             { 
                 returnmsg+=e.getDmlMessage(i)+'<br/>';
             }
             if(returnmsg=='')
             returnmsg=e.getMessage();
        }
        if(returnmsg=='')
        {
          DeactivateParterAccount(p_accId);
        }
        if(returnmsg!='')
          return returnmsg;
        else
          return '';
    }
    @future 
    public static void DeactivateParterAccount(string accid)
    {
      Account acc=new Account(id=accid);
      acc.IsPartnerCustom__c=false;
        /*
           Disabling out of the box isPartner permanently deletes all the partner roles
        acc.IsPartner=false;
        */
      acc.Validation_Override__c=true;
      update acc;
      //SFDC-8973
      List<Contact> cons = [select id,Has_Akamai_University_Access__c,DoNotSync__c,Validation_Override__c, Partner_User__c from Contact where AccountId=:accid ];
      system.debug('*********TS cons ' + cons);
      if(cons.size()>0){
        for(contact c : cons ){
          c.Has_Akamai_University_Access__c = false;
          c.DoNotSync__c = false;
          c.Validation_Override__c = true;
          try{
            update c;
            system.debug('************* here in try');
          }
          catch (Exception e){
            sawyer.saw(e);
          }
        }
        
      }
    }
    public static void ValidateFundBudgetCurrency(list<SFDC_Budget__c> recs)
    {
      if(!ValidateFundBudgetCurrencyFirstRunFlag)
    return;
      list<id> Accountids= new list<id>();
      map<id,string> AccountIdCurrencyMap=new map<id,string>();
      for(SFDC_Budget__c rec:recs)
      {
        Accountids.add(rec.Account__c);
      }
      for(Account acc:[select id,Default_MDF_Currency__c from Account where id in :Accountids])
      AccountIdCurrencyMap.put(acc.id,acc.Default_MDF_Currency__c);
      for(SFDC_Budget__c rec:recs)
      {
        if(rec.CurrencyIsoCode!=AccountIdCurrencyMap.get(rec.Account__c))
        rec.CurrencyISOCode.adderror('Currency should be '+AccountIdCurrencyMap.get(rec.Account__c));
      }
      ValidateFundBudgetCurrencyFirstRunFlag=false;
    }
    public static void ValidateFundRequestCurrency(list<SFDC_MDF__c> recs)
    {
      if(!ValidateFundRequestCurrencyFirstRunFlag)
    return;
      list<id> Accountids= new list<id>();
      map<id,string> AccountIdCurrencyMap=new map<id,string>();
      for(SFDC_MDF__c rec:recs)
      {
        Accountids.add(rec.Account__c);
      }
      for(Account acc:[select id,Default_MDF_Currency__c from Account where id in :Accountids])
      AccountIdCurrencyMap.put(acc.id,acc.Default_MDF_Currency__c);
      for(SFDC_MDF__c rec:recs)
      {
        if(rec.CurrencyIsoCode!=AccountIdCurrencyMap.get(rec.Account__c))
        rec.CurrencyISOCode.adderror('Currency should be '+AccountIdCurrencyMap.get(rec.Account__c));
      }
      ValidateFundRequestCurrencyFirstRunFlag=false;
    }
    public static void ValidateFundClaimCurrency(list<SFDC_MDF_Claim__c> recs)
    {
      if(!ValidateFundClaimCurrencyFirstRunFlag)
    return;
      list<id> FRids= new list<id>();
      map<id,string> FRIdCurrencyMap=new map<id,string>();
      for(SFDC_MDF_Claim__c rec:recs)
      {
        FRids.add(rec.Fund_Request__c);
      }
      for(SFDC_MDF__c acc:[select id,CurrencyIsoCode from SFDC_MDF__c where id in :FRids])
      FRIdCurrencyMap.put(acc.id,acc.CurrencyIsoCode);
      for(SFDC_MDF_Claim__c rec:recs)
      {
        if(rec.CurrencyIsoCode!=FRIdCurrencyMap.get(rec.Fund_Request__c))
        rec.CurrencyISOCode.adderror('Currency should be '+FRIdCurrencyMap.get(rec.Fund_Request__c));
      }
      ValidateFundClaimCurrencyFirstRunFlag=false;
    }
    
    webservice static String updateRebatePayoutStatusAndCreateTask(Id rebatePayoutId, Id partnerAccountId)
    {
      String result='';
      try
      {
       Rebate_Payout__c rp=new Rebate_Payout__c(id=rebatePayoutId,Status__c='In Process');
       update rp;
      
       Task rpTask=new Task();
       rpTask.Subject='Request for Rebate Payment';
       rpTask.WhatId=rebatePayoutId;
         //SFDC-1134 - Assign to CMG
         rpTask.OwnerId = getAccountCMGAnalyst(partnerAccountId);
         if(rpTask.OwnerId==null)
             rpTask.OwnerId=UserInfo.getUserId();

       insert rpTask;
       result='Successfully sent to CMG';
      }
      catch(Exception e)
      {
        result ='Error occurred - Error message : '+e.getMessage();
      }
      return result;
    }
    
    public static void addPartnerAdminSharing(List<Id> accountIdList,List<Rebate_Payout__c> rebatePayoutList)
    {

      List<Id> accountIds = new List<Id>();
        for(Account acc : [Select id, parentid, parent.parentid, parent.parent.parentid, parent.parent.parent.parentid, parent.parent.parent.parent.parentid from account where id IN :accountIdList]){
            if(acc.parentid != NULL){
                accountIds.add(acc.parentid);
                if(acc.parent.parentid != NULL){
                    accountIds.add(acc.parent.parentid);
                    if(acc.parent.parent.parentid != NULL){
                        accountIds.add(acc.parent.parent.parentid);
                        if(acc.parent.parent.parent.parentid != NULL){
                            accountIds.add(acc.parent.parent.parent.parentid);
                            if(acc.parent.parent.parent.parent.parentid != NULL){
                                accountIds.add(acc.parent.parent.parent.parent.parentid);
                            }
                        }
                    }
                }
            }
            
        }
        
        accountIds.addAll(accountIdList);

      List<Contact> partnerAdminContactList=[select Id
                                                    ,Partner_User__c
                                                    ,AccountId 
                                               from Contact 
                                               where AccountId IN :accountIds 
                                               and Partner_User__r.ProfileId= :GsmUtilClass.getPRMSettingValue('Partner_Admin_Id') and Partner_User__r.isActive=true];

       List<Id> ownerIds =new List<Id>();
       for(Rebate_Payout__c rp: rebatePayoutList)
       {
        ownerIds.add(rp.ownerId);
       }                                               
       List<Rebate_Payout__Share> rebateAddShareList=new List<Rebate_Payout__Share>();
       List<Rebate_Payout__Share> rebateDeleteShareList=[select Id,UserOrGroupId from Rebate_Payout__Share where parentId IN : rebatePayoutList and rowCause='Manual' and UserOrGroupId not IN : ownerIds];
       if(rebateDeleteShareList !=null && rebateDeleteShareList.size()>0)
       {
        delete rebateDeleteShareList;
       }
       for(Rebate_Payout__c rp:rebatePayoutList)
       {
          for(Contact con: partnerAdminContactList)                                              
        {
          //if(con.AccountId==rp.Associated_Partner__c)
          //{
           Rebate_Payout__Share rpShare=new Rebate_Payout__Share(parentId=rp.Id,UserOrGroupId=con.Partner_User__c,AccessLevel='Read');
           rebateAddShareList.add(rpShare);
          //}         
        }
       }
       if(rebateAddShareList.size()>0)
       {
         insert rebateAddShareList;
       }
    }


    //SFDC-8975
     public static void modifyPartnerAdminSharingForUser(List<Rebate_Payout__c> rebatePayoutList, List<id> addRpShare , List<id> deleteRpshare)
    {

       List<Id> ownerIds =new List<Id>();
       for(Rebate_Payout__c rp: rebatePayoutList)
       {
        ownerIds.add(rp.ownerId);
       }                                               
       List<Rebate_Payout__Share> rebateAddShareList=new List<Rebate_Payout__Share>();
       List<Rebate_Payout__Share> rebateDeleteShareList=[select Id,UserOrGroupId from Rebate_Payout__Share where parentId IN : rebatePayoutList and rowCause='Manual' and UserOrGroupId  IN : deleteRpshare];

       
       System.debug('********TS rebatePayoutList  ' + rebatePayoutList);
       for(Rebate_Payout__c rp:rebatePayoutList)
       {
          for(Id userIDforAdd: addRpShare)                                              
        {
          //system.debug('&&&&&&&&TS con '+ con);
          //if(con.AccountId==rp.Associated_Partner__c)
          //{
           Rebate_Payout__Share rpShare=new Rebate_Payout__Share(parentId=rp.Id,UserOrGroupId=userIDforAdd,AccessLevel='Read');
           System.debug('********TS rpShare  ' + rpShare);

           rebateAddShareList.add(rpShare);
          //}         
        }

       }
       if(rebateAddShareList.size()>0)
       {
         //insert rebateAddShareList;
         GsmUtilClass.doDatabaseInsert(rebateAddShareList,'PRM_opportunity','modifyPartnerAdminSharingForUser',true);
         System.debug('********TS rebateAddShareList  ' + rebateAddShareList);

       }


       if(rebateDeleteShareList !=null && rebateDeleteShareList.size()>0)
       {
        delete rebateDeleteShareList;
       }
    }

//SFDC-3089
    public static void populateFieldsFromPMA(list<SFDC_MDF__c> fundRequestPopulateFields){
      if(!populateFieldsFromPMAFirstRunFlag)
        return;
        Map<String,String> pmaFrMapping = GsmUtilClass.getGSMSettingValuePartialMatchMap('PMFR_');
        List<Id> pmaCmpIds = new List<Id>();
        Map<Id,SFDC_MDF__c> cmpFRMap = new Map<Id,SFDC_MDF__c>();
        List<Partner_Marketing_Activity__c> pmaList = new List<Partner_Marketing_Activity__c>();
        PartnerMarketingClass pmaObj = new PartnerMarketingClass();
        String query = '';
        List<String> parameters = new List<String>();
        for(String mapping: pmaFrMapping.keySet()){
          parameters.add(pmaObj.formulateField(mapping,'PMFR_'));
          //pmaFrMapping.put(pmaCmpMapping.get(mapping),pmaObj.get(formulateField(mapping,'PMA_')));
        }
        parameters.add('Indirect_Campaign__c');
        for(SFDC_MDF__c fr: fundRequestPopulateFields){
            pmaCmpIds.add(fr.Fund_Request_Campaign__c);
            cmpFRMap.put(fr.Fund_Request_Campaign__c,fr);

        }
      al.SoqlBuilder queryBuilder = new al.SoqlBuilder()
                                      .selectx(parameters)
                                      .fromx('Partner_Marketing_Activity__c')
                                      .wherex(new al.SetCondition('Indirect_Campaign__c').inx(new List<Id>(pmaCmpIds)));
        query = queryBuilder.toSoql();
        system.debug(LoggingLevel.ERROR,'query:: '+query);
        try
        {
            pmaList = Database.query(query);
        }
        catch(Exception exc)
        {
            System.Debug(LoggingLevel.ERROR,'SOQL_ERROR' + exc.getMessage());
        }
        for(Partner_Marketing_Activity__c pma:pmaList)
            if(cmpFRMap.containsKey(pma.Indirect_Campaign__c))
                {
                    SFDC_MDF__c fr = cmpFRMap.get(pma.Indirect_Campaign__c);
                    for(String mapping: pmaFrMapping.keySet()){
                      fr.put(pmaFrMapping.get(mapping),pma.get(pmaObj.formulateField(mapping,'PMFR_')));
                    }
                    system.debug(LoggingLevel.ERROR,'fr in population:: '+fr);
                }
      populateFieldsFromPMAFirstRunFlag = false;
    }

    public static void updateCampaignOnFundRequest(List<SFDC_MDF__c> fundReqs) {

        if(!updateCampaignOnFundRequestFirstRunFlag)
          return;

        List<Id> pmaIdList = new List<Id>();
        Map<Id,Id> pmaToCampaignIdMap = new Map<Id,Id>();

        for (SFDC_MDF__c fr:fundReqs) {
            pmaIdList.add(fr.Partner_Marketing_Activity__c);
        }

        for (Partner_Marketing_Activity__c pma:[Select id,Indirect_Campaign__c 
                                                        From Partner_Marketing_Activity__c
                                                        Where id IN:pmaIdList]) {

            pmaToCampaignIdMap.put(pma.id, pma.Indirect_Campaign__c);
        }

        for (SFDC_MDF__c frr:fundReqs) {
            frr.Fund_Request_Campaign__c = pmaToCampaignIdMap.get(frr.Partner_Marketing_Activity__c);
        }

        updateCampaignOnFundRequestFirstRunFlag = false;
    }
    //SFDC-9141
  public static Opportunity updateOpptyFields(Merge_Contract_Header__c currContract , Opportunity drOpp ){

    Date endDate = currContract.Effective_End_Date__c;
    Date startDate = currContract.Revision_Effective_Start_Date__c!=null ? currContract.Revision_Effective_Start_Date__c : currContract.Effective_Start_Date__c;
    integer contractLen= (endDate.year() - startDate.year())*12 + endDate.month() - startDate.month();

      // List<Opportunity> updateOpptyList = new List<Opportunity>();
      // for(Opportunity opp : [Select id, Contract_Length__c,Payout_Date__c from Opportunity where id in :opptyToContractMap.keySet() ]){
      //     opp.Contract_Length__c = calculateLen(opptyToContractMap.get(opp.id));
      //     opp.Payout_Date__c = opptyToContractMap.get(opp.id).Effective_End_Date__c;
      //     updateOpptyList.add(opp);
      // }
      // if(updateOpptyList.size()>0){
      //   GSMUtilClass.doDatabaseUpdate(updateOpptyList, 'MergeContractHeaderTriggerClass', 'updateOpptyFields');
      // }   
      
      // Opportunity opp = new Opportunity(id = currContract.Opportunity_Name__c);
      drOpp.Contract_Length__c = contractLen;
      drOpp.Payout_Date__c = currContract.Effective_End_Date__c;
      //drOpp.validation_override__c = true;

      if(contractLen<Integer.valueOf(GSMUtilClass.getNAPSettingValue('contract_Length_1'))){  
        drOpp.Rebate__c = GSMUtilClass.getNAPSettingValue('rebate_tier_1');
      }
    else if(contractLen<Integer.valueOf(GSMUtilClass.getNAPSettingValue('contract_Length_2'))){
        drOpp.Rebate__c = GSMUtilClass.getNAPSettingValue('rebate_tier_2'); 
      }
      else{
        drOpp.Rebate__C = GSMUtilClass.getNAPSettingValue('rebate_tier_3');
      }
      return drOpp; 

      
      
      
  }

}