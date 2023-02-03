public class TSTeamMemberExtension {

    ApexPages.StandardController sController;
    public TS_TeamMember__c tmember {get; set;}
    public TS_Support_Team__c parentTeam {get; set;}
    public String teamId {get; set;}
    public Boolean success {get;set;}
    public String action;
    
    public TSTeamMemberExtension(ApexPages.StandardController controller) {
        sController = controller;
        this.tmember = (TS_TeamMember__c) sController.getRecord();
        teamId = ApexPages.currentPage().getParameters().get('teamid');
        action = ApexPages.currentPage().getParameters().get('act');
        if(tmember.TS_Support_Team__c == null)
            tmember.TS_Support_Team__c = teamId;
        success = null;
    }
    
    public PageReference save()
    {
        System.debug('Support team is '+tmember.TS_Support_Team__c);
        System.debug('User selected is '+tmember.Team_Member__c);
        teamId = tmember.TS_Support_Team__c;
        if(action!=null && action.equals('New')){
            String thisUser = tmember.Team_Member__c;
            List<TS_TeamMember__c> userList = [SELECT Team_Member__c, Role__c,Team_Member__r.id, Team_Member__r.alias, Team_Member__r.FirstName, Team_Member__r.LastName from TS_TeamMember__c where TS_Support_Team__r.Id =: teamId];
            for(TS_TeamMember__c itrUser:userList){
                if(itrUser.Team_Member__c.equals(thisUser)){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'This user is already added to this support team.'));
                    return null;
                }   
            }
        } 
        PageReference ref = new PageReference('/apex/TSSupportTeamsList');
        try
        {
           if(sController.save()==null){
            //  ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to add member to Support Team!'));   
              return null;
            }
            success = true;
        }
        catch(Exception e)
        {
            System.debug('Ashwini : Insertion failed ');
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
        }
        return null;
    }
}