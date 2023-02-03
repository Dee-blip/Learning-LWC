public class viewMyProfilePageCustomController 
{
    public Contact currentContact {get;set;}
    public User currentUser {get;set;}
    public string passwordResetRedirectURL {get;set;}
    public String changePasswordUrl {get;set;}
    public String lunaPortalUrl {get;set;}
    public String mode {get;set;}
    public Boolean isLevel3Partner {get;set;}
    private Set<String> allowedModes;
    private String currentUserId;
    
    public viewMyProfilePageCustomController()
    {
        init();
    }
    
    public void init()
    {
        isLevel3Partner = false;
        allowedModes = new Set<String>();
        allowedModes.add('view');
        allowedModes.add('edit');
        allowedModes.add('change_password');
        currentUserId = UserInfo.getUserId();
        lunaPortalUrl = Util.getLunaPortalUrl();
    	changePasswordUrl = Util.getLunaProfilePageUrl();
        setMode();
        
        for(User usr:[select Id
                            ,TimeZoneSidKey
                            ,LocaleSidKey
                            ,LanguageLocaleKey
                            ,CommunityNickname
                            ,Street
                            ,City
                            ,State
                            ,PostalCode
                            ,Country
                            ,Extension
                            //,StartDay
                            //,EndDay
                            ,Email
                            ,ContactId
                            ,Contact.Name
                            ,Contact.FirstName
                            ,Contact.LastName
                            ,Contact.Title
                            ,Contact.Email
                            ,Contact.Fax
                            ,Contact.Phone
                            ,Contact.MobilePhone
                            ,Contact.AccountId
                            ,Contact.Account.OwnerId
                            ,Contact.Account.AKAM_Account_ID__c
                            ,Contact.Account.Owner.Name
                            from User where id =: currentUserId])
        {
            currentUser = usr;
            currentContact = currentUser.Contact;
        }
        isLevel3Partner = Util.isLevel3Partner(currentContact.Account.AKAM_Account_ID__c);
    }
    
    public PageReference Edit()
    {
        mode = 'edit';
        return null;
    }
    
    public PageReference ChangeMyPassword()
    {
        mode = 'change_password';
        return null;
    }
    
    public PageReference Save()
    {
        try
        {
            update currentUser;
            mode = 'view';
        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.message(ApexPages.severity.ERROR,String.valueOf(e)));
            mode = 'edit';
        }
        
        return null;
    }
    
    public PageReference Cancel()
    {
        mode = 'view';
        return null;
    }
    
    private void setMode()
    {
        String pMode = ApexPages.currentPage().getParameters().get('mode');
        pMode = String.isBlank(pMode) ? '' : pMode.toLowerCase();
        this.mode = allowedModes.contains(pMode) ? pMode : 'view';
    }
}