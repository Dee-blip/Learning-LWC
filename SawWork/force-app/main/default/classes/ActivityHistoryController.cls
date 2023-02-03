// SFDC-2407 Added by Mayank Bansal 13th March 2018 
public class ActivityHistoryController {

    @AuraEnabled
    public Static String getTaskRecords(String akam_Lead_ID){
        List<Task> tasks = new List < Task > ();
        List < Task > returnList = new List < Task > ();
        String marketoProfileIDs = null;
        List<GSM_Settings__mdt> gsmSetting = [SELECT MasterLabel, Value__c FROM GSM_Settings__mdt where DeveloperName like 'MarketoProfileIDs'];
        if(gsmSetting.size() > 0){
            marketoProfileIDs = gsmSetting.get(0).Value__c;
        }
        if(marketoProfileIDs != null){
        tasks = [Select Id, ActivityDate, Type, Type__c, createdDate, Owner.Name, AKAM_Modified_Date__c, Subject, What.Name,Status, Priority
                 from Task where Associated_AKAM_Lead_ID__c = :akam_Lead_ID and createdBy.profileID != :marketoProfileIDs];
        } else {
        tasks = [Select Id, ActivityDate, Type, Type__c, createdDate, Owner.Name, AKAM_Modified_Date__c, Subject, What.Name,Status, Priority
                 from Task where Associated_AKAM_Lead_ID__c = :akam_Lead_ID];    
        }
        for (Task tsk: tasks) {
            returnList.add(tsk);
        }
        return JSON.serialize(returnList);
    }

}