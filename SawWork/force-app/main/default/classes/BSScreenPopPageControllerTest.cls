/***************************************************************************
* Name          : BSScreenPopPageControllerTest
* Created By    : William Taylor (TTEC)
* Created Date  : 30-Sept-2020
* Purpose       : Test class for BSScreenPopPageController Page
----------------------------------------------------------------------------
Last Modified BY            Last Modified Date      Purpose
----------------------------------------------------------------------------

****************************************************************************/

@isTest
public class BSScreenPopPageControllerTest {

Public static PSA_TestUtility testUtil;
  public static Account accountRecord;
    public static Account accountRecord2;
    public static Account accountRecord3;
   public static Contact contactRecord;
    public static Contact contactRecord2;
    public static Contact contactRecord3;
    
    
    
    static testmethod void testMarketingLeadOnlyMatch() {
       User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
       Task t = new Task();
         Id[] fixedSearchResults= new Id[2];
       Contact c;
       List<Lead> insLeads;
       System.runAs (thisUser) {
        
       Environment_Setup__c env = new Environment_Setup__c();
       env.Akam_Id_Start_String__c = 'F-';
       insert env;
       
        Account a = new account();
        a.name='TestAccount';
        insert a;
        c = new contact();
        c.lastname='TestName';
        c.phone = '108108108108';
        
        c.accountid = a.id;
        insert c;
         testUtil = new PSA_TestUtility();
         
         
          List<Account> accountList = new List<Account>();
        accountRecord = testUtil.newAccount(false);
        accountRecord.Parent_Division__c = 'Media_APJ';
        accountRecord.Region__c = 'karnataka';
        accountRecord.Area__c = 'Bangalore';
        accountRecord.Division__c = 'India';
        accountRecord.Projected_SDR__c = thisUser.id;
        accountRecord.AKERC__c = '9999';
        accountList.add(accountRecord);
        
        accountRecord2 = testUtil.newAccount(false);
        accountRecord2.Name = 'Test 1';
        accountRecord2.Parent_Division__c = 'Web_EMEA';
        accountRecord2.Region__c = 'karnataka';
        accountRecord2.Area__c = 'Bangalore';
        accountRecord2.Division__c = 'India';
        accountRecord2.AKERC__c = '6666';
        accountList.add(accountRecord2);
        
        accountRecord3 = testUtil.newAccount(false);
        accountRecord3.Name = 'Test 3';
        accountRecord3.Parent_Division__c = 'Web_EMEA';
        accountRecord3.Region__c = 'karnataka';
        accountRecord3.Area__c = 'Bangalore';
        accountRecord3.Division__c = 'India';
        accountRecord3.AKERC__c = '6666';
        accountList.add(accountRecord3);
        
        Insert accountList;
         
        List<Contact> contactList = new List<Contact>();
        contactRecord = testUtil.newResource(false, accountList[0].Id, null );
        contactRecord.phone = '108108108108';
        contactRecord.Recordtypeid = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Business Contact').getRecordTypeId();
        contactList.add(contactRecord);
        
        contactRecord2 = testUtil.newResource(false, accountRecord2.Id, null);
        contactRecord2.phone = '108108108109';
        contactRecord2.Recordtypeid = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Business Contact').getRecordTypeId();
        contactList.add(contactRecord2);
        
        contactRecord3 = testUtil.newResource(false, accountRecord3.Id, null);
        contactRecord3.phone = '108108108178';
        contactRecord3.Recordtypeid = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Business Contact').getRecordTypeId();
        contactList.add(contactRecord3);
        
        Insert contactList;
        
        
        //Create Lead
        new SObjectBuilder(Order_Region_Reporting_Region_Mapping__c.sObjectType)
                .eagerPopulate()
                .create();

        new SObjectBuilder(Sales_Approved_Country__c.SObjectType)
                .eagerPopulate()
                .create();
        List<Account> listOfTestAccounts = (List<Account>) new SObjectBuilder(Account.sObjectType)
                .eagerPopulate()
                .put(Account.Vertical__c, 'Gaming')
                .put(Account.Sub_Vertical__c, 'Gaming')
                .count(1)
                .create()
                .getRecords();


            List<Contact> listOfTestContacts = (List<Contact>) new SObjectBuilder(Contact.sObjectType)
                .eagerPopulate()
                .put(Contact.AccountId, listOfTestAccounts)
                .count(1)
                .create()
                .getRecords();
            //Test.startTest();
        
        Id akamaiLeadRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Akamai Lead').getRecordTypeId();
        Id marketoLeadRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
        
        String autoConvertQId = GSMSettings.getValue('LeadAutoConvert_QueueId');
        
        User marketingOpsUser = [SELECT Id FROM User WHERE Profile.Name = 'Marketing Operations' AND Isactive = True LIMIT 1];
        
        System.runAs(marketingOpsUser)
            {
                new SObjectBuilder(Lead.SObjectType)
                    .eagerPopulate()
                    .count(1)
                    .put(Lead.RecordTypeId, akamaiLeadRecordTypeId)
                    .put(Lead.OwnerId, autoConvertQId)
                    .put(Lead.Associated_Account__c, listOfTestAccounts)
                    .put(Lead.Associated_Contact__c, contactList)
                    .put(Lead.Product_Line__c,'Enterprise')
                    .put(Lead.Validation_Override__c,True)
                    .create();
                
                new SObjectBuilder(Lead.SObjectType)
                    .eagerPopulate()
                    .count(1)
                    .put(Lead.RecordTypeId, marketoLeadRecordTypeId)
                    .put(Lead.OwnerId, autoConvertQId)
                    .put(Lead.Associated_Account__c, listOfTestAccounts)
                    .put(Lead.Associated_Contact__c, contactList)
                    .put(Lead.Product_Line__c,'Enterprise')
                    .put(Lead.Validation_Override__c,True)
                    .create();
            }
        
        insLeads = [select id, phone from lead where recordtype.name ='Marketo Lead'];
        insLeads[0].phone = '108108108108';
        update insLeads[0];
        
        
        fixedSearchResults[0] = c.id;
        fixedSearchResults[1] = insLeads[0].id;
        insert t;
        }
        Test.setFixedSearchResults(fixedSearchResults);
        Test.startTest();
    
        PageReference myVfPage = Page.BSScreenPopPage;
        Test.setCurrentPage(myVfPage);
        
        ApexPages.currentPage().getParameters().put('lob','Marketing');
        ApexPages.currentPage().getParameters().put('ani','108108108108');
        ApexPages.currentPage().getParameters().put('taskid',t.id);

        BSScreenPopPageController bsppc = new BSScreenPopPageController();
        bsppc.runStandardPop();
        bsppc.updateSearch();
        bsppc.updateTaskRecord();
        bsppc.updateUserSearch();
        bsppc.runSearchPhone('108108108108', true);
        bsppc.runSearchPhone('108108108109', true);
        
        
        fixedSearchResults[0] = c.id;
        fixedSearchResults[1] = null;
        
        Test.setFixedSearchResults(fixedSearchResults);
        bsppc.runSearchPhone('108108108108', true);
        fixedSearchResults[0] = null;
        fixedSearchResults[1] = insLeads[0].id;
        
        Test.setFixedSearchResults(fixedSearchResults);
        bsppc.runSearchPhone('108108108108', true);
        
       
        Test.stopTest();
        
    }


static testmethod void testHelpDesk() {
       User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
       Task t = new Task();
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u = new User(Alias = 'standt', Email='standardusertest@akamai.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',Phone='1234567890',
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standardakamaitestuser@testorg.com');
       insert u;
       Id[] fixedSearchResults= new Id[2];
      
      
    
        
        
       System.runAs (u) {
        
        
       BMCServiceDesk__Incident__c incidentRecordForCorp;
       BMCServiceDesk__Incident__c incidentRecordForOps;
          //Create Helpdesk Ticket
        List<BMCServiceDesk__Incident__c> incidentList = new  List<BMCServiceDesk__Incident__c>();
        HD_IncidentTestDataFactory obj = new HD_IncidentTestDataFactory();
        incidentRecordForCorp = obj.getNewIncident(HD_IncidentTestDataFactory.Team.CORPIT);
        incidentRecordForOps = obj.getNewIncident(HD_IncidentTestDataFactory.Team.EAEOPS);
        //incidentRecordForCorp.BMCServiceDesk__FKClient__c = u.id;
        //incidentRecordForOps.BMCServiceDesk__FKClient__c = u.id;
        
        List<Recordtype> rtTypes = [select id, name from recordtype where sobjecttype='BMCServiceDesk__Incident__c' order by name ASC];
        incidentRecordForCorp.recordtypeid = rtTypes[0].id;
        incidentRecordForOps.recordtypeid = rtTypes[0].id;
        incidentRecordForCorp.How_was_the_Issue_Detected__c = 'Other';
        incidentRecordForOps.How_was_the_Issue_Detected__c = 'Other';
        
        incidentList.add(incidentRecordForCorp);
        incidentList.add(incidentRecordForOps);
        Insert incidentList;
        List<BMCServiceDesk__Incident__c> incll = [select id, BMCServiceDesk__Type__c, recordtype.name, BMCServiceDesk__FKStatus__r.name,  BMCServiceDesk__clientId__c,HD_Incident_Group__c from BMCServiceDesk__Incident__c];
        system.debug(incll);
        for (BMCServiceDesk__Incident__c ccf : incll) {
        System.debug('recordtype name: ' + ccf.recordtype.name);
        System.debug('BMCServiceDesk__FKStatus__r.name: ' + ccf.BMCServiceDesk__FKStatus__r.name );
                
        
        }
        
        List<BMCServiceDesk__Status__c> st = [select id , name from BMCServiceDesk__Status__c];
        system.debug(st);
        
        
        //Create Service Request
        HD_TestDataFactory_ServiceRequest.FulfilmentInputWrapperClass tempList=new HD_TestDataFactory_ServiceRequest.FulfilmentInputWrapperClass();
        List<HD_TestDataFactory_ServiceRequest.FulfilmentInputWrapperClass> fulfilmentInputLists=new List<HD_TestDataFactory_ServiceRequest.FulfilmentInputWrapperClass>();
        tempList.order='1';
        tempList.responseType='Text Area';
        tempList.prompt='Description';
        tempList.required='FALSE';
        tempList.hidden='FALSE';
        templist.runWorkflow = 'FALSE';
      
        
        
       Environment_Setup__c env = new Environment_Setup__c();
       env.Akam_Id_Start_String__c = 'F-';
       insert env;
       
        Account a = new account();
        a.name='TestAccount';
        insert a;
        contact c = new contact();
        c.lastname='TestName';
        c.phone = '1234567890';
        c.firstname = 'testname';
        c.accountid = a.id;
        insert c;
        
        insert t;
           
        fixedSearchResults[0] = c.id;
        fixedSearchResults[1] = u.id;   
        }
        
      
      
        
        Test.setFixedSearchResults(fixedSearchResults);
        Test.startTest();
    
        PageReference myVfPage = Page.BSScreenPopPage;
        Test.setCurrentPage(myVfPage);
        
        ApexPages.currentPage().getParameters().put('lob','HelpDesk');
        ApexPages.currentPage().getParameters().put('ani','1234567890');
        ApexPages.currentPage().getParameters().put('taskid',t.id);

        BSScreenPopPageController bsppc = new BSScreenPopPageController();
        bsppc.userNameSearch = 'standardakamaitestuser@testorg.com';
        bsppc.runStandardPop();
        bsppc.updateSearch();
        
        bsppc.runSelection();
        bsppc.runPrePopCheck();
        bsppc.updateTaskRecord();
        bsppc.updateUserSearch();
        bsppc.runSearchPhone('1234567890', true);
        bsppc.updateTask(t.Id);
        
     
       
        Test.stopTest();
        
    }





static testmethod void testEAE() {
       User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
       Task t = new Task();
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u = new User(Alias = 'standt', Email='standardusertest@akamai.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',Phone='1234567890',
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standardakamaitestuser@testorg.com');
       insert u;
       Id[] fixedSearchResults= new Id[2];
      
      
    
        
        
       System.runAs (u) {
        
        
       BMCServiceDesk__Incident__c incidentRecordForCorp;
       BMCServiceDesk__Incident__c incidentRecordForOps;
          //Create Helpdesk Ticket
        List<BMCServiceDesk__Incident__c> incidentList = new  List<BMCServiceDesk__Incident__c>();
        HD_IncidentTestDataFactory obj = new HD_IncidentTestDataFactory();
        incidentRecordForCorp = obj.getNewIncident(HD_IncidentTestDataFactory.Team.CORPIT);
        incidentRecordForOps = obj.getNewIncident(HD_IncidentTestDataFactory.Team.EAEOPS);
        //incidentRecordForCorp.BMCServiceDesk__FKClient__c = u.id;
        //incidentRecordForOps.BMCServiceDesk__FKClient__c = u.id;
        
        List<Recordtype> rtTypes = [select id, name from recordtype where sobjecttype='BMCServiceDesk__Incident__c' order by name ASC];
        incidentRecordForCorp.recordtypeid = rtTypes[0].id;
        incidentRecordForOps.recordtypeid = rtTypes[0].id;
        incidentRecordForCorp.How_was_the_Issue_Detected__c = 'Other';
        incidentRecordForOps.How_was_the_Issue_Detected__c = 'Other';
        
        incidentList.add(incidentRecordForCorp);
        incidentList.add(incidentRecordForOps);
        Insert incidentList;
        List<BMCServiceDesk__Incident__c> incll = [select id, BMCServiceDesk__Type__c, recordtype.name, BMCServiceDesk__FKStatus__r.name,  BMCServiceDesk__clientId__c,HD_Incident_Group__c from BMCServiceDesk__Incident__c];
        system.debug(incll);
        for (BMCServiceDesk__Incident__c ccf : incll) {
        System.debug('recordtype name: ' + ccf.recordtype.name);
        System.debug('BMCServiceDesk__FKStatus__r.name: ' + ccf.BMCServiceDesk__FKStatus__r.name );
                
        
        }
        
        List<BMCServiceDesk__Status__c> st = [select id , name from BMCServiceDesk__Status__c];
        system.debug(st);
        
        
        //Create Service Request
        HD_TestDataFactory_ServiceRequest.FulfilmentInputWrapperClass tempList=new HD_TestDataFactory_ServiceRequest.FulfilmentInputWrapperClass();
        List<HD_TestDataFactory_ServiceRequest.FulfilmentInputWrapperClass> fulfilmentInputLists=new List<HD_TestDataFactory_ServiceRequest.FulfilmentInputWrapperClass>();
        tempList.order='1';
        tempList.responseType='Text Area';
        tempList.prompt='Description';
        tempList.required='FALSE';
        tempList.hidden='FALSE';
        templist.runWorkflow = 'FALSE';
      
        
        
       Environment_Setup__c env = new Environment_Setup__c();
       env.Akam_Id_Start_String__c = 'F-';
       insert env;
       
        Account a = new account();
        a.name='TestAccount';
        insert a;
        contact c = new contact();
        c.lastname='TestName';
        c.phone = '1234567890';
        c.firstname = 'testname';
        c.accountid = a.id;
        insert c;
        
        insert t;
           
        fixedSearchResults[0] = c.id;
        fixedSearchResults[1] = u.id;   
        }
        
      
      
        
        Test.setFixedSearchResults(fixedSearchResults);
        Test.startTest();
    
        PageReference myVfPage = Page.BSScreenPopPage;
        Test.setCurrentPage(myVfPage);
        
        ApexPages.currentPage().getParameters().put('lob','EAE Ops');
        ApexPages.currentPage().getParameters().put('ani','1234567890');
        ApexPages.currentPage().getParameters().put('taskid',t.id);

        BSScreenPopPageController bsppc = new BSScreenPopPageController();
        bsppc.userNameSearch = 'standardakamaitestuser@testorg.com';
        bsppc.runStandardPop();
        bsppc.updateSearch();
        
        bsppc.runSelection();
        bsppc.runPrePopCheck();
        bsppc.updateTaskRecord();
        bsppc.updateUserSearch();
        bsppc.runSearchPhone('1234567890', true);
        bsppc.updateTask(t.Id);
        
     
       
        Test.stopTest();
        
    }






    static testmethod void testAkatec() {
       User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
       Task t = new Task();
         Id[] fixedSearchResults= new Id[2];
       System.runAs (thisUser) {
        
       Environment_Setup__c env = new Environment_Setup__c();
       env.Akam_Id_Start_String__c = 'F-';
       insert env;
       
        Account a = new account();
        a.name='TestAccount';
        insert a;
        contact c = new contact();
        c.lastname='TestName';
        c.phone = '1234567890';
        
        c.accountid = a.id;
        insert c;
        fixedSearchResults[0] = c.id;
        insert t;
        }
        Test.setFixedSearchResults(fixedSearchResults);
        Test.startTest();
    
        PageReference myVfPage = Page.BSScreenPopPage;
        Test.setCurrentPage(myVfPage);
        
        ApexPages.currentPage().getParameters().put('lob','Akatec');
        ApexPages.currentPage().getParameters().put('ani','1234567890');
        ApexPages.currentPage().getParameters().put('taskid',t.id);

        BSScreenPopPageController bsppc = new BSScreenPopPageController();
        bsppc.runStandardPop();
        bsppc.updateSearch();
        
        bsppc.runSelection();
        bsppc.runPrePopCheck();
        bsppc.updateTaskRecord();
        bsppc.updateUserSearch();
        bsppc.runSearchPhone('1234567890', true);
        bsppc.updateTask(t.Id);
        
     
       
        Test.stopTest();
    }
    
    static testmethod void testAkatecCaseId() {
       User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
       Task t = new Task();
         Id[] fixedSearchResults= new Id[2];
         String cid;
         
       System.runAs (thisUser) {
        
       Environment_Setup__c env = new Environment_Setup__c();
       env.Akam_Id_Start_String__c = 'F-';
       insert env;
       
        Account a = new account();
        a.name='TestAccount';
        insert a;
        contact c = new contact();
        c.lastname='TestName';
        c.phone = '1234567890';
        
        c.accountid = a.id;
        insert c;
        
        
        
        SCUtilTestClass.createCustomSettingsForCase();
        Case ca = new Case();
        ca.contactid = c.id;
        ca.origin = 'Phone';
        
        insert ca;
        cid = ca.id;
        
        
        
        fixedSearchResults[0] = c.id;
        fixedSearchResults[1] = cid;
        
        insert t;
        }
        Test.setFixedSearchResults(fixedSearchResults);
        Test.startTest();
    
        PageReference myVfPage = Page.BSScreenPopPage;
        Test.setCurrentPage(myVfPage);
        
        ApexPages.currentPage().getParameters().put('lob','Akatec');
        ApexPages.currentPage().getParameters().put('ani','1234567890');
        ApexPages.currentPage().getParameters().put('taskid',t.id);
        ApexPages.currentPage().getParameters().put('caseid',cid);

        BSScreenPopPageController bsppc = new BSScreenPopPageController();
        bsppc.runStandardPop();
        bsppc.updateSearch();
        
        bsppc.runSelection();
        bsppc.runPrePopCheck();
        bsppc.updateTaskRecord();
        bsppc.updateUserSearch();
        bsppc.runSearchPhone('1234567890', true);
        bsppc.updateTask(t.Id);
        
     
       
        Test.stopTest();
    }
     static testmethod void testAkatecMulti() {
       User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
       Task t = new Task();
         Id[] fixedSearchResults= new Id[2];
       System.runAs (thisUser) {
        
       Environment_Setup__c env = new Environment_Setup__c();
       env.Akam_Id_Start_String__c = 'F-';
       insert env;
       
        Account a = new account();
        a.name='TestAccount';
        insert a;
        contact c = new contact();
        c.lastname='TestName';
        c.phone = '1234567890';
        contact c2 = new contact();
        c2.lastname='TestName2';
        c2.phone = '1234567890';
        c2.accountid = a.id;
        c.accountid = a.id;
        insert c;
        insert c2;
           
        fixedSearchResults[0] = c.id;
           fixedSearchResults[1] = c2.id;
        insert t;
        }
        Test.setFixedSearchResults(fixedSearchResults);
        Test.startTest();
    
        PageReference myVfPage = Page.BSScreenPopPage;
        Test.setCurrentPage(myVfPage);
        
        ApexPages.currentPage().getParameters().put('lob','Akatec');
        ApexPages.currentPage().getParameters().put('ani','1234567890');
        ApexPages.currentPage().getParameters().put('taskid',t.id);

        BSScreenPopPageController bsppc = new BSScreenPopPageController();
        bsppc.runStandardPop();
        bsppc.updateSearch();
        
        bsppc.runSelection();
        bsppc.runPrePopCheck();
        bsppc.updateTaskRecord();
        bsppc.updateUserSearch();
        bsppc.runSearchPhone('1234567890', true);
        bsppc.updateTask(t.Id);
        
     
       
        Test.stopTest();
    
    }
      static testmethod void testAkatecMultiErc() {
       User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
       Task t = new Task();
         Id[] fixedSearchResults= new Id[2];
       System.runAs (thisUser) {
        
       Environment_Setup__c env = new Environment_Setup__c();
       env.Akam_Id_Start_String__c = 'F-';
       insert env;
       
        Account a = new account();
        a.name='TestAccount';
        a.AKERC__c  = '1234';
       insert a;
        Account a2 = new account();
        a2.name='TestAccount2';
        a2.AKERC__c  = '4321';
       insert a2;
           
        fixedSearchResults[0] = a.id;
      fixedSearchResults[1] = a2.id;
        insert t;
        }
        Test.setFixedSearchResults(fixedSearchResults);
        Test.startTest();
    
        PageReference myVfPage = Page.BSScreenPopPage;
        Test.setCurrentPage(myVfPage);
        
        ApexPages.currentPage().getParameters().put('lob','Akatec');
        ApexPages.currentPage().getParameters().put('ani','1234567890');
        ApexPages.currentPage().getParameters().put('taskid',t.id);
        ApexPages.currentPage().getParameters().put('erc','1234');

        BSScreenPopPageController bsppc = new BSScreenPopPageController();
        bsppc.runStandardPop();
        bsppc.updateSearch();
        
        bsppc.runSelection();
        bsppc.runPrePopCheck();
        bsppc.updateTaskRecord();
        bsppc.updateUserSearch();
        bsppc.runSearchPhone('1234567890', true);
        bsppc.updateTask(t.Id);
        
     
       
        Test.stopTest();
      
    }
    
     static testmethod void testMarketing() {
       User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
       Task t = new Task();
         Id[] fixedSearchResults= new Id[2];
       System.runAs (thisUser) {
        
       Environment_Setup__c env = new Environment_Setup__c();
       env.Akam_Id_Start_String__c = 'F-';
       insert env;
       
        Account a = new account();
        a.name='TestAccount';
        insert a;
        contact c = new contact();
        c.lastname='TestName';
        c.phone = '1234567890';
        
        c.accountid = a.id;
        insert c;
        fixedSearchResults[0] = c.id;
        insert t;
        }
        Test.setFixedSearchResults(fixedSearchResults);
        Test.startTest();
    
        PageReference myVfPage = Page.BSScreenPopPage;
        Test.setCurrentPage(myVfPage);
        
        ApexPages.currentPage().getParameters().put('lob','Marketing');
        ApexPages.currentPage().getParameters().put('ani','1234567890');
        ApexPages.currentPage().getParameters().put('taskid',t.id);

        BSScreenPopPageController bsppc = new BSScreenPopPageController();
        bsppc.runStandardPop();
        bsppc.updateSearch();
        
        bsppc.runSelection();
        bsppc.runPrePopCheck();
        bsppc.updateTaskRecord();
        bsppc.updateUserSearch();
        bsppc.runSearchPhone('1234567890', true);
        bsppc.updateTask(t.Id);
        
     
       
        Test.stopTest();
        
    }

    static testmethod void testMarketingMultimatch() {
       User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
       Task t = new Task();
         Id[] fixedSearchResults= new Id[2];
       System.runAs (thisUser) {
        
       Environment_Setup__c env = new Environment_Setup__c();
       env.Akam_Id_Start_String__c = 'F-';
       insert env;
       
        Account a = new account();
        a.name='TestAccount';
        insert a;
        contact c = new contact();
        c.lastname='TestName';
        c.phone = '1234567890';
        contact c2 = new contact();
        c2.lastname='TestName2';
        c2.phone = '1234567890';
        c2.accountid = a.id;
        c.accountid = a.id;
        
        insert c;
        insert c2;
        fixedSearchResults[0] = c.id;
        fixedSearchResults[1] = c2.id;
        insert t;
        }
        Test.setFixedSearchResults(fixedSearchResults);
        Test.startTest();
    
        PageReference myVfPage = Page.BSScreenPopPage;
        Test.setCurrentPage(myVfPage);
        
        ApexPages.currentPage().getParameters().put('lob','Marketing');
        ApexPages.currentPage().getParameters().put('ani','1234567890');
        ApexPages.currentPage().getParameters().put('taskid',t.id);

        BSScreenPopPageController bsppc = new BSScreenPopPageController();
        bsppc.runStandardPop();
        bsppc.updateSearch();
        
        bsppc.runSelection();
        bsppc.runPrePopCheck();
        bsppc.updateTaskRecord();
        bsppc.updateUserSearch();
        bsppc.runSearchPhone('1234567890', true);
        bsppc.updateTask(t.Id);
        
     
       
        Test.stopTest();
        
    }
     static testmethod void testMarketingNoMatch() {
       User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
       Task t = new Task();
         Id[] fixedSearchResults= new Id[2];
       System.runAs (thisUser) {
        
       Environment_Setup__c env = new Environment_Setup__c();
       env.Akam_Id_Start_String__c = 'F-';
       insert env;
       
        Account a = new account();
        a.name='TestAccount';
        insert a;
        contact c = new contact();
        c.lastname='TestName';
        c.phone = '1234567890';
        
        c.accountid = a.id;
        insert c;
        fixedSearchResults[0] = c.id;
        insert t;
        }
        //Test.setFixedSearchResults(fixedSearchResults);
        Test.startTest();
    
        PageReference myVfPage = Page.BSScreenPopPage;
        Test.setCurrentPage(myVfPage);
        
        ApexPages.currentPage().getParameters().put('lob','Marketing');
        ApexPages.currentPage().getParameters().put('ani','1234567890');
        ApexPages.currentPage().getParameters().put('taskid',t.id);

        BSScreenPopPageController bsppc = new BSScreenPopPageController();
        bsppc.runStandardPop();
        bsppc.updateSearch();
        
        bsppc.runSelection();
        bsppc.runPrePopCheck();
        bsppc.updateTaskRecord();
        bsppc.updateUserSearch();
        bsppc.runSearchPhone('1234567890', true);
        bsppc.updateTask(t.Id);
        
     
       
        Test.stopTest();
        
    }
    
    
    static testmethod void testBillingNoMatch() {
       User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
       Task t = new Task();
         Id[] fixedSearchResults= new Id[2];
       System.runAs (thisUser) {
        
       Environment_Setup__c env = new Environment_Setup__c();
       env.Akam_Id_Start_String__c = 'F-';
       insert env;
       
        Account a = new account();
        a.name='TestAccount';
        insert a;
        contact c = new contact();
        c.lastname='TestName';
        c.phone = '1234567890';
        
        c.accountid = a.id;
        insert c;
        fixedSearchResults[0] = c.id;
        insert t;
        }
        //Test.setFixedSearchResults(fixedSearchResults);
        Test.startTest();
    
        PageReference myVfPage = Page.BSScreenPopPage;
        Test.setCurrentPage(myVfPage);
        
        ApexPages.currentPage().getParameters().put('lob','Billing');
        ApexPages.currentPage().getParameters().put('ani','1234567890');
        ApexPages.currentPage().getParameters().put('taskid',t.id);

        BSScreenPopPageController bsppc = new BSScreenPopPageController();
        bsppc.runStandardPop();
        bsppc.updateSearch();
        
        bsppc.runSelection();
        bsppc.runPrePopCheck();
        bsppc.updateTaskRecord();
        bsppc.updateUserSearch();
        bsppc.runSearchPhone('1234567890', true);
        bsppc.updateTask(t.Id);
        
     
       
        Test.stopTest();
        
    }
    
    
     static testmethod void testBillingSingle() {
       User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
       Task t = new Task();
         Id[] fixedSearchResults= new Id[2];
       System.runAs (thisUser) {
        
       Environment_Setup__c env = new Environment_Setup__c();
       env.Akam_Id_Start_String__c = 'F-';
       insert env;
       
        Account a = new account();
        a.name='TestAccount';
        insert a;
        contact c = new contact();
        c.lastname='TestName';
        c.phone = '1234567890';
        
        c.accountid = a.id;
        insert c;
        fixedSearchResults[0] = c.id;
        insert t;
        }
        Test.setFixedSearchResults(fixedSearchResults);
        Test.startTest();
    
        PageReference myVfPage = Page.BSScreenPopPage;
        Test.setCurrentPage(myVfPage);
        
        ApexPages.currentPage().getParameters().put('lob','Billing');
        ApexPages.currentPage().getParameters().put('ani','1234567890');
        ApexPages.currentPage().getParameters().put('taskid',t.id);

        BSScreenPopPageController bsppc = new BSScreenPopPageController();
        bsppc.runStandardPop();
        bsppc.updateSearch();
        
        bsppc.runSelection();
        bsppc.runPrePopCheck();
        bsppc.updateTaskRecord();
        bsppc.updateUserSearch();
        bsppc.runSearchPhone('1234567890', true);
        bsppc.updateTask(t.Id);
        
     
       
        Test.stopTest();
        
    }
    
     static testmethod void testBillingMulti() {
       User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
       Task t = new Task();
         Id[] fixedSearchResults= new Id[2];
       System.runAs (thisUser) {
        
       Environment_Setup__c env = new Environment_Setup__c();
       env.Akam_Id_Start_String__c = 'F-';
       insert env;
       
        Account a = new account();
        a.name='TestAccount';
        insert a;
        contact c = new contact();
        c.lastname='TestName';
        c.phone = '1234567890';
        
        c.accountid = a.id;
        insert c;
        contact c2 = new contact();
        c2.lastname='TestName2';
        c2.phone = '1234567890';
        
        c2.accountid = a.id;
        insert c2;
           
        fixedSearchResults[0] = c.id;
        fixedSearchResults[1] = c2.id;
           
        insert t;
        }
        Test.setFixedSearchResults(fixedSearchResults);
        Test.startTest();
    
        PageReference myVfPage = Page.BSScreenPopPage;
        Test.setCurrentPage(myVfPage);
        
        ApexPages.currentPage().getParameters().put('lob','Billing');
        ApexPages.currentPage().getParameters().put('ani','1234567890');
        ApexPages.currentPage().getParameters().put('taskid',t.id);

        BSScreenPopPageController bsppc = new BSScreenPopPageController();
        bsppc.runStandardPop();
        bsppc.updateSearch();
        
        bsppc.runSelection();
        bsppc.runPrePopCheck();
        bsppc.updateTaskRecord();
        bsppc.updateUserSearch();
        bsppc.runSearchPhone('1234567890', true);
        bsppc.updateTask(t.Id);
        
     
       
        Test.stopTest();
        
    }
    
    
    
    
    
    static testmethod void testBOCC() {
       User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
       Task t = new Task();
       String cid;
       Id[] fixedSearchResults= new Id[2];
        
       System.runAs (thisUser) {
        
       Environment_Setup__c env = new Environment_Setup__c();
       env.Akam_Id_Start_String__c = 'F-';
       insert env;
       
       SCUtilTestClass.createCustomSettingsForCase();
       
        Account a = new account();
        a.name='TestAccount';
        insert a;
        contact c = new contact();
        c.lastname='TestName';
        c.phone = '1234567890';
        
        c.accountid = a.id;
        insert c;
        
        Case ca = new Case();
        ca.contactid = c.id;
        ca.origin = 'Phone';
        ca.Akam_case_Id__c = 'F-CS-100012';  
        
        insert ca;
        cid = ca.id;
    
        
        
        
        fixedSearchResults[0] = c.id;

        insert t;
        }
        Test.setFixedSearchResults(fixedSearchResults);
        Test.startTest();
    
        PageReference myVfPage = Page.BSScreenPopPage;
        Test.setCurrentPage(myVfPage);
        
        ApexPages.currentPage().getParameters().put('lob','BOCC');
        ApexPages.currentPage().getParameters().put('ani','1234567890');
        ApexPages.currentPage().getParameters().put('taskid',t.id);
        ApexPages.currentPage().getParameters().put('caseid','100012');

        BSScreenPopPageController bsppc = new BSScreenPopPageController();
        
        bsppc.runSelection();
        bsppc.runPrePopCheck();
        bsppc.updateTaskRecord();
        bsppc.updateUserSearch();
        bsppc.runSearchPhone('1234567890', true);
        bsppc.updateTask(t.Id);
        
     
       
        Test.stopTest();
        
    }
    
    
    static testmethod void testBOCCNoCaseId() {
       User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       Account a;
       Task t = new Task();
       String cid;
       Id[] fixedSearchResults= new Id[2];
        
       System.runAs (thisUser) {
        
       Environment_Setup__c env = new Environment_Setup__c();
       env.Akam_Id_Start_String__c = 'F-';
       insert env;
       
       SCUtilTestClass.createCustomSettingsForCase();
       
         a = new account();
        a.name='TestAccount';
        insert a;
        contact c = new contact();
        c.lastname='TestName';
        c.phone = '1234567890';
        
        c.accountid = a.id;
        insert c;
        
        Case ca = new Case();
        ca.contactid = c.id;
        ca.origin = 'Phone';
        
        insert ca;
        cid = ca.id;
        fixedSearchResults[0] = c.id;

        insert t;
        }
        Test.setFixedSearchResults(fixedSearchResults);
        Test.startTest();
    
        PageReference myVfPage = Page.BSScreenPopPage;
        Test.setCurrentPage(myVfPage);
        
        ApexPages.currentPage().getParameters().put('lob','BOCC');
        ApexPages.currentPage().getParameters().put('ani','1234567890');
        ApexPages.currentPage().getParameters().put('taskid',t.id);
       
        BSScreenPopPageController bsppc = new BSScreenPopPageController();
        
        bsppc.runSelection();
        bsppc.runPrePopCheck();
        bsppc.updateTaskRecord();
        bsppc.updateUserSearch();
        bsppc.runSearchPhone('1234567890', true);
        bsppc.updateTask(t.Id);
        PageReference ptest = bsppc.navigateToId();
        bsppc.cti_data = 'test';
        bsppc.issueOnBehalf = true;
        bsppc.selectedId = t.Id;
        bsppc.matchedAccount = a;
     
       
        Test.stopTest();
        
    }
    

static testmethod void testHelpDesk2() 
{
       User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
       Task t = new Task();
       Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u = new User(Alias = 'standt', Email='standardusertest@akamai.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',Phone='1234567890',
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standardakamaitestuser@testorg.com');
       insert u;
       Id[] fixedSearchResults= new Id[2];
      
      
    
        
        
       System.runAs (u) {
        
        
       BMCServiceDesk__Incident__c incidentRecordForCorp;
       BMCServiceDesk__Incident__c incidentRecordForOps;
          //Create Helpdesk Ticket
        List<BMCServiceDesk__Incident__c> incidentList = new  List<BMCServiceDesk__Incident__c>();
        HD_IncidentTestDataFactory obj = new HD_IncidentTestDataFactory();
        incidentRecordForCorp = obj.getNewIncident(HD_IncidentTestDataFactory.Team.CORPIT);
        incidentRecordForOps = obj.getNewIncident(HD_IncidentTestDataFactory.Team.CORPIT);
           
        List<Recordtype> rtTypes = [select id, name from recordtype where sobjecttype='BMCServiceDesk__Incident__c' and name = 'Helpdesk' order by name ASC];
        incidentRecordForCorp.recordtypeid = rtTypes[0].id;
        incidentRecordForOps.recordtypeid = rtTypes[0].id;
        incidentRecordForCorp.How_was_the_Issue_Detected__c = 'Other';
        incidentRecordForOps.How_was_the_Issue_Detected__c = 'Other';
        incidentList.add(incidentRecordForCorp);
        incidentList.add(incidentRecordForOps);
        Insert incidentList;
        List<BMCServiceDesk__Incident__c> incll = [select id,recordtype.name, BMCServiceDesk__Type__c,BMCServiceDesk__clientId__c,
                                                   BMCServiceDesk__FKStatus__r.name, BMCServiceDesk__Feedback__c, 
                                                   BMCServiceDesk__shortDescription__c,    HD_Parent_Tree__c,  
                                                   BMCServiceDesk__FKCategory__r.Name , BMCServiceDesk__FKPriority__r.Name,
                                                   HD_Owner_user_queue__c,  HD_Incident_Group__c from BMCServiceDesk__Incident__c  
                                                   order by createddate desc];
        system.debug(incll);

        
        //Create Service Request
       Environment_Setup__c env = new Environment_Setup__c();
       env.Akam_Id_Start_String__c = 'F-';
       insert env;
       
        Account a = new account();
        a.name='TestAccount';
        insert a;
        contact c = new contact();
        c.lastname='TestName';
        c.phone = '1234567890';
        c.firstname = 'testname';
        c.accountid = a.id;
        insert c;
        
        insert t;
           
        fixedSearchResults[0] = c.id;
        fixedSearchResults[1] = u.id;   
        }
        
      
      
        
        Test.setFixedSearchResults(fixedSearchResults);
        Test.startTest();
    
        PageReference myVfPage = Page.BSScreenPopPage;
        Test.setCurrentPage(myVfPage);
        
        ApexPages.currentPage().getParameters().put('lob','HelpDesk');
        ApexPages.currentPage().getParameters().put('ani','1234567890');
        ApexPages.currentPage().getParameters().put('taskid',t.id);

        BSScreenPopPageController bsppc = new BSScreenPopPageController();
        bsppc.userNameSearch = 'standardakamaitestuser@testorg.com';
        bsppc.runStandardPop();
        bsppc.updateSearch();
        
        bsppc.runSelection();
        bsppc.runPrePopCheck();
        bsppc.updateTaskRecord();
        bsppc.updateUserSearch();
        bsppc.runSearchPhone('1234567890', true);
        bsppc.updateTask(t.Id);
        
     
       
        Test.stopTest();
        
    }

static testmethod void testEAE2() {
       User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
       Task t = new Task();
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User u = new User(Alias = 'standt', Email='standardusertest@akamai.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',Phone='1234567890',
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standardakamaitestuser@testorg.com');
       insert u;
       Id[] fixedSearchResults= new Id[2];
      
      
    
        
        
       System.runAs (u) {
        
        
       BMCServiceDesk__Incident__c incidentRecordForCorp;
       BMCServiceDesk__Incident__c incidentRecordForOps;
          //Create Helpdesk Ticket
        List<BMCServiceDesk__Incident__c> incidentList = new  List<BMCServiceDesk__Incident__c>();
        HD_IncidentTestDataFactory obj = new HD_IncidentTestDataFactory();
        incidentRecordForCorp = obj.getNewIncident(HD_IncidentTestDataFactory.Team.CORPIT);
        incidentRecordForOps = obj.getNewIncident(HD_IncidentTestDataFactory.Team.EAEOPS);
        //incidentRecordForCorp.BMCServiceDesk__FKClient__c = u.id;
        //incidentRecordForOps.BMCServiceDesk__FKClient__c = u.id;

           
        List<Recordtype> rtTypes = [select id, name from recordtype where sobjecttype='BMCServiceDesk__Incident__c' and name = 'Helpdesk' order by name ASC];
        incidentRecordForCorp.recordtypeid = rtTypes[0].id;
        incidentRecordForOps.recordtypeid = rtTypes[0].id;
        incidentRecordForCorp.How_was_the_Issue_Detected__c = 'Other';
        incidentRecordForOps.How_was_the_Issue_Detected__c = 'Other';
           
        incidentList.add(incidentRecordForCorp);
        incidentList.add(incidentRecordForOps);
        Insert incidentList;
        List<BMCServiceDesk__Incident__c> incll = [select id, BMCServiceDesk__Type__c, recordtype.name, BMCServiceDesk__FKStatus__r.name,  BMCServiceDesk__clientId__c,HD_Incident_Group__c from BMCServiceDesk__Incident__c];
        system.debug(incll);
        
       Environment_Setup__c env = new Environment_Setup__c();
       env.Akam_Id_Start_String__c = 'F-';
       insert env;
       
        Account a = new account();
        a.name='TestAccount';
        insert a;
        contact c = new contact();
        c.lastname='TestName';
        c.phone = '1234567890';
        c.firstname = 'testname';
        c.accountid = a.id;
        insert c;
        
        insert t;
           
        fixedSearchResults[0] = c.id;
        fixedSearchResults[1] = u.id;   
        }
        
      
      
        
        Test.setFixedSearchResults(fixedSearchResults);
        Test.startTest();
    
        PageReference myVfPage = Page.BSScreenPopPage;
        Test.setCurrentPage(myVfPage);
        
        ApexPages.currentPage().getParameters().put('lob','EAE Ops');
        ApexPages.currentPage().getParameters().put('ani','1234567890');
        ApexPages.currentPage().getParameters().put('taskid',t.id);

        BSScreenPopPageController bsppc = new BSScreenPopPageController();
        bsppc.userNameSearch = 'standardakamaitestuser@testorg.com';
        bsppc.runStandardPop();
        bsppc.updateSearch();
        
        bsppc.runSelection();
        bsppc.runPrePopCheck();
        bsppc.updateTaskRecord();
        bsppc.updateUserSearch();
        bsppc.runSearchPhone('1234567890', true);
        bsppc.updateTask(t.Id);
        
     
       
        Test.stopTest();
        
    }

    
static testmethod void testHelpDeskSR2() 
{
       User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
       Task t = new Task();
       Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        User u = new User(Alias = 'standt', Email='standardusertest@akamai.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',Phone='1234567890',
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standardakamaitestuser@testorg.com');
       insert u;
       Id[] fixedSearchResults= new Id[2];
      
      
    
        
        
       System.runAs (u) {
        
        
       BMCServiceDesk__Incident__c incidentRecordForCorp;
       BMCServiceDesk__Incident__c incidentRecordForOps;
          //Create Helpdesk Ticket
        List<BMCServiceDesk__Incident__c> incidentList = new  List<BMCServiceDesk__Incident__c>();
        HD_IncidentTestDataFactory obj = new HD_IncidentTestDataFactory();
        
        List<Recordtype> rtTypes = [select id, name from recordtype where sobjecttype='BMCServiceDesk__Incident__c' and name = 'Helpdesk' order by name ASC];

        
        
        //Create Service Request
        HD_TestDataFactory_ServiceRequest.FulfilmentInputWrapperClass tempList=new HD_TestDataFactory_ServiceRequest.FulfilmentInputWrapperClass();
        List<HD_TestDataFactory_ServiceRequest.FulfilmentInputWrapperClass> fulfilmentInputLists=new List<HD_TestDataFactory_ServiceRequest.FulfilmentInputWrapperClass>();
        tempList.order='1';
        tempList.responseType='Text Area';
        tempList.prompt='Description';
        tempList.required='FALSE';
        tempList.hidden='FALSE';
        templist.runWorkflow = 'FALSE';
      
        fulfilmentInputLists.add(tempList);
        HD_Test_Data_Factory.init();
        
        MAP<String,Id>categoriesCreated = HD_Test_Data_Factory.categoryMap;
        String clientEmailId=System.UserInfo.getUserEmail();

        Map<String,Id> result=HD_TestDataFactory_ServiceRequest.setUpServiceRequest('testName18','testTitle18',categoriesCreated.get('Hardware'),fulfilmentInputLists,clientEmailId,true,HD_IncidentTestDataFactory.Team.CORPIT);
        result=HD_TestDataFactory_ServiceRequest.setUpServiceRequest('testName18','testTitle18',categoriesCreated.get('Access'),fulfilmentInputLists,clientEmailId,true,HD_IncidentTestDataFactory.Team.CORPIT);
        

         List<BMCServiceDesk__Incident__c> incll = [select id,recordtype.name, BMCServiceDesk__Type__c,BMCServiceDesk__clientId__c,
                                                   BMCServiceDesk__FKStatus__r.name, BMCServiceDesk__Feedback__c, 
                                                   BMCServiceDesk__shortDescription__c,    HD_Parent_Tree__c,  
                                                   BMCServiceDesk__FKCategory__r.Name , BMCServiceDesk__FKPriority__r.Name,
                                                   HD_Owner_user_queue__c,  HD_Incident_Group__c from BMCServiceDesk__Incident__c  
                                                   order by createddate desc];
        system.debug('testHelpDeskSR2: ' + incll);

       Environment_Setup__c env = new Environment_Setup__c();
       env.Akam_Id_Start_String__c = 'F-';
       insert env;
       
        Account a = new account();
        a.name='TestAccount';
        insert a;
        contact c = new contact();
        c.lastname='TestName';
        c.phone = '1234567890';
        c.firstname = 'testname';
        c.accountid = a.id;
        insert c;
        
        insert t;
           
        fixedSearchResults[0] = c.id;
        fixedSearchResults[1] = u.id;   
        }
        
      
      
        
        Test.setFixedSearchResults(fixedSearchResults);
        Test.startTest();
    
        PageReference myVfPage = Page.BSScreenPopPage;
        Test.setCurrentPage(myVfPage);
        
        ApexPages.currentPage().getParameters().put('lob','HelpDesk');
        ApexPages.currentPage().getParameters().put('ani','1234567890');
        ApexPages.currentPage().getParameters().put('taskid',t.id);

        BSScreenPopPageController bsppc = new BSScreenPopPageController();
        bsppc.userNameSearch = 'standardakamaitestuser@testorg.com';
        bsppc.runStandardPop();
        bsppc.updateSearch();
        
        bsppc.runSelection();
        bsppc.runPrePopCheck();
        bsppc.updateTaskRecord();
        bsppc.updateUserSearch();
        bsppc.runSearchPhone('1234567890', true);
        bsppc.updateTask(t.Id);
        
     
       
        Test.stopTest();
        
    }

static testmethod void testEAESR2() {
       User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
       Task t = new Task();
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        User u = new User(Alias = 'standt', Email='standardusertest@akamai.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',Phone='1234567890',
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standardakamaitestuser@testorg.com');
       insert u;
       Id[] fixedSearchResults= new Id[2];
      
      
    
        
        
       System.runAs (u) {
        
        
       BMCServiceDesk__Incident__c incidentRecordForCorp;
       BMCServiceDesk__Incident__c incidentRecordForOps;
          //Create Helpdesk Ticket
        List<BMCServiceDesk__Incident__c> incidentList = new  List<BMCServiceDesk__Incident__c>();
        HD_IncidentTestDataFactory obj = new HD_IncidentTestDataFactory();
        
        List<Recordtype> rtTypes = [select id, name from recordtype where sobjecttype='BMCServiceDesk__Incident__c' and name != 'Helpdesk' order by name ASC];
        
        //Create Service Request
        HD_TestDataFactory_ServiceRequest.FulfilmentInputWrapperClass tempList=new HD_TestDataFactory_ServiceRequest.FulfilmentInputWrapperClass();
        List<HD_TestDataFactory_ServiceRequest.FulfilmentInputWrapperClass> fulfilmentInputLists=new List<HD_TestDataFactory_ServiceRequest.FulfilmentInputWrapperClass>();
        tempList.order='1';
        tempList.responseType='Text Area';
        tempList.prompt='Description';
        tempList.required='FALSE';
        tempList.hidden='FALSE';
        templist.runWorkflow = 'FALSE';
      
        
        fulfilmentInputLists.add(tempList);
        HD_Test_Data_Factory.init();
        
        MAP<String,Id>categoriesCreated = HD_Test_Data_Factory.categoryMap;
        String clientEmailId=System.UserInfo.getUserEmail();
        
        Map<String,Id> result=HD_TestDataFactory_ServiceRequest.setUpServiceRequest('testName18','testTitle18',categoriesCreated.get('Hardware'),fulfilmentInputLists,clientEmailId,true,HD_IncidentTestDataFactory.Team.EAEOPS);
        result=HD_TestDataFactory_ServiceRequest.setUpServiceRequest('testName18','testTitle18',categoriesCreated.get('Access'),fulfilmentInputLists,clientEmailId,true,HD_IncidentTestDataFactory.Team.EAEOPS);
        

        List<BMCServiceDesk__Incident__c> incll = [select id,recordtype.name, BMCServiceDesk__Type__c,BMCServiceDesk__clientId__c,
                                                   BMCServiceDesk__FKStatus__r.name, BMCServiceDesk__Feedback__c, 
                                                   BMCServiceDesk__shortDescription__c,    HD_Parent_Tree__c,  
                                                   BMCServiceDesk__FKCategory__r.Name , BMCServiceDesk__FKPriority__r.Name,
                                                   HD_Owner_user_queue__c,  HD_Incident_Group__c from BMCServiceDesk__Incident__c  
                                                   order by createddate desc];
       system.debug('testEAESR2: ' + incll);

        
       Environment_Setup__c env = new Environment_Setup__c();
       env.Akam_Id_Start_String__c = 'F-';
       insert env;
       
        Account a = new account();
        a.name='TestAccount';
        insert a;
        contact c = new contact();
        c.lastname='TestName';
        c.phone = '1234567890';
        c.firstname = 'testname';
        c.accountid = a.id;
        insert c;
        
        insert t;
           
        fixedSearchResults[0] = c.id;
        fixedSearchResults[1] = u.id;   
        }
        
      
      
        
        Test.setFixedSearchResults(fixedSearchResults);
        Test.startTest();
    
        PageReference myVfPage = Page.BSScreenPopPage;
        Test.setCurrentPage(myVfPage);
        
        ApexPages.currentPage().getParameters().put('lob','EAE Ops');
        ApexPages.currentPage().getParameters().put('ani','1234567890');
        ApexPages.currentPage().getParameters().put('taskid',t.id);

        BSScreenPopPageController bsppc = new BSScreenPopPageController();
        bsppc.userNameSearch = 'standardakamaitestuser@testorg.com';
        bsppc.runStandardPop();
        bsppc.updateSearch();
        
        bsppc.runSelection();
        bsppc.runPrePopCheck();
        bsppc.updateTaskRecord();
        bsppc.updateUserSearch();
        bsppc.runSearchPhone('1234567890', true);
        bsppc.updateTask(t.Id);
        
     
       
        Test.stopTest();
        
    }

static testmethod void testIncidentMultiMatch() {
       User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       
       Task t = new Task();
    	List<User> users = new List<User> ();
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        User u = new User(Alias = 'standt', Email='standardusertest@akamai.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',Phone='1234567890',
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standardakamaitestuser@testorg.com');
        User u2 = new User(Alias = 'standt', Email='standardusertest12@akamai.com', 
            EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',Phone='1234567890',
            LocaleSidKey='en_US', ProfileId = p.Id, 
            TimeZoneSidKey='America/Los_Angeles', UserName='standardakamaitestuser12@testorg.com');
    
    	users.add(u);
    	users.add(u2);    
       insert users;
       Id[] fixedSearchResults= new Id[2];
      
      
    
        
        
       System.runAs (u) {
        
        
        fixedSearchResults[0] = u.id; 
        fixedSearchResults[1] = u2.id;    
        }
        
      
      
        
        Test.setFixedSearchResults(fixedSearchResults);
        Test.startTest();
    
        PageReference myVfPage = Page.BSScreenPopPage;
        Test.setCurrentPage(myVfPage);
        
        ApexPages.currentPage().getParameters().put('lob','EAE Ops');
        ApexPages.currentPage().getParameters().put('ani','1234567890');

        BSScreenPopPageController bsppc = new BSScreenPopPageController();
        bsppc.userNameSearch = 'standardakamaitestuser@testorg.com';
        bsppc.runStandardPop();
        bsppc.updateSearch();
        
        bsppc.runSelection();
        bsppc.runPrePopCheck();
        bsppc.updateTaskRecord();
        bsppc.updateUserSearch();
        bsppc.runSearchPhone('1234567890', true);
        
     
       
        Test.stopTest();
        
    }

    static testmethod void testBOCCNoCaseIdEmptyParam() {
       User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       Account a;
       Task t = new Task();
       String cid;
       Id[] fixedSearchResults= new Id[2];
        
       System.runAs (thisUser) {
        
       Environment_Setup__c env = new Environment_Setup__c();
       env.Akam_Id_Start_String__c = 'F-';
       insert env;
       
       SCUtilTestClass.createCustomSettingsForCase();
       
         a = new account();
        a.name='TestAccount';
        insert a;
        contact c = new contact();
        c.lastname='TestName';
        c.phone = '1234567890';
        
        c.accountid = a.id;
        insert c;
        
        fixedSearchResults[0] = c.id;

        insert t;
        }
        Test.setFixedSearchResults(fixedSearchResults);
        Test.startTest();
    
        PageReference myVfPage = Page.BSScreenPopPage;
        Test.setCurrentPage(myVfPage);
        
        ApexPages.currentPage().getParameters().put('lob','BOCC');
        ApexPages.currentPage().getParameters().put('ani','1234567890');
        ApexPages.currentPage().getParameters().put('taskid',t.id);
	    ApexPages.currentPage().getParameters().put('caseid','100012');
        
        BSScreenPopPageController bsppc = new BSScreenPopPageController();
        
        bsppc.runSelection();
        bsppc.runPrePopCheck();
        bsppc.updateTaskRecord();
        bsppc.updateUserSearch();
        bsppc.runSearchPhone('1234567890', true);
        bsppc.updateTask(t.Id);
        PageReference ptest = bsppc.navigateToId();
        bsppc.cti_data = 'test';
        bsppc.issueOnBehalf = true;
        bsppc.selectedId = t.Id;
        bsppc.matchedAccount = a;
     
       
        Test.stopTest();
        
    }

    
}