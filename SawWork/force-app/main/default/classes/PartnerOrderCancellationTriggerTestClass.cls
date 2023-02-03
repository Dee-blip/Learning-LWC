/**
   @author: Nagaraj Desai
   SFDC-2587 : Formalize Partner Order Cancellation
 * History:
 * =========================
 * Developer        Date        Description

   Nagaraj Desai    15/Apr/18        Added this test-class for SFDC-2587.
   =========================
   This Test Class Covers:
   1) PartnerOrderCancellation_TriggerClass
   2) PartnerOrderCancellationDetailsTrigger
   3) PartnerOrderCancellation_TriggerHandler
 **/
@isTest(seeAllData = false)
private class PartnerOrderCancellationTriggerTestClass {
        static {
                utilTestClass.insertCustomSettings();
        }

        static testMethod void signlePOCD_Insert() {
                User dmlUser = new User(id=UserInfo.getUserId());
                System.runAs(dmlUser) {
                        ManagedPkgErrorClass.isFromManagedPackage = false;
                        Profile partnerAdminProfile =
                        [select id,name from Profile where Name =:GsmUtilClass.getPRMSettingValue('Partner_Admin_Profile')];

                        Account acc = utilTestClass.CreateAccount('__ Test Account');
                        insert acc;
                        acc.IsPartner = true;
                        acc.Validation_Override__c=true;
                        update acc;

                        Contact newContact = new Contact();
                        newContact.FirstName = 'Test';
                        newContact.LastName = 'Test';
                        newContact.Email ='__testContact'+Math.round(Math.random()*10000000*Math.random())+'@Testing.com';
                        newContact.Phone = '999999';
                        newContact.MailingCountry = 'India';
                        newContact.Title = 'Tester';
                        newContact.AccountId = acc.Id;
                        insert newContact;

                        integer userNumber=1;
                        List<User> updateUserList = new List<User>();
                        User PartnerAdmin=new User(
                                Username='sso1'+userNumber+'@akamai.com',
                                Alias = 'sso1'+userNumber,
                                Email='sso1'+userNumber+'@akamai.com',
                                FirstName='John',
                                LastName='Doe'+userNumber,
                                ProfileId = partnerAdminProfile.Id,
                                LanguageLocaleKey='en_US',
                                LocaleSidKey='en_US',
                                EmailEncodingKey='UTF-8',
                                TimeZoneSidKey='America/Los_Angeles',
                                ContactId = newContact.id,
                                UserPreferencesShowEmailToExternalUsers=true
                                );
                        insert PartnerAdmin;

                        Account accc = new Account();
                        accc.Name = 'TestABC';
                        accc.Vertical__c = 'Gaming';
                        accc.Sub_Vertical__c = 'Console Mfs';
                        insert accc;

                        Test.startTest();
                        Partner_Order_Cancellation_Details__c singlePOCD = new Partner_Order_Cancellation_Details__c();
                        singlePOCD.Reseller_Account__c = accc.Id;
                        Date today = Date.today();
                        Date tomorrow = Date.newInstance(today.year(), today.month(), today.day() + 2);
                        singlePOCD.Cancellation_Request_Date__c = tomorrow;
                        singlePOCD.Customer_Name__c = 'Test Customer';
                        singlePOCD.Unique_Id__c = 'Test UniqueId';
                        singlePOCD.Contract_Id__c = 'Test Contract Id';
                        singlePOCD.Services_To_Cancel__c = 'All Services';
                        singlePOCD.Reason_For_Cancellation__c = 'Other';
                        singlePOCD.Other_Reason_For_Cancellation__c = 'Test Reason';
                        System.runAs(PartnerAdmin) {
                                insert singlePOCD;
                        }
                        Test.stopTest();
                }
        }

        static testMethod void multiplePOCD_Insert() {
                User dmlUser = new User(id=UserInfo.getUserId());
                System.runAs(dmlUser) {
                        ManagedPkgErrorClass.isFromManagedPackage = false;
                        Profile partnerAdminProfile =
                        [select id,name from Profile where Name =:GsmUtilClass.getPRMSettingValue('Partner_Admin_Profile')];

                        Account acc = utilTestClass.CreateAccount('__ Test Account');
                        insert acc;
                        acc.IsPartner = true;
                        acc.Validation_Override__c=true;
                        update acc;

                        Contact newContact = new Contact();
                        newContact.FirstName = 'Test';
                        newContact.LastName = 'Test';
                        newContact.Email ='__testContact'+Math.round(Math.random()*10000000*Math.random())+'@Testing.com';
                        newContact.Phone = '999999';
                        newContact.MailingCountry = 'India';
                        newContact.Title = 'Tester';
                        newContact.AccountId = acc.Id;
                        insert newContact;

                        integer userNumber=1;
                        List<User> updateUserList = new List<User>();
                        User PartnerAdmin=new User(
                                Username='sso1'+userNumber+'@akamai.com',
                                Alias = 'sso1'+userNumber,
                                Email='sso1'+userNumber+'@akamai.com',
                                FirstName='John',
                                LastName='Doe'+userNumber,
                                ProfileId = partnerAdminProfile.Id,
                                LanguageLocaleKey='en_US',
                                LocaleSidKey='en_US',
                                EmailEncodingKey='UTF-8',
                                TimeZoneSidKey='America/Los_Angeles',
                                ContactId = newContact.id,
                                UserPreferencesShowEmailToExternalUsers=true
                                );
                        insert PartnerAdmin;

                        Account accc = new Account();
                        accc.Name = 'TestABC';
                        accc.Vertical__c = 'Gaming';
                        accc.Sub_Vertical__c = 'Console Mfs';
                        insert accc;

                        Test.startTest();
                        List<Partner_Order_Cancellation_Details__c> listOfPOCD = new List<Partner_Order_Cancellation_Details__c>();
                        Integer numberOfRecords = 3;
                        for(Integer ii=1; ii<=numberOfRecords; ii++) {
                                Partner_Order_Cancellation_Details__c singlePOCD1 = new Partner_Order_Cancellation_Details__c();
                                singlePOCD1.Reseller_Account__c = accc.Id;
                                Date today = Date.today();
                                Date tomorrow = Date.newInstance(today.year(), today.month(), today.day() + 2);
                                singlePOCD1.Cancellation_Request_Date__c = tomorrow;
                                singlePOCD1.Customer_Name__c = 'Test Customer' + ii;
                                singlePOCD1.Unique_Id__c = 'Test UniqueId';
                                singlePOCD1.Contract_Id__c = 'Test Contract Id';
                                singlePOCD1.Services_To_Cancel__c = 'All Services';
                                singlePOCD1.Reason_For_Cancellation__c = 'Other';
                                singlePOCD1.Other_Reason_For_Cancellation__c = 'Test Reason';

                                listOfPOCD.add(singlePOCD1);
                        }
                        System.runAs(PartnerAdmin) {
                                insert listOfPOCD;
                        }

                        Test.stopTest();
                }
        }
}