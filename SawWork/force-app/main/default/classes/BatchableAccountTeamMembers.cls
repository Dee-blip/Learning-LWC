/* ========================================================================
    Author: Sonia Sawhney
    Description: Class used for updating the shadow object from the Account Team 
    Created Date : 08/01/2013
    ======================================================================== */
global class BatchableAccountTeamMembers implements Database.Batchable<sObject>
{  
   //start method that creates the dynamic query and returns the query locator
    global Database.QueryLocator start(Database.BatchableContext bc)
    {   
        
            AggregateResult result = [Select max(CompletedDate) jobDate from AsyncApexJob where 
                            ApexClass.Name = 'BatchableAccountTeamMembers'  and Status = 'Completed'];
            DateTime LastJobRunDate;
            if(result != null && result.get('jobDate') != null)
            {
                LastJobRunDate = (Datetime)result.get('jobDate');
            }
            string query = 'select Id, AccountAccessLevel,AccountId, TeamMemberRole, UserId from AccountTeamMember where User.isActive = true';
            if(LastJobRunDate != null)
               query += ' AND LastModifiedDate > :LastJobRunDate';
            if(system.Test.isRunningTest())
                query += ' ORDER BY CREATEDDATE DESC LIMIT 200';
            return Database.getQueryLocator(query);
        
       
    }

    //call the S2S sync class to create the sync records 
    global void execute(Database.BatchableContext bc,List<sObject> lstObjects)
    {        
        system.debug('*******************Execute of Batch Apex***********');
        ExternalSharingHelper.CreateUpdateAccountTeams(lstObjects);
    }
    
    //BatchApex Completes
    // execution with this finish method
    global void finish(Database.BatchableContext BC)
    {
        system.debug('****Finished*****');
    }
}