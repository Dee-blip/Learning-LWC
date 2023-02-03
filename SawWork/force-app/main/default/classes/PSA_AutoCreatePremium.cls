/*
Developer                        Date                        JIRA                            Changes
Suhas Jain                   12th Mar 2020               FFPSA-792            Created class for Premium 3.0 Autogens
*/


public class PSA_AutoCreatePremium implements PSA_AutogenInterface {

    public PSA_Autogen__mdt autogenPremium3mdt;
    public Map<String,pse__Proj__c> projTemplates;
    Set<String> productIdsSet = new Set<String>();
    public PSA_AutogenObjectList autogenInstanceList;
    Map<Id,Map<String,Merge_Contract_Detail__c>> clisForProjectMap = new Map<Id,Map<String,Merge_Contract_Detail__c>>();


    public PSA_AutoCreatePremium() {

        autogenInstanceList = new PSA_AutogenObjectList();
        projTemplates = new Map<String,pse__Proj__c>();
        autogenPremium3Mdt = [SELECT Id,Autogen_Usecase__c,Product_Id__c,ProjectCase_Name__c FROM PSA_Autogen__mdt WHERE Product_Name__c = 'PREMIUM3_0' limit 1];
        if(autogenPremium3Mdt.Product_Id__c != NULL)
        {
            productIdsSet.addAll(autogenPremium3Mdt.Product_Id__c.split(','));            
        }

    }

