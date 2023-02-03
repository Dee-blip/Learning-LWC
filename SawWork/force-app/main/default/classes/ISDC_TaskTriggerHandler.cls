public class ISDC_TaskTriggerHandler {

    public static void beforeInsertTask(List<Task> newTask){
        for(Task t:newTask){
            if(t.Subject!=null && t.Subject.containsIgnoreCase('Skipped')){
                t.Status='Skipped';
            }
        }
    }
}