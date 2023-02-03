@isTest(seeAllData=false)
public class GsmLite_ContactButtonPageControllerTest 
{
    static User dmlUser = new User(id=UserInfo.getUserId());
    static testmethod void startTrialButtonUsingGenericContactButton()
    {
        System.runAs(dmlUser)
        {
            Test.startTest();
            Account acc =  (Account)new SobjectBuilder(Account.sObjectType)
                .eagerPopulate()
                .put(Account.Type, 'Lead')
                .create()
                .getRecord();

            Contact con = (Contact)new SobjectBuilder(Contact.sObjectType)
                .eagerPopulate()
                .put(Contact.AccountId, acc.Id)
                .create()
                .getRecord();

            Test.setCurrentPage(Page.GsmLite_ContactButtonPage);
            ApexPages.currentPage().getParameters().put('fromButton','ManageOperationsPortalAccess');
            ApexPages.currentPage().getParameters().put('recordId',con.Id);
            ApexPages.currentPage().getParameters().put('firstname','Bhuvan');
            ApexPages.currentPage().getParameters().put('lastname','Bam');

            GsmLite_ContactButtonPageController abpc;
            PageReference pageRef;

            try
            {
                abpc = new GsmLite_ContactButtonPageController();
                pageRef = abpc.init();
            }
            catch(Exception exx)
            {
                System.Debug('Exception');
            }

            Test.setCurrentPage(Page.GsmLite_ContactButtonPage);
            ApexPages.currentPage().getParameters().put('fromButton','ManageOperationsPortalAccess');
            ApexPages.currentPage().getParameters().put('recordId',con.Id);
            ApexPages.currentPage().getParameters().put('firstname','Bhuv@n');
            ApexPages.currentPage().getParameters().put('lastname','Bam');

            try
            {
                abpc = new GsmLite_ContactButtonPageController();
                pageRef = abpc.init();
            }
            catch(Exception exx)
            {
                System.Debug('Exception');
            }

            Test.setCurrentPage(Page.GsmLite_ContactButtonPage);
            ApexPages.currentPage().getParameters().put('fromButton','UpdateAccess');
            ApexPages.currentPage().getParameters().put('recordId',con.Id);

            abpc = new GsmLite_ContactButtonPageController();

            pageRef = abpc.init();
            Test.stopTest();
        }
    }
}