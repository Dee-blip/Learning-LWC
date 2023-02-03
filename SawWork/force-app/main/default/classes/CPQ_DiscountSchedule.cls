/**
* Test Class: CPQ_Test_CPQ_Create_Products
*/
public with sharing class CPQ_DiscountSchedule {

    public static Map<String,Id> toDeleteDiscTiers = new Map<String,Id>();
    public static Set<String> listOfDiscTiersTOBeDeleted = new Set<String>();

    public static Map<String,SBQQ__DiscountSchedule__c> validateAndMap(Map<String,List<CPQ_PM_UtilityClass.Tiers>> discountSchedules){

        Map<String,SBQQ__DiscountSchedule__c> discNameToSchedule = new Map<String,SBQQ__DiscountSchedule__c>();
        Map<String,Id> existingDisSchedules = new Map<String,Id>();

        List<SBQQ__DiscountSchedule__c> disSchedules = [SELECT Id,Name FROM SBQQ__DiscountSchedule__c LIMIT 10000];
        for(SBQQ__DiscountSchedule__c dsName : disSchedules) {
            existingDisSchedules.put(dsName.Name,dsName.Id);
        }

        for(String ds :discountSchedules.keySet()){  
            if(!existingDisSchedules.containsKey(ds.right(80).trim())) {
                SBQQ__DiscountSchedule__c sds = new SBQQ__DiscountSchedule__c();
                sds.name = ds.right(80);   
                sds.SBQQ__Type__c ='Range';
                sds.SBQQ__DiscountUnit__c ='Percent';
                sds.SBQQ__QuoteLineQuantityField__c ='Quantity';

                discNameToSchedule.put(ds,sds);
            }
            else {
                toDeleteDiscTiers.put(ds, existingDisSchedules.get(ds.right(80).trim()));
                listOfDiscTiersTOBeDeleted.add(ds.right(80).trim());
            }
        }
        return discNameToSchedule;
    }

    public static List<SBQQ__DiscountTier__c> createDiscountTiers(Map<String,List<CPQ_PM_UtilityClass.Tiers>> discountSchedules, Map<String,SBQQ__DiscountSchedule__c> discNameToSchedule){

        List<SBQQ__DiscountTier__c> tierList = new List<SBQQ__DiscountTier__c>();

        for(String ds :discountSchedules.keySet()){

            Integer tierName = 1;
            Decimal baseValue = 0;
            Boolean firstCount = true; 
            Integer upBound = 0;

            for(CPQ_PM_UtilityClass.Tiers ti : discountSchedules.get(ds)){          
                if(firstCount){
                    baseValue = decimal.valueOf(ti.geoRegionPricing[0].pricePoints.list_Z);
                }
                
                SBQQ__DiscountTier__c sdt = new SBQQ__DiscountTier__c();               
                if(!firstCount && ti.tierHigh.value != null && baseValue != 0){
                    sdt.name = String.valueOf(tierName++);
                    sdt.SBQQ__Schedule__c = (discNameToSchedule.get(ds) != null) ? discNameToSchedule.get(ds).id : toDeleteDiscTiers.get(ds);
                    if(upBound != 0 && upBound != ti.tierLow.value){
                        ti.tierLow.value = upBound;
                    }

                    sdt.SBQQ__LowerBound__c = ti.tierLow.value;
                    sdt.SBQQ__UpperBound__c = ti.tierHigh.value;
                    upBound = ti.tierHigh.value;

                    sdt.SBQQ__Discount__c = ((baseValue - decimal.valueOf(ti.geoRegionPricing[0].pricePoints.list_Z))/baseValue) * 100;
                    tierList.add(sdt);
                }
                firstCount = false;
            }
        }
        return tierList;
    }

    public static List<SBQQ__DiscountTier__c> deleteExistingDisTiers(){
        return [Select Id from SBQQ__DiscountTier__c where SBQQ__Schedule__r.Name IN: listOfDiscTiersTOBeDeleted];
    }

    public static void createDiscountSchedules(Map<String,List<CPQ_PM_UtilityClass.Tiers>> discountSchedules){
        
        Map<String,SBQQ__DiscountSchedule__c> discNameToSchedule = new Map<String,SBQQ__DiscountSchedule__c>();
        discNameToSchedule = validateAndMap(discountSchedules);

        List<SBQQ__DiscountTier__c> existingDiscTiers = deleteExistingDisTiers();
        if(existingDiscTiers.size() > 0){
            Database.delete(existingDiscTiers);
        }

        if(discNameToSchedule.size() > 0){
            Database.insert(discNameToSchedule.values(),false);
        }
        List<SBQQ__DiscountTier__c> tierList = new List<SBQQ__DiscountTier__c>();
        tierList = createDiscountTiers(discountSchedules,discNameToSchedule);
        if(tierList.size() > 0){
            Database.insert(tierList,false);
        }
    }
}