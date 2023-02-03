/*****************************************************************************
 * Name             : Test_EmailToCaseHandler
 * Created By       : Pitamber Sharma
 * Created Date     : 17-May-2013
 * Purpose          : Test Class for EmailToCaseHandler
 * 22-Apr-14        : avidapan - Optimization of Test class
 * 02-Mar-15        : Jay - Optimization of Test class
 * 02-Aug-16        : Vamsee - Commented the custom setting creation code to make seeAllData = true
 * 05-Oct-16        : Vamsee - Added new methods to increase the code coverage
 * 13-Apr-17        : Vandhana Krishnamurthy - Increase code coverage
 * 31-May-17        : Pinkesh - Added new methods to increase the code coverage
 * 1-Mar-18         : Vandhana - Added testMethod for Nominum changes
 * 29-Mar-19        : Sumanth - Added test method for SecLaw,SecSales and Salesforce Bounce forwarder functionality
 * 22-Oct-19        : Pinkesh - ESESP-2476   Setting correct Content-Type on the attachments
 *****************************************************************************/   
@isTest(seeAllData = false)
private class Test_EmailToCaseHandler {
    /*
    static { 
    
       list<SObject> lSObjects = new list<SObject>(); 
       utilTestClass.createCustomSettings();
       SCRecordTypeCustomSetting__c varSCRTCS = new SCRecordTypeCustomSetting__c();
       varSCRTCS.RecordTypeName__c = 'Technical,AMG,Billing,GSS CSAT,Emerging Products Engineering,Managed Security';
       varSCRTCS.Name = 'EmailToCaseRT';
       lSObjects.add(varSCRTCS);
        
       SCRecordTypeCustomSetting__c varSCRTCS1 = new SCRecordTypeCustomSetting__c();
       varSCRTCS1.RecordTypeDeveloperName__c = 'Technical,AMG,Billing,GSS CSAT,Emerging Products Engineering,Managed Security';
       varSCRTCS1.Name = 'ReopenRT';
       lSObjects.add(varSCRTCS1);
        
        

       SC_FromEmailAddress__c varSCFromEmailAdd = new SC_FromEmailAddress__c();
       varSCFromEmailAdd.Name = 'ProlexicFromEmailAddress';
       varSCFromEmailAdd.FromAddress__c = 'all@all.com';
       lSObjects.add(varSCFromEmailAdd); 
       
       EmailHandler_CS__c varEmailHandlerCS1 = new EmailHandler_CS__c(); 
       varEmailHandlerCS1.Name = 'billing';
       varEmailHandlerCS1.Email_Address__c = 'billing@akamai.com';
       varEmailHandlerCS1.Record_Type__c = 'Billing'; 
       lSObjects.add(varEmailHandlerCS1);
       
       EmailHandler_CS__c varEmailHandlerCS2 = new EmailHandler_CS__c(); 
       varEmailHandlerCS2.Name = 'care-att';
       varEmailHandlerCS2.Email_Address__c = 'ccare-att@akamai.com';
       varEmailHandlerCS2.Record_Type__c = 'Technical'; 
       lSObjects.add(varEmailHandlerCS2);
       
       EmailHandler_CS__c varEmailHandlerCS3 = new EmailHandler_CS__c(); 
       varEmailHandlerCS3.Name = 'ccare';
       varEmailHandlerCS3.Email_Address__c = 'ccare@akamai.com';
       varEmailHandlerCS3.Record_Type__c = 'Technical'; 
       lSObjects.add(varEmailHandlerCS3);
        
       EmailHandler_CS__c varEmailHandlerCS4 = new EmailHandler_CS__c(); 
       varEmailHandlerCS4.Name = 'ccare-att';
       varEmailHandlerCS4.Email_Address__c = 'ccare-att@akamai.com';
       varEmailHandlerCS4.Record_Type__c = 'Technical'; 
       lSObjects.add(varEmailHandlerCS4);
        
       EmailHandler_CS__c varEmailHandlerCS5 = new EmailHandler_CS__c(); 
       varEmailHandlerCS5.Name = 'client-endusersupport';
       varEmailHandlerCS5.Email_Address__c = 'client-endusersupport@akamai.com';
       varEmailHandlerCS5.Record_Type__c = 'Technical'; 
       lSObjects.add(varEmailHandlerCS5);
       
       EmailHandler_CS__c varEmailHandlerCS6 = new EmailHandler_CS__c(); 
       varEmailHandlerCS6.Name = 'CustomerCare';
       varEmailHandlerCS6.Email_Address__c = 'customercare@akamai.com';
       varEmailHandlerCS6.Record_Type__c = 'Technical'; 
       lSObjects.add(varEmailHandlerCS6);
        
       EmailHandler_CS__c varEmailHandlerCS7 = new EmailHandler_CS__c(); 
       varEmailHandlerCS7.Name = 'Emerging Product Group';
       varEmailHandlerCS7.Email_Address__c = 'epe-support@akamai.com';
       varEmailHandlerCS7.Record_Type__c = 'Emerging Products Engineering'; 
       lSObjects.add(varEmailHandlerCS7); 
       
       EmailHandler_CS__c varEmailHandlerCS8 = new EmailHandler_CS__c(); 
       varEmailHandlerCS8.Name = 'portal-feedback';
       varEmailHandlerCS8.Email_Address__c = 'portal-feedback@akamai.com';
       varEmailHandlerCS8.Record_Type__c = 'Technical'; 
       lSObjects.add(varEmailHandlerCS8); 
       
       EmailHandler_CS__c varEmailHandlerCS9 = new EmailHandler_CS__c(); 
       varEmailHandlerCS9.Name = 'prolexic';
       varEmailHandlerCS9.Email_Address__c = 'prolexic@akamai.com';
       varEmailHandlerCS9.Record_Type__c = 'Managed Security'; 
       lSObjects.add(varEmailHandlerCS9);
       
       EmailHandler_CS__c varEmailHandlerCS10 = new EmailHandler_CS__c(); 
       varEmailHandlerCS10.Name = 'specialist';
       varEmailHandlerCS10.Email_Address__c = 'specialist@akamai.com';
       varEmailHandlerCS10.Record_Type__c = 'AMG'; 
       lSObjects.add(varEmailHandlerCS10);
       
       EmailHandler_CS__c varEmailHandlerCS11 = new EmailHandler_CS__c(); 
       varEmailHandlerCS11.Name = 'ps-tix';
       varEmailHandlerCS11.Email_Address__c = 'ps-tix@akamai.com';
       varEmailHandlerCS11.Record_Type__c = 'Technical'; 
       lSObjects.add(varEmailHandlerCS11);
        
       EmailHandler_CS__c varEmailHandlerCS12 = new EmailHandler_CS__c(); 
       varEmailHandlerCS12.Name = 'support';
       varEmailHandlerCS12.Email_Address__c = 'support@akamai.com';
       varEmailHandlerCS12.Record_Type__c = 'Technical'; 
       lSObjects.add(varEmailHandlerCS12); 
        
       EmailHandler_CS__c varEmailHandlerCS13 = new EmailHandler_CS__c(); 
       varEmailHandlerCS13.Name = 'ManagedSecurity';
       varEmailHandlerCS13.Email_Address__c = 'managedsecurity@akamai.com';
       varEmailHandlerCS13.Record_Type__c = 'Managed Security'; 
       lSObjects.add(varEmailHandlerCS13);

       EmailHandler_CS__c varEmailHandlerCS14 = new EmailHandler_CS__c(); 
       varEmailHandlerCS14.Name = '911prolexic';
       varEmailHandlerCS14.Email_Address__c = '911@prolexic.com';
       varEmailHandlerCS14.Record_Type__c = 'Managed Security'; 
       lSObjects.add(varEmailHandlerCS14);
        
       SCUserIdCustomSetting__c varSCUSerIdCS = new SCUserIdCustomSetting__c();
       varSCUSerIdCS.Name = 'LunaPortalIntegration';
       varSCUSerIdCS.UserId__c = '005G0000003dnrRIAQ';
       lSObjects.add(varSCUSerIdCS);
       
       SurveyEmailHandler_CS__c varSurveyEmailCS1 = new SurveyEmailHandler_CS__c();
       varSurveyEmailCS1.Name = 'Billing Survey';
       varSurveyEmailCS1.Email_Address__c = 'billing_survey_feedback@akamai.com';
       lSObjects.add(varSurveyEmailCS1);
        
       SurveyEmailHandler_CS__c varSurveyEmailCS2 = new SurveyEmailHandler_CS__c();
       varSurveyEmailCS2.Name = 'ccare';
       varSurveyEmailCS2.Email_Address__c = 'ccare@akamai.com';
       lSObjects.add(varSurveyEmailCS2);
        
       SurveyEmailHandler_CS__c varSurveyEmailCS3 = new SurveyEmailHandler_CS__c();
       varSurveyEmailCS3.Name = 'specialist';
       varSurveyEmailCS3.Email_Address__c = 'specialist@akamai.com';
       lSObjects.add(varSurveyEmailCS3); 
        
       System.runas(new User(Id = Userinfo.getUserId())){ 
           insert lSObjects;
           
           Environment_Setup__c setting = Environment_Setup__c.getOrgDefaults();
    setting.Active_Org__c = true;
    update setting;
       }
    }*/
    //Creates the test data 
    @testSetup static void createTestData() {
        //SCUtilTestClass.createCustomSettingsForCase();
        List<SC_FromEmailAddress__c> FromEmails = new List<SC_FromEmailAddress__c>();
        list<SObject> lSObjects = new list<SObject>();

        User tmpUser = utilTestClass.CreateUser('tmUser1', 'Sales Operations', 'Sales Operations');
        insert tmpUser;

        System.runAs(tmpUser){
            utilTestClass.createCustomSettings();

            SCRecordTypeCustomSetting__c varSCRTCS = new SCRecordTypeCustomSetting__c();
            varSCRTCS.RecordTypeName__c = 'Technical,AMG,Billing,GSS CSAT,Emerging Products Engineering,Managed Security,SecLaw,SecSales,CMG';
            varSCRTCS.Name = 'EmailToCaseRT';
            lSObjects.add(varSCRTCS);

            SCRecordTypeCustomSetting__c varSCRTCS1 = new SCRecordTypeCustomSetting__c();
            varSCRTCS1.RecordTypeDeveloperName__c = 'Technical,AMG,Billing,GSS CSAT,Emerging Products Engineering,Managed Security';
            varSCRTCS1.Name = 'ReopenRT';
            lSObjects.add(varSCRTCS1);

            OrgWideEmailAddress owa = [select id, Address from OrgWideEmailAddress where DisplayName='Akamai Case Notification' LIMIT 1];

            SC_FromEmailAddress__c varSCFromEmailAdd = new SC_FromEmailAddress__c();
            varSCFromEmailAdd.Name = 'ProlexicFromEmailAddress';
            varSCFromEmailAdd.FromAddress__c = 'all@all.com';
            lSObjects.add(varSCFromEmailAdd);
            SC_FromEmailAddress__c varSCFromEmailAdd2 = new SC_FromEmailAddress__c();
            varSCFromEmailAdd2.Name = 'PortalWMFromEmailAddress';
            varSCFromEmailAdd2.FromAddress__c = 'mytjykjkstuob@rcgoskkd.com';
            lSObjects.add(varSCFromEmailAdd2);
            SC_FromEmailAddress__c varSCFromEmailAdd3 = new SC_FromEmailAddress__c();
            varSCFromEmailAdd3.Name = 'CMPFromEmailAddress';
            varSCFromEmailAdd3.FromAddress__c = 'fnejltkulyxpas@qyanmjco.com';
            lSObjects.add(varSCFromEmailAdd3);
            SC_FromEmailAddress__c varSCFromEmailAdd4 = new SC_FromEmailAddress__c();
            varSCFromEmailAdd4.Name = 'auto-reply';
            varSCFromEmailAdd4.OrgAddressId__c = owa.id;
            lSObjects.add(varSCFromEmailAdd4);
            SC_FromEmailAddress__c varSCFromEmailAdd5 = new SC_FromEmailAddress__c();
            varSCFromEmailAdd5.Name = 'CMG';
            OrgWideEmailAddress CMG_owa = [select id from OrgWideEmailAddress where DisplayName='Contract Management Group' LIMIT 1];
            varSCFromEmailAdd5.OrgAddressId__c = CMG_owa.id;
            lSObjects.add(varSCFromEmailAdd5);


            EmailHandler_CS__c varEmailHandlerCSs11 = new EmailHandler_CS__c();
            varEmailHandlerCSs11.Name = 'Xerocole';
            varEmailHandlerCSs11.Email_Address__c = 'Xerocolea@akamaia.com';
            varEmailHandlerCSs11.Record_Type__c = 'Xerocole';
            lSObjects.add(varEmailHandlerCSs11);

            EmailHandler_CS__c varEmailHandlerCSs13 = new EmailHandler_CS__c();
            varEmailHandlerCSs13.Name = 'Nominum';
            varEmailHandlerCSs13.Email_Address__c = 'Nominum@akamaia.com';
            varEmailHandlerCSs13.Record_Type__c = 'Nominum';
            lSObjects.add(varEmailHandlerCSs13);

            EmailHandler_CS__c varEmailHandlerCSs14 = new EmailHandler_CS__c();
            varEmailHandlerCSs14.Name = 'SecLaw';
            varEmailHandlerCSs14.Email_Address__c = 'SecLaw@akamaia.com';
            varEmailHandlerCSs14.Record_Type__c = 'SecLaw';
            lSObjects.add(varEmailHandlerCSs14);

            EmailHandler_CS__c varEmailHandlerCSs12 = new EmailHandler_CS__c();
            varEmailHandlerCSs12.Name = 'Encoder Qualification';
            varEmailHandlerCSs12.Email_Address__c = 'Xerssocolea@akamaia.com';
            varEmailHandlerCSs12.Record_Type__c = 'Encoder';
            lSObjects.add(varEmailHandlerCSs12);

            EmailHandler_CS__c varEmailHandlerCSs15 = new EmailHandler_CS__c();
            varEmailHandlerCSs15.Name = 'AMP';
            varEmailHandlerCSs15.Email_Address__c = 'ssocolea@akamaia.com';
            varEmailHandlerCSs15.Record_Type__c = 'AMP';
            lSObjects.add(varEmailHandlerCSs15);

            EmailHandler_CS__c varEmailHandlerCSs16 = new EmailHandler_CS__c();
            varEmailHandlerCSs16.Name = 'soasta';
            varEmailHandlerCSs16.Email_Address__c = 'soasta@akamaia.com';
            varEmailHandlerCSs16.Record_Type__c = 'soasta';
            lSObjects.add(varEmailHandlerCSs16);

            EmailHandler_CS__c varEmailHandlerCS1 = new EmailHandler_CS__c();
            varEmailHandlerCS1.Name = 'billing';
            varEmailHandlerCS1.Email_Address__c = 'billing@akamai.com';
            varEmailHandlerCS1.Record_Type__c = 'Billing';
            lSObjects.add(varEmailHandlerCS1);

            EmailHandler_CS__c varEmailHandlerCS2 = new EmailHandler_CS__c();
            varEmailHandlerCS2.Name = 'care-att';
            varEmailHandlerCS2.Email_Address__c = 'ccare-att@akamai.com';
            varEmailHandlerCS2.Record_Type__c = 'Technical';
            lSObjects.add(varEmailHandlerCS2);

            EmailHandler_CS__c varEmailHandlerCS3 = new EmailHandler_CS__c();
            varEmailHandlerCS3.Name = 'ccare';
            varEmailHandlerCS3.Email_Address__c = 'ccare@akamai.com';
            varEmailHandlerCS3.Record_Type__c = 'Technical';
            lSObjects.add(varEmailHandlerCS3);

            EmailHandler_CS__c varEmailHandlerCS4 = new EmailHandler_CS__c();
            varEmailHandlerCS4.Name = 'ccare-att';
            varEmailHandlerCS4.Email_Address__c = 'ccare-att@akamai.com';
            varEmailHandlerCS4.Record_Type__c = 'Technical';
            lSObjects.add(varEmailHandlerCS4);

            EmailHandler_CS__c varEmailHandlerCS5 = new EmailHandler_CS__c();
            varEmailHandlerCS5.Name = 'client-endusersupport';
            varEmailHandlerCS5.Email_Address__c = 'client-endusersupport@akamai.com';
            varEmailHandlerCS5.Record_Type__c = 'Technical';
            lSObjects.add(varEmailHandlerCS5);

            EmailHandler_CS__c varEmailHandlerCS6 = new EmailHandler_CS__c();
            varEmailHandlerCS6.Name = 'CustomerCare';
            varEmailHandlerCS6.Email_Address__c = 'customercare@akamai.com';
            varEmailHandlerCS6.Record_Type__c = 'Technical';
            lSObjects.add(varEmailHandlerCS6);

            EmailHandler_CS__c varEmailHandlerCS7 = new EmailHandler_CS__c();
            varEmailHandlerCS7.Name = 'Emerging Product Group';
            varEmailHandlerCS7.Email_Address__c = 'epe-support@akamai.com';
            varEmailHandlerCS7.Record_Type__c = 'Emerging Products Engineering';
            lSObjects.add(varEmailHandlerCS7);

            EmailHandler_CS__c varEmailHandlerCS8 = new EmailHandler_CS__c();
            varEmailHandlerCS8.Name = 'portal-feedback';
            varEmailHandlerCS8.Email_Address__c = 'portal-feedback@akamai.com';
            varEmailHandlerCS8.Record_Type__c = 'Technical';
            lSObjects.add(varEmailHandlerCS8);

            EmailHandler_CS__c varEmailHandlerCS9 = new EmailHandler_CS__c();
            varEmailHandlerCS9.Name = 'prolexic';
            varEmailHandlerCS9.Email_Address__c = 'prolexic@akamai.com';
            varEmailHandlerCS9.Record_Type__c = 'Managed Security';
            lSObjects.add(varEmailHandlerCS9);

            EmailHandler_CS__c varEmailHandlerCS10 = new EmailHandler_CS__c();
            varEmailHandlerCS10.Name = 'specialist';
            varEmailHandlerCS10.Email_Address__c = 'specialist@akamai.com';
            varEmailHandlerCS10.Record_Type__c = 'AMG';
            lSObjects.add(varEmailHandlerCS10);

            EmailHandler_CS__c varEmailHandlerCS11 = new EmailHandler_CS__c();
            varEmailHandlerCS11.Name = 'ps-tix';
            varEmailHandlerCS11.Email_Address__c = 'ps-tix@akamai.com';
            varEmailHandlerCS11.Record_Type__c = 'Technical';
            lSObjects.add(varEmailHandlerCS11);

            EmailHandler_CS__c varEmailHandlerCS12 = new EmailHandler_CS__c();
            varEmailHandlerCS12.Name = 'support';
            varEmailHandlerCS12.Email_Address__c = 'support@akamai.com';
            varEmailHandlerCS12.Record_Type__c = 'Technical';
            lSObjects.add(varEmailHandlerCS12);

            EmailHandler_CS__c varEmailHandlerCS13 = new EmailHandler_CS__c();
            varEmailHandlerCS13.Name = 'ManagedSecurity';
            varEmailHandlerCS13.Email_Address__c = 'managedsecurity@akamai.com';
            varEmailHandlerCS13.Record_Type__c = 'Managed Security';
            lSObjects.add(varEmailHandlerCS13);

            EmailHandler_CS__c varEmailHandlerCS14 = new EmailHandler_CS__c();
            varEmailHandlerCS14.Name = '911prolexic';
            varEmailHandlerCS14.Email_Address__c = '911@prolexic.com';
            varEmailHandlerCS14.Record_Type__c = 'Managed Security';
            lSObjects.add(varEmailHandlerCS14);

            EmailHandler_CS__c varEmailHandlerCS15 = new EmailHandler_CS__c();
            varEmailHandlerCS15.Name = 'SecSales';
            varEmailHandlerCS15.Email_Address__c = 'SecSales@prolexic.com';
            varEmailHandlerCS15.Record_Type__c = 'SecSales';
            lSObjects.add(varEmailHandlerCS15);

            EmailHandler_CS__c varEmailHandlerCS16 = new EmailHandler_CS__c();
            varEmailHandlerCS16.Name = 'CMG';
            varEmailHandlerCS16.Email_Address__c = 'cmg@akamai.com';
            varEmailHandlerCS16.Record_Type__c = 'CMG';
            lSObjects.add(varEmailHandlerCS16);

            SCUserIdCustomSetting__c varSCUSerIdCS = new SCUserIdCustomSetting__c();
            varSCUSerIdCS.Name = 'LunaPortalIntegration';
            varSCUSerIdCS.UserId__c = tmpUser.Id;
            lSObjects.add(varSCUSerIdCS);

            SurveyEmailHandler_CS__c varSurveyEmailCS1 = new SurveyEmailHandler_CS__c();
            varSurveyEmailCS1.Name = 'Billing Survey';
            varSurveyEmailCS1.Email_Address__c = 'billing_survey_feedback@akamai.com';
            lSObjects.add(varSurveyEmailCS1);

            SurveyEmailHandler_CS__c varSurveyEmailCS2 = new SurveyEmailHandler_CS__c();
            varSurveyEmailCS2.Name = 'ccare';
            varSurveyEmailCS2.Email_Address__c = 'ccare@akamai.com';
            lSObjects.add(varSurveyEmailCS2);

            SurveyEmailHandler_CS__c varSurveyEmailCS3 = new SurveyEmailHandler_CS__c();
            varSurveyEmailCS3.Name = 'specialist';
            varSurveyEmailCS3.Email_Address__c = 'specialist@akamai.com';
            lSObjects.add(varSurveyEmailCS3);

            insert lSObjects;

            SC_SupportEmail__c SC_SupportEmail_Rec;

            SC_SupportEmail_Rec = new SC_SupportEmail__c();
            SC_SupportEmail_Rec.Name = '1';
            SC_SupportEmail_Rec.Default_Task_Owner__c = 'ONA';
            SC_SupportEmail_Rec.Support_Email_AMS__c = 'sc-dev@akamai.com';
            SC_SupportEmail_Rec.Support_Email_AutoGen__c = 'sc-dev@akamai.com';
            SC_SupportEmail_Rec.PartnerCaseEmail__c = 'asfsa@adf.com;adfas@dfad.com';
            insert SC_SupportEmail_Rec;

            SC_Case_Issue_Sync_Admin_Setting__c adminRec =  new SC_Case_Issue_Sync_Admin_Setting__c();
            adminRec.Access_Token_Issues_API__c = '';
            adminRec.Client_Certificate__c = 'EAA_KMI_Signed_Certificate';
            adminRec.Client_Id_Issues_API__c = '90f8e0f1-696b-46f9-a504-3811b8ce00fc';
            adminRec.Client_Secret_Issues_API__c = 'b8a4f2c9-24e5-4d5e-a794-6b98730b6915';
            adminRec.Hostname_Issues_API__c = 'https://qa.dash-ext.akamai.com/';
            adminRec.Oauth_Endpoint_Issues_API__c = 'oauth2/token';
            adminRec.Scope_Issues_API__c = 'network-services/issues/v1/issues/';
            insert adminRec;

            Account thisAccount = utilTestClass.CreateAccount('Test Account for OA');
            insert thisAccount;

            Opportunity opp = utilTestClass.CreateOpportunity('Test Opportuniry for OA','1. Identify Need');
            opp.AccountId = thisAccount.Id;
            opp.CloseDate = Date.today().addMonths(4);
            opp.Validation_Override__c = true;
            insert opp;

        }

    }
    static testMethod void TestinBoundEmail() {
      // create a new email and envelope object
      Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        Account acc = utilTestClass.CreateAccount('Test Acc Random 34');
        insert acc;
        Contact c = new Contact(FirstName = 'ConTest',LastName = 'Test Con', AccountId = acc.Id, email = 'someaddress@email.com',Login__c = 'test login',MailingCountry = 'India', MailingState = 'DELHI');
      insert c;
        Id queueId = [select id from group where type='Queue' and name = 'ATS_Transition_Queue' limit 1].id;
        Case varCase = new Case(Status = 'Unassigned', Origin = 'Email', severity__c = '2', ContactId=c.Id, OwnerId = queueId, Case_Assignment_Using_Active_Rules__c = false);
        insert varCase;
        test.startTest();
      Case cs = [Select Id, CaseNumber, AKAM_Case_ID__c from Case where id =: varCase.Id Limit 1];
        email.subject = 'Test Email Service Case # ' + cs.AKAM_Case_ID__c + ':' + ' [AKAM-CASE #' + cs.AKAM_Case_ID__c + ']' ;
        email.fromAddress = 'someaddress@email.com';
        email.htmlBody  = 'email body/n2225256325/nTitle Account ID:TestData';
        email.ToAddresses = Test_EmailToCaseHandler.toAddresses1();
        email.ccAddresses = new String[]{'test@test.com'};
        //email.ToAddresses = new String[]{'billing@akamai.com','specialist@akamai.com','support@akamai.com','ccare@akamai.com','epe-support@akamai.com','testgggggggggggggggggggg@akamai.com','managedsecurity@akamai.com','customercare@akamai.com','aura-support@akamai.com'};
        // call the email service class and test it with the data in the testMethod
        EmailToCaseHandler.sendEmailToCustomer(email,cs);
        //EmailToCaseHandler.sendEmailToCustomer1(email,cs);
        EmailToCaseHandler  testInbound = new EmailToCaseHandler();
        
        testInbound.handleInboundEmail(email, env);
        test.stopTest();
    }
    //out of office test method handle
    static testmethod void outOfOfficeTestMethod(){
    Messaging.InboundEmail email = new Messaging.InboundEmail() ;
    Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
    test.startTest();
        email.subject = 'out of office # ';
        email.fromAddress = 'someaddress@email.com';
        email.htmlBody  = 'email body/n2225256325/nTitle Account ID:TestData';
        email.ToAddresses = Test_EmailToCaseHandler.toAddresses1();
        email.ccAddresses = new String[]{'test@test.com'};
        EmailToCaseHandler  testInbound = new EmailToCaseHandler();
        
        testInbound.handleInboundEmail(email, env);
        test.stopTest();
    }
    
    
    
