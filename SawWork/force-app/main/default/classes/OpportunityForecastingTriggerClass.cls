global class OpportunityForecastingTriggerClass{

    public static Boolean manageForecastFirstRunFlag = true;
    public static Boolean genericPopulateMRRFirstRunFlag = true;
    public static Boolean convertMRRToUSDMRRFieldsFirstRunFlag = true;
    public static Map<Id,Opportunity> opptyMapForecasting=new Map<Id,Opportunity>();

    public static Map<Id,Opportunity> genericPopulateMRR(Set<Id> opptyId, String callingCodeName, Set<String> changedFieldName,Set<Opportunity> oppSet, Map<Id,Opportunity> opptyMap)
    {
        opptyMapForecasting=opptyMap;
        genericPopulateMRR(opptyId,callingCodeName,changedFieldName,oppSet);
        return opptyMapForecasting;
    }


    //SFDC-1435 - Modified method to make it configurable and generic
     // common method to populate Security MRR, Security Products MRR, PAE MRR and PAE SMRR when a line item is inserted/updated/deleted: CR 3018413 
    public static void genericPopulateMRR(Set<Id> opptyId, String callingCodeName, Set<String> changedFieldName,Set<Opportunity> oppSet)
    {
        system.debug(LoggingLevel.ERROR,'genericPopulateMRRFirstRunFlag:: '+genericPopulateMRRFirstRunFlag);

        if(!genericPopulateMRRFirstRunFlag)
            return;
            


        system.debug(LoggingLevel.ERROR,'callingCodeName: '+callingCodeName);
         List<Opportunity> opptyList = new List<Opportunity>();
        Set<Opportunity> updateOpptySet = new Set<Opportunity>();
        
        Map<id, Set<OpportunityLineItem>> mapOpptytoLineItem = new Map<id, Set<OpportunityLineItem>>();
        
        String securityGroup = GsmUtilClass.getGSMSettingValue('OppLineItem_SecurityGroup'); //SFDC-2304
        //SFDC-1108 Summarion of EMRI
        Decimal EMRISum=0;
        Boolean emriNeedsUpdate =(GsmUtilClass.getGSMSettingValue('Product_Wizard_GA_Toggle').containsIgnoreCase('true') || OpportunityGetBaseline.isRunning || CustomButtonController.isRunning);

        List<MRR_Roll_Up_On_Opportunity__mdt> listOfMRRRollUpOnOpportunitySettings = new List<MRR_Roll_Up_On_Opportunity__mdt>();
        listOfMRRRollUpOnOpportunitySettings = [Select Id,DeveloperName,Condition_On_Opportunity__c,Conditions_On_Line_Item__c,Line_Item_Rolled_Up_Field__c,Opportunity_Roll_Up_Field__c,Overriding_Flag_On_Opportunity__c from MRR_Roll_Up_On_Opportunity__mdt limit 50000];
        Map<String,String> mapOpptyFieldsToLineItemField = new Map<String,String>();
        Map<String,FieldOperatorConditionWrapper> mapOpptyFieldsToLineItemCondition = new Map<String,FieldOperatorConditionWrapper>();
        Map<String,FieldOperatorConditionWrapper> mapOpptyFieldsToOpptyCondition = new Map<String,FieldOperatorConditionWrapper>();
        
        String opptyFields = '';
        String oliFields = ',';//SFDC-1952
        //populate above fields with metadata values
        for(MRR_Roll_Up_On_Opportunity__mdt mdtRecord : listOfMRRRollUpOnOpportunitySettings){
            //populate only those records which have Condition_On_Opportunity__c populated when code gets called from opportunity trigger, because we need to recalculate all overridden fields
            system.debug(LoggingLevel.Error,'changedFieldName: '+changedFieldName);
            if((callingCodeName.equalsIgnoreCase('OpportunityTrigger') && !String.isBlank(mdtRecord.Overriding_Flag_On_Opportunity__c) && changedFieldName!=null && changedFieldName.contains(mdtRecord.Overriding_Flag_On_Opportunity__c))|| !callingCodeName.equalsIgnoreCase('OpportunityTrigger')){
                mapOpptyFieldsToLineItemField.put(mdtRecord.Opportunity_Roll_Up_Field__c,mdtRecord.Line_Item_Rolled_Up_Field__c);
                if(!opptyFields.contains(mdtRecord.Opportunity_Roll_Up_Field__c))
                    opptyFields +=mdtRecord.Opportunity_Roll_Up_Field__c+',';
                if(!oliFields.contains(','+mdtRecord.Line_Item_Rolled_Up_Field__c+',')){ //SFDC-1952
                    oliFields +=mdtRecord.Line_Item_Rolled_Up_Field__c+',';
                    system.debug(LoggingLevel.ERROR,'oliFields Line_Item_Rolled_Up_Field__c:'+oliFields);
                }
                
                //if(!mdtRecord.Conditions_On_Line_Item__c.contains('\n'))
                //populateFieldOperatorConditions(mdtRecord.Conditions_On_Line_Item__c);
                if(!String.isBlank(mdtRecord.Conditions_On_Line_Item__c)){
                    FieldOperatorConditionWrapper focw = FieldOperatorConditionWrapper.populateFieldOperatorConditions(mdtRecord.Conditions_On_Line_Item__c);
                    if(!focw.conditions.isEmpty())
                        for(FieldOperatorConditionWrapper.FieldOperatorCondition foc:focw.conditions){
                            system.debug(LoggingLevel.ERROR,'oliFields: '+oliFields+' :foc.fieldName: '+foc.fieldName+' contains: '+oliFields.contains(foc.fieldName.trim()));
                            if(!oliFields.contains(foc.fieldName.trim()))
                                oliFields+=foc.fieldName+',';
                        }
                    mapOpptyFieldsToLineItemCondition.put(mdtRecord.Opportunity_Roll_Up_Field__c,focw);
                }
                if(!String.isBlank(mdtRecord.Condition_On_Opportunity__c)){
                    FieldOperatorConditionWrapper focw = FieldOperatorConditionWrapper.populateFieldOperatorConditions(mdtRecord.Condition_On_Opportunity__c);
                    if(!focw.conditions.isEmpty())
                        for(FieldOperatorConditionWrapper.FieldOperatorCondition foc:focw.conditions)
                            if(!opptyFields.contains(foc.fieldName))
                                opptyFields+=foc.fieldName+',';
                   mapOpptyFieldsToOpptyCondition.put(mdtRecord.Opportunity_Roll_Up_Field__c,focw);
                }
            }
        }
        
         //make query for all these fields
         system.debug(LoggingLevel.ERROR,'opptyFields: '+opptyFields);
         system.debug(LoggingLevel.ERROR,'oliFields: '+oliFields);
         if(!callingCodeName.equalsIgnoreCase('OpportunityTrigger') && opptyId!=null){
            //SFDC-3831
            
             String query = 'SELECT id,stageName,Opportunity_Revenue_Impact__c,Validation_Override__c,'+opptyFields+'(SELECT id,Opportunityid'+oliFields+'EMRI__c FROM OpportunityLineItems) FROM Opportunity where id IN :opptyId';
             //Do query
             system.debug(LoggingLevel.ERROR,'::query:: '+query);
             opptyList = Database.query(query);
        }else{//Code-coverage
            if(oppSet!=null){
                opptyList.addAll(oppSet);
                String query = 'SELECT id,Opportunityid'+oliFields+'EMRI__c FROM OpportunityLineItem where Opportunityid IN :opptyList';
                 //Do query
                 system.debug(LoggingLevel.ERROR,'::query:: '+query);
                 List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
                 oliList = Database.query(query);
                 system.debug(LoggingLevel.ERROR,'oliList size:  after queey '+oliList.size());
                 system.debug(LoggingLevel.ERROR,'opptyList size:  after queey '+opptyList.size());
                 for(Opportunity opp : opptyList){
                    Set<OpportunityLineItem> addedOliList =new Set<OpportunityLineItem>();
                    if(!mapOpptytoLineItem.containsKey(opp.id))
                        mapOpptytoLineItem.put(opp.id,addedOliList);
                    for(OpportunityLineItem oli : oliList){
                        if(oli.Opportunityid==opp.id)
                            if(mapOpptytoLineItem.containsKey(opp.id)){
                                addedOliList = mapOpptytoLineItem.get(opp.id);
                                system.debug(LoggingLevel.ERROR,'addedOliList.contains(oli): '+addedOliList.contains(oli));
                                system.debug(LoggingLevel.ERROR,'oli in loop: '+oli);

                                if(!addedOliList.contains(oli))
                                    addedOliList.add(oli);
                                mapOpptytoLineItem.put(opp.id,addedOliList);
                            }
                    }
                 system.debug(LoggingLevel.Error,'addedOliList:: '+addedOliList.size()+' for: '+opp);           
                 }
                 

             }
        }
        
        //SFDC-5364 Define this heavy object here, Once, instead in loop
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        
        for(Opportunity oppty : opptyList)
        {
            List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
            Opportunity opptyToUpdate=OpportunityUtilClass.getOpportunityRecord(opptyMapForecasting,oppty.Id);
            if(!callingCodeName.equalsIgnoreCase('OpportunityTrigger') && opptyId!=null)
                    oliList = oppty.OpportunityLineItems;
                //Code-coverage
                else if(!mapOpptytoLineItem.isEmpty())
                    oliList.addAll(mapOpptytoLineItem.get(oppty.id));
                     system.debug(LoggingLevel.ERROR,'oliList: '+oliList);
                     system.debug(LoggingLevel.ERROR,'oliList SIZE: '+oliList.size());
            for(String opptyField : mapOpptyFieldsToLineItemField.keySet())
            {
             
                Decimal rollUpSum=0;
                EMRISum = 0;
                
                for(OpportunityLineItem lineItem : oliList)
                {    
                   
                    
                    
                    //Check conditions on line item
                    if(lineItem.get(mapOpptyFieldsToLineItemField.get(opptyField))!=null && ((mapOpptyFieldsToLineItemCondition.containsKey(opptyField) && FieldOperatorConditionWrapper.conditionChecker(lineItem,mapOpptyFieldsToLineItemCondition.get(opptyField)))||(!mapOpptyFieldsToLineItemCondition.containsKey(opptyField)))){
                    
                            //system.debug(LoggingLevel.ERROR,'schema type:: '+Schema.getGlobalDescribe().get('OpportunityLineItem').getDescribe().fields.getMap().get(mapOpptyFieldsToLineItemField.get(opptyField)).getDescribe().getType());
                            
                            Schema.DisplayType fielddataType = gd.get('OpportunityLineItem').getDescribe().fields.getMap().get(mapOpptyFieldsToLineItemField.get(opptyField)).getDescribe().getType();
                            system.debug(LoggingLevel.ERROR,'mapOpptyFieldsToLineItemField.get(opptyField): '+mapOpptyFieldsToLineItemField.get(opptyField));
                            if(fielddataType == Schema.DisplayType.Integer || fielddataType == Schema.DisplayType.Currency){
                                rollUpSum+=(Decimal)lineItem.get(mapOpptyFieldsToLineItemField.get(opptyField));
                            }
                            system.debug(LoggingLevel.ERROR,'rollUpSum:: '+rollUpSum+' lineItem: '+lineItem.get(mapOpptyFieldsToLineItemField.get(opptyField)));
                        }
                    if(lineItem.EMRI__c != null)
                        EMRISum += lineItem.EMRI__c;
                        
                }
                //SFDC-3907
                rollUpSum = rollUpSum.setScale(2, RoundingMode.HALF_UP);
                system.debug(LoggingLevel.ERROR,'rollUpSum: '+rollUpSum +' opptyField: '+opptyField);
                //Check conditions on oppty
                if((mapOpptyFieldsToOpptyCondition.containsKey(opptyField) && FieldOperatorConditionWrapper.conditionChecker(oppty,mapOpptyFieldsToOpptyCondition.get(opptyField))) || !mapOpptyFieldsToOpptyCondition.containsKey(opptyField))
                    opptyToUpdate.put(opptyField, rollUpSum);
                //SFDC-1108 Summarion of EMRI


                        
                    
            }
            
        
            
            //SFDC-156
             //SFDC-3831
            String opptyStageToOverride = GSMUtilClass.getGSMSettingValue('opptyStagesForRepsRecTypeChangeToClosed');
            //List<String> opptyStageToOverride = opptyStages.split(',');
             if(!opptyStageToOverride.contains(oppty.stageName))
                opptyToUpdate.Validation_Override__c = true;
            if(emriNeedsUpdate)
            {
                
                opptyToUpdate.Opportunity_Revenue_Impact__c = EMRISum;
                opptyToUpdate.EMRI_Pilot_Copy__c = oppty.Opportunity_Revenue_Impact__c;
            }
            updateOpptySet.add(opptyToUpdate); 
            opptyMapForecasting.put(opptyToUpdate.id, opptyToUpdate);   
        }

       
        // Commented below code since both calls from OpportunityLineItemtrigger is consloidated as part of SFDC-8958
        /*if(updateOpptySet.size()>0 && 
        !(callingCodeName.equalsIgnoreCase('OpportunityTrigger') || 
            (callingCodeName.equalsIgnoreCase('OpportunityLineItemTrigger') &&  (trigger.isInsert||trigger.isUpdate))   
            // Added by Chandra for SFDC-8958 to avoid opportunity update when it is made from Opportunitylinetiem trigger (insert & update)
        ) && opptyId!=null)        
        {   
            System.debug('Set : ' + updateOpptySet);
            List<Opportunity> updateOpptyList = new List<Opportunity>(updateOpptySet);
            System.debug('List : ' + updateOpptyList);
            update updateOpptyList;
        
        }*/
        genericPopulateMRRFirstRunFlag = false;
    }

    //SFDC-1560
    public static void ManageDPMForecast(Opportunity[] opptys, Map<Id, Opportunity> oppOldMap, Map<Id, Opportunity> oppNewMap)
    {
        System.debug(LoggingLevel.Error,'in manageDPMForecast' +manageForecastFirstRunFlag);
        if (!manageForecastFirstRunFlag)
            return;

        List<Manage_Forecast_Date_Category_n_Override__mdt> listOfManageForecastOverrideSettings = new List<Manage_Forecast_Date_Category_n_Override__mdt>();
        listOfManageForecastOverrideSettings = [Select Id,DeveloperName,Error_msg_on_fields_Change_6__c,Forecast_Category__c,Forecast_Close_date__c,Forecast_fields_1__c,Forecast_fields_2__c,MRR_override__c,Override_Close_Date__c,Override_Forecast_Category__c from Manage_Forecast_Date_Category_n_Override__mdt limit 50000];
        //SFDC-3831
        String opptyStageToOverride = GSMUtilClass.getGSMSettingValue('opptyStagesForRepsRecTypeChangeToClosed');
        system.debug(LoggingLevel.ERROR,'listOfManageForecastOverrideSettings: '+listOfManageForecastOverrideSettings);
        
        for(Manage_Forecast_Date_Category_n_Override__mdt manageForecastOverrideSettingsRec : listOfManageForecastOverrideSettings){
                Set<String> fieldNames = new Set<String>();
                fieldNames.addAll(manageForecastOverrideSettingsRec.Forecast_fields_1__c.split(','));
                if(!String.isBlank(manageForecastOverrideSettingsRec.Forecast_fields_2__c))
                    fieldNames.addAll(manageForecastOverrideSettingsRec.Forecast_fields_2__c.split(','));
        for (Opportunity opp:  opptys)
            {   
             // Throw a validation error when GSS user changes any of the Service fields and Oppty.SS = 6-Signed/Closed Admin/Closed Lost during Edit/update.
             if(opptyStageToOverride.contains(opp.stageName) && 
                     !opp.Validation_Override__c && !Trigger.isInsert){//Code-coverage
                if(Util.hasChanges(fieldNames,oppOldMap.get(opp.id),opp)){
                    opp.addError(manageForecastOverrideSettingsRec.Error_msg_on_fields_Change_6__c);//
                }
             }

             // After stage 6, Service overriden fields must be reverted back and overrides = false
             // Service Forecast Amount code :
             //will only get called in delete or update, as checks for prob.
             if(opptyStageToOverride.contains(opp.stageName))
             {     

                for(String mrrOverrideField : manageForecastOverrideSettingsRec.MRR_override__c.split(',')){//Code-coverage
                    opp.put(mrrOverrideField,false);//
                }
             }

             // Service Forecast CloseDate code
             if(opptyStageToOverride.contains(opp.stageName)  || (opp.get(manageForecastOverrideSettingsRec.Override_Close_Date__c)==false && ((Trigger.isinsert && 
                                 opp.get(manageForecastOverrideSettingsRec.Forecast_Close_date__c)==null) || (!Trigger.isInsert && oppOldMap.get(opp.id).get(manageForecastOverrideSettingsRec.Override_Close_Date__c)==false && opp.get(manageForecastOverrideSettingsRec.Forecast_Close_date__c) != opp.CloseDate && 
                                     opp.get(manageForecastOverrideSettingsRec.Forecast_Close_date__c) == oppOldMap.get(opp.id).get(manageForecastOverrideSettingsRec.Forecast_Close_date__c)))))//Code-coverage
             {
                 opp.put(manageForecastOverrideSettingsRec.Forecast_Close_date__c,opp.CloseDate);
                 opp.put(manageForecastOverrideSettingsRec.Override_Close_Date__c,false);
             }

             // Service Forecast Picklist code
             if(opptyStageToOverride.contains(opp.stageName)  || (opp.get(manageForecastOverrideSettingsRec.Override_Forecast_Category__c)==false && opp.ForecastCategoryName != null &&
                         ((Trigger.isInsert && opp.get(manageForecastOverrideSettingsRec.Forecast_Category__c)==null) || (!Trigger.isInsert && oppOldMap.get(opp.id).get(manageForecastOverrideSettingsRec.Override_Forecast_Category__c)==false && 
                             opp.get(manageForecastOverrideSettingsRec.Forecast_Category__c) != opp.ForecastCategoryName && opp.get(manageForecastOverrideSettingsRec.Forecast_Category__c) == oppOldMap.get(opp.id).get(manageForecastOverrideSettingsRec.Forecast_Category__c))))) //Code-coverage
             { 
                
                 opp.put(manageForecastOverrideSettingsRec.Forecast_Category__c, opp.ForecastCategoryName);
                 opp.put(manageForecastOverrideSettingsRec.Override_Forecast_Category__c,false);
             }

             manageForecastFirstRunFlag = false;

         }
       }
    }

    //SFDC -1453 - HC Logic shifted to handler class from Trigger
    public static void convertMRRToUSDMRRFields(Map<Id,Opportunity> mapOfOpptyIdToChangedCloseDateOpptys )
    {
    	if(!convertMRRToUSDMRRFieldsFirstRunFlag){
            return;
        }
        List<OpportunityLineItem> listOfLineItems = new List<OpportunityLineItem>();
        List<String> parameters = OpportunityUtilClass.buildSOQLParametersForUSDConversion('OpportunityLineItem');

        String soql =  new al.SoqlBuilder()
                       .selectx(parameters)
                       .fromx('OpportunityLineItem')
                       .wherex(new al.SetCondition('OpportunityId').inx(new List<Id>(mapOfOpptyIdToChangedCloseDateOpptys.keySet())))
                       .toSoql();

        listOfLineItems = Database.query(soql);
        listOfLineItems = OpportunityUtilClass.genericPopulateUSDOnChangeOfFields(listOfLineItems,true); 
        if(listOfLineItems.size()>0){
          update listOfLineItems;
        }
        convertMRRToUSDMRRFieldsFirstRunFlag = false;
	}
}