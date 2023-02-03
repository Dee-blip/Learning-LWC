/*---------------------------------------------------------------------------------
Class name          :   SC_SI_AllUseCases_TC
Author              :   Vishnu Sharma / Himanshu / Sheena / Vamsee
Created             :   01-Dec-2020
JIRA                :   ESESP-3015
Purpose             :   Test Class for SI Functionality

Last Modified         Developer             Purpose            
============= ========================      ==========
01-Dec-2020     Vishnu Sharma/Himanshu      Initial Version
28-Sep-2021     Vandhana Krishnamurthy      Code Scan changes ESESP-6174
* --------------------------------------------------------------------------------*/
@isTest
public class SC_SI_AllUseCases_TC {
    
    public static User iraptUser;
    public static User nonIraptUser;
    
    // Setup method to create test data.
    static
    {
        iraptUser = [SELECT id,name from user where alias='CRMOPS'];
        nonIraptUser = [SELECT id,name from user where alias='ODIINTEG'];
    }
    
    @testSetup
    static void setupMethod()
    {
        utilTestClass.createCustomSettings();
        
        // Creating Account
        List<Account> accList =  new List<Account>();
        Account acc = utilTestClass.CreateAccount('TestAccount');
        acc.Customer_Tier__c = 'A';
        accList.add(acc);
        Account acc2 = utilTestClass.CreateAccount('TestAccount 2'); 
        accList.add(acc2);
        insert accList;
        
        // Creating Entitled Case Products
        List<EB_AccountProductMap__c> caseProductList = new List<EB_AccountProductMap__c>();
        EB_AccountProductMap__c caseProd = new EB_AccountProductMap__c();
        caseProd.Name = 'Test Case Product';
        caseProd.EB_Account__c= acc.Id;
        caseProd.EB_Product__c = 'Test Case Product';
        caseProductList.add(caseProd);
        
        caseProd = new EB_AccountProductMap__c();
        caseProd.Name = 'Test Case Product 2';
        caseProd.EB_Account__c= acc.Id;
        caseProd.EB_Product__c = 'Test Case Product 2';
        caseProductList.add(caseProd);
        insert caseProductList;
        
        //Creating BMC category type
        BMCServiceDesk__CategoryTypes__c ctype = new BMCServiceDesk__CategoryTypes__c(Name = 'categoryTypeTest' );
        insert ctype;
        
        //Creating category for BMC incident
        BMCServiceDesk__Category__c cat = new BMCServiceDesk__Category__c();
        cat.Name='TempCategory';
        cat.SI_Applies_to_Service_Incident__c = true;
        cat.BMCServiceDesk__AvailableForServiceCatalog__c = true;
        cat.BMCServiceDesk__FKCategoryType__c = ctype.Id;
        insert cat;
        
        //Creating BMC urgency
        BMCServiceDesk__Urgency__c  urg = new BMCServiceDesk__Urgency__c();
        urg.Name='tempUrgency1';
        urg.SI_Applies_to_Service_Incident__c = true;
        insert urg;
        
        //Creating BMC impact
        BMCServiceDesk__Impact__c ima = new BMCServiceDesk__Impact__c();
        ima.Name='tempImpact';
        ima.SI_Applies_to_Service_Incident__c = true;
        insert ima;
        
        //Creating BMC Service Incident
        List<BMCServiceDesk__Incident__c> BMCIncidentList = new List<BMCServiceDesk__Incident__c>();
        BMCServiceDesk__Incident__c incident = new BMCServiceDesk__Incident__c();
        incident.RecordTypeId = BMCServiceDesk__Incident__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Service Incident').getRecordTypeId();
        incident.BMCServiceDesk__FKCategory__c = cat.Id;
        incident.BMCServiceDesk__FKUrgency__c = urg.id;
        incident.BMCServiceDesk__FKImpact__c = ima.Id;
        incident.BMCServiceDesk__shortDescription__c = 'Inc1';
        incident.how_was_the_issue_detected__c = 'others';
        incident.BMCServiceDesk__Service_Request_Title__c= 'Test1234';
        BMCIncidentList.add(incident);
        
        BMCServiceDesk__Incident__c incident2 = new BMCServiceDesk__Incident__c();
        incident2.RecordTypeId = BMCServiceDesk__Incident__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Service Incident').getRecordTypeId();
        incident2.BMCServiceDesk__FKCategory__c = cat.Id;
        incident2.BMCServiceDesk__FKUrgency__c = urg.id;
        incident2.BMCServiceDesk__FKImpact__c = ima.Id;
        incident2.BMCServiceDesk__shortDescription__c = 'Inc2';
        incident2.how_was_the_issue_detected__c = 'others';
        incident2.BMCServiceDesk__Service_Request_Title__c= 'Test';
        //BMCIncidentList.add(incident2);
        
        // changes by Vandhana for ESESP-6174 Code Scan
       System.runAs(iraptUser)
       {
            insert BMCIncidentList;
            insert incident2;
       }
        
        //Insert Attachment
        Attachment newAttachment = new Attachment();
        newAttachment.parentid = BMCIncidentList[0].Id/*BMCIncidentList[1].Id*/;
        newAttachment.Name = 'Test';
        newAttachment.IsPrivate = False;
        newAttachment.Body = Blob.valueOf('test');
        newAttachment.Description = 'Test';
        Insert newAttachment;
        
        // Creating Service Incidents
        List<SC_SI_Service_Incident__c> incidentList = new List<SC_SI_Service_Incident__c>();
        SC_SI_Service_Incident__c incRec = new SC_SI_Service_Incident__c();
        incRec.Status__c = 'Incident Request';
        incRec.Severity__c ='Severity 1';
        incRec.Title__c = 'Test Incident 1';
        incRec.Summary__c ='Test Summary';
        incRec.Symptoms__c ='Test Symptoms';
        incRec.What_Incident_Criteria_is_Met__c='Test Criteria';
        incRec.Customer_Temperature__c='High';
        incRec.How_was_the_issue_detected__c='Customer';
        incRec.Customer_Advisory__c='Test Advisory';
        incRec.SC_SI_Old_Incident_Id__c = BMCIncidentList[0].Id;
        incidentList.add(incRec);
        
        SC_SI_Service_Incident__c siRecord = new SC_SI_Service_Incident__c();
        siRecord.Status__c = '1: In Progress';
        siRecord.Severity__c ='Severity 1';
        siRecord.Title__c = 'Test Incident 2';
        siRecord.Summary__c ='Test Summary';
        siRecord.Symptoms__c ='Test Symptoms';
        siRecord.What_Incident_Criteria_is_Met__c='Test Criteria';
        siRecord.Customer_Temperature__c ='High';
        siRecord.How_was_the_issue_detected__c = 'Customer';
        siRecord.Customer_Advisory__c = 'Test Advisory';
        siRecord.Validation_Override__c = true;
        incidentList.add(siRecord);
        
        SC_SI_Service_Incident__c incRecHomePage = new SC_SI_Service_Incident__c();
        incRecHomePage.Status__c = 'Incident Request';
        incRecHomePage.Severity__c ='Severity 1';
        incRecHomePage.Title__c = 'Test Incident 3';
        incRecHomePage.Summary__c ='Test Summary';
        incRecHomePage.Symptoms__c ='Test Symptoms';
        incRecHomePage.What_Incident_Criteria_is_Met__c='Test Criteria';
        incRecHomePage.Customer_Temperature__c='High';
        incRecHomePage.How_was_the_issue_detected__c='Customer';
        incRecHomePage.Customer_Advisory__c='Test Advisory';
        incRecHomePage.Validation_Override__c = true;
        incidentList.add(incRecHomePage);
      
     
        SC_SI_Service_Incident__c incRecHomePage2 = new SC_SI_Service_Incident__c();
        incRecHomePage2.Status__c = 'Incident Request';
        incRecHomePage2.Severity__c ='Severity 1';
        incRecHomePage2.Title__c = 'Test Incident 4';
        incRecHomePage2.Summary__c ='Test Summary2';
        incRecHomePage2.Symptoms__c ='Test Symptoms2';
        incRecHomePage2.What_Incident_Criteria_is_Met__c='Test Criteria2';
        incRecHomePage2.Customer_Temperature__c='High';
        incRecHomePage2.How_was_the_issue_detected__c='Customer';
        incRecHomePage2.Customer_Advisory__c='Test Advisory';
        incRecHomePage2.Validation_Override__c = true;
        incidentList.add(incRecHomePage2);
        
        insert incidentList;
        
        // Creating Impacted Accounts
        List<SC_SI_Impacted_Account__c> impAccList = new  List<SC_SI_Impacted_Account__c>();
        SC_SI_Impacted_Account__c impAcc = new SC_SI_Impacted_Account__c();
        impAcc.Account_Name__c = acc.Id;
        impAcc.Service_Incident__c = siRecord.Id;
        impAcc.Validation_Override__c = true;
        impAccList.add(impAcc);
        
        insert impAccList;
        
        // Creating Case
        List<Case> newCaseInsertList = new List<Case>();
        Case newCase = new Case();
        newCase.Subject = 'Test Case';
        newCase.Description = 'TestDescription';
        newCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        newCase.Work_Type__c='Reactive';
        newCase.AccountId = acc.Id;
        newCase.origin='Akamai';
        newcase.Status = 'Assigned';
        newcase.Customer_Temperature__c = 'Medium';
        newcase.Level_of_Impact__c = 'Medium';
        newcase.Case_Product__c = caseProductList[1].Id;
        newcase.Service_Incident__c = siRecord.Id;
        newCaseInsertList.add(newCase);
        insert newCaseInsertList;
        
        // creating EB Products
        List<EB_Product__c> ebProducts = new List<EB_Product__c>();
        
        EB_Product__c newEBProduct = new EB_Product__c();
        newEBProduct.Name='Test EB Product';
        newEBProduct.Product_Name__c='Professional Services (EAA/ETP only)';
        newEBProduct.EB_ProductId__c='M-PC-1234';
        newEBProduct.EB_ProductType__c ='Product';
        ebProducts.add(newEBProduct);
        
        EB_Product__c newEBProduct2 = new EB_Product__c();
        newEBProduct2.Name='Test EB Product 2';
        newEBProduct2.Product_Name__c='Professional Services';
        newEBProduct2.EB_ProductId__c='M-PC-5678';
        newEBProduct2.EB_ParentId__c='M-PC-1234'; 
        newEBProduct2.EB_ProductType__c ='Module';
        ebProducts.add(newEBProduct2);
        
        EB_Product__c newEBProduct3 = new EB_Product__c();
        newEBProduct3.Name='Test EB Product 3';
        newEBProduct3.Product_Name__c='Location Services';
        newEBProduct3.EB_ProductId__c='M-PC-4321';
        newEBProduct3.EB_ParentId__c='M-PC-5678';
        newEBProduct3.EB_ProductType__c ='Submodule';
        ebProducts.add(newEBProduct3);
        
        insert ebProducts;
        
        // Creating Impacted Product
        SC_SI_Impacted_Product__c impactedProd = new SC_SI_Impacted_Product__c();
        impactedProd.Product_Name__c = newEBProduct.Id;
        impactedProd.ParentProductName__c = 'Test Impacted Parent Product';
        impactedProd.Service_Incident__c = siRecord.Id;
        impactedProd.Validation_Override__c = true;
        insert impactedProd;
        
        // creting Task
        List<Task> taskList = new List<Task>();
        Task tsk = new Task();
        tsk.RecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('Service Incident Activity').getRecordTypeId();
        tsk.WhatId = incRec.Id;
        tsk.Subject = 'Test Task';
        tsk.Status = 'In Progress';
        tsk.Type__c = 'External Calls';
        tsk.LOE_hours__c=2;
        taskList.add(tsk);
        
        System.runAs(iraptUser){
            insert tsk;
        }
        
        // Creating External Dependency
        SC_SI_External_Dependency__c extDepRec = new  SC_SI_External_Dependency__c();
        extDepRec.Ticket_Number__c = 'ESESP-1234';
        extDepRec.Type__c = 'Jira';
        extDepRec.Category__c = 'Investigation';
        extDepRec.Service_Incident__c = incRec.Id;
        insert  extDepRec;
        
        //Creating Email Message
        EmailMessage email = new EmailMessage();
        email.FromAddress = 'test@abc.org';
        email.ToAddress= 'test@xyz.org';
        email.Subject = 'Test email';
        email.HtmlBody = 'Test email body';
        email.RelatedToId= incRec.Id;
        // insert email;
        
        //Home Page controller data setup
      
        List<SC_SI_Transition_Request__c> transitionList = new List<SC_SI_Transition_Request__c>();
        List<SC_User_Filter__c> userFilterList = new List<SC_User_Filter__c>();
        
        incidentList[2].ownerId = UserInfo.getUserId();
        incidentList[3].ownerId = [select Id from Group where Name = 'ATS_IRAPT_TRANSITION_QUEUE' and Type = 'Queue' limit 1].Id;
        update incidentList;
     
        SC_SI_Transition_Request__c transitionRec = new SC_SI_Transition_Request__c();
        transitionRec.SC_SI_Service_Incident__c = incidentList[3].Id;
        transitionRec.SC_SI_Notes__c = 'test notes';
        transitionRec.SC_SI_Target_Shift__c = 'EMEA';
        transitionRec.SC_SI_Future_Trigger_Time__c = System.now();
        transitionList.add(transitionRec);
        insert transitionList;
        
        //creating test user filter data
        SC_User_Filter__c filterRec1 = new SC_User_Filter__c();
        filterRec1.recordTypeId = Schema.SObjectType.SC_User_Filter__c.getRecordTypeInfosByName().get('IRAPT').getRecordTypeId();
        filterRec1.Unique_ID__c = UserInfo.getUserId()+'-'+ Schema.SObjectType.SC_User_Filter__c.getRecordTypeInfosByName().get('IRAPT').getRecordTypeId();
        filterRec1.Filter_Values__c='{"Status":["All","Incident Request","In Progress","Mitigated","Resolved"],"Severity":["All","Sev1","Sev2","Sev3","Sev4"],"Queue":["Transition Queue"],"FilterStatusUI_save":[{"UI_Value":"All","isEnabled":true},{"UI_Value":"Incident Request","isEnabled":true},{"UI_Value":"In Progress","isEnabled":true},{"UI_Value":"Mitigated","isEnabled":true},{"UI_Value":"Resolved","isEnabled":true}],"FilterSeverityUI_save":[{"UI_Value":"All","isEnabled":true},{"UI_Value":"Sev1","isEnabled":true},{"UI_Value":"Sev2","isEnabled":true},{"UI_Value":"Sev3","isEnabled":true},{"UI_Value":"Sev4","isEnabled":true}],"FilterQueueUI_save":[{"UI_Value":"All Queues","isEnabled":false},{"UI_Value":"Incidents in Queue","isEnabled":false},{"UI_Value":"Transition Queue","isEnabled":true}]}'; 
        userFilterList.add(filterRec1);
        insert userFilterList;
        
    }
    
