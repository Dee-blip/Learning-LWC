/*
 Developer                        Date                        JIRA                            Changes
 Sandeep Naga               17th May 2019                   FFPSA-973            Created class for Plus Project Autogens  

*/
public class PSA_AutoCreatePlus_PSHours implements PSA_AutogenInterface 
{
    //Instantiate the interface instance to send to batch class
    public PSA_AutogenObjectList autogenInstanceList;

    //For each project to be created add the following to the autogenInstanceList:
    // 1. Projects: autogenInstanceList.projectsForUpsert : use PSA_AutoCreateProjectUtil.createProjectCaseAssociationRecord();
    // 2. Cases: autogenInstanceList.casesForUpsert : Update Case.Description value accordingly
    // 3. Milestones: autogenInstanceList.milestonesForUpsert
    // 4. Products: autogenInstanceList.productsForUpsert
    // 5. Budgets: autogenInstanceList.budgetsForUpsert
    // 6. Project Case Asscoiation: autogenInstanceList.pcaForUpsert
   

    //Variable to store the required project templates
    public Map<String,pse__Proj__c> projTemplates;

    //Variable to get the custom metada data from PSA Autogen
    public PSA_Autogen__mdt autogenPlus_mdt;

    //Variable that contains all product Ids obtained from the custom metadata
    Set<String> productIdsSet = new Set<String>();

    //Variable for haveing a map of ("Per month") CLI id : Map of ("Per month"),("Configurations") and ("Hours") CLIs
    Map<Id,Map<String,Merge_Contract_Detail__c>> clisForProjectMap = new Map<Id,Map<String,Merge_Contract_Detail__c>>();


    public PSA_AutoCreatePlus_PSHours()
    {
        //System.debug('@@@Class Contructor');
      //Intantiate the interface object and project templates Map
      autogenInstanceList = new PSA_AutogenObjectList();
        projTemplates = new Map<String,pse__Proj__c>();
        autogenPlus_mdt = [SELECT Id,Autogen_Usecase__c,Product_Id__c,ProjectCase_Name__c FROM PSA_Autogen__mdt WHERE Product_Name__c = 'PLUS_PSHOURS' limit 1];
        if(autogenPlus_mdt.Product_Id__c != NULL)
        {
            productIdsSet.addAll(autogenPlus_mdt.Product_Id__c.split(','));
           
        }
        
        
        //System.debug('@@@productIdsSet: '+productIdsSet);

    }


