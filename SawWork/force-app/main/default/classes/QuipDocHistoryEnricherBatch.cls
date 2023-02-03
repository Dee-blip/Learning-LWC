/*Created By: Vivek Baidya
* Created Date: 23-March-2020
* Description: This batch class creates or updates Account_Plan_Tracker__c records from Quip_Document_History__c records.
* JIRA: https://track.akamai.com/jira/browse/SFDC-6399
*/ 
global class QuipDocHistoryEnricherBatch implements Database.Batchable<Sobject>, Database.AllowsCallouts {
    global final string query;
    global Map<String, Object> quipEventTypeToAction = (Map<String, Object>)JSON.deserializeUntyped(GsmUtilClass.getGSMSettingValue('Quip_EventTypeToAction'));
    global string createEventSubAction = GsmUtilClass.getGSMSettingValue('Quip_CreateEvent_SubAction');
    global string editEventSubAction = GsmUtilClass.getGSMSettingValue('Quip_EditEvent_SubAction');
    
    global QuipDocHistoryEnricherBatch(){
        //query string for non-processed event logs from quip_document_history__c object
        query = 'select id,Quip_Document_Id__c,quip_thread_id__c,quip_user_id__c,On__c,Event__c,Action__c,Sub_Action__c from quip_document_history__c where Is_Processed__c=false order by On__c asc';
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        //fetch all non-processed event logs from quip_document_history__c
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        Set<String> threadIds = new Set<String>();
        Set<String> userIds= new Set<String>();
        List<Quip_Document_History__c> quipDocHistory = (List<Quip_Document_History__c>)scope;
        
        for(Quip_Document_History__c qdh : quipDocHistory){
            //get all thread ids from event logs
            if(qdh.quip_thread_id__c!=null)
                threadIds.add(qdh.quip_thread_id__c); 
            //get all quip user ids from event logs
            if(qdh.Quip_User_Id__c!=null)
                userIds.add(qdh.quip_user_id__c); 
        }
        
        QuipCalloutClass qc = new QuipCalloutClass();
        //get map of quip user id to user email
        Map<String, String> quipUserIdToEmail = qc.getUsers(userIds);
        //get map of thread id to document link
        Map<String, String> quipThreadIdToLink = qc.getThreads(threadIds);
        
        Map<String, Id> linkToAPId = new Map<String, Id>();
        Map<Id, DateTime> apToLastModifiedDate = new Map<Id,DateTime>();
        Map<Id, Id> apToLastModifiedBy = new Map<Id,Id>();
        Map<String, Account_Plan_Tracker__c> actionToAccPlanTracker = new Map<String, Account_Plan_Tracker__c>();
        
        if(quipThreadIdToLink!=null && quipThreadIdToLink.size()>0){
            for(Account_Plan__c ap: [select id,(select id,Unique_Action_By_Date__c,No_of_Times__c,Action__c,User__c,Account_Plan__c,Date__c from Account_Plan_Tracker__r),Quip_New_Document_URL__c,Document_Last_Modified_Date__c, Document_Last_Modified_By__c from Account_Plan__c where Quip_New_Document_URL__c in :quipThreadIdToLink.values()])
            {
                //preapring map of account plan document link to account plan sf id
                linkToAPId.put(ap.Quip_New_Document_URL__c, ap.Id);
                //preapring map of account plan id to account plan document last modified date
                apToLastModifiedDate.put(ap.Id, ap.Document_Last_Modified_Date__c);
                apToLastModifiedBy.put(ap.Id, ap.Document_Last_Modified_By__c);
                //preparing map of unique action by an user for a particular account plan for a given date to Account_Plan_Tracker__c
                for(Account_Plan_Tracker__c apt : ap.Account_Plan_Tracker__r){
                    actionToAccPlanTracker.put(apt.Unique_Action_By_Date__c, apt);
                }
            }
        }
        
        Map<String, Id> userEmailToId = new Map<String,Id>();
        //preapring map of user email to sf user id
        if(quipUserIdToEmail!=null && quipUserIdToEmail.size()>0){
            for(User u: [select id,email from User where email in :quipUserIdToEmail.values()]){
                userEmailToId.put(u.email, u.Id);
            }
        }
        
        string prevActionByUserByPlanByTime='';
        for(Quip_Document_History__c qdh : quipDocHistory){
            string sfUserId='';
            string apId='';
            //getting sf user id from quip user id for a particular event log
            if(qdh.Quip_User_Id__c != null && quipUserIdToEmail.containsKey(qdh.Quip_User_Id__c)){
                string userEmail = quipUserIdToEmail.get(qdh.Quip_User_Id__c);
                if(userEmailToId.containsKey(userEmail)){
                    sfUserId=userEmailToId.get(userEmail);
                    sfUserId = (sfUserId.length() == 18)?sfUserId.substring(0, 15):sfUserId;
                }
            }
            //getting account plan record id from quip thread id for a particular event log
            if(qdh.Quip_Thread_Id__c != null && quipThreadIdToLink.containsKey(qdh.quip_thread_id__c)){
                string link = quipThreadIdToLink.get(qdh.quip_thread_id__c);
                if(linkToAPId.containsKey(link)){
                    apId = linkToAPId.get(link);
                    apId = (apId.length() == 18)?apId.substring(0, 15):apId;
                }
            }
            //getting account plan record id from quip document id for a particular event log
            if(qdh.Quip_Document_Id__c != null && quipThreadIdToLink.containsKey(qdh.Quip_Document_Id__c)){
                string link = quipThreadIdToLink.get(qdh.Quip_Document_Id__c);
                if(linkToAPId.containsKey(link)){
                    apId = linkToAPId.get(link);
                    apId = (apId.length() == 18)?apId.substring(0, 15):apId;
                }
            }
            
            if(apId != null && apId != '' && sfUserId != null && sfUserId != '')
            {
                string eventActionCombination = qdh.Event__c + '#' + qdh.Action__c + '#' + qdh.Sub_Action__c;
                string createEventByUserByPlanByTime = createEventSubAction+sfUserId+apId+string.valueOf(qdh.On__c);
                if(quipEventTypeToAction.containsKey(eventActionCombination) && (createEventByUserByPlanByTime != prevActionByUserByPlanByTime))
                {
                    //preparing unique key using action#date#user#account_plan 
                    String uniqueActionByDateByUser = eventActionCombination +'#'+String.valueOf(qdh.On__c.Date())+'#'+sfUserId+'#'+apId;
                    Account_Plan_Tracker__c apt;
                    //updating No_of_Times__c & Date__c on existing account plan tracker
                    if(actionToAccPlanTracker.containsKey(uniqueActionByDateByUser)){
                        apt = actionToAccPlanTracker.get(uniqueActionByDateByUser);
                        apt.No_of_Times__c = apt.No_of_Times__c + 1;
                        apt.Date__c = qdh.On__c;
                    }
                    //creating new instance of account plan tracker
                    else{
                        apt = new Account_Plan_Tracker__c(Account_Plan__c = apId,Date__c = qdh.On__c,No_of_Times__c = 1,User__c = sfUserId,Action__c = String.valueOf(quipEventTypeToAction.get(eventActionCombination)));
                    }
                    actionToAccPlanTracker.put(uniqueActionByDateByUser,apt);
                    //preparing map of account plan id to last-modified-date and last-modified-user
                    if(apToLastModifiedDate.containsKey(apId) && qdh.Sub_Action__c == editEventSubAction && (apToLastModifiedDate.get(apId)<qdh.On__c || apToLastModifiedDate.get(apId)==null))
                    {
                        apToLastModifiedDate.put(apId, qdh.On__c);
                        apToLastModifiedBy.put(apId, sfUserId);
                    }
                }
                prevActionByUserByPlanByTime=qdh.Sub_Action__c+sfUserId+apId+string.valueOf(qdh.On__c);
            }
            //marking is processed true so it doesn't get picked in the next job run
            qdh.Is_Processed__c = true;
        }
        
        List<Account_Plan_Tracker__c> aptToUpsert = new List<Account_Plan_Tracker__c>();
        aptToUpsert.addAll(actionToAccPlanTracker.values());
        //inserting or updating account plan tracker
        if(aptToUpsert.size()>0){
            GsmUtilClass.doDatabaseUpsert(aptToUpsert,'QuipDocHistoryEnricherBatch','aptToUpsert',false);
        }
        
        List<Account_Plan__c> apListToBeUpdated = new List<Account_Plan__c>();
        for(Id apId : apToLastModifiedDate.keySet())
        {
            apListToBeUpdated.add(new Account_Plan__c(Id=apId, Document_Last_Modified_Date__c=apToLastModifiedDate.get(apId),Document_Last_Modified_By__c=apToLastModifiedBy.get(apId)));
        }
        //updating Document_Last_Modified_Date__c and Document_Last_Modified_By__c on account plan
        if(apListToBeUpdated.size()>0){
            GsmUtilClass.doDatabaseUpdate(apListToBeUpdated,'QuipDocHistoryEnricherBatch','apListToBeUpdated');
        }
        
        //mark Is_Processed__c true for processed quip_document_history__c records
        if(quipDocHistory.size()>0){
            GsmUtilClass.doDatabaseUpdate(quipDocHistory,'QuipDocHistoryEnricherBatch','quipDocHistory');
        }
    }
    
    global void finish(Database.BatchableContext BC){
    }
}