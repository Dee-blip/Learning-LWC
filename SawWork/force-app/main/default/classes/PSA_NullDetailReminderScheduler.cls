/* ========================================================================
    Author: Samir Jha
    Description: Class used for sending weekly email reminder to all Project owners 
    which have have "ONLY NULL" contract line items associated.                 
    Created Date : 01/04/2015
    ======================================================================== */
global class PSA_NullDetailReminderScheduler implements Schedulable{
global void execute(SchedulableContext sc) 
{
PSA_NotifyManagersOfNullDetail b = new PSA_NotifyManagersOfNullDetail(); 
database.executebatch(b);
}

}