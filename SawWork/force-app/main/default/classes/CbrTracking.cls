/***
	CbrTracking
	
    CbrTracking
    @author : Karteek Mekala <kmekala@akamai.com>
    @Description :  This class implements the Schedulable interface thus enabling it to run as a scheduled class.
	
	@Requirements :
	
	CR 690580  CBR Tracking workflow
	
	"For Accounts that meet the following criteria:
	(i) Account Status <> "Lead" OR *Inactive
	(ii) Support Level = "Priority" OR "Premium"
	Create an Activity on the 10th day of every Quarter (Jan 10, April 10, July 10,
	Oct 10) having the following parameters: 
	Type = "To Do"
	Subject = "Deliver CBR"
	Due Date = 30 days from date of creation
	Assigned To = Account Team member on the account in question with Team Role  =
	"Services - Primary".  If no "Services - Primary" found on the account team,
	assign to Account Owner.
	
	If such an activity already exists for an account (same Type, Subject AND Due
	Date), do not create a duplicate."
	
	@History
	--Developer		      --Date			--Change
	Karteek Kumar M		  01/07/10			Created the class.     	

*/


global class CbrTracking implements Schedulable 
{
	
	@future
	public static void CbrTrackingFunction()
	{
		// Get all the Account Team Members that meet the criteria
		List<AccountTeamMember> atmList = [select Id,
											   UserId,
											   AccountId
										from AccountTeamMember 
										where Account.Type != '%Lead%' and 
											  Account.Type != '%Inactive%' and 
											  (Account.Support_Level__c = 'Priority' or  Account.Support_Level__c = 'Premium') and 
											  TeamMemberRole = 'Services - Primary' and
											  User.IsActive = true];
											  
		// Get a list of Account Ids
		Set<Id> accountIdSet = new Set<Id>();
		for(AccountTeamMember atm : atmList)
			accountIdSet.add(atm.AccountId);
			
		// Get CRB Tasks that were already created to prevent duplicate task creation
		Set<Id> accountIdSetExistingTasks = new Set<Id>();
		for(Task tsk : [select Id, WhatId from Task where WhatId IN :accountIdSet and Subject = 'Deliver CBR'])
			accountIdSetExistingTasks.add(tsk.WhatId);
		
		// Create CBR Tasks
		List<Task> cbrTasks = new List<Task>();
		Task temp;
		for(AccountTeamMember atm : atmList)
		{
			if(!accountIdSetExistingTasks.contains(atm.AccountId))
			{
				temp = new Task();
				temp.WhatId = atm.AccountId;
				temp.OwnerId = atm.UserId;
				temp.Subject = 'Deliver CBR';
				temp.ActivityDate = Date.today().addDays(30);
				temp.Type = 'To Do';
				cbrTasks.add(temp);
			}
		}
		if(cbrTasks.size()>0)
			insert cbrTasks;
	}
	
	WebService static void ButtonExecute()
	{
		CbrTrackingFunction();
	}
	 
    global void execute(SchedulableContext sc) 
    {
		CbrTrackingFunction();
    }
	 
}

/**

	Scheduler : 
	
	String seconds = '0';
	String minutes = '0';
	String hours = '0'; 
	String dayOfMonth = '10';
	String month = '1,4,7,10'; 
	String dayOfWeek = '?';
	String year = '2009,2010,2011,2012,2013';
	
	String sch = seconds + ' ' + minutes + ' ' + hours + ' ' + dayOfMonth + ' ' + month + ' ' + dayOfWeek + ' '  + year;
	
	system.schedule('Create CBR Tasks', sch, new CbrTracking());


*/