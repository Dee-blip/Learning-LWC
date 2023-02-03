/***
    CloseOldOpptyScheduleClass
    @author : Karteek Mekala <kmekala@akamai.com>
    @Description :  This class implements the Schedulable interface thus enabling it to run as a scheduled class.
    				The task is to close all Opportunities that have past 16 days from the closed date and have not beel closed yet.
    				These Opportunities are updated to StageName = 'Closed Admin'
				    
	@History
	--Developer		      --Date			--Change
	Karteek Kumar M		  09/04/10			Created the class. 
	Ali KM				  29/07/12			CR 1762643 Re-schedule job to make opportunity 'Closed Admin' .      
											 -> added static boolean variable to bypass the @future calls in OpportunityShares.trigger
*/
global class CloseOldOpptyScheduleClass implements Schedulable
{
	// Flag that will ensure OpportunityShares.trigger code that runs @future is bypassed.
	public static Boolean updateCloseOldOpportunityFlag=false;
	global void execute(SchedulableContext sc) 
    {
		OpportunityTriggerClass.CloseOldOpportunities();
    }
}