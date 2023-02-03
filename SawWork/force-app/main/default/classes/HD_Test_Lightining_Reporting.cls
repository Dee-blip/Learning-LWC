/*
*
*Template: Apex Test Class
*Version: 1.0
*@author: Nikhil Karn @ Akamai Technologies Ltd.
*Created Date : 6th Aug, 2018
*Purpose : This is the test class for class HD_Lightining_Reporting.
*Name Of methods:
*Number Of methods: 
*Test Class Associated : 
*Controller (Boolean): False
*Page Used/Associated (default -> NONE) : NONE
*Trigger Associated : [  ]
*Class used : 
*@Last Modified By: shashank hegade
* Modification Log ===============================================================
* Date               Author               Modification
* Nov 29th, 2021     Aneesh Budnar        PRTORES-2358 - HD Code Scanner 1 fixes
*/

@isTest(seeAllData = false)
public class HD_Test_Lightining_Reporting {
    
    public static Map<String,Id> result;
    public static Map<String,Id> categoriesCreated;
    public static User contextUser;
    public static List<string> requestDefinationsList=new List<String>();
    
    static{//setting up the data 
        contextUser=[SELECT Id, PermissionSet.Name,AssigneeId,Assignee.HD_View_Helpdesk_Confidential_Data__c FROM PermissionSetAssignment where PermissionSet.Name = 'HD_HR_View_Encrypted_data_permission' and Assignee.HD_View_Helpdesk_Confidential_Data__c = true and Assignee.isActive = true limit 1].Assignee;
        //contextUser = [select Id, username from User where Profile.name = 'System Administrator' and isActive = true limit 1];
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
        
        result=HD_TestDataFactory_ServiceRequest.setUpServiceRequest('testName18','testTitle18',categoriesCreated.get('Compensation'),fulfilmentInputLists,'nkarn@akamai.com',true,HD_IncidentTestDataFactory.Team.HR);
        
        requestDefinationsList.add(result.get('serviceRequestId'));
        //requestDefinationsList.add('a5x0S00000001ReQAI');
        System.debug('RESULT========'+result);
        System.debug('requestDefinationList========'+requestDefinationsList);
        
        
    }
    
    
    @isTest(seeAllData = false) 
    public static void callTestHelpMethod(){
       
        //getting reqdef and fullfillment inputs  -- If in futrue if test fails, please chagnge the Service Request.
        BMCServiceDesk__SRM_RequestDefinition__c reqdef = [ select Id,Name from BMCServiceDesk__SRM_RequestDefinition__c limit 5000][0];
        
        
        System.debug(LoggingLevel.DEBUG, 'Request Definition ---> '+reqdef);
        //getting fullfillment Inputs for requested Request Definition
        List<BMCServiceDesk__SRM_FulfillmentInputs__c> fulfillmentinputs = [select Id,Name,BMCServiceDesk__ResponseType__c,BMCServiceDesk__Prompt__c,BMCServiceDesk__Required__c,BMCServiceDesk__InputValues__c from BMCServiceDesk__SRM_FulfillmentInputs__c where BMCServiceDesk__FKRequestDefinition__c =: reqdef.id];
        System.debug(LoggingLevel.DEBUG, 'Fullfilment Inputs  ---> '+fulfillmentinputs);
        
        
        
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
        System.debug(LoggingLevel.DEBUG, 'Inserted Incident ----> '+incident);
        
        
        
        //lets set the request details
        BMCServiceDesk__SRM_RequestDetail__c reqdetail = new BMCServiceDesk__SRM_RequestDetail__c();
        reqdetail.BMCServiceDesk__FKClient__c = UserInfo.getUserId();
        reqdetail.BMCServiceDesk__FKIncident__c = incident.id;
        reqdetail.BMCServiceDesk__FKRequestDefinition__c = reqdef.id;
        reqdetail.BMCServiceDesk__DateExpected__c = Date.today(); 
        insert reqdetail;
        System.debug(LoggingLevel.DEBUG, 'Inserted Request Detail ----> '+reqdetail);
        
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
                String[] picklistLabelValueArray =  String.valueof(fulInp.BMCServiceDesk__InputValues__c).split('П');
                System.debug('-----> '+picklistLabelValueArray[0]);
                for(String lableValueArray : picklistLabelValueArray)
                {
                    String[] labelval = lableValueArray.split('ф');
                    System.debug(' Label value ----> '+labelval[0]);
                    System.debug(' Value value ----> '+labelval[1]);
                    reqdeinpinsertdata.BMCServiceDesk__Response__c = labelval[0];
                    reqdeinpinsertdata.BMCServiceDesk__StoredValue__c = labelval[1];
                    break;
                }//for(String lableValueArray : picklistLabelValueArray)
                
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
        
        List<BMCServiceDesk__Incident__c> srmIncidentsList = [select Id,Name,BMCServiceDesk__Type__c,BMCServiceDesk__FKRequestDefinition__c,BMCServiceDesk__FKRequestDetail__c,BMCServiceDesk__FKBusinessService__c,BMCServiceDesk__FKServiceOffering__c from BMCServiceDesk__Incident__c Where Id =: incident.id ];
        System.debug(LoggingLevel.DEBUG, 'Incident to SR List ----> '+srmIncidentsList);
        
      
        
        
        Date dt=Date.today();
        Integer tempVar;
        String day;
        String month;
        String year=String.valueOf(dt.year());
        
        
        tempVar=dt.day();
        tempvar=tempvar+1;
        
        if(tempVar<10){
            day='0'+tempVar;
        }else{
            day=String.valueOf(tempVar);
        }
        
        
        tempVar=dt.month();
        
        if(tempVar<10){
            month='0'+tempVar;
        }else{
            month=String.valueOf(tempVar);
        }
        
        
        List<BMCServiceDesk__SRM_RequestDefinition__c> reqDef1=HD_Lightining_Reporting.getListOfActiveServiceRequest();
        
        List<BMCserviceDesk__status__c> statusList=HD_Lightining_Reporting.getListOfStatus();
        
        
        

        String toDate= year+'-'+month+'-'+day;
        String fromDate='2000-01-01';
        
        
        HD_Lightining_Reporting.getServiceRequestReport(requestDefinationsList,null,toDate,'2000-01-01');
        
        
        
        fromDate+='T00:00:00.000+0000';
        toDate+='T00:00:00.000+0000';
        
        
        String whereClause='BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKRequestDefinition__r.Id IN :requestDefinationsList';
        //String query='SELECT BMCServiceDesk__Input__c,BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__r.Name,BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__r.HD_Owner_user_queue__c,BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__r.Opened_Date_For__c,BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKRequestDefinition__r.BMCServiceDesk__serviceRequestTitle__c, BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__r.BMCServiceDesk__Category_ID__c,BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__r.SI_Created_Date_International_format__c,BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__r.BMCServiceDesk__FKStatus__r.name,BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__r.BMCServiceDesk__Client_Name__c, BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__r.Launch_Console__c,BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__r.HD_Approval_Status__c,BMCServiceDesk__Response__c, HD_Incident_id__c FROM BMCServiceDesk__SRM_RequestDetailInputs__c WHERE  '+whereClause+' AND CreatedDate <='+toDate+' AND CreatedDate >='+fromDate+' ORDER BY HD_Incident_id__c';
        String query='SELECT BMCServiceDesk__Input__c,BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__r.Name,BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__r.HD_Owner_user_queue__c,BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__r.Opened_Date_For__c,BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__r.BMCServiceDesk__Service_Request_Title__c, BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__r.BMCServiceDesk__Category_ID__c,BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__r.SI_Created_Date_International_format__c,BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__r.BMCServiceDesk__Status_ID__c,BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__r.BMCServiceDesk__Client_Name__c, BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__r.Launch_Console__c,BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__r.HD_Approval_Status__c,BMCServiceDesk__Response__c, HD_Incident_id__c FROM BMCServiceDesk__SRM_RequestDetailInputs__c WHERE  '+whereClause+' AND CreatedDate <='+toDate+' AND CreatedDate >='+fromDate+' ORDER BY HD_Incident_id__c'; //changed two column name @shashankhegade
        List<BMCServiceDesk__SRM_RequestDetailInputs__c> requestDetailInputs=Database.query(query);
        
        HD_Lightining_Reporting.testHelp(requestDetailInputs);
    }
}