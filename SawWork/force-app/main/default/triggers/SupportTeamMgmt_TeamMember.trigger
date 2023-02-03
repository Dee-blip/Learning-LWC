trigger SupportTeamMgmt_TeamMember on TS_TeamMember__c (before update, before insert, before delete) {
    
    STM_Custom_Modal_Layout__mdt versionFlag = [SELECT Field__c FROM STM_Custom_Modal_Layout__mdt WHERE Object__c = 'Metadata'];
    
    if(versionFlag.Field__c == 'Old'){
        
        List<TS_TeamMember__c> teamMembers = new List<TS_TeamMember__c>();
        Map<String,List<String>> teamAccMap = new Map<String,List<String>>();
        List<AccountTeamMember> accTeamMembersDel = new List<AccountTeamMember>();
        List<AccountTeamMember> accTeamMembers = new List<AccountTeamMember>();
        List<TS_TeamAccount__c> teamAccs = new List<TS_TeamAccount__c>();
        List<String> supportTeamIds = new List<String>();
        
        if(Trigger.isUpdate && Trigger.isBefore){
            
            teamMembers = Trigger.old;
            System.debug('TSDebug-> teamMembers old size is '+ teamMembers.size()+' object is '+teamMembers);
            supportTeamIds = new List<String>();
            for(TS_TeamMember__c teamMember : teamMembers){
                supportTeamIds.add(teamMember.TS_Support_Team__c);
            }
            teamAccs = [SELECT Team_Account__c,TS_Support_Team__c from TS_TeamAccount__c  where TS_Support_Team__c = :supportTeamIds];
            teamAccMap =  SupportTeamMgmt_Utility.getTeamAccMap(teamAccs);
            accTeamMembers = SupportTeamMgmt_Utility.getAccTeamMembers(teamAccMap, teamMembers);
            System.debug('TSDebug-> accTeamMembers.size = '+accTeamMembers.size()+' object is '+accTeamMembers);
            accTeamMembersDel = SupportTeamMgmt_Utility.getAccTeamMembersDel(accTeamMembers);
            
            delete accTeamMembersDel;
            
            teamMembers = Trigger.new;
            System.debug('TSDebug-> teamMembers new size is '+ teamMembers.size()+' object is '+teamMembers);
            supportTeamIds = new List<String>();
            for(TS_TeamMember__c teamMember : teamMembers){
                supportTeamIds.add(teamMember.TS_Support_Team__c);
            }
            teamAccs = [SELECT Team_Account__c,TS_Support_Team__c from TS_TeamAccount__c  where TS_Support_Team__c = :supportTeamIds];
            teamAccMap =  SupportTeamMgmt_Utility.getTeamAccMap(teamAccs);
            accTeamMembers = SupportTeamMgmt_Utility.getAccTeamMembers(teamAccMap, teamMembers);
            insert accTeamMembers;
            
            
        }   
        
        if(Trigger.isInsert && Trigger.isBefore){
            teamMembers = Trigger.new;
            System.debug('TSDebug-> teamMembers new size is '+ teamMembers.size()+' object is '+teamMembers);
            supportTeamIds = new List<String>();
            for(TS_TeamMember__c teamMember : teamMembers){
                supportTeamIds.add(teamMember.TS_Support_Team__c);
            }
            teamAccs = [SELECT Team_Account__c,TS_Support_Team__c from TS_TeamAccount__c  where TS_Support_Team__c = :supportTeamIds];
            teamAccMap =  SupportTeamMgmt_Utility.getTeamAccMap(teamAccs);
            accTeamMembers = SupportTeamMgmt_Utility.getAccTeamMembers(teamAccMap, teamMembers);
            try{
                
                insert accTeamMembers; 
                System.debug('TSDebug-> successfully inserted to AccountTeamMember. size of list -> '+accTeamMembers.size()+'  object is '+ accTeamMembers); 
            }
            catch(Exception e){
                for(TS_TeamMember__c teamMember : teamMembers){
                    System.debug('TSDebug-> Exception occurred in adding teamMembers to AccountTeamMember.'+e.getMessage()); 
                    teamMember.addError('There was a problem adding Member to Support Team');
                }
                
                
            }
        }
        
        if(Trigger.isDelete && Trigger.isBefore){
            teamMembers = Trigger.old;
            System.debug('TSDebug-> teamMembers old size is '+ teamMembers.size()+' object is '+teamMembers);
            supportTeamIds = new List<String>();
            for(TS_TeamMember__c teamMember : teamMembers){
                supportTeamIds.add(teamMember.TS_Support_Team__c);
            }
            teamAccs = [SELECT Team_Account__c,TS_Support_Team__c from TS_TeamAccount__c  where TS_Support_Team__c = :supportTeamIds];
            teamAccMap =  SupportTeamMgmt_Utility.getTeamAccMap(teamAccs);
            accTeamMembers = SupportTeamMgmt_Utility.getAccTeamMembers(teamAccMap, teamMembers);
            System.debug('TSDebug-> accTeamMembers.size = '+accTeamMembers.size()+' object is '+accTeamMembers);
            accTeamMembersDel = SupportTeamMgmt_Utility.getAccTeamMembersDel(accTeamMembers);
            
            delete accTeamMembersDel;
        } 
    }
}