/**
   @author: Nagaraj Desai
   SFDC-4283 : Make Files Visible To Partner Users
 * History:
 * =========================
 * Developer        Date        Description

   Nagaraj Desai    05/Feb/19       Added this class for SFDC-4283.
   =========================
   Related Test Class: L2Q_ContentDocumentLinkTriggerTests
 **/


public without sharing class L2Q_ContentDocumentLinkTriggerClass {
        public static Boolean addAttributesAndLinkToPartnerFacingLibraryHasRun = false;
        public static Boolean addAccountVisibiltyForRelatedFilesHasRun = false;
        //SFDC-7779 -Start
        public static Boolean contentDocumentBeforeDeleteOverrideHasRun = false;
        public static Boolean contentDocumentAfterDeleteOverrideHasRun = false;
        //SFDC-7779 -End
        // for every contentdocumentlink to objects mentioned in 'L2Q_ObjectsForPartnerAttributesBatchJSON' :
        //1) Populate ContentVersion Attributes
        //2) Create ContentWorkspaceDoc linking to Partner Facing Library
        public static void addAttributesAndLinkToPartnerFacingLibrary(List<ContentDocumentLink> listOfConDocLinks, Map<String, String> mapOfValidObjects, Map<Id, Id> mapOfTaskIdVsWhatId) {
                if(addAttributesAndLinkToPartnerFacingLibraryHasRun) {
                        return;
                }
                addAttributesAndLinkToPartnerFacingLibraryHasRun = true;

                Map<String, List<Id>> mapOfObjectTypeVsListOfRecordIds = new Map<String, List<Id>>();
                List<Id> listOfRequiredContentDocumentIds = new List<Id>();
                for(ContentDocumentLink eachContentDocumentLink : listOfConDocLinks) {
                        listOfRequiredContentDocumentIds.add(eachContentDocumentLink.ContentDocumentId);
                        String objectName = String.valueOf(eachContentDocumentLink.LinkedEntityId.getSObjectType());
                        Boolean taskTransaction = false;
                        if(objectName == 'Task') {
                                taskTransaction = true;
                                if(mapOfTaskIdVsWhatId != null && mapOfTaskIdVsWhatId.containsKey(eachContentDocumentLink.LinkedEntityId)) {
                                        objectName = String.valueOf(mapOfTaskIdVsWhatId.get(eachContentDocumentLink.LinkedEntityId).getSObjectType());
                                } else {
                                        continue;
                                }
                        }
                        List<Id> idListToAdd;
                        if(mapOfObjectTypeVsListOfRecordIds.containsKey(objectName)) {
                                idListToAdd = mapOfObjectTypeVsListOfRecordIds.get(objectName);
                        }
                        else {
                                idListToAdd = new List<Id>();
                        }
                        if(taskTransaction) {
                                idListToAdd.add(mapOfTaskIdVsWhatId.get(eachContentDocumentLink.LinkedEntityId));

                        } else {
                                idListToAdd.add(eachContentDocumentLink.LinkedEntityId);
                        }
                        mapOfObjectTypeVsListOfRecordIds.put(objectName, idListToAdd);
                }

                Map<Id, Id> mapOfLinkedEntityIdVsPartnerAccountId = new Map<Id, Id>();
                for(String eachObject : mapOfObjectTypeVsListOfRecordIds.KeySet()) {
                        String query = 'Select Id, ';
                        List<Id> listOfIds = mapOfObjectTypeVsListOfRecordIds.get(eachObject);
                        query += mapOfValidObjects.get(eachObject) + ' FROM ' + eachObject + ' WHERE Id IN :listOfIds AND ' + mapOfValidObjects.get(eachObject) + ' != null';
                        List<SObject> listOfSObject = Database.query(query);
                        for(SObject eachSObject : listOfSObject) {
                                mapOfLinkedEntityIdVsPartnerAccountId.put(eachSObject.Id, Id.valueOf(String.valueOf(eachSObject.get(mapOfValidObjects.get(eachObject)))));
                        }
                }
                if(mapOfLinkedEntityIdVsPartnerAccountId.size() > 0) {
                        Map<Id, String> mapOfFailedData = new Map<Id, String>();
                        List<ContentDocumentLink> listOfContentDocumentLink = [SELECT Id, ContentDocumentId, ContentDocument.LatestPublishedVersionId, LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId IN :listOfRequiredContentDocumentIds];
                        List<ContentVersionAttribute__c> listOfAttributes = new List<ContentVersionAttribute__c>();
                        List<ContentWorkspaceDoc> listOfContentWorkspaceDoc = new List<ContentWorkspaceDoc>();
                        Map<Id, Id> mapOfContentVersionToLinkedEntityId = new Map<Id, Id>();
                        Map<Id, Id> mapOfContentDocumentToLinkedEntityId = new Map<Id, Id>();

                        String libId = GSMSettings.getValue('PartnerFacingFilesLibraryId');
                        Id PartnerLibraryId = Id.valueOf(libId);

                        for (ContentDocumentLink eachContentDocumentLink : listOfContentDocumentLink) {
                                Boolean taskTransaction = eachContentDocumentLink.LinkedEntityId.getSObjectType() == Task.SObjectType;
                                if(mapOfLinkedEntityIdVsPartnerAccountId.containsKey(eachContentDocumentLink.LinkedEntityId) || (taskTransaction && mapOfLinkedEntityIdVsPartnerAccountId.containsKey(mapOfTaskIdVsWhatId.get(eachContentDocumentLink.LinkedEntityId)))) {

                                        mapOfContentVersionToLinkedEntityId.put(eachContentDocumentLink.ContentDocument.LatestPublishedVersionId, eachContentDocumentLink.LinkedEntityId);
                                        mapOfContentDocumentToLinkedEntityId.put(eachContentDocumentLink.ContentDocumentId, eachContentDocumentLink.LinkedEntityId);
                                        if(taskTransaction) {
                                                listOfAttributes.add(L2Q_ContentDocumentUtilClass.setContentVersionAttribute(eachContentDocumentLink.ContentDocument.LatestPublishedVersionId, 'Partner Account', mapOfLinkedEntityIdVsPartnerAccountId.get(mapOfTaskIdVsWhatId.get(eachContentDocumentLink.LinkedEntityId))));
                                        }
                                        else {
                                                listOfAttributes.add(L2Q_ContentDocumentUtilClass.setContentVersionAttribute(eachContentDocumentLink.ContentDocument.LatestPublishedVersionId, 'Partner Account', mapOfLinkedEntityIdVsPartnerAccountId.get(eachContentDocumentLink.LinkedEntityId)));
                                        }
                                        listOfContentWorkspaceDoc.add(L2Q_ContentDocumentUtilClass.setContentWorkspaceDoc(PartnerLibraryId, eachContentDocumentLink.ContentDocumentId));
                                }
                        }

                        if(listOfAttributes.size() > 0) {
                                List<Database.SaveResult> listOfDbResult = DataBase.insert(listOfAttributes, false);
                                for(Integer count=listOfDbResult.size()-1; count>=0; count--) {
                                        Database.SaveResult eachDbResult = listOfDbResult.get(count);
                                        if(!eachDbResult.isSuccess()) {
                                                String errorMessage = '';
                                                for(Database.Error eachError : eachDbResult.getErrors()) {
                                                        errorMessage += eachError.getMessage() + '\n';
                                                }
                                                mapOfFailedData.put(mapOfContentVersionToLinkedEntityId.get(listOfAttributes.get(count).ContentVersionId__c), errorMessage);
                                                listOfContentWorkspaceDoc.remove(count);
                                                listOfAttributes.remove(count);
                                                System.DEBUG(LoggingLevel.ERROR, 'in TriggerClass : errorMessage : ' + errorMessage);
                                        }
                                }
                                List<Error_Log__c> listOfErrorLog = new List<Error_Log__c>();
                                // attributes are added for both internal and partner users, where as the file is linked to library only for internal users
                                if(!Userinfo.getUserType().contains('Partner') && (!GsmUtilClass.isFeatureToggleEnabledCustomMetadata('PartnerFileAccessByContentDeliveries') || Test.isRunningTest())/* SFDC-6265 Add Toggle to disable linking of files to library*/) {
                                        
                                        List<ContentVersionAttribute__c> listOfContentVersionAttributesToBeDeleted = new List<ContentVersionAttribute__c>();

                                        List<Database.SaveResult> listOfDBResultsForContentWorkspaceDoc = DataBase.insert(listOfContentWorkspaceDoc, false);
                                        for(Integer count=listOfDBResultsForContentWorkspaceDoc.size()-1; count>=0; count--) {
                                                Database.SaveResult eachDbResult = listOfDBResultsForContentWorkspaceDoc.get(count);
                                                if(!eachDbResult.isSuccess()) {
                                                        String errorMessage = '';
                                                        Boolean addedToList = false;
                                                        for(Database.Error eachError : eachDbResult.getErrors()) {
                                                                if(!(String.valueOf(eachError.getStatusCode()) == 'FIELD_INTEGRITY_EXCEPTION' && eachError.getMessage().contains('is already shared into Library')) && !addedToList) {
                                                                        addedToList = true;
                                                                        listOfContentVersionAttributesToBeDeleted.add(listOfAttributes.get(count));
                                                                }
                                                                errorMessage += eachError.getMessage() + '\n';
                                                        }
                                                        mapOfFailedData.put(mapOfContentDocumentToLinkedEntityId.get(listOfContentWorkspaceDoc.get(count).ContentDocumentId), errorMessage);
                                                }
                                        }
                                        if(listOfContentVersionAttributesToBeDeleted.size() > 0) {
                                                try {
                                                        delete listOfContentVersionAttributesToBeDeleted;
                                                }
                                                catch (Exception e) {
                                                        Error_Log__c el = new Error_Log__c(Name= 'Error During Deleting Attributes', Class__c='L2Q_ContentDocumentLinkTriggerClass', Error_Message__c = e.getMessage());
                                                        listOfErrorLog.add(el);
                                                }
                                        }
                                }
                                if(mapOfFailedData.size() > 0) {
                                        List<Messaging.SingleEmailMessage>  listOfFailureNotifications = new List<Messaging.SingleEmailMessage>();
                                        for(Id eachId : mapOfFailedData.keySet()) {
                                                Error_Log__c el = new Error_Log__c(Name= String.valueOf(eachId), Class__c='L2Q_ContentDocumentLinkTriggerClass', Error_Message__c = mapOfFailedData.get(eachId));
                                                listOfErrorLog.add(el);
                                                Messaging.SingleEmailMessage eachFailureNotification = new Messaging.SingleEmailMessage();
                                                eachFailureNotification.setSubject('Failure: ContentDocumentLinkTrigger-Attributes/WorkspaceDoc');
                                                eachFailureNotification.setToAddresses(String.valueOf(GSMSettings.getValue('AttributesError_NotificationEmails')).split(','));
                                                eachFailureNotification.setBccSender(false);
                                                eachFailureNotification.setUseSignature(false);
                                                eachFailureNotification.setPlainTextBody('Record Id: ' + eachId + '\n\n Errors Observed: ' + mapOfFailedData.get(eachId));
                                                listOfFailureNotifications.add(eachFailureNotification);
                                        }
                                        insert listOfErrorLog;
                                        Messaging.sendEmail(listOfFailureNotifications);
                                }
                        }
                }
        }

        //SFDC-4702 
        
        public static void addAccountVisibiltyForRelatedFiles(List<ContentDocumentLink> contentDocumentList, Map<String, String> accountMapOfValidObjects, Map<Id, Id> accountMapOfTaskIdVsWhatId) 

        {
                if(addAccountVisibiltyForRelatedFilesHasRun) {
                    return;
                }
                addAccountVisibiltyForRelatedFilesHasRun = true;
                List<Id> listOfRequiredContentDocumentIds = new List<Id>();


                Map<Id,ContentDocumentLink> ContentDocumentIdToCDL = new Map<Id,ContentDocumentLink>();
                

                //List<ContentDocumentLink> cdLinkListToInsert = new List<ContentDocumentLink>();
                Map<Id,List<ContentDocumentLink>> objRecordIdToCDListMap = new Map<Id,List<ContentDocumentLink>>();
                Map<String, List<Id>> mapOfObjectTypeVsListOfRecordIds = new Map<String, List<Id>>();

                Map<Id,Id> objRecordIdToAssAccountIdMap = new Map<Id,Id>();
                //Seperate out Task Content Document Links and build CD for all the tasks files.
                for(ContentDocumentLink eachContentDocumentLink : contentDocumentList) {
                        //listOfRequiredContentDocumentIds.add(eachContentDocumentLink.ContentDocumentId);
                        String objectName = String.valueOf(eachContentDocumentLink.LinkedEntityId.getSObjectType());
                        Boolean taskTransaction = false;
                        if(objectName == 'Task') {
                                taskTransaction = true;
                                if(!accountMapOfTaskIdVsWhatId.isEmpty() && accountMapOfTaskIdVsWhatId.containsKey(eachContentDocumentLink.LinkedEntityId)) 
                                {
                                    ContentDocumentLink cdl = buildContentDocLink(eachContentDocumentLink.ContentDocumentId,accountMapOfTaskIdVsWhatId.get(eachContentDocumentLink.LinkedEntityId));                                
                                    ContentDocumentIdToCDL.put(eachContentDocumentLink.ContentDocumentId,cdl);
                                    //cdLinkListToInsert.add(cdl);
                                }
                            }
                        //Populate map of Record Id of the Content Docuemnt and Content Document List of that record
                        else
                        {
                            if(objRecordIdToCDListMap.containsKey(eachContentDocumentLink.LinkedEntityId))
                            {
                                List<ContentDocumentLink> tempCDList = new List<ContentDocumentLink>();
                                tempCDList = objRecordIdToCDListMap.get(eachContentDocumentLink.LinkedEntityId);
                                tempCDList.add(eachContentDocumentLink);
                                objRecordIdToCDListMap.put(eachContentDocumentLink.LinkedEntityId,tempCDList);

                            }
                            else
                            {
                                List<ContentDocumentLink> tempCDList = new List<ContentDocumentLink>();
                                tempCDList.add(eachContentDocumentLink);
                                objRecordIdToCDListMap.put(eachContentDocumentLink.LinkedEntityId,tempCDList);

                            }
                            //Populate Map of object type like Order Approval/Opportunity to related Records
                            if(mapOfObjectTypeVsListOfRecordIds.containsKey(objectName))
                            {
                                List<Id> tempIdList = new List<Id>();
                                tempIdList = mapOfObjectTypeVsListOfRecordIds.get(objectName);
                                tempIdList.add(eachContentDocumentLink.LinkedEntityId);
                                mapOfObjectTypeVsListOfRecordIds.put(objectName,tempIdList);
                            }
                            else
                            {
                                List<Id> tempIdList = new List<Id>();
                                tempIdList.add(eachContentDocumentLink.LinkedEntityId);
                                mapOfObjectTypeVsListOfRecordIds.put(objectName,tempIdList);
                            }
                        }

                                
                }
                //Populate records by forming dynamic query 
                for(String eachObject : mapOfObjectTypeVsListOfRecordIds.KeySet()) {
                        String query = 'Select Id, ';
                        List<Id> listOfIds = mapOfObjectTypeVsListOfRecordIds.get(eachObject);
                        query += accountMapOfValidObjects.get(eachObject) + ' FROM ' + eachObject + ' WHERE Id IN :listOfIds AND ' + accountMapOfValidObjects.get(eachObject) + ' != null';

                        List<SObject> listOfSObject = Database.query(query);
                        //For each record type where relationship fields decide the association with Account like Order Approval
                        for(SObject eachSObject : listOfSObject) {
                                if(accountMapOfValidObjects.get(eachObject).contains('.'))
                                {

                                    List<String> relationalFieldName = accountMapOfValidObjects.get(eachObject).split('\\.');
                                    Id accountID = Id.valueOf(String.valueOf(eachSObject.getsObject(relationalFieldName[0]).get(relationalFieldName[1])));

                                    objRecordIdToAssAccountIdMap.put(eachSObject.Id, accountID);

                                }
                                else
                                    objRecordIdToAssAccountIdMap.put(eachSObject.Id, Id.valueOf(String.valueOf(eachSObject.get(accountMapOfValidObjects.get(eachObject)))));

                        }
                    }
                    
                for(Id recordID :objRecordIdToCDListMap.keySet())
                {
                    if(!objRecordIdToAssAccountIdMap.isEmpty() && objRecordIdToAssAccountIdMap.containsKey(recordID))
                    {
                        Id accountId = objRecordIdToAssAccountIdMap.get(recordID);
                        for(ContentDocumentLink cdlRec :objRecordIdToCDListMap.get(recordID))
                        {
                           ContentDocumentLink cdl =  buildContentDocLink(cdlRec.ContentDocumentId,accountId);
                           ContentDocumentIdToCDL.put(cdlRec.ContentDocumentId,cdl);    
                           //cdLinkListToInsert.add(cdl);
                        }
                    }
                }
                System.debug('ContentDocumentIdToCDL:'+ContentDocumentIdToCDL);
                if(ContentDocumentIdToCDL.size() > 0)
                {
                    List<ContentDocumentLink> cdLinkListToInsert = new List<ContentDocumentLink>();
                    for(ContentDocument cd : [Select id from ContentDocument where id IN :ContentDocumentIdToCDL.keyset() and filetype != 'SNOTE']){
                        cdLinkListToInsert.add(ContentDocumentIdToCDL.get(cd.Id));
                    }
                    if(cdLinkListToInsert.size()>0){
                        insert cdLinkListToInsert;
                    }
                }
        }

        public static ContentDocumentLink buildContentDocLink(Id contentDocId,Id parentId){
            ContentDocumentLink cdl = new ContentDocumentLink();
                                cdl.ContentDocumentId = contentDocId;
                                cdl.LinkedEntityId = parentId;
                                cdl.ShareType = 'V';
            return cdl;

        }

        //Start SFDC-5434 by Saket
        public static void addCustomNotesAgnstContentNotes(Map<Id, List<Id>> MapParentIdToListOfNotes, Set<Id> contentDocLinkIdSet, Set<String>objectTypeList){
            Map<Id, List<ContentNote>> AccIdToContentNote = new Map<Id, List<ContentNote>>();
            Map<Id, ContentNote> cdLinkToContentNote = new Map<Id, ContentNote>();
            //Map<String,Map<Id,List<ContentNote>>> objToObjIdToContentNoteListMap = new Map<String,Map<Id,List<ContentNote>>>();

            for(ContentNote conNote : [Select Id,Title,LatestPublishedVersionId,Content,CreatedById,CreatedDate,LastModifiedById,LastModifiedDate,TextPreview From ContentNote Where Id IN : contentDocLinkIdSet])
            {
                cdLinkToContentNote.put(conNote.Id ,conNote);
            }

            if(cdLinkToContentNote.size()>0){
                for(Id accId : MapParentIdToListOfNotes.keyset()){
                    for(Id cdlId : MapParentIdToListOfNotes.get(accId)){
                        if(AccIdToContentNote.containsKey(accId)){
                            List<ContentNote> CNlist = AccIdToContentNote.get(accId);
                            CNlist.add(cdLinkToContentNote.get(cdlId));
                            AccIdToContentNote.put(accId, CNlist);

                            }else{
                                List<ContentNote> ListContentNote = new List<ContentNote>();
                                ListContentNote.add(cdLinkToContentNote.get(cdlId));
                                AccIdToContentNote.put(accId, ListContentNote);
                            }
                    }
                }

                Map <String, Object> objectToFieldMap = (Map <String, Object>) JSON.deserializeUntyped(GSMSettings.getVerbose('CustomNotesObjectFieldMapping'));
                

                Map<String, List<Id>> SobjectToId = new Map<String, List<Id>>();

                for(Id objectId : MapParentIdToListOfNotes.keyset()){
                    String ObjType = String.valueOf(objectId.getSObjectType());
                    if(objectToFieldMap.keyset().contains(ObjType)){
                        if(SobjectToId.containsKey(ObjType)){
                            List<Id> objectIdList = SobjectToId.get(ObjType);
                            objectIdList.add(objectId);
                            SobjectToId.put(ObjType, objectIdList);
                            }else{
                                List<Id> AnyId = new List<Id>();
                                AnyId.add(objectId);
                                SobjectToId.put(ObjType, AnyId);

                            }
                    }
                }

                Map<String, String> ObjectToQuery = new Map<String, String>();
                Map <String, Object> fieldMappingForKeyValue = new Map <String, Object>();
                List<Custom_Notes__c> customNotesList = new List<Custom_Notes__c>();

                For(String objName: SobjectToId.keySet()){
                    Object innerKeyValue = objectToFieldMap.get(objName);
                    fieldMappingForKeyValue = (Map <String, Object>)innerKeyValue; 
                    String fieldToQuery = '';
                    String QueryForm = ''; 
                    Set<String> fieldSet = new Set<String>();
                    fieldSet = fieldMappingForKeyValue.KeySet();
                    List<String> fieldList = new List<String>();
                    fieldList.addAll(fieldSet);

                    for (Integer i=0; i < fieldList.size()-1; i++){
                        if(fieldList[i] != null)
                        {
                            fieldToQuery += fieldList[i] + ',';
                        }
                    }
                    fieldToQuery += fieldList[fieldList.size()-1];
                    List<Id> SobjectId = SobjectToId.get(objName);
                    QueryForm = 'Select ' + fieldToQuery + ' From ' + objName + ' Where Id IN: SobjectId';
                    //ObjectToQuery.put(objName, QueryForm);
                    for(Sobject sObj : Database.query(QueryForm) ){
                        List<ContentNote> ContentNoteList = AccIdToContentNote.get(sObj.Id);
                        for(ContentNote cn : ContentNoteList){

                            Custom_Notes__c cnRec = new Custom_Notes__c();

                            SObject sObjCN = Schema.getGlobalDescribe().get('Custom_Notes__c').newSObject();
                            sObjCN.put('Parent_Id__c', sObj.Id);
                            sObjCN.put('Parent_Type__c', objName);
                            sObjCN.put('Notes_Created_By__c',cn.CreatedById);
                            sObjCN.put('Notes_Created_Date__c',cn.CreatedDate);
                            sObjCN.put('Notes_Last_Modified_By__c',cn.LastModifiedById);
                            sObjCN.put('Notes_Last_Modified_Date__c',cn.LastModifiedDate);
                            sObjCN.put('Notes_ID__c',cn.Id);

                            //String S = cn.Content.tostring();


                            sObjCN.put('Notes_Body__c', cn.Content.tostring().stripHtmlTags());
                            sObjCN.put('Note_Title__c', cn.Title);

                            for(String parentFieldRef : fieldMappingForKeyValue.keyset()){
                                sObjCN.put(String.valueOf(fieldMappingForKeyValue.get(parentFieldRef)),sObj.get(parentFieldRef));
                            }

                            cnRec = (Custom_Notes__c)sObjCN;
                            customNotesList.add(cnRec);

                        }

                    }

                }
            if(customNotesList.size()>0)
                //insert customNotesList;
                GsmUtilClass.doDatabaseInsert(customNotesList,'L2Q_ContentDocumentLinkTriggerClass','addCustomNotesAgnstContentNotes',True);
            }

        }

        public static void DeleteCustomNote(List<Id> ContentNoteIdlist){

            List<Custom_Notes__c> CustomNotesList = new List<Custom_Notes__c>();

            for(Custom_Notes__c cn : [Select id from Custom_Notes__c where Notes_ID__c IN :ContentNoteIdlist]){
                CustomNotesList.add(cn);
            }
            If(CustomNotesList.size()>0){
                delete CustomNotesList;
            }

        }

        public static void removeCustomNotelink(Set<Id> EntityId, Set<Id> ContentNoteId){

            List<Custom_Notes__c> CustomNotesList = new List<Custom_Notes__c>();

            for(Custom_Notes__c cn : [Select id from Custom_Notes__c where Notes_ID__c IN :ContentNoteId and Parent_Id__c IN :EntityId]){
                CustomNotesList.add(cn);
            }

            if(CustomNotesList.size()>0){
                delete CustomNotesList;
            }

        }

        //End SFDC-5434

        //SFDC-7779 @nadesai - Start
        //Function to get Map of ContentDocument Id Vs List<ContentDocumentLink> for each CD
        private static Map<Id, List<ContentDocumentLink>> getMapOfRequiredCDLs(List<Id> listOfCDId) {
            al.SoqlBuilder queryBuilder = new al.SoqlBuilder();
            List<String> fieldList = new List<String>{  'Id', 
                                                        'ContentDocumentId', 
                                                        'LinkedEntityId', 
                                                        'ContentDocument.Title'
                                                    };
            //Outer And-Condition
            al.NestableCondition nestAndCondition = new al.AndCondition();
            nestAndCondition.add(new al.SetCondition('ContentDocumentId').inX(listOfCDId));
            //Inner Or-Condition
            // al.NestableCondition nestOrCondition = new al.OrCondition();
            // List<String> listOfSOjects = GSMSettings.getValue('ObjectsForCDLShareTypeUpdate').split(',');
            // for(String eachSobject : listOfSOjects) {
            //     nestOrCondition.add(new al.FieldCondition('LinkedEntity.Type', eachSobject));
            // }
            // //Combine Where Clause
            // nestAndCondition.add(nestOrCondition);
            String queryString =  queryBuilder.selectX(fieldList)
                                .fromX('ContentDocumentLink')
                                .whereX(nestAndCondition)
                                .toSoql();
            Map<Id, List<ContentDocumentLink>> mapOfCDIdVsListOfCDLs = new Map<Id, List<ContentDocumentLink>>();
            try {
                List<ContentDocumentLink> listOfCDL = Database.query(queryString);
                String listOfValidObjects_Str = GSMSettings.getValue('ObjectsForCDLShareTypeUpdate');
                for(ContentDocumentLink eachCDL : listOfCDL) {
                    if(listOfValidObjects_Str.contains(String.valueOf(eachCDL.LinkedEntityId.getSobjectType()))) {
                        List<ContentDocumentLink> associatedCDL = new List<ContentDocumentLink>();
                        if(mapOfCDIdVsListOfCDLs.containsKey(eachCDL.ContentDocumentId)) {
                            associatedCDL = mapOfCDIdVsListOfCDLs.get(eachCDL.ContentDocumentId);
                        }
                        associatedCDL.add(eachCDL);
                        mapOfCDIdVsListOfCDLs.put(eachCDL.ContentDocumentId, associatedCDL);
                    }
                }
            }
            catch(Exception e) {
                Sawyer.saw(e);
            }
            return mapOfCDIdVsListOfCDLs;
        }

        //Formulate Map Of Fund Request Id Vs Fund Request
        private static Map<Id, SFDC_MDF__c> getMapOfRequiredFRs(List<List<ContentDocumentLink>> listListCDL) {
            Map<Id, SFDC_MDF__c> mapOfRequiredFRs = new Map<Id, SFDC_MDF__c>();
            List<ContentDocumentLink> listOfRequiredCDLs = new List<ContentDocumentLink>();
            List<Id> listOfFRIds = new List<Id>();
            for(List<ContentDocumentLink> listCDL : listListCDL) {
                for(ContentDocumentLink eachCDL : listCDL) {
                    if(String.valueOf(eachCDL.LinkedEntityId.getSobjectType()).equalsIgnoreCase('SFDC_MDF__c')) {
                        listOfRequiredCDLs.add(eachCDL);
                        listOfFRIds.add(eachCDL.LinkedEntityId);
                    }
                }
            }
            if(listOfFRIds.size() > 0) {
                mapOfRequiredFRs = new Map<Id, SFDC_MDF__c>([SELECT Id, Status__c FROM SFDC_MDF__c WHERE Id IN :listOfFRIds]);
            }
            return mapOfRequiredFRs;
        }

        //Formulate Map Of Fund Claim Id Vs Fund Claim
        private static Map<Id, SFDC_MDF_Claim__c> getMapOfRequiredFCs(List<List<ContentDocumentLink>> listListCDL) {
            Map<Id, SFDC_MDF_Claim__c> mapOfRequiredFCs = new Map<Id, SFDC_MDF_Claim__c>();
            List<ContentDocumentLink> listOfRequiredCDLs = new List<ContentDocumentLink>();
            List<Id> listOfFCIds = new List<Id>();
            for(List<ContentDocumentLink> listCDL : listListCDL) {
                for(ContentDocumentLink eachCDL : listCDL) {
                    if(String.valueOf(eachCDL.LinkedEntityId.getSobjectType()).equalsIgnoreCase('SFDC_MDF_Claim__c')) {
                        listOfRequiredCDLs.add(eachCDL);
                        listOfFCIds.add(eachCDL.LinkedEntityId);
                    }
                }
            }
            if(listOfFCIds.size() > 0) {
                mapOfRequiredFCs = new Map<Id, SFDC_MDF_Claim__c>([SELECT Id, Status__c FROM SFDC_MDF_Claim__c WHERE Id IN :listOfFCIds]);
            }
            return mapOfRequiredFCs;
        }
        
        //making this map static so that it can be used during after delete functionalities, 
        //As CDLs cannot be queried in After Delete of CDs
        private static Map<Id, List<ContentDocumentLink>> mapOfCDIdVsListOfCDLs;

        //Function to over ride Delete and add custom validation before deletion,
        //On Objects mentioned in 'ObjectsForCDLShareTypeUpdate' GSM Settings Metadata
        public static void contentDocumentBeforeDeleteOverride(Map<Id, ContentDocument> mapOfCDIdVsCD) {
            //First Run Flag check
            if(contentDocumentBeforeDeleteOverrideHasRun) {
                return;
            }
            contentDocumentBeforeDeleteOverrideHasRun = true;

            if(mapOfCDIdVsListOfCDLs == null || mapOfCDIdVsListOfCDLs.size() == 0) {
                mapOfCDIdVsListOfCDLs = getMapOfRequiredCDLs(new List<Id>(mapOfCDIdVsCD.keySet()));
            }
            if(mapOfCDIdVsListOfCDLs.size() > 0) {
                Map<Id, SFDC_MDF__c> mapOfRequiredFRs = getMapOfRequiredFRs(mapOfCDIdVsListOfCDLs.values());
                Map<Id, SFDC_MDF_Claim__c> mapOfRequiredFCs = getMapOfRequiredFCs(mapOfCDIdVsListOfCDLs.values());

                //Get Validation Error Messages
                String AuthorisedProfilesForCDDelete = GSMSettings.getValue('AuthorisedProfilesForCDDelete');
                String NotAuthorizedToDeleteCD_Error = GSMSettings.getValue('NotAuthorizedToDeleteCD_Error');
                
                String FR_picklistValsForCD_DeleteError = GSMSettings.getValue('FR_picklistValsForCD_DeleteError');
                String FC_picklistValsForCD_DeleteError = GSMSettings.getValue('FC_picklistValsForCD_DeleteError');

                String FRApproved_CantDelete_Error = GSMSettings.getValue('FRApproved_CantDelete_Error').replace('#RestrictedStatusHere#', FR_picklistValsForCD_DeleteError.replace(',', '/ '));
                String FCApproved_CantDelete_Error = GSMSettings.getValue('FCApproved_CantDelete_Error').replace('#RestrictedStatusHere#', FC_picklistValsForCD_DeleteError.replace(',', '/ '));

                for(Id eachCDId : mapOfCDIdVsListOfCDLs.keySet()) {
                    ContentDocument requiredCD = mapOfCDIdVsCD.get(eachCDId);
                    for(ContentDocumentLink eachCDL : mapOfCDIdVsListOfCDLs.get(eachCDId)) {
                        //Add validations for each object (if any)
                        if(!AuthorisedProfilesForCDDelete.contains(String.valueOf(UserInfo.getProfileId()))) {
                            requiredCD.addError(NotAuthorizedToDeleteCD_Error);
                        } 
                        else {
                            //Fund Request
                            if(String.valueOf(eachCDL.LinkedEntityId.getSObjectType()).equalsIgnoreCase('SFDC_MDF__c')) {
                                if(mapOfRequiredFRs != null && mapOfRequiredFRs.containsKey(eachCDL.LinkedEntityId) && mapOfRequiredFRs.get(eachCDL.LinkedEntityId).Status__c != null) {
                                    //Split picklist values and check
                                    for(String eachPicklist : FR_picklistValsForCD_DeleteError.split(',')) {
                                        if(eachPicklist.equals(String.valueOf(mapOfRequiredFRs.get(eachCDL.LinkedEntityId).Status__c))) {
                                            requiredCD.addError(FRApproved_CantDelete_Error);
                                            break;
                                        }
                                    }
                                }
                            }
                            //Fund Claim
                            if(String.valueOf(eachCDL.LinkedEntityId.getSObjectType()).equalsIgnoreCase('SFDC_MDF_Claim__c')) {
                                if(mapOfRequiredFCs != null && mapOfRequiredFCs.containsKey(eachCDL.LinkedEntityId) && mapOfRequiredFCs.get(eachCDL.LinkedEntityId).Status__c != null) {
                                    for(String eachPicklist : FC_picklistValsForCD_DeleteError.split(',')) {
                                        if(eachPicklist.equals(String.valueOf(mapOfRequiredFCs.get(eachCDL.LinkedEntityId).Status__c))) {
                                            requiredCD.addError(FCApproved_CantDelete_Error);
                                            break;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // With the List<ContentDocumentLink> for all files that are deleted, query the repective LinkedEntityId and populate ContentDocumentDeletionDetails field with respective ContentDocument Data
        private static void updateRespectiveRecords(List<List<ContentDocumentLink>> listListCDL, String listOfValidObjects_Str) {
            //Convert List<List<ContentDocumentLink>> to List<ContentDocumentLink> for convenience 
            List<ContentDocumentLink> consolidatedCDLs = new List<ContentDocumentLink>();
            for(List<ContentDocumentLink> listCDL : listListCDL) {
                for(ContentDocumentLink eachCDL : listCDL) {
                    consolidatedCDLs.add(eachCDL);
                }
            }

            if(consolidatedCDLs.size() > 0) {
                for(String eachObject : listOfValidObjects_Str.split(',')) {
                    List<Id> listOfSobjectId = new List<Id>();
                    Map<Id, ContentDocumentLink> mapOfLinkedEntityIdVsCDL = new Map<Id, ContentDocumentLink>();
                    // remove used up CDLs as each CDL can map to only one family of SObject
                    for(Integer i = consolidatedCDLs.size() - 1; i >= 0; i--) {
                        ContentDocumentLink eachCDL = consolidatedCDLs.get(i);
                        if(String.valueOf(eachCDL.LinkedEntityId.getSobjectType()).equalsIgnoreCase(eachObject)) {
                            listOfSobjectId.add(eachCDL.LinkedEntityId);
                            //Formulate Reverse map from LinkedEntityId to CDL
                            mapOfLinkedEntityIdVsCDL.put(eachCDL.LinkedEntityId, eachCDL);
                            consolidatedCDLs.remove(i);
                        }
                    }
                    //If no records on a particular SObject Family, Continue
                    if(listOfSobjectId.size() == 0) {
                        continue;
                    }
                    //Dynamic Query : @CodeScan - Cannot move outside Loop 
                    //The loop size depends on number of objects mentioned in metadata, if not built dynamically would still consume same number of SOQL Queries
                    al.SoqlBuilder queryBuilder = new al.SoqlBuilder();
                    List<String> fieldList = new List<String>{'Id', 'ContentDocumentDeletionDetails__c'};
                    Schema.SObjectType sobjectType = Schema.getGlobalDescribe().get(eachObject);
                    Map<String, Schema.SObjectField> schemaFieldMap = sobjectType.getDescribe().fields.getMap();
                    if(schemaFieldMap.containsKey('Validation_Override__c')) {
                        fieldList.add('Validation_Override__c');
                    }
                    al.NestableCondition nestAndCondition = new al.AndCondition();
                    nestAndCondition.add(new al.SetCondition('Id').inX(listOfSobjectId));
                    String queryString =  queryBuilder.selectX(fieldList)
                                            .fromX(eachObject)
                                            .whereX(nestAndCondition)
                                            .toSoql();
                    try {
                        List<SObject> listOfRequiredRecords = Database.query(queryString);
                        List<SObject> listOfRecordsToUpdate = new List<SObject>();
                        for(SObject eachSobjectRecord : listOfRequiredRecords) {
                            if(mapOfLinkedEntityIdVsCDL.containsKey(eachSobjectRecord.Id)) {
                                String valueStr = 'Id : ' + mapOfLinkedEntityIdVsCDL.get(eachSobjectRecord.Id).ContentDocumentId + '\nTitle : ' + mapOfLinkedEntityIdVsCDL.get(eachSobjectRecord.Id).ContentDocument.Title;
                                //Trim to 255 Characters if valueStr  Exceeds 255 Chars
                                if(valueStr.length() > 255) {
                                    eachSobjectRecord.put('ContentDocumentDeletionDetails__c', valueStr.substring(0, 255));
                                } else {
                                    eachSobjectRecord.put('ContentDocumentDeletionDetails__c', valueStr);
                                }
                                if(schemaFieldMap.containsKey('Validation_Override__c')) {
                                    eachSobjectRecord.put('Validation_Override__c', true);
                                }
                                listOfRecordsToUpdate.add(eachSobjectRecord);
                            }
                        }
                        if(listOfRecordsToUpdate.size() > 0) {
                            update listOfRecordsToUpdate;
                        }
                        
                    }
                    catch(Exception e) {
                        //System.DEBUG('ND_D : After Delete - 5 : e : ' + e);
                        Sawyer.saw(e);
                    }
                }
            }
        }

        //Function to update ContentDocumentDeletionDetails Field on objects mentioned in 'ObjectsForCDLShareTypeUpdate' GSM Settings Metadata
        //While extending the generic Delete Functionality to other objects, make sure a text area field of 255 length is created by the name of 'ObjectsForCDLShareTypeUpdate', And enable History Tracking for the same
        public static void contentDocumentAfterDeleteOverride(Map<Id, ContentDocument> mapOfCDIdVsCD) {
            //First Run Flag check
            if(contentDocumentAfterDeleteOverrideHasRun) {
                return;
            }
            contentDocumentAfterDeleteOverrideHasRun = true;

            if(mapOfCDIdVsListOfCDLs != null && mapOfCDIdVsListOfCDLs.size() > 0) {
                String listOfValidObjects_Str = GSMSettings.getValue('ObjectsForCDLShareTypeUpdate');
                if(listOfValidObjects_Str != null && listOfValidObjects_Str != '') {
                    updateRespectiveRecords(mapOfCDIdVsListOfCDLs.values(), listOfValidObjects_Str);
                }
            }
        }
        //SFDC-7779 @nadesai - End
}