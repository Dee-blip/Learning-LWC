trigger ebcRequest_bi_bu on EBC_Request__c (before Insert, Before update) {
  //  Code By Rahul : AKAM field updation Through The code
  if(Trigger.isBefore) {
    Id CrmIntegration = Id.valueOf(GsmUtilClass.getGSMSettingValue('CRM_Integration')); // SFDC-2705 Custom Settings Migration
    for(EBC_Request__c request : Trigger.new){
      //This code takes care OF AKAM fields while insert if any of these field is null or Empty
      if(Trigger.isInsert){
        if((UserInfo.getUserId() == CrmIntegration && (request.AKAM_Created_By__c =='' || 
          request.AKAM_Created_Date__c == null ||request.AKAM_System__c =='')) || UserInfo.getUserId() != CrmIntegration ) {
          request.AKAM_Created_By__c = request.AKAM_Alias__c ;
          request.AKAM_Created_Date__c = system.now();
          request.AKAM_System__c ='FORCE';
        }
      }      
    // This code bassically checks if any value of Akam modified is null for Insert or Updates it populates the default value
      if((UserInfo.getUserId() == CrmIntegration && (request.AKAM_Modified_Date__c  == null|| 
        request.AKAM_Modified_By__c == '' || request.AKAM_Modified_By__c == null)) || UserInfo.getUserId() != CrmIntegration )  {
        request.AKAM_Modified_By__c = request.AKAM_Alias__c;
        request.AKAM_Modified_Date__c =  system.now();  
      }
    }
  }       
}