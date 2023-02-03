/*
Author          : Harshil Soni
Description     : Trigger for Support Team Account Object (TS_TeamAccount__c)
Test Class		: SC_STM_Controller_TC

Date				Developer			JIRA #			Description                                                       
------------------------------------------------------------------------------------------------------------------
28-Jan-21			Harshil Soni		ACD-61			Trigger for Support Team Account Object
------------------------------------------------------------------------------------------------------------------
*/
trigger SC_STM_SupportTeamAccountTrigger on TS_TeamAccount__c (after insert, before insert, before delete) {
    
    //Account Team Members are inserted through a process on inserting a support team account
    
    //Querying Metadata to check version
    STM_Custom_Modal_Layout__mdt versionFlag = [SELECT Field__c FROM STM_Custom_Modal_Layout__mdt WHERE Object__c = 'Metadata'];

    Boolean flag = Test.isRunningTest() || versionFlag.Field__c == 'New' ? true : false;

    
    
    if(flag){
        
        if(Trigger.isInsert && Trigger.isAfter){
            
            List<TS_TeamAccount__c> teamAccountList = Trigger.new;
            Map<String, String> newAccERCMap = new Map<String,String>();
            Map<String, String> ERCSupportTeamMap = new Map<String, String>();
            
            
            for(TS_TeamAccount__c eachAccount : teamAccountList){
                if(eachAccount.Team_Account_ERC__c != null && eachAccount.Team_Account_ERC__c != ''){
                    newAccERCMap.put(eachAccount.Team_Account__c, eachAccount.Team_Account_ERC__c);
                }
            }
            System.Debug('### new account erc map ' + newAccERCMap);
            if(!newAccERCMap.isEmpty()){
                //Check if there are any team accounts with the same ERC as inserted team accounts
                for(TS_TeamAccount__c sameERCAcc : [SELECT Id, Team_Account_ERC__c, TS_Support_Team__c FROM TS_TeamAccount__c 
                                                    WHERE Team_Account_ERC__c IN :newAccERCMap.values() 
                                                    AND Team_Account__c NOT IN :newAccERCMap.keySet()]){
                                                        ERCSupportTeamMap.put(sameERCAcc.Team_Account_ERC__c, sameERCAcc.TS_Support_Team__c);
                                                    }
                System.Debug('### erc support team map ' + ERCSupportTeamMap);
                if(!ERCSupportTeamMap.isEmpty()){
                    for(TS_TeamAccount__c newAcc : teamAccountList){
                        //Check if team account is inserted in support team not same as support team of team account with same ERC
                        if(newAcc.TS_Support_Team__c != ERCSupportTeamMap.get(newAcc.Team_Account_ERC__c)){
                            newAcc.addError('Accounts that share an ERC must be assigned to the same support team');
                        } 
                    }
                }
            }
            
        }
        
        if(Trigger.isInsert && Trigger.isBefore){
            //Update Unique field on Insert for duplicate rule validation
            for(TS_TeamAccount__c iteratedSTA : trigger.new){
                iteratedSTA.SC_STM_Unique_Field__c = iteratedSTA.Team_Account__c;
            }
            
        }
        
        if(Trigger.isDelete && Trigger.isBefore){
            
            //Updating child support team with account id of team account being deleted
            //This will trigger a process which deletes corresponding Account Team Members
            List<TS_TeamAccount__c> teamAccountList = Trigger.old;
            
            Map<String,String> teamAccMap = new Map<String,String>();
            List<String> accIds;
            String supportTeamId = '';
            String accountId = '';
            List<TS_Support_Team__c> teamList = new List<TS_Support_Team__c>();
            TS_Support_Team__c teamObj;
            
            for(TS_TeamAccount__c teamAcc : teamAccountList){
                teamAccMap.put(teamAcc.TS_Support_Team__c, teamAcc.Team_Account__c);
            }
            
            for(String teamId : teamAccMap.keySet()){
                teamObj = new TS_Support_Team__c(Id = teamId, Record_To_Process__c = teamAccMap.get(teamId));
                teamList.add(teamObj);
            }
            
            
            Update teamList;
            
            
        }
        
    }
    
}