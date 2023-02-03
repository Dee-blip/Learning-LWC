/*
* Object: SBQQ__Quote__c
* Details : Helper class for CPQ quote object trigger handler.
* 
* Developer			Date			Version		Update 
* kimishra			08/06/2019		1.0			Initial version
* kimishra			09/06/2019		1.1			legal entity logic fixed
* kimishra			09/17/2019		1.1			legal entity logic for unique value like UAE, UK, etc
* kimishra			09/26/2019		1.3			geo location logic commented since it is moved to formula field on Quote.
* kimishra			10/12/2019		1.4			validateCurrency method added to check Quote's currency to be same as its Opportunity.
* shegade           09/11/2020      1.5         CPQ-318, CPQ-368, CPQ-426
* 
*/
public without sharing class CPQ_QuoteTriggerHelper {
    private static Map<Id, Opportunity> opportunityMap = null;
    
    //Lazy Initialization starts
    public static Map<Id, Opportunity> getOpportunityMap(Set<Id> oppIds){
        if(opportunityMap == null){
            opportunityMap = new Map<Id, Opportunity>([SELECT Id, Order_Region__c, CurrencyIsoCode, Pricebook2Id
                                                       FROM Opportunity
                                                       WHERE Id IN :oppIds]);
        }
        return opportunityMap;
    }
    //Lazy Initialization ends

    public static Map<Id, Opportunity> getIndirectOpportunityMap(Set<Id> oppIds){
        Map<Id, Opportunity> indirectOpportunityMap = new Map<Id, Opportunity>();
        try{
            indirectOpportunityMap = new Map<Id, Opportunity>([SELECT Id, Order_Region__c,Partner_Involved__c,Partner_Involved__r.Finance_Region__c, CurrencyIsoCode, Pricebook2Id
                                                       FROM Opportunity
                                                       WHERE Id IN :oppIds]);
        }
        catch(Exception e){
            CPQ_LogException newError = new CPQ_LogException('CPQ_QuoteTriggerHelper: Error in getIndirectOpportunityMap method', e).createErrorRecord(true);
        }
        return indirectOpportunityMap;
    }

    //update the Order Approval Record on Quote
    public static void updateOrderApproval(List<SBQQ__Quote__c> newItems){
        Map<id,id> oppIdOAmap = new Map<Id,Id>();
        Set<id> oppIDs = new set<Id>();
        List<Order_Approval__c> oAList = new List<Order_Approval__c>();
        
        // prepare the list of opportunity ids in this transaction
        for(SBQQ__Quote__c item: newItems){
            if(String.isNotBlank(item.SBQQ__Opportunity2__c)){
                System.debug('--opp id update OA: '+item.SBQQ__Opportunity2__c);
                oppIds.add(item.SBQQ__Opportunity2__c);
            }
        }
 		
        //fetch all the OA related to that opportunity
        oAList = [SELECT id, Associated_Opportunity__c  
                  FROM Order_Approval__c 
                  WHERE Associated_Opportunity__c IN :oppIDs];
        
        //create the map of opp id and OA
        for ( Order_Approval__c item : oAList) {
           oppIdOAmap.put(item.Associated_Opportunity__c,item.id);
        }
        
        for ( SBQQ__Quote__c item : newItems) {
            //update the order approval lookup on the quote for which it is blank
            if(oppIdOAmap.containsKey(item.SBQQ__Opportunity2__c)){
            	id oAid = oppIdOAmap.get(item.SBQQ__Opportunity2__c);
                item.CPQ_Order_Approval__c = oAid;
   				}       
    }
    }
    
    //update the legal entity lookup on Quote based on the related Opportunity's Order Region
    public static void updateLegalEntity (List<SBQQ__Quote__c> newItems){
        Set<Id> oppIds = new Set<Id>();
        Set<String> orderRegions = new Set<String>();
        Map<String, Id> regionIdMap = new Map<String, Id>();
        List<String> orderRegionToAdd = new List<String>();
        Map<String,Object> regionMappingMap = CPQSettings.getMetadataValueMap('reportingRegionOrderRegionMapping'); //CPQ-368
        Set<Id> indirectOpportunityIds = new Set<Id>();

        
        //to check in custom setting if region is unique in naming convention like UAE, UK
        CPQ_Generic_Settings__c regionLegalSetting = CPQ_Generic_Settings__c.getInstance('OrderRegionLegalEntityMapping');
        Map<String, Object> regionLegalMap = (Map<String, Object>)JSON.deserializeUntyped(regionLegalSetting.CPQ_Value__c);
        System.debug('--regionLegalMap: '+regionLegalMap);
        
        //to get default Region and Geo Location
        CPQ_Generic_Settings__c regionGeoSetting = CPQ_Generic_Settings__c.getInstance('DefaultRegionGeoLocation');
        Map<String, Object> defaultRegionGeoLocMap = (Map<String, Object>)JSON.deserializeUntyped(regionGeoSetting.CPQ_Value__c);
        System.debug('--defaultRegionGeoLocMap: '+defaultRegionGeoLocMap);
        String defaultRegion = (String) defaultRegionGeoLocMap.get('Region');
        String defaultGeoLoc = (String) defaultRegionGeoLocMap.get('Geo Location');
        
        //get the Opportunity Ids
        for(SBQQ__Quote__c item : newItems){
            if(String.isNotBlank(item.SBQQ__Opportunity2__c)){
                System.debug('--opp id update legal: '+item.SBQQ__Opportunity2__c);
                oppIds.add(item.SBQQ__Opportunity2__c);
                if(item.CPQ_Quote_Type__c == 'Partner'){
                    indirectOpportunityIds.add(item.SBQQ__Opportunity2__c); //CPQ-368
                }
            }

        }
        
        if(!oppIds.isEmpty()){
            /*Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([SELECT Id, Order_Region__c 
                                                                    FROM Opportunity
                                                                    WHERE Id IN :oppIds]);*/
            Map<Id, Opportunity> oppMap = getOpportunityMap(oppIds);
            Map<Id, Opportunity> indirectOpportunityMap = getIndirectOpportunityMap(indirectOpportunityIds); //CPQ-368
            
            for(Opportunity opp : oppMap.values()){
                if(String.isNotBlank(opp.Order_Region__c)){
                    orderRegions.add(opp.Order_Region__c);
                }
            }

            //CPQ-368
            for(Opportunity opp: indirectOpportunityMap.values()){
                if(String.isNotBlank(opp.Partner_Involved__c) && String.isNotBlank(opp.Partner_Involved__r.Finance_Region__c) && regionMappingMap.containsKey(opp.Partner_Involved__r.Finance_Region__c)){
                    orderRegions.add((String)regionMappingMap.get(opp.Partner_Involved__r.Finance_Region__c));
                }
            }
            //for default LE mapping
            orderRegions.add('United States'); //use custom label
            System.debug('--orderRegions: '+orderRegions);
            
            for(String orderReg : orderRegions){
                if(regionLegalMap.containsKey(orderReg)){
                    String  tempOrderRegion = (String) regionLegalMap.get(orderReg);
                    orderRegionToAdd.add(tempOrderRegion);
                }
            }
            
            if(!orderRegionToAdd.isEmpty()){
                orderRegions.addAll(orderRegionToAdd);
            }
            System.debug('--orderRegions updated: '+orderRegions);
            
            //query required legal entities
            List<Legal_Entity__c> leList = [SELECT Id, Name FROM Legal_Entity__c WHERE Name IN :orderRegions];
            if(!leList.isEmpty()){
                //map the region and LE ids
                for(Legal_Entity__c le : leList){
                    regionIdMap.put(le.Name, le.Id);
                }
            }
            System.debug('--regionIdMap: '+regionIdMap);
            
            //geo location CS - logic moved to formula field on Quote - KIMISHRA 09/26/2019
            //Map<String, CPQ_Order_Region_RSM_Region_Mapping__c> regionCSMap = CPQ_Order_Region_RSM_Region_Mapping__c.getAll();
            
            for(SBQQ__Quote__c item : newItems){
                if(oppMap.containsKey(item.SBQQ__Opportunity2__c)){
                    
                    String quoteRegion = oppMap.get(item.SBQQ__Opportunity2__c).Order_Region__c;
                    //CPQ-368
                    if(item.CPQ_Quote_Type__c == 'Partner' && indirectOpportunityMap.containsKey(item.SBQQ__Opportunity2__c)){
                        String partnerAccountFinanceRegion = indirectOpportunityMap.get(item.SBQQ__Opportunity2__c).Partner_Involved__r.Finance_Region__c;
                        if(regionMappingMap.containsKey(partnerAccountFinanceRegion)){
                            quoteRegion = (String)regionMappingMap.get(partnerAccountFinanceRegion);
                        } 
                        else{
                            quoteRegion = defaultRegion;
                        }
                    }
        
                    //CPQ-368 CPQ_QuoteRegion__c field is a new field to store the region for the legal entity
                    if(String.isNotBlank(quoteRegion)){
                        if(regionIdMap.containsKey(quoteRegion)){
                            item.Legal_Entity__c = regionIdMap.get(quoteRegion);
                            item.CPQ_QuoteRegion__c = quoteRegion;
                        } else if(regionLegalMap.containsKey(quoteRegion) && regionIdMap.containsKey( (String) regionLegalMap.get(quoteRegion))){
                            item.Legal_Entity__c = regionIdMap.get((String) regionLegalMap.get(quoteRegion));
                            item.CPQ_QuoteRegion__c = quoteRegion;
                        } else{
                            item.Legal_Entity__c = regionIdMap.get(defaultRegion);
                            item.CPQ_QuoteRegion__c = defaultRegion;
                        }
                        //geo location
                        /*if(regionCSMap.containsKey(quoteRegion)){
                            item.CPQ_Geo_Location__c = regionCSMap.get(quoteRegion).CPQ_Geo_Location__c;
                        } else{
                            item.CPQ_Geo_Location__c = regionCSMap.get(defaultGeoLoc).CPQ_Geo_Location__c;
                        }*/
                    } else{
                        item.Legal_Entity__c = regionIdMap.get(defaultRegion);
                        item.CPQ_QuoteRegion__c = defaultRegion;
                        //default geo location - AMER
                        //item.CPQ_Geo_Location__c = regionCSMap.get(defaultGeoLoc).CPQ_Geo_Location__c;
                    }
                }
            }
            
            System.debug('--newItems: '+newItems);
        }
    }
    
    /*public static void checkPrimaryQuote(List<SBQQ__Quote__c> newItems){
        map<Id,Integer> oppQuoteCount = new map<Id,Integer>();
        set<Id> oppIds = new set<Id>();
        Set<id> oppQuoteIds = new set<id>();
        //list of all opportunities for the list of qoutes
        for (SBQQ__Quote__c item : newItems ){
            oppIds.add(item.SBQQ__Opportunity2__c);
        }
        
        //query for all quotes for the list of opportunities.
        List<SBQQ__Quote__c> quoteOpps = [SELECT ID,SBQQ__Opportunity2__c FROM SBQQ__Quote__c WHERE SBQQ__Opportunity2__c IN:oppIds];
        
        system.debug(quoteOpps);
        
        //generate map for count of quotes againts given opportunity 
        for (SBQQ__Quote__c item : quoteOpps ){
            oppQuoteIds.add(item.SBQQ__Opportunity2__c);
            /*if(oppQuoteCount.containsKey(item.SBQQ__Opportunity2__c)){
oppQuoteCount.put(item.SBQQ__Opportunity2__c,oppQuoteCount.get(item.SBQQ__Opportunity2__c) + 1);
}
else{
oppQuoteCount.put(item.SBQQ__Opportunity2__c,1);
}
        }
        
        //update the primary flag if the new quote is the only quote under given opportunity
        for (SBQQ__Quote__c item : newItems ){
            if(!(oppQuoteIds.contains(item.SBQQ__Opportunity2__c))){
                item.SBQQ__Primary__c  = true;
            }
        }
    }*/
    
    //method to insert an Approver record if it not already exists in sbaa__Approver__c object
    public static void insertAMapproverRecord(Map<Id, SObject> newItems){
        List<SBQQ__Quote__c> newQuotes = (List<SBQQ__Quote__c>) newItems.values();
        List<Id> listOfAMIds = new List<Id>();
        Set<Id> existingUserApproverSet = new Set<Id>();
        List<sbaa__Approver__c> approversToInsert = new List<sbaa__Approver__c>();
        
        //get the list of quote AMs
        for(SBQQ__Quote__c qt : newQuotes){
            if(qt.Sales_Rep_Manager__c != null){
                listOfAMIds.add(qt.Sales_Rep_Manager__c);
            }
        }
        
        if(!listOfAMIds.isEmpty()){
            //get existing Approvers
            Map<Id, sbaa__Approver__c> approversMap = new Map<Id, sbaa__Approver__c>([SELECT Id, sbaa__User__c
                                                                                      FROM sbaa__Approver__c
                                                                                      WHERE sbaa__User__c IN :listOfAMIds]);
            for(sbaa__Approver__c ap : approversMap.values()){
                existingUserApproverSet.add(ap.sbaa__User__c);
            }
            System.debug('--existingUserApproverSet: '+existingUserApproverSet);
            
            //if(!existingUserApproverSet.isEmpty()){
                for(SBQQ__Quote__c qt : newQuotes){
                    //create a new Approver record if it doesn't exist in the user-approver map
                    if(existingUserApproverSet.isEmpty()){
                        approversToInsert.add(new sbaa__Approver__c(Name = qt.CPQ_Approving_Manager_Name__c,
                                                                    sbaa__User__c = qt.Sales_Rep_Manager__c));
                    }
                    else if (!existingUserApproverSet.contains(qt.Sales_Rep_Manager__c)) {
                        approversToInsert.add(new sbaa__Approver__c(Name = qt.CPQ_Approving_Manager_Name__c,
                                                                    sbaa__User__c = qt.Sales_Rep_Manager__c));
                    }
                }
                System.debug('--approversToInsert: '+approversToInsert);
            //}
            
            if(!approversToInsert.isEmpty()){
                try{
                    insert approversToInsert;
                } catch(Exception e){
                    System.debug('--Exception Occurred: '+e);
                }
            }
        }
    }
    
    //update the RSM value based on geo location
    public static void updateRSM(List<SBQQ__Quote__c> newItems){
        Set<String> userAliasSet = new Set<String>();
        Map<String, Id> aliasIdMap = new Map<String, Id>();
        
        CPQ_Generic_Settings__c geoRSMsetting = CPQ_Generic_Settings__c.getInstance('Geo Location RSM Mapping');
        //put json data in Map
        Map<String, Object> geoRSMmap = (Map<String, Object>)JSON.deserializeUntyped(geoRSMsetting.CPQ_Value__c);
        
        for(SBQQ__Quote__c item : newItems){
            String  userAlias = (String) geoRSMmap.get(item.CPQ_Geo_Location__c);
            userAliasSet.add(userAlias);
            System.debug('quote: '+item.CPQ_Geo_Location__c+' -- '+userAlias);
        }
        
        if(!userAliasSet.isEmpty()){
            for(User us : [SELECT Id, Alias
                           FROM USER
                           WHERE Alias IN :userAliasSet]){
                               aliasIdMap.put(us.Alias, us.Id);
                           }
            
            for(SBQQ__Quote__c item : newItems){
                System.debug('geo location: '+item.CPQ_Geo_Location__c);
                if(item.CPQ_Geo_Location__c != null && geoRSMmap.containsKey(item.CPQ_Geo_Location__c)){
                    String  userAlias = (String) geoRSMmap.get(item.CPQ_Geo_Location__c);
                    item.Sales_Rep_Manager__c = aliasIdMap.get(userAlias);
                    System.debug('alias: '+item.Sales_Rep_Manager__c);
                }
            }
        }
    }

    //purpose@ to make the first quote primary and to make only one quote primary at a time
    //execution event@ insert, update
    public static void appendPrimaryQuote(List<SBQQ__Quote__c> newItems){
        //logic here
        Map<Id,List<SBQQ__Quote__c>> oppQuoteMap = CPQ_QuoteTriggerHelper.getOpportunityQuoteListMap(newItems); 
        //map creation logic has been moved to getOpptyQuoteListMap method from here.
        List<SBQQ__Quote__c> quoteToRemovePrimary = new List<SBQQ__Quote__c>();
        //setting value based on Map created
        for(SBQQ__Quote__c quote : newItems)
        {
           // System.debug('oppQuoteMap.get(quote.SBQQ__Opportunity2__c).size() ---> '+oppQuoteMap.get(quote.SBQQ__Opportunity2__c));
        //if its the first quote created for opportunity its PRIMARY :)
        if(oppQuoteMap.get(quote.SBQQ__Opportunity2__c) == null && String.isNotBlank(quote.SBQQ__Opportunity2__c))//also checking is the opportunity is not null else no use of primary
        {
            quote.CPQ_Primary__c = true;

        }else if(oppQuoteMap.get(quote.SBQQ__Opportunity2__c) != null && oppQuoteMap.get(quote.SBQQ__Opportunity2__c).size() > 0){
            if(quote.CPQ_Primary__c == true){ //checking if the new creating quote is checked primary
               
               for(SBQQ__Quote__c quoteItems: oppQuoteMap.get(quote.SBQQ__Opportunity2__c))
               {
                 if(quote.Id != quoteItems.Id)
                 {  
                    //CPQ-426 There can be Only one Locked Quote under an Opportunity - shegade
                   if(quoteItems.CPQ_Primary__c == true && quoteItems.CPQ_Locked__c == true && quote.CPQ_Quote_Type__c == 'Partner'){
                        quote.addError(System.Label.CPQ_Primary_Quote_Error);
                   }
                   else if(quoteItems.CPQ_Primary__c == true){ //checking if Quote is PRIMARY if true then only add to update
                     quoteItems.CPQ_Primary__c = false;     
                     quoteToRemovePrimary.add(quoteItems);
                   }
                 }//if(quote.Id != quoteItems.Id)
               }//for(SBQQ__Quote__c quoteItems: oppQuoteMap.get(quote.SBQQ__Opportunity2__c))
             
            }//if(quote.CPQ_Primary__c == true)

        }//else if(oppQuoteMap.get(quote.SBQQ__Opportunity2__c).size() > 0)

        }//for(SBQQ__Quote__c quote : newItems)

        if(quoteToRemovePrimary.size() >0) { Update quoteToRemovePrimary; } //updating the recird tio remove and make one primary

    }//END AppendPrimaryQuote
    
    //Currency on primary quotes must match opportunity currency : kimishra - 10/12/2019
    public static void validateCurrency(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        Set<Id> oppIds = new Set<Id>();
        Map<Id, SBQQ__Quote__c> newItemsMap = (Map<Id, SBQQ__Quote__c>) newItems;
        Map<Id, SBQQ__Quote__c> oldItemsMap = (Map<Id, SBQQ__Quote__c>) oldItems;
        
        for(SBQQ__Quote__c item : (List<SBQQ__Quote__c>) newItems.values()) {
            if(String.isNotBlank(item.SBQQ__Opportunity2__c)){
                oppIds.add(item.SBQQ__Opportunity2__c);
            }
        }
        System.debug('--oppIds: '+oppIds);
        
        /*Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([SELECT Id, CurrencyIsoCode FROM Opportunity
                                                                WHERE Id IN :oppIDs]);*/
        Map<Id, Opportunity> oppMap = getOpportunityMap(oppIDs);
        
        for(SBQQ__Quote__c item : (List<SBQQ__Quote__c>) newItems.values()) {
            //check if currency field is changed
            if(item.CPQ_Primary__c) {
                //check if the currency is same as its Opportunity
                if(item.CurrencyIsoCode != oppMap.get(item.SBQQ__Opportunity2__c).CurrencyIsoCode) {
                    item.addError(System.Label.CPQ_Currency_Mismatch);
                }
            }
        }
    }

    public static void updateCurrencyPricebook (List<SBQQ__Quote__c> newItems) {
        Set<Id> oppIds = new Set<Id>();
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
        
        for(SBQQ__Quote__c item : newItems) {
            if(String.isNotBlank(item.SBQQ__Opportunity2__c)){
                oppIds.add(item.SBQQ__Opportunity2__c);
            }
        }
        System.debug('--opp id update currency: '+oppIds);
        
        if(!oppIds.isEmpty()) {
            oppMap = getOpportunityMap(oppIds);
            
            for(SBQQ__Quote__c item : newItems) {
                if(oppMap.containsKey(item.SBQQ__Opportunity2__c)) {
                    if(String.isNotBlank(oppMap.get(item.SBQQ__Opportunity2__c).CurrencyIsoCode)) {
                        item.CurrencyIsoCode = oppMap.get(item.SBQQ__Opportunity2__c).CurrencyIsoCode;
                    }
                    if(String.isNotBlank(oppMap.get(item.SBQQ__Opportunity2__c).Pricebook2Id)) {
                        item.SBQQ__PriceBook__c = oppMap.get(item.SBQQ__Opportunity2__c).Pricebook2Id;
                    }
                }
            }
        }
    }

    /**
     * updateOpportunityAutonomyStatus method update the Autonomy Status field on Opportunity. CPQ-318
     * @param  newItems       Map of Id to Quote.
     * @param  autonomyStatus Status to be set on opportunity.
     * @exception Exception dml exception upon failure of opportunity update.
     */ 
    public static void updateOpportunityAutonomyStatus(Map<Id, SObject> newItems, String autonomyStatus){

        List<SBQQ__Quote__c> newQuotes = (List<SBQQ__Quote__c>) newItems.values();
        Map<id,List<SBQQ__Quote__c>> opptyQuoteMap = CPQ_QuoteTriggerHelper.getOpportunityQuoteListMap(newQuotes);
        List<Id> opportunityIdList = new List<Id>();
        Map<Id,Id> opportunityQuoteIdMap = new Map<Id,Id>();
        List<Opportunity> opptyList = new List<Opportunity>();
        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage>();

        for(SBQQ__Quote__c item: newQuotes){
            List<SBQQ__Quote__c> quoteList = opptyQuoteMap.get(item.SBQQ__Opportunity2__c);
            if(quoteList.size() == 1 && quoteList[0].id == item.Id && quoteList[0].CPQ_Quote_Type__C == 'Partner'){
                opportunityIdList.add(item.SBQQ__Opportunity2__c);
                opportunityQuoteIdMap.put(item.SBQQ__Opportunity2__c,item.Id);
            }

        }

        if(opportunityIdList.size()>0){

            opptyList = [SELECT  Id, Autonomy_Status__c,Validation_Override__c, Channel_Manager__r.PAE_ID__r.Email,FCM__r.Email FROM Opportunity WHERE Id IN :opportunityIdList];
            for(Opportunity item: opptyList){
                item.Validation_Override__c = true;
                item.Autonomy_Status__c = autonomyStatus;
            }

            try{
                update opptyList;
            }
            catch(Exception e){
                CPQ_LogException newError = new CPQ_LogException('CPQ_QuoteTriggerHelper: Error in updateOpportunityAutonomyStatus method', e).createErrorRecord(true).sendEmailtoDev();
                System.debug(System.LoggingLevel.ERROR, newError.getCause());
            }

            if(CPQSettings.getValue('paeEmailTemplate') != null){
                try{
                    for(Opportunity item: opptyList){
                        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
                        message = new CPQ_SendEmailHelper(CPQSettings.getValue('paeEmailTemplate'), opportunityQuoteIdMap.get(item.Id), new List<String>{item.Channel_Manager__r.PAE_ID__r.Email})
                                      .setDefaultOrgWideId(CPQSettings.getValues('defaultOrgWideEmail'))
                                      .getMessageObject();
                        messages.add(message); 
                    }
                 Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
                }
                catch(Exception e){
                    CPQ_LogException newError = new CPQ_LogException('CPQ_QuoteTriggerHelper: Error in updateOpportunityAutonomyStatus method', e).createErrorRecord(true).sendEmailtoDev();
                    System.debug(System.LoggingLevel.ERROR, newError.getCause());
                }
            }

            
        }
        
            
    }

    /**
     * getOpportunityQuoteListMap method is used to list down the quotes attached to opportunities. CPQ-318: moved it from AppendPrimaryQuote Method
     * @param  newItems List of quotes
     * @return          map of opportunity ids and list of quotes attached to it.
     */ 
    private static Map<Id, List<SBQQ__Quote__c>> getOpportunityQuoteListMap(List<SBQQ__Quote__c> newItems){

        Map<Id,List<SBQQ__Quote__c>> oppQuoteMap = new Map<Id,List<SBQQ__Quote__c>>();
        List<SBQQ__Quote__c> quotesWithOppsList = new List<SBQQ__Quote__c>();
        List<id> idListOps = new List<Id>();
        List<Id> currentUpdatingQuoteId = new List<Id>();

        for(SBQQ__Quote__c quote:newItems){
            currentUpdatingQuoteId.add(quote.Id);
            //adding opputunity based on 
            if(String.isNotBlank(quote.SBQQ__Opportunity2__c)){
                idListOps.add(quote.SBQQ__Opportunity2__c);
            }
        }//

        if(!idListOps.isEmpty()){
            quotesWithOppsList = [select id,CPQ_Primary__c,SBQQ__Primary__c,SBQQ__Opportunity2__c,CPQ_Quote_Type__c,CPQ_Locked__c from SBQQ__Quote__c where SBQQ__Opportunity2__c IN:idListOps];
            System.debug('quotesWithOppsList ---> '+quotesWithOppsList.size());
            for(ID currOppId: idListOps){
                List<SBQQ__Quote__c> quoteList = new List<SBQQ__Quote__c>();
                for (SBQQ__Quote__c quotesWithOpp : quotesWithOppsList ){                  
                    if(currOppId == quotesWithOpp.SBQQ__Opportunity2__c )
                    {
                        quoteList.add(quotesWithOpp);
                    }//if
                oppQuoteMap.put(currOppId,quoteList);
                }//for
            }//for(ID oppId: idListOps)
        }

        return oppQuoteMap;
        
    }

}