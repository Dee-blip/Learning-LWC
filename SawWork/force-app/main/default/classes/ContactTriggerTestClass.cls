/**
    ContactTriggerTestClass
    @version 1.0
    @author : Karteek Mekala <kmekala@akamai.com>
    @Description : This class implements the Unit Tests for ContactTrigger.
                   The use cases that are tested are :
                   - Single Contact update
                   - Contact update that has 2 duplicate leads associated to it.
                   - Contact update that has Bulk 'Converted' and Bulk 'Open Leads Associated to it.
                   - Bulk contacts update that have Bulk 'Converted' and Bulk 'Open Leads Associated to it.
    
    @History
    
    Ali KM          18/10/2010      CR 828372 Changes to Lead Field
                                    - Initializing Disposition to New when Leads are created.
    Ali KM          09/Jul/2012     CR 1741378 Manage scores during Contact merge process
                                    - Adding test cases for Merge Contacts.    
    Ruchika Sharma  26/02/2015      CR 2919927 Create Contact Accout Pick list limited to User Account and children
                                    - Added method partnerContactCreationOnCustAccountRestriction   
    Deepak Saxena   06/May/2015    CR 2541531 to move PSA Group ID to User level from Contact.
                                    - Added test method PSAGroupValuePopulationTest 
    Sharath Ravishankar 11/May/2015   Made modification in PSAGroupValuePopulationTest method to add the contact Id                                                                                      
*/
@isTest(SeeAllData=false)
private class ContactTriggerTestClass 
{
    private static Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
    
    //static User
    //static User dmlUser = utilTestClass.getTestRunUser();
    static User dmlUser = [select Id from User where Profile.Name = 'System Administrator' and Name != 'CRM Ops' and IsActive=True Limit 1][0];
    
    // Setup method to create test data.
    @testSetup
    static void setupMethod() {
        System.runAs(dmlUser) {
            
            ManagedPkgErrorClass.isFromManagedPackage = false;
            
            /* Start Of Custom Setting Insertion */
            Test.loadData(globalDescribe.get('Communities_Settings__c'), 'CS_Communities_Settings');
            /* End Of Custom Setting Insertion */
            
            //Create 2 accounts
            List<Account> accList = new List<Account>();
            Account accOld = utilTestClass.CreateAccount('__Test Old Account');
            accOld.Vertical__c = 'Gaming';
            accOld.Sub_Vertical__c = 'Console Mfs';
            accList.add(accOld);
            Account accNew = utilTestClass.CreateAccount('__Test New Account');
            accNew.Vertical__c = 'Gaming';
            accNew.Sub_Vertical__c = 'Console Mfs';     
            accList.add(accNew);
            //Create a partner account
            Account partnerAcc = utilTestClass.CreateAccount('__Test Partner Account');
            partnerAcc.Partner_Type__c = 'ADS Partner';
            partnerAcc.Partner_status__c = 'Partner';
            accList.add(partnerAcc);
            insert accList;
            
            partnerAcc.IsPartner = true;
            partnerAcc.Validation_Override__c=true;
            update partnerAcc;
            
            // Create contact
            List<Contact> conList = new List<Contact>();
            Contact con = utilTestClass.CreateContact('__ Test First','__Test Contact');
            con.AccountId = accOld.Id;
            conList.add(con);
            // Create contact with Partner Account
            Contact partnerCon = utilTestClass.CreateContact('__ Test First','__Test Partner');
            partnerCon.AccountId = partnerAcc.Id;
            conList.add(partnerCon);
            insert conList;
            
            Profile partnerAdminProfile = [select id,name from Profile where Name =:GsmUtilClass.getPRMSettingValue('Partner_Admin_Profile')]; // SFDC-2391 

            Integer userNumber=92;
            User PartnerAdmin=new User(
                Username='TstPar'+userNumber+'@akamai.com',
                Alias = 'test'+userNumber, 
                Email='TstPar'+userNumber+'@akamai.com', 
                FirstName='John', 
                LastName='Doe'+userNumber, 
                ProfileId = partnerAdminProfile.Id, 
                LanguageLocaleKey='en_US', 
                LocaleSidKey='en_US', 
                EmailEncodingKey='UTF-8', 
                TimeZoneSidKey='America/Los_Angeles',
                ContactId = partnerCon.id,
                UserPreferencesShowEmailToExternalUsers=true
            );
            test.startTest();
            insert PartnerAdmin; 
        }
    }
    
