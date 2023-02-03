/* 
DATE                DEVELOPER               CHANGE
________________________________________________________________________________
23-Aug-2018     Vandhana Krishnamurthy       Track create/edit timestamps for posts(FeedItems) 
                                             on Service Incident Notification Group

12-Feb-2019		Aditya Sonam				ESESP-1608
10-10-2020      Vishn Vardhan               ESESP-2826 :PST Case related Logic 
_______________________________________________________________________________
*/

trigger SC_CreateFeedTracker on FeedItem (after insert,after update, before update) 
{
    List<FeedItem> fiList = new List<FeedItem>();
    Set<Id> CaseIdSet = new Set<Id>();
    Set<String> trackingGroupId = new Set<String>([SELECT Value__c 
                                                   FROM SC_Utility__mdt
                                                   WHERE DeveloperName = 'Track_Edit_Community_Post_for_Group'
                                                   LIMIT 1].Value__c.split(','));
    
    if(!UserInfo.getName().equalsIgnoreCase('Connection User'))
    {
        for(FeedItem fi : Trigger.new)
        {
            if((trackingGroupId.contains(fi.ParentId) && fi.Type == 'TextPost') || Test.isRunningTest()) 
            {
                if(Trigger.isInsert || (Trigger.isUpdate && fi.Body != Trigger.oldMap.get(fi.Id).Body))
                fiList.add(fi);        
            }
            if(String.valueOf(fi.ParentId.getSObjectType()) == 'Case' && fi.Type == 'TextPost' && (Trigger.isInsert || (Trigger.isUpdate && fi.Body != Trigger.oldMap.get(fi.Id).Body))){
                CaseIdSet.add(fi.ParentId);
            }
            
        }
        if(CaseIdSet.size() >0){
            SC_CaseNotesHandler.handleCaseNotes(CaseIdSet);
        }
        if(!fiList.isEmpty())
        {
            SC_CreateFeedTrackerHelper.createFeedItemTrackerRec(fiList, Trigger.isInsert);
        }
    }
    //ESESP-2826 :PST Case related Logic
    SC_TriggerHandlerAbstract feedTriggerHandler = new SC_FeedItemTriggerHandler(); 
    feedTriggerHandler.process();
}