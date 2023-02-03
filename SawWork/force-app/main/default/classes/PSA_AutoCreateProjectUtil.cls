/*
 * CR: 3368331
 * Developer: Sharath Prasanna
 * Enhancement: Automated creation of SF projects Util Class
 * Date: 15th September 2016
 *
*/ 
public class PSA_AutoCreateProjectUtil 
{
  public PSA_AutoCreateProjectUtil() 
  {
    
  }

  public static List<Database.UpsertResult> upsertResultRecords = new List<Database.UpsertResult>();
  public static List<Database.SaveResult> saveResultRecords = new List<Database.SaveResult>();

  //public static Map<Id,List<Merge_Contract_Detail__c>> getContractDetails(List<Merge_Contract_Header__c>  ListContractScope,List<Merge_Contract_Detail__c> ListContractDetailstoCheck,List<Case> cases,String product,List<Project_Case_Association__c> projectCases)
  //{
      
  //    List<Merge_Contract_Detail__c> ListContractDetailstoCheckCases = new List<Merge_Contract_Detail__c>();
  //    List<Merge_Contract_Detail__c> ListContractDetailstoCreateProject = new List<Merge_Contract_Detail__c>();     
  //    Map<Id,List<Merge_Contract_Detail__c>> mapContractContractDetails = new Map<Id,List<Merge_Contract_Detail__c>>();
  //    Map<String,String> Contracts2Exclude = new Map<String,String>();
  //    Map<String,String> Case2Case = new Map<String,String>();
       
       
 //      //Populate the Map Contracts2Exclude: This is a map of ContractIdToContractId from the projectCases List
 //      for(Project_Case_Association__c pca : projectCases)
 //      {
 //         if(!Contracts2Exclude.containsKey(pca.Contract__c))
 //         {
 //           Contracts2Exclude.put(pca.Contract__c,pca.Contract__c);
 //         }
            
 //      } 
 //      //Populate the Map Case2Case: This is a map of ContractIdToContractId from the cases List
 //      for(Case caseToCheck: cases)
 //      {
 //         if(!Case2Case.containsKey(caseToCheck.Contract__c))
 //         {
 //           Case2Case.put(caseToCheck.Contract__c,caseToCheck.Contract__c);   
 //         }                   
 //      }
       

 //      for(Merge_Contract_Detail__c cd:ListContractDetailstoCheck)
 //      {
 //         //Check if the contract Id of the detail is not in the map Contracts2Exclude. If so, then add to the List ListContractDetailstoCheckCases
 //            if(! Contracts2Exclude.containsKey(cd.Original_Contract_Id__c))
 //            {
 //                ListContractDetailstoCheckCases.add(cd);
 //            }
 //      }

 //      for(Merge_Contract_Detail__c cd2:ListContractDetailstoCheckCases)
 //      {
 //         //Check if the contract Id of the details in the List ListContractDetailstoCheckCases is in the map Case2Case. If so, then add to the List ListContractDetailstoCreateProject

 //             if(Case2Case.containsKey(cd2.Original_Contract_Id__c))
 //             {
 //                 ListContractDetailstoCreateProject.add(cd2);
 //             }
 //       }
        
 //       // The below block forms a map of the Contract and the corresponding Contract Detail List.
 //       for(Merge_Contract_Detail__c cd1:ListContractDetailstoCreateProject)
 //       {
 //          if(mapContractContractDetails == NULL || mapContractContractDetails.get(cd1.Original_Contract_Id__c) == NULL)
 //          {
 //              mapContractContractDetails.put(cd1.Original_Contract_Id__c, new List<Merge_Contract_Detail__c>{cd1});
              
 //          }
 //          else if(mapContractContractDetails.get(cd1.Original_Contract_Id__c)!= NULL)
 //          {
 //               (mapContractContractDetails.get(cd1.Original_Contract_Id__c)).add(cd1);
 //          }
 //       }

 //       return mapContractContractDetails;        

  //}
  
  //Get the account territory tied to the contract detail. Get the id of the pse__Region__c record which has the name = Account_Name__r.Area__c + ' (Territory)' . If there is no such region record,get the id of the corporate record

  public static Id getRegion(Merge_Contract_Detail__c contractDetail)
  {
      //String regionName = contractDetail.Original_Contract_Id__r.Account_Name__r.Area__c + ' (Territory)';
      String regionName = contractDetail.Original_Contract_Id__r.Account_Name__r.TERR_HIER_5__c + ' (Territory)';
      List<pse__Region__c> regions = [select id from pse__Region__c where name = :regionName ];
      if(regions != null && regions.size() > 0)
      {
          return regions[0].id;  
      }
      else
      {
          regions = [select id from pse__Region__c where name = 'Corporate' ];
          if(regions != null && regions.size() > 0)
          {
              return regions[0].id; 
          }
      }
      return null;
  }

  //For the given list of projects, create the list of project products: with names given in: productNames
  public static void createProjectProducts(List<Id> projectIds, List<String> productNames)
  {      
      List<pse__Project_Methodology__c> methodologies = new List<pse__Project_Methodology__c>();
      pse__Project_Methodology__c methodology;
      for(Id projId: projectIds)
      {
        for(String product: productNames)
          {
              methodology = new pse__Project_Methodology__c();
              methodology.Product__c = product;
              methodology.pse__Project__c = projId;
              methodologies.add(methodology);
          }        
      }
      if(methodologies.size() > 0)
      {
          try
          {
              upsertResultRecords = Database.Upsert(methodologies,false); 
              PopulateErrorTableForUpsert(upsertResultRecords, 'Project Product Creation'); 
          }
          catch(Exception e)
          {
                sendErrorMails('Project Product Creation Exception',e.getMessage());
                
          }
          
      }  
  }

