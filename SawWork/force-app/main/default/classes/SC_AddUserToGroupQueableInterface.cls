global class SC_AddUserToGroupQueableInterface implements Queueable{
    
    
    // Setting Error Message
    public static string errorMessage = '';
    public static string errorMsg = '';
    public static string errorMsgUserUpdate = '';
    
    public List<CollaborationGroupMember> validUserList;

    public static boolean isTestErrorFuture = false;
    public static List<Id> userUpdateIdSuccessList;
    // Constructer for setting the Parameters
    Public SC_AddUserToGroupQueableInterface(list<CollaborationGroupMember> collabGroupMemList){
        
        this.validUserList = collabGroupMemList;
    }
    
    // Default Constructer 
    Public SC_AddUserToGroupQueableInterface(){}
    
    // Execute Method for Queuable Interface
    public void execute(QueueableContext context) {
        
        processData();
        
    }
    
    // Method for processing the Request
    public void processData(){        

        if(validUserList.size()>0){
            
            database.SaveResult[] resultAtt =  database.Insert(validUserList,false);
            // Iterate through each returned result
            
            for (Database.SaveResult sr : resultAtt) {
                if (sr.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully added member to collaboration group: ' + sr.getId());
                }
                if(!sr.isSuccess() || isTestErrorFuture) {
                    // Operation failed, so get all errors 
                    List<String> allExceptionList = new List<String>();
                    String allExceptionString = '';
                    String errorMessage = '';
                    for(Database.Error err : sr.getErrors()) {
                        if(String.valueOf(err.getStatusCode()) != 'DUPLICATE_VALUE'){	
                            errorMessage = err.getMessage();
                            allExceptionString = 'The following error has occurred on adding member to collaboration group. \n' +
                                'Error: ' + errorMessage + '\n';
                            allExceptionList.add(allExceptionString);
                        } 
                    }
                    if(allExceptionList.size()>0){
                        for(string errStr : allExceptionList){
                            errorMsg += errStr + '\n';
                        }
                    }  
                }
            }

            if(errorMsg != Null && errorMsg != ''){
                sendEmail(errorMsg);
            } 
        }    
    }
     /*setting UserPreferencesDisableAllFeedsEmail to true for users
    public static void deactivateUserEmailPreference(list<user> userListForChatterEmailDeactivate){
        if(userListForChatterEmailDeactivate.size() > 0){
           database.SaveResult[] updateResult =  database.Update(userListForChatterEmailDeactivate,false);
           userUpdateIdSuccessList = new List<id>();
            for (Database.SaveResult res : updateResult) {
                if (res.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully updated member UserPreferencesDisableAllFeedsEmail: ' + res.getId());
                    userUpdateIdSuccessList.add(res.getId());
                }
            
            if(!res.isSuccess() || isTestErrorFuture) {
                    // Operation failed, so get all errors 
                    List<String> allExceptionList = new List<String>();
                    String allExceptionString = '';
                    String errorMessage = '';
                    for(Database.Error err : res.getErrors()) {
                            errorMessage = err.getMessage();
                            allExceptionString = 'The following error has occurred on updating member UserPreferencesDisableAllFeedsEmail. \n' +
                                'Error: ' + errorMessage + '\n';
                            allExceptionList.add(allExceptionString);
                    }
                    if(allExceptionList.size()>0){
                        for(string errStr : allExceptionList){
                            errorMsgUserUpdate += errStr + '\n';
                        }
                    }  
                }
            }

            if(errorMsgUserUpdate != Null && errorMsgUserUpdate != ''){
                sendEmail(errorMsgUserUpdate);
            } 
        }
        
    }
     //setting UserPreferencesDisableAllFeedsEmail to false for users
   // public static void activateUserEmailPreference(list<Id> userListForChatterEmailActivate){
        List<User> userChatterEmailActivateList = new List<user>();
        for(Id eachMember :userListForChatterEmailActivate){
            User u = new User();
            u.Id = eachMember;
            u.UserPreferencesDisableAllFeedsEmail = false;
            userChatterEmailActivateList.add(u);
        }
        if(userChatterEmailActivateList.size() > 0){
            //deactivateUserEmailPreference(userChatterEmailActivateList);
        } 
    }*/
    
    
    public static void sendEmail(string errMsg){
   		 String errorMessage = 	'Instance = ' + URL.getSalesforceBaseUrl().toExternalForm() + '\n' +
                    'Batch Class Name = SC_AddCommunityUserToGroupBatch\n' + 
                    'Support Class Name = SC_AddUserToGroupQueableInterface\n' +
                    'Method Name = processData\n' +
                    'Error Message Queueable Call =' + errorMsg;
                
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