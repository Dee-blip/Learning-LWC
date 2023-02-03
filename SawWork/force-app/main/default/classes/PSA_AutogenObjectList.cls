/*
 * CR: FFPSA-271
 * Developer: Sharath Prasanna
 * Enhancement: Automated creation of projects: This is the interface which the individual products class will implement
 * Date: 27th March 2018
 *  A wrapper class to create and insert records
 */ 
public class PSA_AutogenObjectList 
{
	public PSA_AutogenObjectList() 
	{
		casesForUpsert = new List<case>();	
		projectsForUpsert = new List<pse__Proj__c>();
		milestonesForUpsert = new List<pse__Milestone__c>() ;
		budgetsForUpsert = new List<pse__Budget__c>() ;
		productsForUpsert = new List<pse__Project_Methodology__c>() ;
		pcaForUpsert = new List<Project_Case_Association__c>();
		assignmentsForUpsert = new List<pse__Assignment__c>();
		schedulesForUpsert = new List<pse__Schedule__c>();
		renewedProjectsIds = new Set<Id>();
	}
	public List<Case> casesForUpsert;
	public List<pse__Proj__c> projectsForUpsert;
	public List<pse__Milestone__c> milestonesForUpsert;
	public List<pse__Budget__c> budgetsForUpsert;
	public List<pse__Project_Methodology__c> productsForUpsert;
	public List<Project_Case_Association__c> pcaForUpsert;
	public List<pse__Assignment__c> assignmentsForUpsert;
	public List<pse__Schedule__c> schedulesForUpsert;
	public Set<Id> renewedProjectsIds;
	
}