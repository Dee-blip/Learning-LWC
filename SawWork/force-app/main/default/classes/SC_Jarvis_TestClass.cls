/*=====================================================================================================+
Class name        	:   SC_Jarvis_TestClass
Author              :   Vamsee Surya
Created             :   01-Sep-2021
Purpose             :   Test class for 
						SC_Jarvis_Case_Widget_Controller
						SC_Jarvis_AttachmentRL_Ctrl
						SC_Jarvis_Attachment_Detail_Ctrl
						SC_Jarvis_Contact_ACC_Permission_Handler.
						SC_Jarvis_CaseUpdate_Batch
						SC_Jarvis_AccountContactRelation_Batch
						SC_JarvisDatafixJob
						SC_Jarvis_Contact_ACC_Permission_Trigger
						SC_Jarvis_Contact_ACC_Permission_Handler
						

Last Modified 	Developer   	Purpose             
============= 	==========  	=======
01-Aug-21     	Vamsee Surya  	Initial Development(Jira Ticket# ESESP-4356) 
+=====================================================================================================*/
@isTest(SeeAllData = false)
public class SC_Jarvis_TestClass {

    Public Static Account accRec;
    Static Account accRec2;
    Static Account accRec3;
    Static Contact conRec;
    Static Contact conRec2;
    Static Contact conRec3;
    Static task taskRec;
    Static Policy_Domain__c pdRec;
    Static Authorized_Contact__c  acRec;
    
    
    static void testDataSetup(){
		SC_Case_Issue_Sync_Admin_Setting__c adminRec =  new SC_Case_Issue_Sync_Admin_Setting__c();
        adminRec.Access_Token_Issues_API__c = '';
        adminRec.Client_Certificate__c = 'EAA_KMI_Signed_Certificate';
        adminRec.Client_Id_Issues_API__c = '90f8e0f1-696b-46f9-a504-3811b8ce00fc';
        adminRec.Client_Secret_Issues_API__c = 'b8a4f2c9-24e5-4d5e-a794-6b98730b6915';
        adminRec.Hostname_Issues_API__c = 'https://qa.dash-ext.akamai.com/';
        adminRec.Oauth_Endpoint_Issues_API__c = 'oauth2/token';
        adminRec.Scope_Issues_API__c = 'network-services/issues/v1/issues/';
        insert adminRec;        
        utilTestClass.createCustomSettings();
       	User userRun = [SELECT Id FROM User WHERE Alias = 'CRMOPS' limit 1];
       system.runAs(userRun){
           
           //Account Setup
           List<Account> accountList = new List<Account>();
            accountList.add(new Account(Name='Test Account Jarvis',AKAM_Account_ID__c='Test-ABC-123Jarvis',Type='Brand - Active'));
            accountList.add(new Account(Name='Test Account Jarvis 2',AKAM_Account_ID__c='Test-ABC-12Jarvis',Type='Brand - Active'));
            accountList.add(new Account(Name='Akamai Account',AKAM_Account_ID__c='Test-ABC-AKAM',Type='Brand - Active'));
            Insert accountList;
               
            accRec = accountList[0];
            accRec2 = accountList[1];
            accRec3 = accountList[2];

            //Contact Setup
            List<Contact> contactList = new List<Contact>();
            contactList.add(new Contact(AccountId = accRec.Id, Login__c = 'Test_xyz2',Akam_Contact_id__c ='test-222', Email = 'test222@test.com' ,No_Longer_with_Company__c = false, LastName = 'Test Contact2', Contact_Type__c ='Technical Primary - 24x7', Active_Portal_Login__c = True, Primary_Contact_Method__c = 'Phone', Validation_Override__c = True));
            contactList.add(new Contact(AccountId = accRec2.Id, Login__c = 'Test_xyz23',Akam_Contact_id__c ='test-2223', Email = 'test2223@test.com' ,No_Longer_with_Company__c = false, LastName = 'Test Contact2', Contact_Type__c ='Technical Primary - 24x7', Active_Portal_Login__c = True, Primary_Contact_Method__c = 'Phone', Validation_Override__c = True));
            contactList.add(new Contact(AccountId = accRec3.Id, Login__c = 'Test_xyz24',Akam_Contact_id__c ='test-2224', Email = 'test2224@test.com' ,No_Longer_with_Company__c = false, LastName = 'Test Contact2', Contact_Type__c ='Technical Primary - 24x7', Active_Portal_Login__c = True, Primary_Contact_Method__c = 'Phone', Validation_Override__c = True));

            insert contactList;
            conRec = contactList[0];
            conRec2 = contactList[1];
            conRec3 = contactList[2];


            AccountContactRelation acrRec = new AccountContactRelation(AccountID = accRec2.Id, ContactId = conRec.Id, IsActive = true);
            insert acrRec;
           
       }
        
    }
    
