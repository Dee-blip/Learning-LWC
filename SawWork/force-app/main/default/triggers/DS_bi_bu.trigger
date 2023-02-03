trigger DS_bi_bu on dsfs__DocuSign_Recipient_Status__c ( before insert, Before Update) {
 //  Code By Rahul : AKAM field updation Through The code
  if(Trigger.isBefore) {
    Id CrmIntegration = Id.valueOf(GSM_Custom_Settings__c.getInstance('CRM_Integration').value__c);
    for(dsfs__DocuSign_Recipient_Status__c status : Trigger.new){
      //This code takes care OF AKAM fields while insert if any of these field is null or Empty
      if(Trigger.isInsert){
        if((UserInfo.getUserId() == CrmIntegration && (status.AKAM_Created_By__c =='' || 
          status.AKAM_Created_Date__c == null ||status.AKAM_System__c =='')) || UserInfo.getUserId() != CrmIntegration ) {
          status.AKAM_Created_By__c = status.AKAM_Alias__c ;
          status.AKAM_Created_Date__c = system.now();
          status.AKAM_System__c ='FORCE';
        }
      }      
    // This code bassically checks if any value of Akam modified is null for Insert or Updates it populates the default value
      if((UserInfo.getUserId() == CrmIntegration && (status.AKAM_Modified_Date__c  == null|| 
        status.AKAM_Modified_By__c == '' || status.AKAM_Modified_By__c == null)) || UserInfo.getUserId() != CrmIntegration )  {
        status.AKAM_Modified_By__c = status.AKAM_Alias__c;
        status.AKAM_Modified_Date__c =  system.now();  
      }
    }
  }       
}