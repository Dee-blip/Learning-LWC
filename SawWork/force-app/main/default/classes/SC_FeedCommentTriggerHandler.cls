/*******************************************************************************************************
Name         :   SC_FeedCommentTriggerHandler
Author       :   jrathod
Created Date :   Dec 23,2021
JIRA         :   ESESP-4062
Description  :  FeedComment trigger handler
********************************************************************************************************
Jay               23-Dec-2021       ESESP-4062    Implemented validateTaggedUsers method
Vandhana          20-May-2022       ESESP-6457    SC IP Scrubbing, bypass validateTaggedUsers for CRM Ops
*/

public with sharing class SC_FeedCommentTriggerHandler extends SC_TriggerHandlerAbstract
{
    
    
    public override void handleAfterInsert() 
    {
        validateTaggedUsers((Map<Id, FeedComment>) Trigger.newMap);
    }

    public override void handleAfterUpdate() 
    {
        validateTaggedUsers((Map<Id, FeedComment>) Trigger.newMap);
    }

    public static void validateTaggedUsers(Map<Id,FeedComment> feedComments)
    {
        // changes added by Vandhana for ESESP-6457 : bypass validation so that CRM Ops can scrub comments
		String crmOpsId = SC_Utility__mdt.getInstance('CRM_Ops_Id').Value_Text__c;

        if(!String.valueOf(UserInfo.getUserId()).containsIgnoreCase(crmOpsId))
        {
            List<SC_ChatterMentionUtils.FeedItemWrapper> items = new List<SC_ChatterMentionUtils.FeedItemWrapper>();
            for (FeedComment fi : feedComments.values()){
                items.add(new SC_ChatterMentionUtils.FeedItemWrapper(fi));
            }
            Map<Id,List<String>> invalidPosts = SC_ChatterMentionUtils.validateMentionSegments(items);
            for (Id commentId : invalidPosts.keySet()){
                feedComments.get(commentId).addError('Error: Mentioning external users has been disabled. External user(s) found: '+String.join(invalidPosts.get(commentId),', '));
            }
        }
    }
}