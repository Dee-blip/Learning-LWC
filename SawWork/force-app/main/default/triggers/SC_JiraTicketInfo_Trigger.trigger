/*
 * CR: FFPSA-647
 * Developer: Sharath Prasanna
 * Enhancement: trigger for Content Document
 * Date: 21th August 2018
 * 
*/ 

trigger SC_JiraTicketInfo_Trigger on SC_Jira_Ticket_Info__c (before insert, 
before update, 
before delete, 
after insert, 
after update, 
after delete, 
after undelete) 
{
    if(!UserInfo.getName().equalsIgnoreCase('Connection User'))
    {
        ApexTriggerHandlerAbstractClass.createHandler('SC_Jira_Ticket_Info__c');
    }
}