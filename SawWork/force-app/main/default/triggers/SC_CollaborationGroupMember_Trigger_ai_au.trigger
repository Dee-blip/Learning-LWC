trigger SC_CollaborationGroupMember_Trigger_ai_au on CollaborationGroupMember (after insert,after update,before delete) {
    if(!UserInfo.getName().equalsIgnoreCase('Connection User')){
        string errorMsg = '';
        Map<Id,List<Id>> groupMemberListIdMap = new Map<Id,List<Id>>();
        List<Customer_Community_Document__Share> sharesToCreate = new List<Customer_Community_Document__Share>();
        SFCommunity_NQLB_Topics__mdt  communityMetaDataVal = [SELECT UserGroupWith10KMembers__c ,Case_Priority__c , Question_Hours_for_Case_Creation__c, Question_Community_Topic__c,CommunityNetworkId__c, Case_Visibility__c , Case_Severity__c ,DefaultAccountIdForNewContact__c,TopicName__c, DayRange__c FROM SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'CommunityNQLB' limit 1];
        
        If(Trigger.isInsert){
            for(CollaborationGroupMember eachRec : Trigger.New){
                if(!communityMetaDataVal.UserGroupWith10KMembers__c.contains(eachRec.CollaborationGroupId)){
                    if(groupMemberListIdMap.containsKey(eachRec.CollaborationGroupId)) {
                        List<Id> memberIdList = groupMemberListIdMap.get(eachRec.CollaborationGroupId);
                        memberIdList.add(eachRec.memberId );
                        groupMemberListIdMap.put(eachRec.CollaborationGroupId, memberIdList);
                    } 
                    else {
                        groupMemberListIdMap.put(eachRec.CollaborationGroupId, new List<Id> { eachRec.memberId });
                    }   
                }
            }
            
            Map<Id,List<Id>> documentGroupListMap = new Map<Id,List<Id>>();
            if(!groupMemberListIdMap.isEmpty()){
                for(Customer_Community_Document__c eachDocument  :[Select Id,Group_Id__c from Customer_Community_Document__c where Group_Id__c IN :groupMemberListIdMap.keySet() limit 50000]){
                    if(documentGroupListMap.containsKey(eachDocument.Id)) {
                        List<Id> groupList = documentGroupListMap.get(eachDocument.Id);
                        //for(string eachString :eachDocument.Group_Id__c.split(',')){
                        groupList.add(eachDocument.Group_Id__c);
                        // }
                        documentGroupListMap.put(eachDocument.Id, groupList);
                    } 
                    else {
                        List<Id> groupFirstList = new List<Id>();
                        //for(string eachString :eachDocument.Group_Id__c.split(',')){
                        groupFirstList.add(eachDocument.Group_Id__c);
                        //}
                        documentGroupListMap.put(eachDocument.Id,groupFirstList);
                    }
                }
            }
            
            Map<Id,List<Id>> userDocumentMap = new Map<Id,List<Id>>();
            // Iterating over document and group list it is shared with
            if(!documentGroupListMap.isEmpty()){
                for(id eachDocument :documentGroupListMap.keySet()){
                    // Iterating over each group to get its member
                    for(id eachGroup : documentGroupListMap.get(eachDocument)){
                        
                        if(groupMemberListIdMap.containsKey(eachGroup)){
                            for(id eachMember :groupMemberListIdMap.get(eachGroup)){
                                if(userDocumentMap.containsKey(eachMember)) {
                                    List<Id> docIdList = userDocumentMap.get(eachMember);
                                    docIdList.add(eachDocument);
                                    userDocumentMap.put(eachMember, docIdList);
                                } 
                                else {
                                    userDocumentMap.put(eachMember, new List<Id> { eachDocument });
                                }
                            }
                        }
                    }  
                }
            }
            
			if(!userDocumentMap.isEmpty()){
				SC_CollaborationGroupMember_Trig_Helper.shareDocWithCollaborationMember(userDocumentMap);
			}
            /*
                for(id eachUser :userDocumentMap.keyset()){
                    for(id eachDoc :userDocumentMap.get(eachUser)) {
                        Customer_Community_Document__Share cs = new Customer_Community_Document__Share();
                        cs.AccessLevel = 'read';
                        cs.ParentId = eachDoc;
                        cs.UserOrGroupId = eachUser;
                        sharesToCreate.add(cs);
                    }
                }
            }
            
            // do the DML to create shares
            if (!sharesToCreate.isEmpty()){
                //insert sharesToCreate;
                database.SaveResult[] resultShare =  database.Insert(sharesToCreate,false);
                // Iterate through each returned result
                List<Id> successCaseList = new List<Id>();
                
                for (Database.SaveResult sr : resultShare) {
                    if (sr.isSuccess()) {
                        // Operation was successful, so get the ID of the record that was processed
                        System.debug('Successfully inserted Document Share. Document Share ID: ' + sr.getId());
                        successCaseList.add(sr.getId());
                    }
                    else {
                        // Operation failed, so get all errors 
                        List<String> allCaseExceptionList = new List<String>();
                        String allCaseExceptionString = '';
                        String errorMessage = '';
                        for(Database.Error err : sr.getErrors()) {
                            errorMessage = err.getMessage();
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
                SFCommunity_NQLB_Topics__mdt  communityExceptionEmail = [SELECT ExceptionEmailToAddress__c FROM SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'CommunityNQLB' limit 1];
                // Setting To Address
                String[] toAdd = new String[] {};
                    toAdd.add(communityExceptionEmail.ExceptionEmailToAddress__c);
                
                // Sending Email
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(toAdd);
                mail.subject = 'Error: Community Collaboration Group Member Addition Document Permission';
                mail.plainTextBody = errorMsg;
                Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail}); 
                
            }*/

        }
        
        If(Trigger.isDelete){
            for(CollaborationGroupMember eachRec : Trigger.Old){
                if(!communityMetaDataVal.UserGroupWith10KMembers__c.contains(eachRec.CollaborationGroupId)){
                    if(groupMemberListIdMap.containsKey(eachRec.CollaborationGroupId)) {
                        List<Id> memberIdList = groupMemberListIdMap.get(eachRec.CollaborationGroupId);
                        memberIdList.add(eachRec.memberId );
                        groupMemberListIdMap.put(eachRec.CollaborationGroupId, memberIdList);
                    } 
                    else {
                        groupMemberListIdMap.put(eachRec.CollaborationGroupId, new List<Id> { eachRec.memberId });
                    }   
                }
            }
            
            
            Map<Id,List<Id>> documentGroupListMap = new Map<Id,List<Id>>();
            for(Customer_Community_Document__c eachDocument  :[Select Id,Group_Id__c from Customer_Community_Document__c limit 50000]){
                if(documentGroupListMap.containsKey(eachDocument.Id)) {
                    List<Id> groupList = documentGroupListMap.get(eachDocument.Id);
                    //for(string eachString :eachDocument.Group_Id__c.split(',')){
                        groupList.add(eachDocument.Group_Id__c);
                    
                    documentGroupListMap.put(eachDocument.Id, groupList);
                } 
                else {
                    List<Id> groupFirstList = new List<Id>();
                    system.debug('--Group_Id__c--'+eachDocument.Group_Id__c);
                   // for(string eachString :eachDocument.Group_Id__c.split(',')){
                        groupFirstList.add(eachDocument.Group_Id__c);
                    //
                    documentGroupListMap.put(eachDocument.Id,groupFirstList);
                }
            }
            
            Map<Id,List<Id>> userDocumentMap = new Map<Id,List<Id>>();
            // Iterating over document and group list it is shared with
            // 
            if(!documentGroupListMap.isEmpty()){
                for(id eachDocument :documentGroupListMap.keySet()){
                    // Iterating over each group to get its member
                    for(id eachGroup : documentGroupListMap.get(eachDocument)){
                        
                        if(!groupMemberListIdMap.isEmpty() && groupMemberListIdMap.containsKey(eachGroup)){
                            for(id eachMember :groupMemberListIdMap.get(eachGroup)){
                                if(userDocumentMap.containsKey(eachMember)) {
                                    List<Id> docIdList = userDocumentMap.get(eachMember);
                                    docIdList.add(eachDocument);
                                    userDocumentMap.put(eachMember, docIdList);
                                } 
                                else {
                                    userDocumentMap.put(eachMember, new List<Id> { eachDocument });
                                }
                            }
                        }
                    }  
                }
            }
            List<Customer_Community_Document__Share> documentListdeletion = new List<Customer_Community_Document__Share>();
            if(!userDocumentMap.isEmpty()){
                for(Customer_Community_Document__Share eachDocShare :[Select id from Customer_Community_Document__Share where UserOrGroupId IN :userDocumentMap.keyset() and RowCause ='Manual']){
                    documentListdeletion.add(eachDocShare);
                }
            }
            
            if(documentListdeletion.size() >0){
                SC_CollaborationGroupMember_Trig_Helper.deleteDocShareFromExitGroupUser(documentListdeletion);
            }
              /*  try{
                    delete documentListdeletion;
                }
                catch(Exception ex){
                    SFCommunity_NQLB_Topics__mdt  communityExceptionEmail = [SELECT ExceptionEmailToAddress__c FROM SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'CommunityNQLB' limit 1];
                    // Setting To Address
                    String[] toAdd = new String[] {};
                        toAdd.add(communityExceptionEmail.ExceptionEmailToAddress__c);
                    
                    // Sending Email
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail.setToAddresses(toAdd);
                    mail.subject = 'Error: Community Collaboration Group Member Deletion Document Permission ';
                    mail.plainTextBody = ex.getMessage() +'\n'+ ex.getLineNumber();
                    Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
                }
            }*/
        }
    }
}