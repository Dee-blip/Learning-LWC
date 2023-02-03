public with sharing class OCPricingViewIntermediate {



public Online_Channel_Package_Pricing__c ocpp{get;set;}
public String priceId { get; set;}

   
    public OCPricingViewIntermediate(ApexPages.StandardController controller) {
    
    priceId=ApexPages.currentPage().getParameters().get('id');  
    
    //Online_Channel_Package_Product__c is the productlookup
      
 ocpp= [select Id,Name,Online_Channel_Package_Product__r.id,Online_Channel_Package_Product__r.Online_Channel_Package__c from Online_Channel_Package_Pricing__c where id =:priceId][0];

  
    }




 public Pagereference pageRedirect()
  {
  
   String rUrlx = '/apex/OnlineChannelProductModify?pkgId=' + ocpp.Online_Channel_Package_Product__r.Online_Channel_Package__c + '&prodId='  +ocpp.Online_Channel_Package_Product__r.id + '&zpriceId='+ priceId +'&view=true';
    
    PageReference rPage = new PageReference(rUrlx);
    rPage.setRedirect(true);
    return rPage; 
        
  }
  
  
}