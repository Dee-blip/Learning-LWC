/*
Developer                        Date                        JIRA                            Changes
Sandeep Naga                   28th Nov 2019               FFPSA-1148            Created class for MSS BotManager Project Autogens  

*/

public class PSA_AutoCreateMSSBotManager implements PSA_AutogenInterface{
    
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
    public PSA_Autogen__mdt autogenMSSBotManagerMDT;
    
    //Variable that contains all product Ids obtained from the custom metadata
    Set<String> productIdsSet = new Set<String>();
    
    //Variable for haveing a map of ("Per month") CLI id : Map of ("Per month"),("Reviews") and ("Hours") CLIs
    Map<Id,Map<String,Merge_Contract_Detail__c>> clisForProjectMap = new Map<Id,Map<String,Merge_Contract_Detail__c>>();
    
    

    public PSA_AutoCreateMSSBotManager() {
        
        //Intantiate the interface object and project templates Map
        autogenInstanceList = new PSA_AutogenObjectList();
        projTemplates = new Map<String,pse__Proj__c>();
        autogenMSSBotManagerMDT = [SELECT Id,Autogen_Usecase__c,Product_Id__c,ProjectCase_Name__c FROM PSA_Autogen__mdt WHERE Product_Name__c = 'MSSBotManager' limit 1];
        if(autogenMSSBotManagerMDT.Product_Id__c != NULL)
        {
            productIdsSet.addAll(autogenMSSBotManagerMDT.Product_Id__c.split(','));
            System.debug('productIdsSet >> '+ productIdsSet);
            
        }
    }
    
    
    //Validate all the data : Contracts, CLIs, Cases etc
    public PSA_AutogenObjectList getContractDetailsForUpsert(List<Merge_Contract_Header__c> contractsList,List<Merge_Contract_Detail__c> contractDetailsList,List<Case> casesList,List<Project_Case_Association__c> pcaList, Map<String,pse__Proj__c> projTemplatesMap){
        
        //System.debug('contractsList >> ' + contractsList);
        //System.debug('contractDetailsList >> ' + contractDetailsList);
        //System.debug('casesList >> ' + casesList);
        //System.debug('pcaList >> ' + pcaList);
        //System.debug('projTemplatesMap >> ' + projTemplatesMap);
        
        Set<String> perMonthCLIs = new Set<String>();
        //to remove duplicate PER Month CLIs from Cases
        for(Case eachCase : casesList){
            //eachCase.Contract_Detail__c = eachCase.Contract_Detail__c.substring(0,15);
            perMonthCLIs.add(eachCase.Contract_Detail__c);
        }
        
        //Fetch all the project template names required from the custom meta data and use the projTemplatesMap to fetch the actual templates
        for (PSA_ProjectTemplates__mdt templates_mdt :[SELECT Name__c,Parent_Autogen__c, Sub_Type__c, Type__c 
                                                       FROM PSA_ProjectTemplates__mdt 
                                                       WHERE 
                                                       Parent_Autogen__c = :autogenMSSBotManagerMDT.id 
                                                       ORDER BY DeveloperName]){
                                                           
                                                           if(projTemplatesMap.containsKey(templates_mdt.Name__c) && projTemplatesMap.get(templates_mdt.Name__c).pse__Project_Type__c == templates_mdt.Type__c && projTemplatesMap.get(templates_mdt.Name__c).Project_Sub_Type__c == templates_mdt.Sub_Type__c){
                                                               projTemplates.put(templates_mdt.Name__c,projTemplatesMap.get(templates_mdt.Name__c));
                                                               System.debug('projTemplates >> '+ projTemplates);
                                                           }
                                                           
                                                       }
        
        if(projTemplates.size() != 3)
        {
            PSA_AutoCreateProjectUtil.sendErrorMails('MSS - BotManager - Technical Reviews , MSS - BotManager - Security Configuration Assistance and MSS - BotManager - Security Services Primary - Project Template templates have not been found',''); 
            return autogenInstanceList;
        }
        
        
        //Flitered List to use later
        List<Merge_Contract_Detail__c> perMonthAutogenClisList = new List<Merge_Contract_Detail__c>();
        List<Merge_Contract_Detail__c> othersAutogenClisList = new List<Merge_Contract_Detail__c>();
        
        Map<String,Id> cliNameToIdMap = new Map<String,Id>();
        
        
        
        //Filter out all the CLIs which are not satisfying the specific functions of the class
        for(Merge_Contract_Detail__c eachCLI : contractDetailsList){
            System.debug('eachCLI >> ' + eachCLI);
            cliNameToIdMap.put(eachCLI.Name, eachCLI.Id);
            System.debug('cliNameToIdMap >> ' + cliNameToIdMap);
            Date thirtyFourDays = Date.today() + 34; 
            Date lastTwoDays = Date.today()-2;
            
            if( eachCLI.Effective_Start_Date__c < thirtyFourDays || eachCLI.createddate > lastTwoDays) {
                //2. If record type is "Committed"
                //3. If Unit of Measure is "Per Month" ||  "Per Month", "Reviews" || "Per Month", "Hours"
                //4. If any of the PSA Autogen Records contain the product ID associated to Advanced
                //5. Check if cli Id not present in records of project case association so as to not create duplicate projects
                
                //segregate the PerMonth and Hour||Config Clis to different List[]
                if(eachCLI.Record_Type__c == 'Committed' && productIdsSet.contains(eachCLI.Product_Id__c)){
                    System.debug('eachCLI.Product_Id__c >> '+ eachCLI.Product_Id__c);
                    
                    if(eachCLI.Unit_of_Measure__c == 'Per Month' && perMonthCLIs.contains(eachCLI.Name)){
                    //if(eachCLI.Unit_of_Measure__c == 'Per Month'){
                        perMonthAutogenClisList.add(eachCLI);
                    }
                    else if(eachCLI.Unit_of_Measure__c == 'Reviews'|| eachCLI.Unit_of_Measure__c == 'Hour'){                        
                        othersAutogenClisList.add(eachCLI);
                    }                                        
                }
                //System.debug('perMonthAutogenClisList >> ' + perMonthAutogenClisList.size() + ' >>'+perMonthAutogenClisList);
                //System.debug('othersAutogenClisList >> ' +  othersAutogenClisList.size() + ' >>' + othersAutogenClisList);
            }
        }
        
        //to Store Unit Of Measure PerMonth to the ContractDetail ID
        Map<String,Id> cliMap = new Map<String,Id>();
        
        //Run through all the CLIs and MAP all the CLIs required for a project set
        for(Merge_Contract_Detail__c eachPerMonthCLI : perMonthAutogenClisList){
            System.debug('eachPerMonthCLI >> ' + eachPerMonthCLI);
            clisForProjectMap.put(eachPerMonthCLI.id,new Map<String,Merge_Contract_Detail__c>());
            clisForProjectMap.get(eachPerMonthCLI.id).put(eachPerMonthCLI.Unit_of_Measure__c,eachPerMonthCLI);
            //make a combination uniqe to find other Reviews/Hour CLIs that also has the matching columns
            String temp = ''+eachPerMonthCLI.Original_Contract_Id__c + String.valueOf(eachPerMonthCLI.Effective_Start_Date__c) + String.valueOf(eachPerMonthCLI.Effective_End_Date__c);
            cliMap.put(temp,eachPerMonthCLI.id);
            System.debug('cliMap >> '+ cliMap);
            
        }
        
        //Map other (Reviews and Hour) ClIs with perMonth CLIs
        for(Merge_Contract_Detail__c eachOthersCLI : othersAutogenClisList){   
            
            System.debug('eachOthersCLI >> '+ eachOthersCLI);
            String temp = '' + eachOthersCLI.Original_Contract_Id__c + String.valueOf(eachOthersCLI.Effective_Start_Date__c) + String.valueOf(eachOthersCLI.Effective_End_Date__c);
            Id key = cliMap.get(temp);
            System.debug('eachOthersCLI > key >> '+ key);
            if(clisForProjectMap.containsKey(key)){
                
                if(!clisForProjectMap.get(key).containsKey(eachOthersCLI.Unit_of_Measure__c) || clisForProjectMap.get(key).get(eachOthersCLI.Unit_of_Measure__c).lastmodifieddate < eachOthersCLI.lastmodifieddate){
                    clisForProjectMap.get(key).put(eachOthersCLI.Unit_of_Measure__c,eachOthersCLI);                        
                    System.debug('clisForProjectMap >> '+ clisForProjectMap);
                }
            } 
        }
        
        Map<Id,List<Merge_Contract_Detail__c>> caseClisList = new Map<Id,List<Merge_Contract_Detail__c>>();
        
        //if there are valid CLIs and cases, call the funtion to create projects
        if(!clisForProjectMap.isEmpty() && !cliNameToIdMap.isEmpty()){
            
            //Run through all the cases and create project sets for each record in the clisForProjectMap and make an entry with the case id and project ids later in pca
            for(Case eachCase : casesList){
                System.debug('eachCase >> '+ eachCase + ' >>> cliNameToIdMap '+ cliNameToIdMap + ' >>> eachCase.Contract_Detail__c ' + eachCase.Contract_Detail__c);
                System.debug(' >>> clisForProjectMap ' + clisForProjectMap);
                if(eachCase.ParentId == NULL && cliNameToIdMap.containsKey(eachCase.Contract_Detail__c) && clisForProjectMap.containsKey(cliNameToIdMap.get(eachCase.Contract_Detail__c))){
                    caseClisList.put(eachCase.Id , clisForProjectMap.get(cliNameToIdMap.get(eachCase.Contract_Detail__c)).values());
                    System.debug('caseClisList >> '+ caseClisList);
                }
            }   
        }
        
        CreateProjects(caseClisList,casesList);
        
        
        return autogenInstanceList;
    }
    