    public static testmethod void TestACRBatchClass(){
        Test.startTest(); 
        	testDataSetup();
        	Id scrubIPBatchId = Database.executeBatch(new SC_Jarvis_AccountContactRelation_Batch(new list<string>{'ABC'}));
        Test.stopTest();
    }
    
    public static testmethod void TestJarvisCaseUpdate(){
        testDataSetup();
        Test.startTest(); 
            Id caseTechnicalRT = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical').getRecordTypeId();
            List<case> caselist = new List<case>();
            Case caseRec= new Case(contactid = conRec.id, Subject = 'Test', accountid = accRec.Id, recordtypeid= caseTechnicalRT, Description = 'Test', Validation_override__c = true, Origin = 'Email', Do_not_show_in_portal__c = False);
            caselist.add(caseRec);
            Case caseRec2= new Case(Subject = 'Test2', accountid = accRec.Id, recordtypeid= caseTechnicalRT, Description = 'Test', Validation_override__c = true, Origin = 'Email', Do_not_show_in_portal__c = False);
            caselist.add(caseRec2);
            insert caselist;
        
        	taskRec = new Task(Task_Validation_Override__c = true, Subject = 'Test', Description = 'test', Type__c = 'Web Update', whatId = caseRec.Id);
        	insert taskRec;
           
        	
        	Database.executeBatch(new SC_Jarvis_CaseUpdate_Batch2('Direct Customers',null));
        
        Test.stopTest();
        
    }
    
    public static testmethod void TestJarvisCaseUpdate6(){
        testDataSetup();
        Test.startTest(); 
            Id caseTechnicalRT = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical').getRecordTypeId();
            List<case> caselist = new List<case>();
            Case caseRec= new Case(contactid = conRec.id, Subject = 'Test', accountid = accRec.Id, recordtypeid= caseTechnicalRT, Description = 'Test', Validation_override__c = true, Origin = 'Email', Do_not_show_in_portal__c = False);
            caselist.add(caseRec);
            Case caseRec2= new Case(Subject = 'Test2', accountid = accRec.Id, recordtypeid= caseTechnicalRT, Description = 'Test', Validation_override__c = true, Origin = 'Email', Do_not_show_in_portal__c = False, Indirect_Customer__c = accRec2.Id);
            caselist.add(caseRec2);
            insert caselist;
        
        	SC_Jarvis_CaseUpdate_Batch.convertToEighteen(caseTechnicalRT);
        	
        	Database.executeBatch(new SC_Jarvis_CaseUpdate_Batch('Limited Beta',null, false));
        
        Test.stopTest();
        
    }
    
    
    public static testmethod void TestJarvisCaseUpdate4(){
        testDataSetup();
        Test.startTest(); 
            Id caseTechnicalRT = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical').getRecordTypeId();
            List<case> caselist = new List<case>();
            Case caseRec= new Case(contactid = conRec.id, Subject = 'Test', accountid = accRec.Id, recordtypeid= caseTechnicalRT, Description = 'Test', Validation_override__c = true, Origin = 'Email', Do_not_show_in_portal__c = False, Community_Sharing_Set_Account_Lookup__c = accRec.Id );
            caselist.add(caseRec);
            Case caseRec3= new Case(contactid = conRec.id, Subject = 'Test2', accountid = accRec.Id, recordtypeid= caseTechnicalRT, Description = 'Test', Validation_override__c = true, Origin = 'Email', Do_not_show_in_portal__c = False , Community_Sharing_Set_Account_Lookup__c = accRec.Id, Indirect_Customer__c = accRec2.Id);
            caselist.add(caseRec3);
            insert caselist;
         Test.stopTest();
        
        	taskRec = new Task(Task_Validation_Override__c = true, Subject = 'Test', Description = 'test', Type__c = 'Web Update', whatId = caseRec.Id);
        	insert taskRec;
        	
        	Database.executeBatch(new SC_Jarvis_CaseUpdate_Batch2('Others',null));
       
        
    }
    
    
    public static testmethod void TestJarvisCaseUpdate2(){
        testDataSetup();
        
        
        	pdRec = new Policy_Domain__c(Name = 'Testpd', Account_Name__c = accRec.Id, AKAM_Policy_Domain_ID__c = 'Test_ABC_Jarvis', Policy_Domain_Description__c = 'default Test-Pd-123', Policy_Domain_State__c = 'Active', Product__c = 'defaulttestproduct', Additional_Product__c = 'test add prod');
        	insert pdRec;
        	 
        
        	Id caseTechnicalRT = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Managed Security').getRecordTypeId();
            
        Test.startTest(); 
        	List<case> caselist = new List<case>();
            Case caseRec= new Case(contactid = conRec.id, Subject = 'Test', Policy_Domain__c = pdRec.Id, accountid = accRec.Id, recordtypeid= caseTechnicalRT, Description = 'Test', Validation_override__c = true, Origin = 'Email', Do_not_show_in_portal__c = False, Community_Sharing_Set_Account_Lookup__c = accRec.Id );
            caselist.add(caseRec);
        	insert caseList;
        	
        	
        	taskRec = new Task(Task_Validation_Override__c = true, Subject = 'Test', Description = 'test', Type__c = 'Web Update', whatId = caseRec.Id);
        	insert taskRec;
			SC_Jarvis_CaseUpdate_Batch2.convertToEighteen(String.valueOf(taskRec.Id));
        	
        	Database.executeBatch(new SC_Jarvis_CaseUpdate_Batch2('Managed Security','\'Test-ABC-123Jarvis\''));
        
        Test.stopTest();
        
    }
    
    
    public static testmethod void TestJarvisCaseUpdate3(){
        Test.startTest(); 
        	SC_Jarvis_CaseUpdate_Batch2 sc = new SC_Jarvis_CaseUpdate_Batch2('Managed Security',null);
        	sc.sendEmailforException('Error');
        	
        Test.stopTest();
    }
    
