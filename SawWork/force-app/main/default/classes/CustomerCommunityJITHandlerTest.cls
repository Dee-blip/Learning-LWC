@isTest
public class CustomerCommunityJITHandlerTest
{
    static testmethod void Test1()
    {
        //Create User
        Profile pr = [select id from profile where name='Support - Tech Support Manager'][0];
        System.runAs(new User(Id = Userinfo.getUserId())){
        //Create Account
        Account A = new Account();
        A.Name='hdue7jAkamai Technologies - Assets';
        //A.isPartner=true;
        insert A;
        Communities_Settings__c cs = new Communities_Settings__c();
        cs.User_Name_Append_Value__c='.akamai';
        cs.Communities_User_Account_Id__c=A.id;
        cs.Name='Community';
        cs.Self_Registration_Community_Profile_Id__c=pr.id;
        insert cs;
        
        //Create Contact
        Contact C = new Contact();
        C.LastName='Last';
        C.AKAM_Contact_Id__c='ABC123';
        C.AccountId=A.id;
        C.email = 'testtestyyr75u@akamai.com';
        C.Active_Portal_Login__c=true;
        C.Validation_Override__c = true;
        insert C;
        }
        User usr = new User(alias = 'user', email='salesoptest@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__usr@akamai.com',profileid = pr.Id);
        usr.AKAM_User_ID__c = 'ABC123';
        insert usr;
        usr.federationIdentifier = usr.AKAM_User_ID__c;
        
        update usr;
        
        Map<String, String> attributes = new Map<String, String>();
        attributes.put('First','First');
        attributes.put('sfemail','sfemail@akamai.com');
        attributes.put('Last','Last');
        attributes.put('Email','sfemail@akamai.com');
        attributes.put('Company','Company');
        attributes.put('username','usernametest@akamai.com');
        attributes.put('User.Phone','Phone');
        attributes.put('User.Title','User.Title');
        attributes.put('User.AboutMe','User.AboutMe');
        attributes.put('User.Street','User.Street');
        attributes.put('User.State','User.State');
        attributes.put('User.City','User.City');
        attributes.put('User.Zip','User.Zip');
        attributes.put('User.Fax','User.Fax');
        //attributes.put('User.LanguageLocaleKey','User.LanguageLocaleKey');
        //attributes.put('User.TimeZoneSidKey','User.TimeZoneSidKey');
        //attributes.put('User.EmailEncodingKey','User.EmailEncodingKey');
        attributes.put('User.Fax','User.Fax');
        attributes.put('User.IsActive','1');
        //attributes.put('User.ForecastEnabled','1');
        
        
        
        //attributes.put('User.LocaleSidKey','User.LocaleSidKey');
        attributes.put('User.State','User.State');
        attributes.put('User.Country','User.Country');
        // attributes.put('User.CallCenter','User.CallCenter');
        //attributes.put('User.Manager','User.Manage');
        attributes.put('User.MobilePhone','User.MobilePhone');
        //attributes.put('User.DelegatedApproverId','User.DelegatedApproverId');
        attributes.put('User.Department','User.Department');
        attributes.put('User.Division','User.Division');
        attributes.put('User.EmployeeNumber','User.EmployeeNumber');
        attributes.put('User.Extension','User.Extension');
        attributes.put('User.CommunityNickname','User.CommunityNickname');
        attributes.put('User.ReceivesAdminInfoEmails','User.ReceivesAdminInfoEmails');
        attributes.put('User.ReceivesInfoEmails','User.ReceivesInfoEmails');
        //attributes.put('federationIdentifier','ABC123');
        attributes.put('UserType','Employee');
        
        SFCommunity_NQLB_Topics__mdt  communityMdt = [SELECT PartnerProfileId__c,CustomerProfileId__c,PartnerPermissionSet__c,EmployeePermissionSet__c,ModeratorPermissionSetId__c FROM SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'CommunityNQLB' limit 1];
        
        SFCommunity_NQLB_Topics__mdt  communityMetaDataVal = [SELECT DefaultAccountIdForNewContact__c,CommunityNetworkId__c,Guest_Profile__c,ExceptionEmailToAddress__c,SendMassUserEmail__c  FROM SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'CommunityNQLB' limit 1];
        Id CommunityID = communityMetaDataVal.CommunityNetworkId__c;
        //Calling Method
        CustomerCommunityJITHandler CJITHandler = new CustomerCommunityJITHandler();
        CJITHandler.createUser(null,CommunityID,null,'ABC123',attributes,'1234');
        CJITHandler.updateUser(usr.id,null,CommunityID,null,'ABC123',attributes,'1234');
        //CJITHandler.handleUser(true,new User(),attributes,'ABC123',true,null,null,'Employee','ABC123',true);
        //CJITHandler.handlecontact(true,A.id,usr,attributes);
    }
    
