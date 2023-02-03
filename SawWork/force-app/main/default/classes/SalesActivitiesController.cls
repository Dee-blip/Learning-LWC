/**
    UpdateQfaMeetingDateController
    @author : Karteek Mekala <kmekala@akamai.com>
    @Description : This class is used as a VisualForce controller for the VisualForce page "apex/SalesActivities".
					- CR 662770  Create VF page that will look similiar to the page that is displayed when you click the View All button
					
	@History
	--Developer		      --Date			--Change
	Karteek Kumar M		  --/06/10			Created the class	
*/	

public class SalesActivitiesController 
{
    public Account acc{get; set;}
    public List<Task> allTasks{get; set;}
    public Integer count{get; set;}
    public String selectedJumpOption;
    public List<Selectoption> jumpOptions {get; set;}
    public Map <String, Task> taskMap {get; set;}
    public Task selectedTask {get; set;}
    public Boolean initializedFlag {get; set;}
    /**
    	SalesActivitiesController()
    	- Constructor : fetches all the Activities of the Account who's Id is passed as a parameter to the VF page.
    */
    public SalesActivitiesController() 
    {
        initializedFlag = true;
        try
        {
                this.acc = [Select Id, 
                                                   Name, 
                                                   (Select AKAM_Activity_Id__c, 
                                                                   Subject, 
                                                                   OwnerId, 
                                                                   WhatId, 
                                                                   WhoId, 
                                                                   isTask, 
                                                                   Description, 
                                                                   ActivityDate, 
                                                                   AKAM_Modified_Date__c, 
                                                                   Type__c 
                                                        From ActivityHistories 
                                                        where Type__c != 'Nurture'
                                                              and Type__c != 'Other'
                                                              and Type__c != 'Qualifying Questions'
                                                              and Type__c != 'Vtrenz'
                                                              and Type__c != 'WWW'
                                                              and Type__c != 'Audit Trail'
                                                        ORDER BY ActivityDate DESC) 
                                         From Account 
                                         where Id = :ApexPages.currentPage().getParameters().get('id')];
                system.assertNotEquals(acc, null);
        }
        catch(Exception e)
        {
                 ApexPages.Message errMsg = new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to find an Account with the specified Id.');
             ApexPages.addMessage(errMsg); 
             initializedFlag = false;
        }
        if(initializedFlag)
        {
                allTasks = new List<Task>();
                jumpOptions = new List<Selectoption>();
                taskMap = new Map<String, Task>();
                Task temp;
                for(ActivityHistory ah:acc.ActivityHistories)
                {
                        temp = new Task();
                        temp.Subject = ah.Subject;
                        temp.OwnerId = ah.OwnerId;
                        temp.WhatId = ah.WhatId;
                        temp.WhoId = ah.WhoId;
                        temp.Description = ah.Description;
                        temp.ActivityDate = ah.ActivityDate;
                        temp.AKAM_Modified_Date__c = ah.AKAM_Modified_Date__c;
                        temp.Type__c =ah.Type__c;
                        temp.AKAM_Activity_ID__c = ah.AKAM_Activity_Id__c;
                                allTasks.add(temp);
                                taskMap.put(temp.AKAM_Activity_ID__c, temp);
                                jumpOptions.add(new Selectoption(temp.AKAM_Activity_Id__c, temp.Subject));
                }
                count = allTasks.size();
         }
    }
    /**
    	redirect()
    	- Redirects to the Account detail page.
    */
    public PageReference redirect() 
    {
            PageReference accPage = new PageReference('/' + acc.id);
            accPage.setRedirect(true);
            return accPage;
    }
    /**
    	getSelectedJumpOption()
    	- Returns to Select Options to the VF page
    	- used to implement the "Jump To" feature.
    */
    public String getSelectedJumpOption()
    {
            return selectedJumpOption;
    }
    
    public void setSelectedJumpOption(String pSelectedJumpOption)
    {
            this.selectedJumpOption = pSelectedJumpOption;
    }
    
    public PageReference go()
    {
            selectedTask = taskMap.get(selectedJumpOption);
            return null;
    }
}