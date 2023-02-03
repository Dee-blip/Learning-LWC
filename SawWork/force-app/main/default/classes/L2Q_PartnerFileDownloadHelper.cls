public class L2Q_PartnerFileDownloadHelper {
    public L2Q_PartnerFileDownloadHelper () {
        String contentDocId = ApexPages.currentPage().getParameters().get('contentDocumentId');
        useContentDoc = false;
        if(Id.ValueOf(contentDocId).getSObjectType() == ContentDocument.SObjectType) {
            useContentDoc = true;
            ContentDownloadBlocker.OverrideFlag = true;
            conVerData = [SELECT Id, ContentDocumentId, VersionData, Title, FileType FROM ContentVersion WHERE ContentDocumentId = :contentDocId];
            
            String L2Q_ObjectsUsingAttachment = GSMSettings.getVerbose('L2Q_FileTypeToContentTypeMapping');
            Map<String, String> mapOfFileTypeToContentType = new Map<String, String>();
            ContentDownloadBlocker.OverrideFlag = true;
            if(L2Q_ObjectsUsingAttachment != null) {
                for(String eachMapping : L2Q_ObjectsUsingAttachment.split(',')) {
                    List<String> brokenMapping = eachMapping.split(':');
                    mapOfFileTypeToContentType.put(brokenMapping.get(0), brokenMapping.get(1));
                }
            }
            contentType = mapOfFileTypeToContentType.get(conVerData.FileType);
        } else {
            attData = [SELECT Id, Body, Name, ContentType FROM Attachment WHERE Id = :contentDocId];
            contentType = attData.ContentType;
        }
        
    }
    public Boolean useContentDoc {get; set;}
    public ContentVersion conVerData {get;set;}
    public Attachment attData {get;set;}
    public String contentType {get; set;}
    
    public String image {
        get {
            if(useContentDoc) {
                return EncodingUtil.Base64Encode(conVerData.VersionData);
            }
            return EncodingUtil.Base64Encode(attData.Body);
        }
    }
}