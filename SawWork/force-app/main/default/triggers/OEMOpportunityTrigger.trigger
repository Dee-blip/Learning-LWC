trigger OEMOpportunityTrigger on OEM_Opportunity__c (before insert, before update) {

    if (Trigger.isbefore) {
        
            
        If (Trigger.isInsert) {
        
            OEMOpportunityTriggerHandler handler = new OEMOpportunityTriggerHandler();
            handler.insertHandler(Trigger.new);

            AkamFieldHandler akamFieldHandler = new AkamFieldHandler();
            akamFieldHandler.insertHandler(Trigger.new);
            
            
            
        } 
        else if (Trigger.isUpdate) {
            OEMOpportunityTriggerHandler handler = new OEMOpportunityTriggerHandler();
            handler.updateHandler(Trigger.oldMap,Trigger.new);

            AkamFieldHandler akamFieldHandler = new AkamFieldHandler();
            akamFieldHandler.updateHandler(Trigger.new);
            
            //String OEMopptyStageNameInclusion = GSM_Custom_Settings__c.getInstance('OEMInclusionStageList#ForecastCategory').Value__c;
            //SFDC-2686
            //String OEMopptyStageNameExlusion = GSM_Custom_Settings__c.getInstance('OEMExclusionStageList#ForecastCategory').Value__c;
            String OEMopptyStageNameExlusion = GsmUtilClass.getGSMSettingValue('OEMExclusionStageList_ForecastCategory');
            

            /* CR 3243511 - For all OEM Oppty's before Update/Insert*/

            for(OEM_Opportunity__c oemOppty: Trigger.new)
            {
                system.debug(' Inside Loop: Override_Forecast_Category__c '+oemOppty.Override_Forecast_Category__c );
                // if Override Forecast is populated and Stage is 1 to 4 then Override Forecast category with Override Forecast Category field value else make Override Forecast Category as null
                
                if(OEMopptyStageNameExlusion.contains(oemOppty.Stage__c ))
                    oemOppty.Override_Forecast_Category__c = '';
            }



            
        }
    }
}