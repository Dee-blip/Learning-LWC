/* History:
* =========================
* @author Himanshu Verma,  20th June 2018  
MARIT-539
*/
@isTest(seeAllData=false)
public class MARIT_CreateOrLinkToLiveChatTest {
    // Setup method to create test data.
    @testSetup
    static void setupMethod() 
    {
        Account acc = utilTestClass.CreateAccount('Test Account2');
        insert acc;
        
        // Create contact
        List<Contact> conList = new List<Contact>();
        Contact con = utilTestClass.CreateContact('Test First','Test Contact');
        con.AccountId = acc.Id;
        con.email = 'testContactLiveChat@akamai.com';
        insert con;
        
        LiveChatVisitor lcv = new LiveChatVisitor();
        insert lcv;
        LiveChatTranscript lct = new LiveChatTranscript();
        lct.LiveChatVisitorId = lcv.id;
        insert lct;
    }
    
    public static testmethod void Test_SearchLeadAndContact() 
    {
        Account testAccount = [select Id, name from Account where Name = 'Test Account2'];
        Id marketoRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
        Lead testLead = new Lead();
        testLead.Associated_Account__c = testAccount.Id;
        testLead.recordTypeId = marketoRecordTypeId;
        testLead.email = 'testSearchResult002@akamai.com';
        testLead.status = 'New';
        testLead.company = 'Test Company2';
        testLead.firstname = 'Jane';
        testLead.lastname = 'Doe';
        testLead.street = 'Test street';
        testLead.city = 'Test City';
        testLead.state = 'Test state';
        testLead.PostalCode  = '201323';
        testLead.country = 'USA';
        insert testLead;
        
        Id [] fixedSearchResults= new Id[1];
        fixedSearchResults[0] = testLead.Id;
        Test.setFixedSearchResults(fixedSearchResults);
        
        List<String> returnValue = MARIT_CreateOrLinkToLiveChatController.searchForIds(testLead.lastname);
        System.assert(returnValue[0].contains(testLead.Id), 'Query must return the valid data');
        
        Contact con = [Select Id, LastName, Email from Contact where Email = 'testContactLiveChat@akamai.com'];
        fixedSearchResults[0] = con.Id;
        Test.setFixedSearchResults(fixedSearchResults);
        
        returnValue = MARIT_CreateOrLinkToLiveChatController.searchForIds(con.LastName);
        System.assert(returnValue[0].contains(con.Id), 'Query must return the valid data');
    }
    
    public static testmethod void Test_LinkLeadToLiveChat() 
    {
        Account testAccount = [select Id, name from Account where Name = 'Test Account2'];
        LiveChatTranscript la = [Select id,Contact.Id,LeadId,Lead.Name from LiveChatTranscript limit 1]; 
        Id marketoRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
        Lead testLead = new Lead();
        testLead.Associated_Account__c = testAccount.Id;
        testLead.recordTypeId = marketoRecordTypeId;
        testLead.email = 'testSearchResult002@akamai.com';
        testLead.status = 'New';
        testLead.company = 'Test Company2';
        testLead.firstname = 'Jane';
        testLead.lastname = 'Doe';
        testLead.street = 'Test street';
        testLead.city = 'Test City';
        testLead.state = 'Test state';
        testLead.PostalCode  = '201323';
        testLead.country = 'USA';
        insert testLead;
        
        String returnValue = MARIT_CreateOrLinkToLiveChatController.LinkPersonToLiveChat(la.Id, testLead.Id);
        System.assert(returnValue.contains('Jane Doe'), 'Lead must be linked to live chat');
    }
    
    public static testmethod void Test_LinkContactToLiveChat() 
    {
        //Account testAccount = [select Id, name from Account where Name = 'Test Account2'];
        LiveChatTranscript la = [Select id,ContactId,LeadId,Lead.Name from LiveChatTranscript limit 1]; 
        Contact con = [Select Id, LastName, Email from Contact where Email = 'testContactLiveChat@akamai.com'];
        Id businessContactId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Business Contact').getRecordTypeId();
        /*Contact testContact = new Contact();
        testContact.AccountId = testAccount.Id;
        testContact.recordTypeId = businessContactId;
        testContact.email = 'testContactLinked002@akamai.com';
        testContact.firstname = 'John';
        testContact.lastname = 'Doe';
        insert testContact;*/
        
        String returnValue = MARIT_CreateOrLinkToLiveChatController.LinkPersonToLiveChat(la.Id, con.Id);
        System.assert(returnValue.contains(con.LastName), 'Contact must be linked to live chat');
    }
    
    public static testmethod void Test_CheckIfLCAlreadyLinked_ContactLinked() {
        String result = MARIT_CreateOrLinkToLiveChatController.CheckIfLCAlreadyLinked('');
        System.assertEquals(null, result);
        LiveChatTranscript la = [Select id,ContactId,LeadId,Lead.Name from LiveChatTranscript limit 1]; 
        Contact con = [Select Id, LastName, Email from Contact where Email = 'testContactLiveChat@akamai.com'];
        la.ContactId = con.id;
        update la;
        String resultafterContactLinked = MARIT_CreateOrLinkToLiveChatController.CheckIfLCAlreadyLinked(la.Id);
        System.assert(resultafterContactLinked.contains(con.LastName), 'Linked Contact must show up');
    }
    
