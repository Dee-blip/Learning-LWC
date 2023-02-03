/*
 *
 *Template: Apex Class
 *Version: 1.0
 *@author: Nikhil Karn @ Akamai Technologies Ltd.
 *Created Date : 13th March, 2018
 *Purpose : This Class is responsible to genrate service request as per the criteria for the test classes
 *Number Of methods: 5
 *Test Class Associated : 
 *Controller (Boolean): False
 *Page Used/Associated (default -> NONE) : NONE
 *Trigger Associated : [  ]
 *Class used : 
 *@Last Modified By:
 * Modification Log ===============================================================
 * Date                 Author              Modification
 * 5 Aug 2020            Abhishek Singh      PRTORES-1811 - HD code scan 2020 - Blocker and critical part 5
 * Sep 28th, 2020       Aneesh Budnar       PRTORES-1906-Create Events for ODI Load Trigger 
 */

public class HD_TestDataFactory_ServiceRequest {

    public static HD_TestDataFactory_ServiceRequest testDataFactory;
    public static Id createdRequestDefinationId;
    public static String serviceRequestNameTemp;
    public static String clientEmailAddressTemp;
    public static Map<String,id> resultToBeReturned=new Map<String,id>();
    public HD_TestDataFactory_ServiceRequest(){
        System.debug('Load Constructor:HD_TestDataFactory_ServiceRequest');
        testDataFactory = new HD_TestDataFactory_ServiceRequest();
        System.debug('END Constructor:HD_TestDataFactory_ServiceRequest');
    }

    public class FulfilmentInputWrapperClass{
        public String order {get;set;}
        public String responseType {get;set;}
        public String prompt {get;set;}
        public String required {get;set;}
        public String hidden {get;set;}
        public String runWorkflow {get;set;}
        public String inputValuesHolder {get;set;}
    }

    public class RequestDefinitionclass{
        public String RequestdefinitionName;
        public String ServiceRequestTitle;
        public Id CategoryID;
        public String Description;
        public String BusinessServiceName;
        public String ServiceOfferingName;
        public String Online; 
        public String ApprovalRequired;
        public String UserInstructions;
        public List<FulfilmentInputWrapperClass> fulfillmentInputs;
    }

    class RequestDetailsApiWrapperClass{
        public String serviceRequestName{get;set;}
        public String clientEmail{get;set;}
        public Id requestdefinitonID{get;set;}
        public boolean submitted{get;set;}
        public list<RequestdetailInputsdetailsApiWrapperClass> requestdetailinputsdetails{get;set;}
    }

    class RequestdetailInputsdetailsApiWrapperClass{
        public Id requestDetailId {get;set;}
        public Id fulfillmentInputId {get;set;}
        public String inputPromptName {get;set;}
        public String responseToBeStored{get;set;}
    }

    static String businessServiceName='Identity & Access Management';
    static String serviceOfferingName='Access offering';
    static Boolean secureFlag=false;
    static HD_IncidentTestDataFactory.Team teamForWhichIncidentWillBeCreated=null;

    /*
     *
     *
     *
     */
    public static Map<String,Id> setUpServiceRequest(String serviceRequestName,String serviceRequestTitle,Id categoryId,List<FulfilmentInputWrapperClass> fulfilmentInputLists,String clientEmailAddress,Boolean secureFlaginput){

        System.debug('Starting setting up new Service Request:');
        serviceRequestNameTemp=serviceRequestName;
        clientEmailAddressTemp=clientEmailAddress;
        secureFlag=secureFlaginput;

        try{
            String jsonstr =
                    '{'+
                    '"RequestdefinitionName": "'+serviceRequestName+'",'+
                    '"ServiceRequestTitle": "'+serviceRequestTitle+'",'+
                    '"CategoryID": "'+categoryId+'",'+
                    '"Description": "This Service Request is for test data",'+
                    '"BusinessServiceName": "'+businessServiceName+'",'+
                    '"ServiceOfferingName": "'+serviceOfferingName+'",'+
                    '"Online": "TRUE",'+
                    '"ApprovalRequired": "",'+
                    '"UserInstructions": "",'+
                    genrateFulimentInputJsonString(fulfilmentInputLists)+
                    '}';
            System.debug('----> '+jsonstr);
            Id createdServiceReqId=createServiceRequestFROMJSON(jsonstr);
            resultToBeReturned.put('serviceRequestId',createdServiceReqId);
            return resultToBeReturned;
        }catch(Exception e){
            System.debug('Exception Occured in setUpServiceRequest:'+e);
            return new Map<String,id>();
        }

    }