    //Validate all the data : Contracts, CLIs, Cases etc
    public PSA_AutogenObjectList getContractDetailsForUpsert(List<Merge_Contract_Header__c> contractsList,List<Merge_Contract_Detail__c> contractDetailsList,List<Case> casesList,List<Project_Case_Association__c> pcaList, Map<String,pse__Proj__c> projTemplatesMap)
    {

        //Fetch all the project template names required from the custom meta data and use the projTemplatesMap to fetch the actual templates
        for (PSA_ProjectTemplates__mdt templates_mdt :[select Name__c,Parent_Autogen__c, Sub_Type__c, Type__c from PSA_ProjectTemplates__mdt where Parent_Autogen__c = :autogenPlus_mdt.id order by DeveloperName]) //and is in progres???
        {
            if(projTemplatesMap.containsKey(templates_mdt.Name__c) && projTemplatesMap.get(templates_mdt.Name__c).pse__Project_Type__c == templates_mdt.Type__c && projTemplatesMap.get(templates_mdt.Name__c).Project_Sub_Type__c == templates_mdt.Sub_Type__c)
            {
                projTemplates.put(templates_mdt.Name__c,projTemplatesMap.get(templates_mdt.Name__c));
                //System.debug('@@@Templates: '+templates_mdt.Name__c);
            }
        }




        if(projTemplates.size() != 2)
        {
            PSA_AutoCreateProjectUtil.sendErrorMails('PS Hours and Monthly Service report project templates have not been found','');   //???
            return autogenInstanceList;
        }

        // ??? To remove pca check
        //Create a set of per Month CLI ids from project case association list indicating projects have already been created
        //Set<Id> projectCaseAssociationClisIdSet = new Set<Id>();
        //for(Project_Case_Association__c eachProjectCaseAssociation : pcaList)
        //{
        //    if(eachProjectCaseAssociation.Automated_Project_Type__c == autogenPlus_mdt.ProjectCase_Name__c)
        //    {
        //        projectCaseAssociationClisIdSet.add(eachProjectCaseAssociation.Contract_Detail__c);
        //    }
        //}

       ////System.debug('@@@projectCaseAssociationClisIdSet: '+projectCaseAssociationClisIdSet);
       //System.debug('@@@contractDetailsList: '+contractDetailsList);

        //Flitered List to use later
        List<Merge_Contract_Detail__c> perMonthAutogenClisList = new List<Merge_Contract_Detail__c>();
        List<Merge_Contract_Detail__c> othersAutogenClisList = new List<Merge_Contract_Detail__c>();

        Map<String,Id> cliNameToIdMap = new Map<String,Id>();
        
       


        //Filter out all the CLIs which are not satisfying the specific functions of the class
        for(Merge_Contract_Detail__c eachCLI : contractDetailsList)
        {
            cliNameToIdMap.put(eachCLI.Name, eachCLI.Id);
            //System.debug('@@@cliNameToIdMap: '+eachCLI.Name+ ' : '+eachCLI.Id);
          //Specific Checks to be done
          //1. If created date or Effective_Start_Date__c is less than last 2 days
          Date thirtyThreeDays = Date.today()+33; //.addDays(33)
            Date lastTwoDays = Date.today()-2;

            //System.debug('@@@CLI:');
            //System.debug('@@@eachCLI.Product_Id__c: '+eachCLI.Product_Id__c);
            //System.debug('@@@lastTwoDays: '+lastTwoDays);
            //System.debug('@@@createddate: '+ eachCLI.createddate);
            //System.debug('@@@Effective_Start_Date__c: '+eachCLI.Effective_Start_Date__c);
            //System.debug('@@@thirtyThreeDays: '+thirtyThreeDays);

          if( eachCLI.Effective_Start_Date__c < thirtyThreeDays || eachCLI.createddate > lastTwoDays) 
          {
            //2. If record type is "Committed"
            //3. If Unit of Measure is "Per Month", "Configurations" or "Hours"
            //4. If any of the PSA Autogen Records contain the product ID associated to Plus
            //5. Check if cli Id not present in records of project case association so as to not create duplicate projects
                //System.debug('@@@Record_Type__c: '+ eachCLI.Record_Type__c);
                //System.debug('@@@Unit_of_Measure__c: '+ eachCLI.Unit_of_Measure__c);
                //System.debug('@@@productIdsSet: '+ productIdsSet);
                //System.debug('@@@Product_Id__c: '+ eachCLI.Product_Id__c);
                ////System.debug('@@@projectCaseAssociationClisIdSet: '+ projectCaseAssociationClisIdSet);
                //System.debug('@@@Check: '+productIdsSet.contains(eachCLI.Product_Id__c));
                

                //if( !projectCaseAssociationClisIdSet.contains(eachCLI.Id) && eachCLI.Record_Type__c == 'Committed' && productIdsSet.contains(eachCLI.Product_Id__c) )
                if(eachCLI.Record_Type__c == 'Committed' && productIdsSet.contains(eachCLI.Product_Id__c))
                {
                    if(eachCLI.Unit_of_Measure__c == 'Per Month')
                    {
                        perMonthAutogenClisList.add(eachCLI);
                    }
                    else if(eachCLI.Unit_of_Measure__c == 'Configurations'|| eachCLI.Unit_of_Measure__c == 'Hour')
                    {                        
                        othersAutogenClisList.add(eachCLI);
                    }

                }
            }

        }
        //System.debug('@@@perMonthAutogenClisList: '+perMonthAutogenClisList);
        //System.debug('@@@perMonthAutogenClisList.size(): '+perMonthAutogenClisList.size());

        //System.debug('@@@othersAutogenClisList: '+othersAutogenClisList);
        //System.debug('@@@othersAutogenClisList.size(): '+othersAutogenClisList.size());

        
        //Map<String,Merge_Contract_Detail__c> temporaryMap = new Map<String,Merge_Contract_Detail__c>();
        
        Map<String,Id> cliMap = new Map<String,Id>();

        //Run through all the CLIs and MAP all the CLIs required for a project set
        for(Merge_Contract_Detail__c eachPerMonthCLI : perMonthAutogenClisList)
        {            

            //temporaryMap.put(eachPerMonthCLI.Unit_of_Measure__c,eachPerMonthCLI);
            //clisForProjectMap.put(eachPerMonthCLI.id,temporaryMap);
            
            clisForProjectMap.put(eachPerMonthCLI.id,new Map<String,Merge_Contract_Detail__c>());
            clisForProjectMap.get(eachPerMonthCLI.id).put(eachPerMonthCLI.Unit_of_Measure__c,eachPerMonthCLI);

            //System.debug('@@@clisForProjectMap: '+clisForProjectMap);
            String temp = ''+eachPerMonthCLI.Original_Contract_Id__c + String.valueOf(eachPerMonthCLI.Effective_Start_Date__c) + String.valueOf(eachPerMonthCLI.Effective_End_Date__c);
            //System.debug('@@@tempUp: '+temp);
            //System.debug('@@@KeyUP: '+eachPerMonthCLI.id);
            cliMap.put(temp,eachPerMonthCLI.id);
            //System.debug('@@@cliMap: '+cliMap);


        }

        //System.debug('@@@cliMap: '+cliMap);

        for(Merge_Contract_Detail__c eachOthersCLI : othersAutogenClisList)
        {            
            String temp = '' + eachOthersCLI.Original_Contract_Id__c + String.valueOf(eachOthersCLI.Effective_Start_Date__c) + String.valueOf(eachOthersCLI.Effective_End_Date__c);
            Id key = cliMap.get(temp);
           
            //temporaryMap = clisForProjectMap.get(key);
            //temporaryMap.put(eachOthersCLI.Unit_of_Measure__c,eachOthersCLI);
            //check for latest last modified date on Hours and Configurations CLI if nothing is present
            //System.debug('@@@temp: '+temp);
            //System.debug('@@@Key: '+key);
            //System.debug('@@@clisForProjectMap.containsKey(key): '+clisForProjectMap.containsKey(key));

            if(clisForProjectMap.containsKey(key))
            {
                //System.debug('@@@clisForProjectMap.get(key): '+clisForProjectMap.get(key));
                
                if(!clisForProjectMap.get(key).containsKey(eachOthersCLI.Unit_of_Measure__c) || clisForProjectMap.get(key).get(eachOthersCLI.Unit_of_Measure__c).lastmodifieddate < eachOthersCLI.lastmodifieddate) 
                {
                    //System.debug('@@@!clisForProjectMap.get(key).containsKey(eachOthersCLI.Unit_of_Measure__c): '+!clisForProjectMap.get(key).containsKey(eachOthersCLI.Unit_of_Measure__c));
                    clisForProjectMap.get(key).put(eachOthersCLI.Unit_of_Measure__c,eachOthersCLI);                        
                }
                //else
                //{
                //    //No per month CLI
                //}
                
                //clisForProjectMap.put(key,temporaryMap);
            }

            
        }

        //System.debug('@@@clisForProjectMap: '+clisForProjectMap);
        //System.debug('@@@clisForProjectMap.size(): '+clisForProjectMap.size());

        Map<Id,List<Merge_Contract_Detail__c>> caseClisList = new Map<Id,List<Merge_Contract_Detail__c>>();
    List<Merge_Contract_Detail__c> tempCliList = new List<Merge_Contract_Detail__c>();


        

        
        //if there are valid CLIs and cases, call the funtion to create projects
        if(!clisForProjectMap.isEmpty() && !cliNameToIdMap.isEmpty())
        {

          //Run through all the cases and create project sets for each record in the clisForProjectMap and make an entry with the case id and project ids in ???
          for(Case eachCase : casesList)
          {
                //System.debug('@@@eachCase.Contract_Detail__c: '+eachCase.Contract_Detail__c);
                //System.debug('@@@cliNameToIdMap.get(eachCase.Contract_Detail__c): '+cliNameToIdMap.get(eachCase.Contract_Detail__c));
                //System.debug('@@@clisForProjectMap.get(cliNameToIdMap.get(eachCase.Contract_Detail__c)): '+clisForProjectMap.get(cliNameToIdMap.get(eachCase.Contract_Detail__c)));
                if(cliNameToIdMap.containsKey(eachCase.Contract_Detail__c) && clisForProjectMap.containsKey(cliNameToIdMap.get(eachCase.Contract_Detail__c)))
                {

                    caseClisList.put(eachCase.Id , clisForProjectMap.get(cliNameToIdMap.get(eachCase.Contract_Detail__c)).values());


                }
              
          }
            
        }

        
        //System.debug('@@@caseClisList: '+caseClisList);
        //for(Id caseId : caseClisList.keySet())
        //{
        //    for(Merge_Contract_Detail__c cli : caseClisList.get(caseId))
        //    {
        //        //System.debug('Id: '+cli.id+'    Unit_of_Measure__c: '+cli.Unit_of_Measure__c);
        //    }
        //}

        CreateProjects(caseClisList,casesList);

        return autogenInstanceList;
    }

    


