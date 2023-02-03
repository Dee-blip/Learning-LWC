/* ========================================================================
    Author: Denise Bacher (salesforce.com)
    Description: Class used for sceduling the batch job
    Created Date : 11/07/2013
    ======================================================================== */
global class scheduleDeleteCaseArticleBatch implements Schedulable{
   global void execute(SchedulableContext sc) {
          BatchableCaseArticleDelete caseArticleBatch = new BatchableCaseArticleDelete(); 
          database.executebatch(caseArticleBatch);
   }
}