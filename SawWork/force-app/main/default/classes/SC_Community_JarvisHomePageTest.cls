@isTest(seeAllData=false)
public class SC_Community_JarvisHomePageTest {

    @testSetup static void testDataSetup(){
        
        utilTestClass.createCustomSettings();
        OrgWideEmailAddress owemail = [SELECT Id, IsAllowAllProfiles FROM OrgWideEmailAddress where IsAllowAllProfiles = true limit 1];
        insert new SC_FromEmailAddress__c(Name = 'auto-reply', OrgAddressId__c = owemail.Id);
        
        User userRun = [SELECT Id FROM User WHERE Alias = 'CRMOPS' limit 1];
        system.runAs(userRun){
            //Account Setup
            Account accRec = new Account(Name='Test Account Jarvis',AKAM_Account_ID__c='Test-ABC-123Jarvis',Type='Brand - Active');
            //Account accRec2 = new Account(Name='Test Account Jarvis 2',AKAM_Account_ID__c='Test-ABC-12Jarvis',Type='Brand - Active');
            insert accRec;
            
            //Contact Setup
            Contact conRec = new Contact(AccountId = accRec.Id, Login__c = 'Test_xyz2',Akam_Contact_id__c ='test-222', Email = 'test222@test.com' ,No_Longer_with_Company__c = false, LastName = 'Test Contact2', Contact_Type__c ='Technical Primary - 24x7', Active_Portal_Login__c = True);
            conRec.Primary_Contact_Method__c = 'Phone';
            insert conRec;
            
            UserRole ur = [Select Id, PortalType, PortalAccountId From UserRole where portaltype = 'CustomerPortal' limit 1];
            
            User newUser = new User(
                // UserRoleId = ur.Id,
                profileId = '00e0f000000cOem', 
                username = 'test@example.com.akamai123', 
                email = 'test@example.com', 
                emailencodingkey = 'UTF-8', 
                localesidkey = 'en_US', 
                languagelocalekey = 'en_US', 
                timezonesidkey = 'America/Los_Angeles', 
                alias='nuser', 
                lastname='lastname', 
                contactId = conRec.id
            );
            insert newUser;   
            
            //AccountContactRelation acrRec = new AccountContactRelation(AccountID = accRec2.Id, ContactId = conRec.Id, IsActive = true);
            //insert acrRec;
            
            Policy_Domain__c pdRec = new Policy_Domain__c(Name = 'Testpd', Account_Name__c = accRec.Id, AKAM_Policy_Domain_ID__c = 'Test_ABC_Jarvis', Policy_Domain_Description__c = 'default Test-Pd-123', Policy_Domain_State__c = 'Active', Product__c = 'defaulttestproduct', Additional_Product__c = 'test add prod');
            insert pdRec;
            
            SC_Case_Issue_Sync_Admin_Setting__c adminRec =  new SC_Case_Issue_Sync_Admin_Setting__c();
            adminRec.Access_Token_Issues_API__c = '';
            adminRec.Client_Certificate__c = 'EAA_KMI_Signed_Certificate';
            adminRec.Client_Id_Issues_API__c = '90f8e0f1-696b-46f9-a504-3811b8ce00fc';
            adminRec.Client_Secret_Issues_API__c = 'b8a4f2c9-24e5-4d5e-a794-6b98730b6915';
            adminRec.Hostname_Issues_API__c = 'https://qa.dash-ext.akamai.com/';
            adminRec.Oauth_Endpoint_Issues_API__c = 'oauth2/token';
            adminRec.Scope_Issues_API__c = 'network-services/issues/v1/issues/';
            insert adminRec;
        }
    }
    
    testmethod static void testMyFilteredCasesinQueue() {
        
        Test.startTest();
        
        List<Id> accountIds = new List<Id>();
        for(Account acc: [select id from account limit 10]) {
            accountIds.add(acc.Id);
        }
        Id caseTechnicalRT = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        Case jarvisCaseRec = new Case(Subject = 'Test', 
                                      accountid = accountIds[0], 
                                      recordtypeid= caseTechnicalRT, 
                                      Description = 'Test', 
                                      Validation_override__c = true, 
                                      Origin = 'Email');
        
        jarvisCaseRec.Do_Not_Show_in_Portal__c = false;
        jarvisCaseRec.Apply_Jarvis_Logic__c = true;
        jarvisCaseRec.Created_By_Account__c = accountIds[0];

        insert jarvisCaseRec;
        
        Test.stopTest();

        List<contact> cts = [select id from contact limit 1];
        List<User> usr = [select id, contactid from user where contactid = :cts[0].Id];
        
        system.runAs(usr[0]){
            SC_Community_JarvisHomePage.DashboardWrapper wrp;
            wrp = SC_Community_JarvisHomePage.getCasesinQueue('myActiveCases', accountIds);
            System.assertEquals(0, wrp.allCasesCount, 'myActiveCases');
            wrp = SC_Community_JarvisHomePage.getCasesinQueue('myClosedCases', accountIds);
            System.assertEquals(0, wrp.allCasesCount, 'myClosedCases');
        }
    }
    
