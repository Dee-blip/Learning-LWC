/*
Date                    Developer                       Changes
_____________________________________________________________________________

10 April 2017       Vandhana Krishnamurthy        Setting category type for category based on new validation on Category - Category type is mandatory 
31 Oct 2018         Pinkesh Rathore               Added Executive Summary for new validation rule on incident.

_____________________________________________________________________________
*/

@IsTest
private class EB_ProductCatalogComponent_Test
{
    static EB_Product__c product1;
    static EB_Product__c module1;
    static EB_Product__c subModule1;
    static EB_Product__c legacyProduct;
    static List<EB_ProductCatalogComponent.EB_ProductWrapper> productWrapperList;
    static List<SI_ServiceIncidentImpactedProducts__c> impactedProductList;
    static SI_ServiceIncidentImpactedProducts__c impProduct1;
    static SI_ServiceIncidentImpactedProducts__c impModule1;
    static SI_ServiceIncidentImpactedProducts__c impSubModule1;
    static BMCServiceDesk__Incident__c incident = new BMCServiceDesk__Incident__c();
    
    static testMethod void init()
    {
        ManagedPkgErrorClass.isFromManagedPackage=false;
        productWrapperList = new List<EB_ProductCatalogComponent.EB_ProductWrapper>();
        
        list<EB_Product__c> lstProducts = new list<EB_Product__c>();
        product1 = new EB_Product__c();
        product1.EB_ProductId__c = 'test1Id';
        product1.EB_ProductType__c = 'Product';
        product1.EB_ParentId__c = '';
        product1.product_name__c = 'Edge Media Buying';
        product1.EB_Source__c = 'Product Catalog';
        lstProducts.add(product1);
        
        module1 = new EB_Product__c();
        module1.EB_ProductId__c = 'test2Id';
        module1.EB_ProductType__c = 'Module';
        module1.EB_ParentId__c = product1.EB_ProductId__c;
        module1.product_name__c = 'Secure Delivery';
        module1.EB_Source__c = 'Product Catalog';
        lstProducts.add(module1);
        
        subModule1 = new EB_Product__c();
        subModule1.EB_ProductId__c = 'test3Id';
        subModule1.EB_ProductType__c = 'Submodule';
        subModule1.EB_ParentId__c = module1.EB_ProductId__c;
        subModule1.product_name__c = 'SSL Certificates';
        subModule1.EB_Source__c = 'Product Catalog';
        lstProducts.add(subModule1);  
        
        legacyProduct = new EB_Product__c();       
        legacyProduct.product_name__c = 'Legacy Product';
        legacyProduct.EB_ProductType__c = 'Case Product';
        lstProducts.add(legacyProduct);
        
        insert lstProducts; 
        
        /*List <BMCServiceDesk__Category__c> listofCategories = [select Id,Name from BMCServiceDesk__Category__c where name = 'Contact Us'];
        if(listofCategories!=null && listofCategories.Size()!=0)
        {
        incident.BMCServiceDesk__FKCategory__c = listofCategories[0].Id;
        }     */
        
        // changes by Vandhana for 3695602
        // Setting category type for category based on new validation on Category - Category type is mandatory 
        BMCServiceDesk__CategoryTypes__c ctype = new BMCServiceDesk__CategoryTypes__c(Name = 'categoryTypeTest' );       
        insert ctype;

        BMCServiceDesk__Category__c cat = new BMCServiceDesk__Category__c();
        cat.Name='TempCategory';
        cat.SI_Applies_to_Service_Incident__c = true;
        cat.BMCServiceDesk__AvailableForServiceCatalog__c = true;
        cat.BMCServiceDesk__FKCategoryType__c = ctype.Id;
        insert (cat);
        // end of changes by Vandhana        
        
        //String RecordId = [SELECT id FROM RecordType where Name ='Service Incident'][0].id;
        String RecordId = Schema.SObjectType.BMCServiceDesk__Incident__c.getRecordTypeInfosByName().get('Service Incident').getRecordTypeId();
              
       BMCServiceDesk__Impact__c  ima = new BMCServiceDesk__Impact__c();
       ima.Name='tempImpact';
       ima.SI_Applies_to_Service_Incident__c = true;
       insert ima;
       
       BMCServiceDesk__Urgency__c  urg = new BMCServiceDesk__Urgency__c();
       urg.Name='tempUrgency1';
       urg.SI_Applies_to_Service_Incident__c = true;
       insert urg;
        
       incident.BMCServiceDesk__FKCategory__c = cat.Id;
       incident.RecordTypeID = RecordId;
       incident.BMCServiceDesk__FKUrgency__c = urg.id;
       incident.BMCServiceDesk__FKImpact__c = ima.Id;
       incident.how_was_the_issue_detected__c = 'others';
       incident.SI_Executive_Summary__c = 'Test Test Test Test Test Test Test';
       insert(incident);
       
       list<SI_ServiceIncidentImpactedProducts__c> lstImpactedProducts = new list<SI_ServiceIncidentImpactedProducts__c>();
       impProduct1 = new SI_ServiceIncidentImpactedProducts__c();
       impProduct1.SI_ProductName__c = product1.Id;
       impProduct1.SI_ServiceIncident__c = incident.Id;
       lstImpactedProducts.add(impProduct1);
        
        impModule1 = new SI_ServiceIncidentImpactedProducts__c();
        impModule1.SI_ProductName__c = module1.Id;
        impModule1.SI_ServiceIncident__c = incident.Id;
        lstImpactedProducts.add(impModule1);
        
        impSubModule1 = new SI_ServiceIncidentImpactedProducts__c();
        impSubModule1.SI_ProductName__c = subModule1.Id;
        impSubModule1.SI_ServiceIncident__c = incident.Id;
        lstImpactedProducts.add(impSubModule1);
        
        insert lstImpactedProducts;
                  
    }
    
