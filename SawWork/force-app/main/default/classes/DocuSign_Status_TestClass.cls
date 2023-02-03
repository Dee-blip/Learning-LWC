/**
    DocuSign_Status_TestClass
    @version 1.0
    @author : Ali KM <mohkhan@akamai.com>
    @Description : This class implements the unit tests for DocuSign_Status object. 
    @Date: 31/05/2011
    
    @History
    --Developer           --Date            --Change
    Ali KM                31/05/2011        CR 1132858 E-Sign: Flipping to SS-6 once signing process is complete should work only 
                                            if Customer Signee is part of the envelope
                                                -> Created this Class   
    Ali KM                08/04/2012        CR 1477954 Forecasting: Need to update QA env for forecasting
                                                -> Changing the StageName picklist 6-Commit to 6-Signed. 
                                                -> Also replacing where possible StageName 6-Signed with Probability = 90%. 
                                                   This way there is no dependency on StageName and instead relying on equivalent Probability% value.
    Ali KM                07/11/2012        CR 1895176 - Systems Allows Oppty to be moved to SS-6 even after the expiration of Valid Until Date
                                                -> Added a new test case to ensure reminderEmailAlerts don't get sent for DocuSignStatus records having Expired OFs (OA.ValidUntilDate)                                                                                                                     
 */
@isTest(SeeAllData = false)
private class DocuSign_Status_TestClass {
    //private static Map<String, Features_Toggle__c> featureToggleCustomSettings = Features_Toggle__c.getAll();
    private static Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
    private static Map<String, GSM_Settings__mdt> testcaseCustomSettings;
    private static Boolean initFlag = false;
    private static User oldOwner;
    private static User oldOwnerRSM;
    private static User newOwner;
    private static User newOwnerRSM;
    private static Id akamaiRecTypeId;
    private static Account_Reassignment_Rule__c oldOwnerRule;
    private static Account_Reassignment_Rule__c newOwnerRule;
    private static String DSEnvID = 'DS_TEST_123'; // IMP: keep it upper case only.
    private static String DSERSigner1RoleName = 'Customer Signatory 1';
    private static String DSERSigner2RoleName = 'Akamai RSM 1';
    static User dmlUser = new User(id=UserInfo.getUserId());
    /**
        CreateUser()
        - Return a new User with selected Alias, Profile and Role
    */
    /*private static User CreateUser(String pUsrAlias, String pProfile, String pRole)
    {
        Profile pr = [select Id from Profile where Name=:pProfile][0];
        UserRole role = [select Id, Name from UserRole where Name=:pRole][0];
        User newUser = new User(alias = pUsrAlias, 
                                email=pUsrAlias+'@akamai.com',
                                emailencodingkey='UTF-8', 
                                lastname=pUsrAlias, 
                                languagelocalekey='en_US',
                                localesidkey='en_US', 
                                timezonesidkey='America/Los_Angeles', 
                                username=pUsrAlias+'@akamai.com.tclass',
                                profileid = pr.Id, 
                                UserRoleId = role.Id );
        return newUser;     
    }*/

    /*private static Account CreateAccount(String pAccName, Id pOwnerId, String accountStatus)
    {
        Account acc = new Account();
        acc.Name = pAccName;
        acc.BillingCountry = 'India';
        acc.Vertical__c = 'Gaming';
        acc.Sub_Vertical__c = 'Console Mfs';
        acc.OwnerId = pOwnerId;
        acc.BillingCountry = 'India';
        acc.Type = accountStatus;
        acc.Partner_Type__c='Unknown';          
        return acc;
    }*/
    
    /*private static Contact CreateContact(String FirstName,String LastName)
    {
        Contact con = new Contact();
        con.FirstName = FirstName;
        con.LastName = LastName;
        con.Akamai_Vertical__c = 'Gaming';
        con.Sub_Vertical__c = 'Console Mfs';
        con.Phone = '99999';
        con.Email = 'Testing@Testing.com';
        con.Title = 'Tester';   
        con.MailingCountry = 'India';
        return con;
    }*/
   

