/*
 * CR: FFPSA-266
 * Developer: Sharath Prasanna
 * Enhancement: Automated creation of RRS projects
 * Date: 24th October 2017
 * 
 */ 
public class PSA_AutoCreateRRS implements PSA_AutogenInterface
{
    public PSA_Autogen__mdt autogenRRS;
    public PSA_AutoCreateRRS() 
    {
        autogenRRS = [select Autogen_Usecase__c,Product_Id__c,ProjectCase_Name__c from PSA_Autogen__mdt where Product_Name__c = 'RRS' limit 1];
    }
    public PSA_AutogenObjectList getContractDetailsForUpsert(List<Merge_Contract_Header__c> ListContractScope,List<Merge_Contract_Detail__c> ListContractDetailstoCheck,List<Case> CasesCreated,List<Project_Case_Association__c> projectCases,Map<String,pse__Proj__c> templates)
    {
        return null;
    }    
    public void getContractDetails(List<Merge_Contract_Header__c> ListContractScope,List<Merge_Contract_Detail__c> ListContractDetailstoCheck,List<Case> CasesCreated,List<Project_Case_Association__c> projectCases)
    {
        Map<Id,List<Merge_Contract_Detail__c>> mapContractContractDetails = new Map<Id,List<Merge_Contract_Detail__c>>();


        List<Merge_Contract_Detail__c> contractDetailForRRS = new List<Merge_Contract_Detail__c>();

        List<Case> casesForRRS = new List<Case>();
        //This is the map of contract Id to case, this is used to not consider those cases that has associated projects
        Map<Id,Case> contractToCases = new Map<Id,Case>();
        Set<Id> ContractIds = new Set<Id>();
        //Loop over the cases and get all the cases with usecase value KONA-COB-WithoutKSD or KONA-COB-WithKSD
        for (Case caseToCheck: CasesCreated)
        {
            if(caseToCheck.Autogen_UseCase__c.contains(autogenRRS.Autogen_Usecase__c))
            {
                ContractIds.add(caseToCheck.Contract__c);
                contractToCases.put(caseToCheck.Contract__c,caseToCheck);
            }
        }

        //loop over the projectcases and get all the records that has the Automated_Project_Type__c as MKSD
        for (Project_Case_Association__c projectCaseToCheck: projectCases)
        {
            if(projectCaseToCheck.Automated_Project_Type__c == autogenRRS.ProjectCase_Name__c)
            {
                if(ContractIds.contains(projectCaseToCheck.Contract__c))
                {
                    ContractIds.remove(projectCaseToCheck.Contract__c);
                    contractToCases.remove(projectCaseToCheck.Contract__c);
                }
                
            }
        }

        if(contractToCases != null && contractToCases.size() > 0)
        {
            casesForRRS = contractToCases.values();  
        }
        
        //loop over the contract details and get all those contract details that satisfy the requirements for the MKSD project creation. that is, RecordType -> committed and Product_Id__c == 'M-LC-139829' and Unit of Measure -> Hour or Policies or Per Month or Reviews

        for(Merge_Contract_Detail__c detail: ListContractDetailstoCheck)
        {
            if(detail.Record_Type__c == 'Committed' && ((detail.Unit_of_Measure__c == 'Hour' && (detail.Billing_Duration__c == 'Monthly' || detail.Billing_Duration__c == 'Quarterly'))|| detail.Unit_of_Measure__c == 'Reviews' || detail.Unit_of_Measure__c == 'Per Month') && detail.Product_Id__c == autogenRRS.Product_Id__c && ContractIds.contains(detail.Original_Contract_Id__c))
            {

                   if(mapContractContractDetails == NULL || mapContractContractDetails.get(detail.Original_Contract_Id__c) == NULL)
                   {
                       mapContractContractDetails.put(detail.Original_Contract_Id__c, new List<Merge_Contract_Detail__c>{detail});
                      
                   }
                   else if(mapContractContractDetails.get(detail.Original_Contract_Id__c)!= NULL)
                   {
                        (mapContractContractDetails.get(detail.Original_Contract_Id__c)).add(detail);
                   }


            }
        }        

        //call the Util function to get the map of valid contract to list of valid contract details
       //if there are valid contract details, call the funtion to create projects
       if(mapContractContractDetails != null && mapContractContractDetails.size() > 0)
       {
            CreateProjects(mapContractContractDetails,casesForRRS); 
       }
       // if no details are found to conform to the RRS requirements, update all the RRS case descrption
       else if(casesForRRS != null && casesForRRS.size() > 0)
       {
            for (Case caseToUpdate: casesForRRS)
            {
                    if(ContractIds.contains(caseToUpdate.Contract__c))
                    {
                        if(caseToUpdate.description == null)
                        {
                            caseToUpdate.description = '';   
                        }

                       if(!(caseToUpdate.description.contains('PROJECTS NOT CREATED')))
                       {
                            caseToUpdate.Description += '\n\n<### PROJECTS NOT CREATED ###>\n\nPlease note that due to contract set-up Salesforce projects have not been automatically created.\n\nPlease follow these guidelines on how to create the projects:\nhttps://ac.akamai.com/docs/DOC-31295';
                       }

                    }

            }
            Database.Update(casesForRRS,False);
            
       }
    }

