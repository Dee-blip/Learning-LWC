@isTest
private class HD_Test_CloneIncidentTest {

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
 

   List<Incident_CloneFields__c> dlList = new List<Incident_CloneFields__c>();

   Incident_CloneFields__c dl1 = new Incident_CloneFields__c();
   Incident_CloneFields__c dl2 = new Incident_CloneFields__c();
   Incident_CloneFields__c dl3 = new Incident_CloneFields__c();
   Incident_CloneFields__c dl4 = new Incident_CloneFields__c();
   Incident_CloneFields__c dl5 = new Incident_CloneFields__c();
   Incident_CloneFields__c dl6 = new Incident_CloneFields__c();
   
   dl1.name = 'Priority';   
   dl1.APIName__c = 'HD_Ticket_Priority__c';
   dlList.add(dl1);

   dl2.name='Client Name';
   dl2.APIName__c='BMCServiceDesk__Client_Name__c';
   dlList.add(dl2);

   dl3.name='Urgency';
   dl3.APIName__c='BMCServiceDesk__FKUrgency__c';
   dlList.add(dl3);

   dl4.name='Impact';
   dl4.APIName__c='BMCServiceDesk__FKImpact__c';
   dlList.add(dl4);

   dl5.name='Category';
   dl5.APIName__c='BMCServiceDesk__FKCategory__c';
   dlList.add(dl5);

   dl6.name='FK Client';
   dl6.APIName__c='BMCServiceDesk__FKClient__c';
   dlList.add(dl6);

   insert dlList; 
      


}//static


    static testMethod void cloneIncident() {
        //PageReference pagerf = Page.ServiceRequestdetail;
        //Test.setCurrentPage(pagerf);
        
         List<BMCServiceDesk__Incident__c> incidents =  HD_Test_Remedyforce_TestDataFactory.incidentTestData(1,child_category.get('UNIX'),urgencymap.get('Severity 3'),impactmap.get('LOW'));
        insert incidents;
        Test.startTest();
        BMCServiceDesk__Incident__c incident=incidents.get(0);
        System.debug('Incident to be cloned in test: '+incident.id);
        String clonedIncidentId=HD_Clone_Extension.cloneIncident(incident.id);
        System.debug('Cloned Incident Id in test: '+clonedIncidentId);
        System.assertNotEquals(clonedIncidentId,null);
        BMCServiceDesk__Incident__c clonedIncident= [Select BMCServiceDesk__FKCategory__c,BMCServiceDesk__FKClient__c,BMCServiceDesk__incidentDescription__c from BMCServiceDesk__Incident__c where BMCServiceDesk__Incident__c.Id=:clonedIncidentId ];
        System.assertEquals(clonedIncident.BMCServiceDesk__FKCategory__c,incident.BMCServiceDesk__FKCategory__c);
        System.assertEquals(clonedIncident.BMCServiceDesk__FKClient__c,incident.BMCServiceDesk__FKClient__c);
        
        Test.stopTest();
       
        
    }//static testMethod void cloneIncident() 
    
      static testMethod void bulkClone() {
        
        
         List<BMCServiceDesk__Incident__c> incidents =  HD_Test_Remedyforce_TestDataFactory.incidentTestData(1,child_category.get('UNIX'),urgencymap.get('Severity 3'),impactmap.get('LOW'));
        insert incidents;
        Test.startTest();
        BMCServiceDesk__Incident__c incident=incidents.get(0);
        System.debug('Incident to be cloned in test: '+incident.id);
         for(Integer i=0;i<2;i++){
            String clonedIncidentId=HD_Clone_Extension.cloneIncident(incident.id);
            System.debug('Bulk Cloning: '+i);
            System.assertNotEquals(clonedIncidentId,null);
        }
        
        Test.stopTest();
       
        
    }//static testMethod void bulkClone()
    
    static testMethod void testGetIncNum(){
        List<BMCServiceDesk__Incident__c> incidents =  HD_Test_Remedyforce_TestDataFactory.incidentTestData(1,child_category.get('UNIX'),urgencymap.get('Severity 3'),impactmap.get('LOW'));
        insert incidents;
        Test.startTest();
        BMCServiceDesk__Incident__c incident=incidents.get(0);
        System.debug('Incident for getIncidentNum: '+incident.id);
        String incNum=HD_Clone_Extension.getIncidentNum(incident.id);
        System.debug('Incident number in test: '+incNum);
        System.assertNotEquals(incNum, null);
        Test.stopTest();
    }//static testMethod void testGetIncNum()
    
    static testMethod void testCloneIncorrectIncidentId(){
        Test.startTest();
        System.debug('Incident to be cloned in test: abc');
        String clonedIncidentId=HD_Clone_Extension.cloneIncident('abc');
        System.debug('Cloned Incident Id in test: '+clonedIncidentId);
        System.assertEquals(clonedIncidentId,null);
        Test.stopTest();
    }//static testMethod void testCloneIncorrectIncidentId()
}//END OF CLASS