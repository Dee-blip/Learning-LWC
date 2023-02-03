/*Customer Community Component*/
public class SC_CommunityReplyController {
    
    // Method-6 : For displaying Contract details on Case PageLayout
    public List<FeedComment> allFeedReplyToDisplay;
    
    public List<FeedComment> feedCommentWithoutHTML {get;set;}
    
    public boolean displayPopup {get; set;}
    
    public Id getFeedQuestionId {get;set;} // FeedItem Id/QuestionId
    
    Private Integer listSize = 5; //listSize determines the number of records to display.
    
    Private Integer commentCounter = 0; // Determines how many records to be skipped
    
    Private Integer commentTotalSize = 0; // Stores the total number of records in the org
    
    public id bestCommentId {get;set;} // Best CommentId
    
    Private Integer totalPages {get;set;} // total Pages Number
    
    public string noCommentMsg{get;set;}
    
    public string commentId{get;set;}
    
    public string commentPageURL{get;set;}
    
    public string questionURL{get;set;}
    
    public string caseId{get;set;}
    
    
    //Standard Controller
    public SC_CommunityReplyController(ApexPages.StandardController Controller){
        //Id caseId = (Id) Controller.getRecord().get('id');
        // Getting FeedQuestionId__c from Case Page
        Case c = [select Id,Has_Best_Answer__c,FeedQuestionId__c,Question_URL__c,caseNumber from case where Id = :ApexPages.currentPage().getParameters().get('id') limit 1];//ApexPages.currentPage().getParameters().get('id')
        // Case c = (Case) Controller.getRecord();
        
        getFeedQuestionId = c.FeedQuestionId__c;
        caseId = c.Id;
        //Network myNetwork = [SELECT Id FROM Network WHERE Name ='Customer Test Community'];
        questionURL = c.Question_URL__c;
        list<FeedItem> isCommentOnFeedItem = new List<FeedItem>([select id,BestCommentId from FeedItem where id =:getFeedQuestionId limit 1]);
        bestCommentId  = isCommentOnFeedItem.size()>0 ? isCommentOnFeedItem[0].BestCommentId : null; 
        commentTotalSize = [Select count() from FeedComment where FeedItemId = :getFeedQuestionId];
        noCommentMsg = '';
        if(commentTotalSize > 0)
            commentList();
        else
            noCommentMsg = Label.JV_No_Comments_On_Question;
    }
    
    //methhod to get comments using offset
    public PageReference commentList(){
        
        allFeedReplyToDisplay = new List<FeedComment>();
        
        feedCommentWithoutHTML = new List<FeedComment>();
        
        if(allFeedReplyToDisplay !=null){
            allFeedReplyToDisplay.clear();
        }
        
        if(commentTotalSize != 0){
            commentTotalSize = [Select count() from FeedComment where FeedItemId = :getFeedQuestionId];
        }
        
        allFeedReplyToDisplay = [Select id,CommentBody,CommentType,Createddate,CreatedBy.Name, FeedItemId, InsertedById,LastEditDate from FeedComment where FeedItemId = :getFeedQuestionId order by LastEditDate desc limit :listSize offset :commentCounter];
        
        for(feedComment eachComment : allFeedReplyToDisplay){
            eachComment.CommentBody = eachComment.CommentBody.replaceAll('\\<.*?\\>', '');
            eachComment.CommentBody = eachComment.CommentBody.unescapeHtml4();
            eachComment.CommentBody = eachComment.CommentBody.length() > 25 ? eachComment.CommentBody.substring(0,25) : eachComment.CommentBody;
            feedCommentWithoutHTML.add(eachComment);
        }
        
        return null;
    }   
    
    
    public Integer getPageNumber() {
        
        integer x = CommentCounter/listSize +1 ;
        
        return x;
    }
    
    public Integer getTotalPages() 
    {
        if (math.mod(CommentTotalSize, listSize) > 0) 
        {
            return CommentTotalSize/listSize + 1;
            
        } 
        else 
        {
            return (CommentTotalSize/listSize);
        }
    }
    
    //Diables the previous buttons if there is no record previous than current list
    public Boolean getDisablePreviousComment(){
        if(CommentCounter == 0)
            return true;
        else
            return false;
    }
    
    //Diables the next buttons if there is no record next to current list
    public Boolean getDisableNextComment(){        
        if((CommentTotalSize <= listSize) || ((CommentCounter +  listSize) >= CommentTotalSize))
            return true;
        else
            return false;
    }
    
    //Displays the next set of records
    public void nextComment(){        
        CommentCounter = CommentCounter + listSize;
        commentList();
    }
    
    //Displays the previous set of records
    public void previousComment(){
        commentCounter = commentCounter - listSize;
        commentList();
    }
    
    //Displays the last set of records irrespective of current position
    public void nextLastComment(){
        if(math.mod(commentTotalSize, listSize) == 0)
            commentCounter =  commentTotalSize - listSize;
        else
            commentCounter = commentTotalSize - math.mod(commentTotalSize, listSize);
        commentList();
    }
    
    //Displays the first set of records irrespective of current position
    public void previousFirstComment(){
        commentCounter = 0;
        commentList();
    } 
    public void showPopup() {
        displayPopup = true;
        commentPageURL = '/apex/SC_CommunityReply_Comment?id='+commentId;
    }
    public void closePopup() {
        
        displayPopup = false;
        
    }
    
    public pageReference markCorrect(){
        SFCommunity_NQLB_Topics__mdt  communityMetaDataVal = [SELECT CommunityNetworkId__c FROM SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'CommunityNQLB' limit 1];
        String bestAnswerBody = '{"bestAnswerId": "'+bestCommentId+'"}';
        String communityBaseURL = Network.getLoginUrl(communityMetaDataVal.CommunityNetworkId__c).substring(0,Network.getLoginUrl(communityMetaDataVal.CommunityNetworkId__c).indexOf('.com'));
        String endPointURL = communityBaseURL+'.com/services/data/v41.0/connect/communities/'+communityMetaDataVal.CommunityNetworkId__c+'/chatter/feed-elements/'+getFeedQuestionId+'/capabilities/question-and-answers?_HttpMethod=PATCH';
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endPointURL);
        req.setMethod('POST');
        req.setHeader('Authorization', 'Bearer ' + UserInfo.getSessionId());
        req.setHeader('Content-Type','application/json');
        req.setBody(bestAnswerBody);
        Http http = new Http();
        HTTPResponse res = http.send(req);
        if(res.getStatusCode() != 200){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,res.getStatusCode() +'::'+res.getStatus()));
            return null;
        }
        else{
        	Case c = [select Id,Has_Best_Answer__c,FeedQuestionId__c,Question_URL__c,caseNumber from case where id =:caseId];
        	case newCase = new Case();
        	newCase.Has_Best_Answer__c = true;
        	newCase.Id = c.Id;
        	Update newCase;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,Label.JV_Best_Comment_Posted));
            return refreshCommentSection();
        }
        
    }
    
    public pageReference refreshCommentSection(){
        pageReference pr = new pageReference('/apex/SC_CommunityReply?id='+caseId);
        pr.setRedirect(true);
        return pr;
    }   
}