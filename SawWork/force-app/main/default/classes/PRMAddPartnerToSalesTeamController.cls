/**
  PRMAddPartnerToSalesTeamController
    @author : Vinayendra T N <vintara@akamai.com>
    @Description : This is the controller class for the PRMAddPartnerToSalesTeam.
    This class is used in process for Channel manager to add a Partner to sales team and send a email.
    @History
    --Developer           --Date            --Change
    Vinayendra T N       3/2011             Created the class for management of PRM
                                            CR 1085835 PRM: Create proces that will allow an MAE/PAE to add a parnter contact to an oppty sales team
                          
                                            - Created the VF page so that PAE select a partner , the partner is added to sales team. The page is redirected to OOTB page to send email
    Ruchika Sharma       25/05/2015         CR 2994275 : Opty -- Add Partner Contact unfriendly error message
 */
 global class PRMAddPartnerToSalesTeamController {
    public Opportunity opp {get;set;} 
    public Boolean HasError {get;set;} 
    public list<User> userlist {get;set;}
    public string pid{get;set;}
    private PageReference pRef;
    public PRMAddPartnerToSalesTeamController(ApexPages.StandardController controller) {
        this.opp = (opportunity)controller.getRecord();
        HasError=false;
        opp = getOpportunity(opp.id);
        if(opp.Partner_Involved__c==null)
        {
           ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Partner Involved Cannot be Null'));
           HasError=true;
        }
        else
            init();
    }

    public void init()
    {
        //pid=null;
        //Get all roles for the particular Partner involved
        //list<UserRole> UserRoles = [select id from UserRole where PortalAccountId=:opp.Partner_Involved__c];
        //get all users,contacts for that particualr partner which has the roles

        list<id> salesteamlist = getSalesTeamList(opp.Id, opp.OwnerId);
        userlist = getUserList(salesteamlist,opp.Partner_Involved__c ,opp.Partner_Involved__r.ParentId );

        //show all users and let them select the user 
        //CR 2994275 : Opty -- Add Partner Contact unfriendly error message - Start of change
        if(userlist.size()==0)
        {
            //put error in label
            if(salesteamlist.size()!=1)
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, System.Label.PRM_OpportunityTeamMember_AddPartnerContact));
            else
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No partner users found.'));
           HasError=true;
        }
        //CR 2994275 : Opty -- Add Partner Contact unfriendly error message - End of Change
        
       
    }

    // Added for MOB-361 : Refactoring to have queries in Separate methods to support Mobile Backend
    public PRMAddPartnerToSalesTeamController()
    {

    }

    public Opportunity getOpportunity(String oppid)
    {
         return [select id,Name,Partner_Involved__c,Partner_Involved__r.ParentId,OwnerId from Opportunity where id=:oppid][0];
    }

    public List<Id> getSalesTeamList(Id oppId, Id ownerId)
    {
        list<id> salesteamlist =new list<id>();
        salesteamlist.add(ownerId);

        for(OpportunityTeamMember ctm:[select UserId from OpportunityTeamMember where OpportunityId=:oppId and TeamMemberRole='Partner'])
            salesteamlist.add(ctm.UserId);
        return salesteamlist;
    }

    public List<User> getUserList(List<Id> salesteamlist,Id partnerInvolvedId, Id partnerInvolvedParentId)
    {
        List<User> uList = [select id,Name,ContactId,UserRole.Name 
                        from User 
                        where 
                             (contact.AccountId=:partnerInvolvedId 
                              OR
                              contact.AccountId=:partnerInvolvedParentId
                             )
                        and contactId!=null
                        and contact.AccountId!=null
                        and id NOT IN :salesteamlist and IsActive=TRUE];
        return uList;
    }
    public static OpportunityTeamMember getOppTeamMember(Id oppId, Id userId)
    {
        OpportunityTeamMember member = new OpportunityTeamMember();
        member.OpportunityId = oppId;
        member.UserId = userId;
        member.TeamMemberRole = 'Partner';
        return member;
    }
    // End MOB-361

    public pageReference setvalue()
    {
        pid=ApexPages.currentPage().getParameters().get('pid');
        return null;
    }

    //Update Opportunity share table.
    public Static OpportunityShare opptyUpdateShareTable(Id p_opp_id, Id p_user_Id,String p_access)
    {
        OpportunityShare oppsh = null;
        for(OpportunityShare oppshare:[select id,OpportunityAccessLevel,UserOrGroupId from OpportunityShare where OpportunityId=:p_opp_id and UserOrGroupId=:p_user_Id])
            oppsh=oppshare;
        if(oppsh!=null)
            oppsh.OpportunityAccessLevel=p_access;
        return oppsh;
    }
    public Integer CreateTeamMember()
    {
        //pid=ApexPages.currentPage().getParameters().get('pid');
        if(pid==null || pid=='')
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select atleast one partner user'));
            return 1;
        }

        OpportunityTeamMember member = getOppTeamMember(opp.id,pid);

        try
        {
            insert member;  
        }
        catch (Exception e)
        {
            if(e.getMessage().contains('INACTIVE_OWNER_OR_USER'))
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'User cannot be added to the Sales team as Owner of the Opportunity is Inactive'));
            else if(e.getMessage().contains('DUPLICATE_VALUE'))
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'This User already exists in the Sales Team'));
            }
            else
            {
                pRef = SiteLoginController.exceptionNotification(ApexPages.currentPage(),e);
            }
            return 1;
        }
        OpportunityShare oppshare=null;
        oppshare=opptyUpdateShareTable(opp.id,pid,'Edit');
        if(oppshare!=null)
        {
            try
            {
                update oppshare;     
            }
             catch(Exception e)
             {
                pRef = SiteLoginController.exceptionNotification(ApexPages.currentPage(),e);
             }
         }
        return 0;
    }
    global PageReference AddUserAndSendEmail() 
    {
        if(CreateTeamMember()==1)
        return null;
         User usr=[select id,contactid from User where id=:pid];
         //on submit add the partner to sales team and then redirect to send email page with contact as parameter and send =1 , return is opportunity 
        return new PageReference('/_ui/core/email/author/EmailAuthor?rtype=003&p2_lkid='+usr.contactid+'&p3_lkid='+opp.id+'&retURL=/'+opp.id+'&template_id='+GsmUtilClass.getGSMSettingValue('PRMAddPartnerToSalesTeam_template'));

    }
    public PageReference AddUser() 
    {
        if(CreateTeamMember()==1)
        return null;
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'User Succesfully added to sales team.'));
          HasError=true;
        return null;
    }
    public PageReference cancel() {
      PageReference rPage = new PageReference('/'+opp.id);
      rPage.setRedirect(true);
      return rPage;
    }
}