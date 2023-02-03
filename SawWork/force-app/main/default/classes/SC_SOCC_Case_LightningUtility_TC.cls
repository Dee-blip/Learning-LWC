/*=====================================================================================================+
Class name          :   SC_SOCC_Case_LightningUtility_TC 
Author              :   Sheena Bhan
Created             :   06-Sept-19
Purpose             :   Test class for SC_SOCC_Case_LightningUtility

Last Modified 		Developer     		Purpose            
============= 	==================     ==========
06-Sept-19     		Sheena Bhan 	   ESESP-2198
03-March-20     	Sumukh SS	 	   ESESP-2944
03-May-20			Sumukh SS		   ESESP-3434 - Full Test class re-write
26-May-20           Pinkesh            ESESP-3501
30-Mar-21			Tejaswini          ESESP-5109 - To increase coverage
30-Nov-21           Jay                ESESP-6330 - Updated saveSelectedFilters signature change compatibility
29-Apr-22           Tejaswini          ESESP-6444
+=====================================================================================================*/

@isTest
private class SC_SOCC_Case_LightningUtility_TC {
    
    // Setup method to create test data.
    @testSetup
    static void setupMethod()
    {
        utilTestClass.createCustomSettings();
        User getUserInfo = [select id,name from user where id =: UserInfo.getUserId() limit 1];
        
        // Creating Account
        Account accRec = new Account(Name='Test Account IP Address',AKAM_Account_ID__c='Test-ABC-1234IPAddr',Type='Brand - Active', Is_SOCC_Premium_Customer__c = True, Parent_Division__c = 'Web Americas_Web', Division__c = 'Acquisition & ECG');
        insert accRec;  
        
        // Creating Account Team
        List<AccountTeamMember> accTeamInsert = new List<AccountTeamMember>();
        accTeamInsert.add(new AccountTeamMember(AccountId = accRec.Id, UserId = UserInfo.getUserId(),TeamMemberRole='Security Services - Primary'));
        insert accTeamInsert;
        
        // Creating Contact
        Contact con = new Contact();
        con.LastName = 'Test Contact';
        con.AccountId = accRec.id;
        con.Email = 'sbhan@akamai.com';
        con.Primary_Contact_Method__c = 'Mobile';
        insert con;      
        
        //Creating Case Product
        EB_AccountProductMap__c eb_product = new EB_AccountProductMap__c();
        eb_product.Name = 'Kona DDoS Defender';
        eb_product.EB_MarkedForDeletion__c = false;
        eb_product.EB_Product__c='Kona DDoS Defender';
        eb_product.EB_Account__c=accRec.id;
        insert eb_product;
        
        // Creating Policy Domain
        List<Policy_Domain__c> PolicyList = new List<Policy_Domain__c>();
        Policy_Domain__c  Policy = new Policy_Domain__c();
        Policy.Name = 'TestPolicy';
        Policy.Account_Name__c = accRec.Id;
        Policy.Product__c = 'Kona DDoS Defender';
        Policy.Policy_Domain_State__c  = 'Active';
        Policy.Additional_Product__c = 'Application-based Monitoring';
        PolicyList.add(Policy);
        
        Policy_Domain__c  Policy2 = new Policy_Domain__c();
        Policy2.Name = 'TestPolicy2';
        Policy2.Account_Name__c = accRec.Id;
        Policy2.Product__c = 'Test Product';
        Policy2.Policy_Domain_State__c  = 'Provisioned';
        Policy2.Additional_Product__c = 'Managed Kona';
        PolicyList.add(Policy2);
        Insert PolicyList;
        
        // Creating Handler Type
        Handler_Type__c  HandTypeRec = new Handler_Type__c (Name='Phone Call Handler Type',Fields_To_Show__c ='Situation_Instruction__c,Escalation_List__c');
        insert HandTypeRec;  
        
        // Creating Situation Catalog
        SC_SOCC_Situation_Catalog__c  SitCatRec = new SC_SOCC_Situation_Catalog__c (Handler_Type__c =HandTypeRec.id,Name='Kona DDoS DefenderAttack',Product__c	='Kona DDoS Defender',Situation_Class__c ='Attack',Handler_Type_picklist__c ='Phone Call Handler Type');
        insert SitCatRec;  
        
        //Creating Handler
        List<Handler__c> lhandler = new List<Handler__c>();
        
        Handler__c handlerrec= new Handler__c (Name='TestHandler',Handler_Type__c =HandTypeRec.id, Policy_Domain__c =Policy.id);
        lhandler.add(handlerrec);
        insert lhandler;
        
        // Creating situation to handler mapping
        SC_SOCC_Situation_to_Handler_Mapping__c s2hrec = new SC_SOCC_Situation_to_Handler_Mapping__c (Policy_Domain__c =Policy.id,Situation__c =SitCatRec.id, Handler__c =handlerrec.id);
        insert s2hrec;
        System.debug('Number of Queries used so far in this test apex code so far(line:90) in setupMethod: ' + Limits.getQueries());
        //Test.startTest();
        //System.debug('Number of Queries used so far in this test apex code so far(line:92) in setupMethod: ' + Limits.getQueries());
        // Creating Authorized Contact
        Authorized_Contact__c  AuthCon = new Authorized_Contact__c();
        AuthCon.Contact_Name__c = con.id;
        AuthCon.Policy_Domain__c = PolicyList[0].id;
        insert AuthCon;
        Test.startTest();
        System.debug('Number of Queries used so far in this test apex code so far(line:99) in setupMethod: ' + Limits.getQueries());
        List<Case> newCaseInsertList = new List<Case>();
        Case newCase = new Case();
        newCase.Subject = 'TestCasewithtasks';
        newcase.Status = 'Assigned';
        newCase.Description = 'TestDescription';
        newCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Managed Security').getRecordTypeId();
        newCase.validation_override__c = true;
        newCase.recent_update__c = true;
        newCase.AccountId = accRec.Id;
        newCase.origin='Email';
        newcase.Case_Product__c = eb_product.id;
        newcase.Priority_Type__c = 'Hot Customer';
        newcase.Priority_Expiry_Date__c=datetime.now().addDays(1);
        newcase.Severity__c = '1';
        newcase.Policy_Domain__c = PolicyList[0].id;
        newcase.Case_Situation_Handler__c =s2hrec.id;
        newcase.Is_SOCC_Priority__c = True;
        newcase.Problem__c = 'Alerts';
        newcase.Solution_Summary__c='Test Summary 0';
        newCaseInsertList.add(newCase);  
        
        Case newCase1 = new Case();
        newCase1.Subject = 'TestCasewithtasks2';
        newCase1.Status = 'Assigned';
        newCase1.Description = 'TestDescription';
        newCase1.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Managed Security').getRecordTypeId();
        newCase1.validation_override__c = true;
        newCase1.recent_update__c = true;
        newCase1.AccountId = accRec.Id;
        newCase1.origin='Email';
        newCase1.Case_Product__c = eb_product.id;
        newCase1.Priority_Type__c = 'Hot Customer';
        newCase1.Priority_Expiry_Date__c=datetime.now().addDays(1);
        newCase1.Severity__c = '1';
        newCase1.Policy_Domain__c = PolicyList[0].id;
        newCase1.Case_Situation_Handler__c =s2hrec.id;
        newCase1.Is_SOCC_Priority__c = True;
        newCase1.Problem__c = 'Alerts';
        newCase1.Solution_Summary__c='Test Summary 1';
        newCaseInsertList.add(newCase1); 
        
        Case newCase2= new Case();
        newCase2.Subject = 'TestwhiteCase';
        newCase2.Description = 'TestDescription1';
        newCase2.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Managed Security').getRecordTypeId();
        newCase2.validation_override__c = true;
        newCase2.AccountId = accRec.Id;
        newCase2.origin='Email';
        newCase2.Case_Product__c = eb_product.id;
        newcase.Status = 'Unassigned';
        newCase2.Priority_Type__c = 'Hot Customer';
        newCase2.Priority_Expiry_Date__c=datetime.now().addDays(1);
        newCase2.Severity__c = '1';
        newCase2.Policy_Domain__c = PolicyList[0].id;
        newCase2.Is_SOCC_Priority__c = True;
        newCase2.Problem__c = 'Alerts';
        newCase2.Solution_Summary__c='Test Summary 2';
        newCaseInsertList.add(newCase2); 
        
        Case newCase3= new Case();       
        newCase3.Subject = 'TestCasefortasks';
        newCase3.Description = 'TestDescription';
        newCase3.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Managed Security').getRecordTypeId();
        newCase3.validation_override__c = true;
        newCase3.recent_update__c = false;
        newCase3.AccountId = accRec.Id;
        newCase3.origin='Email';
        newCase3.Status = 'Assigned';
        newCase3.Priority_Type__c = 'Hot Customer';
        newCase3.Priority_Expiry_Date__c=datetime.now().addDays(1);
        newCase3.Severity__c = '1';
        newCase3.Is_SOCC_Priority__c = True;
        newCase3.Problem__c = 'Alerts';
        newCase3.Solution_Summary__c='Test Summary 3';
        newCaseInsertList.add(newCase3);
        
        Case newCase4 = new Case();
        newCase4.Subject = 'TestClosedCase';
        newCase4.Status = 'Closed';
        newCase4.Description = 'TestDescription';
        newCase4.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Managed Security').getRecordTypeId();
        newCase4.validation_override__c = true;
        newCase4.recent_update__c = true;
        newCase4.AccountId = accRec.Id;
        newCase4.origin='Email';
        newCase4.Case_Product__c = eb_product.id;
        newCase4.Priority_Type__c = 'Hot Customer';
        newCase4.Priority_Expiry_Date__c=datetime.now().addDays(1);
        newCase4.Severity__c = '1';
        newCase4.Policy_Domain__c = PolicyList[0].id;
        newCase4.Case_Situation_Handler__c =s2hrec.id;
        newCase4.Is_SOCC_Priority__c = True;
        newCase4.Problem__c = 'Alerts';
        newCase4.Solution_Summary__c = 'Test Summary 4';
        newCaseInsertList.add(newCase4); 
        
        Insert newCaseInsertList;
        
        List<EmailMessage> lmsg = new List<EmailMessage>();
        EmailMessage newEmail = new EmailMessage();
        newEmail.FromAddress ='test@abc.org';
        newEmail.Incoming = true;
        newEmail.ToAddress = 'hello@670ocglw7xhomi4oyr5yw2zvf.8kp7yeag.8.case.salesforce.com ; emailtocaseservice@h-1ju2hg3c4u51oyurs2mrz3cslkf2r0o6zllx5kxt8aj0m89s8e.76-4etweaq.cs211.apex.sandbox.salesforce.com ; managedsecurity-qa@akamai.com ; managedsecurity@akamai.com';
        newEmail.Subject ='Test email';
        newEmail.TextBody = '23456';
        newEmail.ParentId = newCaseInsertList[0].Id;
        newEmail.CcAddress = 'abc@xyz.com ; emailtocaseservice@h-1ju2hg3c4u51oyurs2mrz3cslkf2r0o6zllx5kxt8aj0m89s8e.76-4etweaq.cs211.apex.sandbox.salesforce.com ; managedsecurity-qa@akamai.com ; managedsecurity@akamai.com';
        newEmail.BccAddress = 'xyz.abc.com ; emailtocaseservice@h-1ju2hg3c4u51oyurs2mrz3cslkf2r0o6zllx5kxt8aj0m89s8e.76-4etweaq.cs211.apex.sandbox.salesforce.com ; managedsecurity-qa@akamai.com ; managedsecurity@akamai.com';
        lmsg.add(newEmail);
        //newEmail.add(new EmailMessage(FromAddress = 'test@abc.org', Incoming = True, ToAddress= 'hello@670ocglw7xhomi4oyr5yw2zvf.8kp7yeag.8.case.salesforce.com', Subject = 'Test email', TextBody = '23456 ', ParentId = newCaseInsertList[0].Id, CcAddress = 'abc@xyz.com', BccAddress = 'xyz.abc.com')); 
        
       
        EmailMessage newEmail2 = new EmailMessage();
        newEmail2.FromAddress ='test@abc.org';
        newEmail2.Incoming = true;
        newEmail2.ToAddress = 'hello@670ocglw7xhomi4oyr5yw2zvf.8kp7yeag.8.case.salesforce.com;emailtocaseservice@h-1ju2hg3c4u51oyurs2mrz3cslkf2r0o6zllx5kxt8aj0m89s8e.76-4etweaq.cs211.apex.sandbox.salesforce.com;managedsecurity-qa@akamai.com;managedsecurity@akamai.com';
        newEmail2.Subject ='Test email';
        newEmail2.TextBody = '23456';
        newEmail2.ParentId = newCase1.Id;
        newEmail2.CcAddress = 'abc@xyz.com;emailtocaseservice@h-1ju2hg3c4u51oyurs2mrz3cslkf2r0o6zllx5kxt8aj0m89s8e.76-4etweaq.cs211.apex.sandbox.salesforce.com;managedsecurity-qa@akamai.com;managedsecurity@akamai.com';
        newEmail2.BccAddress = 'xyz.abc.com;emailtocaseservice@h-1ju2hg3c4u51oyurs2mrz3cslkf2r0o6zllx5kxt8aj0m89s8e.76-4etweaq.cs211.apex.sandbox.salesforce.com;managedsecurity-qa@akamai.com;managedsecurity@akamai.com';
        newEmail2.Status = '3' ;
        lmsg.add(newEmail2);
        
        
        EmailMessage newEmail3 = new EmailMessage();
        newEmail3.FromAddress ='test1@abc.org';
        //newEmail3.Incoming = true;
        newEmail3.ToAddress = 'hello@670ocglw7xhomi4oyr5yw2zvf.8kp7yeag.8.case.salesforce.com;emailtocaseservice@h-1ju2hg3c4u51oyurs2mrz3cslkf2r0o6zllx5kxt8aj0m89s8e.76-4etweaq.cs211.apex.sandbox.salesforce.com;managedsecurity-qa@akamai.com;managedsecurity@akamai.com';
        newEmail3.Subject ='Test email';
        newEmail3.TextBody = '23456';
        newEmail3.ParentId = newCase1.Id;
        newEmail3.CcAddress = 'abc@xyz.com;emailtocaseservice@h-1ju2hg3c4u51oyurs2mrz3cslkf2r0o6zllx5kxt8aj0m89s8e.76-4etweaq.cs211.apex.sandbox.salesforce.com;managedsecurity-qa@akamai.com;managedsecurity@akamai.com';
        newEmail3.BccAddress = 'xyz.abc.com;emailtocaseservice@h-1ju2hg3c4u51oyurs2mrz3cslkf2r0o6zllx5kxt8aj0m89s8e.76-4etweaq.cs211.apex.sandbox.salesforce.com;managedsecurity-qa@akamai.com;managedsecurity@akamai.com';
        newEmail3.Status = '1' ;
        lmsg.add(newEmail3);
        
        insert lmsg;
        
        // Creating SOCC Living Summary Template
        SC_SOCC_Living_Summary_Template__c SLiv = new SC_SOCC_Living_Summary_Template__c();
        SLiv.Name= 'Test Template';
        SLiv.Living_Summary_Template__c = 'Test Summary Template';
        insert SLiv;
        
        System.debug('Number of Queries used in this apex code so far in testsetup1: ' + Limits.getQueries());        
        /*Group grp = new Group(Name='Primary/Secondary Assignment Queue', type='Queue');
        insert grp;*/
        System.debug('Number of Queries used so far in this test apex code so far(line:245) in setupMethod: ' + Limits.getQueries());
        Test.stopTest();
        System.debug('Number of Queries used in this apex code so far in testsetup2: ' + Limits.getQueries());
        
        
    }
    