    @isTest
    public static void ButtonComp_Test()
    {
        Test.startTest();
        // Fetching Service Incident
        SC_SI_Service_Incident__c siRec = [Select id from SC_SI_Service_Incident__c where Title__c = 'Test Incident 1'];
        // Fetching Case Products
        EB_AccountProductMap__c caseProd = [Select id from EB_AccountProductMap__c where Name = 'Test Case Product'];
        // Fetching Case
        Case cs = [Select Id, Service_Incident__c from Case where Subject='Test Case'];
        // Fetching EB Products
        // changes by Vandhana for ESESP-6174 Code Scan
        List<EB_Product__c> ebProds = [Select id, Name, Product_Name__c, EB_ProductId__c, EB_ParentId__c 
                                        from EB_Product__c
                                        LIMIT 5];
        
        SC_SI_PageLayoutButton_Controllor.IncidentWrapper_Community commIncWrapper = new  SC_SI_PageLayoutButton_Controllor.IncidentWrapper_Community();
        commIncWrapper.customer_Advisory='Test Advisory';
        commIncWrapper.timeValue = system.now().formatGMT('d MMM yyyy HH:mm');
        commIncWrapper.status='Incident Request';
        
        // Creating Wrappers for Impacted Product releated methods
        SC_SI_PageLayoutButton_Controllor.productWrapper prodWrapper = new SC_SI_PageLayoutButton_Controllor.productWrapper();
        prodWrapper.entitledId=ebProds[1].Id;
        prodWrapper.name=ebProds[0].Name;
        prodWrapper.productId=ebProds[0].EB_ProductId__c;
        prodWrapper.items=null;
        
        List<SC_SI_PageLayoutButton_Controllor.Items> itemsWrap = new List<SC_SI_PageLayoutButton_Controllor.Items>();
        
        SC_SI_PageLayoutButton_Controllor.Items prodWrap = new SC_SI_PageLayoutButton_Controllor.Items();
        prodWrap.entitledId=ebProds[0].Id;
        prodWrap.name=ebProds[0].Name;
        prodWrap.productId=ebProds[0].EB_ProductId__c;
        itemsWrap.add(prodWrap);
        
        SC_SI_PageLayoutButton_Controllor.Items prodWrap2 = new SC_SI_PageLayoutButton_Controllor.Items();
        prodWrap2.entitledId=ebProds[1].Id;
        prodWrap2.name=ebProds[1].Name;
        prodWrap2.productId=ebProds[1].EB_ProductId__c;
        prodWrap2.parentProductName=ebProds[0].Name;
        prodWrap2.parentProdId=ebProds[0].EB_ProductId__c;
        itemsWrap.add(prodWrap2);
        
        SC_SI_PageLayoutButton_Controllor.Items prodWrap3 = new SC_SI_PageLayoutButton_Controllor.Items();
        prodWrap3.entitledId=ebProds[2].Id;
        prodWrap3.name=ebProds[2].Name;
        prodWrap3.productId=ebProds[2].EB_ProductId__c;
        prodWrap3.parentModuleName=ebProds[1].Name;
        prodWrap3.parentModProdId=ebProds[1].EB_ProductId__c;
        prodWrap3.parentProductName=ebProds[0].Name;
        prodWrap3.parentProdId=ebProds[0].EB_ProductId__c;
        prodWrap3.items=null;
        itemsWrap.add(prodWrap3);
        
        // Calling Methods in SC_SI_PageLayoutButton_Controllor Class
        
        // Calling Community Methods
        SC_SI_PageLayoutButton_Controllor.getDataForCommunity(siRec.Id,'Create Community Post');
        SC_SI_PageLayoutButton_Controllor.syncFeedItem('<p>Test Community Post</p><p><img src="https://akamai--scdevmay20--c.documentforce.com/servlet/rtaImage?refid=0EM2g0000000m0t"></p>',siRec.Id,'Create Community Post');
        SC_SI_PageLayoutButton_Controllor.getDataForCommunity(siRec.Id,'Update Community Post');
        SC_SI_PageLayoutButton_Controllor.syncFeedItem('<p>Test Community Post</p><p><img src="https://akamai--scdevmay20--c.documentforce.com/servlet/rtaImage?refid=0EM2g0000000m0t"></p>',siRec.Id,'Update Community Post');
        
        //Calling Case Related list Methods
        SC_SI_PageLayoutButton_Controllor.fetchAllRelatedCases(siRec.Id);
        SC_SI_PageLayoutButton_Controllor.deLinkSIRecords(cs.Id);
        
        // Calling Impacted Product Methods
        SC_SI_PageLayoutButton_Controllor.getGridData();
        SC_SI_PageLayoutButton_Controllor.saveImpactedProducts(siRec.Id, itemsWrap);
        Test.stopTest();
        
    }
    @isTest
    public static void ButtonComp2_Test()
    {
        Test.startTest();
        // Fetching the Case
        Case cs = [Select Id, Service_Incident__c from Case where Subject='Test Case'];
        // Fetching Service Incidents
        // changes by Vandhana for ESESP-6174 Code Scan
        List<SC_SI_Service_Incident__c> siRecs = [Select id from SC_SI_Service_Incident__c LIMIT 5];
        //Fetching External Dependency
        SC_SI_External_Dependency__c extDepRec = [Select id,Ticket_Number__c from SC_SI_External_Dependency__c limit 1];
        extDepRec.Ticket_Number__c = 'ESESP-3456';
        update extDepRec;
        
        // Calling SC_SI_PageLayoutButton_Controllor Methods
        
        // Calling Button Access Method
        SC_SI_PageLayoutButton_Controllor.getButtonAccess(siRecs[0].Id);
        
        // Calling Link Case to SI methods
        SC_SI_PageLayoutButton_Controllor.updateCaseWithSI(siRecs[0].Id,cs.Id);
        SC_SI_PageLayoutButton_Controllor.updateCaseWithSI(siRecs[1].Id,cs.Id);
        SC_SI_PageLayoutButton_Controllor.addCaseToSI(siRecs[0].Id,cs.Id);
        
        // Transition methods
        SC_SI_PageLayoutButton_Controllor.getCurrentShiftDetails();
        String wakeUpTime = SC_SI_PageLayoutButton_Controllor.wakeUpTimeMethod('EMEA');
        SC_SI_PageLayoutButton_Controllor.saveTransition(String.valueOf(siRecs[0].Id),'test','EMEA','APJ',wakeUpTime,Id.valueOf(UserInfo.getUserId()),Id.valueOf(UserInfo.getUserId()));
        SC_SI_PageLayoutButton_Controllor.saveTransition(String.valueOf(siRecs[0].Id),'test','EMEA','Transition Now',wakeUpTime,Id.valueOf(UserInfo.getUserId()),Id.valueOf(UserInfo.getUserId()));
        
        //Chart method
        SC_SI_PageLayoutButton_Controllor.getAccChartMap(siRecs[0].Id);
        Test.stopTest();
    }
    
