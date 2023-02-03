trigger cronBatchJob_bi_bu on Cron_Batch_Job__c (before insert , Before update) {
//  Code By Rahul : AKAM field updation Through The code
  if(Trigger.isBefore) {
    Id CrmIntegration = Id.valueOf(GsmUtilClass.getGSMSettingValue('CRM_Integration')); //SFDC-2391
    for(Cron_Batch_Job__c batch : Trigger.new){
      //This code takes care OF AKAM fields while insert if any of these field is null or Empty
      if(Trigger.isInsert){
        if((UserInfo.getUserId() == CrmIntegration && (batch.AKAM_Created_By__c =='' || 
          batch.AKAM_Created_Date__c == null ||batch.AKAM_System__c =='')) || UserInfo.getUserId() != CrmIntegration ) {
          batch.AKAM_Created_By__c = batch.AKAM_Alias__c ;
          batch.AKAM_Created_Date__c = system.now();
          batch.AKAM_System__c ='FORCE';
        }
      }      
    // This code bassically checks if any value of Akam modified is null for Insert or Updates it populates the default value
      if((UserInfo.getUserId() == CrmIntegration && (batch.AKAM_Modified_Date__c  == null|| 
        batch.AKAM_Modified_By__c == '' || batch.AKAM_Modified_By__c == null)) || UserInfo.getUserId() != CrmIntegration )  {
        batch.AKAM_Modified_By__c = batch.AKAM_Alias__c;
        batch.AKAM_Modified_Date__c =  system.now();  
      }
    }
  }       
}