/*
Author: Sharath
Created: 9/21/2010
Description: Scheduled Apex job which deletes tokens belonging to last week
CR 796377: Tokenizing Selection of Accounts in the Mailer Wizard process 
*/
global class EB_TokenDeletion implements Schedulable
{
   global void execute(SchedulableContext sc) 
   {
        List<EB_Token__c> tokensToBeDeleted = [select Id from EB_Token__c where LastModifiedDate >= LAST_WEEK limit 9500];
        delete tokensToBeDeleted;
   }
}