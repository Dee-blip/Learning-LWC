@isTest(seeAllData=false)
public class L2Q_OpportunityTriggerTestClass {
    private static Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
    static User dmlUser = utilTestClass.getTestRunUser();
    
    @testSetup
    static void setupMethod() {
        System.runAs(dmlUser) {
            ManagedPkgErrorClass.isFromManagedPackage = false;
            Test.loadData(globalDescribe.get('Communities_Settings__c'), 'CS_Communities_Settings');
            Test.loadData(globalDescribe.get('Environment_Setup__c'), 'CS_Environment_Setup');
            
            String user_role = GsmUtilClass.getGSMSettingValue('User_Role');
            Id profileId = GsmUtilClass.getGSMSettingValue('PartnerCommunityUserProfileId');
            
            User accOwnerUser = [select id from User where Profile.Name = 'Sales Operations' and IsActive = True limit 1][0];
            User accOwnerMO = [select id from User where Profile.Name = 'Marketing Operations' and IsActive = True limit 1][0];
            User u1 = [select id from User where Profile.Name = 'Business Operations' and IsActive = True limit 1][0];
            
            List<Account_Reassignment_Rule__c> ruleList = new List<Account_Reassignment_Rule__c>();
            Account_Reassignment_Rule__c rule = utilTestClass.CreateAccountReassignmentRule('__TestRule', accOwnerUser.Id, user_role);
            rule.SubTerritory__c = 'Unknown-50001';

            ruleList.add(rule);
            Account_Reassignment_Rule__c rule1 = utilTestClass.CreateAccountReassignmentRule('__TestRule1', accOwnerMO.Id, 'Sales Operations');
            rule1.SubTerritory__c = 'Unknown-50001';
            ruleList.add(rule1);
            Account_Reassignment_Rule__c rule2 = utilTestClass.CreateAccountReassignmentRule('__TestRule2', u1.Id, 'Worldwide');
            rule2.SubTerritory__c = 'Unknown-50001';
            ruleList.add(rule2);
            insert ruleList;
                        
            List<Account> acclist = new List<Account>();
            Account acc = new Account();
            acc.Name = '__Test Account';
            acc.OwnerId = accOwnerUser.Id;
            acc.BillingCountry = 'India';
            acc.BillingState = 'Delhi';
            acclist.add(acc);
            Account acc1 = new Account();
            acc1.Name = '__Test Account1';
            acc1.OwnerId = accOwnerMO.Id;
            acc.Partner_Type__c = 'Unknown';
            acc1.BillingCountry = 'USA';
            acc1.BillingState = 'CA';
            acc1.BillingPostalCode ='12345';
            acclist.add(acc1);
            Account acc2=utilTestClass.CreateAccount('Test acc__1');
            acc2.BillingCountry = 'USA';
            acc2.BillingState = 'CA';
            acc2.BillingPostalCode ='12348';
            acclist.add(acc2);
            Account Partneracc=utilTestClass.CreateAccount('Test Partneracc__1');
            Partneracc.POA_Email_List__c='vinayendra@vinayendra.com';
            acclist.add(Partneracc);
            Account acc3 = utilTestClass.CreateAccount('TEST_acc1');
            acc3.Type= 'Lead';
            acc3.Vertical__c = 'Automotive';
            acclist.add(acc3);
            Account acc5=utilTestClass.CreateAccount('Test acc__5');
            acc5.OwnerId=u1.Id;
            acc5.website = 'www.khtest.com';
            accList.add(acc5);
            Account acc6 = utilTestClass.CreateAccount('Test acc__6');
            acc6.website = 'www.pojutest.com';
            acc6.Finance_Region__c = 'INDIA';
            acc6.Type = 'Akamai Internal - Active';
            accList.add(acc6);
            Account acc10 = new Account();
            acc10.Name = '__Test Account10';
            acc10.OwnerId = accOwnerUser.Id;
            acc10.BillingCountry = 'India';
            acc10.BillingState = 'Delhi';
            acc10.currencyisocode='INR';
            acclist.add(acc10);
            Account partneracc1 = utilTestClass.CreateAccount('__Test partner Account');
            partneracc1.OwnerId = accOwnerMO.Id;
            partneracc1.IsPartnerCustom__c = true;
            partneracc1.Partner_Type__c = 'ADS Partner';
            partneracc1.Partner_status__c = 'Partner';
            partneracc1.Website = 'www.nowwherepartner@torun.com'; 
            partneracc1.GSSM_Class__c = 'AT&T';
            partneracc1.GSSM_Sector__c = 'AT&T';
            acclist.add(partneracc1);
            Account acc7 = utilTestClass.CreateAccount('__Test Account7');
            acc7.OwnerId = accOwnerMO.Id;
            acc7.Indirect_Customer__c = true;
            acc7.Website = 'www.nowwhere@torun.com';     
            acc7.Parent_Division__c = 'UKI_Web';
            acc7.Region__c = 'UKI Media';
            acc7.Area__c = 'Unknown';
            acclist.add(acc7);
            insert acclist;
                        
            List<Contact> conList = new List<Contact>();
            Contact cont = utilTestClass.CreateContact('jimi', 'hendrix');
            cont.AccountId = acc3.Id;
            conList.add(cont);
            // Contact c2 = utilTestClass.CreateContact('John2','Doe');
            // c2.AccountId=Partneracc.id;
            // c2.MailingStreet='123 Main';
            // c2.MailingCity='Peoria';
            // c2.MailingState='IL';
            // c2.MailingPostalCode='33333';
            // c2.MobilePhone='3213213211';
            // c2.Fax='3213123211';
            // c2.Email ='john2@akamai.com';
            // c2.Active_Partner__c=True;
            // conList.add(c2);
            insert conList;
            Test.startTest();
            List<Account> partnerAccountList = SObjectFactory.createPartnerAccounts(2);
            partnerAccountList.remove(1);
            List<User> partnerUsers = SObjectFactory.createPartnerUsers(partnerAccountList);

            List<AccountTeamMember> atms = new List<AccountTeamMember>();
            AccountTeamMember atm=new AccountTeamMember();
            atm.TeamMemberRole='MSS Primary';
            atm.UserId=accOwnerUser.id;
            atm.AccountId=acc2.id;
            atm.Validation_Overide__c = true;
            atms.add(atm);
            
            AccountTeamMember atm2=new AccountTeamMember();
            atm2.TeamMemberRole='Technical Sales - Primary';
            atm2.UserId=accOwnerUser.id;
            atm2.AccountId=acc2.id;
            atm2.Validation_Overide__c = true;
            atms.add(atm2);
            insert atms;
            
            Campaign cmpgn = utilTestClass.CreateCampaign('__ Test Cmpgn');
            cmpgn.AKAM_System__c = '';
            cmpgn.AKAM_Created_By__c = '';
            cmpgn.AKAM_Created_Date__c = null;
            insert cmpgn;
                                    
            List<Opportunity> oppList = new List<Opportunity>();
            Opportunity oppty = utilTestClass.CreateOpportunity('__Test Oppty','1. Identify Need');
            oppty.AccountId = acc.Id;
            oppty.CloseDate = Date.today().addMonths(4);
            oppList.add(oppty);
            Opportunity oppty1 = utilTestClass.CreateOpportunity('__Test Oppty1','1. Identify Need');
            oppty1.AccountId = acc5.Id;
            oppty1.CloseDate = Date.today().addMonths(4);
            oppty1.Partner_Forecast_Amount__c = 10;
            oppty1.Deal_Type__c='Direct';
            oppty1.Is_Authorized_Partner_Sellable_Country__c = false;
            oppList.add(oppty1);
            
            Opportunity oppty2 = utilTestClass.CreateOpportunity('__Test Oppty2','1. Identify Need');
            oppty2.AccountId = acc.Id;
            oppty2.CloseDate = Date.today().addMonths(4);
            oppty2.CampaignId = cmpgn.Id;
            oppList.add(oppty2);
            
            Opportunity oppty3 = utilTestClass.CreateOpportunity('__Test Oppty3','1. Identify Need');
            oppty3.AccountId = acc.Id;
            oppty3.CloseDate = Date.today().addMonths(4);
            oppty3.CampaignId = cmpgn.Id;
            oppList.add(oppty3);
            
            for(integer i=0;i<1;i++)
            {
                Opportunity opp = utilTestClass.CreateOpportunity('__Test_Oppty_Bulk_'+i,'1. Identify Need');
                opp.CloseDate = Date.today().addMonths(4);
                opp.AccountId = acc2.Id;
                opp.Deal_Type__c='Indirect';
                opp.Partner_Involved__c=partnerAccountList.get(0).Id;
                opplist.add(opp);
            }
            insert oppList;
            
            Test.stopTest();
        }
    }
    
    public static testmethod void highRisk_for_testingTest()
    {
        Test.startTest();
        User highRiskUser = UtilTestClass.CreateUser('HRU', 'Worldwide', 'SA - Analyst');
        insert highRiskUser;
        
        Account highRiskAccount;
        Opportunity opp = new Opportunity();
        SubReseller__c subreseller=new SubReseller__c();
        System.runAs(highRiskUser)
        {
            highRiskAccount = UtilTestClass.CreateAccount('High Risk Account');
            highRiskAccount.Collector__c = highRiskUser.Id;
            highRiskAccount.Financial_Risk__c = 'Bankruptcy';
            highRiskAccount.Partner_Type__c = 'Sub-Reseller';
            insert highRiskAccount; 
            AccountTeamMember highRiskATM = UtilTestClass.CreateAccountTeamMember(highRiskAccount.Id,highRiskUser.Id);
            highRiskATM.Validation_Overide__c = true;
            highRiskATM.TeamMemberRole = 'Sales - Analyst';

            insert highRiskATM;
            
            opp.StageName = '1. Identify Need';
            opp.Name = 'Opportunity on High Risk Account';
            opp.Deal_Type__c = 'Direct';
            opp.CloseDate = System.today();
            opp.AccountId = highRiskAccount.id;
            opp.OwnerId = highRiskUser.Id;
            insert opp;

            subreseller.name='samtest';   
              subreseller.Account__c =highRiskAccount.id; 
              subreseller.Partner_Involved__c=highRiskAccount.id;
              insert subreseller; 
        }
        
        List<Opportunity> oppList = new List<Opportunity>();
        oppList.add(opp);
        set<id> subids=new set<id>(); 
        subids.add(subreseller.id);
        OpportunityTriggerClass.sendEmailAlertOnHighRiskAccount(oppList);
        OpportunityTriggerClass.fetchSubResellerMap(subids);

        Test.stopTest();
    }

    static testMethod void OpptyCampaignDetails_Update()
    {
        System.runAs(dmlUser){
            Test.startTest();
            List<Opportunity> oppty = new List<Opportunity>();
            List<Opportunity> opptyToUpdate = new List<Opportunity>();
            List<String> opptyNames = new List<String>();
            opptyNames.add('__Test Oppty2');
            opptyNames.add('__Test Oppty3');
            oppty = [select Id,
                     StageName
                     from Opportunity 
                     where Name in :opptyNames];
            if(oppty.size() > 0) {
                if(oppty.get(0) != null){
                    Opportunity oppty1 = oppty.get(0);  
                    if(oppty1 != null){
                        oppty1.StageName = 'Closed Won';
                        oppty1.Validation_Override__c=true;
                        opptyToUpdate.add(oppty1);
                    }
                }
                if(oppty.get(1) != null){
                    Opportunity oppty2 = oppty.get(1);
                    if(oppty2 != null){
                        oppty2.StageName = 'Closed Lost';
                        oppty2.Validation_Override__c=true;
                        oppty2.Opportunity_Category__c ='Contract Moves';   
                        oppty2.Loss_Reason__c ='Contract Consolidation';
                        opptyToUpdate.add(oppty2);
                    }
                }
                
            }
            
            if(opptyToUpdate.size() > 0){
                update opptyToUpdate;
            }
            Test.stopTest();
        }
    }
    
