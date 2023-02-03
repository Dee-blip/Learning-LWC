trigger Channel_Mapping_bi_bu on Channel_Mapping__c (before insert, before update) {
  
  List<Channel_Mapping__c> cms = new List<Channel_Mapping__c>();
  
  if(Trigger.isUpdate){
    if (!ChannelMappingTriggerClass.checkActiveOppsForCMInactivationFlag)
      return;
    for(Channel_Mapping__c cm : Trigger.new) {
      if(!cm.Active__c && Trigger.oldMap.get(cm.id).Active__c){
        cms.add(cm);
      }
    }
    
    if (!cms.isEmpty()){
      ChannelMappingTriggerClass.checkOpportunitiesBeforeChannelMappingInactivation(cms);
    }
  }
    //  Code By Rahul : AKAM field updation Through The code
  if(Trigger.isBefore) {
    Id CrmIntegration = Id.valueOf(GsmUtilClass.getGSMSettingValue('CRM_Integration')); //SFDC-2304
    for(Channel_Mapping__c cm : Trigger.new){
      //This code takes care OF AKAM fields while insert if any of these field is null or Empty
      if(Trigger.isInsert){
        if((UserInfo.getUserId() == CrmIntegration && (cm.AKAM_Created_By__c =='' || 
          cm.AKAM_Created_Date__c == null ||cm.AKAM_System__c =='')) || UserInfo.getUserId() != CrmIntegration ) {
          cm.AKAM_Created_By__c = cm.AKAM_Alias__c ;
          cm.AKAM_Created_Date__c = system.now();
          cm.AKAM_System__c ='FORCE';
        }
      }      
    // This code bassically checks if any value of Akam modified is null for Insert or Updates it populates the default value
      if((UserInfo.getUserId() == CrmIntegration && (cm.AKAM_Modified_Date__c  == null|| 
        cm.AKAM_Modified_By__c == '' || cm.AKAM_Modified_By__c == null)) || UserInfo.getUserId() != CrmIntegration )  {
        cm.AKAM_Modified_By__c = cm.AKAM_Alias__c;
        cm.AKAM_Modified_Date__c =  system.now();  
      }
    }
  }       
}