    /**
       SingleContact_PositiveTest()
       - Single Contact update
    */
    static testmethod void SingleContact_PositiveTest()
    {
        System.runAs(dmlUser){
            ManagedPkgErrorClass.isFromManagedPackage = false;
            Account accOld, accNew;
            Lead lead1, lead2;
            List<String> accNameList = new List<String>{'__Test Old Account','__Test New Account'};
                for(Account a : [select Id,Name from Account where Name IN : accNameList]){
                    If(a.Name == '__Test Old Account')
                        accOld = a;
                    Else
                        accNew = a;
                }
            Contact con = [select Id, AccountId from Contact where lastname = '__Test Contact'][0];
            List<Lead> leadList = new List<Lead>();
            Test.startTest();
            //Create 2 leads, 1 with Status - 'Open' and other with Status - 'Converted'
            lead1 = utilTestClass.CreateLead();
            lead2 = utilTestClass.CreateLead();
            lead1.Status = 'New';
            lead1.Disposition__c = 'New';
            lead1.Company = 'Use Contact Info';
            lead1.LastName = '__Lead_1';
            lead1.Email = 'test1@test.com';
            lead1.Associated_Contact__c = con.Id;
            lead1.Associated_Account__c = accOld.Id;
            lead1.Product_line__c='Aura';               
            leadList.add(lead1);
            lead2.Status = 'Converted';
            lead2.Disposition__c = 'New';
            lead2.Company = 'Use Contact Info';
            lead2.LastName = '__Lead_2';
            lead2.Email ='test2@test.com';
            lead2.Associated_Account__c = accOld.Id;
            lead2.Associated_Contact__c = con.Id; 
            lead2.Validation_Override__c = true;    //To get over "Converted" validation rule.
            leadList.add(lead2);
            insert leadList;
            
            con.AccountId = accNew.Id;
            update con;
            Test.stopTest();
            //Refresh the leads
            lead1 = [select Id,Associated_Account__c from Lead where Id=:lead1.Id];
            lead2 = [select Id,Associated_Account__c from Lead where Id=:lead2.Id];
            system.assertEquals(lead1.Associated_Account__c,accNew.Id);
            //system.assertEquals(lead2.Associated_Account__c,accOld.Id); //commenting temporary
        }
    }

    /**
       DuplicateLead_PositiveTest()
       - Contact update that has 2 duplicate leads associated to it.
    */
    /* Commenting this as this test is no longer required
    static testmethod void DuplicateLead_PositiveTest()
    {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        Account accOld, accNew;
        Lead lead1, lead2;
        List<String> accNameList = new List<String>{'__Test Old Account','__Test New Account'};
            for(Account a : [select Id,Name from Account where Name IN : accNameList]){
                If(a.Name == '__Test Old Account')
                    accOld = a;
                Else
                    accNew = a;
            }
        Contact con = [select Id, AccountId from Contact where lastname = '__Test Contact'][0];
        Test.startTest();
        System.runAs(dmlUser){
            //Create 2 leads, 1 with Status - 'Open' and other with Status - 'Converted'
            List<Lead> leadList = new List<Lead>();
            lead1 = utilTestClass.CreateLead();
            lead2 = utilTestClass.CreateLead();
            lead1.Status = 'New';
            lead1.Disposition__c = 'New';
            lead1.Company = 'Use Contact Info';
            lead1.LastName = '__Lead_1';
            lead1.Associated_Contact__c = con.Id;
            lead1.Associated_Account__c = accOld.Id;
            lead1.Product_line__c='Aura';               
            leadList.add(lead1);
            
            lead2.Status = 'New';
            lead2.Disposition__c = 'New';
            lead2.Company = 'Use Contact Info';
            lead2.LastName = '__Lead_2';
            lead2.Associated_Account__c = accOld.Id;
            lead2.Associated_Contact__c = con.Id;
            lead2.Product_line__c='Aura';       
            leadList.add(lead2);
            insert leadList;
            
            con.AccountId = accNew.Id;
            update con;
        }
        Test.stopTest();
        //Refresh the leads
        lead1 = [select Id,Associated_Account__c from Lead where Id=:lead1.Id];
        lead2 = [select Id,Associated_Account__c from Lead where Id=:lead2.Id];
        system.assertEquals(lead1.Associated_Account__c,accNew.Id);
        system.assertEquals(lead2.Associated_Account__c,accNew.Id);
    }*/
  
