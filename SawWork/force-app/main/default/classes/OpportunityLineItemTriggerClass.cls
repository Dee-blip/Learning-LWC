/**
 * @description       : OpportunityLineItemTriggerClass  
 * @author            : apyati
 * @team              : GSM
 * @last modified on  : 09-02-2021
 * @last modified by  : apyati
 * Modifications Log
 * Ver   TAG    Date         Author   Modification                                                    
 * 1.0  <T01>   08-30-2021   apyati   SFDC-8809 Added  method to round up currency fields to 2 decimals  
**/
global class OpportunityLineItemTriggerClass implements Schedulable 
{   
    public static Boolean fromOpptyProdWizard=false;
    public static Boolean churnFutureMethodFlag = false;
    public static Boolean updateInvoiceMonthlyMRRMethodFirstRunFlag = true;
    public static Boolean handleProductNotificationsFirstRunFlag = true;
    public static Boolean postToChatterGroupFirstRunFlag=true;
    public static boolean firstRunspecialistcheck = true ; //SFDC-7057
    public static boolean firstRunszoffcheckInsert = true ; // Rajesh SFDC-7061
    public static boolean firstRunszoffcheckUpdate = true ; // Rajesh SFDC-7061




    /**
      updateForecastMRR(OpportunityLineItem[] pTriggerNew)
      @param: List of updated OLIs.
      - This method is only called from OLI triggers.
      - Update the Oppty-Prod.Forecast_MRR__c with Oppty-Prod.Forecast_MRR_RealTime__c on edit
      OR with Oppty-Product.MRR__c * Opportunity.Projected_Forecast_Factor__c
     */
    public static void updateForecastMRR(OpportunityLineItem[] pTriggerNew)
    {
        if (!GsmUtilClass.isFeatureToggleEnabledCustomMetadata('isOOTBForecastingEnabled')) //SFDC-2304
            return;
        if (Trigger.isInsert)
        {
            Set<Id> opptyIdSet = new Set<Id>();
            Map<Id, Double> opptyForecastFactorMap = new Map<Id,Double>();
            for (OpportunityLineItem oli : pTriggerNew)
            {
                opptyIdSet.add(oli.OpportunityId);
            }
            // fetch the Oppty's Projected Forecast Factor value
            for (Opportunity oppty : [Select Id, Name, Projected_Forecast_Factor__c from Opportunity where Id IN :opptyIdSet AND Projected_Forecast_Factor__c!=null])
            {
                opptyForecastFactorMap.put(oppty.Id, oppty.Projected_Forecast_Factor__c);
            }
            // update the Oppty-product forecast MRR.
            for (OpportunityLineItem oli : pTriggerNew)
            {
                oli.MRR__c = oli.UnitPrice;
                if (oli.NRR__c==null)
                    oli.NRR__c = 0;
                if (oli.Reseller_Retail_Price__c==null)
                    oli.Reseller_Retail_Price__c = 0;
                //if ( opptyForecastFactorMap.size()>0 && opptyForecastFactorMap.containsKey(oli.OpportunityId))
                // oli.UnitPrice = oli.MRR__c * opptyForecastFactorMap.get(oli.OpportunityId);
                if ( opptyForecastFactorMap.size()>0 && opptyForecastFactorMap.containsKey(oli.OpportunityId))
                    oli.Forecast_MRR__c = oli.UnitPrice * opptyForecastFactorMap.get(oli.OpportunityId);
                else
                    oli.Forecast_MRR__c=0;
            }
        }
        else if (Trigger.isUpdate)
        {
            // simply update the Oppty-product forecast MRR = forecast real time.
            for (OpportunityLineItem oli : pTriggerNew)
            {
                if (oli.NRR__c==null)
                    oli.NRR__c = 0;
                if (oli.Reseller_Retail_Price__c==null)
                    oli.Reseller_Retail_Price__c = 0;
                oli.MRR__c = oli.UnitPrice;
                oli.Forecast_MRR__c = oli.Forecast_MRR_Realtime__c;

            }
        }
    }

    /**
      fixOpptyProducts()
      @param: NA
      @return: Returns the list of OLIs fixed.
      - This method is entry point for CronJobs, that may be setup to fix Oppty-Product.Forecast MRR
      - Here we pick all related OLIs considering Oppty's CloseDate AND SalesStage.
     */
    public static String fixOpptyProducts()
    {
        // If Feature is OFF, return disabled message.
        if (!GsmUtilClass.isFeatureToggleEnabledCustomMetadata('isOOTBForecastingEnabled')) //SFDC-2304
            return GsmUtilClass.featureToggleMsg('isOOTBForecastingEnabled'); //SFDC-2304

        Integer OPP_CLOSED_DATE_UPPER_LIMIT_MONTHS = Integer.valueOf(GsmUtilClass.getGSMSettingValue('Forecasting_OLIFixUpperLimitMonths')); //SFDC-2304
        Integer OPP_CLOSED_DATE_LOWER_LIMIT_DAYS = Integer.valueOf(GsmUtilClass.getGSMSettingValue('Forecasting_OLIFixLowerLimitDays')); //SFDC-2304
        String[] OPP_SALES_STAGE_EXEMPTED_LIST = GsmUtilClass.getGSMSettingValue('Forecasting_ExemptedSalesStage').split(','); //SFDC-2304
        // Should we only sync up new OLIs i.e. o.Recurring__c = 'MRR', currently it syncs up all of them implying if there is no datafix before forecasting is enabled it will mess up old oli products.
        List<OpportunityLineItem> toUpdateOpptyLineItemsList = [SELECT o.UnitPrice, o.Forecast_MRR__c, o.Opportunity.Projected_Forecast_Factor__c, o.Opportunity.CreatedDate,
            o.Opportunity.CloseDate, o.OpportunityId, o.MRR__c, o.Id, o.Forecast_MRR_Realtime__c, o.Validation_Override__c FROM OpportunityLineItem o
                WHERE o.Opportunity.StageName NOT IN :OPP_SALES_STAGE_EXEMPTED_LIST AND o.Opportunity.CloseDate >= :Date.today().addDays(-1*OPP_CLOSED_DATE_LOWER_LIMIT_DAYS)
                AND o.Opportunity.CloseDate <= :Date.today().addMonths(OPP_CLOSED_DATE_UPPER_LIMIT_MONTHS) LIMIT 750];//WHERE o.Opportunity.CloseDate > LAST_90_DAYS LIMIT 9000];
        return updateOLIForecastMRRFunction(toUpdateOpptyLineItemsList);
    }

    /**
      updateOLIForecastMRRFunction()
      - Used to update the Oppty-Product.UnitPrice based on the Oppty-Product.Forecast_MRR_Realtime__c formula field value.
      - Depends on following fields:
      -> Oppty-Product.Forecast_MRR_Realtime__c
      -> Oppty.Projected_Forecast_Factor__c
     */
    /**
      updateOLIForecastMRRFunction(OpportunityLineItem[] pToUpdateOpptyLineItemsList)
      @param: pToUpdateOpptyLineItemsList; list of OLIs to be fixed.
      @return: Returns the list of OLIs fixed.
      - This method triggers the OLI fix that will update the Oppty-Prod.Forecast MRR
     */
    public static String updateOLIForecastMRRFunction(OpportunityLineItem[] pToUpdateOpptyLineItemsList)
    {
        // If Feature is OFF, return disabled feature message.
        if (!GsmUtilClass.isFeatureToggleEnabledCustomMetadata('isOOTBForecastingEnabled')) //SFDC-2304
            return GsmUtilClass.featureToggleMsg('isOOTBForecastingEnabled'); //SFDC-2304


        String result = '1:There are no OpportunityLineItem record(s) to be fixed.';
        String strOLIFixedInfo = '\n OLI Ids: ';
        List<OpportunityLineItem> toFixOpptyLineItemsList = new List<OpportunityLineItem>();

        for (OpportunityLineItem oli : pToUpdateOpptyLineItemsList)
        {
            if (oli.Forecast_MRR__c!=oli.Forecast_MRR_Realtime__c)
            {
                oli.Validation_Override__c=true;
                toFixOpptyLineItemsList.add(oli);
                strOLIFixedInfo+= oli.id + ';';
            }
        }

        if (toFixOpptyLineItemsList.size()<1)
            return result;

        result = '1:Success: Total OpportunityLineItem record(s) fixed= ' + toFixOpptyLineItemsList.size() + '. ' + strOLIFixedInfo;

        /*try
          {
        //update toFixOpptyLineItemsList;
        } catch (Exception ex)
        {
        result = '0:Failure: Following error occured during OpportunityLineItem data fix:\n' + ex.getMessage() + strOLIFixedInfo;
        }
         */
        Database.SaveResult[] results = Database.update(toFixOpptyLineItemsList, false);
        Integer i=0;
        String strErrorLog = '\nError Log:';
        for(Database.SaveResult sr:results)
        {
            if(!sr.isSuccess())
            {
                String Id=toFixOpptyLineItemsList[i].Id;
                strErrorLog += sr.getErrors()[0]+' SF ID: '+Id+'\n';
            }
            i++;
        }
        if (strErrorLog!='\nError Log:')
            result+=strErrorLog;

        System.debug('toFixOpptyLineItemsList=' + toFixOpptyLineItemsList);
        System.debug('result afer update=' + result);

        return result;
    }

    /**
      execute()
      - Used to invoke fixOpptyProducts() via a scheduled job.
     */
    global void execute(SchedulableContext sc)
    {
        fixOpptyProducts();
    }
    /**
      checkIfPartnerEligibleForDelete()
      - Used for checking partners eligibility to delete a opportunity product for CR 1666876
     */

    public static void checkIfPartnerEligibleForDelete(List<OpportunityLineItem> opptyLineItemListOld)
    {
        List<Id> opptyIds=new List<Id>();
        for(OpportunityLineItem oli : opptyLineItemListOld)
        {
            opptyIds.add(oli.OpportunityId);
        }
        List<Opportunity> oportunityList=[select Id,Account.OwnerIDAlt__r.Profile.Name from Opportunity where id IN :opptyIds];
        Map<Id,String> opptyIdAccountOwnerProfileNameMap=new Map<Id,String>();
        for(Opportunity opp: oportunityList)
        {
            opptyIdAccountOwnerProfileNameMap.put(opp.Id,opp.Account.OwnerIDAlt__r.Profile.Name);
        }
        for (OpportunityLineItem oli : opptyLineItemListOld)
        {
            if(opptyIdAccountOwnerProfileNameMap.get(oli.OpportunityId)!=GsmUtilClass.getGSMSettingValue('OpptyLineItemTrigger_PAEProfileName')) //SFDC-2304
            {
                oli.addError(GsmUtilClass.getGSMSettingValue('OpptyLineItems_ManageProductsError')); //SFDC-2304
            }
        }
    }

    /*CR 2345466: Added method checkOpptyChurnFieldsRemoval()
      Input Parameters: List of Opportunity Ids from Trigger.
      Return values: None.
Functionality:
-> Find all Oppty which do not satisfy the churn conditions for the Id set passed from the trigger.
-> For all these Oppty, find the associated Oppty-Prod (OpptyLineItem)
-> If there are no negative products associated with the Oppty Ids which do not satisy Churn conditions, clean up all the churn fields.
     */

    public static void checkOpptyChurnFieldsRemoval(List<String> oppIdList)
    {
        checkOpptyChurnFieldsRemovalFutureInvoke(oppIdList);
    }

    @future
    public static void checkOpptyChurnFieldsRemovalFutureInvoke(List<String> oppIdList)
    {
        Set<Id> oppIdSet = new Set<Id>();
        Map<Id,List<OpportunityLineItem>> opptyIdProdListMap = new Map<Id,List<OpportunityLineItem>>();
        List<Opportunity> updateOpptyList = new List<Opportunity>();
        Boolean negProdPresent = false;

        for(Opportunity o: [SELECT Id, Name, Zero_MRR_Amount__c, Churn_No_Paper__c, StageName FROM Opportunity
                WHERE Id IN :oppIdList])
        {
            if(o.Zero_MRR_Amount__c !='Zero MRR Contract Ended'
                    && o.Churn_No_Paper__c==false
                    && o.StageName != 'Closed Lost' && o.StageName != 'Closed Contract Ended' && o.StageName != 'Closed Duplicate')
                oppIdSet.add(o.Id);
        }
        for(OpportunityLineItem OLI : [SELECT Id, UnitPrice, OpportunityId FROM OpportunityLineItem
                WHERE OpportunityId IN :oppIdSet])
        {
            if(opptyIdProdListMap.get(OLI.OpportunityId)==null)
                opptyIdProdListMap.put(OLI.OpportunityId,new List<OpportunityLineItem>());

            opptyIdProdListMap.get(OLI.OpportunityId).add(OLI);
        }
        System.debug('+++opptyIdProdListMap '+opptyIdProdListMap);

        for(Id opptyId : oppIdSet)
        {
            negProdPresent = false;
            if(opptyIdProdListMap.get(opptyId)!=null && opptyIdProdListMap.get(opptyId).size() > 0)
            {
                for(OpportunityLineItem oli: opptyIdProdListMap.get(opptyId))
                {
                    if(oli.UnitPrice < 0)
                        negProdPresent=true;
                }
            }
            if(negProdPresent==false)
            {
                // SFDC-3256 - Agility2.0 - Updating Loss reasons, Removing Subcategory, Unacceptable, Initial Out and Missing product feature fields
                Opportunity o = new Opportunity(Id=opptyId);
                o.Opportunity_Category__c=null;
                o.Loss_Reason__c=null;
                // o.Competitor__c=null;( CR 2737416 change[Competitor Primary field blanking out when Oppty p])
                o.Consolidation_Account__c=null;
                o.Aggregation_Partner__c=null;
                o.Duplicate_Opportunity__c=null;
                o.Validation_Override__c=true;
                updateOpptyList.add(o);
            }
        }
        if(updateOpptyList.size() > 0)
        {
            churnFutureMethodFlag = true;
            update updateOpptyList;
        }
    }


    public static void checkClosedOpptyProdDeletion(Map<Id,OpportunityLineItem> p_deletedProductMap)
    {
        Map<Id,String> oaIdOpptyStageMap = new Map<Id,String>();
        String deletionErrorMessage = GsmUtilClass.getGSMSettingValue('OpptyLineItemTrigCls_delErrMsg'); //SFDC-2304
        String akamaiOpptyRecordTypeId = GsmUtilClass.getGSMSettingValue('OpptyTrigger_AkamaiOpptyRecType'); //SFDC-2304
        String exceptionProfileIds = GsmUtilClass.getGSMSettingValue('OppLineItemTrigCls_delExcptProfId'); //SFDC-2304
        String closedOpptyRecordTypeId = GsmUtilClass.getGSMSettingValue('Oppty_Closed_Oppty_Rec_Type_Id'); //SFDC-3261

        if(!exceptionProfileIds.contains(UserInfo.getProfileId()))
        {
            for(OpportunityLineItem oli: [SELECT Id, Opportunity.StageName, Opportunity.CloseDate, Opportunity.RecordTypeId FROM OpportunityLineItem WHERE Id IN: p_deletedProductMap.keyset()])
            {
                //oaIdOpptyStageMap.put(oli.Id,oli.Opportunity.StageName);
                //SFDC-3261
                if(oli.Opportunity.StageName.contains('Closed') && (String.ValueOf(oli.Opportunity.RecordTypeId).contains(akamaiOpptyRecordTypeId) || String.ValueOf(oli.Opportunity.RecordTypeId).contains(closedOpptyRecordTypeId)))
                {
                    //oli.addError(deletionErrorMessage);
                    //throw new customException(deletionErrorMessage);
                    p_deletedProductMap.get(oli.Id).addError(deletionErrorMessage);
                }
            }
        }
    }

    //Aggregate of all the Opportunity line Item Monthly Usage/Commit values to copy it to Opportunity Total Invoiced Monthly Amount USD
    public static Map<Id,Opportunity> updateInvoiceMonthlyMRRMethod(List<OpportunityLineItem> opptyLineItemList,Map<Id,Opportunity> opptyMap)
    {
        if(!updateInvoiceMonthlyMRRMethodFirstRunFlag)
        return opptyMap;



        List<Id> listOfOpportunityIds = new List<Id>();
        List<Opportunity> opptyList = new List<Opportunity>();
        system.Debug('OpptyMap  :'+opptyMap);
        for(OpportunityLineItem opptyLIRecord : opptyLineItemList)
        {
            listOfOpportunityIds.add(opptyLIRecord.OpportunityId);
            opptyList.add(OpportunityUtilClass.getOpportunityRecord(opptyMap,opptyLIRecord.OpportunityId));

        }

        if(listOfOpportunityIds.size() > 0)
        {
            //Get all the Opporutiny Line Items Associated with Opportunity since we need to calcluate the Sum of all the records rather only the one coming from Opportunity line Item
            List<OpportunityLineItem> opptyLIList = [Select Id,OpportunityId,Average_Renewal_Commit_MRR_USD__c,Average_Renewal_Usage_MRR_USD__c From  OpportunityLineItem Where OpportunityId  IN :listOfOpportunityIds];

// Comment from Chandra : Below query not needed for inistantiating opptyList, Commenting below query
            //for(Opportunity opp : [select Id, Total_Invoiced_Monthly_Amount_USD__c  from Opportunity where Id in :listOfOpportunityIds])
            for(Opportunity opp : oppTyList)            
            {
                Decimal sumTotalInvoicedMonthlyAmountUSD = 0;
                for(OpportunityLineItem opptyLI :opptyLIList)
                {
                    if(opptyLI.OpportunityId == opp.Id)
                    {

                        system.Debug('Field  '+opptyLI.Average_Renewal_Usage_MRR_USD__c  + '    '+opptyLI.Average_Renewal_Commit_MRR_USD__c);
                        if(opptyLI.Average_Renewal_Usage_MRR_USD__c != null)
                            sumTotalInvoicedMonthlyAmountUSD =  sumTotalInvoicedMonthlyAmountUSD + opptyLI.Average_Renewal_Usage_MRR_USD__c;
                        if(opptyLI.Average_Renewal_Commit_MRR_USD__c != null)
                            sumTotalInvoicedMonthlyAmountUSD = sumTotalInvoicedMonthlyAmountUSD + opptyLI.Average_Renewal_Commit_MRR_USD__c;
                    }
                }
                opp.Total_Invoiced_Monthly_Amount_USD__c = sumTotalInvoicedMonthlyAmountUSD;
                opp.Validation_Override__c = true;
                opptyMap.put(opp.Id,opp);            
            }
        }
        /*if(opptyList.size() > 0)
        {//removed DML as part of SFDC-8958 to optimize Opportunitylineitem insertion.     
            //update opptyList;
           opptySet.addAll(opptyList);
        }*/
        updateInvoiceMonthlyMRRMethodFirstRunFlag = false;
        return opptyMap;
    }

    /* //CR 2891568 and 2948870: : Need an amount field for "Strategic Net MRR"
       --> Put MRR ('MRR in Dollar’ -> MRR_in_Dollar__c) and MRR__c of all line items , except line item having forecast group ‘Media’ but include 'Media & Delivery - Dynamic Site Delivery' to Strategic MRR USD and Strategic MRR field respectively.
     */
    public static void populateStrategicNetMRR(List<OpportunityLineItem> lineItemSet){

        if(lineItemSet!=null && lineItemSet.size()>0){

            String exclusionForecastGroup = GsmUtilClass.getGSMSettingValue('OppLineItem_ExcludedForecastGroup'); //SFDC-2304
            Set<String> exclusionList= new Set<String>();
            if(exclusionForecastGroup!= null ){
                exclusionList.addAll(exclusionForecastGroup.split(','));
            }
            Set<String> specificInclusionList= new Set<String>();
            String specificInclusionProduct = GsmUtilClass.getGSMSettingValue('OppLineItem_specificInclusionList'); //SFDC-2304
            if(specificInclusionProduct!= null ){
                specificInclusionList.addAll(specificInclusionProduct.split(','));
            }
            System.debug('lineItemlist: '+lineItemSet+' lineItemSet.size(): '+lineItemSet.size());

            for(OpportunityLineItem lineItem: lineItemSet){
                System.debug('product pFamily: '+lineItem.Forecast_Group__c+' Product_Name__c: '+lineItem.Product_Name__c);
                //check if the line item forecast group is not media and if it is media then its name is not 'Media & Delivery - Dynamic Site Delivery'
                if(!exclusionList.contains(lineItem.Forecast_Group__c) || specificInclusionList.contains(lineItem.Product_Name__c)){
                    //SFDC-1453
                    //if(lineItem.MRR_in_Dollar__c!=null)
                    //    lineItem.Strategic_MRR_USD__c = lineItem.MRR_in_Dollar__c;
                    if(lineItem.MRR__c!=null)
                        lineItem.Strategic_MRR__c = lineItem.MRR__c;
                }
            }
        }
    }
    /*
       Adding the logic to remove the extra digit after specified decimal format.for example if the MRR comes in
       following form -0.009, -0.0004etc it will be rounded out to 0.00(<Rahul Gaira>)
     */
    public static void formatDecimalPlaceMRR(List<OpportunityLineItem> NewOli){
        if(NewOli != null && !NewOli.isEmpty()){
            for(OpportunityLineItem oli : NewOli){
                if(Oli.UnitPrice != null && Oli.UnitPrice <0){
                    if(Oli.UnitPrice.Abs() * 1000 < 10){
                        Oli.UnitPrice =0  ;
                    }

                }

            }
        }

    }


    //-------------------------<T01>
    /*
       Adding the logic to round up all currency fields tp 2 decimals 
       following form 100.1245 - 100.12, 46.8995 - 46.90(<apyati>)
     */
    public static void roundUpCurrency2Decimals(List<OpportunityLineItem> NewOli){

        if(NewOli != null && !NewOli.isEmpty()){

            for(OpportunityLineItem oli : NewOli){

                //currency fields
                oli.Reseller_Retail_Price__c= oli.Reseller_Retail_Price__c != null ? oli.Reseller_Retail_Price__c.setScale(2, RoundingMode.HALF_UP) : null;
                oli.Revenue_Impact2__c= oli.Revenue_Impact2__c != null ? oli.Revenue_Impact2__c.setScale(2, RoundingMode.HALF_UP) : null;
                oli.Average_Renewal_Usage_MRR_USD__c= oli.Average_Renewal_Usage_MRR_USD__c != null ? oli.Average_Renewal_Usage_MRR_USD__c.setScale(2, RoundingMode.HALF_UP) : null;
                oli.Average_Renewal_Commit_MRR_USD__c= oli.Average_Renewal_Commit_MRR_USD__c != null ? oli.Average_Renewal_Commit_MRR_USD__c.setScale(2, RoundingMode.HALF_UP) : null;
                oli.Average_Renewal_Usage_MRR__c= oli.Average_Renewal_Usage_MRR__c != null ? oli.Average_Renewal_Usage_MRR__c.setScale(2, RoundingMode.HALF_UP) : null;
                oli.Average_Renewal_Commit_MRR__c= oli.Average_Renewal_Commit_MRR__c != null ? oli.Average_Renewal_Commit_MRR__c.setScale(2, RoundingMode.HALF_UP) : null;
                oli.Projected_Monthly_commit_fees__c= oli.Projected_Monthly_commit_fees__c != null ? oli.Projected_Monthly_commit_fees__c.setScale(2, RoundingMode.HALF_UP) : null;
                oli.Projected_Avg_Rev_Non_Commit__c= oli.Projected_Avg_Rev_Non_Commit__c != null ? oli.Projected_Avg_Rev_Non_Commit__c.setScale(2, RoundingMode.HALF_UP) : null;
                oli.Net_Non_Commit__c= oli.Net_Non_Commit__c != null ? oli.Net_Non_Commit__c.setScale(2, RoundingMode.HALF_UP) : null;
                oli.MRR__c= oli.MRR__c != null ? oli.MRR__c.setScale(2, RoundingMode.HALF_UP) : null;
                oli.Forecast_MRR__c= oli.Forecast_MRR__c != null ? oli.Forecast_MRR__c.setScale(2, RoundingMode.HALF_UP) : null;
                oli.NRR__c= oli.NRR__c != null ? oli.NRR__c.setScale(2, RoundingMode.HALF_UP) : null;
                oli.LMRR__c= oli.LMRR__c != null ? oli.LMRR__c.setScale(2, RoundingMode.HALF_UP) : null;
                oli.EMRI__c= oli.EMRI__c != null ? oli.EMRI__c.setScale(2, RoundingMode.HALF_UP) : null;
                oli.Strategic_MRR__c= oli.Strategic_MRR__c != null ? oli.Strategic_MRR__c.setScale(2, RoundingMode.HALF_UP) : null;
                oli.Specialist_NRR__c= oli.Specialist_NRR__c != null ? oli.Specialist_NRR__c.setScale(2, RoundingMode.HALF_UP) : null;
                oli.Specialist_Projected_Monthly_Usage__c= oli.Specialist_Projected_Monthly_Usage__c != null ? oli.Specialist_Projected_Monthly_Usage__c.setScale(2, RoundingMode.HALF_UP) : null;
                oli.Specialist_Projected_Monthly_Commit__c= oli.Specialist_Projected_Monthly_Commit__c != null ? oli.Specialist_Projected_Monthly_Commit__c.setScale(2, RoundingMode.HALF_UP) : null;

                //number fields storing currency values
                oli.Product_Weighted_MRR_USD__c= oli.Product_Weighted_MRR_USD__c != null ? oli.Product_Weighted_MRR_USD__c.setScale(2, RoundingMode.HALF_UP) : null;
                oli.Product_CCV_USD__c= oli.Product_CCV_USD__c != null ? oli.Product_CCV_USD__c.setScale(2, RoundingMode.HALF_UP) : null;
                oli.Specialist_Net_MRR_USD__c= oli.Specialist_Net_MRR_USD__c != null ? oli.Specialist_Net_MRR_USD__c.setScale(2, RoundingMode.HALF_UP) : null;
                oli.Projected_Monthly_Usage_USD__c= oli.Projected_Monthly_Usage_USD__c != null ? oli.Projected_Monthly_Usage_USD__c.setScale(2, RoundingMode.HALF_UP) : null;
                oli.Projected_Monthly_Commit_USD__c= oli.Projected_Monthly_Commit_USD__c != null ? oli.Projected_Monthly_Commit_USD__c.setScale(2, RoundingMode.HALF_UP) : null;
                oli.Net_Monthly_Usage_USD__c= oli.Net_Monthly_Usage_USD__c != null ? oli.Net_Monthly_Usage_USD__c.setScale(2, RoundingMode.HALF_UP) : null;
                oli.EMRI_USD__c= oli.EMRI_USD__c != null ? oli.EMRI_USD__c.setScale(2, RoundingMode.HALF_UP) : null;
                oli.Strategic_MRR_USD__c= oli.Strategic_MRR_USD__c != null ? oli.Strategic_MRR_USD__c.setScale(2, RoundingMode.HALF_UP) : null;
                oli.NRR_in_Dollar__c= oli.NRR_in_Dollar__c != null ? oli.NRR_in_Dollar__c.setScale(2, RoundingMode.HALF_UP) : null;
                oli.MRR_in_Dollar__c= oli.MRR_in_Dollar__c != null ? oli.MRR_in_Dollar__c.setScale(2, RoundingMode.HALF_UP) : null;
                oli.Specialist__c= oli.Specialist__c != null ? oli.Specialist__c.setScale(2, RoundingMode.HALF_UP) : null;
                oli.Specialist_Projected_Monthly_Usage_USD__c= oli.Specialist_Projected_Monthly_Usage_USD__c != null ? oli.Specialist_Projected_Monthly_Usage_USD__c.setScale(2, RoundingMode.HALF_UP) : null;
                oli.Specialist_NRR_USD__c= oli.Specialist_NRR_USD__c != null ? oli.Specialist_NRR_USD__c.setScale(2, RoundingMode.HALF_UP) : null;


            }
        }
    }
    //---------------------------</T01>


    // SFDC-3933 Notifications -  Added By Prabhanjan

    public static void sendEmailGeneric(List<EmailTemplate> lstEmailTemplates,list<String> recepients,OpportunityLineItem oli,List<Messaging.SingleEmailMessage> mailingList){
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setTemplateId(lstEmailTemplates[0].Id);
        mail.setSaveAsActivity(false);
        mail.setTargetObjectId(oli.Opportunity_Owner__c);
        mail.setTreatTargetObjectAsRecipient(false);
        mail.setToAddresses(recepients);
        mail.setWhatId(oli.Id);
        mailingList.add(mail);
    }

    public static void handleProductNotifications(List<opportunityLineItem> opportunityLineItems)
    {

        if(!OpportunityLineItemTriggerClass.handleProductNotificationsFirstRunFlag)
            return;


        Set<Id> opptyIdSet = new set<Id>();
        Set<Id> opptyLineItemIdSet=new Set<Id>();
        for(OpportunityLineItem oli: opportunityLineItems)
        {
            opptyIdSet.add(oli.OpportunityId);
            opptyLineItemIdSet.add(oli.Id);
        }

        Map <String, Object> jsonValue = (Map <String, Object>) JSON.deserializeUntyped(GSMSettings.getValue('EmailTemplateToATM_JSON'));

        Set<String> emailTemplateUniqueNames = jsonValue.keySet();
        List<Object> accountTeamMembers = jsonValue.values();
        List<String> accountTeamMemberValues = new List<String>();
        for(Object obj : accountTeamMembers){
            accountTeamMemberValues.add(String.valueOf(obj));
        }

        List<EmailTemplate> lstEmailTemplates = [Select Id, Body, Subject, Name from EmailTemplate where DeveloperName in :emailTemplateUniqueNames];
        Map<String,List<EmailTemplate>> emailTemplateMap = new Map<String,List<EmailTemplate>>();
        for(EmailTemplate et : lstEmailTemplates){
            emailTemplateMap.put(et.Name,new List<EmailTemplate>{et});
        }
        List<Profile> profile = [SELECT Id, Name FROM Profile WHERE Id=:userinfo.getProfileId() LIMIT 1];
        String profileName = profile[0].Name;

        List<Opportunity> opptys = [Select id, AccountId, Probability,DPM_Specialist__r.Product_Specialist__r.Email,Security_Specialist__r.Product_Specialist__r.Email, (select Product_Name__c,Forecast_Group__c,OpportunityId,Opportunity_Owner__c from opportunitylineitems where Id not in :opptyLineItemIdSet) from opportunity where Id in :opptyIdSet];
        List<Messaging.SingleEmailMessage> mailingList = new List<Messaging.SingleEmailMessage>();

        Map<String, Set<Id>> forecastGroupToOpptyIds = new Map<String, Set<Id>>();
        Map<Id,Id>opptyIdToAccountId=new Map<Id,Id>();
        Map<Id, Decimal> opptyIdToProbablity=new Map<Id,Decimal>();
        Map<Id,String> opptyidToDpmEmailList = new Map<Id,String>();
        Map<Id,String> opptyidToSecuritySpecialistEmail = new Map<Id,String>();

        for(Opportunity opp: opptys)
        {
            opptyIdToAccountId.put(opp.Id, opp.AccountId);
            opptyIdToProbablity.put(opp.Id, opp.Probability);

            if(opp.DPM_Specialist__r.Product_Specialist__r.Email != null){
                opptyidToDpmEmailList.put(opp.Id,opp.DPM_Specialist__r.Product_Specialist__r.Email);
            }

            if(opp.Security_Specialist__r.Product_Specialist__r.Email != null){
                opptyidToSecuritySpecialistEmail.put(opp.Id,opp.Security_Specialist__r.Product_Specialist__r.Email);
            }


            for(OpportunityLineItem oli :opp.opportunitylineitems)
            {
                if(forecastGroupToOpptyIds.containsKey(oli.OpportunityId))
                {
                    forecastGroupToOpptyIds.get(oli.Forecast_Group__c).add(oli.OpportunityId);
                }
                else
                {
                    forecastGroupToOpptyIds.put(oli.Forecast_Group__c, new Set<Id>{oli.OpportunityId});
                }
            }
        }

        Map<String, List<String>> accountIdToATMEmailList = new Map<String, List<String>>();
        for(AccountTeamMember atm: [Select User.Email,AccountId, TeamMemberRole from AccountTeamMember where AccountId in :opptyIdToAccountId.values() and TeamMemberRole in : accountTeamMemberValues])
        {
            String key = atm.AccountId + '#'+atm.TeamMemberRole;
            if(accountIdToATMEmailList.containsKey(key))
            {
                accountIdToATMEmailList.get(key).add(atm.User.Email);
            }
            else
            {
                accountIdToATMEmailList.put(key, new List<String>{atm.user.Email});
            }
        }

        // outside for loop
        for(OpportunityLineItem newoli : opportunityLineItems)
        {
            Decimal opptyProbability = opptyIdToProbablity.get(newoli.OpportunityId);
            Id accountId = opptyIdToAccountId.get(newoli.OpportunityId);

            if(opptyProbability >=10 && ((forecastGroupToOpptyIds.containsKey(newoli.Forecast_Group__c) && !forecastGroupToOpptyIds.get(newoli.Forecast_Group__c).contains(newoli.OpportunityId)) || !forecastGroupToOpptyIds.containsKey(newoli.Forecast_Group__c)))
            {

                if(newoli.Forecast_Group__c.contains('Security'))
                {
                    if(accountIdToATMEmailList.containsKey(accountId +'#' + accountTeamMemberValues.get(0)))
                    {
                        sendEmailGeneric(emailTemplateMap.get('OpportunityUpdate_ESA'),accountIdToATMEmailList.get(accountId+'#' + accountTeamMemberValues.get(0)),newoli,mailingList);
                    }
                }

                if(newoli.Forecast_Group__c.contains('Enterprise'))
                {
                    if(accountIdToATMEmailList.containsKey(accountId +'#' + accountTeamMemberValues.get(1)))
                    {
                        sendEmailGeneric(emailTemplateMap.get('OpportunityUpdate_ESE'),accountIdToATMEmailList.get(accountId + '#' + accountTeamMemberValues.get(1)),newoli,mailingList);
                    }
                }


                if(GSMSettings.getValue('WebPerformanceArchitect_Products').contains(newoli.Product_Name__c))
                {
                    if(accountIdToATMEmailList.containsKey(accountId +'#' + accountTeamMemberValues.get(2)))
                    {
                        sendEmailGeneric(emailTemplateMap.get('OpportunityUpdate_WPA'),accountIdToATMEmailList.get(accountId + '#'+ accountTeamMemberValues.get(2)),newoli,mailingList);
                    }
                }
            }

            if(!profileName.contains('Sales - ATG') && (GSMSettings.getValue('WebPerformanceArchitect_Products').contains(newoli.Product_Name__c))){
                if(opptyidToDpmEmailList.containsKey(newoli.OpportunityId)){
                    sendEmailGeneric(emailTemplateMap.get('OpportunityUpdate_WPA'),new list<String>{opptyidToDpmEmailList.get(newoli.OpportunityId)},newoli,mailingList);
                }
            }

            if(!profileName.contains('Sales - ATG') && newoli.Product_Name__c.contains('Web Security')){
                if(opptyidToSecuritySpecialistEmail.containsKey(newoli.OpportunityId)){
                    sendEmailGeneric(emailTemplateMap.get('OpportunityUpdate_ESA'),new list<String>{opptyidToSecuritySpecialistEmail.get(newoli.OpportunityId)},newoli,mailingList);
                }
            }
        }

        handleProductNotificationsFirstRunFlag = false;
        Messaging.SendEmailResult[] resultMail = Messaging.sendEmail(mailingList);
    }

    public static void insertOSPARecords(List<OpportunityLineItem> olisForOSPA) {
        Set<Id> oppIds = new Set<id>();
        for(OpportunityLineItem oli : olisForOSPA)
        {
            oppIds.add(oli.OpportunityId);
        }

        String akamaiOpptyRecordTypeId =
            GsmUtilClass.getGSMSettingValue('OpptyTrigger_AkamaiOpptyRecType');
        //Map<Id,Set<Id>> oppSalesPlayMap = new Map<Id,Set<Id>>();
        Map<Id,Set<String>> oppProductsMap = new Map<Id,Set<String>>();
        Map<Id,Id> oppAccMap = new Map<Id,Id>();
        Map<Id,Set<Id>> accSalesPlayMap = new Map<Id,Set<Id>>();
        Map<Id,List<Id>> salesPlayProductsMap = new Map<Id,List<Id>>();
        Set<Id> salesPlayRecIds;
        String prodIds;
        Set<String> oppProdIds;
        Set<String> opportunityProdIds = new Set<String>();
        Set<Id> accIds = new Set<Id>();
        Map<Id,Set<String>> OSPAOppProductsMap = new Map<Id,Set<String>>();
        List<Opportunity_Sales_Play_Association__c> OSPAList =
            new List<Opportunity_Sales_Play_Association__c>();
        Opportunity_Sales_Play_Association__c OSPAObj;
        Map<String,Id> existingOSPARecsMap = new Map<String,Id>();


        List<OpportunityLineItem> oppLineItemList = [Select product2Id__c, OpportunityId,
            Opportunity.AccountId from
                OpportunityLineItem where OpportunityId in :oppIds AND
                Opportunity.isClosed = false];
        if(oppLineItemList.size() > 0){
            for(OpportunityLineItem oli : oppLineItemList) {
                accIds.add(oli.Opportunity.AccountId);
                opportunityProdIds.add(oli.product2Id__c);
                oppAccMap.put(oli.OpportunityId, oli.Opportunity.AccountId);
                oppProdIds = new Set<String>();
                if(oppProductsMap.get(oli.OpportunityId) == null) {
                    oppProdIds.add(oli.product2Id__c);
                    oppProductsMap.put(oli.OpportunityId,oppProdIds);
                } else {
                    oppProductsMap.get(oli.OpportunityId).add(oli.Product2Id__c);
                }
            }

            for(Account_Sales_Play_Association__c ASPARec : [Select Id, Account__c, Sales_Play__c,
                    Sales_Play__r.Product_Id__c from
                    Account_Sales_Play_Association__c where
                    Account__c in :accIds]) {
                if(accSalesPlayMap.get(ASPARec.Account__c) == null) {
                    accSalesPlayMap.put(ASPARec.Account__c,new Set<Id>{ASPARec.Sales_Play__c});
                } else {
                    accSalesPlayMap.get(ASPARec.Account__c).add(ASPARec.Sales_Play__c);
                }
                if(ASPARec.Sales_Play__c!=null && ASPARec.Sales_Play__r.Product_Id__c!=null)
                    salesPlayProductsMap.put(ASPARec.Sales_Play__c,ASPARec.Sales_Play__r.Product_Id__c.split(','));
                    }

            if(accSalesPlayMap.size() > 0) {

                for(Opportunity_Sales_Play_Association__c OSPARec : [Select Id,Opportunity__c,Account__c,
                        Sales_Play__r.Product_Id__c,
                        Sales_Play__c from
                        Opportunity_Sales_Play_Association__c
                        where Opportunity__c in: oppIds]) {
                    existingOSPARecsMap.put(String.valueof(OSPARec.Opportunity__c)+
                            String.valueof(OSPARec.Sales_Play__c),
                            OSPARec.Id);
                        }

                system.debug('oppProductsMap = '+oppProductsMap);
                system.debug('salesPlayProductsMap = '+salesPlayProductsMap);
                system.debug('accSalesPlayMap = '+accSalesPlayMap);
                system.debug('OSPAOppProductsMap = '+OSPAOppProductsMap);


                for(Id opportunityId : oppIds) {
                    Set<String> opportunityProductIds = new Set<String>();
                    opportunityProductIds = oppProductsMap.get(opportunityId);
                    system.debug('opportunityProductIds = '+opportunityProductIds);
                    system.debug('opportunityId = '+opportunityId);
                    Id AccountId = oppAccMap.get(opportunityId);
                    for (Id salesPlayId : accSalesPlayMap.get(AccountId)) {
                        if(!existingOSPARecsMap.containsKey(String.valueOf(opportunityId)+
                                    String.valueOf(salesPlayId))) {
                            List<Id> prdIds = salesPlayProductsMap.get(salesPlayId);
                            for(String oppPrdId : opportunityProductIds) {

                                if(prdIds!=null && prdIds.contains(oppPrdId)) {
                                    OSPAObj = new Opportunity_Sales_Play_Association__c();
                                    OSPAObj.Opportunity__c = opportunityId;
                                    OSPAObj.Sales_Play__c = salesPlayId;
                                    OSPAObj.Account__c = AccountId;
                                    OSPAList.add(OSPAObj);
                                    Break;
                                }
                            }
                                    }
                    }
                }
            }

            if(OSPAList.size() > 0) {
                database.insert(OSPAList);
            }
        }
    }

    public static void postToChatterGroup(List<OpportunityLineItem> olisForChatter, Boolean onInsert)
    {
        if(!postToChatterGroupFirstRunFlag)
            return;

        List<FeedItem> chatterFeedsForOlis = new List<FeedItem>();
        Map<Id, Id> product2IdToChatterGroupId = new Map<Id, Id>();
        Map<String, ObjectToChatterGroupMap__c> omapper = ObjectToChatterGroupMap__c.getAll();

        for(String prodId: omapper.keySet())
        {
            product2IdToChatterGroupId.put((Id)prodId, omapper.get(prodId).ChatterGroupID__c);
        }

        if(product2IdToChatterGroupId.size()<1)
            return;

        String feedMessage = (onInsert) ? '  has been added to the Opportunity ' : '  has been removed from the Opportunity ';
        for(OpportunityLineItem oli : olisForChatter)
        {
            if(product2IdToChatterGroupId.containsKey(oli.Product2Id__c))
            {
                FeedItem feed = new FeedItem();
                feed.ParentId = product2IdToChatterGroupId.get(oli.Product2Id__c);
                feed.Body =oli.Product_Name__c + feedMessage + oli.Opportunity_Name__c + '\n Please refer this link for details' ;
                feed.Title = 'Opportunity ' + oli.Opportunity_Name__c;
                feed.LinkUrl =  URL.getSalesforceBaseUrl().toExternalForm() + '/' +oli.OpportunityID;
                chatterFeedsForOlis.add(feed);
            }
        }
		
        if(chatterFeedsForOlis.size()>0)
            insert chatterFeedsForOlis;

        postToChatterGroupFirstRunFlag=false;

    }
   // Begin,Modifier:- Rajesh Kumar SFDC-7057 -|- logic to copy specialist forecats and closed date to line item when associated oppty is open
    public static void handleSpecialistField(Set<Id> opptyList, OpportunityLineItem[] pTriggerNew) {
    	if (firstRunspecialistcheck) {
    		Map<Id, Opportunity> opptyMap = new Map<Id, Opportunity> ([SELECT Id, ForecastCategoryName, CloseDate, Forecast_Category__c FROM Opportunity where Id in: opptyList and isclosed = false LIMIT 50000]);
    		System.debug('SD_OpptyMap_1-' + opptyMap);
    		if (!opptyMap.keySet().isEmpty()) { // restrict assignment only when oppty is associated && not closed
    			for (OpportunityLineItem oli: pTriggerNew) {
    				if (opptyMap.containsKey(oli.opportunityId)) {
    					oli.Specialist_Forecast_Category__c = (String.isBlank(oli.Specialist_Forecast_Category__c)) ? opptyMap.get(oli.opportunityId).Forecast_Category__c : oli.Specialist_Forecast_Category__c;
    					oli.Specialist_Close_Date__c = (String.isBlank(String.valueOf(oli.Specialist_Close_Date__c))) ? opptyMap.get(oli.opportunityId).CloseDate : oli.Specialist_Close_Date__c;
    				}
    			}
    		}
    		firstRunspecialistcheck = false;
    	}
    }
    //End - SFDC-7057

 // Begin,Modifier:- Rajesh Kumar SFDC-7061 -|- logic to update zoff associated check box on oppty to determine whether oppty have zoff product associated
 public static Map<Id,Opportunity> validateZoffproduct(set<id> opptyId, List<OpportunityLineItem> opptyList, Map<Id, Opportunity> opptyMap) { //list is just for showing unlikely error if happens,since keeping common method when called from CDC it would be null
    List<Opportunity> opptyUpdatelist = new List<Opportunity> ();
    List<String> webVerticalForZOFF = GsmUtilClass.getGSMSettingValue('Web_Vertical_For_ZOFF').split(',');
    List<String> webSubVerticalForZOFF = GsmUtilClass.getGSMSettingValue('Zoff_Sub_Vetical_For_Web_HighTech').split(',');
    // if (firstRunszoffcheckInsert ) { // remove this first run not required for insert context
        List<Opportunity> opprecordList = [Select Id, ZOFF_Enabled__c,ZOFF_Status__C, Account_Division__c, Opportunity_Type__c, recordtype.developername, isclosed, Associated_Account_Vertical__c, Associated_Account_Sub_Vertical__c,(Select id,Zoff_Product__c,contract_promo_code__C,ZoffAutoCreate__c from OpportunityLineItems) from opportunity where Id in: opptyId and isclosed = false and recordtype.developername = 'Akamai_Opportunity' limit 50000];
        for (Opportunity opp: opprecordList) {
            Opportunity oppUpd = OpportunityUtilClass.getOpportunityRecord(opptyMap,opp.Id);
            //oppUpd.id = opp.Id;
            boolean isZoffproduct = false;
            boolean isZoffpromo = false;
            boolean isautoCreate = false;
            if(!opp.OpportunityLineItems.isEmpty()){
                for (OpportunityLineItem opl: opp.OpportunityLineItems){
                    isZoffproduct = isZoffproduct || opl.Zoff_Product__c; // trade off b/w multiple O(n) for loop against all check
                    isZoffpromo = isZoffpromo || (opl.contract_promo_code__C == 'ZOFF' ? true : false);
                    isautoCreate = isautoCreate || opl.ZoffAutoCreate__c; // When record is created from auto-renewal job then new opportunity will be created and this will be the flag identifier for autorenewal
                }
                System.debug('isZoffproduct==' + isZoffproduct  + '=='+isZoffpromo + '==' + isautoCreate + 'sds' + opp.opportunity_type__c);
                String opptyType = String.isNotBlank(opp.opportunity_type__c) ? opp.opportunity_type__c.toLowercase() : '';
                Boolean isWebVertical = (webVerticalForZOFF.contains(opp.Associated_Account_Vertical__c) || (opp.Associated_Account_Vertical__c == 'High Technology' && webSubVerticalForZOFF.contains(opp.Associated_Account_Sub_Vertical__c)))? True : False;
                if('Renewal'.equalsIgnoreCase(opp.opportunity_type__c) || 'Auto-Renewal'.equalsIgnoreCase(opp.opportunity_type__c)){
                    switch on opptyType{
                        when 'renewal'{
                                oppUpd.Zoff_Status__c = ((isautoCreate && !isZoffpromo && isZoffproduct)?'No':( isautoCreate && !isZoffpromo && !isZoffproduct  ? 'Ineligible' : (isautoCreate && isZoffpromo ? 'Yes':(!isautoCreate && !isZoffproduct  ? 'Ineligible' : (!isautoCreate && isZoffproduct && (opp.ZOFF_Status__C == 'No' || opp.ZOFF_Status__C =='Yes' )?opp.ZOFF_Status__C:null)))));
                                oppUpd.ZOFF_Enabled__c = isZoffproduct;
                                if(!isWebVertical){
                                    oppUpd.Opt_Out_Reason__c = 'Existing ZOFF contract renewal';
                                }
                                //opptyUpdatelist.add(oppUpd); //---Commented by Chandra for SFDC -8958, need to add it to map instead of list
                                opptyMap.put(oppUpd.Id,OppUpd);
                                break;
                        }
                        when 'auto-renewal'{
                            oppUpd.ZOFF_Status__c = ((isZoffpromo && isZoffproduct)? 'Yes' : ((!isZoffpromo && isZoffproduct) ? 'No':((!isZoffpromo && !isZoffproduct)?'Ineligible':null)));
                            oppUpd.ZOFF_Enabled__c = isZoffproduct;
                            oppUpd.Opt_Out_Reason__c = (!isZoffpromo && isZoffproduct) ? 'Auto Renewal' : null;
                            if(isWebVertical){
                                oppUpd.ZOFF_Approval__c = (!isZoffpromo && isZoffproduct) ? 'Approved' : null;
                            }
                            //opptyUpdatelist.add(oppUpd); //---Commented by Chandra for SFDC -8958, need to add it to map instead of list
                            //System.debug('opptyUpdatelist' + isZoffproduct  + '=='+isZoffpromo + '==' + opptyUpdatelist);
                            opptyMap.put(oppUpd.Id,OppUpd);
                            break;
                        }
                    }
                }
                else{
                    if(isWebVertical){
                        oppUpd.ZOFF_Status__c = isZoffproduct ? ('Ineligible'.equalsignoreCase(opp.ZOFF_Status__c) ? '' : opp.ZOFF_Status__c) : 'Ineligible';
                    }
                    else{
                        oppUpd.ZOFF_Status__c = isZoffproduct ? 'No' : 'Ineligible';
                    }
                    oppUpd.ZOFF_Enabled__c = isZoffproduct;
                    //opptyUpdatelist.add(oppUpd); //---Commented by Chandra for SFDC -8958, need to add it to map instead of list
                    opptyMap.put(oppUpd.Id,OppUpd);
                }
            } 
            else{
                if (opp.Zoff_Enabled__c == true){
                    oppUpd.ZOFF_Enabled__c = false;
                    //opptyUpdatelist.add(oppUpd); //---Commented by Chandra for SFDC -8958, need to add it to map instead of list
                    opptyMap.put(oppUpd.Id,OppUpd);
                }
            }
              //opptyMap.put(oppUpd.Id,OppUpd);

        }
        // Commented Opportunity update below as part of SFDC-8958 
        //System.debug('=ZOFF=RK_01='+opptyUpdatelist);
        /*if (!opptyUpdatelist.isEmpty()) {
            updateZoffchangesoppties(opptyUpdatelist, opptyList,'sync');
        }*/
    // }
    // firstRunszoffcheckInsert = false;
    return opptyMap;
}
// this is called from batch context
public static void updatezoffopptyonLinezoffchanges(set<id> opptyId, List<OpportunityLineItem> opptyList ,String source) 
{
    Map<Id,Opportunity> opptyMap= new Map<Id,Opportunity>();
    opptyMap=updatezoffopptyonLinezoffchanges(opptyId, opptyList , source,  opptyMap);
    if(opptyMap!=null & opptyMap.values().size()>0)
        updateZoffchangesoppties(opptyMap.values(),opptyList,source);
}

//This is called from Trigger 
public static Map<Id,Opportunity> updatezoffopptyonLinezoffchanges(set<id> opptyId, List<OpportunityLineItem> opptyList ,String source, Map<Id,Opportunity> opptyMap) {
    if(firstRunszoffcheckUpdate){
    List<Opportunity> opptyUpdatelist = new List<Opportunity> ();
    List<Opportunity> opprecordList = [Select Id, ZOFF_Enabled__c, Account_Division__c, Opportunity_Type__c, ZOFF_Status__c, recordtype.developername, isclosed, (Select id from OpportunityLineItems where ZOFF_Product__c = True) from opportunity where Id in: opptyId and isclosed = false limit 50000];
    for (Opportunity opps: opprecordList) {
        Opportunity opp=OpportunityUtilClass.getOpportunityRecord(opptyMap,opps.Id);
        if (!opps.OpportunityLineItems.isEmpty() && opps.ZOFF_Enabled__c == false) { // this value should override if any validation and needs to be updated in System context . -|- exception case
            opp.Zoff_Enabled__c=true;
            opp.Zoff_Status__c=(opps.ZOFF_Status__c == 'Ineligible' ? '' : opps.ZOFF_Status__c);
            //opptyUpdatelist.add(new Opportunity(Id = opps.Id, ZOFF_Enabled__c = true ,validation_override__c = true ,ZOFF_Status__c = (opps.ZOFF_Status__c == 'Ineligible' ? '' : opps.ZOFF_Status__c) ));
        }
        if (opps.OpportunityLineItems.isEmpty() && opps.ZOFF_Enabled__c == true) {
            opp.Zoff_Enabled__c=false;
            opp.Zoff_Status__c='Ineligible';
            //opptyUpdatelist.add(new Opportunity(Id = opps.Id, ZOFF_Enabled__c = false ,validation_override__c = true , ZOFF_Status__c = 'Ineligible' ));
        }
        opptyMap.put(opps.Id,opp);
    }
    /*if (!opptyUpdatelist.isEmpty()) {
        updateZoffchangesoppties(opptyUpdatelist, opptyList , source);
    }*/
    firstRunszoffcheckUpdate = false;
    }
    return opptyMap;
}
public static void updateZoffchangesoppties(List<Opportunity> oppList, List<OpportunityLineItem> opptyList , String source) {
    try {
        update oppList;
    } catch (exception ex) {
        Sawyer.saw(ex);
        if (Trigger.isExecuting && source == 'sync') {
            String errMessage = ex.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION') ? ex.getMessage().split(',')[1] : 'Something went wrong while updating/deleting requests.' ;
            opptyList[0].addError(errMessage);
        } 
    }
}
//End - SFDC-7061
}