    @isTest
    public static void TestEmailMethods(){
        
        List<String> SelectedGeoFromUser = new list<String>{'Americas', 'APJ' };
            Map<String,integer> sortOrder = new Map<String,integer>();
        sortOrder.put('In Progress',0);
        sortOrder.put('Waiting on Someone Else',1);
        sortOrder.put('Deferred',2);
        sortOrder.put('Not Started',3);
        sortOrder.put('Completed Important',4);
        sortOrder.put('Completed',5);
        
        
        Test.startTest();
        System.debug('Number of Queries used in this test apex code so far(line:266) in TestEmailMethods: ' + Limits.getQueries());
        // Fetching data from setupMethod
        User getUserInfo = [select id,name from user where id =: UserInfo.getUserId() limit 1];
        List<Case> CaseDet = [Select Id,AccountId,Case_Prod_Name__c,AKAM_Account_ID__c,akam_case_id__c,Contact.name,Case_Account_Name__c, Priority_Type__c, Owner.Name, Severity__c, lastmodifieddate from Case where Subject='TestCasewithtasks' LIMIT 1];
        EmailMessage newEmail = [Select Id, FromAddress, Incoming, ToAddress, Subject, ParentId, CcAddress, BccAddress from EmailMessage where FromAddress='test@abc.org' LIMIT 1];
        
        
        // Calling SC_SOCC_Case_LightningUtility Methods
        SC_SOCC_Case_LightningUtility.getEmail(CaseDet[0].Id);
        SC_SOCC_Case_LightningUtility.getSingleEmail(newEmail.Id);
        SC_SOCC_Case_LightningUtility.sortOrder = sortOrder;
        System.debug('Number of Queries used in this test apex code so far(line:277) in TestEmailMethods: ' + Limits.getQueries());
        Test.stopTest();
        
    }
    
