@isTest(seeAllData = false)

private class ConvertContactToLeadPageControllerTest {
    
    static{
        utilTestClass.insertCustomSettings();
    }
    
    static testmethod void convertLeadMethodTest()
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            // TODO - to be fixed
            String user_role = GsmUtilClass.getGSMSettingValue('User_Role');
            
            List<User> userList = new List<user>();
            User salesUser = utilTestClass.CreateUser('newUs1', user_role, 'Sales Operations');
            userList.add(salesUser);
            //TODO-uncomment once Radha fixed user roles
            //User gssUser = utilTestClass.CreateUser('newUs2', 'Worldwide', 'GSS Operations');
            //userList.add(gssUser);

            insert userList;

            Account account = utilTestClass.CreateAccount('Test_Account');
            account.BillingStreet = '#39,7th Cross';
            account.BillingCity   = 'LA';
            account.BillingState = 'CA';
            account.BillingPostalCode = '56005';
            account.BillingCountry = 'USA';
            account.Type='Lead';
            account.Vertical__c = 'Business Services';
            account.Sub_Vertical__c = 'BPO';
            account.OwnerId = salesUser.Id;
            insert account;
    
            Contact contact = utilTestClass.CreateContact('Test_FirstName', 'Test_LastName');
            contact.Phone = '+11234567890';
            contact.MailingCountry = 'USA';
            contact.MailingStreet = '#39,7th Cross';
            contact.MailingState = 'CA';
            contact.MailingPostalCode = '560126';
            contact.MailingCity = 'SD';
            contact.AccountId = account.Id;
            contact.Authorized_For_Marketplace__c = true;
            insert contact;


    
            Test.startTest();
            //ApexPages.StandardController sc1 = new ApexPages.StandardController(contact);
            //ConvertContactToLeadPageController  controller2 = new ConvertContactToLeadPageController();
            system.runAs(salesUser)
            {
            GSM_Lite_ContactToLeadCreateController controller1 = new GSM_Lite_ContactToLeadCreateController();
            PageReference pageRef1 = Page.ConvertContactToLeadPage;
            Test.setCurrentPage(pageRef1);

            GSM_Lite_ContactToLeadCreateController.loadPicklistValues('Lead','Product_Line__c');
            GSM_Lite_ContactToLeadCreateController.getUIThemeDescription();
            GSM_Lite_ContactToLeadCreateController.isValidUserCheck();
            GSM_Lite_ContactToLeadCreateController.isSDRUserCheck();
            GSM_Lite_ContactToLeadCreateController.loadSDRLeadTypePicklistValues();
            GSM_Lite_ContactToLeadCreateController.insertNewLead('Media','Test Lead',contact.Id,'Inbound Email');
        }
        //TODO-uncomment once Radha fixed user roles
        //system.runAs(gssUser)
        //    {
        //    GSM_Lite_ContactToLeadCreateController controller1 = new GSM_Lite_ContactToLeadCreateController();
        //    PageReference pageRef1 = Page.ConvertContactToLeadPage;
        //    Test.setCurrentPage(pageRef1);

        //    GSM_Lite_ContactToLeadCreateController.loadPicklistValues('Lead','Product_Line__c');
        //    GSM_Lite_ContactToLeadCreateController.getUIThemeDescription();
        //    GSM_Lite_ContactToLeadCreateController.isValidUserCheck();
        //    GSM_Lite_ContactToLeadCreateController.isSDRUserCheck();
        //    GSM_Lite_ContactToLeadCreateController.loadSDRLeadTypePicklistValues();
        //    GSM_Lite_ContactToLeadCreateController.insertNewLead('Media','Test Lead',contact.Id,'Inbound Email');
        //}





            
            Test.stopTest();
            
            //List<Lead> leadList = [Select Id From Lead ];//Where Associated_Contact__c  = :contact.Id];
            //System.debug(LoggingLevel.ERROR, controller.campaignOption);
            //System.debug(LoggingLevel.ERROR, controller.selectProductLine);
    
