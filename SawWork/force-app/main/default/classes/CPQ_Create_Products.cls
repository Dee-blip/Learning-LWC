/**
* Test Class: CPQ_Test_CPQ_Create_Products
* @author  Mausam Singh
* @since   2022-04-03
*/
public with sharing class CPQ_Create_Products {

public static void createProducts(Map<String, CPQ_ProductLaunchManagement__c> plmMap, Map<String, CPQ_ProductLaunchSetting__c> productSettings,String typeOfProduct)
{
        insert plmMap.values();

        for(String productCode : productSettings.KeySet()){
            if(typeOfProduct =='Carrier'){
                System.enqueueJob(new CPQ_AsyncProductCloneCarrier(productCode,productSettings.get(productCode),plmMap.get(productCode)));
            }
            else{
                System.enqueueJob(new CPQ_AsyncProductClone(productCode,productSettings.get(productCode),plmMap.get(productCode)));
            }  
        }   
}
}