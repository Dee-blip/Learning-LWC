global class UpdateForecastedOpportunityCountBatch implements Database.Batchable<sObject>, Database.Stateful{
    final string query;
    id akamaiOpptyRecTypeId;
    //SFDC-3261
    String closedOpptyRecType;
    List<String> stageExclutionList;
    set<id> accIdSet;
    integer opptyUpdateCount;
    
    global UpdateForecastedOpportunityCountBatch(){
        opptyUpdateCount = 0;
        akamaiOpptyRecTypeId = GsmUtilClass.getGSMSettingValue('OpptyTrigger_AkamaiOpptyRecType');
        stageExclutionList = GsmUtilClass.getGSMSettingValue('UpdForecastOpptyCount_ExclusionStageList').split(',');
        accIdSet = new set<id>();
        //SFDC-3261
        closedOpptyRecType = GsmUtilClass.getGSMSettingValue('Closed_Opportunity_Rec_Type');
        string oppQuery = 'Select AccountId From Opportunity Where CloseDate >= LAST_N_MONTHS:' + Label.ForecastOpptyJobMonthLowerLimit.trim() + ' AND CloseDate <= NEXT_N_MONTHS:' + Label.ForecastOpptyJobMonthUpperLimit.trim() + ' AND (RecordTypeId =: akamaiOpptyRecTypeId OR RecordType.Name=:closedOpptyRecType) AND AccountId != null AND StageName NOT IN : stageExclutionList';
        for(Opportunity opp : Database.Query(oppQuery)){
            accIdSet.add(opp.AccountId);
        }
        query = 'Select Id From Account Where Id IN : accIdSet';
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope) {
        List<Opportunity> listOfOpportunitiesSinceLastMonth= new List<Opportunity>();
        List<Opportunity> listOfOpportunitiesToBeUpdated= new List<Opportunity>();
        Map<Id,Decimal> opptyIdToOldCount = new Map<Id,Decimal>();
        Map<Id,Map<Integer, Integer> > accountIdToNewOpptyCount = new Map<Id,Map<Integer, Integer>>();
        //SFDC-3261
        String queryToFilterForecastedOpptys = 'select Id, Name, AccountId, New_Oppty_Count__c, Forecast_Months__c, Opportunity_Type__c, ForecastCategoryName from Opportunity where CloseDate >=LAST_N_MONTHS:' + Label.ForecastOpptyJobMonthLowerLimit.trim() + ' AND CloseDate<= NEXT_N_MONTHS:' + Label.ForecastOpptyJobMonthUpperLimit.trim() + ' AND (RecordTypeId =: akamaiOpptyRecTypeId OR RecordType.Name=:closedOpptyRecType) AND AccountId IN : scope AND StageName NOT IN : stageExclutionList';
        try
        {
            listOfOpportunitiesSinceLastMonth = Database.query(queryToFilterForecastedOpptys);
        }
        catch(Exception e)
        {

        }
        
        try
        {
            if(listOfOpportunitiesSinceLastMonth.size()>0)
            {
                for(Opportunity oppty : listOfOpportunitiesSinceLastMonth)
                {
                    opptyIdToOldCount.put(oppty.Id, oppty.New_Oppty_Count__c);
                    if(accountIdToNewOpptyCount.get(oppty.AccountId)==null)
                    {
                        accountIdToNewOpptyCount.put(oppty.AccountId, new Map<Integer, Integer>());
                    }
                    Map<Integer, Integer> forecastMonthToCountMap = accountIdToNewOpptyCount.get(oppty.AccountId);
                    Integer forecastMonthForCurrentOppty = Integer.valueOf(oppty.Forecast_Months__c);
                    if((oppty.Opportunity_Type__c=='New Logo') && (oppty.ForecastCategoryName=='Commit' || oppty.ForecastCategoryName=='Closed'))
                    {
                        if(forecastMonthToCountMap.get(forecastMonthForCurrentOppty)==null)
                        {
                            forecastMonthToCountMap.put(forecastMonthForCurrentOppty, 1);
                        }
                        else
                        {
                            Integer currentCount = forecastMonthToCountMap.get(forecastMonthForCurrentOppty);
                            forecastMonthToCountMap.put(forecastMonthForCurrentOppty, currentCount+1);
                        }
                    }
                    accountIdToNewOpptyCount.put(oppty.AccountId, forecastMonthToCountMap);
                }
                
                for(Opportunity oppty : listOfOpportunitiesSinceLastMonth)
                {
                    if(accountIdToNewOpptyCount.get(oppty.AccountId)!=null)
                    {
                        if(accountIdToNewOpptyCount.get(oppty.AccountId).get(Integer.valueOf(oppty.Forecast_Months__c))!=null)
                        {
                            oppty.New_Oppty_Count__c = accountIdToNewOpptyCount.get(oppty.AccountId).get(Integer.valueOf(oppty.Forecast_Months__c));
                        }
                        else
                        {
                            oppty.New_Oppty_Count__c = 0;
                        }
                    }
                    else
                    {
                        oppty.New_Oppty_Count__c = 0;
                    }
                    oppty.Validation_Override__c = true;
                    if(oppty.Opportunity_Type__c!='New Logo')
                    {
                        oppty.New_Oppty_Count__c = 0;
                    }
                    if(oppty.ForecastCategoryName!='Commit' && oppty.ForecastCategoryName!='Closed')
                    {
                        oppty.New_Oppty_Count__c=0;
                    }
                    if((opptyIdToOldCount.get(oppty.Id)!=null) && oppty.New_Oppty_Count__c!=opptyIdToOldCount.get(oppty.Id))
                    {
                        listOfOpportunitiesToBeUpdated.add(oppty);
                    }
                }
                
                listOfOpportunitiesSinceLastMonth.clear(); 
                opptyIdToOldCount.clear();
                accountIdToNewOpptyCount.clear();
                
                DMLResults updateResults = new DMLResults();

                if(listOfOpportunitiesToBeUpdated.size()>0)
                {
                    opptyUpdateCount = opptyUpdateCount + listOfOpportunitiesToBeUpdated.size();
                    updateResults.add(Database.upsert(listOfOpportunitiesToBeUpdated,false),listOfOpportunitiesToBeUpdated);
                    updateResults.withClassName('UpdateForecastedOpportunityCountBatch').insertRecordsInErrorLog();
                }
            }
        }
        catch(Exception e)
        {
            
        }
    }
    
    global void finish(Database.BatchableContext BC) {
        AsyncApexJob jobDetails = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems FROM AsyncApexJob WHERE Id =: BC.getJobId()];
        string results = 'Status: '+jobDetails.Status+', Number Of Opportunities Updated: '+opptyUpdateCount+', Number Of Errors: '+jobDetails.NumberOfErrors;
        Util.updateCronRunWithResult('Update Forecasted Opportunity Count', results);
    }
}