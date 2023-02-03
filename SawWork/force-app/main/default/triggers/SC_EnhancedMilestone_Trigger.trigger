/*
Author          : Vamsee S
Description     : Trigger on Enhanced_Milestone__c
Test Class		: 

Date                Developer              JIRA #                 Description                                                       
------------------------------------------------------------------------------------------------------------------
03 May 2021       	Vamsee               ESESP-4735             Initial Version
------------------------------------------------------------------------------------------------------------------
*/
trigger SC_EnhancedMilestone_Trigger on Enhanced_Milestone__c (Before Delete) {
	if(Trigger.isDelete && Trigger.isBefore){
        if(UserInfo.getName() != 'CRM Ops'){
            for(Enhanced_Milestone__c eachRecord : trigger.old){
                eachRecord.addError('Enhanced Milestone Records cannot be deleted');
            }
        }
    }
}