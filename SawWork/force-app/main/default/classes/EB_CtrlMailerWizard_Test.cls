/*
Author: Sharath K
History: 09/19/2010 - CR -794793: revamped the test class according to Code review findings. Using common Init methods, covering all test cases according to flow
Description: Contains all positive and negative test cases for EB_CtrlMailerWizard
Test Cases: 
Create single mails, Service Incident Notification, account only search
Create single mails, General Incident Notification, account only search
Create Mass mails, Service Incident Notification, account only search
Create Mass mails, General Incident Notification, account only search

Create single mails, Service Incident Notification, account product search
Create single mails, General Incident Notification, account product search
Create Mass mails, Service Incident Notification, account product search
Create Mass mails, General Incident Notification, account product search

Create single mails, Service Incident Notification, product only search
Create single mails, General Incident Notification, product only search
Create Mass mails, Service Incident Notification, product only search
Create Mass mails, General Incident Notification, product only search

Navigate to AccountId/CPCode page from 1st page (Cover all scenarios i.e single/mass mail & serice/general incident notification)

Carry out few negative test cases like - Empty search criteria, invalid search criteria

3/29/2011 - old test class was refering to createMailer() instead of createMailerDirectly() for mass mails, made necessary changes
          - added few methods to improve test coverage after changes for CR 1029711 - CNotify: Standardize Action Poller Content, Create Mailer and CR 845804 CNotify: User should be able to pick the default Email Template during Mailer creation

Modified on: 06/25/2012 by janantha for CR 1733044: Enhancing the existing Account Product Search to Incorporate New Prod Catg Search      
*/

@isTest
private class EB_CtrlMailerWizard_Test {
    //Start of changes by janantha for CR 1733044
    public static EB_Product__c product;
    static EmailTemplate et;
    static EB_EmailTemplate__c testTemplate;
    //End of changes by janantha for CR 1733044
/**
    Create Account search criteria which can be reused in various test cases
*/
    private static void CreateAccountSearchCriteria(EB_CtrlMailerWizard controller){
        //set the first row for account search
        controller.SearchFR1C1='Support_Level__c';
        controller.SearchOR1C1='=';   
        controller.SearchVR1C1='Premium';
        controller.SearchVR1C2='Priority';
        controller.SearchVR1C3='';
        controller.SearchLR1C3='OR';

        //set the second row for Account search
        controller.SearchFR2C1='Customer_Tier__c';
        controller.SearchOR2C1='=';   
        controller.SearchVR2C1='A'; 
        controller.SearchVR2C2='A+';
        controller.SearchVR2C3='';
        controller.SearchLR2C3='OR';

        //set the third row for Account search
        controller.SearchFR3C1='Name';
        controller.SearchOR3C1='=';   
        controller.SearchVR3C1='General Motors Corporation'; 
        controller.SearchVR3C2='Grand Hotels & Resorts Ltd';
        controller.SearchVR3C3='Viacom Inc';
        controller.SearchLR3C3='';

        //set the 4th row for Account search
        controller.SearchFR4C1='';
        controller.SearchOR4C1='';   
        controller.SearchVR4C1=''; 
        controller.SearchVR4C2='';
        controller.SearchVR4C3='';
        controller.SearchLR4C3='';
            
        controller.SearchFR5C1='';
        controller.SearchOR5C1='';   
        controller.SearchVR5C1=''; 
        controller.SearchVR5C2='';
        controller.SearchVR5C3='';
        controller.SearchLR5C3='';
    }
  
  /**
    Create an empty Account search criteria which can be reused in various test cases
*/  
    private static void CreateEmptyAccountSearchCriteria(EB_CtrlMailerWizard controller){
        //set the first row for account search
        controller.SearchFR1C1='';
        controller.SearchOR1C1='';   
        controller.SearchVR1C1='';
        controller.SearchVR1C2='';
        controller.SearchVR1C3='';
        controller.SearchLR1C3='';

        //set the second row for Account search
        controller.SearchFR2C1='';
        controller.SearchOR2C1='';   
        controller.SearchVR2C1=''; 
        controller.SearchVR2C2='';
        controller.SearchVR2C3='';
        controller.SearchLR2C3='';

        //set the third row for Account search
        controller.SearchFR3C1='';
        controller.SearchOR3C1='';   
        controller.SearchVR3C1=''; 
        controller.SearchVR3C2='';
        controller.SearchVR3C3='';
        controller.SearchLR3C3='';

        //set the 4th row for Account search
        controller.SearchFR4C1='';
        controller.SearchOR4C1='';   
        controller.SearchVR4C1=''; 
        controller.SearchVR4C2='';
        controller.SearchVR4C3='';
        controller.SearchLR4C3='';
            
        controller.SearchFR5C1='';
        controller.SearchOR5C1='';   
        controller.SearchVR5C1=''; 
        controller.SearchVR5C2='';
        controller.SearchVR5C3='';
        controller.SearchLR5C3='';
    }

/**
    Create a valid product search criteria which can be reused in various test cases
*/
    private static void CreateProductSearchCriteria(EB_CtrlMailerWizard controller){
        controller.PSearchFR1C1='EB_Product__c';
        controller.PSearchOR1C1='=';   
        controller.PSearchVR1C1='EdgeControl'; 
        controller.PSearchVR1C2='Other';
        controller.PSearchVR1C3='EdgeComputing';
        controller.PSearchLR1C3='';

        controller.PSearchFR2C1='';
        controller.PSearchOR2C1='';   
        controller.PSearchVR2C1=''; 
        controller.PSearchVR2C2='';
        controller.PSearchVR2C3='';
        controller.PSearchLR2C3='';

        controller.PSearchFR3C1='';
        controller.PSearchOR3C1='';   
        controller.PSearchVR3C1=''; 
        controller.PSearchVR3C2='';
        controller.PSearchVR3C3='';
        controller.PSearchLR3C3='';
    }

/**
    Create an empty product search criteria which can be reused in various test cases
*/
    private static void CreateEmptyProductSearchCriteria(EB_CtrlMailerWizard controller){
        controller.PSearchFR1C1='';
        controller.PSearchOR1C1='';   
        controller.PSearchVR1C1=''; 
        controller.PSearchVR1C2='';
        controller.PSearchVR1C3='';
        controller.PSearchLR1C3='';

        controller.PSearchFR2C1='';
        controller.PSearchOR2C1='';   
        controller.PSearchVR2C1=''; 
        controller.PSearchVR2C2='';
        controller.PSearchVR2C3='';
        controller.PSearchLR2C3='';

        controller.PSearchFR3C1='';
        controller.PSearchOR3C1='';   
        controller.PSearchVR3C1=''; 
        controller.PSearchVR3C2='';
        controller.PSearchVR3C3='';
        controller.PSearchLR3C3='';
    }
    
