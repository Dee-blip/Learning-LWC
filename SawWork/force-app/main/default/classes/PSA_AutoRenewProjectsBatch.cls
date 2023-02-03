/*
 * JIRA : FFPSA-636
 * Developer: Suhas Jain
 * Feature: Automated Renewal of Projects
 * Date: 31st Aug 2020
 *
*/ 

public with sharing class PSA_AutoRenewProjectsBatch implements Database.Batchable<sObject> {

    //Variables for PSA Autorenew Custom Metdata
    Set<String> autoRenewProducts = new Set<String>();
    Map<String, String> autogenUseCaseToClassNameMap = new Map<String, String>();
    Set<String> projectTemplateNamesSet = new Set<String>();

    //Global Variable for contract setup
    public Map<String,Map<String,Merge_Contract_Detail__c>> contractSetupMap;

    public PSA_AutoRenewProjectsBatch() 
    {

        // Query CMD to fecth values for the Renewal Class Names, Renewal Product Ids
        // To distinguish the CMD between autogen and autorenew , introduced the field Renewal Class Name . The fields is Active and Renewal class names 
        //can be used in combination for class and CMD to picked in the respective Batch class ( Autogen Batch Class and Auto Renew Batch Class )
        for(PSA_Autogen__mdt autogenDataMDT: [
            SELECT 
                id,ProjectCase_Name__c,Renewal_Class_Name__c,
                (select id, Auto_Renew_Product__c,Unit_Of_Measures__c, Name__c from PSA_ProjectTemplates__r where Auto_Renew_Product__c != null) 
            FROM PSA_Autogen__mdt 
            WHERE Renewal_Class_Name__c != null and
            ProjectCase_Name__c != null
        ]) 
        {            
            
            for(PSA_ProjectTemplates__mdt templateMDT: autogenDataMDT.PSA_ProjectTemplates__r )
            {            
                autoRenewProducts.add(templateMDT.Auto_Renew_Product__c); // emiminate the variable                 
                projectTemplateNamesSet.add(templateMDT.Name__c);                  
            }      
        }           
    }

    public Database.QueryLocator start(Database.BatchableContext batchContext) 
    {
        //Date next7Days = Date.today() + 7 ;

        System.debug('projectTemplateNamesSet: ' + projectTemplateNamesSet );
        System.debug('autoRenewProducts: ' + autoRenewProducts );


        // Query PCLI and filter on Autogen Project using the field Autogen Product on Project Object and Filter PCLI with effective end date less than 7 days and PCLI Products in AutoRenew Products
        String batchQuery = 'SELECT id, Name, lastmodifieddate, Units_Low__c, Unit_Price__c, Contract_Detail__r.Unit_of_Measure__c, Contract_Detail__r.Units_Low__c, Contract_Line_Record_Type__c, Contract_Detail__r.Effective_Start_Date__c, Contract_Detail__r.Effective_End_Date__c, Contract_Detail__r.Billing_Duration__c,Project__r.Id , Project__c, Project__r.Project_Off_Boarded__c, Project__r.Project_Template__c , Project__r.Project_Template__r.Name , Product_Id__c, Effective_Start_Date__c, Effective_End_Date__c, Original_Contract_Id__c, Original_Contract_Id__r.Account_Name__c, Contract_Detail__c, ProjectDateInSync__c from project_contract_line_item__c  where  Project__r.Project_Template__r.Name in :projectTemplateNamesSet AND Product_Id__c in :autoRenewProducts and Project__r.Project_Off_Boarded__c = false and (Effective_End_Date__c = NEXT_N_DAYS:7 OR ProjectDateInSync__c = false) and (Project__r.Autogen_Product__c != null and Project__r.Autogen_Product__c != \'\')  and Project__r.Project_Template__c != null AND Project__r.pse__Is_Active__c = True AND Project__r.pse__Stage__c != \'Closed\'';

        System.debug('Check query:'  + batchQuery );
        
        return Database.getQueryLocator(batchQuery);
    }

    public void execute(Database.BatchableContext batchContext, List<sObject> scope) 
    {

        List<Project_Contract_Line_Item__c> pclis = new List<Project_Contract_Line_Item__c>();
        
        
        PSA_AutogenObjectList recordsForUpsert;

        List<Case> casesForUpsert = new List<case>();
        List<pse__Proj__c> projectsForUpsert = new List<pse__Proj__c>();
        List<pse__Milestone__c> milestonesForUpsert = new List<pse__Milestone__c>();
        List<pse__Budget__c> budgetsForUpsert = new List<pse__Budget__c>() ;
        List<Project_Case_Association__c> pcaForUpsert = new List<Project_Case_Association__c>(); 
        List<pse__Schedule__c> schedulesForUpsert = new List<pse__Schedule__c>();
        Set<Id> renewedProjectsIds = new Set<Id>();


        System.debug('Scope size for each batch :' + scope.size());

        pclis = scope;
        
        Map<String,Map<pse__Proj__c,Project_Contract_Line_Item__c>> validRenewalClassNameToProjectPCLIMap = new Map<String,Map<pse__Proj__c,Project_Contract_Line_Item__c>>();
        // Call the method that validates the contract setup and returns the valid set of PCLIs
        contractSetupMap = new Map<String,Map<String,Merge_Contract_Detail__c>>();

        try{
            validRenewalClassNameToProjectPCLIMap = PSA_AutoRenewProjectsUtil.validateContractSetup(pclis,contractSetupMap); 
        }
        catch(Exception e){
            String error ='Exception type caught: ' + e.getTypeName() + '</br>Message: ' + e.getMessage() + '</br>Cause: ' + e.getCause() + '</br>Line number: ' + e.getLineNumber() + '</br>Stack trace: ' + e.getStackTraceString();    
            PSA_AutoCreateProjectUtil.sendErrorMails('There was as error at validRenewalClassNameToProjectPCLIMap: ',error);
        }
        

        if(validRenewalClassNameToProjectPCLIMap!= NULL && !validRenewalClassNameToProjectPCLIMap.isEmpty() && contractSetupMap != null && !contractSetupMap.isEmpty())
        {
            //Call the respective auto renew classes
            for(String eachRenewalClassName: validRenewalClassNameToProjectPCLIMap.keySet() )
            {
                System.debug('validRenewalClassNameToProjectPCLIMap.Key:'+eachRenewalClassName);
                System.debug('validRenewalClassNameToProjectPCLIMap.value:'+validRenewalClassNameToProjectPCLIMap.get(eachRenewalClassName));
                System.debug('Class Name:'+eachRenewalClassName);
                
                try{
                    PSA_AutoRenewInterface autoRenewClass = (PSA_AutoRenewInterface)Type.forName(eachRenewalClassName).newInstance();
                    recordsForUpsert = autoRenewClass.renewProjects(validRenewalClassNameToProjectPCLIMap.get(eachRenewalClassName),contractSetupMap); 
                }
                catch(Exception e){
                    String error ='Exception type caught: ' + e.getTypeName() + '</br>Message: ' + e.getMessage() + '</br>Cause: ' + e.getCause() + '</br>Line number: ' + e.getLineNumber() + '</br>Stack trace: ' + e.getStackTraceString();    
                    PSA_AutoCreateProjectUtil.sendErrorMails('There was as error at recordsForUpsert: ',error);
                }


                System.debug('recordsForUpsert values:'+recordsForUpsert);
                if(recordsForUpsert != null)
                {
                    if(recordsForUpsert.casesForUpsert != null && !recordsForUpsert.casesForUpsert.isEmpty())
                    {
                        casesForUpsert.addAll(recordsForUpsert.casesForUpsert);
                    }
                    if(recordsForUpsert.projectsForUpsert != null && !recordsForUpsert.projectsForUpsert.isEmpty())
                    {
                        projectsForUpsert.addAll(recordsForUpsert.projectsForUpsert);
                        //Projects can be updated for renewal or offboarding scenarios, whenever the project is to be updated due to renewal, it will be a part of the renewedProjectsIds List.
                        if(recordsForUpsert.renewedProjectsIds != null && !recordsForUpsert.renewedProjectsIds.isEmpty()){
                            renewedProjectsIds.addAll(recordsForUpsert.renewedProjectsIds);
                        }
                    }
                    if(recordsForUpsert.milestonesForUpsert != null && !recordsForUpsert.milestonesForUpsert.isEmpty())
                    {
                        milestonesForUpsert.addAll(recordsForUpsert.milestonesForUpsert);
                    }
                    if(recordsForUpsert.budgetsForUpsert != null && !recordsForUpsert.budgetsForUpsert.isEmpty())
                    {
                        budgetsForUpsert.addAll(recordsForUpsert.budgetsForUpsert);
                    }
                    
                    if(recordsForUpsert.pcaForUpsert != null && !recordsForUpsert.pcaForUpsert.isEmpty())
                    {
                        pcaForUpsert.addAll(recordsForUpsert.pcaForUpsert);
                    }

                    if (recordsForUpsert.schedulesForUpsert != null && !recordsForUpsert.schedulesForUpsert.isEmpty() ) 
                    {
                        schedulesForUpsert.addAll(recordsForUpsert.schedulesForUpsert);
                    }
                    
                }

            }
        
            //Collect and create/update all project related objects at once
            Map<Id,pse__Proj__c> projIdToProjectsMap = new Map<Id,pse__Proj__c>();
            Map<Id,Id> projIdToCaseIdMap = new Map<Id,Id>();
            Set<Id> projectInsertedIds = new Set<Id>();

            for(pse__Proj__c proj:projectsForUpsert){
                projIdToProjectsMap.put(proj.Id,proj);
            }

            List<Database.UpsertResult> upsertResultRecords = new List<Database.UpsertResult>();
            
            
            if(!projectsForUpsert.isEmpty())
            {                
                try{
                    //Update all the renewed and offboarded projects
                    upsertResultRecords = Database.Upsert(projectsForUpsert,false);
                }
                catch(Exception e){ 
                    String error ='Exception type caught: ' + e.getTypeName() + '</br>Message: ' + e.getMessage() + '</br>Cause: ' + e.getCause() + '</br>Line number: ' + e.getLineNumber() + '</br>Stack trace: ' + e.getStackTraceString();    
                    PSA_AutoCreateProjectUtil.sendErrorMails('There was as error at projectsForUpsert: ',error);
                }

                List<pse__Proj__c> renewedProjectsList = new List<pse__Proj__c>();
                for(Database.UpsertResult project: upsertResultRecords)
                {
                    System.debug('Projects after query: '+project.id+ ' '+project.isSuccess());
                    System.debug('Projects after query Errors: '+project.getErrors());
                    if (project.isSuccess()) 
                    {
                        projectInsertedIds.add(project.getId());
                        //Check if there are any projects which have been renewed, They should be present in the renewedProjectsIds List.
                        if(renewedProjectsIds.contains(project.getId())){
                            renewedProjectsList.add(projIdToProjectsMap.get(project.getId()));                    	
                        }
                    }
                }

                //Create renew emails
                PSA_AutoRenewProjectsUtil.addRenewalEmail(renewedProjectsList);
            }

            if( !schedulesForUpsert.isEmpty() )
            {
                List<pse__Schedule__c> schedulesUpsertList = new List<pse__Schedule__c>();
                for (pse__Schedule__c schedule : schedulesForUpsert) {

                    schedulesUpsertList.add(schedule);
                }

                try{
                    upsertResultRecords = Database.Upsert(schedulesUpsertList,false);
                }
                catch(Exception e){
                    String error ='Exception type caught: ' + e.getTypeName() + '</br>Message: ' + e.getMessage() + '</br>Cause: ' + e.getCause() + '</br>Line number: ' + e.getLineNumber() + '</br>Stack trace: ' + e.getStackTraceString();    
                    PSA_AutoCreateProjectUtil.sendErrorMails('There was as error at schedulesUpsertList: ',error);
                }                
                for(Database.UpsertResult schedule: upsertResultRecords){
                    System.debug('Schedule after query :'+schedule.id+' '+schedule.isSuccess());
                    System.debug('Schedule after query Errors:'+schedule.getErrors());
                
                }

            }
            

            if(!casesForUpsert.isEmpty())
            {
                List<Case> updatedCasesForUpsert = new List<Case>();
                for(Case offBoardingCase :casesForUpsert)
                {
                    //Insert an offboarding case only if the project update was successfull
                    if(projectInsertedIds.contains(offBoardingCase.pse_Project__c))
                    {
                        updatedCasesForUpsert.add(offBoardingCase);
                    }
                }
                if(!updatedCasesForUpsert.isEmpty())
                {
                    try{
                        //Insert all the new offboarding cases
                        upsertResultRecords = Database.Upsert(updatedCasesForUpsert,false);
                    }
                    catch(Exception e){
                        String error ='Exception type caught: ' + e.getTypeName() + '</br>Message: ' + e.getMessage() + '</br>Cause: ' + e.getCause() + '</br>Line number: ' + e.getLineNumber() + '</br>Stack trace: ' + e.getStackTraceString();    
                        PSA_AutoCreateProjectUtil.sendErrorMails('There was as error at updatedCasesForUpsert: ',error);
                    }
                    
        
                    Database.UpsertResult offBoardingCase;
                    for(Integer index=0; index<upsertResultRecords.size(); index++)
                    {
                        System.debug('index:'+index);
                        
                        offBoardingCase = upsertResultRecords[index];
                        System.debug('offBoardingCase: '+offBoardingCase);
                        System.debug('Case after query :'+offBoardingCase.id+ ' '+offBoardingCase.isSuccess());
                        System.debug('Case after query Errors:'+offBoardingCase.getErrors());
        
                        if (offBoardingCase.isSuccess()) 
                        {
                            System.debug('offBoardingCase.getId(): '+offBoardingCase.getId());
                            System.debug('updatedCasesForUpsert[index]: '+updatedCasesForUpsert[index]);     

                            //Create a map of project Ids to CaseIds to be used for project case association creation                    
                            projIdToCaseIdMap.put(updatedCasesForUpsert[index].pse_Project__c, offBoardingCase.getId());

                        }                    
                    }
                }
                
                if(pcaForUpsert!=null && !pcaForUpsert.isEmpty())
                {
                    List<Project_Case_Association__c> updatedPcaForUpsert = new List<Project_Case_Association__c>();
                    for(Project_Case_Association__c pca :pcaForUpsert)
                    {
                        //Create Project case association only if the associated projects and cases have been upserted succesfully.
                        if(projectInsertedIds.contains(pca.Project__c) && projIdToCaseIdMap.containsKey(pca.Project__c))
                        {
                            //The project lookup is already present on the pca record, use the project Id to fetch case Id and create the case lookup on the pca record
                            pca.Case__c = projIdToCaseIdMap.get(pca.Project__c);
                            updatedpcaForUpsert.add(pca);
                        }
                    }
                    if(!updatedPcaForUpsert.isEmpty())
                    {
                        try{
                            upsertResultRecords = Database.Upsert(updatedPcaForUpsert,false);
                        }
                        catch(Exception e){
                            String error ='Exception type caught: ' + e.getTypeName() + '</br>Message: ' + e.getMessage() + '</br>Cause: ' + e.getCause() + '</br>Line number: ' + e.getLineNumber() + '</br>Stack trace: ' + e.getStackTraceString();    
                            PSA_AutoCreateProjectUtil.sendErrorMails('There was as error at updatedPcaForUpsert: ',error);
                        }
                        
                    
                        for(Database.UpsertResult pca: upsertResultRecords){
                            System.debug('PCA after query :'+pca.id+' '+pca.isSuccess());
                            System.debug('PCA after query Errors:'+pca.getErrors());
                            
                        }                
                    }            
                }  
            }
                

            if(!milestonesForUpsert.isEmpty())
            {
                List<pse__Milestone__c> milestoneRecords = new List<pse__Milestone__c>();
                for(pse__Milestone__c milestoneRecord : milestonesForUpsert)
                {
                        milestoneRecords.add(milestoneRecord);
                }
                try{
                    upsertResultRecords = Database.Upsert(milestoneRecords,false);
                }
                catch(Exception e){
                    String error ='Exception type caught: ' + e.getTypeName() + '</br>Message: ' + e.getMessage() + '</br>Cause: ' + e.getCause() + '</br>Line number: ' + e.getLineNumber() + '</br>Stack trace: ' + e.getStackTraceString();    
                    PSA_AutoCreateProjectUtil.sendErrorMails('There was as error at milestoneRecords: ',error);
                }
                
                for(Database.UpsertResult milestone: upsertResultRecords){
                    System.debug('Milestone after query :'+milestone.id+ ' '+milestone.isSuccess());
                    System.debug('Milestone after query Errors:'+milestone.getErrors());
                }
            }

            if(!budgetsForUpsert.isEmpty())
            {
                List<pse__Budget__c> budgetRecords = new List<pse__Budget__c>();
                for(pse__Budget__c budgetRecord : budgetsForUpsert)
                {
                        budgetRecords.add(budgetRecord);
                }
                try{
                    upsertResultRecords = Database.Upsert(budgetRecords,false);
                }
                catch(Exception e){
                    String error ='Exception type caught: ' + e.getTypeName() + '</br>Message: ' + e.getMessage() + '</br>Cause: ' + e.getCause() + '</br>Line number: ' + e.getLineNumber() + '</br>Stack trace: ' + e.getStackTraceString();    
                    PSA_AutoCreateProjectUtil.sendErrorMails('There was as error at budgetRecords: ',error);
                }
                
                for(Database.UpsertResult budget: upsertResultRecords){
                    System.debug('Budget after query :'+budget.id+ ' '+budget.isSuccess());
                    System.debug('Budget after query Errors:'+budget.getErrors());
                }
            }

        }
        
    }

    public void finish(Database.BatchableContext batchContext) {
        System.debug('Finish block');
    }

}