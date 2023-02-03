/*
Template: Apex Test Class/Trigger Template

CopyRight: Hemant Kumar @ Akamai Technologies Ltd.

Version: 1.0

Created Date : Jan 13 2016

Base Line : Used as a part for SRM template generator

Purpose : The Code factory for JSON template generator
          
Usage : Used in creating the SRM template
          
Test Class Asssociated : null

Controller (Boolean): false

Page Used/Asssociated (default -> NONE) : null

Trigger Associated : NONE
Class Associated : [ ]
              
*/  


/*
Json format for calling this class


{
    "RequestdefinitionName": "",
    "ServiceRequestTitle": "",
    "CategoryID": "",
    "Description": "",
    "BusinessServiceName": "",
    "ServiceOfferingName": "",
    "Online": "",
    "ApprovalRequired": "",
    "UserInstructions": "",
    "fulfillmentInputs": [{
            "order": "1",
            "ResponseType": "Radio Button",
            "Prompt": "Platform",
            "Required": "TRUE",
            "Hidden": "FALSE",
            "Run_workflow": "TRUE",
            "Input_Values_holder": "Windows?Windows?True*Unix?Unix?False"
        },

        {
            "order": "2",
            "ResponseType": "Text Field",
            "Prompt": "Time in ET (3 hour duration)",
            "Required": "FALSE",
            "Hidden": "FALSE",
            "Run_workflow": "FALSE",
            "Input_Values_holder": ""
        },

        {
            "order": "3",
            "ResponseType": "Text Area",
            "Prompt": "Service Name:",
            "Required": "TRUE",
            "Hidden": "FALSE",
            "Run_workflow": "FALSE",
            "Input_Values_holder": ""
        },

        {
            "order": "4",
            "ResponseType": "Header Section",
            "Prompt": "OS/Applications*",
            "Required": "",
            "Hidden": "",
            "Run_workflow": "",
            "Input_Values_holder": ""
        },

        {
            "order": "5",
            "ResponseType": "Picklist",
            "Prompt": "Environment",
            "Required": "TRUE",
            "Hidden": "FALSE",
            "Run_workflow": "TRUE",
            "Input_Values_holder": "Dev?Dev?False*QA?QA?False*Stage?Stage?False*Prod?Prod?False"
        }



    ]
}
* Modification Log ===============================================================
* Date 				      Author 				      Modification
* Aug 08th, 2020    Aneesh Budnar       PRTORES-1810 - Code scanner fixes
*/