     private static void Init(){
    ManagedPkgErrorClass.isFromManagedPackage=false;
        
        PageReference pg = new PageReference('/apex/EB_VfpMailerWizard1');
        Test.setCurrentPage(pg);
        
        
        list<EB_Product__c> lstproducts = new list<EB_Product__c>();
        //Start of changes by janantha for CR 1733044
        product= new EB_Product__c();
        product.Product_Name__c = 'Test Product';
        product.EB_ProductId__c = 'Test1';
        lstproducts.add(product);
        
        EB_Product__c product1= new EB_Product__c();
        product1.Product_Name__c = 'Test Product2';
        product1.EB_ProductId__c = 'Test2';
        product1.EB_ProductType__c = 'Module';
        product1.EB_ParentId__c = 'Test1';
        lstproducts.add(product1);
        
        EB_Product__c product2= new EB_Product__c();
        product2.Product_Name__c = 'Test Product3';
        product2.EB_ProductId__c = 'Test3';
        product2.EB_ProductType__c = 'Submodule';
        product1.EB_ParentId__c = 'Test2';
        lstproducts.add(product2);
        
        EB_Product__c product3= new EB_Product__c();
        product3.Product_Name__c = 'Test Product4';
        product3.EB_ProductId__c = 'Test4';
        product3.EB_ProductType__c = 'Product';
        lstproducts.add(product3);
        
        EB_Product__c product4= new EB_Product__c();
        product4.Product_Name__c = 'Test Product5';
        product4.EB_ProductId__c = 'Test5';
        product4.EB_ProductType__c = 'Case Product';
        lstproducts.add(product4);
        insert lstproducts;
       
        if(et == null)
        {
            et = [Select Id from EmailTemplate where Templatetype = 'text' and Folder.Name = 'Customer Notify Mass Email' and isActive = true limit 1];
        }

        if(testTemplate == null)
        {
            list<EB_EmailTemplate__c> lstTemplate =[Select id,Name from EB_EmailTemplate__c limit 1];
            if(lstTemplate.size() > 0)
            {
                testTemplate = lstTemplate[0];
            }
            else
            {
                testTemplate= EB_InitializeObjects.createCustomTemplate('template 1','text', et.Id);
                database.insert(testTemplate);
            }
        }
        //End of changes by janantha for CR 1733044
    }
    
