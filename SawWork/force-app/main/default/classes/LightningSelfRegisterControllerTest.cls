@IsTest
public with sharing class LightningSelfRegisterControllerTest 
{
    static testmethod void test1()
    {
        LightningSelfRegisterController LC = new LightningSelfRegisterController();
        
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
        String Country = 'USA';
        String State = 'New York';
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
        LightningSelfRegisterController.isValidPassword('TestPassword','TestConfirmPassword');
        LightningSelfRegisterController.siteAsContainerEnabled(startUrl);
        LightningSelfRegisterController.selfRegister(firstName,lastName,email,companyName,Country,State,linkedIn,password,confirmPasswordCorrect,accountId,regConfirmUrl,extraFields,startUrl,includePassword);
        LightningSelfRegisterController.getHomeNetworkURL();
        LightningSelfRegisterController.getExtraFields('CommunityNickname');
        LightningSelfRegisterController.setExperienceId('1234');
    }
 
    static testmethod void test2()
    {
        LightningSelfRegisterController LC = new LightningSelfRegisterController();
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
        Contact C = new Contact(Email='test878781000User@akamai.com',LastName='Last');
        C.AccountId=acc.id;
        Insert C;
        
        SC_Community_Registration__c SC = new SC_Community_Registration__c();
        SC.Email__c='test878781000User@akamai.com';
        SC.IsApproved__c=true;
        insert SC;
        
        String firstName = 'test';
        String lastName = 'User';
        String email = 'test878781000User@akamai.com';
        String companyName ='abc';
        String Country = 'USA';
        String State = 'New York';
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
        LightningSelfRegisterController.isValidPassword('TestPassword','TestConfirmPassword');
        LightningSelfRegisterController.siteAsContainerEnabled(startUrl);
        LightningSelfRegisterController.selfRegister('',lastName,email,companyName,Country,State,linkedIn,password,confirmPasswordCorrect,accountId,regConfirmUrl,extraFields,startUrl,includePassword);
        LightningSelfRegisterController.selfRegister(firstName,'',email,companyName,Country,State,linkedIn,password,confirmPasswordCorrect,accountId,regConfirmUrl,extraFields,startUrl,includePassword);
        LightningSelfRegisterController.selfRegister(firstName,lastName,'',companyName,Country,State,linkedIn,password,confirmPasswordCorrect,accountId,regConfirmUrl,extraFields,startUrl,includePassword);
        LightningSelfRegisterController.selfRegister(firstName,lastName,email,'',Country,State,linkedIn,password,confirmPasswordCorrect,accountId,regConfirmUrl,extraFields,startUrl,includePassword);
        LightningSelfRegisterController.selfRegister(firstName,lastName,email,companyName,Country,'',linkedIn,password,confirmPasswordCorrect,accountId,regConfirmUrl,extraFields,startUrl,includePassword);
        LightningSelfRegisterController.getHomeNetworkURL();
        LightningSelfRegisterController.getExtraFields('CommunityNickname');
        LightningSelfRegisterController.setExperienceId('1234');
        LightningSelfRegisterController.validatePassword(usr2,'TestPassword','TestConfirmPassword');
    }
 
    static testmethod void test3()
    {
        LightningSelfRegisterController LC = new LightningSelfRegisterController();
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
            usr2 = new User(alias = 'user', email='test8787sa81000User@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner2', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__usr2@akamai.com',profileid = pr.Id);
            usr2.AKAM_User_ID__c = 'ABC1234';
            insert usr2;
        }
        Contact C = new Contact(Email='test8787sa81000User@akamai.com',LastName='Last');
        C.AccountId=acc.id;
        Insert C;
        
        SC_Community_Registration__c SC = new SC_Community_Registration__c();
        SC.Email__c='test8787sa81000User@akamai.com';
        SC.IsApproved__c=false;
        SC.Reject__c=false;
        insert SC;
        
        String firstName = 'test';
        String lastName = 'User';
        String email = 'test8787sa81000User@akamai.com';
        String companyName ='abc';
        String Country = 'USA';
        String State = 'New York';
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
        LightningSelfRegisterController.isValidPassword('TestPassword','TestConfirmPassword');
        LightningSelfRegisterController.siteAsContainerEnabled(startUrl);
        LightningSelfRegisterController.selfRegister('',lastName,email,companyName,Country,State,linkedIn,password,confirmPasswordCorrect,accountId,regConfirmUrl,extraFields,startUrl,includePassword);
        LightningSelfRegisterController.selfRegister(firstName,'',email,companyName,Country,State,linkedIn,password,confirmPasswordCorrect,accountId,regConfirmUrl,extraFields,startUrl,includePassword);
        LightningSelfRegisterController.selfRegister(firstName,lastName,'',companyName,Country,State,linkedIn,password,confirmPasswordCorrect,accountId,regConfirmUrl,extraFields,startUrl,includePassword);
        LightningSelfRegisterController.selfRegister(firstName,lastName,email,'',linkedIn,Country,State,password,confirmPasswordCorrect,accountId,regConfirmUrl,extraFields,startUrl,includePassword);
        LightningSelfRegisterController.selfRegister(firstName,lastName,email,companyName,Country,State,linkedIn,password,confirmPasswordCorrect,accountId,regConfirmUrl,extraFields,startUrl,includePassword);
        LightningSelfRegisterController.selfRegister(firstName,lastName,email,companyName,Country,'',linkedIn,password,confirmPasswordCorrect,accountId,regConfirmUrl,extraFields,startUrl,includePassword);
        LightningSelfRegisterController.getHomeNetworkURL();
        LightningSelfRegisterController.getExtraFields('CommunityNickname');
        LightningSelfRegisterController.setExperienceId('1234');
        LightningSelfRegisterController.validatePassword(usr2,'TestPassword','TestConfirmPassword');
    }
 
    static testmethod void test4()
    {
        LightningSelfRegisterController LC = new LightningSelfRegisterController();
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
            usr2 = new User(alias = 'user', email='test8787pa81000User@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner2', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__usr2@akamai.com',profileid = pr.Id);
            usr2.AKAM_User_ID__c = 'ABC1234';
            insert usr2;
        }
        Contact C = new Contact(Email='test8787pa81000User@akamai.com',LastName='Last');
        C.AccountId=acc.id;
        Insert C;
        
        SC_Community_Registration__c SC = new SC_Community_Registration__c();
        SC.Email__c='test8787pa81000User@akamai.com';
        SC.IsApproved__c=false;
        SC.Reject__c=false;
        insert SC;
        
        String firstName = 'test';
        String lastName = 'User';
        String email = 'test8787pa81000User@akamai.com';
        String invalidemail = 'test8787pa81000User';
        String companyName ='abc';
        String Country = 'USA';
        String State = 'New York';
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
        LightningSelfRegisterController.isValidPassword('TestPassword','TestConfirmPassword');
        LightningSelfRegisterController.siteAsContainerEnabled(startUrl);
        LightningSelfRegisterController.selfRegister('',lastName,email,companyName,Country,State,linkedIn,password,confirmPasswordCorrect,accountId,regConfirmUrl,extraFields,startUrl,includePassword);
        LightningSelfRegisterController.selfRegister(firstName,'',email,companyName,Country,State,linkedIn,password,confirmPasswordCorrect,accountId,regConfirmUrl,extraFields,startUrl,includePassword);
        LightningSelfRegisterController.selfRegister(firstName,lastName,'',companyName,Country,State,linkedIn,password,confirmPasswordCorrect,accountId,regConfirmUrl,extraFields,startUrl,includePassword);
        LightningSelfRegisterController.selfRegister(firstName,lastName,email,'',Country,State,linkedIn,password,confirmPasswordCorrect,accountId,regConfirmUrl,extraFields,startUrl,includePassword);
        LightningSelfRegisterController.selfRegister(firstName,lastName,email,companyName,'',State,linkedIn,password,confirmPasswordCorrect,accountId,regConfirmUrl,extraFields,startUrl,includePassword);
        LightningSelfRegisterController.selfRegister(firstName,lastName,email,companyName,Country,State,linkedIn,password,confirmPasswordCorrect,accountId,regConfirmUrl,extraFields,startUrl,includePassword);
        LightningSelfRegisterController.selfRegister(firstName,lastName,email,companyName,Country,'',linkedIn,password,confirmPasswordCorrect,accountId,regConfirmUrl,extraFields,startUrl,includePassword);
        //LightningSelfRegisterController.selfRegister(firstName,lastName,invalidemail,companyName,'Wanada','',linkedIn,password,confirmPasswordCorrect,accountId,regConfirmUrl,extraFields,startUrl,includePassword);
        
        LightningSelfRegisterController.getHomeNetworkURL();
        LightningSelfRegisterController.getExtraFields('CommunityNickname');
        LightningSelfRegisterController.setExperienceId('1234');
        LightningSelfRegisterController.validatePassword(usr2,'TestPassword','TestConfirmPassword');
    }
   
    static testmethod void test5()
    {
        LightningSelfRegisterController LC = new LightningSelfRegisterController();
        
        String firstName = 'test';
        String lastName = 'User';
        String email = 'test8787pa81000User@akamai.com';
        String invalidemail = 'test8787pa81000User';
        String companyName ='abc';
        String Country = 'duywgj';
        String State = 'oeudfhlj';
        String linkedIn ='Cde';
        String password = 'testuser123';
        String confirmPasswordCorrect = 'testuser123';
        String confirmPasswordWrong = 'wrongpassword';
        String accountId = 'testuser123';
        String regConfirmUrl = 'http://registration-confirm.com';
        String extraFields ='Testabc';
        String startUrl = 'http://my.company.salesforce.com';
        Boolean includePassword =true;
        User enggUser = [select id from user where profile.name = 'Salesforce Engineering' and isActive = true limit 1];
        
        //Methods
        /*LightningSelfRegisterController.isValidPassword('TestPassword','TestConfirmPassword');
        LightningSelfRegisterController.siteAsContainerEnabled(startUrl);
        LightningSelfRegisterController.selfRegister('',lastName,email,companyName,Country,State,linkedIn,password,confirmPasswordCorrect,accountId,regConfirmUrl,extraFields,startUrl,includePassword);
        LightningSelfRegisterController.selfRegister(firstName,'',email,companyName,Country,State,linkedIn,password,confirmPasswordCorrect,accountId,regConfirmUrl,extraFields,startUrl,includePassword);
        LightningSelfRegisterController.selfRegister(firstName,lastName,'',companyName,Country,State,linkedIn,password,confirmPasswordCorrect,accountId,regConfirmUrl,extraFields,startUrl,includePassword);
        LightningSelfRegisterController.selfRegister(firstName,lastName,email,'',Country,State,linkedIn,password,confirmPasswordCorrect,accountId,regConfirmUrl,extraFields,startUrl,includePassword);
        LightningSelfRegisterController.selfRegister(firstName,lastName,email,companyName,'',State,linkedIn,password,confirmPasswordCorrect,accountId,regConfirmUrl,extraFields,startUrl,includePassword);
        LightningSelfRegisterController.selfRegister(firstName,lastName,email,companyName,Country,State,linkedIn,password,confirmPasswordCorrect,accountId,regConfirmUrl,extraFields,startUrl,includePassword);
        LightningSelfRegisterController.selfRegister(firstName,lastName,email,companyName,Country,'',linkedIn,password,confirmPasswordCorrect,accountId,regConfirmUrl,extraFields,startUrl,includePassword);*/
        system.runAs(enggUser){
            LightningSelfRegisterController.selfRegister(firstName,lastName,email,companyName,Country,State,linkedIn,password,confirmPasswordCorrect,accountId,regConfirmUrl,extraFields,startUrl,includePassword);
            LightningSelfRegisterController.selfRegister(firstName,lastName,email,companyName,'India','XYZ',linkedIn,password,confirmPasswordCorrect,accountId,regConfirmUrl,extraFields,startUrl,includePassword);
            LightningSelfRegisterController.selfRegister(firstName,lastName,'tetetete',companyName,'India','Delhi',linkedIn,password,confirmPasswordCorrect,accountId,regConfirmUrl,extraFields,startUrl,includePassword);
        }
                /*LightningSelfRegisterController.getHomeNetworkURL();
        LightningSelfRegisterController.getExtraFields('CommunityNickname');
        LightningSelfRegisterController.setExperienceId('1234');
        LightningSelfRegisterController.validatePassword(usr2,'TestPassword','TestConfirmPassword');*/
    }
}