    @isTest
    public static void TestCaseDetailMethods1(){
        
        Test.startTest();
        System.debug('Number of Queries used in this test apex code so far(line:286) in TestCaseDetailMethods1: ' + Limits.getQueries());
        SC_SOCC_Living_Summary_Template__c SLiv = [Select Id,Name,Living_Summary_Template__c from SC_SOCC_Living_Summary_Template__c where Name= 'Test Template' LIMIT 1];
        List<Case> CaseDet = [Select Id from Case where Subject='TestCasewithtasks' LIMIT 1];
        list<EB_AccountProductMap__c> caseprod=   [Select Id from EB_AccountProductMap__c where Name='Kona DDoS Defender' LIMIT 1];    
        SC_SOCC_Case_LightningUtility.getInternalEmails(CaseDet[0].Id);
        SC_SOCC_Case_LightningUtility.getwebupdateTaskDetails(CaseDet[0].Id);
        SC_SOCC_Case_LightningUtility.getCaseInitialSetupDetails(CaseDet[0].Id);
        SC_SOCC_Case_LightningUtility.getLivingSummaryDetails();
        SC_SOCC_Case_LightningUtility.getLivingSummaryBody(SLiv.id);
        //SC_SOCC_Case_LightningUtility.getPolicyDomainList(CaseDet[0].Id,caseprod[0].Id);
        System.debug('Number of Queries used in this test apex code so far(line:296) in TestCaseDetailMethods1: ' + Limits.getQueries());
        Test.stopTest();
        
    }
    
