public without sharing class SF1_DeleteFiles {

    @AuraEnabled
    public static List<ContentDocument> getContentDocumentRecords(Id orderApprovalId)
   {
       System.debug('orderApprovalId:'+orderApprovalId);
       List<Id> cdIdList = new List<Id>();
       List<ContentDocument> ContentDocumentList = new List<ContentDocument>();
       for(ContentDocumentlink cdl : [select id, ContentDocumentId, LinkedEntityId, sharetype from ContentDocumentlink where LinkedEntityId = :orderApprovalId limit 50000]){
           cdIdList.add(cdl.ContentDocumentId);
       }
       if(!cdIdList.isEmpty()){
           ContentDocumentList = [Select id, title, Owner.Name, createddate, LastModifiedDate from ContentDocument where Id IN :cdIdList and owner.Alias = 'MUSER'];
       }
       System.debug('ContentDocumentList:'+ContentDocumentList);
       return ContentDocumentList;
   }
    
   @AuraEnabled
    public static string deleteContentFiles(String contentDocumentLists){
        System.debug('Inside deleteFiles method');
        Type idArrType = Type.forName('List<ContentDocument>');
        List<ContentDocument> cdlList = (List<ContentDocument>) JSON.deserialize(contentDocumentLists, idArrType);
        System.debug('cdlList:'+cdlList);
        if(cdlList.size()>0){
            try{
                delete cdlList;
                //Database.delete(cdlList, false);
                //GsmUtilClass.doDatabaseDelete(cdlList, 'SF1_DeleteFiles', 'deleteContentFiles');
            }
            catch(Exception Ex){
                Error_Log__c el = new Error_Log__c(Name='deleteContentFiles', Class__c='SF1_DeleteFiles', Error_Message__c=Ex.getMessage());
                insert el;
                return Ex.getMessage();
            }
        }
        return 'Success';
    }
    @AuraEnabled
    public static string getDataTableHeader(){
        String header = GSMSettings.getVerbose('DataTable_Header_Delete_Files_Func');
        System.debug('Header:'+JSON.serialize(header));
        return header;
    }
}