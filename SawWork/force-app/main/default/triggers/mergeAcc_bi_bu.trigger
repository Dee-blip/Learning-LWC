trigger mergeAcc_bi_bu on Merged_Account__c (before insert, before update) {
    //  Code By Rahul : AKAM field updation Through The code
  if(Trigger.isBefore) {
    //Id CrmIntegration = Id.valueOf(GSM_Custom_Settings__c.getInstance('CRM_Integration').value__c); //SFDC-2304
    Id CrmIntegration = Id.valueOf(GsmUtilClass.getGSMSettingValue('CRM_Integration')); //SFDC-2304
    for(Merged_Account__c ma : Trigger.new){
      //This code takes care OF AKAM fields while insert if any of these field is null or Empty
      if(Trigger.isInsert){
        if((UserInfo.getUserId() == CrmIntegration && (ma.AKAM_Created_By__c =='' || 
          ma.AKAM_Created_Date__c == null ||ma.AKAM_System__c =='')) || UserInfo.getUserId() != CrmIntegration ) {
          ma.AKAM_Created_By__c = ma.AkaM_Alias__c ;
          ma.AKAM_Created_Date__c = system.now();
          ma.AKAM_System__c ='FORCE';
        }
      }      
    // This code bassically checks if any value of Akam modified is null for Insert or Updates it populates the default value
      if((UserInfo.getUserId() == CrmIntegration && (ma.AKAM_Modified_Date__c  == null|| 
        ma.AKAM_Modified_By__c == '' || ma.AKAM_Modified_By__c == null)) || UserInfo.getUserId() != CrmIntegration )  {
        ma.AKAM_Modified_By__c = ma.AkaM_Alias__c;
        ma.AKAM_Modified_Date__c =  system.now();  
      }
    }
  }       
}