global class PartnerPortalWelcomeCustom 
{
    public string displayDetails {get;set;}
    private Contact currentContact {get;set;}
    private string currentUserId {get;set;}
    private Map<String,String> detailsMap;
    
    public PartnerPortalWelcomeCustom()
    {
        init();
    }
    
    public void init()
    {
        currentUserId=UserInfo.getUserId();
        System.debug('Echo: currentUserId: '+currentUserId);
        displayDetails = '';
        
        for(Contact c:[select Id, AccountId, Account.Owner.Name,Account.Owner.Email, FirstName, LastName, Name from Contact where Partner_User__c = :currentUserId])
        {
            currentContact = c;
        }
        
        if(currentContact != null)
        {
            populateDetails();
        }
    }
    
    /*
    	Populate the following:
    		-	Conract Name
    		-	My Company Profile Link
    		-	My Profile Link
    		-	Channel Manager Name
    		-	Channel Manager Email
    */
    private void populateDetails(){
    	detailsMap = new Map<String,String>();
    	String myCompanyProfileLink = '/' + currentContact.AccountId + '';
    	String myProfileLink = Util.isLunaConnectionActive() ? '/apex/viewMyProfilePageCustom' : '/_ui/core/portal/PortalUserMyProfilePage/d';
    	
    	detailsMap.put('contactName',currentContact.Name);
    	detailsMap.put('myCompanyProfileLink',myCompanyProfileLink);
    	detailsMap.put('myProfileLink',myProfileLink);
    	detailsMap.put('channelManagerName',currentContact.Account.Owner.Name);
    	detailsMap.put('channelManagerEmail',currentContact.Account.Owner.Email);
    	
    	displayDetails = Util.convertMapToJson(detailsMap);
    }
}