    public PSA_AutogenObjectList getContractDetailsForUpsert(List<Merge_Contract_Header__c> contractsList,List<Merge_Contract_Detail__c> contractDetailsList,List<Case> casesList,List<Project_Case_Association__c> pcaList, Map<String,pse__Proj__c> projTemplatesMap){

        Set<String> perMonthCLIs = new Set<String>();
        
        for(Case eachCase : casesList){

            //eachCase.Contract_Detail__c = eachCase.Contract_Detail__c.substring(0,15);
            perMonthCLIs.add(eachCase.Contract_Detail__c);

        }

        for (PSA_ProjectTemplates__mdt templates_mdt : [ SELECT Name__c,Parent_Autogen__c, Sub_Type__c, Type__c FROM PSA_ProjectTemplates__mdt WHERE Parent_Autogen__c = :autogenPremium3Mdt.id ORDER BY DeveloperName ] ) 
        {
            if(projTemplatesMap.containsKey(templates_mdt.Name__c))
            {
                if(projTemplatesMap.get(templates_mdt.Name__c).pse__Project_Type__c == templates_mdt.Type__c && projTemplatesMap.get(templates_mdt.Name__c).Project_Sub_Type__c == templates_mdt.Sub_Type__c)
                {
                    projTemplates.put(templates_mdt.Name__c,projTemplatesMap.get(templates_mdt.Name__c));
                }
            }  
        }

        System.debug('proj tem size :' + projTemplates.size() );

        if(projTemplates.size() != 6)
        {
            PSA_AutoCreateProjectUtil.sendErrorMails('Premium 3.0 Project Templates not found',''); 
            return autogenInstanceList;
        }

        List<Merge_Contract_Detail__c> perMonthAutogenClisList = new List<Merge_Contract_Detail__c>();
        List<Merge_Contract_Detail__c> othersAutogenClisList = new List<Merge_Contract_Detail__c>();
        
        Map<String,Id> cliNameToIdMap = new Map<String,Id>();

        for(Merge_Contract_Detail__c eachCLI : contractDetailsList)
        {
            cliNameToIdMap.put(eachCLI.Name, eachCLI.Id);

            Date thirtyFourDays = Date.today() + 34; 
            Date lastTwoDays = Date.today()-2;

            System.debug('start date :' + eachCLI.Effective_Start_Date__c );

            if( eachCLI.Effective_Start_Date__c < thirtyFourDays || eachCLI.createddate > lastTwoDays) {

                System.debug('inside date cond');

                System.debug('p id set : ' + productIdsSet + ' each prod id : ' + eachCLI.Product_Id__c );

                
                //segregate the PerMonth and Hour||Config Clis to different List[]
                if(eachCLI.Record_Type__c == 'Committed' && productIdsSet.contains(eachCLI.Product_Id__c)){

                    System.debug('rcrd type is cmtd ');
                    System.debug('other cli UOM :' + eachCLI.Unit_of_Measure__c);
                    System.debug('cli : ' + perMonthCLIs + ' and cli name : ' + eachCLI.Name );
                    
                    if(eachCLI.Unit_of_Measure__c == 'Per Month' && perMonthCLIs.contains(eachCLI.Name)){
                    //if(eachCLI.Unit_of_Measure__c == 'Per Month'){
                        System.debug('added per month cli ');
                        perMonthAutogenClisList.add(eachCLI);
                    }
                    else if(eachCLI.Unit_of_Measure__c == 'Reviews' || eachCLI.Unit_of_Measure__c == 'Hour' || eachCLI.Unit_of_Measure__c == 'Assessments' || eachCLI.Unit_of_Measure__c == 'Onsite Training Days' || eachCLI.Unit_of_Measure__c == 'Technical Advisory Hours' || eachCLI.Unit_of_Measure__c == 'Support Advocacy Hours'   ){ 
                        System.debug('adding to other clis' + eachCLI.Unit_of_Measure__c );
                        othersAutogenClisList.add(eachCLI);
                    }                                        
                } if( eachCLI.Record_Type__c == 'Usage' && productIdsSet.contains(eachCLI.Product_Id__c) && eachCLI.Unit_of_Measure__c == 'Hour'  )
                {
                    System.debug(' other cli Usage Record Type ');
                    othersAutogenClisList.add(eachCLI);
                }

            }
        }

        Map<String,Id> cliMap = new Map<String,Id>();


        // null checks for perMonthAutogenClisList and  othersAutogenClisList

        if ( perMonthAutogenClisList!= null && perMonthAutogenClisList.size() >0 ) {

            for(Merge_Contract_Detail__c eachPerMonthCLI : perMonthAutogenClisList){

                clisForProjectMap.put(eachPerMonthCLI.id,new Map<String,Merge_Contract_Detail__c>());
                clisForProjectMap.get(eachPerMonthCLI.id).put(eachPerMonthCLI.Unit_of_Measure__c,eachPerMonthCLI);
                
                //make a combination uniqe to find other Reviews/Hour CLIs that also has the matching columns
                String temp = ''+eachPerMonthCLI.Original_Contract_Id__c + String.valueOf(eachPerMonthCLI.Effective_Start_Date__c) + String.valueOf(eachPerMonthCLI.Effective_End_Date__c);
                cliMap.put(temp,eachPerMonthCLI.id);
                
            }
            
        }


        if (othersAutogenClisList != null && othersAutogenClisList.size() >0 ) {

            for(Merge_Contract_Detail__c eachOthersCLI : othersAutogenClisList){

                String temp = '' + eachOthersCLI.Original_Contract_Id__c + String.valueOf(eachOthersCLI.Effective_Start_Date__c) + String.valueOf(eachOthersCLI.Effective_End_Date__c);
                Id key = cliMap.get(temp);
    
                if(clisForProjectMap.containsKey(key)){
                    
                    if( eachOthersCLI.Unit_of_Measure__c != 'Hour' &&  (!clisForProjectMap.get(key).containsKey(eachOthersCLI.Unit_of_Measure__c) || clisForProjectMap.get(key).get(eachOthersCLI.Unit_of_Measure__c).lastmodifieddate < eachOthersCLI.lastmodifieddate) ){
                        clisForProjectMap.get(key).put(eachOthersCLI.Unit_of_Measure__c,eachOthersCLI);   
                        System.debug(' added other cli to map ' + clisForProjectMap.get(key) );
                    } else if( eachOthersCLI.Unit_of_Measure__c == 'Hour' && (!clisForProjectMap.get(key).containsKey(eachOthersCLI.Unit_of_Measure__c + ',' + eachOthersCLI.Product_Id__c) || clisForProjectMap.get(key).get(eachOthersCLI.Unit_of_Measure__c + ',' + eachOthersCLI.Product_Id__c).lastmodifieddate < eachOthersCLI.lastmodifieddate) ) {
                        clisForProjectMap.get(key).put(eachOthersCLI.Unit_of_Measure__c + ',' + eachOthersCLI.Product_Id__c ,eachOthersCLI);  
                    }
                } 
            }   
        }


        Map<Id,List<Merge_Contract_Detail__c>> caseClisList = new Map<Id,List<Merge_Contract_Detail__c>>();

        if(!clisForProjectMap.isEmpty() && !cliNameToIdMap.isEmpty()){

            System.debug('is enpty');
        
            //Run through all the cases and create project sets for each record in the clisForProjectMap and make an entry with the case id and project ids later in pca
            for(Case eachCase : casesList){

                System.debug(' chk crt : ' + (cliNameToIdMap.containsKey(eachCase.Contract_Detail__c) && clisForProjectMap.containsKey(cliNameToIdMap.get(eachCase.Contract_Detail__c))) );
                
                if(cliNameToIdMap.containsKey(eachCase.Contract_Detail__c) && clisForProjectMap.containsKey(cliNameToIdMap.get(eachCase.Contract_Detail__c)) ){

                    if (eachCase.Subject !=null && eachCase.Subject.contains('TPM::CSG')  ) {
                        continue;
                    }

                    System.debug('check if only one val : ' + clisForProjectMap.get(cliNameToIdMap.get(eachCase.Contract_Detail__c)).values() );
                    caseClisList.put(eachCase.Id , clisForProjectMap.get(cliNameToIdMap.get(eachCase.Contract_Detail__c)).values());

                }
            }   
        }

        System.debug('before method call : ' + caseClisList );
        System.debug('before method again : ' + casesList );

        CreateProjects(caseClisList,casesList);

        return autogenInstanceList;
    }

