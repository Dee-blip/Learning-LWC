/*
 * CR: FFPSA-238
 * Developer: Sharath Prasanna
 * Enhancement: Clone a test record
 * Date: 5th August 2017
 * 
*/ 
global class PSA_CloneTestRecords 
{
	@AuraEnabled
	public static String callClone(Id testId)
	{
		return cloneTestRecord(testId);	
	} 
	webservice static String cloneTestRecord(String testRecordId)
	{
		Test__c clonedRecord = new Test__c();
		String returnString;
		List<Test__c> parentRecord = new List<Test__c>();
		parentRecord = [select Test_Date_Time__c,Engagement__c,Estimated_Test_Duration__c,Deliverable__c,Test_date_TBD__c,Report_Required__c,Testing_PE_multi__c,Known_Issues_and_Errors__c,Testing_Environment__c,Goals__c,Type_of_test__c,Notes__c,Num_of_Virtual_Users__c,Scripting_Environment__c from Test__c where id = :testRecordId];		
		if(parentRecord != null && !parentRecord.isEmpty())
		{
			clonedRecord.Test_Date_Time__c = parentRecord[0].Test_Date_Time__c;
			clonedRecord.Engagement__c = parentRecord[0].Engagement__c;
			clonedRecord.Estimated_Test_Duration__c = parentRecord[0].Estimated_Test_Duration__c;
			clonedRecord.Deliverable__c = parentRecord[0].Deliverable__c;
			clonedRecord.Test_date_TBD__c	 = parentRecord[0].Test_date_TBD__c;
			clonedRecord.Report_Required__c = parentRecord[0].Report_Required__c;
			clonedRecord.Testing_PE_multi__c = parentRecord[0].Testing_PE_multi__c;
			clonedRecord.Known_Issues_and_Errors__c = parentRecord[0].Known_Issues_and_Errors__c;
			clonedRecord.Testing_Environment__c = parentRecord[0].Testing_Environment__c;
			clonedRecord.Goals__c = parentRecord[0].Goals__c;
			clonedRecord.Type_of_test__c = parentRecord[0].Type_of_test__c;
			clonedRecord.Notes__c = parentRecord[0].Notes__c;
			clonedRecord.Num_of_Virtual_Users__c = 	parentRecord[0].Num_of_Virtual_Users__c;
			clonedRecord.Scripting_Environment__c = parentRecord[0].Scripting_Environment__c;
			try
			{
				insert clonedRecord;	
			}
			catch (Exception e)
			{
				returnString =  'Exception: ' + e.getMessage();	
			}
			if(clonedRecord.id != null)
			{
				returnString = clonedRecord.id;
			}
		}
		return returnString;
	}
}