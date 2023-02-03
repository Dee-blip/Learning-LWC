public without sharing class L2Q_DocusignForPartnerPassThrough {
    public L2Q_DocusignForPartnerPassThrough() {}

    @AuraEnabled
    public static boolean isCommunity(){
        Id siteId = Network.getNetworkId(); 
        if (siteId != null) {
            return true;
        }
        return false;
    }

    @AuraEnabled
    public static string checkIfTNCSigningIsNeeded(String poaId){
        Partner_Order_Acceptance_Document__c thisPoa = [SELECT Id, 
        Opportunity__r.Account.T_Cs_Signed__c, 
        Opportunity__r.Partner_Involved__r.Partner_Type__c 
        FROM Partner_Order_Acceptance_Document__c WHERE Id = :poaId];

        // this process applies only to associate partners
        if(!thisPoa.Opportunity__r.Partner_Involved__r.Partner_Type__c.equalsIgnoreCase('Associate Partner'))
            return NAPSettings.getValue('SendTNCErrorOnlyForAssociates');
        if(thisPoa.Opportunity__r.Account.T_Cs_Signed__c==true)
            return NAPSettings.getValue('SendTNCErrorAlreadySigned');
        return 'needed';
    }
        @AuraEnabled
        public static List<ContentDocumentLink> initCon(String poaId) {
            List<Id> idList = new List<Id>();
            
            Partner_Order_Acceptance_Document__c thisPoa = [SELECT Id, Opportunity__c FROM Partner_Order_Acceptance_Document__c WHERE Id = :poaId];
            idList.add(thisPoa.Id);
  
            List<ContentDocumentLink> lcd = [SELECT Id, ContentDocument.Title, ContentDocument.LatestPublishedVersionId, ContentDocument.LatestPublishedVersion.Title, 
                                                ContentDocument.ContentModifiedDate, ContentDocument.LatestPublishedVersion.ContentModifiedBy.Name, LinkedEntity.Type 
                                                FROM ContentDocumentLink Where LinkedEntityId = :idList AND ContentDocument.LatestPublishedVersion.Tag__c 
                                                LIKE :GSMSettings.getValue('Passthrough_TC') ORDER BY ContentDocument.LatestPublishedVersion.lastModifiedDate DESC];
            return lcd;
        }

        @AuraEnabled
        public static String updateTags(String contentVersionId, String recordId) {
            try {
                ContentDocument cd = [SELECT Id, LatestPublishedVersionId, LatestPublishedVersion.VersionData, LatestPublishedVersion.pathOnClient, LatestPublishedVersion.Title FROM ContentDocument WHERE LatestPublishedVersionId = :contentVersionId];
                ContentVersion dup = L2Q_ContentDocumentUtilClass.setContentVersion('S', cd.LatestPublishedVersion.PathOnClient, cd.LatestPublishedVersion.Title, cd.LatestPublishedVersion.VersionData);
                dup.TagCsv = GSMSettings.getValue('Passthrough_TC');
    
                    insert dup;
                    delete cd;
    
                    ContentVersion inCV = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :dup.Id];
                    ContentDocumentLink contentDocumentLinkRecord = L2Q_ContentDocumentUtilClass.setContentDocumentLink(inCV.ContentDocumentId, recordId, 'I', 'AllUsers');
                    insert contentDocumentLinkRecord;
    
                }
                catch(Exception e) {
                    Sawyer.saw(e);
                    throw e;
                }
    
                return 'Successful';
        }

        @AuraEnabled
        public static String createRestEnvelop(String name, String email, String sourceId, String documentId) {
           try {
               Partner_Order_Acceptance_Document__c poad = [select id,Opportunity__r.AccountId, Opportunity__r.Partner_Involved__r.Name from Partner_Order_Acceptance_Document__c where id=:sourceId];
                L2Q_DocuSignCalloutClass.createEnvelope(name, email, documentId, poad);
                return 'Successfully created';
                
            }
            catch (Exception e) {
                System.DEBUG(LoggingLevel.ERROR, 'AGH Exception caught'+ String.valueOf(e));
                Sawyer.saw(e);
                throw e;
            }
        }

        /*
        @AuraEnabled
        public static void bulkSendEnvelopeMethod(Map<Id, Partner_Passthrough_Detail__c> mapOfDetails) {
            try {
                List<dfsle.Envelope> listOfEnvelops = new List<dfsle.Envelope>();

                for(Partner_Passthrough_Detail__c eachDetails : mapOfDetails.values()) {

                    dfsle.Envelope eachEnvelop = dfsle.EnvelopeService.getEmptyEnvelope(new dfsle.Entity(eachDetails.Partner_Order_Acceptance_Document__c));

                    //eachEnvelop.withEmail('You have a pass through document to sign');
                    final List<dfsle.Document> doc = dfsle.DocumentService.getDocuments
                    (ContentVersion.getSObjectType(), new Set <Id> {
                        Id.valueOf(eachDetails.Content_Version_Id__c)
                    });
                    
                    eachEnvelop = eachEnvelop.withDocuments(doc);
    
                    
                    dfsle.Recipient eachRecepient = dfsle.Recipient.fromSource(
                        eachDetails.Customer_Name__c, // Signer name
                        eachDetails.Customer_Email__c, // Signer email
                        null,
                        'null',
                        null);
    
                    eachEnvelop = eachEnvelop.withRecipients(new List < dfsle.Recipient > {
                        eachRecepient
                    });

                    listOfEnvelops.add(eachEnvelop);
                }
                if(listOfEnvelops.size() > 0) {
                    List<Partner_Passthrough_Detail__c> lst = new List<Partner_Passthrough_Detail__c>();
                    for (dfsle.Envelope eachEnvelope : dfsle.EnvelopeService.sendEnvelopes(listOfEnvelops)) {
                        if (eachEnvelope.error == null) {
                            lst.add(new Partner_Passthrough_Detail__c(Id = mapOfDetails.get(eachEnvelope.source.Id).Id, EnvelopSent__c = true));
                        } else {
                            //sawyer.saw();
                        }
                    }
                    update lst;
                }
                //List<dfsle.Envelope> savedEnvelopes = dfsle.EnvelopeService.saveSentEnvelopes(sentEnvelopes);

            } catch (Exception e) {
                Sawyer.saw(e);
                //System.DEBUG(e);
            }
        }

        @AuraEnabled
        public static Map<String, String> saveEnvelopWrapper(String name, String email, String sourceId, String documentId) {
            Map<String, String> returnVal = new Map<String, String>();
            Partner_Passthrough_Detail__c obj = new Partner_Passthrough_Detail__c();
            obj.Customer_Name__c = name;
            obj.Customer_Email__c = email;
            obj.Content_Version_Id__c = documentId;
            obj.Partner_Order_Acceptance_Document__c  = Id.valueOf(sourceId);
            try {
                insert obj;
                returnVal.put('successMessage', 'We have recorded your action. You will be notified once the document is further processed and sent');
            }
            catch (Exception e) {
                returnVal.put('errorMessage', e.getMessage());
                Sawyer.saw(e);
            }
            return returnVal;
        }


        @AuraEnabled
        public static Map<String, String> sendEnvelopeMethod(String name, String email, String sourceId, String documentId) {
            Map<String, String> returnMap = new Map<String, String>();
            try {
                dfsle.Envelope myEnvelope = dfsle.EnvelopeService.getEmptyEnvelope(new dfsle.Entity(sourceId));
                final List<dfsle.Document> doc = dfsle.DocumentService.getDocuments
                    (ContentVersion.getSObjectType(), new Set <Id> {
                        documentId
                    });
                myEnvelope = myEnvelope.withDocuments(doc);
    
                String SIGNER_NAME = name;
                String SIGNER_EMAIL = email;
    
                dfsle.Recipient myRecipient = dfsle.Recipient.fromSource(
                    SIGNER_NAME, // Signer name
                    SIGNER_EMAIL, // Signer email
                    null, // Signer phone number
                    'null', // Signer role parameter is required
                    null) // No Salesforce association
                    // .withTabs(new List < dfsle.Tab > { // Associate the tabs with this recipient
                    // mySignatureTab
                    //})
                    ;
    
                myEnvelope = myEnvelope.withRecipients(new List < dfsle.Recipient > {
                    myRecipient
                    });
    
                myEnvelope = dfsle.EnvelopeService.sendEnvelope(
                    myEnvelope, // The envelope to send
                    true);

                returnMap.put('envelopId', String.valueOf(myEnvelope.Id));
                returnMap.put('successMessage', 'Successfullly sent Envelop with Id : ' + String.valueOf(myEnvelope.Id));
            }
            catch (Exception e) {
                returnMap.put('errorMessage', String.valueOf(e));
            }
            
            return returnMap;
    }
    */
}