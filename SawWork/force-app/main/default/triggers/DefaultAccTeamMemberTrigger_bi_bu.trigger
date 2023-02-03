trigger DefaultAccTeamMemberTrigger_bi_bu on Default_Account_Team_Members__c (Before insert, before update) {

//  Code By Rahul : AKAM field updation Through The code
  if(Trigger.isBefore) {
    //Id CrmIntegration = Id.valueOf(GSM_Custom_Settings__c.getInstance('CRM_Integration').value__c); //SFDC-2304
    Id CrmIntegration = Id.valueOf(GsmUtilClass.getGSMSettingValue('CRM_Integration')); //SFDC-2304
    for(Default_Account_Team_Members__c datm : Trigger.new){
      //This code takes care OF AKAM fields while insert if any of these field is null or Empty
      if(Trigger.isInsert){
        if((UserInfo.getUserId() == CrmIntegration && (datm.AKAM_Created_By__c =='' || 
          datm.AKAM_Created_Date__c == null ||datm.AKAM_System__c =='')) || UserInfo.getUserId() != CrmIntegration ) {
          datm.AKAM_Created_By__c = datm.AKAM_Alias__c ;
          datm.AKAM_Created_Date__c = system.now();
          datm.AKAM_System__c ='FORCE';
        }
      }      
    // This code bassically checks if any value of Akam modified is null for Insert or Updates it populates the default value
      if((UserInfo.getUserId() == CrmIntegration && (datm.AKAM_Modified_Date__c  == null|| 
        datm.AKAM_Modified_By__c == '' || datm.AKAM_Modified_By__c == null)) || UserInfo.getUserId() != CrmIntegration )  {
        datm.AKAM_Modified_By__c = datm.AKAM_Alias__c;
        datm.AKAM_Modified_Date__c =  system.now();  
      }
    }
  }       
}