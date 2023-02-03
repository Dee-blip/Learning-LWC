/**
    OrderApprovalTestClass
    @version 1.0
    @author : Karteek Mekala <kmekala@akamai.com>
    @Description : This class implements the unit tests for OrderApprovalClass. 
                   Use cases that are tested :
                   1. Different use cases while using the "Create Order Approval" button on the Oppty detail page.
                   2. Different use cases with the "Approvals Required" Multi-Select-Picklist.
                      The Rec-Type and the Owners change according to this field.
                   3. Check if CCG#,Legal# and DealDesk# fields from Order Approval are promoted to the associated Oppty.                  

    @History
    --Developer           --Date            --Change                   
    Karteek Kumar M       26/05/10          CR 610624  When OA.DD # is updated update Oppty.DD # (vs Oppty.ADS DD #) for ADS OA
    Karteek Kumar M       28/06/10          CR 568963  Yitong Data Visibility
                                            Removed CCG_Owner_Test.
                                            Replaced all OrderApproval.OwnerID with OrderpApproval.CCG_Owner__c
                                            Reformated the query indending.
    Ali KM                23/08/10          CR 734005 Change profile names and supporting code/WF/FV where appropriate from Acerno to ADS
                                            - Replacing 'Acerno' keyword with 'ADS' part of cleanup efforts.
    Vinayendra T N        23/08/10          CR 694234 China CDN, EdgeSuite Transition , PS Approval Process 
                                            - added test classes for PS,EdgeSuite Transition,China CDN Approval
    Ali KM                21/10/10         CR 812208 PDRA Update part-2
                                            - Added logic to run ONA if Account.Owner does not have an AccountReassignmentRule
                                            - Implemented ONA Name using Custom Settings - Account_Reassignment_Class_Settings__c
                                            - Also added new field Account_Reassignment_Rule__c.User_Role__c & new method:
                                                -) CreateAccountReassignmentRule()                                                          
                                            - Creating AccountReassignmentRule for User = SalesUser
                                                -) OrderApprovalTestClassInit()
    Lisha Murthy          06/01/12          CR 1498591  Create new DD# Modified field 
                                            - Checking this functionality in CDN_OpptyUpdate_Test() function
                                                -)If Deal desk status is 'Completed' -> DD# is updated to AKAM OA Id. These changes should be reflected in Oppty
                                                -)If Deal desk status is 'Not Needed' -> DD# is updated to null. These changes should be reflected in Oppty
*/
@isTest(seeAllData=false)
private class OrderApprovalTestClass 
{
    public static Map<String,GSM_Settings__mdt> testcaseCustomSettings;  
    static Id akamaiRecTypeId;
    static Id akamaiClosedRecTypeId;
    static Map<String,Id> recTypeMap;
    static Id oaRecTypeId; 
    static User  MinteUser = new User();
    static User dmlUser = new User(id=UserInfo.getUserId());   
    private static Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();

    static {
        MinteUser = [Select id from user where Alias = 'MINTE' limit 1][0];
        akamaiRecTypeId = [select Id from RecordType where Name='Akamai Opportunity'][0].Id;
        akamaiClosedRecTypeId = [select Id from RecordType where Name = 'Closed Opportunity'][0].Id;
        System.runAs(dmlUser) {
            Test.loadData(globalDescribe.get('Environment_Setup__c'), 'CS_Environment_Setup');
            Test.loadData(globalDescribe.get('Q2O_Custom_Settings__c'), 'Q2O_Custom_Settings');
            PSA_Settings__c psa = new PSA_Settings__c();
            psa.Name = 'Engineering Team Email';
            psa.Value__c = 'services-engg-qa@akamai.com';
            insert psa;
        }
    }

