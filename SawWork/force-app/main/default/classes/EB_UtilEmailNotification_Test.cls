/*
 Author : Jayalakshmi A
 Description: Contains all test cases related to EB_UtilEmailNotification
 Modified: 1)on 9/3/2010 by janantha for changing the Mass mail functionality similar to single mails since the WhatId cannot be set to Contact Id in Mass mails for CR# 785433.
 2)9/21/2010- CR 794793,794802: Implementing code review findings- This class now uses a common class EB_InitializeObjects to initialize the prerequisites for test cases
 3)on 3/21/2011 by janantha for sending emails to all the Contacts belonging to a particular
   Mailer using action poller in order to avoid multiple clicks to the Send Emails button. CR#967107
 4)on 11/11/11 by janantha for Lighter Foot Print Mass Mails CR# 1383743
 5)on 28/08/2013 by ssawhney for validation on Issue start/end time and impacted product CR#2308403
 6)On 24/12/2013 by ssawhney to bulkify the test data creation to fix TOO Many SOQL error
 */
 
@isTest
private class EB_UtilEmailNotification_Test {
    static EB_AkaMAccount__c acc = new EB_AkaMAccount__c();    
    static EB_AkaMContact__c mailerContact1;
    
    static EB_AkaMContact__c mailerContact2;
    //Start of changes for CR#967107
    static EB_AkaMAccount__c accMass = new EB_AkaMAccount__c();
    static EB_AkaMContact__c mailerContact1Mass;
    static EB_AkaMContact__c mailerContact2Mass;
    static EB_AkaMContact__c mailerContact3Mass;
    //End of changes for CR#967107
    static EB_AkaMContact__c mailerContact3;
    static EB_AkaMContact__c mailerContact4;
    static EB_EmailTemplate__c testTemplate;
    static EB_AkaMailer__c mailer;
    static EB_AkaMailer__c massMailer;
    static Contact con1;
    static Contact con2;
    static Contact con3;
    static Account accOld;
    static Contact con4;
    static EB_AkaMAccount__c accWithoutContacts;
    static EB_AkaMailer__c mailerWithoutAccounts;
    static EB_AkaMAccount__c accWithAllContactsCcOrBcc;
    static EB_AkaMContact__c mailerContactCc;
    static EB_AkaMContact__c InvalidmailerContact; 
    static EB_AkaMAccount__c InvalidmailerAccount;
    static EB_NotificationType__c templateType;
    static EB_NotificationType__c templateType1;
    static EmailTemplate et;
    static String organizationId;
    //Start of changes for CR#967107
    /*this variable gives the total number of contacts for a particular mailer. this needs to be initialized 
    in the init method.*/
    static Integer totalContacts;
    //End of changes for CR#967107
    
