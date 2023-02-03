/*
 * CR: FFPSA-598
 * Developer: Sharath Prasanna
 * Enhancement: Automated creation of projects for PNP: SOA + SMP
 * Date: 24th October 2018
 * 
 *
 * CR: FFPSA-814
 * Developer: Sandeep Naga
 * Enhancement: Updating feeSchedule value, frequency scaling and currency exchange calculation
 * Date: 5th Decemeber 2018
 */ 
public class PSA_AutoCreatePPN_SOA_SMP implements PSA_AutogenInterface 
{
    public PSA_Autogen__mdt autogenPNP;
    public PSA_AutogenObjectList autogenPNPList;
    public Map<String,pse__Proj__c> projTemplates;
    public Map<String,Double> externalIdToBudgetMap ;
    //public Set<String> productIds;
    public PSA_AutoCreatePPN_SOA_SMP() 
    {
        autogenPNP = [select Autogen_Usecase__c,Product_Id__c,ProjectCase_Name__c from PSA_Autogen__mdt where Product_Name__c = 'PPN-SOA-SMP' limit 1];
        autogenPNPList = new PSA_AutogenObjectList();
        projTemplates = new Map<String,pse__Proj__c>();
        externalIdToBudgetMap = new Map<String,Double>();

        //productIds.addAll(autogenPNP.Product_Id__c.split(','));
    }
    public void getContractDetails(List<Merge_Contract_Header__c> ListContractScope,List<Merge_Contract_Detail__c> ListContractDetailstoCheck,List<Case> CasesCreated,List<Project_Case_Association__c> projectCases)
    {

    }

