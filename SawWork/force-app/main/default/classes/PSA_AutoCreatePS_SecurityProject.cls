/*
 * CR: FFPSA-271
 * Developer: Sharath Prasanna
 * Enhancement: Automated creation of projects for PSS: 
 * Date: 27th March 2018
 * 
 */ 
public class PSA_AutoCreatePS_SecurityProject implements PSA_AutogenInterface
{
    public PSA_Autogen__mdt autogenPSS;
    public PSA_AutogenObjectList autogenPSSList;
    public List<pse__Proj__c> projTemplates;
    public PSA_AutoCreatePS_SecurityProject() 
    {
        autogenPSS = [select Autogen_Usecase__c,Product_Id__c,ProjectCase_Name__c from PSA_Autogen__mdt where Product_Name__c = 'PSS' limit 1];
        autogenPSSList = new PSA_AutogenObjectList();
        projTemplates = new List<pse__Proj__c>();
    }
    public void getContractDetails(List<Merge_Contract_Header__c> ListContractScope,List<Merge_Contract_Detail__c> ListContractDetailstoCheck,List<Case> CasesCreated,List<Project_Case_Association__c> projectCases)
    {

    }

    public PSA_AutogenObjectList getContractDetailsForUpsert(List<Merge_Contract_Header__c> ListContractScope,List<Merge_Contract_Detail__c> ListContractDetailstoCheck,List<Case> CasesCreated,List<Project_Case_Association__c> projectCases, Map<String,pse__Proj__c> projTemplatesMap)
    {
        for (PSA_ProjectTemplates__mdt templates :[select Name__c,Parent_Autogen__c, Sub_Type__c, Type__c from PSA_ProjectTemplates__mdt where Parent_Autogen__c = :autogenPSS.id order by DeveloperName])
        {
            if(projTemplatesMap.containsKey(templates.Name__c) && projTemplatesMap.get(templates.Name__c).pse__Project_Type__c == templates.Type__c && projTemplatesMap.get(templates.Name__c).Project_Sub_Type__c == templates.Sub_Type__c)
            {
                projTemplates.add(projTemplatesMap.get(templates.Name__c));
            }
        }

        Map<Id,List<Merge_Contract_Detail__c>> mapContractContractDetails = new Map<Id,List<Merge_Contract_Detail__c>>();

        List<Merge_Contract_Detail__c> contractDetailForPSS = new List<Merge_Contract_Detail__c>();
        //This is the map of contract Id to case, this is used to not consider those cases that has associated projects
        Map<Id,Case> contractToCases = new Map<Id,Case>();
        List<Case> casesForPSS = new List<Case>();
        Set<Id> ContractIds = new Set<Id>();
        //Loop over the cases and get all the cases with usecase value PSS
        for (Case caseToCheck: CasesCreated)
        {
            if(caseToCheck.Autogen_UseCase__c == autogenPSS.Autogen_Usecase__c) 
            {
                ContractIds.add(caseToCheck.Contract__c);
                contractToCases.put(caseToCheck.Contract__c,caseToCheck);
            }
        }

        //loop over the projectcases and get all the records that has the Automated_Project_Type__c as PSS
        for (Project_Case_Association__c projectCaseToCheck: projectCases)
        {
            if(projectCaseToCheck.Automated_Project_Type__c == autogenPSS.ProjectCase_Name__c)
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
            casesForPSS = contractToCases.values();
        }

        //loop over the contract details and get all those contract details that satisfy the requirements for the PSS project creation. UOM -> Hour (recordtype -> Usage or Committed) or Per Month or Each; The effective Start date should not be in the future
        for(Merge_Contract_Detail__c detail: ListContractDetailstoCheck)
        {
            if( detail.Product_Id__c == autogenPSS.Product_Id__c && detail.Effective_Start_Date__c<=system.today() &&
                 ContractIds.contains(detail.Original_Contract_Id__c) && ( ( detail.Unit_of_Measure__c == 'Hour' && ( detail.Record_Type__c == 'Committed' || detail.Record_Type__c == 'Usage' ) ) || 
                ( (detail.Unit_of_Measure__c == 'Per Month' || detail.Unit_of_Measure__c == 'Each') && detail.Record_Type__c == 'Committed') )  )
            {

                   if(!mapContractContractDetails.containsKey(detail.Original_Contract_Id__c))
                   {
                       mapContractContractDetails.put(detail.Original_Contract_Id__c, new List<Merge_Contract_Detail__c>{detail});
                   }
                   else
                   {
                        (mapContractContractDetails.get(detail.Original_Contract_Id__c)).add(detail);
                   }
            }
        }        

       //if there are valid contract details, call the funtion to create projects
       if(!mapContractContractDetails.isEmpty())
       {
             CreateProjects(mapContractContractDetails,casesForPSS); 
       }

       //if no details are found to conform to the PSS requirements, update all the PSS case descrption
       else if(casesForPSS != null && casesForPSS.size() > 0)
       {
            for (Case caseToUpdate: casesForPSS)
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
            autogenPSSList.casesForUpsert.addAll(casesForPSS);
       }        

       return autogenPSSList;
    }
    public void CreateProjects(Map<Id,List<Merge_Contract_Detail__c>> mapContractContractDetails,List<Case> cases)
    {
        List<pse__proj__c> ListProj2Insert = new List<pse__proj__c>();
        List<pse__Budget__c> ListBudget2Insert = new List<pse__Budget__c>();
        List<Id> ProjectInsertedIds = new List<Id>();


        List<Case> caseSuccessfulUpdate = new List<Case>();
        List<pse__Budget__c> budgetsToUpdate = new List<pse__Budget__c>();
        List<Project_Case_Association__c> projectCases2Insert = new List<Project_Case_Association__c>();
        
        Map<String,Double> projectToBudgetAmount = new Map<String,Double>();
        Map<String,Double> externalIdToPlannedHours = new Map<String,Double>();
        if(projTemplates.size() != 1)
        {
            PSA_AutoCreateProjectUtil.sendErrorMails('GSS Products/PS-Security - Project Template is not found or duplicates exist',
                'The template with the name as GSS Products/PS-Security - Project Template, is either not found or more than one template with that name exists.');
            return;
        }

        pse__proj__c projTemplate = projTemplates[0];

        //loop through the List of Contracts
        for(Id cId:mapContractContractDetails.keySet())
        {
           
                //Create a map of Unit of Measure and the Index of the corresponding contract detail 
                //in the mapContractContractDetails.get list
                List<Integer> hourCommittedList = new List<Integer>();
                List<Integer> hourUsageList = new List<Integer>();
                Integer perMonthIndex = -1;
                Integer eachIndex = -1;

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
                        //When the first per month cli is encountered or If there are more than one month clis
                        // and the current CLI is the latest updated
                        if( perMonthIndex == -1 || (contractDetail.LastModifiedDate > mapContractContractDetails.get(cId)[perMonthIndex].LastModifiedDate))
                        {
                            perMonthIndex = index;
                        }
                    }
                    else if(contractDetail.Unit_of_Measure__c =='Each')
                    {
                        //When the first each cli is encountered or If there are more than one each clis
                        // and the current CLI is the latest updated

                        if( eachIndex == -1 || (contractDetail.LastModifiedDate > mapContractContractDetails.get(cId)[eachIndex].LastModifiedDate))
                        {
                            eachIndex = index;
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
                Double budgetAmount;
                Double productCap;
                pse__proj__c proj;
                //MRR and Bucket project creation
                //No. of line items having UoM – “Hour” and Billing Duration = “Quarterly” or “Monthly ”= No. of MRR projects created.
                //No. of line items having UoM – “Hour” and Billing Duration < > “Quarterly” or “Monthly ”= No. of Bucket projects created.
                //If there are duplicates in UoM - "Per Month" -> The code picks latest modified among them for project creation
                //If there are duplicates in UoM - "Each" -> The code picks latest modified among them for project creation for bucket only
                //For Bucket projects, Uom - "Each" or "Per Month" is considered. If both are present latest modified each is picked for bucket only 
                if( hourCommittedList!=null && hourCommittedList.size() > 0 && ( perMonthIndex > -1|| eachIndex > -1) )
                {
                    for(Integer cliIndex : hourCommittedList)
                    {
                        cliSelected = mapContractContractDetails.get(cId)[cliIndex];
                        noOfActiveMonths = PSA_AutoCreateProjectUtil.numberOfActiveMonths(cliSelected.Effective_Start_Date__c,cliSelected.Effective_End_Date__c); 
                           
                        if(perMonthIndex > -1)
                        {
                           cliSelected2 = mapContractContractDetails.get(cId)[perMonthIndex];
                           onGngProject_RBAmt = ( (cliSelected2.Unit_Price__c!=null )? cliSelected2.Unit_Price__c : 0);
                        }

                        if(cliSelected.Units_Low__c == null)
                        {
                            cliSelected.Units_Low__c = 0;
                        }
                        //MRR project
                        if( (cliSelected.Billing_Duration__c == 'Monthly' || cliSelected.Billing_Duration__c == 'Quarterly') && perMonthIndex > -1 )
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
                            proj = PSA_AutoCreateProjectUtil.createProjectWithTemplate('Professional Services - Security_MRR',projTemplate,cId,cliSelected,autogenPSS.ProjectCase_Name__c,cliSelected.Id, cliSelected.Id, cliSelected2.Id, feeSchedule,onGngProject_RBAmt,plannedHours);
                            //recurring Planned hours is Monthly recurring hours
                            proj.Ongoing_Project_Recurring_Planned_Hour__c = cliSelected.Units_Low__c / noMonthsPerBilling;
                            proj.External_Id__c = String.valueOf(cliSelected.Id) + String.valueOf(cliSelected2.Id) + autogenPSS.ProjectCase_Name__c + String.valueOf(system.now());
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
                            if( eachIndex > -1)
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
                            proj = PSA_AutoCreateProjectUtil.createProjectWithTemplate('Professional Services - Security_Bucket',projTemplate,cId,cliSelected,autogenPSS.ProjectCase_Name__c,cliSelected.Id, cliSelected.Id, cliSelected2.Id, feeSchedule,onGngProject_RBAmt,plannedHours);                    
                            proj.External_Id__c = String.valueOf(cliSelected.Id) + String.valueOf(cliSelected2.Id) + autogenPSS.ProjectCase_Name__c + String.valueOf(system.now());
                            
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
                        feeSchedule = 'Time & Materials - No Cap';

                        if(cliSelected.Units_High__c == null)
                        {                            
                            productCap = 0;
                        }
                        else if(cliSelected.Billing_Duration__c == 'Monthly')
                        {
                            productCap = cliSelected.Units_High__c * PSA_AutoCreateProjectUtil.customRound(noOfActiveMonths);
                        }
                        else if(cliSelected.Billing_Duration__c == 'Quarterly')
                        {
                            productCap = cliSelected.Units_High__c * PSA_AutoCreateProjectUtil.customRound( Double.valueOf(noOfActiveMonths / 3.0 ));
                        }
                        else if(cliSelected.Billing_Duration__c == 'Annual')
                        {
                            productCap = cliSelected.Units_High__c * PSA_AutoCreateProjectUtil.customRound( Double.valueOf(noOfActiveMonths / 12.0 ));
                        }
                        else
                        {
                            productCap = cliSelected.Units_High__c;
                        }

                        usageRate = cliSelected.Unit_Price__c == null ? 0 : cliSelected.Unit_Price__c;
                        onGngProject_RBAmt = 0;
                        //Planned hours cannot be 0 for non-internal projects
                        plannedHours = productCap == 0? 1: productCap;
                        //createProjectWithTemplate(name,template,contractId,detail,product,mrr, overrage,permonth,  billingType, ongoingRecurringBudgetAmount, plannedHours)
                        proj = PSA_AutoCreateProjectUtil.createProjectWithTemplate('Professional Services - Security_Time & Material',projTemplate,cId,cliSelected,autogenPSS.ProjectCase_Name__c,cliSelected.Id, cliSelected.Id, cliSelected.Id, feeSchedule,onGngProject_RBAmt,plannedHours);    
                        proj.External_Id__c = String.valueOf(cliSelected.Id) + String.valueOf(cliSelected.Id) + autogenPSS.ProjectCase_Name__c + String.valueOf(system.now());
                        budgetAmount = usageRate * productCap;
                        projectToBudgetAmount.put(proj.External_Id__c,budgetAmount);
                        ListProj2Insert.add(proj);
                    }
                }
                  
        } 

        //Adding the list of projects to be created to the create object to be returned to the main class
        autogenPSSList.projectsForUpsert.addAll(ListProj2Insert);
        
        Boolean successfulCase = False;
        Map<Id,List<pse__Proj__c>> contractToProjectLists = new Map<Id,List<pse__Proj__c>>();

        //Create a map of contract to project -> 1 contract can be linked to any number of projects
        
        for(pse__proj__c p1:ListProj2Insert)
        {  
            externalIdToPlannedHours.put(p1.External_Id__c,p1.pse__Planned_Hours__c);
            if(!contractToProjectLists.containsKey(p1.SMP_Contract__c))
            {
                contractToProjectLists.put(p1.SMP_Contract__c,new List<pse__Proj__c>());    
            }            
            contractToProjectLists.get(p1.SMP_Contract__c).add(p1);
        }

        //Loop over the cases: create the Project_Case_Association__c record for the project created. if the project is not created for a case -> update the description 
        for(case c1:cases)
        {
            successfulCase = False;
            if(contractToProjectLists.containsKey(c1.contract__c))
             {  
                Project_Case_Association__c pca1;  
                for(pse__Proj__c p1: contractToProjectLists.get(c1.contract__c))
                {
                     if(p1.Name.contains('Professional Services - Security_MRR'))
                    {
                        pca1 = PSA_AutoCreateProjectUtil.createProjectCaseAssociationRecordExternalid(p1,c1.Id,c1.contract__c,'Professional Services - Security_MRR',autogenPSS.ProjectCase_Name__c);
                    } 
                    else if(p1.Name.contains('Professional Services - Security_Bucket')) 
                    {
                        pca1 = PSA_AutoCreateProjectUtil.createProjectCaseAssociationRecordExternalid(p1,c1.Id,c1.contract__c,'Professional Services - Security_Bucket',autogenPSS.ProjectCase_Name__c);
                    } 
                    else if(p1.Name.contains('Professional Services - Security_Time & Material'))
                    {
                        pca1 = PSA_AutoCreateProjectUtil.createProjectCaseAssociationRecordExternalid(p1,c1.Id,c1.contract__c,'Professional Services - Security_T&M',autogenPSS.ProjectCase_Name__c);
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
            String errorMessage =   '\n\n<### PROJECT NOT CREATED ###>\n\n'+
                                    'Please note that due to contract set-up the Salesforce project has not been automatically created.'+
                                    '\n\nPlease follow these guidelines on how to create the projects:\nhttps://ac.akamai.com/docs/DOC-9413';

            String successMessage = '\n\nPlease note that a Salesforce project has been automatically created:\n'+
                                     'Link to the Project can be found on the Project Related List section of the Case\n\n'+
                                     'Please follow these guidelines on project assignment & usage:\nhttps://ac.akamai.com/docs/DOC-9413';

            c1.Description = c1.Description.replaceAll(errorMessage,'');              
            c1.Description = c1.Description.replaceAll(successMessage,'');              

            if(successfulCase)
            {
                c1.Description += successMessage;
                caseSuccessfulUpdate.add(c1);                              
            }
            else if( !(c1.description.contains('PROJECT NOT CREATED')) )
            {
                c1.Description += errorMessage;
                caseSuccessfulUpdate.add(c1);
            }
        }

        //Adding the list of project case records to be created to the object to be returned to the main class
        autogenPSSList.pcaForUpsert.addAll(projectCases2Insert);


        //Update case description.
        autogenPSSList.casesForUpsert.addAll(caseSuccessfulUpdate);        
        
        ////To create the budget with specific name -> create a map of project name to budget name. This is to be passed as the second parameter
        Map<String,String> ProjectNametoBudgetName = new Map<String,String>();
        ProjectNametoBudgetName.put('Professional Services - Security_MRR','PS-S_MRR');
        ProjectNametoBudgetName.put('Professional Services - Security_Bucket','PS-S_Bucket');
        ProjectNametoBudgetName.put('Professional Services - Security_Time & Material','PS-S_T&M');

         
        //createBudgetWithName(projects, type, ProjectNametoBudgetName)
        listBudget2Insert = PSA_AutoCreateProjectUtil.createBudgetWithNameExternalId(ListProj2Insert,'Customer Purchase Order',ProjectNametoBudgetName);

        // change the amount for the budget
        if(listBudget2Insert!=null || listBudget2Insert.size() > 0 )
        {
            for( pse__Budget__c budg : listBudget2Insert )
            {
                if(budg.Name.contains('PS-S_T&M'))
                {
                    budg.pse__Amount__c = projectToBudgetAmount.get(budg.External_Id__c);
                }
                if(budg.pse__Amount__c == externalIdToPlannedHours.get(budg.External_Id__c) && budg.pse__Amount__c != 0)
                {
                    budg.pse__Amount__c += 0.1;
                }   
            }
        }
        

        //Adding the list of budget records to be created to the object to be returned to the main class
        autogenPSSList.budgetsForUpsert.addAll(listBudget2Insert);


       //If all milestones of a project should have a constant value, create a map of the project name to the constant value. Similarly for the planned hours, create a map of  the project name to the constant value. 
       //If the milestone amount has to be set from the project -> project.Ongoing_Project_Recurring_Budget_Amt__c * project.Months_from_Start_to_End_Date__c, create a list of the milestone names.
       //If the milestone planned hours has to be set from the project, create a list of the milestone names -> milestone.pse__Planned_Hours__c = project.pse__Planned_Hours__c
       List<pse__Milestone__c> milestones = new List<pse__Milestone__c>();

       //createMilestones (List<pse__Proj__c> projects, List<String> setAmountFromProject,List<String> setPlannedhoursFromProject, Map<String,Double> setDefaultAmountProjectToAmount,Map<String,Integer> setDefaultPlannedHoursProjectToHours)
        milestones = PSA_AutoCreateProjectUtil.createMilestonesExternalId(ListProj2Insert,null,null,null,null);
        
        //Adding the list of milestone records to be created to the object to be returned to the main class
        autogenPSSList.milestonesForUpsert.addAll(milestones);

       

    }

    

}