    public static testmethod void TestJarvisDatafix(){
         testDataSetup();
         Test.startTest();
        	//ID conID = [Select Id from Contact LIMIT 1].Id;
        	pdRec = new Policy_Domain__c(Name = 'Testpd', Account_Name__c = accRec.Id, AKAM_Policy_Domain_ID__c = 'Test_ABC_Jarvis', Policy_Domain_Description__c = 'default Test-Pd-123', Policy_Domain_State__c = 'Active', Product__c = 'defaulttestproduct', Additional_Product__c = 'test add prod');
        	insert pdRec;
        	
        	acRec = new Authorized_Contact__c (Emergency_Email__c = true, Product_Interests__c = 'All');

       		acRec.Policy_Domain__c = pdRec.Id;
            acRec.Contact_Name__c = conRec.Id;
        	insert acRec;
           
        	Database.executeBatch(new SC_JarvisDatafixJob(null));
         Test.stopTest();
        
    }
    
    public static testmethod void TestACCPermissionObject(){
        testDataSetup();
        
        Test.startTest(); 
        	pdRec = new Policy_Domain__c(Name = 'Testpd', Account_Name__c = accRec.Id, AKAM_Policy_Domain_ID__c = 'Test_ABC_Jarvis', Policy_Domain_Description__c = 'default Test-Pd-123', Policy_Domain_State__c = 'Active', Product__c = 'defaulttestproduct', Additional_Product__c = 'test add prod');
        	insert pdRec;
        	
        	//ID conID = [Select Id from Contact LIMIT 1].Id;
        	acRec = new Authorized_Contact__c (Emergency_Email__c = true, Product_Interests__c = 'All');

       		acRec.Policy_Domain__c = pdRec.Id;
            acRec.Contact_Name__c = conRec.id;
        	insert acRec;
            Jarvis_Contact_ACC_Permission__c jcRec = new Jarvis_Contact_ACC_Permission__c();
            jcRec.Contact__c = conRec.id;
            jcRec.Active__c = True;
       		jcRec.Force_Sync__c = True;
        	jcRec.Response__c =  '[  {    \"accountId\": \"Test-ABC-123Jarvis\",    \"authGrants\": [      {        \"contractId\": \"G-39NFM0P\",        \"scopes\": [          \"CASE_MANAGEMENT_WRITE\",          \"CASE_MANAGEMENT_READ\",          \"CASE_MANAGEMENT_UPDATE\"        ]      }    ]  }]';
            jcRec.Akam_Contact_ACC_Permission_Id__c = 'TestJC-123';
            Insert jcRec;
        
        	jcRec.Force_Sync__c = True;
        	Update jcRec;
        
        	jcRec.Response__c =  '[  {    \"accountId\": \"Test-ABC-123Jarvis\",    \"authGrants\": [      {        \"contractId\": \"G-39NFM0P\",        \"scopes\": [                   \"CASE_MANAGEMENT_READ\",          \"CASE_MANAGEMENT_UPDATE\"        ]      }    ]  }]';
            Update jcRec;

			jcRec.Active__c = False;
        	Update jcRec;
       		        
        	List<SC_Jarvis_Contact_ACC_Permission_Handler.AccountContactPermissionWrapper> responseWrappers = new List<SC_Jarvis_Contact_ACC_Permission_Handler.AccountContactPermissionWrapper>();
        	SC_Jarvis_Contact_ACC_Permission_Handler.AccountContactPermissionWrapper accountContactWrapper = new SC_Jarvis_Contact_ACC_Permission_Handler.AccountContactPermissionWrapper();
        	accountContactWrapper.contactId = jcRec.Akam_Contact_Id__c;
            accountContactWrapper.parentId = jcRec.Id;
            accountContactWrapper.contactSalesforceId = jcRec.Contact__c;
           	responseWrappers.add(accountContactWrapper);
        	Set<String> contactIds = new Set<String>();
        	contactIds.add(jcRec.Contact__c);
        	//SC_Jarvis_Contact_ACC_Permission_Handler.createPermissionRecords(responseWrappers, contactIds);
        
			Delete jcRec;        
        
        Test.stopTest();
        
        
    }

    
    public static testmethod void testCaseWidget(){
        testDataSetup();
        Test.startTest(); 
        	List<case> caselist = new List<case>();
        	Id caseTechnicalRT = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Managed Security').getRecordTypeId();
            
            Case caseRec= new Case(contactid = conRec.id, Subject = 'Test', accountid = accRec.Id, recordtypeid= caseTechnicalRT, Description = 'Test', Validation_override__c = true, Origin = 'Email', Do_not_show_in_portal__c = False, Community_Sharing_Set_Account_Lookup__c = accRec.Id );
            caselist.add(caseRec);
            Case caseRec2= new Case(contactid = conRec.id, Subject = 'Test2', accountid = accRec.Id, recordtypeid= caseTechnicalRT, Description = 'Test', Validation_override__c = true, Origin = 'Email', Do_not_show_in_portal__c = False , Community_Sharing_Set_Account_Lookup__c = accRec.Id);
            caselist.add(caseRec2);
            insert caselist;
        
        	User userRun = [SELECT Id FROM User WHERE Alias = 'CRMOPS' limit 1];
        	SFCommunity_NQLB_Topics__mdt communityMdt = [SELECT PartnerProfileId__c, PartnerCommunityProfileId__c, CustomerProfileId__c,PartnerPermissionSet__c,EmployeePermissionSet__c FROM SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'CommunityNQLB' limit 1];
        	User communityUser;
        	Id caseId = caselist[0].Id;
       		system.runAs(userRun){
            	//Contact c = [SELECT Id, email, akam_contact_id__c, Phone, firstname, lastname, title, account.name FROM Contact limit 1];
        		list<AccountContactRelation> ACRtoUpdate = new list<AccountContactRelation>();
                for(AccountContactRelation eacdACR : [SELECT ID, Isactive FROM AccountContactRelation WHERE ContactId = :conRec.id and Isactive =  False]){
                    eacdACR.Isactive = True;
                    ACRtoUpdate.add(eacdACR);
                }
            	Update ACRtoUpdate;
        		User tempUser = [SELECT Username, AKAM_User_Id__c, FederationIdentifier, contactId, Phone, Email, Firstname, Lastname, Title, Companyname, LocaleSidKey, LanguageLocaleKey, TimeZoneSidKey, EmailEncodingKey, profileId FROM User WHERE Id=:UserInfo.getUserId() LIMIT 1];
                tempUser.Alias = 'a'+ math.random();
                communityUser = SC_Jarvis_CoreSecurityController.createNewCustomerUser(conRec,tempUser,communityMdt.CustomerProfileId__c);
                communityUser.Username = communityUser.Username + math.random();
                communityUser.FederationIdentifier = communityUser.FederationIdentifier + math.random();
                communityUser.AKAM_User_ID__c = 'JvTest123';
                insert communityUser;

                PSA_TestUtility testUtil = new PSA_TestUtility();

                Merge_contract_Header__c contract = testUtil.newContract(false, accRec.Id, '123','456',null,System.today(), System.today().addDays(50));
                contract.Original_Contract_Id__c = '123';
                insert contract;

                Jarvis_Contact_ACC_Permission__c permissionRec= new Jarvis_Contact_ACC_Permission__c();
                permissionRec.contact__c = conRec.Id;
                permissionRec.Active__c = true; 
                permissionRec.User__c = communityUser.id;           
                permissionRec.Akam_Contact_ACC_Permission_Id__c = conRec.Akam_Contact_Id__c;   
                permissionRec.Response__c='[                 ]';         
                insert permissionRec;  

                Jarvis_Contact_ACC_Permission_Contract__c contractRec = new Jarvis_Contact_ACC_Permission_Contract__c();
                contractRec.Active__c = true;
                contractRec.Customer_Permission__c = permissionRec.Id;
                contractRec.Account__c = accRec.Id;
                contractRec.contract__c = contract.Id;
                contractRec.Permission__c = 'CASE_MANAGEMENT_WRITE;CASE_MANAGEMENT_PS_ACCESS';
                contractRec.Akam_Contact_ACC_Permission_Contract_ID__c = conRec.Id;
                contractRec.Case_Management__c = 'CREATE';
                insert contractRec;  
                
                
                List<CaseShare> caseShares = new List<CaseShare>();
                caseShares.add(new CaseShare( CaseId = caselist[0].Id, CaseAccessLevel = 'Edit', UserOrGroupId = communityUser.id));
                caseShares.add(new CaseShare( CaseId = caselist[1].Id, CaseAccessLevel = 'Edit', UserOrGroupId = communityUser.id));
                insert caseShares;
                
                ContentVersion conVer = L2Q_ContentDocumentUtilClass.setContentVersion('S', 'Name.txt', 'Name', 'Test Data');
                insert conVer;

                ContentVersion conVerdata = [Select Id, ContentDocumentId From ContentVersion Where Id = :conVer.Id];

                ContentDocumentLink conDocLink = L2Q_ContentDocumentUtilClass.setContentDocumentLink(conVerdata.ContentDocumentId, caseId, 'V', 'AllUsers');
                insert conDocLink;
                
                ContentDocument conDocument = [SELECT Id FROM ContentDocument WHERE Id =:conVerdata.ContentDocumentId];
            
            	SC_Jarvis_Attachment_Detail_Ctrl adc = new SC_Jarvis_Attachment_Detail_Ctrl();
            	SC_Jarvis_Attachment_Detail_Ctrl.getAttachmentDetail(conDocument.Id);
            
        	}
        
        system.runAs(communityUser){
            SC_Jarvis_Case_Widget_Controller cs = new SC_Jarvis_Case_Widget_Controller();
        	SC_Jarvis_Case_Widget_Controller.getCaseCountData();
            SC_Jarvis_AttachmentRL_Ctrl js = new SC_Jarvis_AttachmentRL_Ctrl();
            SC_Jarvis_AttachmentRL_Ctrl.getAttachmentRelatedListWrapper(caseId);
		}
        Test.stopTest();
    }