  //For the given list of projects, create the list of project products: given in the map: templatetoProductNames. For the project with template id as key in the map, create the value list of products 
  public static void createTemplateSpecificProjectProducts(List<pse__Proj__c> projects,Map<id,List<String>> templatetoProductNames)
  {
      List<pse__Project_Methodology__c> methodologies = new List<pse__Project_Methodology__c>();
      pse__Project_Methodology__c methodology;
      if(templatetoProductNames == null)
      {
          return ;
      }   
      for(pse__Proj__c project: projects)
      {
        if(templatetoProductNames.get(project.Project_Template__c) != null)
        {
            for(String product: templatetoProductNames.get(project.Project_Template__c))
            {
                methodology = new pse__Project_Methodology__c();
                methodology.Product__c = product;
                methodology.pse__Project__c = project.id;
                methodologies.add(methodology);
            }        

        }

      }
      if(methodologies.size() > 0)
      {
          try
          {
              upsertResultRecords = Database.Upsert(methodologies,false); 
              PopulateErrorTableForUpsert(upsertResultRecords, 'Project Product Creation'); 
          }
          catch(Exception e)
          {
                sendErrorMails('Project Product Creation Exception',e.getMessage());
                
          }
          
      }  
  }

  //Create a Project_Case_Association__c record,given the projectid, cseid, contractid,name and the product name
  public static Project_Case_Association__c createProjectCaseAssociationRecord(Id projectId, Id caseId, String contractHeader,String name, String product)
  {
        Project_Case_Association__c pc = new Project_Case_Association__c();                 
        pc.Case__c = caseId;
        pc.Project__c = projectId;
        pc.Contract__c = contractHeader;
        pc.Name = name;
        pc.Autogen_Project__c = True;
        pc.Automated_Project_Type__c = product;
        return pc;
  }

  //Changes by Sharath for FFPSA-271: Creating the project case association record and setting the project lookup to the external Id
  public static Project_Case_Association__c createProjectCaseAssociationRecordExternalid(pse__proj__c projectLink, Id caseId, String contractHeader,String name, String product)
  {
        pse__proj__c projLookUp = new pse__proj__c();
            
        projLookUp.External_Id__c = projectLink.External_Id__c;
            
        Project_Case_Association__c pc = new Project_Case_Association__c();                 
        pc.Case__c = caseId;
        pc.Project__r = projLookUp;
        pc.Contract__c = contractHeader;
        pc.Name = name;
        pc.Autogen_Project__c = True;
        pc.Automated_Project_Type__c = product;
        return pc;
  }

  //public static pse__Budget__c createBudget(Id projectId, Id accountId,Boolean billable, String type,Date startDate)
  //{
  //      pse__Budget__c budget= new pse__Budget__c();
  //      budget.pse__Billable__c = billable;
  //      budget.pse__Project__c = projectId;
  //      budget.pse__Account__c = accountId;
  //      budget.pse__Status__c = 'Approved';
        
