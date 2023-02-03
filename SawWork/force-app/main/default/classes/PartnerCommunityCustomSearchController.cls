public class PartnerCommunityCustomSearchController {
    
    @AuraEnabled
    public static String searchForRecords(String searchText) {
        //List<List<SObject>> results = [FIND :searchText IN ALL FIELDS  RETURNING Account(Id), Contact(Id), Lead(Id)];
        List<String> objectsList = PartnerCommunityNavigationController.getCommunityObject();
        System.debug('Community Objects : '+objectsList);
        //String searchQuery = getSearchStringForObject(objectsList,searchText);
        /*for (String s:objectList) {
            searchQuery += s+'(Id),';
        }
        searchQuery = searchQuery.removeEnd(',');*/ 
        
        //System.debug('searchQuery :'+searchQuery);
        //String searchquery='FIND\'Edge*\'IN ALL FIELDS RETURNING Account(Id),Contact, Lead'; 
        List<List<SObject>> searchList = getSearchResults(objectsList,searchText);
        
        String resultObj = JSON.serialize(searchList);
        System.debug('resultObj :'+resultObj);
        
        /*List<String> ids = new List<String>();
        for (List<SObject> sobjs : searchList) {
          for (SObject sobj : sobjs) {
            ids.add(sobj.Id);
          }
        }
        return ids;*/
        return resultObj;
    }
    
    public static List<List<SObject>> getSearchResults(List<String> sObjectAPINameList,String searchText) {
        
        String AccountId = CurrentUser.attributes.get('Partner Account');
        List<Account> accountsInHierarchy = GsmUtilClass.getAccCompleteHierarchy(AccountId,'Down');
        
        Set<Id> setOfAccountIds     = new Set<Id>();
        String soslQuery;
        
        for(Account acc : accountsInHierarchy)
            setOfAccountIds.add(acc.Id);
        
        Map<String,String> mapOfObjectToFields = getMapOfObjectToFields();
        System.debug('mapOfObjectToFields' + mapOfObjectToFields);
        
        soslQuery = 'FIND #SEARCHTERM# IN ALL Fields RETURNING ';
        
        Set<Id> setOfOpportunityIds = new Set<Id>();
        Set<Id> setOfLeadIds = new Set<Id>();
        Set<Id> setOfFundBudgetIds = new Set<Id>();
        Set<Id> setOfFundRequestIds = new Set<Id>();
        Set<Id> setOfFundClaimIds   = new Set<Id>();
        Set<Id> setOfCaseIds   = new Set<Id>();
        Set<Id> setOfContactIds = new Set<Id>();
        Set<Id> setOfPartnerPlanIds = new Set<Id>();
        Set<Id> setOfRebatePayoutIds    = new Set<Id>();
        Set<Id> setPOCIds   = new Set<Id>();
        Set<Id> setOfPartnerProfileIds  = new Set<Id>();
        Set<Id> setOfPMAIds = new Set<Id>();
        Set<Id> setOfPMPIds = new Set<Id>();
        Set<Id> setOfQuotesIds = new Set<Id>();
        
        for (String s:sObjectAPINameList) {
            if (s=='Opportunity') {
                setOfOpportunityIds = getOpportunities(setOfAccountIds);
                soslQuery += 'Opportunity(' +mapOfObjectToFields.get('Opportunity')+ ' WHERE Id IN : setOfOpportunityIds LIMIT 50),';
            }
            if (s=='Lead') {
                setOfLeadIds = getLeads(setOfAccountIds);
                soslQuery += 'Lead(' +mapOfObjectToFields.get('Lead')+ ' WHERE Id IN: setOfLeadIds LIMIT 100),';
            }
            if (s=='SFDC_Budget__c') {
                setOfFundBudgetIds = getFundBudgets(setOfAccountIds);
                soslQuery += 'SFDC_Budget__c(' +mapOfObjectToFields.get('Fund Budget')+ ' WHERE Id IN: setOfFundBudgetIds LIMIT 100),';
            }
            if (s=='SFDC_MDF__c') {
                setOfFundRequestIds = getFundRequests(setOfAccountIds);
                soslQuery += 'SFDC_MDF__c(' +mapOfObjectToFields.get('Fund Request')+ ' WHERE Id IN :setOfFundRequestIds LIMIT 100),';
            }
            if (s=='SFDC_MDF_Claim__c') {
                setOfFundClaimIds   = getFundClaims(setOfAccountIds);
                soslQuery += 'SFDC_MDF_Claim__c(' +mapOfObjectToFields.get('Fund Claim')+ ' WHERE Id IN: setOfFundClaimIds LIMIT 100),';
            }
            if (s=='Case') {
                setOfCaseIds = getCases(setOfAccountIds);
                soslQuery += 'Case(' +mapOfObjectToFields.get('Case')+ ' WHERE Id IN: setOfCaseIds LIMIT 100),';
            }
            if (s=='Contact') {
                setOfContactIds = getContacts(setOfAccountIds);
                soslQuery += 'Contact(' + mapOfObjectToFields.get('Contact') +' WHERE Id IN : setOfContactIds LIMIT 100),';
            }
            if (s=='SFDC_Channel_Account_Plan__c') {
                setOfPartnerPlanIds = getPartnerPlans(setOfAccountIds);
                soslQuery += 'SFDC_Channel_Account_Plan__c(' + mapOfObjectToFields.get('Partner Plan') +' WHERE Id IN : setOfPartnerPlanIds LIMIT 100),';
            }
            if (s=='Rebate_Payout__c') {
                setOfRebatePayoutIds = getRebatePayouts(setOfAccountIds);
                soslQuery += 'Rebate_Payout__c(' + mapOfObjectToFields.get('Rebate Payout') +' WHERE Id IN : setOfRebatePayoutIds LIMIT 100),';
            }
            if (s=='Partner_Order_Cancellation_Details__c') {
                setPOCIds = getPOCs(setOfAccountIds);
                soslQuery += 'Partner_Order_Cancellation_Details__c(' + mapOfObjectToFields.get('Partner Order Cancellation Details') +' WHERE Id IN : setPOCIds LIMIT 100),';
            }
            if (s=='Partner_Profile__c') {
                setOfPartnerProfileIds  = getPartnerProfiles(setOfAccountIds);
                soslQuery += 'Partner_Profile__c(' + mapOfObjectToFields.get('Partner Profile') +' WHERE Id IN : setOfPartnerProfileIds LIMIT 100),';
            }
            if (s=='Partner_Marketing_Activity__c') {
                setOfPMAIds = getPMAs(setOfAccountIds);
                soslQuery += 'Partner_Marketing_Activity__c(' + mapOfObjectToFields.get('Partner MDF Activity') +' WHERE Id IN : setOfPMAIds LIMIT 100),';
            }
            if (s=='Partner_Marketing_Plan__c') {
                setOfPMPIds = getPMPs(setOfAccountIds);
                soslQuery += 'Partner_Marketing_Plan__c(' + mapOfObjectToFields.get('Partner MDF Plan') +' WHERE Id IN : setOfPMPIds LIMIT 100),';
            }
            if (s=='SBQQ__Quote__c') {
                setOfQuotesIds = getQuotes(setOfAccountIds);
                soslQuery += 'SBQQ__Quote__c(' + mapOfObjectToFields.get('Quote') +' WHERE Id IN : setOfQuotesIds LIMIT 100),';
            }
        }
        soslQuery = soslQuery.removeEnd(',');
        soslQuery = soslQuery.replace('#SEARCHTERM#' , '\''+ String.escapeSingleQuotes('*' + searchText + '*')+'\'');
        System.debug('soslQuery :'+soslQuery);
        List<List<SObject>> searchList = search.query(soslQuery);
        System.debug('Search List :'+searchList);
        return searchList;
    }
    
    /*public  static List<List<SObject>> search(String searchTerm)
    {

        String AccountId = CurrentUser.attributes.get('Partner Account');
        List<Account> accountsInHierarchy = GsmUtilClass.getAccCompleteHierarchy(AccountId,'Down');
        List<List<SObject>> searchList = new List<List<SObject>>();
        
        if(accountsInHierarchy.size()>0)
        {
            

            Set<Id> setOfAccountIds     = new Set<Id>();
            Set<Id> setOfContactIds     = new Set<Id>();
            Set<Id> setOfOpportunityIds = new Set<Id>();
            Set<Id> setOfFundRequestIds = new Set<Id>();
            Set<Id> setOfFundClaimIds   = new Set<Id>();
            String soslQuery;

            for(Account acc : accountsInHierarchy)
                setOfAccountIds.add(acc.Id);

            setOfContactIds     = getContacts(setOfAccountIds);
            setOfOpportunityIds = getOpportunities(setOfAccountIds);
            setOfFundRequestIds = getFundRequests(setOfAccountIds);
            setOfFundClaimIds   = getFundClaims(setOfAccountIds);

            Map<String,String> mapOfObjectToFields = getMapOfObjectToFields();
            System.debug('mapOfObjectToFields' + mapOfObjectToFields);

            soslQuery = 'FIND #SEARCHTERM# IN ALL Fields RETURNING ' + 
                         'Contact(' + mapOfObjectToFields.get('Contact') +' where Id IN : setOfContactIds LIMIT 100),'+
                         'Opportunity(' +mapOfObjectToFields.get('Opportunity')+ ' where Id IN : setOfOpportunityIds LIMIT 50),'+
                         'SFDC_MDF__c(' +mapOfObjectToFields.get('Fund Request')+ ' where Id IN :setOfFundRequestIds LIMIT 100),'+
                         'SFDC_MDF_Claim__c(' +mapOfObjectToFields.get('Fund Claim')+ ' where Id IN: setOfFundClaimIds LIMIT 100)' ;
            soslQuery = soslQuery.replace('#SEARCHTERM#' , '\''+ String.escapeSingleQuotes('*' + searchTerm + '*')+'\'');

            System.debug('soslQuery:' +soslQuery);

            searchList = search.query(soslQuery);

            /*if(setOfOpportunityIds.size()>0)
                getOpportunitiesWithSOQL(searchTerm,setOfOpportunityIds);

            getPartnerOrderAcceptances();*/
        //}
        //return searchList;
    //}

    /*private static void getOpportunitiesWithSOQL(String searchTerm,Set<Id> setOfOpportunityIds )
    {

            Set<Id> setOfOpptyIdsToExclude = new Set<Id>();

            for(Opportunity oppty : (List<Opportunity>)searchList[1])
            {
                setOfOpptyIdsToExclude.add(oppty.Id);
            }

            //String query = 'Select '+ mapOfObjectToFields.get('Opportunity')+  ' from Opportunity where Id IN:setOfOpportunityIds AND Account.Name LIKE \'%' + searchTerm +'%\' and Id NOT IN: setOfOpptyIdsToExclude LIMIT 50';
            System.debug('query' + query);
            List<SObject> temporaryList = Database.query(query);
            System.debug('temporaryList' + temporaryList);
            if(temporaryList.size()>0)
                searchList[1].addAll(temporaryList);            

    }*/
    
    /*private static void getPartnerOrderAcceptances()
    {
        List<Partner_Order_Acceptance_Document__c> listOfPOA ;
         
        if(Schema.sObjectType.Partner_Order_Acceptance_Document__c.isAccessible())
        {
            if(searchList[1].size()>0)
            {
                Set<Id> setOfResultOpptyIds = new Set<Id>();

                for(SObject oppty : searchList[1])
                    setOfResultOpptyIds.add(oppty.Id);

                String poaQuery = 'Select ' + mapOfObjectToFields.get('Partner Order Acceptance') + ' from Partner_Order_Acceptance_Document__c where Opportunity__c IN :setOfResultOpptyIds LIMIT 100';
                 listOfPOA = Database.query(poaQuery);

            }
        }
        if(listOfPOA!=null)
            searchList.add(listOfPOA);
        else
            searchList.add(new List<sobject>());

    }*/

    public  static Set<Id> getContacts(Set<Id> setOfAccountIds) {
        Set<Id> setOfContactIds = new Set<Id>();
        if(Schema.sObjectType.Contact.isAccessible()) {
        for(Contact contactObj : [Select Id from Contact where AccountId IN :setOfAccountIds])
            setOfContactIds.add(contactObj.Id);
        }
        return setOfContactIds;
    }

    public static Set<Id> getLeads(Set<Id> setOfAccountIds) {
        Set<Id> setOfLeadIds = new Set<Id>();
        if(Schema.sObjectType.Lead.isAccessible()) {
        for(Lead leadObj : [Select Id from Lead where Partner_Involved__c IN :setOfAccountIds])
            setOfLeadIds.add(leadObj.Id);
        }
        return setOfLeadIds;
    }
        
    public static Set<Id> getFundBudgets(Set<Id> setOfAccountIds) {
        Set<Id> setOfFBIds = new Set<Id>();
        if(Schema.sObjectType.SFDC_Budget__c.isAccessible()) {
        for(SFDC_Budget__c  fbObj : [Select Id from SFDC_Budget__c  where Account__c  IN :setOfAccountIds])
            setOfFBIds.add(fbObj.Id);
        }
        return setOfFBIds;
    }
    
    public static Set<Id> getCases(Set<Id> setOfAccountIds) {
        Set<Id> setOfCaseIds = new Set<Id>();
        if(Schema.sObjectType.Case.isAccessible()) {
        for(Case caseObj : [Select Id from Case where Partner_Account__c IN :setOfAccountIds])
            setOfCaseIds.add(caseObj.Id);
        }
        return setOfCaseIds;
    }
    
    public static Set<Id> getOpportunities(Set<Id> setOfAccountIds) {
        Set<Id> setOfOpportunityIds = new Set<Id>();
        if(Schema.sObjectType.Opportunity.isAccessible()) {
            for(Opportunity opptyObj : [Select Name,Id from Opportunity where Partner_Involved__c IN :setOfAccountIds]){
                setOfOpportunityIds.add(opptyObj.Id);
            }
        }
        return setOfOpportunityIds;
    }

    public static Set<Id> getFundRequests(Set<Id> setOfAccountIds) {
        Set<Id> setOfFundRequestIds = new Set<Id>();
        if(Schema.sObjectType.SFDC_MDF__c.isAccessible()) {
            for(SFDC_MDF__c fundrequestObj : [Select Id from SFDC_MDF__c where Account__c IN :setOfAccountIds])
                setOfFundRequestIds.add(fundrequestObj.Id);
        }
        return setOfFundRequestIds;
    }

    public static Set<Id> getFundClaims(Set<Id> setOfAccountIds) {
        Set<Id> setOfFundClaimIds = new Set<Id>();
        if(Schema.sObjectType.SFDC_MDF_Claim__c.isAccessible()){
            for(SFDC_MDF_Claim__c fundClaimObj : [Select Id from SFDC_MDF_Claim__c where Account__c IN :setOfAccountIds])
                setOfFundClaimIds.add(fundClaimObj.Id);
        }
        return setOfFundClaimIds;
    }
    
    public static Set<Id> getPartnerPlans(Set<Id> setOfAccountIds) {
        Set<Id> setOfPartnerPlanIds = new Set<Id>();
        if(Schema.sObjectType.SFDC_Channel_Account_Plan__c.isAccessible()){
            for(SFDC_Channel_Account_Plan__c ppObj : [Select Id from SFDC_Channel_Account_Plan__c where Partner_Account__c IN :setOfAccountIds])
                setOfPartnerPlanIds.add(ppObj.Id);
        }
        return setOfPartnerPlanIds;
    }
    
    public static Set<Id> getRebatePayouts(Set<Id> setOfAccountIds) {
        Set<Id> setOfRebatePayoutIds = new Set<Id>();
        if(Schema.sObjectType.Rebate_Payout__c.isAccessible()){
            for(Rebate_Payout__c ppObj : [Select Id from Rebate_Payout__c where Associated_Partner__c IN :setOfAccountIds])
                setOfRebatePayoutIds.add(ppObj.Id);
        }
        return setOfRebatePayoutIds;
    }
    
    public static Set<Id> getPOCs(Set<Id> setOfAccountIds) {
        Set<Id> setOfPOCIds = new Set<Id>();
        if(Schema.sObjectType.Partner_Order_Cancellation_Details__c.isAccessible()){
            for(Partner_Order_Cancellation_Details__c pocObj : [Select Id from Partner_Order_Cancellation_Details__c where Reseller_Account__c IN :setOfAccountIds])
                setOfPOCIds.add(pocObj.Id);
        }
        return setOfPOCIds;
    }
    
    public static Set<Id> getPartnerProfiles(Set<Id> setOfAccountIds) {
        Set<Id> setOfPPIds = new Set<Id>();
        if(Schema.sObjectType.Partner_Profile__c.isAccessible()){
            for(Partner_Profile__c ppObj : [Select Id from Partner_Profile__c where Partner_Account_Name__c IN :setOfAccountIds])
                setOfPPIds.add(ppObj.Id);
        }
        return setOfPPIds;
    }
    
    public static Set<Id> getPMAs(Set<Id> setOfAccountIds) {
        Set<Id> setOfPMAIds = new Set<Id>();
        if(Schema.sObjectType.Partner_Marketing_Activity__c.isAccessible()){
            for(Partner_Marketing_Activity__c pmaObj : [Select Id from Partner_Marketing_Activity__c where Partner__c IN :setOfAccountIds])
                setOfPMAIds.add(pmaObj.Id);
        }
        return setOfPMAIds; 
    }
    
    public static Set<Id> getPMPs(Set<Id> setOfAccountIds) {
        Set<Id> setOfPMPIds = new Set<Id>();
        if(Schema.sObjectType.Partner_Marketing_Plan__c.isAccessible()){
            for(Partner_Marketing_Plan__c pmpObj : [Select Id from Partner_Marketing_Plan__c where Partner__c IN :setOfAccountIds])
                setOfPMPIds.add(pmpObj.Id);
        }
        return setOfPMPIds;
    }

    public static Set<Id> getQuotes(Set<Id> setOfAccountIds) {
        Set<Id> setOfQuotesIds = new Set<Id>();
        if(Schema.sObjectType.SBQQ__Quote__c.isAccessible()){
            for(SBQQ__Quote__c quoteObj : [Select Id from SBQQ__Quote__c where SBQQ__Opportunity2__r.Partner_Involved__c IN :setOfAccountIds])
                setOfQuotesIds.add(quoteObj.Id);
        }
        return setOfQuotesIds;
    }
        
    public static Map<String,String> getMapOfObjectToFields() {
        Map<String,String> mapOfObjectToFields = new Map<String,String>();
        for(NAP_Object_Search_Setting__mdt obj : [Select Label,Fields__c from NAP_Object_Search_Setting__mdt])
            mapOfObjectToFields.put(obj.Label,obj.Fields__c);

        return mapOfObjectToFields;
    }
    
    /*@AuraEnabled
    public static Map<String,List<String>> getObjectToListToIds(List<String> recordIds) {
        System.debug('Record ids size -'+recordIds.size());
        Map<String,List<String>> getObjectToListToIdsMap = new Map<String,List<String>>();
        if (recordIds != null && recordIds.size() > 0) {
            for (String s:recordIds) {
                String ObjectLabel = Id.valueOf(s).getSObjectType().getDescribe().getLabel();
                List<String> recordsList;
                if (getObjectToListToIdsMap.keySet().contains(ObjectLabel)) {
                    recordsList = getObjectToListToIdsMap.get(ObjectLabel);
                } else {
                    recordsList = new List<String>();
                }
                recordsList.add(s);
                getObjectToListToIdsMap.put(ObjectLabel,recordsList);
            }
        }
        System.debug('getObjectToListToIdsMap :'+getObjectToListToIdsMap);
        return getObjectToListToIdsMap;
    }*/
    
    @AuraEnabled
    public static Map<String,String> getObjectLabelMap(List<String> objAPINames) {
        System.debug('objAPINames :'+objAPINames);
        Map<String,String> responseMap = new Map<String,String>();
        List<Schema.DescribeSObjectResult> describeSobjectsResult = Schema.describeSObjects(objAPINames);
        for (Schema.DescribeSObjectResult s:describeSobjectsResult) {
            responseMap.put(s.getName(), s.getLabel());
        }
        //String objectLabel = describeSobjectsResult[0].getLabel();
        System.debug('Response Map :'+responseMap);
        return responseMap;
    }
    
    @AuraEnabled
    public static List<String> getFieldsLabels(List<String> fieldsAPINames,String objectName) {
        List<String> results = new List<String>();

        List<Schema.DescribeSObjectResult> describeSobjectsResult = Schema.describeSObjects(new List<String>{objectName});
        //String objectLabel = describeSobjectsResult[0].getLabel();
        Map<String, Schema.SObjectField> allFields = describeSobjectsResult[0].fields.getMap();
        //System.debug(allFields);
        for (String s:fieldsAPINames) {
            s = s.replace('__r','__c');
            results.add(allFields.get(s).getDescribe().getLabel()) ;
        }
        //String fieldLabel = allFields.get(fieldName).getDescribe().getLabel();
        return results;
    }

}