@isTest(SeeAllData=false)
public without sharing class SC_Jarvis_Utility_Test 
{    
    public SC_Jarvis_Utility_Test() 
    {

    }
    public static Case newCasetech;
    public static Account accRec;
    public static Contact conRec;
    public static AccountContactRelation acrRec;
    public static Policy_Domain__c pdRec;
    public static Authorized_Contact__c acRec;
    public static SC_Case_Issue_Sync_Admin_Setting__c adminRec;
    public static PSA_TestUtility testUtil;
    public static SC_SupportEmail__c scEmailSetup;
    public static Jarvis_Contact_ACC_Permission__c permissionRec;
    public static Merge_contract_Header__c contract;
    public static Merge_Contract_Detail__c contDetailCommitted;
    public static Jarvis_Contact_ACC_Permission_Contract__c contractRec;
    public static Siebel_Marketing_Prod_Case_Prod_Map__c mapping1;
    public static Case_Product_Siebel_LOV__c lovRec;
    public static CONTRACT_ENGINEERING_PRODUCT_DETAIL__c cepd;
    public static PAC_Product_Catalog__c cp;
    public static EB_AccountProductMap__c caseProd;
    public static Case_Questionnaire__c question;
    public static User customerUser;
    public static Id profileid;
    public static user adminUser;
    static
    {
        createTestData();
    }
    Public static void createTestData()
    {
        testUtil = new PSA_TestUtility();
        scEmailSetup = testUtil.newSCEmailSetup(true);

        utilTestClass.createCustomSettings();
        
        SC_Case_Issue_Sync_Admin_Setting__c adminRec =  new SC_Case_Issue_Sync_Admin_Setting__c();
        adminRec.Access_Token_Issues_API__c = '';
        adminRec.Client_Certificate__c = 'EAA_KMI_Signed_Certificate';
        adminRec.Client_Id_Issues_API__c = '90f8e0f1-696b-46f9-a504-3811b8ce00fc';
        adminRec.Client_Secret_Issues_API__c = 'b8a4f2c9-24e5-4d5e-a794-6b98730b6915';
        adminRec.Hostname_Issues_API__c = 'https://qa.dash-ext.akamai.com/';
        adminRec.Oauth_Endpoint_Issues_API__c = 'oauth2/token';
        adminRec.Scope_Issues_API__c = 'network-services/issues/v1/issues/';
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

        
        newCasetech = new Case();
        newCasetech.Subject = 'TestCasetechnical';
        newCasetech.Description = 'TestDescription';
        newCasetech.Severity__c = '3';
        newCasetech.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        newCasetech.validation_override__c = true;
        newCasetech.origin='Email';
        
        //Insert newCasetech;


        accRec = new Account(Name='Test Account Jarvis',AKAM_Account_ID__c='Test-ABC-123Jarvis',Type='Direct - Active');
        insert accRec;
                
        conRec = new Contact(AccountId = accRec.Id, Login__c = 'Test_xyz2',Akam_Contact_id__c ='test-222', Email = 'test222@test.com' ,No_Longer_with_Company__c = false, LastName = 'Test Contact2', Contact_Type__c ='Technical Primary - 24x7', Active_Portal_Login__c = True, Primary_Contact_Method__c = 'Phone');
        insert conRec;
           
    
        testUtil = new PSA_TestUtility();

        pdRec = new Policy_Domain__c(Name = 'Testpd', Account_Name__c = accRec.Id, AKAM_Policy_Domain_ID__c = 'Test_ABC_Jarvis', Policy_Domain_Description__c = 'default Test-Pd-123', Policy_Domain_State__c = 'Active', Product__c = 'defaulttestproduct', Additional_Product__c = 'test add prod');
           
        acRec = new Authorized_Contact__c (Contact_Name__c = conRec.Id, Emergency_Email__c = true, Policy_Domain__c = pdRec.Id, Product_Interests__c = 'All');
        

        profileid = [Select id from profile where name = 'SFCommunityCustomers' limit 1].Id;
        adminUser = [Select id from User where name = 'CRM Ops' limit 1];

        contract = testUtil.newContract(false, accRec.Id, '123','456',null,System.today(), System.today().addDays(50));
        contract.Original_Contract_Id__c = '123';
        
 
        contDetailCommitted = testUtil.newContractDetail(false, 'test','test',null, System.today(), System.today().addDays(50));
        contDetailCommitted.Record_Type__c = 'Committed';
        contDetailCommitted.Billing_Duration__c = 'Monthly';
        contDetailCommitted.Product_Id__c = 'M-LC-160618';
        contDetailCommitted.Units_Low__c = 30;
        contDetailCommitted.Product__c = 'Test1';
        contDetailCommitted.Unit_of_Measure__c = 'Hour';

        mapping1 = new Siebel_Marketing_Prod_Case_Prod_Map__c();
        mapping1.Case_Product_Name__c = 'product1';
        mapping1.Service_Product__c = true;
        mapping1.Marketing_Product_ID__c = 'M-LC-160618';

        lovRec = new Case_Product_Siebel_LOV__c();
        lovRec.Product__c = 'product1';
        lovRec.Problem__c = 'problem1';
        lovRec.Marked_For_Deletion__c = false;
        lovRec.Area__C = 'Technical Support';

        cepd = new CONTRACT_ENGINEERING_PRODUCT_DETAIL__c();  
        cepd.contract_id__c = '123';
        cepd.EFFECTIVE_END_DATE__c = date.today().addDays(20);
        cepd.ENGINEERING_PRODUCT_NAME__c = 'Professional_Services::Luna_PS_Request';
        cepd.MARKETING_PRODUCT_NAME__c = 'test222';

        cp = new PAC_Product_Catalog__c();
        cp.Marketing_Product_Id__c = 'M-LC-160618';
        cp.Business_Unit__c = '1234';

        caseProd = new EB_AccountProductMap__c();
        caseProd.EB_Product__c = 'product1';
        caseProd.EB_Account__c = accRec.id;
        caseProd.EB_MarkedForDeletion__c = false;


        question = new Case_Questionnaire__c();
        question.Help_Text__c = '123';
        question.Is_Active__c =true;
        question.Case_Product__c = 'product1';
        question.Problem__c = 'problem1';
        question.Question__c = 'test';
        question.Question_Type__c = 'URL';

    }

    @isTest static void testMethod1()
    {
        
            
        Test.startTest();        
            new SC_Jarvis_utility();
            SC_Jarvis_utility.getAccessSet('Write');
            AccountContactRelation acrRec = [Select Id, Application__c, isActive from AccountContactRelation limit 1];
            acrRec.Application__c = 'JARVIS';
            acrRec.isActive = true;
            update acrRec;
            insert pdRec;
            insert acRec;

            system.runAs(adminUser)
            {
                customerUser = SC_Jarvis_CoreSecurityController.createNewCustomerUser (conRec,SC_Jarvis_CoreSecurityController.getLoggedInUser() , profileId);
                customerUser.contactId = conRec.Id;
                insert customerUser;
            }

            permissionRec= new Jarvis_Contact_ACC_Permission__c();
            permissionRec.contact__c = conRec.Id;
            permissionRec.Active__c = true; 
            permissionRec.User__c = customerUser.id;           
            permissionRec.Akam_Contact_ACC_Permission_Id__c = conRec.Akam_Contact_Id__c;            
                        
            insert permissionRec;    
            insert contract;

            contractRec = new Jarvis_Contact_ACC_Permission_Contract__c();
            contractRec.Active__c = true;
            contractRec.Customer_Permission__c = permissionRec.Id;
            contractRec.Account__c = accRec.Id;
            contractRec.contract__c = contract.Id;
            contractRec.Permission__c = 'CASE_MANAGEMENT_WRITE;CASE_MANAGEMENT_PS_ACCESS';
            contractRec.Akam_Contact_ACC_Permission_Contract_ID__c = conRec.Id;
            insert contractRec;        
            
            SC_Jarvis_utility.getAccountRecords(conRec.Id,'ReadMode');
            SC_Jarvis_utility.getAccountRecords(conRec.Id,'EditMode');
            SC_Jarvis_Create_Case_Controller.getParentAccount(acRec.Id);

        Test.stoptest();
    }

    @isTest static void testMethod2()
    {

        Test.startTest();   

            insert mapping1;
            insert lovRec;

            SC_Jarvis_utility.getLOVs(null,accRec.id,new Set<String>{'product1'});
            SC_Jarvis_utility.getMappingRecords(new Set<String>{'product1'}, null);

        Test.stopTest();
    }
    @isTest static void testMethod3()
    {
        Test.startTest();   

            insert cepd;
            SC_Jarvis_utility.getServicesPS(new Set<String>{accRec.id},null, new Set<String>{'product1'}, 0);   
            SC_Jarvis_utility.getServicesPS(null,new Set<String>{'123'}, new Set<String>{'product1'}, 0);   

        Test.stopTest();
    }

    @isTest static void testMethod4()
    {
        Test.startTest();   

            insert cp;
            SC_Jarvis_utility.getBusinessUnit(new Set<String>{'1234'}, 0);
            insert caseProd;
            SC_Jarvis_utility.getCaseProduct('1234', accRec.id);

        Test.stopTest();
    }

    @isTest static void testMethod5()
    {
        Test.startTest();   

            SC_Jarvis_utility.getAreas('AMG');
            SC_Jarvis_utility.getAreas('Billing');
            SC_Jarvis_utility.getAreas('Technical');
            SC_Jarvis_utility.getAreas('PS');
            SC_Jarvis_utility.getAreas('SOCC');

            SC_Jarvis_utility.setSeverityMap();

        Test.stopTest();
    }

    @isTest static void testMethod6()
    {

        Test.startTest();   
            insert question;
            SC_Jarvis_utility.getQuestions(new Set<String>{'1234'}, new Set<String>{'99999'});

            SC_Jarvis_utility.getAccessLevel('CASE_MANAGEMENT_WRITE');

            SC_Jarvis_utility.stripHtmlTag('<b>test</b>', '<b>', '');

            SC_Jarvis_utility.isValidEmail('shprasan@akamai.com');

            SC_Jarvis_utility.filterValidEmails(new Set<String>{'shprasan@akamai.com'});

            SC_Jarvis_utility.getStatusValue('Unassigned');

            SC_Jarvis_utility.getCategoryRecordType('Client Services Manager/ Business Support Issue');
            SC_Jarvis_utility.getCategoryRecordType('Billing Support Issue or Question' );
            SC_Jarvis_utility.getCategoryRecordType('Technical Support Issue');
            SC_Jarvis_utility.getCategoryRecordType('Professional Services Request (billable)');
            SC_Jarvis_utility.getCategoryRecordType('Managed Security Support');

        Test.stoptest();
    }

    @isTest static void testMethod7()
    {
        Test.startTest();

            Knowledge__kav htKAV = new Knowledge__kav(Title='Random Unique Title12121',Summary='How To summary',UrlName='RandomUniqueTitle12121');
            insert htKAV;
            List<KnowledgeArticleVersion> kaVersionList = [Select Id,KnowledgeArticleId,Title,ArticleNumber,OwnerId,VersionNumber from KnowledgeArticleVersion where Language='en_US' AND PublishStatus = 'Draft'];
            
            KbManagement.PublishingService.publishArticle(kaVersionList.get(0).KnowledgeArticleId,true);
            SC_Jarvis_Create_Case_Controller.getKnowledgeDiscussion('Random Unique','How To' );
            SC_Jarvis_Create_Case_Controller.getArticleData(htKAV.id);
            SC_Jarvis_Create_Case_Controller.saveVote(htKAV.id,'Up');
            SC_Jarvis_Create_Case_Controller.saveVote(htKAV.id,'Down');
            SC_Jarvis_Create_Case_Controller.saveVote(htKAV.id,'None');
        Test.stopTest();
    }
    

    @isTest static void testMethod8()
    {
        Test.startTest();

            system.runAs(adminUser)
            {
                customerUser = SC_Jarvis_CoreSecurityController.createNewCustomerUser (conRec,SC_Jarvis_CoreSecurityController.getLoggedInUser() , profileId);
                customerUser.contactId = conRec.Id;
                insert customerUser;
            }

            insert pdRec;
            insert acRec;
            system.runAs(customerUser)
            {
                new SC_Jarvis_Create_Case_Controller();
                SC_Jarvis_Create_Case_Controller.getAccount(true);
                SC_Jarvis_Create_Case_Controller.getPolicyDomains(accRec.id);
    
            }

        Test.stopTest();
    }
    @isTest static void testMethod9()
    {
        Test.startTest();

            system.runAs(adminUser)
            {
                customerUser = SC_Jarvis_CoreSecurityController.createNewCustomerUser (conRec,SC_Jarvis_CoreSecurityController.getLoggedInUser() , profileId);
                customerUser.contactId = conRec.Id;
                insert customerUser;
            }
            insert pdRec;
            insert acRec;
            
            List<SC_Jarvis_Contact_ACC_Permission_Handler.AccountContactPermissionWrapper> wrappers = new
            List<SC_Jarvis_Contact_ACC_Permission_Handler.AccountContactPermissionWrapper>();

            SC_Jarvis_Contact_ACC_Permission_Handler.AccountContactPermissionWrapper accountWrapper= new 
            SC_Jarvis_Contact_ACC_Permission_Handler.AccountContactPermissionWrapper();

            SC_Jarvis_Contact_ACC_Permission_Handler.ContractPermissionWrapper contractWrapper= new 
            SC_Jarvis_Contact_ACC_Permission_Handler.ContractPermissionWrapper();
        
            contractWrapper.contractId = '123';
            contractWrapper.scopes = new String[] {'CASE_MANAGEMENT_WRITE', 'CASE_MANAGEMENT_PS_ACCESS'};

            accountWrapper.accountId = 'Test-ABC-123Jarvis';
            accountWrapper.authGrants = new SC_Jarvis_Contact_ACC_Permission_Handler.ContractPermissionWrapper[]{contractWrapper};

            wrappers.add(accountWrapper);

            insert contract;

            permissionRec= new Jarvis_Contact_ACC_Permission__c();
            permissionRec.contact__c = conRec.Id;
            permissionRec.Active__c = true; 
            permissionRec.User__c = customerUser.id;           
            permissionRec.Akam_Contact_ACC_Permission_Id__c = conRec.Akam_Contact_Id__c;            
            permissionRec.Response__c =  JSON.serialize(wrappers);                      
            insert permissionRec;    
               
            system.runAs(customerUser)
            {
                SC_Jarvis_Create_Case_Controller.getCategories(accRec.id);
            }            
            

        Test.stopTest();
    }
    @isTest static void testMethod10()
    {
        Test.startTest();
            newCasetech.jarvis_also_notify__c = 'shprasan@akamai.com';
            insert newCasetech;

            insert question;
            SC_Jarvis_Create_Case_Controller.getQuestionRecords('product1','problem1');
            SC_Jarvis_Create_Case_Controller.getCaseRecord(newCasetech.id);

            new SC_Jarvis_Create_Case_Controller.DiscussionWrapper('String titleString','String recordIdValue', 
            0,true);
            new SC_Jarvis_Create_Case_Controller.KnowledgeWrapper('String titleString','String summaryString', 'String akamIdValue', 
            'recordIdValue',10);
        Test.stopTest();
    }
    @isTest static void testMethod11()
    {
        Test.startTest();

            insert pdRec;
            insert acRec;

            system.runAs(adminUser)
            {
                newCasetech.jarvis_also_notify__c = 'shprasan@akamai.com';
                insert newCasetech;
    
            }

            SC_Jarvis_Create_Case_Controller.getCanInstruct(conRec.id);
        Test.stopTest();
    }
    @isTest static void testMethod12()
    {
        Test.startTest();
            system.runAs(adminUser)
            {
                newCasetech.jarvis_also_notify__c = 'shprasan@akamai.com';
                newCasetech.contactId = conRec.Id;
                insert newCasetech;
            }
            SC_Jarvis_Create_Case_Controller.getCaseContactAccess(newCasetech.id,true);
            SC_Jarvis_Create_Case_Controller.getCaseContactAccess(newCasetech.id,false);

        Test.stopTest();
    }

    @isTest static void testMethod13()
    {
        Test.startTest();

            SC_Jarvis_utility.getSeverityValuesCreateCase(accRec.id,'Technical','Carrier');
            SC_Jarvis_utility.getSeverityValuesCorrespondingToCase('Technical', null, accRec.id, '3');

            insert pdRec;
            insert acRec;

            system.runAs(adminUser)
            {
                customerUser = SC_Jarvis_CoreSecurityController.createNewCustomerUser (conRec,SC_Jarvis_CoreSecurityController.getLoggedInUser() , profileId);
                customerUser.contactId = conRec.Id;
                insert customerUser;
            }
            
            List<SC_Jarvis_Contact_ACC_Permission_Handler.AccountContactPermissionWrapper> wrappers = new
            List<SC_Jarvis_Contact_ACC_Permission_Handler.AccountContactPermissionWrapper>();

            SC_Jarvis_Contact_ACC_Permission_Handler.AccountContactPermissionWrapper accountWrapper= new 
            SC_Jarvis_Contact_ACC_Permission_Handler.AccountContactPermissionWrapper();

            SC_Jarvis_Contact_ACC_Permission_Handler.ContractPermissionWrapper contractWrapper= new 
            SC_Jarvis_Contact_ACC_Permission_Handler.ContractPermissionWrapper();
        
            contractWrapper.contractId = '123';
            contractWrapper.scopes = new String[] {'CASE_MANAGEMENT_WRITE', 'CASE_MANAGEMENT_PS_ACCESS'};

            accountWrapper.accountId = 'Test-ABC-123Jarvis';
            accountWrapper.authGrants = new SC_Jarvis_Contact_ACC_Permission_Handler.ContractPermissionWrapper[]{contractWrapper};

            wrappers.add(accountWrapper);

            insert contract;

            permissionRec= new Jarvis_Contact_ACC_Permission__c();
            permissionRec.contact__c = conRec.Id;
            permissionRec.Active__c = true; 
            permissionRec.User__c = customerUser.id;           
            permissionRec.Akam_Contact_ACC_Permission_Id__c = conRec.Akam_Contact_Id__c;            
            permissionRec.Response__c =  JSON.serialize(wrappers);                      
            insert permissionRec;    
              
            System.runAs(customerUser)
            {
                SC_Jarvis_utility.getCategoriesAccounts(conRec.id, new List<String>{accRec.Id});
            }
        Test.stopTest();
    }

    @isTest static void testMethod14()
    {
        Test.startTest();
            
            System.runAs(adminUser)
            {
                newCasetech.jarvis_also_notify__c = 'shprasan@akamai.com';
                insert newCasetech;    
            }

            
            Group reg = new group();
            reg.Name = 'JARVIS_PD';
            reg.Type = 'Regular';
            insert reg;
            SC_Jarvis_utility.createCaseShare(newCasetech.Id, reg.Id, 'Read');
            SC_Jarvis_utility.getCaseSharesJarvis(new Set<String>{newCasetech.id});

        Test.stopTest();
    }
    @isTest static void testMethod15()
    {
        Test.startTest();
            System.runAs(adminUser)
            {
                newCasetech.jarvis_also_notify__c = 'shprasan@akamai.com';
                insert newCasetech;    
            }


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


            SC_Jarvis_utility.getComments(new Set<String>{newCasetech.id});
            SC_Jarvis_utility.getCommentDetails(newCasetech.id, 'JARVIS', 'Case', 'Public');

            Group reg = new group();
            reg.Name = 'JARVIS_PD';
            reg.Type = 'Regular';
            insert reg;

            SC_Jarvis_utility.createCommentShare(comment.id,reg.Id);
            SC_Jarvis_utility.getCommentSharesJarvis(new Set<String>{newCasetech.id},new Set<String>{comment.id});


        Test.stopTest();
    }

    @isTest static void testMethod16()
    {
        Test.startTest();
            system.runAs(adminUser)
            {
                customerUser = SC_Jarvis_CoreSecurityController.createNewCustomerUser (conRec,SC_Jarvis_CoreSecurityController.getLoggedInUser() , profileId);
                customerUser.contactId = conRec.Id;
                insert customerUser;
            }

            Knowledge__kav htKAV = new Knowledge__kav(Title='Random Unique Title12121',Summary='How To summary',UrlName='RandomUniqueTitle12121');
            insert htKAV;
            List<KnowledgeArticleVersion> kaVersionList = [Select Id,KnowledgeArticleId,Title,ArticleNumber,OwnerId,VersionNumber from KnowledgeArticleVersion where Language='en_US' AND PublishStatus = 'Draft'];
            KbManagement.PublishingService.publishArticle(kaVersionList.get(0).KnowledgeArticleId,true);

            SC_Jarvis_utility.getArticle(htKAV.Id);
            SC_Jarvis_utility.getVoteRec(htKAV.Id,customerUser.id);
        Test.stopTest();
    }

    @isTest static void testMethod17()
    {
        Test.startTest();
            newCasetech.jarvis_also_notify__c = 'shprasan@akamai.com';
            newCasetech.contactId = conRec.Id;
            insert newCasetech;    
            system.runAs(adminUser)
            {
                customerUser = SC_Jarvis_CoreSecurityController.createNewCustomerUser (conRec,SC_Jarvis_CoreSecurityController.getLoggedInUser() , profileId);
                customerUser.contactId = conRec.Id;
                insert customerUser;
            }

            SC_Jarvis_utility.getUserEditAccess(customerUser.id,newCasetech.Id);
            SC_Jarvis_utility.sendEmailtoAlsoNotify(new List<Id>{newCasetech.id});
        Test.stopTest();
    }

    @isTest static void testMethod18()
    {
        Test.startTest();
            insert pdRec;
            insert acRec;

            system.runAs(adminUser)
            {
                customerUser = SC_Jarvis_CoreSecurityController.createNewCustomerUser (conRec,SC_Jarvis_CoreSecurityController.getLoggedInUser() , profileId);
                customerUser.contactId = conRec.Id;
                insert customerUser;
            }

            List<SC_Jarvis_Contact_ACC_Permission_Handler.AccountContactPermissionWrapper> wrappers = new
            List<SC_Jarvis_Contact_ACC_Permission_Handler.AccountContactPermissionWrapper>();

            SC_Jarvis_Contact_ACC_Permission_Handler.AccountContactPermissionWrapper accountWrapper= new 
            SC_Jarvis_Contact_ACC_Permission_Handler.AccountContactPermissionWrapper();

            SC_Jarvis_Contact_ACC_Permission_Handler.ContractPermissionWrapper contractWrapper= new 
            SC_Jarvis_Contact_ACC_Permission_Handler.ContractPermissionWrapper();
        
            contractWrapper.contractId = '123';
            contractWrapper.scopes = new String[] {'CASE_MANAGEMENT_WRITE', 'CASE_MANAGEMENT_PS_ACCESS'};

            accountWrapper.accountId = 'Test-ABC-123Jarvis';
            accountWrapper.authGrants = new SC_Jarvis_Contact_ACC_Permission_Handler.ContractPermissionWrapper[]{contractWrapper};

            wrappers.add(accountWrapper);

            insert contract;

            permissionRec= new Jarvis_Contact_ACC_Permission__c();
            permissionRec.contact__c = conRec.Id;
            permissionRec.Active__c = true; 
            permissionRec.User__c = customerUser.id;           
            permissionRec.Akam_Contact_ACC_Permission_Id__c = conRec.Akam_Contact_Id__c;            
            permissionRec.Response__c =  JSON.serialize(wrappers);                      
            insert permissionRec;    
                        
            system.runAs(customerUser)
            {
                SC_Jarvis_utility.getCategoriesAccounts(conRec.id, new List<String>{accRec.Id});
            }
            
        Test.stopTest();
    }
    @isTest static void testMethod19()
    {
        Test.startTest();
            insert pdRec;
            insert acRec;

            system.runAs(adminUser)
            {
                customerUser = SC_Jarvis_CoreSecurityController.createNewCustomerUser (conRec,SC_Jarvis_CoreSecurityController.getLoggedInUser() , profileId);
                customerUser.contactId = conRec.Id;
                insert customerUser;
            }

            List<SC_Jarvis_Contact_ACC_Permission_Handler.AccountContactPermissionWrapper> wrappers = new
            List<SC_Jarvis_Contact_ACC_Permission_Handler.AccountContactPermissionWrapper>();

            SC_Jarvis_Contact_ACC_Permission_Handler.AccountContactPermissionWrapper accountWrapper= new 
            SC_Jarvis_Contact_ACC_Permission_Handler.AccountContactPermissionWrapper();

            SC_Jarvis_Contact_ACC_Permission_Handler.ContractPermissionWrapper contractWrapper= new 
            SC_Jarvis_Contact_ACC_Permission_Handler.ContractPermissionWrapper();
        
            contractWrapper.contractId = '123';
            contractWrapper.scopes = new String[] {'CASE_MANAGEMENT_WRITE', 'CASE_MANAGEMENT_PS_ACCESS'};

            accountWrapper.accountId = 'Test-ABC-123Jarvis';
            accountWrapper.authGrants = new SC_Jarvis_Contact_ACC_Permission_Handler.ContractPermissionWrapper[]{contractWrapper};

            wrappers.add(accountWrapper);

            insert contract;

            permissionRec= new Jarvis_Contact_ACC_Permission__c();
            permissionRec.contact__c = conRec.Id;
            permissionRec.Active__c = true; 
            permissionRec.User__c = customerUser.id;           
            permissionRec.Akam_Contact_ACC_Permission_Id__c = conRec.Akam_Contact_Id__c;            
            permissionRec.Response__c =  JSON.serialize(wrappers);                      
            insert permissionRec;    
            
            system.runAs(customerUser)
            {
                SC_Jarvis_utility.hasCreateAccess(conRec.id);
            }
            
        Test.stopTest();
    }

    @isTest static void testMethod20()
    {
        Test.startTest();

                system.runAs(adminUser)
                {
                    customerUser = SC_Jarvis_CoreSecurityController.createNewCustomerUser (conRec,SC_Jarvis_CoreSecurityController.getLoggedInUser() , profileId);
                    customerUser.contactId = conRec.Id;
                    insert customerUser;
                }

                insert pdRec;                

                Map<String,String> param = new Map<String,String>();
                param.put('accountId',accRec.Id);
                param.put('policyDomainId',pdRec.Id);
                system.runAs(customerUser)
                {
                    SC_Jarvis_Create_Case_Controller.getProducts(JSON.serialize(param));
                }
                

            
            Test.stopTest();
    }

    @isTest static void testMethod21()
    {
        Test.startTest();

                system.runAs(adminUser)
                {
                    customerUser = SC_Jarvis_CoreSecurityController.createNewCustomerUser (conRec,SC_Jarvis_CoreSecurityController.getLoggedInUser() , profileId);
                    customerUser.contactId = conRec.Id;
                    insert customerUser;
                }

                system.runAs(adminUser)
                {
                    List<SC_Jarvis_Contact_ACC_Permission_Handler.AccountContactPermissionWrapper> wrappers = new
                    List<SC_Jarvis_Contact_ACC_Permission_Handler.AccountContactPermissionWrapper>();
        
                    SC_Jarvis_Contact_ACC_Permission_Handler.AccountContactPermissionWrapper accountWrapper= new 
                    SC_Jarvis_Contact_ACC_Permission_Handler.AccountContactPermissionWrapper();
        
                    SC_Jarvis_Contact_ACC_Permission_Handler.ContractPermissionWrapper contractWrapper= new 
                    SC_Jarvis_Contact_ACC_Permission_Handler.ContractPermissionWrapper();
                
                    contractWrapper.contractId = '123';
                    contractWrapper.scopes = new String[] {'CASE_MANAGEMENT_WRITE', 'CASE_MANAGEMENT_PS_ACCESS'};
        
                    accountWrapper.accountId = 'Test-ABC-123Jarvis';
                    accountWrapper.authGrants = new SC_Jarvis_Contact_ACC_Permission_Handler.ContractPermissionWrapper[]{contractWrapper};
        
                    wrappers.add(accountWrapper);
        
                    insert contract;
        
                    permissionRec= new Jarvis_Contact_ACC_Permission__c();
                    permissionRec.contact__c = conRec.Id;
                    permissionRec.Active__c = true; 
                    permissionRec.User__c = customerUser.id;           
                    permissionRec.Akam_Contact_ACC_Permission_Id__c = conRec.Akam_Contact_Id__c;            
                    permissionRec.Response__c =  JSON.serialize(wrappers);                      
                    insert permissionRec;    
    
                }
            
                contDetailCommitted.original_contract_id__c = contract.Id;
                insert contDetailCommitted;
                
                insert mapping1;
                insert lovRec;
                
                Map<String,String> param = new Map<String,String>();
                param.put('accountId',accRec.Id);
                param.put('category','Technical');

                system.runAs(customerUser)
                {
                    SC_Jarvis_Create_Case_Controller.getProducts(JSON.serialize(param));
                }
            Test.stopTest();
    }
    @isTest static void testMethod22()
    {
        Test.startTest();

                insert lovRec;                
                Map<String,String> param = new Map<String,String>();

                param.put('accountId',accRec.Id);
                param.put('category','Technical');
                param.put('product','product1');

                SC_Jarvis_Create_Case_Controller.getProblem(JSON.serialize(param));            
            Test.stopTest();
    }
    @isTest static void testMethod23()
    {
        ContentVersion conVer = L2Q_ContentDocumentUtilClass.setContentVersion('S', 'Name', 'Name', 'Test Data');
        insert conVer;

       	ContentVersion conVerdata = [Select Id, ContentDocumentId From ContentVersion Where Id = :conVer.Id];
        
        String filesToAttach = '["'+conVerdata.ContentDocumentId+'"]';

        Test.startTest();


                Map<String,String> caseMap = new Map<String,String>();
                caseMap.put('Case_Product__c','product1');
                caseMap.put('RecordType','Technical');
                caseMap.put('Severity__c','3');
                caseMap.put('Subject','product1');
                caseMap.put('Description','product1');
                caseMap.put('AccountId',accRec.Id);
            
                SC_Jarvis_Create_Case_Controller.createCase(JSON.serialize(caseMap), filesToAttach);    
            
            Test.stopTest();
    }

    @isTest static void testMethod24()
    {
        Test.startTest();

                system.runAs(adminUser)
                {
                    customerUser = SC_Jarvis_CoreSecurityController.createNewCustomerUser (conRec,SC_Jarvis_CoreSecurityController.getLoggedInUser() , profileId);
                    customerUser.contactId = conRec.Id;
                    insert customerUser;
                }

                system.runAs(adminUser)
                {
                    newCasetech.jarvis_also_notify__c = 'shprasan@akamai.com';
                    insert newCasetech;    
    
                    List<SC_Jarvis_Contact_ACC_Permission_Handler.AccountContactPermissionWrapper> wrappers = new
                    List<SC_Jarvis_Contact_ACC_Permission_Handler.AccountContactPermissionWrapper>();
        
                    SC_Jarvis_Contact_ACC_Permission_Handler.AccountContactPermissionWrapper accountWrapper= new 
                    SC_Jarvis_Contact_ACC_Permission_Handler.AccountContactPermissionWrapper();
        
                    SC_Jarvis_Contact_ACC_Permission_Handler.ContractPermissionWrapper contractWrapper= new 
                    SC_Jarvis_Contact_ACC_Permission_Handler.ContractPermissionWrapper();
                
                    contractWrapper.contractId = '123';
                    contractWrapper.scopes = new String[] {'CASE_MANAGEMENT_WRITE', 'CASE_MANAGEMENT_PS_ACCESS'};
        
                    accountWrapper.accountId = 'Test-ABC-123Jarvis';
                    accountWrapper.authGrants = new SC_Jarvis_Contact_ACC_Permission_Handler.ContractPermissionWrapper[]{contractWrapper};
        
                    wrappers.add(accountWrapper);
        
                    insert contract;
        
                    permissionRec= new Jarvis_Contact_ACC_Permission__c();
                    permissionRec.contact__c = conRec.Id;
                    permissionRec.Active__c = true; 
                    permissionRec.User__c = customerUser.id;           
                    permissionRec.Akam_Contact_ACC_Permission_Id__c = conRec.Akam_Contact_Id__c;            
                    permissionRec.Response__c =  JSON.serialize(wrappers);                      
                    insert permissionRec;    
    
                }
            
                contDetailCommitted.original_contract_id__c = contract.Id;
                insert contDetailCommitted;
                
                insert mapping1;
                insert lovRec;

                system.runAs(adminUser)
                {
                    Knowledge__kav htKAV = new Knowledge__kav(Title='Random Unique Title12121',Summary='How To summary',UrlName='RandomUniqueTitle12121');
                    insert htKAV;
                    List<KnowledgeArticleVersion> kaVersionList = [Select Id,KnowledgeArticleId,Title,ArticleNumber,OwnerId,VersionNumber from KnowledgeArticleVersion where Language='en_US' AND PublishStatus = 'Draft'];
                    
                    KbManagement.PublishingService.publishArticle(kaVersionList.get(0).KnowledgeArticleId,true);        

                }

                system.runAs(customerUser)
                {
                    try
                    {
                        SC_Jarvis_Create_Case_Controller.cloneSetup(newCasetech.id);
                    }
                    catch(exception e)
                    {

                    }
                    
                }
                

            Test.stopTest();
    }


    @isTest static void testMethod25()
    {
        Test.startTest();

                System.runAs(adminUser)
                {
                    newCasetech.jarvis_also_notify__c = 'shprasan@akamai.com';
                    insert newCasetech;    
                }

                map<string, string> labelvalues = new map<string, string> ();
                labelvalues.put('Severity__c','Severity');
                SC_Jarvis_Create_Case_Controller.getLabelDetails(labelvalues, newCasetech.Id, 'Technical', false,'Carrier');
                SC_Jarvis_Create_Case_Controller.getLabelDetails(labelvalues, newCasetech.Id, 'Technical', true,'CMP Alerts');
            Test.stopTest();
    }

    @isTest static void testMethod26()
    {
        ContentVersion conVer = L2Q_ContentDocumentUtilClass.setContentVersion('S', 'Name', 'Name', 'Test Data');
        insert conVer;
		ContentVersion conVerdata = [Select Id, ContentDocumentId From ContentVersion Where Id = :conVer.Id];
        
        String filesToAttach = '["'+conVerdata.ContentDocumentId+'"]';
        

        Test.startTest();

                System.runAs(adminUser)
                {
                    newCasetech.jarvis_also_notify__c = 'shprasan@akamai.com';
                    insert newCasetech;    
                }
        		
        		
                SC_Jarvis_Create_Case_Controller.alsoNotifyCheck('test222@test.com',accRec.id,null,JSON.serialize(newCasetech), null, filesToAttach);
        		SC_Jarvis_Create_Case_Controller.alsoNotifyCheck(null,accRec.id,null,null,JSON.serialize(newCasetech), filesToAttach);
            Test.stopTest();
    }

    @isTest static void testMethod27()
    {
        Test.startTest();

                System.runAs(adminUser)
                {
                    newCasetech.jarvis_also_notify__c = 'shprasan@akamai.com';
                    insert newCasetech;    
                }

                Map<String,String> caseMap = new Map<String,String>();
                caseMap.put('Case_Product__c','product1');
                caseMap.put('Severity__c','3');
                caseMap.put('Subject','product1');
                caseMap.put('Description','product1');
                caseMap.put('Id',newCasetech.Id);

                SC_Jarvis_Create_Case_Controller.updateCaseRecord(JSON.serialize(caseMap));
            Test.stopTest();
    }

    @isTest static void testMethod28()
    {
        Test.startTest();
            system.runAs(adminUser)
            {
                customerUser = SC_Jarvis_CoreSecurityController.createNewCustomerUser (conRec,SC_Jarvis_CoreSecurityController.getLoggedInUser() , profileId);
                customerUser.contactId = conRec.Id;
                insert customerUser;
            }

            permissionRec= new Jarvis_Contact_ACC_Permission__c();
            permissionRec.contact__c = conRec.Id;
            permissionRec.Active__c = true; 
            permissionRec.User__c = customerUser.id;           
            permissionRec.Akam_Contact_ACC_Permission_Id__c = conRec.Akam_Contact_Id__c;            

            insert permissionRec;    

            system.runAs(customerUser)
            {
                SC_Jarvis_utility.getExistingUserCustz(customerUser.id); 
                SC_Jarvis_utility.saveUserCustomizations(new List<Id>{accRec.Id}, 2, 'myActiveCases');    
            }
        Test.stopTest();
    }
    @isTest static void testMethod29()
    {
        Test.startTest();
            insert contract;

            contDetailCommitted.Original_Contract_id__c = contract.Id;
            insert contDetailCommitted;
            
            SC_Jarvis_utility.getContractDetails(null, new Set<String> {'M-LC-160618'},new Set<String> {accRec.Id}, 1);
        Test.stopTest();
    }

    @isTest static void testMethod30()
    {
        Test.startTest();


                Map<String,String> caseMap = new Map<String,String>();
                caseMap.put('Case_Product__c','product1');
                caseMap.put('RecordType','Professional Services');
                caseMap.put('Severity__c','3');
                caseMap.put('Subject','product1');
                caseMap.put('Description','product1');
                caseMap.put('AccountId',accRec.Id);
            
                SC_Jarvis_Create_Case_Controller.createCase(JSON.serialize(caseMap), '[]');    
            
            Test.stopTest();
    }

    @isTest static void testMethod31()
    {
        Test.startTest();

                system.runAs(adminUser)
                {
                    customerUser = SC_Jarvis_CoreSecurityController.createNewCustomerUser (conRec,SC_Jarvis_CoreSecurityController.getLoggedInUser() , profileId);
                    customerUser.contactId = conRec.Id;
                    insert customerUser;
                }

                system.runAs(adminUser)
                {
                    newCasetech.jarvis_also_notify__c = 'shprasan@akamai.com';
                    newCasetech.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();                    
                    insert newCasetech;    
    
                    List<SC_Jarvis_Contact_ACC_Permission_Handler.AccountContactPermissionWrapper> wrappers = new
                    List<SC_Jarvis_Contact_ACC_Permission_Handler.AccountContactPermissionWrapper>();
        
                    SC_Jarvis_Contact_ACC_Permission_Handler.AccountContactPermissionWrapper accountWrapper= new 
                    SC_Jarvis_Contact_ACC_Permission_Handler.AccountContactPermissionWrapper();
        
                    SC_Jarvis_Contact_ACC_Permission_Handler.ContractPermissionWrapper contractWrapper= new 
                    SC_Jarvis_Contact_ACC_Permission_Handler.ContractPermissionWrapper();
                
                    contractWrapper.contractId = '123';
                    contractWrapper.scopes = new String[] {'CASE_MANAGEMENT_WRITE', 'CASE_MANAGEMENT_PS_ACCESS'};
        
                    accountWrapper.accountId = 'Test-ABC-123Jarvis';
                    accountWrapper.authGrants = new SC_Jarvis_Contact_ACC_Permission_Handler.ContractPermissionWrapper[]{contractWrapper};
        
                    wrappers.add(accountWrapper);
        
                    insert contract;
        
                    permissionRec= new Jarvis_Contact_ACC_Permission__c();
                    permissionRec.contact__c = conRec.Id;
                    permissionRec.Active__c = true; 
                    permissionRec.User__c = customerUser.id;           
                    permissionRec.Akam_Contact_ACC_Permission_Id__c = conRec.Akam_Contact_Id__c;            
                    permissionRec.Response__c =  JSON.serialize(wrappers);                      
                    insert permissionRec;    
    
                }
            
                contDetailCommitted.original_contract_id__c = contract.Id;
                insert contDetailCommitted;
                
                insert mapping1;
                insert lovRec;

                system.runAs(adminUser)
                {
                    Knowledge__kav htKAV = new Knowledge__kav(Title='Random Unique Title12121',Summary='How To summary',UrlName='RandomUniqueTitle12121');
                    insert htKAV;
                    List<KnowledgeArticleVersion> kaVersionList = [Select Id,KnowledgeArticleId,Title,ArticleNumber,OwnerId,VersionNumber from KnowledgeArticleVersion where Language='en_US' AND PublishStatus = 'Draft'];
                    
                    KbManagement.PublishingService.publishArticle(kaVersionList.get(0).KnowledgeArticleId,true);        

                }
                system.runAs(customerUser)
                {
                    try
                    {
                        SC_Jarvis_Create_Case_Controller.cloneSetup(newCasetech.id);
                    }
                    catch(exception e)
                    {

                    }
                    
                }
                

            Test.stopTest();
    }

    @isTest static void testMethod32()
    {
        Test.startTest();

                system.runAs(adminUser)
                {
                    customerUser = SC_Jarvis_CoreSecurityController.createNewCustomerUser (conRec,SC_Jarvis_CoreSecurityController.getLoggedInUser() , profileId);
                    customerUser.contactId = conRec.Id;
                    insert customerUser;
                }

                system.runAs(adminUser)
                {
                    List<SC_Jarvis_Contact_ACC_Permission_Handler.AccountContactPermissionWrapper> wrappers = new
                    List<SC_Jarvis_Contact_ACC_Permission_Handler.AccountContactPermissionWrapper>();
        
                    SC_Jarvis_Contact_ACC_Permission_Handler.AccountContactPermissionWrapper accountWrapper= new 
                    SC_Jarvis_Contact_ACC_Permission_Handler.AccountContactPermissionWrapper();
        
                    SC_Jarvis_Contact_ACC_Permission_Handler.ContractPermissionWrapper contractWrapper= new 
                    SC_Jarvis_Contact_ACC_Permission_Handler.ContractPermissionWrapper();
                
                    contractWrapper.contractId = '123';
                    contractWrapper.scopes = new String[] {'CASE_MANAGEMENT_WRITE', 'CASE_MANAGEMENT_PS_ACCESS'};
        
                    accountWrapper.accountId = 'Test-ABC-123Jarvis';
                    accountWrapper.authGrants = new SC_Jarvis_Contact_ACC_Permission_Handler.ContractPermissionWrapper[]{contractWrapper};
        
                    wrappers.add(accountWrapper);
        
                    insert contract;
        
                    permissionRec= new Jarvis_Contact_ACC_Permission__c();
                    permissionRec.contact__c = conRec.Id;
                    permissionRec.Active__c = true; 
                    permissionRec.User__c = customerUser.id;           
                    permissionRec.Akam_Contact_ACC_Permission_Id__c = conRec.Akam_Contact_Id__c;            
                    permissionRec.Response__c =  JSON.serialize(wrappers);                      
                    insert permissionRec;    
    
                }
            
                contDetailCommitted.original_contract_id__c = contract.Id;
                insert contDetailCommitted;
                
                insert mapping1;
                insert lovRec;
                
                Map<String,String> param = new Map<String,String>();
                param.put('accountId',accRec.Id);
                param.put('category','PS');

                system.runAs(customerUser)
                {
                    SC_Jarvis_Create_Case_Controller.getProducts(JSON.serialize(param));
                }
            Test.stopTest();
    }

    @isTest static void testMethod33()
    {
        Test.startTest();

                system.runAs(adminUser)
                {
                    customerUser = SC_Jarvis_CoreSecurityController.createNewCustomerUser (conRec,SC_Jarvis_CoreSecurityController.getLoggedInUser() , profileId);
                    customerUser.contactId = conRec.Id;
                    insert customerUser;
                }

                system.runAs(adminUser)
                {
                    newCasetech.jarvis_also_notify__c = 'shprasan@akamai.com';
                    newCasetech.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Managed Security').getRecordTypeId();                    
                    insert newCasetech;    
    
                    List<SC_Jarvis_Contact_ACC_Permission_Handler.AccountContactPermissionWrapper> wrappers = new
                    List<SC_Jarvis_Contact_ACC_Permission_Handler.AccountContactPermissionWrapper>();
        
                    SC_Jarvis_Contact_ACC_Permission_Handler.AccountContactPermissionWrapper accountWrapper= new 
                    SC_Jarvis_Contact_ACC_Permission_Handler.AccountContactPermissionWrapper();
        
                    SC_Jarvis_Contact_ACC_Permission_Handler.ContractPermissionWrapper contractWrapper= new 
                    SC_Jarvis_Contact_ACC_Permission_Handler.ContractPermissionWrapper();
                
                    contractWrapper.contractId = '123';
                    contractWrapper.scopes = new String[] {'CASE_MANAGEMENT_WRITE', 'CASE_MANAGEMENT_PS_ACCESS'};
        
                    accountWrapper.accountId = 'Test-ABC-123Jarvis';
                    accountWrapper.authGrants = new SC_Jarvis_Contact_ACC_Permission_Handler.ContractPermissionWrapper[]{contractWrapper};
        
                    wrappers.add(accountWrapper);
        
                    insert contract;
        
                    permissionRec= new Jarvis_Contact_ACC_Permission__c();
                    permissionRec.contact__c = conRec.Id;
                    permissionRec.Active__c = true; 
                    permissionRec.User__c = customerUser.id;           
                    permissionRec.Akam_Contact_ACC_Permission_Id__c = conRec.Akam_Contact_Id__c;            
                    permissionRec.Response__c =  JSON.serialize(wrappers);                      
                    insert permissionRec;    
    
                }
            

                system.runAs(adminUser)
                {
                    Knowledge__kav htKAV = new Knowledge__kav(Title='Random Unique Title12121',Summary='How To summary',UrlName='RandomUniqueTitle12121');
                    insert htKAV;
                    List<KnowledgeArticleVersion> kaVersionList = [Select Id,KnowledgeArticleId,Title,ArticleNumber,OwnerId,VersionNumber from KnowledgeArticleVersion where Language='en_US' AND PublishStatus = 'Draft'];
                    
                    KbManagement.PublishingService.publishArticle(kaVersionList.get(0).KnowledgeArticleId,true);        

                }
                system.runAs(customerUser)
                {
                    try
                    {
                        SC_Jarvis_Create_Case_Controller.cloneSetup(newCasetech.id);
                    }
                    catch(exception e)
                    {

                    }
                    
                }
                

            Test.stopTest();
    }

    @isTest static void testMethod34()
    {
        insert caseProd;
        Test.startTest();

                system.runAs(adminUser)
                {
                    customerUser = SC_Jarvis_CoreSecurityController.createNewCustomerUser (conRec,SC_Jarvis_CoreSecurityController.getLoggedInUser() , profileId);
                    customerUser.contactId = conRec.Id;
                    insert customerUser;
                }

                system.runAs(adminUser)
                {
                    newCasetech.jarvis_also_notify__c = 'shprasan@akamai.com';
                    newCasetech.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Billing').getRecordTypeId();                    
                    newCasetech.Case_Product__c = caseProd.Id;
                    insert newCasetech;    
    
                    List<SC_Jarvis_Contact_ACC_Permission_Handler.AccountContactPermissionWrapper> wrappers = new
                    List<SC_Jarvis_Contact_ACC_Permission_Handler.AccountContactPermissionWrapper>();
        
                    SC_Jarvis_Contact_ACC_Permission_Handler.AccountContactPermissionWrapper accountWrapper= new 
                    SC_Jarvis_Contact_ACC_Permission_Handler.AccountContactPermissionWrapper();
        
                    SC_Jarvis_Contact_ACC_Permission_Handler.ContractPermissionWrapper contractWrapper= new 
                    SC_Jarvis_Contact_ACC_Permission_Handler.ContractPermissionWrapper();
                
                    contractWrapper.contractId = '123';
                    contractWrapper.scopes = new String[] {'CASE_MANAGEMENT_WRITE', 'CASE_MANAGEMENT_PS_ACCESS'};
        
                    accountWrapper.accountId = 'Test-ABC-123Jarvis';
                    accountWrapper.authGrants = new SC_Jarvis_Contact_ACC_Permission_Handler.ContractPermissionWrapper[]{contractWrapper};
        
                    wrappers.add(accountWrapper);
        
                    insert contract;
        
                    permissionRec= new Jarvis_Contact_ACC_Permission__c();
                    permissionRec.contact__c = conRec.Id;
                    permissionRec.Active__c = true; 
                    permissionRec.User__c = customerUser.id;           
                    permissionRec.Akam_Contact_ACC_Permission_Id__c = conRec.Akam_Contact_Id__c;            
                    permissionRec.Response__c =  JSON.serialize(wrappers);                      
                    insert permissionRec;    
    
                }
            
                system.runAs(adminUser)
                {
                    Knowledge__kav htKAV = new Knowledge__kav(Title='Random Unique Title12121',Summary='How To summary',UrlName='RandomUniqueTitle12121');
                    insert htKAV;
                    List<KnowledgeArticleVersion> kaVersionList = [Select Id,KnowledgeArticleId,Title,ArticleNumber,OwnerId,VersionNumber from KnowledgeArticleVersion where Language='en_US' AND PublishStatus = 'Draft'];
                    
                    KbManagement.PublishingService.publishArticle(kaVersionList.get(0).KnowledgeArticleId,true);        

                }
                system.runAs(customerUser)
                {
                    try
                    {
                        SC_Jarvis_Create_Case_Controller.cloneSetup(newCasetech.id);
                    }
                    catch(exception e)
                    {

                    }
                    
                }
                

            Test.stopTest();
    }

    @isTest static void testMethod35()
    {
        insert caseProd;
        Test.startTest();

                
                system.runAs(adminUser)
                {
                    customerUser = SC_Jarvis_CoreSecurityController.createNewCustomerUser (conRec,SC_Jarvis_CoreSecurityController.getLoggedInUser() , profileId);
                    customerUser.contactId = conRec.Id;
                    insert customerUser;
                }

                system.runAs(adminUser)
                {
                    newCasetech.jarvis_also_notify__c = 'shprasan@akamai.com';
                    newCasetech.Case_Product__c = caseProd.Id;
                    newCasetech.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('AMG').getRecordTypeId();                    
                    insert newCasetech;    
    
                    List<SC_Jarvis_Contact_ACC_Permission_Handler.AccountContactPermissionWrapper> wrappers = new
                    List<SC_Jarvis_Contact_ACC_Permission_Handler.AccountContactPermissionWrapper>();
        
                    SC_Jarvis_Contact_ACC_Permission_Handler.AccountContactPermissionWrapper accountWrapper= new 
                    SC_Jarvis_Contact_ACC_Permission_Handler.AccountContactPermissionWrapper();
        
                    SC_Jarvis_Contact_ACC_Permission_Handler.ContractPermissionWrapper contractWrapper= new 
                    SC_Jarvis_Contact_ACC_Permission_Handler.ContractPermissionWrapper();
                
                    contractWrapper.contractId = '123';
                    contractWrapper.scopes = new String[] {'CASE_MANAGEMENT_WRITE', 'CASE_MANAGEMENT_PS_ACCESS'};
        
                    accountWrapper.accountId = 'Test-ABC-123Jarvis';
                    accountWrapper.authGrants = new SC_Jarvis_Contact_ACC_Permission_Handler.ContractPermissionWrapper[]{contractWrapper};
        
                    wrappers.add(accountWrapper);
        
                    insert contract;
        
                    permissionRec= new Jarvis_Contact_ACC_Permission__c();
                    permissionRec.contact__c = conRec.Id;
                    permissionRec.Active__c = true; 
                    permissionRec.User__c = customerUser.id;           
                    permissionRec.Akam_Contact_ACC_Permission_Id__c = conRec.Akam_Contact_Id__c;            
                    permissionRec.Response__c =  JSON.serialize(wrappers);                      
                    insert permissionRec;    
    
                }
            
                system.runAs(adminUser)
                {
                    Knowledge__kav htKAV = new Knowledge__kav(Title='Random Unique Title12121',Summary='How To summary',UrlName='RandomUniqueTitle12121');
                    insert htKAV;
                    List<KnowledgeArticleVersion> kaVersionList = [Select Id,KnowledgeArticleId,Title,ArticleNumber,OwnerId,VersionNumber from KnowledgeArticleVersion where Language='en_US' AND PublishStatus = 'Draft'];
                    
                    KbManagement.PublishingService.publishArticle(kaVersionList.get(0).KnowledgeArticleId,true);        

                }
                system.runAs(customerUser)
                {
                    try
                    {
                        SC_Jarvis_Create_Case_Controller.cloneSetup(newCasetech.id);
                    }
                    catch(exception e)
                    {

                    }
                    
                }
                

            Test.stopTest();
    }

    @isTest static void testMethod36()
    {
        insert caseProd;
        Test.startTest();

                system.runAs(adminUser)
                {
                    customerUser = SC_Jarvis_CoreSecurityController.createNewCustomerUser (conRec,SC_Jarvis_CoreSecurityController.getLoggedInUser() , profileId);
                    customerUser.contactId = conRec.Id;
                    insert customerUser;
                }

                system.runAs(adminUser)
                {
                    newCasetech.jarvis_also_notify__c = 'shprasan@akamai.com';
                    newCasetech.Case_Product__c = caseProd.Id;
                    newCaseTech.recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Emerging Products Engineering').getRecordTypeId();                    
                    insert newCasetech;    
    
                    List<SC_Jarvis_Contact_ACC_Permission_Handler.AccountContactPermissionWrapper> wrappers = new
                    List<SC_Jarvis_Contact_ACC_Permission_Handler.AccountContactPermissionWrapper>();
        
                    SC_Jarvis_Contact_ACC_Permission_Handler.AccountContactPermissionWrapper accountWrapper= new 
                    SC_Jarvis_Contact_ACC_Permission_Handler.AccountContactPermissionWrapper();
        
                    SC_Jarvis_Contact_ACC_Permission_Handler.ContractPermissionWrapper contractWrapper= new 
                    SC_Jarvis_Contact_ACC_Permission_Handler.ContractPermissionWrapper();
                
                    contractWrapper.contractId = '123';
                    contractWrapper.scopes = new String[] {'CASE_MANAGEMENT_WRITE', 'CASE_MANAGEMENT_PS_ACCESS'};
        
                    accountWrapper.accountId = 'Test-ABC-123Jarvis';
                    accountWrapper.authGrants = new SC_Jarvis_Contact_ACC_Permission_Handler.ContractPermissionWrapper[]{contractWrapper};
        
                    wrappers.add(accountWrapper);
        
                    insert contract;
        
                    permissionRec= new Jarvis_Contact_ACC_Permission__c();
                    permissionRec.contact__c = conRec.Id;
                    permissionRec.Active__c = true; 
                    permissionRec.User__c = customerUser.id;           
                    permissionRec.Akam_Contact_ACC_Permission_Id__c = conRec.Akam_Contact_Id__c;            
                    permissionRec.Response__c =  JSON.serialize(wrappers);                      
                    insert permissionRec;    
    
                }
            
                contDetailCommitted.original_contract_id__c = contract.Id;
                insert contDetailCommitted;
                
                insert mapping1;
                insert lovRec;

                system.runAs(adminUser)
                {
                    Knowledge__kav htKAV = new Knowledge__kav(Title='Random Unique Title12121',Summary='How To summary',UrlName='RandomUniqueTitle12121');
                    insert htKAV;
                    List<KnowledgeArticleVersion> kaVersionList = [Select Id,KnowledgeArticleId,Title,ArticleNumber,OwnerId,VersionNumber from KnowledgeArticleVersion where Language='en_US' AND PublishStatus = 'Draft'];
                    
                    KbManagement.PublishingService.publishArticle(kaVersionList.get(0).KnowledgeArticleId,true);        

                }

                system.runAs(customerUser)
                {
                    try
                    {
                        SC_Jarvis_Create_Case_Controller.cloneSetup(newCasetech.id);
                    }
                    catch(exception e)
                    {

                    }
                    
                }
                

            Test.stopTest();
    }


    @isTest static void testMethod37()
    {
        insert caseProd;
        Test.startTest();


                system.runAs(adminUser)
                {
                    newCasetech.jarvis_also_notify__c = 'shprasan@akamai.com';
                    newCasetech.Case_Product__c = caseProd.Id;
                    newCaseTech.recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Emerging Products Engineering').getRecordTypeId();                    
                    insert newCasetech;    
                    
                    try
                    {
                        SC_Jarvis_Create_Case_Controller.mitigateCase(newCasetech.id);
                    }
                    catch(Exception e)
                    {

                    }
                }
            Test.stopTest();
    }

    @isTest static void testMethod38()
    {
        insert caseProd;
        insert cp;
        insert mapping1;
        Test.startTest();


                system.runAs(adminUser)
                {
                    newCasetech.jarvis_also_notify__c = 'shprasan@akamai.com';
                    newCasetech.Case_Product__c = caseProd.Id;
                    newCaseTech.recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();                    
                    insert newCasetech;    
                    
                    try
                    {
                        SC_CaseTriggerHelperClass3.updateBusinessHours = false;    
                        SC_CaseTriggerHelperClass3.updateBusinessHoursCases(new List<Id>{newCasetech.Id});
                    }
                    catch(Exception e)
                    {

                    }
                }
            Test.stopTest();
    }
    
}