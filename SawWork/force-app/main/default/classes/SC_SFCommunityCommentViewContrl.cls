/*Customer Community Component*/
public class SC_SFCommunityCommentViewContrl {
    
    public string commentBody{get;set;}
    public string commentBodyFinal{get;set;}
    public id commentId;
    
    public SC_SFCommunityCommentViewContrl(){
        commentId = ApexPages.currentPage().getParameters().get('id');
        feedComment comment = [SELECT id,feedItemId,commentBody from feedComment where id = :ApexPages.currentPage().getParameters().get('id') limit 1];
        commentBody = comment.commentBody;
        commentBodyFinal = commentBody;
        integer totalImageTag = commentBody.countMatches('sfdc://069');
        list<String> idList = new List<String>();
        for(integer i= 0;i<totalImageTag;i++){
            integer count1 = commentBody.indexOf('sfdc://');
            string imageId1 = commentBody.subString(count1,count1+22);
            string imageId2 = imageId1.replaceFirst('sfdc://','');
            commentBody = commentBody.replaceFirst('sfdc://','');
            idList.add(imageId2);
            
        }
        if(idList.size()>0){
            Map<Id,Id> contentDocVerisonMap =  new Map<Id,Id>();  
            for(contentVersion cv :[SELECT Id, ContentDocumentId from contentVersion where ContentDocumentId IN :idList]){
                contentDocVerisonMap.put(cv.ContentDocumentId,String.valueOf(cv.Id).substring(0,15));
            }
            for(id eachKey:contentDocVerisonMap.keyset()){
                id versionID = contentDocVerisonMap.get(eachKey);
                commentBodyFinal = commentBodyFinal.replace(eachKey,versionID);
            }
            commentBodyFinal = commentBodyFinal.replaceAll('sfdc://','/sfc/servlet.shepherd/version/download/');
            
        }
    }
    
}