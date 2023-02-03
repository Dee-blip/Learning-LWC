/*
* File Name: HDVisaTemplate_Test
* Description : Test class for HDVisaTemplate
* @author : 
* Modification Log ===============================================================
* Date              Author              Modification
* 5 Aug 2020        Abhishek Singh      PRTORES-1811 - HD code scan 2020 - Blocker and critical part 5
* Aug 08th, 2020    Aneesh Budnar       PRTORES-1811 - Code Scanner part 5 fixes
*/
@isTest(SeeAllData=false)
public class HDVisaTemplate_Test {
    //Global variable 
    
    
    private static testmethod void controllerTest(){
        HD_Test_Data_Factory.init();
                      
        BMCServiceDesk__Category__c category = new BMCServiceDesk__Category__c();
        category.Name = 'Corporate Sustainability';
        category.BMCServiceDesk__AvailableForIncidents__c = true;
        insert category;
        BMCServiceDesk__BMC_BaseElement__c service = new BMCServiceDesk__BMC_BaseElement__c();
        service.Name = 'Infrastructure Services-INST_2014_12_1_1_58_4_8781004';
        service.BMCServiceDesk__Name__c = 'Infrastructure Services-INST_2014_12_1_1_58_4_8781004';
        insert service;
        
        BMCServiceDesk__SRM_RequestDefinition__c sr = new BMCServiceDesk__SRM_RequestDefinition__c();
        sr.BMCServiceDesk__Online__c = true;
        sr.BMCServiceDesk__Status__c = 'Deployed';
        sr.Name = 'test';
        sr.BMCServiceDesk__FKCategory__c = category.Id;
        sr.BMCServiceDesk__FKBusinessService__c = service.Id;
        sr.BMCServiceDesk__FKServiceOffering__c = service.Id;
        sr.BMCServiceDesk__serviceRequestTitle__c = 'Presentation Integration';
        insert sr;
        BMCServiceDesk__SRM_RequestDefinition__c nsr =  sr.clone();
        nsr.BMCServiceDesk__serviceRequestTitle__c = 'Test Network Contract';
        sr.Name = 'Travel Visa';
        insert nsr;
        
        BMCServiceDesk__SRM_RequestDetail__c rd = new BMCServiceDesk__SRM_RequestDetail__c();
        rd.BMCServiceDesk__FKClient__c = system.userInfo.getUserId();
        rd.BMCServiceDesk__FKRequestDefinition__c = nsr.Id;
        insert rd;
        
        BMCServiceDesk__Incident__c inc = new BMCServiceDesk__Incident__c();
        inc.BMCServiceDesk__FKCategory__c = category.Id;
        inc.HD_Ticket_Priority__c = '4';
        inc.BMCServiceDesk__FKUrgency__c = HD_Test_Data_Factory.urgencyMap.get('Severity 4');
        inc.BMCServiceDesk__FKClient__c = system.userInfo.getUserId();
        inc.BMCServiceDesk__FKImpact__c= HD_Test_Data_Factory.impactMap.get('LOW'); 
        inc.RecordtypeId = Schema.SObjectType.BMCServiceDesk__Incident__c.getRecordTypeInfosByName().get('Helpdesk').getRecordTypeId(); 
        inc.BMCServiceDesk__FKRequestDetail__c = rd.Id;
        inc.How_was_the_Issue_Detected__c = 'Customer reported';
        inc.BMCServiceDesk__incidentDescription__c = 'Test Data Description values';
        insert inc;
        
        BMCServiceDesk__SRM_FulfillmentInputs__c ffi = new BMCServiceDesk__SRM_FulfillmentInputs__c();
        ffi.BMCServiceDesk__FKRequestDefinition__c = nsr.id;
        ffi.BMCServiceDesk__Order__c = 1;
        ffi.BMCServiceDesk__Prompt__c = 'Select Date';
        ffi.BMCServiceDesk__ResponseType__c = 'Date';
        insert ffi;
        
        BMCServiceDesk__SRM_RequestDetailInputs__c rdi1 =  new BMCServiceDesk__SRM_RequestDetailInputs__c();
        rdi1.BMCServiceDesk__FKFulfillmentInputs__c = ffi.Id;
        rdi1.BMCServiceDesk__FKRequestDetail__c = rd.Id;
        rdi1.BMCServiceDesk__Response__c = '31/07/2020';
        rdi1.BMCServiceDesk__StoredValue__c = '31/07/2020';
        rdi1.BMCServiceDesk__Input__c = 'Start Date';
        insert rdi1;
        
        HDVisaTemplate instance = new HDVisaTemplate();
        instance.incid = inc.id;
        Boolean valid = instance.validTemplate;
        instance.testClassRun = true;
        instance.controllerValue = 'test value';
        instance.test = 'test value';
        Map<String,String> output = instance.templateDetails;
        BMCServiceDesk__Incident__c incclient = [select id, BMCServiceDesk__Type__c, BMCServiceDesk__FKClient__r.name from BMCServiceDesk__Incident__c where Id=:inc.Id limit 1];
        System.assertEquals(incclient.BMCServiceDesk__FKClient__r.name, output.get('Client Name'), 'Expected value not same as actual value');
    }
}