trigger PLM_UpdateSolutionCategoryID on Solution__c (before insert, before update) 
{
    // Cast Iron Integration : Resolve the SolutionCategory  Foreign Keys
    List<Solution__c> solutionList = new List<Solution__c>(); 
    for(Solution__c row : Trigger.new)
    {
        if(Trigger.isInsert && row.CI_Solution_Category__c != null) 
            solutionList.add(row);
        else if(!Trigger.isInsert && row.CI_Solution_Category__c != Trigger.oldMap.get(row.ID).CI_Solution_Category__c)
			row.addError('Solution Category cannot be updated after insert.');
	
    }
    if(solutionList.size() > 0)
        PLM_CastIronClass.Resolve_Solution_CategoryForeginKeys(solutionList);   
}