    static{

        Map<String , String> customMap = New Map<String , String>();
        utilTestClass.insertCustomSettings(New Map<String,String>{'GSM_Custom_Settings__c'    => 'CS_GSM_Custom_Settings',
                                                                 'Communities_Settings__c'   => 'CS_Communities_Settings',
                                                                    'Features_Toggle__c' => 'CS_Features_Toggle',
                                                                    'UserTriggerClassSettings__c' => 'CS_UserTriggerClassSettings',
                                                                    'Account_Reassignment_Settings__c' => 'CS_Account_Reassignment_Settings',
                                                                  'Account_Reassignment_Class_Settings__c' => 'CS_Account_Reassignment_Class_Settings',
                                                                  'Address_Validation_Class_Settings__c' => 'CS_Address_Validation_Class_Settings',
                                                                  'PRM_Settings__c'           => 'CS_PRM_Settings',
                                                                  'Environment_Setup__c' => 'CS_Environment_Setup',
                                                                  'Q2O_Custom_Settings__c' => 'Q2O_Custom_Settings',
                                                                  'Order_approval_class_settings__c' => 'CS_Order_Approval_Class_Settings',
                                                                  'Sync_To_Siebel_Fields_Settings__c' => 'CS_Sync_To_Siebel_Fields_Settings'});
    
    //Test.loadData(globalDescribe.get('Q2O_Custom_Settings__c'), 'Q2O_Custom_Settings');
    //Test.loadData(globalDescribe.get('GSM_Custom_Settings__c'), 'CS_GSM_Custom_Settings');
    testcaseCustomSettings = GsmUtilClass.getGSMSettingValue();   
    OA_eSign_Intermediate__c esign = new OA_eSign_Intermediate__c();

    esign.Name ='dsConfigRecordName';
    esign.value__c ='DSX-147';
    insert esign;
    OA_eSign_Intermediate__c esign1 = new OA_eSign_Intermediate__c();
    esign1.Name ='SendEmailReminder';
    esign1.value__c ='true';
    insert esign1;
    // insert case
    
    SC_RiverbedCaseProdID__c sc = new SC_RiverbedCaseProdID__c();
        sc.Name = 'Riverbed_SAAS_OEM';
        sc.Case_Product_ID__c = 'a0TG0000003wloVMAQ';
        sc.RecordTypeID__c = '012G0000000z10xIAA';
        insert sc;
        
        SCRecordTypeCustomSetting__c scr = new SCRecordTypeCustomSetting__c();
        scr.Name = 'NotificationTeam';
        scr.RecordTypeName__c = 'Professional Services&&AMG&&Technical&&Managed Security&&Carrier Products&&Emerging Products Engineering';
        insert scr;
        list<Email_to_Case__c> EcsList = new list<Email_to_Case__c>();
        Email_to_Case__c ECs = new Email_to_Case__c();
        ECs.Name = 'Momentum';
        ECs.CaseRecord__c = '012A0000000OWfW';
        ECs.ContextAlias__c = 'CRMOPS';
        ECs.Severity__c = '3 - Difficult to do job';
        ECs.Contact__c = '003A000000Z4JBG';
        ECs.OrgWide__c = '0D2A00000004Cnh';
        ECs.reporterId__c = '0B7A0000000CaWW';
        ECs.GroupEmail__c = 'momentum-help@akamai.com';
        ECs.Queue_Email__c = 'momentum-admins@akamai.com';
        ECs.EmailTemplate__c = '00XA0000000bwQE';
        ECs.delimiter__c = '#case';
        ECs.Priority__c = 'Medium';
       // insert ECs;
        
        EcsList.add(ECs);

        Email_to_Case__c ECs1 = new Email_to_Case__c();
        ECs1.Name = 'ProdMgmt';
        ECs1.CaseRecord__c = '012A0000000OmQ8';
        ECs1.ContextAlias__c = 'CRMOPS';
        ECs1.Severity__c = '3 - Difficult to do job';
        ECs1.Contact__c = '003A000000Zs1L4';
        ECs1.OrgWide__c = '0D2A00000004CpJ';
        ECs1.reporterId__c = '0B7A0000000CaWW';
        ECs1.GroupEmail__c = 'chinacdn_application@akamai.com';
        ECs1.Queue_Email__c = 'China-app-sf@akamai.com';
        ECs1.EmailTemplate__c = '00XA0000000cIp6';
        ECs1.delimiter__c = '#case';
        ECs1.Priority__c = 'Medium';

        EcsList.add(ECs1);


        insert EcsList;
    
    }

    private static  void insertEsignCustomSetting(){
    OA_eSign_Intermediate__c esign = new OA_eSign_Intermediate__c();
    esign.Name ='dsConfigRecordName';
    esign.value__c ='DSX-147';
    insert esign;

    }

    private static dsfs__DocuSign_Envelope__c CreateDSE()
    {
        dsfs__DocuSign_Envelope__c dse = new dsfs__DocuSign_Envelope__c();
        dse.dsfs__DocuSign_Envelope_ID__c =  DSEnvID;
        return dse;
    }
    private static dsfs__DocuSign_Envelope__c RefreshDSE(String dseId)
    {
        return [Select Id, Name, dsfs__DocuSign_Envelope_ID__c from dsfs__DocuSign_Envelope__c where Id=:dseId];
    }
    private static dsfs__DocuSign_Envelope_Recipient__c CreateDSER(Contact pCon, dsfs__DocuSign_Envelope__c pDSE, String pDSERRoleName)
    {
        dsfs__DocuSign_Envelope_Recipient__c dser = new dsfs__DocuSign_Envelope_Recipient__c();
        dser.dsfs__DocuSign_EnvelopeID__c = pDSE.Id;
        dser.dsfs__RoleName__c = pDSERRoleName;
        dser.dsfs__DSER_ContactID__c = pCon.Id;
        return dser;
    }
    // Generate DS Recipient Status
    private static dsfs__DocuSign_Recipient_Status__c CreateDSRS(dsfs__DocuSign_Status__c pDss, Integer pRoutingOrder, String pEmailID, String pSigneeName)
    {   
        dsfs__DocuSign_Recipient_Status__c dsrs = new dsfs__DocuSign_Recipient_Status__c();
        dsrs.dsfs__Recipient_Status__c = 'Sent';
        dsrs.dsfs__DocuSign_Recipient_Email__c = pEmailID;
        dsrs.dsfs__DocuSign_Routing_Order__c = pRoutingOrder;
        dsrs.dsfs__DocuSign_Recipient_Title__c ='ASE - TEST';
        dsrs.Name = pSigneeName;
        dsrs.dsfs__Date_Sent__c = DateTime.now();
        dsrs.dsfs__DocuSign_Recipient_Id__c = 'XYZ' + pSigneeName;
        dsrs.dsfs__Parent_Status_Record__c =pDss.Id;
        return dsrs;
        //System.debug('dsrsID=' + dsrs.Id);
    }
    