    @testSetup
    static void setupMethod() 
    {
        System.runAs(dmlUser) {

        testcaseCustomSettings = GsmUtilClass.getGsmSettingValue();

        List<GSM_Custom_Settings__c> Oblist = new List<GSM_Custom_Settings__c>();
        
        GSM_Custom_Settings__c ob = new GSM_Custom_Settings__c();
        ob.Name = 'CaseTrigger#updateContact';
        ob.Value__c = 'Collections, International Business Development, Invoice Review Case, Invoice Review Read Only, Momentum Case Record, Partner Portal Case, Product Management, SF Feedback';
        Oblist.add(ob);

        GSM_Custom_Settings__c ob1 = new GSM_Custom_Settings__c();
        ob1.Name = 'IR_CaseDefaultRecordTypeId';
        ob1.Value__c = '012G0000000ygAxIAI';
        Oblist.add(ob1);

        GSM_Custom_Settings__c ob2 = new GSM_Custom_Settings__c();
        ob2.Name = 'IR_CaseRecordTypeIds';
        ob2.Value__c = '012G0000000ygAxIAI,012G0000000ygB2IAI';
        Oblist.add(ob2);

        insert Oblist;

        SC_RiverbedCaseProdID__c sc = new SC_RiverbedCaseProdID__c();
        sc.Name = 'Riverbed_SAAS_OEM';
        sc.Case_Product_ID__c = 'a0TG0000003wloVMAQ';
        sc.RecordTypeID__c = '012G0000000z10xIAA';
        insert sc;

        List<Email_to_Case__c> EcsList = new List<Email_to_Case__c>();

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

        SCRecordTypeCustomSetting__c scr = new SCRecordTypeCustomSetting__c();
        scr.Name = 'NotificationTeam';
        scr.RecordTypeName__c = 'Professional Services&&AMG&&Technical&&Managed Security&&Carrier Products&&Emerging Products Engineering';
        insert scr;

        user accOwner = utilTestClass.CreateUser('SysAdmin', 'Worldwide', 'System Administrator');
        accOwner.IsActive = true;
        insert accOwner;
            
        Account acc = utilTestClass.CreateAccount('__Test Account');
        acc.OwnerId = accOwner.Id;
        acc.BillingCountry = 'India';
        acc.BillingState = 'DELHI';
        acc.website = 'www.OrderApprovalTestClass.com';
        insert acc;
            
        Contact con = utilTestClass.CreateContact('first','Test');
        con.Akam_Contact_Id__c = 'F-CO-2435149';
        con.AccountId = acc.id;
        insert con;
            
        }

    }

    // Create Order Approval Refresh function
    private static Order_Approval__c RefreshOrderOpp(String OrderAppId)
    {
        return [select  Id,
                    //Approvals_Required__c, 
                    Associated_Opportunity__c, 
                    RecordTypeId,
                    Compliance_Issue_Type__c,
                    Commission_Exception__c
              from Order_Approval__c 
              where Id=:OrderAppId][0];
              
              
    } 
    // Create Opportunity Refresh function
    private static Opportunity RefreshOpportunity(String OppId)
    {
        return [select  Id, 
                        CCG__c, 
                        Type,
                        StageName,
                        RecordTypeId,
                        Deal_Desk__c, 
                        Legal_Control__c,
                        CCG_Approved_Date__c, 
                        Compliance_Issue_Type__c,
                        Commission_Exception__c                     
                        from Opportunity where Id=:OppId];
             
    } 
    public static testmethod void CreateOrderApprovalforAutomatedPurchaseOppty()
    {
        System.runAs(MinteUser) {
            Test.startTest();
            Account acc = [select id from account where Name = '__Test Account' limit 1];
            Opportunity opp = utilTestClass.CreateOpportunity('__Test Oppty','1. Identify Need');
            opp.AccountId = acc.Id;
            opp.CloseDate = Date.today().addDays(5);
            opp.RecordTypeId = akamaiRecTypeId;
            opp.Opportunity_Type__c = 'Automated Purchase';
            opp.Validation_Override__c = true;
            //opp.createdby.alias = 'MINTE';
            insert opp;
            Test.stopTest();
        }
    }
    
