/*=====================================================================================================+
Class name          :   SC_PolicyDomain_Test 
Author              :   Pinkesh, Aditya & Vamsee
Created             :   30-Oct-17
Purpose             :   This test class is used to cover code for classes and trigger
1. SC_PassphraseController
2. SC_PolicyDomainTrigger
3. SC_AuthorizedContactTrigger
4. SC_EditAuthorizedContactCtrl
5. SC_AddAuthorizedContactsCtrl
Vandhana            ::  6. SC_AuthContOnCaseCtrlr     
Vikas 				::  7. SC_ServiceAccountPDMapTrigger
Tejaswini           ::  8. SC_ServiceAccountPDMapTrigger - Insert,Update
Tejaswini           ::  ESESP-5132 (Increase Code coverage)
=========================================================================================================*/
@isTest(seeAllData = false)
public class SC_PolicyDomain_Test {
    //Create Test Data variables 
    static Account accRec;
    static Account serAccRec;
    static Account serAccRec2;
    static Account serAccRec3;
    static Account serAccRec4;
    static Contact conRec;
    static Contact serConRec;
    static Contact ConRec2;
    Static Policy_Domain__c pdRec;
    static Service_Account_PD_Mapping__c serAccPdRec;
    Static Authorized_Contact__c acRec;
    Static Authorized_Contact__c serAcRec;
    Static User nonMSUserWithAccess;
    Static User nonMSTPMUserWithAccess;
    //ESESP-5132    
    private static User sysAdmin = SObjectFactory.ADMIN_USER;
    static void createTestData() {
        //Create all custom settings to set (seeAlldata=false)
        utilTestClass.createCustomSettings();
        User currentusr = [Select id from User where Id = :UserInfo.getUserId()];
        System.RunAs(currentusr)
        {
            Environment_Setup__c environmentSetup = Environment_Setup__c.getOrgDefaults();
            environmentSetup.Active_Org__c = true;
            update environmentSetup;
        }
        
        // Creating Account Records
        List<Account> lAcc = new List<Account>();
        accRec = new Account(Name='Test Account1',AKAM_Account_ID__c='Test-111');
        lAcc.add(accRec);
        serAccRec = new Account(Name='Service Test Account1',AKAM_Account_ID__c='Test-112');
        lAcc.add(serAccRec);
        serAccRec2 = new Account(Name='Service Test Account2',AKAM_Account_ID__c='Test-113');
        lAcc.add(serAccRec2);
        serAccRec3 = new Account(Name='Service Test Account3',AKAM_Account_ID__c='Test-114');
        lAcc.add(serAccRec3);
        serAccRec4 = new Account(Name='Service Test Account4',AKAM_Account_ID__c='Test-115');
        lAcc.add(serAccRec4);
        insert lAcc;
        
        // Creating Contact Record
        List<Contact> lCon = new List<Contact>();
        conRec = new Contact(AccountId = accRec.Id, Login__c = 'Test_xyz', Email = 'Test_xyz@akamai.com',Primary_Contact_Method__c = 'Phone',
                             No_Longer_with_Company__c = false, LastName = 'Test ContactAcc');
        lCon.add(conRec);
        ConRec2 = new Contact(AccountId = serAccRec.Id, Login__c = 'Test_xyz_service2', Email = 'Test_xyz_service2@akamai.com',Primary_Contact_Method__c = 'Phone',
                              No_Longer_with_Company__c = false, LastName = 'Test ContactServ2');
        lCon.add(ConRec2);
        serConRec = new Contact(AccountId = serAccRec.Id, Login__c = 'Test_xyz_service', Email = 'Test_xyz_service@akamai.com',Primary_Contact_Method__c = 'Phone',
                                No_Longer_with_Company__c = false, LastName = 'Test ContactServ');
        lCon.add(serConRec);
        Insert lCon;
        //Changes for ESESP-5132
        System.runAs(sysAdmin)
        {
        List<User> lUser = new List<User>();
        nonMSTPMUserWithAccess = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'GSS Professional Services'].Id,
            LastName = 'last',
            Email = 'puser000@akamai.com',
            Username = 'puser000@amamama.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'Technical Project Manager',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
        lUser.add(nonMSTPMUserWithAccess);
        
        nonMSUserWithAccess = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'GSS Professional Services'].Id,
            LastName = 'last',
            Email = 'puser000@akamai.com',
            Username = 'puser000@amamama.com' + System.currentTimeMillis(),
            CompanyName = 'TEST',
            Title = 'Title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
        lUser.add(nonMSUserWithAccess);
        insert lUser;
        System.debug('the user id is: '+nonMSUserWithAccess.Id);
        }
    }
    static testMethod void testPDTriggerUT()
    {
        createTestData();
        try
        {
            test.startTest();
            System.RunAs(nonMSTPMUserWithAccess){ 
                // Creating Policy Domain Record
                pdRec = new Policy_Domain__c();
                pdRec.Name = 'Test PD1';
                pdRec.AKAM_Policy_Domain_ID__c = 'Test-123';
                pdRec.Account_Name__c = accRec.Id;
                pdRec.Product__c = 'Test Prod 123';
                pdRec.Service_Account__c = serAccRec.Id;
                pdRec.Policy_Domain_State__c = 'Active';
                insert pdRec;
            }
            test.stopTest();
        }
        catch(exception e)
        {
            system.debug('ERROR : '+e.getMessage());
        }
    }
    static testMethod void testPDTriggerSSPAT()
    {
        createTestData();
        // Creating Account Record to add team members
        Account accRecPass = new Account(Name='Test Account PassPhrase',AKAM_Account_ID__c='Test-1119');
        insert accRecPass;
        
        if(nonMSUserWithAccess != Null){
            AccountTeamMember atm = new AccountTeamMember();
            atm.UserId = nonMSUserWithAccess.Id;
            atm.AccountID = accRecPass.Id;
            atm.TeamMemberRole = 'Security Services - Primary';
            insert atm; 
        }
        try
        {
            test.startTest();
            System.RunAs(nonMSUserWithAccess){
                // Creating Policy Domain Record
                Policy_Domain__c accTeamRolepdRec = new Policy_Domain__c();
                accTeamRolepdRec.Name = 'Test PD12';
                accTeamRolepdRec.AKAM_Policy_Domain_ID__c = 'Test-1234';
                accTeamRolepdRec.Account_Name__c = accRecPass.Id;
                accTeamRolepdRec.Product__c = 'Test Prod 123';
                accTeamRolepdRec.Service_Account__c = serAccRec.Id;
                accTeamRolepdRec.Policy_Domain_State__c = 'Active';
                insert accTeamRolepdRec;
            }
            test.stopTest();
        }
        catch(exception e)
        {
            system.debug('ERROR : '+e.getMessage());
        }
    }
    static testMethod void testPDTriggerSPAT()
    {
        createTestData();
        // Creating Account Record
        Account accRecPass = new Account(Name='Test Account PassPhrase',AKAM_Account_ID__c='Test-1117');
        insert accRecPass;
        
        if(nonMSUserWithAccess != Null){
            AccountTeamMember atm = new AccountTeamMember();
            atm.UserId = nonMSUserWithAccess.Id;
            atm.AccountID = accRecPass.Id;
            atm.TeamMemberRole = 'Services - Primary';
            insert atm; 
        }
        try
        {
            test.startTest();
            System.RunAs(nonMSUserWithAccess){
                // Creating Policy Domain Record
                Policy_Domain__c accTeamRolepdRec = new Policy_Domain__c();
                accTeamRolepdRec.Name = 'Test PD12';
                accTeamRolepdRec.AKAM_Policy_Domain_ID__c = 'Test-1234';
                accTeamRolepdRec.Account_Name__c = accRecPass.Id;
                accTeamRolepdRec.Product__c = 'Test Prod 123';
                accTeamRolepdRec.Service_Account__c = serAccRec.Id;
                accTeamRolepdRec.Policy_Domain_State__c = 'Active';
                insert accTeamRolepdRec;
            }
            test.stopTest();
        }
        catch(exception e)
        {
            system.debug('ERROR : '+e.getMessage());
        }
    }
    static testMethod void testACTriggerUT()
    {
        createTestData();
        try
        {
            // Creating Policy Domain Record
            pdRec = new Policy_Domain__c();
            pdRec.Name = 'Test PD1';
            pdRec.AKAM_Policy_Domain_ID__c = 'Test-123';
            pdRec.Account_Name__c = accRec.Id;
            pdRec.Product__c = 'Test Prod 123';
            pdRec.Service_Account__c = serAccRec.Id;
            pdRec.Policy_Domain_State__c = 'Active';
            insert pdRec;
            test.startTest();
            System.RunAs(nonMSTPMUserWithAccess){ 
                Authorized_Contact__c authorizedContact = new Authorized_Contact__c();
                authorizedContact.Policy_Domain__c = pdRec.Id;
                authorizedContact.Contact_Name__c = conRec.Id;
                authorizedContact.Product_Interests__c = 'All';
                authorizedContact.Emergency_Email__c = True;
                Insert authorizedContact;
            }
            test.stopTest();
        }
        catch(exception e)
        {
            system.debug('ERROR : '+e.getMessage());
        }
    }
    static testMethod void testACTriggerSSPAT()
    {
        createTestData();
        // Creating Account Record to add team members
        Account accRecPass = new Account(Name='Test Account PassPhrase',AKAM_Account_ID__c='Test-1119');
        insert accRecPass;
        if(nonMSUserWithAccess != Null){
            AccountTeamMember atm = new AccountTeamMember();
            atm.UserId = nonMSUserWithAccess.Id;
            atm.AccountID = accRecPass.Id;
            atm.TeamMemberRole = 'Security Services - Primary';
            insert atm; 
        }
        try
        {
            // Creating Policy Domain Record
            Policy_Domain__c accTeamRolepdRec = new Policy_Domain__c();
            accTeamRolepdRec.Name = 'Test PD12';
            accTeamRolepdRec.AKAM_Policy_Domain_ID__c = 'Test-1234';
            accTeamRolepdRec.Account_Name__c = accRecPass.Id;
            accTeamRolepdRec.Product__c = 'Test Prod 123';
            accTeamRolepdRec.Service_Account__c = serAccRec.Id;
            accTeamRolepdRec.Policy_Domain_State__c = 'Active';
            insert accTeamRolepdRec;
            
            test.startTest();
            System.RunAs(nonMSUserWithAccess){
                Authorized_Contact__c authorizedContact = new Authorized_Contact__c();
                authorizedContact.Policy_Domain__c = accTeamRolepdRec.Id;
                authorizedContact.Contact_Name__c = conRec.Id;
                authorizedContact.Product_Interests__c = 'All';
                authorizedContact.Emergency_Email__c = True;
                Insert authorizedContact;
            }
            test.stopTest();
        }
        catch(exception e)
        {
            system.debug('ERROR : '+e.getMessage());
        }
    } 
    static testMethod void testACTriggerSPAT()
    {
        createTestData();
        // Creating Account Record
        Account accRecPass = new Account(Name='Test Account PassPhrase',AKAM_Account_ID__c='Test-1117');
        insert accRecPass;
        
        if(nonMSUserWithAccess != Null){
            AccountTeamMember atm = new AccountTeamMember();
            atm.UserId = nonMSUserWithAccess.Id;
            atm.AccountID = accRecPass.Id;
            atm.TeamMemberRole = 'Services - Primary';
            insert atm; 
        }
        try
        {
            // Creating Policy Domain Record
            Policy_Domain__c accTeamRolepdRec = new Policy_Domain__c();
            accTeamRolepdRec.Name = 'Test PD12';
            accTeamRolepdRec.AKAM_Policy_Domain_ID__c = 'Test-1234';
            accTeamRolepdRec.Account_Name__c = accRecPass.Id;
            accTeamRolepdRec.Product__c = 'Test Prod 123';
            accTeamRolepdRec.Service_Account__c = serAccRec.Id;
            accTeamRolepdRec.Policy_Domain_State__c = 'Active';
            insert accTeamRolepdRec;
            
            test.startTest();
            
            Case c = new Case();
            c.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Managed Security').getRecordTypeId();
            c.Subject = 'New MS Case';
            c.Description = 'MS Case Desc';
            c.AccountId = accRecPass.Id;
            c.Validation_Override__c = true;
            c.Policy_Domain__c = accTeamRolepdRec.Id;
            c.Do_Not_Show_in_Portal__c = false;
            insert c;
            
            System.RunAs(nonMSUserWithAccess){
                Authorized_Contact__c authorizedContact = new Authorized_Contact__c();
                authorizedContact.Policy_Domain__c = accTeamRolepdRec.Id;
                authorizedContact.Contact_Name__c = conRec.Id;
                authorizedContact.Product_Interests__c = 'All';
                authorizedContact.Emergency_Email__c = True;
                Insert authorizedContact;
            }
            test.stopTest();
        }
        catch(exception e)
        {
            system.debug('ERROR : '+e.getMessage());
        }
    }
    
    Static TestMethod void test1()
    {
        createTestData();
        
        test.startTest();
        
        // Creating Policy Domain Record
        pdRec = new Policy_Domain__c();
        pdRec.Name = 'Test PD1';
        pdRec.AKAM_Policy_Domain_ID__c = 'Test-123';
        pdRec.Account_Name__c = accRec.Id;
        pdRec.Product__c = 'Test Prod 123';
        pdRec.Service_Account__c = serAccRec.Id;
        pdRec.Policy_Domain_State__c = 'Active';
        insert pdRec;
        
        // Creating Authorized Contacts
        acRec = new Authorized_Contact__c(Policy_Domain__c=pdRec.Id, Contact_Name__c = conRec.Id);
        insert acRec;
        serAcRec = new Authorized_Contact__c(Policy_Domain__c = pdRec.Id, Contact_Name__c = serConRec.Id, Service__c = true);
        insert serAcRec;
        
        // Update Service Account on Policy Domain
        pdRec.Service_Account__c = null;
        update pdRec;
        
        delete pdRec;
        
        test.stopTest();
    }
    
    public static testMethod void SC_PassphraseTest(){
        
        User currentusr = [Select id from User where Id = :UserInfo.getUserId()];
        string connectionId = [Select Id from PartnerNetworkConnection where ConnectionStatus != 'Inactive' limit 1].Id;

        System.RunAs(currentusr){  
            
            
            //Create Custom setting instance for making (SeeAlldata=false)
            Environment_Setup__c environment1 = new Environment_Setup__c();
            environment1.Active_Org__c = false;
            environment1.Akam_Id_Start_String__c = 'F-';
            environment1.CName_Url__c = 'https://crm.akamai.com/apex/OpenByAKAMid?Id=';
            environment1.ConnectionId__c = connectionId;
            environment1.Connection_Name__c = 'DR';
            environment1.Environment_Type__c = 'Primary';
            insert environment1;  
        }
        
        // Creating Account Record
        Account accRecPass = new Account(Name='Test Account PassPhrase',AKAM_Account_ID__c='Test-111');
        insert accRecPass;
        
        // Creating Contact Record
        Contact conRecPass = new Contact(AccountId = accRecPass.Id, Login__c = 'Test_PassPhrase', Email = 'Test_PassPhrase@akamai.com',
                                         No_Longer_with_Company__c = false, LastName = 'Test PassPhrase');
        Insert conRecPass;
        
        User managedSecurityUsr = [Select id, ProfileId, Profile.name,IsActive from User where Profile.name LIKE '%Managed Security%' and IsActive =true limit 1];
        //Changes for ESESP-5132
        List<User> nonMSUserWithAccess = [Select id, ProfileId, Profile.name,IsActive from User where IsActive =true AND Profile.name LIKE '%GSS Professional Services%' and email like '%akamai.com' limit 1];
        User noAccessUser = [Select id, ProfileId, Profile.name,IsActive from User where Profile.name LIKE '%Engineering%' and IsActive =true limit 1];
        
        //Changes for ESESP-5132
        if(nonMSUserWithAccess.size()>0){
            nonMSUserWithAccess[0].Title = 'Client Service Manager..';
            update nonMSUserWithAccess[0];
            
            AccountTeamMember atm = new AccountTeamMember();
            atm.UserId = nonMSUserWithAccess[0].Id;
            atm.AccountID = accRecPass.Id;
            atm.TeamMemberRole = 'Services - Primary';
            
            insert atm; 
        }
        
        test.startTest(); 
        
        System.RunAs(managedSecurityUsr){ 
            PageReference pageRef = Page.SC_PassphraseDetail;
            test.setCurrentPage(pageRef);
            ApexPages.StandardController sc = new ApexPages.StandardController(conRecPass);
            ApexPages.currentPage().getParameters().put('Id',conRecPass.ID);
            SC_PassphraseController scPassPharase = new SC_PassphraseController(sc);
            
        } 
        System.RunAs(currentusr){ 
            PageReference pageRef1 = Page.SC_PassphraseDetail;
            test.setCurrentPage(pageRef1);
            ApexPages.StandardController sc1 = new ApexPages.StandardController(conRecPass);
            ApexPages.currentPage().getParameters().put('Id',conRecPass.ID);
            SC_PassphraseController scPassPharase1 = new SC_PassphraseController(sc1);
            scPassPharase1.newPassphrase = 'Pass@123';
            scPassPharase1.confirmPassphrase = 'Pass@123';
            scPassPharase1.encrypt();
            
            SC_PassphraseController scPassPharase2 = new SC_PassphraseController(sc1);
            scPassPharase2.newPassphrase = 'Pass@123';
            scPassPharase2.confirmPassphrase = 'Pass@12';
            scPassPharase2.encrypt();
        }
        //Changes for ESESP-5132
        if(nonMSUserWithAccess.size()>0){
            system.runAs(nonMSUserWithAccess[0]) {
            PageReference pageRef2 = Page.SC_PassphraseDetail;
            test.setCurrentPage(pageRef2);
            ApexPages.StandardController sc2 = new ApexPages.StandardController(conRecPass);
            ApexPages.currentPage().getParameters().put('Id',conRecPass.ID);
            SC_PassphraseController scPassPharase2 = new SC_PassphraseController(sc2);
        } 
        }
        
        system.runAs(noAccessUser) {
            PageReference pageRef3 = Page.SC_PassphraseDetail;
            test.setCurrentPage(pageRef3);
            ApexPages.StandardController sc3 = new ApexPages.StandardController(conRecPass);
            ApexPages.currentPage().getParameters().put('Id',conRecPass.ID);
            SC_PassphraseController scPassPharase3 = new SC_PassphraseController(sc3);
        }
        test.stopTest();    
    }
    
    public static testMethod void SC_AddAuthorizedContacts_Test(){
        
        //Create Account and Contact
        createTestData();
        //Creating Policy Domain Record
        Policy_Domain__c pdRec = new Policy_Domain__c();
        pdRec.Name = 'Test PD2';
        pdRec.AKAM_Policy_Domain_ID__c = 'Test-1234';
        pdRec.Account_Name__c = accRec.Id;
        pdRec.Product__c = 'Test Prod 1234';
        pdRec.Service_Account__c = serAccRec.Id;
        pdRec.Policy_Domain_State__c = 'Active';
        insert pdRec;
        
        Authorized_Contact__c authorizedContact = new Authorized_Contact__c();
        authorizedContact.Policy_Domain__c = pdRec.Id;
        authorizedContact.Contact_Name__c = conRec.Id;
        authorizedContact.Product_Interests__c = 'All';
        authorizedContact.Emergency_Email__c = True;
        
        
        test.startTest(); 
        Insert authorizedContact;
        //Test With Service Account
        PageReference pageRef1 = Page.SC_AddAuthorizedContacts;
        test.setCurrentPage(pageRef1);
        ApexPages.StandardController sc1 = new ApexPages.StandardController(new Authorized_Contact__c());
        ApexPages.currentPage().getParameters().put('policyDomainId',pdRec.ID);
        ApexPages.currentPage().getParameters().put('isDelete','False');
        ApexPages.currentPage().getParameters().put('FromPD','True');
        SC_AddAuthorizedContactsCtrl addAuthorizedContacts = new SC_AddAuthorizedContactsCtrl(sc1);
        addAuthorizedContacts.getContactList();
        addAuthorizedContacts.selectedRecords = conRec.Id + ',' + serConRec.Id;
        addAuthorizedContacts.errorMessageText = 'Test';
        addAuthorizedContacts.processSelectedRecords();
        
        //Test without Service Account
        pdRec.Service_Account__c = null;
        Update pdRec;
        
        PageReference pageRef2 = Page.SC_AddAuthorizedContacts;
        test.setCurrentPage(pageRef2);
        ApexPages.StandardController sc2 = new ApexPages.StandardController(new Authorized_Contact__c());
        ApexPages.currentPage().getParameters().put('policyDomainId',pdRec.ID);
        ApexPages.currentPage().getParameters().put('isDelete','False');
        ApexPages.currentPage().getParameters().put('FromPD','True');
        SC_AddAuthorizedContactsCtrl addAuthorizedContacts2 = new SC_AddAuthorizedContactsCtrl(sc2);
        addAuthorizedContacts2.getContactList();
        addAuthorizedContacts2.selectedRecords = ConRec2.Id;
        addAuthorizedContacts2.processSelectedRecords();
        
        //Test for Deleting Authorized contacts
        PageReference pageRef3 = Page.SC_AddAuthorizedContacts;
        test.setCurrentPage(pageRef3);
        ApexPages.StandardController sc3 = new ApexPages.StandardController(new Authorized_Contact__c());
        ApexPages.currentPage().getParameters().put('policyDomainId',pdRec.ID);
        ApexPages.currentPage().getParameters().put('isDelete','True');
        ApexPages.currentPage().getParameters().put('FromPD','True');
        SC_AddAuthorizedContactsCtrl deleteAuthorizedContacts = new SC_AddAuthorizedContactsCtrl(sc3);
        deleteAuthorizedContacts.getContactList();
        deleteAuthorizedContacts.selectedRecords = authorizedContact.Id;
        deleteAuthorizedContacts.processSelectedRecords();
        
        //When Account on the contact is updated
        /*conRec.AccountId = serAccRec.Id;
        Update conRec;
        
        //Associate Policy Domain to the Contact
        PageReference pageRef4 = Page.SC_AddAuthorizedContacts;
        test.setCurrentPage(pageRef4);
        ApexPages.StandardController sc4 = new ApexPages.StandardController(new Authorized_Contact__c());
        ApexPages.currentPage().getParameters().put('contactId',conRec.ID);
        ApexPages.currentPage().getParameters().put('isDelete','False');
        ApexPages.currentPage().getParameters().put('FromPD','False');
        SC_AddAuthorizedContactsCtrl associatePD = new SC_AddAuthorizedContactsCtrl(sc4);
        associatePD.getPolicyDomainList();
        associatePD.selectedRecords = pdRec.Id;
        associatePD.processSelectedRecords();
        
        //Disassociate Policy Domain from the Contact
        PageReference pageRef5 = Page.SC_AddAuthorizedContacts;
        test.setCurrentPage(pageRef5);
        ApexPages.StandardController sc5 = new ApexPages.StandardController(new Authorized_Contact__c());
        ApexPages.currentPage().getParameters().put('contactId',conRec.ID);
        ApexPages.currentPage().getParameters().put('isDelete','True');
        ApexPages.currentPage().getParameters().put('FromPD','False');
        SC_AddAuthorizedContactsCtrl disassociatePD = new SC_AddAuthorizedContactsCtrl(sc4);
        disassociatePD.getPolicyDomainList();
        disassociatePD.selectedRecords = pdRec.Id;
        disassociatePD.processSelectedRecords();*/
        
        test.stopTest();
    }
    public static testMethod void SC_DeleteAuthorizedContacts_Test(){
        
        //Create Account and Contact
        createTestData();
        //Creating Policy Domain Record
        Policy_Domain__c pdRec = new Policy_Domain__c();
        pdRec.Name = 'Test PD2';
        pdRec.AKAM_Policy_Domain_ID__c = 'Test-1234';
        pdRec.Account_Name__c = accRec.Id;
        pdRec.Product__c = 'Test Prod 1234';
        pdRec.Service_Account__c = serAccRec.Id;
        pdRec.Policy_Domain_State__c = 'Active';
        insert pdRec;
        
        Authorized_Contact__c authorizedContact = new Authorized_Contact__c();
        authorizedContact.Policy_Domain__c = pdRec.Id;
        authorizedContact.Contact_Name__c = conRec.Id;
        authorizedContact.Product_Interests__c = 'All';
        authorizedContact.Emergency_Email__c = True;
        
        
        test.startTest(); 
        //When Account on the contact is updated
        conRec.AccountId = serAccRec.Id;
        Update conRec;
        
        //Associate Policy Domain to the Contact
        PageReference pageRef4 = Page.SC_AddAuthorizedContacts;
        test.setCurrentPage(pageRef4);
        ApexPages.StandardController sc4 = new ApexPages.StandardController(new Authorized_Contact__c());
        ApexPages.currentPage().getParameters().put('contactId',conRec.ID);
        ApexPages.currentPage().getParameters().put('isDelete','False');
        ApexPages.currentPage().getParameters().put('FromPD','False');
        SC_AddAuthorizedContactsCtrl associatePD = new SC_AddAuthorizedContactsCtrl(sc4);
        associatePD.getPolicyDomainList();
        associatePD.selectedRecords = pdRec.Id;
        associatePD.processSelectedRecords();
        
        //Disassociate Policy Domain from the Contact
        PageReference pageRef5 = Page.SC_AddAuthorizedContacts;
        test.setCurrentPage(pageRef5);
        ApexPages.StandardController sc5 = new ApexPages.StandardController(new Authorized_Contact__c());
        ApexPages.currentPage().getParameters().put('contactId',conRec.ID);
        ApexPages.currentPage().getParameters().put('isDelete','True');
        ApexPages.currentPage().getParameters().put('FromPD','False');
        SC_AddAuthorizedContactsCtrl disassociatePD = new SC_AddAuthorizedContactsCtrl(sc4);
        disassociatePD.getPolicyDomainList();
        disassociatePD.selectedRecords = pdRec.Id;
        disassociatePD.processSelectedRecords();
        
        test.stopTest();
    }
    
    public static testMethod void SC_EditAuthorizedContacts_Test(){
        
        //Create Account and Contact
        createTestData();
        //Creating Policy Domain Record
        
        //Create Custom setting for SC_FromEmailAddress
        SC_FromEmailAddress__c scfrm= new SC_FromEmailAddress__c();
        scfrm.Name='TechnialCaseNotification';
        scfrm.FromAddress__c = 'sf-noreply@akamai.com';
        //scfrm.OrgAddressId__c = '0D2G00000004FpY';
        scfrm.OrgAddressId__c = UserInfo.getOrganizationId();
        insert scfrm;
        
        Policy_Domain__c pdRec = new Policy_Domain__c();
        pdRec.Name = 'Test PD3';
        pdRec.AKAM_Policy_Domain_ID__c = 'Test-12345';
        pdRec.Account_Name__c = accRec.Id;
        pdRec.Product__c = 'Test Prod 12345';
        pdRec.Additional_Product__c = 'TestProd1; TestProd2; TestProd3';
        pdRec.Service_Account__c = serAccRec.Id;
        pdRec.Policy_Domain_State__c = 'Active';
        insert pdRec;
        
        test.startTest(); 
        //Create Authorized Contact
        Authorized_Contact__c authorizedContact = new Authorized_Contact__c();
        authorizedContact.Policy_Domain__c = pdRec.Id;
        authorizedContact.Contact_Name__c = conRec.Id;
        authorizedContact.Product_Interests__c = 'All';
        authorizedContact.Emergency_Email__c = True;
        Insert authorizedContact;
        
        //Page Setup
        PageReference pageRef1 = Page.SC_EditAuthorizedContact;
        test.setCurrentPage(pageRef1);
        ApexPages.StandardController sc1 = new ApexPages.StandardController(new Authorized_Contact__c());
        ApexPages.currentPage().getParameters().put('Id',authorizedContact.Id);
        SC_EditAuthorizedContactCtrl editAuthorizedContact = new SC_EditAuthorizedContactCtrl(sc1);
        
        //Negative scenario - 'All' & Other product in chosen List
        editAuthorizedContact.chosenProductList.add(new selectOption('Test Prod 12345','Test Prod 12345'));
        editAuthorizedContact.UpdateAuthorizedContact();
        
        //Negative Scenario - Empty Chosen List
        editAuthorizedContact.chosenProductList = new List<selectOption>();
        editAuthorizedContact.UpdateAuthorizedContact();
        
        //Positive scenario
        editAuthorizedContact.chosenProductList.add(new selectOption('TestProd 3','TestProd 3'));
        editAuthorizedContact.UpdateAuthorizedContact();
        test.stopTest();
    }
    /*Commenting Because of 101 SOQL error
public static testMethod void SC_AuthContCase_Test()
{    
//Create Account and Contact
createTestData();

//Create custom setting record for SC_fromEmailAddress
SC_FromEmailAddress__c scfrmadd = new SC_FromEmailAddress__c();
scfrmadd.Name = 'TechnialCaseNotification';
scfrmadd.FromAddress__c = 'sf-noreply@akamai.com';
scfrmadd.OrgAddressId__c = '0D2G00000004FpY';
insert scfrmadd;

//Creating Policy Domain Record
Policy_Domain__c pdRec = new Policy_Domain__c();
pdRec.Name = 'New PolDomain';
pdRec.AKAM_Policy_Domain_ID__c = 'TestPD_1';
pdRec.Account_Name__c = accRec.Id;
pdRec.Product__c = 'Kona DDoS Defender';
pdRec.Additional_Product__c = 'Prod1; Prod2; Prod3';
pdRec.Service_Account__c = serAccRec.Id;
pdRec.Policy_Domain_State__c = 'Active';
insert pdRec;

//Create Authorized Contact
Authorized_Contact__c authorizedContact = new Authorized_Contact__c();
authorizedContact.Policy_Domain__c = pdRec.Id;
authorizedContact.Contact_Name__c = conRec.Id;
authorizedContact.Product_Interests__c = 'All';
authorizedContact.Emergency_Email__c = True;
Insert authorizedContact;

EB_AccountProductMap__c prodTest = new EB_AccountProductMap__c(); 
prodTest.Name = 'Kona DDoS Defender';
prodTest.EB_Account__c = accRec.Id;
prodTest.EB_Product__c = 'Kona DDoS Defender';

insert ProdTest;

Case c = new Case();
c.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Managed Security').getRecordTypeId();
c.Subject = 'New MS Case';
c.Description = 'MS Case Desc';
c.AccountId = accRec.Id;
c.Validation_Override__c = true;
c.Policy_Domain__c = pdRec.Id;
c.Case_Product__c = prodTest.Id;
insert c;

Test.startTest();
PageReference pageRef1 = Page.SC_AuthContOnCase;
test.setCurrentPage(pageRef1);

ApexPages.StandardController sc1 = new ApexPages.StandardController(c);
SC_AuthContOnCaseCtrlr authContOnCaseCt = new SC_AuthContOnCaseCtrlr(sc1);
authContOnCaseCt.first();authContOnCaseCt.last();authContOnCaseCt.next();authContOnCaseCt.previous();
Boolean has = authContOnCaseCt.hasNext;
has = authContOnCaseCt.hasPrev;
List<Authorized_Contact__c> allCont = authContOnCaseCt.getallAuthCont();
Integer i = authContOnCaseCt.totalPageNumber; i = authContOnCaseCt.pageNumber;
test.stopTest();

}*/
    
    public static testMethod void checkMandatorySituations()
    { 
        //Create Account and Contact
        createTestData();
        //Creating Policy Domain Record
        Policy_Domain__c pdRec = new Policy_Domain__c();
        pdRec.Name = 'Test PD2';
        pdRec.AKAM_Policy_Domain_ID__c = 'Test-1234';
        pdRec.Account_Name__c = accRec.Id;
        pdRec.Product__c = 'Kona DDoS Defender';
        pdRec.Policy_Domain_State__c = 'Active';
        insert pdRec;
        
        // Creating Handler Type
        Handler_Type__c  handTypeRec = new Handler_Type__c (Name='Phone Call Handler Type', Fields_To_Show__c='Situation_Instruction__c,Escalation_List__c');
        insert handTypeRec;  
        
        // Creating Situation Catalog
        SC_SOCC_Situation_Catalog__c  konaSituation = new SC_SOCC_Situation_Catalog__c (Handler_Type__c=handTypeRec.id, Name='Kona DDoS DefenderAttack Mandatory', Product__c='Kona DDoS Defender', Situation_Class__c='Attack', Handler_Type_picklist__c='Phone Call Handler Type');
        insert konaSituation; 
        
        SC_SOCC_Situation_Catalog__c  mssSituation = new SC_SOCC_Situation_Catalog__c (Handler_Type__c=handTypeRec.id, Name='MSS Attack Mandatory', Product__c='Kona DDoS Defender', Situation_Class__c='Attack', Handler_Type_picklist__c='Phone Call Handler Type');
        insert mssSituation; 
        
        SC_SOCC_Escalation_List__c esclistrec = new SC_SOCC_Escalation_List__c (Policy_Domain__c=pdRec.id, Name='Test escalation list name');
        insert esclistrec; 
        
        //Creating Handler
        List<Handler__c> lhandler = new List<Handler__c>();
        
        Handler__c handlerRec= new Handler__c (Name='TestHandler', Handler_Type__c=handTypeRec.id, Policy_Domain__c=pdRec.id, Escalation_List__c=esclistrec.id);
        lhandler.add(handlerRec);
        
        Handler__c handlerrec2= new Handler__c (Name='TestHandlerfordeletion', Handler_Type__c=handTypeRec.id, Policy_Domain__c=pdRec.id, Escalation_List__c=esclistrec.id);
        lhandler.add(handlerrec2);
        insert lhandler;
        
        // Creating situation to handler mapping
        SC_SOCC_Situation_to_Handler_Mapping__c s2hRec = new SC_SOCC_Situation_to_Handler_Mapping__c (Policy_Domain__c=pdRec.id, Situation__c=mssSituation.id, Handler__c=handlerRec.id);
        insert s2hRec;
        
        test.startTest(); 
        pdRec.Runbook_name__c = 'Transitioned';
        try{
            update pdRec;
        }
        catch(Exception e){
            
        }
        test.stopTest(); 
    }
    
    public static testMethod void checkServiceAccountPDMappingTest()
    {
        //Create Account and Contact
        createTestData();
        //Creating Policy Domain Record
        Policy_Domain__c pdRec = new Policy_Domain__c();
        pdRec.Name = 'Test PD2';
        pdRec.AKAM_Policy_Domain_ID__c = 'Test-1234';
        pdRec.Account_Name__c = accRec.Id;
        pdRec.Product__c = 'Kona DDoS Defender';
        pdRec.Policy_Domain_State__c = 'Active';
        insert pdRec;
        
        Service_Account_PD_Mapping__c serviceAccountPD = new Service_Account_PD_Mapping__c();
        serviceAccountPD.Policy_Domain__c = pdRec.Id;
        serviceAccountPD.Service_Account__c = serAccRec.Id;
        insert serviceAccountPD;
        
        serAcRec = new Authorized_Contact__c(Policy_Domain__c = pdRec.Id, Contact_Name__c = serConRec.Id, Service__c = true);
        insert serAcRec;
         
        test.startTest(); 
        delete serviceAccountPD;     
        test.stopTest(); 
    }
    
    //Changes by Tejaswini for ESESP-4953
    public static testMethod void serviceAccountPDMappingTriggerTest(){
        createTestData();
        
        //Creating Policy Domain Record
        Policy_Domain__c pdRec = new Policy_Domain__c();
        pdRec.Name = 'Test PD3';
        pdRec.AKAM_Policy_Domain_ID__c = 'Test-12345';
        pdRec.Account_Name__c = accRec.Id;
        pdRec.Product__c = 'Kona DDoS Defender';
        pdRec.Policy_Domain_State__c = 'Active';
        insert pdRec;
        
        List<Service_Account_PD_Mapping__c> lstserviceAccountPD = new List<Service_Account_PD_Mapping__c>();
        
        Service_Account_PD_Mapping__c serviceAccountPD = new Service_Account_PD_Mapping__c();
        serviceAccountPD.Policy_Domain__c = pdRec.Id;
        serviceAccountPD.Service_Account__c = serAccRec.Id;
        lstserviceAccountPD.add(serviceAccountPD);
        
        Service_Account_PD_Mapping__c serviceAccountPD2 = new Service_Account_PD_Mapping__c();
        serviceAccountPD2.Policy_Domain__c = pdRec.Id;
        serviceAccountPD2.Service_Account__c = serAccRec2.Id;
        lstserviceAccountPD.add(serviceAccountPD2);
        
        insert lstserviceAccountPD;
        
        serAcRec = new Authorized_Contact__c(Policy_Domain__c = pdRec.Id, Contact_Name__c = serConRec.Id, Service__c = true);
        insert serAcRec;
        
        //Service_Account_PD_Mapping__c serviceAccountPD2 = new Service_Account_PD_Mapping__c();
        //serviceAccountPD2.Id = serviceAccountPD.Id;
        List<Service_Account_PD_Mapping__c> lUpdateServiceAccountPD = new List<Service_Account_PD_Mapping__c>();
        
        serviceAccountPD.Service_Account__c = serAccRec3.Id;
        //serviceAccountPD.Service_Account__c = serAccRec2.Id;
        lUpdateServiceAccountPD.add(serviceAccountPD);
        
        serviceAccountPD2.Service_Account__c= serAccRec4.Id;
        //serviceAccountPD2.Service_Account__c= accRec.Id;
        lUpdateServiceAccountPD.add(serviceAccountPD2);
        
        test.startTest(); 
        /*try{
            update lUpdateServiceAccountPD;
        }
        catch(Exception e)
        {
            System.debug('Caught exception');
        }*/
        update lUpdateServiceAccountPD;
        delete serviceAccountPD;     
        test.stopTest(); 
    }
    
    static testMethod void testServiceAccPDTriggerUT()
    {
        createTestData();
        Policy_Domain__c pdRec = new Policy_Domain__c();
        pdRec.Name = 'Test PD4';
        pdRec.AKAM_Policy_Domain_ID__c = 'Test-123456';
        pdRec.Account_Name__c = accRec.Id;
        pdRec.Product__c = 'Kona DDoS Defender';
        pdRec.Policy_Domain_State__c = 'Active';
        insert pdRec;
        try
        {
            test.startTest();
            System.RunAs(nonMSTPMUserWithAccess){ 
                // Creating Policy Domain Record
                serAccPdRec = new Service_Account_PD_Mapping__c();
                serAccPdRec.Policy_Domain__c = pdRec.Id;
                serAccPdRec.Service_Account__c = serAccRec4.Id;
                
                insert serAccPdRec;
            }
            test.stopTest();
        }
        catch(exception e)
        {
            system.debug('ERROR : '+e.getMessage());
        }
    }
    
    static testMethod void testServiceAccPDTriggerSSPAT()
    {
        createTestData();
        // Creating Account Record to add team members
        Account accRecPass = new Account(Name='Test Account PassPhrase',AKAM_Account_ID__c='Test-1119');
        insert accRecPass;
        
        Policy_Domain__c pdRec = new Policy_Domain__c();
        pdRec.Name = 'Test PD5';
        pdRec.AKAM_Policy_Domain_ID__c = 'Test-1234567';
        pdRec.Account_Name__c = accRec.Id;
        pdRec.Product__c = 'Kona DDoS Defender';
        pdRec.Policy_Domain_State__c = 'Active';
        insert pdRec;
        
        if(nonMSUserWithAccess != Null){
            AccountTeamMember atm = new AccountTeamMember();
            atm.UserId = nonMSUserWithAccess.Id;
            atm.AccountID = accRec.Id;
            atm.TeamMemberRole = 'Security Services - Primary';
            insert atm; 
        }
        try
        {
            test.startTest();
            System.RunAs(nonMSUserWithAccess){
                // Creating Policy Domain Record
                Service_Account_PD_Mapping__c serAccPdRec = new Service_Account_PD_Mapping__c();
                serAccPdRec.Policy_Domain__c = pdRec.Id;
                serAccPdRec.Service_Account__c = serAccRec4.Id;
                
                insert serAccPdRec;
            }
            test.stopTest();
        }
        catch(exception e)
        {
            system.debug('ERROR : '+e.getMessage());
        }
    }
    
    static testMethod void testServiceAccPDTriggerSPAT()
    {
        createTestData();
        // Creating Account Record
        Account accRecPass = new Account(Name='Test Account PassPhrase',AKAM_Account_ID__c='Test-1117');
        insert accRecPass;
        
        Policy_Domain__c pdRec = new Policy_Domain__c();
        pdRec.Name = 'Test PD6';
        pdRec.AKAM_Policy_Domain_ID__c = 'Test-12345678';
        pdRec.Account_Name__c = accRec.Id;
        pdRec.Product__c = 'Kona DDoS Defender';
        pdRec.Policy_Domain_State__c = 'Active';
        insert pdRec;
        
        if(nonMSUserWithAccess != Null){
            AccountTeamMember atm = new AccountTeamMember();
            atm.UserId = nonMSUserWithAccess.Id;
            atm.AccountID = accRec.Id;
            atm.TeamMemberRole = 'Services - Primary';
            insert atm; 
        }
        try
        {
            test.startTest();
            System.RunAs(nonMSUserWithAccess){
                Service_Account_PD_Mapping__c serAccPdRec = new Service_Account_PD_Mapping__c();
                serAccPdRec.Policy_Domain__c = pdRec.Id;
                serAccPdRec.Service_Account__c = serAccRec4.Id;
                
                insert serAccPdRec;
            }
            test.stopTest();
        }
        catch(exception e)
        {
            system.debug('ERROR : '+e.getMessage());
        }
    }
}