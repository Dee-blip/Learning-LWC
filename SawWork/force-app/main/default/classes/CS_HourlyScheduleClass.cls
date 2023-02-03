/*
Author: Sharath
Created: 1/27/2011
Description: Schedule the class CS_ScheduleSurveyResponseProcessing to run every one hour
CR 935416: Read the salesforce name value pair custom object to process the survey results & update contact's survey results summary fields
Modified for CR 1014942 - Reduce Processing time for the Scheduled Apex Job Contacts Update
*/
global class CS_HourlyScheduleClass
{
 global void CS_HourlyScheduleClass() {}
 public static String jobName = 'Scheduled Contact Update';
 
 public static void start()
 {
 //Seconds Minutes Hours Day_of_month Month Day_of_week optional_year
 // modified  by Sharath - 2/16/2011 - changed the schedule. job now runs every hour at 20 mins
 // CR 1014942 chnage - modified by Sharath - 4/11/2011 - changing schedule. job runs every hour at 45 mins
 System.schedule(jobName, '0 45 1-23 * * ?', new CS_ScheduleSurveyResponseProcessing());
 }
}