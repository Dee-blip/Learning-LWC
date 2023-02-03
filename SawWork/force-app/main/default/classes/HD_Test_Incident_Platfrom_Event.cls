/*
* @Developer : Hemant Barapatre
* purpose : To test the platfrom event HD_Incident_Platfrom_Event
* Modification Log ===============================================================
* Date 				 Author 			  Modification
* Sep 28th, 2020     Aneesh Budnar        1906-Create Events for ODI Load Trigger 
*/

@isTest(seeAllData=false)
public class HD_Test_Incident_Platfrom_Event {
    
    static BMCServiceDesk__Incident__c testIncident;    
    static BMCServiceDesk__Category__c testCategory;    
    static List<BMCServiceDesk__Incident__c> incList = new List<BMCServiceDesk__Incident__c>();
    
    public static Map<String,Id> result;
    public static Map<String,Id> categoriesCreated;
    
    
    static{
        ManagedPkgErrorClass.isFromManagedPackage = false;
        HD_Test_Data_Factory.init();
        System.debug('RESULT========'+result);
    }//
    
    private static Map<String,Id> setUpServiceRequest(
        String srName, 
        String srTitle, 
        Id categoryId,
        String clientEmail,
        Boolean secureFlaginput) {
            
            //Creating Service Request        
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
            
            return HD_TestDataFactory_ServiceRequest.setUpServiceRequest(
                srName,srTitle,categoryId,
                fulfilmentInputLists,clientEmail,secureFlaginput);
        }
    
    private static List<BMCServiceDesk__Incident__c> getIncident(Id incidentId) {
        return [SELECT NAME,
                BMCServiceDesk__FKClient__c,BMCServiceDesk__FKRequestDetail__c,HD_IncidentGroup__c,
                BMCServiceDesk__Category_ID__c,BMCServiceDesk__FKCategory__c,
                BMCServiceDesk__FKStatus__c,BMCServiceDesk__Status_ID__c,
                BMCServiceDesk__incidentDescription__c,
                BMCServiceDesk__Type__c,BMCServiceDesk__IncidentType__c,
                BMCServiceDesk__clientId__c,BMCServiceDesk__clientEmail__c,
                BMCServiceDesk__Service_Request_Title__c,
                Owner.name,
                ownerId FROM BMCServiceDesk__Incident__c WHERE ID=:incidentId];
    }
    
    @isTest static void testPlatfromEventSR(){
        Test.startTest();
        result = setUpServiceRequest('testName18','testTitle18',HD_Test_Data_Factory.categoryMap.get('Compensation'),'nkarn@akamai.com',true);
        List<BMCServiceDesk__Incident__c> incidentList = getIncident(result.get('incidentId'));
        System.debug('SRLIST========'+incidentList);
        system.assert(incidentList.size() > 0);
        HD_Incident_Platfrom_Event.publish_Incident_Event(incidentList);
        Test.getEventBus().deliver();
        Test.stopTest();
        System.assertEquals(0, HD_Incident_Platfrom_Event.platformEvents.size());
    }//END
    
    @isTest static void whenSRTitleInMDTExpectPlatformEventIsRaised() {
        BMCServiceDesk__Category__c category = new BMCServiceDesk__Category__c(
            BMCServiceDesk__FKCategoryType__c = HD_Test_Data_Factory.categoryTypeMap.get('Q_EAE_OPS'), 
            BMCServiceDesk__AvailableForIncidents__c = true,
            Name='Oracle Data Integrator(ODI)');
        insert category;
        result = setUpServiceRequest('Adhoc Load Trigger','Adhoc Load Trigger',category.Id,'nkarn@akamai.com',true);
        
        Test.startTest();
        System.debug('IncidentId-->'+result.get('incidentId'));
        List<BMCServiceDesk__Incident__c> incidentList = getIncident(result.get('incidentId'));
        HD_Incident_Platfrom_Event.publish_Incident_Event(incidentList);
        Test.getEventBus().deliver();
        Test.stopTest();
        System.assertEquals(1, HD_Incident_Platfrom_Event.platformEvents.size());
    }
    
    @isTest static void testWrapperClass(){//not required will delete this class in coming days
        Test.startTest();
        HD_Inc_Platfrom_Event_SR_Wrapper_Class hipesWC = new HD_Inc_Platfrom_Event_SR_Wrapper_Class();
        hipesWC.inputprompt = 'Name';
        hipesWC.Response = 'P2rTest';        
        Test.stopTest();
    }//END
    
    
}