    //Three Methods of the implemented interface PSA_AutogenInterface : getContractDetails, getContractDetailsForUpsert, CreateProjects

    //Ignore this method
    public void getContractDetails(List<Merge_Contract_Header__c> ListContractScope,List<Merge_Contract_Detail__c> ListContractDetailstoCheck,List<Case> CasesCreated,List<Project_Case_Association__c> projectCases)
    {}

    //Ignore this method
    public void CreateProjects(Map<Id,List<Merge_Contract_Detail__c>> caseClisList,List<Case> autogenCasesList)
    {
        
        Merge_Contract_Detail__c perMonthCli;
        Merge_Contract_Detail__c configurationCli;
        Merge_Contract_Detail__c hoursCli;

        Project_Case_Association__c pca;

        Integer noOfActiveMonths;
        Integer noOfMonthlyReports;
        Integer noOfMonthlsPerBillingPeriod;
        Double monthlyRecurringHours;
        
        Double budget;
        Double plannedHours;

        String feeSchedule;
        String projectName;

        String successProjects;
        String failureProjects;       

        


        for(Case eachCase : autogenCasesList)
        {
            successProjects = '';
            failureProjects = '';   
            

            perMonthCli = NULL;
            configurationCli = NULL;
            hoursCli = NULL;

            if(caseClisList.containsKey(eachCase.Id))
            {
                for(Merge_Contract_Detail__c cli : caseClisList.get(eachCase.Id))
                {
                    if(cli.Unit_of_Measure__c == 'Per Month')
                    {
                        perMonthCli = cli;
                    }
                    if(cli.Unit_of_Measure__c == 'Configurations')
                    {
                        configurationCli = cli;
                    }
                    if(cli.Unit_of_Measure__c == 'Hour')
                    {
                        hoursCli = cli;
                    }
                }

                
                //if(perMonthCli == NULL || (configurationCli == NULL && hoursCli == NULL))
                if(configurationCli == NULL && hoursCli == NULL)
                {
                    //all projects failed
                    failureProjects += '\nPlus Monthly Service Report\nPlus-Hours';
                }
                else
                {                    
                    if(configurationCli != NULL)
                    {
                        //Create Monthly Service report project
                        //System.debug('@@@Monthly Service Report Project');
                        //No of Active Months/Monthly reports and Planned Hours
                        noOfActiveMonths = PSA_AutoCreateProjectUtil.numberOfActiveMonths(configurationCli.Effective_Start_Date__c,configurationCli.Effective_End_Date__c);      
                        noOfMonthlyReports = noOfActiveMonths;
                        plannedHours = noOfMonthlyReports * 2;
                        budget = 0;
                        feeSchedule = 'Monthly Commit (MRR)';
                        pse__proj__c projectTemplate = projTemplates.get('GSS Products/Plus - Monthly Service Report – Project Template');
                        //Number of configurations is Units_Low__c
                        projectName = 'Plus Monthly Service Report-' + configurationCli.Units_Low__c +' configurations';
                        //currency = ???
                        //practise = ??

                        pse__proj__c project = new pse__proj__c();
                        project = PSA_AutoCreateProjectUtil.createProjectWithTemplate(projectName,projectTemplate,eachCase.Contract__c,configurationCli,autogenPlus_mdt.ProjectCase_Name__c,configurationCli.Id,configurationCli.Id,perMonthCli.Id,'Monthly Commit (MRR)',budget,plannedHours);                                     
                        try{
                            project.Ongoing_Project_Recurring_Planned_Hour__c = plannedHours/noOfActiveMonths;
                        }
                        catch(Exception e)
                        {
                            project.Ongoing_Project_Recurring_Planned_Hour__c = 0;
                        }
                        project.pse__Planned_Hours__c = plannedHours;

                        //Generate ExtrenalId unique to project as perMonth CLI Id + configuration CLI Id
                        project.External_Id__c = String.valueOf(perMonthCli.Id) + String.valueOf(configurationCli.Id) + String.valueOf(system.now());
                        //System.debug('@@@MSR Project: '+project);
                        autogenInstanceList.projectsForUpsert.add(project);

                        //Create Project to Case association
                        pca = PSA_AutoCreateProjectUtil.createProjectCaseAssociationRecordExternalid(project,eachCase.Id,eachCase.Contract__c,'Plus- Monthly Service Report',autogenPlus_mdt.ProjectCase_Name__c);
                        pca.Contract_Detail__c = perMonthCli.Id;
                        autogenInstanceList.pcaForUpsert.add(pca);

                        successProjects += '\nPlus Monthly Service Report';
                        if(hoursCli == NULL)
                        {
                            failureProjects += '\nPlus-Hours';
                        }


                    }
                    if(hoursCli != NULL)
                    {
                        //Create PS Hours Project
                        //System.debug('@@@PS Hours project');
                        //No of Active Months/Monthly reports and Planned Hours
                        noOfActiveMonths = PSA_AutoCreateProjectUtil.numberOfActiveMonths(hoursCli.Effective_Start_Date__c,hoursCli.Effective_End_Date__c);      
                        noOfMonthlsPerBillingPeriod = 3;
                        try{
                            monthlyRecurringHours = hoursCli.Units_Low__c / noOfMonthlsPerBillingPeriod;
                        }
                        catch(Exception e)
                        {
                            monthlyRecurringHours = 0;
                        }
                        plannedHours = noOfActiveMonths * monthlyRecurringHours;
                        budget = 0;
                        feeSchedule = 'Quarterly Commit (MRR) w/ Overage';
                        pse__proj__c projectTemplate = projTemplates.get('GSS Products/Plus - Professional Services – Project Template');
                        projectName = 'Plus-Hours';
                        //currency = ???
                        //practise = ??


                        pse__proj__c project = new pse__proj__c();
                        project = PSA_AutoCreateProjectUtil.createProjectWithTemplate(projectName,projectTemplate,eachCase.Contract__c,hoursCli,'MSR-PSH',hoursCli.Id,hoursCli.Id,perMonthCli.Id,'Quarterly Commit (MRR) w/ Overage',budget,plannedHours);                                     

                        project.Ongoing_Project_Recurring_Planned_Hour__c = monthlyRecurringHours;
                        project.pse__Planned_Hours__c = plannedHours;

                        //Generate ExtrenalId unique to project as perMonth CLI Id + configuration CLI Id
                        project.External_Id__c = String.valueOf(perMonthCli.Id) + String.valueOf(hoursCli.Id) + String.valueOf(system.now());
                        //System.debug('@@@PSH Project: '+project);
                        autogenInstanceList.projectsForUpsert.add(project);


                        //Create Project to Case association
                        pca = PSA_AutoCreateProjectUtil.createProjectCaseAssociationRecordExternalid(project,eachCase.Id,eachCase.Contract__c,'Plus-PS Hours Report',autogenPlus_mdt.ProjectCase_Name__c);
                        pca.Contract_Detail__c = perMonthCli.Id;
                        autogenInstanceList.pcaForUpsert.add(pca);
                        
                        successProjects += '\nPlus-Hours';
                        if(configurationCli == NULL)
                        {
                            failureProjects += '\nPlus Monthly Service Report';
                        }
                        
                    }

                    
                }
                //Update Case Description
                //eachCase.Description += '\n\nPlease refer to Plus Service and Support customer onboarding steps located at: https://ac.akamai.com/docs/DOC-62811';
                
                //System.debug('@@@failureProjects: '+failureProjects);
                //System.debug('@@@successProjects: '+successProjects);

                //System.debug('@@@eachCase.Description.0.0: '+eachCase.Description);

                //Replace the case description of no projects created with blank to ensure no duplicate entry is made into the case description
                //String noProjectsCreatedErrorMessage = '<### PROJECTS NOT CREATED ###>\nPlus Monthly Service Report\nPlus-Hours\n\nPlease note that due to contract set-up, none of the Salesforce projects have been automatically created. Please follow these guidelines on how to create the projects manually: https://ac.akamai.com/docs/DOC-60701\n';
                
                String allError =   '\n\n<### PROJECTS NOT CREATED ###>\n\n'+
                                        'Plus Monthly Service Report'+
                                        '\nPlus-Hours\n\n'+
                                        'Please note that due to contract set-up, none of the Salesforce projects have been automatically created.'+
                                        '\n\nPlease follow these guidelines on how to create the projects manually: https://ac.akamai.com/docs/DOC-60701';

                String partError =  '\n\nDue to contract set-up, only some projects could be automatically created.\n\n'+
                                        'Links to Projects can be found on the Project Case Association Related List section of the Case'+
                                        '\n\n<### PROJECTS SUCCESSFULLY CREATED ###>' + successProjects + 
                                        '\n\n<### PROJECTS NOT CREATED ###>' + failureProjects +
                                        '\n\nPlease follow these guidelines on project assignment & usage: https://ac.akamai.com/docs/DOC-60701';

                String allSuccess = '\n\nPlease note that all projects have been automatically created:'+
                                        '\nLinks to Projects can be found on the Project Case Association Related List section of the Case'+
                                        '\nPlease follow these guidelines on project assignment & usage: https://ac.akamai.com/docs/DOC-60701';


                //System.debug('@@@eachCase.Description1: '+eachCase.Description);
                if(eachCase.Description == null)
                {
                   eachCase.Description = ''; 
                } 
                //System.debug('@@@eachCase.Description2: '+eachCase.Description);

                eachCase.Description = eachCase.Description.replaceAll(allError,'');
                //System.debug('@@@eachCase.Description3: '+eachCase.Description);

                if(String.isEmpty(failureProjects))
                {
                    //All projects creation succeeded
                    eachCase.Description += allSuccess;
                    //System.debug('@@@allSuccess: '+allSuccess);
                    //System.debug('@@@eachCase.Description4: '+eachCase.Description);
                    
                }
                else if(String.isEmpty(successProjects))
                {
                    //All projects creation failed
                    eachCase.Description += allError;
                    //System.debug('@@@allError: '+allError);
                    //System.debug('@@@eachCase.Description5: '+eachCase.Description);

                }
                else
                {
                    //One project succedeed, one failed
                    eachCase.Description += partError;
                    //System.debug('@@@allError: '+allError);
                    //System.debug('@@@eachCase.Description6: '+eachCase.Description);
                }

                autogenInstanceList.casesForUpsert.add(eachCase);
            }
            
        }
   
        
        //For all the projects create BUDGETS and use externalId to link
        
        //To create the budget with specific name -> create a map of project name to budget name. This is to be passed as the second parameter
        Map<String,String> ProjectNametoBudgetName = new Map<String,String>();
        ProjectNametoBudgetName.put('Plus Monthly Service Report','Plus Monthly Reports');
        ProjectNametoBudgetName.put('Plus-Hours','Plus PS Hours');

        autogenInstanceList.budgetsForUpsert.addAll(PSA_AutoCreateProjectUtil.createBudgetWithNameExternalId(autogenInstanceList.projectsForUpsert,'Customer Purchase Order',ProjectNametoBudgetName));

        for(pse__Budget__c bud : autogenInstanceList.budgetsForUpsert)
        {
            //System.debug('@@@Budget:bud: '+bud);
        }
        
        //For all the projects create all the MILESTONES and use externalId to link

        //For monthly service report project, for the montly report preparation we have to set milestone planned hpi=urs = project planned hours
        List<String> setPlannedhoursFromProject = new List<String>();
        setPlannedhoursFromProject.add('Monthly Report Preparation');

        autogenInstanceList.milestonesForUpsert.addAll(PSA_AutoCreateProjectUtil.createMilestonesExternalId(autogenInstanceList.projectsForUpsert,null,setPlannedhoursFromProject,null,null));
        

        //System.debug('@@@autogenInstanceList: ');
        //System.debug('@@@projects: '+autogenInstanceList.projectsForUpsert.size());
        //System.debug('@@@pca: '+autogenInstanceList.pcaForUpsert.size());
        //System.debug('@@@budgets: '+autogenInstanceList.budgetsForUpsert.size());
        //System.debug('@@@milestones: '+autogenInstanceList.milestonesForUpsert.size());
    }

 
    
}