    /*
     Author : Jayalakshmi A
     Description: This method is used to initialise data for test method.
     Created On: 5/-/2010
     Modified:9/21/2010- CR 794793,794802: Implementing code review findings- This class now uses a common class EB_InitializeObjects to initialize the prerequisites for test cases
              28/08/2013 by ssawhney CR#2308403 for validation on Issue start/end time and impacted product 
    */
    static void Init()  
    {         
         ManagedPkgErrorClass.isFromManagedPackage=false;
     // create new Email template for testing purpose
         //CR 794793, 794802- calling the method in the common class(EB_InitializeObjects) for initializing email template
         //CR#2308403 ssawhney - added to bypass the mixed dml exception error
         User usr = [Select id from User where Id = :UserInfo.getUserId()];
 
         System.RunAs(usr)
         {
            et = EB_InitializeObjects.createEmailTemplate('New_Email_Template','text');
            Database.insert(et);
         }
         
        list<EB_NotificationType__c> lstTypes = new list<EB_NotificationType__c>();
        //create Email Template Types Single Email and Mass Email
        templateType=new EB_NotificationType__c();
        templateType.Name= 'Single Email';
        templateType.Folder_Name__c=' EB_CNSingleMail';
        lstTypes.add(templateType);

        templateType1=new EB_NotificationType__c();
        templateType1.Name= 'Mass Email';
        templateType1.Folder_Name__c=' EB_CNMassMail';
        lstTypes.add(templateType1);
        database.insert(lstTypes);

        //create email template fot testing purpose
        //CR 794793,794802- calling the method in the common class(EB_InitializeObjects) for initializing custom template
        testTemplate= EB_InitializeObjects.createCustomTemplate('EB_Mailer_NotifyFailed','text', et.Id);
        database.insert(testTemplate);

        //create a mailer
        list<EB_AkaMailer__c> lstmailer = new list<EB_AkaMailer__c>();
        mailer = EB_InitializeObjects.createMailer(testTemplate.Id,'Single Email');
        /*CR 1367210 change - to invoke chatter notification  method*/
        mailer.EB_ChatterNotification__c = true;
        lstmailer.add(mailer);
        
        massMailer = EB_InitializeObjects.createMailer(testTemplate.Id,'Mass Email');
        /*CR 1367210 change - to invoke chatter notification  method*/
        massMailer.EB_ChatterNotification__c = true;
        lstmailer.add(massMailer);
        Database.insert(lstmailer);

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
        Database.insert(lstContact);    

        //create a mailer account
        list<EB_AkaMAccount__c> lstMailerAcc = new list<EB_AkaMAccount__c>();
        acc = EB_InitializeObjects.createMailerAccount(testTemplate.Id, mailer.Id, accOld.Id);
        lstMailerAcc.add(acc);
        
        accMass = EB_InitializeObjects.createMailerAccount(testTemplate.Id, massMailer.Id, accOld.Id);
        lstMailerAcc.add(accMass);
        Database.insert(lstMailerAcc);
        
        //create 5 mailer contacts
        list<EB_AkaMContact__c> lstMailerCon = new list<EB_AkaMContact__c>();
        mailerContact1 = EB_InitializeObjects.createMailerContact(testTemplate.Id, acc.Id, con1.Id);
        lstMailerCon.add(mailerContact1);
        
        mailerContact4 = EB_InitializeObjects.createMailerContact(testTemplate.Id, acc.Id, con1.Id);
        lstMailerCon.add(mailerContact4);  
        
        //Start of changes for CR#967107
        mailerContact1Mass = EB_InitializeObjects.createMailerContact(testTemplate.Id, accMass.Id, con1.Id);
        mailerContact1Mass.EB_IsBCC__c=true;
        //Start of changes for CR# 1383743 by janantha for Lighter Foot Print Mass Mails 
        mailerContact1Mass.EB_ToList__c = 'janantha@akamai.com;shandatt@akamai.com';
        //End of changes for CR# 1383743 by janantha for Lighter Foot Print Mass Mails
        lstMailerCon.add(mailerContact1Mass);  
              
        mailerContact2Mass = EB_InitializeObjects.createMailerContact(testTemplate.Id, accMass.Id, con1.Id);
        //Start of changes for CR# 1383743 by janantha for Lighter Foot Print Mass Mails 
        mailerContact2Mass.EB_ToList__c = 'janantha@akamai.com;shandatt@akamai.com';
        //End of changes for CR# 1383743 by janantha for Lighter Foot Print Mass Mails 
        lstMailerCon.add(mailerContact2Mass);
        
        mailerContact3Mass = EB_InitializeObjects.createMailerContact(testTemplate.Id, accMass.Id, con1.Id);
        //Start of changes for CR# 1383743 by janantha for Lighter Foot Print Mass Mails
        mailerContact3Mass.EB_ToList__c = 'janantha@akamai.com;shandatt@akamai.com';
        //End of changes for CR# 1383743 by janantha for Lighter Foot Print Mass Mails
        lstMailerCon.add(mailerContact3Mass);  
        //End of changes for CR#967107
        
        mailerContact2 = EB_InitializeObjects.createMailerContact(testTemplate.Id, acc.Id, con2.Id);
        mailerContact2.EB_IsBCC__c=true;
        lstMailerCon.add(mailerContact2);  

        mailerContact3 = EB_InitializeObjects.createMailerContact(testTemplate.Id, acc.Id, con3.Id);
        mailerContact3.EB_IsCC__c=true;
        lstMailerCon.add(mailerContact3); 
        Database.insert(lstMailerCon);
        //Start of changes for CR#967107
        totalContacts = 2;
        //End of changes for CR#967107
    }