    static testmethod void Test2()
    {
        //Create User
        Profile pr = [select id from profile where name='Support - Tech Support Manager'][0];
        System.runAs(new User(Id = Userinfo.getUserId())){
        //Create Account
        Account A = new Account();
        A.Name='test12345';
        //A.isPartner=true;
        insert A;
        
        Communities_Settings__c cs = new Communities_Settings__c();
        cs.User_Name_Append_Value__c='.akamai';
        cs.Communities_User_Account_Id__c=A.id;
        cs.Name='Community';
        cs.Self_Registration_Community_Profile_Id__c=pr.id;
        insert cs;
        
        A.IsPartner =true;
        update A;
        
        //Create Contact
        Contact C = new Contact();
        C.LastName='Last';
        C.AKAM_Contact_Id__c='ABC123';
        C.AccountId=A.id;
        C.email = 'testtestee@akamai.com';
        C.Active_Portal_Login__c=true;
        insert C;
        }
        User usr = new User(alias = 'user', email='testtestee@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__usrrr@akamai.com',profileid = pr.Id);
        usr.AKAM_User_ID__c = 'ABC123';
        insert usr;
        usr.federationIdentifier = usr.AKAM_User_ID__c;
        
        update usr;
        
        User usr2 =[Select UserRoleId,Alias,DelegatedApproverId,EmailEncodingKey,LocaleSidKey,LanguageLocaleKey,TimeZoneSidKey from User where id=:usr.id limit 1];
        
        Map<String, String> attributes = new Map<String, String>();
        attributes.put('First','First');
        attributes.put('sfemail','sfemail@akamai.com');
        attributes.put('Last','Last');
        attributes.put('Company','Company');
        attributes.put('Email','usernametest@akamai.com');	
        attributes.put('username','usernametest@akamai.com');
        attributes.put('User.Phone','Phone');
        attributes.put('User.Title','User.Title');
        attributes.put('User.AboutMe','User.AboutMe');
        attributes.put('User.Street','User.Street');
        attributes.put('User.State','User.State');
        attributes.put('User.City','User.City');
        attributes.put('User.Zip','User.Zip');
        attributes.put('User.Fax','User.Fax');
        attributes.put('User.LanguageLocaleKey',usr2.LanguageLocaleKey);
        attributes.put('User.TimeZoneSidKey',usr2.TimeZoneSidKey);
        attributes.put('User.EmailEncodingKey',usr2.EmailEncodingKey);
        attributes.put('User.Fax','User.Fax');
        attributes.put('User.IsActive','1');
        attributes.put('User.ForecastEnabled','0');
        attributes.put('User.UserRoleId',usr2.UserRoleId);
        
        
        
        attributes.put('User.LocaleSidKey',usr2.LocaleSidKey);
        attributes.put('User.State','User.State');
        attributes.put('User.Country','User.Country');
        // attributes.put('User.CallCenter','User.CallCenter');
        //attributes.put('User.Manager','User.Manage');
        attributes.put('User.MobilePhone','User.MobilePhone');
        attributes.put('User.DelegatedApproverId',usr2.DelegatedApproverId);
        attributes.put('User.Department','User.Department');
        attributes.put('User.Division','User.Division');
        attributes.put('User.EmployeeNumber','User.EmployeeNumber');
        attributes.put('User.Extension','User.Extension');
        attributes.put('User.CommunityNickname','User.CommunityNickname');
        attributes.put('User.ReceivesAdminInfoEmails','User.ReceivesAdminInfoEmails');
        attributes.put('User.ReceivesInfoEmails','User.ReceivesInfoEmails');
        attributes.put('User.Alias',usr2.Alias);
        attributes.put('UserType','Partner');
        //attributes.put('federationIdentifier','ABC123');
        
        SFCommunity_NQLB_Topics__mdt  communityMdt = [SELECT PartnerProfileId__c,CustomerProfileId__c,PartnerPermissionSet__c,EmployeePermissionSet__c,ModeratorPermissionSetId__c FROM SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'CommunityNQLB' limit 1];
        
        SFCommunity_NQLB_Topics__mdt  communityMetaDataVal = [SELECT DefaultAccountIdForNewContact__c,CommunityNetworkId__c,Guest_Profile__c,ExceptionEmailToAddress__c,SendMassUserEmail__c  FROM SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'CommunityNQLB' limit 1];
        Id CommunityID = communityMetaDataVal.CommunityNetworkId__c;
        //Calling Method
        CustomerCommunityJITHandler CJITHandler = new CustomerCommunityJITHandler();
        test.startTest();
        CJITHandler.createUser(null,CommunityID,null,'ABC123',attributes,'1234');
        CJITHandler.updateUser(usr.id,null,CommunityID,null,'ABC1234',attributes,'1234');
        test.stopTest();
        //CJITHandler.handleUser(true,usr.id,attributes,'ABC123',true,null,null,'Employee','ABC123',true);
        //CJITHandler.handlecontact(true,A.id,usr,attributes);
    }
    static testmethod void Test3()
    {
        Profile pr = [select id from profile where name='Support - Tech Support Manager'][0];
        System.runAs(new User(Id = Userinfo.getUserId())){
            //Create Account
            Account A = new Account();
            A.Name='test123456';
            //A.isPartner=true;
            insert A;
            Communities_Settings__c cs = new Communities_Settings__c();
            cs.User_Name_Append_Value__c='.akamai';
            cs.Communities_User_Account_Id__c=A.id;
            cs.Name='Community';
            cs.Self_Registration_Community_Profile_Id__c=pr.id;
            insert cs;
            
            //Create Contact
            Contact C = new Contact();
            C.LastName='Last';
            C.AKAM_Contact_Id__c='ABC123';
            C.AccountId=A.id;
            C.email = 'testtesttryiern@akamai.com';
            C.Active_Portal_Login__c=true;
            C.Validation_Override__c = true;
            insert C;
        }

        Map<String, String> attributes = new Map<String, String>();
        attributes.put('First','First');
        attributes.put('sfemail','sfemail@akamai.com');
        attributes.put('Last','Last');
        attributes.put('email','sfemail7yhury3@akamai.com');
        attributes.put('Company','Company');
        attributes.put('username','usernametest@akamai.com');
        attributes.put('User.Phone','Phone');
        attributes.put('User.Title','User.Title');
        attributes.put('User.AboutMe','User.AboutMe');
        attributes.put('User.Street','User.Street');
        attributes.put('User.State','User.State');
        attributes.put('User.City','User.City');
        attributes.put('User.Zip','User.Zip');
        attributes.put('User.Fax','User.Fax');
        attributes.put('User.Fax','User.Fax');
        attributes.put('User.IsActive','1');
        attributes.put('User.State','User.State');
        attributes.put('User.Country','User.Country');
        attributes.put('User.MobilePhone','User.MobilePhone');
        attributes.put('User.Department','User.Department');
        attributes.put('User.Division','User.Division');
        attributes.put('User.EmployeeNumber','User.EmployeeNumber');
        attributes.put('User.Extension','User.Extension');
        attributes.put('User.CommunityNickname','User.CommunityNickname');
        attributes.put('User.ReceivesAdminInfoEmails','User.ReceivesAdminInfoEmails');
        attributes.put('User.ReceivesInfoEmails','User.ReceivesInfoEmails');
        attributes.put('federationIdentifier','ABC123');
        attributes.put('UserType','Partner');
        
        SFCommunity_NQLB_Topics__mdt  communityMdt = [SELECT PartnerProfileId__c,CustomerProfileId__c,PartnerPermissionSet__c,EmployeePermissionSet__c,ModeratorPermissionSetId__c FROM SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'CommunityNQLB' limit 1];
        
        SFCommunity_NQLB_Topics__mdt  communityMetaDataVal = [SELECT DefaultAccountIdForNewContact__c,CommunityNetworkId__c,Guest_Profile__c,ExceptionEmailToAddress__c,SendMassUserEmail__c  FROM SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'CommunityNQLB' limit 1];
        Id CommunityID = communityMetaDataVal.CommunityNetworkId__c;
        //Calling Method
        CustomerCommunityJITHandler CJITHandler = new CustomerCommunityJITHandler();
        CJITHandler.createUser(null,CommunityID,null,'ABC123',attributes,'1234');
    }
    static testMethod void Test4(){
        Profile pr = [select id from profile where name='Support - Tech Support Manager'][0];
        System.runAs(new User(Id = Userinfo.getUserId())){
            //Create Account
            Account A = new Account();
            A.Name='tdgje689nAkamai Technologies - Assets';
            //A.isPartner=true;
            insert A;
            Communities_Settings__c cs = new Communities_Settings__c();
            cs.User_Name_Append_Value__c='.akamai';
            cs.Communities_User_Account_Id__c=A.id;
            cs.Name='Community';
            cs.Self_Registration_Community_Profile_Id__c=pr.id;
            insert cs;
            
            //Create Contact
            Contact C = new Contact();
            C.LastName='Last';
            C.AKAM_Contact_Id__c='ABC123';
            C.AccountId=A.id;
            C.email = 'testtestghdbfdj@akamai.com';
            C.Active_Portal_Login__c=true;
            C.Validation_Override__c = true;
            insert C;
        }

        Map<String, String> attributes = new Map<String, String>();
        attributes.put('First','First');
        attributes.put('sfemail','sfemail@akamai.com');
        attributes.put('Last','Last');
        attributes.put('email','sfemail@akamai.com');
        attributes.put('Company','Company');
        attributes.put('username','usernametest@akamai.com');
        attributes.put('User.Phone','Phone');
        attributes.put('User.Title','User.Title');
        attributes.put('User.AboutMe','User.AboutMe');
        attributes.put('User.Street','User.Street');
        attributes.put('User.State','User.State');
        attributes.put('User.City','User.City');
        attributes.put('User.Zip','User.Zip');
        attributes.put('User.Fax','User.Fax');
        attributes.put('User.Fax','User.Fax');
        attributes.put('User.IsActive','1');
        attributes.put('User.State','User.State');
        attributes.put('User.Country','User.Country');
        attributes.put('User.MobilePhone','User.MobilePhone');
        attributes.put('User.Department','User.Department');
        attributes.put('User.Division','User.Division');
        attributes.put('User.EmployeeNumber','User.EmployeeNumber');
        attributes.put('User.Extension','User.Extension');
        attributes.put('User.CommunityNickname','User.CommunityNickname');
        attributes.put('User.ReceivesAdminInfoEmails','User.ReceivesAdminInfoEmails');
        attributes.put('User.ReceivesInfoEmails','User.ReceivesInfoEmails');
        attributes.put('federationIdentifier','ABC123');
        attributes.put('UserType','Customer');
        
        SFCommunity_NQLB_Topics__mdt  communityMdt = [SELECT PartnerProfileId__c,CustomerProfileId__c,PartnerPermissionSet__c,EmployeePermissionSet__c,ModeratorPermissionSetId__c FROM SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'CommunityNQLB' limit 1];
        
        SFCommunity_NQLB_Topics__mdt  communityMetaDataVal = [SELECT DefaultAccountIdForNewContact__c,CommunityNetworkId__c,Guest_Profile__c,ExceptionEmailToAddress__c,SendMassUserEmail__c  FROM SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'CommunityNQLB' limit 1];
        Id CommunityID = communityMetaDataVal.CommunityNetworkId__c;
        //Calling Method
        CustomerCommunityJITHandler CJITHandler = new CustomerCommunityJITHandler();
        CJITHandler.createUser(null,CommunityID,null,'ABC123',attributes,'1234');
    }