    /*
    *
    *
    *
    */
    public static Map<String,Id> setUpServiceRequest(String serviceRequestName,String serviceRequestTitle,Id categoryId,List<FulfilmentInputWrapperClass> fulfilmentInputLists,String clientEmailAddress,Boolean secureFlaginput,HD_IncidentTestDataFactory.Team team){
        teamForWhichIncidentWillBeCreated=null;
        if(team!=null){
            teamForWhichIncidentWillBeCreated=team;
        }
        return setUpServiceRequest(serviceRequestName,serviceRequestTitle,categoryId,fulfilmentInputLists,clientEmailAddress,secureFlaginput);
    }


    /*
     *
     *
     *
     */
    public static String genrateFulimentInputJsonString(List<FulfilmentInputWrapperClass> fulfilmentInputLists){
        String temp='';
        for(FulfilmentInputWrapperClass fInput:fulfilmentInputLists){
            temp=temp+'{"order": "'+fInput.order+'","ResponseType": "'+fInput.responseType+'","Prompt": "'+fInput.prompt+'","Required": "'+fInput.required+'","Hidden": "'+fInput.hidden+'","runworkflow": "'+fInput.runWorkflow+'","inputValuesHolder": "'+fInput.inputValuesHolder+'"}';
        }

        String result='"fulfillmentInputs": ['+temp+']';

        return result;
    }


    /*
     *
     *
     *
     */
    public static Id createServiceRequestFROMJSON(String jsonstringtemplate){
        System.debug('Start method:createServiceRequestFROMJSON');
        BMCServiceDesk__SRM_RequestDefinition__c inserted_REQ_DEF;

        try{
            RequestDefinitionclass rfc ;
            if(jsonstringtemplate != null){
                rfc=(RequestDefinitionclass)JSON.deserialize(jsonstringtemplate,RequestDefinitionclass.class);
            }

            //write your logic for executing the Template here
            inserted_REQ_DEF = SRM_Requestdefinition(rfc.RequestdefinitionName,rfc.CategoryID,rfc.ServiceRequestTitle,rfc.Description,rfc.BusinessServiceName,rfc.ServiceOfferingName,Boolean.valueOf(rfc.Online) ,Boolean.valueOf(rfc.ApprovalRequired),rfc.UserInstructions);
            System.debug(' Request Definition Id ---> '+inserted_REQ_DEF.id); 

            //building fulfillment Inputs fields
            List<BMCServiceDesk__SRM_FulfillmentInputs__c> ffiListParameter = new List<BMCServiceDesk__SRM_FulfillmentInputs__c>();

            System.debug('fulfilment input list details:'+rfc.fulfillmentInputs);
            for( FulfilmentInputWrapperClass ffiClass : rfc.fulfillmentInputs ){

                BMCServiceDesk__SRM_FulfillmentInputs__c ffiClassData = new BMCServiceDesk__SRM_FulfillmentInputs__c();
                ffiClassData.BMCServiceDesk__Order__c =  decimal.valueOf(ffiClass.order);
                ffiClassData.BMCServiceDesk__ResponseType__c = ffiClass.responseType;
                ffiClassData.BMCServiceDesk__Prompt__c = ffiClass.prompt;
                ffiClassData.BMCServiceDesk__Required__c = Boolean.valueOf(ffiClass.required);
                ffiClassData.BMCServiceDesk__Hidden__c =   Boolean.valueOf(ffiClass.hidden);
                ffiClassData.Run_workflow__c =  Boolean.valueOf(ffiClass.runWorkflow);
                ffiClassData.Input_Values_holder__c =  ffiClass.inputValuesHolder;

                ffiListParameter.add(ffiClassData);
            }

            if( ffiListParameter.size()>0){
                SRM_FullfilmentInputCreation( inserted_REQ_DEF.id,ffiListParameter);
                createdRequestDefinationId=inserted_REQ_DEF.id;

                createServiceRequest(createdRequestDefinationId,rfc.RequestdefinitionName);
            }

        }catch(Exception e){
            system.debug('[]Exception Happened : '+e+'  Line Number'+e.getLineNumber()+'     Cause'+e.getCause());
        }


        System.debug('END method:createServiceRequestFROMJSON');

        return inserted_REQ_DEF.id;

    }//


