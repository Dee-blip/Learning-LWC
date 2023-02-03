/*******************************************************************************************************
Author       :   jrathod
Created Date :   Jan 05,2022
JIRA         :   ESESP-4062
Description  :  Utility class to validate external user mentions in rich text chatter posts or comments
********************************************************************************************************
Jay               05-Jan-2022       ESESP-4062    Initial version
*/

public without sharing class SC_ChatterMentionUtils {

    public class FeedItemWrapper {
        public Id itemId;
        public Id parentId;
        public Object feedItemOrComment;

        public FeedItemWrapper(Object feedItemOrComment){
            this.feedItemOrComment = feedItemOrComment;
            if (feedItemOrComment instanceof FeedItem) {
                this.itemId = ((FeedItem) feedItemOrComment).Id;
                this.parentId = ((FeedItem) feedItemOrComment).ParentId;
            }else if (feedItemOrComment instanceof FeedComment) {
                this.itemId = ((FeedComment) feedItemOrComment).Id;
                this.parentId = ((FeedComment) feedItemOrComment).ParentId;
            }
        }
    }

    public static Map<Id,List<String>> validateMentionSegments(List<FeedItemWrapper> feedItems) {
        SC_Utility__mdt mdtEmailDomains = SC_Utility__mdt.getInstance('ChatterMentionsEmailDomain');
        SC_Utility__mdt mdtObjects = SC_Utility__mdt.getInstance('ChatterMention_ObjectApplicableTo');
        SC_Utility__mdt mdtCaseRTs = SC_Utility__mdt.getInstance('ChatterMention_CaseRTs');
        Map<Id,List<String>> invalidItems = new Map<Id, List<String>>();
        if (mdtEmailDomains.Active__c && mdtObjects.Active__c && mdtCaseRTs.Active__c) {
            Set<String> allowedObjects = new Set<String>(mdtObjects.Value_Text__c.split(','));
            Set<String> allowedCaseRTs = new Set<String>(mdtCaseRTs.Value_Text__c.split(','));

            List<Id> caseIds = new List<Id>();
            for (FeedItemWrapper wr : feedItems) {
                String objName = String.valueOf(wr.parentId.getSobjectType());
                if (objName == 'Case') {
                    caseIds.add(wr.parentId);
                }
            }
            Map<Id, Case> cases = new Map<Id, Case>();
            if (!caseIds.isEmpty()) {
                cases = new Map<Id, Case>([SELECT Id,RecordType_Name__c FROM Case WHERE Id IN :caseIds]);
            }
            Set<Id> fiToValidate = new Set<Id>();
            for (FeedItemWrapper wr : feedItems) {
                String objName = String.valueOf(wr.parentId.getSobjectType());
                if (allowedObjects.contains(objName)) {
                    if (objName == 'Case') {
                        if (allowedCaseRTs.contains(cases.get(wr.parentId).RecordType_Name__c)) fiToValidate.add(wr.itemId);
                    } else {
                        fiToValidate.add(wr.itemId);
                    }
                }
            }
            Map<Id, List<Id>> itemToMentionedUserIds = new Map<Id, List<Id>>();

            for (FeedItemWrapper wr : feedItems) {
                if (fiToValidate.contains(wr.itemId)) {
                    List<ConnectApi.MessageSegment> messageSegments = new List<ConnectApi.MessageSegment>();
                    try{
                        if (Test.isRunningTest()) {
                            List<Id> userIds = new List<Id>();
                            Id uId = UserInfo.getUserId();
                            userIds.add(uId);
                            itemToMentionedUserIds.put(wr.itemId,userIds);
                            continue;
                        }
                        if (wr.feedItemOrComment instanceof FeedItem) {
                            ConnectApi.FeedElement fElem = ConnectApi.ChatterFeeds.getFeedElement('internal', wr.itemId);
                            if (fElem != null && fElem.body != null) {
                                messageSegments = fElem.body.messageSegments;
                            }
                        } else if (wr.feedItemOrComment instanceof FeedComment) {
                            ConnectApi.Comment fComment = ConnectApi.ChatterFeeds.getComment('internal', wr.itemId);
                            if (fComment != null && fComment.body != null) {
                                messageSegments = fComment.body.messageSegments;
                            }
                        }
                    }catch (Exception e){
                        System.debug(e);
                        sendErrorEmail(e);
                    }
                    if (!messageSegments.isEmpty()) {
                        for (ConnectApi.MessageSegment segment : messageSegments) {
                            if (segment instanceof ConnectApi.MentionSegment) {
                                ConnectApi.MentionSegment mentionSegment = (ConnectApi.MentionSegment) segment;
                                if (mentionSegment.record != null) {
                                    if (itemToMentionedUserIds.containsKey(wr.itemId)) {
                                        itemToMentionedUserIds.get(wr.itemId).add(mentionSegment.record.id);
                                    } else {
                                        itemToMentionedUserIds.put(wr.itemId, new List<Id>{mentionSegment.record.id});
                                    }
                                }
                            }
                        }
                    }
                }
            }

            if (itemToMentionedUserIds.size() > 0) {
                List<String> allowedEmailDomains = mdtEmailDomains.Value_Text__c.split(',');
                Set<Id> userIds = new Set<Id>();
                for (List<Id> temp : itemToMentionedUserIds.values()) {
                    userIds.addAll(temp);
                }
                Map<Id, User> mentionedUsers = new Map<Id, User>();
                for (User u : [SELECT Id,Email,Name FROM User WHERE Id IN :userIds]) {
                    mentionedUsers.put(u.Id, u);
                }

                for (Id itemId : itemToMentionedUserIds.keySet()){
                    List<Id> users = itemToMentionedUserIds.get(itemId);
                    List<String> userNames = new List<String>();
                    for (Id userId : users){
                        if (mentionedUsers.containsKey(userId)) {
                            User u = mentionedUsers.get(userId);
                            String emailDomain = u.Email.substringAfterLast('@');
                            if (!allowedEmailDomains.contains(emailDomain)) userNames.add(u.Name);
                        }
                    }
                    if (!userNames.isEmpty()) {
                        invalidItems.put(itemId,userNames);
                    }
                }
            }

        }
        return invalidItems;
    }

    public static void sendErrorEmail(Exception e){
        String setEmailSub = 'Exception in Chatter Post Mentions Validation';
        String errorMessage =  	'Instance = ' + Url.getSalesforceBaseUrl().toExternalForm() + '\n' +
                'Support Class Name = SC_ChatterMentionUtils\n' +
                'Method Name = validateMentionSegments\n';
        errorMessage += e.getCause()+'..'+e.getLineNumber()+'..'+e.getMessage()+'..'+e.getTypeName()+'..'+e.getStackTraceString();
        new SC_Autogen_COB_Support().senEmailForError(setEmailSub, errorMessage);
    }

}