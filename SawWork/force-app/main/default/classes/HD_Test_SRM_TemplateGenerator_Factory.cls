/*
Template: Apex Test Class/Trigger Template

CopyRight: Hemant Kumar @ Akamai Technologies Ltd.

Version: 1.0

Created Date : 

Base Line : used as a apart of requirment for SRM template Generator, Unit Test

Purpose : an Unit Test for Class 'HD_SRM_TemplateGenerator_Factory.cls'

Usage : used as an test for the business logic 

Test Class Asssociated : NONE

Controller (Boolean): false

Page Used/Asssociated (default -> NONE) : NONE

Trigger Associated : none
Class controller Associated : HD_SRM_TemplateGenerator_Factory.cls

 */
/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest(SeeAllData=false)
private class HD_Test_SRM_TemplateGenerator_Factory
{

	public static Map<String,Id> result;
	public static Map<String,Id> categoriesCreated;
	public static User contextUser;

	static{
		/*
		 *@LastModifiedBy: Nikhil Karn
		 *@ModificationReason: added this lines to load service request test data factory.
		 */
		contextUser=[SELECT Id, PermissionSet.Name,AssigneeId,Assignee.HD_View_Helpdesk_Confidential_Data__c FROM PermissionSetAssignment where PermissionSet.Name = 'HD_HR_View_Encrypted_data_permission' and Assignee.HD_View_Helpdesk_Confidential_Data__c = true and Assignee.isActive = true limit 1].Assignee;
		HD_TestDataFactory_ServiceRequest.FulfilmentInputWrapperClass tempList=new HD_TestDataFactory_ServiceRequest.FulfilmentInputWrapperClass();
		List<HD_TestDataFactory_ServiceRequest.FulfilmentInputWrapperClass> fulfilmentInputLists=new List<HD_TestDataFactory_ServiceRequest.FulfilmentInputWrapperClass>();
		tempList.order='1';
		tempList.responseType='Text Area';
		tempList.prompt='Host Name';
		tempList.required='FALSE';
		tempList.hidden='FALSE';
		tempList.inputValuesHolder='upguard.akamai.com?upguard.akamai.com?false'; 
		tempList.runWorkflow='TRUE';

		fulfilmentInputLists.add(tempList);

		HD_Test_Data_Factory.init();
		categoriesCreated = HD_Test_Data_Factory.categoryMap;
		System.debug(categoriesCreated);

		result=HD_TestDataFactory_ServiceRequest.setUpServiceRequest('testName18','testTitle18',categoriesCreated.get('Compensation'),fulfilmentInputLists,'nkarn@akamai.com',true,HD_IncidentTestDataFactory.Team.HR);
		System.debug('RESULT========'+result);
	}

	@isTest
	static void positivTEstCase()
	{
		//getting Payroll Category 
		BMCServiceDesk__Category__C category = [ Select id,Name from BMCServiceDesk__Category__c where  Name  = 'Access' limit 1 ];

		String jsonstr = '{'+
				'"RequestdefinitionName": "Test Payroll Template",'+
				'"ServiceRequestTitle": "Test Payroll Template",'+
				'"CategoryID": "'+category.id+'",'+
				'"Description": "HR payroll System",'+
				'"BusinessServiceName": "Test Identity & Access Management",'+
				'"ServiceOfferingName": "Test Access offering",'+
				'"Online": "TRUE",'+
				'"ApprovalRequired": "FALSE",'+
				'"UserInstructions": "This is HR Service request created using Script",'+
				'"fulfillmentInputs": [{'+
				'"order": "1",'+
				'"ResponseType": "Picklist",'+
				'"Prompt": "Region",'+
				'"Required": "TRUE",'+
				'"Hidden": "FALSE",'+
				'"Run_workflow": "TRUE",'+
				'"Input_Values_holder": "US/Americas?US/Americas?false*APJ?APJ?false*EMEA?EMEA?false*India?India?false"'+
				'}'+
				']'+
				'}';

		HD_SRM_TemplateGenerator_Factory tf = new HD_SRM_TemplateGenerator_Factory();
		tf.SRMServiceRequestFROMJSON(jsonstr);

	}//
}