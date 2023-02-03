@isTest
public with sharing class Wizards_IdeaEmailTestClass {
	
	public static IdeaEmail__c objIdeaEmail;

	public static testMethod void testIdeaEmailCreation() {
		objIdeaEmail = WizardsInitData.createIdeaEmail();
		IdeaEmail__c tmpIdeaEmail = [Select Id from IdeaEmail__c where Id = :objIdeaEmail.Id];
		System.assert(tmpIdeaEmail.Id != null);
	}
}