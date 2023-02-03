@isTest
private class LeanData_Account_Match_Controller_Test {
    
    @isTest static void updateMultipleAccountForLeadTest()
    {
        Test.startTest();
        List<Account> listOfTestAccounts = (List<Account>) new SObjectBuilder(Account.sObjectType)
                .eagerPopulate()
                .put(Account.Vertical__c, 'Gaming')
                .put(Account.Sub_Vertical__c, 'Gaming')
                .put(Account.Type, 'Lead')
                .count(2)
                .create()
                .getRecords();
        Id marketoRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
        Id akamaiRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Akamai Lead').getRecordTypeId();
        
        Lead l1 = new Lead();
        l1.RecordTypeId = marketoRecordTypeId;
        l1.email = 'test1@akamai.com.invalid';
        l1.Associated_Account__c = listOfTestAccounts[0].id;
        l1.status = 'New';
        l1.firstname = 'LeanData';
        l1.lastname = 'AccountMatchTest1';
        l1.Company = 'Test Company';
        l1.Associated_Contact__c=null;
        insert l1;
        
        Lead l2 = new Lead();
        l2.RecordTypeId = akamaiRecordTypeId;
        l2.email = 'test2@akamai.com.invalid';
        l2.Associated_Account__c = listOfTestAccounts[0].id;
        l2.LeanData__Reporting_Matched_Account__c = listOfTestAccounts[1].id;
        l2.status = 'New';
        l2.Parent_Lead__c = l1.Id;
        l2.firstname = 'LeanData';
        l2.lastname = 'AccountMatchTest2';
        l2.Company = 'Test Company';
        l2.Associated_Contact__c=null;
        insert l2;
        
        List<Id> lst1 = new List<Id>();
        lst1.add(l1.Id);
        
        List<Id> lst2 = new List<Id>();
        lst2.add(l2.Id);
        
        String message1 = LeanData_Account_Match_Controller.updateMultipleAccountControl(null, lst1);
        String message2 = LeanData_Account_Match_Controller.updateMultipleAccountControl('Lead', lst2);
        
        Lead l = new Lead();
        l.RecordTypeId = marketoRecordTypeId;
        l.email = 'test@akamai.com.invalid';
        l.Associated_Account__c = listOfTestAccounts[0].id;
        l.LeanData__Reporting_Matched_Account__c = listOfTestAccounts[1].id;
        l.status = 'New';
        l.firstname = 'LeanData';
        l.lastname = 'AccountMatchTest';
        l.Company = 'Test Company';
        l.Associated_Contact__c=null;
        insert l;
        List<Id> lst = new List<Id>();
        lst.add(l.Id);
        String message = LeanData_Account_Match_Controller.updateMultipleAccountControl('Lead', lst);
        System.assert(message == 'Success');
        Test.stopTest();
    }
    @isTest static void updateMultipleAccountForContactTest()
    {
        
        Test.startTest();
        List<Account> listOfTestAccounts = (List<Account>) new SObjectBuilder(Account.sObjectType)
                .eagerPopulate()
                .put(Account.Vertical__c, 'Gaming')
                .put(Account.Sub_Vertical__c, 'Gaming')
                .count(2)
                .create()
                .getRecords();
        List<Contact> con = (List<Contact>) new SObjectBuilder(Contact.sObjectType)
            	.eagerPopulate()
            	.put(Contact.LeanData_Reporting_Matched_Account__c,listOfTestAccounts[0].Id)
            	.put(Contact.AccountId,listOfTestAccounts[1].Id)
            	.count(1)
            	.create()
            	.getRecords();
        List<Contact> con1 = (List<Contact>) new SObjectBuilder(Contact.sObjectType)
            	.eagerPopulate()
            	.put(Contact.AccountId,listOfTestAccounts[1].Id)
            	.count(1)
            	.create()
            	.getRecords();
        List<Id> lst = new List<Id>();
        lst.add(con[0].Id);
        List<Id> lst1 = new List<Id>();
        lst1.add(con1[0].Id);
        String message = LeanData_Account_Match_Controller.updateMultipleAccountControl('Contact', lst);
        String message1 = LeanData_Account_Match_Controller.updateMultipleAccountControl(null, lst1);
        
        System.assert(message == 'Success');
        Test.stopTest();
        
    }
    @isTest static void testPageControl()
    {
        
        Test.startTest();
        Id marketoRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
        List<Account> listOfTestAccounts = (List<Account>) new SObjectBuilder(Account.sObjectType)
                .eagerPopulate()
                .put(Account.Vertical__c, 'Gaming')
                .put(Account.Sub_Vertical__c, 'Gaming')
                .count(2)
                .create()
                .getRecords();
        /*List<sObject> leads = (List<Lead>) new SObjectBuilder(Lead.sObjectType)
            	.eagerPopulate()
            	.put(Lead.LeanData__Reporting_Matched_Account__c,listOfTestAccounts[0].Id)
            	.put(Lead.Associated_Account__c,listOfTestAccounts[1].Id)
            	.count(2)
            	.create()
            	.getRecords();*/
        Lead l1 = new Lead();
        l1.RecordTypeId = marketoRecordTypeId;
        l1.email = 'test@akamai.com.invalid1';
        l1.Associated_Account__c = listOfTestAccounts[0].id;
        l1.LeanData__Reporting_Matched_Account__c = listOfTestAccounts[1].id;
        l1.status = 'New';
        l1.firstname = 'LeanData1';
        l1.lastname = 'AccountMatchTest1';
        l1.Company = 'Test Company';
        l1.Associated_Contact__c=null;
        insert l1;
        Lead l2 = new Lead();
        l2.RecordTypeId = marketoRecordTypeId;
        l2.email = 'test@akamai.com.invalid2';
        l2.Associated_Account__c = listOfTestAccounts[0].id;
        l2.LeanData__Reporting_Matched_Account__c = listOfTestAccounts[1].id;
        l2.status = 'New';
        l2.firstname = 'LeanData2';
        l2.lastname = 'AccountMatchTest2';
        l2.Company = 'Test Company';
        l2.Associated_Contact__c=null;
        insert l2;
        List<Lead> leads = [Select id,name from Lead where Lead_Record_Type__c = 'Marketo Lead' limit 2];
        
        system.debug('IDs::'+l1.Id+'::'+l2.Id);
        string message = null;
        if(leads!=null && !leads.isEmpty())
        {
            system.debug(Logginglevel.ERROR,'Entered Page Lead Control::'+leads);
            ApexPages.StandardSetController sc = null;
            try
            {
				sc = new ApexPages.StandardSetController(leads);
            }
            catch(Exception e)
            {
                system.debug(e.getMessage());
            }
            LeanData_Account_Match_Controller.getUIThemeDescription();
            system.debug(Logginglevel.ERROR,'Entered Standard Controller::'+sc);
            LeanData_Account_Match_Controller testController = new LeanData_Account_Match_Controller(sc);
            system.debug(Logginglevel.ERROR,'Entered LeanData Controller::'+testController);
            PageReference pageRef = Page.LeanData_Account_Match_Page;
            system.debug(Logginglevel.ERROR,'Entered Page ref::'+pageRef);
            Test.setCurrentPage(pageRef);
            List<Id> leadIds = new List<Id>();
            for(sObject l: leads)
            {
                leadIds.add(l.Id);
            }
            message = LeanData_Account_Match_Controller.updateMultipleAccountControl('Lead', leadIds);
        }
		system.assert(message == 'Success');
        Test.stopTest();
    }
    @isTest static void testCheckRecords()
    {
        Test.startTest();
        Id akamaiRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Akamai Lead').getRecordTypeId();
        Id marketoRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
        List<Account> listOfTestAccounts = (List<Account>) new SObjectBuilder(Account.sObjectType)
                .eagerPopulate()
                .put(Account.Vertical__c, 'Gaming')
                .put(Account.Sub_Vertical__c, 'Gaming')
                .count(2)
                .create()
                .getRecords();
        List<Contact> con = (List<Contact>) new SObjectBuilder(Contact.sObjectType)
            	.eagerPopulate()
            	.put(Contact.AccountId,listOfTestAccounts[1].Id)
            	.count(1)
            	.create()
            	.getRecords();
        List<Lead> leads1 = (List<Lead>) new SObjectBuilder(Lead.sObjectType)
            	.eagerPopulate()
            	.put(Lead.Associated_Account__c,listOfTestAccounts[1].Id)
            	.put(Lead.RecordTypeId,marketoRecordTypeId)
            	.count(1)
            	.create()
            	.getRecords();
        List<Lead> leads2 = (List<Lead>) new SObjectBuilder(Lead.sObjectType)
            	.eagerPopulate()
            	.put(Lead.LeanData__Reporting_Matched_Account__c,listOfTestAccounts[0].Id)
            	.put(Lead.Associated_Account__c,listOfTestAccounts[1].Id)
            	.put(Lead.RecordTypeId,marketoRecordTypeId)
            	.count(1)
            	.create()
            	.getRecords();
        List<Lead> leads = (List<Lead>) new SObjectBuilder(Lead.sObjectType)
                .eagerPopulate()
                .put(Lead.LeanData__Reporting_Matched_Account__c,listOfTestAccounts[0].Id)
                .put(Lead.Associated_Account__c,listOfTestAccounts[1].Id)
                .put(Lead.RecordTypeId,akamaiRecordTypeId)
                .put(Lead.Parent_Lead__c,leads1[0].Id)
                .count(1)
                .create()
                .getRecords();
        List<Id> leadIds = new List<Id>();
        leadIds.add(leads[0].Id);
        List<Id> leadIds1 = new List<Id>();
        leadIds1.add(leads1[0].Id);
        List<Id> leadIds2 = new List<Id>();
        leadIds2.add(leads2[0].Id);
        List<Id> contactIds = new List<Id>();
        contactIds.add(con[0].Id);
        List<Id> emptyIds = new List<Id>();
        string leadMessage = LeanData_Account_Match_Controller.checkRecords(null,leadIds);
        string contactMessage = LeanData_Account_Match_Controller.checkRecords('Contact', contactIds);
        string leadMessage1 = LeanData_Account_Match_Controller.checkRecords('Lead', leadIds1);
        string emptyListRecords = LeanData_Account_Match_Controller.checkRecords('Lead', emptyIds);
        string leadMessage2 = LeanData_Account_Match_Controller.checkRecords('Lead', leadIds2);
        system.assert(leadMessage!= null);
        system.assert(contactMessage!=null);
        system.assert(leadMessage1!=null);
        Test.stopTest();
        
    }

}