  //      budget.pse__Type__c = type;
  //      budget.pse__Approved__c = TRUE;
  //      budget.pse__Effective_Date__c = startDate;
  //      budget.pse__Amount__c = 0;
  //      return budget;
  //}

//Create the budget -> given the list of projects and the type. The name of the budget in this case is -> project name (73 characters) and -Budget. The checkbox Autogen_Budget__c remains false.
public static List<pse__Budget__c> createBudget(List<pse__Proj__c> projects, String type)
  { 
        List<pse__Budget__c> budgets = new List<pse__Budget__c>();
        pse__Budget__c budget = new pse__Budget__c();
        Integer noOfActiveMonths;
        for(pse__proj__c project: projects)
        {
            budget= new pse__Budget__c();
            budget.pse__Billable__c = project.pse__Is_Billable__c;
            budget.pse__Project__c = project.Id;
            budget.pse__Account__c = project.pse__Account__c;
            budget.pse__Status__c = 'Approved';
            
            budget.pse__Type__c = type;
            budget.pse__Approved__c = TRUE;
            budget.pse__Effective_Date__c = project.pse__Start_Date__c;
            noOfActiveMonths = numberOfActiveMonths(project.pse__Start_Date__c,project.pse__End_Date__c);
            budget.pse__Amount__c = project.Ongoing_Project_Recurring_Budget_Amt__c * noOfActiveMonths;

            budgets.add(budget);
        }    
        return budgets;
  }

//Create the budget -> given the list of projects ,the type and the map of project to budget name. The name of the budget in this case is -> Account name(30 chars) and Budget name (43 chars) and -Budget. The checkbox Autogen_Budget__c remains true.
public static List<pse__Budget__c> createBudgetWithName(List<pse__Proj__c> projects, String type, Map<String,String> ProjectNametoBudgetName)
  { 
        List<pse__Budget__c> budgets = new List<pse__Budget__c>();
        pse__Budget__c budget = new pse__Budget__c();
        String budgetName;
        Integer noOfActiveMonths;
        for(pse__proj__c project: projects)
        {
            budgetName = '';
            if(ProjectNametoBudgetName != null)
            {
              for(String projectName: ProjectNametoBudgetName.keySet())
              {
                  if(project.name.contains(projectName))
                  {
                      budgetName = ProjectNametoBudgetName.get(projectName);
                  }
              }
            }
            budget= new pse__Budget__c();
            if(budgetName != '')
            {
                budget.Name = budgetName;
            }
            budget.pse__Billable__c = project.pse__Is_Billable__c;
            budget.pse__Project__c = project.Id;
            budget.pse__Account__c = project.pse__Account__c;
            budget.pse__Status__c = 'Approved';
            
            budget.pse__Type__c = type;
            budget.pse__Approved__c = TRUE;
            budget.Autogen_Budget__c = true;
            budget.pse__Effective_Date__c = project.pse__Start_Date__c;
            noOfActiveMonths = numberOfActiveMonths(project.pse__Start_Date__c,project.pse__End_Date__c);
            budget.pse__Amount__c = project.Ongoing_Project_Recurring_Budget_Amt__c * noOfActiveMonths;

            budgets.add(budget);
        }    
        return budgets;
  }
  //Changes by Sharath for FFPSA-271: Adding the method to create budgets with project External Id
  //Create the budget -> given the list of projects ,the type and the map of project to budget name. The name of the budget in this case is -> Account name(30 chars) and Budget name (43 chars) and -Budget. The checkbox Autogen_Budget__c remains true.
  public static List<pse__Budget__c> createBudgetWithNameExternalId(List<pse__Proj__c> projects, String type, Map<String,String> ProjectNametoBudgetName)
  { 
        List<pse__Budget__c> budgets = new List<pse__Budget__c>();
        pse__Budget__c budget = new pse__Budget__c();
        pse__Proj__c projectLookUp;
        String budgetName;
        Integer noOfActiveMonths;
        for(pse__proj__c project: projects)
        {
            budgetName = '';
            if(ProjectNametoBudgetName != null)
            {
              for(String projectName: ProjectNametoBudgetName.keySet())
              {
                  if(project.name.contains(projectName))
                  {
                      budgetName = ProjectNametoBudgetName.get(projectName);
                  }
              }
            }
            budget= new pse__Budget__c();
            if(budgetName != '')
            {
                budget.Name = budgetName;
            }
            budget.pse__Billable__c = project.pse__Is_Billable__c;

            projectLookUp = new pse__Proj__c();
            projectLookUp.External_Id__c = project.External_Id__c;
            
            budget.External_Id__c = project.External_Id__c;
            budget.pse__Project__r = projectLookUp;
            budget.pse__Account__c = project.pse__Account__c;
            budget.pse__Status__c = 'Approved';
            
            budget.pse__Type__c = type;
            budget.pse__Approved__c = TRUE;
            budget.Autogen_Budget__c = true;
            budget.pse__Effective_Date__c = project.pse__Start_Date__c;
            noOfActiveMonths = numberOfActiveMonths(project.pse__Start_Date__c,project.pse__End_Date__c);
            budget.pse__Amount__c = project.Ongoing_Project_Recurring_Budget_Amt__c * noOfActiveMonths;

            budgets.add(budget);
        }    
        return budgets;
  }

  //Creates the Project_Contract__c record
  public static Project_Contract__c createProjectContract(Id projectId,Id accountId,Id contractId)
  {
      Project_Contract__c pc = new Project_Contract__c();
      pc.Project__c = projectId;
      pc.Original_Contract_Id__c = contractId;
      pc.Account__c = accountId;      
      return pc;
  }

    public static void insertPCLItems(List<pse__proj__c> projects)
    {
        //List<pse__proj__c> p = [select Id,Name,SMP_Contract__c,pse__Account__c,SMP_Contract_Line_Item__c,Automated_Project__c from pse__proj__c where Id in :projIds];
        Set<Id> ContractLI = new Set<Id>();
        List<pse__proj__c> Proj2Update = new List<pse__proj__c>();
        List<Project_Contract__c> projConList = new List<Project_Contract__c>();
        List<Project_Contract_Line_Item__c> PCLI2Insert = new List<Project_Contract_Line_Item__c>();
        List<Merge_Contract_Detail__c>List2Update = new List<Merge_Contract_Detail__c>();
        Map<pse__proj__c,Project_Contract__c> ProjProjContractMap = new Map<pse__proj__c,Project_Contract__c>();
        
        // The below block creates a List of Project Contracts to insert and forms a map of Project and Project Contract. 
        Project_Contract__c pc;
        for(pse__proj__c p1:projects)
        {
            pc = createProjectContract(p1.Id,p1.pse__Account__c,(Id)(p1.SMP_Contract__c));
            projConList.add(pc);
            ProjProjContractMap.put(p1,pc);            
        }

        //Insert all the project contracts.
        try
        {
              upsertResultRecords = Database.Upsert(projConList,False);
              PopulateErrorTableForUpsert(upsertResultRecords, 'Project Contract Creation'); 

        }
        catch(Exception e)
        {
            sendErrorMails('Project Contract Creation Exception',e.getMessage());
            return;
        }        
        

        for(pse__proj__c p2:ProjProjContractMap.keySet())
        {
            Project_Contract_Line_Item__c pcli = new Project_Contract_Line_Item__c();
            pcli.Contract_Detail__c = (Id)(p2.SMP_Contract_Line_Item__c);
            pcli.Original_Contract_Id__c = ProjProjContractMap.get(p2).Original_Contract_Id__c;
            pcli.Project__c = p2.Id;
            pcli.Project_Contract__c = ProjProjContractMap.get(p2).Id;
            pcli.Valid_Create__c = TRUE;
            PCLI2Insert.add(pcli);
            ContractLI.add(pcli.Contract_Detail__c);

            // Final step is to update the flag - 'SMP Automated Project' to TRUE and set the Contract closed to TRUE. 
            p2.SMP_Automated_Project__c = TRUE;
            p2.Contract_Closed__c = 'Yes';
            Proj2Update.add(p2);
            
        }

        //Insert the PCLI's and update the Contract closed and the Automated Project flags on Project.
        try
        {
              upsertResultRecords = Database.Upsert(PCLI2Insert,False);
              PopulateErrorTableForUpsert(upsertResultRecords, 'Project Contract Line Item Creation'); 

        }
        catch(Exception e)
        {
            sendErrorMails('Project Contract Creation Exception',e.getMessage());
            return;

        }
        try
        {
              saveResultRecords = Database.update(Proj2Update,False);
              PopulateErrorTableForUpdate(saveResultRecords,Proj2Update);
        }
        catch(Exception e)
        {
            sendErrorMails('Project Update Exception',e.getMessage());
            return;

        }
        
        
        
    }

