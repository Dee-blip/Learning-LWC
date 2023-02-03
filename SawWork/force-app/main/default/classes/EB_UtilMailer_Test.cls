/*
 Authors: Jayalakshmi A & Sharath K
 Description: Contains test cases for UtilMailer class
 9/21/2010- CR 794793: Implementing code review findings- This class now uses a common class EB_InitializeObjects to initialize the prerequisites for test cases
 on 3/21/2011 by janantha for updating templates at all the Mailer Accounts and Mailer Contacts belonging to a particular
 Mailer using action poller in order to avoid multiple clicks to the Update Templates button. CR#967107
 Modified on 24/12/2013 by ssawhney to fix Too many soql Error
 */
 
@isTest
private class EB_UtilMailer_Test {
    
    static EB_AkaMAccount__c acc;  
    static EB_AkaMAccount__c acc1;
    static EB_AkaMAccount__c acc2;
    static EB_AkaMAccount__c acc3;
    static EB_AkaMContact__c mailerContact1;
    static EB_AkaMContact__c mailerContact2;
    static EB_AkaMContact__c mailerContact3;
    static EB_AkaMContact__c mailerContact4;
    static EB_AkaMContact__c mailerContact5;
    static EB_EmailTemplate__c testTemplate;
    static EB_EmailTemplate__c testTemplate2;
    static EB_AkaMailer__c mailer;
    static EB_AkaMailer__c mailer1;
    static EB_AkaMailer__c mailer2;
    static Contact con1;
    static Contact con2;
    static Contact con3;
    static Account accOld;
    static List<String> accountIds = new List<String>();
    static List<EB_AkaMContact__c> exceptionContactList = new List<EB_AkaMContact__c>();
    static EB_NotificationType__c templateType;
    static EB_NotificationType__c templateType1;            
    static EmailTemplate et;
    static EmailTemplate et1;
    static String result1;
    //Start of changes for CR#967107
    /*this variable gives the total number of contacts for a particular mailer. this needs to be initialized 
    in the init method.*/
    static Integer totalContacts;
    //End of changes for CR#967107
    static EB_UtilMailer utilMailer = new EB_UtilMailer();
    
