/**
 * =========================
 * Developer        Date        Description
 * --------------------------------------------------------------------------------------------------
 * Ali Khan       14/Mar/12   Created this trigger to stamp SF Reminder & SF QA Reminder Data time fields to fire at specific datetime.
                CR 1565005 Release Object - Email alerts changes
*/
trigger Release_bi_bu on Release__c (before insert, before update) 
{ 
  List<Release__c> toUpdateReminderDateList = new List<Release__c>();
  for (Release__c rel : Trigger.new) 
  {
    // if either QA Release Date or PROD Release Date changes, trigger reminderDate update.
    if (Trigger.isInsert || rel.Release_Date__c!=null && rel.Release_Date__c!= Trigger.oldMap.get(rel.Id).Release_Date__c || 
        rel.QA_Release_Date__c!=null && rel.QA_Release_Date__c!= Trigger.oldMap.get(rel.Id).QA_Release_Date__c)
          toUpdateReminderDateList.add(rel);
  }
  if (toUpdateReminderDateList.size()>0)
  {
    ReleaseTriggerClass relTrigger = new ReleaseTriggerClass();
      relTrigger.updateReminderDates(toUpdateReminderDateList);
  }
//  Code By Rahul : AKAM field updation Through The code
    if(Trigger.isBefore) {
    Id CrmIntegration = Id.valueOf(GSM_Custom_Settings__c.getInstance('CRM_Integration').value__c);
    for(Release__c release : Trigger.new){
      //This code takes care OF AKAM fields while insert if any of these field is null or Empty
      if(Trigger.isInsert){
        if((UserInfo.getUserId() == CrmIntegration && (release.AKAM_Created_By__c =='' || 
          release.AKAM_Created_Date__c == null ||release.AKAM_System__c =='')) || UserInfo.getUserId() != CrmIntegration ) {
          release.AKAM_Created_By__c = release.AKAM_Alias__c ;
          release.AKAM_Created_Date__c = system.now();
          release.AKAM_System__c ='FORCE';
        }
      }      
    // This code bassically checks if any value of Akam modified is null for Insert or Updates it populates the default value
      if((UserInfo.getUserId() == CrmIntegration && (release.AKAM_Modified_Date__c  == null|| 
        release.AKAM_Modified_By__c == '' || release.AKAM_Modified_By__c == null)) || UserInfo.getUserId() != CrmIntegration )  {
        release.AKAM_Modified_By__c = release.AKAM_Alias__c;
        release.AKAM_Modified_Date__c =  system.now();  
      }
    }
  }       
}