    public static testmethod void CreateOrderApprovalforAutomatedTrialOppty()
    {
        System.runAs(MinteUser) {
            Test.startTest();
            Account acc = [select id from account where Name = '__Test Account' limit 1];
            Opportunity opp = utilTestClass.CreateOpportunity('__Test Oppty','1. Identify Need');
            opp.AccountId = acc.Id;
            opp.CloseDate = Date.today().addDays(5);
            opp.RecordTypeId = akamaiRecTypeId;
            opp.Opportunity_Type__c = 'Automated Trial';
            opp.Validation_Override__c = true;
            //opp.createdby.alias = 'MINTE';
            insert opp;
            Test.stopTest();
        }
    }

    public static testmethod void CreateOrderApprovalforContractChange()
    {
        System.runAs(MinteUser) {
            
            //OrderApprovalTestClassInit();
            Test.startTest();
            Account acc = [select id from account where Name = '__Test Account' limit 1];
            Opportunity opp = utilTestClass.CreateOpportunity('__Test Oppty','1. Identify Need');
            opp.AccountId = acc.Id;
            opp.CloseDate = Date.today().addDays(5);
            opp.RecordTypeId = akamaiRecTypeId;
            opp.Opportunity_Type__c = 'Contract Change';
            opp.Validation_Override__c = true;
            //opp.createdby.alias = 'MINTE';
            insert opp;
            Test.stopTest();
        }
    }

    public static testmethod void CreateOrderApprovalforBEDButton()
    {
        System.runAs(dmlUser) {
            Test.startTest();
            Account acc = [select id from account where Name = '__Test Account' limit 1];
            akamaiRecTypeId = [select Id from RecordType where Name='Akamai Opportunity'][0].Id;
            Opportunity opp = utilTestClass.CreateOpportunity('__Test Oppty','1. Identify Need');
            opp.AccountId = acc.Id;
            opp.CloseDate = Date.today().addDays(5);
            opp.RecordTypeId = akamaiRecTypeId;
            opp.Opportunity_Type__c = 'Contract Change';
            opp.Bed_Change__c = True;
            opp.Validation_Override__c = true;
            //opp.createdby.alias = 'MINTE';
            insert opp;
            Test.stopTest();
        }
    }
    public static testmethod void CreateOrderApprovalforExtendContractButton()
    {
        System.runAs(dmlUser) {
            Test.startTest();
            Account acc = [select id from account where Name = '__Test Account' limit 1];
            Opportunity opp = utilTestClass.CreateOpportunity('__Test Oppty','1. Identify Need');
            opp.AccountId = acc.Id;
            opp.CloseDate = Date.today().addDays(5);
            opp.RecordTypeId = akamaiRecTypeId;
            opp.Opportunity_Type__c = 'Contract Change';
            opp.Contract_Extension__c = True;
            opp.Validation_Override__c = true;
            //opp.createdby.alias = 'MINTE';
            insert opp;
            Test.stopTest();
        }
    }


