public class SC_STM_TriggerUtility {
    
    @InvocableMethod(label='InsertAccTeamMembers' description='Method for inserting Account Team Members from Support Team Account Process')
    public static void InsAccTeamMembers(List<Id> recordIds){
        
        // Getting Sobject Type
        String sobjectType = recordIds[0].getSObjectType().getDescribe().getName();
        
        if(sobjectType == 'TS_TeamAccount__c')
            InsAccTeamMembers_fromSTA(recordIds[0]);
        
        else if(sobjectType == 'TS_TeamMember__c')
            InsAccTeamMembers_fromSTM(recordIds[0]);
        
        else if(sobjectType == 'TS_Support_Team__c')
            DelAccTeamMembers(recordIds[0]);
            }
    
    public static void DelAccTeamMembers(ID supportTeamId){
        
        Id deleteId = [Select Id, Record_To_Process__c From TS_Support_Team__c Where Id = :supportTeamId LIMIT 1].Record_To_Process__c;
        
        String sobjectType = deleteId.getSObjectType().getDescribe().getName();
        
        if(sobjectType == 'Account')
            DelAccTeamMembers_fromSTA(supportTeamId, deleteId);
        else if(sobjectType == 'User')
            DelAccTeamMembers_fromSTM(supportTeamId, deleteId);
    }
    
    public static void DelAccTeamMembers_fromSTA(ID supportTeamId, ID teamAccId){
        
        //List<TS_TeamMember__c> teamMembers = [Select Id, Team_Member__c, Role__c From TS_TeamMember__c Where TS_Support_Team__c = :supportTeamId];
        try{
            Delete [Select Id from AccountTeamMember Where UserId IN (Select Team_Member__c From TS_TeamMember__c Where TS_Support_Team__c = :supportTeamId)
                    AND AccountId = :teamAccId];
        }
        catch (Exception e){
            System.Debug(e.getMessage());
        }
        
    }
    
    public static void DelAccTeamMembers_fromSTM(ID supportTeamId, ID teamMemId){
        
        try{
        Delete [Select Id from AccountTeamMember Where AccountId IN (Select Team_Account__c from TS_TeamAccount__c Where TS_Support_Team__c = :supportTeamId)
               And UserId = :teamMemId];
        }
        catch (Exception e){
            System.Debug(e.getMessage());
        }
    }
    
    public static void InsAccTeamMembers_fromSTA (ID supportTeamAccountID){
        
        AccountTeamMember accTeamMember;
        List<AccountTeamMember> accTeamMembers = new List<AccountTeamMember>();
        String accountId = [Select Team_Account__c FROM TS_TeamAccount__c Where Id = :supportTeamAccountID LIMIT 1].Team_Account__c;
        for(TS_TeamMember__c teamMember : [ SELECT Id, Role__c, Team_Member__c, TS_Support_Team__c
                                           FROM TS_TeamMember__c
                                           WHERE TS_Support_Team__c IN
                                           (select TS_Support_Team__c from TS_TeamAccount__c where Id = :supportTeamAccountID)]){
                                               
                                               accTeamMember = new AccountTeamMember();
                                               accTeamMember.AccountId = accountId;
                                               accTeamMember.UserId = teamMember.Team_Member__c;
                                               accTeamMember.TeamMemberRole = teamMember.Role__c;
                                               accTeamMembers.add(accTeamMember);
                                           }
        System.Debug('### ' + accTeamMembers);
        Insert accTeamMembers;
    }
    
    
    public static void InsAccTeamMembers_fromSTM (ID supportTeamMemID){
        
        AccountTeamMember accTeamMember;
        List<AccountTeamMember> accTeamMembers = new List<AccountTeamMember>();
        TS_TeamMember__c teamMember = [SELECT Team_Member__c, Role__c FROM TS_TeamMember__c WHERE id = :supportTeamMemID];
        for(TS_TeamAccount__c teamAccount : [ SELECT Team_Account__c,TS_Support_Team__c 
                                             from TS_TeamAccount__c  
                                             where TS_Support_Team__c IN
                                             (select TS_Support_Team__c from TS_TeamMember__c where id = :supportTeamMemID)]){
                                               
                                               accTeamMember = new AccountTeamMember();
                                               accTeamMember.AccountId = teamAccount.Team_Account__c;
                                               accTeamMember.UserId = teamMember.Team_Member__c;
                                               accTeamMember.TeamMemberRole = teamMember.Role__c;
                                               accTeamMembers.add(accTeamMember);
                                           }
        System.Debug('### ' + accTeamMembers);
        Insert accTeamMembers;
    }
    
}