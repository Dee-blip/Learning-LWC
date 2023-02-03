public with sharing class LeadTriggerClass
{
    public static Boolean useContactInfoFirstRunFlag = true;
    public static Boolean sdrAssignmentHasRun=false;
    public static Boolean setBuyAkamaiFieldsHasRun = false;
    public static Boolean prepareAccoutsForRecomputationFirstRun = true;

    // SFDC-2417
    public static void setBuyAkamaiFields(Set<Lead> leadsRequiringBuyAkamaiFields) {
        if(setBuyAkamaiFieldsHasRun) {
            return;
        }
        Map<Id,Account> accIdAccountMap = getAccountIdvsAccountMap(leadsRequiringBuyAkamaiFields);
        Map <String,List<String>> mapOfReportingRegionvsOrderRegions = getMapOfReportingRegionvsOrderRegions();
        Map<String,String> salesApprovedCountryMapping = getSalesApprovedCountryMapping();

        for (Lead eachLead : leadsRequiringBuyAkamaiFields) {
            eachLead.Deal_Type__c = setDealType();
            eachLead.Order_Region__c = setOrderRegion(eachLead, accIdAccountMap, mapOfReportingRegionvsOrderRegions, salesApprovedCountryMapping);
            eachLead.CurrencyIsoCode = setCurrency(eachLead, accIdAccountMap);
        }
        setBuyAkamaiFieldsHasRun = true;
    }

    // SFDC-2417
    public static Map<Id,Account> getAccountIdvsAccountMap(Set<Lead> leadsRequiringBuyAkamaiFields) {
        List<Id> accIds = new List<Id>();
        for (Lead eachLead: leadsRequiringBuyAkamaiFields) {
            accIds.add(eachLead.Associated_Account__c);
        }
        List<Account> accountList = [Select Account_Status__c, BillingCountry, Finance_Region__c, Owner.DefaultCurrencyIsoCode From Account where id IN :accIds];
        Map<Id,Account> accIdAccountMap = new Map<Id,Account>();
        if (accountList.size() > 0) {
            for (Account acc:accountList) {
                accIdAccountMap.put(acc.id, acc);
            }
        }
        return accIdAccountMap;
    }

    // SFDC-2417
    public static Map<String,List<String>> getMapOfReportingRegionvsOrderRegions() {
        List<Order_Region_Reporting_Region_Mapping__c> mappingList = [Select Reporting_Region__c,
            Order_Region__c
                From Order_Region_Reporting_Region_Mapping__c];
        Map <String,List<String>> mapOfReportingRegionvsOrderRegions = new Map <String,List<String>>();
        if (mappingList.size() > 0) {
            //Create the Map for Account finance region and related opportunity region
            for (Order_Region_Reporting_Region_Mapping__c mapping:mappingList) {
                //Code-coverage
                if (mapOfReportingRegionvsOrderRegions.get(mapping.Reporting_Region__c.toUpperCase()) == null) {
                    List<String> orderRegionList = new List<String>();
                    orderRegionList.add(mapping.Order_Region__c);
                    mapOfReportingRegionvsOrderRegions.put(mapping.Reporting_Region__c.toUpperCase(), orderRegionList);
                } else {
                    //orderRegionList.add(mapping.Order_Region__c);
                    List<String> orderRegionList = mapOfReportingRegionvsOrderRegions.get(mapping.Reporting_Region__c.toUpperCase());
                    orderRegionList.add(mapping.Order_Region__c);
                    mapOfReportingRegionvsOrderRegions.put(mapping.Reporting_Region__c.toUpperCase(), orderRegionList);
                }
            }
        }
        return mapOfReportingRegionvsOrderRegions;
    }

    // SFDC-2417
    public static Map<String,String> getSalesApprovedCountryMapping() {
        List<Sales_Approved_Country__c> salesApprovedCountriesList = [Select Name, Order_Region__c
            From Sales_Approved_Country__c];
        Map<String,String> salesApprovedCountryMapping = new Map<String,String>();
        for (Sales_Approved_Country__c sac:salesApprovedCountriesList) {
            salesApprovedCountryMapping.put(sac.Name, sac.Order_Region__c);
        }
        return salesApprovedCountryMapping;
    }

    // SFDC-2417
    public static String setDealType() {
        return 'Direct';
    }

    // SFDC-2417
    public static String setOrderRegion(Lead singleLeadRecord, Map<Id,Account> accIdAccountMap, Map <String,List<String>> mapOfReportingRegionvsOrderRegions, Map<String,String> salesApprovedCountryMapping) {

        if(singleLeadRecord.Associated_Account__c == null) {
            return null;
        }

        String orderRegion;
        if(singleLeadRecord.Order_Region__c != null) {
            orderRegion = singleLeadRecord.Order_Region__c;
        }

        String accountStatus = accIdAccountMap.get(singleLeadRecord.Associated_Account__c).Account_Status__c;

        String country = accIdAccountMap.get(singleLeadRecord.Associated_Account__c).BillingCountry;
        String accFinanceRegion = accIdAccountMap.get(singleLeadRecord.Associated_Account__c).Finance_Region__c;
        // if (accFinanceRegion != null && accFinanceRegion != '' && accountStatus.endsWith('Active'))
        if (accFinanceRegion != null && accFinanceRegion != '') {
            accFinanceRegion = accFinanceRegion.toUpperCase();
            List<String> orderRegionListFromMapping = mapOfReportingRegionvsOrderRegions.get(accFinanceRegion);

            if (orderRegionListFromMapping != null && orderRegionListFromMapping.size() > 0) {
                orderRegion = orderRegionListFromMapping[0];
            }
            else {
                orderRegion = 'North America';
            }
        } else if(salesApprovedCountryMapping.size() > 0 && country != null && salesApprovedCountryMapping.get(country) != null) {
            orderRegion = salesApprovedCountryMapping.get(country);
        } else {
            orderRegion = 'North America';
        }

        return orderRegion;
    }

    // SFDC-2417
    public static String setCurrency(Lead l, Map<Id,Account> accIdAccountMap) {

        String currencyValue;
        if(l.CurrencyIsoCode != null) {
            currencyValue = l.CurrencyIsoCode;
        }

        if(accIdAccountMap.containsKey(l.Associated_Account__c) && accIdAccountMap.get(l.Associated_Account__c).Owner.DefaultCurrencyIsoCode != null) {
            currencyValue = accIdAccountMap.get(l.Associated_Account__c).Owner.DefaultCurrencyIsoCode;
        }
        return currencyValue;
    }


    public static void setConverted(List<Lead> akamaiLeads)
    {
        List<Lead> associatedParentRecords = new List<Lead>();
        for(Lead l : akamaiLeads) 
        {
            if(l.Associated_Contact__c == null && l.Parent_Lead__c != null) 
            {
                Lead parentLead = new Lead(Id=l.Parent_Lead__c);
                parentLead.Status = 'Converted';
                associatedParentRecords.add(parentLead);
            }
        }
        if(associatedParentRecords.size()>0)
            update associatedParentRecords;
    }


    //SFDC-2361
    public static void runLeadReassignmentRules(List<Lead> leadsToBeProcessed, Map<Id, Boolean> leadIdToForceRunMap)
    {       
        
        System.debug(LoggingLevel.Error, 'Mayank, inside try, leadsToBeProcessed entry '+leadsToBeProcessed);
        System.debug(LoggingLevel.Error, 'Mayank, inside try, leadIdToForceRunMap entry '+leadIdToForceRunMap);
        Set<Id> leadsForReassignmentOperation = new Set<Id>();
        Set<Id> leadsForForceReassignment = new Set<Id>();

        for(Lead eachLead : leadsToBeProcessed)
        {                
            if(leadIdToForceRunMap != null && leadIdToForceRunMap.get(eachLead.Id)  == true){
                leadsForForceReassignment.add(eachLead.Id);
            } else{
                leadsForReassignmentOperation.add(eachLead.Id);
            }
        }
        
        List<Lead> leadsWithoutSDRProfiles = new List<Lead>();
        if(leadsForForceReassignment.size() > 0){
            leadsWithoutSDRProfiles = [Select id, createdBy.ProfileId from Lead where id in :leadsForForceReassignment and ((status in ('New') and owner.type = 'User') OR (status in ('New', 'In Process') and owner.type = 'Queue')) and (recordType.Name like 'Akamai Lead')];
        } 

        if(leadsForReassignmentOperation.size() > 0){
            List<Lead> queriedLeads = [Select id, createdBy.ProfileId from Lead where id in :leadsForReassignmentOperation and ((NOT createdBy.Profile.Name like '%Sales Development Representative%') AND (NOT Owner.Profile.Name like '%Sales Development Representative%')) and status in ('New', 'In Process') and (recordType.Name like 'Akamai Lead')];
            leadsWithoutSDRProfiles.addAll(queriedLeads);
        }

        if(leadsWithoutSDRProfiles.size() > 0)
        {
            try
            {       
                System.debug(LoggingLevel.Error, 'AGH_D, inside try, leadsToBeProcessed: ' + leadsWithoutSDRProfiles.size());
                Database.DMLOptions dmo = new Database.DMLOptions();
                dmo.assignmentRuleHeader.useDefaultRule = true;
                Database.update(leadsWithoutSDRProfiles, dmo);
                System.debug(LoggingLevel.Error, 'AGH_D  leadsToBeProcessed: ' + leadsWithoutSDRProfiles.size());
            }
            catch(Exception e)
            {
                System.debug(LoggingLevel.Error, 'AGH_D in runLeadReassignmentRules caught exception: ' + e.getMessage());
                Error_log__c erroLog = new Error_log__c(Name = 'LeadTriggerClass', Class__c = 'LeadTriggerClass',Error_Message__c = e.getMessage()+'-'+e.getCause());
                insert erroLog;
            }
        }
        // runLeadReassignmentRulesFirstRunFlag=false;
    }
    //End of SFDC-2361


    //Rajul Vishwakarma
    //Start of SFDC-9138
    public static void prepareAccoutsForRecomputation(Boolean isInsert,Boolean isUpdate,Map<Id,SObject> oldLeadsMap,List<Lead> newLeads,List<Lead> oldLeads){
        if(!prepareAccoutsForRecomputationFirstRun){
            return;
        }
        Set<Id> uniqueAccountIds = new Set<Id>();
        if(isInsert){
            for(Lead l:newLeads){
                uniqueAccountIds.add(l.Associated_Account__c);
            }
        }
        else if(isUpdate){
            for(Lead newLead:newLeads){
                Lead oldLead = (Lead)oldLeadsMap.get(newLead.Id);
                if(newLead.Associated_Account__c != oldLead.Associated_Account__c){
                uniqueAccountIds.add(newLead.Associated_Account__c);
                uniqueAccountIds.add(oldLead.Associated_Account__c);
                }
                if(newLead.IsConverted != oldLead.IsConverted){
                    uniqueAccountIds.add(newLead.Associated_Account__c);
                }
            }
        }
        else {
            for(Lead l:oldLeads){
                uniqueAccountIds.add(l.Associated_Account__c);
            }
        }
        if(uniqueAccountIds.size()>0){
            L2Q_AccountTriggerClass.updateAndInsertAccountHelperObjects(uniqueAccountIds);
        }
        
        prepareAccoutsForRecomputationFirstRun = false;
    }
    //End of SFDC-9138
}