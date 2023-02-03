/*Customer Community Component*/
public class SC_CommunityUserCreation {

    @future
    public static void createCommunityPortalUser(String commRegUserEmail){
        
        SFCommunity_NQLB_Topics__mdt  communityMetaDataVal = [SELECT DefaultAccountIdForNewContact__c,Guest_Profile__c,ExceptionEmailToAddress__c,SendMassUserEmail__c  FROM SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'CommunityNQLB' limit 1];
        
        String errorMsg = '';
        
        List<Id> sendResetEmailUserList = new List<Id>();
        
        List<User> userList = new List<User>();
        
        List<Contact> contactList = new List<Contact>();

        profile guestProfile = [SELECT id,name from profile where name = :communityMetaDataVal.Guest_Profile__c];
        
        List<string> contEmailList = new List<String>();
        for(String eachCommReg :commRegUserEmail.split(',')){            
            contEmailList.add(eachCommReg);
        }
        if(contEmailList.size()>0){
            contactList = [Select Id,FirstName,LastName,Email,LinkedIn__c,MailingCountry,MailingState,AKAM_Contact_Id__c from Contact where email IN:contEmailList and AccountId =:communityMetaDataVal.DefaultAccountIdForNewContact__c];
            if(contactList.size() == 0){
              contactList = [Select Id,FirstName,LastName,Email,LinkedIn__c,MailingCountry,MailingState,AKAM_Contact_Id__c from Contact where email IN:contEmailList];  
            }
        }
        User usr;
        
        for(Contact eachContact : contactList){
            usr = new User();
            usr.Username = eachContact.Email;
            usr.Email = eachContact.Email ;
            usr.alias = eachContact.lastname.length() > 3 ? 'CCM-'+(eachContact.FirstName.substring(0,1) + eachContact.LastName.substring(0,2)) : 'CCM-'+(eachContact.FirstName.substring(0,1) + eachContact.LastName); 
            system.debug('----alias---'+usr.alias);
            String nickname = ((eachContact.firstname != null && eachContact.firstname.length() > 0) ? eachContact.firstname.substring(0,1) : '' ) + eachContact.lastname.substring(0,1);
            nickname += String.valueOf(Crypto.getRandomInteger()).substring(1,7);
            usr.CommunityNickname = nickname;
            usr.ProfileId = guestProfile.Id;
            usr.LastName = eachContact.LastName;
            usr.FirstName = eachContact.FirstName;
            usr.LinkedIn_URL__c = eachContact.LinkedIn__c;
            usr.IsActive = true;
            usr.ContactId = eachContact.Id;
            usr.AKAM_User_Id__c = eachContact.AKAM_Contact_Id__c;
            usr.Country = eachContact.MailingCountry;
            usr.State = eachContact.MailingState;
            usr.LanguageLocaleKey='en_US';
            usr.LocaleSidKey='en_US';
            usr.EmailEncodingKey='UTF-8';
            usr.TimeZoneSidKey='America/Los_Angeles';
            usr.FederationIdentifier = eachContact.AKAM_Contact_Id__c;
            userList.add(usr);
            
        }
        
        if(userList.size()>0){
            database.SaveResult[] resultUser =  database.Insert(userList,false);
            // Iterate through each returned result
            for (Database.SaveResult sr : resultUser) {
                if (sr.isSuccess()) {
                    sendResetEmailUserList.add(sr.getId());
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully inserted user. User Id: ' + sr.getId());
                }
                else {
                    // Operation failed, so get all errors 
                    List<String> allCaseExceptionList = new List<String>();
                    String allCaseExceptionString = '';
                    String errorMessage = '';
                    for(Database.Error err : sr.getErrors()) {
                        errorMessage = err.getMessage();
                        allCaseExceptionString = 'The following error has occurred on User insertion. \n' +
                            'Error: ' + errorMessage + '\n';
                        allCaseExceptionList.add(allCaseExceptionString);
                        
                    }
                    for(string errStr : allCaseExceptionList){
                        errorMsg += errStr + '\n';
                    } 
                }
            }
            
            if(errorMsg != null && errorMsg != '')
                sendEmailForError('Error:Community Approved User Creation Error',errorMsg);
            
            if(communityMetaDataVal.SendMassUserEmail__c && sendResetEmailUserList.size()>0)
                resetUserPasswordAndSendEmail(sendResetEmailUserList,communityMetaDataVal.SendMassUserEmail__c);
        }
    }
    
    
    public static void resetUserPasswordAndSendEmail(List<id> userIdList, boolean sendEmailAfterReset){
        Map<Id,String> userIdWithPassword = new Map<Id,String>();
        for(id eachUserId :userIdList){
            system.ResetPasswordResult	res = system.resetPassword(eachUserId,sendEmailAfterReset);
            userIdWithPassword.put(eachUserId,res.getPassword());
        }  
        //if(userIdWithPassword.size() >0)
            //updatePasswordOnRegObj(userIdWithPassword);
    }
    
    /*Storing first password to send in email seperately.
    public static void updatePasswordOnRegObj(Map<Id,String> userIdWithPassword){

        list<User> regUserList = new List<User>();
        User eachRegRec;
        for(id eachUserId :userIdWithPassword.keyset()){
            eachRegRec = new User();
            eachRegRec.Guest_User_Cust_Community_Password__c  = userIdWithPassword.get(eachUserId);//InitialResetPassword__c = userIdWithPassword.get(eachUserId);
            eachRegRec.Id = eachUserId;//regUserMap.get(eachUserId);
            regUserList.add(eachRegRec);
        }
        if(regUserList.size()>0){
            
            database.SaveResult[] resultUser =  database.Update(regUserList,false);
            String errorPassUpdateMsg ='';
            // Iterate through each returned result
            for (Database.SaveResult sr : resultUser) {
                if (sr.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully inserted User. User ID: ' + sr.getId());
                }
                else {
                    // Operation failed, so get all errors 
                    List<String> exceptionList = new List<String>();
                    String exceptionString = '';
                    String errorMessage = '';
                    for(Database.Error err : sr.getErrors()) {
                        errorMessage = err.getMessage();
                        exceptionString = 'The following error has occurred on Registered User Password Update. \n' +
                            'Error: ' + errorMessage + '\n';
                        exceptionList.add(exceptionString);
                        
                    }
                    for(string errStr : exceptionList){
                        errorPassUpdateMsg += errStr + '\n';
                    } 
                }
            }
            if(errorPassUpdateMsg != null && errorPassUpdateMsg != '')
                sendEmailForError('Error:Community Approved User Creation Error',errorPassUpdateMsg);
            
        }
    }*/
    
    
    public static void sendEmailForError(string emailSubject, string emailBody){
 		SFCommunity_NQLB_Topics__mdt  communityExceptionEmail = [SELECT ExceptionEmailToAddress__c FROM SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'CommunityNQLB' limit 1];
        // Setting To Address
        String[] toAdd = new String[] {};
        toAdd.add(communityExceptionEmail.ExceptionEmailToAddress__c);

        // Sending Email
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(toAdd);
        mail.subject = emailSubject;
        mail.plainTextBody = emailBody;
        Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail}); 
        
    } 
}