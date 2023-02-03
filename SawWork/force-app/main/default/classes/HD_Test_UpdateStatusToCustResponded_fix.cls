/* Notify assigned staff whenever client replies to the mail received via �Email Conversation� feature.    
- The status of the associated Incident should change to �Customer responded�.
*/

/* 
Last Modified as a part of CR 2688114 - Fixing Test Classes for Validation Rule- Description should not be
Developer@ Hemant Kumar
Comment : Whole Test class Modification , Wrong test method logic was written
/*
* File Name: HD_Test_UpdateStatusToCustResponded_fix
* Description : Test class status update status of the associated Incident to Customer responded
* @author : Abhishek Singh
* Modification Log ===============================================================
* Date Author Modification
* 5 Aug 2020 line 218-225 Remove the hardcode Id Abhishek Singh PRTORES-1811 - HD code scan 2020 - Blocker and critical part 5
*/

@isTest(seealldata=false)
Public class HD_Test_UpdateStatusToCustResponded_fix
{
 
 //Global variable 
private static Map<String,String> urgencymap = new Map<String,String>();
private static Map<String,String> impactmap = new Map<String,String>();
private static Map<String,String> cattypemap = new Map<String,String>();
private static Map<String,String> parent_category = new Map<String,String>();
private static Map<String,String> child_category = new Map<String,String>();
private static Map<String,String> stagemap = new Map<String,String>();
private static Map<String,String> statusmap = new Map<String,String>();
private static Map<String,String> actionsmap = new Map<String,String>();

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

    
     //Insert Status List
     MAP<String,String> status_map = HD_Test_Remedyforce_TestDataFactory.insertAllStatus();

   /*
   //Creating a Status
    List<BMCServiceDesk__Status__c> statList = new List<BMCServiceDesk__Status__c>();
    //UNassigned status
    BMCServiceDesk__Status__c status_unassigned = new BMCServiceDesk__Status__c(Name='UNASSIGNED',BMCServiceDesk__FKSYSStage__c=stagemap.get('Opened'),BMCServiceDesk__defaultStatus__c=true,BMCServiceDesk__appliesToIncident__c=true,BMCServiceDesk__appliesToProblem__c=false,BMCServiceDesk__appliesToTask__c=true,BMCServiceDesk__state__c = false);
    statList.add(status_unassigned);
    BMCServiceDesk__Status__c status_customerresponded = new BMCServiceDesk__Status__c(Name='CUSTOMER RESPONDED',BMCServiceDesk__FKSYSStage__c=stagemap.get('In Process'),BMCServiceDesk__defaultStatus__c=false,BMCServiceDesk__appliesToIncident__c=true,BMCServiceDesk__appliesToProblem__c=true,BMCServiceDesk__appliesToTask__c=true);
    statList.add(status_customerresponded);
    BMCServiceDesk__Status__c status_assigned = new BMCServiceDesk__Status__c(Name='ASSIGNED',BMCServiceDesk__FKSYSStage__c=stagemap.get('Opened'),BMCServiceDesk__defaultStatus__c=true,BMCServiceDesk__appliesToIncident__c=true,BMCServiceDesk__appliesToProblem__c=false,BMCServiceDesk__appliesToTask__c=true,BMCServiceDesk__state__c = false);
    statList.add(status_assigned);
    BMCServiceDesk__Status__c status_closed = new BMCServiceDesk__Status__c(Name='CLOSED',BMCServiceDesk__FKSYSStage__c=stagemap.get('In Process'),BMCServiceDesk__defaultStatus__c=false,BMCServiceDesk__appliesToIncident__c=true,BMCServiceDesk__appliesToProblem__c=true,BMCServiceDesk__appliesToTask__c=true);
    statList.add(status_closed);
    BMCServiceDesk__Status__c status_inprogress = new BMCServiceDesk__Status__c(Name='IN PROGRESS',BMCServiceDesk__FKSYSStage__c=stagemap.get('Opened'),BMCServiceDesk__defaultStatus__c=true,BMCServiceDesk__appliesToIncident__c=true,BMCServiceDesk__appliesToProblem__c=false,BMCServiceDesk__appliesToTask__c=true,BMCServiceDesk__state__c = false);
    statList.add(status_inprogress);
    BMCServiceDesk__Status__c status_resolved = new BMCServiceDesk__Status__c(Name='RESOLVED',BMCServiceDesk__FKSYSStage__c=stagemap.get('In Process'),BMCServiceDesk__defaultStatus__c=false,BMCServiceDesk__appliesToIncident__c=true,BMCServiceDesk__appliesToProblem__c=true,BMCServiceDesk__appliesToTask__c=true);
    statList.add(status_resolved);
    BMCServiceDesk__Status__c status_wiating4resp = new BMCServiceDesk__Status__c(Name='WAITING FOR RESPONSE',BMCServiceDesk__FKSYSStage__c=stagemap.get('In Process'),BMCServiceDesk__defaultStatus__c=false,BMCServiceDesk__appliesToIncident__c=true,BMCServiceDesk__appliesToProblem__c=true,BMCServiceDesk__appliesToTask__c=true);
    statList.add(status_wiating4resp);

    statusmap = HD_Test_Remedyforce_TestDataFactory.createStatus(statList);
    */
    //creating Actions
    List<BMCServiceDesk__Action__c> actionList = new List<BMCServiceDesk__Action__c>();
    

    

    List<BMCServiceDesk__Category__c>  parent_catList = new List<BMCServiceDesk__Category__c>();
    //creating parent category
    BMCServiceDesk__Category__c adddesktop =  new BMCServiceDesk__Category__c(Name='Additional Desktop/Laptop',BMCServiceDesk__FKCategoryType__c=cattypemap.get('Q_HELPDESK_TRIAGE'),BMCServiceDesk__AvailableForIncidents__c=true,BMCServiceDesk__Display_In_SelfService__c=true);
    parent_catList.add(adddesktop);

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


}//static


