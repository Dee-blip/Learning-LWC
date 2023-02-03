trigger rebatePayout_bi_bu on Rebate_Payout__c (before insert, before update) {
  //  Code By Rahul : AKAM field updation Through The code
  if(Trigger.isBefore) {
    Id CrmIntegration = Id.valueOf(GsmUtilClass.getGSMSettingValue('CRM_Integration'));
    for(Rebate_Payout__c rebate : Trigger.new){
      //This code takes care OF AKAM fields while insert if any of these field is null or Empty
      if(Trigger.isInsert){
        if((UserInfo.getUserId() == CrmIntegration && (rebate.AKAM_Created_By__c =='' || 
          rebate.AKAM_Created_Date__c == null ||rebate.AKAM_System__c =='')) || UserInfo.getUserId() != CrmIntegration ) {
          rebate.AKAM_Created_By__c = rebate.AKAM_Alias__c ;
          rebate.AKAM_Created_Date__c = system.now();
          rebate.AKAM_System__c ='FORCE';
        }
      }      
    // This code bassically checks if any value of Akam modified is null for Insert or Updates it populates the default value
      if((UserInfo.getUserId() == CrmIntegration && (rebate.AKAM_Modified_Date__c  == null|| 
        rebate.AKAM_Modified_By__c == '' || rebate.AKAM_Modified_By__c == null)) || UserInfo.getUserId() != CrmIntegration )  {
        rebate.AKAM_Modified_By__c = rebate.AKAM_Alias__c;
        rebate.AKAM_Modified_Date__c =  system.now();  
      }
    }
  }       
}