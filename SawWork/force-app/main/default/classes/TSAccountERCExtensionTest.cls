@isTest(SeeAllData=true)
public class TSAccountERCExtensionTest {

    testmethod static void testCheckAccNamesWithSameERCs()
    {
        Account acc1 = new Account();
        acc1.Name = 'Test Account';
        acc1.AKERC__c = 'ABCD';
        insert acc1;
        Account acc2 = new Account();
        acc2.Name = 'Test Account 2';
        insert acc2;
        acc2.AKERC__c = 'BCCE';
	      Apexpages.StandardController stdController1 = new Apexpages.StandardController(acc1);
        TSAccountERCExtension tsAccErcExt1 = new TSAccountERCExtension(stdController1);
        System.assert(tsAccErcExt1.ercNumeric == '2223');
        Apexpages.StandardController stdController = new Apexpages.StandardController(acc2);
        TSAccountERCExtension tsAccErcExt = new TSAccountERCExtension(stdController);
        PageReference pageRef = Page.TSERCCreate;
	      Test.setCurrentPage(pageRef);
	      ApexPages.currentPage().getParameters().put('currErc', acc2.AKERC__c);
        tsAccErcExt.fetchErcNumeric();
        // test if erc numeric is successfully fetched
        System.assert(tsAccErcExt.ercNumeric == '2223');
        tsAccErcExt.save();
        System.assertEquals(true, tsAccErcExt.success);
    }

}