    // Refresh DS Recipeint Status
    private static dsfs__DocuSign_Recipient_Status__c refreshDSRS(Id pDSRSID)
    {
        return [SELECT  Id, 
                dsfs__DocuSign_Routing_Order__c, 
                dsfs__DocuSign_Recipient_Title__c, 
                Name, 
                dsfs__DocuSign_Recipient_Id__c, 
                dsfs__Envelope_Id__c, 
                dsfs__Parent_Status_Record__c, 
                dsfs__Date_Declined__c, 
                dsfs__Date_Delivered__c, 
                dsfs__Date_Sent__c, 
                dsfs__Date_Signed__c, 
                dsfs__Decline_Reason__c, 
                dsfs__DocuSign_Recipient_Email__c, 
                dsfs__Recipient_Status__c 
                FROM    dsfs__DocuSign_Recipient_Status__c 
                WHERE   Id = :pDSRSID];
    }
    private static dsfs__DocuSign_Status__c CreateDSS(dsfs__DocuSign_Envelope__c pDSE)
    {
        dsfs__DocuSign_Status__c dss = new dsfs__DocuSign_Status__c();
        dss.dsfs__DocuSign_Envelope_ID__c = DSEnvID;
        dss.dsfs__Envelope_Status__c = 'Sent';
        dss.dsfs__Sent_Date_Time__c = DateTime.now().addDays(-1);
        dss.isCustomerEnvelope__c = false;
        return dss;
    }
    // Opportunity Refresh
    private static dsfs__DocuSign_Status__c RefreshDSS(String dssId)
    {
        return [select Id, dsfs__DocuSign_Envelope_ID__c, dsfs__Envelope_Status__c, isCustomerEnvelope__c from dsfs__DocuSign_Status__c where Id=:dssId];
    } 

    /**
        RefreshAccount(Account acc)
        - Refresh single account
    */
    private static Account RefreshAccount(Account acc)
    {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        return RefreshAccount(new Account[]{acc})[0];
    }
    /**
        RefreshAccount(Account[] acc)
        - Refresh bulk accounts
    */  
    private static Account[] RefreshAccount(Account[] accounts)
    {
        return [select Id, 
                       OwnerId, 
                       Account_Status__c 
                from Account 
                where Id IN :accounts];
    }           
    /**
        CreateAccountReassignmentRule()
            - generates a new AccountReassignmentRule based on parameters
            - returns Account_Reassignment_Rule__c      
    */
    /*private static Account_Reassignment_Rule__c  CreateAccountReassignmentRule(String ruleName, User associatedUser, User associatedUserRSM, String roleName)
    {
        Account_Reassignment_Rule__c  tempRule = new Account_Reassignment_Rule__c();
        temprule.Name = ruleName;
        temprule.Associated_User__c = associatedUser.Id;
        temprule.Associated_User_RSM__c = associatedUserRSM.Id;
        if(featureToggleCustomSettings.get('UserRoleUpdateThroughAssignmentRule').Toggle__c == true)        
            temprule.User_Role__c = roleName;
        return tempRule;
    }*/     
    /**
        CreateAccountReassignment(Account acc, Account_Reassignment_Rule__c rule)
        - Create an Account Reassignment Request
    */
    private static void CreateAccountReassignment(Account acc, Account_Reassignment_Rule__c rule)
    {
          PageReference pageRef = Page.AccountReassignment2;
          pageRef.getParameters().put('id', acc.id);
          Test.setCurrentPageReference(pageRef);
          AccountReassignmentInterfaceClass controller = new AccountReassignmentInterfaceClass();
          controller.accReassign.Assign_To__c = rule.Id;
          controller.save();
    }
    // Opportunity Create function
    /*
    private static Opportunity CreateOpportunity(String stageName)
    {
        Opportunity opp = new Opportunity();
        opp.Name = '__Test Oppty';
        opp.StageName = '1-Create';
        
        return opp;
    }*/

    // Opportunity Refresh function
    private static Opportunity RefreshOpportunity(String OppId)
    {
        return [select  Id, 
                        CCG__c, 
                        Type,
                        StageName,
                        RecordTypeId,
                        Deal_Desk__c, 
                        Legal_Control__c, 
                        DD_CCG_Expiration_Date__c,
                        CCG_Approved_Date__c, 
                        Compliance_Issue_Type__c,
                        Gross_Margin__c,
                        Commission_Exception__c           
                from Opportunity where Id=:OppId];
    } 

    // Create Order Approval Refresh function
    private static Order_Approval__c RefreshOrderOpp(String OrderAppId)
    {
        return [select  Id, 
                    Approvals_Required__c, 
                    Associated_Opportunity__c, 
                    RecordTypeId, 
                    CCG_Owner__c, 
                    Deal_Desk_Owner__c,
                    Legal_Owner__c, 
                    CCG__c, 
                    Deal_Desk__c, 
                    Legal__c, 
                    //DD_CCG_Expiration_Date__c,
                    CCG_Approved_Date__c,
                    Compliance_Issue_Type__c,
                    Gross_Margin__c,
                    Commission_Exception__c,
                    CCG_Status__c,
                    Deal_Desk_Status__c,
                    Legal_Status__c
              from Order_Approval__c 
              where Id=:OrderAppId][0];
    }
    // Create Order Approval Refresh function
    private static Order_Approval__c RefreshOrderOppAs(String OrderAppAsId)
    {
                return  [select Id, 
                         Associated_Opportunity__c, 
                         RecordTypeId, 
                         CCG_Owner__c, 
                         Deal_Desk_Owner__c,
                         Legal_Owner__c, 
                         CCG__c, 
                         Deal_Desk__c, 
                         Legal__c ,
                         Type__c,
                         CCG_Status__c,
                         DD_CCG_Expiration_Date__c
                from Order_Approval__c 
                         where Associated_Opportunity__c=:OrderAppAsId][0];
    }
    
