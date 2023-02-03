/**
 * @description       : OpportunityLineItemTriggerHandler
 * @author            : apyati
 * @team              : GSM
 * @last modified on  : 08-30-2021
 * @last modified by  : apyati
 * Modifications Log
 * Ver   TAG    Date         Author   Modification                                                    
 * 1.0  <T01>   08-30-2021   apyati   SFDC-8809 Added  method to round up currency fields to 2 decimals  
 * **/
public without sharing class OpportunityLineItemTriggerHandler extends ApexTriggerHandlerAbstractClass 
{
    public static L2Q_ZOFF_Feature__mdt  zoffmdtValue = ZoffUtilClass.getZOFFmdtsetting('ZOFF');//Cached Metadata Rajesh - SFDC-7061 ||
    
    public override void beforeInsertBeforeUpdateTrigger()
    {
        String newProductWizardGA = GsmUtilClass.getGSMSettingValue('Product_Wizard_GA_Toggle');
        List<Id> ownerIds = new List<Id>();
        Map<Id,Boolean> mapIdToPilotUser = new Map<Id,Boolean>();
        Set<Id> opptyIds = new Set<Id> ();//SFDC-7057
        List<OpportunityLineItem> listOfOpportunityLineItemsWithUpdatedStrategicMRR = new List<OpportunityLineItem>();
        for(SObject so: Trigger.new)
        {
            OpportunityLineItem oli = (OpportunityLineItem)so;
            OpportunityLineItem oldOli;
             // Begin,Modifier:- Rajesh Kumar SFDC-7057
             if (Trigger.isInsert ) {
                 opptyIds.add(oli.OpportunityId);
            }
             System.debug('RK_OpptyId=>' + opptyIds);
            // End SFDC-7057
            if(Trigger.isUpdate)
                oldOli = (OpportunityLineItem)Trigger.oldMap.get(oli.Id);

            // If the Oppty-Prod is moving from Loss to Profit, please clean up the Loss Type (LMRR_Type__c). As this is used in Oppty.Churn/New calculation.
            if (Trigger.isUpdate && oli.UnitPrice!= oldOli.UnitPrice && oldOli.UnitPrice<0 && oli.UnitPrice>=0)
                oli.LMRR_Type__c='';

            ownerIds.add(oli.Opportunity_Owner__c);
        }
       // Begin,Modifier:- Rajesh Kumar SFDC-7057
        if(!opptyIds.isEmpty()){
           OpportunityLineItemTriggerClass.handleSpecialistField(opptyIds, Trigger.new);
        }
       //End SFDC-7057
        system.debug(LoggingLevel.ERROR,'ownerIds: '+ownerIds);
        if(!ownerIds.isEmpty())
            mapIdToPilotUser = GsmUtilClass.isPilotUser(ownerIds);

        for(SObject so: Trigger.new)
        {
            OpportunityLineItem oli = (OpportunityLineItem)so;

            Boolean isPioltUser = false;
            if(!mapIdToPilotUser.isEmpty())
                isPioltUser = mapIdToPilotUser.get(oli.Opportunity_Owner__c);
            //system.debug(LoggingLevel.ERROR,'isPioltUser:: '+isPioltUser);
            if(Trigger.isUpdate)
            {

                //SFDC-1108 - EMRI: Retrieving Contract Baseline information on Opportunity
                //SFDC-1952
                if(newProductWizardGA == 'True')
                {
                    OpportunityLineItem oldOLI = (OpportunityLineItem)Trigger.oldMap.get(oli.Id);

                    //Calculate Unit Price
                    Decimal projectedMonthlyCommit = 0.00 ;
                    Decimal averageRenewalCommit = 0.00 ;
                    if(oli.Projected_Monthly_commit_fees__c == null)
                        projectedMonthlyCommit = 0.00;
                    else{
                        oli.Projected_Monthly_commit_fees__c = oli.Projected_Monthly_commit_fees__c.setScale(2, RoundingMode.HALF_UP);
                        projectedMonthlyCommit = oli.Projected_Monthly_commit_fees__c;
                    }

                    if(oli.Average_Renewal_Commit_MRR__c == null )
                        averageRenewalCommit = 0.00;
                    else
                        averageRenewalCommit = oli.Average_Renewal_Commit_MRR__c ;

                    //SFDC-1952 - For pilot users. MRR ≈ Projected commit, Projected usage ≈ EMRI - MRR, Baseline = 0
                    if(!isPioltUser)
                    {
                        if( Util.hasChanges('Projected_Monthly_commit_fees__c' , oli, oldOLI) || Util.hasChanges('Average_Renewal_Commit_MRR__c' , oli, oldOLI))
                            oli.UnitPrice = projectedMonthlyCommit - averageRenewalCommit;
                    }
                    else
                    {

                        system.debug(LoggingLevel.ERROR,'Inside IsPilot User for Update at Trigger '+oli.UnitPrice +'Average_Renewal_Commit_MRR__c '+oli.Average_Renewal_Commit_MRR__c+'EMRI '+oli.EMRI__c);
                        //SFDC-2042
                        //Set EMRI and MRR to 0 if they are null
                        if(oli.EMRI__c==null)
                            oli.EMRI__c=0;
                        else
                            oli.EMRI__c=oli.EMRI__c.setScale(2, RoundingMode.HALF_UP);
                        if(oli.UnitPrice==null)
                            oli.UnitPrice=0.00;
                        else
                            oli.UnitPrice=oli.UnitPrice.setScale(2, RoundingMode.HALF_UP);
                        //Pilot user would be entering unitPrice manually.
                        oli.Projected_Monthly_commit_fees__c = oli.UnitPrice;
                        if(oli.Average_Renewal_Commit_MRR__c != null)
                            oli.Average_Renewal_Commit_MRR__c=0.00;
                        //for pilot user, Projected usage ≈ EMRI - MRR, and baseline =0 for baseline products
                        Decimal emri = 0.00;
                        Decimal mrr = 0.00;
                        emri = oli.EMRI__c;
                        mrr=oli.UnitPrice;

                        oli.Projected_Avg_Rev_Non_Commit__c = emri - mrr;
                        if(oli.Average_Renewal_Usage_MRR__c != null)
                            oli.Average_Renewal_Usage_MRR__c=0.00;

                    }
                    //oli.MRR__c = oli.UnitPrice;

                    system.debug(LoggingLevel.ERROR,'Projected Avg '+oli.Projected_Avg_Rev_Non_Commit__c +' Average Renewal '+oli.Average_Renewal_Usage_MRR__c);

                    //Calculate Net Non Commit
                    Decimal projectedAvgRenNonCommit = 0.00;
                    Decimal averageRenewalUsage = 0.00;
                    if(oli.Projected_Avg_Rev_Non_Commit__c == null)
                        projectedAvgRenNonCommit = 0.00;
                    else{
                        oli.Projected_Avg_Rev_Non_Commit__c = oli.Projected_Avg_Rev_Non_Commit__c.setScale(2, RoundingMode.HALF_UP);
                        projectedAvgRenNonCommit = oli.Projected_Avg_Rev_Non_Commit__c;
                    }

                    if(oli.Average_Renewal_Usage_MRR__c == null)
                        averageRenewalUsage = 0.00;
                    else
                        averageRenewalUsage = oli.Average_Renewal_Usage_MRR__c ;

                    if(Util.hasChanges('Projected_Avg_Rev_Non_Commit__c' , oli, oldOLI) || Util.hasChanges('Average_Renewal_Usage_MRR__c' , oli, oldOLI))
                    {
                        oli.Net_Non_Commit__c = projectedAvgRenNonCommit - averageRenewalUsage;
                        system.debug('Projected Avg '+oli.Projected_Avg_Rev_Non_Commit__c +' Average Renewal '+oli.Average_Renewal_Usage_MRR__c);
                    }


                    //Calculate EMRI field

                    //oli.EMRI__c = oli.UnitPrice + oli.Net_Non_Commit__c ;
                    if(!isPioltUser)
                    {
                        oli.EMRI__c = ((oli.UnitPrice==null) ? 0 : oli.UnitPrice) + ((oli.Net_Non_Commit__c==null) ? 0 : oli.Net_Non_Commit__c);
                    }

                    system.debug(' Inside Before Update '+oli.UnitPrice + oli.Net_Non_Commit__c + oli.EMRI__c);
                }
            }

            if(Trigger.isInsert)
            {
                // || isPioltUser

                if(newProductWizardGA == 'True')
                {
                    //SFDC-1108 - EMRI: Retrieving Contract Baseline information on Opportunity
                    Decimal projectedMonthlyCommitInsert = 0.00;
                    Decimal avgRenewalCommitMRRInsert = 0.00;
                    Decimal projectedAvgRenNonCommitInsert = 0.00;
                    Decimal avgRenUsageMRRInsert = 0.00;

                    if(oli.Projected_Monthly_commit_fees__c ==null)
                        projectedMonthlyCommitInsert = 0.00;
                    else{
                        oli.Projected_Monthly_commit_fees__c = oli.Projected_Monthly_commit_fees__c.setScale(2, RoundingMode.HALF_UP);
                        projectedMonthlyCommitInsert = oli.Projected_Monthly_commit_fees__c;
                    }

                    if(oli.Average_Renewal_Commit_MRR__c == null)
                        avgRenewalCommitMRRInsert = 0.00;
                    else
                        avgRenewalCommitMRRInsert = oli.Average_Renewal_Commit_MRR__c ;

                    //if(oli.Projected_Monthly_commit_fees__c!= null &&  oli.Average_Renewal_Commit_MRR__c != null)
                    if(!isPioltUser){
                        oli.UnitPrice = projectedMonthlyCommitInsert - avgRenewalCommitMRRInsert;
                    }else{
                        oli.Projected_Monthly_commit_fees__c = oli.UnitPrice;
                        if(oli.Average_Renewal_Commit_MRR__c != null)
                            oli.Average_Renewal_Commit_MRR__c=0.00;
                        if(oli.EMRI__c==null)
                            oli.EMRI__c=0.00;
                        else
                            oli.EMRI__c=oli.EMRI__c.setScale(2, RoundingMode.HALF_UP);
                        if(oli.UnitPrice==null)
                            oli.UnitPrice=0.00;
                        else
                            oli.UnitPrice=oli.UnitPrice.setScale(2, RoundingMode.HALF_UP);
                        //for pilot user, Projected usage ≈ EMRI - MRR, and baseline =0 for baseline products
                        Decimal emri = 0.00;
                        Decimal mrr = 0.00;
                        emri = oli.EMRI__c;
                        mrr=oli.UnitPrice;

                        oli.Projected_Avg_Rev_Non_Commit__c = emri - mrr;
                        if(oli.Average_Renewal_Usage_MRR__c != null)
                            oli.Average_Renewal_Usage_MRR__c=0.00;
                    }

                    if(oli.Projected_Avg_Rev_Non_Commit__c == null)
                        projectedAvgRenNonCommitInsert = 0.00;
                    else{
                        oli.Projected_Avg_Rev_Non_Commit__c = oli.Projected_Avg_Rev_Non_Commit__c.setScale(2, RoundingMode.HALF_UP);
                        projectedAvgRenNonCommitInsert = oli.Projected_Avg_Rev_Non_Commit__c;
                    }

                    if(oli.Average_Renewal_Usage_MRR__c == null)
                        avgRenUsageMRRInsert = 0.00;
                    else
                        avgRenUsageMRRInsert = oli.Average_Renewal_Usage_MRR__c ;

                    oli.Net_Non_Commit__c = projectedAvgRenNonCommitInsert -  avgRenUsageMRRInsert;


                    if(!isPioltUser)
                        oli.EMRI__c = oli.UnitPrice + oli.Net_Non_Commit__c;

                    system.debug('Inside Before Insert '+oli.UnitPrice + oli.Net_Non_Commit__c + oli.EMRI__c);
                }
            }
            // Update the Oppty-Prod.UnitPrice with Oppty-Prod.Forecast_MRR_RealTime__c on create/edit.

        }

        OpportunityLineItemTriggerClass.updateForecastMRR(Trigger.new);
        //Adding the logic to remove the extra digit after specified decimal format.for example if the MRR comes in following form -0.009, -0.0004etc it will be rounded out to 0.00
        OpportunityLineItemTriggerClass.formatDecimalPlaceMRR(Trigger.new);

        for(SObject so: Trigger.new)
        {
            OpportunityLineItem oli = (OpportunityLineItem)so;
            //CR 2891568 and 2948870: SNMRR, Need MRR_in_Dollar__c to get changed before calling below line of code
            if(Trigger.isUpdate)
            {
                OpportunityLineItem oldOLI = (OpportunityLineItem)Trigger.oldMap.get(oli.Id);
                //CR 2891568 and 2948870:
                if(oli.MRR_in_Dollar__c!=null && Util.hasChanges('MRR_in_Dollar__c' , oldOLI, oli)){
                    listOfOpportunityLineItemsWithUpdatedStrategicMRR.add(oli);
                }
            }
            if(Trigger.isInsert)
            {
                //CR 2891568 and 2948870:
                listOfOpportunityLineItemsWithUpdatedStrategicMRR.add(oli);
            }
        }

        if(listOfOpportunityLineItemsWithUpdatedStrategicMRR.size()>0)
        {
            System.debug('listOfOpportunityLineItemsWithUpdatedStrategicMRR size: '+listOfOpportunityLineItemsWithUpdatedStrategicMRR.size());
            OpportunityLineItemTriggerClass.populateStrategicNetMRR(listOfOpportunityLineItemsWithUpdatedStrategicMRR);
        }
        set<OpportunityLineItem> setOfOlisWithChangedMRRs = new Set<OpportunityLineItem>();
        set<Id> opptyIdsForChangedMRR = new Set<Id>();
        //CR 2891568 and 2948870: SNMRR, a list to add oli if strategic mrr needs to update
        // Start - Generic code for all MRR- MRR USD conversions- SFDC - 1316 & SFDC-1453
        Set<String> fieldNames = new Set<String>();
        for(USD__mdt usdObj : [Select Field__c,USD_Field__c from USD__mdt where Object__c = 'OpportunityLineItem'])
            fieldNames.add(usdObj.Field__c);
        for(SObject so: Trigger.new)
        {
            OpportunityLineItem oli = (OpportunityLineItem)so;
            if((Trigger.isInsert && Util.isInserted(fieldNames,oli))|| (Trigger.isUpdate && Util.hasChanges(fieldNames,Trigger.oldMap.get(oli.Id),oli)))
            {
                setOfOlisWithChangedMRRs.add(oli);
            }
        }

        if(setOfOlisWithChangedMRRs.size() > 0)
        {
            OpportunityUtilClass.genericPopulateUSDOnChangeOfFields(new List<OpportunityLineItem>(setOfOlisWithChangedMRRs),false);
        }


        System.debug('@@apyati+ Trigger.new+ before'+Trigger.new.size());
        OpportunityLineItemTriggerClass.roundUpCurrency2Decimals(Trigger.new); //<T01/>
       
       // End - Generic code for all MRR-MRR USD conversions- SFDC - 1316 & SFDC-1453

    }

    public override void afterInsertAfterUpdateTrigger()
    {
        List<OpportunityLineItem> listOfOLIWithInvoicedMonthlyMRRUSD = new List<OpportunityLineItem>();
        List<OpportunityLineItem> addedProductList = new List<OpportunityLineItem>();
        List<OpportunityLineItem> opportunityLineItemsAdded = new List<OpportunityLineItem>();

        String newProductWizardGA = GsmUtilClass.getGSMSettingValue('Product_Wizard_GA_Toggle');
        String forecastGroupsForSpecialistFields = GsmUtilClass.getGSMSettingValue('ProductforecastGroups');
        Set<Id> oppIds = new Set<Id>();
        String changedFieldsList = GsmUtilClass.getGSMSettingValue('FieldChange_to_calculate_MRR_roll_up');
        Set<String> fieldNames = new Set<String>();
        fieldNames.addAll(changedFieldsList.split(','));
        List<OpportunityLineItem> olisForOSPA = new List<OpportunityLineItem>();
        String forecastGroupsForProductNotification = GSMSettings.getValue('ForecastGroupsForLineItem');
        Set<Id> oppIdSet = new Set<Id>();
        Map<Id, Id> opptyProdIdOpptyIdMap = new Map<Id, Id>();
        List<OpportunityLineItem> olisForChatter= new List<OpportunityLineItem>();
        //String CIAMProducts = GSMSettings.getVerbose('CIAMProducts');
        String CIAMProducts = GsmUtilClass.getGSMSettingValue('CIAMProducts');
        List<OpportunityLineItem> ciamProductList = new List<OpportunityLineItem>();
        Set<Id> oppIdsRealtedToCiam = new Set<Id>(); 
        //SFDC-8125
        String ProlexicProducts = GsmUtilClass.getGSMSettingValue('ProlexicProducts');
        map<OpportunityLineItem,string> ProductSpecialistType = new map<OpportunityLineItem,string>();

        set<id> zffopptyMap = new set<id>();//RAJESH - SFDC-7061
        List<Opportunity> opptysTobeUpdated= new List<Opportunity>();
        //Start - Added By Chandra - SFDC - 8958
        Map<Id,Opportunity> opptyMap= new Map<Id,Opportunity>();
        for(SObject so: Trigger.new)
        {
            OpportunityLineItem oli = (OpportunityLineItem)so;
            OpportunityLineItem oldOli ;

            if(Trigger.isUpdate)
                oldOli = (OpportunityLineItem)Trigger.oldMap.get(oli.Id);

            if( oli.Average_Renewal_Commit_MRR_USD__c != null || oli.Average_Renewal_Usage_MRR_USD__c != null )
            {
                listOfOLIWithInvoicedMonthlyMRRUSD.add(oli);
            }

            if((Trigger.isInsert && oli.Strategic_MRR__c!=null) || (Trigger.isUpdate && oli.Strategic_MRR__c != null && oli.Strategic_MRR__c != oldOli.Strategic_MRR__c))
                oppIdSet.add(oli.OpportunityId);

            if((Trigger.isInsert && oli.MRR__c!=null) || (Trigger.isUpdate && oli.MRR__c!= null && oli.MRR__c!= oldOli.MRR__c))
                oppIdSet.add(oli.OpportunityId);

            //SFDC-1108 - EMRI: Retrieving Contract Baseline information on Opportunity
            if(newProductWizardGA == 'True' && ((Trigger.isUpdate && Util.hasChanges(fieldNames, oli, oldOLI)) || (Trigger.isInsert && Util.isInserted(fieldNames, oli))))
                oppIdSet.add(oli.OpportunityId);

            if (Trigger.isUpdate && oli.UnitPrice!=oldOli.UnitPrice && oldOli.UnitPrice<0 && oli.UnitPrice>=0 && oli.Validation_Override__c==false)
                opptyProdIdOpptyIdMap.put(oli.Id,oli.OpportunityId);

            if (Trigger.isInsert && oli.Forecast_Group__c != null && forecastGroupsForSpecialistFields.contains(oli.Forecast_Group__c))
            {
                addedProductList.add(oli);
                oppIds.add(oli.opportunityId);
            }

            if(Trigger.isInsert && CIAMProducts.contains(oli.Product_Name__c)) {
                ciamProductList.add(oli);
                oppIdsRealtedToCiam.add(oli.opportunityId);
                ProductSpecialistType.put(oli,'CIAM');

            }
            //SFDC-8125
            if(Trigger.isInsert && ProlexicProducts.contains(oli.Product_Name__c)) {
                ciamProductList.add(oli);
                oppIdsRealtedToCiam.add(oli.opportunityId);
                ProductSpecialistType.put(oli,'Prolexic');
            }

            if (Trigger.isInsert && oli.Forecast_Group__c != null && forecastGroupsForProductNotification.contains(oli.Forecast_Group__c))
                opportunityLineItemsAdded.add(oli);

            if (Trigger.isInsert)
                olisForOSPA.add(oli);

            if(Trigger.isInsert)
                olisForChatter.add(oli);

              // BEGIN  Rajesh Kumar SFDC-7061  -|- FILTER ZOFF RELATED OPPORTUNITY HERE AND THEN REST LOGIC IN CONTROLLER
            if(Trigger.isInsert && zoffmdtValue.Feature_Enabled__c )//   filter only when ZOFF product renewal|auto-renewal
             {
               if(oli.Zoff_Product__c || oli.ZoffAutoCreate__c || oli.Contract_promo_code__c == 'ZOFF' ||  'Renewal'.equalsIgnoreCase(oli.ZOFF_Opportunity_Type__c) || 'Auto-Renewal'.equalsIgnoreCase(oli.ZOFF_Opportunity_Type__c) )
               {
                zffopptyMap.add(oli.OpportunityId);
               }
             }
            // END  Rajesh Kumar SFDC-7061


        }

        List<Opportunity> opptyList=null;
        if(addedProductList.size()>0)
        opptyMap=OpportunityTriggerClass.autoAssignSpecialist(addedProductList, oppIds);

        if(ciamProductList.size() > 0) {
            opptyMap=OpportunityTriggerClass.autoAssignCIAMSpecialist(oppIdsRealtedToCiam,ProductSpecialistType,OpptyMap);
        }

        if(opptyProdIdOpptyIdMap.size() > 0)
            OpportunityLineItemTriggerClass.checkOpptyChurnFieldsRemoval(opptyProdIdOpptyIdMap.values());

        if(listOfOLIWithInvoicedMonthlyMRRUSD.size() > 0)
        {
            opptyMap=OpportunityLineItemTriggerClass.updateInvoiceMonthlyMRRMethod(listOfOLIWithInvoicedMonthlyMRRUSD,opptyMap);
                   
        }
        if(oppIdSet.size() > 0)
        {
            opptyMap=OpportunityTriggerClass.updatePrimaryProductNameOnOppty(oppIdSet,opptyMap);
            OpportunityForecastingTriggerClass.genericPopulateMRRFirstRunFlag = true;
            opptyMap=OpportunityForecastingTriggerClass.genericPopulateMRR(oppIdSet,'OpportunityLineItemTrigger',null,null,opptyMap);
        }
        // SFDC-3933 Notifications -  Added By Prabhanjan
        if (opportunityLineItemsAdded.size()>0)
            OpportunityLineItemTriggerClass.handleProductNotifications(opportunityLineItemsAdded);

        if(olisForOSPA.size() > 0)
            OpportunityLineItemTriggerClass.insertOSPARecords(olisForOSPA);

        if(olisForChatter.size()>0)
            OpportunityLineItemTriggerClass.postToChatterGroup(olisForChatter, true);
        // Begin,Modifier:- Rajesh Kumar SFDC-7061 -|- invoke handler for zoff product association

        if(!zffopptyMap.isEmpty() && zoffmdtValue.Feature_Enabled__c)
        {
            opptyMap=OpportunityLineItemTriggerClass.validateZoffproduct(zffopptyMap,Trigger.new,opptyMap);
        }
        // End-SFDC-7061
        if(opptyMap != null && opptyMap.values().size()>0)
        OpportunityUtilClass.updateOpportunityFromLineItemAfterInsertAfterUpdate(opptyMap.values());

    }

    public override void beforeDeleteBeforeUndeleteTrigger()
    {

        // added trigger level validation to check id partners have delete permission on products for CR 1666876
        //List<OpportunityLineItem> opptLineItemDeleted=new List<OpportunityLineItem>();
        List<OpportunityLineItem> oldOlis = new List<OpportunityLineItem>();
        //String carrierForecastGroup = GsmUtilClass.getGSMSettingValue('OpptyLineItemTrigger_CarrierFamily');

        Map<Id,OpportunityLineItem> olisOldMap = (Map<Id,OpportunityLineItem>)oldMap;
        //SFDC-6398
        Set<Id> opptyForAutoRenewalIdSet = new Set<id>();
        List<Id> opptyLineItemIdList = new List<Id>();

        if(Trigger.isDelete)
        {
            for(SObject so: Trigger.old)
            {
                OpportunityLineItem oli = (OpportunityLineItem)so;
                if(Userinfo.getUserType().equals('PowerPartner'))
                {
                    oldOlis.add(oli);
                }

                /*if(oli.Forecast_Group__c==carrierForecastGroup) //SFDC-2304
                {
                    opptLineItemDeleted.add(oli);
                }*/

                //SFDC-6398
                if(oli.MRR__c == 0 &&  oli.EMRI__c == 0)
                {
                    opptyForAutoRenewalIdSet.add(oli.OpportunityId);
                    opptyLineItemIdList.add(oli.Id);
                }
            }

            if(oldOlis.size()>0)
                OpportunityLineItemTriggerClass.checkIfPartnerEligibleForDelete(Trigger.old);
            //SFDC-6398
            if(opptyForAutoRenewalIdSet.size() > 0)
            {
                Map<Id, Opportunity> opptyMapOliDel= new Map<Id,Opportunity>();
                opptyMapOliDel = OpportunityTriggerClass.switchToAutoRenewalTypeFromOLI(opptyForAutoRenewalIdSet,opptyLineItemIdList,opptyMapOliDel);

            }

            /*if(opptLineItemDeleted.size()>0)
            {
                OpportunityTriggerClass.UpdateCarrierApplicationOnOpportunity(opptLineItemDeleted);
            }*/

            OpportunityLineItemTriggerClass.checkClosedOpptyProdDeletion(olisOldMap);
        }
    }

    public override void afterDeleteAfterUndeleteTrigger()
    {
        Map<Id,Id> delOpptyProdIdOpptyIdMap = new Map<Id,Id>();
        Set<Id> oppIdSet = new Set<Id>();
        set<Id> zoffopptydelSet  = new Set<id>(); //Rajesh SFDC-7061
        // Moved to afterDelete trigger to optimize lineitem deletion by Chandra - SFDC -8958
        List<OpportunityLineItem> opptLineItemDeleted=new List<OpportunityLineItem>();
        //SFDC-6398
        Set<Id> opptyForAutoRenewalIdSet = new Set<id>();
        List<Id> opptyLineItemIdList = new List<Id>();
        String carrierForecastGroup = GsmUtilClass.getGSMSettingValue('OpptyLineItemTrigger_CarrierFamily');

        String newProductWizardGA = GsmUtilClass.getGSMSettingValue('Product_Wizard_GA_Toggle');
        List<OpportunityLineItem> olisForChatter= new List<OpportunityLineItem>();
        Map<Id, Opportunity> opptyMapOliDeletion= new Map<Id,Opportunity>();

        if(Trigger.isDelete)
        {
            for(SObject so: Trigger.old)
            {
                OpportunityLineItem oli = (OpportunityLineItem)so;
                //Rajesh Kumar SFDC-7061     during delete only filter ZOFFABLE lineItem
               if(oli.Zoff_Product__c  && zoffmdtValue.Feature_Enabled__c) //change the filter
                  {
                    zoffopptydelSet.add(oli.OpportunityId);
                  }
                 //End Kumar SFDC-7061
                delOpptyProdIdOpptyIdMap.put(oli.Id,oli.OpportunityId);


                //For updation of Primary Product Name field
                oppIdSet.add(oli.OpportunityId);
                if(oli.Product2Id__c!=null)
                    olisForChatter.add(oli);

                // Moved to After delete trigger to Optimize Oppty delete - SFDC -8958 by Chandra
                    //SFDC-6398
                if(oli.MRR__c == 0 &&  oli.EMRI__c == 0)
                {
                    opptyForAutoRenewalIdSet.add(oli.OpportunityId);
                    opptyLineItemIdList.add(oli.Id);
                }
                if(oli.Forecast_Group__c==carrierForecastGroup) //SFDC-2304
                {
                    opptLineItemDeleted.add(oli);
                }
            }


            if(oppIdSet.size() > 0)
            {
                opptyMapOliDeletion=OpportunityTriggerClass.updatePrimaryProductNameOnOppty(oppIdSet,opptyMapOliDeletion);
                //SFDC-2042 - shadow forecasting methd should rerun as with deletion of oli, shadow forescasting could have changed.
                OpportunityForecastingTriggerClass.genericPopulateMRRFirstRunFlag = true;
                opptyMapOliDeletion=OpportunityForecastingTriggerClass.genericPopulateMRR(oppIdSet,'OpportunityLineItemTrigger',null,null,opptyMapOliDeletion);
                manageSalesPlayProductsController.deleteOpportunitySalesPlay(oppIdSet);
            }
            if(delOpptyProdIdOpptyIdMap.size() > 0)
                OpportunityLineItemTriggerClass.checkOpptyChurnFieldsRemoval(delOpptyProdIdOpptyIdMap.values());

            if(olisForChatter.size()>0)
                OpportunityLineItemTriggerClass.postToChatterGroup(olisForChatter, false);


            // Begin,Modifier:- Rajesh Kumar SFDC-7061 -|- invoke handler for zoff product association
            if(!zoffopptydelSet.isEmpty())
            {
                opptyMapOliDeletion=OpportunityLineItemTriggerClass.updatezoffopptyonLinezoffchanges(zoffopptydelSet,Trigger.old,'sync',opptyMapOliDeletion);
            }
            // End-SFDC-7061
            // Moved to After delete trigger for SFDC -8958 - Chandra
            //SFDC-6398
            if(opptyForAutoRenewalIdSet.size() > 0)
            {
                opptyMapOliDeletion=OpportunityTriggerClass.switchToAutoRenewalTypeFromOLI(opptyForAutoRenewalIdSet,opptyLineItemIdList,opptyMapOliDeletion);

            }
            if(opptLineItemDeleted.size()>0)
            {
                opptyMapOliDeletion=OpportunityTriggerClass.UpdateCarrierApplicationOnOpportunity(opptLineItemDeleted,opptyMapOliDeletion);
            }
            if(opptyMapOliDeletion != null && opptyMapOliDeletion.values().size()>0)
                OpportunityUtilClass.updateOpportunityFromLineItemAfterInsertAfterUpdate(opptyMapOliDeletion.values());   

        }
    }
    
}