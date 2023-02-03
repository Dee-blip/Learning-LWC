public class TSSupportSingleTeamExtension {

 
    public String teamId {get; set;}
    public List<TS_TeamMember__c> userList {get; set;}
    public List<TS_TeamAccount__c> accountList {get;set;}
    public TS_Support_Team__c teamObj;
    public String toBeDelMember {get; set;}
    public String toBeDelAcc {get; set;}
    public List<TS_Support_Team__c> selectedTeamObjList {get; set;}

    public TSSupportSingleTeamExtension(ApexPages.StandardController controller) {
        teamId = ApexPages.currentPage().getParameters().get('teamId');
        selectedTeamObjList = [SELECT Team_Name__c,Team_Type__c,VDN__c,LastModifiedBy.Name,LastModifiedDate from TS_Support_Team__c where Id =:teamId];
        getTeamMembers();
        getTeamAccounts();
    }

    public PageReference newTeam()
    {
        PageReference ref = new PageReference('/apex/TSSupportTeamCreate');
        return ref;
    }
    
    public void getTeamMembers() {
        teamId = ApexPages.currentPage().getParameters().get('teamId');
        userList = [SELECT Team_Member__c, Role__c, Team_Member__r.alias, Team_Member__r.FirstName, Team_Member__r.LastName from TS_TeamMember__c where TS_Support_Team__r.Id =: teamId];        
    }
    
    public void getTeamAccounts() {
        teamId = ApexPages.currentPage().getParameters().get('teamId');
        accountList = [SELECT Team_Account__c, Team_Account__r.Name, Team_Account__r.Id, Team_Account__r.AKAM_Account_ID__c, Team_Account__r.Support_Level__c, Team_Account__r.Customer_Tier__c, 
                        Team_Account__r.Geography_Formula__c, Team_Account__r.ERC_Numeric__c from TS_TeamAccount__c where TS_Support_Team__r.Id =: teamId];  
    }
    
    public TS_Support_Team__c getSupportTeam() {
        teamObj = [SELECT Name from TS_Support_Team__c where Id =:teamId];
        return teamObj;
    }
    
    public PageReference newMember()
    {
        TS_Support_Team__c obj = getSupportTeam();         
        PageReference ref = new PageReference('/apex/TSTeamMemberCreate');
        ref.getParameters().put('teamid', teamId);
        return ref;
    }
    
    public PageReference newAccount()
    {
        TS_Support_Team__c obj = getSupportTeam();         
        PageReference ref = new PageReference('/apex/TSTeamAccountCreate');
        ref.getParameters().put('teamid', teamId);
        return ref;
    }
    
    public void deleteMember(){
        List<TS_TeamMember__c> tempUserList;
        tempUserList = [Select id,Name from TS_TeamMember__c where id =: toBeDelMember];
        if(tempUserList.size() > 0 || tempUserList[0].Id != '')
        {
            delete tempUserList;
        }
        userList = [SELECT Team_Member__c, Role__c, Team_Member__r.alias, Team_Member__r.FirstName, Team_Member__r.LastName from TS_TeamMember__c where TS_Support_Team__r.Id =: teamId];        
   }
   
   public void deleteAcc(){
        List<TS_TeamAccount__c> accList;
        accList = [Select id,Name from TS_TeamAccount__c where id =: toBeDelAcc];
        if(accList.size() > 0 || accList[0].Id != '')
        {
            delete accList;
        }
        accountList = [SELECT Team_Account__c, Team_Account__r.Name, Team_Account__r.Id, Team_Account__r.AKAM_Account_ID__c, Team_Account__r.Support_Level__c, Team_Account__r.Customer_Tier__c, 
                        Team_Account__r.Geography_Formula__c, Team_Account__r.ERC_Numeric__c from TS_TeamAccount__c where TS_Support_Team__r.Id =: teamId];
   }

}