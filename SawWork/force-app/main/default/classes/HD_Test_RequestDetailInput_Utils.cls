@isTest( seeAlldata = false)
public class HD_Test_RequestDetailInput_Utils {
    
    public static Map<String,Id> categoriesCreated;
    public static User contextUser;
    public static Map<String,Id> result;
    public static List<HD_TestDataFactory_ServiceRequest.FulfilmentInputWrapperClass> fulfilmentInputLists;
    static{
        HD_RequestDetailInput_Utils.firstRun = true;
        contextUser=[SELECT Id, PermissionSet.Name,AssigneeId,Assignee.HD_View_Helpdesk_Confidential_Data__c FROM PermissionSetAssignment where PermissionSet.Name = 'HD_HR_View_Encrypted_data_permission' and Assignee.HD_View_Helpdesk_Confidential_Data__c = true and Assignee.isActive = true limit 1].Assignee;
        HD_TestDataFactory_ServiceRequest.FulfilmentInputWrapperClass tempList=new HD_TestDataFactory_ServiceRequest.FulfilmentInputWrapperClass();
        fulfilmentInputLists=new List<HD_TestDataFactory_ServiceRequest.FulfilmentInputWrapperClass>();
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
        
        String clientEmailId=System.UserInfo.getUserEmail(); 

        
        result=HD_TestDataFactory_ServiceRequest.setUpServiceRequest('testName18','testTitle18',categoriesCreated.get('Compensation'),fulfilmentInputLists,clientEmailId,true,HD_IncidentTestDataFactory.Team.HR);
        
    }
    static TestMethod void PositiveTestcase(){
        Test.startTest();
        //get the request definition id
        BMCServiceDesk__SRM_RequestDefinition__c requestDefId =  [select id from BMCServiceDesk__SRM_RequestDefinition__c limit 1];
        
        //create a new Lookup fulfillment input
        BMCServiceDesk__SRM_FulfillmentInputs__c lookupInput = new BMCServiceDesk__SRM_FulfillmentInputs__c(
        	BMCServiceDesk__Prompt__c = 'reference', BMCServiceDesk__Order__c  = 2, BMCServiceDesk__ResponseType__c = 'Lookup',
            BMCServiceDesk__InputValues__c = 'BMCServiceDesk__category__c', Input_Values_holder__c = 'BMCServiceDesk__category__c',
            HD_Object_Api__c  = 'BMCServiceDesk__Category__c', HD_Object_Fields__c = 'Name ',
            BMCServiceDesk__FKRequestDefinition__c = requestDefId.ID
        );
        insert lookupInput;
        
        //crete a seeker fulfillment input
        BMCServiceDesk__SRM_FulfillmentInputs__c seekerInput = new BMCServiceDesk__SRM_FulfillmentInputs__c(
        	BMCServiceDesk__Prompt__c = 'seeker', BMCServiceDesk__Order__c  = 3, BMCServiceDesk__ResponseType__c = 'Text',
            HD_Field_Seeker__c = 'Name', HD_Parent_Input__c = lookupInput.id,
            BMCServiceDesk__FKRequestDefinition__c = requestDefId.ID
        );
       	insert seekerInput;
        
        String clientEmailId=System.UserInfo.getUserEmail();
		

		//creating requestdetail record        
        String IncidentID = null;

        BMCServiceDesk__SRM_RequestDetail__c srmRequestDetail = new BMCServiceDesk__SRM_RequestDetail__c();

       

        
        //srmRequestDetail.BMCServiceDesk__FKClient__c = clientId;
        srmRequestDetail.BMCServiceDesk__FKIncident__c = incidentID;
        srmRequestDetail.BMCServiceDesk__FKRequestDefinition__c = requestDefId.ID;
        srmRequestDetail.BMCServiceDesk__Submitted__c = true;
        
        insert srmRequestDetail;
        //result=HD_TestDataFactory_ServiceRequest.setUpServiceRequest('testName18','testTitle18',categoriesCreated.get('Compensation'),fulfilmentInputLists,clientEmailId,true,HD_IncidentTestDataFactory.Team.HR);
        //System.debug('RESULT========'+result);
        //check the utility functions
        
        List<BMCServiceDesk__SRM_RequestDetailInputs__c> rdi = new List<BMCServiceDesk__SRM_RequestDetailInputs__c>();
        rdi.add(new BMCServiceDesk__SRM_RequestDetailInputs__c(
        	BMCServiceDesk__Response__c = 'P2R',
            BMCServiceDesk__FKFulfillmentInputs__c = lookupInput.id,
            BMCServiceDesk__FKRequestDetail__c  = srmRequestDetail.id 
        ));
        rdi.add(new BMCServiceDesk__SRM_RequestDetailInputs__c(
        	BMCServiceDesk__Response__c = '',
           
            BMCServiceDesk__FKFulfillmentInputs__c = seekerInput.id,
            BMCServiceDesk__FKRequestDetail__c  = srmRequestDetail.id
        ));
        HD_RequestDetailInput_Utils.firstRun = true;
        insert rdi;
        
        //HD_RequestDetailInput_Utils.initializeLookups(rdi);
        //HD_RequestDetailInput_Utils.manipulateSeekers(rdi);
        
        
            
        Test.stopTest();
    }
}