    /*
     Author : Jayalakshmi A
     Description: This method is used to initialise negative data for test method.
     Created On: 5/-/2010
     Modified:9/21/2010- CR 794793,794802: Implementing code review findings- This class now uses a common class EB_InitializeObjects to initialize the prerequisites for test cases
              28/08/2013 by ssawhney CR#2308403 for validation on Issue start/end time and impacted product 
    */
    static void InitNegative1()  
    {
         ManagedPkgErrorClass.isFromManagedPackage=false;
     // create new Email template for testing purpose
         //CR 794793, 794802- calling the method in the common class(EB_InitializeObjects) for initializing custom template
        
        //CR#2308403 ssawhney - added to bypass the mixed dml exception error
         User usr = [Select id from User where Id = :UserInfo.getUserId()];
 
         System.RunAs(usr)
         {
            et = EB_InitializeObjects.createEmailTemplate('New_Email_Template','text');
            Database.insert(et);
         }
         //create email template fot testing purpose
        testTemplate= EB_InitializeObjects.createCustomTemplate('EB_Mailer_NotifyFailed','text', et.Id);
        database.insert(testTemplate);

        //create a mailer
        list <EB_AkaMailer__c> lstmailer = new list<EB_AkaMailer__c>();
        mailer = EB_InitializeObjects.createMailer(testTemplate.Id,'Single Email');
        lstmailer.add(mailer);

        mailerWithoutAccounts = EB_InitializeObjects.createMailer(testTemplate.Id,'Single Email');
        lstmailer.add(mailerWithoutAccounts);
        Database.insert(lstmailer);
        
        // create an account     
        accOld = EB_InitializeObjects.createAccount('TestAccount_01'); 
        Database.insert(accOld); 
        
        accWithoutContacts = EB_InitializeObjects.createMailerAccount(testTemplate.Id, mailer.Id, accOld.Id);
        Database.insert(accWithoutContacts);
    }
    