  /**
    Test case to implement Account-Product Search ServiceNotification - both for single mails & mass mails
*/  
    static testMethod void AccountProductSearchServiceNotification() {
        // instantiate the controller
        //start of changes by janantha for CR 1733044
        
        EBCS_Application__c objApp = EBCS_Application__c.getInstance('ProductSearch');
        objApp.Value__c = 'Legacy Product';
        update objApp;
        //end of changes by janantha for CR 1733044
        
        Init();
        EB_CtrlMailerWizard controller = new EB_CtrlMailerWizard();

        //Id TempID=[Select id,Name from EB_EmailTemplate__c][0].ID;
        Id TempID=testTemplate.Id;
         controller.newtoken.EB_TokenEmailTemplate__c=TempID;
        controller.getNewtoken();
         //Start of changes by janantha for CR 1733044       
        EB_CtrlMailerWizard.EB_ProductWrapper prdWrapper = new EB_CtrlMailerWizard.EB_ProductWrapper(product);
        //EB_ProductWrapper prdWrapperSet = new EB_ProductWrapper(productSet);
        EB_CtrlMailerWizard.EB_ProductWrapper prdWrapperNoParam = new EB_CtrlMailerWizard.EB_ProductWrapper();
             
        // from EB_VfpCtrlMailerWizard1(1st page of wizard) go to EB_VfpCtrlMailerWizard2 - criteria is single mail & Service notification
        controller.radioChoice='DefaultSearch';
        controller.setchoice('selectedContacts');
        controller.mailchoice='singleMail';
        controller.goToSearchPage();
        controller.goToPreviewPage();
        controller.getRenderHelpText();
        
        // populate the search criteria fields
        CreateAccountSearchCriteria(controller);
        CreateProductSearchCriteria(controller);
        // go to EB_VfpCtrlMailerWizard3 - invoking page2() invokes build,validate, formsqls directly
        PageReference pg2=controller.page2();
        // get the accounts explicitly and set the checkboxes to true, so that we can add accounts
        controller.accountList =controller.getAccounts();
        for(EB_AccountWrapper accwrapper : controller.accountList)
            accwrapper.selected= true;
        Test.startTest();
        //get the selected accounts & add them to EB_SelectedAccounts__c - invokes getSelected() too
        controller.getAdded();
        // create a mailer for the selected accounts
        PageReference mailerpg=controller.createMailer();
        
        //start of changes by janantha for CR 1733044
        EBCS_Application__c objApp1 = EBCS_Application__c.getInstance('ProductSearch');
        objApp1.Value__c = 'Product Catalog';
        update objApp1;
        
        Init();
        EB_CtrlMailerWizard controller1 = new EB_CtrlMailerWizard();
        
        TempID=[Select id,Name from EB_EmailTemplate__c][0].ID;
         controller1.newtoken.EB_TokenEmailTemplate__c=TempID;
        // from EB_VfpCtrlMailerWizard1(1st page of wizard) go to EB_VfpCtrlMailerWizard2 - criteria is single mail & Service notification
        controller1.radioChoice='DefaultSearch';
        controller1.setchoice('selectedContacts');
        controller1.mailchoice='singleMail';
        controller1.goToSearchPage();
        Pagereference pg7=controller1.goToPreviewPage();
        // populate the search criteria fields
        CreateAccountSearchCriteria(controller1);
        CreateProductSearchCriteria(controller1);
        // go to EB_VfpCtrlMailerWizard3 - invoking page2() invokes build,validate, formsqls directly
        PageReference pg3=controller1.page2();
        //go to Eb_Search Criteria invoking showcriteria().
        controller1.showcriteria(); 
        // get the accounts explicitly and set the checkboxes to true, so that we can add accounts
        controller1.accountList =controller.getAccounts();
        for(EB_AccountWrapper accwrapper : controller.accountList)
            accwrapper.selected= true;
        //Test.startTest();
        //get the selected accounts & add them to EB_SelectedAccounts__c - invokes getSelected() too
        controller1.getAdded();
        // create a mailer for the selected accounts
        PageReference mailerpg1=controller1.createMailer();
        //end of changes by janantha for CR 1733044
        //To invoke the getreaderxml method. CR : 1816825, mshardul
        controller1.XML = '<?xml version="1.0"?><SearchCriteria><row><Field>Region</Field><Operator>Not Equals</Operator><Value>India</Value><LogicalOperator></LogicalOperator></row></SearchCriteria>';
        controller1.getreadXML();
         
        Test.stopTest();
    }
    
