global class ConvertAttachmentsToFiles implements Database.Batchable<sObject>, Database.Stateful {

        global String query = '';
        global Long numberOfRecords = 0;
        global Map<String, String> mapOfObjectIdInitialsVsObjectName = new Map<String, String>();
        global List<String> listOfObjects = new List<String>();
        global String currentExecutableObject = '';
        global Integer currentCountOfBatch;
        global String fileId = '';
        global List<Id> attachmentIds = new List<Id>();
        global boolean isSingleObject = false;
        global DMLResults results_ContentVersion = new DMLResults();
        global DMLResults results_ContentDocumentLink = new DMLResults();
        global DMLResults results_CustomMetadata = new DMLResults();
        global Integer totalCount = 0;
        global Integer totalConverted = 0;
        Set<Id> alreadyConveretedAttachmentIds = new Set<Id>();
        String L2Q_ObjectsUsingAttachment = '';
        String yearUnderConsideration = '';
        DateTime startDate;
        DateTime endDate;

        public void sendMail(String messageBody,String recepients){
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            message.toAddresses = new String[] { recepients };
            message.optOutPolicy = 'FILTER';
            message.subject = 'Attachment Conversion Results ';
            message.plainTextBody = messageBody;
            Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
            Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        }


        global ConvertAttachmentsToFiles(Integer countOfBatch,Integer year) {
                L2Q_ObjectsUsingAttachment = GSMSettings.getVerbose('L2Q_ObjectsUsingAttachment_ForBatch');
                listOfObjects = L2Q_ObjectsUsingAttachment.split(',');
                currentExecutableObject = listOfObjects.get(countOfBatch);
                yearUnderConsideration = String.valueOf(year);
                alreadyConveretedAttachmentIds.clear();
                for (AttachmentToFileConverison__c atfc: [Select Id,Object__c,AttachmentIds__c from AttachmentToFileConverison__c Where Object__c = :currentExecutableObject And Year__c = : yearUnderConsideration]) {
                    if (atfc.AttachmentIds__c != null) {
                        for (String attachmentId : atfc.AttachmentIds__c.split(',') ) {
                            if ( attachmentId != null && Id.valueOf(attachmentId) != null) {
                                    alreadyConveretedAttachmentIds.add(Id.valueOf(attachmentId));
                            }
                        }
                    }
                }

                
                startDate = Date.valueOf(yearUnderConsideration + '-01-01');
                endDate = Date.valueOf(String.valueOf(year + 1) + '-01-01');
                currentCountOfBatch = countOfBatch;
                query = 'SELECT Id, Name, Body, ParentId, Parent.Type From Attachment WHERE Parent.Type = :currentExecutableObject AND CreatedDate >= :startDate And CreatedDate <= : endDate And Id not in :alreadyConveretedAttachmentIds';
        }


        global ConvertAttachmentsToFiles(String fileId) {
           List<ContentVersion> conDoc = [SELECT VersionData FROM ContentVersion WHERE ContentDocumentId = :fileId];
           if(conDoc.size() != 0){
                List<Id> idList = new List<Id>();
                for(String str : (conDoc.get(0).VersionData).toString().split('\n')) {
                    idList.add(Id.valueOf(str));
                }
                attachmentIds = idList;
            }
            query = 'SELECT Id, Name, Body, ParentId, Parent.Type From Attachment where Id  in :attachmentIds';

        }

        global ConvertAttachmentsToFiles(List<Id> idList) {
            attachmentIds = idList;
            query = 'SELECT Id, Name, Body, ParentId, Parent.Type From Attachment where Id  in :attachmentIds';

        }


        global ConvertAttachmentsToFiles(Integer year,String objectName) {
                isSingleObject = true;
                currentExecutableObject = objectName;
                yearUnderConsideration = String.valueOf(year);
                alreadyConveretedAttachmentIds.clear();
                for (AttachmentToFileConverison__c atfc: [Select Id,Object__c,AttachmentIds__c from AttachmentToFileConverison__c Where Object__c = :currentExecutableObject And Year__c = : yearUnderConsideration]) {
                    if (atfc.AttachmentIds__c != null) {
                        for (String attachmentId : atfc.AttachmentIds__c.split(',') ) {
                            if ( attachmentId != null && Id.valueOf(attachmentId) != null) {
                                    alreadyConveretedAttachmentIds.add(Id.valueOf(attachmentId));
                            }
                        }
                    }
                }

                
                startDate = Date.valueOf(yearUnderConsideration + '-01-01');
                endDate = Date.valueOf(String.valueOf(year + 1) + '-01-01');
                query = 'SELECT Id, Name, Body, ParentId, Parent.Type From Attachment WHERE Parent.Type = :currentExecutableObject AND CreatedDate >= :startDate And CreatedDate <= : endDate And Id not in :alreadyConveretedAttachmentIds';
        }


        global Database.QueryLocator start(Database.BatchableContext BC) {
                return Database.getQueryLocator(query);
        }

         global void execute(Database.BatchableContext BC, List<sObject> scope) {

                List<Attachment> attachmentsToConvert = new List<Attachment>();
                Set<Id> parentIds = new Set<Id>();
                if(scope.size() > 0) {
                    totalCount += scope.size();
                    for(Attachment att : (List<Attachment>)scope){
                        parentIds.add(att.parentId);
                    }

                    Map<Id,List<String>> parentIdToFileNames = new Map<Id,List<String>>();
                    for(ContentDocumentLink d : [SELECT ContentDocumentId,contentdocument.title,LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId in :parentIds]){
                        if(parentIdToFileNames.containsKey(d.LinkedEntityId)){
                            parentIdToFileNames.get(d.LinkedEntityId).add(d.contentdocument.title);
                        }
                        else{
                            parentIdToFileNames.put(d.LinkedEntityId,new List<String>{d.contentdocument.title});
                        }
                    }
                    for(Attachment att : (List<Attachment>)scope){
                        if(parentIdToFileNames.containsKey(att.parentId)){
                            if(!parentIdToFileNames.get(att.parentId).contains(att.name)){
                                attachmentsToConvert.add(att);
                            }
                        }
                        else{
                            attachmentsToConvert.add(att);
                        }
                    }
                }

            
                if (attachmentsToConvert.size() > 0) {
                    results_ContentDocumentLink.includeSuccess();
                    Integer successCount = 0;
                    String shareType = GSMSettings.getVerbose('AttachmentConversionShareType');
                    List<ContentVersion> listOfContentVersion = new List<ContentVersion>();
                    List<Id> listOf_L2QAttachments = new List<Id>();
                    AttachmentToFileConverison__c convertedData = new AttachmentToFileConverison__c();
                    Map<Id,Id> contentVersionIdToAttachmentId = new Map<Id,Id>();
                    convertedData.Object__c = 'NA';
                    convertedData.Year__c = 'NA';
                    if(currentExecutableObject != '')
                        convertedData.Object__c = currentExecutableObject;
                    if(yearUnderConsideration != '')
                        convertedData.Year__c = yearUnderConsideration;
                    convertedData.AttachmentIds__c = '';

                    for (Attachment eachAttachment : attachmentsToConvert) {
                        listOf_L2QAttachments.add(eachAttachment.parentId);
                        listOfContentVersion.add(L2Q_ContentDocumentUtilClass.setContentVersion('S', eachAttachment.Name, eachAttachment.Name, eachAttachment.Body));
                    }

                        results_ContentVersion.dmlInsert(listOfContentVersion);

                        Integer iter = 0;
                        for(Attachment eachAttachment : attachmentsToConvert){
                           contentVersionIdToAttachmentId.put(listOfContentVersion.get(iter++).Id,eachAttachment.Id);
                        }

                        Map<Id, ContentVersion> mapOfInsertedIdVsContentVersion = new Map<Id, ContentVersion>([SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN:listOfContentVersion]);
                        List<ContentDocumentLink> listOfContentDocumentLink = new List<ContentDocumentLink>();
                        Map<Id,Id> contentDocumentLinkIdToContentVersionId = new Map<Id,Id>();
                        List<Id> failedAttachments = new List<Id>();
                        Integer count = 0;
                        List<Attachment> convertedAttachments = new List<Attachment>();
                        for (ContentVersion eachContentVersion : listOfContentVersion) {
                            if (mapOfInsertedIdVsContentVersion.containsKey(eachContentVersion.Id)) {
                                listOfContentDocumentLink.add(L2Q_ContentDocumentUtilClass.setContentDocumentLink(mapOfInsertedIdVsContentVersion.get(eachContentVersion.Id).COntentDocumentId, listOf_L2QAttachments.get(count), shareType, 'AllUsers'));
                            }
                            else{
                                failedAttachments.add(listOf_L2QAttachments.get(count));
                            }
                            count++;
                        }

                        if (failedAttachments.size() > 0) {
                            String allAttachmentIds = '';
                            for(Id attId : failedAttachments){
                                allAttachmentIds += String.valueOf(attId);
                            }
                            Error_Log__c el = new Error_Log__c(Name= 'ContentVersion Insert Failure', Class__c='ConvertAttachmentsToFiles', Error_Message__c = allAttachmentIds);
                            insert el;
                        }

                        results_ContentDocumentLink.dmlInsert(listOfContentDocumentLink);

                        iter = 0;
                        for(ContentVersion eachContentVersion : listOfContentVersion){
                           contentDocumentLinkIdToContentVersionId.put(listOfContentDocumentLink.get(iter++).Id,eachContentVersion.Id);
                        }

                        for(DmlResults.Result res : results_ContentDocumentLink.results)
                        {
                            if(res.success){
                                successCount++;
                                totalConverted++;
                                Id contentVersionId = contentDocumentLinkIdToContentVersionId.get(res.Id);
                                Id attachmentId = contentVersionIdToAttachmentId.get(contentVersionId);
                                convertedData.AttachmentIds__c += String.valueOf(attachmentId) + ',';
                            }
                        }
                        if(successCount > 0)
                            results_CustomMetadata.dmlInsert(new List<AttachmentToFileConverison__c>{convertedData});

                    results_ContentDocumentLink.clear();
                    results_ContentVersion.clear();
                    results_CustomMetadata.clear();
                }
        }

        global void finish(Database.BatchableContext BC) {
                if(fileId == '' && attachmentIds.size() == 0  && !isSingleObject) {
                     if (currentCountOfBatch < listOfObjects.size()-1) {
                        ConvertAttachmentsToFiles checkAttachment = new ConvertAttachmentsToFiles(++currentCountOfBatch,Integer.valueOf(yearUnderConsideration));
                        Database.executeBatch(checkAttachment, 200);
                    }
                    else{
                        String messageBody = 'Total records attempted to modify : ' + totalCount + '\n Total records succesfully converted : ' + totalConverted + '\n\n';
                        sendMail(messageBody,'pkoushik@akamai.com');
                        results_ContentDocumentLink.withClassName('Attachment Converison For Year ' + yearUnderConsideration).insertRecordsInErrorLog();
                        results_ContentVersion.withClassName('Attachment Converison Error for Content Version').insertRecordsInErrorLog();
                    }
                }
                else{
                    String messageBody = 'Total records attempted to modify : ' + totalCount + '\n Total records succesfully converted : ' + totalConverted + '\n\n';
                    sendMail(messageBody,'pkoushik@akamai.com');
                    results_ContentDocumentLink.withClassName('Attachment Converison').insertRecordsInErrorLog();
                    results_ContentVersion.withClassName('Attachment Converison Error for Content Version').insertRecordsInErrorLog();
                }
        }
}