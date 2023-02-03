/**
   History
      
      --Developer       --Date         --Description
      Ruchika sharma    08/06/2020     Created this Class - SFDC-6405
    
*/
public with sharing class NAPPartnerPricingAccessHandler  extends ApexTriggerHandlerAbstractClass{
    public NAPPartnerPricingAccessHandler() {

    }
public override void beforeInsertBeforeUpdateTrigger()
    {
    
        List<NAP_Products_Pricing_Access__c> ppaTriggerNew = (List<NAP_Products_Pricing_Access__c>)newList;
        List<NAP_Products_Pricing_Access__c> ppaTriggerOld = (List<NAP_Products_Pricing_Access__c>)oldList;
        Map<Id,NAP_Products_Pricing_Access__c> ppaTriggerNewMap = (Map<Id,NAP_Products_Pricing_Access__c>)newMap;
        Map<Id,NAP_Products_Pricing_Access__c> ppaTriggerOldMap = (Map<Id,NAP_Products_Pricing_Access__c>)oldMap;
        List<NAP_Products_Pricing_Access__c> pricingAcessUpdatedData = new List<NAP_Products_Pricing_Access__c> ();
        List<NAP_Products_Pricing_Access__c> uniqueProductUpdatedData = new List<NAP_Products_Pricing_Access__c> ();

        ByPassAndLimitUtils.setAkamField(Trigger.isInsert,Trigger.isUpdate,ppaTriggerNew);
        for(SObject so: newList)
        {

            NAP_Products_Pricing_Access__c ppaRecNew = (NAP_Products_Pricing_Access__c)so;
            NAP_Products_Pricing_Access__c ppaRecOld = null;

            if(Trigger.isUpdate)
                ppaRecOld=(NAP_Products_Pricing_Access__c)oldMap.get(ppaRecNew.Id);
                // SFDC-7108
            if(ppaRecNew.Product__c!=null && (Trigger.isInsert || (Trigger.isUpdate && Util.hasChanges('Product__c',ppaRecOld,ppaRecNew))))
                uniqueProductUpdatedData.add(ppaRecNew);
            if(Trigger.isInsert || (Trigger.isUpdate && Util.hasChanges('Pricing_Access__c',ppaRecOld,ppaRecNew)))
                    pricingAcessUpdatedData.add(ppaRecNew);
        }
        PartnerPricingClass ppaObj = new PartnerPricingClass();
        // SFDC-7108
        if(!uniqueProductUpdatedData.isEmpty()){
                ppaObj.updateUniqueProductAndAccount(uniqueProductUpdatedData);
            }
        if(!pricingAcessUpdatedData.isEmpty()){
                ppaObj.updatePricingAcessDetails(pricingAcessUpdatedData,ppaTriggerOldMap);
            }
    }

    public override void beforeDeleteBeforeUndeleteTrigger(){

    }

    public override void afterInsertAfterUpdateTrigger(){

    }

    public override void afterDeleteAfterUndeleteTrigger(){

    }
}