    static testMethod void updateRequiredDuplicateOpptyDetails_Test(){
        system.runAs(dmlUser){
            set<id> originalOpptyIds = new set<id>();
            Test.startTest();
            Id originalOpptyId = [select id from opportunity where name = '__Test Oppty2' limit 1][0].id;
            Id conId = [select id from contact where name = 'jimi hendrix' limit 1][0].id;
            originalOpptyIds.add(originalOpptyId);
            account acc = [select id from account where name = '__Test Account' limit 1][0];
            list<Opportunity> duplicateOpptys = new list<Opportunity>();
            Opportunity duplicateOppty = utilTestClass.CreateOpportunity('__Test Dup Oppty','1. Identify Need');
            duplicateOppty.AccountId = acc.Id;
            duplicateOppty.CloseDate = Date.today().addMonths(4);
            duplicateOppty.Duplicate_Opportunity__c = originalOpptyId;
            duplicateOppty.Validation_Override__c = true;
            duplicateOpptys.add(duplicateOppty);
            insert duplicateOpptys;
            OpportunityTeamMember otm = new OpportunityTeamMember();
            otm.TeamMemberRole = 'Channel - Secondary';
            otm.UserId = dmlUser.Id;
            otm.OpportunityId = duplicateOppty.id;
            insert otm;
            OpportunityContactRole ocr = new OpportunityContactRole();
            ocr.Role = 'Lead';
            ocr.opportunityId = duplicateOppty.id;
            ocr.contactId = conId;
            insert ocr;
            Close_Plan__c cp = new Close_Plan__c();
            cp.Opportunity__c = duplicateOppty.Id;
            cp.Validation_Override__c = true;
            insert cp;
            User seUser = [Select id from user where profile.name='Solutions Engineer' and isactive=true Limit 1];
            system.runAs(seUser){
                Deal_Support_Request__c dsr = new Deal_Support_Request__c();
                dsr.Opportunity__c = duplicateOppty.Id;
                dsr.RecordTypeId = Schema.SObjectType.Deal_Support_Request__c.getRecordTypeInfosByDeveloperName().get('Pre_Sales_Engagement').getRecordTypeId();
                dsr.Request_Type__c = 'POC';
                dsr.POC_Status__c = 'Planned';
                dsr.Start_Date__c = System.today();
                dsr.End_Date__c = System.today() + 5;
                dsr.Contract_Type__c = 'Out Clause';
                dsr.Success_Criteria__c = 'Success';
                dsr.Product__c = 'Adaptive Media Delivery';
                dsr.Validation_Override__c = true;
                insert dsr;
            }
            OpportunityTriggerClass.updateRequiredDuplicateOpptyDetails(duplicateOpptys,originalOpptyIds);
            Test.stopTest();
        }
    }
    
    static testMethod void updateCampaignForDealReg_Test(){
        system.runAs(dmlUser){
            account acc = [select id from account where name = '__Test Account' limit 1][0];
            Test.startTest();
            Opportunity oppty = utilTestClass.CreateOpportunity('__Test New Oppty','1. Identify Need');
            oppty.AccountId = acc.Id;
            oppty.CloseDate = Date.today().addMonths(4);
            oppty.Validation_Override__c = true;
            insert oppty;
            list<Id> oppIdList = new list<Id>();
            oppIdList.add(oppty.Id);
            OpportunityTriggerClass.updateCampaignForDealReg(oppIdList);
            Test.stopTest();
        }
    }
    
    /*static testMethod void verifyMinimumContactRolesOnStageChange_Test(){
        Test.startTest(); 
        User usrCrmInte = [select id from User where Profile.Name = 'CRM Integration' and IsActive = True limit 1][0];
        Id conId = [select id from contact where name = 'jimi hendrix' limit 1][0].id;
        Id con2Id = SobjectRepository.getPartnerContact().Id;
        
        account acc = [select id from account where name = '__Test Account' limit 1][0];
        system.runAs(usrCrmInte){
            Opportunity oppty = utilTestClass.CreateOpportunity('__Test Demo Oppty','1. Identify Need');
            oppty.AccountId = acc.Id;
            oppty.CloseDate = Date.today().addMonths(4);
            oppty.Validation_Override__c = true;
            
            insert oppty;
            OpportunityContactRole ocr = new OpportunityContactRole();
            ocr.Role = 'Cancelled Customer Survey';
            ocr.opportunityId = oppty.id;
            ocr.contactId = conId;
            insert ocr;
            OpportunityContactRole ocr1 = new OpportunityContactRole();
            ocr1.Role = 'Cancelled Customer Survey';
            ocr1.opportunityId = oppty.id;
            ocr1.contactId = con2Id;
            insert ocr1;
            oppty.Opportunity_Category__c = 'Customer Churn';
            oppty.StageName = '5. Negotiate';
            oppty.Validation_Override__c = true;
            update oppty;
            //OpportunityTriggerClass.verifyMinimumContactRolesOnStageChange(opptyList);
            Test.stopTest();
        }
    }*/
    
    static testMethod void updateTrialOpptyWithSalesOppty_Test(){
        system.runAs(dmlUser){
            List<Opportunity> oppty = new List<Opportunity>();
            List<String> opptyNames = new List<String>();
            opptyNames.add('__Test Oppty2');
            opptyNames.add('__Test Oppty3');
            oppty = [select Id,
                     StageName, AccountId, ForecastCategoryName, SQLDateTime__c
                     from Opportunity 
                     where Name in :opptyNames];
            user us=[select id from user where id='005A0000000NHIEIA4'];

            Test.startTest();
            Q2O_Custom_Settings__c sett = new Q2O_Custom_Settings__c ();
            sett.Name = 'CollectionUser';
            sett.value__c = us.id;
            insert sett;
            /*SFDC-5392 Removed Related_trial_opportunity
            Map<Id,Id> trialToSalesOpptyMap = new Map<Id,Id>();
            trialToSalesOpptyMap.put(oppty[0].Id, oppty[1].Id);
            OpportunityTriggerClass.updateTrialOpptyWithSalesOppty(trialToSalesOpptyMap);
            */
            OpportunityTriggerClass.uncheckPullForward();
            OpportunityTriggerClass.creditCheckTask(oppty);
            OpportunityTriggerClass.setSQLDateTime(oppty[0]);
            OpportunityTriggerClass.checkOrderApprovalForOpp(oppty);
            OpportunityTriggerClass.checkOppContactRole(oppty);
            OpportunityTriggerClass.updateOpptyContractReviewedBy(oppty);
            Test.stopTest();
        }
    }
    
    //rsharma - SFDC-1435
    static testMethod void testConfigurableGenericPopulateMRR()
    {
        System.runAs(dmlUser){
            ManagedPkgErrorClass.isFromManagedPackage = false;
            Opportunity oppty;
            // Assert that the Opportunity is currently CustomerStatus = '-'
            oppty = [select Id, CurrencyIsoCode ,OwnerId
                     from Opportunity 
                     where Name = '__Test Oppty'];
            //Create Specialist Mapping and Comp Team
            Specialist_Territory_Mapping__c STM = new Specialist_Territory_Mapping__c();
            STM.Sub_Territory_Name__c = 'Unknown-50001';
            STM.Specialist_User__c = oppty.OwnerId;
            STM.User_Type__c = 'ESR';
            insert STM;
            //Create Specialist Comp Team
            Specialist_Comp_Team__c SCT = new Specialist_Comp_Team__c();
            SCT.Product_Specialist__c = oppty.OwnerId;
            SCT.Type__c ='Enterprise Sales Specialist';
            insert SCT; 
            // Create products
            List<Product2> productList = new List<Product2>();
            
            Product2 testProduct1= new Product2();
            testProduct1.Name = 'Test_Security_Product';
            testProduct1.family = 'Security';
            testProduct1.AKAM_INT_ID__c = 111;
            testProduct1.AKAM_Product_ID__c='F-PR-4575';
            productList.add(testProduct1);
            
            Product2 testProduct2= new Product2();
            testProduct2.Name = 'Test_Web_Product';
            testProduct2.family = 'Web';
            testProduct2.AKAM_INT_ID__c = 222;
            testProduct2.AKAM_Product_ID__c='F-PR-4574';
            productList.add(testProduct2);
            
            Product2 testProduct3= new Product2();
            testProduct3.Name = 'Test_Service_Product';
            testProduct3.family = 'Service';
            testProduct3.AKAM_INT_ID__c = 333;
            testProduct3.AKAM_Product_ID__c='F-PR-4573';
            productList.add(testProduct3);

            Product2 testProduct4= new Product2();
            testProduct4.Name = 'Test_Enterprise_Product';
            testProduct4.family = 'Enterprise';
            testProduct4.AKAM_INT_ID__c = 444;
            testProduct4.AKAM_Product_ID__c='F-PR-55000';
            productList.add(testProduct4);
            
            Test.startTest();
            insert productList;
            
            // Create pricebook entries
            List<PricebookEntry> pricebookList = new List<PricebookEntry>();
            for(Product2 product : productList)
            {
                PricebookEntry pbEntry= new PricebookEntry();
                pbEntry.Pricebook2Id = Test.getStandardPricebookId();
                pbEntry.Product2Id   = product.id;
                pbEntry.CurrencyIsoCode = 'USD';
                pbEntry.IsActive     = true;
                pbEntry.UnitPrice    = 1; 
                pricebookList.add(pbEntry);      
            }
            insert(pricebookList);
            // Create line items 
            List<OpportunityLineItem> OpportunityLineItemList= new List<OpportunityLineItem>();
            for(PricebookEntry pbEntry : pricebookList) {
                OpportunityLineItem oli = new OpportunityLineItem();
                oli.opportunityId       = oppty.id;
                oli.pricebookentryid    = pbEntry.Id;
                oli.quantity            = 1;
                oli.unitprice           = 200;
                oli.Average_Renewal_Commit_MRR__c = 100;
                oli.Average_Renewal_Usage_MRR__c = 100;
                oli.Projected_Monthly_commit_fees__c = 100;
                oli.Projected_Avg_Rev_Non_Commit__c = 100;
                OpportunityLineItemList.add(oli);
            }
            
            insert OpportunityLineItemList;
            Test.stopTest();
            Opportunity testOppty = [SELECT id,Opportunity_Revenue_Impact__c,Aggregate_Security_MRR__c,Baseline_Monthly_Commit__c,Baseline_Monthly_Usage__c,PAE_Projected_Monthly_Commit__c,PAE_Projected_Monthly_Usage__c,Security_Baseline_Monthly_Commit__c,Security_Baseline_Monthly_Usage__c,Security_Projected_Monthly_Commit__c,Security_Projected_Monthly_Usage__c,Service_Baseline_Monthly_Commit_1__c,Service_Baseline_Monthly_Commit_2__c,Service_Baseline_Monthly_Usage_1__c,Service_Baseline_Monthly_Usage_2__c,Service_Projected_Monthly_Commit_1__c,Service_MRR_Override_1__c,Service_Projected_Monthly_Commit_2__c,Service_MRR_Override_2__c,Service_Projected_Monthly_Usage_1__c,Service_Projected_Monthly_Usage_2__c from Opportunity where id=:oppty.id];
        }
    }

    /**
        OpportunityDelete
        - Test "Prevent user from deleteing an Opportunity unless his profile is 'System Administrator' or 'CRM Integraion' or 'Business Operations'
    */  
    static testmethod void OpportunityDelete()
    {
        System.runAs(dmlUser){
            ManagedPkgErrorClass.isFromManagedPackage = false;
            User usrSalesOp = [select id from User where Profile.Name = 'Sales Operations' and IsActive = True limit 1][0];
            User usrCrmIntg = [select id from User where Profile.Name = 'CRM Integration' and IsActive = True limit 1][0];
            
            Account acc = [select Id from Account where Name = '__Test Account'];
            Test.startTest();
            // Create Opportunity
            Opportunity oppty = utilTestClass.CreateOpportunity('__Test Opportunity delete Opp1','1. Identify Need');
            oppty.AccountId = acc.Id;
            oppty.CloseDate = Date.today().addMonths(4);
            insert oppty;    
            Opportunity oppty1 = new Opportunity();
            oppty1 = [select Id, CurrencyIsoCode 
                     from Opportunity 
                     where Name = '__Test Oppty'];  
            List<Opportunity> opptunityRecs = new List<Opportunity>();
            opptunityRecs.add(oppty);
            Set<Id> oppRecIds = new Set<Id>();
            oppRecIds.add(oppty1.Id);
            OpportunityTriggerClass.updateRequiredDuplicateOpptyDetails(opptunityRecs,oppRecIds);  
            //OpportunityTriggerClass.creditCheckTask(opptunityRecs);
            // ---------------- Sales Op  ---------------       
            system.runas(usrSalesOp)
            {
                try
                {
                    delete oppty;
                }
                catch(DmlException e)
                {
                    system.assert(e.getMessage().contains('access'));
                }
            }       
            List<Opportunity> testOpp;
            testOpp = RefreshOpportunity(oppty); 
            system.assertEquals(testOpp.size(),1);
            // ---------------- SYSTEM ADMIN ---------------
            oppty = utilTestClass.CreateOpportunity('__Test Opportunity delete Opp2','1. Identify Need');
            oppty.AccountId = acc.Id;
            oppty.CloseDate = Date.today().addMonths(4);
            
            insert oppty; 
            system.runas(dmlUser)
            {
                delete oppty;
            }
            testOpp = RefreshOpportunity(oppty); 
            system.assertEquals(testOpp.size(),0);
            // --------------- CRM Integration -------------
            oppty = utilTestClass.CreateOpportunity('__Test Opportunity delete Opp3','1. Identify Need');
            oppty.AccountId = acc.Id;
            oppty.CloseDate = Date.today().addMonths(4);
            insert oppty;   
            system.runas(usrCrmIntg)
            {
                delete oppty;
            }
            testOpp = RefreshOpportunity(oppty); 
            system.assertEquals(testOpp.size(),0); 
            Test.stopTest();
        }
    }

