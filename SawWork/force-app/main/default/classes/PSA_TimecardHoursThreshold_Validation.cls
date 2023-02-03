public with sharing class PSA_TimecardHoursThreshold_Validation {

    //Flags to avoid recursion
    public static boolean run = true;
    public static boolean upsertRun = true;

    //Map of country to country:MaximumThreshold:LegalThreshold
    public static Map<String,String> countryToHoursThresholdMap;

    public static Map<Id,String> resourceToHoursThresholdMap;
    public static Set<String> weeklyUserTimecardsKeySet;

    static{
        
        countryToHoursThresholdMap = new Map<String,String>();

        //Fetch all countries custom metadata 
        PSA_Common_Setting__mdt countriesMDT = [
            SELECT Value_Long__c
            FROM PSA_Common_Setting__mdt 
            WHERE Name__c = 'Country Timecard Hours Thresholds'
            limit 1
        ];

        if(countriesMDT != NULL && countriesMDT.Value_Long__c != NULL){
            for(String eachValue : countriesMDT.Value_Long__c.split(',')){
                countryToHoursThresholdMap.put(eachValue.split(':')[0],eachValue);
            }
        }
    }
    
    //Method to ensure the validation and calculation happens only once
    public static boolean runOnce()
    {
        if(run){
            run = false;
            return true;
        }
        else{
            return run;
        }
    }
    
    //Method to ensure the upsert of auto approval tcs happens only once
    public static boolean upsertOnce()
    {
        if(upsertRun){
            upsertRun = false;
            return true;
        }
        else{
            return upsertRun;
        }
    }

    //Helper Methods

    //Create an instance of record createInstanceForWeeklyUserTimecardHours
    public static PSA_Weekly_User_Timecard_Hours__c createInstanceForWeeklyUserTimecardHours (pse__Timecard_Header__c timecard)
    {
        PSA_Weekly_User_Timecard_Hours__c tempWeeklyUserRecord  = new PSA_Weekly_User_Timecard_Hours__c();
        tempWeeklyUserRecord.Resource__c = timecard.pse__Resource__c;
        tempWeeklyUserRecord.Weekly_Start_Date__c = timecard.pse__Start_Date__c;
        tempWeeklyUserRecord.Weekly_End_Date__c = timecard.pse__End_Date__c; 
        tempWeeklyUserRecord.Total_Hours__c = 0;
        tempWeeklyUserRecord.Total_Approved_Hours__c = 0;   
        tempWeeklyUserRecord.Country__c  = resourceToHoursThresholdMap.get(timecard.pse__Resource__c).split(':')[0];
        tempWeeklyUserRecord.Maximum_Hours_Threshold__c  = Decimal.valueOf(resourceToHoursThresholdMap.get(timecard.pse__Resource__c).split(':')[1]);
        tempWeeklyUserRecord.Legal_Hours_Threshold__c  = Decimal.valueOf(resourceToHoursThresholdMap.get(timecard.pse__Resource__c).split(':')[2]);
        tempWeeklyUserRecord.Action__c = timecard.pse__Status__c;

        return tempWeeklyUserRecord;
    }

    //Method to filter timecards with resources country valid for thresholding
    public static List<pse__Timecard_Header__c> getValidTimecardsForThresholdCheck(List<pse__Timecard_Header__c> timecards, Map<Id,pse__Timecard_Header__c> oldTimecardsMap)
    {
        //List to store Filtered timecards included for the thresholding
        List<pse__Timecard_Header__c> newTimecards = new List<pse__Timecard_Header__c>();

        resourceToHoursThresholdMap = new Map<Id,String>();
        weeklyUserTimecardsKeySet = new Set<String>();
        
        for(pse__Timecard_Header__c timecard : timecards){
            //Validate if the user if of desired country and timecards are submitted, approved, rejected or recalled only        
            if(countryToHoursThresholdMap.containsKey(timecard.Resource_Country__c) && (timecard.pse__Status__c == 'Approved' || timecard.pse__Status__c == 'Submitted' || timecard.pse__Status__c == 'Rejected' || ( timecard.pse__Status__c == 'Saved' && oldTimecardsMap != NULL && oldTimecardsMap.containsKey(timecard.Id) && oldTimecardsMap.get(timecard.Id).pse__Status__c == 'Submitted'))){
                newTimecards.add(timecard);

                resourceToHoursThresholdMap.put(timecard.pse__Resource__c,countryToHoursThresholdMap.get(timecard.Resource_Country__c));
                weeklyUserTimecardsKeySet.add(timecard.Weekly_User_Timecards_Key__c);
            }
        }
        System.debug('newTimecards***:'+newTimecards);
        return newTimecards;
    }

    //Method to Aggregate the Total_Hours__c and Total_Approved_Hours__c of the new timecards
    public static Map<String,PSA_Weekly_User_Timecard_Hours__c> groupNewTimecards(List<pse__Timecard_Header__c> newTimecards)
    {
                
        Map<String,PSA_Weekly_User_Timecard_Hours__c> weeklyUserTimecardHoursMap = new Map<String,PSA_Weekly_User_Timecard_Hours__c>();
        PSA_Weekly_User_Timecard_Hours__c tempWeeklyUserRecord;
        
        for(pse__Timecard_Header__c timecard:newTimecards)
        {             
            if(weeklyUserTimecardHoursMap == null || !weeklyUserTimecardHoursMap.containsKey(timecard.Weekly_User_Timecards_Key__c)){
                tempWeeklyUserRecord = createInstanceForWeeklyUserTimecardHours(timecard);
            }
            else{
                tempWeeklyUserRecord = weeklyUserTimecardHoursMap.get(timecard.Weekly_User_Timecards_Key__c);
            }

            //If timecard is Approved, add timecards Hours to the Total_Approved_Hours__c 
            if(timecard.pse__Status__c == 'Approved'){
                tempWeeklyUserRecord.Total_Approved_Hours__c = tempWeeklyUserRecord.Total_Approved_Hours__c + timecard.pse__Total_Hours__c;                
            }
            //If timecard is Submitted, add timecards Hours to the Total_Hours__c 
            else if(timecard.pse__Status__c == 'Submitted'){
                if(timecard.Is_Auto_Approvable__c){
                    tempWeeklyUserRecord.Action__c = 'Auto Approved';
                    tempWeeklyUserRecord.Total_Approved_Hours__c = tempWeeklyUserRecord.Total_Approved_Hours__c + timecard.pse__Total_Hours__c;
                }                
                tempWeeklyUserRecord.Total_Hours__c = tempWeeklyUserRecord.Total_Hours__c + timecard.pse__Total_Hours__c;
            }
            //If timecard is rejected or recalled, substract timecards Hours from Total_Hours__c 
            else{         
                tempWeeklyUserRecord.Total_Hours__c = tempWeeklyUserRecord.Total_Hours__c - timecard.pse__Total_Hours__c;
            }


            weeklyUserTimecardHoursMap.put(timecard.Weekly_User_Timecards_Key__c,tempWeeklyUserRecord);
                    
        }
        
        return weeklyUserTimecardHoursMap;
    }

    //Query the junction object records for 
    // 1. Checking thresholds in before trigger
    // 2. Setting saleforce Id on weeklyUserTimecardHoursMap fro upsert in After trigger context
    public static Map<String,PSA_Weekly_User_Timecard_Hours__c> getQueriedWeeklyTimecardHoursMap(Set<String> keySet)
    {
        Map<String,PSA_Weekly_User_Timecard_Hours__c> queriedWeeklyUserTimecardHoursMap = new Map<String,PSA_Weekly_User_Timecard_Hours__c>();
        for(PSA_Weekly_User_Timecard_Hours__c weeklyHourRecord : [
            SELECT Id, Resource__c , Weekly_Start_Date__c , Weekly_End_Date__c , Maximum_Hours_Threshold__c, Legal_Hours_Threshold__c, Total_Approved_Hours__c ,Total_Hours__c , Weekly_User_Timecards_Key__c
            FROM PSA_Weekly_User_Timecard_Hours__c
            WHERE Weekly_User_Timecards_Key__c in :keySet
        ]){
            queriedWeeklyUserTimecardHoursMap.put(weeklyHourRecord.Weekly_User_Timecards_Key__c,weeklyHourRecord);
        }

        return queriedWeeklyUserTimecardHoursMap;
    }

    //Method to add aggregated new Timecard Hours with Queried Junction object hours
    public static Map<String,PSA_Weekly_User_Timecard_Hours__c> aggregatedGroupedTimecardsWithQueriedRecords(Map<String,PSA_Weekly_User_Timecard_Hours__c> weeklyUserTimecardHoursMap, Map<String,PSA_Weekly_User_Timecard_Hours__c> queriedWeeklyUserTimecardHoursMap)
    {
        for(String key : weeklyUserTimecardHoursMap.keySet())
        {
            if(queriedWeeklyUserTimecardHoursMap.containsKey(key)){
                weeklyUserTimecardHoursMap.get(key).Total_Hours__c += queriedWeeklyUserTimecardHoursMap.get(key).Total_Hours__c;
            }
        }
        return weeklyUserTimecardHoursMap;
    }

    public static Map<String,PSA_Weekly_User_Timecard_Hours__c> setSalesforceIdForUpsertOnWeeklyUserTimecardHoursMap(Map<String,PSA_Weekly_User_Timecard_Hours__c> weeklyUserTimecardHoursMap, Map<String,PSA_Weekly_User_Timecard_Hours__c> queriedWeeklyUserTimecardHoursMap)
    {
        for(String key : weeklyUserTimecardHoursMap.keySet())
        {
            if(queriedWeeklyUserTimecardHoursMap.containsKey(key)){
                weeklyUserTimecardHoursMap.get(key).Id = queriedWeeklyUserTimecardHoursMap.get(key).Id;
            }
        }
        return weeklyUserTimecardHoursMap;
    }

    /*
     * Method to use weeklyUserTimecardHoursMap, check thresholds on timecards and perform action accordingly. 
     * Additionally create emails to send on crossing Max Threshold.  
     * Additionally, we also stmp the country, Maximum threshold and Legal Threshold on the weeklyUserTimecardHoursMap
    */
    public static void checkThresholds(List<pse__Timecard_Header__c> newTimecards,Map<String,PSA_Weekly_User_Timecard_Hours__c> weeklyUserTimecardHoursMap)
    {
        PSA_Weekly_User_Timecard_Hours__c tempWeeklyUserRecord = new PSA_Weekly_User_Timecard_Hours__c();        
        
        for(pse__Timecard_Header__c timecard:newTimecards)
        {
            tempWeeklyUserRecord = new PSA_Weekly_User_Timecard_Hours__c();
            
            //If the country of the resource is valid for thresholding, fetch the resourceToHoursThresholdMap
            if(resourceToHoursThresholdMap.containsKey(timecard.pse__Resource__c) && weeklyUserTimecardHoursMap.containsKey(timecard.Weekly_User_Timecards_Key__c)){
                                
                tempWeeklyUserRecord  = weeklyUserTimecardHoursMap.get(timecard.Weekly_User_Timecards_Key__c);
                //If the total hours exceeds the Legal Threshold, stop and throw an error
                if(tempWeeklyUserRecord.Total_Hours__c > tempWeeklyUserRecord.Legal_Hours_Threshold__c || tempWeeklyUserRecord.Total_Approved_Hours__c > tempWeeklyUserRecord.Legal_Hours_Threshold__c){
                    sObject obj = tempWeeklyUserRecord;
                    String label = System.Label.PSA_Legal_Threshold_Error_Message;
                    String msg = PSA_AutoCreateProjectUtil.getCustomizedLabelMessage('PSA_Weekly_User_Timecard_Hours__c',label,obj,null);
                    timecard.addError(msg);
                }                    
                 
            }
        }
    }
    
    //Filter timecards with valid resources country
    public static void validateTotalHoursWithThresholds(List<pse__Timecard_Header__c> newTimecards, Map<Id,pse__Timecard_Header__c> oldTimecardsMap)
    {
        if(runOnce())
        {
            
            //Check if timecards resources country is valid for thresholding, and if it is submitted, rejected, recalled or approved
            newTimecards = getValidTimecardsForThresholdCheck(newTimecards,oldTimecardsMap);

            if(newTimecards != NULL && newTimecards.size() > 0)
            {                                  
                //Aggregate the Total_Hours__c and Total_Approved_Hours__c of the new timecards          
                Map<String,PSA_Weekly_User_Timecard_Hours__c> weeklyUserTimecardHoursMap =  groupNewTimecards(newTimecards);    
                
                Map<String,PSA_Weekly_User_Timecard_Hours__c> queriedWeeklyUserTimecardHoursMap = getQueriedWeeklyTimecardHoursMap(weeklyUserTimecardHoursMap.keySet());

                //Sum up aggreate records with queried junction object records fro before trigger validation
                weeklyUserTimecardHoursMap = aggregatedGroupedTimecardsWithQueriedRecords(weeklyUserTimecardHoursMap,queriedWeeklyUserTimecardHoursMap); 

                //Using weeklyUserTimecardHoursMap, check thresholds on timecards and perform action accordingly. Additionally create emails to send on crossing Max Threshold.  
                checkThresholds(newTimecards,weeklyUserTimecardHoursMap);

            }
        }
    }

    //Method called on after trigger to upsert weeklyUserTimecardHoursMap values and send emails from emailsToSend
    public static void upsertweeklyUserTimecardHours(List<pse__Timecard_Header__c> newTimecards, Map<Id,pse__Timecard_Header__c> oldTimecardsMap)
    {
        if(upsertOnce() == true)
        {

            //Check if timecards resources country is valid for thresholding, and if it is submitted, rejected, recalled or approved
            newTimecards = getValidTimecardsForThresholdCheck(newTimecards,oldTimecardsMap);

            if(newTimecards != NULL && newTimecards.size() > 0)
            {                                  
                //Aggregate the Total_Hours__c and Total_Approved_Hours__c of the new timecards          
                Map<String,PSA_Weekly_User_Timecard_Hours__c> weeklyUserTimecardHoursMap =  groupNewTimecards(newTimecards);    
                
                Map<String,PSA_Weekly_User_Timecard_Hours__c> queriedWeeklyUserTimecardHoursMap = getQueriedWeeklyTimecardHoursMap(weeklyUserTimecardHoursMap.keySet());

                //Sum up aggreate records with queried junction object records fro before trigger validation
                weeklyUserTimecardHoursMap = setSalesforceIdForUpsertOnWeeklyUserTimecardHoursMap(weeklyUserTimecardHoursMap,queriedWeeklyUserTimecardHoursMap); 
                if(weeklyUserTimecardHoursMap != NULL && weeklyUserTimecardHoursMap.size() > 0){
                    createEvents(weeklyUserTimecardHoursMap.values());
                }

            }
        }
    }

    public static void createEvents(List<PSA_Weekly_User_Timecard_Hours__c> weeklyUserTimecardHoursList)
    {
        //Creata an Event to call upsert on the PSA_Weekly_User_Timecard_Hours__c object
        List<PSA_Timecard_thresholds__e> eventList = new List<PSA_Timecard_thresholds__e>();
                    
        for(PSA_Weekly_User_Timecard_Hours__c weeklyhours : weeklyUserTimecardHoursList)
        {                                            
            PSA_Timecard_thresholds__e event = new PSA_Timecard_thresholds__e();
            event.Resource__c = weeklyhours.Resource__c;
            event.Weekly_Start_Date__c = weeklyhours.Weekly_Start_Date__c;
            event.Weekly_End_Date__c = weeklyhours.Weekly_End_Date__c; 

            if (weeklyhours.Action__c == 'Approved'){
                event.Total_Approved_Hours__c = weeklyhours.Total_Approved_Hours__c;
            } 
            else if(weeklyhours.Action__c == 'Auto Approved'){
                event.Total_Approved_Hours__c = weeklyhours.Total_Approved_Hours__c;
                event.Total_Hours__c = weeklyhours.Total_Hours__c;        
            }
            else{
                event.Total_Hours__c = weeklyhours.Total_Hours__c;        
            }

            event.Country__c  = weeklyhours.Country__c;
            event.Maximum_Hours_Threshold__c  = weeklyhours.Maximum_Hours_Threshold__c;
            event.Legal_Hours_Threshold__c  = weeklyhours.Legal_Hours_Threshold__c;
            event.Action__c = weeklyhours.Action__c;
            
            if(weeklyhours.Id != null){
                event.Salesforce_Id__c = weeklyhours.Id;
            }

            eventList.add(event);                
        }

        List<Database.SaveResult> sresult = EventBus.publish(eventList);
        for (Database.SaveResult sr : sresult) 
        {
            if(sr.isSuccess()){
                System.debug('Successfully published event.');  
            }
            else {
                for(Database.Error err : sr.getErrors()) {
                    System.debug('Error returned: ' +err.getStatusCode() +' - ' +err.getMessage());
                }
            }
        } 
    }


    /* Method to generate lightning component on single timecard record page
     * Calculated the sum of timecard hours with aggregated Approved hours for the user week
     * If the sum is above threshold and the timecard has been submitted, the lighting component message is shown
     * Input: timecardId, Output: String(MaximLimit) if threshold met, otherwise ''.
    */
    @AuraEnabled(cacheable=true)
    public static String checktoNotifyTimecardHoursConsumed(String recordId){
        Id usrId = UserInfo.getUserId();
        
        //Query the data of the timecard
        pse__Timecard_Header__c timecard = [
            SELECT 
                Id, pse__Resource__c, pse__Start_Date__c, pse__End_Date__c, pse__Status__c, pse__Total_Hours__c, Weekly_User_Timecards_Key__c
            FROM 
                pse__Timecard_Header__c
            WHERE 
                Id =: recordId
        ];
        
        //If the timecard is submitted and is awaiting approval
        if(timecard.pse__Status__c == 'Submitted')
        {
            //Query the aggregated Total_Approved_Hours__c and Maximum_Hours_Threshold__c of the timecards corresponding week.
            PSA_Weekly_User_Timecard_Hours__c weeklyUserTimecardHour = [
                SELECT 
                    Id, Resource__c , Weekly_Start_Date__c , Weekly_End_Date__c , Maximum_Hours_Threshold__c, Legal_Hours_Threshold__c, Total_Approved_Hours__c ,Total_Hours__c , Weekly_User_Timecards_Key__c
                FROM
                    PSA_Weekly_User_Timecard_Hours__c
                WHERE
                    Weekly_User_Timecards_Key__c = :timecard.Weekly_User_Timecards_Key__c
            ];
            
            //Calculate sum as timecard hours and Total_Approved_Hours__c. Check if the sum is greater than Maximum_Hours_Threshold__c. if yes, return true.
            if( (weeklyUserTimecardHour.Total_Approved_Hours__c + timecard.pse__Total_Hours__c) >= weeklyUserTimecardHour.Maximum_Hours_Threshold__c){
                return 'MaximLimit';
            }
        }
        return '';           
    }
}