    /*
     *
     *
     *
     */
    private static Map<String,BMCServiceDesk__SYSTemplate__c> SRM_Template_Generator(String RequestdefinitionName){

        System.debug('Start method:SRM_Template_Generator');

        //return map
        Map<String,BMCServiceDesk__SYSTemplate__c> returnedMap = new Map<String,BMCServiceDesk__SYSTemplate__c>();

        BMCServiceDesk__SYSTemplate__c incidentTemplate = new BMCServiceDesk__SYSTemplate__c();
        BMCServiceDesk__SYSTemplate__c requestDetailTemplate = new BMCServiceDesk__SYSTemplate__c();
        BMCServiceDesk__SYSTemplateLink__c templateLinkage = new BMCServiceDesk__SYSTemplateLink__c();

        //1st generate Incident Template
        incidentTemplate.BMCServiceDesk__templateFor__c = 'Incident';
        incidentTemplate.Name = RequestdefinitionName+'-INC';
        incidentTemplate.BMCServiceDesk__description__c = 'Incident Template for '+ RequestdefinitionName;
        incidentTemplate.BMCServiceDesk__keywords__c = RequestdefinitionName;

        Insert incidentTemplate;
        system.debug('Inserted ---> '+incidentTemplate);

        //2nd generate RD template
        requestDetailTemplate.BMCServiceDesk__templateFor__c = 'Request Detail';
        requestDetailTemplate.Name = RequestdefinitionName+'-RD';
        requestDetailTemplate.BMCServiceDesk__description__c = 'Request Detail Template for '+ RequestdefinitionName;
        requestDetailTemplate.BMCServiceDesk__keywords__c = RequestdefinitionName;

        insert requestDetailTemplate;
        system.debug('Inserted ---> '+requestDetailTemplate);

        //Template Info populating code



        //Creating the template linkage 
        templateLinkage.BMCServiceDesk__linkedTemplateId__c = incidentTemplate.id; 
        templateLinkage.BMCServiceDesk__parentTemplateId__c  = requestDetailTemplate.id;

        Insert templateLinkage;
        system.debug('Inserted ---> '+templateLinkage);

        //adding the incident and Request details Ids and data in to the MAp
        returnedMap.put('Incident',incidentTemplate);
        returnedMap.put('Request Detail',requestDetailTemplate);
        System.debug('END method:SRM_Template_Generator');
        return returnedMap;
    }//


