/*
Template: Apex Test Class/Trigger Template

CopyRight: Hemant Kumar @ Akamai Technologies Ltd.

Version: 1.0

Created Date : 

Base Line : used as a apart of requirment for Service Request Managment , Unit Test

Purpose : an Unit Test for trigger HD_SRM_RequestDetailInputs_Tri.trigger

Usage : used as an test for the business logic , for trigger HD_SRM_RequestDetailInputs_Tri.trigger

Test Class Asssociated : NONE

Controller (Boolean): False

Page Used/Asssociated (default -> NONE) : NONE

Trigger Associated : HD_SRM_RequestDetailInputs_Tri.trigger
Class Associated : HD_SRM_RequestDetailInputs_Tri_ctrl,HD_Test_Remedyforce_TestDataFactory
* Modification Log ===============================================================
* Date              Author              Modification
* Aug 08th, 2020    Aneesh Budnar       PRTORES-1811 - Code Scanner part 5 fixes
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
@isTest( seeAlldata = false)//@nikhil:changed from true to false as per the jira 871 and now test coverage is 83% 
private class HD_Test_SRM_RequestDetailInputs_Tri
{

  //Global variable 
  
  public static Map<String,Id> categoriesCreated;
  public static User contextUser;
  public static Map<String,Id> result;

  
    /*
     *@LastModifiedBy: Nikhil Karn
     *@ModificationReason: added this static block to load test data factory.
    */
    static{
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
        
        String clientEmailId=System.UserInfo.getUserEmail(); 

        result=HD_TestDataFactory_ServiceRequest.setUpServiceRequest('testName18','testTitle18',categoriesCreated.get('Compensation'),fulfilmentInputLists,clientEmailId,true,HD_IncidentTestDataFactory.Team.HR);
        System.debug('RESULT========'+result);
    }
  


  //this test method will test 
  static TestMethod void PositiveTestcase()
  {
    //getting reqdef and fullfillment inputs  -- If in futrue if test fails, please chagnge the Service Request.
    BMCServiceDesk__SRM_RequestDefinition__c reqdef = [ select Id,Name from BMCServiceDesk__SRM_RequestDefinition__c limit 5000][0];
    BMCServiceDesk__Category__c cat = [SELECt ID, Name from BMCServiceDesk__Category__c Limit 1];


    System.debug('Request Definition ---> '+reqdef);
    //getting fullfillment Inputs for requested Request Definition
    List<BMCServiceDesk__SRM_FulfillmentInputs__c> fulfillmentinputs = [select Id,Name,BMCServiceDesk__ResponseType__c,BMCServiceDesk__Prompt__c,BMCServiceDesk__Required__c,BMCServiceDesk__InputValues__c from BMCServiceDesk__SRM_FulfillmentInputs__c where BMCServiceDesk__FKRequestDefinition__c =: reqdef.id];
    System.debug('Fullfilment Inputs  ---> '+fulfillmentinputs);



    //create a incident first
    //inserting an incident
    BMCServiceDesk__Incident__c incident = new BMCServiceDesk__Incident__c();
    incident.BMCServiceDesk__FKUrgency__c = HD_Test_Data_Factory.urgencyMap.get('Severity 3');
    incident.BMCServiceDesk__FKImpact__c =   HD_Test_Data_Factory.impactMap.get('LOW');
    incident.BMCServiceDesk__FKRequestDefinition__c = reqdef.id;
    User user = [SELECT Id FROM User WHERE UserName like '%abudnar@akamai.com%' LIMIT 1];
    incident.BMCServiceDesk__FKClient__c = user.Id;
    incident.OwnerId = user.Id;
    insert incident;
    System.debug('Inserted Incident ----> '+incident);


    
    //lets set the request details
    BMCServiceDesk__SRM_RequestDetail__c reqdetail = new BMCServiceDesk__SRM_RequestDetail__c();
    reqdetail.BMCServiceDesk__FKClient__c = UserInfo.getUserId();
    reqdetail.BMCServiceDesk__FKIncident__c = incident.id;
    reqdetail.BMCServiceDesk__FKRequestDefinition__c = reqdef.id;
    reqdetail.BMCServiceDesk__DateExpected__c = Date.today(); 
    insert reqdetail;
    System.debug('Inserted Request Detail ----> '+reqdetail);

    //lets insert the fufillment inputs to Request Input details
    List<BMCServiceDesk__SRM_RequestDetailInputs__c> reqdetInp = new List<BMCServiceDesk__SRM_RequestDetailInputs__c>();

    //looping through fullfilment
    for(BMCServiceDesk__SRM_FulfillmentInputs__c fulInp : fulfillmentinputs )
    {
      BMCServiceDesk__SRM_RequestDetailInputs__c reqdeinpinsertdata = new BMCServiceDesk__SRM_RequestDetailInputs__c();
      reqdeinpinsertdata.BMCServiceDesk__FKRequestDetail__c = reqdetail.id;
      reqdeinpinsertdata.BMCServiceDesk__FKFulfillmentInputs__c = fulInp.id;
      reqdeinpinsertdata.BMCServiceDesk__Input__c = fulInp.BMCServiceDesk__Prompt__c;

      //logic for picklist values, will alwayz pick the first value dynamically
      if( fulInp.BMCServiceDesk__Prompt__c == 'picklist')
      {
        String[] picklist_label_value_array =  String.valueof(fulInp.BMCServiceDesk__InputValues__c).split('П');
        System.debug('-----> '+picklist_label_value_array[0]);
        for(String lable_value_array : picklist_label_value_array)
        {
          String[] labelval = lable_value_array.split('ф');
          System.debug(' Label value ----> '+labelval[0]);
          System.debug(' Value value ----> '+labelval[1]);
          reqdeinpinsertdata.BMCServiceDesk__Response__c = labelval[0];
          reqdeinpinsertdata.BMCServiceDesk__StoredValue__c = labelval[1];
          break;
        }//for(String lable_value_array : picklist_label_value_array)

      }else{//if( fulInp.BMCServiceDesk__Prompt__c == 'picklist')
        reqdeinpinsertdata.BMCServiceDesk__Response__c = 'Testinput@akamai.com;';
        reqdeinpinsertdata.BMCServiceDesk__StoredValue__c =  'Testinput@akamai.com;';
      }

      //adding the request details input to List
      reqdetInp.add(reqdeinpinsertdata);

    }//for(BMCServiceDesk__SRM_FulfillmentInputs__c fulInp : fulfillmentinputs )

    //insert the Request details inputs 
    Insert reqdetInp;

    //Updating Incident with Req detail & Req Def
    incident.BMCServiceDesk__FKRequestDefinition__c = reqdef.id;
    incident.BMCServiceDesk__FKRequestDetail__c = reqdetail.id;
    update incident;

    List<BMCServiceDesk__Incident__c> SrmIncidentsList = [select Id,Name,BMCServiceDesk__Type__c,BMCServiceDesk__FKRequestDefinition__c,BMCServiceDesk__FKRequestDetail__c,BMCServiceDesk__FKBusinessService__c,BMCServiceDesk__FKServiceOffering__c from BMCServiceDesk__Incident__c Where Id =: incident.id ];
    System.debug('Incident to SR List ----> '+SrmIncidentsList);

    test.startTest();
    //Now test the page controller
    PageReference pagerf = Page.ServiceRequestinputdetailsecure; 
    Test.setCurrentPage(pagerf);
    //setting page parameter
    ApexPages.currentPage().getParameters().put('id',SrmIncidentsList[0].id ); 
    //initialization  

    ApexPages.StandardController srmstdctrl = new ApexPages.StandardController(SrmIncidentsList[0]);
    HD_ServiceRequestinputdetailsecure_ctrl srmsrdetext = new HD_ServiceRequestinputdetailsecure_ctrl(srmstdctrl);


    //test for Print services page
    //Lets insert the print record

    HD_SRMPrintService__c printsrv = new HD_SRMPrintService__c();
    printsrv.Template_Name__c = 'HR compensation letter';
    printsrv.Request_Definition__c = reqdef.id;
    printsrv.Template_formate__c = 'To,[Request For],I would like to gladly inform you that your salary has been increased by [amount] starting from [effective day]. Your new monthly salary will be [new salary]. This increase resembles a recognition to your outstanding efforts. The company values your contribution and continuously looks for ways to reward loyal and hard working employees like yourself.Your Request given below :[Priority][CC][Short Description ( encrypted once saved )]Thanks,HR Team';   
    Insert printsrv;   
    System.Debug('Print Services Record : ----> '+printsrv);    


    //Now test the page controller
    PageReference printservicespage = Page.ServiceRequestprintservice; 
    Test.setCurrentPage(printservicespage);
    ApexPages.currentPage().getParameters().put('id',printsrv.id );
    ApexPages.currentPage().getParameters().put('reqdefid',reqdef.id);
    ApexPages.currentPage().getParameters().put('incid',SrmIncidentsList[0].id );

    ApexPages.StandardController srmprintservices = new ApexPages.StandardController(printsrv);
    HD_SRMPrintServiceExtension hdsrmprntsvr = new HD_SRMPrintServiceExtension(srmprintservices);
    test.stopTest();      


  }//static TestMethod void PositiveTestcase()


}//END OF TEST Class