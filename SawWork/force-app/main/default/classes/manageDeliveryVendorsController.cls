public class manageDeliveryVendorsController {
    
    @AuraEnabled
    public static List < Delivery_Vendor__c  > fetchDeliveryVendors(Id tsObjId) {
        
        List < Delivery_Vendor__c > returnList = new List < Delivery_Vendor__c > ();
        List < Delivery_Vendor__c > lstOfDV = [Select Id, Name, Vendor_Traffic_Share__c, Can_Akamai_get_more_traffic__c, 
                                               PB_Month__c,Unit_of_Measure__c, Amount__c,Additional_Traffic_Comments__c, Delivery_Vendor__c  from 
                                               Delivery_Vendor__c where Traffic_Share__c = :tsObjId];
        
        for (Delivery_Vendor__c dv: lstOfDV) {
            returnList.add(dv);
        }
        return returnList;
    }
    
    @AuraEnabled
    public static String saveVendors(List<Delivery_Vendor__c> vendorList,List<Delivery_Vendor__c> deletevendorList){
        try{
            if(deletevendorList.size() > 0)
                Database.delete(deletevendorList);
            if(vendorList.size() > 0)
        		Database.Upsert(vendorList);
            return 'success';
        } catch (Exception e) {
            string error= e.getMessage();
            system.debug('Swati'+error);
            string customErrorMsg = GSMUtilClass.getGSMSettingValue('DeliveryVendorErrorMsg');
            string validationError= GSMUtilClass.getGSMSettingValue('DeliveryVendorValidation');
            
            if(error.contains('duplicate value found: Delivery_Vendor_Unique_Key__c'))
                return customErrorMsg;
            else if(error.contains('This field cannot be selected as'))
                return validationError;
            else
                return error;
        }
    }

    @AuraEnabled
    public static list<String> fetchVendorList(){
        
        list<string> vendorList =new list<string>();
        string vendorValue = GSMUtilClass.getGSMSettingValue('DeliveryVendorList');
        if(vendorValue != null)
            vendorList = vendorValue.split(',');
        system.debug('Swati>>'+vendorList);
        return vendorList;
       
    }

}