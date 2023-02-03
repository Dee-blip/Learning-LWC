public class SupportTeamMgmt_Utility {
    public static Map<String, List<String>> getTeamAccMap(List<TS_TeamAccount__c> teamAccList){
        Map<String, List<String>> teamAccMap = new Map<String, List<String>>();
        String supportTeamId = '';
        String accountId = '';
        List<String> accIds = new List<String>();
        
        for(TS_TeamAccount__c teamAccount : teamAccList){
            supportTeamId = teamAccount.TS_Support_Team__c;
            accountId = teamAccount.Team_Account__c;
            if((teamAccMap.get(supportTeamId))!=null){
                accIds = teamAccMap.get(supportTeamId);
                accIds.add(accountId);
                teamAccMap.put(supportTeamId, accIds) ;
            }
            else{
                accIds = new List<String>();
                accIds.add(accountId);
                teamAccMap.put(supportTeamId, accIds);
            }
        }
        return teamAccMap;
    }
    
    public static List<AccountTeamMember> getAccTeamMembers
        (Map<String, List<String>> teamAccountMap){ 
            List<TS_TeamMember__c> teamMembers = [SELECT Id, Role__c, Team_Member__c,TS_Support_Team__c from TS_TeamMember__c where TS_Support_Team__c in :teamAccountMap.keySet()];
            List<AccountTeamMember> accTeamMembers = new List<AccountTeamMember>();
            for(TS_TeamMember__c teamMember : teamMembers){
                
                for(String accId : teamAccountMap.get(teamMember.TS_Support_Team__c)){
                    AccountTeamMember accTeamMember = new AccountTeamMember();
                    accTeamMember.AccountId = accId;
                    accTeamMember.UserId = teamMember.Team_Member__c;
                    accTeamMember.TeamMemberRole = teamMember.Role__c;
                    accTeamMembers.add(accTeamMember);
                }
            }           
            return accTeamMembers;
        }
    
    public static List<AccountTeamMember> getAccTeamMembers
        (Map<String, List<String>> teamAccountMap, List<TS_TeamMember__c> teamMembers){ 
            //List<TS_TeamMember__c> teamMembers = [SELECT Id, Role__c, Team_Member__c,TS_Support_Team__c from TS_TeamMember__c where TS_Support_Team__c in :teamAccountMap.keySet()];
            List<AccountTeamMember> accTeamMembers = new List<AccountTeamMember>();
            for(TS_TeamMember__c teamMember : teamMembers){
                if(teamAccountMap.get(teamMember.TS_Support_Team__c)!=null){
                    for(String accId : teamAccountMap.get(teamMember.TS_Support_Team__c)){
                        AccountTeamMember accTeamMember = new AccountTeamMember();
                        accTeamMember.AccountId = accId;
                        accTeamMember.UserId = teamMember.Team_Member__c;
                        accTeamMember.TeamMemberRole = teamMember.Role__c;
                        accTeamMembers.add(accTeamMember);
                    }
            	}
            }
            
            return accTeamMembers; 
        }
    
    public static Map<String,List<String>> getAccTeamMap(List<TS_TeamMember__c> teamMembers){
        List<String> supportTeamIds = new List<String>();
        Map<String,List<String>> teamAccMap = new Map<String,List<String>>();
        
        String supportTeamId = '';
        String accountId = '';
        List<String> accIds = new List<String>();
        
        for(TS_TeamMember__c teamMember : teamMembers){
            supportTeamIds.add(teamMember.Id);
        }
        List<TS_TeamAccount__c> teamAccs = [SELECT Team_Account__c,TS_Support_Team__c from TS_TeamAccount__c  where TS_Support_Team__c = :supportTeamIds];
        for( TS_TeamAccount__c teamAcc : teamAccs ){
            supportTeamId = teamAcc.TS_Support_Team__c;
            accountId = teamAcc.Team_Account__c;
            if(teamAccMap.get(supportTeamId)!=null){
                accIds = teamAccMap.get(supportTeamId);
                accIds.add(accountId);
                teamAccMap.put(supportTeamId, accIds);
            }
            else{
                accIds = new List<String>();
                accIds.add(accountId);
                teamAccMap.put(supportTeamId, accIds);
            }
        }
        return teamAccMap;  
    }
    
    public static List<AccountTeamMember> getAccTeamMembersDel(List<AccountTeamMember> accTeamMembers){
        List<AccountTeamMember> accTeamMembersDelete = new List<AccountTeamMember>();
        List<String> accIds = new List<String>();
        for(AccountTeamMember accTeamMember : accTeamMembers){
            accIds.add(accTeamMember.AccountId);
        }
        
        List<AccountTeamMember> accTeamMembersAll = [select Id, AccountId, UserId, TeamMemberRole from AccountTeamMember where AccountId in :accIds];
        
        for(AccountTeamMember accTeamMember : accTeamMembersAll){
            for(AccountTeamMember accTeamMember1 : accTeamMembers){
                if((accTeamMember.AccountId==accTeamMember1.AccountId)&&
                   (accTeamMember.UserId==accTeamMember1.UserId)&&
                   (accTeamMember.TeamMemberRole==accTeamMember1.TeamMemberRole)){
                       accTeamMembersDelete.add(accTeamMember);
                   }
            }
            
        }
        return accTeamMembersDelete;
    }

    public static String getERCNumeric(String AKERCNumeric){
        String[] AKERCNumericArry = AKERCNumeric.toLowerCase().split('');
        String ERCNumeric = '';

        for(String chr : AKERCNumericArry){
            if(chr.isNumeric()){
                 ERCNumeric += chr;
            }
            else if (chr >= 'a' && chr <= 'c'){ 
                ERCNumeric += 2;     
            }   
            else if (chr >= 'd' && chr <= 'f'){ 
                ERCNumeric += 3;
            }   
            else if (chr >= 'g' && chr <= 'i'){ 
                ERCNumeric += 4;
            }   
            else if (chr >= 'j' && chr <= 'l'){ 
                ERCNumeric += 5;
            }   
            else if (chr >= 'm' && chr <= 'o'){ 
                ERCNumeric += 6;
            }   
            else if (chr >= 'p' && chr <= 's'){ 
                ERCNumeric += 7;
            }   
            else if (chr >= 't' && chr <= 'v'){ 
                ERCNumeric += 8;
            }   
            else  if (chr >= 'w' && chr <= 'z'){ 
                ERCNumeric += 9;
            }  
        }
    return ERCNumeric;

    }

}