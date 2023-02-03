/*=============================================================================================================+  
SC_InvoiceTriggerHandlerTest
@version 1.0
@author :Bhavesh Kumar
@Description : Test class for SC_InvoiceTriggerHandler
@History
--Developer           --Date            --Change
Bhavesh Kumar        22/05/2021        Created the class Jira:ESESP-4094.*/
@isTest
public class SC_InvoiceTriggerHandlerTest {
    public static Account acc;
    public Static Opportunity opp;
	public static Invoice__c createInvoice(String accountId, String pContractId, String pInvoiceId, Date pInvDate, Decimal pAmount)
	{
		Invoice__c newInvoice = new Invoice__c();
		newInvoice.Account_Name__c  = accountId;
		newInvoice.Original_Contract_Id__c =pContractId;
		newInvoice.Invoice_Date__c= pInvDate;
		newInvoice.Name = pInvoiceId;
		newInvoice.Original_Amount__c=pAmount;
		return newInvoice;
	}
   
    public static Merge_Contract_Header__c createContractHeader(String pName, Id pAccId, Id pOpptyId)
	{
        Merge_Contract_Header__c ch=new Merge_Contract_Header__c();
        ch.Name=pName;
        ch.Account_Name__c=pAccId;
        ch.Opportunity_Name__c=pOpptyId;
        ch.Cancellation_Date__c=Date.today().addMonths(5);
        ch.Effective_Start_Date__c=Date.today().addMonths(-2);
        ch.Effective_End_Date__c=Date.today().addYears(1);
        ch.Locked__c=true;
        ch.Active__c=true;
        ch.Acceptance_Date__c=Date.today().addMonths(-1);
        ch.Contract_Type__c = 'Direct Customer';
        ch.Double_Invoice_Review__c=true;
        ch.Manual_List__c=true;
        return ch;
	}
    @testSetup
    public static void testData(){
        utilTestClass.createCustomSettings();
        acc = utilTestClass.CreateAccount('TestSepcialEscalationAccount');   
        acc.Support_Advocacy_Special_Escalation__c = true;
        acc.Support_Level__c='Standard';
        acc.BillingCountry = 'India';
        insert acc;
        //CreateAccountTeamMember
        opp = utilTestClass.CreateOpportunity('test','1. Identify Need');
        opp.CloseDate =Date.Today().addDays(5);
        opp.Deal_Type__c = 'Direct';
        insert opp;
        
        
            
    }
    
    public static testmethod void testCreationOfBillingCase(){
        acc = [select id from account limit 1];
        opp = [select id from opportunity limit 1];
        List<Merge_Contract_Header__c> contrList = new List<Merge_Contract_Header__c>();
        List<Invoice__c> invLIst = new LIst<Invoice__c>();
        Merge_Contract_Header__c contract1 = createContractHeader('test1',acc.id, opp.id);
        contract1.Delivery_Method__c = 'OIS';
        Merge_Contract_Header__c contract2 = createContractHeader('test2',acc.id, opp.id);
        contract2.Delivery_Method__c = 'OIS/EMAIL';
        Merge_Contract_Header__c contract3 = createContractHeader('test3',acc.id, opp.id);
        contract3.Delivery_Method__c = 'test';
        contrList.add(contract1);
        contrList.add(contract2);
        contrList.add(contract3);
        insert contrList;
        
        Invoice__c inv1 = createInvoice(acc.id, contract1.id, 'test1', Date.today(), 1000);
        Invoice__c inv2 = createInvoice(acc.id, contract2.id, 'test2', Date.today(), 1000);
        Invoice__c inv3 = createInvoice(acc.id, contract3.id, 'test3', Date.today(), 1000);
        invList.add(inv1);
        invList.add(inv2);
        invList.add(inv3);
        insert invLIst;
        
        
        List<case> billingCaselist = [select id,OwnerId from case where recordtype.name = 'billing'];
        System.assertEquals(2,billingCaselist.size());
        System.assertEquals('00G', (''+billingCaselist[0].OwnerId).substring(0,3));
        
    }
    
    public static testmethod void testBillingCaseOwner(){
        acc = [select id from account limit 1];
        opp = [select id from opportunity limit 1];
        AccountTeamMember atm = utilTestClass.CreateAccountTeamMember(acc.id, userinfo.getuserId());
        atm.TeamMemberRole = 'Billing Analyst';
        insert atm;
        List<Merge_Contract_Header__c> contrList = new List<Merge_Contract_Header__c>();
        List<Invoice__c> invLIst = new LIst<Invoice__c>();
        Merge_Contract_Header__c contract1 = createContractHeader('test1',acc.id, opp.id);
        contract1.Delivery_Method__c = 'OIS';
        
        contrList.add(contract1);
        
        insert contrList;
        
        Invoice__c inv1 = createInvoice(acc.id, contract1.id, 'test1', Date.today(), 1000);
        invList.add(inv1);
        
        insert invLIst;
        
        
        List<case> billingCaselist = [select id,OwnerId from case where recordtype.name = 'billing'];
        System.assertEquals('005', (''+billingCaselist[0].OwnerId).substring(0,3));
        
    }
}