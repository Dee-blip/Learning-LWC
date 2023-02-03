@isTest
public with sharing class GSM_Controller_LA_LeadFromContactTest 
{
    @testSetup static void setupDataForTest() 
    {
        Account acc = utilTestClass.CreateAccount('__Test Account');
        insert acc;
        
        // Create contact
        List<Contact> conList = new List<Contact>();
        Contact con = utilTestClass.CreateContact('__ Test First','__Test Contact');
        con.AccountId = acc.Id;
        con.email = 'test@akamai.com';
        insert con;
        
        LiveChatVisitor lcv = new LiveChatVisitor();
        insert lcv;
        LiveChatTranscript lct = new LiveChatTranscript();
        lct.LiveChatVisitorId = lcv.id;
        insert lct;
    }
    
    // This test validates msgs when no person is linked to chat, then links Contact and then C2A to validate messages
    @isTest static void oneTestToTestThemAll() 
    {
        LiveChatTranscript la = [Select id,Contact.Id,LeadId,Lead.Name from LiveChatTranscript limit 1]; 
        String message = '';
        // Case 1 : When No contact/Lead Linked 
        message = GSM_Controller_LA_LeadFromContact.validateTranscriptRecord(la.Id);
        System.assertEquals(message,'Error: No Contact/Lead linked to chat record. Please link a valid contact/lead and try again.');
        
        // Case 2 : When a Contact is linked
        Contact con = [select id from contact limit 1];
        la.ContactId = con.Id;
        update la;
        message = GSM_Controller_LA_LeadFromContact.validateTranscriptRecord(la.Id);
        System.assertEquals(message,'Success:');
        // Case : When lead is not linked
        System.assertEquals(GSM_Controller_LA_LeadFromContact.isLeadPresent(String.valueof(la.Id)), 'No Lead Present');
        
        // Case 3 : Create Lead from Contact
        message = GSM_Controller_LA_LeadFromContact.createLeadFromContact(la.Id);
        System.assertNotEquals(message,null);
        
        // Case 4 : Associated Lead, Now check for error
        la = [Select id,Contact.Id,LeadId,Lead.Name, C2a_Lead_Id__c from LiveChatTranscript limit 1]; 
        message = GSM_Controller_LA_LeadFromContact.validateTranscriptRecord(la.Id);
        System.assertEquals(message,'Error: A C2A Lead is already Linked to chat record.');
    }
    
    // Test to ensure that no CTA is created when Do no call and email opt out are true
    @isTest static void ctaCreationErrorWhenOptedOut() 
    {
        // Case 5: Error While creating a Lead for a linked contact if the DoNotCall and HasOptedOutOfEmail is checked
        LiveChatTranscript la = [Select id,Contact.Id,LeadId,Lead.Name from LiveChatTranscript limit 1]; 
        Contact con = [select id,DoNotCall,HasOptedOutOfEmail from contact limit 1];
        con.DoNotCall = true;
        con.HasOptedOutOfEmail = true;
        update con;
        la.ContactId = con.Id;
        update la;
        LiveChatTranscript la2 = [Select id,Contact.Id,Contact.DoNotCall,Contact.HasOptedOutOfEmail,LeadId,Lead.Name from LiveChatTranscript limit 1];
        String message = GSM_Controller_LA_LeadFromContact.createLeadFromContact(la.Id);
        System.assertEquals(message,'Error: Cannot create C2A when "Do Not Call" and "Email Opt Out" is checked');
        
    }
    
    // Test ensures that system behaves correctly when person lead is linekd and then CTA is created from person lead
    @isTest static void createLeadWithLinkedLead() 
    {
        Id marketoRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
        Account acc =  [Select id from Account limit 1];
            
        Lead l = utilTestClass.CreateLead();
        l.LastName = 'testmarketoLeadLivechat001';
        l.Company = 'testmarketoLeadLivechat001Company';
        l.Associated_Account__c = acc.Id;
        l.email = 'testmarketoLeadLivechat001@akamai.com';
        l.RecordTypeId = marketoRecordTypeId;
        insert l;
        
        LiveChatTranscript la = [Select id,Contact.Id,LeadId,Lead.Name from LiveChatTranscript limit 1]; 
        String message = '';
        // Case 1 : When a Lead is linked
        la.LeadId = l.Id;
        update la;
        message = GSM_Controller_LA_LeadFromContact.validateTranscriptRecord(la.Id);
        System.assertEquals(message,'Success:');
        // Case 3 : Create CTA Lead from Person Lead
        message = GSM_Controller_LA_LeadFromContact.createLeadFromContact(la.Id);
        System.assertNotEquals(message,null);
        message = GSM_Controller_LA_LeadFromContact.validateTranscriptRecord(la.Id);
        System.assertEquals(message,'Error: A C2A Lead is already Linked to chat record.');
    }
    
    // test ensures Linking of CTA to live chat works as expected
    @isTest static void Test_linkC2AToLiveChat()
    {
        Id marketoRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
        Id AkamaiRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Akamai Lead').getRecordTypeId();
        Account acc = [Select id from Account limit 1];
        
        Lead ml = utilTestClass.CreateLead();
        ml.LastName = 'testmarketoLeadLivechat001';
        ml.Company = 'testmarketoLeadLivechat001Company';
        ml.Associated_Account__c = acc.Id;
        ml.email = 'testmarketoLeadLivechat001@akamai.com';
        ml.RecordTypeId = marketoRecordTypeId;
        insert ml;
        
        Lead l = utilTestClass.CreateLead();
        l.parent_Lead__c = ml.Id;
        l.LastName = 'testakamaiLeadLivechat001';
        l.Company = 'testakamaiLeadLivechat001Company';
        l.Associated_Account__c = acc.Id;
        l.email = 'testakamaiLeadLivechat001@akamai.com';
        l.RecordTypeId = AkamaiRecordTypeId;
        insert l;
        
        LiveChatTranscript la = [Select id,Contact.Id,LeadId,Lead.Name from LiveChatTranscript limit 1];
        String retValue = GSM_Controller_LA_LeadFromContact.linkC2AToLiveChat(la.Id, l.Id);
        System.assertEquals(l.Id, retValue, 'Called function should return valid linked lead id');
    }
    
    // Test ensures that if CTA is linked to live chat it shows up and if not then it returns null
    @isTest static void Test_ShowC2AOnLoad()
    {
        Id marketoRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
        Id AkamaiRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Akamai Lead').getRecordTypeId();
        Account acc = [Select id from Account limit 1];
        
        Lead ml = utilTestClass.CreateLead();
        ml.LastName = 'testmarketoLeadLivechat001';
        ml.Company = 'testmarketoLeadLivechat001Company';
        ml.Associated_Account__c = acc.Id;
        ml.email = 'testmarketoLeadLivechat001@akamai.com';
        ml.RecordTypeId = marketoRecordTypeId;
        insert ml;
        
        Lead l = utilTestClass.CreateLead();
        l.parent_Lead__c = ml.Id;
        l.LastName = 'testakamaiLeadLivechat001';
        l.Company = 'testakamaiLeadLivechat001Company';
        l.Associated_Account__c = acc.Id;
        l.email = 'testakamaiLeadLivechat001@akamai.com';
        l.RecordTypeId = AkamaiRecordTypeId;
        insert l;
        
        LiveChatTranscript la = [Select id,Contact.Id,LeadId,Lead.Name from LiveChatTranscript limit 1];
        String retValue = GSM_Controller_LA_LeadFromContact.ShowC2AOnLoad(la.Id);
        // No CTA linked so it must return null
        System.assertEquals(null, retValue, 'As no C2A is linked, call should return null');
        
        // Link CTA to live chat now
        la.C2A_Lead_Id__c = l.Id;
        update la;
        retValue = GSM_Controller_LA_LeadFromContact.ShowC2AOnLoad(la.Id);
        System.assertEquals(l.Id, retValue, 'Called function should return valid linked C2A lead id');
    }
}