      //public static List<pse__Milestone__c> createMilestones (pse__Proj__c project, Id templateId)
      //{
      //      List<pse__Milestone__c> milestones = new List<pse__Milestone__c>();
      //      List<pse__Milestone__c> templateMilestones = [select Id,Name,RecordtypeID,Billable__c,pse__Status__c,Task_Milestone_Name__c,pse__Description__c,
      //                                       pse__Milestone_Amount__c,Milestone_Type_List__c,Milestone_Type_Value__c,pse__Planned_Hours__c from pse__Milestone__c where pse__Project__c = :templateId];
      //       pse__Milestone__c milestone;                                              
      //      for(pse__Milestone__c m: templateMilestones)
      //      {
      //          milestone = m.clone(false,true,false,false);
      //          milestone.Start_Date__c = project.pse__Start_Date__c;
      //          milestone.pse__Target_Date__c = project.pse__End_Date__c;
      //          milestone.pse__Project__c = project.Id;
      //          milestone.pse__Milestone_Amount__c = 0;
      //          milestone.pse__Planned_Hours__c = 0; 
      //          milestones.add(milestone);
      //      }


      //      return milestones;
      //}

      //create the milestones
      public static List<pse__Milestone__c> createMilestones (List<pse__Proj__c> projects, List<String> setAmountFromProject,List<String> setPlannedhoursFromProject, Map<String,Double> setDefaultAmountProjectToAmount,Map<String,Integer> setDefaultPlannedHoursProjectToHours)
      {
          //get the map of template to list of projs
            Map<id,List<pse__Proj__c>> templatetoProjectIds  = new Map<id,List<pse__Proj__c>>();
            Integer noOfActiveMonths;
            for(pse__Proj__c proj : projects)
            {
                if(!templatetoProjectIds.containsKey(proj.Project_Template__c))
                {
                    templatetoProjectIds.put(proj.Project_Template__c,new List<pse__proj__c>());
                }
                templatetoProjectIds.get(proj.Project_Template__c).add(proj);
            }

            List<pse__Milestone__c> milestones = new List<pse__Milestone__c>();
            //get the list of the template milestones
            List<pse__Milestone__c> templateMilestones = [select Id,Name,RecordtypeID,Billable__c,pse__Status__c,Task_Milestone_Name__c,pse__Description__c,
                                             pse__Milestone_Amount__c,Milestone_Type_List__c,Milestone_Type_Value__c,pse__Planned_Hours__c,pse__Project__c from pse__Milestone__c where pse__Project__c in :templatetoProjectIds.keySet()];
             pse__Milestone__c milestone; 
             
             //for every template milestone m, for every project in the list got by templatetoProjectIds.get(m.pse__Project__c), create a milestone. 
            for(pse__Milestone__c m: templateMilestones)
            {
                for(pse__Proj__c project: templatetoProjectIds.get(m.pse__Project__c))
                {                                
                        milestone = m.clone(false,true,false,false);
                        milestone.Start_Date__c = project.pse__Start_Date__c;
                        milestone.pse__Target_Date__c = project.pse__End_Date__c;
                        milestone.pse__Project__c = project.Id;
                        milestone.pse__Milestone_Amount__c = 0;
                        milestone.pse__Planned_Hours__c = 0; 
                        
                        //map of Project name to milestone default amount
                        if(setDefaultAmountProjectToAmount != null)
                        {
                            for(String pName: setDefaultAmountProjectToAmount.keySet())
                            {
                                if(project.name.contains(pName))
                                {
                                    milestone.pse__Milestone_Amount__c = setDefaultAmountProjectToAmount.get(pName);
                                }
                            }

                        }
                        //map of Project name to milestone default planned hours
                        if(setDefaultPlannedHoursProjectToHours != null)
                        {
                            for(String pName: setDefaultPlannedHoursProjectToHours.keySet())
                            {
                                if(project.name.contains(pName))
                                {
                                    milestone.pse__Planned_Hours__c = setDefaultPlannedHoursProjectToHours.get(pName);
                                }
                            }

                        }

                        //set the milestone amount from the project
                        if(setAmountFromProject != null)
                        {
                            for(String mName: setAmountFromProject)
                            {
                                if(milestone.name.contains(mName))
                                {
                                    noOfActiveMonths = numberOfActiveMonths(project.pse__Start_Date__c,project.pse__End_Date__c);
                                    milestone.pse__Milestone_Amount__c = project.Ongoing_Project_Recurring_Budget_Amt__c * noOfActiveMonths;
                                }
                            }

                        }
                        //set the milestone planned hours from the project
                        if(setPlannedhoursFromProject != null)
                        {
                            for(String mName: setPlannedhoursFromProject)
                            {
                                if(milestone.name.contains(mName))
                                {
                                    milestone.pse__Planned_Hours__c = project.pse__Planned_Hours__c;
                                }

                            }                          
                        }
                        milestones.add(milestone);
                }        
          }


          return milestones;
      }

