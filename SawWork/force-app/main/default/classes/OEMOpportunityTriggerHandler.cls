/***
    OEMOpportunityTriggerHandler
    @author : Shivam Verma <shiverma@akamai.com>
    @Description : This class implements the following logic for the OEM Opportunity trigger :
                    - Update the USD Amount value based on Currency Rate
   
    @History
    --Developer           --Date            --Change
    Shivam Verma          04/04/2015        Created the class.
***/
public class OEMOpportunityTriggerHandler {

    public void insertHandler(List<OEM_Opportunity__c> newList) {
        
        updateAmountInUSD(newList);
    }
    
    public void updateHandler(Map<Id,OEM_Opportunity__c> oldMap, List<OEM_Opportunity__c> newList) {
        
        List<OEM_Opportunity__c> OEMOppToUpdate = new List<OEM_Opportunity__c>();

        for (OEM_Opportunity__c OEMOpp:newList) {
            if (oldMap.get(OEMOpp.id).Amount__c != OEMOpp.Amount__c || 
                oldMap.get(OEMOpp.id).CurrencyIsoCode != OEMOpp.CurrencyIsoCode ||
                oldMap.get(OEMOpp.id).Close_Date__c != OEMOpp.Close_Date__c) {
                OEMOppToUpdate.add(OEMOpp);
            }
        }
        updateAmountInUSD(OEMOppToUpdate);
    } 

    public void updateAmountInUSD(List<OEM_Opportunity__c> OEMOppList)  {
        
        List<String> listOfOEMOpportunityCurrencyCodes = new List<String>();
        
        //Toggle functionality for the OTB Exchange Rate movement.
        //SFDC-2686
        /*if(GsmUtilClass.isFeatureToggleEnabledCustomMetadata('SFExchangeRateToggle') == true){ //Commented by Vivek as this functionality is not being used.
            Map<String, List<Dated_Exchange_Rate__c>> mapOfIsoCodeToDCR = new Map<String, List<Dated_Exchange_Rate__c>>();
            
            
            for(OEM_Opportunity__c opp : OEMOppList)
            { 
                listOfOEMOpportunityCurrencyCodes.add(opp.CurrencyIsoCode);
            }
            for(Dated_Exchange_Rate__c dcr : [SELECT CurrencyIsoCode, ConversionRate__c, NextStartDate__c, StartDate__C FROM Dated_Exchange_Rate__c WHERE CurrencyIsoCode in :listOfOEMOpportunityCurrencyCodes])
            {
                if(!mapOfIsoCodeToDCR.containsKey(dcr.CurrencyIsoCode))
                    mapOfIsoCodeToDCR.put(dcr.CurrencyIsoCode, new List<Dated_Exchange_Rate__c>());
                mapOfIsoCodeToDCR.get(dcr.CurrencyIsoCode).add(dcr);
            }
            for(OEM_Opportunity__c OEMOpp : OEMOppList)
            {
                //Opportunity parentOpp = mapOfOpportunityIdToOpportunity.get(oli.OpportunityId);
                
                for(Dated_Exchange_Rate__c tempDCR : mapOfIsoCodeToDCR.get(OEMOpp.CurrencyIsoCode))
                {
                    if(tempDCR.StartDate__c <= OEMOpp.Close_Date__c && tempDCR.NextStartDate__c > OEMOpp.Close_Date__c)
                    {
                        if(OEMOpp.Amount__c != null)
                        {
                            OEMOpp.Amount_in_USD__c = OEMOpp.Amount__c / tempDCR.ConversionRate__c ;  
                        }
                    }
                }
            }
        }*/
        //else
        {
            Map<String, List<DatedConversionRate>> mapOfIsoCodeToDCR = new Map<String, List<DatedConversionRate>>();
            
            
            for(OEM_Opportunity__c opp : OEMOppList)
            { 
                listOfOEMOpportunityCurrencyCodes.add(opp.CurrencyIsoCode);
            }
            for(DatedConversionRate dcr : [SELECT IsoCode, ConversionRate, NextStartDate, StartDate FROM DatedConversionRate WHERE IsoCode in :listOfOEMOpportunityCurrencyCodes])
            {
                if(!mapOfIsoCodeToDCR.containsKey(dcr.IsoCode))
                    mapOfIsoCodeToDCR.put(dcr.IsoCode, new List<DatedConversionRate>());
                mapOfIsoCodeToDCR.get(dcr.IsoCode).add(dcr);
            }
            for(OEM_Opportunity__c OEMOpp : OEMOppList)
            {
                //Opportunity parentOpp = mapOfOpportunityIdToOpportunity.get(oli.OpportunityId);
                
                for(DatedConversionRate tempDCR : mapOfIsoCodeToDCR.get(OEMOpp.CurrencyIsoCode))
                {
                    if(tempDCR.StartDate <= OEMOpp.Close_Date__c && tempDCR.NextStartDate > OEMOpp.Close_Date__c)
                    {
                        if(OEMOpp.Amount__c != null)
                        {
                            OEMOpp.Amount_in_USD__c = OEMOpp.Amount__c / tempDCR.ConversionRate ;  
                        }
                    }
                }
            }
            
        }
    }
    
    public void updateForecastCategory(List<OEM_Opportunity__c> OEMOppList)  {
        /*String OEMopptyStageNameInclusion = GSM_Custom_Settings__c.getInstance('OEMInclusionStageList#ForecastCategory').Value__c;
        String OEMopptyStageNameExlusion = GSM_Custom_Settings__c.getInstance('OEMExclusionStageList#ForecastCategory').Value__c;

        for(OEM_Opportunity__c oemOppty: OEMOppList)
            {
                
                    /*if(OEMopptyStageNameInclusion.contains(oemOppty.Stage__c ))
                    {
                        system.debug('Inside if');
                        oemOppty.Forecast_Category__c  = oemOppty.Override_Forecast_Category__c;
                    }
                    else 
                    if(OEMopptyStageNameExlusion.contains(oemOppty.Stage__c ))
                    {
                        System.debug('Inside else ');
                        oemOppty.Override_Forecast_Category__c = '';
                    }
               }*/
                    
                
            }
            
    public void updateForecastCategoryStageChange(List<OEM_Opportunity__c> OEMOppList)  {
        /*String OEMopptyStageNameInclusion = GSM_Custom_Settings__c.getInstance('OEMInclusionStageList#ForecastCategory').Value__c;
        String OEMopptyStageNameExlusion = GSM_Custom_Settings__c.getInstance('OEMExclusionStageList#ForecastCategory').Value__c;
        
        for(OEM_Opportunity__c oemOppty: OEMOppList)
            {
                
                    /*if(OEMopptyStageNameInclusion.contains(oemOppty.Stage__c))
                    {
                        if(oemOppty.Override_Forecast_Category__c != null)
                            oemOppty.Forecast_Category__c = oemOppty.Override_Forecast_Category__c;
                    }

                    //else if(OEMopptyStageNameExlusion.contains(oemOppty.Stage__c))
                    if(OEMopptyStageNameExlusion.contains(oemOppty.Stage__c))

                    {
                        oemOppty.Override_Forecast_Category__c = '';
                    }
                    
               }*/

        
                    
    }
    
}