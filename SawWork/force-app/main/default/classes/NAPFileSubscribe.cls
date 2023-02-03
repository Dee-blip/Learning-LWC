/**  
  Sonali Tandon 	SFDC- 1201 NAP -- Implement File Subscribe functionality -  4th Oct 2016 - NAPFileSubscribe is a helper class to get NAP File Subscription details. 

 **/

public class NAPFileSubscribe {


	private List<NAP_File_Subscribe__c> listOfFileSubscriptionDetails;
	private List<Id> listOfContentDocumentIds;

	public NAPFileSubscribe(List<ContentVersion> cvList)
	{
		listOfContentDocumentIds = new List<Id>();
		for(ContentVersion cv : cvList)
		{
			listOfContentDocumentIds.add(cv.ContentDocumentId);
		}

		listOfFileSubscriptionDetails = [Select Id,Content_Document_Id__c, Active_subscription__c, User__c from NAP_File_Subscribe__c
			where User__c =: System.UserInfo.getUserId() AND Content_Document_Id__c IN :listOfContentDocumentIds];

	}

	public  Map<Id,Boolean> getActiveSubscriptionFlags()
	{
		// initialize 
		Map<Id,Boolean> mapOfContentDocumentIdToActiveSubscription = new Map<Id,Boolean>();
		for(Id documentId : listOfContentDocumentIds)
		{
			mapOfContentDocumentIdToActiveSubscription.put(documentId,false);
		}

		for(NAP_File_Subscribe__c fileSubscribeObj  : listOfFileSubscriptionDetails)
		{
			if(fileSubscribeObj.Active_subscription__c)
				mapOfContentDocumentIdToActiveSubscription.put(Id.valueOf(fileSubscribeObj.Content_Document_Id__c),fileSubscribeObj.Active_subscription__c);
		}

		return mapOfContentDocumentIdToActiveSubscription;

	}

	
}