/**
@CreatedBy : Aayushi Agrawal
@CreatedDate : 12 May , 2020
@Purpose : SForce - 62 , To simplify the batch job and queueable job framework using a custom object
*/
//extends JobQueueSchedulerFrameworkInterface
global class JobQueueSchedulerFramework  extends JobQueueSchedulerFrameworkInterface{
    public static String jobStatusQueued = 'Queued';
    public static String jobStatusFailed = 'Failed';
    public static String jobTypeBatch = 'Batch';
    public static String jobTypeQueueable = 'Queueable';
    public static String jobTypeCallable = 'Callable';
    public static Integer MAX_BATCHLIMIT = 100;
    public static Integer MAX_RETRY_COUNT = 10;
    public static String SchedulerName = 'JobQueueSchedulerFramework';
    public static Set<String> apexClassList = new Set<String>();
    public static String jobIdToToRunImmediately;
    public static List<Job_Scheduler__c> lstJobQueueToUpdate = new List<Job_Scheduler__c>();
    public static List<Job_Run__c> jobDetailsToInsert = new List<Job_Run__c>();
        

    /*
    * execute method which will get called on scheduling the main class
    */
    global void execute(SchedulableContext sc ){

        collectJobInfo(lstJobQueueToUpdate);//collect job details in case of both success and error
        saveJobQueueSchedulerRecords(lstJobQueueToUpdate); // save collected info
        executeBatchJobs(lstJobQueueToUpdate, jobDetailsToInsert); //start Batch Jobs
        executeQueueableJobs(lstJobQueueToUpdate , jobDetailsToInsert); // start Queueable Job
        executeCallableMethods(lstJobQueueToUpdate , jobDetailsToInsert); // execute callable methods
        saveJobQueueSchedulerRecords(lstJobQueueToUpdate); // save JobQueue records with all details

        
    }//end of execute method

    /**
    * governor limit left for DML operations
    */
    private static Integer getAvailableDMLLimit(){
        return Limits.getLimitDMLRows() - Limits.getDmlRows();
    }//end of getAvailableDMLLimit Method

    /**
    * governor limit left for Queuable Apex
    */
    private static Integer availableQueueableLimit(){
        //return 2;
        return Limits.getLimitQueueableJobs() - Limits.getQueueableJobs() ;
    }//END of availableQueueableLimit Method

    /**
    * Process all batch jobs added in custom object : Job_Scheduler__c
    */
    private static void executeBatchJobs(List<Job_Scheduler__c > lstJobQueueToUpdate, List<Job_Run__c> jobDetailsToInsert){ 
        //check for available limit for batch run
        Integer availableLimit = MAX_BATCHLIMIT;
        
        List<AsyncApexJob> runningJobs = [SELECT ID ,ApexClass.Name FROM AsyncApexJob WHERE Status = 'Holding'
                                        ];
        availableLimit = availableLimit - runningJobs.size();
        //Splitting the limit of 100 withing batch and queue
        if(availableLimit > 50 ){
            availableLimit = 50;
        }                             
        if(availableLimit > 0){
            //Query on Batch Scheduler Object to get batches in queue
            List<Job_Scheduler__c> batchList = getPendingJobs(jobTypeBatch , availableLimit);
            markJobForNextRun(jobTypeBatch,batchList,jobDetailsToInsert);
            //execute batch here
            if(!batchList.isEmpty()){
                jobDetailsToInsert.clear();
                /*for(Job_Scheduler__c  scheduler : batchList){
                    jobDetailsToInsert.add(createJobQueueDetailRec(scheduler.id, 'Holding', scheduler.Class_Name__c));
                }//end of for    
                if(!jobDetailsToInsert.isEmpty()){
                    insert jobDetailsToInsert;

                }//end of if*/
                for(Job_Scheduler__c  scheduler : batchList){ 
                    Job_Run__c jobRunRec = createJobQueueDetailRec(scheduler.id, 'Holding', scheduler.Class_Name__c);

                    try{
                        
                        scheduler.Status__c = 'In Progress'; 
                        if(jobIdToToRunImmediately != null){
                        scheduler.Run_Job_Immediately__c = false;
                        }else{
                        calculateNextRun(scheduler,false);
                        }
                        Type t = Type.forName(scheduler.Class_Name__c);
                        
                        
                        Database.batchable<sObject> b = (Database.batchable<sObject>)t.newInstance();
                        scheduler.Job_Id__c = Database.executeBatch(b, Integer.valueOf(scheduler.Batch_Size__c));
                        jobRunRec.Job_Id__c =  scheduler.Job_Id__c;
                        }catch(Exception e){
                        scheduler.status__c = 'Failed'; 
                        scheduler.Retry__c = true;
                        jobRunRec.Error_Message__c =  e.getMessage()+'\n'+e.getStackTraceString();
                        jobRunRec.status__c = 'Failed';
                        
                    }//END of catch Block
                    jobDetailsToInsert.add(jobRunRec);
                    lstJobQueueToUpdate.add(scheduler);
                }//END of for(Job_Scheduler__c  q : batchList)
                if(!jobDetailsToInsert.isEmpty()){
                    insert jobDetailsToInsert;

                }//end of if*/
            }//END of if(!batchList.isEmpty()) 
        }//END of if(availableLimit > 0)                
    }//END of Method : executeBatchJobs

    /**
    * Process all queueable jobs added in custom object : Job_Scheduler__c
    */
    private  static void executeQueueableJobs(List<Job_Scheduler__c> lstJobQueueToUpdate, List<Job_Run__c> jobDetailsToInsert){
        Integer availableLimit = availableQueueableLimit() ;
        if(availableLimit > 0 ){
            List<Job_Scheduler__c> queueableList = getPendingJobs(jobTypeQueueable , availableLimit);
            markJobForNextRun(jobTypeQueueable,queueableList,jobDetailsToInsert);
            //Enqueue jobs here
            if(!queueableList.isEmpty()){
                jobDetailsToInsert.clear();
                /*for(Job_Scheduler__c  scheduler : queueableList){
                    jobDetailsToInsert.add(createJobQueueDetailRec(scheduler.id, 'Holding', scheduler.Class_Name__c));
                }//end of for    
                if(!jobDetailsToInsert.isEmpty()){
                    insert jobDetailsToInsert;

                }//end of if*/
               
               
                for(Job_Scheduler__c  scheduler : queueableList){ 
                    Job_Run__c jobRunRec = createJobQueueDetailRec(scheduler.id, 'Completed', scheduler.Class_Name__c);

                    try{
                        scheduler.Status__c = 'In Progress'; 
                        if(jobIdToToRunImmediately != null){
                        scheduler.Run_Job_Immediately__c = false;
                        }
                        else{
                        calculateNextRun(scheduler,false);
                        }
                        Type t = Type.forName(scheduler.Class_Name__c);
                        
                        if(scheduler.next_run__c != null && scheduler.next_run__c > System.now()){
                            scheduler.Status__c = 'Queued';
                        }else{
                            scheduler.Status__c = 'Completed';
                        }
                        scheduler.Job_Id__c = System.enqueueJob((Queueable )t.newInstance()); 
                        jobRunRec.Job_Id__c =  scheduler.Job_Id__c;
                        
                        }catch(Exception e){ 
                        scheduler.Status__c = 'Failed';
                        scheduler.Retry__c = true;
                        jobRunRec.Error_Message__c =  e.getMessage()+'\n'+e.getStackTraceString();
                        jobRunRec.status__c = 'Failed';
                    }//END of Catch Block  
                    jobDetailsToInsert.add(jobRunRec);
                    lstJobQueueToUpdate.add(scheduler);
                }//END of for(Job_Scheduler__c  q : queueableList)
                if(!jobDetailsToInsert.isEmpty()){
                    insert jobDetailsToInsert;

                }//end of if*/
            }//END of if(!queueableList.isEmpty()) 
        }//END of if(availableLimit > 0 ) 

    }//END of Method : executeQueueableJobs

        /**
    * Process all callable method
    */
    private  static void executeCallableMethods(List<Job_Scheduler__c> lstJobQueueToUpdate, List<Job_Run__c> jobDetailsToInsert){
        List<Job_Scheduler__c> callableListList = getPendingJobs(jobTypeCallable , 1000);
        markJobForNextRun(jobTypeCallable,callableListList,jobDetailsToInsert);
        //Enqueue jobs here
        if(!callableListList.isEmpty()){
            jobDetailsToInsert.clear();
                
            
            for(Job_Scheduler__c  scheduler : callableListList){ 
                try{
                    Callable extension = (Callable)Type.forName(scheduler.Class_Name__c).newInstance();
                    String output = (String) extension.call(scheduler.Method_Name__c,null);
                    if(jobIdToToRunImmediately != null){
                        scheduler.Run_Job_Immediately__c = false;
                    }else{   
                        calculateNextRun(scheduler,false);
                    }
                    if(scheduler.next_run__c != null && scheduler.next_run__c > System.now()){
                        scheduler.Status__c = 'Queued';
                    }else{
                        scheduler.Status__c = 'Completed';
                    }
                    Job_Run__c jobDetail = createJobQueueDetailRec(scheduler.id, 'Completed', scheduler.Class_Name__c);
                    jobDetail.Method_Outcome__c = output;
                    jobDetailsToInsert.add(jobDetail);
                    
                    }catch(Exception e){ 
                    scheduler.Status__c = 'Failed';
                    scheduler.Retry__c = true;
                    
                    Job_Run__c jobDetail = createJobQueueDetailRec(scheduler.id, 'Failed', scheduler.Class_Name__c);
                    jobDetail.Method_Outcome__c = 'Exception Occured ' +e.getMessage();
                    jobDetailsToInsert.add(jobDetail);
                    jobDetail.error_message__c =  e.getMessage()+'\n'+e.getStackTraceString();
                    
                }//END of Catch Block  
                lstJobQueueToUpdate.add(scheduler);
            }//END of for(Job_Scheduler__c  q : queueableList)
            if(!jobDetailsToInsert.isEmpty()){
                insert jobDetailsToInsert;

            }//end of if
        }//END of if(!queueableList.isEmpty()) 

    }//END of Method : executeQueueableJobs

    /*
    * @Purpose : Method to create instance of jobDetail record on job run
    */
    private static Job_Run__c createJobQueueDetailRec(String jobId ,String status ,String className){
        Job_Run__c jobDetail = new Job_Run__c();
        jobDetail.Job_Scheduler__c = jobId;
        jobDetail.Execution_Time__c = System.now();
        jobDetail.Status__c = status;
        jobDetail.Class__c = className;
        return jobDetail;
    }//END of createJobQueueDetailRec

    /*
    * @Purpose : Method to update instance of jobDetail record on job finish
    */
    public static void updateJobDetailRecords(String jobId , String Message , String status , String Method, Integer totalJobItems , Integer numberOfFailure){
        jobId = jobId.subString(0,15); 
        List<Job_Run__c> jobDetail = [ SELECT ID,Status__c,Error_Message__c,Method__c,TotalJobItems__c,
                                                        Number_Of_Failure__c 
                                                        FROM Job_Run__c 
                                                        WHERE Job_Scheduler__r.job_Id__c =:  jobId Order by createdDate desc limit 1 ];
        if(!jobDetail.isEmpty()){
            jobDetail[0].Status__c = status;
            jobDetail[0].Error_Message__c = Message;
            jobDetail[0].Method__c = Method;
            jobDetail[0].TotalJobItems__c = totalJobItems;
            jobDetail[0].Number_Of_Failure__c = numberOfFailure;

            update jobDetail[0];
        }//END of if(!jobDetail.isEmpty())

    }//END of updateJobDetailRecords

    /*
    * @Method to return pending jobs for current execution
    */
    private static List<Job_Scheduler__c> getPendingJobs(String jobType , Integer availableLimit){
 

        if(jobType == jobTypeBatch || jobType == jobTypeQueueable){
            ApexClassList.clear();
            String jobtype1 = jobtype == jobTypeBatch ?  'BatchApex' : jobType;
            List<AsyncApexJob> runningJobs = [SELECT ID ,ApexClass.Name FROM AsyncApexJob WHERE Status  IN  ('Holding','Queued','Preparing','Processing')
                                                AND jobType =: jobtype1
                                                ORDER By TotalJobItems DESC];
            for(AsyncApexJob asyncJob : runningJobs){
                ApexClassList.add(asyncJob.ApexClass.Name);
            }
            if(jobType == jobTypeBatch){
                availableLimit -= ApexClassList.size();
            }
            
        }
        DateTime startTimeWindow = DateTime.newInstance(System.now().year(), System.now().month(), System.now().Day(), System.now().hour(), 0, 0);
        DateTime endTimeWindow = startTimeWindow.addHours(1);
        if(jobIdToToRunImmediately == null){
            return [SELECT ID,Batch_Size__c,Class_Name__c,Job_Id__c,Method_Name__c,
                Job_Type__c, Retry__c,Status__c,Retry_Count__c,Next_run__c,frequency__c,Start_time__c,rescheduling_frequency__c,Run_every__c ,Run_Job_Immediately__c
                FROM Job_Scheduler__c
                WHERE ((Status__c = :jobStatusQueued
                OR (Retry__c = true AND Status__c =: jobStatusFailed ))
                AND Retry_Count__c < : MAX_RETRY_COUNT    
                AND Job_Type__c =: jobType
                AND Class_Name__c Not IN : ApexClassList
                AND ((  start_time__c <=: endTimeWindow  AND Next_run__c = null) OR 
                    (Next_run__c != null AND  Next_run__c <=: endTimeWindow
                    ))  AND Active__c = true)
                    
                ORDER By Priority__c DESC     
                LIMIT : availableLimit ];
        }else{
            return [SELECT ID,Batch_Size__c,Class_Name__c,Job_Id__c,Method_Name__c,
                Job_Type__c, Retry__c,Status__c,Retry_Count__c,Next_run__c,frequency__c,Start_time__c,rescheduling_frequency__c,Run_every__c ,Run_Job_Immediately__c
                FROM Job_Scheduler__c
                WHERE ID =: jobIdToToRunImmediately 
                AND  Job_Type__c =: jobType
                ORDER By Priority__c DESC     
                LIMIT : availableLimit ];
        }
        
                /*((start_time__c >=: startTimeWindow AND  start_time__c <=: endTimeWindow  AND Next_run__c = null) OR 
                    (Next_run__c != null AND Next_run__c >=: startTimeWindow AND  Next_run__c <=: endTimeWindow
                    )) // */

    }//END of getPendingJobs

    /*
    *  @Purpose : This method will collect info(Errors , Success ) from child object : jobDetail and update same in parent object
    */ 
    private static void collectJobInfo(List<Job_Scheduler__c> lstJobQueueToUpdate){
        Integer availableLimit = getAvailableDMLLimit();
        //get the records where Error hasn't been collected
        List<Job_Scheduler__c> queueJobList = new List<Job_Scheduler__c>([SELECT ID,Batch_Size__c,Class_Name__c,Job_Id__c,Method_Name__c,
                                                            Job_Type__c, Retry__c,Status__c,Retry_Count__c,Next_run__c,Run_every__c ,Run_Job_Immediately__c
                                                            FROM Job_Scheduler__c
                                                            WHERE 
                                                            Status__c  IN ('In Progress','Failed')  
                                                            LIMIT : availableLimit ]);

        //prepare jobId to object Map
        Map<String,Job_Scheduler__c> mapJobIdToJob = new Map<String,Job_Scheduler__c>();
        for(Job_Scheduler__c sch : queueJobList){
            if(sch.Job_Id__c != null){
                mapJobIdToJob.put(sch.Job_Id__c , sch);
            }
        }    
        //get details for already scheduled jobs but having no details
        List<Job_Run__c> jobQueueDetailsList = [SELECT ID,Job_Scheduler__c,Error_Message__c,Method__c,
                                                                    Job_Scheduler__r.Job_Id__c,Status__c ,TotalJobItems__c,Number_Of_Failure__c,Job_Scheduler__r.Next_run__c
                                                                    FROM Job_Run__c 
                                                                    WHERE Job_Scheduler__r.Job_Id__c IN : mapJobIdToJob.keySet()
                                                                            AND Status__c IN ('Completed','Failed', 'Holding') 
                                                                            AND Job_Scheduler__r.Error_Collection_Status__c != 'Collected'
                                                                            order by createdDate desc];
        
        Set<String> jobQueueIdsSet = new Set<String>();
        //rollup summary from child record to parent object indicating failure or Success
        for(Job_Run__c jobDetail : jobQueueDetailsList){
            if(!jobQueueIdsSet.contains(jobDetail.Job_Scheduler__r.Job_Id__c)){
                Job_Scheduler__c jobInQueue = mapJobIdToJob.get(jobDetail.Job_Scheduler__r.Job_Id__c);
                jobInQueue.Retry__c = False;
                if(jobInQueue.Next_run__c != null && jobInQueue.Next_run__c > System.now()){
                    jobInQueue.Status__c = 'Queued';
                }else{
                    jobInQueue.Status__c = 'Completed';
                    jobInQueue.Error_Collection_Status__c = 'Collected';
                }
                if(jobDetail.Status__c == 'Failed'){
                    jobInQueue.Retry__c = TRUE;
                    jobInQueue.Status__c = 'FAILED';
                    jobInQueue.Retry_Count__c = jobInQueue.Retry_Count__c == NULL ? 1 : jobInQueue.Retry_Count__c+1;

                }//END Of else if(jobDetail.Status__c == 'Failed')
                
                lstJobQueueToUpdate.add(jobInQueue);
            }
            
            jobQueueIdsSet.add(jobDetail.Job_Scheduler__r.Job_Id__c);
            

        }//END of for(Job_Run__c jobDetail : jobQueueDetailsList)

    } //END Of Method : collectJobInfo

    /**
    @Purpose : Method to perform DML on Job_Scheduler__c list to update status
    */
    private static void saveJobQueueSchedulerRecords(List<Job_Scheduler__c> lstJobQueueToUpdate){
        if(!lstJobQueueToUpdate.isEmpty()){
            update lstJobQueueToUpdate;
        }//END of if(!lstJobQueueToUpdate.isEmpty()
        lstJobQueueToUpdate.clear();
    }//END of Method : saveJobQueueSchedulerRecords

    /**
    @To read Cron job expression and see if job can run at current or not
    */ 
    private static void calculateNextRun(Job_Scheduler__c job, Boolean isReschedule){
        String frequency ;
         Integer X = 1;
         DateTime startTimeWindow = DateTime.newInstance(System.now().year(), System.now().month(), System.now().Day(), System.now().hour(), 0, 0);
        
        if(isReschedule == true){
            if(job.rescheduling_Frequency__c != null){
                frequency = job.rescheduling_Frequency__c;
            }else{
                frequency = 'Hour';
            }   
        
        }else{
            frequency = job.frequency__c;
           
            if(job.Run_every__c  != null){
                X = integer.valueOf(job.Run_every__c );
                
            }
        }
        
        if(frequency != null){

            if(frequency.contains('Minutes')){
                Integer minutesToBeAdded =  Integer.valueOf( frequency.substring(6,8));
                if(job.Next_run__c == null){
                    job.Next_run__c = startTimeWindow.addMinutes(minutesToBeAdded);
                }else{
                    job.Next_run__c = job.Next_run__c.addMinutes(minutesToBeAdded);
                }
            }
            if(frequency == 'Hour'){
                if(job.Next_run__c == null){
                    job.Next_run__c = startTimeWindow.addHours(X);
                }else{
                    job.Next_run__c = job.Next_run__c.addHours(X);
                }
            }else if(frequency == 'Day'){
                if(job.Next_run__c == null){
                    job.Next_run__c = startTimeWindow.addDays(X);
                }else{
                    job.Next_run__c = job.Next_run__c.addDays(X);
                }

            }else if(frequency == 'Month'){
                if(job.Next_run__c == null){
                    job.Next_run__c = startTimeWindow.addMonths(X);
                }else{
                    job.Next_run__c = job.Next_run__c.addMonths(X);
                }

            }if(frequency == 'Year'){
                if(job.Next_run__c == null){
                    job.Next_run__c = startTimeWindow.addYears(X);
                }else{
                    job.Next_run__c = job.Next_run__c.addYears(X);
                }
            }//END of if(q.frequency__c == 'Every Hour')
        }//END of if(q.End_time__c <= System.now())
    }//END of calculateNextRun 

    private static void markJobForNextRun(String jobType , List<Job_Scheduler__c> listToExclude,List<Job_Run__c> jobDetailsToInsert){
        DateTime startTimeWindow = DateTime.newInstance(System.now().year(), System.now().month(), System.now().Day(), System.now().hour(), 0, 0);
        DateTime endTimeWindow = startTimeWindow.addHours(1);

        List<Job_Scheduler__c> listToUpdate = [SELECT ID,Batch_Size__c,Class_Name__c,Job_Id__c,Method_Name__c,rescheduling_frequency__c,
                Job_Type__c, Retry__c,Status__c,Retry_Count__c,Next_run__c,frequency__c,Start_time__c,Run_every__c ,Run_Job_Immediately__c
                FROM Job_Scheduler__c
                WHERE (Status__c = :jobStatusQueued
                OR (Retry__c = true AND Status__c =: jobStatusFailed ))
                AND Retry_Count__c < : MAX_RETRY_COUNT    
                AND Job_Type__c =: jobType
                AND ((  start_time__c <=: endTimeWindow AND next_run__c = null) OR 
                    (Next_run__c != null  AND  Next_run__c <=: endTimeWindow
                    )) AND Active__c = true
                AND ID NOT IN : listToExclude];
                /*((start_time__c >=: startTimeWindow AND  start_time__c <=: endTimeWindow AND next_run__c = null) OR 
                    (Next_run__c != null AND Next_run__c >=: startTimeWindow AND  Next_run__c <=: endTimeWindow
                    ))  */
                jobDetailsToInsert.clear();   
            List<String> apexClassesRunning = new List<String>();
            apexClassesRunning.addAll(apexClassList);           
        for(Job_Scheduler__c job : listToUpdate){
            DateTime temp = job.Next_run__c;
            calculateNextRun(job, true);
            Job_Run__c jobDetail = createJobQueueDetailRec(job.id, 'Rescheduled',job.Class_Name__c);
            
            if(apexClassList.contains(job.class_Name__c)){
                jobDetail.rescheduling_reason__c = 'The same apex class '+job.class_Name__c+' is running in backend';
            }else{
                jobDetail.rescheduling_reason__c = 'This job has been rescheduled because of too many number of of job, from Time Stamp - ' + (temp != null ? temp : job.Start_time__c) + ' To - '+job.Next_run__c+'\n Here is list of classes:';
                for(integer i = 0 ;i< apexClassesRunning.size() ; i++){
                        if(i > 10)
                        break;
                    jobDetail.rescheduling_reason__c += apexClassesRunning[i] + '\n'; 
                }
            }
            jobDetail.is_Rescheduled__c = true;
            jobDetailsToInsert.add(jobDetail);
        }        
        if(!jobDetailsToInsert.isEmpty()){
            insert jobDetailsToInsert;
        }
        update listToUpdate;
    }//END of getPendingJobs
   @InvocableMethod(label='Run Job Immediately' description='Run the job immediately irrespective of schedule' category='Job_Scheduler__c')
    public static void runJob(List<ID> ids) {
        jobIdToToRunImmediately = ids[0];
        executeBatchJobs(lstJobQueueToUpdate, jobDetailsToInsert); //start Batch Jobs
        executeQueueableJobs(lstJobQueueToUpdate , jobDetailsToInsert); // start Queueable Job
        executeCallableMethods(lstJobQueueToUpdate , jobDetailsToInsert); // execute callable methods
        saveJobQueueSchedulerRecords(lstJobQueueToUpdate); // save JobQueue records with all details

    }
   
}//END of Class : JobQueueSchedulerFramework