    testmethod static void testAllFilteredCasesinQueue() {
        
        Test.startTest();
        
        List<Id> accountIds = new List<Id>();
        for(Account acc: [select id from account limit 10]) {
            accountIds.add(acc.Id);
        }
        Id caseTechnicalRT = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        Case jarvisCaseRec = new Case(Subject = 'Test', 
                                      accountid = accountIds[0], 
                                      recordtypeid= caseTechnicalRT, 
                                      Description = 'Test', 
                                      Validation_override__c = true, 
                                      Origin = 'Email');
        
        jarvisCaseRec.Do_Not_Show_in_Portal__c = false;
        jarvisCaseRec.Apply_Jarvis_Logic__c = true;
        jarvisCaseRec.Created_By_Account__c = accountIds[0];

        insert jarvisCaseRec;
        
        Test.stopTest();

        List<contact> cts = [select id from contact limit 1];
        List<User> usr = [select id, contactid from user where contactid = :cts[0].Id];
        
        system.runAs(usr[0]){
            SC_Community_JarvisHomePage.DashboardWrapper wrp;
            wrp = SC_Community_JarvisHomePage.getCasesinQueue('allActiveCases', accountIds);
            System.assertEquals(0, wrp.allCasesCount, 'allActiveCases');
            wrp = SC_Community_JarvisHomePage.getCasesinQueue('allClosedCases', accountIds);
            System.assertEquals(0, wrp.allCasesCount, 'allClosedCases');
        }
    }
    
    Class OuterObject
    {
        String accountId;
        List<innerObject> authGrants;
    }
    
    Class innerObject
    {
        String contractId;
        List<String> scopes;	
    }    
    testmethod static void testFetchAllCases() {
        
        Test.startTest();
			PSA_TestUtility testUtil = new PSA_TestUtility();
        	
	        List<contact> cts = [select id from contact limit 1];
    	    List<User> usr = [select id, contactid from user where contactid = :cts[0].Id];

        
        	List<Id> accountIds = new List<Id>();
        	for(Account acc: [select id from account limit 10]) 
            {
            	accountIds.add(acc.Id);
	        }
        	Id caseTechnicalRT = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        	Case jarvisCaseRec = new Case(Subject = 'Test', 
                                      accountid = accountIds[0], 
                                      recordtypeid= caseTechnicalRT, 
                                      Description = 'Test', 
                                      Validation_override__c = true, 
                                      Origin = 'Email');
        
            jarvisCaseRec.Do_Not_Show_in_Portal__c = false;
            jarvisCaseRec.Apply_Jarvis_Logic__c = true;
            jarvisCaseRec.Created_By_Account__c = accountIds[0];
            jarvisCaseRec.community_sharing_set_account_lookup__c = accountIds[0];
            insert jarvisCaseRec;

        	Merge_Contract_Header__c contract = testUtil.newContract(false, accountIds[0], '123','456',null,System.today(), System.today().addDays(50));
        	contract.Original_Contract_Id__c = 'G-2JIHK23';
        	contract.Contract_Type__c = 'Direct Customer';
        	contract.CI_Account_Name__c  = 'Test-ABC-123Jarvis';
			insert contract;

            List<OuterObject> outerObjects = new List<OuterObject>();
            OuterObject object1 = new OuterObject();
            object1.accountId = 'Test-ABC-123Jarvis';
            
            List<innerObject> innerObjects = new List<innerObject>();
            innerObject innerObject = new innerObject();
            innerObject.contractId = 'G-2JIHK23';
            innerObject.scopes = new List<String>();
            innerObject.scopes.add('CASE_MANAGEMENT_READ');
            innerObjects.add(innerObject);
            
            object1.authGrants = innerObjects;
        	outerObjects.add(object1);
        	
        	Jarvis_Contact_ACC_Permission__c permissionRec= new Jarvis_Contact_ACC_Permission__c();
            permissionRec.contact__c = cts[0].Id;
            permissionRec.Active__c = true; 
            permissionRec.User__c = usr[0].id;
        	permissionRec.Response__c = JSON.serialize(outerObjects);
            permissionRec.Akam_Contact_ACC_Permission_Id__c = cts[0].Id;            
                        
            insert permissionRec;    
            

        Test.stopTest();
	

        system.runAs(usr[0])
        {
            List<SC_Community_JarvisHomePage.CaseWrapper> wrp = SC_Community_JarvisHomePage.fetchAllCases(accountIds);
            System.assertEquals(1, wrp.size(), 'fetchAllCases');
        }
    }
    