    /*static testMethod void TestinBoundEmail1() {
      // create a new email and envelope object
      Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
      // setup the data for the email
        email.subject = 'Test Email Service ' ;
        email.fromAddress = 'someaddress@akamai.com';
        email.htmlBody  = 'email body/n2225256325/nTitle Account ID:TestData';
        email.ToAddresses = Test_EmailToCaseHandler.toAddresses();
        //email.ToAddresses = new String[]{'billing@akamai.com','specialist@akamai.com','support@akamai.com','ps-tix@akamai.com','epe-support@akamai.com','testgggggggggggggggggggg@akamai.com','ccare@akamai.com','managedsecurity@akamai.com','customercare@akamai.com','aura-support@akamai.com'};
        email.ccAddresses = new String[]{'bitestlling@akamai.com'};
        for(integer i =0 ; i< 26;i++){
          email.ToAddresses.add('test'+i+'@test.com;');
        }
        for(integer i =0 ; i< 26;i++){
          email.ccAddresses.add('test'+i+'@test.com;');
        }
         // call the email service class and test it with the data in the testMethod
        test.startTest();
      EmailToCaseHandler  test_Inbound = new EmailToCaseHandler();
        test_Inbound.handleInboundEmail(email, env);
        test.stopTest();
        email.subject = 'testing';
        //Messaging.InboundEmail.BinaryAttachment attBinary1 = new Messaging.InboundEmail.BinaryAttachment();
        Messaging.InboundEmail.BinaryAttachment attBinary = new Messaging.InboundEmail.BinaryAttachment();
        // set the body of the attachment
        //attBinary1.mimeTypeSubType = 'text/plain';
        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] {attBinary};
       //Validate Text Attachments
        Messaging.InboundEmail.TextAttachment attText = new Messaging.InboundEmail.TextAttachment();
      // set the body of the attachment
        attText.body = 'test content';
        attText.mimeTypeSubType = 'text/plain';
      
        //Messaging.InboundEmail.TextAttachment attText1 = new Messaging.InboundEmail.TextAttachment();
        // set the body of the attachment
        //attText1.filename = 'TestTestTestTestTestTestTestTestTestTestTestTestTestTestTestTestTestTestTestTesttTestTestTestTestTestTesttTestTestTestTestTestTest greater then 80 character';
        //attText1.mimeTypeSubType = 'text/plain';
        email.textAttachments = new Messaging.inboundEmail.TextAttachment[] {attText};
        test.stARTTEST();
        EmailToCaseHandler  test_In_bound = new EmailToCaseHandler();
        test_In_bound.handleInboundEmail(email, env);
        TEST.STOPTEST();
        email.subject = 'testing [AKAM-CASE #';
        email.plaintextbody = 'test';
        test.startTest();
        EmailToCaseHandler  test_In_bound_2 = new EmailToCaseHandler();
        test_In_bound_2.handleInboundEmail(email, env);
        test.stopTest();
        email.subject = 'out of office';
        test.startTest();
        EmailToCaseHandler  test_In_bound_3 = new EmailToCaseHandler();
        test_In_bound_3.handleInboundEmail(email, env);
        test.stopTest();
    }*/
    
