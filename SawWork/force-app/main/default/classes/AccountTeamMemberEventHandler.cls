public class AccountTeamMemberEventHandler {
    public static void createRecordsToSync(Set<Id> recordIds,String objectName) {
        List<RecordToSync__c> auditTrailsToBeInserted = new List<RecordToSync__c>();

    	List<Account> recordsThatUpdated = [Select Id,AKAM_Account_ID__c from Account where Id in :recordIds];
         System.debug('recordsThatUpdated ' + recordsThatUpdated);
         for(Account record : recordsThatUpdated) {
             System.debug('record Id ' + record.AKAM_Account_ID__c);
             RecordToSync__c  auditTrail = new RecordToSync__c();
             auditTrail.BusinessComponent__c = objectName;
             auditTrail.ChangedFields__c = '';
             auditTrail.IntegrationId__c = record.AKAM_Account_ID__c; 
             auditTrail.DownstreamSystemToSync__c  = 'Siebel';
             auditTrailsToBeInserted.add(auditTrail);
       }
        
       if(auditTrailsToBeInserted.size() > 0) {
       		insert auditTrailsToBeInserted;
       }
    }
}