    /**
       addOpptySalesTeam_PositiveTest      
       - A test account & oppty are created.
       - MSS Profile User creates an Opportunity
         -) Opportunity Owner is added as Sales Team member with TeamRole = 'MSS Primary'   
         -) Created new Account Reassignment Rule for accOwnerUser - rule2. (part of CR 812208 PDRA Update part-2)     
    */
    public static testmethod void addOpptySalesTeam_PositiveTest()
    {
        System.runAs(dmlUser){
            ManagedPkgErrorClass.isFromManagedPackage = false;
            User accOwnerUser, opptyMSSOwnerUser;
            opptyMSSOwnerUser = [select id from User where Profile.Name = 'Sales - Partner Account Executive' and IsActive = True limit 1][0];
            accOwnerUser = [select id from User where Profile.Name = 'Marketing Operations' and IsActive = True limit 1][0];
            Account acc = [select Id from Account where Name = '__Test Account1'];
            Test.startTest();
            Opportunity oppty1 = utilTestClass.CreateOpportunity('__Test Oppty 0','1. Identify Need');
            oppty1.AccountId =acc.Id;
            oppty1.OwnerId = opptyMSSOwnerUser.Id;
            oppty1.CloseDate = Date.today();            
            System.runAs(opptyMSSOwnerUser){
                insert oppty1;
            }
            // Get the updated account and oppty
            Account testAcc = [select Id,OwnerId,Reassign_Account__c from Account where Name='__Test Account1'][0];
            Opportunity testOppty1 = [select Id,OwnerId from Opportunity where Name='__Test Oppty 0'][0];
            OpportunityTeamMember opptyTeamMember = [select UserId, TeamMemberRole from OpportunityTeamMember where OpportunityId = :oppty1.Id][0];
            Test.stopTest();
            // Verify account Owner     
            system.assertEquals(testAcc.OwnerId,accOwnerUser.Id);
            // Verify SalesTeam is Created & matches MSS Owner      
            system.assertNotEquals(opptyTeamMember, null);      
            system.assertEquals(opptyTeamMember.TeamMemberRole, 'Channel - Primary');
            system.assertEquals(opptyTeamMember.UserId,opptyMSSOwnerUser.Id);
        }
    }

    // Sonali Tandon : CR 3018413 - Test class for genericPopulateMRR()
    static testMethod void testGenericPopulateMRR()
    {
        System.runAs(dmlUser){
            ManagedPkgErrorClass.isFromManagedPackage = false;
            Opportunity oppty;
            // Assert that the Opportunity is currently CustomerStatus = '-'
            oppty = [select Id, CurrencyIsoCode 
                     from Opportunity 
                     where Name = '__Test Oppty'];
            // Create products
            List<Product2> productList = new List<Product2>();
            
            Product2 testProduct1= new Product2();
            testProduct1.Name = 'Test_Security_Product';
            testProduct1.family = 'Security';
            testProduct1.AKAM_INT_ID__c = 111;
            testProduct1.AKAM_Product_ID__c='F-PR-4575';
            productList.add(testProduct1);
            
            Product2 testProduct2= new Product2();
            testProduct2.Name = 'Test_Web_Product';
            testProduct2.family = 'Web';
            testProduct2.AKAM_INT_ID__c = 222;
            testProduct2.AKAM_Product_ID__c='F-PR-4574';
            productList.add(testProduct2);
            
            Product2 testProduct3= new Product2();
            testProduct3.Name = 'Test_Service_Product';
            testProduct3.family = 'Service';
            testProduct3.AKAM_INT_ID__c = 333;
            testProduct3.AKAM_Product_ID__c='F-PR-4573';
            productList.add(testProduct3);
            
            Test.startTest();
            insert productList;
            
            // Create pricebook entries
            List<PricebookEntry> pricebookList = new List<PricebookEntry>();
            for(Product2 product : productList)
            {
                PricebookEntry pbEntry= new PricebookEntry();
                pbEntry.Pricebook2Id = Test.getStandardPricebookId();
                pbEntry.Product2Id   = product.id;
                pbEntry.CurrencyIsoCode = 'USD';
                pbEntry.IsActive     = true;
                pbEntry.UnitPrice    = 1; 
                pricebookList.add(pbEntry);      
            }
            insert(pricebookList);
            // Create line items 
            List<OpportunityLineItem> OpportunityLineItemList= new List<OpportunityLineItem>();
            for(PricebookEntry pbEntry : pricebookList) {
                OpportunityLineItem oli = new OpportunityLineItem();
                oli.opportunityId       = oppty.id;
                oli.pricebookentryid    = pbEntry.Id;
                oli.quantity            = 1;
                oli.unitprice           = 200;
                oli.Average_Renewal_Commit_MRR__c = 100;
                oli.Average_Renewal_Usage_MRR__c = 100;
                oli.Projected_Monthly_commit_fees__c = 100;
                oli.Projected_Avg_Rev_Non_Commit__c = 100;
                OpportunityLineItemList.add(oli);
            }
            
            insert OpportunityLineItemList;
            Test.stopTest();
            
            Opportunity testOppty = [select Id,PAE_Strategic_MRR__c,Partner_Forecast_Amount__c,MRR__c,Aggregate_Security_MRR__c,Security_MRR__c,Strategic_MRR__c from Opportunity where id=:oppty.id];                
            System.assertEquals(testOppty.PAE_Strategic_MRR__c,testOppty.Strategic_MRR__c);
            System.assertEquals(testOppty.Partner_Forecast_Amount__c,testOppty.MRR__c);
            
        }
    }

    /**
       BulkAddOpptySalesTeam_PositiveTest
       - Bulk insert of 100 opportunities is done with user having MSS profile
       - Creation of 100 SalesTeamMember for respective Oppty is verified
       - Created new Account Reassignment Rule for accOwnerUser - rule2. (part of CR 812208 PDRA Update part-2) 
    */ 
    public static testmethod void BulkAddOpptySalesTeam_PositiveTest()
    {
        System.runAs(dmlUser){
            ManagedPkgErrorClass.isFromManagedPackage = false;
            User accOwnerUser, opptyMSSOwnerUser;
            opptyMSSOwnerUser = [select id from User where Profile.Name = 'Sales - Partner Account Executive' and IsActive = True limit 1][0];
            accOwnerUser = [select id from User where Profile.Name = 'Marketing Operations' and IsActive = True limit 1][0];
            Account acc = [select Id from Account where Name = '__Test Account1'];
            //Bulk insert
            Integer i;
            List<Opportunity> bulkOpportunitiesList = new List<Opportunity>();  
            for(i=0;i<3;i++)
            {       
                Opportunity oppty = utilTestClass.CreateOpportunity('#Test bulkAddOpptySalesTeam'+i,'1. Identify Need');
                oppty.AccountId = acc.Id;
                oppty.OwnerId = opptyMSSOwnerUser.Id;
                oppty.CloseDate = Date.today();
                bulkOpportunitiesList.add(oppty);
            } 
            Test.startTest();
            System.runAs(opptyMSSOwnerUser){insert bulkOpportunitiesList;}
            
            
            //Refresh BulkOpportunities
            bulkOpportunitiesList = RefreshOpportunity(bulkOpportunitiesList);
            
            //Get the updated opportunities 
            List<OpportunityTeamMember> bulkOpptyTeamMember = new List<OpportunityTeamMember>();
            
            bulkOpptyTeamMember = [select TeamMemberRole, UserId from OpportunityTeamMember where OpportunityId in : bulkOpportunitiesList];
            Test.stopTest();
            system.assertNotEquals(bulkOpptyTeamMember, null);              
            for(i=0;i<3;i++) 
            {                   
                system.assertEquals(bulkOpptyTeamMember[i].UserId,opptyMSSOwnerUser.Id);
                system.assertEquals(bulkOpptyTeamMember[i].TeamMemberRole,'Channel - Primary');
            }
        }
    }

    /**
       updateOpptyOwnerId_PositiveTest     
       - A test account & oppty are created.
       - MSS Profile User creates an Opportunity
         -) Opportunity Owner is added as Sales Team member with TeamRole = 'MSS Primary'
         -) Created new Account Reassignment Rule for accOwnerUser - rule2. (part of CR 812208 PDRA Update part-2)       
    */
    public static testmethod void updateOpptyOwnerId_PositiveTest()
    {
        System.runAs(dmlUser){
            ManagedPkgErrorClass.isFromManagedPackage = false;
            //ApprovalHistoryPageControllerTestClass.disableDealMakerCoreSettings();
            User accOwnerUser, opptySCMOwnerUser;
            opptySCMOwnerUser = [select id from User where Profile.Name = 'Sales - Partner Account Executive' and IsActive = True limit 1][0];
            accOwnerUser = [select id from User where Profile.Name = 'Marketing Operations' and IsActive = True limit 1][0];
            Account acc = [select Id from Account where Name = '__Test Account1'];
            
            Test.startTest();
            Opportunity oppty1 = utilTestClass.CreateOpportunity('__Test Oppty 0','1. Identify Need');
            oppty1.AccountId =acc.Id;
            oppty1.OwnerId = opptySCMOwnerUser.Id;
            oppty1.CloseDate = Date.today();            
            System.runAs(opptySCMOwnerUser){insert oppty1;}
            
            // Get the updated account and oppty
            Account testAcc = [select Id,OwnerId,Reassign_Account__c from Account where Name='__Test Account1'][0];
            Opportunity testOppty1 = [select Id,OwnerId, CreatedById from Opportunity where Name='__Test Oppty 0'][0];  
            Test.stopTest();
            
            // Verify account Owner
            system.assertEquals(testAcc.OwnerId,accOwnerUser.Id);
            // Verify Oppty Owner
            system.assertEquals(testAcc.OwnerId,testOppty1.OwnerId);
            // Verify Oppty CreatedById     
            system.assertEquals(testOppty1.CreatedById, opptySCMOwnerUser.Id);     
        }
    }

    /**
       BulkUpdateOpptyOwnerId_PositiveTest
       - Bulk insert of 100 opportunities is done with runAs user.profile = 'Sales Channel Manager profile'
       - Check for assertion - Account.ownerId = Oppty.OwnerId
       - Created new Account Reassignment Rule for accOwnerUser - rule2. (part of CR 812208 PDRA Update part-2)
    */ 
    public static testmethod void BulkUpdateOpptyOwnerId_PositiveTest()
    {
        System.runAs(dmlUser){
            ManagedPkgErrorClass.isFromManagedPackage = false;
            //ApprovalHistoryPageControllerTestClass.disableDealMakerCoreSettings();
            User accOwnerUser, opptySCMOwnerUser;
            opptySCMOwnerUser = [select id from User where Profile.Name = 'Sales - Partner Account Executive' and IsActive = True limit 1][0];
            accOwnerUser = [select id from User where Profile.Name = 'Marketing Operations' and IsActive = True limit 1][0];
            Account acc = [select Id, OwnerId from Account where Name = '__Test Account1'];
            //Bulk insert
            Integer i;
            List<Opportunity> bulkOpportunityList = new List<Opportunity>(); 
            for(i=0;i<3;i++)
            {       
                Opportunity oppty = utilTestClass.CreateOpportunity('#Test bulkAddOpptySalesTeam'+i,'1. Identify Need');
                oppty.AccountId = acc.Id;
                oppty.OwnerId = opptySCMOwnerUser.Id;
                oppty.CloseDate = Date.today();
                bulkOpportunityList.add(oppty);
            }   
            Test.startTest();
            System.runAs(opptySCMOwnerUser){insert bulkOpportunityList;}
            
            //Refresh bulkOpportunityList
            bulkOpportunityList = RefreshOpportunity(bulkOpportunityList);
            Test.stopTest();
            
            // Assert test      
            // Verify account Owner     
            system.assertEquals(acc.OwnerId,accOwnerUser.Id);
            for(i=0;i<3;i++) 
            {           
                // Verify Oppty Owner
                system.assertEquals(bulkOpportunityList[i].OwnerId, acc.OwnerId);           
                // Verify Oppty CreatedById
                system.assertEquals(bulkOpportunityList[i].CreatedById, opptySCMOwnerUser.Id);
            }    
        }
    }

