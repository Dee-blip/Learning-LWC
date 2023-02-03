/*
 Developer                        Date                        JIRA                            Changes
 Sandeep Naga               8th June 2020                   FFPSA-1055            Created class for mPulse Project Autogens  

*/
public class PSA_AutoCreateMPulseProject implements PSA_AutogenInterface 
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

    //Variable for haveing a map of ("Per month") CLI id : Map of ("Per month"),("Assessments") and ("Hour") CLIs
    Map<Id,Map<String,Merge_Contract_Detail__c>> clisForProjectMap = new Map<Id,Map<String,Merge_Contract_Detail__c>>();
    
    //Variable for mapping unique key to Per month Cli Id.
    Map<String,Id> cliMap = new Map<String,Id>();


    public PSA_AutoCreateMPulseProject()
    {
      	//Intantiate the interface object and project templates Map
      	autogenInstanceList = new PSA_AutogenObjectList();
        projTemplates = new Map<String,pse__Proj__c>();
        autogenPlus_mdt = [SELECT Id,Autogen_Usecase__c,Product_Id__c,ProjectCase_Name__c FROM PSA_Autogen__mdt WHERE Product_Name__c = 'mPulse' limit 1];
        if(autogenPlus_mdt.Product_Id__c != NULL){
            productIdsSet.addAll(autogenPlus_mdt.Product_Id__c.split(','));
        }
    }

    //Validate all the data : Contracts, CLIs, Cases etc
    public PSA_AutogenObjectList getContractDetailsForUpsert(List<Merge_Contract_Header__c> contractsList,List<Merge_Contract_Detail__c> contractDetailsList,List<Case> casesList,List<Project_Case_Association__c> pcaList, Map<String,pse__Proj__c> projTemplatesMap)
    {

        //Fetch all the project template names required from the custom meta data and use the projTemplatesMap to fetch the actual templates
        for (PSA_ProjectTemplates__mdt templates_mdt :[select Name__c,Parent_Autogen__c, Sub_Type__c, Type__c from PSA_ProjectTemplates__mdt where Parent_Autogen__c = :autogenPlus_mdt.id order by DeveloperName]){
            System.debug('@@@templates_mdt.Name__c: '+templates_mdt.Name__c);
            System.debug(projTemplatesMap.containsKey(templates_mdt.Name__c));
            
            if(projTemplatesMap.containsKey(templates_mdt.Name__c) && projTemplatesMap.get(templates_mdt.Name__c).pse__Project_Type__c == templates_mdt.Type__c && projTemplatesMap.get(templates_mdt.Name__c).Project_Sub_Type__c == templates_mdt.Sub_Type__c){
                projTemplates.put(templates_mdt.Name__c,projTemplatesMap.get(templates_mdt.Name__c));
            }
        }

        if(projTemplates.size() != 3){
            PSA_AutoCreateProjectUtil.sendErrorMails('Monthly Tuning Reports,PS Hours, Business Assessment Reports project templates have not been found','');
            return autogenInstanceList;
        }

        //Flitered List to use later
        List<Merge_Contract_Detail__c> perMonthAutogenClisList = new List<Merge_Contract_Detail__c>();
        List<Merge_Contract_Detail__c> othersAutogenClisList = new List<Merge_Contract_Detail__c>();
        Map<String,Id> cliNameToIdMap = new Map<String,Id>();

        //Filter out all the CLIs which are not satisfying the specific functions of the class
        for(Merge_Contract_Detail__c eachCLI : contractDetailsList){
            
            cliNameToIdMap.put(eachCLI.Name, eachCLI.Id);            
          	Date thirtyThreeDays = Date.today()+33;
            Date lastTwoDays = Date.today()-2;
          	if( (eachCLI.Effective_Start_Date__c<thirtyThreeDays || eachCLI.createddate>lastTwoDays) && eachCLI.Record_Type__c=='Committed' && productIdsSet.contains(eachCLI.Product_Id__c) ){
                if(eachCLI.Unit_of_Measure__c == 'Per Month'){
                    perMonthAutogenClisList.add(eachCLI);
                }
                else if(eachCLI.Unit_of_Measure__c == 'Assessments'|| eachCLI.Unit_of_Measure__c == 'Hour'){                        
                    othersAutogenClisList.add(eachCLI);
                }
            }
            
        }
        
        
        //Run through all the CLIs and MAP all the CLIs required for a project set
        for(Merge_Contract_Detail__c eachPerMonthCLI : perMonthAutogenClisList){            
            clisForProjectMap.put(eachPerMonthCLI.id,new Map<String,Merge_Contract_Detail__c>());
            clisForProjectMap.get(eachPerMonthCLI.id).put(eachPerMonthCLI.Unit_of_Measure__c,eachPerMonthCLI);
			String temp = ''+eachPerMonthCLI.Original_Contract_Id__c + String.valueOf(eachPerMonthCLI.Effective_Start_Date__c) + String.valueOf(eachPerMonthCLI.Effective_End_Date__c);
            cliMap.put(temp,eachPerMonthCLI.id);
        }

        for(Merge_Contract_Detail__c eachOthersCLI : othersAutogenClisList){
            
            String temp = '' + eachOthersCLI.Original_Contract_Id__c + String.valueOf(eachOthersCLI.Effective_Start_Date__c) + String.valueOf(eachOthersCLI.Effective_End_Date__c);
            Id key = cliMap.get(temp);
            if(clisForProjectMap.containsKey(key)){
                if(!clisForProjectMap.get(key).containsKey(eachOthersCLI.Unit_of_Measure__c) || clisForProjectMap.get(key).get(eachOthersCLI.Unit_of_Measure__c).lastmodifieddate < eachOthersCLI.lastmodifieddate){
                    clisForProjectMap.get(key).put(eachOthersCLI.Unit_of_Measure__c,eachOthersCLI);                        
                }
            }
        }

        Map<Id,List<Merge_Contract_Detail__c>> caseClisList = new Map<Id,List<Merge_Contract_Detail__c>>();
	    List<Merge_Contract_Detail__c> tempCliList = new List<Merge_Contract_Detail__c>();

        //if there are valid CLIs and cases, call the funtion to create projects
        if(!clisForProjectMap.isEmpty() && !cliNameToIdMap.isEmpty()){
        	//Run through all the cases and create project sets for each record in the clisForProjectMap and make an entry with the case id and project ids in ???
          	for(Case eachCase : casesList){
            	if(cliNameToIdMap.containsKey(eachCase.Contract_Detail__c) && clisForProjectMap.containsKey(cliNameToIdMap.get(eachCase.Contract_Detail__c))){
                  	caseClisList.put(eachCase.Id , clisForProjectMap.get(cliNameToIdMap.get(eachCase.Contract_Detail__c)).values());
              	}              
         	} 
        }

        CreateProjects(caseClisList,casesList);
        return autogenInstanceList;
    }

    //Three Methods of the implemented interface PSA_AutogenInterface : getContractDetails, getContractDetailsForUpsert, CreateProjects

    //Ignore this method
    public void getContractDetails(List<Merge_Contract_Header__c> ListContractScope,List<Merge_Contract_Detail__c> ListContractDetailstoCheck,List<Case> CasesCreated,List<Project_Case_Association__c> projectCases){}

    //Ignore this method
    public void CreateProjects(Map<Id,List<Merge_Contract_Detail__c>> caseClisList,List<Case> autogenCasesList)
    {
        
        Merge_Contract_Detail__c perMonthCli;
        Merge_Contract_Detail__c assessmentsCli;
        Merge_Contract_Detail__c hoursCli;

        Project_Case_Association__c pca;

        Integer noOfActiveMonths;
        Integer noOfTuningReports;
        Integer noOfBusinessAssessmentReports;
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
            assessmentsCli = NULL;
            hoursCli = NULL;

            if(caseClisList.containsKey(eachCase.Id)){
                for(Merge_Contract_Detail__c cli : caseClisList.get(eachCase.Id)){
                    if(cli.Unit_of_Measure__c == 'Per Month'){
                        perMonthCli = cli;
                    }
                    else if(cli.Unit_of_Measure__c == 'Assessments'){
                        assessmentsCli = cli;
                    }
                    else if(cli.Unit_of_Measure__c == 'Hour'){
                        hoursCli = cli;
                    }
                }
				//All projects failed
                if(perMonthCli == NULL){
                    failureProjects += '\nMonthly Tuning Reports\nPS Hours\nBusiness Assessment Reports';
                }
                else{       
                    //Create Monthly Tuning Reports project
                    //{
                    	noOfActiveMonths = PSA_AutoCreateProjectUtil.numberOfActiveMonths(perMonthCli.Effective_Start_Date__c,perMonthCli.Effective_End_Date__c);      
                        noOfTuningReports = noOfActiveMonths;
                        plannedHours = noOfTuningReports * 2;
                        budget = 0;
                        feeSchedule = 'Monthly Commit (MRR)';
                        pse__proj__c projectTemplate = projTemplates.get('GSS Products/mPulse Service - Monthly Tuning Reports - Project Template');
                        projectName = 'mPulse Service Monthly Tuning Reports';
                        
                        pse__proj__c project = new pse__proj__c();
                        project = PSA_AutoCreateProjectUtil.createProjectWithTemplate(projectName,projectTemplate,eachCase.Contract__c,perMonthCli,autogenPlus_mdt.ProjectCase_Name__c,perMonthCli.Id,perMonthCli.Id,perMonthCli.Id,feeSchedule,budget,plannedHours);                                     
                        project.Ongoing_Project_Recurring_Planned_Hour__c = 0;
                        project.pse__Planned_Hours__c = plannedHours;

                        //Generate ExtrenalId unique to project as perMonth CLI Id + configuration CLI Id
                        project.External_Id__c = String.valueOf(perMonthCli.Id) + String.valueOf(system.now());
                        autogenInstanceList.projectsForUpsert.add(project);

                        //Create Project to Case association
                        pca = PSA_AutoCreateProjectUtil.createProjectCaseAssociationRecordExternalid(project,eachCase.Id,eachCase.Contract__c,'mPulse-Monthly Tuning Reports',autogenPlus_mdt.ProjectCase_Name__c);
                        pca.Contract_Detail__c = perMonthCli.Id;
                        autogenInstanceList.pcaForUpsert.add(pca);
						successProjects += '\nMonthly Tuning Reports';
                	//}
                    
                    //Create Business Assessment Reports project
                    if(assessmentsCli != NULL){
                        noOfActiveMonths = PSA_AutoCreateProjectUtil.numberOfActiveMonths(assessmentsCli.Effective_Start_Date__c,assessmentsCli.Effective_End_Date__c);      
                        try{
                            noOfBusinessAssessmentReports = Integer.valueOf(Math.floor(noOfActiveMonths/6.0));
                        }
                        catch(Exception e){
                            noOfBusinessAssessmentReports = 0;
                        }
                        
                        plannedHours = noOfBusinessAssessmentReports * 20;
                        budget = 0;
                        feeSchedule = 'Annual Commit (ARR)';
                        projectTemplate = projTemplates.get('GSS Products/mPulse Service - Business Assessment Reports - Project Template');
                        projectName = 'mPulse Service Business Assessment Reports';
                        
                        project = new pse__proj__c();
                        project = PSA_AutoCreateProjectUtil.createProjectWithTemplate(projectName,projectTemplate,eachCase.Contract__c,assessmentsCli,'mPulse-BAR',assessmentsCli.Id,assessmentsCli.Id,perMonthCli.Id,feeSchedule,budget,plannedHours);                                     
                        project.Ongoing_Project_Recurring_Planned_Hour__c = 0;
                        project.pse__Planned_Hours__c = plannedHours;

                        //Generate ExtrenalId unique to project as perMonth CLI Id + configuration CLI Id
                        project.External_Id__c = String.valueOf(perMonthCli.Id) + String.valueOf(assessmentsCli.Id) + String.valueOf(system.now());
                        autogenInstanceList.projectsForUpsert.add(project);

                        //Create Project to Case association
                        pca = PSA_AutoCreateProjectUtil.createProjectCaseAssociationRecordExternalid(project,eachCase.Id,eachCase.Contract__c,'mPulse-Business Assessment Reports',autogenPlus_mdt.ProjectCase_Name__c);
                        pca.Contract_Detail__c = perMonthCli.Id;
                        autogenInstanceList.pcaForUpsert.add(pca);
						successProjects += '\nBusiness Assessment Reports';                        
                    }
                    else{
                        failureProjects += '\nBusiness Assessment Reports';
                    }
                    //Create PS Hours Project
                    if(hoursCli != NULL){
                        noOfActiveMonths = PSA_AutoCreateProjectUtil.numberOfActiveMonths(hoursCli.Effective_Start_Date__c,hoursCli.Effective_End_Date__c);      
                        
                        if(hoursCli.Billing_Duration__c != NULL){
                            if(hoursCli.Billing_Duration__c == 'Monthly'){
                                noOfMonthlsPerBillingPeriod = 1;
                            }
                            else if(hoursCli.Billing_Duration__c == 'Quarterly'){
                                noOfMonthlsPerBillingPeriod = 3;
                            }
                            else if(hoursCli.Billing_Duration__c == 'Annualy'){
                                noOfMonthlsPerBillingPeriod = 12;
                            }
                        }
                        else{
                            noOfMonthlsPerBillingPeriod = 0; 
                        }
                        try{
                            monthlyRecurringHours = hoursCli.Units_Low__c / noOfMonthlsPerBillingPeriod;
                        }
                        catch(Exception e){
                            monthlyRecurringHours = 0;
                        }
                        plannedHours = noOfActiveMonths * monthlyRecurringHours;
                        budget = 0;
                        feeSchedule = 'Quarterly Commit (MRR) w/ Overage';
                        projectTemplate = projTemplates.get('GSS Products/mPulse Service - PS Hours - Project Template');
                        projectName = 'mPulse Service-Hours';

                        project = new pse__proj__c();
                        project = PSA_AutoCreateProjectUtil.createProjectWithTemplate(projectName,projectTemplate,eachCase.Contract__c,hoursCli,'mPulse-PSH',hoursCli.Id,hoursCli.Id,perMonthCli.Id,feeSchedule,budget,plannedHours);                                     
						project.Ongoing_Project_Recurring_Planned_Hour__c = monthlyRecurringHours;
                        project.pse__Planned_Hours__c = plannedHours;

                        //Generate ExtrenalId unique to project as perMonth CLI Id + configuration CLI Id
                        project.External_Id__c = String.valueOf(perMonthCli.Id) + String.valueOf(hoursCli.Id) + String.valueOf(system.now());
                        autogenInstanceList.projectsForUpsert.add(project);

                        //Create Project to Case association
                        pca = PSA_AutoCreateProjectUtil.createProjectCaseAssociationRecordExternalid(project,eachCase.Id,eachCase.Contract__c,'mPulse- PS Hours',autogenPlus_mdt.ProjectCase_Name__c);
                        pca.Contract_Detail__c = perMonthCli.Id;
                        autogenInstanceList.pcaForUpsert.add(pca);
                        successProjects += '\nPS Hours';
                    }                    
                    else{
                        failureProjects += '\nPS Hours';
                    }
                }
                                
                String allError =   '\n\n<### PROJECTS NOT CREATED ###>\n\n'+
                                        'Monthly Tuning Report'+
                    					'\nBusiness Assessment Reports\n'+
                                        '\nPS Hours\n\n'+
                                        'Please note that due to contract set-up, none of the Salesforce projects have been automatically created.'+
                                        '\n\nPlease follow these guidelines on how to create the projects manually: https://ac.akamai.com/docs/DOC-70286';

                String partError =  '\n\nDue to contract set-up, only some projects could be automatically created.\n\n'+
                                        'Links to Projects can be found on the Project Case Association Related List section of the Case'+
                                        '\n\n<### PROJECTS SUCCESSFULLY CREATED ###>' + successProjects + 
                                        '\n\n<### PROJECTS NOT CREATED ###>' + failureProjects +
                                        '\n\nPlease follow these guidelines on project assignment & usage: https://ac.akamai.com/docs/DOC-70286';

                String allSuccess = '\n\nPlease note that all projects have been automatically created:'+
                                        '\nLinks to Projects can be found on the Project Case Association Related List section of the Case'+
                                        '\nPlease follow these guidelines on project assignment & usage: https://ac.akamai.com/docs/DOC-70286';


                if(eachCase.Description == null){
                   eachCase.Description = ''; 
                } 
                eachCase.Description = eachCase.Description.replaceAll(allError,'');
                
                //All projects creation succeeded
                if(String.isEmpty(failureProjects)){
                    eachCase.Description += allSuccess;
                }
                //All projects creation failed
                else if(String.isEmpty(successProjects)){ 
                    eachCase.Description += allError;
                }
                //Partial projects success, partial failure
                else{
                    eachCase.Description += partError;
                }
                autogenInstanceList.casesForUpsert.add(eachCase);
            }
        }

        //For all the projects create BUDGETS and use externalId to link
        
        //To create the budget with specific name -> create a map of project name to budget name. This is to be passed as the second parameter
        Map<String,String> ProjectNametoBudgetName = new Map<String,String>();
        ProjectNametoBudgetName.put('mPulse Service Monthly Tuning Reports','Monthly Tuning Report');
        ProjectNametoBudgetName.put('mPulse Service Business Assessment Reports','Business Assessment Reports');
        ProjectNametoBudgetName.put('mPulse Service-Hours','PS Hours');

        autogenInstanceList.budgetsForUpsert.addAll(PSA_AutoCreateProjectUtil.createBudgetWithNameExternalId(autogenInstanceList.projectsForUpsert,'Customer Purchase Order',ProjectNametoBudgetName));
        
        //For all the projects create all the MILESTONES and use externalId to link
		List<String> setPlannedhoursFromProject = new List<String>();
        setPlannedhoursFromProject.add('Business Assessment Report Preparation');
        autogenInstanceList.milestonesForUpsert.addAll(PSA_AutoCreateProjectUtil.createMilestonesExternalId(autogenInstanceList.projectsForUpsert,null,setPlannedhoursFromProject,null,null));   
    }
}