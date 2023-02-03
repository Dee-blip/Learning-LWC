/***

Pramod Kamath Voderbet         Release 3.40     CR 2568594 - Online Channel:Package Creation

Pramod Kamath Voderbet         Release 3.44     CR 2703234- Online Channel: New Pricing Type - Cloudlets

Ruchika Sharma                 Release 4.1      CR 2801910- Marketplace : 4.1                          
***/

public with sharing class OnlineChannelProdAdd {


    public String    pkgId { get; set;}
    public String campprodtype { get; set;}
    public Online_Channel_Package_Product__c campProd {get;set;}
    public Online_Channel_Package_Pricing__c campPrice {get;set;} 
    public Online_Channel_Message__c ocmsg {get;set;} 
    
  
    public OnlineChannelProdAdd(ApexPages.StandardController controller) 
    {
    
    //constructor to get required details from the URL especially. 
     campPrice=new Online_Channel_Package_Pricing__c();
     //CR 2801910 : Ruchika Sharma: Added Default value to unit fields, so that they can be queried
     campPrice.Cloudlet_Pricing_unit1__c = 'GB';
     campPrice.Cloudlet_Pricing_unit2__c = 'Mbps';
     campPrice.Cloudlet_Pricing_unit3__c = 'MPV';
     ocmsg = new Online_Channel_Message__c();
     //campId = ApexPages.currentPage().getParameters().get('cId'); 
     pkgId = ApexPages.currentPage().getParameters().get('pkgId');       
       
     // campprodtype=ApexPages.currentPage().getParameters().get('prodtype');       
     campProd = new Online_Channel_Package_Product__c();
     campProd.Online_Channel_Package__c = pkgId; 
                          
    }   
    
    public PageReference save()
  {    
     //this button saves the product. 
       insert campProd;
      
       campPrice.Online_Channel_Package_Product__c= campProd.Id;
       campPrice.CurrencyIsoCode ='USD';
       campPrice.Name = campPrice.CurrencyIsoCode;//'USD';
       insert campPrice;          
       
       String rUrl = '/' + ApexPages.currentPage().getParameters().get('pkgId');
       PageReference rPage = new PageReference(rUrl);
       rPage.setRedirect(true);
       return rPage; 
    
  }
  
  
   public PageReference cancel() {  
   //this button cancels this product page and goes back to package
            String rUrl = '/' + ApexPages.currentPage().getParameters().get('pkgId');
            PageReference rPage = new PageReference(rUrl);
            rPage.setRedirect(true);
            return rPage;      
  
    
  }  
  
  
  public PageReference saveandaddpro() {  
  //this button saves the product and goes to the edit page to add new currency.
          insert campProd;
      
          campPrice.Online_Channel_Package_Product__c= campProd.Id;
          campPrice.Name = campPrice.CurrencyIsoCode;//'USD';
          insert campPrice;  
   
          String rUrlx = '/apex/OnlineChannelProductModify?pkgId=' + ApexPages.currentPage().getParameters().get('pkgId') + '&prodId='  +campProd.Id + '&zpriceId=null';
          PageReference rPage = new PageReference(rUrlx);
          rPage.setRedirect(true);
          return rPage;      
   } 
  
   
}