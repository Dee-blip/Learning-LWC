/**
 * @description       : 
 * @author            : apyati
 * @team              : GSM
 * @last modified on  : 08-30-2021
 * @last modified by  : apyati
 * Modifications Log
 * Ver   Date         Author   Modification
 * 1.0   08-30-2021   apyati   Initial Version
**/
@isTest
private class OpportunityLineItemTests 
{
    static User dmlUser = new User(id=UserInfo.getUserId());
    private static final Integer numOfProducts=3;

   

    @testSetUp static void createTestData()
    {
        User sOpsUser = SObjectRepository.getSalesOpsUser();
        new SobjectBuilder(Environment_Setup__c.sObjectType)
            .put(Environment_Setup__c.Environment_Type__c, 'Primary')
            .put(Environment_Setup__c.Active_Org__c, true)
            .put(Environment_Setup__c.Akam_Id_Start_String__c, 'F-')
            .create();

           
       /*
        {
             new SObjectBuilder(Account_Reassignment_Rule__c.sObjectType)
            .eagerPopulate()
            .put(Account_Reassignment_Rule__c.SubTerritory__c, 'Multiple')
            .put(Account_Reassignment_Rule__c.Associated_User__c, sOpsUser.Id)
            .create();
        }*/
           new SobjectBuilder(Order_Region_Reporting_Region_Mapping__c.sObjectType)
                .put(Order_Region_Reporting_Region_Mapping__c.Name, 'India')
                .put(Order_Region_Reporting_Region_Mapping__c.Order_Region__c, 'India')
                .put(Order_Region_Reporting_Region_Mapping__c.Reporting_Region__c, 'INDIA')
                .create();

            new SObjectBuilder(Sales_Approved_Country__c.sObjectType)
                .put(Sales_Approved_Country__c.Order_Region__c, 'India')
                .put(Sales_Approved_Country__c.Order_Currency__c, 'USD')
                .put(Sales_Approved_Country__c.Sub_Region__c, 'North')
                .put(Sales_Approved_Country__c.Region__c, 'Gharwal')
                .create();

        Account acc;
        
        System.runAs(sOpsUser)
        {
            acc = (Account)new SobjectBuilder(Account.sObjectType)
                .eagerPopulate()
                .put(Account.Vertical__c, 'Public Sector')
                .put(Account.Sub_Vertical__c, 'PS - Higher Ed')
                .put(Account.Anaplan_Sub_Territory__c, 'Multiple')
                .put(Account.Finance_Region__c, 'INDIA')
                .put(Account.IsGlobalAccount__c, True) //SFDC-6410
                .put(Account.Parent_Division__c, 'Web EMEA_Web') //SFDC 7061
                .put(Account.Vertical__c, 'Commerce')
                .put(Account.Sub_Vertical__c, 'Retail')
                .put(Account.Anaplan_Sub_Territory__c, 'Anaplan-Sub') //SFDC 7061
                .put(Account.CurrencyIsoCode, 'INR')    
                .create()
                .getRecord();
         
        }
      

        acc = [select id, ownerid from Account where id=:acc.Id];
        System.assert(acc.Ownerid==sOpsUser.Id, 'Account owner is:'+acc.OwnerId);


        List<String> akamIds = new List<String>();
        new SobjectBuilder(Product2.sObjectType)
            .count(numOfProducts)
            .create();



        List<Product2> tProds =[select id from Product2 limit :numOfProducts];

        List<PricebookEntry> pbEntry= (List<PriceBookEntry>)new SObjectBuilder(PriceBookEntry.sObjectType)
            .put(PriceBookEntry.Pricebook2Id, Test.getStandardPricebookId())
            .put(PriceBookEntry.Product2Id, tProds)
            .put(PriceBookEntry.CurrencyIsoCode, 'INR')
            .put(PriceBookEntry.IsActive, true)
            .put(PriceBookEntry.UnitPrice, 2600000)
            .count(numOfProducts)
            .create()
            .getRecords();

        new SobjectBuilder(Opportunity.sObjectType)
            .eagerPopulate()
            .put(Opportunity.AccountId, acc.Id)
            .put(Opportunity.Opportunity_Type__c, 'New Logo')
            .put(Opportunity.Is_Authorized_Partner_Sellable_Country__c, false)
            .put(Opportunity.CurrencyIsoCode, 'INR')
            .put(Opportunity.ZOFF_Enabled__c, true) // SFDC-7061
            .put(Opportunity.Validation_Override__c, true) // SFDC - 7061
            .create();

            insert new Product2(Name = 'Test_000_003456_Unique',Zoff_Product__c = true); // SFDC - 7061


    }


