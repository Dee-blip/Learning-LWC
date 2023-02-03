/*   
* Test Class: CPQ_Test_Product_Search_Controller
* @author  Mausam Singh
* @since   2021-09-23
*/
public with sharing class CPQ_Product_Search_Controller {
    public static  Map<String, CPQ_ProductLaunchSetting__c> productSettingsMap =  new Map<String, CPQ_ProductLaunchSetting__c>();
    public static  Map<String, CPQ_ProductLaunchManagement__c> plmMap = new Map<String, CPQ_ProductLaunchManagement__c>();
    public static  Map<String, String> launchMap = new Map<String, String>();
    public static  Map<String, SectionWrapper> sectionWrapperMap = new Map<String, SectionWrapper>();
    private final static Integer MAX_RESULTS = 5;
    
    /*
    * This method perform search on the productIds and return the valid products Ids
    */ 
    
    @AuraEnabled(Cacheable=true)
    public static List<CPQ_Lookup_Search_Result> search(String searchTerm, List<String> selectedIds, String type) {
    // Prepare query paramters
    searchTerm += '*';
    String recordType = type+'_Products';
    
    // Execute search query
    List<List<SObject>> searchResults = [
        FIND :searchTerm
        IN ALL FIELDS
        RETURNING
        Product2(Id, ProductCode, Name WHERE id NOT IN :selectedIds AND CPQ_Record_Type_Name__c =:recordType AND IsActive = TRUE)
        LIMIT :MAX_RESULTS];
    
    // Prepare results
    List<CPQ_Lookup_Search_Result> results = new List<CPQ_Lookup_Search_Result>();
    
    // Extract PLU__c & convert them into CPQ_Lookup_Search_Result
    String accountIcon = 'utility:product_service_campaign';
    Product2[] launchsettings = (List<Product2>) searchResults[0];
    for (Product2 cpl : launchsettings) {
        String subtitle = cpl.ProductCode == null ? 'Product2' : cpl.ProductCode;
        results.add(new CPQ_Lookup_Search_Result(cpl.Id, 'Product2', accountIcon, cpl.Name, subtitle));
    }
    // Optionnaly sort all results on title
    results.sort();
    
    return results;
    }
    
    /*
    * This method get the features from section API and helps to set the deatils in the accordion section (Product_Setup_Component) 
    */
    
    @AuraEnabled(cacheable=true)
    public static Map<String,SectionWrapper> fetchSectionDetails(List<String> productIds,Map<String,String> sectionData){ 
    System.debug(LoggingLevel.INFO, 'productIds ==> ' + productIds);
        for(String productId: productIds)
        {    
            sectionWrapperMap.putAll(getSectionDetails(productId,sectionData.get(productId)));
        }
    return sectionWrapperMap;
    }
    
    /*
    * This method initates the product creation process
    * No caching is required - DML is performed in this method
    */
    
    @AuraEnabled
    public static ValidatePLM createProductSettings( Id releaseId, String  productSettings, String typeOfProduct){
    
    System.debug(LoggingLevel.INFO, 'releaseId ==> ' + releaseId +'productSettings ==> ' + productSettings);
    
        List<ProductWrapper> productDetails = new List<ProductWrapper>();
         
        // Constructing data to create CPQ_Launch_Setting record and CPQ_ProductLaunchManagement__c record
        
        productDetails = (List<ProductWrapper>)JSON.deserialize(productSettings,List<ProductWrapper>.class);
        for(ProductWrapper prod : productDetails){
            productSettingsMap.put(prod.productId,new CPQ_ProductLaunchSetting__c(BillingModels__c=(prod.billingModels!=null&&prod.billingModels!='')?(prod.billingModels.replace(',',';')):null,UsageSectionNumber__c=prod.usage,Product_Mkt_Code__c=prod.productId,Name=prod.productId,Available__c= true) );//,Product_Type__c=typeOfProduct) );
            launchMap.put(prod.productId,prod.name);  // needs improvement
        }
    
        System.debug(LoggingLevel.INFO, 'productSettingsMap ==> ' + productSettingsMap);
    
        // Handle Duplicates
        ValidatePLM validatedPLM = checkDuplicatePLM(releaseId);
        System.debug(LoggingLevel.INFO, 'validatedPLM ==> ' + validatedPLM);
    
        if(validatedPLM.isDuplicate){
           
            return validatedPLM;
        }
          
        
    
        // Handling CPQ_Launch_Management Creation
    
        for(String productId: launchMap.Keyset()){
            CPQ_ProductLaunchManagement__c tempHolder = getRecordWithDefaultValues(releaseId, productId,launchMap.get(productId),typeOfProduct);
            plmMap.put(productId, tempHolder);  
        }

        /* 
        <-- Handle Carrier PriceBooks --> 
        <--Callout to CPQ_Create_Products for final product creation-->
        <-- plmMap --> Launch Management info, productSettingsMap --> Product Setting Info  , typeOf Product -- Carrier OR Partner)
        */
        CPQ_Create_Products.createProducts(plmMap,productSettingsMap,typeOfProduct);
        
        // Handling CPQ_Launch_Setting Creation after callout to avoid error
        getRecord();
        return validatedPLM;

        
    }
    public class ProductWrapper{
    public String productId;
    public String name;
    public String billingModels;
    public Integer usage;
    public Boolean availabel;  
    }
    
    /* 
    * Constructing CPQ_Launch_Management record
    */
    
    public static CPQ_ProductLaunchManagement__c getRecordWithDefaultValues(Id launchId, String productCode, String productName, String typeOfProduct){
    
    CPQ_ProductLaunchManagement__c returnRecord =  new CPQ_ProductLaunchManagement__c();
    List<Product2> prodlist = new List<Product2>();
    prodlist =[Select id,Name from Product2 WHERE ProductCode =: productCode ORDER BY createdDate desc limit 1 ];
    returnRecord.Name = productCode;
    returnRecord.Product_Name__c = productName;
    returnRecord.Launch__c = launchId;
    returnRecord.Product_Creation_Status__c = 'In Progress';
    returnRecord.Product_Launch_Status__c = 'Draft';
    returnRecord.Product_Type__c = typeOfProduct;
    if(!prodlist.isEmpty()){
        for(Product2 p :prodlist ){
            returnRecord.Product_previous_version__c = p.id;
        }
    }
    return returnRecord;
    }
    
    /* 
    * Handles creation of new CPQ launch Setting and Update the existing Launch Setting record
    */
    public static void getRecord(){
    
    Map<Id,CPQ_ProductLaunchSetting__c> existingProductSetting =  new Map<Id,CPQ_ProductLaunchSetting__c>();
    Map<String,CPQ_ProductLaunchSetting__c> ignoreProductSetting = new Map<String,CPQ_ProductLaunchSetting__c>();
    
    List<CPQ_ProductLaunchSetting__c> productSettingList = [SELECT id,Product_Mkt_Code__c,BillingModels__c,UsageSectionNumber__c FROM CPQ_ProductLaunchSetting__c WHERE Product_Mkt_Code__c IN :productSettingsMap.Keyset()];
    
    for(CPQ_ProductLaunchSetting__c prodSetting :productSettingList )
    {
        prodSetting.BillingModels__c = productSettingsMap.get(prodSetting.Product_Mkt_Code__c).BillingModels__c;
        prodSetting.UsageSectionNumber__c = productSettingsMap.get(prodSetting.Product_Mkt_Code__c).UsageSectionNumber__c;
        existingProductSetting.put(prodSetting.id,prodSetting);
        ignoreProductSetting.put(prodSetting.Product_Mkt_Code__c,prodSetting);
    }
    
    System.debug(LoggingLevel.INFO, 'existingProductSetting ==> ' + existingProductSetting);
    update existingProductSetting.values();
    
    Map<String, CPQ_ProductLaunchSetting__c> newProductSetting =  new Map<String, CPQ_ProductLaunchSetting__c>(productSettingsMap);
    for (String key : ignoreProductSetting.keySet())
    {
        newProductSetting.remove(key);
    }
    System.debug(LoggingLevel.INFO, 'newProductSetting ==> ' + newProductSetting);
    insert newProductSetting.values();
    }
    /* 
    * Handles creation of accordion section on UI */
    
    public static Map<String,SectionWrapper> getSectionDetails(String productId,String sectionData){ 
    System.debug(LoggingLevel.INFO, 'productId ==> ' + productId);
        // Constructing section details for products with no data in CPQ Launch Setting
    
        SectionWrapper sectionInfo = new SectionWrapper();
        sectionInfo.sectionData = sectionData ;
        sectionWrapperMap.put(productId,sectionInfo);
        
        // Constructing section details for products with data in CPQ Launch Setting
    
    List<CPQ_ProductLaunchSetting__c> productSettingList = new List<CPQ_ProductLaunchSetting__c>();
    productSettingList=[SELECT id,Available__c,ProductLabel__c,Product_Mkt_Code__c,BillingModels__c,UsageSectionName__c,UsageSectionNumber__c FROM CPQ_ProductLaunchSetting__c WHERE Product_Mkt_Code__c =: productId];
    
    if(!productSettingList.isEmpty()){
        for(CPQ_ProductLaunchSetting__c productSetting  : productSettingList){
        
            SectionWrapper existingSectionInfo = new SectionWrapper();
            existingSectionInfo.sectionData = sectionData;
            existingSectionInfo.billingInfo =  productSetting.BillingModels__c;
            existingSectionInfo.preSelected = new List<Integer>{Integer.valueOf(productSetting.UsageSectionNumber__c)};
            existingSectionInfo.available = productSetting.Available__c;
            sectionWrapperMap.put(productSetting.Product_Mkt_Code__c,existingSectionInfo);   
        }
    } 
    System.debug(LoggingLevel.INFO, 'sectionWrapperMap ==> ' + sectionWrapperMap);
    return sectionWrapperMap;
    }
    public class SectionWrapper{
    
    @AuraEnabled public String sectionData;
    @AuraEnabled public String billingInfo;
    @AuraEnabled public Boolean available;
    @AuraEnabled public List<Integer> preSelected;   
    }
    
    public static ValidatePLM checkDuplicatePLM(Id releaseId){
    
    // Handling Duplication
    Integer count = 0;
    List<CPQ_ProductLaunchManagement__c> launchList = new List<CPQ_ProductLaunchManagement__c>();
    launchList = [SELECT Id,Name,Product__r.Name,Launch__r.Name,Product_Creation_Status__c FROM CPQ_ProductLaunchManagement__c WHERE Launch__c  =:releaseId AND Name =: launchMap.Keyset() ];
       
        Map<String,CPQ_ProductLaunchManagement__c> mapCpl = new Map<String,CPQ_ProductLaunchManagement__c>();
        ValidatePLM duplicatePlM = new ValidatePLM();  
        for(CPQ_ProductLaunchManagement__c cpl : launchList)
        {
        String plmKey = cpl.Launch__c+'_'+cpl.Name;
        mapCpl.put(plmKey,cpl);
        }
    
        for(String productId: launchMap.Keyset())
        {
        String key = releaseId+'_'+productId;
        if(mapCpl.containsKey(key))
        {   
            duplicatePlM.duplicateProductCodeNames.add(productId);
            count++;
            System.debug(LoggingLevel.INFO, 'count ==> ' + count);
        }
        }
        if(count>0){
    
           duplicatePlM.isDuplicate = true;
           return duplicatePlM;
    
        }
        duplicatePlM.isDuplicate = false;
        return duplicatePlM;
        
        
    }
    public class ValidatePLM{
        @AuraEnabled public Boolean isDuplicate;
        @AuraEnabled public List<String> duplicateProductCodeNames;
    
    public ValidatePLM(){
        duplicateProductCodeNames = new List<String>();
    }
    }
    
    
    }