    /**
        Init()
        - Intialize the static variables for this Test Class
    */
    private static void Init()
    {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        if(initFlag)
            return;
        String profileName = 'Sales - Media';
        String roleName = testcaseCustomSettings.get('User_Role').Value__c;
        // Create Old Owner User
        /*oldOwner = CreateUser('TST_OUSR', profileName, New_2015_ECG Media);
        oldOwnerRSM = CreateUser('TST_ORSM', profileName, 2014_ECG ANZ);
        newOwner = CreateUser('TST_NUSR', profileName, 2014_ECG ANZ);
        newOwnerRSM = CreateUser('TST_NRSM', profileName, 2014_ECG ANZ);*/
         

            oldOwner = utilTestClass.CreateUser('TST_OUSR', roleName, profileName);
            oldOwnerRSM = utilTestClass.CreateUser('TST_ORSM', roleName, profileName);
            newOwner = utilTestClass.CreateUser('TST_NUSR', roleName, profileName);
            newOwnerRSM = utilTestClass.CreateUser('TST_NRSM', roleName, profileName);
                   insert (new User[] {oldOwner, oldOwnerRSM, newOwner, newOwnerRSM});
        
        // Create rules for the users
        //oldOwnerRule = CreateAccountReassignmentRule(oldOwner.Name, oldOwner, oldOwnerRSM, '2014_ECG ANZ');
        oldOwnerRule = utilTestClass.CreateAccountReassignmentRule(oldOwner.Name, oldOwner.Id, roleName);
        oldOwnerRule.Associated_User_RSM__c = oldOwnerRSM.Id;
        
        //newOwnerRule = CreateAccountReassignmentRule(newOwner.Name, newOwner, newOwnerRSM, '2014_ECG ANZ');
        newOwnerRule = utilTestClass.CreateAccountReassignmentRule(newOwner.Name, newOwner.Id, roleName);
        newOwnerRule.Associated_User_RSM__c = newOwnerRSM.Id;
        insert (new Account_Reassignment_Rule__c[] {oldOwnerRule, newOwnerRule});
        akamaiRecTypeId = [select Id from RecordType where Name='Akamai Opportunity'][0].Id;
        initFlag = true;      
        
    }

    /**
        SingleDocuSignInitiatorReminderEmail_PositiveTest()
        - Send out Email to E-Sign Initiator.
        1. Initiator Test Case:
            a. Create
                DSS, DSRS, OA
                - Set the NextReminderDate less than now for DSS, Sender Email
            b. Now call the CronJob handle in DSS class
            c. Add code in DSS class to return string for Test.isRunning() calls instead of sending out emails.
            d. Check if Dss.NextReminderDate > now() + ReminderIntervalDays.
            e. Now call the CronJob handle in DSS class; no reminder alerts should go out.
            2. SS-6 Flip Test Case:
                - reuse records from above.
            a. Check the code that takes care of flipping the SS-6 and build accordinlgy.
    */
    static testmethod void SingleDocuSignInitiatorReminderEmail_PositiveTest()
    {
    
    System.runAs(dmlUser){
        // Initialize
        test.startTest();

        Init();

        
        // Create Account
        //Account acc = CreateAccount('__Test Account', oldOwner.Id, 'Lead');
        Account acc = utilTestClass.CreateAccount('__ Test Account');
        acc.Vertical__c = 'Gaming';
        acc.Sub_Vertical__c = 'Console Mfs';
        acc.OwnerId = oldOwner.Id;
        acc.Type = 'Lead';
        acc.Partner_Type__c='Unknown';
        //Account acc = CreateAccount('__Test Account');        
        insert acc;

        Contact con = utilTestClass.CreateContact('__ Test First','__Test Contact');
        con.AccountId = acc.Id;
        insert con;
        
        // Create Opportunity
        //Opportunity opp = CreateOpportunity('1-Create');
        Opportunity opp = utilTestClass.CreateOpportunity('__Test Oppty','1-Create');
        opp.AccountId = acc.Id;
        opp.CloseDate = Date.today().addDays(30);
        opp.RecordTypeId = akamaiRecTypeId;
        insert opp;

        // Create Order Approval
        String returnMsg;
        returnMsg = OrderApprovalClass.Create_OrderApproval(opp.Id,opp.RecordTypeId+'',opp.StageName);
        //system.assertEquals('DUMMY',returnMsg);
       // system.assert(returnMsg.contains('1:'));
        
        // Refresh Records
        opp = RefreshOpportunity(opp.Id);
        Order_Approval__c oa = RefreshOrderOppAs(opp.Id);
        oa.DD_CCG_Expiration_Date__c = Date.today().addDays(-2);
        update oa;

        opp.DD_CCG_Expiration_Date__c = Date.today().addDays(-2);
        update opp;


        dsfs__DocuSign_Envelope__c dse = CreateDSE();
        insert dse;
        
                // Create DocuSign Status record
        dsfs__DocuSign_Status__c dss = new dsfs__DocuSign_Status__c();
        dss.dsfs__DocuSign_Envelope_ID__c = dse.dsfs__DocuSign_Envelope_ID__c;
        dss.dsfs__Envelope_Status__c = 'Sent';
        dss.dsfs__Sent_Date_Time__c = DateTime.now().addDays(-1);
        dss.isCustomerEnvelope__c = false;
        dss.Order_Approval__c = oa.Id;
        dss.dsfs__Sender__c = 'test sender';
        dss.dsfs__Sender_Email__c = 'mohkhan@akamai.com';
        dss.Next_Reminder_Alert__c = Datetime.now().addDays(-1);
        System.debug('Next Reminder Alert Test =' + dss.Next_Reminder_Alert__c);
        insert dss;
        
        // Create DocuSign Recipient Status record
        dsfs__DocuSign_Recipient_Status__c dsrs = new dsfs__DocuSign_Recipient_Status__c();
        dsrs.dsfs__Recipient_Status__c = 'Sent';
        dsrs.dsfs__DocuSign_Recipient_Email__c = 'abc_test1@akamai.com';
        dsrs.dsfs__DocuSign_Routing_Order__c = 1;
        dsrs.dsfs__DocuSign_Recipient_Title__c ='ASE - TEST';
        dsrs.Name = 'Test Signee1';
        dsrs.dsfs__Date_Sent__c = DateTime.now().addDays(-1);
        dsrs.dsfs__DocuSign_Recipient_Id__c = 'XYZ' + 'Test Signee1';
        dsrs.dsfs__Parent_Status_Record__c =dss.Id;
        //dsfs__DocuSign_Recipient_Status__c dsrs1 = CreateDSRS(dss, 1, 'abc_test1@akamai.com', 'Test Signee1');



        insert dsrs;
        dsfs__DocuSign_Envelope_Recipient__c DocuSignEnvelopeRecipient1 = CreateDSER(con,dse,DSERSigner1RoleName);
        dsfs__DocuSign_Envelope_Recipient__c DocuSignEnvelopeRecipient2 = CreateDSER(con,dse,DSERSigner2RoleName);
        insert DocuSignEnvelopeRecipient1;
        insert DocuSignEnvelopeRecipient2;

        String result;
        
        //Invoke the initiator schedule run
        result = DocuSignStatusTriggerClass.ButtonExecute(); 
        //System.debug('TEST Initiator Invoke Results First Run=' + result);
        
        
        // execute another initiator schedule run - this should not send out any emails.
        result = DocuSignStatusTriggerClass.invokeDocuSignInitiatorReminderJob('SendDocuSignInitiatorReminderEmail');
        //System.debug('TEST Initiator Invoke Results SECOND RUN=' + result);
    
        System.assertNotEquals(opp.StageName, '6. Signed');

        // Test to ensure Oppty SS is flipped.
        dss.isCustomerEnvelope__c = true;
        dss.dsfs__Envelope_Status__c = 'Completed';
        update dss;
        
        opp = RefreshOpportunity(opp.Id);
        //System.assertEquals(opp.StageName, '6-Signed');
        test.stoptest();
        }

    }
    