    public static testmethod void testCoreSecurity(){
       User userRun = [SELECT Id FROM User WHERE Alias = 'CRMOPS' limit 1];
       system.runAs(userRun){
       		utilTestClass.createCustomSettings();
       }
            List<Account> accountList = new List<Account>();
            	accountList.add(new Account(Name='Akamai Technologies - Assets',AKAM_Account_ID__c='Test-ABC-123Jarvis',Type='Brand - Active'));
            Insert accountList;
        accRec = accountList[0];
       
        conRec = new Contact(AccountId = accRec.Id, Login__c = 'Test_xyz2',Akam_Contact_id__c ='test-222', Email = 'test222@akamai.com' ,No_Longer_with_Company__c = false, LastName = 'Test Contact2', Contact_Type__c ='Technical Primary - 24x7', Active_Portal_Login__c = True, Primary_Contact_Method__c = 'Phone', Validation_Override__c = True);
        insert conRec;
        system.runAs(userRun){
            User usr = utilTestClass.CreateUserWithProfileId('test222','Worldwide', '00eG0000000f0ZNIAY');
            usr.Akam_User_Id__c = conRec.AKAM_Contact_ID__c;
            usr.isActive = False;
        	Insert usr;
        }
        SC_Jarvis_CoreSecurityController.checkForUser(new List<String>{String.valueOf(conRec.Id)});
    }
    
