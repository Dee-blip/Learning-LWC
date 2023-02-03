global class L2Q_UpdateLeadAndContactCountScheduler implements Schedulable {
    global void execute(SchedulableContext ctx) {
        L2Q_UpdateLeadAndContactCountOnAccount obj = new L2Q_UpdateLeadAndContactCountOnAccount();
        system.enqueueJob(obj);
    }
}