    /*
     Author : Jayalakshmi A, Sharath K
     Description: This method initialises data.
     Created On: 6/-/2010
    */
    static testMethod void Init()  
    { 
        ManagedPkgErrorClass.isFromManagedPackage=false;
       // create new Email template for testing purpose
        //CR 794793- calling the method in the common class(EB_InitializeObjects) for initializing email template
        User usr = [Select id from User where Id = :UserInfo.getUserId()];
 
        System.RunAs(usr)
        {
            list<EmailTemplate> lstTemplate = new list<EmailTemplate>();
            et = EB_InitializeObjects.createEmailTemplate('New_Email_Template','text');
            lstTemplate.add(et);
            
            et1 = EB_InitializeObjects.createEmailTemplate('New_Email_Template_2','text');
            lstTemplate.add(et1);
            Database.insert(lstTemplate);
        }
        
        //create Email Template Types Single Email and Mass Email
        list <EB_NotificationType__c> lstNotify = new list<EB_NotificationType__c>();
        templateType=new EB_NotificationType__c();
        templateType.Name= 'Single Email';
        templateType.Folder_Name__c=' EB_CNSingleMail';
        lstNotify.add(templateType);

        templateType1=new EB_NotificationType__c();
        templateType1.Name= 'Mass Email';
        templateType1.Folder_Name__c=' EB_CNMassMail';
        lstNotify.add(templateType1);
        database.insert(lstNotify);

        //create email template fot testing purpose
        //CR 794793- calling the method in the common class(EB_InitializeObjects) for initializing custom template
        list<EB_EmailTemplate__c> lstEmailTemplates = new list<EB_EmailTemplate__c>();
        testTemplate= EB_InitializeObjects.createCustomTemplate('template 1','text', et.Id);
        lstEmailTemplates.add(testTemplate);
        
        //CR 794793- calling the method in the common class(EB_InitializeObjects) for initializing custom template
        testTemplate2= EB_InitializeObjects.createCustomTemplate('New_Email_Template_2','text', et1.Id);
        lstEmailTemplates.add(testTemplate2);
        database.insert(lstEmailTemplates);

        //create a mailer
        list<EB_AkaMailer__c> lstMailer = new list<EB_AkaMailer__c>();
        mailer = EB_InitializeObjects.createMailer(testTemplate.Id,'Single Email');
        lstMailer.add(mailer);
        
        mailer1 = EB_InitializeObjects.createMailer(testTemplate.Id,'Single Email');
        lstMailer.add(mailer1);
        
        mailer2 = EB_InitializeObjects.createMailer(testTemplate.Id,'Single Email');
        lstMailer.add(mailer2);
        Database.insert(lstMailer);
        
        // create an account     
        accOld = EB_InitializeObjects.createAccount('TestAccount_01'); 
        Database.insert(accOld); 

        // Create contacts
        list<Contact> lstContact = new list<Contact>();
        con1 = EB_InitializeObjects.createContact('Fname','Lname',accOld.Id);
        lstContact.add(con1); 

        con2 = EB_InitializeObjects.createContact('Fname_1','Lname_1',accOld.Id);
        lstContact.add(con2);

        con3 = EB_InitializeObjects.createContact('Fname_2','Lname_3',accOld.Id);
        lstContact.add(con3);   
        database.insert(lstContact);

        //create a mailer account
        list<EB_AkaMAccount__c> lstMailerAcc = new list<EB_AkaMAccount__c>();
        acc = EB_InitializeObjects.createMailerAccount(testTemplate.Id, mailer.Id, accOld.Id);
        lstMailerAcc.add(acc);
        
        acc2 = EB_InitializeObjects.createMailerAccount(testTemplate.Id, mailer1.Id, accOld.Id);
        lstMailerAcc.add(acc2);
        
        acc3 = EB_InitializeObjects.createMailerAccount(testTemplate.Id, mailer2.Id, accOld.Id);
        lstMailerAcc.add(acc3);
        database.insert(lstMailerAcc);

        //create 3 mailer contacts
        list<EB_AkaMContact__c> lstMailerCon = new list<EB_AkaMContact__c>();
        mailerContact1 = EB_InitializeObjects.createMailerContact(testTemplate.Id, acc.Id, con1.Id);
        lstMailerCon.add(mailerContact1);  

        mailerContact2 = EB_InitializeObjects.createMailerContact(testTemplate.Id, acc.Id, con2.Id);
        lstMailerCon.add(mailerContact2);  

        mailerContact3 = EB_InitializeObjects.createMailerContact(testTemplate.Id, acc.Id, con3.Id);
        lstMailerCon.add(mailerContact3);  
        
        mailerContact4 = EB_InitializeObjects.createMailerContact(testTemplate.Id, acc2.Id, con3.Id);
        mailerContact4.EB_Status__c = 'Failed';
        lstMailerCon.add(mailerContact4); 
        
        mailerContact5 = EB_InitializeObjects.createMailerContact(testTemplate.Id, acc3.Id, con3.Id);
        mailerContact5.EB_Status__c = 'Processed';
        lstMailerCon.add(mailerContact5);
        Database.insert(lstMailerCon);  
        
        lstMailerAcc = new list<EB_AkaMAccount__c>();
        acc2.EB_Status__c = 'Failed';
        lstMailerAcc.add(acc2);
        
        acc3.EB_Status__c = 'Processed';
        lstMailerAcc.add(acc3);
        update lstMailerAcc;
        
        lstMailer = new list<EB_AkaMailer__c>();
        mailer1.EB_Status__c = 'Failed';
        lstMailer.add(mailer1);
        
        mailer2.EB_Status__c = 'Processed';
        lstMailer.add(mailer2);
        update lstMailer;       
                
        //Start of changes for CR#967107
        totalContacts = 5;
        //End of changes for CR#967107
    }
    
