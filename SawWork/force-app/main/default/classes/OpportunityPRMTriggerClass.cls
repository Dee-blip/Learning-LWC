global class OpportunityPRMTriggerClass {

    public static Boolean isopptyWithRejectedDealRegStatus = true;
    public static Map<Id, Channel_Mapping__c> ChannelMapping_Id_Map;
      private static Boolean onDealApprovalFristRunFlag = true;
//SFDC-1595
    public static Boolean populateChannelLevelFirstRunFlag = true;
    public static Boolean populateChannelLevelEventUpdate = false;
    // SFDC-9133
    private static Boolean calcDRRebateAtClosedWon = true;
    public static map<String,Double> IsoMap = new map<String,Double>();


    // The curreny is fetched and put in a map so that it can used later if needed.
    
    public static void initilizeCurrencyRate()
    {   
        for (CurrencyType ct :[Select IsoCode, ConversionRate From CurrencyType where IsActive=true])
            IsoMap.put(ct.IsoCode,ct.ConversionRate);
    }

    //SFDC -1337
    public static void setFieldsWhenDealIsRejected(List<Opportunity> opptyWithRejectedDealRegStatus)
    {
        system.debug('Static variable '+OpportunityTriggerHandler.amgOppRecordType);
        if(!isopptyWithRejectedDealRegStatus)
            return;
        for(Opportunity oppty: opptyWithRejectedDealRegStatus)//Code-coverage
        {
            oppty.Discount_Status__c = 'Not Qualified';
            oppty.Discount_Percentage__c = 0;
        }
        isopptyWithRejectedDealRegStatus = false;

    }

    // Update Owner to Partner Owner
    // CR 1077168 PRM - Add associated contact field to deal registration page
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


    // Add channel mapping to Channel Manager field
    public static void UpdateChannelManager ( Opportunity[] opptys )   
    {  
      list<id> PartnerInvolvedIds = new list<id>();     
        for (Opportunity opp: opptys)
        {
              PartnerInvolvedIds.add(opp.Partner_Involved__c);
      }
      Boolean CmEntry;
      Map<Id, Channel_Mapping__c> cm_accid_map= GetChannelMapping(PartnerInvolvedIds);
      for (Opportunity opp: opptys)
        {
          CmEntry = false;
        for(Channel_Mapping__c cm: cm_accid_map.values())
        {
          if(cm.Partner_Name__c == opp.Partner_Involved__c && (cm.PAE_ID__c == opp.FCM__c || cm.Comp_Owner1__c == opp.FCM__c)) //SFDC-2590 (added cm.Comp_Owner1__c == opp.FCM__c condition)
            {
              opp.Channel_Manager__c=cm.id;
              CmEntry = true;
            }
        }
        if(CmEntry == false)
        opp.addError(Label.Channel_Manager_to_Partner_Mapping_not_found);
        }
    }

    // Add Fcm and set Channel manager on record Creation for Opporunirty (Only for partners)
    public static void addFCMdealcreation ( Opportunity[] opptys )   
    {       
        //initilizeChannelMappingdata();    
        User partnerUser = [select contactId,contact.AccountId from User where id =:Userinfo.getUserId()];                      
        //Contact partnerContactId = [select AccountId from Contact where Id=:partnerUser.ContactId ];    
        list<id> AccId = new list<id>();
        AccId.add(partnerUser.contact.AccountId); 
        Map<Id, Channel_Mapping__c> cm_accid_map;
        if(AccId.size()>0)
            cm_accid_map = GetChannelMapping(AccId);
        List<Channel_Mapping__c> fcmIds= getCMRecordsForAccount(partnerUser.contact.AccountId);
        for (Opportunity opp: opptys)
        {
          if(fcmIds.size()==1)
          {
            opp.FCM__c=fcmIds[0].PAE_ID__c;
            opp.Channel_Manager__c=fcmIds[0].id;
          }
        }
           
    }

    // Update the Owners of deal and add to case team (after trigger)
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

    //Code-coverage
    public static Map<Id, Channel_Mapping__c> GetChannelMapping(list<Id> Accid)
    {   
        if(ChannelMapping_Id_Map == null)
            ChannelMapping_Id_Map = new Map<Id, Channel_Mapping__c>();
        Boolean queryRunFlag = true;
        if(queryRunFlag)
        {
            for (Channel_Mapping__c cm :[SELECT Id, Partner_Name__c, PAE_ID__c, VAR_Manager_Team_Role__c,PAE_ID__r.ManagerId,MDF_Approver__c, Comp_Owner1__c FROM Channel_Mapping__c WHERE Active__c = True and Partner_Name__c IN :AccId]) //SFDC-2590(queried Comp_Owner1__c field and removed (VAR_Manager_Status__c='Active' or Comp_Owner1__r.IsActive=true) check as part of SFDC-2649)
                ChannelMapping_Id_Map.put(cm.Id, cm);
        }
        
        return ChannelMapping_Id_Map;
    }

    public static List<Channel_Mapping__c> getCMRecordsForAccount(Id pAccountId)
    {
        List<Channel_Mapping__c> cmList = new List<Channel_Mapping__c>();
        for(Channel_Mapping__c cm: ChannelMapping_Id_Map.values())
        {
            if(cm.Partner_Name__c == pAccountId)
                cmList.add(cm);
        }
        return cmList; 
    }

   // On Deal approval check if Account is added
    public static void onDealApproval ( Opportunity[] opptys )   
    {   
        if (!onDealApprovalFristRunFlag)
          return;

        // SFDC-4549 Added By Prabhanjan ( Logic to Add ESR )
        // SFDC-9133- modified query to add No_Rebate_Required__c and get metadata values
        List<Opportunity> opptys_queried = [Select Id,Account.Anaplan_Sub_Territory__c,Primary_Product__c,Secondary_Product__c,Validation_Override__c,AccountId,Partner_Involved__r.No_Rebate_Required__c,Deal_Type__c,Deal_Reg_Account_Status__c,Deal_Registration_Approved_Date__c from Opportunity where id in : opptys ];
        String drRebateEligibleAccStatus = GsmUtilClass.getPRMSettingValue('DRRebateEligibleAccountDRStatus');
        List<String> rebateEligibleAccStatus = drRebateEligibleAccStatus.split(',');
        Map<id,Opportunity> DRrebateCalcMap = new Map<id, Opportunity>();
        // SFDC-9133 - End
        List<String> subTerritories = new List<String>();
        List<String> keyValues = new List<String>();
        Map <String, Object> PrimaryAndSecondaryProductMap_JSON = (Map <String, Object>) JSON.deserializeUntyped(GSMSettings.getVerbose('PrimaryAndSecondaryProductMap_Oppty'));
        List<String> allProducts = new List<String>();
        Map<String,String> PrimaryAndSecondaryProductMap = new Map<String,String>();
        Map<Id,String> opptyIdToAnaplanST = new Map<Id,String>();

        for (String key : PrimaryAndSecondaryProductMap_JSON.keySet()) {
            Object value = PrimaryAndSecondaryProductMap_JSON.get(key);
            for (String temp : String.valueOf(value).split(',')) {
              allProducts.add(temp);
              PrimaryAndSecondaryProductMap.put(temp,key);
            }
        }
        
        for (Opportunity opp: opptys_queried) {
            //SFDC-4549 Added By Prabhanjan
            Boolean subTerritoryAdded = false;
            if (allProducts.contains(opp.Primary_Product__c) && PrimaryAndSecondaryProductMap.containsKey(opp.Primary_Product__c)) {
                subTerritories.add(opp.Account.Anaplan_Sub_Territory__c);
                opptyIdToAnaplanST.put(opp.Id,opp.Account.Anaplan_Sub_Territory__c);
                subTerritoryAdded = true;
                keyValues.add(PrimaryAndSecondaryProductMap.get(opp.Primary_Product__c));
            }
            else if (allProducts.contains(opp.Secondary_Product__c) && PrimaryAndSecondaryProductMap.containsKey(opp.Secondary_Product__c)) {
                if (!subTerritoryAdded) {
                  opptyIdToAnaplanST.put(opp.Id,opp.Account.Anaplan_Sub_Territory__c);
                  subTerritories.add(opp.Account.Anaplan_Sub_Territory__c);
                }
                keyValues.add(PrimaryAndSecondaryProductMap.get(opp.Secondary_Product__c));
            }
        }
       
        if (keyValues.size() > 0 && subTerritories.size() > 0) {
            SubTerritoryHelper StHelper = new SubTerritoryHelper(keyValues,subTerritories);
            Map<String,Id> anaplanSTtoSpecialsitUser = StHelper.getAnaplanSTtoSpecialsitUser();
            Map<Id,Id> userIdTospecialistCompTeam = StHelper.getUserIdTospecialistCompTeam();
            Map<String,String> keyValueToOpptyFieldName = StHelper.getKeyValueToOpptyFieldName();
			
            for (Opportunity opp: opptys) {
                if(!opp.Validation_Override__c && opp.AccountId==null)
                  opp.AddError('Account is mandatory before Approval of the deal');

                Id userId = null;
                String keyValue = '';
                if (anaplanSTtoSpecialsitUser.containsKey(opptyIdToAnaplanST.get(opp.Id))) {
                    userId = anaplanSTtoSpecialsitUser.get(opptyIdToAnaplanST.get(opp.Id));
                    if (PrimaryAndSecondaryProductMap.containsKey(opp.Primary_Product__c)) {
                       keyValue = PrimaryAndSecondaryProductMap.get(opp.Primary_Product__c);
                    }
                    else {
                       keyValue = PrimaryAndSecondaryProductMap.get(opp.Secondary_Product__c);
                    }
                }
               
                if (userId != null && keyValue !='' && userIdTospecialistCompTeam.containsKey(userId) && keyValueToOpptyFieldName.containsKey(keyValue)) {
                        String opptyFieldToUpdate = keyValueToOpptyFieldName.get(keyValue);
                    	opp.put(opptyFieldToUpdate,userIdTospecialistCompTeam.get(userId));       
                }
            } 
        }
        // SFDC-9133 - calling from here to save on additional query in calcDRRebate method and to avoid additional testing by splitting query from here to common place.
        for (Opportunity drOpp: opptys_queried) {
          if(drOpp.Deal_Type__c=='Indirect' && rebateEligibleAccStatus!=null && rebateEligibleAccStatus.contains(drOpp.Deal_Reg_Account_Status__c) && !drOpp.Partner_Involved__r.No_Rebate_Required__c){
            DRrebateCalcMap.put(drOpp.id, drOpp);
            system.debug(LoggingLevel.Error, 'DR acc no rebate:: '+drOpp.Partner_Involved__r.No_Rebate_Required__c);
        }
      }
      if(!DRrebateCalcMap.isEmpty())
        calcDRRebate(DRrebateCalcMap,opptys);
        
        onDealApprovalFristRunFlag=false;
    }

    // SFDC-9133
    public static void calcDRRebate(Map<id,Opportunity> DRrebateCalcMap, List<Opportunity> origOppty){
      
      // List<Opportunity> oppList = [select Id,Partner_Involved__r.No_Rebate_Required__c from Opportunity where id in :DRRebateCalcList ];
      for(Opportunity drOpp: origOppty){
        if(DRrebateCalcMap.containsKey(drOpp.id))
          drOpp.rebate__c = GSMUtilClass.getNAPSettingValue('rebate_tier_1');
      
      
    }
  }

    //  SFDC-9133
    public static void calcDRRebateAtClosedWon( List<Opportunity> origOppty){
      
      if(!calcDRRebateAtClosedWon)
        return;
      List<Merge_Contract_Header__c> contractList = [select Id,name,Opportunity_Name__c, Effective_End_Date__c, Revision_Effective_Start_Date__c, Effective_Start_Date__c from Merge_Contract_Header__c where Opportunity_Name__c in :origOppty ];
      for(Opportunity drOpp: origOppty){
        for(Merge_Contract_Header__c con: contractList){
          if(con.Opportunity_Name__c==drOpp.id)
              PRM_opportunity.updateOpptyFields(con,drOpp);    
              system.debug(LoggingLevel.Error,'drOpp:: ' +drOpp);
        }
    }
    calcDRRebateAtClosedWon = false;
  }

    // Add Make Account owner as Opporunity owner
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

    //SFDC-1595
    public static List<Opportunity> populateChannelLevel(List<Opportunity> oppList,Boolean isUpdate) {
        system.debug(LoggingLevel.ERROR,'populateChannelLevelEventUpdate: '+populateChannelLevelEventUpdate+' isUpdate: '+isUpdate);
        system.debug(LoggingLevel.ERROR,'populateChannelLevelFirstRunFlag: '+populateChannelLevelFirstRunFlag);
        //it could be update or upsert
            //insert populateChannelLevelEventUpdate -> false isUpdate-> false
            //update populateChannelLevelEventUpdate -> false isUpdate-> true
            //it should not rerun in case of update only, but should rerun in case of upsert.`
        if(populateChannelLevelEventUpdate!=isUpdate)
            populateChannelLevelFirstRunFlag=true;
        if(!populateChannelLevelFirstRunFlag)
            return new List<Opportunity>();
        List<String> gssmKeyList = new List<String>();
        for(Opportunity opp: oppList){
                opp.Channel_Hierarchy_Map__c = null;
                gssmKeyList.add(opp.GSSM_Key__c);
            }
            system.debug(LoggingLevel.ERROR,'gssmKeyList: '+gssmKeyList );
                for(Channel_Hierarchy_Map__c clmObj: [select id,Name from Channel_Hierarchy_Map__c where Name IN :gssmKeyList]){
                    for(Opportunity opp: oppList){
                        if(opp.GSSM_Key__c==clmObj.Name)
                            opp.Channel_Hierarchy_Map__c = clmObj.id;
                            system.debug(LoggingLevel.ERROR,'opp.Channel_Hierarchy_Map__c: '+opp.Channel_Hierarchy_Map__c);
                    }

                }

                if(populateChannelLevelEventUpdate!=isUpdate)
                    populateChannelLevelEventUpdate = isUpdate;
                system.debug(LoggingLevel.ERROR,'populateChannelLevelEventUpdate in end: '+populateChannelLevelEventUpdate);
                populateChannelLevelFirstRunFlag=false;
               
               return oppList;
   
    }

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

    //SFDC-2324
    public static void updateFCMForDealRegOpptys(List<Opportunity> fcmChangedOpptyList,Set<Id> channelMappingIds)
    {
      Map<Id,Id> cmIdToPaeId = new Map<Id,Id>();

      for(Channel_Mapping__c eachCM : [select Id,PAE_ID__c,Comp_Owner1__c,Master_Channel_Mapping__c,PAE_ID__r.IsActive,Comp_Owner1__r.IsActive from Channel_Mapping__c where Id in :channelMappingIds])
      {
          //SFDC-2590
          if(eachCM.Master_Channel_Mapping__c && eachCM.PAE_ID__c!=null && eachCM.PAE_ID__r.IsActive)
          cmIdToPaeId.put(eachCM.Id, eachCM.PAE_ID__c);
          else if(!eachCM.Master_Channel_Mapping__c && eachCM.Comp_Owner1__c!=null && eachCM.Comp_Owner1__r.IsActive)
            cmIdToPaeId.put(eachCM.Id, eachCM.Comp_Owner1__c);
      }
      
      if(cmIdToPaeId != null && !cmIdToPaeId.isEmpty())
      {
        for(Opportunity eachOppty : fcmChangedOpptyList)
        {
          eachOppty.FCM__c = cmIdToPaeId.get(eachOppty.Channel_Manager__c);
        }
      }
    }
    //End of SFDC-2324

     //SFDC-9224
     public static void sendEmailWhenRebateChanges( Opportunity[] opptys)
    {
        
        string AkamaiEmailIdentifier = GsmUtilClass.getGSMSettingValue('OpptyTriggerClass_AkamaiIdentifier'); //SFDC-2304
        string SendEmailWhenClosedWonFlag = GsmUtilClass.getGSMSettingValue('OpptyTriggerClass_SendEmailClosedWon'); //SFDC-2304
        //SFDC-2572
        string PartnerPortalOrgWideId = GsmUtilClass.getPRMSettingValue('Partner_Portal_Email_Id');
        String emailHeader=GsmUtilClass.getGSMSettingValue('CFA_SendEmailController_EmailHeader'); //SFDC-2304
        String emailfooter=GsmUtilClass.getGSMSettingValue('CFA_SendEmailController_Emailfooter'); //SFDC-2304
  
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

        List<Id> partnerInvolvedIds = new List<Id>();
        //Id partnerInvolved = oppty.Partner_Involved__c;
        // SFDC-9285
        String PartnerSfURL;
        if(PartnerSfURL=='')
            {
                if (Test.isRunningTest()) {
                    PartnerSfURL= GsmUtilClass.getGSMSettingValue('CFA_SendEmailController_SfUrl'); //SFDC-2304
                }
                else{
                    Organization org=[select Fax,Division from Organization limit 1][0];
                    PartnerSfURL=org.Fax;
                }
            }
        //Get the email template that needs to be used
        EmailTemplate EmTempPartner=null;
        for(EmailTemplate em:[select Body,Subject,DeveloperName from EmailTemplate where DeveloperName='Rebate_Change_Email' ])
        {
            if(em.DeveloperName=='Rebate_Change_Email')
                EmTempPartner=em;
        }
        system.assertNotEquals(EmTempPartner,null);
        
        for(Opportunity opp:opptys){
            opttylist.add(opp.id);
            if(opp.AccountId!=null){
                AccountIdslist.add(opp.AccountId);
            }
            if(opp.Partner_Involved__c!=null){
              partnerInvolvedIds.add(opp.Partner_Involved__c);
            }
        }

        
        //Get all account team member for the opportunity
        //SFDC-2572 - Modified query to add conditions checked in if construct
        
          for(AccountTeamMember ctm:[select id,User.Email,TeamMemberRole,AccountId from AccountTeamMember where AccountId IN :partnerInvolvedIds and User.Isactive=true and TeamMemberRole='Partner'  ])
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
        for(OpportunityTeamMember ctm:[select id,User.Email,TeamMemberRole,OpportunityId from OpportunityTeamMember where OpportunityId IN :opttylist  and User.Isactive=true  and TeamMemberRole='Partner'])
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
        for(Opportunity oppty:opptys){
        
            set<string> partnerEmails = new set<string>();
            // Add all sales team members
            if(oppty.AccountId!=null && AccAccountTeamMap.get(oppty.Partner_Involved__c)!=null)
            {
                for(AccountTeamMember atmSingle:AccAccountTeamMap.get(oppty.Partner_Involved__c))
                {
                  partnerEmails.add(atmSingle.User.Email);
                 }
                
            }
            // add all account team members
            if(OpptySalesTeamMap.get(oppty.id)!=null)
            {
                for(OpportunityTeamMember otmSingle:OpptySalesTeamMap.get(oppty.id))
                {
                  partnerEmails.add(otmSingle.User.Email);
                }
            }
            // add the emails in POA email list
            if(oppty.Partner_Involved__c!=null)
            {
                if(idOpportunityMap.get(oppty.id).Partner_Involved__r.POA_Email_List__c!=null)
                {
                    for(string eml:idOpportunityMap.get(oppty.id).Partner_Involved__r.POA_Email_List__c.replace(' ','').split(','))
                    {
                       partnerEmails.add(eml);
                    }
                }
            }
            // Prepare the Email subject and Body
            // For internal Users

            // For Partner Users
            string partnerSubjectText=EmTempPartner.Subject;
            string partnerBodyText=EmTempPartner.Body;
           // SFDC-9285
           partnerSubjectText = OpportunityTriggerClass.getRebateModifiedText(partnerSubjectText,oppty,false);
           partnerBodyText = OpportunityTriggerClass.getRebateModifiedText(partnerBodyText,oppty, false);
           
           partnerBodyText=partnerBodyText.replace('#opptylink#',PartnerSfURL+'/'+oppty.id); //if partner , show partner friendly link


            string partnerHtmlBodyText=emailHeader+partnerBodyText.replace('\n','<br/>')+'<br/>'+emailfooter;
        
            if(partnerEmails.size()>0)
            {
                for(string emlSingle:partnerEmails)
                    sendEmailList.add(GsmUtilClass.createSingleEmailWithOrgId(emlSingle,'',partnerSubjectText,partnerBodyText,partnerHtmlBodyText,PartnerPortalOrgWideId));
            }

        }
        
        if (sendEmailList.size()>0 )
            Messaging.sendEmail(sendEmailList);
        system.debug('EmailList:'+sendEmailList);
        
        
    }

}