    public static testmethod void DVPToFollowOppty_PositiveTest()
    {
        System.runAs(dmlUser){
            ManagedPkgErrorClass.isFromManagedPackage = false;
            List<PicklistEntry> DVPNamesPickListValues=Opportunity.DVP_to_Follow__c.getDescribe().getPickListValues();
            List<String> DVPNamesList=new List<String>();
            for(PicklistEntry p:DVPNamesPickListValues)
            {
                DVPNamesList.add(p.getLabel());
            }
            User accOwnerUser = [select id from User where Profile.Name = 'Marketing Operations' and IsActive = True limit 1][0];
            Account acc = [select Id, OwnerId from Account where Name = '__Test Account1'];
            Test.startTest();
            Opportunity oppty1 = utilTestClass.CreateOpportunity('__Test Oppty 0','1. Identify Need');
            oppty1.AccountId =acc.Id;
            oppty1.OwnerId = accOwnerUser.Id;
            oppty1.CloseDate = Date.today();            
            System.runAs(accOwnerUser){insert oppty1;}
            List<String> userNameList=new List<String>();
            userNameList.add(DVPNamesList[0]);
            userNameList.add(DVPNamesList[1]);
            userNameList.add('Owner');
            oppty1.DVP_to_Follow__c=DVPNamesList[0]+';'+DVPNamesList[1];
            
            System.runAs(accOwnerUser) {update oppty1;}
            
            List<User> followers=[select Id,Name from User where Name IN :userNameList Order by Id ];
            List<EntitySubscription> followersList=[select Id, SubscriberId from EntitySubscription where parentId=:oppty1.Id order by SubscriberId];
            Test.stopTest();
            
            Integer i=0;
            for(EntitySubscription entity: followersList)
            {
                System.assertEquals(entity.SubscriberId,followers[i++].Id);
            }
        }
    }

    public static testmethod void EmailSentWhenClosedWonPositive()
    {
        System.runAs(dmlUser){
            ManagedPkgErrorClass.isFromManagedPackage = false;
            User accOwnerUser, salesOpsUser, opptySCMOwnerUser;
            opptySCMOwnerUser = [select id from User where Profile.Name = 'Sales - Partner Account Executive' and IsActive = True limit 1][0];
            accOwnerUser = [select id from User where Profile.Name = 'Marketing Operations' and IsActive = True limit 1][0];
            salesOpsUser = [select id from User where Profile.Name = 'Sales Operations' and IsActive = True limit 1][0];
            Test.startTest();
            Account acc, Partneracc;
            List<String> accNames = new List<String>{'Test acc__1','Test Partneracc__1'};
                for(Account a : [select Id, Name from Account where Name IN : accNames]){
                    if(a.Name == 'Test acc__1')
                        acc = a;
                    else if(a.Name == 'Test Partneracc__1')
                        Partneracc = a;
                }
            Id profileId = GsmUtilClass.getGSMSettingValue('PartnerCommunityUserProfileId');
            User partner = SobjectRepository.getPartnerUser();
            
            Opportunity opp = [select Id, CloseDate, AccountId, Deal_Type__c, Partner_Involved__c from Opportunity where Name LIKE '__Test_Oppty_Bulk_%' limit 1];
            
            list<OpportunityTeamMember> otmlist = new list<OpportunityTeamMember>();
            
            OpportunityTeamMember otm=new OpportunityTeamMember();
            otm.TeamMemberRole='Sales - Primary';
            otm.UserId=accOwnerUser.id;
            otm.OpportunityId=opp.id;
            otm.Validation_Override__c = true;
            otmlist.add(otm);
            
            otm=new OpportunityTeamMember();
            otm.TeamMemberRole='Partner';
            otm.UserId=partner.id;
            otm.OpportunityId=opp.id;
            otm.Validation_Override__c = true;
            otmlist.add(otm);
            
            OpportunityShare os = new OpportunityShare();
            os.OpportunityId = opp.id;
            os.UserOrGroupId = partner.id;
            os.OpportunityAccessLevel = 'Edit';
            insert os;
            
            insert otmlist;
            
            opp.StageName='6. Signed';
            opp.Validation_Override__c=true;
            opp.Opportunity_Type__c='Churn';
            update opp;
            
            opp.Contract_ID__c='123456';
            opp.StageName='Closed Won';
            opp.Validation_Override__c=true;
            update opp;
            Test.stopTest();
            delete otm;
        }
    }

    public static testmethod void EmailSentWhenClosedWonBulk()
    {
        System.runAs(dmlUser){
            ManagedPkgErrorClass.isFromManagedPackage = false;
            User accOwnerUser, salesOpsUser, opptySCMOwnerUser;
            opptySCMOwnerUser = [select id from User where Profile.Name = 'Sales - Partner Account Executive' and IsActive = True limit 1][0];
            accOwnerUser = [select id from User where Profile.Name = 'Marketing Operations' and IsActive = True limit 1][0];
            salesOpsUser = [select id from User where Profile.Name = 'Sales Operations' and IsActive = True limit 1][0];
            Account acc, Partneracc;
            List<String> accNames = new List<String>{'Test acc__1','Test Partneracc__1'};
                for(Account a : [select Id, Name from Account where Name IN : accNames]){
                    if(a.Name == 'Test acc__1')
                        acc = a;
                    else if(a.Name == 'Test Partneracc__1')
                        Partneracc = a;
                }
            Test.startTest();
            Id profileId = GsmUtilClass.getGSMSettingValue('PartnerCommunityUserProfileId');
            
            integer i=0;
            list<Opportunity> opplist=[select Id, CloseDate, AccountId, Deal_Type__c, Partner_Involved__c from Opportunity where Name LIKE '__Test_Oppty_Bulk_%' limit 1];
            
            list<OpportunityTeamMember> otmlist = new list<OpportunityTeamMember>();
            Contact partnerContact = SobjectRepository.getPartnerContact();
            for(Opportunity oppsingle:opplist)
            {
                OpportunityTeamMember otm=new OpportunityTeamMember();
                otm.TeamMemberRole='Sales - Primary';
                otm.UserId=accOwnerUser.id;
                otm.OpportunityId=oppsingle.id;
                otmlist.add(otm);
                
                otm=new OpportunityTeamMember();
                otm.TeamMemberRole='Partner';
                otm.UserId=partnerContact.Partner_User__c;
                otm.OpportunityId=oppsingle.id;
                otmlist.add(otm);
            }
            insert otmlist;
            
            list<Opportunity> opplistupdate=new list<Opportunity>();
            for(Opportunity oppsingle:opplist)
            {
                Opportunity opp=new Opportunity(id=oppsingle.id);
                opp.StageName='6. Signed';
                opp.Validation_Override__c=true;
                opplistupdate.add(opp);
            }
            update opplistupdate;
            
            for(Task t:[select id,ActivityDate from task where subject=:GsmUtilClass.getGSMSettingValue('OpptyTrigger_SS6TaskSubject') and WhatId IN :opplist])
                system.assertEquals(t.ActivityDate, datetime.now().date().addDays(2));
            
            opplistupdate=new list<Opportunity>();
            /*
            for(Opportunity oppsingle:opplist)
            {
                Opportunity opp=new Opportunity(id=oppsingle.id);
                opp.Contract_ID__c='123456';
                opp.StageName='Closed Won';
                opp.Validation_Override__c=true;
                opplistupdate.add(opp);
            }
            update opplistupdate;
            */
            Test.stopTest();
        }
    }

    public static testmethod void createTaskWhenSalesStage6TestCase1()
    {
        System.runAs(dmlUser){
            ManagedPkgErrorClass.isFromManagedPackage = false;
            User accOwnerUser, salesOpsUser, opptySCMOwnerUser;
            opptySCMOwnerUser = [select id from User where Profile.Name = 'Sales - Partner Account Executive' and IsActive = True limit 1][0];
            accOwnerUser = [select id from User where Profile.Name = 'Marketing Operations' and IsActive = True limit 1][0];
            salesOpsUser = [select id from User where Profile.Name = 'Sales Operations' and IsActive = True limit 1][0];
            Id profileId = GsmUtilClass.getGSMSettingValue('PartnerCommunityUserProfileId');
            Test.startTest();
            User partner = SobjectRepository.getPartnerUser();
            
            Opportunity opp = [select Id, CloseDate, AccountId, Deal_Type__c, Partner_Involved__c from Opportunity where Name LIKE '__Test_Oppty_Bulk_%' limit 1];
            
            list<OpportunityTeamMember> otmlist = new list<OpportunityTeamMember>();
            Map<Id,Set<Id>> oppMapId = new Map<Id,Set<Id>>();
            Set<Id> oppIds = new Set<Id>();
            OpportunityTeamMember otm=new OpportunityTeamMember();
            otm.TeamMemberRole='Sales - Secondary';
            otm.UserId=accOwnerUser.id;
            otm.OpportunityId=opp.id;
            otm.Validation_Override__c = true;
            otmlist.add(otm);
            oppIds.add(opp.Id);
            oppMapId.put(opp.AccountId,oppIds);            
            
            otm=new OpportunityTeamMember();
            otm.TeamMemberRole='Partner';
            otm.UserId=partner.id;
            otm.OpportunityId=opp.id;
            otm.Validation_Override__c = true;
            otmlist.add(otm);
            
            otm=new OpportunityTeamMember();
            otm.TeamMemberRole='Technical Sales - Secondary';
            otm.UserId=partner.id;
            otm.OpportunityId=opp.id;
            otm.Validation_Override__c = true;
            otmlist.add(otm);
            OpportunityShare os = new OpportunityShare();
            os.OpportunityId = opp.id;
            os.UserOrGroupId = partner.id;
            os.OpportunityAccessLevel = 'Edit';
            insert os;
            
            //owner is active
            insert otmlist;
            
            //owner is inactive and no manager
            accOwnerUser.isActive=false;
            update accOwnerUser;
            OpportunityTriggerClass.createTaskWhenSalesStage6FirstRunFlag=true;
            opp.StageName='6. Signed';
            opp.Validation_Override__c=true;
            opp.Approvals_Received__c = 'Deal Reg Approval';
            update opp;
            Test.stopTest();
        }
    }

