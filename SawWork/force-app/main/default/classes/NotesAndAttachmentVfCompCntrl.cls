public with sharing class NotesAndAttachmentVfCompCntrl {
    public Id parentId {get;set;}
    public list<ContentDocumentLink> fileList;
    public transient Blob attchBody {get;set;}
    public String attchName {get;set;}
    
    public NotesAndAttachmentVfCompCntrl(){
    }
    
    public list<ContentDocumentLink> getFileList(){
        return [Select Id, ContentDocument.LatestPublishedVersionId, ContentDocument.Title, ContentDocument.ContentModifiedDate, ContentDocument.LatestPublishedVersion.ContentModifiedById, ContentDocument.LatestPublishedVersion.ContentModifiedBy.Name from ContentDocumentLink Where LinkedEntityId =: parentId];
    }
    
    public void onFileChange(){
        ContentVersion contentVersion = L2Q_ContentDocumentUtilClass.setContentVersion('S',attchName,attchName,attchBody);
        insert contentVersion;
        ContentVersion cV = [select Id, ContentDocumentId from ContentVersion where Id =: contentVersion.Id];
        ContentDocumentLink contentDocumentLink = L2Q_ContentDocumentUtilClass.setContentDocumentLink(cV.ContentDocumentId,parentId,'I','AllUsers');
        insert contentDocumentLink;
    }

    //SFDC-6363
    @AuraEnabled
    public static List<ContentDocumentLink> getTheAttachedFileList(String recordId) {
        List<ContentDocumentLink> listOfContentDocumentLinks = new List<ContentDocumentLink>();
        if(recordId != null && recordId != '') {
            try {
                listOfContentDocumentLinks = [SELECT Id, ContentDocumentId, ContentDocument.LatestPublishedVersionId, ContentDocument.LatestPublishedVersion.Title, ContentDocument.LatestPublishedVersion.ContentModifiedBy.Name, ContentDocument.ContentModifiedDate FROM ContentDocumentLink WHERE LinkedEntityId = :recordId];
            } catch(Exception e) {
                String errorMessage = 'Error : ' + e.getMessage() + '\n' + 'Stack trace : ' + e.getStackTraceString();
	            Error_Log__c el = new Error_Log__c(Name = 'getTheAttachedFileList', Class__c = 'NotesAndAttachmentVfCompCntrl', Error_Message__c = errorMessage);
                insert el;
            }
        }
        return listOfContentDocumentLinks;
    }

    @AuraEnabled
    public static Boolean getShowComponentOnLayout(String recordId) {
        try {
            String currentObject = String.valueOf(Id.valueOf(recordId).getSObjectType());
            String L2Q_ObjectsForPartnerAttributesBatchJSON = GSMSettings.getVerbose('L2Q_ObjectsForPartnerAttributesBatchJSON');
            List<L2Q_ContentDocumentLinkTriggerHandler.ObjectCustom> listOfObjects = (List<L2Q_ContentDocumentLinkTriggerHandler.ObjectCustom>)JSON.deserialize(L2Q_ObjectsForPartnerAttributesBatchJSON, List<L2Q_ContentDocumentLinkTriggerHandler.ObjectCustom>.Class);
            for(L2Q_ContentDocumentLinkTriggerHandler.ObjectCustom eachObject : listOfObjects) {
                if(eachObject.ObjectName == currentObject) {
                    return true;
                }
            }
        }
        catch(Exception e) {
            String errorMessage = 'Error : ' + e.getMessage() + '\n' + 'Stack trace : ' + e.getStackTraceString();
	        Error_Log__c el = new Error_Log__c(Name = 'getShowComponentOnLayout', Class__c = 'NotesAndAttachmentVfCompCntrl', Error_Message__c = errorMessage);
            insert el;
        }
        return false;
    }
}