    static testMethod void positiveTest()
    {
        init();
        String incidentName = [select Id,Name from BMCServiceDesk__Incident__c where Id = :incident.Id].Name;        
        ApexPages.currentPage().getParameters().put('incidentName',incidentName);
        EB_ProductCatalogComponent.EB_ProductWrapper wrapper = new EB_ProductCatalogComponent.EB_ProductWrapper(product1);
        wrapper.selected = true;
        productWrapperList.add(wrapper);
        
        EB_ProductCatalogComponent.EB_ProductWrapper wrapper1 = new EB_ProductCatalogComponent.EB_ProductWrapper(module1);
        wrapper1.selected = true;
        wrapper1.isModule = true;
        productWrapperList.add(wrapper1);
        
        EB_ProductCatalogComponent.EB_ProductWrapper wrapper2 = new EB_ProductCatalogComponent.EB_ProductWrapper(subModule1);
        wrapper2.selected = true;
        wrapper2.isSubModule = true;
        productWrapperList.add(wrapper2);
        
        Test.startTest();
        EB_ProductCatalogComponent prdCat = new EB_ProductCatalogComponent();
        prdCat.getModuleForProduct();
        prdCat.wrappers.add(productWrapperList);
        prdCat.getSelectedCount();
        prdCat.searchString = 'SSL';
        prdCat.performProductSearch();
        prdCat.saveSelectedProducts1();
        Test.stopTest();
    }         

