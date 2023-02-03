trigger PLM_UpdatePackageVersionProductsIDs on PackageVersion_Products__c (before insert, before update)
{    // Cast Iron Integration : Resolve the PackageVersion Product Keys 
List<PackageVersion_Products__c> pkgVersionProductsList = new List<PackageVersion_Products__c>();    
for(PackageVersion_Products__c row : Trigger.new)            
{                
	if(Trigger.isInsert && row.CI_Package_Version__c != null && row.CI_Product__c != null)    
	pkgVersionProductsList.add(row);  
    else if((!Trigger.isInsert && row.CI_Package_Version__c != Trigger.oldMap.get(row.ID).CI_Package_Version__c)||(!Trigger.isInsert && row.CI_Product__c != Trigger.oldMap.get(row.ID).CI_Product__c))
	row.addError('Package Version Id OR Product Id cannot be updated after insert.');
	         
}            
if(pkgVersionProductsList.size() > 0)                
PLM_CastIronClass.Resolve_PackageVersion_Products_ForeginKeys(pkgVersionProductsList);   
}