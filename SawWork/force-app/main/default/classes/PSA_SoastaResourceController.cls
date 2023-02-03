/*
 * CR: FFPSA-238
 * Developer: Sharath Prasanna
 * Enhancement: The controller for the Multi Resource field for Test Object
 * Date: 5th August 2017
 * 
*/ 
public class PSA_SoastaResourceController {
	public Id testId;

    public boolean isClassic
    {
        get
        {
            return (UserInfo.getUiThemeDisplayed() == 'Theme3');

        }
        set;
    }    

	public Test__c testRecord
	{
		get
		{
			if(testRecord == null)
			{
				testRecord = new Test__c();	
			}
			return testRecord;
		}
		set;
	}
	public List<SelectOption> availableList
	{
		get
		{
			if(availableList == null)
			{
				availableList = new List<SelectOption>();	
			}
			return availableList;
		}
		set;
	}

	public List<selectOption> chosenList
	{
		get
		{
			if(chosenList == null)
			{
				chosenList = new List<SelectOption>();	
			}
			return chosenList;
		}
		set;
	}

	public PSA_SoastaResourceController(ApexPages.StandardController sc) 
	{
		testId = ApexPages.currentPage().getParameters().get('id');
		List<Test__c>testRecords = [select id, Testing_PE_multi__c,Engagement__c from Test__c where id = :testId];

		Set<String> resources = new Set<String>();
		Set<String> duplicateCheckSet = new Set<String>();
		if(testRecords != null && !testRecords.isEmpty())
		{
			testRecord = testRecords[0];
			if(testRecord.Testing_PE_multi__c != null)
			{
				
				for(String resource: testRecord.Testing_PE_multi__c.split(';'))
				{
					chosenList.add(new SelectOption(resource,resource));
					
					resources.add(resource);
				}

			}
			Date today = Date.today();
		    for(pse__Assignment__c assignment: [select id,pse__resource__r.Name from pse__Assignment__c where pse__project__c = :testRecord.Engagement__c and pse__Closed_For_Time_Entry__c = false and pse__End_Date__c >= :today ])
		    {
		    	if(! resources.contains(assignment.pse__resource__r.Name) && !duplicateCheckSet.contains(assignment.pse__resource__r.Name))
		    	{
		    		availableList.add(new SelectOption(assignment.pse__resource__r.Name,assignment.pse__resource__r.Name));	
		    		duplicateCheckSet.add(assignment.pse__resource__r.Name);	
		    	}
		    	
		    }
		}
	}

	public PageReference SaveField()
	{

		String selectedResources = '';
		for(SelectOption selected: chosenList)
		{
			selectedResources += selected.getValue() + ';';
		}
		if(selectedResources.length() > 0)
		{
			selectedResources = selectedResources.substring(0,selectedResources.length() - 1);	
		}
		testRecord.Testing_PE_multi__c = selectedResources;
		update testRecord;
		PageReference pg = new PageReference('/'+testRecord.id);
		return pg;	

	}
	public PageReference CancelField()
	{
		PageReference pg = new PageReference('/'+testRecord.id);
		return pg;	
	}

}