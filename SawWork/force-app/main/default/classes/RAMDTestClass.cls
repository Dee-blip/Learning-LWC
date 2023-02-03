/**
 * Created by kusharma on 04/01/18.
 */

@isTest(seeAllData = false)
public class RAMDTestClass {

    public static Account accountRAMD;
    public static RAMD_Processor__c ramdProcessor1;
    public static RAMD_Orange_Zone_Countries__c ramdOrangeZoneCountry;
    static User dmlUser = new User(id=UserInfo.getUserId());

    

    @testSetup
    public static void createTestData(){
        System.runAs(dmlUser) {
            utilTestClass.insertCustomSettings();
        }

        List<Account> lAccounts = new List<Account>();
        List<RAMD_Processor__c> lRamdProcessors = new List<RAMD_Processor__c>();
        accountRAMD = utilTestClass.CreateAccount('__Test RAMD Account');
        accountRAMD.Type = 'Direct Customer - Active';
        lAccounts.add(accountRAMD);

        Account accountForRAMDProcessor1 = utilTestClass.CreateAccount('RAMD Account For Processor1');
        accountForRAMDProcessor1.Type = 'Direct Customer - Active';
        lAccounts.add(accountForRAMDProcessor1);

        Account accountForRAMDProcessor2 = utilTestClass.CreateAccount('RAMD Account For Processor2');
        accountForRAMDProcessor2.Type = 'Direct Customer - Active';
        lAccounts.add(accountForRAMDProcessor2);

        Account accountForRAMDProcessor3 = utilTestClass.CreateAccount('RAMD Account For Processor3');
        accountForRAMDProcessor3.Type = 'Direct Customer - Active';
        lAccounts.add(accountForRAMDProcessor3);

        Account accountForRAMDProcessor4 = utilTestClass.CreateAccount('RAMD Account For Processor4');
        accountForRAMDProcessor4.Type = 'Direct Customer - Active';
        lAccounts.add(accountForRAMDProcessor4);

        Account accountForRAMDProcessor5 = utilTestClass.CreateAccount('RAMD Account For Processor5');
        accountForRAMDProcessor5.Type = 'Direct Customer - Active';
        lAccounts.add(accountForRAMDProcessor5);

        Account accountForRAMDProcessor6 = utilTestClass.CreateAccount('RAMD Account For Processor6');
        accountForRAMDProcessor6.Type = 'Direct Customer - Active';
        lAccounts.add(accountForRAMDProcessor6);

        Account accountForRAMDProcessor7 = utilTestClass.CreateAccount('RAMD Account For Processor7');
        accountForRAMDProcessor7.Type = 'Direct Customer - Active';
        accountForRAMDProcessor7.Orange_Zone__c = true;
        lAccounts.add(accountForRAMDProcessor7);

        Account accountForRAMDProcessor8 = utilTestClass.CreateAccount('RAMD Account For Processor8');
        accountForRAMDProcessor8.Type = 'Direct Customer - Active';
        lAccounts.add(accountForRAMDProcessor8);

        Account accountForRAMDProcessor9 = utilTestClass.CreateAccount('RAMD Account For Processor9');
        accountForRAMDProcessor9.Type = 'Direct Customer - Active';
        accountForRAMDProcessor9.Orange_Zone__c = true;
        lAccounts.add(accountForRAMDProcessor9);

        Account accountForRAMDProcessor10 = utilTestClass.CreateAccount('RAMD Account For Processor10');
        accountForRAMDProcessor10.Type = 'Direct Customer - Active';
        accountForRAMDProcessor10.Orange_Zone__c = true;
        lAccounts.add(accountForRAMDProcessor10);

        insert lAccounts;

        AccountTeamMember accountTeamMember10 = new AccountTeamMember();
        accountTeamMember10.AccountId = accountForRAMDProcessor10.Id;
        accountTeamMember10.UserId = UserInfo.getUserId();
        insert accountTeamMember10;

        ramdProcessor1 = new RAMD_Processor__c();
        ramdProcessor1.Account__c = accountForRAMDProcessor1.Id;
        ramdProcessor1.Event_Type__c = 'New Record';
        ramdProcessor1.Account_Country__c = 'India';
        ramdProcessor1.Sales_Primary_Country__c = 'India';
        ramdProcessor1.Processing_Status__c = 'Pending';
        lRamdProcessors.add(ramdProcessor1);

        RAMD_Processor__c ramdProcessor2 = new RAMD_Processor__c();
        ramdProcessor2.Account__c = accountForRAMDProcessor2.Id;
        ramdProcessor2.Event_Type__c = 'Account Country Change';
        ramdProcessor2.Account_Country__c = 'China';
        ramdProcessor2.Sales_Primary_Country__c = 'India';
        ramdProcessor2.Processing_Status__c = 'Pending';
        lRamdProcessors.add(ramdProcessor2);

        RAMD_Processor__c ramdProcessor3 = new RAMD_Processor__c();
        ramdProcessor3.Account__c = accountForRAMDProcessor3.Id;
        ramdProcessor3.Event_Type__c = 'Account Country Change';
        ramdProcessor3.Account_Country__c = 'India';
        ramdProcessor3.Sales_Primary_Country__c = 'China';
        ramdProcessor3.Processing_Status__c = 'Pending';
        lRamdProcessors.add(ramdProcessor3);

        RAMD_Processor__c ramdProcessor4 = new RAMD_Processor__c();
        ramdProcessor4.Account__c = accountForRAMDProcessor4.Id;
        ramdProcessor4.Event_Type__c = 'New Record';
        ramdProcessor4.Account_Country__c = 'China';
        ramdProcessor4.Sales_Primary_Country__c = 'India';
        ramdProcessor4.Processing_Status__c = 'Pending';
        lRamdProcessors.add(ramdProcessor4);

        RAMD_Processor__c ramdProcessor5 = new RAMD_Processor__c();
        ramdProcessor5.Account__c = accountForRAMDProcessor5.Id;
        ramdProcessor5.Event_Type__c = 'New Record';
        ramdProcessor5.Account_Country__c = 'India';
        ramdProcessor5.Sales_Primary_Country__c = 'China';
        ramdProcessor5.Processing_Status__c = 'Pending';
        lRamdProcessors.add(ramdProcessor5);

        RAMD_Processor__c ramdProcessor6 = new RAMD_Processor__c();
        ramdProcessor6.Account__c = accountForRAMDProcessor6.Id;
        ramdProcessor6.Event_Type__c = 'Sales Primary Movement';
        ramdProcessor6.Account_Country__c = 'China';
        ramdProcessor6.Sales_Primary_Country__c = 'India';
        ramdProcessor6.Processing_Status__c = 'Pending';
        lRamdProcessors.add(ramdProcessor6);

        RAMD_Processor__c ramdProcessor7 = new RAMD_Processor__c();
        ramdProcessor7.Account__c = accountForRAMDProcessor7.Id;
        ramdProcessor7.Event_Type__c = 'Sales Primary Movement';
        ramdProcessor7.Account_Country__c = 'India';
        ramdProcessor7.Sales_Primary_Country__c = 'China';
        ramdProcessor7.Sales_Primary_Country_Old__c = 'China';
        ramdProcessor7.Processing_Status__c = 'Pending';
        lRamdProcessors.add(ramdProcessor7);

        RAMD_Processor__c ramdProcessor8 = new RAMD_Processor__c();
        ramdProcessor8.Account__c = accountForRAMDProcessor8.Id;
        ramdProcessor8.Event_Type__c = 'New OZone Country';
        ramdProcessor8.Account_Country__c = 'India';
        ramdProcessor8.Sales_Primary_Country__c = 'China';
        ramdProcessor8.Processing_Status__c = 'Pending';
        lRamdProcessors.add(ramdProcessor8);

        RAMD_Processor__c ramdProcessor9 = new RAMD_Processor__c();
        ramdProcessor9.Account__c = accountForRAMDProcessor9.Id;
        ramdProcessor9.Event_Type__c = 'Account Country Change';
        ramdProcessor9.Account_Country__c = 'India';
        ramdProcessor9.Sales_Primary_Country__c = 'India';
        ramdProcessor9.Processing_Status__c = 'Pending';
        lRamdProcessors.add(ramdProcessor9);

        RAMD_Processor__c ramdProcessor10 = new RAMD_Processor__c();
        ramdProcessor10.Account__c = accountForRAMDProcessor10.Id;
        ramdProcessor10.Event_Type__c = 'Sales Primary Movement';
        ramdProcessor10.Account_Country__c = 'India';
        ramdProcessor10.Sales_Primary_Country__c = 'Chian';
        ramdProcessor10.Processing_Status__c = 'Pending';
        lRamdProcessors.add(ramdProcessor10);

        insert lRamdProcessors;

        ramdOrangeZoneCountry = new RAMD_Orange_Zone_Countries__c();
        ramdOrangeZoneCountry.Country_Name__c = 'China';
        ramdOrangeZoneCountry.Country_Code__c = 'China';
        ramdOrangeZoneCountry.Active__c = true;
        insert ramdOrangeZoneCountry;

    }