    public static testmethod void createTaskWhenSalesStage6TestCase2()
    {
        System.runAs(dmlUser){
            ManagedPkgErrorClass.isFromManagedPackage = false;
            User accOwnerUser, salesOpsUser, opptySCMOwnerUser;
            opptySCMOwnerUser = [select id from User where Profile.Name = 'Sales - Partner Account Executive' and IsActive = True limit 1][0];
            accOwnerUser = [select id from User where Profile.Name = 'Marketing Operations' and IsActive = True limit 1][0];
            salesOpsUser = [select id from User where Profile.Name = 'Sales Operations' and IsActive = True limit 1][0];
            Test.startTest();
            Account acc, Partneracc;
            List<String> accNames = new List<String>{'Test acc__1','Test Partneracc__1'};
                for(Account a : [select Id, Name from Account where Name IN : accNames]){
                    if(a.Name == 'Test acc__1')
                        acc = a;
                    else if(a.Name == 'Test Partneracc__1')
                        Partneracc = a;
                }
            
            Id profileId = GsmUtilClass.getGSMSettingValue('PartnerCommunityUserProfileId');
            User partner = SobjectRepository.getPartnerUser();
            
            Opportunity opp = [select Id, CloseDate, AccountId, Deal_Type__c, Partner_Involved__c, OwnerId from Opportunity where Name LIKE '__Test_Oppty_Bulk_%' limit 1];
            
            list<OpportunityTeamMember> otmlist = new list<OpportunityTeamMember>();
            OpportunityTeamMember otm=new OpportunityTeamMember();
            List<Opportunity> opps = new List<Opportunity>();
            opps.add(opp);
            otm.TeamMemberRole='Sales - Primary';
            otm.UserId=accOwnerUser.id;
            otm.OpportunityId=opp.id;
            otm.Validation_Override__c = true;
            otmlist.add(otm);
            
            otm=new OpportunityTeamMember();
            otm.TeamMemberRole='Partner';
            otm.UserId=partner.id;
            otm.OpportunityId=opp.id;
            otm.Validation_Override__c = true;
            otmlist.add(otm);
            
            OpportunityShare os = new OpportunityShare();
            os.OpportunityId = opp.id;
            os.UserOrGroupId = partner.id;
            os.OpportunityAccessLevel = 'Edit';
            insert os;
            
            insert otmlist;
            Map<Id, Map<Id, List<OpportunityTeammember>>> mapMem = new Map<Id, Map<Id, List<OpportunityTeammember>>>();
            mapMem = OpportunityTriggerClass.formulateOpportunityTeammemberMap(opps);
            
            opp.OwnerId=accOwnerUser.id;
            opp.StageName='1. Identify Need';
            opp.Opportunity_Leader__c = opp.OwnerId;
            opp.Owner__c = opp.OwnerId;
            opp.Validation_Override__c=true;
            update opp;
            
            //owner is inactive but manager present
            accOwnerUser.ManagerId=opptySCMOwnerUser.id;
            update accOwnerUser;
            opp.StageName='6. Signed';
            opp.Validation_Override__c=true;
            update opp;
            
            Test.stopTest();
        }
    }

    public static testmethod void TestOpporunityDeletion()
    {
        Test.startTest();
        System.runAs(dmlUser){
            ManagedPkgErrorClass.isFromManagedPackage = false;
            User accOwnerUser = [select id from User where Profile.Name = 'Sales Operations' and IsActive = True limit 1][0];
            Account acc = [select Id, OwnerId from Account where Name = '__Test Account' limit 1][0];
            
            Opportunity opp = utilTestClass.CreateOpportunity('__Test Oppty 0','1. Identify Need');
            opp.CloseDate = Date.today().addMonths(4);
            opp.AccountId = acc.Id;
            opp.Deal_Type__c='Direct';
            opp.OwnerId=accOwnerUser.id;
            opp.Opportunity_category__c='ALL';
            opp.Loss_reason__c='Bankruptcy';
            insert opp;
        
            system.runAs(accOwnerUser)
            {
                string msg='';
                try{
                    delete opp;
                }
                catch(Exception e)
                {
                    msg=e.getMessage();
                }
            }
            system.runAs(dmlUser)
            {
                delete opp;
            }
        }
        Test.stopTest();
    }

    /*public static testmethod void testVerifyMinimumContactRoles()
    {
        System.runAs(dmlUser){
            ManagedPkgErrorClass.isFromManagedPackage = false;
            Test.startTest();
            User u1 = [select id from User where Profile.Name = 'Business Operations' and IsActive = True limit 1][0];
            Account acc1 = [select Id, OwnerId from Account where Name = 'TEST_acc1' limit 1][0];
            Integer minRoles = Integer.valueOf(GsmUtilClass.getGSMSettingValue('OpptyTriggerClass_minContacts').trim());
            List<Contact> listOfContacts = new List<Contact>();
            for(Integer k=0; k<minRoles; k++)
            {
                Contact cont = utilTestClass.CreateContact('jimi'+k , 'hendrix');
                cont.AccountId = acc1.Id;
                listOfContacts.add(cont);
            }
            insert listOfContacts;
            System.runAs(u1)
            {
                List<Opportunity> listOfOpp = new List<Opportunity>();
                List<OpportunityContactRole> listOfOCR = new List<OpportunityContactRole>();
                Integer numberOfTestRecords = 2;
                for(Integer i=0 ; i<numberOfTestRecords ; i++)
                {
                    Opportunity opp = utilTestClass.CreateOpportunity('TEST_opp'+i, '3. Verify Options');
                    opp.AccountId = acc1.Id;
                    opp.CloseDate = Date.today().addMonths(4);   
                    opp.Opportunity_Category__c = 'Customer Churn';
                    opp.Loss_Reason__c = 'Bankruptcy';
                    opp.CurrencyIsoCode = 'USD';
                    listOfOpp.add(opp);
                }
                insert(listOfOpp);
                Map<Id, Map<Id, List<OpportunityContactRole>>> oppContactMap = new Map<Id, Map<Id, List<OpportunityContactRole>>>();
                oppContactMap = OpportunityTriggerClass.formulateOpportunityContactRoleMap(listOfOpp);
                Map<Id, List<OpportunityLineItem>> opptyIdToOLIList = utilTestClass.insertOpptyProductForEach(listOfOpp, 1, 'USD');
                for(Opportunity opp : listOfOpp)
                {
                    opp.StageName = '5. Negotiate';
                }
                try
                {
                    update(listOfOpp);
                }
                catch(Exception e)
                {
                    //system.assert(e.getMessage().contains(GsmUtilClass.getGSMSettingValue('OpptyTriggerClass_minOCRMsg')));
                }
                
                String contactRole = GsmUtilClass.getGSMSettingValue('OpptyTriggerClass_contactRole');
                for(Integer i=0 ; i<numberOfTestRecords ; i++)
                {
                    for(Integer j=0; j<2 ; j++)
                    {
                        OpportunityContactRole ocr = new OpportunityContactRole();
                        ocr.ContactId = listOfContacts[j].Id;
                        ocr.OpportunityId = listOfOpp[i].Id;
                        ocr.Role = contactRole;
                        listOfOCR.add(ocr);
                    }
                }
                
                insert(listOfOCR);
                
                for(Opportunity opp : listOfOpp)
                {
                    opp.Zero_MRR_Amount__c = 'Zero MRR Upgrade';
                    opp.StageName = '5. Negotiate';
                    opp.Validation_Override__c =true;
                }
                
                update(listOfOpp);
                OpportunityTriggerClass.verifyMinimumContactRolesOnStageChange(listOfOpp);
                Test.stopTest();
                for(Opportunity opp : [select Id, StageName from Opportunity where Id in :listOfOpp])
                {
                    System.assertEquals(opp.get('StageName') , '5. Negotiate');
                }
            }
        }
    }*/

    public static testMethod void testUpdateForecastedCountNegative()
    {
        System.runAs(dmlUser){
            ManagedPkgErrorClass.isFromManagedPackage = false;
            Test.startTest();
            User u1 = [select id from User where Profile.Name = 'Business Operations' and IsActive = True limit 1][0];
            Account acc1 = [select Id, OwnerId from Account where Name = 'TEST_acc1' limit 1][0];
            
            System.runAs(u1)
            {
                List<Opportunity> listOfOpp = new List<Opportunity>();
                Integer numberOfTestRecords = 2;
                
                for(Integer i=0 ; i<numberOfTestRecords ; i++)
                {
                    Opportunity opp = utilTestClass.CreateOpportunity('TEST_opp'+i, '3. Verify Options');
                    opp.AccountId = acc1.Id;
                    opp.CloseDate = Date.today();
                    opp.Deal_Type__c = 'Direct';
                    opp.Contract_ID__c = '12345';
                    opp.Override_New_Churn__c =false;
                    listOfOpp.add(opp);
                }
                insert(listOfOpp);
                
                listOfOpp = RefreshOpportunity(listOfOpp);
                for(Integer i=0;i<numberOfTestRecords;i++)
                {
                    System.assert((listOfOpp[i].ForecastCategoryName!='Commit' && listOfOpp[i].ForecastCategoryName!='Closed'), 'ForecastCategoryName wrong for index i' + i + ' Found - ' + listOfOpp[i].ForecastCategoryName);
                }
                UpdateForecastedOpportunityCountBatch batchObj = new UpdateForecastedOpportunityCountBatch();
                Database.executebatch(batchObj);
                Test.stopTest();
                listOfOpp = RefreshOpportunity(listOfOpp);
                for(Integer i=0;i<numberOfTestRecords;i++)
                {
                    System.assert(listOfOpp[i].New_Oppty_Count__c==0, 'Assert failed in index ' + i);
                }
            }
        }
    }

    public static testMethod void testUpdateForecastedCountPositive()
    {
        System.runAs(dmlUser){
            
            ManagedPkgErrorClass.isFromManagedPackage = false;
            Test.startTest();
            User u1 = [select id from User where Profile.Name = 'Business Operations' and IsActive = True limit 1][0];
            Account acc1 = [select Id, OwnerId from Account where Name = 'TEST_acc1' limit 1][0];
            
            System.runAs(u1)
            {
                List<Opportunity> listOfOpp = new List<Opportunity>();
                Integer numberOfTestRecords = 2;
                Integer numberOfOpptysWithZeroForecastMonth = 2;
                Integer numberOfOpptysWithOneForecastMonth = 3;
                Integer numberOfOpptysWithTwoForecastMonth = 4;
                
                for(Integer i=0 ; i<numberOfTestRecords ; i++)
                {
                    Opportunity opp = utilTestClass.CreateOpportunity('TEST_opp'+i, '5. Negotiate');
                    opp.AccountId = acc1.Id;
                    if(i<numberOfOpptysWithZeroForecastMonth)
                    {
                        opp.CloseDate = Date.today();
                    }
                    else if(i<numberOfOpptysWithZeroForecastMonth+numberOfOpptysWithOneForecastMonth)
                    {
                        opp.CloseDate = Date.today().addMonths(1);
                    }
                    else if(i<numberOfOpptysWithOneForecastMonth+numberOfOpptysWithZeroForecastMonth+numberOfOpptysWithTwoForecastMonth)
                    {
                        opp.CloseDate = Date.today().addMonths(2);  
                    }
                    else
                    {
                        opp.CloseDate = Date.today().addMonths(3);
                    }
                    opp.Deal_Type__c = 'Direct';
                    opp.ForecastCategoryName = 'Commit';
                    opp.Contract_ID__c = '12345';
                    opp.Override_New_Churn__c =false;
                    opp.CurrencyIsoCode = 'USD';
                    opp.Validation_Override__c =true;
                    opp.Opportunity_type__c='New Logo';
                    listOfOpp.add(opp);
                }
                insert(listOfOpp);
                
                Map<Id, List<OpportunityLineItem>> opptyIdToOLIList = utilTestClass.insertOpptyProductForEach(listOfOpp, 1, 'USD');
                 listOfOpp = RefreshOpportunity(listOfOpp);
                for(Integer i=0;i<numberOfTestRecords;i++)
                {
                   // System.assertEquals(listOfOpp[i].New_Churn__c, 'New');
                    System.assertEquals(listOfOpp[i].ForecastCategoryName, 'Commit');
                }
                //OpportunityScheduledJobsClass.updateForecastedOpportunityCount();
                UpdateForecastedOpportunityCountBatch batchObj = new UpdateForecastedOpportunityCountBatch();
                Database.executebatch(batchObj);
                
                Test.stopTest();
                listOfOpp = RefreshOpportunity(listOfOpp);
                for(Integer i=0;i<numberOfTestRecords;i++)
                {
                    if(i<numberOfOpptysWithZeroForecastMonth)
                    {
                        System.assert(listOfOpp[i].New_Oppty_Count__c==numberOfOpptysWithZeroForecastMonth, 'Assert failed in index ' + i+ ' Expected :' + numberOfOpptysWithZeroForecastMonth + '. Found: ' + listOfOpp[i].New_Oppty_Count__c);
                    }
                    else if(i<numberOfOpptysWithZeroForecastMonth+numberOfOpptysWithOneForecastMonth)
                    {
                        System.assert(listOfOpp[i].New_Oppty_Count__c==numberOfOpptysWithOneForecastMonth, 'Assert failed in index ' + i);
                    }
                    else if(i<numberOfOpptysWithOneForecastMonth+numberOfOpptysWithZeroForecastMonth+numberOfOpptysWithTwoForecastMonth)
                    {
                        System.assert(listOfOpp[i].New_Oppty_Count__c==numberOfOpptysWithTwoForecastMonth, 'Assert failed in index ' + i);
                    }
                    else
                    {
                        System.assert(listOfOpp[i].New_Oppty_Count__c==(numberOfTestRecords - numberOfOpptysWithOneForecastMonth - numberOfOpptysWithZeroForecastMonth - numberOfOpptysWithTwoForecastMonth), 'Assert failed in index ' + i);
                    }
                }
            }
        }
    }

