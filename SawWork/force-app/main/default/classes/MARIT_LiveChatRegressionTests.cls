@isTest(seeAllData = false)
private class MARIT_LiveChatRegressionTests {
    private static User dmlUser = new User(id=UserInfo.getUserId());
    
    // Setup method to create test data.
    @testSetup
    static void setupMethod() 
    {
        MarketingIT_Custom_Settings__c settings = new MarketingIT_Custom_Settings__c();
        settings.Name = 'LeadAsyncConversionFlagStatus';
        settings.Flag_Status__c = false;
        insert settings;
        Account acc = utilTestClass.CreateAccount('Test Account2');
        insert acc;
        
        LiveChatVisitor lcv = new LiveChatVisitor();
        insert lcv;
        LiveChatTranscript lct = new LiveChatTranscript();
        lct.LiveChatVisitorId = lcv.id;
        insert lct;
    }
    
    static testmethod void LiveChat_FindPersonRecord_ReturnsDesiredResult() 
    {
        User SDR = [select id from user where profile.name='Sales Development Representative' and isactive=true limit 1];
        Test.startTest();
        System.runAs(SDR){
            Account testAccount = [select Id, name from Account where Name = 'Test Account2'];
            Integer numberOfLeads = 5;
            List<Lead> leadList= CreateMarketoLeads(numberOfLeads, testAccount);
            insert leadList;
            Id [] fixedSearchResults= new Id[numberOfLeads];
            for(integer i =0 ; i< numberOfLeads ; i++) {
                fixedSearchResults[i] = leadList[i].Id;
            }
            Test.setFixedSearchResults(fixedSearchResults);
            
            // Search Multiple leads based on Name
            List<String> returnValueList = MARIT_CreateOrLinkToLiveChatController.searchForIds('Test ML00');
            System.assert(returnValueList.size() == 5, 'All leads must satisfy the search criteria');
            for(String retVal : returnValueList) {
                System.assert(retVal.contains('Test ML00'), 'Lead should contain the search Name');
            }
        }
        Test.stopTest();
    }
    
    static testmethod void LiveChat_FindPersonContactRecord_ReturnsDesiredResult() 
    {
        User SDR = [select id from user where profile.name='Sales Development Representative' and isactive=true limit 1];
        Test.startTest();
        System.runAs(SDR){
            Account testAccount = [select Id, name from Account where Name = 'Test Account2'];
            Integer numberOfContacts = 5;
            List<Contact> conList= CreateContacts(numberOfContacts, testAccount);
            insert conList;
            Id [] fixedSearchResults= new Id[numberOfContacts];
            for(integer i =0 ; i< numberOfContacts ; i++) {
                fixedSearchResults[i] = conList[i].Id;
            }
            Test.setFixedSearchResults(fixedSearchResults);
            
            // Search Multiple Contacts based on Name
            List<String> returnValueList = MARIT_CreateOrLinkToLiveChatController.searchForIds('Test Contact00');
            System.assert(returnValueList.size() == 5, 'All Contacts must satisfy the search criteria');
            for(String retVal : returnValueList) {
                System.assert(retVal.contains('Test Contact00'), 'Contact should contain the search Name');
            }
        }
        Test.stopTest();
    }
    
    static testmethod void CreatePersonViaLiveChat_PersonCreatedSuccessfully() 
    {
        User SDR = [select id from user where profile.name='Sales Development Representative' and isactive=true limit 1];
        Test.startTest();
        System.runAs(SDR){
            Account testAccount = [select Id, name from Account where Name = 'Test Account2'];
            LiveChatTranscript la = [Select id,Contact.Id,LeadId,Lead.Name from LiveChatTranscript limit 1];
            Id marketoRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
            
            Lead lObj = new Lead();
            lObj.RecordTypeId = marketoRecordTypeId;
            lObj.FirstName = 'Test';
            lObj.LastName = 'ML00Create';
            lObj.Email = lObj.FirstName + lObj.LastName + '@akamai.com';
            lObj.Associated_Account__c = testAccount.Id;
            lObj.Company = 'Test Company';
            lObj.Phone = '345345634';
            lObj.Country = 'USA';
            lObj.State = 'TX';
            lObj.Title = 'Test Title';
            
            String resultafterLeadSaved = MARIT_CreateOrLinkToLiveChatController.SaveMarketoLeadAndLinkToChat(lObj, la.Id);
            LiveChatTranscript laFinal = [select id, contactId, LeadId from LiveChatTranscript where id =:la.Id];
            Lead testLead = [Select Id, ConvertedContactId from Lead where Email = :lObj.Email];
            System.assert(resultafterLeadSaved.contains('ML00Create'), 'Linked Lead must show up');
            System.assertEquals(testLead.Id, laFinal.LeadId);
        }
        Test.stopTest();
    }