    /**
        SingleDocuSignInitiatorReminderEmail_ExpiredOrderForm_Test()
        - Test the OF Expired DocuSign doesn't trigger Reminder Email alerts.
    */
    static testmethod void SingleDocuSignInitiatorReminderEmail_ExpiredOrderForm_Test()
    {
        // Initialize
        System.runAs(dmlUser){
        test.startTest();
        Init();
        // Create Account
        //Account acc = CreateAccount('__Test Account', oldOwner.Id, 'Lead');
        Account acc = utilTestClass.CreateAccount('__ Test Account');
        acc.Vertical__c = 'Gaming';
        acc.Sub_Vertical__c = 'Console Mfs';
        acc.OwnerId = oldOwner.Id;
        acc.Type = 'Lead';
        acc.Partner_Type__c='Unknown';
        //Account acc = CreateAccount('__Test Account');        
        insert acc;
        
        // Create Opportunity
        //Opportunity opp = CreateOpportunity('1-Create');
        Opportunity opp = utilTestClass.CreateOpportunity('__Test Oppty','1-Create');
        opp.AccountId = acc.Id;
        opp.CloseDate = Date.today().addDays(30);
        opp.RecordTypeId = akamaiRecTypeId;
        //opp.DD_CCG_Expiration_Date__c = Date.today().addDays(-2);
        insert opp;

        // Create Order Approval
        String returnMsg;
        returnMsg = OrderApprovalClass.Create_OrderApproval(opp.Id,opp.RecordTypeId+'',opp.StageName);
        //system.assertEquals('DUMMY',returnMsg);
        //system.assert(returnMsg.contains('1:'));
        
        // Refresh Records
        opp = RefreshOpportunity(opp.Id);
        Order_Approval__c oa = RefreshOrderOppAs(opp.Id);
        
        oa.DD_CCG_Expiration_Date__c = Date.today().addDays(-2);
        update oa;
        system.assertEquals(Date.today().addDays(-2), oa.DD_CCG_Expiration_Date__c);
        
        oa = RefreshOrderOppAs(opp.Id);
        //test.startTest();
        // Create DocuSign Status record
        dsfs__DocuSign_Status__c dss = new dsfs__DocuSign_Status__c();
        dss.dsfs__DocuSign_Envelope_ID__c = 'DS_TEST_123';
        dss.dsfs__Envelope_Status__c = 'Sent';
        dss.dsfs__Sent_Date_Time__c = DateTime.now().addDays(-1);
        dss.isCustomerEnvelope__c = false;
        dss.Order_Approval__c = oa.Id;
        dss.dsfs__Sender__c = 'test sender';
        dss.dsfs__Sender_Email__c = 'mohkhan@akamai.com';
        dss.Next_Reminder_Alert__c = Datetime.now().addDays(-1);
        System.debug('Next Reminder Alert Test =' + dss.Next_Reminder_Alert__c);
        insert dss;
        
        // Create DocuSign Recipient Status record
        dsfs__DocuSign_Recipient_Status__c dsrs = new dsfs__DocuSign_Recipient_Status__c();
        dsrs.dsfs__Recipient_Status__c = 'Sent';
        dsrs.dsfs__DocuSign_Recipient_Email__c = 'abc_test1@akamai.com';
        dsrs.dsfs__DocuSign_Routing_Order__c = 1;
        dsrs.dsfs__DocuSign_Recipient_Title__c ='ASE - TEST';
        dsrs.Name = 'Test Signee1';
        dsrs.dsfs__Date_Sent__c = DateTime.now().addDays(-1);
        dsrs.dsfs__DocuSign_Recipient_Id__c = 'XYZ' + 'Test Signee1';
        dsrs.dsfs__Parent_Status_Record__c =dss.Id;
        dsfs__DocuSign_Recipient_Status__c dsrs1 = CreateDSRS(dss, 1, 'abc_test1@akamai.com', 'Test Signee1');

        insert dsrs;
        
        dss.isCustomerEnvelope__c = true;
        dss.dsfs__Envelope_Status__c = 'Sent';
        update dss;
        
        String result;
        
        // execute another initiator schedule run - this should not send out any emails.
        result = DocuSignStatusTriggerClass.invokeDocuSignInitiatorReminderJob('SendDocuSignInitiatorReminderEmail');
        // return should contain Count: 0 if no Emails were sent out.
        System.debug('result=' + result);
        test.stoptest();
        }

    }

