trigger Fund_Budget_bi_bu on SFDC_Budget__c (before insert, before update) {
  list<SFDC_Budget__c> ValidateCurrencyList=new list<SFDC_Budget__c>();
  for(SFDC_Budget__c fb : Trigger.new)
      {
        if(Trigger.isInsert)
        {
          //CR 2423532 - Removed Validation override in the next line to ensure currency check is done for all Fund Budgets
          if(fb.Account__c!=null)
          ValidateCurrencyList.add(fb);
        }
      }
      if(ValidateCurrencyList.size()>0)
      PRM_opportunity.ValidateFundBudgetCurrency(ValidateCurrencyList);

        
//  Code By Rahul : AKAM field updation Through The code
  if(Trigger.isBefore) {
    Id CrmIntegration = Id.valueOf(GsmUtilClass.getGSMSettingValue('CRM_Integration')); //SFDC-2304
    for(SFDC_Budget__c budget : Trigger.new){
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