    public static testmethod void CreateOrderApprovalandChangeOAStatus()
    {

        System.runAs(dmlUser) {
            
            Account acc = [select id from account where Name = '__Test Account' limit 1];
            Opportunity opp = utilTestClass.CreateOpportunity('__Test Oppty','1. Identify Need');
            opp.AccountId = acc.Id;
            opp.CloseDate = Date.today().addDays(-1);
            opp.RecordTypeId = akamaiRecTypeId;
            opp.Validation_Override__c = true;
            insert opp;
            Test.startTest();
            Order_Approval__c oa = [Select id,Associated_Opportunity__c, Associated_Opportunity__r.AccountId from Order_Approval__c where Associated_Opportunity__c = :opp.id limit 1][0];
            Case cs = new Case();
            cs.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Order Approval-Order Management').getRecordTypeId();
            cs.Order_Approval__c = oa.id;
            cs.Opportunity__c = opp.Id;
            cs.AccountId = oa.Associated_Opportunity__r.AccountId;
            cs.Valid_Until_Date__c = date.today().addDays(2);
            cs.Paper_Source__c = 'Cancellation Letter';
            cs.Order_Type__c = 'Account Assignment Letter';
            
            insert cs;
            
            //Approval_Details__c AD = utilTestClass.CreateApprovalDetailsReference(cs,'Auto-approved','Auto-approved','Auto-approved');
            Approval_Details__c AD = new Approval_Details__c();
            AD.Approval_Request__c = 'Auto-approved';
            AD.Approval_Status__c = 'Auto-approved';
            AD.Approver_Notes__c = 'Auto-approved';
            AD.Related_To__c = cs.id;
            AD.Order_Approval__c = cs.Order_Approval__c;
            AD.AKAM_Approved_Date__c = datetime.now();
            AD.Validation_Override__c = True;
            insert AD;
            
            opp = RefreshOpportunity(opp.Id);
            opp.StageName = 'Closed Lost';
            opp.Validation_Override__c = True;
            update opp;
            Test.stopTest();
        }
    }

    
    public static testmethod void CreateCasesAndApprovalDetails(){

        System.runAs(MinteUser) {
    
            Test.startTest();
            Account acc = [select id from account where Name = '__Test Account' limit 1];
            Opportunity opp = utilTestClass.CreateOpportunity('__Test Oppty1','1. Identify Need');
            opp.AccountId = acc.Id;
            opp.CloseDate = Date.today().addDays(5);
            opp.RecordTypeId = akamaiRecTypeId;
            opp.Opportunity_Type__c = 'Contract Change';
            opp.Validation_Override__c = true;
            insert opp;
            Test.stopTest();
        }
    }
    
    public static testmethod void TestViewOrderApprovalButton(){
        Test.startTest();
        Account acc = [select id from account where Name = '__Test Account' limit 1];
        Opportunity opp = utilTestClass.CreateOpportunity('__Test Oppty1','6. Signed');
        opp.AccountId = acc.Id;
        opp.CloseDate = Date.today().addDays(5);
        opp.RecordTypeId = akamaiClosedRecTypeId;
        opp.Validation_Override__c = true;
        insert opp;
        OrderApprovalClass.Create_OrderApproval(opp.id,opp.RecordTypeId,opp.StageName,'Testing');
        PageReference pageRef = Page.SF1_CreateViewOrderApproval;
        Test.setCurrentPageReference(pageRef);
        ApexPages.currentPage().getParameters().put('recordId',opp.Id);
        ViewOrderApproval button = new ViewOrderApproval();
        button.init();
        Test.stopTest();
    }
    
    public static testmethod void TestAzureMarketplace(){       
        Test.startTest();
        Account acc = [select id from account where Name = '__Test Account' limit 1];
        Opportunity opp = utilTestClass.CreateOpportunity('__Test Oppty1','1. Identify Need');
        opp.AccountId = acc.Id;
        opp.CloseDate = Date.today().addDays(5);
        opp.RecordTypeId = akamaiRecTypeId;
        opp.Validation_Override__c = true;
        opp.Source__c = 'Azure Marketplace';
        opp.Opportunity_Type__c = 'Non-Renewal: Add-On';
        insert opp;
        Test.stopTest();
        
    }
    
     public static testmethod void TestAutoRenewalOpportunity(){       
        Test.startTest();
        Account acc = [select id from account where Name = '__Test Account' limit 1];
        Opportunity opp = utilTestClass.CreateOpportunity('__Test Oppty1','1. Identify Need');
        opp.AccountId = acc.Id;
        opp.CloseDate = Date.today().addDays(5);
        opp.RecordTypeId = akamaiRecTypeId;
        opp.Opportunity_Type__c = 'Auto-Renewal';
        opp.Auto_Renewal__c = true;
        opp.Validation_Override__c = true;
        insert opp;
         
        opp.StageName = '6. Signed';
         
        update opp;
        
        Test.stopTest();       
    }
             
}