    @isTest
    public static void TriggerMethods_Test()
    {
        Test.startTest();
        
        // Fetching Account
        Account acc = [Select Id from Account where Name='TestAccount 2'];
        // Fetching Impacted Account
        SC_SI_Impacted_Account__c impAcc = [Select id,Account_Name__c from SC_SI_Impacted_Account__c limit 1];
        // Fetching Impacted Product
        SC_SI_Impacted_Product__c impProd = [Select id from SC_SI_Impacted_Product__c limit 1];
        // Fetching Task
        List<Task> taskList = [Select id from Task where Subject='Test Task'];
        // Fetching Service Incidents
        SC_SI_Service_Incident__c siRecs = [Select id from SC_SI_Service_Incident__c where Title__c = 'Test Incident 1' ];
        
        // Updating Impacted Account
        impAcc.Account_Name__c = acc.Id;
        update impAcc;
        
        // Deleting Task for Task LOE Logic on after delete
        delete taskList;
        
        // Deleting Impacted Account for restricting deletion for Non-Irapt user on before delete
        system.runAs(nonIraptUser){
            try{
                SC_SI_Utility.byPassImpAccTrigger=false;
                delete impAcc;
            }
            catch(exception e){
                system.debug(e.getMessage());
            }
        }
        
        
        
        // Deleting Impacted Product for restricting deletion for Non-Irapt user on before delete
        system.runAs(nonIraptUser){
            try{
                SC_SI_Utility.byPassImpProdTrigger=false;
                delete impProd;
            }
            catch(exception e){
                system.debug(e.getMessage());
            }
        }
        
        // Deleting Service Incident for restricting deletion on before delete
        try{
            delete siRecs;
        }
        catch(exception e){
            system.debug(e.getMessage());
        }
        
        Test.stopTest();
        
    }
    