    /*
     *
     *
     *
     */
    public static BMCServiceDesk__SRM_RequestDefinition__c SRM_Requestdefinition( String RequestdefinitionName ,ID CategoryID ,String ServiceRequestTitle, String Description, String BusinessServiceName,String ServiceOfferingName,Boolean Online, Boolean ApprovalRequired,String UserInstructions){  
        System.debug('Start method:SRM_Requestdefinition');

        //Map for Inserted Template
        Map<String,BMCServiceDesk__SYSTemplate__c> processtemplateMap = SRM_Template_Generator(RequestdefinitionName);


        //Logic for finding the BUsiness services and Service Offeing id Via Name
        Map<String,BMCServiceDesk__BMC_BaseElement__c> businessServiceandofferingMap = new Map<String,BMCServiceDesk__BMC_BaseElement__c>();
        BMCServiceDesk__BMC_BaseElement__c blist1=new BMCServiceDesk__BMC_BaseElement__c();

        blist1.BMCServiceDesk__Name__c='Test Identity & Access Management';
        blist1.BMCServiceDesk__ServiceType__c='Test Offering';

        insert blist1;

        BMCServiceDesk__BMC_BaseElement__c bList2=new BMCServiceDesk__BMC_BaseElement__c();

        bList2.BMCServiceDesk__Name__c='Test Access offering';
        bList2.BMCServiceDesk__ServiceType__c='Test Offering';

        insert bList2;

        List<BMCServiceDesk__BMC_BaseElement__c> bslist = [Select id,Name,BMCServiceDesk__ServiceType__c,BMCServiceDesk__Parent_Service__c from BMCServiceDesk__BMC_BaseElement__c limit 500];
        System.debug('BSLIST:'+bslist);
        for(BMCServiceDesk__BMC_BaseElement__c bso : bslist)
        {
            businessServiceandofferingMap.put(bso.Name, bso);

        }


        BMCServiceDesk__SRM_RequestDefinition__c rd = new BMCServiceDesk__SRM_RequestDefinition__c();
        rd.Name = RequestdefinitionName;
        rd.BMCServiceDesk__AllAccounts__c = TRUE; //checkbox
        rd.BMCServiceDesk__FKCategory__c = CategoryID;//Category ID
        rd.BMCServiceDesk__serviceRequestTitle__c = ServiceRequestTitle; //title for the service
        rd.BMCServiceDesk__Profiles__c = 'ALL';

        rd.BMCServiceDesk__Description__c = Description;



        rd.BMCServiceDesk__FKBusinessService__c = businessServiceandofferingMap.get('Test Identity & Access Management').id;
        rd.BMCServiceDesk__FKServiceOffering__c = businessServiceandofferingMap.get('Test Access offering').id;

        rd.BMCServiceDesk__Online__c =  Online;
        rd.BMCServiceDesk__ApprovalRequired__c =  ApprovalRequired;
        rd.BMCServiceDesk__Status__c = 'Deployed';
        rd.BMCServiceDesk__ProvideInformation__c = 'Attachment__c';

        rd.BMCServiceDesk__UserInstructions__c = UserInstructions;

        //Insertion here
        Insert rd;
        system.debug('Inserted ---> '+rd);


        //creating process template
        BMCServiceDesk__SRM_ProcessTemplate__c pt = new BMCServiceDesk__SRM_ProcessTemplate__c();
        pt.BMCServiceDesk__FKRequestDefinition__c = rd.id;
        pt.BMCServiceDesk__FKTemplate__c = processtemplateMap.get('Request Detail').id;

        //Insert here
        Insert pt;
        system.debug('Inserted ---> '+pt);
        System.debug('END method:SRM_Requestdefinition');
        return rd;

    }//



    //Method for creating input fields for the request definition
    /*
     *
     *
     *
     */
    private static List<BMCServiceDesk__SRM_FulfillmentInputs__c> SRM_FullfilmentInputCreation(id requestdefinitionID,List<BMCServiceDesk__SRM_FulfillmentInputs__c> fullfillmentinputsList){
        System.debug('Start method:SRM_FullfilmentInputCreation');
        System.debug('Starting Fullfilment input creation');
        //inserting the Fields
        List <BMCServiceDesk__SRM_FulfillmentInputs__c> ffiToInsertList = new List<BMCServiceDesk__SRM_FulfillmentInputs__c>();
        for( BMCServiceDesk__SRM_FulfillmentInputs__c ff : fullfillmentinputsList){
            BMCServiceDesk__SRM_FulfillmentInputs__c ffi = new BMCServiceDesk__SRM_FulfillmentInputs__c();
            ffi.BMCServiceDesk__Order__c =  ff.BMCServiceDesk__Order__c;
            ffi.BMCServiceDesk__ResponseType__c = ff.BMCServiceDesk__ResponseType__c;
            ffi.BMCServiceDesk__Prompt__c = ff.BMCServiceDesk__Prompt__c;
            ffi.BMCServiceDesk__Required__c = ff.BMCServiceDesk__Required__c;
            ffi.BMCServiceDesk__Hidden__c =   ff.BMCServiceDesk__Hidden__c;
            ffi.Run_workflow__c =  ff.Run_workflow__c;
            ffi.Input_Values_holder__c =  ff.Input_Values_holder__c;
            ffi.BMCServiceDesk__FKRequestDefinition__c = requestdefinitionID;

            if(secureFlag){
                ffi.HD_Secure_Field__c =true;
            } 

            //adding it to the LIst
            ffiToInsertList.add(ffi); 
        }
        System.debug('Fulfilment input field Size:'+ffiToInsertList.size()+'    and list:'+ffiToInsertList);
        if( ffiToInsertList.size() > 0 ){
            try{
                insert ffiToInsertList;
            }catch(Exception e){
                System.debug('Exception occured while inserting fulfilment input:'+e);
            }
        }
        system.debug('Input Fields inserted ----> '+ffiToInsertList);
        System.debug('END method:SRM_FullfilmentInputCreation');
        return ffiToInsertList;
    }//