    /*
     Author : Jayalakshmi A
     Description: This method is a positive test case for sendMails method(Single email).
     Created On: 5/-/2010
    */
    static testMethod void sendMails_PositiveUnitTest()
    {
        Init();
        test.startTest();
        EBCS_Application__c Config = EBCS_Application__c.getInstance('UseOrgWideEmailAddress');
        Config.Value__c = 'TRUE';
        update Config;
        EBCS_Application__c displayName = EBCS_Application__c.getInstance('OrgWideEmailAddressName');
        displayName.Value__c = 'Akamai Customer Care';
        update displayName;
        EBCS_Application__c displayNameReplyTo = EBCS_Application__c.getInstance('OrgWideReplyToEmailAddressName');
        displayNameReplyTo.Value__c = 'ccare-replyTo';
        update displayNameReplyTo;                  
        EB_UtilEmailNotification.sendMails(mailer.Id);
        test.stopTest();
    }
    /*Start of changes for CR#967107 for using action poller to send mails to all the Contacts belonging 
    to a particular Mailer in order to avoid multiple clicks by the user.*/
    /*
     Author : Jayalakshmi A
     Description: This method is a positive test case for sendMails using Action Poller(Single email).CR#967107
     Created On: 23 March 2011
    */
    static testMethod void sendMailsActionPoller_PositiveUnitTest()
    {
        
        Init();
        test.startTest();
        EBCS_Application__c Config = EBCS_Application__c.getInstance('UseOrgWideEmailAddress');
        Config.Value__c = 'TRUE';
        update Config;
        EBCS_Application__c displayName = EBCS_Application__c.getInstance('OrgWideEmailAddressName');
        displayName.Value__c = 'Akamai Customer Care';
        update displayName;
        EBCS_Application__c displayNameReplyTo = EBCS_Application__c.getInstance('OrgWideReplyToEmailAddressName');
        displayNameReplyTo.Value__c = 'ccare-replyTo';
        update displayNameReplyTo;
        EBCS_Application__c singleMailBatchSize = EBCS_Application__c.getInstance('SingleMailsBatchSize');
        singleMailBatchSize.Value__c = String.ValueOf(1);
        update singleMailBatchSize;
        EBCS_UseActionPollerToSendMails__c useActionPoller = EBCS_UseActionPollerToSendMails__c.getInstance();
        useActionPoller.EB_UseActionPoller__c = 'True';
        upsert useActionPoller;         
        PageReference sendMailsActionPoller = Page.EB_VfpSendMailActionPoller;
        Test.setCurrentPageReference(sendMailsActionPoller);
        organizationId = [select Id from Organization limit 1 ][0].Id;
        sendMailsActionPoller.getParameters().put('id', mailer.Id);
        sendMailsActionPoller.getParameters().put('mailerType',mailer.EB_Type__c);
        sendMailsActionPoller.getParameters().put('totalContacts', String.ValueOf(totalContacts));
        sendMailsActionPoller.getParameters().put('OrganizationId', organizationId);
        mailer.EB_BatchStatus__c = 'EndOfBatch';
        mailer.EB_Operation__c = 'SendMails';
        update mailer;
        EB_UtilEmailNotification emailNotification = new EB_UtilEmailNotification(); 
        PageReference singleMails = emailNotification.sendEmailActionPoller();
        /* Start of CR 1367210 change - to invoke chatter notification  method*/
        mailer.EB_OperationStatus__c = 'End';
        update mailer;      
        singleMails = emailNotification.sendEmailActionPoller();
         /*End of CR 1367210 change - to invoke chatter notification  method*/ 
        
        //commented by ssawhney on 28/08/2013 to fix errors related to salesforce limit hits
        //Moved code to separate method
        /*mailer.EB_OperationStatus__c = 'Start';
        update mailer;       
        singleMails = emailNotification.sendEmailActionPoller();*/
        
        //PageReference singleMails1 = emailNotification.sendEmailActionPoller();
        emailNotification.getPendingBatchSize();
        emailNotification.getBatchSizeCustomSetting();
        emailNotification.getMailerRecord();
        emailNotification.getPendingContacts();
        emailNotification.getImage();  
         /*CR 1367210 change - to invoke chatter notification  method*/
        EB_CtrlChatterNotfication chatterNotification = new EB_CtrlChatterNotfication();
        PageReference chatterPage = Page.EB_VfpChatterNotification;
        Test.setCurrentPageReference(chatterPage);
        chatterPage.getParameters().put('id',mailer.Id);
        PageReference mailerPg = chatterNotification.redirectToMailer();
       /* con1.Email = '';
        update con1;
        singleMails = emailNotification.sendEmailActionPoller();*/
        test.stopTest();
    }
    
