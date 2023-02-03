/**
 * Trigger on SC_User_Filter__c object
 * Test Class:
 * History:
 * =========================
 * Developer        Date        	Description
 * ---------------------------------------------------------------------------------------------------------------------------
 * Harshil			03/09/2020		Created Trigger. ESESP-3537: Added logic to trigger deletion for marked EB Product records 
*/

trigger SC_User_FilterTrigger on SC_User_Filter__c (after Update) {
    
    boolean isCallToEBProductJob = false;
    
    for(SC_User_Filter__c eachRec : Trigger.New){
        
        if(eachRec.Unique_ID__c == 'EB_Product_Job' && eachRec.Filter_Values__c != Trigger.OldMap.get(eachRec.Id).Filter_Values__c  &&
           eachRec.Filter_Values__c  == 'Synced' && eachRec.RecordTypeId == Schema.SObjectType.SC_User_Filter__c.getRecordTypeInfosByName().get('Metadata').getRecordTypeId()){
            isCallToEBProductJob = true;
           }
        
    }
    
    // Call to EB Product Job
    if(isCallToEBProductJob)
        Database.executeBatch(new SC_DeleteSobject('Select Id FROM EB_Product__c WHERE EB_Marked_for_Deletion__c = true','EB_Product_Job'),2000);
    
}