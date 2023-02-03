/* ========================================================================
    Author: Sonia Sawhney
    Description: Class used for deleting the shadow object for the deleted Account Teams 
    Created Date : 08/02/2013
    ======================================================================== */
global class BatchableDeleteAccountTeamMembers implements Database.Batchable<sObject>
{  
   //start method that creates the query and returns the query locator
    global Database.QueryLocator start(Database.BatchableContext bc)
    {   
       string query = 'select Id, AccountTeamId__c from Account_team__c order by CreatedDate desc';
       if(system.Test.isRunningTest())
            query += ' LIMIT 200';
        return Database.getQueryLocator(query);
    }

    //call the delete account method 
    global void execute(Database.BatchableContext bc,List<Account_Team__c> lstObjects)
    {        
        system.debug('*******************Execute of Batch Apex***********');
        set<Id> ids = new set<Id>();
        set<Id> teamIds = new set<Id>();
        for(Account_Team__c accTeam : lstObjects)
        {
            if(accTeam.AccountTeamId__c !=null)
                ids.add(accTeam.AccountTeamId__c);
            teamIds.add(accTeam.id);
        }
        list<AccountTeamMember> lstTeams = [Select Id from AccountteamMember where id in :ids];
        set<string> existingTeams = new set<string>();
        for(AccountTeamMember member : lstTeams)
        {
            existingTeams.add(member.id);
        }
        list<Account_Team__c> accountTeam = [Select Id from Account_Team__c where id in :teamIds
                                            and AccountTeamId__c not in:existingTeams];
        delete accountTeam;        
    }
    
    //BatchApex Completes
    // execution with this finish method
    global void finish(Database.BatchableContext BC)
    {
        system.debug('****Finished*****');
    }
}