    @isTest
    public static void UtilityMethods_Test()
    {
        // changes by Vandhana for ESESP-6174 Code Scan
        List<SC_SI_Service_Incident__c> siList = [Select Id from SC_SI_Service_Incident__c LIMIT 1];
        List<BMCServiceDesk__Incident__c> BMCIncidents = [Select Id from BMCServiceDesk__Incident__c LIMIT 1];
        Test.startTest();
        //Email related list method
        SC_SI_Utility.getEmailRelatedListData(siList[0].Id);
        
        //fetch lookup result method
        SC_SI_Utility.fetchLookUpValues('test', 'User');
        SC_SI_Utility.fetchLookUpValues('test', 'SC_SI_Service_Incident__c');
        
        //redirection controller method (require BMC data setup in test setup method)
        SC_SI_Utility.lightningRedirectionController(BMCIncidents[0].Id);
        
        // redirection method for VF page (require BMC data setup in test setup method)
        ApexPages.StandardController sc = new ApexPages.StandardController(BMCIncidents[0]);
        SC_SI_Utility testAccPlan = new SC_SI_Utility(sc);
        PageReference pageRef = Page.SC_SI_RedirectionPage; // Add your VF page Name here
        pageRef.getParameters().put('id', String.valueOf(BMCIncidents[0].Id));
        Test.setCurrentPage(pageRef);
        testAccPlan.Redirect(); 
        Test.stopTest();
    }
    
