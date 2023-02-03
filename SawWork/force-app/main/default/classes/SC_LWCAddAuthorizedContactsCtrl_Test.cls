/*
************************************************************************************************************
    Author              :   Tejaswini 
    Created             :   27-April-2021
    Purpose             :   Test Class for SC_LWCAddAuthorizedContactsCtrl

	Date                 Developer                  JIRA #          Description                                                      
-----------------------------------------------------------------------------------------------------------
	27 Apr 2021          Tejaswini      			ESESP-4953		SOCC CAR 2 - RunBooks 2

************************************************************************************************************
*/
@isTest
public with sharing class SC_LWCAddAuthorizedContactsCtrl_Test {
    @testSetup
    static void testDataSetup()
    {
        utilTestClass.createCustomSettings();

        // Create Account
        List<Account> lAcc =  new List<Account>();

        Account acc1 = utilTestClass.CreateAccount('TestAccount 1');   
        lAcc.add(acc1);
        
        Account acc2 = utilTestClass.CreateAccount('TestServiceAccount 1');   
        lAcc.add(acc2);
        
        insert lAcc;
        
        //Create Contact
        
        //Account ac = [SELECT Id FROM Account where Name='TestServiceAccount 1' LIMIT 1];
        
        List<Contact> lContact = new List<Contact>();
        
        Contact con1 = new Contact();
        con1.FirstName = 'Testfn1';
        con1.LastName = 'Testln1';
        con1.Email = '__testContact'+Math.round(Math.random()*10000000*Math.random())+'@Testing.com';
        con1.Title= 'Software Engineer';
        con1.AccountId=acc1.Id;
        con1.Primary_Contact_Method__c='Mobile';
        lContact.add(con1);
        
        Contact con2 = new Contact();
        con2.FirstName = 'Testfn2';
        con2.LastName = 'Testln2';
        con2.Email = '__testContact'+Math.round(Math.random()*10000000*Math.random())+'@Testing.com';
        con2.Title= 'Software Engineer';
        con2.AccountId=acc1.Id;
        con2.Primary_Contact_Method__c='Phone';
        lContact.add(con2);
        
        Contact con3 = new Contact();
        con3.FirstName = 'Testfn3';
        con3.LastName = 'Testln3';
        con3.Email = '__testContact'+Math.round(Math.random()*10000000*Math.random())+'@Testing.com';
        con3.Title= 'Software Engineer II';
        con3.AccountId=acc1.Id;
        con3.Primary_Contact_Method__c='Mobile';
        lContact.add(con3);
        
        Contact con4 = new Contact();
        con4.FirstName = 'Testfn4';
        con4.LastName = 'Testln4';
        con4.Email = '__testContact'+Math.round(Math.random()*10000000*Math.random())+'@Testing.com';
        con4.Title= 'Software Engineer II';
        con4.AccountId=acc2.Id;
        con4.Primary_Contact_Method__c='Phone';
        lContact.add(con4);
        
        Contact con5 = new Contact();
        con5.FirstName = 'Testfn5';
        con5.LastName = 'Testln5';
        con5.Email = '__testContact'+Math.round(Math.random()*10000000*Math.random())+'@Testing.com';
        con5.Title= 'Software Engineer II';
        con5.AccountId=acc2.Id;
        con5.Primary_Contact_Method__c='Mobile';
        lContact.add(con5);
        
        Contact con6 = new Contact();
        con6.FirstName = 'Testfn6';
        con6.LastName = 'Testln6';
        con6.Email = '__testContact'+Math.round(Math.random()*10000000*Math.random())+'@Testing.com';
        con6.Title= 'Software Engineer III';
        con6.AccountId=acc2.Id;
        con6.Primary_Contact_Method__c='Phone';
        lContact.add(con6);
        
        insert lContact;
        
        //Create PD
        
        Policy_Domain__c pd = new Policy_Domain__c();
        pd.Account_name__c = acc1.Id;
        pd.Name = 'test PD';
        pd.Product__c  = 'PLX';
        pd.Policy_Domain_State__c = 'Active';
        insert pd;

        //Create service account pd mapping record
        
        List<Service_Account_PD_Mapping__c> lServiceAccPdMap = new List<Service_Account_PD_Mapping__c>();
        
        Service_Account_PD_Mapping__c serviceAccPdMap1=new Service_Account_PD_Mapping__c();
        serviceAccPdMap1.Policy_Domain__c=pd.Id;
        serviceAccPdMap1.Service_Account__c=acc2.Id;
        lServiceAccPdMap.add(serviceAccPdMap1);
        
        
        insert lServiceAccPdMap;
        
        //Create authorised contact record
        
        List<Authorized_Contact__c> lAuthContact = new List<Authorized_Contact__c>();
        
        Authorized_Contact__c authCon1 = new Authorized_Contact__c();
        authCon1.Contact_Name__c = con3.Id ;
        authCon1.Policy_Domain__c = pd.Id;
        authCon1.Product_Interests__c = 'All';
        
        lAuthContact.add(authCon1);
        
        Authorized_Contact__c authCon2 = new Authorized_Contact__c();
        authCon2.Contact_Name__c = con6.Id ;
        authCon2.Policy_Domain__c = pd.Id;
        authCon2.Product_Interests__c = 'All';
        
        lAuthContact.add(authCon2);
        
        insert lAuthContact;
        
    }
    
    public static testMethod void associateContactTest()
    {
        
        Policy_Domain__c pd=[Select Id, Account_Name__c from Policy_Domain__c LIMIT 1 ];
        
        List<Service_Account_PD_Mapping__c> serviceAccountPDList =[Select id, Service_Account__c from Service_Account_PD_Mapping__c where Policy_Domain__c =: pd.Id];
        List<Id> serviceAccountIDList = new List<Id>();
        //Set<Id> setServiceAccountRecords;
        for(Service_Account_PD_Mapping__c SAPDMap : serviceAccountPDList){
                serviceAccountIDList.add(SAPDMap.Service_Account__c);
        }
        
        List<Contact> lCon=[Select Id from Contact WHERE  (AccountId =: pd.Account_Name__c OR AccountId =: serviceAccountIDList) AND AccountId != NULL AND
                                                Id NOT In (SELECT Contact_Name__c FROM Authorized_Contact__c WHERE Policy_Domain__c  =:pd.Id) ORDER BY Name ASC ];
        
        Id[] arrContact = new List<Id>();
        for(Contact c:lCon){
            arrContact.add(c.Id);
        }
        Test.startTest();
        
        List<SC_LWCAddAuthorizedContactsCtrl.ContactWrapper> lConWrapper = SC_LWCAddAuthorizedContactsCtrl.getAllContactRecs(pd.Id);
        SC_LWCAddAuthorizedContactsCtrl.StatusWrapper lStatusWrapper = SC_LWCAddAuthorizedContactsCtrl.addContactRecs(pd.Id,arrContact);
        
        Test.stopTest();
    }

    public static testMethod void removeContactTest()
    {
        Policy_Domain__c pd=[Select Id, Account_Name__c from Policy_Domain__c LIMIT 1 ];
        
        List<Authorized_Contact__c> lauthCon= [Select Id from Authorized_Contact__c where Policy_Domain__c =:pd.Id];
        
        System.debug('The list of auth contact is'+lauthCon);
        System.debug('The list of auth contact is'+lauthCon.size());
        
        /*Id[] arrAuthContact = new Id[lauthCon.size()];
        for(Authorized_Contact__c ac:lauthCon){
            System.debug('Id is '+ ac.Id);
            arrAuthContact.add(ac.Id);
        }*/
        
        Id[] arrAuthContact = new List<Id>();
        for(Authorized_Contact__c ac:lauthCon){
            System.debug('Id is '+ ac.Id);
            arrAuthContact.add(ac.Id);
        }
        System.debug('the array of Ids are '+arrAuthContact);
        Test.startTest();
        
        List<SC_LWCAddAuthorizedContactsCtrl.ContactWrapper> lAuthConWrapper= SC_LWCAddAuthorizedContactsCtrl.getAllAuthContactRecs(pd.Id);
        SC_LWCAddAuthorizedContactsCtrl.StatusWrapper lStatusWrapper = SC_LWCAddAuthorizedContactsCtrl.deleteAuthContact(arrAuthContact);
        //SC_LWCAddAuthorizedContactsCtrl.deleteAuthContact(arrAuthContact);
        
        Test.stopTest();
    }
}