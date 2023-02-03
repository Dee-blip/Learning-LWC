/*Customer Community Component*/
global class SC_SFCommunityNQLBBatch implements Database.Batchable<sObject>, Database.stateful{
    
    //This will store the Error Message from support class
    Public string errorMessage = '' ;
    
    //Get the record type ID
    Id recTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical').getRecordTypeId();
    
    //This will store the Query for the batch class
    Public string feedItemQuery;
    
    //This will store the Query for the test class 
    Public string feedItemQuery_Test;
    
    
    public SC_SFCommunityNQLBBatch(){
        
        //Get the Topic for which case needs to be created
        
        SFCommunity_NQLB_Topics__mdt communityMetaDataVal = [SELECT TopicName__c, DayRange__c,Activate_NQLB_Batch__c ,CommunityNetworkId__c FROM SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'CommunityNQLB' limit 1];
        if(communityMetaDataVal.Activate_NQLB_Batch__c){
            dateTime settime  = system.now().addDays(-Integer.valueOf((communityMetaDataVal.DayRange__c)));
            String valuesettimefrom = String.valueOfGmt(settime);
            valuesettimefrom = valuesettimefrom.substring(0,10)+'T'+'00:00:00z';
            
            dateTime setEndTime  = system.now().addDays(-Integer.valueOf((1)));
			String valuesetEndtimefrom = String.valueOfGmt(setEndTime);
			valuesetEndtimefrom = valuesetEndtimefrom.substring(0,10)+'T'+'00:00:00z';
            
            string communityNetworkId = communityMetaDataVal.CommunityNetworkId__c;
            
            String allTopics = '';
            for(string eachStr : communityMetaDataVal.TopicName__c.split(',')){
                allTopics += '\''+eachStr+'\''+',';
            }
            allTopics =  allTopics.removeEnd(',');
            
            
            feedItemQuery_Test = 'SELECT ID, Title, CreatedDate, CreatedBy.FirstName,CreatedBy.Email,CreatedBy.LastName, ParentId, Parent.Name, Body, BestCommentId,'+ 
                'CommentCount, LikeCount, HasVerifiedComment, IsRichText, LinkUrl, NetworkScope, Status, Type, Visibility,'+
                'HasFeedEntity FROM FeedItem WHERE TYPE =\'QuestionPost\' AND (NetworkScope = \''+communityNetworkId+'\')' +' AND Id IN (SELECT EntityId FROM TopicAssignment'+
                ' WHERE EntityType = \'FeedItem\' and Topic.Name IN ('+allTopics+')) Limit 10';
            
            
            //'CreatedDate > ' +settimefrom +
            feedItemQuery =  'SELECT ID, Title, CreatedDate, CreatedBy.FirstName, CreatedBy.LastName, CreatedBy.Email, ParentId, Parent.Name, Body, BestCommentId,'+ 
                'CommentCount, LikeCount, HasVerifiedComment, IsRichText, LinkUrl, NetworkScope, Status, Type, Visibility,'+
                'HasFeedEntity FROM FeedItem WHERE TYPE =\'QuestionPost\' AND '+
                'CreatedDate >= '+valuesettimefrom+ ' AND '+ 'CreatedDate <= '+valuesetEndtimefrom+ ' AND '+
                'BestCommentId = Null' + ' AND '+
                '(NetworkScope = \''+communityNetworkId+'\')'+' AND '+
                'Id IN (SELECT EntityId FROM TopicAssignment '+
                'WHERE EntityType = \'FeedItem\' and Topic.Name IN ('+allTopics+'))';
            
        }
    }
    
    //Start Method
    global Database.QueryLocator start(Database.BatchableContext BC){
        
        //Check whether its a test class execution or normal execution
        string batchQuery = (System.Test.isRunningTest()) ? feedItemQuery_Test : feedItemQuery;
        if(batchQuery != null)
            return Database.getQueryLocator(batchQuery);
        else
            return null;
    }
    
    //Execute Method
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        
        //Convert Sobject list to feedItem List
        List<FeedItem> qualifiedFeedQuestionList = (FeedItem[]) scope;
        
        //Call helper class to identify and create NQLB Questions
        if(qualifiedFeedQuestionList.size() > 0){
            SC_SFCommunityNQLBController SFCommunity = new SC_SFCommunityNQLBController();
            errorMessage += SFCommunity.createNQLBCase(qualifiedFeedQuestionList) + '\n';
        }
    }
    
    //Finish Method
    global void finish(Database.BatchableContext BC){
        //if error message is not empty then send email to support email address
        if(errorMessage.length() > 5){
            SC_SFCommunityNQLBController.sendEmailforException(errorMessage);
        } 
        
    }
}