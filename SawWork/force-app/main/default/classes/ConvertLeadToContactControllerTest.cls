@isTest(seeAllData = false)
public with sharing class ConvertLeadToContactControllerTest 
{
	static{
        utilTestClass.insertCustomSettings();
    }
    static testmethod void oneTestToTestThemAll()
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

            Id akamaiRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
            Lead ml = new Lead();
            ml.RecordTypeId = akamaiRecordTypeId;
            ml.email = 'test2@akamai.com.invalid';
            ml.Status = 'New';
            ml.firstname = 'Test';
            ml.lastname = 'Test2';
            ml.Associated_Account__c = account.Id;
            ml.Company = 'Test Company';
            ml.Product_Line__c = 'Media';
            insert ml;

            User SDR = [select id from user where profile.name='Sales Development Representative' and isactive=true limit 1];
			Lead l = new Lead();
			l.Associated_Account__c = account.Id;
			l.email = 'testemail@email.com';
			l.status = 'New';
			l.CurrencyIsoCode = 'USD';
			l.company = 'Test Company';
			l.firstname = 'Test';
			l.lastname = 'Lead';
			l.Product_Line__c = 'Media';
			l.website = 'testwebsite.com';
			l.industry = 'Banking';
			l.street = 'Test street';
			l.city = 'Test City';
			l.state = 'Test state';
			l.PostalCode  = '201323';
			l.country = 'USA';
			l.Primary_Product__c = 'Cloud Networking - Enterprise Application Access';
			l.Services_Hostname__c = 'testwebsite.com';
			l.description = 'Test Description';
			l.Parent_Lead__c = ml.Id;
            l.OwnerId = SDR.id;
			insert l;

    
            Test.startTest();
            
    
            PageReference pageRef1 = Page.Convert_Lead_To_Contact;
            Test.setCurrentPage(pageRef1);
            ConvertLeadToContactController  controller = new ConvertLeadToContactController(new ApexPages.StandardController(l));
            controller.convertLead();
             Test.stopTest();
           
        }
        static testmethod void MarketoLeadToContactConvert_NetworkContact() {
            Account netaccount = utilTestClass.CreateAccount('Test_Account1');
            netaccount.BillingStreet = '#39,7th Cross';
            netaccount.BillingCity   = 'LA';
            netaccount.BillingState = 'CA';
            netaccount.BillingPostalCode = '56005';
            netaccount.BillingCountry = 'USA';
            netaccount.Network_Account__c = true;
            netaccount.Sales_Account__c = false;
            insert netaccount;
            
            Id marketoRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
            Lead ml = new Lead();
            ml.RecordTypeId = marketoRecordTypeId;
            ml.email = 'test20123@akamai123.com';
            ml.firstname = 'Test';
            ml.lastname = 'Test2';
            ml.Associated_Account__c = netaccount.Id;
            ml.Company = 'Test Company';
            insert ml;
            
            User SDR = [select id from user where profile.name='Sales Development Representative' and isactive=true limit 1];
            System.runAs(SDR){
            try {
                PageReference pageRef1 = Page.Convert_Lead_To_Contact;
                Test.setCurrentPage(pageRef1);
                ConvertLeadToContactController  controller = new ConvertLeadToContactController(new ApexPages.StandardController(ml));
                controller.convertLead();
            } catch(Exception e) {
                System.assert(e.getMessage().contains('network contact'));
            }
        }
    }
}