    public static testMethod void testUpdateForecastedCountPositiveWithForecastMonthZero()
    {
        System.runAs(dmlUser){
            
            ManagedPkgErrorClass.isFromManagedPackage = false;
            Test.startTest();
            User u1 = [select id from User where Profile.Name = 'Business Operations' and IsActive = True limit 1][0];
            Account acc1 = [select Id, OwnerId from Account where Name = 'TEST_acc1' limit 1][0];
            
            System.runAs(u1)
            {
                List<Opportunity> listOfOpp = new List<Opportunity>();
                Integer numberOfTestRecords = 2;
                
                for(Integer i=0 ; i<numberOfTestRecords ; i++)
                {
                    Opportunity opp = utilTestClass.CreateOpportunity('TEST_opp'+i, '5. Negotiate');
                    opp.AccountId = acc1.Id;
                    opp.CloseDate = Date.today();
                    opp.Deal_Type__c = 'Direct';
                    opp.ForecastCategoryName = 'Commit';
                    opp.Contract_ID__c = '12345';
                    opp.Override_New_Churn__c =false;
                    opp.CurrencyIsoCode = 'USD';
                    opp.Validation_Override__c =true;
                    opp.Opportunity_type__c='New Logo';
                    listOfOpp.add(opp);
                }
                insert(listOfOpp);
                
                Map<Id, List<OpportunityLineItem>> opptyIdToOLIList = utilTestClass.insertOpptyProductForEach(listOfOpp, 1, 'USD');
                listOfOpp = RefreshOpportunity(listOfOpp);
                for(Integer i=0;i<numberOfTestRecords;i++)
                {
                    //System.assertEquals(listOfOpp[i].New_Churn__c, 'New');
                    System.assertEquals(listOfOpp[i].ForecastCategoryName, 'Commit');
                }
                UpdateForecastedOpportunityCountBatch batchObj = new UpdateForecastedOpportunityCountBatch();
                Database.executebatch(batchObj);

                Test.stopTest();
                listOfOpp = RefreshOpportunity(listOfOpp);
                for(Integer i=0;i<numberOfTestRecords;i++)
                {
                    System.assert(listOfOpp[i].New_Oppty_Count__c==numberOfTestRecords, 'Assert failed in index i' + i + '. Expected :0 but found : '+ listOfOpp[i].New_Oppty_Count__c);
                }
            }
        }
    }

    public static testmethod void testChangeOfUSDFieldsWithUSDCurrency()
    {
        System.runAs(dmlUser){            
            ManagedPkgErrorClass.isFromManagedPackage = false;
            User accOwnerUser = [select id from User where Profile.Name = 'Sales Operations' and IsActive = True limit 1][0];
            Account a = [select Id, OwnerId from Account where Name = '__Test Account' limit 1][0];
            System.runAs(accOwnerUser)
            {
                Test.startTest();
                List<Opportunity> listOfTestOpp = new List<Opportunity>();
                OpportunityStage stage = [select MasterLabel from OpportunityStage limit 1];
                Integer numOfTimes=2;
                for(Integer num=0 ; num<numOfTimes ; num++)
                {
                    Opportunity o = utilTestClass.CreateOpportunity('__ TEST','1. Identify Need');
                    o.AccountId = a.id;
                    o.CurrencyIsoCode = 'USD';  
                    o.name = 'test'+ String.valueof(num+1);
                    o.CloseDate    = Date.today() + (-365-num);
                    o.Validation_Override__c =true;
                    listOfTestOpp.add(o);
                }
                insert(listOfTestOpp);
                Integer numOfOpptyProductsForEachOppty = 1;
                Map<Id, List<OpportunityLineItem>> opptyIdToOLIList = utilTestClass.insertOpptyProductForEach(listOfTestOpp, numOfOpptyProductsForEachOppty, 'USD');
                List<OpportunityLineItem> listOfOLI = new List<OpportunityLineItem>();
                for(Id opptyId: opptyIdToOLIList.keySet())
                {
                    for(OpportunityLineItem oli : opptyIdToOLIList.get(opptyId))
                    {
                        listOfOLI.add(oli);
                    }
                    
                }
                
                listOfOLI = refreshOpportunityLineItem(listOfOLI);
                list<USD__mdt> objList = new list<USD__mdt>();
                objList = [Select Field__c,USD_Field__c from USD__mdt where Object__c ='OpportunityLineItem'];
                
                //SFDC-1453
                List<USD__mdt> usdList = [Select Field__c,USD_Field__c from USD__mdt where Object__c ='Opportunity'];
                for(Opportunity oppty : listOfTestOpp)
                {
                    for(USD__mdt obj : usdList)
                        System.assertEquals(oppty.get(obj.Field__c),oppty.get(obj.USD_Field__c));
                }
                //change closedate and verify that MRR and MRR in dollar fields are same
                for(Opportunity tempOpp : listOfTestOpp )
                {
                    tempOpp.CloseDate = tempOpp.CloseDate + (-90);
                }
                update listOfTestOpp;
                Test.stopTest();
            }
        }
    }

    public static testmethod void testChangeOfUSDFieldsOnCloseDateChange()
    {
        System.runAs(dmlUser){            
            ManagedPkgErrorClass.isFromManagedPackage = false;
            User accOwnerUser = [select id from User where Profile.Name = 'Sales Operations' and IsActive = True limit 1][0];
            Account a = [select Id, OwnerId from Account where Name = '__Test Account10' limit 1][0];
            System.runAs(accOwnerUser)
            {
                Test.startTest();
                List<Opportunity> listOfTestOpp = new List<Opportunity>();
                OpportunityStage stage = [select MasterLabel from OpportunityStage limit 1];
                Integer numOfTimes=2;
                for(Integer num=0 ; num<numOfTimes ; num++)
                {
                    Opportunity o = utilTestClass.CreateOpportunity('__ TEST','1. Identify Need');
                    o.AccountId = a.id;
                    o.CurrencyIsoCode = 'INR';  
                    o.name = 'test'+ String.valueof(num+1);
                    o.CloseDate    = Date.today() + (-365-num);
                    o.Validation_Override__c =true;
                    listOfTestOpp.add(o);
                }
                insert(listOfTestOpp);
                Integer numOfOpptyProductsForEachOppty = 3;
                Map<Id, List<OpportunityLineItem>> opptyIdToOLIList = utilTestClass.insertOpptyProductForEach(listOfTestOpp, numOfOpptyProductsForEachOppty, 'INR');
                List<OpportunityLineItem> listOfOLI = new List<OpportunityLineItem>();
                Map<Id,OpportunityLineItem> mapOfNewOliIdToOli = new Map<Id,OpportunityLineItem>();
                for(Id opptyId: opptyIdToOLIList.keySet())
                {
                    for(OpportunityLineItem oli : opptyIdToOLIList.get(opptyId))
                    {
                        listOfOLI.add(oli);
                    }
                    
                }
                listOfOLI = refreshOpportunityLineItem(listOfOLI);
                OpportunityTriggerClass.UpdateCarrierApplicationOnOpportunity(listOfOLI,new Map<Id,Opportunity>());
                
                for(Opportunity tempOpp : listOfTestOpp )
                {
                    tempOpp.CloseDate = tempOpp.CloseDate + (-365);
                }
                update listOfTestOpp;
                Test.stopTest();
            }
        }
    }

    public static testmethod void testUSDFieldsCronJob()
    {
        System.runAs(dmlUser){            
            ManagedPkgErrorClass.isFromManagedPackage = false;
            User accOwnerUser = [select id from User where Profile.Name = 'Sales Operations' and IsActive = True limit 1][0];
            Account a = [select Id, OwnerId from Account where Name = '__Test Account10' limit 1][0];
            Test.startTest();
            System.runAs(accOwnerUser)
            {
                List<Opportunity> listOfTestOpp = new List<Opportunity>();
                OpportunityStage stage = [select MasterLabel from OpportunityStage limit 1];
                Integer numOfTimes=2;
                for(Integer num=0 ; num<numOfTimes ; num++)
                {
                    Opportunity o = utilTestClass.CreateOpportunity('__ TEST','1. Identify Need');
                    o.AccountId = a.id;
                    o.CurrencyIsoCode = 'INR';  
                    o.name = 'test'+ String.valueof(num+1);
                    o.CloseDate    = Date.today() + 365;
                    o.Validation_Override__c =true;
                    listOfTestOpp.add(o);
                }
                
                insert(listOfTestOpp);
                Integer numOfOpptyProductsForEachOppty = 1;
                // make sure override the dollar mrr trigger update so that the job can fix these
                OpportunityUtilClass.genericUSDFlagForTestClass = false;
                Map<Id, List<OpportunityLineItem>> opptyIdToOLIList = utilTestClass.insertOpptyProductForEach(listOfTestOpp, numOfOpptyProductsForEachOppty, 'INR');
                List<OpportunityLineItem> listOfOLI = new List<OpportunityLineItem>();
                for(Id opptyId: opptyIdToOLIList.keySet())
                {
                    for(OpportunityLineItem oli : opptyIdToOLIList.get(opptyId))
                    {
                        listOfOLI.add(oli);
                    }
                }
                
                listOfOLI = refreshOpportunityLineItem(listOfOLI);
                list<USD__mdt> objList = new list<USD__mdt>();
                objList = [Select Field__c,USD_Field__c from USD__mdt where Object__c ='OpportunityLineItem'];
                //make sure MRR USD fields are null
                for(OpportunityLineItem tempOLI : listOfOLI )
                {
                    for(USD__mdt obj : objList)
                        System.assert(tempOLI.get(obj.USD_Field__c) == null || tempOLI.get(obj.USD_Field__c) == 0.0,obj.USD_Field__c + 'is null or zero' + tempOLI.get(obj.USD_Field__c));
                } 
                OpportunityUtilClass.genericUSDFlagForTestClass = true;
                CronCurrencytoUsdConversionBatchClass tempBatchClass= new CronCurrencytoUsdConversionBatchClass();
                Database.executeBatch(tempBatchClass);
                
                listOfOLI = refreshOpportunityLineItem(listOfOLI);
                Test.stopTest();
            }
        }
    }
    
    /**Sonali Tandon - 22/02/2016 - CR 3313721 - NAP -- Enhance Partner Onboarding form :: When Partner onboarding record is created/ opportunity on
    it is updated, stamp the partner onboarding on the corresponding opportunity.**/
    static testmethod void teststampPartnerOnboardingOnOppty()
    {
        System.runAs(dmlUser){            
            ManagedPkgErrorClass.isFromManagedPackage = false;
            Test.startTest();
            Account acct = [select Id, OwnerId from Account where Name = 'Test acc__1' limit 1][0];
            // Create 2 opptys
            Opportunity oppty1 = utilTestClass.CreateOpportunity('__Test Oppty1','1. Identify Need');
            oppty1.AccountId = acct.Id;
            oppty1.Deal_Type__c = 'Indirect';
            oppty1.CloseDate = Date.today().addMonths(4);
            oppty1.Validation_Override__c =true;
            insert oppty1;            
            // associate POB record with Opportunity 1
            Partner_Onboarding__c pOb = utilTestClass.CreatePartnerOnboarding(oppty1.Id);      
            
            insert pOb;
            Test.stopTest();
            
            //Opportunity refreshedOppty = [Select Id,Partner_Onboarding__c from Opportunity where Id =: oppty1.Id ];
            //System.assertEquals(refreshedOppty.Partner_Onboarding__c, pOb.Id);
        }
    }

