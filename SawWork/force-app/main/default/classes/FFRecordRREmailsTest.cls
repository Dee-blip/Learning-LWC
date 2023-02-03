@isTest(SeeAllData=false)
private class FFRecordRREmailsTest 
{
    static testMethod void testInboundEmail() 
    {
        PSA_TestUtility testUtil = new PSA_TestUtility();
        List<String> toAddressList = new List<String>();
        toAddressList.add('test@email.com');
        List<String> ccAddressList = new List<String>();
        ccAddressList.add('testcc@email.com');
        pse__Region__c reg = testUtil.newRegionMaster(true);
        Account acct = testUtil.newAccount(false);
        acct.Area__c ='Comm Central';   
        insert acct;
        User usr = testUtil.newUserSysAdmin(true);  
        
        Contact resource = testUtil.newResource(false, acct.Id, usr.Id);
        pse__Grp__c grp = testUtil.newGroupMaster(TRUE);
        resource.pse__Group__c = grp.Id;
        
        insert resource;
        
        //Changes by Sharath for FFPSA-607: Commenting the opp creation
        //Opportunity opp = testUtil.newOpportunity(true,acct.Id, '0=Plan', System.today());
        //List<OpportunityLineItem> lineItems = testUtil.createOpportunityItems(opp.Id, 4);
        pse__Practice__c pract = testUtil.newPracticeMaster(true);
        Id practId =  pract.ID;
        pse__Proj__c templateProj = testUtil.newProject(false,reg.id,practId,true,'One-Time: Fixed Price', resource.Id, acct.Id);   
        templateProj.pse__Is_Template__c = true;
        insert templateProj;        
        User usr2 = testUtil.newUserSysAdmin(true);
        
        pse__Resource_Request__c projResReq;   
        
        pse__Permission_Control__c pc = testUtil.newPermissionControl(true, usr2.Id, reg.Id);   
        
        System.runAs(usr) 
        {       
            projResReq = testUtil.newResourceRequest(true, acct.Id, resource.id, System.today(), System.today().addDays(15), templateProj.Id, null,reg.Id);   
        }
        
        pse__Resource_Request__c resReq = [select Id, Name from pse__Resource_Request__c where id = :projResReq.Id];       

        // create a new email and envelope object
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

        // setup the data for the email
        email.subject = 'Resource Request '+'[AKAM-RR #'+resReq.Name+ '] for Test - Ready to Staff';
        email.fromname = 'FirstName LastName';
        email.fromAddress = 'someaddress@email.com';
        email.toAddresses = toAddressList;
        email.ccAddresses = ccAddressList;
        email.htmlBody = '<html><body>test html content</body></html>';
        email.plainTextBody = 'test plain email body';
        env.fromAddress = 'someaddress@email.com';
        env.toAddress = 'testaddress@email.com';

        // add an attachment
        Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
        attachment.body = blob.valueOf('my attachment text');
        attachment.fileName = 'textfile.txt';
        attachment.mimeTypeSubType = 'text/plain';

        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment };

        // call the email service class and test it with the data in the testMethod
        FFRecordRREmails emailProcess = new FFRecordRREmails();
        emailProcess.handleInboundEmail(email, env);

        Messaging.InboundEmail email1 = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env1 = new Messaging.InboundEnvelope();

        email1.subject = '[AKAM-RR #'+resReq.Name+ '] - Resource on Hold - test';
        email1.fromname = 'FirstName LastName';
        env1.fromAddress = 'someaddress@email.com';
        email1.toAddresses = toAddressList;
        email1.plainTextBody = 'test plain email body';

        Messaging.InboundEmail.BinaryAttachment attachment1 = new Messaging.InboundEmail.BinaryAttachment();
        attachment1.body = blob.valueOf('my attachment text');
        attachment1.fileName = 'textfile.txt';
        attachment1.mimeTypeSubType = 'text/plain';

        Messaging.InboundEmail.textAttachment attachment2 = new Messaging.InboundEmail.TextAttachment();
        attachment2.body = 'my attachment text';
        attachment2.fileName = 'textfile1.txt';
        attachment2.mimeTypeSubType = 'text/plain';

        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment1 };
        email.textAttachments = new Messaging.inboundEmail.TextAttachment[] { attachment2 };

        emailProcess.handleInboundEmail(email1, env1);
        emailProcess.handleInboundEmail(email, env1);

    }
}