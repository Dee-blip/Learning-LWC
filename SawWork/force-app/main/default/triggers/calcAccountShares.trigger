/*  
    Trigger to calc account shares for all child accounts for a newly partner enabled account and
    newly partner enabled contacts. When a new partner user is created, check if other users 
    in same account exist. If no, then get role for that user's account and create shares for all child 
    accounts under that account.  
*/
trigger calcAccountShares on User (after insert) {
    Set<Id> accIds = new Set<Id>();
    Map<String, Default__c> accessSettingsMap = Default__c.getAll();
    
    //always have partner portal is enabled.
    String criteria = 'Contact.Account.IsPartner = true';
    GroupSharingHelper.userTypes.add('PowerPartner');
    
    if(accessSettingsMap.containsKey('Default')){
        Default__c settings = accessSettingsMap.get('Default');
        if(settings.is_Customer_Portal_Enabled__c){
            GroupSharingHelper.userTypes.add('PowerCustomerSuccess');
            GroupSharingHelper.userTypes.add('CustomerSuccess');
            criteria = '(Contact.Account.IsPartner = true or Contact.Account.IsCustomerPortal = true)';
        }
        if(settings.is_Partner_Portal_Enabled__c){
            GroupSharingHelper.userTypes.add('PowerPartner');
        }
    }
    Map<Id,User> partnerUsers ;
    String cond = GroupSharingHelper.join(accIds, ',', '\'') ;
    if(cond == ''){
        cond = '\'\'';
    }
    String pquery = 'select Id, Contact.AccountId from User where Contact.AccountId in (' + cond + ')'+ 
                'and ' + criteria;
    if(!GroupSharingHelper.ISTEST){
        partnerUsers = new Map<Id,User>([Select Id, Contact.AccountId from User 
                                                    where Contact.AccountId != null 
                                                    And Id In :trigger.newMap.keySet()
                                                    And UserType in :GroupSharingHelper.userTypes]); //allowing for customer portal users added by Ankita 4/13/2010
    }else{
        partnerUsers = new Map<Id,User>([Select Id, Contact.AccountId from User 
                                                    where Contact.AccountId != null 
                                                    And Id In :trigger.newMap.keySet()
                                                    And UserType in :GroupSharingHelper.userTypes limit 10]);
        pquery = pquery + ' limit 10';                                           
    }
    for(User u : partnerUsers.values()){
        //check if user is partner user
            accIds.add(u.Contact.AccountId);
    }
    Map<Id,List<User>> accUserMap = new Map<Id, List<User>>(); 
    /*[select Id, Contact.AccountId from User where Contact.AccountId in :accIds 
                    and (Contact.Account.IsPartner = true or Contact.Account.IsCustomerPortal = true)]*/            
    for(User u : Database.query(pquery)){ 
    //only those accounts that are partner enabled or customer portal enabled - added customer portal check by Ankita 4/13/2010 for CP support 
        List<User> users = new List<User>();
        if(accUserMap.containsKey(u.Contact.AccountId)){
            users = accUserMap.get(u.Contact.AccountId);
            users.add(u);
        }else{
            users.add(u);
        }
        accUserMap.put(u.Contact.AccountId, users);
    } 
    Set<Id> processAccIds = new Set<Id>();
    for(Id id : accUserMap.keySet()){
        if(accUserMap.get(id).size() == 1){
            //add this account to the list of accids to be processed
            processAccIds.add(id);
        }
    }
    if(processAccIds.size() > 0){
        List<Id> accIdsForRoles = new List<Id>(processAccIds);
        Map<Id,Id> accountIdUserRoleIdMap = GroupSharingHelper.getRoles(accIdsForRoles, 'Partner');
        Map<Id,Id> gMap = GroupSharingHelper.getGroups(accountIdUserRoleIdMap.values());
        GroupSharing.calcChildSharesFromUser(processAccIds, accountIdUserRoleIdMap, gMap, 'add');
    }
}