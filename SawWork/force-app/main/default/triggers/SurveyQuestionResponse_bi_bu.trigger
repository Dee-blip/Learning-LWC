trigger SurveyQuestionResponse_bi_bu on SurveyQuestionResponse__c (before insert , before update) {
     // Code for CR-2762535 : AKAM field updation Through The code
   if(Trigger.isBefore) {
    Id CrmIntegration = Id.valueOf(GSM_Custom_Settings__c.getInstance('CRM_Integration').value__c);
    for(SurveyQuestionResponse__c sqr : Trigger.new){
      //This code takes care OF AKAM fields while insert if any of these field is null or Empty
      if(Trigger.isInsert){
        if((UserInfo.getUserId() == CrmIntegration && (sqr.AKAM_Created_By__c =='' || 
          sqr.AKAM_Created_Date__c == null ||sqr.AKAM_System__c =='')) || UserInfo.getUserId() != CrmIntegration ) {
          sqr.AKAM_Created_By__c = sqr.AKAM_Alias__c ;
          sqr.AKAM_Created_Date__c = system.now();
          sqr.AKAM_System__c ='FORCE';
        }
      }      
    // This code bassically checks if any value of Akam modified is null for Insert or Updates it populates the default value
      if((UserInfo.getUserId() == CrmIntegration && (sqr.AKAM_Modified_Date__c  == null|| 
        sqr.AKAM_Modified_By__c == '' || sqr.AKAM_Modified_By__c == null)) || UserInfo.getUserId() != CrmIntegration )  {
        sqr.AKAM_Modified_By__c = sqr.AKAM_Alias__c;
        sqr.AKAM_Modified_Date__c =  system.now();  
      }
    }
  }       
}