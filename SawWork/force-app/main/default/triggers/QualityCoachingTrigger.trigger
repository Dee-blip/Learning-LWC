/*
* Developer  : Bhavesh Kumar
* Purpose    : Trigger on Quality coaching object
* Date       : 4 Jan 2021
* Test Class : 
* Handler Name:SC_QualityCoachingTriggerHandler
* Date                 Developer           JIRA                            Changes
* 4-Jan-2021          Bhavesh         ESESP-3590                 RCA:restrict users to delete quality coaching record.
*   

*/ 
trigger QualityCoachingTrigger on SC_KCS_Scorecard__c (before delete, before update) {
    List<SC_KCS_Scorecard__c> rcaQualityDeleteList = new List< SC_KCS_Scorecard__c>();
    List<SC_KCS_Scorecard__c> rcaQualityUpdateList = new List< SC_KCS_Scorecard__c>();
    Id rcaRtId = Schema.SObjectType.SC_KCS_Scorecard__c.getRecordTypeInfosByName().get('RCA Request').getRecordTypeId();
	if(Trigger.isBefore && Trigger.isDelete){
    	for(SC_KCS_Scorecard__c score : Trigger.Old){
            if( score.recordTypeId == rcaRtId ){
                rcaQualityDeleteList.add(score);
            }
        }
    }
    if(Trigger.isBefore && Trigger.isUpdate){
        for(SC_KCS_Scorecard__c score : Trigger.New){
            if( score.recordTypeId == rcaRtId 
                && (score.Coaching_Occurred_By__c != Trigger.oldMap.get(score.Id).Coaching_Occurred_By__c || 
                    score.Coaching_Start_Date__c != Trigger.oldMap.get(score.Id).Coaching_Start_Date__c) ){
                if( score.Coaching_Occurred_By__c == NULL ){
                    score.addError('Coaching occurred by cannot be blank.');
                } else if( score.Coaching_Start_Date__c == NULL ){
                    score.addError('Coaching start date cannot be blank.');
                } else {
                    rcaQualityUpdateList.add(score);
                }       
                
            }
        }
    }
    
    if(rcaQualityDeleteList.size()>0){
        SC_QualityCoachingTriggerHandler.restrictRcaQualityDelete(rcaQualityDeleteList);
    }
    if(rcaQualityUpdateList.size()>0){
        SC_QualityCoachingTriggerHandler.qualityCoachingOccuredValidation(rcaQualityUpdateList);
    }
}