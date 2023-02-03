/*
 Developer                        Date                        JIRA                            Changes
 Sandeep Naga               17th May 2019                   FFPSA-973            Created class for Plus Project Autogens  
 Sandeep Naga				28th April 2020					FFPSA-1377			 Made changes to chage pca check from lookup to string value
 Sandeep Naga				20th May 2020					FFPSA-1295			 Added a child query to the case base query to fetch TPM cases
*/

public class PSA_AutogenProjectBatch_New implements Database.Batchable<sObject>,Database.Stateful 
{

    //Variables for PSA Autogen Custom Metdata
    public Set<Id> allAutogenProductIdsSet = new Set<Id>();
    public Set<String> allProductIdsSet = new Set<String>();
    public Set<String> allAutogenUseCasesSet = new Set<String>();
    public Map<String,String> allCaseUseCaseToProjMap = new Map<String,String>();
    //Variables contain the class names of the various products to be called and other common variables
    public Set<String> allClassNamesSet = new Set<String>();
    public Set<String> allProjectCaseTypesSet = new Set<String>();

    //Variables for PSA Project Template Metadata
    List<String> tNames = new List<String>();
    List<String> tTypes = new List<String>();
    List<String> tSubTypes = new List<String>();
    Map<String,pse__Proj__c> nameToTemplate = new Map<String,pse__Proj__c>();

    //Variables for Start : batch and test queries
    public string batchQuery = NULL;
    private string autogenCaseQuery;
    static String TestClass_Query = null;

    

    


    public PSA_AutogenProjectBatch_New() 
    {
        //Fetch all the custom metadata : PSA Autogen, PSA Project Template

        //PSA Autogen
        for(PSA_Autogen__mdt autogenData_mdt: [SELECT id, Autogen_Usecase__c,ClassName__c,Product_Id__c,Product_Name__c,ProjectCase_Name__c,BatchClass__c FROM PSA_Autogen__mdt WHERE IsActive__c = true and BatchClass__c = 'PSA_AutogenProjectBatch_New']) 
        {
            allAutogenProductIdsSet.add(autogenData_mdt.id);
            if(autogenData_mdt.Product_Id__c != null)
            {
                allProductIdsSet.addAll(autogenData_mdt.Product_Id__c.split(','));
            }            
            //allProductIdsSet.add(autogenData_mdt.Product_Id__c);
            if(autogenData_mdt.Autogen_Usecase__c != null)
            {
                allAutogenUseCasesSet.addAll(autogenData_mdt.Autogen_Usecase__c.split(','));    
                for(String caseUseCase: autogenData_mdt.Autogen_Usecase__c.split(','))
                {
                    allCaseUseCaseToProjMap.put(caseUseCase,autogenData_mdt.ProjectCase_Name__c);
                }
            }
            
            allProjectCaseTypesSet.add(autogenData_mdt.ProjectCase_Name__c);
            allClassNamesSet.add(autogenData_mdt.ClassName__c);
        }   

        System.debug('@@@allProjectCaseTypesSet: '+allProjectCaseTypesSet);
        System.debug('@@@allClassNamesSet: '+allClassNamesSet);
        System.debug('@@@allAutogenProductIdsSet: '+allAutogenProductIdsSet);
        System.debug('@@@allProductIdsSet: '+allProductIdsSet);
        System.debug('@@@allAutogenUseCasesSet: '+allAutogenUseCasesSet);

        //PSA Project Template
        for (PSA_ProjectTemplates__mdt templates_mdt:[SELECT Name__c,Parent_Autogen__c, Sub_Type__c, Type__c FROM PSA_ProjectTemplates__mdt WHERE Parent_Autogen__c = :allAutogenProductIdsSet])
        {
            tNames.add(templates_mdt.Name__c);
            System.debug('@@@tNames:'+templates_mdt.Name__c);
            tTypes.add(templates_mdt.Type__c);
            System.debug('@@@tTypes:'+templates_mdt.Type__c);
            tSubTypes.add(templates_mdt.Sub_Type__c);
			System.debug('@@@tSubTypes:'+templates_mdt.Sub_Type__c);
        }

        
		
        
        //Fetch all the required Project Templates
        for (pse__Proj__c templateProject:[SELECT Id,name,pse__Allow_Self_Staffing__c,Ongoing_Project_Recurring_Budget_Amt__c,Ongoing_Project_Recurring_Planned_Hour__c,pse__Planned_Hours__c,pse__Allow_Timecards_Without_Assignment__c,pse__Is_Billable__c,pse__Time_Credited__c,pse__Time_Excluded__c,Months_from_Start_to_End_Date__c,pse__Daily_Timecard_Notes_Required__c,RecordtypeId,pse__Is_Active__c,pse__Project_Status__c,pse__Stage__c,pse__Practice__c,Project_Sub_Type__c,pse__Project_Type__c FROM pse__proj__c WHERE pse__Project_Type__c IN :tTypes AND Project_Sub_Type__c IN :tSubTypes AND Name IN :tNames AND pse__Is_Template__c = TRUE AND pse__Stage__c != 'Closed'])
        {
            nameToTemplate.put(templateProject.Name,templateProject);
        }

        System.debug('@@@nameToTemplate: '+nameToTemplate.keySet());
        
        
    }

