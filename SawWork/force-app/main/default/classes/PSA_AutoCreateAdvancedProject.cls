/*
Developer                        Date                        JIRA                            Changes
Sujay                      25th Aug 2019                   FFPSA-972            Created class for Advanced Project Autogens  
Sandeep					   28th April 2020                 FFPSA-1295			Changes for Advanced Project Management Project Enhancement
*/

public class PSA_AutoCreateAdvancedProject implements PSA_AutogenInterface{
    
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
    public PSA_Autogen__mdt autogenAdvancedMDT;
    
    //Variable that contains all product Ids obtained from the custom metadata
    Set<String> productIdsSet = new Set<String>();
    
    //Variable for haveing a map of ("Per month") CLI id : Map of ("Per month"),("Configurations") and ("Hours") CLIs
    Map<Id,Map<String,Merge_Contract_Detail__c>> clisForProjectMap = new Map<Id,Map<String,Merge_Contract_Detail__c>>();
    
    //To store all the Project Management Option Contract in Scope.
    Set<String> contInScope = new Set<String>();
    
    //To store all the Project Management Option Contract in Scope where additional 2 milestones need to be created.
    Set<String> milestonesToInclude = new Set<String>();
    
    Map<Id,Case> emCaseIdToTmpCaseMap = new Map<Id,Case>();
    
