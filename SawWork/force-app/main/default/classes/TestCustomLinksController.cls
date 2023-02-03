/*****************************************************************************
 * Name             : TestCustomLinksController
 * Created By       : Vinod
 * Created Date      : June 28,2013
 * Purpose          : Test Class for the CustomLinksController controller class
 * 23-Apr-14		:avidapan - optimization of Test class
 *****************************************************************************/
@isTest
private class TestCustomLinksController {

    static testMethod void myUnitTest() {
        test.startTest();
       Map<String, Schema.RecordTypeInfo> rtMap = 
                    Case.sObjectType.getDescribe().getRecordTypeInfosByName();
        Case cs = new Case();
        cs.RecordTypeId = rtMap.get('Technical').getRecordTypeId();
        cs.Status = 'Unassigned';
        cs.Origin = 'Email';
        cs.ProductPL__c = 'Alta';
        PageReference pRef = Page.Custom_Links;        
        Test.setCurrentPage(pRef);        
        ApexPages.StandardController stdCon = new ApexPages.StandardController(cs);      
        CustomLinksController controller = new CustomLinksController(stdCon); 
		test.stopTest();       
    }
}