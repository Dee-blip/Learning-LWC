/* 
/***************************************************************************
 * Name             : SC_Jarvis_TestClass2
 * Created By       : Sharath Prasanna
 * Created Date     : 22 Sep 2021
 * Purpose          : Code Coverage for below Components:
 						1. SC_Jarvis_Case_Questionnaire_Controller - Apex Class
                        2. SC_Jarvis_Delete_Siebel_Data_Batch - Apex Class
                        3. SC_Jarvis_CaseHistory_Controller - Apex Class
                        4. SC_Select_Options_Wrapper - Apex ClassTrigger
                        5. SC_Select_Options - Apex Class
                        6. SC_Jarvis_Case_Provision_Queue - Apex Class
                        7. SC_Jarvis_User_Setup_Batch - Apex Class
                        8. SC_Jarvis_Permission_Setup_Batch - Apex Class
                        9. SC_Jarvis_Search_Controller - Apex Class
                        10. SC_Jarvis_AuthorizedContact_Queue - Apex Class
                        11. SC_Jarvis_Permission_Deprovision_Batch - Apex Class
                        12. SC_Jarvis_User_Permission_Queue - Apex Class
                        13. SC_Jarvis_User_Deprovision_Batch - Apex Class
                        14. SC_Jarvis_User_Deprovision_Queue - Apex Class
 
 *****************************************************************************/ 


