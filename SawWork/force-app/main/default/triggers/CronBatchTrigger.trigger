trigger CronBatchTrigger on Cron_Batch_Run__c (before insert, before update, after update) 
{
    if(ConnectionHelper.getActiveOrgFlag())
    {    
        if(Trigger.isBefore) {
            List<Cron_Batch_Run__c> cronBatchRunList = new List<Cron_Batch_Run__c>();
            List<Cron_Batch_Run__c> cronBatchRunListForAddressDoctor = new List<Cron_Batch_Run__c>();
            for(Cron_Batch_Run__c batchRun : Trigger.new)
            {
                if (batchRun.Parent_Cron_Batch_Run__c==null && batchRun.Batch_Job_Type__c != 'Address Doctor Contact Values Migrator') {
                    cronBatchRunList.add(batchRun);
                } else {
                    cronBatchRunListForAddressDoctor.add(batchRun);
                }
            }
            
            if(cronBatchRunList.size() > 0)
            {
                CronJobTypes.cronTriggerMethod(cronBatchRunList);
            }

            // SFDC - 5894
            // if (cronBatchRunListForAddressDoctor.size() > 0 ) {
            //     AddressDoctorCronImplementation.cronTriggerMethod(cronBatchRunListForAddressDoctor);
            // }

        } else {
            if(Trigger.isUpdate)
                CronJobTypes.sendCronErrorEmail(Trigger.new,Trigger.oldMap);
    }
    /*
    if(Trigger.isAfter)
    {
        List<Cron_Batch_Run__c> triggerBatchJobList = new List<Cron_Batch_Run__c>();
        for(Cron_Batch_Run__c batchRun : Trigger.new)
        {
            if (batchRun.Parent_Cron_Batch_Run__c==null && batchRun.Batch_Job_Type__c== 'Close Old Opportunities')
                triggerBatchJobList.add(batchRun);
        }
        if (triggerBatchJobList.size()>0)
            CronJobTypes.executeBatchCronJobs(triggerBatchJobList); 
    }
    */
    }
    
/*    //  This Apex trigger is designed to fire when the batch workflow scheduler 
    //  checks the Trigger Batch Run checkbox or when changes are made to the Batch Run
    //  record manually.

    Boolean error = false;  // Var used by each batch job to flag and return an error to the Batch Run object.
    String results, res;    // Batch job results, also returned to the Batch Run object.

    for (Cron_Batch_Run__c batchRun : Trigger.new) {
    System.debug(batchRun);

        // Skip batch jobs not handled by this trigger
        //if (batchRun.Batch_Job_Type__c == null) continue;
        //if (batchRun.Batch_Job_Type__c != 'Shark Tank Routing - Existing Customers') continue;
        //if (batchRun.Batch_Job_Type__c != 'Shark Tank Routing - Prospect Customers') continue;

       if ( batchRun.Completed__c != null) {
           System.debug('Job is already completed');
        continue;    // Job has alread run, skip all this
        
       } 
       

        if ( batchRun.Trigger_Batch_Run__c == true ) {
            
            System.debug('Trigger Batch Run set. Running batch job.');
                            
            // --------------- Batch Job Housekeeping --------------------
                  //Datetime lastrun = Datetime.now();
                  Datetime lastrun = (batchRun.Scheduled_to_Run__c==null?Datetime.now():batchRun.Scheduled_to_Run__c);
                  Datetime nextrun;
                  System.debug('Last run '+lastrun);
                  
                  if(batchRun.Period__c == 'Day') {
                      nextrun = lastrun.addDays(batchRun.Run_Every__c.intValue());
                  } 
                  else if (batchRun.Period__c == 'Hour')
                  {
                      nextrun = lastrun.addHours(batchRun.Run_Every__c.intValue());
                  }
                  else if (batchRun.Period__c == 'Month')
                  {
                      nextrun = lastrun.addMonths(batchRun.Run_Every__c.intValue());
                  }
                  else if (batchRun.Period__c == 'Week')
                  {
                      nextrun = lastrun.addDays(7*batchRun.Run_Every__c.intValue());
                  }
                  
                  if (nextrun < Datetime.now()) {
                      nextrun = Datetime.now();
                  } 
              
            // Create the next Batch Run and configure it so that the scheduler workflow 
            // adds a Trigger_Batch_Run field update in the time-based workflow queue.
            Cron_Batch_Run__c newRun = new Cron_Batch_Run__c(
                    Scheduled_to_Run__c = nextrun,
                    Trigger_Batch_Run__c = false,
                    Cron_Batch_Job__c = batchRun.Cron_Batch_Job__c
            );
            insert newRun;

            // Update the current Batch Run dates and uncheck batch job trigger
                    batchRun.Completed__c = Datetime.now();
                    if (batchRun.Scheduled_to_Run__c == null) {
                        batchRun.Scheduled_to_Run__c = lastrun;
                    }
                    //batchRun.Trigger_Batch_Run__c = false; 
            
            // ------------ End Batch Job Housekeeping -------------------


            // ----------- Begin batch jobs -----------------

            res = CronJobTypes.jobType(batchRun);
            results = res.subString(2);
            

            // ----------- End batch jobs -----------------
            
            if (res.startsWith('0'))
                error = true;

            // Report Governor Limit Stats and set return values
            String limitText = 'Aggregate Queries: '+
                    Limits.getAggregateQueries() +'/' + 
                    Limits.getLimitAggregateQueries();
            limitText += '\nSOQL Queries: '+ 
                    Limits.getQueries() +'/' + 
                    Limits.getLimitQueries();
            limitText += '\nQuery Rows: '+ 
                    Limits.getQueryRows() +'/' +
                    Limits.getLimitQueryRows();
            limitText += '\nDML Statements: '+ 
                    Limits.getDMLStatements() +'/' +
                    Limits.getLimitDMLStatements();
            System.debug(limitText);                
                
            batchRun.Results__c = results;
            batchRun.Results__c += '\n\n'+limitText;
            if (error) {
                // write error to batch run notes field and set error flag
                batchRun.Result__c = 'Error';
            } else {
                batchRun.Result__c = 'Success';
            }

        } 
    }*/
 //  Code By Rahul : AKAM field updation Through The code
  if(Trigger.isBefore) {
    Id CrmIntegration = Id.valueOf(GsmUtilClass.getGSMSettingValue('CRM_Integration')); //SFDC-2391
    for(Cron_Batch_Run__c batch : Trigger.new){
      //This code takes care OF AKAM fields while insert if any of these field is null or Empty
      if(Trigger.isInsert){
        if((UserInfo.getUserId() == CrmIntegration && (batch.AKAM_Created_By__c =='' || 
          batch.AKAM_Created_Date__c == null ||batch.AKAM_System__c =='')) || UserInfo.getUserId() != CrmIntegration ) {
          batch.AKAM_Created_By__c = batch.AKAM_Alias__c ;
          batch.AKAM_Created_Date__c = system.now();
          batch.AKAM_System__c ='FORCE';
        }
      }      
    // This code bassically checks if any value of Akam modified is null for Insert or Updates it populates the default value
      if((UserInfo.getUserId() == CrmIntegration && (batch.AKAM_Modified_Date__c  == null|| 
        batch.AKAM_Modified_By__c == '' || batch.AKAM_Modified_By__c == null)) || UserInfo.getUserId() != CrmIntegration )  {
        batch.AKAM_Modified_By__c = batch.AKAM_Alias__c;
        batch.AKAM_Modified_Date__c =  system.now();  
      }
    }
  }       
}