@isTest(seeAllData=false)
public class GsmLite_AccntReAssignmentCtrlTest 
{
    
    public static testmethod void testEscalatePositive()
    {
        Test.startTest();
        
        Account acc = utilTestClass.CreateAccount('__Test Account');
        acc.IsPartnerCustom__c = true;
        acc.BillingState = 'ANDAMAN AND NICOBAR ISLANDS';
        insert acc;
        
        
        Test.setCurrentPage(Page.GsmLite_AccountReassignmentButtonPage);
        ApexPages.currentPage().getParameters().put('fromButton','Escalate');
        ApexPages.currentPage().getParameters().put('accReassignId',acc.Id);
        
        System.debug('accReassignId :'+acc.Id);
        
        GsmLite_AccntReAssignmentCtrl abpc = new GsmLite_AccntReAssignmentCtrl();
        
        abpc.init();
        
        Test.stopTest();
        
    }
    
}