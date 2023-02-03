/*
Template: Apex Class/Trigger Template

CopyRight: Hemant Kumar @ Akamai Technologies Ltd.

Version: 1.0

Created Date : 29-jun-2015

Base Line : used as apart of requirment for RF incident periodic email updates

Purpose : an implementation for periodic Email Updated batch apex
          
Usage : used as an implementation for the periodic email based on status
          
Test Class Asssociated : 

Controller (Boolean): False

Page Used/Asssociated (default -> NONE) : NONE

Class Associated : 

Custom settings : HD_TicketStatusAlert @ this class exclusivly uses the custome setting for batch job processing

To run the apex in scheduled manner :
***************************************
HD_TicketStatusAlert m = new HD_TicketStatusAlert();
String sch = '0 30 * * * ?'; //every 30 min
String jobID = system.schedule('HD Ticket Status', sch, m);          
*/
global class HD_TicketStatusAlert implements Schedulable {

global void execute(SchedulableContext SC)
{
	HD_TicketStatusAlert_batchapex ticketbatch = new HD_TicketStatusAlert_batchapex(false);
	ID batchprocessid = database.executebatch(ticketbatch);
	AsyncApexJob aaj = [SELECT Id, Status, JobItemsProcessed, TotalJobItems, NumberOfErrors  FROM AsyncApexJob WHERE ID =: batchprocessid ];

}//


}//global class HD_TicketStatusAlert implements Schedulable