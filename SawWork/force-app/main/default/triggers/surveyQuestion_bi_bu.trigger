trigger surveyQuestion_bi_bu on Survey_Question__c (before insert, before update) {
//  Code By Rahul : AKAM field updation Through The code
  if(Trigger.isBefore) {
    Id CrmIntegration = Id.valueOf(GSM_Custom_Settings__c.getInstance('CRM_Integration').value__c);
    for(Survey_Question__c sq : Trigger.new){
      //This code takes care OF AKAM fields while insert if any of these field is null or Empty
      if(Trigger.isInsert){
        if((UserInfo.getUserId() == CrmIntegration && (sq.AKAM_Created_By__c =='' || 
          sq.AKAM_Created_Date__c == null ||sq.AKAM_System__c =='')) || UserInfo.getUserId() != CrmIntegration ) {
          sq.AKAM_Created_By__c = sq.AKAM_Alias__c ;
          sq.AKAM_Created_Date__c = system.now();
          sq.AKAM_System__c ='FORCE';
        }
      }      
    // This code bassically checks if any value of Akam modified is null for Insert or Updates it populates the default value
      if((UserInfo.getUserId() == CrmIntegration && (sq.AKAM_Modified_Date__c  == null|| 
        sq.AKAM_Modified_By__c == '' || sq.AKAM_Modified_By__c == null)) || UserInfo.getUserId() != CrmIntegration )  {
        sq.AKAM_Modified_By__c = sq.AKAM_Alias__c;
        sq.AKAM_Modified_Date__c =  system.now();  
      }
    }
  }       
}