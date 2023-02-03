/***
    TaskTriggerClass
    @author : Shivam Verma <shiverma@akamai.com>
    @Description :  This class contains static methods that are called by Task trigger specific to L2Q team

    @History
    --Developer           --Date            --Change
    Shivam Verma          --/08/17          Created the class. 

*/
public class L2Q_TaskTriggerClass {
    
    /*
     * Below code updates the TQL SLA Activity counter based on the following criteria
     * If an Activity is Created for an Opportunity with following conditions increment the TQL SLA Activity counter value
     *  Record Type = 'AWE Opportunities' 
     *  AND Sales Stage = '1 - Create' 
     *  AND Activity Created Date >= [N3 TQL Date] 
     *  AND Activity Created Date <= [TQL SLA End Date] 
     *  AND Activity Created By = Activity's Opportunity Owner
     */
    //public static boolean firstRunFlagForStampTQLSLACounter = false;
    public static void stampTQLSLACounterValue(Task[] taskList) {
        
        /*List<Opportunity> opportunityUpdateList = new List<opportunity>();
        
        //Get the AWE opportunity record type id
        Id aweOppRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('AWE Opportunities').getRecordTypeId();
        
        List<String> stagesList = GSMUtilClass.getGSMSettingValue('N3TaskCounterStages').split(',');
        Set<String> stagesSet = new Set<String>();
        stagesSet.addAll(stagesList);
        
        //Create a list of task ids and a map to task id to task
        List<Id> opptyIds = new List<Id>();
        Map<Id,Id> oppIdToTaskIdMap = new Map<Id,Id>();
        for (Task t:taskList) {
            opptyIds.add(t.whatId);
            oppIdToTaskIdMap.put(t.WhatId, t.Id);
        }
        
        //Creating map of task id to opportunity record to check the matching criteria
        Map<Id,Opportunity> taskIdToOppotunityMap = new Map<Id,Opportunity>();
        List<Opportunity> taskRelatedOppty = [Select id,StageName,RecordTypeId,OwnerId,N3_TQL_Date__c,Owner__c ,
                                                      TQL_SLA_End_Date__c, TQL_SLA_Activity_Counter__c, Validation_Override__c
                                              From Opportunity where id IN:opptyIds];
        
        if (taskRelatedOppty != null && taskRelatedOppty.size() > 0) {
            for (Opportunity opp:taskRelatedOppty) {
                Id taskId = oppIdToTaskIdMap.get(opp.id);
                taskIdToOppotunityMap.put(taskId, opp);
            }
        }
        
        for (Task t:taskList) {
            System.debug('task here :'+t);
            Opportunity opp = taskIdToOppotunityMap.get(t.Id);
            //System.debug('TQL_SLA_End_Date__c :'+opp.TQL_SLA_End_Date__c);
            
            if (opp != null) {
                    if ((opp.recordTypeId != null && opp.recordTypeId.equals(aweOppRecordTypeId)) &&
                    stagesSet.contains(opp.StageName) &&
                    t.AKAM_Created_Date__c >= opp.N3_TQL_Date__c &&
                    t.AKAM_Created_Date__c <= opp.TQL_SLA_End_Date__c &&
                    t.CreatedById.equals(opp.OwnerId)
                   )
                {
                    System.debug('Updating counter on opportunity');
                    Integer counterValue = 0;
                    if (opp.TQL_SLA_Activity_Counter__c != null) {
                        counterValue = Integer.valueOf(opp.TQL_SLA_Activity_Counter__c);
                    }       
                    opp.TQL_SLA_Activity_Counter__c = counterValue + 1;
                    opp.Validation_Override__c = true;
                    opportunityUpdateList.add(opp);    
                }
            }
            
        }
        
        if (opportunityUpdateList.size() > 0)
            update opportunityUpdateList;
        
        firstRunFlagForStampTQLSLACounter = true;*/
    }

}