      //Changes by Sharath for FFPSA-271: Linking the project via external Id
      public static List<pse__Milestone__c> createMilestonesExternalId (List<pse__Proj__c> projects, List<String> setAmountFromProject,List<String> setPlannedhoursFromProject, Map<String,Double> setDefaultAmountProjectToAmount,Map<String,Integer> setDefaultPlannedHoursProjectToHours)
      {
          //get the map of template to list of projs
            Map<id,List<pse__Proj__c>> templatetoProjectIds  = new Map<id,List<pse__Proj__c>>();
            pse__Proj__c projectLookUp;
            Integer noOfActiveMonths;
            for(pse__Proj__c proj : projects)
            {
                if(!templatetoProjectIds.containsKey(proj.Project_Template__c))
                {
                    templatetoProjectIds.put(proj.Project_Template__c,new List<pse__proj__c>());
                }
                templatetoProjectIds.get(proj.Project_Template__c).add(proj);
            }

            List<pse__Milestone__c> milestones = new List<pse__Milestone__c>();
            //get the list of the template milestones
            List<pse__Milestone__c> templateMilestones = [select Id,Name,RecordtypeID,Billable__c,pse__Status__c,Task_Milestone_Name__c,pse__Description__c,
                                             pse__Milestone_Amount__c,Milestone_Type_List__c,Milestone_Type_Value__c,pse__Planned_Hours__c,pse__Project__c from pse__Milestone__c where pse__Project__c in :templatetoProjectIds.keySet()];
             pse__Milestone__c milestone; 
             
             //for every template milestone m, for every project in the list got by templatetoProjectIds.get(m.pse__Project__c), create a milestone. 
            for(pse__Milestone__c m: templateMilestones)
            {
                for(pse__Proj__c project: templatetoProjectIds.get(m.pse__Project__c))
                {                                
                        milestone = new pse__Milestone__c();    
                        milestone.RecordtypeID  = m.RecordtypeID;
                        milestone.pse__Status__c  = m.pse__Status__c;
                        milestone.Milestone_Type_List__c  = m.Milestone_Type_List__c;
                        milestone.Milestone_Type_Value__c  = m.Milestone_Type_Value__c;
                        milestone.Task_Milestone_Name__c = m.Task_Milestone_Name__c;
                        milestone.Name = m.Name;
                        milestone.Billable__c = m.Billable__c;                        
                        milestone.Start_Date__c = project.pse__Start_Date__c;
                        milestone.pse__Target_Date__c = project.pse__End_Date__c;
                        milestone.External_Id__c = project.External_Id__c + milestones.size();                        

                        projectLookUp = new pse__Proj__c();
                        projectLookUp.External_Id__c = project.External_Id__c;
                        milestone.pse__Project__r = projectLookUp;

                        milestone.pse__Milestone_Amount__c = 0;
                        milestone.pse__Planned_Hours__c = 0; 
                        
                        //map of Project name to milestone default amount
                        if(setDefaultAmountProjectToAmount != null)
                        {
                            for(String pName: setDefaultAmountProjectToAmount.keySet())
                            {
                                if(project.name.contains(pName))
                                {
                                    milestone.pse__Milestone_Amount__c = setDefaultAmountProjectToAmount.get(pName);
                                }
                            }

                        }
                        //map of Project name to milestone default planned hours
                        if(setDefaultPlannedHoursProjectToHours != null)
                        {
                            for(String pName: setDefaultPlannedHoursProjectToHours.keySet())
                            {
                                if(project.name.contains(pName))
                                {
                                    milestone.pse__Planned_Hours__c = setDefaultPlannedHoursProjectToHours.get(pName);
                                }
                            }

                        }

                        //set the milestone amount from the project
                        if(setAmountFromProject != null)
                        {
                            for(String mName: setAmountFromProject)
                            {
                                if(milestone.name.contains(mName))
                                {
                                    noOfActiveMonths = numberOfActiveMonths(project.pse__Start_Date__c,project.pse__End_Date__c);
                                    milestone.pse__Milestone_Amount__c = project.Ongoing_Project_Recurring_Budget_Amt__c * noOfActiveMonths;
                                }
                            }

                        }
                        //set the milestone planned hours from the project
                        if(setPlannedhoursFromProject != null)
                        {
                            for(String mName: setPlannedhoursFromProject)
                            {
                                if(milestone.name.contains(mName))
                                {
                                    milestone.pse__Planned_Hours__c = project.pse__Planned_Hours__c;
                                }

                            }                          
                        }
                        milestones.add(milestone);
                }        
          }


          return milestones;
      }

