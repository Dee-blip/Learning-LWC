/*********************************************************************************
    PSA_ProjectUpdate_Controller
    @author Liz Ichihashi
    @Description : This Class is invoked from the PSA_ProjectUpdate_Page.
    			   This page provides the ability for the user to search/find
				   Projects where they are Owner and the project is Active.
                   They can further filter and update many projects at once.  
                   They can also update Project Milestones, Products
                   and Budgets.
                   
                   This class supports PSA customization requirment 4.1.15 - Project Status and Timeline page update
	@History
	--Developer		      --Date			--Change
	Liz Ichihashi    	  01/04/2013		Created the class.	
    Sharath Prasanna	  22/06/2015		Modified the class for CR 3004292 	
*********************************************************************************/
public class PSA_ProjectUpdate_Controller {
    
	//the filterProjObj is used only for data entry fields for the to/from date filter.  
	//Using this dummy object allows the use of inputField, which provides date widget and date validation.
	public pse__Proj__c filterProjObj {get; set;}
	/* list of projects that are active for user */
	public List<PSA_SelectableObject> projectList {get; set;}
	/* variables used for filtering results */
	public List<SelectOption> filterTypes  {get; set;}
	public String selectedFilterType {get; set;}
	public String selectedFilter {get; set;}
	/* booleans to determine which nested objects to show on page */
	public Boolean showBudgets {get; set;}	
	public Boolean showProjectProducts {get; set;}	
	public Boolean showMilestones {get; set;}		
	/* number of projecrts retrieved */
	public Integer projCount {get; set;}
	/* base query to return all projects that are active where user is owner */
    // Changes made by shprasan for CR CR 3004292. Added the fields Basic_Implementation_Complete__c and Implementation_Complete__c
	public static String baseQuery = 'Select Id, Name, pse__Account__c, pse__Planned_Hours__c, pse__Parent_Project__c, ' +		
										' pse__Practice__c, pse__Project_Manager__c, pse__Stage__c, pse__Parent_Project__r.Name, '+
										' pse__Project_Status__c, pse__Project_Status_Notes__c, Billing_Effective_Date__c, ' +
										' Customer_Live__c, pse__Start_Date__c, pse__End_Date__c, Customer_Acceptance_Requested__c, ' +
        								' Basic_Implementation_Complete__c, Implementation_Complete__c '	;


	public PSA_ProjectUpdate_Controller() {       	
	}   
	
	/* called from page action attribute to get page ready */
	public PageReference setup() {
		projCount = 0;
		showBudgets = true;
        showProjectProducts = true;
       	showMilestones = true;  
       	filterProjObj = new pse__Proj__c();
       	filterProjObj.pse__Is_Active__c = true;
       	filterProjObj.pse__Is_Billable__c = true;
       	filterProjObj.pse__Is_Template__c = true;
		setupFilterTypes();
		return null;
	}
	
	/* Setup select options for the filter type picklist */
	private void setupFilterTypes() {
		filterTypes = new List<SelectOption>();
		SelectOption filterType = new SelectOption('Project', 'Project');
		filterTypes.add(filterType);
		filterType = new SelectOption('Milestone', 'Milestone');
		filterTypes.add(filterType);
		filterType = new SelectOption('Account', 'Account');
		filterTypes.add(filterType);
	}

