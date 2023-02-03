/******

Author: Sharath Ravishankar
Created Date: 24th April 2017
Description: This is a class as a part of autogenerating projects for PS-E product based on requirements. It has methods which are used by 
             PSA_AutogenProjectBatch class.


Jira : FFPSA-143

Developer               Date                Jira            Description
Sharath Ravishankar     22nd May 2017       FFPSA-232       Changed the logic in selection of each clis for bucket creation and 
                                                            calculations also for the same
*/
public class PSA_AutoCreatePSProject {

    public void getPSEContractDetails(List<Merge_Contract_Header__c> ListContractScope,List<Merge_Contract_Detail__c> ListContractDetailstoCheck,List<Case> CasesCreated,List<Project_Case_Association__c> projectCases)
    {
        Map<Id,List<Merge_Contract_Detail__c>> mapContractContractDetails = new Map<Id,List<Merge_Contract_Detail__c>>();

        List<Merge_Contract_Detail__c> contractDetailForPSE = new List<Merge_Contract_Detail__c>();
        //This is the map of contract Id to case, this is used to not consider those cases that has associated projects
        Map<Id,Case> contractToCases = new Map<Id,Case>();
        List<Case> casesForPSE = new List<Case>();
        Set<Id> ContractIds = new Set<Id>();
        //Loop over the cases and get all the cases with usecase value PSE
        for (Case caseToCheck: CasesCreated)
        {
            if(caseToCheck.Autogen_UseCase__c == 'PSE-COB') 
            {
                ContractIds.add(caseToCheck.Contract__c);
                contractToCases.put(caseToCheck.Contract__c,caseToCheck);
            }
        }

        //loop over the projectcases and get all the records that has the Automated_Project_Type__c as PS-E
        for (Project_Case_Association__c projectCaseToCheck: projectCases)
        {
            if(projectCaseToCheck.Automated_Project_Type__c == 'PS-E')
            {
                if(ContractIds.contains(projectCaseToCheck.Contract__c))
                {
                    ContractIds.remove(projectCaseToCheck.Contract__c);
                    contractToCases.remove(projectCaseToCheck.Contract__c);
                }
            }
        }

        if(contractToCases.size() > 0)
        {
            casesForPSE = contractToCases.values();
        }

        //loop over the contract details and get all those contract details that satisfy the requirements for the PSE project creation. that is, RecordType -> committed and Product_Id__c == 'M-LC-135915' and Unit of Measure -> 'Hour' or Per Month'
        //For 17.5 we got a new requirement, for not creating projects for the clis having effective start date in future.
        //Hence the added entry condition : detail.Effective_Start_Date__c<=system.today()
        for(Merge_Contract_Detail__c detail: ListContractDetailstoCheck)
        {
            if( detail.Product_Id__c == 'M-LC-135915' && detail.Effective_Start_Date__c<=system.today() &&
                 ContractIds.contains(detail.Original_Contract_Id__c) && ( ( detail.Unit_of_Measure__c == 'Hour' && ( detail.Record_Type__c == 'Committed' || detail.Record_Type__c == 'Usage' ) ) || 
                ( (detail.Unit_of_Measure__c == 'Per Month' || detail.Unit_of_Measure__c == 'Each') && detail.Record_Type__c == 'Committed') )  )
            //Changes by Sharath Ravishankar to include each cli for bucket project
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

       //if there are valid contract details, call the funtion to create projects
       if(mapContractContractDetails != null && mapContractContractDetails.size() > 0)
       {
             CreatePSEProjects(mapContractContractDetails,casesForPSE); 
       }

       //if no details are found to conform to the PSE requirements, update all the PSE case descrption
       else if(casesForPSE != null && casesForPSE.size() > 0)
       {
            for (Case caseToUpdate: casesForPSE)
            {
                    if(ContractIds.contains(caseToUpdate.Contract__c))
                    {
                        if(caseToUpdate.description == null)
                        {
                            caseToUpdate.description = '';   
                        }

                        if(!(caseToUpdate.description.contains('PROJECT NOT CREATED')))
                        {
                            caseToUpdate.Description += '\n\n<<### PROJECT NOT CREATED ###>\n\nPlease note that due to contract set-up the Salesforce project has not been automatically created.\n\nPlease follow these guidelines on how to create the projects:\nhttps://ac.akamai.com/docs/DOC-9413';
                        }
                    }

            }
            Database.Update(casesForPSE,False);
       }        
    }

    public void CreatePSEProjects(Map<Id,List<Merge_Contract_Detail__c>> mapContractContractDetails,List<Case> casesForPS)
    {
        List<Database.UpsertResult> upsertResultRecords = new List<Database.UpsertResult>();
        List<Database.SaveResult> saveResultRecords = new List<Database.SaveResult>();
        List<pse__proj__c> ListProj2Insert = new List<pse__proj__c>();
        List<pse__Budget__c> ListBudget2Insert = new List<pse__Budget__c>();
        List<Id> ProjectInsertedIds = new List<Id>();

        Map<Id,pse__Proj__c> insertedProjects = new Map<Id,pse__Proj__c>();

        List<Case> caseSuccessfulUpdate = new List<Case>();
        List<pse__Budget__c> budgetsToUpdate = new List<pse__Budget__c>();
        List<Project_Case_Association__c> projectCases2Insert = new List<Project_Case_Association__c>();
        
        //Query for the Professional Services/MRR - Project Template

        List<pse__proj__c> projectTemplatePSList = new List<pse__proj__c>();
        projectTemplatePSList = [SELECT Id,pse__Allow_Self_Staffing__c,Ongoing_Project_Recurring_Budget_Amt__c,Ongoing_Project_Recurring_Planned_Hour__c,
                             pse__Planned_Hours__c,pse__Allow_Timecards_Without_Assignment__c,pse__Is_Billable__c,pse__Time_Credited__c,
                             pse__Time_Excluded__c,Months_from_Start_to_End_Date__c,pse__Daily_Timecard_Notes_Required__c,
                             RecordtypeId,pse__Is_Active__c,pse__Project_Status__c,pse__Stage__c,pse__Practice__c,
                             Project_Sub_Type__c,pse__Project_Type__c FROM pse__proj__c 
                             WHERE pse__Project_Type__c = 'Professional Services' AND Project_Sub_Type__c = 'MRR' AND 
                             Name = 'Professional Services/MRR - Project Template' AND pse__Is_Template__c = TRUE LIMIT 1];
        if(projectTemplatePSList.size() != 1)
        {
            PSA_AutoCreateProjectUtil.sendErrorMails('Professional Services/MRR - Project Template is not found or duplicates exist',
                'The PS template with the name as Professional Services/MRR - Project Template, is either not found or more than one template with that name exists.');
            return;
        }

        pse__proj__c projTemplateMRR = projectTemplatePSList[0];

        projectTemplatePSList = [SELECT Id,pse__Allow_Self_Staffing__c,Ongoing_Project_Recurring_Budget_Amt__c,Ongoing_Project_Recurring_Planned_Hour__c,
                             pse__Planned_Hours__c,pse__Allow_Timecards_Without_Assignment__c,pse__Is_Billable__c,pse__Time_Credited__c,
                             pse__Time_Excluded__c,Months_from_Start_to_End_Date__c,pse__Daily_Timecard_Notes_Required__c,
                             RecordtypeId,pse__Is_Active__c,pse__Project_Status__c,pse__Stage__c,pse__Practice__c,
                             Project_Sub_Type__c,pse__Project_Type__c FROM pse__proj__c 
                             WHERE pse__Project_Type__c = 'Professional Services' AND Project_Sub_Type__c = 'Bucket' AND 
                             Name = 'Professional Services/Bucket - Project Template' AND pse__Is_Template__c = TRUE LIMIT 1];

        if(projectTemplatePSList.size() != 1)
        {
            PSA_AutoCreateProjectUtil.sendErrorMails('Professional Services/Bucket - Project Template is not found or duplicates exist',
                'The PS template with the name as Professional Services/Bucket - Project Template, is either not found or more than one template with that name exists.');
            return;
        }

        pse__proj__c projTemplateBucket = projectTemplatePSList[0];

        projectTemplatePSList = [SELECT Id,pse__Allow_Self_Staffing__c,Ongoing_Project_Recurring_Budget_Amt__c,Ongoing_Project_Recurring_Planned_Hour__c,
                             pse__Planned_Hours__c,pse__Allow_Timecards_Without_Assignment__c,pse__Is_Billable__c,pse__Time_Credited__c,
                             pse__Time_Excluded__c,Months_from_Start_to_End_Date__c,pse__Daily_Timecard_Notes_Required__c,
                             RecordtypeId,pse__Is_Active__c,pse__Project_Status__c,pse__Stage__c,pse__Practice__c,
                             Project_Sub_Type__c,pse__Project_Type__c FROM pse__proj__c 
                             WHERE pse__Project_Type__c = 'Professional Services' AND Project_Sub_Type__c = 'Time & Materials' AND 
                             Name = 'Professional Services/Time & Materials - Project Template' AND pse__Is_Template__c = TRUE LIMIT 1];

        if(projectTemplatePSList.size() != 1)
        {
            PSA_AutoCreateProjectUtil.sendErrorMails('Professional Services/Time & Materials - Project Template is not found or duplicates exist','The PS template with the name as Professional Services/Time & Materials - Project Template, is either not found or more than one template with that name exists.');
            return;
        }


        pse__proj__c projectTemplateTNM = projectTemplatePSList[0];        

        //loop through the List of Contracts
        for(Id cId:mapContractContractDetails.keySet())
        {
          //Integer clisize = ((mapContractContractDetails.get(cId)).size());
           
                //Create a map of Unit of Measure and the Index of the corresponding contract detail 
                //in the mapContractContractDetails.get list
                //Map<String,Integer> UOMToIndex = new Map<String,Integer>();

                //Map<String,List<Integer>> UOMGrpToIndexes = new Map<String,List<Integer>>();
                List<Integer> hourCommittedList = new List<Integer>();
                List<Integer> hourUsageList = new List<Integer>();
                //List<Integer> perMonth = new List<Integer>();
                Boolean perMonthChk = FALSE;
                Integer perMonthIndex = 0;
                //Changes by Sharath Ravishankar to include each cli for bucket project
                Boolean eachChk = FALSE;
                Integer eachIndex = 0;

                //List<String> UOMGrpList = new List<String>();
                Integer index = 0;
                
                for(Merge_Contract_Detail__c contractDetail: mapContractContractDetails.get(cId))
                {
                    if(contractDetail.Unit_of_Measure__c =='Hour')
                    {
                        if(contractDetail.Record_Type__c == 'Committed')
                        {
                            hourCommittedList.add(index);
                        }
                        else if( contractDetail.Record_Type__c == 'Usage' )
                        {
                            hourUsageList.add(index);
                        }
                    }

                    else if (contractDetail.Unit_of_Measure__c =='Per Month')
                    {
                        //Initially when the first per month cli is encountered
                        if( !perMonthChk )
                        {
                            perMonthIndex = index;
                            perMonthChk = TRUE;
                        }
                        else
                        {
                            //If there are more than one month clis, check whether it is updated 
                            //recently than the previously considered month cli
                            if(contractDetail.LastModifiedDate > mapContractContractDetails.get(cId)[perMonthIndex].LastModifiedDate)
                            {
                                perMonthIndex = index;
                            }
                        }   
                    }
                    else if(contractDetail.Unit_of_Measure__c =='Each')
                    {
                        if( !eachChk)
                        {
                            eachIndex = index;
                            eachChk = TRUE;
                        }
                        else
                        {
                            if(contractDetail.LastModifiedDate > mapContractContractDetails.get(cId)[eachIndex].LastModifiedDate)
                            {
                                eachIndex = index;
                            }   
                        }

                    }
                    index++;
                }

                Merge_Contract_Detail__c cliSelected;
                Merge_Contract_Detail__c cliSelected2;
                Integer noHours;
                Integer noOfActiveMonths;
                String feeSchedule;
                Double plannedHours; 
                Double monthlyRecurringHours;
                Double noMonthsPerBilling;
                Double packagePrice;
                Double onGngProject_RBAmt;
                Double usageRate;
                pse__proj__c proj;
                //MRR and Bucket project creation
                //No. of line items having UoM – “Hour” and Billing Duration = “Quarterly” or “Monthly ”= No. of MRR projects created.
                //No. of line items having UoM – “Hour” and Billing Duration < > “Quarterly” or “Monthly ”= No. of Bucket projects created.
                //If there are duplicates in UoM - "Per Month" -> The code picks latest modified among them for project creation
                //If there are duplicates in UoM - "Each" -> The code picks latest modified among them for project creation for bucket only
                //For Bucket projects, Uom - "Each" or "Per Month" is considered. If both are present latest modified each is picked for bucket only 
                if( hourCommittedList!=null && hourCommittedList.size() > 0 && ( perMonthChk || eachChk) )
                {
                    for(Integer cliIndex : hourCommittedList)
                    {
                        cliSelected = mapContractContractDetails.get(cId)[cliIndex];
                        noOfActiveMonths = PSA_AutoCreateProjectUtil.numberOfActiveMonths(cliSelected.Effective_Start_Date__c,cliSelected.Effective_End_Date__c); 
                           
                        if(perMonthChk)
                        {
                           cliSelected2 = mapContractContractDetails.get(cId)[perMonthIndex];
                           onGngProject_RBAmt = ( (cliSelected2.Unit_Price__c!=null )? cliSelected2.Unit_Price__c : 0);
                        }

                        proj = new pse__proj__c();
                        if(cliSelected.Units_Low__c == null)
                        {
                            cliSelected.Units_Low__c = 0;
                        }
                        //MRR project
                        if( (cliSelected.Billing_Duration__c == 'Monthly' || cliSelected.Billing_Duration__c == 'Quarterly') && perMonthChk )
                        {
                            if(cliSelected.Billing_Duration__c == 'Monthly')
                            {
                                noMonthsPerBilling = 1.0;
                                feeSchedule = 'Monthly Commit (MRR)';
                            }
                            else
                            {
                                noMonthsPerBilling = 3.0;
                                feeSchedule = 'Quarterly Commit (MRR)';
                            }
                            
                            plannedHours = cliSelected.Units_Low__c / noMonthsPerBilling * noOfActiveMonths;
                            //planned hours can't be null for MRR projects
                            if(plannedHours == 0)
                            {
                                plannedHours = 1.0;
                            }
                            
                            //createProjectWithTemplate(name,template,contractId,detail,product,mrr, overrage,permonth,  billingType, ongoingRecurringBudgetAmount, plannedHours)
                            proj = PSA_AutoCreateProjectUtil.createProjectWithTemplate('Professional Services - Enterprise_MRR',projTemplateMRR,cId,cliSelected,'PS-E',cliSelected.Id, cliSelected.Id, cliSelected2.Id, feeSchedule,onGngProject_RBAmt,plannedHours);                    
                            //Ongoing project recurring planned hours is set to 0 and the PSA SMP2.0 Set Ongoing Recurring Hours (Workflow rule)
                            //sets it to appropriate value. 
                            ListProj2Insert.add(proj);
                        }
                        
                        //Bucket Project
                        else if(cliSelected.Billing_Duration__c != 'Monthly' && cliSelected.Billing_Duration__c != 'Quarterly')
                        {
                            feeSchedule = 'One-Time: Fixed Price';

                            plannedHours = cliSelected.Units_Low__c;

                            if(plannedHours == 0)
                            {
                                plannedHours = 1.0;
                            } 

                            //Bucket project with each cli
                            if( eachChk )
                            {
                                cliSelected2 = mapContractContractDetails.get( cId )[eachIndex];
                                
                                if(noOfActiveMonths == 0 || cliSelected2.Unit_Price__c == null)
                                {
                                    onGngProject_RBAmt = 0;
                                }
                                else
                                {
                                    onGngProject_RBAmt = cliSelected2.Unit_Price__c / noOfActiveMonths;
                                }
                                
                            }                           
                            //createProjectWithTemplate(name,template,contractId,detail,product,mrr, overrage,permonth,  billingType, ongoingRecurringBudgetAmount, plannedHours)
                            proj = PSA_AutoCreateProjectUtil.createProjectWithTemplate('Professional Services - Enterprise_Bucket',projTemplateBucket,cId,cliSelected,'PS-E',cliSelected.Id, cliSelected.Id, cliSelected2.Id, feeSchedule,onGngProject_RBAmt,plannedHours);                    
                            
                            ListProj2Insert.add(proj);    
                        }
                    }
                }
                //Time & materials project
                //No. of line items having UoM – “Hour” and Record type - "Usage" = No. of TnM projects created.
                if(hourUsageList!=null && hourUsageList.size() > 0)
                {
                    for(Integer cliIndex : hourUsageList)
                    {
                        cliSelected = mapContractContractDetails.get(cId)[cliIndex];
                        noOfActiveMonths = PSA_AutoCreateProjectUtil.numberOfActiveMonths(cliSelected.Effective_Start_Date__c,cliSelected.Effective_End_Date__c); 
                        feeSchedule = 'Time & Materials';

                        if(cliSelected.Units_High__c == null)
                        {
                            //T&M projects can have planned hours as 0
                            plannedHours = 0;
                        }
                        else if(cliSelected.Billing_Duration__c == 'Monthly')
                        {
                            plannedHours = cliSelected.Units_High__c * PSA_AutoCreateProjectUtil.customRound(noOfActiveMonths);
                        }
                        else if(cliSelected.Billing_Duration__c == 'Quarterly')
                        {
                            plannedHours = cliSelected.Units_High__c * PSA_AutoCreateProjectUtil.customRound( Double.valueOf(noOfActiveMonths / 3.0 ));
                        }
                        else if(cliSelected.Billing_Duration__c == 'Annual')
                        {
                            plannedHours = cliSelected.Units_High__c * PSA_AutoCreateProjectUtil.customRound( Double.valueOf(noOfActiveMonths / 12.0 ));
                        }
                        else
                        {
                            plannedHours = cliSelected.Units_High__c;
                        }

                        onGngProject_RBAmt = 0;
                        proj = new pse__proj__c(); 
                        //createProjectWithTemplate(name,template,contractId,detail,product,mrr, overrage,permonth,  billingType, ongoingRecurringBudgetAmount, plannedHours)
                        proj = PSA_AutoCreateProjectUtil.createProjectWithTemplate('Professional Services-Enterprise_Time & Material',projectTemplateTNM,cId,cliSelected,'PS-E',cliSelected.Id, cliSelected.Id, cliSelected.Id, feeSchedule,onGngProject_RBAmt,plannedHours);                    
                        ListProj2Insert.add(proj);
                    }
                }
                  
        } 
        upsertResultRecords = Database.Upsert(ListProj2Insert);
        PSA_AutoCreateProjectUtil.PopulateErrorTableForUpsert(upsertResultRecords, 'Project Creation for PS-E');

        //insertedProjects = new List<pse__Proj__c>();
        for(Database.UpsertResult project: upsertResultRecords)
        {
              if (project.isSuccess()) 
              {
                    ProjectInsertedIds.add(project.getId());
              }
        }
        
        //query for the inserted projects
        insertedProjects = new Map<id,pse__Proj__c>([select Id,Name,pse__Start_Date__c,pse__End_Date__c,Months_from_Start_to_End_Date__c,pse__Billing_Type__c,Project_Template__c,SMP_Contract__c,pse__Account__c,pse__Is_Billable__c,Ongoing_Project_Recurring_Budget_Amt__c,pse__Planned_Hours__c,SMP_Contract_Line_Item__c,SMP_Automated_Project__c,PCLI_MRR1__r.Units_Low__c,PCLI_MRR1__r.Unit_Price__c,PCLI_PerMonth1__r.Effective_Start_Date__c,PCLI_PerMonth1__r.Effective_End_Date__c from pse__proj__c where Id in :ProjectInsertedIds]);
        Boolean successfulCase = False;
        Map<Id,List<pse__Proj__c>> contractToProjectLists = new Map<Id,List<pse__Proj__c>>();

        //Create a map of contract to project -> 1 contract can be linked to any number of projects
        
        for(pse__proj__c p1:insertedProjects.values())
        {  
            if(!contractToProjectLists.containsKey(p1.SMP_Contract__c))
            {
                contractToProjectLists.put(p1.SMP_Contract__c,new List<pse__Proj__c>());    
            }            
            contractToProjectLists.get(p1.SMP_Contract__c).add(p1);
        }

        //Loop over the cases: create the Project_Case_Association__c record for the project created. if the project is not created for a case -> update the description 
        for(case c1:casesForPS)
        {
            successfulCase = False;
            if(contractToProjectLists.containsKey(c1.contract__c))
             {  
                Project_Case_Association__c pca1;  
                for(pse__Proj__c p1: contractToProjectLists.get(c1.contract__c))
                {
                     if(p1.Name.contains('Professional Services - Enterprise_MRR'))
                    {
                        pca1 = PSA_AutoCreateProjectUtil.createProjectCaseAssociationRecord(p1.Id,c1.Id,c1.contract__c,'Professional Services - Enterprise_MRR','PS-E');
                    } 
                    else if(p1.Name.contains('Professional Services - Enterprise_Bucket')) 
                    {
                        pca1 = PSA_AutoCreateProjectUtil.createProjectCaseAssociationRecord(p1.Id,c1.Id,c1.contract__c,'Professional Services - Enterprise_Bucket','PS-E');
                    } 
                    else if(p1.Name.contains('Professional Services-Enterprise_Time & Material'))
                    {
                        pca1 = PSA_AutoCreateProjectUtil.createProjectCaseAssociationRecord(p1.Id,c1.Id,c1.contract__c,'Professional Services - Enterprise_T&M','PS-E');
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
            String errorMessage =   '\n\n<<### PROJECT NOT CREATED ###>\n\n'+
                                    'Please note that due to contract set-up the Salesforce project has not been automatically created.'+
                                    '\n\nPlease follow these guidelines on how to create the projects:\nhttps://ac.akamai.com/docs/DOC-9413';

            String successMessage = '\n\nPlease note that a Salesforce project has been automatically created:\n'+
                                     'Link to the Project can be found on the Project Related List section of the Case\n\n'+
                                     'Please follow these guidelines on project assignment & usage:\nhttps://ac.akamai.com/docs/DOC-9413';

            if(successfulCase)
            {
                c1.Description = c1.Description.replace(errorMessage,'');              
                c1.Description += successMessage;
                caseSuccessfulUpdate.add(c1);                              
            }
            else if( !(c1.description.contains('PROJECT NOT CREATED')) )
            {
                c1.Description += errorMessage;
                caseSuccessfulUpdate.add(c1);
            }
        }

        //Insert the Project Case records.
        upsertResultRecords = Database.Upsert(projectCases2Insert,False);
        //Sending the caption ProjectCaseAssociation Upsert during PS-E Autogen for better interpretation of errors.
        PSA_AutoCreateProjectUtil.PopulateErrorTableForUpsert(upsertResultRecords, 'ProjectCaseAssociation Upsert during PS-E Autogen');

        //Update case description.
        saveResultRecords = Database.Update(caseSuccessfulUpdate,False);
        PSA_AutoCreateProjectUtil.PopulateErrorTableForUpdate(saveResultRecords, CaseSuccessfulUpdate);
        
        ////To create the budget with specific name -> create a map of project name to budget name. This is to be passed as the second parameter
        Map<String,String> ProjectNametoBudgetName = new Map<String,String>();
        ProjectNametoBudgetName.put('Professional Services - Enterprise_MRR','PS-E_MRR');
        ProjectNametoBudgetName.put('Professional Services - Enterprise_Bucket','PS-E_Bucket');
        ProjectNametoBudgetName.put('Professional Services-Enterprise_Time & Material','PS-E_T&M');

         
        //createBudgetWithName(projects, type, ProjectNametoBudgetName)
        listBudget2Insert = PSA_AutoCreateProjectUtil.createBudgetWithName(insertedProjects.values(),'Customer Purchase Order',ProjectNametoBudgetName);

        // change the noofactivemonths for the budget and also the pse amount calculation.
        if(listBudget2Insert!=null || listBudget2Insert.size() > 0 )
        {
            for( pse__Budget__c budg : listBudget2Insert )
            {
                if(budg.Name == 'PS-E_T&M')
                {
                    pse__Proj__c p = insertedProjects.get(budg.pse__Project__c);
                    //for time n materials, the budget amount = product cap (which is calculated in planned hours)* usage rate (hour cli's unit price) 
                    if(p.PCLI_MRR1__r.Unit_Price__c == null)
                    {
                        p.PCLI_MRR1__r.Unit_Price__c = 0;
                    }
                    budg.pse__Amount__c = p.pse__Planned_Hours__c * p.PCLI_MRR1__r.Unit_Price__c;
                }
                //pse__Proj__c p = insertedProjects.get(budg.pse__Project__c);
                //Integer noOfActMonths = PSA_AutoCreateProjectUtil.numberOfActiveMonths(p.PCLI_PerMonth1__r.Effective_Start_Date__c,p.PCLI_PerMonth1__r.Effective_End_Date__c);
                //budg.pse__Amount__c = p.Ongoing_Project_Recurring_Budget_Amt__c * noOfActMonths;

            }
        }
        
        List<Database.UpsertResult> budgetResults = new List<Database.UpsertResult>();
        List<Id> budgetSuccesses = new List<Id>();
        budgetResults = Database.Upsert(listBudget2Insert,false);

        //create the project contract, project contract line item records. update the project -> contract closed : yes
       PSA_AutoCreateProjectUtil.insertPCLItems(insertedProjects.values());

       //If all milestones of a project should have a constant value, create a map of the project name to the constant value. Similarly for the planned hours, create a map of  the project name to the constant value. 
       //If the milestone amount has to be set from the project -> project.Ongoing_Project_Recurring_Budget_Amt__c * project.Months_from_Start_to_End_Date__c, create a list of the milestone names.
       //If the milestone planned hours has to be set from the project, create a list of the milestone names -> milestone.pse__Planned_Hours__c = project.pse__Planned_Hours__c
       List<pse__Milestone__c> milestones = new List<pse__Milestone__c>();

       //createMilestones (List<pse__Proj__c> projects, List<String> setAmountFromProject,List<String> setPlannedhoursFromProject, Map<String,Double> setDefaultAmountProjectToAmount,Map<String,Integer> setDefaultPlannedHoursProjectToHours)
        milestones = PSA_AutoCreateProjectUtil.createMilestones(insertedProjects.values(),null,null,null,null);
        upsertResultRecords = Database.Upsert(milestones,false);
        //Passing Milestones Creation during PS-E Autogen as caption helping the debug process.
        PSA_AutoCreateProjectUtil.PopulateErrorTableForUpsert(upsertResultRecords, 'Milestones Creation during PS-E Autogen');
       

    }
}