trigger deployementStep_bi_bu on Deployment_Step__c (before insert, Before Update, after insert, after update) {
   //  Code By Rahul : AKAM field updation Through The code
  if(Trigger.isBefore) {
    Id CrmIntegration = Id.valueOf(GSM_Custom_Settings__c.getInstance('CRM_Integration').value__c);
    for(Deployment_Step__c tm : Trigger.new){
      //This code takes care OF AKAM fields while insert if any of these field is null or Empty
      if(Trigger.isInsert){
        if((UserInfo.getUserId() == CrmIntegration && (tm.AKAM_Created_By__c =='' || 
          tm.AKAM_Created_Date__c == null ||tm.AKAM_System__c =='')) || UserInfo.getUserId() != CrmIntegration ) {
          tm.AKAM_Created_By__c = tm.AKAM_Alias__c ;
          tm.AKAM_Created_Date__c = system.now();
          tm.AKAM_System__c ='FORCE';
        }
      }      
    // This code bassically checks if any value of Akam modified is null for Insert or Updates it populates the default value
      if((UserInfo.getUserId() == CrmIntegration && (tm.AKAM_Modified_Date__c  == null|| 
        tm.AKAM_Modified_By__c == '' || tm.AKAM_Modified_By__c == null)) || UserInfo.getUserId() != CrmIntegration )  {
        tm.AKAM_Modified_By__c = tm.AKAM_Alias__c;
        tm.AKAM_Modified_Date__c =  system.now();  
      }
    }
  }        
    if(Trigger.isAfter && Trigger.isUpdate) {
        for(Deployment_Step__c tm : Trigger.new){
          if((Trigger.oldMap.get(tm.id).QA_Deployed__c == false && tm.QA_Deployed__c == true) && tm.Number_of_QA_Deployed_manifests__c != tm.Number_of_manifests__c)
            tm.addError('QA Deployed cannot be marked until all manifests are deployed to QA');

        if((Trigger.oldMap.get(tm.id).Production_Deployed__c == false && tm.Production_Deployed__c == true) && tm.Number_of_Prod_Deployed_manifests__c != tm.Number_of_manifests__c)
            tm.addError('Prod Deployed cannot be marked until all manifests are deployed to production');    
        }
    }
}