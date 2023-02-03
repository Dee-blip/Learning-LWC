/**
*  SF1_NotificationSenderUtil
*
 --Developer         --Date          --Description
   Sausharm           25/07/2017       Initial version for Sending Feeds to recipients
**/
public with sharing class SF1_NotificationSenderUtil
 {
     public static boolean firstRun = true;
     
     public static void postFeedWithLink(Id recepientId, String msg, Id subjectId)
     {
        if(isFeedEnabled(recepientId))
        {

         ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();      
         ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
         ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();
         
         messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
        
         //Add  Recepient
         ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();
         mentionSegmentInput.id = recepientId;
         messageBodyInput.messageSegments.add(mentionSegmentInput);
  
         
         textSegmentInput.text = msg;
         messageBodyInput.messageSegments.add(textSegmentInput);
         
         feedItemInput.body = messageBodyInput;
         feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
         feedItemInput.subjectId = subjectId;

         // Add link
         ConnectApi.LinkCapabilityInput linkIn = new ConnectApi.LinkCapabilityInput();
         linkIn.urlName = 'Respond here';              
         linkIn.url = URL.getSalesforceBaseUrl().toExternalForm()+'/apex/SF1_Page_TaskNotificationIntermediate?taskId='+subjectId;
         ConnectApi.FeedElementCapabilitiesInput feedElementCapabilitiesInput = new ConnectApi.FeedElementCapabilitiesInput();
         feedElementCapabilitiesInput.link = linkIn;              
         feedItemInput.capabilities = feedElementCapabilitiesInput;

         // Post feed only for non Test scenarios
         if(!Test.isRunningTest())
         {
            ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), feedItemInput);
         }
        }
     }

     @future
     public static void sendNotification(List<Id> recepients, String msg, Id subjectId)
     {
        recepients = filterUserIdWithFeedEnabled(recepients);
        if( recepients.size() > 0)
        {

         ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();      
         ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
         ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();
         
         messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
         
        for(Id recepientId:recepients)
        {
            ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();
            mentionSegmentInput.id = recepientId;
            messageBodyInput.messageSegments.add(mentionSegmentInput);
        }
         
         textSegmentInput.text = msg;
         messageBodyInput.messageSegments.add(textSegmentInput);
         
         feedItemInput.body = messageBodyInput;
         feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
         feedItemInput.subjectId = subjectId;
         
         // Post feed only for non Test scenarios
         if(!Test.isRunningTest())
         {
            ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), feedItemInput);
         }
      }
     }


     public static void sendChatterFeedOnTaskCommentChange(List<Task> newTaskList, Map<Id,Task> oldTaskMap, Boolean isInsert)
     {

        if(firstRun)
        {
            List<Task> taskList = new List<Task>();
            Map<Id, Id> taskIDToOAIdMap = new Map<Id, Id>();
            Map<Id, Order_Approval__c> oaIdToOAMap = new Map<Id, Order_Approval__c>();
            Map<Id, Order_Approval__c> taskIdToOAMap = new Map<Id, Order_Approval__c>();

            for(Task t : newTaskList)
            {
                Boolean isNewTaskWithComments = isInsert && t.Description != null;
                Boolean isExistingTaskWithChangeInComments = !isInsert && (t.Description != oldTaskMap.get(t.Id).Description);

                if( (isNewTaskWithComments || isExistingTaskWithChangeInComments) &&
                     t.WhatId != null &&
                     String.valueof(t.WhatId.getSObjectType()) == 'Order_Approval__c'
                  )
                // Additional Checks for Task Types
                // Or custom setting for SF1 Enabled users
                {
                    taskList.add(t);
                    taskIDToOAIdMap.put(t.Id, t.whatId);
                }
            }

            if(taskIDToOAIdMap.values().size() > 0)
            {
                for( Order_Approval__c oa : [Select Id,Name,Associated_Opportunity__r.OwnerId, Associated_Opportunity__r.Name  from Order_Approval__c where id in: taskIDToOAIdMap.values()])
                {
                    oaIdToOAMap.put(oa.Id,oa);
                }
            }

            for(Id key : taskIDToOAIdMap.keySet())
            {
                if(taskIDToOAIdMap.get(key) != null && oaIdToOAMap.get(taskIDToOAIdMap.get(key)) != null)
                {
                    taskIdToOAMap.put(key,oaIdToOAMap.get(taskIDToOAIdMap.get(key)));
                }
            }

            for( Task t : taskList)
            {
                if(taskIdToOAMap.get(t.id) != null)
                {
                    Id oppOwnerId = taskIdToOAMap.get(t.id).Associated_Opportunity__r.OwnerId;
                    Id taskOwnerId = t.OwnerId;
                    
                    String oppName = taskIdToOAMap.get(t.id).Associated_Opportunity__r.Name;
                    String message =  ' New comment added to the '+t.Task_Type__c+' Task on the Opportunity \''+oppName+'\'';
                    Id loggedInUserID = Userinfo.getuserid();

                    // Send feed notification to others, not Self
                    if(loggedInUserID != oppOwnerId)
                    {
                        postFeedWithLink(oppOwnerId, message, t.Id);
                    }
                    if(loggedInUserID != taskOwnerId && oppOwnerId !=  taskOwnerId)
                    {
                        postFeedWithLink(taskOwnerId, message, t.Id);
                    }
                    
                }
            }
            firstRun = false;
        }

     } 
     private static boolean isFeedEnabled(Id userId)
     {
        User u = [Select id, SF1_Receive_OATask_ChatterFeed__c from User where id =: userId];
        return u.SF1_Receive_OATask_ChatterFeed__c;

     }
     private static list<Id> filterUserIdWithFeedEnabled(list<Id> userIdList)
     {
        List<id> uIdListNew = new list<Id>();
        for( User u : [Select id, SF1_Receive_OATask_ChatterFeed__c from User where id in : userIdList])
        {
            if(u.SF1_Receive_OATask_ChatterFeed__c)
            {
                uIdListNew.add(u.Id);
            }
        }
        return uIdListNew;

     }
}