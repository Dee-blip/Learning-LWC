/*
 * CR: 3368331
 * Developer: Sharath Prasanna
 * Enhancement: Automated creation of SF projects
 * Date: 15th September 2016
 * 
 Developer                        Date                            Changes
 Sharath Prasanna               18th October 2016               Changed the class for autogen project for MKSD   
 Akhila Vidapanapati            20-Dec-2016                     Changed the class for autogen project for GDS 
 Sharath Prasanna               14th Feb 2017                   Changed the class for CR 3588241: remove planned hours rounding off
 Sharath Ravishankar            14th Feb 2017                   Changed the class for autogen project for TAS 
                                                                as in CR 3562401
                                                               (Commented out the changes on 1st MAR 2017)
 Sharath Ravishankar            24th April 2017                   Changed the class for autogen project for PS-E as in CR 3562381
 Sharath Prasanna               23th June 2017                   Changed the class for FFPSA-180: For Autogen project of TAS 

 Sharath Prasanna               24th Oct 2017                   Changed the class for FFPSA-266: For the autogen of RRS    

 Sharath Prasanna               27th March 2018                 Changed the class for FFPSA-271: for the autogen of PS-Security

 sharath Prasanna               24th of Oct 2018                Changed the class for FFPSA-598: PNP
*/ 
public class PSA_AutogenProjectBatch implements Database.Batchable<sObject>,Database.Stateful 
{

    public Set<String> productIds = new Set<String>();
    
    public Set<String> autogenUseCase = new Set<String>();

    public Set<String> projectCaseTypes = new Set<String>();

    public Map<String,String> caseUseCaseToProj = new Map<String,String>();

    //This will contain the class names of the various products to be called.
    public Set<String> classNames = new Set<String>();

    //Changes for FFPSA-271
    public Set<Id> autogenProductIds = new Set<Id>();

    public string batchQuery = NULL;
    

    private string query;
    
    //Query string for test classes
    static String TestClass_Query = null;

    public PSA_AutogenProjectBatch() 
    {
        productIds.add('M-LC-160425');
        
        //Changes by sharath for MKSD
        productIds.add('M-LC-139829');

        //Changes by Akhila for GDS
        productIds.add('M-LC-159905');

        //Changes by Sharath Ravishankar for TAS
        //commenting the changes for TAS
        //Changes by Sharath Prasanna: Uncommenting the changes for TAS
        productIds.add('M-LC-134267');

        //Changes by Sharath Ravishankar for PS-E
        productIds.add('M-LC-135915');

        autogenUseCase.add('SOA-Parent');

        //Changes by sharath for MKSD
        autogenUseCase.add('KONA-COB-WithKSD');        
        autogenUseCase.add('KONA-COB-WithoutKSD');        

        //Changes by Akhila for GDS
        autogenUseCase.add('GDS-COB');

        // Changes by Sharath Ravishankar for TAS
        //commenting the changes for TAS
        //Changes by Sharath Prasanna: Uncommenting the changes for TAS
        autogenUseCase.add('TAS-COB');

        //Changes by Sharath Ravishankar for PS-E
        autogenUseCase.add('PSE-COB');

        projectCaseTypes.add('SOA');

        //Changes by Sharath for MKSD
        projectCaseTypes.add('MKSD');        
        
        //Changes by Akhila for GDS
        projectCaseTypes.add('GDS');

        // Changes by Sharath Ravishankar for TAS
        //commenting the changes for TAS
        //Changes by Sharath Prasanna: Uncommenting the changes for TAS
        projectCaseTypes.add('TAS');

        //Changes by Sharath Ravishankar for PS-E
        projectCaseTypes.add('PS-E');   

        //Changes by Sharath Prasanna: This will fetch all the active autogens from the metadata PSA_Autogen__mdt.
        //The loop adds the required values: product id, usecase name and the class name to the respective classes

        for(PSA_Autogen__mdt autogenData: [select id, Autogen_Usecase__c,ClassName__c,Product_Id__c,Product_Name__c,ProjectCase_Name__c,BatchClass__c from PSA_Autogen__mdt where IsActive__c = true and BatchClass__c = null]) 
        {
            autogenProductIds.add(autogenData.id);
            if(autogenData.Product_Id__c != null)
            {
                productIds.addAll(autogenData.Product_Id__c.split(','));
            }            
            //productIds.add(autogenData.Product_Id__c);
            if(autogenData.Autogen_Usecase__c != null)
            {
                autogenUseCase.addAll(autogenData.Autogen_Usecase__c.split(','));    
                for(String caseUseCase: autogenData.Autogen_Usecase__c.split(','))
                {
                    caseUseCaseToProj.put(caseUseCase,autogenData.ProjectCase_Name__c);
                }
            }
            
            projectCaseTypes.add(autogenData.ProjectCase_Name__c);
            classNames.add(autogenData.ClassName__c);
        }   
    }

    public Database.QueryLocator start(Database.BatchableContext BC) 
    {
        //This is a query on the Contract object that gets a List of all Contracts that satisfy the below criteria. This would return all valid contracts. 
        query =  'select Id,Account_Name__c,Effective_Start_Date__c,Effective_End_Date__c,' + 
                                'Name,Account_Name__r.Name,Account_Name__r.AKAM_Account_ID__c,' + 
                                'Opportunity_Name__r.Name, Opportunity_Name__r.AKAM_Opportunity_ID__c' +
                                ' from Merge_Contract_Header__c where ' +
                                ' Locked__c = true and ' +
                                ' Cancellation_Date__c = Null and '+
                                ' Contract_Transferred_To__c = Null and ' +
                              ' Effective_End_Date__c >= Today and ' +
                              ' Effective_Start_Date__c <> null and ' +
                              ' Effective_End_Date__c <> null';
        
        //For the test class: Adding limit 5                       
        TestClass_Query = query + ' order by createddate desc limit 1'; 
        
        batchQuery = (System.Test.isRunningTest()) ? TestClass_Query : query;
        //System.debug('Started the start method');
        return Database.getQueryLocator(batchQuery);
    }