    static testmethod void testChatterFeedInsertAndDelete()
    {
        User emriUser;
        System.runAs(dmlUser)
        {


            Account acc = SobjectRepository.getAccount();
            Opportunity oppty = SobjectRepository.getOpportunity();
            List<PriceBookEntry> pbEntries = [select id from PriceBookEntry limit :numOfProducts];


            // make the account owner an EMRI user

            new SObjectBuilder(PermissionSetAssignment.sObjectType)
                .put(PermissionSetAssignment.PermissionSetId, GSMSettings.getValue('Emri_2_0_Pilot_Users'))
                .put(PermissionSetAssignment.AssigneeId, acc.OwnerId)
                .create();

            emriUser = new User(Id=acc.Ownerid);

            Product2 tProd = [select id from Product2 where name='WebProduct1'];
            new SobjectBuilder(ObjectToChatterGroupMap__c.sObjectType)
                .put(ObjectToChatterGroupMap__c.Name, String.valueOf(tProd.Id))
                .put(ObjectToChatterGroupMap__c.ChatterGroupID__c, emriUser.Id)
                .create();

            Integer numOfProducts = 3;
            List<OpportunityLineItem> olis;
            System.runAs(emriUser)
            {
                olis = (List<OpportunityLineItem>)new SobjectBuilder(OpportunityLineItem.sObjectType)
                    .put(OpportunityLineItem.OpportunityId, oppty.Id)
                    .put(OpportunityLineItem.PriceBookEntryId, pbEntries)
                    .put(OpportunityLineItem.Quantity, 1)
                    .count(numOfProducts)
                    .create()
                    .getRecords();

                for(OpportunityLineItem oli: [SELECT id,EMRI__c, UnitPrice From OpportunityLineItem where id in :olis])
                {
                    System.assertEquals(0, oli.EMRI__c);
                    System.assertEquals(0, oli.UnitPrice);
                }

            }
            // one feeditem per insert
            // only one product had chatter
            Integer FeedCount = [SELECT count() From FeedItem where ParentId = :emriUser.Id];
            System.assertEquals(1, FeedCount);
            OpportunityLineItemTriggerClass.postToChatterGroupFirstRunFlag=true;

            System.runAs(emriUser)
            {
                delete olis;
            }

            // one feeditem per insert and one for delete
            FeedCount = [SELECT count() From FeedItem where ParentId = :emriUser.Id];
            System.assertEquals(2, FeedCount);

        }
    }

    static testMethod void testProductNotificationsAndSalesPlayAndStrategicNetMRR() 
    {
        System.runAs(dmlUser)
        {

            Test.startTest();
            Account acc = SobjectRepository.getAccount();
            Opportunity oppty = SobjectRepository.getOpportunity();
            List<PriceBookEntry> pbEntries = [select id from PriceBookEntry limit :numOfProducts];


            // make the account owner an EMRI user

            User emriUser = new User(Id=acc.Ownerid);
            User bizOpsUser = SobjectRepository.getBizOpsUser();

            Product2 tProd = [select id from Product2 where name='WebProduct1'];

            // for product notifications
            tProd.Family = 'Security';
            update tProd;

            Specialist_Comp_Team__c sct = (Specialist_Comp_Team__c)new SObjectBuilder(Specialist_Comp_Team__c.SobjectType)
                .put(Specialist_Comp_Team__c.Product_Specialist__c, bizOpsUser.Id)
                .put(Specialist_Comp_Team__c.Type__c, 'Security Specialist')
                .put(Specialist_Comp_Team__c.Name, 'TestCarrierSpecialist')
                .create()
                .getRecord();


            oppty.Security_Specialist__c = sct.Id;
            oppty.CloseDate=Date.today().addMonths(1);
            oppty.StageName='5. Negotiate';
            oppty.Validation_Override__c =true;

            update oppty;

            User securityArchitect = SobjectRepository.getSolutionsEngineer();

            new SobjectBuilder(AccountTeamMember.SObjectType)
                .put(AccountTeamMember.UserId, securityArchitect.Id)
                .put(AccountTeamMember.TeamMemberRole, 'Enterprise Security Architect')
                .put(AccountTeamMember.Validation_Overide__c,true)
                .put(AccountTeamMember.AccountId, acc.Id)
                .create();

            Sales_Play__c sp = (Sales_Play__c)new SObjectBuilder(Sales_Play__c.sObjectType)
                .put(Sales_Play__c.Start_Date__c, System.today())
                .put(Sales_Play__c.End_Date__c, System.today()+5)
                .put(Sales_Play__c.Name, 'Test_Sales_play')
                .put(Sales_Play__c.Relevant_Products__c, 'Testng_sec_prod')
                .create()
                .getRecord();

            new SObjectBuilder(Account_Sales_Play_Association__c.sObjectType)
                .put(Account_Sales_Play_Association__c.Sales_Play__c, sp.Id)
                .put(Account_Sales_Play_Association__c.Account__c, acc.Id)
                .create();


            Integer numOfProducts = 3;
            List<OpportunityLineItem> olis;
            System.runAs(emriUser)
            {

                olis = (List<OpportunityLineItem>)new SobjectBuilder(OpportunityLineItem.sObjectType)
                    .put(OpportunityLineItem.OpportunityId, oppty.Id)
                    .put(OpportunityLineItem.PriceBookEntryId, pbEntries[0].Id)
                    .put(OpportunityLineItem.Quantity, 1)
                    .put(OpportunityLineItem.UnitPrice, 2600000)
                    .put(OpportunityLineItem.Projected_Monthly_commit_fees__c, 2)
                    .put(OpportunityLineItem.Average_Renewal_Commit_MRR__c, 1)
                    .count(numOfProducts)
                    .create()
                    .getRecords();
            }

            for(OpportunityLineItem oli: [select id, Strategic_MRR__c, Strategic_MRR_USD__c from OpportunityLineItem where id in :olis])
            {
                System.assert(oli.Strategic_MRR__c==1, 'Strategic is:'+oli);
            }

            oppty = [select id, Strategic_MRR__c from Opportunity where id=:oppty.id];
            //System.assert(math.floor(oppty.Strategic_MRR__c)==3, 'Strategic is:'+oppty);

            Test.stopTest();

        }
    }