    public static testmethod void testCoreSecurity2(){
        
    	
        testDataSetup();
        Test.startTest(); 
        		SFCommunity_NQLB_Topics__mdt communityMdt = [SELECT PartnerProfileId__c, PartnerCommunityProfileId__c, CustomerProfileId__c,PartnerPermissionSet__c,EmployeePermissionSet__c FROM SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'CommunityNQLB' limit 1];
        		User tempUser = [SELECT Username, AKAM_User_Id__c, FederationIdentifier, contactId, Phone, Email, Firstname, Lastname, Title, Companyname, LocaleSidKey, LanguageLocaleKey, TimeZoneSidKey, EmailEncodingKey, profileId FROM User WHERE Id=:UserInfo.getUserId() LIMIT 1];
                tempUser.Alias = 'a'+System.currentTimeMillis();
                User communityUser = SC_Jarvis_CoreSecurityController.createNewCustomerUser(conRec,tempUser,communityMdt.CustomerProfileId__c);
                insert communityUser;
                
                SC_Jarvis_CoreSecurityController.checkForUser(new List<String>{String.valueOf(conRec.Id)});
        Test.stopTest();
                
        

    }
    
    public static testmethod void testCoreSecurity3(){
        SC_Jarvis_CoreSecurityController.checkForUser(null);
       User userRun = [SELECT Id FROM User WHERE Alias = 'CRMOPS' limit 1];
       system.runAs(userRun){
       		utilTestClass.createCustomSettings();
       }
            List<Account> accountList = new List<Account>();
            	accountList.add(new Account(Name='Akamai Technologies - Assets',AKAM_Account_ID__c='Test-ABC-123Jarvis',Type='Brand - Active'));
            Insert accountList;
        accRec = accountList[0];
       
        conRec = new Contact(AccountId = accRec.Id, Login__c = 'Test_xyz2',Akam_Contact_id__c ='test-222', Email = 'test222@akamai.com' ,No_Longer_with_Company__c = false, LastName = 'Test Contact2', Contact_Type__c ='Technical Primary - 24x7', Active_Portal_Login__c = True, Primary_Contact_Method__c = 'Phone', Validation_Override__c = True);
        insert conRec;
        system.runAs(userRun){
            User usr = utilTestClass.CreateUserWithProfileId('test333','Worldwide', '00eG0000000eSjyIAE');
            usr.Akam_User_Id__c = conRec.AKAM_Contact_ID__c;
            usr.isActive = False;
            Insert usr;
        }
        SC_Jarvis_CoreSecurityController.checkForUser(new List<String>{String.valueOf(conRec.Id)});
    }

