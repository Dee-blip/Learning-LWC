/**
    Momentum Email Handler Test Class
    @version 1.0
    @author : Vinayendra T N <vinatara@akamai.com>
    @Description : This class implements the unit tests for MomentumHandlerClass and EmailtoCase Class.
                   Use cases that are tested :   
                   1. Case Creation using email with Attachements.
                   2. Case Creation using email with long length body without Attachements.
                   3. Task to Case Creation using email with Attachements.
                   4. Task to Case Creation using email with long length body without Attachements.
                                   
*/
//CR 2770464 - rsharma: adding SeeAllData = true to make this class to pass, also changed api version to 23.0
@isTest(seeAllData=false)
private class MomentumEmailHandlerTest {
//private static Email_to_Case__c CustomSettings = Email_to_Case__c.getInstance('Momentum');
  //static String CaseRecord=CustomSettings.CaseRecord__c;
    /*private static Contact CreateContact(String FirstName,String LastName,String conemail)
    {
        Contact con = new Contact();
        con.FirstName = FirstName;
        con.LastName = LastName;
        con.Akamai_Vertical__c = 'Gaming';
        con.Sub_Vertical__c = 'Console Mfs';
        con.Phone = '99999';
        con.Email = conemail;
        con.Title = 'Tester';   
        con.MailingCountry = 'India';
        con.AKAM_Contact_ID__c = 'ABC123';
        return con;
    }
    private static Account CreateAccount(String pAccName)
    {
        Account accOld = new Account();
        accOld.Name = pAccName;
        accOld.BillingCountry = 'India';
        //Start Modified By Chandra For CR 693820
        accOld.Vertical__c = 'Gaming';
        //End Modified By Chandra For CR 693820
        accOld.Sub_Vertical__c = 'Console Mfs';         
        return accOld;
    }*/
    