    @isTest
    public static void UserPermissionSet_Test()
    {
        Test.startTest();
        
        // Creating Irapt User
        Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        
        User iraptUser = new User(Alias = 'testSI', Email='testSIUser@akamai.com', 
                                  EmailEncodingKey='UTF-8', LastName='testSIUser', LanguageLocaleKey='en_US', 
                                  LocaleSidKey='en_US', ProfileId = p.Id, 
                                  TimeZoneSidKey='America/Los_Angeles', UserName='testSIUser@akamai.com',SC_SI_IRAPT_User__c=true);
        insert iraptUser;
        
        // Updating User
        iraptUser.SC_SI_IRAPT_User__c=false;
        update iraptUser;
        
        Test.stopTest();
        
    }
    
    @isTest
    Public static void testEmailHandler(){
        Test.startTest();
        
            SC_SI_Email_Config__c newEmailConfig = new SC_SI_Email_Config__c();
            newEmailConfig.To_Email_Address__c = 'Test@akamai.com';
            newEmailConfig.CC_Email_Address__c = 'Test@akamai.com';
            newEmailConfig.BCC_Email_Address__c = 'Test@akamai.com';
            Insert newEmailConfig;
        
            Messaging.InboundEmail email = new Messaging.InboundEmail() ;
            Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
            SC_SI_Service_Incident__c incidentRecord = [Select Id, Name from SC_SI_Service_Incident__c Limit 1];
            email.subject = 'Test Email Service ['+ incidentRecord.Name + ']' ;
            email.fromAddress = 'someaddress@email.com';
            email.htmlBody  = 'email body/n2225256325/nTitle Account ID:TestData';
            email.ToAddresses = new List<String>{'someaddress@email.com'};
            email.fromname = 'Test User';
            email.plainTextBody = 'Test Body';
            email.ccAddresses = new List<String>{'someaddress@email.com'};
            SC_SI_EmailHandler  testInbound = new SC_SI_EmailHandler();
            testInbound.handleInboundEmail(email, env);
        Test.stopTest();
    }
    
