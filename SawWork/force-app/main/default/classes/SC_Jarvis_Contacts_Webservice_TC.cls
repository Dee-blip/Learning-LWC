/*=====================================================================================================+
Class name          :   SC_Jarvis_Contacts_Webservice_TC
Author              :   Jay R
Created             :   08-Sep-21
Purpose             :   This is the Test class for SC_Jarvis_Contacts_Webservice webservice class

Last Modified Developer                 Purpose
============= ========================  =======
08-Sep-21     Jay                       Initial development
+=====================================================================================================*/
@IsTest
public class SC_Jarvis_Contacts_Webservice_TC {

    @TestSetup
    static void testSetup(){

        SC_Case_Issue_Sync_Admin_Setting__c adminRec =  new SC_Case_Issue_Sync_Admin_Setting__c();
        adminRec.Access_Token_Issues_API__c = '';
        adminRec.Client_Certificate__c = 'EAA_KMI_Signed_Certificate';
        adminRec.Client_Id_Issues_API__c = '90f8e0f1-696b-46f9-a504-3811b8ce00fc';
        adminRec.Client_Secret_Issues_API__c = 'b8a4f2c9-24e5-4d5e-a794-6b98730b6915';
        adminRec.Hostname_Issues_API__c = 'https://qa.dash-ext.akamai.com/';
        adminRec.Oauth_Endpoint_Issues_API__c = 'oauth2/token';
        adminRec.Scope_Issues_API__c = 'network-services/issues/v1/issues/';
        insert adminRec;

        User crmOpsUsr = [SELECT Id FROM User WHERE Name='CRM Ops' LIMIT 1];
        SFCommunity_NQLB_Topics__mdt communityMdt = [SELECT PartnerProfileId__c, PartnerCommunityProfileId__c, CustomerProfileId__c,PartnerPermissionSet__c,EmployeePermissionSet__c FROM SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'CommunityNQLB' limit 1];
        
        Account accRec = new Account(Name='Test Account Jarvis',AKAM_Account_ID__c='Test-ABC-123Jarvis',Type='Direct - Active');
        insert accRec;


        Contact conRec = new Contact(AccountId = accRec.Id, Login__c = 'Test_xyz2',Akam_Contact_id__c ='test-222', Email = 'test222@test.com' ,No_Longer_with_Company__c = false, LastName = 'Test Contact2', Contact_Type__c ='Technical Primary - 24x7', Active_Portal_Login__c = True);
        insert conRec;

        User customerUser;
        system.runAs(crmOpsUsr)
        {
            customerUser = SC_Jarvis_Contacts_Webservice.createNewCustomerUser (conRec,SC_Jarvis_Contacts_Webservice.getLoggedInUser() , communityMdt.CustomerProfileId__c);
            customerUser.contactId = conRec.Id;
            insert customerUser;
            Test.setCreatedDate(customerUser.Id,System.now().addDays(-40));
        }
    

        Jarvis_Contact_ACC_Permission__c  permissionRec= new Jarvis_Contact_ACC_Permission__c();
        permissionRec.contact__c = conRec.Id;
        permissionRec.Active__c = true; 
        permissionRec.User__c = customerUser.id;           
        permissionRec.Akam_Contact_ACC_Permission_Id__c = conRec.Akam_Contact_Id__c;            
        //permissionRec.Response__c =  JSON.serialize(wrappers);                      
        insert permissionRec;    




    }

    @IsTest
    static void test_getContacts_OneTimeSync(){

        new SC_Jarvis_Contacts_Webservice();
        
        Jarvis_Contact_ACC_Permission__c permission = [SELECT  User__r.CreatedDate,User__r.LastLoginDate,Id,Contact__r.Account.AKAM_Account_ID__c,Contact__r.Login__c,Active__c,Eligible_for_Pollers__c,Active_Permission_Count__c,User__r.IsActive FROM Jarvis_Contact_ACC_Permission__c];
        System.debug(permission);
        System.debug(permission.Contact__r.Login__c);
        System.debug(permission.User__r.IsActive);
        System.debug(permission.User__r.CreatedDate);
        System.debug(permission.User__r.LastLoginDate);
        Map<String,Object> requestParams = new Map<String, Object>();
        requestParams.put('offset','0');
        requestParams.put('oneTimeSync',false);
        RestRequest request = new RestRequest();
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(JSON.serialize(requestParams));
        RestContext.request = request;
        String getContactsResponse = SC_Jarvis_Contacts_Webservice.getContacts();
        System.debug(getContactsResponse);
    }

    @IsTest
    static void test_getContacts(){
        Contact c = [SELECT Id FROM Contact];
        Map<String,Object> requestParams = new Map<String, Object>();
        requestParams.put('oneTimeSync',true);
        requestParams.put('contacts',c.Id);
        requestParams.put('direct',true);
        RestRequest request = new RestRequest();
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(JSON.serialize(requestParams));
        RestContext.request = request;
        String getContactsResponse = SC_Jarvis_Contacts_Webservice.getContacts();
        System.debug(getContactsResponse);
    }

    @IsTest
    static void test_getContacts1(){

        Contact c = [SELECT Id, email, akam_contact_id__c, Phone, firstname, lastname, title, account.name FROM Contact limit 1];
        User u = [SELECT Username, AKAM_User_Id__c, FederationIdentifier, contactId, Phone, Email, Firstname, Lastname, Title, Companyname, LocaleSidKey, LanguageLocaleKey, TimeZoneSidKey, EmailEncodingKey, profileId FROM User LIMIT 1];
        Map<String,Object> requestParams = new Map<String, Object>();
        requestParams.put('oneTimeSync',true);
        requestParams.put('contacts',c.Id);
        requestParams.put('direct',false);
        RestRequest request = new RestRequest();
        request.httpMethod = 'POST';
        request.requestBody = Blob.valueOf(JSON.serialize(requestParams));
        RestContext.request = request;
        String getContactsResponse = SC_Jarvis_Contacts_Webservice.getContacts();
        System.debug(getContactsResponse);
        SFCommunity_NQLB_Topics__mdt communityMdt = [SELECT PartnerProfileId__c, PartnerCommunityProfileId__c, CustomerProfileId__c,PartnerPermissionSet__c,EmployeePermissionSet__c FROM SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'CommunityNQLB' limit 1];        
        
        // SC_Jarvis_Contacts_Webservice.createNewCustomerUser(c, u,communityMdt.CustomerProfileId__c);
    }


}