    public static testmethod void  testInvoiceMonthlyAmountsClean()
    {
        System.runAs(dmlUser)
        {

            Test.startTest();
            Account acc = SobjectRepository.getAccount();
            Opportunity oppty = SobjectRepository.getOpportunity();
            List<PriceBookEntry> pbEntries = [select id from PriceBookEntry limit :numOfProducts];

            System.assert(pbEntries.size()==numOfProducts, 'Pricebook entries are:'+pbEntries);

            // make the account owner an EMRI user

            User emriUser = new User(Id=acc.Ownerid);
            User bizOpsUser = SobjectRepository.getBizOpsUser();


            List<OpportunityLineItem> olis;
            System.runAs(emriUser)
            {
                olis = (List<OpportunityLineItem>)new SobjectBuilder(OpportunityLineItem.sObjectType)
                    .put(OpportunityLineItem.OpportunityId, oppty.Id)
                    .put(OpportunityLineItem.PriceBookEntryId, pbEntries)
                    .put(OpportunityLineItem.Quantity, 1)
                    .put(OpportunityLineItem.UnitPrice, 900000)
                    .put(OpportunityLineItem.Projected_Monthly_commit_fees__c, 200)
                    .put(OpportunityLineItem.Average_Renewal_Commit_MRR__c, 100)
                    .put(OpportunityLineItem.Average_Renewal_Usage_MRR__c, 1000)
                    .count(numOfProducts)
                    .create()
                    .getRecords();
            }

            olis= [select Average_Renewal_Commit_MRR__c,
                Average_Renewal_Commit_MRR_USD__c,
                Average_Renewal_Usage_MRR__c,
                OpportunityId,
                Average_Renewal_Usage_MRR_USD__c
                    from OpportunityLineItem
                    where Id in :olis];

            DatedConversionRate dcr = [select ConversionRate 
                from DatedConversionRate 
                where IsoCode='INR' 
                and StartDate<:oppty.CloseDate 
                and NextStartDate>:oppty.CloseDate 
                limit 1];

            System.assert(olis.size()==numOfProducts, 'numOfProducts:'+olis.size());
            for(OpportunityLineItem oli: olis)
            {
                // test that dollar is stronger than indian rupee hehe :D
                System.assert(oli.Average_Renewal_Commit_MRR__c>oli.Average_Renewal_Commit_MRR_USD__c, 'values are:'+olis);
            }
            ByPassAndLimitUtils.disable('OpportunityLineItemTrigger');

            OpportunityLineItemTriggerClass.fixOpptyProducts();
            update olis[0];

            Test.stopTest();
            ApexPages.StandardController sc = new ApexPages.StandardController(olis[0]);
            PageReference pageRef = Page.OpportunityLineItemsView;
            pageRef.getParameters().put('id', [select id from Product2 where Name='CarrierProduct1' order by CreatedDate desc limit 1].Id);
            Test.setCurrentPageReference(pageRef);
            OpportunityLineItemsViewController poli = new OpportunityLineItemsViewController(sc);
            poli.cancel();
            poli.remove();
        }

    }

    public static testmethod void  testMinContactRole()
    {
        System.runAs(dmlUser)
        {

            Test.startTest();
            Account acc = SobjectRepository.getAccount();
            Opportunity oppty = SobjectRepository.getOpportunity();

            User accOwner = new User(Id=acc.Ownerid);
            User usrCrmIntg = SObjectRepository.getCRMIntegrationUser();

            Order_Approval__c oa = (Order_Approval__c)new SobjectBuilder(Order_Approval__c.sObjectType)
                .eagerPopulate()
                .put(Order_Approval__c.Associated_Opportunity__c, oppty.Id)
                .create()
                .getRecord();
            List<OpportunityLineItem> olis;
            System.runAs(usrCrmIntg)
            {
                oppty.Opportunity_Type__c='New Logo';
                oppty.CloseDate=Date.today().addMonths(3);
                oppty.Opportunity_Category__c='Customer Churn';
                oppty.Loss_Reason__c='Bankruptcy';
                oppty.StageName = '5. Negotiate';
                try
                {
                    update oppty;
                }
                catch(Exception e)
                {
                    system.assert(e.getMessage().containsIgnoreCase('contact role'), 'exception was:'+e.getMessage());
                }
            }

            Test.stopTest();

        }

    }

    //Only for code coverege 
    static testmethod void methodForCodeCoverege()
    {
        System.runAs(dmlUser){  
            list<Opportunity> opplist=[select Id, CloseDate, AccountId, Deal_Type__c, Partner_Involved__c, Contract_Entered_by__c, Contract_Reviewed_by__c, Partner_Involved_AKAM_Id__c,
                                       Renew_Contract_Id_Text__c, Contract_Effective_End_Date__c, Channel_Manager__c,Transaction_Type__c,Double_Reviewed_By__c
                                       from Opportunity limit 10];
            Test.startTest();
            OpportunityTriggerClass.updateOnlineChannelOpptyTaskStatus(opplist[0]);
            OpportunityTriggerClass.populateRenewalOpptyFieldsFirstRunFlag = true;
            OpportunityTriggerClass.populateRenewalOpptyFields(opplist);
            OpportunityTriggerClass.managerSwarmOpptys(opplist);
            OpportunityTriggerClass.updateOpptyStageForAMG(opplist);
            OpportunityTriggerClass.checkForInactiveUser(opplist);
            OpportunityTriggerClass.createtask(null,null,null,null,null,null);
            OpportunityTriggerClass.createtask(null,null,null,null,null,null,false,null,null);

            OpportunityTriggerClass.addOpptySalesTeam(oppList);
            OpportunityTriggerClass.checkOrderApprovalForOpp(oppList);
            OpportunityTriggerClass.checkOppContactRole(oppList);
            OpportunityTriggerClass.PreventOppDelete(oppList);
            OpportunityTriggerClass.uncheckPullForward();
            OpportunityTriggerClass.CloseOldOpportunities();
            Test.stopTest();
        }
    }