    public static testmethod void Test_CheckIfLCAlreadyLinked_LeadLinked() {
        Account testAccount = [select Id, name from Account where Name = 'Test Account2'];
        LiveChatTranscript la = [Select id,Contact.Id,LeadId,Lead.Name from LiveChatTranscript limit 1]; 
        Id marketoRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
        Lead testLead = new Lead();
        testLead.Associated_Account__c = testAccount.Id;
        testLead.recordTypeId = marketoRecordTypeId;
        testLead.email = 'testSearchResult002@akamai.com';
        testLead.company = 'Test Company2';
        testLead.firstname = 'Jane';
        testLead.lastname = 'Doe';
        insert testLead;
        la.LeadId = testLead.id;
        update la;
        String resultafterContactLinked = MARIT_CreateOrLinkToLiveChatController.CheckIfLCAlreadyLinked(la.Id);
        System.assert(resultafterContactLinked.contains('Jane Doe'), 'Linked Contact must show up');
    }
    
    public static testmethod void Test_CheckIfLCAlreadyLinked_LeadLinkedWithConvertedContact() {
        Account testAccount = [select Id, name from Account where Name = 'Test Account2'];
        LiveChatTranscript la = [Select id,Contact.Id,LeadId,Lead.Name from LiveChatTranscript limit 1]; 
        Contact con = [select id from contact limit 1];
        Id marketoRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
        Lead testLead = new Lead();
        testLead.Associated_Account__c = testAccount.Id;
        testLead.recordTypeId = marketoRecordTypeId;
        testLead.email = 'testSearchResult002@akamai.com';
        testLead.company = 'Test Company2';
        testLead.firstname = 'Jane';
        testLead.lastname = 'Doe';
        testLead.Marketo_Convert_to_Contact__c = true;
        insert testLead;
        
        Lead lObj = [Select Id, ConvertedContactId from Lead where Id =:testLead.Id];
        la.LeadId = testLead.id;
        update la;
        
        String resultafterContactLinked = MARIT_CreateOrLinkToLiveChatController.CheckIfLCAlreadyLinked(la.Id);
        LiveChatTranscript laFinal = [select id, contactId, LeadId from LiveChatTranscript where id =:la.Id];
        System.assertEquals(lObj.ConvertedContactId, laFinal.contactId);
        System.assert(resultafterContactLinked.contains('Jane Doe'), 'Linked Contact must show up');
    }
    
    public static testmethod void Test_SaveMarketoLead() {
        Account testAccount = [select Id, name from Account where Name = 'Test Account2'];
        LiveChatTranscript la = [Select id,Contact.Id,LeadId,Lead.Name from LiveChatTranscript limit 1]; 
        Id marketoRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
        Lead testLead = new Lead();
        testLead.Associated_Account__c = testAccount.Id;
        testLead.recordTypeId = marketoRecordTypeId;
        testLead.Email = 'testSearchResult002@akamai.com';
        testLead.Company = 'Test Company2';
        testLead.FirstName = 'Jane';
        testLead.LastName = 'Doe';
        testLead.Phone = '6464636364';
        testLead.Country = 'India';
        testLead.State = 'Delhi';
        testLead.Title = 'Test Title';
        
        String resultafterLeadSaved = MARIT_CreateOrLinkToLiveChatController.SaveMarketoLeadAndLinkToChat(testLead, la.Id);
        LiveChatTranscript laFinal = [select id, contactId, LeadId from LiveChatTranscript where id =:la.Id];
        Lead lObj = [Select Id, ConvertedContactId from Lead where Email = 'testSearchResult002@akamai.com'];
        System.assert(resultafterLeadSaved.contains('Jane Doe'), 'Linked Lead must show up');
        System.assertEquals(lObj.Id, laFinal.LeadId);
    }
    
    public static testmethod void Test_getLiveChat() {
        LiveChatTranscript la = [Select id,Contact.Id,LeadId,Lead.Name from LiveChatTranscript limit 1];
        LiveChatTranscript laRec = MARIT_CreateOrLinkToLiveChatController.getLiveChat(la.Id);
        System.assert(laRec!=null, 'Chat Transcript must not be null');
    }
    
    public static testmethod void Test_NoC2ALinkedToLiveChat() {
        Account testAccount = [select Id, name from Account where Name = 'Test Account2'];
        LiveChatTranscript la = [Select id,Contact.Id,LeadId,Lead.Name from LiveChatTranscript limit 1];
        String result = MARIT_CreateOrLinkToLiveChatController.IsC2ALinkedToLiveChat(la.Id);
        System.assertEquals('Successful', result);
    }
    
    public static testmethod void Test_C2ALinkedToLiveChat() {
        Account testAccount = [select Id, name from Account where Name = 'Test Account2'];
        LiveChatTranscript la = [Select id,Contact.Id,LeadId,Lead.Name from LiveChatTranscript limit 1];
        Contact con = [Select Id, LastName, Email from Contact where Email = 'testContactLiveChat@akamai.com'];
        
        Id AkamaiRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Akamai Lead').getRecordTypeId();
        Lead testLead = new Lead();
        testLead.Associated_Account__c = testAccount.Id;
        testLead.recordTypeId = AkamaiRecordTypeId;
        testLead.email = 'testSearchResult002@akamai.com';
        testLead.company = 'Test Company2';
        testLead.firstname = 'Jane';
        testLead.lastname = 'Doe';
        testLead.Associated_Contact__c = con.Id;
        insert testLead;
        
        la.C2A_Lead_Id__c = testLead.Id;
        update la;
        
        String resultAfterC2ALinked = MARIT_CreateOrLinkToLiveChatController.IsC2ALinkedToLiveChat(la.Id);
        System.assertEquals('C2A Exists', resultAfterC2ALinked);
    }
}