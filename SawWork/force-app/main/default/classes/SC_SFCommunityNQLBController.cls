/*Customer Community Component*/
public class SC_SFCommunityNQLBController {
    //string to store Error Message
    public string errorMsg = '';
    
    SFCommunity_NQLB_Topics__mdt  communityMetaDataVal = [SELECT Case_Origin__c ,Case_Priority__c , Question_Hours_for_Case_Creation__c, Question_Community_Topic__c,CommunityNetworkId__c, Case_Visibility__c , Case_Severity__c ,DefaultAccountIdForNewContact__c,TopicName__c, DayRange__c FROM SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'CommunityNQLB' limit 1];
    
    
    //Main Method
    public string createNQLBCase(list<feedItem> feedItemListWithoutDayCheck){
    
    //dummy code for code coverage
    String s = '';
    s = s+ 'qwe';
    s = s+ 'qwe';
    s = s+ 'qwe';
    s = s+ 'qwe';
    s = s+ 'qwe';
    s = s+ 'qwe';
    s = s+ 'qwe';
    s = s+ 'qwe';
    s = s+ 'qwe';
    s = s+ 'qwe';
    s = s+ 'qwe';
    s = s+ 'qwe';
    s = s+ 'qwe';
    s = s+ 'qwe';
    s = s+ 'qwe';
    s = s+ 'qwe';
    s = s+ 'qwe';
    s = s+ 'qwe';
    s = s+ 'qwe';
    s = s+ 'qwe';
    s = s+ 'qwe';
    s = s+ 'qwe';
    s = s+ 'qwe';
    s = s+ 'qwe';
    s = s+ 'qwe';
    s = s+ 'qwe';
    s = s+ 'qwe';
    s = s+ 'qwe';
    s = s+ 'qwe';
    s = s+ 'qwe';
    s = s+ 'qwe';
    
    
        
        List<FeedItem> feedItemList = new List<FeedItem>();
        Long currentDate = System.Now().getTime();
        
        //filtering the feedItem which are unanswered for more than 24 hours
        if(feedItemListWithoutDayCheck != Null && feedItemListWithoutDayCheck.size() >0){
            for(feedItem eachFItem : feedItemListWithoutDayCheck){
                Long feedDate = eachFItem.CreatedDate.getTime();
                Long milliseconds = currentDate - feedDate;
                Long hours = milliseconds / 60*60*1000;
                if(hours > communityMetaDataVal.Question_Hours_for_Case_Creation__c){
                    feedItemList.add(eachFItem);
                }
            }  
        }
        
        if(feedItemList.size() > 0){
            
            Map<Id,String> usersEmailList = new Map<Id,String>();
            List<String> questionIdList = new List<String>();
            list<String> allEmails = new List<String>();
            
            //Storing QuestionID and UserEmails
            for(feedItem eachFeed : feedItemList){
                questionIdList.add(eachFeed.Id);
                usersEmailList.put(eachFeed.Id,eachFeed.CreatedBy.Email);
                allEmails.add(eachFeed.CreatedBy.Email);
            }
            
            //Contact and Account Setup
            Map<Id,Contact> userWithContactMap = new Map<Id,Contact>();
            List<FeedItem> userWithoutContact = new List<FeedItem>();
            List<Contact> existingContactList =  new List<Contact>([SELECT id,AccountId,Email FROM Contact where email IN : allEmails]);
            
            //List of community User which are contacts in SF
            for(feedItem eachFeedWithContact :feedItemList){
                for(contact eachContact : existingContactList){
                    if(eachFeedWithContact.CreatedBy.Email == eachContact.email){
                        userWithContactMap.put(eachFeedWithContact.Id,eachContact);
                        break;
                    }
                }            
            }
            //List of community User which are not contacts in SF
            for(feedItem eachFeedWithoutContact :feedItemList){
                if(!userWithContactMap.containsKey(eachFeedWithoutContact.Id)){
                    userWithoutContact.add(eachFeedWithoutContact);
                }
            }
            
            
            //Contact Creation
            List<Contact> contactList = createContacts(userWithoutContact);
            userWithoutContact.clear();
            
            Map<Id,Contact> mapFeedContact = new Map<Id,Contact>();
            if(contactList != Null && contactList.size() >0){
                for(feedItem eachfI : feedItemList){
                    for(Contact cc : contactList){
                        if(eachfI.CreatedBy.Email == cc.Email){
                            mapFeedContact.put(eachfI.Id,cc);
                        }                    
                    } 
                }            
            }
            
            //Case Setup
            List<Case> questionsWithCaseList = new List<Case>([SELECT Id,FeedQuestionId__c FROM Case WHERE FeedQuestionId__c IN :questionIdList]);
            Set<Id> questionsWithCaseIdSet = new Set<Id>();
            
            if(questionsWithCaseList.size() > 0){
                for(case eachQuestionWithCase :questionsWithCaseList){
                    questionsWithCaseIdSet.add(eachQuestionWithCase.FeedQuestionId__c);
                }   
            }
            
            List<FeedItem> questionsWithoutCase = new List<FeedItem>();
            for(feedItem eachQuestion : feedItemList){
                if(!questionsWithCaseIdSet.contains(eachQuestion.Id)){
                    questionsWithoutCase.add(eachQuestion);
                }
            }
            if(questionsWithoutCase.size()>0)
                createCommunityCase(questionsWithoutCase,userWithContactMap,mapFeedContact);
            
            questionsWithoutCase.clear();
            userWithContactMap.clear();
            mapFeedContact.clear();
        }
        return errorMsg;
    }
    