    static testmethod void testCloseOldOpptys()
    {
        System.runAs(dmlUser){  
            Test.startTest();
            Opportunity oppty = SobjectRepository.getOpportunity();
            oppty.CloseDate= date.today().addMonths(-1);
            update oppty;
            OpportunityTriggerClass.CloseOldOpportunities();
            Test.stopTest();
        }
    }
    public static testmethod void  testGST()
    {
        System.runAs(dmlUser)
        {

            // opptyAddOpportunityShareSettings(Id pOpptyId, Id pUserId, String pOpptyAccessLeve)
            // fetchChannelManagerIds
            //         if(!ByPassAndLimitUtils.run('OpportunityTriggerClass.sendDoubleByteNotification'))
            //min contact role
            // CloseOldOpportunities with close date -1 minth

            OpportunityTriggerClass.manageForecastCategoryFirstRunFlag = true;
            OpportunityTriggerClass.managePartnerForecastFirstRunFlag = true;
            Test.startTest();
            Account acc = SobjectRepository.getAccount();
            acc.GST__c=null;
            update acc;
            User accOwner = new User(Id=acc.Ownerid);

            new SobjectBuilder(AccountTeamMember.sObjectType)
                .put(AccountTeamMember.TeamMemberRole, 'Technical Sales - Primary')
                .put(AccountTeamMember.UserId, accOwner.Id)
                .put(AccountTeamMember.AccountId, acc.Id)
                .put(AccountTeamMember.Validation_Overide__c,true)
                .create();

            Opportunity oppty = SobjectRepository.getOpportunity();
            oppty.Opportunity_Category__c='Customer Churn';
            oppty.Opportunity_Type__c='New Logo';
            oppty.CloseDate= date.today().addMonths(1);
            oppty.StageName = '3. Verify Options';
            update oppty;

            Test.stopTest();

        }

    }
    public static testmethod void testUncheckPullForward()
    {
        System.runAs(dmlUser)
        {

            Test.startTest();
            Opportunity oppty = SobjectRepository.getOpportunity();
            oppty.Pull_Forward__c=true;
            oppty.CloseDate = Date.today().addMonths(-1);
            update oppty;
            OpportunityTriggerClass.uncheckPullForward();

            Test.stopTest();

        }

    }
    public static testmethod void testAddOpptySalesTeam()
    {
        System.runAs(dmlUser)
        {

            Test.startTest();
            Account acc = SobjectRepository.getAccount();

            Opportunity oppty = SobjectRepository.getOpportunity();
            oppty.Channel_Manager__c=null;
            update oppty;
            OpportunityTriggerClass.addOpptySalesTeam(new List<Opportunity>{oppty});
            OpportunityTriggerClass.opptyAddOpportunityShareSettings(oppty.id, dmlUser.id, 'Edit');

            Test.stopTest();

        }

    }
    public static testmethod void  testSalesStage6Change()
    {
        System.runAs(dmlUser)
        {

            User u=[select id from user where name ='Collections Queue' limit 1];
            new SobjectBuilder(Q2O_Custom_Settings__c.sObjectType)
                .put(Q2O_Custom_Settings__c.Name, 'CollectionUser')
                .put(Q2O_Custom_Settings__c.Value__c, u.id)
                .create();
		
            ByPassAndLimitUtils.enable('OpportunityTriggerClass.sendDoubleByteNotification');
            Product2 tProd = [select id from Product2 where name='WebProduct1'];

            // for product notifications
            tProd.Family = 'Enterprise';
            update tProd;

            Account acc = SobjectRepository.getAccount();
            
            new SObjectBuilder(Contact.sObjectType)
                .eagerPopulate()
                .put(Contact.Double_byte__c, true)
                .put(Contact.AccountId, acc.Id)
                .create();

            Opportunity oppty = SobjectRepository.getOpportunity();
            oppty.Opportunity_Category__c='Customer Churn';
            oppty.Opportunity_Type__c='New Logo';
            oppty.CloseDate= date.today().addMonths(1);
            oppty.Contract_Reviewed__c = Date.today();
            oppty.Contract_Reviewed_by__c = 'AGH';
            oppty.Loss_Reason__c='Bankruptcy';
            oppty.StageName = '5. Negotiate';
            oppty.Validation_Override__c =true;

            update oppty;

            Test.startTest();

            OpportunityTriggerClass.creditCheckTask(new List<Opportunity>{oppty});
            List<PriceBookEntry> pbEntries = [select id from PriceBookEntry limit :numOfProducts];

            System.assert(pbEntries.size()==numOfProducts, 'Pricebook entries are:'+pbEntries);


            User accOwner = new User(Id=acc.Ownerid);


            List<OpportunityLineItem> olis;
            System.runAs(accOwner)
            {
                olis = (List<OpportunityLineItem>)new SobjectBuilder(OpportunityLineItem.sObjectType)
                    .put(OpportunityLineItem.OpportunityId, oppty.Id)
                    .put(OpportunityLineItem.PriceBookEntryId, pbEntries)
                    .put(OpportunityLineItem.Quantity, 1)
                    .put(OpportunityLineItem.UnitPrice, 100000)
                    .put(OpportunityLineItem.Projected_Monthly_commit_fees__c, 200)
                    .put(OpportunityLineItem.Average_Renewal_Commit_MRR__c, 100)
                    .put(OpportunityLineItem.Average_Renewal_Usage_MRR__c, 1000)
                    .count(numOfProducts)
                    .create()
                    .getRecords();
            }
            OpportunityTriggerClass.autoAssignSpecialist(olis,new Set<id>{oppty.id});
            Map<Id,Opportunity> opptyMap= new Map<Id,Opportunity>();
            opptyMap.put(oppty.Id, oppty);
            Map<OpportunityLineItem,string> productusertype = new Map<OpportunityLineItem,string>();
            productusertype.put(olis[0],'CIAM');
            opptyMap=OpportunityTriggerClass.autoAssignCIAMSpecialist(new Set<id>{oppty.id},productusertype,opptyMap);
            //OpportunityTriggerClass.switchToAutoRenewalType(new list<opportunity>{oppty});
            OpportunityUtilClass.updateOpportunityFromLineItemAfterInsertAfterUpdate(opptyMap.values());
            CustomException ex = new CustomException('This is a test exception');
            OpportunityUtilClass.handleOpportunityException(ex,opptyMap.values());            
            /*OpportunityTriggerClass.autoAssignSpecialist(olis,new Set<id>{oppty.id});
            OpportunityTriggerClass.autoAssignCIAMSpecialist(olis,new Set<id>{oppty.id});

            OpportunityTriggerClass.OpptyCategoryCheckFirstRunFlag=true;

            oppty.stageName= '6. Signed';
            oppty.Opportunity_Category__c=null;
            oppty.Loss_Reason__c=null;
            OpportunityTriggerClass.setSQLDateTime(oppty);
            update oppty;*/

            // oppty.Contract_Id__c='C-MG-324';
            // oppty.StageName ='Closed Won';
            // update oppty;
            Test.stopTest(); 

        }

    }