    @isTest
    public static void TestInitialCaseSetupMethods(){
        Test.startTest();
        System.debug('Number of Queries used in this test apex code so far(line:304) in TestInitialCaseSetupMethods: ' + Limits.getQueries());
        List<Case> CaseDet = [Select Id,SOCC_Image_Banner_Category__c from Case where Subject='TestCasewithtasks' LIMIT 1];
        Policy_Domain__c Policy = [Select Id,Name from Policy_Domain__c where Name = 'TestPolicy' LIMIT 1];
        
        
        SC_SOCC_Case_LightningUtility.getSituationsforPolicyDomain(Policy.id,CaseDet[0].id);
        SC_SOCC_Case_LightningUtility.getCaseHandlerDetails(CaseDet[0].id);
        SC_SOCC_Case_LightningUtility.UpdateImageBanner(CaseDet[0].Id, CaseDet[0].SOCC_Image_Banner_Category__c);
        SC_SOCC_Case_LightningUtility.savePolicyDomainandSituation(CaseDet[0].Id, Policy.Id,null);
        System.debug('Number of Queries used in this test apex code so far(line:313) in TestInitialCaseSetupMethods: ' + Limits.getQueries());
        Test.stopTest();
        
    }
    
    
    // 2nd Method for calling SOCCDash methods
    @isTest
    public static void TestSOCCDashChartMethods(){
        
        Id getUserId = UserInfo.getUserId();
        DateTime myDateTime = datetime.now().addDays(1);
        Integer DeferValue = 3;
        String StatusValue = 'Deferred';
        Integer TaskCountbelow0to6 = 1;
        Integer TaskCount0to6 = 2;
        Integer TaskCount6to12 = 3;
        Integer TaskCountabove12 = 4; 
        
        // Fetching data from setupMethod
        Test.startTest();
        System.debug('Number of Queries used in this test apex code so far(line:334) in TestSOCCDashChartMethods: ' + Limits.getQueries());
        Contact con = [Select Id, LastName from Contact where LastName='Test Contact' limit 1];
        List<Case> CaseDet = [Select Id,Recent_Update__c,Is_SOCC_Priority__c,Last_Update_By__c,Account.Is_SOCC_Premium_Customer__c,Account.Geography_Formula__c,Account.Division__c,SOCC_Image_Banner_Category__c, Priority_Type__c, Owner.Name, Severity__c, lastmodifieddate from Case where Subject='TestCasewithtasks' LIMIT 1];
        
        
        
        //Test.startTest();
        // Creating Task
        List<Task> TaskList = new List<Task>();
        Task tsk = new Task();
        tsk.OwnerId = getUserId;
        tsk.Subject = 'Call';
        tsk.Status = 'In Progress';
        tsk.Type__c = '1st Meeting';
        tsk.Priority = 'High';
        tsk.WhatId = CaseDet[0].Id;
        tsk.DueDateProlexic__c = myDateTime;
        TaskList.add(tsk);
        Insert TaskList;
        
        // Calling SC_SOCC_Case_LightningUtility Methods
        SC_SOCC_Case_LightningUtility.getContactDetails(con.Id);
        SC_SOCC_Case_LightningUtility.Task_chart_wrapper TaskChartWrap = new SC_SOCC_Case_LightningUtility.Task_chart_wrapper(TaskCountbelow0to6, TaskCount0to6, TaskCount6to12, TaskCountabove12);
        SC_SOCC_Case_LightningUtility.getTaskcountByDueDate();
        SC_SOCC_Case_LightningUtility.Task_geo_chart_wrapper TaskGeoWrap = new SC_SOCC_Case_LightningUtility.Task_geo_chart_wrapper(TaskCountbelow0to6, TaskCount0to6, TaskCount6to12);
        SC_SOCC_Case_LightningUtility.getTaskcountBygeo();
        System.debug('Number of Queries used in this test apex code so far(line:360) in TestSOCCDashChartMethods: ' + Limits.getQueries());
        Test.stopTest();
        
        
    }
    
