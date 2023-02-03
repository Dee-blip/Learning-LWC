/* ========================================================================
    Author: Sonia Sawhney
    Description: Class used for sceduling the batch job
    Created Date : 08/01/2013
    ======================================================================== */
global class scheduledAccountteamBatch implements Schedulable{
   global void execute(SchedulableContext sc) {
          BatchableAccountTeamMembers accountTeambatch = new BatchableAccountTeamMembers(); 
          database.executebatch(accountTeambatch);
   }
}