    public static testmethod void  testAMGOpportunityStatusChange()
    {
        System.runAs(dmlUser)
        {
            Test.startTest();
            Opportunity oppty = SobjectRepository.getOpportunity();
            Id amgRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('AMG Opportunity').getRecordTypeId();
            oppty.RecordTypeId = amgRecordTypeId;
            oppty.AMG_Opportunity_Status__c='Rejected';
            update oppty;
            oppty = [select id,isclosed,RecordTypeId,AMG_Opportunity_Status__c from opportunity where id=:oppty.id];
            System.assert(oppty.isclosed==true, 'Opportunity is not closed:'+oppty);

            Test.stopTest();

        }

    }

    /* SFDC-5392 Removal of Related_Trial_Opportunity__c lookup field
    public static testmethod void  testRelatedTrialOppty()
    {
        System.runAs(dmlUser)
        {
            Test.startTest();
            Opportunity oppty = SobjectRepository.getOpportunity();
            Account acc = SobjectRepository.getAccount();



            User accOwner = new User(Id=acc.Ownerid);

            new SobjectBuilder(AccountTeamMember.sObjectType)
                .put(AccountTeamMember.TeamMemberRole, 'Technical Sales - Primary')
                .put(AccountTeamMember.UserId, accOwner.Id)
                .put(AccountTeamMember.AccountId, acc.Id)
                .create();


            System.runAs(accOwner)
            {
                Opportunity dupOppty = (Opportunity)new SobjectBuilder(Opportunity.sObjectType)
                    .eagerPopulate()
                    .put(Opportunity.AccountId, acc.Id)
                    .put(Opportunity.Opportunity_Type__c, 'New Logo')
                    .put(Opportunity.Is_Authorized_Partner_Sellable_Country__c, false)
                    .put(Opportunity.CurrencyIsoCode, 'INR')
                    .create()
                    .getRecord();

                oppty.Related_Trial_Opportunity__c = dupOppty.Id;
                update oppty;
            }

            Test.stopTest();

        }

    }
    */
    public static testmethod void  testClosedDuplicate()
    {
        System.runAs(dmlUser)
        {
            Test.startTest();
            Opportunity oppty = SobjectRepository.getOpportunity();
            Account acc = SobjectRepository.getAccount();



            User accOwner = new User(Id=acc.Ownerid);

            new SobjectBuilder(AccountTeamMember.sObjectType)
                .put(AccountTeamMember.TeamMemberRole, 'Technical Sales - Primary')
                .put(AccountTeamMember.UserId, accOwner.Id)
                .put(AccountTeamMember.Validation_Overide__c,true)
                .put(AccountTeamMember.AccountId, acc.Id)
                .create();

            User s1 = SobjectRepository.getSalesPAEUser();

            new SobjectBuilder(OpportunityTeamMember.sObjectType)
                .put(OpportunityTeamMember.TeamMemberRole, 'Channel - Primary')
                .put(OpportunityTeamMember.UserId, s1.Id)
                .put(OpportunityTeamMember.OpportunityAccessLevel, 'Edit')
                .put(OpportunityTeamMember.OpportunityId, oppty.Id)
                .create();

            Contact ct = (Contact)new SObjectBuilder(Contact.sObjectType)
                .eagerPopulate()
                .put(Contact.AccountId, acc.Id)
                .create()
                .getRecord();

            Close_Plan__c cp = (Close_Plan__c)new SobjectBuilder(Close_Plan__c.sObjectType)
                .eagerPopulate()
                .put(Close_Plan__c.Opportunity__c,oppty.id)
                .put(Close_Plan__c.Validation_Override__c, true)
                .create()
                .getRecord();


            new SobjectBuilder(OpportunityContactRole.sObjectType)
                .put(OpportunityContactRole.ContactId, ct.Id)
                .put(OpportunityContactRole.Role, 'Technical Primary')
                .put(OpportunityContactRole.OpportunityId, oppty.Id)
                .create();

            Id onemoreopptyid = null;
            System.runAs(accOwner)
            {
                Opportunity dupOppty = (Opportunity)new SobjectBuilder(Opportunity.sObjectType)
                    .eagerPopulate()
                    .put(Opportunity.AccountId, acc.Id)
                    .put(Opportunity.Opportunity_Type__c, 'New Logo')
                    .put(Opportunity.Is_Authorized_Partner_Sellable_Country__c, false)
                    .put(Opportunity.CurrencyIsoCode, 'INR')
                    .create()
                    .getRecord();

                oppty.Duplicate_Opportunity__c = dupOppty.Id;
                oppty.stageName='Closed Duplicate';
                oppty.CloseDate=Date.today();
                onemoreopptyid = dupOppty.Id;
                update oppty;
            }
            cp.Opportunity__c = onemoreopptyid;
           	delete cp;
            Test.stopTest();

        }

    }
    public static testmethod void  testOrderRegionUpdate()
    {
        System.runAs(dmlUser)
        {
            Test.startTest();
            Opportunity oppty = SobjectRepository.getOpportunity();


            oppty.Order_Region__c='Japan';
            oppty.Validation_Override__c=true;
            update oppty;
            Test.stopTest();

        }

    }
    public static testmethod void  testCampaignTieBack()
    {
        System.runAs(dmlUser)
        {
            Test.startTest();
            Opportunity oppty = SobjectRepository.getOpportunity();
            Account acc = SobjectRepository.getAccount();
            Campaign cmpgn = (Campaign)new SobjectBuilder(Campaign.sObjectType).eagerPopulate().create().getRecord();
            List<PriceBookEntry> pbEntries = [select id from PriceBookEntry limit :numOfProducts];

            List<OpportunityLineItem> olis = (List<OpportunityLineItem>)new SobjectBuilder(OpportunityLineItem.sObjectType)
                .put(OpportunityLineItem.OpportunityId, oppty.Id)
                .put(OpportunityLineItem.PriceBookEntryId, pbEntries)
                .put(OpportunityLineItem.Quantity, 1)
                .put(OpportunityLineItem.UnitPrice, 900000)
                .put(OpportunityLineItem.Projected_Monthly_commit_fees__c, 200)
                .put(OpportunityLineItem.Average_Renewal_Commit_MRR__c, 100)
                .put(OpportunityLineItem.Average_Renewal_Usage_MRR__c, 1000)
                .create()
                .getRecords();

            oppty.CampaignId =  cmpgn.Id;
            oppty.CloseDate = Date.today();
            update oppty;
            oppty = [select id, CampaignId, StageName from Opportunity where id=:oppty.id];
            System.assert(oppty.CampaignId!=null, 'Campaign is null:'+oppty);


            User accOwner = new User(Id=acc.Ownerid);


            oppty.stageName='Closed Lost';
            oppty.Loss_Reason__c='Bankruptcy';
            oppty.StageName = '5. Negotiate';
            oppty.Validation_Override__c =true;

            update oppty;

            delete olis;
            Test.stopTest();

        }

    }

