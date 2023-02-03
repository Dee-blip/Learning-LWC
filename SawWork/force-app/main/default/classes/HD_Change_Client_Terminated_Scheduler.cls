public class HD_Change_Client_Terminated_Scheduler implements Schedulable{
	public void execute(SchedulableContext sc) {
    	HD_Change_Client_when_Terminated cct = new HD_Change_Client_when_Terminated();
        cct.changeClientWithEmailAlert();
    }
}