    /*
    static testMethod void InitNegative()  
    {
        Init();
        con4 = new Contact();
        con4.FirstName = '__ Test First';
        con4.LastName = '__Test Contact';
        con4.AccountId = accOld.Id;
        con4.Akamai_Vertical__c = 'Gaming';
        con4.Sub_Vertical__c = 'G - Console Mfs';
        con4.Phone = '99999';
        con4.Email = 'janantha123@akamai.com';
        con4.Title = 'Tester';   
        con4.MailingCountry = 'India';
        Database.insert(con4); 
    }
    */
    
    static testMethod void getUrl_unittest(){
        String url=EB_UtilMailer.getUrl();
    }
    /*
     Author : Sharath K
     Description: This method is a positive test case for update templates at the Mailer Account level.
     Created On: 6/-/2010
    */
    static testMethod void UpdateTemplate_PositiveUnitTest()     
    {    
        Init();
        Test.startTest();    
        EB_UtilMailer.update_template('New_Email_Template_2',acc.Id);        
        /* Switch back to Test */             
        EB_AkaMContact__c mailerCon = [select Id,Email_Template__c from EB_AkaMContact__c where EB_AkaMContact__c.EB_AkaMAccount__r.Id=:acc.Id limit 1];        
        // Test the updates        
        system.assertNotEquals(mailerCon.Email_Template__c,null );        
        Test.stopTest();               
    }
    /*
     Author : Sharath K
     Description: This method is a negative test case for update templates at the Mailer Account level.
     Created On: 6/-/2010
    */
    static testMethod void UpdateTemplate_NegativeUnitTest()     
    {    
        Init();
        Test.startTest();
        String validAccountId = acc.Id;
        // supply invalid template name - throws out List exception
        EB_UtilMailer.update_template('templateName6876',validAccountId);            
        Test.stopTest();
    }
    
    /*
     Author : Jayalakshmi A
     Description: This method is a positive test case for update templates at the Mailer level.
     Created On: 6/-/2010
    */
    static testMethod void updateTemplateMailer_PositiveUnitTest() 
    {
        Init();
        test.startTest();
        result1 = EB_UtilMailer.updateTemplate(mailer.Id,'New_Email_Template_2');
        result1 = EB_UtilMailer.updateTemplate(mailer.Id,'New_Email_Template_2');
        test.stopTest();
    }
    /*Start of changes for CR#967107 for using action poller to update templates at the Mailer accounts and
    Mailer contacts in order to avoid multiple clicks by the user.*/
    /*
     Author : Jayalakshmi A
     Description: This method is a positive test case for update templates using Action Poller at the Mailer level.
     Created On: March 23 2011
    */
    static testMethod void updateTemplateMailerActionPoller_PositiveUnitTest() 
    {
        Init();
        test.startTest();
        EBCS_UseActionPollerToSendMails__c useActionPoller = EBCS_UseActionPollerToSendMails__c.getInstance();
        useActionPoller.EB_UseActionPollerUpdateTemplates__c = 'True';
        update useActionPoller; 
        PageReference updateTemplatesActionPoller = Page.EB_VfpUpdateTemplateActionPoller;
        Test.setCurrentPageReference(updateTemplatesActionPoller);
        String organizationId = [select Id from Organization limit 1 ][0].Id;
        updateTemplatesActionPoller.getParameters().put('OrganizationId', organizationId);
        updateTemplatesActionPoller.getParameters().put('TotalContacts', String.ValueOf(totalContacts));
        String templateId = testTemplate2.Id;
        updateTemplatesActionPoller.getParameters().put('TemplateId', templateId);
        updateTemplatesActionPoller.getParameters().put('id', mailer.Id);
        EB_UtilMailer updateActionPoller = new EB_UtilMailer();
        PageReference pg = updateActionPoller.updateTemplateActionPoller();
        updateActionPoller.getProcessedContacts();
        updateActionPoller.getPendingContacts();
        updateActionPoller.getPendingBatchSize();
        updateActionPoller.getBatchSizeCustomSetting();
        updateActionPoller.getMailerRecord();
        updateActionPoller.getImage();
        updateActionPoller.getMailerLink();
        updateActionPoller.getRenderMailerLink();
        updateActionPoller.getRenderWarningText();
        updateActionPoller.getStatusMessage();
        result1 = EB_UtilMailer.updateTemplateActionPoller(mailer.Id,'New_Email_Template_2');
       // result1 = EB_UtilMailer.updateTemplateActionPoller(mailer.Id,'New_Email_Template_2');
        test.stopTest();
    }
    /*End of changes for CR#967107 for using action poller to update templates at the Mailer accounts and
    Mailer contacts in order to avoid multiple clicks by the user.*/
       