    static testMethod void Test5(){
        Profile pr = [select id from profile where name='Support - Tech Support Manager'][0];
        SFCommunity_NQLB_Topics__mdt  communityMdt = [SELECT PartnerProfileId__c,CustomerProfileId__c,
        PartnerPermissionSet__c,EmployeePermissionSet__c,ModeratorPermissionSetId__c FROM 
        SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'CommunityNQLB' limit 1];
        System.runAs(new User(Id = Userinfo.getUserId())){
            //Create Account
            Account A = new Account();
            A.Name='tdgje689nAkamai Technologies - Assets';
            //A.isPartner=true;
            insert A;
            Communities_Settings__c cs = new Communities_Settings__c();
            cs.User_Name_Append_Value__c='.akamai';
            cs.Communities_User_Account_Id__c=A.id;
            cs.Name='Community';
            cs.Self_Registration_Community_Profile_Id__c=pr.id;
            insert cs;
            
            //Create Contact
            Contact C = new Contact();
            C.LastName='Last';
            C.AKAM_Contact_Id__c='ABC123';
            C.AccountId=A.id;
            C.email = 'testtestghdbfdj@akamai.com';
            C.Active_Portal_Login__c=true;
            C.Validation_Override__c = true;
            insert C;

            User customerUser = SC_Jarvis_CoreSecurityController.createNewCustomerUser (C,SC_Jarvis_CoreSecurityController.getLoggedInUser() , communityMdt.CustomerProfileId__c);
            customerUser.contactId = c.Id;
            customerUser.isActive = false;
            insert customerUser;
            
        }

        Map<String, String> attributes = new Map<String, String>();
        attributes.put('First','First');
        attributes.put('sfemail','sfemail@akamai.com');
        attributes.put('Last','Last');
        attributes.put('email','sfemail@akamai.com');
        attributes.put('Company','Company');
        attributes.put('username','usernametest@akamai.com');
        attributes.put('User.Phone','Phone');
        attributes.put('User.Title','User.Title');
        attributes.put('User.AboutMe','User.AboutMe');
        attributes.put('User.Street','User.Street');
        attributes.put('User.State','User.State');
        attributes.put('User.City','User.City');
        attributes.put('User.Zip','User.Zip');
        attributes.put('User.Fax','User.Fax');
        attributes.put('User.Fax','User.Fax');
        attributes.put('User.IsActive','1');
        attributes.put('User.State','User.State');
        attributes.put('User.Country','User.Country');
        attributes.put('User.MobilePhone','User.MobilePhone');
        attributes.put('User.Department','User.Department');
        attributes.put('User.Division','User.Division');
        attributes.put('User.EmployeeNumber','User.EmployeeNumber');
        attributes.put('User.Extension','User.Extension');
        attributes.put('User.CommunityNickname','User.CommunityNickname');
        attributes.put('User.ReceivesAdminInfoEmails','User.ReceivesAdminInfoEmails');
        attributes.put('User.ReceivesInfoEmails','User.ReceivesInfoEmails');
        attributes.put('federationIdentifier','ABC123');
        attributes.put('UserType','Customer');
        
        
        
        SFCommunity_NQLB_Topics__mdt  communityMetaDataVal = [SELECT DefaultAccountIdForNewContact__c,CommunityNetworkId__c,Guest_Profile__c,ExceptionEmailToAddress__c,SendMassUserEmail__c  FROM SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'CommunityNQLB' limit 1];
        Id CommunityID = communityMetaDataVal.CommunityNetworkId__c;
        //Calling Method
        CustomerCommunityJITHandler CJITHandler = new CustomerCommunityJITHandler();
        try
        {
            CJITHandler.createUser(null,CommunityID,null,'ABC123',attributes,'1234');
        }
        catch(Exception e)
        {

        }
    }    

