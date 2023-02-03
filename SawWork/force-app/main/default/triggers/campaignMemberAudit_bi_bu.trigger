trigger campaignMemberAudit_bi_bu on CampaignMemberAuditTrail__c (Before insert , Before update) {
  //  Code By Rahul : AKAM field updation Through The code
  if(Trigger.isBefore) {
    Id CrmIntegration = Id.valueOf(GsmUtilClass.getGSMSettingValue('CRM_Integration'));// SFDC-2705 Custom Settings Migration
    for(CampaignMemberAuditTrail__c cmat : Trigger.new){
      //This code takes care OF AKAM fields while insert if any of these field is null or Empty
      if(Trigger.isInsert){
        if((UserInfo.getUserId() == CrmIntegration && (cmat.AKAM_Created_By__c =='' || 
          cmat.AKAM_Created_Date__c == null ||cmat.AKAM_System__c =='')) || UserInfo.getUserId() != CrmIntegration ) {
          cmat.AKAM_Created_By__c = cmat.AKAM_Alias__c ;
          cmat.AKAM_Created_Date__c = system.now();
          cmat.AKAM_System__c ='FORCE';
        }
      }      
    // This code bassically checks if any value of Akam modified is null for Insert or Updates it populates the default value
      if((UserInfo.getUserId() == CrmIntegration && (cmat.AKAM_Modified_Date__c  == null|| 
        cmat.AKAM_Modified_By__c == '' || cmat.AKAM_Modified_By__c == null)) || UserInfo.getUserId() != CrmIntegration )  {
        cmat.AKAM_Modified_By__c = cmat.AKAM_Alias__c;
        cmat.AKAM_Modified_Date__c =  system.now();  
      }
    }
  }       
}