    /**
    Test case to implement Account-Product Search General Notification - both for single mails & mass mails
*/ 
    static testMethod void AccountProductSearchGeneralNotification() {
        // instantiate the controller
        //start of changes by janantha for CR 1733044
        EBCS_Application__c objApp1 = EBCS_Application__c.getInstance('ProductSearch');
        objApp1.Value__c = 'Product Catalog';
        update objApp1;
        //end of changes by janantha for CR 1733044
        
        Init();
        EB_CtrlMailerWizard controller = new EB_CtrlMailerWizard();
        
         
        // from EB_VfpCtrlMailerWizard1(1st page of wizard) go to EB_VfpCtrlMailerWizard2 - criteria is single mail & General notification
        controller.getRenderHelpText();
        controller.radioChoice='DefaultSearch';
        controller.setchoice('allContacts');
        controller.mailchoice='singleMail';
        controller.goToSearchPage();
        controller.getRenderHelpText();
        // populate the search criteria fields
        CreateAccountSearchCriteria(controller);
        CreateProductSearchCriteria(controller);
        // go to EB_VfpCtrlMailerWizard3 - invoking page2() invokes build,validate, formsqls directly
        PageReference pg2=controller.page2();
        // get the accounts explicitly and set the checkboxes to true, so that we can add accounts
        controller.accountList =controller.getAccounts();
        for(EB_AccountWrapper accwrapper : controller.accountList){
            if(accwrapper.acc.Id != acc2.Id)
            accwrapper.selected= true;
            }
        Test.startTest();
        //get the selected accounts & add them to EB_SelectedAccounts__c - invokes getSelected() too
        controller.getAdded();
        // create a mailer for the selected accounts
        PageReference mailerpg=controller.createMailer();
        /*  CR 845804 CNotify: User should be able to pick the default Email Template during Mailer creation 
        CR 1029711 - CNotify: Standardize Action Poller Content, Create Mailer
        2.1 release changes */
        pageReference p4 = controller.getMailerStatus();
        String googleImage = controller.getMailerDetails();
        String mailerLink = controller.getCurrentMailerLink();
        Boolean rendermailerLink = controller.getRenderMailerLink();
        
        // from EB_VfpCtrlMailerWizard1(1st page of wizard) go to EB_VfpCtrlMailerWizard2 - criteria is MASS mail & General notification
        controller.radioChoice='DefaultSearch';
        controller.setchoice('allContacts');
        controller.mailchoice='massMail';
        controller.goToSearchPage();
        // populate the search criteria fields
        CreateAccountSearchCriteria(controller);
        CreateProductSearchCriteria(controller);
        // go to EB_VfpCtrlMailerWizard3 - invoking page2() invokes build,validate, formsqls directly
        pg2=controller.page2();
        // create a mailer for the selected accounts
        mailerpg=controller.createMailerDirectly();      
        Test.setCurrentpage(mailerpg);
        EB_CtrlChatterNotfication controllerChatter = new EB_CtrlChatterNotfication();
        Pagereference chatterpg=controllerchatter.sendChatterNotification();
        //controllerchatter.CallForMassmailTechteam();
        //start of changes by janantha for CR 1733044
        EBCS_Application__c objApp2 = EBCS_Application__c.getInstance('ProductSearch');
        objApp2.Value__c = 'Legacy Product';
        update objApp2;
        
        Init();
        EB_CtrlMailerWizard controller1 = new EB_CtrlMailerWizard();
        
        
        // from EB_VfpCtrlMailerWizard1(1st page of wizard) go to EB_VfpCtrlMailerWizard2 - criteria is single mail & General notification
        controller1.radioChoice='DefaultSearch';
        controller1.setchoice('allContacts');
        controller1.mailchoice='singleMail';
        controller1.goToSearchPage();
        // populate the search criteria fields
        CreateAccountSearchCriteria(controller1);
        CreateProductSearchCriteria(controller1);
        // go to EB_VfpCtrlMailerWizard3 - invoking page2() invokes build,validate, formsqls directly
        PageReference pg22=controller.page2();
        // get the accounts explicitly and set the checkboxes to true, so that we can add accounts
        controller1.accountList =controller.getAccounts();
        for(EB_AccountWrapper accwrapper : controller1.accountList){
             if(accwrapper.acc.Id != acc2.Id)
            accwrapper.selected= true;
           }
        
        //get the selected accounts & add them to EB_SelectedAccounts__c - invokes getSelected() too
        controller1.getAdded();
        // create a mailer for the selected accounts
        try{
        PageReference mailerpg1=controller.createMailer();
        }
        catch(exception e){
        }
        /*  CR 845804 CNotify: User should be able to pick the default Email Template during Mailer creation 
        CR 1029711 - CNotify: Standardize Action Poller Content, Create Mailer
        2.1 release changes */
        pageReference p44 = controller.getMailerStatus();
        String googleImage1 = controller.getMailerDetails();
        String mailerLink1= controller.getCurrentMailerLink();
        Boolean rendermailerLink1 = controller.getRenderMailerLink();
        
        // from EB_VfpCtrlMailerWizard1(1st page of wizard) go to EB_VfpCtrlMailerWizard2 - criteria is MASS mail & General notification
        controller1.radioChoice='DefaultSearch';
        controller1.setchoice('allContacts');
        controller1.mailchoice='massMail';
        controller1.goToSearchPage();
        // populate the search criteria fields
        CreateAccountSearchCriteria(controller1);
        CreateProductSearchCriteria(controller1);
        // go to EB_VfpCtrlMailerWizard3 - invoking page2() invokes build,validate, formsqls directly
        pg22=controller.page2();
        // create a mailer for the selected accounts
       // mailerpg1=controller.createMailerDirectly();
        Test.stopTest();
        //end of changes by janantha for CR 1733044
    }
    
