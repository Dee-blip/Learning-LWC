/*
 * CR: FFPSA-266
 * Developer: Sharath Prasanna
 * Enhancement: Automated creation of projects: This is the interface which the individual products class will implement
 * Date: 24th October 2017
 * 
 * Changes by Sharath Prasanna: Updating the interface: Adding another method to the 
 * interface which returns object of type PSA_AutogenObjectList
 */ 
public interface PSA_AutogenInterface 
{
	//The method which gets the contract list and filters them out based on the creation criteria
	void getContractDetails(List<Merge_Contract_Header__c> ListContractScope,List<Merge_Contract_Detail__c> ListContractDetailstoCheck,List<Case> CasesCreated,List<Project_Case_Association__c> projectCases);
	//The method which creates the projects for the valid contract and contract details 
	void CreateProjects(Map<Id,List<Merge_Contract_Detail__c>> mapContractContractDetails,List<Case> cases);

	//The method which gets the contract list and filters them out based on the creation criteria 
	//and returns the list of objects to be upserted to the parent class
	PSA_AutogenObjectList getContractDetailsForUpsert(List<Merge_Contract_Header__c> ListContractScope,List<Merge_Contract_Detail__c> ListContractDetailstoCheck,List<Case> CasesCreated,List<Project_Case_Association__c> projectCases,Map<String,pse__Proj__c> templates);
}