    // 3rd Method for calling SC_SOCC_Case_LightningUtility methods
    @isTest
    public static void TestSOCCDashMethods(){
        
        DateTime myDateTime = datetime.now().addDays(1);
        String premiumFilter = 'True';
        List<String> SeverityFilter = new list<String>{'1', '2','3'};
            Map<string,decimal> Metadatafields_RankMap = new Map<string,decimal>();
        Metadatafields_RankMap.put('1-true-true', 1);
        String searchtype = 'Account.Name';
        String searchvalue = '';
        
        //System.debug('Number of Queries used in this apex code so far before CallingMethod3: ' + Limits.getQueries());
        
        Test.startTest();
        System.debug('Number of Queries used in this test apex code so far(line:381) in TestSOCCDashMethods: ' + Limits.getQueries());
        List<Case> CaseDet = [Select Id,AKAM_Case_ID__c,status,Recent_Update__c,Policy_Domain__r.Name,Policy_Domain__r.id,AKAM_Modified_By__c,Is_SOCC_Priority__c,Problem__c,Last_Update_By__c,Account.Is_SOCC_Premium_Customer__c,Initial_Response_Date__c,Geography__c,Account.Name,SOCC_Image_Banner_Category__c, Priority_Type__c, Owner.Name, Severity__c, lastmodifieddate,subject  from Case where Subject='TestCasewithtasks' LIMIT 1];
        
        List<Task> TaskList = new List<Task>();
        Task tsk = new Task();
        //tsk.OwnerId = getUserInfo.Id;
        tsk.Subject = 'Call';
        tsk.Status = 'In Progress';
        tsk.Type__c = '1st Meeting';
        tsk.Priority = 'High';
        tsk.WhatId = CaseDet[0].Id;
        tsk.DueDateProlexic__c = myDateTime;
        TaskList.add(tsk);
        
        Task tsk1 = new Task();
        //tsk1.OwnerId = getUserInfo.Id;
        tsk1.Subject = 'Call';
        tsk1.Status = 'In Progress';
        tsk1.Type__c = '1st Meeting';
        tsk1.Priority = 'High';
        tsk1.WhatId = CaseDet[0].Id;
        tsk1.DueDateProlexic__c = myDateTime;
        TaskList.add(tsk1);
        
        Insert TaskList;
        EB_AccountProductMap__c eb_product = [Select id, name from EB_AccountProductMap__c where name = 'Kona DDoS Defender' limit 1];
        
        Set<Id> CaseIds = new Set<id>();
        CaseIds.add(CaseDet[0].Id);
        Map<Id,Case> CaseID_CaseDetails = new Map<Id,Case>();
        CaseID_CaseDetails.put(CaseDet[0].Id, CaseDet[0]);
        
        SC_SOCC_Case_LightningUtility.getContactEmail(CaseDet[0].Id);
        SC_SOCC_Case_LightningUtility.getAuthorizedContacts(CaseDet[0].Id);
        SC_SOCC_Case_LightningUtility.main_Auth_contact_wrapper MainWrapper = new SC_SOCC_Case_LightningUtility.main_Auth_contact_wrapper();
        SC_SOCC_Case_LightningUtility.sub_Contact_Wrapper SubWrapper = new SC_SOCC_Case_LightningUtility.sub_Contact_Wrapper();
        SC_SOCC_Case_LightningUtility.Contact_Details_Wrapper ContactWrapper = new SC_SOCC_Case_LightningUtility.Contact_Details_Wrapper();
        SC_SOCC_Case_LightningUtility.Contact_Details_Wrapper ConWrapper = new SC_SOCC_Case_LightningUtility.Contact_Details_Wrapper();
        SC_SOCC_Case_LightningUtility.getPolicyDomainList(CaseDet[0].Id, null);
        //System.debug('Number of Queries used in this apex code so far in CallingMethod3: ' + Limits.getQueries());
        System.debug('Number of Queries used in this test apex code so far(line:421) in TestSOCCDashMethods: ' + Limits.getQueries());
        Test.stopTest();
        
    }
    
