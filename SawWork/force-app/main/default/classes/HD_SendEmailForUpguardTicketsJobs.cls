/*
*
*Template: Apex Class
*Version: 1.0
*@author: Nikhil Karn @ Akamai Technologies Ltd.
*Created Date : 13th March, 2018
*Purpose : an implementation to shedule email trigger if ticket count is more then specific number
*Number Of methods: 1
*Test Class Asssociated : HD_Test_SendEmailForUpguardTicketsJobs
*Controller (Boolean): False
*Page Used/Asssociated (default -> NONE) : NONE
*Trigger Associated : [ ]
*Class used : 
*@Last Modified By:
*/
global class HD_SendEmailForUpguardTicketsJobs implements Schedulable
{

	// This test runs a scheduled job at:

    global void execute(SchedulableContext sc) 
    {
            HD_SendEmailForUpguardTickets.runEmail();  
    }     
}