trigger ChannelAccPlan_bi_bu on SFDC_Channel_Account_Plan__c (before insert, before update) {
    //  Code By Rahul : AKAM field updation Through The code
  if(Trigger.isBefore) {
    Id CrmIntegration = Id.valueOf(GsmUtilClass.getGSMSettingValue('CRM_Integration'));
    //SFDC-5995, SFDC-6600
    //Map<Id, SFDC_Channel_Account_Plan__c> mapOfAccountIdVsPP = new Map<Id, SFDC_Channel_Account_Plan__c>();
    for(SFDC_Channel_Account_Plan__c AccountPlan : Trigger.new){
      //This code takes care OF AKAM fields while insert if any of these field is null or Empty
      if(Trigger.isInsert){
        if((UserInfo.getUserId() == CrmIntegration && (AccountPlan.AKAM_Created_By__c =='' || 
          AccountPlan.AKAM_Created_Date__c == null ||AccountPlan.AKAM_System__c =='')) || UserInfo.getUserId() != CrmIntegration ) {
          AccountPlan.AKAM_Created_By__c = AccountPlan.AKAM_Alias__c ;
          AccountPlan.AKAM_Created_Date__c = system.now();
          AccountPlan.AKAM_System__c ='FORCE';
        }

        //SFDC-5995, SFDC-6600
        //if(AccountPlan.Partner_Account__c != null) {
        //    mapOfAccountIdVsPP.put(AccountPlan.Partner_Account__c, AccountPlan);
        //}
      }      
    // This code bassically checks if any value of Akam modified is null for Insert or Updates it populates the default value
      if((UserInfo.getUserId() == CrmIntegration && (AccountPlan.AKAM_Modified_Date__c  == null|| 
        AccountPlan.AKAM_Modified_By__c == '' || AccountPlan.AKAM_Modified_By__c == null)) || UserInfo.getUserId() != CrmIntegration )  {
        AccountPlan.AKAM_Modified_By__c = AccountPlan.AKAM_Alias__c;
        AccountPlan.AKAM_Modified_Date__c =  system.now();  
      }
    }
    //SFDC-5995, SFDC-6600
    //if(!mapOfAccountIdVsPP.isEmpty()) {
    //    PartnerMarketingClass.copyOverDefaultMDFCurrencyToPartnerMDFObjects(mapOfAccountIdVsPP, 'SFDC_Channel_Account_Plan__c');
    //}
  }       
}