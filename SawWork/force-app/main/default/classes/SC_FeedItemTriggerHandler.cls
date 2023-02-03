/****************************************************************************
* Class name          :   SC_FeedItemTriggerHandler.cls
* Author              :   Vishnu Vardhan
* Created             :   20-August-2020
* Purpose             :   Feed Item Trigger Handler
* Test Class          :   
-------------------------------------------------------------------------------
* MethodName          : Purpose
-------------------------------------------------------------------------------
*****************************************************************************

DATE             DEVELOPER        CR              DESCRIPTION
===========      =========        =======         ===========
Aug 20, 2020     Vishnu Vardhan   ESESP-2826      PST related Case Trigger logic
Dec 23, 2021     Jay Rathod       ESESP-4062      Implemented validateTaggedUsers
20-May-2022      Vandhana         ESESP-6457    SC IP Scrubbing, bypass validateTaggedUsers for CRM Ops
*****************************************************************************/

public with sharing class SC_FeedItemTriggerHandler extends SC_TriggerHandlerAbstract{

    public override Boolean triggerCheck() {
        System.debug('logLevel');
        return !UserInfo.getName().equalsIgnoreCase('Connection User');
    }

    public override void handleAfterInsert() 
    {
        Map<Id,FeedItem> feedItems = (Map<Id, FeedItem>) Trigger.newMap;
        
        List<FeedItem> newCaseFeedItems = new List<FeedItem>();
        for(FeedItem fi : feedItems.values()) 
        {
            String sobjectType = String.valueOf(fi.ParentId.getSObjectType());
            if(sobjectType == 'Case' && fi.type == 'TextPost') 
            {
                newCaseFeedItems.add(fi);
            }
        }

        //ESESP-2826 :PST Case related Logic
        if(!newCaseFeedItems.isEmpty()) 
        {
            this.updatePstCase(newCaseFeedItems);
        }

        //ESESP-4062
        validateTaggedUsers(feedItems);
    }

    //ESESP-4062
    public override void handleAfterUpdate() 
    {
        Map<Id,FeedItem> feedItems = (Map<Id, FeedItem>) Trigger.newMap;
        if (feedItems!=null && !feedItems.isEmpty()) 
        {
            validateTaggedUsers(feedItems);
        }
    }

    public override void handleBeforeUpdate() 
    {
        List<FeedItem> newList = Trigger.new;
        Map<Id, FeedItem> oldMap = (Map<Id, FeedItem>)Trigger.oldMap;
        List<FeedItem> updatedCaseFeedItems = new List<FeedItem>();

        for(FeedItem fi : newList) 
        {
            String sobjectType = String.valueOf(fi.ParentId.getSObjectType());
            if(sobjectType == 'Case' && fi.type == 'TextPost') 
            {
                if(fi.Body != oldMap.get(fi.Id).Body) 
                {
                    updatedCaseFeedItems.add(fi);
                }
            }
        }
        //ESESP-2826 :PST Case related Logic
        this.pstFeedValidation(updatedCaseFeedItems);
    }
    public override void handleBeforeDelete() {
        List<FeedItem> oldList = Trigger.old;
        List<FeedItem> textFeedDeletes = new List<FeedItem>();

        // filter case feeditems with type "TextPost"
        for(FeedItem fi : oldList) {
            String sobjectType = String.valueOf(fi.ParentId.getSObjectType());
            if(sobjectType == 'Case' && fi.type == 'TextPost') {
                textFeedDeletes.add(fi);
            }
        }

        this.pstFeedValidation(textFeedDeletes);
        
    }


    // Field Update: Update Notes field for PST Case
    // ESESP-2826 - Vishnu Vardhan
    public void updatePstCase(List<FeedItem> newFeeds) {
        Set<Id> caseIds = new Set<Id>();
        for(FeedItem fi: newFeeds) {
            caseIds.add(fi.parentId);
        }

        Map<Id, Case> pstCaseMap = new Map<id, Case>([select id from Case where id =:caseIds and RecordType.DeveloperName = 'PST_Case' and isClosed = false]);
        if(pstCaseMap.isEmpty()) {
            return;
        }
        List<Case> toUpdPSTCases = new List<Case>();

        for(FeedItem fi: newFeeds) {
            Case pstCase = pstCaseMap.get(fi.ParentId);

            if(pstCase != null) {
                pstCase.PST_Notes__c = fi.Body;
                pstCase.Last_Customer_Activity_Date__c = System.now();
                toUpdPSTCases.add(pstCase);
            }
        }

        update toUpdPSTCases;
    }

    //Validation: PST TextPosts are immutable (cannot be edited/ deleted)
    // ESESP-2826 - Vishnu Vardhan
    public void pstFeedValidation(List<FeedItem> textFeeds) {

        if(textFeeds.isEmpty()) {
            return;
        }

        Set<Id> caseIds = new Set<Id>();
        for(FeedItem fi: textFeeds) {
            caseIds.add(fi.parentId);
        }
        Map<Id, Case> pstCaseMap = new Map<id, Case>([select id from Case where id =:caseIds and RecordType.DeveloperName = 'PST_Case']);
        
        if(pstCaseMap.isEmpty()) {
            return;
        }

        for(FeedItem fi: textFeeds) {
            if(pstCaseMap.containsKey(fi.ParentId)) 
            {
                fi.addError('PST Case comments cannot be edited/ deleted.');
            }
        }
    }
    
    public static void validateTaggedUsers(Map<Id,FeedItem> feedItems)
    {
        // changes added by Vandhana for ESESP-6457 : bypass validation so that CRM Ops can scrub comments
        String crmOpsId = SC_Utility__mdt.getInstance('CRM_Ops_Id').Value_Text__c;
        
        // changes added by Vandhana for ESESP-6457 : bypass validation so that CRM Ops can scrub comments
        if(!String.valueOf(UserInfo.getUserId()).containsIgnoreCase(crmOpsId))
        {
            System.debug('Non Ops');
            List<SC_ChatterMentionUtils.FeedItemWrapper> items = new List<SC_ChatterMentionUtils.FeedItemWrapper>();
            for (FeedItem fi : feedItems.values()){
                items.add(new SC_ChatterMentionUtils.FeedItemWrapper(fi));
            }
            Map<Id,List<String>> invalidPosts = SC_ChatterMentionUtils.validateMentionSegments(items);
            for (Id feedItemId : invalidPosts.keySet()){
                feedItems.get(feedItemId).addError('Mentioning external users has been disabled. External user(s) found: '+String.join(invalidPosts.get(feedItemId),', '));
            }
            
        }
    }

}