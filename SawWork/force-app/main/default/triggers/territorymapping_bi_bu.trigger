trigger territorymapping_bi_bu on Territory_Mapping__c (before insert, before update) {
//  Code By Rahul : AKAM field updation Through The code
  if(Trigger.isBefore) {
    //Id CrmIntegration = Id.valueOf(GSM_Custom_Settings__c.getInstance('CRM_Integration').value__c); //SFDC-2304
    Id CrmIntegration = Id.valueOf(GsmUtilClass.getGSMSettingValue('CRM_Integration')); //SFDC-2304
    for(Territory_Mapping__c tm : Trigger.new){
      //This code takes care OF AKAM fields while insert if any of these field is null or Empty
      if(Trigger.isInsert){
        if((UserInfo.getUserId() == CrmIntegration && (tm.AKAM_Created_By__c =='' || 
          tm.AKAM_Created_Date__c == null ||tm.AKAM_System__c =='')) || UserInfo.getUserId() != CrmIntegration ) {
          tm.AKAM_Created_By__c = tm.AKAM_Alias__c ;
          tm.AKAM_Created_Date__c = system.now();
          tm.AKAM_System__c ='FORCE';
        }
      }      
    // This code bassically checks if any value of Akam modified is null for Insert or Updates it populates the default value
      if((UserInfo.getUserId() == CrmIntegration && (tm.AKAM_Modified_Date__c  == null|| 
        tm.AKAM_Modified_By__c == '' || tm.AKAM_Modified_By__c == null)) || UserInfo.getUserId() != CrmIntegration )  {
        tm.AKAM_Modified_By__c = tm.AKAM_Alias__c;
        tm.AKAM_Modified_Date__c =  system.now();  
      }
    }
  }       
}