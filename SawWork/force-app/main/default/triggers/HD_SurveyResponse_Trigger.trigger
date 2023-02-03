/*
*
* Object: HD_Survey_Response__c
* Details : Trigger for custom survey response object.
* 
* Developer      Date      Version    Update 
* kimishra      06/13/2020    1.0      Initial version
*
*
*/
trigger HD_SurveyResponse_Trigger on HD_Survey_Response__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    CPQ_TriggerDispatcher.run(new HD_SurveyResponseTriggerHandler());
}