/**
 * Appirio | Dharmesh Patel | Initital Development
 * Trigger to check if Communities' User has updated username. if yes, does the username have ".akamai" append at the end? 
 * if not, append ".akamai" at the end of user name. 
 */
trigger CommunitiesUserTrigger_bu on User (before update) {
    Communities_Settings__c cs = Communities_Settings__c.getInstance('Community');
    String appendValue;
    String accountId;
    if(cs != null){
        appendValue = (cs.User_Name_Append_Value__c != null) ? cs.User_Name_Append_Value__c.toLowerCase() : ''; 
        accountId = cs.Communities_User_Account_Id__c;
    }
    Set<String> setContactIds = New Set<String>();
    for (User u: Trigger.new){
        setContactIds.add(u.ContactId);
    }
    
    Set<String> setCommunityUsersContactIds = New Set<String>();
    for (Contact c: [Select AccountId, Id From Contact Where Id in :setContactIds And AccountId = :accountId]){
     	  setCommunityUsersContactIds.add(c.Id);
    }
    
    for (User u: Trigger.new){
        if (Trigger.oldMap.get(u.Id).username != u.username && setCommunityUsersContactIds.contains(u.ContactId)){
            if (!u.username.toLowerCase().endsWith(appendValue)){
                u.username = u.username + appendValue;
            }
        }
    }
}