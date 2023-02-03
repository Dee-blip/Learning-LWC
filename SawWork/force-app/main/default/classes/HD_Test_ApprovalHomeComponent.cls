/*
Template: Apex Test Class/Trigger Template

CopyRight: Hemant Kumar @ Akamai Technologies Ltd.

Version: 1.0

Created Date : Feb 27 2015

Base Line : used as a apart of requirment for Approval Visual force Home page component, Unit Test

Purpose : an Unit Test for Controller Items for approval
          
Usage : used as an test for the business logic , for Component Controller Approval
          
Test Class Asssociated : NONE

Controller (Boolean): true

Page Used/Asssociated (default -> NONE) : ServiceRequestdetail

Trigger Associated : NONE
Class Associated : [ HDApprovalHomeComponent ]
* Modification Log ===============================================================
* Date 				      Author 				      Modification
* Aug 08th, 2020    Aneesh Budnar       PRTORES-1810 - Code scanner fixes
*/
@isTest
private class HD_Test_ApprovalHomeComponent
{
//Global variable 
private static Map<String,String> urgencymap = new Map<String,String>();
private static Map<String,String> impactmap = new Map<String,String>();
private static Map<String,String> cattypemap = new Map<String,String>();
private static Map<String,String> parent_category = new Map<String,String>();
private static Map<String,String> child_category = new Map<String,String>();
private static Map<String,String> stagemap = new Map<String,String>();
private static Map<String,String> statusmap = new Map<String,String>();

static{

    //default data initialization
    List<String> urgencyname = new List<String>{'Severity 1','Severity 2','Severity 3','Severity 4'};
    List<String> impactname = new List<String>{'LOW'};
    List<String> cattypeNames = new List<String>{'Q_ABI-DEV','Q_COGS_IT','Q_Corporate_DataCenter','Q_CORP_SVC','Q_CORP_SVC_BLR','Q_DBA','Q_EAE_OPS','Q_Entsec','Q_HELPDESK_HARDWARE','Q_HELPDESK_MALWARE','Q_HELPDESK_TELECOM','Q_HELPDESK_TRIAGE','Q_HYPERION_ADMIN','Q_ITOC','Q_ITOC_Alerts','Q_ITOC_TEST','Q_ITOC_TEST3','Q_IT_HR_APPS','Q_Legal_IP','Q_Legal_Marketing Review','Q_Legal_Network','Q_Legal_Procurement','Q_Legal_Vendor','Q_Messaging','Q_NETSTATSENGINE_IT','Q_Network Engineering','Q_Network_IDF','Q_ORACLE_APPS','Q_SI','Q_SI_OPS','Q_UNIVERSITY'};
    List<String> stagenames = new List<String>{'Opened','Acknowledged','In Process','Closed'};

    //urgency
    urgencymap  = HD_Test_Remedyforce_TestDataFactory.createUrgency(urgencyname);
    //impact
    impactmap = HD_Test_Remedyforce_TestDataFactory.createImpact(impactname);
    //category type
    cattypemap = HD_Test_Remedyforce_TestDataFactory.createcategorytype(cattypeNames);
    //Sysstage creation
    stagemap = HD_Test_Remedyforce_TestDataFactory.createStageSys(stagenames);

   //Creating a Status
    List<BMCServiceDesk__Status__c> statList = new List<BMCServiceDesk__Status__c>();
    //UNassigned status
    BMCServiceDesk__Status__c status_unassigned = new BMCServiceDesk__Status__c(Name='UNASSIGNED',BMCServiceDesk__FKSYSStage__c=stagemap.get('Opened'),BMCServiceDesk__defaultStatus__c=true,BMCServiceDesk__appliesToIncident__c=true,BMCServiceDesk__appliesToProblem__c=false,BMCServiceDesk__appliesToTask__c=true);
    statList.add(status_unassigned);
    BMCServiceDesk__Status__c status_riskanalysis = new BMCServiceDesk__Status__c(Name='RISK ANALYSIS',BMCServiceDesk__FKSYSStage__c=stagemap.get('In Process'),BMCServiceDesk__defaultStatus__c=false,BMCServiceDesk__appliesToIncident__c=false,BMCServiceDesk__appliesToProblem__c=true,BMCServiceDesk__appliesToTask__c=false);
    statList.add(status_riskanalysis);
    
    statusmap = HD_Test_Remedyforce_TestDataFactory.createStatus(statList);

    List<BMCServiceDesk__Category__c>  parent_catList = new List<BMCServiceDesk__Category__c>();
    //creating parent category
    BMCServiceDesk__Category__c telecomcat =  new BMCServiceDesk__Category__c(Name='Telecom',BMCServiceDesk__FKCategoryType__c=cattypemap.get('Q_HELPDESK_TRIAGE'),BMCServiceDesk__AvailableForIncidents__c=true,BMCServiceDesk__Display_In_SelfService__c=true);
    parent_catList.add(telecomcat);

    //creating parent category
    BMCServiceDesk__Category__c hardwarecat =  new BMCServiceDesk__Category__c(Name='Hardware',BMCServiceDesk__FKCategoryType__c=cattypemap.get('Q_HELPDESK_HARDWARE'),BMCServiceDesk__AvailableForIncidents__c=true,BMCServiceDesk__Display_In_SelfService__c=true);
    parent_catList.add(hardwarecat);

    //adding parent category
    parent_category =  HD_Test_Remedyforce_TestDataFactory.createCategory(parent_catList);

    //Creating Child Cat List
    List<BMCServiceDesk__Category__c>  child_catList = new List<BMCServiceDesk__Category__c>();
    BMCServiceDesk__Category__c UNIX_childcat =  new BMCServiceDesk__Category__c(Name='UNIX',BMCServiceDesk__FKCategoryType__c=cattypemap.get('Q_HELPDESK_HARDWARE'),BMCServiceDesk__AvailableForIncidents__c=true,BMCServiceDesk__Display_In_SelfService__c=true,BMCServiceDesk__FKParentCategory__c=parent_category.get('Hardware'));
    child_catList.add(UNIX_childcat);

    //adding the child cat list 
    child_category = HD_Test_Remedyforce_TestDataFactory.createCategory(child_catList); 

    //populating custom setting used for new old trigger
    Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
   System.debug('decribe ---'+gd.containsKey('HD_RF_TRIGGER_FLAG__c'));
   if(gd.containsKey('HD_RF_TRIGGER_FLAG__c'))
   {
     List<HD_RF_TRIGGER_FLAG__c>  rfList =  new List<HD_RF_TRIGGER_FLAG__c>();
     HD_RF_TRIGGER_FLAG__c  HD_RemedyForceCustomizations = new HD_RF_TRIGGER_FLAG__c(Name='HD_RemedyForceCustomizations',Enable__c=true,Information__c='This is Old trigger');
     rfList.add(HD_RemedyForceCustomizations);
     HD_RF_TRIGGER_FLAG__c  HD_RemedyForceCustomization_Tri = new HD_RF_TRIGGER_FLAG__c(Name='HD_RemedyForceCustomization_Tri',Enable__c=false,Information__c='This is new trigger');
     rfList.add(HD_RemedyForceCustomization_Tri);
     //Inserting 
     insert rfList; 

   }//

    //adding dataload custom setting added by Bhaskar verma 
    Group grp = [SELECT Id FROM GROUP WHERE Name = 'Default Queue' LIMIT 1];
    if(grp != null) {
        HD_DataLoad__c dl = new HD_DataLoad__c();
        dl.TextValue__c = grp.Id;
        dl.name = 'Triage_Team';
        insert dl;
    }
}//static


static testMethod void ApprovalHomeComponent()
{
PageReference pagerf = Page.HDApprovalHomeComponent;
Test.setCurrentPage(pagerf);

    //inserting an incident
       List<BMCServiceDesk__Incident__c> incidents =  HD_Test_Remedyforce_TestDataFactory.incidentTestData(2,child_category.get('UNIX'),urgencymap.get('Severity 3'),impactmap.get('LOW'));
       insert incidents;

      //
      HDApprovalHomeComponent histcomp = new HDApprovalHomeComponent();

       try {
      //submitting the record for approval
      Approval.ProcessSubmitRequest req1 =  new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval.');
        req1.setObjectId(histcomp.loggedInUser);
      Approval.ProcessResult result = Approval.process(req1);  
       }//
      catch(Exception e)
      {
        Boolean expectedExceptionThrown =  e.getMessage().contains('NO_APPLICABLE_PROCESS,') ? true : false;
        System.AssertEquals(expectedExceptionThrown, true);  
      } //

    histcomp.getApprovaldetails();

}//static testMethod void ApprovalHomeComponent()
	
}//END