/**
    Product Management Email Handler Test Class
    @version 1.0
    @author : Vinayendra T N <vinatara@akamai.com>
    @Description : This class implements the unit tests for ProdMgmtEmailHandler and EmailtoCase Class.
                   Use cases that are tested :   
                   1. Case Creation using email with Attachements.
                   2. Case Creation using email with long length body without Attachements.
                   3. Task to Case Creation using email with Attachements.
                   4. Task to Case Creation using email with long length body without Attachements.
                                   
*/
@isTest
private class ProdMgmtEmailHandlerTest {
/*private static Email_to_Case__c CustomSettings = Email_to_Case__c.getInstance('ProdMgmt');
	static String CaseRecord=CustomSettings.CaseRecord__c;
    private static Contact CreateContact(String FirstName,String LastName,String conemail)
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
        accOld.Akamai_Vertical__c = 'Gaming';
        accOld.Sub_Vertical__c = 'Console Mfs';         
        return accOld;
    }
    static testMethod void ProdMgmtCaseCreation() {
 
      // create a new email and envelope object
      Messaging.InboundEmail email = new Messaging.InboundEmail() ;
      Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
     
      // setup the data for the email
      email.subject = 'Creating a test case in test class';
      //email.bodytext = 'Creating a test case in test class';
      email.fromname = 'FirstName LastName';
      email.fromAddress = 'someaddress@akamai.com';
      Account acc = CreateAccount('__Test Old Account');        
      insert acc;
      Contact con= CreateContact('__First','__last','someaddress@akamai.com');
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
      ProdMgmtEmailHandler emailProcess = new ProdMgmtEmailHandler();
      Test.startTest();
      emailProcess.handleInboundEmail(email, env);
      Test.stopTest();
     
      // query for the contact the email service created
      Case testc = [Select case.id,case.CaseNumber,case.ContactId,case.Associated_Email__c,case.Email_to_case__c from Case where case.Subject = 'Creating a test case in test class'];
      
      System.assertEquals(testc.Associated_Email__c, 'someaddress@akamai.com');
      System.assertEquals(testc.ContactId, con.id);
      System.assert(testc.Email_to_case__c);
      
     
     
      // find the attachment
      //Attachment a = [select name from attachment where parentId = :testc.id];
     
      //System.assertEquals(a.name,'textfile.txt');
     
    }
    static testMethod void ProdMgmtCaseCreationNagative() {
 
      // create a new email and envelope object
      Messaging.InboundEmail email = new Messaging.InboundEmail() ;
      Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
     
      // setup the data for the email
      email.subject = 'Creating a test case in test class';
      email.plainTextBody= '1234567889';
      for(integer i=0;i<3205;i++)
      email.plainTextBody= email.plainTextBody+'01234567889';
     
      email.fromname = 'FirstName LastName';
      email.fromAddress = 'someotheraddress@akamai.com';
      email.toAddresses = new String[] {'testingnewaddress@akamai.com' };
      email.ccAddresses = new String[] {'Vinay<testingnewccaddress@akamai.com>' };

      // call the email service class and test it with the data in the testMethod
      ProdMgmtEmailHandler emailProcess = new ProdMgmtEmailHandler();
      Test.startTest();
      emailProcess.handleInboundEmail(email, env);
      Test.stopTest();
      // query for the contact the email service created
      Case testc = [Select case.id,case.CaseNumber,case.ContactId,case.Associated_Email__c from Case where case.Subject = :email.subject];
      
     
      System.assertEquals(testc.ContactId, null);
      System.assertEquals(testc.Associated_Email__c, 'someotheraddress@akamai.com');
     
      // find the attachment
      Attachment a = [select name from attachment where parentId = :testc.id];
      //check if there is no other files attached
      System.assertNotEquals(a.name,'textfile.txt');
      // check if body comes as attachment
      System.assertEquals(a.name,'Email contents.txt');
      //Creates a case if casnumber is wrong
      email.subject = 'Creating a test case in test class #case [123456]';
      emailProcess.handleInboundEmail(email, env);
    }
    static testMethod void ProdMgmtTaskToCaseCreation() {
 
      // create a new email and envelope object
      Messaging.InboundEmail email = new Messaging.InboundEmail() ;
      Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
      
      
      
      Profile pr = [select id from profile where name='Sales - Rep'][0];
      User usr = new User(alias = 'user', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__usr@akamai.com',profileid = pr.Id);
      usr.AKAM_User_ID__c = 'ABC123';
      insert usr;
      // Create Account
      Account acc = CreateAccount('__ Test Account');           
      insert acc;
        // Create Contact
      Contact con = CreateContact('__Test Contact FirstName','__Test Contact LastName','someaddress@akamai.com');
       con.AccountId = acc.Id;
      insert con;
        // Create Case
      
      
      Case cs = new Case();
      System.runAs(usr)
       {
            // Run as 'usr' to stamp Case.CreatedById
            cs.Subject = '__Testing New Case';
            cs.RecordTypeId=CaseRecord;
            insert cs;
       }     
       
       Case testc = [Select case.id,case.CaseNumber from Case where case.Subject = '__Testing New Case'];
       
     // throw new CustomException('Here'+cs.CaseNumber);
      // setup the data for the email
      email.subject = 'Testing New Case #case ['+testc.CaseNumber+']';
      //email.bodytext = 'Creating a test case in test class';
      email.fromname = 'FirstName LastName';
      email.fromAddress = 'someaddress@akamai.com';
      
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
      ProdMgmtEmailHandler emailProcess = new ProdMgmtEmailHandler();
      Test.startTest();
      emailProcess.handleInboundEmail(email, env);
      Test.stopTest();
      // query for the contact the email service created
      Task tsk;
      for(Task task1:[Select id,Subject,Status,Type__c,WhoId from Task where WhatId= :cs.id and Type__c='Email' and WhoId=:con.id])
      tsk=task1;
      
      System.assertEquals(tsk.Status,'Completed');
      System.assertEquals(tsk.Type__c,'Email');
      System.assertEquals(tsk.Subject,'Testing New Case');
       System.assertEquals(tsk.WhoId,con.id);

     
      // find the attachment
      //Attachment a = [select name from attachment where parentId = :tsk.id];
     
      //System.assertEquals(a.name,'textfile.txt');
     
    }
    static testMethod void ProdMgmtTaskToCaseCreationNegative() {
 
      // create a new email and envelope object
      Messaging.InboundEmail email = new Messaging.InboundEmail() ;
      Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
      
      
      
      Profile pr = [select id from profile where name='Sales - Rep'][0];
      User usr = new User(alias = 'user', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__usr@akamai.com',profileid = pr.Id);
      usr.AKAM_User_ID__c = 'ABC123';
      insert usr;
      // Create Account
      
        // Create Case
      Case cs = new Case();
      System.runAs(usr)
       {
            // Run as 'usr' to stamp Case.CreatedById
            cs.Subject = '__Testing New Case';
            cs.RecordTypeId=CaseRecord;
            insert cs;
       }     
       
       Case testc = [Select case.id,case.CaseNumber from Case where case.Subject = '__Testing New Case' ];
       
     // throw new CustomException('Here'+cs.CaseNumber);
      // setup the data for the email
      email.subject = 'Testing New Case #case ['+testc.CaseNumber+']';
      //email.bodytext = 'Creating a test case in test class';
      email.plainTextBody= '1234567889';
      for(integer i=0;i<3205;i++)
      email.plainTextBody= email.plainTextBody+'01234567889';
      email.fromname = 'FirstName LastName';
      email.fromAddress = 'salesop@akamai.com';
    
     
     
      // call the email service class and test it with the data in the testMethod
      ProdMgmtEmailHandler emailProcess = new ProdMgmtEmailHandler();
      Test.startTest();
      emailProcess.handleInboundEmail(email, env);
      Test.stopTest();
      // query for the contact the email service created
      Task tsk;
      for(Task task1:[Select id,Subject,Status,Type__c,WhoId,OwnerId from Task where WhatId= :cs.id and Type__c='Email'])
      tsk=task1;
      
      System.assertEquals(tsk.Status,'Completed');
      System.assertEquals(tsk.Type__c,'Email');
      System.assertEquals(tsk.Subject,'Testing New Case');
      System.assertEquals(tsk.WhoId,null);
      System.assertEquals(tsk.OwnerId,usr.id);
     
      // find the attachment
      Attachment a = [select name from attachment where parentId = :tsk.id];
     
      System.assertNotEquals(a.name,'textfile.txt');
      // check if body comes as attachment
      System.assertEquals(a.name,'Email contents.txt');
     
    }
    static testMethod void ProdMgmtTaskToCaseCreation2() {
 
      // create a new email and envelope object
      Messaging.InboundEmail email = new Messaging.InboundEmail() ;
      Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
      
      
      
      Profile pr = [select id from profile where name='Sales - Rep'][0];
      User usr = new User(alias = 'user', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__usr@akamai.com',profileid = pr.Id);
      usr.AKAM_User_ID__c = 'ABC123';
      insert usr;
      // Create Account
      
        // Create Case
      Case cs = new Case();
      System.runAs(usr)
       {
            // Run as 'usr' to stamp Case.CreatedById
            cs.Subject = '__Testing New Case';
            cs.Associated_Email__c='vinatar@akamai.com';
            cs.RecordTypeId=CaseRecord;
            cs.Description='4567889';
            insert cs;
            Task ta=new Task();
            ta.WhatId=cs.id;
            ta.OwnerId=usr.id;
            ta.Description='TESTing';
            ta.subject='Testing';
            insert ta;
       }     
       
       Case testc = [Select case.id,case.CaseNumber from Case where case.Subject = '__Testing New Case' ];
       
     // throw new CustomException('Here'+cs.CaseNumber);
      // setup the data for the email
      email.subject = 'Testing New Case';
      //email.bodytext = 'Creating a test case in test class';
      email.plainTextBody= '1234567889';
      email.fromname = 'FirstName LastName';
      email.fromAddress = 'vinatar@akamai.com';
      email.ccAddresses = new String[] {'Group Email<'+CustomSettings.GroupEmail__c+'>' };
      email.toAddresses = new String[] {CustomSettings.GroupEmail__c };
     
      // call the email service class and test it with the data in the testMethod
      ProdMgmtEmailHandler emailProcess = new ProdMgmtEmailHandler();
      Test.startTest();
      emailProcess.handleInboundEmail(email, env);
      Test.stopTest();
      // query for the contact the email service created
      Task tsk;
      for(Task task1:[Select id,Subject,Status,Type__c,WhoId,OwnerId from Task where WhatId= :cs.id and Type__c='Email'])
      tsk=task1;
      
      System.assertEquals(tsk.Status,'Completed');
      System.assertEquals(tsk.Type__c,'Email');
      System.assertEquals(tsk.Subject,'Testing New Case');
      System.assertEquals(tsk.WhoId,null);
     
      
     
    }*/
}