trigger PLM_UpdateSolutionPurposeIDs on Solution_Purpose__c (before insert, before update)
{    // Cast Iron Integration : Resolve the Solution Purpose Keys 
List<Solution_Purpose__c> solutionPurposeList = new List<Solution_Purpose__c>();    
for(Solution_Purpose__c row : Trigger.new)            
{                
	if(Trigger.isInsert && row.CI_Purpose__c != null && row.CI_Solution__c != null)    
	solutionPurposeList.add(row);
	else if((!Trigger.isInsert && row.CI_Purpose__c != Trigger.oldMap.get(row.ID).CI_Purpose__c)||(!Trigger.isInsert && row.CI_Solution__c != Trigger.oldMap.get(row.ID).CI_Solution__c))
	row.addError('Solution Id OR Purpose Id cannot be updated after insert.');
	           
}            
if(solutionPurposeList.size() > 0)                
PLM_CastIronClass.Resolve_Solution_Purpose_ForeginKeys(solutionPurposeList);   
}