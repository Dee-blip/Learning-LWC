/*
   Anand Hegde - Upgraded API version
                 SeeAllData = false

*/
@isTest
public class OpportunityScheduledJobsTestClass 
{

    public static testMethod void renewalOpptyChatterAndEmailTest_Positive() 
    {
        
        System.runAs(utilTestClass.getTestRunUser())
        {
        ManagedPkgErrorClass.isFromManagedPackage = false;
        utilTestClass.insertCustomSettings();
        User managerUser = utilTestClass.CreateUser('__mgrUsr', 'Worldwide', 'Sales - Regional Manager - Media');
        insert managerUser;
        
        User ownerUser = utilTestClass.CreateUser('__onrUsr', 'Worldwide', 'Sales - Media');
        ownerUser.ManagerId = managerUser.Id;
        insert ownerUser;
        
        Account_Reassignment_Rule__c rule = utilTestClass.CreateAccountReassignmentRule('__TestRule', ownerUser.Id, 'Worldwide');
        insert rule;
        
        Account acc = utilTestClass.CreateAccount('__TestAccount');
        acc.BillingState = 'CA';
        acc.BillingPostalCode = '94104';
        acc.BillingCountry = 'USA';
        acc.BillingCity = 'SanFrancisco';
        acc.ShippingStreet = '417';
        acc.ShippingState = 'CA';
        acc.ShippingPostalCode = '94104';
        acc.ShippingCountry = 'USA';
        acc.ShippingCity = 'SanFrancisco';
        System.runAs(ownerUser)
        {
            insert acc;
        }
        
        Merge_Contract_Header__c contract = new Merge_Contract_Header__c();
        contract.Account_Name__c = acc.Id;
        contract.Name = '__TestContract';
        contract.Original_Contract_Id__c = '__TestContract';
        insert contract;
        
        List<Opportunity> oppList = new List<Opportunity>();
        Map<Id,Opportunity> oppIdOppMap = new Map<Id,Opportunity>();
        
        Opportunity opp = utilTestClass.CreateOpportunity('__TestOppty', '2-Qualify');
        opp.AccountId = acc.Id;
        opp.Contract_Effective_End_Date__c = Datetime.now().addMonths(Integer.ValueOf(GsmUtilClass.getGSMSettingValue('OppSchCls_RenewalOpp_finalCheck'))).date();
        opp.CloseDate = Datetime.now().addMonths(Integer.ValueOf(GsmUtilClass.getGSMSettingValue('OppSchCls_RenewalOpp_finalCheck'))).date();
        opp.Opportunity_Type__c = 'Auto Renewal';
        opp.Renew_Contract_Id_Text__c = contract.Id;
        oppList.add(opp);
        
        Opportunity opp2 = utilTestClass.CreateOpportunity('__TestOppty2', '2-Qualify');
        opp2.AccountId = acc.Id;
        opp2.Contract_Effective_End_Date__c = Datetime.now().addMonths(2).date();
        opp2.CloseDate = Datetime.now().addMonths(Integer.ValueOf(GsmUtilClass.getGSMSettingValue('OppSchCls_RenewalOpp_finalCheck'))).date();
        opp2.Opportunity_Type__c = 'Auto Renewal';
        opp2.AKAM_Modified_Date__c = Datetime.now().addMonths(-2);
        opp2.Renew_Contract_Id_Text__c = contract.Id;
        oppList.add(opp2);
        
        System.runAs(ownerUser)
        {
            insert oppList;
        }
        System.debug('Test Opp List '+oppList);
        
        for(Opportunity o: oppList)
            oppIdOppMap.put(o.Id,o);
        
        //Cron job to create chatter and send email to Oppty Owner and Owner's Manager.
        String res = OpportunityScheduledJobsClass.createChatterForRenewalOppty();
        
        System.assert(res.startsWith('1:'));
        
        List<FeedItem> chatterList = new List<FeedItem>();
        
        for(FeedItem fi: [SELECT Body FROM FeedItem WHERE ParentId IN: oppList])
            chatterList.add(fi);
            
        System.assert(chatterList.size()>0);
        }
        
    }

