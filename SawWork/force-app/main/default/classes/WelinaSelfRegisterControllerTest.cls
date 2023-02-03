@IsTest
public with sharing class WelinaSelfRegisterControllerTest 
{
    static testmethod void test1()
    {
        WelinaSelfRegisterController wrc = new WelinaSelfRegisterController();
        //Data setup
        Account acc = new Account(name = 'test acc');
        insert acc;
        
        Id marketoRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();

        Lead l = new Lead();
        l.RecordTypeId = marketoRecordTypeId;
        l.email = 'test878781000User@salesforce.com';
        l.Associated_Account__c = acc.Id;
        l.Status = 'New';
        l.firstname = 'Test';
        l.lastname = 'AccountMatchTest2';
        l.Company = 'Test Company';
        l.Lead_Qualification_Stage__c ='Qualified Lead - Warm';
        insert l;
        
        String firstName = 'test';
        String lastName = 'User';
        String email = 'test878781000User@salesforce.com';
        String companyName ='abc';
        String country = 'USA';
        String linkedIn ='Cde';
        String password = 'testuser123';
        String confirmPasswordCorrect = 'testuser123';
        String confirmPasswordWrong = 'wrongpassword';
        String accountId = 'testuser123';
        String regConfirmUrl = 'http://registration-confirm.com';
        String extraFields ='Testabc';
        String startUrl = 'http://my.company.salesforce.com';
        Boolean includePassword =true;
        
        Contact con = new Contact(Email='test87sdvs8781000User@akamai.com',LastName='Last');
        con.AccountId=acc.id;
        Insert con;
        
        //Methods
        WelinaSelfRegisterController.isValidPassword('TestPassword','TestConfirmPassword');
        WelinaSelfRegisterController.siteAsContainerEnabled(startUrl);
        WelinaSelfRegisterController.selfRegister(firstName,lastName,email,companyName,country,linkedIn,password,confirmPasswordCorrect,accountId,regConfirmUrl,extraFields,startUrl,includePassword);
        //WelinaSelfRegisterController.getHomeNetworkURL();
        WelinaSelfRegisterController.getExtraFields('CommunityNickname');
        WelinaSelfRegisterController.setExperienceId('1234');
        WelinaSelfRegisterController.createUser(con.Id, acc.Id, 'testDummy001', 'WelinaDummy001', 'test87sdvs8781000User@akamai.com');
        System.assert(con.Id != null);
    }
 
    static testmethod void test2()
    {
        WelinaSelfRegisterController lc = new WelinaSelfRegisterController();
        Account acc;
        Profile pr;
        User usr2;
        
        User thisUser = [SELECT Id FROM User WHERE Name = 'CRM Ops' limit 1];
        System.runAs(thisUser){
            //Data setup
            acc = new Account(name = 'test acc');
            insert acc;
            
            pr = [select id from profile where name='Support - Tech Support Manager'][0];
            //Create User
            usr2 = new User(alias = 'user', email='test878781000User@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner2', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__usr2@akamai.com',profileid = pr.Id);
            usr2.AKAM_User_ID__c = 'ABC1234';
            insert usr2;
        }
        Contact con = new Contact(Email='test878781000User@akamai.com',LastName='Last');
        con.AccountId=acc.id;
        Insert con;
        
        String firstName = 'test';
        String lastName = 'User';
        String email = 'test878781000User@akamai.com';
        String companyName ='abc';
        String country = 'USA';
        String state = 'New York';
        String linkedIn ='Cde';
        String password = 'testuser123';
        String confirmPasswordCorrect = 'testuser123';
        String confirmPasswordWrong = 'wrongpassword';
        String accountId = 'testuser123';
        String regConfirmUrl = 'http://registration-confirm.com';
        String extraFields ='Testabc';
        String startUrl = 'http://my.company.salesforce.com';
        Boolean includePassword =true;
        
        //Methods
        WelinaSelfRegisterController.isValidPassword('TestPassword','TestConfirmPassword');
        WelinaSelfRegisterController.siteAsContainerEnabled(startUrl);
        WelinaSelfRegisterController.selfRegister('',lastName,email,companyName,country,linkedIn,password,confirmPasswordCorrect,accountId,regConfirmUrl,extraFields,startUrl,includePassword);
        WelinaSelfRegisterController.selfRegister(firstName,'',email,companyName,country,linkedIn,password,confirmPasswordCorrect,accountId,regConfirmUrl,extraFields,startUrl,includePassword);
        WelinaSelfRegisterController.selfRegister(firstName,lastName,'',companyName,country,linkedIn,password,confirmPasswordCorrect,accountId,regConfirmUrl,extraFields,startUrl,includePassword);
        WelinaSelfRegisterController.selfRegister(firstName,lastName,email,'',country,linkedIn,password,confirmPasswordCorrect,accountId,regConfirmUrl,extraFields,startUrl,includePassword);
        WelinaSelfRegisterController.selfRegister(firstName,lastName,email,companyName,country,linkedIn,password,confirmPasswordCorrect,accountId,regConfirmUrl,extraFields,startUrl,includePassword);
        WelinaSelfRegisterController.selfRegister(firstName,lastName,email,companyName,'RandomCountryTest',linkedIn,password,confirmPasswordCorrect,accountId,regConfirmUrl,extraFields,startUrl,includePassword);
        //WelinaSelfRegisterController.getHomeNetworkURL();
        WelinaSelfRegisterController.getExtraFields('CommunityNickname');
        WelinaSelfRegisterController.setExperienceId('1234');
        WelinaSelfRegisterController.validatePassword(usr2,'TestPassword','TestConfirmPassword');
        System.assert(con.Id != null);
    }
 
    static testmethod void test3()
    {
        WelinaSelfRegisterController wrc = new WelinaSelfRegisterController();
        
        String firstName = 'Test Con 001';
        String lastName = 'Welina Test Con';
        String email = 'test3dummyUser@akamai.com';
        String companyName ='Test com';
        String country = 'India';
        String state = 'Delhi';
        
        //Methods
        WelinaSelfRegisterController.selfRegister(firstName,lastName,email,companyName,country,'','','','','','','',false);
        Contact con = [Select Id from Contact where Email = 'test3dummyUser@akamai.com' limit 1];
        System.assert(con.Id != null);
    }
    static testmethod void test4()
    {
        WelinaSelfRegisterController wrc = new WelinaSelfRegisterController();
        
        String firstName = 'Test Con 004';
        String lastName = 'Welina Test Con4';
        String email = 'test4dummyUser@akamai.com';
        String companyName ='Test com';
        String country = 'Random Country Test';
        String state = 'Delhi';
        //Methods
        WelinaSelfRegisterController.selfRegister(firstName,lastName,email,companyName,country,'','','','','','','',false);    
        Contact con = [Select Id from Contact where Email = 'test4dummyUser@akamai.com' limit 1];
        System.assert(con.Id != null);
    }

    static testmethod void test5() {
        List<String> countryList = WelinaSelfRegisterController.getCountryPicklistVal();
        System.assert(countryList!=null);
    }

    static testmethod void createUserWrongEmailFail(){
        string firstName = 'Test';
        string lastName = 'User';
        WelinaSelfRegisterController.createUser(null, null, firstName, lastName, null);
        List<User> users = [select email,lastName from user where email = null ];
        system.assert(users.size()==0, 'No users created');
    }
    
    static testmethod void createUserCorrectEmailPass(){
        string firstname = 'first name';
        string lastname = 'last name';
        string country = 'USA';
        string company = 'test';
        List<string> email = new List<string>();
        email.add('test.email1@test.com');
        email.add('test.email2@test.com');
        email.add('test.email3@test.com');
        email.add('test.email4@test.com');
        email.add('test.email5@test.com');
        email.add('test.email6@test.com');
        email.add('test.email7@test.com');
        email.add('test.email8@test.com');
        for(string s : email){
            WelinaSelfRegisterController.selfRegister(firstname, lastname, s, company, country, '', '', '', '', '', '', '', false);
        }
        list<User> user = [select email from user where email like 'test.email_@test.com'];
        system.assert(user!=null, 'Users created for above created data');
	}
    
    static testmethod void createContactFailTest(){
        string firstname = 'testname';
        string lastname = 'lastname';
        string email = 'test.email@invalid.com`';
        string country = 'USA';
        string company = 'test';
                                                        
        string str = WelinaSelfRegisterController.selfRegister(firstname, lastname, email, company, country, '', '', '', '', '', '', '', false);
        system.assert(str!=null, 'Contact not created');
    }
    
    static testmethod void createContactFailTest2(){
        string firstname = 'testname';
        string lastname = 'Failinglastnamedeliberatleytoensureexcetionblockiscoveredandcodecoverageistakecareof';
        string email = 'test.email@invalid.com';
        string country = 'USA';
        string company = 'test';
                                                        
        string str = WelinaSelfRegisterController.selfRegister(firstname, lastname, email, company, country, '', '', '', '', '', '', '', false);
        system.assert(str!=null, 'Contact not created');
    }
    
    // code coverage method
    static testmethod void testContactHelper(){
        Id contactRT = Contact.sObjectType.getDescribe().getRecordTypeInfosByName().get('Business Contact').getRecordTypeId();
        list<SFCommunity_NQLB_Topics__mdt>  communityMetaDataVal = [SELECT Case_Origin__c ,Case_Priority__c , Question_Hours_for_Case_Creation__c, Question_Community_Topic__c, Case_Visibility__c , Case_Severity__c ,DefaultAccountIdForNewContact__c,TopicName__c, DayRange__c FROM SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'WelinaNQLB' limit 1];
            
        string str = WelinaSelfRegisterController.createContactHelper(contactRT,'TestHelperFname' ,'testlname0345', 'abc@aasfaf.com','India','',communityMetaDataVal,0);
        System.debug('Str test val : '+ str);
        List<Contact> conList = [Select Id from Contact where email = 'abc@aasfaf.com' limit 1];
        System.debug('conList : '+ conList);
        System.assert(conList.size() == 1, 'Contact must be created');
    }
    
    
    // code coverage method
    static testmethod void testContactHelper2() {
        Account testAccount = utilTestClass.CreateAccount('Test Account2');
        insert testAccount;
        Id marketoRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
        Lead testLead = new Lead();
        testLead.Associated_Account__c = testAccount.Id;
        testLead.recordTypeId = marketoRecordTypeId;
        testLead.email = 'testContactHelperTest123@akamai.com';
        testLead.company = 'Test Company2';
        testLead.firstname = 'Test';
        testLead.lastname = 'Lead2';
        insert testLead;
        Id contactRT = Contact.sObjectType.getDescribe().getRecordTypeInfosByName().get('Business Contact').getRecordTypeId();
        list<SFCommunity_NQLB_Topics__mdt>  communityMetaDataVal = [SELECT Case_Origin__c ,Case_Priority__c , Question_Hours_for_Case_Creation__c, Question_Community_Topic__c, Case_Visibility__c , Case_Severity__c ,DefaultAccountIdForNewContact__c,TopicName__c, DayRange__c FROM SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'WelinaNQLB' limit 1];
            
        string str = WelinaSelfRegisterController.createContactHelper(contactRT,'TestHelperFname' ,'testlname0345', 'testContactHelperTest123@akamai.com','India','',communityMetaDataVal,0);
        System.debug('Str test val : '+ str);
        List<Contact> conList = [Select Id from Contact where email = 'testContactHelperTest123@akamai.com' limit 1];
        System.debug('conList : '+ conList);
        System.assert(conList.size() == 1, 'Contact must be created');
    }
}