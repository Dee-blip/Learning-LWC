global class L2Q_Sales_processInactiveUserScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        L2Q_Sales_ProcessInactiveUser batchJob = new L2Q_Sales_ProcessInactiveUser();
        database.executebatch(batchJob);
    }
}