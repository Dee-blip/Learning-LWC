@isTest
private class HD_Test_IncidentToProblemTest {
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
        BMCServiceDesk__Status__c status_assigned = new BMCServiceDesk__Status__c(Name='ASSIGNED',BMCServiceDesk__FKSYSStage__c=stagemap.get('Opened'),BMCServiceDesk__defaultStatus__c=true,BMCServiceDesk__appliesToIncident__c=true,BMCServiceDesk__appliesToProblem__c=false,BMCServiceDesk__appliesToTask__c=true);
        statList.add(status_assigned);
        BMCServiceDesk__Status__c status_closed = new BMCServiceDesk__Status__c(Name='CLOSED',BMCServiceDesk__FKSYSStage__c=stagemap.get('Closed'),BMCServiceDesk__defaultStatus__c=true,BMCServiceDesk__appliesToIncident__c=true,BMCServiceDesk__appliesToProblem__c=false,BMCServiceDesk__appliesToTask__c=true);
        statList.add(status_closed);
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
        if(gd.containsKey('HD_RF_TRIGGER_FLAG__c')){
            List<HD_RF_TRIGGER_FLAG__c>  rfList =  new List<HD_RF_TRIGGER_FLAG__c>();
            HD_RF_TRIGGER_FLAG__c  HD_RemedyForceCustomizations = new HD_RF_TRIGGER_FLAG__c(Name='HD_RemedyForceCustomizations',Enable__c=true,Information__c='This is Old trigger');
            rfList.add(HD_RemedyForceCustomizations);
            HD_RF_TRIGGER_FLAG__c  HD_RemedyForceCustomization_Tri = new HD_RF_TRIGGER_FLAG__c(Name='HD_RemedyForceCustomization_Tri',Enable__c=false,Information__c='This is new trigger');
            rfList.add(HD_RemedyForceCustomization_Tri);
            //Inserting 
            insert rfList; 
        }
        List<Incident_Problem_clone__c> dlList = new List<Incident_Problem_clone__c>();
        Incident_Problem_clone__c dl1 = new Incident_Problem_clone__c();
        Incident_Problem_clone__c dl2 = new Incident_Problem_clone__c();
        Incident_Problem_clone__c dl3 = new Incident_Problem_clone__c();
        Incident_Problem_clone__c dl4 = new Incident_Problem_clone__c();
        Incident_Problem_clone__c dl5 = new Incident_Problem_clone__c();
        dl1.name = 'Description';   
        dl1.IncidentAPIName__c = 'BMCServiceDesk__incidentDescription__c';
        dl1.ProblemAPIName__c = 'BMCServiceDesk__Problem_Description__c';
        dlList.add(dl1);
        dl2.name='Impact';
        dl2.IncidentAPIName__c= 'BMCServiceDesk__FKImpact__c';
        dl2.ProblemAPIName__c = 'BMCServiceDesk__FKImpact__c';
        dlList.add(dl2);
        dl3.name='Service';
        dl3.IncidentAPIName__c= 'BMCServiceDesk__FKCategory__c';
        dl3.ProblemAPIName__c = 'Category_alias__c';
        dlList.add(dl3);
        dl4.name='Title Summary';
        dl4.IncidentAPIName__c='BMCServiceDesk__shortDescription__c';
        dl4.ProblemAPIName__c = 'Title_Summary__c';
        dlList.add(dl4);
        dl5.name='Urgency';
        dl5.IncidentAPIName__c= 'BMCServiceDesk__FKUrgency__c';
        dl5.ProblemAPIName__c = 'BMCServiceDesk__FKUrgency__c';
        dlList.add(dl5);
        insert dlList; 
    }//static
    static testMethod void cloneIncidentToProblemTest() {
        List<BMCServiceDesk__Incident__c> incidents =  HD_Test_Remedyforce_TestDataFactory.incidentTestData(1,child_category.get('UNIX'),urgencymap.get('Severity 3'),impactmap.get('LOW'));
        insert incidents;
        Test.startTest();
        BMCServiceDesk__Incident__c incident=incidents.get(0);
        incident.BMCServiceDesk__shortDescription__c = 'short descrtiption for the incident';
        update incident;
        System.debug('Incident to be promoted to problem in test: '+incident.id);
        String clonedProblemId=HD_Problem_Incident_Clone_Extension.cloneIncidentToProblem(incident.id);
        System.debug('Problem created in test: '+clonedProblemId);
        System.assertNotEquals(clonedProblemId,null);
        BMCServiceDesk__Problem__c problemCreated= [Select Category_alias__c,Title_Summary__c from BMCServiceDesk__Problem__c where BMCServiceDesk__Problem__c.Id=:clonedProblemId ];
        System.assertEquals(problemCreated.Category_alias__c,incident.BMCServiceDesk__FKCategory__c);
        System.assertNotEquals(problemCreated.Category_alias__c, incident.BMCServiceDesk__shortDescription__c);
        System.assertEquals(problemCreated.Title_Summary__c,incident.BMCServiceDesk__shortDescription__c);
        Test.stopTest();
    }//static testMethod void cloneIncidentToProblemTest() 
    static testMethod void bulkCloneIncidentToProblem() {
        List<BMCServiceDesk__Incident__c> incidents =  HD_Test_Remedyforce_TestDataFactory.incidentTestData(1,child_category.get('UNIX'),urgencymap.get('Severity 3'),impactmap.get('LOW'));
        insert incidents;
        Test.startTest();
        BMCServiceDesk__Incident__c incident=incidents.get(0);
        System.debug('Incident to be promoted to Problem in test: '+incident.id);
        for(Integer i=0;i<2;i++){
            String problemId=HD_Problem_Incident_Clone_Extension.cloneIncidentToProblem(incident.id);
            System.debug('Bulk problem creating: '+i);
            System.assertNotEquals(problemId,null);
        }
        Test.stopTest();
    }
    
    public static TestMethod void testRedirect()
    {
        List<BMCServiceDesk__Incident__c> incidents =  HD_Test_Remedyforce_TestDataFactory.incidentTestData(1,child_category.get('UNIX'),urgencymap.get('Severity 3'),impactmap.get('LOW'));
        insert incidents;
        Test.startTest();
        BMCServiceDesk__Incident__c incident=incidents.get(0);
        String checkURL = HD_Problem_Incident_Clone_Extension.getPage(incident.id);
        //system.debug('amp--'+checkURL);
        System.assertNotEquals(' ',checkURL);
    	Test.stopTest();
    }
}//END OF CLASS