    public Database.QueryLocator start(Database.BatchableContext BC) 
    {
        //Query Cases to fetch all autocreated cases created within the last two days
        autogenCaseQuery = 'SELECT id,Contract_Detail__c,Contract__c,Description,Autogen_UseCase__c, Subject ,ParentId,' +
            					' (SELECT id,Contract_Detail__c,Contract__c,Description,Autogen_UseCase__c, Subject ,ParentId FROM Cases WHERE Autogen_UseCase__c != NULL)' +
                                ' FROM case WHERE Autogen_UseCase__c in :allAutogenUseCasesSet AND' +
                                ' createddate = LAST_N_DAYS:2';


        //For the test class: Adding limit 5                       
        TestClass_Query = autogenCaseQuery + ' order by createddate desc limit 1'; 
        
        batchQuery = (System.Test.isRunningTest()) ? TestClass_Query : autogenCaseQuery;

        System.debug('@@@batchQuery: '+batchQuery);
        return Database.getQueryLocator(batchQuery);
    }

    public void execute(Database.BatchableContext BC, List<sObject> scope) 
    {
        System.debug('@@@Execute:scope: '+scope);
    	PSA_AutogenObjectList recordsForUpsert;

        //Get the cases List from scope
        List<Case> autogenCasesList = new List<Case>();
        autogenCasesList = scope;


    	//Variables for Project Case Association
    	List<Project_Case_Association__c> autogenProjectToCaseAssociationList = new List<Project_Case_Association__c>();

        System.debug('@@@allProjectCaseTypesSet: '+allProjectCaseTypesSet);
        System.debug('@@@autogenCasesList: '+autogenCasesList);
    	//Fetch Project To Case association records
        autogenProjectToCaseAssociationList = [
                                            SELECT Contract_Detail_Name__c,Contract_Detail__r.Name,Project__c,Contract__c,Contract_Detail__c,Case__c,Automated_Project_Type__c
                                            FROM Project_Case_Association__c
                                            WHERE 
                                                Automated_Project_Type__c in :allProjectCaseTypesSet AND
                                                Autogen_Project__c = TRUE AND
                                                Case__c in :autogenCasesList

        ];
        //test

        System.debug('@@@autogenProjectToCaseAssociationList: '+autogenProjectToCaseAssociationList);

        //Fetch existing contract details
        Set<String> existingCLINamesSet = new Set<String>();
        for(Project_Case_Association__c eachPca : autogenProjectToCaseAssociationList)
        {
            existingCLINamesSet.add(eachPca.Contract_Detail_Name__c);
        }

        System.debug('@@@existingCLINamesSet: '+existingCLINamesSet);


        //Variable for set of all contracts to fetch CLIs
        Set<Id> allContractIdsSet = new Set<Id>();
        //Get the list of all contract Ids and perMonthCLIs linked to the autogen cases

        //Remove all cases that have a PCA associated to it
        List<Case> newCasesList = new List<Case>();
        for(Case eachCase : autogenCasesList)
        {
            if(!existingCLINamesSet.contains(eachCase.Contract_Detail__c))
            {
                newCasesList.add(eachCase);
                allContractIdsSet.add(eachCase.Contract__c);
            }
        }

        System.debug('@@@newCasesList: '+newCasesList);        

        System.debug('@@@allContractIdsSet: '+allContractIdsSet);      
        System.debug('@@@existingCLINamesSet: '+existingCLINamesSet);  


        Date lastTwoDays = Date.today()-2;
        System.debug('@@@lastTwoDays: '+lastTwoDays);
		List<Merge_Contract_Detail__c> autogenClisList = new List<Merge_Contract_Detail__c>();
        //Fetch all CLIs that have a autogenCase created
        autogenClisList = [ 
                            SELECT Name,id,Original_Contract_Id__c,Unit_of_Measure__c,Product_Id__c,Record_Type__c,Effective_Start_Date__c,Effective_End_Date__c,createddate,Units_Low__c, Original_Contract_Id__r.Account_Name__r.TERR_HIER_5__c,Original_Contract_Id__r.Currency__c,Unit_Price__c,lastmodifieddate, Billing_Duration__c,Original_Detail_Id__c
                            FROM Merge_Contract_Detail__c
                            WHERE 
                                Original_Contract_Id__c in :allContractIdsSet AND
                                Product_Id__c in :allProductIdsSet AND
                                Name NOT in :existingCLINamesSet AND
                                //id NOT in :existingCLINamesSet AND
                                //Record_Type__c in ('Committed') AND
                                //Unit_of_Measure__c in ('Per Month','Configurations','Hours') AND
                                //Locked__c = true AND
                                //Cancellation_Date__c = Null AND
                                //Contract_Transferred_To__c = Null AND
                                //Effective_End_Date__c >= Today AND
                                //Effective_Start_Date__c <> null AND
                                //Effective_End_Date__c <> null AND
                                //Code Review by Sharath: wrong filter on effective start date
                                (
                                    createddate = LAST_N_DAYS:2 OR
                                    Effective_Start_Date__c > :lastTwoDays
                                )
        ];
	

        //System.debug('@@@autogenClisList: ');
        for(Merge_Contract_Detail__c ecli : autogenClisList)
        {
            System.debug('@@@: '+ecli);
        }
        //System.debug('@@@autogenClisList.size(): '+autogenClisList.size());   

        List<Case> casesForUpsert = new List<case>();
        List<pse__Proj__c> projectsForUpsert = new List<pse__Proj__c>();
        List<pse__Milestone__c> milestonesForUpsert = new List<pse__Milestone__c>();
        List<pse__Budget__c> budgetsForUpsert = new List<pse__Budget__c>() ;
        List<pse__Project_Methodology__c> productsForUpsert = new List<pse__Project_Methodology__c>();
        List<Project_Case_Association__c> pcaForUpsert = new List<Project_Case_Association__c>(); 

        //Call all the classes that need to be called
        for(String classNameToCall: allClassNamesSet)
        {
            System.debug('@@@Class Name: '+classNameToCall);
            PSA_AutogenInterface autogenClass = (PSA_AutogenInterface)Type.forName(classNameToCall).newInstance();
            List<Merge_Contract_Header__c> t = new List<Merge_Contract_Header__c>();
            recordsForUpsert = autogenClass.getContractDetailsForUpsert(t,autogenClisList,newCasesList,autogenProjectToCaseAssociationList,nameToTemplate);
            if(recordsForUpsert != null)
            {
                if(recordsForUpsert.casesForUpsert != null && !recordsForUpsert.casesForUpsert.isEmpty())
                {
                    casesForUpsert.addAll(recordsForUpsert.casesForUpsert);
                }
                if(recordsForUpsert.projectsForUpsert != null && !recordsForUpsert.projectsForUpsert.isEmpty())
                {
                    projectsForUpsert.addAll(recordsForUpsert.projectsForUpsert);
                }
                if(recordsForUpsert.milestonesForUpsert != null && !recordsForUpsert.milestonesForUpsert.isEmpty())
                {
                    milestonesForUpsert.addAll(recordsForUpsert.milestonesForUpsert);
                }
                if(recordsForUpsert.budgetsForUpsert != null && !recordsForUpsert.budgetsForUpsert.isEmpty())
                {
                    budgetsForUpsert.addAll(recordsForUpsert.budgetsForUpsert);
                }
                if(recordsForUpsert.productsForUpsert != null && !recordsForUpsert.productsForUpsert.isEmpty())
                {
                    productsForUpsert.addAll(recordsForUpsert.productsForUpsert);
                }

                if(recordsForUpsert.pcaForUpsert != null && !recordsForUpsert.pcaForUpsert.isEmpty())
                {
                    pcaForUpsert.addAll(recordsForUpsert.pcaForUpsert);
                }
            }

        }
    
        //Collect and create/update all project related objects at once
        List<pse__proj__c> insertedProjects = new List<pse__proj__c>();
        List<Id> projectInsertedIds = new List<Id>();
        Map<String,Id> projExternalIdToIdMap = new Map<String,Id>();
        Map<Id,Set<String>> contractIdToProducts = new Map<Id,Set<String>>();

        List<Database.UpsertResult> upsertResultRecords = new List<Database.UpsertResult>();
        List<Database.SaveResult> saveResultRecords = new List<Database.SaveResult>();

        Set<String> cliNamesSet = new Set<String>();
        List<Case> casesForDescriptionUpdateList = new List<Case>();

       
        System.debug('@@@projectsForUpsert: '+projectsForUpsert.size()+'  :  '+projectsForUpsert);

        System.debug('@@@casesForUpsert: '+casesForUpsert.size()+'  :  '+casesForUpsert);
        System.debug('@@@milestonesForUpsert: '+milestonesForUpsert.size()+'  :  '+milestonesForUpsert);
        System.debug('@@@budgetsForUpsert: '+budgetsForUpsert.size()+'  :  '+budgetsForUpsert);
        
        
        if(!projectsForUpsert.isEmpty())
        {
            upsertResultRecords = Database.Upsert(projectsForUpsert,false);
            
            PSA_AutoCreateProjectUtil.PopulateErrorTableForUpsert(upsertResultRecords, 'Projects');
            insertedProjects = new List<pse__Proj__c>();
            for(Database.UpsertResult project: upsertResultRecords)
            {
                System.debug('@@@upsertResultRecords :'+project.id+ ' '+project.isSuccess());
                if (project.isSuccess()) 
                {
                    projectInsertedIds.add(project.getId());
                }
            }
            

            insertedProjects = [select Id,External_id__c,Autogen_Product__c,Name,pse__Start_Date__c,pse__End_Date__c,Months_from_Start_to_End_Date__c,pse__Billing_Type__c,Project_Template__c,SMP_Contract__c,pse__Account__c,pse__Is_Billable__c,Ongoing_Project_Recurring_Budget_Amt__c,pse__Planned_Hours__c,SMP_Contract_Line_Item__c,SMP_Automated_Project__c,PCLI_PerMonth1__r.Name from pse__proj__c where Id in :projectInsertedIds];

            

            for(pse__Proj__c proj: insertedProjects)
            {
                projExternalIdToIdMap.put(proj.External_id__c,proj.Id);

                //Get the per month CLI from the project
                cliNamesSet.add(proj.PCLI_PerMonth1__r.Name);

                System.debug('@@@insertedProjects: '+proj);

                //if(!contractIdToProducts.containsKey(proj.SMP_Contract__c))
                //{
                //    contractIdToProducts.put(proj.SMP_Contract__c, new Set<String>());
                //}
                //contractIdToProducts.get(proj.SMP_Contract__c).add(proj.Autogen_Product__c);
            }
        }

        //if(!casesForUpsert.isEmpty())
        //{
        //    List<case> caseRecords = new List<case>();
        //    for(case caseRecord : casesForUpsert)
        //    {
        //        //System.debug('@@@caseRecord.Autogen_Usecase__c: '+caseRecord.Autogen_Usecase__c);
        //        if(caseRecord.Description.contains('Please note that a Salesforce project has been automatically created') || caseRecord.Description.contains('projects have been automatically created') || caseRecord.Description.contains('PROJECTS SUCCESSFULLY CREATED'))
        //        {
        //            if(contractIdToProducts.containsKey(caseRecord.contract__c) && contractIdToProducts.get(caseRecord.contract__c).contains(allCaseUseCaseToProjMap.get(caseRecord.Autogen_Usecase__c)))
        //            {
        //                caseRecords.add(caseRecord);
        //            }
        //        }
        //        else if(caseRecord.Description.contains('PROJECT NOT CREATED') || caseRecord.Description.contains('PROJECTS NOT CREATED'))
        //        {
        //            caseRecords.add(caseRecord);      
        //        }
        //    }
        //    saveResultRecords = Database.Update(caseRecords,False);
        //    PSA_AutoCreateProjectUtil.PopulateErrorTableForUpdate(saveResultRecords, casesForUpsert);
        //}

        
        if(!casesForUpsert.isEmpty())
        {
            for(Case eachCase : casesForUpsert)
            {
                if(cliNamesSet.contains(eachCase.Contract_Detail__c) || eachCase.Description.contains('none of the Salesforce projects have been automatically created'))
                {
                    casesForDescriptionUpdateList.add(eachCase);
                }
                System.debug('@@@Cases: '+eachCase);
                System.debug('@@@eachCase.DescriptionFinal: '+eachCase.Description);
                
            }
            saveResultRecords = Database.Update(casesForDescriptionUpdateList,False);
            PSA_AutoCreateProjectUtil.PopulateErrorTableForUpdate(saveResultRecords, casesForDescriptionUpdateList);
            System.debug(casesForDescriptionUpdateList.size());
        }


        if(!milestonesForUpsert.isEmpty())
        {
            List<pse__Milestone__c> milestoneRecords = new List<pse__Milestone__c>();
            for(pse__Milestone__c milestoneRecord : milestonesForUpsert)
            {
                if(projExternalIdToIdMap.containsKey(milestoneRecord.pse__Project__r.External_id__c))
                {
                    System.debug('@@@milestoneRecord: '+milestoneRecord);
                    milestoneRecords.add(milestoneRecord);
                }
            }
            upsertResultRecords = Database.Upsert(milestoneRecords,false);
            PSA_AutoCreateProjectUtil.PopulateErrorTableForUpsert(upsertResultRecords, 'Milestones');
        }

        if(!budgetsForUpsert.isEmpty())
        {
            List<pse__Budget__c> budgetRecords = new List<pse__Budget__c>();
            for(pse__Budget__c budgetRecord : budgetsForUpsert)
            {
                if(projExternalIdToIdMap.containsKey(budgetRecord.pse__Project__r.External_id__c))
                {
                    System.debug('@@@budgetRecord: '+budgetRecord);
                    budgetRecords.add(budgetRecord);
                }
            }

            upsertResultRecords = Database.Upsert(budgetRecords,false);
            PSA_AutoCreateProjectUtil.PopulateErrorTableForUpsert(upsertResultRecords, 'Budgets');
        }

        if(!productsForUpsert.isEmpty())
        {
            List<pse__Project_Methodology__c> productRecords = new List<pse__Project_Methodology__c>();
            for(pse__Project_Methodology__c productRecord : productsForUpsert)
            {
                if(projExternalIdToIdMap.containsKey(productRecord.pse__Project__r.External_id__c))
                {
                    System.debug('@@@productRecord: '+productRecord);
                    productRecords.add(productRecord);
                }
            }
            upsertResultRecords = Database.Upsert(productRecords,false);
            PSA_AutoCreateProjectUtil.PopulateErrorTableForUpsert(upsertResultRecords, 'Products');
        }

        if(insertedProjects != null && !insertedProjects.isEmpty())
        {
            System.debug('@@@insertedProjects: '+insertedProjects);
            PSA_AutoCreateProjectUtil.insertPCLItems(insertedProjects);

        }

        if(pcaForUpsert != null && !pcaForUpsert.isEmpty())
        {
            List<Project_Case_Association__c> projectCaseRecords = new List<Project_Case_Association__c>();
            for(Project_Case_Association__c projectCaseRecord : pcaForUpsert)
            {
                if(projExternalIdToIdMap.containsKey(projectCaseRecord.Project__r.External_id__c))
                {
                    System.debug('@@@projectCaseRecord: '+projectCaseRecord);
                    projectCaseRecords.add(projectCaseRecord);
                }
                System.debug('@@@projectCaseRecord: '+projectCaseRecord);
            }
            upsertResultRecords = Database.Upsert(projectCaseRecords,false);
            PSA_AutoCreateProjectUtil.PopulateErrorTableForUpsert(upsertResultRecords, 'ProjectCaseAssociation');
        }
               
    
        System.debug('@@@Final Inserts');
        System.debug('@@@projectInsertedIds: '+projectInsertedIds);


    }

    public void finish(Database.BatchableContext BC) 
    {
        
    }

}