public class OpportunityUtilClass{
    
    public static Boolean genericUSDFlagForTestClass = true;
    public static Boolean updateOpportunityOpptyLineItemAfterInsertUpdate =true;

    // Commented as part of SFDC-8127

    public static boolean CheckCountryWarning(Id opptyId){

    	boolean flag=false;
    	opportunity currentOppty = [select id, deal_type__c, Sales_Approval_Status__c, IALT_Received__c, IALT_Requested__c, Is_Restricted_Country__c, OwnerId,Is_Authorized_Partner_Sellable_Country__c, Account.BillingCountry, Partner_Involved__r.Partner_Sellable_Countries__c,Account.Name,isWon, isClosed, Account.eCustoms_Legal_Approved__c, Account.RPS_Status__c  from Opportunity where id= :opptyId];
        //SFDC-2686
        //Error_Page_Settings__c eps =Error_Page_Settings__c.getInstance(currentOppty.Sales_Approval_Status__c);
        String eps = null;
        String metadataName = currentOppty.Sales_Approval_Status__c;
        if(metadataName != null){
          if(metadataName.contains(' ')){
              metadataName = metadataName.replaceAll(' ', '_');
          }
          if(metadataName.isNumeric()){
              metadataName = 'X'+metadataName;
          }
         eps = GsmUtilClass.getErrorPageSettingValue(metadataName);  //Error_Page_Settings__c.getInstance(currentOppty.Sales_Approval_Status__c);
        }
        //Error_Page_Settings__c partnerSellableCountriesError = Error_Page_Settings__c.getInstance('PartnerSellableCountriesError');
        String partnerSellableCountriesError = GsmUtilClass.getErrorPageSettingValue('PartnerSellableCountriesError');
        // for strictly restricted country || // show warning only on open indirect opportunities || // eCustoms_Legal_Approved__c is false
        if((eps!=null && (!currentOppty.IALT_Received__c && currentOppty.Sales_Approval_Status__c=='Both Restricted') || (currentOppty.Sales_Approval_Status__c == 'Only Reselling Allowed' && currentOppty.Deal_Type__c=='Direct')) || (GsmUtilClass.isFeatureToggleEnabledCustomMetadata('Partner_Sellable_Country_Toggle') && partnerSellableCountriesError != null && !currentOppty.Is_Authorized_Partner_Sellable_Country__c && currentOppty.Deal_Type__c == 'Indirect' && currentOppty.isWon ==false && currentOppty.isClosed == false) || (currentOppty.Account.eCustoms_Legal_Approved__c == false && currentOppty.Account.RPS_Status__c == GsmUtilClass.getGSMSettingValue('Account_RPS_Status_c_Red')))
        {       
            flag=true;
        }
        return flag;

    }

    //SFDC-1453 - Sonali Tandon - Reusable USD conversion logic
    public static List<SObject> genericPopulateUSDOnChangeOfFields(List<SObject> objectList,Boolean validationOverride)
    {
        list<SObject> returnTestSObj =new list<SObject>();

        if(!genericUSDFlagForTestClass)
            return returnTestSObj;

        Set<String> setOfCurrencyIsoCodes                       = new Set<String>();
        Map<String, List<DatedConversionRate>> mapOfIsoCodeToDC = new Map<String, List<DatedConversionRate>>();
        Map<String,List<USD__mdt>> mapOfObjectToUSDmdt          = new Map<String,List<USD__mdt>>();

        // get all currency iso codes 
        for(SObject objectInstance : objectList)
        {
            if(objectInstance.getSObjectType() == Opportunity.getSObjectType())
              setOfCurrencyIsoCodes.add((String)objectInstance.get('CurrencyIsoCode'));
            else if(objectInstance.getSObjectType() == OpportunityLineItem.getSObjectType())
              setOfCurrencyIsoCodes.add((String)objectInstance.get('Opportunity_CurrencyIsoCode__c'));
        }

        System.debug(LoggingLevel.ERROR, 'setOfCurrencyIsoCodes' + setOfCurrencyIsoCodes);
        System.debug(LoggingLevel.ERROR, 'objectList' + objectList);
        
        // get conversion rates for the iso codes
        for(DatedConversionRate dcr : [SELECT IsoCode, ConversionRate, NextStartDate, StartDate FROM DatedConversionRate WHERE IsoCode in :setOfCurrencyIsoCodes])
        {
            if(!mapOfIsoCodeToDC.containsKey(dcr.IsoCode))
                mapOfIsoCodeToDC.put(dcr.IsoCode, new List<DatedConversionRate>());
            mapOfIsoCodeToDC.get(dcr.IsoCode).add(dcr);
        }

        // get fields to be converted to their corresponding USD values 
        for(USD__mdt usdObj : [Select Field__c,USD_Field__c,Object__c from USD__mdt ORDER BY Object__c limit 50000])
        {
            if(!mapOfObjectToUSDmdt.containsKey(usdObj.Object__c))
                mapOfObjectToUSDmdt.put(usdObj.Object__c,new List<USD__mdt>{usdObj});
            else
                mapOfObjectToUSDmdt.get(usdObj.Object__c).add(usdObj);
        }

        // USD conversion
        for(SObject objectInstance : objectList)
        {
            if(validationOverride)
                objectInstance.put('Validation_Override__c',validationOverride);

            if(objectInstance.getSObjectType() == Opportunity.getSObjectType())
            {
                for(DatedConversionRate dcr : mapOfIsoCodeToDC.get((String)objectInstance.get('CurrencyIsoCode')))
                {
                    if(dcr.StartDate <= (Date)objectInstance.get('CloseDate') && dcr.NextStartDate > (Date)objectInstance.get('CloseDate'))
                    {
                        for(USD__mdt usdObj :mapOfObjectToUSDmdt.get('Opportunity'))
                        {
                            if(objectInstance.get(usdObj.Field__c)!=null)
                                objectInstance.put(usdObj.USD_Field__c,((Decimal)objectInstance.get(usdObj.Field__c)/dcr.ConversionRate).setScale(2, RoundingMode.HALF_UP));
                            else
                                objectInstance.put(usdObj.USD_Field__c,0);
                        }

                        break; 
                    }
                }
            }
            else
            {
                for(DatedConversionRate dcr : mapOfIsoCodeToDC.get((String)objectInstance.get('Opportunity_CurrencyIsoCode__c')))
                {
                    if(dcr.StartDate <= (Date)objectInstance.get('Opportunity_Close_Date__c') && dcr.NextStartDate > (Date)objectInstance.get('Opportunity_Close_Date__c'))
                    {
                        for(USD__mdt usdObj :mapOfObjectToUSDmdt.get('OpportunityLineItem'))
                        {
                            if(objectInstance.get(usdObj.Field__c)!=null)
                                objectInstance.put(usdObj.USD_Field__c,((Decimal)objectInstance.get(usdObj.Field__c)/dcr.ConversionRate).setScale(2, RoundingMode.HALF_UP));
                            else
                                objectInstance.put(usdObj.USD_Field__c,0);
                        }

                        break; 
                    }
                }

            }
  
        }

        System.debug(LoggingLevel.ERROR, 'Modified Object List :'+ objectList);

        return objectList;

    } 