            //System.debug(LoggingLevel.ERROR, leadList);
            //Integer size = leadList.size();
            //System.assertNotEquals(size,0); 
            
        }
    }

    static testmethod void GSM_CallToAction_CreateLeadControllerMethodTest()
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            // TODO - to be fixed
            
            Account account = utilTestClass.CreateAccount('Test_Account');
            account.BillingStreet = '#39,7th Cross';
            account.BillingCity   = 'LA';
            account.BillingState = 'CA';
            account.BillingPostalCode = '56005';
            account.BillingCountry = 'USA';
            account.Type='Lead';
            account.Vertical__c = 'Business Services';
            account.Sub_Vertical__c = 'BPO';
            insert account;
    
            Contact contact = utilTestClass.CreateContact('Test_FirstName', 'Test_LastName');
            contact.Phone = '+11234567890';
            contact.MailingCountry = 'USA';
            contact.MailingStreet = '#39,7th Cross';
            contact.MailingState = 'CA';
            contact.MailingPostalCode = '560126';
            contact.MailingCity = 'SD';
            contact.AccountId = account.Id;
            contact.Authorized_For_Marketplace__c = true;
            insert contact;

            LiveChatVisitor lcv = new LiveChatVisitor();
            insert lcv;
            
            LiveChatTranscript lct = new LiveChatTranscript();
            lct.LiveChatVisitorId = lcv.id;
            insert lct;

            Lead lead = utilTestClass.CreateLead();
            lead.RecordTypeId = GSMUtilClass.getGSMSettingValue('AkamaiLeadRecordTypeId');
            lead.Associated_Contact__c = contact.Id;
            lead.Associated_Account__c = account.Id;
            insert lead;



    
            Test.startTest();
            //ApexPages.StandardController sc1 = new ApexPages.StandardController(contact);
            GSM_CallToAction_CreateLeadController controller1 = new GSM_CallToAction_CreateLeadController();
            PageReference pageRef1 = Page.ConvertContactToLeadPage;
            Test.setCurrentPage(pageRef1);

            GSM_CallToAction_CreateLeadController.loadPicklistValues('Lead','Product_Line__c');
            GSM_CallToAction_CreateLeadController.getUIThemeDescription();
            GSM_CallToAction_CreateLeadController.isSDRUserCheck();
           GSM_CallToAction_CreateLeadController.callToActionLeadExists(contact.Id,True);
            GSM_CallToAction_CreateLeadController.callToActionLeadExists(contact.Id,False);
            GSM_CallToAction_CreateLeadController.callToActionLeadExists(lct.id,True);
            GSM_CallToAction_CreateLeadController.callToActionLeadExists(lct.Id,False);




            
            Test.stopTest();
            
            
            
        }
    }

    static testmethod void GSM_CallToAction_CreateActivityOnC2A() {
        System.runAs(utilTestClass.getTestRunUser())
        {  
            Account account = utilTestClass.CreateAccount('Test_Account');
            account.BillingStreet = '#39,7th Cross';
            account.BillingCity   = 'LA';
            account.BillingState = 'CA';
            account.BillingPostalCode = '56005';
            account.BillingCountry = 'USA';
            account.Type='Lead';
            account.Vertical__c = 'Business Services';
            account.Sub_Vertical__c = 'BPO';
            insert account;
            
            Contact contact = utilTestClass.CreateContact('Test_FirstName', 'Test_LastName');
            contact.Phone = '+11234567890';
            contact.MailingCountry = 'USA';
            contact.MailingStreet = '#39,7th Cross';
            contact.MailingState = 'CA';
            contact.MailingPostalCode = '560126';
            contact.MailingCity = 'SD';
            contact.AccountId = account.Id;
            contact.Authorized_For_Marketplace__c = true;
            insert contact;
            
            Lead lead = utilTestClass.CreateLead();
            lead.RecordTypeId = GSMUtilClass.getGSMSettingValue('AkamaiLeadRecordTypeId');
            lead.Associated_Contact__c = contact.Id;
            lead.Associated_Account__c = account.Id;
            insert lead;

            Test.startTest();
            GSM_CallToAction_CreateLeadController.creteActivityAndGetUITheme('Media','Inbound Email', 'Check Activity Creation Test', lead.Id);
            Test.stopTest();
            
            List<Task> tasks = [Select Id, WhoId  from Task limit 1];
            System.assert(tasks.size() > 0, 'Task list must not be empty');
            System.assertEquals(tasks[0].WhoId, lead.Id);
        }  
    }

}