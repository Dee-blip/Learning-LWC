/*Created By: Vivek Baidya
* Created Date: 7-May-2021
* Description: This batch class creates or updates Account_Plan_Tracker__c records from Quip Metrics records.
* JIRA: https://track.akamai.com/jira/browse/SFDC-8471
*/ 


global class QuipDocHistoryEnricherBatchNew implements Database.Batchable<Sobject> {
    global final string query;
    global final string thread_type = 'DOCUMENT';
    
    global QuipDocHistoryEnricherBatchNew(){
        Integer sinceTimestampInDays = Integer.valueOf(GsmUtilClass.getGSMSettingValue('Quip_Event_Since_Timestamp_In_Days'));
        query = 'SELECT ID, MetricDate, SalesforceUserId, EditCount, ViewCount FROM CollabUserEngagementMetric WHERE QuipThreadType =: thread_type AND CreatedDate = LAST_N_DAYS:'+sinceTimestampInDays+' AND SalesforceUserId != NULL ORDER BY MetricDate ASC';
    }
    
    global Database.QueryLocator start(Database.BatchableContext bContext){
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bContext, List<sObject> scope){
        List<CollabUserEngagementMetric> enggMetricList = (List<CollabUserEngagementMetric>)scope;
        processEngagmentMetrics(enggMetricList);
    }
    
    global void finish(Database.BatchableContext bContext){
        //System.debug('QuipDocHistoryEnricherBatchNew Batch completed');
    }
    
    //create an instance of log record
    @TestVisible
    private Account_Plan_Tracker__c getTrackerInstance(String planId, DateTime metricDate, Integer noOfTimes, String sfUserId, String action){
        return new Account_Plan_Tracker__c(Account_Plan__c=planId, Date__c=metricDate, No_of_Times__c=noOfTimes, User__c=sfUserId, Action__c=action,ExternalId__c =PlanId+action+metricDate+sfUserId);
    } 
    
    @TestVisible
    private void processEngagmentMetrics(List<CollabUserEngagementMetric> enggMetricList ){
        
        List<Account_Plan_Tracker__c> aptToInsert = new List<Account_Plan_Tracker__c>();
        Map<Id,Id> metricIdToPlanId = new Map<Id,Id>();
        Map<Id,Account_Plan__c> planIdToPlan = new Map<Id,Account_Plan__c>();
        Map<Id,DateTime> planCreateDate = new Map<Id,DateTime>();
        
        //Map QuipMetrics to AccountPlan
        for(CollabUserEngmtRecordLink link : [SELECT UserEngagementMetricId, ParentRecordId FROM CollabUserEngmtRecordLink WHERE UserEngagementMetricId IN : enggMetricList]){
            metricIdToPlanId.put(link.UserEngagementMetricId, link.ParentRecordId);
        }
        //get the Account Plan's created dtae
        for(Account_Plan__c plan :[Select Id,Createddate from Account_Plan__c where id in :metricIdToPlanId.values()]){
            planCreateDate.put(plan.Id,plan.Createddate);
        } 
        
        //
        for(CollabUserEngagementMetric metric : enggMetricList){
            //check if the log created date is same as account plan created date then create log for created action
            if(metric.metricDate.Date() == PlanCreateDate.get(metricIdToPlanId.get(metric.Id)).Date()){
                aptToInsert.add(getTrackerInstance(metricIdToPlanId.get(metric.Id),metric.MetricDate,1,metric.SalesforceUserId,'Created'));
                
                //Update Plan with lastdocument update date from latest log metric date
                planIdToPlan.put(metricIdToPlanId.get(metric.Id), new Account_Plan__c(Id=metricIdToPlanId.get(metric.Id), Document_Last_Modified_Date__c=metric.MetricDate, Document_Last_Modified_By__c=metric.SalesforceUserId));
                
            }
            //check if the view count is present then create log for Opened action
            if(metric.ViewCount > 0){
                aptToInsert.add(getTrackerInstance(metricIdToPlanId.get(metric.Id),metric.MetricDate,metric.ViewCount,metric.SalesforceUserId,'Opened'));
            }
            //check if the edit count is present then create log of edit action
            if(metric.EditCount > 0){
                aptToInsert.add(getTrackerInstance(metricIdToPlanId.get(metric.Id),metric.MetricDate,metric.EditCount,metric.SalesforceUserId,'Edited'));
                
                //Update Plan with lastdocument update date from latest log metric date
                planIdToPlan.put(metricIdToPlanId.get(metric.Id), new Account_Plan__c(Id=metricIdToPlanId.get(metric.Id), Document_Last_Modified_Date__c=metric.MetricDate, Document_Last_Modified_By__c=metric.SalesforceUserId));
            }
            
        }
        
        //Insert Activity Logs
        if(aptToInsert.size()>0){
            GsmUtilClass.doDatabaseInsert(aptToInsert,'QuipDocHistoryEnricherBatchNew','aptToInsert',false);
        }
        
        //update Plans
        if(planIdToPlan.size()>0){
            GsmUtilClass.doDatabaseUpdate(planIdToPlan.values(),'QuipDocHistoryEnricherBatchNew','planIdToPlan');
        }
        
    }
    
}