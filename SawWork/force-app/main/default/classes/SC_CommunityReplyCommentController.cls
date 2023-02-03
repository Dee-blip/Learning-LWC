/*Customer Community Component*/
public class SC_CommunityReplyCommentController {
    
    public string bodyContent{get;set;}
    public static id feedItemId;
    public boolean showMessage{get;set;}
    public string communityQuestion{get;set;}
    
    public SC_CommunityReplyCommentController(){
        String commentBody = '';
        feedItemId = ApexPages.currentPage().getParameters().get('id');
        if(feedItemId != Null){
           communityQuestion = [select id,body,title from feedItem where id =:feedItemId limit 1].title;
           showMessage = false;
        }
        else{
        showMessage = true;
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, Label.JV_Feed_Doesnt_Exist));
        }
        
        
    }
    
    public PageReference PostComment(){
        
        FeedComment eachComment = new FeedComment();
        eachComment.CommentBody = bodyContent;
        eachComment.CommentType = 'TextComment';
        eachComment.FeedItemId = ApexPages.currentPage().getParameters().get('id');
        eachComment.CreatedDate = system.now();
        eachComment.IsRichText = true;
        eachComment.Status = 'Published';
        showMessage = true;
        try{
        	If(eachComment.FeedItemId != Null){
        		insert eachComment;
            	ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM, Label.JV_Comment_Posted));
            }
            else
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,Label.JV_Feed_Doesnt_Exist));
        }
        catch(Exception e){
           ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Error:'+e));
        }
       
        return null;
        
    }
    
    public static void CancelComment(){
        
    }
    
    public pageReference getComment(){
        return null;
    }
}