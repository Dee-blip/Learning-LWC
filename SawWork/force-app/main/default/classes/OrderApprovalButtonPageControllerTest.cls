@isTest(seeAllData=false)
public class OrderApprovalButtonPageControllerTest {

    public static testmethod void OAButtonTest(){
        String akamaiRecTypeId = [select Id from RecordType where Name='Akamai Opportunity'][0].Id;
        Account newAccount = new Account();
        newAccount.Name = 'OAButton Test Account';
        newAccount.BillingCountry = 'USA';
        insert newAccount;    
        
        Opportunity opp = new Opportunity();
        opp.Name = 'OA Button Test Oppty';
        opp.StageName = '1. Identify Need';
        opp.AccountId = newAccount.Id;
        opp.CloseDate = Date.today().addDays(30);
        opp.RecordTypeId = akamaiRecTypeId;
        insert opp;
        
        Order_Approval__c oa = new Order_Approval__c();
        oa.Associated_Opportunity__c = opp.Id;
        oa.Order_Expires_Unless_Duly_Executed_By__c = Date.today().addDays(-2);
        insert oa;
        
        Test.setCurrentPage(Page.OrderApprovalButtonPage);
        ApexPages.currentPage().getParameters().put('fromButton','SendForESignature');
        ApexPages.currentPage().getParameters().put('recordId',oa.Id);
        ApexPages.currentPage().getParameters().put('eSignOverride','1');
        ApexPages.currentPage().getParameters().put('accountPrimaryCountry','USA');
        
        OrderApprovalButtonPageController oaObj = new OrderApprovalButtonPageController();
        PageReference pageRef;
        pageRef = oaObj.init();
        pageRef = oaObj.orderExpiryConfirmed();
        pageRef = oaObj.orderExpiryRejected();
        
        ApexPages.currentPage().getParameters().put('fromButton','SendForESignature');
        ApexPages.currentPage().getParameters().put('recordId',oa.Id);
        ApexPages.currentPage().getParameters().put('eSignOverride','0');
        ApexPages.currentPage().getParameters().put('accountPrimaryCountry','INDIA');
        pageRef = oaObj.init();
        
    }
}