    public static testMethod void renewalOpptyChatterAndEmailTest_Negative() 
    {
        
        System.runAs(utilTestClass.getTestRunUser())
        {
        
        ManagedPkgErrorClass.isFromManagedPackage = false;
        utilTestClass.insertCustomSettings();
        User managerUser = utilTestClass.CreateUser('__mgrUsr', 'Worldwide', 'Sales - Regional Manager - Media');
        insert managerUser;
        
        User ownerUser = utilTestClass.CreateUser('__onrUsr', 'Worldwide', 'Sales - Media');
        ownerUser.ManagerId = managerUser.Id;
        insert ownerUser;
        
        Account_Reassignment_Rule__c rule = utilTestClass.CreateAccountReassignmentRule('__TestRule', ownerUser.Id, 'Worldwide');
        insert rule;
        
        Account acc = utilTestClass.CreateAccount('__TestAccount');
        acc.BillingState = 'CA';
        acc.BillingCountry = 'USA';
        acc.BillingPostalCode = '94104';
        acc.ShippingState = 'CA';
        acc.ShippingCountry = 'USA';
        System.runAs(ownerUser)
        {
            insert acc;
        }
        
        List<Opportunity> oppList = new List<Opportunity>();
        Map<Id,Opportunity> oppIdOppMap = new Map<Id,Opportunity>();
        
        Merge_Contract_Header__c contract = new Merge_Contract_Header__c();
        contract.Account_Name__c = acc.Id;
        contract.Name = '__TestContract';
        contract.Original_Contract_Id__c = '__TestContract';
        insert contract;
        
        Opportunity opp = utilTestClass.CreateOpportunity('__TestOppty', 'Closed Won');
        opp.AccountId = acc.Id;
        opp.Contract_Effective_End_Date__c = Datetime.now().addMonths(Integer.ValueOf(GsmUtilClass.getGSMSettingValue('OppSchCls_RenewalOpp_finalCheck'))).date();
        opp.CloseDate = Datetime.now().addMonths(Integer.ValueOf(GsmUtilClass.getGSMSettingValue('OppSchCls_RenewalOpp_finalCheck'))).date();
        opp.Opportunity_Type__c = 'Auto Renewal';
        opp.Renew_Contract_Id_Text__c = contract.Id;
        opp.Validation_Override__c=true;
        oppList.add(opp);
        
        Opportunity opp2 = utilTestClass.CreateOpportunity('__TestOppty2', 'Closed Won');
        opp2.AccountId = acc.Id;
        opp2.Contract_Effective_End_Date__c = Datetime.now().addMonths(2).date();
        opp2.CloseDate = Datetime.now().addMonths(Integer.ValueOf(GsmUtilClass.getGSMSettingValue('OppSchCls_RenewalOpp_finalCheck'))).date();
        opp2.Opportunity_Type__c = 'Auto Renewal';
        opp2.AKAM_Modified_Date__c = Datetime.now().addMonths(-2);
        opp2.Renew_Contract_Id_Text__c = contract.Id;
        opp2.Validation_Override__c=true;
        oppList.add(opp2);
        
        System.runAs(ownerUser)
        {
            insert oppList;
        }
        
        System.debug('Test Opp List '+oppList);
        for(Opportunity o: oppList)
            oppIdOppMap.put(o.Id,o);
        
        //Cron job to create chatter and send email to Oppty Owner and Owner's Manager.
        String res = OpportunityScheduledJobsClass.createChatterForRenewalOppty();
        
        System.assert(res.startsWith('1:'));
        
        List<FeedItem> chatterList = new List<FeedItem>();
        
        for(FeedItem fi: [SELECT Body FROM FeedItem WHERE ParentId IN: oppList])
            chatterList.add(fi);
            
        System.assertEquals(chatterList.size(),0);
        }
        
    }

    public static testMethod void sendMailforOpptyPastDue_Test() {
        System.runAs(utilTestClass.getTestRunUser())
        {
            Account acc = utilTestClass.CreateAccount('__TestAccount');
            insert acc;

            date today = date.Today();
            date dueDate = today.addDays(-14);

            Id akamaiOpptyRecTypeId = GsmUtilClass.getGSMSettingValue('OpptyTrigger_AkamaiOpptyRecType');

            Opportunity opp = utilTestClass.CreateOpportunity('__TestOppty', '1-Create');
            opp.AccountId = acc.Id;
            opp.CloseDate = dueDate;
            opp.Probability = 1;
            opp.RecordTypeId = akamaiOpptyRecTypeId;
            insert opp;

            OpportunityScheduledJobsClass.sendMailforOpptyPastDue();
        }
    }
}