    /**
       BulkLead_PositiveTest()
       - Contact update that has Bulk 'Converted' and Bulk 'Open Leads Associated to it.
    */
    static testmethod void BulkLead_PositiveTest()
    {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        Account accOld, accNew;
        List<String> accNameList = new List<String>{'__Test Old Account','__Test New Account'};
            for(Account a : [select Id,Name from Account where Name IN : accNameList]){
                If(a.Name == '__Test Old Account')
                    accOld = a;
                Else
                    accNew = a;
            }
        Contact con = [select Id, AccountId from Contact where lastname = '__Test Contact'][0];
        Integer i=0;
        Lead[] Bulk_LeadOpen = new Lead[30];
        Lead[] Bulk_LeadConverted = new Lead[30];
        
        Test.startTest();
        System.runAs(dmlUser){
            for(i=0;i<30;i++)
            {
                Bulk_LeadOpen[i] = new Lead();
                Bulk_LeadOpen[i].Associated_Contact__c = con.Id;
                Bulk_LeadOpen[i].Associated_Account__c = accOld.Id;              
                Bulk_LeadOpen[i].Status = 'New';
                Bulk_LeadOpen[i].Disposition__c = 'New';
                Bulk_LeadOpen[i].Company = 'Use Contact Info';
                Bulk_LeadOpen[i].LastName = 'Use Contact Info';
                Bulk_LeadOpen[i].Product_line__c='Aura';
                Bulk_LeadOpen[i].Email='test@test.com';
            }
            
            for(i=0;i<30;i++)
            {       
                Bulk_LeadConverted[i] = new Lead();
                Bulk_LeadConverted[i].Associated_Account__c = accOld.Id;
                Bulk_LeadConverted[i].Associated_Contact__c = con.Id;             
                Bulk_LeadConverted[i].Status = 'Converted';
                Bulk_LeadConverted[i].Disposition__c = 'New';
                Bulk_LeadConverted[i].LeadSource = 'Web';
                Bulk_LeadConverted[i].QFA_Meeting_Date__c = date.today();
                Bulk_LeadConverted[i].Validation_Override__c = true;
                Bulk_LeadConverted[i].Business_Pain__c = 'Performance';
                Bulk_LeadConverted[i].Destination__c = 'ECG';
                Bulk_LeadConverted[i].Disposition__c='New';
                //Start Modified By Chandra For CR 693820
                Bulk_LeadConverted[i].Lead_Type__c = 'Prospect';
                //End Modified By Chandra For CR 693820
                Bulk_LeadConverted[i].Product__c= 'Custom';
                Bulk_LeadConverted[i].Product_Line__c = 'ADS';
                Bulk_LeadConverted[i].Project_Timeframe__c = '3 months or less';
                Bulk_LeadConverted[i].Customer_Type__c = 'Direct';
                Bulk_LeadConverted[i].Budget__c = 'Unsure'; 
                Bulk_LeadConverted[i].Company = 'Use Contact Info';
                Bulk_LeadConverted[i].LastName = 'Use Contact Info';  
                Bulk_LeadConverted[i].Email='test@test.com';
            }
            insert Bulk_LeadOpen;
            insert Bulk_LeadConverted;
            
            con.AccountId = accNew.Id;
            update con;
        }
        Test.stopTest();
        //Refresh the leads
        Bulk_LeadOpen = [select Id,Associated_Account__c from Lead where Id IN :Bulk_LeadOpen];
        Bulk_LeadConverted = [select Id,Associated_Account__c from Lead where Id IN :Bulk_LeadConverted];
        for(i=0;i<30;i++)
        {
            system.assertEquals(Bulk_LeadOpen[i].Associated_Account__c,accNew.Id);
            //system.assertEquals(Bulk_LeadConverted[i].Associated_Account__c,accOld.Id); //commenting temporary
        }
    }