    static testMethod void Test6(){
        Profile pr = [select id from profile where name='Support - Tech Support Manager'][0];
        SFCommunity_NQLB_Topics__mdt  communityMdt = [SELECT PartnerProfileId__c,CustomerProfileId__c,
        PartnerPermissionSet__c,EmployeePermissionSet__c,ModeratorPermissionSetId__c FROM 
        SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'CommunityNQLB' limit 1];
        User customerUser;
        System.runAs(new User(Id = Userinfo.getUserId())){
            //Create Account
            Account A = new Account();
            A.Name='tdgje689nAkamai Technologies - Assets';
            //A.isPartner=true;
            insert A;
            Communities_Settings__c cs = new Communities_Settings__c();
            cs.User_Name_Append_Value__c='.akamai';
            cs.Communities_User_Account_Id__c=A.id;
            cs.Name='Community';
            cs.Self_Registration_Community_Profile_Id__c=pr.id;
            insert cs;
            
            //Create Contact
            Contact C = new Contact();
            C.LastName='Last';
            C.AKAM_Contact_Id__c='ABC123';
            C.AccountId=A.id;
            C.email = 'testtestghdbfdj@akamai.com';
            C.Active_Portal_Login__c=true;
            C.Validation_Override__c = true;
            insert C;

            customerUser = SC_Jarvis_CoreSecurityController.createNewCustomerUser (C,SC_Jarvis_CoreSecurityController.getLoggedInUser() , communityMdt.CustomerProfileId__c);
            customerUser.contactId = c.Id;
            customerUser.isActive = true;
            insert customerUser;
            
        }

        Map<String, String> attributes = new Map<String, String>();
        attributes.put('First','First');
        attributes.put('sfemail','sfemail@akamai.com');
        attributes.put('Last','Last');
        attributes.put('email','sfemail@akamai.com');
        attributes.put('Company','Company');
        attributes.put('username','usernametest@akamai.com');
        attributes.put('User.Phone','Phone');
        attributes.put('User.Title','User.Title');
        attributes.put('User.AboutMe','User.AboutMe');
        attributes.put('User.Street','User.Street');
        attributes.put('User.State','User.State');
        attributes.put('User.City','User.City');
        attributes.put('User.Zip','User.Zip');
        attributes.put('User.Fax','User.Fax');
        attributes.put('User.Fax','User.Fax');
        attributes.put('User.IsActive','1');
        attributes.put('User.State','User.State');
        attributes.put('User.Country','User.Country');
        attributes.put('User.MobilePhone','User.MobilePhone');
        attributes.put('User.Department','User.Department');
        attributes.put('User.Division','User.Division');
        attributes.put('User.EmployeeNumber','User.EmployeeNumber');
        attributes.put('User.Extension','User.Extension');
        attributes.put('User.CommunityNickname','User.CommunityNickname');
        attributes.put('User.ReceivesAdminInfoEmails','User.ReceivesAdminInfoEmails');
        attributes.put('User.ReceivesInfoEmails','User.ReceivesInfoEmails');
        attributes.put('federationIdentifier','ABC123');
        attributes.put('UserType','Customer');
        
        
        
        SFCommunity_NQLB_Topics__mdt  communityMetaDataVal = [SELECT DefaultAccountIdForNewContact__c,CommunityNetworkId__c,Guest_Profile__c,ExceptionEmailToAddress__c,SendMassUserEmail__c  FROM SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'CommunityNQLB' limit 1];
        Id CommunityID = communityMetaDataVal.CommunityNetworkId__c;
        //Calling Method
        CustomerCommunityJITHandler CJITHandler = new CustomerCommunityJITHandler();
        try
        {
            CJITHandler.updateUser(customerUser.Id,null,CommunityID,null,'ABC123',attributes,'1234');
        }
        catch(Exception e)
        {
            
        }
    }            