    static testMethod void testSurveyCaseOne() {
      // create a new email and envelope object
      Messaging.InboundEmail email = new Messaging.InboundEmail() ;
      Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
      System.runAs(new User(id=Userinfo.getUserId())){
            User anyUser = utilTestClass.CreateUser('testUser','CMG','Support - AMG Agent');
      		insert anyUser;
        }
      Account acc = utilTestClass.CreateAccount('Test Acc Random 34');
        acc.Parent_Division__c = 'Web APJ_Web';
        insert acc;
        Test.startTest();
        acc = [select akam_account_id__C from account where id=:acc.id];      
        email.subject = 'Test subject Account ID:TestData';
        email.fromAddress = 'service_desk@feedback.akamai.com';
        email.htmlBody = 'email body/n2225256325/nTitle Account ID: '+acc.akam_account_id__c + '  Manager: ' + 'testUser';
        email.ToAddresses = new String[]{EmailHandler_CS__c.getValues('ccare').Email_Address__c};
        email.ccAddresses = new String[]{'test@test.com'};
        email.headers = new Messaging.InboundEmail.Header[]{new Messaging.InboundEmail.Header()};
      EmailToCaseHandler testInboundSurvey = new EmailToCaseHandler();
        testInboundSurvey.handleInboundEmail(email, env);
        Test.stopTest();
    }
    