    /**
        SingleDocuSignStatus_PositiveTest()
        - Check if Envelope isCustomerEnvelope.
    */
    static testmethod void SingleDocuSignStatus_PositiveTest()
    {
    System.runAs(dmlUser){
        // Initialize
        test.startTest();
        Init();

        // Create Account
        //Account acc = CreateAccount('__Test Account', oldOwner.Id, 'Lead');
        Account acc = utilTestClass.CreateAccount('__ Test Account');
        acc.Vertical__c = 'Gaming';
        acc.Sub_Vertical__c = 'Console Mfs';
        acc.OwnerId = oldOwner.Id;
        acc.Type = 'Lead';
        acc.Partner_Type__c='Unknown';
        //Account acc = CreateAccount('__Test Account');        
        insert acc;
        
        // Create contact
        Contact con = utilTestClass.CreateContact('__ Test First','__Test Contact');
        con.AccountId = acc.Id;
        insert con;
        
        // Create DSEnvelope
        dsfs__DocuSign_Envelope__c dse = CreateDSE();
        insert dse;
        
        // Create DSERecipients
        dsfs__DocuSign_Envelope_Recipient__c dser1 = CreateDSER(con,dse,DSERSigner1RoleName);
        insert dser1;
        dsfs__DocuSign_Envelope_Recipient__c dser2 = CreateDSER(con,dse,DSERSigner2RoleName);
        insert dser2;
        
        // Create DSS
        dsfs__DocuSign_Status__c dss = CreateDSS(dse);
        insert dss;
                
        // refresh dse
        dse = RefreshDSE(dse.Id);
        
        // Assertions
        System.assertEquals(dse.dsfs__DocuSign_Envelope_ID__c, 'DS_TEST_123');
        
        //check for dser values
        System.assertEquals(dser1.dsfs__DocuSign_EnvelopeID__c, dse.Id);
        System.assertEquals(dser1.dsfs__RoleName__c, 'Customer Signatory 1');
        
        System.assertEquals(dser2.dsfs__DocuSign_EnvelopeID__c, dse.Id);
        System.assertEquals(dser2.dsfs__RoleName__c, 'Akamai RSM 1');
        
        // refresh dss
        dss = RefreshDSS(dss.Id);
        
        // check if isCustomerEnvelope is Updated
        System.assertEquals(dss.dsfs__DocuSign_Envelope_ID__c, 'DS_TEST_123');
        System.assertEquals(dss.dsfs__Envelope_Status__c, 'Sent');
        System.assertEquals(dss.isCustomerEnvelope__c, true);
        
        // update the dss Envelope Status to Completed
        dss.dsfs__Envelope_Status__c = 'Completed';
        update dss;
        
        dss = RefreshDSS(dss.Id);
        System.assertEquals(dss.dsfs__Envelope_Status__c, 'Completed');
           test.stopTest();
    }

    }
        static testmethod void SendEmail()
    {
        // Initialize
        System.runAs(dmlUser){
        test.startTest();
        Init();
        // Create Account
        //Account acc = CreateAccount('__Test Account', oldOwner.Id, 'Lead');
        Account acc = utilTestClass.CreateAccount('__ Test Account');
        acc.Vertical__c = 'Gaming';
        acc.Sub_Vertical__c = 'Console Mfs';
        acc.OwnerId = oldOwner.Id;
        acc.Type = 'Lead';
        acc.Partner_Type__c='Unknown';
        //Account acc = CreateAccount('__Test Account');        
        insert acc;
        
        // Create Opportunity
        //Opportunity opp = CreateOpportunity('1-Create');
        Opportunity opp = utilTestClass.CreateOpportunity('123__Test Oppty','1-Create');
        opp.AccountId = acc.Id;
        opp.CloseDate = Date.today().addDays(30);
        opp.RecordTypeId = akamaiRecTypeId;
        //opp.DD_CCG_Expiration_Date__c = Date.today().addDays(-2);
        insert opp;

        // Create Order Approval
        String returnMsg;
        returnMsg = OrderApprovalClass.Create_OrderApproval(opp.Id,opp.RecordTypeId+'',opp.StageName);
        //system.assertEquals('DUMMY',returnMsg);
        //system.assert(returnMsg.contains('1:'));
        
        // Refresh Records
        opp = RefreshOpportunity(opp.Id);
        Order_Approval__c oa = RefreshOrderOppAs(opp.Id);
        
        oa.DD_CCG_Expiration_Date__c = Date.today().addDays(-2);
        update oa;
        system.assertEquals(Date.today().addDays(-2), oa.DD_CCG_Expiration_Date__c);
        
        oa = RefreshOrderOppAs(opp.Id);

        opp.DD_CCG_Expiration_Date__c = oa.DD_CCG_Expiration_Date__c;
        update opp;
        Case cs2 = new Case();
         cs2.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Order Approval-Order Management').getRecordTypeId();
        cs2.Order_Approval__c =oa.id;
        cs2.Opportunity__c =opp.Id;
        cs2.AccountId =acc.id;
        cs2.Valid_Until_Date__c = date.today().addDays(-2);
        cs2.Paper_Source__c = 'Cancellation Letter';
        cs2.Order_Type__c = 'Account Assignment Letter';
        insert cs2;                      
        opp = RefreshOpportunity(opp.Id);

        System.debug('Expiration Date:'+opp.DD_CCG_Expiration_Date__c);
        //test.startTest();
        // Create DocuSign Status record
        dsfs__DocuSign_Status__c dss = new dsfs__DocuSign_Status__c();
        dss.dsfs__DocuSign_Envelope_ID__c = 'DS_TEST_123';
        dss.dsfs__Envelope_Status__c = 'Sent';
        dss.dsfs__Sent_Date_Time__c = DateTime.now().addDays(-1);
        dss.isCustomerEnvelope__c = false;
        dss.Order_Approval__c = oa.Id;
        dss.dsfs__Sender__c = 'test sender';
        dss.dsfs__Sender_Email__c = 'mohkhan@akamai.com';
        dss.Next_Reminder_Alert__c = Datetime.now().addDays(-1);
        System.debug('Next Reminder Alert Test =' + dss.Next_Reminder_Alert__c);
        insert dss;
        
        // Create DocuSign Recipient Status record
        dsfs__DocuSign_Recipient_Status__c dsrs = new dsfs__DocuSign_Recipient_Status__c();
        dsrs.dsfs__Recipient_Status__c = 'Sent';
        dsrs.dsfs__DocuSign_Recipient_Email__c = 'abc_test1@akamai.com';
        dsrs.dsfs__DocuSign_Routing_Order__c = 1;
        dsrs.dsfs__DocuSign_Recipient_Title__c ='ASE - TEST';
        dsrs.Name = 'Test Signee1';
        dsrs.dsfs__Date_Sent__c = DateTime.now().addDays(-1);
        dsrs.dsfs__DocuSign_Recipient_Id__c = 'XYZ' + 'Test Signee1';
        dsrs.dsfs__Parent_Status_Record__c =dss.Id;
        //dsfs__DocuSign_Recipient_Status__c dsrs1 = CreateDSRS(dss, 1, 'abc_test1@akamai.com', 'Test Signee1');

        insert dsrs;
        
        dss.isCustomerEnvelope__c = true;
        dss.dsfs__Envelope_Status__c = 'Completed';
        update dss;
        
        String result;
        
        // execute another initiator schedule run - this should not send out any emails.
        result = DocuSignStatusTriggerClass.invokeDocuSignInitiatorReminderJob('SendDocuSignInitiatorReminderEmail');
        // return should contain Count: 0 if no Emails were sent out.
        System.debug('result=' + result);
        test.stoptest();
        }

    }

