public without sharing class L2Q_OpportunityTeamMemberTriggerHandler {

    public static void duplicateRoleCheck(List<OpportunityTeamMember> otmTriggerNew,set<id> opptyIds,string dupTeamRole){
    
    
        List<OpportunityTeamMember> teamMembersList = new List<OpportunityTeamMember>();
        Map<id, Set<String>> teamMembersRoleMap = new Map<id, Set<String>>();
        string errorMessage = GsmUtilClass.getGSMSettingValue('TeamMemberRoleError'); 

            teamMembersList =[select id,TeamMemberRole,OpportunityId from OpportunityTeamMember where OpportunityId in: opptyIds];
            system.debug('swati::'+teamMembersList);
            //map of OpportunityId to teammemberroles
            for(OpportunityTeamMember member : teamMembersList){

                if(dupTeamRole.contains(member.TeamMemberRole)){

                    if(teamMembersRoleMap.containskey(member.OpportunityId)){
                        teamMembersRoleMap.get(member.OpportunityId).add(member.TeamMemberRole);

                    }else{
                        teamMembersRoleMap.put(member.OpportunityId,new set<string>());
                        teamMembersRoleMap.get(member.OpportunityId).add(member.TeamMemberRole);
                    }
                }
            }
            system.debug('Swati::'+teamMembersRoleMap);
            //check for duplicate teammemberroles
            for(OpportunityTeamMember otm : otmTriggerNew){
                system.debug('swati::'+otm);
              if(teamMembersRoleMap.containsKey(otm.OpportunityId))
                if(teamMembersRoleMap.get(otm.OpportunityId).contains(otm.TeamMemberRole))
                        otm.TeamMemberRole.addError(errorMessage);

            }
    
    
    }









}