public class SC_AddCommunityUserToGroups {
    
    public static list<User> employeeList = new List<User>();
    public static list<User> customerList = new List<User>();
    public static list<User> partnerList = new List<User>();
    public static list<User> guestList = new List<User>();
    public static list<User> allRegisteredUserList = new List<User>();
    public static list<User> allRegistWithoutGuestList = new List<User>();
    public static string errorMsg = '';
    public static boolean isFirstRun = true;
    @testVisible public static boolean isTestError = false;
    
    public static void findUserType(list<User> userList){}/*
        
        if(isFirstRun){
            List<User> allUserList = new List<User>([Select id,companyName,email,contactId,Contact.Account.isPartner,Contact.Account.Name,Profile.Name,Name,UserName,Alias,IsActive from User where ID IN :userList]);
            SFCommunity_NQLB_Topics__mdt  communityMdt = [SELECT EmployeePublicGroupId__c,EnableAutoAddUserToGroupTrigger__c,CustomerPublicGroupId__c,PartnerPublicGroupId__c,GuestPublicGroupId__c,AllRegisteredCollabGroupId__c, AllRegExceptGuestCollabGroupId__c FROM SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'CommunityNQLB' limit 1];
            if(communityMdt.EnableAutoAddUserToGroupTrigger__c){
                for(User eachUser :allUserList){

                    if(eachUser.companyName != null && eachUser.companyName.containsIgnoreCase('Akamai') && eachUser.email.contains('@akamai.com')){
                        System.debug('----employeeList----'+eachUser);
                        employeeList.add(eachUser);
                        allRegisteredUserList.add(eachUser);
                        allRegistWithoutGuestList.add(eachUser);
                    }
                    else if(eachUser.contactId != Null && eachUser.Contact.Account.IsPartner && !eachUser.Contact.Account.Name.contains('Akamai Technologies - Assets')){
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
                    
                    addMemberToCollabGroup(allRegisterUserString,communityMdt.AllRegisteredCollabGroupId__c);
                }
                if(allRegistWithoutGuestList.size() > 0){
                    String allRegisterUserWithGuestStr = '';
                    for(user eachUser :allRegisteredUserList){
                        allRegisterUserWithGuestStr += eachUser.Id+',';

                        
                    }
                    allRegisterUserWithGuestStr = allRegisterUserWithGuestStr.removeEnd(',');
                    allRegisterUserWithGuestStr = allRegisterUserWithGuestStr.trim();
                    
                    addMemberToCollabGroup(allRegisterUserWithGuestStr,communityMdt.AllRegExceptGuestCollabGroupId__c);
                }
            }
        }
        isFirstRun = false;   
    }
    public static void addMemberToPublicGroup(list<User> userListToAdd, id publicGroupId){  
        List<GroupMember> groupMemberlist = new List<GroupMember>();
        for(User eachUser : userListToAdd) {
            if(eachUser.isActive) {
                GroupMember grpMember = new GroupMember();
                grpMember.GroupId = publicGroupId;
                grpMember.UserOrGroupId = eachUser.Id;
                groupMemberlist.add(grpMember);         
            }
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
                    /* Operation failed, so get all errors 
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
            sendEmailforException(errorMsg);
        }        
    }
    
    @future
    public static void addMemberToCollabGroup(String userListString, String collabIdString){
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
        for(id eachCollabId :collaborationList){
            for(Id eachUser :userList){
                CollaborationGroupMember cgMember = new CollaborationGroupMember();   
                cgMember.CollaborationGroupId = eachCollabId;
                cgMember.MemberId = eachUser;
                cgMember.CollaborationRole = 'Standard';
                cgMember.NotificationFrequency = 'N';
                collabGroupMemList.add(cgMember);
            } 
        }
        
        if(collabGroupMemList.size()>0){
            database.SaveResult[] resultAtt =  database.Insert(collabGroupMemList,false);
            // Iterate through each returned result
            
            for (Database.SaveResult sr : resultAtt) {
                if (sr.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully added member to collaboration group: ' + sr.getId());
                }
                if(!sr.isSuccess() || isTestError) {
                    // Operation failed, so get all errors 
                    List<String> allExceptionList = new List<String>();
                    String allExceptionString = '';
                    String errorMessage = '';
                    for(Database.Error err : sr.getErrors()) {
                        errorMessage = err.getMessage();
                        allExceptionString = 'The following error has occurred on adding member to collaboration group. \n' +
                            'Error: ' + errorMessage + '\n';
                        allExceptionList.add(allExceptionString);
                        
                    }
                    for(string errStr : allExceptionList){
                        errorMsg += errStr + '\n';
                    } 
                    
                }
            }
            //
            sendEmailforException(errorMsg);
        }   
    }
    
    
    //Method to send email when exception occurs
    public static void sendEmailforException(String body){
        String errorMessage = 	'Instance = ' + URL.getSalesforceBaseUrl().toExternalForm() + '\n' +
            'Class Name = SC_AddCommunityUserToGroup\n' + 
            'Method Name = findUserType\n' +
            'Error Message =' + body;
        
        //Get the to address
        SFCommunity_NQLB_Topics__mdt emailSettings = [SELECT ExceptionEmailToAddress__c FROM SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'CommunityNQLB' limit 1];
        
        String[] toAdd = new String[] {};
            toAdd.add(emailSettings.ExceptionEmailToAddress__c);
        
        // Sending Email
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(toAdd);
        mail.subject = 'Exception: In class - SC_AddCommunityUserToGroup';
        mail.plainTextBody = errorMessage;
        Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail}); 
        
    }*/
    
}