    /**
    Test case to implement Account Search ServiceNotification - both for single mails & mass mails
*/ 
    static testMethod void OnlyAccountSearchServiceNotification() {
        //start of changes by janantha for CR 1733044
        EBCS_Application__c objApp = EBCS_Application__c.getInstance('ProductSearch');
        objApp.Name = 'ProductSearch';
        objApp.Value__c = 'Legacy Product';
        update objApp;
        //end of changes by janantha for CR 1733044
        // instantiate the controller
        Init();
        EB_CtrlMailerWizard controller = new EB_CtrlMailerWizard();
        
        
        // from EB_VfpCtrlMailerWizard1(1st page of wizard) go to EB_VfpCtrlMailerWizard2 - criteria is single mail & Service notification
        Test.startTest();
    controller.radioChoice='DefaultSearch';
        controller.setchoice('selectedContacts');
        controller.mailchoice='singleMail';
        controller.goToSearchPage();
        // populate the search criteria fields
        CreateAccountSearchCriteria(controller);
        // no product search
        CreateEmptyProductSearchCriteria(controller);
        // go to EB_VfpCtrlMailerWizard3 - invoking page2() invokes build,validate, formsqls directly
        PageReference pg2=controller.page2();
        // get the accounts explicitly and set the checkboxes to true, so that we can add accounts
        controller.accountList =controller.getAccounts();
        for(EB_AccountWrapper accwrapper : controller.accountList)
            accwrapper.selected= true;
       
        //get the selected accounts & add them to EB_SelectedAccounts__c - invokes getSelected() too
        controller.getAdded();
        // create a mailer for the selected accounts
        PageReference mailerpg=controller.createMailer();
        
        // from EB_VfpCtrlMailerWizard1(1st page of wizard) go to EB_VfpCtrlMailerWizard2 - criteria is Mass mail & Service notification
        controller.radioChoice='DefaultSearch';
        controller.setchoice('selectedContacts');
        controller.mailchoice='massMail';
        controller.goToSearchPage();
        // populate the search criteria fields
        CreateAccountSearchCriteria(controller);
        // no product search
        CreateEmptyProductSearchCriteria(controller); 
        // go to EB_VfpCtrlMailerWizard3 - invoking page2() invokes build,validate, formsqls directly
        pg2=controller.page2();
        mailerpg=controller.createMailerDirectly();
     
        //start of changes by janantha for CR 1733044
        EBCS_Application__c objApp1 = EBCS_Application__c.getInstance('ProductSearch');
        objApp1.Value__c = 'Product Catalog';
        update objApp1;
        
        Init();
        EB_CtrlMailerWizard controller1 = new EB_CtrlMailerWizard();
        
        
        // from EB_VfpCtrlMailerWizard1(1st page of wizard) go to EB_VfpCtrlMailerWizard2 - criteria is single mail & Service notification
        controller1.radioChoice='DefaultSearch';
        controller1.setchoice('selectedContacts');
        controller1.mailchoice='singleMail';
        controller1.goToSearchPage();
        // populate the search criteria fields
        CreateAccountSearchCriteria(controller1);
        // no product search
        CreateEmptyProductSearchCriteria(controller1);
        // go to EB_VfpCtrlMailerWizard3 - invoking page2() invokes build,validate, formsqls directly
        PageReference pg22=controller1.page2();
        // get the accounts explicitly and set the checkboxes to true, so that we can add accounts
        controller1.accountList =controller1.getAccounts();
        for(EB_AccountWrapper accwrapper : controller1.accountList)
            accwrapper.selected= true;
       
        //get the selected accounts & add them to EB_SelectedAccounts__c - invokes getSelected() too
        controller1.getAdded();
        // create a mailer for the selected accounts
        PageReference mailerpg1=controller1.createMailer();
        
        // from EB_VfpCtrlMailerWizard1(1st page of wizard) go to EB_VfpCtrlMailerWizard2 - criteria is Mass mail & Service notification
        controller1.radioChoice='DefaultSearch';
        controller1.setchoice('selectedContacts');
        controller1.mailchoice='massMail';
        controller1.goToSearchPage();
        // populate the search criteria fields
        CreateAccountSearchCriteria(controller1);
        // no product search
        CreateEmptyProductSearchCriteria(controller1); 
        // go to EB_VfpCtrlMailerWizard3 - invoking page2() invokes build,validate, formsqls directly
       // pg22=controller.page2();
        //mailerpg1=controller1.createMailerDirectly();
        Test.stopTest();
        //end of changes by janantha for CR 1733044
    }
    
    /**
    Test case to implement Account Search general Notification - both for single mails & mass mails
*/ 
    static testMethod void OnlyAccountSearchGeneralNotification() {
        // instantiate the controller
        Init();
        EB_CtrlMailerWizard controller = new EB_CtrlMailerWizard();
        
        
        // from EB_VfpCtrlMailerWizard1(1st page of wizard) go to EB_VfpCtrlMailerWizard2 - criteria is single mail & General notification
        controller.radioChoice='DefaultSearch';
        controller.setchoice('allContacts');
        controller.mailchoice='singleMail';
        controller.goToSearchPage();
        // populate the search criteria fields
        CreateAccountSearchCriteria(controller);
        //No product search
        CreateEmptyProductSearchCriteria(controller);
        // go to EB_VfpCtrlMailerWizard3 - invoking page2() invokes build,validate, formsqls directly
        PageReference pg2=controller.page2();
        // get the accounts explicitly and set the checkboxes to true, so that we can add accounts
        controller.accountList =controller.getAccounts();
        for(EB_AccountWrapper accwrapper : controller.accountList)
            accwrapper.selected= true;
        Test.startTest();
        //get the selected accounts & add them to EB_SelectedAccounts__c - invokes getSelected() too
        controller.getAdded();
        // create a mailer for the selected accounts
        PageReference mailerpg=controller.createMailer();
        
        // from EB_VfpCtrlMailerWizard1(1st page of wizard) go to EB_VfpCtrlMailerWizard2 - criteria is MASS mail & General notification
        controller.radioChoice='DefaultSearch';
        controller.setchoice('allContacts');
        controller.mailchoice='massMail';
        controller.goToSearchPage();
        // populate the search criteria fields
        CreateAccountSearchCriteria(controller);
        // NO product search
        CreateEmptyProductSearchCriteria(controller);
        // go to EB_VfpCtrlMailerWizard3 - invoking page2() invokes build,validate, formsqls directly
        pg2=controller.page2();
        
        mailerpg=controller.createMailerDirectly();
        Test.stopTest();
    }
    