    public static pse__Proj__c createProjectWithTemplate(String name,pse__Proj__c template,Id contractId,Merge_Contract_Detail__c detail,String product,Id mrr, Id overrage, Id permonth, String billingType,Double ongoingRecurringBudgetAmount,Double plannedHours)
    { 
        PSA_Settings__c psa_settings = PSA_Settings__c.getInstance('Project Manager');
        pse__Proj__c proj = new pse__Proj__c();

        Id regionID = getRegion(detail);
        
        //For the SOA product: Config_Assistance project is to be tied to the detail with Unit Of measure hour and the Service project is to be tied to the detail with Unit Of measure Reviews

        /* Create a clone from the template. 
        clone(preserveId, isDeepClone, preserveReadOnlyTimestamps, preserveAutoNumber)*/
        
        proj=template.clone(false,true,false,false);
        
        proj.Name = name;
        proj.Project_Template__c = template.id;
        // The currency and Account Name come from the Contract.
        proj.CurrencyIsoCode = detail.Original_Contract_Id__r.Currency__c;
        proj.pse__Account__c = detail.Original_Contract_Id__r.Account_Name__c;

        // Initially Contract closed is set to No. 
        proj.Contract_Closed__c = 'No';

        proj.pse__Billing_Type__c = billingType;

        // Project Manager is set to PSA User.     
        proj.pse__Project_Manager__c = psa_settings.Value__c;

        // start and end date of Project come from the Contract Line Item. 
        proj.pse__End_Date__c = detail.Effective_End_Date__c;
        proj.pse__Start_Date__c = detail.Effective_Start_Date__c;

        //if(regionID == null)
        //{
        //    proj.pse__Region__c = null;   
        //}
        //else
        if(regionID != null)
        {
            proj.pse__Region__c = regionID; 
        }
        

        //Initially set the value of Planned Hours, Recurring Planned Hour etc to default values. These will be changed by WF field updates. 

        proj.pse__Planned_Hours__c = plannedHours;
        proj.Ongoing_Project_Recurring_Planned_Hour__c = 0;
        proj.SMP_Contract__c = contractId;
        proj.SMP_Contract_Line_Item__c = detail.Id; 

        proj.PCLI_MRR1__c = mrr; 
        proj.PCLI_Overage1__c = overrage; 
        proj.PCLI_PerMonth1__c = permonth; 

        proj.Unit_Price__c = detail.Unit_Price__c;
        proj.Units_Low__c = detail.Units_Low__c;
        proj.Ongoing_Project_Recurring_Budget_Amt__c = ongoingRecurringBudgetAmount;
        
        proj.Autogen_Product__c = product;
        system.debug('Sam MRR Project Added');




        return proj;
    }

    //Changes by Sharath Prasanna: Commenting out the function with Integer Planned Hours as the argument
    //public static pse__Proj__c createProjectWithTemplate(String name,pse__Proj__c template,Id contractId,Merge_Contract_Detail__c detail,String product,Id mrr, Id overrage, Id permonth, String billingType,Double ongoingRecurringBudgetAmount,Integer plannedHours)
    //{ 
    //    PSA_Settings__c psa_settings = PSA_Settings__c.getInstance('Project Manager');
    //    pse__Proj__c proj = new pse__Proj__c();

    //    Id regionID = getRegion(detail);
        
    //    //For the SOA product: Config_Assistance project is to be tied to the detail with Unit Of measure hour and the Service project is to be tied to the detail with Unit Of measure Reviews

    //    /* Create a clone from the template. 
    //    clone(preserveId, isDeepClone, preserveReadOnlyTimestamps, preserveAutoNumber)*/
        
    //    proj=template.clone(false,true,false,false);
        
    //    proj.Name = name;
    //    proj.Project_Template__c = template.id;
    //    // The currency and Account Name come from the Contract.
    //    proj.CurrencyIsoCode = detail.Original_Contract_Id__r.Currency__c;
    //    proj.pse__Account__c = detail.Original_Contract_Id__r.Account_Name__c;

    //    // Initially Contract closed is set to No. 
    //    proj.Contract_Closed__c = 'No';

    //    proj.pse__Billing_Type__c = billingType;

    //    // Project Manager is set to PSA User.     
    //    proj.pse__Project_Manager__c = psa_settings.Value__c;

    //    // start and end date of Project come from the Contract Line Item. 
    //    proj.pse__End_Date__c = detail.Effective_End_Date__c;
    //    proj.pse__Start_Date__c = detail.Effective_Start_Date__c;

    //    if(regionID == null)
    //    {
    //        proj.pse__Region__c = '';   
    //    }
    //    else
    //    {
    //        proj.pse__Region__c = regionID; 
    //    }
        

    //    //Initially set the value of Planned Hours, Recurring Planned Hour etc to default values. These will be changed by WF field updates. 

    //    proj.pse__Planned_Hours__c = plannedHours;
    //    proj.Ongoing_Project_Recurring_Planned_Hour__c = 0;
    //    proj.SMP_Contract__c = contractId;
    //    proj.SMP_Contract_Line_Item__c = detail.Id; 

    //    proj.PCLI_MRR1__c = mrr; 
    //    proj.PCLI_Overage1__c = overrage; 
    //    proj.PCLI_PerMonth1__c = permonth; 