    /**
       BulkContact_n_BulkLead_PositiveTest()
       - Bulk Contacts update that have Bulk 'Converted' and Bulk 'Open Leads Associated to it.
    */
    static testmethod void BulkContact_n_BulkLead_PositiveTest()
    {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        Account accOld, accNew;
        List<String> accNameList = new List<String>{'__Test Old Account','__Test New Account'};
            for(Account a : [select Id,Name from Account where Name IN : accNameList]){
                If(a.Name == '__Test Old Account')
                    accOld = a;
                Else
                    accNew = a;
            }
        Integer i=0;
        // Create a set of contacts
        Contact[] BulkCon = new Contact[50];
        for(i=0;i<50;i++)
        {
            
            BulkCon[i] = utilTestClass.CreateContact('__ Test First'+i,'__Test Contact'+i);
            BulkCon[i].AccountId = accOld.Id;
        }
        Lead[] Bulk_LeadOpen = new Lead[50];
        Lead[] Bulk_LeadConverted = new Lead[50];
        
        Test.startTest();
        System.runAs(dmlUser){
            insert BulkCon;
            for(i=0;i<50;i++)
            {
                Bulk_LeadOpen[i] = utilTestClass.CreateLead();
                Bulk_LeadOpen[i].Associated_Contact__c = BulkCon[i].Id;
                Bulk_LeadOpen[i].Associated_Account__c = accOld.Id;     
                Bulk_LeadOpen[i].Status = 'New';
                Bulk_LeadOpen[i].Disposition__c = 'New';
                Bulk_LeadOpen[i].Product_line__c='Aura';
                Bulk_LeadOpen[i].Company = 'Use Contact Info';
                Bulk_LeadOpen[i].LastName = 'Use Contact Info';
                Bulk_LeadOpen[i].Email='test@test.com';
            }
            for(i=0;i<50;i++)
            {       
                Bulk_LeadConverted[i] = utilTestClass.CreateLead();
                Bulk_LeadConverted[i].Associated_Account__c = accOld.Id;
                Bulk_LeadConverted[i].Associated_Contact__c = BulkCon[i].Id;   
                Bulk_LeadConverted[i].Status = 'Converted';
                Bulk_LeadConverted[i].Disposition__c = 'New';   
                Bulk_LeadConverted[i].QFA_Meeting_Date__c = date.today();
                Bulk_LeadConverted[i].Validation_Override__c = true;
                Bulk_LeadConverted[i].Business_Pain__c = 'Performance';
                Bulk_LeadConverted[i].Destination__c = 'ECG';
                Bulk_LeadConverted[i].Disposition__c='New';
                //Start Modified By Chandra For CR 693820
                Bulk_LeadConverted[i].Lead_Type__c = 'Prospect';
                //End Modified By Chandra For CR 693820
                Bulk_LeadConverted[i].Product__c= 'Custom';
                Bulk_LeadConverted[i].Product_Line__c = 'ADS';
                Bulk_LeadConverted[i].Project_Timeframe__c = '3 months or less';
                Bulk_LeadConverted[i].Customer_Type__c = 'Direct';
                Bulk_LeadConverted[i].Budget__c = 'Unsure';    
                Bulk_LeadConverted[i].Company = 'Use Contact Info';
                Bulk_LeadConverted[i].LastName = 'Use Contact Info'; 
                Bulk_LeadConverted[i].Email='test@test.com';
            }
            insert Bulk_LeadOpen;
            insert Bulk_LeadConverted;
            //Change the Contact.AccountId now
            for(i=0;i<50;i++)
            {       
                BulkCon[i].AccountId = accNew.Id;
            }
            update BulkCon;
        }
        Test.stopTest();
        //Refresh the leads 
        Bulk_LeadOpen = [select Id,Associated_Account__c from Lead where Id IN :Bulk_LeadOpen];
        Bulk_LeadConverted = [select Id,Associated_Account__c from Lead where Id IN :Bulk_LeadConverted];
        for(i=0;i<50;i++)
        {
            system.assertEquals(Bulk_LeadOpen[i].Associated_Account__c,accNew.Id);
            //system.assertEquals(Bulk_LeadConverted[i].Associated_Account__c,accOld.Id); //commenting temporary
        }
    }

