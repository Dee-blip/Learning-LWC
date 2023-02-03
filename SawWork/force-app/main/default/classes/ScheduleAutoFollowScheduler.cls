global class ScheduleAutoFollowScheduler {
    global void ScheduleAutoFollowScheduler() {}
    public static void start()
    {
        //Seconds Minutes Hours Day_of_month Month Day_of_week optional_year
        //Schedules the job every midnight....
        System.schedule('Auto Follow Schedule', '0 0 0 * * ?', new ScheduleAutoFollow());
    }
    
}