    /* This method was divided into two test cases due to hitting salesforce limits in one method
     Author : ssawhney
     Description: This method is a positive test case for sendMails using Action Poller(Single email).CR#967107
     Created On: 28 August 2013
    */
    static testMethod void sendMailsActionPoller_PositiveUnitTest1()
    {
        
        Init();
        test.startTest();
        EBCS_Application__c Config = EBCS_Application__c.getInstance('UseOrgWideEmailAddress');
        Config.Value__c = 'TRUE';
        update Config;
        EBCS_Application__c displayName = EBCS_Application__c.getInstance('OrgWideEmailAddressName');
        displayName.Value__c = 'Akamai Customer Care';
        update displayName;
        EBCS_Application__c displayNameReplyTo = EBCS_Application__c.getInstance('OrgWideReplyToEmailAddressName');
        displayNameReplyTo.Value__c = 'ccare-replyTo';
        update displayNameReplyTo;
        EBCS_Application__c singleMailBatchSize = EBCS_Application__c.getInstance('SingleMailsBatchSize');
        singleMailBatchSize.Value__c = String.ValueOf(1);
        update singleMailBatchSize;
        EBCS_UseActionPollerToSendMails__c useActionPoller = EBCS_UseActionPollerToSendMails__c.getInstance();
        useActionPoller.EB_UseActionPoller__c = 'True';
        upsert useActionPoller;         
        PageReference sendMailsActionPoller = Page.EB_VfpSendMailActionPoller;
        Test.setCurrentPageReference(sendMailsActionPoller);
        organizationId = [select Id from Organization limit 1 ][0].Id;
        sendMailsActionPoller.getParameters().put('id', mailer.Id);
        sendMailsActionPoller.getParameters().put('mailerType',mailer.EB_Type__c);
        sendMailsActionPoller.getParameters().put('totalContacts', String.ValueOf(totalContacts));
        sendMailsActionPoller.getParameters().put('OrganizationId', organizationId);
        mailer.EB_BatchStatus__c = 'EndOfBatch';
        mailer.EB_Operation__c = 'SendMails';
        update mailer;
        EB_UtilEmailNotification emailNotification = new EB_UtilEmailNotification();   
        mailer.EB_OperationStatus__c = 'Start';
        update mailer;   
        PageReference singleMails = emailNotification.sendEmailActionPoller();      
        singleMails = emailNotification.sendEmailActionPoller();
        test.stopTest();
    }
    
