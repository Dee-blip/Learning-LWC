public class PSA_Contract_Detail_Actions
{
    
    public static void checkForBillingEffectiveDateUpdate(List<Merge_Contract_Detail__c> oldList, List<Merge_Contract_Detail__c> newList,Boolean isDelete) {    
        
        Map<Id, Merge_Contract_Detail__c> newMap;
        
        if (newList != null && newList.size() > 0) {
            newMap = new Map<Id, Merge_Contract_Detail__c>(newList);
        }   
        Map<Id, pse__Proj__c> projectsToUpdate = new Map<Id, pse__Proj__c>();
        Set<Id> contractLineIds = new Set<Id>();
        Set<Id> projectIds = new Set<Id>();
        Set<Id> cliPSHours = new Set<Id>();
        
        /*18.8 for PS hours calculation*/
        List<Id> psHourProjectIds = new List<Id>();
        List<PSA_Common_Setting__mdt> products = new List<PSA_Common_Setting__mdt>([SELECT Value_Long__c 
                                                                                    FROM PSA_Common_Setting__mdt 
                                                                                    WHERE Name__c = 'GSS Protect and Perform Products']);
        Set<String> productList = new Set<String>();
        
        for(PSA_Common_Setting__mdt product : products)
        {
            for(String str :product.Value_Long__c.split(',') )
            {
                productList.add(str.trim());
            }
            //productList.addAll(new Set<String>(product.Value_Long__c.split(',')) );
        }
        
        if (isDelete) {
            /* after delete */
            for (Merge_Contract_Detail__c contRow : oldList) {
                contractLineIds.add(contRow.Id);
            }
        } else {
            /* after update */
            for (Merge_Contract_Detail__c contRow : oldList) {
                if (newMap.get(contRow.Id).Effective_Start_Date__c != contRow.Effective_Start_Date__c) {
                    contractLineIds.add(contRow.Id);
                }
                
                //18.8 store all CLI Ids criteria meets PSHours
                if (newMap.get(contRow.Id).Effective_Start_Date__c != NULL && newMap.get(contRow.Id).Effective_Start_Date__c != contRow.Effective_Start_Date__c && newMap.get(contRow.Id).Unit_of_Measure__c != null && newMap.get(contRow.Id).Unit_of_Measure__c.equalsIgnoreCase('Hour') && (newMap.get(contRow.Id).Units_High__c != NULL && newMap.get(contRow.Id).Units_High__c != 0) && (newMap.get(contRow.Id).Units_Low__c != NULL && newMap.get(contRow.Id).Units_Low__c != 0) && ( newMap.get(contRow.Id).Billing_Duration__c != NULL && (newMap.get(contRow.Id).Billing_Duration__c == 'Quarterly' || newMap.get(contRow.Id).Billing_Duration__c == 'Annual') ) && ( newMap.get(contRow.Id).Product_Id__c != NULL && productList.contains(newMap.get(contRow.Id).Product_Id__c) ) ) 
                {
                    cliPSHours.add(contRow.Id);
                } 
                
            }
        }
        
        
        if (contractLineIds.size() > 0 || cliPSHours.size() > 0) 
        {
            /* get all projects that are related to these contracts */
            List<Project_Contract_Line_Item__c> tempProjContracts = [SELECT Id, Project__c, Contract_Detail__c,Product__c,
                                                                     Contract_Detail__r.Effective_Start_Date__c, Contract_Detail__r.Effective_End_Date__c
                                                                     FROM Project_Contract_Line_Item__c 
                                                                     WHERE (Contract_Detail__c IN :contractLineIds 
                                                                            OR Contract_Detail__c IN :cliPSHours) ];                   
            
            if (tempProjContracts != null && tempProjContracts.size() > 0) {
                
                for (Project_Contract_Line_Item__c projContRow : tempProjContracts) {
                    if(contractLineIds.contains(projContRow.Contract_Detail__c)){
                        projectIds.add(projContRow.Project__c); 
                    }
                    
                    if(cliPSHours.contains(projContRow.Contract_Detail__c)){
                        psHourProjectIds.add(projContRow.Project__c);
                    }
                    
                }
            }  
            /* pass list of project Ids into method to set Billing Effective Date */   
            if(projectIds != NULL && projectIds.size() > 0 ){
                checkProjectContractsForEarliestBillingDate(projectIds);
            }
            if(psHourProjectIds != NULL && psHourProjectIds.size() > 0 ){
                PSA_TimecardActions.reCalculateHoursFuture(psHourProjectIds);
            }
            
        }
        
    }    
    
    public static void checkProjectContractsForEarliestBillingDate(Set<Id> projectIds) {
        /* Get all Projects with Project Contracts for all related to these Contracts. */
        /* Sort Project Contracts so that the earliest one shows up first.  Also, ignore those contracts will a null revision start date */                            
        List<pse__Proj__c> projects = [Select Id, Billing_Effective_Date__c,
                                       (Select Id, Contract_Detail__c, 
                                        Contract_Detail__r.Effective_Start_Date__c, Effective_Start_Date__c 
                                        From Project_Contract_Line_Items__r 
                                        Where Effective_Start_Date__c <> null
                                        order by Contract_Detail__r.Effective_Start_Date__c limit 1)
                                       From pse__Proj__c
                                       Where Id in :projectIds
                                       And pse__Stage__c <> 'Closed'];  
        
        if (projects != null && projects.size() > 0) {
            for (pse__Proj__c projRow : projects) {
                if (projRow.Project_Contract_Line_Items__r.size() > 0) {
                    /* if the project billing effective date is null or not equal to the earliest contract revision eff date, set the billing eff date to this one */
                    if (projRow.Billing_Effective_Date__c == null || 
                        projRow.Project_Contract_Line_Items__r[0].Contract_Detail__r.Effective_Start_Date__c <> projRow.Billing_Effective_Date__c) {
                            projRow.Billing_Effective_Date__c = projRow.Project_Contract_Line_Items__r[0].Contract_Detail__r.Effective_Start_Date__c;
                        } else {
                            System.debug('not updating proj bill effective date because it is already the earliest of all cont rev eff dates related to proj.');
                        }
                } else {
                    System.debug('blanking billing effective date because there are no contract related to proj.');
                    projRow.Billing_Effective_Date__c = null;
                } 
            }
            update projects;            
        }               
    }
    
    
    public static void checkForOverageParamChanges(Map<Id,Merge_Contract_Detail__c> oldMap, Map<Id,Merge_Contract_Detail__c> newMap)
    {
        
        Set<Id> setOvgIds                                   = new Set<Id>();
        //load all project Ids of recently created PCLIs
        List<Id> projectIds                                 = new List<Id>();
        //load all Timedates of Project linked in PCLIs
        List<pse__Time_Date__c> timeDatesOfProjects         = new List<pse__Time_Date__c>();
        //load all timedate Ids
        List<Id> timeDateIds                                = new List<Id>();
        //21.1 filter timedates and store the timedate recs
        List<pse__Time_Date__c> timeDateRecords             = new List<pse__Time_Date__c>();
        List<PS_Approved_Hours__c> lstApprovedHrsToUpdate   = new List<PS_Approved_Hours__c>();
        Map<String,Integer> nameToNumberMapping             = new Map<String,Integer>();
        
        for(Id eCLI : newMap.KeySet())
        {
            //check if Overage param is changed
            if( newMap.get(eCLI).Record_Type__c == 'Overage'
                    && oldMap.get(eCLI).Effective_End_Date__c != newMap.get(eCLI).Effective_End_Date__c)
            {
                //lstOverageParam.add(newMap.get(eCLI).Overage_Filters__c);
                setOvgIds.add(eCLI);
            }
        }
        
        
        System.debug('setOvgIds :: '+ setOvgIds);
        //21.1 fetch the equivalent dilling duration term
        for (Siebel_LOV__c  durationMapping : [select  
                                                Description__c, Display_Value__c 
                                               from 
                                                Siebel_LOV__c 
                                               where 
                                                Active__c = 'Y'])
        {
            nameToNumberMapping.put(durationMapping.Display_Value__c,Integer.valueOf(durationMapping.Description__c));
        }
        
        //Date lastMonth = Date.today().addMonths(-1).toStartofMonth();
        
        for(PS_Approved_Hours__c approvedHr : [SELECT 
                                                    Id, Name, Approved_Hours__c, Overage_Hours__c, Billing_Period_End_Date__c, Project__c, Contract_Detail__c
                                                FROM 
                                                    PS_Approved_Hours__c
                                                WHERE 
                                                    Contract_Detail__c IN :setOvgIds
                                                AND Billing_Period_End_Date__c >= THIS_MONTH
                                                ] )
        {
            PS_Approved_Hours__c ah = new PS_Approved_Hours__c();
            ah.Id = approvedHr.Id;
            approvedHr.Approved_Hours__c = 0;
            approvedHr.Overage_Hours__c = 0; 
            projectIds.add(approvedHr.Project__c);
            lstApprovedHrsToUpdate.add(approvedHr);
            System.debug('approvedHr :: '+ approvedHr);
        }
        
        try
        {
            if(!lstApprovedHrsToUpdate.isEmpty())
            {
                Database.update(lstApprovedHrsToUpdate,false);
            }
            
            if(!projectIds.isEmpty())
            {
                //Date oneYearBefore = Date.valueOf(Date.today().addYears(-1));
                //21.1 adding more columns to differntiate timedate record to consider re-iteration only for present and future month billing period 
                for(pse__Time_Date__c td : [SELECT 
                                                Id, CLI_Overage_Filters__c , CLI_Billing_Duration__c , CLI_Effective_End_Date__c , CLI_Effective_Start_Date__c , 
                                                CLI_Record_Type__c , CLI_Units_Low__c , CLI_Units_of_Measure__c, pse__Date__c 
                                           FROM 
                                            pse__Time_date__c 
                                           WHERE 
                                            psE__timecard__r.pse__billable__C = true 
                                           AND pse__timecard__r.pse__status__C = 'Approved' 
                                           //AND pse__date__c >= :oneYearBefore
                                           AND CLI_Record_Type__c  = 'Committed'
                                           AND psE__timecard__r.pse__Project__c = :projectIds 
                                           AND pse__Hours__c != 0])
                {
                    timeDateRecords.add(td);                           
                }
                
                if(!timeDateRecords.isEmpty())
                {
                    //21.1 to filter the data sent to check overage method to ensure to calculate present and future overages
                    List<Date> periodDates;
                    for(pse__Time_date__c eachTD: timeDateRecords)
                    {
                        //metod return if billing period dates and further need to validate if it falls in >= current calender month
                        periodDates = PSA_OverageController.getBillingPeriodDates(eachTD.CLI_Effective_End_Date__c,eachTD.CLI_Effective_Start_Date__c,nameToNumberMapping.get(eachTD.CLI_Billing_Duration__c),eachTD.pse__Date__c, true);
                        if(periodDates != null && periodDates.size() == 2)
                        {
                            if((periodDates[1].month()) >= Date.today().month() && (periodDates[1].year()) >= Date.today().year() )
                            {
                                timeDateIds.add(eachTD.Id);
                            } 
                        }
                    }
                    if(!timeDateIds.isEmpty())
                    {
                        PSA_OverageController.checkOverage(timeDateIds);
                    }
                }
            }
        }
        catch(Exception e)
        {
            PSA_AutoCreateProjectUtil.sendErrorMails('checkForOverageParamChanges Method Exception : Failed to update some of PS Approved Hours', e.getMessage() + ' : Line : '+ e.getLineNumber());
        }

    }//end of checkForOverageParamChanges
}