    static testMethod void Test7(){
        Profile pr = [select id from profile where name='Support - Tech Support Manager'][0];
        SFCommunity_NQLB_Topics__mdt  communityMdt = [SELECT PartnerProfileId__c,CustomerProfileId__c,
        PartnerPermissionSet__c,EmployeePermissionSet__c,ModeratorPermissionSetId__c,PartnerCommunityProfileId__c FROM 
        SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'CommunityNQLB' limit 1];
        User customerUser;
        System.runAs(new User(Id = Userinfo.getUserId())){
            //Create Account
            Account A = new Account();
            A.Name='tdgje689nAkamai Technologies - Assets';
            //A.isPartner=true;
            insert A;
            Communities_Settings__c cs = new Communities_Settings__c();
            cs.User_Name_Append_Value__c='.akamai';
            cs.Communities_User_Account_Id__c=A.id;
            cs.Name='Community';
            cs.Self_Registration_Community_Profile_Id__c=pr.id;
            insert cs;
            
            //Create Contact
            Contact C = new Contact();
            C.LastName='Last';
            C.AKAM_Contact_Id__c='ABC123';
            C.AccountId=A.id;
            C.email = 'testtestghdbfdj@akamai.com';
            C.Active_Portal_Login__c=true;
            C.Validation_Override__c = true;
            insert C;

            customerUser = SC_Jarvis_CoreSecurityController.createNewCustomerUser (C,SC_Jarvis_CoreSecurityController.getLoggedInUser() , communityMdt.PartnerCommunityProfileId__c);
            customerUser.contactId = c.Id;
            customerUser.isActive = true;
            insert customerUser;
            
        }

        Map<String, String> attributes = new Map<String, String>();
        attributes.put('First','First');
        attributes.put('sfemail','sfemail@akamai.com');
        attributes.put('Last','Last');
        attributes.put('email','sfemail@akamai.com');
        attributes.put('Company','Company');
        attributes.put('username','usernametest@akamai.com');
        attributes.put('User.Phone','Phone');
        attributes.put('User.Title','User.Title');
        attributes.put('User.AboutMe','User.AboutMe');
        attributes.put('User.Street','User.Street');
        attributes.put('User.State','User.State');
        attributes.put('User.City','User.City');
        attributes.put('User.Zip','User.Zip');
        attributes.put('User.Fax','User.Fax');
        attributes.put('User.Fax','User.Fax');
        attributes.put('User.IsActive','1');
        attributes.put('User.State','User.State');
        attributes.put('User.Country','User.Country');
        attributes.put('User.MobilePhone','User.MobilePhone');
        attributes.put('User.Department','User.Department');
        attributes.put('User.Division','User.Division');
        attributes.put('User.EmployeeNumber','User.EmployeeNumber');
        attributes.put('User.Extension','User.Extension');
        attributes.put('User.CommunityNickname','User.CommunityNickname');
        attributes.put('User.ReceivesAdminInfoEmails','User.ReceivesAdminInfoEmails');
        attributes.put('User.ReceivesInfoEmails','User.ReceivesInfoEmails');
        attributes.put('federationIdentifier','ABC123');
        attributes.put('UserType','Customer');
        
        
        
        SFCommunity_NQLB_Topics__mdt  communityMetaDataVal = [SELECT DefaultAccountIdForNewContact__c,CommunityNetworkId__c,Guest_Profile__c,ExceptionEmailToAddress__c,SendMassUserEmail__c  FROM SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'CommunityNQLB' limit 1];
        Id CommunityID = communityMetaDataVal.CommunityNetworkId__c;
        //Calling Method
        CustomerCommunityJITHandler CJITHandler = new CustomerCommunityJITHandler();
        try
        {
            CJITHandler.updateUser(customerUser.Id,null,CommunityID,null,'ABC123',attributes,'1234');
        }
        catch(Exception e)
        {
            
        }
    }                

