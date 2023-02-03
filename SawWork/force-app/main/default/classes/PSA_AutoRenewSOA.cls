/*
 * JIRA : FFPSA-636
 * Developer: Suhas Jain
 * Feature: Automated Renewal of Projects
 * Date: 31st Aug 2020
 *
 * 17th Nov 2020            Sandeep Naga            FFPSA-1771      Compliance issue fix to change budget amount and ongoing project recurring budget amount to 1
*/ 

public with sharing class PSA_AutoRenewSOA implements PSA_AutoRenewInterface {

    public PSA_AutogenObjectList autoRenewInstanceList;
    public PSA_Autogen__mdt autogenMDT;

    public PSA_AutoRenewSOA() {
        autoRenewInstanceList = new PSA_AutogenObjectList();        
        // Query the CMD to find the Name of the Autogen Use case
        autogenMDT = [SELECT Id,Autogen_Usecase__c,Product_Id__c,ProjectCase_Name__c FROM PSA_Autogen__mdt WHERE Product_Name__c = 'SOA' WITH SECURITY_ENFORCED limit 1];
            
    }

    public PSA_AutogenObjectList renewProjects(Map<pse__Proj__c,Project_Contract_Line_Item__c> projectsToPCLIMap, Map<String,Map<String,Merge_Contract_Detail__c>> contractSetupMap)
    {
        
        Double monthlyRecurringHours;
        Integer monthsPerBillPeriod = 0;
        Integer noOfActiveMonths;
        Boolean addProject = False;

        Project_Contract_Line_Item__c pcli;
       
        // Loop through all the Projects and Extend all the Project and its associated object records with Relavent values since this List already contains only the Project which has the right contract setup
        for(pse__Proj__c proj: projectsToPCLIMap.keySet())
        {
            pcli = projectsToPCLIMap.get(proj);

            System.debug('proj.Id: '+proj.Id);
            System.debug('pcli.Id: '+pcli.Id);

            Double pricePerMonth;
            Double reviewUnitsLow = 0.0;
            Integer noOfSecurityReviews = 0;
            Decimal noOfSecurityReviewsPerYear = 0;
            Integer noOfSecurityReviewsNew = 0;
            Integer noOfActiveMonthsCA;
            Integer noOfActiveMonthsCAnewTerm = 0;
            Integer noOfActiveMonthsMRR ;
            Integer noOfActiveMonthsSSR;
            Integer noOfActiveMonthsSSRnewTerm;
            Double recurringCommittedHours =  0.0;
            String billingDuration = '';
            Double mrr = 0.0;


            // Additional Check , but check also included in batch query
            if(!pcli.ProjectDateInSync__c)
            {

                Merge_Contract_Detail__c tempCLI = new Merge_Contract_Detail__c(); // Creating dummy CLI since pricePerMonth accepts CLI 
                tempCLI.Effective_Start_Date__c = pcli.Effective_Start_Date__c;
                tempCLI.Effective_End_Date__c = pcli.Effective_End_Date__c;
                tempCLI.Unit_Price__c = pcli.Unit_Price__c;
                tempCLI.Units_Low__c = pcli.Units_Low__c;

                String key = String.valueOf(pcli.Original_Contract_Id__c) + String.valueOf(pcli.Effective_Start_Date__c) + String.valueOf(pcli.Effective_End_Date__c);

                try {
                    if ((contractSetupMap.get(key)).get('Hour').Record_Type__c == 'Committed' ) {
                        billingDuration = (contractSetupMap.get(key)).get('Hour').Billing_Duration__c ;
                    }
                } catch (Exception e) {
                    System.debug('billing duration not present');
                }

                if ((contractSetupMap.get(key)).get('Hour').Record_Type__c == 'Committed' ) {
                    billingDuration = (contractSetupMap.get(key)).get('Hour').Billing_Duration__c ;
                }
                
                System.debug('pcli.Contract_Detail__r.Billing_Duration__c: '+pcli.Contract_Detail__r.Billing_Duration__c);
                
                // Months per billing period is calculated based on the Billing Duration field on the CLI
                switch on billingDuration {
                    when  'Annual' { monthsPerBillPeriod = 12; }
                    when  'Quarterly' { monthsPerBillPeriod = 3; }
                    when  'Monthly' { monthsPerBillPeriod = 1; }
                    when else { monthsPerBillPeriod = 0; }
                }

                // Call the genric method to check the no of months between the dates of the PCLI
                noOfActiveMonths = PSA_AutoCreateProjectUtil.numberOfActiveMonths(pcli.Effective_Start_Date__c,pcli.Effective_End_Date__c);      
                pricePerMonth = PSA_AutoCreateProjectUtil.pricePerMonth(tempCLI);

                noOfActiveMonthsCA = PSA_AutoCreateProjectUtil.numberOfActiveMonths( (contractSetupMap.get(key)).get('Hour').Effective_Start_Date__c , (contractSetupMap.get(key)).get('Hour').Effective_End_Date__c);      

                noOfActiveMonthsCAnewTerm = PSA_AutoCreateProjectUtil.numberOfActiveMonths( Date.today() , (contractSetupMap.get(key)).get('Hour').Effective_End_Date__c );

                noOfActiveMonthsMRR = PSA_AutoCreateProjectUtil.numberOfActiveMonths( (contractSetupMap.get(key)).get('Per Month').Effective_Start_Date__c , (contractSetupMap.get(key)).get('Per Month').Effective_End_Date__c );

                noOfActiveMonthsSSR = PSA_AutoCreateProjectUtil.numberOfActiveMonths( (contractSetupMap.get(key)).get('Reviews').Effective_Start_Date__c , (contractSetupMap.get(key)).get('Reviews').Effective_End_Date__c );

                noOfActiveMonthsSSRnewTerm = PSA_AutoCreateProjectUtil.numberOfActiveMonths( Date.today() , (contractSetupMap.get(key)).get('Reviews').Effective_End_Date__c );

                try {
                    if ( (contractSetupMap.get(key) ).get('Reviews').Record_Type__c == 'Committed') {
                        noOfSecurityReviewsPerYear = (contractSetupMap.get(key) ).get('Reviews').Units_Low__c ;
                    }
                } catch (Exception e) {
                    System.debug('noOfSecurityReviewsPerYear not present , setting to zero');
                    noOfSecurityReviewsPerYear = 0;
                }

                try {
                    if ((contractSetupMap.get(key)).get('Per Month').Record_Type__c == 'Committed' ) {
                        mrr = (contractSetupMap.get(key)).get('Per Month').Unit_Price__c ;
                    }
                    
                } catch (Exception e) {
                    System.debug('mrr vaalue not present');
                    mrr = 0.0;
                }

                try {
                    if( (contractSetupMap.get(key)).get('Hour').Record_Type__c == 'Committed')
                    {
                        recurringCommittedHours = (contractSetupMap.get(key)).get('Hour').Units_Low__c ;
                    }
                } catch (Exception e) {
                    System.debug('recurringCommittedHours not present , setting to zero');
                    recurringCommittedHours = 0.0;
                }
                
                System.debug('noOfActiveMonths:'+noOfActiveMonths);


                try {
                    if ( (contractSetupMap.get(key) ).get('Reviews').Record_Type__c == 'Committed' ) {
                        reviewUnitsLow = (contractSetupMap.get(key) ) .get('Reviews').Units_Low__c ; 
                    }
                    
                } catch (Exception e) {
                    System.debug('error in getting Units low for review cli - SOA');
                    reviewUnitsLow = 0;
                }

                // No of Secuirty Review for SOA is calculated only for the CLI which has the record type as commited.
                if(noOfSecurityReviewsPerYear != 0 ){
                    noOfSecurityReviews = ( (( noOfSecurityReviewsPerYear /12 ) * noOfActiveMonthsSSR).round(System.RoundingMode.HALF_UP) ).intValue() ;
                    noOfSecurityReviewsNew = ( (( noOfSecurityReviewsPerYear /12 ) * noOfActiveMonthsSSRnewTerm ).round(System.RoundingMode.HALF_UP) ).intValue();
                    System.debug('check two vals : ' + noOfSecurityReviewsNew + ' and this : ' + noOfActiveMonthsSSRnewTerm );
                }

                try{                    
                    monthlyRecurringHours = recurringCommittedHours / monthsPerBillPeriod;
                }
                catch(Exception e){
                    monthlyRecurringHours = 0;
                }
                System.debug('monthlyRecurringHours : '+ monthlyRecurringHours);


                System.debug('noOfSecurityReviews:'+noOfSecurityReviews);

                proj.pse__End_Date__c = pcli.Effective_End_Date__c ;
                proj.Ongoing_Project_Recurring_Planned_Hour__c = monthlyRecurringHours;

                try {
                    proj.Ongoing_Project_Recurring_Budget_Amt__c = ( (monthlyRecurringHours * noOfActiveMonthsCA ) / ( (monthlyRecurringHours * noOfActiveMonthsCA ) + (noOfSecurityReviews * 20 ) ) ) * (pricePerMonth) / noOfActiveMonths;
                    
                } catch (Exception e) {
                    System.debug('Error in calculating the field value Ongoing_Project_Recurring_Budget_Amt__c for proj :' + proj);
                    String error ='Exception type caught: ' + e.getTypeName() + '</br>Message: ' + e.getMessage() + '</br>Cause: ' + e.getCause() + '</br>Line number: ' + e.getLineNumber() + '</br>Stack trace: ' + e.getStackTraceString();    
                }

                
                
                // Stampping the date as Today since the Current Contract Term start date will be considered on the day on which the project was extended
                proj.Current_Contract_Term_Start_Date__c = Date.today();


                // Planned Hours formula is differnet for SOA Projects that is linked to Hours and Reviews (Hour's Project and Review's Project)
                if( pcli.Contract_Detail__r.Unit_of_Measure__c == 'Hour'  ){
                    proj.Current_Contract_Term_Planned_Hours_Num__c = monthlyRecurringHours * noOfActiveMonthsCAnewTerm ;

                    try {
                        proj.pse__Planned_Hours__c = (recurringCommittedHours/ monthsPerBillPeriod) * noOfActiveMonthsCA ;
                    } catch (Exception e) {
                        System.debug('error in calculating pse__Planned_Hours__c for Hours CLI');
                    }
                    
                    try {
                        proj.Ongoing_Project_Recurring_Budget_Amt__c =( ( (monthlyRecurringHours * noOfActiveMonthsCA ) / ( (monthlyRecurringHours * noOfActiveMonthsCA ) + (noOfSecurityReviews * 20 ) ) ) * ( mrr * noOfActiveMonthsMRR ) )/ noOfActiveMonthsCA ;
                    } catch (Exception e) {
                        System.debug('error in calculating Ongoing_Project_Recurring_Budget_Amt__c for Hours CLI');
                    }

                    addProject = True;
                    autoRenewInstanceList.renewedProjectsIds.add(proj.id);
                }

                
                else if(pcli.Contract_Detail__r.Unit_of_Measure__c == 'Reviews')
                {
                    proj.Ongoing_Project_Recurring_Planned_Hour__c = 0;
                    proj.pse__Planned_Hours__c = noOfSecurityReviews * 20;
                    proj.Current_Contract_Term_Planned_Hours_Num__c = noOfSecurityReviewsNew * 20 ;

                    try {
                        proj.Ongoing_Project_Recurring_Budget_Amt__c =( ( (noOfSecurityReviews * 20 ) / ( (monthlyRecurringHours * noOfActiveMonthsSSR ) + (noOfSecurityReviews * 20 ) ) ) * ( mrr * noOfActiveMonthsMRR ) )/ noOfActiveMonthsSSR ;
                        
                    } catch (Exception e) {
                        System.debug(' error in calculating Ongoing_Project_Recurring_Budget_Amt__c for review cli');
                    }

                    addProject = True;

                    // After the Project is extended, if the no of milestones is lesser than the no of secuirty review, create the delta no of Milestones
                    if(proj.pse__milestones__r != null && !proj.pse__milestones__r.isEmpty() && proj.pse__milestones__r.size() < noOfSecurityReviews)
                    {
                        for (integer i =0 ; i < noOfSecurityReviews - proj.pse__milestones__r.size(); i ++ ) {
                            pse__Milestone__c newMile = new pse__Milestone__c();
                            //newMile = proj.pse__milestones__r[0].clone(false , true , false , false );
                            newMile.Task_Milestone_Name__c = 'Secuirty Service Review';
                            newMile.pse__Project__c = proj.id;
                            newMile.Milestone_Type_List__c = 'Delivery';
                            newMile.Billable__c = true;
                            newMile.Start_Date__c = Date.today();
                            newMile.pse__Start_Date__c = Date.today();
                            newMile.pse__Target_Date__c = pcli.Effective_End_Date__c;
                            autoRenewInstanceList.milestonesForUpsert.add(newMile);
                        }
                    }
                    autoRenewInstanceList.renewedProjectsIds.add(proj.id);
                }

                // Extending the Budget records with relavant info
                for(pse__Budget__c budget: proj.pse__Budgets__r ){
                    
                    if ( pcli.Contract_Detail__r.Unit_of_Measure__c == 'Reviews' ) {
                        System.debug('Review things :: noOfSecurityReviews :' + noOfSecurityReviews + ' ::monthlyRecurringHours : ' + monthlyRecurringHours + ' ::noOfActiveMonthsSSR ' + noOfActiveMonthsSSR + ' ::mrr :: ' + mrr + ' :: noOfSecurityReviews :: ' + noOfSecurityReviews + ' ::noOfActiveMonthsMRR :: ' + noOfActiveMonthsMRR );
                        try {
                            budget.pse__Amount__c = ( (noOfSecurityReviews * 20) / ( ( monthlyRecurringHours * noOfActiveMonthsSSR ) + (noOfSecurityReviews * 20) ) ) * ( mrr * noOfActiveMonthsMRR ) ;
                        } catch (Exception e) {
                            System.debug('Error in calculating Budget amount for Project : review ' + proj);
                            String error ='Exception type caught: ' + e.getTypeName() + '</br>Message: ' + e.getMessage() + '</br>Cause: ' + e.getCause() + '</br>Line number: ' + e.getLineNumber() + '</br>Stack trace: ' + e.getStackTraceString();    
                        }
                    }
                    
                    if (pcli.Contract_Detail__r.Unit_of_Measure__c == 'Hour') {
                        System.debug('HORS thing :: monthlyRecurringHours :' + monthlyRecurringHours + ' ::noOfActiveMonthsCA : ' + noOfActiveMonthsCA + ' ::noOfSecurityReviews ' + noOfSecurityReviews + ' ::mrr :: ' + mrr + ' :: noOfActiveMonthsMRR :: ' + noOfActiveMonthsMRR );
                        try {
                            budget.pse__Amount__c = ( ( monthlyRecurringHours * noOfActiveMonthsCA ) / (( monthlyRecurringHours * noOfActiveMonthsCA ) + ( noOfSecurityReviews * 20 ) ) ) * ( mrr * noOfActiveMonthsMRR ) ;
                        } catch (Exception e) {
                            System.debug('Error in calculating Budget amount for Project : Hour ' + proj);
                            String error ='Exception type caught: ' + e.getTypeName() + '</br>Message: ' + e.getMessage() + '</br>Cause: ' + e.getCause() + '</br>Line number: ' + e.getLineNumber() + '</br>Stack trace: ' + e.getStackTraceString();    
                        }
                        
                    }

                    //FFPSA-1771 Compliance issue fix
                    if(budget.pse__Amount__c == 0){
                        budget.pse__Amount__c = 1;
                    }
                    //budget.pse__Amount__c = monthlyRecurringHours * noOfActiveMonths; 
                    autoRenewInstanceList.budgetsForUpsert.add(budget);
                }


                // Extending the already present milestone with new PCLI end dates 
                for (pse__Milestone__c milestone : proj.pse__milestones__r ) {
                    milestone.pse__Target_Date__c = pcli.Effective_End_Date__c;
                    autoRenewInstanceList.milestonesForUpsert.add(milestone);
                }

                // Inorder to extend the assignments , extend its associated Schedule
                for (pse__Assignment__c assignment : proj.pse__Assignments__r) {
                    //assignment.pse__End_Date__c = pcli.Effective_End_Date__c;
                    pse__Schedule__c schedule = new pse__Schedule__c();
                    schedule.id = assignment.pse__Schedule__c;
                    schedule.pse__End_Date__c = pcli.Effective_End_Date__c;
                    autoRenewInstanceList.schedulesForUpsert.add(schedule);
                    //autoRenewInstanceList.assignmentsForUpsert.add(assignment);
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
                

                //FFPSA-1771 Compliance issue fix
                if(proj.Ongoing_Project_Recurring_Budget_Amt__c == 0){
                    proj.Ongoing_Project_Recurring_Budget_Amt__c = 1;
                }

                autoRenewInstanceList.projectsForUpsert.add(proj);
            }
            System.debug('proj:'+proj);

        }

        // Returning the List autoRenewInstanceList to the batch class to Perform the upsert operation for all the records at once.
        return autoRenewInstanceList;

    }
}