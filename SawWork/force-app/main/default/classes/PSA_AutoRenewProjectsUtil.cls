/***
 * Description: This class provides all the util methods for Autorenewal of projects.
 * Developer: Sandeep Naga
 * Date: 3rd August 2020
 * 
 * Date                     Developer               JIRA            Subject
 * 
 * 17th Nov 2020            Sandeep Naga            FFPSA-1771      Adding CLI Record Type = "Committed" check
***/
public with sharing class PSA_AutoRenewProjectsUtil {

    //Map of project temaplate Name to  <Product Id:Unit of Measure of CLI>  E.g:  M-LC-1234:Hour,M-LC-1234:Reviews,M-LC-9999:Per Month
    public static Map<String,String> projectTemplateToUnitOfMeasureMap = new Map<String,String>();

    //Set of all the Unit of measures to be used in the filter of CLI SOQL
    public static Set<String> allUnitOfMeasuresSet = new Set<String> ();

    //Map of project temaplate Name to Autogen Product / Use case name. This value is used to be set as product name on Project case association.
    public static Map<String,String> projectTemplateToAutogenUseCaseName = new Map<String,String>();

    //Map of project template Name to Renewal Class Name
    public static Map<String,String> projectTemplateToRenewalClassNameMap = new Map<String,String>();

    
    static{
        //Fetch all the PSA Project Template custom metadata and create name to UnitOfMeasures Map
        for(PSA_ProjectTemplates__mdt templatesMdt:[
                SELECT Name__c,Parent_Autogen__c, Sub_Type__c, Type__c , Unit_Of_Measures__c, Parent_Autogen__r.Autogen_Usecase__c, Parent_Autogen__r.Renewal_Class_Name__c
            	FROM PSA_ProjectTemplates__mdt
                WHERE Unit_Of_Measures__c != NULL
                    AND Auto_Renew_Product__c!= null
                    AND Parent_Autogen__r.ProjectCase_Name__c != null
                    AND Parent_Autogen__r.Product_Name__c != null
        ]){
            projectTemplateToUnitOfMeasureMap.put(templatesMdt.Name__c, templatesMdt.Unit_Of_Measures__c);
            for(String uom : templatesMdt.Unit_Of_Measures__c.split(',')){
                allUnitOfMeasuresSet.add(uom.split(':')[1]);
            }
            projectTemplateToAutogenUseCaseName.put(templatesMdt.Name__c,templatesMdt.Parent_Autogen__r.Autogen_Usecase__c);
            projectTemplateToRenewalClassNameMap.put(templatesMdt.Name__c,templatesMdt.Parent_Autogen__r.Renewal_Class_Name__c);
        }
    }
    
    
    /*
        Input: List of PCLIs to be validated for contract setup
        Output: Map of Product Id (E.g: M-LC-1234) to the list of validated PCLIs
        Description: This method takes in the PCLIs to be validated, Fetches all the CLI relevant to the PCLI with the help of the Unit_Of_Measures__c field on custom metadata, Product Ids and Contract Ids fetched from the PCLI and project linked.SELECT  FROM ${1||}
            We ensure that in the current setup, the all the CLIs with necessary product Id and Unit of Measure are present and also verify that the bunch of CLIs are in sync by having same start date and end date. 
            Only if All the necessary CLI are present, we add it our output map
    */
    public static Map<String,Map<pse__Proj__c,Project_Contract_Line_Item__c>> validateContractSetup(List<Project_Contract_Line_Item__c> pclis,Map<String,Map<String,Merge_Contract_Detail__c>> contractSetupMap){
        
        String key;
        Boolean flag; 
        Set<String> allProductIdsSet = new Set<String>();
        Set<Id> allContractHeadersSet = new Set<Id>();

        //A Set of CLI product Id + Unit of Measure+ Contract Id + End Date + Start Date
        Set<String> valueToCliKeySet = new Set<String>();

        //Temporary map for contractSetup
        Map<String,Merge_Contract_Detail__c> unitOfMeasureToCLIMap;
    
        for(Project_Contract_Line_Item__c pcli : pclis){
            allContractHeadersSet.add(pcli.Original_Contract_Id__c);
            allProductIdsSet.add(pcli.Product_Id__c);
            System.debug('pcli.Id:'+pcli.Id);
        }
        
        System.debug('allContractHeadersSet:' + allContractHeadersSet );
        System.debug('allProductIdsSet:' + allProductIdsSet );
        System.debug('allUnitOfMeasuresSet:' + allUnitOfMeasuresSet );

        try{
            for(Merge_Contract_Detail__c cli : [
                SELECT Product_Id__c, Unit_of_Measure__c, Original_Contract_Id__c, Effective_Start_Date__c, Effective_End_Date__c, Record_Type__c, Unit_Price__c, Units_Low__c, Billing_Duration__c
                FROM Merge_Contract_Detail__c
                WHERE 
                    Original_Contract_Id__c IN :allContractHeadersSet AND
                    Product_Id__c IN :allProductIdsSet AND
                    Unit_of_Measure__c IN :allUnitOfMeasuresSet AND
                    //FFPSA-1771 : Adding CLI Record Type = "Committed" check
                    Record_Type__c = 'Committed'
                ]){
                key = String.valueOf(cli.Original_Contract_Id__c) + String.valueOf(cli.Effective_Start_Date__c) + String.valueOf(cli.Effective_End_Date__c);            
                
                unitOfMeasureToCLIMap = new Map<String,Merge_Contract_Detail__c>();
                if(contractSetupMap != null && contractSetupMap.containsKey(key))
                {                    
                    unitOfMeasureToCLIMap.putAll(contractSetupMap.get(key));
                }
                unitOfMeasureToCLIMap.put(cli.Unit_of_Measure__c,cli);

                contractSetupMap.put(key,unitOfMeasureToCLIMap);

                key = cli.Product_Id__c + ':' + cli.Unit_of_Measure__c + key;
                valueToCliKeySet.add(key);     
                System.debug('cli key:'+key);    
                System.debug('cli.Id: '+cli.Id);  
            }

            
        }
        catch(Exception e){
            String error ='Exception type caught: ' + e.getTypeName() + '</br>Message: ' + e.getMessage() + '</br>Cause: ' + e.getCause() + '</br>Line number: ' + e.getLineNumber() + '</br>Stack trace: ' + e.getStackTraceString();    
            PSA_AutoCreateProjectUtil.sendErrorMails('There was as error at CLI Query: ',error);
        }
        
        
        Map<Id,Project_Contract_Line_Item__c> validProjectIdsToPCLIMap = new Map<Id,Project_Contract_Line_Item__c>();
        //Run through all the pclis, 
        for(Project_Contract_Line_Item__c pcli : pclis){            
            flag = True;             
            key = String.valueOf(pcli.Original_Contract_Id__c) + String.valueOf(pcli.Effective_Start_Date__c) + String.valueOf(pcli.Effective_End_Date__c);
            System.debug('pcli key:'+key);
            System.debug('Project__r.Project_Template__r.Name:'+pcli.Project__r.Project_Template__r.Name);
            System.debug('projectTemplateToUnitOfMeasureMap:'+projectTemplateToUnitOfMeasureMap.containsKey(pcli.Project__r.Project_Template__r.Name));
            if(projectTemplateToUnitOfMeasureMap.containsKey(pcli.Project__r.Project_Template__r.Name))
            {
                for(String value : projectTemplateToUnitOfMeasureMap.get(pcli.Project__r.Project_Template__r.Name).split(',')){
                    System.debug('pcli value: '+value);
                    System.debug('pcli value+key: '+value+''+key);

                    if(!valueToCliKeySet.contains(value + key)){
                        System.debug('Incorrect Setup : CLI');
                        flag = False;
                        break;
                    }                
                }
            }
            else{
                flag = false;
                System.debug('Incorrect Setup : Map');
            }

            if(flag){
                validProjectIdsToPCLIMap.put(pcli.Project__c,pcli);      
                System.debug('validProjectIdsToPCLIMap :'+pcli.Project__c+' : '+validProjectIdsToPCLIMap.get(pcli.Project__c));            
            } 
            else if(!flag && contractSetupMap.containsKey(key)){
                contractSetupMap.remove(key);
            }                       
        } 

        System.debug('validProjectIdsToPCLIMap.keySet():'+validProjectIdsToPCLIMap.keySet());
        String renewalClassName;  
        Map<pse__Proj__c,Project_Contract_Line_Item__c> projectToPCLIMap;
        Map<String,Map<pse__Proj__c,Project_Contract_Line_Item__c>> validRenewalClassNameToProjectPCLIMap = new Map<String,Map<pse__Proj__c,Project_Contract_Line_Item__c>>();
        try{
            //Query all the project records
            List<pse__Proj__c> projects = [
                SELECT id, name, pse__End_Date__c, Current_Contract_Term_Planned_Hours_Num__c ,pse__Planned_Hours__c,Project_Template__r.name ,Ongoing_Project_Recurring_Planned_Hour__c, Ongoing_Project_Recurring_Budget_Amt__c , pse__Account__c, pse__Project_Manager__c, pse__Project_Manager__r.pse__Salesforce_User__c,Project_Off_Boarded__c , Owner_Email_address__c, Owner_Manager_Email_address__c,pse__Account__r.Name,RecordTypeId,External_Id__c, 
                    (select id, pse__Amount__c from pse__Budgets__r ) , 
                    (select id,pse__Target_Date__c from pse__milestones__r ) , 
                    (select id,pse__End_Date__c,pse__Schedule__c  from pse__Assignments__r )   
                FROM pse__Proj__c 
                WHERE id in :validProjectIdsToPCLIMap.keySet()
                WITH SECURITY_ENFORCED 
            ];

            System.debug('projects:'+projects);
            for(pse__Proj__c proj : projects){   
                System.debug('Project query: proj.Id:'+proj.Id);
                System.debug('validProjectIdsToPCLIMap.containsKey(proj.Id):'+validProjectIdsToPCLIMap.containsKey(proj.Id));
                System.debug('projectTemplateToRenewalClassNameMap.containsKey(proj.Project_Template__r.Name):'+projectTemplateToRenewalClassNameMap.containsKey(proj.Project_Template__r.Name));
                if(validProjectIdsToPCLIMap != null && validProjectIdsToPCLIMap.containsKey(proj.Id) && projectTemplateToRenewalClassNameMap != null && projectTemplateToRenewalClassNameMap.containsKey(proj.Project_Template__r.Name))
                {
                    projectToPCLIMap = new Map<pse__Proj__c,Project_Contract_Line_Item__c>();

                    renewalClassName = projectTemplateToRenewalClassNameMap.get(proj.Project_Template__r.Name);
                    if(validRenewalClassNameToProjectPCLIMap.containsKey(renewalClassName))
                    {
                        projectToPCLIMap.putAll(validRenewalClassNameToProjectPCLIMap.get(renewalClassName));
                    }
                    projectToPCLIMap.put(proj,validProjectIdsToPCLIMap.get(proj.Id));
                    System.debug('projectToPCLIMap : '+proj+' : '+projectToPCLIMap.get(proj));
                    System.debug('renewalClassName :'+renewalClassName);
                    validRenewalClassNameToProjectPCLIMap.put(renewalClassName,projectToPCLIMap);                    
                }     
            }
        }
        catch(Exception e){
            String error ='Exception type caught: ' + e.getTypeName() + '</br>Message: ' + e.getMessage() + '</br>Cause: ' + e.getCause() + '</br>Line number: ' + e.getLineNumber() + '</br>Stack trace: ' + e.getStackTraceString();    
            PSA_AutoCreateProjectUtil.sendErrorMails('There was as error at Project looping: ',error);
        }
        
        
        return validRenewalClassNameToProjectPCLIMap;
    }


    
    /*
        Input: List of projects to be offboarded and need a project case association
        Description: For all the valid offboarded projects, create a project case association.
    */
    public static Project_Case_Association__c createOffboardingProjectCaseAssociation(pse__Proj__c proj, Project_Contract_Line_Item__c pcli)
    {
        System.debug('PCLI proj.Id:'+proj.Id);
        
        Project_Case_Association__c pca = new Project_Case_Association__c();  
        pca.Project__c = proj.Id;
        pca.Contract__c = pcli.Original_Contract_Id__c;

        //The product name of the PCA can be set using the calue from the custom metadata
        if(projectTemplateToAutogenUseCaseName.containsKey(proj.Project_Template__r.Name)){
            pca.Name = projectTemplateToAutogenUseCaseName.get(proj.Project_Template__r.Name);
        }
        else{
            pca.Name = 'Offboarding PCA';
        }
            
        pca.Autogen_Project__c = True;
        pca.Automated_Project_Type__c = 'Offboarding PCA';
        pca.Contract_Detail__c = pcli.Contract_Detail__c;
        
        return pca;
    }
    
    /*
        Input: List of email object which is passed by reference, Projects for which renew emails have to be sent
        Description: For all the succesfully renewed projects, send an email to the Project Manager and Project Manager's Manager. Make use of the Email Template PSA_Renew_Email_Template

    */
    public static void addRenewalEmail(List<pse__Proj__c> projList)
    {

        //Fetch the email template ID used for send auto renew email
        Id emailTemplateId;
        try {
            emailTemplateId = [select id, name from EmailTemplate where developername = 'PSA_Renew_Email_Template'].id;
        }
        catch (Exception e) {
            System.debug('Exception: Email template issue: '+e);
        }

        Messaging.SingleEmailMessage[] emailsToBeSent = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage email;

        if(projList!=null){
            for(pse__Proj__c proj : projList){
                email = new Messaging.Singleemailmessage();
                email.saveAsActivity = false;
                email.setWhatId(proj.Id);
                email.setTargetObjectId(proj.pse__Project_Manager__c);
                email.setToAddresses(new List<String>{proj.Owner_Email_address__c,proj.Owner_Manager_Email_address__c});
                email.setTemplateId(emailTemplateId);

                emailsToBeSent.add(email);
            }

            try{
                //Send out emails if project renewal is succesfull
                if(emailsToBeSent!=null && !emailsToBeSent.isEmpty()){
                    Messaging.SendEmailResult [] mailSendResult = Messaging.sendEmail(emailsToBeSent,false);
                    for(Messaging.SendEmailResult result : mailSendResult)
                    {
                        System.debug('Email result ' + result.IsSuccess());
                        System.debug('Result :' + result);
                    }
                }
            }
            catch(Exception e){
                String error ='Exception type caught: ' + e.getTypeName() + '</br>Message: ' + e.getMessage() + '</br>Cause: ' + e.getCause() + '</br>Line number: ' + e.getLineNumber() + '</br>Stack trace: ' + e.getStackTraceString();    
                PSA_AutoCreateProjectUtil.sendErrorMails('There was as error at sendRenewEmail: ',error);
            }

            
        }        
    }
}