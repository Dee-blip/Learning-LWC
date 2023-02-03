/*
Author: Sharath K
History: 9/14/2010- CR 794793: Implementing code review findings - Revamped test class to cover all test cases in a systematic manner
11/14/2011 - Made few changes to the test class for CR 1378172 CNotify: Superficial Fix, Accepting Issue Details & SI# in the first step of Mailer Creation

Description: Contains all positive and negative test cases for EB_CtrlMailerWizard
Test Cases: 
Create single mails, Service Incident Notification, AccountId search
Create single mails, General Incident Notification,AccountId search
Create Mass mails, Service Incident Notification, AccountId search
Create Mass mails, General Incident Notification, AccountId search
 Yet to implement:
Create single mails, Service Incident Notification, CP Code search
Create single mails, General Incident Notification, CP Code search
Create Mass mails, Service Incident Notification, CP Code search
Create Mass mails, General Incident Notification, CP Code search

Also:
Navigate to other pages
Negative test cases
*/

@isTest
private class EB_CtrlMailerWizardByAccCPId_Test {

    
     private static void Init(){
		ManagedPkgErrorClass.isFromManagedPackage=false;
     // set LimitSQL custom setting value to 20 for test classes
        EBCS_Application__c limitRows = EBCS_Application__c.getInstance('LimitSQL');
        limitRows.Value__c = '20';
        update limitRows;
    }
    
     /* Test case to simulate AccountId Search -ServiceNotification ,SingleMail
     */
    static testMethod void AccountIdSearchServiceNotificationSingleMail() {
      string dispVal;
        EB_CtrlMailerWizard c1 = new EB_CtrlMailerWizard();
        //create a token by clicking on goTosearchPage()
        c1.goToSearchPage();
        //set parameters for the page
        PageReference SearchPg = Page.EB_VfpMailerWizardByAccCPId1;
        Test.setCurrentPageReference(SearchPg);
        Searchpg.getParameters().put('basis', 'accId');
        Searchpg.getParameters().put('choice', 'selectedContacts');
        Searchpg.getParameters().put('type', 'single');
        Searchpg.getParameters().put('token', c1.newtoken.Id);
        // instantiate the controller
        EB_CtrlMailerWizardByAccCPId controller = new EB_CtrlMailerWizardByAccCPId();
        Init();
        controller.SQLWhere='F-AC-140731 \n F-AC-140729 \n F-AC-140732 \n F-AC-140730 \n F-AC-140734 \n 1-K05YI \n AANA-44I5JM \n 1-6J4BQP \n 1-7TL1 \n 1-2JA0T \n 1-6TOG1';
        dispVal=controller.getDispvalue();
        // go to EB_VfpCtrlMailerWizardByAccCPId2 - invoking page2() invokes build,validate directly
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
        Test.stopTest();
    }
    
    /* Test case to simulate AccountId Search -ServiceNotification ,Mass Mail
     */
    static testMethod void AccountIdSearchServiceNotificationMassMail() {
      string dispVal;
        EB_CtrlMailerWizard c1 = new EB_CtrlMailerWizard();
        //create a token by clicking on goTosearchPage()
        c1.goToSearchPage();
        //set parameters for the page
        PageReference SearchPg = Page.EB_VfpMailerWizardByAccCPId1;
        Test.setCurrentPageReference(SearchPg);
        Searchpg.getParameters().put('basis', 'accId');
        Searchpg.getParameters().put('choice', 'selectedContacts');
        Searchpg.getParameters().put('type', 'mass');
        Searchpg.getParameters().put('token', c1.newtoken.Id);
        // instantiate the controller
        EB_CtrlMailerWizardByAccCPId controller = new EB_CtrlMailerWizardByAccCPId();
        Init();
        controller.SQLWhere='F-AC-140731 \n F-AC-140729 \n F-AC-140732 \n F-AC-140730 \n F-AC-140734 \n 1-K05YI \n AANA-44I5JM \n 1-6J4BQP \n 1-7TL1 \n 1-2JA0T \n 1-6TOG1';
        dispVal=controller.getDispvalue();
        // go to EB_VfpCtrlMailerWizardByAccCPId2 - invoking page2() invokes build,validate directly
        PageReference pg2=controller.page2();
        // get the accounts explicitly and set the checkboxes to true, so that we can add accounts
        controller.accountList =controller.getAccounts();
        for(EB_AccountWrapper accwrapper : controller.accountList)
            accwrapper.selected= true;
        Test.startTest();
        //get the selected accounts & add them to EB_SelectedAccounts__c - invokes getSelected() too
        controller.getAdded();
        // create a mailer for the selected accounts
        PageReference mailerpg=controller.createMailerDirectly();
        Test.stopTest();
    }
    
