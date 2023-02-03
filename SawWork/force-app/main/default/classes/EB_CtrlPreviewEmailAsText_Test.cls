/*
 Author: Jayalakshmi A & Sharath K
 Description: Contains all the test cases for EB_CtrlPreviewEmailAsText
  9/21/2010- CR 794793: Implementing code review findings- This class now uses a common class EB_InitializeObjects to initialize the prerequisites for test cases
  Modified on: 11/14/11 by janantha for enabling Preview Template for Text Templates in Mass Mails CR# 1404271
 */
@isTest
private class EB_CtrlPreviewEmailAsText_Test {
    
    static EB_AkaMailer__c mailer;
    static Account accOld;
    static EB_AkaMAccount__c acc; 
    static EB_AkaMContact__c mailerContact1;
    static Contact con1;
    static EB_EmailTemplate__c testTemplate2;
    static EB_CtrlPreviewEmailAsText textEmailPreview;
    static EB_NotificationType__c templateType;
    static EB_NotificationType__c templateType1; 
    
    /*
     Author : Jayalakshmi A
     Description: This method is used to initialise data for test method.
     Created On: 7/-/2010
     Modified by: Sharath
     9/21/2010:  CR 794793: Implementing code review findings - all the objects are now initialized by calling a common class EB_InitializeObjects
    */
    static void Init()
    {
        ManagedPkgErrorClass.isFromManagedPackage=false;
		//create Email Template Types Single Email and Mass Email
        templateType=new EB_NotificationType__c();
        templateType.Name= 'Single Email';
        templateType.Folder_Name__c=' EB_CNSingleMail';
        database.insert(templateType);
        
        templateType1=new EB_NotificationType__c();
        templateType1.Name= 'Mass Email';
        templateType1.Folder_Name__c=' EB_CNMassMail';
        database.insert(templateType1);
        
        String tempId1=[Select e.Id,developerName From EmailTemplate e where e.TemplateType='text' and e.FolderId in ( select Id from Folder where Name='Out of the box Templates') limit 1].Id;
        //CR 794793- calling the method in the common class(EB_InitializeObjects) for initializing custom template 
        testTemplate2= EB_InitializeObjects.createCustomTemplate('template 2','text', tempId1);
        database.insert(testTemplate2);
        
        // create an account
        //CR 794793- calling the method in the common class(EB_InitializeObjects) for initializing Account    
        accOld = EB_InitializeObjects.createAccount('TestAccount_01'); 
        Database.insert(accOld); 
        
        //create a mailer
        //CR 794793- calling the method in the common class(EB_InitializeObjects) for initializing mailer
        mailer = EB_InitializeObjects.createMailer(testTemplate2.Id,'Single Email');
        Database.insert(mailer);
        
        //create a mailer account
        //CR 794793- calling the method in the common class(EB_InitializeObjects) for initializing mailer account
        acc = EB_InitializeObjects.createMailerAccount(testTemplate2.Id, mailer.Id, accOld.Id);
        Database.insert(acc);
    
        // Create contact
        //CR 794793- calling the method in the common class(EB_InitializeObjects) for initializing Contact
        con1 = EB_InitializeObjects.createContact('Fname','Lname',accOld.Id);
        Database.insert(con1); 
        //create a mailer contact
        //CR 794793- calling the method in the common class(EB_InitializeObjects) for initializing mailer contact
        mailerContact1 = EB_InitializeObjects.createMailerContact(testTemplate2.Id, acc.Id, con1.Id);
        Database.insert(mailerContact1); 
    
    }
    
    /*
     Author : Jayalakshmi A
     Description: This method is a positive test case for preview of text based Email templates.
     Created On: 7/-/2010
    */
    static testMethod void TextEmailPreview_UnitTest() {
        Init();
        String mailerId = mailerContact1.Id;
        //system.assertEquals(mailerId,null);
        PageReference Pg = Page.EB_VfpPreviewEmailAsText;  
        Test.setCurrentPageReference(Pg);
        ApexPages.currentPage().getParameters().put('id',mailerId);
        ApexPages.currentPage().getParameters().put('MailerType','Single Email');
        test.startTest();
        textEmailPreview = new EB_CtrlPreviewEmailAsText();
        test.stopTest();
    }
    
    /*
     Author : Jayalakshmi A
     Description: This method is a positive test case for preview of text based Email templates for Mass Emails.
     Created On: 11/14/2011
    */
    
    static testMethod void TextEmailPreview_UnitTest_MassEmail() {
        Init();
        String mailerId = mailerContact1.Id;
        //system.assertEquals(mailerId,null);
        PageReference Pg = Page.EB_VfpPreviewEmailAsText;  
        Test.setCurrentPageReference(Pg);
        ApexPages.currentPage().getParameters().put('id',mailerId);
        ApexPages.currentPage().getParameters().put('MailerType','Mass Email');
        test.startTest();
        textEmailPreview = new EB_CtrlPreviewEmailAsText();
        test.stopTest();
    }
}