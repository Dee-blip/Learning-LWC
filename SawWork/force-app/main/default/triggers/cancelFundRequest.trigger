trigger cancelFundRequest on SFDC_MDF__c (after update) {

PRMTriggerClass.FRCancelFundRequestTriggerMethod(Trigger.new, Trigger.oldMap, Trigger.newMap);
    
    /*
     *  If a Fund Request is cancelled and was previously approved, release the reserved funds (allocations) from any associated budgets.
     */ 
/*     
     set<Id> frids = new set<Id>();
     list<SFDC_MDF__c> frlist = new list<SFDC_MDF__c>();
     SFDC_MDF__c oldFundRequest = null;
     for (SFDC_MDF__c fr : trigger.new) {
        oldFundRequest = trigger.oldMap.get(fr.Id);
        if ((fr.Status__c == 'Cancelled') && (oldFundRequest.Status__c != 'Cancelled')) {
            frids.add(fr.Id);
            frlist.add(fr);
        }
     }
     if (frids != null && frids.size() > 0) {
         list<Budget_Allocation__c> updBAs = new list<Budget_Allocation__c>();
         Id rtid = [select Id from RecordType where SObjectType = 'Budget_Allocation__c' and Name = 'Cancelled' limit 1].Id;
         for (Budget_Allocation__c ba : [select Id, RecordTypeId from Budget_Allocation__c where Fund_Request__c in :frids and RecordType.Name = 'Reserved']) {
            ba.RecordTypeId = rtid;
            updBAs.add(ba);
         }
         
         if (updBAs.size() > 0) {
             try {
                update updBAs;
             } catch(Exception e) {
                String message = 'An error occurred: '+ '\nMessage: ' + e.getMessage() + '\nCause: ' + e.getCause();
                frlist.get(0).addError(message);
             }
         }
    }
*/
}