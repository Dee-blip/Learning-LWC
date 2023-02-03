/*
Author          : Harshil Soni
Description     : Trigger for Support Team Object (TS_Support_Team__c)
Test Class		: SC_STM_Controller_TC

Date				Developer			JIRA #			Description                                                       
------------------------------------------------------------------------------------------------------------------
28-Jan-21			Harshil Soni		ACD-61			Trigger for Support Team Object
07-Jun-21			Harshil Soni		ACD-363			Changing references to team types
------------------------------------------------------------------------------------------------------------------
*/
trigger SC_STM_SupportTeamTrigger on TS_Support_Team__c (before Update) {
    
    //Querying Metadata to check version
    STM_Custom_Modal_Layout__mdt versionFlag = [SELECT Field__c FROM STM_Custom_Modal_Layout__mdt WHERE Object__c = 'Metadata'];

    Boolean flag = Test.isRunningTest() || versionFlag.Field__c == 'New' ? true : false;
    
    if(flag){
        
        if(Trigger.isUpdate && Trigger.isBefore){
            
            Set<Id> teamIdList = new Set<Id>();
            //Map<Id, String> teamAccTypeMap = new Map<Id,String>();
            Set<Id> errorTeamList = new Set<Id>();
            
            for(TS_Support_Team__c team : Trigger.new){
                //Check whether team type is changed to premium* from non-premium*
                //ACD-363 - Changes by Harshil
                if(team.Team_Type__c.containsIgnoreCase('geo-p') && !trigger.oldMap.get(team.id).Team_Type__c.containsIgnoreCase('geo-p'))
                    teamIdList.add(team.Id);
                System.debug('### teamIdList' + teamIdList);
            }
            
            if(!teamIdList.isEmpty()){
                //Check if there are any team accounts present with support level not containing premium
                for(TS_TeamAccount__c teamAccount : [Select Id, Team_Account_Support_Level__c, TS_Support_Team__c From TS_TeamAccount__c Where TS_Support_Team__c IN :teamIdList AND (NOT (Team_Account_Support_Level__c LIKE '%Premium%'))]){
                    //teamAccTypeMap.put(teamAccount.TS_Support_Team__c,'premium');
                    errorTeamList.add(teamAccount.TS_Support_Team__c);
                    System.debug('### errorTeamList' + errorTeamList);
                }
                
                if(!errorTeamList.isEmpty()){
                    for(TS_Support_Team__c team : Trigger.new){
                        if(errorTeamList.contains(team.Id))
                            team.addError('Team Type cannot be changed to Premium (Geo-P) because Support Team contains one OR more Non-Premium Accounts!');
                    }
                }
            }
            
        }
    }
}