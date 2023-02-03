trigger CampaignTrigger_bi_bu on Campaign (Before insert, Before update) {

   // Code for CR 2762535: AKAM field updation Through The code 
    if(Trigger.isBefore) {
         User userObj = [Select id , alias, profileId From User Where Id =: UserInfo.getUserId()];
         Profile pr = [select Name from profile where Id =:userObj.ProfileId ]; 
         for(Campaign campObj : Trigger.new){
            If(Trigger.isInsert ) {  
              if(campObj.AKAM_Created_By__c =='' || campObj.AKAM_Created_Date__c  == null ||campObj.AKAM_System__c =='' ) {
                  campObj.AKAM_Created_By__c = userObj.alias ;
                  campObj.AKAM_Created_Date__c = system.now();
                  campObj.AKAM_System__c ='FORCE';
               }
               if(pr.Name != 'CRM Integration') {
                  If((campObj.AKAM_Modified_Date__c  == null)|| 
                     (campObj.AKAM_Modified_By__c == '' || campObj.AKAM_Modified_By__c == null))  {
                      campObj.AKAM_Modified_By__c = userObj.alias;
                      campObj.AKAM_Modified_Date__c =  system.now();                   
                      }
                  }
              }
              If(Trigger.isUpdate) {
                if(pr.Name != 'CRM Integration' && (campObj.AKAM_Modified_By__c == Trigger.oldMap.get(campObj.id).AKAM_Modified_By__c || 
                   Trigger.oldMap.get(campObj.id).AKAM_Modified_By__c == null) && (campObj.AKAM_Modified_Date__c == Trigger.oldMap.get(campObj.id).AKAM_Modified_Date__c || 
                   Trigger.oldMap.get(campObj.id).AKAM_Modified_Date__c == null) &&(campObj.LastModifiedBy != Trigger.oldMap.get(CampObj.id).lastModifiedBy) ) {
                   campObj.AKAM_Modified_By__c = userObj.alias;
                   campObj.AKAM_Modified_Date__c =  system.now();
                }
             }
         }
     }       

}