    /*********************************************************************************************************************/
    /*********************************************************************************************************************/
    /***************************************Below Methods are to create new service requests*****************************/
    /*********************************************************************************************************************/
    /*********************************************************************************************************************/




    private static Id createServiceRequest( Id serciceRequestId,String serviceRequestName){
        System.debug('Start method:createServiceRequest');
        String IncidentID = null;

        BMCServiceDesk__SRM_RequestDetail__c srmRequestDetail = new BMCServiceDesk__SRM_RequestDetail__c();

        //validating service request 
        validateRequsetDefination(serciceRequestId,serviceRequestName);

        srmRequestDetail.BMCServiceDesk__ServiceRequest__c = serviceRequestName;
        Id clientId=getClientId(clientEmailAddressTemp);
        srmRequestDetail.BMCServiceDesk__FKClient__c = clientId;
        srmRequestDetail.BMCServiceDesk__FKRequestDefinition__c = serciceRequestId;
        srmRequestDetail.BMCServiceDesk__Submitted__c = true;

        Savepoint dataBaseSavePoint  = Database.setSavepoint();
        try{

            insert srmRequestDetail;
            System.debug('Created Service Request: '+srmRequestDetail.id);

            //Get the fullfilment inputs details  
            List<BMCServiceDesk__SRM_RequestDetailInputs__c> requestDetailInputsList = new List<BMCServiceDesk__SRM_RequestDetailInputs__c>();

            List<RequestdetailInputsdetailsApiWrapperClass> requestdetailinputsdetails=getpayLoadExpected(serciceRequestId);
            System.debug('FINAL SETUP:'+requestdetailinputsdetails);
            for( RequestdetailInputsdetailsApiWrapperClass rdindawc : requestdetailinputsdetails){
                BMCServiceDesk__SRM_RequestDetailInputs__c requestDetailInput = new BMCServiceDesk__SRM_RequestDetailInputs__c();
                requestDetailInput.BMCServiceDesk__Input__c = rdindawc.inputPromptName;
                requestDetailInput.BMCServiceDesk__FKFulfillmentInputs__c = rdindawc.fulfillmentInputId;
                requestDetailInput.BMCServiceDesk__FKRequestDetail__c = srmRequestDetail.Id;
                requestDetailInput.BMCServiceDesk__Response__c   =   rdindawc.responseToBeStored;
                requestDetailInput.BMCServiceDesk__StoredValue__c =   rdindawc.responseToBeStored; 

                requestDetailInputsList.add(requestDetailInput);
            }

            insert  requestDetailInputsList; 

            //lets create the incident and link to this 
            HD_IncidentTestDataFactory rfFactory =  new HD_IncidentTestDataFactory();
            BMCServiceDesk__Incident__c incident=null;
            if(teamForWhichIncidentWillBeCreated!=null){
                     incident = rfFactory.getIncidentTestData(teamForWhichIncidentWillBeCreated);
                }else{
                     incident = rfFactory.getIncidentTestData(HD_IncidentTestDataFactory.Team.GENERIC);
                }

            incident.BMCServiceDesk__FKClient__c = clientId;
            incident.BMCServiceDesk__FKRequestDefinition__c = serciceRequestId;
            incident.BMCServiceDesk__FKRequestDetail__c = srmRequestDetail.Id;
			incident.BMCServiceDesk__Service_Request_Title__c = serviceRequestName;
            update incident;
            IncidentID =  incident.id;
            srmRequestDetail.BMCServiceDesk__FKIncident__c=IncidentID;
            update srmRequestDetail;

        }catch(Exception e){
            Database.rollback(dataBaseSavePoint); 
            //throw new HDWebserviceCustomException(e,e.getMessage(),400);
        }
        System.debug('END method:createServiceRequest');
        resultToBeReturned.put('incidentId',IncidentID);
        resultToBeReturned.put('serviceRequestDetailId',srmRequestDetail.Id);
        return srmRequestDetail.Id;
    }