    /*
     Author : Jayalakshmi A
     Description: This method is a negative test case for sendMails using Action Poller(Single email).CR#967107
     Created On: 23 March 2011
    */
    static testMethod void sendMailsActionPoller_NegativeUnitTest2()
    {
        
        InitNegative1();   
        test.startTest();    
        EB_UtilEmailNotification.sendMailsActionPoller(mailer.Id);
        test.stopTest();
    }
        /*
         Author : Jayalakshmi A
         Description: This method is a positive test case for sendMassEmails method(Mass email).CR#967107
         Created On: March 23 2011
        */
        static testMethod void sendMassEmailsActionPoller_PositiveUnitTest()
        {
            
            Init();
            test.startTest();
            EBCS_Application__c Config = EBCS_Application__c.getInstance('UseOrgWideEmailAddress');
            Config.Value__c = 'TRUE';
            update Config;
            EBCS_Application__c displayName = EBCS_Application__c.getInstance('OrgWideEmailAddressName');
            displayName.Value__c = 'Akamai Customer Care';
            update displayName;
            EBCS_Application__c displayNameReplyTo = EBCS_Application__c.getInstance('OrgWideReplyToEmailAddressName');
            displayNameReplyTo.Value__c = 'ccare-replyTo';
            update displayNameReplyTo;
            
            EBCS_UseActionPollerToSendMails__c useActionPoller = EBCS_UseActionPollerToSendMails__c.getInstance();
            useActionPoller.EB_UseActionPoller__c = 'True';
            upsert useActionPoller;
            EBCS_Application__c massMailBatchSize = EBCS_Application__c.getInstance('MassMailsBatchSize');
            massMailBatchSize.Value__c = String.ValueOf(1);
            update massMailBatchSize;
                             
            PageReference sendMailsActionPollerMassMails = Page.EB_VfpSendMailActionPoller;
            Test.setCurrentPageReference(sendMailsActionPollerMassMails);
            organizationId = [select Id from Organization limit 1 ][0].Id;
            sendMailsActionPollerMassMails.getParameters().put('id', massMailer.Id);
            sendMailsActionPollerMassMails.getParameters().put('mailerType',massMailer.EB_Type__c);
            sendMailsActionPollerMassMails.getParameters().put('totalContacts', String.ValueOf(totalContacts));
            sendMailsActionPollerMassMails.getParameters().put('OrganizationId', organizationId);
            massMailer.EB_BatchStatus__c = 'EndOfBatch';
            massMailer.EB_Operation__c = 'SendMassMails';
            update massMailer;
            EB_UtilEmailNotification emailNotification = new EB_UtilEmailNotification(); 
            PageReference massMails = emailNotification.sendEmailActionPoller();  
            /* Start of CR 1367210 change - to invoke chatter notification  method*/
          massMailer.EB_OperationStatus__c = 'End';
          update massMailer;      
          massMails = emailNotification.sendEmailActionPoller();
            EB_CtrlChatterNotfication chatterNotification = new EB_CtrlChatterNotfication();
            PageReference chatterPage = Page.EB_VfpChatterNotification;
          Test.setCurrentPageReference(chatterPage);
          chatterPage.getParameters().put('id',massMailer.Id);
            PageReference mailerPg = chatterNotification.redirectToMailer();
            /*End of CR 1367210 change - to invoke chatter notification  method*/ 
            test.stopTest();
        }
        /*End of changes for CR#967107 for using action poller to send mails to all the Contacts belonging 
          to a particular Mailer in order to avoid multiple clicks by the user.*/
        static testMethod void sendMassEmails_PositiveUnitTest()
        {
            
            Init();
            test.startTest();
            EBCS_Application__c Config = EBCS_Application__c.getInstance('UseOrgWideEmailAddress');
            Config.Value__c = 'TRUE';
            update Config;
            EBCS_Application__c displayName = EBCS_Application__c.getInstance('OrgWideEmailAddressName');
            displayName.Value__c = 'Akamai Customer Care';
            update displayName;
            EBCS_Application__c displayNameReplyTo = EBCS_Application__c.getInstance('OrgWideReplyToEmailAddressName');
            displayNameReplyTo.Value__c = 'ccare-replyTo';
            update displayNameReplyTo;   
            //Start of changes for CR# 1383743 by janantha for Lighter Foot Print Mass Mails        
            EB_UtilEmailNotification.sendMassEmails(massMailer.Id);
            //End of changes for CR# 1383743 by janantha for Lighter Foot Print Mass Mails
            test.stopTest();
        }
//end of changes on 9/3/2010 by janantha for changing the Mass mail functionality similar to single mails since the WhatId cannot be set to Contact Id in Mass mails for CR# 785433.

        /*
         Author : Jayalakshmi A
         Description: This method is a positive test case for sendMailToContact method, this method sends an email to a single contact.
         Created On: 5/-/2010
        */
        static testMethod void sendMailToContact_PositiveUnitTest()
        {
            Init();    
            test.startTest();       
            String strContactId = con1.Id;
            EB_UtilEmailNotification.sendMailToContact(strContactId, 'EB_Mailer_NotifyFailed', mailerContact1.Id);
            test.stopTest();
        }
        
        
        
    /* 
     Author : ssawhney
     Description: This method contains test cases for CR#2308403 to check for errors if mailer details are not valid
     Created On: 28 August 2013
    */
    static testMethod void validateMailerDetails_MassEmail()
    {
        
        Init();
        test.startTest();        
 
        mailer.EB_IssueEndDateTime__c = null;
        mailer.EB_IssueStartDateTime__c = null; 
        mailer.EB_ImpactedAkamaiProduct__c = null;
        update mailer; 
        string error = EB_UtilEmailNotification.validateDataForSendEmail(mailer.Id)  ;
        
        massMailer.EB_IssueEndDateTime__c = null;
        massMailer.EB_IssueStartDateTime__c = null; 
        massMailer.EB_ImpactedAkamaiProduct__c = null;
        update massMailer;
        error = EB_UtilEmailNotification.validateDataForSendEmail(massMailer.Id)  ;

        test.stopTest();
    }
}