    static testmethod void CreatePersonViaLiveChat_InvalidDetails_ErrorCreatingPerson() 
    {
        User SDR = [select id from user where profile.name='Sales Development Representative' and isactive=true limit 1];
        Test.startTest();
        System.runAs(SDR){
            Account testAccount = [select Id, name from Account where Name = 'Test Account2'];
            LiveChatTranscript la = [Select id,Contact.Id,LeadId,Lead.Name from LiveChatTranscript limit 1];
            Id marketoRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
            
            // No account added
            Lead lObj = new Lead();
            lObj.RecordTypeId = marketoRecordTypeId;
            lObj.FirstName = 'Test';
            lObj.LastName = 'ML002Create';
            lObj.Email = lObj.FirstName + lObj.LastName + '@akamai.com';
            lObj.Company = 'Test Company';
            lObj.Phone = '345345634';
            lObj.Title = 'Test Title';
            
            String resultafterLeadSaved = MARIT_CreateOrLinkToLiveChatController.SaveMarketoLeadAndLinkToChat(lObj, la.Id);
            System.assert(resultafterLeadSaved.contains('Insert failed'), 'Person Lead must not be created');
        }
        Test.stopTest();
    }
    
    /*
    static testmethod void CreatePersonViaLiveChat_SameEmail_ErrorSaving() 
    {
        Account testAccount = [select Id, name from Account where Name = 'Test Account2'];
        LiveChatTranscript la = [Select id,Contact.Id,LeadId,Lead.Name from LiveChatTranscript limit 1];
        Id marketoRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
        
        Contact conObj = new Contact();
        conObj.FirstName = 'Test';
        conObj.LastName = 'Contact010';
        conObj.Email = 'TestSameEmail@akamai.com';
        conObj.AccountId = testAccount.Id;
        
        Lead lObj = new Lead();
        lObj.RecordTypeId = marketoRecordTypeId;
        lObj.FirstName = 'Test';
        lObj.LastName = 'ML010';
        lObj.Email = 'TestSameEmail@akamai.com';
        lObj.Associated_Account__c = testAccount.Id;
        lObj.Company = 'Test Company';
        
        Test.startTest();
        insert conObj;
        String resultafterLeadSaved = MARIT_CreateOrLinkToLiveChatController.SaveMarketoLeadAndLinkToChat(lObj, la.Id);
        Test.stopTest();
        System.debug('Result error same email : ' + resultafterLeadSaved);
        System.assert(resultafterLeadSaved.contains('already exists in the system'), resultafterLeadSaved);
    }*/
    
    static testmethod void CTAOnLiveChat_NoPersonLinked_GivesError()  {
        User SDR = [select id from user where profile.name='Sales Development Representative' and isactive=true limit 1];
        Test.startTest();
        System.runAs(SDR){
            Account testAccount = [select Id, name from Account where Name = 'Test Account2'];
            LiveChatTranscript la = [Select id,Contact.Id,LeadId,Lead.Name from LiveChatTranscript limit 1];
            
            String result = GSM_Controller_LA_LeadFromContact.validateTranscriptRecord(la.Id);
            System.assert(result.contains('No Contact/Lead linked to chat record'), 'Chat must have a person record linked');
        }
        Test.stopTest();
    }
    
    static testmethod void LiveChat_LinkPersonRecord()  {
        User SDR = [select id from user where profile.name='Sales Development Representative' and isactive=true limit 1];
        Test.startTest();
        System.runAs(SDR){
            Account testAccount = [select Id, name from Account where Name = 'Test Account2'];
            LiveChatTranscript la = [Select id,Contact.Id,LeadId,Lead.Name from LiveChatTranscript limit 1];
            Integer numberOfLeads = 1;
            List<Lead> leadList = CreateMarketoLeads(numberOfLeads, testAccount);
            insert leadList;
            
            String returnValue = MARIT_CreateOrLinkToLiveChatController.LinkPersonToLiveChat(la.Id, leadList[0].Id);
            System.assert(returnValue.contains(leadList[0].LastName), 'Lead must be linked to live chat');
            LiveChatTranscript laFinal = [Select id,Contact.Id,LeadId,Lead.Name, AccountId from LiveChatTranscript limit 1];
            System.assert(laFinal.AccountId == testAccount.Id,'Account should be automatically linked to live chat');
        }
        Test.stopTest();
    }
    