    @isTest
    public static void TestMethodforCaseProduct(){
        
        Test.startTest();
        System.debug('Number of Queries used in this test apex code so far(line:430) in TestMethodforCaseProduct: ' + Limits.getQueries());
        List<Case> CaseDet = [Select Id from Case where Subject='TestCasewithtasks' LIMIT 1];
        Policy_Domain__c Policy = [Select Id from Policy_Domain__c where Name = 'TestPolicy' LIMIT 1];
        EB_AccountProductMap__c eb_product = [Select id from EB_AccountProductMap__c where name = 'Kona DDoS Defender' limit 1];
        
        SC_SOCC_Case_LightningUtility.getCaseProductList(CaseDet[0].Id);
        SC_SOCC_Case_LightningUtility.saveProduct(CaseDet[0].Id, eb_product.Id, Policy.Id,null);
        // System.debug('Number of Queries used in this apex code so far in CallingMethodforCaseProduct: ' + Limits.getQueries());
        System.debug('Number of Queries used in this test apex code so far(line:438) in TestMethodforCaseProduct: ' + Limits.getQueries());
        Test.stopTest();
        
    }
    
    @isTest
    public static void TestMethodforSendEmail(){
        Test.startTest();
        System.debug('Number of Queries used in this test apex code so far(line:446) in TestMethodforSendEmail: ' + Limits.getQueries());
        List<Case> CaseDet = [Select Id from Case where Subject='TestCasewithtasks' LIMIT 1];
        SC_SOCC_Case_LightningUtility.sendEmailToAccountTeam(CaseDet[0].Id);
        System.debug('Number of Queries used in this test apex code so far(line:449) in TestMethodforSendEmail: ' + Limits.getQueries());
        Test.stopTest();
        
    }
    