    //SFDC-1453 - Sonali Tandon - Reusable USD conversion logic
    public static List<String> buildSOQLParametersForUSDConversion(String objectName)
    {
        List<String> parameters = new List<String>();
        
        // add these to field sets 
        if(objectName.equals('Opportunity'))
        {
            for(Schema.FieldSetMember f : SObjectType.Opportunity.FieldSets.Opportunity_USD_conversion_field_set.getFields()) 
                parameters.add(f.getFieldPath());
        }
         else if(objectName.equals('OpportunityLineItem'))
        {
            for(Schema.FieldSetMember f : SObjectType.OpportunityLineItem.FieldSets.Opportunity_Product_USD_conversion_field.getFields()) 
                parameters.add(f.getFieldPath());
        }      
        
        for(USD__mdt param : [Select Field__c,USD_Field__c from USD__mdt where Object__c =:objectName])
        {
            parameters.add(param.Field__c);
            parameters.add(param.USD_Field__c);
        }

        return parameters;

    }
        // pre requisite : isClosed field on Opportunity should be queried
    public static Boolean isClosed(Id opportunityId)
    {
        Opportunity record = [Select isClosed from Opportunity where Id =:opportunityId];
        return record.isClosed;
    }
    public static Opportunity getOpportunityRecord(Map<Id,Opportunity> opptyMap, Id opptyId)
    {
        Opportunity opp = null;
        if(opptyMap != null)
        opp=opptyMap.get(opptyId);

        if (opp==null)
        opp=new Opportunity(Id= opptyId);

        return opp;
    }

    public static void updateOpportunityFromLineItemAfterInsertAfterUpdate(List<Opportunity> opptyList)
    {
        if(!updateOpportunityOpptyLineItemAfterInsertUpdate)
            return ;
        try {
            update opptyList;
            system.debug('Opportunity update :'+ opptyList);
        } catch (exception ex) {
            handleOpportunityException(ex,opptyList);
        }
        updateOpportunityOpptyLineItemAfterInsertUpdate=false;
    }
    public static void handleOpportunityException(Exception ex, List<Opportunity> opptyList)
    {
        Sawyer.saw(ex);
        String competitorError=GsmUtilClass.getGSMSettingValue('OpptyTriggerClass_CompetitorMandatory'); 
           /* if(ex.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION, Competitor is mandatory'))
                 customErrorMsg  = GsmUtilClass.getGSMSettingValue('OpptyTriggerClass_CompetitorMandatory'); */  //SFDC-2304
               
            /*} else if(ex.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION, Opportunity Category, Sub-Category, Cancellation/Loss Reason is required')){
                 customErrorMsg  = GsmUtilClass.getGSMSettingValue('OpptyTriggerClass_SubCategoryError');   //SFDC-2304
                if(customErrorMsg !='')
                opptyList[0].adderror(customErrorMsg1); //
            }
            else */
            String customErrorMsg = ex.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION, Competitor is mandatory') ? competitorError 
                                : (ex.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')? ex.getMessage().split(',')[1] 
                                : 'Something went wrong while updating/deleting requests.'+ex.getMessage()) ;
                
            if(customErrorMsg !='')
                opptyList[0].adderror(customErrorMsg);    
    }
    public static Boolean hasAssociatedRenewalContract(Id opportunityId)
    {
        List<Renewal_Contract_Object__c> renewalContracts = [Select Id from Renewal_Contract_Object__c where Opportunity__c=:opportunityId];
        Boolean returnValue;
        if(renewalContracts.size() == 0)
            returnValue = false;
        else if(renewalContracts.size()>0)
            returnValue = true;
        return returnValue;
    }


}