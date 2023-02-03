public class PSA_OverageController
{

    public List<String> errorsKeys{get;set;}
    List <PS_Overage_Hours__c> overagesToUpdate;
    //changes: stroing projectIds, filteredOveragerecords.
    List <PS_Overage_Hours__c> filteredOveragesToUpdate;
    List<String> associatedProjInOvgs;
    List<PS_Overage_Hours__c> bulkOverages;
    Map<Id,String> idToName;
    public Integer successCountSubmitted{get;set;}
    public Integer successCountSignedOff{get;set;}

    public Map<String,List<String>> updateErrors{get;set;}
    
    public static Boolean validAutomatedUpsert = false;
    
    public String prefix 
    {
        get
        {
            if(prefix == null)
            {
                prefix = Schema.getGlobalDescribe().get('PS_overage_Hours__c').getDescribe().getKeyPrefix();
            }
            return prefix;
        }
        set;
    }
    
    public PSA_OverageController() 
    {
        
    }
    
    public PSA_OverageController(ApexPages.StandardController controller)
    {
        
    }
    
    //used in Bulk SignOff
    public PSA_OverageController(ApexPages.StandardSetController setController)
    {
        
        overagesToUpdate = new List <PS_Overage_Hours__c>();
        //chnages: store projects Id and Overage records
        associatedProjInOvgs = new List<String>();
        bulkOverages = new List<PS_Overage_Hours__c>();
        idToName = new Map<Id,String>();
        
        successCountSubmitted = 0;
        successCountSignedOff = 0;
        errorsKeys = new List<String>();
        for ( PS_Overage_Hours__c overageRec : (PS_Overage_Hours__c[])setController.getSelected() )
        {
             bulkOverages.add(overageRec);
             //changes: adding PS Overage Project Ids
             associatedProjInOvgs.add(overageRec.Project_ID__c);
             idToName.put(overageRec.Id,overageRec.Name);
        }
    }
    
    public void validateOveragesBeforeSignOff(){
        
    }
    
    public void bulkSignOffOverage()
    {
        String projectIDinString = '';
        filteredOveragesToUpdate = new List <PS_Overage_Hours__c>();
        if(associatedProjInOvgs.isEmpty()){
            return; 
        }
        PS_Overage_Hours__c newRec;
        System.debug('In BulkSignOff');
        //projectIDinString  = String.join(associatedProjInOvgs, ',');
        Map<String, String> prIdToCommittedKey = getCLILinkedToProject(JSON.serialize(associatedProjInOvgs));
        System.debug('In BulkSignOff prIdToCommittedKey :: '+ prIdToCommittedKey);
        String keyOverageCLI;
        List<PS_Overage_Hours__c> nonMatchingOverages = new List<PS_Overage_Hours__c>();
        Map<Id,Boolean> overageIdToGSSApproverMap = new Map<Id,Boolean>();
        Map<Id,Boolean> overageIdToFinanceApproverMap = new Map<Id,Boolean>();
        if(!bulkOverages.isEmpty())
        {
            //changes: to have OverageRecordTypeId Check
            Id overageRecordTypeId = Schema.SObjectType.PS_Overage_Hours__c.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
            //Map<String,PS_Overage_Hours__c> ovgKeyToOverageCLI = new Map<String,PS_Overage_Hours__c>();
            for(PS_Overage_Hours__c eachOvg : bulkOverages)
            {
                System.debug('eachOvg :: ' + eachOvg);
                //eachOvg.Trigger_Sign_Off__c = true;
                //changes: adding Contract detail check
                if(eachOvg.Original_Detail_ID__c != NULL)
                {
                    //20.2
                    //keyOverageCLI = '' + String.valueOf(eachOvg.Original_Contract_Id__c).substring(0, 15) + String.valueOf(eachOvg.CLI_End_Date__c) + String.valueOf(eachOvg.CLI_Unit_of_Measure__c) + eachOvg.Marketing_Product_Id__c;
                    keyOverageCLI = eachOvg.Overage_Filters__c;
                    System.debug('keyOverageCLI >> '+ keyOverageCLI);
                    if((prIdToCommittedKey.containsKey(String.valueOf(eachOvg.Project_ID__c).substring(0, 15)) && prIdToCommittedKey.get(String.valueOf(eachOvg.Project_ID__c).substring(0, 15)) == keyOverageCLI && overageRecordTypeId == eachOvg.RecordTypeId)
                       || overageRecordTypeId != eachOvg.RecordTypeId)
                    {
                        newRec = new PS_Overage_Hours__c();
                        newRec.Id = eachOvg.Id;
                        newRec.Trigger_Sign_Off__c = true;
                        
                        newRec.Overage_Stage__c = eachOvg.Overage_Stage__c;
                        newRec.RecordTypeId = eachOvg.RecordTypeId;
                        newRec.To_be_Billed_Hours__c = eachOvg.To_be_Billed_Hours__c;
                        newRec.Overage_Hours__c = eachOvg.Overage_Hours__c;

                        overageIdToGSSApproverMap.put(newRec.Id,eachOvg.GSS_Approver__c);
                        overageIdToFinanceApproverMap.put(newRec.Id,eachOvg.Finance_Approver__c);
                                                                                            
                        filteredOveragesToUpdate.add(newRec);
                        System.debug('newRec >> '+ newRec);
                    }
                    else
                    {
                        System.debug('nonMatching Overage CLI in Esle >> '+ eachOvg);
                        nonMatchingOverages.add(eachOvg);
                    }
                }
                else if(eachOvg.Original_Detail_ID__c == NULL)
                {
                    nonMatchingOverages.add(eachOvg);
                }
            }
            System.debug('filteredOveragesToUpdate >> '+ filteredOveragesToUpdate);
            //Database.SaveResult[] saveResults = Database.update(overagesToUpdate,false);
            Database.SaveResult[] saveResults = Database.update(filteredOveragesToUpdate,false);
            Database.SaveResult sr;
            String errorResult;
            updateErrors = new Map<String,List<String>>();
            List<Id> updatedOverageIds = new List<Id>();
            List<PS_Overage_Hours__c> updatedOveragesList = new List<PS_Overage_Hours__c>();
            for(Integer i = 0; saveResults != null && i < saveResults.size(); i++)
            {
                sr = saveResults.get(i);
                if (!sr.isSuccess()) 
                {
                    errorResult = '';
                    
                    for(Database.Error err : sr.getErrors()) 
                    {
                        System.debug('*** inside failure record >> :: '+ sr + '  :: '+sr.getId());
                        System.debug('*** Error inside:'+ err);
                        errorResult += err.getStatusCode() + ': ' + err.getMessage() + '<br />';
                    }
                    updateErrors.put(filteredOveragesToUpdate.get(i).id,new List<String>());
                    updateErrors.get(filteredOveragesToUpdate.get(i).id).add(errorResult);
                    updateErrors.get(filteredOveragesToUpdate.get(i).id).add(idToName.get(filteredOveragesToUpdate.get(i).Id));
                    System.debug('updateErrors >> '+ updateErrors);
                }
                else if(filteredOveragesToUpdate.get(i).Overage_Stage__c != 'Signed - Off')
                {
                    System.debug('*** inside success record >> :: '+ sr + '  :: '+sr.getId());
                    //updatedOverageIds.add(sr.getId());
                    updatedOveragesList.add(filteredOveragesToUpdate.get(i));
                    //successCount++;
                }
                
            }

            System.debug('*** updatedOveragesList:');
            for(PS_Overage_Hours__c ovg : updatedOveragesList){
                System.debug('\t\t\t*** ovg.Id:'+ovg.Id);
                System.debug('\t\t\t*** ovg.Overage_Stage__c:'+ovg.Overage_Stage__c);
                System.debug('\t\t\t*** ovg.RecordTypeId:'+ovg.RecordTypeId);
                System.debug('\t\t\t*** ovg.To_be_Billed_Hours__c:'+ovg.To_be_Billed_Hours__c);
                System.debug('\t\t\t*** ovg.Overage_Hours__c:'+ovg.Overage_Hours__c);
                System.debug('\t\t\t*** ovg.GSS_Approver__c:'+overageIdToGSSApproverMap.get(ovg.Id));
                System.debug('\t\t\t*** ovg.Finance_Approver__c:'+overageIdToFinanceApproverMap.get(ovg.Id));
                System.debug('');
            }
            
            if(!updateErrors.isEmpty()){
                System.enqueueJob(new PSA_OveragesSuccessRecordUpdate (updatedOveragesList));
            }
            
            
            
            //changes: adding custom error messages for Bulk Sign-Off
            for(PS_Overage_Hours__c eachOverageRec : nonMatchingOverages)
            {
                System.debug('inside eachOverageRec iterating  nonMatchingOverages:: '+ eachOverageRec);
                errorResult = '';
                errorResult += 'The Overage Contract Detail is not present in the system OR does not Match with the Project any more!' + '<br />';
                updateErrors.put(eachOverageRec.Id, new List<String>());
                updateErrors.get(eachOverageRec.Id).add(errorResult);
                updateErrors.get(eachOverageRec.Id).add(idToName.get(eachOverageRec.Id));
                System.debug('updateErrors at nonMatchingOverages :: '+ updateErrors);
            }

            //String userTitle = [select Title from user where id=:userinfo.getuserid()].Title;
            Id automatedId = Schema.SObjectType.PS_Overage_Hours__c.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
            Id manualId = Schema.SObjectType.PS_Overage_Hours__c.getRecordTypeInfosByName().get('Manual').getRecordTypeId();
            //String profileIdValues = [select value__c from PSA_Common_Setting__mdt where DeveloperName = 'Overage_Finance_Profiles'].value__c;    
            
            System.debug('*** automatedId:'+automatedId);
            System.debug('*** manualId:'+manualId);            
            if(!updatedOveragesList.isEmpty()){
                for(PS_Overage_Hours__c overageRec : updatedOveragesList)
                {
                    if(
                        overageRec.Overage_Stage__c == 'Saved' &&                         
                        overageIdToGSSApproverMap.get(overageRec.Id) && 
                        !overageIdToFinanceApproverMap.get(overageRec.Id) &&
                        (
                            overageRec.RecordTypeId == manualId ||
                            (overageRec.RecordTypeId == automatedId && overageRec.To_be_Billed_Hours__c > overageRec.Overage_Hours__c)
                        )
                    ){
                        successCountSubmitted++;
                    }
                    else if(
                        (overageIdToFinanceApproverMap.get(overageRec.Id) && overageRec.Overage_Stage__c == 'Submitted') || 
                        ((overageIdToFinanceApproverMap.get(overageRec.Id) || overageIdToGSSApproverMap.get(overageRec.Id)) && overageRec.Overage_Stage__c == 'Saved')
                    )
                    {
                        successCountSignedOff++;                         
                    }
                    System.debug('successCountSignedOff :: ' + successCountSignedOff +   ' :::: successCountSubmitted ::: ' + successCountSubmitted );
                }
            }


            errorsKeys = new List<String>();
            errorsKeys.addAll(updateErrors.keySet());
            System.debug('errorsKeys :: ' + errorsKeys  );
        }
    }
    
    public static Boolean checkRecursion = false;
    public static Boolean checkRecursionPost = false;
    
    @AuraEnabled
    public static String getManualFieldsList()
    {
        Map<String,String> parameters = new Map<String,String>();
        PSA_Common_Setting__mdt fieldsRec = [select 
                                                id, Value__c  
                                             from 
                                                PSA_Common_Setting__mdt  
                                             where 
                                                DeveloperName = 'Manual_Overage_Fields' limit 1] ;
        parameters.put('fields',fieldsRec.Value__c);
        parameters.put('prefix',Schema.getGlobalDescribe().get('PS_overage_Hours__c').getDescribe().getKeyPrefix());
        parameters.put('recordTypeId',Schema.SObjectType.PS_Overage_Hours__c.getRecordTypeInfosByName().get('Manual').getRecordTypeId());
        return JSON.serialize(parameters);
        
    }
    
    @AuraEnabled
    public static String getProfilesList()
    {
        Map<String,String> parameters = new Map<String,String>();
        for (PSA_Common_Setting__mdt commonMet : [select 
                                                    id,type__c, Value__c  
                                                  from 
                                                    PSA_Common_Setting__mdt  
                                                  where 
                                                    type__c in ('Overage_Automated_Profiles','Overage_Finance_Profiles')])
        {
            if(!parameters.containsKey(commonMet.type__c))
            {
                parameters.put(commonMet.type__c,commonMet.Value__c);    
            }
            else
            {
                String values = parameters.get(commonMet.type__c) + ',' + commonMet.Value__c;
                parameters.put(commonMet.type__c,values);    
            }
        }
        return JSON.serialize(parameters);

    }
    
    public static void sendReminderEmailAfterChecks(Map<Id,PS_Overage_Schedule__c > oldMap,List<PS_Overage_Schedule__c > newList)
    {
        Set<Date> holidays = new Set<Date>();
        Boolean sendFinanceReminder = false;
        //List<Id> overageIdsToRecalculate = new List<Id>();
        Integer numberOfDays = 3;
        Integer cutOffHours = 12;
        Integer financeCutOff = 17;
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
        
        Map <Id,Date> idToDatesToCheck = new Map <Id,Date>();
        for(PS_Overage_Schedule__c psSchedule : newList)
        {
            if(psSchedule.Number_of_Mails_Sent__c   != oldMap.get(psSchedule.Id).Number_of_Mails_Sent__c  
                && psSchedule.Reminder_Mail_Date__c   == oldMap.get(psSchedule.Id).Reminder_Mail_Date__c 
                && psSchedule.Number_of_Mails_Sent__c  > oldMap.get(psSchedule.Id).Number_of_Mails_Sent__c)
            {
                idToDatesToCheck.put(psSchedule.Id,psSchedule.Reminder_Mail_Date__c.date());
            }
            else if(psSchedule.Send_File_to_CMG__c)
            {                
                idToDatesToCheck.put(psSchedule.Id,psSchedule.Lock_Date__c.dateGMT().addMonths(1).toStartOfMonth());
            }
            else if(psSchedule.Finance_Reminder__c )
            {
                sendFinanceReminder = true;
                psSchedule.Finance_Reminder__c = false;
            }
        }
        if(!idToDatesToCheck.isEmpty())
        {
            List<Date> datesToCheck = idToDatesToCheck.values();
            datesToCheck.sort();
            Date minDateToCheck = datesToCheck.get(0);
            Date maxDateToCheck = datesToCheck.get(datesToCheck.size() - 1).addMonths(1);
            for(Finance_Calendar__c financeHoliday :[Select Holiday_Date__c from Finance_Calendar__c where Active__c = true and Holiday_Date__c >= :minDateToCheck and Holiday_Date__c <= :maxDateToCheck order by Holiday_Date__c])
            {
                holidays.add(financeHoliday.Holiday_Date__c);
            }
        }
        for(PS_Overage_Schedule__c psSchedule : newList)            
        {
            //normal reminder emails + change the reminder mail date accordingly ignoring Holiday + weekends
            if(idToDatesToCheck.containsKey(psSchedule.Id) && !psSchedule.Send_File_to_CMG__c)
            {
                String day = psSchedule.Reminder_Mail_Date__c.format('EEEE','GMT');
                Date reminderMailDate = psSchedule.Reminder_Mail_Date__c.dateGMT();
                // Ignore to send Reminder Emails on non Workking Days/ on a Listed Holiday from Finance Calender
                if(day == 'Saturday' || day == 'Sunday' || holidays.contains(reminderMailDate))
                {
                    psSchedule.Number_of_Mails_Sent__c--;
                }
                else
                {
                    //Send reminder mails to GSS: Notification_to_fill_out_overage_entries  
                    if(!system.isFuture())
                    {
                        sendOutOfOfficeMail();    
                    }
                    
                }
                // reset reminderMailDate to next Business day
                if(psSchedule.Number_of_Mails_Sent__c < numberOfDays)
                {
                    reminderMailDate = addBusinessDays(reminderMailDate.addDays(1), 1,holidays);                        
                    psSchedule.Reminder_Mail_Date__c = convertToESTCutOff(reminderMailDate, cutOffHours);
                }
            }
            //sending file to CMG and resetting the Overage Schedule for the next month Overage Calculation
            else if(idToDatesToCheck.containsKey(psSchedule.Id) && psSchedule.Send_File_to_CMG__c )
            {
                psSchedule.Send_File_to_CMG__c = false;
                Date lockedDateGMT = psSchedule.Lock_Date__c.dateGMT().addMonths(1).toStartOfMonth();
                Date firstReminderDate = addBusinessDays(lockedDateGMT, 1,holidays);                        
                psSchedule.Reminder_Mail_Date__c = convertToESTCutOff(firstReminderDate, cutOffHours);
                firstReminderDate = addBusinessDays(lockedDateGMT, 3,holidays);                        
                psSchedule.Lock_Date__c = convertToESTCutOff(firstReminderDate, financeCutOff);
                psSchedule.Number_of_Mails_Sent__c = 0;
                sendFileToCMG(true);
            }
            
        }
        if(sendFinanceReminder)
        {
            sendFinanceReminderMail();
        }
        
    }
    
    @future
    public static void sendFinanceReminderMail()
    {
            List<Messaging.SingleEmailMessage> emailsToBeSent = new List<Messaging.SingleEmailMessage>();
            List<String> toAddresses = new List<String>();
            String orgWideEmailId;
            Id targetObjectId;
            Id templateId;
            String fromEmailAddress;
            List<EmailTemplate> templates = [SELECT 
                                                id,developerName 
                                             FROM 
                                                EmailTemplate 
                                             WHERE 
                                                developerName in ('Overage_Finance_Reminder') ];
        
            if(templates == null || templates.size() != 1)
            {
                return;
            }
            try
            {
                fromEmailAddress = [Select 
                                        Value_Long__c 
                                    from 
                                        PSA_Common_Setting__mdt 
                                    where 
                                        Name__c = 'FromEmailAdress' limit 1].Value_Long__c ; 
                orgWideEmailId = [select 
                                    Id 
                                  from 
                                    OrgWideEmailAddress 
                                  where 
                                    Address= :fromEmailAddress limit 1].Id;
                
            }
            catch(Exception e)
            {
                orgWideEmailId = null;
            }

            for(User financeUsers: [Select id, email from User where PS_Overage_Finance_Approver__c = true and isactive = true])
            {
                toAddresses.add(financeUsers.email);
                if(targetObjectId == null)
                {
                    targetObjectId = financeUsers.Id;
                }
            }
            if(toAddresses != null)
            {
                templateId = templates.get(0).Id;
                emailsToBeSent.add(prepareMail(orgWideEmailId,toAddresses,targetObjectId, templateId,null,null,null, false));
            }
            if(! emailsToBeSent.isempty())
            {
                try
                {
                    Messaging.sendEmail(emailsToBeSent);    
                    system.debug('SENT successfully! ');
                }
                catch(Exception e)
                {
                    system.debug('Exeption: ' + e.getMessage());
                    //changes : 20.2.1 Notify mailinglist if any exceptions
                    PSA_AutoCreateProjectUtil.sendErrorMails('sendFinanceReminderMail Method Exception :: ',e.getMessage() + ' :Line: '+ e.getLineNumber());
                }
                
            }
        
        
    }
    
    //To identify the matching Overage CLI when on Manual Overage record creation
    public static void getOverageLinkedToProject(Boolean isInsert,Map<Id,PS_Overage_Hours__c> oldMap,List<PS_Overage_Hours__c> newList)
    {
        Id manualId = Schema.SObjectType.PS_Overage_Hours__c.getRecordTypeInfosByName().get('Manual').getRecordTypeId();
        Set<Id> projectIds = new Set<Id>();
        Set<Id> overagesIds = new Set<Id>();
        Map<Id, String> projectToKey = new Map<Id, String>();
        Map<String,Id> keyToOverage = new Map<String,Id>();
        Set<Date> endDates =  new Set<Date>();
        Set<Date> startDates =  new Set<Date>();
        Set<String> productIds = new Set<String>();
        //adding UOM
        Set<String> unitOfMeasures = new Set<String>();
        Set<Id> contractIds = new Set<Id>();
        for(PS_Overage_Hours__c psOverage : newList)
        {
            if(psOverage.recordTypeId == manualId && isInsert && psOverage.Original_Detail_ID__c == null) 
               //|| (!isInsert && oldMap.get(psOverage.Id).Project_ID__c != psOverage.Project_ID__c))
            {
                projectIds.add(psOverage.Project_ID__c);
                overagesIds.add(psOverage.Id);
            }
        }
        String key;
        //add 2 formula fileds on CLI and PCLI to have the key matched in both of them
        for(Project_Contract_Line_Item__c pcli : [Select 
                                                    Project__c,Contract_Detail__r.Effective_End_Date__c, Contract_Detail__r.Effective_Start_Date__c,Overage_Filters__c, Contract_Detail__r.Units_Low__c,
                                                    Contract_Detail__r.Product_Id__c,Contract_Detail__r.Original_Contract_Id__c,Contract_Detail__r.Unit_Of_Measure__c
                                                  from 
                                                    Project_Contract_Line_Item__c 
                                                  where 
                                                    Project__c in : projectIds 
                                                  and Contract_Detail__r.Record_Type__c = 'Committed'])
        {
            //key = '' + String.valueOf(pcli.Contract_Detail__r.Original_Contract_Id__c).substring(0, 15) + String.valueOf(pcli.Contract_Detail__r.Effective_End_Date__c) + 
                //String.valueOf(pcli.Contract_Detail__r.Effective_Start_Date__c) + pcli.Contract_Detail__r.Product_Id__c;
            //changes: removing Start data and adding Unit of Measure
            //key = '' + String.valueOf(pcli.Contract_Detail__r.Original_Contract_Id__c).substring(0, 15) + String.valueOf(pcli.Contract_Detail__r.Effective_End_Date__c) + 
                //String.valueOf(pcli.Contract_Detail__r.Unit_Of_Measure__c) + pcli.Contract_Detail__r.Product_Id__c;
            //20.2
            key = pcli.Overage_Filters__c;
            
            projectToKey.put(pcli.Project__c,key);
            endDates.add(pcli.Contract_Detail__r.Effective_End_Date__c);
            startDates.add(pcli.Contract_Detail__r.Effective_Start_Date__c);
            productIds.add(pcli.Contract_Detail__r.Product_Id__c);
            contractIds.add(pcli.Contract_Detail__r.Original_Contract_Id__c); 
            //adding the Unit of Measure
            unitOfMeasures.add(pcli.Contract_Detail__r.Unit_Of_Measure__c);
        }
        
        //changes: removing startDate Filters to find the Matching Overage CLI : removed from SOQL -> and Effective_Start_Date__c in :startDates && adding the Unit of Measure Filter
        for (Merge_Contract_Detail__c overagesCLI : [Select 
                                                        Id,Effective_Start_Date__c,Effective_End_Date__c, Overage_Filters__c,
                                                        Product_Id__c,original_Contract_Id__c, Unit_Of_Measure__c, Units_Low__c 
                                                     from 
                                                        Merge_Contract_Detail__c 
                                                     where 
                                                        original_Contract_Id__c in :contractIds
                                                     and Product_Id__c in :productIds 
                                                     and Unit_Of_Measure__c IN :unitOfMeasures
                                                     and Effective_End_Date__c in :endDates
                                                     and Record_Type__c = 'Overage' 
                                                     order by Effective_Start_Date__c desc])
        {
            //key = '' + String.valueOf(overagesCLI.original_Contract_Id__c).substring(0, 15) + String.valueOf(overagesCLI.Effective_End_Date__c) + 
                //String.valueOf(overagesCLI.Effective_Start_Date__c) + overagesCLI.Product_Id__c;
            //chages: removing Start data and adding Unit of Measure
            //key = '' + String.valueOf(overagesCLI.original_Contract_Id__c).substring(0, 15) + String.valueOf(overagesCLI.Effective_End_Date__c) + 
                //String.valueOf(overagesCLI.Unit_Of_Measure__c) + overagesCLI.Product_Id__c;
            //20.2
            key = overagesCLI.Overage_Filters__c;
            if(!keyToOverage.containsKey(key))
            {
                keyToOverage.put(key,overagesCLI.Id);
                
            }
        }
        
        for(PS_Overage_Hours__c psOverage : newList)
        {
            if(psOverage.recordTypeId == manualId && overagesIds.contains(psOverage.Id))
            {
                key = projectToKey.get(psOverage.Project_ID__c);
                if(key != null && keyToOverage.containsKey(key) && keyToOverage.get(key) != null)
                {
                    psOverage.Original_Detail_ID__c = keyToOverage.get(key);
                }
                //else
                //{
                //    psOverage.addError('The Project does not have an associated Overage Contract Detail!');
                //}
            }
        }

        
    }
    
    //called on before update of Overage record, TriggerInv
    public static void submitSignOff(Map<Id,PS_Overage_Hours__c> oldMap,List<PS_Overage_Hours__c> newList)
    {
        //String profiles = getProfilesList();
        Id profileId = UserInfo.getProfileId();
        Id automatedId = Schema.SObjectType.PS_Overage_Hours__c.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        Id manualId = Schema.SObjectType.PS_Overage_Hours__c.getRecordTypeInfosByName().get('Manual').getRecordTypeId();
        Id lockedId = Schema.SObjectType.PS_Overage_Hours__c.getRecordTypeInfosByName().get('Locked').getRecordTypeId();
        //Map<String,String> parameters = (Map<String,String>) JSON.deserializeStrict(profiles, Map<String,String>.class);
        Set<Date> holidays = new Set<Date>();
        for(PS_Overage_Hours__c psOverage : newList)
        {     
            //20.5 Addting Finance to take actions on the Automated Records as well
            //(RT = automated + GSS App) or ((RT = manual | RT = auto) + Finance App) or ( RT = manual + old recrod != null + old RT = locked )
            //|| psOverage.recordTypeId == automatedId
            // to unlock postpone records from Locked
            if((psOverage.recordTypeId == automatedId && psOverage.GSS_Approver__c ) 
               || ( (psOverage.recordTypeId == manualId || psOverage.recordTypeId == automatedId) && psOverage.Finance_Approver__c )
               || (psOverage.recordTypeId == manualId && oldMap != null &&  oldMap.get(psOverage.Id).recordTypeId == lockedId)
              )
            {
                if(psOverage.Trigger_Sign_Off__c)
                {
                    //to convert a Overage record to Manual when an GSS Approver Sign-Off
                    System.debug( 'Trigger Sign Off ');
                    if(psOverage.recordTypeId == automatedId && 
                       (psOverage.Overage_Action__c == 'Bill' && 
                        psOverage.Overage_Hours__c  < psOverage.To_be_Billed_Hours__c))
                    {
                        System.debug( 'Trigger Sign Off + Action = Bill + to be billed > Ovg hrs ');
                        psOverage.recordTypeId = manualId;
                        psOverage.Submitted__c = true;
                        psOverage.Submitted_Date__c = DateTime.now();
                        psOverage.Submitted_By__c = UserInfo.getUserId();
                        psOverage.Overage_Stage__c = 'Submitted'; 
                        //20.5 if logged in user is also a Finance person - allow him to Sign-off Overage at once
                        if(psOverage.Finance_Approver__c){
                            System.debug('Finance approver Signing automated TBB > OH ');
                            psOverage.Sign_Off__c = true;
                            psOverage.Sign_Off_Date__c = DateTime.now();
                            psOverage.Signed_Off_By__c = UserInfo.getUserId();
                            psOverage.Overage_Stage__c = 'Signed - Off';
                        } 
                    }
                    else
                    {
                        // Set this record for both Manual/ Automated by Approvers
                        System.debug( ' Trigger Sign Off + Action != Bill  ');
                        psOverage.Sign_Off__c = true;
                        psOverage.Sign_Off_Date__c = DateTime.now();
                        psOverage.Signed_Off_By__c = UserInfo.getUserId();
                        psOverage.Overage_Stage__c = 'Signed - Off';
                        //Finance create a record and he Sign Off for the first time
                        if(psOverage.recordTypeId == manualId && psOverage.Finance_Approver__c && !psOverage.Submitted__c)                                    
                        {
                            System.debug( 'RT = Manual + FF App + Submitted = false');
                            psOverage.Submitted__c = true;
                            psOverage.Submitted_Date__c = DateTime.now();
                            psOverage.Submitted_By__c = UserInfo.getUserId();
                            
                        }
                        else if ((psOverage.Automated_Overage__c && psOverage.Overage_Action__c == 'Bill'
                                  && psOverage.Overage_Hours__c  >= psOverage.To_be_Billed_Hours__c && 
                                  !psOverage.PS_Approved_Hours_Locked__c) && psOverage.Finance_Approver__c && psOverage.recordTypeId == manualId)
                        {
                            // convert bakc from manual to automated
                            psOverage.recordTypeId = automatedId;
                            psOverage.Manual_Overage__c =  false;        
                        }
                        //remove this block
                        else if(psOverage.Automated_Overage__c && psOverage.Overage_Action__c == 'Bill'
                                && psOverage.To_be_Billed_Hours__c > psOverage.Overage_Hours__c && psOverage.Finance_Approver__c && !psOverage.PS_Approved_Hours_Locked__c && psOverage.recordTypeId == automatedId)
                        {
                            //psOverage.recordTypeId = manualId;
                        }
                    }
                    
                }
                else
                {
                    //GSS  or FInance any one who modified the records over Submitted record
                    psOverage.Sign_Off__c = false;
                    psOverage.Sign_Off_Date__c = null;
                    psOverage.Signed_Off_By__c = null;
                    //SLM/SLD makes any changes - change the record stage to Saved or Finance make changes on manual record always set it to Submitted
                    psOverage.Overage_Stage__c = psOverage.recordTypeId == manualId && psOverage.Finance_Approver__c && psOverage.Overage_Stage__c != 'Saved'? 'Submitted' : 'Saved';
                    //20.5 if Finacec tried to modify any other field and Save
                    if(psOverage.Finance_Approver__c && psOverage.recordTypeId == automatedId){
                        psOverage.Submitted__c = false;
                        psOverage.Submitted_Date__c = null;
                        psOverage.Submitted_By__c = null;
                    }
                }
            }
            else if(psOverage.recordTypeId == manualId && psOverage.GSS_Approver__c)
            {
                //GSS or Finance Approver create Manual record
                if(psOverage.Trigger_Sign_Off__c)
                {
                    //if(psOverage.Automated_Overage__c && (psOverage.Overage_Action__c != 'Postpone' || 
                    //    psOverage.Overage_Hours__c  >= psOverage.To_be_Billed_Hours__c) && !psOverage.PS_Approved_Hours_Locked__c )
                    if((psOverage.Automated_Overage__c && psOverage.Overage_Action__c == 'Bill'
                        && psOverage.Overage_Hours__c  >= psOverage.To_be_Billed_Hours__c && 
                        !psOverage.PS_Approved_Hours_Locked__c) ||
                       psOverage.Overage_Action__c == 'Waive' || psOverage.Overage_Action__c == 'Postpone')
                    {
                        //any manual converted record is also considered when OVg <= To be Billed +   any record with Waive/Postpone - GSS Approver can Sign_off 
                        psOverage.Sign_Off__c = true;
                        psOverage.Sign_Off_Date__c = DateTime.now();
                        psOverage.Signed_Off_By__c = UserInfo.getUserId();
                        psOverage.Overage_Stage__c = 'Signed - Off';
                        if(psOverage.Overage_Action__c == 'Bill')
                        {
                            // convert bakc from manual to automated
                            psOverage.recordTypeId = automatedId;
                            psOverage.Manual_Overage__c =  false;    
                            
                        }
                        else if(psOverage.Overage_Action__c == 'Waive' || psOverage.Overage_Action__c == 'Postpone')
                        {
                            // any one can Sign Off Waive / Postpone
                            psOverage.Submitted__c = true;
                            psOverage.Submitted_Date__c = DateTime.now();
                            psOverage.Submitted_By__c = UserInfo.getUserId();
                            
                        }
                    }
                    else
                    {
                        // its normal Submission by GSS Approver clicks on SignOff
                        psOverage.Sign_Off__c = false;
                        psOverage.Sign_Off_Date__c = null;
                        psOverage.Signed_Off_By__c = null;
                        
                        psOverage.Submitted__c = true;
                        psOverage.Submitted_Date__c = DateTime.now();
                        psOverage.Submitted_By__c = UserInfo.getUserId();
                        psOverage.Overage_Stage__c = 'Submitted';                            
                        
                    }
                }
                else
                {
                    //Gss App when changes a manual record (created by Fiannce/GSs) + non SignOff
                    psOverage.Sign_Off__c = false;
                    psOverage.Sign_Off_Date__c = null;
                    psOverage.Signed_Off_By__c = null;
                    
                    psOverage.Submitted__c = false;
                    psOverage.Submitted_Date__c = null;
                    psOverage.Submitted_By__c = null;
                    psOverage.Overage_Stage__c = 'Saved';
                }
            }
            //else if(!validAutomatedUpsert && 
            //20.4.1 added validation flag && 
            //20.5 adding other users apart from (GA + FA) and removing as PM is also considered as another user now : psOverage.Project_Owner__c 
            else if(oldMap.get(psOverage.Id).Validation_Override__c == psOverage.Validation_Override__c && !validAutomatedUpsert && 
                    !(!psOverage.Trigger_Sign_Off__c && !psOverage.GSS_Approver__c 
                      && !psOverage.Finance_Approver__c  
                      &&  psOverage.Overage_Stage__c == 'Saved' && oldMap != null  
                      && (oldMap.get(psOverage.Id).Additional_Allocation_Project_ID__c != psOverage.Additional_Allocation_Project_ID__c
                          || oldMap.get(psOverage.Id).Justification_Category__c != psOverage.Justification_Category__c
                          || oldMap.get(psOverage.Id).Justification_Sub_Category__c != psOverage.Justification_Sub_Category__c
                          || oldMap.get(psOverage.Id).Project_Owner_Comments__c != psOverage.Project_Owner_Comments__c
                          || (psOverage.Project_Owner__c == true && (oldMap.get(psOverage.Id).Overage_Action__c != psOverage.Overage_Action__c
                          || oldMap.get(psOverage.Id).To_be_Billed_Hours__c != psOverage.To_be_Billed_Hours__c
                          || oldMap.get(psOverage.Id).Date_to_be_Billed__c != psOverage.Date_to_be_Billed__c
                          || oldMap.get(psOverage.Id).Justification__c != psOverage.Justification__c 
                          || oldMap.get(psOverage.Id).Details__c != psOverage.Details__c)))))
            {
                psOverage.addError('You do not have access to perform this action!');
            }
            psOverage.Trigger_Sign_Off__c = false;
        }
    }
    
    // method called on before insert/update of PS Overgaes Hour Records to set Overage Lock Date - Reminder Date - Amount and Currency Columns
    public static void postUpdateActions(Boolean isInsert, Map<Id,PS_Overage_Hours__c> oldMap, List<PS_Overage_Hours__c> newList)
    {
            Integer numberOfDays = 3;
            Integer cutOffHours = 12;
            Integer financeCutOff= 17;
            //Map<Id, Date> idToDate = new Map<Id, Date>();
            Map<String, Date> idToDate = new Map<String, Date>();
            Set<Date> holidayDates = new Set<Date>();
            Map<String,Double> conversionRateMap = new Map<String,Double>();
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
            Set<String> currencies = new Set<String>();
            List<PS_Overage_Hours__c> overages = new List<PS_Overage_Hours__c>();
            //changes: not needed 
            //PS_Overage_Hours__c overageRec;
            List<PS_Overage_Schedule__c> schedules = [Select 
                                                        Lock_Date__c 
                                                      from 
                                                        PS_Overage_Schedule__c ];   
            Id automatedId = Schema.SObjectType.PS_Overage_Hours__c.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
            Id manualId = Schema.SObjectType.PS_Overage_Hours__c.getRecordTypeInfosByName().get('Manual').getRecordTypeId();
         
            for(PS_Overage_Hours__c overageRec: newList)
            {
                String ovgKey = ''+overageRec.Project_ID__c+overageRec.Billing_Period_Start_Date__c+overageRec.Billing_Period_End_Date__c;
                    if(isInsert || overageRec.Overage_Lock_Date__c == null || overageRec.Overage_Billing_USD__c == null)
                    {
                        currencies.add(overageRec.Contract_Currency__c ); 
                        //store Overage Id To Billing Period End Date
                        if(overageRec.Billing_Period_End_Date__c != null && overageRec.RecordTypeId == automatedId && (isInsert || overageRec.Overage_Lock_Date__c == null))
                        {
                            //idToDate.put(overageRec.Id,overageRec.Billing_Period_End_Date__c);    
                            idToDate.put(ovgKey,overageRec.Billing_Period_End_Date__c);    
                        }
                        else if(isInsert && overageRec.RecordTypeId == manualId && !schedules.isEmpty())
                        {   
                            //set Overage Id to a Date of one month back
                            if(DateTime.now() < schedules.get(0).Lock_Date__c && schedules.get(0).Lock_Date__c.month() == date.Today().month() &&  schedules.get(0).Lock_Date__c.year() == date.Today().year() )
                            {
                                //idToDate.put(overageRec.Id,DateTime.now().dateGMT().addMonths(-1));    
                                idToDate.put(ovgKey,DateTime.now().dateGMT().addMonths(-1));    
                            }
                            //set Overage Id to a Date if time now is > Schedule Lock Date
                            else
                            {   
                                //idToDate.put(overageRec.Id,DateTime.now().dateGMT());    
                                idToDate.put(ovgKey,DateTime.now().dateGMT());    
                            }
                        }
                        //else
                        //{
                        //    system.assertEquals(1,2);
                        //}
                        
                    }
                    else
                    {   
                        if(oldMap.get(overageRec.Id).Overage_Hours__c != overageRec.Overage_Hours__c ||
                             oldMap.get(overageRec.Id).To_be_Billed_Hours__c != overageRec.To_be_Billed_Hours__c ||
                                oldMap.get(overageRec.Id).Amount_to_be_Billed_Contract_Cur_Num__c != overageRec.Amount_to_be_Billed_Contract_Cur_Num__c )
                        {
                            //at the time of manual cretion, check if Contract_Currency__c ! null as it may not have Contract Detail 
                            if(overageRec.Contract_Currency__c != null)
                            {
                                currencies.add(overageRec.Contract_Currency__c ); 
                            }
                            
                        }
                          
                    }
            }
            if(!idToDate.isEmpty())
            {
                List<Date> endDates = idToDate.values();
                endDates.sort();
                Date minDate = endDates.get(0);
                Date maxDate = endDates.get(endDates.size() - 1) != null ? endDates.get(endDates.size() - 1).addMonths(1) : null;
                // find all the Holidays between the Billing period end dates
                for(Finance_Calendar__c financeHoliday :[Select 
                                                            Holiday_Date__c 
                                                         from 
                                                            Finance_Calendar__c 
                                                         where 
                                                            Active__c = true 
                                                         and 
                                                            Holiday_Date__c >= :minDate 
                                                         and Holiday_Date__c <= :maxDate 
                                                         order by Holiday_Date__c])
                {                                           
                    holidayDates.add(financeHoliday.Holiday_Date__c);
                }
            }
            if(!currencies.isEmpty())
            {   
                                
                Date yearStartDate = date.newInstance(date.today().year(), 01, 01);
                //find and store all the Overage currencies from the DatedConversionRate    
                for(DatedConversionRate conversionRec: [select 
                                                            ConversionRate, IsoCode 
                                                        from 
                                                            DatedConversionRate 
                                                        where 
                                                            startdate >= :yearStartDate 
                                                        and IsoCode in :currencies])   
                {
                    conversionRateMap.put(conversionRec.IsoCode,conversionRec.ConversionRate);
                }
                conversionRateMap.put('USD',1.0);
                system.debug('The conversionMap: ' + conversionRateMap);
            }    
            //iterate the new List of Overages
            for(PS_Overage_Hours__c overageRec: newList)
            {
                String ovgKey = ''+overageRec.Project_ID__c+overageRec.Billing_Period_Start_Date__c+overageRec.Billing_Period_End_Date__c;
                //overageRec = null;
                //chnages: added overageRec.Contract_Currency__c
                if(overageRec.Contract_Currency__c != NULL && (isInsert || 
                   (!isInsert && 
                        (oldMap.get(overageRec.Id).Overage_Hours__c != overageRec.Overage_Hours__c || 
                            //21.1 adding late overages check to stamp proper values on amount || currency fields
                            (overageRec.Late_Hours__c && oldMap.get(overageRec.Id).Overage_Hours__c != overageRec.Overage_Hours__c) ||
                                oldMap.get(overageRec.Id).To_be_Billed_Hours__c != overageRec.To_be_Billed_Hours__c ||
                                    oldMap.get(overageRec.Id).Amount_to_be_Billed_Contract_Cur_Num__c != overageRec.Amount_to_be_Billed_Contract_Cur_Num__c ||
                                        overageRec.Amount_to_be_Billed_Contract_Cur_Num__c == null || overageRec.Overage_Billing_USD__c == null
                        )
                   ) 
                  ))
                {
                    //changes: commenting below
                    //newRec = new PS_Overage_Hours__c ();
                    //newRec.Id = overageRec.Id;
                    Double conversionRateDouble = conversionRateMap.get(overageRec.Contract_Currency__c ) == null ? 1.0 : conversionRateMap.get(overageRec.Contract_Currency__c );
                    try
                    {
                        system.debug('Overage_Hours__c: ' + overageRec.Overage_Hours__c + ' Overage_Rate__c: ' + overageRec.Overage_Rate__c + ' conversionRateDouble: ' + conversionRateDouble);
                        //set Overage_Billing_USD__c
                        if((overageRec.Overage_Hours__c != null  && overageRec.Overage_Rate__c != null && !overageRec.Event_Based_Overage__c ) )
                        {
                            overageRec.Overage_Billing_USD__c = overageRec.Overage_Hours__c * overageRec.Overage_Rate__c / conversionRateDouble;        
                        }   
                        //set Amount_to_be_Billed_Contract_Cur_Num__c and Amount
                        system.debug('To_be_Billed_Hours__c: ' + overageRec.To_be_Billed_Hours__c + ' Overage_Rate__c: ' + overageRec.Overage_Rate__c);
                        if(overageRec.To_be_Billed_Hours__c != null && overageRec.Overage_Rate__c != null && !overageRec.Event_Based_Overage__c )
                        {
                            overageRec.Amount_to_be_Billed_Contract_Cur_Num__c = overageRec.To_be_Billed_Hours__c * overageRec.Overage_Rate__c;
                            overageRec.Amount_to_be_Billed_USD__c = overageRec.To_be_Billed_Hours__c * overageRec.Overage_Rate__c / conversionRateDouble;    
                        }
                        //set Event_Based_Overage__c
                        if(overageRec.Event_Based_Overage__c && overageRec.Amount_to_be_Billed_Contract_Cur_Num__c != null)
                        {
                            overageRec.Amount_to_be_Billed_USD__c = overageRec.Amount_to_be_Billed_Contract_Cur_Num__c / conversionRateDouble;
                        }
                    }
                    catch(Exception e)
                    {
                        overageRec.Amount_to_be_Billed_Contract_Cur_Num__c = 0;
                        overageRec.Overage_Billing_USD__c = 0;
                        overageRec.Amount_to_be_Billed_USD__c = 0;
                    }
                }
                // if IsInsert idToDate contains OVerage id
                //if(isInsert || idToDate.containsKey(overageRec.Id))
                if(isInsert || idToDate.containsKey(ovgKey))
                {
                    //newRec is null || newRecId = OvgId -- set newRecId
                    /*if(overageRec == null || overageRec.Id != overageRec.Id)
                    {
                        overageRec = new PS_Overage_Hours__c ();
                        overageRec.Id = overageRec.Id;                        
                    }*/
                    date lockedDate = idToDate.get(ovgKey);
                    Integer daysToAdd = 0;
                    //lockedDate != null
                    if(lockedDate != null)
                    {
                        //21.1 - check if Late Hours are tracked in the system and set the Lock Date to next month from the current month
                        lockedDate = overageRec.Late_Hours__c ? lockedDate.addMonths(2).toStartOfMonth() : lockedDate.addMonths(1).toStartOfMonth();
                        overageRec.Reminder_Mail_Date__c = convertToESTCutOff(lockedDate, cutOffHours);
                        daysToAdd = numberOfDays;
                        lockedDate = addBusinessDays(lockedDate, daysToAdd,holidayDates);                        
                        //overageRec.Overage_Lock_Date__c = convertToESTCutOff(lockedDate, cutOffHours);
                        overageRec.Overage_Lock_Date__c = convertToESTCutOff(lockedDate, financeCutOff);
                    }
                    
                }  
                /*if(overageRec != null && overageRec.id == overageRec.Id)
                {
                    overages.add(overageRec); 
                }*/
                
            }
            /*if(!overages.isEmpty())
            {
                validAutomatedUpsert = true;
                Database.SaveResult[] saveResults = Database.update(overages,false);
                PSA_AutoCreateProjectUtil.PopulateErrorTableForUpdate(saveResults, overages);
            }*/
                
            
    }
    
    public static Datetime convertToESTCutOff(Date lockedDate, Integer cutOffHours)
    {
        Datetime lockedDateTime = datetime.newInstanceGMT(lockedDate.year(), lockedDate.month(), lockedDate.day(),cutOffHours,0,0);
        Timezone tz = Timezone.getTimeZone('America/New_York');
        Integer offset = -tz.getOffset(lockedDateTime)/ 1000;
        lockedDateTime = lockedDateTime.addSeconds(offset);                            
        
        return lockedDateTime;
    }
    
    // to calculate a proper business day ignoring Saturday/Sunday/a Akamai Holiday
    public static Date addBusinessDays(Date startDate, Integer days,Set<Date> holidayDates)
    {
        if(startDate == null || days == 0)
        {
            return null;
        }
        Integer daysToAdd = days;
        String day;
        Datetime startDateTime;
        system.debug('daysToAdd: ' + daysToAdd);
        while (daysToAdd > 0)
        {
            system.debug('New Iteration:  daysToAdd' + daysToAdd);
            startDateTime = datetime.newInstanceGmt(startDate.year(), startDate.month(), startDate.day());
            system.debug('startDateTime: ' + startDateTime);
            day = startDateTime.format('EEEE','GMT');
            system.debug('day: ' + day);
            if(day == 'Saturday' || day == 'Sunday')
            {
                system.debug('Inside weekend if' );
                startDate = (day == 'Saturday' ? startDate.addDays(2) : (day == 'Sunday' ? startDate.addDays(1) : startDate));        
            }
            else if(!holidayDates.isempty() && holidayDates.contains(startDate))
            {
                system.debug('Inside holidays if' );                
                startDate = startDate.addDays(1);
            }
            else
            {
                system.debug('Inside days decrease' );   
                if(daysToAdd > 1)
                {
                    startDate = startDate.addDays(1);    
                }
                daysToAdd--;
                
            }
            system.debug('daysToAdd: '+ daysToAdd );            
            system.debug('startDate: '+ startDate );            
        }
        return startDateTime.dateGmt();
        
        /*Datetime startDateTime = datetime.newInstanceGMT(endDate.year(), endDate.month(), endDate.day(),12,0,0);
        
        Timezone tz = Timezone.getTimeZone('America/New_York');
        Integer offset = -tz.getOffset(startDateTime)/ 1000;
        startDateTime = startDateTime.addSeconds(offset);*/
        
        //return startDate;
    }
    
    public static Messaging.SingleEmailMessage prepareMail(Id orgWideEmailId,String[] toAddresses,Id targetObjectId, Id templateId,Id whatId, String[] bccAddresses,String[] ccAddresses, Boolean sendMail)
    {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        if(orgWideEmailId != null)
        {
            email.setOrgWideEmailAddressId(orgWideEmailId);    
        }        
        if(toAddresses != null)
        {
            email.setToAddresses(toAddresses);    
        }            
        if(targetObjectId != null)
        {
            email.setTargetObjectId(targetObjectId);    
        }        
        email.setTemplateId(templateId);
        if(bccAddresses != null)
        {
            email.setBccAddresses(bccAddresses);    
        }
        if(ccAddresses != null)
        {
            email.setccAddresses(ccAddresses);    
        }       
        email.setSaveAsActivity(false);
        if(whatId != null)
        {
            email.setwhatId(whatId);    
        }
        if(sendMail)
        {
            try
            {
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});             
            }
            catch(Exception e)
            {
                //changes : 20.2.1 Notify mailinglist if any exceptions
                PSA_AutoCreateProjectUtil.sendErrorMails('prepareMail Method Exception :: ',e.getMessage() + ' :Line: '+ e.getLineNumber());
            }
            return null;    
        }
        else
        {
            return email;
        }
    }
    
    //Split Emails to given limit and stores in a Map and rerurn
    public static Map<Integer, List<String>> splitEmails(List<String> lEmails, Integer loadInterval){
        
        //remove duplicate emails
        Set<String> sfilterdEmails = new Set<String>(lEmails);
        System.debug('sfilterdEmails size()' + sfilterdEmails.size());
        Map<Integer, List<String>> keyTolEmals = new Map<Integer, List<String>>();
        Integer i = 0;
        Integer incrementCounter = loadInterval;

        for(String email : sfilterdEmails){

            if(i == incrementCounter){
                incrementCounter += loadInterval;
            }
            if(i <= incrementCounter){
                if(!keyTolEmals.containsKey(incrementCounter)){
                    keyTolEmals.put(incrementCounter, new List<String>());
                    keyTolEmals.get(incrementCounter).add(email);
                }else{
                    keyTolEmals.get(incrementCounter).add(email);
                }
            }
            i++;
        }
        
        /*for(Integer key : keyTolEmals.keySet()){
         System.debug('keyTolEmals key :: '+ key + ' :: ' + keyTolEmals.get(key).size());
        }*/
        
        if(!keyTolEmals.isEmpty()){
            return keyTolEmals;
        }else{
            return null;
        }

    }

    
    //to send out email reminder about the Overages created for the first 3 business Days to PM + PMs Manager + Additonal Maining Lists + OOO mails
    @future
    public static void sendOutOfOfficeMail()
    {
        
            Id userId = userInfo.getUserId();
            String fromEmailAddress;
            Id whatId;
            Id targetObjectId;
            Id templateId;
            List<String> bccAddresses = new List<String>();
            String bccAddressesString;
            List<Messaging.SingleEmailMessage> emailsToBeSent = new List<Messaging.SingleEmailMessage>();

            String orgWideEmailId;
            List<EmailTemplate> templates = [SELECT 
                                                id,developerName 
                                             FROM 
                                                EmailTemplate 
                                             WHERE 
                                                developerName in ('OOO_Notification_for_Manager', 'Notification_to_fill_out_overage_entries')];
            if(templates == null || templates.size() != 2)
            {
                return;
            }
        
            try
            {
                for (PSA_Common_Setting__mdt commonRec :[Select 
                                                            value__c,Value_Long__c,developerName 
                                                         from 
                                                            PSA_Common_Setting__mdt 
                                                         where 
                                                            developerName in ('FromEmailAdress','Overage_Reminder_Addresses')])
                {
                    if(commonRec.developerName == 'FromEmailAdress')
                    {
                        fromEmailAddress = commonRec.Value_Long__c;
                    }
                    else
                    {
                        bccAddressesString = commonRec.Value__c;
                    }
                }
                orgWideEmailId = [select 
                                    Id 
                                  from 
                                    OrgWideEmailAddress 
                                  where 
                                    Address= :fromEmailAddress limit 1].Id;
                
            }
                    
            
            catch(Exception e)
            {
                orgWideEmailId = null;
            }

            for(ps_overage_hours__c overageHoursRec: [Select 
                                                        id,project_id__r.OwnerId,project_id__r.Owner_Email_address__c, project_id__r.Owner_Manager_Email_address__c  
                                                      from 
                                                        ps_overage_hours__c 
                                                      where 
                                                        recordtype.Name != 'Locked' 
                                                      and Overage_Lock_Date__c = THIS_MONTH])
            {
                bccAddresses.add(overageHoursRec.project_id__r.Owner_Email_address__c);
                bccAddresses.add(overageHoursRec.project_id__r.Owner_Manager_Email_address__c);
                if(targetObjectId == null && overageHoursRec.project_id__r.OwnerId != null)
                {
                    targetObjectId = overageHoursRec.project_id__r.OwnerId;
                }
            }
            if(bccAddresses != null)
            {
                bccAddresses.addAll(bccAddressesString.split(','));
                PS_Overage_Schedule__c schedule = [Select Id  from PS_Overage_Schedule__c limit 1];   
                whatId = schedule.Id;
                templateId = templates.get(0).developerName == 'Notification_to_fill_out_overage_entries'? templates.get(0).Id: templates.get(1).Id;
                //emailsToBeSent.add(prepareMail(orgWideEmailId,null,targetObjectId, templateId,whatId,bccAddresses,null, false));
                //20.2.1 changes : email split + notifying everyone in batches of 80 from metadata
                PSA_Common_Setting__mdt getEmailLimit = [SELECT 
                                                            Name__c, Value__c 
                                                         FROM 
                                                            PSA_Common_Setting__mdt 
                                                         WHERE
                                                            DeveloperName = 'Email_Limit_for_Overages' 
                                                         AND type__c = 'Email_Limit_for_Overages'];
                /*Adding Junk emails for testing purpose comment out after QA verified                
                for(Integer i =0; i <=500; i++){
                       bccAddresses.add('qaTest'+i+'@akam.com'); 
                }*/
                
                Map<Integer, List<String>> splitEmails = PSA_OverageController.splitEmails(bccAddresses, Integer.valueOf(getEmailLimit.Value__c));
                for(Integer key : splitEmails.keySet()){
                    if(key != NULL && splitEmails.get(key) != NULL){
                        /*List<String> addVibhuByDefault = new List<String>();
                        addVibhuByDefault.add('vbajpai@akamai.com');
                        addVibhuByDefault.addAll(splitEmails.get(key));*/
                        emailsToBeSent.add(prepareMail(orgWideEmailId,splitEmails.get(key),targetObjectId, templateId,whatId,null,null, false));
                    }
                }
                //emailsToBeSent.add(prepareMail(orgWideEmailId,bccAddresses,targetObjectId, templateId,whatId,null,null, false));
                
            }
            for (user userRec : [Select 
                                    id,email, PS_Out_of_Office__c,ManagerId,Manager.Email 
                                 from 
                                    user 
                                 where 
                                    PS_Out_of_Office__c = true 
                                 and isactive = true])
            {
                if(userRec.PS_Out_of_Office__c)
                {
                    templateId = templates.get(0).developerName == 'OOO_Notification_for_Manager'? templates.get(0).Id: templates.get(1).Id;
                    emailsToBeSent.add(prepareMail(orgWideEmailId,new String[] {userRec.Manager.Email},userRec.Id, templateId,null,null,null, false));                
                }
                
            }
            if(! emailsToBeSent.isempty())
            {
                try
                {
                    Messaging.sendEmail(emailsToBeSent);             
                }
                catch(Exception e)
                {
                    //changes : 20.2.1 Notify mailinglist if any exceptions
                    PSA_AutoCreateProjectUtil.sendErrorMails('sendOutOfOfficeMail Method Exception :: ',e.getMessage() + ' :Line: '+ e.getLineNumber());
                }
                
            }
    }

    @future
    public static void checkOverage(List<Id> timedateIds)
    {
            try
            {    
                system.debug('iNside checkOverage');
                Set<Date> startDates = new Set<Date>();
                Set<Date> endDates = new Set<Date>();
                Set<String> productIds = new Set<String>();
                Set<String> contractids = new Set<String>();
                Set<Id> projectIds = new Set<Id>();
                Set<String> overageIds = new Set<String>();
                //Chnages: storing Unit of measures to apply filter
                Set<String> unitOfMeasures = new Set<String>();
                //add All the Billing Duration for committed and Overage CLI as well
                Set <String> billingDurations = new Set <String>();
                //Store all CommittedKey TO set<Project Ids>
                Map<String,Set<Id>> contractKeyToProjects = new Map<String,Set<Id>>();
                //store all the Project Id TO Committed CLI Key
                Map<Id, String> projectIdToString = new Map<Id, String>();
                //store all the Project Id TO Date at which the resource Logged the Time TO hours Invested.
                Map<Id,Map<Date,Decimal>> projectToHours = new Map<Id,Map<Date,Decimal>>();
                //20.2 store all projectId TO CMT CLI
                //Map<Id,Merge_Contract_Detail__c> projIdToCMTCLI = new Map<Id,Merge_Contract_Detail__c>();
                //20.4.1 converted data prep to a wrapper class
                Map<Id,PSA_CommintCLIWrapper> projIdToCMTCLI = new Map<Id,PSA_CommintCLIWrapper>();
                //Map<String,Merge_Contract_Detail__c> projIdTrimmedToCMTCLI = new Map<String,Merge_Contract_Detail__c>();
                //20.4.1 converted data prep to a wrapper class
                Map<String,PSA_CommintCLIWrapper> projIdTrimmedToCMTCLI = new Map<String,PSA_CommintCLIWrapper>();
                //store all overageKey TO Overage CLI
                Map<String,Merge_Contract_Detail__c> contractKeyToOverage = new Map<String,Merge_Contract_Detail__c>();
                String key;
                //20.4.1 load all project Id To its PCLI Id
                Map<String, String> projIdToPCLIId = new Map<String, String>();
                
                
                //20.2 adding additional columns Overage filters and CLI Id -- 20.4.1 Added PCLI column from TimeDates 
                for(pse__Time_Date__c timedate: [select 
                                                    id, pse__Hours__c,pse__Date__c, Contract_Salesforce_Id__c, CLI_Overage_Filters__c,
                                                    CLI_Effective_End_Date__c,CLI_Effective_Start_Date__c,CLI_Billing_Duration__c ,
                                                    Product_Id__c, pse__Timecard__r.pse__Project__c, CLI_Units_of_Measure__c,CLI_Units_Low__c,
                                                    pse__Timecard__r.pse__Assignment__r.Project_Contract_Line_Item__r.Contract_Detail__c,
                                                    pse__Timecard__r.pse__Assignment__r.Project_Contract_Line_Item__c
                                                 from 
                                                    pse__Time_Date__c 
                                                 where 
                                                    pse__Timecard__r.pse__Billable__c  = true 
                                                 and pse__Hours__c != 0
                                                 and CLI_Record_Type__c  = 'Committed' 
                                                 and pse__Timecard__r.pse__Status__c = 'Approved'
                                                 and id in :timedateIds])
                { 
                    
                    //FFPSA-1327 : Removing Start Date and Billing Duration Filter and adding Unit of Measure filter by Sujay
                    //key = '' + String.valueOf(timedate.Contract_Salesforce_Id__c).substring(0, 15) + String.valueOf(timedate.CLI_Effective_End_Date__c) + 
                        //String.valueOf(timedate.CLI_Effective_Start_Date__c) + timedate.Product_Id__c + timedate.CLI_Billing_Duration__c;
                    //20.2
                    //key = '' + String.valueOf(timedate.Contract_Salesforce_Id__c).substring(0, 15) + String.valueOf(timedate.CLI_Effective_End_Date__c) + 
                        //String.valueOf(timedate.CLI_Units_of_Measure__c) + timedate.Product_Id__c ;
                    //20.4.1 loading projIdToPCLIId
                    if(! projIdToPCLIId.containsKey(timedate.pse__Timecard__r.pse__Project__c)){
                        projIdToPCLIId.put(String.valueOf(timedate.pse__Timecard__r.pse__Project__c).substring(0, 15), timedate.pse__Timecard__r.pse__Assignment__r.Project_Contract_Line_Item__c);
                    }
                    key = timedate.CLI_Overage_Filters__c;
                    System.debug('CMT Key >>' + key);
                    //chanages: commenting Start Date filter
                    //chanages : startDates.add(timedate.CLI_Effective_Start_Date__c);
                    endDates.add(timedate.CLI_Effective_End_Date__c);
                    productIds.add(timedate.Product_Id__c); 
                    contractids.add(timedate.Contract_Salesforce_Id__c);
                    //store all the Project Id TO Committed CLI Key
                    projectIdToString.put(timedate.pse__Timecard__r.pse__Project__c,key);
                    //chnages : adding Unit of Measure and billingDurations of Committed CLIs
                    unitOfMeasures.add(timedate.CLI_Units_of_Measure__c);
                    billingDurations.add(timedate.CLI_Billing_Duration__c); 
                    //20.2
                    if(timedate.pse__Timecard__r.pse__Assignment__r.Project_Contract_Line_Item__r.Contract_Detail__c != NULL && !projIdToCMTCLI.containsKey(timedate.pse__Timecard__r.pse__Project__c))
                    {
                        //20.4.1 converting the data prep to a wrapper class
                        PSA_CommintCLIWrapper cmtCLI  = new PSA_CommintCLIWrapper(timedate.pse__Timecard__r.pse__Assignment__r.Project_Contract_Line_Item__r.Contract_Detail__c, timedate.CLI_Effective_End_Date__c, timedate.CLI_Effective_Start_Date__c,timedate.CLI_Units_of_Measure__c, timedate.CLI_Units_Low__c, timedate.CLI_Billing_Duration__c);
                        /*Merge_Contract_Detail__c cmtCLI = new Merge_Contract_Detail__c();
                        cmtCLI.Id = timedate.pse__Timecard__r.pse__Assignment__r.Project_Contract_Line_Item__r.Contract_Detail__c;
                        cmtCLI.Effective_End_Date__c = timedate.CLI_Effective_End_Date__c;
                        cmtCLI.Effective_Start_Date__c = timedate.CLI_Effective_Start_Date__c;
                        cmtCLI.Billing_Duration__c = timedate.CLI_Billing_Duration__c;
                        cmtCLI.Unit_Of_Measure__c = timedate.CLI_Units_of_Measure__c;
                        cmtCLI.Units_Low__c = timedate.CLI_Units_Low__c;*/
                        projIdToCMTCLI.put(timedate.pse__Timecard__r.pse__Project__c,cmtCLI);
                        projIdTrimmedToCMTCLI.put(String.valueOf(timedate.pse__Timecard__r.pse__Project__c).substring(0, 15),cmtCLI);
                    }
                    if(!contractKeyToProjects.containsKey(key))
                    {
                        contractKeyToProjects.put(key,new Set<Id>());
                    }
                    if(! contractKeyToProjects.get(key).contains(timedate.pse__Timecard__r.pse__Project__c))
                    {
                        contractKeyToProjects.get(key).add(timedate.pse__Timecard__r.pse__Project__c);
                    }
                    if(!projectToHours.containsKey(timedate.pse__Timecard__r.pse__Project__c))
                    {
                        projectToHours.put(timedate.pse__Timecard__r.pse__Project__c,new Map<Date,Decimal>());
                    }
                    if(!projectToHours.get(timedate.pse__Timecard__r.pse__Project__c).containsKey(timedate.pse__Date__c))
                    {                
                        projectToHours.get(timedate.pse__Timecard__r.pse__Project__c).put(timedate.pse__Date__c,0);                
                        System.debug('for Project Id : ' + timedate.pse__Timecard__r.pse__Project__c + ' ::: '+ ' project Id to hours :: '+  ' :: for date:: '+ timedate.pse__Date__c + ' ::: hours = '+ projectToHours.get(timedate.pse__Timecard__r.pse__Project__c).get(timedate.pse__Date__c));
                    }
                    System.debug('for Project Id : ' + timedate.pse__Timecard__r.pse__Project__c +' ::: Timedate hours :: '+ timedate.pse__Hours__c);
                    Decimal totalHours = projectToHours.get(timedate.pse__Timecard__r.pse__Project__c).get(timedate.pse__Date__c);
                    System.debug('totalHours at that date  :: '+ totalHours);
                    totalHours += timedate.pse__Hours__c;
                    System.debug('totalHours + Timedate hours :: '+ totalHours);
                    projectToHours.get(timedate.pse__Timecard__r.pse__Project__c).put(timedate.pse__Date__c,totalHours);
                    System.debug('Adding total Hours at that particular date for that project ::  ' + timedate.pse__Timecard__r.pse__Project__c + ' ::: '+ ' :: for date:: '+ timedate.pse__Date__c +  ' project Id to hours :: '+ projectToHours.get(timedate.pse__Timecard__r.pse__Project__c).get(timedate.pse__Date__c));
                }
                System.debug('contractKeyToProjects >> '+ contractKeyToProjects);
                System.debug('projectToHours >> '+ projectToHours);
                projectIds = new Set<Id>();
                overageIds = new Set<String>();
                
                //Moving billingDurations to also Load Commited CLI billing Duration
                //Set <String> billingDurations = new Set <String>();
                //chanages : removing SOQL with Start Date Filter - and Effective_Start_Date__c in :startDates and added Units_of_Measure__c column abd the filter
                for (Merge_Contract_Detail__c overagesCLI : [Select Id,Effective_Start_Date__c,Billing_Duration__c,Effective_End_Date__c, Unit_of_Measure__c,
                                                               Product_Id__c,Units_Low__c,original_Contract_Id__c,original_Contract_Id__r.Account_Name__c, Overage_Filters__c 
                                                             from 
                                                                Merge_Contract_Detail__c 
                                                             where 
                                                                original_Contract_Id__c in :contractids
                                                             and Product_Id__c in :productIds 
                                                             and Effective_End_Date__c in :endDates
                                                             and Record_Type__c = 'Overage' 
                                                             and Unit_of_Measure__c IN :unitOfMeasures
                                                             order by Effective_Start_Date__c desc])
                {
                    //chanages :FFPSA-1327 : Removing Start Date and Billing Duration Filter and adding Unit of Measure filter by Sujay
                    //key = '' + String.valueOf(overagesCLI.original_Contract_Id__c).substring(0, 15) + String.valueOf(overagesCLI.Effective_End_Date__c) + 
                        //String.valueOf(overagesCLI.Effective_Start_Date__c) + overagesCLI.Product_Id__c ;
                    //20.2
                    //key = '' + String.valueOf(overagesCLI.original_Contract_Id__c).substring(0, 15) + String.valueOf(overagesCLI.Effective_End_Date__c) + 
                        //String.valueOf(overagesCLI.Unit_of_Measure__c) + overagesCLI.Product_Id__c ;
                    key = overagesCLI.Overage_Filters__c;
                    System.debug('Ovg Key >> ' + key);
                    if(!contractKeyToOverage.containsKey(key))
                    {
                        //store all overageKey TO Overage CLI
                        contractKeyToOverage.put(key,overagesCLI);
                        if(contractKeyToProjects.containsKey(key))
                        {
                              //store all the ProjectIds that has matching Overage CLI, store all Overgae Ids, store all Billing Durations
                              projectIds.addAll(contractKeyToProjects.get(key)); 
                              overageIds.add(overagesCLI.Id);
                              billingDurations.add(overagesCLI.Billing_Duration__c);
                        }
                        
                    }
                }
                //store all the UOM value that has corresponding number
                Map<String,Integer> nameToNumberMapping = new Map<String,Integer>();
                if(billingDurations != null && billingDurations.size() > 0)
                {
                       //for (PSA_Common_Setting__mdt durationMapping : [Select Name__c ,Value__c  from PSA_Common_Setting__mdt  
                       //                                                where DeveloperName like  'Billing_Duration%' and type__c = 'AK_CC_BILLING_DURATION'])
                       //{
                       //    system.debug('durationMapping: ' + durationMapping);
                       //    nameToNumberMapping.put(durationMapping.Name__c,Integer.valueOf(durationMapping.Value__c));
                       //}
                       //Changes : this table gives the equivalent period to consider.
                       for (Siebel_LOV__c  durationMapping : [select  
                                                                Description__c, Display_Value__c 
                                                              from 
                                                                Siebel_LOV__c 
                                                              where 
                                                                Active__c = 'Y' 
                                                              and Display_Value__c in :billingDurations])
                       {
                           system.debug('durationMapping: ' + durationMapping);
                           nameToNumberMapping.put(durationMapping.Display_Value__c,Integer.valueOf(durationMapping.Description__c));
                       }
                        System.debug('nameToNumberMapping >> '+ nameToNumberMapping);
                       if(nameToNumberMapping.isEmpty())
                       {
                           //changes : Just find the equivalent period to consider from CMD if the Siebel_LOV__c is not having the data
                           for (PSA_Common_Setting__mdt durationMapping : [Select 
                                                                            Name__c ,Value__c  
                                                                           from 
                                                                            PSA_Common_Setting__mdt  
                                                                           where 
                                                                            DeveloperName like  'Billing_Duration%' 
                                                                           and type__c = 'AK_CC_BILLING_DURATION'])
                           {
                               //system.debug('durationMapping: ' + durationMapping);
                               nameToNumberMapping.put(durationMapping.Name__c,Integer.valueOf(durationMapping.Value__c));
                           }
                           
                       }
        
                }
                //send an error email if Billing Duration has no entry 
                if(nameToNumberMapping.isEmpty())
                {
                    PSA_AutoCreateProjectUtil.sendErrorMails('Check Overage Method Missing BillingDuration','List of ids: ' + timedateIds);
                    return;
                }
                system.debug('contractKeyToOverage: ' + contractKeyToOverage);
                system.debug('billingDurations: ' + billingDurations);
                //Stores the Key of Billing Period that shud be part of PS Approved hours To hours Invested on that period
                Map<String, Decimal> overageRecKeyToHours = new Map<String, Decimal>();
                List<Date> periodDates;
                Merge_Contract_Detail__c overageCLI;
                //20.2
                //Merge_Contract_Detail__c cmtCLI;
                //20.4.1
                PSA_CommintCLIWrapper cmtCLI;
                String billingPeriodKey;
                Decimal totalHours = 0;
                Set<Id> missingDurationProjects = new Set<Id>();
                for(Id projectId: projectIds)
                {
                    //projectIdToString has Project Id TO Committed CLI Key, contractKeyToOverage has OverageKey TO Overage CLI
                    overageCLI = contractKeyToOverage.get(projectIdToString.get(projectId));
                    //20.2
                    cmtCLI = projIdToCMTCLI.get(projectId);
                    System.debug('cmtCLI :: '+ cmtCLI);
                    //if(nameToNumberMapping.containsKey(overageCLI.Billing_Duration__c))
                    if(nameToNumberMapping.containsKey(cmtCLI.BillingDuration))
                    {
                        for (Date hoursDate: projectToHours.get(projectId).KeySet())
                        {     
                            //20.2
                            //periodDates = getBillingPeriodDates(overageCLI.Effective_Start_Date__c,overageCLI.Effective_End_Date__c,nameToNumberMapping.get(overageCLI.Billing_Duration__c),hoursDate, true);
                            periodDates = getBillingPeriodDates(cmtCLI.EffectiveStartDate,cmtCLI.EffectiveEndDate,nameToNumberMapping.get(cmtCLI.BillingDuration),hoursDate, true);
                            System.debug('hoursDate >> ' + 'periodDates >> '+ periodDates);
                            if(periodDates != null && periodDates.size() == 2)
                            {
                                startDates.add(periodDates.get(0));
                                endDates.add(periodDates.get(1));                        
                                //billingPeriodKey =  String.valueOf(periodDates.get(0)) + ','
                                //    + String.valueOf(periodDates.get(1)) + ','+ String.valueOf(overageCLI.id) + ',' + String.valueOf(projectId);
                                billingPeriodKey =  String.valueOf(periodDates.get(0)) + ','
                                    + String.valueOf(periodDates.get(1)) + ',' + String.valueOf(projectId).substring(0, 15);
                                //Stores the Key of Billing Period that shud be part of PS Approved hours To hours Invested on that period
                                System.debug('billingPeriodKey >> '+ billingPeriodKey);
                                if(!overageRecKeyToHours.containsKey(billingPeriodKey))
                                {
                                    overageRecKeyToHours.put(billingPeriodKey,0);
                                }
                                totalHours = overageRecKeyToHours.get(billingPeriodKey);
                                System.debug('totalHours present fot billingPeriodKey ::  '+ totalHours);
                                totalHours += projectToHours.get(projectId).get(hoursDate);
                                System.debug('totalHours after summing ::: '+ totalHours);
                                overageRecKeyToHours.put(billingPeriodKey,totalHours);
                                System.debug('overageRecKeyToHours ::  ' + overageRecKeyToHours);
                            }   
                        }
                        System.debug('overageRecKeyToHours after the loop ::: ' + overageRecKeyToHours);
                    }
                    else
                    {
                        missingDurationProjects.add(projectId);
                    }
                }
                
                List<PS_Approved_Hours__c> approvedHourRecsToUpsert = new List<PS_Approved_Hours__c>();
                List<PS_Overage_Hours__c> overageRecsToUpsert = new List<PS_Overage_Hours__c>();
                
                List<String> keySplit = new List<String>();
                Decimal unitsLowForPeriod;
                system.debug('overageRecKeyToHours: ' + overageRecKeyToHours);
                system.debug('nameToNumberMapping: ' + nameToNumberMapping);
                system.debug('contractKeyToProjects: ' + contractKeyToProjects);
                system.debug('projectToHours: ' + projectToHours);
                
                // chnages : adding unit of measure column //20.4.1 - adding PCLI column
                for (PS_Approved_Hours__c approvedHourRec: [Select Project__c, Contract_Detail__c, Billing_Duration__c, Approved_Hours__c, 
                                                                    Overage_Hours__c,Units_Low__c,Contract_Detail__r.Units_Low__c,
                                                                    Billing_Period_Start_Date__c,Billing_Period_End_Date__c,
                                                                    CLI_Start_Date__c, CLI_End_Date__c,Locked__c, Contract_Detail__r.Unit_Of_Measure__c,
                                                                    Project_Contract_Line_Item__c, Late_Hours__c, Late_Overage_Hours__c
                                                            from 
                                                                PS_Approved_Hours__c 
                                                            where
                                                                Project__c in :projectIds 
                                                            and Contract_Detail__c in :overageIds 
                                                            and Billing_Period_Start_Date__c in :startDates
                                                            and Billing_Period_End_Date__c in :endDates]) 
                {
                    //key = String.valueOf(approvedHourRec.Billing_Period_Start_Date__c) + ',' + 
                    //                + String.valueOf(approvedHourRec.Billing_Period_End_Date__c) + ','+ String.valueOf(approvedHourRec.Contract_Detail__c) + ','+ String.valueOf(approvedHourRec.Project__c);
                    key = String.valueOf(approvedHourRec.Billing_Period_Start_Date__c) + ',' + 
                                    + String.valueOf(approvedHourRec.Billing_Period_End_Date__c) + ','+ String.valueOf(approvedHourRec.Project__c).substring(0, 15);
                    //21.2 this is to ensure approved hour calculation happens to any Approved hour record that belongs to > previous month 
                    if(approvedHourRec.Billing_Period_End_Date__c.month() >= Date.today().addMonths(-1).toStartOfMonth().month())
                    {
                        totalHours = overageRecKeyToHours.get(key);
                        if(totalHours != null)
                        {
                            if(approvedHourRec.Contract_Detail__r.Units_Low__c != approvedHourRec.Units_Low__c)
                            {
                                approvedHourRec.Units_Low__c = approvedHourRec.Contract_Detail__r.Units_Low__c;
                            }
                            approvedHourRec.Approved_Hours__c = approvedHourRec.Approved_Hours__c == null? 0 : approvedHourRec.Approved_Hours__c;
                            totalHours += approvedHourRec.Approved_Hours__c;
                            
                            //changes: added one more param to the getUnitsLow method call to alter Units Low if UOM is Business Days
                            //20.2 adding changes to consider UOM and Billing duration from CMT CLI 
                            cmtCLI = projIdToCMTCLI.get(approvedHourRec.Project__c);
                            //unitsLowForPeriod = getUnitsLow(approvedHourRec.Billing_Duration__c, approvedHourRec.Billing_Period_Start_Date__c, approvedHourRec.Billing_Period_End_Date__c, approvedHourRec.Units_Low__c, approvedHourRec.Contract_Detail__r.Unit_Of_Measure__c);                    
                            //20.4.1
                            unitsLowForPeriod = getUnitsLow(cmtCLI.BillingDuration, approvedHourRec.Billing_Period_Start_Date__c, approvedHourRec.Billing_Period_End_Date__c, approvedHourRec.Units_Low__c, cmtCLI.UnitOfMeasure);                    
                            //approvedHourRec.Overage_Hours__c = approvedHourRec.Approved_Hours__c > unitsLowForPeriod ? approvedHourRec.Approved_Hours__c - unitsLowForPeriod : 0;                    
                            
                            //check if the hours Approved are after the Billing Period of the previous calender month end
                            //21.1 Check if the Billing Period End Date is for the previous month and the Hours are tracked for the current Month
                            if((approvedHourRec.Billing_Period_End_Date__c.addMonths(1)).toStartOfMonth().month() == Date.today().month() &&  (approvedHourRec.Billing_Period_End_Date__c.addMonths(1)).toStartOfMonth().year() == Date.today().year() )
                            {
                                System.debug('prining Billing_Period_End_Date__c just before setting it to Late HoursapprovedHourRec :: '+ approvedHourRec);
                                approvedHourRec.Late_Hours__c = true;
                                approvedHourRec.Late_Overage_Hours__c  = totalHours > unitsLowForPeriod ? (approvedHourRec.Overage_Hours__c != null && approvedHourRec.Overage_Hours__c != 0  ) ? totalHours - (approvedHourRec.Overage_Hours__c + unitsLowForPeriod) : totalHours - unitsLowForPeriod : 0 ;
                                //uncheck this locked field to ensure the late overages are tracked if the approved hour record is locked post billing cycle for the previous month 
                                approvedHourRec.Locked__c = false;
                            }
                            else
                            {
                                approvedHourRec.Late_Hours__c = false;
                                approvedHourRec.Overage_Hours__c = totalHours > unitsLowForPeriod ? totalHours - unitsLowForPeriod: 0;
                            }
                            
                            approvedHourRec.Approved_Hours__c = totalHours;
                            approvedHourRec.Project_Contract_Line_Item__c = projIdToPCLIId.get(String.valueOf(approvedHourRec.Project__c).substring(0, 15));
                            approvedHourRecsToUpsert.add(approvedHourRec);
                        }
                    }
                    if(overageRecKeyToHours.containsKey(key))
                    {
                         overageRecKeyToHours.remove(key);
                    }
                }
        
                system.debug('overageRecKeyToHours: '+ overageRecKeyToHours);
                if(overageRecKeyToHours != null && overageRecKeyToHours.size() > 0)
                {
                    startDates = new Set<Date>();
                    endDates = new Set<Date>();
                    projectIds = new Set<Id>();            
                    for(String overageKey : overageRecKeyToHours.keySet())
                    {
                        keySplit = overageKey.split(',');
                        startDates.add(Date.valueOf(keySplit[0]));
                        endDates.add(Date.valueOf(keySplit[1]));
                        projectIds.add(Id.valueOf(keySplit[2]));
                    }
                    List<Date> timeDateFilter = new List<Date>();
                    timeDateFilter.addAll(startDates);
                    timeDateFilter.addAll(endDates);
                    timeDateFilter.sort();
                    
                    Date minDate = timeDateFilter.get(0);
                    Date maxDate = timeDateFilter.get(timeDateFilter.size() - 1);
                    
                    Map<String,Decimal> overageKeyToTotalHours = new Map<String,Decimal>();
                    
                    //system.assertEquals(Limits.getDMLRows(),Limits.getLimitDMLRows());            
                    Integer limitRecords = Limits.getLimitQueryRows() - Limits.getQueryRows() - 10001;
                    
                    //chnages: Adding Unit Of Measure column from TimeDates Query for comuting if UoM = 'Business Days'
                    for(pse__Time_Date__c timedate: [select 
                                                        id, pse__Hours__c,pse__Date__c, Contract_Salesforce_Id__c,CLI_Overage_Filters__c,
                                                        CLI_Effective_End_Date__c,CLI_Effective_Start_Date__c,CLI_Billing_Duration__c,
                                                        Product_Id__c, pse__Timecard__r.pse__Project__c, CLI_Units_of_Measure__c, CLI_Units_Low__c
                                                     from 
                                                        pse__Time_Date__c 
                                                     where 
                                                        pse__Timecard__r.pse__Billable__c  = true 
                                                     and pse__Hours__c != 0
                                                     and CLI_Record_Type__c  = 'Committed' 
                                                     and pse__Timecard__r.pse__Status__c = 'Approved'
                                                     and pse__Timecard__r.pse__Project__c in :projectIds 
                                                     and pse__Date__c >= :minDate
                                                     and pse__Date__c <= :maxDate 
                                                     order by pse__Date__c limit :limitRecords
                                                    ])
                    {     
                        //changes: remove Effective_Start_Date__c, Billing_Duration__c and add UOM from Overage CLI                                    
                        //20.2
                        //String CMTkey = '' + String.valueOf(timedate.Contract_Salesforce_Id__c).substring(0, 15) + String.valueOf(timedate.CLI_Effective_End_Date__c) + 
                                            //String.valueOf(timedate.CLI_Units_of_Measure__c) + timedate.Product_Id__c ;
                        String CMTkey = timedate.CLI_Overage_Filters__c;
                        Merge_Contract_Detail__c ovgCLI = contractKeyToOverage.get(CMTkey);
                        //20.2 added cmtdCLI and modified the check to CMT CLI
                        //Merge_Contract_Detail__c cmtdCLI = projIdToCMTCLI.get(timedate.pse__Timecard__r.pse__Project__c);
                        //20.4.1
                        PSA_CommintCLIWrapper cmtdCLI = projIdToCMTCLI.get(timedate.pse__Timecard__r.pse__Project__c);
                        //if(nameToNumberMapping.get(timedate.CLI_Billing_Duration__c) != null)
                        if(nameToNumberMapping.get(cmtdCLI.BillingDuration) != null)
                        {   
                            //20.2 shouls consider Billing Duration from CMT CLI
                            //periodDates = getBillingPeriodDates(timedate.CLI_Effective_End_Date__c,ovgCLI.Effective_Start_Date__c,
                                                                //nameToNumberMapping.get(ovgCLI.Billing_Duration__c),timedate.pse__Date__c, true);
                            periodDates = getBillingPeriodDates(timedate.CLI_Effective_Start_Date__c,timedate.CLI_Effective_End_Date__c,
                                                                nameToNumberMapping.get(timedate.CLI_Billing_Duration__c),timedate.pse__Date__c, true);
                            System.debug('periodDates >> '+ periodDates);
                            if(periodDates != null && periodDates.size() ==2)
                            {
                                key = String.valueOf(periodDates[0]) + ',' + 
                                    + String.valueOf(periodDates[1]) + ','+ String.valueOf(timedate.pse__Timecard__r.pse__Project__c).substring(0, 15);
                                System.debug('key of Period end Dates >>' + key);
                                if(overageRecKeyToHours.containsKey(key))
                                {
                                    if(!overageKeyToTotalHours.containsKey(key))
                                    {
                                        overageKeyToTotalHours.put(key,0);
                                    }
                                    overageKeyToTotalHours.put(key,(overageKeyToTotalHours.get(key) + timedate.pse__Hours__c));
                                    
                                }
                                System.debug('overageRecKeyToHours >> '+ overageRecKeyToHours);
                            }
                        } 
                        else
                        {
                             missingDurationProjects.add(timedate.pse__Timecard__r.pse__Project__c);                            
                        }
                    }//end of for
                    
                    system.debug('overageKeyToTotalHours: '+ overageKeyToTotalHours);
        
                    limitRecords = Limits.getLimitQueryRows() - Limits.getQueryRows() - 10001;
                    if(limitRecords == 0)
                    {
                        PSA_AutoCreateProjectUtil.sendErrorMails('PS Overage Limit Reached','The TimeDate Ids: ' + timedateIds);                       
                    }
        
                    if(!overageKeyToTotalHours.isEmpty())
                    {
                        PS_Approved_Hours__c approvedHourRec;
                        for(String overageRecKey: overageKeyToTotalHours.keySet())
                        {
                            keySplit = overageRecKey.split(',');
                            overageCLI = contractKeyToOverage.get(projectIdToString.get(Id.valueOf(keySplit[2])));
                            //20.2 adding a Project check if its present in the projIdTrimmedToCMTCLI
                            if(projIdTrimmedToCMTCLI.containsKey(String.valueOf(keySplit[2]))){
                                cmtCLI = projIdTrimmedToCMTCLI.get(String.valueOf(keySplit[2]));
                                System.debug('Trimmed Proj Id : '+ String.valueOf(keySplit[2]) + ' : cmtCLI :: '+ cmtCLI);
                                System.debug('overageCLI to create an PS Approved Hour >> '+ overageCLI);
                                approvedHourRec = new PS_Approved_Hours__c();
                                approvedHourRec.Approved_Hours__c = overageKeyToTotalHours.get(overageRecKey);
                                approvedHourRec.Billing_Duration__c = overageCLI.Billing_Duration__c;
                                approvedHourRec.Billing_Period_End_Date__c = Date.valueOf(keySplit[1]);
                                approvedHourRec.Billing_Period_Start_Date__c = Date.valueOf(keySplit[0]);
                                approvedHourRec.CLI_End_Date__c = overageCLI.Effective_End_Date__c;
                                approvedHourRec.CLI_Start_Date__c = overageCLI.Effective_Start_Date__c;
                                approvedHourRec.Contract_Detail__c = overageCLI.Id;
                                approvedHourRec.Original_Contract_ID__c = overageCLI.original_Contract_Id__c;
                                approvedHourRec.Account__c = overageCLI.original_Contract_Id__r.Account_Name__c;
                                approvedHourRec.Locked__c = false;
                                approvedHourRec.Project__c = Id.valueOf(keySplit[2]);
                                approvedHourRec.Units_Low__c = overageCLI.Units_Low__c;
                                //20.4.1 adding addtional column PCLI when PS Approved Hours are created the very first time
                                approvedHourRec.Project_Contract_Line_Item__c = projIdToPCLIId.get(keySplit[2]);
                                //changes: added one more param to the getUnitsLow method call to alter Units Low if UOM is Business Days
                                //unitsLowForPeriod = getUnitsLow(approvedHourRec.Billing_Duration__c, approvedHourRec.Billing_Period_Start_Date__c, approvedHourRec.Billing_Period_End_Date__c, approvedHourRec.Units_Low__c, overageCLI.Unit_Of_Measure__c);                    
                                //20.2 pointing to Committed CLIs  Billing Duration and UOM inplace of Overage CLI
                                unitsLowForPeriod = getUnitsLow(cmtCLI.BillingDuration, approvedHourRec.Billing_Period_Start_Date__c, approvedHourRec.Billing_Period_End_Date__c, approvedHourRec.Units_Low__c, cmtCLI.UnitOfMeasure);                    
                                System.debug('approvedHourRec :: '+ approvedHourRec + ' : :: unitsLowForPeriod :: ' + unitsLowForPeriod);
                                //21.1
                                if((approvedHourRec.Billing_Period_End_Date__c.addMonths(1)).toStartOfMonth().month() == Date.today().month() &&  (approvedHourRec.Billing_Period_End_Date__c.addMonths(1)).toStartOfMonth().year() == Date.today().year() )
                                {
                                    System.debug('prining Billing_Period_End_Date__c just before setting it to Late HoursapprovedHourRec :: '+ approvedHourRec);
                                    approvedHourRec.Late_Hours__c = true;
                                    approvedHourRec.Late_Overage_Hours__c  = approvedHourRec.Approved_Hours__c > unitsLowForPeriod ? approvedHourRec.Approved_Hours__c - unitsLowForPeriod : 0;
                                    //uncheck this locked field to ensure the late overages are tracked if the approved hour record is locked post billing cycle for the previous month 
                                    approvedHourRec.Locked__c = false;
                                } 
                                else
                                {
                                    approvedHourRec.Late_Hours__c = false;
                                    approvedHourRec.Overage_Hours__c = approvedHourRec.Approved_Hours__c > unitsLowForPeriod ? approvedHourRec.Approved_Hours__c - unitsLowForPeriod : 0;
                                }
                                System.debug('approvedHourRec.Overage_Hours__c :: '+ approvedHourRec.Overage_Hours__c);
                                approvedHourRec.External_Id__c = keySplit[0] + ',' + keySplit[1] + ',' + keySplit[2] + ',' + string.valueOf(overageCLI.Id); 
                                System.debug('approvedHourRec >> ' + approvedHourRec);
                                approvedHourRecsToUpsert.add(approvedHourRec);
                            }
                        }
                    }
                }
                system.debug('approvedHourRecsToUpsert: '+ approvedHourRecsToUpsert);
                if(!approvedHourRecsToUpsert.isEmpty())
                {
                    List<Database.UpsertResult> upsertResultRecords = new List<Database.UpsertResult>();
                    upsertResultRecords = Database.Upsert(approvedHourRecsToUpsert,false);
                    PSA_AutoCreateProjectUtil.PopulateErrorTableForUpsert(upsertResultRecords, 'Approved Hours Upsert');
                    
                }
                if(!missingDurationProjects.isEmpty())
                {
                    PSA_AutoCreateProjectUtil.sendErrorMails('Check Overage Method Missing Duration','Projects have different Billing Durations ' + missingDurationProjects);
                }
            }
            catch(Exception e)
            {
                   PSA_AutoCreateProjectUtil.sendErrorMails('Check Overage Method Exception',e.getMessage() + ':Line: '+ e.getLineNumber() + '\nTimedates: ' + timedateIds);
            }
    }
    
    //This method creates an instance for PS Overage record creation called from upsertOverageRecords method
    public static PS_Overage_Hours__c createOverageRecord(PS_Approved_Hours__c approvedHourRec, Boolean useExternalId)
    {
        PS_Overage_Hours__c overageRec;
        PS_Approved_Hours__c approvedHourRecPointer;
            
        overageRec = new PS_Overage_Hours__c();
        overageRec.Billing_Period_End_Date__c = approvedHourRec.Billing_Period_End_Date__c;
        overageRec.Billing_Period_Start_Date__c = approvedHourRec.Billing_Period_Start_Date__c;
        overageRec.Manual_Overage__c = false;
        overageRec.Original_Detail_ID__c = approvedHourRec.Contract_Detail__c;
        overageRec.Original_Contract_ID__c  = approvedHourRec.Original_Contract_ID__c;
        //21.1
        overageRec.Overage_Hours__c = approvedHourRec.Late_Hours__c ? approvedHourRec.Late_Overage_Hours__c : approvedHourRec.Overage_Hours__c;
        overageRec.Project_ID__c = approvedHourRec.Project__c;
        overageRec.End_Customer_Name__c  = approvedHourRec.Account__c;
        //20.4.1 adding a column on PS Overage Hours - PCLI
        overageRec.Project_Contract_Line_Item__c = approvedHourRec.Project_Contract_Line_Item__c;
        if(useExternalId)
        {
            approvedHourRecPointer = new PS_Approved_Hours__c();
            approvedHourRecPointer.External_Id__c = approvedHourRec.External_Id__c;
            overageRec.PS_Approved_Hours__r = approvedHourRecPointer;
        }
        else
        {
            overageRec.PS_Approved_Hours__c = approvedHourRec.Id;
        }
        overageRec.RecordTypeId  = Schema.SObjectType.PS_Overage_Hours__c.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
        //21.1 - check for Late Overage Hours - mark to be billed based on that
        overageRec.Late_Hours__c = approvedHourRec.Late_Hours__c;
        overageRec.To_be_Billed_Hours__c = approvedHourRec.Late_Hours__c ? approvedHourRec.Late_Overage_Hours__c : approvedHourRec.Overage_Hours__c;
        overageRec.Billable_Hours__c = approvedHourRec.Approved_Hours__c; 
        overageRec.Automated_Overage__c = true; 
        
        
        return overageRec;
    }
    
    //changes : This mehod is genric and it gives the period start and end date as per the CLI start and end Date
    public static List<Date> getBillingPeriodDates (Date startDate, Date endDate, Integer billingDuration, Date dateToCheck, Boolean prorateMonthly)
    {        
        //20.2 if Billing duration < 0 retrun null if  == 0 then return the start and end date as ontime
        if(dateToCheck == null || startDate == null || endDate == null || billingDuration == null || billingDuration < 0)
        {
            return null;
        }
        Date firstDate = startDate > endDate? endDate : startDate;
        Date lastDate =  startDate > endDate? startDate : endDate;
        date periodStartDate;
        date periodEndDate;
       
        if(dateToCheck < firstDate || dateToCheck > lastDate)
        {
            return null;
        }
        
        List <date> periodDates = new List <date>();
        
        //20.2 returning same period of start and end date if BD = "0"
        if(billingDuration == 0){
            periodDates.add(startDate);
            periodDates.add(endDate);
            return periodDates;
        }
        
        if(billingDuration == 1 && prorateMonthly)
        {
            periodStartDate = dateToCheck.toStartOfMonth();
            Integer noOfDays = Date.daysInMonth(dateToCheck.year(), dateToCheck.month());            
            periodEndDate = periodStartDate.addDays(noOfDays - 1);             
        }
        else
        {
            Integer daysBetween = firstDate.daysBetween(dateToCheck);
    
            Decimal monthsBetween = 0;
            monthsBetween = firstDate.monthsBetween(dateToCheck) - 1 + 
                ((Decimal)(Date.daysInMonth(firstDate.year(), firstDate.month()) - firstDate.day())/Date.daysInMonth(firstDate.year(), firstDate.month())) 
                + ((Decimal)dateToCheck.day()/Date.daysInMonth(dateToCheck.year(), dateToCheck.month()))
            ;
            //Decimal valueOfEachDay = daysBetween/monthsBetween;
            
            //Decimal daysToSubtract = math.mod(billingDuration, 5) == 0 ? monthsBetween/(Decimal)billingDuration: monthsBetween/(Decimal)billingDuration - 1;
            
            //Decimal total = (monthsBetween - (daysToSubtract/valueOfEachDay))/billingDuration;
            Decimal total = monthsBetween/billingDuration;
            
            Integer floorTotal = (Integer)Math.floor(total);
            
            //List <date> periodDates = new List <date>();
            //date periodStartDate = firstDate.addMonths(floorTotal * billingDuration).addDays(floorTotal);
            periodStartDate = firstDate.addMonths(floorTotal * billingDuration);
            //date periodEndDate = periodStartDate.addMonths(billingDuration);
            periodEndDate = periodStartDate.addMonths(billingDuration).addDays(-1);
            
        }
        
        //if(periodStartDate >= firstDate)
        //{
        //    periodDates.add(periodStartDate);    
        //}
        //else
        //{
        //    periodDates.add(firstDate);    
        //}
        //if(periodEndDate <= lastDate)
        //{
        //    periodDates.add(periodEndDate);
        //}
        //else
        //{
        //    periodDates.add(lastDate);
        //}
        //
        periodStartDate = periodEndDate < dateToCheck? periodEndDate.addDays(1) : periodStartDate;
        periodEndDate = periodStartDate > periodEndDate ? periodStartDate.addMonths(billingDuration).addDays(-1) : periodEndDate;


        periodStartDate = periodStartDate < firstDate? firstDate : periodStartDate;
        periodEndDate = periodEndDate > lastDate? lastDate:periodEndDate;


        periodDates.add(periodStartDate);
        periodDates.add(periodEndDate);
        return periodDates;
    }
    
    //changes: This method computes and returns the Units Low value if Billing Duration is Monthly: Applies proration, It also consider if Unit Of measure is 'Business Days' it multiples with 8
    public static Decimal getUnitsLow(String billingDuration, Date periodStart, Date periodEnd, Decimal unitsLow, String unitOfmeasure)
    {
          Date monthlyStartDate;
          Date monthlyEndDate;
          Decimal unitsLowValue;
          unitsLowValue = unitsLow;
            if(unitOfmeasure == 'Business Days')
            {
                unitsLowValue = (Decimal)unitsLow * 8;
            }        

            if(billingDuration == 'Monthly' )
            {
                Integer noOfDaysMonth = Date.daysInMonth(periodStart.year(), periodStart.month());            
                Integer daysBetween = periodStart.daysBetween(periodEnd) + 1;
                if(noOfDaysMonth != daysBetween)
                {
                    System.debug('(Decimal)unitsLowValue :: '+ (Decimal)unitsLowValue + ' :: (Decimal)noOfDaysMonth :: '+ (Decimal)noOfDaysMonth+ ' ::: (Decimal)daysBetween '+ (Decimal)daysBetween );
                    unitsLowValue = (Decimal)unitsLowValue/(Decimal)noOfDaysMonth * (Decimal)daysBetween;
                    System.debug('unitsLowValue >> ' + unitsLowValue);
                    //return unitsLowValue;
                }                    
            }
            //add one more formula field.
            return unitsLowValue;
    }
    
    //Called from PS_Approved_Hours__c trigger post insert/update
    /* Below method Update/Create PS Overage Hours (Ovg Hours, To be Billed and Billable hours when Ovg is still Saved and Automated type)*/
    public static void upsertOverageRecords (Boolean isInsert, Map<Id,PS_Approved_Hours__c> oldMap, List<PS_Approved_Hours__c> newList)
    {
        Map<Id,PS_Approved_Hours__c> approvedHourRecIdsMap = new Map<Id,PS_Approved_Hours__c>();
        List<PS_Overage_Hours__c> overageRecToUpsert = new List<PS_Overage_Hours__c>();
        //21.1 load normal Overage and Late Overage Hours based on PS Approved Hour Key.
        Map<Id,List<PS_Overage_Hours__c>> overageAndLateOvrgaes = new Map<Id,List<PS_Overage_Hours__c>>();
        
        for(PS_Approved_Hours__c approvedHourRec : newList)
        {
            //20.4.1 added one more if condition to check and update the PCLI when chnaged
            //20.4.2 adding one more filter if Overage hours > 0 only then update the Project Contract Line Item
            //21.1 During Insert/update to Approved hour record - check for Overage/Late hours are changed in the system and inclide them for updates for respecetd Billing periods
            if( (isInsert && (approvedHourRec.Overage_Hours__c > 0 || (approvedHourRec.Late_Overage_Hours__c > 0 &&  approvedHourRec.Late_Hours__c)))  || 
                (!isInsert && (approvedHourRec.Overage_Hours__c != oldMap.get(approvedHourRec.Id).Overage_Hours__c || (approvedHourRec.Late_Hours__c && !(oldMap.get(approvedHourRec.Id).Late_Overage_Hours__c == null && approvedHourRec.Late_Overage_Hours__c == 0) && approvedHourRec.Late_Overage_Hours__c != oldMap.get(approvedHourRec.Id).Late_Overage_Hours__c ) ) ) )
            {
                approvedHourRecIdsMap.put(approvedHourRec.id,approvedHourRec);
            }
        }
        if(!approvedHourRecIdsMap.isEmpty())
        {
                System.debug('Printing the approvedHourRecIdsMap ' + approvedHourRecIdsMap);
                Id automatedId  = Schema.SObjectType.PS_Overage_Hours__c.getRecordTypeInfosByName().get('Automated').getRecordTypeId();
                //20.4.1 Adding PCLI column to load the data on Overage Rec to use
                //21.1 Adding more columns to Overage Hours Query for tracking Late overage hours recs
                for(PS_Overage_Hours__c overageRec: [Select 
                                                        Overage_Hours__c ,Manual_Overage__c, Overage_Stage__c,PS_Approved_Hours__c ,RecordTypeId,
                                                        To_be_Billed_Hours__c ,Billable_Hours__c, Billing_Period_End_Date__c, 
                                                        PS_Approved_Hours__r.Project_Contract_Line_Item__c, Project_Contract_Line_Item__c, Late_Hours__c,
                                                        PS_Approved_Hours__r.Late_Hours__c , PS_Approved_Hours__r.Late_Overage_Hours__c
                                                      from 
                                                        PS_Overage_Hours__c 
                                                      where 
                                                        PS_Approved_Hours__c in :approvedHourRecIdsMap.keySet() order by PS_Approved_Hours__c ])
                {                                       
                if(! overageAndLateOvrgaes.containsKey(overageRec.PS_Approved_Hours__c))
                    {
                        overageAndLateOvrgaes.put(overageRec.PS_Approved_Hours__c,new List<PS_Overage_Hours__c>());
                     }
                overageAndLateOvrgaes.get(overageRec.PS_Approved_Hours__c).add(overageRec);
                }
            
                System.debug('Printing the overageAndLateOvrgaes ' + overageAndLateOvrgaes);
                                                     
            //changing the for loop to iterate over ps Approved hours key from ps Overage Hours                              
                for (Id psApprovedId: approvedHourRecIdsMap.keySet() )
                {
                    PS_Overage_Hours__c overageRec = new PS_Overage_Hours__c();
                    boolean removePSApprovedHourKey = false;
                    
                    System.debug('printing pprovedHourRecIdsMap.get(psApprovedId)  ' + approvedHourRecIdsMap.get(psApprovedId).Late_Hours__c);
                    if( approvedHourRecIdsMap.get(psApprovedId).Late_Hours__c && overageAndLateOvrgaes.containsKey(psApprovedId) )
                    {
                        System.debug('printing overageAndLateOvrgaes.get(psApprovedId)  ' + overageAndLateOvrgaes.get(psApprovedId));
                        for(PS_Overage_Hours__c ovg : overageAndLateOvrgaes.get(psApprovedId))
                        {
                            System.debug('printing ovg  ' + ovg);
                            if(ovg.Late_Hours__c && ovg.ps_Approved_Hours__r.Late_Hours__c)
                            {
                                overageRec = ovg;
                                removePSApprovedHourKey = true;
                                System.debug('printing overageRec  ' + overageRec);
                            }
                        }  
                    }
                    else if( !approvedHourRecIdsMap.get(psApprovedId).Late_Hours__c && overageAndLateOvrgaes.containsKey(psApprovedId) && overageAndLateOvrgaes.get(psApprovedId).size() == 1 && !overageAndLateOvrgaes.get(psApprovedId)[0].Late_Hours__c )
                    {
                        overageRec = overageAndLateOvrgaes.get(psApprovedId)[0];
                        removePSApprovedHourKey = true;
                        System.debug('printing overageRec in elseIf ' + overageRec);
                    }
                    
                    if(overageRec.RecordTypeId == automatedId && !overageRec.Manual_Overage__c && overageRec.Overage_Stage__c == 'Saved' && approvedHourRecIdsMap.containsKey(overageRec.PS_Approved_Hours__c))
                    {
                        System.debug('printing overageRec for insert/update ' + overageRec);
                         //21.1 - update Late Overage Hours when there is change in the overage hours
                        overageRec.Overage_Hours__c = overageRec.Late_Hours__c ? approvedHourRecIdsMap.get(overageRec.PS_Approved_Hours__c).Late_Overage_Hours__c : approvedHourRecIdsMap.get(overageRec.PS_Approved_Hours__c).Overage_Hours__c;
                        //check if its normal Overgage/late Overgae Hours and set the to be billed hours
                        if(overageRec.Billing_Period_End_Date__c !=null && ( (!overageRec.Late_Hours__c && Date.today() < overageRec.Billing_Period_End_Date__c.addMonths(1).toStartOfMonth()) ||  (overageRec.Late_Hours__c && (overageRec.Billing_Period_End_Date__c.addDays(2)).toStartOfMonth().month() == Date.today().month() &&  (overageRec.Billing_Period_End_Date__c.addDays(2)).toStartOfMonth().year() == Date.today().year()  ) ) )
                        {
                            //21.1 - check if Late hours are tracked update the To Be billed to corresponding date 
                            overageRec.To_be_Billed_Hours__c = overageRec.Late_Hours__c ? approvedHourRecIdsMap.get(overageRec.PS_Approved_Hours__c).Late_Overage_Hours__c : approvedHourRecIdsMap.get(overageRec.PS_Approved_Hours__c).Overage_Hours__c;
                            System.debug('printing overageRec late/normal To_be_Billed_Hours__c ' + overageRec);
                        }
                        overageRec.Billable_Hours__c = approvedHourRecIdsMap.get(overageRec.PS_Approved_Hours__c).Approved_Hours__c;
                        //20.4.1 Adding an additonal column to track Billing Duration of CMT CLI
                        overageRec.Project_Contract_Line_Item__c = approvedHourRecIdsMap.get(overageRec.PS_Approved_Hours__c).Project_Contract_Line_Item__c;
                        
                        System.debug('printing overageRec after all changes ' + overageRec);
                        overageRecToUpsert.add(overageRec);
                    }
                    System.debug('printing overageRecToUpsert :: ' + overageRecToUpsert);
                    if(removePSApprovedHourKey)
                    {
                       System.debug('printing removePSApprovedHourKey :: ' + removePSApprovedHourKey);
                       approvedHourRecIdsMap.remove(overageRec.PS_Approved_Hours__c); 
                    }
                    
                }
                if(!approvedHourRecIdsMap.isEmpty())
                {
                    System.debug('printing approvedHourRecIdsMap for insert :: ' + approvedHourRecIdsMap);
                    for(Id approvedHourRecId : approvedHourRecIdsMap.keySet())
                    {
                        overageRecToUpsert.add(createOverageRecord(approvedHourRecIdsMap.get(approvedHourRecId), false));
                        System.debug('printing overageRecToUpsert for insert :: ' + overageRecToUpsert);
                    }
                }
            
        }
        if(!overageRecToUpsert.isEmpty())
        {
            List<Database.UpsertResult> upsertResultRecords = new List<Database.UpsertResult>();
            upsertResultRecords = Database.Upsert(overageRecToUpsert, false);
            PSA_AutoCreateProjectUtil.PopulateErrorTableForUpsert(upsertResultRecords, 'Overage Upsert');
        }
    }

    public PageReference openNewOverageCreatePage()
    {
        String recordTypeId = Schema.getGlobalDescribe().get('PS_overage_Hours__c').getDescribe().getRecordTypeInfosByName().get('Manual').getRecordTypeId();
        String objPrefix = Schema.getGlobalDescribe().get('PS_overage_Hours__c').getDescribe().getKeyPrefix();
        String baseUrl = system.URL.getSalesforceBaseUrl().toExternalForm()  + '/' + objPrefix + '/e?RecordType=' + recordTypeId + '&retURL=/';
        PageReference pg = new PageReference(baseUrl);
        pg.setRedirect(true);
        
        return pg;
    }
    
    //changes: add Org Wide Email Address
    @future
    public static void sendFileToCMG(Boolean lockRecords)
    {
            System.debug('sendFileToCMG : ' + lockRecords );
            //fields store all those columns that has to sent for billing.
            String fields;
            String header;
            //Changes: adding from and OrgWide address
            String orgWideEmailId;
            String fromAddress= '';
            List<String> toAddresses = new List<String>();
            Integer numberOfDays = 3;
            Integer cutOffHours = 12;
            Integer financeCutOff= 17;

            Date firstReminderDate;
            try{
                PSA_Common_Setting__mdt cs= [SELECT 
                                                Id, Name__c , Value_Long__c 
                                             FROM
                                                PSA_Common_Setting__mdt 
                                             WHERE 
                                                Name__c = 'FromEmailAdress'];
                fromAddress = cs.Value_Long__c != NULL ? cs.Value_Long__c : 'services-engg@akamai.com';
            }
            catch(Exception e ){
                System.debug('Exception occured in fetching CMD :: ' + e.getMessage());
                fromAddress = 'services-engg@akamai.com';
            }
            
            //add try catch block and use custom metadata
            try{
                orgWideEmailId = [select 
                                    Id 
                                  from 
                                    OrgWideEmailAddress 
                                  where 
                                    Address = :fromAddress limit 1].Id;
            }
            catch(Exception e){
                System.debug('Exception occured while fetching OrWideEmailId in sendFileToCMG from PSA_overageController :: ' + e.getMessage());
                orgWideEmailId = null;
            }
            
            for (PSA_Common_Setting__mdt commonRec : [Select 
                                                        DeveloperName ,Value_Long__c, Value__c 
                                                      from 
                                                        PSA_Common_Setting__mdt  
                                                      where 
                                                        DeveloperName in ('PS_Overage_Report_Fields','PS_Overage_Report_Headers','Overage_CMG_Addresses','Overage_CutOff_Days','Overage_SignOff_Cutoff_GMT','PS_Overage_Finance_Cut_Off')])
            {
                if(commonRec.DeveloperName == 'PS_Overage_Report_Fields')
                {
                    fields = commonRec.Value_Long__c;
                }
                else if(commonRec.DeveloperName == 'PS_Overage_Report_Headers')
                {
                    header = commonRec.Value_Long__c + '\n';
                }
                else if(commonRec.DeveloperName == 'Overage_CMG_Addresses')
                {
                    //20.7 - shifted from text to text area to accomadoate more email entries
                    System.debug('tets ' + commonRec.Value_Long__c.split(','));
                    toAddresses = commonRec.Value_Long__c.split(',');
                }
                else if(commonRec.developername == 'Overage_CutOff_Days')
                {
                    numberOfDays = Integer.valueOf(commonRec.Value__c);
                }
                else if(commonRec.developername == 'Overage_SignOff_Cutoff_GMT')
                {
                    cutOffHours = Integer.valueOf(commonRec.Value__c);
                }
                else if(commonRec.developername == 'PS_Overage_Finance_Cut_Off')
                {
                    financeCutOff = Integer.valueOf(commonRec.Value__c);
                }
                
            }
            //String fields = 'End_Customer_Name__r.Name,Billing_Customer_ID__c,Billing_Customer_Name__c,Original_Contract_ID__r.Name,Original_Detail_ID__r.Name,Marketing_Product_Id__c,Marketing_Product_Name__c,CLI_Start_Date__c,CLI_End_Date__c,Billing_Duration__c,Billing_Period_Start_Date__c,Billing_Period_End_Date__c,Budget_Hours__c,Billable_Hours__c,Overage_Hours__c,Project_ID__c,Project_Owner__c,Project_Owner_Manager__c,Overage_Rate__c,Overage_Billing_Contract_Currency__c,Contract_Currency__c,Overage_Billing_USD__c,Billing_SOB__c,Required_Approver__c,Overage_Action__c,Submitted_By__r.Alias,Submitted_Date__c,Signed_Off_By__r.Alias,Sign_Off_Date__c,To_be_Billed_Hours__c,Project_Owner_Comments__c,Amount_to_be_Billed_Contract_Currency__c,Amount_to_be_Billed_USD__c,Justification_Category__c,Justification_Sub_Category__c,Justification__c,Additional_Allocation_Project_ID__c';
            String query = 'Select ' + fields + ',Event_Based_Overage__c,Overage_Hours__c,RecordTypeId,Id,Overage_Stage__c,Original_Contract_ID__c,Original_Detail_ID__c,Date_to_be_Billed__c,Overage_Lock_Date__c,Automated_Overage__c,Reminder_Mail_Date__c  from PS_Overage_Hours__c where RecordType.Name != \'Locked\' and Current_Period__c = true';
            List<PS_Overage_Hours__c> overageList= new List<PS_Overage_Hours__c>();
            overageList = Database.query(query);
            
            //String header = 'End Customer Name,Billing Customer ID,Billing Customer Name,Original Contract ID,Original Detail ID,Marketing Product Id,Marketing Product Name,CLI Start Date,CLI End Date,Billing Duration,Billing Period Start Date,Billing Period End Date,Budget Hours,Billable Hours(Approved),Overage Hours,Project ID,Project Owner,Project Owner Manager,Overage Rate(Contract Currency),Overage Billing (Contract Currency),Contract Currency,Overage Billing (USD),Billing SOB,Required Approver,Overage Action,Submitted By,Submitted Date,Signed-Off By,Sign-Off Date,To be Billed Hours,Project Owner Comments,Amount to be Billed (Contract Currency),Amount to be Billed (USD),Justification Category,Justification Sub-Category,Justification,Additional Allocation (Project ID)\n';
            String finalstr = header ;
    
            Id lockedRecordType = Schema.SObjectType.PS_Overage_Hours__c.getRecordTypeInfosByName().get('Locked').getRecordTypeId();
            List<PS_Overage_Hours__c> recordsToUpdate = new List<PS_Overage_Hours__c>();
            String recordString = '"';
            List <String> fieldSplits;
            String fieldName;
            List<String> parts;
            Object columnValueObject;
            String columnValueString;
            Decimal toround;
            Decimal rounded;
        
            for(PS_Overage_Hours__c overageRec: overageList)
            {
               if(overageRec.Overage_Stage__c == 'Signed - Off' && 
                  overageRec.Overage_Action__c == 'Bill' )
                {
                    System.debug('tets : '+ overageRec);
                    if(overageRec.Original_Contract_ID__c != null &&
                         overageRec.Original_Detail_ID__c != null)
                    {
                           overageRec.Sent_For_Billing__c = true; 
                           recordString = '';
                           fieldSplits = fields.split(',');
                           for(Integer i =0; i < fieldSplits.size() ; i++)
                           {    
                               fieldName = fieldSplits.get(i);
                               //to split key with (.) ex: input : Signed_Off_By__r.Alias output : [Signed_Off_By__r,Alias]
                               parts = fieldName.split('\\.');
                               system.debug('field: ' + fieldName);
                               
                               try
                               {
                                      if(parts != null && parts.size() == 1 && overageRec.get(fieldName) != null)
                                       {
                                            columnValueObject = overageRec.get(fieldName);
                                            if (columnValueObject instanceof Decimal)
                                            {
                                                toround = (Decimal)columnValueObject;
                                                rounded = toRound.setScale(2, RoundingMode.HALF_UP);
                                                columnValueString = String.ValueOf(rounded);
                                            }
                                            else
                
                                            {
                                               columnValueString = String.ValueOf(columnValueObject).escapeCsv();
                                            }
                                            recordString += (columnValueString.stripHtmlTags()).replaceAll('\\n', ' ** ');
                                       }
                                       else if(parts != null && parts.size() == 2 )
                                       {
                                           if(overageRec.getSobject(parts[0]) != null && overageRec.getSobject(parts[0]).get(parts[1]) != null)
                                           {
                                                columnValueObject = overageRec.getSobject(parts[0]).get(parts[1]);
                                                if (columnValueObject instanceof Decimal)
                                                {
                                                    toround = (Decimal)columnValueObject;
                                                    rounded = toRound.setScale(2, RoundingMode.HALF_UP);
                                                    columnValueString = String.ValueOf(rounded);
                                                }
                                                else
                
                                                {
                                                    columnValueString = String.ValueOf(columnValueObject).escapeCsv();
                
                                                }
                                                recordString += (columnValueString.stripHtmlTags()).replaceAll('\\n', ' ** ');
                                           }
                                           
                                       }
                                   
                               }
                               catch (Exception e)
                               {
                                    system.debug('Ignoring the column');    
                               }
                               if( i!= fieldSplits.size() - 1)
                               {
                                    recordString += ',';
                               }
                               
                           }
                    
                           recordString +='\n';
                           finalstr = finalstr +recordString;                   
                        
                    }
                    else 
                    {
                        overageRec.FF_Rejected__c = true;                        
                        overageRec.FF_Rejection_Reason__c = overageRec.Original_Contract_ID__c == null? 'Missing Contract' : 'Missing Contract Detail';
                    }

               }
               if(overageRec.Overage_Stage__c != 'Signed - Off')
               {
                   if(overageRec.Original_Detail_ID__c == NULL || (!overageRec.Event_Based_Overage__c && overageRec.Overage_Hours__c == 0) )
                   {
                       overageRec.Overage_Action__c = 'Invalid';    
                   }
                   else
                   {
                        overageRec.Overage_Action__c = 'No Action Taken';    
                   }
                   
               }
               if(overageRec.Overage_Stage__c == 'Signed - Off' && overageRec.Overage_Action__c == 'Postpone')
               {
                  firstReminderDate = overageRec.Date_to_be_Billed__c.addMonths(1).toStartOfMonth();   
                  overageRec.Reminder_Mail_Date__c =  convertToESTCutOff(firstReminderDate, cutOffHours);
                  firstReminderDate = addBusinessDays(firstReminderDate, numberOfDays,new Set<Date>());                         
                  overageRec.Overage_Lock_Date__c  = convertToESTCutOff(firstReminderDate, financeCutOff);
                  overageRec.Automated_Overage__c = false;
                  overageRec.Submitted__c = false;
                  overageRec.Submitted_Date__c = null;
                  overageRec.Submitted_By__c = null;
                  overageRec.Manual_Overage__c = true; 
               }
               if(lockRecords)
               {
                    overageRec.RecordTypeId = lockedRecordType;    
               }
               
               recordsToUpdate.add(overageRec); 
        }
    
            Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
            blob csvBlob = Blob.valueOf(finalstr);
            string csvname= 'Overages.csv';
            csvAttc.setFileName(csvname);
            csvAttc.setBody(csvBlob);
            Messaging.SingleEmailMessage email =new Messaging.SingleEmailMessage();
            String subject ='Overages CSV';
            email.setSubject(subject);
            //changes: adding the OrgWideEmail and email sending is in try catch block
            email.setOrgWideEmailAddressId(orgWideEmailId);
            email.setToAddresses( toAddresses );
            email.setPlainTextBody('PFA the Overages CSV');
            email.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttc});
            try
            {
                Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});  
            }
            catch(Exception e)
            {
                PSA_AutoCreateProjectUtil.sendErrorMails('Error: Overage notification to CMG failed from sendFileToCMG() - (Class:PSA_OverageController), ', e.getMessage());
            }
                
            if(lockRecords && !recordsToUpdate.isempty())
            {
                validAutomatedUpsert = true;
                Database.SaveResult[] saveResults = Database.update(recordsToUpdate,false);
                PSA_AutoCreateProjectUtil.PopulateErrorTableForUpdate(saveResults, recordsToUpdate);
            }
    }
    
    //This is called from a Component where it returns the Map of ProjectId To Key
    @AuraEnabled
    public static Map<String,String> getCLILinkedToProject(String projectIds)
    {   
        List<Id> projectIdsList = (List<String>)System.JSON.deserialize(projectIds, List<String>.class);
        Map<String,String> projectIdToKey = new Map<String,String>();
        String key;
        for(Project_Contract_Line_Item__c pcli : [Select 
                                                    Project__c,Original_Contract_Id__c ,Effective_End_Date__c , Overage_Filters__c, Units_Low__c,
                                                    Effective_Start_Date__c , Product_Id__c , Contract_Line_Record_Type__c, Unit_of_Measure__c  
                                                  from 
                                                    Project_Contract_Line_Item__c 
                                                  where 
                                                    Project__c in :projectIdsList 
                                                  and Contract_Line_Record_Type__c = 'Committed'])
        {
            //changes: adding Unit Of measure check and removing the 
            //key = '' + String.valueOf(pcli.Original_Contract_Id__c).substring(0, 15) + String.valueOf(pcli.Effective_End_Date__c) + 
                //String.valueOf(pcli.Effective_Start_Date__c) + pcli.Product_Id__c;
            //key = '' + String.valueOf(pcli.Original_Contract_Id__c).substring(0, 15) + String.valueOf(pcli.Effective_End_Date__c) + 
                //String.valueOf(pcli.Unit_of_Measure__c) + pcli.Product_Id__c;
            //20.2
            key = pcli.Overage_Filters__c;
            
            projectIdToKey.put(String.valueOf(pcli.Project__c).substring(0, 15),key);
        }
        return projectIdToKey;
    }
    
    public static void resetSchedule(Boolean isInsert,Map <Id, Finance_Calendar__c> oldMap,  List<Finance_Calendar__c> newList)
    {
        Integer numberOfDays = 3;
        Integer cutOffHours = 12;
        Integer financeCutOff= 17;
        for(PSA_Common_Setting__mdt commonMet : [Select 
                                                    id,developername, Value__c  
                                                 from 
                                                    PSA_Common_Setting__mdt  
                                                 where developername in ('Overage_CutOff_Days','Overage_SignOff_Cutoff_GMT','PS_Overage_Finance_Cut_Off') ])
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
        
        Set <Date> holidaysToConsider = new Set <Date>();
        Set <Date> holidays = new Set<Date>();
        PS_Overage_Schedule__c schedule = [Select 
                                            Lock_Date__c,Number_of_Mails_Sent__c,Reminder_Mail_Date__c, 
                                            Overage_Billing_Month__c,Billing_Month__c  
                                           from 
                                            PS_Overage_Schedule__c limit 1];
        Date lockedDateGMT = schedule.Lock_Date__c.dateGMT();
        for(Finance_Calendar__c calendar : newList)
        {
            if(calendar.Holiday_Month__c == schedule.Billing_Month__c  && 
               calendar.Holiday_Date__c <= lockedDateGMT)
            {
                holidaysToConsider.add(calendar.Holiday_Date__c);   
            }
            if(!isInsert && oldMap != null && 
               oldMap.get(calendar.Id).Holiday_Month__c == schedule.Billing_Month__c  && 
               oldMap.get(calendar.Id).Holiday_Date__c <= lockedDateGMT)
            {
                holidaysToConsider.add(oldMap.get(calendar.Id).Holiday_Date__c);
            }
        }
        if(!holidaysToConsider.isEmpty())
        {
            lockedDateGMT = lockedDateGMT.toStartOfMonth();
            for(Finance_Calendar__c financeHoliday :[Select Holiday_Date__c from Finance_Calendar__c where Active__c = true and Holiday_Month__c = :schedule.Billing_Month__c ])
            {
                holidays.add(financeHoliday.Holiday_Date__c);
            }
            Date firstReminderDate;
            if(schedule.Number_of_Mails_Sent__c == 0)
            {
                firstReminderDate = addBusinessDays(lockedDateGMT, 1,holidays);                        
            }
            else
            {
                firstReminderDate = addBusinessDays(schedule.Reminder_Mail_Date__c.dateGMT(), 1,holidays);                        
            }
            schedule.Reminder_Mail_Date__c = convertToESTCutOff(firstReminderDate, cutOffHours);
            firstReminderDate = addBusinessDays(lockedDateGMT, numberOfDays,holidays);                        
            schedule.Lock_Date__c = convertToESTCutOff(firstReminderDate, financeCutOff);
            try
            {
                update schedule;    
            }
            catch(Exception e)
            {
                PSA_AutoCreateProjectUtil.sendErrorMails('Schedule Update Failed! ',e.getMessage());
            }
        }
        
    }
}