    public void getContractDetails(List<Merge_Contract_Header__c> ListContractScope,List<Merge_Contract_Detail__c> ListContractDetailstoCheck,List<Case> CasesCreated,List<Project_Case_Association__c> projectCases){}

    public void CreateProjects(Map<Id,List<Merge_Contract_Detail__c>> caseClisList,List<Case> autogenCasesList){
        
        Merge_Contract_Detail__c perMonthCli;
        Merge_Contract_Detail__c supportAdvocayCli;
        Merge_Contract_Detail__c hoursCli;
        Merge_Contract_Detail__c offHoursCli;
        Merge_Contract_Detail__c AssessmentsCli;
        Merge_Contract_Detail__c onSiteTrainingCli;
        Merge_Contract_Detail__c technicalAdvisoryCli;
        
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
            
            successProjects = '';
            failureProjects = '';   
            
            
            perMonthCli = NULL;
            supportAdvocayCli = NULL;
            hoursCli = NULL;
            offHoursCli = NULL;
            technicalAdvisoryCli = NULL;
            onSiteTrainingCli = NULL;
            AssessmentsCli = NULL;

            System.debug('not reach if :' + (eachCase.ParentId == NULL && caseClisList.containsKey(eachCase.Id)) );
            
            if(eachCase.ParentId == NULL && caseClisList.containsKey(eachCase.Id))
            {
                System.debug('debu ');
                System.debug('eachCase : '+ eachCase.Id);
                for(Merge_Contract_Detail__c cli : caseClisList.get(eachCase.Id))
                {
                    System.debug('insid for ' + cli.Unit_of_Measure__c );
                    if(cli.Unit_of_Measure__c == 'Per Month')
                    {
                        perMonthCli = cli;
                    }
                    if(cli.Unit_of_Measure__c == 'Assessments')
                    {
                        AssessmentsCli = cli;
                    }
                    if(cli.Unit_of_Measure__c == 'Support Advocacy Hours')
                    {
                        supportAdvocayCli = cli;
                    }
                    if(cli.Unit_of_Measure__c == 'Onsite Training Days')
                    {
                        onSiteTrainingCli = cli;
                    }
                    if (cli.Unit_of_Measure__c == 'Technical Advisory Hours' ) 
                    {
                        technicalAdvisoryCli = cli;
                    }
                    if (cli.Unit_of_Measure__c == 'Hour') {
                        if (cli.Product_Id__c == 'M-LC-165827' ) {
                            offHoursCli = cli;
                        } else if ( cli.Product_Id__c == 'M-LC-165819' ) { hoursCli = cli;  }
                    }
                }

                if(perMonthCli != NULL)
                {

                    System.debug('per month : ');
                            
                    noOfActiveMonths = PSA_AutoCreateProjectUtil.numberOfActiveMonths(perMonthCli.Effective_Start_Date__c,perMonthCli.Effective_End_Date__c);      
                    consultingPlannedHours = noOfActiveMonths * 12;
                    msrPlannedHours = noOfActiveMonths * 3;
                    noOfQBRReviews = noOfActiveMonths/3;
                    qbrPlannedHours = noOfQBRReviews * 3;
                    Integer monthsPerBillPeriod = 0;
                    pse__proj__c projectTemplate;
                    pse__proj__c project = new pse__proj__c();

                    plannedHours = (consultingPlannedHours + msrPlannedHours + qbrPlannedHours) == 0 ? 1 : (consultingPlannedHours + msrPlannedHours + qbrPlannedHours); 
                                        
                
                    if(supportAdvocayCli != NULL)
                    {

                        System.debug('supportAdvocayCli deb');
                        switch on supportAdvocayCli.Billing_Duration__c {
                            when  'Annual' { monthsPerBillPeriod = 12; }
                            when  'Quarterly' { monthsPerBillPeriod = 3; }
                            when  'Monthly' { monthsPerBillPeriod = 1; }
                            when else { monthsPerBillPeriod = 0; }
                        }

                        try{
                            monthlyRecurringHours = supportAdvocayCli.Units_Low__c/monthsPerBillPeriod;
                            System.debug('mothly rec hrs : '+ monthlyRecurringHours);
                        }
                        catch(Exception e){
                            monthlyRecurringHours = 0;
                        }

                        noOfActiveMonths = PSA_AutoCreateProjectUtil.numberOfActiveMonths(supportAdvocayCli.Effective_Start_Date__c,supportAdvocayCli.Effective_End_Date__c);      
                        System.debug('no activ month : ' + noOfActiveMonths + ' product : ' +  ( monthlyRecurringHours * noOfActiveMonths) );
                        plannedHours = monthlyRecurringHours * noOfActiveMonths;
                        
                        budget = 0;
                        feeSchedule = 'Quarterly Commit (MRR)';
                        projectTemplate = projTemplates.get('GSS Products/Premium 3.0 - Support Advocacy – Project Template');
                        //Number of Reviews is Units_Low__c
                        projectName = 'Premium 3.0 Support Advocacy';
                        
                        project = new pse__proj__c();
                        project = PSA_AutoCreateProjectUtil.createProjectWithTemplate(projectName,projectTemplate,eachCase.Contract__c,supportAdvocayCli,autogenPremium3mdt.ProjectCase_Name__c,supportAdvocayCli.Id,supportAdvocayCli.Id,perMonthCli.Id,feeSchedule,budget,plannedHours);                                     
                        project.Ongoing_Project_Recurring_Planned_Hour__c = monthlyRecurringHours;
                        project.pse__Planned_Hours__c = plannedHours;
                        project.Contract_Closed__c = 'Yes';
                        //Generate ExtrenalId unique to project as perMonth CLI Id + reviews CLI Id
                        project.External_Id__c = String.valueOf(perMonthCli.Id) + String.valueOf(supportAdvocayCli.Id) + String.valueOf(system.now());
                        
                        //Creatre Map of External Id to noOfTSRReviews
                        projectExternalIdToReviewsMap.put(project.External_Id__c,noOfTSRReviews);
                        System.debug('project.External_Id__c: '+project.External_Id__c );
                        
                        autogenInstanceList.projectsForUpsert.add(project);
                        

                        //Create Project to Case association
                        pca = PSA_AutoCreateProjectUtil.createProjectCaseAssociationRecordExternalid(project,eachCase.Id,eachCase.Contract__c,'Premium 3.0 - Support Advocacy',autogenPremium3mdt.ProjectCase_Name__c);
                        pca.Contract_Detail__c = perMonthCli.Id;
                        autogenInstanceList.pcaForUpsert.add(pca);
                        
                        successProjects += '\nSupport Advocacy';

                    }
                    else 
                    {
                        failureProjects += '\nSupport Advocacy';
                    }

                    if (hoursCli != NULL) {

                        System.debug('hours Cli');
                        switch on hoursCli.Billing_Duration__c {
                            when  'Annual' { monthsPerBillPeriod = 12; }
                            when  'Quarterly' { monthsPerBillPeriod = 3; }
                            when  'Monthly' { monthsPerBillPeriod = 1; }
                            when else { monthsPerBillPeriod = 0; }
                        }

                        try{
                            monthlyRecurringHours = hoursCli.Units_Low__c/monthsPerBillPeriod;
                            System.debug('mothly rec hrs : '+ monthlyRecurringHours);
                        }
                        catch(Exception e){
                            monthlyRecurringHours = 0;
                        }

                        noOfActiveMonths = PSA_AutoCreateProjectUtil.numberOfActiveMonths(hoursCli.Effective_Start_Date__c,hoursCli.Effective_End_Date__c);      
                        //noOfTSRReviews = ((technicalAdvisoryCli.Units_Low__c/12) * noOfActiveMonths).intValue();
                        System.debug('no activ month : ' + noOfActiveMonths + ' product : ' +  ( monthlyRecurringHours * noOfActiveMonths) );
                        plannedHours = monthlyRecurringHours * noOfActiveMonths;
                        
                        budget = 0;
                        feeSchedule = 'Quarterly Commit (MRR) w/ Overage';
                        projectTemplate = projTemplates.get('GSS Products/Premium 3.0 - PS Hours – Project Template');

                        projectName = 'Premium 3.0 PS Hours';
                        
                        project = new pse__proj__c();
                        project = PSA_AutoCreateProjectUtil.createProjectWithTemplate(projectName,projectTemplate,eachCase.Contract__c,hoursCli,autogenPremium3mdt.ProjectCase_Name__c,hoursCli.Id,hoursCli.Id,perMonthCli.Id,feeSchedule,budget,plannedHours);                                     
                        project.Ongoing_Project_Recurring_Planned_Hour__c = monthlyRecurringHours;
                        project.pse__Planned_Hours__c = plannedHours;
                        project.Contract_Closed__c = 'Yes';
                        //Generate ExtrenalId unique to project as perMonth CLI Id + reviews CLI Id
                        project.External_Id__c = String.valueOf(perMonthCli.Id) + String.valueOf(hoursCli.Id) + String.valueOf(system.now());
                        
                        //Creatre Map of External Id to noOfTSRReviews
                        projectExternalIdToReviewsMap.put(project.External_Id__c,noOfTSRReviews);
                        System.debug('project.External_Id__c: '+project.External_Id__c );
                        
                        autogenInstanceList.projectsForUpsert.add(project);
                        
                        //Create Project to Case association
                        pca = PSA_AutoCreateProjectUtil.createProjectCaseAssociationRecordExternalid(project,eachCase.Id,eachCase.Contract__c,'Premium 3.0- PS Hours',autogenPremium3mdt.ProjectCase_Name__c);
                        pca.Contract_Detail__c = perMonthCli.Id;
                        autogenInstanceList.pcaForUpsert.add(pca);
                        
                        successProjects += '\nPS Hours';

                    }
                    else 
                    {
                        failureProjects += '\nPS Hours ';
                    }

                    if (AssessmentsCli != NULL) {

                        System.debug('assessments Cli');
                        noOfActiveMonths = PSA_AutoCreateProjectUtil.numberOfActiveMonths(AssessmentsCli.Effective_Start_Date__c,AssessmentsCli.Effective_End_Date__c);      
                        plannedHours = (AssessmentsCli.Units_Low__c * 2.5 ) * noOfActiveMonths;
                        //plannedHours = noOfTSRReviews == 0 ? 1 : (noOfTSRReviews * 10); 
                        //plannedHours = noOfTSRReviews;
                        
                        budget = 0;
                        feeSchedule = 'Annual Commit (ARR)';
                        projectTemplate = projTemplates.get('GSS Products/Premium 3.0 - Technical Business Assessments – Template');

                        projectName = 'Premium 3.0 Technical Business Assessments';
                        
                        project = new pse__proj__c();
                        project = PSA_AutoCreateProjectUtil.createProjectWithTemplate(projectName,projectTemplate,eachCase.Contract__c,AssessmentsCli,autogenPremium3mdt.ProjectCase_Name__c,AssessmentsCli.Id,AssessmentsCli.Id,perMonthCli.Id,feeSchedule,budget,plannedHours);                                     
                        project.Ongoing_Project_Recurring_Planned_Hour__c = 0;
                        project.pse__Planned_Hours__c = plannedHours;
                        project.Contract_Closed__c = 'Yes';
                        //Generate ExtrenalId unique to project as perMonth CLI Id + reviews CLI Id
                        project.External_Id__c = String.valueOf(perMonthCli.Id) + String.valueOf(AssessmentsCli.Id) + String.valueOf(system.now());
                        
                        //Creatre Map of External Id to noOfTSRReviews
                        projectExternalIdToReviewsMap.put(project.External_Id__c,noOfTSRReviews);
                        System.debug('project.External_Id__c: '+project.External_Id__c );
                        
                        autogenInstanceList.projectsForUpsert.add(project);
                        

                        //Create Project to Case association
                        pca = PSA_AutoCreateProjectUtil.createProjectCaseAssociationRecordExternalid(project,eachCase.Id,eachCase.Contract__c,'Premium 3.0-Technical Business Assessments',autogenPremium3mdt.ProjectCase_Name__c);
                        pca.Contract_Detail__c = perMonthCli.Id;
                        autogenInstanceList.pcaForUpsert.add(pca);
                        
                        successProjects += '\nTechnical Business Assessments';

                    }
                    else 
                    {
                        failureProjects += '\nTechnical Business Assessments ';
                    }

                    if (technicalAdvisoryCli != NULL) {

                        System.debug('Technical Advisory Cli');

                        switch on technicalAdvisoryCli.Billing_Duration__c {
                            when  'Annual' { monthsPerBillPeriod = 12; }
                            when  'Quarterly' { monthsPerBillPeriod = 3; }
                            when  'Monthly' { monthsPerBillPeriod = 1; }
                            when else { monthsPerBillPeriod = 0; }
                        }

                        try{
                            monthlyRecurringHours = technicalAdvisoryCli.Units_Low__c/monthsPerBillPeriod;
                            System.debug('mothly rec hrs : '+ monthlyRecurringHours);
                        }
                        catch(Exception e){
                            monthlyRecurringHours = 0;
                        }

                        noOfActiveMonths = PSA_AutoCreateProjectUtil.numberOfActiveMonths(technicalAdvisoryCli.Effective_Start_Date__c,technicalAdvisoryCli.Effective_End_Date__c);      
                        //noOfTSRReviews = ((technicalAdvisoryCli.Units_Low__c/12) * noOfActiveMonths).intValue();
                        System.debug('no activ month : ' + noOfActiveMonths + ' product : ' +  ( monthlyRecurringHours * noOfActiveMonths) );
                        plannedHours = monthlyRecurringHours * noOfActiveMonths;
                        
                        budget = 0;
                        feeSchedule = 'Quarterly Commit (MRR) w/ Overage';
                        projectTemplate = projTemplates.get('GSS Products/Premium 3.0 - Technical Advisory – Project Template');

                        projectName = 'Premium 3.0 Technical Advisory';
                        
                        project = new pse__proj__c();
                        project = PSA_AutoCreateProjectUtil.createProjectWithTemplate(projectName,projectTemplate,eachCase.Contract__c,technicalAdvisoryCli,autogenPremium3mdt.ProjectCase_Name__c,technicalAdvisoryCli.Id,technicalAdvisoryCli.Id,perMonthCli.Id,feeSchedule,budget,plannedHours);                                     
                        project.Ongoing_Project_Recurring_Planned_Hour__c = monthlyRecurringHours;
                        project.pse__Planned_Hours__c = plannedHours;
                        project.Contract_Closed__c = 'Yes';
                        //Generate ExtrenalId unique to project as perMonth CLI Id + reviews CLI Id
                        project.External_Id__c = String.valueOf(perMonthCli.Id) + String.valueOf(technicalAdvisoryCli.Id) + String.valueOf(system.now());
                        
                        //Creatre Map of External Id to noOfTSRReviews
                        projectExternalIdToReviewsMap.put(project.External_Id__c,noOfTSRReviews);
                        System.debug('project.External_Id__c: '+project.External_Id__c );
                        
                        autogenInstanceList.projectsForUpsert.add(project);
                        

                        //Create Project to Case association
                        pca = PSA_AutoCreateProjectUtil.createProjectCaseAssociationRecordExternalid(project,eachCase.Id,eachCase.Contract__c,'Premium 3.0- Technical Advisory',autogenPremium3mdt.ProjectCase_Name__c);
                        pca.Contract_Detail__c = perMonthCli.Id;
                        autogenInstanceList.pcaForUpsert.add(pca);
                        
                        successProjects += '\nTechnical Advisory';

                    }
                    else 
                    {
                        failureProjects += '\nTechnical Advisory';
                    }


                    if (onSiteTrainingCli != NULL) {

                        System.debug('On Site training');

                        Date startDate = Date.newInstance(onSiteTrainingCli.Effective_Start_Date__c.year(), onSiteTrainingCli.Effective_Start_Date__c.month() , onSiteTrainingCli.Effective_Start_Date__c.day()  );
                        Date endDate = Date.newInstance(onSiteTrainingCli.Effective_End_Date__c.year(), onSiteTrainingCli.Effective_End_Date__c.month() , onSiteTrainingCli.Effective_End_Date__c.day()  );
                        Decimal activeYears;
                        Integer daysBTW = startDate.daysBetween(endDate);

                        try { 
                            activeYears = daysBTW/365.25;
                            System.debug('activ years : ' + activeYears );
                            activeYears = activeYears.round(System.RoundingMode.HALF_UP);
                            System.debug('check activ years again : ' + activeYears );
                        } 
                        catch (Exception e) {
                            activeYears = 0;
                        }
                        
                        plannedHours = onSiteTrainingCli.Units_Low__c * activeYears * 8;
                        
                        budget = 0;
                        feeSchedule = 'Annual Commit (ARR)';
                        projectTemplate = projTemplates.get('GSS Products/Premium 3.0 - Akamai University – Project Template');

                        projectName = 'Premium 3.0 Akamai University';
                        
                        project = new pse__proj__c();
                        project = PSA_AutoCreateProjectUtil.createProjectWithTemplate(projectName,projectTemplate,eachCase.Contract__c,onSiteTrainingCli,autogenPremium3mdt.ProjectCase_Name__c,onSiteTrainingCli.Id,onSiteTrainingCli.Id,perMonthCli.Id,feeSchedule,budget,plannedHours);                                     
                        project.Ongoing_Project_Recurring_Planned_Hour__c = 0;
                        project.pse__Planned_Hours__c = plannedHours;
                        project.Contract_Closed__c = 'Yes';
                        //Generate ExtrenalId unique to project as perMonth CLI Id + reviews CLI Id
                        project.External_Id__c = String.valueOf(perMonthCli.Id) + String.valueOf(onSiteTrainingCli.Id) + String.valueOf(system.now());
                        
                        //Creatre Map of External Id to noOfTSRReviews
                        projectExternalIdToReviewsMap.put(project.External_Id__c,noOfTSRReviews);
                        System.debug('project.External_Id__c: '+project.External_Id__c );
                        
                        autogenInstanceList.projectsForUpsert.add(project);
                        

                        //Create Project to Case association
                        pca = PSA_AutoCreateProjectUtil.createProjectCaseAssociationRecordExternalid(project,eachCase.Id,eachCase.Contract__c,'Premium 3.0-Akamai University',autogenPremium3mdt.ProjectCase_Name__c);
                        pca.Contract_Detail__c = perMonthCli.Id;
                        autogenInstanceList.pcaForUpsert.add(pca);
                        
                        successProjects += '\nAkamai University';

                    }
                    else 
                    {
                        failureProjects += '\nAkamai University';
                    }


                    if (offHoursCli != NULL) {

                        System.debug('On Site training');
                        //noOfActiveMonths = PSA_AutoCreateProjectUtil.numberOfActiveMonths(offHoursCli.Effective_Start_Date__c,offHoursCli.Effective_End_Date__c);      
                        //noOfTSRReviews = ((offHoursCli.Units_Low__c/12) * noOfActiveMonths).intValue();
                        //plannedHours = noOfTSRReviews == 0 ? 1 : (noOfTSRReviews * 10); 
                        
                        budget = 0;
                        feeSchedule = 'Time & Materials - No Cap';
                        projectTemplate = projTemplates.get('GSS Products/Premium 3.0 - Off-Hour Configuration Assistance – Project Template');

                        projectName = 'Premium 3.0 Off-Hour Configuration Assistance';
                        
                        project = new pse__proj__c();
                        project = PSA_AutoCreateProjectUtil.createProjectWithTemplate(projectName,projectTemplate,eachCase.Contract__c,offHoursCli,autogenPremium3mdt.ProjectCase_Name__c,offHoursCli.Id,offHoursCli.Id,perMonthCli.Id,feeSchedule,budget,plannedHours);                                     
                        project.Ongoing_Project_Recurring_Planned_Hour__c = 0;
                        project.pse__Planned_Hours__c = 1;
                        project.Contract_Closed__c = 'Yes';
                        //Generate ExtrenalId unique to project as perMonth CLI Id + reviews CLI Id
                        project.External_Id__c = String.valueOf(perMonthCli.Id) + String.valueOf(offHoursCli.Id) + String.valueOf(system.now());
                        
                        //Creatre Map of External Id to noOfTSRReviews
                        projectExternalIdToReviewsMap.put(project.External_Id__c,noOfTSRReviews);
                        System.debug('project.External_Id__c: '+project.External_Id__c );
                        
                        autogenInstanceList.projectsForUpsert.add(project);
                        

                        //Create Project to Case association
                        pca = PSA_AutoCreateProjectUtil.createProjectCaseAssociationRecordExternalid(project,eachCase.Id,eachCase.Contract__c,'Premium 3.0 Off-Hour Configuration Assistance',autogenPremium3mdt.ProjectCase_Name__c);
                        pca.Contract_Detail__c = perMonthCli.Id;
                        autogenInstanceList.pcaForUpsert.add(pca);
                        
                        successProjects += '\nPremium 3.0- Off-Hour Config Assistance Project';

                    }
                    else 
                    {
                        failureProjects += '\nPremium 3.0- Off-Hour Config Assistance Project';
                    }


                    
                }
                //All Projects failed
                else
                {
                    failureProjects += '\nSupport Advocacy\nPS Hours\nTechnical Business Assessments\nTechnical Advisory\nAkamai University\nPremium 3.0- Off-Hour Config Assistance Project';
                }
                
                //Update Case Description

                String allError =   '\n\n<### PROJECTS NOT CREATED ###>\n\n'+
                                        'Support Advocacy'+
                                        '\nPS Hours\n\n'+
                                        '\nTechnical Reviews\n\n'+
                                        '\nTechnical Advisory\n\n'+
                                        '\nAkamai University\n\n'+
                                        '\nPremium 3.0- Off-Hour Config Assistance Project\n\n'+
                                        '\nPlease refer to Premium Service and Support 3.0 customer onboarding steps located at: https://ac.akamai.com/docs/DOC-50914'+
                                        '\nPlease note that due to contract set-up, none of the Salesforce projects have been automatically created.'+
                                        '\n\nPlease follow these guidelines on how to create the projects manually: https://ac.akamai.com/docs/DOC-60729';

                String partError =  '\n\nDue to contract set-up, only some projects could be automatically created.\n\n'+
                                        'Links to Projects can be found on the Project Case Association Related List section of the Case'+
                                        '\nPlease refer to Premium Service and Support 3.0 customer onboarding steps located at: https://ac.akamai.com/docs/DOC-50914'+
                                        '\n\n<### PROJECTS SUCCESSFULLY CREATED ###>' + successProjects + 
                                        '\n\n<### PROJECTS NOT CREATED ###>' + failureProjects +
                                        '\n\nPlease follow these guidelines on project assignment & usage: https://ac.akamai.com/docs/DOC-60729';

                String allSuccess = '\n\nPlease refer to Premium Service and Support 3.0 customer onboarding steps located at: https://ac.akamai.com/docs/DOC-50914'+
                                        '\nPlease note that all projects have been automatically created:'+
                                        '\nLinks to Projects can be found on the Project Case Association Related List section of the Case'+
                                        '\nPlease follow these guidelines on project assignment & usage: https://ac.akamai.com/docs/DOC-60729';

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

        autogenInstanceList.milestonesForUpsert.addAll(PSA_AutoCreateProjectUtil.createMilestonesExternalId(autogenInstanceList.projectsForUpsert,null,null,null,null));
        
    }
}