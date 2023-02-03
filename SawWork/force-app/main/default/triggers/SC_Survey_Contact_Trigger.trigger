/*
Author          : Sheena
Description     : Trigger on Survey Contacts
Test Class      : SC_AMG_Customer_Survey_Test

Date                Developer                   JIRA #                 Description                                                       
---------------------------------------------------------------------------------------------------------------------------------------------------
15 Nov 2021         Sheena               		ESESP-5143             Initial Version
---------------------------------------------------------------------------------------------------------------------------------------------------

*/
trigger SC_Survey_Contact_Trigger on CS_Survey_Contact__c (after update) {
    if(Trigger.isUpdate && Trigger.isAfter){
        Set<Id> caseIds = new Set<Id>();
        List<Case> surveyedCases = new List<Case>();
        List<Contact> surveyedContacts = new List<Contact>();
        for(CS_Survey_Contact__c surveyContact: Trigger.new){
            if(surveyContact.Qualtrics_Survey_Notification_Sent__c != Trigger.oldMap.get(surveyContact.Id).Qualtrics_Survey_Notification_Sent__c && surveyContact.Qualtrics_Survey_Notification_Sent__c){
                Case cs = new Case(Id=surveyContact.CS_Case__c);
                if(!surveyedCases.toString().contains(cs.Id)){
                    cs.Qualtrics_Survey_Notification_Sent__c = true;
                    cs.Internal_Case_Survey_Enabled__c = false;
                    cs.Validation_Override__c = true;
                    surveyedCases.add(cs);
                }
                Contact con = new Contact(Id=surveyContact.CS_Contact_Name__c);
                con.Last_Time_Contact_Surveyed__c= system.now();
                surveyedContacts.add(con);
                
                
            }
        }
        
        try{
            if(!surveyedCases.isEmpty()){
                update surveyedCases;
                
            }
            if(!surveyedContacts.isEmpty()){
                update surveyedContacts;
            }
        }
        catch(exception e){
            system.debug('exception while updating surveyed case://'+ e.getMessage());
        }
    }
}