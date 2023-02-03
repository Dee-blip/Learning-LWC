/**
   History
      
      --Developer       --Date         --Description
      Ruchika sharma    08/06/2020     Created this Class - SFDC-6405
    
*/

public with sharing class PartnerPricingClass {
    public PartnerPricingClass() {

    }

    public void updatePricingAcessDetails(List<NAP_Products_Pricing_Access__c> pricingAcessUpdatedData, Map<Id,NAP_Products_Pricing_Access__c> ppaTriggerOldMap){
        for(NAP_Products_Pricing_Access__c nppaObj : pricingAcessUpdatedData){
            nppaObj.Pricing_Access_Updated_On__c = system.now();
            if(ppaTriggerOldMap!=null)
                nppaObj.Previous_Pricing_Access__c = ppaTriggerOldMap.get(nppaObj.id).Pricing_Access__c;
        }
    }

    public void updateUniqueProductAndAccount(List<NAP_Products_Pricing_Access__c> uniqueProductUpdatedData){
        for(NAP_Products_Pricing_Access__c nppaObj : uniqueProductUpdatedData)
            nppaObj.Unique_Product_And_Account__c = nppaObj.Partner_Name__c+' '+nppaObj.Product__c;
    }
}