//CR 2839539 - Ruchika Sharma PRM: Moving a partner from one profile/role to another profile/role in a user friendly manner
//CR 2884323 -- Akamai University Tab visiblity to follow permission set
//Ruchika Sharma   25/01/2016  CR 3379911 SFDC-837: Partner Concierge -- Integrate Zift platform with Akamai SFDC
public class PartnerAccessController {
  
      public String contactId{get;set;}
      public User partnerUser{get;set;}
      public Boolean isViewMode{get;set;}
      public Boolean isSRAPartner{get;set;}
      public Contact partnerCon{get;set;}
      private PageReference pageRef;
      public Boolean hasAUAccess{get;set;}

      //CR 2839539: rsharma - added more fields to show role and profile on DefinePartnerAccess page
      public Map<id,UserRole> Roles ;
      public Transient Map<id,Profile> ProfileList ;
      public Boolean NoRolesFound {get;set;}
      public String BUOpt{get;set;}
      public String BUOptProfile{get;set;}
      public Boolean isAccountConcierge{get;set;}
 
      public PartnerAccessController()
      {
      //SFDC-837
      isAccountConcierge = false;
      try {
      init();
      } catch(Exception e) {
        pageRef = SiteLoginController.exceptionNotification(ApexPages.currentPage(),e);
      }

      }

      public static Boolean isLiteLicenseSufficient(User pUser)
      {
      for(String fieldName : PRM_Settings__c.getInstance('NonLitePermissionSets').Value__c.split(','))
      {
         if(pUser.get(fieldName.trim())==true)
             return false;
      }
      return true;
      }

      public static void populateProfile(User pUser)
      {
      // if Admin is selected, retain it
      // else if lite is sufficient then assign lite
      // else assign partner comm user

      if(!String.valueOf(pUser.ProfileId).contains(PRM_Settings__c.getInstance('Partner Admin Id').Value__c))
      {
        if(isLiteLicenseSufficient(pUser))
        {
            pUser.ProfileId = PRM_Settings__c.getInstance('PartnerCommunityLiteProfileId').Value__c;
            // This is in Update access case
            if(pUser.Profile!=null)
                pUser.Profile.Name = 'Partner Community Lite';

        }
        else
        {
            pUser.ProfileId = PRM_Settings__c.getInstance('Partner User ID').Value__c;
            if(pUser.Profile!=null)
            pUser.Profile.Name = 'Partner Community User';
        }
      }
      }

      public static void populateLeadAccess(User pUser) {
          if (pUser.Has_MDF_Access__c || pUser.Has_PartnerPlans_Access__c || 
                pUser.Has_DealRegistration_Access__c || pUser.Has_PartnerCertification_Access__c ||
                pUser.Has_view_content_in_portals__c || pUser.Has_Partner_Concierge_Access__c || 
                pUser.Has_Start_Trial_Access__c || pUser.Has_View_Trial_Access__c) {

            pUser.Has_Partner_Lead_View_Access__c = true;
          } else {
            pUser.Has_Partner_Lead_View_Access__c = false;
          }

      }

      //CR 2839539: rsharma- added method to retrieve partner profiles. - start
      public void setProfiles(){

            string query='';
            string profilesToBeExcluded = PRM_Settings__c.getInstance('Default Partner Profile').Value__c;
            query='select id,Name from Profile where UserType = \'PowerPartner\' ORDER BY Name';
            if(!Userinfo.getProfileId().contains(PRM_Settings__c.getInstance('Partner Support Profile Id').Value__c))
                  query+=' DESC';
            else
                  query+=' ASC';
            ProfileList = new Map<id,Profile>();
            for(Profile pr: Database.query(query))
                  if(!pr.Name.contains('DoNotUse') && !profilesToBeExcluded.contains(pr.Name))
                  ProfileList.put(pr.id,pr);
      }
      //CR 2839539: End

