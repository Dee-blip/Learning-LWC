/**
   @author: Nagaraj Desai
   SFDC-4283 : Make Files Visible To Partner Users
 * History:
 * =========================
 * Developer        Date        Description

   Nagaraj Desai    05/Feb/19        Added this class for SFDC-4283.
   =========================
   Related Test Class: L2Q_ContentDocumentLinkTriggerTests
 **/
 
public without sharing class L2Q_ContentDocumentLinkTriggerHandler extends ApexTriggerHandlerAbstractClass {
        public class ObjectCustom {
                public String ObjectName;
                public String PartnerAccount;

                public ObjectCustom() {
                }
        }

        public class AccountObjectCustom {
                public String ObjectName;
                public String FieldAPI;

                public AccountObjectCustom() {
                }
        }
        
        

        public L2Q_ContentDocumentLinkTriggerHandler() {
        }
        static String L2Q_ObjectsForPartnerAttributesBatchJSON;
        static Map<Id, Id> mapOfTaskIdVsWhatId;
        static Map<String, String> mapOfValidObjects;
        static Map <String, Object> objectToFieldMap;
        public override void beforeInsertBeforeUpdateTrigger() {
                if(Trigger.isInsert) {
                        if(L2Q_ObjectsForPartnerAttributesBatchJSON == null || L2Q_ObjectsForPartnerAttributesBatchJSON == '') {
                                L2Q_ObjectsForPartnerAttributesBatchJSON = GSMSettings.getVerbose('L2Q_ObjectsForPartnerAttributesBatchJSON');
                        }
                        List<ObjectCustom> listOfObjects = (List<ObjectCustom>)JSON.deserialize(L2Q_ObjectsForPartnerAttributesBatchJSON, List<ObjectCustom>.Class);
                        if(mapOfValidObjects == null) {
                                mapOfValidObjects = new Map<String, String>();
                                for(ObjectCustom eachObject : listOfObjects) {
                                        mapOfValidObjects.put(eachObject.ObjectName, eachObject.PartnerAccount);
                                }
                        }

                        Map<Id, ContentDocumentLink> mapOfTaskIdsVsContentDocumentLink = new Map<Id, ContentDocumentLink>();
                        
                        for(SObject eachSObject : newList) {
                                ContentDocumentLink newContentDocumentLink = (ContentDocumentLink) eachSObject;
                                if(newContentDocumentLink.LinkedEntityId.getSObjectType() == Task.SObjectType) {
                                        mapOfTaskIdsVsContentDocumentLink.put(newContentDocumentLink.LinkedEntityId, newContentDocumentLink);
                                }
                        }
                        
                        if(mapOfTaskIdVsWhatId == null || mapOfTaskIdVsWhatId.size() == 0) {
                                mapOfTaskIdVsWhatId = new Map<Id, Id>();

                                if(mapOfTaskIdsVsContentDocumentLink.size() > 0) {
                                        for(Task eachTask : [SELECT Id, WhatId FROM Task WHERE Id IN :mapOfTaskIdsVsContentDocumentLink.keySet()]) {
                                                if(mapOfValidObjects.containsKey(String.valueOf(eachTask.WhatId.getSObjectType()))) {
                                                        mapOfTaskIdVsWhatId.put(eachTask.Id, eachTask.WhatId);
                                                }
                                        }
                                }
                        }

                        for(SObject eachSObject : newList) {
                                ContentDocumentLink newContentDocumentLink = (ContentDocumentLink) eachSObject;
                                if(mapOfValidObjects.containsKey(String.valueOf(newContentDocumentLink.LinkedEntityId.getSObjectType())) || (newContentDocumentLink.LinkedEntityId.getSObjectType() == Task.SObjectType && mapOfTaskIdVsWhatId.containsKey(newContentDocumentLink.LinkedEntityId)) && newContentDocumentLink.Visibility != 'AllUsers') {
                                        newContentDocumentLink.Visibility = 'AllUsers';
                                        System.DEBUG('eachSObject: ' + eachSObject);
                                }
                                //SFDC-7398 - If use duplicate files toogle is switched off and the contentdocument link on OA is getting added with share type as V, then make it I so that it can be linked for further reference on POA
                                if(newContentDocumentLink.LinkedEntityId.getSObjectType() == Order_Approval__c.SObjectType && !GsmUtilClass.isFeatureToggleEnabledCustomMetadata('useDuplicateFilesFOrPOA') && newContentDocumentLink.ShareType == 'V') {
                                        newContentDocumentLink.ShareType = 'I';
                                }
                                //SFDC-7779 - Start : @nadesai - Update CDL's share type to 'I' on FR and FCs
                                System.DEBUG(LoggingLevel.ERROR, 'ND_D : Here : ' + newContentDocumentLink);
                                if((newContentDocumentLink.ShareType == 'null' || newContentDocumentLink.ShareType == 'V') && GSMSettings.getValue('ObjectsForCDLShareTypeUpdate').contains(String.valueOf(newContentDocumentLink.LinkedEntityId.getSObjectType()))) {
                                        System.DEBUG(LoggingLevel.ERROR, 'ND_D : inside : ' + newContentDocumentLink);
                                        newContentDocumentLink.ShareType = 'I';
                                }
                                //SFDC-7779 - End
                        }
                }

        }
        public override void beforeDeleteBeforeUndeleteTrigger() {
                System.debug('before delete content document link');
                //Map<Id,List<Id>> LinkedEntityIdToContentDocId = new Map<Id,List<Id>>();
                //Start SFDC-5434
                List<ContentDocumentLink> oldContentDocumentLinkList = (List<ContentDocumentLink>) oldList;
                Set<Id> EntityId = new Set<Id>();
                Set<Id> ContentNoteId = new Set<Id>();
                List<ContentDocumentLink> listOfCDLsNotToDelete = new List<ContentDocumentLink>();
                //SFDC-7779 - Start
                String ObjectsForCDLShareTypeUpdate = GSMSettings.getValue('ObjectsForCDLShareTypeUpdate');
                String CDL_DeleteRestrictionMessage = GSMSettings.getValue('CDL_DeleteRestrictionMessage');
                //SFDC-7779 - End

                for(ContentDocumentLink cdl : oldContentDocumentLinkList){
                        EntityId.add(cdl.LinkedEntityId);
                        ContentNoteId.add(cdl.ContentDocumentId);
                        //SFDC-7779 - Start
                        if(ObjectsForCDLShareTypeUpdate.contains(String.valueOf(cdl.LinkedEntityId.getSObjectType()))) {
                                cdl.addError(CDL_DeleteRestrictionMessage);
                        }
                        //SFDC-7779 - End
                }

                if(EntityId.size()>0){
                        L2Q_ContentDocumentLinkTriggerClass.removeCustomNotelink(EntityId,ContentNoteId);
                }
                //Start SFDC-5434

        }

        public override void afterInsertAfterUpdateTrigger() {
                if(Trigger.isInsert) {
                        if(L2Q_ObjectsForPartnerAttributesBatchJSON == null || L2Q_ObjectsForPartnerAttributesBatchJSON == '') {
                                L2Q_ObjectsForPartnerAttributesBatchJSON = GSMSettings.getVerbose('L2Q_ObjectsForPartnerAttributesBatchJSON');
                        }
                        
                        String L2Q_ObjectsForAccountFileSyncBatchJSON = '';
                        L2Q_ObjectsForAccountFileSyncBatchJSON = GSMSettings.getVerbose('L2Q_AccountFileSyncObjectToField');
                        
                        
                        List<ObjectCustom> listOfObjects = (List<ObjectCustom>)JSON.deserialize(L2Q_ObjectsForPartnerAttributesBatchJSON, List<ObjectCustom>.Class);
                        if(mapOfValidObjects == null || mapOfValidObjects.size() == 0) {
                                mapOfValidObjects = new Map<String, String>();
                                for(ObjectCustom eachObject : listOfObjects) {
                                        mapOfValidObjects.put(eachObject.ObjectName, eachObject.PartnerAccount);
                                }
                        }

                        List<AccountObjectCustom> listOfAccountObjects = (List<AccountObjectCustom>)JSON.deserialize(L2Q_ObjectsForAccountFileSyncBatchJSON, List<AccountObjectCustom>.Class);
                        Map<String,String> accountSyncMapOfValidObjects = new Map<String, String>();
                        List<ContentDocumentLink> accountListOfContentDocumentLink = new List<ContentDocumentLink>();
                        Map<Id,Id> accountMapOfTaskIdVsWhatId = new Map<Id,Id>();


                        for(AccountObjectCustom eachObject : listOfAccountObjects) 
                            {
                                accountSyncMapOfValidObjects.put(eachObject.ObjectName,eachObject.FieldAPI);
                            }

                        
                        List<ContentDocumentLink> listOfContentDocumentLink = new List<ContentDocumentLink>();
                        Map<Id, ContentDocumentLink> mapOfTaskIdsVsContentDocumentLink = new Map<Id, ContentDocumentLink>();
                        
                        
                        System.debug(LoggingLevel.ERROR, 'ND_D mapOfValidObjects: ' + mapOfValidObjects);

                        //Start SFDC-5434 
                        if(objectToFieldMap == null) {
                            objectToFieldMap = (Map <String, Object>) JSON.deserializeUntyped(GSMSettings.getVerbose('CustomNotesObjectFieldMapping'));
                        }
                        Map<Id,ContentDocumentLink> MapOfParentIdToCDLForNotes = new Map<Id,ContentDocumentLink>();
                        Set<Id> contentDocLinkIdSet = new Set<Id>();
                        Set<String> objectTypeList = new Set<String>();

                        Map<Id,List<Id>>MapParentIdToListOfNotes = new Map<Id,List<Id>>();

                        //End SFDC-5434

                        for(SObject eachSObject : newList) {
                                ContentDocumentLink newContentDocumentLink = (ContentDocumentLink) eachSObject;

                                System.debug(LoggingLevel.ERROR, 'ND_D String.valueOf(newContentDocumentLink.LinkedEntityId.getSObjectType()): ' + String.valueOf(newContentDocumentLink.LinkedEntityId.getSObjectType()));
                                if(mapOfValidObjects.containsKey(String.valueOf(newContentDocumentLink.LinkedEntityId.getSObjectType()))) {
                                        listOfContentDocumentLink.add(newContentDocumentLink);
                                }
                                if(accountSyncMapOfValidObjects.containsKey(String.valueOf(newContentDocumentLink.LinkedEntityId.getSObjectType()))) {
                                        accountListOfContentDocumentLink.add(newContentDocumentLink);
                                }                                
                                if(newContentDocumentLink.LinkedEntityId.getSObjectType() == Task.SObjectType) {
                                        mapOfTaskIdsVsContentDocumentLink.put(newContentDocumentLink.LinkedEntityId, newContentDocumentLink);
                                }

                                //Start SFDC-5434
                                if(objectToFieldMap.containsKey(String.valueOf(newContentDocumentLink.LinkedEntityId.getSObjectType()))){

                                    contentDocLinkIdSet.add(newContentDocumentLink.ContentDocumentId);
                                    objectTypeList.add(String.valueOf(newContentDocumentLink.LinkedEntityId.getSObjectType()));

                                    if(MapParentIdToListOfNotes.containsKey(newContentDocumentLink.LinkedEntityId)){
                                        List<Id> CDLList = MapParentIdToListOfNotes.get(newContentDocumentLink.LinkedEntityId);
                                        CDLList.add(newContentDocumentLink.ContentDocumentId);
                                        MapParentIdToListOfNotes.put(newContentDocumentLink.LinkedEntityId, CDLList);
                                    }
                                    else{
                                        List<Id> CDL = new List<Id>();
                                        CDL.add(newContentDocumentLink.ContentDocumentId);
                                        MapParentIdToListOfNotes.put(newContentDocumentLink.LinkedEntityId, CDL);
                                    }

                                }
                                //End SFDC-5434

                        }
                    


                        /*if(mapOfTaskIdVsWhatId == null) {
                                mapOfTaskIdVsWhatId = new Map<Id, Id>();
                            }
                                if(mapOfTaskIdsVsContentDocumentLink.size() > 0) {
                                        for(Task eachTask : [SELECT Id, WhatId FROM Task WHERE Id IN :mapOfTaskIdsVsContentDocumentLink.keySet()]) {
                                                
                                                if(mapOfTaskIdVsWhatId.isEmpty() && mapOfValidObjects.containsKey(String.valueOf(eachTask.WhatId.getSObjectType()))) {
                                                        listOfContentDocumentLink.add(mapOfTaskIdsVsContentDocumentLink.get(eachTask.Id));
                                                        mapOfTaskIdVsWhatId.put(eachTask.Id, eachTask.WhatId);
                                                }
                                                else if(String.valueOf(eachTask.WhatId.getSObjectType()) == 'Account')
                                                {
                                                    accountMapOfTaskIdVsWhatId.put(eachTask.Id, eachTask.WhatId);
                                                    accountListOfContentDocumentLink.add(mapOfTaskIdsVsContentDocumentLink.get(eachTask.Id));
                                                }

                                            }
                                        }*/
                        //SFDC-4702 - Seperated the SOQL so that it can be used with different conditions
                        List<Task> taskList = new List<Task>();
                        if(!mapOfTaskIdsVsContentDocumentLink.isEmpty()) 
                              taskList =  [SELECT Id, WhatId FROM Task WHERE Id IN :mapOfTaskIdsVsContentDocumentLink.keySet()];

                        if(taskList.size() > 0)
                        {
                            for(Task eachTask : taskList) {
                                        if(mapOfValidObjects.containsKey(String.valueOf(eachTask.WhatId.getSObjectType()))) {
                                                listOfContentDocumentLink.add(mapOfTaskIdsVsContentDocumentLink.get(eachTask.Id));
                                        }
                                        if(String.valueOf(eachTask.WhatId.getSObjectType()) == 'Account') {
                                                accountMapOfTaskIdVsWhatId.put(eachTask.Id, eachTask.WhatId);
                                                accountListOfContentDocumentLink.add(mapOfTaskIdsVsContentDocumentLink.get(eachTask.Id));
                                        }
                            }
                        }



                        if(listOfContentDocumentLink.size() > 0) {
                                System.debug('ND_D: inside listOfContentDocumentLink.size() > 0: ' + listOfContentDocumentLink + ' mapOfValidObjects: ' + mapOfValidObjects + ' mapOfTaskIdVsWhatId: ' + mapOfTaskIdVsWhatId);
                                L2Q_ContentDocumentLinkTriggerClass.addAttributesAndLinkToPartnerFacingLibrary(listOfContentDocumentLink, mapOfValidObjects, mapOfTaskIdVsWhatId);
                        }


                        System.debug(LoggingLevel.ERROR,'Map '+accountListOfContentDocumentLink);

                        System.debug('ND_D: listOfContentDocumentLink: ' + listOfContentDocumentLink + ' mapOfValidObjects: ' + mapOfValidObjects + ' mapOfTaskIdVsWhatId: ' + mapOfTaskIdVsWhatId);

                        if( !accountSyncMapOfValidObjects.isEmpty())
                            L2Q_ContentDocumentLinkTriggerClass.addAccountVisibiltyForRelatedFiles(accountListOfContentDocumentLink,accountSyncMapOfValidObjects,accountMapOfTaskIdVsWhatId);

                        //Start SFDC-5434
                        if(!MapParentIdToListOfNotes.isEmpty())
                        {
                            system.debug('Map '+MapParentIdToListOfNotes);
                            //L2Q_ContentDocumentLinkTriggerClass.addCustomNotesAgainstContentNotes(MapOfParentIdToCDLForNotes,contentDocLinkIdSet,objectTypeList);
                            L2Q_ContentDocumentLinkTriggerClass.addCustomNotesAgnstContentNotes(MapParentIdToListOfNotes, contentDocLinkIdSet, objectTypeList);
                        }
                        //End SFDC-5434

                }

        }
        public override void afterDeleteAfterUndeleteTrigger() {
        }
}
//Resolved Conflict