    static testmethod void LiveChatWithPersonLinked_LinkAnotherPerson_AccountIdForLiveChatChanges()  {
        User SDR = [select id from user where profile.name='Sales Development Representative' and isactive=true limit 1];
        Account acc = utilTestClass.CreateAccount('Test Account');
        insert acc;
        Test.startTest();
        System.runAs(SDR){
            Account testAccount = [select Id, name from Account where Name = 'Test Account2'];
            LiveChatTranscript la = [Select id,Contact.Id,LeadId,Lead.Name from LiveChatTranscript limit 1];
            Integer numberOfLeads = 2;
            List<Lead> leadList = CreateMarketoLeads(numberOfLeads, testAccount);
            leadList[1].Associated_Account__c = acc.Id;
            insert leadList;
            
            String returnValue = MARIT_CreateOrLinkToLiveChatController.LinkPersonToLiveChat(la.Id, leadList[0].Id);
            System.assert(returnValue.contains(leadList[0].LastName), 'Lead must be linked to live chat');
            LiveChatTranscript laFinal = [Select id,Contact.Id,LeadId,Lead.Name, AccountId from LiveChatTranscript limit 1];
            System.assert(laFinal.AccountId == testAccount.Id,'Account should be automatically linked to live chat');
            
            String returnValue2 = MARIT_CreateOrLinkToLiveChatController.LinkPersonToLiveChat(la.Id, leadList[1].Id);
            System.assert(returnValue2.contains(leadList[1].LastName), 'Lead must be linked to live chat');
            LiveChatTranscript laFinal2 = [Select id,Contact.Id,LeadId,Lead.Name, AccountId from LiveChatTranscript limit 1];
            System.assert(laFinal2.AccountId == acc.Id,'Account should be automatically changed');
        }
        Test.stopTest();
    }
    
    static testmethod void CTAOnLiveChat_PersonLinked_CTACreatedSuccessfully()  {
        User SDR = [select id from user where profile.name='Sales Development Representative' and isactive=true limit 1];
        Test.startTest();
        System.runAs(SDR){
            Account testAccount = [select Id, name from Account where Name = 'Test Account2'];
            LiveChatTranscript la = [Select id,Contact.Id,LeadId,Lead.Name from LiveChatTranscript limit 1];
            Integer numberOfLeads = 1;
            List<Lead> leadList = CreateMarketoLeads(numberOfLeads, testAccount);
            insert leadList;
            
            String returnValue = MARIT_CreateOrLinkToLiveChatController.LinkPersonToLiveChat(la.Id, leadList[0].Id);
            System.assert(returnValue.contains(leadList[0].LastName), 'Lead must be linked to live chat');
            
            String result = GSM_Controller_LA_LeadFromContact.validateTranscriptRecord(la.Id);
            System.assert(result.contains('Success'), 'No Validation issue before creating CTA : ' + result);
            
            String ctaResult = GSM_Controller_LA_LeadFromContact.createLeadFromContact(la.Id);
            System.assert(!ctaResult.contains('Error'), 'CTA should be created : ' + ctaResult);
            
            List<CampaignMember> cmList = [Select Id, LeadId from CampaignMember where LeadId =: leadList[0].Id];
            System.assert(cmList.size() == 1, 'Campaign member should be created');
            System.assert(cmList[0].LeadId == leadList[0].Id, 'Campaign member should be created for same Lead');
        }
        Test.stopTest();
    }
    
    static testmethod void CTAOnLiveChat_CampMemAlreadyPresent_NoCampaignRelatederror()  {
        User SDR = [select id from user where profile.name='Sales Development Representative' and isactive=true limit 1];
        Test.startTest();
        System.runAs(SDR){
            Account testAccount = [select Id, name from Account where Name = 'Test Account2'];
            LiveChatTranscript la = [Select id,Contact.Id,LeadId,Lead.Name from LiveChatTranscript limit 1];
            Integer numberOfLeads = 1;
            List<Lead> leadList = CreateMarketoLeads(numberOfLeads, testAccount);
            insert leadList;
            
            String returnValue = MARIT_CreateOrLinkToLiveChatController.LinkPersonToLiveChat(la.Id, leadList[0].Id);
            System.assert(returnValue.contains(leadList[0].LastName), 'Lead must be linked to live chat');
            
            String ctaResult = GSM_Controller_LA_LeadFromContact.createLeadFromContact(la.Id);
            System.assert(!ctaResult.contains('Error'), 'CTA should be created : ' + ctaResult);
            
            List<CampaignMember> cmList = [Select Id, LeadId from CampaignMember where LeadId =: leadList[0].Id];
            System.assert(cmList.size() == 1, 'Campaign member should be created');
            System.assert(cmList[0].LeadId == leadList[0].Id, 'Campaign member should be created for same Lead');
            
            // Convert the lead
            Lead c2aLead = [Select Id, Status from Lead where Parent_Lead__c = :leadList[0].Id];
            c2aLead.Lead_Qualification_Status__c = 'Converted';
            c2aLead.Product_Line__c = 'Media';
            c2aLead.ANUM_Description__c = 'NA';
            c2aLead.Authority__c = 'NA';
            c2aLead.Need__c = 'NA';
            c2aLead.Urgency__c = 'NA';
            c2aLead.Money__c = 'NA';
            c2aLead.QFA_Meeting_Date__c = date.today();
            update c2aLead;
            
            Lead ctaLeadConverted = [Select Id, Status from Lead where Parent_Lead__c = :leadList[0].Id];
            System.assert(ctaLeadConverted.Status == 'Converted', 'First CTA lead must be in converted state');
            
            // Create another CTA if the exiting linked CTA is in closed or ocnverted state.
            String secondCTAResult = GSM_Controller_LA_LeadFromContact.createLeadFromContact(la.Id);
            System.assert(!secondCTAResult.contains('Error'), 'CTA should be created : ' + secondCTAResult);
            System.assert(secondCTAResult != ctaResult, 'BOTH CTAs should be different');
        }
        Test.stopTest();
    }
    
