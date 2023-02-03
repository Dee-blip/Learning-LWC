public class SC_AddCommunityUserToGroupController {
    //string to store Error Message
    public string errorMsg = '';
    public list<User> employeeList = new List<User>();
    public list<User> customerList = new List<User>();
    public list<User> partnerList = new List<User>();
    public list<User> guestList = new List<User>();
    public list<User> allRegisteredUserList = new List<User>();
    public list<User> allRegistWithoutGuestList = new List<User>();
    public boolean isTestError = false;
    public static boolean isTestErrorFuture = false;
    public static string errorMsgFuture = '';
    public list<CollaborationGroupMember> returnUserList = new List<CollaborationGroupMember>();
    
    //Main Method
    public list<CollaborationGroupMember> addUserToGroup(list<User> userList){
        
        SFCommunity_NQLB_Topics__mdt  communityMdt = [SELECT EmployeePublicGroupId__c,EnableAutoAddUserToGroupTrigger__c,CustomerPublicGroupId__c,PartnerPublicGroupId__c,GuestPublicGroupId__c,AllRegisteredCollabGroupId__c, AllRegExceptGuestCollabGroupId__c FROM SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'CommunityNQLB' limit 1];
        for(User eachUser :userList){
            
            if(eachUser.companyName != null && eachUser.companyName.containsIgnoreCase('Akamai') && eachUser.email.contains('@akamai.com')){
                System.debug('----employeeList----'+eachUser);
                employeeList.add(eachUser);
                allRegisteredUserList.add(eachUser);
                allRegistWithoutGuestList.add(eachUser);
            }
            else if(eachUser.contactId != Null && ( eachUser.Profile.UserLicense.Name == 'Partner Community' || eachUser.profile.Name == 'SFCommunityPartners')){
                System.debug('----partnerList----'+eachUser);
                partnerList.add(eachUser);
                allRegisteredUserList.add(eachUser);
                allRegistWithoutGuestList.add(eachUser);
            }
            else if(eachUser.contactId != Null && eachUser.profile.Name == 'SFCommunityGuests'){
                System.debug('----guestList----'+eachUser);
                guestList.add(eachUser);
                allRegisteredUserList.add(eachUser);
            }
            else if(eachUser.contactId != Null && eachUser.profile.Name == 'SFCommunityCustomers'){
                System.debug('----customerList----'+eachUser);
                customerList.add(eachUser);
                allRegisteredUserList.add(eachUser);
                allRegistWithoutGuestList.add(eachUser);
            }
        }
        
        if(employeeList.size() > 0){
            addMemberToPublicGroup(employeeList,communityMdt.EmployeePublicGroupId__c);
        }
        if(partnerList.size() > 0){
            addMemberToPublicGroup(partnerList,communityMdt.PartnerPublicGroupId__c);
        }
        if(guestList.size() > 0){
            addMemberToPublicGroup(guestList,communityMdt.GuestPublicGroupId__c);
        }
        if(customerList.size() > 0){
            addMemberToPublicGroup(customerList,communityMdt.CustomerPublicGroupId__c);
        }
        if(allRegisteredUserList.size() > 0){
            String allRegisterUserString = '';
            for(user eachUser :allRegisteredUserList){
                allRegisterUserString += eachUser.Id+',';
                
            }
            allRegisterUserString = allRegisterUserString.removeEnd(',');
            allRegisterUserString = allRegisterUserString.trim();
            
            returnUserList = addMemberToCollabGroup(allRegisterUserString,communityMdt.AllRegisteredCollabGroupId__c);
        }
        if(allRegistWithoutGuestList.size() > 0){
            String allRegisterUserWithGuestStr = '';
            for(user eachUser :allRegistWithoutGuestList){
                allRegisterUserWithGuestStr += eachUser.Id+',';
                
            }
            allRegisterUserWithGuestStr = allRegisterUserWithGuestStr.removeEnd(',');
            allRegisterUserWithGuestStr = allRegisterUserWithGuestStr.trim();
            
            returnUserList.addAll(addMemberToCollabGroup(allRegisterUserWithGuestStr,communityMdt.AllRegExceptGuestCollabGroupId__c));
        }
        
        return returnUserList;
    }
    
    public void addMemberToPublicGroup(list<User> userListToAdd, id publicGroupId){
        list<User> userWithoutGroup = new list<User>();
        List<GroupMember> groupMemberlist = new List<GroupMember>();
        //List<GroupMember> groupMemList = new List<GroupMember>([Select GroupId,UserOrGroupId from GroupMember where groupId=:publicGroupId]);
        
        List<GroupMember> existingGroupMemList = new List<GroupMember>([Select GroupId,UserOrGroupId from GroupMember where groupId=:publicGroupId and UserOrGroupId in:(userListToAdd)]);
        if(existingGroupMemList.size() > 0) {
            for(user eachUsr :userListToAdd){
                boolean userFound = false;
                for(GroupMember eachMem :existingGroupMemList){
                    if((string.valueOf(eachUsr).startsWith('005')) && eachMem.UserOrGroupId == eachUsr.Id){
                        userFound = true;
                        break;
                    }
                }
                if(!userFound){
                    userWithoutGroup.add(eachUsr);
                }
            }
        }
        else{
            userWithoutGroup.addAll(userListToAdd);
        }
        
        /*if(groupMemList.size() > 0) {
            for(user eachUsr :userListToAdd){
                boolean userFound = false;
                for(GroupMember eachMem :groupMemList){
                    if((string.valueOf(eachUsr).startsWith('005')) && eachMem.UserOrGroupId == eachUsr.Id){
                        userFound = true;
                        break;
                    }
                }
                if(!userFound){
                    userWithoutGroup.add(eachUsr);
                }
            }
        }*/
        
        for(user eachUserWithoutGrp : userWithoutGroup){
            GroupMember grpMember = new GroupMember();
            grpMember.GroupId = publicGroupId;
            grpMember.UserOrGroupId = eachUserWithoutGrp.Id;
            groupMemberlist.add(grpMember);   
        }
        
        if(groupMemberlist.size()>0){
            database.SaveResult[] resultAtt =  database.Insert(groupMemberlist,false);
            // Iterate through each returned result
            
            for (Database.SaveResult sr : resultAtt) {
                if (sr.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully added member to public group: ' + sr.getId());
                }
                if(!sr.isSuccess() || isTestError) {
                    // Operation failed, so get all errors 
                    List<String> allExceptionList = new List<String>();
                    String allExceptionString = '';
                    String errorMessage = '';
                    for(Database.Error err : sr.getErrors()) {
                        errorMessage = err.getMessage();
                        allExceptionString = 'The following error has occurred on adding member to public group. \n' +
                            'Error: ' + errorMessage + '\n';
                        allExceptionList.add(allExceptionString);
                        
                    }
                    for(string errStr : allExceptionList){
                        errorMsg += errStr + '\n';
                    } 
                }
            }
            if(errorMsg != Null && errorMsg != ''){
                String errorMessage = 	'Instance = ' + URL.getSalesforceBaseUrl().toExternalForm() + '\n' +
                    'Batch Class Name = SC_AddCommunityUserToGroupBatch\n' + 
                    'Support Class Name = SC_AddCommunityUserToGroupController\n' +
                    'Method Name = addUserToGroup\n' +
                    'Error Message =' + errorMsg;
                
                //Get the to address
                SFCommunity_NQLB_Topics__mdt emailSettings = [SELECT ExceptionEmailToAddress__c FROM SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'CommunityNQLB' limit 1];
                
                String[] toAdd = new String[] {};
                    toAdd.add(emailSettings.ExceptionEmailToAddress__c);
                
                // Sending Email
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(toAdd);
                mail.subject = 'Exception: In Batch Job - SC_AddCommunityUserToGroupBatch';
                mail.plainTextBody = errorMessage;
                Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail}); 
            } 
        }
    }
    
    
    public list<CollaborationGroupMember> addMemberToCollabGroup(String userListString, String collabIdString){
        list<CollaborationGroupMember> collabGroupMemList = new List<CollaborationGroupMember>();
        List<Id> userList = new List<Id>();
        if(userListString != ''){
            for(string eachString :userListString.split(',')){
                userList.add(eachString); 
            } 
        }
        
        list<Id> collaborationList = new List<Id>();
        
        for(String eachString :collabIdString.split(',')){
            collaborationList.add(eachString.trim());
        }
        
        list<CollaborationGroupMember> colGrpMemList;
        Map<Id,list<id>> mapColGrpIdMemList = new Map<Id,list<id>>();
        
        for(id eachColGrpId :collaborationList){
            
            colGrpMemList = new List<CollaborationGroupMember>([Select MemberId,CollaborationGroupId from CollaborationGroupMember where CollaborationGroupId = :eachColGrpId and MemberId IN :userList]);        
            List<Id> usersIdList = new List<Id>();
            for(Id eachUser :userList){
                if(colGrpMemList.size()>0){
                    for(CollaborationGroupMember eachCol :colGrpMemList){
                        if(eachCol.MemberId != eachUser){
                            if(mapColGrpIdMemList.containsKey(eachCol.CollaborationGroupId)) {
                                List<Id> usersId = mapColGrpIdMemList.get(eachCol.CollaborationGroupId);
                                usersId.add(eachUser);
                                mapColGrpIdMemList.put(eachCol.CollaborationGroupId, usersId);
                            }
                            else {
                                mapColGrpIdMemList.put(eachCol.CollaborationGroupId, new List<Id> { eachUser });
                            } 
                        }
                    }
                }
                else{
                    usersIdList.add(eachUser);
                    mapColGrpIdMemList.put(eachColGrpId, usersIdList);
                }
            }
        }
        
        for(Id eachUser :userList){                
            for(id eachCollabId :mapColGrpIdMemList.keyset()){
                if(mapColGrpIdMemList.get(eachCollabId).contains(eachUser)){
                    
                    CollaborationGroupMember cgMember = new CollaborationGroupMember();   
                    cgMember.CollaborationGroupId = eachCollabId;
                    cgMember.MemberId = eachUser;
                    cgMember.CollaborationRole = 'Standard';
                    cgMember.NotificationFrequency = 'N';
                    collabGroupMemList.add(cgMember);
                    
                }
            }
        }
        return collabGroupMemList; 
    }   
}