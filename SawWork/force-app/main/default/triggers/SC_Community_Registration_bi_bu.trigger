/*Customer Community Component*/
trigger SC_Community_Registration_bi_bu on SC_Community_Registration__c (before update) {
    if(!UserInfo.getName().equalsIgnoreCase('Connection User')){
        if(Trigger.isBefore && Trigger.isUpdate){
            String userCreationEmailStr = '';
            for(SC_Community_Registration__c eachRec :Trigger.New){
                if(!Trigger.oldMap.get(eachRec.Id).IsApproved__c && eachRec.IsApproved__c && !eachRec.Reject__c){
                    userCreationEmailStr += eachRec.Email__c + ',';
                }       
                
            }
            if(userCreationEmailStr != Null && userCreationEmailStr != '' && !System.isFuture()){
                userCreationEmailStr = userCreationEmailStr.removeEnd(',').trim();
                SC_CommunityUserCreation.createCommunityPortalUser(userCreationEmailStr);
            }
        }
    }
}