    static testmethod void PersonWithCTALinked_CTALinkedSuccessfully()  {
        User SDR = [select id from user where profile.name='Sales Development Representative' and isactive=true limit 1];
        Test.startTest();
        System.runAs(SDR){
            Account testAccount = [select Id, name from Account where Name = 'Test Account2'];
            LiveChatTranscript la = [Select id,Contact.Id,LeadId,Lead.Name from LiveChatTranscript limit 1];
            Integer numberOfLeads = 1;
            List<Lead> leadList = CreateMarketoLeads(numberOfLeads, testAccount);
            insert leadList;
            
            Id AkamaiRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Akamai Lead').getRecordTypeId();
            Lead testLead = new Lead();
            testLead.Associated_Account__c = testAccount.Id;
            testLead.recordTypeId = AkamaiRecordTypeId;
            testLead.email = 'testSearchResult002@akamai.com';
            testLead.company = 'Test Company2';
            testLead.firstname = 'Jane';
            testLead.lastname = 'Doe';
            testLead.Parent_Lead__c = leadList[0].Id;
            insert testLead;
            
            
            String returnValue = MARIT_CreateOrLinkToLiveChatController.LinkPersonToLiveChat(la.Id, leadList[0].Id);
            System.assert(returnValue.contains(leadList[0].LastName), 'Lead must be linked to live chat');
            
            String result = GSM_Controller_LA_LeadFromContact.validateTranscriptRecord(la.Id);
            System.assert(result.contains('Success'), 'No Validation issue before creating CTA : ' + result);
            
            String ctaResult = GSM_Controller_LA_LeadFromContact.isLeadPresent(la.Id);
            System.assert(ctaResult.contains(testLead.Id), 'CTA should be present');
            
            String linkedCTA = GSM_Controller_LA_LeadFromContact.linkC2AToLiveChat(la.Id, testLead.Id);
            System.assert(linkedCTA.contains(testLead.Id), 'CTA should be present');
            
            LiveChatTranscript laFinal = [Select id,Contact.Id,LeadId,Lead.Name, C2A_Lead_Id__c from LiveChatTranscript limit 1];
            System.assert(laFinal.C2A_Lead_Id__c == testLead.Id, 'Linked CTA must be same as previous CTA');
        }
        Test.stopTest();
    }
    
    private static List<Lead> CreateMarketoLeads(Integer leadCount, Account testAccount) {
        Id marketoRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
        List<Lead> leadList = new List<Lead>();
        for(integer i =0 ; i< leadCount ; i++) {
            Lead lObj = new Lead();
            lObj.RecordTypeId = marketoRecordTypeId;
            lObj.FirstName = 'Test';
            lObj.LastName = 'ML00' + (i+1);
            lObj.Email = lObj.FirstName + lObj.LastName + '@akamai.com';
            lObj.Associated_Account__c = testAccount.Id;
            lObj.Company = 'Test Company';
            lObj.Country = 'USA';
            lObj.State = 'TX';
            leadList.add(lObj);
        }
        return leadList;
    }
    private static List<Contact> CreateContacts(Integer contactCount, Account testAccount) {
        List<Contact> conList = new List<Contact>();
        for(integer i =0 ; i< contactCount ; i++) {
            Contact conObj = new Contact();
            conObj.FirstName = 'Test';
            conObj.LastName = 'Contact00' + (i+1);
            conObj.Email = conObj.FirstName + conObj.LastName + '@akamai.com';
            conObj.AccountId = testAccount.Id;
            conList.add(conObj);
        }
        return conList;
    }
}