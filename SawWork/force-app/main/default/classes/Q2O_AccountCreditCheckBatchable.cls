/***
@author - Poojashri Rao
@Description : This class implements the Cron Job functionality.This Class picks all the Accounts that need Credit Check and Creates 
        Tasks for the same on daily Basis.

  Developer             Date               Description
  Sneha                 1 jun 2016         CR 3423541.Credit check status is showing up as 'null' in the comments section of the task generated to Collections team.
                                           added the field in query
    Sonali Tandon         30/6/2016      SFDC-1014 Task creation for Credit & Collections team - Added more conditions for credit check task creation

***/        
        




global class Q2O_AccountCreditCheckBatchable implements Database.Batchable<sObject> 
{
  Cron_Batch_Run__c parentCronBatchRun=null;
  List<String> stagesForCreditCheck; 
  String opportunityStageForAnnualCheck;  
  /**Boolean initialized=false;
  Set<Id> accountIds = new Set<Id>();
  String query ;
  List<Id> accIds = new List<Id>();**/

  global Q2O_AccountCreditCheckBatchable(Cron_Batch_Run__c pParentCronBatchRun)  
    {
      this.parentCronBatchRun = pParentCronBatchRun;
      String opportunityStages = [Select DeveloperName,Value__c from GSM_Settings__mdt where DeveloperName = 'Q2O_AccountCreditCheck_OpptyStages'].Value__c;
      if(opportunityStages != null)
      {
          stagesForCreditCheck = new List<String>();
          for(String stage : opportunityStages.split(','))
          stagesForCreditCheck.add(stage);   
      }   

      opportunityStageForAnnualCheck = [Select DeveloperName,Value__c from GSM_Settings__mdt where DeveloperName = 'Q2O_AccountCreditCheck_OpptyStagesAnnual'].Value__c;

      //this.initialized=doInitialize();
    }
    
  /**public Boolean doInitialize() 
  {  
   List<String> stagesForCreditCheck = new List<String> ();
   stagesForCreditCheck.add('3-Develop');
   stagesForCreditCheck.add('4-Prove');
   stagesForCreditCheck.add('5-Negotiate');
   //QTOO-2525 : Modifying the below query such that it creates Task irrespective of the Credit check Status(i.e, it need not be SEC DEP only). 
   for (Opportunity opp : [Select Id,AccountId from Opportunity where createdDate=LAST_N_DAYS:90 AND Account.Credit_Check_Date__c != LAST_N_DAYS:60 and Account.taskCreatedForCreditCheck__c = false and StageName IN :stagesForCreditCheck LIMIT 10000])
       accountIds.add(opp.AccountId);    
    accIds.addAll(accountIds);
    if(Test.isRunningTest())
    query='select Id,Name,taskCreatedForCreditCheck__c,Credit_Check_Status__c from Account where id IN :accIds and createdDate=LAST_N_DAYS:3 LIMIT 100';
    else
  query = 'select Id,Name,taskCreatedForCreditCheck__c,Credit_Check_Status__c from Account where id IN :accIds' ;  //new al.SoqlBuilder().selectx(new Set<Object> {'Id','Name','taskCreatedForCreditCheck__c'}).fromx('Account').wherex(new al.SetCondition('id').inx(new List<Id>(accountIds))).toSoql();
   return true;
  }**/
  
   global database.querylocator start(Database.BatchableContext BC)
    {  
      //SFDC-1245
        return Database.getQueryLocator([Select Id,AccountId,Account.taskCreatedForCreditCheck__c from Opportunity where Account.taskCreatedForCreditCheck__c = false AND (/*( StageName IN :stagesForCreditCheck   
   AND Account.Credit_Check_Status__c!= null AND createdDate=LAST_N_DAYS:90 AND Account.Credit_Check_Date__c != LAST_N_DAYS:60 ) OR*/
    (StageName >=: opportunityStageForAnnualCheck AND  Deal_Type__c = 'Direct' AND Partner_Involved__c=null AND Dollar_MRR__c >:Decimal.valueOf(GsmUtilClass.getGSMSettingValue('Opportunity_forecasted_MRR_Limit')) AND ForecastCategoryName = 'Commit' AND (CloseDate>TODAY AND CloseDate=NEXT_N_DAYS:61) AND  (NOT Account.Name LIKE '%Account Split%') AND (NOT Associated_Account_Vertical__c LIKE '%Internal%') AND (Account.Credit_Check_Date__c < LAST_N_DAYS:335 OR Account.Credit_Check_Date__c = null) AND
    (Account.Max_Invoice_Date__c < LAST_N_DAYS:335 OR Account.Max_Invoice_Date__c = null)))]);
    } 
   
   
  global void execute(Database.BatchableContext BC, List<sObject> scope)
  {
    List<Account> listOfAccountsToUpdate = new List<Account>();
    List<Account> listofAccountsToQuery  = new List<Account>();
    List<Task> taskList                  = new List<Task>();
    Set<Id> setOfAccountIds              = new Set<Id>();
   // String strErrorLog=null;
    //accList = scope;

    List<Opportunity> listOfOpportunities = (List<Opportunity>)scope;

    // Get list of Account Ids
    for(Opportunity oppty : listOfOpportunities)
      setOfAccountIds.add(oppty.AccountId);

    System.debug('setOfAccountIds' + setOfAccountIds);

     if(Test.isRunningTest())
        listofAccountsToQuery = [Select Id,Validation_Override__c,Name,taskCreatedForCreditCheck__c,Credit_Check_Status__c from Account where id IN :setOfAccountIds and createdDate=LAST_N_DAYS:3 LIMIT 100];
    else
        listofAccountsToQuery =[Select Id,Validation_Override__c,Name,taskCreatedForCreditCheck__c,Credit_Check_Status__c from Account where id IN :setOfAccountIds];
    
    System.debug('listofAccountsToQuery' + listofAccountsToQuery);

    for (Account acc : listofAccountsToQuery)
    {
        acc.taskCreatedForCreditCheck__c =true;
        acc.Validation_Override__c = true;
        Task tempTask = new Task();
        tempTask.OwnerId = Q2O_Custom_Settings__c.getInstance('CollectionUser').value__c;
        tempTask.Subject = 'Credit Check Needed';
        tempTask.WhatId = acc.Id;
        tempTask.Description =  Label.CreditCheckTaskDescriptionForBatch +acc.Credit_Check_Status__c + ' or ' + Label.CreditCheckTaskDescriptionForBatchAnnual ;
        taskList.add(tempTask);
        listOfAccountsToUpdate.add(acc);
    }
     System.debug('listOfAccountsToUpdate ::' + listOfAccountsToUpdate);
     Database.update(listOfAccountsToUpdate,false);
     if (taskList.size() > 0)
     {
     Database.SaveResult[] results  = Database.insert(taskList,false);
     String strErrorLog=null;
      Integer failedCount=0;
      Integer count=0;
      
      for(Database.SaveResult sr:results)
      {
         if(!sr.isSuccess())
         {
              strErrorLog+='\nFailed Record count:'+ ++failedCount;
                strErrorLog+='##getStatusCode:'+sr.getErrors()[0].getStatusCode();
                strErrorLog+='##getRecordId:'+ taskList[count].Id;
         }
         count++;
      }  
          
   String res='No. of Closed Tasks' + (count-failedcount);
     if (this.parentCronBatchRun!=null)        
      {  
          if (this.parentCronBatchRun!=null)
          this.parentCronBatchRun = [Select Id, Scheduled_to_Run__c, Cron_Batch_Job__c, Completed__c, Trigger_Batch_Run__c, Parent_Cron_Batch_Run__c,BatchProcessId__c,  
            Results__c, Result__c, Validation_Override__c from Cron_Batch_Run__c where BatchProcessId__c = : GSM_Custom_Settings__c.getInstance('CreditCheck#lastBatchProcessId').Value__c][0];
        

        Cron_Batch_Run__c cbr = new Cron_Batch_Run__c();
        cbr.Cron_Batch_Job__c = parentCronBatchRun.Cron_Batch_Job__c;
        cbr.Parent_Cron_Batch_Run__c = parentCronBatchRun.Id;
        cbr.Scheduled_to_Run__c = parentCronBatchRun.Scheduled_to_Run__c;
        
        if(strErrorLog!=null)
        {
          cbr.Result__c ='Error';
          res+=strErrorLog;
        }
        else
          cbr.Result__c = 'Success';
        
        // Trim the length of Result to ensure its less than 32K  
        if (res.length()>31990)
          res = res.substring(0,31900);   
        cbr.Results__c = res;
        cbr.Validation_Override__c=true;
        cbr.Trigger_Batch_Run__c = true;
        cbr.Completed__c = Datetime.now();
        insert cbr;
      }
        }  
  }
 
   global void finish(Database.BatchableContext BC)
    {   
         AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email
              FROM AsyncApexJob WHERE Id = :BC.getJobId()];
              
    if (this.parentCronBatchRun!=null)          
    {  
      Cron_Batch_Run__c cbr = [Select Id, Cron_Batch_Job__c, Completed__c, Trigger_Batch_Run__c, Parent_Cron_Batch_Run__c, 
        BatchProcessId__c, Results__c, Result__c, Validation_Override__c from Cron_Batch_Run__c where BatchProcessId__c =: GSM_Custom_Settings__c.getInstance('CreditCheck#lastBatchProcessId').Value__c][0];//BC.getJobId()][0];
      if (a.NumberOfErrors>0)
        cbr.Result__c ='Error';
      else
        cbr.Result__c = 'Success';
      cbr.Results__c = '\n BatchProcessId=' +BC.getJobId()+ '\n CustomSetting BatchProcessID='+ GSM_Custom_Settings__c.getInstance('CreditCheck#lastBatchProcessId').Value__c +'\nThe job processed ' + a.TotalJobItems + ' batches with '+ a.NumberOfErrors + ' failures.\n';
      cbr.Validation_Override__c=true;
      update cbr;
    }


     }
}