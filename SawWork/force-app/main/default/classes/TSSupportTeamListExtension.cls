public class TSSupportTeamListExtension {
    public String teamId {get; set;}
    public String teamName {get; set;}
    public List<TS_TeamMember__c> userList {get; set;}
    public List<TS_TeamAccount__c> accountList {get;set;}
    public TS_Support_Team__c teamObj;
    public String toBeDelMember {get; set;}
    public String toBeDelAcc {get; set;}
    public List<TS_Support_Team__c> selectedTeamObjList {get; set;}
    public List<TS_Support_Team__c> teams {get; set;}
    public Map<String, String> teamAccountMap {get; set;}
    public TS_TeamMember__c teamMemberObj;

    public TSSupportTeamListExtension(ApexPages.StandardSetController controller) {
        controller.setPageSize(controller.getResultSize());
        teamAccountMap = new Map<String, String>();
        teams = [Select Name, Id, Team_Name__c, Team_Type__c, VDN__c, Akam_Row_ID__c, No_of_Accounts__c, LastModifiedBy.Name, LastModifiedDate from TS_Support_Team__c order by LastModifiedDate DESC];
        List<AggregateResult> teamAccList = [SELECT count(Team_Account__c) noAcc, TS_Support_Team__r.Id teamId from TS_TeamAccount__c group by TS_Support_Team__r.Id];
        if(teamAccList != null && teamAccList.size()>0){
            for(AggregateResult teamAccObj : teamAccList){
                teamAccountMap.put((String)teamAccObj.get('teamId'),teamAccObj.get('noAcc')+'');
            }
        }
        for(TS_Support_Team__c supportTeam : teams){
            String noOfAccs = 0+'';
            if(teamAccountMap.get(supportTeam.Id)==null){
                teamAccountMap.put(supportTeam.Id, noOfAccs);
            }
        }
    }

    public TSSupportTeamListExtension(ApexPages.StandardController controller) {
        /*if(teamListObject == null) {
            teamListObject = new ApexPages.StandardSetController(getSupportTeamsList());
            teamList = teamListObject.getRecords();
            //teamListObject.setPageSize(teamListObject.getResultSize());
        }*/
    }

    public PageReference refresh(){
        PageReference pageRef = new PageReference(getURL());
        pageRef.setRedirect(true);
        return pageRef;
    }

    public String getURL() {
        String URL = ApexPages.CurrentPage().GetURL();
        return URL.substring(0,URL.indexOf('?'));
    }

    public PageReference newTeam()
    {
        PageReference ref = new PageReference('/apex/TSSupportTeamCreate');
        return ref;
    }

    public void getTeamMembersAndAccounts(){
        if(teamId==null){
            return;
        }
        List<TeamMemberWrapper> memberWrapperList = new List<TeamMemberWrapper>();
        userList = [SELECT Team_Member__c, Role__c, Team_Member__r.alias, Team_Member__r.FirstName, Team_Member__r.LastName from TS_TeamMember__c where TS_Support_Team__r.Id =: teamId order by Role__c DESC];
        for(TS_TeamMember__c teamMemberObj : userList){
            memberWrapperList.add(new TeamMemberWrapper(teamMemberObj));
        }
        memberWrapperList.sort();
        userList.clear();
        for(TeamMemberWrapper teamMembrWrapper : memberWrapperList){
            userList.add(teamMembrWrapper.teamMember);
        }
        accountList = [SELECT Team_Account__c, Team_Account__r.Name, Team_Account__r.Id, Team_Account__r.AKAM_Account_ID__c, Team_Account__r.Support_Level__c, Team_Account__r.Customer_Tier__c,
                        Team_Account__r.Geography_Formula__c, Team_Account__r.ERC_Numeric__c from TS_TeamAccount__c where TS_Support_Team__r.Id =: teamId order by Team_Account__r.Name];
    }

    public class TeamMemberWrapper implements Comparable {

        public TS_TeamMember__c teamMember = new TS_TeamMember__c();

        public TeamMemberWrapper(TS_TeamMember__c teamMemberRecord) {
            teamMember = teamMemberRecord;
        }

        public Integer compareTo(Object compareTo) {
            TeamMemberWrapper compareToTeamMember = (TeamMemberWrapper)compareTo;
            Integer returnValue = 0;
            if (teamMember.Role__c < compareToTeamMember.teamMember.Role__c) {
                returnValue = 1;
            } else if (teamMember.Role__c > compareToTeamMember.teamMember.Role__c) {
                returnValue = -1;
            }
            return returnValue;
        }
    }

    public void getTeamMembers() {
        userList = [SELECT Team_Member__c, Role__c, Team_Member__r.alias, Team_Member__r.FirstName, Team_Member__r.LastName from TS_TeamMember__c where TS_Support_Team__r.Id =: teamId order by Role__c DESC];
    }

    public void updateTeamMembers() {
        userList = [SELECT Team_Member__c, Role__c, Team_Member__r.alias, Team_Member__r.FirstName, Team_Member__r.LastName from TS_TeamMember__c where TS_Support_Team__r.Id =: teamId order by Role__c DESC];
    }

    public void getTeamAccounts() {
        accountList = [SELECT Team_Account__c, Team_Account__r.Name, Team_Account__r.Id, Team_Account__r.AKAM_Account_ID__c, Team_Account__r.Support_Level__c, Team_Account__r.Customer_Tier__c,
                        Team_Account__r.Geography_Formula__c, Team_Account__r.ERC_Numeric__c from TS_TeamAccount__c where TS_Support_Team__r.Id =: teamId order by Team_Account__r.Name];
    }

    public PageReference newMember()
    {
        PageReference ref = new PageReference('/apex/TSTeamMemberCreate');
        ref.getParameters().put('teamid', teamId);
        return ref;
    }

    public String getTeamDetail(){
        selectedTeamObjList = [SELECT Name, Team_Name__c from TS_Support_Team__c where Id =:teamId];
        if(selectedTeamObjList != null && !selectedTeamObjList.isEmpty())
            return selectedTeamObjList[0].Team_Name__c;
        else
            return null;
    }

    public PageReference newAccount()
    {
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