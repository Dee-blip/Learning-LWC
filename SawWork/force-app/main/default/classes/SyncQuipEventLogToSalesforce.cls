global class SyncQuipEventLogToSalesforce implements Schedulable {
    global void execute(SchedulableContext ctx) 
    {
        doAsyncQuipEventAPICall();
    }
    
    @future(callout=true)
    public static void doAsyncQuipEventAPICall(){
        AsyncQuipEventAPICall quipEventAPICall = new AsyncQuipEventAPICall();
        system.enqueueJob(quipEventAPICall);
    }
}