@isTest
private class CreateCustomContactControllerTest {
    @isTest static void testCreateNewContact_CreatedSuccessfully() {
        String emailAddress = 'CustomContactWorkflow@gmail.com';
        Account newAccount = new Account();
        newAccount.Name = 'CustomContactWorkflowAccount';
        newAccount.BillingCountry = 'India';
        newAccount.BillingState = 'DELHI';
        insert newAccount;
        
        String recordtypeID = [select Id from RecordType where DeveloperName = 'Business_Contact'].id;
        
        Contact c = new Contact(AccountId = newAccount.id,
                                lastName = 'CustomContactWorkflowContact',
                                email = emailAddress);
        String conInfo = CreateCustomContactController.CheckOrCreateNewContact(c, recordtypeID);
        List<Contact> conList = [Select Id, LastName, Email from Contact where Email = :emailAddress];
        System.assertEquals(1,conList.size());
    }
    
    @isTest static void testCreateNewContact_CreationFailedDMLException() {
        String emailAddress = 'CustomContactWorkflow@gmail.com';
        Account newAccount = new Account();
        newAccount.Name = 'CustomContactWorkflowAccount';
        newAccount.BillingCountry = 'India';
        newAccount.BillingState = 'DELHI';
        insert newAccount;
        
        String recordtypeID = [select Id from RecordType where DeveloperName = 'Business_Contact'].id;
        
        Contact c = new Contact(AccountId = newAccount.id,
                                email = emailAddress);
        String conInfo = CreateCustomContactController.CheckOrCreateNewContact(c, recordtypeID);
        List<Contact> conList = [Select Id, LastName, Email from Contact where Email = :emailAddress];
        System.assertEquals(0,conList.size());
    }
    
     @isTest static void testFetchRecord_EmptyContactRecordId_DefaultRecordIdFetched() {
        
        RecordType rec = CreateCustomContactController.FetchRecordBasedOnId('');
        System.assertNotEquals(null,rec);
    }
    
    @isTest static void testCreateNewContact_CheckLeadExists() {
        String emailAddress = 'CustomContactWorkflow@gmail.com';
        Account newAccount = new Account();
        newAccount.Name = 'CustomContactWorkflowAccount';
        newAccount.BillingCountry = 'India';
        newAccount.BillingState = 'DELHI';
        insert newAccount;
        
        String marketoLeadId = [select Id from RecordType where DeveloperName = 'Marketo_Lead'].id;
        Lead l = new Lead();
		l.recordTypeId = marketoLeadId; // Marketo lead
		l.email = emailAddress;
		l.company = 'Test Company';
		l.lastname = 'TestLead';
        l.Associated_Account__c = newAccount.id;
		insert l;
        String recordtypeID = [select Id from RecordType where DeveloperName = 'Business_Contact'].id;
        Contact c = new Contact(AccountId = newAccount.id,
                                lastName = 'CustomContactWorkflowContact',
                                email = emailAddress);
        String conInfo = CreateCustomContactController.CheckOrCreateNewContact(c, recordtypeID);
        List<Contact> conList = [Select Id, LastName, Email from Contact where Email = :emailAddress];
        System.assertEquals(0,conList.size());
    }
    
    @isTest static void testCreateNewContact_CheckContactExists() {
        String emailAddress = 'CustomContactWorkflow@gmail.com';
        Account newAccount = new Account();
        newAccount.Name = 'CustomContactWorkflowAccount';
        newAccount.BillingCountry = 'India';
        newAccount.BillingState = 'DELHI';
        insert newAccount;
        
        Contact c1 = new Contact(AccountId = newAccount.id,
                                lastName = 'CustomContactWorkflowContact',
                                email = emailAddress);
        insert c1;
        String recordtypeID = [select Id from RecordType where DeveloperName = 'Business_Contact'].id;
        Contact c2 = new Contact(AccountId = newAccount.id,
                                lastName = 'CustomContactWorkflowContact',
                                email = emailAddress);
        String conInfo = CreateCustomContactController.CheckOrCreateNewContact(c2, recordtypeID);
        List<Contact> conList = [Select Id, LastName, Email from Contact where Email = :emailAddress];
        System.assertEquals(1,conList.size());
    }
    
    @isTest static void testIgnoreAndCreateNewContact() {
        String emailAddress = 'CustomContactWorkflow@gmail.com';
        Account newAccount = new Account();
        newAccount.Name = 'CustomContactWorkflowAccount';
        newAccount.BillingCountry = 'India';
        newAccount.BillingState = 'DELHI';
        insert newAccount;
        String recordtypeID = [select Id from RecordType where DeveloperName = 'Business_Contact'].id;
        Contact c = new Contact(AccountId = newAccount.id,
                                lastName = 'CustomContactWorkflowContact',
                                email = emailAddress);

        CreateCustomContactController.IgnoreAndCreateNewContact(c, recordtypeID);
        List<Contact> conList = [Select Id, LastName, Email from Contact where Email = :emailAddress];
        System.assertEquals(1,conList.size());
    }
    
    @isTest static void testConvertExistingLeadToContact() {
        String emailAddress = 'CustomContactWorkflow@gmail.com';
        Account newAccount = new Account();
        newAccount.Name = 'CustomContactWorkflowAccount';
        newAccount.BillingCountry = 'India';
        newAccount.BillingState = 'DELHI';
        insert newAccount;
        
        String marketoLeadId = [select Id from RecordType where DeveloperName = 'Marketo_Lead'].id;
        Lead l = new Lead();
        l.recordTypeId = marketoLeadId; // Marketo lead
        l.email = emailAddress;
        l.company = 'Test Company';
        l.lastname = 'TestLead';
        l.Associated_Account__c = newAccount.id;
        insert l;

        String conInfo = CreateCustomContactController.ConvertExistingLeadToContact(emailAddress);
        List<Contact> conList = [Select Id, LastName, Email from Contact where Email = :emailAddress];
        System.assertEquals(1,conList.size());
    }
    
    @isTest static void testConvertExistingLeadToContact_LeadDoesNotExists() {
		String emailAddress = 'CustomContactWorkflow@gmail.com';
		Account newAccount = new Account();
		newAccount.Name = 'CustomContactWorkflowAccount';
		newAccount.BillingCountry = 'India';
		newAccount.BillingState = 'DELHI';
		insert newAccount;

		String conInfo = CreateCustomContactController.ConvertExistingLeadToContact(emailAddress);
		List<Contact> conList = [Select Id, LastName, Email from Contact where Email = :emailAddress];
		System.assertEquals(0,conList.size());
	}
		
    @isTest static void testFetchRecordBasedOnId() {
        String recordtypeID = [select Id from RecordType where DeveloperName = 'Business_Contact'].id;
        RecordType rec = CreateCustomContactController.FetchRecordBasedOnId(recordtypeID);
        System.assertEquals(recordtypeID, rec.Id);
    }
    
    @isTest static void testcheckProfileToShowIgnoreAndCreateButton() {
        User admin = [select id from user where profile.name='System Administrator' and isactive=true limit 1];
        Test.startTest();
            System.runAs(admin){
                Boolean canCreate = CreateCustomContactController.checkProfileToShowIgnoreAndCreateButton();
                System.assertEquals(canCreate, true, 'User can Ignore and create contact.');
            } 
        Test.stopTest();
    }
}