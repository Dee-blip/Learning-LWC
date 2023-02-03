@isTest(seeAllData = false)
public class updateTrafficShareControllerTest 
{
    static testmethod void oneTestToTestThemAll()
    {
                    Account account = utilTestClass.CreateAccount('Test_Account');
            account.BillingStreet = '#39,7th Cross';
            account.BillingCity   = 'LA';
            account.BillingState = 'CA';
            account.BillingPostalCode = '56052';
            account.BillingCountry = 'USA';
            account.Type='Lead';
            account.Vertical__c = 'Business Services';
            account.Sub_Vertical__c = 'BPO';
            insert account;
            
        Traffic_Share__c ts = new Traffic_Share__c();
        ts.Account__c = account.id;
        insert ts;
        Delivery_Vendor__c dv = new Delivery_Vendor__c();
        dv.Traffic_Share__c  = ts.id;
        insert dv;
        
		Test.startTest();
            
    
            PageReference pageRef1 = Page.updateTrafficShareModifiedDate;
            Test.setCurrentPage(pageRef1);
             system.currentPageReference().getParameters().put('recordId', dv.Id);
            updateTrafficShareModifiedDateController  controller = new updateTrafficShareModifiedDateController();
            controller.init();
             Test.stopTest();
    }
}