    public PSA_AutoCreateAdvancedProject() {
        
        //Intantiate the interface object and project templates Map
        autogenInstanceList = new PSA_AutogenObjectList();
        projTemplates = new Map<String,pse__Proj__c>();
        autogenAdvancedMDT = [SELECT Id,Autogen_Usecase__c,Product_Id__c,ProjectCase_Name__c FROM PSA_Autogen__mdt WHERE Product_Name__c = 'Advanced' limit 1];
        if(autogenAdvancedMDT.Product_Id__c != NULL)
        {
            productIdsSet.addAll(autogenAdvancedMDT.Product_Id__c.split(','));
            System.debug('productIdsSet >> '+ productIdsSet);
            
        }
    }
    
    
    //Validate all the data : Contracts, CLIs, Cases etc
    public PSA_AutogenObjectList getContractDetailsForUpsert(List<Merge_Contract_Header__c> contractsList,List<Merge_Contract_Detail__c> contractDetailsList,List<Case> casesList,List<Project_Case_Association__c> pcaList, Map<String,pse__Proj__c> projTemplatesMap){
      
        System.debug('contractDetailsList >> ' + contractDetailsList);
        System.debug('pcaList >> ' + pcaList);
        
        /*
        String cliKey;
        Map<String,String> perMonthCliNameToKeyMap = new Map<String,String>();
        Map<String,String> unitCliNameToKeyMap = new Map<String,String>();
        
        for(Merge_Contract_Detail__c eachCli : contractDetailsList){
            cliKey = eachCli.Original_Contract_Id__r.Account_Name__c+string.valueOfGmt(eachCli.Effective_Start_Date__c)+string.valueOfGmt(eachCli.Effective_End_Date__c);
            if(eachCli.Unit_of_Measure__c == 'Per Month' && eachCli.Product_Id__c == 'M-LC-165776'){
                perMonthCliNameToKeyMap.put(eachCli.Original_Detail_Id__c,cliKey);
            }
            else if(eachCli.Unit_of_Measure__c == 'Per Month' && eachCli.Product_Id__c == 'M-LC-165782'){
                unitCliNameToKeyMap.put(eachCli.Original_Detail_Id__c,cliKey);
            }   
        }
        
        List<Case> casesList = new List<Case>();
        Set<String> perMonthCLINames = new Set<String>();
        Map<String,Id> keyToEmCaseIdMap = new Map<String,Id>(); 
        
        for(Case eachCase : allCasesList){
            //Em case has Unit of measure = per month
            if(perMonthCliNameToKeyMap.containsKey(eachCase.Contract_Detail__c)){
                casesList.add(eachCase);
                //to remove duplicate PER Month CLIs from Cases
                perMonthCLINames.add(eachCase.Contract_Detail__c);
                
                cliKey  = perMonthCliNameToKeyMap.get(eachCase.Contract_Detail__c);
                keyToEmCaseIdMap.put(cliKey,eachCase.Id);
            }
        }
        
        
        for(Case eachCase : allCasesList){
            if(unitCliNameToKeyMap.containsKey(eachCase.Contract_Detail__c) && keyToEmCaseIdMap.containsKey(unitCliNameToKeyMap.get(eachCase.Contract_Detail__c))){
                emCaseIdToTmpCaseMap.put(keyToEmCaseIdMap.get(unitCliNameToKeyMap.get(eachCase.Contract_Detail__c)),eachCase);
            }
        }
        
    	*/
        
        System.debug('casesList >> ' + casesList);
                
        
        //Fetch all the project template names required from the custom meta data and use the projTemplatesMap to fetch the actual templates
        for (PSA_ProjectTemplates__mdt templates_mdt :[SELECT Name__c,Parent_Autogen__c, Sub_Type__c, Type__c 
                                                       FROM PSA_ProjectTemplates__mdt 
                                                       WHERE 
                                                       Parent_Autogen__c = :autogenAdvancedMDT.id 
                                                       ORDER BY DeveloperName]){
                                                           System.debug('Template name: >> '+templates_mdt.Name__c);
                                                           System.debug(projTemplatesMap.containsKey(templates_mdt.Name__c));
                                                           if(projTemplatesMap.containsKey(templates_mdt.Name__c) && projTemplatesMap.get(templates_mdt.Name__c).pse__Project_Type__c == templates_mdt.Type__c && projTemplatesMap.get(templates_mdt.Name__c).Project_Sub_Type__c == templates_mdt.Sub_Type__c){
                                                               projTemplates.put(templates_mdt.Name__c,projTemplatesMap.get(templates_mdt.Name__c));
                                                               System.debug('projTemplates >> '+ projTemplates);
                                                           }
                                                           
                                                       }
        System.debug('projTemplates.size(): >>'+projTemplates.size());
        if(projTemplates.size() != 4)
        {
            PSA_AutoCreateProjectUtil.sendErrorMails('Advanced Service Reports, Advanced Hours and Technical Advisory templates have not been found',''); 
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
                //3. If Unit of Measure is "Per Month" ||  "Per Month", "Configurations" || "Per Month", "Hours"
                //4. If any of the PSA Autogen Records contain the product ID associated to Advanced
                //5. Check if cli Id not present in records of project case association so as to not create duplicate projects
                
                //segregate the PerMonth and Hour||Config Clis to different List[]
                if(eachCLI.Record_Type__c == 'Committed' && productIdsSet.contains(eachCLI.Product_Id__c)){
                    System.debug('eachCLI.Product_Id__c >> '+ eachCLI.Product_Id__c);
                    if(eachCLI.Product_Id__c == 'M-LC-165776'){
                        //if(eachCLI.Unit_of_Measure__c == 'Per Month' && perMonthCLINames.contains(eachCLI.Name)){
                        if(eachCLI.Unit_of_Measure__c == 'Per Month'){
                            perMonthAutogenClisList.add(eachCLI);
                        }
                        else if(eachCLI.Unit_of_Measure__c == 'Configurations'|| eachCLI.Unit_of_Measure__c == 'Hour'){                        
                            othersAutogenClisList.add(eachCLI);
                        }
                    }
                    if(eachCLI.Product_Id__c == 'M-LC-165782'){
                        if(eachCLI.Effective_End_Date__c > Date.today()){
                            contInScope.add(eachCLI.Original_Contract_Id__c);
                        }
                        if(eachCLI.Unit_of_Measure__c == 'Per Month'){
                            othersAutogenClisList.add(eachCLI);
                        }
                        
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
            System.debug('eachPerMonthCLI >> ' + eachPerMonthCLI.Id);
            clisForProjectMap.put(eachPerMonthCLI.id,new Map<String,Merge_Contract_Detail__c>());
            clisForProjectMap.get(eachPerMonthCLI.id).put(eachPerMonthCLI.Unit_of_Measure__c,eachPerMonthCLI);
            //make a combination uniqe to find other Config/Hour CLIs that also has the matching columns
            String temp = ''+eachPerMonthCLI.Original_Contract_Id__c + String.valueOf(eachPerMonthCLI.Effective_Start_Date__c) + String.valueOf(eachPerMonthCLI.Effective_End_Date__c);
            cliMap.put(temp,eachPerMonthCLI.id);
            System.debug('cliMap >> '+ cliMap.values());
            
        }
        
        for(Merge_Contract_Detail__c eachOthersCLI : othersAutogenClisList){   
            
            System.debug('eachOthersCLI >> '+ eachOthersCLI);
            String temp = '' + eachOthersCLI.Original_Contract_Id__c + String.valueOf(eachOthersCLI.Effective_Start_Date__c) + String.valueOf(eachOthersCLI.Effective_End_Date__c);
            Id key = cliMap.get(temp);
            if(key!=null){
                System.debug('eachOthersCLI > key >> '+ key);
            }
            
            if(key!=null && clisForProjectMap.containsKey(key)){
                System.debug('@@@clisForProjectMap.get(key): '+clisForProjectMap.get(key));
                System.debug('@@@clisForProjectMap.get(key).containsKey(eachOthersCLI.Unit_of_Measure__c): ');
                System.debug(clisForProjectMap.get(key).containsKey(eachOthersCLI.Unit_of_Measure__c));
                if(!clisForProjectMap.get(key).containsKey(eachOthersCLI.Unit_of_Measure__c) || clisForProjectMap.get(key).get(eachOthersCLI.Unit_of_Measure__c).lastmodifieddate < eachOthersCLI.lastmodifieddate){
                    
                    /*if(eachOthersCLI.Product_Id__c == 'M-LC-165782' && eachOthersCLI.Unit_of_Measure__c == 'Per Month'){
                        clisForProjectMap.get(key).put('Unit',eachOthersCLI);
                    }
                    else{*/
                        clisForProjectMap.get(key).put(eachOthersCLI.Unit_of_Measure__c,eachOthersCLI);                        
                    //}
                    
                    System.debug('clisForProjectMap >> '+ key+ ': '+eachOthersCLI.Unit_of_Measure__c);
                }
                else if(eachOthersCLI.Product_Id__c == 'M-LC-165782' && eachOthersCLI.Unit_of_Measure__c == 'Per Month'){
                    if(!clisForProjectMap.get(key).containsKey('Unit') || clisForProjectMap.get(key).get('Unit').lastmodifieddate < eachOthersCLI.lastmodifieddate ){
                        clisForProjectMap.get(key).put('Unit',eachOthersCLI);
                    }
                	
                }
            } 
        }
        
        Map<Id,List<Merge_Contract_Detail__c>> caseClisList = new Map<Id,List<Merge_Contract_Detail__c>>();
        List<Merge_Contract_Detail__c> tempCliList = new List<Merge_Contract_Detail__c>();
        
        //if there are valid CLIs and cases, call the funtion to create projects
        if(!clisForProjectMap.isEmpty() && !cliNameToIdMap.isEmpty()){
            
            //Run through all the cases and create project sets for each record in the clisForProjectMap and make an entry with the case id and project ids in ???
            for(Case eachCase : casesList){
                System.debug('cliNameToIdMap.containsKey(eachCase.Contract_Detail__c): >>>');
                System.debug(cliNameToIdMap.containsKey(eachCase.Contract_Detail__c));
                System.debug('cliNameToIdMap.get(eachCase.Contract_Detail__c): >>>'+cliNameToIdMap.get(eachCase.Contract_Detail__c));
                System.debug('clisForProjectMap.containsKey(cliNameToIdMap.get(eachCase.Contract_Detail__c)): >>>'+clisForProjectMap.containsKey(cliNameToIdMap.get(eachCase.Contract_Detail__c)));
                System.debug('eachCase.ParentId: >>>'+eachCase.ParentId);
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
        Merge_Contract_Detail__c configurationCli;
        Merge_Contract_Detail__c hoursCli;
        Merge_Contract_Detail__c unitCli;
        
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
            
            System.debug('eachCase >>> '+ eachCase);
            successProjects = '';
            failureProjects = '';   
            
            
            perMonthCli = NULL;
            configurationCli = NULL;
            hoursCli = NULL;
            
            if(eachCase.ParentId == NULL && caseClisList.containsKey(eachCase.Id))
            {
                System.debug('eachCase >> '+ eachCase.Id);
                for(Merge_Contract_Detail__c cli : caseClisList.get(eachCase.Id))
                {
                    if(cli.Unit_of_Measure__c == 'Per Month' && cli.Product_Id__c == 'M-LC-165776')
                    {
                        perMonthCli = cli;
                        System.debug('@@@perMonthCli.Id+'+perMonthCli.Id);
                    }
                    if(cli.Unit_of_Measure__c == 'Configurations')
                    {
                        configurationCli = cli;
                        System.debug('@@@configurationCli.Id+'+configurationCli.Id);
                    }
                    if(cli.Unit_of_Measure__c == 'Hour')
                    {
                        hoursCli = cli;
                        System.debug('@@@hoursCli.Id+'+hoursCli.Id);
                    }
                    if(cli.Unit_of_Measure__c == 'Per Month' && cli.Product_Id__c == 'M-LC-165782')
                    {
                        unitCli = cli;
                        System.debug('@@@unitCli.Id+'+unitCli.Id);
                    }
                    
                }
                
                if(configurationCli != NULL)
                {
                    System.debug('configurationCli >> '+ configurationCli);
                    //Create Advanced Service Reports Project
                    
                    //No of Active Months/Monthly reports and Planned Hours
                    noOfActiveMonths = PSA_AutoCreateProjectUtil.numberOfActiveMonths(configurationCli.Effective_Start_Date__c,configurationCli.Effective_End_Date__c);      
                    //noOfMonthlyReports = noOfActiveMonths;
                    plannedHours = 6.33 * noOfActiveMonths; 
                    budget = 0;
                    feeSchedule = 'Monthly Commit (MRR)';
                    pse__proj__c projectTemplate = projTemplates.get('GSS Products/Advanced - Service Reports – Project Template');
                    //Number of configurations is Units_Low__c
                    projectName = 'Advanced Service Reports-' + configurationCli.Units_Low__c +' configurations';
                    
                    pse__proj__c project = new pse__proj__c();
                    project = PSA_AutoCreateProjectUtil.createProjectWithTemplate(projectName,projectTemplate,eachCase.Contract__c,configurationCli,autogenAdvancedMDT.ProjectCase_Name__c,configurationCli.Id,configurationCli.Id,perMonthCli.Id,feeSchedule,budget,plannedHours);                                     
                    project.Ongoing_Project_Recurring_Planned_Hour__c = 0;
                    project.pse__Planned_Hours__c = Math.round(plannedHours);
                    project.Contract_Closed__c = 'Yes';
                    //Generate ExtrenalId unique to project as perMonth CLI Id + configuration CLI Id
                    project.External_Id__c = String.valueOf(perMonthCli.Id) + String.valueOf(configurationCli.Id) + String.valueOf(system.now());
                    autogenInstanceList.projectsForUpsert.add(project);
                    
                    if(contInScope.contains(configurationCli.Original_Contract_Id__c)){
                        milestonesToInclude.add(project.External_Id__c);
                    }
                    //Create Project to Case association
                    pca = PSA_AutoCreateProjectUtil.createProjectCaseAssociationRecordExternalid(project,eachCase.Id,eachCase.Contract__c,'Advanced- Service Report',autogenAdvancedMDT.ProjectCase_Name__c);
                    pca.Contract_Detail__c = perMonthCli.Id;
                    autogenInstanceList.pcaForUpsert.add(pca);
                    
                    successProjects += '\nAdvanced Service Reports Project';
                    
                }
                if(hoursCli != NULL)
                {
                    System.debug('hoursCli >> '+ hoursCli);
                    //Create Advanced Hours Project
                    //No of Active Months/Monthly reports and Planned Hours
                    noOfActiveMonths = PSA_AutoCreateProjectUtil.numberOfActiveMonths(hoursCli.Effective_Start_Date__c,hoursCli.Effective_End_Date__c);      
                    noOfMonthlsPerBillingPeriod = hoursCli.Billing_Duration__c != null ? setBillingDuration(hoursCli): 0;
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
                    pse__proj__c projectTemplate = projTemplates.get('GSS Products/Advanced - Professional Services – Project Template');
                    projectName = 'Advanced-Hours';
                    
                    pse__proj__c project = new pse__proj__c();
                    project = PSA_AutoCreateProjectUtil.createProjectWithTemplate(projectName,projectTemplate,eachCase.Contract__c,hoursCli,'Advanced-HP',hoursCli.Id,hoursCli.Id,perMonthCli.Id,feeSchedule,budget,plannedHours);                                     
                    
                    project.Ongoing_Project_Recurring_Planned_Hour__c = monthlyRecurringHours;
                    project.pse__Planned_Hours__c = Math.round(plannedHours);
                    project.Contract_Closed__c = 'Yes';
                    
                    //Generate ExtrenalId unique to project as perMonth CLI Id + configuration CLI Id
                    project.External_Id__c = String.valueOf(perMonthCli.Id) + String.valueOf(hoursCli.Id) + String.valueOf(system.now());
                    //System.debug('@@@PSH Project: '+project);
                    autogenInstanceList.projectsForUpsert.add(project);
                    
                    
                    //Create Project to Case association
                    pca = PSA_AutoCreateProjectUtil.createProjectCaseAssociationRecordExternalid(project,eachCase.Id,eachCase.Contract__c,'Advanced- Hours Report',autogenAdvancedMDT.ProjectCase_Name__c);
                    pca.Contract_Detail__c = perMonthCli.Id;
                    autogenInstanceList.pcaForUpsert.add(pca);
                    
                    successProjects += '\nAdvanced Hours Project';
                    
                }
                if(perMonthCli != NULL)
                {
                    
                    if(unitCli != NULL){
                        
                        noOfActiveMonths = PSA_AutoCreateProjectUtil.numberOfActiveMonths(perMonthCli.Effective_Start_Date__c,perMonthCli.Effective_End_Date__c);      
                        plannedHours = noOfActiveMonths*8;
                        
                        budget = 0;
                        feeSchedule = 'Monthly Commit (MRR) w/ Overage';
                        pse__proj__c projectTemplate = projTemplates.get('GSS Products/Advanced - Project Management – Project Template');
                        projectName = 'Advanced-Project Management';
                        
                        pse__proj__c project = new pse__proj__c();
                        project = PSA_AutoCreateProjectUtil.createProjectWithTemplate(projectName,projectTemplate,eachCase.Contract__c,unitCli,'Advanced-PM',unitCli.Id,unitCli.Id,unitCli.Id,feeSchedule,budget,plannedHours);                                     
                        
                        try{
                            project.Ongoing_Project_Recurring_Planned_Hour__c = plannedHours/noOfActiveMonths;
                        }
                        catch(Exception e){
                            project.Ongoing_Project_Recurring_Planned_Hour__c = 0;
                        }
                        
                        project.pse__Planned_Hours__c = Math.round(plannedHours);
                        project.Contract_Closed__c = 'Yes';
                        
                        //Generate ExtrenalId unique to project as perMonth CLI Id + configuration CLI Id
                        project.External_Id__c = String.valueOf(perMonthCli.Id) + String.valueOf(unitCli.Id) + String.valueOf(system.now());
                        //System.debug('@@@PSH Project: '+project);
                        autogenInstanceList.projectsForUpsert.add(project);
                        
                        
                        //Create Project to Case association for EM:CSG Case using perMonth Cli
                        pca = PSA_AutoCreateProjectUtil.createProjectCaseAssociationRecordExternalid(project,eachCase.Id,eachCase.Contract__c,'Advanced- Project Management',autogenAdvancedMDT.ProjectCase_Name__c);
                        pca.Contract_Detail__c = perMonthCli.Id;
                        autogenInstanceList.pcaForUpsert.add(pca);
                        
                        /*
                        if(emCaseIdToTmpCaseMap.containsKey(eachCase.Id)){
                            System.debug('@@@emCaseIdofTmpCase'+emCaseIdToTmpCaseMap.get(eachCase.Id));
                            Case tmpCase = emCaseIdToTmpCaseMap.get(eachCase.Id);
                            pca = PSA_AutoCreateProjectUtil.createProjectCaseAssociationRecordExternalid(project,tmpCase.Id,tmpCase.Contract__c,'Advanced- Project Management',autogenAdvancedMDT.ProjectCase_Name__c);
                            pca.Contract_Detail__c = perMonthCli.Id;
                            autogenInstanceList.pcaForUpsert.add(pca);
                    	}
						*/
                        
                        //Create Project to Case association for TMP:CSG Case using Unit Cli
                        //fetch child records of eachCase, identify the TPM using autogen use case = 
                        for(Case childCase: eachCase.Cases)
                        {
                            if(childCase.Autogen_UseCase__c == 'Project Management Option'){
                                pca = PSA_AutoCreateProjectUtil.createProjectCaseAssociationRecordExternalid(project,childCase.Id,childCase.Contract__c,'Advanced- Project Management',autogenAdvancedMDT.ProjectCase_Name__c);
                            	pca.Contract_Detail__c = unitCli.Id;
                            	autogenInstanceList.pcaForUpsert.add(pca);
                            }
                        }
                        
                        successProjects += '\nProject Management Project';
                    }
                    else{
                        failureProjects += '\nProject Management Project';
                    }
                    
                    
                    System.debug('perMonthCli >> '+ perMonthCli);
                    
                    //Create Advanced Hours Project
                    //No of Active Months/Monthly reports and Planned Hours
                    noOfActiveMonths = PSA_AutoCreateProjectUtil.numberOfActiveMonths(perMonthCli.Effective_Start_Date__c,perMonthCli.Effective_End_Date__c);      
                    plannedHours = noOfActiveMonths * 8;
                    budget = 0;
                    feeSchedule = 'Monthly Commit (MRR) w/ Overage';
                    pse__proj__c projectTemplate = projTemplates.get('GSS Products/Advanced - Technical Advisory – Project Template');
                    projectName = 'Advanced-Technical Advisory';
                    
                    pse__proj__c project = new pse__proj__c();
                    project = PSA_AutoCreateProjectUtil.createProjectWithTemplate(projectName,projectTemplate,eachCase.Contract__c,perMonthCli,'Advanced-TAP',perMonthCli.Id,perMonthCli.Id,perMonthCli.Id,feeSchedule,budget,plannedHours);                                     
                    
                    project.Ongoing_Project_Recurring_Planned_Hour__c = 0;
                    project.pse__Planned_Hours__c = Math.round(plannedHours);
                    project.Contract_Closed__c = 'Yes';
                    
                    //Generate ExtrenalId unique to project as perMonth CLI Id + configuration CLI Id
                    project.External_Id__c = String.valueOf(perMonthCli.Id) + String.valueOf(system.now());
                    //System.debug('@@@PSH Project: '+project);
                    autogenInstanceList.projectsForUpsert.add(project);
                    
                    
                    //Create Project to Case association
                    pca = PSA_AutoCreateProjectUtil.createProjectCaseAssociationRecordExternalid(project,eachCase.Id,eachCase.Contract__c,'Advanced- Technical Advisory Report',autogenAdvancedMDT.ProjectCase_Name__c);
                    pca.Contract_Detail__c = perMonthCli.Id;
                    autogenInstanceList.pcaForUpsert.add(pca);
                    
                    
                    
                    successProjects += '\nTechnical Advisory Project';
                    if(hoursCli == NULL && configurationCli != NULL){
                        failureProjects += '\nAdvanced Hours Project';
                    }
                    else if(hoursCli != NULL && configurationCli == NULL){
                        failureProjects += '\nAdvanced Service Reports Project';
                    }
                    else if(hoursCli == NULL && configurationCli == NULL){
                        failureProjects += '\nAdvanced Hours Project \nAdvanced Service Reports Project';
                    }
                }
                
                
                
                //Update Case Description
                
                //Replace the case description of no projects created with blank to ensure no duplicate entry is made into the case description
                //String noProjectsCreatedErrorMessage = '<### PROJECTS NOT CREATED ###>\nPlus Monthly Service Report\nPlus-Hours\n\nPlease note that due to contract set-up, none of the Salesforce projects have been automatically created. Please follow these guidelines on how to create the projects manually: https://ac.akamai.com/docs/DOC-60701\n';
                
                String allError =   '\n\n'+
                    '\n\n<### PROJECTS NOT CREATED ###>\n\n'+
                    'Advanced Service Reports'+
                    '\nAdvanced Hours'+
                    '\nProject Management Project'+
                    '\nTechnical Advisory Project\n\n' +
                    'Please note that due to contract set-up, none of the Salesforce projects have been automatically created. '+
                    '\n\nPlease follow these guidelines on how to create the projects manually: https://ac.akamai.com/docs/DOC-60708';
                
                String partError =  '\n\n'+
                    '\n\nDue to contract set-up, only some projects could be automatically created.\n\n'+
                    'Links to Projects can be found on the Project Case Association Related List section of the Case'+
                    '\n\n<### PROJECTS SUCCESSFULLY CREATED ###> \n' + successProjects + 
                    '\n\n<### PROJECTS NOT CREATED ###>\n' + failureProjects +
                    '\n\nPlease follow these guidelines on project assignment & usage: https://ac.akamai.com/docs/DOC-60708';
                
                String allSuccess = '\n\n'+
                    '\n\nPlease note that all projects have been automatically created: Links to Projects can be found on the Project Case Association Related List section of the Case'+
                    '\n\nPlease follow these guidelines on project assignment & usage: https://ac.akamai.com/docs/DOC-60708';
                
                
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
  
                /*if(emCaseIdToTmpCaseMap.containsKey(eachCase.Id)){
                    System.debug('@@@Desciption emCaseIdofTmpCase'+emCaseIdToTmpCaseMap.get(eachCase.Id));
                    Case tmpCase = emCaseIdToTmpCaseMap.get(eachCase.Id);
                    tmpCase.Description = eachCase.Description;
                    System.debug('@@@TPM Case Description: '+tmpCase.Description);
                     
                    autogenInstanceList.casesForUpsert.add(tmpCase);
                }*/
                
                //fetch child records of eachCase, identify the TPM using autogen use case = 
                for(Case childCase: eachCase.Cases)
                {
                    if(childCase.Autogen_UseCase__c == 'Project Management Option'){
                    	childCase.Description = eachCase.Description;
                    	System.debug('@@@TPM Case Description: '+childCase.Description);
                        autogenInstanceList.casesForUpsert.add(childCase);
                    }
                }
            }
        }
        //For all the projects create BUDGETS and use externalId to link
        
        //To create the budget with specific name -> create a map of project name to budget name. This is to be passed as the second parameter
        Map<String,String> ProjectNametoBudgetName = new Map<String,String>();
        ProjectNametoBudgetName.put('Advanced Service Reports','Advanced Service Reports');
        ProjectNametoBudgetName.put('Advanced-Hours','Advanced Hours');
        ProjectNametoBudgetName.put('Advanced-Technical Advisory','Advanced Technical Advisory');
        ProjectNametoBudgetName.put('Advanced-Project Management','Advanced Project Management');
        
        autogenInstanceList.budgetsForUpsert.addAll(PSA_AutoCreateProjectUtil.createBudgetWithNameExternalId(autogenInstanceList.projectsForUpsert,'Customer Purchase Order',ProjectNametoBudgetName));
        
        //For all the projects create all the MILESTONES and use externalId to link
        
        //For monthly service report project, for the montly report preparation we have to set milestone planned hpi=urs = project planned hours
        List<String> setPlannedhoursFromProject = new List<String>();
        setPlannedhoursFromProject.add('Technical Advisory - Reports/Healthchecks');
        
        List<pse__Milestone__c> lstMilestonesForUpsert = new List<pse__Milestone__c>();
        List<pse__Milestone__c> filteredMilestonesForUpsert = new List<pse__Milestone__c>();
        
        //to store the milestones by removeing the dummmy set Weekly Report Preparation: Billable
        lstMilestonesForUpsert.addAll(PSA_AutoCreateProjectUtil.createMilestonesExternalId(autogenInstanceList.projectsForUpsert,null,setPlannedhoursFromProject,null,null));
        System.debug( 'milestonesToInclude >>> '+ milestonesToInclude );
        for(pse__Milestone__c eachMileStone : lstMilestonesForUpsert){
            System.debug( 'eachMileStone.Name.contains >>> ' + eachMileStone.Name + ' >>> '+ eachMileStone.pse__Project__r.External_Id__c );
            if(milestonesToInclude.contains(eachMileStone.pse__Project__r.External_Id__c)){
                filteredMilestonesForUpsert.add(eachMileStone);
                System.debug( 'eachMileStone >> filteredMilestonesForUpsert >>> ' + eachMileStone.Name);
            }
            else if(! (milestonesToInclude.contains(eachMileStone.pse__Project__r.External_Id__c)) && !('Weekly Report Presentation: Billable'.contains(eachMileStone.Name) || 'Weekly Report Preparation: Billable'.contains(eachMileStone.Name))){
                filteredMilestonesForUpsert.add(eachMileStone);
                System.debug( 'eachMileStone >> filteredMilestonesForUpsert >>> ' + eachMileStone.Name);
            }
        }
        autogenInstanceList.milestonesForUpsert.addAll(filteredMilestonesForUpsert);
        
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