    public static testmethod void  testCampaignTieBackClosedWon()
    {
        System.runAs(dmlUser)
        {
            Test.startTest();
            Opportunity oppty = SobjectRepository.getOpportunity();
            Account acc = SobjectRepository.getAccount();
            Campaign cmpgn = (Campaign)new SobjectBuilder(Campaign.sObjectType).eagerPopulate().create().getRecord();
            oppty.CampaignId =  cmpgn.Id;
            oppty.CloseDate = Date.today();
            User bizOpsUser = SObjectRepository.getBizOpsUser();
            oppty.Opportunity_Leader__c = bizOpsUser.Id;
            update oppty;



            User accOwner = new User(Id=acc.Ownerid);

            new SobjectBuilder(Task.sObjectType)
                .put(Task.OwnerId, accOwner.Id)
                .put(Task.Subject, 'Request for Contract Entry')
                .put(Task.Status, 'In Progress')
                .put(Task.Type__c, 'Meeting')
                .put(Task.WhatId, oppty.Id)
                .create();

            System.runAs(accOwner)
            {
                oppty.StageName='6. Signed';
                oppty.CCG__C='fdasjkl';
                oppty.Opportunity_Type__c='New Logo';
                oppty.Contract_Entered_by__c ='Online Channel';
                oppty.Momentum_Automated__c ='Online Channel Sales';
                oppty.No_of_Contracts__c = 'fdasjkl';
                oppty.StageName ='Closed Won';
                oppty.Validation_Override__c =true;
                update oppty;
            }

            delete oppty;

            Test.stopTest();

        }

    }
    public static testmethod void testRenewals()
    {
        System.runAs(dmlUser)
        {
            Test.startTest();
            Opportunity oppty = SobjectRepository.getOpportunity();
            Account acc = SobjectRepository.getAccount();
            User accOwner = new User(Id=acc.Ownerid);

            Merge_Contract_Header__c mch = (Merge_Contract_Header__c)new SobjectBuilder(Merge_Contract_Header__c.SObjectType)
                .eagerPopulate()
                .put(Merge_Contract_Header__c.Original_Contract_Id__c, 'C-YXYXY1')
                .put(Merge_Contract_Header__c.Currency__c, 'INR')
                .put(Merge_Contract_Header__c.Account_Name__c, acc.Id)
                .create()
                .getRecord();


            Contract_Product__c cp = (Contract_Product__c)new SObjectBuilder(Contract_Product__c.SobjectType)
                .eagerPopulate()
                .put(Contract_Product__c.Original_Contract_Id__c, mch.Id)
                .put(Contract_Product__c.Forecast_Product_Id__c, 'F-PR-275')
                .put(Contract_Product__c.Contract_Product_Akam_Id__c, 'CP-P-34')
                .put(Contract_Product__c.Effective_End_Date__c, System.today()+100)
                .create()
                .getRecord();
		List<String> contractIds = new String[]{mch.Id};
        List<String> contractProductIds = new String[]{cp.Id};

        Opportunity oppRenewed = SF1_CreateNewOpportunityFlowController.createRenewalOpportunityFromContracts(contractIds, 'INR', false,'Renewal');
       // Opportunity oppRenewed = SF1_CreateNewOpportunityFlowController.createRenewalOpportunityWithProducts(contractProductIds, 'INR','Renewal');

        List<OpportunityLineItem> oli = [Select Id from  OpportunityLineItem where id = :oppRenewed.id ];
        delete oli;
        Test.stopTest();

        }

    }

