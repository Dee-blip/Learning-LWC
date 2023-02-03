@isTest
private class SI_NewImpactedProduct_Test
{
    static ApexPages.StandardController stdController;
       
    static testMethod void positiveUnitTest()
    {
        SI_ComponentControllerBase compController;
        SI_NewImpactedProduct impPrd = new SI_NewImpactedProduct(stdController);
        SI_NewImpactedProduct impPrd1 = new SI_NewImpactedProduct();
        impPrd.getMyComponentController();
        impPrd.setComponentController(compController);
    }
}