    //    proj.Unit_Price__c = detail.Unit_Price__c;
    //    proj.Units_Low__c = detail.Units_Low__c;
    //    proj.Ongoing_Project_Recurring_Budget_Amt__c = ongoingRecurringBudgetAmount;
        
    //    proj.Autogen_Product__c = product;
    //    system.debug('Sam MRR Project Added');




    //    return proj;
    //}

    //The function to loop over the List of Update/Save results. If there is any failure, send a mail with the error table
    public static void PopulateErrorTableForUpdate(List<Database.SaveResult> results,List<SObject> objectLists)
    {
        String Errors = '';            
        String Table = ''; 
        for(Integer i = 0; results != null && objectLists != null &&  i < results.size(); i++)
        {
          Database.SaveResult sr = results.get(i);
            if (!sr.isSuccess()) 
            {
                for(Database.Error err : sr.getErrors()) 
                {
                   Errors += '<tr><td>' + err.getStatusCode() + ': ' + err.getMessage() + '</td><td>'+ objectLists.get(i).id + '</td></tr>';
                }
            }

        }
        if(Errors != '')
        {
          Table = '<table><tr><th>' + 'The error in Record </th>' + '<th> The Record ID </th></tr>';
          Table += Errors;
          Table += '</table><br/><br/>';          
          sendErrorMails('Update Failed: ' + '',Table);
        }
        
    }

    //The function to loop over the List of upsert results. If there is any failure, send a mail with the error table
    public static void PopulateErrorTableForUpsert(List<Database.UpsertResult> results,String caption)
    {
        String Errors = '';            
        String Table = ''; 
        for (Database.UpsertResult sr : results)
        {
            if (!sr.isSuccess()) 
            {
                for(Database.Error err : sr.getErrors()) 
                {
                   Errors += '<tr><td>' + err.getStatusCode() + ': ' + err.getMessage() + '</td><td>'+ err.getFields() + '</td></tr>';
                }
            }
        }
        if(Errors != '')
        {
          Table = '<table><caption><b>' +caption + '</b></caption><tr><th>' + 'The error in Record </th>' + '<th> The fields that affected this error </th></tr>';
          Table += Errors;
          Table += '</table><br/><br/>';  
          sendErrorMails('Upsert Failed: ' + '',Table);        
        }
        
    }

    //This takes in the subject and the error message string: sends a mail to the engg team
    public static void sendErrorMails(String Subject, String Error)
    {
        if(Error == '')
        {
          return;
        }
        System.debug('Host: ' + URL.getSalesforceBaseUrl().getHost()); 
        // 20.4.2 Adding Host name on the email that we send
        String hostName = URL.getSalesforceBaseUrl().getHost(); 
        PSA_Settings__c EnggEmail = PSA_Settings__c.getInstance('Engineering Team Email');
        String emailAddress = EnggEmail != null ?EnggEmail.Value__c : 'services-engg@akamai.com';
        String Body = '<html><style> table {border-collapse: collapse;} td,th {border: 1px solid black;}</style><body>Hi ' + UserInfo.getName() +', <br/> Instance : '+  hostName + '<br/><br/>';  
        Body += Error;
        Body += '</body></html>';
        Messaging.SingleEmailMessage[] mailsToBeSent = new List<Messaging.SingleEmailMessage>();
        Messaging.Singleemailmessage objEmail;
        objEmail = new Messaging.Singleemailmessage();
        objEmail.setReplyTo('noreply@akamai.com');
        objEmail.setToAddresses(new list<String>{emailAddress});            
        objEmail.setSubject(Subject + hostName);
        objEmail.setHTMLBody( Body );
        mailsToBeSent.add(objEmail);
        Messaging.sendEmail(mailsToBeSent,false);

    }

    //computes the number of Active months -> if the params are null, return 0
    public static Integer numberOfActiveMonths(Date startDate, Date endDate)
    {
          if(startDate == null || endDate == null)
          {
            return 0;
          }
          Date firstDate;
          Date secondDate;
          Integer noOfMonths;
          Integer diffDays;

          //Get the lower date and store it in firstDate. The greater date is stored in secondDate
          if(startDate <= endDate)
          {
            firstDate = startDate;
            secondDate = endDate;

          }
          else
          {
            secondDate = startDate;
            firstDate = endDate;

          }
          //get the number of months between the 2 dates. It will ignore the day difference. 
          //noOfMonths = firstDate.MonthsBetween(secondDate);
          noOfMonths  = ((secondDate.year() - firstDate.year()) * 12 )+ secondDate.month() - firstDate.month();
          //system.assertEquals(noOfMonths,0);
          //If the day of the second date is greater than or equal to the day of the first date, add 1 to the months. If the day of the first date is greater, then find the difference in days between the 2; if the difference is less than 15, then subtract 1 from the total months.
          if(secondDate.day() >= firstDate.day())
          {
              diffDays =  secondDate.day() - firstDate.day() ;
              if(Math.abs(diffDays) >= 15)
              {
                  noOfMonths++;
              }
          }
          else
          {
              Integer daysInMonth = 0;
              if(firstDate.month() == 1 || firstDate.month() == 3  || firstDate.month() == 5  || firstDate.month() == 7 || firstDate.month() == 8  || firstDate.month() == 10 || firstDate.month() == 12  )
              {
                  daysInMonth = 31;
              }
              else if(firstDate.month() == 2)
              {
                  daysInMonth = 28;
              }
              else
              {
                  daysInMonth = 30;
              }
               diffDays = daysInMonth - firstDate.day() + secondDate.day(); 
              if(Math.abs(diffDays) < 15)
              {
                  noOfMonths--;
              }
          }

          return Math.abs(noOfMonths);

    }