    public static testmethod void testAutoRenewals()
    {
        System.runAs(dmlUser)
        {
            Test.startTest();
            Opportunity oppty = SobjectRepository.getOpportunity();
            Account acc = SobjectRepository.getAccount();
            User accOwner = new User(Id=acc.Ownerid);

            Merge_Contract_Header__c mch = (Merge_Contract_Header__c)new SobjectBuilder(Merge_Contract_Header__c.SObjectType)
                .eagerPopulate()
                .put(Merge_Contract_Header__c.Original_Contract_Id__c, 'C-YXYXY1')
                .put(Merge_Contract_Header__c.Currency__c, 'INR')
                .put(Merge_Contract_Header__c.Account_Name__c, acc.Id)
                .create()
                .getRecord();


            Contract_Product__c cp = (Contract_Product__c)new SObjectBuilder(Contract_Product__c.SobjectType)
                .eagerPopulate()
                .put(Contract_Product__c.Original_Contract_Id__c, mch.Id)
                .put(Contract_Product__c.Forecast_Product_Id__c, 'F-PR-275')
                .put(Contract_Product__c.Contract_Product_Akam_Id__c, 'CP-P-34')
                .put(Contract_Product__c.Effective_End_Date__c, System.today()+100)
                .create()
                .getRecord();

             
        List<String> contractIds = new String[]{mch.Id};
        List<String> contractProductIds = new String[]{cp.Id};


         Opportunity oppAutoRenewed = SF1_CreateNewOpportunityFlowController.createRenewalOpportunityFromContracts(contractIds, 'INR', false,'Auto-Renewal');
        //Opportunity oppAutoRenewed = SF1_CreateNewOpportunityFlowController.createRenewalOpportunityWithProducts(contractProductIds, 'INR','Auto-Renewal');


        try { // this is only for coverage  // SFDC 7061
            CreateRenewalOpptyWithMultipleContracts co = new CreateRenewalOpptyWithMultipleContracts(mch.Original_Contract_Id__c);
            co.refreshOpportunityProducts(oppty.id);
        }
        catch (Exception ex)
        {

        }
        Test.stopTest();

        }

    }

    public static testMethod void testZOFFrenewal() 
    {
        Account acc = SobjectRepository.getAccount();
        Opportunity oppty = SobjectRepository.getOpportunity();
        update new Opportunity (Id = oppty.id,opportunity_type__c = 'Renewal',Validation_Override__c = true, Churn_Risk__c = '', EMRI_Risk__c = '');
        Opportunity oppty0 = SobjectRepository.getOpportunity();
        Product2 pdUser = [Select id ,Zoff_Product__c from product2 limit 1];
        update new Product2(Id = pdUser.id,Zoff_Product__c = true);
        PriceBookEntry pbEntry  = [select id from PriceBookEntry  where product2.Zoff_Product__c = true limit 1 ];
        Test.startTest();
        OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = oppty0.Id,UnitPrice = 900000,Quantity = 1,Average_Renewal_Commit_MRR__c = 1000,Average_Renewal_Usage_MRR__c = 100,pricebookEntryId = pbEntry.id,Validation_Override__c = true);
        insert oli ;
        Test.stopTest();
    }
    public static testMethod void testZOFFautorenewal() 
    {
        Account acc = SobjectRepository.getAccount();
        Opportunity oppty = SobjectRepository.getOpportunity();
        update new Opportunity (Id = oppty.id,opportunity_type__c = 'Auto-Renewal',Validation_Override__c = true, Churn_Risk__c = '', EMRI_Risk__c = '');
        Opportunity oppty0 = SobjectRepository.getOpportunity();
        Product2 pdUser = [Select id ,Zoff_Product__c from product2 limit 1];
        update new Product2(Id = pdUser.id,Zoff_Product__c = true);
        PriceBookEntry pbEntry  = [select id from PriceBookEntry  where product2.Zoff_Product__c = true limit 1 ];
        Test.startTest();
        OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = oppty0.Id,UnitPrice = 900000,Quantity = 1,Average_Renewal_Commit_MRR__c = 1000,Average_Renewal_Usage_MRR__c = 100,pricebookEntryId = pbEntry.id,Validation_Override__c = true);
        insert oli ;
        Test.stopTest();
    }
    public static testMethod void testZOFFaddOn() 
    {
        Account acc = SobjectRepository.getAccount();
       // Opportunity oppty = SobjectRepository.getOpportunity();
        //update new Opportunity (Id = oppty.id,opportunity_type__c = 'Auto-Renewal',Validation_Override__c = true);
        Opportunity oppty0 = SobjectRepository.getOpportunity();
        Product2 pdUser = [Select id ,Zoff_Product__c from product2 limit 1];
        update new Product2(Id = pdUser.id,Zoff_Product__c = true);
        PriceBookEntry pbEntry  = [select id from PriceBookEntry  where product2.Zoff_Product__c = true limit 1 ];
        Test.startTest();
        OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = oppty0.Id,UnitPrice = 900000,Quantity = 1,Average_Renewal_Commit_MRR__c = 1000,Average_Renewal_Usage_MRR__c = 100,pricebookEntryId = pbEntry.id,Validation_Override__c = true);
        insert oli ;
        delete oli;
        Test.stopTest();
    }
    public static testMethod void testZOFFchurn() 
    {
        Account acc = SobjectRepository.getAccount();
        Opportunity oppty = SobjectRepository.getOpportunity();
        //update new Opportunity (Id = oppty.id,opportunity_type__c = 'Auto-Renewal',Validation_Override__c = true);
        Opportunity oppty0 = SobjectRepository.getOpportunity();
        Product2 pdUser = [Select id ,Zoff_Product__c from product2 limit 1];
        update new Product2(Id = pdUser.id,Zoff_Product__c = true);
        PriceBookEntry pbEntry  = [select id from PriceBookEntry  where product2.Zoff_Product__c = true limit 1 ];
        Test.startTest();
        OpportunityLineItem oli = new OpportunityLineItem(OpportunityId = oppty0.Id,UnitPrice = 900000,Quantity = 1,Average_Renewal_Commit_MRR__c = 1000,Average_Renewal_Usage_MRR__c = 100,pricebookEntryId = pbEntry.id,Validation_Override__c = true);
        insert oli ;
        Test.stopTest();
    }

