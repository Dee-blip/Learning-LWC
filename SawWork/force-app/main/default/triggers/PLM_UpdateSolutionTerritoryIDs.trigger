trigger PLM_UpdateSolutionTerritoryIDs on Solution_Territory__c (before insert, before update)
{    // Cast Iron Integration : Resolve the Solution Territory Keys    
List<Solution_Territory__c> solutionTerritoryList = new List<Solution_Territory__c>();    
for(Solution_Territory__c row : Trigger.new)            
{                
	if(Trigger.isInsert && row.CI_Solution__c != null && row.CI_Territory__c != null)    
	solutionTerritoryList.add(row);   
	else if((!Trigger.isInsert && row.CI_Solution__c != Trigger.oldMap.get(row.ID).CI_Solution__c)||(!Trigger.isInsert && row.CI_Territory__c != Trigger.oldMap.get(row.ID).CI_Territory__c))
	row.addError('Solution Id OR Territory Id cannot be updated after insert.');
	            
}            
if(solutionTerritoryList.size() > 0)                
PLM_CastIronClass.Resolve_Solution_Territory_ForeginKeys(solutionTerritoryList);   
}