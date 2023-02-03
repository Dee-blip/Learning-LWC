/*
Author: Jayalakshmi A
Description: Contains test cases for EB_CtrlBouncedEmailReport. CR 1414090
Created Date: 12/1/2011
*/

@isTest
private class EB_CtrlBouncedEmailReport_Test 
{
    static EmailTemplate et;
    static EB_EmailTemplate__c testTemplate;
    static EB_AkaMailer__c mailer;
    static EB_AkaMAccount__c acc;
    static Contact con1;
    static Contact con2;
    static Account accOld;
    static EB_AkaMContact__c mailerContact1;
    static EB_AkaMContact__c mailerContact2;
    static EB_CtrlBouncedEmailReport bouncedEmailReport;
    
    /*
     Author : Jayalakshmi A
     Description: This method initialises data. CR 1414090
     Created Date: 12/1/2011
    */
    static testMethod void init()
    {
        ManagedPkgErrorClass.isFromManagedPackage=false;
        User thisUser = [Select ID from User where ID = :UserInfo.getUserId()];
        System.runAs(thisUser){
            et = EB_InitializeObjects.createEmailTemplate('New_Email_Template','text');
            Database.insert(et);
        }
            
        testTemplate= EB_InitializeObjects.createCustomTemplate('template 1','text', et.Id);
        database.insert(testTemplate);
        
        // create an account     
        accOld = EB_InitializeObjects.createAccount('TestAccount_01'); 
        Database.insert(accOld); 

        // Create contacts
        con1 = EB_InitializeObjects.createContact('Fname','Lname',accOld.Id);
        con1.EmailBouncedReason = '550:Invaid Recipient';
        con1.Email = 'janantha@akamai.com';
        Database.insert(con1); 
        
        con2 = EB_InitializeObjects.createContact('Fname','Lname',accOld.Id);
        con2.EmailBouncedReason = '550:Invaid Recipient';
        con2.Email = 'test@akamai.com';
        Database.insert(con2); 
        
        //create a mailer 
        mailer = EB_InitializeObjects.createMailer(testTemplate.Id,'Single Email');
        Database.insert(mailer);
        
        acc = EB_InitializeObjects.createMailerAccount(testTemplate.Id, mailer.Id, accOld.Id);
        Database.insert(acc);
        
        //create 3 mailer contacts
        mailerContact1 = EB_InitializeObjects.createMailerContact(testTemplate.Id, acc.Id, con1.Id);
        mailerContact1.EB_ToList__c = 'janantha@akamai.com\ntest@akamai.com';
        Database.insert(mailerContact1);
        
        mailerContact2 = EB_InitializeObjects.createMailerContact(testTemplate.Id, acc.Id, con2.Id);
        mailerContact2.EB_ToList__c = 'janantha@akamai.com\ntest@akamai.com';
        Database.insert(mailerContact2);
    }
    
    /*
     Author : Jayalakshmi A
     Description: This method is a test case for obtaining the bounced report for the mailer created in the init method. CR 1414090
     Created Date: 12/1/2011
    */
    static testMethod void bounceEmailTest() 
    {
        init();
        PageReference Pg = Page.EB_VfpEmailBounceReport;  
        Test.setCurrentPageReference(Pg);
        ApexPages.currentPage().getParameters().put('mailerId',mailer.Id);
        test.startTest();
        bouncedEmailReport = new EB_CtrlBouncedEmailReport();
        test.stopTest();
    }
    
    /*
     Author : Jayalakshmi A
     Description: This method is a negative test case. CR 1414090
     Created Date: 12/1/2011
    */
    static testMethod void negativeBounceEmailTest() 
    {
        init();
        PageReference Pg = Page.EB_VfpEmailBounceReport;  
        Test.setCurrentPageReference(Pg);
        ApexPages.currentPage().getParameters().put('mailerId','123');
        test.startTest();
        bouncedEmailReport = new EB_CtrlBouncedEmailReport();
        test.stopTest();
    }
}