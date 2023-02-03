public class SF1_CustomSortController 
{
	public SF1_CustomSortController() 
	{
		
	}

	@AuraEnabled
    public static Map<String,String> getMapOfFieldNamesvsApiName(String sObjectName) {

    	SF1_CustomSortSetting__mdt sortFieldNamesForSObject = [SELECT fieldsNamesAvailableInSorting__c FROM SF1_CustomSortSetting__mdt where sObjectApiName__c=:sObjectName][0];
		String fieldsNamesAvailableInSorting = sortFieldNamesForSObject.fieldsNamesAvailableInSorting__c;
		Set<String> fieldsNamesAvailableInSortingParts = new Set<String>();
        fieldsNamesAvailableInSortingParts.addAll(fieldsNamesAvailableInSorting.split(',')); 
		Map<String, Schema.SObjectField> M = Schema.SObjectType.Opportunity.fields.getMap();
		Map<String,String> mapOfFieldNamesvsApiName = new Map<String,String>();
		System.debug('fieldsNamesAvailableInSortingParts :'+fieldsNamesAvailableInSortingParts);
		for(String key : fieldsNamesAvailableInSortingParts)
		{
		    if(M.get(key.toLowerCase())!=null)
		    {
			  mapOfFieldNamesvsApiName.put(M.get(key.toLowerCase()).getDescribe().getLabel(),key);
		    }
		    
		}
        System.debug('mapOfFieldNamesvsApiName :'+mapOfFieldNamesvsApiName);
        return mapOfFieldNamesvsApiName;
    }
}