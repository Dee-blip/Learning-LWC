/*
* File Name: HD_Test_SREdit
* Description : Test class for HD_Edit_ServiceRequest
* @author : 
* Modification Log ===============================================================
* Date              Author              Modification
* 5 Aug, 2020       Abhishek Singh      PRTORES-1811 - HD code scan 2020 - Blocker and critical part 5 
* Aug 08th, 2020    Aneesh Budnar       PRTORES-1811 - Code Scanner part 5 fixes
*/
@isTest(seeAllData = false)
public class HD_Test_SREdit {
     static testMethod void testEditServiceRequest(){
        HD_Test_Data_Factory.init();
        
        //Creating Service Request
        List<HD_TestDataFactory_ServiceRequest.FulfilmentInputWrapperClass> fulfilmentInputLists=new List<HD_TestDataFactory_ServiceRequest.FulfilmentInputWrapperClass>();
        Map<String,Id> categoriesCreated = HD_Test_Data_Factory.categoryMap;
        Map<String,Id> result = HD_TestDataFactory_ServiceRequest.setUpServiceRequest('testName18','testTitle18',categoriesCreated.get('Compensation'),fulfilmentInputLists,'nkarn@akamai.com',true,HD_IncidentTestDataFactory.Team.HR);
        
        BMCServiceDesk__SRM_FulfillmentInputs__c ffi = new BMCServiceDesk__SRM_FulfillmentInputs__c();
        ffi.BMCServiceDesk__FKRequestDefinition__c = result.get('serviceRequestId');
        ffi.BMCServiceDesk__Order__c = 1;
        ffi.BMCServiceDesk__Prompt__c = 'Select Picklist';
        ffi.INPUT_VALUES_HOLDER__C = 'Medium?M?false*High?H?false*Low?L?false';
        ffi.BMCSERVICEDESK__INPUTVALUES__C = 'MediumфMфfalseПHighфH?falseПLowфLфfalse';
        ffi.BMCServiceDesk__ResponseType__c = 'Picklist';
         
        BMCServiceDesk__SRM_FulfillmentInputs__c ffi1 = new BMCServiceDesk__SRM_FulfillmentInputs__c();
        ffi1.BMCServiceDesk__FKRequestDefinition__c = result.get('serviceRequestId');
        ffi1.BMCServiceDesk__Order__c = 2;
        ffi1.BMCServiceDesk__Prompt__c = 'Add Text';
        ffi1.BMCServiceDesk__ResponseType__c = 'Text Field';
        
        BMCServiceDesk__SRM_FulfillmentInputs__c ffi2 = new BMCServiceDesk__SRM_FulfillmentInputs__c();
        ffi2.BMCServiceDesk__FKRequestDefinition__c = result.get('serviceRequestId');
        ffi2.BMCServiceDesk__Order__c = 3;
        ffi2.BMCServiceDesk__Prompt__c = 'Add Date';
        ffi2.BMCServiceDesk__ResponseType__c = 'Date';
        
        BMCServiceDesk__SRM_FulfillmentInputs__c ffi3 = new BMCServiceDesk__SRM_FulfillmentInputs__c();
        ffi3.BMCServiceDesk__FKRequestDefinition__c = result.get('serviceRequestId');
        ffi3.BMCServiceDesk__Order__c = 4;
        ffi3.BMCServiceDesk__Prompt__c = 'Add Date/Time';
        ffi3.BMCServiceDesk__ResponseType__c = 'Date/Time';
         
        BMCServiceDesk__SRM_FulfillmentInputs__c ffi4 = new BMCServiceDesk__SRM_FulfillmentInputs__c();
        ffi4.BMCServiceDesk__FKRequestDefinition__c = result.get('serviceRequestId');
        ffi4.BMCServiceDesk__Order__c = 5;
        ffi4.BMCServiceDesk__Prompt__c = 'Add Text Area text';
        ffi4.BMCServiceDesk__ResponseType__c = 'Text Area';
        insert new List<BMCServiceDesk__SRM_FulfillmentInputs__c> {ffi, ffi1, ffi2, ffi3, ffi4};
        
        BMCServiceDesk__Incident__c inc = new BMCServiceDesk__Incident__c();
        inc.BMCServiceDesk__FKCategory__c = categoriesCreated.get('Compensation');
        inc.HD_Ticket_Priority__c = '4';
        inc.BMCServiceDesk__FKRequestDefinition__c = result.get('serviceRequestId');
        inc.BMCServiceDesk__FKUrgency__c=  HD_Test_Data_Factory.urgencyMap.get('Severity 4');
        inc.BMCServiceDesk__FKClient__c = system.userInfo.getUserId();
        inc.BMCServiceDesk__FKImpact__c= HD_Test_Data_Factory.impactMap.get('LOW');
        inc.RecordtypeId = Schema.SObjectType.BMCServiceDesk__Incident__c.getRecordTypeInfosByName().get('Helpdesk').getRecordTypeId(); 
        inc.BMCServiceDesk__incidentDescription__c = 'Test Data Description values ';
        insert inc;
        
         BMCServiceDesk__SRM_RequestDetail__c rd = new BMCServiceDesk__SRM_RequestDetail__c();
        rd.BMCServiceDesk__FKClient__c = system.userInfo.getUserId();
        rd.BMCServiceDesk__FKIncident__c = inc.Id;
        rd.BMCServiceDesk__FKRequestDefinition__c = result.get('serviceRequestId');
        insert rd;
        
        BMCServiceDesk__SRM_RequestDetailInputs__c rdi1 =  new BMCServiceDesk__SRM_RequestDetailInputs__c();
        rdi1.BMCServiceDesk__FKFulfillmentInputs__c = ffi.Id;
        rdi1.BMCServiceDesk__FKRequestDetail__c = rd.Id;
        rdi1.BMCServiceDesk__Response__c = 'Medium';
        rdi1.BMCServiceDesk__StoredValue__c = 'M';
        
        BMCServiceDesk__SRM_RequestDetailInputs__c rdi2 =  new BMCServiceDesk__SRM_RequestDetailInputs__c();
        rdi2.BMCServiceDesk__FKFulfillmentInputs__c = ffi3.Id;
        rdi2.BMCServiceDesk__FKRequestDetail__c = rd.Id;
        rdi2.BMCServiceDesk__Response__c = '2017-11-29T23:45:00:00Z';
        rdi2.BMCServiceDesk__StoredValue__c = '11/29/2017 11:45 PM';
        
        BMCServiceDesk__SRM_RequestDetailInputs__c rdi3 =  new BMCServiceDesk__SRM_RequestDetailInputs__c();
        rdi3.BMCServiceDesk__FKFulfillmentInputs__c = ffi2.Id;
        rdi3.BMCServiceDesk__FKRequestDetail__c = rd.Id;
        rdi3.BMCServiceDesk__Response__c = '2017-11-28';
        rdi3.BMCServiceDesk__StoredValue__c = '11/28/2017';
   
        insert new List<BMCServiceDesk__SRM_RequestDetailInputs__c>{rdi1, rdi2, rdi3};
         
    
        
        Test.startTest();
     
        HD_Edit_ServiceRequest.SR_Details  srd= HD_Edit_ServiceRequest.getSRDetails(inc.Id);

        Map<String,String> ffiValue = new  Map<String,String>();

        ffiValue.put(ffi.Id,'Low');
        ffiValue.put(ffi2.Id,'2017-11-30');
        ffiValue.put(ffi3.Id,'2017-11-23T23:45:00:00Z');
        ffiValue.put(ffi1.Id, 'New text response');
        HD_Edit_ServiceRequest.SaveSRDetails(inc.Id,ffiValue);
        Test.stopTest();
       BMCServiceDesk__SRM_RequestDetailInputs__c srd2 = [SELECT BMCServiceDesk__History__c,id from BMCServiceDesk__SRM_RequestDetailInputs__c where id = :rdi2.id limit 1];
       System.assertEquals(true,srd2.BMCServiceDesk__History__c, 'Expected value not same as actual value' );
     }

}