    public static testMethod void ramdPendingRequestTest(){
        Test.startTest();

        accountRAMD = [SELECT Id, BillingCountry, AKAM_Account_ID__c FROM Account WHERE Name = 'RAMD Account For Processor10'][0];
        //List<RAMD_Processor__c> lRamdProcessors = [SELECT Id,Name FROM RAMD_Processor__c];
        //System.debug('###lRamdProcessors ' + lRamdProcessors + ' ## ' + accountRAMD.AKAM_Account_ID__c);
        Test.setCurrentPageReference(new PageReference('Page.RAMDPendingRequestViewer'));
        ApexPages.currentPage().getParameters().put('akamAccountId', accountRAMD.AKAM_Account_ID__c);
        RAMDPendingRequestProcessorCtrl pendingRequestProcessorCtrl = new RAMDPendingRequestProcessorCtrl();
        pendingRequestProcessorCtrl.newPendingRecToDisplay = accountRAMD.AKAM_Account_ID__c;
        //List<SelectOption> lOZoneReasons = pendingRequestProcessorCtrl.lOZoneReasons;
        //List<SelectOption> lOZoneOpts = pendingRequestProcessorCtrl.currentRecToDisplay.lOZoneOpts;
        //String oZoneCountry = pendingRequestProcessorCtrl.oZoneCountry;
        pendingRequestProcessorCtrl.actionSupportCall();
        pendingRequestProcessorCtrl.saveAccountRec();

        Test.stopTest();
    }

