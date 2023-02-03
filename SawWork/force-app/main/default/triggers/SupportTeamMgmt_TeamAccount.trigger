trigger SupportTeamMgmt_TeamAccount on TS_TeamAccount__c (before update, after insert, before delete) {
    
    STM_Custom_Modal_Layout__mdt versionFlag = [SELECT Field__c FROM STM_Custom_Modal_Layout__mdt WHERE Object__c = 'Metadata'];
    
    if(versionFlag.Field__c == 'Old'){
        if(Trigger.isUpdate && Trigger.isBefore){
            List<TS_TeamAccount__c> teamAccountList = new List<TS_TeamAccount__c>();
            Map<String, List<String>> teamAccountMap = new Map<String, List<String>>();
            List<AccountTeamMember> accountTeamMemberList = new  List<AccountTeamMember>();
            
            teamAccountList = Trigger.old;
            teamAccountMap = SupportTeamMgmt_Utility.getTeamAccMap(teamAccountList);
            accountTeamMemberList = SupportTeamMgmt_Utility.getAccTeamMembers(teamAccountMap);
            
            List<AccountTeamMember> accTeamMembersDelete = SupportTeamMgmt_Utility.getAccTeamMembersDel(accountTeamMemberList);
            delete accTeamMembersDelete;
            
            
            teamAccountList = Trigger.new;
            teamAccountMap = SupportTeamMgmt_Utility.getTeamAccMap(teamAccountList);
            accountTeamMemberList = SupportTeamMgmt_Utility.getAccTeamMembers(teamAccountMap);
            
            insert accountTeamMemberList;   
        }  
        
        if(Trigger.isInsert && Trigger.isAfter){
            List<TS_TeamAccount__c> teamAccountList = Trigger.new;
            
            Map<String, List<String>> teamAccountMap = SupportTeamMgmt_Utility.getTeamAccMap(teamAccountList);
            List<AccountTeamMember> accTeamMembers = SupportTeamMgmt_Utility.getAccTeamMembers(teamAccountMap);
            
            insert accTeamMembers;   
        }
        
        if(Trigger.isDelete && Trigger.isBefore){
            List<TS_TeamAccount__c> teamAccountList = Trigger.old;
            
            
            Map<String, List<String>> teamAccMap =  SupportTeamMgmt_Utility.getTeamAccMap(teamAccountList);
            List<AccountTeamMember> accTeamMembers = SupportTeamMgmt_Utility.getAccTeamMembers(teamAccMap);
            
            List<AccountTeamMember> accTeamMembersDelete = SupportTeamMgmt_Utility.getAccTeamMembersDel(accTeamMembers);
            delete accTeamMembersDelete;
            
        } 
        
    }
    
}