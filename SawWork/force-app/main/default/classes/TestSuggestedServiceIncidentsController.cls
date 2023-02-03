/*=====================================================================================================+
    Class name          :   TestSuggestedServiceIncidentsController 
    Author              :   Himanshu Kar
    Purpose             :   This test class is used to cover code for below Components
                            1. SuggestedServiceIncidentsController
                            
    Last Modified Developer  Purpose            
    ============= =========  =======
    28-JUN-14     Vinod     Initial Development 
    14-AUG-14     Himanshu   Removed (seeAllData=true),increased code coverage and optimized test class
	31-OCT-18	  Pinkesh	Added Executive Summary for new validation rule on incident.
    
+=====================================================================================================*/
@isTest
private class TestSuggestedServiceIncidentsController {
    
    // For Account Record
    public static Account testAcc;
    
    // For Incident Record
    public static BMCServiceDesk__Incident__c incident;
    
    //Method for creating Test data
    static void myUnitTest() {
        
        // Call to - createCustomSettings For Case Setup
         utilTestClass.createCustomSettings();

    
         List<HD_RF_TRIGGER_FLAG__c>  rfList =  new List<HD_RF_TRIGGER_FLAG__c>();
         HD_RF_TRIGGER_FLAG__c  HD_RemedyForceCustomizations = new HD_RF_TRIGGER_FLAG__c(Name='HD_RemedyForceCustomizations',Enable__c=true,Information__c='This is Old trigger');
         rfList.add(HD_RemedyForceCustomizations);
         HD_RF_TRIGGER_FLAG__c  HD_RemedyForceCustomization_Tri = new HD_RF_TRIGGER_FLAG__c(Name='HD_RemedyForceCustomization_Tri',Enable__c=false,Information__c='This is new trigger');
         rfList.add(HD_RemedyForceCustomization_Tri);
         //Inserting 
         insert rfList;
        
        Map<String, Schema.RecordTypeInfo> rtMap = Case.sObjectType.getDescribe().getRecordTypeInfosByName();    
        
        //Create Account
        testAcc = utilTestClass.CreateAccount('__Test Account');
        testAcc.Vertical__c = 'Gaming';  
        insert testAcc;
    
        //Create BMC Urgency
        BMCServiceDesk__Urgency__c  urg = new BMCServiceDesk__Urgency__c();
        urg.Name='tempUrgency';
        urg.SI_Applies_to_Service_Incident__c = true;
        insert urg;
        id RecordId = [SELECT id FROM RecordType where Name ='Service Incident'][0].id;
       

       // changes by Vandhana for 3695602
        // Setting category type for category based on new validation on Category - Category type is mandatory 
        BMCServiceDesk__CategoryTypes__c ctype = new BMCServiceDesk__CategoryTypes__c(Name = 'categoryTypeTest' );       
        insert ctype;

        //Create BMC Category
        BMCServiceDesk__Category__c  cat = new BMCServiceDesk__Category__c();
        cat.Name='tempCategory';
        cat.SI_Applies_to_Service_Incident__c = true;
        cat.BMCServiceDesk__AvailableForIncidents__c = true;
        cat.BMCServiceDesk__FKCategoryType__c = ctype.Id;
        insert cat;
        
        //Create BMC Status
         BMCServiceDesk__Status__c sta = new BMCServiceDesk__Status__c();
         sta.Name='IN PROGRESS11111';
         sta.SI_Applies_to_Service_Incident__c = true;
         insert sta;
       
        //Create Impact
         BMCServiceDesk__Impact__c  ima = new BMCServiceDesk__Impact__c();
         ima.Name='IN PROGRESS';
         ima.SI_Applies_to_Service_Incident__c = true;
         insert ima;
      
       //Create Category
        BMCServiceDesk__Category__c  cat1 = new BMCServiceDesk__Category__c();
        cat1.Name='tempCategory1';
        cat1.SI_Applies_to_Service_Incident__c = true;
        cat1.BMCServiceDesk__AvailableForIncidents__c = true;
        insert cat1;
        
        //Create Incident
        incident = new BMCServiceDesk__Incident__c();
        incident.BMCServiceDesk__FKUrgency__c = urg.id;
        incident.RecordTypeID=RecordId;
        incident.BMCServiceDesk__FKCategory__c = cat.Id;
        incident.BMCServiceDesk__FKImpact__c = ima.Id;
        incident.How_was_the_issue_detected__c = 'others';
        incident.SI_Executive_Summary__c = 'Test Test Test Test Test Test Test';
        insert(incident);

        //Create tstService
        SI_ServiceIncidentImpactedCustomers__c tstService = new SI_ServiceIncidentImpactedCustomers__c ();
        tstService.SI_Service_Incident__c = incident.ID;
        tstService.SI_AccountName__c = testAcc.id;
        insert tstService;
        
        /*Create Service Incident Impacted Products
        SI_ServiceIncidentImpactedProducts__c serviceIncidentProducts = new SI_ServiceIncidentImpactedProducts__c();
        serviceIncidentProducts.SI_ServiceIncident__c = incident.ID;
        serviceIncidentProducts.SI_IncidentRecordType__c =RecordId;
        serviceIncidentProducts.SI_ParentProductName__c = 'test product';
        insert serviceIncidentProducts; */
    }
       
        // Test Method
        static testmethod void ServiceIncidentsMethod()
        {
            // Calling dataSetup Method
            myUnitTest();
            
            test.startTest();
            
                //Create Case
                case testCase = utilTestClass.CreateCase(testAcc.ID);
       
                PageReference pRef = Page.Suggested_Service_Incidents;        
                Test.setCurrentPage(pRef);  

                // instantiate controller
                ApexPages.StandardController stdCon = new ApexPages.StandardController(testCase);      
                SuggestedServiceIncidentsController controller = new SuggestedServiceIncidentsController(stdCon);
                
                controller.selectedIncident = (string)incident.ID;
                controller.PopulateCaseIncident();
                
                controller.strServiceIncidentsText = '';
                controller.SearchedIncident();
                
            test.stopTest();
       }
}