    //computes the monthlyRecurringHours. If the Units_Low__c or Billing_Duration__c is null, return 0
    public static Double monthlyRecurringHours(Merge_Contract_Detail__c detail)
    {
          if(detail == null || detail.Units_Low__c == null || detail.Billing_Duration__c == null)
          {
              return 0;
          }
          Double monthlyRecurringHours;

          return (detail.Billing_Duration__c == 'Quarterly') ? (detail.Units_Low__c / 3): (detail.Units_Low__c / 1);
    }

    //computes the securityServiceReviews. If the Units_Low__c or Effective_Start_Date__c or Effective_End_Date__c is null, return 0
    public static Double securityServiceReviews(Merge_Contract_Detail__c detail)
    {
        if(detail == null || detail.Units_Low__c == null || detail.Effective_Start_Date__c == null ||detail.Effective_End_Date__c == null)
        {
            return 0;
        }
        Double sSR = detail.Units_Low__c / 12.0 * numberOfActiveMonths(detail.Effective_Start_Date__c,detail.Effective_End_Date__c);
        Double roundSSR = Math.round(sSR);
        if((sSR - roundSSR) == 0.5)
        {
          roundSSR += 1.0; 
        }
        return roundSSR; 
    }

    //computes the hoursPerPolicy. If the Units_Low__c or Effective_Start_Date__c or Effective_End_Date__c is null, return 0
    public static Double hoursPerPolicy(Merge_Contract_Detail__c detail)
    {
        if(detail == null || detail.Units_Low__c == null || detail.Effective_Start_Date__c == null ||detail.Effective_End_Date__c == null)
        {
            return 0;
        }
        Double sSR = detail.Units_Low__c * (45.0 / 12.0) * numberOfActiveMonths(detail.Effective_Start_Date__c,detail.Effective_End_Date__c);
        Double roundSSR = customRound(sSR);
        return roundSSR; 
    }

    //computes the pricePerMonth. If the Unit_Price__c or Effective_Start_Date__c or Effective_End_Date__c is null, return 0
    public static Double pricePerMonth(Merge_Contract_Detail__c detail)
    {
        if(detail == null || detail.Unit_Price__c == null || detail.Effective_Start_Date__c == null || detail.Effective_End_Date__c == null)
        {
            return 0;
        }
        Double pPM = detail.Unit_Price__c * numberOfActiveMonths(detail.Effective_Start_Date__c,detail.Effective_End_Date__c);
        return pPm;
    }

    //Rounds a decimal value. The standard Math.Round rounds x.5 to x This function rounds x.5 to x+1
    public static Integer customRound(Double toRound)
    {
        if(toRound == null)
        {
            return 0;
        }
        Integer rounded = Math.round(toRound);
        if((toRound - rounded) == 0.5)
        {
          rounded += 1; 
        }
        return rounded;
    }

    //Adds months to given date
    public static Date customAddMonths(Date initialDate,Double monthsToAdd)
    {
        if(monthsToAdd == null || monthsToAdd == 0.0 || initialDate == null)
        {
            return initialDate;
        }
        Integer months = (Integer) monthsToAdd;
        Integer numberOfDays = Date.daysInMonth(initialDate.year(),initialDate.month());
        Integer days = PSA_AutoCreateProjectUtil.customRound((numberOfDays * (monthsToAdd - months)));
        Date finalDate = initialDate.addDays(days).addMonths(months);
        return finalDate;
    }
    
    
    //Method to take in object name, custom label, optional : sObject,where clause
    //The fieldset name on the object should be names as Label_Message_Fields and should contain all the fields necessary
    public static String getCustomizedLabelMessage(String objectName, String label, sObject obj, String whereClause)
    {
        if( ( (objectName==NULL||objectName.length()==0) && obj == NULL ) || label == NULL || label.length() == 0){
            return 'Error in getCustomizedLabelMessage';
        }
        Schema.DescribeSObjectResult DescribeSObjectResultObj = Schema.getGlobalDescribe().get(objectName).getDescribe();
        Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get('Label_Message_Fields');
        List<Schema.FieldSetMember> fieldSetMemberList = fieldSetObj.getFields();
        if(obj == NULL){
            String query = 'SELECT Id';
            for(Schema.FieldSetMember fieldSetMemberObj : fieldSetMemberList){
              query = query + ',' + fieldSetMemberObj.getFieldPath();
            }
            query = query + ' FROM ' + objectName+ ' ';
            if(whereClause != NULL && whereClause.length() > 0){
              query = query + whereClause;
            }
            query = query + ' Limit 1';
            
            obj = Database.query(query);
        }
        
        String apiName;
        for(Schema.FieldSetMember fieldSetMemberObj : fieldSetMemberList){
          apiName = fieldSetMemberObj.getFieldPath();
            System.debug('@@@apiName: '+apiName);
          if(label.containsIgnoreCase(apiName)){
            label = label.replace(apiName,String.valueOf(obj.get(apiName)));
          }
        }
        return label;
    }
}