    public static testMethod void ramdBatchTest(){
        Database.executeBatch(new RAMDProcessATMChangesBatch(), 400);
        Database.executeBatch(new RAMDPendingRecordsProcessorBatch(), 400);
    }

    public static testMethod void updateAccountCountry(){
        accountRAMD = [SELECT Id, BillingCountry FROM Account WHERE Name = '__Test RAMD Account'][0];
        System.debug('### accountRAMD ' + accountRAMD);
        accountRAMD.BillingCountry = 'Japan';
        update accountRAMD;
    }


    public static testMethod void processNewOrangeZoneCountry(){
        accountRAMD = [SELECT Id, BillingCountry FROM Account WHERE Name = '__Test RAMD Account'][0];
        RAMD_Processor__c ramdProcessor8 = new RAMD_Processor__c();
        ramdProcessor8.Account__c = accountRAMD.Id;
        ramdProcessor8.Event_Type__c = 'Sales Primary Movement';
        ramdProcessor8.Account_Country__c = 'India';
        ramdProcessor8.Sales_Primary_Country__c = 'China';
        ramdProcessor8.Processing_Status__c = 'Completed';
        insert ramdProcessor8;
        Test.startTest();
        Database.executeBatch(new RAMDOZoneCountryProcessorBatch(), 300);
        Test.stopTest();
    }

    public static testMethod void ramdExecuteOZoneProcessorTest(){
        ramdOrangeZoneCountry = [SELECT Id FROM RAMD_Orange_Zone_Countries__c LIMIT 1];
        Test.setCurrentPageReference(new PageReference('Page.RAMDExecuteOZoneProcessor'));
        ApexPages.StandardController sc = new ApexPages.StandardController(ramdOrangeZoneCountry);
        RAMDExecuteOZoneProcessor instanceProcessor = new RAMDExecuteOZoneProcessor(sc);
        Test.startTest();
        RAMDExecuteOZoneProcessor.executeATMChangesBatch();
        RAMDExecuteOZoneProcessor.executePendingRecBatch();
        //PageReference pgRef = instanceProcessor.executeOzoneBatch();
        instanceProcessor.executeOzoneBatch();
        ramdOrangeZoneCountry.Active__c = false;
        update ramdOrangeZoneCountry;
        Test.stopTest();
    }
}