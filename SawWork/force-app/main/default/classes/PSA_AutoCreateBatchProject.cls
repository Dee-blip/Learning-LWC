/*
 * CR: 2806500
 * Developer: Samir Jha
 * Enhancement:Automated creation of SF projects for SMP 2.0 product
 * Release: 4.12
 * Date: 12th October 2015
 *
 * Modified By: Jaya on 11th March 2016 
 * Change: Added comments and implemented CR https://bugzilla.akamai.com/show_bug.cgi?id=3305101
 * Modified By: Sharath on 13th May 2016
 * Change: Changed the select query for contract details: added the filter on billing duration
 * Modified By: Sharath on 25th Jan 2017
 * Change: Changed for https://bugzilla.akamai.com/show_bug.cgi?id=3560081. Changed the active months formula
 * MODIFIED by Sharath on 8th Feb 2018. Added the batch size to the Autogen batch call in the finish mehthod
*/

global class PSA_AutoCreateBatchProject implements Database.Batchable<sObject>,Database.Stateful
{
    list<Merge_Contract_Header__c> listContractScope = new list<Merge_Contract_Header__c>();
    list<Merge_Contract_Detail__c> listContractDetailstoCheck = new list<Merge_Contract_Detail__c>();
    map<Merge_Contract_Header__c,Case> mapContractCase = new map<Merge_Contract_Header__c,Case>();
    list<Merge_Contract_Detail__c> listContractDetailstoCheckCases = new list<Merge_Contract_Detail__c>();
    list<Merge_Contract_Detail__c> listContractDetailstoCreateProject = new list<Merge_Contract_Detail__c>();
    list<Merge_Contract_Detail__c> listContractDetailstoUpdate = new list<Merge_Contract_Detail__c>();
    map<Id,list<Merge_Contract_Detail__c>> mapContractContractDetails = new map<Id,list<Merge_Contract_Detail__c>>();
    list<String> Contracts2Exclude = new list<String>();
     public string batchQuery = NULL;
    //global list<Project_Case_Association__c> projectCases = [select Id,Contract__c from Project_Case_Association__c];
    
    /* Project case association object has 3 lookups - Contract, Project and Case. It also has a field called Automated Project. This is set to true by this class. */
    list<Project_Case_Association__c> projectCases2Insert = new list<Project_Case_Association__c>();
    //global list<Case> CasesCreated = [select Id,Contract__c from Case where CreatedDate = LAST_N_DAYS:2 and Autogen_UseCase__c = 'SMP-NonSecurity'];
    global PSA_AutoCreateBatchProject()
    {
        
    }
    private string query;
     /*......Query for Test Class.......*/      
    static String TestClass_Query = null;
    global Database.QueryLocator start(Database.BatchableContext BC) 
    {
        //query = 'select Id,Units_Low__c,Currency__c,Unit_of_Measure__c,Billing_Duration__c,Unit_Price__c,Product_Id__c, Product__c, Original_Contract_Id__c,Original_Contract_Id__r.Account_Name__c,Effective_Start_Date__c,Effective_End_Date__c, CreatedDate from Merge_Contract_Detail__c where CreatedDate = LAST_N_DAYS:2 and SMP_Project_Created__c = FALSE and Product_Id__c= \'M-LC-120877\' and Record_Type__c = \'Committed\' and (Unit_of_Measure__c = \'Hour\' or Unit_of_Measure__c = \'Configurations\')';
       
        /* This is a query on the Contract object that gets a list of all Contracts that satisfy the below criteria. This would return almost all valid Contracts in the system. */
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
                              
        TestClass_Query = query + ' order by createddate desc limit 5'; 
        
        batchQuery = (System.Test.isRunningTest()) ? TestClass_Query : query;
        
        return Database.getQueryLocator(batchQuery);
                               
        //return Database.getQueryLocator(query); 
    }
    global void execute(Database.BatchableContext BC,list<sObject> scope)
    {
       
       listContractScope= scope;//listContractDetailstoCreateProject listContractDetailstoCheck

       /* The below query fetches the list of all Contract Details that are created in the last 2 days with the record type Committed and UOM should be Hour or Configurations and 
       Original Contract Id in the list above. */
       //Start of changes by janantha for CR 3305101 to check for an additional line item.
       /*listContractDetailstoCheck = [select Id,Units_Low__c,CurrencyIsoCode,Unit_of_Measure__c,Billing_Duration__c,Unit_Price__c,Product_Id__c, Product__c, 
                                     Original_Contract_Id__c,Original_Contract_Id__r.Currency__c,Original_Contract_Id__r.Account_Name__c,Original_Contract_Id__r.Account_Name__r.Area__c,Effective_Start_Date__c,Effective_End_Date__c, 
                                     CreatedDate from Merge_Contract_Detail__c where (CreatedDate = LAST_N_DAYS:2 OR Effective_Start_Date__c = LAST_N_DAYS:2) and Product_Id__c= 'M-LC-120877' 
                                     and Record_Type__c = 'Committed' and (Unit_of_Measure__c = 'Hour' or Unit_of_Measure__c = 'Configurations') and Original_Contract_Id__c in:listContractScope];*/
       //Changes by Sharath: added the billing duration filter                                            
       listContractDetailstoCheck = [select Id,Units_Low__c,CurrencyIsoCode,Unit_of_Measure__c,Billing_Duration__c,Unit_Price__c,Product_Id__c, Product__c, 
                                     Original_Contract_Id__c,Original_Contract_Id__r.Currency__c,Original_Contract_Id__r.Account_Name__c,Original_Contract_Id__r.Account_Name__r.TERR_HIER_5__c,Effective_Start_Date__c,Effective_End_Date__c, 
                                     CreatedDate from Merge_Contract_Detail__c where (CreatedDate = LAST_N_DAYS:2 OR Effective_Start_Date__c = LAST_N_DAYS:2) and Product_Id__c= 'M-LC-120877' 
                                     and Record_Type__c = 'Committed' and ((Unit_of_Measure__c = 'Hour' and (Billing_Duration__c = 'Monthly' or Billing_Duration__c = 'Quarterly'))or Unit_of_Measure__c = 'Configurations' or Unit_of_Measure__c = 'Per Month') and Original_Contract_Id__c in:listContractScope];

        //End of changes by janantha for CR 3305101 to check for an additional line item.

       /* The below query fetches a list of all Cases created in the last 2 days with the autogen use case field set to SMP. */
       list<Case> CasesCreated = [select Id,Description ,Contract__c from Case where CreatedDate = LAST_N_DAYS:2 and Autogen_UseCase__c = 'SMP-NonSecurity-COB' and Contract__c in :listContractScope];

       /* The below query fetches all the Contracts that have an associated project. These contracts need to be excluded as every contract can have Projects created only once. */
       list<Project_Case_Association__c> projectCases = [select Id,Contract__c from Project_Case_Association__c where Contract__c in :listContractScope and Automated_Project__c = TRUE]; 
       
       for(Project_Case_Association__c pca : projectCases)
       {
            Contracts2Exclude.add(pca.Contract__c);
       }  

       Boolean elligible,Valid;

       for(Merge_Contract_Detail__c cd:listContractDetailstoCheck)
       {
         /* Initially set eligible flag to TRUE. */
         elligible = TRUE;

         /* For every Contract in the list of Contracts that already have a project associated, 
         if the Contract Detail is associated to that Contract, make the eligible flag false.*/
         for(String contract : Contracts2Exclude)
         {
             if(cd.Original_Contract_Id__c == contract)
             {
                 elligible = FALSE;
                 break;
             }
         }
         /* If the eligible flag is true then we need to check if that Contract Detail has a case associated with it. So add it in a list for further checks. */
         if(elligible)
         {
              listContractDetailstoCheckCases.add(cd);
         }
       }

       for(Merge_Contract_Detail__c cd2:listContractDetailstoCheckCases)
       {
          /* Initially set valid flag to false. */
          valid = FALSE;

          /* In the list of all cases created in the past 2 days check if the Contract Id of 
          the contracts in listContractDetailstoCheckCases match with the Contract Id of the case created. */
          for(Case c: CasesCreated)
          {
              if(c.Contract__c == cd2.Original_Contract_Id__c)
              {
                  Valid = TRUE;
                  break;
              }
          }
          if(!Valid)
          {
            //Cannot create Project as associated Case not present.  
          }
          else
          {
              /* This is the final list of all the Contract detail id's for which Projects need to be created. */
              listContractDetailstoCreateProject.add(cd2);
          }
        }
        
        /* The below block forms a map of the Contract and the corresponding Contract Detail list. */
        for(Merge_Contract_Detail__c cd1:listContractDetailstoCreateProject)
        {
           if(mapContractContractDetails == NULL || mapContractContractDetails.get(cd1.Original_Contract_Id__c) == NULL)
           {
               mapContractContractDetails.put(cd1.Original_Contract_Id__c, new list<Merge_Contract_Detail__c>{cd1});
              
           }
           else if(mapContractContractDetails.get(cd1.Original_Contract_Id__c)!= NULL)
           {
                (mapContractContractDetails.get(cd1.Original_Contract_Id__c)).add(cd1);
           }
        }       
        CreateProjects(mapContractContractDetails,CasesCreated);
    }

    global void finish(Database.BatchableContext BC)
    {
        //Changes by Sharath Prasanna for the CR 3368331: SOA
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
        //system.assertEquals(1,2);
        PSA_AutogenProjectBatch  autogenProject = new PSA_AutogenProjectBatch();
        Database.executeBatch(autogenProject,batchSize);
        
    }

    /*
    This function creates the Projects taking the map of Contract Id and list of Contract details as parameters.
     */
   
        public void CreateProjects(map<Id,list<Merge_Contract_Detail__c>> mapContractContractDetailsVar,list<Case> CasesCreated)
        {
            system.debug('Sam CreateProjects Case ' + CasesCreated + 'For Contract' + mapContractContractDetailsVar.keyset());
            //adding a new integer value here for holding the value of the 3rd parameter that is for the billing permonth.
            integer MRR,Overage,perMonth;
            list<pse__proj__c>listProj2Insert = new list<pse__proj__c>();
            list<Project_Contract__c>PCList2Insert = new list<Project_Contract__c>();
            list<Project_Contract_Line_Item__c>pclItems2Insert = new list<Project_Contract_Line_Item__c>();
            list<pse__Budget__c> listBudget2Insert = new list<pse__Budget__c>();
            list<Id> ProjectInsertedIds = new list<Id>();
            Map<Id,Merge_Contract_Detail__c> mapProjIdCD = new Map<Id,Merge_Contract_Detail__c>();
            list<Merge_Contract_Detail__c> CDUpdate = new list<Merge_Contract_Detail__c>();
            Map<Id,pse__proj__c> mapIdProj = new Map<Id,pse__proj__c>();
            List<pse__Budget__c> budgetsToUpdate = new List<pse__Budget__c>();
 
            /* Query for a list of Regions. Changing the query to get only Territory records from Region as Projects are associated with Territories 
             */
            //list<pse__Region__c> Reg = [Select Id,Name from pse__Region__c];
            list<pse__Region__c> Reg = [Select Id,Name from pse__Region__c where Name like '%(Territory)%'];

            list<Case> CaseSuccessfulUpdate = new list<Case>();
            list<Case> CaseUnsuccessfulUpdate = new list<Case>();

            //In the below map the region name will be unique because we are only querying for Territories and each Territory is unique.
            Map<String,Id> RegMap = new Map<String,Id>();

            for(pse__Region__c r:Reg)
            {
                RegMap.put(r.Name,r.Id);
            }

            //Query for the MRR template.
            pse__proj__c p2MRR =[select Id,pse__Allow_Self_Staffing__c,Ongoing_Project_Recurring_Budget_Amt__c,Ongoing_Project_Recurring_Planned_Hour__c,
                                 pse__Planned_Hours__c,pse__Allow_Timecards_Without_Assignment__c,pse__Is_Billable__c,pse__Time_Credited__c,
                                 pse__Time_Excluded__c,Months_from_Start_to_End_Date__c,pse__Daily_Timecard_Notes_Required__c,RecordtypeId,pse__Is_Active__c,pse__Project_Status__c,
                                 pse__Stage__c,pse__Practice__c,Project_Sub_Type__c,pse__Project_Type__c from pse__proj__c 
                                 where pse__Project_Type__c = 'GSS Product' and Project_Sub_Type__c = 'Service Management' and Name like '%MRR%'and pse__Is_Template__c = TRUE limit 1];
            Id p2MRRId = p2MRR.Id;

            //Query for the OS template.
            pse__proj__c p2 =[select Id,pse__Allow_Self_Staffing__c,Ongoing_Project_Recurring_Budget_Amt__c,Ongoing_Project_Recurring_Planned_Hour__c,
                              pse__Planned_Hours__c,pse__Allow_Timecards_Without_Assignment__c,pse__Is_Billable__c,pse__Time_Credited__c,
                              pse__Time_Excluded__c,pse__Daily_Timecard_Notes_Required__c,RecordtypeId,pse__Is_Active__c,pse__Project_Status__c,
                              pse__Stage__c,pse__Practice__c,Project_Sub_Type__c,pse__Project_Type__c from pse__proj__c 
                              where pse__Project_Type__c = 'GSS Product' and Project_Sub_Type__c = 'Service Management' and Name like '%(OS)%' and pse__Is_Template__c = TRUE limit 1];
            Id p2Overage = p2.Id;

            //the below custom setting is set to PSA User and we have a validation rule that does not allow TC entry when the project mgr is PSA user.
            PSA_Settings__c psa_settings = PSA_Settings__c.getInstance('Project Manager');

            //Insert Projects
            
            //loop through the list of Contracts
            For(Id cId:mapContractContractDetailsVar.keySet())
            {
                system.debug('PSA Contracts to be checked:' + cId);
                system.debug((mapContractContractDetailsVar.get(cId)).size());
                //try
                //{
                    //Every Contract should have exactly 2 Contract Line Items, one with UOM hour and the other with UOM Configuration.
                    /* Modifying the below line to check for 3 Contract details instead of 2 according to CR 3305101. */
                    //if((mapContractContractDetailsVar.get(cId)).size() == 2)
                    if((mapContractContractDetailsVar.get(cId)).size() == 3)
                    {
                        system.debug('Inside size = 3' + mapContractContractDetailsVar.get(cId));

                        /*If the UOM is Hour then this line item is associated to MRR project. If the UOM is Configuration then the line item is associated to Optimization Schedule project.*/
                        /* Modifying the below block to check for 3 Contract details instead of 2 according to CR 3305101. */
                       /* if(mapContractContractDetailsVar.get(cId)[0].Unit_of_Measure__c == 'Hour' && mapContractContractDetailsVar.get(cId)[1].Unit_of_Measure__c == 'Configurations')
                        {   
                            MRR = 0;
                            Overage = 1;
                        }
                        else if(mapContractContractDetailsVar.get(cId)[1].Unit_of_Measure__c == 'Hour' && mapContractContractDetailsVar.get(cId)[0].Unit_of_Measure__c == 'Configurations')
                        {
                            MRR = 1;
                            Overage = 0;
                        }
                        else
                        {
                            MRR = 0;
                            Overage = 0;
                        } */

                        if(mapContractContractDetailsVar.get(cId)[0].Unit_of_Measure__c == 'Hour' && mapContractContractDetailsVar.get(cId)[1].Unit_of_Measure__c == 'Configurations' && mapContractContractDetailsVar.get(cId)[2].Unit_of_Measure__c == 'Per Month')
                        {   
                            MRR = 0;
                            Overage = 1;
                            perMonth = 2;
                        }
                        else if(mapContractContractDetailsVar.get(cId)[0].Unit_of_Measure__c == 'Hour' && mapContractContractDetailsVar.get(cId)[2].Unit_of_Measure__c == 'Configurations' && mapContractContractDetailsVar.get(cId)[1].Unit_of_Measure__c == 'Per Month')
                        {
                            MRR = 0;
                            Overage = 2;
                            perMonth = 1;
                        }
                        else if(mapContractContractDetailsVar.get(cId)[1].Unit_of_Measure__c == 'Hour' && mapContractContractDetailsVar.get(cId)[0].Unit_of_Measure__c == 'Configurations' && mapContractContractDetailsVar.get(cId)[2].Unit_of_Measure__c == 'Per Month')
                        {
                            MRR = 1;
                            Overage = 0;
                            perMonth = 2;
                        }
                        else if(mapContractContractDetailsVar.get(cId)[1].Unit_of_Measure__c == 'Hour' && mapContractContractDetailsVar.get(cId)[2].Unit_of_Measure__c == 'Configurations' && mapContractContractDetailsVar.get(cId)[0].Unit_of_Measure__c == 'Per Month')
                        {
                            MRR = 1;
                            Overage = 2;
                            perMonth = 0;
                        }
                        else if(mapContractContractDetailsVar.get(cId)[2].Unit_of_Measure__c == 'Hour' && mapContractContractDetailsVar.get(cId)[0].Unit_of_Measure__c == 'Configurations' && mapContractContractDetailsVar.get(cId)[1].Unit_of_Measure__c == 'Per Month')
                        {
                            MRR = 2;
                            Overage = 0;
                            perMonth = 1;
                        }
                        else if(mapContractContractDetailsVar.get(cId)[2].Unit_of_Measure__c == 'Hour' && mapContractContractDetailsVar.get(cId)[1].Unit_of_Measure__c == 'Configurations' && mapContractContractDetailsVar.get(cId)[0].Unit_of_Measure__c == 'Per Month')
                        {
                            MRR = 2;
                            Overage = 1;
                            perMonth = 0;
                        }
                        else
                        {
                            MRR = 0;
                            Overage = 0;
                            perMonth = 0;
                        }

                        system.debug('MRR = ' + MRR + ' Overage = ' + Overage +' Per Month = '+perMonth);

                        //Modifying the below line to include the 3rd UOM that is per month
                        //if(mapContractContractDetailsVar.get(cId)[MRR].Unit_of_Measure__c == 'Hour' && mapContractContractDetailsVar.get(cId)[Overage].Unit_of_Measure__c == 'Configurations')
                        if(mapContractContractDetailsVar.get(cId)[MRR].Unit_of_Measure__c == 'Hour' && mapContractContractDetailsVar.get(cId)[Overage].Unit_of_Measure__c == 'Configurations' && mapContractContractDetailsVar.get(cId)[perMonth].Unit_of_Measure__c == 'Per Month')
                        {  
                            //Changes by sharath for CR: 3560081
                            Merge_Contract_Detail__c mrrDetail = (mapContractContractDetailsVar.get(cId))[MRR];
                            Merge_Contract_Detail__c overrageDetail = (mapContractContractDetailsVar.get(cId))[Overage];
                            Merge_Contract_Detail__c perMonthDetail = (mapContractContractDetailsVar.get(cId))[perMonth];
                            
                            Integer noOfActiveMonthsMRR = PSA_AutoCreateProjectUtil.numberOfActiveMonths(mrrDetail.Effective_End_Date__c,mrrDetail.Effective_Start_Date__c);
                            Integer noOfActiveMonthsOverrage = PSA_AutoCreateProjectUtil.numberOfActiveMonths(overrageDetail.Effective_End_Date__c,overrageDetail.Effective_Start_Date__c);
                            //Integer noOfActiveMonthsPerMonth = PSA_AutoCreateProjectUtil.numberOfActiveMonths(noOfActiveMonthsPerMonth.Effective_End_Date__c,noOfActiveMonthsPerMonth.Effective_Start_Date__c);

                            Double monthlyRecurringHours = PSA_AutoCreateProjectUtil.monthlyRecurringHours(mrrDetail);
                            //Integer noOfEngagements = PSA_AutoCreateProjectUtil.customRound((Double)(noOfActiveMonthsOverrage / 3.0));
                            Integer noOfEngagements;
                            Double noOfConfigurations = overrageDetail.Units_Low__c;
                            //Double pricePerMonth = PSA_AutoCreateProjectUtil.pricePerMonth(perMonthDetail);
                            Double pricePerMonth;
                            //End of changes by Sharath

                            pse__proj__c p1MRR = new pse__proj__c();

                            /* Create a clone from the MRR template. 
                            clone(preserveId, isDeepClone, preserveReadOnlyTimestamps, preserveAutoNumber)*/
                            p1MRR=p2MRR.clone(false,true,false,false);
                            
                            p1MRR.Name = 'Service Management_MRR';

                            /* The currency and Account Name come from the Contract. */
                            p1MRR.CurrencyIsoCode = (mapContractContractDetailsVar.get(cId))[MRR].Original_Contract_Id__r.Currency__c;
                            p1MRR.pse__Account__c = (mapContractContractDetailsVar.get(cId))[MRR].Original_Contract_Id__r.Account_Name__c;

                            /* Initially Contract closed is set to No. */
                            p1MRR.Contract_Closed__c = 'No';
                            //janantha : Modifying the below block for CR 3305101 to check for billing duration either monthly or quaterly.
                            /*if((mapContractContractDetailsVar.get(cId))[MRR].Billing_Duration__c == 'Quarterly')
                                p1MRR.pse__Billing_Type__c = 'Quarterly Commit (MRR)';
                            else
                                p1MRR.pse__Billing_Type__c = 'Monthly Commit (MRR)';*/

                            if((mapContractContractDetailsVar.get(cId))[MRR].Billing_Duration__c == 'Quarterly')
                                p1MRR.pse__Billing_Type__c = 'Quarterly Commit (MRR)';
                            else if((mapContractContractDetailsVar.get(cId))[MRR].Billing_Duration__c == 'Monthly')
                                p1MRR.pse__Billing_Type__c = 'Monthly Commit (MRR)';

                            /* Project Manager is set to PSA User. */    
                            p1MRR.pse__Project_Manager__c = psa_settings.Value__c;

                            /* start and end date of Project come from the Contract Line Item. */
                            p1MRR.pse__End_Date__c = (mapContractContractDetailsVar.get(cId))[MRR].Effective_End_Date__c;
                            p1MRR.pse__Start_Date__c = (mapContractContractDetailsVar.get(cId))[MRR].Effective_Start_Date__c;

                            try
                            {
                                /* Area field on the Account corresponds to Territory. If the Account Territory name is present in the Region map then 
                                populate that in the Region field of the Project else, leave it blank. */
                                p1MRR.pse__Region__c = RegMap.get((mapContractContractDetailsVar.get(cId))[MRR].Original_Contract_Id__r.Account_Name__r.TERR_HIER_5__c + ' (Territory)');
                            }

                            catch(Exception e)
                            {
                                p1MRR.pse__Region__c = ''; 
                            }

                            /* Initially set the value of Planned Hours, Recurring Planned Hour etc to default values. These will be changed by WF field updates. */
                            p1MRR.pse__Planned_Hours__c = 1;
                            p1MRR.Ongoing_Project_Recurring_Planned_Hour__c = 1;
                            p1MRR.SMP_Contract__c = cId;
                            p1MRR.SMP_Contract_Line_Item__c = (mapContractContractDetailsVar.get(cId))[MRR].Id; 
                            /*Start of changes by Jaya for CR 3305101*/
                            p1MRR.PCLI_MRR1__c = (mapContractContractDetailsVar.get(cId))[MRR].Id; 
                            p1MRR.PCLI_Overage1__c = (mapContractContractDetailsVar.get(cId))[Overage].Id; 
                            p1MRR.PCLI_PerMonth1__c = (mapContractContractDetailsVar.get(cId))[perMonth].Id; 
                            /*End of changes by Jaya for CR 3305101*/
                            p1MRR.Unit_Price__c = (mapContractContractDetailsVar.get(cId))[MRR].Unit_Price__c;
                            p1MRR.Units_Low__c = (mapContractContractDetailsVar.get(cId))[MRR].Units_Low__c;
                            p1MRR.Ongoing_Project_Recurring_Budget_Amt__c = 0;
                            //Changes by sharath for CR: 3560081

                            p1MRR.pse__Planned_Hours__c =  monthlyRecurringHours * noOfActiveMonthsMRR;
                            if(p1MRR.pse__Planned_Hours__c == 0.0)
                            {
                               p1MRR.pse__Planned_Hours__c = 1.0; 
                            }
                            try
                            {
                                pricePerMonth = perMonthDetail.Unit_Price__c * noOfActiveMonthsMRR;
                                noOfEngagements = PSA_AutoCreateProjectUtil.customRound((Double)(noOfActiveMonthsMRR / 3.0));
                                p1MRR.Ongoing_Project_Recurring_Budget_Amt__c =  ((monthlyRecurringHours * noOfActiveMonthsMRR) / ((noOfEngagements * noOfConfigurations * 6.0) + (monthlyRecurringHours * noOfActiveMonthsMRR)) ) * (pricePerMonth) / noOfActiveMonthsMRR;

                            }
                            catch(Exception e)
                            {
                                p1MRR.Ongoing_Project_Recurring_Budget_Amt__c  = 0;
                            }
                            //End of changes by Sharath
                             
                            //insert p1MRR;
                            system.debug('Sam MRR Project Added');

                            /* Add the MRR project to list of projects to insert. */
                            listProj2Insert.add(p1MRR);
                            //Overage Project
                            pse__proj__c p1 = new pse__proj__c();

                            /* Clone the Optimization Schedule Project. */
                            p1=p2.clone(false,true,false,false);
                            p1.ID= NULL;
                            p1.Name = 'Service Management_Optimization Schedule';

                            /* Get the Currency code and Account from the Contract. */
                            p1.CurrencyIsoCode = (mapContractContractDetailsVar.get(cId))[Overage].Original_Contract_Id__r.Currency__c;
                            p1.pse__Account__c = (mapContractContractDetailsVar.get(cId))[Overage].Original_Contract_Id__r.Account_Name__c;

                            /* Initially set Contract Closed to No. */
                            p1.Contract_Closed__c = 'No';
                            p1.Ongoing_Project_Recurring_Budget_Amt__c = 0;
                            //if((mapContractContractDetailsVar.get(cId))[Overage].Billing_Duration__c == 'Monthly')
                            //    p1.pse__Billing_Type__c = 'Monthly Commit (MRR) w/ Overage';
                            //else
                            //    p1.pse__Billing_Type__c = 'Quarterly Commit (MRR) w/ Overage';
                            p1.pse__Billing_Type__c = 'One-Time: Fixed Price';
                            p1.PCLI_MRR1__c = (mapContractContractDetailsVar.get(cId))[MRR].Id; 
                            p1.PCLI_Overage1__c = (mapContractContractDetailsVar.get(cId))[Overage].Id; 
                            p1.PCLI_PerMonth1__c = (mapContractContractDetailsVar.get(cId))[perMonth].Id;

                            /* Set the Project Manager to PSA User. */
                            p1.pse__Project_Manager__c = psa_settings.Value__c;
                            p1.pse__End_Date__c = (mapContractContractDetailsVar.get(cId))[Overage].Effective_End_Date__c;
                            p1.pse__Start_Date__c = (mapContractContractDetailsVar.get(cId))[Overage].Effective_Start_Date__c;
                            //p1.pse__practice__c = 'aAD110000004C9h';
                            try
                            {
                                p1.pse__Region__c = RegMap.get((mapContractContractDetailsVar.get(cId))[Overage].Original_Contract_Id__r.Account_Name__r.TERR_HIER_5__c + ' (Territory)');
                            }//p1MRR.pse__practice__c = 'aAD110000004C9h';
                            catch(Exception e)
                            {
                                p1.pse__Region__c = ''; 
                            }

                            /* Set default values for Planned hours, recurring planned hours etc. These would get re set from WF field updates. */ 
                            p1.pse__Planned_Hours__c = 1;
                            p1.Ongoing_Project_Recurring_Planned_Hour__c = 1;
                            p1.SMP_Contract__c = cId;
                            p1.SMP_Contract_Line_Item__c = (mapContractContractDetailsVar.get(cId))[Overage].Id;
                            p1.Unit_Price__c = (mapContractContractDetailsVar.get(cId))[Overage].Unit_Price__c;
                            p1.Units_Low__c = (mapContractContractDetailsVar.get(cId))[Overage].Units_Low__c;

                            //Changes by sharath for CR: 3560081
                            noOfEngagements = PSA_AutoCreateProjectUtil.customRound((Double)(noOfActiveMonthsOverrage / 3.0));
                            //p1.pse__Planned_Hours__c = noOfActiveMonthsOverrage/3.0 * overrageDetail.Units_Low__c * 6.0;
                            p1.pse__Planned_Hours__c = noOfEngagements * noOfConfigurations * 6.0;
                            if(p1.pse__Planned_Hours__c == 0.0)
                            {
                                p1.pse__Planned_Hours__c = 1.0; 
                            }
                            
                            try
                            {
                                pricePerMonth = perMonthDetail.Unit_Price__c * noOfActiveMonthsOverrage;                                
                                p1.Ongoing_Project_Recurring_Budget_Amt__c = ((noOfEngagements * noOfConfigurations * 6.0) / ((noOfEngagements * noOfConfigurations * 6.0) + (monthlyRecurringHours * noOfActiveMonthsOverrage)) ) * (pricePerMonth) / noOfActiveMonthsOverrage;

                            }
                            catch(Exception e)
                            {
                                p1.Ongoing_Project_Recurring_Budget_Amt__c = 0;
                            }

                            //End of changes by Sharath
                            //system.assertEquals(mapContractContractDetailsVar.get(cId)[Overage],NULL);
                            //mapProjCD.put(p1,mapContractContractDetailsVar.get(cId)[Overage]);
                            
                            /* Add the OS project to list of projects to insert. */
                            listProj2Insert.add(p1);
                            system.debug('Sam OS Project Added');
                            
                            
                        }
                    }
                //}
                //catch(Exception e)
                //{
                  //  system.debug('###'+ e.getMessage());
                   // continue;
                //}
            }
            try
            {
                Database.Upsert(listProj2Insert);
            }
            Catch(Exception e)
            {
                system.debug(e.getMessage());
            }
            system.debug('Sam Project DML Insert');
            Boolean successfulCase = False;

            /* The below block is to create associated Project Cases for each Project that was created successfully. */
            for(case c1:CasesCreated)
            {
               successfulCase = False;
               for(pse__proj__c p1:listProj2Insert)
               {
                 if(c1.contract__c == p1.SMP_Contract__c && p1.Id!= NULL)
                 {
                     Project_Case_Association__c pca1 = new Project_Case_Association__c();
                     system.debug('Sam Case Project Added inside if');
                     pca1.Case__c = c1.Id;
                     pca1.Project__c = p1.Id;
                     pca1.Contract__c = c1.contract__c;
                     if((p1.Name).contains('MRR'))
                      pca1.Name = 'Service Management_MRR';
                     else
                      pca1.Name = 'Service Management_Optimization Schedule';   
                     pca1.Automated_Project__c = True;
                     projectCases2Insert.add(pca1);
                     successfulCase = True;  
                 }
               }

               /* Update the case description saying the projects were created or not created successfully. */
               if(successfulCase)
               {
                 c1.Description = 'Please refer to the detailed SMP 2.0 on-boarding steps located at:\n https://agora.akamai.com/wiki/GSS_products_SMP2_fulfillment#Onboarding \n\n Please note that MRR & OS Salesforce projects have been automatically created:\nLinks to Projects can be found on the Project Case Association Related List section of the Case\n\nPlease follow these guidelines on project assignment & usage:\nhttps://agora.akamai.com/wiki/GSS_products_SMP2_fulfillment#Automated_Project_Creation'; 
                 CaseSuccessfulUpdate.add(c1); 
               }
               else if(!((c1.description.contains('Please note that'))))
               {
                  c1.Description = 'Please refer to the detailed SMP 2.0 on-boarding steps located at:\n https://agora.akamai.com/wiki/GSS_products_SMP2_fulfillment#Onboarding\n\n<### PROJECT NOT CREATED ###>\n\nPlease note that due to contract set-up the MRR & OS Salesforce projects have not been automatically created.\n\nPlease follow these guidelines on how to create the projects: https://agora.akamai.com/wiki/GSS_products_SMP2_fulfillment#Manual_Project_Creation';
                  CaseSuccessfulUpdate.add(c1);
               }
            }

            //Insert the Project Case records.
            Database.Upsert(projectCases2Insert,False);

            //Update case description.
            Database.Update(CaseSuccessfulUpdate,False);
            system.debug('Sam Project Case DML Insert');
            
            //Insert Budget Records and also create list of ids of inserted projects
            //After the Projects are inserted, we need to insert the budget, Milestone, PC and PCLI.
            for(pse__proj__c pb:listProj2Insert)
            {
                pse__Budget__c b1= new pse__Budget__c();
                b1.pse__Billable__c = pb.pse__Is_Billable__c;
                b1.pse__Project__c = pb.Id;
                b1.pse__Account__c = pb.pse__Account__c;
                b1.pse__Status__c = 'Approved';
                
                b1.pse__Type__c = 'Customer Purchase Order';
                b1.pse__Approved__c = TRUE;
                b1.pse__Effective_Date__c = pb.pse__Start_Date__c;
                b1.pse__Amount__c = 0;
                /*if(pb.Name.contains('MRR'))
                {

                  b1.pse__Amount__c = pb.Budget_MRR_Amount__c;
                }
                else if(pb.Name.contains('Optimization Schedule'))
                {
                  b1.pse__Amount__c = pb.Budget_Overage_Amount__c;
                }*/
                //b1.Ongoing_Project_Recurring_Budget_Amt__c = 0;
                listBudget2Insert.add(b1);
                ProjectInsertedIds.add(pb.Id);
            }
            List<Database.UpsertResult> budgetResults = new List<Database.UpsertResult>();
            List<Id> budgetSuccesses = new List<Id>();
            try
            {
                budgetResults = Database.Upsert(listBudget2Insert,false);
            }
            catch(exception e)
            {
                //Proceed with rest of execution
            }
            for(Database.UpsertResult budget:budgetResults)
            {
              if (budget.isSuccess()) 
              {
                budgetSuccesses.add(budget.getId());
              }
              /*if(budget.pse__Project__r.Name.contains('MRR'))
              {
                budget.pse__Amount__c = budget.pse__Project__r.Budget_MRR_Amount__c;
              }
              else if(budget.pse__Project__r.Name.contains('Optimization Schedule'))
              {
                budget.pse__Amount__c = budget.pse__Project__r.Budget_Overage_Amount__c;
              }
              budgetsToUpdate.add(budget);*/
            }
            for(pse__Budget__c budget:[select Id, pse__Amount__c, pse__Project__r.Name, pse__Project__r.Ongoing_Project_Recurring_Budget_Amt__c, pse__Project__r.pse__Start_Date__c,pse__Project__r.pse__End_Date__c from pse__Budget__c where Id in :budgetSuccesses])
            {
              //if(budget.pse__Project__r.Name.contains('MRR'))
              //{

              //  //budget.pse__Amount__c = budget.pse__Project__r.Budget_MRR_Amount__c;
              //}
              //else if(budget.pse__Project__r.Name.contains('Optimization Schedule'))
              //{

              //  //budget.pse__Amount__c = budget.pse__Project__r.Budget_Overage_Amount__c;
              //}
              //Changes by sharath for CR: 3560081: computing the budget amount from the project recurring budget amount
              budget.pse__Amount__c = budget.pse__Project__r.Ongoing_Project_Recurring_Budget_Amt__c * PSA_AutoCreateProjectUtil.numberOfActiveMonths(budget.pse__Project__r.pse__Start_Date__c, budget.pse__Project__r.pse__End_Date__c);

              budgetsToUpdate.add(budget);
            }
            update budgetsToUpdate;
            insertMilestones(ProjectInsertedIds,p2MRRId,p2Overage);
            insertPCLItems(ProjectInsertedIds);
        }

        /* This function inserts Milestones for the MRR and the OS Projects. */
        public void insertMilestones(list<Id> projIds,Id ProjMRRTemplate,ID ProjOverageTemplate)
        {
            //Changes by sharath for CR: 3560081: Changed the query: added the field Ongoing_Project_Recurring_Budget_Amt__c and pse__Planned_Hours__c
            list<pse__proj__c> p = [select Id,Name,pse__Start_Date__c,pse__End_Date__c,Months_from_Start_to_End_Date__c,PCLI_MRR1__r.Effective_Start_Date__c,PCLI_MRR1__r.Effective_End_Date__c,pse__Billing_Type__c,PCLI_MRR1__r.Billing_Duration__c,PCLI_MRR1__r.Units_Low__c,PCLI_Overage1__r.Units_Low__c,PCLI_PerMonth1__r.Unit_Price__c,MRR_Milestone_Planned_Hours__c,Ongoing_Project_Recurring_Budget_Amt__c,pse__Planned_Hours__c from pse__proj__c where Id in :projIds];
            list<pse__Milestone__c>listMAdd = new list<pse__Milestone__c>();
            Integer mrrBillingDuration;
            Integer mrrBillingType; 
            Decimal activeMonths;     

            //Query for all the Milestones from the MRR project template.
            list<pse__Milestone__c> m1MRR = [select Id,Name,RecordtypeID,Billable__c,pse__Status__c,Task_Milestone_Name__c,pse__Description__c,
                                             pse__Milestone_Amount__c,Milestone_Type_List__c,Milestone_Type_Value__c,pse__Planned_Hours__c from pse__Milestone__c where pse__Project__c = :ProjMRRTemplate];

            //Query for all the Milestones from the OS project template.
            list<pse__Milestone__c> m1 = [select Id,Name,RecordtypeID,Billable__c,pse__Status__c,Task_Milestone_Name__c,pse__Description__c,
                                          pse__Milestone_Amount__c,Milestone_Type_List__c,Milestone_Type_Value__c,pse__Planned_Hours__c from pse__Milestone__c where pse__Project__c = :ProjOverageTemplate];
            for(pse__proj__c p1: p)
            {
                
                /* If the project is an MRR project then clone the MRR Milestones. */
                if(p1.Name.contains('MRR'))
                {
                    activeMonths = p1.Months_from_Start_to_End_Date__c;
                    mrrBillingDuration = (p1.pse__Billing_Type__c=='Quarterly Commit (MRR)'?3:1);
                    mrrBillingType = (p1.PCLI_MRR1__r.Billing_Duration__c == 'Quarterly'?3:1);

                    for(pse__Milestone__c m:m1MRR)
                    {
                        pse__Milestone__c m2 = m.clone(false,true,false,false);
                        //m2.Id = NULL;
                        m2.Start_Date__c = p1.pse__Start_Date__c;
                        m2.pse__Target_Date__c = p1.pse__End_Date__c;
                        m2.pse__Project__c = p1.Id;
                        //Start of changes by janantha for populating the Milestone Amount.
                        //Changes by sharath: if the milestone is Maintenance:Billable, compute the planned hours and amount
                        if (m2.name.contains('Maintenance'))
                        {
                            //m2.pse__Milestone_Amount__c = (((p1.PCLI_MRR1__r.Units_Low__c / mrrBillingDuration) * activeMonths) / (((p1.PCLI_MRR1__r.Units_Low__c / mrrBillingDuration) * activeMonths) + (Math.round(activeMonths/3) * p1.PCLI_Overage1__r.Units_Low__c * 6))) * p1.PCLI_PerMonth1__r.Unit_Price__c * activeMonths;
                            //m2.pse__Planned_Hours__c = p1.MRR_Milestone_Planned_Hours__c;
                            //Changes by sharath for CR: 3560081: computing the amount from the project's recurring budget amount
                            m2.pse__Milestone_Amount__c = p1.Ongoing_Project_Recurring_Budget_Amt__c * PSA_AutoCreateProjectUtil.numberOfActiveMonths(p1.pse__Start_Date__c,p1.pse__End_Date__c);
                            m2.pse__Planned_Hours__c = p1.pse__Planned_Hours__c;
                        }
                        else
                        {
                            m2.pse__Milestone_Amount__c = 0;
                            m2.pse__Planned_Hours__c = 0; 
                        }
                        //End of changes by janantha for populating the Milestone Amount.
                        listMAdd.add(m2);
                    }
                }
                /* If the project is OS then clone the Milestones from OS project. */
                else if(p1.Name.contains('Optimization Schedule'))
                {
                    for(pse__Milestone__c m:m1)
                    {
                        //system.assertequals(1,0);
                        pse__Milestone__c m2 = m.clone(false,true,false,false);
                        //m2.Id = NULL;
                        m2.Start_Date__c = p1.pse__Start_Date__c;
                        m2.pse__Target_Date__c = p1.pse__End_Date__c;
                        m2.pse__Project__c = p1.Id;
                        listMAdd.add(m2);
                    }
                }
            }
            Database.Upsert(listMAdd,False);
        }

        /* This function inserts the PC's and PCLI's. */
        public void insertPCLItems(list<Id> projIds)
        {
            list<pse__proj__c> p = [select Id,Name,SMP_Contract__c,pse__Account__c,SMP_Contract_Line_Item__c,SMP_Automated_Project__c from pse__proj__c where Id in :projIds];
            Set<Id> ContractLI = new Set<Id>();
            list<pse__proj__c> Proj2Update = new list<pse__proj__c>();
            list<Project_Contract__c> projConList = new list<Project_Contract__c>();
            list<Project_Contract_Line_Item__c> PCLI2Insert = new list<Project_Contract_Line_Item__c>();
            list<Merge_Contract_Detail__c>List2Update = new list<Merge_Contract_Detail__c>();
            map<pse__proj__c,Project_Contract__c> ProjProjContractMap = new map<pse__proj__c,Project_Contract__c>();
            
            /* The below block creates a list of Project Contracts to insert and forms a map of Project and Project Contract. */
            for(pse__proj__c p1:p)
            {
                Project_Contract__c pc = new Project_Contract__c();
                pc.Project__c = p1.Id;
                pc.Original_Contract_Id__c = (Id)(p1.SMP_Contract__c);
                pc.Account__c = p1.pse__Account__c;
                projConList.add(pc);
                ProjProjContractMap.put(p1,pc);
                
            }

            //Insert all the project contracts.
            Database.Upsert(projConList,False);

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

                /* Final step is to update the flag - 'SMP Automated Project' to TRUE and set the Contract closed to TRUE. */
                p2.SMP_Automated_Project__c = TRUE;
                p2.Contract_Closed__c = 'Yes';
                Proj2Update.add(p2);
                
            }

            //Insert the PCLI's and update the Contract closed and the Automated Project flags on Project.
            Database.Upsert(PCLI2Insert,False);
            Database.update(Proj2Update,False);
            
        }

    }