    /**
    Test case to implement Product Search Service Notification - both for single mails & mass mails
*/ 
    static testMethod void OnlyProductSearchServiceNotification() {
        // instantiate the controller
        Init();
        EB_CtrlMailerWizard controller = new EB_CtrlMailerWizard();
       
        
        // from EB_VfpCtrlMailerWizard1(1st page of wizard) go to EB_VfpCtrlMailerWizard2 - criteria is single mail & Service notification
        controller.radioChoice='DefaultSearch';
        controller.setchoice('selectedContacts');
        controller.mailchoice='singleMail';
        controller.goToSearchPage();
        // populate the search criteria fields
        // no account search
        CreateEmptyAccountSearchCriteria(controller);
        CreateProductSearchCriteria(controller);
        // go to EB_VfpCtrlMailerWizard3 - invoking page2() invokes build,validate, formsqls directly
        Test.startTest();
    PageReference pg2=controller.page2();
        // get the accounts explicitly and set the checkboxes to true, so that we can add accounts
        controller.accountList =controller.getAccounts();
        for(EB_AccountWrapper accwrapper : controller.accountList)
            accwrapper.selected= true;
        
        //get the selected accounts & add them to EB_SelectedAccounts__c - invokes getSelected() too
        
        controller.getAdded();
        // create a mailer for the selected accounts
        PageReference mailerpg=controller.createMailer();
        
        // from EB_VfpCtrlMailerWizard1(1st page of wizard) go to EB_VfpCtrlMailerWizard2 - criteria is Mass mail & Service notification
        controller.radioChoice='DefaultSearch';
        controller.setchoice('selectedContacts');
        controller.mailchoice='massMail';
        controller.goToSearchPage();
        // populate the search criteria fields
        // no account search
        CreateEmptyAccountSearchCriteria(controller);
        CreateProductSearchCriteria(controller); 
        // go to EB_VfpCtrlMailerWizard3 - invoking page2() invokes build,validate, formsqls directly
        pg2=controller.page2();

        mailerpg=controller.createMailerDirectly();
        Test.stopTest();
    }
    
    /**
    Test case to implement product Search general Notification - both for single mails & mass mails
*/ 
    static testMethod void OnlyProductSearchGeneralNotification() {
        // instantiate the controller
        Init();
        EB_CtrlMailerWizard controller = new EB_CtrlMailerWizard();
        
        
        // from EB_VfpCtrlMailerWizard1(1st page of wizard) go to EB_VfpCtrlMailerWizard2 - criteria is single mail & General notification
        controller.radioChoice='DefaultSearch';
        controller.setchoice('allContacts');
        controller.mailchoice='singleMail';
        controller.goToSearchPage();
        // populate the search criteria fields
        // no account search
        CreateEmptyAccountSearchCriteria(controller);
        CreateProductSearchCriteria(controller);
        // go to EB_VfpCtrlMailerWizard3 - invoking page2() invokes build,validate, formsqls directly
        Test.startTest();
    PageReference pg2=controller.page2();
        // get the accounts explicitly and set the checkboxes to true, so that we can add accounts
        controller.accountList =controller.getAccounts();
        for(EB_AccountWrapper accwrapper : controller.accountList)
            accwrapper.selected= true;
        
        //get the selected accounts & add them to EB_SelectedAccounts__c - invokes getSelected() too
        controller.getAdded();
        // create a mailer for the selected accounts
        PageReference mailerpg=controller.createMailer();
        
        // from EB_VfpCtrlMailerWizard1(1st page of wizard) go to EB_VfpCtrlMailerWizard2 - criteria is MASS mail & General notification
        controller.radioChoice='DefaultSearch';
        controller.setchoice('allContacts');
        controller.mailchoice='massMail';
        controller.goToSearchPage();
        // populate the search criteria fields
        // no account search
        CreateEmptyAccountSearchCriteria(controller);
        CreateProductSearchCriteria(controller);
        // go to EB_VfpCtrlMailerWizard3 - invoking page2() invokes build,validate, formsqls directly
        pg2=controller.page2();

        mailerpg=controller.createMailerDirectly();
        Test.stopTest();
    }
    
    /**
    Test case to navigate between different pages of the wizard
*/ 
    static testmethod void NavigateToOtherPagesTest()
    {
  ManagedPkgErrorClass.isFromManagedPackage=false;
  Init();
    EB_CtrlMailerWizard controller = new EB_CtrlMailerWizard();
    
    //Service Incident notification,Mass Mail, Acc Id Search
    controller.setchoice('selectedContacts');
    controller.radioChoice='CustomSearch-Acc';
    controller.mailchoice='massMail';
    controller.goToSearchPage();
    
    //Service Incident notification,Single Mail, Acc Id Search
    controller.setchoice('selectedContacts');
    controller.radioChoice='CustomSearch-Acc';
    controller.mailchoice='singleMail';
    controller.goToSearchPage();
    
    //General Incident notification,Mass Mail, Acc Id Search
    controller.setchoice('allContacts');
    controller.radioChoice='CustomSearch-Acc';
    controller.mailchoice='massMail';
    controller.goToSearchPage();
    
    //General Incident notification,Single Mail, Acc Id Search
    controller.setchoice('allContacts');
    controller.radioChoice='CustomSearch-Acc';
    controller.mailchoice='singleMail';
    controller.goToSearchPage();
    
    //Service Incident notification,Mass Mail, Cp Code Search
    controller.setchoice('selectedContacts');
    controller.radioChoice='CustomSearch-Cp';
    controller.mailchoice='massMail';
    controller.goToSearchPage();
    
    //Service Incident notification,Single Mail, Cp Code Search
    controller.setchoice('selectedContacts');
    controller.radioChoice='CustomSearch-Cp';
    controller.mailchoice='singleMail';
    controller.goToSearchPage();
    
    //General Incident notification,Mass Mail, Cp Code Search
    controller.setchoice('allContacts');
    controller.radioChoice='CustomSearch-Cp';
    controller.mailchoice='massMail';
    controller.goToSearchPage();
    
    //General Incident notification,Single Mail, Cp Code Search
    controller.setchoice('allContacts');
    controller.radioChoice='CustomSearch-Cp';
    controller.mailchoice='singleMail';
    controller.goToSearchPage();
    
    //redirect to the VfpMailerWizard1 page from VfpMailerWizard2
    PageReference main_pg=controller.main_page();
    // URL to dispaly the Entitled Products Report
    String AccountProductPage= controller.getAccountProductPage();
    //URL to the enhanced list Selected Accounts that is displayed in a different page
    String selectedAccountsURL=controller.RedirectToSelectedAccounts();
    // redirect to the VfpMailerWizard2 page from VfpMailerWizard3
    PageReference page1= controller.page1();
    }
    
