public with sharing class EB_ProductCatalogComponent extends SI_ComponentControllerBase
{
    private Map<String, Integer> listPosition = null;  
    private Map<String, List<String>> sortedFieldValuesPerFieldName = null;  
    private Map<String, Map<String, List<String>>> sObjectIDsPerFieldNames = null;
    
    public List<sObject> originalList {get; set;}
    public static Integer getCountPrdCatalogSelected{get;set;}
    public static Integer getCountLegacyPrdSelected{get;set;}        
    public List<EB_ProductWrapper> searchedProductsWrapper{get;set;}   
    public Boolean renderSearchedPanelTrue{get;set;}
    public Boolean renderSearchedPanelFalse{get;set;}
    List<EB_ProductWrapper> tempProductWrapper = new List<EB_ProductWrapper>();
    public Integer countOfSelectedProducts{get;set;}
    public List<EB_Product__c> selectedLegacyProductList{get;set;}
    public List<EB_Product__c> selectedPrdCatProductList{get;set;}
    public String searchString{get;set;}
    public EB_ProductWrapper products{get;set;}
    //Start of changes by ssawhney for CR 2528913 Fix exception in production
    //changed to list of list 
    public list<List<EB_ProductWrapper>> wrappers{get;set;}    
    public List<EB_ProductWrapper> legacyProductList{get;set;}
    
    private Map<String,Set<EB_Product__c>> productModules = new Map<String,Set<EB_Product__c>>();
    private Map<String,Set<EB_Product__c>> moduleSubModules = new Map<String,Set<EB_Product__c>>(); 
    public Set<EB_Product__c> selectedProductList = new Set<EB_Product__c>();
     
    private List<EB_Product__c> productsList = new List<EB_Product__c>();   
    public Boolean renderNewProductSearch{get;set;}
    public Boolean renderOldProductSearch{get;set;}
    
    public List<EB_ProductWrapper> selPrdList{get;set;}
    public String SelectedPrdDetails{get;set;}
    
    //Start of changes by janantha for CR 1799680 to display the hierarchy of selected products
    public Map<String,String> productNameProductId{get;set;}
    public Map<String,String> productIdProductName{get;set;}
    public Map<String,String> productIdParentProductId{get;set;}
    public Map<String,String> submoduleIdModuleId{get;set;}
    public Map<String,String> moduleIdProductId{get;set;}
    List<String> selectedModuleIdList = new List<String>();
    Set<String> selectedModuleIdSet = new Set<String>();
    Set<String> selectedSubModuleIdSet = new Set<String>(); 
    public Set<String> productNamesPrdCat{get;set;}  
    
    public Set<EB_Product__c> impactedProductSet{get;set;}
    public List<SI_ServiceIncidentImpactedProducts__c> impactedProductListToInsert = new List<SI_ServiceIncidentImpactedProducts__c>(); 
    //End of changes by janantha for CR 1799680 to display the hierarchy of selected products
    
    String incidentName = '';
    
    
     
    public EB_ProductCatalogComponent()
    {
        //Start of changes by janantha for CR 1799680
        selectedLegacyProductList = new List<EB_Product__c>();
        selectedPrdCatProductList = new List<EB_Product__c>();
        getCountPrdCatalogSelected = 0;
        getCountLegacyPrdSelected = 0;
        renderSearchedPanelTrue = false;
        renderSearchedPanelFalse = true;
        productNameProductId = new Map<String,String>();
        productIdProductName = new Map<String,String>();
        productIdParentProductId = new Map<String,String>();
        submoduleIdModuleId = new Map<String,String>();
        moduleIdProductId = new Map<String,String>();
        
        String tempModuleId = '';
        String tempProductId = '';
        String tempParentConcat = '';
        selPrdList = new List<EB_ProductWrapper>();
        impactedProductSet = new Set<EB_Product__c>();   
        
        incidentName = ApexPages.currentPage().getParameters().get('incidentName');   
        //End of changes by janantha for CR 1799680
         
        try
        { 
            //Start of changes by janantha for CR 1799680 to display the hierarchy of selected products
            //form a map of product name and product id
            
            productNamesPrdCat = new Set<String>();
            for(EB_Product__c product:[select Id,EB_ProductId__c,Product_Name__c,EB_ParentId__c,EB_ProductType__c from EB_Product__c where (EB_ProductId__c!=null and EB_ProductId__c!='')])
            {
                productNamesPrdCat.add('"'+product.Product_Name__c+'"');    
            }      
           
            //End of changes by janantha for CR 1799680 to display the hierarchy of selected products
            productModules = new Map<String,Set<EB_Product__c>>();
            moduleSubModules = new Map<String,Set<EB_Product__c>>();
            productsList = new List<EB_Product__c>();
                          
           /* if(EB_UtilApplication.getProperty('ProductSearch') == 'Product Catalog')
            {
                renderNewProductSearch = true;
                renderOldProductSearch = false;
            }
            
            else
            {
                renderNewProductSearch = false;
                renderOldProductSearch = true;
            }*/
            
            /*if(EB_UtilApplication.getProperty('ProductSearch') == 'Product Catalog')
            {*/
                   
                products = new EB_ProductWrapper();
                Set<EB_Product__c> productModuleIds; 
                Set<EB_Product__c> productSet = new Set<EB_Product__c>();
                Set<EB_Product__c> moduleSet = new Set<EB_Product__c>();
                Set<EB_Product__c> productSubModuleIds;
                Set<EB_Product__c> legacyProducts = new Set<EB_Product__c>();
                       
                for(EB_Product__c product:[select EB_ProductId__c,Product_Name__c,EB_ParentId__c,EB_ProductType__c from EB_Product__c where EB_ProductType__c = 'Module'])
                {
                    productModuleIds = new Set<EB_Product__c>();
                    productSet = new Set<EB_Product__c>();
                    
                    if (productModules.containsKey(product.EB_ParentId__c) == true)
                    {  
                        productModuleIds=productModules.remove(product.EB_ParentId__c);                                      
                    }
                    
                    productSet.addAll(productModuleIds);
                    productSet.add(product);
                                      
                    productModules.put(product.EB_ParentId__c, productSet); 
                                                    
                }
                
                for(EB_Product__c product:[select Id,EB_ProductId__c,Product_Name__c,EB_ParentId__c,EB_ProductType__c from EB_Product__c where EB_ProductType__c = 'Submodule'])
                {
                    productSubModuleIds = new Set<EB_Product__c>();
                    moduleSet = new Set<EB_Product__c>();
                    
                    if (moduleSubModules.containsKey(product.EB_ParentId__c) == true)
                    {
                        productSubModuleIds=moduleSubModules.remove(product.EB_ParentId__c);                               
                    }
                    moduleSet.addAll(productSubModuleIds);
                    moduleSet.add(product);
                    
                    moduleSubModules.put(product.EB_ParentId__c, moduleSet);
                    
                }   
               
                productsList = new List<EB_Product__c>();
                for(EB_Product__c product:[select Id,EB_ProductId__c,Product_Name__c,EB_ProductType__c from EB_Product__c where EB_ProductType__c = 'Product'])
                {                   
                    productsList.add(product);           
                }
                
                originalList = productsList;
                productsList = new List<EB_Product__c>();
                productsList = (List<EB_Product__c>)getSortedList('Product_Name__c', true);  
               
                getModuleForProduct();
                legacyProductList = new List<EB_ProductWrapper>();
                for(EB_Product__c product:[select Product_Name__c,EB_ProductType__c from EB_Product__c where EB_ProductType__c = 'Case Product'])
                {
                    EB_ProductWrapper legacyWrapper = new EB_ProductWrapper(product);
                    legacyProductList.add(legacyWrapper);           
                }              
           // }            
        }
        catch(Exception eCons){               
                ApexPages.Message myMsg;                
                myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,eCons.getMessage());              
                ApexPages.addMessage(myMsg);
        }         
    }
    
    
    public List<sObject> getSortedList(String fieldName, Boolean ascending) {
            
        fieldName = fieldName.toUpperCase();       
        return makeSortedList(fieldName, ascending);
    }
    
    public List<sObject> getSortedList(List<sObject> originalList, String fieldName, Boolean ascending) {
        this.originalList = originalList;
        sortedFieldValuesPerFieldName = null;
        return getSortedList(fieldName, ascending);
    }
    

    private void InitializeFieldName(String fieldName) {
        String sObjectID;
        Integer position;
        String fieldValue;
        List<String> sObjectIDs = null;
        Set<String> valuesForFieldSet = null;   
        List<String> valuesForFieldList = null;
        Map<String, List<String>> sObjectIDsPerFieldValues = null;
        
        if (sortedFieldValuesPerFieldName == null) {
            listPosition = new Map<String, Integer>();
            sortedFieldValuesPerFieldName = new Map<String, List<String>>();
            sObjectIDsPerFieldNames = new Map<String, Map<String, List<String>>>();
        }
        
        sObjectIDsPerFieldValues = sObjectIDsPerFieldNames.get(fieldName);
        if (sObjectIDsPerFieldValues == null) {
            sObjectIDsPerFieldValues = new Map<String, List<String>>();
            /*<field name, <sObject id, field value>>*/
            sObjectIDsPerFieldNames.put(fieldName, sObjectIDsPerFieldValues);
        }
        if (!sortedFieldValuesPerFieldName.keySet().contains(fieldName)) {
            
            position = 0;
            valuesForFieldSet = new Set<String>();
            listPosition = new Map<String, Integer>();
            
            for (sObject sObj : originalList) {
                sObjectID = sObj.ID;
                fieldValue = getValue(sObj, fieldName);
                               
                listPosition.put(sObjectID, position++);
                
                valuesForFieldSet.add(fieldValue);
                
                sObjectIDs = sObjectIDsPerFieldValues.get(fieldValue);
                if (sObjectIDs == null) {
                    sObjectIDs = new List<String>();
                    sObjectIDsPerFieldValues.put(fieldValue, sObjectIDs);
                }
                
                sObjectIDs.add(sObjectID);
            }
            
            valuesForFieldList = new List<String>();
            valuesForFieldList.addAll(valuesForFieldSet);
            valuesForFieldList.sort();
            
            sortedFieldValuesPerFieldName.put(fieldName, valuesForFieldList);
            
        }
    }
    private List<sObject> makeSortedList(String fieldName, Boolean ascending) {
        Integer position;
        List<String> sObjectIDs = null;
        List<String> valuesForFieldList = null;      
        InitializeFieldName(fieldName);     
        List<sObject> outputList = originalList.clone();
        outputList.clear();       
        valuesForFieldList = sortedFieldValuesPerFieldName.get(fieldName);
        
        for (String fieldValue : valuesForFieldList) {       
            sObjectIDs = sObjectIDsPerFieldNames.get(fieldName).get(fieldValue);
          
            for (String ID : sObjectIDs) {                
                position = listPosition.get(ID);               
                if ((ascending) || (outputList.size()==0)) {
                    outputList.add(originalList[position]);
                } else {
                    outputList.add(0, originalList[position]);
                }
            }
        }
       
        return outputList;      
    }
    private static String getValue(sObject sObj, String fieldName) {
      
        Integer pieceCount;
        String[] fieldNamePieces;
        
        fieldNamePieces = fieldName.split('\\.');
        pieceCount = fieldNamePieces.size();
        for (Integer i = 0; i < (pieceCount-1); i++) {
            sObj = sObj.getSObject(fieldNamePieces[i]);
        }
        return String.valueOf(sObj.get(fieldNamePieces[pieceCount-1]));
    }
    
    public list<List<EB_ProductWrapper>> getModuleForProduct() 
    {
        try
        {
            //Start of changes by ssawhney for CR 2528913
            wrappers = new list<List<EB_ProductWrapper>>();
            list<EB_ProductWrapper> lstModules = new list<EB_ProductWrapper>();
            
            Set<EB_Product__c> modulesFor1Product = new Set<EB_Product__c>();
            Set<EB_Product__c> subModulesFor1Module = new Set<EB_Product__c>();
            
            for(EB_Product__c product:productsList)
            {
                EB_ProductWrapper wrapper = new EB_ProductWrapper(product);
                //added to restirct lists with more than 1000 products in them 
                if(lstModules.size() < 1000)
                {
                    lstModules.add(wrapper);
                }
                else
                {
                    wrappers.add(lstModules);
                    lstModules = new list<EB_ProductWrapper>();
                    lstModules.add(wrapper);
                }            
       
                ///wrappers.add(wrapper);
                //changes for sort
                modulesFor1Product = productModules.get(product.EB_ProductId__c);
               
                if(modulesFor1Product!=null)
                {
                    for(EB_Product__c module:modulesFor1Product)
                    {
                        EB_ProductWrapper wrapper1 = new EB_ProductWrapper(module);
                        if(lstModules.size() < 1000)
                        {
                            lstModules.add(wrapper1);
                        }
                        else
                        {
                            wrappers.add(lstModules);
                            lstModules = new list<EB_ProductWrapper>();
                            lstModules.add(wrapper1);
                        }    
                        
                        subModulesFor1Module = moduleSubModules.get(module.EB_ProductId__c);
                        
                        if(subModulesFor1Module!=null)
                        {
                            for(EB_Product__c subModule:subModulesFor1Module)
                            {
                                EB_ProductWrapper wrapper2 = new EB_ProductWrapper(subModule);                          
                                if(lstModules.size() < 1000)
                                {
                                    lstModules.add(wrapper2);
                                }
                                else
                                {
                                    wrappers.add(lstModules);
                                    lstModules = new list<EB_ProductWrapper>();
                                    lstModules.add(wrapper2);
                                }    
                            }
                        }
                    }
                }               
            }
            if(lstModules.size()>0)
                wrappers.add(lstModules);
            //End of changes by ssawhney for CR 2528913
            return wrappers;
        }
        catch(Exception eWrapper){
                ApexPages.Message myMsg;                
                myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,eWrapper.getMessage());              
                ApexPages.addMessage(myMsg);
                return null;
        }
    }
    
    public PageReference getSelectedProducts()
    {       
        //Start of changes by janantha for CR 1799680   
        List<EB_Product__c> tempProductList = new List<EB_Product__c>();
        Set<EB_Product__c> tempProductSet = new Set<EB_Product__c>();
        List<EB_Product__c> tempLegacyProductList = new List<EB_Product__c>();
        Set<EB_Product__c> tempLegacyProductSet = new Set<EB_Product__c>();
        //End of changes by janantha for CR 1799680
        //selectedProductList.clear();
        Integer dup=0;
        
        try
        {
        for(list<EB_ProductWrapper> lstWrappers : wrappers)
        {     
            for(EB_ProductWrapper prdWrapper: lstWrappers)
            {
                if(prdWrapper.selected == true)
                {
                    selectedProductList.add(prdWrapper.product); 
                    //Start of changes by janantha for CR 1799680
                    selectedPrdCatProductList.add(prdWrapper.product);              
                    //End of changes by janantha for CR 1799680               
                }
                
                else if(selectedProductList.Contains(prdWrapper.product) && prdWrapper.selected == false)
                {                            
                    selectedProductList.remove(prdWrapper.product);               
                }  
            }                  
        }
        if(searchedProductsWrapper!=null)
        {
            for(EB_ProductWrapper prdWrapper : searchedProductsWrapper)
            {            
                if(prdWrapper.selected == true)
                {
                    selectedProductList.add(prdWrapper.product); 
                    //Start of changes by janantha for CR 1799680
                    selectedPrdCatProductList.add(prdWrapper.product);              
                    //End of changes by janantha for CR 1799680               
                }
                
                else if(selectedProductList.Contains(prdWrapper.product) && prdWrapper.selected == false)
                {                            
                    selectedProductList.remove(prdWrapper.product);               
                }          
            }
        }
        //Start of changes by janantha for CR 1799680
        for (EB_Product__c p : selectedPrdCatProductList) 
        {
            if (tempProductSet.add(p) && selectedProductList.Contains(p)) 
            {
                tempProductList.add(p);
            }
            else if(tempProductSet.add(p) && !selectedProductList.Contains(p))
            {
                tempProductList.remove(dup);
            }
            dup++;
        }
        selectedPrdCatProductList.clear();
        selectedPrdCatProductList.addAll(tempProductList);
        //End of changes by janantha for CR 1799680
        
        for(EB_ProductWrapper prdWrapper : legacyProductList)
        {           
            if(prdWrapper.selected == true)
            {
                selectedProductList.add(prdWrapper.product);
                //Start of changes by janantha for CR 1799680
                selectedLegacyProductList.add(prdWrapper.product);             
                //End of changes by janantha for CR 1799680
            }
            else if(selectedProductList.Contains(prdWrapper.product) && prdWrapper.selected == false)
            {                
                selectedProductList.remove(prdWrapper.product);               
            }
        }
        //Start of changes by janantha for CR 1799680
        dup = 0;
        for (EB_Product__c p : selectedLegacyProductList) 
        {
            if (tempLegacyProductSet.add(p) && selectedProductList.Contains(p)) 
            {
                tempLegacyProductList.add(p);
            }
            else if(tempLegacyProductSet.add(p) && !selectedProductList.Contains(p))
            {
                tempLegacyProductList.remove(dup);
            }
            dup++;
        }
        selectedLegacyProductList.clear();
        selectedLegacyProductList.addAll(tempLegacyProductList);
        
        //End of changes by janantha for CR 1799680     
        return null;
        }
        catch(Exception e)
        {
            ApexPages.Message myMsg;                
            myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,e.getMessage());              
            ApexPages.addMessage(myMsg);
            return null;
        }
    }
      
    //End of changes by janantha for CR 1733044
    
    //Start of changes by janantha for CR 1799680
    public PageReference getSelectedCount()
    {  
        try
        {            
        getSelectedProducts();
              
        /*Start of set of variables required if the search string is a module*/
        Set<EB_Product__c> searchedModules = new Set<EB_Product__c>();
        Map<String,Set<EB_Product__c>> parentProductsForSearchedModules = new Map<String,Set<EB_Product__c>>();
        Set<EB_Product__c> tempModules = new Set<EB_Product__c>();
        /*End of set of variables required if the search string is a module*/
        
        /*Start of set of variables required if the search string is a Submodule*/
        Map<String,Set<EB_Product__c>> productModulesSearched = new Map<String,Set<EB_Product__c>>();
        Set<EB_Product__c> tempProductModule = new Set<EB_Product__c>();
        Set<EB_Product__c> searchedProductModule = new Set<EB_Product__c>();
        
        Map<String,Set<EB_Product__c>> modulesSearchedSubModules = new Map<String,Set<EB_Product__c>>();
        Set<EB_Product__c> tempModuleSubModule = new Set<EB_Product__c>();
        Set<EB_Product__c> searchedModuleSubModule = new Set<EB_Product__c>();
        
        Set<String> searchedSubModuleModule = new Set<String>();
        /*End of set of variables required if the search string is a Submodule*/
        
        /*Start of set of variables required if the search string is a product*/
        Set<EB_Product__c> searchedProducts = new Set<EB_Product__c>();
        /*End of set of variables required if the search string is a product*/
        
        List<EB_ProductWrapper> searchedProductsWrapper = new List<EB_ProductWrapper>();
        Set<EB_Product__c> productsOfSearchedModules = new Set<EB_Product__c>();
        Set<String> productsIdsOfSearchedModules = new Set<String>();
        Set<String> productIdsOfSearchedSubmodules = new Set<String>();
        Set<SI_ServiceIncidentImpactedProducts__c> alreadyAddedProducts = new Set<SI_ServiceIncidentImpactedProducts__c>();
        
        List<String> alreadyAddedProductIds = new List<String>();
        //searchedProductsWrapper.clear();
        List<EB_Product__c> alreadyAddedProductsList = new List<EB_Product__c>();
        /*get all the products that are already selected for that incident to display in the selected products tab.*/
        List<SI_ServiceIncidentImpactedProducts__c> tempAlreadyAddedProducts = new List<SI_ServiceIncidentImpactedProducts__c>();
        List<BMCServiceDesk__Incident__c> incidentRecord1 = [select Id from BMCServiceDesk__Incident__c where Name = :incidentName];
        tempAlreadyAddedProducts = [select SI_ProductName__r.Id,SI_ProductName__r.EB_ProductId__c,SI_ProductName__r.Product_Name__c,SI_ProductName__r.EB_ProductType__c,SI_ProductName__r.EB_ParentId__c,SI_ProductName__c from SI_ServiceIncidentImpactedProducts__c where SI_ServiceIncident__c = :incidentRecord1[0].Id];
        //alreadyAddedProducts.addAll(tempAlreadyAddedProducts);
        //System.assertEquals(tempAlreadyAddedProducts,null);
        for(SI_ServiceIncidentImpactedProducts__c siPrd:tempAlreadyAddedProducts)
        {
            alreadyAddedProductIds.add(siPrd.SI_ProductName__c);   
        }
        //System.assertEquals(alreadyAddedProductIds,null);
        alreadyAddedProductsList = [select Id,EB_ProductId__c,Product_Name__c,EB_ProductType__c,EB_ParentId__c from EB_Product__c where Id in :alreadyAddedProductIds];
        //alreadyAddedProductsSetTemp.addAll(alreadyAddedProductsList);
        selectedPrdCatProductList.addAll(alreadyAddedProductsList);           
        for(EB_Product__c product:selectedPrdCatProductList)
        {                
            if(product.EB_ProductType__c == 'Module')
            {            
                tempModules = new Set<EB_Product__c>();
                searchedModules = new Set<EB_Product__c>();
                
                if (parentProductsForSearchedModules.containsKey(product.EB_ParentId__c) == true)
                {  
                    tempModules=parentProductsForSearchedModules.remove(product.EB_ParentId__c);                                      
                }
                
                searchedModules.addAll(tempModules);
                searchedModules.add(product);
                //Map of products of the selected modules and the modules.                  
                parentProductsForSearchedModules.put(product.EB_ParentId__c, searchedModules);
            } 
           // System.assertEquals(parentProductsForSearchedModules,null);
            if(product.EB_ProductType__c == 'Submodule')
            {
                tempModuleSubModule = new Set<EB_Product__c>();
                searchedModuleSubModule = new Set<EB_Product__c>();
                
                if (modulesSearchedSubModules.containsKey(product.EB_ParentId__c) == true)
                {  
                    tempModuleSubModule=modulesSearchedSubModules.remove(product.EB_ParentId__c);                                      
                }
                
                searchedModuleSubModule.addAll(tempModuleSubModule);
                searchedModuleSubModule.add(product);
                //Map of Modules and sub modules for all searched submodules.
                modulesSearchedSubModules.put(product.EB_ParentId__c, searchedModuleSubModule);                                            
            }
            
            if(product.EB_ProductType__c == 'Product')
            {
                searchedProducts.add(product);
            }
        }
                
        if(parentProductsForSearchedModules!=null)
            productsIdsOfSearchedModules = parentProductsForSearchedModules.keySet();
        if(modulesSearchedSubModules!=null)
            searchedSubModuleModule = modulesSearchedSubModules.keySet();
        
        List<EB_Product__c> modulesofSearchedSubModules = [select Id,EB_ProductId__c,Product_Name__c,EB_ProductType__c,EB_ParentId__c from EB_Product__c where EB_ProductId__c in :searchedSubModuleModule];
        List<EB_Product__c> tempProductsOfSearchedModules = [select Id,EB_ProductId__c,Product_Name__c,EB_ProductType__c,EB_ParentId__c from EB_Product__c where EB_ProductId__c in :productsIdsOfSearchedModules];
        productsOfSearchedModules.addAll(tempProductsOfSearchedModules);
        
        if(modulesofSearchedSubModules!=null)
        {
            for(EB_Product__c module:modulesofSearchedSubModules)
            {
                tempProductModule = new Set<EB_Product__c>();
                searchedProductModule = new Set<EB_Product__c>();
                
                if (productModulesSearched.containsKey(module.EB_ParentId__c) == true)
                {  
                    tempProductModule=productModulesSearched.remove(module.EB_ParentId__c);                                      
                }
                
                searchedProductModule.addAll(tempProductModule);
                searchedProductModule.add(module);
                                  
                productModulesSearched.put(module.EB_ParentId__c, searchedProductModule);
            }
        }
        
        Set<EB_Product__c> searchedModuleList = new Set<EB_Product__c>();
               
        if(productModulesSearched!=null)
            productIdsOfSearchedSubmodules = productModulesSearched.keySet();
        Set<EB_Product__c> moduleWrapperForSearchedSubModules = new Set<EB_Product__c>();
        Set<EB_Product__c> subModuleWrapperForSearchedSubModules = new Set<EB_Product__c>();
        Set<EB_Product__c> tempModulesRemoval = new Set<EB_Product__c>();
        List<EB_Product__c> tempProductsOfSearchedSubModules = [select Id,EB_ProductId__c,Product_Name__c,EB_ProductType__c,EB_ParentId__c from EB_Product__c where EB_ProductId__c in :productIdsOfSearchedSubmodules];
        Set<EB_Product__c> productsOfSearchedSubModules = new Set<EB_Product__c>();
        productsOfSearchedSubModules.addAll(tempProductsOfSearchedSubModules);
        
        if(productsOfSearchedSubModules!=null)
        {
            for(EB_Product__c product:productsOfSearchedSubModules)
            {
                if(searchedProducts.Contains(product))
                {
                    EB_ProductWrapper searchWrapper = new EB_ProductWrapper(product);
                    searchWrapper.selected = true;                    
                    searchedProductsWrapper.add(searchWrapper);
                    searchedProducts.remove(product);     
                                   
                }
                else
                {
                    EB_ProductWrapper searchWrapper = new EB_ProductWrapper(product);
                    searchedProductsWrapper.add(searchWrapper);
                }
                /*if(productsOfSearchedModules.contains(product))
                {
                    productsOfSearchedModules.remove(product);
                } */
                /*get the set of all modules for the selected sub module*/
                moduleWrapperForSearchedSubModules = productModulesSearched.get(product.EB_ProductId__c);
                if(moduleWrapperForSearchedSubModules!=null)
                {
                    for(EB_Product__c module:moduleWrapperForSearchedSubModules)
                    {
                        tempModulesRemoval = new Set<EB_Product__c>();
                        if(parentProductsForSearchedModules != null)
                        {
                            if(parentProductsForSearchedModules.get(module.EB_ParentId__c) != null)
                            {
                                tempModulesRemoval.addAll(parentProductsForSearchedModules.remove(module.EB_ParentId__c));
                                EB_ProductWrapper searchWrapper1 = new EB_ProductWrapper(module);
                                searchWrapper1.selected = true;                            
                                searchedProductsWrapper.add(searchWrapper1);
                                tempModulesRemoval.remove(module);
                                //System.assertEquals(tempModulesRemoval,null);
                                //parentProductsForSearchedModules.remove(module.EB_ParentId__c);
                                parentProductsForSearchedModules.put(module.EB_ParentId__c,tempModulesRemoval);
                            }
                            else
                            {
                                EB_ProductWrapper searchWrapper1 = new EB_ProductWrapper(module);
                                searchedProductsWrapper.add(searchWrapper1);
                            }
                        }
                        else
                        {
                            EB_ProductWrapper searchWrapper1 = new EB_ProductWrapper(module);
                            searchedProductsWrapper.add(searchWrapper1);
                        }
                        subModuleWrapperForSearchedSubModules = modulesSearchedSubModules.get(module.EB_ProductId__c);
                        if(subModuleWrapperForSearchedSubModules!=null)
                        {
                            for(EB_Product__c subModule:subModuleWrapperForSearchedSubModules)
                            {
                                EB_ProductWrapper searchWrapper2 = new EB_ProductWrapper(subModule);
                                //check box maintenance
                                searchWrapper2.selected = true;
                                searchedProductsWrapper.add(searchWrapper2);
                            }   
                        }       
                    }
                }
            }
        }
        
        if(productsOfSearchedModules!=null)
        {
            for(EB_Product__c product:productsOfSearchedModules)
            {           
                /*if the parent product of the module is selected then check the selected checkbox. And remove it from
                the selected products set so that it does not appear twice in the selected products tab.*/
                
                if(searchedProducts.Contains(product))
                {
                    EB_ProductWrapper searchWrapper = new EB_ProductWrapper(product);
                    searchWrapper.selected = true;
                    searchedProductsWrapper.add(searchWrapper);                   
                    searchedProducts.remove(product);
                }
                /*only if the product was not a part of sub module products then add it to the wrapper.*/               
                else if(productsOfSearchedSubModules.contains(product) == false)
                {
                    EB_ProductWrapper searchWrapper = new EB_ProductWrapper(product);
                    searchedProductsWrapper.add(searchWrapper);
                }
                if(parentProductsForSearchedModules != null)
                    searchedModuleList = parentProductsForSearchedModules.get(product.EB_ProductId__c);
                if(searchedModuleList != null)
                {
                    for(EB_Product__c module:searchedModuleList)
                    {
                        EB_ProductWrapper searchWrapperModule = new EB_ProductWrapper(module);
                        //check box maintenance
                        searchWrapperModule.selected = true;
                        searchedProductsWrapper.add(searchWrapperModule);
                    }
                }
            }
        }
        
        if(searchedProducts!=null)
        {
            for(EB_Product__c searchedProduct:searchedProducts)
            {
                EB_ProductWrapper searchWrapper = new EB_ProductWrapper(searchedProduct);
                //check box maintenance
                searchWrapper.selected = true;
                searchedProductsWrapper.add(searchWrapper);
            }
        }
        //if(renderSearchedPanelTrue == false) 
        selPrdList.clear();
        selPrdList.addAll(searchedProductsWrapper);   
        SelectedPrdDetails = 'SelectedPrdDetails';  
        getCountPrdCatalogSelected = selectedPrdCatProductList.size();
        getCountLegacyPrdSelected = selectedLegacyProductList.size();
      
        return null;
        }
        
        catch(Exception e)
        {            
            ApexPages.Message myMsg;                
            myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,e.getMessage());              
            ApexPages.addMessage(myMsg);
            return null;
        }
    }
    
    
    public PageReference performProductSearch()
    {
        /*Start of set of variables required if the search string is a module*/
        Set<EB_Product__c> searchedModules = new Set<EB_Product__c>();
        Map<String,Set<EB_Product__c>> parentProductsForSearchedModules = new Map<String,Set<EB_Product__c>>();
        Set<EB_Product__c> tempModules = new Set<EB_Product__c>();
        /*End of set of variables required if the search string is a module*/
        
        /*Start of set of variables required if the search string is a Submodule*/
        Map<String,Set<EB_Product__c>> productModulesSearched = new Map<String,Set<EB_Product__c>>();
        Set<EB_Product__c> tempProductModule = new Set<EB_Product__c>();
        Set<EB_Product__c> searchedProductModule = new Set<EB_Product__c>();
        
        Map<String,Set<EB_Product__c>> modulesSearchedSubModules = new Map<String,Set<EB_Product__c>>();
        Set<EB_Product__c> tempModuleSubModule = new Set<EB_Product__c>();
        Set<EB_Product__c> searchedModuleSubModule = new Set<EB_Product__c>();
        
        Set<String> searchedSubModuleModule = new Set<String>();
        /*End of set of variables required if the search string is a Submodule*/
        
        /*Start of set of variables required if the search string is a product*/
        Set<EB_Product__c> searchedProducts = new Set<EB_Product__c>();
        /*End of set of variables required if the search string is a product*/
        
        searchedProductsWrapper = new List<EB_ProductWrapper>();
        List<EB_Product__c> productsOfSearchedModules = new List<EB_Product__c>();
        Set<String> productsIdsOfSearchedModules = new Set<String>();
        Set<String> productIdsOfSearchedSubmodules = new Set<String>();
        
       try
        {
        List<SI_ServiceIncidentImpactedProducts__c> tempAlreadyAddedProducts = new List<SI_ServiceIncidentImpactedProducts__c>();
        List<EB_Product__c> alreadyAddedProductsList = new List<EB_Product__c>();
        List<String> alreadyAddedProductIds = new List<String>();
        Set<EB_Product__c> alreadyAddedProductsSetTemp = new Set<EB_Product__c>();
        
      
        List<BMCServiceDesk__Incident__c> incidentRecord1 = [select Id from BMCServiceDesk__Incident__c where Name = :incidentName];
        tempAlreadyAddedProducts = [select SI_ProductName__r.Id,SI_ProductName__r.EB_ProductId__c,SI_ProductName__r.Product_Name__c,SI_ProductName__r.EB_ProductType__c,SI_ProductName__r.EB_ParentId__c,SI_ProductName__c from SI_ServiceIncidentImpactedProducts__c where SI_ServiceIncident__c = :incidentRecord1[0].Id];
        //alreadyAddedProducts.addAll(tempAlreadyAddedProducts);
        //System.assertEquals(tempAlreadyAddedProducts,null);
        for(SI_ServiceIncidentImpactedProducts__c siPrd:tempAlreadyAddedProducts)
        {
            alreadyAddedProductIds.add(siPrd.SI_ProductName__c);   
        }
        //System.assertEquals(alreadyAddedProductIds,null);
        alreadyAddedProductsList = [select Id,EB_ProductId__c,Product_Name__c,EB_ProductType__c,EB_ParentId__c from EB_Product__c where Id in :alreadyAddedProductIds];
        alreadyAddedProductsSetTemp.addAll(alreadyAddedProductsList);
        
        
        if(searchString!=null && searchString!='')
        {
            if(renderSearchedPanelTrue == false)
            {
                tempProductWrapper.clear();
                //Start of changes by ssawhney for CR 2528913
                for(list<EB_ProductWrapper> lstWrappers : wrappers)
                {
                    tempProductWrapper.addAll(lstWrappers);
                }
                //end of changes by ssawhney for CR 2528913
            }
            
            renderSearchedPanelTrue = true;
            renderSearchedPanelFalse = false;
             
            searchString = '%' + searchString + '%';
            //System.assertEquals(searchString,null);
            
            for(EB_Product__c product:[select Id,EB_ProductId__c,Product_Name__c,EB_ProductType__c,EB_ParentId__c from EB_Product__c where Product_Name__c like :searchString])
            {
                if(!alreadyAddedProductsSetTemp.contains(product))
                {
                    if(product.EB_ProductType__c == 'Module')
                    {
                        tempModules = new Set<EB_Product__c>();
                        searchedModules = new Set<EB_Product__c>();
                        
                        if (parentProductsForSearchedModules.containsKey(product.EB_ParentId__c) == true)
                        {  
                            tempModules=parentProductsForSearchedModules.remove(product.EB_ParentId__c);                                      
                        }
                        
                        searchedModules.addAll(tempModules);
                        searchedModules.add(product);
                        //Map of products of the selected modules and the modules.                  
                        parentProductsForSearchedModules.put(product.EB_ParentId__c, searchedModules);
                    } 
                    
                    if(product.EB_ProductType__c == 'Submodule')
                    {
                        tempModuleSubModule = new Set<EB_Product__c>();
                        searchedModuleSubModule = new Set<EB_Product__c>();
                        
                        if (modulesSearchedSubModules.containsKey(product.EB_ParentId__c) == true)
                        {  
                            tempModuleSubModule=modulesSearchedSubModules.remove(product.EB_ParentId__c);                                      
                        }
                        
                        searchedModuleSubModule.addAll(tempModuleSubModule);
                        searchedModuleSubModule.add(product);
                        //Map of Modules and sub modules for all searched submodules.
                        modulesSearchedSubModules.put(product.EB_ParentId__c, searchedModuleSubModule);                                            
                    }
                    
                    if(product.EB_ProductType__c == 'Product')
                    {
                        searchedProducts.add(product);
                    }
                }
            }
                
            if(parentProductsForSearchedModules!=null)
                productsIdsOfSearchedModules = parentProductsForSearchedModules.keySet();
            if(modulesSearchedSubModules!=null)
                searchedSubModuleModule = modulesSearchedSubModules.keySet();
            
            List<EB_Product__c> modulesofSearchedSubModules = [select Id,EB_ProductId__c,Product_Name__c,EB_ProductType__c,EB_ParentId__c from EB_Product__c where EB_ProductId__c in :searchedSubModuleModule];
            productsOfSearchedModules = [select Id,EB_ProductId__c,Product_Name__c,EB_ProductType__c,EB_ParentId__c from EB_Product__c where EB_ProductId__c in :productsIdsOfSearchedModules];
            if(modulesofSearchedSubModules!=null)
            {
                for(EB_Product__c module:modulesofSearchedSubModules)
                {
                    tempProductModule = new Set<EB_Product__c>();
                    searchedProductModule = new Set<EB_Product__c>();
                    
                    if (productModulesSearched.containsKey(module.EB_ParentId__c) == true)
                    {  
                        tempProductModule=productModulesSearched.remove(module.EB_ParentId__c);                                      
                    }
                    
                    searchedProductModule.addAll(tempProductModule);
                    searchedProductModule.add(module);
                                      
                    productModulesSearched.put(module.EB_ParentId__c, searchedProductModule);
                }
            }
            if(searchedProducts!=null)
            {
                for(EB_Product__c searchedProduct:searchedProducts)
                {
                    EB_ProductWrapper searchWrapper = new EB_ProductWrapper(searchedProduct);
                    searchedProductsWrapper.add(searchWrapper);
                }
            }
            Set<EB_Product__c> searchedModuleList = new Set<EB_Product__c>();
            
            if(productsOfSearchedModules!=null)
            {
                for(EB_Product__c product:productsOfSearchedModules)
                {
                    EB_ProductWrapper searchWrapper = new EB_ProductWrapper(product);
                    searchedProductsWrapper.add(searchWrapper);
                    searchedModuleList = parentProductsForSearchedModules.get(product.EB_ProductId__c);
                    for(EB_Product__c module:searchedModuleList)
                    {
                        EB_ProductWrapper searchWrapperModule = new EB_ProductWrapper(module);
                        searchedProductsWrapper.add(searchWrapperModule);
                    }
                }
            }
            if(productModulesSearched!=null)
                productIdsOfSearchedSubmodules = productModulesSearched.keySet();
            Set<EB_Product__c> moduleWrapperForSearchedSubModules = new Set<EB_Product__c>();
            Set<EB_Product__c> subModuleWrapperForSearchedSubModules = new Set<EB_Product__c>();
            List<EB_Product__c> productsOfSearchedSubModules = [select Id,EB_ProductId__c,Product_Name__c,EB_ProductType__c,EB_ParentId__c from EB_Product__c where EB_ProductId__c in :productIdsOfSearchedSubmodules];
            if(productsOfSearchedSubModules!=null)
            {
                for(EB_Product__c product:productsOfSearchedSubModules)
                {
                    EB_ProductWrapper searchWrapper = new EB_ProductWrapper(product);
                    searchedProductsWrapper.add(searchWrapper);
                    moduleWrapperForSearchedSubModules = productModulesSearched.get(product.EB_ProductId__c);
                    if(moduleWrapperForSearchedSubModules!=null)
                    {
                        for(EB_Product__c module:moduleWrapperForSearchedSubModules)
                        {
                            EB_ProductWrapper searchWrapper1 = new EB_ProductWrapper(module);
                            searchedProductsWrapper.add(searchWrapper1);
                            subModuleWrapperForSearchedSubModules = modulesSearchedSubModules.get(module.EB_ProductId__c);
                            if(subModuleWrapperForSearchedSubModules!=null)
                            {
                                for(EB_Product__c subModule:subModuleWrapperForSearchedSubModules)
                                {
                                    EB_ProductWrapper searchWrapper2 = new EB_ProductWrapper(subModule);
                                    searchedProductsWrapper.add(searchWrapper2);
                                }   
                            }       
                        }
                    }
                }
            }
            /*wrappers.clear();
            wrappers.addAll(searchedProductsWrapper);*/
            countOfSelectedProducts = searchedProductsWrapper.size();
        }
        return null;
       }
        catch(Exception e)
        {
            ApexPages.Message myMsg;                
            myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,e.getMessage());              
            ApexPages.addMessage(myMsg);
            return null;
        }
    }
    
    public PageReference clearProductCatalogSearch()
    {
        try
        {
        searchString = null;
        if(renderSearchedPanelTrue == true)
        {
            wrappers.clear();
            list<EB_ProductWrapper> lstwrapper = new list<EB_ProductWrapper>();
            //Start of changes by ssawhney for CR 2528913
            for(EB_ProductWrapper prodWrapper : tempProductWrapper)
            {
                if(lstwrapper.size() < 1000)
                {
                    lstwrapper.add(prodWrapper);
                }
                else
                {
                    wrappers.add(lstwrapper);
                    lstwrapper = new list<EB_ProductWrapper>();
                    lstwrapper.add(prodWrapper);
                } 
            }   
            
            if(lstwrapper.size()>0)
                wrappers.add(lstwrapper);
            //end of changes by ssawhney for CR 2528913
            renderSearchedPanelTrue = false;
            renderSearchedPanelFalse = true;
        }
        return null;
        }
        catch(Exception e)
        {
            ApexPages.Message myMsg;                
            myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,e.getMessage());              
            ApexPages.addMessage(myMsg);
            return null;
        }
    }
    
    public PageReference gotoIncidentPage()
    {
        BMCServiceDesk__Incident__c incidentRecord = [select Id from BMCServiceDesk__Incident__c where Name = :incidentName];
        PageReference pg = new PageReference('/'+incidentRecord.Id);
        return pg;
    }
    
    public PageReference saveSelectedProducts1()
    {
        Map<String,String> productIdParentProductId = new Map<String,String>();
        Map<String,String> productIdProductName = new Map<String,String>();
        Map<String,String> moduleIdModuleName = new Map<String,String>();
        Map<String,String> productIdParentModuleId = new Map<String,String>();
        Map<String,String> moduleIdSubModuleProductId = new Map<String,String>();
        Map<String,String> subModuleProductIdProductName = new Map<String,String>();
        Set<String> productIds = new Set<String>();
        Set<String> moduleIds = new Set<String>();
        Set<String> productIdsOfSubModules = new Set<String>();
        String subModuleProductId = '';
        String subModuleProductName = '';
        String subModuleProdId = '';
        List<SI_ServiceIncidentImpactedProducts__c> tempAlreadyAddedProducts = new List<SI_ServiceIncidentImpactedProducts__c>();
        List<EB_Product__c> alreadyAddedProductsList = new List<EB_Product__c>();
        List<String> alreadyAddedProductIds = new List<String>();
        Set<EB_Product__c> alreadyAddedProductsSetTemp = new Set<EB_Product__c>();
        try
        {
        getSelectedProducts();
        impactedProductSet = new Set<EB_Product__c>();
        List<BMCServiceDesk__Incident__c> incidentRecord1 = [select Id from BMCServiceDesk__Incident__c where Name = :incidentName];
        tempAlreadyAddedProducts = [select SI_ProductName__r.Id,SI_ProductName__r.EB_ProductId__c,SI_ProductName__r.Product_Name__c,SI_ProductName__r.EB_ProductType__c,SI_ProductName__r.EB_ParentId__c,SI_ProductName__c from SI_ServiceIncidentImpactedProducts__c where SI_ServiceIncident__c = :incidentRecord1[0].Id];
        //alreadyAddedProducts.addAll(tempAlreadyAddedProducts);
        //System.assertEquals(tempAlreadyAddedProducts,null);
        for(SI_ServiceIncidentImpactedProducts__c siPrd:tempAlreadyAddedProducts)
        {
            alreadyAddedProductIds.add(siPrd.SI_ProductName__c);   
        }
        //System.assertEquals(alreadyAddedProductIds,null);
        alreadyAddedProductsList = [select Id,EB_ProductId__c,Product_Name__c,EB_ProductType__c,EB_ParentId__c from EB_Product__c where Id in :alreadyAddedProductIds];
        alreadyAddedProductsSetTemp.addAll(alreadyAddedProductsList);
        
        for(EB_Product__c prd:selectedProductList)
        {
            if(!alreadyAddedProductsSetTemp.contains(prd))
            {
                impactedProductSet.add(prd);
            }
        }
        
        for(EB_Product__c product:impactedProductSet)
        {
            subModuleProdId = '';
            if(product.EB_ProductType__c == 'Module')
            {
                productIdParentProductId.put(product.EB_ProductId__c,product.EB_ParentId__c);
                productIds.add(product.EB_ParentId__c);
            }
            else if(product.EB_ProductType__c == 'Submodule')
            {
                productIdParentModuleId.put(product.EB_ProductId__c,product.EB_ParentId__c);
                //subModuleProdId = productIdParentProductId.get(product.EB_ParentId__c);
                //moduleIdSubModuleProductId.put(product.EB_ParentId__c,subModuleProdId);
                moduleIds.add(product.EB_ParentId__c);
            }
        }
        for(EB_Product__c productId:[select EB_ProductId__c,Product_Name__c from EB_Product__c where EB_ProductId__c in :productIds])
        {
            productIdProductName.put(productId.EB_ProductId__c,productId.Product_Name__c);
        }
        for(EB_Product__c moduleId:[select EB_ProductId__c,Product_Name__c, EB_ParentId__c from EB_Product__c where EB_ProductId__c in :moduleIds])
        {
            moduleIdModuleName.put(moduleId.EB_ProductId__c,moduleId.Product_Name__c);
            moduleIdSubModuleProductId.put(moduleId.EB_ProductId__c,moduleId.EB_ParentId__c);
            productIdsOfSubModules.add(moduleId.EB_ParentId__c);
        }
        for(EB_Product__c product:[select EB_ProductId__c,Product_Name__c,Id from EB_Product__c where EB_ProductId__c in :productIdsOfSubModules])
        {
            subModuleProductIdProductName.put(product.EB_ProductId__c,product.Product_Name__c);
        }
        
        BMCServiceDesk__Incident__c incidentRecord = [select Id from BMCServiceDesk__Incident__c where Name = :incidentName];
        //System.assertEquals(
        for(EB_Product__c impactedPrd:impactedProductSet)
        {
            subModuleProductId = '';
            subModuleProductName = '';
            SI_ServiceIncidentImpactedProducts__c impactedProduct = new SI_ServiceIncidentImpactedProducts__c();
            impactedProduct.SI_ProductName__c = impactedPrd.Id;
            impactedProduct.SI_ServiceIncident__c = incidentRecord.Id;
            if(impactedPrd.EB_ProductType__c == 'Module')
            {
                impactedProduct.SI_ParentProductName__c = productIdProductName.get(impactedPrd.EB_ParentId__c);
                impactedProduct.SI_ParentModuleName__c = impactedPrd.Product_Name__c;              
            }
            else if(impactedPrd.EB_ProductType__c == 'Submodule')
            {
                impactedProduct.SI_ParentModuleName__c = moduleIdModuleName.get(impactedPrd.EB_ParentId__c);
                subModuleProductId = moduleIdSubModuleProductId.get(impactedPrd.EB_ParentId__c);
                subModuleProductName = subModuleProductIdProductName.get(subModuleProductId);
                impactedProduct.SI_ParentProductName__c = subModuleProductName;
                impactedProduct.SI_SubModule__c = impactedPrd.Product_Name__c;                
            }
            else
            {
                impactedProduct.SI_ParentProductName__c = impactedPrd.Product_Name__c;                
            }
            impactedProductListToInsert.add(impactedProduct);
        }
        if(impactedProductListToInsert.size()>0)
            insert impactedProductListToInsert;
        PageReference pg = new PageReference('/'+incidentRecord.Id);
        return pg;
        }
        Catch(Exception e)
        {
            ApexPages.Message myMsg;                
            myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,e.getMessage());              
            ApexPages.addMessage(myMsg);
            return null;
        }
    }
    //End of changes by janantha for CR 1799680
    
    public class EB_ProductWrapper 
    {
        public EB_Product__c product{get;set;}  
        public Boolean selected{get;set;}   
        public Boolean isModule{get;set;}
        public Boolean isSubModule{get;set;}
        //Start of changes by janantha for CR 1799680
        public Boolean wordWrap{get;set;}
        public Boolean noWordWrap{get;set;}
        public String temp{get;set;}
        //End of changes by janantha for CR 1799680
        public EB_ProductWrapper()
        {
            
        }
        
        public EB_ProductWrapper(EB_Product__c prd)
        {
            product = new EB_Product__c();
            if(prd.EB_ProductType__c == 'Module')
                isModule = true;
            else if(prd.EB_ProductType__c == 'Submodule')
                isSubModule = true;
            //Start of changes by janantha for CR 1799680
            if(prd.Product_Name__c.length()>25)
            {
                wordWrap = true;
                noWordWrap = false;
                temp = prd.Product_Name__c.substring(0,24);
                temp = temp+'...';
                //prd.Product_Name__c = temp;
            }   
            else
            {
                wordWrap = false;
                noWordWrap = true;
            }
            //End of changes by janantha for CR 1799680
            product = prd;
            selected = false;
        }     
    }
}