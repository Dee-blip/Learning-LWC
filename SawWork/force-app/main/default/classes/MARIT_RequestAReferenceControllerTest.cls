@isTest
private class MARIT_RequestAReferenceControllerTest {
    @isTest static void testCreateNewOpportunity_RequestAReferenceCalled_ReturnsFalse() {
        Account acc = new Account();
        acc.Name = 'TestABC';
        acc.Vertical__c = 'Gaming';
        acc.Sub_Vertical__c = 'Console Mfs';
        insert acc;

        Opportunity opp = new Opportunity();
        opp.Account = acc;
        opp.AccountId = acc.Id;
        opp.Name = 'OppName';
        opp.Deal_Type__c = 'Direct';
        opp.StageName = '2. Explore Options';
        opp.CurrencyIsoCode = 'BRL';
        opp.CloseDate = Date.today();
        insert opp;

        string resultStr =  MARIT_RequestAReferenceController.FetchOpportunity(opp.Id);
        system.assertEquals(true, resultStr.contains('"isOpptyValid":false'));
    }
    
    @isTest static void testCreateNewOpportunity_RequestAReferenceCalled_ReturnsTrue() {
        Account acc = new Account();
        acc.Name = 'TestABC';
        acc.Vertical__c = 'Gaming';
        acc.Sub_Vertical__c = 'Console Mfs';
        insert acc;

        Opportunity opp = new Opportunity();
        opp.Account = acc;
        opp.AccountId = acc.Id;
        opp.Name = 'OppName';
        opp.Deal_Type__c = 'Direct';
        opp.StageName = '5. Negotiate';
        opp.CurrencyIsoCode = 'BRL';
        opp.CloseDate = Date.today();
        insert opp;
        
        string resultStr =  MARIT_RequestAReferenceController.FetchOpportunity(opp.Id);
        system.assertEquals(true, resultStr.contains('"isOpptyValid":true'));
    }
}