    @isTest
    Public static void testDataMigrationBatch(){
        Test.startTest();
            SC_SI_IncidentMigration_Batch batchClass = new SC_SI_IncidentMigration_Batch(1);
            Database.executeBatch(batchClass);
            
            SC_SI_IncidentMigration_Batch batchClass2 = new SC_SI_IncidentMigration_Batch(2);
            Database.executeBatch(batchClass2);
        Test.stopTest();
    }
    
    
     @isTest
    Public static void testBusinessExec(){
        Test.startTest();
            SC_SI_Email_Config__c newEmailConfig = new SC_SI_Email_Config__c();
            newEmailConfig.Email_Ids_for_Sev_1__c = 'Test@akamai.com';
            newEmailConfig.Email_Ids_for_Sev_2__c = 'Test@akamai.com';
            newEmailConfig.Email_Ids_for_Sev_3__c = 'Test@akamai.com';
            Insert newEmailConfig;
        
            SC_SI_Business_Excecutive__c newBE = new SC_SI_Business_Excecutive__c();
            newBE.Email_Config__c = newEmailConfig.Id;
            newBE.User__c = iraptUser.Id;
            Insert newBE;
        
            Delete newBE;
        Test.stopTest();
    }
    
       @isTest
    public static void testHomePageController()
    {   
        // changes by Vandhana for ESESP-6174 Code Scan
        List<SC_SI_Service_Incident__c> siList = [Select Id,ownerId from SC_SI_Service_Incident__c LIMIT 5];
        List<SC_User_Filter__c> userFilterRecList = [Select Id from SC_User_Filter__c LIMIT 1];
        List<SC_SI_Transition_Request__c>  transitionRecords = [Select Id from SC_SI_Transition_Request__c LIMIT 1];  
        
        String json_status = '[{"UI_Value":"All","isEnabled":true},{"UI_Value":"Incident Request","isEnabled":true},{"UI_Value":"In Progress","isEnabled":true},{"UI_Value":"Mitigated","isEnabled":true},{"UI_Value":"Resolved","isEnabled":true}]';
        String json_severity = '[{"UI_Value":"All","isEnabled":true},{"UI_Value":"Sev1","isEnabled":true},{"UI_Value":"Sev2","isEnabled":true},{"UI_Value":"Sev3","isEnabled":true},{"UI_Value":"Sev4","isEnabled":true}]';
        String json_queue = '[{"UI_Value":"All Queues","isEnabled":true},{"UI_Value":"Incidents in Queue","isEnabled":true},{"UI_Value":"Transition Queue","isEnabled":true}]';
        
        
     
        Test.startTest();
            try{
            SC_SI_HomePageControllor.getHomePageData(true,'');
            SC_SI_HomePageControllor.getHomePageData(false,'Incidents In Queue');
            SC_SI_HomePageControllor.updateOwner(siList[2].Id);
            SC_SI_HomePageControllor.updateOwner(userFilterRecList[0].Id);
            SC_SI_HomePageControllor.getFilterData(true, 'Incidents In Queue', new List<String>{'All'},new List<String>{'All'}, new List<String>{'All Queues'});
            SC_SI_HomePageControllor.saveFilterData(true,new List<String>{'All'},new List<String>{'All'}, new List<String>{'All Queues'},json_status,json_severity,json_queue);
            
            transitionRecords[0].SC_SI_Completed__c = true;
            transitionRecords[0].SC_SI_Completed_Date__c = System.now();
            update transitionRecords[0];
            delete transitionRecords[0];
            siList[3].ownerId = UserInfo.getUserId();
            update siList;
            }catch(Exception e){
                String message = e.getMessage();
                Boolean expectedExceptionThrown = message.contains('Transition Records can not be deleted') ? true : false;
                System.assertEquals(expectedExceptionThrown, true);
            }    
            
        Test.stopTest();
     } 
    
