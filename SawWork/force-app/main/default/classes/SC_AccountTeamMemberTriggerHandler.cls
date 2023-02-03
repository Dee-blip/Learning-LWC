public without sharing class SC_AccountTeamMemberTriggerHandler extends ApexTriggerHandlerAbstractClass
{
	public Sc_AccountTeamMemberTriggerHandler(){}
    
    public override void beforeInsertBeforeUpdateTrigger()
    {
        
    }
    
    public override void afterInsertAfterUpdateTrigger()
    {
        // Vishnu Sharma - Start - ESESP-1588
        createCaseNotificationOnUpdate(newList,oldMap);
        // Vishnu Sharma - End - ESESP-1588
    }   
    
    // Vishnu Sharma - Start - ESESP-1588
    public static void createCaseNotificationOnUpdate(List<sObject> newList, Map<Id, sObject> oldMap){
        List<Case_Notification_Subscription__c> caseNotificationSubsList= new List<Case_Notification_Subscription__c>();
        List<Case_Notification_Subscription__c> caseNotificationSubsListToUpdate= new List<Case_Notification_Subscription__c>();
        List<Case_Notification_Subscription__c> caseNotificationSubsListToDelete= new List<Case_Notification_Subscription__c>();
        Case_Notification_Subscription__c tempCaseNotificationSubscription;
        Map<Id,String> teamMemberVsAccountMap = new Map<Id,String>();
        Map<Id,List<Case_Notification_Subscription__c>> accountVsCaseNotificationList = new Map<Id,List<Case_Notification_Subscription__c>>();
        List<Id> teamMembersIdList = new List<Id>();
        List<Id> teamMembersIdListUpdatedToNonCXM = new List<Id>();
        List<Id> accountsIdList = new List<Id>();
        List<AccountTeamMember> recsToBeProcessed = new List<AccountTeamMember>();
        SC_Utility__mdt teamRolerec = [Select Id,Value_Text__c from SC_Utility__mdt where Label = 'CXM value team role' limit 1];
        
        for(SObject so:newList){
            if((Trigger.isInsert && (String)so.get('TeamMemberRole') == teamRolerec.Value_Text__c) || (Trigger.isUpdate && ((String)so.get('TeamMemberRole') == teamRolerec.Value_Text__c && (String)oldMap.get(so.Id).get('TeamMemberRole') != (String)so.get('TeamMemberRole') || (String)oldMap.get(so.Id).get('TeamMemberRole') == teamRolerec.Value_Text__c && (String)oldMap.get(so.Id).get('TeamMemberRole') != (String)so.get('TeamMemberRole')))){

                teamMembersIdList.add(so.Id);
            }  
             
            
        }
        //Creating Map of Account Team Member Vs Account Status
        List<AccountTeamMember> teamMemberList= [Select Id,AccountId,Account.Type,Account.OwnerId,UserId,TeamMemberRole from AccountTeamMember where Id IN:teamMembersIdList];
        for(AccountTeamMember iteratedTeamMember : teamMemberList){
            if(iteratedTeamMember.Account.Type.contains('- Active')){
                accountsIdList.add(iteratedTeamMember.AccountId);
                teamMemberVsAccountMap.put(iteratedTeamMember.Id,iteratedTeamMember.Account.OwnerId);
                recsToBeProcessed.add(iteratedTeamMember);
            }
        }
        //Creating map of Account vs List of CNS
        List<Case_Notification_Subscription__c> existingCaseNotificationList = new List<Case_Notification_Subscription__c>();
        existingCaseNotificationList = [Select id,Account__c,User__c,Severity__c from Case_Notification_Subscription__c where Account__c IN: accountsIdList AND Case_Record_Type__c = 'All'];
        for(Case_Notification_Subscription__c iteratedCNS : existingCaseNotificationList){
            if(accountVsCaseNotificationList.containsKey(iteratedCNS.Account__c)){
                accountVsCaseNotificationList.get(iteratedCNS.Account__c).add(iteratedCNS);
            }else{
                List<Case_Notification_Subscription__c> tempList = new List<Case_Notification_Subscription__c>();
                tempList.add(iteratedCNS);
                accountVsCaseNotificationList.put(iteratedCNS.Account__c,tempList);
            }
        }
        for(AccountTeamMember atm: recsToBeProcessed)
        {
           
            Case_Notification_Subscription__c CNSToBeUpdated = new Case_Notification_Subscription__c();
            Case_Notification_Subscription__c CNSToBeDeleted = new Case_Notification_Subscription__c();
           
           
            //Validating if added /updated team member is present as subscriber and creating / updating CNS based on that.
          
            if(accountVsCaseNotificationList.containsKey(atm.AccountId)){
                for(Case_Notification_Subscription__c iteratedCNS : accountVsCaseNotificationList.get(atm.AccountId)){
                    if(iteratedCNS.User__c == atm.UserId && atm.TeamMemberRole == teamRolerec.Value_Text__c){
                      
                        CNSToBeUpdated = iteratedCNS;
                        break;
                    }else if(iteratedCNS.User__c == atm.UserId && atm.TeamMemberRole != teamRolerec.Value_Text__c && atm.UserId != teamMemberVsAccountMap.get(atm.Id)){
                        CNSToBeDeleted = iteratedCNS;
                    }
                }
            } 
           
            if(String.isBlank(CNSToBeDeleted.Id)){
                if(atm.TeamMemberRole == teamRolerec.Value_Text__c){
                    if(!String.isBlank(CNSToBeUpdated.Id)){
                        caseNotificationSubsListToUpdate.add(AccountTriggerClass.genericMethodForCNSCreateUpdate(CNSToBeUpdated,atm.UserId,atm.AccountId));
                    }else{
                        caseNotificationSubsList.add(AccountTriggerClass.genericMethodForCNSCreateUpdate(CNSToBeUpdated,atm.UserId,atm.AccountId));
                    }
                }   
            }else{
                caseNotificationSubsListToDelete.add(CNSToBeDeleted);
            }
           
           
        } 
        //Deleting CNS records
        if(caseNotificationSubsListToDelete.size() > 0){
            delete(caseNotificationSubsListToDelete);
      }
        //Inserting new CNS records
         if(caseNotificationSubsList.size() > 0){
               insert(caseNotificationSubsList);
         }
        //Updating esisting CNS records
         if(caseNotificationSubsListToUpdate.size() > 0){
             update(caseNotificationSubsListToUpdate); 
         }

    }
    // Vishnu Sharma - End - ESESP-1588
    public override void beforeDeleteBeforeUndeleteTrigger()
    {
          
    }
    
    public override void afterDeleteAfterUndeleteTrigger()
    {
        List<AccountTeamMember> atmTriggerOld = (List<AccountTeamMember>)oldList;
		List<Case_Notification_Subscription__c> cnsToDelete = new List<Case_Notification_Subscription__c>();
        Map<Id,Id> userIdWithAccIdMap = new Map<Id,Id>();
        
        if(Trigger.isDelete && Trigger.isAfter)
        {
            SC_Utility__mdt teamRolerec = [Select Id,Value_Text__c from SC_Utility__mdt where Label = 'CXM value team role' limit 1];
            for(AccountTeamMember atm : atmTriggerOld)
            {
                if( atm.TeamMemberRole == teamRolerec.Value_Text__c)
                	userIdWithAccIdMap.put(atm.UserId, atm.AccountId);
            }
        }
       
        if(userIdWithAccIdMap.size()>0){
            for( Case_Notification_Subscription__c cns : [Select Id,Account__c,User__c FROM Case_Notification_Subscription__c
                                                         WHERE User__c IN: userIdWithAccIdMap.keySet() OR Account__c in: userIdWithAccIdMap.values()]){
                if( userIdWithAccIdMap.containsKey(cns.User__c) && userIdWithAccIdMap.get(cns.User__c) == cns.Account__c ){
                    cnsToDelete.add(cns);
                }
            }
            if(cnsToDelete.size()>0){
                delete cnsToDelete;
            }
        }
    }    
}