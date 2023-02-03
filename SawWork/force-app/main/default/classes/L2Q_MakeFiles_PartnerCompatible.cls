global class L2Q_MakeFiles_PartnerCompatible implements Database.Batchable<sObject>, Database.Stateful {

        public class ObjectCustom {
                String ObjectName;
                String PartnerAccount;

                public ObjectCustom() {
                }
        }
        global String query;
        global String currentExecutableObject;
        global String currentExecutableObject_ParentAccountField;
        Set<Id> alreadyCompatableRecordIds;
        List<ObjectCustom> listOfObjects;
        Integer currentCountOfBatch;
        Integer yearUnderConsideration;
        Map<Id, String> mapOfFailedData;
        global Boolean shouldExecuteNext;
        global Id PartnerLibraryId;

        global L2Q_MakeFiles_PartnerCompatible(Integer countOfBatch, Integer year, String incomingQuery, Boolean executeNext, String libraryId) {
                shouldExecuteNext = executeNext;
                PartnerLibraryId = Id.valueOf(libraryId);
                String L2Q_ObjectsForPartnerAttributesBatchJSON = GSMSettings.getVerbose('L2Q_ObjectsForPartnerAttributesBatchJSON');
                listOfObjects = new List<ObjectCustom>();
                currentCountOfBatch = countOfBatch;
                yearUnderConsideration = year;
                listOfObjects = (List<ObjectCustom>)JSON.deserialize(L2Q_ObjectsForPartnerAttributesBatchJSON, List<ObjectCustom>.Class);
                currentExecutableObject = listOfObjects.get(countOfBatch).ObjectName;
                currentExecutableObject_ParentAccountField = listOfObjects.get(countOfBatch).PartnerAccount;
                String attachmentToFileConverisonObjectName = currentExecutableObject + ':FileAttributes';
                String startDate = year + '-01-01T00:00:00Z';
                String endDate = (year+1) + '-01-01T00:00:00Z';
                System.DEBUG('query ND_ :: ' + startDate);
                System.DEBUG('query ND_ :: ' + endDate);
                alreadyCompatableRecordIds = new Set<Id>();
                mapOfFailedData = new Map<Id, String>();
                for (AttachmentToFileConverison__c atfc: [Select Id,Object__c,AttachmentIds__c from AttachmentToFileConverison__c Where Object__c = :attachmentToFileConverisonObjectName And Year__c = : String.valueOf(year)]) {
                        if (atfc.AttachmentIds__c != null) {
                                for (String attachmentId : atfc.AttachmentIds__c.split(',') ) {
                                        if ( attachmentId != null && attachmentId != '' && Id.valueOf(attachmentId) != null) {
                                                alreadyCompatableRecordIds.add(Id.valueOf(attachmentId));
                                        }
                                }
                        }
                }

                if(incomingQuery == null || incomingQuery == '') {
                        query = 'SELECT Id, ' + currentExecutableObject_ParentAccountField + ' From ' + currentExecutableObject + ' WHERE Akam_Created_Date__c >=' + startDate + ' AND Akam_Created_Date__c < ' + endDate + 'AND ' + currentExecutableObject_ParentAccountField + ' != null AND Id NOT IN :alreadyCompatableRecordIds';
                } else {
                        query = incomingQuery;
                }
                System.DEBUG('query ND_ :: ' + query);
        }

        global Database.QueryLocator start(Database.BatchableContext BC) {
                return Database.getQueryLocator(query);
        }

        global void execute(Database.BatchableContext BC, List<sObject> scope) {
                if (scope.size() > 0) {
                        List<Id> listOfRecordIds = new List<Id>();
                        Map<Id, Id> mapOfLinkedEntityIdVsPartnerAccountId = new Map<Id, Id>();
                        for (SObject eachSObject : scope) {
                                listOfRecordIds.add(eachSObject.Id);
                                mapOfLinkedEntityIdVsPartnerAccountId.put(eachSObject.Id, Id.valueOf(String.valueOf(eachSObject.get(currentExecutableObject_ParentAccountField))));
                        }
                        List<ContentDocumentLink> listOfContentDocumentLink = [SELECT Id, LinkedEntityId, LinkedEntity.Type, ContentDocumentId, ContentDocument.LatestPublishedVersionId, ContentDocument.LatestPublishedVersion.OwnerId, Visibility FROM ContentDocumentLink WHERE LinkedEntityId IN :listOfRecordIds];
                        if(listOfContentDocumentLink != null && listOfContentDocumentLink.size() > 0) {
                                List<ContentVersionAttribute__c> listOfAttributes = new List<ContentVersionAttribute__c>();
                                List<ContentWorkspaceDoc> listOfContentWorkspaceDoc = new List<ContentWorkspaceDoc>();
                                Set<Id> setOfLinkedEntityIds = new Set<Id>();
                                Map<Id, Id> mapOfContentVersionToLinkedEntityId = new Map<Id, Id>();
                                Map<Id, Id> mapOfContentDocumentToLinkedEntityId = new Map<Id, Id>();
                                List<Id> listOfOwnerId = new List<Id>();
                                for (ContentDocumentLink eachContentDocumentLink : listOfContentDocumentLink) {
                                        listOfOwnerId.add(eachContentDocumentLink.ContentDocument.LatestPublishedVersion.OwnerId);
                                        setOfLinkedEntityIds.add(eachContentDocumentLink.LinkedEntityId);
                                        mapOfContentVersionToLinkedEntityId.put(eachContentDocumentLink.ContentDocument.LatestPublishedVersionId, eachContentDocumentLink.LinkedEntityId);
                                        mapOfContentDocumentToLinkedEntityId.put(eachContentDocumentLink.ContentDocumentId, eachContentDocumentLink.LinkedEntityId);
                                }
                                Map<Integer, ContentWorkspaceDoc> mapFromAttributesToWorkspaceDocs = new Map<Integer, ContentWorkspaceDoc>();
                                Map<Id, User> mapOfOwnerIdVsUserData = new Map<Id, User>([SELECT Id, UserType FROM User WHERE Id IN:listOfOwnerId]);
                                List<ContentDocumentLink> listOfContentDocumentLinksToUpdate = new List<ContentDocumentLink>();
                                for (ContentDocumentLink eachContentDocumentLink : listOfContentDocumentLink) {
                                        if(eachContentDocumentLink.Visibility != 'AllUsers') {
                                                eachContentDocumentLink.Visibility = 'AllUsers';
                                                listOfContentDocumentLinksToUpdate.add(eachContentDocumentLink);
                                        }
                                        if(mapOfLinkedEntityIdVsPartnerAccountId.containsKey(eachContentDocumentLink.LinkedEntityId)) {
                                                listOfAttributes.add(L2Q_ContentDocumentUtilClass.setContentVersionAttribute(eachContentDocumentLink.ContentDocument.LatestPublishedVersionId, 'Partner Account', mapOfLinkedEntityIdVsPartnerAccountId.get(eachContentDocumentLink.LinkedEntityId)));
                                                if(!(mapOfOwnerIdVsUserData != null && mapOfOwnerIdVsUserData.containsKey(eachContentDocumentLink.ContentDocument.LatestPublishedVersion.OwnerId) && mapOfOwnerIdVsUserData.get(eachContentDocumentLink.ContentDocument.LatestPublishedVersion.OwnerId).UserType != null && mapOfOwnerIdVsUserData.get(eachContentDocumentLink.ContentDocument.LatestPublishedVersion.OwnerId).UserType == 'PowerPartner')) {
                                                        mapFromAttributesToWorkspaceDocs.put((listOfAttributes.size() - 1), L2Q_ContentDocumentUtilClass.setContentWorkspaceDoc(PartnerLibraryId, eachContentDocumentLink.ContentDocumentId));
                                                }
                                        }
                                }
                                //Insert
                                if(listOfContentDocumentLinksToUpdate.size() > 0) {
                                        try {
                                                update listOfContentDocumentLinksToUpdate;
                                        } catch (Exception e){
                                                Error_Log__c el = new Error_Log__c(Name= 'L2Q_MakeFiles_PartnerCompatible', Class__c='L2Q_MakeFiles_PartnerCompatible : ', Error_Message__c = String.valueOf(e));
                                                insert el;
                                        }
                                }

                                if(listOfAttributes.size() > 0) {
                                        List<Database.SaveResult> listOfDbResult = DataBase.insert(listOfAttributes, false);
                                        for(Integer count=listOfDbResult.size()-1; count>=0; count--) {
                                                Database.SaveResult eachDbResult = listOfDbResult.get(count);
                                                if(!eachDbResult.isSuccess()) {
                                                        mapFromAttributesToWorkspaceDocs.remove(count);
                                                        String errorMessage = '';
                                                        for(Database.Error eachError : eachDbResult.getErrors()) {
                                                                errorMessage += eachError.getMessage() + '\n';
                                                        }
                                                        mapOfFailedData.put(mapOfContentVersionToLinkedEntityId.get(listOfAttributes.get(count).ContentVersionId__c), errorMessage);
                                                }
                                        }
                                        if(mapFromAttributesToWorkspaceDocs.size() > 0) {
                                                listOfContentWorkspaceDoc = mapFromAttributesToWorkspaceDocs.values();
                                                List<Database.SaveResult> listOfDbResult2 = DataBase.insert(listOfContentWorkspaceDoc, false);
                                                for(Integer count=listOfDbResult2.size()-1; count>=0; count--) {
                                                        Database.SaveResult eachDbResult = listOfDbResult2.get(count);
                                                        if(!eachDbResult.isSuccess()) {
                                                                String errorMessage = '';
                                                                for(Database.Error eachError : eachDbResult.getErrors()) {
                                                                        errorMessage += eachError.getMessage() + '\n';
                                                                }
                                                                mapOfFailedData.put(mapOfContentDocumentToLinkedEntityId.get(listOfContentWorkspaceDoc.get(count).ContentDocumentId), errorMessage);
                                                        }
                                                }
                                        }
                                        setOfLinkedEntityIds.removeAll(mapOfFailedData.keySet());
                                        if(setOfLinkedEntityIds.size() > 0) {
                                                AttachmentToFileConverison__c atfc = new AttachmentToFileConverison__c();
                                                atfc.AttachmentIds__c = '';
                                                for(Id eachId : setOfLinkedEntityIds) {
                                                        atfc.AttachmentIds__c += eachId + ',';
                                                }
                                                atfc.Object__c = currentExecutableObject + ': FileAttributes : ' + yearUnderConsideration;
                                                insert atfc;
                                        }
                                }
                        }
                }
        }

        global void finish(Database.BatchableContext BC) {
                if(mapOfFailedData.size() > 0) {
                        List<Error_Log__c> listOfErrorLog = new List<Error_Log__c>();
                        for(Id eachId : mapOfFailedData.keySet()) {
                                Error_Log__c el = new Error_Log__c(Name= String.valueOf(eachId), Class__c='L2Q_MakeFiles_PartnerCompatible : ' + currentExecutableObject, Error_Message__c = mapOfFailedData.get(eachId));
                                listOfErrorLog.add(el);
                        }
                        insert listOfErrorLog;
                }
                if(shouldExecuteNext) {
                        if(currentCountOfBatch < listOfObjects.size()-1) {
                                L2Q_MakeFiles_PartnerCompatible obj = new L2Q_MakeFiles_PartnerCompatible(++currentCountOfBatch, yearUnderConsideration, '', true, String.valueOf(PartnerLibraryId));
                                Database.executeBatch(obj, 200);
                        }
                }
        }
}