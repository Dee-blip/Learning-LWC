/* ========================================================================
    Author: Sonia Sawhney
    Description: Class used for sceduling the batch job for data cleanup
    Created Date : 08/12/2013
    ======================================================================== */
global class ScheduleDeleteRecords implements Schedulable{
   global void execute(SchedulableContext sc) {
          BatchableDeleteRecords deleteRecords = new BatchableDeleteRecords(); 
          database.executebatch(deleteRecords);
   }
}