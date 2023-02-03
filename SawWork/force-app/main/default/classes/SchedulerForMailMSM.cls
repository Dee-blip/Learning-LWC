global class SchedulerForMailMSM implements Schedulable {
    global void execute(SchedulableContext ctx){
        SendMailForManualStep.sendMail();
    }
}