    @isTest
    public static void testUserPSAssignment(){
        Test.startTest();
            
            String userName1 = utilTestClass.getRandomString(8);
            String userName2 = utilTestClass.getRandomString(8);
            
            Id profileId = [SELECT Id FROM Profile WHERE Name = 'Support - Tech Support Agent'].Id;
            List<User> userList = new List<User>();
            User eachUser1 = new User(
            Username=''+userName1+'@akamai.com',
                        Alias = userName1, 
                        Email=''+userName1+'@akamai.com', 
                        FirstName='John', 
                        LastName='Doe'+userName1, 
                        ProfileId = profileId, 
                        LanguageLocaleKey='en_US', 
                        LocaleSidKey='en_US', 
                        EmailEncodingKey='UTF-8', 
                        TimeZoneSidKey='America/Los_Angeles',
                        SC_SI_IRAPT_User__c = True);
            userList.add(eachUser1);
        
            User eachUser2 = new User(
                Username=''+userName2+'@akamai.com',
                            Alias = userName2, 
                            Email=''+userName2+'@akamai.com', 
                            FirstName='John', 
                            LastName='Doe'+userName1, 
                            ProfileId = profileId, 
                            LanguageLocaleKey='en_US', 
                            LocaleSidKey='en_US', 
                            EmailEncodingKey='UTF-8', 
                            TimeZoneSidKey='America/Los_Angeles',
                            SC_SI_IRAPT_User__c = False);
            userList.add(eachUser2);
        
            Insert userList;
            SC_SI_Utility.AssignPermissionSet(new List<Id>{userList[0].Id}, new List<Id>{userList[1].Id}, False);
            userList[0].SC_SI_IRAPT_User__c = False;
            userList[1].SC_SI_IRAPT_User__c = True;
            Update userList;
            SC_SI_Utility.AssignPermissionSet(new List<Id>{userList[1].Id}, new List<Id>{userList[0].Id}, True);
        
        Test.stopTest();
        
    }
    
    @isTest
    public static void testApexLinkRedirection(){
        List<SC_SI_Service_Incident__c> siList = [Select Id,Name from SC_SI_Service_Incident__c];
        Test.startTest();
            PageReference newPage = Page.serviceincident;
            Test.setCurrentPageReference(newPage);
            newPage.getParameters().put('Id', siList[0].Name);
            newPage.getParameters().put('Id', '');
            SC_SI_Utility rc = new SC_SI_Utility();
            rc.getGetLocation();
                
 
        Test.stopTest();
    }    
    
}