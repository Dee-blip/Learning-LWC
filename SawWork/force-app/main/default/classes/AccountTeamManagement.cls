/***
    AccountTeamManagement
    @author : Vinayendra T N <vintara@akamai.com>
    @Description : This is the Custom Controller for the Account Team Management Page
            
    @History
    --Developer           --Date            --Change
    Vinayendra T N       03/10/2010         Created this clas.
                                            CR 795063 Account Team Management Page
                                            1. The page shall display a list containing the following columns (Account
                                                Name, Account Id, Role Type).
                                            2. The data shall be constrained to only those accounts which the logged in
                                               user is a member of.
                                            3. Each row shall have a delete checkbox to allow multiple rows to be deleted
                                                at once.
                                            4. Team role is made editable also
                                            5. AccountTeamManagementWrapper is added is help updation of team role or
                                               deletion of account team member
                                            6. Account Access and opportunity access also added. Small bug fixed.
                                            7. Added Account Owner column and PDRA information.

*/

global class AccountTeamManagement
{   
    public List<AccountTeamManagementWrapper> AccTMember {get;set;}
    private List<AccountTeamMember> DelList ;
    private List<AccountTeamMember> SaveList ;
    public string value {get;set;}
    public AccountTeamManagement () 
    {    
        init();
    }    

    
    // Initialize and get the accountTeamMember data of the user
    public void init()
    {
        value='';
        AccTMember = new List<AccountTeamManagementWrapper>();
        List<AccountTeamMember> atmList = [select TeamMemberRole, Id,Account.OwnerId,Account.Name ,Account.AKAM_Account_ID__c, Account.Id,UserId,Account.Owner.Name,Account.Region__c, Account.Parent_Division__c, Account.Division__c, Account.Area__c From AccountTeamMember where UserId = :UserInfo.getUserId() limit 999];
        Map<Id, AccountShare> accShareMap = new Map<Id, AccountShare>();
        for(AccountShare accShare : [select AccountAccessLevel,OpportunityAccessLevel,AccountId from AccountShare where UserOrGroupId = :UserInfo.getUserId()])
            accShareMap.put(accShare.AccountId, accShare);
        AccountShare asn;
        Schema.DescribeFieldResult fieldResult = AccountTeamMember.TeamMemberRole.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        List<String> pickval = new List<String>();
        for(Schema.PicklistEntry p : ple)
        {
            pickval.add(p.getValue());      
        }
        for(AccountTeamMember atm : atmList) 
        {
            AccountTeamManagementWrapper pw;
            asn = accShareMap.get(atm.Account.Id);          
            if(asn == null)
            {// if Account Share is not available then pass only Account Team Member to wrapper
                pw = new AccountTeamManagementWrapper(atm,pickval);
            }
            else // Pass both Account Team and account share.       
                pw = new AccountTeamManagementWrapper(atm,asn,pickval);
            AccTMember.add(pw);
        }
        if(AccTMember.size()==0)
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You are not part of any account Teams'));
    
    }
    // Call this function when the delete  button is click and delete the user from the account team
    global Pagereference deleteAcc()
    {
        DelList= new List<AccountTeamMember>();
        value='Loading Please Wait...';
        for(AccountTeamManagementWrapper atm : AccTMember)
        {    
            //when checkbox is ticked the checked gets updated to true
            if(atm.checked)
            {    
                //Add it to the Dellist list for deletion            
                DelList.add(atm.a);
            }
        }
        try{
        if(DelList.size() > 0)
            delete DelList;   
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, value));
        }
        catch (exception ex)
        {
            throw new CustomException('There is some problem with deletion. Please contact system admin . Error Details : '+ex);       
        } 
        return null;
    }
    // This founction is used to save the account Team Member`s role
    global Pagereference saveAcc()
    {
        SaveList= new List<AccountTeamMember>();
        value='';
        for(AccountTeamManagementWrapper atm : AccTMember)
        {   //Check is the string saved and the original value of the TeamMemberRole is same
            if(atm.a.TeamMemberRole!=atm.BUOpt)
            {
                atm.a.TeamMemberRole=atm.BUOpt;
                SaveList.add(atm.a);
                
            }
        }
        try{
        if(SaveList.size() > 0)
            {
                update SaveList;   
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Successfully updated '+SaveList.size()+' record(s)'));
            }
            else
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'No records were updated'));
        }
        catch (exception ex)
        {
            throw new CustomException('There is some problem with Updation. Please contact system admin . Error Details : '+ex);
        } 
        return null;
    }
    /* Commenting out the following lines as its not needed anymore
    public static void LogInfo(string url,string AccType,string Lead_Oppty,id Leadid,id Opptyid)
	{
			LeadOpptyLog__c log=new LeadOpptyLog__c();
			Log.Access_Type__c=AccType;
			log.URL__c=url;
			log.Lead_Oppty__c=Lead_Oppty;
			if(Leadid!=null)
			log.Lead__c=Leadid;
			if(Opptyid!=null)
			log.Opportunity__c=Opptyid;
			log.User__c=Userinfo.getUserId();
			insert log;
			
	}
	WebService static void LoggingData(String Pageurl)
    { 
        string leftUrl;
        string rightUrl=null;
        if(Pageurl.contains('?'))
        {
            List<String> FullUrlparts = Pageurl.split('\\?');
            leftUrl=FullUrlparts[0];
            rightUrl=FullUrlparts[1];
        }
        else
            leftUrl=Pageurl;
        list<string> strlist=new list<string>();
        List<String> parts = leftUrl.split('/');
        //check for the id
        if(parts.size()>3)
        {
            //If its a record id 
            if(parts[3].length()==15 || parts[3].length()==18)
            {
               if(parts[3].substring(0,3)=='006')
               {
               	 LogInfo(Pageurl,'View Page','Oppty',null,parts[3]);
               }
               if(parts[3].substring(0,3)=='00Q')
               {
               	 LogInfo(Pageurl,'View Page','Lead',parts[3],null);
               }
            }
            if(parts[3].length()==3)
            {
            	if(parts[3]=='006')
            	{
            	  LogInfo(Pageurl,'List Page','Oppty',null,null);
            	}
            	if(parts[3]=='00Q')
            	{
            	  LogInfo(Pageurl,'List Page','Lead',null,null);
            	}
            }
        }
        if(leftUrl.contains('/apex/leadView'))
        {
        	if(rightUrl!=null)
        	{
        		//if(rightUrl.contains('00Q'))
        		//LogInfo(Pageurl,'View Page','Lead',null,null);
        		
        		List<String> Rightparts = rightUrl.split('&');
        		for(string str:Rightparts)
        		{
        			if(str.contains('id='))
        			{
        				list<string> RightPartsIdParts= str.split('id=');
        				if(RightPartsIdParts[1]!=null && RightPartsIdParts[1].length()>3 && RightPartsIdParts[1].substring(0,3)=='00Q')
        				{
        					LogInfo(Pageurl,'View Page','Lead',RightPartsIdParts[1],null);
        				}
        			}
        		}
        	}
        }
    }
    */
    
}