//creating a function to insert Custom Settings, this function is limited to this class
private static testmethod void utilFunc()
{    
    ////inserting Custom settings HD_DEFAULT_CATEGORY__c
     List<HD_DEFAULT_CATEGORY__c>  defaultcat = new List<HD_DEFAULT_CATEGORY__c>();
     HD_DEFAULT_CATEGORY__c dc1 = new HD_DEFAULT_CATEGORY__c(Name='Additional Desktop/Laptop',Category_Name__c='Additional Desktop/Laptop');
     HD_DEFAULT_CATEGORY__c dc2 = new HD_DEFAULT_CATEGORY__c(Name='Corporate Services',Category_Name__c='Corporate Services');
     HD_DEFAULT_CATEGORY__c dc3 = new HD_DEFAULT_CATEGORY__c(Name='New Hire Onboarding',Category_Name__c='New Hire Onboarding');
     HD_DEFAULT_CATEGORY__c dc4 = new HD_DEFAULT_CATEGORY__c(Name='Telecom',Category_Name__c='Telecom');
     HD_DEFAULT_CATEGORY__c dc5 = new HD_DEFAULT_CATEGORY__c(Name='Hardware',Category_Name__c='Hardware');
     HD_DEFAULT_CATEGORY__c dc6 = new HD_DEFAULT_CATEGORY__c(Name='Parent-New Hire Onboarding',Category_Name__c='Parent-New Hire Onboarding');
     HD_DEFAULT_CATEGORY__c dc7 = new HD_DEFAULT_CATEGORY__c(Name='Child1-New Hire Onboarding',Category_Name__c='Child1-New Hire Onboarding');
     HD_DEFAULT_CATEGORY__c dc8 = new HD_DEFAULT_CATEGORY__c(Name='Child2-Telecom_New Hire',Category_Name__c='Child2-Telecom_New Hire');
     HD_DEFAULT_CATEGORY__c dc9 = new HD_DEFAULT_CATEGORY__c(Name='Child3-Cor_service',Category_Name__c='Child3-Cor_service');
     HD_DEFAULT_CATEGORY__c dc10 = new HD_DEFAULT_CATEGORY__c(Name='Desktop/Laptop',Category_Name__c='Desktop/Laptop');
     HD_DEFAULT_CATEGORY__c dc11 = new HD_DEFAULT_CATEGORY__c(Name='Hardware -> Linux',Category_Name__c='Hardware -> Linux');

     defaultcat.add(dc1);
     defaultcat.add(dc2);
     defaultcat.add(dc3);
     defaultcat.add(dc4);
     defaultcat.add(dc5);
     defaultcat.add(dc6);
     defaultcat.add(dc7);
     defaultcat.add(dc8);
     defaultcat.add(dc9);
     defaultcat.add(dc10);
     defaultcat.add(dc11);


     insert defaultcat;
     
      SI_Status__c sistatus = new SI_Status__c();
      sistatus.Name = 'SIStatus' ;
      sistatus.Status__c = 'IMPACT MITIGATED,CLOSED,RESOLVED';
      insert sistatus;

     //Inserting HD Ticket Priority-Urgency Map 
     List<HD_Ticket_Priority__c>  Ticket_Priority = new List<HD_Ticket_Priority__c>();
     HD_Ticket_Priority__c hdtp1 = new HD_Ticket_Priority__c(Name='1',Priority_Name__c='1',Urgency_Id__c= urgencymap.get('Severity 1'),Urgency_Name__c='Severity 1');
     HD_Ticket_Priority__c hdtp2 = new HD_Ticket_Priority__c(Name='2',Priority_Name__c='2',Urgency_Id__c= urgencymap.get('Severity 2'),Urgency_Name__c='Severity 2');
     HD_Ticket_Priority__c hdtp3 = new HD_Ticket_Priority__c(Name='3',Priority_Name__c='3',Urgency_Id__c= urgencymap.get('Severity 3'),Urgency_Name__c='Severity 3');
     HD_Ticket_Priority__c hdtp4 = new HD_Ticket_Priority__c(Name='4',Priority_Name__c='4',Urgency_Id__c= urgencymap.get('Severity 4'),Urgency_Name__c='Severity 4');
     HD_Ticket_Priority__c hdtp5 = new HD_Ticket_Priority__c(Name='default',Priority_Name__c='4',Urgency_Id__c=urgencymap.get('Severity 4'),Urgency_Name__c='Severity 4');
     Ticket_Priority.add(hdtp1);
     Ticket_Priority.add(hdtp2);
     Ticket_Priority.add(hdtp3);
     Ticket_Priority.add(hdtp4);
     Ticket_Priority.add(hdtp5);

     insert Ticket_Priority;
     
    
    
    //inserting Custom settings RF_Default_Custom_Setting
    List<HD_Default_Custom_Setting__c> RF_Default_Custom_Setting = new List<HD_Default_Custom_Setting__c>();
    HD_Default_Custom_Setting__c defcustset1 = new  HD_Default_Custom_Setting__c(Name='DEFAULT VALUES',Default_Account__c='Akamai Helpdesk',Default_Impact__c='LOW');
    RF_Default_Custom_Setting.add(defcustset1);
    insert RF_Default_Custom_Setting;

    //inserting Custom settings Incident Groupd
     List<HD_EIS_INCIDENT_GROUP__c> groupList = HD_EIS_INCIDENT_GROUP__c.getall().values();
          
     if( groupList==null|| groupList.size() == 0 )
     {
        HD_EIS_INCIDENT_GROUP__c IncidentGroup = new HD_EIS_INCIDENT_GROUP__c();
        HD_EIS_INCIDENT_GROUP__c IncidentGroup1 = new HD_EIS_INCIDENT_GROUP__c();
        HD_EIS_INCIDENT_GROUP__c IncidentGroup2 = new HD_EIS_INCIDENT_GROUP__c();
        HD_EIS_INCIDENT_GROUP__c IncidentGroup3 = new HD_EIS_INCIDENT_GROUP__c();
        HD_EIS_INCIDENT_GROUP__c IncidentGroup4 = new HD_EIS_INCIDENT_GROUP__c();
        
        IncidentGroup.NAME = 'HELPDESK_HARDWARE';
        IncidentGroup.IncidentGroup__c = 'Q_HELPDESK_HARDWARE';
        groupList.add(IncidentGroup);
        
        
        IncidentGroup1.NAME = 'HELPDESK_MALWARE';
        IncidentGroup1.IncidentGroup__c = 'Q_HELPDESK_MALWARE';
        groupList.add(IncidentGroup1);
        
        
        IncidentGroup2.NAME = 'HELPDESK_TRIAGE';
        IncidentGroup2.IncidentGroup__c = 'Q_HELPDESK_TRIAGE';
        groupList.add(IncidentGroup2);
        
        
        IncidentGroup3.NAME = 'ITOC';
        IncidentGroup3.IncidentGroup__c = 'Q_ITOC';
        groupList.add(IncidentGroup3);
        
        
        IncidentGroup4.NAME = 'ITOC_Alerts';
        IncidentGroup4.IncidentGroup__c = 'Q_ITOC_Alerts';
        groupList.add(IncidentGroup4);
        
        Insert groupList;
               
        
        
     }//if( groupList==null|| groupList.size() == 0 )
     System.debug('GroupList CustomSetting------>'+groupList);

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
   Group gp = new Group();
   gp.Name = 'Triage_Team';
   insert gp;
   //adding dataload custom setting added by Bhaskar verma 
   HD_DataLoad__c dl = new HD_DataLoad__c();
   dl.name = 'Triage_Team';
   dl.TextValue__c = gp.Id;
   insert dl;
     
}//private static void UtilFunc()

