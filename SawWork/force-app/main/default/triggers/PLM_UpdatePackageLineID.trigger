trigger PLM_UpdatePackageLineID on Package__c (before insert, before update) 
{    
// Cast Iron Integration : Resolve the PackageLine Foreign Keys
    List<Package__c> packageList = new List<Package__c>();     
    for(Package__c row : Trigger.new)    
    {        
	    if(Trigger.isInsert && row.CI_PackageLine__c != null)             
	    packageList.add(row); 
	    else if(!Trigger.isInsert && row.CI_PackageLine__c != Trigger.oldMap.get(row.ID).CI_PackageLine__c)
		row.addError('Package Line Id cannot be updated after insert.');
	   
    }    
    if(packageList.size() > 0)        
    PLM_CastIronClass.Resolve_PackageLine_ForeginKeys(packageList);   
}