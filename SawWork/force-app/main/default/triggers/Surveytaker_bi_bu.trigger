trigger Surveytaker_bi_bu on SurveyTaker__c (before insert , before update) {
    // Code for CR-2762535 : AKAM field updation Through The code
 if(Trigger.isBefore) {
     
    //18.7 getting the Id of CRM_Integration from Custom Meta Data instead of Custom Settings
    //Id CrmIntegration = Id.valueOf(GSM_Custom_Settings__c.getInstance('CRM_Integration').value__c);
    Id CrmIntegration = Id.valueOf(GsmUtilClass.getGSMSettingValue('CRM_Integration'));
     
    for(SurveyTaker__c st : Trigger.new){
      //This code takes care OF AKAM fields while insert if any of these field is null or Empty
      if(Trigger.isInsert){
        if((UserInfo.getUserId() == CrmIntegration && (st.AKAM_Created_By__c =='' || 
          st.AKAM_Created_Date__c == null ||st.AKAM_System__c =='')) || UserInfo.getUserId() != CrmIntegration ) {
          st.AKAM_Created_By__c = st.AKAM_Alias__c ;
          st.AKAM_Created_Date__c = system.now();
          st.AKAM_System__c ='FORCE';
        }
      }      
    // This code bassically checks if any value of Akam modified is null for Insert or Updates it populates the default value
      if((UserInfo.getUserId() == CrmIntegration && (st.AKAM_Modified_Date__c  == null|| 
        st.AKAM_Modified_By__c == '' || st.AKAM_Modified_By__c == null)) || UserInfo.getUserId() != CrmIntegration )  {
        st.AKAM_Modified_By__c = st.AKAM_Alias__c;
        st.AKAM_Modified_Date__c =  system.now();  
      }
    }
  }       
}