public static testMethod void testZoffapproval ()
{
  
    Account acc = SobjectRepository.getAccount();
    Opportunity oppty = SobjectRepository.getOpportunity();
    Opportunity opUodate = new Opportunity (opportunity_type__c = 'Churn',Id = oppty.id,ZOFF_Status__c = 'No',Opt_Out_Reason__c = 'Renewals',Validation_Override__c = true,Churn_Risk__c = '', EMRI_Risk__c = '');
    Test.startTest();
    update opUodate ;
    Test.stopTest();
    Opportunity oppty_0 = SobjectRepository.getOpportunity();
    //System.assert(false,'Opp****'+oppty_0);
}

// update Related_Trial_Opportunity__c
    public static testMethod void testZoffapprvalidation ()
    {
        Opportunity oppty = [Select id,opportunity_type__c,ZOFF_Status__c,Opt_Out_Reason__c,Validation_Override__c,Zoff_Approval__c from opportunity Limit 1 ];
        //Account_Reassignment_Rule__c acccc = [Select id from Account_Reassignment_Rule__c limit 1];
        Opportunity opUodate = new Opportunity (opportunity_type__c = 'Renewal',Id = oppty.id,ZOFF_Status__c = 'No',Opt_Out_Reason__c = 'Renewals',Validation_Override__c = true ,Zoff_Approval__c = 'Approved');
       try { update opUodate ;
        
     }
       catch(exception ex) {}   
      // System.assert(false,oppty);
    }

    public static testMethod void testZoffapprvalidation2 ()
    {
        Opportunity oppty = [Select id,opportunity_type__c,ZOFF_Status__c,Opt_Out_Reason__c,Validation_Override__c,Zoff_Approval__c from opportunity Limit 1 ];
        Map<Id,ZoffUtilClass.emailListwrapper> prepareEmailist = new Map<Id,ZoffUtilClass.emailListwrapper>();
        ZoffUtilClass.emailListwrapper em = new ZoffUtilClass.emailListwrapper();
        em.toList = new List<String>{'abc@akamai.com'};
        em.zoffStatus = 'Submitted';
        prepareEmailist.put(oppty.id, em );
        ZoffUtilClass.sendZoffEmail(prepareEmailist);
        //Account_Reassignment_Rule__c acccc = [Select id from Account_Reassignment_Rule__c limit 1];
        Opportunity opUodate = new Opportunity (opportunity_type__c = 'Renewal',Id = oppty.id,ZOFF_Status__c = 'No',Opt_Out_Reason__c = 'Renewals',Validation_Override__c = true );
       try { update opUodate ;
            
     }
       catch(exception ex) {}   
      // System.assert(false,oppty);
    }


    public static testMethod void  product2Test()
    {
        Test.enableChangeDataCapture();
        Product2 p01 = [Select id,Zoff_Product__c from product2 where Name = 'Test_000_003456_Unique' limit 1];
        update new Product2(Id = p01.id,Zoff_Product__c = false);
        Test.getEventBus().deliver();
        
        Opportunity oppty = [Select id,opportunity_type__c,ZOFF_Status__c,Opt_Out_Reason__c,Validation_Override__c,Zoff_Approval__c from opportunity Limit 1 ];
        try {
            Product2TriggerClass.zoffopportunityUpdate(new List<id> {oppty.id});
        }
        catch(Exception ex) {
            
        }
        delete p01;
        
    }

    public static testMethod void testProductsync()
    {
        Opportunity oppty = [Select id,opportunity_type__c,ZOFF_Status__c,Opt_Out_Reason__c,Validation_Override__c,Zoff_Approval__c from opportunity Limit 1 ];
        L2Q_Product2OpptySyncBatchClass lq = new L2Q_Product2OpptySyncBatchClass(new set<Id>{oppty.id});
        Test.startTest();
        Database.executeBatch(lq,1);
        Test.stopTest();
        
    }
}