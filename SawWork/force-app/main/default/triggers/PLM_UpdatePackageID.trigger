trigger PLM_UpdatePackageID on Package_Version__c (before insert, before update)
{    
// Cast Iron Integration : Resolve the Package Foreign Key
    List<Package_Version__c> packageVersionList = new List<Package_Version__c>();
    for(Package_Version__c row : Trigger.new)        
    {            
	    if(Trigger.isInsert && row.CI_Package__c != null)
	    packageVersionList.add(row);        
    	else if(!Trigger.isInsert && row.CI_Package__c != Trigger.oldMap.get(row.ID).CI_Package__c)
		row.addError('Package Id cannot be updated after insert.');
    }     
    if(packageVersionList.size() > 0)            
    PLM_CastIronClass.Resolve_Package_ForeginKeys(packageVersionList);   
}