    @isTest
    public static void SOCCDashLWCMethods()
    {
        List<String> SeverityFilter = new list<String>{'1', '2','3'};
            List<String> SelectedGeoFromUser = new list<String>{'Americas', 'APJ' };
                Test.startTest();
        System.debug('Number of Queries used in this test apex code so far(line:460) in SOCCDashLWCMethods: ' + Limits.getQueries());
        List<Case> CaseDet = [Select Id from Case where subject='TestCasefortasks'];
        List<Task> TaskList = new List<Task>();
        Task tsk = new Task();
        tsk.Subject = 'Call';
        tsk.Status = 'In Progress';
        tsk.Type__c = '1st Meeting';
        tsk.Priority = 'High';
        tsk.WhatId = CaseDet[0].Id;
        tsk.DueDateProlexic__c =datetime.now().addDays(1);
        TaskList.add(tsk);
        
        /*Task orange = new Task();
        orange.Subject = 'Call';
        orange.Status = 'In Progress';
        orange.Type__c = '1st Meeting';
        orange.Priority = 'High';
        orange.WhatId = CaseDet[0].Id;
        orange.DueDateProlexic__c =datetime.now().AddHours(4);
        TaskList.add(orange);
        
        Task attacktsk = new Task();
        attacktsk.Subject = 'Call';
        attacktsk.Status = 'In Progress';
        attacktsk.Type__c = 'Attack';
        attacktsk.Priority = 'High';
        attacktsk.WhatId = CaseDet[0].Id;
        attacktsk.DueDateProlexic__c =datetime.now().addDays(-1);
        TaskList.add(attacktsk);*/
        
        Task overdue = new Task();
        overdue.Subject = 'Call';
        overdue.Status = 'In Progress';
        overdue.Type__c = '1st Meeting';
        overdue.Priority = 'High';
        overdue.WhatId = CaseDet[0].Id;
        overdue.DueDateProlexic__c =datetime.now().addDays(-1);
        TaskList.add(overdue);
        
        Insert TaskList;
     
        SC_SOCC_Lightning_HomePage.getSocHomeTask('All', 'All', 'All',SeverityFilter, null, null);
        SC_SOCC_Lightning_HomePage.saveSelectedFilters(SelectedGeoFromUser,'50','excludeUSFed');
        SC_SOCC_Lightning_HomePage.getRecordTypeID();
        //To increase coverage for ESESP-5109
        SC_SOCC_Lightning_HomePage.GenerateDynamicQuery('All', 'All', 'True',SeverityFilter, 'Test', null);
        SC_SOCC_Case_LightningUtility.getTaskData(CaseDet[0].Id, 'In Progress', '1st Meeting');
        SC_SOCC_Case_LightningUtility.assignTask(tsk.Id);
        //SC_SOCC_Case_LightningUtility.deferTask(orange.Id, 4);
        //SC_SOCC_Case_LightningUtility.completeTask(attacktsk.Id);
        System.debug('Number of Queries used in this test apex code so far(line:510) in SOCCDashLWCMethods: ' + Limits.getQueries());
        Test.stopTest(); 
        
    }
    
    @isTest
    public static void SOCCDashLWCMethods2()
    {
         Test.startTest();
         System.debug('Number of Queries used in this test apex code so far(line:519) in SOCCDashLWCMethods2: ' + Limits.getQueries());
         List<Case> CaseDet = [Select Id from Case where subject='TestCasefortasks'];
         List<Task> TaskList = new List<Task>();
        
         Task orange = new Task();
         orange.Subject = 'Call';
         orange.Status = 'In Progress';
         orange.Type__c = '1st Meeting';
         orange.Priority = 'High';
         orange.WhatId = CaseDet[0].Id;
         orange.DueDateProlexic__c =datetime.now().AddHours(4);
         TaskList.add(orange);
        
         Task attacktsk = new Task();
         attacktsk.Subject = 'Call';
         attacktsk.Status = 'In Progress';
         attacktsk.Type__c = 'Attack';
         attacktsk.Priority = 'High';
         attacktsk.WhatId = CaseDet[0].Id;
         attacktsk.DueDateProlexic__c =datetime.now().addDays(-1);
         TaskList.add(attacktsk);
        
         insert TaskList;
        
         SC_SOCC_Case_LightningUtility.deferTask(orange.Id, 4);
         SC_SOCC_Case_LightningUtility.completeTask(attacktsk.Id);
         System.debug('Number of Queries used in this test apex code so far(line:545) in SOCCDashLWCMethods2: ' + Limits.getQueries());
         Test.stopTest();
    }
    