    static testMethod void Test8(){
        Profile pr = [select id from profile where name='Support - Tech Support Manager'][0];
        SFCommunity_NQLB_Topics__mdt  communityMdt = [SELECT PartnerProfileId__c,CustomerProfileId__c,
        PartnerPermissionSet__c,EmployeePermissionSet__c,ModeratorPermissionSetId__c,GuestProfileId__c FROM 
        SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'CommunityNQLB' limit 1];
        User customerUser;
        System.runAs(new User(Id = Userinfo.getUserId())){
            //Create Account
            Account A = new Account();
            A.Name='tdgje689nAkamai Technologies - Assets';
            //A.isPartner=true;
            insert A;
            Communities_Settings__c cs = new Communities_Settings__c();
            cs.User_Name_Append_Value__c='.akamai';
            cs.Communities_User_Account_Id__c=A.id;
            cs.Name='Community';
            cs.Self_Registration_Community_Profile_Id__c=pr.id;
            insert cs;
            
            //Create Contact
            Contact C = new Contact();
            C.LastName='Last';
            C.AKAM_Contact_Id__c='ABC123';
            C.AccountId=A.id;
            C.email = 'testtestghdbfdj@akamai.com';
            C.Active_Portal_Login__c=true;
            C.Validation_Override__c = true;
            insert C;

            customerUser = SC_Jarvis_CoreSecurityController.createNewCustomerUser (C,SC_Jarvis_CoreSecurityController.getLoggedInUser() , communityMdt.GuestProfileId__c);
            customerUser.contactId = c.Id;
            customerUser.isActive = false;
            insert customerUser;
            
        }

        Map<String, String> attributes = new Map<String, String>();
        attributes.put('First','First');
        attributes.put('sfemail','sfemail@akamai.com');
        attributes.put('Last','Last');
        attributes.put('email','sfemail@akamai.com');
        attributes.put('Company','Company');
        attributes.put('username','usernametest@akamai.com');
        attributes.put('User.Phone','Phone');
        attributes.put('User.Title','User.Title');
        attributes.put('User.AboutMe','User.AboutMe');
        attributes.put('User.Street','User.Street');
        attributes.put('User.State','User.State');
        attributes.put('User.City','User.City');
        attributes.put('User.Zip','User.Zip');
        attributes.put('User.Fax','User.Fax');
        attributes.put('User.Fax','User.Fax');
        attributes.put('User.IsActive','1');
        attributes.put('User.State','User.State');
        attributes.put('User.Country','User.Country');
        attributes.put('User.MobilePhone','User.MobilePhone');
        attributes.put('User.Department','User.Department');
        attributes.put('User.Division','User.Division');
        attributes.put('User.EmployeeNumber','User.EmployeeNumber');
        attributes.put('User.Extension','User.Extension');
        attributes.put('User.CommunityNickname','User.CommunityNickname');
        attributes.put('User.ReceivesAdminInfoEmails','User.ReceivesAdminInfoEmails');
        attributes.put('User.ReceivesInfoEmails','User.ReceivesInfoEmails');
        attributes.put('federationIdentifier','ABC123');
        attributes.put('UserType','Customer');
        
        
        
        SFCommunity_NQLB_Topics__mdt  communityMetaDataVal = [SELECT DefaultAccountIdForNewContact__c,CommunityNetworkId__c,Guest_Profile__c,ExceptionEmailToAddress__c,SendMassUserEmail__c  FROM SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'CommunityNQLB' limit 1];
        Id CommunityID = communityMetaDataVal.CommunityNetworkId__c;
        //Calling Method
        CustomerCommunityJITHandler CJITHandler = new CustomerCommunityJITHandler();
        try
        {
            CJITHandler.updateUser(customerUser.Id,null,CommunityID,null,'ABC123',attributes,'1234');
        }
        catch(Exception e)
        {
            
        }
    }                
    static testMethod void Test9(){
        Profile pr = [select id from profile where name='Support - Tech Support Manager'][0];
        SFCommunity_NQLB_Topics__mdt  communityMdt = [SELECT PartnerProfileId__c,CustomerProfileId__c,
        PartnerPermissionSet__c,EmployeePermissionSet__c,ModeratorPermissionSetId__c,PartnerCommunityProfileId__c FROM 
        SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'CommunityNQLB' limit 1];
        User customerUser;
        System.runAs(new User(Id = Userinfo.getUserId())){
            //Create Account
            Account A = new Account();
            A.Name='tdgje689nAkamai Technologies - Assets';
            //A.isPartner=true;
            insert A;
            Communities_Settings__c cs = new Communities_Settings__c();
            cs.User_Name_Append_Value__c='.akamai';
            cs.Communities_User_Account_Id__c=A.id;
            cs.Name='Community';
            cs.Self_Registration_Community_Profile_Id__c=pr.id;
            insert cs;
            
            //Create Contact
            Contact C = new Contact();
            C.LastName='Last';
            C.AKAM_Contact_Id__c='ABC123';
            C.AccountId=A.id;
            C.email = 'testtestghdbfdj@akamai.com';
            C.Active_Portal_Login__c=true;
            C.Validation_Override__c = true;
            insert C;

            customerUser = SC_Jarvis_CoreSecurityController.createNewCustomerUser (C,SC_Jarvis_CoreSecurityController.getLoggedInUser() , communityMdt.PartnerCommunityProfileId__c);
            customerUser.contactId = c.Id;
            customerUser.isActive = false;
            insert customerUser;
            
        }

        Map<String, String> attributes = new Map<String, String>();
        attributes.put('First','First');
        attributes.put('sfemail','sfemail@akamai.com');
        attributes.put('Last','Last');
        attributes.put('email','sfemail@akamai.com');
        attributes.put('Company','Company');
        attributes.put('username','usernametest@akamai.com');
        attributes.put('User.Phone','Phone');
        attributes.put('User.Title','User.Title');
        attributes.put('User.AboutMe','User.AboutMe');
        attributes.put('User.Street','User.Street');
        attributes.put('User.State','User.State');
        attributes.put('User.City','User.City');
        attributes.put('User.Zip','User.Zip');
        attributes.put('User.Fax','User.Fax');
        attributes.put('User.Fax','User.Fax');
        attributes.put('User.IsActive','1');
        attributes.put('User.State','User.State');
        attributes.put('User.Country','User.Country');
        attributes.put('User.MobilePhone','User.MobilePhone');
        attributes.put('User.Department','User.Department');
        attributes.put('User.Division','User.Division');
        attributes.put('User.EmployeeNumber','User.EmployeeNumber');
        attributes.put('User.Extension','User.Extension');
        attributes.put('User.CommunityNickname','User.CommunityNickname');
        attributes.put('User.ReceivesAdminInfoEmails','User.ReceivesAdminInfoEmails');
        attributes.put('User.ReceivesInfoEmails','User.ReceivesInfoEmails');
        attributes.put('federationIdentifier','ABC123');
        attributes.put('UserType','Customer');
        
        
        
        SFCommunity_NQLB_Topics__mdt  communityMetaDataVal = [SELECT DefaultAccountIdForNewContact__c,CommunityNetworkId__c,Guest_Profile__c,ExceptionEmailToAddress__c,SendMassUserEmail__c  FROM SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'CommunityNQLB' limit 1];
        Id CommunityID = communityMetaDataVal.CommunityNetworkId__c;
        //Calling Method
        CustomerCommunityJITHandler CJITHandler = new CustomerCommunityJITHandler();
        try
        {
            CJITHandler.updateUser(customerUser.Id,null,CommunityID,null,'ABC123',attributes,'1234');
        }
        catch(Exception e)
        {
            
        }
    }                

}