    static{
        utilTestClass.createCustomSettings();
        list<HD_DEFAULT_CATEGORY__c> listHD = new list<HD_DEFAULT_CATEGORY__c>();
        HD_DEFAULT_CATEGORY__c hd1 = new HD_DEFAULT_CATEGORY__c();
        hd1.Name = 'Additional Desktop/Laptop';
        hd1.Category_Name__c = 'Additional Desktop/Laptop';
        listHD.add(hd1);
        
        HD_DEFAULT_CATEGORY__c hd2 = new HD_DEFAULT_CATEGORY__c();
        hd2.Name = 'Child1-New Hire Onboarding';
        hd2.Category_Name__c = 'New Hire Onboarding';
        listHD.add(hd2);

        HD_DEFAULT_CATEGORY__c hd3 = new HD_DEFAULT_CATEGORY__c();
        hd3.Name = 'Child2-Telecom_New Hire';
        hd3.Category_Name__c = 'New Hire Extension';
        listHD.add(hd3);

        HD_DEFAULT_CATEGORY__c hd4 = new HD_DEFAULT_CATEGORY__c();
        hd4.Name = 'Child3-Cor_service';
        hd4.Category_Name__c = 'Corporate Services';
        listHD.add(hd4);

        HD_DEFAULT_CATEGORY__c hd5 = new HD_DEFAULT_CATEGORY__c();
        hd5.Name = 'Corporate Services';
        hd5.Category_Name__c = 'Corporate Services';
        listHD.add(hd5);

        HD_DEFAULT_CATEGORY__c hd6 = new HD_DEFAULT_CATEGORY__c();
        hd6.Name = 'Telecom';
        hd6.Category_Name__c = 'Telecom';
        listHD.add(hd6);

        HD_DEFAULT_CATEGORY__c hd7 = new HD_DEFAULT_CATEGORY__c();
        hd7.Name = 'Hardware';
        hd7.Category_Name__c = 'Hardware';
        listHD.add(hd7);
        
        HD_DEFAULT_CATEGORY__c hd8 = new HD_DEFAULT_CATEGORY__c();
        hd8.Name = 'New Hire Onboarding';
        hd8.Category_Name__c = 'New Hire Onboarding';
        listHD.add(hd8);
        
        HD_DEFAULT_CATEGORY__c hd9 = new HD_DEFAULT_CATEGORY__c();
        hd9.Name = 'Parent-New Hire Onboarding';
        hd9.Category_Name__c = 'New Hire Onboarding';
        listHD.add(hd9);
        //insert listHD;
        
        HD_DEFAULT_CATEGORY__c dc10 = new HD_DEFAULT_CATEGORY__c(Name='Desktop/Laptop',Category_Name__c='Desktop/Laptop');
        HD_DEFAULT_CATEGORY__c dc11 = new HD_DEFAULT_CATEGORY__c(Name='Hardware -> Linux',Category_Name__c='Hardware -> Linux');
        listHD.add(dc10);
        listHD.add(dc11);
        insert listHD;
        
        Account acc = utilTestClass.CreateAccount('test acc1');
        insert acc;
        
        HD_Default_Custom_Setting__c defaultHD = new HD_Default_Custom_Setting__c();
        defaultHD.Name = 'DEFAULT VALUES';
        defaultHD.Default_Account__c = 'test acc1';
        defaultHD.Default_Impact__c = 'tempImpact';
        insert defaultHD;
        
        SI_ProductSearch__c search = new SI_ProductSearch__c();
        search.Value__c = 'Product Catalog';
        insert search;
        
        SI_IncidentRecordType__c SIRecordType = new SI_IncidentRecordType__c();
        SIRecordType.Service_Incident__c =  Schema.SObjectType.BMCServiceDesk__Incident__c.getRecordTypeInfosByName().get('Service Incident').getRecordTypeId();
        insert SIRecordType;     
        
        SI_Status__c sistatus = new SI_Status__c();
        sistatus.Name = 'SIStatus' ;
        sistatus.Status__c = 'IMPACT MITIGATED,CLOSED,RESOLVED';
        insert sistatus;
        
        EmailHandler_CS__c csEmailHandler = new EmailHandler_CS__c(Name = 'ccare', Email_Address__c='ccare@akamai.com',Record_Type__c = 'Technical');
        insert csEmailHandler;
         //populating custom setting used for new old trigger
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        System.debug('decribe ---'+gd.containsKey('HD_RF_TRIGGER_FLAG__c'));
        if(gd.containsKey('HD_RF_TRIGGER_FLAG__c'))
        {
         List<HD_RF_TRIGGER_FLAG__c>  rfList =  new List<HD_RF_TRIGGER_FLAG__c>();
         HD_RF_TRIGGER_FLAG__c  HD_RemedyForceCustomizations = new HD_RF_TRIGGER_FLAG__c(Name='HD_RemedyForceCustomizations',Enable__c=true,Information__c='This is Old trigger');
         rfList.add(HD_RemedyForceCustomizations);
         HD_RF_TRIGGER_FLAG__c  HD_RemedyForceCustomization_Tri = new HD_RF_TRIGGER_FLAG__c(Name='HD_RemedyForceCustomization_Tri',Enable__c=false,Information__c='This is new trigger');
         rfList.add(HD_RemedyForceCustomization_Tri);
         //Inserting 
         insert rfList; 
    
       }//
      //adding dataload custom setting added by Bhaskar verma 
       HD_DataLoad__c dl = new HD_DataLoad__c();
       dl.name = 'Triage_Team';
       dl.TextValue__c = '00GG0000002ewrWMAQ';
       insert dl;
    }
}