    private static Id getClientId(String emailAddress){
         
        return System.UserInfo.getUserId();
    }






    private static void validateRequsetDefination(Id requestdefinitonID,String serviceRequestName){
        System.debug('Start method:validateRequsetDefination');
        BMCServiceDesk__SRM_RequestDefinition__c requestDefiniton = [Select Id,Name,BMCServiceDesk__Description__c,BMCServiceDesk__serviceRequestTitle__c,BMCServiceDesk__FKCategory__r.name,BMCServiceDesk__Inactive__c from BMCServiceDesk__SRM_RequestDefinition__c WHERE Id =:requestdefinitonID][0];

        if(requestDefiniton==null){
            //throw new HDWebserviceCustomException('Service Request ID is NOT valid',400);
        }
        if(requestDefiniton.BMCServiceDesk__Inactive__c==true){
            //throw new HDWebserviceCustomException('Service Request is NOT Active',400);
        }
        if(requestDefiniton.name!=serviceRequestName){
            //throw new HDWebserviceCustomException('Service Request NAME is not valid',400);
        }
        System.debug('END method:validateRequsetDefination');


    }







    private  static List<RequestdetailInputsdetailsApiWrapperClass> getpayLoadExpected(String serviceRequestNameorID){

        System.debug('Start method:getpayLoadExpected');
        String requestDefinationQuery='Select Id,Name,BMCServiceDesk__Description__c,BMCServiceDesk__serviceRequestTitle__c,BMCServiceDesk__FKCategory__r.name,BMCServiceDesk__Inactive__c from BMCServiceDesk__SRM_RequestDefinition__c WHERE BMCServiceDesk__Online__c =true ORDER BY Name';
        String fulfilmentInputsQuery='Select BMCServiceDesk__Prompt__c,BMCServiceDesk__Condition__c,BMCServiceDesk__Conditional__c,BMCServiceDesk__Hidden__c,BMCServiceDesk__ResponseType__c,Input_Values_holder__c,BMCServiceDesk__InputValues__c,BMCServiceDesk__Required__c From BMCServiceDesk__SRM_FulfillmentInputs__c where BMCServiceDesk__FKRequestDefinition__c =';

        BMCServiceDesk__SRM_RequestDefinition__c  requestDefination=[Select Id,Name,BMCServiceDesk__Description__c,BMCServiceDesk__serviceRequestTitle__c,BMCServiceDesk__FKCategory__r.name,BMCServiceDesk__Inactive__c from BMCServiceDesk__SRM_RequestDefinition__c WHERE id =:serviceRequestNameorID][0];
        RequestDetailsApiWrapperClass rdwc = new RequestDetailsApiWrapperClass();
        List<BMCServiceDesk__SRM_FulfillmentInputs__c> fulfilmentInputs = new List<BMCServiceDesk__SRM_FulfillmentInputs__c>() ;


        fulfilmentInputs = [Select BMCServiceDesk__Prompt__c,BMCServiceDesk__Condition__c,BMCServiceDesk__Conditional__c,BMCServiceDesk__Hidden__c,BMCServiceDesk__ResponseType__c,Input_Values_holder__c,BMCServiceDesk__InputValues__c,BMCServiceDesk__Required__c From BMCServiceDesk__SRM_FulfillmentInputs__c where BMCServiceDesk__FKRequestDefinition__c =: serviceRequestNameorID ];
        List<RequestdetailInputsdetailsApiWrapperClass> rdidwcList = new List<RequestdetailInputsdetailsApiWrapperClass>();

        for(BMCServiceDesk__SRM_FulfillmentInputs__c fulfilInput:fulfilmentInputs){

            RequestdetailInputsdetailsApiWrapperClass rdidwc = new RequestdetailInputsdetailsApiWrapperClass();
            rdidwc.requestDetailId = serviceRequestNameorID;
            rdidwc.fulfillmentInputId = fulfilInput.id;
            rdidwc.inputPromptName = fulfilInput.BMCServiceDesk__Prompt__c;
            rdidwc.responseToBeStored = 'TEST DATA RESPONSE';     
            rdidwcList.add(rdidwc);   
        }

        rdwc.requestdetailinputsdetails = rdidwcList;

        System.debug('END method:getpayLoadExpected');
        return rdidwcList;

    }
}