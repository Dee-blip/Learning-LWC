/* Developer @Hemant Barapatre
* Purpose: To update the Incident Service Target Object records , field-> Clock to Stopped once Ticket is closed.
* ClassUsed : 
* To Schedule the Job use the following code Pallete below:
	HD_RectifyPausedSLAOnClosed_Schedular hdrs = new HD_RectifyPausedSLAOnClosed_Schedular();
	String cronStr = '0 30 * * * ?';
	Datetime now = Datetime.now();
	Integer offset = UserInfo.getTimezone().getOffset(now);
	Datetime local = now.addSeconds(offset/1000);
	System.schedule('HD_RectifyPausedSLAOnClosed_Schedular '+local, cronStr, hdrs);
* class used : HD_RectifyPausedSLAOnClosed.apex
*/
global class HD_RectifyPausedSLAOnClosed_Schedular implements Schedulable {
    
    global void execute(SchedulableContext ctx){
        HD_RectifyPausedSLAOnClosed hdr = new HD_RectifyPausedSLAOnClosed();
        Database.executeBatch(hdr, 1);
    }

}