    @IsTest
    public static void test_populateAccountFields(){

        testDataSetup();
        Test.startTest();
        Id caseTechnicalRT = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        List<case> caselist = new List<case>();
        Case caseRec= new Case(contactid = conRec3.id, Subject = 'Test', accountid = accRec3.Id, recordtypeid= caseTechnicalRT, Description = 'Test', Validation_override__c = true, Origin = 'Email', Do_not_show_in_portal__c = False, Community_Sharing_Set_Account_Lookup__c = accRec3.Id );
        caselist.add(caseRec);
        Case caseRec3= new Case(contactid = conRec3.id, Subject = 'Test2', accountid = accRec3.Id, recordtypeid= caseTechnicalRT, Description = 'Test', Validation_override__c = true, Origin = 'Email', Do_not_show_in_portal__c = False , Community_Sharing_Set_Account_Lookup__c = accRec3.Id, Indirect_Customer__c = accRec.Id);
        caselist.add(caseRec3);
        insert caselist;
        Test.stopTest();
        Set<Id> caseIds = new Set<Id>();
        for(Case c: caselist){
            caseIds.add(c.Id);
        }

        List<Case> cases = [SELECT Id, AccountId, Community_Sharing_Set_Account_Lookup__c, Created_By_Account__c, Indirect_Customer__c, Policy_Domain__c, Account.AKAM_Account_Id__c, RecordType.Name, IsClosed, ContactId, Contact.AccountID, Contact.Account.AKAM_Account_Id__c, Indirect_Customer__r.AKAM_Account_Id__c,Contact.Account.Name FROM Case WHERE Id IN :caseIds];

        SC_Jarvis_CaseUpdate_Batch2.populateAccountFields(cases);

    }