    static testmethod void SingleDocuSignInitiatorReminderEmail_PositiveTest1()
    {
    
    System.runAs(dmlUser){
        // Initialize
        test.startTest();

        Init();
        // Create Account
        //Account acc = CreateAccount('__Test Account', oldOwner.Id, 'Lead');
        Account acc = utilTestClass.CreateAccount('__ Test Account');
        acc.Vertical__c = 'Gaming';
        acc.Sub_Vertical__c = 'Console Mfs';
        acc.OwnerId = oldOwner.Id;
        acc.Type = 'Lead';
        acc.Partner_Type__c='Unknown';
        //Account acc = CreateAccount('__Test Account');        
        insert acc;
        
        // Create Opportunity
        //Opportunity opp = CreateOpportunity('1-Create');
        Opportunity opp = utilTestClass.CreateOpportunity('__Test Oppty','1-Create');
        opp.AccountId = acc.Id;
        opp.CloseDate = Date.today().addDays(30);
        opp.RecordTypeId = akamaiRecTypeId;
        insert opp;

        // Create Order Approval
        String returnMsg;
        returnMsg = OrderApprovalClass.Create_OrderApproval(opp.Id,opp.RecordTypeId+'',opp.StageName);
        //system.assertEquals('DUMMY',returnMsg);
       // system.assert(returnMsg.contains('1:'));
        
        // Refresh Records
        opp = RefreshOpportunity(opp.Id);
        Order_Approval__c oa = RefreshOrderOppAs(opp.Id);
        
        // 
                /*  Case cs1 = new Case();
                        cs1.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Order Approval-Order Management').getRecordTypeId();
                        cs1.Order_Approval__c =oa.id;
                        cs1.Opportunity__c =opp.Id;
                        cs1.AccountId =acc.id;
                       // cs.Valid_Until_Date__c = date.today().addDays(3);
                        cs1.Paper_Source__c = 'Cancellation Letter';
                        cs1.Order_Type__c = 'Account Assignment Letter';
                        
                        insert cs1;*/
        
                       // Create DocuSign Status record
        dsfs__DocuSign_Status__c dss = new dsfs__DocuSign_Status__c();
        dss.dsfs__DocuSign_Envelope_ID__c = '12345';
        dss.dsfs__Envelope_Status__c = 'Sent';
        dss.dsfs__Sent_Date_Time__c = DateTime.now().addDays(-1);
        dss.isCustomerEnvelope__c = false;
        dss.Order_Approval__c = oa.Id;
        dss.dsfs__Sender__c = 'test sender';
        dss.dsfs__Sender_Email__c = 'mohkhan@akamai.com';
        dss.Next_Reminder_Alert__c = Datetime.now().addDays(-1);
        System.debug('Next Reminder Alert Test =' + dss.Next_Reminder_Alert__c);
        insert dss;
        
        // Create DocuSign Recipient Status record
        dsfs__DocuSign_Recipient_Status__c dsrs = new dsfs__DocuSign_Recipient_Status__c();
        dsrs.dsfs__Recipient_Status__c = 'Sent';
        dsrs.dsfs__DocuSign_Recipient_Email__c = 'abc_test1@akamai.com';
        dsrs.dsfs__DocuSign_Routing_Order__c = 1;
        dsrs.dsfs__DocuSign_Recipient_Title__c ='ASE - TEST';
        dsrs.Name = 'Test Signee1';
        dsrs.dsfs__Date_Sent__c = DateTime.now().addDays(-1);
        dsrs.dsfs__DocuSign_Recipient_Id__c = 'XYZ' + 'Test Signee1';
        dsrs.dsfs__Parent_Status_Record__c =dss.Id;
        //dsfs__DocuSign_Recipient_Status__c dsrs1 = CreateDSRS(dss, 1, 'abc_test1@akamai.com', 'Test Signee1');

        insert dsrs;
        
        String result;
        
        //Invoke the initiator schedule run
        result = DocuSignStatusTriggerClass.ButtonExecute(); 
        //System.debug('TEST Initiator Invoke Results First Run=' + result);
        
        
        // execute another initiator schedule run - this should not send out any emails.
        result = DocuSignStatusTriggerClass.invokeDocuSignInitiatorReminderJob('SendDocuSignInitiatorReminderEmail');
        //System.debug('TEST Initiator Invoke Results SECOND RUN=' + result);
    
        System.assertNotEquals(opp.StageName, '6. Signed');

        // Test to ensure Oppty SS is flipped.
        dss.isCustomerEnvelope__c = true;
        dss.dsfs__Envelope_Status__c = 'Completed';
        update dss;
        test.stoptest();
        opp = RefreshOpportunity(opp.Id);
       // System.assertEquals(opp.StageName, '6. Signed');
        
        }

    }
    
