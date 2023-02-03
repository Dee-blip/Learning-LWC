trigger PLM_UpdateDefaultSolutionID on Solution_Category__c (before insert, before update) 
{
    // Cast Iron Integration : Resolve the DefaultSolution Foreign Keys
    List<Solution_Category__c> solutionCategoryList = new List<Solution_Category__c>(); 
    for(Solution_Category__c row : Trigger.new)
    {
        if(row.CI_Default_Solution__c != null) {
            if(Trigger.isInsert)
            solutionCategoryList.add(row);
        else{
            if(row.CI_Default_Solution__c != Trigger.oldMap.get(row.ID).CI_Default_Solution__c)
                solutionCategoryList.add(row);
            }
        }
    }
    if(solutionCategoryList.size() > 0)
        PLM_CastIronClass.Resolve_Solution_ForeginKeys(solutionCategoryList);      
}