@isTest(SeeAllData = false)
public class SC_SFCommunityNQLBBatchTest {
    
    static void createTestData() {
        User currentusr = [Select id from User where Id = :UserInfo.getUserId()];
        
        Account accRec = new Account(Name='Test Account1',AKAM_Account_ID__c='Test-111-ABC-XYZ',Type='Brand - Active',Parent_Division__c='APJ_');
        insert accRec;  
        
        //Get Network Id
        Id networkId = [Select Id,Name from Network where name = 'Customer Community' Limit 1].Id;
        
        //Create Topic    
        List<Topic> topicList = new List<Topic>();
        for(integer i=0;i<10;i++){
            if(i==0){
                Topic tpic = new Topic();
                tpic.Name = 'Web Performance Test';
                tpic.Description = 'Web Performance';
                tpic.NetworkId = networkId;
                topicList.add(tpic);
            }
            else{
                Topic tpic = new Topic();
                tpic.Name = 'Web Performance'+i;
                tpic.Description = 'Web Performance'+i;
                tpic.NetworkId = networkId;
                //topicList.add(tpic);
            } 
        }
        insert topicList;
        
        
        //Create Feed
        List<FeedItem> fItemList = new List<FeedItem>();
        
        FeedItem post = new FeedItem();
        post.Body = 'HelloThere sfdc://069m0000000BVj1AAG';
        post.ParentId = currentusr.Id;
        post.Title = 'FileName';
        post.Type = 'QuestionPost';
        post.NetworkScope = networkId;
        insert post;
        
        
        //Create TopicAssignment
        
        TopicAssignment tpAssignment = new TopicAssignment();
        tpAssignment.NetworkId = networkId;
        tpAssignment.TopicId = topicList[0].Id;
        tpAssignment.EntityId = post.Id;
        Insert tpAssignment;
        
    } 
    
    static testmethod void NQLBBatchJob()
    {
        // Calling dataSetup Method
        createTestData();
        utilTestClass.createCustomSettings();
        Account accRec1 = new Account(Name='Test AccountCom1',AKAM_Account_ID__c='Test-111-Com1',Type='Brand - Active',Parent_Division__c='APJ_');
        insert accRec1;
        Id recTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        Case newCase = new Case();
        newCase.Subject = 'TestCase';
        newCase.Description = 'TestDescription';
        newCase.RecordTypeId = recTypeId;
        newCase.validation_override__c = true;
        newCase.AccountId = accRec1.Id;
        try{
            insert newCase;
        }
        catch(Exception e){
            system.debug('--Error--'+e.getCause());
            system.debug('--Error--'+e.getLineNumber());
            system.debug('--Error--'+e.getStackTraceString());
        }
        
        list<Id> caseListId = new List<Id>();
        list<String> contentIdList = new List<String>();
        caseListId.add(newCase.Id);
        Map<id,List<String>> contentIdMap = new Map<Id,List<String>>();
        contentIdMap.put(newCase.Id, contentIdList);

        //SC_SFCommunityNQLBController nqlbBatch = new SC_SFCommunityNQLBController();
        
        List<FeedItem> fItemList = [SELECT ID, Title, CreatedDate, CreatedBy.FirstName,CreatedBy.LastName, ParentId, Parent.Name, Body, BestCommentId, 
                                    CommentCount, LikeCount, IsRichText, LinkUrl, NetworkScope, Status, Type, Visibility, HasFeedEntity 
                                    FROM FeedItem
                                    LIMIT 1000];
        
        SC_SFCommunityNQLBBatch nqlbBatch = new SC_SFCommunityNQLBBatch();
        
        Test.startTest(); 
        String s = SC_SFCommunityNQLBController.createAttachments(caseListId,contentIdMap);
        
        SC_SFCommunityNQLBController SFCommunity = new SC_SFCommunityNQLBController();
        String createNQLBCaseStr = SFCommunity.createNQLBCase(fItemList);
        list<Contact> lContacts = SFCommunity.createContacts(fItemList);
        String errorMessage = 'Test error message. Please Ignore.';
        SC_SFCommunityNQLBController.sendEmailforException(errorMessage);
        
        Id batchProcessId = Database.executeBatch(nqlbBatch);
        Test.stopTest();
        
    }
    /*
    static testmethod void NQLBBatchMethod(){
        SFCommunity_NQLB_Topics__mdt communityMetaDataVal = [SELECT CommunityNetworkId__c FROM SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'CommunityNQLB' limit 1];
        Id recTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical').getRecordTypeId();	
        user currentUser = [Select id from user where name = 'CRM Ops' limit 1];
        
        Account accRec = new Account(Name='Test Account IP Addr',AKAM_Account_ID__c='Test-ABC-123IPAddr',Type='Brand - Active');
        insert accRec; 
        FeedItem newFeed = new FeedItem();
        newFeed.Body = 'This is a test body';
        newFeed.NetworkScope = communityMetaDataVal.CommunityNetworkId__c;
        newFeed.ParentId = 	currentUser.Id;
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
        }
        catch(Exception e){
            system.debug('--Error--'+e.getCause());
            system.debug('--Error--'+e.getLineNumber());
            system.debug('--Error--'+e.getStackTraceString());
        }
        
        list<Id> caseListId = new List<Id>();
        list<String> contentIdList = new List<String>();
        caseListId.add(newCase.Id);
        Map<id,List<String>> contentIdMap = new Map<Id,List<String>>();
        contentIdMap.put(newCase.Id, contentIdList);

        //SC_SFCommunityNQLBController nqlbBatch = new SC_SFCommunityNQLBController();
        String s = SC_SFCommunityNQLBController.createAttachments(caseListId,contentIdMap);
        
    }*/
    
}