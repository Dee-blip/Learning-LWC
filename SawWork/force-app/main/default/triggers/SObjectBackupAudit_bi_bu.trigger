trigger SObjectBackupAudit_bi_bu on Sobject_Backup_Audit__c (before insert , Before Update) {
 //  Code By Rahul : AKAM field updation Through The code
  if(Trigger.isBefore) {
    //SFDC-2686
    Id CrmIntegration = Id.valueOf(GsmUtilClass.getGSMSettingValue('CRM_Integration'));
    for(Sobject_Backup_Audit__c sbackaudit : Trigger.new){
      //This code takes care OF AKAM fields while insert if any of these field is null or Empty
      if(Trigger.isInsert){
        if((UserInfo.getUserId() == CrmIntegration && (sbackaudit.AKAM_Created_By__c =='' || 
          sbackaudit.AKAM_Created_Date__c == null ||sbackaudit.AKAM_System__c =='')) || UserInfo.getUserId() != CrmIntegration ) {
          sbackaudit.AKAM_Created_By__c = sbackaudit.AKAM_Alias__c ;
          sbackaudit.AKAM_Created_Date__c = system.now();
          sbackaudit.AKAM_System__c ='FORCE';
        }
      }      
    // This code bassically checks if any value of Akam modified is null for Insert or Updates it populates the default value
      if((UserInfo.getUserId() == CrmIntegration && (sbackaudit.AKAM_Modified_Date__c  == null|| 
        sbackaudit.AKAM_Modified_By__c == '' || sbackaudit.AKAM_Modified_By__c == null)) || UserInfo.getUserId() != CrmIntegration )  {
        sbackaudit.AKAM_Modified_By__c = sbackaudit.AKAM_Alias__c;
        sbackaudit.AKAM_Modified_Date__c =  system.now();  
      }
    }
  }       
}