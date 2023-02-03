public class SC_Community_Document_Trigger_Helper {
    @testVisible static string errorMsg = '';
    @testVisible static string testError = '';
    public static void createDocumentShare(Map<Id,Set<id>> colGroupMemberMap, list<Customer_Community_Document__c> docList,List<Id> userWithAccess,Map<Id,List<Id>> shareRecordGroupIdMap){
        
        //Document Share list
        List<Customer_Community_Document__Share> sharesToCreate = new List<Customer_Community_Document__Share>();
        //Sharing record to each member of the group
        if (!colGroupMemberMap.isEmpty()) {
            for(Customer_Community_Document__c eachRecord : docList){
                if(shareRecordGroupIdMap.containsKey(eachRecord.Id)){
                    for(id eachGroup : shareRecordGroupIdMap.get(eachRecord.Id)){
                        if(colGroupMemberMap.containsKey(eachGroup)){
                            for(id eachMember :colGroupMemberMap.get(eachGroup)){
                                if(!userWithAccess.contains(eachMember)){
                                    Customer_Community_Document__Share cs = new Customer_Community_Document__Share();
                                    cs.AccessLevel = 'Edit';
                                    cs.ParentId = eachRecord.Id;
                                    cs.UserOrGroupId = eachMember;
                                    sharesToCreate.add(cs);
                                }
                            }
                        }
                    }
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
                if(!sr.isSuccess() || testError != ''){
                    // Operation failed, so get all errors 
                    List<String> allCaseExceptionList = new List<String>();
                    String allCaseExceptionString = '';
                    String errorMessage = '';
                    for(Database.Error err : sr.getErrors()) {
                        errorMessage = err.getMessage()+'::::'+err.getFields()+'::::'+err.fields;
                        allCaseExceptionString = 'The following error has occurred on Document Share insertion. \n' +'Error: ' + errorMessage + '\n';
                        allCaseExceptionList.add(allCaseExceptionString);
                        
                    }
                    if(allCaseExceptionList.size()>0){
                    	for(string errStr : allCaseExceptionList){
                        	errorMsg += errStr + '\n';
                    	} 
                    }
                }
            }
        }
        If(errorMsg != ''){
            SFCommunity_NQLB_Topics__mdt  communityExceptionEmail = [SELECT ExceptionEmailToAddress__c FROM SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'CommunityNQLB' limit 1];
            // Setting To Address
            String[] toAdd = new String[] {};
                toAdd.add(communityExceptionEmail.ExceptionEmailToAddress__c);
            
            // Sending Email
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(toAdd);
            mail.subject = 'Error: Community Document Share';
            mail.plainTextBody = errorMsg;
            Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail}); 
            
        }
    } 
    
}