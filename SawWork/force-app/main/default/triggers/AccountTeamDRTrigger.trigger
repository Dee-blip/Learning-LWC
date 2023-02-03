/* ========================================================================
    Author: Sonia Sawhney
    Description: Used for automatic syncing of new account team records with the DR organization , re-establishing the 
                 lookup relationships for the DR and creation/deletion/updation of AccountTeamMembers
    Created Date : 07/31/2013
    ======================================================================== */
trigger AccountTeamDRTrigger on Account_Team__c (before insert, before update, after insert, after update, after delete) 
{ 
    //Check for preventing recursive trigger calls
    if(!ExternalSharingHelper.isTriggerFutureControl && (!system.Test.isRunningTest() || (system.Test.isRunningTest() && ExternalSharingHelper.RunFromtestClass == true)))
    {
        Environment_Setup__c environmentSetup = Environment_Setup__c.getInstance();
        if(environmentSetup.Environment_Type__c.equalsIgnorecase('Primary'))
        {
            if(Trigger.isInsert && Trigger.isAfter)
                ExternalSharingHelper.createS2Ssync('', Trigger.new, null); 
        }
        else
        {
            if(!Trigger.isDelete)
            {
                //Establish the lookup relationships in the before trigger
                if(Trigger.isBefore)
                {
                    ExternalSharingHelper.linkUserLookups('Account_Team__c', Trigger.new, Trigger.isUpdate, Trigger.oldMap) ;
                    //Establish lookup relationship
                    ExternalSharingHelper.linkObjectsSync('Account_Team__c',Trigger.new, Trigger.isUpdate, Trigger.oldMap);
                }
                //Create/update the account teams
                else 
                {
                    ExternalSharingHelper.CreateUpdateAccTeams(Trigger.new);
                }
            }        
            //Delete the Account teams once shadow object record is deleted
            else if(Trigger.isAfter)
            {
                ExternalSharingHelper.DeleteAccountTeams(Trigger.old);
            }
        }

    }
    // start of GSM code

    if(Trigger.isInsert && Trigger.isAfter)
    {
        // upsert Contract Share records
        System.debug(Logginglevel.ERROR,'AGH_D enteredc');
        ContractSharing.upsertContractShares(Trigger.new);

    }
    // you cannot update UserId or AccountId in account team members

    if(Trigger.isDelete && Trigger.isAfter)
    {
        // delete Contract Share records
        Set<Id> atmsToBeDeleted = new Set<Id>();
        for(Account_Team__c atm : Trigger.old)
        {
             //Added by ssawhney as Account Team records are created without a accountTeamid in DR org
            if(atm.AccountTeamId__c!=null)
            {
            	atmsToBeDeleted.add(atm.AccountTeamId__c);
        	}
        }

        if(atmsToBeDeleted.size()>0)
        {
            // contract sharing delete
            ContractSharing.deleteContractShares(atmsToBeDeleted);
        }

    }

    //end of gsm code
}