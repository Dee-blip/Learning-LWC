trigger SC_PSAutomationDLTrigger on PS_Automation_Admin_DL__c (before insert) {
List<Id> accountId = new List<Id>();
Map<Id,PS_Automation_Admin_DL__c> accIdVsMailerRec = new Map<Id,PS_Automation_Admin_DL__c> ();
integer  count= database.countQuery('Select count() from PS_Automation_Admin_DL__c where recordType.Name = \'Internal\'');

    for(PS_Automation_Admin_DL__c dlRec :Trigger.new){
        if(dlRec.recordTypeId ==  Schema.SObjectType.PS_Automation_Admin_DL__c.getRecordTypeInfosByName().get('External').getRecordTypeId())
        accountId.add(dlRec.Account__c);
      

   
       else {
            if(count > 0){
                dlRec.addError('Internal Type record is already available.');
            }
          }
        
    }
    if(accountId.size() > 0){
        for(PS_Automation_Admin_DL__c dlRec :[Select Id,Name,Account__c from PS_Automation_Admin_DL__c where Account__c IN:accountId]){
            accIdVsMailerRec.put(dlRec.Account__c,dlRec);
        }
        for(PS_Automation_Admin_DL__c dlRec :Trigger.new){
            if(accIdVsMailerRec.containsKey(dlRec.Account__c)){
                dlRec.addError('Other record is already available for selected Account');
            }
        }
    }
    


}