    //Ignore this method as its not implemented
    public void getContractDetails(List<Merge_Contract_Header__c> ListContractScope,List<Merge_Contract_Detail__c> ListContractDetailstoCheck,List<Case> CasesCreated,List<Project_Case_Association__c> projectCases){
        
    }
    
    //Ignore this method
    public void CreateProjects(Map<Id,List<Merge_Contract_Detail__c>> caseClisList,List<Case> autogenCasesList){
        
        System.debug('caseClisList >>  ' + caseClisList);
        System.debug('autogenCasesList >>  ' + autogenCasesList);
        Merge_Contract_Detail__c perMonthCli;
        Merge_Contract_Detail__c reviewsCli;
        Merge_Contract_Detail__c hoursCli;
        
        Project_Case_Association__c pca;
        
        Integer noOfActiveMonths;
        Integer consultingPlannedHours;
        Integer msrPlannedHours;
        Integer noOfQBRReviews;
        Integer qbrPlannedHours;
        Integer noOfMonthlsPerBillingPeriod;
        Integer noOfTSRReviews;
        Double monthlyRecurringHours;
        
        Double budget;
        Double plannedHours;
        
        String feeSchedule;
        String projectName;
        
        String successProjects;
        String failureProjects;    
        
        Map<String,Integer> projectExternalIdToReviewsMap = new Map<String,Integer>();
        List<pse__Milestone__c> initialMilestones = new List<pse__Milestone__c>();
        Integer noOfMilestonesToCreate;
        pse__Milestone__c tempMilestone;
        List<pse__Milestone__c> milestonesToCreate = new List<pse__Milestone__c>();
        
        
        for(Case eachCase : autogenCasesList)
        {
            
            System.debug('eachCase >>> '+ eachCase);
            successProjects = '';
            failureProjects = '';   
            
            
            perMonthCli = NULL;
            reviewsCli = NULL;
            hoursCli = NULL;
            
            if(eachCase.ParentId == NULL && caseClisList.containsKey(eachCase.Id))
            {
                System.debug('eachCase >> '+ eachCase.Id);
                for(Merge_Contract_Detail__c cli : caseClisList.get(eachCase.Id))
                {
                    if(cli.Unit_of_Measure__c == 'Per Month')
                    {
                        perMonthCli = cli;
                    }
                    if(cli.Unit_of_Measure__c == 'Reviews')
                    {
                        reviewsCli = cli;
                    }
                    if(cli.Unit_of_Measure__c == 'Hour')
                    {
                        hoursCli = cli;
                    }
                }

                if(perMonthCli != NULL)
                {
                
                    //Security Services Project

                        // System.debug('perMonthCli >> '+ perMonthCli);
                            
                        noOfActiveMonths = PSA_AutoCreateProjectUtil.numberOfActiveMonths(perMonthCli.Effective_Start_Date__c,perMonthCli.Effective_End_Date__c);      
                        consultingPlannedHours = noOfActiveMonths * 12;
                        msrPlannedHours = noOfActiveMonths * 3;
                        noOfQBRReviews = noOfActiveMonths/3;
                        qbrPlannedHours = noOfQBRReviews * 3;
                        
                        plannedHours = (consultingPlannedHours + msrPlannedHours + qbrPlannedHours) == 0 ? 1 : (consultingPlannedHours + msrPlannedHours + qbrPlannedHours); 
                        try{
                            monthlyRecurringHours = plannedHours/noOfActiveMonths;
                        }
                        catch(Exception e){
                            monthlyRecurringHours = 0;
                        }

                        budget = 0;
                        feeSchedule = 'One-Time: Fixed Price';
                        pse__proj__c projectTemplate = projTemplates.get('GSS Products/MSS - BotMan - Security Services Primary - Project Template');
                        //Number of Reviews is Units_Low__c
                        projectName = 'Managed Security Service_SSP';
                        
                        pse__proj__c project = new pse__proj__c();
                        project = PSA_AutoCreateProjectUtil.createProjectWithTemplate(projectName,projectTemplate,eachCase.Contract__c,perMonthCli,autogenMSSBotManagerMDT.ProjectCase_Name__c,perMonthCli.Id,perMonthCli.Id,perMonthCli.Id,feeSchedule,budget,plannedHours);                                     
                        project.Ongoing_Project_Recurring_Planned_Hour__c = monthlyRecurringHours;
                        project.pse__Planned_Hours__c = Math.round(plannedHours);
                        project.Contract_Closed__c = 'Yes';
                        //Generate ExtrenalId unique to project as perMonth CLI Id
                        project.External_Id__c = String.valueOf(perMonthCli.Id) + String.valueOf(system.now());
                        autogenInstanceList.projectsForUpsert.add(project);
                        
                        
                        //Create Project to Case association
                        pca = PSA_AutoCreateProjectUtil.createProjectCaseAssociationRecordExternalid(project,eachCase.Id,eachCase.Contract__c,'MSS - BotMan - Security Services Primary',autogenMSSBotManagerMDT.ProjectCase_Name__c);
                        pca.Contract_Detail__c = perMonthCli.Id;
                        autogenInstanceList.pcaForUpsert.add(pca);

                        successProjects += '\nSecurity Services';

                    //Technical Reviews Project
                    if(reviewsCli != NULL)
                    {

                        // System.debug('reviewsCli >> '+ reviewsCli);
                        
                        noOfActiveMonths = PSA_AutoCreateProjectUtil.numberOfActiveMonths(reviewsCli.Effective_Start_Date__c,reviewsCli.Effective_End_Date__c);      
                        noOfTSRReviews = ((reviewsCli.Units_Low__c/12) * noOfActiveMonths).intValue();
                        plannedHours = noOfTSRReviews == 0 ? 1 : (noOfTSRReviews * 10);
                        budget = 0;
                        feeSchedule = 'One-Time: Fixed Price';
                        projectTemplate = projTemplates.get('GSS Products/MSS - BotMan - Technical Reviews – Project Template');
                        //Number of Reviews is Units_Low__c
                        projectName = 'Managed Security Service_TSR';
                        
                        project = new pse__proj__c();
                        project = PSA_AutoCreateProjectUtil.createProjectWithTemplate(projectName,projectTemplate,eachCase.Contract__c,reviewsCli,autogenMSSBotManagerMDT.ProjectCase_Name__c,reviewsCli.Id,reviewsCli.Id,perMonthCli.Id,feeSchedule,budget,plannedHours);                                     
                        project.Ongoing_Project_Recurring_Planned_Hour__c = 0;
                        project.pse__Planned_Hours__c = Math.round(plannedHours);
                        project.Contract_Closed__c = 'Yes';
                        //Generate ExtrenalId unique to project as perMonth CLI Id + reviews CLI Id
                        project.External_Id__c = String.valueOf(perMonthCli.Id) + String.valueOf(reviewsCli.Id) + String.valueOf(system.now());
                        
                        //Creatre Map of External Id to noOfTSRReviews
                        projectExternalIdToReviewsMap.put(project.External_Id__c,noOfTSRReviews);
                        System.debug('project.External_Id__c: >> '+project.External_Id__c );
                        
                        autogenInstanceList.projectsForUpsert.add(project);
                        

                        //Create Project to Case association
                        pca = PSA_AutoCreateProjectUtil.createProjectCaseAssociationRecordExternalid(project,eachCase.Id,eachCase.Contract__c,'MSS - BotMan - Technical Reviews',autogenMSSBotManagerMDT.ProjectCase_Name__c);
                        pca.Contract_Detail__c = perMonthCli.Id;
                        autogenInstanceList.pcaForUpsert.add(pca);
                        
                        successProjects += '\nTechnical Reviews';

                    }
                    else 
                    {
                        failureProjects += '\nTechnical Reviews';
                    }

                    //Security Configuration Assistance Project
                    if(hoursCli != NULL)
                    {

                        // System.debug('hoursCli >> '+ hoursCli);
                        
                        noOfActiveMonths = PSA_AutoCreateProjectUtil.numberOfActiveMonths(hoursCli.Effective_Start_Date__c,hoursCli.Effective_End_Date__c);      
                        noOfMonthlsPerBillingPeriod = hoursCli.Billing_Duration__c != null ? setBillingDuration(hoursCli): 0;
                        try
                        {
                            monthlyRecurringHours = hoursCli.Units_Low__c / noOfMonthlsPerBillingPeriod;
                        }
                        catch(Exception e)
                        {
                            monthlyRecurringHours = 0;
                        }
                        plannedHours = (monthlyRecurringHours * noOfActiveMonths) == 0 ? 1 : (monthlyRecurringHours * noOfActiveMonths); 
                        budget = 0;
                        feeSchedule = 'Quarterly Commit (MRR) w/ Overage';
                        projectTemplate = projTemplates.get('GSS Products/MSS - BotMan - Security Configuration Assistance – Project Template');
                        //Number of Reviews is Units_Low__c
                        projectName = 'Managed Security Service_SCA';
                        
                        project = new pse__proj__c();
                        project = PSA_AutoCreateProjectUtil.createProjectWithTemplate(projectName,projectTemplate,eachCase.Contract__c,hoursCli,autogenMSSBotManagerMDT.ProjectCase_Name__c,hoursCli.Id,hoursCli.Id,perMonthCli.Id,feeSchedule,budget,plannedHours);                                     
                        project.Ongoing_Project_Recurring_Planned_Hour__c = monthlyRecurringHours;
                        project.pse__Planned_Hours__c = Math.round(plannedHours);
                        project.Contract_Closed__c = 'Yes';
                        //Generate ExtrenalId unique to project as perMonth CLI Id + hoursCli CLI Id
                        project.External_Id__c = String.valueOf(perMonthCli.Id) + String.valueOf(hoursCli.Id) + String.valueOf(system.now());
                        autogenInstanceList.projectsForUpsert.add(project);
                        

                        //Create Project to Case association
                        pca = PSA_AutoCreateProjectUtil.createProjectCaseAssociationRecordExternalid(project,eachCase.Id,eachCase.Contract__c,'MSS - BotMan - Security Configuration Assistance',autogenMSSBotManagerMDT.ProjectCase_Name__c);
                        pca.Contract_Detail__c = perMonthCli.Id;
                        autogenInstanceList.pcaForUpsert.add(pca);

                        successProjects += '\nSecurity Configuration Assistance';
                    }
                    else 
                    {
                        failureProjects += '\nSecurity Configuration Assistance';
                    }

                }
                //All Projects failed
                else
                {
                    failureProjects += '\nSecurity Services\nTechnical Reviews\nSecurity Configuration Assistance';
                }
                
                //Update Case Description

                String allError =   '\n\n<### PROJECTS NOT CREATED ###>\n\n'+
                                        'Security Services'+
                                        '\nSecurity Configuration Assistance\n\n'+
                                        '\nTechnical Reviews\n\n'+
                                        'Please note that due to contract set-up, none of the Salesforce projects have been automatically created.'+
                                        '\n\nPlease follow these guidelines on how to create the projects manually: https://ac.akamai.com/docs/DOC-75404';

                String partError =  '\n\nDue to contract set-up, only some projects could be automatically created.\n\n'+
                                        'Links to Projects can be found on the Project Case Association Related List section of the Case'+
                                        '\n\n<### PROJECTS SUCCESSFULLY CREATED ###>' + successProjects + 
                                        '\n\n<### PROJECTS NOT CREATED ###>' + failureProjects +
                                        '\n\nPlease follow these guidelines on project assignment & usage: https://ac.akamai.com/docs/DOC-75404';

                String allSuccess = '\n\nPlease note that all projects have been automatically created:'+
                                        '\nLinks to Projects can be found on the Project Case Association Related List section of the Case'+
                                        '\nPlease follow these guidelines on project assignment & usage: https://ac.akamai.com/docs/DOC-75404';

                if(eachCase.Description == null)
                {
                   eachCase.Description = ''; 
                } 
                //Replace the case description of no projects created with blank to ensure no duplicate entry is made into the case description
                eachCase.Description = eachCase.Description.replaceAll(allError,'');

                if(String.isEmpty(failureProjects))
                {
                    //All projects creation succeeded
                    eachCase.Description += allSuccess;
                }
                else if(String.isEmpty(successProjects))
                {
                    //All projects creation failed
                    eachCase.Description += allError;
                }
                else
                {
                    //Atleast one project failed
                    eachCase.Description += partError;
                }

                autogenInstanceList.casesForUpsert.add(eachCase);

               
            }
        }
        //For all the projects create BUDGETS and use externalId to link
        
        //To create the budget with specific name -> create a map of project name to budget name. This is to be passed as the second parameter
        Map<String,String> ProjectNametoBudgetName = new Map<String,String>();
        ProjectNametoBudgetName.put('Security Services','Security Services');
        ProjectNametoBudgetName.put('Security Configuration Assistance','Security Configuration Assistance');
        ProjectNametoBudgetName.put('Technical Reviews','Technical Reviews');
        
        autogenInstanceList.budgetsForUpsert.addAll(PSA_AutoCreateProjectUtil.createBudgetWithNameExternalId(autogenInstanceList.projectsForUpsert,'Customer Purchase Order',ProjectNametoBudgetName));
        
        //For all the projects create all the MILESTONES and use externalId to link
        initialMilestones = PSA_AutoCreateProjectUtil.createMilestonesExternalId(autogenInstanceList.projectsForUpsert,null,null,null,null);
        
        //Dynamic milestones for TSR Reviews, run through all milestones and fetch ones with Project ExternalId present in the map
        for(pse__Milestone__c eachMilestone : initialMilestones)
        {
            if(projectExternalIdToReviewsMap.containsKey(eachMilestone.pse__Project__r.External_Id__c))
            {
                System.debug('eachMilestone.pse__Project__r.No Of Reviews: >> '+eachMilestone.Name+ ' : '+projectExternalIdToReviewsMap.get(eachMilestone.pse__Project__r.External_Id__c) );
                for(Integer i = 1; i <= projectExternalIdToReviewsMap.get(eachMilestone.pse__Project__r.External_Id__c);i++)
                {
                    tempMilestone = eachMilestone.clone();
                    tempMilestone.Name = tempMilestone.Name + ' #' +i;
                    tempMilestone.pse__Planned_Hours__c  = 10;
                    tempMilestone.Task_Milestone_Name__c = tempMilestone.Task_Milestone_Name__c + ' #' +i;
                    tempMilestone.External_Id__c = tempMilestone.External_Id__c + ' #' +i;
                    milestonesToCreate.add(tempMilestone);
                }
            }
            else
            {
                milestonesToCreate.add(eachMilestone);
            }
        }
		//System.assert(false, '!!End');
        autogenInstanceList.milestonesForUpsert.addAll(milestonesToCreate);
    }
    
    public Integer setBillingDuration(Merge_Contract_Detail__c cli){
        Integer billDuration = 0;
        if(cli.Billing_Duration__c.contains('Monthly')){
            billDuration = 1;
        }else if(cli.Billing_Duration__c.contains('Quarterly')){
            billDuration = 3;
        }else if(cli.Billing_Duration__c.contains('Annual')){
            billDuration = 12;
        }
        return billDuration;
    }
    
}