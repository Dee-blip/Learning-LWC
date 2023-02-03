global class L2Q_POA_NoFilesFixerBatch extends GenericBatchClass  {

    global String MailMessage = '';
    global L2Q_POA_NoFilesFixerBatch() {
        super();
        
		operationType = 'Update';
		className = 'L2Q_POA_NoFilesFixerBatch';
        query = 'SELECT Id, Name, ContenDocumentId__c, Attachment__c, Validation_Override__c, Opportunity__c, Opportunity__r.Partner_Involved__c, Order_Acceptance_Status__c From Partner_Order_Acceptance_Document__c Where CreatedDate = LAST_N_DAYS:' + GSMSettings.getInt('POA_NoFilesFixerBatchLastNDays'); 
    }  

    global override void execute(Database.BatchableContext BC,List<SObject> scope){
        try {
            Map<Id, Partner_Order_Acceptance_Document__c> MapOfrecentPOADs = new Map<Id, Partner_Order_Acceptance_Document__c>();
            for(SObject eachRecord : scope) {
                Partner_Order_Acceptance_Document__c eachPOA = (Partner_Order_Acceptance_Document__c) eachRecord;
                MapOfrecentPOADs.put(eachPOA.Id, eachPOA);
            }

            List<ContentDocumentLink> recentDocumentLinks = [SELECT Id, LinkedEntityId FROM ContentDocumentLink Where LinkedEntityId = :MapOfrecentPOADs.keySet()];
            Set<Id> poasWithCDL = new Set<Id>();
            for(ContentDocumentLink eachCDL : recentDocumentLinks) {
                poasWithCDL.add(eachCDL.LinkedEntityId);
            }
            List<Partner_Order_Acceptance_Document__c> POAsWithoutCDL = new List<Partner_Order_Acceptance_Document__c>();
            List<Id> listOfAssociateOppty = new List<Id>();
            MailMessage += '<br /><br />Ids of Existing POAs Without Files Attached : ';
            for(Partner_Order_Acceptance_Document__c eachPOA : MapOfrecentPOADs.values()) {
                if(!poasWithCDL.contains(eachPOA.Id)) {
                    POAsWithoutCDL.add(eachPOA);
                    MailMessage += eachPOA.Id + ', ';
                    listOfAssociateOppty.add(eachPOA.Opportunity__c);
                }
            }

            MailMessage += '<br /><br />Number of Existing POAs Without Files Attached : ' + POAsWithoutCDL.size();

            if(POAsWithoutCDL.size() > 0) {

                Map<Id, Order_Approval__c> OAMap = new Map<Id, Order_Approval__c>([Select Id, Associated_Opportunity__c From Order_Approval__c Where Associated_Opportunity__c  = :listOfAssociateOppty]);
                List<ContentDocumentLink> allCDLs = [SELECT Id, LinkedEntityId, ContentDocument.LatestPublishedVersionId, ContentDocument.Title FROM ContentDocumentLink Where LinkedEntityId = :OAMap.values() OR LinkedEntityId = :listOfAssociateOppty];
                Map<Id, List<ContentDocumentLink>> mapOfOpptyIdVsPotentialCDLs = new Map<Id, List<ContentDocumentLink>>();
                Map<Id, String> mapOfCvIdVsTitle = new Map<Id, String>();

                for(ContentDocumentLink eachCDL : allCDLs) {

                    if(!mapOfCvIdVsTitle.containsKey(eachCDL.ContentDocument.LatestPublishedVersionId)) {
                        mapOfCvIdVsTitle.put(eachCDL.ContentDocument.LatestPublishedVersionId, String.valueOf(ContentDocument.Title));
                    }
                    Id opprtyId;
                    if(eachCDL.LinkedEntityId.getSobjectType() == Order_Approval__c.SObjectType) {
                        opprtyId = OAMap.get(eachCDL.LinkedEntityId).Associated_Opportunity__c;
                    } 
                    else {
                        opprtyId = eachCDL.LinkedEntityId;
                    }
                    
                    List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();
                    if(mapOfOpptyIdVsPotentialCDLs.containsKey(opprtyId)) {
                        cdlList = mapOfOpptyIdVsPotentialCDLs.get(opprtyId);
                    }
                    cdlList.add(eachCDL);
                    mapOfOpptyIdVsPotentialCDLs.put(opprtyId, cdlList);
                }

                String tableForPOAWIthFilesAttached = '';
                String tableForPOAWIthoutFilesAttached = '';

                Map<Id, Id> mapOfPoaIdVsCVId = new Map<Id, Id>();
                for(Partner_Order_Acceptance_Document__c eachPOA : POAsWithoutCDL) {
                    String matchName = eachPOA.Name.substringBeforeLast('.');
                    List<Id> listOfMatchingCVIds = new List<Id>();
                    for(ContentDocumentLink eachCL : mapOfOpptyIdVsPotentialCDLs.get(eachPOA.Opportunity__c)) {
                        if(eachCL.ContentDocument.Title.startsWith(matchName)) {
                            listOfMatchingCVIds.add(eachCL.ContentDocument.LatestPublishedVersionId);
                        }
                    }
                    if(listOfMatchingCVIds.size() == 1) {
                        mapOfPoaIdVsCVId.put(eachPOA.Id, listOfMatchingCVIds.get(0));
                        tableForPOAWIthFilesAttached += '<br /><br />POA : ' + eachPOA.Id + ' -> Original CV : ' + listOfMatchingCVIds.get(0);
                    }
                    else if(listOfMatchingCVIds.size() > 1 ) {
                        Boolean attchFile = true;
                        String titleOfFile = '';
                        if(mapOfCvIdVsTitle.containsKey(listOfMatchingCVIds.get(0))) {
                            titleOfFile = mapOfCvIdVsTitle.get(listOfMatchingCVIds.get(0));
                        }
                        for(Id eachId : listOfMatchingCVIds) {
                            if(!titleOfFile.equals(mapOfCvIdVsTitle.get(eachId))) {
                                attchFile = false;
                                break;
                            }
                        }
                        if(attchFile) {
                            mapOfPoaIdVsCVId.put(eachPOA.Id, listOfMatchingCVIds.get(0));
                            tableForPOAWIthFilesAttached += '<br /><br />POA : ' + eachPOA.Id + ' -> Original CV : ' + listOfMatchingCVIds.get(0) + ' , Other Matching CVs : ' + listOfMatchingCVIds;
                        } else {
                            tableForPOAWIthoutFilesAttached += '<br /><br /> POA : ' + eachPOA.Id + ' -> Associated Oppty : ' +  eachPOA.Opportunity__c + ' listOfMatchingCVIds : ' + listOfMatchingCVIds;
                        }
                    } 
                    else {
                        tableForPOAWIthoutFilesAttached += '<br /><br /> POA : ' + eachPOA.Id + ' -> Associated Oppty : ' +  eachPOA.Opportunity__c + ' listOfMatchingCVIds : ' + listOfMatchingCVIds;
                    }  
                }

                MailMessage += '<br /><br />Table For POA With Files Attached Now: ' + tableForPOAWIthFilesAttached;
                MailMessage += '<br /><br />Table For POA Without Files Attached Now: ' + tableForPOAWIthoutFilesAttached;

                Map<Id, ContentVersion> mapOfCV = new Map<Id, ContentVersion>([SELECT Id, ContentDocumentId, ContentLocation, PathOnClient, Title, VersionData FROM ContentVersion Where Id = :mapOfPoaIdVsCVId.values()]);
                List<ContentVersion> newCVList = new List<ContentVersion>();
                if(mapOfPoaIdVsCVId.size() > 0 ) {
                    List<ContentVersionAttribute__c> listOfContentVersionAttributes = new List<ContentVersionAttribute__c>();
                    //if duplicate toggle is on, then create duplicates
                    if(GsmUtilClass.isFeatureToggleEnabledCustomMetadata('useDuplicateFilesFOrPOA') || Test.isRunningTest()) {
                        for(Id poaId : mapOfPoaIdVsCVId.keySet()) {
                            ContentVersion cv = L2Q_ContentDocumentUtilClass.setContentVersion('S', mapOfCV.get(mapOfPoaIdVsCVId.get(poaId)).PathOnClient, mapOfCV.get(mapOfPoaIdVsCVId.get(poaId)).Title, mapOfCV.get(mapOfPoaIdVsCVId.get(poaId)).VersionData);
                            cv.FirstPublishLocationId = poaId;
                            newCVList.add(cv);
                        }
                        insert newCVList;
                        List<ContentVersion> insertedCVs = [Select Id, ContentDocumentId, FirstPublishLocationId FROM ContentVersion Where Id = :newCVList];

                        List<Partner_Order_Acceptance_Document__c> poadToUpdate = new List<Partner_Order_Acceptance_Document__c>();
                        for(ContentVersion cv : insertedCVs) {
                            if(MapOfrecentPOADs.containsKey(cv.FirstPublishLocationId)) {
                                Partner_Order_Acceptance_Document__c eachPoad = MapOfrecentPOADs.get(cv.FirstPublishLocationId);
                                eachPoad.Attachment__c = cv.Id;
                                eachPoad.ContenDocumentId__c = cv.ContentDocumentId;
                                eachPoad.Validation_Override__c = true;
                                poadToUpdate.add(eachPoad);
                                listOfContentVersionAttributes.add(L2Q_ContentDocumentUtilClass.setContentVersionAttribute(cv.Id, 'Partner Account', eachPoad.Opportunity__r.Partner_Involved__c));
                            }
                        }
                        if(poadToUpdate.size() > 0) {
                            update poadToUpdate;
                            List<ContentDocumentLink> cdlinkList = [SELECT Id, ShareType, Visibility FROM ContentDocumentLink WHERE LinkedEntityId = :mapOfPoaIdVsCVId.keySet()];
                            for(ContentDocumentLink eachcdl : cdlinkList) {
                                eachcdl.ShareType = 'I';
                                eachcdl.Visibility = 'AllUsers';
                            }
                            update cdlinkList;
                        }
                    }
                    //if duplicate toggle is off, just create links
                    else {
                        List<ContentDocumentLink> listOfCDLs = new List<ContentDocumentLink>();
                        for(Partner_Order_Acceptance_Document__c eachPOA : POAsWithoutCDL) {
                            if(mapOfPoaIdVsCVId.containsKey(eachPOA.Id)) {
                                listOfCDLs.add(L2Q_ContentDocumentUtilClass.setContentDocumentLink(mapOfCV.get(mapOfPoaIdVsCVId.get(eachPOA.Id)).ContentDocumentId, eachPOA.Id, 'I', 'AllUsers'));
                                listOfContentVersionAttributes.add(L2Q_ContentDocumentUtilClass.setContentVersionAttribute(mapOfPoaIdVsCVId.get(eachPOA.Id), 'Partner Account', eachPOA.Opportunity__r.Partner_Involved__c));
                            }
                        }
                        if(listOfCDLs.size() > 0) {
                                insert listOfCDLs;
                        }
                    }

                    if(listOfContentVersionAttributes.size() > 0) {
                        insert listOfContentVersionAttributes;
                    }
                }
            }
        }
        catch (Exception e) {
            MailMessage += '<br /> Exception : <br />' + String.valueOf(e) + e.getStackTraceString() + e.getLineNumber();
        }
    }     
    
    global override void finish(Database.BatchableContext BC){
        super.finish(BC);
        List<String> recepients = new List<String>();
        recepients.add('nadesai@akamai.com');
        recepients.add('rsharma@akamai.com');
        EmailUtils.sendHTMLEmail(recepients,'Alert: Stats of DataFix for POAs without Files', MailMessage);
    }
    
}