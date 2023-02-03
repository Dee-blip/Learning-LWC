public class L2Q_ChimeProductsLinksController {
    @AuraEnabled
    public static List<PAC_Product_Catalog__c>  getProductLOEDetailsForLink(){
        return [Select Id,Product_Name__c,Default_LOE_Managed__c,Default_LOE_Standard__c from PAC_Product_Catalog__c Where IsActive__c = true AND Is_Available_For_Chime__c = true order by Product_Name__c asc];
      
    }
    
}