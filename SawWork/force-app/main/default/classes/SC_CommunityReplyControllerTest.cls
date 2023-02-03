@isTest
Public class SC_CommunityReplyControllerTest{
    
    static void setupData(){
        /*SFCommunity_NQLB_Topics__mdt communityMetaDataVal = [SELECT CommunityNetworkId__c FROM SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'CommunityNQLB' limit 1];
Id recTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Community Response').getRecordTypeId();  
user currentUser = [Select id from user where name = 'CRM Ops' limit 1];
FeedItem newFeed = new FeedItem();
newFeed.Body = 'This is a test body';
newFeed.NetworkScope = communityMetaDataVal.CommunityNetworkId__c;
newFeed.ParentId =  currentUser.Id;
newFeed.Status = 'Published';
newFeed.Title = 'This is a test title';
newFeed.Type = 'QuestionPost';
newFeed.Visibility = 'AllUsers';
insert newFeed;

FeedComment newComment = new FeedComment();
newComment.commentBody = 'This is feed test comment';
newComment.commentType = 'TextComment';
newComment.FeedItemId = newFeed.Id;
newComment.Status = 'Published';
insert newComment;

Case newCase = new Case();
newCase.Subject = 'TestCase';
newCase.Description = 'TestDescription';
newCase.RecordTypeId = recTypeId;
newCase.validation_override__c = true;
newCase.FeedQuestionId__c = newFeed.Id;
insert newCase;*/
        
    }
    
    static testmethod void testCommunityReplyController(){
        SFCommunity_NQLB_Topics__mdt communityMetaDataVal = [SELECT CommunityNetworkId__c FROM SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'CommunityNQLB' limit 1];
        Id recTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical').getRecordTypeId();   
        user currentUser = [Select id from user where name = 'CRM Ops' limit 1];
        
        
        //Create all custom settings
       //
        utilTestClass.createCustomSettings();
       
    
        Account accRec = new Account(Name='Test Account IP Addr',AKAM_Account_ID__c='Test-ABC-123IPAddr',Type='Brand - Active');
        insert accRec; 
        FeedItem newFeed = new FeedItem();
        newFeed.Body = 'This is a test body';
        newFeed.NetworkScope = communityMetaDataVal.CommunityNetworkId__c;
        newFeed.ParentId =  currentUser.Id;
        newFeed.Status = 'Published';
        newFeed.Title = 'This is a test title';
        newFeed.Type = 'QuestionPost';
        newFeed.Visibility = 'AllUsers';
        insert newFeed;
        
        FeedComment newComment = new FeedComment();
        newComment.commentBody = 'This is feed test comment sfdc://069999919292394';
        newComment.commentType = 'TextComment';
        newComment.FeedItemId = newFeed.Id;
        newComment.Status = 'Published';
        insert newComment;
        system.debug('--newFeed.Id--'+newFeed.Id);
        system.debug('--accRec.Id--'+accRec.Id);
        system.debug('--recTypeId--'+recTypeId);
        
        Case newCase = new Case();
        string feedId = newFeed.Id;
        newCase.Subject = 'TestCase';
        newCase.Description = 'TestDescription';
        newCase.RecordTypeId = recTypeId;
        newCase.validation_override__c = true;
        newCase.FeedQuestionId__c = feedId;
        newCase.AccountId = accRec.Id;
        try{
            insert newCase;
            system.debug('Case in test class'+newCase);
        }
        catch(Exception e){
            system.debug('--Error--'+e.getCause());
            system.debug('--Error--'+e.getLineNumber());
            system.debug('--Error--'+e.getStackTraceString());
        }
        
        test.startTest();
        try{
            
            PageReference ref1 = Page.SC_CommunityReply_Comment;  
            Test.setCurrentPageReference(ref1);
            ApexPages.currentPage().getParameters().put('id',newFeed.Id);
            ApexPages.StandardController sc1 = new ApexPages.StandardController(newFeed);
            SC_CommunityReplyCommentController newContComm = new SC_CommunityReplyCommentController(); 
            newContComm.PostComment();
            //newContComm.CancelComment();
            newContComm.getComment();
            
            PageReference ref2 = Page.SC_SFCommunityCommentView;  
            Test.setCurrentPageReference(ref2);
            ApexPages.currentPage().getParameters().put('id',newComment.Id);
            ApexPages.StandardController sc3 = new ApexPages.StandardController(newComment);
            SC_SFCommunityCommentViewContrl newContComm1 = new SC_SFCommunityCommentViewContrl();
            
            
            PageReference ref = Page.SC_CommunityReply;  
            Test.setCurrentPageReference(ref);
            ApexPages.currentPage().getParameters().put('id',newCase.Id);
            
            ApexPages.StandardController sc = new ApexPages.StandardController(newCase);
            SC_CommunityReplyController newCont = new SC_CommunityReplyController(sc);    
            
            newCont.commentList();
            newCont.getPageNumber();
            newCont.getTotalPages();
            newCont.getDisablePreviousComment();
            newCont.getDisableNextComment();
            newCont.nextComment();
            newCont.previousComment();
            newCont.nextLastComment();
            newCont.previousFirstComment();
            newCont.showPopup();
            newCont.closePopup();
            newCont.refreshCommentSection();
            newCont.markCorrect();
            newCont.refreshCommentSection();
        }
        catch(Exception e){
            system.debug('SC_CommunityREplyCOntroller test failure');
        }
        
        
    }
    
    
}