    /**
    Test case to invoke some miscellaneous methods - to improve coverage
*/ 
    static testmethod void TestMiscMethods(){
        Init();
        EB_CtrlMailerWizard controller = new EB_CtrlMailerWizard();
        
        String disableAccount = 'true';
        String disableProduct = 'true';
        String disableMailerButton;
        String choice;
        List<SelectOption> pickListItemsAccount = new List<SelectOption>();
        List<SelectOption> pickListItemsProduct = new List<SelectOption>();
        List<SelectOption> logicalOperators = new List<SelectOption>();
        List<SelectOption> items = new List<SelectOption>();
        List<SelectOption> operators = new List<SelectOption>();
    ManagedPkgErrorClass.isFromManagedPackage=false;
        
        controller.setdisableStatus('true');
        disableAccount = controller.getdisableStatus();
        System.assertEquals(disableAccount,'true');
        controller.setdisableProduct('true');
        disableProduct = controller.getdisableProduct();
        System.assertEquals(disableProduct,'true');
        controller.setdisableMailerButton(controller.getdisableMailerButton());
        controller.disableButton();
        System.assertEquals(controller.buttonVisible,false);
        controller.enableButton();
        System.assertEquals(controller.buttonVisible,true);
        choice=controller.getchoice();
        pickListItemsAccount = controller.getPickListItems();
        pickListItemsProduct = controller.getPickListItemsProduct();
        logicalOperators = controller.getlogicalOperators();
        items = controller.getItems();
        items=controller.getRadioItems();
        items=controller.getMailItems();
        operators = controller.getOperators();
        controller.enableProduct();
        controller.enable();
        controller.clearSearch();
        controller.clearProductSearch();
       
    }
    
     static testmethod void TestMiscMethods1(){
        Init();
        EB_CtrlMailerWizard controller = new EB_CtrlMailerWizard();
        controller.getSortedList(controller.originalList,'Product_Name__c', true);
        boolean showTemplate = controller.showDefaultTemplate;
        
        System.currentPageReference().getParameters().put('incident_type', 'true');
    
        string incidentType = controller.MailerIncidentType;
    
        System.assert(controller.objController != null);
        boolean next = controller.hasNext;
        boolean previous = controller.hasPrevious;
        controller.first();
        controller.last();
        
        
        controller.wrappers[0].selected = true;
        controller.getSelectedProducts();       
    }
    
    /**
    Test case to Carry out few negative test cases like - Empty search criteria, invalid search criteria
*/ 
    static testmethod void NegativeSearchTest(){
        Init();
        EB_CtrlMailerWizard controller = new EB_CtrlMailerWizard();
        
        
         // from EB_VfpCtrlMailerWizard1(1st page of wizard) go to EB_VfpCtrlMailerWizard2 - criteria is single mail & General notification
        controller.radioChoice='DefaultSearch';
        controller.setchoice('allContacts');
        controller.mailchoice='singleMail';
        controller.goToSearchPage();
        // populate empty search criteria fields
        CreateEmptyAccountSearchCriteria(controller);
        CreateEmptyProductSearchCriteria(controller);
        // go to EB_VfpCtrlMailerWizard3 - invoking page2() invokes build,validate, formsqls directly
                Test.startTest();
        PageReference pg2=controller.page2();

        //creating wrong SQLs so that validation of SQLs fail
        controller.SQLWhere='(null=\'A\')';
        controller.PSQLWhere='(null=\'EdgeControl\')';
        PageReference pg1= controller.validateProduct();
        pg2= controller.validateAccount();
    Test.stopTest();
    }
    
    static testmethod void QuickFilterPositiveTest()
    {
        Init();
        EB_CtrlMailerWizard controller = new EB_CtrlMailerWizard();
        
        controller.radioChoice='DefaultSearch';
        controller.setchoice('allContacts');
        controller.mailchoice='singleMail';
        controller.goToSearchPage();
        // populate empty search criteria fields
        CreateEmptyAccountSearchCriteria(controller);
        CreateEmptyProductSearchCriteria(controller);
        // go to EB_VfpCtrlMailerWizard3 - invoking page2() invokes build,validate, formsqls directly
        Test.startTest();
    PageReference pg2=controller.page2();
        controller.addAllAccounts();
        controller.customerTier='A';
        controller.supportLevel='A';
        controller.accountName='A';
        controller.accountId='A';    
        controller.toggleSortOrder();
        controller.applyFilter();  
        controller.clearFilter();  
    Test.stopTest();
    }
    
