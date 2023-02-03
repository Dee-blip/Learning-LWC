public class MARIT_CSAT_FollowUp_Dialog_Controller {
    public class DateAndFields {
        DateTime onLoadDate;
        DateTime actualCompletionDate;
        String followUpFields;
    }
    
    @AuraEnabled
    public static String GetFollowUpFields(String recordId) {
        DateAndFields initialFields = new DateAndFields();
        List<Qualtrics_Setting__mdt> mdtRecord = [select Id, JSONValue__c from Qualtrics_Setting__mdt where DeveloperName = 'QualtricsFollowUpFields'];
        if(mdtRecord.size() > 0) {
            initialFields.followUpFields = mdtRecord[0].JSONValue__c;
        }
        CSAT_Survey_Response__c csatObj = [Select Id, Follow_Up_Complete_Date__c, Actual_Completion_Date__c  from CSAT_Survey_Response__c where Id =:recordId];
        initialFields.onLoadDate = csatObj.Follow_Up_Complete_Date__c;
        initialFields.actualCompletionDate = csatObj.Actual_Completion_Date__c;
        return Json.serialize(initialFields);
    }
}