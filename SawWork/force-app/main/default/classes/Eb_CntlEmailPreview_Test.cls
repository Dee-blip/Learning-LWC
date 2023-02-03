/*
CR 2812593 - Email preview in Mailer not working for HTML templates 
Created On: 1 January 2016
Created By: ssawhney
Description: Test Class for Eb_CntlEmailPreview 
*/
@isTest(SeeAllData=true)
private class Eb_CntlEmailPreview_Test {
    
    static Account acc;
    static Contact con;
    static Emailtemplate emailTemp;
    static EB_EmailTemplate__c template;
    static EB_AkaMailer__c mailer;
    static EB_AkaMAccount__c mailerAcc; 
    static EB_AkaMContact__c mailerCon;
    static Eb_CntlEmailPreview emailPreview;
    static User usr = [Select id from User where Id = :UserInfo.getUserId()];
    
    static void InitTextTemplate()
    {
        ManagedPkgErrorClass.isFromManagedPackage=false;

        emailTemp = EB_InitializeObjects.createEmailTemplate('New_Email_Template','text');
        System.RunAs(usr){
            insert emailTemp;
        }

        //Create Custom Email Template
        template = EB_InitializeObjects.createCustomTemplate('text template','text', emailTemp.Id);
        insert template;
        
        //Create an Account   
        acc = EB_InitializeObjects.createAccount('Preview Email Acc'); 
        insert acc;
        
        // Create a Contact
        con = EB_InitializeObjects.createContact('Fname','Lname',acc.Id);
        insert con;

        //Create a mailer
        mailer = EB_InitializeObjects.createMailer(template.Id,'Single Email');
        insert mailer;
        
        //create a mailer account
        mailerAcc = EB_InitializeObjects.createMailerAccount(template.Id, mailer.Id, acc.Id);
        insert mailerAcc;
    
        //create a mailer contact
        mailerCon = EB_InitializeObjects.createMailerContact(template.Id, mailerAcc.Id, con.Id);
        insert mailerCon; 
    
    }

    static void InitHTMLTemplate()
    {
        ManagedPkgErrorClass.isFromManagedPackage=false;

        emailTemp = EB_InitializeObjects.createEmailTemplate('New_Email_Template','HTML');
        emailTemp.TemplateStyle = 'formalLetter';        
        emailTemp.HtmlValue = '<body>html body</body>';
        System.RunAs(usr){
            insert emailTemp;
        }

        //Create Custom Email Template
        template = EB_InitializeObjects.createCustomTemplate('html template','html', emailTemp.Id);
        insert template;
        
        //Create an Account   
        acc = EB_InitializeObjects.createAccount('Preview Email Acc'); 
        insert acc;
        
        // Create a Contact
        con = EB_InitializeObjects.createContact('Fname','Lname',acc.Id);
        insert con;

        //Create a mailer
        mailer = EB_InitializeObjects.createMailer(template.Id,'Mass Email');
        insert mailer;
        
        //create a mailer account
        mailerAcc = EB_InitializeObjects.createMailerAccount(template.Id, mailer.Id, acc.Id);
        insert mailerAcc;
    
        //create a mailer contact
        mailerCon = EB_InitializeObjects.createMailerContact(template.Id, mailerAcc.Id, con.Id);
        insert mailerCon; 
    
    }
    
    static testMethod void TextEmailPreview_SingleMail_UnitTest() {
        InitTextTemplate();
        PageReference ref = Page.EB_EmailPreview;  
        Test.setCurrentPageReference(ref);
        ApexPages.currentPage().getParameters().put('id',mailerCon.Id);
        ApexPages.currentPage().getParameters().put('MailerType','Single Email');
        test.startTest();
        emailPreview = new Eb_CntlEmailPreview();
        emailPreview.FetchEmailBody();
        test.stopTest();
        System.assertNotEquals(emailPreview.textBody, null);
    }

    static testMethod void TextEmailPreview_MassMail_UnitTest() {
        InitTextTemplate();
        PageReference ref = Page.EB_EmailPreview;  
        Test.setCurrentPageReference(ref);
        ApexPages.currentPage().getParameters().put('id',mailerCon.Id);
        ApexPages.currentPage().getParameters().put('MailerType','Mass Email');
        test.startTest();
        emailPreview = new Eb_CntlEmailPreview();
        emailPreview.FetchEmailBody();
        test.stopTest();
        System.assertNotEquals(emailPreview.textBody, null);
    }

    static testMethod void HTMLEmailPreview_SingleMail_UnitTest() {
        InitHTMLTemplate();
        PageReference ref = Page.EB_EmailPreview;  
        Test.setCurrentPageReference(ref);
        ApexPages.currentPage().getParameters().put('id',mailerCon.Id);
        ApexPages.currentPage().getParameters().put('MailerType','Single Email');
        test.startTest();
        emailPreview = new Eb_CntlEmailPreview();
        emailPreview.FetchEmailBody();
        test.stopTest();
        System.assertNotEquals(emailPreview.htmlBody, null);
    }

    static testMethod void HTMLEmailPreview_MassMail_UnitTest() {
        InitHTMLTemplate();
        PageReference ref = Page.EB_EmailPreview;  
        Test.setCurrentPageReference(ref);
        ApexPages.currentPage().getParameters().put('id',mailerCon.Id);
        ApexPages.currentPage().getParameters().put('MailerType','Mass Email');
        test.startTest();
        emailPreview = new Eb_CntlEmailPreview();
        emailPreview.FetchEmailBody();
        test.stopTest();
        System.assertNotEquals(emailPreview.htmlBody, null);
    }

    static testMethod void Exception1_UnitTest() {
    	InitTextTemplate();
        mailer.Email_Template__c = null;
        update mailer;

    	PageReference ref = Page.EB_EmailPreview;  
        Test.setCurrentPageReference(ref);
        ApexPages.currentPage().getParameters().put('id',mailerCon.Id);
        ApexPages.currentPage().getParameters().put('MailerType','Mass Email');
        test.startTest();
    	emailPreview = new Eb_CntlEmailPreview();
        test.stopTest();

        ApexPages.Message[] pageMessages = ApexPages.getMessages();
		System.assertNotEquals(0, pageMessages.size());
    }

    static testMethod void Exception2_UnitTest() {
    	InitTextTemplate();

    	System.RunAs(usr){
	       	delete emailTemp;
	    }

    	PageReference ref = Page.EB_EmailPreview;  
        Test.setCurrentPageReference(ref);
        ApexPages.currentPage().getParameters().put('id',mailerCon.Id);
        ApexPages.currentPage().getParameters().put('MailerType','Mass Email');
        test.startTest();
    	emailPreview = new Eb_CntlEmailPreview();
    	emailPreview.FetchEmailBody();
        test.stopTest();

        ApexPages.Message[] pageMessages = ApexPages.getMessages();
		System.assertNotEquals(0, pageMessages.size());
    }
}