    /**
       AssociatedAccountIDMap_Test()
       - Check the functionality of ContactTriggerClass.AssociatedAccountIDMap
       - This is called only when User is "CRM Integration"
       - This function populates the Contact.AccountId based on the recieved Contact.Associated_AKAM_Account_Id
    */
    static testmethod void AssociatedAccountIDMap_PositiveTest()
    {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        Account acc = [select Id, AKAM_Account_ID__c from Account where Name = '__Test Old Account'][0];
        User integrationUser = utilTestClass.CreateUser('_intg', 'Worldwide', 'CRM Integration');  
        System.RunAs(dmlUser){
            Test.StartTest();
            Contact con = utilTestClass.CreateContact('__ Test First','__Test Contact');
            system.runAs(integrationUser){
                con.Associated_AKAM_Account_ID__c = acc.AKAM_Account_ID__c;             
                insert con;
            }
            
            Test.stopTest();
            con = [select Id, AccountId, Associated_AKAM_Account_ID__c from Contact where Id=:con.Id ][0];
            // Test
            system.assertNotEquals(con, null);
            system.assertEquals(con.AccountId, acc.Id);
            system.assertEquals(con.Associated_AKAM_Account_ID__c, acc.AKAM_Account_ID__c);
        }
    }

    /**
       CheckDuplicatesTest()
       - Test ContactTriggerClass.CheckDuplicates
       - Contact.Name + Contact.Email should be unique.
    */
    static testmethod void CheckDuplicatesTest()
    {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        Account accOld = [select Id, AKAM_Account_ID__c from Account where Name = '__Test Old Account'][0];
        System.RunAs(dmlUser){
            Test.StartTest();
            Contact con = utilTestClass.CreateContact('__ Test First','__Test Contact');
            con.AccountId = accOld.Id;  
            con.email='DuplicateEmailtest@testing.com';
            insert con; 
            ContactTriggerClass.AssociatedAccountIDMapFirstRunFlag = true;      
            ContactTriggerClass.checkDuplicatesFirstRunFlag = true;
            // Error : Duplicate Insert attempt
            Contact newCon = utilTestClass.CreateContact('__ Test First','__Test Contact');
            newCon.email='DuplicateEmailtest@testing.com';
            newCon.AccountId = accOld.Id;
            Boolean failFlag = false;
            try
            {           
                insert newCon;
            }
            catch(Exception e)
            {
                system.assert(e.getMessage().contains('A contact with Contact Email '));
                system.assert(e.getMessage().contains('already exists'));
                failFlag = true;
            }              
            Test.stopTest();
            system.assertEquals(failFlag, true);
        }
        ContactTriggerClass.checkDuplicatesFirstRunFlag = true;
    }

    /**
       mergeContactTest()
       - Merges two contacts and checks if the Merged_ContactId is updated correctly.
    */
    static testmethod void mergeContactTest()
    {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        Account accOld = [select Id, AKAM_Account_ID__c from Account where Name = '__Test Old Account'][0];
        System.RunAs(dmlUser){
            List<Contact> conList = new List<Contact>();
            //contact 1
            Contact con = [select Id, AccountId from Contact where lastname = '__Test Contact'][0];
            //Create contact 2
            Contact newCon = utilTestClass.CreateContact('__ Test First2','__Test Contact2');
            newCon.email='DuplicateEmailtest2@testing.com';
            newCon.AccountId = accOld.Id;
            insert newCon;
            List<String> conNameList = new List<String>{'__Test Contact','__Test Contact2'};
                for(Contact c : [Select Id, MasterRecordId, AKAM_Contact_ID__c, Merged_ContactID__c, LastName from Contact where LastName IN : conNameList]){
                    If(c.LastName == '__Test Contact')
                        con = c;
                    Else
                        newCon = c;
                }
            Test.StartTest();
            merge newCon con;             
            Test.stopTest();
            //Refresh newCon
            newCon = [Select Id, MasterRecordId, AKAM_Contact_ID__c, Merged_ContactID__c from Contact where Id =: newCon.Id][0];
            system.assertEquals(con.AKAM_Contact_ID__c,newCon.Merged_ContactID__c);
        }
    }

