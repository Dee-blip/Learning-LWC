/*
 * JIRA : FFPSA-636
 * Developer: Suhas Jain
 * Feature: Automated Renewal of Projects
 * Date: 31st Aug 2020
 *
*/ 
public with sharing class PSA_AutoRenewPlus implements PSA_AutoRenewInterface {

    public PSA_AutogenObjectList autoRenewInstanceList;
    public PSA_Autogen__mdt autogenMDT;

    public PSA_AutoRenewPlus() {
        autoRenewInstanceList = new PSA_AutogenObjectList();        
        // Make sure we can update the database before even trying
        // Query the CMD to find the Name of the Autogen Use case
        autogenMDT = [SELECT Id,Autogen_Usecase__c,Product_Id__c,ProjectCase_Name__c FROM PSA_Autogen__mdt WHERE Product_Name__c = 'PLUS_PSHOURS' WITH SECURITY_ENFORCED limit 1];
            
    }

    public PSA_AutogenObjectList renewProjects(Map<pse__Proj__c,Project_Contract_Line_Item__c> projectsToPCLIMap, Map<String,Map<String,Merge_Contract_Detail__c>> contractSetupMap)
    {
        
        Double monthlyRecurringHours;
        Integer noOfMonthlsPerBillingPeriod = 0;
        Integer noOfActiveMonths;
        Integer noOfActiveMonthsnewTerm = 0 ;
        Integer noOfMonthlyReports = 0;
        Boolean addProject = False;

        
        Project_Contract_Line_Item__c pcli;

        
        for(pse__Proj__c proj: projectsToPCLIMap.keySet())
        {
            pcli = projectsToPCLIMap.get(proj);

            System.debug('proj.Id: '+proj.Id);
            System.debug('pcli.Id: '+pcli.Id);
            // Additional Check , but check also included in batch query
            if(!pcli.ProjectDateInSync__c)
            {

                noOfActiveMonths = PSA_AutoCreateProjectUtil.numberOfActiveMonths(pcli.Effective_Start_Date__c,pcli.Effective_End_Date__c);
                noOfActiveMonthsnewTerm = PSA_AutoCreateProjectUtil.numberOfActiveMonths( Date.today() ,pcli.Effective_End_Date__c  );

                System.debug('noOfActiveMonths:'+noOfActiveMonths);
                proj.pse__End_Date__c = pcli.Effective_End_Date__c ;
                proj.Current_Contract_Term_Start_Date__c = Date.today();
                addProject = True;

                //Monthly Service Report Project
                if( pcli.Contract_Detail__r.Unit_of_Measure__c == 'Configurations'){
                    noOfMonthlyReports = noOfActiveMonths;
                    proj.pse__Planned_Hours__c = noOfMonthlyReports * 2;
                    proj.Current_Contract_Term_Planned_Hours_Num__c = noOfActiveMonthsnewTerm * 2;
                    try{
                        proj.Ongoing_Project_Recurring_Planned_Hour__c = proj.pse__Planned_Hours__c/noOfActiveMonths;
                    }
                    catch(Exception e)
                    {
                        proj.Ongoing_Project_Recurring_Planned_Hour__c = 0;
                    }
                }
                //PS Hours project
                else if( pcli.Contract_Detail__r.Unit_of_Measure__c == 'Hour'){
                    noOfMonthlsPerBillingPeriod = 3;
                    try{
                        monthlyRecurringHours = pcli.Contract_Detail__r.Units_Low__c / noOfMonthlsPerBillingPeriod;
                    }
                    catch(Exception e)
                    {
                        monthlyRecurringHours = 0;
                    }
                    proj.pse__Planned_Hours__c = noOfActiveMonths * monthlyRecurringHours;
                    proj.Ongoing_Project_Recurring_Planned_Hour__c = monthlyRecurringHours ;
                    proj.Current_Contract_Term_Planned_Hours_Num__c = monthlyRecurringHours * noOfActiveMonthsnewTerm ;
                }
    
                
                
                autoRenewInstanceList.renewedProjectsIds.add(proj.id);
                
    
                for (pse__Milestone__c milestone : proj.pse__milestones__r ) {
                    milestone.pse__Target_Date__c = pcli.Effective_End_Date__c;
                    autoRenewInstanceList.milestonesForUpsert.add(milestone);
                }
    
                for (pse__Assignment__c assignment : proj.pse__Assignments__r) {
                    //assignment.pse__End_Date__c = pcli.Effective_End_Date__c;
                    
                    pse__Schedule__c schedule = new pse__Schedule__c();
                    schedule.id = assignment.pse__Schedule__c;
                    schedule.pse__End_Date__c = pcli.Effective_End_Date__c;
                    autoRenewInstanceList.schedulesForUpsert.add(schedule);

                    autoRenewInstanceList.assignmentsForUpsert.add(assignment);
                }

        	}	

            System.debug('Date.today(): '+Date.today());
            System.debug('Date.today().addDays(7): '+Date.today().addDays(7));

            //For all the projects which are ending in 7 days, create offboarding case, pca and stamp flag on project.
            if(!proj.Project_Off_Boarded__c && proj.pse__End_Date__c >= Date.today() && proj.pse__End_Date__c <= Date.today().addDays(7)){
                
                try{
                    //Create offboarding case                
                    Case offboardingCase = SC_Utility.createOffboardingCase(autogenMDT.Autogen_Usecase__c, proj, pcli.Original_Contract_Id__c, False);
                    
                    //offboardingCase.External_Id_for_Migration__c = proj.External_Id__c;
                    autoRenewInstanceList.casesForUpsert.add(offboardingCase);
                }
                catch(Exception e){
                    String error ='Exception type caught: ' + e.getTypeName() + '</br>Message: ' + e.getMessage() + '</br>Cause: ' + e.getCause() + '</br>Line number: ' + e.getLineNumber() + '</br>Stack trace: ' + e.getStackTraceString();    
                    PSA_AutoCreateProjectUtil.sendErrorMails('There was as error at offboarding case: projId:'+proj.Id,error);                    
                }
                
                try{
                    //Create project case association record                
                    autoRenewInstanceList.pcaForUpsert.add(PSA_AutoRenewProjectsUtil.createOffboardingProjectCaseAssociation(proj,pcli));
                
                }
                catch(Exception e){
                    String error ='Exception type caught: ' + e.getTypeName() + '</br>Message: ' + e.getMessage() + '</br>Cause: ' + e.getCause() + '</br>Line number: ' + e.getLineNumber() + '</br>Stack trace: ' + e.getStackTraceString();    
                    PSA_AutoCreateProjectUtil.sendErrorMails('There was as error at project Case association : projId:'+proj.Id,error);
                }
                
                //Stamp flag on project
                proj.Project_Off_Boarded__c = True;
                addProject = True;
                                           
            }
            
            if(addProject){
                if (proj.pse__Planned_Hours__c == 0) {
                    proj.pse__Planned_Hours__c = 1;
                }
                autoRenewInstanceList.projectsForUpsert.add(proj);
            }
            
            System.debug('proj:'+proj);
            
        }

        return autoRenewInstanceList;

    }
}