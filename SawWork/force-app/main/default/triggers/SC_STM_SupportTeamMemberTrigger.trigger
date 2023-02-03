/*
Author          : Harshil Soni
Description     : Trigger for Support Team Member Object (TS_TeamMember__c)
Test Class		: SC_STM_Controller_TC

Date				Developer			JIRA #			Description                                                       
------------------------------------------------------------------------------------------------------------------
28-Jan-21			Harshil Soni		ACD-61			Trigger for Support Team Member Object
------------------------------------------------------------------------------------------------------------------
*/
trigger SC_STM_SupportTeamMemberTrigger on TS_TeamMember__c (before insert, before update, before delete){
    
    //Account Team Members are inserted through a process on inserting a support team account
        
    List<TS_TeamMember__c> teamMembers = new List<TS_TeamMember__c>();
    //Map<String,List<String>> teamAccMap = new Map<String,List<String>>();
    //List<AccountTeamMember> accTeamMembersDel = new List<AccountTeamMember>();
    //List<AccountTeamMember> accTeamMembers = new List<AccountTeamMember>();
    //List<TS_TeamAccount__c> teamAccs = new List<TS_TeamAccount__c>();
    List<String> supportTeamIds = new List<String>();
    //Map<String, String> memberTeamMap = new Map<String, String>();
    List<Id> filteredMemId = new List<Id>();
    
    //Querying Metadata to check version
    STM_Custom_Modal_Layout__mdt versionFlag = [SELECT Field__c FROM STM_Custom_Modal_Layout__mdt WHERE Object__c = 'Metadata'];

    Boolean flag = Test.isRunningTest() || versionFlag.Field__c == 'New' ? true : false;
    
    if(flag){
        
        if(Trigger.isUpdate && Trigger.isBefore){
            
            for(TS_TeamMember__c iteratedSTM : trigger.new){
                if(iteratedSTM.TS_Support_Team__c != trigger.oldMap.get(iteratedSTM.id).TS_Support_Team__c || iteratedSTM.Team_Member__c  != trigger.oldMap.get(iteratedSTM.id).Team_Member__c ){
                    //Update Unique field on Update for duplicate rule validation
                    iteratedSTM.Unique_Field__c = iteratedSTM.TS_Support_Team__c + '-' + iteratedSTM.Team_Member__c;
                    filteredMemId.add(iteratedSTM.Id);
                }
            }
            
            //Updating child support team with user id of team member being updated
            //This will trigger a process which deletes corresponding Account Team Members
            teamMembers = Trigger.old;
            Map<String,String> teamMemMap = new Map<String,String>();
            //supportTeamIds = new List<String>();
            //List<String> userIds = new List<String>();
            List<TS_Support_Team__c> teamList = new List<TS_Support_Team__c>();
            TS_Support_Team__c teamObj;
            for(TS_TeamMember__c teamMember : teamMembers){
                if(filteredMemId.contains(teamMember.Id)){
                    /*supportTeamIds.add(teamMember.TS_Support_Team__c);
					userIds.add(teamMember.Team_Member__c);*/
                    teamMemMap.put(teamMember.TS_Support_Team__c, teamMember.Team_Member__c);
                }
            }
            
            for(String teamId : teamMemMap.keySet()){
                teamObj = new TS_Support_Team__c(Id = teamId, Record_To_Process__c = teamMemMap.get(teamId));
                teamList.add(teamObj);
            }
            
            Update teamList;
            /*teamAccs = [SELECT Team_Account__c,TS_Support_Team__c from TS_TeamAccount__c  where TS_Support_Team__c = :supportTeamIds];
            
            SC_STM_TriggerUtility.DelAccTeamMembers_fromSTM(teamAccs,userIds);*/
            
        }   
        
        if(Trigger.isInsert && Trigger.isBefore){
            teamMembers = Trigger.new;
            //supportTeamIds = new List<String>();
            //Update Unique field on Insert for duplicate rule validation
            for(TS_TeamMember__c teamMember : teamMembers){
                //Code to Update Unique field
                teamMember.Unique_Field__c = teamMember.TS_Support_Team__c + '-' + teamMember.Team_Member__c;
                //supportTeamIds.add(teamMember.TS_Support_Team__c);
            }
            
        }
        
        if(Trigger.isDelete && Trigger.isBefore){
            //Updating child support team with user id of team member being deleted
            //This will trigger a process which deletes corresponding Account Team Members
            teamMembers = Trigger.old;
            Map<String,String> teamMemMap = new Map<String,String>();
            //supportTeamIds = new List<String>();
            //List<String> userIds = new List<String>();
            List<TS_Support_Team__c> teamList = new List<TS_Support_Team__c>();
            TS_Support_Team__c teamObj;
            for(TS_TeamMember__c teamMember : teamMembers){
                /*supportTeamIds.add(teamMember.TS_Support_Team__c);
				userIds.add(teamMember.Team_Member__c);*/
                teamMemMap.put(teamMember.TS_Support_Team__c, teamMember.Team_Member__c);
            }
            //teamAccs = [SELECT Team_Account__c from TS_TeamAccount__c  where TS_Support_Team__c = :supportTeamIds];
            
            //SC_STM_TriggerUtility.DelAccTeamMembers_fromSTM(teamAccs,userIds);
            
            for(String teamId : teamMemMap.keySet()){
                teamObj = new TS_Support_Team__c(Id = teamId, Record_To_Process__c = teamMemMap.get(teamId));
                teamList.add(teamObj);
            }
            
            Update teamList;
            
        }
        
    }
    
}