    /* Test case to simulate AccountId Search -General Notification ,Mass Mail
     */
    static testMethod void AccountIdSearchGeneralNotificationMassMail() {
      string dispVal;
        EB_CtrlMailerWizard c1 = new EB_CtrlMailerWizard();
        //create a token by clicking on goTosearchPage()
        c1.goToSearchPage();
        //set parameters for the page
        PageReference SearchPg = Page.EB_VfpMailerWizardByAccCPId1;
        Test.setCurrentPageReference(SearchPg);
        Searchpg.getParameters().put('basis', 'accId');
        Searchpg.getParameters().put('choice', 'allContacts');
        Searchpg.getParameters().put('type', 'mass');
        Searchpg.getParameters().put('token', c1.newtoken.Id);
        // instantiate the controller
        EB_CtrlMailerWizardByAccCPId controller = new EB_CtrlMailerWizardByAccCPId();
        Init();
        controller.SQLWhere='F-AC-140731 \n F-AC-140729 \n F-AC-140732 \n F-AC-140730 \n F-AC-140734 \n 1-K05YI \n AANA-44I5JM \n 1-6J4BQP \n 1-7TL1 \n 1-2JA0T \n 1-6TOG1';
        dispVal=controller.getDispvalue();
        // go to EB_VfpCtrlMailerWizardByAccCPId2 - invoking page2() invokes build,validate directly
        PageReference pg2=controller.page2();
        // get the accounts explicitly and set the checkboxes to true, so that we can add accounts
        controller.accountList =controller.getAccounts();
        for(EB_AccountWrapper accwrapper : controller.accountList)
            accwrapper.selected= true;
        Test.startTest();
        //get the selected accounts & add them to EB_SelectedAccounts__c - invokes getSelected() too
        controller.getAdded();
        // create a mailer for the selected accounts
        PageReference mailerpg=controller.createMailerDirectly();
        Test.stopTest();
    }
    
    /* Test case to simulate AccountId Search -General Notification ,SingleMail
     */
    static testMethod void AccountIdSearchGeneralNotificationSingleMail() {
      string dispVal;
        EB_CtrlMailerWizard c1 = new EB_CtrlMailerWizard();
        //create a token by clicking on goTosearchPage()
        c1.goToSearchPage();
        //set parameters for the page
        PageReference SearchPg = Page.EB_VfpMailerWizardByAccCPId1;
        Test.setCurrentPageReference(SearchPg);
        Searchpg.getParameters().put('basis', 'accId');
        Searchpg.getParameters().put('choice', 'allContacts');
        Searchpg.getParameters().put('type', 'single');
        Searchpg.getParameters().put('token', c1.newtoken.Id);
        // instantiate the controller
        EB_CtrlMailerWizardByAccCPId controller = new EB_CtrlMailerWizardByAccCPId();
        Init();
        controller.SQLWhere='F-AC-140731 \n F-AC-140729 \n F-AC-140732 \n F-AC-140730 \n F-AC-140734 \n 1-K05YI \n AANA-44I5JM \n 1-6J4BQP \n 1-7TL1 \n 1-2JA0T \n 1-6TOG1';
        dispVal=controller.getDispvalue();
        // go to EB_VfpCtrlMailerWizardByAccCPId2 - invoking page2() invokes build,validate directly
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
        Test.stopTest();
    }
    
   /* Test case to navigate to other page
     */
    static testmethod void NavigateToOtherPagesTest()
    {
    EB_CtrlMailerWizardByAccCPId controller = new EB_CtrlMailerWizardByAccCPId();
    // redirect to the EB_VfpCtrlMailerWizardByAccCPId1 page from EB_VfpCtrlMailerWizardByAccCPId2
    PageReference page1= controller.page1();
    }
    
    /* Negative test cases - empty search criteria & wrong Account IDs
     */
    static testmethod void NegativeSearchTest(){
      //set parameters for the page
        PageReference SearchPg = Page.EB_VfpMailerWizardByAccCPId1;
        Test.setCurrentPageReference(SearchPg);
        Searchpg.getParameters().put('basis', 'accId');
        Searchpg.getParameters().put('choice', 'allContacts');
        Searchpg.getParameters().put('type', 'single');
        EB_CtrlMailerWizardByAccCPId controller = new EB_CtrlMailerWizardByAccCPId();
        Init();
        // empty search criteria
    controller.SQLWhere='';
    PageReference pg2=controller.page2();
    
    // wrong search criteria
    controller.SQLWhere='1abc xyz pqr';
    PageReference validate=controller.validateAccount();
    pg2=controller.page2();        
    }
   
}