    static testMethod void testSurveyCaseTwo() {
      	Account acc = utilTestClass.CreateAccount('Test Acc Random 34');
      	insert acc;
        System.runAs(new User(id=Userinfo.getUserId())){
            User anyUser = utilTestClass.CreateUser('testUser','CMG','Support - AMG Agent');
      		insert anyUser;
        }
        
        acc = [select akam_account_id__C from account where id=:acc.id];
        Contact c = new Contact(FirstName = 'ConTest',LastName = 'Test Con', AccountId = acc.Id, email = 'someaddress@email.com',Login__c = 'test login',MailingCountry = 'India', MailingState = 'DELHI');
        insert c;
        list<string> lParamToSend = new list<string>{'Hello'};
        List<string> lStringToLowerCase = EmailToCaseUtility.convertLowerCase(lParamToSend);
      // create a new email and envelope object
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
      Test.startTest();
        email.subject = 'Test subject Account ID: '+acc.akam_account_id__C+'  Manager: ' + 'testUser';
        email.fromAddress = 'ccare_dsat@feedback.akamai.com';
        email.htmlBody = 'email body/n2225256325/nTitle \n Manager: '+ 'testUser' + '\n'+ 'Account ID: '+acc.akam_account_id__C;
        email.ToAddresses = new String[]{EmailHandler_CS__c.getValues('ccare').Email_Address__c};
        email.ccAddresses = new String[]{'test@test.com'};
        email.headers = new Messaging.InboundEmail.Header[]{new Messaging.InboundEmail.Header()};
      	EmailToCaseHandler testInboundSurvey2 = new EmailToCaseHandler();
        testInboundSurvey2.handleInboundEmail(email, env);
      Test.stopTest();
    } 
    
    static testMethod void TestinBoundEmail_closed() {
      // create a new email and envelope object
      Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        Map<String, Schema.RecordTypeInfo> rtMap = Case.sObjectType.getDescribe().getRecordTypeInfosByName();
        Account acc = utilTestClass.CreateAccount('Test Acc Random 34');
        insert acc;
        EB_AccountProductMap__c v = new EB_AccountProductMap__c();
        v.EB_Account__c  = acc.id;
        v.EB_Product__c = 'testing_product';
        insert v;
        Case varCase = new Case(Status = 'Mitigated / Solution Provided', Origin = 'Email', severity__c = '2', Validation_Override__c = True,
                accountId=acc.Id,Start_Time__c = System.now());
        insert varCase;
        
        varCase.status = 'Closed';
        varCase.LOE_Hours__c = 1;
        varCase.Task_LOE__c = 1;
        varCase.recordtypeid = rtMap.get('Technical').getRecordTypeId();
        varCase.Case_Product__c = v.id ;
        varCase.Resolved_Date__c = system.now();
        varCase.Solution_Summary__c = 'testing';
        varCase.Sub_Type__c = 'proActive';
        varCase.Service_Category__c = 'Product Support';
        varCase.Problem__c = 'Performance';
        varCase.Sub_Problem__c = 'Access Error';
        varCase.Solution_Status__c = 'Work Completed';
        update varCase;
        
        test.startTest();
      Case cs = [Select Id, CaseNumber, AKAM_Case_ID__c from Case where id =: varCase.Id Limit 1];
        email.subject = 'Test Email Service Case # ' + cs.AKAM_Case_ID__c + ':' + ' [AKAM-CASE #' + cs.AKAM_Case_ID__c + ']' ;
        email.fromAddress = 'someaddress@email.com';
        email.htmlBody  = 'email body/n2225256325/nTitle Account ID:TestData';
        email.ToAddresses = Test_EmailToCaseHandler.toAddresses2();
        //email.ToAddresses = new String[]{'billing@akamai.com','specialist@akamai.com','support@akamai.com','ps-tix@akamai.com','epe-support@akamai.com','testgggggggggggggggggggg@akamai.com','ccare@akamai.com','managedsecurity@akamai.com','customercare@akamai.com','aura-support@akamai.com'};
        // call the email service class and test it with the data in the testMethod
      EmailToCaseHandler  test1Inbound = new EmailToCaseHandler();
        test1Inbound.handleInboundEmail(email, env);
        test.stopTest();
    }

    static testMethod void TestinBoundEmail_last() {
        // create a new email and envelope object
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        Account acc = utilTestClass.CreateAccount('Test Acc Random 34');
        insert acc;

        Contact c = new Contact(FirstName = 'ConTest',LastName = 'Test Con', AccountId = acc.Id, email = 'someaddress@email.com',Login__c = 'test login', MailingCountry = 'India', MailingState = 'DELHI');
        insert c;
        User userRun = [SELECT Id FROM User WHERE Alias = 'CRMOPS' limit 1];

        Case varCase;
        System.runAs(userRun) {
            Test.startTest();
            varCase = new Case(Status = 'Unassigned', Origin = 'Email', severity__c = '3', ContactId=c.Id, AKAM_Case_ID__c = 'AK-17AKC');
            varCase.validation_override__c = true;
            insert varCase;
            Test.stopTest();
            /*String cassIdString = cs.id;
            string Case_ThreadID = 'ref:_'  + UserInfo.getOrganizationId().left(5)
            + UserInfo.getOrganizationId().mid(11,4)
            + '._'
            + cassIdString.left(5)
            + cassIdString.mid(10,5) + ':ref';*/
            /*email.subject = 'Test Email Service Case # [AKAM-CASE # '+ varCase.AKAM_Case_ID__c  + '] ';
            email.fromAddress = 'someaddress@email.com';
            email.htmlBody  = 'email body/n2225256325/nTitle Account ID:TestData '+ varCase.AKAM_Case_ID__c;
            email.ToAddresses = Test_EmailToCaseHandler.toAddresses2();
            //email.ToAddresses = new String[]{'billing@akamai.com','specialist@akamai.com','support@akamai.com','ps-tix@akamai.com','epe-support@akamai.com','testgggggggggggggggggggg@akamai.com','ccare@akamai.com','managedsecurity@akamai.com','customercare@akamai.com','aura-support@akamai.com'};
            // call the email service class and test it with the data in the testMethod
            EmailToCaseHandler  testInbound_last = new EmailToCaseHandler();
            testInbound_last.handleInboundEmail(email, env);
            test.stopTest();*/
        }
    }
    