@isTest(SeeAllData=false)
public without sharing class SC_Jarvis_TestClass2 
{
    public SC_Jarvis_TestClass2() 
    {

    }
    public static Case newCasetech;
    public static EB_AccountProductMap__c caseProd;
    public static Account accRec;
    public static Contact conRec;
    public static AccountContactRelation acrRec;
    public static Policy_Domain__c pdRec;
    public static Authorized_Contact__c acRec;
    public static SC_Case_Issue_Sync_Admin_Setting__c adminRec;
    static
    {
        createTestData();
    }
    Public static void createTestData()
    {
        utilTestClass.createCustomSettings();        

        adminRec =  new SC_Case_Issue_Sync_Admin_Setting__c();
        adminRec.Access_Token_Issues_API__c = '';
        adminRec.Client_Certificate__c = 'EAA_KMI_Signed_Certificate';
        adminRec.Client_Id_Issues_API__c = '90f8e0f1-696b-46f9-a504-3811b8ce00fc';
        adminRec.Client_Secret_Issues_API__c = 'b8a4f2c9-24e5-4d5e-a794-6b98730b6915';
        adminRec.Hostname_Issues_API__c = 'https://qa.dash-ext.akamai.com/';
        adminRec.Oauth_Endpoint_Issues_API__c = 'oauth2/token';
        adminRec.Scope_Issues_API__c = 'network-services/issues/v1/issues/';
        adminRec.Jarvis_IDM_Scope__c = 'GET_IDM_PERMISSION';
        adminRec.Get_API_Jarvis__c	= 'cases-external-idm/v1/fetchpermission';

        insert adminRec;
        
        CHIME_GSS_Settings__c setting = new CHIME_GSS_Settings__c();
        setting.name = 'CHIME GSS';
        setting.Business_Hour_ID__c = '01mG0000000GptZIAS';
        setting.Default_ContactId__c = '003G000001LD4tWIAT';
        setting.Last_Success_Run__c = '1632358933302';
        setting.P1_Escalation_Hours__c = 24;
        setting.P2_Escalation_Hours__c = 48;
        setting.P3_Escalation_Hours__c = 72;
        setting.Question_Admin_Email__c = 'test@test.com';
        insert setting;        
       
       //Account Setup
       accRec = new Account(Name='Test Account Jarvis',AKAM_Account_ID__c='Test-ABC-123Jarvis',Type='Direct - Active');
       insert accRec;
                
       newCasetech = new Case();
       newCasetech.Subject = 'TestCasetechnical';
       newCasetech.Description = 'TestDescription';
       newCasetech.Severity__c = '3';
       newCasetech.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical').getRecordTypeId();
       newCasetech.validation_override__c = true;
       newCasetech.accountId = accRec.Id;
       newCasetech.origin='Email';

       caseProd = new EB_AccountProductMap__c();
       caseProd.EB_Product__c = 'product1';
       caseProd.Name = 'product1';
       caseProd.EB_Account__c = accRec.id;
       caseProd.EB_MarkedForDeletion__c = false;

       //Contact Setup
       conRec = new Contact(AccountId = accRec.Id, Login__c = 'Test_xyz2',Akam_Contact_id__c ='test-222', Email = 'test222@test.com' ,No_Longer_with_Company__c = false, LastName = 'Test Contact2', Contact_Type__c ='Technical Primary - 24x7', Active_Portal_Login__c = True, Primary_Contact_Method__c = 'Phone');
       insert conRec;
           
        
    //    AccountContactRelation acrRec = new AccountContactRelation(AccountID = accRec.Id, ContactId = conRec.Id, IsActive = true);
    //     insert acrRec;
        
           
        pdRec = new Policy_Domain__c(Name = 'Testpd', Account_Name__c = accRec.Id, AKAM_Policy_Domain_ID__c = 'Test_ABC_Jarvis', Policy_Domain_Description__c = 'default Test-Pd-123', Policy_Domain_State__c = 'Active', Product__c = 'defaulttestproduct', Additional_Product__c = 'test add prod');
        insert pdRec;
           
        acRec = new Authorized_Contact__c (Contact_Name__c = conRec.Id, Emergency_Email__c = true, Policy_Domain__c = pdRec.Id, Product_Interests__c = 'All');
        insert acRec;
        
    }

    @isTest static void testCaseQuestionController()
    {
        Siebel_Marketing_Prod_Case_Prod_Map__c mapping1 = new Siebel_Marketing_Prod_Case_Prod_Map__c();
        mapping1.Case_Product_Name__c = 'product1';
        mapping1.Service_Product__c = true;

        Case_Product_Siebel_LOV__c lovRec = new Case_Product_Siebel_LOV__c();
        lovRec.Product__c = 'product1';
        lovRec.Problem__c = 'problem1';
        lovRec.Marked_For_Deletion__c = false;
        
            
        Test.startTest();        
            insert mapping1;
            insert lovRec;
            SC_Jarvis_Case_Questionnaire_Controller classVar = new SC_Jarvis_Case_Questionnaire_Controller();
            SC_Jarvis_Case_Questionnaire_Controller.findLookupRecords('product1');
            SC_Jarvis_Case_Questionnaire_Controller.getProblem('product1');
        Test.stoptest();
    }

    @isTest static void testSiebelDeleteBatch()
    {
        Case_Product_Siebel_LOV__c lovRec = new Case_Product_Siebel_LOV__c();
        lovRec.Product__c = 'product1';
        lovRec.Problem__c = 'problem1';
        lovRec.Marked_For_Deletion__c = true;
        
            
        Test.startTest();        
            insert lovRec;
            SC_Jarvis_Delete_Siebel_Data_Batch batchVar = new SC_Jarvis_Delete_Siebel_Data_Batch();
            batchVar.objectType = 'Case_Product_Siebel_LOV__c';
            database.executeBatch(batchVar);
        Test.stoptest();
    }

    @isTest static void testCaseHistoryController()
    {
        Test.startTest();
            Insert newCasetech;     
            List<CaseHistory> histories = new List<CaseHistory>();
            histories.add(new CaseHistory(CaseId=newCasetech.Id, Field='Status'));
            histories.add(new CaseHistory(CaseId=newCasetech.Id, Field='ownerAssignment'));
            histories.add(new CaseHistory(CaseId=newCasetech.Id, Field='Severity__c'));
            insert histories;
            
            Case_History_Custom__c customRec= new Case_History_Custom__c();
            customRec.Field__c = 'Alternate Contact Company';
            customRec.New_Value__c = 'test1';
            customRec.Original_Value__c = 'test2';
            customRec.case__c = newCasetech.Id;
            insert customRec;
            new SC_Jarvis_CaseHistory_Controller();

            SC_Jarvis_CaseHistory_Controller.getCurrentAction('test1','test2','test');
            SC_Jarvis_CaseHistory_Controller.getCurrentAction('','test2','test');
            SC_Jarvis_CaseHistory_Controller.getCurrentAction('','','test');
            SC_Jarvis_CaseHistory_Controller.getCurrentAction('test1','','test');
            SC_Jarvis_CaseHistory_Controller.getHistoryWrapper(newCasetech.Id,0,10);
        Test.stoptest();
    }

    @isTest static void testSelectOptionWrapper()
    {
        Test.startTest();                                
            SC_Select_Options wrapper = new SC_Select_Options('test','test');
            List<SC_Select_Options> options = new List<SC_Select_Options>();
            options.add(wrapper);
            new SC_Select_Options_Wrapper(options,'test');
            new SC_Select_Options_Wrapper();
        Test.stoptest();
    }

    @isTest static void testCaseProvisionQueue()
    {
        Test.startTest(); 
            Insert newCasetech;                               
            SC_Jarvis_Case_Provision_Queue queueRec = new SC_Jarvis_Case_Provision_Queue();
            queueRec.caseIds.add(newCasetech.Id);
            System.enqueueJob(queueRec);
        Test.stoptest();
    }

    @isTest static void testUserSetupBatch()
    {
        Test.startTest();   
        
            SC_Jarvis_User_Setup_Batch batchRec = new SC_Jarvis_User_Setup_Batch();
            batchRec.contactIds.add(conRec.Id);
            Database.executeBatch(batchRec);
        Test.stoptest();
    }

    @isTest static void testJarvisPermissionSetupBatch()
    {
        Test.startTest();   
            Id profileid = [Select id from profile where name = 'SFCommunityCustomers' limit 1].Id;
            user adminUser = [Select id from User where name = 'CRM Ops' limit 1];
            system.runAs(adminUser)
            {
                insert SC_Jarvis_CoreSecurityController.createNewCustomerUser (conRec,SC_Jarvis_CoreSecurityController.getLoggedInUser() , profileId);
                
                SC_Jarvis_Permission_Setup_Batch batchRec = new SC_Jarvis_Permission_Setup_Batch();
                batchRec.contactIds.add(conRec.Id);
                Database.executeBatch(batchRec);
    
            }
    

        Test.stoptest();
    }

    @isTest static void testJarvisSearchController()
    {
        Test.startTest();   
            Knowledge__kav htKAV = new Knowledge__kav(Title='Random Unique Title12121',Summary='How To summary',UrlName='RandomUniqueTitle12121');
            insert htKAV;
            List<KnowledgeArticleVersion> kaVersionList = [Select Id,KnowledgeArticleId,Title,ArticleNumber,OwnerId,VersionNumber from KnowledgeArticleVersion where Language='en_US' AND PublishStatus = 'Draft'];
            
            KbManagement.PublishingService.publishArticle(kaVersionList.get(0).KnowledgeArticleId,true);
    
            new SC_Jarvis_Search_Controller();
            SC_Jarvis_Search_Controller.searchKnowledge('Random Unique','How To','Article');
            SC_Jarvis_Search_Controller.searchKnowledge('Random Unique','How To','Feed');
            SC_Jarvis_Search_Controller.searchKnowledge('Random Unique','How To','Both');
        Test.stoptest();
    }

    @isTest static void testAuthorizedContactQueue()
    {
        Test.startTest();                                
            SC_Jarvis_AuthorizedContact_Queue queueRec = new SC_Jarvis_AuthorizedContact_Queue();
            queueRec.authorizedContactGroups.add(conRec.id + '-'+pdRec.Id);
            System.enqueueJob(queueRec);
        Test.stoptest();
    }
 
    @isTest static void testJarvisPermissionDeprovisionBatch()
    {
        Test.startTest();   
            Jarvis_Contact_ACC_Permission__c permissionRec= new Jarvis_Contact_ACC_Permission__c();
            permissionRec.contact__c = conRec.Id;
            permissionRec.Active__c = true;
            permissionRec.Akam_Contact_ACC_Permission_Id__c = conRec.Akam_Contact_Id__c;            
            insert permissionRec;

            SC_Jarvis_Permission_Deprovision_Batch batchRec = new SC_Jarvis_Permission_Deprovision_Batch();
            batchRec.contactIds.add(conRec.Id);
            Database.executeBatch(batchRec);

        Test.stoptest();
    }


    @isTest static void testJarvisUserPermissionQueue1()
    {
        Test.startTest(); 
            Test.setMock(HttpCalloutMock.class, new SC_Jarvis_PermissionHttpRequestMock());                      
            Id profileid = [Select id from profile where name = 'SFCommunityCustomers' limit 1].Id;
            user adminUser = [Select id from User where name = 'CRM Ops' limit 1];
            system.runAs(adminUser)
            {
                adminRec.Jarvis_Access_Token__c = '1234556';
                adminRec.Jarvis_Token_Expiry_Datetime__c = Datetime.now().addHours(12);
                update adminRec;
                insert SC_Jarvis_CoreSecurityController.createNewCustomerUser (conRec,SC_Jarvis_CoreSecurityController.getLoggedInUser() , profileId);
                
                SC_Jarvis_User_Permission_Queue queueRec = new SC_Jarvis_User_Permission_Queue();
                queueRec.contactIds.add(conRec.id);
                System.enqueueJob(queueRec);
    
            }

                                       
        Test.stoptest();
    }

    @isTest static void testJarvisUserPermissionQueue2()
    {
        Test.startTest(); 
            Id profileid = [Select id from profile where name = 'SFCommunityCustomers' limit 1].Id;
            user adminUser = [Select id from User where name = 'CRM Ops' limit 1];
            system.runAs(adminUser)
            {
                SC_Jarvis_User_Permission_Queue queueRec = new SC_Jarvis_User_Permission_Queue();
                queueRec.contactIds.add(conRec.id);
                System.enqueueJob(queueRec);
    
            }

                                       
        Test.stoptest();
    }

    @isTest static void testJarvisUserDeprovisionBatch1()
    {
        Test.startTest();   
            Id profileid = [Select id from profile where name = 'SFCommunityCustomers' limit 1].Id;
            user adminUser = [Select id from User where name = 'CRM Ops' limit 1];
            system.runAs(adminUser)
            {
                User communityUser = SC_Jarvis_CoreSecurityController.createNewCustomerUser(conRec,SC_Jarvis_CoreSecurityController.getLoggedInUser() , profileId);
                insert communityUser;

                Jarvis_Contact_ACC_Permission__c permissionRec= new Jarvis_Contact_ACC_Permission__c();
                permissionRec.contact__c = conRec.Id;
                permissionRec.Active__c = true;
                permissionRec.User__c = communityUser.Id;
                permissionRec.Akam_Contact_ACC_Permission_Id__c = conRec.Akam_Contact_Id__c;            
                insert permissionRec;

                SC_Jarvis_User_Deprovision_Batch batchRec = new SC_Jarvis_User_Deprovision_Batch();
                batchRec.contactIds.add(conRec.Id);
                Database.executeBatch(batchRec);
            }
        Test.stoptest();
    }

    @isTest static void testJarvisUserDeprovisionBatch2()
    {
        Test.startTest();   
            Id profileid = [Select id from profile where name = 'SFCommunityCustomers' limit 1].Id;
            user adminUser = [Select id from User where name = 'CRM Ops' limit 1];
            system.runAs(adminUser)
            {
                SC_Jarvis_User_Deprovision_Batch batchRec = new SC_Jarvis_User_Deprovision_Batch();
                Database.executeBatch(batchRec);                    
            }
        Test.stoptest();
    }

    @isTest static void testJarvisUserDeprovisionQueue()
    {
        Test.startTest();   
            Id profileid = [Select id from profile where name = 'SFCommunityCustomers' limit 1].Id;
            user adminUser = [Select id from User where name = 'CRM Ops' limit 1];
            system.runAs(adminUser)
            {
                User communityUser = SC_Jarvis_CoreSecurityController.createNewCustomerUser(conRec,SC_Jarvis_CoreSecurityController.getLoggedInUser() , profileId);
                insert communityUser;

                Jarvis_Contact_ACC_Permission__c permissionRec= new Jarvis_Contact_ACC_Permission__c();
                permissionRec.contact__c = conRec.Id;
                permissionRec.Active__c = true;
                permissionRec.User__c = communityUser.Id;
                permissionRec.Akam_Contact_ACC_Permission_Id__c = conRec.Akam_Contact_Id__c;            
                insert permissionRec;

                SC_Jarvis_User_Deprovision_Queue queueRec = new SC_Jarvis_User_Deprovision_Queue();
                queueRec.contactIds.add(conRec.Id);
                System.enqueueJob(queueRec);
            }
        Test.stoptest();
    }

    @isTest static void contractTriggerTest()
    {
        Test.startTest();   
            PSA_TestUtility testUtil = new PSA_TestUtility();
            SC_Jarvis_CoreSecurityController.createPublicGroupForSObjectRecChk = false;
            Merge_contract_Header__c contract = testUtil.newContract(false, accRec.Id, '123','456',null,System.today(), System.today().addDays(50));
            contract.Original_Contract_Id__c = '123';
            contract.Account_name__c = accRec.Id;
            contract.Akam_NAP_Master_Contract_ID__c = '999';
            insert contract;

            accRec = new Account(Name='Test Account Jarvis2',AKAM_Account_ID__c='Test-ABC-123Jarvis2',Type='Direct - Active');
            insert accRec;
     

            contract.account_Name__c = accRec.Id;           
            update contract;
        Test.stoptest();

    }
    @isTest static void contractTriggerTest2()
    {
        Test.startTest();   
            PSA_TestUtility testUtil = new PSA_TestUtility();
            SC_Jarvis_CoreSecurityController.createPublicGroupForSObjectRecChk = false;

            Opportunity opp = testUtil.newOpportunity(false,accRec.Id, '0=Plan', System.today());
            opp.StageName = '1. Identify Need';
            opp.Validation_Override__c = TRUE;
            insert opp;
    
            Merge_contract_Header__c contract = testUtil.newContract(false, accRec.Id, '123','456',null,System.today(), System.today().addDays(50));
            contract.Original_Contract_Id__c = '123';
            contract.Account_name__c = accRec.Id;
            contract.Opportunity_Name__c = opp.id;
            contract.Akam_NAP_Master_Contract_ID__c = '999';

            insert contract;

            opp = testUtil.newOpportunity(false,accRec.Id, '0=Plan', System.today());
            opp.StageName = '1. Identify Need';
            opp.Validation_Override__c = TRUE;
            insert opp;

            contract.Opportunity_Name__c = opp.id;
            update contract;

        Test.stoptest();

    }

    @isTest static void contractTriggerTest3()
    {
        Test.startTest();   
            PSA_TestUtility testUtil = new PSA_TestUtility();

            SC_Jarvis_CoreSecurityController.createPublicGroupForSObjectRecChk = true;
            Merge_contract_Header__c contract1 = testUtil.newContract(false, accRec.Id, '1234','999',null,System.today(), System.today().addDays(50));
            contract1.Original_Contract_Id__c = '1234';
            contract1.Account_name__c = accRec.Id;
            contract1.Akam_NAP_Master_Contract_ID__c = '999';
            contract1.account_Name__c = accRec.Id;      
            contract1.Contract_Type__c = 'Value Added Reseller';      
            insert contract1;

            accRec = new Account(Name='Test Account Jarvis2',AKAM_Account_ID__c='Test-ABC-123Jarvis5',Type='Direct - Active');
            insert accRec;

            SC_Jarvis_CoreSecurityController.createPublicGroupForSObjectRecChk = false;
            Merge_contract_Header__c contract = testUtil.newContract(false, accRec.Id, '123','9999',null,System.today(), System.today().addDays(50));
            contract.Original_Contract_Id__c = '123';
            contract.Account_name__c = accRec.Id;
            contract.Akam_NAP_Master_Contract_ID__c = '9999';
            contract.account_Name__c = accRec.Id;      
            contract.Contract_Type__c = 'Value Added Reseller';      
            contract.Parent_Contract__c = contract1.Id;
            insert contract;

     

        Test.stoptest();

    }

    @isTest static void coreSecurity1()
    {
        Test.startTest();   
        
        Insert newCasetech;
        Group reg = new group();
        reg.Name = 'JARVIS_WRITE';
        reg.Type = 'Regular';
        insert reg;

        List<Sobject> shares = new List<Sobject>();
        shares.add(SC_Jarvis_utility.createCaseShare(newCasetech.ID, reg.ID, 'JARVIS_WRITE'));
        
        community_comments__c comment = new community_comments__c();
        comment.Parent_ID__c = newCasetech.id;
        comment.Visibility__c = 'Public';
        comment.Account_ID_for_Community_Share__c = accRec.id;
        comment.Application__c = 'JARVIS';
        comment.Related_Object__c = 'Case';
        comment.AKAM_Created_Date__c = datetime.now();
        comment.AKAM_Modified_Date__c = Datetime.now();
        comment.Commented_By__c = 'Customer';
        insert comment;
    
        shares.add(SC_Jarvis_utility.createCommentShare(comment.Id, reg.ID));

        insert shares;

        SC_Jarvis_CoreSecurityController.caseShareListJarvisDeprovision(new List<String> {newCasetech.id});
        Test.stopTest();

    }
    @isTest static void contactTrigger1()
    {
        Test.startTest();   
            conRec.Active_portal_login__c = false;
            update conRec;

            ContactTriggerHandler handler = new ContactTriggerHandler();
            handler.afterDeleteAfterUndeleteTrigger();
        Test.stopTest();

    }

    @isTest static void coreSecurity2()
    {
        Test.startTest();   

            insert caseProd;
            newCasetech.case_product__c = caseProd.Id;
            Insert newCasetech;
            community_comments__c comment = new community_comments__c();
            comment.Parent_ID__c = newCasetech.id;
            comment.Visibility__c = 'Public';
            comment.Account_ID_for_Community_Share__c = accRec.id;
            comment.Application__c = 'JARVIS';
            comment.Related_Object__c = 'Case';
            comment.AKAM_Created_Date__c = datetime.now();
            comment.AKAM_Modified_Date__c = Datetime.now();
            comment.Commented_By__c = 'Customer';
            insert comment;

            SC_Jarvis_CoreSecurityController.calculateAndAssignCaseShare(new List<String>{newCasetech.id});

        Test.stopTest();
    }

    @isTest static void coreSecurity3()
    {
        Test.startTest();   
        
            newCasetech.recordTypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get('AMG').getRecordTypeId();
            Insert newCasetech;
            community_comments__c comment = new community_comments__c();
            comment.Parent_ID__c = newCasetech.id;
            comment.Visibility__c = 'Public';
            comment.Account_ID_for_Community_Share__c = accRec.id;
            comment.Application__c = 'JARVIS';
            comment.Related_Object__c = 'Case';
            comment.AKAM_Created_Date__c = datetime.now();
            comment.AKAM_Modified_Date__c = Datetime.now();
            comment.Commented_By__c = 'Customer';
            insert comment;

            SC_Jarvis_CoreSecurityController.calculateAndAssignCaseShare(new List<String>{newCasetech.id});

        Test.stopTest();
    }

    @isTest static void coreSecurity4()
    {
        Test.startTest();   
        
            newCasetech.recordTypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Billing').getRecordTypeId();
            Insert newCasetech;
            community_comments__c comment = new community_comments__c();
            comment.Parent_ID__c = newCasetech.id;
            comment.Visibility__c = 'Public';
            comment.Account_ID_for_Community_Share__c = accRec.id;
            comment.Application__c = 'JARVIS';
            comment.Related_Object__c = 'Case';
            comment.AKAM_Created_Date__c = datetime.now();
            comment.AKAM_Modified_Date__c = Datetime.now();
            comment.Commented_By__c = 'Customer';
            insert comment;

            SC_Jarvis_CoreSecurityController.calculateAndAssignCaseShare(new List<String>{newCasetech.id});

        Test.stopTest();
    }

    @isTest static void coreSecurity5()
    {
        Test.startTest();   
        
            insert caseProd;
            newCasetech.recordTypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();
            newCasetech.case_product__c = caseProd.Id;
            Insert newCasetech;
            community_comments__c comment = new community_comments__c();
            comment.Parent_ID__c = newCasetech.id;
            comment.Visibility__c = 'Public';
            comment.Account_ID_for_Community_Share__c = accRec.id;
            comment.Application__c = 'JARVIS';
            comment.Related_Object__c = 'Case';
            comment.AKAM_Created_Date__c = datetime.now();
            comment.AKAM_Modified_Date__c = Datetime.now();
            comment.Commented_By__c = 'Customer';
            insert comment;

            SC_Jarvis_CoreSecurityController.calculateAndAssignCaseShare(new List<String>{newCasetech.id});

        Test.stopTest();
    }

    @isTest static void coreSecurity6()
    {
        Test.startTest();   
        
            newCasetech.recordTypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Managed Security').getRecordTypeId();
            Insert newCasetech;
            community_comments__c comment = new community_comments__c();
            comment.Parent_ID__c = newCasetech.id;
            comment.Visibility__c = 'Public';
            comment.Account_ID_for_Community_Share__c = accRec.id;
            comment.Application__c = 'JARVIS';
            comment.Related_Object__c = 'Case';
            comment.AKAM_Created_Date__c = datetime.now();
            comment.AKAM_Modified_Date__c = Datetime.now();
            comment.Commented_By__c = 'Customer';
            insert comment;

            SC_Jarvis_CoreSecurityController.calculateAndAssignCaseShare(new List<String>{newCasetech.id});
        Test.stopTest();
    }

    @isTest static void coreSecurity7()
    {
        Test.startTest();   

            PSA_TestUtility testUtil = new PSA_TestUtility();
            testUtil.newSCEmailSetup(true);

            Merge_Contract_Header__c contract = testUtil.newContract(false, accRec.Id, '123','456',null,System.today(), System.today().addDays(50));
            contract.Original_Contract_Id__c = '123';
            insert contract;

            Merge_Contract_Detail__c contDetailCommitted = testUtil.newContractDetail(false, 'test','test',null, System.today(), System.today().addDays(50));
            contDetailCommitted.Record_Type__c = 'Committed';
            contDetailCommitted.Billing_Duration__c = 'Monthly';
            contDetailCommitted.Product_Id__c = 'M-LC-160618';
            contDetailCommitted.Units_Low__c = 30;
            contDetailCommitted.Product__c = 'Test1';
            contDetailCommitted.Unit_of_Measure__c = 'Hour';
            contDetailCommitted.Original_Contract_Id__c = contract.Id;
            insert contDetailCommitted;

            Siebel_Marketing_Prod_Case_Prod_Map__c mapping1 = new Siebel_Marketing_Prod_Case_Prod_Map__c();
            mapping1.Case_Product_Name__c = 'product1';
            mapping1.Service_Product__c = true;
            mapping1.Marketing_Product_ID__c = 'M-LC-160618';
            insert mapping1;

            Case_Product_Siebel_LOV__c lovRec = new Case_Product_Siebel_LOV__c();
            lovRec.Product__c = 'product1';
            lovRec.Problem__c = 'problem1';
            lovRec.Marked_For_Deletion__c = false;
            lovRec.Area__C = 'Technical Support';
            insert lovRec;

            CONTRACT_ENGINEERING_PRODUCT_DETAIL__c cepd = new CONTRACT_ENGINEERING_PRODUCT_DETAIL__c();  
            cepd.contract_id__c = '123';
            cepd.EFFECTIVE_END_DATE__c = date.today().addDays(20);
            cepd.ENGINEERING_PRODUCT_NAME__c = 'Professional_Services::Luna_PS_Request';
            cepd.MARKETING_PRODUCT_NAME__c = 'test222';
            insert cepd;

            PAC_Product_Catalog__c cp = new PAC_Product_Catalog__c();
            cp.Marketing_Product_Id__c = 'M-LC-160618';
            cp.Business_Unit__c = '1234';
            insert cp;
        
            insert caseProd;
            newCasetech.recordTypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();
            newCasetech.case_product__c = caseProd.Id;
            insert newCasetech;

            community_comments__c comment = new community_comments__c();
            comment.Parent_ID__c = newCasetech.id;
            comment.Visibility__c = 'Public';
            comment.Account_ID_for_Community_Share__c = accRec.id;
            comment.Application__c = 'JARVIS';
            comment.Related_Object__c = 'Case';
            comment.AKAM_Created_Date__c = datetime.now();
            comment.AKAM_Modified_Date__c = Datetime.now();
            comment.Commented_By__c = 'Customer';
            insert comment;

            SC_Jarvis_CoreSecurityController.calculateAndAssignCaseShare(new List<String>{newCasetech.id});

        Test.stopTest();
    }
    @isTest static void coreSecurity8()
    {
        Test.startTest();   
        
            newCasetech.recordTypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Managed Security').getRecordTypeId();
            Insert newCasetech;
            community_comments__c comment = new community_comments__c();
            comment.Parent_ID__c = newCasetech.id;
            comment.Visibility__c = 'Public';
            comment.Account_ID_for_Community_Share__c = accRec.id;
            comment.Application__c = 'JARVIS';
            comment.Related_Object__c = 'Case';
            comment.AKAM_Created_Date__c = datetime.now();
            comment.AKAM_Modified_Date__c = Datetime.now();
            comment.Commented_By__c = 'Customer';
            insert comment;

            Group reg = new group();
            reg.Name = 'JARVIS_WRITE';
            reg.Type = 'Regular';
            insert reg;
    
            //SC_Jarvis_CoreSecurityController.calculateAndAssignCaseShare(new List<String>{newCasetech.id});
            Map<String,Case> caseIdtoRec = new Map<String,Case>();
            caseIdtoRec.put(newCasetech.Id,newCasetech);

            Map<String,Set<String>> casesToSetGroups = new Map<String,Set<String>>();
            casesToSetGroups.put(newCasetech.Id,new Set<String>{'JARVIS_WRITE'});

            SC_Jarvis_CoreSecurityController.assignCaseAndCommentShares(casesToSetGroups,caseIdtoRec);
        Test.stopTest();
    }    
    @isTest static void coreSecurity9()
    {
        Test.startTest();   

            PSA_TestUtility testUtil = new PSA_TestUtility();
            testUtil.newSCEmailSetup(true);

            Merge_Contract_Header__c contract = testUtil.newContract(false, accRec.Id, '123','456',null,System.today(), System.today().addDays(50));
            contract.Original_Contract_Id__c = '123';
            insert contract;

            Merge_Contract_Detail__c contDetailCommitted = testUtil.newContractDetail(false, 'test','test',null, System.today(), System.today().addDays(50));
            contDetailCommitted.Record_Type__c = 'Committed';
            contDetailCommitted.Billing_Duration__c = 'Monthly';
            contDetailCommitted.Product_Id__c = 'M-LC-160618';
            contDetailCommitted.Units_Low__c = 30;
            contDetailCommitted.Product__c = 'Test1';
            contDetailCommitted.Unit_of_Measure__c = 'Hour';
            contDetailCommitted.Original_Contract_Id__c = contract.Id;
            insert contDetailCommitted;

            Siebel_Marketing_Prod_Case_Prod_Map__c mapping1 = new Siebel_Marketing_Prod_Case_Prod_Map__c();
            mapping1.Case_Product_Name__c = 'product1';
            mapping1.Service_Product__c = true;
            mapping1.Marketing_Product_ID__c = 'M-LC-160618';
            insert mapping1;

            Case_Product_Siebel_LOV__c lovRec = new Case_Product_Siebel_LOV__c();
            lovRec.Product__c = 'product1';
            lovRec.Problem__c = 'problem1';
            lovRec.Marked_For_Deletion__c = false;
            lovRec.Area__C = 'Technical Support';
            insert lovRec;

            CONTRACT_ENGINEERING_PRODUCT_DETAIL__c cepd = new CONTRACT_ENGINEERING_PRODUCT_DETAIL__c();  
            cepd.contract_id__c = '123';
            cepd.EFFECTIVE_END_DATE__c = date.today().addDays(20);
            cepd.ENGINEERING_PRODUCT_NAME__c = 'Professional_Services::Luna_PS_Request';
            cepd.MARKETING_PRODUCT_NAME__c = 'test222';
            insert cepd;

            PAC_Product_Catalog__c cp = new PAC_Product_Catalog__c();
            cp.Marketing_Product_Id__c = 'M-LC-160618';
            cp.Business_Unit__c = '1234';
            insert cp;
        
            insert caseProd;
            
            newCasetech.recordTypeid = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();
            //newCasetech.case_product__c = caseProd.Id;
            newCasetech.Service__c = 'test222';
            newCasetech.PS_Product__c = 'product1';
            newCasetech.Subject = 'TEsting DEBUG';
            insert newCasetech;

            // Case caserec = [select Service__c,PS_Product__c from Case where id = :newCasetech.Id];
            // system.assertEquals(caserec.Service__c,caserec.PS_Product__c);

            SC_Jarvis_CoreSecurityController.calculateAndAssignCaseShare(new List<String>{newCasetech.id});

        Test.stopTest();
    }

    @isTest static void coreSecurity10()
    {
        Test.startTest();   
        
        Jarvis_Contact_ACC_Permission__c permissionRec= new Jarvis_Contact_ACC_Permission__c();
        permissionRec.contact__c = conRec.Id;
        permissionRec.Active__c = true;
        permissionRec.Akam_Contact_ACC_Permission_Id__c = conRec.Akam_Contact_Id__c;            
        insert permissionRec;


            SC_Jarvis_CoreSecurityController.forceSyncPermissions(new Set<Jarvis_Contact_ACC_Permission__c>{permissionRec});
        Test.stopTest();
    }
    @isTest static void coreSecurity11()
    {
        Test.setMock(HttpCalloutMock.class, new SC_Jarvis_PermissionHttpRequestMock()); 
        Test.startTest();   
            List<SC_Jarvis_CoreSecurityController.ContactPermissionWrapper> wrappers = new List<SC_Jarvis_CoreSecurityController.ContactPermissionWrapper>();
            wrappers.add(new SC_Jarvis_CoreSecurityController.ContactPermissionWrapper(conRec.Id,'test-222','test','Test_xyz2'));

            try
            {
                SC_Jarvis_CoreSecurityController.getIdmPermission(wrappers);
            }
            catch(Exception e)
            {
                
            }
            
        Test.stopTest();
    }
    
}