    @isTest 
    public static void testTicketPushMethods()
    {
        //List<Case> lc=[Select Id,Subject from Case];
        Test.startTest();
        String caseId1;
        String caseId2;
        System.debug('Number of Queries used in this test apex code so far(line:556) in testTicketPushMethods: ' + Limits.getQueries());
        for(Case c: [Select Id,Subject from Case])
        {
            if(c.Subject=='TestCasewithtasks')
        	{
            	caseId1=c.Id;
        		String msg = SC_SOCC_Case_LightningUtility.createTicketPushTask('24',caseId1);
        		String msg2 = SC_SOCC_Case_LightningUtility.createTicketPushTask('72',caseId1);
        	}
        	/*else if(c.Subject=='TestCasewithtasks2')
        	{
            	caseId2=c.Id;
        		//String msg = SC_SOCC_Case_LightningUtility.createTicketPushTask('24',caseId);
        		String msg2 = SC_SOCC_Case_LightningUtility.createTicketPushTask('72',caseId2);
        	}*/
            else if(c.Subject=='TestClosedCase')
            {
                String caseId=c.Id;
        		//String msg = SC_SOCC_Case_LightningUtility.createTicketPushTask('24',caseId);
        		String msg2 = SC_SOCC_Case_LightningUtility.createTicketPushTask('72',caseId);
            }
        }
        
        if(caseId1!=null )
        {
            EmailMessage newEmail = new EmailMessage();
        	newEmail.FromAddress ='test@abc.org';
        	newEmail.Incoming = true;
        	newEmail.ToAddress = 'hello@670ocglw7xhomi4oyr5yw2zvf.8kp7yeag.8.case.salesforce.com ; emailtocaseservice@h-1ju2hg3c4u51oyurs2mrz3cslkf2r0o6zllx5kxt8aj0m89s8e.76-4etweaq.cs211.apex.sandbox.salesforce.com ; managedsecurity-qa@akamai.com ; managedsecurity@akamai.com';
        	newEmail.Subject ='Test email';
        	newEmail.TextBody = '23456';
        	newEmail.ParentId = Id.valueOf(caseId1);
        	newEmail.CcAddress = 'abc@xyz.com ; emailtocaseservice@h-1ju2hg3c4u51oyurs2mrz3cslkf2r0o6zllx5kxt8aj0m89s8e.76-4etweaq.cs211.apex.sandbox.salesforce.com ; managedsecurity-qa@akamai.com ; managedsecurity@akamai.com';
        	newEmail.BccAddress = 'xyz.abc.com ; emailtocaseservice@h-1ju2hg3c4u51oyurs2mrz3cslkf2r0o6zllx5kxt8aj0m89s8e.76-4etweaq.cs211.apex.sandbox.salesforce.com ; managedsecurity-qa@akamai.com ; managedsecurity@akamai.com';
        	insert newEmail;
            
        }
        System.debug('Number of Queries used in this test apex code so far(line:593) in testTicketPushMethods: ' + Limits.getQueries());
        /*if(caseId2!=null){
            Task newtask = new Task();
            newtask.WhatId = Id.valueOf(caseId2);
            newtask.Status = 'Completed';
            newtask.Type__c='Web Update';
            newtask.Subject = 'Jarvis Comment';
            newtask.Description='Jarvis task';
            insert newtask;

        }*/
               
         Test.stopTest(); 
               
    }
    
    @isTest
    public static void testTicketPushMethods2()
    {
		Test.startTest(); 
        System.debug('Number of Queries used in this test apex code so far(line:613) in testTicketPushMethods2: ' + Limits.getQueries());
        List<Case> lc =[Select Id,Subject from Case where Subject = 'TestCasewithtasks2' limit 1];
        if(lc.size()>0)
        {
            String caseId=lc[0].Id;
            String msg = SC_SOCC_Case_LightningUtility.createTicketPushTask('72',caseId);
            
            Task newtask = new Task();
            newtask.WhatId = lc[0].Id;
            newtask.Status = 'Completed';
            newtask.Type__c='Web Update';
            newtask.Subject = 'Jarvis Comment';
            newtask.Description='Jarvis task';
            insert newtask;
        }
        System.debug('Number of Queries used in this test apex code so far(line:628) in testTicketPushMethods2: ' + Limits.getQueries());
        Test.stopTest(); 
    }
    
}