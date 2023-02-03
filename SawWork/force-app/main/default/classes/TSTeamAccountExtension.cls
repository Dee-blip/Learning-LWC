public class TSTeamAccountExtension {

    ApexPages.StandardController sController;
    public TS_TeamAccount__c taccount {get; set;}
    public TS_Support_Team__c parentTeam {get; set;}
    public String teamId {get; set;}
    public Boolean success {get;set;}

    public TSTeamAccountExtension(ApexPages.StandardController controller) {
        sController = controller;
        this.taccount = (TS_TeamAccount__c) sController.getRecord();
        teamId = ApexPages.currentPage().getParameters().get('teamid');
        if(taccount.TS_Support_Team__c == null)
            taccount.TS_Support_Team__c = teamId;
        success = null;
    }

    public PageReference save()
    {
        PageReference ref = new PageReference('/apex/TSSupportTeamsList');
        try
        {
            String thisTeam = taccount.TS_Support_Team__c;
            String thisAccount = taccount.Team_Account__c;
            List<TS_TeamAccount__c> accountsList = [SELECT Team_Account__c, TS_Support_Team__r.Team_Name__c from TS_TeamAccount__c];
            for(TS_TeamAccount__c itrAccount:accountsList){
                if(itrAccount.Team_Account__c != null && itrAccount.Team_Account__c.equals(thisAccount)){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'This account is already associated with a support team - ' + itrAccount.TS_Support_Team__r.Team_Name__c));
                    return null;
                }
            }

            TS_Support_Team__c team = [SELECT Name,Team_Type__c from TS_Support_Team__c where Id =:teamId];
            Account acc = [SELECT Name,Support_Level__c,ERC_Numeric__c from Account where Id =:taccount.Team_Account__c];
            if(team.Team_Type__c.containsIgnoreCase('premium') && (acc.Support_Level__c == null || (!acc.Support_Level__c.containsIgnoreCase('premium'))))
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You can only assign Premium accounts to a Premium Team'));
                return null;
            }
            // check if another account with same ERC is present and is associated to another support team
            if(acc.ERC_Numeric__c != null && acc.ERC_Numeric__c != '')
            {
                List<Account> accountsWithSameERC = [Select Id, ERC_Numeric__c, Name from Account where ERC_Numeric__c =:acc.ERC_Numeric__c and Id !=:acc.Id];
                if(!accountsWithSameERC.isEmpty())
                {
                    for(Account acct:accountsWithSameERC){
                        TS_TeamAccount__c[] teamAcc = [SELECT TS_Support_Team__c, Team_Account__c from TS_TeamAccount__c where Team_Account__c =:acct.Id];
                        if((teamAcc.size() > 0) && (teamAcc[0].TS_Support_Team__c != taccount.TS_Support_Team__c))
                        {
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Accounts that share an ERC must be assigned to the same support team.'));
                            return null;
                        }
                    }
                }
            }
            System.debug('ITDiscovy-Criteria matched. Adding account to the team.');
            sController.save();
            success = true;
        }
        catch(Exception e)
        {
            System.debug('ITDiscovy-Exception occured while adding account to the team. '+ e.getMessage());
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            return null;
        }
        return null;
    }

}