/*
Author: Sharath
Created: 1/19/2011
Description: Scheduled Apex job which picks all contacts for Survey Response processing
CR 935416: Read the salesforce name value pair custom object to process the survey results & update contact's survey results summary fields
*/
global class CS_ScheduleSurveyResponseProcessing implements Schedulable
{
   global void execute(SchedulableContext sc) 
   {
        CS_UpdateContacts processResponses = new CS_UpdateContacts();
        processResponses.execute();
   }
}