    testmethod static void testAddCase() {
        
        Test.startTest();
        
        List<Id> accountIds = new List<Id>();
        for(Account acc: [select id from account limit 10]) {
            accountIds.add(acc.Id);
        }
        Id caseTechnicalRT = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        Case jarvisCaseRec = new Case(Subject = 'Test', 
                                      accountid = accountIds[0], 
                                      recordtypeid= caseTechnicalRT, 
                                      Description = 'Test', 
                                      Validation_override__c = true, 
                                      Origin = 'Email');
        
        jarvisCaseRec.Do_Not_Show_in_Portal__c = false;
        jarvisCaseRec.Apply_Jarvis_Logic__c = true;
        jarvisCaseRec.Created_By_Account__c = accountIds[0];

        insert jarvisCaseRec;
        
        List<AccountContactRelation> acrList = [select id, isActive from AccountContactRelation limit 10];
        for(AccountContactRelation ac: acrList) {
            ac.isActive = true;
        }
        update acrList;
        Test.stopTest();

        List<contact> cts = [select id from contact limit 1];
        List<User> usr = [select id, contactid from user where contactid = :cts[0].Id];
        
        system.runAs(usr[0]){
            SC_Community_JarvisHomePage.DashboardWrapper dwrp = new SC_Community_JarvisHomePage.DashboardWrapper();
            Case cs = [select id, Account.Name, Policy_Domain__r.Name,Akam_Case_Id__c, Contact.Name,
                       RecordType.Name,subject,Sub_Type__c,AccountId,Severity__c, status,
                       owner.type, owner.name,description,CreatedDate, Last_Case_Update__c 
                       from Case where id = :jarvisCaseRec.Id];
            dwrp.addCase(cs);
         list<case> csList = SC_Community_JarvisHomePage.getCasedetails(cs.Id);
            System.assertEquals(1, csList.size(), 'get case size');
        }
    }
    
     testmethod static void testMitigateCase() {
         List<Id> accountIds = new List<Id>();
         for(Account acc: [select id from account limit 10]) {
             accountIds.add(acc.Id);
         }
         
         
         Test.startTest();
         Id caseTechnicalRT = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical').getRecordTypeId();
         Case jarvisCaseRec = new Case(Subject = 'Test', 
                                       accountid = accountIds[0], 
                                       recordtypeid= caseTechnicalRT, 
                                       Description = 'Test', 
                                       Validation_override__c = true, 
                                       Origin = 'Email');
         
         jarvisCaseRec.Do_Not_Show_in_Portal__c = false;
         jarvisCaseRec.Apply_Jarvis_Logic__c = true;
         jarvisCaseRec.Created_By_Account__c = accountIds[0];
         insert jarvisCaseRec;
         
         List<AccountContactRelation> acrList = [select id, isActive from AccountContactRelation limit 10];
         for(AccountContactRelation ac: acrList) {
             ac.isActive = true;
         }
         update acrList;
         Test.stopTest();
         
         List<contact> cts = [select id from contact limit 1];
         List<User> usr = [select id, contactid from user where contactid = :cts[0].Id];
         Insert new CaseShare(CaseId = jarvisCaseRec.id, UserOrGroupId = usr[0].Id, CaseAccessLevel = 'Edit');
         system.runAs(usr[0]){
             
             Boolean isMitigated = SC_Community_JarvisHomePage.mitigateCase(jarvisCaseRec.Id);
             System.assertEquals(true, isMitigated, 'isMitigated');

         }
     }
}