      public void init()
      {
            contactId=ApexPages.currentPage().getParameters().get('id');
            isSRAPartner=false;
            //CR 2839539: rsharma- added variables for profile and role and account (to retreive roles for this account) - start
            NoRolesFound=false;
            Roles= new Map<id,UserRole>();
            ProfileList = new Map<id,Profile>();
            string accid;
            //CR 2839539: End
            if(contactId!=null)
            {
            //CR 2839539: rsharma- Modified query to retrieve extra fields
            partnerUser=[select Id
                             ,can_Accept_POA__c
                             ,ProfileId
                             ,Has_Partner_Lead_Access__c
                             ,Has_Partner_Lead_View_Access__c
                             ,UserRoleId
                             ,IsActive
                             ,UserRole.Name
                             ,Profile.Name
                             ,Has_MDF_Access__c
                             ,Has_PartnerPlans_Access__c
                             ,Has_DealRegistration_Access__c
                             ,Has_Portal_Tableau_Access__c
                             ,Has_PartnerCertification_Access__c
                             ,View_Pricing_Details__c
                     ,Has_view_content_in_portals__c,
                              Has_Partner_Concierge_Access__c ,
                              Has_Start_Trial_Access__c,
                              Has_View_Trial_Access__c
                          from User
                          where contactId =:contactId];
                          //SFDC-837
            if(partnerUser==null)
            {
            throw new customException('There is no user associated with contact.');
            }
            //CR 2839539: rsharma- Modified query to retrieve account id also
            partnerCon=[select Id,Account.Partner_Type__c,Has_Akamai_University_Access__c,Account.AKAM_Account_Id__c,Account.id,Account.Partner_Concierge_Access__c  from contact where id=:contactId]  ;

            //CR 2839539: rsharma- added null check
            if(PartnerCon!=null )
            {
            //CR 2839539: rsharma- getting current partner account id
             accid=partnerCon.Account.id;
            if(partnerCon.Account.Partner_Type__c =='SRA Partner')
            {
              isSRAPartner=true;
            }
            //CR 2839539: rsharma- calling method to set profiles
            setProfiles();

            hasAUAccess=partnerCon.Has_Akamai_University_Access__c;
            //CR 2839539: rsharma- added below code to query roles based on account id - start
            string query='';
            query='select id,Name from UserRole where PortalAccountId=:accid ORDER BY Name';
            if(!Userinfo.getProfileId().contains(PRM_Settings__c.getInstance('Partner Support Profile Id').Value__c))
               query+=' DESC';
            else{
               query+=' ASC';
             }
            for(UserRole usrrole: Database.query(query))
              Roles.put(usrrole.id,usrrole);
            if(partnerCon.Account.Partner_Concierge_Access__c){
              isAccountConcierge = true;
            }
            }
            //CR 2839539: End
            }

            isViewMode=true;

            //CR 2839539: rsharma - checking roles so as to set NoRolesFound to true
            if(Roles.size()==0)
              NoRolesFound=true;
      }

      //CR 2839539: rsharma - added below method to get list of roles in SelectOptions form

      public List<SelectOption> getBUOptions() 
      {
        List<SelectOption> options = new List<SelectOption>();
        
        //first add current partner user role id in pick list
        if(partnerUser!=null && Roles.containsKey(partnerUser.UserRoleId) ){
           options.add(new SelectOption(partnerUser.UserRoleId,Roles.get(partnerUser.UserRoleId).Name));        
          }
            for(Id rol : Roles.keySet())
            {
                //Add other user roles (roles other than current user role)
                if(partnerUser!=null && partnerUser.UserRoleId!=rol){
                    options.add(new SelectOption(rol,Roles.get(rol).Name));        
                }
                
            }
        return options;
      }
      //CR 2839539: End of Method

      //CR 2839539: rsharma - added below method to get list of Profiles in SelectOptions form
      public List<SelectOption> getBUOptionsProfile() 
      { 
        if(ProfileList==null||ProfileList.isEmpty())
          setProfiles();
        List<SelectOption> options = new List<SelectOption>();
        //below code is written to show that the found users role at top 
       // Rahul Gaira      12/12/2014  CR 2866701 PRM: Channel -- Level 3 Prohibited Account Custom Setting
         //                       -> Level3PartnerAccountAKAMId Custom Label is moved to the GSM Custom Setting
       if(GsmUtilClass.GetCustomSettingValue('Level3PartnerAccountAKAMId').contains(PartnerCon.Account.AKAM_Account_Id__c))
        {
         //End of CR 2866701 changes 
      //if(Label.Level3PartnerAccountAKAMId.contains(PartnerCon.Account.AKAM_Account_Id__c))
       
            for(Id pro : ProfileList.keySet())
            {
                if(!ProfileList.get(pro).Name.contains('Admin') )
                { options.add(new SelectOption(pro,ProfileList.get(pro).Name));        
                }
            }
        }
        else
        {

        //ensure that the current profile of user comes on top
        if(ProfileList.containsKey(partnerUser.ProfileId) ){
              options.add(new SelectOption(partnerUser.ProfileId,ProfileList.get(partnerUser.ProfileId).Name));   
            }
        for(Id pro : ProfileList.keySet())
        {            
         if(partnerUser.ProfileId!=pro ){
            options.add(new SelectOption(pro,ProfileList.get(pro).Name));
           }
          
        }
      }
        return options;
      }
      //CR 2839539: End of Method

       public PageReference exceptionCheck() {
                return pageRef;
       }
 