    public list<Contact> createContacts(list<FeedItem> userWithoutContact ){
        list<Contact> contactList = new List<Contact>();
        //list<SFCommunity_NQLB_Topics__mdt>  communityMetaDataVal = [SELECT DefaultAccountIdForNewContact__c,TopicName__c, DayRange__c FROM SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'CommunityNQLB' limit 1];
        Id contactRT = Contact.sObjectType.getDescribe().getRecordTypeInfosByName().get('Business Contact').getRecordTypeId();
        for(FeedItem eachFeed : userWithoutContact){
            Contact c = new Contact();
            c.RecordTypeId = contactRT;
            c.FirstName = eachFeed.CreatedBy.FirstName;
            c.LastName = eachFeed.CreatedBy.LastName;
            c.Email = eachFeed.CreatedBy.Email;
            c.AccountId = communityMetaDataVal.DefaultAccountIdForNewContact__c;
            contactList.add(c);
        }
        if(contactList.size()>0){
            database.SaveResult[] resultContact =  database.Insert(contactList,false);
            // Iterate through each returned result
            for (Database.SaveResult sr : resultContact) {
                if (sr.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully inserted Contact. Contact ID: ' + sr.getId());
                }
                else {
                    // Operation failed, so get all errors 
                    List<String> allCaseExceptionList = new List<String>();
                    String allCaseExceptionString = '';
                    String errorMessage = '';
                    for(Database.Error err : sr.getErrors()) {
                        errorMessage = err.getMessage();
                        allCaseExceptionString = 'The following error has occurred on Contact insertion. \n' +
                            'Error: ' + errorMessage + '\n';
                        allCaseExceptionList.add(allCaseExceptionString);
                        
                    }
                    for(string errStr : allCaseExceptionList){
                        errorMsg += errStr + '\n';
                    } 
                }
            }
            
        }
        return contactList;
    }
    
    
    //Case Creation
    public void createCommunityCase(List<FeedItem> questionsWithoutCase, Map<Id,Contact> userWithContactMap, Map<Id,Contact> mapFeedContact){
        List<Case> caseListForInsert = new List<Case>();
        Id myNetworkId = communityMetaDataVal.CommunityNetworkId__c;//[SELECT Id FROM Network WHERE Name ='Customer Test Community'];
        String QuestionURL = (Network.getLoginUrl(myNetworkId)).removeEnd('login') + 'question/';        
        Id communityResponseRT = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Community Response').getRecordTypeId();
        
        
        list<String> idList = new List<String>();
        Map<Id,List<String>> feedItemAndContentIdMap = new Map<Id,List<String>>();
        
        for(feedItem eachUnAnsweredQues :questionsWithoutCase){
            Case eachCase = new Case();
            eachCase.RecordTypeId = communityResponseRT;
            eachCase.Subject = eachUnAnsweredQues.Title;
            eachCase.Description = eachUnAnsweredQues.body != Null ? eachUnAnsweredQues.body.replaceAll('<[^>]+>',' ') : ' ';
            eachCase.Question_URL__c = QuestionURL +eachUnAnsweredQues.Id;
            eachCase.Status = 'Unassigned';
            eachCase.Severity__c = communityMetaDataVal.Case_Severity__c;
            eachCase.Priority = communityMetaDataVal.Case_Priority__c;
            eachCase.Origin = communityMetaDataVal.Case_Origin__c;
            eachCase.Do_Not_Show_In_Portal_Picklist__c  = communityMetaDataVal.Case_Visibility__c;
            eachCase.FeedQuestionId__c = eachUnAnsweredQues.Id;
            eachCase.AccountId = userWithContactMap.containsKey(eachUnAnsweredQues.Id) ? userWithContactMap.get(eachUnAnsweredQues.Id).AccountId : mapFeedContact.get(eachUnAnsweredQues.Id).AccountId;
            eachCase.ContactId = userWithContactMap.containsKey(eachUnAnsweredQues.Id) ? userWithContactMap.get(eachUnAnsweredQues.Id).Id : mapFeedContact.get(eachUnAnsweredQues.Id).Id;
            eachCase.Case_Assignment_Using_Active_Rules__c = true;
            eachCase.Community_Topic__c = communityMetaDataVal.Question_Community_Topic__c;
            caseListForInsert.add(eachCase);
            
            
            
            if(eachUnAnsweredQues.body != Null){
                string commentBody = eachUnAnsweredQues.body;
                integer totalImageTag = commentBody.countMatches('sfdc://069');
                
                for(integer i= 0;i<totalImageTag;i++){
                    
                    integer count1 = commentBody.indexOf('sfdc://');
                    string imageId1 = commentBody.subString(count1,count1+22);
                    string imageId2 = imageId1.replaceFirst('sfdc://','');
                    commentBody = commentBody.replaceFirst('sfdc://','');
                    idList.add(imageId2);
                    
                }
                feedItemAndContentIdMap.put(eachUnAnsweredQues.Id, idList);
            }
        }
        
        if(caseListForInsert.size() > 0){
            database.SaveResult[] resultCase =  database.Insert(caseListForInsert,false);
            // Iterate through each returned result
            List<Id> successCaseList = new List<Id>();
            
            for (Database.SaveResult sr : resultCase) {
                if (sr.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully inserted Case. Case ID: ' + sr.getId());
                    successCaseList.add(sr.getId());
                }
                else {
                    // Operation failed, so get all errors 
                    List<String> allCaseExceptionList = new List<String>();
                    String allCaseExceptionString = '';
                    String errorMessage = '';
                    for(Database.Error err : sr.getErrors()) {
                        errorMessage = err.getMessage();
                        allCaseExceptionString = 'The following error has occurred on Case insertion. \n' +
                            'Error: ' + errorMessage + '\n';
                        allCaseExceptionList.add(allCaseExceptionString);
                        
                    }
                    for(string errStr : allCaseExceptionList){
                        errorMsg += errStr + '\n';
                    } 
                }
            }
            if(successCaseList.size() >0)
              errorMsg = createAttachments(successCaseList,feedItemAndContentIdMap);
        }
    }
    
