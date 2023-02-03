/*
 * CR: Investment Work
 * Developer: Sharath Prasanna
 * Enhancement: Cloning Investment Work record
 * Date: 17th September 2018
 * 
*/ 
public class IW_CloneInvestmentRecord 
{
	public IW_CloneInvestmentRecord() 
	{
		
	}

	@AuraEnabled
    public static String cloneRecord(Id recordId)
    {
    	PSA_Common_Setting__mdt cloneFieldList =[select Value_Long__c from PSA_Common_Setting__mdt where Name__c = 'IWCloneFields' limit 1];
    	String message;
    	if(cloneFieldList.Value_Long__c != null)
    	{	

    		try
    		{

	    		String fieldList = cloneFieldList.Value_Long__c;
	    		String query = 'Select ' + cloneFieldList.Value_Long__c + ' from Investment_Workbox__c where Id = :recordId limit 1';

	    		Investment_Workbox__c recordToClone = Database.query(query);
	    		Investment_Workbox__c newRecord = new Investment_Workbox__c();
	    		string fieldType;
	    		String fieldNameTrimmed;
	    		for(String fieldName :fieldList.split(','))
	    		{	    		

	    			fieldNameTrimmed = fieldName.trim();
		            newRecord.put(fieldNameTrimmed, recordToClone.get(fieldNameTrimmed));					
	    		}
                newRecord.put('IW_Modify__c', true);
	    		insert newRecord;
	    		message = 'SUCCESS:'+newRecord.Id;
    		}
    		catch(Exception e)
    		{

    			message = 'Error: ' + e.getMessage();
    		}

    	}
    	else
    	{
    		message = 'Error: Custom Setting Missing' ;	
    	}
    	return message;
    }

}