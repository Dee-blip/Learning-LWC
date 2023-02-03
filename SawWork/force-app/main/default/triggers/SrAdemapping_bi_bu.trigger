trigger SrAdemapping_bi_bu on Sr_ADE_Mapping__c (before insert , Before Update) {
    //  Code By Rahul : AKAM field updation Through The code
  if(Trigger.isBefore) {
    Id CrmIntegration = Id.valueOf(GSM_Custom_Settings__c.getInstance('CRM_Integration').value__c);
    for(Sr_ADE_Mapping__c SrAde : Trigger.new){
      //This code takes care OF AKAM fields while insert if any of these field is null or Empty
      if(Trigger.isInsert){
        if((UserInfo.getUserId() == CrmIntegration && (SrAde.AKAM_Created_By__c =='' || 
          SrAde.AKAM_Created_Date__c == null ||SrAde.AKAM_System__c =='')) || UserInfo.getUserId() != CrmIntegration ) {
          SrAde.AKAM_Created_By__c = SrAde.AKAM_Alias__c ;
          SrAde.AKAM_Created_Date__c = system.now();
          SrAde.AKAM_System__c ='FORCE';
        }
      }      
    // This code bassically checks if any value of Akam modified is null for Insert or Updates it populates the default value
      if((UserInfo.getUserId() == CrmIntegration && (SrAde.AKAM_Modified_Date__c  == null|| 
        SrAde.AKAM_Modified_By__c == '' || SrAde.AKAM_Modified_By__c == null)) || UserInfo.getUserId() != CrmIntegration )  {
        SrAde.AKAM_Modified_By__c = SrAde.AKAM_Alias__c;
        SrAde.AKAM_Modified_Date__c =  system.now();  
      }
    }
  }       
}