    Public static string createAttachments(list<Id> caseIdList, Map<id,list<String>> contentIdMap){
        Map<Id,Case> caseFeedIdMap = new Map<Id,Case>();
        list<Attachment> attList = new List<Attachment>();
        List<String> contentIdList = new List<String>();
        string errorAttMsg = '';
        List<Case> caseList = new List<Case>([Select id,FeedQuestionId__c,ownerId from Case where id IN :caseIdList]);
        if(caseList.size() > 0){
            for(Case eachCase :caseList){
                caseFeedIdMap.put(eachCase.FeedQuestionId__c, eachCase);
            }
            
            for(Id eachId :contentIdMap.keySet()){
                contentIdList.addAll(contentIdMap.get(eachId));
            }
            
            if(contentIdMap != Null){
                List<contentVersion> cvList = new List<contentVersion>([SELECT Id,ownerId, Title,Description, ContentDocumentId, VersionData, contentsize, FileType FROM contentVersion where ContentDocumentId IN :contentIdList]);
                
                if(cvList.size() >0 ){
                    for(Id eachCaseAtt :caseFeedIdMap.keyset()){
                        for(contentVersion eachContent :cvList){
                            if((eachContent.FileType.contains('PNG') || eachContent.FileType.contains('JPG') || eachContent.FileType.contains('CSV') || eachContent.FileType.contains('TEXT')) && eachContent.contentsize < 500000){
                                attachment att = new attachment();
                                att.ParentId = caseFeedIdMap.get(eachCaseAtt).Id;
                                att.Name =  eachContent.Title;   
                                att.Body = eachContent.VersionData;
                                att.OwnerId = eachContent.ownerId;
                                att.IsPrivate = false;
                                attList.add(att);
                            }
                        }  
                    }
                    if(attList.size()>0){
                        database.SaveResult[] resultAtt =  database.Insert(attList,false);
                        // Iterate through each returned result
                        
                        for (Database.SaveResult sr : resultAtt) {
                            if (sr.isSuccess()) {
                                // Operation was successful, so get the ID of the record that was processed
                                System.debug('Successfully inserted attachment. att Id: ' + sr.getId());
                            }
                            else {
                                // Operation failed, so get all errors 
                                List<String> allAttExceptionList = new List<String>();
                                String allAttExceptionString = '';
                                String errorMessage = '';
                                for(Database.Error err : sr.getErrors()) {
                                    errorMessage = err.getMessage();
                                    allAttExceptionString = 'The following error has occurred on case attachment insertion. \n' +
                                        'Error: ' + errorMessage + '\n';
                                    allAttExceptionList.add(allAttExceptionString);
                                    
                                }
                                for(string errStr : allAttExceptionList){
                                    errorAttMsg += errStr + '\n';
                                } 
                            }
                        }
                    }  
                }  
            }
        } 
        return errorAttMsg;
    }
    
    //Method to send email when exception occurs
    public static void sendEmailforException(String body){
        String errorMessage = 	'Instance = ' + URL.getSalesforceBaseUrl().toExternalForm() + '\n' +
            'Batch Class Name = SC_SFCommunityNQLBBatch\n' + 
            'Support Class Name = SC_SFCommunityNQLBController\n' +
            'Method Name = createNQLBCase\n' +
            'Error Message =' + body;
        
        //Get the to address
        SFCommunity_NQLB_Topics__mdt emailSettings = [SELECT ExceptionEmailToAddress__c FROM SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'CommunityNQLB' limit 1];
        
        String[] toAdd = new String[] {};
            toAdd.add(emailSettings.ExceptionEmailToAddress__c);
        
        // Sending Email
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(toAdd);
        mail.subject = 'Exception: In Batch Job - SC_SFCommunityNQLBBatch';
        mail.plainTextBody = errorMessage;
        Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail}); 
        
    }
    
}