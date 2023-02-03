/*
Author          : Sharath Prasanna
Description     : Trigger for AccountContactRelation Trigger - User for jarvis account permissioning

Date                    Developer                   JIRA #                      Description                                                       
------------------------------------------------------------------------------------------------------------------
09 Feb 2021             Authors                                           JARVIS Initial Development
------------------------------------------------------------------------------------------------------------------
*/
trigger AccountContactRelationTrigger on AccountContactRelation (before insert, 
before update, 
before delete, 
after insert, 
after update, 
after delete, 
after undelete)  
{
    if(Trigger.isInsert && trigger.isBefore)
    {
        for(AccountContactRelation contactRec: Trigger.New)
        {
            if(contactRec.Application__c != 'JARVIS' && contactRec.isActive)
            {
                contactRec.isActive = false;
            }
            if(contactRec.AKAM_Account_Contact_Id__c == null && contactRec.Akam_Account_Id__c != null 
            && contactRec.Akam_Contact_Id__c != null)
            {
                contactRec.AKAM_Account_Contact_Id__c = contactRec.Akam_Account_Id__c + 
                contactRec.Akam_Contact_Id__c;
            }            
        }

    }

}