public class HDApexJobMonitorScheduler implements Schedulable {
	 public void execute(SchedulableContext SC) {
     	HDApexJobMonitor ajm = new HDApexJobMonitor();
		ajm.createContent();
   }
}