    public PSA_AutogenObjectList getContractDetailsForUpsert(List<Merge_Contract_Header__c> ListContractScope,List<Merge_Contract_Detail__c> ListContractDetailstoCheck,List<Case> CasesCreated,List<Project_Case_Association__c> projectCases, Map<String,pse__Proj__c> projTemplatesMap)
    {
        
        for (PSA_ProjectTemplates__mdt templates :[select Name__c,Parent_Autogen__c, Sub_Type__c, Type__c from PSA_ProjectTemplates__mdt where Parent_Autogen__c = :autogenPNP.id order by DeveloperName])
        {
            if(projTemplatesMap.containsKey(templates.Name__c) && projTemplatesMap.get(templates.Name__c).pse__Project_Type__c == templates.Type__c && projTemplatesMap.get(templates.Name__c).Project_Sub_Type__c == templates.Sub_Type__c)
            {
                projTemplates.put(templates.Name__c,projTemplatesMap.get(templates.Name__c));
            }
        }

        if(projTemplates.size() != 3)
        {
            PSA_AutoCreateProjectUtil.sendErrorMails('The template setup is not correct',
                'The templates with the name Professional Services/MRR - Project Template,GSS Products/Security Optimization Assistance_Service_Review - Project Template,GSS Products/Service Management (OS) - Project Template is either not found or more than one template with that name exists.');
            return autogenPNPList;
        }

        Map<Id,List<Merge_Contract_Detail__c>> mapContractContractDetails = new Map<Id,List<Merge_Contract_Detail__c>>();

        List<Merge_Contract_Detail__c> contractDetailForPNP = new List<Merge_Contract_Detail__c>();
        //This is the map of contract Id to case, this is used to not consider those cases that has associated projects
        Map<Id,List<Case>> contractToCases = new Map<Id,List<Case>>();
        List<Case> casesForPNP = new List<Case>();
        Set<Id> ContractIds = new Set<Id>();
        //Loop over the cases and get all the cases with usecase value PNP
        for (Case caseToCheck: CasesCreated)
        {
            if(caseToCheck.Autogen_UseCase__c == autogenPNP.Autogen_Usecase__c) 
            {
                ContractIds.add(caseToCheck.Contract__c);
                if(!contractToCases.containsKey(caseToCheck.Contract__c))
                {
                	contractToCases.put(caseToCheck.Contract__c,new List<Case>());	
                }

                contractToCases.get(caseToCheck.Contract__c).add(caseToCheck);
            }
        }

        //loop over the projectcases and get all the records that has the Automated_Project_Type__c as PNP
        for (Project_Case_Association__c projectCaseToCheck: projectCases)
        {
            if(projectCaseToCheck.Automated_Project_Type__c == autogenPNP.ProjectCase_Name__c)
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
        	for(Id contractToCasesKey: contractToCases.keySet())
        	{
        		casesForPNP.addAll(contractToCases.get(contractToCasesKey));	
        	}
            
        }
        

        //loop over the contract details and get all those contract details that satisfy the requirements for the PNP project creation. UOM -> Hour (recordtype -> Usage or Committed) or Per Month or Each; The effective Start date should not be in the future
        for(Merge_Contract_Detail__c detail: ListContractDetailstoCheck)
        {
            if( ContractIds.contains(detail.Original_Contract_Id__c) && detail.Effective_Start_Date__c<=system.today() && detail.Record_Type__c == 'Committed' && 
                   ( ( detail.Product_Id__c == 'M-LC-162635' && detail.Unit_of_Measure__c == 'Reviews') || ( detail.Product_Id__c == 'M-LC-162752' && detail.Unit_of_Measure__c == 'Per Month')  || (detail.Product_Id__c == 'M-LC-162752' && detail.Unit_of_Measure__c == 'Hour') || (detail.Product_Id__c == 'M-LC-162764' && detail.Unit_of_Measure__c == 'Configurations'))  )
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
             CreateProjects(mapContractContractDetails,casesForPNP); 
             
       }
       
            

       //if no details are found to conform to the PNP requirements, update all the PNP case descrption
       else if(casesForPNP != null && casesForPNP.size() > 0)
       {
            
       
            for (Case caseToUpdate: casesForPNP)
            {
                    if(ContractIds.contains(caseToUpdate.Contract__c))
                    {
                        if(caseToUpdate.description == null)
                        {
                            caseToUpdate.description = '';   
                        }
                        if(!(caseToUpdate.description.contains('PROJECTS NOT CREATED')) && caseToUpdate.Service__c == 'Security Optimization Assistance')
                        {

                            caseToUpdate.Description += '\n\n<<### PROJECTS NOT CREATED ###>\n\nPlease note that due to contract set-up PS Hours and Security Service Review Salesforce projects have not been automatically created.\n\nPlease follow these guidelines on how to create the projects:\nhttps://ac.akamai.com/docs/DOC-43991';
                        }
                        else if(!(caseToUpdate.description.contains('PROJECTS NOT CREATED')) && caseToUpdate.Service__c == 'Service Management')
                        {
                            caseToUpdate.Description += '\n\n<<### PROJECTS NOT CREATED ###>\n\nPlease note that due to contract set-up PS-Hours & OS Salesforce projects have not been automatically created.\n\nPlease follow these guidelines on how to create the projects:\nhttps://ac.akamai.com/docs/DOC-43991';

                        }
                    }

            }
            autogenPNPList.casesForUpsert.addAll(casesForPNP);
       }        

       return autogenPNPList;
    }
    public void CreateProjects(Map<Id,List<Merge_Contract_Detail__c>> mapContractContractDetails,List<Case> cases)
    {
        
        List<pse__proj__c> ListProj2Insert = new List<pse__proj__c>();
        List<pse__Budget__c> ListBudget2Insert = new List<pse__Budget__c>();
        List<Id> ProjectInsertedIds = new List<Id>();


        List<Case> caseSuccessfulUpdate = new List<Case>();
        List<pse__Budget__c> budgetsToUpdate = new List<pse__Budget__c>();
        List<Project_Case_Association__c> projectCases2Insert = new List<Project_Case_Association__c>();
        
        Map<Id, Map<String,Case>> contractIdToCaseService = new Map<Id, Map<String,Case>>();

        pse__proj__c SMPTemplate = projTemplates.get('GSS Products/Service Management (OS) - Project Template');

        pse__proj__c SOATemplate = projTemplates.get('GSS Products/Security Optimization Assistance_Service_Review - Project Template');

        pse__proj__c MRRTemplate = projTemplates.get('Professional Services/MRR - Project Template');

        

        for(case pnpCase: cases)
        {
            
        	if(!contractIdToCaseService.containsKey(pnpCase.contract__c))
        	{
        		contractIdToCaseService.put(pnpCase.contract__c,new Map<String,Case>());	
        	}
        	if(pnpCase.Service__c == 'Security Optimization Assistance')
        	{
        		contractIdToCaseService.get(pnpCase.contract__c).put('Security Optimization',pnpCase);
        	}
        	else if(pnpCase.Service__c == 'Service Management')
        	{
        		contractIdToCaseService.get(pnpCase.contract__c).put('SMP 2.0',pnpCase);
        	}
        }

        


        //loop through the List of Contracts
        for(Id cId:mapContractContractDetails.keySet())
        {
           
            //Create a map of Unit of Measure and the Index of the corresponding contract detail 
            //in the mapContractContractDetails.get list
            Merge_Contract_Detail__c perMonthCli;
            Merge_Contract_Detail__c hourCli;
            Merge_Contract_Detail__c configurationCli;
            Merge_Contract_Detail__c reviewCli;

            

            if((mapContractContractDetails.get(cId)).size() > 1 && contractIdToCaseService.get(cId).size() == 2)
            {


                for(Merge_Contract_Detail__c contractDetail: mapContractContractDetails.get(cId))
                {
                    if(contractDetail.Unit_of_Measure__c =='Hour')
                    {      
                    	hourCli = (hourCli == null || contractDetail.LastModifiedDate > hourCli.LastModifiedDate)?contractDetail : hourCli;             	
                    }

                    else if (contractDetail.Unit_of_Measure__c =='Per Month')
                    {
                    	perMonthCli = (perMonthCli == null || contractDetail.LastModifiedDate > perMonthCli.LastModifiedDate)?contractDetail : perMonthCli;             	
                    }
                    else if(contractDetail.Unit_of_Measure__c =='Reviews')
                    {
                    	reviewCli = (reviewCli == null || contractDetail.LastModifiedDate > reviewCli.LastModifiedDate)?contractDetail : reviewCli;             	

                    }
                    else if (contractDetail.Unit_of_Measure__c =='Configurations')
                    {
                    	configurationCli = (configurationCli == null || contractDetail.LastModifiedDate > configurationCli.LastModifiedDate)?contractDetail : configurationCli;          
                    }
                }

                
                
                Double noOfSecurityReviewsPerYear;
                Double securityServiceReviews;
                Double totalReviewHours;

                //Integer frequencyPerYear;
                Double frequencyPerYear;
                Double noConfigurationsUnderOS;                
                
                Integer noOfActiveMonthsSMP;
                Integer noOfActiveMonthsSSR;				
				Integer noOfActiveMonthsMRR;

                Integer noOfActiveMonthsMRRPerMonth;

                //Changes Made by Sandeep Naga for FFPSA-814 : Part 1

                Double annual_revenue_SSR;
                Double annual_revenue_SMP;
                Double annual_revenue_MRR;

                Double total_annual_revenue = 0;
                Double revenue_allocation_SSR = 0;
                Double revenue_allocation_SMP = 0;
                Double revenue_allocation_MRR = 0;

                Double plannedHoursSSR;
                Double plannedHoursSMP;
                Double plannedHoursMRR;

				Double noOfEngagements;
				Double recurringCommittedHours;
				Double numberOfMonthsPerBillingPeriod;
				Double monthlyRecurringHours;

                Double ongoingRecurringBudgetAmount;
                Double projectBudgetAmountSSR;
                Double projectBudgetAmountSMP;
                Double projectBudgetAmountMRR;

                Double MRRPerMonth= 0;
                     

                String feeSchedule;  

                PSA_Common_Setting__mdt frequencyFunction = [SELECT type__c from PSA_Common_Setting__mdt where Label = 'PNP Autogen frequencyPerYear' limit 1];    

                if(perMonthCli != null)
                {
                    //MRR is 0, Unit price or Unit High * Unit Price
                    if(perMonthCli.Unit_Price__c == null || perMonthCli.Units_High__c == null)
                        MRRPerMonth = 0;
                    else if(perMonthCli.Units_High__c == 1)               
                        MRRPerMonth = perMonthCli.Unit_Price__c;   
                    else if(perMonthCli.Units_High__c > 1)
                        MRRPerMonth = perMonthCli.Units_High__c * perMonthCli.Unit_Price__c;

                    
                    
                 

                    noOfActiveMonthsMRRPerMonth = PSA_AutoCreateProjectUtil.numberOfActiveMonths(perMonthCli.Effective_Start_Date__c,perMonthCli.Effective_End_Date__c);      
                    

                    

                    //INITIALIZE Project 1: SOA
                    if(reviewCli != null)
                    {
                    		
                        
    					switch on reviewCli.Billing_Duration__c 
    					{
                            when 'Annual' 
                            {
                               frequencyPerYear = 1;
                            }
                            when 'Quarterly' 
                            {
                               frequencyPerYear = 4;
                            }
                            when 'Monthly' 
                            {
                               frequencyPerYear = 12;
                            }
                            when null 
                            {
                               frequencyPerYear = 0;
                               //frequencyPerYear = 12;
                            }
                            when else 
                            {
                               frequencyPerYear = 12;
                            }
    					}  
                        
                        

                        noOfActiveMonthsSSR = PSA_AutoCreateProjectUtil.numberOfActiveMonths(reviewCli.Effective_Start_Date__c,reviewCli.Effective_End_Date__c);      
                        noOfSecurityReviewsPerYear = reviewCli.Units_Low__c != null ? reviewCli.Units_Low__c : 0;

                        if(noOfActiveMonthsSSR > = 12)
                        {
                            frequencyPerYear = frequencyPerYear * noOfActiveMonthsSSR / 12.0;
                            if(frequencyFunction.type__c.equals('round'))
                                frequencyPerYear = PSA_AutoCreateProjectUtil.customRound(frequencyPerYear);
                            else if(frequencyFunction.type__c.equals('ceil'))
                                frequencyPerYear = Math.ceil(frequencyPerYear);
                        }


                        annual_revenue_SSR = (noOfSecurityReviewsPerYear * 20.0 * 350.0 * frequencyPerYear);
                        total_annual_revenue = total_annual_revenue + annual_revenue_SSR;
                        
                        securityServiceReviews = PSA_AutoCreateProjectUtil.securityServiceReviews(reviewCli);
                        totalReviewHours = securityServiceReviews * 20.0;
                        plannedHoursSSR = totalReviewHours == 0? 1 : totalReviewHours;
                    }                     

                    //INITIALIZE THE SECOND PROJECT ->  SMP
                    if(configurationCli != null)
                    {
                        
                        switch on configurationCli.Billing_Duration__c 
                        {
                            when 'Annual' 
                            {
                               frequencyPerYear = 1;
                            }
                            when 'Quarterly' 
                            {
                               frequencyPerYear = 4;
                            }
                            when 'Monthly' 
                            {
                               frequencyPerYear = 12;
                            }
                            when null 
                            {
                               frequencyPerYear = 0;
                               //frequencyPerYear = 12;
                            }
                            when else 
                            {
                               frequencyPerYear = 12;
                            }
                        }                          
                        
                        
                        noOfActiveMonthsSMP = PSA_AutoCreateProjectUtil.numberOfActiveMonths(configurationCli.Effective_Start_Date__c,configurationCli.Effective_End_Date__c);
                        noConfigurationsUnderOS = configurationCli.Units_Low__c != null ? configurationCli.Units_Low__c : 0;
                        noOfEngagements = PSA_AutoCreateProjectUtil.customRound((Double)(noOfActiveMonthsSMP / 3.0));
                        
                        if(noOfActiveMonthsSMP > = 12)
                        {
                            frequencyPerYear = frequencyPerYear * noOfActiveMonthsSMP / 12.0;
                            if(frequencyFunction.type__c.equals('round'))
                                frequencyPerYear = PSA_AutoCreateProjectUtil.customRound(frequencyPerYear);
                            else if(frequencyFunction.type__c.equals('ceil'))
                                frequencyPerYear = Math.ceil(frequencyPerYear);
                        }

                        annual_revenue_SMP = (noConfigurationsUnderOS * 24.0 * 300.0 * frequencyPerYear);
                        total_annual_revenue = total_annual_revenue + annual_revenue_SMP;


                        plannedHoursSMP = noOfEngagements * noConfigurationsUnderOS * 6.0;
                        plannedHoursSMP = plannedHoursSMP == 0? 1.0 : plannedHoursSMP;
                    }

                    //INITIALIZE THE THIRD PROJECT -> PS Hours               
                    if(hourCli != null)
                    {
                                          
                        switch on hourCli.Billing_Duration__c 
                        {
                            when 'Quarterly' 
                            {
                               numberOfMonthsPerBillingPeriod = 3;
                               frequencyPerYear = 4;
                               feeSchedule = 'Quarterly Commit (MRR) w/ Overage';
                            }
                            when 'Monthly' 
                            {
                               numberOfMonthsPerBillingPeriod = 1;
                               frequencyPerYear = 12;
                               feeSchedule = 'Monthly Commit (MRR) w/ Overage';
                            }
                            when 'Annual'
                            {
                                numberOfMonthsPerBillingPeriod = 1;
                                frequencyPerYear = 1;
                                feeSchedule = 'Annual Commit (ARR)';
                            }
                            when null 
                            {
                               numberOfMonthsPerBillingPeriod = 0;
                               frequencyPerYear = 0;
                               //frequencyPerYear = 12;
                               feeSchedule = 'Monthly Commit (MRR) w/ Overage';
                            }      
                            when else 
                            {
                               numberOfMonthsPerBillingPeriod = 1;
                               frequencyPerYear = 12;
                               feeSchedule = 'Monthly Commit (MRR) w/ Overage';
                            }
                        }  

                       
                        noOfActiveMonthsMRR = PSA_AutoCreateProjectUtil.numberOfActiveMonths(hourCli.Effective_Start_Date__c,hourCli.Effective_End_Date__c);
                        recurringCommittedHours = hourCli.Units_Low__c != null ? hourCli.Units_Low__c : 0;  
                        monthlyRecurringHours = numberOfMonthsPerBillingPeriod == 0? 0 : (recurringCommittedHours / numberOfMonthsPerBillingPeriod);
                        //The ongoing recurring planned hours value is monthlyRecurringHours
                        
                        if(noOfActiveMonthsMRR > = 12)
                        {
                            frequencyPerYear = frequencyPerYear * noOfActiveMonthsMRR / 12.0;
                            if(frequencyFunction.type__c.equals('round'))
                                frequencyPerYear = PSA_AutoCreateProjectUtil.customRound(frequencyPerYear);
                            else if(frequencyFunction.type__c.equals('ceil'))
                                frequencyPerYear = Math.ceil(frequencyPerYear);
                        }

                        
                        annual_revenue_MRR = (((recurringCommittedHours * 24.0) / 42.0 * 350.0) + 
                            ((recurringCommittedHours * 18.0) / 42.0 * 300.0)) * frequencyPerYear;
                        total_annual_revenue = total_annual_revenue + annual_revenue_MRR; 
                        

                        plannedHoursMRR = (monthlyRecurringHours * noOfActiveMonthsMRR) ;
                        if(plannedHoursMRR == 0.0)
                        {
                            plannedHoursMRR = 1.0;   
                        }


                    }

                        
                    

                    //Find total revenue allocation and revenue allocation for each project
                    //total_annual_revenue = annual_revenue_SSR + annual_revenue_SMP + annual_revenue_MRR;
                    try{
                        revenue_allocation_SSR = annual_revenue_SSR/total_annual_revenue;
                    }
                    catch(Exception e){
                        revenue_allocation_SSR = 0;
                    }

                    try{
                        revenue_allocation_SMP = annual_revenue_SMP/total_annual_revenue;
                    }
                    catch(Exception e){
                        revenue_allocation_SMP = 0;
                    }

                    try{
                        revenue_allocation_MRR = annual_revenue_MRR/total_annual_revenue;
                    }
                    catch(Exception e){
                        revenue_allocation_MRR = 0;
                    }


                    //Creating the projects
                    //CreateProjectWithTemplate(name,template,contractId,detail,product,mrr, overrage,permonth,  billingType, ongoingRecurringBudgetAmount, plannedHours)
                    
                    //The formula for the ongoingRecurringBudgetAmount can result in Exceptions -> divide by zero or zero by zero errors. in this case set the value to 0


                    //Create PROJECT 1 : SOA		                
                          
                    if(reviewCli != null)     
                    {             
                        if(hourCli != null && configurationCli != null )
                            ongoingRecurringBudgetAmount = revenue_allocation_SSR * (MRRPerMonth);
                        else
                            ongoingRecurringBudgetAmount = 0.23 * (MRRPerMonth);
                    
                        pse__proj__c project1 = new pse__proj__c();
                        project1 = PSA_AutoCreateProjectUtil.createProjectWithTemplate('Protect & Perform-Security Service Review',SOATemplate,cId,reviewCli,autogenPNP.ProjectCase_Name__c,reviewCli.Id, reviewCli.Id, perMonthCli.Id, 'One-Time: Fixed Price',ongoingRecurringBudgetAmount,plannedHoursSSR);                                     
                        project1.Ongoing_Project_Recurring_Planned_Hour__c = 0;
                        project1.External_Id__c = String.valueOf(reviewCli.Id) + String.valueOf(perMonthCli.Id) + autogenPNP.ProjectCase_Name__c + String.valueOf(system.now());

                        projectBudgetAmountSSR = ongoingRecurringBudgetAmount * noOfActiveMonthsMRRPerMonth;

                        externalIdToBudgetMap.put(project1.External_Id__c,projectBudgetAmountSSR);

                        ListProj2Insert.add(project1);
                    }
                



                //Create PROJECT 2 : SMP               
                    
                    if(configurationCli != null)
                    {                   
                        if(hourCli != null && reviewCli != null)
                            ongoingRecurringBudgetAmount = revenue_allocation_SMP * (MRRPerMonth);
                        else
                            ongoingRecurringBudgetAmount = 0.16 * (MRRPerMonth);

                        pse__proj__c project2 = new pse__proj__c();                   
                        project2 = PSA_AutoCreateProjectUtil.createProjectWithTemplate('Protect & Perform-Optimization Schedule',SMPTemplate,cId,configurationCli,autogenPNP.ProjectCase_Name__c,configurationCli.Id, configurationCli.Id, perMonthCli.Id, 'One-Time: Fixed Price',ongoingRecurringBudgetAmount,plannedHoursSMP);
                        project2.Ongoing_Project_Recurring_Planned_Hour__c = 0;
                        project2.External_Id__c = String.valueOf(configurationCli.Id) + String.valueOf(perMonthCli.Id) + autogenPNP.ProjectCase_Name__c + String.valueOf(system.now());

                        projectBudgetAmountSMP = ongoingRecurringBudgetAmount * noOfActiveMonthsMRRPerMonth;

                        externalIdToBudgetMap.put(project2.External_Id__c,projectBudgetAmountSMP);

                        ListProj2Insert.add(project2);
                    }
                 
                

                

		        //Create PROJECT 3 : MRR/PS HOURS                        
               
                    if(hourCli != null)
                    {
                        if(reviewCli != null && configurationCli != null)
                        {
                            ongoingRecurringBudgetAmount = revenue_allocation_MRR * (MRRPerMonth);
                            

                        }
                        else
                        {
                            ongoingRecurringBudgetAmount = 0.61 * (MRRPerMonth);


                        }
                        
                        pse__proj__c project3 = new pse__proj__c();                   
                        //project3 = PSA_AutoCreateProjectUtil.createProjectWithTemplate('Protect & Perform-Hours',MRRTemplate,cId,hourCli,autogenPNP.ProjectCase_Name__c,hourCli.Id, hourCli.Id, perMonthCli.Id, 'One-Time: Fixed Price',ongoingRecurringBudgetAmount,PlannedHours);
                        project3 = PSA_AutoCreateProjectUtil.createProjectWithTemplate('Protect & Perform-Hours',MRRTemplate,cId,hourCli,autogenPNP.ProjectCase_Name__c,hourCli.Id, hourCli.Id, perMonthCli.Id, feeSchedule,ongoingRecurringBudgetAmount,plannedHoursMRR );                    
                        project3.Ongoing_Project_Recurring_Planned_Hour__c = monthlyRecurringHours;
                        project3.External_Id__c = String.valueOf(hourCli.Id) + String.valueOf(perMonthCli.Id) + autogenPNP.ProjectCase_Name__c + String.valueOf(system.now());

                        projectBudgetAmountMRR = ongoingRecurringBudgetAmount * noOfActiveMonthsMRRPerMonth;

                        externalIdToBudgetMap.put(project3.External_Id__c,projectBudgetAmountMRR);
                                           
                        ListProj2Insert.add(project3);
                    }
                

                }
            }
        } 

        //Adding the list of projects to be created to the create object to be returned to the main class
        autogenPNPList.projectsForUpsert.addAll(ListProj2Insert);
        
        Boolean successfulCase = False;
        Map<Id,Map<String,pse__Proj__c>> contractToProjectLists = new Map<Id,Map<String,pse__Proj__c>>();

        //Create a map of contract to project -> 1 contract can be linked to any number of projects
        
        for(pse__proj__c p1:ListProj2Insert)
        {  
            //externalIdToPlannedHours.put(p1.External_Id__c,p1.pse__Planned_Hours__c);
            if(!contractToProjectLists.containsKey(p1.SMP_Contract__c))
            {
                contractToProjectLists.put(p1.SMP_Contract__c,new Map<String,pse__Proj__c>());    
            }            
            contractToProjectLists.get(p1.SMP_Contract__c).put(p1.Name,p1);
        }

        //Loop over the cases: create the Project_Case_Association__c record for the project created. if the project is not created for a case -> update the description 






		String successSMP = '\n\nPlease note that PS-Hours & OS Salesforce projects have been automatically created:\n' + 'Links to Projects can be found on the Project Case Association Related List section of the Case \n\n' + 'Please follow these guidelines on project assignment & usage:\n' + 'https://ac.akamai.com/docs/DOC-9413';
		String successSOA = '\n\nPlease note that PS Hours and Security Service Review Salesforce projects have been automatically created:\n' + 'Links to Projects can be found on the Project Case Association Related List section of the Case \n\n' + 'Please follow these guidelines on project assignment & usage:\n' + 'https://ac.akamai.com/docs/DOC-9413';
        
      
        String errorSMP =   '\n\n<### PROJECTS NOT CREATED ###>\n\n'+
                                'Please note that due to contract set-up the PS-Hours & OS Salesforce projects have not been automatically created.'+
                                '\n\nPlease follow these guidelines on how to create the projects:\nhttps://ac.akamai.com/docs/DOC-43991';
        String errorSOA =   '\n\n<### PROJECTS NOT CREATED ###>\n\n'+
                                'Please note that due to contract set-up PS Hours and Security Service Review Salesforce projects have not been automatically created.'+
                                '\n\nPlease follow these guidelines on how to create the projects:\nhttps://ac.akamai.com/docs/DOC-43991';

        String partialSuccess = '\n\nDue to contract set-up, only some projects could be automatically created. \n\n<### PROJECTS SUCCESSFULLY CREATED ###>\n';
        String partialFailure  = '\n\n<### PROJECTS NOT CREATED ###>\n';
        String documentLink = '\nPlease follow these guidelines on how to create the projects:\n' + 
        						'https://ac.akamai.com/docs/DOC-43991';

        for(Id caseContract:contractIdToCaseService.keySet())
        {
            Case caseSOA = contractIdToCaseService.get(caseContract).get('Security Optimization');  
            Case caseSMP = contractIdToCaseService.get(caseContract).get('SMP 2.0');

            String smpSuccess = '';
            String soaSuccess = '';
            String smpFail = '';
            String soaFail = '';

            if(caseSOA != null && caseSMP != null)
            {
                    if(caseSOA.Description == null)
                    {
                        caseSOA.Description = '';
                    }

                    if(caseSMP.Description == null)
                    {
                        caseSMP.Description = '';
                    }

                    caseSOA.Description = caseSOA.Description.replaceAll(errorSOA,'');              
                    caseSMP.Description = caseSMP.Description.replaceAll(errorSMP,'');              

                    if(contractToProjectLists.containsKey(caseContract))
                     {  

                        Project_Case_Association__c pca1;
                        pse__proj__c projVar;

                        if(contractToProjectLists.get(caseContract).containsKey('Protect & Perform-Security Service Review'))
                        {
                                projVar = contractToProjectLists.get(caseContract).get('Protect & Perform-Security Service Review');
                                pca1 = PSA_AutoCreateProjectUtil.createProjectCaseAssociationRecordExternalid(projVar,caseSOA.Id,caseContract,'Protect & Perform-Security Service Review',autogenPNP.ProjectCase_Name__c);
                                projectCases2Insert.add(pca1);
                                soaSuccess += 'Security Service Review\n';

                        }
                        else
                        {   
                                soaFail += 'Security Service Review\n';
                        }
                        if(contractToProjectLists.get(caseContract).containsKey('Protect & Perform-Optimization Schedule'))
                        {
                                projVar = contractToProjectLists.get(caseContract).get('Protect & Perform-Optimization Schedule');
                                pca1 = PSA_AutoCreateProjectUtil.createProjectCaseAssociationRecordExternalid(projVar,caseSMP.Id,caseContract,'Protect & Perform-Optimization Schedule',autogenPNP.ProjectCase_Name__c);
                                projectCases2Insert.add(pca1);
                                smpSuccess += 'Optimization Schedule\n';
                        }
                        else
                        {
                                smpFail += 'Optimization Schedule\n';
                        }
                        if(contractToProjectLists.get(caseContract).containsKey('Protect & Perform-Hours'))
                        {
                                projVar = contractToProjectLists.get(caseContract).get('Protect & Perform-Hours');

                                pca1 = PSA_AutoCreateProjectUtil.createProjectCaseAssociationRecordExternalid(projVar,caseSMP.Id,caseContract,'Protect & Perform-Hours',autogenPNP.ProjectCase_Name__c);

                                projectCases2Insert.add(pca1);                        
                                
                                pca1 = PSA_AutoCreateProjectUtil.createProjectCaseAssociationRecordExternalid(projVar,caseSOA.Id,caseContract,'Protect & Perform-Hours',autogenPNP.ProjectCase_Name__c);                        
                                projectCases2Insert.add(pca1);

                                soaSuccess += 'PS-Hours\n';
                                smpSuccess += 'PS-Hours\n';
                        }
                        else
                        {
                                soaFail += 'PS-Hours\n';
                                smpFail += 'PS-Hours\n';
                        }
                        if(contractToProjectLists.get(caseContract).size() == 3)
                        {
                            caseSOA.Description += successSOA;
                            caseSMP.Description += successSMP;

                        }
                        else
                        {                
                            String caseFinalDescription;
                            if(soaSuccess == '')
                            {
                                caseFinalDescription = errorSOA;
                            }
                            else if(soaFail == '')
                            {
                                caseFinalDescription = successSOA;
                            }
                            else
                            {
                                caseFinalDescription = partialSuccess + soaSuccess + partialFailure + soaFail + documentLink;
                            }
                            caseSOA.Description += caseFinalDescription;

                            if(smpSuccess == '')
                            {
                                caseFinalDescription = errorSMP;
                            }
                            else if(smpFail == '')
                            {
                                caseFinalDescription = successSMP;
                            }
                            else
                            {
                                caseFinalDescription = partialSuccess + smpSuccess + partialFailure + smpFail + documentLink;
                            }
                            
                            caseSMP.Description += caseFinalDescription;
                        }
                    }
                    else
                    {
                        caseSOA.Description += errorSOA;
                        caseSMP.Description += errorSMP;

                    }
                    // Update the case description saying the projects were created or not created successfully.
                    caseSuccessfulUpdate.add(caseSOA);
                    caseSuccessfulUpdate.add(caseSMP);

            }
        
        }

        //Adding the list of project case records to be created to the object to be returned to the main class
        autogenPNPList.pcaForUpsert.addAll(projectCases2Insert);


        //Update case description.
        autogenPNPList.casesForUpsert.addAll(caseSuccessfulUpdate);        
        
        ////To create the budget with specific name -> create a map of project name to budget name. This is to be passed as the second parameter
        Map<String,String> ProjectNametoBudgetName = new Map<String,String>();
        ProjectNametoBudgetName.put('Protect & Perform-Security Service Review','Security_Service_Review');
        ProjectNametoBudgetName.put('Protect & Perform-Optimization Schedule','Optimization_Schedule');
        ProjectNametoBudgetName.put('Protect & Perform-Hours','PS');

        //createBudgetWithName(projects, type, ProjectNametoBudgetName)
        listBudget2Insert = PSA_AutoCreateProjectUtil.createBudgetWithNameExternalId(ListProj2Insert,'Customer Purchase Order',ProjectNametoBudgetName);

        Double projectBudget = 0;
        //Map the project external id based budget amount to the budget value based on budget external id as the project external id and budget external id are the same.
        for(pse__Budget__c budget : listBudget2Insert)
        {
            projectBudget = externalIdToBudgetMap.get(budget.External_Id__c);
            budget.pse__Amount__c = projectBudget;
        }

        //Adding the list of budget records to be created to the object to be returned to the main class
        autogenPNPList.budgetsForUpsert.addAll(listBudget2Insert);


       //If all milestones of a project should have a constant value, create a map of the project name to the constant value. Similarly for the planned hours, create a map of  the project name to the constant value. 
       //If the milestone amount has to be set from the project -> project.Ongoing_Project_Recurring_Budget_Amt__c * project.Months_from_Start_to_End_Date__c, create a list of the milestone names.
       //If the milestone planned hours has to be set from the project, create a list of the milestone names -> milestone.pse__Planned_Hours__c = project.pse__Planned_Hours__c
       List<pse__Milestone__c> milestones = new List<pse__Milestone__c>();
       
       List<String> setAmountFromProject = new List<String> ();
       setAmountFromProject.add('Optimization Schedule');
       
       Map<String,Integer> setDefaultPlannedHoursProjectToHours = new Map<String,Integer>();
       setDefaultPlannedHoursProjectToHours.put('Protect & Perform-Optimization Schedule',24);
       setDefaultPlannedHoursProjectToHours.put('Protect & Perform-Security Service Review',20);
       //createMilestones (List<pse__Proj__c> projects, List<String> setAmountFromProject,List<String> setPlannedhoursFromProject, Map<String,Double> setDefaultAmountProjectToAmount,Map<String,Integer> setDefaultPlannedHoursProjectToHours)
        milestones = PSA_AutoCreateProjectUtil.createMilestonesExternalId(ListProj2Insert,setAmountFromProject,null,null,setDefaultPlannedHoursProjectToHours);
        
        for(pse__Milestone__c milestoneRecord :milestones)
        {
        	if(milestoneRecord.pse__Milestone_Amount__c != 0)
        	{
        		milestoneRecord.pse__Milestone_Amount__c = ((Double)milestoneRecord.pse__Milestone_Amount__c / 4.0);	
        	}
        }
        //Adding the list of milestone records to be created to the object to be returned to the main class
        autogenPNPList.milestonesForUpsert.addAll(milestones);

       

    }

    

}