    //This method is for creating the case with subtype CMP Alerts
    /*static testMethod void TestinBoundEmail_CMP() {
      // create a new email and envelope object
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        EmailToCaseHandler  testInbound_cmp = new EmailToCaseHandler();
        //For CMP Alerts
        test.startTest();
        Messaging.InboundEmail.Header hditem= new Messaging.InboundEmail.Header(); 
        email.headers=new Messaging.InboundEmail.Header[1]; 
        hditem.name='Date'; 
        hditem.value='Tue, 28 Apr 2009 14:08:37 -0700';
        email.headers[0]=hditem;
        email.subject ='[portal-feedback] PORTAL FEEDBACK FORM FROM CUSTOMER';
        email.fromAddress = SC_FromEmailAddress__c.getValues('CMPFromEmailAddress').FromAddress__c.trim();
        email.htmlBody = 'CATEGORY:      CMP';
        email.ToAddresses = Test_EmailToCaseHandler.toAddresses1();
        testInbound_cmp.handleInboundEmail(email, env);
        test.stopTest();
        }
    */

    static testMethod void TestinBoundEmail_portal() {
      // create a new email and envelope object
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        EmailToCaseHandler  testInbound_portal = new EmailToCaseHandler();
        test.startTest();
        email.subject ='[portal-feedback] PORTAL FEEDBACK FORM FROM CUSTOMER';
        email.fromAddress = 'portal-webmaster@akamai.com';
        email.htmlBody = 'test';
        email.ToAddresses = Test_EmailToCaseHandler.toAddresses2();
        testInbound_portal.handleInboundEmail(email, env);
        test.stopTest();
        }

    //This method is to create Managed security Case
    static testMethod void TestinBoundEmail_Security() {
      // create a new email and envelope object
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        EmailToCaseHandler  testInbound_security = new EmailToCaseHandler();
        test.startTest();
        email.subject ='Test';
        email.fromAddress = SC_FromEmailAddress__c.getValues('ProlexicFromEmailAddress').FromAddress__c.trim() ;
        email.htmlBody = 'test';
        email.ToAddresses = new List<String>{EmailHandler_CS__c.getValues('specialist').Email_Address__c};
        testInbound_security.handleInboundEmail(email, env);
        test.stopTest();
        }
        
   //This method is to create Carrier Products Case - Nominum
    static testMethod void TestinBoundEmail_CarrierProd()
    {
      // create a new email and envelope object
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        EmailToCaseHandler testInbound_cp = new EmailToCaseHandler();
        test.startTest();
        email.subject ='Testing [sev1] case Carrier';
        email.fromAddress = 'testCustomer@gmail.com';
        email.htmlBody = 'test';
        email.ToAddresses = new List<String>{EmailHandler_CS__c.getValues('Nominum').Email_Address__c};
        testInbound_cp.handleInboundEmail(email, env);
        test.stopTest();
        }     
    
    static testMethod void TestinBoundEmail_webform() {
      // create a new email and envelope object
        Account acc = utilTestClass.CreateAccount('Test Acc Random 34');
        insert acc;
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        EmailToCaseHandler  testInbound_portal = new EmailToCaseHandler();
        test.startTest();
        email.subject ='[client-endusersupport] Download Manager Feedback \n Account ID:'+acc.akam_account_id__C;
        email.fromAddress = 'webforms@akamai.com';
        email.htmlBody = 'test Account ID: '+acc.akam_account_id__C;
        email.ToAddresses = Test_EmailToCaseHandler.toAddresses2();
        testInbound_portal.handleInboundEmail(email, env);
        test.stopTest();
        }
    
    public static string[] toAddresses1()
    {
        String[] toAddressesFromCS = new String[]{EmailHandler_CS__c.getValues('ccare').Email_Address__c,EmailHandler_CS__c.getValues('specialist').Email_Address__c,EmailHandler_CS__c.getValues('ManagedSecurity').Email_Address__c};
        return toAddressesFromCS;
    }  

    public static string[] toAddresses2()
    {
         String[] toAddressesFromCS = new String[]{EmailHandler_CS__c.getValues('billing').Email_Address__c,EmailHandler_CS__c.getValues('Emerging Product Group').Email_Address__c,EmailHandler_CS__c.getValues('Encoder Qualification').Email_Address__c,EmailHandler_CS__c.getValues('Xerocole').Email_Address__c};
        return toAddressesFromCS;
    } 
    
    static testMethod void TestinBoundEmail_subjectException() {
      // create a new email and envelope object
      Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        test.startTest();
        email.subject = 'Test Email Service [AKAM-CASE #';
        email.fromAddress = 'someaddress@akamai.com';
        email.htmlBody  = 'email body/n2225256325/nTitle Account ID: 123';
        email.ToAddresses = Test_EmailToCaseHandler.toAddresses1();
        EmailToCaseHandler  testInbound = new EmailToCaseHandler();
        
        testInbound.handleInboundEmail(email, env);
        test.stopTest();
    }
    