    static Account acc2;
    static{
        utilTestClass.createCustomSettings();
        list<Account> lAcc = new list<Account>();
        Account acc = utilTestClass.CreateAccount('test acc1');
        //acc.AKAM_Account_ID__c = 'F-AC-Test-ACC';
        lAcc.add(acc);
        
        acc2 = utilTestClass.CreateAccount('test acc2');
        acc2.AKAM_Account_ID__c = 'F-AC-Test-ACC1';
        lAcc.add(acc2);
        
        insert lAcc;
        Contact internalContact = utilTestClass.CreateContact('Test','MailerContact');
        internalContact.AccountId = acc.Id;
        insert internalContact;
        list<EBCS_Application__c> listApp = new list<EBCS_Application__c>();
        EBCS_Application__c  app1 = new EBCS_Application__c();
        app1.Name = 'InternalContactId';
        app1.Value__c = internalContact.Id;
        listApp.add(app1);
        EBCS_Application__c  app2 = new EBCS_Application__c();
        app2.Name = 'MassMailsBatchSize';
        app2.Value__c = '25';
        listApp.add(app2);
        EBCS_Application__c  app3 = new EBCS_Application__c();
        app3.Name = 'OrgWideEmailAddressName';
        app3.Value__c = 'ccare-noreply';
        listApp.add(app3);
        EBCS_Application__c  app4 = new EBCS_Application__c();
        app4.Name = 'OrgWideReplyToEmailAddressName';
        app4.Value__c = 'ccare-replyTo';
        listApp.add(app4);
        EBCS_Application__c  app5 = new EBCS_Application__c();
        app5.Name = 'SingleMailsBatchSize';
        app5.Value__c = '25';
        listApp.add(app5);
        EBCS_Application__c  app6 = new EBCS_Application__c();
        app6.Name = 'UseOrgWideEmailAddress';
        app6.Value__c = 'TRUE';
        listApp.add(app6);
        // set LimitSQL custom setting value to 20 for test classes
        EBCS_Application__c app7 = new EBCS_Application__c();
        app7.Name = 'LimitSQL';
        app7.Value__c = '20';
        listApp.add(app7);
        
        EBCS_Application__c app8 = new EBCS_Application__c();
        app8.Name = 'RowsPerPage';
        app8.Value__c = '25';
        listApp.add(app8);
        EBCS_Application__c app9 = new EBCS_Application__c();
        app9.Name = 'DebugSQL';
        app9.Value__c = 'TRUE';
        listApp.add(app9);
        EBCS_Application__c app10 = new EBCS_Application__c();
        app10.Name = 'EnvironmentURL';
        app10.Value__c = URL.getSalesforceBaseUrl().toExternalForm();
        listApp.add(app10);
        EBCS_Application__c app11 = new EBCS_Application__c();
        app11.Name = 'DefaultEmailTemplate';
        app11.Value__c = 'Visible';
        listApp.add(app11);
        
        EBCS_Application__c app12 = new EBCS_Application__c();
        app12.Name = 'ProductSearch';
        app12.Value__c = 'Product Catalog';
        listApp.add(app12);
        EBCS_Application__c app13 = new EBCS_Application__c();
        app13.Name = 'ProductsListReport';
        app13.Value__c = '00OA0000002t4Md';
        listApp.add(app13);
        
        insert listApp;
        
        list<EBCS_AccountSearchFields__c> lstAccSearch = new list<EBCS_AccountSearchFields__c>();
        EBCS_AccountSearchFields__c accSearch1 = new EBCS_AccountSearchFields__c();
        accSearch1.Name = 'Account Id';
        accSearch1.EB_DataType__c = 'String';
        accSearch1.Name_API__c = 'AKAM_Account_ID__c';
        lstAccSearch.add(accSearch1);
        EBCS_AccountSearchFields__c accSearch2 = new EBCS_AccountSearchFields__c();
        accSearch2.Name = 'Account Name';
        accSearch2.EB_DataType__c = 'String';
        accSearch2.Name_API__c = 'Name';
        lstAccSearch.add(accSearch2);
        EBCS_AccountSearchFields__c accSearch3 = new EBCS_AccountSearchFields__c();
        accSearch3.Name = 'Customer Tier';
        accSearch3.EB_DataType__c = 'String';
        accSearch3.Name_API__c = 'Customer_Tier__c';
        lstAccSearch.add(accSearch3);
        EBCS_AccountSearchFields__c accSearch4 = new EBCS_AccountSearchFields__c();
        accSearch4.Name = 'Support Level';
        accSearch4.EB_DataType__c = 'String';
        accSearch4.Name_API__c = 'Support_Level__c';
        lstAccSearch.add(accSearch4);
        insert lstAccSearch;
              
        EBCS_ProductSearchFields__c prodSearch = new EBCS_ProductSearchFields__c();
        prodSearch.Name = 'Product Name';
        prodSearch.EB_Data_Type__c = 'String';
        prodSearch.Name_API__c = 'EB_Product__c';
        insert prodSearch;
        
        EBCS_DisplayFields__c display = new EBCS_DisplayFields__c();
        display.Name = 'Account Name';
        display.Name_API__c = 'Name';
        insert display;
        
        
        EB_ResellerContractId__c reseller = new EB_ResellerContractId__c();
        reseller.Name = 'AT&T Services, Inc.1';
        reseller.Original_Contract_Id__c = '3-VIY7BF';
        insert reseller;
        
        //Account accDetails = [SELECT Id, AKAM_Account_ID__c FROM Account][0];
        EBAccountDetails__c accDetailsCS = new EBAccountDetails__c();
        accDetailsCS.Name = 'AkamaiAsset';
        accDetailsCS.AccountAkamId__c = 'ACXC';
        accDetailsCS.EBAccountId__c = acc2.Id;
        
        insert accDetailsCS;
    }
}