public with sharing class HD_SRM_TemplateGenerator_Factory 
{
    //Generic Constructor
    public HD_SRM_TemplateGenerator_Factory() 
    {
        
    }

    //Template generator for Requestdefinition
    //This is step one.
    //fields are Template for , Name, Description, Keywords
      private Map<String,BMCServiceDesk__SYSTemplate__c> SRM_Template_Generator(String RequestdefinitionName)
      {
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
       
       return returnedMap;
      }//


    //Method for creating request definition
    //This is step two
    //Test command 
    /*
    HD_SRM_TemplateGenerator_Factory tf = new HD_SRM_TemplateGenerator_Factory();
    tf.SRM_Requestdefinition('Test Request definition','a58Z0000000DFdg','Create the dummy Service Request','Test DEscription','Personal Computing Services','Desktop Services',true,false,'Please this is a Dummy Service request by Code');
    */
    public BMCServiceDesk__SRM_RequestDefinition__c SRM_Requestdefinition( String RequestdefinitionName ,ID CategoryID ,String ServiceRequestTitle, String Description, String BusinessServiceName,String ServiceOfferingName,Boolean Online, Boolean ApprovalRequired,String UserInstructions)
    {  
       //Map for Inserted Template
       Map<String,BMCServiceDesk__SYSTemplate__c> processtemplateMap = SRM_Template_Generator(RequestdefinitionName);


        //Logic for finding the BUsiness services and Service Offeing id Via Name
       Map<String,BMCServiceDesk__BMC_BaseElement__c> businessServiceandofferingMap = new Map<String,BMCServiceDesk__BMC_BaseElement__c>();
       List<BMCServiceDesk__BMC_BaseElement__c> bslist = [Select id,Name,BMCServiceDesk__ServiceType__c,BMCServiceDesk__Parent_Service__c from BMCServiceDesk__BMC_BaseElement__c LIMIT 500];
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

      
         
       rd.BMCServiceDesk__FKBusinessService__c = businessServiceandofferingMap.get(BusinessServiceName).id;
       rd.BMCServiceDesk__FKServiceOffering__c = businessServiceandofferingMap.get(ServiceOfferingName).id;

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

       return rd;

    }//


    
    //Method for creating input fields for the request definition

    private List<BMCServiceDesk__SRM_FulfillmentInputs__c> SRM_FullfilmentInputCreation(id requestdefinitionID,List<BMCServiceDesk__SRM_FulfillmentInputs__c> fullfillmentinputsList)
    {

     //inserting the Fields
    List <BMCServiceDesk__SRM_FulfillmentInputs__c> ffiToInsertList = new List<BMCServiceDesk__SRM_FulfillmentInputs__c>();
    for( BMCServiceDesk__SRM_FulfillmentInputs__c ff : fullfillmentinputsList)
    {
        BMCServiceDesk__SRM_FulfillmentInputs__c ffi = new BMCServiceDesk__SRM_FulfillmentInputs__c();
        ffi.BMCServiceDesk__Order__c =  ff.BMCServiceDesk__Order__c;
        ffi.BMCServiceDesk__ResponseType__c = ff.BMCServiceDesk__ResponseType__c;
        ffi.BMCServiceDesk__Prompt__c = ff.BMCServiceDesk__Prompt__c;
        ffi.BMCServiceDesk__Required__c = ff.BMCServiceDesk__Required__c;
        ffi.BMCServiceDesk__Hidden__c =   ff.BMCServiceDesk__Hidden__c;
        ffi.Run_workflow__c =  ff.Run_workflow__c;
        ffi.Input_Values_holder__c =  ff.Input_Values_holder__c;
        ffi.BMCServiceDesk__FKRequestDefinition__c = requestdefinitionID;

        //adding it to the LIst
        ffiToInsertList.add(ffi); 
    }

    if( ffiToInsertList.size() > 0 )
    {
      insert ffiToInsertList;
    }
    system.debug('Input Fields inserted ----> '+ffiToInsertList);
    
    return ffiToInsertList;
    }//



   // Method for creating Service Request from json 
   //
   public  void SRMServiceRequestFROMJSON(String jsonstringtemplate)
    {
     try
     {
        RequestDefinitionclass rfc ;
       if(jsonstringtemplate != null)
       {
         JSONParser parser = JSON.createParser(jsonstringtemplate);
         while(parser.nextToken() != null)
        {
            if(parser.getCurrentToken() == JSONToken.START_OBJECT)
            {
             rfc = (RequestDefinitionclass)parser.readValueAs(RequestDefinitionclass.class);
             

            }

         }
                  

       }
       system.debug('----> '+rfc.RequestdefinitionName);
       system.debug(' ServiceRequestTitle ----> '+rfc.ServiceRequestTitle);
       system.debug(' CategoryID ----> '+rfc.CategoryID);
       system.debug(' Description ----> '+rfc.Description);
       system.debug(' BusinessServiceName ----> '+rfc.BusinessServiceName);
       system.debug(' ServiceOfferingName ----> '+rfc.ServiceOfferingName);
       system.debug(' Online ----> '+rfc.Online);
       system.debug(' ApprovalRequired ----> '+rfc.ApprovalRequired);
       system.debug(' UserInstructions ----> '+rfc.UserInstructions);
       system.debug(' fulfillmentInputsClass List ----> '+rfc.fulfillmentInputs);
       //write your logic for executing the Template here
       BMCServiceDesk__SRM_RequestDefinition__c inserted_REQ_DEF = SRM_Requestdefinition(rfc.ServiceRequestTitle,rfc.CategoryID,rfc.ServiceRequestTitle,rfc.Description,rfc.BusinessServiceName,rfc.ServiceOfferingName,Boolean.valueOf(rfc.Online) ,Boolean.valueOf(rfc.ApprovalRequired),rfc.UserInstructions);
       System.debug(' Request Definition Id ---> '+inserted_REQ_DEF.id); 

       //building fulfillment Inputs fields
       List<BMCServiceDesk__SRM_FulfillmentInputs__c> ffiListParameter = new List<BMCServiceDesk__SRM_FulfillmentInputs__c>();
       for( fulfillmentInputsClass ffiClass : rfc.fulfillmentInputs )
       {
         BMCServiceDesk__SRM_FulfillmentInputs__c ffiClassData = new BMCServiceDesk__SRM_FulfillmentInputs__c();
        ffiClassData.BMCServiceDesk__Order__c =  decimal.valueOf(ffiClass.Order);
        ffiClassData.BMCServiceDesk__ResponseType__c = ffiClass.ResponseType;
        ffiClassData.BMCServiceDesk__Prompt__c = ffiClass.Prompt;
        ffiClassData.BMCServiceDesk__Required__c = Boolean.valueOf(ffiClass.Required);
        ffiClassData.BMCServiceDesk__Hidden__c =   Boolean.valueOf(ffiClass.Hidden);
        ffiClassData.Run_workflow__c =  Boolean.valueOf(ffiClass.Run_workflow);
        ffiClassData.Input_Values_holder__c =  ffiClass.Input_Values_holder;
        // Add it ot the list
        ffiListParameter.add(ffiClassData);
       }//for

       if( ffiListParameter.size() >  0 )
       {
         SRM_FullfilmentInputCreation( inserted_REQ_DEF.id,ffiListParameter);
         
       }
      
     }//try
      catch(Exception e)
      {
        system.debug('[]Exception Happened : '+e.getMessage());
      }//catch

    }//

    //class for JSON parser

    public class RequestDefinitionclass
    {
        public String RequestdefinitionName;
        public String ServiceRequestTitle;
        public Id CategoryID;
        public String Description;
        public String BusinessServiceName;
        public String ServiceOfferingName;
        public String Online; 
        public String ApprovalRequired;
        public String UserInstructions;
        public List<fulfillmentInputsClass> fulfillmentInputs;


    }//

    public class fulfillmentInputsClass
    {
          public String  Order;
          public String  ResponseType;
          public String  Prompt;
          public String Required;
          public String Hidden;
          public String Run_workflow;
          public String  Input_Values_holder;
    }





}//CLASS END