/* CPQ_Product_Launch_Controller is a used for product launch management  
* Test Class: CPQ_Test_Product_Search_Controller
* @author  Mausam Singh
* @since   2021-09-23
*/
public with sharing class CPQ_Product_Launch_Controller {

/*
* This method query the CPQ_ProductLaunchManagement__c object and return list of records
*/ 

@AuraEnabled(cacheable=true)
public static List<CPQ_ProductLaunchManagement__c> getProdLaunchList(Id launchId, String typeOfProduct) {

List<CPQ_ProductLaunchManagement__c> launchList = new List<CPQ_ProductLaunchManagement__c>();
launchList = [SELECT Id,Name,Product__c,Product_Name__c,Version__c,Launch__c,Product_previous_version__c,Product__r.Name,Product__r.CPQ_Reviewed__c,Launch__r.Name,Product_previous_version__r.Name,Product_Launch_Status__c,Product_Creation_Status__c,productValidation__c
                FROM CPQ_ProductLaunchManagement__c WHERE Launch__c  =:launchId AND Product_Type__c =:typeOfProduct];
System.debug(LoggingLevel.INFO, 'launchList ==> ' + launchList);
return launchList;

}

/*
* This method handles the activation/deactivation of product and updates the CPQ_ProductLaunchManagement__c records
* No caching is required - DML is performed in this method
*/
@AuraEnabled
public static boolean launchSelectedProduct(List<Id> launchManagementIds){
    Set<Id> launchSet = new Set<Id>();
    launchSet.addAll(launchManagementIds);
    
    List<CPQ_ProductLaunchManagement__c> newlaunchList = new List<CPQ_ProductLaunchManagement__c>();
    Map<Id,String> productLaunchMap = new Map<Id,String>();
    List<CPQ_ProductLaunchManagement__c> launchList = new List<CPQ_ProductLaunchManagement__c>();
    launchList = [SELECT Id,Product__c,Product_Name__c,Launch__c,Launch__r.Name,Product_previous_version__c,Product__r.isActive,Product_previous_version__r.isActive,Product_Launch_Status__c FROM CPQ_ProductLaunchManagement__c WHERE id  =:launchSet];
    
    // Making old version of the product inactive
    Set<Id> oldProductSet = new Set<Id>();
    for(CPQ_ProductLaunchManagement__c cpl : launchList)
    {
        if(cpl.Product_previous_version__c!=null)
            
        {
            oldProductSet.add(cpl.Product_previous_version__c);
        }  
    }
    List<Product2> prodList = new List<Product2>();
    for(Product2 product :[SELECT id,Name,isActive FROM Product2 WHERE Id IN: oldProductSet])
    {
        product.isActive = false;
        prodlist.add(product);
        System.debug(LoggingLevel.INFO, 'prodList ==> ' + prodList);
        
    }
    if(!prodlist.isEmpty())
    {    
        update prodList;    
    }

    // Making new version of the product active
    Set<Id> newProductSet = new Set<Id>();
    for(CPQ_ProductLaunchManagement__c cpl : launchList)
    {
        if(cpl.Product__c!=null)
        {
            newProductSet.add(cpl.Product__c);
            productLaunchMap.put(cpl.Product__c,cpl.Launch__r.Name);
        }
        
    }
    List<Product2> newProdList = new List<Product2>();
    for(Product2 product :[SELECT id,Name,isActive,CPQ_Launch__c FROM Product2 WHERE Id IN: newProductSet]) 
    {
        product.isActive = true;
        product.CPQ_Launch__c = productLaunchMap.get(product.Id);  
        newProdList.add(product);
        System.debug(LoggingLevel.INFO, 'newProdList ==> ' + newProdList);
    }
    if(!newProdList.isEmpty())  
    {
    update newProdList;
    }
    // Updating Launch Management - Launch Status
    for(CPQ_ProductLaunchManagement__c cpl :launchList){
        cpl = new CPQ_PM_UtilityClass.productLaunchRecordBuilder(cpl)
                                        .setLaunchStatus('Activated').setCreationStatus('Success').setCreationMessage('Successfully created and launched')
                                        .getRecord();
        newlaunchList.add(cpl);
        System.debug(LoggingLevel.INFO, 'newlaunchList ==> ' + newlaunchList);
    }
    if(!newlaunchList.isEmpty()){
        update newlaunchList;
    }  
return true;
}
@AuraEnabled
public static boolean unlinkPlm(List<Id> plmIds){
    List<CPQ_ProductLaunchManagement__c> productLaunchManagementList = new list<CPQ_ProductLaunchManagement__c>();
    List<CPQ_ProductLaunchManagement__c> productLaunchManagementListToUnlink = new list<CPQ_ProductLaunchManagement__c>();

    productLaunchManagementList = [ SELECT id,Launch__c,Product__c  FROM CPQ_ProductLaunchManagement__c WHERE id =: plmIds];

    for(CPQ_ProductLaunchManagement__c cpl : productLaunchManagementList ){
        if(cpl.Launch__c!=null){
            cpl.Launch__c=null;
            productLaunchManagementListToUnlink.add(cpl);
        }   
    }

    if(!productLaunchManagementListToUnlink.isEmpty() && CPQ_ProductLaunchManagement__c.SObjectType.getDescribe().isUpdateable()) {
                update productLaunchManagementListToUnlink;
    }
    // Unlink launch from the product
    Set<Id> newProductSet = new Set<Id>();
    for(CPQ_ProductLaunchManagement__c cpl : productLaunchManagementList)
    {
        if(cpl.Product__c!=null)
        {
            newProductSet.add(cpl.Product__c);
        }
        
    }
    List<Product2> newProdList = new List<Product2>();
    for(Product2 product :[SELECT id,Name,isActive,CPQ_Launch__c FROM Product2 WHERE Id IN: newProductSet]) 
    {
        product.CPQ_Launch__c = '';
        newProdList.add(product);
    }
    if(!newProdList.isEmpty())  
    {
    update newProdList;
    }
    return true; 
}

}