    static testmethod void testPartnerUserEmailChangeOnPartnerContactEmailChange()
    {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        Account acc = [select Id, AKAM_Account_ID__c from Account where Name = '__Test Old Account'][0];
        System.RunAs(dmlUser){
            Test.StartTest();
            List<User> listOfPartnerUsers = new List<User>();
            {
                listOfPartnerUsers= utilTestClass.createPartnerUsers(100, acc.Id);
                //This is to make sure the Partner_User__c field on contact gets updated
            }
            PRM_opportunity.updateUserRoleProfileFutureInvokeFirstRunFlag=true;
            PRM_opportunity.updateUserUsernameOrEmailFutureInvokeFirstRunFlag=true;
            PRM_opportunity.updateUserFutureFlag=true;
            
            List<Id> contactIdList = new list<id>();
            List<Id> userIdList = new List<Id>();
            Map<Id, String> userIdToOldEmailMap = new Map<Id, String>();
            Map<Id, String> userIdToOldUsernameMap = new Map<Id, String>();
            for(User ithUser : listOfPartnerUsers)
            {
                contactIdList.add(ithUser.ContactId);
                userIdToOldEmailMap.put(ithUser.Id, ithUser.Email);
                userIdToOldUsernameMap.put(ithUser.Id, ithUser.Username);
                userIdList.add(ithUser.Id);
            }
            
            Integer userNumber = 0;
            List<Contact> listOfContacts = refreshContacts(contactIdList);
            Map<Id, String> contactIdToNewEmailMap = new Map<Id, String>();
            Map<Id, String> contactIdToNewLoginMap= new Map<Id, String>();
            //change contact email ids and contact login__c
            for(Contact ithContact : listOfContacts)
            {
                ithContact.Email = 'changed'+userNumber+'@akamai.com';
                ithContact.Login__c = 'changedLogin'+userNumber+'@akamai.com';
                contactIdToNewEmailMap.put(ithContact.Id, ithContact.Email);
                contactIdToNewLoginMap.put(ithContact.Id, ithContact.Login__c);
                userNumber++;
            }
            update listOfContacts;
            PRM_opportunity.updateUserUsernameOrEmail(contactIdToNewEmailMap, contactIdToNewLoginMap);
            listOfPartnerUsers = refreshUsers(userIdList);           
            Test.stopTest();
        }
    }

    /**
     partnerContactCreationOnCustAccountRestriction()
     - Test Method for restrictContactCreationByPartner and getContactsAccountHierarchy of ContactTriggerClass, which is called by ContactTrigger_bi_bu
     - restrict the partner to create a contact on other account (for which partner should not have access to create account like customer account)
       except the account associated with partner contact or children of that account
    */
    static testmethod void partnerContactCreationOnCustAccountRestriction()
    {
        System.runAs(dmlUser){
            ManagedPkgErrorClass.isFromManagedPackage = false;
            Account partnerAcc, custAcc;
            List<String> accNameList = new List<String>{'__Test Old Account','__Test Partner Account'};
                for(Account a : [select Id,Name from Account where Name IN : accNameList]){
                    If(a.Name == '__Test Old Account')
                        custAcc = a;
                    Else
                        partnerAcc = a;
                }
            Contact con = [select Id, AccountId from Contact where lastname = '__Test Partner'][0];
            User PartnerAdmin = [select Id from User where LastName = 'Doe92'];
            Test.startTest();
            //A partner user should not be allowed to create contact on account not associated with partner
            Boolean successFlag = true;
            System.RunAs(PartnerAdmin){
                try{
                    Contact custCon = utilTestClass.CreateContact('__ Test First','__Test Customer');
                    custCon.AccountId = custAcc.Id;
                    insert custCon;
                }
                catch(Exception e)
                {
                    successFlag = false;
                    System.debug('Error occurred: '+e.getMessage());
                }
                System.assert(successFlag==false, 'Partner is able to create contact on other accounts');
                //A partner user should be allowed to create contact on account associated with partner
                Contact parCon = utilTestClass.CreateContact('__ Test First','__Test Par');
                parCon.AccountId = partnerAcc.Id;
                insert parCon; 
            }
            Test.stopTest();
        }
    }

    // Test method to test PSA Group Id population from Contact to User
    static testmethod void PSAGroupValuePopulationTest()
    {
        System.runAs(dmlUser){
            ManagedPkgErrorClass.isFromManagedPackage = false;
            User u = utilTestClass.createUser('ds1108','WorldWide','System Administrator'); 
            Account accOld = [select Id, AKAM_Account_ID__c from Account where Name = '__Test Old Account'][0];
            Id recordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('PSA Resource').getRecordTypeId();
            
            pse__Grp__c grp = new pse__Grp__c(Name='Test Group');
            insert grp;
            
            Contact con = utilTestClass.CreateContact('__ Test First','__Test Contact');
            con.AccountId = accOld.Id;  
            con.email='DuplicateEmailtest@testing.com';
            con.RecordTypeId = recordTypeId;
            con.pse__Salesforce_User__c = u.Id; 
            con.pse__Group__c = grp.Id;
            
            Test.startTest();   
            insert con;
            Test.stopTest(); 
        }
    }