    public static testmethod void TestupdateDealRegOpptyShareForPartnerInvolved()
    {
        System.runAs(dmlUser){            
            ManagedPkgErrorClass.isFromManagedPackage = false;
            Test.startTest();
            User accOwnerUser = [select id from User where Profile.Name = 'Sales Operations' and IsActive = True limit 1][0];
            List<Account> partnerAccountList = [select id from account where isPartnerCustom__c=true order by createddate desc limit 2];
            //SFDC-1571
            Map<String, Schema.RecordTypeInfo> rtMap = Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName();
            Opportunity opp = utilTestClass.CreateOpportunity('__Test Oppty 0','1. Identify Need');
            opp.CloseDate = Date.today().addMonths(4);
            opp.Partner_Involved__c = partnerAccountList[0].Id;
            opp.Deal_Type__c='Indirect';
            opp.OwnerId=accOwnerUser.id;
            opp.recordtypeId = rtMap.get('Deal Reg Unsubmitted').getRecordTypeId();
            OpportunityTriggerClass.addOpptyShareFirstRunFlag = true;
            insert opp;
            
            List<OpportunityShare> oppShares = new List<OpportunityShare>();
            oppShares = [select id, OpportunityAccessLevel, RowCause, UserOrGroupId,OpportunityId from OpportunityShare where OpportunityId = :opp.id];
            
            system.assert(oppShares.size()>=2);
            //SFDC-1571
            OpportunityTriggerClass.addOpptyShareFirstRunFlag = true;
            OpportunityTriggerClass.delOpptyShareFirstRunFlag = true;
            opp.Partner_Involved__c = partnerAccountList[1].id;
            opp.recordtypeId = rtMap.get('Deal Reg Submitted').getRecordTypeId();
            update opp;
            
            oppShares = [select id, OpportunityAccessLevel, RowCause, UserOrGroupId,OpportunityId from OpportunityShare where OpportunityId = :opp.id];
            test.stopTest();
        }
    }

    public static testmethod void BulkTestupdateDealRegOpptyShareForPartnerInvolved()
    {
        System.runAs(dmlUser){            
            ManagedPkgErrorClass.isFromManagedPackage = false;
            User accOwnerUser, opptyOwnerUser;
            opptyOwnerUser = [select id from User where Profile.Name = 'Sales - Partner Account Executive' and IsActive = True limit 1][0];
            accOwnerUser = [select id from User where Profile.Name = 'Marketing Operations' and IsActive = True limit 1][0];
            Account acc = [select Id, OwnerId from Account where Name = '__Test Account1' limit 1][0];
            acc.Validation_Override__c=true;
            acc.IsPartner = true;
            acc.IsPartnercustom__C = true;
            // SFDC-9222
            acc.Partner_Type__c = 'ADS Partner';
            acc.Partner_status__c = 'Partner';
            Test.startTest();
            update acc;
            //Bulk insert
            Integer i;
            List<Opportunity> bulkOpportunitiesList = new List<Opportunity>(); 
            
            Map<String, Schema.RecordTypeInfo> rtMap = Opportunity.sObjectType.getDescribe().getRecordTypeInfosByName();
            for(i=0;i<2;i++)
            {       
                Opportunity oppty = utilTestClass.CreateOpportunity('#Test bulkAddOpptyShares'+i,'1. Identify Need');
                oppty.AccountId = acc.Id;
                oppty.OwnerId = opptyOwnerUser.Id;
                oppty.CloseDate = Date.today();
                oppty.Partner_Involved__c = acc.Id;
                oppty.Deal_Type__c='Indirect';
                oppty.recordtypeId = rtMap.get('Deal Reg Unsubmitted').getRecordTypeId();
                bulkOpportunitiesList.add(oppty);
            }       
            for(i=0;i<2;i++)
            {       
                Opportunity oppty = utilTestClass.CreateOpportunity('#Test bulkAddOpptyShares'+i,'1. Identify Need');
                oppty.AccountId = acc.Id;
                oppty.OwnerId = opptyOwnerUser.Id;
                oppty.CloseDate = Date.today();
                
                oppty.recordtypeId = rtMap.get('Akamai Opportunity').getRecordTypeId();
                bulkOpportunitiesList.add(oppty);
            }         
            //insert bulkOpportunitiesList;
            System.runAs(opptyOwnerUser){insert bulkOpportunitiesList;}
            
            List<Opportunity> akamaiBulkOpportunitiesList = [select Id,Name, New_Oppty_Count__c,OwnerId,CreatedById,ForecastCategoryName,recordtypeId,Partner_Involved__c,Deal_Type__c from Opportunity where Id IN :bulkOpportunitiesList and recordtypeId = 'Akamai Opportunity'];
            for(Opportunity oppty : akamaiBulkOpportunitiesList){
                oppty.Partner_Involved__c = acc.Id;
                oppty.Deal_Type__c='Indirect';
            }
            update akamaiBulkOpportunitiesList;
            Test.stopTest();
        }
    }

    //SFDC-1571
    static testMethod void getCMRecordsTest()
    {
        test.startTest();
        System.runAs(dmlUser){            
            ManagedPkgErrorClass.isFromManagedPackage = false;
            User opptySCMOwnerUser = [select id from User where Profile.Name = 'Sales - Partner Account Executive' and IsActive = True limit 1][0];
            Account Partneracc = [select Id, OwnerId from Account where Name = 'Test Partneracc__1' limit 1][0];
            System.runAs(opptySCMOwnerUser){
                Channel_Mapping__c cm = utilTestClass.CreateChannelMapping('Test Channel Mapping', Partneracc.Id, opptySCMOwnerUser.Id);
                insert cm;
            }
            OpportunityPRMTriggerClass.GetChannelMapping(new List<Id>{Partneracc.id});
            OpportunityPRMTriggerClass.getCMRecordsForAccount(Partneracc.id);
        }
        test.stopTest();
    }

