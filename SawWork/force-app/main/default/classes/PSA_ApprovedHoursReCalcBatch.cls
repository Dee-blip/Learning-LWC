public class PSA_ApprovedHoursReCalcBatch implements Database.Batchable<sObject>, Database.Stateful 
{ 

  
    public String query;
    public Map<String,Integer> nameToNumberMapping;
    public String table; 
    public String approvedRow;
    public Map<String,Decimal> conversionRateMap;
    public Integer numberOfDays;
    public Integer cutOffHours;
    public Integer financeCutOff;
    public Integer overageRecsCount;    
    public PSA_Timecard_Approval__c stopApproval;
    
    public PSA_ApprovedHoursReCalcBatch() 
    {   
        table = 'Approved Record Id,Old Value,New Value\n';
        overageRecsCount = 0;
        approvedRow = '';
        nameToNumberMapping = new Map<String,Integer>();
        for (Siebel_LOV__c  durationMapping : [select  
                                               Description__c, Display_Value__c 
                                               from 
                                               Siebel_LOV__c 
                                               where 
                                               Active__c = 'Y'])
        {
            nameToNumberMapping.put(durationMapping.Display_Value__c,Integer.valueOf(durationMapping.Description__c));
        }
        
        Date yearStartDate = date.newInstance(date.today().year(), 01, 01);
        conversionRateMap = new map<String,Decimal>();
        
        for(DatedConversionRate conversionRec: [select 
                                                ConversionRate, IsoCode 
                                                from 
                                                DatedConversionRate 
                                                where startdate >= :yearStartDate ])   
        {
            conversionRateMap.put(conversionRec.IsoCode,conversionRec.ConversionRate);
        }
        conversionRateMap.put('USD',1.0);
        
        numberOfDays = 3;
        cutOffHours = 0;
        financeCutOff= 15;
        for(PSA_Common_Setting__mdt commonMet : [Select 
                                                 id,developername, Value__c  
                                                 from 
                                                 PSA_Common_Setting__mdt  
                                                 where 
                                                 developername in ('Overage_CutOff_Days','Overage_SignOff_Cutoff_GMT','PS_Overage_Finance_Cut_Off') ])
        {
            if(commonMet.developername == 'Overage_CutOff_Days')
            {
                numberOfDays = Integer.valueOf(commonMet.Value__c);
            }
            else if(commonMet.developername == 'Overage_SignOff_Cutoff_GMT')
            {
                cutOffHours = Integer.valueOf(commonMet.Value__c);
            }
            else if(commonMet.developername == 'PS_Overage_Finance_Cut_Off')
            {
                financeCutOff = Integer.valueOf(commonMet.Value__c);
            }
        }
        
        stopApproval = PSA_Timecard_Approval__c.getOrgDefaults();
        System.debug('stopApproval >> '+ stopApproval);
        if(stopApproval != null)
        {
            stopApproval.Stop_Approval__c = true;
            update stopApproval;
        }
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC) 
    {
        if(query == null)
        {
            //20.2 : added a column Overage_Filters__c
            //21.1 : adding Late overage hours columns + iterating overages for previous month as well.
            query = 'select Late_Hours__c, Late_Overage_Hours__c, Billing_Duration__c,Approved_Hours__c, Billing_Period_End_Date__c, Billing_Period_Start_Date__c, Contract_Detail__c, Id,Original_Contract_ID__c, Overage_Hours__c, Project__c, Units_Low__c,CLI_End_Date__c, CLI_Start_Date__c,Contract_Detail__r.Product_id__c,Contract_Detail__r.Units_Low__c, Contract_Detail__r.Unit_Of_Measure__c,Overage_Filters__c from PS_Approved_Hours__c where (Billing_Period_End_Date__c = LAST_MONTH or Billing_Period_End_Date__c = THIS_MONTH or Billing_Period_End_Date__c = NEXT_MONTH) and Locked__c = false and Original_Contract_ID__c != null and Contract_Detail__c != null';
            if(Test.isRunningTest())
            {
                query += ' limit 1';
            }
        }
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<sObject> scope) 
    {
        
        List<PS_Approved_Hours__c> approvedHours = (List<PS_Approved_Hours__c>)scope;
        List<PS_Approved_Hours__c> approvedHourRecsToUpsert = new List<PS_Approved_Hours__c>();
        PS_Approved_Hours__c approvedHourRec;
        Decimal unitsLowForPeriod;
        Map<Id, String> projectIdToKey = new Map<Id, String>();
        //changes : load all the existing projects and respected committed CLI Unit Of Measures.
        Map<Id, String> projIdIdTOUnitofMeasures = new Map<Id, String>();
        //20.2 to load all the existing projects and respected committed CLI Unit Low.
        Map<Id, Decimal> projIdIdTOUnitsLow = new Map<Id, Decimal>();
        String key;
        List<Date> timeDatesFilter = new List<Date>();
        List<Id> approvedRecIds = new List<Id>();
        //20.4.1 converting it to wrapper class
        //Map<String,Merge_Contract_detail__c> projIdTrimmedToCMTCLI = new Map<String,Merge_Contract_detail__c>();
        Map<String,PSA_CommintCLIWrapper> projIdTrimmedToCMTCLI = new Map<String,PSA_CommintCLIWrapper>();
        
        for(PS_Approved_Hours__c approvedHour : approvedHours)
        {
            //changes: adding Unit Of measure and removing Billing Duration
            //key = '' + String.valueOf(approvedHour.Original_Contract_ID__c).substring(0, 15) + String.valueOf(approvedHour.CLI_End_Date__c) + 
                //String.valueOf(approvedHour.Contract_Detail__r.Unit_Of_Measure__c) + approvedHour.Contract_Detail__r.Product_Id__c ;
            //20.2 using Overage Filters column
            key = approvedHour.Overage_Filters__c; 
            System.debug(' approvedHour :: '+ approvedHour);
            System.debug('key >> Overage CLI Key'+ key);
            if(!projectIdToKey.containsKey(approvedHour.Project__c))
            {
                projectIdToKey.put(approvedHour.Project__c,key);    
            }
            timeDatesFilter.add(approvedHour.Billing_Period_Start_Date__c);
            timeDatesFilter.add(approvedHour.Billing_Period_End_Date__c);
        }
        
        timeDatesFilter.sort();
        
        Date minDate = timeDatesFilter.get(0);
        Date maxDate = timeDatesFilter.get(timeDatesFilter.size() - 1);
        
        for(Project_Contract_Line_Item__c pcli: [select 
                                                     Contract_Detail__r.Billing_Duration__c,Original_Contract_Id__c,Contract_Detail__c,Overage_Filters__c, Units_Low__c, 
                                                     Effective_End_Date__c, Effective_Start_Date__c, Product_Id__c, Project__c, Unit_Of_Measure__c 
                                                 from 
                                                    Project_Contract_Line_Item__c 
                                                 where 
                                                    Project__c in: projectIdToKey.keySet()])
        {
            //changes: adding the Unit Of Measure as Key - removed Billing duration check again.
            //key = '' + String.valueOf(pcli.Original_Contract_ID__c).substring(0, 15) + String.valueOf(pcli.Effective_End_Date__c) + 
                //String.valueOf(pcli.Unit_Of_Measure__c) + pcli.Product_Id__c ;
            //20.2
            key = pcli.Overage_Filters__c;
            
            System.debug('PCLI ::'+ pcli);
            System.debug('key >> PCLI ::'+ key);
            //load projIdIdTOUnitofMeasures that will have committed CLI linked to Project and its Unit Of Measure
            if(pcli.Unit_Of_Measure__c != NULL)
            {
                projIdIdTOUnitofMeasures.put(pcli.Project__c,pcli.Unit_Of_Measure__c);  
                //20.2
                projIdIdTOUnitsLow.put(pcli.Project__c,pcli.Units_Low__c);
            }
            System.debug('projectIdToKey.containsKey(pcli.Project__c :: '+ projectIdToKey.containsKey(pcli.Project__c));
            if(!projectIdToKey.containsKey(pcli.Project__c) || projectIdToKey.get(pcli.Project__c) != key)
            {
                projectIdToKey.remove(pcli.Project__c);
            }            
        }
        
        system.debug('projectIdToKey: ' + projectIdToKey);
        Map<String, Decimal> overageKeyToTotalHours = new Map<String, Decimal>();
        List<Date> periodDates;
        
        if(!projectIdToKey.isEmpty())
        {
            //load overageKeyToTotalHours that will have the PS Approved Hours Record to the number of hours logged by resporces at that billing period duration
            //20.2 added one more column to fetch cmt CLI Id
            for(pse__Time_Date__c timedate: [select 
                                                 id, pse__Hours__c,pse__Date__c, Contract_Salesforce_Id__c,
                                                 CLI_Effective_End_Date__c,CLI_Effective_Start_Date__c,CLI_Units_Low__c, CLI_Overage_Filters__c,
                                                 CLI_Billing_Duration__c ,Product_Id__c, pse__Timecard__r.pse__Project__c,CLI_Units_of_Measure__c,
                                                 pse__Timecard__r.pse__Assignment__r.Project_Contract_Line_Item__r.Contract_Detail__c
                                             from 
                                                pse__Time_Date__c 
                                             where 
                                                pse__Timecard__r.pse__Billable__c  = true 
                                             and pse__Hours__c != 0
                                             and CLI_Record_Type__c  = 'Committed' 
                                             and pse__Timecard__r.pse__Status__c = 'Approved'
                                             and pse__Timecard__r.pse__Project__c in :projectIdToKey.keySet() 
                                             and pse__Date__c >= :minDate
                                             and pse__Date__c <= :maxDate 
                                             order by pse__Date__c 
                                            ])
            {
                periodDates = PSA_OverageController.getBillingPeriodDates(timedate.CLI_Effective_End_Date__c,timedate.CLI_Effective_Start_Date__c,nameToNumberMapping.get(timedate.CLI_Billing_Duration__c),timedate.pse__Date__c, true);
                if(periodDates != null && periodDates.size() == 2)
                {
                    key = String.valueOf(periodDates[0]) + ',' + 
                        + String.valueOf(periodDates[1]) + ','+ String.valueOf(timedate.pse__Timecard__r.pse__Project__c).substring(0, 15);
                    
                    if(!overageKeyToTotalHours.containsKey(key))
                    {
                        overageKeyToTotalHours.put(key,0);
                    }
                    overageKeyToTotalHours.put(key,(overageKeyToTotalHours.get(key) + timedate.pse__Hours__c));
                    
                }
                
                //20.2 adding the committed CLI details in to a map to refere further
                if(!projIdTrimmedToCMTCLI.containsKey(String.valueOf(timedate.pse__Timecard__r.pse__Project__c).substring(0, 15)))
                {
                    //20.4.1 converting it to wrapper class
                    PSA_CommintCLIWrapper cmtCLI  = new PSA_CommintCLIWrapper(timedate.pse__Timecard__r.pse__Assignment__r.Project_Contract_Line_Item__r.Contract_Detail__c, timedate.CLI_Effective_End_Date__c, timedate.CLI_Effective_Start_Date__c,timedate.CLI_Units_of_Measure__c, timedate.CLI_Units_Low__c, timedate.CLI_Billing_Duration__c);
                    /*Merge_Contract_detail__c cmtCLI = new Merge_Contract_detail__c();
                    cmtCLI.Id = timedate.pse__Timecard__r.pse__Assignment__r.Project_Contract_Line_Item__r.Contract_Detail__c;
                    cmtCLI.Effective_End_Date__c = timedate.CLI_Effective_End_Date__c;
                    cmtCLI.Effective_Start_Date__c = timedate.CLI_Effective_Start_Date__c;
                    cmtCLI.Billing_Duration__c = timedate.CLI_Billing_Duration__c;
                    cmtCLI.Unit_Of_Measure__c = timedate.CLI_Units_of_Measure__c;
                    cmtCLI.Units_Low__c = timedate.CLI_Units_Low__c;*/
                    projIdTrimmedToCMTCLI.put(String.valueOf(timedate.pse__Timecard__r.pse__Project__c).substring(0, 15),cmtCLI);
                }
                
            }
            /*for(String ovgKeyWithHrs : overageKeyToTotalHours.keySet()){
                System.debug('ovgKeyWithHrs :: '+ ovgKeyWithHrs + ' :: '+ overageKeyToTotalHours.get(ovgKeyWithHrs));
            }*/
            system.debug('overageKeyToTotalHours' + overageKeyToTotalHours);
            
            //update the PS Approved Hrs if there are any missmatches
            for(PS_Approved_Hours__c approvedHour : approvedHours)
            {
                key = String.valueOf(approvedHour.Billing_Period_Start_Date__c) + ',' + 
                    + String.valueOf(approvedHour.Billing_Period_End_Date__c) + ',' + String.valueOf(approvedHour.Project__c).substring(0, 15);
                if(projectIdToKey.containsKey(approvedHour.Project__c) && overageKeyToTotalHours.containsKey(key))
                {
                    //changes: added condition to consider if OVerage CLI UOM is Business Days || if change in PS Approved hours 
                    if((overageKeyToTotalHours.get(key) != approvedHour.Approved_Hours__c) 
                       || (approvedHour.Contract_Detail__r.Unit_Of_Measure__c == 'Business Days'))
                    {
                        approvedRow += approvedHour.Id  + ','+ approvedHour.Approved_Hours__c + ','+ overageKeyToTotalHours.get(key)+'\n';                  
                        approvedHourRec = new PS_Approved_Hours__c();
                        approvedHourRec.Id = approvedHour.Id;
                        
                        approvedHourRec.Units_Low__c = approvedHour.Units_Low__c;
                        if(approvedHour.Contract_Detail__r.Units_Low__c != approvedHourRec.Units_Low__c)
                        {
                            approvedHourRec.Units_Low__c = approvedHour.Contract_Detail__r.Units_Low__c;
                        }
                        
                        //changes: adding Unit of Measure to the getUnitsLow Method
                        //20.2 Adding chanages to consider CMT CLIs Billing Duration and Units Low
                        PSA_CommintCLIWrapper cmtCLI = projIdTrimmedToCMTCLI.get(String.valueOf(approvedHour.Project__c).substring(0, 15));
                        //unitsLowForPeriod = PSA_OverageController.getUnitsLow(approvedHour.Billing_Duration__c, approvedHour.Billing_Period_Start_Date__c, approvedHour.Billing_Period_End_Date__c, approvedHourRec.Units_Low__c, approvedHour.Contract_Detail__r.Unit_Of_Measure__c );
                        //20.4.1 chnaging the reference of cmtCLI
                        unitsLowForPeriod = PSA_OverageController.getUnitsLow(cmtCLI.BillingDuration, approvedHour.Billing_Period_Start_Date__c, approvedHour.Billing_Period_End_Date__c, cmtCLI.UnitsLow, approvedHour.Contract_Detail__r.Unit_Of_Measure__c );
                        
                        approvedHourRec.Approved_Hours__c = overageKeyToTotalHours.get(key);
                        //approvedHourRec.Overage_Hours__c = overageKeyToTotalHours.get(key) > unitsLowForPeriod ? overageKeyToTotalHours.get(key) - unitsLowForPeriod: 0;
                        //21.1 check for late hours entry and store it in new field 
                        if((approvedHour.Billing_Period_End_Date__c.addMonths(1)).toStartOfMonth().month() == Date.today().month() &&  (approvedHour.Billing_Period_End_Date__c.addMonths(1)).toStartOfMonth().year() == Date.today().year() )
                        {
                            System.debug('prining Billing_Period_End_Date__c just before setting it to Late HoursapprovedHourRec :: '+ approvedHourRec);
                            approvedHourRec.Late_Hours__c = true;
                            approvedHourRec.Late_Overage_Hours__c  = overageKeyToTotalHours.get(key) > unitsLowForPeriod ? (approvedHour.Overage_Hours__c != 0 && approvedHour.Overage_Hours__c != null ) ? overageKeyToTotalHours.get(key) - (approvedHour.Overage_Hours__c + unitsLowForPeriod) : overageKeyToTotalHours.get(key) - unitsLowForPeriod : 0 ;
                            //uncheck this locked field to ensure the late overages are tracked if the approved hour record is locked post billing cycle for the previous month 
                            approvedHourRec.Locked__c = false;
                        }
                        else
                        { 
                            approvedHourRec.Late_Hours__c = false;
                            approvedHourRec.Overage_Hours__c = overageKeyToTotalHours.get(key) > unitsLowForPeriod ? overageKeyToTotalHours.get(key) - unitsLowForPeriod: 0;
                        }
                        System.debug('approvedHour record :: '+ approvedHour);
                        System.debug('approvedHourRec with difference in Business Days/ Approved he Diff :: '+ approvedHourRec);
                        approvedHourRecsToUpsert.add(approvedHourRec);
                        
                    }
                    
                    approvedRecIds.add(approvedHour.Id);
                }
                
                //changes: adding a condition when the batch Job runs to set Approved Hours as "0" is there is change in Unit Of Measure for committed CLI and Overage CLI of the project
                //20.2 to set Approved Hours as "0" is there is change in Units Low for committed CLI and Overage CLI of the project
                else if(approvedHour.Contract_Detail__r.Units_Low__c != NULL && approvedHour.Contract_Detail__r.Unit_Of_Measure__c != NULL && 
                        projIdIdTOUnitofMeasures.containsKey(approvedHour.Project__c) && projIdIdTOUnitsLow.containsKey(approvedHour.Project__c) && 
                        (approvedHour.Contract_Detail__r.Unit_Of_Measure__c != projIdIdTOUnitofMeasures.get(approvedHour.Project__c) || approvedHour.Contract_Detail__r.Units_Low__c != projIdIdTOUnitsLow.get(approvedHour.Project__c) ) )
                {
                    System.debug('approvedHour record with difference in UOM :: '+ approvedHour);
                    approvedHourRec = new PS_Approved_Hours__c();
                    approvedHourRec.Id = approvedHour.Id;
                    approvedHourRec.Approved_Hours__c = 0;   
                    approvedHourRec.Overage_Hours__c = 0;
                    //21.1 set late hours also to "0" if its overage param are changed
                    approvedHourRec.Late_Overage_Hours__c = 0;
                    approvedRow += approvedHour.Id  + ','+ approvedHour.Approved_Hours__c + ','+ overageKeyToTotalHours.get(key)+'\n';                  
                    System.debug('approvedHourRec record with difference in UOM :: '+ approvedHourRec);
                    approvedHourRecsToUpsert.add(approvedHourRec);
                }
                
            }
            system.debug('approvedHourRecsToUpsert'+ approvedHourRecsToUpsert);
            if(!approvedHourRecsToUpsert.isempty())
            {
                PSA_OverageController.validAutomatedUpsert = true;
                Database.SaveResult[] saveResults = Database.update(approvedHourRecsToUpsert,false);
                PSA_AutoCreateProjectUtil.PopulateErrorTableForUpdate(saveResults, approvedHourRecsToUpsert);
                
            }   
            
            List<PS_Overage_Hours__c> overages = new List<PS_Overage_Hours__c>();
            PS_Overage_Hours__c newRec;
            
            Double conversionRateDouble;
            Boolean updateRecord = false;
            Decimal calculatedValue;
            //21.1 - adding Late Hours column on query 
            for (PS_Overage_Hours__c overageRec : [select 
                                                   id , contract_currency__c,overage_hours__c, to_be_billed_Hours__c,
                                                   overage_rate__c,Billing_Period_End_Date__c,Amount_to_be_Billed_USD__c,
                                                   Overage_Billing_USD__c ,Amount_to_be_Billed_Contract_Cur_Num__c,
                                                   Overage_Lock_Date__c ,Reminder_Mail_Date__c , Late_Hours__c 
                                                   from 
                                                   PS_Overage_Hours__c 
                                                   where 
                                                   overage_stage__c = 'Saved' 
                                                   and Recordtype.name != 'Locked' 
                                                   and PS_Approved_Hours__c in :approvedRecIds])
            {
                updateRecord = false;   
                conversionRateDouble = conversionRateMap.get(overageRec.Contract_Currency__c ) == null ? 1.0 : conversionRateMap.get(overageRec.Contract_Currency__c );
                
                newRec = new PS_Overage_Hours__c ();
                newRec.Id = overageRec.Id;
                //set Overage billing in USD|| Ammount to be billed with Contract Currency || Amount to be billind in USD when they != calculatedValue
                if(overageRec.Overage_Rate__c != null && overageRec.Overage_Rate__c != 0)
                {
                    calculatedValue = overageRec.Overage_Hours__c * overageRec.Overage_Rate__c / conversionRateDouble;
                    //calculatedValue = calculatedValue.setScale(2, RoundingMode.HALF_UP);
                    if(overageRec.Overage_Billing_USD__c != calculatedValue)
                    {
                        system.debug('overageRec.Overage_Billing_USD__c ' + overageRec.Overage_Billing_USD__c + 'calculatedValue:' + calculatedValue);
                        newRec.Overage_Billing_USD__c = calculatedValue;        
                        updateRecord = true;
                    }
                    calculatedValue = overageRec.To_be_Billed_Hours__c * overageRec.Overage_Rate__c;
                    //calculatedValue = calculatedValue.setScale(2, RoundingMode.HALF_UP);
                    if(overageRec.Amount_to_be_Billed_Contract_Cur_Num__c != calculatedValue)
                    {
                        system.debug('overageRec.Overage_Billing_USD__c ' + overageRec.Overage_Billing_USD__c + 'calculatedValue:' + calculatedValue);                            
                        newRec.Amount_to_be_Billed_Contract_Cur_Num__c = calculatedValue;    
                        updateRecord = true;
                    }
                    calculatedValue = overageRec.To_be_Billed_Hours__c * overageRec.Overage_Rate__c / conversionRateDouble;
                    //calculatedValue = calculatedValue.setScale(2, RoundingMode.HALF_UP);
                    if(overageRec.Amount_to_be_Billed_USD__c != calculatedValue)
                    {
                        system.debug('newRec.Amount_to_be_Billed_USD__c ' + newRec.Amount_to_be_Billed_USD__c + 'calculatedValue:' + calculatedValue);                            
                        newRec.Amount_to_be_Billed_USD__c = calculatedValue;        
                        updateRecord = true;
                    }
                }
                
                //set reminder Mail Date || Overage Lock Date when overage Lock Date is NULL
                if(overageRec.Overage_Lock_Date__c == null)
                {
                    //Date lockedDate = overageRec.Billing_Period_End_Date__c.addMonths(1).toStartOfMonth();
                    //21.1 - set overage Lock date 
                    Date lockedDate = overageRec.Late_Hours__c ? overageRec.Billing_Period_End_Date__c.addMonths(2).toStartOfMonth() : overageRec.Billing_Period_End_Date__c.addMonths(1).toStartOfMonth();
                    newRec.Reminder_Mail_Date__c = PSA_OverageController.convertToESTCutOff(lockedDate, cutOffHours);
                    
                    lockedDate = PSA_OverageController.addBusinessDays(lockedDate, numberOfDays,new Set<Date>());                        
                    newRec.Overage_Lock_Date__c = PSA_OverageController.convertToESTCutOff(lockedDate, financeCutOff);
                    updateRecord = true;
                }
                
                if(updateRecord)
                {
                    overages.add(newRec);    
                    
                }
                
            }
            if(!overages.isempty())
            {
                overageRecsCount +=  overages.size();
                PSA_OverageController.validAutomatedUpsert = true;
                Database.SaveResult[] saveResults = Database.update(overages,false);
                PSA_AutoCreateProjectUtil.PopulateErrorTableForUpdate(saveResults, overages);
                
            }   
            
        }
    }
    
    public void finish(Database.BatchableContext BC) 
    {
        if(stopApproval != null)
        {
            stopApproval.Stop_Approval__c = false;
            update stopApproval;
        }
        
        
        if(approvedRow != '')
        {
            PSA_Settings__c EnggEmail = PSA_Settings__c.getInstance('Engineering Team Email');
            String emailAddress = EnggEmail != null ?EnggEmail.Value__c : 'services-engg@akamai.com';
            
            Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
            blob csvBlob = Blob.valueOf(table + approvedRow);
            string csvname= 'ApprovedHoursUpdated.csv';
            csvAttc.setFileName(csvname);
            csvAttc.setBody(csvBlob);
            Messaging.SingleEmailMessage email =new Messaging.SingleEmailMessage();
            String subject ='ApprovedHoursUpdated CSV';
            email.setSubject(subject);
            email.setToAddresses( new List<String>{emailAddress});
            email.setPlainTextBody('PFA the ApprovedHoursUpdated CSV.' + overageRecsCount + ' Overages updated.');
            email.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttc});
            Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});  
            
        }
        else
        {
            PSA_AutoCreateProjectUtil.sendErrorMails('Approved Records Batch Processed! ','No Approved Hours Updated. ' + overageRecsCount + ' Overages updated.');
        }
        
    }
    
}