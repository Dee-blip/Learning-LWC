/**
IRCaseLockQueueable
    @author : Ankit Chawla
    @Description : This class queues the batch call for IR Cases lock

    @History
    --Developer           --Date            --Change
    Achawla               23/09/2019        MOM-980: Created the class.
*/
public class IRCaseLockQueueable implements Queueable {
    public Date startDate;
	  public Date endDate;
    public Id userId;

    public IRCaseLockQueueable(Date pStartDate, Date pEndDate, Id pUserId){
        startDate = pStartDate;
        endDate = pEndDate;
        userId = pUserId;
    }

	public void execute(QueueableContext context) {
      IRCaseLockClass execIRCaseLock = new IRCaseLockClass(startDate, endDate, userId);
		  Database.executeBatch(execIRCaseLock);
  }
}