              static testmethod void extraCoverage()
        {
                System.runAs(dmlUser){

                        Account genericAcc = new Account();
                        genericAcc.Name = 'Test Acc 1234567890';
                        genericAcc.BillingCountry = 'India';
                        genericAcc.BillingState = 'DELHI';
                        genericAcc.Website='https://TestWinOrg457.co.in';
                        genericAcc.CurrencyIsoCode = 'USD';
                        genericAcc.Credit_Check_Status__c = 'Credit Approved';
                        insert genericAcc;

                        Opportunity newOppty = new Opportunity();
                        newOppty.Name = 'TestOppty123467890';
                        newOppty.StageName = '1-Create';
                        newOppty.accountId = genericAcc.Id;
                        newOppty.CloseDate = Date.today();
                        //newOppty.DD_CCG_Expiration_Date__c = Date.today().addDays(-2);
                        insert newOppty;

                        Order_Approval__c newOA = new Order_Approval__c();
                        newOA.Associated_Opportunity__c = newOppty.Id;
                        newOA.DD_CCG_Expiration_Date__c = Date.today().addDays(-3);
                        insert newOA;
                        
                    
                       /* Case cs = new Case();
                        cs.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Order Approval-Order Management').getRecordTypeId();
                        cs.Order_Approval__c = newOA.id;
                        cs.Opportunity__c = newOppty.Id;
                        cs.AccountId = genericAcc.id;
                        cs.Valid_Until_Date__c = date.today().addDays(-3);
                        cs.Paper_Source__c = 'Cancellation Letter';
                        cs.Order_Type__c = 'Account Assignment Letter';
                        
                        insert cs;*/

                        dsfs__DocuSign_Status__c dss = new dsfs__DocuSign_Status__c();
                        dss.dsfs__DocuSign_Envelope_ID__c = 'DS_TEST_1234567890';
                        dss.dsfs__Envelope_Status__c = 'Sent';
                        dss.Order_Approval__c = newOA.Id;
                        //dss.PreviousOFExpiredAlertsValidUntilDate__c = Date.today();
                        dss.dsfs__Sent_Date_Time__c = DateTime.now().addDays(-1);
                        dss.dsfs__Sender_Email__c = 'e@email.com';
                        dss.isCustomerEnvelope__c = true;
                        //dss.isCustomerEnvelope__c = false;
                        insert dss;
                        //dss.sendOFExpiredAlert__c = 'Y';
                        //update dss;
                        DocuSignStatusTriggerClass dsClassHandle = new DocuSignStatusTriggerClass();
                        String result = dsClassHandle.pendingESignWithExpiredOrderFormEmailAlert();
                        String str = DocuSignStatusTriggerClass.invokePendingESignWithExpiredOrderFormEmailAlert();
                    
                    String errorMessage = DocuSignStatusTriggerClass.getErrorMessage();
                }



        }
        
      
    
    
}