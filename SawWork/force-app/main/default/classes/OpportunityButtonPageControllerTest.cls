@isTest(seeAllData=false)
public class OpportunityButtonPageControllerTest
{
    static User dmlUser = new User(id=UserInfo.getUserId());
    @testSetup
    static void createTestData()
    {
        System.runAs(dmlUser)
        {
            utilTestClass.insertCustomSettings(new List<String>{'GSM_Custom_Settings'});
            Account acc = utilTestClass.CreateAccount('__Test Account');
            acc.Vertical__c = 'Gaming';
            acc.Sub_Vertical__c = 'Console Mfs';
            insert acc;

            Contact con = utilTestClass.CreateContact('__Test Contact FirstName','__Test Contact LastName');
            con.AccountId = acc.Id;
            con.Email = 'generictesting@generictester.com';
            insert con;
        
            Lead lead = utilTestClass.CreateLead();
            lead.Disposition__c = 'Existing Customer';
            lead.Associated_Contact__c = con.Id;
            lead.Product_line__c='Aura';
            lead.Company = 'Akamai';
            lead.LastName = 'iAMlead';
            insert lead;
            
            Opportunity testOppty = utilTestClass.CreateOpportunity('Test Oppty','1-Create');
            Opportunity testOppty1 = utilTestClass.CreateOpportunity('Test Oppty Test','1-Create');
            testOppty1.CloseDate = Date.today();
            upsert testOppty1;
            testOppty.CloseDate = Date.today();
            testOppty.Duplicate_Opportunity__c = testOppty1.Id;
            testOppty.AccountId = acc.Id;
            upsert testOppty;
        }
    }
    public static testmethod void createViewOrderForm()
    {
        System.runAs(dmlUser)
        {
            Opportunity testOpptyQuery = [select Id,RecordtypeId,StageName from Opportunity where Name = 'Test Oppty'];
            Lead lead = [select id from lead limit 1];
            testOpptyQuery.Associated_Lead__c = lead.Id;
            update testOpptyQuery;

            Test.startTest();

            Test.setCurrentPage(Page.OpportunityButtonPage);
            ApexPages.currentPage().getParameters().put('fromButton','CreateViewOrderForm');
            ApexPages.currentPage().getParameters().put('recordId',testOpptyQuery.Id);
            ApexPages.currentPage().getParameters().put('recordTypeId',testOpptyQuery.RecordTypeId);
            ApexPages.currentPage().getParameters().put('stageName',testOpptyQuery.Stagename);
            ApexPages.currentPage().getParameters().put('getField','Order_Form_Url__c');

            OpportunityButtonPageController op = new OpportunityButtonPageController();

            PageReference pageRef = op.init();
            Order_Approval__c oa2 = new Order_Approval__c();
            oa2.Associated_Opportunity__c = testOpptyQuery.Id;
                                    
            upsert testOpptyQuery;
            List<Order_Approval__c> oaList = [select Id, Associated_Opportunity__r.Id, Associated_Opportunity__r.Momentum_Order_Form_Initiated__c, Associated_Opportunity__r.Momentum_Order_Form_Initiated_Date__c from Order_Approval__c where Associated_Opportunity__c = :testOpptyQuery.Id];
            oaList.add(oa2);
            OpportunityButtonPageController.updateMomentumFields(oaList);
            pageRef = op.init();

            Test.stopTest();
        }
    }

    public static testmethod void campaignManagerApproval()
    {
        System.runAs(dmlUser)
        {
            Opportunity testOpptyQuery = [select Id,RecordtypeId,StageName,Duplicate_Opportunity__c from Opportunity where Name = 'Test Oppty'];

            Test.startTest();

            Test.setCurrentPage(Page.OpportunityButtonPage);
            ApexPages.currentPage().getParameters().put('fromButton','CampaignManager');
            ApexPages.currentPage().getParameters().put('recordId',testOpptyQuery.Id);
            ApexPages.currentPage().getParameters().put('profileName','System Administrator');
            ApexPages.currentPage().getParameters().put('dupOpp',testOpptyQuery.Duplicate_Opportunity__c);

            OpportunityButtonPageController op = new OpportunityButtonPageController();

            PageReference pageRef = op.init();
            pageRef = op.init();
        
            String verifyAssert = OpportunityButtonPageController.campaignManagerApproval(testOpptyQuery.Id);
            System.assertEquals('There is no lead associated with this Opportunity', verifyAssert);
            Lead lead = [select id from lead limit 1];
            testOpptyQuery.Associated_Lead__c = lead.Id;
            upsert testOpptyQuery;
        
            verifyAssert = OpportunityButtonPageController.campaignManagerApproval(testOpptyQuery.Id);
            System.assertEquals('Successfully Approved this tieback', verifyAssert);
            
            testOpptyQuery.Campaign_Manager_Approved__c = true;
            upsert testOpptyQuery;
            verifyAssert = OpportunityButtonPageController.campaignManagerApproval(testOpptyQuery.Id);
            ApexPages.currentPage().getParameters().put('fromButton','SalesRepAcknowledge');
            pageRef = op.init();
            ApexPages.currentPage().getParameters().put('fromButton','TransferOpptyToPartner');
            pageRef = op.init();
            System.assertEquals('This Tieback has already been approved', verifyAssert);
            op.backToOppty();
            ApexPages.currentPage().getParameters().put('fromButton','MigrateDealRegData');
            pageRef = op.init();
            pageRef = op.performMigrateDealRegData();
            Test.stopTest();
        }
    }

    public static testmethod void submitForOppApproval()
    {
        System.runAs(dmlUser)
        {
            Opportunity testOpptyQuery = [select Id,RecordtypeId,StageName from Opportunity Where Name = 'Test Oppty'];
            Lead lead = [select id from lead limit 1];
            testOpptyQuery.Associated_Lead__c = lead.Id;
            testOpptyQuery.Deal_Type__c = 'Direct';
            update testOpptyQuery;

            Test.startTest();

            Test.setCurrentPage(Page.OpportunityButtonPage);
            ApexPages.currentPage().getParameters().put('fromButton','SubmitForApproval');
            ApexPages.currentPage().getParameters().put('recordId',testOpptyQuery.Id);
            ApexPages.currentPage().getParameters().put('rebate', 'false');

            OpportunityButtonPageController op = new OpportunityButtonPageController();

            PageReference pageRef = op.init();

            ApexPages.currentPage().getParameters().put('fcm', 'Not Null');
            pageRef = op.init();

            ApexPages.currentPage().getParameters().put('fromButton', 'KnowYourCustomer');
            pageRef = op.init();
            Test.stopTest();
        }
    }

    public static testmethod void testOpportunityListViewButtonPageExtn()
    {
        System.runAs(dmlUser)
        {
            Opportunity testOpptyQuery = [select Id,RecordtypeId,StageName, AccountId from Opportunity Where Name = 'Test Oppty'];
            List<Opportunity> opptyList = new List<Opportunity>();
            opptyList.add(testOpptyQuery);
            Test.startTest();
            OpportunityListViewButtonPageExtn ob = new OpportunityListViewButtonPageExtn();
            ob.getTrialOpportunities();

            PageReference pageRef = Page.TrialOpportunityButtonPage;
            pageRef.getParameters().put('id', testOpptyQuery.AccountId);
            Test.setCurrentPageReference(pageRef);
            
            ApexPages.StandardSetController opptyController = new ApexPages.StandardSetController(opptyList);
            OpportunityListViewButtonPageExtn tempController = new OpportunityListViewButtonPageExtn(opptyController);
            Test.stopTest();
        }
    }

}