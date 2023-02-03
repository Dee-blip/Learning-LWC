trigger PLM_UpdateSolutionPackageVersionIDs on Solution_PackageVersion__c (before insert, before update)
{    // Cast Iron Integration : Resolve the Solution PackageVersion Keys 
List<Solution_PackageVersion__c> solutionPackageVersionList = new List<Solution_PackageVersion__c>();    
for(Solution_PackageVersion__c row : Trigger.new)            
{                
	if(Trigger.isInsert && row.CI_Package_Version__c != null && row.CI_Solution__c != null)    
	solutionPackageVersionList.add(row);
	else if((!Trigger.isInsert && row.CI_Package_Version__c != Trigger.oldMap.get(row.ID).CI_Package_Version__c)||(!Trigger.isInsert && row.CI_Solution__c != Trigger.oldMap.get(row.ID).CI_Solution__c))
	row.addError('Solution Id OR Package Version Id cannot be updated after insert.');
	             
}            
if(solutionPackageVersionList.size() > 0)                
PLM_CastIronClass.Resolve_Solution_PackageVersion_ForeginKeys(solutionPackageVersionList);   
}