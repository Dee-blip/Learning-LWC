/******
 * Description : Controller class for the lightning component "Community_Comments"
 * Author : Vikas R
 * Test Class : CommunityBlogCommentCtrlTest
 * @History
    --Developer       --Date          --Change
    Vikas             23-May-2018      ESESP-1318:Edit permission for comment is given using UserRecordAccess object
******/
public class CommunityBlogCommentCtrl {
	@AuraEnabled
    public static String addBlogComment(Community_Blog_Comment__c blogCommentrecord, String blogId, String urlName){
        try{
            String descLength = String.valueOf(blogCommentrecord.Comment__c.length()); 
            if(blogCommentrecord.Comment__c.length() >= 131072){
                //throw new CommunityException('Blog Description exceeded maximum character limit. Please reduce the size and save.');
                return 'SIZEERROR'+descLength;
            }
            else{
                String searchquery='FIND \''+urlName+'\' IN ALL FIELDS RETURNING Knowledge__kav(KnowledgeArticleId)'; 
                String query;
                List<List<SObject>>searchList=search.query(searchquery);
                for(List<SObject> objList : searchList)
                {
                    for(SObject obj: objList)
                    {
                        query = 'SELECT KnowledgeArticleId,OwnerId,ArticleNumber,Title,VersionNumber FROM '+obj.getSObjectType();
                        if(blogId != null)
                            query+=' where id in (\''+blogId+'\')';
                    }
                }
                List <sObject> blogList = Database.query(query);
                if(blogList.size() > 0)
                {
                    if(blogCommentrecord != null){
                        blogCommentrecord.Community_Blog_Id__c = (String)blogList[0].get('KnowledgeArticleId');
                        blogCommentrecord.Article_Created_By__c = (Id)blogList[0].get('OwnerId');
                        blogCommentrecord.Article_ID__c = (String)blogList[0].get('ArticleNumber');
                        blogCommentrecord.Article_SF_Id__c = (String)blogList[0].get('KnowledgeArticleId');
                        blogCommentrecord.Article_Title__c = (String)blogList[0].get('Title');
                        blogCommentrecord.Article_Version__c = (Integer)blogList[0].get('VersionNumber');
                        upsert blogCommentrecord;
                    }
                }
                return null;
            }
        } 
        catch (Exception ex){
            system.debug('******AN EXCEPTION : '+ex.getMessage()+' OCCURED AT : '+ex.getLineNumber()+' of class CommunityBlogCommentCtrl ******');
       		return null;
        }
    }
    @AuraEnabled
    public static List<SC_CommunityWrapper> fetchBlogComments(String blogId,String urlName){
        SC_CommunityWrapper commentWrapper;
        List<Community_Blog_Comment__c> blogCommentList = new List<Community_Blog_Comment__c>();
        List<SC_CommunityWrapper> commentWrapList = new List<SC_CommunityWrapper>();
        List<Id> commentIdList = new List<Id>();
        Map<Id,Boolean> commentEditMap = new Map<Id,Boolean>();
        Map<Id,Boolean> commentDelMap = new Map<Id,Boolean>();
        try
        {
            String searchquery='FIND \''+urlName+'\' IN ALL FIELDS RETURNING Knowledge__kav(KnowledgeArticleId)'; 
            String query;
            List<List<SObject>>searchList=search.query(searchquery);
            for(List<SObject> objList : searchList)
            {
                for(SObject obj: objList)
                {
                    query = 'SELECT KnowledgeArticleId FROM '+obj.getSObjectType();
                    if(blogId != null)
                        query+=' where id in (\''+blogId+'\')';
                }
            }
            if(!String.isEmpty(query))
            {
                List <sObject> objList = Database.query(query);
                if(objList.size() > 0)
                {
                    Id kbId = (Id)objList[0].get('KnowledgeArticleId');
                    blogCommentList = [select id, Name, Comment__c, Edit_Blog__c, CreatedBy.Name, CreatedBy.Id, CreatedDate from Community_Blog_Comment__c 
                                       where Community_Blog_Id__c =: String.valueOf(kbId) order by CreatedDate];
                    for(Community_Blog_Comment__c blogComment : blogCommentList)
                    {
                        if(!String.isEmpty(blogComment.Comment__c))
                        {
                            commentIdList.add(blogComment.Id);
                        }
                    }
                    list<UserRecordAccess> uRaList= [Select RecordId, HasEditAccess, HasDeleteAccess, HasAllAccess From UserRecordAccess Where UserId =:UserInfo.getUserId() AND RecordId IN:(commentIdList)];
                    for(UserRecordAccess uRa : uRaList){
                        commentEditMap.put(uRa.RecordId,uRa.HasAllAccess);
                        commentDelMap.put(uRa.RecordId,uRa.HasAllAccess);
                    }
                    
                    for(Community_Blog_Comment__c blogComment : blogCommentList)
                    {
                        if(!String.isEmpty(blogComment.Comment__c))
                        {
                            commentWrapper = new SC_CommunityWrapper();
                            //blogComment.Comment__c = blogComment.Comment__c.replaceAll('<[^>]+>',' ');
                            //blogComment.Comment__c = blogComment.Comment__c.unescapeHtml4();
                            commentWrapper.comment = blogComment;
                            commentWrapper.hasEdit = commentEditMap.get(blogComment.Id);
                            commentWrapper.hasDel = commentDelMap.get(blogComment.Id);
                            commentWrapList.add(commentWrapper);
                        }
                    }
                }
            }
        } 
        catch (Exception ex){
            system.debug('******AN EXCEPTION : '+ex.getMessage()+' OCCURED AT : '+ex.getLineNumber()+' of class CommunityBlogCommentCtrl ******');
        }
        return commentWrapList;
    }
    @AuraEnabled
    public static Boolean checkAccess(){
        Profile p = [select name from Profile where id =:UserInfo.getProfileId()];
		List<SC_CommunityUtility__mdt> communityUtilList = [select Value__c, MasterLabel from SC_CommunityUtility__mdt];
        Map<String,String> communityUtilMap = new Map<String,String>();
        for(SC_CommunityUtility__mdt commUtil: communityUtilList)
        {
            communityUtilMap.put(commUtil.MasterLabel, commUtil.Value__c);
        }
		if(p.name != communityUtilMap.get('CommuntiyGuestProfile'))
            return true;
        else
            return false;
    }
    @AuraEnabled
    public static Community_Blog_Comment__c fetchBlogComment(String commentId){
        return [select id,Name,Comment__c,Community_Blog_Id__c from Community_Blog_Comment__c where id=:id.valueOf(commentId) limit 1];
    }
    @AuraEnabled
    public static void deleteBlogComment(String commentId){
        delete[Select id from Community_Blog_Comment__c where id=:id.valueOf(commentId)];
    }
}