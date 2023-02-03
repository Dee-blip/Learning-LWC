public without sharing class L2Q_AaccountTeamMemberTriggerClass {

   public static boolean AccountTeamMemberUpdateExclusion=false;

    public static void duplicateRoleCheck(List<AccountTeamMember> atmTriggerNew,set<id> accountIds,string dupTeamRole){
          
          List<AccountTeamMember> teamMembersList = new List<AccountTeamMember>();
            Map<id, Set<String>> teamMembersRoleMap = new Map<id, Set<String>>();
            string duplicateErrorMsg = GsmUtilClass.getGSMSettingValue('TeamMemberRoleError');

            teamMembersList =[select id,TeamMemberRole,AccountId from AccountTeamMember where AccountId in: accountIds];
            
            //map of AccountId to teammemberroles
            for(AccountTeamMember member : teamMembersList){

                if(dupTeamRole.contains(member.TeamMemberRole)){

                    if(teamMembersRoleMap.containskey(member.AccountId)){
                        teamMembersRoleMap.get(member.AccountId).add(member.TeamMemberRole);

                    }else{
                        teamMembersRoleMap.put(member.AccountId,new set<string>());
                        teamMembersRoleMap.get(member.AccountId).add(member.TeamMemberRole);
                    }
                }
                
              }
            
            //check for duplicate teammemberroles
            for(AccountTeamMember atm :atmTriggerNew){
                if(teamMembersRoleMap.containsKey(atm.AccountId)){
                    if(teamMembersRoleMap.get(atm.AccountId).contains(atm.TeamMemberRole))
                            atm.TeamMemberRole.addError(duplicateErrorMsg);
                }
            }
    
    
    }

    //SFDC-9170  Rajul Vishwakarma
    //Start
    public static void checkForNonAkamaiUsers(List<AccountTeamMember> atmTriggerNew){

        Map<Id,LIst<AccountTeamMember>> mapUserAndATM = new Map<Id,List<AccountTeamMember>>();

        for(AccountTeamMember atm:atmTriggerNew){
            if(!atm.Validation_Overide__c){
                if(mapUserAndATM.containsKey(atm.userId)){
                    mapUserAndATM.get(atm.userId).add(atm);
                }else{
                    mapUserAndATM.put(atm.userId,new List<AccountTeamMember>{atm});
                }
            } 
        }
        List<User> nonAkamaiUsers = [Select Email from User where id in :mapUserAndATM.keySet() and (NOT Email like '%@akamai.com')];
        for(User u:nonAkamaiUsers){
            List<AccountTeamMember> accounTeamMembers = mapUserAndATM.get(u.id);
            for(AccountTeamMember at:accounTeamMembers){
                at.addError('User with non-Akamai email address can not be added to the Account team');
            }
        }
    }
    //End
/*
    public static void checkATMUpdate(List<AccountTeamMember> atmToBeUpdated, Set<Id> accountIds){
        List<AccountTeamMember> allATMs=[select Id,TeamMemberRole,userId,AccountId,Account.OwnerId from AccountTeamMember where AccountId IN : accountIds];
        Map<Id,String> accountToAccountTeamMemberMap=new Map<Id,String>();
        for(AccountTeamMember atm : allATMs)
        {
            String atmListString=null;
            if(accountToAccountTeamMemberMap.containsKey(atm.AccountId))
            atmListString=accountToAccountTeamMemberMap.get(atm.AccountId);
            else
            atmListString='';
            atmListString += atm.UserId + ',';
            if(!atmListString.contains(atm.Account.OwnerId))
                atmListString += atm.Account.OwnerId + ',';
            accountToAccountTeamMemberMap.put(atm.AccountId,atmListString);
        }
        String profileIds=GsmUtilClass.getGSMSettingValue('AccounTeamDefaultAccessProfileIds');
        for(AccountTeamMember atm : atmToBeUpdated)
        {
            String userIds = accountToAccountTeamMemberMap.get(atm.AccountId);
            String currentUserId=UserInfo.getUserId();
            String currentUserProfileId=UserInfo.getProfileId();
           
            if(!profileIds.contains(currentUserProfileId) && !userIds.contains(currentUserId) && !Test.isRunningTest() && !AccountTeamMemberUpdateExclusion)
            atm.addError(GsmUtilClass.getGSMSettingValue('AccountTeamAccessErrorMessage'));
        }
    } */
    /** Start Added by Chandra for SFDC-9619*/
    
    public static Boolean hasChanges(String field, SObject oldRecord, SObject newRecord) {
        if (oldRecord == null) {
            return true;
        }
        return (oldRecord.get(field) != newRecord.get(field));
    } 
    public static void captureATMCreateUpdateDeleteAudit(List<AccountTeamMember> atmToBeUpdated, Map<Id,AccountTeamMember> atmOldMap){

        List<String> fieldsToAudit=new List<String> {'UserId','AccountId','AccountAccessLevel','OpportunityAccessLevel','CaseAccessLevel','TeamMemberRole','ContactAccessLevel'};
  
        List<AccountTeamMemberAudit__c> atmAuditRecords= new List<AccountTeamMemberAudit__c>();
        for(AccountTeamMember atm: atmToBeUpdated)
        {
           if(trigger.isInsert || trigger.isDelete)
           {
            AccountTeamMemberAudit__c atmAudit=new AccountTeamMemberAudit__c(ATM_Record_Id__c=atm.Id);
            if(trigger.isInsert) 
                atmAudit.Operation__c='Create';
            else 
                atmAudit.Operation__c='Delete';
            atmAuditRecords.add(atmAudit);
           }
           
           if(trigger.isUpdate)
           {
            for(String fieldToAudit: fieldsToAudit)
            {
                if(hasChanges(fieldToAudit,atmOldMap.get(atm.id),atm))
                {
                    AccountTeamMemberAudit__c atmAudit=new AccountTeamMemberAudit__c(Operation__c='Update',
                                                                                    ChangeType__c=fieldToAudit,
                                                                                    Old_Value__c=(String)atmOldMap.get(atm.Id).get(fieldToAudit),
                                                                                    New_Value__c=(String)atm.get(fieldToAudit),
                                                                                    ATM_Record_Id__c=atm.Id);
                    atmAuditRecords.add(atmAudit);
                }
            }
           }
            

        }
        insert atmAuditRecords;
    }
    /** End Added by Chandra for SFDC-9619*/
}