    /*
     Author : Jayalakshmi A
     Description: This method is a negative test case for update templates at the Mailer level.
     Created On: 6/-/2010
    */
    static testMethod void updateTemplateMailer_NegativeUnitTest() 
    {
        Init();
        // supply invalid template name - throws out List exception
        result1 = EB_UtilMailer.updateTemplate(mailer.Id,'templateName1234');
    }
    /*
     Author : Jayalakshmi A
     Description: This method is a positive test case for deep clone at the Mailer level.
     Created On: 7/-/2010
    */
   static testMethod void deepclone_PositiveUnitTest() {
        Init();
        test.startTest();
         //Start of chnages by MSHARDUL CR-1799662
        PageReference pageRef = new PageReference('/apex/EB_VfpMailerClone?mailer_Id='+mailer2.Id+'&cloneType=deepClone');
        utilMailer.strMailerId = mailer2.Id;
        //utilMailer.cloneType = 'deepClone';
        
        utilMailer.deepClone();
        utilMailer.getNewtoken();
        //Test.setCurrentPage(pageRef);
         //End of chnages by MSHARDUL CR-1799662
        
        test.stopTest();
    }
    /*
     Author : Jayalakshmi A
     Description: This method is a negative test case for deep clone at the Mailer level.
     Created On: 7/-/2010
    */
    static testMethod void deepclone_NegativeUnitTest1() {
        Init();
        String invalidMailerId = mailer.Id+'-1';
        test.startTest();      
         //Start of chnages by MSHARDUL CR-1799662
        PageReference pageRef = new PageReference('/apex/EB_VfpMailerClone?mailer_Id='+mailer1.Id+'1'+'&cloneType=deepClone');
        utilMailer.strMailerId = mailer1.Id;
        //utilMailer.cloneType = 'deepClone';
        //Test.setCurrentPage(pageRef);
        //End of chnages by MSHARDUL CR-1799662
        test.stopTest();
    } 
    /*
     Author : Jayalakshmi A
     Description: This method is a negative test case for deep clone at the Mailer level.
     Created On: 7/-/2010
    */
    static testMethod void deepclone_NegativeUnitTest2() {
        Init();
        test.startTest();
    // supply ivalid template Name - throws List Exception
       //Start of chnages by MSHARDUL CR-1799662
        PageReference pageRef = new PageReference('/apex/EB_VfpMailerClone?mailer_Id='+mailer1.Id+'&cloneType=deepClone');
        utilMailer.strMailerId = mailer1.Id;
        //utilMailer.cloneType = 'deepClone';
        //Test.setCurrentPage(pageRef);
         //End of chnages by MSHARDUL CR-1799662
       test.stopTest();
}
    /*
     Author : Jayalakshmi A
     Description: This method is a positive test case for cloning Failed contact records at the Mailer level.
     Created On: 9/27/2010
    */
    static testMethod void cloneFailedRecords_PositiveUnitTest() {
        Init();
       // String MailerId = mailer1.Id;
        test.startTest();       
         //Start of chnages by MSHARDUL CR-1799662
       PageReference pageRef = new PageReference('/apex/EB_VfpMailerClone?mailer_Id='+mailer1.Id+'&cloneType=cloneFailedRecords');
       utilMailer.strMailerId = mailer1.Id;
       utilMailer.cloneType = 'cloneFailedRecords';
       utilMailer.CloneFailedRecords();
       //Test.setCurrentPage(pageRef);
         //End of chnages by MSHARDUL CR-1799662
        test.stopTest();
    }
    /*
     Author : Jayalakshmi A
     Description: This method is a positive test case for cloning Processed contact records at the Mailer level.
     Created On: 9/27/2010
    */
    static testMethod void cloneProcessedRecords_PositiveUnitTest() {
        Init();
        //String MailerId = mailer2.Id;
        test.startTest();
       //Start of chnages by MSHARDUL CR-1799662
       PageReference pageRef = new PageReference('/apex/EB_VfpMailerClone?mailer_Id='+mailer2.Id+'&cloneType=cloneProcessedRecords');
       utilMailer.strMailerId = mailer2.Id;
       utilMailer.cloneType = 'cloneProcessedRecords';
       //Test.setCurrentPage(pageRef);
       utilMailer.CloneProcessedRecords();
         //End of chnages by MSHARDUL CR-1799662
        test.stopTest();
    }  
    /*
     Author : Jayalakshmi A
     Description: This method is a positive test case for getting preview url at the Mailer level.
     Created On: 7/-/2010
    */
    static testMethod void preview_PositiveUnitTest(){
        test.startTest();
        Init();
        List<String> result = new List<String>();
        List<String> akamContactIds= new List<String>();
        akamContactIds.add(mailerContact1.Id);
        akamContactIds.add(mailerContact2.Id);
        akamContactIds.add(mailerContact3.Id);
        String contactId = con1.Id;
        result = EB_UtilMailer.getPreviewURL(contactId , testTemplate.Id,akamContactIds);
        test.stopTest();
    } 
    /*
     Author : Jayalakshmi A
     Description: This method is a negative test case for getting preview url at the Mailer level.
     Created On: 7/-/2010
    */
    static testMethod void preview_NegativeUnitTest(){
        test.startTest();
        Init();
        List<String> result = new List<String>();
        List<String> akamContactIds= new List<String>();
        akamContactIds.add('-1');
        akamContactIds.add('-1sanvd');
        akamContactIds.add('-1abcd');
        String contactId = con1.Id;
        result = EB_UtilMailer.getPreviewURL(contactId , testTemplate.Id,akamContactIds);
        test.stopTest();
    } 
    /*
     Author : Sharath K
     Description: This method is a negative test case for getting preview url at the Mailer level.
     Created On: 7/-/2010
    */
    static testMethod void ReportTest(){
        test.startTest();
        Init();
        String retval;
        String m;
        retval=EB_UtilMailer.parameter_report( mailer.Name, 'Mailer Exception Report');
        System.assertNotEquals(retval,null);
        retval=EB_UtilMailer.parameter_report( mailer.Name, 'Email Bounce Report');
        System.assertNotEquals(retval,null);
        retval=EB_UtilMailer.parameter_report( mailer.Name, 'Mailer Warning Report');
        System.assertNotEquals(retval,null);
        test.stopTest();
    } 
    
    static testMethod void refresh_email_templates(){
        String retUrl;
        test.startTest();
        retUrl = EB_UtilMailer.refresh_email_templates();
        test.stopTest();
        System.assertNotEquals(retUrl,null);
        
    }
    
    static testMethod void testCloneRenderBoolFuncs(){
        ManagedPkgErrorClass.isFromManagedPackage=false;
        test.startTest();
        utilMailer.cloneType = 'deepClone';
        utilMailer.getRenderdeepClone();
        utilMailer.cloneType = 'test';
        utilMailer.getRenderdeepClone();
        utilMailer.cloneType = 'cloneProcessedRecords';
        utilMailer.getRendercloneProcessedRecords();
        utilMailer.cloneType = 'test';
        utilMailer.getRendercloneProcessedRecords();
        utilMailer.cloneType = 'cloneFailedRecords';
        utilMailer.getRendercloneFailedRecords();
        utilMailer.cloneType = 'test';
        utilMailer.getRendercloneFailedRecords();   
    }
}