    static testmethod void MomentumRunFirst()
    {
      CaseCreation(new MomentumEmailHandler(),Email_to_Case__c.getInstance('Momentum'));
    }
    static testmethod void MomentumRunFirst2()
    { 
      MomentumCaseCreationNagative(new MomentumEmailHandler(),Email_to_Case__c.getInstance('Momentum'));
    }
    static testmethod void MomentumRunFirst3()
    {
      MomentumTaskToCaseCreation(new MomentumEmailHandler(),Email_to_Case__c.getInstance('Momentum'));
    }
    static testmethod void MomentumRunFirst4()
    {
      MomentumTaskToCaseCreationNegative(new MomentumEmailHandler(),Email_to_Case__c.getInstance('Momentum'));
    }
    static testmethod void MomentumRunFirst5()
    {
      MomentumTaskToCaseCreation2(new MomentumEmailHandler(),Email_to_Case__c.getInstance('Momentum'));
    }
    static testmethod void ProdMgmtRunFirst()
    {
      CaseCreation(new ProdMgmtEmailHandler(),Email_to_Case__c.getInstance('ProdMgmt'));
    }
    static testmethod void ProdMgmtRunFirst2()
    { 
      MomentumCaseCreationNagative(new ProdMgmtEmailHandler(),Email_to_Case__c.getInstance('ProdMgmt'));
    }
    static testmethod void ProdMgmtRunFirst3()
    {
      MomentumTaskToCaseCreation(new ProdMgmtEmailHandler(),Email_to_Case__c.getInstance('ProdMgmt'));
    }
    static testmethod void ProdMgmtRunFirst4()
    {
      MomentumTaskToCaseCreationNegative(new ProdMgmtEmailHandler(),Email_to_Case__c.getInstance('ProdMgmt'));
    }
    static testmethod void ProdMgmtRunFirst5()
    {
      MomentumTaskToCaseCreation2(new ProdMgmtEmailHandler(),Email_to_Case__c.getInstance('ProdMgmt'));
    }
    static testmethod void PartnerPortalRunFirst()
    {
      CaseCreation(new E2CPartnerPortalEmailHandler(),Email_to_Case__c.getInstance('PartnerPortal'));
    }
    static testmethod void PartnerPortalRunFirst2()
    { 
      MomentumCaseCreationNagative(new E2CPartnerPortalEmailHandler(),Email_to_Case__c.getInstance('PartnerPortal'));
    }
    static testmethod void PartnerPortalRunFirst3()
    {
      MomentumTaskToCaseCreation(new E2CPartnerPortalEmailHandler(),Email_to_Case__c.getInstance('PartnerPortal'));
    }
    static testmethod void PartnerPortalRunFirst4()
    {
      MomentumTaskToCaseCreationNegative(new E2CPartnerPortalEmailHandler(),Email_to_Case__c.getInstance('PartnerPortal'));
    }
    static testmethod void PartnerPortalRunFirst5()
    {
      MomentumTaskToCaseCreation2(new E2CPartnerPortalEmailHandler(),Email_to_Case__c.getInstance('PartnerPortal'));
    }
    static testmethod void E2CIntlBusDevRunFirst()
    {
      CaseCreation(new E2CIntlBusDev(),Email_to_Case__c.getInstance('E2CIntlBusDev'));
    }
    static testmethod void E2CIntlBusDevRunFirst2()
    { 
      MomentumCaseCreationNagative(new E2CIntlBusDev(),Email_to_Case__c.getInstance('E2CIntlBusDev'));
    }
    static testmethod void E2CIntlBusDevRunFirst3()
    {
      MomentumTaskToCaseCreation(new E2CIntlBusDev(),Email_to_Case__c.getInstance('E2CIntlBusDev'));
    }
    static testmethod void E2CIntlBusDevRunFirst4()
    {
      MomentumTaskToCaseCreationNegative(new E2CIntlBusDev(),Email_to_Case__c.getInstance('E2CIntlBusDev'));
    }
    static testmethod void E2CIntlBusDevRunFirst5()
    {
      MomentumTaskToCaseCreation2(new E2CIntlBusDev(),Email_to_Case__c.getInstance('E2CIntlBusDev'));
    }
    static void CaseCreation(Object emailProcess,Email_to_Case__c CustomSettings) {
  ManagedPkgErrorClass.isFromManagedPackage = false;
      // create a new email and envelope object
      Messaging.InboundEmail email = new Messaging.InboundEmail() ;
      Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
     
      // setup the data for the email
      email.subject = 'Creating a test case in test class1';
      //email.bodytext = 'Creating a test case in test class';
      email.fromname = 'FirstName LastName';
      email.fromAddress = 'someaddress1@akamai.com';
      //Account acc = CreateAccount('__Test Old Account1');
      Account acc = utilTestClass.CreateAccount('__ Test Old Account1');
      acc.Vertical__c = 'Gaming';
      acc.Sub_Vertical__c = 'Console Mfs';        
      insert acc;
      Contact con= utilTestClass.CreateContact('__First1','__last1');
      con.Email = 'someaddress1@akamai.com';
      con.AKAM_Contact_ID__c = 'ABC123';
      con.AccountId=acc.id;
      insert con;
       email.plainTextBody= null;
       email.htmlbody= '01234567889';
      // add an attachment
      Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
      attachment.body = blob.valueOf('my attachment text');
      attachment.fileName = 'textfile.txt';
      attachment.mimeTypeSubType = 'text/plain';
     
      email.binaryAttachments =
        new Messaging.inboundEmail.BinaryAttachment[] { attachment };
      Messaging.InboundEmail.TextAttachment attachment2 = new Messaging.InboundEmail.TextAttachment();
      attachment2.body = 'my attachment text';
      attachment2.fileName = 'textfile.txt';
      attachment2.mimeTypeSubType = 'text/plain';

      email.TextAttachments =
        new Messaging.inboundEmail.TextAttachment[] { attachment2 };
      // call the email service class and test it with the data in the testMethod
      
      if (emailProcess instanceof MomentumEmailHandler)
      {
        MomentumEmailHandler emailProcessCast = (MomentumEmailHandler) emailProcess;
        emailProcessCast.handleInboundEmail(email, env);
      }
      else if (emailProcess instanceof ProdMgmtEmailHandler)
      {
        ProdMgmtEmailHandler emailProcessCast = (ProdMgmtEmailHandler) emailProcess;
        emailProcessCast.handleInboundEmail(email, env);
      }
      else if (emailProcess instanceof E2CPartnerPortalEmailHandler)
      {
        E2CPartnerPortalEmailHandler emailProcessCast = (E2CPartnerPortalEmailHandler) emailProcess;
        emailProcessCast.handleInboundEmail(email, env);
      }
      else if (emailProcess instanceof E2CIntlBusDev)
      {
        E2CIntlBusDev emailProcessCast = (E2CIntlBusDev) emailProcess;
        emailProcessCast.handleInboundEmail(email, env);
      }
      
     
      // query for the contact the email service created
      Case testc = [Select case.id,case.CaseNumber,case.ContactId,case.Associated_Email__c,case.Email_to_case__c from Case where case.Subject = 'Creating a test case in test class1'];
      
      System.assertEquals(testc.Associated_Email__c, 'someaddress1@akamai.com');
      System.assertEquals(testc.ContactId, con.id);
      System.assert(testc.Email_to_case__c);
      
     
     
      // find the attachment
      //Attachment a = [select name from attachment where parentId = :testc.id];
     
      //System.assertEquals(a.name,'textfile.txt');
     
    }
    static void MomentumCaseCreationNagative(Object emailProcess,Email_to_Case__c CustomSettings) {
  ManagedPkgErrorClass.isFromManagedPackage = false;
      // create a new email and envelope object
      Messaging.InboundEmail email = new Messaging.InboundEmail() ;
      Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
     
      // setup the data for the email
      email.subject = 'Creating a test case in test class2';
      email.plainTextBody= '1234567889';
      for(integer i=0;i<3205;i++)
      email.plainTextBody= email.plainTextBody+'01234567889';
     
      email.fromname = 'FirstName LastName';
      email.fromAddress = 'someotheraddress2@akamai.com';
      email.toAddresses = new String[] {'testingnewaddress@akamai.com' };
      email.ccAddresses = new String[] {'Vinay<testingnewccaddress@akamai.com>' };

      // call the email service class and test it with the data in the testMethod

      if (emailProcess instanceof MomentumEmailHandler)
      {
        MomentumEmailHandler emailProcessCast = (MomentumEmailHandler) emailProcess;
        emailProcessCast.handleInboundEmail(email, env);
      }
      else if (emailProcess instanceof ProdMgmtEmailHandler)
      {
        ProdMgmtEmailHandler emailProcessCast = (ProdMgmtEmailHandler) emailProcess;
        emailProcessCast.handleInboundEmail(email, env);
      }
      else if (emailProcess instanceof E2CPartnerPortalEmailHandler)
      {
        E2CPartnerPortalEmailHandler emailProcessCast = (E2CPartnerPortalEmailHandler) emailProcess;
        emailProcessCast.handleInboundEmail(email, env);
      }
      else if (emailProcess instanceof E2CIntlBusDev)
      {
        E2CIntlBusDev emailProcessCast = (E2CIntlBusDev) emailProcess;
        emailProcessCast.handleInboundEmail(email, env);
      }

      // query for the contact the email service created
      Case testc = [Select case.id,case.CaseNumber,case.ContactId,case.Associated_Email__c from Case where case.Subject = :email.subject];
      
     
      System.assertEquals(testc.ContactId, null);
      System.assertEquals(testc.Associated_Email__c, 'someotheraddress2@akamai.com');
     
      // find the attachment
      Attachment a = [select name from attachment where parentId = :testc.id];
      //check if there is no other files attached
      System.assertNotEquals(a.name,'textfile.txt');
      // check if body comes as attachment
      System.assertEquals(a.name,'Email contents.txt');
      //Creates a case if casnumber is wrong
      email.subject = 'Creating a test case in test class #case [123456]';
      if (emailProcess instanceof MomentumEmailHandler)
      {
        MomentumEmailHandler emailProcessCast = (MomentumEmailHandler) emailProcess;
        emailProcessCast.handleInboundEmail(email, env);
      }
      else if (emailProcess instanceof ProdMgmtEmailHandler)
      {
        ProdMgmtEmailHandler emailProcessCast = (ProdMgmtEmailHandler) emailProcess;
        emailProcessCast.handleInboundEmail(email, env);
      }
      else if (emailProcess instanceof E2CPartnerPortalEmailHandler)
      {
        E2CPartnerPortalEmailHandler emailProcessCast = (E2CPartnerPortalEmailHandler) emailProcess;
        emailProcessCast.handleInboundEmail(email, env);
      }
      else if (emailProcess instanceof E2CIntlBusDev)
      {
        E2CIntlBusDev emailProcessCast = (E2CIntlBusDev) emailProcess;
        emailProcessCast.handleInboundEmail(email, env);
      }
    }
    static void MomentumTaskToCaseCreation(Object emailProcess,Email_to_Case__c CustomSettings) {
  ManagedPkgErrorClass.isFromManagedPackage = false;
      // create a new email and envelope object
      Messaging.InboundEmail email = new Messaging.InboundEmail() ;
      Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
      
      
      
      Profile pr = [select id from profile where name='Sales - Media'][0];
      User usr = new User(alias = 'user', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__usr@akamai.com',profileid = pr.Id);
      usr.AKAM_User_ID__c = 'ABC123';
      insert usr;
      // Create Account
      //Account acc = CreateAccount('__ Test Account3');
      Account acc = utilTestClass.CreateAccount('__ Test Account3');
      acc.Vertical__c = 'Gaming';
      acc.Sub_Vertical__c = 'Console Mfs';           
      insert acc;
        // Create Contact
      Contact con3 = utilTestClass.CreateContact('__Test Contact FirstName3','__Test Contact LastName3');
      con3.Email = 'someaddress3@akamai.com';
      con3.AKAM_Contact_ID__c = 'ABC123';
      con3.AccountId = acc.Id;
      insert con3;
        // Create Case
      
      
      Case cs = new Case();
      System.runAs(usr)
       {
            // Run as 'usr' to stamp Case.CreatedById
            cs.Subject = '__Testing New Case3';
            cs.RecordTypeId=CustomSettings.CaseRecord__c;
            insert cs;
       }     
       
       Case testc = [Select case.id,case.CaseNumber from Case where case.Subject = '__Testing New Case3'];
       
     // throw new CustomException('Here'+cs.CaseNumber);
      // setup the data for the email
      email.subject = 'Testing New Case3 #case ['+testc.CaseNumber+']';
      //email.bodytext = 'Creating a test case in test class';
      email.fromname = 'FirstName LastName';
      email.fromAddress = 'someaddress3@akamai.com';
      
      // add an attachment
      Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
      attachment.body = blob.valueOf('my attachment text');
      attachment.fileName = 'textfile.txt';
      attachment.mimeTypeSubType = 'text/plain';
     
      email.binaryAttachments =
        new Messaging.inboundEmail.BinaryAttachment[] { attachment };

      Messaging.InboundEmail.TextAttachment attachment2 = new Messaging.InboundEmail.TextAttachment();
      attachment2.body = 'my attachment text';
      attachment2.fileName = 'textfile.txt';
      attachment2.mimeTypeSubType = 'text/plain';
     
      email.TextAttachments =
        new Messaging.inboundEmail.TextAttachment[] { attachment2 };
        
      // call the email service class and test it with the data in the testMethod
            
      if (emailProcess instanceof MomentumEmailHandler)
      {
        MomentumEmailHandler emailProcessCast = (MomentumEmailHandler) emailProcess;
        emailProcessCast.handleInboundEmail(email, env);
      }
      else if (emailProcess instanceof ProdMgmtEmailHandler)
      {
        ProdMgmtEmailHandler emailProcessCast = (ProdMgmtEmailHandler) emailProcess;
        emailProcessCast.handleInboundEmail(email, env);
      }
      else if (emailProcess instanceof E2CPartnerPortalEmailHandler)
      {
        E2CPartnerPortalEmailHandler emailProcessCast = (E2CPartnerPortalEmailHandler) emailProcess;
        emailProcessCast.handleInboundEmail(email, env);
      }
      else if (emailProcess instanceof E2CIntlBusDev)
      {
        E2CIntlBusDev emailProcessCast = (E2CIntlBusDev) emailProcess;
        emailProcessCast.handleInboundEmail(email, env);
      }
      // query for the contact the email service created
      Task tsk;
      for(Task task1:[Select id,Subject,Status,Type__c,WhoId from Task where WhatId= :cs.id and Type__c='Email' and WhoId=:con3.id])
      tsk=task1;
      
      System.assertEquals(tsk.Status,'Completed');
      System.assertEquals(tsk.Type__c,'Email');
      System.assertEquals(tsk.Subject,'Testing New Case3');
       System.assertEquals(tsk.WhoId,con3.id);

     
      // find the attachment
      //Attachment a = [select name from attachment where parentId = :tsk.id];
     
      //System.assertEquals(a.name,'textfile.txt');
     
    }
    static void MomentumTaskToCaseCreationNegative(Object emailProcess,Email_to_Case__c CustomSettings) {
    ManagedPkgErrorClass.isFromManagedPackage = false;
      // create a new email and envelope object
      Messaging.InboundEmail email = new Messaging.InboundEmail() ;
      Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
      
      
      
      Profile pr = [select id from profile where name='Sales - Media'][0];
      User usr = new User(alias = 'user', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__usr@akamai.com',profileid = pr.Id);
      usr.AKAM_User_ID__c = 'ABC123';
      insert usr;
      // Create Account
      
        // Create Case
      Case cs = new Case();
      System.runAs(usr)
       {
            // Run as 'usr' to stamp Case.CreatedById
            cs.Subject = '__Testing New Case4';
            cs.RecordTypeId=CustomSettings.CaseRecord__c;
            insert cs;
       }     
       
       Case testc = [Select case.id,case.CaseNumber from Case where case.Subject = '__Testing New Case4' ];
       
     // throw new CustomException('Here'+cs.CaseNumber);
      // setup the data for the email
      email.subject = 'Testing New Case4 #case ['+testc.CaseNumber+']';
      //email.bodytext = 'Creating a test case in test class';
      email.plainTextBody= '1234567889';
      for(integer i=0;i<3205;i++)
      email.plainTextBody= email.plainTextBody+'01234567889';
      email.fromname = 'FirstName LastName';
      email.fromAddress = 'salesop@akamai.com';
    
     
     
      // call the email service class and test it with the data in the testMethod
      
      if (emailProcess instanceof MomentumEmailHandler)
      {
        MomentumEmailHandler emailProcessCast = (MomentumEmailHandler) emailProcess;
        emailProcessCast.handleInboundEmail(email, env);
      }
      else if (emailProcess instanceof ProdMgmtEmailHandler)
      {
        ProdMgmtEmailHandler emailProcessCast = (ProdMgmtEmailHandler) emailProcess;
        emailProcessCast.handleInboundEmail(email, env);
      }
      else if (emailProcess instanceof E2CPartnerPortalEmailHandler)
      {
        E2CPartnerPortalEmailHandler emailProcessCast = (E2CPartnerPortalEmailHandler) emailProcess;
        emailProcessCast.handleInboundEmail(email, env);
      }
      else if (emailProcess instanceof E2CIntlBusDev)
      {
        E2CIntlBusDev emailProcessCast = (E2CIntlBusDev) emailProcess;
        emailProcessCast.handleInboundEmail(email, env);
      }
      // query for the contact the email service created
      Task tsk;
      for(Task task1:[Select id,Subject,Status,Type__c,WhoId,OwnerId from Task where WhatId= :cs.id and Type__c='Email'])
      tsk=task1;
      
      System.assertEquals(tsk.Status,'Completed');
      System.assertEquals(tsk.Type__c,'Email');
      System.assertEquals(tsk.Subject,'Testing New Case4');
      System.assertEquals(tsk.WhoId,null);
      System.assertEquals(tsk.OwnerId,usr.id);
     
      // find the attachment
      Attachment a = [select name from attachment where parentId = :tsk.id];
     
      System.assertNotEquals(a.name,'textfile.txt');
      // check if body comes as attachment
      System.assertEquals(a.name,'Email contents.txt');
     
    }
    static void MomentumTaskToCaseCreation2(Object emailProcess,Email_to_Case__c CustomSettings) {
    ManagedPkgErrorClass.isFromManagedPackage = false;
      // create a new email and envelope object
      Messaging.InboundEmail email = new Messaging.InboundEmail() ;
      Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
      
      
      
      Profile pr = [select id from profile where name='Sales - Media'][0];
      User usr = new User(alias = 'user', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__usr@akamai.com',profileid = pr.Id);
      usr.AKAM_User_ID__c = 'ABC123';
      insert usr;
      // Create Account
      
        // Create Case
      Case cs = new Case();
      System.runAs(usr)
       {
            // Run as 'usr' to stamp Case.CreatedById
            cs.Subject = '__Testing New Case5';
            cs.Associated_Email__c='vinatar@akamai.com';
            cs.RecordTypeId=CustomSettings.CaseRecord__c;
            cs.Description='4567889';
            insert cs;
            Task ta=new Task();
            ta.WhatId=cs.id;
            ta.OwnerId=usr.id;
            ta.Description='TESTing';
            ta.subject='Testing';
            insert ta;
       }     
       
       Case testc = [Select case.id,case.CaseNumber from Case where case.Subject = '__Testing New Case5' ];
       
     // throw new CustomException('Here'+cs.CaseNumber);
      // setup the data for the email
      email.subject = 'Testing New Case5';
      //email.bodytext = 'Creating a test case in test class';
      email.plainTextBody= '1234567889';
      email.fromname = 'FirstName LastName';
      email.fromAddress = 'vinatar@akamai.com';
      email.ccAddresses = new String[] {'Group Email<'+CustomSettings.GroupEmail__c+'>' };
      email.toAddresses = new String[] {CustomSettings.GroupEmail__c };
     
      // call the email service class and test it with the data in the testMethod
      
      if (emailProcess instanceof MomentumEmailHandler)
      {
        MomentumEmailHandler emailProcessCast = (MomentumEmailHandler) emailProcess;
        emailProcessCast.handleInboundEmail(email, env);
      }
      else if (emailProcess instanceof ProdMgmtEmailHandler)
      {
        ProdMgmtEmailHandler emailProcessCast = (ProdMgmtEmailHandler) emailProcess;
        emailProcessCast.handleInboundEmail(email, env);
      }
      else if (emailProcess instanceof E2CPartnerPortalEmailHandler)
      {
        E2CPartnerPortalEmailHandler emailProcessCast = (E2CPartnerPortalEmailHandler) emailProcess;
        emailProcessCast.handleInboundEmail(email, env);
      }
      else if (emailProcess instanceof E2CIntlBusDev)
      {
        E2CIntlBusDev emailProcessCast = (E2CIntlBusDev) emailProcess;
        emailProcessCast.handleInboundEmail(email, env);
      }
      
      // query for the contact the email service created
      Task tsk;
      for(Task task1:[Select id,Subject,Status,Type__c,WhoId,OwnerId from Task where WhatId= :cs.id and Type__c='Email'])
      tsk=task1;
      
      System.assertEquals(tsk.Status,'Completed');
      System.assertEquals(tsk.Type__c,'Email');
      System.assertEquals(tsk.Subject,'Testing New Case5');
      System.assertEquals(tsk.WhoId,null);
    }
}