      public PageReference updateContact()
      {
            if(partnerCon.Has_Akamai_University_Access__c!=hasAUAccess)
            {  
                  try
                  {
                        partnerCon.Validation_Override__c=true;
                        update partnerCon;
         
                  } catch(Exception e) {
                        Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'There are problems while executing your request. Error Message :'+e.getMessage()));
                        return SiteLoginController.exceptionNotification(ApexPages.currentPage(),e);
                  }
            }
            isViewMode=true;
            return null;
      }
  
      public PageReference updateAccess()
      {
            try
            {
                  //CR 2839539: rsharma - added selected role to PartnerUser
                  if(BUOpt!=null){
                        partnerUser.UserRoleId=BUOpt;
                        partnerUser.UserRole.Name = Roles.get(BUOpt).Name;
                  }
          
                  //CR 2839539: rsharma - added selected profile to PartnerUser
                  if(BUOptProfile!=null){
                        partnerUser.ProfileId = BUOptProfile;
                        partnerUser.Profile.Name = ProfileList.get(BUOptProfile).Name;
                  }
          

                  populateProfile(partnerUser);
                  populateLeadAccess(partnerUser);
                  update partnerUser;
                  updateRemoveUserPermissionSet(partnerUser,partnerCon);
            }
            catch(Exception e)
            {
                  Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'There are problems while executing your request. Error Message :'+e.getMessage()));
                  return SiteLoginController.exceptionNotification(ApexPages.currentPage(),e);
            }
            return null;
      }
 
      public PageReference edit()
      {
            isViewMode=false;
            return null;
      }
 
      public PageReference cancel()
      {
            PageReference pageref=null;
            if(isViewMode)
            {
                  pageref=new PageReference('/'+contactId);
            }
            else
            {
                isViewMode=true;
            }
  
            return pageref;
      }
 
      public static void updateRemoveUserPermissionSet(User user, Contact partCon)
      {
        Map<String, String> fieldApiToCustomMetadataDeveloperName = new Map<String, String>{ 
            'Has_MDF_Access__c' => 'MDFAccess',
                'Has_DealRegistration_Access__c' => 'DealRegAccess',
                'Has_Partner_Lead_Access__c' => 'PartnerLeadAccess',
                'Has_Start_Trial_Access__c' => 'StartTrialAccess',
                'Has_View_Trial_Access__c' => 'ViewTrialAccess',
                'Has_Partner_Lead_View_Access__c' => 'PartnerLeadViewAccess',
                'Has_PartnerPlans_Access__c' => 'PartnerPlanAccess',
                'Has_Akamai_University_Access__c' => 'AUAccess',
                'Has_view_content_in_portals__c' => 'viewContentInPortals',
                'Can_Accept_POA__c' => 'POAAccess',
                'Has_PartnerCertification_Access__c' => 'PartnerCertAccess',
                'View_Pricing_Details__c' => 'PricingAccess',
                'Has_Partner_Concierge_Access__c' => 'Partner_Concierge_Access'};

        Set<Id> existingAssignments = new Set<Id>();
        Map<Id, PermissionSetAssignment> psaMap = new Map<Id, PermissionSetAssignment>();
        for(PermissionSetAssignment psa : [select id, AssigneeId, PermissionSetId from PermissionSetAssignment where AssigneeId=:user.Id])
        {
            existingAssignments.add(psa.PermissionSetId);
            psaMap.put(psa.PermissionSetId, psa);
        }

        List<PermissionSetAssignment> permissionsToBeAdded=new List<PermissionSetAssignment>();
        List<PermissionSetAssignment> permissionsToBeDeleted=new List<PermissionSetAssignment>();
        Set<String> userFields = Schema.SObjectType.User.fields.getMap().keySet();

        for(String fieldApiName : fieldApiToCustomMetadataDeveloperName.keySet())
        {
            String pSetID = NAPSettings.getValue('PartnerAccess_'+ fieldApiToCustomMetadataDeveloperName.get(fieldApiName));
            PermissionSetAssignment perm=new PermissionSetAssignment(AssigneeId=user.Id,PermissionSetId=pSetID);


            Boolean isUserFieldSet = userFields.contains(fieldApiName.toLowerCase()) && (user.get(fieldApiName)==true);
            Boolean isContactFieldSet = !userFields.contains(fieldApiName.toLowerCase()) && (partCon.get(fieldApiName)==true);
            Boolean isFieldSet = (isUserFieldSet || isContactFieldSet) ;


            if(!existingAssignments.contains(pSetID) && isFieldSet)
            {
                permissionsToBeAdded.add(perm);
            }
            else if(existingAssignments.contains(pSetID) && !isFieldSet)
            {
                permissionsToBeDeleted.add(psaMap.get(pSetID));
            }
        }
        if(permissionsToBeAdded.size()>0)
            insert permissionsToBeAdded;

        if(permissionsToBeDeleted.size()>0)
            delete permissionsToBeDeleted;
    }

 
}