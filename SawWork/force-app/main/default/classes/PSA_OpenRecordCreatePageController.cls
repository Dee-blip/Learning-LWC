/*
 * CR: FFPSA-647
 * Developer: Sharath Prasanna
 * Enhancement: A generic class for new Object creation quick action
 * Date: 21th August 2018
 * 
*/ 
public class PSA_OpenRecordCreatePageController 
{
	public PSA_OpenRecordCreatePageController() 
	{
			
	}

	@AuraEnabled
	public static String prepareDefaultJsonString(String recordId, String objectType)
	{
		Id parentId = (Id)recordId;
		String parentName = parentId.getSObjectType().getDescribe().getName();
		Map<String,String> keyValueMap = new Map<String,String>();
		Map<String,String> keyValueMapParent = new Map<String,String>();
		List<String> keyList = new List<String>();
		String fieldList = '';
		String jsonString = 'Nothing Found';
		//List<PSA_Object_Default_Mapping__mdt> mappingRecords = [select Object__c, Parent__c, Parent_Default_Fields__c, Static_Default_Fields__c from PSA_Object_Default_Mapping__mdt where Object__c = :objectType and Parent__c = :parentName];
		List<PSA_Common_Setting__mdt> mappingRecords = [select Object__c, Parent__c, Parent_Default_Fields__c, Static_Default_Fields__c from PSA_Common_Setting__mdt where type__c = 'PSA_Object_Default_Mapping__mdt' and Object__c = :objectType and Parent__c = :parentName];
		if(mappingRecords != null && !mappingRecords.isEmpty())
		{
			for(PSA_Common_Setting__mdt mappingRecord : mappingRecords)
			{
				if(mappingRecord.Static_Default_Fields__c != null)
				{
					for(String keyValue : mappingRecord.Static_Default_Fields__c.split(','))
					{
						keyList = keyValue.split(':');
						if(keyList != null && keyList.size() == 2)
						{
							keyValueMap.put(keyList.get(0).trim(),keyList.get(1).trim());	
						}
						
					}

				}
				if(mappingRecord.Parent_Default_Fields__c != null)
				{
					for(String keyValue : mappingRecord.Parent_Default_Fields__c.split(','))
					{
						keyList = keyValue.split(':');
						if(keyList != null && keyList.size() == 2)
						{
							keyValueMapParent.put(keyList.get(1).trim(),keyList.get(0).trim());	
							fieldList += keyList.get(1).trim() + ','; 
						}
						
					}
				}
				
			}
			if(fieldList.length() > 0)
			{
				fieldList = fieldList.substring(0, fieldList.length() - 1);	
				String query = 'select ' + fieldList + ' from ' + parentName + ' where Id = \'' + parentId + '\'';
				List<SObject> parentRecords = Database.query(query);
				SObject parentRecord;
				if(parentRecords != null && !parentRecords.isEmpty())
				{
					parentRecord = parentRecords.get(0);
					system.debug('The parent object: ' + parentRecord);
					for(String key: keyValueMapParent.keySet())
					{
						if(parentRecord.get(key) != null)
						{
							keyValueMap.put(keyValueMapParent.get(key),String.valueOf(parentRecord.get(key)));
						}
					}
				}
			}

			jsonString = JSON.serialize(keyValueMap);
		}
		return jsonString;
	}
}