//initializing this as main function
private static void init()
{
//Calling Util Function 
 UtilFunc();
 ManagedPkgErrorClass.isFromManagedPackage=false;
}//private static void init()
/*
private static testMethod void UpdateStatusToCustomerResponded() 
{
    
    //Calling init method
    init();
    BMCServiceDesk__Incident__c newIncident = new BMCServiceDesk__Incident__c(BMCServiceDesk__FKCategory__c=parent_category.get('Additional Desktop/Laptop'),BMCServiceDesk__FKClient__c = system.userInfo.getUserId(),BMCServiceDesk__FKUrgency__c=urgencymap.get('Severity 4'),BMCServiceDesk__FKImpact__c = impactmap.get('LOW'),BMCServiceDesk__incidentDescription__c = 'Test Data Description values',HD_Ticket_Priority__c='3' );

    //Creating a new Incident         
    insert newIncident;
    system.debug('-----> '+newIncident);
    //system.AssertNotEquals(incident_for_Insert,Null);
    List<BMCServiceDesk__Action__c> actionList = new LIST <BMCServiceDesk__Action__c>();
    BMCServiceDesk__Action__c act1 = new BMCServiceDesk__Action__c(Name='Email Received',BMCServiceDesk__Abbreviation__c='EMAILIN',BMCServiceDesk__appliesToIncident__c=true,BMCServiceDesk__Display_In_SelfService__c=false,BMCServiceDesk__appliesToBroadcasts__c=false,BMCServiceDesk__inactive__c=false);
    actionList.add(act1);
    BMCServiceDesk__Action__c act2 = new BMCServiceDesk__Action__c(Name='Notes',BMCServiceDesk__Abbreviation__c='Notes',BMCServiceDesk__appliesToIncident__c=true,BMCServiceDesk__Display_In_SelfService__c=true,BMCServiceDesk__appliesToBroadcasts__c=false,BMCServiceDesk__inactive__c=false);
    actionList.add(act2);
    actionsmap = HD_Test_Remedyforce_TestDataFactory.createAction(actionList);
            
    test.startTest();
    //lets iterate through inserted Incident

    // Creating a new Incident History record
     BMCServiceDesk__IncidentHistory__c newHistory = new BMCServiceDesk__IncidentHistory__c(BMCServiceDesk__FKIncident__c=newIncident.id,BMCServiceDesk__FKAction__c=act1.id,BMCServiceDesk__note__c = 'test notes - '+newIncident.BMCServiceDesk__clientEmail__c);
     insert newHistory; 
     BMCServiceDesk__Incident__c incident = [Select BMCServiceDesk__Status_ID__c FROM BMCServiceDesk__Incident__c where id =:newIncident.id LIMIT 1][0];

    
    
     BMCServiceDesk__IncidentHistory__c newHistory1 = new BMCServiceDesk__IncidentHistory__c(BMCServiceDesk__FKIncident__c=newIncident.id,BMCServiceDesk__FKAction__c=act2.id);
     insert newHistory1; 
    
             
    test.stopTest();  
    
        
    // System.assertEquals(incident.BMCServiceDesk__Status_ID__c,'CUSTOMER RESPONDED');       
    
    
}//static testMethod void UpdateStatusToCustomerResponded() 

 */

}//Test Class Ends