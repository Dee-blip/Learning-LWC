trigger fundbudgetAllocation_bi_bu on Budget_Allocation__c (before insert , Before update) {
 //  Code By Rahul : AKAM field updation Through The code
  if(Trigger.isBefore) {
    Id CrmIntegration = Id.valueOf(GSMSettings.getValue('CRM_Integration'));

    for(Budget_Allocation__c budget : Trigger.new){
      //This code takes care OF AKAM fields while insert if any of these field is null or Empty
      if(Trigger.isInsert){
        if((UserInfo.getUserId() == CrmIntegration && (budget.AKAM_Created_By__c =='' || 
          budget.AKAM_Created_Date__c == null ||budget.AKAM_System__c =='')) || UserInfo.getUserId() != CrmIntegration ) {
          budget.AKAM_Created_By__c = budget.AKAM_Alias__c ;
          budget.AKAM_Created_Date__c = system.now();
          budget.AKAM_System__c ='FORCE';
        }
      }      
    // This code bassically checks if any value of Akam modified is null for Insert or Updates it populates the default value
      if((UserInfo.getUserId() == CrmIntegration && (budget.AKAM_Modified_Date__c  == null|| 
        budget.AKAM_Modified_By__c == '' || budget.AKAM_Modified_By__c == null)) || UserInfo.getUserId() != CrmIntegration )  {
        budget.AKAM_Modified_By__c = budget.AKAM_Alias__c;
        budget.AKAM_Modified_Date__c =  system.now();  
      }
    }
  }       
}