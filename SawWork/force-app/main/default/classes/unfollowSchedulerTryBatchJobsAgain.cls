global with sharing class unfollowSchedulerTryBatchJobsAgain {

    public static void start(){
        //Seconds Minutes Hours Day_of_month Month Day_of_week optional_year
        //does it once per day at midnight
        //13 seconds, 57 minutes, 0 hours, Day of month = All (*), Day of Week = All (*), Year = no value (?) as it is optional
        //Note the funky random time is to let me query to see if this schedule has been started as 
        //at the time of coding there's an unfixed bug where CronTrigger.Name does not exist, 
        //so I can't query on CronTrigger.Name='Unfollow Rules'
        system.schedule('Try Unfollow Batch Jobs Again', '13 57 * * * ?', new unfollowScheduleTryBatchJobsAgainExecute ()); 
//        system.schedule('Try Unfollow Batch Jobs Again2', '13 57 01 * * ?', new unfollowScheduleTryBatchJobsAgainExecute ()); 
//        system.schedule('Try Unfollow Batch Jobs Again3', '13 57 02 * * ?', new unfollowScheduleTryBatchJobsAgainExecute ()); 
//        system.schedule('Try Unfollow Batch Jobs Again4', '13 57 03 * * ?', new unfollowScheduleTryBatchJobsAgainExecute ()); 
//        system.schedule('Try Unfollow Batch Jobs Again5', '13 57 04 * * ?', new unfollowScheduleTryBatchJobsAgainExecute ()); 
//        system.schedule('Try Unfollow Batch Jobs Again6', '13 57 05 * * ?', new unfollowScheduleTryBatchJobsAgainExecute ()); 
    }//start
 
}//unfollowScheduler