     static testMethod void TestinBoundEmail_securityClosed() {
      // create a new email and envelope object
      Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        Account acc = utilTestClass.CreateAccount('Test Acc Random 34');
        insert acc;
        Contact c = new Contact(FirstName = 'ConTest',LastName = 'Test Con', AccountId = acc.Id, email = 'someaddress@email.com',Login__c = 'test login',MailingCountry = 'India', MailingState = 'DELHI');
      insert c;
        Case varCase = new Case(Status = 'Closed', Origin = 'Email', severity__c = '2', ContactId=c.Id, validation_override__c = true, recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Managed Security').getRecordTypeId());
      insert varCase;
        test.startTest();
      Case cs = [Select Id, CaseNumber, AKAM_Case_ID__c from Case where id =: varCase.Id Limit 1];
        email.subject = 'Test Email Service Case # ' + cs.AKAM_Case_ID__c + ':' + ' [AKAM-CASE #' + cs.AKAM_Case_ID__c + ']' ;
        email.fromAddress = 'someaddress@email.com';
        email.htmlBody  = 'email body/n2225256325/nTitle Account ID:TestData';
         email.ToAddresses = new List<String>{EmailHandler_CS__c.getValues('ManagedSecurity').Email_Address__c};
        email.ccAddresses = new String[]{'test@test.com'};
        // call the email service class and test it with the data in the testMethod
        EmailToCaseHandler.sendEmailToCustomer(email,cs);
        //EmailToCaseHandler.sendEmailToCustomer1(email,cs);
        EmailToCaseHandler  testInbound = new EmailToCaseHandler();
        
        testInbound.handleInboundEmail(email, env);
        test.stopTest();
    }
    
        static testMethod void TestinBoundEmail_governorLimits() {
      // create a new email and envelope object
      Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        Account acc = utilTestClass.CreateAccount('Test Acc Random 34');
        insert acc;
        Contact c = new Contact(FirstName = 'ConTest',LastName = 'Test Con', AccountId = acc.Id, email = 'someaddress@email.com',Login__c = 'test login',MailingCountry = 'India', MailingState = 'DELHI');
        insert c;
        Case varCase = new Case(Status = 'Unassigned', Origin = 'Email', severity__c = '2', ContactId=c.Id, Case_Assignment_Using_Active_Rules__c = false);
        insert varCase;

        test.startTest();
        Case cs = [Select Id, CaseNumber, AKAM_Case_ID__c from Case where id =: varCase.Id Limit 1];
        email.subject = 'Test Email Service Case # ' + cs.AKAM_Case_ID__c + ':' + ' [AKAM-CASE #' + cs.AKAM_Case_ID__c + ']' ;
        email.fromAddress = 'someaddress@email.com';
        email.fromname = 'some address';
        email.plainTextBody = 'test plaint text body';
        List<String> lToAdd = new List<String>{EmailHandler_CS__c.getValues('ccare').Email_Address__c};
        for(Integer i=0; i<200; i++)
        {
            String toAdd = 'samplemail'+i+'@testemail.com';
          lToAdd.add(toAdd);
        }
        email.ToAddresses = lToAdd;
        email.ccAddresses = lToAdd;
    email.htmlBody  = 'email body/n2225256325/nTitle Account ID:TestData';
    for(Integer i=0; i<400; i++)
        {
            email.htmlBody  += 'testemail body/n2225256325/nTitle Account ID:/nTestData with test big html values';
        }
        
    Messaging.InboundEmail.BinaryAttachment binaryAttachment = new Messaging.InboundEmail.BinaryAttachment();
    
    binaryAttachment.filename = 'image.png';
    binaryAttachment.body = blob.valueOf('my attachment text');
    Messaging.InboundEmail.Header binaryHeader = new Messaging.InboundEmail.Header();
    binaryHeader.Name = 'Content-Type';
    binaryHeader.Value = 'image/png;image.png';
    List<Messaging.InboundEmail.Header> lBinaryHeader = new List<Messaging.InboundEmail.Header>();
    lBinaryHeader.add(binaryHeader);
    binaryAttachment.headers = lBinaryHeader;

    email.binaryAttachments = new List<Messaging.InboundEmail.BinaryAttachment>{binaryAttachment};

        
    Messaging.InboundEmail.TextAttachment textAttachment = new Messaging.InboundEmail.TextAttachment();
    email.textAttachments = new List<Messaging.InboundEmail.TextAttachment>{textAttachment};
        
        EmailToCaseHandler.sendEmailToCustomer(email,cs);
        //EmailToCaseHandler.sendEmailToCustomer1(email,cs);
        EmailToCaseHandler  testInbound = new EmailToCaseHandler();
        
        testInbound.handleInboundEmail(email, env);
        test.stopTest();
    }
  
    static testMethod void TestinBoundEmail2() {
      // create a new email and envelope object
      Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        Account acc = utilTestClass.CreateAccount('Test Acc Random 34');
        insert acc;
        Contact c = new Contact(FirstName = 'ConTest',LastName = 'Test Con', AccountId = acc.Id, email = 'someaddress@email.com',Login__c = 'test login',MailingCountry = 'India', MailingState = 'DELHI');
      insert c;
        acc = [select akam_account_id__C from account where id=:acc.id];
        test.startTest();
        email.subject = '[portal-feedback] PORTAL FEEDBACK FORM FROM CUSTOMER' ;
        email.fromAddress = 'portal-webmaster@akamai.com';
        email.htmlBody  = 'email body/n2225256325/nTitle Account ID: '+acc.akam_account_id__c+' test';
        email.ToAddresses = new List<String>{EmailHandler_CS__c.getValues('ccare').Email_Address__c};
        email.ccAddresses = new String[]{'test@test.com'};
        EmailToCaseHandler  testInbound = new EmailToCaseHandler();
        testInbound.handleInboundEmail(email, env);
        test.stopTest();
    }
    
    static testMethod void TestinBoundEmail3() {
      // create a new email and envelope object
      Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        Account acc = utilTestClass.CreateAccount('Test Acc Random 34');
        insert acc;
        Contact c = new Contact(FirstName = 'ConTest',LastName = 'Test Con', AccountId = acc.Id, email = 'someaddress@email.com',Login__c = 'test login',MailingCountry = 'India', MailingState = 'DELHI');
      insert c;
        acc = [select akam_account_id__C from account where id=:acc.id];
        test.startTest();
        
        email.fromAddress = 'webforms@akamai.com';
        email.subject = '[client-endusersupport] Download Manager Feedback';
        email.htmlBody  = 'email body/n2225256325/nTitle Account ID: '+acc.akam_account_id__c+' test';
        email.ToAddresses = new List<String>{EmailHandler_CS__c.getValues('ccare').Email_Address__c};
        email.ccAddresses = new String[]{'test@test.com'};
        EmailToCaseHandler  testInbound = new EmailToCaseHandler();

        testInbound.handleInboundEmail(email, env);
        test.stopTest();
    }

    static testmethod void TestinBoundEmailSecSales()
    {
    
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        Account acc = utilTestClass.CreateAccount('Test Acc Random 34');
        insert acc;
        Contact c = new Contact(FirstName = 'ConTest',LastName = 'Test Con', AccountId = acc.Id, email = 'someaddress@email.com',Login__c = 'test login',MailingCountry = 'India', MailingState = 'DELHI');
        insert c;
        acc = [select akam_account_id__C from account where id=:acc.id];
        
        test.startTest();
        
        email.subject ='Testing [sev1] case Carrier';
        email.fromAddress = 'testCustomer@gmail.com';
        email.htmlBody = 'test';
        email.ToAddresses = new List<String>{EmailHandler_CS__c.getValues('SecSales').Email_Address__c};
        
        
        EmailToCaseHandler  testInbound = new EmailToCaseHandler();
        testInbound.handleInboundEmail(email, env);
        
        test.stopTest();
    
    
    }
    
    static testmethod void testInboundEmailSecLaw()
    {
    
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        Account acc = utilTestClass.CreateAccount('Test Acc Random 34');
        insert acc;
        //Account acc = [SELECT Id, akam_account_id__C from Account Limit 1];
        Contact c = new Contact(FirstName = 'ConTest',LastName = 'Test Con', AccountId = acc.Id, email = 'testCustomer@random.com',Login__c = 'test login',MailingCountry = 'India', MailingState = 'DELHI');
        insert c;
        //acc = [select akam_account_id__C from account where id=:acc.id];
        
        test.startTest();
        
        email.subject ='Testing [sev1] case Carrier';
        email.fromAddress = 'testCustomer@random.com';
        email.htmlBody = 'test';
        email.ToAddresses = new List<String>{EmailHandler_CS__c.getValues('SecLaw').Email_Address__c};
        
        
        EmailToCaseHandler  testInbound = new EmailToCaseHandler();
        testInbound.handleInboundEmail(email, env);
        
        test.stopTest();
    
    
    }
    
    static testMethod void testBounceEmailUseCase()
    {
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();       
        Messaging.InboundEmail email1 = new Messaging.InboundEmail() ;
        Account acc = utilTestClass.CreateAccount('Test Acc Random 34');
        insert acc;
        Contact c = new Contact(FirstName = 'ConTest',LastName = 'Test Con', AccountId = acc.Id, email = 'someaddress@email.com',Login__c = 'test login',MailingCountry = 'India', MailingState = 'DELHI');
        insert c;
        Case varCase = new Case(Status = 'Unassigned', Origin = 'Email', severity__c = '2', ContactId=c.Id, Case_Assignment_Using_Active_Rules__c = false);
        insert varCase;
        
        test.startTest();
        Case cs = [Select Id, CaseNumber, AKAM_Case_ID__c from Case where id =: varCase.Id Limit 1];
        
        
        
        /***Case 2***/
        String body2 = 'CASE #'+cs.AKAM_Case_ID__c+':';
        //Create an email attachment 
        Messaging.InboundEmail.BinaryAttachment attachment1 = new Messaging.InboundEmail.BinaryAttachment();
        attachment1.body = blob.valueOf(body2);
        attachment1.fileName = 'textfileone.txt';
        attachment1.mimeTypeSubType = 'text/plain';
        
        //Creating headers
        Messaging.InboundEmail.Header hditem1= new Messaging.InboundEmail.Header();
        hditem1.Name ='Content-Type';
        hditem1.Value = 'text/plain';
        
        
        attachment1.headers = new Messaging.InboundEmail.Header[1];
        attachment1.headers[0]=hditem1;
        
        email1.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment1 };
            email1.subject ='Testing sev1 case Carrier';
        email1.fromAddress = 'testCustomer@gmail.com';
        email1.htmlBody = 'test';
        email1.ToAddresses = new List<String>{EmailHandler_CS__c.getValues('ManagedSecurity').Email_Address__c};
            email1.FromName='Salesforce Bounce Forwarder';
        
        EmailToCaseHandler  testInbound1 = new EmailToCaseHandler();
        testInbound1.handleInboundEmail(email1, env);
        
        test.stopTest();
        
    }
    
    static testmethod void TestinBoundEmailSalesforceBounceForwarder()
    {
    
       Messaging.InboundEmail email = new Messaging.InboundEmail() ;
       Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
       
       Messaging.InboundEmail email1 = new Messaging.InboundEmail() ;
       Messaging.InboundEmail email2 = new Messaging.InboundEmail() ;
       Messaging.InboundEmail email3 = new Messaging.InboundEmail() ;
       
       
       Account acc = utilTestClass.CreateAccount('Test Acc Random 34');
       insert acc;
       Contact c = new Contact(FirstName = 'ConTest',LastName = 'Test Con', AccountId = acc.Id, email = 'someaddress@email.com',Login__c = 'test login',MailingCountry = 'India', MailingState = 'DELHI');
       insert c;
       Case varCase = new Case(Status = 'Unassigned', Origin = 'Email', severity__c = '2', ContactId=c.Id, Case_Assignment_Using_Active_Rules__c = false);
       insert varCase;
       
       test.startTest();
       Case cs = [Select Id, CaseNumber, AKAM_Case_ID__c from Case where id =: varCase.Id Limit 1];
       
       
       /***Case 1***/
       String body1 = '[AKAM-CASE #'+cs.AKAM_Case_ID__c+']';
       //Create an email attachment 
       Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
       attachment.body = blob.valueOf(body1);
       attachment.fileName = 'textfileone.txt';
       attachment.mimeTypeSubType = 'text/plain';
       
       //Creating headers
       Messaging.InboundEmail.Header hditem= new Messaging.InboundEmail.Header();
       hditem.Name ='Content-Type';
       hditem.Value = 'text/plain';
       
      
       attachment.headers = new Messaging.InboundEmail.Header[1];
       attachment.headers[0]=hditem;
       
       
       email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment };
       email.subject ='Testing sev1 case Carrier';
       email.fromAddress = 'testCustomer@gmail.com';
       email.htmlBody = 'test';
       email.ToAddresses = new List<String>{EmailHandler_CS__c.getValues('ManagedSecurity').Email_Address__c};
       email.FromName='Salesforce Bounce Forwarder';
       
       
       EmailToCaseHandler  testInbound = new EmailToCaseHandler();
       testInbound.handleInboundEmail(email, env);
        
