/**
 * =========================
 * Developer        Date        Description

   Sausharm      23/Oct/18     SFDC-3673 Initial version : Controller for MoveAll button page on DSRs on Opportunity
 **/

public class GSM_Controller_DSRMoveAll 
{

	@AuraEnabled
	public static list<Opportunity> searchOpportunity(String nameString,String existingOppId)
	{
		String searchString = nameString+'%';
		return [select id,Name from Opportunity where name LIKE :searchString and id!= :existingOppId];
	}

	@AuraEnabled
	public static String getDSRCount(String existingOppId)
	{
		return String.valueof( getListOfDSRForOpportunity(existingOppId).size());
	}
	@AuraEnabled
	public static String moveAllDSRbyOpportunity(String existingOppId, String newOpportunityId)
	{
		try
		{
			List<Deal_Support_Request__c> listOfDSRtoUpdate = getListOfDSRForOpportunity(existingOppId);
			for (Deal_Support_Request__c dsr : listOfDSRtoUpdate)
			{
				dsr.Opportunity__c = Id.valueof(newOpportunityId);
			}
			update listOfDSRtoUpdate;
			return '';
		}
		catch(Exception e)
		{
			return 'Error: '+e.getMessage();
		}

	}

	private static List<Deal_Support_Request__c> getListOfDSRForOpportunity(String oppId)
	{
		List<Deal_Support_Request__c> listOfDSR = new List<Deal_Support_Request__c>();
		for (Deal_Support_Request__c dsr : [select id,Opportunity__c from Deal_Support_Request__c where Opportunity__c = :oppId])
		{
			listOfDSR.add(dsr);
		}
		return listOfDSR;
	}

}