    @IsTest
    public static void test_populateAccountFields1(){

        testDataSetup();
        Test.startTest();
        Id caseTechnicalRT = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        List<case> caselist = new List<case>();
        Case caseRec= new Case(contactid = conRec.id, Subject = 'Test', accountid = accRec.Id, recordtypeid= caseTechnicalRT, Description = 'Test', Validation_override__c = true, Origin = 'Email', Do_not_show_in_portal__c = False, Community_Sharing_Set_Account_Lookup__c = accRec.Id );
        caselist.add(caseRec);
        Case caseRec3= new Case(contactid = conRec2.id, Subject = 'Test2', accountid = accRec2.Id, recordtypeid= caseTechnicalRT, Description = 'Test', Validation_override__c = true, Origin = 'Email', Do_not_show_in_portal__c = False , Community_Sharing_Set_Account_Lookup__c = accRec2.Id, Indirect_Customer__c = accRec.Id);
        caselist.add(caseRec3);
        insert caselist;

        Test.stopTest();
        Set<Id> caseIds = new Set<Id>();
        for(Case c: caselist){
            caseIds.add(c.Id);
        }

        List<Case> cases = [SELECT Id, AccountId, Community_Sharing_Set_Account_Lookup__c, Created_By_Account__c, Indirect_Customer__c, Policy_Domain__c, Account.AKAM_Account_Id__c, RecordType.Name, IsClosed, ContactId, Contact.AccountID, Contact.Account.AKAM_Account_Id__c, Indirect_Customer__r.AKAM_Account_Id__c,Contact.Account.Name FROM Case WHERE Id IN :caseIds];

        SC_Jarvis_CaseUpdate_Batch2.populateAccountFields(cases);

    }

    @IsTest
    public static void test_populateAccountFields2(){

        testDataSetup();
        Test.startTest();
        Id caseTechnicalRT = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        List<case> caselist = new List<case>();
        Case caseRec= new Case(contactid = conRec.id, Subject = 'Test', accountid = accRec.Id, recordtypeid= caseTechnicalRT, Description = 'Test', Validation_override__c = true, Origin = 'Email', Do_not_show_in_portal__c = False, Community_Sharing_Set_Account_Lookup__c = accRec.Id );
        caselist.add(caseRec);
        Case caseRec3= new Case(contactid = conRec2.id, Subject = 'Test2', accountid = accRec2.Id, recordtypeid= caseTechnicalRT, Description = 'Test', Validation_override__c = true, Origin = 'Email', Do_not_show_in_portal__c = False , Community_Sharing_Set_Account_Lookup__c = accRec2.Id, Indirect_Customer__c = accRec.Id);
        caselist.add(caseRec3);
        insert caselist;

        Test.stopTest();
        Set<Id> caseIds = new Set<Id>();
        for(Case c: caselist){
            caseIds.add(c.Id);
        }

        List<Case> cases = [SELECT Id, AccountId, Community_Sharing_Set_Account_Lookup__c, Created_By_Account__c, Indirect_Customer__c, Policy_Domain__c, Account.AKAM_Account_Id__c, RecordType.Name, IsClosed, ContactId, Contact.AccountID, Contact.Account.AKAM_Account_Id__c, Indirect_Customer__r.AKAM_Account_Id__c,Contact.Account.Name FROM Case WHERE Id IN :caseIds];

        SC_Jarvis_CaseUpdate_Batch2.populateAccountFieldsSOCC(cases);

    }
    
    

}