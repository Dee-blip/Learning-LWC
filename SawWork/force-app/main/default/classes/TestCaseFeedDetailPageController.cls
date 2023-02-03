/**
 * Name             : TestCaseFeedDetailPageController
 * Created By       : Vinod
 * Created Date     : June 13,2013
 * Purpose          : Test Class for the CaseFeedDetailPageController controller class
 * 23-Apr-14        : avidapan-Optimiztion of test class(added test blocks)
 */
 
@isTest(seeAllData =  false)
private class TestCaseFeedDetailPageController {

    static testMethod void myUnitTest() {
        
        utilTestClass.createCustomSettings();
        Account acc1 = utilTestClass.createAccount('test1 Acc');  
        insert acc1;  
        
        HD_Test_Data_Factory.init();
        BMCServiceDesk__Category__c category = new BMCServiceDesk__Category__c();
        category.Name = 'Corporate Sustainability';
        category.BMCServiceDesk__AvailableForIncidents__c = true;
        insert category;
        
        BMCServiceDesk__Incident__c inc = new BMCServiceDesk__Incident__c();
        inc.BMCServiceDesk__FKCategory__c = category.Id;
        inc.HD_Ticket_Priority__c = '4';
        inc.BMCServiceDesk__FKUrgency__c = HD_Test_Data_Factory.urgencyMap.get('Severity 4');
        inc.BMCServiceDesk__FKClient__c = system.userInfo.getUserId();
        inc.BMCServiceDesk__FKImpact__c= HD_Test_Data_Factory.impactMap.get('LOW'); 
        inc.RecordtypeId = Schema.SObjectType.BMCServiceDesk__Incident__c.getRecordTypeInfosByName().get('Helpdesk').getRecordTypeId(); 
        //inc.BMCServiceDesk__FKRequestDetail__c = rd.Id;
        inc.How_was_the_Issue_Detected__c = 'Customer reported';
        inc.BMCServiceDesk__incidentDescription__c = 'Test Data Description values';
        insert inc;
        
        SI_ProductSearch__c search = new SI_ProductSearch__c();
        search.Value__c = 'Product Catalog';
        insert search;
        
        EB_Product__c product1 = new EB_Product__c();
        product1.EB_ProductId__c = 'test1Id';
        product1.EB_ProductType__c = 'Product';
        product1.EB_ParentId__c = '';
        product1.product_name__c = 'Edge Media Buying';
        product1.EB_Source__c = 'Product Catalog';
        insert product1;
        
        SI_IncidentRecordType__c SIRecordType = new SI_IncidentRecordType__c();
        SIRecordType.Service_Incident__c =  Schema.SObjectType.BMCServiceDesk__Incident__c.getRecordTypeInfosByName().get('Service Incident').getRecordTypeId();
        insert SIRecordType;     
        
        SI_Status__c sistatus = new SI_Status__c();
        sistatus.Name = 'SIStatus' ;
        sistatus.Status__c = 'IMPACT MITIGATED,CLOSED,RESOLVED';
        insert sistatus;
        
        SI_ServiceIncidentImpactedCustomers__c customer = new SI_ServiceIncidentImpactedCustomers__c();
        customer.SI_Service_Incident__c = inc.Id;
        customer.SI_AccountName__c= acc1.Id;
        insert customer;
        
        test.startTest();
        Case testCase = utilTestClass.createCase(acc1.Id);
        PageReference pRef = Page.CaseFeedDetailPage;        
        Test.setCurrentPage(pRef);        
        ApexPages.StandardController stdCon = new ApexPages.StandardController(testCase);       
        CaseFeedDetailPageController controller = new CaseFeedDetailPageController(stdCon);
        controller.PopulateCaseIncident();
        test.stopTest();
    }
}