        test.stopTest();

  }
  
    static testMethod void testingUseCaseThree()
    {
        Account acc = utilTestClass.CreateAccount('Test Acc Random 34');
        insert acc;
        Contact c = new Contact(FirstName = 'ConTest',LastName = 'Test Con', AccountId = acc.Id, email = 'someaddress@email.com',Login__c = 'test login',MailingCountry = 'India', MailingState = 'DELHI');
        insert c;
        Case varCase = new Case(Status = 'Unassigned', Origin = 'Email', severity__c = '2', ContactId=c.Id, Case_Assignment_Using_Active_Rules__c = false);
        insert varCase;
        test.startTest();
        Case cs = [Select Id, CaseNumber, AKAM_Case_ID__c from Case where id =: varCase.Id Limit 1];
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        Messaging.InboundEmail email2 = new Messaging.InboundEmail() ;
        /***Case 3***/
        String body3 = '{'+cs.AKAM_Case_ID__c+'}';
        //Create an email attachment 
        Messaging.InboundEmail.BinaryAttachment attachment2 = new Messaging.InboundEmail.BinaryAttachment();
        attachment2.body = blob.valueOf(body3);
        attachment2.fileName = 'textfileone.txt';
        attachment2.mimeTypeSubType = 'text/plain';
        
        //Creating headers
        Messaging.InboundEmail.Header hditem2= new Messaging.InboundEmail.Header();
        hditem2.Name ='Content-Type';
        hditem2.Value = 'text/plain';
        
        
        attachment2.headers = new Messaging.InboundEmail.Header[1];
        attachment2.headers[0]=hditem2;
        
        email2.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment2 };
            email2.subject ='Testing sev1 case Carrier';
        email2.fromAddress = 'testCustomer@gmail.com';
        email2.htmlBody = 'test';
        email2.ToAddresses = new List<String>{EmailHandler_CS__c.getValues('ManagedSecurity').Email_Address__c};
            email2.FromName='Salesforce Bounce Forwarder';
        
        
        EmailToCaseHandler  testInbound2 = new EmailToCaseHandler();
        testInbound2.handleInboundEmail(email2, env);
        Test.stopTest();
        
    }
    
 static testmethod void TestinBoundEmailSalesforceBounceImage()
 {
 
       
       
       Messaging.InboundEmail email = new Messaging.InboundEmail() ;
       Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
       
       Messaging.InboundEmail email1 = new Messaging.InboundEmail() ;
       Messaging.InboundEmail email2 = new Messaging.InboundEmail() ;
       Messaging.InboundEmail email3 = new Messaging.InboundEmail() ;
       
       
       Account acc = utilTestClass.CreateAccount('Test Acc Random 34');
       insert acc;
       Contact c = new Contact(FirstName = 'ConTest',LastName = 'Test Con', AccountId = acc.Id, email = 'someaddress@email.com',Login__c = 'test login',MailingCountry = 'India', MailingState = 'DELHI');
       insert c;
       Case varCase = new Case(Status = 'Unassigned', Origin = 'Email', severity__c = '2', ContactId=c.Id, Case_Assignment_Using_Active_Rules__c = false);
       insert varCase;
       
       test.startTest();
       Case cs = [Select Id, CaseNumber, AKAM_Case_ID__c from Case where id =: varCase.Id Limit 1];
       
       
       /***Case 1***/
       String body1 = '[AKAM-CASE #'+cs.AKAM_Case_ID__c+']';
       //Create an email attachment 
       Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
       attachment.body = blob.valueOf(body1);
       attachment.fileName = 'textfileone.png';
       attachment.mimeTypeSubType = 'image/png';
       
       //Creating headers
       Messaging.InboundEmail.Header hditem= new Messaging.InboundEmail.Header();
       hditem.Name ='Content-Type';
       hditem.Value = 'image/png';
       
      
       attachment.headers = new Messaging.InboundEmail.Header[1];
       attachment.headers[0]=hditem;
       
       
       email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment };
       email.subject ='Testing sev1 case Carrier';
       email.fromAddress = 'testCustomer@gmail.com';
       email.htmlBody = 'test';
       email.ToAddresses = new List<String>{EmailHandler_CS__c.getValues('ManagedSecurity').Email_Address__c};
       email.FromName='Salesforce Bounce Forwarder';
       
       
       EmailToCaseHandler  testInbound = new EmailToCaseHandler();
     	testInbound.handleInboundEmail(email, env);
     
     
     
     
     
     
     
     
 	}    
    
    static testmethod void TestEmailToCaseUtility(){
        String textStr = EmailToCaseUtility.convertHtmlBodyToText('<p> Test Message </p>');
        String reqString = EmailToCaseUtility.findStringAMG('Random Parent \\nAccount: \\n not this one', 'Account');
        Boolean isInternalAct = EmailToCaseUtility.isInternalActivity('test@nomail.com', 'test@nomail.com', 'nocc-shift@akamai.com');
        isInternalAct = EmailToCaseUtility.isInternalActivity('test@nomail.com', 'test@akamai.com', 'test@akamai.com');
        isInternalAct = EmailToCaseUtility.isInternalActivity('test@akamai.com', 'test@nomail.com', 'test@nomail.com');
        isInternalAct = EmailToCaseUtility.isInternalActivity('test@nomail.com', 'test@nomail.com', 'test@nomail.com');
        isInternalAct = EmailToCaseUtility.isInternalActivity('test@nomail.com', 'test@nomail.com', 'test@akamai.com');
        isInternalAct = EmailToCaseUtility.isInternalActivity('test@akamai.com', 'test@akamai.com', 'test@nomail.com');
        isInternalAct = EmailToCaseUtility.isInternalActivity('test@akamai.com', 'test@akamai.com', 'test@akamai.com');
        Boolean isPartnerAct = EmailToCaseUtility.isPartnerActivity('test@nomail.com', 'test@nomail.com', 'test@nomail.com');
        isPartnerAct = EmailToCaseUtility.isPartnerActivity('test@akamai.com', 'test@akamai.com;test1@akamai.com', 'test@nomail.com');
        isPartnerAct = EmailToCaseUtility.isPartnerActivity('test@akamai.com', 'test@akamai.com;test1@akamai.com', 'test@akamai.com');
    }
    static testMethod void testOAChanges() {
        // create a new email and envelope object
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        
        Messaging.InboundEmail rejEmail = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope rejEnv = new Messaging.InboundEnvelope();
        
        Account thisAccount = [SELECT Id FROM Account WHERE Name = 'Test Account for OA' LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'Test Opportuniry for OA' LIMIT 1];
        
        Order_Approval__c thisOA = new Order_Approval__c();
        thisOA.Associated_Opportunity__c = opp.id;
        thisOA.Validation_Override__c = true;
        insert thisOA;
        
        Case thisCase = new Case();
        thisCase.Description = 'testPS1';
        thisCase.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Order Approval-Escalations').getRecordTypeId();
        thisCase.Subject = 'testS2ET1';
        thisCase.Service__c = 'Managed Integration';
        thisCase.Validation_Override__c = true;
        thisCase.AccountId = thisAccount.Id;
        thisCase.Opportunity__c = opp.Id;
        thisCase.Order_Approval__c = thisOA.id;
        thisCase.Approver__c = UserInfo.getUserId();
        
        Case thisCaseOthers = new Case();
        thisCaseOthers.Description = 'testPS1';
        thisCaseOthers.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Order Approval-Escalations').getRecordTypeId();
        thisCaseOthers.Subject = 'testS2ET1';
        thisCaseOthers.Service__c = 'Managed Integration';
        thisCaseOthers.Validation_Override__c = true;
        thisCaseOthers.AccountId = thisAccount.Id;
        thisCaseOthers.Opportunity__c = opp.Id;
        thisCaseOthers.Order_Approval__c = thisOA.id;
        thisCaseOthers.Approver__c = UserInfo.getUserId();
        thisCaseOthers.OwnerId = UserInfo.getUserId();
        insert new List<Case>{thisCase,thisCaseOthers};
        
        Approval_Details__c thisAD = new Approval_Details__c();
        thisAD.Related_To__c = thisCase.id;
        thisAD.Validation_Override__c = true;
        thisAD.Approver_Notes__c = 'Test';
        
        Approval_Details__c thisOthersAD = new Approval_Details__c();
        thisOthersAD.Related_To__c = thisCaseOthers.id;
        thisOthersAD.Validation_Override__c = true;
        thisOthersAD.Approver_Notes__c = 'Test';
        insert new List<Approval_Details__c>{ thisAD,thisOthersAD};
        
        Case cs = [Select Id, CaseNumber, AKAM_Case_ID__c from Case where id =: thisCase.Id Limit 1];
        email.subject = 'Test Email Service Case # ' + cs.AKAM_Case_ID__c + ':' + ' [AKAM-CASE #' + cs.AKAM_Case_ID__c + '] Approve' ;
        email.fromAddress = 'someaddress@email.com';
        email.htmlBody  = 'email body/n2225256325/nTitle Account ID:TestData';
        email.ToAddresses = Test_EmailToCaseHandler.toAddresses1();
        email.ccAddresses = new String[]{'test@test.com'};
            //email.ToAddresses = new String[]{'billing@akamai.com','specialist@akamai.com','support@akamai.com','ccare@akamai.com','epe-support@akamai.com','testgggggggggggggggggggg@akamai.com','managedsecurity@akamai.com','customercare@akamai.com','aura-support@akamai.com'};
            // call the email service class and test it with the data in the testMethod
            EmailToCaseHandler.sendEmailToCustomer(email,cs);
        //EmailToCaseHandler.sendEmailToCustomer1(email,cs);
        EmailToCaseHandler  testInbound = new EmailToCaseHandler();
        test.startTest();
   
        
        testInbound.handleInboundEmail(email, env);
        
        Case csOther = [Select Id, CaseNumber, AKAM_Case_ID__c,ownerid,owner.name,owner.email,RecordType.Name,Contact.Name,AKAM_Created_Date__c,Subject from Case where id =: thisCaseOthers.Id Limit 1];
		System.debug('>>>>>>>>>>'+csother+':::::'+Userinfo.getUserId()+':::::'+userinfo.getUserEmail());
        rejEmail.subject = 'Test Email Service Case # ' + csOther.AKAM_Case_ID__c + ':' + ' [AKAM-CASE #' + csOther.AKAM_Case_ID__c + '] Reject' ;
        rejEmail.fromAddress = 'someaddress@email.com';
        rejEmail.htmlBody  = 'email body/n2225256325/nTitle Account ID:TestData';
        rejEmail.ToAddresses = Test_EmailToCaseHandler.toAddresses1();
        rejEmail.ccAddresses = new String[]{'test@test.com'};
            EmailToCaseHandler.sendEmailToOwner(csOther);
            //email.ToAddresses = new String[]{'billing@akamai.com','specialist@akamai.com','support@akamai.com','ccare@akamai.com','epe-support@akamai.com','testgggggggggggggggggggg@akamai.com','managedsecurity@akamai.com','customercare@akamai.com','aura-support@akamai.com'};
            // call the email service class and test it with the data in the testMethod
            EmailToCaseHandler.sendEmailToCustomer(rejEmail,csOther);
        //EmailToCaseHandler.sendEmailToCustomer1(email,cs);
        EmailToCaseHandler  testInboundOther = new EmailToCaseHandler();
        
        testInboundOther.handleInboundEmail(rejEmail, rejEnv);
        
        
        Messaging.InboundEmail email1 = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env1 = new Messaging.InboundEnvelope();
        email1.subject = 'Test Email Service Case # ' + cs.AKAM_Case_ID__c + ':' + ' [AKAM-CASE #' + cs.AKAM_Case_ID__c + '] Approve' ;
        email1.fromAddress = 'ccare_team@feedback.akamai.com';
        email1.htmlBody  = 'email body/n2225256325/nTitle Account ID:TestData';
        email1.ToAddresses = Test_EmailToCaseHandler.toAddresses1();
        email1.ccAddresses = new String[]{'test@test.com'};
            //email.ToAddresses = new String[]{'billing@akamai.com','specialist@akamai.com','support@akamai.com','ccare@akamai.com','epe-support@akamai.com','testgggggggggggggggggggg@akamai.com','managedsecurity@akamai.com','customercare@akamai.com','aura-support@akamai.com'};
            // call the email service class and test it with the data in the testMethod
            EmailToCaseHandler.sendEmailToCustomer(email1,cs);
        //EmailToCaseHandler.sendEmailToCustomer1(email,cs);
        EmailToCaseHandler  testInbound1 = new EmailToCaseHandler();
        
        testInbound1.handleInboundEmail(email1, env1);
        
        test.stopTest();
    }
    
    
    static testMethod void testOAChanges2() {
        // create a new email and envelope object
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        
        Messaging.InboundEmail rejEmail = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope rejEnv = new Messaging.InboundEnvelope();
        
        Account thisAccount = utilTestClass.CreateAccount('Test Account for OA');           
        insert thisAccount;
        
        Case thisCase = new Case();
        thisCase.Description = 'test';
        thisCase.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        thisCase.Sub_Type__c = 'Carrier';
        thisCase.Subject = 'test';
        thisCase.Validation_Override__c = true;
        insert thisCase;
        
        Test.startTest();
        Case cs = [Select Id, CaseNumber, AKAM_Case_ID__c from Case where id =: thisCase.Id Limit 1];
        email.subject = 'Test Email Service Case # ' + cs.AKAM_Case_ID__c + ':' + ' [AKAM-CASE #' + cs.AKAM_Case_ID__c + '] Approve' ;
        email.fromAddress = 'someaddress@email.com';
        email.htmlBody  = 'email body/n2225256325/nTitle Account ID:TestData';
        email.ToAddresses = Test_EmailToCaseHandler.toAddresses1();
        email.ccAddresses = new String[]{'test@test.com'};
        EmailToCaseHandler.sendEmailToCustomer(email,cs);
        
        test.stopTest();
    }

    static testMethod void testInboundEmailWithSenderIdHeader() {
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        
        Account acc = utilTestClass.CreateAccount('Test Acc Random 34');
        insert acc;
        Contact c = new Contact(FirstName = 'ConTest',LastName = 'Test Con', AccountId = acc.Id, email = 'someaddress@email.com',Login__c = 'test login',MailingCountry = 'India', MailingState = 'DELHI');
        insert c;
        Id queueId = [select id from group where type='Queue' and name = 'ATS_Transition_Queue' limit 1].id;
        Case varCase = new Case(Status = 'Unassigned', Origin = 'Email', severity__c = '2', ContactId=c.Id, OwnerId = queueId, Case_Assignment_Using_Active_Rules__c = false);
        insert varCase;
        
        test.startTest();
        
        Case cs = [Select Id, CaseNumber, AKAM_Case_ID__c from Case where id =: varCase.Id Limit 1];
        
        email.subject = 'Test Email Service Case # ' + cs.AKAM_Case_ID__c + ':' + ' [AKAM-CASE #' + cs.AKAM_Case_ID__c + ']';
        email.fromAddress = [SELECT Value_Text__c FROM SC_Utility__mdt
                             WHERE DeveloperName = 'EmailMessage_ManagedSecurityEmailAddress'
                             AND Active__c = true].Value_Text__c;
        email.htmlBody = 'email body';
        email.ToAddresses = Test_EmailToCaseHandler.toAddresses1();
        Messaging.InboundEmail.Header senderIdHeader = new Messaging.InboundEmail.Header();
        senderIdHeader.name = 'SenderId';
        senderIdHeader.value = UserInfo.getUserId();
        email.headers = new Messaging.InboundEmail.Header[1];
        email.headers[0] = senderIdHeader;
        
        EmailToCaseHandler testInbound = new EmailToCaseHandler();
        testInbound.handleInboundEmail(email, env);
        
        test.stopTest();
    }

      static testMethod void testJarvisEmail() {
        // create a new email and envelope object
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();

        Messaging.InboundEmail rejEmail = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope rejEnv = new Messaging.InboundEnvelope();

        Account thisAccount = utilTestClass.CreateAccount('Test Account for OA');
        insert thisAccount;

        Case thisCase = new Case();
        thisCase.Description = 'test';
        thisCase.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        thisCase.Subject = 'test';
        thisCase.Validation_Override__c = true;
        thisCase.apply_jarvis_logic__c = false;
        thisCase.Do_Not_Show_in_Portal__c = true;
        thisCase.Sub_Type__c = 'Carrier';
        insert thisCase;

        Test.startTest();
        Case cs = [Select Id, CaseNumber, apply_jarvis_logic__c, AKAM_Case_ID__c from Case where id =: thisCase.Id Limit 1];
        email.subject = 'Test Email Service Case # ' + cs.AKAM_Case_ID__c + ':' + ' [AKAM-CASE #' + cs.AKAM_Case_ID__c + '] Approve' ;
        email.fromAddress = 'someaddress@email.com';
        email.htmlBody  = 'email body/n2225256325/nTitle Account ID:TestData';
        email.ToAddresses = Test_EmailToCaseHandler.toAddresses1();
        email.ccAddresses = new String[]{'test@test.com'};
        EmailToCaseHandler.sendEmailToCustomer(email,cs);

        test.stopTest();
    }
    static testMethod void TestinBoundEmailJarvis2() {
      // create a new email and envelope object
      Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        Account acc = utilTestClass.CreateAccount('Test Acc Random 34');
        insert acc;

        Contact c = new Contact(FirstName = 'ConTest',LastName = 'Test Con', AccountId = acc.Id, email = 'someaddress@akamai.com',Login__c = 'test login', MailingCountry = 'India', MailingState = 'DELHI');
        insert c;
        User userRun = [SELECT Id FROM User WHERE Alias = 'CRMOPS' limit 1];


        test.startTest();
        System.runAs(userRun) {


            String cassIdString = 'Test1231312345678';
            string Case_ThreadID = 'ref:_'  + UserInfo.getOrganizationId().left(5)
            + UserInfo.getOrganizationId().mid(11,4)
            + '._'
            + cassIdString.left(5)
            + cassIdString.mid(10,5) + ':ref';
            email.subject = 'Test Email Service Case #  ' + Case_ThreadID;
            email.fromAddress = 'someaddress@akamai.com';
            email.htmlBody  = 'email body/n2225256325/nTitle Account ID:TestData '+ Case_ThreadID;
            email.ToAddresses = Test_EmailToCaseHandler.toAddresses2();
            //email.ToAddresses = new String[]{'billing@akamai.com','specialist@akamai.com','support@akamai.com','ps-tix@akamai.com','epe-support@akamai.com','testgggggggggggggggggggg@akamai.com','ccare@akamai.com','managedsecurity@akamai.com','customercare@akamai.com','aura-support@akamai.com'};
            // call the email service class and test it with the data in the testMethod
            EmailToCaseHandler  testInbound = new EmailToCaseHandler();
            testInbound.handleInboundEmail(email, env);
        }
        test.stopTest();
    }

    static testmethod void testInboundEmailCMG() {
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        Account acc = utilTestClass.CreateAccount('Test Acc Random 34');
        insert acc;
        Contact c = new Contact(FirstName = 'ConTest',LastName = 'Test Con', AccountId = acc.Id, email = 'email@example.com',Login__c = 'test login',MailingCountry = 'India', MailingState = 'DELHI');
        insert c;

        test.startTest();

        email.subject ='Testing CMG case';
        email.fromAddress = 'email@example.com';
        email.htmlBody = 'test';
        email.ToAddresses = new List<String>{EmailHandler_CS__c.getValues('CMG').Email_Address__c};
        email.ccAddresses = new String[]{'email@example.com'};
        EmailToCaseHandler testInbound = new EmailToCaseHandler();
        testInbound.handleInboundEmail(email, env);

        test.stopTest();
    }

}