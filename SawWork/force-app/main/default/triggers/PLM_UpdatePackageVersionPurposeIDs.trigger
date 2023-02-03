trigger PLM_UpdatePackageVersionPurposeIDs on PackageVersion_Purpose__c (before insert, before update)
{    // Cast Iron Integration : Resolve the PackageVersion Purpose Keys 
List<PackageVersion_Purpose__c> packageVersionPurposeList = new List<PackageVersion_Purpose__c>();    
for(PackageVersion_Purpose__c row : Trigger.new)            
{                
	if(Trigger.isInsert && row.CI_Purpose__c != null && row.CI_Package_Version__c != null)    
	packageVersionPurposeList.add(row);
	else if((!Trigger.isInsert && row.CI_Package_Version__c != Trigger.oldMap.get(row.ID).CI_Package_Version__c)||(!Trigger.isInsert && row.CI_Purpose__c != Trigger.oldMap.get(row.ID).CI_Purpose__c))
	row.addError('Package Version Id OR Purpose Id cannot be updated after insert.');
	             
}            
if(packageVersionPurposeList.size() > 0)                
PLM_CastIronClass.Resolve_PackageVersion_Purpose_ForeginKeys(packageVersionPurposeList);   
}