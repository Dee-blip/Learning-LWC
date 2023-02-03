/* ========================================================================
    Author: Sonia Sawhney
    Description: Class used for sceduling the batch job
    Created Date : 08/12/2013
    ======================================================================== */
global class scheduledDeleteAccountteamBatch implements Schedulable{
   global void execute(SchedulableContext sc) {
          BatchableDeleteAccountTeamMembers accountTeambatch = new BatchableDeleteAccountTeamMembers(); 
          database.executebatch(accountTeambatch);
   }
}