    public void getSOAContractDetails(List<Merge_Contract_Header__c> ListContractScope,List<Merge_Contract_Detail__c> ListContractDetailstoCheck,List<Case> CasesCreated,List<Project_Case_Association__c> projectCases)
    {
        Map<Id,List<Merge_Contract_Detail__c>> mapContractContractDetails = new Map<Id,List<Merge_Contract_Detail__c>>();


        List<Merge_Contract_Detail__c> contractDetailForSOA = new List<Merge_Contract_Detail__c>();

        List<Case> casesForSOA = new List<Case>();
        Set<Id> ContractIds = new Set<Id>();
        //Loop over the cases and get all the cases with usecase value SOA-Parent
        for (Case caseToCheck: CasesCreated)
        {
            if(caseToCheck.Autogen_UseCase__c == 'SOA-Parent')
            {
                ContractIds.add(caseToCheck.Contract__c);
                casesForSOA.add(caseToCheck);
            }
        }

        //List<Project_Case_Association__c> projectCasesForSOA = new List<Project_Case_Association__c>();
        //loop over the projectcases and get all the records that has the Automated_Project_Type__c as SOA
        for (Project_Case_Association__c projectCaseToCheck: projectCases)
        {
            if(projectCaseToCheck.Automated_Project_Type__c == 'SOA')
            {
                if(ContractIds.contains(projectCaseToCheck.Contract__c))
                {
                    ContractIds.remove(projectCaseToCheck.Contract__c);
                }
                
            }
        }

        //loop over the contract details and get all those contract details that satisfy the requirements for the SOA project creation. that is, RecordType -> committed and Product_Id__c == 'M-LC-160425' and Unit of Measure -> Hour or Reviews or Per Month

        for(Merge_Contract_Detail__c detail: ListContractDetailstoCheck)
        {
            if(detail.Record_Type__c == 'Committed' && ((detail.Unit_of_Measure__c == 'Hour' && (detail.Billing_Duration__c == 'Monthly' || detail.Billing_Duration__c == 'Quarterly'))|| detail.Unit_of_Measure__c == 'Reviews' || detail.Unit_of_Measure__c == 'Per Month') && detail.Product_Id__c == 'M-LC-160425' && ContractIds.contains(detail.Original_Contract_Id__c))
            {
                //contractDetailForSOA.add(detail);
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
       //mapContractContractDetails = PSA_AutoCreateProjectUtil.getContractDetails(ListContractScope,contractDetailForSOA,casesForSOA,'SOA',projectCasesForSOA);
       //if there are valid contract details, call the funtion to create projects
       if(mapContractContractDetails != null && mapContractContractDetails.size() > 0)
       {
            CreateSOAProjects(mapContractContractDetails,casesForSOA); 
       }
       // if no details are found to conform to the SOA requirements, update all the SOA case descrption
       else if(casesForSOA != null && casesForSOA.size() > 0)
       {
            for (Case caseToUpdate: casesForSOA)
            {
                    if(ContractIds.contains(caseToUpdate.Contract__c))
                    {
                        if(caseToUpdate.description == null)
                        {
                            caseToUpdate.description = '';   
                        }

                       if(!(caseToUpdate.description.contains('PROJECTS NOT CREATED')))
                       {
                            caseToUpdate.Description += '\n\n<### PROJECTS NOT CREATED ###>\n\nPlease note that due to contract set-up Salesforce projects have not been automatically created.\n\nPlease follow these guidelines on how to create the projects:\nhttps://ac.akamai.com/docs/DOC-7177';
                       }

                    }

            }
            Database.Update(casesForSOA,False);
            
       }

    }

    //Change by Sharath for MKSD
    public void getMKSDContractDetails(List<Merge_Contract_Header__c> ListContractScope,List<Merge_Contract_Detail__c> ListContractDetailstoCheck,List<Case> CasesCreated,List<Project_Case_Association__c> projectCases)
    {
        Map<Id,List<Merge_Contract_Detail__c>> mapContractContractDetails = new Map<Id,List<Merge_Contract_Detail__c>>();


        List<Merge_Contract_Detail__c> contractDetailForMKSD = new List<Merge_Contract_Detail__c>();

        List<Case> casesForMKSD = new List<Case>();
        //This is the map of contract Id to case, this is used to not consider those cases that has associated projects
        Map<Id,Case> contractToCases = new Map<Id,Case>();
        Set<Id> ContractIds = new Set<Id>();
        //Loop over the cases and get all the cases with usecase value KONA-COB-WithoutKSD or KONA-COB-WithKSD
        for (Case caseToCheck: CasesCreated)
        {
            if(caseToCheck.Autogen_UseCase__c.contains('KONA-COB'))
            {
                ContractIds.add(caseToCheck.Contract__c);
                contractToCases.put(caseToCheck.Contract__c,caseToCheck);
            }
        }

        //loop over the projectcases and get all the records that has the Automated_Project_Type__c as MKSD
        for (Project_Case_Association__c projectCaseToCheck: projectCases)
        {
            if(projectCaseToCheck.Automated_Project_Type__c == 'MKSD')
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
            casesForMKSD = contractToCases.values();  
        }
        
        //loop over the contract details and get all those contract details that satisfy the requirements for the MKSD project creation. that is, RecordType -> committed and Product_Id__c == 'M-LC-139829' and Unit of Measure -> Hour or Policies or Per Month or Reviews

        for(Merge_Contract_Detail__c detail: ListContractDetailstoCheck)
        {
            if(detail.Record_Type__c == 'Committed' && ((detail.Unit_of_Measure__c == 'Hour' && (detail.Billing_Duration__c == 'Monthly' || detail.Billing_Duration__c == 'Quarterly'))|| detail.Unit_of_Measure__c == 'Reviews' || detail.Unit_of_Measure__c == 'Policies'  || detail.Unit_of_Measure__c == 'Per Month') && detail.Product_Id__c == 'M-LC-139829' && ContractIds.contains(detail.Original_Contract_Id__c))
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
       //mapContractContractDetails = PSA_AutoCreateProjectUtil.getContractDetails(ListContractScope,contractDetailForSOA,casesForSOA,'SOA',projectCasesForSOA);
       //if there are valid contract details, call the funtion to create projects
       if(mapContractContractDetails != null && mapContractContractDetails.size() > 0)
       {
            CreateMKSDProjects(mapContractContractDetails,casesForMKSD); 
       }
       // if no details are found to conform to the SOA requirements, update all the SOA case descrption
       else if(casesForMKSD != null && casesForMKSD.size() > 0)
       {
            for (Case caseToUpdate: casesForMKSD)
            {
                    if(ContractIds.contains(caseToUpdate.Contract__c))
                    {
                        if(caseToUpdate.description == null)
                        {
                            caseToUpdate.description = '';   
                        }

                       if(!(caseToUpdate.description.contains('PROJECTS NOT CREATED')))
                       {
                            caseToUpdate.Description += '\n\n<### PROJECTS NOT CREATED ###>\n\nPlease note that due to contract set-up Salesforce projects have not been automatically created.\n\nPlease follow these guidelines on how to create the projects:\nhttps://ac.akamai.com/docs/DOC-5522';
                       }

                    }

            }
            Database.Update(casesForMKSD,False);
            
       }

    }
  //End of changes by sharath for MKSD

    //Changes by Akhila for GDS
    public void getGDSContractDetails(List<Merge_Contract_Header__c> ListContractScope,List<Merge_Contract_Detail__c> ListContractDetailstoCheck,List<Case> CasesCreated,List<Project_Case_Association__c> projectCases)
    {
        Map<Id,List<Merge_Contract_Detail__c>> mapContractContractDetails = new Map<Id,List<Merge_Contract_Detail__c>>();

        List<Merge_Contract_Detail__c> contractDetailForGDS = new List<Merge_Contract_Detail__c>();
        //This is the map of contract Id to case, this is used to not consider those cases that has associated projects
        Map<Id,Case> contractToCases = new Map<Id,Case>();
        List<Case> casesForGDS = new List<Case>();
        Set<Id> ContractIds = new Set<Id>();
        //Loop over the cases and get all the cases with usecase value GDS-COB
        for (Case caseToCheck: CasesCreated)
        {
            if(caseToCheck.Autogen_UseCase__c == 'GDS-COB')
            {
                ContractIds.add(caseToCheck.Contract__c);
                contractToCases.put(caseToCheck.Contract__c,caseToCheck);
            }
        }

        //loop over the projectcases and get all the records that has the Automated_Project_Type__c as GDS
        for (Project_Case_Association__c projectCaseToCheck: projectCases)
        {
            if(projectCaseToCheck.Automated_Project_Type__c == 'GDS')
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
            casesForGDS = contractToCases.values();
        }

        //loop over the contract details and get all those contract details that satisfy the requirements for the GDS project creation. that is, RecordType -> committed and Product_Id__c == 'M-LC-159905' and Unit of Measure -> 'Unit' or Per Month'
        for(Merge_Contract_Detail__c detail: ListContractDetailstoCheck)
        {
            if(detail.Record_Type__c == 'Committed' && (detail.Unit_of_Measure__c == 'Unit' || detail.Unit_of_Measure__c == 'Per Month') && detail.Product_Id__c == 'M-LC-159905' && ContractIds.contains(detail.Original_Contract_Id__c))
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
            CreateGDSProjects(mapContractContractDetails,casesForGDS); 
       }

       //if no details are found to conform to the GDS requirements, update all the GDS case descrption
       else if(casesForGDS != null && casesForGDS.size() > 0)
       {
            for (Case caseToUpdate: casesForGDS)
            {
                    if(ContractIds.contains(caseToUpdate.Contract__c))
                    {
                        if(caseToUpdate.description == null)
                        {
                            caseToUpdate.description = '';   
                        }

                        if(!(caseToUpdate.description.contains('PROJECT NOT CREATED')))
                        {
                            caseToUpdate.Description += '\n\n<<### PROJECT NOT CREATED ###>\n\nPlease note that due to contract set-up the Salesforce project has not been automatically created.\n\nPlease follow these guidelines on how to create the projects:\nhttps://ac.akamai.com/docs/DOC-8302#jive_content_id_Manual_Project_Creation';
                        }
                    }

            }
            Database.Update(casesForGDS,False);
       }        
    }
    //End of changes by Akhila for GDS

    //Changes by Sharath Ravishankar for TAS
    //commenting the changes for TAS
    //Changes by Sharath Prasanna: Uncommenting the changes for TAS for FFPSA-180
        
    public void getTASContractDetails(List<Merge_Contract_Header__c> ListContractScope,List<Merge_Contract_Detail__c> ListContractDetailstoCheck,List<Case> CasesCreated,List<Project_Case_Association__c> projectCases)
    {
        Map<Id,List<Merge_Contract_Detail__c>> mapContractContractDetails = new Map<Id,List<Merge_Contract_Detail__c>>();

        List<Merge_Contract_Detail__c> contractDetailForTAS = new List<Merge_Contract_Detail__c>();
        //This is the map of contract Id to case, this is used to not consider those cases that has associated projects
        Map<Id,Case> contractToCases = new Map<Id,Case>();
        List<Case> casesForTAS = new List<Case>();
        Set<Id> ContractIds = new Set<Id>();
        //Loop over the cases and get all the cases with usecase value TAS
        for (Case caseToCheck: CasesCreated)
        {
            if(caseToCheck.Autogen_UseCase__c == 'TAS-COB')
            {
                ContractIds.add(caseToCheck.Contract__c);
                contractToCases.put(caseToCheck.Contract__c,caseToCheck);
            }
        }

        //loop over the projectcases and get all the records that has the Automated_Project_Type__c as TAS
        for (Project_Case_Association__c projectCaseToCheck: projectCases)
        {
            if(projectCaseToCheck.Automated_Project_Type__c == 'TAS')
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
            casesForTAS = contractToCases.values();
        }

        //loop over the contract details and get all those contract details that satisfy the requirements for the TAS project creation. that is, RecordType -> committed and Product_Id__c == 'M-LC-134267' and Unit of Measure -> 'Hour' or Per Month' or 'Business Days'. The effective start date should not be in the future
        for(Merge_Contract_Detail__c detail: ListContractDetailstoCheck)
        {
            if(detail.Record_Type__c == 'Committed' &&  detail.Effective_Start_Date__c <= system.today() && (  ((detail.Unit_of_Measure__c == 'Hour' || detail.Unit_of_Measure__c == 'Business Days' ) && ( detail.Billing_Duration__c=='Monthly' || detail.Billing_Duration__c == 'Quarterly' || detail.Billing_Duration__c == 'Semi-Annual' || detail.Billing_Duration__c == 'Annual' ))  || detail.Unit_of_Measure__c == 'Per Month'  ) && detail.Product_Id__c == 'M-LC-134267' && ContractIds.contains(detail.Original_Contract_Id__c))
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
            CreateTASProjects(mapContractContractDetails,casesForTAS); 
       }

       //if no details are found to conform to the TAS requirements, update all the TAS case descrption
       else if(casesForTAS != null && casesForTAS.size() > 0)
       {

            for (Case caseToUpdate: casesForTAS)
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
            Database.Update(casesForTAS,False);
       }        
    }
    
    //End of changes by Sharath Ravishankar for TAS

    public void execute(Database.BatchableContext BC, List<sObject> scope) 
    {
       List<Merge_Contract_Header__c> ListContractScope = new List<Merge_Contract_Header__c>();
       ListContractScope = scope;
       List<Merge_Contract_Detail__c> ListContractDetailstoCheck = new List<Merge_Contract_Detail__c>();    
    
       List<Case> CasesCreated = new List<Case>();
       List<Project_Case_Association__c> projectCases = new  List<Project_Case_Association__c>();
       
       // The below query fetches the List of all Contract Details that are created in the last 2 days or the effective start date is in the last 2 days with the Original Contract Id in the List ListContractScope. 
       ListContractDetailstoCheck = [select Id,Units_Low__c,Units_High__c,CurrencyIsoCode,Unit_of_Measure__c,Billing_Duration__c,Unit_Price__c,Product_Id__c, Product__c, 
                                     Original_Contract_Id__c,Original_Contract_Id__r.Currency__c,Original_Contract_Id__r.Account_Name__c,Original_Contract_Id__r.Account_Name__r.TERR_HIER_5__c,Effective_Start_Date__c,Effective_End_Date__c, 
                                     CreatedDate,LastModifiedDate,Record_Type__c from Merge_Contract_Detail__c where (CreatedDate = LAST_N_DAYS:2 OR Effective_Start_Date__c = LAST_N_DAYS:2) and Product_Id__c in :productIds
                                     and Original_Contract_Id__c in:ListContractScope];

       //The below query fetches a List of all Cases created in the last 2 days with the autogen use case field set to one of the possible values in the set autogenUseCase.
       CasesCreated = [select Id,Description ,Contract__c,Autogen_UseCase__c, Service__c from Case where CreatedDate = LAST_N_DAYS:2 and Autogen_UseCase__c in :autogenUseCase and Contract__c in :ListContractScope];

        // Project case association object has 3 lookups - Contract, Project and Case. It also has a field called Autogen_Project__c . This is set to true by this class. Automated_Project_Type__c field is stamped with the product name.

       projectCases = [select Id,Contract__c,Automated_Project_Type__c from Project_Case_Association__c where Contract__c in :ListContractScope and Autogen_Project__c = TRUE and Automated_Project_Type__c in  : projectCaseTypes]; 

       //changes by Sharath Prasanna: for FFPSA-271: Creating the list to perform upserts
        List<Case> casesForUpsert = new List<case>();
        List<pse__Proj__c> projectsForUpsert = new List<pse__Proj__c>();
        List<pse__Milestone__c> milestonesForUpsert = new List<pse__Milestone__c>();
        List<pse__Budget__c> budgetsForUpsert = new List<pse__Budget__c>() ;
        List<pse__Project_Methodology__c> productsForUpsert = new List<pse__Project_Methodology__c>();
        List<Project_Case_Association__c> pcaForUpsert = new List<Project_Case_Association__c>();    

        List<String> tNames = new List<String>();
        List<String> tTypes = new List<String>();
        List<String> tSubTypes = new List<String>();

        PSA_AutogenObjectList recordsForUpsert;

        List<Database.UpsertResult> upsertResultRecords = new List<Database.UpsertResult>();
        List<Database.SaveResult> saveResultRecords = new List<Database.SaveResult>();

        Map<String,pse__Proj__c> nameToTemplate = new Map<String,pse__Proj__c>();

       if(ListContractDetailstoCheck != null && ListContractDetailstoCheck.size() >0 && CasesCreated != null && CasesCreated.size() > 0)
       {
               //Get the contract details to check for SOA product

               getSOAContractDetails(ListContractScope,ListContractDetailstoCheck,CasesCreated,projectCases);

               //Changes by Sharath for MKSD
               //Get the contract details to check for MKSD product 
               getMKSDContractDetails(ListContractScope,ListContractDetailstoCheck,CasesCreated,projectCases);                

               //Changes by Akhila for GDS 
               //Get the contract details to check for GDS product
               getGDSContractDetails(ListContractScope,ListContractDetailstoCheck,CasesCreated,projectCases);

               //Changes done by Sharath Ravishankar for PSE
               //Get the contract details to check for PSE product
               PSA_AutoCreatePSProject psProj = new PSA_AutoCreatePSProject();
               psProj.getPSEContractDetails(ListContractScope,ListContractDetailstoCheck,CasesCreated,projectCases);

               // Changes by Sharath Ravishankar for TAS
               //Get the contract details to check for TAS product
               //System.debug('\n\ncalling TAS contractdetails\n\n');
               //commenting the changes for TAS
               //Changes by Sharath: Uncommenting changes for TAS
               getTASContractDetails(ListContractScope,ListContractDetailstoCheck,CasesCreated,projectCases);

                for (PSA_ProjectTemplates__mdt templates :[select Name__c,Parent_Autogen__c, Sub_Type__c, Type__c from PSA_ProjectTemplates__mdt where Parent_Autogen__c = :autogenProductIds])
                {
                    tNames.add(templates.Name__c);
                    tTypes.add(templates.Type__c);
                    tSubTypes.add(templates.Sub_Type__c);

                }
                for (pse__Proj__c templateProject: [SELECT Id,name,pse__Allow_Self_Staffing__c,Ongoing_Project_Recurring_Budget_Amt__c,Ongoing_Project_Recurring_Planned_Hour__c,
                                     pse__Planned_Hours__c,pse__Allow_Timecards_Without_Assignment__c,pse__Is_Billable__c,pse__Time_Credited__c,
                                     pse__Time_Excluded__c,Months_from_Start_to_End_Date__c,pse__Daily_Timecard_Notes_Required__c,
                                     RecordtypeId,pse__Is_Active__c,pse__Project_Status__c,pse__Stage__c,pse__Practice__c,
                                     Project_Sub_Type__c,pse__Project_Type__c FROM pse__proj__c 
                                     WHERE pse__Project_Type__c IN :tTypes AND Project_Sub_Type__c IN :tSubTypes AND 
                                     Name IN :tNames AND pse__Is_Template__c = TRUE ])
                {
                    nameToTemplate.put(templateProject.Name,templateProject);
                }

               for(String classNameToCall: classNames)
               {
                    PSA_AutogenInterface autogenClass = (PSA_AutogenInterface)Type.forName(classNameToCall).newInstance();
                    if(classNameToCall == 'PSA_AutoCreateRRS')
                    {
                        autogenClass.getContractDetails(ListContractScope,ListContractDetailstoCheck,CasesCreated,projectCases);

                    }
                    else
                    {
                        recordsForUpsert = autogenClass.getContractDetailsForUpsert(ListContractScope,ListContractDetailstoCheck,CasesCreated,projectCases,nameToTemplate);
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
                    
               }

               //changes by Sharath for FFPSA-272

               List<pse__proj__c> insertedProjects = new List<pse__proj__c>();
               List<Id> projectInsertedIds = new List<Id>();
               Map<String,Id> projExternalIdToId = new Map<String,Id>();
               Map<Id,Set<String>> contractIdToProducts = new Map<Id,Set<String>>();
               
               if(!projectsForUpsert.isEmpty())
               {
                    upsertResultRecords = Database.Upsert(projectsForUpsert,false);
                    PSA_AutoCreateProjectUtil.PopulateErrorTableForUpsert(upsertResultRecords, 'Projects');
                    insertedProjects = new List<pse__Proj__c>();
                    for(Database.UpsertResult project: upsertResultRecords)
                    {
                          if (project.isSuccess()) 
                          {                                
                                projectInsertedIds.add(project.getId());
                          }
                    }

                    insertedProjects = [select Id,External_id__c,Autogen_Product__c,Name,pse__Start_Date__c,pse__End_Date__c,Months_from_Start_to_End_Date__c,pse__Billing_Type__c,Project_Template__c,SMP_Contract__c,pse__Account__c,pse__Is_Billable__c,Ongoing_Project_Recurring_Budget_Amt__c,pse__Planned_Hours__c,SMP_Contract_Line_Item__c,SMP_Automated_Project__c from pse__proj__c where Id in :projectInsertedIds];
                    for(pse__Proj__c proj: insertedProjects)
                    {
                        projExternalIdToId.put(proj.External_id__c,proj.Id);
                        if(!contractIdToProducts.containsKey(proj.SMP_Contract__c))
                        {
                            contractIdToProducts.put(proj.SMP_Contract__c, new Set<String>());   
                        }
                        contractIdToProducts.get(proj.SMP_Contract__c).add(proj.Autogen_Product__c);
                    }
               }
               if(!casesForUpsert.isEmpty())
               {

                    List<case> caseRecords = new List<case>();
                    for(case caseRecord : casesForUpsert)
                    {                                                  
                        if(caseRecord.Description.contains('Please note that a Salesforce project has been automatically created') || caseRecord.Description.contains('projects have been automatically created') || caseRecord.Description.contains('PROJECTS SUCCESSFULLY CREATED'))
                        {

                             if(contractIdToProducts.containsKey(caseRecord.contract__c) && contractIdToProducts.get(caseRecord.contract__c).contains(caseUseCaseToProj.get(caseRecord.Autogen_Usecase__c)))
                            {
                                caseRecords.add(caseRecord);
                            }
                        }    
                        else if(caseRecord.Description.contains('PROJECT NOT CREATED') || caseRecord.Description.contains('PROJECTS NOT CREATED'))
                        {
                            caseRecords.add(caseRecord);      
                        }
                    }
                    saveResultRecords = Database.Update(caseRecords,False);
                    PSA_AutoCreateProjectUtil.PopulateErrorTableForUpdate(saveResultRecords, casesForUpsert);
               }
               if(!milestonesForUpsert.isEmpty())
               {
                    List<pse__Milestone__c> milestoneRecords = new List<pse__Milestone__c>();
                    for(pse__Milestone__c milestoneRecord : milestonesForUpsert)
                    {
                        if(projExternalIdToId.containsKey(milestoneRecord.pse__Project__r.External_id__c))
                        {
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
                        if(projExternalIdToId.containsKey(budgetRecord.pse__Project__r.External_id__c))
                        {
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
                        if(projExternalIdToId.containsKey(productRecord.pse__Project__r.External_id__c))
                        {
                            productRecords.add(productRecord);
                        }
                    }
                    upsertResultRecords = Database.Upsert(productRecords,false);
                    PSA_AutoCreateProjectUtil.PopulateErrorTableForUpsert(upsertResultRecords, 'Products');

               }
               if(insertedProjects != null && !insertedProjects.isEmpty())
               {
                    PSA_AutoCreateProjectUtil.insertPCLItems(insertedProjects); 
               }
               if(pcaForUpsert != null && !pcaForUpsert.isEmpty())
               {
                    List<Project_Case_Association__c> projectCaseRecords = new List<Project_Case_Association__c>();
                    for(Project_Case_Association__c projectCaseRecord : pcaForUpsert)
                    {
                        if(projExternalIdToId.containsKey(projectCaseRecord.Project__r.External_id__c))
                        {
                            projectCaseRecords.add(projectCaseRecord);
                        }
                    }
                    upsertResultRecords = Database.Upsert(projectCaseRecords,false);
                    PSA_AutoCreateProjectUtil.PopulateErrorTableForUpsert(upsertResultRecords, 'ProjectCaseAssociation');

               }
               
       } 
    
    }

    //creates the SOA projects
    public void CreateSOAProjects(Map<Id,List<Merge_Contract_Detail__c>> mapContractContractDetails,List<Case> casesForSOA)
    {

        List<Database.UpsertResult> upsertResultRecords = new List<Database.UpsertResult>();
        List<Database.SaveResult> saveResultRecords = new List<Database.SaveResult>();
        List<pse__proj__c>ListProj2Insert = new List<pse__proj__c>();
        List<pse__Budget__c> ListBudget2Insert = new List<pse__Budget__c>();
        List<Id> ProjectInsertedIds = new List<Id>();

        List<pse__Proj__c> insertedProjects = new List<pse__proj__c>();

        List<Case> CaseSuccessfulUpdate = new List<Case>();
        List<Case> CaseUnsuccessfulUpdate = new List<Case>();
        List<pse__Budget__c> budgetsToUpdate = new List<pse__Budget__c>();
        List<Project_Case_Association__c> projectCases2Insert = new List<Project_Case_Association__c>();

        //Query for the Config template.
        pse__proj__c projectTemplate1 =[select Id,pse__Allow_Self_Staffing__c,Ongoing_Project_Recurring_Budget_Amt__c,Ongoing_Project_Recurring_Planned_Hour__c,
                             pse__Planned_Hours__c,pse__Allow_Timecards_Without_Assignment__c,pse__Is_Billable__c,pse__Time_Credited__c,
                             pse__Time_Excluded__c,Months_from_Start_to_End_Date__c,pse__Daily_Timecard_Notes_Required__c,RecordtypeId,pse__Is_Active__c,pse__Project_Status__c,
                             pse__Stage__c,pse__Practice__c,Project_Sub_Type__c,pse__Project_Type__c from pse__proj__c 
                             where pse__Project_Type__c = 'GSS Product' and Project_Sub_Type__c = 'Security Optimization Assistance' and Name like '%Config%'and pse__Is_Template__c = TRUE limit 1];

        //Query for the Service template.
        pse__proj__c projectTemplate2 =[select Id,pse__Allow_Self_Staffing__c,Ongoing_Project_Recurring_Budget_Amt__c,Ongoing_Project_Recurring_Planned_Hour__c,
                          pse__Planned_Hours__c,pse__Allow_Timecards_Without_Assignment__c,pse__Is_Billable__c,pse__Time_Credited__c,
                          pse__Time_Excluded__c,pse__Daily_Timecard_Notes_Required__c,RecordtypeId,pse__Is_Active__c,pse__Project_Status__c,
                          pse__Stage__c,pse__Practice__c,Project_Sub_Type__c,pse__Project_Type__c from pse__proj__c 
                          where pse__Project_Type__c = 'GSS Product' and Project_Sub_Type__c = 'Security Optimization Assistance' and Name like '%Service%' and pse__Is_Template__c = TRUE limit 1];
        //if either of the project templates are null -> return and send a mail to the engg team
        if(projectTemplate1 == null || projectTemplate2 == null)
        {
            PSA_AutoCreateProjectUtil.sendErrorMails('SOA Templates not found','The SOA templates are not found');
            return;
        }
        Id projectTemplate1Id = projectTemplate1.Id;
        
        Id projectTemplate2Id = projectTemplate2.Id;

        //the below custom setting is set to PSA User and we have a validation rule that does not allow TC entry when the project mgr is PSA user.
        PSA_Settings__c psa_settings = PSA_Settings__c.getInstance('Project Manager');

        //loop through the List of Contracts
        for(Id cId:mapContractContractDetails.keySet())
        {
            //System.debug('PSA Contracts to be checked:' + cId);
            //System.debug((mapContractContractDetails.get(cId)).size());
            if((mapContractContractDetails.get(cId)).size() == 3)
            {
                //System.debug('Inside size = 3' + mapContractContractDetails.get(cId));

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
                if(UOMToIndex.containsKey('Hour') && UOMToIndex.containsKey('Reviews') && UOMToIndex.containsKey('Per Month') )
                {  
                    Integer hour = UOMToIndex.get('Hour');
                    Integer review = UOMToIndex.get('Reviews');
                    Integer month = UOMToIndex.get('Per Month');
                    Double monthlyRecurringHours;
                    Integer noOfActiveMonthsHour;
                    Integer noOfActiveMonthsReview;
                    Double pricePerMonth;
                    Double  securityServiceReviews;
                    Double ongoingRecurringBudgetAmount;
                    //Changes by Sharath Prasanna for CR 3588241 : Changing planned hours to Double
                    //Integer PlannedHours;                    
                    Double PlannedHours;                  
                    
                    monthlyRecurringHours = PSA_AutoCreateProjectUtil.monthlyRecurringHours((mapContractContractDetails.get(cId))[hour]);
                    noOfActiveMonthsHour = PSA_AutoCreateProjectUtil.numberOfActiveMonths((mapContractContractDetails.get(cId))[hour].Effective_Start_Date__c,(mapContractContractDetails.get(cId))[hour].Effective_End_Date__c);

                    securityServiceReviews = PSA_AutoCreateProjectUtil.securityServiceReviews((mapContractContractDetails.get(cId))[review]);
                    noOfActiveMonthsReview = PSA_AutoCreateProjectUtil.numberOfActiveMonths((mapContractContractDetails.get(cId))[review].Effective_Start_Date__c,(mapContractContractDetails.get(cId))[review].Effective_End_Date__c);
                    pricePerMonth = PSA_AutoCreateProjectUtil.pricePerMonth((mapContractContractDetails.get(cId))[month]);
                    //The formula for the ongoingRecurringBudgetAmount can result in Exceptions -> divide by zero or zero by zero errors. in this case set the value to 0
                    try
                    {
                        ongoingRecurringBudgetAmount = ((monthlyRecurringHours * noOfActiveMonthsHour) / ((monthlyRecurringHours * noOfActiveMonthsHour) + (securityServiceReviews * 20.0)) ) * (pricePerMonth) / noOfActiveMonthsHour;

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
                    //Changes by Sharath Prasanna for CR 3588241: removing the rounding off of planned hours
                    //PlannedHours = Math.round(monthlyRecurringHours * noOfActiveMonthsHour);
                    PlannedHours = monthlyRecurringHours * noOfActiveMonthsHour;
                    //Planned Hours has to be 1 for non-internal projects
                    if(PlannedHours == 0.0)
                    {
                        PlannedHours = 1.0;   
                    }
                    //createProjectWithTemplate(name,template,contractId,detail,product,mrr, overrage,permonth,  billingType, ongoingRecurringBudgetAmount, plannedHours)

                    project1 = PSA_AutoCreateProjectUtil.createProjectWithTemplate('Security Optimization Assistance_Config_Assistance',projectTemplate1,cId,(mapContractContractDetails.get(cId))[hour],'SOA',(mapContractContractDetails.get(cId))[hour].Id, (mapContractContractDetails.get(cId))[review].Id, (mapContractContractDetails.get(cId))[month].Id, billingType,ongoingRecurringBudgetAmount,PlannedHours);                    
                    

                    ListProj2Insert.add(project1);
                    //The formula for the ongoingRecurringBudgetAmount can result in Exceptions -> divide by zero or zero by zero errors. in this case set the value to 0

                    try
                    {
                        ongoingRecurringBudgetAmount = ((securityServiceReviews * 20.0) / ((monthlyRecurringHours * noOfActiveMonthsReview) + (securityServiceReviews * 20.0)) ) * (pricePerMonth) / noOfActiveMonthsReview;

                    }
                    catch(Exception e)
                    {
                        ongoingRecurringBudgetAmount = 0;
                    }


                    pse__proj__c project2 = new pse__proj__c();                   
                    //createProjectWithTemplate(name,template,contractId,detail,product,mrr, overrage,permonth,  billingType, ongoingRecurringBudgetAmount, plannedHours)

                    //Changes by Sharath Prasanna for CR 3588241: removing the rounding off
                    //PlannedHours = Math.round(securityServiceReviews * 20.0);
                    PlannedHours = securityServiceReviews * 20.0;
                    if(PlannedHours == 0.0)
                    {
                        PlannedHours = 1.0;   
                    }

                    project2 = PSA_AutoCreateProjectUtil.createProjectWithTemplate('Security Optimization Assistance_Service_Review',projectTemplate2,cId,(mapContractContractDetails.get(cId))[review],'SOA',(mapContractContractDetails.get(cId))[hour].Id, (mapContractContractDetails.get(cId))[review].Id, (mapContractContractDetails.get(cId))[month].Id, 'One-Time: Fixed Price',ongoingRecurringBudgetAmount,PlannedHours);                    
                    ListProj2Insert.add(project2);
                    //System.debug('Sam OS Project Added');
                    
                    
                }
            }
        }
        //List<Database.UpsertResult> projectResults;
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

        //ProjectInsertedIds.addAll(successIds);
        //query for the inserted projects
        insertedProjects = [select Id,Name,pse__Start_Date__c,pse__End_Date__c,Months_from_Start_to_End_Date__c,pse__Billing_Type__c,Project_Template__c,SMP_Contract__c,pse__Account__c,pse__Is_Billable__c,Ongoing_Project_Recurring_Budget_Amt__c,pse__Planned_Hours__c,SMP_Contract_Line_Item__c,SMP_Automated_Project__c from pse__proj__c where Id in :ProjectInsertedIds];
        Boolean successfulCase = False;
        Map<Id,List<pse__Proj__c>> contractToProjects = new Map<Id,List<pse__Proj__c>>();

        //Create a map of contract to list of projects -> 1 contract should be linked to 2 projects
        for(pse__proj__c p1:insertedProjects)
        {
            if(!contractToProjects.containsKey(p1.SMP_Contract__c))
            {
                contractToProjects.put(p1.SMP_Contract__c,new List<pse__Proj__c>());    
            }            
            contractToProjects.get(p1.SMP_Contract__c).add(p1);
        }
        //Loop over the cases: create the Project_Case_Association__c record for each of the project created. if the project is not created for a case -> update the description 
        for(case c1:casesForSOA)
        {
           successfulCase = False;
             if(contractToProjects.containsKey(c1.contract__c))
             {  
                Project_Case_Association__c pca1;  
                for(pse__Proj__c p1: contractToProjects.get(c1.contract__c))
                {
                     if(p1.Name.contains('Config'))
                     {
                        pca1 = PSA_AutoCreateProjectUtil.createProjectCaseAssociationRecord(p1.Id,c1.Id,c1.contract__c,'Security Optimization Assistance_Config_Assistance','SOA');
                     }
                     else
                     {
                        pca1 = PSA_AutoCreateProjectUtil.createProjectCaseAssociationRecord(p1.Id,c1.Id,c1.contract__c,'Security Optimization Assistance_Service_Review','SOA');

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
          String errorMessage = '\n\n<### PROJECTS NOT CREATED ###>\n\nPlease note that due to contract set-up Salesforce projects have not been automatically created.\n\nPlease follow these guidelines on how to create the projects:\nhttps://ac.akamai.com/docs/DOC-7177';

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
        //System.debug('Sam Project Case DML Insert');

        //To create the budget with specific name -> create a map of project name to budget name. This is to be passed as the second parameter
        Map<String,String> ProjectNametoBudgetName = new Map<String,String>();
        ProjectNametoBudgetName.put('Config','Security Optimization Assistance_(CA)');
        ProjectNametoBudgetName.put('Service','Security Optimization Assistance_(SR)');

        // createBudgetWithName(projects, type, ProjectNametoBudgetName)
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
       List<String> setAmountFromProject = new List<String>();
       setAmountFromProject.add('Security Config. Assist.');
       Map<String,Integer> setDefaultPlannedHoursProjectToHours = new Map<String,Integer>();
       setDefaultPlannedHoursProjectToHours.put('Service',20);

       //createMilestones (List<pse__Proj__c> projects, List<String> setAmountFromProject,List<String> setPlannedhoursFromProject, Map<String,Double> setDefaultAmountProjectToAmount,Map<String,Integer> setDefaultPlannedHoursProjectToHours)
        milestones = PSA_AutoCreateProjectUtil.createMilestones(insertedProjects,setAmountFromProject,setAmountFromProject,null,setDefaultPlannedHoursProjectToHours);
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

       //The ProjectProducts creation:
       List<String> products = new List<String>();
       products.add('Kona Site Defender');
       products.add('Web Application Firewall');
       products.add('Bot Manager');
       products.add('Prolexic Routed');
       products.add('Prolexic Connect');
       PSA_AutoCreateProjectUtil.createProjectProducts(ProjectInsertedIds,products);



    }

    //Changes by Sharath for MKSD : creates the MKSD projects
    public void CreateMKSDProjects(Map<Id,List<Merge_Contract_Detail__c>> mapContractContractDetails,List<Case> casesForMKSD)
    {
        List<Database.UpsertResult> upsertResultRecords = new List<Database.UpsertResult>();
        List<Database.SaveResult> saveResultRecords = new List<Database.SaveResult>();
        List<pse__proj__c>ListProj2Insert = new List<pse__proj__c>();
        List<pse__Budget__c> ListBudget2Insert = new List<pse__Budget__c>();
        List<Id> ProjectInsertedIds = new List<Id>();

        List<pse__Proj__c> insertedProjects = new List<pse__proj__c>();

        List<Case> CaseSuccessfulUpdate = new List<Case>();
        List<Case> CaseUnsuccessfulUpdate = new List<Case>();
        List<pse__Budget__c> budgetsToUpdate = new List<pse__Budget__c>();
        List<Project_Case_Association__c> projectCases2Insert = new List<Project_Case_Association__c>();

        //contractToMilestoneAmount maps the Contract Id to the milestone amount for the TR project. This is used to compute the milestone amount
        Map<Id,Double> contractToMilestoneAmount = new Map<Id,Double>();
        //projectToMilestoneAmount maps the project Id to the milestone amount for the TR project. This is used to compute the milestone amount
        Map<Id,Double> projectToMilestoneAmount = new Map<Id,Double>();

        //projectToActiveMonths maps the project Id to the number of active months for the SCSM project. This is used to compute the planned hours of milestone
        Map<Id,Integer> projectToActiveMonths = new Map<Id,Integer>();
        
        //Query for the TR template.
        pse__proj__c projectTemplateTR =[select Id,pse__Allow_Self_Staffing__c,Ongoing_Project_Recurring_Budget_Amt__c,Ongoing_Project_Recurring_Planned_Hour__c,
                             pse__Planned_Hours__c,pse__Allow_Timecards_Without_Assignment__c,pse__Is_Billable__c,pse__Time_Credited__c,
                             pse__Time_Excluded__c,Months_from_Start_to_End_Date__c,pse__Daily_Timecard_Notes_Required__c,RecordtypeId,pse__Is_Active__c,pse__Project_Status__c,
                             pse__Stage__c,pse__Practice__c,Project_Sub_Type__c,pse__Project_Type__c from pse__proj__c 
                             where pse__Project_Type__c = 'GSS Product' and Project_Sub_Type__c = 'Managed Kona' and Name like '%(TR)%'and pse__Is_Template__c = TRUE limit 1];

        //Query for the SCSM template.
        pse__proj__c projectTemplateSCSM =[select Id,pse__Allow_Self_Staffing__c,Ongoing_Project_Recurring_Budget_Amt__c,Ongoing_Project_Recurring_Planned_Hour__c,
                          pse__Planned_Hours__c,pse__Allow_Timecards_Without_Assignment__c,pse__Is_Billable__c,pse__Time_Credited__c,
                          pse__Time_Excluded__c,pse__Daily_Timecard_Notes_Required__c,RecordtypeId,pse__Is_Active__c,pse__Project_Status__c,
                          pse__Stage__c,pse__Practice__c,Project_Sub_Type__c,pse__Project_Type__c from pse__proj__c 
                          where pse__Project_Type__c = 'GSS Product' and Project_Sub_Type__c = 'Managed Kona' and Name like '%SCSM%' and pse__Is_Template__c = TRUE limit 1];

        //Query for the Config template.
        pse__proj__c projectTemplateConfig =[select Id,pse__Allow_Self_Staffing__c,Ongoing_Project_Recurring_Budget_Amt__c,Ongoing_Project_Recurring_Planned_Hour__c,
                          pse__Planned_Hours__c,pse__Allow_Timecards_Without_Assignment__c,pse__Is_Billable__c,pse__Time_Credited__c,
                          pse__Time_Excluded__c,pse__Daily_Timecard_Notes_Required__c,RecordtypeId,pse__Is_Active__c,pse__Project_Status__c,
                          pse__Stage__c,pse__Practice__c,Project_Sub_Type__c,pse__Project_Type__c from pse__proj__c 
                          where pse__Project_Type__c = 'GSS Product' and Project_Sub_Type__c = 'Managed Kona' and Name like '%Config%' and pse__Is_Template__c = TRUE limit 1];

        //if either of the project templates are null -> return and send a mail to the engg team
        if(projectTemplateTR == null || projectTemplateSCSM == null || projectTemplateConfig == null)
        {
            PSA_AutoCreateProjectUtil.sendErrorMails('MKSD Templates not found','The MKSD templates are not found');
            return;
        }
        Id projectTemplateTRid = projectTemplateTR.Id;
        
        Id projectTemplateSCSMid = projectTemplateSCSM.Id;

        Id projectTemplateConfigid = projectTemplateConfig.Id;

        //the below custom setting is set to PSA User and we have a validation rule that does not allow TC entry when the project mgr is PSA user.
        PSA_Settings__c psa_settings = PSA_Settings__c.getInstance('Project Manager');

        //loop through the List of Contracts
        for(Id cId:mapContractContractDetails.keySet())
        {
            //System.debug('PSA Contracts to be checked:' + cId);
            //System.debug((mapContractContractDetails.get(cId)).size());
            if((mapContractContractDetails.get(cId)).size() == 3 || (mapContractContractDetails.get(cId)).size() == 4)
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
                if(UOMToIndex.containsKey('Hour') && UOMToIndex.containsKey('Policies') && UOMToIndex.containsKey('Per Month') && !(UOMToIndex.size() == 4 && !UOMToIndex.containsKey('Reviews')))
                {  
                    Integer hour = UOMToIndex.get('Hour');

                    Integer review;
                    if(UOMToIndex.containsKey('Reviews'))
                    {
                       review = UOMToIndex.get('Reviews');
                    }
                    else
                    {
                       review = UOMToIndex.get('Policies'); 
                    }
                    Integer policy = UOMToIndex.get('Policies');
                    Integer month = UOMToIndex.get('Per Month');
                    Double monthlyRecurringHours;
                    Integer noOfActiveMonthsHour;
                    Integer noOfActiveMonthsReview;
                    Integer noOfActiveMonthsPolicy;
                    Integer noOfActiveMonthsMonth;
                    Double pricePerMonth;
                    Double  technicalReviews;
                    Double hoursPerPolicy;
                    Double ongoingRecurringBudgetAmount;
                    //Changes by Sharath Prasanna for CR 3588241: changing planned hours to double                    
                    //Integer PlannedHours;                    
                    Double PlannedHours;                    
                    Double halfActiveMonthsMonth;

                    monthlyRecurringHours = PSA_AutoCreateProjectUtil.monthlyRecurringHours((mapContractContractDetails.get(cId))[hour]);
                    noOfActiveMonthsHour = PSA_AutoCreateProjectUtil.numberOfActiveMonths((mapContractContractDetails.get(cId))[hour].Effective_Start_Date__c,(mapContractContractDetails.get(cId))[hour].Effective_End_Date__c);

                    technicalReviews = PSA_AutoCreateProjectUtil.securityServiceReviews((mapContractContractDetails.get(cId))[review]);
                    hoursPerPolicy = PSA_AutoCreateProjectUtil.hoursPerPolicy((mapContractContractDetails.get(cId))[policy]);
                    noOfActiveMonthsReview = PSA_AutoCreateProjectUtil.numberOfActiveMonths((mapContractContractDetails.get(cId))[review].Effective_Start_Date__c,(mapContractContractDetails.get(cId))[review].Effective_End_Date__c);
                    noOfActiveMonthsPolicy = PSA_AutoCreateProjectUtil.numberOfActiveMonths((mapContractContractDetails.get(cId))[policy].Effective_Start_Date__c,(mapContractContractDetails.get(cId))[policy].Effective_End_Date__c);
                    noOfActiveMonthsMonth = PSA_AutoCreateProjectUtil.numberOfActiveMonths((mapContractContractDetails.get(cId))[month].Effective_Start_Date__c,(mapContractContractDetails.get(cId))[month].Effective_End_Date__c);
                    halfActiveMonthsMonth = noOfActiveMonthsMonth/6.0;
                    pricePerMonth = PSA_AutoCreateProjectUtil.pricePerMonth((mapContractContractDetails.get(cId))[month]);
                    
                    //THE FIRST PROJECT -> CONFIG
                    //The formula for the ongoingRecurringBudgetAmount can result in Exceptions -> divide by zero or zero by zero errors. in this case set the value to 0
                    try
                    {                        

                        ongoingRecurringBudgetAmount = ((monthlyRecurringHours * noOfActiveMonthsHour) / ((monthlyRecurringHours * noOfActiveMonthsHour) + (technicalReviews * 20.0) + hoursPerPolicy + (14 * noOfActiveMonthsMonth) + (3 * PSA_AutoCreateProjectUtil.customRound(halfActiveMonthsMonth))) ) * (pricePerMonth) / noOfActiveMonthsHour;

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

                    project1 = PSA_AutoCreateProjectUtil.createProjectWithTemplate('Managed Kona_Config_Assistance',projectTemplateConfig,cId,(mapContractContractDetails.get(cId))[hour],'MKSD',(mapContractContractDetails.get(cId))[hour].Id, (mapContractContractDetails.get(cId))[policy].Id, (mapContractContractDetails.get(cId))[month].Id, billingType,ongoingRecurringBudgetAmount,PlannedHours);                    
                    

                    ListProj2Insert.add(project1);

                    //THE SECOND PROJECT -> TR                   
                    //The formula for the ongoingRecurringBudgetAmount can result in Exceptions -> divide by zero or zero by zero errors. in this case set the value to 0

                    //Compute the Milestone Amount
                    Double milestoneAmount;
                    try
                    {
                        ongoingRecurringBudgetAmount = ((technicalReviews * 20.0) / ((monthlyRecurringHours * noOfActiveMonthsHour) + (technicalReviews * 20.0) + hoursPerPolicy + (14 * noOfActiveMonthsMonth) + (3 * PSA_AutoCreateProjectUtil.customRound(halfActiveMonthsMonth))) ) * (pricePerMonth) / noOfActiveMonthsReview;
                        milestoneAmount = (ongoingRecurringBudgetAmount * noOfActiveMonthsMonth) / technicalReviews;

                    }
                    catch(Exception e)
                    {
                        ongoingRecurringBudgetAmount = 0;
                        milestoneAmount = 0;
                    }
                    //populating the contractToMilestoneAmount map
                    contractToMilestoneAmount.put(cId,milestoneAmount);


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

                    project2 = PSA_AutoCreateProjectUtil.createProjectWithTemplate('Managed Kona_TR',projectTemplateTR,cId,(mapContractContractDetails.get(cId))[review],'MKSD',(mapContractContractDetails.get(cId))[hour].Id, (mapContractContractDetails.get(cId))[policy].Id, (mapContractContractDetails.get(cId))[month].Id, 'One-Time: Fixed Price',ongoingRecurringBudgetAmount,PlannedHours);                    
                    ListProj2Insert.add(project2);
                    
                    //THE THIRD PROJECT -> SCSM
                    //The formula for the ongoingRecurringBudgetAmount can result in Exceptions -> divide by zero or zero by zero errors. in this case set the value to 0
                    try
                    {
                        ongoingRecurringBudgetAmount = (((14 * noOfActiveMonthsMonth) + (3 * PSA_AutoCreateProjectUtil.customRound(halfActiveMonthsMonth))) / ((monthlyRecurringHours * noOfActiveMonthsHour) + (technicalReviews * 20.0) + hoursPerPolicy + (14 * noOfActiveMonthsMonth) + (3 * PSA_AutoCreateProjectUtil.customRound(halfActiveMonthsMonth))) ) * (pricePerMonth) / noOfActiveMonthsMonth;

                    }
                    catch(Exception e)
                    {
                        ongoingRecurringBudgetAmount = 0;
                    }

                    pse__proj__c project3 = new pse__proj__c();                   
                    PlannedHours = ((14 * noOfActiveMonthsMonth) + (3 * PSA_AutoCreateProjectUtil.customRound(halfActiveMonthsMonth)));
                    if(PlannedHours == 0.0)
                    {
                        PlannedHours = 1.0;   
                    }

                    //createProjectWithTemplate(name,template,contractId,detail,product,mrr, overrage,permonth,  billingType, ongoingRecurringBudgetAmount, plannedHours)
                    project3 = PSA_AutoCreateProjectUtil.createProjectWithTemplate('Managed Kona_SCSM',projectTemplateSCSM,cId,(mapContractContractDetails.get(cId))[month],'MKSD',(mapContractContractDetails.get(cId))[hour].Id, (mapContractContractDetails.get(cId))[policy].Id, (mapContractContractDetails.get(cId))[month].Id, 'One-Time: Fixed Price',ongoingRecurringBudgetAmount,PlannedHours);                    
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

            //Populating the map projectToMilestoneAmount
            if(p1.name.contains('SCSM'))
            {
                Integer activeMonthsMRR = PSA_AutoCreateProjectUtil.numberOfActiveMonths(p1.pse__Start_Date__c,p1.pse__End_Date__c);
                projectToActiveMonths.put(p1.id,activeMonthsMRR);
            }

            if(p1.name.contains('TR'))
            {

               projectToMilestoneAmount.put(p1.id,contractToMilestoneAmount.get(p1.SMP_Contract__c));
            }
        }
        //Loop over the cases: create the Project_Case_Association__c record for each of the project created. if the project is not created for a case -> update the description 
        for(case c1:casesForMKSD)
        {
           successfulCase = False;
             if(contractToProjects.containsKey(c1.contract__c))
             {  
                Project_Case_Association__c pca1;  
                for(pse__Proj__c p1: contractToProjects.get(c1.contract__c))
                {
                     if(p1.Name.contains('Config'))
                     {
                        pca1 = PSA_AutoCreateProjectUtil.createProjectCaseAssociationRecord(p1.Id,c1.Id,c1.contract__c,'Managed Kona_Config_Assistance','MKSD');
                     }
                     else if(p1.Name.contains('TR'))
                     {
                        pca1 = PSA_AutoCreateProjectUtil.createProjectCaseAssociationRecord(p1.Id,c1.Id,c1.contract__c,'Managed Kona_TR','MKSD');

                     }
                     else
                     {
                        pca1 = PSA_AutoCreateProjectUtil.createProjectCaseAssociationRecord(p1.Id,c1.Id,c1.contract__c,'Managed Kona_SCSM','MKSD');                      
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
          String errorMessage = '\n\n<### PROJECTS NOT CREATED ###>\n\nPlease note that due to contract set-up Salesforce projects have not been automatically created.\n\nPlease follow these guidelines on how to create the projects:\nhttps://ac.akamai.com/docs/DOC-5522';

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
        ProjectNametoBudgetName.put('Config','Managed Kona_(CA)');
        ProjectNametoBudgetName.put('TR','Managed Kona_(TR)');
        ProjectNametoBudgetName.put('SCSM','Managed Kona_(SCSM)');
         
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
       //List<String> setAmountFromProject = new List<String>();
       //setAmountFromProject.add('Security Config. Assist.');
       Map<String,Integer> setDefaultPlannedHoursProjectToHours = new Map<String,Integer>();
       setDefaultPlannedHoursProjectToHours.put('TR',20);

       //createMilestones (List<pse__Proj__c> projects, List<String> setAmountFromProject,List<String> setPlannedhoursFromProject, Map<String,Double> setDefaultAmountProjectToAmount,Map<String,Integer> setDefaultPlannedHoursProjectToHours)
        milestones = PSA_AutoCreateProjectUtil.createMilestones(insertedProjects,null,null,null,setDefaultPlannedHoursProjectToHours);
       if(milestones != null && milestones.size() > 0)
       {   Double plannedHoursMilestone; 
           for(pse__Milestone__c m: milestones)
           {
                if(m.name.contains('Table Top (Attack) Drills') && projectToActiveMonths.containsKey(m.pse__Project__c))
                {
                    
                    plannedHoursMilestone = projectToActiveMonths.get(m.pse__Project__c) / 6.0;
                    m.pse__Planned_Hours__c = 6 * PSA_AutoCreateProjectUtil.customRound(plannedHoursMilestone);
                }
                else if(m.name.contains('Reporting') && projectToActiveMonths.containsKey(m.pse__Project__c))
                {
                    plannedHoursMilestone = projectToActiveMonths.get(m.pse__Project__c);
                    m.pse__Planned_Hours__c = 8 * plannedHoursMilestone;
                }
                else if(m.name.contains('Customer Meetings') && projectToActiveMonths.containsKey(m.pse__Project__c) )
                {
                    plannedHoursMilestone = projectToActiveMonths.get(m.pse__Project__c);
                    m.pse__Planned_Hours__c = 6 * plannedHoursMilestone;
                }
                else if(m.name.contains('Technical Review'))
                {
                    //The start date should be computed as the project start date + (project number of active months/5) months for the first review milestone: Review#1 and for the other milestones, the project start date + milestone review number * (project number of active months/5). That is, for the milestone, Review#5, start date = project start date + 5 * (project number of active months/5) months
                    Double monthsToAdd; 
                    //Compute the number of active months of the corresponding project. In the milestone creation function, the start date and the target date of the milestone are set to the start and end date of the project
                    Integer reviewNoOfActiveMonths = PSA_AutoCreateProjectUtil.numberOfActiveMonths(m.Start_Date__c,m.pse__Target_Date__c);
                    Double reviewMonthsSpan = reviewNoOfActiveMonths/5.0;
                    if(m.name.contains('#1'))
                    {
                        monthsToAdd = reviewMonthsSpan;
                        m.Start_Date__c = PSA_AutoCreateProjectUtil.customAddMonths(m.Start_Date__c,monthsToAdd);
                        m.pse__Target_Date__c = m.Start_Date__c;

                    }
                    else if (m.name.contains('#2'))
                    {
                        monthsToAdd = reviewMonthsSpan * 2;
                        m.Start_Date__c = PSA_AutoCreateProjectUtil.customAddMonths(m.Start_Date__c,monthsToAdd);
                        m.pse__Target_Date__c = m.Start_Date__c;

                    }
                    else if (m.name.contains('#3'))
                    {
                        monthsToAdd = reviewMonthsSpan * 3;
                        m.Start_Date__c = PSA_AutoCreateProjectUtil.customAddMonths(m.Start_Date__c,monthsToAdd);
                        m.pse__Target_Date__c = m.Start_Date__c;
                        
                    }
                    else if (m.name.contains('#4'))
                    {
                        monthsToAdd = reviewMonthsSpan * 4;
                        m.Start_Date__c = PSA_AutoCreateProjectUtil.customAddMonths(m.Start_Date__c,monthsToAdd);
                        m.pse__Target_Date__c = m.Start_Date__c;
                        
                    }
                    else if (m.name.contains('#5'))
                    {
                        monthsToAdd = reviewMonthsSpan * 5;
                        m.Start_Date__c = PSA_AutoCreateProjectUtil.customAddMonths(m.Start_Date__c,monthsToAdd);
                        m.pse__Target_Date__c = m.Start_Date__c;
                    }
                    m.pse__Milestone_Amount__c = projectToMilestoneAmount.get(m.pse__Project__c);
                }
           } 
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

    public void CreateGDSProjects(Map<Id,List<Merge_Contract_Detail__c>> mapContractContractDetails,List<Case> casesForGDS)
    {
        List<Database.UpsertResult> upsertResultRecords = new List<Database.UpsertResult>();
        List<Database.SaveResult> saveResultRecords = new List<Database.SaveResult>();
        List<pse__proj__c> ListProj2Insert = new List<pse__proj__c>();
        List<pse__Budget__c> ListBudget2Insert = new List<pse__Budget__c>();
        List<Id> ProjectInsertedIds = new List<Id>();

        List<pse__Proj__c> insertedProjects = new List<pse__proj__c>();

        List<Case> caseSuccessfulUpdate = new List<Case>();
        List<pse__Budget__c> budgetsToUpdate = new List<pse__Budget__c>();
        List<Project_Case_Association__c> projectCases2Insert = new List<Project_Case_Association__c>();
       
        //projectToActiveQuarters maps the project Id to the number of active quarters for the computation of the planned hours of milestone
        Map<Id,Integer> projectToActiveQuarters = new Map<Id,Integer>();
        //to store project corresponding GDS Units for Milestone's planned hours computation
        Map<Id,Integer> projectToGDSUnits = new Map<Id,Integer>();
        //Query for the GSS template.

        pse__proj__c projectTemplateGSS =[select Id,pse__Allow_Self_Staffing__c,Ongoing_Project_Recurring_Budget_Amt__c,Ongoing_Project_Recurring_Planned_Hour__c,
                             pse__Planned_Hours__c,pse__Allow_Timecards_Without_Assignment__c,pse__Is_Billable__c,pse__Time_Credited__c,
                             pse__Time_Excluded__c,Months_from_Start_to_End_Date__c,pse__Daily_Timecard_Notes_Required__c,RecordtypeId,pse__Is_Active__c,pse__Project_Status__c,
                             pse__Stage__c,pse__Practice__c,Project_Sub_Type__c,pse__Project_Type__c from pse__proj__c 
                             where pse__Project_Type__c = 'GSS Product' and Project_Sub_Type__c = 'Guided Delivery Service' and Name = 'GSS Products/Guided Delivery Service - Project Template' and pse__Is_Template__c = TRUE limit 1];

        //if GSS project template is null -> return and send a mail to the engg team
        if(projectTemplateGSS == null)
        {
            PSA_AutoCreateProjectUtil.sendErrorMails('GDS Template not found','The GDS template is not found');
            return;
        }
        Id projectTemplateGSSid = projectTemplateGSS.Id;        

        //loop through the List of Contracts
        for(Id cId:mapContractContractDetails.keySet())
        {
            //Looking for 2 contract line items, one with UOM Unit and another one with Per Month
            if((mapContractContractDetails.get(cId)).size() == 2)
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
                //There should be 2 contract details with the unit of measure being Per Month and Unit. This is condition 1a and 1b
                if(UOMToIndex.containsKey('Unit') && UOMToIndex.containsKey('Per Month'))
                {  
                    Integer unit = UOMToIndex.get('Unit');                    
                    Integer month = UOMToIndex.get('Per Month');

                    Integer noGDSUnits;
                    Double pkgPriceMRR;
                    Integer noOfActiveQuarters;
                    Integer noOfActiveMonths;
                    String feeSchedule;
                    Double plannedHours; 
                    Merge_Contract_Detail__c ctrUnit = mapContractContractDetails.get(cId)[unit];                

                    noGDSUnits = (Integer)ctrUnit.Units_Low__c;
                    pkgPriceMRR = mapContractContractDetails.get(cId)[month].Unit_Price__c;
                   
                    if(ctrUnit.Billing_Duration__c == 'Quarterly')
                    {
                        feeSchedule = 'Quarterly Commit (MRR)';
                    }
                    else 
                    {
                        feeSchedule = 'Monthly Commit (MRR)';
                    }
                   
                    noOfActiveMonths = PSA_AutoCreateProjectUtil.numberOfActiveMonths(ctrUnit.Effective_Start_Date__c,ctrUnit.Effective_End_Date__c);                                
                    noOfActiveQuarters = PSA_AutoCreateProjectUtil.customRound((Double)(noOfActiveMonths/3.0));
                    pse__proj__c project = new pse__proj__c();
                   
                    plannedHours = 12.5 * noOfActiveQuarters * noGDSUnits;
                    //Planned Hours has to be 1 for non-internal projects
                    if(plannedHours == 0.0)
                    {
                        plannedHours = 1.0;   
                    }
                    //createProjectWithTemplate(name,template,contractId,detail,product,mrr, overrage,permonth,  billingType, ongoingRecurringBudgetAmount, plannedHours)

                    project = PSA_AutoCreateProjectUtil.createProjectWithTemplate('Guided Delivery Service',projectTemplateGSS,cId,ctrUnit,'GDS',ctrUnit.Id, ctrUnit.Id, ctrUnit.Id, feeSchedule,pkgPriceMRR,plannedHours);                    
                    //Ongoing Project Recurring Panned Hour formula is different for GDS
                    project.Ongoing_Project_Recurring_Planned_Hour__c = plannedHours/noOfActiveMonths;

                    ListProj2Insert.add(project);
                }
            }
        }
    upsertResultRecords = Database.Upsert(ListProj2Insert);
        PSA_AutoCreateProjectUtil.PopulateErrorTableForUpsert(upsertResultRecords, 'Project Creation');

        insertedProjects = new List<pse__Proj__c>();
        for(Database.UpsertResult project: upsertResultRecords)
        {
              if (project.isSuccess()) 
              {
                    ProjectInsertedIds.add(project.getId());
              }
        }

        //query for the inserted projects
        insertedProjects = [select Id,Name,pse__Start_Date__c,pse__End_Date__c,Months_from_Start_to_End_Date__c,pse__Billing_Type__c,Project_Template__c,SMP_Contract__c,pse__Account__c,pse__Is_Billable__c,Ongoing_Project_Recurring_Budget_Amt__c,pse__Planned_Hours__c,SMP_Contract_Line_Item__c,SMP_Automated_Project__c,PCLI_MRR1__r.Units_Low__c from pse__proj__c where Id in :ProjectInsertedIds];
        Boolean successfulCase = False;
        Map<Id,pse__Proj__c> contractToProjects = new Map<Id,pse__Proj__c>();

        //Create a map of contract to project -> 1 contract should be linked to 1 project
        for(pse__proj__c p1:insertedProjects)
        {                      
            contractToProjects.put(p1.SMP_Contract__c,p1);
            Integer noOfActiveMonths = PSA_AutoCreateProjectUtil.numberOfActiveMonths(p1.pse__Start_Date__c,p1.pse__End_Date__c);
            Integer noOfActiveQuarters = PSA_AutoCreateProjectUtil.customRound((Double)(noOfActiveMonths/3.0));
            projectToActiveQuarters.put(p1.Id,noOfActiveQuarters);
            projectToGDSUnits.put(p1.Id,(Integer)p1.PCLI_MRR1__r.Units_Low__c);
        }

        //Loop over the cases: create the Project_Case_Association__c record for the project created. if the project is not created for a case -> update the description 
        for(case c1:casesForGDS)
        {
            successfulCase = False;
            if(contractToProjects.containsKey(c1.contract__c))
            {  
                Project_Case_Association__c pca1;  
                pse__Proj__c p1 = contractToProjects.get(c1.contract__c);
                
                if(p1.Name.contains('Guided Delivery Service'))
                {
                    pca1 = PSA_AutoCreateProjectUtil.createProjectCaseAssociationRecord(p1.Id,c1.Id,c1.contract__c,'Guided Delivery Service','GDS');
                }                
                 
                projectCases2Insert.add(pca1);                 
                successfulCase = True;  
            }

            // Update the case description saying the projects were created or not created successfully.
            if(c1.Description == null)
            {
                c1.Description = '';
            }
            String errorMessage = '\n\n<### PROJECT NOT CREATED ###>\n\nPlease note that due to contract set-up the Salesforce project has not been automatically created.\n\nPlease follow these guidelines on how to create the projects:\nhttps://ac.akamai.com/docs/DOC-8302#jive_content_id_Manual_Project_Creation';

            String successMessage = '\n\nPlease note that a Salesforce project has been automatically created:\nLink to the Project can be found on the Project Related List section of the Case\n\nPlease follow these guidelines on project assignment & usage:\nhttps://ac.akamai.com/docs/DOC-8302#jive_content_id_Automated_Project_Creation';

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
        PSA_AutoCreateProjectUtil.PopulateErrorTableForUpsert(upsertResultRecords, 'ProjectCaseAssociation');

        //Update case description.
        saveResultRecords = Database.Update(caseSuccessfulUpdate,False);
        PSA_AutoCreateProjectUtil.PopulateErrorTableForUpdate(saveResultRecords, CaseSuccessfulUpdate);
        
        ////To create the budget with specific name -> create a map of project name to budget name. This is to be passed as the second parameter
        Map<String,String> ProjectNametoBudgetName = new Map<String,String>();
        ProjectNametoBudgetName.put('Guided Delivery Service','Guided_Delivery_Service');
         
        //createBudgetWithName(projects, type, ProjectNametoBudgetName)
        listBudget2Insert = PSA_AutoCreateProjectUtil.createBudgetWithName(insertedProjects,'Customer Purchase Order',ProjectNametoBudgetName);
        List<Database.UpsertResult> budgetResults = new List<Database.UpsertResult>();
        List<Id> budgetSuccesses = new List<Id>();
        budgetResults = Database.Upsert(listBudget2Insert,false);

        //create the project contract, project contract line item records. update the project -> contract closed : yes
       PSA_AutoCreateProjectUtil.insertPCLItems(insertedProjects);

       //If all milestones of a project should have a constant value, create a map of the project name to the constant value. Similarly for the planned hours, create a map of  the project name to the constant value. 
       //If the milestone amount has to be set from the project -> project.Ongoing_Project_Recurring_Budget_Amt__c * project.Months_from_Start_to_End_Date__c, create a list of the milestone names.
       //If the milestone planned hours has to be set from the project, create a list of the milestone names -> milestone.pse__Planned_Hours__c = project.pse__Planned_Hours__c
       List<pse__Milestone__c> milestones = new List<pse__Milestone__c>();

       //createMilestones (List<pse__Proj__c> projects, List<String> setAmountFromProject,List<String> setPlannedhoursFromProject, Map<String,Double> setDefaultAmountProjectToAmount,Map<String,Integer> setDefaultPlannedHoursProjectToHours)
        milestones = PSA_AutoCreateProjectUtil.createMilestones(insertedProjects,null,null,null,null);
       if(milestones != null && milestones.size() > 0)
       {   
           Double plannedHoursMilestone; 
           for(pse__Milestone__c m: milestones)
           {
                if(m.name.contains('Training') )
                {
                    m.pse__Planned_Hours__c = 2.5;
                }
                else if(m.name.contains('Guided Config Update') && projectToActiveQuarters.containsKey(m.pse__Project__c) && projectToGDSUnits.containsKey(m.pse__Project__c)) 
                {
                    m.pse__Planned_Hours__c = 5 * projectToActiveQuarters.get(m.pse__Project__c) * projectToGDSUnits.get(m.pse__Project__c);
                }
                else if(m.name.contains('Quarterly Insight') && projectToActiveQuarters.containsKey(m.pse__Project__c))
                {
                    m.pse__Planned_Hours__c = 5 * projectToActiveQuarters.get(m.pse__Project__c);
                }                
           } 
           upsertResultRecords = Database.Upsert(milestones,false);
           PSA_AutoCreateProjectUtil.PopulateErrorTableForUpsert(upsertResultRecords, 'Milestones');
       }

    }

    //Changes by Sharath Prasanna: Uncommenting the changes for TAS for FFPSA-180 
    public void CreateTASProjects(Map<Id,List<Merge_Contract_Detail__c>> mapContractContractDetails,List<Case> casesForTAS)
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
        
        //projectToActiveQuarters maps the project Id to the number of active quarters for the computation of the planned hours of milestone
        //Map<Id,Integer> projectToActiveQuarters = new Map<Id,Integer>();
        //to store project corresponding TAS Units for Milestone's planned hours computation
        //Map<Id,Integer> projectToTASUnits = new Map<Id,Integer>();
        
        //Query for the GSS template required for TAS.
        List<pse__proj__c> projectTemplateGSSList = new List<pse__proj__c>();
        projectTemplateGSSList =[select Id,pse__Allow_Self_Staffing__c,Ongoing_Project_Recurring_Budget_Amt__c,Ongoing_Project_Recurring_Planned_Hour__c,
                             pse__Planned_Hours__c,pse__Allow_Timecards_Without_Assignment__c,pse__Is_Billable__c,pse__Time_Credited__c,
                             pse__Time_Excluded__c,Months_from_Start_to_End_Date__c,pse__Daily_Timecard_Notes_Required__c,RecordtypeId,pse__Is_Active__c,pse__Project_Status__c,
                             pse__Stage__c,pse__Practice__c,Project_Sub_Type__c,pse__Project_Type__c from pse__proj__c 
                             where pse__Project_Type__c = 'GSS Product' and Project_Sub_Type__c = 'Technical Advisory' and Name = 'GSS Products/Technical Advisory - Project Template' and pse__Is_Template__c = TRUE limit 1];

        //if GSS project template is null -> return and send a mail to the engg team
        if(projectTemplateGSSList.size() != 1)
        {
            PSA_AutoCreateProjectUtil.sendErrorMails('TAS Template not found or duplicates exist','The TAS template with the name as GSS Products/Technical Advisory - Project Template, is either not found or more than one template with that name exists.');
            return;
        }
        Id projectTemplateGSSid = projectTemplateGSSList[0].Id;        

        //loop through the List of Contracts
        for(Id cId:mapContractContractDetails.keySet())
        {

            Integer clIsize = mapContractContractDetails.get(cId).size();
            
            //There should atleast be 2 Contract Line items to create a project ('Hour and Per Month' or 'Business days and Per Month')
            if ( clIsize >= 2)
            {
                
                //Create a map of Unit of Measure and the Index of the corresponding contract detail in the mapContractContractDetails.get list
                Map<String,List<Integer>> UOMToIndex = new Map<String,List<Integer>>();
                Integer perMonthIndex = -1;
                Integer index = 0;
                for(Merge_Contract_Detail__c contractDetail: mapContractContractDetails.get(cId))
                {
                    if(contractDetail.Unit_of_Measure__c == 'Per Month')
                    {
                        //check for the last modified per month CLI
                        if(perMonthIndex == -1 || (perMonthIndex != -1 && mapContractContractDetails.get(cId)[perMonthIndex].LastModifiedDate < mapContractContractDetails.get(cId)[index].LastModifiedDate))
                        {
                            perMonthIndex = index;   
                        }
                    }   
                    else
                    {
                        if(!UOMToIndex.containsKey(contractDetail.Unit_of_Measure__c))
                        {
                            UOMToIndex.put(contractDetail.Unit_of_Measure__c,new List<Integer>());
                                
                        }
                        UOMToIndex.get(contractDetail.Unit_of_Measure__c).add(index);   

                    }  
                    index++;
                }

                //The per month CLI should exist along with hour and/ or business days CLI
                if ( perMonthIndex != -1 && ( UOMToIndex.containsKey('Hour') || UOMToIndex.containsKey('Business Days')) )
                {
                    
                    Merge_Contract_Detail__c cliMonth;
                    List <Merge_Contract_Detail__c> selectedCLIs = new List <Merge_Contract_Detail__c>();
                    
                    Double onGngProject_RBAmt;
                    Integer noOfActiveMonths;
                    String feeSchedule;
                    Double plannedHours; 
                    Double monthlyRecurringHours;
                    Double noMonthsPerBilling;

                    //If the UOM is Hour, dont create the projects for Business Days CLI
                    if(UOMToIndex.containsKey('Hour'))
                    {
                       for(Integer hourIndex: UOMToIndex.get('Hour'))
                       {
                            selectedCLIs.add(mapContractContractDetails.get(cId)[hourIndex]);  
                       }                       
                    }
                    else
                    {
                       for(Integer daysIndex: UOMToIndex.get('Business Days'))
                       {
                            selectedCLIs.add(mapContractContractDetails.get(cId)[daysIndex]);  
                       }                       
                    }
                    cliMonth = mapContractContractDetails.get(cId)[perMonthIndex];

                    //Get the number of active months of the per month CLI
                    noOfActiveMonths = PSA_AutoCreateProjectUtil.numberOfActiveMonths(cliMonth.Effective_Start_Date__c,cliMonth.Effective_End_Date__c);                                
                    onGngProject_RBAmt = cliMonth.Unit_Price__c;
                    if(onGngProject_RBAmt == null)
                    {
                        onGngProject_RBAmt = 1;   
                    }

                    //for each of the CLI create a project
                    for(Merge_Contract_Detail__c cliSelected: selectedCLIs)
                    {
                        if(cliSelected.Billing_Duration__c == 'Monthly')
                        {
                            noMonthsPerBilling = 1.0;
                            feeSchedule = 'Monthly Commit (MRR)';
                        }
                        else if(cliSelected.Billing_Duration__c == 'Quarterly')
                        {
                            noMonthsPerBilling = 3.0;
                            feeSchedule = 'Quarterly Commit (MRR)';
                        }
                        else if(cliSelected.Billing_Duration__c == 'Semi-Annual')
                        {
                            noMonthsPerBilling = 6.0;
                            feeSchedule = 'Semi-Annual Commit (ARR)';
                        }
                        else if(cliSelected.Billing_Duration__c == 'Annual')
                        {
                            noMonthsPerBilling = 12.0;
                            feeSchedule = 'Annual Commit (ARR)';
                        }
                        
                        if(cliSelected.Units_Low__c == null || cliSelected.Units_Low__c == 0)
                        {
                            monthlyRecurringHours = 0;
                        }
                        else
                        {
                            if(UOMToIndex.containsKey('Hour'))
                            {
                              //when it has cli, having hour 
                              monthlyRecurringHours = cliSelected.Units_Low__c  / noMonthsPerBilling;
                            }
                            else
                            {
                              //when it has cli, having Businessdays
                              monthlyRecurringHours = (cliSelected.Units_Low__c * 8.0 )/ noMonthsPerBilling;
                            }
                        }    
                        plannedHours = monthlyRecurringHours * noOfActiveMonths;
                        if(plannedHours == 0)
                        {
                            plannedHours = 1;   
                        }
                        //createProjectWithTemplate(name,template,contractId,detail,product,mrr, overrage,permonth,  billingType, ongoingRecurringBudgetAmount, plannedHours)
                        pse__proj__c project = new pse__proj__c();
                        project = PSA_AutoCreateProjectUtil.createProjectWithTemplate('Technical Advisory',projectTemplateGSSList[0],cId,cliSelected,'TAS',cliSelected.Id, cliSelected.Id, cliMonth.Id, feeSchedule,onGngProject_RBAmt,plannedHours);                    
                        try
                        {
                            project.Ongoing_Project_Recurring_Planned_Hour__c = ( monthlyRecurringHours * noOfActiveMonths )/noOfActiveMonths;
                        }
                        catch(Exception e)
                        {
                            project.Ongoing_Project_Recurring_Planned_Hour__c = 1;   
                        }
                        ListProj2Insert.add(project);

                    }
                }
                
            }
        }

        upsertResultRecords = Database.Upsert(ListProj2Insert);
        PSA_AutoCreateProjectUtil.PopulateErrorTableForUpsert(upsertResultRecords, 'Project Creation for TAS');

        //insertedProjects = new List<pse__Proj__c>();
        for(Database.UpsertResult project: upsertResultRecords)
        {
              if (project.isSuccess()) 
              {
                    ProjectInsertedIds.add(project.getId());
              }
        }

        //query for the inserted projects
        insertedProjects = new Map<id,pse__Proj__c>([select Id,Name,pse__Start_Date__c,pse__End_Date__c,Months_from_Start_to_End_Date__c,pse__Billing_Type__c,Project_Template__c,SMP_Contract__c,pse__Account__c,pse__Is_Billable__c,Ongoing_Project_Recurring_Budget_Amt__c,pse__Planned_Hours__c,SMP_Contract_Line_Item__c,SMP_Automated_Project__c,PCLI_MRR1__r.Units_Low__c,PCLI_PerMonth1__r.Effective_Start_Date__c,PCLI_PerMonth1__r.Effective_End_Date__c from pse__proj__c where Id in :ProjectInsertedIds]);
        Boolean successfulCase = False;
        Map<Id,List<pse__Proj__c>> contractToProjects = new Map<Id,List<pse__Proj__c>>();

        //Create a map of contract to List of projects -> 1 contract can be linked to multiple projects
        
        for(pse__proj__c p1:insertedProjects.values())
        {        
            if(!contractToProjects.containsKey(p1.SMP_Contract__c))
            {
                contractToProjects.put(p1.SMP_Contract__c,new List<pse__Proj__c>());    
            }              
            contractToProjects.get(p1.SMP_Contract__c).add(p1);
        }

        //Loop over the cases: create the Project_Case_Association__c record for the project created. if the project is not created for a case -> update the description 
        for(case c1:casesForTAS)
        {
            successfulCase = False;
            if(contractToProjects.containsKey(c1.contract__c))
            {  
                Project_Case_Association__c pca1;  
                for (pse__Proj__c p1:contractToProjects.get(c1.contract__c))
                {
                    if(p1.Name.contains('Technical Advisory'))
                    {
                        pca1 = PSA_AutoCreateProjectUtil.createProjectCaseAssociationRecord(p1.Id,c1.Id,c1.contract__c,'Technical Advisory Service','TAS');
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
            String errorMessage = '\n\n<<### PROJECT NOT CREATED ###>\n\nPlease note that due to contract set-up the Salesforce project has not been automatically created.\n\nPlease follow these guidelines on how to create the projects:\nhttps://ac.akamai.com/docs/DOC-9413';

            String successMessage = '\n\nPlease note that a Salesforce project has been automatically created:\nLink to the Project can be found on the Project Related List section of the Case\n\nPlease follow these guidelines on project assignment & usage:\nhttps://ac.akamai.com/docs/DOC-9413';

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
        PSA_AutoCreateProjectUtil.PopulateErrorTableForUpsert(upsertResultRecords, 'ProjectCaseAssociation');

        //Update case description.
        saveResultRecords = Database.Update(caseSuccessfulUpdate,False);
        PSA_AutoCreateProjectUtil.PopulateErrorTableForUpdate(saveResultRecords, CaseSuccessfulUpdate);
        
        ////To create the budget with specific name -> create a map of project name to budget name. This is to be passed as the second parameter
        Map<String,String> ProjectNametoBudgetName = new Map<String,String>();
        ProjectNametoBudgetName.put('Technical Advisory','TAS');
         
        //createBudgetWithName(projects, type, ProjectNametoBudgetName)
        listBudget2Insert = PSA_AutoCreateProjectUtil.createBudgetWithName(insertedProjects.values(),'Customer Purchase Order',ProjectNametoBudgetName);

        // change the noofactivemonths for the budget and also the pse amount calculation.
        if(listBudget2Insert!=null || listBudget2Insert.size() > 0)
        {
            for( pse__Budget__c budg : listBudget2Insert )
            {
                pse__Proj__c p = insertedProjects.get(budg.pse__Project__c);
                Integer noOfActMonths = PSA_AutoCreateProjectUtil.numberOfActiveMonths(p.PCLI_PerMonth1__r.Effective_Start_Date__c,p.PCLI_PerMonth1__r.Effective_End_Date__c);
                budg.pse__Amount__c = p.Ongoing_Project_Recurring_Budget_Amt__c * noOfActMonths;

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
        PSA_AutoCreateProjectUtil.PopulateErrorTableForUpsert(upsertResultRecords, 'Milestones');
       

    }
  

    public void finish(Database.BatchableContext BC) 
    {
        PSA_Settings__c psaSetting = PSA_Settings__c.getValues('AutogenBatchSize');

        Integer batchSize = 0;
        if(psaSetting == null)
        {
            batchSize = 200;
        }
        else
        {
            batchSize =  Integer.valueOf(psaSetting.Value__c);
        }
        PSA_AutogenProjectBatch_New  autogenProject = new PSA_AutogenProjectBatch_New();
        Database.executeBatch(autogenProject,batchSize);
    }

}