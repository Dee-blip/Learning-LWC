public class SI_NewImpactedProduct extends SI_PageControllerBase
{
    public Set<EB_Product__c> impactedProductSet{get;set;}
    public List<SI_ServiceIncidentImpactedProducts__c> impactedProductListToInsert = new List<SI_ServiceIncidentImpactedProducts__c>();
    
    public SI_NewImpactedProduct(ApexPages.StandardController stdController)
    {
    }
    
    public SI_NewImpactedProduct()
    {
    }
    
    public EB_ProductCatalogComponent myComponentController { get; set; }
    
    public override void setComponentController(SI_ComponentControllerBase compController) 
    {
        myComponentController = (EB_ProductCatalogComponent)compController;
    }
    
    public override SI_ComponentControllerBase getMyComponentController() 
    {
        return myComponentController;
    }
}