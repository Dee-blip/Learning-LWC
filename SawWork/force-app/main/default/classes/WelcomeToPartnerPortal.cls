global class WelcomeToPartnerPortal
{
    public Contact currentContact{get;set;}
    private string currentUserId {get;set;}
    public String myProfileLink{get;set;}
    public String myCompanyProfileLink{get;set;}
    
    public WelcomeToPartnerPortal()
    {
        init();
    }
    
    public void init()
    {
        currentUserId=UserInfo.getUserId();
        for(Contact c:[select Id, AccountId,Account.OwnerId, Account.Owner.Name,Account.Owner.Email, FirstName, LastName, Name from Contact where Partner_User__c = :currentUserId])
        {
            currentContact = c;
        }
        
        if(currentContact != null)
        {
            populateDetails();
        }
    }
    
    
    private void populateDetails(){
       
        if(Util.isLunaConnectionActive()){
           myProfileLink = 'apex/viewMyProfilePageCustom';
        }
        else{ 
        myProfileLink = '_ui/core/portal/PortalUserMyProfilePage/d';
        }
        
    }
}