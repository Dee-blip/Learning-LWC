/*
 Author: Jayalakshmi A & Sharath K
 Description: Contains all methods that are invoked from Custom Buttons from CSAT Page Layouts. CR# 1416592,1430119
 Created Date: 12/01/2011
 */

global class CS_CustomButtonMethods 
{
	/*
     Author : Jayalakshmi A
     Description: This method deletes the Survey Account given the Survey Account Id and returns the 3 digit Id for the Survey Account tab. CR# 1416592
     Created Date: 12/1/2011
    */
	webservice static String deleteSurveyAccount(String surveyAccId)
	{
		 CS_SurveyAccount__c surveyAccount = new CS_SurveyAccount__c();
		 try
		 {
			 surveyAccount = [select Id from CS_SurveyAccount__c where Id = :surveyAccId];
			 delete surveyAccount;
			 
			 String tempPrefix;
			 Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe(); 
			 Map<String,String> keyPrefixMap = new Map<String,String>{};
			 Set<String> keyPrefixSet = gd.keySet();
			 for(String sObj : keyPrefixSet)
			 {
				 Schema.DescribeSObjectResult r =  gd.get(sObj).getDescribe();
				 String tempName = r.getName();
				 if(tempName == 'CS_SurveyAccount__c')
				 {
				 	tempPrefix = r.getKeyPrefix();
				 	return tempPrefix;
				 }
			 }			  
		 }
		 
		 catch(Exception e)
	     {
	    	CS_SurveyException__c exception1 = new CS_SurveyException__c();
	    	exception1.CS_ExceptionInObject__c = 'CS_SurveyAccount__c';
	    	exception1.CS_ExceptionMessage__c = e.getMessage();
	    	exception1.CS_ErrorRecordId__c = surveyAccount.Id;
	    	insert exception1;
	     }
	     return '';
	}
	
	/*
     Author : Jayalakshmi A
     Description: This method deletes the Survey Contact given the Survey Contact Id and returns the 3 digit Id for the Survey Contact tab. CR# 1416592
     Created Date: 12/1/2011
    */
	webservice static String deleteSurveyContact(String surveyConId)
	{
		CS_SurveyContacts__c surveyContact = new CS_SurveyContacts__c();
		 try
		 {
			 surveyContact = [select Id from CS_SurveyContacts__c where Id = :surveyConId];
			 delete surveyContact;
			 
			 String tempPrefix;
			 Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe(); 
			 Map<String,String> keyPrefixMap = new Map<String,String>{};
			 Set<String> keyPrefixSet = gd.keySet();
			 for(String sObj : keyPrefixSet)
			 {
				 Schema.DescribeSObjectResult r =  gd.get(sObj).getDescribe();
				 String tempName = r.getName();
				 if(tempName == 'CS_SurveyContacts__c')
				 {
				 	tempPrefix = r.getKeyPrefix();
				 	return tempPrefix;
				 }
			 }		 
		 }
		 
		 catch(Exception e)
	     {
	    	CS_SurveyException__c exception1 = new CS_SurveyException__c();
	    	exception1.CS_ExceptionInObject__c = 'CS_SurveyContacts__c';
	    	exception1.CS_ExceptionMessage__c = e.getMessage();
	    	exception1.CS_ErrorRecordId__c = surveyContact.Id;
	    	insert exception1;
	     }
	     return '';
	}
	/*
     Author : Sharath
     Description:CR 1430119- This method associates an account to the latest survey account record
     Created Date: 12/1/2011
    */
	webservice static void associateSurveyAccount(String surveyAccId)
	{
		Account acc = new Account();
		try{
		String accountId = [select CS_Account__c from CS_SurveyAccount__c where Id = :surveyAccId].CS_Account__c;
		acc = [select Id, CS_SurveyAccount__c,Validation_Override__c from Account where Id = :accountId];
		acc.CS_SurveyAccount__c = surveyAccId;
		acc.Validation_Override__c = true;
		update acc;
		}
		catch(Exception e)
	     {
	    	CS_SurveyException__c exception1 = new CS_SurveyException__c();
	    	exception1.CS_ExceptionInObject__c = 'Accounts';
	    	exception1.CS_ExceptionMessage__c = e.getMessage();
	    	exception1.CS_ErrorRecordId__c = acc.Id;
	    	insert exception1;
	     }
	}
	/*
     Author : Sharath
     Description:CR 1430119- This method associates a contact and a survey contact. Also marks the currently surveyed flag = true
     Created Date: 12/1/2011
    */
	webservice static void associateSurveyContact(String surveyConId)
	{
		Contact con = new Contact();
		try{
			String contactId = [select Id,CS_Contact__c from CS_SurveyContacts__c where Id = :surveyConId].CS_Contact__c;
			con = [select Id, CS_AssociatedSurveyContact__c,CS_CurrentlySurveyed__c,Validation_Override__c from Contact where Id = :contactId];
			con.CS_AssociatedSurveyContact__c = surveyConId;
			con.Validation_Override__c = true;
			con.CS_CurrentlySurveyed__c = true;
			update con;
		}
		catch(Exception e)
	     {
	    	CS_SurveyException__c exception1 = new CS_SurveyException__c();
	    	exception1.CS_ExceptionInObject__c = 'Contacts';
	    	exception1.CS_ExceptionMessage__c = e.getMessage();
	    	exception1.CS_ErrorRecordId__c = con.Id;
	    	insert exception1;
	     }
	}
	
	/*
     Author : Sharath
     Description:CR 1430119- This method removes the association between a contact and a survey contact Id. Also marks the currently surveyed flag = false 
     Created Date: 12/1/2011
    */
	webservice static void removeSurveyContactAssociation(String surveyConId)
	{
		Contact con = new Contact();
		try{
			String contactId = [select Id,CS_Contact__c from CS_SurveyContacts__c where Id = :surveyConId].CS_Contact__c;
			con = [select Id, CS_AssociatedSurveyContact__c,CS_CurrentlySurveyed__c,Validation_Override__c from Contact where Id = :contactId];
			con.CS_AssociatedSurveyContact__c = null;
			con.Validation_Override__c = true;
			con.CS_CurrentlySurveyed__c = false;
			update con;
		}
		catch(Exception e)
	     {
	    	CS_SurveyException__c exception1 = new CS_SurveyException__c();
	    	exception1.CS_ExceptionInObject__c = 'Contacts';
	    	exception1.CS_ExceptionMessage__c = e.getMessage();
	    	exception1.CS_ErrorRecordId__c = con.Id;
	    	insert exception1;
	     }
	}
	
	/*
     Author : Sharath
     Description:CR 1430119- This method removes the association between an account and a survey account record
     Created Date: 12/1/2011
    */
	webservice static void removeSurveyAccountAssociation(String surveyAccId)
	{
		Account acc = new Account();
		try{
			String accountId = [select CS_Account__c from CS_SurveyAccount__c where Id = :surveyAccId].CS_Account__c;
			acc = [select Id, CS_SurveyAccount__c,Validation_Override__c from Account where Id = :accountId];
			acc.CS_SurveyAccount__c = null;
			acc.Validation_Override__c = true;
			update acc;
		}
		catch(Exception e)
	     {
	    	CS_SurveyException__c exception1 = new CS_SurveyException__c();
	    	exception1.CS_ExceptionInObject__c = 'Accounts';
	    	exception1.CS_ExceptionMessage__c = e.getMessage();
	    	exception1.CS_ErrorRecordId__c = acc.Id;
	    	insert exception1;
	     }
	}
}