    //Test method for Method:associateContactToAccount
    static testmethod void associateContactToAccountTest()
    {
        Id wwwLeadGenAccountId = GSMUtilClass.getGSMSettingValue('ContactAssociation_WWWLeadGenAccountId');
        
        List<Domain__c> domainList = new List<Domain__c>();
        Domain__c dmn1 = new Domain__c();
        dmn1.Name = 'akamai.com';
        dmn1.Associated_Account__c = wwwLeadGenAccountId;//String.valueOf(wwwLeadGenAccountId).substring(0, 15);
        domainList.add(dmn1);
        
        Domain__c dmn2 = new Domain__c();
        dmn2.Name = 'test.com';
        dmn2.Associated_Account__c = wwwLeadGenAccountId;//String.valueOf(wwwLeadGenAccountId).substring(0, 15);
        domainList.add(dmn2);
        
        try{
            insert domainList;
        }catch(Exception e){
            
        }
        
        List<Contact> conList = new List<Contact>();
        Contact con = utilTestClass.CreateContact('_Test First','_Test Contact');
        con.AccountId = wwwLeadGenAccountId; //String.valueOf(wwwLeadGenAccountId).substring(0, 15) ; 
        con.email='DuplicateEmailtest@akamai.com';
        con.MailingCountry = 'India';
        conList.add(con);
        
        Contact con2 = utilTestClass.CreateContact('_Test Frst','_Test Cntact');
        con2.AccountId = wwwLeadGenAccountId; //String.valueOf(wwwLeadGenAccountId).substring(0, 15) ; 
        con2.email='DuplicateEmailtest@test.com';
        con2.MailingCountry = 'USA';
        conList.add(con2);
        
        Test.startTest();   
        System.runAs(dmlUser)
        {
            try{
                insert conList;
            }catch(Exception e){
                
            }
        }
        Test.stopTest(); 
    }

    static testmethod void restrictContactCreationByPartnertest()
    {
        System.runAs(dmlUser){
            ManagedPkgErrorClass.isFromManagedPackage = false;
            Account partnerAcc = [select Id from Account where Name = '__Test Partner Account'];
            List<Account> accList = new List<Account>();
            //Create a customer account
            for(Integer i=0;i<6;i++)
            {
                Account custAcc = utilTestClass.CreateAccount(i+'_Test Customer Account');
                custAcc.Vertical__c = 'Gaming';
                custAcc.Sub_Vertical__c = 'Console Mfs';     
                accList.add(custAcc);
            }

            insert accList;
            
            accList[0].parentId = partnerAcc.Id;
            accList[1].parentId = accList[0].Id;
            accList[2].parentId = accList[1].Id;
            accList[3].parentId = accList[2].Id;
            accList[4].parentId = accList[3].Id;

            update accList;
            
            Contact con = [select Id, AccountId from Contact where lastname = '__Test Partner'][0];
            User PartnerAdmin = [select Id from User where LastName = 'Doe92'];
            Test.startTest();
            //A partner user should not be allowed to create contact on account not associated with partner
            Boolean successFlag = true;
            System.RunAs(PartnerAdmin){
                try{
                    Contact custCon = utilTestClass.CreateContact('__ Test First','__Test Customer');
                    custCon.AccountId = partnerAcc.Id;
                    insert custCon;
                }
                catch(Exception e)
                {
                    successFlag = false;
                    System.debug('Error occurred: '+e.getMessage());
                }
            }
            Test.stopTest();
        }
    }
    
    public static List<Contact> refreshContacts(List<Id> contactIds)
    {
        return [select id, Email, Partner_User__c, Partner_User__r.Email from Contact where Id in :contactIds];
    }

    public static List<User> refreshUsers(List<Id> userIds)
    {
        return [select Id, Email, Username from User where Id in :userIds];
    }
}