    static testMethod void testForecastCategory()
    {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        User accOwnerUser = [select id from User where Profile.Name = 'Marketing Operations' and IsActive = True limit 1][0];
        Account acc = [select Id, OwnerId from Account where Name = '__Test Account1' limit 1][0];
        System.runAs(accOwnerUser) {
            Opportunity opp = utilTestClass.CreateOpportunity('__Test Oppty 0','1. Identify Need');
            opp.AccountId = acc.Id;
            opp.CloseDate = Date.today().addMonths(4);
            //opp.Partner_Involved__c = acc.Id;
            opp.Deal_Type__c='Direct';
            opp.OwnerId=accOwnerUser.id;
            opp.Partner_Forecast_Amount__c = 10;
            //opp.recordtypeId = rtMap.get('Deal Reg Unsubmitted').getRecordTypeId();
            Test.startTest();
            insert opp;
            //OpportunityLineItem oli = utilTestClass.insertSecurityOpptyProduct(opp,'USD','Security');
            utilTestClass.insertOpptyProductForEach(new List<Opportunity>{opp},2,'USD');
            //insert oli;
            OpportunityTriggerClass.managePartnerForecastFirstRunFlag = true;
            OpportunityTriggerClass.manageForecastCategoryFirstRunFlag = true;
            opportunitytriggerClass.manageForecastFirstRunFlag = true;
            opp.stageName= '3. Verify Options';
            opp.PAE_Projected_Monthly_Commit__c = 30;
            opp.DPM_Projected_Monthly_Commit__c = 30;
            opp.DPM_MRR_Override__c = true;
            opp.Service_MRR_Override_1__c = true;
            opp.Override_PAE_TCV__c = true;
            opp.Override_Close_Date__c =true;
            update opp;
            OpportunityTriggerClass.managePartnerForecastFirstRunFlag = true;
            OpportunityTriggerClass.manageForecastCategoryFirstRunFlag = true;
            opportunitytriggerClass.manageForecastFirstRunFlag = true;
            opp.stageName= '6. Signed';
            opp.validation_override__C = true;
            update opp;
            OpportunityTriggerClass.managePartnerForecastFirstRunFlag = true;
            OpportunityTriggerClass.manageForecastCategoryFirstRunFlag = true;
            opportunitytriggerClass.manageForecastFirstRunFlag = true;
            opp.stageName= '6. Signed';
            opp.validation_override__C = false;
            opp.Partner_Forecast_Amount__c = 40;
            opp.DPM_Projected_Monthly_Commit__c = 60;
            opp.Service_Projected_Monthly_Commit_1__c = 60;
            opp.PAE_Close_Date__c = Date.today();
            opp.Partner_Forecast__c = 'Commit';
            try{    
                update opp;
            }catch(DmlException e){
                system.debug(LoggingLevel.ERROR,' in catch:: '+e.getMessage());
                system.assert(e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'));
            }
            Test.stopTest();
        }
    }

    static testmethod void testsetFieldsWhenDealIsRejected()
    {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        User accOwnerUser, u1;
        u1 = [select id from User where Profile.Name = 'Business Operations' and IsActive = True limit 1][0];
        accOwnerUser = [select id from User where Profile.Name = 'Marketing Operations' and IsActive = True limit 1][0];
        Account acc = [select Id from Account where Name = '__Test Account1' limit 1][0];
        System.runAs(accOwnerUser) {
            Opportunity opp = utilTestClass.CreateOpportunity('__Test Oppty 0','1. Identify Need');
            opp.CloseDate = Date.today().addMonths(4);
            
            opp.Partner_Forecast_Amount__c = 10;
            opp.AccountId = acc.Id;
            opp.Deal_Type__c='Direct';
            
            Test.startTest();
            insert opp;
            OpportunityTriggerClass.opptyAddOpportunityShareSettings(opp.id, u1.id, 'Edit');
            OpportunityPRMTriggerClass.isopptyWithRejectedDealRegStatus= true;
            opp.Registration_Status__c = 'Rejected';
            opp.CloseDate = Date.today().addMonths(-1);
            update opp;
            OpportunityTriggerClass.CloseOldOpportunities();
            Test.stopTest();
        }
    }

    static testmethod void testupdateOnlineChannelOpptyTaskStatus()
    {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        User accOwnerUser = [select id from User where Profile.Name = 'Business Operations' and IsActive = True limit 1][0];
        Opportunity opp = [select Id from Opportunity where Name = '__Test Oppty1' limit 1][0];
        System.runAs(accOwnerUser) {
            Test.startTest();
            Task oppTask = utilTestClass.createTask(accOwnerUser.id,'Request for Contract Entry','In Progress','Meeting',opp.id);
            insert oppTask;
            opp.StageName ='Closed Won';
            opp.Contract_Entered_by__c ='Online Channel';
            opp.Momentum_Automated__c ='Online Channel Sales';
            opp.No_of_Contracts__c = '1';
            opp.Validation_Override__c =true;
            update opp;
            Test.stopTest();
        }
    }

    static testmethod void testupdateOrderRegionActiveAccount()
    {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        User accOwnerUser = [select id from User where Profile.Name = 'Business Operations' and IsActive = True limit 1][0];
        Account acc = [select Id from Account where Name = 'Test acc__6' limit 1][0];
        //Opportunity opp = [select Id from Opportunity where Name = '__Test Oppty1' limit 1][0];
        System.runAs(accOwnerUser) {
            Test.startTest();
            Order_Region_Reporting_Region_Mapping__c test1 = new Order_Region_Reporting_Region_Mapping__c(name='India',Order_Region__c='India',Reporting_Region__c='INDIA');
            insert test1;
            Sales_Approved_Country__c sac = new Sales_Approved_Country__c(Name='INDIA' ,Order_Region__c='India',Order_Currency__c='USD',Sub_Region__c='India',Region__c='India');
            insert sac;
            Opportunity opp = utilTestClass.CreateOpportunity('__Test Oppty 0','1. Identify Need');
            opp.CloseDate = Date.today().addMonths(4);
            //opp.Partner_Involved__c = acc.Id;
            
            opp.Partner_Forecast_Amount__c = 10;
            opp.AccountId = acc.Id;
            opp.Deal_Type__c='Direct';
            opp.Is_Authorized_Partner_Sellable_Country__c = false;
            //opp.Partner_Involved__c=Partneracc.id;
            
            //opp.recordtypeId = rtMap.get('Deal Reg Unsubmitted').getRecordTypeId();
            insert opp;
            opp.Order_Region__c = 'Japan';
            opp.Validation_Override__c = True;
            update opp;
            Test.stopTest();
        }
    }

    static testmethod void testupdateOrderRegioninActiveAccount()
    {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        User accOwnerUser = [select id from User where Profile.Name = 'Business Operations' and IsActive = True limit 1][0];
        Account acc = [select Id from Account where Name = 'Test acc__6' limit 1][0];
        //Opportunity opp = [select Id from Opportunity where Name = '__Test Oppty1' limit 1][0];
        System.runAs(accOwnerUser) {
            Opportunity opp = utilTestClass.CreateOpportunity('__Test Oppty 0','1. Identify Need');
            opp.CloseDate = Date.today().addMonths(4);
            //opp.Partner_Involved__c = acc.Id;
            
            opp.Partner_Forecast_Amount__c = 10;
            opp.AccountId = acc.Id;
            opp.Deal_Type__c='Direct';
            opp.Is_Authorized_Partner_Sellable_Country__c = false;
            //opp.Partner_Involved__c=Partneracc.id;
            
            //opp.recordtypeId = rtMap.get('Deal Reg Unsubmitted').getRecordTypeId();
            Test.startTest();
            Order_Region_Reporting_Region_Mapping__c test1 = new Order_Region_Reporting_Region_Mapping__c(name='India',Order_Region__c='India',Reporting_Region__c='INDIA');
            insert test1;
            Sales_Approved_Country__c sac = new Sales_Approved_Country__c(Name='INDIA' ,Order_Region__c='India',Order_Currency__c='USD',Sub_Region__c='India',Region__c='India');
            insert sac;
            insert opp;
            opp.Order_Region__c = 'Japan';
            opp.Validation_Override__c = True;
            update opp;
            Test.stopTest();
        }
    }

    //SFDC-1595
    public static testmethod void populateChannelLevelTest()
    {
        User accOwnerUser, opptySCMOwnerUser;
        opptySCMOwnerUser = [select id from User where Profile.Name = 'Sales - Partner Account Executive' and IsActive = True limit 1][0];
        accOwnerUser = [select id from User where Profile.Name = 'Marketing Operations' and IsActive = True limit 1][0];
        Account acc, partneracc;
        List<String> accNames = new List<String>{'__Test Account7','__Test partner Account'};
            for(Account a : [select Id, Name from Account where Name IN : accNames]){
                if(a.Name == '__Test Account7')
                    acc = a;
                else if(a.Name == '__Test partner Account')
                    partneracc = a;
            }
        Channel_Hierarchy_Map__c chm1 = new Channel_Hierarchy_Map__c(Name='AT&T-AT&T-UKI Media',CHANNEL_GEOGRAPHY__c='Carrier Americas',CHANNEL_ID__c='1601',CHANNEL_LEVEL_1__c='Team AT&T',CHANNEL_LEVEL_2__c='Team AT&T',CHANNEL_LEVEL_3__c='Team AT&T',GLOBAL_PARTNER__c='AT&T');
        Channel_Hierarchy_Map__c chm2 = new Channel_Hierarchy_Map__c(Name='Unknown-AT&T',CHANNEL_GEOGRAPHY__c='Carrier EMEA',CHANNEL_ID__c='2320',CHANNEL_LEVEL_1__c='Team UKI',CHANNEL_LEVEL_2__c='Team UKI',CHANNEL_LEVEL_3__c='Team UKI',GLOBAL_PARTNER__c='AT&T');
        List<Channel_Hierarchy_Map__c> chmlist = new List<Channel_Hierarchy_Map__c>();
        chmlist.add(chm1);
        chmlist.add(chm2);
        System.runAs(accOwnerUser) {
            AccountTriggerClass.createUpdateEntitlementFirstRunFlag=true;
            insert chmlist;
        }
        Opportunity oppty1 = utilTestClass.CreateOpportunity('__Test Oppty 0','1. Identify Need');
        oppty1.AccountId =acc.Id;
        oppty1.OwnerId = opptySCMOwnerUser.Id;
        oppty1.CloseDate = Date.today(); 
        Oppty1.deal_type__c = 'Indirect';
        oppty1.Partner_Involved__c = partneracc.id;
        Test.startTest();
        System.runAs(opptySCMOwnerUser){
            AccountTriggerClass.createUpdateEntitlementFirstRunFlag=true;
            insert oppty1;
            oppty1 = [select id,Channel_Hierarchy_Map__c from Opportunity where id=:oppty1.id];
        }
        
        System.runAs(accOwnerUser){
            acc.Parent_Division__c = 'Americas_Enterprise & Carrier';
            acc.Region__c = 'Carrier Americas';
            AccountTriggerClass.createUpdateEntitlementFirstRunFlag=true;
            update acc;
            oppty1 = [select id,Channel_Hierarchy_Map__c from Opportunity where id=:oppty1.id];
        }
        Test.stopTest();
    }

    //SFDC-2324
    public static testmethod void fcmFieldUpdateOnChannelManagerChange()
    {
        User accOwnerUser, opptySCMOwnerUser;
        opptySCMOwnerUser = [select id from User where Profile.Name = 'Sales - Partner Account Executive' and IsActive = True limit 1][0];
        accOwnerUser = [select id from User where Profile.Name = 'Marketing Operations' and IsActive = True limit 1][0];
        Account acc, partneracc;
        List<String> accNames = new List<String>{'__Test Account7','__Test partner Account'};
            for(Account a : [select Id, Name from Account where Name IN : accNames]){
                if(a.Name == '__Test Account7')
                    acc = a;
                else if(a.Name == '__Test partner Account')
                    partneracc = a;
            }
        System.runAs(accOwnerUser)
        {
            Test.startTest();
            //Channel_Mapping__c cm= new Channel_Mapping__c(Name = 'Test Channel Mapping', Partner_Name__c = Partneracc.id, PAE_ID__c = opptySCMOwnerUser.id);
            Channel_Mapping__c cm = utilTestClass.CreateChannelMapping('Test Channel Mapping', Partneracc.Id, opptySCMOwnerUser.Id);
            insert cm;
            
            Opportunity oppty1 = utilTestClass.CreateOpportunity('__Test Oppty 0','1. Identify Need');
            oppty1.AccountId =acc.Id;
            oppty1.OwnerId = opptySCMOwnerUser.Id;
            oppty1.CloseDate = Date.today(); 
            oppty1.Deal_type__c = 'Indirect';
            oppty1.Partner_Involved__c = partneracc.id;
            oppty1.Channel_Manager__c = cm.Id;
            
            insert oppty1;
            Test.stopTest();
        }
    }
    
    //Only for code coverege 
    static testmethod void methodForCodeCoverege()
    {
        System.runAs(dmlUser){  
            list<Opportunity> opplist=[select Id, CloseDate, AccountId, Deal_Type__c, Partner_Involved__c, Contract_Entered_by__c, Contract_Reviewed_by__c, Partner_Involved_AKAM_Id__c,
                                       Renew_Contract_Id_Text__c, Contract_Effective_End_Date__c, Channel_Manager__c,Transaction_Type__c,Double_Reviewed_By__c
                                       from Opportunity where Name LIKE '__Test_Oppty_Bulk_%' limit 1];
            Test.startTest();
            OpportunityTriggerClass.checkUnderSharingForPartners();
            OpportunityTriggerClass.checkOverSharingForPartners();
            OpportunityTriggerClass.updateOnlineChannelOpptyTaskStatus(opplist[0]);
            OpportunityTriggerClass.populateRenewalOpptyFieldsFirstRunFlag = true;
            OpportunityTriggerClass.populateRenewalOpptyFields(opplist);
            OpportunityTriggerClass.managerSwarmOpptys(opplist);
            OpportunityTriggerClass.updateOpptyStageForAMG(opplist);
            OpportunityTriggerClass.checkForInactiveUser(opplist);
            OpportunityTriggerClass.createtask(null,null,null,null,null,null);
            OpportunityTriggerClass.createtask(null,null,null,null,null,null,false,null,null);
            Test.stopTest();
        }
    }

    /**
        RefreshOpportunity()
        - Overloaded to refresh Single Opportunity
    */
    private static List<Opportunity> RefreshOpportunity(Opportunity pOpp)
    {
        return RefreshOpportunity(new List<Opportunity> {pOpp});
    }
    /**
        RefreshOpportunity()
        - Overloaded to refresh bulk Opportunities
    */
    private static List<Opportunity> RefreshOpportunity(List<Opportunity> pOppList)
    {
        //SFDC-1453
        String query = 'SELECT Name,New_Oppty_Count__c,OwnerId,CreatedById,ForecastCategoryName';
        List<String> parameters = OpportunityUtilClass.buildSOQLParametersForUSDConversion('Opportunity');
        for(String params : parameters)
            query+=','+ params;
        query += ' from Opportunity where id IN :pOppList';
        return Database.query(query);
        
    }   
    
    private static List<OpportunityLineItem> refreshOpportunityLineItem(List<OpportunityLineItem> oliList)
    {
        //SFDC-1453
        String query = 'SELECT unitprice,OpportunityId,quantity';
        List<String> parameters = OpportunityUtilClass.buildSOQLParametersForUSDConversion('OpportunityLineItem');
        for(String params : parameters)
            query+=','+ params;
        query += ' from OpportunityLineItem where id IN :oliList order by AKAM_Created_Date__c';
        System.debug('query'+query);
        return Database.query(query);
    }

    public static testmethod void sendEmailToSpecialist(){

        Account acc = [select Id from Account where Name = 'Test acc__6' limit 1][0];
        Opportunity opp = utilTestClass.CreateOpportunity('__Test Oppty 0','3. Verify Options');
        opp.AccountId = acc.Id;
        opp.CloseDate = Date.today(); 
        opp.deal_type__c = 'Direct';
        Test.startTest();
        opp.Validation_Override__c = True;
        insert opp;

        opp = [select Id, CurrencyIsoCode ,OwnerId
                     from Opportunity 
                     where Name = '__Test Oppty 0'];

        List<Specialist_Comp_Team__c> SCTList = new List<Specialist_Comp_Team__c>();
        user opptySCMOwnerUser = [select id from User where Profile.Name = 'Sales - Partner Account Executive' and IsActive = True limit 1][0];

        Specialist_Comp_Team__c SCT = new Specialist_Comp_Team__c();
        SCT.Product_Specialist__c = opp.OwnerId;
        SCT.Type__c = 'Enterprise Sales Specialist';
        SCTList.add(SCT);

        Specialist_Comp_Team__c SCT1 = new Specialist_Comp_Team__c();
        SCT1.Product_Specialist__c = opptySCMOwnerUser.id;
        SCT1.Type__c = 'CIAM Specialist';
        SCTList.add(SCT1);

        insert SCTList;

        List<Product2> productList = new List<Product2>();
            
        Product2 testProduct1= new Product2();
        testProduct1.Name = 'Test_Security_Product';
        testProduct1.family = 'Enterprise';
        testProduct1.AKAM_INT_ID__c = 111;
        testProduct1.AKAM_Product_ID__c='F-PRO-2021850';
        productList.add(testProduct1);
        
        Product2 testProduct2= new Product2();
        testProduct2.Name = 'Test_Web_Product';
        testProduct2.family = 'Web';
        testProduct2.AKAM_INT_ID__c = 222;
        testProduct2.AKAM_Product_ID__c='F-PRO-2573650';
        productList.add(testProduct2);
        
        Product2 testProduct3= new Product2();
        testProduct3.Name = 'Test_Enterprise_Product';
        testProduct3.family = 'Security';
        testProduct3.AKAM_INT_ID__c = 333;
        testProduct3.AKAM_Product_ID__c='F-PRO-2827950';
        productList.add(testProduct3);

        insert productList;

        // Create pricebook entries
        List<PricebookEntry> pricebookList = new List<PricebookEntry>();
        for(Product2 product : productList)
        {
            PricebookEntry pbEntry= new PricebookEntry();
            pbEntry.Pricebook2Id = Test.getStandardPricebookId();
            pbEntry.Product2Id   = product.id;
            pbEntry.CurrencyIsoCode = 'USD';
            pbEntry.IsActive     = true;
            pbEntry.UnitPrice    = 1; 
            pricebookList.add(pbEntry);      
        }

        insert(pricebookList);
        // Create line items 
        List<OpportunityLineItem> OpportunityLineItemList= new List<OpportunityLineItem>();
        for(PricebookEntry pbEntry : pricebookList) {
            OpportunityLineItem oli = new OpportunityLineItem();
            oli.opportunityId       = opp.id;
            oli.pricebookentryid    = pbEntry.Id;
            oli.quantity            = 1;
            oli.unitprice           = 200;
            oli.Average_Renewal_Commit_MRR__c = 100;
            oli.Average_Renewal_Usage_MRR__c = 100;
            oli.Projected_Monthly_commit_fees__c = 100;
            oli.Projected_Avg_Rev_Non_Commit__c = 100;
            OpportunityLineItemList.add(oli);
        }
        
        insert OpportunityLineItemList;

        opp.Soha_Specialist__c = SCT.id;
        opp.CIAM_Specialist__c = SCT1.id;
        opp.StageName = 'Closed Lost';
        opp.Validation_Override__c = True;
        opp.Opportunity_Category__c ='Contract Moves';  
        opp.Loss_Reason__c ='Contract Consolidation';
        update opp;
        Test.stopTest();
    }

}