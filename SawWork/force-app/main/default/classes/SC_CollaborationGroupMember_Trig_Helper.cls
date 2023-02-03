public class SC_CollaborationGroupMember_Trig_Helper {
    @testVisible static string errorMsg = '';
    @testVisible static string testError = '';
    
    public static void shareDocWithCollaborationMember(Map<Id,List<Id>> userDocumentMap){
        List<Customer_Community_Document__Share> sharesToCreate = new List<Customer_Community_Document__Share>();
        if(!userDocumentMap.isEmpty()){
            for(id eachUser :userDocumentMap.keyset()){
                for(id eachDoc :userDocumentMap.get(eachUser)) {
                    Customer_Community_Document__Share cs = new Customer_Community_Document__Share();
                    cs.AccessLevel = 'Edit';
                    cs.ParentId = eachDoc;
                    cs.UserOrGroupId = eachUser;
                    sharesToCreate.add(cs);
                }
            }
        }
        
        // do the DML to create shares
        if (!sharesToCreate.isEmpty()){
            //insert sharesToCreate;
            system.debug('------sharesToCreate----'+sharesToCreate);
            database.SaveResult[] resultShare =  database.Insert(sharesToCreate,false);
            // Iterate through each returned result
            List<Id> successCaseList = new List<Id>();
            
            for (Database.SaveResult sr : resultShare) {
                if (sr.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully inserted Document Share. Document Share ID: ' + sr.getId());
                    successCaseList.add(sr.getId());
                }
                if(!sr.isSuccess() || testError != '') {
                    // Operation failed, so get all errors 
                    List<String> allCaseExceptionList = new List<String>();
                    String allCaseExceptionString = '';
                    String errorMessage = '';
                    for(Database.Error err : sr.getErrors()) {
                        errorMessage = err.getMessage()+'::::'+err.getFields()+'::::'+err.fields;
                        allCaseExceptionString = 'The following error has occurred on Document Share insertion. \n' +
                            'Error: ' + errorMessage + '\n';
                        allCaseExceptionList.add(allCaseExceptionString);
                        
                    }
                    for(string errStr : allCaseExceptionList){
                        errorMsg += errStr + '\n';
                    } 
                }
            }
        }
        If(errorMsg != ''){
            sendEmailOnError('Error: Community Collaboration Group Member Addition Document Permission',errorMsg);            
        }
    }
    
    public static void deleteDocShareFromExitGroupUser(List<Customer_Community_Document__Share> documentListdeletion){
        List<id> documentShareIdList = new List<id>();
        if(documentListdeletion.size()>0){
            for(Customer_Community_Document__Share eachShare :documentListdeletion){
                documentShareIdList.add(eachShare.id);
            }
        }
        if(documentListdeletion.size() >0){
            
            database.DeleteResult[] resultShare =  database.Delete(documentListdeletion,false);
            for (Database.DeleteResult sr : resultShare) {
                if (sr.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully Deleted Document Share. Document Share ID: ' + sr.getId());
                }
                if(!sr.isSuccess() || testError != '') {
                    // Operation failed, so get all errors 
                    List<String> allCaseExceptionList = new List<String>();
                    String allCaseExceptionString = '';
                    String errorMessage = '';
                    for(Database.Error err : sr.getErrors()) {
                        errorMessage = err.getMessage()+'::::'+err.getFields()+'::::'+err.fields;
                        allCaseExceptionString = 'Error: Community Collaboration Group Member Deletion Document Permission . \n' +
                            'Error: ' + errorMessage + '\n';
                        allCaseExceptionList.add(allCaseExceptionString);
                        
                    }
                    for(string errStr : allCaseExceptionList){
                        errorMsg += errStr + '\n';
                    } 
                }
            }
            
            If(errorMsg != ''){
                sendEmailOnError('Error: Community Collaboration Group Member Deletion Document Permission ',errorMsg);
            }
        }
    }
    
    public static void sendEmailOnError(String Subject, String ErrorMsg){
        SFCommunity_NQLB_Topics__mdt  communityExceptionEmail = [SELECT ExceptionEmailToAddress__c FROM SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'CommunityNQLB' limit 1];
        // Setting To Address
        String[] toAdd = new String[] {};
        toAdd.add(communityExceptionEmail.ExceptionEmailToAddress__c);
        
        // Sending Email
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(toAdd);
        mail.subject = Subject;
        mail.plainTextBody = ErrorMsg;
        Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
        
    }
}