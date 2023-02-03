trigger PSA_TimeCardThresholds on PSA_Timecard_thresholds__e (after insert) 
{
    List<PSA_Weekly_User_Timecard_Hours__c> psaWeeklylist = new List<PSA_Weekly_User_Timecard_Hours__c>();
    Map<Id,List<PSA_Weekly_User_Timecard_Hours__c>> sfIdToThreshHoldRecords = new Map<Id,List<PSA_Weekly_User_Timecard_Hours__c>>();
        
    for(PSA_Timecard_thresholds__e event : trigger.new)
    {
        PSA_Weekly_User_Timecard_Hours__c weeklyTimecardHourRec = createInstanceForWeeklyUserTimecardHours(event);
        
        if(event.Salesforce_Id__c == null){
            psaWeeklylist.add(weeklyTimecardHourRec);
        }
        else
        {
            if(!sfIdToThreshHoldRecords.containsKey(event.Salesforce_Id__c)){
                sfIdToThreshHoldRecords.put(event.Salesforce_Id__c, new List<PSA_Weekly_User_Timecard_Hours__c>{weeklyTimecardHourRec});   
            }
            else{
                sfIdToThreshHoldRecords.get(event.Salesforce_Id__c).add(weeklyTimecardHourRec);   
            }
        }
    }
    System.debug('sfIdToThreshHoldRecords ***:'+sfIdToThreshHoldRecords);
    
    if(!sfIdToThreshHoldRecords.isEmpty())
    {
        Map<Id, PSA_Weekly_User_Timecard_Hours__c> weeklyHourRecordFromDB = new Map<Id, PSA_Weekly_User_Timecard_Hours__c>([SELECT 
                                                                                                                            Id, Total_Approved_Hours__c, Total_Hours__c 
                                                                                                                        FROM 
                                                                                                                            PSA_Weekly_User_Timecard_Hours__c
                                                                                                                        WHERE 
                                                                                                                            Id IN :sfIdToThreshHoldRecords.keySet() FOR UPDATE]);
        System.debug('weeklyHourRecordFromDB ***: '+ weeklyHourRecordFromDB);
        for(Id key : sfIdToThreshHoldRecords.keySet())
        {
            PSA_Weekly_User_Timecard_Hours__c weeklyTimecardHourRec = sfIdToThreshHoldRecords.get(key)[0];
            if(sfIdToThreshHoldRecords.get(key).size() > 1)
            {   
                Decimal totalApprovedHours      = 0;
                Decimal totalHours              = 0;
                
                for(PSA_Weekly_User_Timecard_Hours__c weeklyTimecardRow : sfIdToThreshHoldRecords.get(key) )
                {
                    System.debug('weeklyTimecardRow.Total_Approved_Hours__c ***' + weeklyTimecardRow.Total_Approved_Hours__c + ' ***  weeklyHourRecordFromDB.get(key).Total_Approved_Hours__c ***  ' + weeklyHourRecordFromDB.get(key).Total_Approved_Hours__c);
                    System.debug('Action ***' + weeklyTimecardRow.Action__c);
                    
                    totalApprovedHours+= weeklyTimecardRow.Total_Approved_Hours__c;
                    
                    if (weeklyTimecardRow.Action__c == 'Submitted' || weeklyTimecardRow.Action__c == 'Rejected' || weeklyTimecardRow.Action__c == 'Saved')
                    {
                        totalHours+= weeklyTimecardRow.Total_Hours__c;
                    }
                    system.debug('totalApprovedHours ***: ' + totalApprovedHours + ' ::: ' + ' totalHours ***: ' + totalHours);
                }
                weeklyTimecardHourRec.Total_Approved_Hours__c = totalApprovedHours + weeklyHourRecordFromDB.get(key).Total_Approved_Hours__c;
                weeklyTimecardHourRec.Total_Hours__c = totalHours + weeklyHourRecordFromDB.get(key).Total_Hours__c;
                System.debug('weeklyTimecardHourRec.Total_Hours__c multiple ***'+ weeklyTimecardHourRec.Total_Approved_Hours__c);
                System.debug('weeklyTimecardHourRec.Total_Hours__c multiple ***'+ weeklyTimecardHourRec.Total_Hours__c);
            }
            else
            {
                if(weeklyTimecardHourRec.Action__c == 'Approved')
                {
                    weeklyTimecardHourRec.Total_Approved_Hours__c = sfIdToThreshHoldRecords.get(key)[0].Total_Approved_Hours__c + weeklyHourRecordFromDB.get(key).Total_Approved_Hours__c;  
                	weeklyTimecardHourRec.Total_Hours__c = weeklyHourRecordFromDB.get(key).Total_Hours__c;
                }
                else if (weeklyTimecardHourRec.Action__c == 'Rejected' || weeklyTimecardHourRec.Action__c == 'Saved' || weeklyTimecardHourRec.Action__c == 'Submitted')
                {
                    weeklyTimecardHourRec.Total_Hours__c = weeklyHourRecordFromDB.get(key).Total_Hours__c + weeklyTimecardHourRec.Total_Hours__c;
                    weeklyTimecardHourRec.Total_Approved_Hours__c = weeklyHourRecordFromDB.get(key).Total_Approved_Hours__c;
                }
                System.debug('weeklyTimecardHourRec.Total_Hours__c single ***'+ weeklyTimecardHourRec.Total_Hours__c);
                System.debug('weeklyTimecardHourRec.Total_Approved_Hours__c single ***'+ weeklyTimecardHourRec.Total_Approved_Hours__c);
            }
            
            psaWeeklylist.add(weeklyTimecardHourRec);
        }
        
    }
    
    system.debug('psaWeeklylist ***:'+psaWeeklylist);
    if(!psaWeeklylist.isEmpty()){        
        upsert psaWeeklylist;   
    }
    
    
    public PSA_Weekly_User_Timecard_Hours__c createInstanceForWeeklyUserTimecardHours (PSA_Timecard_thresholds__e event)
    {
        PSA_Weekly_User_Timecard_Hours__c psaWeekly = new PSA_Weekly_User_Timecard_Hours__c ();
        psaWeekly.Resource__c = event.Resource__c;
        psaWeekly.Weekly_Start_Date__c = event.Weekly_Start_Date__c;
        psaWeekly.Weekly_End_Date__c = event.Weekly_End_Date__c; 
        psaWeekly.Total_Hours__c = event.Total_Hours__c==null?0:event.Total_Hours__c;
        psaWeekly.Total_Approved_Hours__c = event.Total_Approved_Hours__c==null?0:event.Total_Approved_Hours__c;   
        psaWeekly.Country__c  = event.Country__c;
        psaWeekly.Maximum_Hours_Threshold__c  = event.Maximum_Hours_Threshold__c;
        psaWeekly.Legal_Hours_Threshold__c  = event.Legal_Hours_Threshold__c;
        psaWeekly.Action__c = event.Action__c;
        if(event.Salesforce_Id__c != null)
        {
            psaWeekly.Id = event.Salesforce_Id__c;
        }
        System.debug('psaWeekly ***:: '+ psaWeekly);
        
        return psaWeekly;
    }
    
}