    public void CreateProjects(Map<Id,List<Merge_Contract_Detail__c>> mapContractContractDetails,List<Case> casesForRRS)
    {
        List<Database.UpsertResult> upsertResultRecords = new List<Database.UpsertResult>();
        List<Database.SaveResult> saveResultRecords = new List<Database.SaveResult>();
        List<pse__proj__c> ListProj2Insert = new List<pse__proj__c>();
        List<pse__Budget__c> ListBudget2Insert = new List<pse__Budget__c>();
        List<Id> ProjectInsertedIds = new List<Id>();

        List<pse__Proj__c> insertedProjects = new List<pse__Proj__c>();

        List<Case> caseSuccessfulUpdate = new List<Case>();
        List<pse__Budget__c> budgetsToUpdate = new List<pse__Budget__c>();
        List<Project_Case_Association__c> projectCases2Insert = new List<Project_Case_Association__c>();
        
        //Query for the Config template

        List<pse__proj__c> projectTemplatePSList = new List<pse__proj__c>();
        projectTemplatePSList = [SELECT Id,pse__Allow_Self_Staffing__c,Ongoing_Project_Recurring_Budget_Amt__c,Ongoing_Project_Recurring_Planned_Hour__c,
                             pse__Planned_Hours__c,pse__Allow_Timecards_Without_Assignment__c,pse__Is_Billable__c,pse__Time_Credited__c,
                             pse__Time_Excluded__c,Months_from_Start_to_End_Date__c,pse__Daily_Timecard_Notes_Required__c,
                             RecordtypeId,pse__Is_Active__c,pse__Project_Status__c,pse__Stage__c,pse__Practice__c,
                             Project_Sub_Type__c,pse__Project_Type__c FROM pse__proj__c 
                             WHERE pse__Project_Type__c = 'GSS Product' AND Project_Sub_Type__c = 'Readiness & Response Service' AND 
                             Name = 'GSS Products/Readiness & Response_Config Assist-Project Template' AND pse__Is_Template__c = TRUE LIMIT 1];
        if(projectTemplatePSList.size() != 1)
        {
            PSA_AutoCreateProjectUtil.sendErrorMails('GSS Products/Readiness & Response_Config Assist-Project Template',
                'The PS template with the name as GSS Products/Readiness & Response_Config Assist-Project Template, is either not found or more than one template with that name exists.');
            return;
        }

        pse__Proj__c projectTemplateConfig = projectTemplatePSList[0];

        //Query for the Service Request template
        projectTemplatePSList = [SELECT Id,pse__Allow_Self_Staffing__c,Ongoing_Project_Recurring_Budget_Amt__c,Ongoing_Project_Recurring_Planned_Hour__c,
                             pse__Planned_Hours__c,pse__Allow_Timecards_Without_Assignment__c,pse__Is_Billable__c,pse__Time_Credited__c,
                             pse__Time_Excluded__c,Months_from_Start_to_End_Date__c,pse__Daily_Timecard_Notes_Required__c,
                             RecordtypeId,pse__Is_Active__c,pse__Project_Status__c,pse__Stage__c,pse__Practice__c,
                             Project_Sub_Type__c,pse__Project_Type__c FROM pse__proj__c 
                             WHERE pse__Project_Type__c = 'GSS Product' AND Project_Sub_Type__c = 'Readiness & Response Service' AND 
                             Name = 'GSS Products/Readiness & Response Service (SSR)-Project Template' AND pse__Is_Template__c = TRUE LIMIT 1];

        if(projectTemplatePSList.size() != 1)
        {
            PSA_AutoCreateProjectUtil.sendErrorMails('GSS Products/Readiness & Response Service (SSR)-Project Template is not found or duplicates exist',
                'The PS template with the name as GSS Products/Readiness & Response Service (SSR)-Project Template, is either not found or more than one template with that name exists.');
            return;
        }

        pse__Proj__c projectTemplateSSR = projectTemplatePSList[0];

        //Query for the SEM template
        projectTemplatePSList = [SELECT Id,pse__Allow_Self_Staffing__c,Ongoing_Project_Recurring_Budget_Amt__c,Ongoing_Project_Recurring_Planned_Hour__c,
                             pse__Planned_Hours__c,pse__Allow_Timecards_Without_Assignment__c,pse__Is_Billable__c,pse__Time_Credited__c,
                             pse__Time_Excluded__c,Months_from_Start_to_End_Date__c,pse__Daily_Timecard_Notes_Required__c,
                             RecordtypeId,pse__Is_Active__c,pse__Project_Status__c,pse__Stage__c,pse__Practice__c,
                             Project_Sub_Type__c,pse__Project_Type__c FROM pse__proj__c 
                             WHERE pse__Project_Type__c = 'GSS Product' AND Project_Sub_Type__c = 'Readiness & Response Service' AND 
                             Name = 'GSS Products/Readiness & Response (SEM) - Project Template' AND pse__Is_Template__c = TRUE LIMIT 1];

        if(projectTemplatePSList.size() != 1)
        {
            PSA_AutoCreateProjectUtil.sendErrorMails('GSS Products/Readiness & Response (SEM) - Project Template is not found or duplicates exist','The PS template with the name as GSS Products/Readiness & Response (SEM) - Project Template, is either not found or more than one template with that name exists.');
            return;
        }


        pse__Proj__c projectTemplateSEM = projectTemplatePSList[0];        
        PSA_Settings__c psa_settings = PSA_Settings__c.getInstance('Project Manager');

        //loop through the List of Contracts
        for(Id cId:mapContractContractDetails.keySet())
        {
            system.debug('PSA Contracts to be checked:' + cId);
            system.debug((mapContractContractDetails.get(cId)).size());
            if(mapContractContractDetails.get(cId).size() == 3 )
            {
                
                //Create a map of Unit of Measure and the Index of the corresponding contract detail in the mapContractContractDetails.get list
                Map<String,Integer> UOMToIndex = new Map<String,Integer>();
                Integer index = 0;
                for(Merge_Contract_Detail__c contractDetail: mapContractContractDetails.get(cId))
                {

                    if(!UOMToIndex.containsKey(contractDetail.Unit_of_Measure__c))
                    {
                        UOMToIndex.put(contractDetail.Unit_of_Measure__c,index);
                        index++;    
                    }   
                    
                }
                //There should be 3 contract details with the unit of measure being Hour, Per Month and Policies. If the Number of contract details for the contract for MKSD is 4 and the 4th contract detail doesnt have Unit of Measure equal to Reviews, dont create the projects
                if(UOMToIndex.containsKey('Hour') && UOMToIndex.containsKey('Per Month') && UOMToIndex.containsKey('Reviews'))
                {  
                    Integer hour = UOMToIndex.get('Hour');
                    Integer review = UOMToIndex.get('Reviews');
                    Integer month = UOMToIndex.get('Per Month');
                    
                    Double monthlyRecurringHours;
                    Integer noOfActiveMonthsHour;
                    Integer noOfActiveMonthsReview;
                    Integer noOfActiveMonthsMonth;
                    Double pricePerMonth;
                    Double  technicalReviews;
                    Double ongoingRecurringBudgetAmount;
                    Double PlannedHours;                    

                    monthlyRecurringHours = PSA_AutoCreateProjectUtil.monthlyRecurringHours((mapContractContractDetails.get(cId))[hour]);
                    noOfActiveMonthsHour = PSA_AutoCreateProjectUtil.numberOfActiveMonths((mapContractContractDetails.get(cId))[hour].Effective_Start_Date__c,(mapContractContractDetails.get(cId))[hour].Effective_End_Date__c);

                    technicalReviews = PSA_AutoCreateProjectUtil.securityServiceReviews((mapContractContractDetails.get(cId))[review]);
                    noOfActiveMonthsReview = PSA_AutoCreateProjectUtil.numberOfActiveMonths((mapContractContractDetails.get(cId))[review].Effective_Start_Date__c,(mapContractContractDetails.get(cId))[review].Effective_End_Date__c);
                    noOfActiveMonthsMonth = PSA_AutoCreateProjectUtil.numberOfActiveMonths((mapContractContractDetails.get(cId))[month].Effective_Start_Date__c,(mapContractContractDetails.get(cId))[month].Effective_End_Date__c);
                    pricePerMonth = PSA_AutoCreateProjectUtil.pricePerMonth((mapContractContractDetails.get(cId))[month]);
                    
                    //THE FIRST PROJECT -> CONFIG
                    //The formula for the ongoingRecurringBudgetAmount can result in Exceptions -> divide by zero or zero by zero errors. in this case set the value to 0
                    try
                    {                        

                        ongoingRecurringBudgetAmount = ((monthlyRecurringHours * noOfActiveMonthsHour) / ((monthlyRecurringHours * noOfActiveMonthsHour) + (technicalReviews * 20.0) +  (7.5 * noOfActiveMonthsMonth) ) ) * (pricePerMonth) / noOfActiveMonthsHour;                        

                    }
                    catch(Exception e)
                    {
                        ongoingRecurringBudgetAmount = 0;
                    }

                    pse__proj__c project1 = new pse__proj__c();
                    String billingType;
                    if((mapContractContractDetails.get(cId))[hour].Billing_Duration__c == 'Quarterly')
                    {
                        billingType = 'Quarterly Commit (MRR)';
                    }
                    else if((mapContractContractDetails.get(cId))[hour].Billing_Duration__c == 'Monthly')
                    {
                        billingType = 'Monthly Commit (MRR)';
                    }
                    //Changes by Sharath Prasanna for CR 3588241: Removing the rounding off
                    //PlannedHours = PSA_AutoCreateProjectUtil.customRound(monthlyRecurringHours * noOfActiveMonthsHour);
                    PlannedHours = monthlyRecurringHours * noOfActiveMonthsHour;
                    //Planned Hours has to be 1 for non-internal projects
                    if(PlannedHours == 0.0)
                    {
                        PlannedHours = 1.0;   
                    }
                    //createProjectWithTemplate(name,template,contractId,detail,product,mrr, overrage,permonth,  billingType, ongoingRecurringBudgetAmount, plannedHours)

                    project1 = PSA_AutoCreateProjectUtil.createProjectWithTemplate('Readiness and Response Service_Config_Assistance',projectTemplateConfig,cId,(mapContractContractDetails.get(cId))[hour],autogenRRS.ProjectCase_Name__c,(mapContractContractDetails.get(cId))[hour].Id, (mapContractContractDetails.get(cId))[review].Id, (mapContractContractDetails.get(cId))[month].Id, billingType,ongoingRecurringBudgetAmount,PlannedHours);

                    //The ongoing recurring planned hours value is monthlyRecurringHours                     
                    project1.Ongoing_Project_Recurring_Planned_Hour__c = monthlyRecurringHours;

                    ListProj2Insert.add(project1);

                    //THE SECOND PROJECT ->  SERVICE REVIEW                
                    //The formula for the ongoingRecurringBudgetAmount can result in Exceptions -> divide by zero or zero by zero errors. in this case set the value to 0

                    try
                    {
                        ongoingRecurringBudgetAmount = ((technicalReviews * 20.0) / ((monthlyRecurringHours * noOfActiveMonthsHour) + (technicalReviews * 20.0) +  (7.5 * noOfActiveMonthsMonth) ) ) * (pricePerMonth) / noOfActiveMonthsReview;

                    }
                    catch(Exception e)
                    {
                        ongoingRecurringBudgetAmount = 0;
                    }

                    pse__proj__c project2 = new pse__proj__c();                   
                    Double technicalReviews20 = technicalReviews * 20.0;
                    //Changes by Sharath Prasanna for CR 3588241: removing the rounding off

                    //PlannedHours = PSA_AutoCreateProjectUtil.customRound(technicalReviews20);
                    PlannedHours = technicalReviews20;
                    if(PlannedHours == 0.0)
                    {
                        PlannedHours = 1.0;   
                    }

                    //createProjectWithTemplate(name,template,contractId,detail,product,mrr, overrage,permonth,  billingType, ongoingRecurringBudgetAmount, plannedHours)

                    project2 = PSA_AutoCreateProjectUtil.createProjectWithTemplate('Readiness and Response Service_Service_Review',projectTemplateSSR,cId,(mapContractContractDetails.get(cId))[review],autogenRRS.ProjectCase_Name__c,(mapContractContractDetails.get(cId))[hour].Id, (mapContractContractDetails.get(cId))[review].Id, (mapContractContractDetails.get(cId))[month].Id, 'One-Time: Fixed Price',ongoingRecurringBudgetAmount,PlannedHours); 

                    //The ongoing recurring planned hours value is monthlyRecurringHours                     
                    project2.Ongoing_Project_Recurring_Planned_Hour__c = 0;

                    ListProj2Insert.add(project2);
                    
                    //THE THIRD PROJECT -> SEM
                    //The formula for the ongoingRecurringBudgetAmount can result in Exceptions -> divide by zero or zero by zero errors. in this case set the value to 0
                    try
                    {
                        ongoingRecurringBudgetAmount = ((7.5 * noOfActiveMonthsMonth ) / ((monthlyRecurringHours * noOfActiveMonthsHour) + (technicalReviews * 20.0) +  (7.5 * noOfActiveMonthsMonth) ) ) * (pricePerMonth) / noOfActiveMonthsMonth;

                    }
                    catch(Exception e)
                    {
                        ongoingRecurringBudgetAmount = 0;
                    }

                    pse__proj__c project3 = new pse__proj__c();                   
                    PlannedHours = (7.5 * noOfActiveMonthsMonth) ;
                    if(PlannedHours == 0.0)
                    {
                        PlannedHours = 1.0;   
                    }

                    //createProjectWithTemplate(name,template,contractId,detail,product,mrr, overrage,permonth,  billingType, ongoingRecurringBudgetAmount, plannedHours)
                    project3 = PSA_AutoCreateProjectUtil.createProjectWithTemplate('Readiness and Response Service_SEM',projectTemplateSEM,cId,(mapContractContractDetails.get(cId))[month],autogenRRS.ProjectCase_Name__c,(mapContractContractDetails.get(cId))[hour].Id, (mapContractContractDetails.get(cId))[review].Id, (mapContractContractDetails.get(cId))[month].Id, 'Monthly Commit (MRR)',ongoingRecurringBudgetAmount,PlannedHours); 

                    //The ongoing recurring planned hours value                     
                    project3.Ongoing_Project_Recurring_Planned_Hour__c = 7.5;
                                       
                    ListProj2Insert.add(project3);
                    
                    
                }
            }
        }
        List<Database.UpsertResult> projectResults;
        try
        {
            
            upsertResultRecords = Database.Upsert(ListProj2Insert);
            PSA_AutoCreateProjectUtil.PopulateErrorTableForUpsert(upsertResultRecords, 'Project Creation');
        }
        Catch(Exception e)
        {
                PSA_AutoCreateProjectUtil.sendErrorMails('Project Creation Exception',e.getMessage());
                return;
        }

        insertedProjects = new List<pse__Proj__c>();
        for(Database.UpsertResult project: upsertResultRecords)
        {
              if (project.isSuccess()) 
              {
                    ProjectInsertedIds.add(project.getId());
              }
        }

        //query for the inserted projects
        insertedProjects = [select Id,Name,pse__Start_Date__c,pse__End_Date__c,Months_from_Start_to_End_Date__c,pse__Billing_Type__c,Project_Template__c,SMP_Contract__c,pse__Account__c,pse__Is_Billable__c,Ongoing_Project_Recurring_Budget_Amt__c,pse__Planned_Hours__c,SMP_Contract_Line_Item__c,SMP_Automated_Project__c from pse__proj__c where Id in :ProjectInsertedIds];
        Boolean successfulCase = False;
        Map<Id,List<pse__Proj__c>> contractToProjects = new Map<Id,List<pse__Proj__c>>();

        //Create a map of contract to list of projects -> 1 contract should be linked to 3 projects
        for(pse__proj__c p1:insertedProjects)
        {            
            if(!contractToProjects.containsKey(p1.SMP_Contract__c))
            {
                contractToProjects.put(p1.SMP_Contract__c,new List<pse__Proj__c>());    
            }            
            contractToProjects.get(p1.SMP_Contract__c).add(p1);

        }
        //Loop over the cases: create the Project_Case_Association__c record for each of the project created. if the project is not created for a case -> update the description 
        for(case c1:casesForRRS)
        {
           successfulCase = False;
             if(contractToProjects.containsKey(c1.contract__c))
             {  
                Project_Case_Association__c pca1;  
                for(pse__Proj__c p1: contractToProjects.get(c1.contract__c))
                {
                     if(p1.Name.contains('Config'))
                     {
                        pca1 = PSA_AutoCreateProjectUtil.createProjectCaseAssociationRecord(p1.Id,c1.Id,c1.contract__c,'Readiness and Response Service_Config_Assistance',autogenRRS.ProjectCase_Name__c);
                     }
                     else if(p1.Name.contains('Service_Review'))
                     {
                        pca1 = PSA_AutoCreateProjectUtil.createProjectCaseAssociationRecord(p1.Id,c1.Id,c1.contract__c,'Readiness and Response Service_Service_Review',autogenRRS.ProjectCase_Name__c);

                     }
                     else
                     {
                        pca1 = PSA_AutoCreateProjectUtil.createProjectCaseAssociationRecord(p1.Id,c1.Id,c1.contract__c,'Readiness and Response Service_SEM',autogenRRS.ProjectCase_Name__c);                      
                     }
                     projectCases2Insert.add(pca1);

                }
                 
                successfulCase = True;  
             }

           // Update the case description saying the projects were created or not created successfully.
           if(c1.Description == null)
           {
                c1.Description = '';
           }
          String errorMessage = '\n\n<### PROJECTS NOT CREATED ###>\n\nPlease note that due to contract set-up Salesforce projects have not been automatically created.\n\nPlease follow these guidelines on how to create the projects:\nhttps://ac.akamai.com/docs/DOC-31295';

          String successMessage = '\n\nPlease note that Salesforce projects have been automatically created:\nLinks to Projects can be found on the Project Case Association Related List section of the Case\n\nPlease follow these guidelines on project assignment & usage:\nhttps://ac.akamai.com/docs/DOC-9413';

           if(successfulCase)
           {
                     
                c1.Description = c1.Description.replace(errorMessage,'');              
                c1.Description += successMessage;
                  CaseSuccessfulUpdate.add(c1);                              
           }
           else if(!((c1.description.contains('PROJECTS NOT CREATED'))) && !((c1.description.contains('Please note that Salesforce projects have been automatically created:'))))
           {
                c1.Description += errorMessage;
                CaseSuccessfulUpdate.add(c1);
           }
        }

        //Insert the Project Case records.
        upsertResultRecords = Database.Upsert(projectCases2Insert,False);
        PSA_AutoCreateProjectUtil.PopulateErrorTableForUpsert(upsertResultRecords, 'ProjectCaseAssociation');

        //Update case description.
        saveResultRecords =Database.Update(CaseSuccessfulUpdate,False);
        PSA_AutoCreateProjectUtil.PopulateErrorTableForUpdate(saveResultRecords, CaseSuccessfulUpdate);
        

        ////To create the budget with specific name -> create a map of project name to budget name. This is to be passed as the second parameter
        Map<String,String> ProjectNametoBudgetName = new Map<String,String>();
        ProjectNametoBudgetName.put('Config','Readiness and Response Service_(CA)');
        ProjectNametoBudgetName.put('Service_Review','Readiness and Response Service_(SR)');
        ProjectNametoBudgetName.put('SEM','Readiness and Response Service_(SEM)');
         
         //createBudgetWithName(projects, type, ProjectNametoBudgetName)
        
        listBudget2Insert = PSA_AutoCreateProjectUtil.createBudgetWithName(insertedProjects,'Customer Purchase Order',ProjectNametoBudgetName);
        List<Database.UpsertResult> budgetResults = new List<Database.UpsertResult>();
        List<Id> budgetSuccesses = new List<Id>();
        try
        {
            budgetResults = Database.Upsert(listBudget2Insert,false);
        }
        catch(exception e)
        {
                PSA_AutoCreateProjectUtil.sendErrorMails('Budget Creation Exception',e.getMessage());
                return;
        }

        //create the project contract, project contract line item records. update the project -> contract closed : yes
       PSA_AutoCreateProjectUtil.insertPCLItems(insertedProjects);

       //If all milestones of a project should have a constant value, create a map of the project name to the constant value. Similarly for the planned hours, create a map of  the project name to the constant value. If the milestone amount has to be set from the project -> project.Ongoing_Project_Recurring_Budget_Amt__c * project.Months_from_Start_to_End_Date__c, create a list of the milestone names. If the milestone planned hours has to be set from the project, create a list of the milestone names -> milestone.pse__Planned_Hours__c = project.pse__Planned_Hours__c
       List<pse__Milestone__c> milestones = new List<pse__Milestone__c>();

       Map<String,Integer> setDefaultPlannedHoursProjectToHours = new Map<String,Integer>();
       setDefaultPlannedHoursProjectToHours.put('Service_Review',20);

       //createMilestones (List<pse__Proj__c> projects, List<String> setAmountFromProject,List<String> setPlannedhoursFromProject, Map<String,Double> setDefaultAmountProjectToAmount,Map<String,Integer> setDefaultPlannedHoursProjectToHours)
        milestones = PSA_AutoCreateProjectUtil.createMilestones(insertedProjects,null,null,null,setDefaultPlannedHoursProjectToHours);
       if(milestones != null && milestones.size() > 0)
       {   
           try
           {
                    upsertResultRecords = Database.Upsert(milestones,false);
                    PSA_AutoCreateProjectUtil.PopulateErrorTableForUpsert(upsertResultRecords, 'Milestones');

           }
           catch(Exception e)
           {
                PSA_AutoCreateProjectUtil.sendErrorMails('Milestone Creation Exception',e.getMessage());
                return;

           } 

       }



    }   
}