	/* retrieve data from db, check filters to see if any should be applied */
	public void getData() {
		projectList = new List<PSA_SelectableObject>();	
		String selectQuery = '';
		
		//filterProjObj is just being used for the UI component of the filter from and to date fields and the include flags.
		/* show budgets? */
		if (filterProjObj.pse__Is_Active__c) {
			showBudgets = true;
			
		} else {
			showBudgets = false;
		}
		
		/* show project products? */
		if (filterProjObj.pse__Is_Billable__c) {
			showProjectProducts = true;
		} else {
			showProjectProducts = false;
		}
		
		/* show milestones? */
		if (filterProjObj.pse__Is_Template__c) {  	
			showMilestones = true;			
		} else {
			showMilestones = false;
		}
		/* add the child queries to get budgets, project products and milestones */
        //Changes made by shprasan for CR 3004292. Added the field Go_Live_Date__c.
		selectQuery = ', (Select Id, Name, pse__Amount__c from pse__Budgets__r) ';
		selectQuery += ', (Select Id, Name, Basic_Implementation_Complete__c, Go_Live_Date__c from pse__Project_Methodologies__r) ';
		selectQuery += ',  (Select Id, Name, RecordTypeId, pse__Status__c, pse__Target_Date__c, pse__Milestone_Amount__c, '+
						' pse__Planned_Hours__c, pse__Actual_Date__c, Start_Date__c, pse__Closed_for_Time_Entry__c, Billable__c, Task_Milestone_Name__c, Milestone_Type_List__c from pse__Milestones__r '+
						' where RecordType.DeveloperName = \'Task_Milestone_Non_Internal\') ';		
		String fromClause = ' from pse__Proj__c where pse__Is_Active__c = true and OwnerId = \'' + UserInfo.getUserId() + '\'';
		
		
		if (filterProjObj.pse__Start_Date__c != null) {
			fromClause += ' and pse__Start_Date__c >= ' + String.valueOf(filterProjObj.pse__Start_Date__c);
		}
		if (filterProjObj.pse__End_Date__c != null) {
			fromClause += ' and pse__End_Date__c <= ' + String.valueOf(filterProjObj.pse__End_Date__c);
		}
		
		if (filterProjObj.pse__Project_Status__c != null) {
			fromClause += ' and pse__Project_Status__c = \'' + filterProjObj.pse__Project_Status__c + '\'';
		}
		
		if (selectedFilter != null && selectedFilter.length() > 0) {
			String escapedFilter = String.escapeSingleQuotes(selectedFilter);
			if (selectedFilterType == 'Project') {
				fromClause += ' and Name like \'%' + escapedFilter.trim() + '%\'';
			} else if (selectedFilterType == 'Milestone') {
				String mileQuery = 'select pse__Project__c, Id from pse__Milestone__c where Name like \'%' + escapedFilter.trim() + '%\''; 
				List<pse__Milestone__c> milestones = Database.query(mileQuery);
				String inList = '';
				Set<Id> projIds = new Set<Id>();
				for (pse__Milestone__c mileRow : milestones) {
					projIds.add(mileRow.pse__Project__c);
					inList += '\'' + mileRow.pse__Project__c + '\',';
				} 
				if (inList.length() > 0) {
					//get rid of trailing comma
					inlist = inlist.substring(0,inlist.length()-1);
					fromClause += ' and Id in (' + inList + ') ';
				}	
			} else {
				//selectedFilterType is Account
				fromClause += ' and pse__Account__r.Name like \'%' + selectedFilter.trim() + '%\'';	
			}	
		}
		
		String fullQuery = baseQuery + selectQuery + fromClause + ' order by Name';
		String countQuery = 'select count() ' + fromClause;
		System.debug('fullQuery='+fullQuery);
		Integer rowCount = Database.countQuery(countQuery);
		if (rowCount > 100) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Your search returned too many results.  Please narrow your search by entering one or more filters.'));
			return;
		}
		PSA_SelectableObject newRow;
		List<pse__Proj__c> tempProjList = Database.query(fullQuery);
		
		for (pse__Proj__c projRow : tempprojList) {
			newRow = new PSA_SelectableObject();
			newRow.obj = projRow;  
			newRow.showBudgets = showBudgets;
			newRow.showMilestones = showMilestones;
			newRow.showProjectProducts = showProjectProducts;
			projectList.add(newRow);
		}

		projCount = projectList.size();
		if (projCount == 0) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'No Projects were found using the filter(s) you selected.'));
		}
	}

	/* called from button on page to save changes to the DB and return a success message to user */
	public PageReference save() {		
		Savepoint dbSave = Database.setSavepoint();
		try {
			List<pse__Proj__c> projList = new List<pse__Proj__c>();
			List<pse__Milestone__c> milestoneList = new List<pse__Milestone__c>();
			List<pse__Budget__c> budgList = new List<pse__Budget__c>();
			List<pse__Project_Methodology__c> projectProductList = new List<pse__Project_Methodology__c> ();
			for (PSA_SelectableObject projRow : projectList) {
				projList.add(projRow.getProject());
				for (pse__Milestone__c mileRow : projRow.getProject().pse__Milestones__r) {
					milestoneList.add(mileRow);
				}
				for (pse__Budget__c budgRow : projRow.getProject().pse__Budgets__r) {
					budgList.add(budgRow);
				}
				for (pse__Project_Methodology__c projProdRow : projRow.getProject().pse__Project_Methodologies__r) {
					projectProductList.add(projProdRow);
				}
			}	
			update projList;
			update milestoneList;  
			update budgList;
			update projectProductList;
			getData();
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Successfully updated Project Data.'));
		} catch (Exception e) {
			List<ApexPages.Message> messList = ApexPages.getMessages();  
			if (messList == null || messList.size() == 0) {
				ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, e.getMessage()));
			}	
			Database.rollback(dbSave);
		}	
		
		return null;
	}
	
	/* called from filter button on page to re-retrieve data based on new filters */
	public PageReference filter()  {
		getData();
		return null;
	}
	
	/* called from clear button on page to re-retrieve data based on no filters */
	public PageReference clear()  {
		setup();
		getData();
		return null;
	}

	/* called from cancel button on page to cancel any changes made on page without saving */
	public PageReference cancel() {
		setup();
		getData();
		ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Successfully cancelled changes.'));
		return null;
	}
}