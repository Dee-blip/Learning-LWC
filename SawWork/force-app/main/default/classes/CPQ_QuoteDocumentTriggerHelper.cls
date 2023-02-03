/**
 * Object: SBQQ__QuoteDocument__c
 * Details : Helper class for CPQ quote document object trigger handler.
 * 
 * Developer        Date            Version     Update
 * kimishra         03-MAR-2021     1.0         Initial version CPQ-501 for converting QuoteDocs to Files
 * mausin           17-AUG-2021     2.0         CPQ-830 ( Create Content Version Attribute record to handle download)        
 */
public inherited sharing class CPQ_QuoteDocumentTriggerHelper {

    //CPQ-501 @ kimishra : function to create copy of ContentDocument for every QuoteDocument being inserted
    public static void migrateAttachmentToContentDocument(Map<Id, SObject> newMap) {

        Set<Id> attachmentIds = new Set<Id>();
        //get map of Quote doc and Quote Id, since ParentId in Attachment is of Opportunity
        Map<Id, Id> attachIdQuoteIdMap = new Map<Id, Id>();
        
        List<ContentVersion> listOfContentVersion = new List<ContentVersion>();
        List<ContentVersionAttribute__c> listOfContentVersionAttributes = new List<ContentVersionAttribute__c>();
        // List<Attachment> listOfAttachments = new List<Attachment>();

        if(newMap != null) {

            List<SBQQ__QuoteDocument__c> quoteDocListNew = (List<SBQQ__QuoteDocument__c>) newMap.values();

            for(SBQQ__QuoteDocument__c quoteDoc : quoteDocListNew) {
                attachmentIds.add(quoteDoc.SBQQ__AttachmentId__c);
                attachIdQuoteIdMap.put(quoteDoc.SBQQ__AttachmentId__c, quoteDoc.SBQQ__Quote__c);

            }

            if(attachmentIds != null && attachmentIds.size() > 0) {
                listOfContentVersion = getContentVersionFromAttachIds(attachmentIds, attachIdQuoteIdMap);
            }
            Map<Id,Id> partnerAccount = getpartnerAccount(attachIdQuoteIdMap);

            try {
                if(listOfContentVersion != null && listOfContentVersion.size() > 0 && listOfContentVersion[0].getSObjectType().getDescribe().isCreateable()) {
                    insert listOfContentVersion;
                    
                }
              
                for(ContentVersion cv : listOfContentVersion){

                if(partnerAccount.get(cv.FirstPublishLocationId)!=null)
                { 
                listOfContentVersionAttributes.add(L2Q_ContentDocumentUtilClass.setContentVersionAttribute(cv.Id, 'Partner Account',partnerAccount.get(cv.FirstPublishLocationId) ));
                System.debug(LoggingLevel.INFO, '--listOfContentVersionAttributes: '+listOfContentVersionAttributes);
                } 
                
                }
                if(!listOfContentVersionAttributes.isEmpty())
                {
                    insert listOfContentVersionAttributes;
                }
            
            }
            catch(Exception e) {
                CPQ_LogException newError = new CPQ_LogException('CPQ_QuoteDocumentTriggerHelper: Error in migrateAttachmentToContentDocument method', e).createErrorRecord(true);
                System.debug(LoggingLevel.INFO, '--newError: '+newError);
            }
        }
    }

    private static List<ContentVersion> getContentVersionFromAttachIds(Set<Id> attachmentIds, Map<Id, Id> attachIdQuoteIdMap) {

        List<ContentVersion> contentVersionList = new List<ContentVersion>();

        List<Attachment> newAttachmentList = [SELECT Id, Name, Body, ParentId//, Parent.Type
                                                FROM Attachment 
                                                WHERE Id IN :attachmentIds
                                                WITH SECURITY_ENFORCED];

        String networkName = [SELECT IsPortalEnabled FROM User WHERE Id = :UserInfo.getUserId()].IsPortalEnabled ? 'Partners' : '';
        for(Attachment eachAttachment : newAttachmentList) {
            // listOfAttachments.add(eachAttachment);
            ContentVersion conVer = new CPQ_UtilityClass.ContentVersionBuilder(eachAttachment.Name, eachAttachment.Name, eachAttachment.Body)
                                                    .withContentLocation('S')
                                                    .withNetworkName(networkName)
                                                    .withFirstPublishLocationId(attachIdQuoteIdMap.get(eachAttachment.Id))
                                                    .getRecord();
            System.debug(LoggingLevel.INFO, '--conVer: '+conVer);
            contentVersionList.add(conVer);
        }
        return contentVersionList;
    }

    private static Map<Id,Id> getpartnerAccount(Map<Id, Id> attachIdQuoteIdMap){
        Map<Id,Id> partnerAccountIdMap = new Map<Id,Id>();
        List<SBQQ__Quote__c> quoteList = new List<SBQQ__Quote__c>();
        quoteList =  [SELECT id,Name,CPQ_Partner_Account_SFId__c FROM SBQQ__Quote__c WHERE id IN :attachIdQuoteIdMap.values() ];
        for(SBQQ__Quote__c qc : quoteList){
            if(qc.CPQ_Partner_Account_SFId__c!=null){
                partnerAccountIdMap.put(qc.id,qc.CPQ_Partner_Account_SFId__c);
                
            }
    }
    return partnerAccountIdMap;
    }
}